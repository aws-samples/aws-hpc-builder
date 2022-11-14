#!/bin/bash

export VASP_VERSION=6.3.0
export JOB_DIR=/fsx/spooler/${JOB_ID:-06-opt_blind6_22_exp}
#export JOB_DIR=/fsx/spooler/07-opt_blind6_26_exp
#export JOB_DIR=/fsx/spooler/08-opt_blind6_234_exp

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

ulimit -s unlimited
export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=1
#export OMP_PLACES=cores
#export OMP_PROC_BIND=close

#Report bindings
#    Intel MPI: -print-rank-map
#    MVAPICH2: MV2_SHOW_CPU_BINDING=1
#    OpenMPI: --report-bindings

if [ "${HPC_COMPILER}" == "icc" ]
then
    SHOW_BIND_OPTS="-print-rank-map"
else
    SHOW_BIND_OPTS="--report-bindings"
fi

echo "Running VASP on $(date)"
cd ${JOB_DIR}
NPROCS=$(cat /sys/devices/system/cpu/cpu*/topology/thread_siblings_list | cut -d, -f1 | sort -u | wc -l)

START_DATE=$(date)
echo "${START_DATE} - JobStart - $(basename ${JOB_DIR}) - ${HPC_COMPILER}" >> vasp_$(uname -m).time

mpiexec -np ${NPROCS} --bind-to hwthread --map-by core ${SHOW_BIND_OPTS} ${HPC_PREFIX}/${HPC_COMPILER}/vasp.${VASP_VERSION}/bin/vasp_std >> mpiexe_${SARCH}_${HPC_COMPILER}.log 2>&1

END_DATE=$(date)
echo "${END_DATE} - JobEnd - $(basename ${JOB_DIR}) - ${HPC_COMPILER}" >> vasp_$(uname -m).time

JOB_FINISH_TIME=$(($(date -d "${END_DATE}" +%s)-$(date -d "${START_DATE}" +%s)))
echo "$(date) - Job ${JOB_DIR} took ${JOB_FINISH_TIME} seconds($(echo "scale=5;${JOB_FINISH_TIME}/3600" | bc) hours)." >> vasp_$(uname -m).time
