#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#ECBUILD_VERSION=git
ECBUILD_VERSION=${2:-3.8.3}
DISABLE_COMPILER_ENV=false

ECBUILD_SRC="ecbuild-${ECBUILD_VERSION}.tar.gz"

install_sys_dependency_for_ecbuild()
{
    # packages for build ecbuild
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

download_ecbuild() {
    echo "zzz *** $(date) *** Downloading source code ${ECBUILD_SRC}"
    if [ "${ECBUILD_VERSION}" == "git" ]
    then
	git clone https://github.com/ecmwf/ecbuild.git
	return $?
    else
        if  [ -f ${ECBUILD_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://github.com/ecmwf/ecbuild/archive/refs/tags/${ECBUILD_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_ecbuild()
{
    echo "zzz *** $(date) *** Build ecbuild-${ECBUILD_VERSION}"
    if [ "${ECBUILD_VERSION}" == "git" ]
    then
	mv ecbuild ecbuild-${ECBUILD_VERSION}
    else
	rm -rf ${ECBUILD_SRC%.tar.gz}
	tar xf ${ECBUILD_SRC}
    fi

    cd ${ECBUILD_SRC%.tar.gz}

    if [ -f ../../patch/ecbuild/ecbuild-${ECBUILD_VERSION}.patch ]
    then
	patch -Np1 < ../../patch/ecbuild/ecbuild-${ECBUILD_VERSION}.patch
    fi

    mkdir build
    cd build

    ../bin/ecbuild --prefix=/path/to/install/ecbuild ..
    ctest
    sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB env make install && cd ../..
}

update_ecbuild_version()
{
    MODULE_VERSION=${ECBUILD_VERSION}
}
