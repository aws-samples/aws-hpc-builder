#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

JASPER_VERSION=${2:-2.0.33}
JASPER_SRC="jasper-${JASPER_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=false


install_sys_dependency_for_jasper()
{
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y update
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

download_jasper()
{
    if [ -f ${JASPER_SRC} ]
    then
        return
    else
	curl --retry 3 -JLOk "https://github.com/jasper-software/jasper/releases/download/version-${JASPER_VERSION}/jasper-${JASPER_VERSION}.tar.gz"
	return $?
    fi
}

install_jasper()
{
    echo "zzz *** $(date) *** Build ${JASPER_SRC%.tar.gz}"
    sudo rm -rf "${JASPER_SRC%.tar.gz}" "${JASPER_SRC%.tar.gz}-build"
    tar xf "${JASPER_SRC}"

    if [ -f ../../patch/jasper/jasper-${JASPER_VERSION}.patch ]
    then
	cd  "${JASPER_SRC%.tar.gz}"
	patch -Np1 < ../../patch/jasper/jasper-${JASPER_VERSION}.patch
       	cd ..
    fi

    mkdir -p "${JASPER_SRC%.tar.gz}-build"
    cmake -H${JASPER_SRC%.tar.gz} -B${JASPER_SRC%.tar.gz}-build \
	    -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DCMAKE_PREFIX_PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DJAS_ENABLE_DOC=false || exit 1

    cmake --build "${JASPER_SRC%.tar.gz}-build"  -j $(nproc) || exit 1

    sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB,I_MPI_CC,I_MPI_CXX,I_MPI_FC,I_MPI_F77,I_MPI_F90 env cmake --install "${JASPER_SRC%.tar.gz}-build" && \
	sudo rm -rf ${JASPER_SRC%.tar.gz} ${JASPER_SRC%.tar.gz}-build || exit 1

}

update_jasper_version()
{
    MODULE_VERSION=${JASPER_VERSION}
}
