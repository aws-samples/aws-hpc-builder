#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

# **************************************
# 修改下面的版本号可以编译不同的版本组合
# **************************************
GCC_VERSION=${2:-12.2.0}
CMAKE_VERSION=3.25.1
CLANG_VERSION=${2:-15.0.2}
ARM_COMPILER_VERSION=${2:-22.1}
AMD_COMPILER_VERSION=${2:-4.0.0}
NVIDIA_COMPILER_VERSION=22.11
NVIDIA_COMPILER_MAJOR_VERSION=$(echo ${NVIDIA_COMPILER_VERSION} | cut -f1 -d'.')
NVIDIA_CUDA_VERSION=11.8
#AMD_COMPILER_VERSION=${2:-3.2.0}
#AMD_AOCL_VERSION=${AMD_COMPILER_VERSION}
AMD_AOCL_VERSION=4.0
BINUTILS_VERSION=2.39
ELFUTILS_VERSION=0.187

# to build the packages in the smame host, the first part of the TARGET much compatible(identical)
HPC_TARGET=$(arch)-bing-linux
#HPC_HOST=$(gcc -dumpmachine)
#HPC_BUILD=${HOST}
#HPC_TARGET=$(gcc -### 2>&1 | grep "^Target:" | awk '{print $2}')
# **************************************

# Intel OneAPI Base and HPC toolkits URLs
# https://www.intel.com/content/www/us/en/developer/tools/oneapi/toolkits.html
# https://www.intel.com/content/www/us/en/developer/tools/oneapi/base-toolkit-download.html
# https://www.intel.com/content/www/us/en/developer/tools/oneapi/hpc-toolkit-download.html

# Intel OneAPI 2021.3
#INTEL_COMPILER_VERSION=${2:-2021.3.0.3219}
#INTEL_HPC_COMPILER_VERSION=2021.3.0.3230
#INTEL_COMPILER_DL_ID=17977
#INTEL_HPC_COMPILER_DL_ID=17912
#https://registrationcenter-download.intel.com/akdlm/irc_nas/17977/l_BaseKit_p_2021.3.0.3219_offline.sh
#https://registrationcenter-download.intel.com/akdlm/irc_nas/17912/l_HPCKit_p_2021.3.0.3230_offline.sh

# Intel OneAPI 2021.4
#INTEL_COMPILER_VERSION=${2:-2021.4.0.3422}
#INTEL_HPC_COMPILER_VERSION=2021.4.0.3347
#INTEL_COMPILER_DL_ID=18236
#INTEL_HPC_COMPILER_DL_ID=18211
#https://registrationcenter-download.intel.com/akdlm/irc_nas/18236/l_BaseKit_p_2021.4.0.3422_offline.sh
#https://registrationcenter-download.intel.com/akdlm/irc_nas/18211/l_HPCKit_p_2021.4.0.3347_offline.sh

# Intel OneAPI 2022.1
#INTEL_COMPILER_VERSION=${2:-2022.1.2.146}
#INTEL_HPC_COMPILER_VERSION=2022.1.2.117
#INTEL_COMPILER_DL_ID=18487
#INTEL_HPC_COMPILER_DL_ID=18479
##https://registrationcenter-download.intel.com/akdlm/irc_nas/18487/l_BaseKit_p_2022.1.2.146_offline.sh
#https://registrationcenter-download.intel.com/akdlm/irc_nas/18479/l_HPCKit_p_2022.1.2.117_offline.sh
#https://registrationcenter-download.intel.com/akdlm/irc_nas/18438/l_HPCKit_p_2022.1.1.97_offline.sh

# Intel OneAPI 2022.2
INTEL_COMPILER_VERSION=${2:-2022.2.0.262}
INTEL_HPC_COMPILER_VERSION=2022.2.0.191
INTEL_COMPILER_DL_ID=18673
INTEL_HPC_COMPILER_DL_ID=18679
#https://registrationcenter-download.intel.com/akdlm/irc_nas/18673/l_BaseKit_p_2022.2.0.262_offline.sh
#https://registrationcenter-download.intel.com/akdlm/irc_nas/18679/l_BaseKit_p_2022.2.0.191_offline.sh

