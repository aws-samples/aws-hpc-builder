#!/bin/bash
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.
# SPDX-License-Identifier: MIT

if [ "${HPC_ENV_SET}" == "yes" ]
then
    echo $"AWS HPC Builder environment has been set, deactivate it with \"hpc_deactivate\" first."
    return
fi

hpc_deactivate () {
    # reset old environment variables
    if [ -n "${_OLD_PATH:-}" ]
    then
        export PATH="${_OLD_PATH:-}"
	export MANPATH="${_OLD_MANPATH:-}"
	export LD_LIBRARY_PATH="${_OLD_LD_LIBRARY_PATH:-}"
	export LIBRARY_PATH="${_OLD_LIBRARY_PATH:-}"
	export PKG_CONFIG_PATH="${_OLD_PKG_CONFIG_PATH:-}"
	export MODULEPATH="${_OLD_MODULEPATH:-}"
	export LOADEDMODULES="${_OLD_LOADEDMODULES:-}"
	unset _OLD_PATH
	unset _OLD_MANPATH
	unset _OLD_LD_LIBRARY_PATH
	unset _OLD_LIBRARY_PATH
	unset _OLD_PKG_CONFIG_PATH
	unset _OLD_MODULEPATH
	unset _OLD_LOADEDMODULES

	unset PREFIX
	unset SARCH
	unset HPC_PREFIX
	unset HPC_TARGET
	unset HPC_HOST_TARGET
	unset HPC_COMPILER
	unset HPC_MPI
	unset HPC_CFLAGS
	unset HPC_FFT_LIB
	unset HPC_INCS
	unset HPC_INC_DIR
	unset HPC_LLIBS
	unset PROG_MODEL

	unset -f check_and_install_gcc10
	unset -f fix_clang_ld
	unset -f get_compiler
	unset -f set_compiler_env
	unset -f unset_compiler_env
	unset -f use_vendor_compiler
	unset -f validate_compiler
	unset -f check_and_use_intelmpi
	unset -f check_and_use_nvidiampi
	unset -f print_msg
	unset -f print_mark

	unset HPC_ENV_SET
    fi

    # This should detect bash and zsh, which have a hash command that must
    # be called to get it to forget past commands.  Without forgetting
    # past commands the $PATH changes we made may not be respected
    if [ -n "${BASH:-}" -o -n "${ZSH_VERSION:-}" ]
    then
        hash -r 2> /dev/null
    fi

    if [ -n "${_OLD_PS1:-}" ]
    then
        export PS1="${_OLD_PS1:-}"
        unset _OLD_PS1
    fi

    if [ ! "${1:-}" == "nondestructive" ]
    then
    # Self destruct!
        unset -f hpc_deactivate
    fi
}

# unset irrelevant variables
hpc_deactivate nondestructive

export _OLD_PATH="${PATH}"
export _OLD_MANPATH="${_OLD_MANPATH}"
export _OLD_LD_LIBRARY_PATH="${LD_LIBRARY_PATH}"
export _OLD_LIBRARY_PATH="${LIBRARY_PATH}"
export _OLD_PKG_CONFIG_PATH="${PKG_CONFIG_PATH}"

if [ -z "${HPC_ENV_DISABLE_PROMPT:-}" ]
then
    export _OLD_PS1="${PS1}"
    PS1="\[\e[1m\e[93m\](AWS HPC Builder)\[\e[0m\] ${PS1:-}"
    export PS1
    HPC_ENV_PROMPT="(AWS HPC Builder) "
    export HPC_ENV_PROMPT
fi

# This should detect bash and zsh, which have a hash command that must
# be called to get it to forget past commands.  Without forgetting
# past commands the $PATH changes we made may not be respected
if [ -n "${BASH:-}" -o -n "${ZSH_VERSION:-}" ]
then
    hash -r 2> /dev/null
fi

fix_clang_ld()
{
    if [ "${HPC_COMPILER}" == "clang" ] || [ "${HPC_COMPILER}" == "armclang" ] || [ "${HPC_COMPILER}" == "amdclang" ]
    then
        # https://github.com/Unidata/netcdf-fortran/issues/309
        sed -i -e 's/wl=""/wl="-Wl,"/g' -e 's/pic_flag=""/pic_flag="-fPIC -DPIC"/g' libtool
	#sed -i -e 's#wl=""#wl="-Wl,"#g' libtool
	#sed -i -e 's#pic_flag=""#pic_flag=" -fPIC -DPIC"#g' libtool
    fi
}

