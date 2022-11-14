#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

# **************************************
# 修改下面的版本号可以编译不同的版本组合
# **************************************
GCC_VERSION=${2:-12.2.0}
ARM_COMPILER_VERSION=${2:-22.1}
AMD_COMPILER_VERSION=${2:-4.0.0}
#AMD_COMPILER_VERSION=${2:-3.2.0}
#AMD_AOCL_VERSION=${AMD_COMPILER_VERSION}
AMD_AOCL_VERSION=4.0
BINUTILS_VERSION=2.39
ELFUTILS_VERSION=0.187

# to build the packages in the smame host, the first part of the TARGET much compatible(identical)
TARGET=$(uname -m)-bing-linux
#HOST=$(gcc -dumpmachine)
#BUILD=${HOST}
#TARGET=$(gcc -### 2>&1 | grep "^Target:" | awk '{print $2}')
# **************************************

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
#INTEL_COMPILER_VERSION=${2:-2022.2.0.262}
#INTEL_HPC_COMPILER_VERSION=2022.2.0.191
#INTEL_COMPILER_DL_ID=18673
#INTEL_HPC_COMPILER_DL_ID=18679
#https://registrationcenter-download.intel.com/akdlm/irc_nas/18673/l_BaseKit_p_2022.2.0.262_offline.sh
#https://registrationcenter-download.intel.com/akdlm/irc_nas/18679/l_BaseKit_p_2022.2.0.191_offline.sh

# Intel OneAPI 2022.3
INTEL_COMPILER_VERSION=${2:-2022.3.0.8767}
INTEL_HPC_COMPILER_VERSION=2022.3.0.8751
INTEL_COMPILER_DL_ID=18852
INTEL_HPC_COMPILER_DL_ID=18679
#https://registrationcenter-download.intel.com/akdlm/irc_nas/18852/l_BaseKit_p_2022.3.0.8767_offline.sh
#https://registrationcenter-download.intel.com/akdlm/irc_nas/18679/l_HPCKit_p_2022.3.0.8751_offline.sh


INTEL_COMPILER_SRC="l_BaseKit_p_${INTEL_COMPILER_VERSION}_offline.sh"
INTEL_HPC_COMPILER_SRC="l_HPCKit_p_${INTEL_HPC_COMPILER_VERSION}_offline.sh"
AMD_COMPILER_SRC=aocc-compiler-${AMD_COMPILER_VERSION}.tar
AMD_AOCL_SRC=aocl-linux-aocc-${AMD_AOCL_VERSION}.tar.gz
GCC_SRC="gcc-${GCC_VERSION}.tar.gz"
BINUTILS_SRC="binutils-${BINUTILS_VERSION}.tar.gz"
ELFUTILS_SRC="elfutils-${ELFUTILS_VERSION}.tar.bz2"

install_sys_dependency_for_compiler()
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
		gcc gcc-c++ gcc-gfortran make bison flex gmp-devel libmpc-devel mpfr-devel texinfo isl-devel \
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
		gcc gcc-c++ gcc-gfortran make bison flex gmp-devel libmpc-devel mpfr-devel texinfo isl-devel \
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

