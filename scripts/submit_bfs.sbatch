#!/bin/bash
# Copyright # Copyright (C) 2023 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.
# SPDX-License-Identifier: MIT

#SBATCH --wait-all-nodes=1
#SBATCH --ntasks-per-node=64
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-core=1
#SBATCH --export=ALL
#SBATCH --exclusive
#SBATCH -o /fsx/log/bfs.out

#--------------------------- customized Job env -----------------------------
#SBATCH --nodes=2
#SBATCH --partition=c6g

export BFS_VERSION=3.0.1

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
source ${PREFIX}/scripts/env.sh 1 0
#----------------------------------------------------------------------------
LOGDIR=${PREFIX}/log
BFS_LOG=${LOGDIR}/mpirun_${SARCH}_${HPC_COMPILER}_${HPC_MPI}_bfs-${BFS_VERSION}.log
mkdir -p ${LOGDIR}

ulimit -s unlimited

HPC_MPI_DEBUG=1
# load MPI settings
source ${PREFIX}/scripts/mpi_settings.sh

echo "Running bfs on $(date)"

# greatly speed up BFS running
export SKIP_VALIDATION=1

# save graph file - ref: https://github.com/graph500/graph500
# TMPFILE=<filename> and also REUSEFILE=1 to keep the file.
# REUSEFILE=1
# TMPFILE=/fsx/spooler/bfs/graph29-2

START_DATE=$(date)
echo "zzz *** ${START_DATE} *** - JobStart - bfs - ${HPC_COMPILER} - ${HPC_MPI}" >> ${BFS_LOG} 2>&1

#export OMPI_MCA_coll_tuned_use_dynamic_rules=1
##export OMPI_MCA_coll_tuned_bcast_algorithm=1
mpirun ${MPI_SHOW_BIND_OPTS} graph500_reference_bfs 29 >> ${BFS_LOG} 2>&1

END_DATE=$(date)
echo "zzz *** ${END_DATE} *** - JobEnd - bfs - ${HPC_COMPILER} - ${HPC_MPI}" >> ${BFS_LOG} 2>&1

JOB_FINISH_TIME=$(($(date -d "${END_DATE}" +%s)-$(date -d "${START_DATE}" +%s)))
echo "zzz *** $(date) *** - Job bfs took ${JOB_FINISH_TIME} seconds($(echo "scale=5;${JOB_FINISH_TIME}/3600" | bc) hours)." >> ${BFS_LOG} 2>&1
