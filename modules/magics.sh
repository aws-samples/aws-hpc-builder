#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#MAGICS_VERSION=git
MAGICS_VERSION=${2:-4.15.2}
DISABLE_COMPILER_ENV=false

MAGICS_SRC="magics-${MAGICS_VERSION}.tar.gz"

install_sys_dependency_for_magics()
{
    # packages for build magics
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

download_magics() {
    echo "zzz *** $(date) *** Downloading source code ${MAGICS_SRC}"
    if [ "${MAGICS_VERSION}" == "git" ]
    then
	git clone https://github.com/ecmwf/magics.git
	return $?
    else
        if  [ -f ${MAGICS_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://github.com/ecmwf/magics/archive/refs/tags/${MAGICS_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_magics()
{
    echo "zzz *** $(date) *** Build magics-${MAGICS_VERSION}"
    if [ "${MAGICS_VERSION}" == "git" ]
    then
	mv magics magics-${MAGICS_VERSION}
    else
	rm -rf ${MAGICS_SRC%.tar.gz}
	tar xf ${MAGICS_SRC}
    fi

    cd ${MAGICS_SRC%.tar.gz}

    if [ -f ../../patch/magics/magics-${MAGICS_VERSION}.patch ]
    then
	patch -Np1 < ../../patch/magics/magics-${MAGICS_VERSION}.patch
    fi

    mkdir build

    cmake .. -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    cmake --build . -j $(nproc)
    sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB env cmake --install . && cd ../..
}

update_magics_version()
{
    MODULE_VERSION=${MAGICS_VERSION}
}
