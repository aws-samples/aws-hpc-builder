#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

OPENMPI_VERSION=${2:-4.1.4}
OPENMPI_SRC="openmpi-${OPENMPI_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_openmpi()
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

download_openmpi() {
    echo "zzz *** $(date) *** Downloading source code ${OPENMPI_SRC}"
    if [ -f ${OPENMPI_SRC} ]
    then
        return
    else
	wget "https://download.open-mpi.org/release/open-mpi/v${OPENMPI_VERSION%.*}/${OPENMPI_SRC}"
	return $?
    fi
}

install_openmpi()
{
    if [ ${HPC_MPI} != "openmpi" ]
    then
	echo "Current MPI is not openmpi, installation stopped" 1>&2
	return 1
    fi
    
    sudo rm -rf "${OPENMPI_SRC%.tar.gz}"
    tar xf "${OPENMPI_SRC}"
    cd "${OPENMPI_SRC%.tar.gz}"
    mkdir -p build
    cd build
    if [ -d /opt/amazon/efa ]
    then
	    #--build=${WRF_TARGET} \
	    #--host=${WRF_TARGET} \
	    #--target=${WRF_TARGET} \
	../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
	    --with-ofi=/opt/amazon/efa
    else
	    #--build=${WRF_TARGET} \
	    #--host=${WRF_TARGET} \
	    #--target=${WRF_TARGET}
	../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    fi
    result=$?
    if [ $result -ne 0 ]
    then
        return  $result
    fi
    make && sudo --preserve-env=PATH,LD_LIBRARY_PATH env make install && cd ../..
}

update_openmpi_version()
{
    MODULE_VERSION=${OPENMPI_VERSION}
}
