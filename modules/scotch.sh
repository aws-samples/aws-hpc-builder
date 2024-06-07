#o!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#SCOTCH_VERSION=git
SCOTCH_VERSION=${2:-7.0.4}
DISABLE_COMPILER_ENV=false

SCOTCH_SRC="scotch-${SCOTCH_VERSION}.tar.gz"

install_sys_dependency_for_scotch()
{
    # packages for build scotch
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y install libtiff-devel
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
	    sudo dnf -y install libtiff-devel
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
	    sudo apt-get -y install libtiff-dev
	    return
	    ;;
	*)
	    exit 1
	    ;;
    esac
}

download_scotch() {
    echo "zzz *** $(date) *** Downloading source code ${SCOTCH_SRC}"
    if [ "${SCOTCH_VERSION}" == "git" ]
    then
	git clone https://github.com/live-clones/scotch.git
	return $?
    else
        if  [ -f ${SCOTCH_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://github.com/live-clones/scotch/archive/refs/tags/v${SCOTCH_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_scotch()
{
    echo "zzz *** $(date) *** Build scotch-${SCOTCH_VERSION}"
    if [ "${SCOTCH_VERSION}" == "git" ]
    then
	mv scotch scotch-${SCOTCH_VERSION}
    else
	sudo rm -rf ${SCOTCH_SRC%.tar.gz}
	tar xf ${SCOTCH_SRC}
    fi

    cd ${SCOTCH_SRC%.tar.gz}

    if [ -f ../../patch/scotch/scotch-${SCOTCH_VERSION}.patch ]
    then
	patch -Np1 < ../../patch/scotch/scotch-${SCOTCH_VERSION}.patch
    fi

    mkdir build
    cd build

    cmake .. -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}  \
	    -DCMAKE_PREFIX_PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DCMAKE_INSTALL_LIBDIR=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib \
	    -DBUILD_SHARED_LIBS=ON \
	    -DCMAKE_BUILD_TYPE=Release && \
	    cmake --build .  -j $(nproc)  && \
	    sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB env cmake --install . && \
	    cd ../.. && \
	    sudo rm -rf ${SCOTCH_SRC%.tar.gz} || exit 1
}

update_scotch_version()
{
    MODULE_VERSION=${SCOTCH_VERSION}
}
