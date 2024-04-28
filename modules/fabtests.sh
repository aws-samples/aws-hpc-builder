#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

FABTESTS_VERSION=${2:-1.16.1}
FABTESTS_SRC="libfabric-${FABTESTS_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_fabtests()
{
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y update
	    case  "${S_NAME}" in
		"Alibaba Cloud Linux (Aliyun Linux)"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		    sudo yum -y install libfabric libfabric-devel rdma-core-devel librdmacm-utils libpsm2-devel infinipath-psm-devel libibverbs-utils libnl3 libnl3-devel python3
		    ;;
		"Amazon Linux")
		    sudo yum -y install libfabric libfabric-devel rdma-core-devel librdmacm-utils libpsm2-devel infinipath-psm-devel libibverbs-utils libnl3 libnl3-devel python3
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

download_fabtests() {
    echo "zzz *** $(date) *** Downloading source code ${FABTESTS_SRC}"
    if [ -f ${FABTESTS_SRC} ]
    then
        return
    else
	curl --retry 3 -JLOk "https://github.com/ofiwg/libfabric/archive/refs/tags/v${FABTESTS_VERSION}.tar.gz"
	return $?
    fi
}

install_fabtests()
{
    sudo rm -rf "${FABTESTS_SRC%.tar.gz}"
    tar xf "${FABTESTS_SRC}"
    cd "${FABTESTS_SRC%.tar.gz}/fabtests"

    ./autogen.sh

    if [ -d /opt/amazon/efa ]
    then
	./configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    --with-libfabric=/opt/amazon/efa
    else
	./configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    --with-libfabric=/usr
    fi
    result=$?
    if [ $result -ne 0 ]
    then
        return  $result
    fi
    make && \
	sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB,FFLAGS,FCFLAGS env make install && \
	cd ../.. && \
	sudo rm -rf "${FABTESTS_SRC%.tar.gz} || exit 1
}

update_fabtests_version()
{
    MODULE_VERSION=${FABTESTS_VERSION}
}
