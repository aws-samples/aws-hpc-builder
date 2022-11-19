#!/bin/bash
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.
# SPDX-License-Identifier: MIT

fix_clang_ld()
{
    if [ "${HPC_COMPILER}" == "clang" ] || [ "${HPC_COMPILER}" == "armclang" ]
    then
        # https://github.com/Unidata/netcdf-fortran/issues/309
        sed -i -e 's/wl=""/wl="-Wl,"/g' -e 's/pic_flag=""/pic_flag="-fPIC"/g' libtool
    fi
}

fix_lib_missing()
{
    if [ "${HPC_COMPILER}" == "gcc" ]
    then
        echo "${HPC_PREFIX}/opt/gnu/lib64" > /tmp/libgfortran.conf
        sudo mv /tmp/libgfortran.conf /etc/ld.so.conf.d/
        sudo ldconfig
    elif [ "${HPC_COMPILER}" == "icc" ]
    then
        # Intel 编译器找不到 libimf 的问题: https://stackoverflow.com/questions/70687930/intel-oneapi-2022-libimf-so-no-such-file-or-directory-during-openmpi-compila
        INTEL_ICC_VERSION=$(ls -lhd ${HPC_PREFIX}/opt/intel/oneapi/compiler/latest | awk '{print $NF}')
        echo "${HPC_PREFIX}/opt/intel/oneapi/compiler/${INTEL_ICC_VERSION}/linux/compiler/lib/intel64_lin/" > /tmp/libimf.conf
        sudo mv /tmp/libimf.conf /etc/ld.so.conf.d/
        sudo ldconfig
    elif [ "${HPC_COMPILER}" == "armgcc" ]
    then
        # ARM 编译器找不到 libgfortran 的问题
        ARM_GCC_VERSION=$(module avail 2>&1 | grep -A1 "${HPC_PREFIX}" | tail -n1 | awk '{print $3}' | sed s"%gnu/%%g")
        echo "${HPC_PREFIX}/opt/gcc-${ARM_GCC_VERSION}_Generic-AArch64_RHEL-${S_VERSION_ID}_aarch64-linux/lib64/" > /tmp/libgfortran.conf
        sudo mv /tmp/libgfortran.conf /etc/ld.so.conf.d/
        sudo ldconfig
    elif [ "${HPC_COMPILER}" == "amdclang" ]
    then
	echo "${HPC_PREFIX}/opt/aocc-compiler-${AMD_COMPILER_VERSION}/lib" > /tmp/libomp.conf
	sudo mv /tmp/libomp.conf /etc/ld.so.conf.d/
	sudo ldconfig
    fi
}

check_and_uninstall_gcc10()
{
    if [ ${GCC10_INSTALLED} -eq 1 ] && ([ "${HPC_COMPILER}" == "clang" ] ||  [ "${HPC_COMPILER}" == "armclang" ])
    then
	sudo rpm -e --nodeps gcc10
    fi
}

check_and_install_gcc10()
{
    if [ ${GCC10_INSTALLED} -eq 1 ] && ([ "${HPC_COMPILER}" == "clang" ] ||  [ "${HPC_COMPILER}" == "armclang" ])
    then
	sudo yum install -y gcc10
    fi
}

validate_compiler()
{
    if [ "${SARCH}" == "x86_64" ] || [ "${SARCH}" == "amd64" ]
    then
	if [ "${HPC_COMPILER}" == "icc" ] || [ "${HPC_COMPILER}" == "icx" ] || [ "${HPC_COMPILER}" == "gcc" ] || [ "${HPC_COMPILER}" == "clang" ] || [ "${HPC_COMPILER}" == "amdclang" ]
	then
	    return
	fi
    elif [ "${SARCH}" == "aarch64" ]
    then
	if [ "${HPC_COMPILER}" == "armgcc" ] || [ "${HPC_COMPILER}" == "armclang" ] || [ "${HPC_COMPILER}" == "gcc" ] || [ "${HPC_COMPILER}" == "clang" ] 
	then
	    return
	fi
    fi
    return 1
}