# Intel OneAPI 2022.3
#INTEL_COMPILER_VERSION=${2:-2022.3.1.17310}
#INTEL_HPC_COMPILER_VERSION=2022.3.1.16997
#INTEL_COMPILER_DL_ID=18970
#INTEL_HPC_COMPILER_DL_ID=18975
#https://registrationcenter-download.intel.com/akdlm/irc_nas/18970/l_BaseKit_p_2022.3.1.17310_offline.sh
#https://registrationcenter-download.intel.com/akdlm/irc_nas/18975/l_HPCKit_p_2022.3.1.16997_offline.sh
#https://registrationcenter-download.intel.com/akdlm/irc_nas/18852/l_BaseKit_p_2022.3.0.8767_offline.sh
#https://registrationcenter-download.intel.com/akdlm/irc_nas/18679/l_HPCKit_p_2022.3.0.8751_offline.sh


# Intel OneAPI 2023.1
#INTEL_COMPILER_VERSION=${2:-2023.3.1.0.46401}
#INTEL_HPC_COMPILER_VERSION=2023.1.0.46346
#INTEL_COMPILER_DL_ID=7deeaac4-f605-4bcf-a81b-ea7531577c61
#INTEL_HPC_COMPILER_DL_ID=1ff1b38a-8218-4c53-9956-f0b264de35a
#https://registrationcenter-download.intel.com/akdlm/IRC_NAS/7deeaac4-f605-4bcf-a81b-ea7531577c61/l_BaseKit_p_2023.1.0.46401_offline.sh
#https://registrationcenter-download.intel.com/akdlm/IRC_NAS/1ff1b38a-8218-4c53-9956-f0b264de35a4/l_HPCKit_p_2023.1.0.46346_offline.sh

# ArmPL 22.02
#https://armkeil.blob.core.windows.net/developer/Files/downloads/hpc/arm-allinea-studio/$(echo ${ARM_COMPILER_VERSION} | tr '.' '-')/arm-compiler-for-linux_${ARM_COMPILER_VERSION}_RHEL-${S_VERSION_ID}_${SARCH}.tar"
# ArmPL 22.1
#https://developer.arm.com/-/media/Files/downloads/hpc/arm-compiler-for-linux/22-1/arm-compiler-for-linux_22.1_RHEL-7_aarch64.tar
#https://developer.arm.com/-/media/Files/downloads/hpc/arm-compiler-for-linux/22-1/arm-compiler-for-linux_22.1_RHEL-8_aarch64.tar
#https://developer.arm.com/-/media/Files/downloads/hpc/arm-compiler-for-linux/22-1/arm-compiler-for-linux_22.1_Ubuntu-18.04_aarch64.tar
#https://developer.arm.com/-/media/Files/downloads/hpc/arm-compiler-for-linux/22-1/arm-compiler-for-linux_22.1_Ubuntu-20.04_aarch64.tar

# aocc/aocl url
# https://www.amd.com/en/developer/aocc.html
# https://www.amd.com/en/developer/aocl.html
# https://developer.amd.com/amd-aocc/#downloads
# https://developer.amd.com/amd-aocl/#downloads
# 4.0.0/4.0
# https://download.amd.com/developer/eula/aocc-compiler/aocc-compiler-4.0.0.tar
# https://download.amd.com/developer/eula/aocl/aocl-4-0/aocl-linux-aocc-4.0.tar.gz
# 3.2.0/3.2
# https://download.amd.com/developer/eula/aocc-compiler/aocc-compiler-3.2.0.tar
# https://download.amd.com/developer/eula/aocl/aocl-3-2/aocl-linux-aocc-3.2.0.tar.gz

# NVIDIA HPC SDK
# 23.3
# https://developer.download.nvidia.com/hpc-sdk/23.3/nvhpc_2023_233_Linux_aarch64_cuda_12.0.tar.gz
#
# 22.11
# https://developer.download.nvidia.com/hpc-sdk/22.11/nvhpc_2022_2211_Linux_aarch64_cuda_11.8.tar.gz

if [ "${HPC_PACKAGE_TYPE}" == "rpm" ]
then
    ARM_COMPILER_SRC=arm-compiler-for-linux_${ARM_COMPILER_VERSION}_RHEL-${S_VERSION_ID}_${SARCH}.tar
elif [ "${HPC_PACKAGE_TYPE}" == "deb" ]
then
    ARM_COMPILER_SRC=arm-compiler-for-linux_${ARM_COMPILER_VERSION}_Ubuntu-${S_VERSION_ID}.04_${SARCH}.tar
fi

NVIDIA_COMPILER_SRC=nvhpc_20${NVIDIA_COMPILER_MAJOR_VERSION}_$(echo ${NVIDIA_COMPILER_VERSION} | sed 's/\.//g')_Linux_$(arch)_cuda_${NVIDIA_CUDA_VERSION}.tar.gz

