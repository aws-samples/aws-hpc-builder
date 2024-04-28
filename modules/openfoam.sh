#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

OPENFOAM_VERSION=${2:-2212}
OPENFOAM_MAJOR_VERSION=$(echo ${OPENFOAM_VERSION} | cut -f1 -d.)

if [ ${OPENFOAM_MAJOR_VERSION} -gt 1000 ]
then
    THIRDPARTY_SRC=ThirdParty-v${OPENFOAM_VERSION}.tgz
    OPENFOAM_SRC=OpenFOAM-v${OPENFOAM_VERSION}.tgz
elif [ ${OPENFOAM_MAJOR_VERSION} -gt 5 ]
then
    THIRDPARTY_SRC=ThirdParty-${OPENFOAM_VERSION}-version-${OPENFOAM_VERSION}.tgz
    OPENFOAM_SRC=OpenFOAM-${OPENFOAM_VERSION}-version-${OPENFOAM_VERSION}.tgz
elif [ ${OPENFOAM_MAJOR_VERSION} -gt 3 ]
then
    THIRDPARTY_SRC=ThirdParty-${OPENFOAM_MAJOR_VERSION}.x-version-${OPENFOAM_VERSION}.tgz
    OPENFOAM_SRC=OpenFOAM-${OPENFOAM_MAJOR_VERSION}.x-version-${OPENFOAM_VERSION}.tgz
else
    THIRDPARTY_SRC=ThirdParty-${OPENFOAM_VERSION}.tgz
    OPENFOAM_SRC=OpenFOAM-${OPENFOAM_VERSION}.tgz
fi

DISABLE_COMPILER_ENV=false

install_sys_dependency_for_openfoam()
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

download_openfoam()
{
    if [ ! -f ${OPENFOAM_SRC} ]
    then
        if [ ${OPENFOAM_MAJOR_VERSION} -gt 1000 ]
	then
	    curl --retry 3 -JLOk https://dl.openfoam.com/source/v${OPENFOAM_VERSION}/${OPENFOAM_SRC}
        else
            curl --retry 3 -JLOk https://dl.openfoam.org/source/$(echo ${OPENFOAM_VERSION} | tr '.' '-')
	fi
	result=$?
	if [ ${result} -ne 0 ]
	then
	    return ${result}
	fi
    fi
    if [ -f ${THIRDPARTY_SRC} ]
    then
	return
    else
        if [  ${OPENFOAM_MAJOR_VERSION} -gt 1000 ]
	then
	    curl --retry 3 -JLOk https://dl.openfoam.com/source/v${OPENFOAM_VERSION}/${THIRDPARTY_SRC}
        else
            curl --retry 3 -JLOk https://dl.openfoam.org/third-party/$(echo ${OPENFOAM_VERSION} | tr '.' '-')
	fi
	return $?
    fi
}

patch_openfoam()
{
    if [ -f ../../patch/openfoam/openfoam-$(arch)-${HPC_COMPILER}.patch ]
    then
	patch -Np1 < ../../patch/openfoam/openfoam-$(arch)-${HPC_COMPILER}.patch
    fi
}

