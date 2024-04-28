#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

GPCNET_VERSION=${2:-git}
GPCNET_SRC=GPCNET-${GPCNET_VERSION}.tar.gz
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_gpcnet()
{
    return
}

download_gpcnet()
{
    echo "zzz *** $(date) *** Downloading source code ${GPCNET_SRC}"
    if [ "${GPCNET_VERSION}" == "git" ]
    then
	rm -rf GPCNET
	git clone https://github.com/netbench/GPCNET.git
	return $?
    fi

    if [ -f ${GPCNET_SRC} ]
    then
        return
    else
	 curl --retry 3 -JLOk https://github.com/netbench/GPCNET/archive/refs/tags/${GPCNET_VERSION}.tar.gz
         return $?
    fi
}

install_gpcnet()
{
    if [ "${GPCNET_VERSION}" == "git" ]
    then
	cd GPCNET
    else
	sudo rm -rf ${GPCNET_SRC%.tar.gz}
	tar xf ${GPCNET_SRC}
	cd ${GPCNET_SRC%.tar.gz}
    fi
    make all CC=mpicc CXX=mpicxx && cd .. &&  \
	if [ "${GPCNET_VERSION}" == "git" ]
	then
	    sudo mv GPCNET "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/GPCNET-${GPCNET_VERSION}"
	else
	    sudo mv "${GPCNET_SRC%.tar.gz}" "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/GPCNET-${GPCNET_VERSION}"
	fi && \
	    sudo rm -rf ${GPCNET_SRC%.tar.gz} || exit 1
}

update_gpcnet_version()
{
    MODULE_VERSION=${GPCNET_VERSION}
}
