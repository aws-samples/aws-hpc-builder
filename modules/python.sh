#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#PYTHON_VERSION=git
PYTHON_VERSION=${2:-3.11.9}
DISABLE_COMPILER_ENV=false

PYTHON_SRC="Python-${PYTHON_VERSION}.tgz"

install_sys_dependency_for_python()
{
    # packages for build python
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

download_python() {
    echo "zzz *** $(date) *** Downloading source code ${PYTHON_SRC}"
    if [ "${PYTHON_VERSION}" == "git" ]
    then
	git clone https://github.com/python/python.git
	return $?
    else
        if  [ -f ${PYTHON_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://www.python.org/ftp/python/${PYTHON_VERSION}/${PYTHON_SRC}"
	    return $?
       	fi
    fi
}

install_python()
{
    echo "zzz *** $(date) *** Build python-${PYTHON_VERSION}"
    if [ "${PYTHON_VERSION}" == "git" ]
    then
	mv python python-${PYTHON_VERSION}
    else
	sudo rm -rf ${PYTHON_SRC%.tgz}
	tar xf ${PYTHON_SRC}
    fi

    cd ${PYTHON_SRC%.tgz}

    if [ -f ../../patch/python/python-${PYTHON_VERSION}.patch ]
    then
	patch -Np1 < ../../patch/python/python-${PYTHON_VERSION}.patch
    fi
     
    ./configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} --enable-optimizations
     make && \
	 sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB env make install && \
	 cd .. && \
	 sudo rm -rf ${PYTHON_SRC%.tgz} || exit 1

}

update_python_version()
{
    MODULE_VERSION=${PYTHON_VERSION}
}
