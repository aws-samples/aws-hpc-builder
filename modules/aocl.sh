#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

AMD_AOCL_VERSION=${2:-4.0}
# to build the packages in the smame host, the first part of the TARGET much compatible(identical)
TARGET=$(arch)-bing-linux
#HOST=$(gcc -dumpmachine)
#BUILD=${HOST}
#TARGET=$(gcc -### 2>&1 | grep "^Target:" | awk '{print $2}')
# **************************************

AMD_AOCL_SRC=aocl-linux-aocc-${AMD_AOCL_VERSION}.tar.gz

install_sys_dependency_for_aocl()
{
    return
}

download_aocl() {
    if [ -f ${AMD_AOCL_SRC} ]
    then
        return
    else
        echo "Please go to https://developer.amd.com/amd-aocl/#downloads , download ${AMD_AOCL_SRC} to $(pwd)/ and run the installation again" >&2
    exit 1
    fi
}


install_aocl()
{   
    if [ -f ${HPC_PREFIX}/opt/${AMD_AOCL_VERSION}/amd-libs.cfg ]
    then
        return
    fi
    tar xf ${AMD_AOCL_SRC}
    cd ${AMD_AOCL_SRC%.tar.gz}
    sudo bash ./install.sh -t ${HPC_PREFIX}/opt -i lp64
    cd ..
}

update_aocl_version()
{
    MODULE_VERSION=${AMD_AOCL_VERSION}
}
