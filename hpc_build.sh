#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

check_os_version()
{
    eval  "$(cat /etc/os-release | grep "^NAME=\|VERSION_ID=")"
    if [ "${NAME}" != "Amazon Linux" ]
    then
	echo "Unsupported Linux system: ${NAME} ${VERSION_ID}"
	exit 1
    fi
    if [ ${VERSION_ID} -eq 2 ]
    then
	S_VERSION_ID=7
    elif [ ${VERSION_ID} -eq 2022 ]
    then
	S_VERSION_ID=8
    fi
}

change_workdir()
{
    mkdir -p ${WORKDIR}
    cd ${WORKDIR}
}

get_compiler()
{
    if [ "${HPC_USE_VENDOR_COMPILER}" == "false" ]
    then
        return
    fi

    if [ "${SARCH}" == "x86_64" ]
    then
        export HPC_COMPILER=icc
    elif [ "${SARCH}" == "amd64" ]
    then
        export HPC_COMPILER=amdclang
    elif [ "${SARCH}" == "aarch64" ]
    then
         export HPC_COMPILER=armgcc
    fi
}

update_world()
{
    echo "${1}" | sudo tee -a ${HPC_PREFIX}/.world > /dev/null 2>&1
}

search_world()
{
    if [ x"${1}" == "x" ]
    then
	return -1
    fi
    grep -q "^${1}" ${HPC_PREFIX}/.world > /dev/null 2>&1
    return $?
}

# build_hpc_module <module name> <module version>
build_hpc_module()
{
    for module in $(awk -F',' '{ for( i=1; i<=NF; i++ ) print $i }' <<< ${1})
    do
	# multiple modules, only the match one(last one) use this MODULE_VERSION(original value saved in TARGET_MODULE_VERSION) from command line
	if [ "${module}" == "${HPC_MODULE}" ]
	then
            MODULE_VERSION=${TARGET_MODULE_VERSION}
	    source ../modules/${module}.sh updateversion ${MODULE_VERSION}
	else
            source ../modules/${module}.sh DEFAULTVERSION
	fi
	update_$(echo ${module} | tr '-' '_')_version

	# 目标模块完全匹配才不安装，非目标模快，模块名匹配就跳过
	if [ "${module}" != "${HPC_MODULE}" ]
	then
	    if (search_world ${HPC_COMPILER}-${HPC_MPI}-${module})
	    then
                continue 
	    fi
        else
	    if (search_world ${HPC_COMPILER}-${HPC_MPI}-${module}-${MODULE_VERSION})
	    then
                return
	    fi
	fi
        
	if [ "${module}" == "compiler" ]
	then
            echo "zzz *** $(date) *** Install system dependency for ${HPC_COMPILER}-${HPC_MPI}-${module}-${MODULE_VERSION}" | tee -a ${HPC_BUILD_LOG}
	else
            echo "zzz *** $(date) *** Install system dependency for ${HPC_MPI}-${module}-${MODULE_VERSION}" | tee -a ${HPC_BUILD_LOG}
	fi
	install_sys_dependency_for_$(echo ${module} | tr '-' '_') >> ${HPC_BUILD_LOG} 2>&1
	if [ "${module}" == "compiler" ]
	then
	    echo "zzz *** $(date) *** Install ${HPC_COMPILER}-${HPC_MPI}-${module}-${MODULE_VERSION}" | tee -a ${HPC_BUILD_LOG}
	else
	    echo "zzz *** $(date) *** Build ${HPC_MPI}-${module}-${MODULE_VERSION} with ${HPC_COMPILER}" | tee -a ${HPC_BUILD_LOG}
	fi
	if [ "${DISABLE_COMPILER_ENV}" == "true" ]
	then
	    unset_compiler_env
	fi
	download_$(echo ${module} | tr '-' '_')  && install_$(echo ${module} | tr '-' '_') >> ${HPC_BUILD_LOG} 2>&1 
	if [ $? -eq 0 ] 
	then
	    if [ ${module} == "compiler" ]
	    then
		if [ "${HPC_COMPILER}" == "icc" ] || [ "${HPC_COMPILER}" == "icc" ]
		then
		    update_world icc-openmpi-${module}-${MODULE_VERSION}
		    update_world icx-openmpi-${module}-${MODULE_VERSION}
		    update_world icc-mpich-${module}-${MODULE_VERSION}
		    update_world icx-mpich-${module}-${MODULE_VERSION}
		    update_world icc-intelmpi-${module}-${MODULE_VERSION}
		    update_world icx-intelmpi-${module}-${MODULE_VERSION}
		elif [ "${HPC_COMPILER}" == "armgcc" ] || [ "${HPC_COMPILER}" == "armclang" ]
		then
		    update_world armgcc-openmpi-${module}-${MODULE_VERSION}
		    update_world armclang-openmpi-${module}-${MODULE_VERSION}
		    update_world armgcc-mpich-${module}-${MODULE_VERSION}
		    update_world armclang-mpich-${module}-${MODULE_VERSION}
		else
		    update_world ${HPC_COMPILER}-openmpi-${module}-${MODULE_VERSION}
		    update_world ${HPC_COMPILER}-mpich-${module}-${MODULE_VERSION}
		fi
	    else
		update_world ${HPC_COMPILER}-${HPC_MPI}-${module}-${MODULE_VERSION}
		   
	    fi
	fi

	if [ "${DISABLE_COMPILER_ENV}" == "true" ]
	then
	    set_compiler_env
	fi
    done
}

