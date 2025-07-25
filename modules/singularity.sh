#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

SINGULARITY_VERSION=${2:-3.8.7}
SINGULARITY_SRC="singularity-${SINGULARITY_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=false


install_sys_dependency_for_singularity()
{
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y update
	    sudo yum -y install golang
	    case "${S_NAME}" in
		"Alibaba Cloud Linux (Aliyun Linux)"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		    return
		    ;;
		"Amazon Linux")
		    return
		    ;;
	    esac
	    ;;
	8)
	    sudo $(dnf check-release-update 2>&1 | grep "dnf update --releasever" | tail -n1) -y 2> /dev/null
	    sudo dnf -y update
	    sudo dnf -y install golang
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
	    sudo apt-get -y install golang
	    ;;
	*)
	    exit 1
	    ;;
    esac
}

download_singularity()
{
    if [ -f ${SINGULARITY_SRC} ]
    then
        return
    else
	curl --retry 3 -JLOk "https://github.com/apptainer/singularity/archive/refs/tags/v${SINGULARITY_VERSION}.tar.gz"
	return $?
    fi
}

install_singularity()
{
    echo "zzz *** $(date) *** Build ${SINGULARITY_SRC%.tar.gz}"
    sudo rm -rf "${SINGULARITY_SRC%.tar.gz}" ${SINGULARITY_SRC%.tar.gz}-build
    tar xf "${SINGULARITY_SRC}"

    if [ -f ../patch/singularity/singularity-${JASPER_VERSION}.patch ]
    then
        cd "${SINGULARITY_SRC%.tar.gz}"
	patch -Np1 < ../../patch/singularity/singularity-${SINGULARITY_VERSION}.patch
	cd ..
    fi

    cd "${SINGULARITY_SRC%.tar.gz}"
    export GOPATH="$(pwd)/gopath"
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2> /dev/null)
    export AWS_REGION=$(curl -H "X-aws-ec2-metadata-token: ${TOKEN}" http://169.254.169.254/latest/meta-data/placement/region)

    ./mconfig --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}

    if (echo ${AWS_REGION} | grep "^cn-" > /dev/null)
    then
	export GOPROXY="https://goproxy.cn"
	sed -i s'%^GOPROXY :=.*%GOPROXY := "https://goproxy.cn"%g' builddir/Makefile
    fi

    go mod tidy

    cd builddir

    make
    sudo --preserve-env=GOPATH,GOPROXY,PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB,I_MPI_CC,I_MPI_CXX,I_MPI_FC,I_MPI_F77,I_MPI_F90 env make install \
	    && cd ../.. \
	    && sudo rm -rf ${SINGULARITY_SRC%.tar.gz} || exit 1

}

update_singularity_version()
{
    MODULE_VERSION=${SINGULARITY_VERSION}
}
