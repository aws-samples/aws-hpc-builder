#!/bin/bash
# Copyright # Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.
# SPDX-License-Identifier: MIT

#SBATCH --wait-all-nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-core=1
#SBATCH --export=ALL
#SBATCH --exclusive
#SBATCH -o /fsx/log/osu.out

#--------------------------- customized Job env -----------------------------
#SBATCH --nodes=2
#SBATCH --partition=c6g

export OSU_VERSION=6.1

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
# 0 openmpi # 1 mpich
# 2 intelmpi
#
# usage: env.sh <compiler> <MPI>
#        C M
# env.sh 0 0   ## select vendor's native compilers with openmpi
# env.sh 0 1   ## select vendor's native compilers with mpich
# env.sh 0 2   ## select vendor's native compilers with intelmpi
# env.sh 1 0   ## select GNU/GCC compilers with openmpi
# env.sh ...

PREFIX=/fsx
source ${PREFIX}/scripts/env.sh 1 0
#----------------------------------------------------------------------------
LOGDIR=${PREFIX}/log
OSU_LOG=${LOGDIR}/mpirun_${SARCH}_${HPC_COMPILER}_${HPC_MPI}_OSU-${OSU_VERSION}.log
mkdir -p ${LOGDIR}

# detect EFA support
source ${PREFIX}/scripts/detect_efa.sh

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

echo "Running osu on $(date)"

START_DATE=$(date)
echo "zzz *** ${START_DATE} *** - JobStart - osu - ${HPC_COMPILER} - ${HPC_MPI}" >> ${OSU_LOG} 2>&1

#export OMPI_MCA_coll_tuned_use_dynamic_rules=1
##export OMPI_MCA_coll_tuned_bcast_algorithm=1
mpirun ${SHOW_BIND_OPTS} ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/${OSU_VERSION}/c/mpi/pt2pt/osu_latency >> ${OSU_LOG} 2>&1
#mpirun ${SHOW_BIND_OPTS} ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/${OSU_VERSION}/c/mpi/pt2pt/osu_bcast >> ${OSU_LOG} 2>&1
#mpirun ${SHOW_BIND_OPTS} ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/${OSU_VERSION}/c/mpi/pt2pt/osu_scatter >> ${OSU_LOG} 2>&1

END_DATE=$(date)
echo "zzz *** ${END_DATE} *** - JobEnd - osu - ${HPC_COMPILER} - ${HPC_MPI}" >> ${OSU_LOG} 2>&1

JOB_FINISH_TIME=$(($(date -d "${END_DATE}" +%s)-$(date -d "${START_DATE}" +%s)))
echo "zzz *** $(date) *** - Job osu took ${JOB_FINISH_TIME} seconds($(echo "scale=5;${JOB_FINISH_TIME}/3600" | bc) hours)." >> ${OSU_LOG} 2>&1