install_scripts()
{
    sudo mkdir -p ${PREFIX}/scripts
    sed s"%XXPREFIXXX%${PREFIX}%g" ../scripts/env_template.sh > /tmp/env.sh
    sudo install -m 755 -D -t ${PREFIX}/scripts /tmp/env.sh
    sudo install -m 755 -D -t ${PREFIX}/scripts ../scripts/compiler.sh
    sudo install -m 755 -D -t ${PREFIX}/scripts ../scripts/detect_efa.sh
    sudo install -m 755 -D -t ${PREFIX}/scripts ../scripts/test.sh
    sudo install -m 755 -D -t ${PREFIX}/scripts ../scripts/submit_wrf.sbatch
    sudo install -m 755 -D -t ${PREFIX}/scripts ../scripts/submit_vasp.sh
}

check_and_uninstall_gcc10()
{
    if [ ${GCC10_INSTALLED} -eq 1 ] && ([ "${HPC_COMPILER}" == "clang" ] ||  [ "${HPC_COMPILER}" == "armclang" ] || [ "${HPC_COMPILER}" == "amdclang" ])
    then
	sudo rpm -e --nodeps gcc10
    fi
}

check_and_install_gcc10()
{
    if [ ${GCC10_INSTALLED} -eq 1 ] && ([ "${HPC_COMPILER}" == "clang" ] ||  [ "${HPC_COMPILER}" == "armclang" ] || [ "${HPC_COMPILER}" == "amdclang" ])
    then
	sudo yum install -y gcc10
    fi
}

main()
{
    if [ ${LIST_MODULE} -eq 1 ]
    then
	ls modules | grep -v modules.dep | sed "s/.sh//g"
	exit 0
    fi

    SARCH=$(uname -m)
    #if [ "${SARCH}" == "x86_64" ] && (sudo dmidecode -t processor | grep AMD > /dev/null)
    if [ "${SARCH}" == "x86_64" ] && (grep AMD /proc/cpuinfo > /dev/null)
    then
	SARCH=amd64
    fi

    HPC_PREFIX="${PREFIX}/${SARCH}"
    sudo mkdir -p ${HPC_PREFIX}

    get_compiler
    sudo mkdir -p ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    list_installed_module

    check_os_version

    WORKDIR=hpc_build
    GCC10_INSTALLED=0
    rpm -q gcc10 > /dev/null 2>&1 && GCC10_INSTALLED=1
    HPC_BUILD_LOG="$(pwd)/${WORKDIR}/.hpc_build-${HPC_COMPILER}-${HPC_MPI}.log"

    change_workdir

    install_scripts
 
    check_and_uninstall_gcc10

    # to build the packages in the same host, the first part of the TARGET much compatible(identical)
    TARGET=$(uname -m)-bing-linux
    #HOST=$(gcc -dumpmachine)
    #BUILD=${HOST}
    #TARGET=$(gcc -### 2>&1 | grep "^Target:" | awk '{print $2}')
    # **************************************

    TARGET_MODULE_VERSION=${MODULE_VERSION}
    if [ "${HPC_MODULE}" == "compiler" ] 
    then
	build_hpc_module compiler ${MODULE_VERSION}
    else
	MODULES=$(grep "^${HPC_COMPILER}-${HPC_MPI}:.*${HPC_MODULE}$" ../modules/modules.dep | head -n1 | awk -F':' '{print $NF}')
	# the HPC_HOST_TARGET is not set yet, set if for install/building compilers
	if [ ! -f /usr/bin/gcc ]
	then
            echo "zzz *** $(date) *** Install system gcc to identify target machine"  | tee -a ${HPC_BUILD_LOG}
	    sudo yum install -y gcc >> ${HPC_BUILD_LOG} 2>&1 || sudo dnf -y install gcc >> ${HPC_BUILD_LOG} 2>&1 || sudo apt-get install -y gcc >> ${HPC_BUILD_LOG} 2>&1
	fi
	export HPC_HOST_TARGET=$(/usr/bin/gcc -dumpmachine)
	build_hpc_module compiler
	source ../scripts/compiler.sh
	set_compiler_env
	fix_lib_missing
	export PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/${HPC_TARGET}/bin:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/bin:${PATH}
	export LD_LIBRARY_PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib64:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib:${LD_LIBRARY_PATH}
	build_hpc_module ${MODULES} ${TARGET_MODULE_VERSION}
    fi

    check_and_install_gcc10
}