fix_lib_missing()
{
    if [ "${HPC_COMPILER}" == "gcc" ]
    then
        echo "${HPC_PREFIX}/opt/gnu/lib64" > /tmp/libgfortran.conf
        sudo mv /tmp/libgfortran.conf /etc/ld.so.conf.d/
        sudo ldconfig > /dev/null 2>&1 
    elif [ "${HPC_COMPILER}" == "icc" ]
    then
        # Intel 编译器找不到 libimf 的问题: https://stackoverflow.com/questions/70687930/intel-oneapi-2022-libimf-so-no-such-file-or-directory-during-openmpi-compila
        INTEL_ICC_VERSION=$(ls -lhd ${HPC_PREFIX}/opt/intel/oneapi/compiler/latest | awk '{print $NF}')
        echo "${HPC_PREFIX}/opt/intel/oneapi/compiler/${INTEL_ICC_VERSION}/linux/compiler/lib/intel64_lin/" > /tmp/libimf.conf
        sudo mv /tmp/libimf.conf /etc/ld.so.conf.d/
        sudo ldconfig > /dev/null 2>&1 
    elif [ "${HPC_COMPILER}" == "armgcc" ]
    then
        # ARM 编译器找不到 libgfortran 的问题
        ARM_GCC_VERSION=$(module avail 2>&1 | grep -A1 "${HPC_PREFIX}" | tail -n1 | awk '{print $3}' | sed s"%gnu/%%g")
	if [ "${HPC_PACKAGE_TYPE}" == "rpm" ]
	then
	    echo "${HPC_PREFIX}/opt/gcc-${ARM_GCC_VERSION}_Generic-AArch64_RHEL-${S_VERSION_ID}_aarch64-linux/lib64/" > /tmp/libgfortran.conf
	elif [ "${HPC_PACKAGE_TYPE}" == "deb" ]
	then
	    echo "${HPC_PREFIX}/opt/gcc-${ARM_GCC_VERSION}_Generic-AArch64_Ubuntu-${S_VERSION_ID}.04_aarch64-linux/lib64/" > /tmp/libgfortran.conf
	fi
        sudo mv /tmp/libgfortran.conf /etc/ld.so.conf.d/
        sudo ldconfig > /dev/null 2>&1 
    elif [ "${HPC_COMPILER}" == "amdclang" ]
    then
	echo "${HPC_PREFIX}/opt/aocc-compiler-${AMD_COMPILER_VERSION}/lib" > /tmp/libomp.conf
	sudo mv /tmp/libomp.conf /etc/ld.so.conf.d/
	sudo ldconfig > /dev/null 2>&1 
    fi
}

check_and_uninstall_gcc10()
{
    if [ ${GCC10_INSTALLED} -eq 1 ] && ([ "${HPC_COMPILER}" == "clang" ] ||  [ "${HPC_COMPILER}" == "armclang" ])
    then
	sudo rpm -e --nodeps gcc10
    fi
}

check_and_install_gcc10()
{
    if [ ${GCC10_INSTALLED} -eq 1 ] && ([ "${HPC_COMPILER}" == "clang" ] ||  [ "${HPC_COMPILER}" == "armclang" ])
    then
	sudo yum install -y gcc10
    fi
}

validate_compiler()
{
    if [ "${SARCH}" == "x86_64" ] || [ "${SARCH}" == "amd64" ]
    then
	if [ "${HPC_COMPILER}" == "icc" ] || [ "${HPC_COMPILER}" == "icx" ] || [ "${HPC_COMPILER}" == "gcc" ] || [ "${HPC_COMPILER}" == "clang" ] || [ "${HPC_COMPILER}" == "amdclang" ] || [ "${HPC_COMPILER}" == "nvc" ]
	then
	    return
	fi
    elif [ "${SARCH}" == "aarch64" ]
    then
	if [ "${HPC_COMPILER}" == "armgcc" ] || [ "${HPC_COMPILER}" == "armclang" ] || [ "${HPC_COMPILER}" == "gcc" ] || [ "${HPC_COMPILER}" == "clang" ] || [ "${HPC_COMPILER}" == "nvc" ]
	then
	    return
	fi
    fi
    return 1
}

