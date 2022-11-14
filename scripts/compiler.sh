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
    if [ ${USE_GNU} -eq 1 ]
    then
        echo "${HPC_PREFIX}/opt/gnu/lib64" > /tmp/libgfortran.conf
        sudo mv /tmp/libgfortran.conf /etc/ld.so.conf.d/
        sudo ldconfig
        return
    fi

    # Intel 编译器找不到 libimf 的问题: https://stackoverflow.com/questions/70687930/intel-oneapi-2022-libimf-so-no-such-file-or-directory-during-openmpi-compila
    if [ "${SARCH}" == "x86_64" ]
    then
        INTEL_ICC_VERSION=$(ls -lhd ${HPC_PREFIX}/opt/intel/oneapi/compiler/latest | awk '{print $NF}')
        echo "${HPC_PREFIX}/opt/intel/oneapi/compiler/${INTEL_ICC_VERSION}/linux/compiler/lib/intel64_lin/" > /tmp/libimf.conf
        sudo mv /tmp/libimf.conf /etc/ld.so.conf.d/
        sudo ldconfig
    # ARM 编译器找不到 libgfortran 的问题
    elif [ "${SARCH}" == "aarch64" ]
    then
        ARM_GCC_VERSION=$(module avail 2>&1 | grep -A1 "${HPC_PREFIX}" | tail -n1 | awk '{print $3}' | sed s"%gnu/%%g")
        echo "${HPC_PREFIX}/opt/gcc-${ARM_GCC_VERSION}_Generic-AArch64_RHEL-${S_VERSION_ID}_aarch64-linux/lib64/" > /tmp/libgfortran.conf
        sudo mv /tmp/libgfortran.conf /etc/ld.so.conf.d/
        sudo ldconfig
    elif [ "${SARCH}" == "amd64" ]
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

# openmpi 找不到编译器, 使用全路径
set_compiler_env()
{
    if [ ${USE_GNU} -eq 1 ]
    then
	export FC=$(which gfortran)
	export F77=$(which gfortran)
	export CC=$(which gcc)
	export CXX=$(which g++)
	export AR=$(which $(${CC} -dumpmachine)-ar)
	export NM=$(which $(${CC} -dumpmachine)-nm)
	export RANLIB=$(which $(${CC} -dumpmachine)-ranlib)
	return
    fi

    if [ "${SARCH}" == "x86_64" ]
    then
	export FC=$(which ifort)
	export F77=$(which ifort)
	export CC=$(which icc)
	export CXX=$(which icpc)
	#export OMPI_CC=icc
	#export OMPI_CXX=icpc
	#export OMPI_FC=ifort
    elif [ "${SARCH}" == "amd64" ]
    then
	if [ ${USE_INTEL_ICC} -eq 1 ]
	then
	    export FC=$(which ifort)
	    export F77=$(which ifort)
	    export CC=$(which icc)
	    export CXX=$(which icpc)
	    #export OMPI_CC=icc
	    #export OMPI_CXX=icpc
	    #export OMPI_FC=ifort
	else
	    export FC=$(which flang)
	    export F77=$(which flang)
	    export CC=$(which clang)
	    export CXX=$(which clang++)
	    export AR=$(which llvm-ar)
	    export RANLIB=$(which llvm-ranlib)
	    #export OMPI_CC=$(which clang)
	    #export OMPI_CXX=$(which clang++)
	    #export OMPI_FC=$(which flang)
	fi
    elif [ "${SARCH}" == "aarch64" ]
    then
	if [ ${USE_ARM_CLANG} -eq 1 ]
	then
	    export FC=$(which armflang)
	    export F77=$(which armflang)
	    export CC=$(which armclang)
	    export CXX=$(which armclang++)
	    export AR=$(which armllvm-ar)
	    export RANLIB=$(which armllvm-ranlib)
	    #export OMPI_CC=gcc
	    #export OMPI_CXX=g++
	    #export OMPI_FC=gfortran
        else
	    export FC=$(which gfortran)
	    export F77=$(which gfortran)
	    export CC=$(which gcc)
	    export CXX=$(which g++)
	    export AR=$(which $(${CC} -dumpmachine)-gcc-ar)
	    export NM=$(which $(${CC} -dumpmachine)-gcc-nm)
	    export RANLIB=$(which $(${CC} -dumpmachine)-gcc-ranlib)
	    #export OMPI_CC=gcc
	    #export OMPI_CXX=g++
	    #export OMPI_FC=gfortran
	fi
    fi
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
    if [ ${USE_GNU} -eq 1 ]
    then
        export HPC_COMPILER=gcc
        return
    fi

    if [ "${SARCH}" == "x86_64" ]
    then
        export HPC_COMPILER=icc
    elif [ "${SARCH}" == "amd64" ]
    then
	if [ ${USE_INTEL_ICC} -eq 1 ]
	then
            export HPC_COMPILER=icc
	else
	    export HPC_COMPILER=clang
	fi
    elif [ "${SARCH}" == "aarch64" ]
    then
        if [ ${USE_ARM_CLANG} -eq 1 ]
        then
            export HPC_COMPILER=armclang
        else
            export HPC_COMPILER=armgcc
        fi
    fi
}

