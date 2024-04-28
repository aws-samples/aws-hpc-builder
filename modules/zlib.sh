#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#ZLIB_VERSION=${2:-git}
ZLIB_VERSION=${2:-2.1.6}
DISABLE_COMPILER_ENV=false

ZLIB_SRC="zlib-ng-${ZLIB_VERSION}.tar.gz"

install_sys_dependency_for_zlib()
{
    # packages for build zlib
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

download_zlib() {
    echo "zzz *** $(date) *** Downloading source code ${ZLIB_SRC}"
    if [ "${ZLIB_VERSION}" == "git" ]
    then
	git clone https://github.com/zlib-ng/zlib-ng.git
	return $?
    else
        if  [ -f ${ZLIB_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://github.com/zlib-ng/zlib-ng/archive/refs/tags/${ZLIB_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_zlib()
{
    echo "zzz *** $(date) *** Build zlib-ng-${ZLIB_VERSION}"
    if [ "${ZLIB_VERSION}" == "git" ]
    then
	mv zlib-ng zlib-ng-${ZLIB_VERSION}
    else
	sudo rm -rf ${ZLIB_SRC%.tar.gz}
	tar xf ${ZLIB_SRC}
    fi

    cd ${ZLIB_SRC%.tar.gz}

    if [ -f ../../patch/zlib/zlib-${ZLIB_VERSION}.patch ]
    then
	patch -Np1 < ../../patch/zlib/zlib-${ZLIB_VERSION}.patch
    fi
     
    ./configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} --zlib-compat
     make && \
	 sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB env make install && \
	 cd .. && \
	 sudo rm -rf ${ZLIB_SRC%.tar.gz} || exit 1

}

update_zlib_version()
{
    MODULE_VERSION=${ZLIB_VERSION}
}
