#o!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#BOOST_VERSION=git
BOOST_VERSION=${2:-1.85.0}
DISABLE_COMPILER_ENV=false

BOOST_SRC="boost_$(echo ${BOOST_VERSION} | tr '.' '_').tar.gz"

install_sys_dependency_for_boost()
{
    # packages for build boost
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y install libtiff-devel patchelf
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
	    sudo dnf -y install libtiff-devel patchelf
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
	    sudo apt-get -y install libtiff-dev patchelf
	    return
	    ;;
	*)
	    exit 1
	    ;;
    esac
}

download_boost() {
    echo "zzz *** $(date) *** Downloading source code ${BOOST_SRC}"
    if [ "${BOOST_VERSION}" == "git" ]
    then
	git clone https://github.com/boostorg/boost.git
	return $?
    else
        if  [ -f ${BOOST_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://archives.boost.io/release/${BOOST_VERSION}/source/${BOOST_SRC}"
	    return $?
       	fi
    fi
}

install_boost()
{
    echo "zzz *** $(date) *** Build boost-${BOOST_VERSION}"
    if [ "${BOOST_VERSION}" == "git" ]
    then
	mv BOOST BOOST-${BOOST_VERSION}
    else
	sudo rm -rf ${BOOST_SRC%.tar.gz}
	tar xf ${BOOST_SRC}
    fi

    cd ${BOOST_SRC%.tar.gz}

    if [ -f ../../patch/boost/boost-${BOOST_VERSION}.patch ]
    then
	patch -Np1 < ../../patch/boost/boost-${BOOST_VERSION}.patch
    fi

    ./bootstrap.sh  \
	--prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	--libdir=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib \
       	--with-libraries=thread \
       	--with-libraries=system

    patchelf --set-rpath $LIBRARY_PATH b2

    ./b2 -j $(nproc) && \
	    sudo --preserve-env=PATH,LD_LIBRARY_PATH,LIBRARY_PATH,I_MPI_CC,I_MPI_CXX,I_MPI_FC,I_MPI_F77,I_MPI_F90,CC,CXX,F77,FC,AR,RANLIB,FFLAGS,FCFLAGS ./b2 install && \
	    cd .. && sudo rm -rf ${BOOST_SRC%.tar.gz} || exit 1
}

update_boost_version()
{
    MODULE_VERSION=${BOOST_VERSION}
}
