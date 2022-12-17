#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

NETCDF_FORTRAN_VERSION=${2:-4.5.4}
NETCDF_FORTRAN_SRC="netcdf-fortran-${NETCDF_FORTRAN_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_netcdf_fortran()
{
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y update
	    case  "${S_NAME}" in
		"Alibaba Cloud Linux (Aliyun Linux)"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		    return
		    ;;
		"Amazon Linux")
		    return
		    ;;
	    esac
	    ;;
	8)
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
	    ;;
	18|20)
	    sudo apt-get -y update
	    ;;
	*)
	    exit 1
	    ;;
    esac
}

download_netcdf_fortran() {
    if [ -f ${NETCDF_FORTRAN_SRC} ]
    then
	return
    else
	wget "https://downloads.unidata.ucar.edu/netcdf-fortran/${NETCDF_FORTRAN_VERSION}/${NETCDF_FORTRAN_SRC}"
	return $?
    fi
}

install_netcdf_fortran()
{
    echo "zzz *** $(date) *** Build ${NETCDF_FORTRAN_SRC%.tar.gz}"
    sudo rm -rf "${NETCDF_FORTRAN_SRC%.tar.gz}"
    tar xf "${NETCDF_FORTRAN_SRC}"
    cd "${NETCDF_FORTRAN_SRC%.tar.gz}"
    mkdir build
    cd build
	    #--build=${WRF_TARGET} \
	    #--host=${WRF_TARGET} \
	    #--target=${WRF_TARGET} \
    #CC=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/bin/mpicc FC=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/bin/mpif90 F77=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/bin/mpif77 \
    CPPFLAGS=-I${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include LDFLAGS=-L${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib \
    ../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
            --libdir=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib \
            --enable-shared
    fix_clang_ld
    make check
    sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB,CPPFLAGS,LDFLAGS env make install
    cd ../..
}

update_netcdf_fortran_version()
{
    MODULE_VERSION=${NETCDF_FORTRAN_VERSION}
}
