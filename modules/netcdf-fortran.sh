#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

NETCDF_FORTRAN_VERSION=${2:-4.5.4}
NETCDF_FORTRAN_SRC="netcdf-fortran-${NETCDF_FORTRAN_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_netcdf_fortran()
{
    # packages for build gcc/binutils ref: https://wiki.osdev.org/Building_GCC
    # packages for armclang(libtinfo.so.5)
    # packages for build elfutils ref: https://github.com/iovisor/bcc/issues/3601  sqlite-devel, libcurl-devel libmicrohttpd-devel and libarchive-devel
    # packages for build wrf
    # packages for build wps
    # packages for install Intel OneAPI compiler and toolchains
    if [ ${VERSION_ID} -eq 2 ]
    then
	sudo yum -y update
	#sudo yum -y install hdf5-devel zlib-devel libcurl-devel cmake3 m4 openmpi-devel libxml2-devel libtirpc-devel bzip2-devel jasper-devel libpng-devel zlib-devel libjpeg-turbo-devel tmux patch git
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

download_netcdf_fortran() {
    if [ -f ${NETCDF_FORTRAN_SRC} ]
    then
	return
    else
	wget "https://downloads.unidata.ucar.edu/netcdf-fortran/${NETCDF_FORTRAN_VERSION}/${NETCDF_FORTRAN_SRC}"
	return $?
    fi
}

install_netcdf_fortran()
{
    echo "zzz *** $(date) *** Build ${NETCDF_FORTRAN_SRC%.tar.gz}"
    sudo rm -rf "${NETCDF_FORTRAN_SRC%.tar.gz}"
    tar xf "${NETCDF_FORTRAN_SRC}"
    cd "${NETCDF_FORTRAN_SRC%.tar.gz}"
    mkdir build
    cd build
	    #--build=${WRF_TARGET} \
	    #--host=${WRF_TARGET} \
	    #--target=${WRF_TARGET} \
    #CC=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/bin/mpicc FC=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/bin/mpif90 F77=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/bin/mpif77 \
    CPPFLAGS=-I${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include LDFLAGS=-L${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib \
    ../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
            --libdir=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib \
            --enable-shared
    fix_clang_ld
    make check
    sudo --preserve-env=PATH,LD_LIBRARY_PATH env make install
    cd ../..
}

update_netcdf_fortran_version()
{
    MODULE_VERSION=${NETCDF_FORTRAN_VERSION}
}
