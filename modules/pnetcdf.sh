#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

PNETCDF_VERSION=${2:-1.12.3}
PNETCDF_SRC="pnetcdf-${PNETCDF_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=true

install_sys_dependency_for_pnetcdf()
{
    if [ ${S_VERSION_ID} -eq 7 ]
    then
	sudo yum -y update
	case  "${S_NAME}" in
	    "Alibaba Cloud Linux (Aliyun Linux)"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		return
		;;
	    "Amazon Linux")
		return
		;;
	esac
    elif [ ${S_VERSION_ID} -eq 8 ]
    then
	sudo $(dnf check-release-update 2>&1 | grep "dnf update --releasever" | tail -n1) -y 2> /dev/null
       	sudo dnf -y update
	case  "${S_NAME}" in
	    "Alibaba Cloud Linux"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		return
		;;
	    "Amazon Linux")
		return
		;;
	esac
    else
	exit 1
    fi
}

download_pnetcdf() {
    echo "zzz *** $(date) *** Downloading source code ${PNETCDF_SRC}"
    if [ -f ${PNETCDF_SRC} ]
    then
	return
    else
	wget "https://parallel-netcdf.github.io/Release/${PNETCDF_SRC}"
	return $?
    fi
}


install_pnetcdf()
{
    sudo rm -rf "${PNETCDF_SRC%.tar.gz}"
    tar xf "${PNETCDF_SRC}"
    cd "${PNETCDF_SRC%.tar.gz}"
    mkdir -p build
    cd build
    # pnetcdf has to disable compiler env
    # pnetcdf 要设置mpicc等，或者取消掉CC 等环境变量设置
    #configure: error:
    #-----------------------------------------------------------------------
    # Invalid MPI compiler specified or detected: "/fsx/wrf-aarch64/opt/arm-linux-compiler-22.1_Generic-AArch64_RHEL-7_aarch64-linux/bin/armclang"
    # A working MPI C compiler is required. Please specify the location
    # of one either in the MPICC environment variable (not CC variable) or
    # through --with-mpi configure flag. Abort.
    #-----------------------------------------------------------------------
	    #--build=${HPC_TARGET} \
	    #--host=${HPC_TARGET} \
	    #--target=${HPC_TARGET} \
    ../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    --enable-fortran \
            --enable-shared && fix_clang_ld 
    make && sudo --preserve-env=PATH,LD_LIBRARY_PATH env make install && cd ../..
}

update_pnetcdf_version()
{
    MODULE_VERSION=${PNETCDF_VERSION}
}