check_and_use_intelmpi()
{
    if [ "${HPC_MPI}" == "intelmpi" ]
    then
	export I_MPI_CC=${CC}
	export I_MPI_FC=${FC}
	export I_MPI_CXX=${CXX}
	export I_MPI_F90=${F90}
	export I_MPI_F77=${F77}
    fi
}

check_and_use_nvidiampi()
{
    if [ "${HPC_MPI}" == "nvidiampi" ]
    then
	export OMPI_CC=${CC}
	export OMPI_FC=${FC}
	export OMPI_CXX=${CXX}
	export OMPI_F77=${F77}
    fi
}

# openmpi 找不到编译器, 使用全路径
use_vendor_compiler()
{
    if [ "${SARCH}" == "x86_64" ]
    then
        export FC=$(which ifort)
        export F77=$(which ifort)
        export F90=$(which ifort)
        export CC=$(which icc)
        export CXX=$(which icpc)
        export AR=$(which xiar)
        #export OMPI_CC=icc
        #export OMPI_CXX=icpc
        #export OMPI_FC=ifort
    elif [ "${SARCH}" == "amd64" ]
    then
	export FC=$(which flang)
	export F77=$(which flang)
	export F90=$(which flang)
	export CC=$(which clang)
	export CXX=$(which clang++)
	export AR=$(which llvm-ar)
	export RANLIB=$(which llvm-ranlib)
	#export OMPI_CC=$(which clang)
	##export OMPI_CXX=$(which clang++)
	##export OMPI_FC=$(which flang)
    elif [ "${SARCH}" == "aarch64" ]
    then
	export FC=$(which gfortran)
	export F77=$(which gfortran)
	export F90=$(which gfortran)
	export CC=$(which gcc)
	export CXX=$(which g++)
	export AR=$(which $(${CC} -dumpmachine)-gcc-ar)
	export NM=$(which $(${CC} -dumpmachine)-gcc-nm)
	export RANLIB=$(which $(${CC} -dumpmachine)-gcc-ranlib)
	#export OMPI_CC=gcc
	##export OMPI_CXX=g++
	##export OMPI_FC=gfortran
    fi
    check_and_use_intelmpi
}

set_compiler_env()
{
    if (! validate_compiler)
    then
	echo "Unknown compiler or unsupported compiler, please check the compiler settings"
	exit 1
    fi

    if [ "${HPC_USE_VENDOR_COMPILER}" == "false"  ]
    then
	case ${HPC_COMPILER} in
	    "gcc")
		export FC=$(which gfortran)
		export F77=$(which gfortran)
		export F90=$(which gfortran)
		export CC=$(which gcc)
		export CXX=$(which g++)
		export AR=$(which $(${CC} -dumpmachine)-gcc-ar)
		export NM=$(which $(${CC} -dumpmachine)-gcc-nm)
		export RANLIB=$(which $(${CC} -dumpmachine)-gcc-ranlib)
		;;
	    "clang"|"amdclang")
		export FC=$(which flang)
		export F77=$(which flang)
		export F90=$(which flang)
		export CC=$(which clang)
		export CXX=$(which clang++)
		export AR=$(which llvm-ar)
		export RANLIB=$(which llvm-ranlib)
		#export OMPI_CC=$(which clang)
		##export OMPI_CXX=$(which clang++)
		#export OMPI_FC=$(which flang)
		;;
	    "icc")
		export FC=$(which ifort)
		export F77=$(which ifort)
		export F90=$(which ifort)
		export CC=$(which icc)
		export CXX=$(which icpc)
		export AR=$(which xiar)
		#export OMPI_CC=icc
		##export OMPI_CXX=icpc
		##export OMPI_FC=ifort
		;;
	    "icx")
		export FC=$(which ifx)
		export F77=$(which ifx)
		export F90=$(which ifx)
		export CC=$(which icx)
		export CXX=$(which icpx)
		#export AR=$(which xiar)
		#export OMPI_CC=icc
		##export OMPI_CXX=icpc
		##export OMPI_FC=ifort
		;;
	    "armgcc")
		export FC=$(which gfortran)
		export F77=$(which gfortran)
		export F90=$(which gfortran)
		export CC=$(which gcc)
		export CXX=$(which g++)
		export AR=$(which $(${CC} -dumpmachine)-gcc-ar)
		export NM=$(which $(${CC} -dumpmachine)-gcc-nm)
		export RANLIB=$(which $(${CC} -dumpmachine)-gcc-ranlib)
		#export OMPI_CC=gcc
		##export OMPI_CXX=g++
		##export OMPI_FC=gfortran
		;;
	    "armclang")
		export FC=$(which armflang)
		export F77=$(which armflang)
		export F90=$(which armflang)
		export CC=$(which armclang)
		export CXX=$(which armclang++)
		export AR=$(which armllvm-ar)
		export RANLIB=$(which armllvm-ranlib)
		#export OMPI_CC=gcc
		##export OMPI_CXX=g++
		##export OMPI_FC=gfortran
		;;
	    "nvc")
		export FC=$(which nvfortran)
		export F77=$(which nvfortran)
		export F90=$(which armflang)
		export CC=$(which nvc)
		export CXX=$(which nvc++)
		#export OMPI_CC=gcc
		##export OMPI_CXX=g++
		##export OMPI_FC=gfortran
		;;
	esac
	# to change to pre-build MPIs' compilers, have to specify the corresponding environment parameters
	check_and_use_intelmpi
	check_and_use_nvidiampi
	return
    fi
    use_vendor_compiler
}

