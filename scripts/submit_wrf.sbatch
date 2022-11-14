#!/bin/bash
# Copyright # Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.
# SPDX-License-Identifier: MIT

#SBATCH --wait-all-nodes=1
#SBATCH --ntasks-per-node=64
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-core=1
#SBATCH --export=ALL
#SBATCH --exclusive
#SBATCH -o /fsx/slurm.out

#--------------------------- customized Job env -----------------------------
#SBATCH --nodes=6
#SBATCH --partition=wrfc7g

#export WRF_VERSION=4.2.2
#export JOB_DIR=/fsx/spooler/xxxxxx

#export WRF_VERSION=4.2.2
#export JOB_DIR=/fsx/spooler/conus_2.5km_v4

export WRF_VERSION=3.9.1
export JOB_DIR=/fsx/spooler/run

#export WRF_VERSION=3.9.1
#export JOB_DIR=/fsx/spooler/wrf_sample_3.9
#----------------------------------------------------------------------------

#ENV VARIABLES#

#------------------------------- Run-time env -------------------------------
# compiler selection
# env.sh 1     ## select GNU/GCC/gfortran
# env.sh       ## select vendor's native compliers(Intel=icc, AMD=clang, ARM=armgcc)
# env.sh 0     ## select vendor's native compliers(Intel=icc, AMD=clang, ARM=armgcc)
# env.sh 0 1   ## select Intel icc on AMD64 and armclang on AArch64
# env.sh 0 1 1 ## select Intell icc and Intel MPI

source /fsx/scripts/env.sh
#----------------------------------------------------------------------------

# detect EFA support
source /fsx/scripts/detect_efa.sh

ulimit -s unlimited

echo "Running WRF on $(date)"
cd ${JOB_DIR}
ln -sf /fsx/wrf-${WARCH}/${WRF_COMPILER}/WRF-${WRF_VERSION}/main/wrf.exe  .

START_DATE=$(date)
echo "${START_DATE} - JobStart - $(basename ${JOB_DIR}) - ${WRF_COMPILER}" >> wrf_$(uname -m).time

mpirun --report-bindings ./wrf.exe >> mpirun_${WARCH}_${WRF_COMPILER}.log 2>&1

END_DATE=$(date)
echo "${END_DATE} - JobEnd - $(basename ${JOB_DIR}) - ${WRF_COMPILER}" >> wrf_$(uname -m).time

JOB_FINISH_TIME=$(($(date -d "${END_DATE}" +%s)-$(date -d "${START_DATE}" +%s)))
echo "$(date) - Job ${JOB_DIR} took ${JOB_FINISH_TIME} seconds($(echo "scale=2;${JOB_FINISH_TIME}/3600" | bc) hours)." >> wrf_$(uname -m).time
