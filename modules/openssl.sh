#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#OPENSSL_VERSION=git
OPENSSL_VERSION=${2:-3.2.1}
DISABLE_COMPILER_ENV=false

OPENSSL_SRC="openssl-openssl-${OPENSSL_VERSION}.tar.gz"

install_sys_dependency_for_openssl()
{
    # packages for build openssl
    case ${S_VERSION_ID} in
	7)
	    case  "${S_NAME}" in
		"Alibaba Cloud Linux (Aliyun Linux)"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
                    sudo yum -y install perl-IPC-Cmd
		    return
		    ;;
		"Amazon Linux")
                    sudo yum -y install perl-IPC-Cmd
		    return
		    ;;
	    esac
	    ;;
	8)
	    case  "${S_NAME}" in
		"Alibaba Cloud Linux"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
                    sudo dnf -y install perl-IPC-Cmd
		    return
		    ;;
		"Amazon Linux")
                    sudo dnf -y install perl-IPC-Cmd
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

download_openssl() {
    echo "zzz *** $(date) *** Downloading source code ${OPENSSL_SRC}"
    if [ "${OPENSSL_VERSION}" == "git" ]
    then
	git clone https://github.com/openssl/openssl.git
	return $?
    else
        if  [ -f ${OPENSSL_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://github.com/openssl/openssl/archive/refs/tags/openssl-${OPENSSL_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_openssl()
{
    echo "zzz *** $(date) *** Build openssl-${OPENSSL_VERSION}"
    if [ "${OPENSSL_VERSION}" == "git" ]
    then
	mv openssl openssl-${OPENSSL_VERSION}
    else
	sudo rm -rf ${OPENSSL_SRC%.tar.gz}
	tar xf ${OPENSSL_SRC}
    fi

    cd ${OPENSSL_SRC%.tar.gz}

    if [ -f ../../patch/openssl/openssl-${OPENSSL_VERSION}.patch ]
    then
	patch -Np1 < ../../patch/openssl/openssl-${OPENSSL_VERSION}.patch
    fi
     
    ./Configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
     make && \
	 sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB env make install && \
	 cd .. && \
	 sudo rm -rf ${OPENSSL_SRC%.tar.gz} || exit 1

}

update_openssl_version()
{
    MODULE_VERSION=${OPENSSL_VERSION}
}