download_compiler() {
    if [ "${SARCH}" == "aarch64" ]
    then
	if [ -f arm-compiler-for-linux_${ARM_COMPILER_VERSION}_RHEL-${S_VERSION_ID}_${SARCH}.tar ]
	then
            return
        else
	    # 22.02
            #wget "https://armkeil.blob.core.windows.net/developer/Files/downloads/hpc/arm-allinea-studio/$(echo ${ARM_COMPILER_VERSION} | tr '.' '-')/arm-compiler-for-linux_${ARM_COMPILER_VERSION}_RHEL-${S_VERSION_ID}_${SARCH}.tar"
            # 22.1
            #wget https://developer.arm.com/-/media/Files/downloads/hpc/arm-compiler-for-linux/22-1/arm-compiler-for-linux_22.1_RHEL-7_aarch64.tar
            wget "https://developer.arm.com/-/media/Files/downloads/hpc/arm-compiler-for-linux/$(echo ${ARM_COMPILER_VERSION} | tr '.' '-')/arm-compiler-for-linux_${ARM_COMPILER_VERSION}_RHEL-${S_VERSION_ID}_${SARCH}.tar"
	    return $?
	fi
    elif [ "${SARCH}" == "x86_64" ]
    then
	if [ -f ${INTEL_COMPILER_SRC} ]
	then
	    return
        else
	    wget "https://registrationcenter-download.intel.com/akdlm/irc_nas/${INTEL_COMPILER_DL_ID}/${INTEL_COMPILER_SRC}"
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
            wget "https://registrationcenter-download.intel.com/akdlm/irc_nas/${INTEL_HPC_COMPILER_DL_ID}/${INTEL_HPC_COMPILER_SRC}"
	    return $?
	fi
    elif [ "${SARCH}" == "amd64" ]
    then
	if [ ${USE_INTEL_ICC} -eq 1 ]
	then
            if [ -f ${INTEL_COMPILER_SRC} ]
            then
	        return
            else
	        wget "https://registrationcenter-download.intel.com/akdlm/irc_nas/${INTEL_COMPILER_DL_ID}/${INTEL_COMPILER_SRC}"
	        if [ $? -ne 0 ]
	        then
                    return $?
	        fi
	    fi
	    if [ -f ${INTEL_HPC_COMPILER_SRC} ]
	    then
	        return
            else
                wget "https://registrationcenter-download.intel.com/akdlm/irc_nas/${INTEL_HPC_COMPILER_DL_ID}/${INTEL_HPC_COMPILER_SRC}"
	        return $?
            fi
	fi

	if [ ! -f ${AMD_COMPILER_SRC} ] && [ ${USE_GNU} -eq 0 ]
	then
	    echo "Please go to https://developer.amd.com/amd-aocc/#downloads , download ${AMD_COMPILER_SRC} to $(pwd)/ and run the installation again" >&2
	    echo "Please go to https://developer.amd.com/amd-aocl/#downloads , download ${AMD_AOCL_SRC} to $(pwd)/ and run the installation again" >&2
	    exit 1
	fi
	if [ -f ${AMD_AOCL_SRC} ] && [ ${USE_GNU} -eq 0 ]
	then
	    return
	fi
    fi
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
}


install_arm_compiler()
{
    sudo rm -rf arm-compiler-for-linux_${ARM_COMPILER_VERSION}_RHEL-${S_VERSION_ID}
    tar xf arm-compiler-for-linux_${ARM_COMPILER_VERSION}_RHEL-${S_VERSION_ID}_aarch64.tar
    cd arm-compiler-for-linux_${ARM_COMPILER_VERSION}_RHEL-${S_VERSION_ID}
    sudo bash arm-compiler-for-linux_${ARM_COMPILER_VERSION}_RHEL-${S_VERSION_ID}.sh -a -i ${HPC_PREFIX}/opt -f
    cd ..
}

install_intel_compiler()
{
    sudo bash ${INTEL_HPC_COMPILER_SRC} -a --action remove -s
    sudo bash ${INTEL_COMPILER_SRC} -a --action remove -s
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
    sudo bash ./install.sh -t ${HPC_PREFIX}/opt/ -i lp64
    cd ..
}