INTEL_COMPILER_SRC="l_BaseKit_p_${INTEL_COMPILER_VERSION}_offline.sh"
INTEL_HPC_COMPILER_SRC="l_HPCKit_p_${INTEL_HPC_COMPILER_VERSION}_offline.sh"
AMD_COMPILER_SRC=aocc-compiler-${AMD_COMPILER_VERSION}.tar
AMD_AOCL_SRC=aocl-linux-aocc-${AMD_AOCL_VERSION}.tar.gz
GCC_SRC="gcc-${GCC_VERSION}.tar.gz"
CMAKE_SRC=cmake-${CMAKE_VERSION}.tar.gz
CLANG_SRC="llvmorg-${CLANG_VERSION}.tar.gz"
BINUTILS_SRC="binutils-${BINUTILS_VERSION}.tar.gz"
ELFUTILS_SRC="elfutils-${ELFUTILS_VERSION}.tar.bz2"

install_sys_dependency_for_compiler()
{
    # packages for build gcc/binutils ref: https://wiki.osdev.org/Building_GCC
    # packages for build llvm/clang/cmake(openssl)
    # packages for build elfutils ref: https://github.com/iovisor/bcc/issues/3601  sqlite-devel, libcurl-devel libmicrohttpd-devel and libarchive-devel
    # packages for build wrf
    # packages for build wps
    # packages for install Intel OneAPI compiler and toolchains
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y update
	    #sudo yum -y install hdf5-devel zlib-devel libcurl-devel cmake3 m4 openmpi-devel libxml2-devel libtirpc-devel bzip2-devel jasper-devel libpng-devel zlib-devel libjpeg-turbo-devel tmux patch git
	    sudo yum -y install \
		gcc gcc-c++ gcc-gfortran make bison flex gmp-devel libmpc-devel mpfr-devel texinfo \
		openssl-devel ninja-build \
		sqlite-devel libarchive-devel libmicrohttpd-devel libcurl-devel \
		bzip2 wget time dmidecode tcsh libtirpc-devel \
	       	mesa-libgbm at-spi gtk3 xdg-utils libnotify libxcb tcl environment-modules \
		libXrender-devel expat-devel libX11-devel freetype-devel fontconfig-devel libXext-devel pixman-devel cairo-devel \
	       	zlib-devel libcurl-devel cmake3 m4 libxml2-devel bzip2-devel jasper-devel libpng-devel libjpeg-turbo-devel tmux patch git   

	    case  "${S_NAME}" in
		"Alibaba Cloud Linux (Aliyun Linux)"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		    return
		    ;;
		"Amazon Linux")
		    # packages for armclang(libtinfo.so.5) | gcc
		    sudo yum -y install ncurses-compat-libs isl-devel
		    ;;
	    esac
	    ;;
	8)
	    # packages for build gcc/binutils ref: https://wiki.osdev.org/Building_GCC
	    # packages for build llvm/clang
	    # packages for armclang(libtinfo.so.5)
	    # packages for build elfutils ref: https://github.com/iovisor/bcc/issues/3601  sqlite-devel, libcurl-devel libmicrohttpd-devel and libarchive-devel
	    # packages for build wrf
	    # packages for build wps
	    # packages for install Intel OneAPI compiler and toolchains
	    sudo $(dnf check-release-update 2>&1 | grep "dnf update --releasever" | tail -n1) -y 2> /dev/null
	    sudo dnf -y update
	    sudo dnf -y install \
		gcc gcc-c++ gcc-gfortran make bison flex gmp-devel libmpc-devel mpfr-devel texinfo isl-devel \
		ninja-build \
		ncurses-compat-libs \
		sqlite-devel libarchive-devel libmicrohttpd-devel libcurl-devel \
	       	bzip2 wget time dmidecode tcsh libtirpc-devel \
		mesa-libgbm gtk3 xdg-utils libnotify libxcb tcl environment-modules \
		libXrender-devel expat-devel libX11-devel freetype-devel fontconfig-devel libXext-devel pixman-devel cairo-devel \
		zlib-devel cmake m4 libxml2-devel bzip2-devel jasper-devel libpng-devel libjpeg-turbo-devel tmux patch git

	    case  "${S_NAME}" in
		"Alibaba Cloud Linux")
		    return
		    ;;
		"Amazon Linux"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		    sudo dnf -y install libxcrypt-compat
		    ;;
	    esac
	    ;;
	18|20)
	    sudo apt-get -y update
	    sudo apt-get -y install gcc g++ gfortran make bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo \
		libssl-dev libncurses5 ninja-build \
		libsqlite3-dev libarchive-dev libmicrohttpd-dev libcurl4-nss-dev \
	       	bzip2 wget time dmidecode tcsh libtirpc-dev \
		libgbm1 libgtk-3-0 xdg-utils libnotify4 libxcb1 tcl environment-modules \
		libxrender-dev libexpat1-dev libx11-dev libfreetype6-dev libfontconfig1-dev libxext-dev libpixman-1-dev libcairo2-dev \
		zlib1g-dev cmake m4 libxml2-dev libbz2-dev libpng-dev libturbojpeg0-dev tmux patch git

	    ;;
	*)
	    exit 1
	    ;;
    esac
}

