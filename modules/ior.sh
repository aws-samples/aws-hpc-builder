#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#IOR_VERSION=git
IOR_VERSION=${2:-4.0.0rc1}
DISABLE_COMPILER_ENV=false

IOR_SRC="ior-${IOR_VERSION}.tar.gz"

install_sys_dependency_for_ior()
{
    # packages for build ior
    case ${S_VERSION_ID} in
	7)
	    return
	    case  "${S_NAME}" in
		"Alibaba Cloud Linux (Aliyun Linux)"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		    return
		    ;;
		"Amazon Linux")
		    return
		    ;;
	    esac
	    ;;
	8)
	    return
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
	    return
	    ;;
	*)
	    exit 1
	    ;;
    esac
}

download_ior() {
    echo "zzz *** $(date) *** Downloading source code ${IOR_SRC}"
    if [ "${IOR_VERSION}" == "git" ]
    then
	git clone https://github.com/hpc/ior.git
	return $?
    else
        if  [ -f ${IOR_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://github.com/hpc/ior/archive/refs/tags/${IOR_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_ior()
{
    echo "zzz *** $(date) *** Build ior-${IOR_VERSION}"
    if [ "${IOR_VERSION}" == "git" ]
    then
	mv ior ior-${IOR_VERSION}
    else
	sudo rm -rf ${IOR_SRC%.tar.gz}
	tar xf ${IOR_SRC}
    fi

    cd ${IOR_SRC%.tar.gz}

    if [ -f ../../patch/ior/ior-${IOR_VERSION}.patch ]
    then
	patch -Np1 < ../../patch/ior/ior-${IOR_VERSION}.patch
    fi

    if [ -f ./bootstrap ]
    then
	./bootstrap
    fi
    export CC=$(which mpicc)
    ./configure --prefix="${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}"
    make && \
	sudo --preserve-env=PATH,LD_LIBRARY_PATH,I_MPI_CC,I_MPI_CXX,I_MPI_FC,I_MPI_F77,I_MPI_F90 env make install && \
	cd .. && \
	sudo rm -rf ${IOR_SRC%.tar.gz} || exit 1
}

update_ior_version()
{
    MODULE_VERSION=${IOR_VERSION}
}
