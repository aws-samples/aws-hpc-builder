#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#LAMMPS_VERSION=git
#LAMMPS_VERSION=${2:-stable_2Aug2023}
LAMMPS_VERSION=${2:-git}
DISABLE_COMPILER_ENV=false

LAMMPS_SRC="lammps-${LAMMPS_VERSION}.tar.gz"

install_sys_dependency_for_lammps()
{
    # packages for build lammps
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

download_lammps() {
    echo "zzz *** $(date) *** Downloading source code ${LAMMPS_SRC}"
    if [ "${LAMMPS_VERSION}" == "git" ]
    then
	git clone https://github.com/lammps/lammps.git
	return $?
    else
        if  [ -f ${LAMMPS_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://github.com/lammps/lammps/archive/refs/tags/${LAMMPS_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_lammps()
{
    echo "zzz *** $(date) *** Build lammps-${LAMMPS_VERSION}"
    if [ "${LAMMPS_VERSION}" == "git" ]
    then
	sudo rm -rf lammps-${LAMMPS_VERSION}
	mv lammps lammps-${LAMMPS_VERSION}
    else
	sudo rm -rf ${LAMMPS_SRC%.tar.gz}
	tar xf ${LAMMPS_SRC}
    fi

    cd ${LAMMPS_SRC%.tar.gz}

    if [ -f ../../patch/lammps/lammps-$(arch)-${HPC_COMPILER}.patch ]
    then
        patch -Np1 < ../../patch/lammps/lammps-$(arch)-${HPC_COMPILER}.patch
    fi

    mkdir -p build && cd build
    if [ "${HPC_COMPILER}" == "icc" ]
    then
	cmake ../cmake -DFFT=MKL -DFFT_MKL_THREADS=on \
	    -DBUILD_MPI=yes \
	    -DPKG_REPLICA=yes -DPKG_KSPACE=yes -DPKG_MANYBODY=yes \
	    -DWITH_JPEG=yes -DWITH_GZIP=yes \
	    -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    else
	cmake ../cmake -DFFT=FFTW3 -DFFTW3_LIBRARY="${HPC_FFT_LIB}" -DFFTW3_INCLUDE_DIR="${HPC_INC_DIR}" \
	    -DBUILD_MPI=yes \
	    -DPKG_REPLICA=yes -DPKG_KSPACE=yes -DPKG_MANYBODY=yes \
	    -DWITH_JPEG=yes -DWITH_GZIP=yes \
	    -DCMAKE_EXE_LINKER_FLAGS="${HPC_LLIBS}" \
	    -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    fi
	cmake --build .  -j $(nproc) && \
	sudo --preserve-env=PATH,LD_LIBRARY_PATH,I_MPI_CC,I_MPI_CXX,I_MPI_FC,I_MPI_F77,I_MPI_F90 env make install && \
	cd ../.. && \
	sudo rm -rf lammps-${LAMMPS_VERSION} || exit 1
}

update_lammps_version()
{
    MODULE_VERSION=${LAMMPS_VERSION}
}
