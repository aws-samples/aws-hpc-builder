#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

QD_VERSION=${2:-2.3.23}
QD_SRC=qd-${QD_VERSION}.tar.gz
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_qd()
{
    return
}

download_qd()
{
    echo "zzz *** $(date) *** Downloading source code ${QD_SRC}"
    if [ -f ${QD_SRC} ]
    then
        return
    else
         wget https://www.davidhbailey.com/dhbsoftware/${QD_SRC}
         return $?
    fi
}

install_qd()
{
    rm -rf ${QD_SRC%.tar.gz}
    tar xf ${QD_SRC}
    cd ${QD_SRC%.tar.gz}
    ./configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    make && sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB env make install
    cd ..

}

update_qd_version()
{
    MODULE_VERSION=${QD_VERSION}
}
