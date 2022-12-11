#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

IMB_VERSION=${2:-2021.3}
IMB_SRC=IMB-v${IMB_VERSION}.tar.gz
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_imb()
{
    return
}

download_imb()
{
    echo "zzz *** $(date) *** Downloading source code ${IMB_SRC}"
    if [ -f ${IMB_SRC} ]
    then
        return
    else
         wget https://github.com/intel/mpi-benchmarks/archive/refs/tags/${IMB_SRC}
         return $?
    fi
}

install_imb()
{
    rm -rf mpi-benchmarks-${IMB_SRC%.tar.gz}
    tar xf ${IMB_SRC}
    cd mpi-benchmarks-${IMB_SRC%.tar.gz}
    if [ -f ../../patch/imb/imb-${IMB_VERSION}-return-value.patch ]
    then
	patch -Np1 < ../../patch/imb/imb-${IMB_VERSION}-return-value.patch
    fi
    CC=mpicc CXX=mpicxx make && cd .. && sudo mv "mpi-benchmarks-${IMB_SRC%.tar.gz}" "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/"
}

update_imb_version()
{
    MODULE_VERSION=${IMB_VERSION}
}