unset_compiler_env()
{
	unset FC
	unset F77
	unset F90
	unset CC
	unset CXX
	unset AR
	unset NM
	unset RANLIB
	#unset OMPI_CC
	#unset OMPI_CXX
	#unset OMPI_FC
}

get_compiler()
{
    if [ "${HPC_USE_VENDOR_COMPILER}" == "false" ]
    then
        return
    fi

    if [ "${SARCH}" == "x86_64" ]
    then
        export HPC_COMPILER=icc
    elif [ "${SARCH}" == "amd64" ]
    then
	export HPC_COMPILER=amdclang
    elif [ "${SARCH}" == "aarch64" ]
    then
	export HPC_COMPILER=armgcc
    fi
}

export SARCH=$(arch)
export HPC_HOST_TARGET=$(/usr/bin/gcc -dumpmachine)

#if [ "${SARCH}" == "x86_64" ] && (sudo dmidecode -t processor | grep AMD > /dev/null)
if [ "${SARCH}" == "x86_64" ] && (grep AMD /proc/cpuinfo > /dev/null)
then
    export SARCH=amd64
fi

get_compiler
export PROG_MODEL=lp64

export HPC_PREFIX="${PREFIX}/${SARCH}"

if [ ! -f ${PREFIX}/${SARCH}/.world ] || (! grep -q "^${HPC_COMPILER}" ${PREFIX}/${SARCH}/.world)
then
    echo -e "\e[1m\e[31mCompiler not found, deactivate AWS HPC Builder environment.\e[0m"
    hpc_deactivate
    return
fi