download_compiler() {
    if [ ! -f ${CMAKE_SRC} ] && ([ ${S_VERSION_ID} -eq 7 ] || [ ${S_VERSION_ID} -eq 18 ])
    then
	wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/${CMAKE_SRC}
	result=$?
	if [ ${result} -ne 0 ]
	then
	    return ${result}
	fi
    fi

    case "${HPC_COMPILER}" in
	"armgcc" | "armclang")
	    if [ -f ${ARM_COMPILER_SRC} ]
	    then
		return
	    else
		wget "https://developer.arm.com/-/media/Files/downloads/hpc/arm-compiler-for-linux/$(echo ${ARM_COMPILER_VERSION} | tr '.' '-')/${ARM_COMPILER_SRC}"
		return $?
	    fi
	    ;;
	"icc" | "icx")
	    INTEL_COMPILER_VERSION_YEAR=$(echo ${INTEL_COMPILER_VERSION} | cut -f1 -d.)
	    if [ ${INTEL_COMPILER_VERSION_YEAR} -lt 2023 ]
	    then
		INTEL_DOWNLOAD_BASE_URL="https://registrationcenter-download.intel.com/akdlm/irc_nas"
	    else
		INTEL_DOWNLOAD_BASE_URL="https://registrationcenter-download.intel.com/akdlm/IRC_NAS"
	    fi

	    if [ ! -f ${INTEL_COMPILER_SRC} ]
            then
		wget "${INTEL_DOWNLOAD_BASE_URL}/${INTEL_COMPILER_DL_ID}/${INTEL_COMPILER_SRC}"
		result=$?
		if [ ${result} -ne 0 ]
		then
		    return ${result}
		fi
	    fi
	    if [ -f ${INTEL_HPC_COMPILER_SRC} ]
	    then
		return
	    else
		wget "${INTEL_DOWNLOAD_BASE_URL}/${INTEL_HPC_COMPILER_DL_ID}/${INTEL_HPC_COMPILER_SRC}"
		return $?
	    fi
	    ;;
	"amdclang")
	    # aocc/aocl url
	    # https://www.amd.com/en/developer/aocc.html
	    # https://www.amd.com/en/developer/aocl.html
	    # https://developer.amd.com/amd-aocc/#downloads
	    # https://developer.amd.com/amd-aocl/#downloads
	    # https://download.amd.com/developer/eula/aocc-compiler/aocc-compiler-4.0.0.tar
	    # https://download.amd.com/developer/eula/aocl/aocl-4-0/aocl-linux-aocc-4.0.tar.gz
	    if [ ! -f ${AMD_COMPILER_SRC} ]
	    then
		wget https://download.amd.com/developer/eula/aocc-compiler/${AMD_COMPILER_SRC}
		result=$?
		if [ ${result} -ne 0 ]
		then
		    return ${result}
		fi
	    fi
	    if [ -f ${AMD_AOCL_SRC} ]
	    then
		return
	    else
		wget https://download.amd.com/developer/eula/aocl/aocl-$(echo ${AMD_AOCL_VERSION} | awk -F'.' '{print $1"-"$2}')/${AMD_AOCL_SRC}
		return $?
	    fi
	    ;;
	"gcc")
	    if [ ! -f ${BINUTILS_SRC} ]
	    then
		wget "https://ftp.gnu.org/gnu/binutils/${BINUTILS_SRC}"
		result=$?
		if [ ${result} -ne 0 ]
		then
		    return ${result}
		fi
	    fi
	    if [ ! -f ${ELFUTILS_SRC} ]
	    then
		wget "https://sourceware.org/elfutils/ftp/${ELFUTILS_VERSION}/${ELFUTILS_SRC}"
		result=$?
		if [ ${result} -ne 0 ]
		then
		    return ${result}
		fi
	    fi
	    if [ -f ${GCC_SRC} ]
	    then
		return
	    else
		wget "https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/${GCC_SRC}"
		return $?
	    fi
	    ;;
	"clang")
	    if [ -f ${CLANG_SRC} ]
	    then
		return
	    else
		wget "https://github.com/llvm/llvm-project/archive/refs/tags/${CLANG_SRC}"
		return $?
	    fi
	    ;;
	"nvc")
	    if [ -f ${NVIDIA_COMPILER_SRC} ]
	    then
		return
	    else
		wget https://developer.download.nvidia.com/hpc-sdk/${NVIDIA_COMPILER_VERSION}/${NVIDIA_COMPILER_SRC}
		return $?
	    fi
	    ;;
    esac
}


