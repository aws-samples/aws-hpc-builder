#!/bin/bash
# Copyright # Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.
# SPDX-License-Identifier: MIT

#SBATCH --wait-all-nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --cpus-per-task=8
#SBATCH --ntasks-per-core=1
#SBATCH --export=ALL
#SBATCH --exclusive
#SBATCH -o /fsx/log/wrf.out

#--------------------------- customized Job env -----------------------------
#SBATCH --nodes=2
#SBATCH --partition=c6gn

PREFIX=/fsx

#export WRF_VERSION=3.9.1
#export JOB_DIR=${PREFIX}/spooler/bench_12km
#export JOB_DIR=${PREFIX}/spooler/bench_2.5km

#export WRF_VERSION=4.2.2
#export JOB_DIR=${PREFIX}/spooler/v4_bench_conus12km
#export JOB_DIR=${PREFIX}/spooler/v4_bench_conus2.5km

export WRF_VERSION=4.4.2
export JOB_DIR=${PREFIX}/spooler/v4.4_bench_conus12km
#export JOB_DIR=${PREFIX}/spooler/v4.4_bench_conus2.5km
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
# 3 mvapich
#
# usage: env.sh <compiler> <MPI>
#        C M
# env.sh 0 0   ## select vendor's native compilers with openmpi
# env.sh 0 1   ## select vendor's native compilers with mpich
# env.sh 0 2   ## select vendor's native compilers with intelmpi
# env.sh 0 3   ## select vendor's native compilers with mvapich
# env.sh 1 0   ## select GNU/GCC compilers with openmpi
# env.sh ...

source ${PREFIX}/scripts/env.sh 7 1
#----------------------------------------------------------------------------
LOGDIR=${PREFIX}/log
WRF_LOG=${LOGDIR}/mpirun_${SARCH}_${HPC_COMPILER}_${HPC_MPI}_wrf-${WRF_VERSION}.log
mkdir -p ${LOGDIR}

ulimit -s unlimited
export MKL_NUM_THREADS=8
export OMP_NUM_THREADS=8
#export WRF_NUM_TILES=1

HPC_MPI_DEBUG=1
# load MPI settings
source ${PREFIX}/scripts/mpi_settings.sh

echo "Running WRF on $(date)"
cd ${JOB_DIR}
#ln -sfn ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/WRF-${WRF_VERSION}/run/{CAMtr_volume_mixing_ratio*,ozone*,RRTM*,*.TBL} .
#cp -anL ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/WRF-${WRF_VERSION}/run/* .
ln -sfn ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/WRF-${WRF_VERSION}/main/wrf.exe .

START_DATE=$(date)
echo "zzz *** ${START_DATE} *** - JobStart - $(basename ${JOB_DIR}) - ${HPC_COMPILER} - ${HPC_MPI}" >> ${WRF_LOG} 2>&1

mpirun ${MPI_SHOW_BIND_OPTS} ./wrf.exe >> ${WRF_LOG} 2>&1

END_DATE=$(date)
echo "zzz *** ${END_DATE} *** - JobEnd - $(basename ${JOB_DIR}) - ${HPC_COMPILER} - ${HPC_MPI}" >> ${WRF_LOG} 2>&1

JOB_FINISH_TIME=$(($(date -d "${END_DATE}" +%s)-$(date -d "${START_DATE}" +%s)))
echo "zzz *** $(date) *** - Job ${JOB_DIR} took ${JOB_FINISH_TIME} seconds($(echo "scale=2;${JOB_FINISH_TIME}/3600" | bc) hours)." >> ${WRF_LOG} 2>&1
