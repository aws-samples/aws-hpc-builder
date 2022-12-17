#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

SCALAPACK_VERSION=${2:-2.2.1}
SCALAPACK_SRC="scalapack-${SCALAPACK_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_scalapack()
{
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y update
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

download_scalapack() {
    echo "zzz *** $(date) *** Downloading source code ${SCALAPACK_SRC}"
    if [ -f ${SCALAPACK_SRC} ]
    then
        return
    else
	wget "https://github.com/Reference-ScaLAPACK/scalapack/archive/refs/tags/v${SCALAPACK_VERSION}.tar.gz" -O ${SCALAPACK_SRC}
	return $?
    fi
}

install_scalapack()
{
    sudo rm -rf "${SCALAPACK_SRC%.tar.gz}"
    tar xf "${SCALAPACK_SRC}"
    cd "${SCALAPACK_SRC%.tar.gz}"
    mkdir -p build
    cd build
    if [ "${HPC_COMPILER}" == "armgcc" ]
    then
	CC=mpicc FC=mpif90 cmake3 .. -DMPIEXEC=mpirun -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} -DBUILD_SHARED_LIBS=ON -DCMAKE_Fortran_FLAGS="-fallow-argument-mismatch -fallow-invalid-boz" -DLAPACK_LIBRARIES=${ARMPL_DIR}/lib/libarmpl.so -DBLAS_LIBRARIES=${ARMPL_DIR}/lib/libarmpl.so
    elif [ "${HPC_COMPILER}" == "armclang" ]
    then
	CC=mpicc FC=mpif90 cmake3 .. -DMPIEXEC=mpirun -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} -DBUILD_SHARED_LIBS=ON -DLAPACK_LIBRARIES=${ARMPL_DIR}/lib/libarmpl.so -DBLAS_LIBRARIES=${ARMPL_DIR}/lib/libarmpl.so
    else
        echo "Not supported compiler"
        exit 1
    fi
    make && sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB env make install && cd ../..
}

update_scalapack_version()
{
    MODULE_VERSION=${SCALAPACK_VERSION}
}
