#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#ADIOS2_VERSION=git
ADIOS2_VERSION=${2:-2.10.0}
DISABLE_COMPILER_ENV=false

ADIOS2_SRC="ADIOS2-${ADIOS2_VERSION}.tar.gz"

install_sys_dependency_for_adios2()
{
    # packages for build adios2
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

download_adios2() {
    echo "zzz *** $(date) *** Downloading source code ${ADIOS2_SRC}"
    if [ "${ADIOS2_VERSION}" == "git" ]
    then
	git clone https://github.com/ornladios/ADIOS2.git
	return $?
    else
        if  [ -f ${ADIOS2_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://github.com/ornladios/ADIOS2/archive/refs/tags/v${ADIOS2_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_adios2()
{
    echo "zzz *** $(date) *** Build adios2-${ADIOS2_VERSION}"
    if [ "${ADIOS2_VERSION}" == "git" ]
    then
	mv ADIOS2 ADIOS2-${ADIOS2_VERSION}
    else
	sudo rm -rf ${ADIOS2_SRC%.tar.gz}
	tar xf ${ADIOS2_SRC}
    fi

    if [ -f ../patch/adios2/adios2-${ADIOS2_VERSION}.patch ]
    then
        cd ${ADIOS2_SRC%.tar.gz}
	patch -Np1 < ../../patch/adios2/adios2-${ADIOS2_VERSION}.patch
	cd ..
    fi

    mkdir -p "${ADIOS2_SRC%.tar.gz}-build"

    cmake -H${ADIOS2_SRC%.tar.gz} -B${ADIOS2_SRC%.tar.gz}-build \
	    -DCMAKE_PREFIX_PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DBUILD_SHARED_LIBS=ON \
	    -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} || exit 1

    cmake --build "${ADIOS2_SRC%.tar.gz}-build"  -j $(nproc) && \
	sudo --preserve-env=PATH,LD_LIBRARY_PATH,LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB,I_MPI_ROOT,MPI_ROOT,I_MPI_CC,I_MPI_CXX,I_MPI_FC,I_MPI_F77,I_MPI_F90 env cmake --install "${ADIOS2_SRC%.tar.gz}-build"  && \
	sudo rm -rf ${ADIOS2_SRC%.tar.gz}-build || exit 1
}

update_adios2_version()
{
    MODULE_VERSION=${ADIOS2_VERSION}
}