# openmpi 找不到编译器, 使用全路径
use_vendor_compiler()
{
    if [ "${SARCH}" == "x86_64" ]
    then
        export FC=$(which ifort)
        export F77=$(which ifort)
        export CC=$(which icc)
        export CXX=$(which icpc)
        export AR=$(which xiar)
        #export OMPI_CC=icc
        #export OMPI_CXX=icpc
        #export OMPI_FC=ifort
    elif [ "${SARCH}" == "amd64" ]
    then
	export FC=$(which flang)
	export F77=$(which flang)
	export CC=$(which clang)
	export CXX=$(which clang++)
	export AR=$(which llvm-ar)
	export RANLIB=$(which llvm-ranlib)
	#export OMPI_CC=$(which clang)
	##export OMPI_CXX=$(which clang++)
	##export OMPI_FC=$(which flang)
    elif [ "${SARCH}" == "aarch64" ]
    then
	export FC=$(which gfortran)
	export F77=$(which gfortran)
	export CC=$(which gcc)
	export CXX=$(which g++)
	export AR=$(which $(${CC} -dumpmachine)-gcc-ar)
	export NM=$(which $(${CC} -dumpmachine)-gcc-nm)
	export RANLIB=$(which $(${CC} -dumpmachine)-gcc-ranlib)
	#export OMPI_CC=gcc
	##export OMPI_CXX=g++
	##export OMPI_FC=gfortran
    fi
}

set_compiler_env()
{
    if (! validate_compiler)
    then
	echo "Unknown compiler or unsupported compiler, please check the compiler settings"
	exit 1
    fi

    if [ "${HPC_USE_VENDOR_COMPILER}" == "false"  ]
    then
	case ${HPC_COMPILER} in
	    "gcc")
		export FC=$(which gfortran)
		export F77=$(which gfortran)
		export CC=$(which gcc)
		export CXX=$(which g++)
		export AR=$(which $(${CC} -dumpmachine)-ar)
		export NM=$(which $(${CC} -dumpmachine)-nm)
		export RANLIB=$(which $(${CC} -dumpmachine)-ranlib)
		;;
	    "clang"|"amdclang")
		export FC=$(which flang)
		export F77=$(which flang)
		export CC=$(which clang)
		export CXX=$(which clang++)
		export AR=$(which llvm-ar)
		export RANLIB=$(which llvm-ranlib)
		#export OMPI_CC=$(which clang)
		##export OMPI_CXX=$(which clang++)
		#export OMPI_FC=$(which flang)
		;;
	    "icc")
		export FC=$(which ifort)
		export F77=$(which ifort)
		export CC=$(which icc)
		export CXX=$(which icpc)
		export AR=$(which xiar)
		#export OMPI_CC=icc
		##export OMPI_CXX=icpc
		##export OMPI_FC=ifort
		;;
	    "icx")
		export FC=$(which ifx)
		export F77=$(which ifx)
		export CC=$(which icx)
		export CXX=$(which icpx)
		#export AR=$(which xiar)
		#export OMPI_CC=icc
		##export OMPI_CXX=icpc
		##export OMPI_FC=ifort
		;;
	    "armgcc")
		export FC=$(which gfortran)
		export F77=$(which gfortran)
		export CC=$(which gcc)
		export CXX=$(which g++)
		export AR=$(which $(${CC} -dumpmachine)-gcc-ar)
		export NM=$(which $(${CC} -dumpmachine)-gcc-nm)
		export RANLIB=$(which $(${CC} -dumpmachine)-gcc-ranlib)
		#export OMPI_CC=gcc
		##export OMPI_CXX=g++
		##export OMPI_FC=gfortran
		;;
	    "armclang")
		export FC=$(which armflang)
		export F77=$(which armflang)
		export CC=$(which armclang)
		export CXX=$(which armclang++)
		export AR=$(which armllvm-ar)
		export RANLIB=$(which armllvm-ranlib)
		#export OMPI_CC=gcc
		##export OMPI_CXX=g++
		##export OMPI_FC=gfortran
		;;
	esac
	return
    fi
    use_vendor_compiler
}

