#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

CUDA_VERSION=${2:-12.0.0_525.60.13}
if [ "$(arch)" == "aarch64" ]
then
    CUDA_SRC="cuda_${CUDA_VERSION}_linux_sbsa.run"
elif [ "$(arch)" == "x86_64" ]
then
    CUDA_SRC="cuda_${CUDA_VERSION}_linux.run"
fi

DISABLE_COMPILER_ENV=false

install_sys_dependency_for_cuda()
{
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y update
	    case  "${S_NAME}" in
		"Alibaba Cloud Linux (Aliyun Linux)"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		    sudo yum -y install kernel-devel-$(uname -r) kernel-headers-$(uname -r)
		    ;;
		"Amazon Linux")
		    sudo yum -y install kernel-devel-$(uname -r) kernel-headers-$(uname -r)
		    ;;
	    esac
	    ;;
	8)
	    sudo $(dnf check-release-update 2>&1 | grep "dnf update --releasever" | tail -n1) -y 2> /dev/null
	    sudo dnf -y update
	    sudo dnf -y install kernel-devel-$(uname -r) kernel-headers-$(uname -r)
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
	    sudo apt-get install linux-headers-$(uname -r)
	    ;;
	*)
	    exit 1
	    ;;
    esac
}

download_cuda() {
    echo "zzz *** $(date) *** Downloading source code ${CUDA_SRC}"
    if [ -f ${CUDA_SRC} ]
    then
        return
    else
	curl --retry 3 -JLOk "https://developer.download.nvidia.com/compute/cuda/$(echo ${CUDA_VERSION} | cut -d_ -f1)/local_installers/${CUDA_SRC}"
	return $?
    fi
}

install_cuda()
{
    export IGNORE_CC_MISMATCH=1
    sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,IGNORE_CC_MISMATCH bash ${CUDA_SRC} \
	--silent --override \
	--toolkitpath=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/usr/local/cuda-$(echo ${CUDA_VERSION} | cut -d. -f1)
    sudo ln -sfn ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/usr/local/cuda-$(echo ${CUDA_VERSION} | cut -d. -f1) ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/usr/local/cuda
}

update_cuda_version()
{
    MODULE_VERSION=${CUDA_VERSION}
}
