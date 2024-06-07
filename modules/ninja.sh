#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#NINJA_VERSION=git
NINJA_VERSION=${2:-1.12.1}
DISABLE_COMPILER_ENV=false

NINJA_SRC="ninja-${NINJA_VERSION}.tar.gz"

install_sys_dependency_for_ninja()
{
    # packages for build ninja
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

download_ninja() {
    echo "zzz *** $(date) *** Downloading source code ${NINJA_SRC}"
    if [ "${NINJA_VERSION}" == "git" ]
    then
	git clone https://github.com/ninja-build/ninja.git
	return $?
    else
        if  [ -f ${NINJA_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://github.com/ninja-build/ninja/archive/refs/tags/v${NINJA_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_ninja()
{
    echo "zzz *** $(date) *** Build ninja-${NINJA_VERSION}"
    if [ "${NINJA_VERSION}" == "git" ]
    then
	mv ninja ninja-${NINJA_VERSION}
    else
	sudo rm -rf ${NINJA_SRC%.tar.gz}
	tar xf ${NINJA_SRC}
    fi

    if [ -f ../patch/ninja/ninja-${NINJA_VERSION}.patch ]
    then
        cd ${NINJA_SRC%.tar.gz}
	patch -Np1 < ../../patch/ninja/ninja-${NINJA_VERSION}.patch
	cd ..
    fi

    mkdir -p "${NINJA_SRC%.tar.gz}-build"

    cmake -H${NINJA_SRC%.tar.gz} -B${NINJA_SRC%.tar.gz}-build \
	    -DCMAKE_PREFIX_PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DBUILD_SHARED_LIBS=ON \
	    -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DCMAKE_BUILD_TYPE=Release || exit 1

    cmake --build "${NINJA_SRC%.tar.gz}-build"  -j $(nproc) && \
	sudo --preserve-env=PATH,LD_LIBRARY_PATH,LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB,I_MPI_ROOT,MPI_ROOT,I_MPI_CC,I_MPI_CXX,I_MPI_FC,I_MPI_F77,I_MPI_F90 env cmake --install "${NINJA_SRC%.tar.gz}-build"  && \
	sudo rm -rf ${NINJA_SRC%.tar.gz}-build || exit 1
}

update_ninja_version()
{
    MODULE_VERSION=${NINJA_VERSION}
}