install_arm_compiler()
{
    sudo rm -rf "${ARM_COMPILER_SRC%_aarch64.tar}"
    tar xf "${ARM_COMPILER_SRC}"
    cd "${ARM_COMPILER_SRC%_aarch64.tar}"
    sudo bash "${ARM_COMPILER_SRC%_aarch64.tar}.sh" -a -i ${HPC_PREFIX}/opt -f
    cd ..
}

install_intel_compiler()
{
    
    for product in $(sudo bash ${INTEL_HPC_COMPILER_SRC} -a -c --list-products | grep true | awk '{print $1":"$2}')
    do
	product_id=$(echo ${product} | cut -d: -f1)
	product_ver=$(echo ${product} | cut -d: -f2)
        sudo bash ${INTEL_HPC_COMPILER_SRC} -a -c -s --action remove --product-id ${product_id} --product-ver ${product_ver}
    done
    for product in $(sudo bash ${INTEL_COMPILER_SRC} -a -c --list-products | grep true | awk '{print $1":"$2}')
    do
	product_id=$(echo ${product} | cut -d: -f1)
	product_ver=$(echo ${product} | cut -d: -f2)
        sudo bash ${INTEL_COMPILER_SRC} -a -c -s --action remove --product-id ${product_id} --product-ver ${product_ver}
    done
    sudo bash ${INTEL_COMPILER_SRC} -a -s --eula accept --install-dir=${HPC_PREFIX}/opt/intel/oneapi
    sudo bash ${INTEL_HPC_COMPILER_SRC} -a -s --eula accept --install-dir=${HPC_PREFIX}/opt/intel/oneapi
}

install_amd_compiler()
{   
    sudo mkdir -p ${HPC_PREFIX}/opt
    sudo tar xf ${AMD_COMPILER_SRC} -C ${HPC_PREFIX}/opt
    pushd ${HPC_PREFIX}/opt/${AMD_COMPILER_SRC%.tar}
    sudo bash install.sh
    popd
    tar xf ${AMD_AOCL_SRC}
    cd ${AMD_AOCL_SRC%.tar.gz}
    sudo bash ./install.sh -t ${HPC_PREFIX}/opt -i lp64
    cd ..
}


install_nvidia_compiler()
{
    rm -rf ${NVIDIA_COMPILER_SRC%.tar.gz}
    tar xf ${NVIDIA_COMPILER_SRC}
    export NVHPC_SILENT=true
    export NVHPC_INSTALL_DIR=${HPC_PREFIX}/opt/nvidia
    export NVHPC_INSTALL_TYPE=single
    sudo --preserve-env=NVHPC_SILENT,NVHPC_INSTALL_DIR,NVHPC_INSTALL_TYPE env ${NVIDIA_COMPILER_SRC%.tar.gz}/install
}