case ${HPC_COMPILER} in
    "gcc"|"clang")
	export HPC_TARGET=$(${HPC_PREFIX}/opt/gnu/bin/${HPC_COMPILER} -dumpmachine)
	export LD_LIBRARY_PATH=${HPC_PREFIX}/opt/gnu/lib64:${HPC_PREFIX}/opt/gnu/lib:${LD_LIBRARY_PATH}
	export PATH=${HPC_PREFIX}/opt/gnu/${HPC_TARGET}/bin:${HPC_PREFIX}/opt/gnu/bin:${PATH}
	export MANPATH=:${HPC_PREFIX}/opt/gnu/share/man${MANPATH}
	if [ "$(arch)" == "aarch64" ]
	then
	    export HPC_CFLAGS="-Ofast -mcpu=native"
	    export HPC_CXXFLAGS="-Ofast -mcpu=native"
	    export HPC_FCFLAGS="-Ofast -mcpu=native"
	    export HPC_FFLAGS="-Ofast -mcpu=native"
	else
	    export HPC_CFLAGS="-Ofast -march=native"
	    export HPC_CXXFLAGS="-Ofast -march=native"
	    export HPC_FCFLAGS="-Ofast -march=native"
	    export HPC_FFLAGS="-Ofast -march=native"
	fi
	export HPC_LDFLAGS="-L${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib64 -lblas -lopenblas -llapack"
	export HPC_LLIBS="-L${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib64 -lblas -lopenblas -llapack"
	export HPC_INCS="-I${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include"
	export HPC_INC_DIR="${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include"
	export C_INCLUDE_PATH="${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include"
	export CPLUS_INCLUDE_PATH="${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include"
	export HPC_FFT_LIB="-L${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/lib -llftw3"
	;;
    "armgcc")
        source /etc/profile.d/modules.sh
        #module load mpi/openmpi-${SARCH}
        export MODULEPATH=${MODULEPATH}:${HPC_PREFIX}/opt/modulefiles
        module load gnu/$(ls ${HPC_PREFIX}/opt/modulefiles/gnu)
        module load armpl/$(ls ${HPC_PREFIX}/opt/moduledeps/gnu/[0-9.]*/armpl)
        #module load $(ls ${HPC_PREFIX}/opt/moduledeps/gnu/[0-9.]*/armpl/[0-9.]*)
        export HPC_TARGET=$(gcc -dumpmachine)
	if [ "$(arch)" == "aarch64" ]
	then
	    export HPC_CFLAGS="-Ofast -mcpu=native"
	    export HPC_CXXFLAGS="-Ofast -mcpu=native"
	    export HPC_FCFLAGS="-Ofast -mcpu=native"
	    export HPC_FFLAGS="-Ofast -mcpu=native"
	else
	    export HPC_CFLAGS="-Ofast -march=native"
	    export HPC_CXXFLAGS="-Ofast -march=native"
	    export HPC_FCFLAGS="-Ofast -march=native"
	    export HPC_FFLAGS="-Ofast -march=native"
	fi
	export HPC_LDFLAGS="-L${ARMPL_DIR}/lib -larmpl_${PROG_MODEL} -lamath -lm -lastring"
	export HPC_LLIBS="-L${ARMPL_DIR}/lib -larmpl_${PROG_MODEL} -lamath -lm -lastring"
	export HPC_INC_DIR="${ARMPL_DIR}/include"
	export C_INCLUDE_PATH="${HPC_INC_DIR}:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include"
	export CPLUS_INCLUDE_PATH="${HPC_INC_DIR}:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include"
	export HPC_INCS="-I${ARMPL_DIR}/include"
	export HPC_FFT_LIB="${ARMPL_DIR}/lib/libarmpl.so"
	;;
    "armclang")
        source /etc/profile.d/modules.sh
        #module load mpi/openmpi-${SARCH}
        export MODULEPATH=${MODULEPATH}:${HPC_PREFIX}/opt/modulefiles
	module load acfl/$(ls ${HPC_PREFIX}/opt/modulefiles/acfl)
	module load armpl/$(ls ${HPC_PREFIX}/opt/moduledeps/acfl/[0-9.]*/armpl)
        export HPC_TARGET=$(armclang -dumpmachine)

	## fix system /usr/bin/ls coudn't find crtbeginS.o etc.
	## restrict the armgcc_dtarget in armgcc directory
	## replace find with echo to improve the speed
	##armgcc_lib_search_loc=$(dirname $(dirname $(find ${HPC_PREFIX}/opt -iname "crtbeginS.o" | grep Generic-AArch64)))
	##sysgcc_lib_search_loc=$(dirname $(dirname $(sudo find /usr -iname "crtbeginS.o")))
	armgcc_lib_search_loc=$(echo /fsx/aarch64/opt/*Generic-AArch64*/lib/gcc/aarch64-linux-gnu)
	sysgcc_lib_search_loc="/usr/lib/gcc/${HPC_HOST_TARGET}"


	export HPC_CFLAGS="-Ofast -mcpu=native"
	export HPC_CXXFLAGS="-Ofast -mcpu=native"
	export HPC_FCFLAGS="-Ofast -mcpu=native"
	export HPC_FFLAGS="-Ofast -mcpu=native"
	export HPC_LDFLAGS="-L${ARMPL_DIR}/lib -armpl=${PROG_MODEL} -lamath -lm -lastring"

	export HPC_LLIBS="-L${ARMPL_DIR}/lib -armpl=${PROG_MODEL} -lamath -lm -lastring"
	export HPC_INC_DIR="${ARMPL_DIR}/include"
	export C_INCLUDE_PATH="${HPC_INC_DIR}:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include"
	export CPLUS_INCLUDE_PATH="${HPC_INC_DIR}:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include"
	export HPC_INCS="-I${ARMPL_DIR}/include"
	export HPC_FFT_LIB="${ARMPL_DIR}/lib/libarmpl.so"

	## https://unix.stackexchange.com/questions/207294/create-symlink-overwrite-if-one-exists
	##If a directory, or symlink to a directory, already exists with the target name, the symlink will be created inside it
	##(so you'd end up with /path/to/recent/file/file in the example above). The -n option, available in some versions of ln,
	##will take care of symlinks to directories for you, replacing them as necessary:
	#if [ ! -d $(dirname ${sysgcc_lib_search_loc})/${HPC_TARGET} ] || [ ! -L $(dirname ${sysgcc_lib_search_loc})/${HPC_TARGET} ]
	#then
	#    sudo ln -sfn ${armgcc_lib_search_loc} $(dirname ${sysgcc_lib_search_loc})/${HPC_TARGET}
	#fi

	# add armgcc headers to search path
	# restrict the armgcc_dtarget in armgcc directory
        #for armgcc_dtarget in $(find ${HPC_PREFIX}/opt -iname aarch64-linux-gnu | grep Generic-AArch64)
	#for armgcc_dtarget in $(echo ${HPC_PREFIX}/opt/*Generic-AArch64*/{include/c++/*/,lib/gcc/,libexec/gcc/,}aarch64-linux-gnu)
        #do
	#    if [ ! -d $(dirname ${armgcc_dtarget})/${HPC_TARGET} ] || [ ! -L $(dirname ${armgcc_dtarget})/${HPC_TARGET} ]
	#    then
	#	sudo ln -sfn ${armgcc_dtarget} $(dirname ${armgcc_dtarget})/${HPC_TARGET}
	#    fi
        #done
	;;
    "icc"|"icx")
	source ${HPC_PREFIX}/opt/intel/oneapi/compiler/latest/env/vars.sh
	source ${HPC_PREFIX}/opt/intel/oneapi/mkl/latest/env/vars.sh
        export HPC_TARGET=$(${HPC_COMPILER} -dumpmachine)
	#export HPC_CFLAGS="-xHOST -fma -ftz -fomit-frame-pointer"
	#export HPC_CFLAGS="-Ofast -ipo -mavx -axCORE-AVX2,CORE-AVX512"
	#export HPC_CFLAGS="-Ofast -ipo -mavx -axCORE-AVX2,CORE-AVX512 -march=icelake-server"
	export HPC_CFLAGS="-Ofast -fp-model fast=2 -xHost -no-prec-div -no-prec-sqrt -axCORE-AVX2,CORE-AVX512"
	export HPC_CXXFLAGS="-Ofast -fp-model fast=2 -xHost -no-prec-div -no-prec-sqrt -axCORE-AVX2,CORE-AVX512"
	export HPC_FCFLAGS="-Ofast -fp-model fast=2 -xHost -no-prec-div -no-prec-sqrt -axCORE-AVX2,CORE-AVX512"
	export HPC_FFLAGS="-Ofast -fp-model fast=2 -xHost -no-prec-div -no-prec-sqrt -axCORE-AVX2,CORE-AVX512"
	export HPC_LDFLAGS="-L${MKLROOT}/lib/intel64 -lmkl_scalapack_${PROG_MODEL} -lmkl_cdft_core -lmkl_intel_${PROG_MODEL} -lmkl_intel_thread -lmkl_core -lmkl_blacs_intelmpi_${PROG_MODEL} -liomp5 -lpthread -lm -ldl"
	export HPC_LLIBS="-L${MKLROOT}/lib/intel64 -lmkl_scalapack_${PROG_MODEL} -lmkl_cdft_core -lmkl_intel_${PROG_MODEL} -lmkl_intel_thread -lmkl_core -lmkl_blacs_intelmpi_${PROG_MODEL} -liomp5 -lpthread -lm -ldl"
	export HPC_INCS="-I${MKLROOT}/include"
	export C_INCLUDE_PATH="${HPC_INC_DIR}:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include"
	export CPLUS_INCLUDE_PATH="${HPC_INC_DIR}:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include"
	export HPC_INC_DIR="${MKLROOT}/include"
	;;
    "amdclang")
	source ${HPC_PREFIX}/opt/setenv_AOCC.sh
	# acocc 4.0.0
	#source $(ls ${HPC_PREFIX}/opt/[0-9.]*/amd-libs.cfg)
	# acocc 4.1.0
	source $(ls ${HPC_PREFIX}/opt/[0-9.]*/aocc/amd-libs.cfg)
        export HPC_TARGET=$(clang -dumpmachine)
	#export HPC_CFLAGS="-O3 -march=znver3 -mfma -fvectorize -mfma -mavx2 -m3dnow -floop-unswitch-aggressive -fuse-ld=lld"
	#export HPC_CXXFLAGS="-O3 -march=znver3 -mfma -fvectorize -mfma -mavx2 -m3dnow -fuse-ld=lld"
	export HPC_CFLAGS="-Ofast -march=native -fuse-ld=lld"
	export HPC_CXXFLAGS="-Ofast -march=native -fuse-ld=lld"
	export HPC_FCFLAGS="-Ofast -march=native -fuse-ld=lld"
	export HPC_FFLAGS="-Ofast -march=native -fuse-ld=lld"
	export HPC_LDFLAGS="-L${AOCL_ROOT}/lib -lblis-mt -lflame -lscalapack -lfftw3 -lfftw3_omp -lalm -lm"
	export HPC_LLIBS="-L${AOCL_ROOT}/lib -lblis-mt -lflame -lscalapack -lfftw3 -lfftw3_omp -lalm -lm"
	export HPC_INC_DIR="${AOCL_ROOT}/include"
	export C_INCLUDE_PATH="${HPC_INC_DIR}:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include"
	export CPLUS_INCLUDE_PATH="${HPC_INC_DIR}:${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/include"
	export HPC_INCS="-I${AOCL_ROOT}/include"
	export HPC_FFT_LIB="${AOCL_ROOT}/lib/libfftw3.so"
	;;
    "nvc")
        export MODULEPATH=${MODULEPATH}:${HPC_PREFIX}/opt/nvidia/modulefiles
	module load $(basename ${HPC_PREFIX}/opt/nvidia/modulefiles/nvhpc-nompi)/$(ls ${HPC_PREFIX}/opt/nvidia/modulefiles/nvhpc-nompi)
	export HPC_TARGET=$(arch)-linux
	;;
