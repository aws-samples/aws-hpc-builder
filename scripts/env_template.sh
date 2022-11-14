#!/bin/sh
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.
# SPDX-License-Identifier: MIT

PREFIX=XXPREFIXXX
# compiler selection
# env.sh 1     ## select GNU/GCC/gfortran
# env.sh       ## select vendor's native compliers(Intel=icc, AMD=clang, ARM=armgcc)
# env.sh 0     ## select vendor's native compliers(Intel=icc, AMD=clang, ARM=armgcc)
# env.sh 0 1   ## select Intel icc on AMD64 and armclang on AArch64
# env.sh 0 1 1 ## select Intell icc and Intel MPI

# default settings
USE_GNU=${1:-0}
USE_INTEL_ICC=${2:-0}
USE_INTEL_MPI=${3:-0}
USE_ARM_CLANG=${2:-0}


source ${PREFIX}/scripts/compiler.sh

if [ ${USE_INTEL_MPI} -ne 1 ]
then
    export PATH=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_TARGET}/bin:${HPC_PREFIX}/${HPC_COMPILER}/bin:${PATH}
    export LD_LIBRARY_PATH=${HPC_PREFIX}/${HPC_COMPILER}/lib64:${HPC_PREFIX}/${HPC_COMPILER}/lib:${LD_LIBRARY_PATH}
fi

export OMP_STACKSIZE=128M