install_gcc_compiler()
{   
    if [ ${S_VERSION_ID} -eq 7 ]
    then
	build_elfutils_stage_one
    fi
    # after build binutils, use it for gcc build
    export OPATH=${PATH}
    export PATH=${HPC_PREFIX}/tmp/${HPC_COMPILER}/${HPC_TARGET}/bin:${HPC_PREFIX}/tmp/${HPC_COMPILER}/bin:${PATH}
    export OLD_LIBRARY_PATH=${LD_LIBRARY_PATH}
    export LD_LIBRARY_PATH=${HPC_PREFIX}/tmp/${HPC_COMPILER}/lib64:${HPC_PREFIX}/${HPC_COMPILER}/tmp/lib:${LD_LIBRARY_PATH}
    build_binutils_stage_one
    build_gcc_stage_one
    if [ ${S_VERSION_ID} -eq 7 ]
    then
	build_elfutils
    fi
    export PATH=${HPC_PREFIX}/opt/gnu/${HPC_TARGET}/bin:${HPC_PREFIX}/opt/gnu/bin:${HPC_PREFIX}/tmp/${HPC_COMPILER}/${HPC_TARGET}/bin:${HPC_PREFIX}/tmp/${HPC_COMPILER}/bin:${PATH}
    export LD_LIBRARY_PATH=${HPC_PREFIX}/opt/gnu/lib64:${HPC_PREFIX}/opt/gnu/lib:${LD_LIBRARY_PATH}
    export PKG_CONFIG_PATH=${HPC_PREFIX}/opt/gnu/lib64/pkgconfig:${HPC_PREFIX}/opt/gnu/lib/pkgconfig:${PKG_CONFIG_PATH}
    build_binutils
    # after build binutils, use the official version to rebuild gcc
    build_gcc

    # restore enviroment
    export PATH=${OPATH}
    export LD_LIBRARY_PATH=${OLD_LIBRARY_PATH}
    unset OPATH
    unset OLD_LIBRARY_PATH
}

build_cmake()
{
    if [ ${S_VERSION_ID} -eq 7 ] || [ ${S_VERSION_ID} -eq 18 ]
    then
	echo "zzz *** $(date) *** Build ${CMAKE_SRC%.tar.gz}"
	sudo rm -rf "${CMAKE_SRC%.tar.gz}"
	tar xf "${CMAKE_SRC}"
	cd "${CMAKE_SRC%.tar.gz}"
	./bootstrap --prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} --parallel=$(($(nproc) / 2)) -- -DCMAKE_BUILD_TYPE:STRING=Release
	make && sudo --preserve-env=PATH,LD_LIBRARY_PATH,PKG_CONFIG_PATH env make install && cd ..
    fi
}

build_clang()
{
    build_cmake

    if [ ${S_VERSION_ID} -eq 7 ]
    then
	sudo ln -s /usr/bin/ninja-build /usr/local/bin/ninja
    fi

    echo "zzz *** $(date) *** Build ${CLANG_SRC%.tar.gz}"
    sudo rm -rf "${CLANG_SRC%.tar.gz}"
    tar xf "${CLANG_SRC}"
    BUILDDIR=llvm/build
    mkdir -p ${BUILDDIR}
    cmake -DLLVM_DEFAULT_TARGET_TRIPLE=${HPC_HOST_TARGET} \
	-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD="" \
        -DLLVM_PARALLEL_COMPILE_JOBS=$(($(nproc) / 2)) \
        -G Ninja -S llvm-project-llvmorg-${CLANG_VERSION}/llvm -B ${BUILDDIR} \
	-DLLVM_INSTALL_UTILS=ON \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_INSTALL_PREFIX=${HPC_PREFIX}/opt/gnu \
	-DLLVM_ENABLE_PROJECTS='clang;clang-tools-extra;flang;lldb'

    sudo --preserve-env=PATH,LD_LIBRARY_PATH,PKG_CONFIG_PATH env \
	ninja -C ${BUILDDIR} install
    sudo --preserve-env=PATH,LD_LIBRARY_PATH,PKG_CONFIG_PATH env \
	cmake -G Ninja -S llvm-project-llvmorg-${CLANG_VERSION}/llvm  -B ${BUILDDIR} \
	-DLLVM_EXTERNAL_LIT=./llvm-project-llvmorg-${CLANG_VERSION}/llvm/utils/lit/lit.py \
	-DLLVM_ROOT=${HPC_PREFIX}/opt/gnu

}

install_clang_compiler()
{
    export PATH=${HPC_PREFIX}/opt/gnu/bin:${PATH}
    export LD_LIBRARY_PATH=${HPC_PREFIX}/opt/gnu/lib:${LD_LIBRARY_PATH}
    export PKG_CONFIG_PATH=${HPC_PREFIX}/opt/gnu/lib/pkgconfig:${PKG_CONFIG_PATH}
    build_clang
    sudo ln -sf ${HPC_PREFIX}/opt/gnu/bin/{flang-new,flang}
}

install_compiler()
{
    case ${HPC_COMPILER} in
    "gcc")
	install_gcc_compiler
	return $?
	;;
    "clang")
	install_clang_compiler
	return $?
	;;
    "armgcc" | "armclang")
        install_arm_compiler
	return $?
	;;
    "icc" | "icx")
	install_intel_compiler
	return $?
	;;
    "amdclang")
	install_amd_compiler
	return $?
	;;
    "nvc")
	install_nvidia_compiler
	return $?
	;;
