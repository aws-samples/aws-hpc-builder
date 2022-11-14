#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

PNETCDF_VERSION=${2:-1.12.3}
PNETCDF_SRC="pnetcdf-${PNETCDF_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=true

install_sys_dependency_for_pnetcdf()
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

download_pnetcdf() {
    echo "zzz *** $(date) *** Downloading source code ${PNETCDF_SRC}"
    if [ -f ${PNETCDF_SRC} ]
    then
	return
    else
	wget "https://parallel-netcdf.github.io/Release/${PNETCDF_SRC}"
	return $?
    fi
}


install_pnetcdf()
{
    sudo rm -rf "${PNETCDF_SRC%.tar.gz}"
    tar xf "${PNETCDF_SRC}"
    cd "${PNETCDF_SRC%.tar.gz}"
    mkdir -p build
    cd build
    # pnetcdf has to disable compiler env
    # pnetcdf 要设置mpicc等，或者取消掉CC 等环境变量设置
    #configure: error:
    #-----------------------------------------------------------------------
    # Invalid MPI compiler specified or detected: "/fsx/wrf-aarch64/opt/arm-linux-compiler-22.1_Generic-AArch64_RHEL-7_aarch64-linux/bin/armclang"
    # A working MPI C compiler is required. Please specify the location
    # of one either in the MPICC environment variable (not CC variable) or
    # through --with-mpi configure flag. Abort.
    #-----------------------------------------------------------------------
	    #--build=${HPC_TARGET} \
	    #--host=${HPC_TARGET} \
	    #--target=${HPC_TARGET} \
    ../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER} \
	    --enable-fortran \
            --enable-shared && fix_clang_ld 
    make && sudo --preserve-env=PATH,LD_LIBRARY_PATH env make install && cd ../..
}

update_pnetcdf_version()
{
    MODULE_VERSION=${PNETCDF_VERSION}
}
