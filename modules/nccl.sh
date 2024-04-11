#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

NCCL_VERSION=${2:-2.16.2-1}
NCCL_SRC="nccl-${NCCL_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_nccl()
{
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y update
	    case  "${S_NAME}" in
		"Alibaba Cloud Linux (Aliyun Linux)"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		    sudo yum -y install libfabric libfabric-devel rdma-core-devel librdmacm-utils libpsm2-devel infinipath-psm-devel libibverbs-utils libnl3 libnl3-devel python3
		    ;;
		"Amazon Linux")
		    sudo yum -y install libfabric libfabric-devel rdma-core-devel librdmacm-utils libibverbs-utils libnl3 libnl3-devel python3
		    ;;
	    esac
	    ;;
	8)
	    sudo $(dnf check-release-update 2>&1 | grep "dnf update --releasever" | tail -n1) -y 2> /dev/null
	    sudo dnf -y update
	    sudo dnf -y install libfabric libfabric-devel rdma-core-devel librdmacm-utils libibverbs-utils libnl3 libnl3-devel python3
	    case  "${S_NAME}" in
		"Alibaba Cloud Linux"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		    return
		    ;;
		"Amazon Linux")
		    return
		    ;;
	    esac
	    ;;
	18|20)
	    sudo apt-get -y update
	    sudo apt-get -y install python3
	    ;;
	*)
	    exit 1
	    ;;
    esac
}

download_nccl()
{
    if [ -f ${NCCL_SRC} ]
    then
        return
    else
	curl --retry 3 -JLOk "https://github.com/NVIDIA/nccl/archive/refs/tags/v${NCCL_VERSION}.tar.gz"
	return $?
    fi
}

install_nccl()
{
    echo "zzz *** $(date) *** Build ${NCCL_SRC%.tar.gz}"
    sudo rm -rf "${NCCL_SRC%.tar.gz}"
    tar xf "${NCCL_SRC}"
    cd "${NCCL_SRC%.tar.gz}"
    export PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB,PREFIX make src.install \
	CUDA_HOME=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/usr/local/cuda && \
	cd ..
}

update_nccl_version()
{
    MODULE_VERSION=${NCCL_VERSION}
}