esac

}

	    #--enable-interwork --disable-multilib \
	    #--enable-gprofng=no \
# https://www.linuxfromscratch.org/lfs/view/development/chapter05/binutils-pass1.html 
# stage1 use host build
# with-sysroot allow this LD search library from the host system
build_binutils_stage_one()
{
    echo "zzz *** $(date) *** Build ${BINUTILS_SRC%.tar.gz} stage one"
    sudo rm -rf "${BINUTILS_SRC%.tar.gz}"
    tar xf "${BINUTILS_SRC}"
    cd "${BINUTILS_SRC%.tar.gz}"
    mkdir -p build
    cd build
    # the binutils on RHEL/Centos/AL doesn't enable TARGET, if set build and host, fix error: "x86_64-redhat-linux-ar: Command not found"
	    #--build=$(../config.guess)\
	    #--host=${HOST} \
	    #--target=${HPC_TARGET} \
    ../configure --prefix=${HPC_PREFIX}/tmp/${HPC_COMPILER}  \
	    --build=$(../config.guess) \
	    --host=$(../config.guess) \
	    --target=${HPC_TARGET} \
	    --with-sysroot=/ \
	    --enable-shared \
	    --enable-gprofng=no \
	    --disable-nls --disable-werror
    make
    sudo --preserve-env=PATH,LD_LIBRARY_PATH env make install
    cd ../..
}

# stage2 use target build
# with-sysroot allow this LD search library from the host system
# 
# issue: /bin/sh: line 5: x86_64-bing-linux-ranlib: command not found
# solution:
# https://stackoverflow.com/questions/23078282/ranlib-not-found
# https://unix.stackexchange.com/questions/83191/how-to-make-sudo-preserve-path
build_binutils()
{
    echo "zzz *** $(date) *** Build ${BINUTILS_SRC%.tar.gz}"
    sudo rm -rf "${BINUTILS_SRC%.tar.gz}"
    tar xf "${BINUTILS_SRC}"
    cd "${BINUTILS_SRC%.tar.gz}"
    mkdir -p build
    cd build
	    #--host=${HPC_HOST} \
	    #--target=${HPC_TARGET} \
	    #--with-sysroot=/ \
#    LD=$(which ld) \
    ../configure --prefix=${HPC_PREFIX}/opt/gnu \
	    --build=${HPC_TARGET} \
	    --host=${HPC_TARGET} \
	    --target=${HPC_TARGET} \
	    --with-sysroot=/ \
	    --enable-gold --enable-ld=default \
	    --enable-plugins --enable-shared \
	    --enable-64-bit-bfd --with-system-zlib \
	    --enable-gprofng=no \
	    --disable-multilib \
	    --disable-werror
    make
    sudo --preserve-env=PATH,LD_LIBRARY_PATH env make install
    cd ../..
}

# https://forums.gentoo.org/viewtopic-t-1089690-start-0.html
#  
# stage1 use host build
build_elfutils_stage_one()
{
    echo "zzz *** $(date) *** Build ${ELFUTILS_SRC%.tar.bz2} stage one"
    sudo rm -rf "${ELFUTILS_SRC%.tar.bz2}"
    tar xf "${ELFUTILS_SRC}"
    cd "${ELFUTILS_SRC%.tar.bz2}"
    mkdir -p build
    cd build
    ../configure --prefix=${HPC_PREFIX}/tmp/${HPC_COMPILER}
    make CFLAGS="-Wno-error=deprecated-declarations"
    sudo --preserve-env=PATH,LD_LIBRARY_PATH env make CFLAGS="-Wno-error=deprecated-declarations" install
    cd ../..
}

# stage2 use target build
build_elfutils()
{
    echo "zzz *** $(date) *** Build ${ELFUTILS_SRC%.tar.bz2}"
    sudo rm -rf "${ELFUTILS_SRC%.tar.bz2}"
    tar xf "${ELFUTILS_SRC}"
    cd "${ELFUTILS_SRC%.tar.bz2}"
    mkdir -p build
    cd build
    ../configure --prefix=${HPC_PREFIX}/opt/gnu
    make CFLAGS="-Wno-error=deprecated-declarations"
    sudo --preserve-env=PATH,LD_LIBRARY_PATH env make CFLAGS="-Wno-error=deprecated-declarations" install
    cd ../..
}

