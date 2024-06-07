#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#CCMIO_VERSION=git
CCMIO_VERSION=${2:-2.6.1}
DISABLE_COMPILER_ENV=false

CCMIO_SRC="libccmio-${CCMIO_VERSION}.tar.gz"

install_sys_dependency_for_ccmio()
{
    # packages for build ccmio
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

download_ccmio() {
    echo "zzz *** $(date) *** Downloading source code ${CCMIO_SRC}"
    if [ "${CCMIO_VERSION}" == "git" ]
    then
	git clone https://github.com/xxxxxxx/libccmio.git
	return $?
    else
        if  [ -f ${CCMIO_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://nchc.dl.sourceforge.net/project/foam-extend/ThirdParty/libccmio-${CCMIO_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_ccmio()
{
    echo "zzz *** $(date) *** Build ccmio-${CCMIO_VERSION}"
    if [ "${CCMIO_VERSION}" == "git" ]
    then
	mv libccmio libccmio-${CCMIO_VERSION}
    else
	sudo rm -rf ${CCMIO_SRC%.tar.gz}
	tar xf ${CCMIO_SRC}
    fi

    cd ${CCMIO_SRC%.tar.gz}

    wget 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD' -O 'config/config.guess'
    wget 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD' -O 'config/config.sub'

    if [ -f ../../patch/ccmio/ccmio-${CCMIO_VERSION}.patch ]
    then
	patch -Np1 < ../../patch/ccmio/ccmio-${CCMIO_VERSION}.patch
    fi


    RELEASE=1 SHARED=1 make 
    sudo cp libccmio/*.h  ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include && \
	sudo cp $(find ./lib -name release-shared)/* ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib && \
	cd .. && \ 
	sudo rm -rf ${CCMIO_SRC%.tar.gz} || exit 1
}

update_ccmio_version()
{
    MODULE_VERSION=${CCMIO_VERSION}
}
