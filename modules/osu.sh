#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

OSU_VERSION=${2:-6.1}
OSU_SRC=osu-micro-benchmarks-${OSU_VERSION}.tar.gz
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_osu()
{
    return
}

download_osu()
{
    echo "zzz *** $(date) *** Downloading source code ${OSU_SRC}"
    if [ -f ${OSU_SRC} ]
    then
        return
    else
         wget https://mvapich.cse.ohio-state.edu/download/mvapich/${OSU_SRC}
         return $?
    fi
}

install_osu()
{
    rm -rf ${OSU_SRC%.tar.gz}
    tar xf ${OSU_SRC}
    cd ${OSU_SRC%.tar.gz}
    if [ -f ../../patch/osu/osu-${OSU_VERSION}-return-value.patch ]
    then
	patch -Np1 < ../../patch/osu/osu-${OSU_VERSION}-return-value.patch
    fi
    ./configure CC=mpicc CXX=mpicxx
    make && cd .. && sudo mv "${OSU_SRC%.tar.gz}" "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/"
}

update_osu_version()
{
    MODULE_VERSION=${OSU_VERSION}
}
