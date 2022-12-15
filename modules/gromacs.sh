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
	# https://nekodaemon.com/2021/01/10/%E4%BF%AE%E5%A4%8DNVIDIA-HPC-SDK%E4%B8%8ECMake%E5%85%BC%E5%AE%B9%E9%97%AE%E9%A2%98/
	# NVIDIA HPC SDK incompatible with CMake
	# nvcc doesn't support new gcc version
	unset_compiler_env
	cmake .. -DCMAKE_C_COMPILER=$(which gcc) \
	    -DCMAKE_CXX_COMPILER=$(which g++) \
	    -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DGMX_BUILD_OWN_FFTW=ON \
	    -DGMX_MPI=ON -DGMX_MP=ON \
	    -DGMX_GPU=CUDA
    else 
	if [ -d ${HPC_PREFIX}/opt/nvidia/Linux_$(arch)/${NVIDIA_COMPILER_VERSION}/cuda ]
	then
	    export MODULEPATH=${MODULEPATH}:${HPC_PREFIX}/opt/nvidia/modulefiles
	    module load $(basename ${HPC_PREFIX}/opt/nvidia/modulefiles/nvhpc-nompi)/$(ls ${HPC_PREFIX}/opt/nvidia/modulefiles/nvhpc-nompi)
	    check_and_use_nvidiampi
	    cmake .. -DCMAKE_C_COMPILER=${CC} \
		-DCMAKE_CXX_COMPILER=${CXX} \
		-DCMAKE_CXX_COMPILER=$(which g++) \
		-DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
		-DGMX_BUILD_OWN_FFTW=ON \
		-DGMX_MPI=ON -DGMX_MP=ON \
		-DGMX_GPU=CUDA
	else
	    cmake .. -DCMAKE_C_COMPILER=${CC} \
		-DCMAKE_CXX_COMPILER=${CXX} \
		-DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
		-DGMX_BUILD_OWN_FFTW=ON \
		-DGMX_MPI=ON -DGMX_MP=ON
	fi
    fi
    make && sudo --preserve-env=PATH,LD_LIBRARY_PATH env make install && cd ../..
}

update_gromacs_version()
{
    MODULE_VERSION=${GROMACS_VERSION}
}
