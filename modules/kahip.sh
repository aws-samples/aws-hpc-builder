#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#KAHIP_VERSION=git
KAHIP_VERSION=${2:-3.16}
DISABLE_COMPILER_ENV=false

KAHIP_SRC="KaHIP-${KAHIP_VERSION}.tar.gz"

install_sys_dependency_for_kahip()
{
    # packages for build kahip
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

download_kahip() {
    echo "zzz *** $(date) *** Downloading source code ${KAHIP_SRC}"
    if [ "${KAHIP_VERSION}" == "git" ]
    then
	git clone https://github.com/KaHIP/KaHIP.git
	return $?
    else
        if  [ -f ${KAHIP_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://github.com/KaHIP/KaHIP/archive/refs/tags/v${KAHIP_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_kahip()
{
    echo "zzz *** $(date) *** Build kahip-${KAHIP_VERSION}"
    if [ "${KAHIP_VERSION}" == "git" ]
    then
	mv KaHIP KaHIP-${KAHIP_VERSION}
    else
	sudo rm -rf ${KAHIP_SRC%.tar.gz}
	tar xf ${KAHIP_SRC}
    fi

    if [ -f ../patch/kahip/kahip-${KAHIP_VERSION}.patch ]
    then
        cd ${KAHIP_SRC%.tar.gz}
	patch -Np1 < ../../patch/kahip/kahip-${KAHIP_VERSION}.patch
	cd ..
    fi

    mkdir -p "${KAHIP_SRC%.tar.gz}-build"
    #sed -i s"%/usr/local/include%${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include%g" "${KAHIP_SRC%.tar.gz}/CMakeLists.txt"

    cmake -H${KAHIP_SRC%.tar.gz} -B${KAHIP_SRC%.tar.gz}-build \
	    -DCMAKE_PREFIX_PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DCMAKE_CXX_FLAGS="-I${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include" \
	    -DBUILD_SHARED_LIBS=ON \
	    -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} || exit 1

    cmake --build "${KAHIP_SRC%.tar.gz}-build"  -j $(nproc) && \
	sudo --preserve-env=PATH,LD_LIBRARY_PATH,LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB,I_MPI_ROOT,MPI_ROOT,I_MPI_CC,I_MPI_CXX,I_MPI_FC,I_MPI_F77,I_MPI_F90 env cmake --install "${KAHIP_SRC%.tar.gz}-build"  && \
	sudo rm -rf ${KAHIP_SRC%.tar.gz}-build || exit 1
}

update_kahip_version()
{
    MODULE_VERSION=${KAHIP_VERSION}
}
