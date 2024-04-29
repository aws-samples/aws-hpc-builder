#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

HDF5_VERSION=${2:-1.14.4.2}
HDF5_SRC="hdf5-hdf5_${HDF5_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=false


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
	#curl --retry 3 -JLOk "https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${HDF5_VERSION%.*}/hdf5-${HDF5_VERSION}/src/hdf5-${HDF5_VERSION}.tar.gz"
	curl --retry 3 -JLOk "https://github.com/HDFGroup/hdf5/archive/refs/tags/hdf5_${HDF5_VERSION}.tar.gz"
	return $?
    fi
}

install_hdf5()
{
    echo "zzz *** $(date) *** Build ${HDF5_SRC%.tar.gz}"
    sudo rm -rf "${HDF5_SRC%.tar.gz}" ${HDF5_SRC%.tar.gz}-build
    tar xf "${HDF5_SRC}"

    if [ -f ../patch/hdf5/hdf5-${JASPER_VERSION}.patch ]
    then
        cd "${HDF5_SRC%.tar.gz}"
	patch -Np1 < ../../patch/hdf5/hdf5-${HDF5_VERSION}.patch
	cd ..
    fi

    # https://forum.hdfgroup.org/t/compilation-with-aocc-clang-error/6148
    # https://stackoverflow.com/questions/4580789/ld-unknown-option-soname-on-os-x
	    #--build=${HPC_TARGET} \
	    #--host=${HPC_TARGET} \
	    #--target=${HPC_TARGET} \
    #CC=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/bin/mpicc FC=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/bin/mpif90 ./configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \

    # support intelmpi and the combination of intelmpi + non-intel compilers
    if [ "${HPC_MPI}" == "intelmpi" ] && [ "${HPC_COMPILER}" == "icc" ]
    then
        LIBS_OPTS="-lmpi -lmpifort -L${I_MPI_ROOT}/lib -L${I_MPI_ROOT}/lib/release ${LIBS}"
        CXX_OPTS=$(which mpiicpc)
        FC_OPTS=$(which mpiifort)
        CC_OPTS=$(which mpiicc)
    else
        CXX_OPTS=$(which mpicxx)
        FC_OPTS=$(which mpif90)
        CC_OPTS=$(which mpicc)
    fi
    # bulid with mpich fails on check due to limited stacksize on some systems
    #make check && sudo --preserve-env=PATH,LD_LIBRARY_PATH,I_MPI_CC,I_MPI_CXX,I_MPI_FC,I_MPI_F77,I_MPI_F90 env make install && cd .. 
    mkdir -p "${HDF5_SRC%.tar.gz}-build"

    cmake -H${HDF5_SRC%.tar.gz} -B${HDF5_SRC%.tar.gz}-build \
	    -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} -DCMAKE_PREFIX_PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    -DBUILD_SHARED_LIBS=ON \
	    -DHDF5_BUILD_FORTRAN=ON \
	    -DHDF5_BUILD_HL_LIB=ON \
	    -DHDF5_ENABLE_PARALLEL=ON \
	    -DHDF5_ENABLE_LARGE_FILE=ON \
	    -DHDF5_BUILD_TOOLS=ON \
	    -DHDF5_BUILD_FORTRAN=ON \
	    -DHDF5_ENABLE_PARALLEL=ON || exit 1

    cmake --build "${HDF5_SRC%.tar.gz}-build"  -j $(nproc) || exit 1

    sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB,I_MPI_CC,I_MPI_CXX,I_MPI_FC,I_MPI_F77,I_MPI_F90 env cmake --install "${HDF5_SRC%.tar.gz}-build" \
	    && sudo rm -rf ${HDF5_SRC%.tar.gz} ${HDF5_SRC%.tar.gz}-build || exit 1

    # add compatible links
    sudo ln -s libhdf5_hl_fortran.so libhdf5hl_fortran.so
    sudo ln -s libhdf5_hl_fortran.a libhdf5hl_fortran.a
    sudo mv libhdf5hl_fortran.a libhdf5hl_fortran.so ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib

}

update_hdf5_version()
{
    MODULE_VERSION=${HDF5_VERSION}
}
