#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#PROJ_VERSION=git
PROJ_VERSION=${2:-9.4.0}
DISABLE_COMPILER_ENV=false

PROJ_SRC="PROJ-${PROJ_VERSION}.tar.gz"

install_sys_dependency_for_proj()
{
    # packages for build proj
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y install libtiff-devel
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
	    sudo dnf -y install libtiff-devel
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
	    sudo apt-get -y install libtiff-dev
	    return
	    ;;
	*)
	    exit 1
	    ;;
    esac
}

download_proj() {
    echo "zzz *** $(date) *** Downloading source code ${PROJ_SRC}"
    if [ "${PROJ_VERSION}" == "git" ]
    then
	git clone https://github.com/OSGeo/PROJ.git
	return $?
    else
        if  [ -f ${PROJ_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://github.com/OSGeo/PROJ/archive/refs/tags/${PROJ_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_proj()
{
    echo "zzz *** $(date) *** Build proj-${PROJ_VERSION}"
    if [ "${PROJ_VERSION}" == "git" ]
    then
	mv PROJ PROJ-${PROJ_VERSION}
    else
	sudo rm -rf ${PROJ_SRC%.tar.gz}
	tar xf ${PROJ_SRC}
    fi

    cd ${PROJ_SRC%.tar.gz}

    if [ -f ../../patch/proj/proj-${PROJ_VERSION}.patch ]
    then
	patch -Np1 < ../../patch/proj/proj-${PROJ_VERSION}.patch
    fi

    mkdir build
    cd build

    cmake .. -Wno-dev \
	    -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}  \
	    -DCMAKE_PREFIX_PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DCMAKE_INSTALL_LIBDIR=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib  && \
	    cmake --build .  -j $(nproc)  && \
	    sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB env cmake --install . && \
	    cd ../.. && \
	    sudo rm -rf ${PROJ_SRC%.tar.gz} || exit 1
}

update_proj_version()
{
    MODULE_VERSION=${PROJ_VERSION}
}