# https://www.linuxfromscratch.org/lfs/view/development/chapter05/gcc-libstdc++.html
build_libstdcxx()
{
    sudo rm -rf "${GCC_SRC%.tar.gz}"
    tar xf "${GCC_SRC}"
    cd "${GCC_SRC%.tar.gz}"
    mkdir -p build
    cd build
    ../libstdc++-v3/configure --prefix=${HPC_PREFIX}/tmp/${HPC_COMPILER} \
	    --enable-multilib \
	    --disable-nls \
	    --disable-libstdcxx-pch \
	    --with-gxx-include-dir=${HPC_PREFIX}/tmp/${HPC_COMPILER}/include/c++/${GCC_VERSION}
    make
    sudo --preserve-env=PATH,LD_LIBRARY_PATH env make install
    cd ../..

}

# https://www.linuxfromscratch.org/lfs/view/development/chapter05/gcc-pass1.html
# stage1 use host build
build_gcc_stage_one()
{
    echo "zzz *** $(date) *** Build ${GCC_SRC%.tar.gz} stage one"
    sudo rm -rf "${GCC_SRC%.tar.gz}"
    tar xf "${GCC_SRC}"
    cd "${GCC_SRC%.tar.gz}"
    mkdir -p build
    cd build
    # the binutils on RHEL/Centos/AL doesn't enable TARGET, if set build and host, fix error: "x86_64-redhat-linux-ar: Command not found"
	    #--target=${HPC_TARGET} --disable-lto \
	    #--build=$(../config.guess) \
	    #--host=${HOST} \
	    #--target=${HPC_TARGET} \
    ../configure --prefix=${HPC_PREFIX}/tmp/${HPC_COMPILER} \
	    --build=$(../config.guess) \
	    --host=$(../config.guess) \
	    --target=${HPC_TARGET} \
	    --with-sysroot=/ \
	    --enable-bootstrap \
	    --disable-nls \
	    --disable-threads \
	    --enable-shared \
	    --disable-multilib \
	    --enable-languages=c,c++,fortran
    make
    sudo --preserve-env=PATH,LD_LIBRARY_PATH env make install
    cd ../..

    #echo "xxxx ******* build libstdcxx"
    #build_libstdcxx
}

# stage2 use target build
build_gcc()
{
    echo "zzz *** $(date) *** Build ${GCC_SRC%.tar.gz}"
    sudo rm -rf "${GCC_SRC%.tar.gz}"
    tar xf "${GCC_SRC}"
    cd "${GCC_SRC%.tar.gz}"
    mkdir -p build
    cd build
	    #--build=${HPC_TARGET} \
	    #--host=${HPC_TARGET} \
	    #--target=${HPC_TARGET} \
    ../configure --prefix=${HPC_PREFIX}/opt/gnu \
	    --build=${HPC_TARGET} \
	    --host=${HPC_TARGET} \
	    --target=${HPC_TARGET} \
	    --with-sysroot=/ \
	    --enable-bootstrap \
	    --enable-shared \
	    --disable-multilib \
	    --enable-languages=c,c++,fortran,lto \
	    --enable-threads=posix \
	    --enable-checking=release \
	    --with-system-zlib \
	    --enable-__cxa_atexit \
	    --disable-libunwind-exceptions \
	    --enable-gnu-unique-object \
	    --enable-linker-build-id \
	    --with-gcc-major-version-only \
	    --with-linker-hash-style=gnu \
	    --enable-plugin \
	    --enable-initfini-array \
	    --enable-gnu-indirect-function
	    #--with-tune=neoverse-n1 --with-arch=armv8.2-a+crypto --build=aarch64-redhat-linux
    make
    sudo --preserve-env=PATH,LD_LIBRARY_PATH env make install
    cd ../..
}

update_compiler_version()
{
    case ${HPC_COMPILER} in
    "gcc")
	MODULE_VERSION=${GCC_VERSION}
	;;
    "clang")
	MODULE_VERSION=${CLANG_VERSION}
	;;
    "armgcc"|"armclang")
	MODULE_VERSION=${ARM_COMPILER_VERSION}
	;;
    "icc"|"icx")
	MODULE_VERSION=${INTEL_COMPILER_VERSION}
	;;
    "amdclang")
	MODULE_VERSION=${AMD_COMPILER_VERSION}
	;;
    "nvc")
	MODULE_VERSION=${NVIDIA_COMPILER_VERSION}
	;;
esac
}
