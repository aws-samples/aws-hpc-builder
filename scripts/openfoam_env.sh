#!/bin/bash
# Copyright # Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.
# SPDX-License-Identifier: MIT


case ${HPC_COMPILER} in
    "amdclang")
	WM_COMPILER=Amd
	;;
    "armclang")
	WM_COMPILER=Arm
	;;
    "armgcc"|"gcc")
	WM_COMPILER=Gcc
	;;
    "clang")
	WM_COMPILER=Clang
	;;
    "nvc")
	WM_COMPILER=Nvidia
	;;
    "icc")
	WM_COMPILER=Icc
	;;
    "icx")
	WM_COMPILER=Icx
	;;
    *)
	exit 1
	;;
esac


case ${HPC_MPI} in
    "intelmpi")
	WM_MPILIB="INTELMPI"
	;;
    "mpich"|"mvapich")
	export MPI_ARCH_FLAGS="-DMPICH_SKIP_MPICXX -DOMPI_SKIP_MPICXX"
	export MPI_ARCH_INC="-isystem ${MPI_ROOT}/include"
	export MPI_ARCH_LIBS="-L${MPI_ROOT}/lib -lmpi -lrt"
	WM_MPILIB="SYSTEMMPI"
	;;
    "openmpi")
	export MPI_ARCH_FLAGS="-DMPICH_SKIP_MPICXX -DOMPI_SKIP_MPICXX"
	export MPI_ARCH_INC="-isystem ${MPI_ROOT}/include"
	export MPI_ARCH_LIBS="-L${MPI_ROOT}/lib -lmpi"
	WM_MPILIB="SYSTEMMPI"
	;;
    *)
	echo "unknown or unsupported MPI"
	exit 1
	;;
esac

. "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/OpenFOAM-v${OPENFOAM_VERSION}/etc/bashrc" WM_COMPILER=${WM_COMPILER} WM_MPLIB=${WM_MPILIB}

