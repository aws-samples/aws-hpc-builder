#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2023 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

LAPACK_VERSION=${2:-3.12.0}
LAPACK_SRC="lapack-${LAPACK_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_lapack()
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

download_lapack() {
    echo "zzz *** $(date) *** Downloading source code ${LAPACK_SRC}"
    if [ -f ${LAPACK_SRC} ]
    then
        return
    else
	curl --retry 3 -JLOk https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v${LAPACK_VERSION}.tar.gz
	return $?
    fi
}

install_lapack()
{
    sudo rm -rf "${LAPACK_SRC%.tar.gz}"
    tar xf "${LAPACK_SRC}"
    cd "${LAPACK_SRC%.tar.gz}"
    mkdir -p build
    cd build
    cmake .. -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} -DBUILD_SHARED_LIBS=ON
    cmake --build .  -j $(nproc)
    sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB env cmake --install . && cd ../..
}

update_lapack_version()
{
    MODULE_VERSION=${LAPACK_VERSION}
}
