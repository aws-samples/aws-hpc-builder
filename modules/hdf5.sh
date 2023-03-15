#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

HDF5_VERSION=${2:-1.12.2}
HDF5_SRC="hdf5-${HDF5_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=true


install_sys_dependency_for_hdf5()
{
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y update
	    case "${S_NAME}" in
		"Alibaba Cloud Linux (Aliyun Linux)"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		    return
		    ;;
		"Amazon Linux")
		    return
		    ;;
	    esac
	    ;;
	8)
	    sudo $(dnf check-release-update 2>&1 | grep "dnf update --releasever" | tail -n1) -y 2> /dev/null
	    sudo dnf -y update
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
	    ;;
	*)
	    exit 1
	    ;;
    esac
}

download_hdf5()
{
    if [ -f ${HDF5_SRC} ]
    then
        return
    else
	wget "https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${HDF5_VERSION%.*}/hdf5-${HDF5_VERSION}/src/hdf5-${HDF5_VERSION}.tar.gz"
	return $?
    fi
}

install_hdf5()
{
    echo "zzz *** $(date) *** Build ${HDF5_SRC%.tar.gz}"
    sudo rm -rf "${HDF5_SRC%.tar.gz}"
    tar xf "${HDF5_SRC}"
    cd "${HDF5_SRC%.tar.gz}"
    # https://forum.hdfgroup.org/t/compilation-with-aocc-clang-error/6148
    # https://stackoverflow.com/questions/4580789/ld-unknown-option-soname-on-os-x
	    #--build=${WRF_TARGET} \
	    #--host=${WRF_TARGET} \
	    #--target=${WRF_TARGET} \
    #CC=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/bin/mpicc FC=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/bin/mpif90 ./configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \

    # add intelmpi support
    if [ "${HPC_MPI}" == "intelmpi" ]
    then
	LIBS_OPTS="-lmpi -lmpifort -L${I_MPI_ROOT}/lib -L${I_MPI_ROOT}/lib/release ${LIBS}"
    fi
    ./configure LIBS="${LIBS_OPTS}" --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    --libdir=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib \
	    --enable-fortran \
	    --enable-shared \
	    --enable-hl \
	    --enable-parallel \
	    --enable-unsupported && fix_clang_ld
    # bulid with mpich fails on check due to limited stacksize on some systems
    #make check && sudo --preserve-env=PATH,LD_LIBRARY_PATH,I_MPI_CC,I_MPI_CXX,I_MPI_FC,I_MPI_F77,I_MPI_F90 env make install && cd .. 
    make && sudo --preserve-env=PATH,LD_LIBRARY_PATH,I_MPI_CC,I_MPI_CXX,I_MPI_FC,I_MPI_F77,I_MPI_F90 env make install && cd ..
}

update_hdf5_version()
{
    MODULE_VERSION=${HDF5_VERSION}
}
