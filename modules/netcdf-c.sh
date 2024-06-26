#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

NETCDF_C_VERSION=${2:-4.9.2}
NETCDF_C_SRC="netcdf-c-${NETCDF_C_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_netcdf_c()
{
    return
}

download_netcdf_c() {
    if [ -f ${NETCDF_C_SRC} ]
    then
	return
    else
	curl --retry 3 -JLOk "https://downloads.unidata.ucar.edu/netcdf-c/${NETCDF_C_VERSION}/${NETCDF_C_SRC}"
	return $?
    fi
}

install_netcdf_c()
{
    echo "zzz *** $(date) *** Build ${NETCDF_C_SRC%.tar.gz}"
    sudo rm -rf "${NETCDF_C_SRC%.tar.gz}"
    tar xf "${NETCDF_C_SRC}"
    cd "${NETCDF_C_SRC%.tar.gz}"

    if [ -f ../../patch/netcdf-c/netcdf-c-$(arch)-${HPC_COMPILER}.patch ]
    then
        patch -Np1 < ../../patch/netcdf-c/netcdf-c-$(arch)-${HPC_COMPILER}.patch
    fi

    mkdir build
    cd build
    #cmake3 -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} -DCMAKE_INSTALL_LIBDIR=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib ..
	    #--build=${HPC_TARGET} \
	    #--host=${HPC_TARGET} \
	    #--target=${HPC_TARGET} \
    CPPFLAGS=-I${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include LDFLAGS=-L${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib  ../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    --libdir=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib \
	    --enable-shared \
	    --enable-pnetcdf \
	    --enable-large-file-tests \
	    --enable-largefile  \
	    --enable-parallel-tests \
	    --disable-netcdf-4  \
	    --with-pic \
	    --disable-doxygen \
	    --disable-dap
    make && \
	sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB,CPPFLAGS,LDFLAGS make install && \
	cd ../.. && \
	sudo rm -rf "${NETCDF_C_SRC%.tar.gz}" || exit 1
}

update_netcdf_c_version()
{
    MODULE_VERSION=${NETCDF_C_VERSION}
}