unset_compiler_env()
{
	unset FC
	unset F77
	unset CC
	unset CXX
	unset AR
	unset NM
	unset RANLIB
	#unset OMPI_CC
	#unset OMPI_CXX
	#unset OMPI_FC
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

export SARCH=$(uname -m)
export HPC_HOST_TARGET=$(/usr/bin/gcc -dumpmachine)

#if [ "${SARCH}" == "x86_64" ] && (sudo dmidecode -t processor | grep AMD > /dev/null)
if [ "${SARCH}" == "x86_64" ] && (grep AMD /proc/cpuinfo > /dev/null)
then
    export SARCH=amd64
fi

get_compiler

export HPC_PREFIX="${PREFIX}/${SARCH}"

if [ ! -f ${PREFIX}/${SARCH}/.world ] || (! grep -q "^${HPC_COMPILER}" ${PREFIX}/${SARCH}/.world)
then
    return
fi


case ${HPC_COMPILER} in
    "gcc"|"clang")
	export HPC_TARGET=$(${HPC_PREFIX}/opt/gnu/bin/${HPC_COMPILER} -dumpmachine)
	export LD_LIBRARY_PATH=${HPC_PREFIX}/opt/gnu/lib64:${HPC_PREFIX}/opt/gnu/lib:${LD_LIBRARY_PATH}
	export PATH=${HPC_PREFIX}/opt/gnu/${HPC_TARGET}/bin:${HPC_PREFIX}/opt/gnu/bin:${HPC_PREFIX}/${HPC_COMPILER}/bin:${PATH}
	;;
    "armgcc")
        source /etc/profile.d/modules.sh
        #module load mpi/openmpi-${SARCH}
        export MODULEPATH=${MODULEPATH}:${HPC_PREFIX}/opt/modulefiles
        module load gnu/$(ls ${HPC_PREFIX}/opt/modulefiles/gnu)
        module load armpl/$(ls ${HPC_PREFIX}/opt/moduledeps/gnu/[0-9.]*/armpl)
        #module load $(ls ${HPC_PREFIX}/opt/moduledeps/gnu/[0-9.]*/armpl/[0-9.]*)
        export HPC_TARGET=$(gcc -dumpmachine)
	;;
    "armclang")
        source /etc/profile.d/modules.sh
        #module load mpi/openmpi-${SARCH}
        export MODULEPATH=${MODULEPATH}:${HPC_PREFIX}/opt/modulefiles
	module load acfl/$(ls ${HPC_PREFIX}/opt/modulefiles/acfl)
	module load armpl/$(ls ${HPC_PREFIX}/opt/moduledeps/acfl/[0-9.]*/armpl)
        export HPC_TARGET=$(armclang -dumpmachine)

	# fix system /usr/bin/ls coudn't find crtbeginS.o etc.
	armgcc_lib_search_loc=$(dirname $(dirname $(find ${HPC_PREFIX}/opt -iname "crtbeginS.o")))
	sysgcc_lib_search_loc=$(dirname $(dirname $(sudo find /usr -iname "crtbeginS.o")))
	#sudo ln -sf ${armgcc_lib_search_loc} $(dirname ${armgcc_lib_search_loc})/${HPC_TARGET}
	sudo ln -sf ${armgcc_lib_search_loc} $(dirname ${sysgcc_lib_search_loc})/${HPC_TARGET}
	# add armgcc headers to search path
        for armgcc_dtarget in $(find ${HPC_PREFIX}/opt -iname aarch64-linux-gnu)
        do
            sudo ln -sf ${armgcc_dtarget} $(dirname ${armgcc_dtarget})/${HPC_TARGET}
        done
	;;
    "icc"|"icx")
	if [ "${HPC_MPI}" == "intelmpi" ]
	then
	    source ${HPC_PREFIX}/opt/intel/oneapi/setvars.sh
	    if [ "${HPC_COMPILER}" == "icx" ]
	    then
		export I_MPI_CC=icx
		export I_MPI_FC=ifx
		export I_MPI_CXX=ipcx
		export I_MPI_F90=ifx
		export I_MPI_F77=ifx
	    fi
	else
	    source ${HPC_PREFIX}/opt/intel/oneapi/compiler/latest/env/vars.sh
	fi
        export HPC_TARGET=$(${HPC_COMPILER} -dumpmachine)
	;;
    "amdclang")
	source ${HPC_PREFIX}/opt/setenv_AOCC.sh
	source $(ls ${HPC_PREFIX}/opt/[0-9.]*/amd-libs.cfg)
        export HPC_TARGET=$(clang -dumpmachine)
	;;
esac

export LD_LIBRARY_PATH=${LIBRARY_PATH}:${LD_LIBRARY_PATH}
