#!/bin/bash
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.
# SPDX-License-Identifier: MIT

PREFIX=/fsx
# compiler & MPI selection
# compiler table:
# ---------------
# 0 VENDOR's compiler, Intel=icc, AMD=amdclang, ARM=armgcc
# 1 GNU/GCC compiler
# 2 GNU/CLANG compiler
# 3 INTEL/ICC compiler
# 4 INTEL/ICX compiler
# 5 AMD/CLANG compiler
# 6 ARM/GCC compiler
# 7 ARM/CLANG compiler
# 8 NVidia/NVC compiler
#
# 
# MPI table:
# ----------
# 0 openmpi
# 1 mpich
# 2 intelmpi
# 3 mvapich
# 4 nvidiampi
#
# usage: env.sh <compiler> <MPI>
#        C M
# env.sh 0 0   ## select vendor's native compilers with openmpi
# env.sh 0 1   ## select vendor's native compilers with mpich
# env.sh 0 2   ## select vendor's native compilers with intelmpi
# env.sh 0 3   ## select vendor's native compilers with mvapich
# env.sh 1 0   ## select GNU/GCC compilers with openmpi
# env.sh 8 4   ## select Nvidia compilers with mpi shipped by Nvidia compilers
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
    8)
	HPC_COMPILER=nvc
	;;
    *)
	echo "unknown compiler"
	;;
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
    3)
	HPC_MPI=mvapich
	;;
    4)
	HPC_MPI=nvidiampi
	;;
    *)
	echo "unknown MPI"
	;;
esac

source ${PREFIX}/scripts/compiler.sh

export PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/${HPC_TARGET}/bin:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/bin:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/usr/local/bin:${PATH}
export MANPATH=:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/share/man:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/usr/local/share/man${MANPATH}
export LD_LIBRARY_PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib64:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/usr/local/lib64:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/usr/local/lib:${LD_LIBRARY_PATH}
export PKG_CONFIG_PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib64/pkgconfig:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib/pkgconfig:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/usr/local/lib64/pkgconfig:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH}

# To support EFA, use libfabric provided by Amazon
if [ -d /opt/amazon/efa ]
then
    export LD_LIBRARY_PATH=/opt/amazon/efa/lib64:${LD_LIBRARY_PATH}
fi

export OMP_STACKSIZE=128M
export KMP_STACKSIZE=128M
