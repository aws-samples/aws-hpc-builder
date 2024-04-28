#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

AWS_OFI_NCCL_VERSION=${2:-1.4.0}
AWS_OFI_NCCL_SRC="aws-ofi-nccl-${AWS_OFI_NCCL_VERSION}-aws.tar.gz"
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_aws_ofi_nccl()
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

download_aws_ofi_nccl()
{
    if [ -f ${AWS_OFI_NCCL_SRC} ]
    then
        return
    else
	curl --retry 3 -JLOk "https://github.com/aws/aws-ofi-nccl/archive/refs/tags/v${AWS_OFI_NCCL_VERSION}-aws.tar.gz"
	return $?
    fi
}

install_aws_ofi_nccl()
{
    echo "zzz *** $(date) *** Build ${AWS_OFI_NCCL_SRC%-aws.tar.gz}"
    sudo rm -rf "${AWS_OFI_NCCL_SRC%.tar.gz}"
    tar xf "${AWS_OFI_NCCL_SRC}"
    cd "${AWS_OFI_NCCL_SRC%.tar.gz}"
    ./autogen.sh
    if [ -d /opt/amazon/efa ]
    then
	./configure  --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    --with-libfabric=/opt/amazon/efa \
	    --with-cuda=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/usr/local/cuda \
	    --with-nccl=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/usr/local \
	    --with-mpi=$(dirname $(dirname $(which mpirun)))
    else
	./configure  --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    --with-libfabric=/usr \
	    --with-cuda=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/usr/local/cuda \
	    --with-nccl=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/usr/local \
	    --with-mpi=$(dirname $(dirname $(which mpirun)))
    fi
    make && \
	sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB env make install && \
	cd .. && \
	sudo rm -rf "${AWS_OFI_NCCL_SRC%.tar.gz}" || exit 1
}

update_aws_ofi_nccl_version()
{
    MODULE_VERSION=${AWS_OFI_NCCL_VERSION}
}