install_openfoam()
{
    echo "zzz *** $(date) *** Build ${OPENFOAM_SRC%.tgz}"
    # OpenFOAM 旧版本的 Clean PATH 会把安装目录下的 bin PATH 清理掉，
    # 因此安装目录不能同 HPC 软件安装目录相同，故放在 OpenFOAM 子目录
    export OPENFOAM_PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/OpenFOAM
    sudo mkdir -p ${OPENFOAM_PREFIX}
    #sudo chown -R $(id -u):$(id -g) ${OPENFOAM_PREFIX}
    sudo rm -rf "${OPENFOAM_PREFIX}/OpenFOAM-${OPENFOAM_VERSION}"
    sudo rm -rf "${OPENFOAM_PREFIX}/ThirdParty-${OPENFOAM_VERSION}"
    tar xf "${OPENFOAM_SRC}"
    tar xf "${THIRDPARTY_SRC}"
    sudo mv "${OPENFOAM_SRC%.tgz}" "${OPENFOAM_PREFIX}/OpenFOAM-${OPENFOAM_VERSION}"
    sudo mv "${THIRDPARTY_SRC%.tgz}" "${OPENFOAM_PREFIX}/ThirdParty-${OPENFOAM_VERSION}"

    case ${HPC_COMPILER} in
	"amdclang")
	    WM_COMPILER=Clang
	    ;;
	"armclang")
	    WM_COMPILER=Arm
	    ;;
	"armgcc"|"gcc")
	    WM_COMPILER=Gcc
	    ;;
	"clang")
	    WM_COMPILER=Clang
	    ;;
	"nvc")
	    WM_COMPILER=Nvidia
	    ;;
	"icc")
	    WM_COMPILER=Icc
	    ;;
	"icx")
	    WM_COMPILER=Icx
	    ;;
	*)
	    exit 1
	    ;;
    esac

    case ${HPC_MPI} in
	"intelmpi")
	    export MPI_ROOT=${I_MPI_ROOT}
	    export MPI_ARCH_FLAGS="-DMPICH_SKIP_MPICXX -DOMPI_SKIP_MPICXX"
	    WM_MPLIB="INTELMPI"
	    ;;
	"mpich"|"mvapich"|"openmpi")
	    export MPI_ROOT=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
	    export MPI_ARCH_FLAGS="-DMPICH_SKIP_MPICXX -DOMPI_SKIP_MPICXX"
	    export MPI_ARCH_INC="-isystem ${MPI_ROOT}/include"
	    WM_MPILIB="SYSTEMMPI"
	    if [ "${HPC_MPI}" == "openmpi" ]
	    then 
		export MPI_ARCH_LIBS="-L${MPI_ROOT}/lib -lmpi"
	    else
		export MPI_ARCH_LIBS="-L${MPI_ROOT}/lib -lmpi -lrt"
	    fi
	    ;;
	*)
	    echo "unknown or unsupported MPI"
	    exit 1
	    ;;
    esac

    export FOAM_INST_DIR=${OPENFOAM_PREFIX}

    . "${OPENFOAM_PREFIX}/OpenFOAM-${OPENFOAM_VERSION}/etc/bashrc" WM_COMPILER=${WM_COMPILER} WM_MPLIB=${WM_MPLIB}
    #export LD_LIBRARY_PATH=${FOAM_LIBBIN}:${LD_LIBRARY_PATH}
    cd "${OPENFOAM_PREFIX}/OpenFOAM-${OPENFOAM_VERSION}"
    # 4 以下版本 ipcp 等编译器无法找到 .o 文件导致很多库无法链接，而编译器生成的是 .so 文件
    # https://www.cfd-online.com/Forums/openfoam-programming-development/162594-usr-bin-ld-cannot-find-llagrangianturbulence-usr-bin-ld-cannot-find-lfluidtherm.html
    if [ ${OPENFOAM_MAJOR_VERSION} -lt 4 ] && [ "${HPC_COMPILER}" == "icc" ]
    then
	sed -i 's/libOSspecific.o/libOSspecific.so/g' src/OpenFOAM/Make/options
       	sed -i 's/postCalc.o/postCalc.so/g' applications/utilities/postProcessing/*/*/Make/options
    fi
    if [ ${OPENFOAM_MAJOR_VERSION} -lt 3 ]
    then
        # version 2.3.1 with isnan issue: https://bugs.openfoam.org/view.php?id=2041
        sed -i -e 's/ isnan/ std::isnan/g' -e 's/(isnan/(std::isnan/g' src/conversion/ensight/part/ensightPart*.C
        # cmake issue
        sed -i 's%//CMakeLists.txt%/CMakeLists.txt%g' ../ThirdParty-${OPENFOAM_VERSION}/CGAL-*/src/CMakeLists.txt
    fi
    # Gcc: warning: ISO C++17 does not allow ‘register’ storage class specifier [-Wregister]
    # Clang: 'register' storage class specifier is deprecated and incompatible with C++17 [-Wdeprecated-register]
    #export WM_CFLAGS="${WM_CFLAGS} -std=gnu11"
    #export WM_CXXFLAGS="${WM_CXXFLAGS} -std=gnu++11"
    #sed -i 's/^cOPT *= /&-std=gnu99 /g' wmake/rules/linux64${WM_COMPILER}/cOpt
    #sed -i 's/^c++OPT *= /&-std=gnu++98 /g' wmake/rules/linux64${WM_COMPILER}/c++Opt
    #./Allwmake -s -l
    ./Allwmake -s || exit 1
    cd -

}

update_openfoam_version()
{
    MODULE_VERSION=${OPENFOAM_VERSION}
}
