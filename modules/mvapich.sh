#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

# to support efa version must be 3.0a+
MVAPICH_VERSION=${2:-3.0rc}
MVAPICH_SRC="mvapich2-${MVAPICH_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_mvapich()
{
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y update
	    case  "${S_NAME}" in
		"Alibaba Cloud Linux (Aliyun Linux)"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		    sudo yum -y install libfabric libfabric-devel rdma-core-devel librdmacm-utils libpsm2-devel infinipath-psm-devel libibverbs-utils libnl3 libnl3-devel
		    ;;
		"Amazon Linux")
		    sudo yum -y install libfabric libfabric-devel
		    return
		    ;;
	    esac
	    ;;
	8)
	    sudo $(dnf check-release-update 2>&1 | grep "dnf update --releasever" | tail -n1) -y 2> /dev/null
	    sudo dnf -y update
	    sudo dnf -y install libfabric libfabric-devel
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

download_mvapich() {
    echo "zzz *** $(date) *** Downloading source code ${MVAPICH_SRC}"
    if [ -f ${MVAPICH_SRC} ]
    then
        return
    else
	curl --retry 3 -JLOk https://mvapich.cse.ohio-state.edu/download/mvapich/mv2/${MVAPICH_SRC}
	return $?
    fi
}

install_mvapich()
{
    if [ ${HPC_MPI} != "mvapich" ]
    then
        echo "Current MPI is not mvapich, installation stopped" 1>&2
        return 1
    fi

    sudo rm -rf "${MVAPICH_SRC%.tar.gz}"
    tar xf "${MVAPICH_SRC}"
    cd "${MVAPICH_SRC%.tar.gz}"
    mkdir -p build
    cd build
    if [ -d /opt/amazon/efa ]
    then
	    #--build=${HPC_TARGET} \
	    #--host=${HPC_TARGET} \
	    #--target=${HPC_TARGET} \
	if [ "$(basename ${FC})" == "gfortran" ]
	then
	    # a mvapich bug, have to remove the space between ch4:ofi and "\"
	    FFLAGS=-fallow-argument-mismatch FCFLAGS=-fallow-argument-mismatch ../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
		--with-device=ch4:ofi\
		--with-libfabric=/opt/amazon/efa
        else
	    ../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
		--with-device=ch4:ofi\
		--with-libfabric=/opt/amazon/efa
	fi
    else
	if [ "$(basename ${FC})" == "gfortran" ]
	then
	    FFLAGS=-fallow-argument-mismatch FCFLAGS=-fallow-argument-mismatch ../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
		--with-device=ch4:ofi
	else
	    ../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
		--with-device=ch4:ofi
	fi
    fi
    result=$?
    if [ $result -ne 0 ]
    then
        return  $result
    fi
    make && \
	sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB,FFLAGS,FCFLAGS env make install && \
	cd ../.. && \
	sudo rm -rf "${MVAPICH_SRC%.tar.gz}" || exit 1
}

update_mvapich_version()
{
    MODULE_VERSION=${MVAPICH_VERSION}
}
