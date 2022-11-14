#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#WRF_VERSION=git
WRF_VERSION=${2:-4.2.2}
DISABLE_COMPILER_ENV=false

# 读取命令行新的版本信息后再计算WRF的主要版本等信息
WRF_MAJOR_VERSION=${WRF_VERSION%%.*}
#　与官方开始支持ARM　版本有关（4.2 以后版本加入了 ARM )
WRF_ARM_VERSION=$(echo ${WRF_VERSION} | awk -F'.' '{print $1$2}')

WRF_SRC="WRF-${WRF_VERSION}.tar.gz"

install_sys_dependency_wrf()
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

download_wrf() {
    echo "zzz *** $(date) *** Downloading source code ${WRF_SRC}"
    if [ "${WRF_VERSION}" == "git" ]
    then
	git clone https://github.com/wrf-model/WRF.git
	return $?
    else
        if  [ -f ${WRF_SRC} ]
       	then
            return
	else
            if [ ${WRF_MAJOR_VERSION} -gt 3 ]
	    then
	        wget "https://github.com/wrf-model/WRF/archive/refs/tags/v${WRF_VERSION}.tar.gz" -O "${WRF_SRC}"
		return $?
	    else 
	        wget "https://github.com/wrf-model/WRF/archive/refs/tags/V${WRF_VERSION}.tar.gz" -O "${WRF_SRC}"
		return $?
	    fi
       	fi
    fi
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

set_wrf_build_env()
{
    echo "zzz *** $(date) *** Setup build env"
    export NETCDF=${HPC_PREFIX}/${HPC_COMPILER}
    export PNETCDF=${HPC_PREFIX}/${HPC_COMPILER}
    export HDF5=${HPC_PREFIX}/${HPC_COMPILER}
    export PHDF5=${HPC_PREFIX}/${HPC_COMPILER}
    export JASPERLIB=/usr/lib64
    export JASPERINC=/usr/include
    export WRFIO_NCD_LARGE_FILE_SUPPORT=1
    export NETCDF_classic=1
}

build_wrf_dependency()
{
    echo "zzz *** $(date) *** Build WRF dependency"
    if [ "${BUILD_ALL}" == "all" ]
    then
	#sleep 1
	install_vendor_compiler
    fi
    echo "Setup WRF build env"
    set_wrf_build_env
    set_compiler_env
    fix_lib_missing
   

    if [ "${BUILD_ALL}" == "all" ]
    then
	build_openmpi
	# hdf5 和 pnetcdf 使用mpicc/mpif90/mpif70 等编译，需要取消掉 CC/FC/F77等环境变量
        unset_compiler_env
	build_hdf5
	build_pnetcdf
        set_compiler_env
	build_netcdf_c
	build_netcdf_fortran
	#sleep 1
    fi
}

patch_wrf()
{
    # 精度问题, patch GIT 版本(加上SARCH 只需给特定平台(如aarch64) 提供patch, clang 通过 ${HPC_COMPILER} 差异提供或不提供补丁
    if [ "$WRF_VERSION" == "git" ] 
    then
	if [ -f "../../patch/wrf/WRF-${WRF_VERSION}-$(uname -m)-${HPC_COMPILER}.patch" ]
	then
	    patch -Np1 < "../../patch/wrf/WRF-${WRF_VERSION}-$(uname -m)-${HPC_COMPILER}.patch"
	fi
	if [ -f "../../patch/wrf/WRF-4.z-double-precision-${SARCH}.patch" ]
	then
	    patch -Np1 < "../../patch/wrf/WRF-4.z-double-precision-${SARCH}.patch"
	fi
	return
    fi
    # 精度问题, patch 其他版本
    if [ -f "../../patch/wrf/WRF-${WRF_MAJOR_VERSION}.x-double-precision-${SARCH}.patch" ]
    then
	patch -Np1 < "../../patch/wrf/WRF-${WRF_MAJOR_VERSION}.x-double-precision-${SARCH}.patch"
    fi
    
    # Amazon Linux 2022/RHEL8/Centos8/Oracle Linux 8's tirpc issue
    if [ ${WRF_ARM_VERSION} -lt 42 ] && [ ${VERSION_ID} -eq 2022 ]
    then
	patch -Np1 < "../../patch/wrf/WRF-tirpc.patch"
    fi

    # 编译器支持, aarch64
    if [ "${SARCH}" == "aarch64" ]
    then
	#PROCESSOR_TYPE=$(sudo dmidecode -t processor | grep -i Version | awk '{print $NF}')
        if [ ${WRF_ARM_VERSION} -lt 40 ] 
        then
	    if [ -f "../../patch/wrf/WRF-3.x-${SARCH}-${HPC_COMPILER}.patch" ]
	    then
		patch -Np1 < "../../patch/wrf/WRF-3.x-${SARCH}-${HPC_COMPILER}.patch"
                #patch -Np1 < "../../patch/wrf/WRF-3.x-${SARCH}-${PROCESSOR_TYPE}.patch"
	    fi
        elif [ ${WRF_ARM_VERSION} -lt 42 ]
        then 
	    if [ -f "../../patch/wrf/WRF-4.x-${SARCH}-${HPC_COMPILER}.patch" ]
	    then 
		#patch -Np1 < "../../patch/wrf/WRF-4.x-${SARCH}-${PROCESSOR_TYPE}.patch"
		patch -Np1 < "../../patch/wrf/WRF-4.x-${SARCH}-${HPC_COMPILER}.patch"
	    fi
	elif [ ${WRF_ARM_VERSION} -ge 42 ]
	then
	    if [ -f "../../patch/wrf/WRF-4.z-${SARCH}-${HPC_COMPILER}.patch" ]
	    then
		patch -Np1 < "../../patch/wrf/WRF-4.z-${SARCH}-${HPC_COMPILER}.patch"
	    fi
        fi
    # 编译器支持, intel and amd
    # Intel 和 AMD, 如果使用clang 和 gcc 可以使用同样的 patch, 所以这里补丁变量使用 $(uname -m)
    elif [ "${SARCH}" == "x86_64" ] || [ "${SARCH}" == "amd64" ]
    then
        if [ ${WRF_ARM_VERSION} -lt 40 ]
        then
	    if [ -f "../../patch/wrf/WRF-3.x-$(uname -m)-${HPC_COMPILER}.patch" ]
	    then
		patch -Np1 < "../../patch/wrf/WRF-3.x-$(uname -m)-${HPC_COMPILER}.patch"
	    fi
        elif [ ${WRF_ARM_VERSION} -lt 41 ]
        then
            # 对于icc, 事实上 4.0的最后一个版本 4.0.3 已经修正 "-openmpi" 成 "-gopenmpi", 所以只有4.1 之前非 4.0.3 版本需要此 icc 补丁
	    if [ "${HPC_COMPILER}" == "icc" ]
	    then
		if [ "${WRF_VERSION}" != "4.0.3" ]
		then
		    if [ -f "../../patch/wrf/WRF-4.x-${SARCH}-${HPC_COMPILER}.patch" ]
		    then
			patch -Np1 < "../../patch/wrf/WRF-4.x-${SARCH}-${HPC_COMPILER}.patch"
		    fi
		fi
	    else 
		# 对于gcc，或者clang 等编译器, 4.0.x 版本都使用相同的补丁
		if [ -f "../../patch/wrf/WRF-4.x-$(uname -m)-${HPC_COMPILER}.patch" ]
		then
		    patch -Np1 < "../../patch/wrf/WRF-4.x-$(uname -m)-${HPC_COMPILER}.patch"
		fi
	    fi
	else
	    # 使用开源编译器，可以使用相同的patch，所以这里用 $(uname -m)
	    if [ "${HPC_COMPILER}" != "icc" ]
	    then
		patch -Np1 < "../../patch/wrf/WRF-4.x-$(uname -m)-${HPC_COMPILER}.patch"
	    fi
        fi
    fi
}

install_wrf()
{
    build_wrf_dependency  >> "${HPC_BUILD_LOG}" 2>&1
    # 如果设置了 WPS 版本，并且指定的 WRF 已经编译好, 只编译WPS
    if [ "${WPS_VERSION+set}" == "set" ] && [ -f ${HPC_PREFIX}/${HPC_COMPILER}/WRF-${WRF_VERSION}/main/wrf.exe ]
    then
	return
    fi
    

    echo "zzz *** $(date) *** Build WRF-${WRF_VERSION}"
    if [ "${WRF_VERSION}" == "git" ]
    then
       	sudo rm -rf "${HPC_PREFIX}/${HPC_COMPILER}/WRF-${WRF_VERSION}"
        cd WRF
    else
       	sudo rm -rf "${WRF_SRC%.tar.gz}" "${HPC_PREFIX}/${HPC_COMPILER}/${WRF_SRC%.tar.gz}"
        tar xf "${WRF_SRC}"
       	cd "${WRF_SRC%.tar.gz}"
    fi

    patch_wrf

    check_wrf_config

    if [ "${WRF_CONFIG+set}" == "set" ]
    then
        echo -e "${WRF_CONFIG}\n1\n" | ./configure
    else 
	echo "unsupported platform"
	exit 1
    fi

    # 默认是 -j 2, 如果有问题,尝试改成 -j 1
    ./compile em_real >> "${HPC_BUILD_LOG}" 2>&1 && cd ..
    if [ "${WRF_VERSION}" == "git" ]
    then
	sudo mv WRF "${HPC_PREFIX}/${HPC_COMPILER}/WRF-${WRF_VERSION}"
    else 
	sudo mv "${WRF_SRC%.tar.gz}" "${HPC_PREFIX}/${HPC_COMPILER}/"
    fi
    sudo mkdir -p /fsx/scripts
    sudo install -m 755 -D -t /fsx/scripts ../scripts/env.sh 
    sudo install -m 755 -D -t /fsx/scripts ../scripts/detect_efa.sh
    sudo install -m 755 -D -t /fsx/scripts ../scripts/test.sh
    sudo install -m 755 -D -t /fsx/scripts ../scripts/submit.sbatch
    #if [ ${WRF_MAJOR_VERSION} -lt 4 ]
    #then
    #    ./compile -j 1 em_real >> "${HPC_BUILD_LOG}" 2>&1
    #else 
    #    ./compile -j $(nproc) em_real >> "${HPC_BUILD_LOG}" 2>&1
    #fi
}

update_wrf_version()
{
    MODULE_VERSION=${WRF_VERSION}
}