list_installed_module()
{
    if [ ${LIST_INSTALLED} -eq 1 ]
    then
	cat ${HPC_PREFIX}/.world
	exit 0
    fi
}

hpc_builder_help()
{
    echo "Usage: hpc_build.sh [-p PREFIX] [-c COMPILER] [-m MODULE] [-i MPI] [-M MOD_VERSION] [-l] [-L]"
    echo "Description:"
    echo "  -p PREFIX"
    echo "     specify installation prefix(default ${PREFIX})"
    echo "  -c COMPILER"
    echo "     specify HPC compilers(icc|icx|amdclang|armgcc|armclang|gcc|clang, default vendor's)"
    echo "  -i MPI"
    echo "     specify mpi(supported MPIs: openmpi|intelmpi|mpich, default=openmpi)"
    echo "  -m MODULE"
    echo "     specify module(default compiler)"
    echo "  -M MODULE_VERSION"
    echo "     specify module version"
    echo "  -l"
    echo "     list all available modules"
    echo "  -L"
    echo "     List installed modules"
    echo "  -h"
    echo "     display this page"
    exit -1
}

# default settings
PREFIX=/fsx
HPC_MPI=openmpi
LIST_MODULE=0
LIST_INSTALLED=0
HPC_MODULE=compiler
HPC_USE_VENDOR_COMPILER=true

while getopts 'p:c:m:M:i:lLh' OPT; do
    case $OPT in
        p) PREFIX="$OPTARG";;
	c) HPC_USE_VENDOR_COMPILER=false; HPC_COMPILER="$OPTARG";;
        i) HPC_MPI="$OPTARG";;
        m) HPC_MODULE="$OPTARG";;
        M) MODULE_VERSION="$OPTARG";;
	l) LIST_MODULE=1;;
	L) LIST_INSTALLED=1;;
        h) hpc_builder_help;;
        ?) hpc_builder_help;;
    esac
done

if [ "${HPC_MPI}" != "openmpi" ] && [ "${HPC_MPI}" != "mpich" ] && [ "${HPC_MPI}" != "intelmpi" ]
then
    HPC_MPI=openmpi
fi

export HPC_MPI
export HPC_COMPILER

main
 
