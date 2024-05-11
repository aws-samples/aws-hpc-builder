#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#WRFDA_VERSION=git
WRFDA_VERSION=${2:-4.5.2}
DISABLE_COMPILER_ENV=false

# 读取命令行新的版本信息后再计算WRF的主要版本等信息
WRFDA_MAJOR_VERSION=${WRFDA_VERSION%%.*}
#　与官方开始支持ARM　版本有关（4.2 以后版本加入了 ARM )
WRFDA_FORMATED_VERSION=$(echo ${WRFDA_VERSION} | awk -F'.' '{print $1$2}')

WRFDA_SRC="WRF-${WRFDA_VERSION}.tar.gz"

install_sys_dependency_for_wrfda()
{
    # packages for build wrf
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y update
	    sudo yum -y install time dmidecode tcsh libtirpc-devel
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
	    sudo dnf -y install time dmidecode tcsh libtirpc-devel
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
	    sudo apt-get -y install time dmidecode tcsh libtirpc-dev
	    ;;
	*)
	    exit 1
	    ;;
    esac
}

download_wrfda() {
    echo "zzz *** $(date) *** Downloading source code ${WRFDA_SRC}"
    if [ "${WRFDA_VERSION}" == "git" ]
    then
	git clone https://github.com/wrf-model/WRF.git
	return $?
    else
        if  [ -f ${WRFDA_SRC} ]
       	then
            return
	else
            if [ ${WRFDA_MAJOR_VERSION} -gt 3 ]
	    then
	        curl --retry 3 -JLOk "https://github.com/wrf-model/WRF/archive/refs/tags/v${WRFDA_VERSION}.tar.gz"
		return $?
	    else 
	        curl --retry 3 -JLOk "https://github.com/wrf-model/WRF/archive/refs/tags/V${WRFDA_VERSION}.tar.gz"
		return $?
	    fi
       	fi
    fi
}

check_wrfda_config()
{
    if [ "${SARCH}" == "aarch64" ]
    then
	export WRFDA_CONFIG=4
    elif [ "${HPC_COMPILER}" == "icc" ]
    then
    	export WRFDA_CONFIG=16
    else
	export WRFDA_CONFIG=35
    fi
}

set_wrfda_build_env()
{
    echo "zzz *** $(date) *** Setup build env"
    export NETCDF=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    export NETCDFF=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    export PNETCDF=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    export HDF5=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    export PHDF5=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    export JASPERLIB=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib
    export JASPERINC=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include/jasper
    export WRFIO_NCD_LARGE_FILE_SUPPORT=1
    export NETCDF_classic=1
    #export WRF_DM_CORE=1
    #export WRF_PLUS_CORE=1
    #export BUFR=1
    export CRTM=0
}

