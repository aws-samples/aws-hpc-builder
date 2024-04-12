#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#ECCODES_VERSION=git
ECCODES_VERSION=${2:-2.35.0}
DISABLE_COMPILER_ENV=false

ECCODES_SRC="eccodes-${ECCODES_VERSION}.tar.gz"

install_sys_dependency_for_eccodes()
{
    # packages for build eccodes
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

download_eccodes() {
    echo "zzz *** $(date) *** Downloading source code ${ECCODES_SRC}"
    if [ "${ECCODES_VERSION}" == "git" ]
    then
	git clone https://github.com/ecmwf/eccodes.git
	return $?
    else
        if  [ -f ${ECCODES_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://github.com/ecmwf/eccodes/archive/refs/tags/${ECCODES_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_eccodes()
{
    echo "zzz *** $(date) *** Build eccodes-${ECCODES_VERSION}"
    if [ "${ECCODES_VERSION}" == "git" ]
    then
	mv eccodes eccodes-${ECCODES_VERSION}
    else
	rm -rf ${ECCODES_SRC%.tar.gz}
	tar xf ${ECCODES_SRC}
    fi

    cd ${ECCODES_SRC%.tar.gz}

    if [ -f ../../patch/eccodes/eccodes-${ECCODES_VERSION}.patch ]
    then
	patch -Np1 < ../../patch/eccodes/eccodes-${ECCODES_VERSION}.patch
    fi

    mkdir build

    cmake .. -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    cmake --build . -j $(nproc)
    ctest
    sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB env cmake --install . && cd ../..
}

update_eccodes_version()
{
    MODULE_VERSION=${ECCODES_VERSION}
}
