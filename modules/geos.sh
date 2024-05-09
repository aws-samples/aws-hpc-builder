#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#GEOS_VERSION=git
GEOS_VERSION=${2:-3.12.1}
DISABLE_COMPILER_ENV=false

GEOS_SRC="geos-${GEOS_VERSION}.tar.bz2"

install_sys_dependency_for_geos()
{
    # packages for build geos
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

download_geos() {
    echo "zzz *** $(date) *** Downloading source code ${GEOS_SRC}"
    if [ "${GEOS_VERSION}" == "git" ]
    then
	git clone https://github.com/ecmwf/geos.git
	return $?
    else
        if  [ -f ${GEOS_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2"
	    return $?
       	fi
    fi
}

install_geos()
{
    echo "zzz *** $(date) *** Build geos-${GEOS_VERSION}"
    if [ "${GEOS_VERSION}" == "git" ]
    then
	mv geos geos-${GEOS_VERSION}
    else
	sudo rm -rf ${GEOS_SRC%.tar.bz2}
	tar xf ${GEOS_SRC}
    fi

    if [ -f ../patch/geos/geos-${GEOS_VERSION}.patch ]
    then
        cd ${GEOS_SRC%.tar.bz2}
	patch -Np1 < ../../patch/geos/geos-${GEOS_VERSION}.patch
	cd ..
    fi

    mkdir -p "${GEOS_SRC%.tar.bz2}-build"

    export CXXFLAGS="-I ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include/jasper"
    cmake -H${GEOS_SRC%.tar.bz2} -B${GEOS_SRC%.tar.bz2}-build \
	    -DCMAKE_PREFIX_PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} || exit 1

    cmake --build "${GEOS_SRC%.tar.bz2}-build"  -j $(nproc) && \
	sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB,I_MPI_CC,I_MPI_CXX,I_MPI_FC,I_MPI_F77,I_MPI_F90 env cmake --install "${GEOS_SRC%.tar.bz2}-build"  && \
	sudo rm -rf ${GEOS_SRC%.tar.bz2}-build || exit 1
}

update_geos_version()
{
    MODULE_VERSION=${GEOS_VERSION}
}
