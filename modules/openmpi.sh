#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

OPENMPI_VERSION=${2:-4.1.6}
OPENMPI_SRC="openmpi-${OPENMPI_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_openmpi()
{
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y update
	    case  "${S_NAME}" in
		"Alibaba Cloud Linux (Aliyun Linux)"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		    sudo yum -y install libfabric libfabric-devel rdma-core-devel librdmacm-utils libpsm2-devel infinipath-psm-devel libibverbs-utils libnl3 libnl3-devel
		    ;;
		"Amazon Linux")
		    sudo yum -y install libfabric libfabric-devel rdma-core-devel librdmacm-utils libpsm2-devel infinipath-psm-devel libibverbs-utils libnl3 libnl3-devel
		    ;;
	    esac
	    ;;
	8)
	    sudo $(dnf check-release-update 2>&1 | grep "dnf update --releasever" | tail -n1) -y 2> /dev/null
	    sudo dnf -y update
	    sudo dnf -y install libfabric libfabric-devel rdma-core-devel librdmacm-utils libibverbs-utils libnl3 libnl3-devel
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
	    ;;
	*)
	    exit 1
	    ;;
    esac
}

download_openmpi() {
    echo "zzz *** $(date) *** Downloading source code ${OPENMPI_SRC}"
    if [ -f ${OPENMPI_SRC} ]
    then
        return
    else
	curl -JLOk "https://download.open-mpi.org/release/open-mpi/v${OPENMPI_VERSION%.*}/${OPENMPI_SRC}"
	return $?
    fi
}

install_openmpi()
{
    if [ ${HPC_MPI} != "openmpi" ]
    then
	echo "Current MPI is not openmpi, installation stopped" 1>&2
	return 1
    fi
    
    sudo rm -rf "${OPENMPI_SRC%.tar.gz}"
    tar xf "${OPENMPI_SRC}"
    cd "${OPENMPI_SRC%.tar.gz}"
    mkdir -p build
    cd build
    if [ -d /opt/amazon/efa ]
    then
	    #--build=${HPC_TARGET} \
	    #--host=${HPC_TARGET} \
	    #--target=${HPC_TARGET} \
	../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    --enable-orterun-prefix-by-default \
            --enable-wrapper-rpath \
	    --with-ofi=/opt/amazon/efa
    else
	    #--build=${HPC_TARGET} \
	    #--host=${HPC_TARGET} \
	    #--target=${HPC_TARGET}
	../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    --enable-orterun-prefix-by-default \
            --enable-wrapper-rpath
    fi
    result=$?
    if [ $result -ne 0 ]
    then
        return  $result
    fi
    make && sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB env make install && cd ../..
}

update_openmpi_version()
{
    MODULE_VERSION=${OPENMPI_VERSION}
}
