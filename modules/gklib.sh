#o!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#GKLIB_VERSION=git
GKLIB_VERSION=${2:-5.1.1-DistDGL-0.5}
DISABLE_COMPILER_ENV=false

GKLIB_SRC="GKlib-METIS-v${GKLIB_VERSION}.tar.gz"

install_sys_dependency_for_gklib()
{
    # packages for build gklib
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

download_gklib() {
    echo "zzz *** $(date) *** Downloading source code ${GKLIB_SRC}"
    if [ "${GKLIB_VERSION}" == "git" ]
    then
	git clone https://github.com/KarypisLab/GKlib.git
	return $?
    else
        if  [ -f ${GKLIB_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://github.com/KarypisLab/GKLIB/archive/refs/tags/v${GKLIB_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_gklib()
{
    echo "zzz *** $(date) *** Build gklib-${GKLIB_VERSION}"
    if [ "${GKLIB_VERSION}" == "git" ]
    then
	mv GKLIB GKLIB-${GKLIB_VERSION}
    else
	sudo rm -rf ${GKLIB_SRC%.tar.gz}
	tar xf ${GKLIB_SRC}
    fi


    if [ -f ../patch/gklib/gklib-${GKLIB_VERSION}.patch ]
    then
	cd ${GKLIB_SRC%.tar.gz}
	patch -Np1 < ../../patch/gklib/gklib-${GKLIB_VERSION}.patch
	cd ..
    fi

    mkdir -p "${GKLIB_SRC%.tar.gz}-build"
	    
    cmake -H${GKLIB_SRC%.tar.gz} -B${GKLIB_SRC%.tar.gz}-build \
       	-DBUILD_SHARED_LIBS=ON \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_C_FLAGS_RELEASE="${HPC_CFLAGS}" \
       	-DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} || exit 1

    cmake --build "${GKLIB_SRC%.tar.gz}-build"  -j $(nproc) && \
	sudo --preserve-env=PATH,LD_LIBRARY_PATH,LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB,I_MPI_ROOT,MPI_ROOT,I_MPI_CC,I_MPI_CXX,I_MPI_FC,I_MPI_F77,I_MPI_F90 env cmake --install "${GKLIB_SRC%.tar.gz}-build"  && \
				        sudo rm -rf ${GKLIB_SRC%.tar.gz}-build || exit 1
}

update_gklib_version()
{
    MODULE_VERSION=${GKLIB_VERSION}
}
