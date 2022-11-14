#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

SCALAPACK_VERSION=${2:-2.2.1}
SCALAPACK_SRC="scalapack-${SCALAPACK_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_scalapack()
{
    return
    # packages for build gcc/binutils ref: https://wiki.osdev.org/Building_GCC
    # packages for armclang(libtinfo.so.5)
    # packages for build elfutils ref: https://github.com/iovisor/bcc/issues/3601  sqlite-devel, libcurl-devel libmicrohttpd-devel and libarchive-devel
    # packages for build wrf
    # packages for build wps
    # packages for install Intel OneAPI compiler and toolchains
    if [ ${VERSION_ID} -eq 2 ]
    then
	sudo yum -y update
	#sudo yum -y install hdf5-devel zlib-devel libcurl-devel cmake3 m4 scalapack-devel libxml2-devel libtirpc-devel bzip2-devel jasper-devel libpng-devel zlib-devel libjpeg-turbo-devel tmux patch git
	sudo yum -y install \
		gcc gcc-c++ make bison flex gmp-devel libmpc-devel mpfr-devel texinfo isl-devel \
		ncurses-compat-libs \
		sqlite-devel libarchive-devel libmicrohttpd-devel libcurl-devel \
		wget time dmidecode tcsh libtirpc-devel \
	       	mesa-libgbm at-spi gtk3 xdg-utils libnotify libxcb environment-modules \
		libXrender-devel expat-devel libX11-devel freetype-devel fontconfig-devel expat-devel libXext-devel pixman-devel cairo-devel \
	       	zlib-devel libcurl-devel cmake3 m4 libxml2-devel bzip2-devel jasper-devel libpng-devel zlib-devel libjpeg-turbo-devel tmux patch git   
    elif [ ${VERSION_ID} -eq 2022 ]
    then
	sudo $(dnf check-release-update 2>&1 | grep "dnf update --releasever" | tail -n1) -y 2> /dev/null
       	sudo dnf -y update
       	sudo dnf -y install \
		gcc gcc-c++ make bison flex gmp-devel libmpc-devel mpfr-devel texinfo isl-devel \
		ncurses-compat-libs \
		sqlite-devel libarchive-devel libmicrohttpd-devel libcurl-devel \
	       	wget time dmidecode tcsh libtirpc-devel \
		mesa-libgbm gtk3 xdg-utils libnotify libxcb libxcrypt-compat environment-modules \
		libXrender-devel expat-devel libX11-devel freetype-devel fontconfig-devel expat-devel libXext-devel pixman-devel cairo-devel \
		zlib-devel libcurl-devel cmake m4 libxml2-devel bzip2-devel jasper-devel libpng-devel zlib-devel libjpeg-turbo-devel tmux patch git
    else
	exit 1
    fi
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
	CC=mpicc FC=mpif90 cmake3 .. -DMPIEXEC=mpirun -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER} -DBUILD_SHARED_LIBS=ON -DCMAKE_Fortran_FLAGS="-fallow-argument-mismatch -fallow-invalid-boz" -DLAPACK_LIBRARIES=${ARMPL_DIR}/lib/libarmpl.so -DBLAS_LIBRARIES=${ARMPL_DIR}/lib/libarmpl.so
    elif [ "${HPC_COMPILER}" == "armclang" ]
    then
	CC=mpicc FC=mpif90 cmake3 .. -DMPIEXEC=mpirun -DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/${HPC_COMPILER} -DBUILD_SHARED_LIBS=ON -DLAPACK_LIBRARIES=${ARMPL_DIR}/lib/libarmpl.so -DBLAS_LIBRARIES=${ARMPL_DIR}/lib/libarmpl.so
    else
        echo "Not supported compiler"
        exit 1
    fi
    make && sudo --preserve-env=PATH,LD_LIBRARY_PATH env make install && cd ../..
}

update_scalapack_version()
{
    MODULE_VERSION=${SCALAPACK_VERSION}
}
