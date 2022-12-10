#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

MPICH_VERSION=${2:-4.0.3}
MPICH_SRC="mpich-${MPICH_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_mpich()
{
    # packages for build gcc/binutils ref: https://wiki.osdev.org/Building_GCC
    # packages for armclang(libtinfo.so.5)
    # packages for build elfutils ref: https://github.com/iovisor/bcc/issues/3601  sqlite-devel, libcurl-devel libmicrohttpd-devel and libarchive-devel
    # packages for build wrf
    # packages for build wps
    # packages for install Intel OneAPI compiler and toolchains
    if [ ${S_VERSION_ID} -eq 7 ]
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
	if [ "$(sudo dmidecode -s system-product-name)" == "Alibaba Cloud ECS" ]
	then
	    sudo yum -y install libfabric libfabric-devel
	fi
    elif [ ${S_VERSION_ID} -eq 8 ]
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
	if [ "$(sudo dmidecode -s system-product-name)" == "Alibaba Cloud ECS" ]
	then
	    sudo dnf -y install libfabric libfabric-devel
	fi
    else
	exit 1
    fi
}

download_mpich() {
    echo "zzz *** $(date) *** Downloading source code ${MPICH_SRC}"
    if [ -f ${MPICH_SRC} ]
    then
        return
    else
	wget "https://www.mpich.org/static/downloads/${MPICH_VERSION}/${MPICH_SRC}"
	return $?
    fi
}

install_mpich()
{
    if [ ${HPC_MPI} != "mpich" ]
    then
        echo "Current MPI is not mpich, installation stopped" 1>&2
        return 1
    fi

    sudo rm -rf "${MPICH_SRC%.tar.gz}"
    tar xf "${MPICH_SRC}"
    cd "${MPICH_SRC%.tar.gz}"
    mkdir -p build
    cd build
    if [ -d /opt/amazon/efa ]
    then
	    #--build=${HPC_TARGET} \
	    #--host=${HPC_TARGET} \
	    #--target=${HPC_TARGET} \
	if [ "$(basename ${FC})" == "gfortran" ]
	then
	    FFLAGS=-fallow-argument-mismatch FCFLAGS=-fallow-argument-mismatch ../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
		--with-device=ch4:ofi \
		--with-libfabric=/opt/amazon/efa
        else
	    ../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
		--with-device=ch4:ofi \
		--with-libfabric=/opt/amazon/efa
	fi
    else
	if [ "$(basename ${FC})" == "gfortran" ]
	then
	    FFLAGS=-fallow-argument-mismatch FCFLAGS=-fallow-argument-mismatch ../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
	else
	    ../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
		--with-device=ch4:ofi
	fi
    fi
    result=$?
    if [ $result -ne 0 ]
    then
        return  $result
    fi
    make && sudo --preserve-env=PATH,LD_LIBRARY_PATH env make install && cd ../..
}

update_mpich_version()
{
    MODULE_VERSION=${MPICH_VERSION}
}
