#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#ECCODES_VERSION=git
ECCODES_VERSION=${2:-2.35.0}
DISABLE_COMPILER_ENV=false

ECCODES_SRC="eccodes-${ECCODES_VERSION}.tar.gz"

install_sys_dependency_for_eccodes()
{
    # packages for build eccodes
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

download_eccodes() {
    echo "zzz *** $(date) *** Downloading source code ${ECCODES_SRC}"
    if [ "${ECCODES_VERSION}" == "git" ]
    then
	git clone https://github.com/ecmwf/eccodes.git
	return $?
    else
        if  [ -f ${ECCODES_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://github.com/ecmwf/eccodes/archive/refs/tags/${ECCODES_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_eccodes()
{
    echo "zzz *** $(date) *** Build eccodes-${ECCODES_VERSION}"
    if [ "${ECCODES_VERSION}" == "git" ]
    then
	mv eccodes eccodes-${ECCODES_VERSION}
    else
	sudo rm -rf ${ECCODES_SRC%.tar.gz}
	tar xf ${ECCODES_SRC}
    fi

    if [ -f ../patch/eccodes/eccodes-${ECCODES_VERSION}.patch ]
    then
        cd ${ECCODES_SRC%.tar.gz}
	patch -Np1 < ../../patch/eccodes/eccodes-${ECCODES_VERSION}.patch
	cd ..
    fi

    mkdir -p "${ECCODES_SRC%.tar.gz}-build"

    export CXXFLAGS="-I ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include/jasper"
    cmake -H${ECCODES_SRC%.tar.gz} -B${ECCODES_SRC%.tar.gz}-build \
	    -DCMAKE_PREFIX_PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} || exit 1

    cmake --build "${ECCODES_SRC%.tar.gz}-build"  -j $(nproc) && \
	sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB,I_MPI_CC,I_MPI_CXX,I_MPI_FC,I_MPI_F77,I_MPI_F90 env cmake --install "${ECCODES_SRC%.tar.gz}-build"  && \
	sudo rm -rf ${ECCODES_SRC%.tar.gz}-build || exit 1
}

update_eccodes_version()
{
    MODULE_VERSION=${ECCODES_VERSION}
}
