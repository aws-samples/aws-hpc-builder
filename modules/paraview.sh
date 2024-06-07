#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#PARAVIEW_VERSION=git
PARAVIEW_VERSION=${2:-5.12.0}
DISABLE_COMPILER_ENV=false

PARAVIEW_SRC="ParaView-v${PARAVIEW_VERSION}.tar.gz"

install_sys_dependency_for_paraview()
{
    # packages for build paraview
    case ${S_VERSION_ID} in
	7)
            sudo yum install -y python3-devel mesa-libGL-devel libX11-devel libXt-devel qt5-qtbase-devel qt5-qtx11extras-devel qt5-qttools-devel qt5-qtxmlpatterns-devel tbb-devel ninja-build git
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
            sudo dnf install -y python3-devel mesa-libGL-devel libX11-devel libXt-devel qt5-qtbase-devel qt5-qtx11extras-devel qt5-qttools-devel qt5-qtxmlpatterns-devel tbb-devel ninja-build git
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
	    sudo apt install -y git cmake build-essential libgl1-mesa-dev libxt-dev libqt5x11extras5-dev libqt5help5 qttools5-dev qtxmlpatterns5-dev-tools libqt5svg5-dev python3-dev python3-numpy libopenmpi-dev libtbb-dev ninja-build qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools
	    return
	    ;;
	*)
	    exit 1
	    ;;
    esac
}

download_paraview() {
    echo "zzz *** $(date) *** Downloading source code ${PARAVIEW_SRC}"
    if [ "${PARAVIEW_VERSION}" == "git" ]
    then
	git clone https://gitlab.kitware.com/paraview/paraview.git
	return $?
    else
        if  [ -f ${PARAVIEW_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://www.paraview.org/paraview-downloads/download.php?submit=Download&version=v$(echo ${PARAVIEW_VERSION} | cut -f1,2 -d.)&type=source&os=Sources&downloadFile=ParaView-v${PARAVIEW_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_paraview()
{
    echo "zzz *** $(date) *** Build paraview-${PARAVIEW_VERSION}"
    if [ "${PARAVIEW_VERSION}" == "git" ]
    then
	mv ParaView ParaView-${PARAVIEW_VERSION}
    else
	sudo rm -rf ${PARAVIEW_SRC%.tar.gz}
	tar xf ${PARAVIEW_SRC}
    fi

    if [ -f ../patch/paraview/paraview-${PARAVIEW_VERSION}.patch ]
    then
        cd ${PARAVIEW_SRC%.tar.gz}
	patch -Np1 < ../../patch/paraview/paraview-${PARAVIEW_VERSION}.patch
	cd ..
    fi

    mkdir -p "${PARAVIEW_SRC%.tar.gz}-build"

    cmake -H${PARAVIEW_SRC%.tar.gz} -B${PARAVIEW_SRC%.tar.gz}-build \
	    -DCMAKE_PREFIX_PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -GNinja -DPARAVIEW_USE_MPI=ON \
	    -DBUILD_SHARED_LIBS=ON \
	    -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DPARAVIEW_USE_PYTHON=ON -DVTK_SMP_IMPLEMENTATION_TYPE=TBB \
	    -DCMAKE_BUILD_TYPE=Release || exit 1

    cmake --build "${PARAVIEW_SRC%.tar.gz}-build"  -j $(nproc) && \
	sudo --preserve-env=PATH,LD_LIBRARY_PATH,LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB,I_MPI_ROOT,MPI_ROOT,I_MPI_CC,I_MPI_CXX,I_MPI_FC,I_MPI_F77,I_MPI_F90 env cmake --install "${PARAVIEW_SRC%.tar.gz}-build"  && \
	sudo rm -rf ${PARAVIEW_SRC%.tar.gz}-build || exit 1
}

update_paraview_version()
{
    MODULE_VERSION=${PARAVIEW_VERSION}
}
