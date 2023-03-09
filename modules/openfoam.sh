#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

OPENFOAM_VERSION=${2:-2212}
THIRDPARTY_SRC=ThirdParty-v${OPENFOAM_VERSION}.tgz
OPENFOAM_SRC=OpenFOAM-v${OPENFOAM_VERSION}.tgz
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_openfoam()
{
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y update
	    case  "${S_NAME}" in
		"Alibaba Cloud Linux (Aliyun Linux)"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		    sudo yum -y install tmux git
		    ;;
		"Amazon Linux")
		    sudo yum -y install tmux git
		    ;;
	    esac
	    ;;
	8)
	    sudo $(dnf check-release-update 2>&1 | grep "dnf update --releasever" | tail -n1) -y 2> /dev/null
	    sudo dnf -y update
	    sudo dnf -y install tmux git
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
	    sudo apt-get -y update
	    sudo apt-get -y install tmux git
	    ;;
	*)
	    exit 1
	    ;;
    esac
}

download_openfoam()
{
    if [ -f ${OPENFOAM_SRC} ]
    then
        return
    else
	wget https://dl.openfoam.com/source/v${OPENFOAM_VERSION}/OpenFOAM-v${OPENFOAM_VERSION}.tgz
	return $?
    fi

    if [ -f ${THIRDPARTY_SRC} ]
    then
        return
    else
	wget https://dl.openfoam.com/source/v${OPENFOAM_VERSION}/ThirdParty-v${OPENFOAM_VERSION}.tgz
	return $?
    fi

}

patch_openfoam()
{
    if [ -f ../../patch/openfoam/openfoam-$(arch)-${HPC_COMPILER}.patch ]
    then
	patch -Np1 < ../../patch/openfoam/openfoam-$(arch)-${HPC_COMPILER}.patch
    fi
}

install_openfoam()
{
    echo "zzz *** $(date) *** Build ${OPENFOAM_SRC%.tgz}"
    sudo rm -rf "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/${OPENFOAM_SRC%.tgz}"
    sudo rm -rf "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/${THIRDPARTY_SRC%.tgz}"
    tar xf "${OPENFOAM_SRC%.tgz}"
    tar xf "${THIRDPARTY_SRC%.tgz}"
    sudo mv "${OPENFOAM_SRC%.tgz}" "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/"
    sudo mv "${THIRDPARTY_SRC%.tgz}" "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/"

    export MPI_ROOT=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    export MPI_ARCH_FLAGS="-DOMPI_SKIP_MPICXX"
    export MPI_ARCH_INC="-isystem $MPI_ROOT/include"
    export MPI_ARCH_LIBS="-L$MPI_ROOT/lib -lmpi"
    
    case ${HPC_COMPILER} in
	"amdclang")
	    WM_COMPILER=Amd
	    ;;
	"armclang")
	    WM_COMPILER=Arm
	    ;;
	"armgcc"|"gcc")
	    WM_COMPIER=Gcc
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
	"mpich"|"mvapich"|"nvidiampi"|"openmpi")
	    WM_MPILIB="SYSTEMMPI"
	    ;;
	*)
	    exit 1
	    ;;
    esac
    
    .   "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/OpenFOAM-v${OPENFOAM_VERSION}/etc/bashrc" WM_COMPILER=${WM_COMPILER} WM_MPLIB=${WM_MPLIB}
    foam
    ./Allwmake -s -l
    cd -

}

update_openfoam_version()
{
    MODULE_VERSION=${OPENFOAM_VERSION}
}
