#o!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#CGAL_VERSION=git
CGAL_VERSION=${2:-4.14.3}
DISABLE_COMPILER_ENV=false

CGAL_SRC="cgal-${CGAL_VERSION}.tar.gz"

install_sys_dependency_for_cgal()
{
    # packages for build cgal
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

download_cgal() {
    echo "zzz *** $(date) *** Downloading source code ${CGAL_SRC}"
    if [ "${CGAL_VERSION}" == "git" ]
    then
	git clone https://github.com/CGAL/cgal.git
	return $?
    else
        if  [ -f ${CGAL_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://github.com/CGAL/cgal/archive/refs/tags/v${CGAL_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_cgal()
{
    echo "zzz *** $(date) *** Build cgal-${CGAL_VERSION}"
    if [ "${CGAL_VERSION}" == "git" ]
    then
	mv cgal cgal-${CGAL_VERSION}
    else
	sudo rm -rf ${CGAL_SRC%.tar.gz}
	tar xf ${CGAL_SRC}
    fi

    cd ${CGAL_SRC%.tar.gz}

    if [ -f ../../patch/cgal/cgal-${CGAL_VERSION}.patch ]
    then
	patch -Np1 < ../../patch/cgal/cgal-${CGAL_VERSION}.patch
    fi

    mkdir build
    cd build

    cmake .. -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}  \
	    -DCMAKE_PREFIX_PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DCMAKE_INSTALL_LIBDIR=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib \
	    -DCMAKE_BUILD_TYPE=Release \
	    -DBUILD_SHARED_LIBS=ON \
	    -DWITH_CGAL_Core=OFF \
	    -DWITH_CGAL_ImageIO=OFF \
	    -DWITH_CGAL_Qt5=OFF 

	    cmake --build . -j $(nproc)  && \
	    sudo --preserve-env=PATH,LD_LIBRARY_PATH,LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB env cmake --install . && \
	    cd ../.. && \
	    sudo rm -rf ${CGAL_SRC%.tar.gz} || exit 1
}

update_cgal_version()
{
    MODULE_VERSION=${CGAL_VERSION}
}
