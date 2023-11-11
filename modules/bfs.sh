#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2023 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

BFS_VERSION=${2:-3.0.1}
BFS_SRC=graph500-${BFS_VERSION}.tar.gz
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_bfs()
{
    return
}

download_bfs()
{
    echo "zzz *** $(date) *** Downloading source code ${BFS_SRC}"
    if [ -f ${BFS_SRC} ]
    then
        return
    else
	 curl -JLOk https://github.com/graph500/graph500/archive/refs/tags/${BFS_VERSION}.tar.gz
         return $?
    fi
}

install_bfs()
{
    rm -rf ${BFS_SRC%.tar.gz}
    tar xf ${BFS_SRC}
    cd ${BFS_SRC%.tar.gz}
    if [ -f ../../patch/bfs/bfs-${BFS_VERSION}-return-value.patch ]
    then
	patch -Np1 < ../../patch/bfs/bfs-${BFS_VERSION}-return-value.patch
    fi
    cd src
    make graph500_reference_bfs
    sudo install -m 755 -D -t ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} ./graph500_reference_bfs
}

update_bfs_version()
{
    MODULE_VERSION=${BFS_VERSION}
}
