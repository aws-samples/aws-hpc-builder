#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#WRF_VERSION=git
WRF_VERSION=4.4.1
WPS_VERSION=${2:-4.4}
DISABLE_COMPILER_ENV=false

# 读取命令行新的版本信息后再计算WRF的主要版本等信息
WRF_MAJOR_VERSION=${WRF_VERSION%%.*}
#　与官方开始支持ARM　版本有关（4.2 以后版本加入了 ARM )
WRF_ARM_VERSION=$(echo ${WRF_VERSION} | awk -F'.' '{print $1$2}')
# WPS 4.3.1 版本以后开始才开始支持 gfortran 9
WPS_GNU_VERSION=$(echo ${WPS_VERSION} | awk -F'.' '{print $1$2}')

WRF_SRC="WRF-${WRF_VERSION}.tar.gz"
WPS_SRC="WPS-${WPS_VERSION}.tar.gz"

install_sys_dependency_for_wps()
{
    # packages for build wps
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y update
	    sudo yum -y install mesa-libgbm at-spi gtk3 xdg-utils libnotify libxcb jasper-devel \
		libXrender-devel expat-devel libX11-devel freetype-devel fontconfig-devel expat-devel libXext-devel pixman-devel cairo-devel


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
	    sudo dnf -y install mesa-libgbm at-spi gtk3 xdg-utils libnotify libxcb jasper-devel \
		libXrender-devel expat-devel libX11-devel freetype-devel fontconfig-devel expat-devel libXext-devel pixman-devel cairo-devel

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
	    sudo apt-get -y install libgbm1 libgtk-3-0 xdg-utils libnotify4 libxcb1 tcl environment-modules \
                libxrender-dev libexpat1-dev libx11-dev libfreetype6-dev libfontconfig1-dev libxext-dev libpixman-1-dev libcairo2-dev
	    ;;
	*)
	    exit 1
	    ;;
    esac
}

set_wps_build_env()
{
    export NETCDF=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    export JASPERLIB=/usr/lib64
    export JASPERINC=/usr/include
    #export PNETCDF=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    #export HDF5=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    #export PHDF5=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    #export NETCDF_classic=1
}

download_wps() {
    if [ "${WPS_VERSION+set}" == "set" ]
    then
	if [ "${WPS_VERSION}" == "git" ]
	then
	    git clone https://github.com/wrf-model/WPS.git
	    return $?
	else
	    if  [ -f ${WPS_SRC} ]
	    then
		return
	    else
		wget "https://github.com/wrf-model/WPS/archive/refs/tags/v${WPS_VERSION}.tar.gz" -O "${WPS_SRC}"
		return $?
	    fi
	fi
    fi
    return -1
}

check_wrf_config()
{
    if [ "${SARCH}" == "aarch64" ]
    then
	export WRF_CONFIG=4
    elif [ "${SARCH}" == "x86_64" ] && [ "${HPC_COMPILER}" == "icc" ]
    then
    	export WRF_CONFIG=16
    else
	export WRF_CONFIG=35
    fi
}

check_wps_config()
{
    export WPS_CONFIG=3
}
patch_wps()
{
    patch -Np1 < "../../patch/wps/WPS-${SARCH}-${HPC_COMPILER}.patch"
    if [ ${WPS_GNU_VERSION} -lt 43 ]
    then
	patch -Np1 < "../../patch/wps/WPS-4.x-${HPC_COMPILER}.patch"
    fi
    
    if [ ${WPS_GNU_VERSION} -lt 41 ]
    then
	patch -Np1 < "../../patch/wps/WPS-4.x-mismatch-integer-iand.patch"
    fi
}

install_wps()
{
    echo "zzz *** $(date) *** Build WPS-${WPS_VERSION}"
    if [ "${WPS_VERSION}" == "git" ]
    then
       	sudo rm -rf "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/WRF-${WRF_VERSION}/WPS-${WPS_VERSION}"
        cd WPS
    else
       	sudo rm -rf "${WPS_SRC%.tar.gz}" "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/WRF-${WRF_VERSION}/${WPS_SRC%.tar.gz}"
        tar xf "${WPS_SRC}"
       	cd "${WPS_SRC%.tar.gz}"
    fi

    export WRF_DIR=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/WRF-${WRF_VERSION}

    patch_wps
    check_wps_config
    set_wps_build_env

    # 由于MPI_LIB 与 openmpi 环境变量冲突，取消此环境变量再编译
    unset MPI_LIB

    # WPS 4.1 及以上的版本才支持 WRF_DIR, 旧版本会搜寻上级目录的WRFV3
    if [ ${WPS_GNU_VERSION} -le 41 ]
    then
        ln -sf ${WRF_DIR} ../WRFV3
    else
        rm -f ../WRFV3
    fi

    # disable MAKEFLAGS
    unset MAKEFLAGS

    if [ "${WPS_CONFIG+set}" == "set" ]
    then
        echo -e "${WPS_CONFIG}\n" | ./configure
    else 
	echo "unsupported platform"
	exit 1
    fi

    ./compile >> "${HPC_BUILD_LOG}" 2>&1
    rm -f ../WRFV3
    cd ..

    if [ "${WPS_VERSION}" == "git" ]
    then
	sudo mv WPS "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/WRF-${WRF_VERSION}/WPS-${WPS_VERSION}"
    else 
	sudo mv "${WPS_SRC%.tar.gz}" "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/WRF-${WRF_VERSION}/"
    fi
}

update_wps_version()
{
    MODULE_VERSION=${WPS_VERSION}
}