esac

# move intelmpi loading here:
# 1. It only executes once, so the set_compiler_env is re-usable. 
# 2. unlike other mpi implementations are built from source, their default compilers are 
#    the ones built it, intelmpis' have to be specified by environments parameters
#    when unset_compiler_env, the intelmpi wrappers still uses to the correct compilers
if [ "${HPC_MPI}" == "intelmpi" ]
then
    source ${HPC_PREFIX}/opt/intel/oneapi/mpi/latest/env/vars.sh 

elif [ "${HPC_MPI}" == "nvidiampi" ]
then
    if [ "${HPC_COMPILER}" != "nvc" ]
    then
	export MODULEPATH=${MODULEPATH}:${HPC_PREFIX}/opt/nvidia/modulefiles
    fi
    module unload  $(basename ${HPC_PREFIX}/opt/nvidia/modulefiles/nvhpc-nompi)/$(ls ${HPC_PREFIX}/opt/nvidia/modulefiles/nvhpc-nompi)
    module load  $(basename ${HPC_PREFIX}/opt/nvidia/modulefiles/nvhpc)/$(ls ${HPC_PREFIX}/opt/nvidia/modulefiles/nvhpc)
fi

export LD_LIBRARY_PATH=${LIBRARY_PATH}:${LD_LIBRARY_PATH}
export HPC_ENV_SET="yes"
