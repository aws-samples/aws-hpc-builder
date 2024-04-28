#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

NETCDF_FORTRAN_VERSION=${2:-4.6.1}
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
	curl --retry 3 -JLOk "https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v${NETCDF_FORTRAN_VERSION}.tar.gz"
	return $?
    fi
}

install_netcdf_fortran()
{
    echo "zzz *** $(date) *** Build ${NETCDF_FORTRAN_SRC%.tar.gz}"
    sudo rm -rf "${NETCDF_FORTRAN_SRC%.tar.gz}" "${NETCDF_FORTRAN_SRC%.tar.gz}-build"
    tar xf "${NETCDF_FORTRAN_SRC}"

    if [ -f ../patch/netcdf-fortran/netcdf-fortran-${NETCDF_FORTRAN_VERSION}.patch ]
    then
	cd "${NETCDF_FORTRAN_SRC%.tar.gz}"
	patch -Np1 < ../../patch/netcdf-fortran/netcdf-fortran-${NETCDF_FORTRAN_VERSION}.patch
	cd ..
    fi

    mkdir -p "${NETCDF_FORTRAN_SRC%.tar.gz}-build"

    cmake -H${NETCDF_FORTRAN_SRC%.tar.gz} -B${NETCDF_FORTRAN_SRC%.tar.gz}-build \
	    -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} -DCMAKE_PREFIX_PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DBUILD_SHARED_LIBS=ON || exit 1

    cmake --build "${NETCDF_FORTRAN_SRC%.tar.gz}-build"  -j $(nproc) || exit 1

    sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB,I_MPI_CC,I_MPI_CXX,I_MPI_FC,I_MPI_F77,I_MPI_F90 env cmake --install "${NETCDF_FORTRAN_SRC%.tar.gz}-build" \
	    && sudo rm -rf "${NETCDF_FORTRAN_SRC%.tar.gz}" "${NETCDF_FORTRAN_SRC%.tar.gz}-build" || exit 1

}

update_netcdf_fortran_version()
{
    MODULE_VERSION=${NETCDF_FORTRAN_VERSION}
}
