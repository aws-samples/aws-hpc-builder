#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

NETCDF_C_VERSION=${2:-4.9.0}
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
	wget "https://downloads.unidata.ucar.edu/netcdf-c/${NETCDF_C_VERSION}/${NETCDF_C_SRC}"
	return $?
    fi
}

install_netcdf_c()
{
    echo "zzz *** $(date) *** Build ${NETCDF_C_SRC%.tar.gz}"
    sudo rm -rf "${NETCDF_C_SRC%.tar.gz}"
    tar xf "${NETCDF_C_SRC}"
    cd "${NETCDF_C_SRC%.tar.gz}"
    mkdir build
    cd build
    #cmake3 -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER} -DCMAKE_INSTALL_LIBDIR=${HPC_PREFIX}/${HPC_COMPILER}/lib ..
	    #--build=${WRF_TARGET} \
	    #--host=${WRF_TARGET} \
	    #--target=${WRF_TARGET} \
    CPPFLAGS=-I${HPC_PREFIX}/${HPC_COMPILER}/include LDFLAGS=-L${HPC_PREFIX}/${HPC_COMPILER}/lib  ../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER} \
	    --libdir=${HPC_PREFIX}/${HPC_COMPILER}/lib \
	    --enable-shared \
	    --enable-pnetcdf \
	    --enable-large-file-tests \
	    --enable-largefile  \
	    --enable-parallel-tests \
	    --enable-netcdf-4  \
	    --with-pic \
	    --disable-doxygen \
	    --disable-dap
    make
    sudo --preserve-env=PATH,LD_LIBRARY_PATH env make install
    cd ../..
}

update_netcdf_c_version()
{
    MODULE_VERSION=${NETCDF_C_VERSION}
}
