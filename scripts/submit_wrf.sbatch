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
# compiler & MPI selection
# compiler table:
# ---------------
# 0 VENDOR's compiler, Intel=icc, AMD=armclang, ARM=armgcc
# 1 GNU/GCC compiler
# 2 GNU/CLANG compiler
# 3 INTEL/ICC compiler
# 4 INTEL/ICX compiler
# 5 AMD/CLANG compiler
# 6 ARM/GCC compiler
# 7 ARM/CLANG compiler
#
#
# MPI table:
# ----------
# 0 openmpi
# 1 mpich
# 2 intelmpi
#
# usage: env.sh <compiler> <MPI>
#        C M
# env.sh 0 0   ## select vendor's native compilers with openmpi
# env.sh 0 1   ## select vendor's native compilers with mpich
# env.sh 0 2   ## select vendor's native compilers with intelmpi
# env.sh 1 0   ## select GNU/GCC compilers with openmpi
# env.sh ...

source /fsx/scripts/env.sh 0 0
#----------------------------------------------------------------------------

# detect EFA support
source /fsx/scripts/detect_efa.sh

ulimit -s unlimited

#Report bindings
#    Intel MPI: -print-rank-map
#    MVAPICH2: MV2_SHOW_CPU_BINDING=1
#    OpenMPI: --report-bindings

if [ "${HPC_MPI}" == "intelmpi" ]
then
    SHOW_BIND_OPTS="-print-rank-map"
elif ["${HPC_MPI}" == "openmpi" ]
then
    SHOW_BIND_OPTS="--report-bindings"
fi

echo "Running WRF on $(date)"
cd ${JOB_DIR}
ln -sf /fsx/wrf-${WARCH}/${WRF_COMPILER}/WRF-${WRF_VERSION}/main/wrf.exe  .

START_DATE=$(date)
echo "${START_DATE} - JobStart - $(basename ${JOB_DIR}) - ${WRF_COMPILER} - ${HPC_MPI}" >> wrf_$(uname -m).time

mpirun ${SHOW_BIND_OPTS} ./wrf.exe >> mpirun_${WARCH}_${WRF_COMPILER}_${HPC_MPI}.log 2>&1

END_DATE=$(date)
echo "${END_DATE} - JobEnd - $(basename ${JOB_DIR}) - ${WRF_COMPILER} - ${HPC_MPI}" >> wrf_$(uname -m).time

JOB_FINISH_TIME=$(($(date -d "${END_DATE}" +%s)-$(date -d "${START_DATE}" +%s)))
echo "$(date) - Job ${JOB_DIR} took ${JOB_FINISH_TIME} seconds($(echo "scale=2;${JOB_FINISH_TIME}/3600" | bc) hours)." >> wrf_$(uname -m).time
