#!/bin/sh
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.
# SPDX-License-Identifier: MIT

PREFIX=/fsx
# compiler & MPI selection
# compiler table:
# ---------------
# 0 VENDOR's compiler, Intel=icc, AMD=armclang, ARM=armgcc
# 1 GNU/GCC compiler
# 1 GNU/CLANG compiler
# 2 INTEL/ICC compiler
# 3 INTEL/ICX compiler
# 4 AMD/CLANG compiler
# 5 ARM/GCC compiler
# 6 ARM/CLANG compiler
#
# 
# MPI table:
# ----------
# 0 openmpi
# 1 mpich
# 2 intelmpi
#
# usage: env.sh <compiler> <MPI>
#        C M
# env.sh 0 0   ## select vendor's native compilers with openmpi
# env.sh 0 1   ## select vendor's native compilers with mpich
# env.sh 0 2   ## select vendor's native compilers with intelmpi
# env.sh 1 0   ## select GNU/GCC compilers with openmpi
# env.sh ...

export HPC_USE_VENDOR_COMPILER=false

# default settings
case $1 in 
    0)
	HPC_USE_VENDOR_COMPILER=true
	;;
    1)
	HPC_COMPILER=gcc
	;;
    2)
	HPC_COMPILER=clang
	;;
    3)
	HPC_COMPILER=icc
	;;
    4)
	HPC_COMPILER=icx
	;;
    5)
	HPC_COMPILER=amdclang
	;;
    6)
	HPC_COMPILER=armgcc
	;;
    7)
	HPC_COMPILER=armclang
	;;
    *)
	echo "unknown compiler"
esac

case $2 in 
    0)
	HPC_MPI=openmpi
	;;
    1)
	HPC_MPI=mpich
	;;
    2)
	HPC_MPI=intelmpi
	;;
    *)
	echo "unknown MPI"
esac

source ${PREFIX}/scripts/compiler.sh

export PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_TARGET}/${HPC_MPI}/bin:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/bin:${PATH}
export LD_LIBRARY_PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib64:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib:${LD_LIBRARY_PATH}

export OMP_STACKSIZE=128M
