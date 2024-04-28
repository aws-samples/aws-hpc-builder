#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2023 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

FFTW_VERSION=${2:-3.3.10}
FFTW_SRC="fftw-${FFTW_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_fftw()
{
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y update
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

download_fftw() {
    echo "zzz *** $(date) *** Downloading source code ${FFTW_SRC}"
    if [ -f ${FFTW_SRC} ]
    then
        return
    else
	curl --retry 3 -JLOk https://fftw.org/pub/fftw/fftw-${FFTW_VERSION}.tar.gz
	return $?
    fi
}

install_fftw()
{
    sudo rm -rf "${FFTW_SRC%.tar.gz}"
    tar xf "${FFTW_SRC}"
    cd "${FFTW_SRC%.tar.gz}"
    ./configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} --enable-shared --enable-openmp --enable-mpi
    make -j$(nproc) && \
	sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB env make install && \
	cd .. && \
	sudo rm -rf "${FFTW_SRC%.tar.gz}" || exit 1
}

update_fftw_version()
{
    MODULE_VERSION=${FFTW_VERSION}
}