# Changelog
# * Version 1.0 * support Amazon Linux 2 for building any WRF version on aarch64
# * Version 2.0 * add support on Intel and AMD compiler on both aarch64 and x86_64(intel)
# * Version 2.1 * fix Intel compiler dependencies
# * Version 2.2 * add WRF double precision patch
# * Version 2.3 * remove duplicated build_openmpi
# * Version 3.0 * support Amazon Linux 2022 by solving tirpc path issue
# * Version 3.1 * add command line build option 
# * Version 3.2 * support build all or just the WRF
# * Version 3.3 * add install_ncl.txt and backport tirpc support to 3.x
# * Version 3.5 * patch with FCOPTIM for fortran optimization
# * Version 3.6 * provide patches for ALL WRF versions
# * Version 3.7 * disable nproc for make avoiding build error
# * Version 3.9 * add -j WRF build info
# * Version 5.0 * remove unset_compiler_env from WRF version greater than 4.2
# * Version 5.1 * add vendor's compiler LIBRARY_PATH to LD_LIBRARY_PATH avoiding missing library from the compiler
# * Version 5.2 * add Intel icc/ifort support for all versions
# * Version 5.3 * enable Amazon EFA libfabric(OFI) support
# * Version 5.5 * automatically detect and enable Amazon EFA libfabric(OFI)
# * Version 6.0 * add Clang/ARMClang support, also add the ability to build the latest version GNU/GCC
# * Version 6.1 * remove build/host/target from packages to support all compilers, like clang/armclang
# * Version 6.2 * add armclang/clang openmpi support
# * Version 6.3 * remove flags "-march=native" for armclang/clang
# * Version 6.5 * upgrade ARM compiler to v22.1
# * Version 6.6 * fix $(which <command>), because ARM's gcc machine name is aarch64-linux-gnu, but the prefix of nm, as and ranlib is aarch64-linux-gnu-gcc
# * Version 6.7 * disable threads for the first stage of gcc compiling
# * Version 6.8 * add --with-sysroot to avoid No such file or directory of crti.o -lt  
#/${PREFIX}x86_64/tmp/${HPC_COMPILER}/x86_64-bing-linux/bin/ld: cannot find crti.o: No such file or directory
#/${PREFIX}x86_64/tmp/${HPC_COMPILER}/x86_64-bing-linux/bin/ld: cannot find -lc: No such file or directory
#/${PREFIX}x86_64/tmp/${HPC_COMPILER}/x86_64-bing-linux/bin/ld: cannot find crtn.o: No such file or directory
# * Version 6.9 * change netcdf-fortran compiler from mpicc/mpif90/mipf77 to no wrappered, Add F77 as it is required for nf_test
# * Version 7.0 * add multiple compilers support on one platform, all new program are installed into ${HPC_PREFIX}/${HPC_COMPILER}
# * Version 7.1 * add command line options parsing with getopts
# * Version 7.2 * pre-set HPC_COMPILER before set_hpc_build_env and set_compiler_env
# * Version 7.3 * acquires version # after the command line parsing
# * Version 7.5 * update history changelog
# * Version 7.6 * support parallel compiling and logging with different compilers
# * Version 7.7 * change "mpicc -cc=$(SCC)" to "mpicc" for fixing openmpi build issue
# * Version 7.8 * install env.sh and test.sh to ${PREFIX}/scripts, update test.sh to support command line option with compiler vendor
# * Version 7.9 * Amazon Linux 2 system with gcc10 installed will causing clang missing -lstdc++ and -lquadmath
# * Version 8.0 * add support for building WPS
# * Version 8.1 * add large file support set WRFIO_NCD_LARGE_FILE_SUPPORT=1
# wrf.exe: ../../libsrc/posixio.c:294: px_pgout: Assertion `*posp == OFF_NONE || *posp == lseek(nciop->fd, 0, SEEK_CUR)' failed.
#Program received signal SIGABRT: Process abort signal.
#Backtrace for this error:
#0  0x400039b4785b in ???
# ...
#14  0x400039b7c01b in nf_put_vara_real_
#        at ../../fortran/nf_varaio.F90:372
# * Version 8.2 * increase OMP_STACKSIZE to 128M to avoid segment fault for binary compiled by icc/ifort
# https://mailman.ucar.edu/pipermail/wrf-users/2016/004429.html
# https://stackoverflow.com/questions/13264274/why-segmentation-fault-is-happening-in-this-openmp-code
# * Version 8.3 * Add Intel compilers support on AMD platform
# * Version 9.0 * Rename project from WRF Builder to HPC builder, standardizes and modularizes the build procedure, add osu support
# * Version 9.1 * Support build VASP on Aarch64(with new module scalapack) and update Intel compiler to 2022.4, AMD compiler to 4.0.0
# * Version 10.0 * Refactor the application to support various MPI implementations, all new program are installed into ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} now
