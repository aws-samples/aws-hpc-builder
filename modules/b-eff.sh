#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

B_EFF_VERSION=${2:-latest}
B_EFF_SRC=b_eff.c
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_b_eff()
{
    return
}

download_b_eff()
{
    echo "zzz *** $(date) *** Downloading source code ${B_EFF_SRC}"
    if [ "${B_EFF_VERSION}" == "latest" ]
    then
	rm -f ${B_EFF_SRC} b_eff
	curl --retry 3 -JLOk https://fs.hlrs.de/projects/par/mpi/b_eff/b_eff.c
	return $?
    fi

    rm -f ${B_EFF_SRC} b_eff
    curl --retry 3 -JLOk  https://fs.hlrs.de/projects/par/mpi/b_eff/b_eff_${B_EFF_VERSION}/${B_EFF_SRC}
    return $?
}

install_b_eff()
{
    mpicc -Ofast -o b_eff -D MEMORY_PER_PROCESSOR=1024 b_eff.c -lm
    sudo mkdir -p "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/b_eff-${B_EFF_VERSION}"
    sudo mv b_eff "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/b_eff-${B_EFF_VERSION}/"
}

update_b_eff_version()
{
    MODULE_VERSION=${B_EFF_VERSION}
}