install_gnu_compiler()
{   
    build_elfutils_stage_one
    # after build binutils, use it for gcc build
    export OPATH=${PATH}
    export PATH=${HPC_PREFIX}/tmp/${HPC_COMPILER}/${TARGET}/bin:${HPC_PREFIX}/tmp/${HPC_COMPILER}/bin:${PATH}
    export OLD_LIBRARY_PATH=${LD_LIBRARY_PATH}
    export LD_LIBRARY_PATH=${HPC_PREFIX}/tmp/${HPC_COMPILER}/lib64:${HPC_PREFIX}/${HPC_COMPILER}/tmp/lib:${LD_LIBRARY_PATH}
    build_binutils_stage_one
    build_gcc_stage_one
    build_elfutils
    export PATH=${HPC_PREFIX}/opt/gnu/${TARGET}/bin:${HPC_PREFIX}/opt/gnu/bin:${HPC_PREFIX}/tmp/${HPC_COMPILER}/${TARGET}/bin:${HPC_PREFIX}/tmp/${HPC_COMPILER}/bin:${PATH}
    export LD_LIBRARY_PATH=${HPC_PREFIX}/opt/gnu/lib64:${HPC_PREFIX}/opt/gnu/lib:${LD_LIBRARY_PATH}
    build_binutils
    # after build binutils, use the official version to rebuild gcc
    build_gcc

    # restore enviroment
    export PATH=${OPATH}
    export LD_LIBRARY_PATH=${OLD_LIBRARY_PATH}
    unset OPATH
    unset OLD_LIBRARY_PATH
}

install_compiler()
{
    echo "zzz *** $(date) *** Install vendor compiler"
    if [ ${USE_GNU} -eq 1 ]
    then
	install_gnu_compiler
	return
    fi

    if [ "${SARCH}" == "aarch64" ]
    then
        install_arm_compiler
    elif [ "${SARCH}" == "x86_64" ]
    then
        install_intel_compiler
    elif [ "${SARCH}" == "amd64" ]
    then
	if [ ${USE_INTEL_ICC} -eq 1 ]
	then
            install_intel_compiler
	else
	    install_amd_compiler
	fi
    fi
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
	    #--target=${TARGET} \
    ../configure --prefix=${HPC_PREFIX}/tmp/${HPC_COMPILER}  \
	    --build=$(../config.guess) \
	    --host=$(../config.guess) \
	    --target=${TARGET} \
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
	    #--host=${HOST} \
	    #--target=${TARGET} \
	    #--with-sysroot=/ \
#    LD=$(which ld) \
    ../configure --prefix=${HPC_PREFIX}/opt/gnu \
	    --build=${TARGET} \
	    --host=${TARGET} \
	    --target=${TARGET} \
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
    make
    sudo --preserve-env=PATH,LD_LIBRARY_PATH env make install
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
    make
    sudo --preserve-env=PATH,LD_LIBRARY_PATH env make install
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
	    #--target=${TARGET} --disable-lto \
	    #--build=$(../config.guess) \
	    #--host=${HOST} \
	    #--target=${TARGET} \
    ../configure --prefix=${HPC_PREFIX}/tmp/${HPC_COMPILER} \
	    --build=$(../config.guess) \
	    --host=$(../config.guess) \
	    --target=${TARGET} \
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
	    #--build=${TARGET} \
	    #--host=${TARGET} \
	    #--target=${TARGET} \
    ../configure --prefix=${HPC_PREFIX}/opt/gnu \
	    --build=${TARGET} \
	    --host=${TARGET} \
	    --target=${TARGET} \
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
    if [ ${USE_GNU} -eq 1 ]
    then
	MODULE_VERSION=${GCC_VERSION}
	return
    fi

    if [ "${SARCH}" == "aarch64" ]
    then
	MODULE_VERSION=${ARM_COMPILER_VERSION}
    elif [ "${SARCH}" == "x86_64" ]
    then
	MODULE_VERSION=${INTEL_COMPILER_VERSION}
    elif [ "${SARCH}" == "amd64" ]
    then
	if [ ${USE_INTEL_ICC} -eq 1 ]
	then
	    MODULE_VERSION=${INTEL_COMPILER_VERSION}
	else
	    MODULE_VERSION=${AMD_COMPILER_VERSION}
	fi
    fi
}
