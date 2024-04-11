#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2023 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

OPENBLAS_VERSION=${2:-0.3.25}
OPENBLAS_SRC="OpenBLAS-${OPENBLAS_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_openblas()
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

download_openblas() {
    echo "zzz *** $(date) *** Downloading source code ${OPENBLAS_SRC}"
    if [ -f ${OPENBLAS_SRC} ]
    then
        return
    else
	curl --retry 3 -JLOk https://github.com/OpenMathLib/OpenBLAS/archive/refs/tags/v${OPENBLAS_VERSION}.tar.gz
	return $?
    fi
}

install_openblas()
{
    sudo rm -rf "${OPENBLAS_SRC%.tar.gz}"
    tar xf "${OPENBLAS_SRC}"
    cd "${OPENBLAS_SRC%.tar.gz}"
    mkdir -p build
    cd build
    cmake .. -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} -DBUILD_SHARED_LIBS=ON
    cmake --build .  -j $(nproc)
    sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB env cmake --install . && cd ../..
}

update_openblas_version()
{
    MODULE_VERSION=${OPENBLAS_VERSION}
}
