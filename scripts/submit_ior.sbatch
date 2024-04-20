#!/bin/bash
# Copyright # Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.
# SPDX-License-Identifier: MIT

#SBATCH --wait-all-nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-core=1
#SBATCH --constraint=c7g
#SBATCH --export=ALL
#SBATCH --exclusive
#SBATCH -o /fsx/log/ior.out

#--------------------------- customized Job env -----------------------------
#SBATCH --nodes=2
#SBATCH --partition=gxlarge

export IOR_VERSION=4.0.0rc1

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

PREFIX=/fsx
source ${PREFIX}/scripts/env.sh 6 0
#----------------------------------------------------------------------------
LOGDIR=${PREFIX}/log
IOR_LOG=${LOGDIR}/mpirun_${SARCH}_${HPC_COMPILER}_${HPC_MPI}_ior-${IOR_VERSION}.log

mkdir -p ${LOGDIR}

JOBDIR=${PREFIX}/spooler/ior
mkdir -p ${JOBDIR}
cd ${JOBDIR}

ulimit -s unlimited
#export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=1

HPC_MPI_DEBUG=1
# load MPI settings
source ${PREFIX}/scripts/mpi_settings.sh

echo "Running ior on $(date)"

START_DATE=$(date)
echo "zzz *** ${START_DATE} *** - JobStart - ior - ${HPC_COMPILER} - ${HPC_MPI}" >> ${IOR_LOG} 2>&1

#export OMPI_MCA_coll_tuned_use_dynamic_rules=1
##export OMPI_MCA_coll_tuned_bcast_algorithm=1
mpirun ${MPI_SHOW_BIND_OPTS} ior --posix.odirect -t 1m -b 16m -s 200 -F >> ${IOR_LOG} 2>&1

END_DATE=$(date)
echo "zzz *** ${END_DATE} *** - JobEnd - ior - ${HPC_COMPILER} - ${HPC_MPI}" >> ${IOR_LOG} 2>&1

JOB_FINISH_TIME=$(($(date -d "${END_DATE}" +%s)-$(date -d "${START_DATE}" +%s)))
echo "zzz *** $(date) *** - Job ior took ${JOB_FINISH_TIME} seconds($(echo "scale=5;${JOB_FINISH_TIME}/3600" | bc) hours)." >> ${IOR_LOG} 2>&1
