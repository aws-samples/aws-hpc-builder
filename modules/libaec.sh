#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#LIBAEC_VERSION=git
LIBAEC_VERSION=${2:-1.1.3}
DISABLE_COMPILER_ENV=false

LIBAEC_SRC="libaec-v${LIBAEC_VERSION}.tar.gz"

install_sys_dependency_for_libaec()
{
    # packages for build libaec
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

download_libaec() {
    echo "zzz *** $(date) *** Downloading source code ${LIBAEC_SRC}"
    if [ "${LIBAEC_VERSION}" == "git" ]
    then
	git clone https://gitlab.dkrz.de/k202009/libaec.git
	return $?
    else
        if  [ -f ${LIBAEC_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://gitlab.dkrz.de/k202009/libaec/-/archive/v${LIBAEC_VERSION}/libaec-v${LIBAEC_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_libaec()
{
    echo "zzz *** $(date) *** Build libaec-${LIBAEC_VERSION}"
    if [ "${LIBAEC_VERSION}" == "git" ]
    then
	mv libaec libaec-${LIBAEC_VERSION}
    else
	sudo rm -rf ${LIBAEC_SRC%.tar.gz}
	tar xf ${LIBAEC_SRC}
    fi

    cd ${LIBAEC_SRC%.tar.gz}

    if [ -f ../../patch/libaec/libaec-${LIBAEC_VERSION}.patch ]
    then
	patch -Np1 < ../../patch/libaec/libaec-${LIBAEC_VERSION}.patch
    fi

    mkdir build
    cd build

    cmake .. -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DCMAKE_INSTALL_LIBDIR=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib || exit 1
    cmake --build .  -j $(nproc) && \
	sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB env cmake --install . && \
	cd ../.. && \
	sudo rm -rf ${LIBAEC_SRC%.tar.gz} || exit 1
}

update_libaec_version()
{
    MODULE_VERSION=${LIBAEC_VERSION}
}
