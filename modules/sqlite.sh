#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#SQLITE_VERSION=git
SQLITE_VERSION=${2:-3.45.2}
DISABLE_COMPILER_ENV=false

SQLITE_SRC="sqlite-version-${SQLITE_VERSION}.tar.gz"

install_sys_dependency_for_sqlite()
{
    # packages for build sqlite
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

download_sqlite() {
    echo "zzz *** $(date) *** Downloading source code ${SQLITE_SRC}"
    if [ "${SQLITE_VERSION}" == "git" ]
    then
	git clone https://github.com/sqlite/sqlite.git
	return $?
    else
        if  [ -f ${SQLITE_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://github.com/sqlite/sqlite/archive/refs/tags/${SQLITE_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_sqlite()
{
    echo "zzz *** $(date) *** Build sqlite-${SQLITE_VERSION}"
    if [ "${SQLITE_VERSION}" == "git" ]
    then
	mv sqlite sqlite-${SQLITE_VERSION}
    else
	rm -rf ${SQLITE_SRC%.tar.gz}
	tar xf ${SQLITE_SRC}
    fi

    cd ${SQLITE_SRC%.tar.gz}

    if [ -f ../../patch/sqlite/sqlite-${SQLITE_VERSION}.patch ]
    then
	patch -Np1 < ../../patch/sqlite/sqlite-${SQLITE_VERSION}.patch
    fi

    mkdir build
    cd build

    cmake .. -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    cmake --build .  -j $(nproc)
    sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB env cmake --install . && cd ../..
}

update_sqlite_version()
{
    MODULE_VERSION=${SQLITE_VERSION}
}
