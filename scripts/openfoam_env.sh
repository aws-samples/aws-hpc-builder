#!/bin/bash
# Copyright # Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.
# SPDX-License-Identifier: MIT

OPENFOAM_VERSION=${OPENFOAM_VERSION:-2212}

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
	export MPI_ROOT=${I_MPI_ROOT}
        export MPI_ARCH_FLAGS="-DMPICH_SKIP_MPICXX -DOMPI_SKIP_MPICXX"
	export WM_MPLIB="INTELMPI"
	;;
    "mpich"|"mvapich"|"openmpi")
	export MPI_ROOT=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
	export MPI_ARCH_FLAGS="-DMPICH_SKIP_MPICXX -DOMPI_SKIP_MPICXX"
	export MPI_ARCH_INC="-isystem ${MPI_ROOT}/include"
	if [ "${HPC_MPI}" == "openmpi" ]
	then 
            export WM_MPLIB="SYSTEMOPENMPI"
	    export MPI_ARCH_LIBS="-L${MPI_ROOT}/lib -lmpi"
	else
            export WM_MPLIB="SYSTEMMPI"
	    export MPI_ARCH_LIBS="-L${MPI_ROOT}/lib -lmpi -lrt"
	fi
	;;
    *)
	echo "unknown or unsupported MPI"
	exit 1
	;;
esac

# 旧版本如 2.3.1 需要设置  FOAM_INST_DIR
export OPENFOAM_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/OpenFOAM
export FOAM_INST_DIR=${OPENFOAM_PREFIX}

. "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/OpenFOAM/OpenFOAM-${OPENFOAM_VERSION}/etc/bashrc" WM_COMPILER=${WM_COMPILER} WM_MPLIB=${WM_MPLIB} WM_COMPILE_OPTION=OptHB