build_wrfda_dependency()
{
    echo "zzz *** $(date) *** Build WRF dependency"
    if [ "${BUILD_ALL}" == "all" ]
    then
	#sleep 1
	install_vendor_compiler
    fi
    echo "Setup WRF build env"
    set_wrfda_build_env
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

patch_wrfda()
{
    # 精度问题, patch GIT 版本(加上SARCH 只需给特定平台(如aarch64) 提供patch, clang 通过 ${HPC_COMPILER} 差异提供或不提供补丁
    if [ "$WRFDA_VERSION" == "git" ] 
    then
	if [ -f "../../patch/wrf/WRF-${WRFDA_VERSION}-$(arch)-${HPC_COMPILER}-${HPC_MPI}.patch" ]
	then
	    patch -Np1 < "../../patch/wrf/WRF-${WRFDA_VERSION}-$(arch)-${HPC_COMPILER}-${HPC_MPI}.patch"
	fi
	if [ -f "../../patch/wrf/WRF-4.z-double-precision-${SARCH}-${HPC_MPI}.patch" ]
	then
	    patch -Np1 < "../../patch/wrf/WRF-4.z-double-precision-${SARCH}-${HPC_MPI}.patch"
	fi
	return
    fi
    # 精度问题, patch 其他版本
    if [ -f "../../patch/wrf/WRF-${WRFDA_MAJOR_VERSION}.x-double-precision-${SARCH}-${HPC_MPI}.patch" ]
    then
	patch -Np1 < "../../patch/wrf/WRF-${WRFDA_MAJOR_VERSION}.x-double-precision-${SARCH}-${HPC_MPI}.patch"
    fi
    
    # 解决 4.4以前版本 WRF da_rag_diags out-of-order declarations 问题
    if [ ${WRFDA_FORMATED_VERSION} -lt 44 ]
    then
	patch -Np1 < "../../patch/wrf/WRF-da-rad-diags.patch"
    fi

    # Amazon Linux 2023/RHEL8/Centos8/Oracle Linux 8's tirpc issue
    if [ ${WRFDA_FORMATED_VERSION} -lt 42 ] && [ ${S_VERSION_ID} -eq 8 ]
    then
	patch -Np1 < "../../patch/wrf/WRF-tirpc.patch"
    fi

    # 编译器支持, aarch64
    if [ "${SARCH}" == "aarch64" ]
    then
	#PROCESSOR_TYPE=$(sudo dmidecode -t processor | grep -i Version | awk '{print $NF}')
	
	# support WRF 3.7.x on aarch64
	if [ ${WRFDA_FORMATED_VERSION} -lt 39 ]
	then
	    if [ -f "../../patch/wrf/WRF-3.w-${SARCH}-${HPC_COMPILER}-${HPC_MPI}.patch" ]
	    then
		patch -Np1 < "../../patch/wrf/WRF-3.w-${SARCH}-${HPC_COMPILER}-${HPC_MPI}.patch"
	    fi
        elif [ ${WRFDA_FORMATED_VERSION} -lt 40 ] 
        then
	    if [ -f "../../patch/wrf/WRF-3.x-${SARCH}-${HPC_COMPILER}-${HPC_MPI}.patch" ]
	    then
		patch -Np1 < "../../patch/wrf/WRF-3.x-${SARCH}-${HPC_COMPILER}-${HPC_MPI}.patch"
                #patch -Np1 < "../../patch/wrf/WRF-3.x-${SARCH}-${PROCESSOR_TYPE}.patch"
	    fi
        elif [ ${WRFDA_FORMATED_VERSION} -lt 42 ]
        then 
	    if [ -f "../../patch/wrf/WRF-4.x-${SARCH}-${HPC_COMPILER}-${HPC_MPI}.patch" ]
	    then 
		#patch -Np1 < "../../patch/wrf/WRF-4.x-${SARCH}-${PROCESSOR_TYPE}.patch"
		patch -Np1 < "../../patch/wrf/WRF-4.x-${SARCH}-${HPC_COMPILER}-${HPC_MPI}.patch"
	    fi
	elif [ ${WRFDA_FORMATED_VERSION} -ge 42 ]
	then
	    if [ -f "../../patch/wrf/WRF-4.z-${SARCH}-${HPC_COMPILER}-${HPC_MPI}.patch" ]
	    then
		patch -Np1 < "../../patch/wrf/WRF-4.z-${SARCH}-${HPC_COMPILER}-${HPC_MPI}.patch"
	    fi
	    # WRF 4.4+ for armclang need a new patch 
	    if [ ${WRFDA_FORMATED_VERSION} -ge 43 ] &&  [ "${HPC_COMPILER}" == "armclang" ]
            then
                patch -Np1 < "../../patch/wrf/WRF-4.z+-${SARCH}-${HPC_COMPILER}-${HPC_MPI}.patch"
            fi
        fi
    # 编译器支持, intel and amd
    # Intel 和 AMD, 如果使用clang 和 gcc 可以使用同样的 patch, 所以这里补丁变量使用 $(arch)
    elif [ "${SARCH}" == "x86_64" ] || [ "${SARCH}" == "amd64" ]
    then 
	# support building WRF 3.7.x with intel compiler and mpi
	if [ ${WRFDA_FORMATED_VERSION} -lt 39 ]
	then
	    if [ -f "../../patch/wrf/WRF-3.w-$(arch)-${HPC_COMPILER}-${HPC_MPI}.patch" ]
	    then
		patch -Np1 < "../../patch/wrf/WRF-3.w-$(arch)-${HPC_COMPILER}-${HPC_MPI}.patch"
	    fi
        elif [ ${WRFDA_FORMATED_VERSION} -lt 40 ] 
        then
	    if [ -f "../../patch/wrf/WRF-3.x-$(arch)-${HPC_COMPILER}-${HPC_MPI}.patch" ]
	    then
		patch -Np1 < "../../patch/wrf/WRF-3.x-$(arch)-${HPC_COMPILER}-${HPC_MPI}.patch"
	    fi
        elif [ ${WRFDA_FORMATED_VERSION} -lt 41 ]
        then
            # 对于icc, 事实上 4.0的最后一个版本 4.0.3 已经修正 "-openmpi" 成 "-gopenmpi", 所以只有4.1 之前非 4.0.3 版本需要此 icc 补丁
	    if [ "${HPC_COMPILER}" == "icc" ]
	    then
		if [ "${WRFDA_VERSION}" == "4.0.3" ]
		then
		    if [ -f "../../patch/wrf/WRF-4.z-${SARCH}-${HPC_COMPILER}-${HPC_MPI}.patch" ]
		    then
			patch -Np1 < "../../patch/wrf/WRF-4.z-${SARCH}-${HPC_COMPILER}-${HPC_MPI}.patch"
		    fi
		else
		    if [ -f "../../patch/wrf/WRF-4.x-${SARCH}-${HPC_COMPILER}-${HPC_MPI}.patch" ]
		    then
			patch -Np1 < "../../patch/wrf/WRF-4.x-${SARCH}-${HPC_COMPILER}-${HPC_MPI}.patch"
		    fi
		fi
	    else 
		# 对于gcc，或者clang 等编译器, 4.0.x 版本都使用相同的补丁
		if [ -f "../../patch/wrf/WRF-4.x-$(arch)-${HPC_COMPILER}-${HPC_MPI}.patch" ]
		then
		    patch -Np1 < "../../patch/wrf/WRF-4.x-$(arch)-${HPC_COMPILER}-${HPC_MPI}.patch"
		fi
	    fi
	else
	    # 使用开源编译器，可以使用相同的patch，所以这里用 $(arch)
	    if [ "${HPC_COMPILER}" == "icc" ]
	    then
		patch -Np1 < "../../patch/wrf/WRF-4.z-$(arch)-${HPC_COMPILER}-${HPC_MPI}.patch"
	    elif [ "${HPC_COMPILER}" == "amdclang" ] && [ ${WRFDA_FORMATED_VERSION} -gt 42 ]
	    then
		patch -Np1 < "../../patch/wrf/WRF-4.z-$(arch)-${HPC_COMPILER}-${HPC_MPI}.patch"
	    else
		patch -Np1 < "../../patch/wrf/WRF-4.x-$(arch)-${HPC_COMPILER}-${HPC_MPI}.patch"
	    fi
        fi
    fi
}

install_wrfda()
{
    build_wrfda_dependency  >> "${HPC_BUILD_LOG}" 2>&1

    echo "zzz *** $(date) *** Build WRF-${WRFDA_VERSION}"
    if [ "${WRFDA_VERSION}" == "git" ]
    then
       	sudo rm -rf "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/WRFDA-${WRFDA_VERSION}"
        cd WRF
    else
       	sudo rm -rf "${WRFDA_SRC%.tar.gz}" "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/WRFDA-${WRFDA_VERSION}"
        tar xf "${WRFDA_SRC}"
       	cd "${WRFDA_SRC%.tar.gz}"
	# since 4.4, the NoahMP code has been moved to an external repository
	# https://github.com/wrf-model/WRF/releases/tag/v4.4
	if [ ${WRFDA_FORMATED_VERSION} -ge 44 ]
	then
	    cd phys
	    NOAHMP_BRANCH=release-v$(echo ${WRFDA_VERSION} | awk -F. '{print $1"."$2}')-WRF
	    git clone --branch ${NOAHMP_BRANCH} https://github.com/NCAR/noahmp.git
	    cd ..
	fi
    fi

    patch_wrfda

    check_wrfda_config

    # disable MAKEFLAGS
    #unset MAKEFLAGS

    if [ "${WRFDA_CONFIG+set}" == "set" ]
    then
        echo -e "${WRFDA_CONFIG}\n1\n" | ./configure wrfda || exit 2
    else 
	echo "unsupported platform"
	exit 1
    fi

    # 默认是 -j 2, 如果有问题,尝试改成 -j 1
    ./compile all_wrfvar >> "${HPC_BUILD_LOG}" 2>&1 || exit 1
    cd ..

    if [ "${WRFDA_VERSION}" == "git" ]
    then
	sudo mv WRF "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/WRFDA-${WRFDA_VERSION}"
    else 
	sudo mv "${WRFDA_SRC%.tar.gz}" "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/WRFDA-${WRFDA_VERSION}"
    fi
    #if [ ${WRFDA_MAJOR_VERSION} -lt 4 ]
    #then
    #    ./compile -j 1 em_real >> "${HPC_BUILD_LOG}" 2>&1
    #else 
    #    ./compile -j $(nproc) em_real >> "${HPC_BUILD_LOG}" 2>&1
    #fi
}

update_wrfda_version()
{
    MODULE_VERSION=${WRFDA_VERSION}
}
