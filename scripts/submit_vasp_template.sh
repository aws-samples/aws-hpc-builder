#!/bin/bash


PREFIX=XXPREFIXXX
export VASP_VERSION=6.3.0
export JOB_DIR=${PREFIX}/spooler/${JOB_ID:-06-opt_blind6_22_exp}
#export JOB_DIR=${PREFIX}/spooler/07-opt_blind6_26_exp
#export JOB_DIR=${PREFIX}/spooler/08-opt_blind6_234_exp

#----------------------------------------------------------------------------

#ENV VARIABLES#

#------------------------------- Run-time env -------------------------------
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

source ${PREFIX}/scripts/env.sh 0 0

#----------------------------------------------------------------------------
LOGDIR=${PREFIX}/log
VASP_LOG=${LOGDIR}/mpiexec_${SARCH}_${HPC_COMPILER}_${HPC_MPI}_VASP-${VASP_VERSION}.log
mkdir -p ${LOGDIR}

ulimit -s unlimited
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=1
#export OMP_PLACES=cores
#export OMP_PROC_BIND=close

HPC_MPI_DEBUG=1
# load MPI settings
source ${PREFIX}/scripts/mpi_settings.sh

echo "Running VASP on $(date)"
cd ${JOB_DIR}
NPROCS=$(cat /sys/devices/system/cpu/cpu*/topology/thread_siblings_list | cut -d, -f1 | sort -u | wc -l)

START_DATE=$(date)
echo "zzz *** ${START_DATE} *** - JobStart - $(basename ${JOB_DIR}) - ${HPC_COMPILER} - ${HPC_MPI}" >> ${VASP_LOG} 2>&1

mpiexec -np ${NPROCS} --bind-to hwthread --map-by core ${MPI_SHOW_BIND_OPTS} ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/vasp.${VASP_VERSION}/bin/vasp_std >> ${VASP_LOG} 2>&1

END_DATE=$(date)
echo "zzz *** ${END_DATE} *** - JobEnd - $(basename ${JOB_DIR}) - ${HPC_COMPILER} - ${HPC_MPI}" >> ${VASP_LOG} 2>&1

JOB_FINISH_TIME=$(($(date -d "${END_DATE}" +%s)-$(date -d "${START_DATE}" +%s)))
echo "zzz *** $(date) *** - Job ${JOB_DIR} took ${JOB_FINISH_TIME} seconds($(echo "scale=5;${JOB_FINISH_TIME}/3600" | bc) hours)." >> ${VASP_LOG} 2>&1
