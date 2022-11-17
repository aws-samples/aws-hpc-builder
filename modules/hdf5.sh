#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

HDF5_VERSION=${2:-1.12.2}
HDF5_SRC="hdf5-${HDF5_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=true


install_sys_dependency_for_hdf5()
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
    ./configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    --libdir=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib \
	    --enable-fortran \
	    --enable-shared \
	    --enable-hl \
	    --enable-parallel \
	    --enable-unsupported && fix_clang_ld
    make check && sudo --preserve-env=PATH,LD_LIBRARY_PATH env make install && cd ..
}

update_hdf5_version()
{
    MODULE_VERSION=${HDF5_VERSION}
}
