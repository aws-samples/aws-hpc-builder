#!/bin/bash
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.
# SPDX-License-Identifier: MIT

WRF_VERSION=3.9.1

USE_VENDOR_COMPILER=${1:-vendor}
if [ "${USE_VENDOR_COMPILER}" == "gnu" ]
then
    # use WRF built by GNU/GCC compiler
    source /fsx/scripts/env.sh 1
else
    # use WRF built by vendor compiler
    source /fsx/scripts/env.sh
fi

ln -sf /fsx/wrf-${WARCH}/${WRF_COMPILER}/WRF-${WRF_VERSION}/main/wrf.exe  .

ulimit -s unlimited

if [ "$(arch)" == "x86_64" ]
then
    num_proc=$(echo $(nproc)/2 | bc)
elif [ "$(arch)" == "aarch64" ]
then
    num_proc=$(nproc)
fi

time ./wrf.exe
#time mpirun -np ${num_proc} wrf.exe