export SARCH=$(uname -m)

#if [ "${SARCH}" == "x86_64" ] && (sudo dmidecode -t processor | grep AMD > /dev/null)
if [ "${SARCH}" == "x86_64" ] && (grep AMD /proc/cpuinfo > /dev/null)
then
    export SARCH=amd64
fi

get_compiler

export HPC_PREFIX="${PREFIX}/${SARCH}"

if [ ! -f ${PREFIX}/${SARCH}/.world ] || (! grep -q "${HPC_COMPILER}" ${PREFIX}/${SARCH}/.world)
then
    return
fi

if [ ${USE_GNU} -eq 1 ]
then
    if [ -f ${HPC_PREFIX}/opt/[0-9.]*/amd-libs.cfg ]
    then
        source $(ls ${HPC_PREFIX}/opt/[0-9.]*/amd-libs.cfg)
    fi
    export HPC_TARGET=$(${HPC_PREFIX}/opt/gnu/bin/gcc -dumpmachine)
    export LD_LIBRARY_PATH=${HPC_PREFIX}/opt/gnu/lib64:${HPC_PREFIX}/opt/gnu/lib:${LD_LIBRARY_PATH}
    export PATH=${HPC_PREFIX}/opt/gnu/${HPC_TARGET}/bin:${HPC_PREFIX}/opt/gnu/bin:${HPC_PREFIX}/${HPC_COMPILER}/bin:${PATH}
else
    if [ "${SARCH}" == "aarch64" ]
    then
        source /etc/profile.d/modules.sh
        #module load mpi/openmpi-${SARCH}
        export MODULEPATH=${MODULEPATH}:${HPC_PREFIX}/opt/modulefiles
        module load $(module avail 2>&1 | grep -A1 "${HPC_PREFIX}" | tail -n1)
        export HPC_TARGET=$(gcc -dumpmachine)
    elif [ "${SARCH}" == "x86_64" ]
    then
	if [ ${USE_INTEL_MPI} -eq 1 ]
	then
	    source ${HPC_PREFIX}/opt/intel/oneapi/setvars.sh
	else
	    source ${HPC_PREFIX}/opt/intel/oneapi/compiler/latest/env/vars.sh
	fi
        export HPC_TARGET=$(icc -dumpmachine)
    elif [ "${SARCH}" == "amd64" ]
    then
	if [ ${USE_INTEL_ICC} -eq 1 ]
	then
	    if [ ${USE_INTEL_MPI} -eq 1 ]
	    then
	        source ${HPC_PREFIX}/opt/intel/oneapi/setvars.sh
	    else
	        source ${HPC_PREFIX}/opt/intel/oneapi/compiler/latest/env/vars.sh
	    fi
            export HPC_TARGET=$(icc -dumpmachine)
	else
	    source ${HPC_PREFIX}/opt/setenv_AOCC.sh
	    source $(ls ${HPC_PREFIX}/opt/[0-9.]*/amd-libs.cfg)
	fi
    fi
    export LD_LIBRARY_PATH=${LIBRARY_PATH}:${LD_LIBRARY_PATH}
fi
