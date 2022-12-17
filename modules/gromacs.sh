#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

GROMACS_VERSION=${2:-2022.4}
GROMACS_SRC=gromacs-${GROMACS_VERSION}.tar.gz
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_gromacs()
{
    return
}

download_gromacs()
{
    echo "zzz *** $(date) *** Downloading source code ${GROMACS_SRC}"
    if [ -f ${GROMACS_SRC} ]
    then
        return
    else
         wget https://ftp.gromacs.org/gromacs/${GROMACS_SRC}
         return $?
    fi
}

install_gromacs()
{
    rm -rf ${GROMACS_SRC%.tar.gz}
    tar xf ${GROMACS_SRC}
    cd ${GROMACS_SRC%.tar.gz}
    if [ -f ../../patch/gromacs/gromacs-${GROMACS_VERSION}-${HPC_COMPILER}-${HPC_MPI}.patch ]
    then
	patch -Np1 < ../../patch/gromacs/gromacs-${GROMACS_VERSION}-${HPC_COMPILER}-${HPC_MPI}.patch
    fi
    mkdir -p build
    cd build
    if [ "${HPC_COMPILER}" == "nvc" ]
    then
	# NVIDIA HPC SDK incompatible with CMake
	# https://nekodaemon.com/2021/01/10/%E4%BF%AE%E5%A4%8DNVIDIA-HPC-SDK%E4%B8%8ECMake%E5%85%BC%E5%AE%B9%E9%97%AE%E9%A2%98/
	# NVIDIA HPC SDK doesn't work well with cmake
        # https://github.com/openmm/openmm/issues/3106
	export CPATH=${HPC_PREFIX}/opt/nvidia/Linux_$(arch)/${NVIDIA_COMPILER_VERSION}/math_libs/include:${CPATH}
	export NVCC_PREPEND_FLAGS=-allow-unsupported-compiler
	cmake .. -DCMAKE_C_COMPILER=${CC} \
	    -DCMAKE_CXX_COMPILER=${CXX} \
	    -DCUDA_HOST_COMPILER=$(which mpic++) \
	    -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DGMX_BUILD_OWN_FFTW=ON \
	    -DGMX_MPI=ON -DGMX_MP=ON \
	    -DCUDA_TOOLKIT_ROOT_DIR=${HPC_PREFIX}/opt/nvidia/Linux_$(arch)/${NVIDIA_COMPILER_VERSION}/cuda \
	    -DGMX_GPU=CUDA
    else 
	if [ -d ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/usr/local/cuda ]
	then
	    cmake .. -DCMAKE_C_COMPILER=${CC} \
		-DCMAKE_CXX_COMPILER=${CXX} \
		-DCUDA_HOST_COMPILER=$(which mpic++) \
		-DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
		-DGMX_BUILD_OWN_FFTW=ON \
		-DGMX_MPI=ON -DGMX_MP=ON \
		-DCUDA_TOOLKIT_ROOT_DIR=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/usr/local/cuda \
		-DGMX_GPU=CUDA
	elif [ -d /usr/local/cuda ]
	    # nvcc(cuda 11.x) doesn't support new gcc version greater than 10
	    # 132 | #error -- unsupported GNU version! gcc versions later than 11 are not supported! The nvcc flag '-allow-unsupported-compiler' can be used to override this version check" " however, using an unsupported host compiler may cause compilation failure or incorrect run time execution. Use at your own risk.
            #         |  ^~~~~
            #
            #           " "MATCHES" "nsupported"
	    if [ $(gcc -dumpversion) -gt 10 ]
	    then
		echo "nvcc doesn't support gcc version greater than 10"
		exit 1
	    fi
	    cmake .. -DCMAKE_C_COMPILER=${CC} \
		-DCMAKE_CXX_COMPILER=${CXX} \
		-DCUDA_HOST_COMPILER=$(which mpic++) \
		-DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
		-DGMX_BUILD_OWN_FFTW=ON \
		-DGMX_MPI=ON -DGMX_MP=ON \
		-DCUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda \
		-DGMX_GPU=CUDA
	else
	    cmake .. -DCMAKE_C_COMPILER=${CC} \
		-DCMAKE_CXX_COMPILER=${CXX} \
		-DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
		-DGMX_BUILD_OWN_FFTW=ON \
		-DGMX_MPI=ON -DGMX_MP=ON
	fi
    fi
    make && sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB make install && cd ../..
}

update_gromacs_version()
{
    MODULE_VERSION=${GROMACS_VERSION}
}
