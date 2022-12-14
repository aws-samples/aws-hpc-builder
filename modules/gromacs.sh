#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

GROMACS_VERSION=${2:-2022.4}
GROMACS_SRC=gromacs-${GROMACS_VERSION}.tar.gz
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_gromacs()
{
    return
}

download_gromacs()
{
    echo "zzz *** $(date) *** Downloading source code ${GROMACS_SRC}"
    if [ -f ${GROMACS_SRC} ]
    then
        return
    else
         wget https://ftp.gromacs.org/gromacs/${GROMACS_SRC}
         return $?
    fi
}

install_gromacs()
{
    rm -rf ${GROMACS_SRC%.tar.gz}
    tar xf ${GROMACS_SRC}
    cd ${GROMACS_SRC%.tar.gz}
    if [ -f ../../patch/gromacs/gromacs-${GROMACS_VERSION}-${HPC_COMPILER}-${HPC_MPI}.patch ]
    then
	patch -Np1 < ../../patch/gromacs/gromacs-${GROMACS_VERSION}-${HPC_COMPILER}-${HPC_MPI}.patch
    fi
    mkdir -p build
    cd build
    if [ "${HPC_COMPILER}" == "nvc" ]
    then
	cmake .. -DCMAKE_C_COMPILER=${CC} \
	    -DCMAKE_CXX_COMPILER=${CXX} \
	    -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DGMX_BUILD_OWN_FFTW=ON \
	    -DGMX_MPI=ON -DGMX_MP=ON \
	    -DGMX_GPU=CUDA
    else
	cmake .. -DCMAKE_C_COMPILER=${CC} \
	    -DCMAKE_CXX_COMPILER=${CXX} \
	    -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DGMX_BUILD_OWN_FFTW=ON \
	    -DGMX_MPI=ON -DGMX_MP=ON
    fi
    make && sudo --preserve-env=PATH,LD_LIBRARY_PATH env make install && cd ../..
}

update_gromacs_version()
{
    MODULE_VERSION=${GROMACS_VERSION}
}
