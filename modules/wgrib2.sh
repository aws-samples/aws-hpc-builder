#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

WGRIB2_VERSION=${2:-3.1.2}
WGRIB2_SRC="wgrib2.tar.gz.v${WGRIB2_VERSION}"
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_wgrib2()
{
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y update
	    case  "${S_NAME}" in
		"Alibaba Cloud Linux (Aliyun Linux)"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		    sudo yum -y install tmux git
		    ;;
		"Amazon Linux")
		    sudo yum -y install tmux git
		    ;;
	    esac
	    ;;
	8)
	    sudo $(dnf check-release-update 2>&1 | grep "dnf update --releasever" | tail -n1) -y 2> /dev/null
	    sudo dnf -y update
	    sudo dnf -y install tmux git
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
	    sudo apt-get -y install tmux git
	    ;;
	*)
	    exit 1
	    ;;
    esac
}

download_wgrib2()
{
    if [ -f ${WGRIB2_SRC} ]
    then
        return
    else
	wget https://www.ftp.cpc.ncep.noaa.gov/wd51we/wgrib2/${WGRIB2_SRC}
	return $?
    fi
}


patch_wgrib2()
{
    patch -Np1 < ../../wgrib2/wgrib2-$(uname -m)-${HPC_COMPILER}.patch
}

install_wgrib2()
{
    echo "zzz *** $(date) *** Build wgrib2-${WGRIB2_VERSION}"
    sudo rm -rf grib2
    tar xf "${WGRIB2_SRC}"
    cd grib2
    patch_wgrib2

    export BUILD=$(${CC} -dumpmachine)
    export NETCDF_INCLUDES=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include
    export NETCDF_LIBRARIES=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib
    export HDF5_INCLUDES=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include
    export HDF5_LIBRARIES=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib

    make && \
	sudo cp wgrib2/wgrib2 ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/bin && \
	cd ..
}

update_wgrib2_version()
{
    MODULE_VERSION=${WGRIB2_VERSION}
}
