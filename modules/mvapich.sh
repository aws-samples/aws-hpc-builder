#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

# to support efa version must be 3.0a+
MVAPICH_VERSION=${2:-3.0a}
MVAPICH_SRC="mvapich2-${MVAPICH_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_mvapich()
{
    return
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
	case  "${S_NAME}" in
	    "Alibaba Cloud Linux (Aliyun Linux)")
		sudo yum -y install libfabric libfabric-devel rdma-core-devel librdmacm-utils libpsm2-devel infinipath-psm-devel libibverbs-utils
		;;
	    *)
		continue
		;;
	esac
    elif [ ${S_VERSION_ID} -eq 8 ]
    then
	sudo $(dnf check-release-update 2>&1 | grep "dnf update --releasever" | tail -n1) -y 2> /dev/null
       	sudo dnf -y update
       	sudo dnf -y install \
		gcc gcc-c++ make bison flex gmp-devel libmpc-devel mpfr-devel texinfo isl-devel \
		ncurses-compat-libs \
		sqlite-devel libarchive-devel libmicrohttpd-devel libcurl-devel \
	       	wget time dmidecode tcsh libtirpc-devel \
		mesa-libgbm gtk3 xdg-utils libnotify libxcb environment-modules \
		libXrender-devel expat-devel libX11-devel freetype-devel fontconfig-devel expat-devel libXext-devel pixman-devel cairo-devel \
		zlib-devel libcurl-devel cmake m4 libxml2-devel bzip2-devel jasper-devel libpng-devel zlib-devel libjpeg-turbo-devel tmux patch git
	case  "${S_NAME}" in
	    "Alibaba Cloud Linux")
		sudo dnf -y install libfabric libfabric-devel
		;;
	    "Amazon Linux"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		sudo dnf -y install libxcrypt-compat
		;;
	    *)
		continue
		;;
	esac
    else
	exit 1
    fi
}

download_mvapich() {
    echo "zzz *** $(date) *** Downloading source code ${MVAPICH_SRC}"
    if [ -f ${MVAPICH_SRC} ]
    then
        return
    else
	wget https://mvapich.cse.ohio-state.edu/download/mvapich/mv2/${MVAPICH_SRC}
	return $?
    fi
}

install_mvapich()
{
    if [ ${HPC_MPI} != "mvapich" ]
    then
        echo "Current MPI is not mvapich, installation stopped" 1>&2
        return 1
    fi

    sudo rm -rf "${MVAPICH_SRC%.tar.gz}"
    tar xf "${MVAPICH_SRC}"
    cd "${MVAPICH_SRC%.tar.gz}"
    mkdir -p build
    cd build
    if [ -d /opt/amazon/efa ]
    then
	    #--build=${HPC_TARGET} \
	    #--host=${HPC_TARGET} \
	    #--target=${HPC_TARGET} \
	if [ "$(basename ${FC})" == "gfortran" ]
	then
	    # a mvapich bug, have to remove the space between ch4:ofi and "\"
	    FFLAGS=-fallow-argument-mismatch FCFLAGS=-fallow-argument-mismatch ../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
		--with-device=ch4:ofi\
		--with-libfabric=/opt/amazon/efa
        else
	    ../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
		--with-device=ch4:ofi\
		--with-libfabric=/opt/amazon/efa
	fi
    else
	if [ "$(basename ${FC})" == "gfortran" ]
	then
	    FFLAGS=-fallow-argument-mismatch FCFLAGS=-fallow-argument-mismatch ../configure --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} \
		--with-device=ch4:ofi
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

update_mvapich_version()
{
    MODULE_VERSION=${MVAPICH_VERSION}
}
