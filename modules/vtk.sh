#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#VTK_VERSION=git
VTK_VERSION=${2:-9.3.0}
DISABLE_COMPILER_ENV=false

VTK_SRC="VTK-${VTK_VERSION}.tar.gz"

install_sys_dependency_for_vtk()
{
    # packages for build vtk
    case ${S_VERSION_ID} in
	7)
            sudo yum install -y libXcursor-devel mesa-libGL-devel libXt-devel python3-deve
	    case  "${S_NAME}" in
		"Alibaba Cloud Linux (Aliyun Linux)"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		    return
		    ;;
		"Amazon Linux")
	            sudo yum install -y libXcursor-devel mesa-libGL-devel libXt-devel python3-deve
		    return
		    ;;
	    esac
	    ;;
	8)
            sudo dnf install -y libXcursor-devel mesa-libGL-devel libXt-devel python3-deve
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
	    sudo apt install -y mesa-common-dev mesa-utils freeglut3-dev ninja-build
	    return
	    ;;
	*)
	    exit 1
	    ;;
    esac
}

download_vtk() {
    echo "zzz *** $(date) *** Downloading source code ${VTK_SRC}"
    if [ "${VTK_VERSION}" == "git" ]
    then
	git clone https://gitlab.kitware.com/vtk/vtk.git
	return $?
    else
        if  [ -f ${VTK_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://www.vtk.org/files/release/$(echo ${VTK_VERSION} | cut -f1,2 -d.)/VTK-${VTK_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_vtk()
{
    echo "zzz *** $(date) *** Build vtk-${VTK_VERSION}"
    if [ "${VTK_VERSION}" == "git" ]
    then
	mv VTK VTK-${VTK_VERSION}
    else
	sudo rm -rf ${VTK_SRC%.tar.gz}
	tar xf ${VTK_SRC}
    fi

    if [ -f ../patch/vtk/vtk-${VTK_VERSION}.patch ]
    then
        cd ${VTK_SRC%.tar.gz}
	patch -Np1 < ../../patch/vtk/vtk-${VTK_VERSION}.patch
	cd ..
    fi

    mkdir -p "${VTK_SRC%.tar.gz}-build"

    cmake -H${VTK_SRC%.tar.gz} -B${VTK_SRC%.tar.gz}-build \
	    -DCMAKE_PREFIX_PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -GNinja -DVTK_USE_MPI=ON \
	    -DBUILD_SHARED_LIBS=ON \
	    -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DCMAKE_BUILD_TYPE=Release || exit 1

    cmake --build "${VTK_SRC%.tar.gz}-build"  -j $(nproc) && \
	sudo --preserve-env=PATH,LD_LIBRARY_PATH,LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB,I_MPI_ROOT,MPI_ROOT,I_MPI_CC,I_MPI_CXX,I_MPI_FC,I_MPI_F77,I_MPI_F90 env cmake --install "${VTK_SRC%.tar.gz}-build"  && \
	sudo rm -rf ${VTK_SRC%.tar.gz}-build || exit 1
}

update_vtk_version()
{
    MODULE_VERSION=${VTK_VERSION}
}
