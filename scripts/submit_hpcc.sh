#!/bin/bash
# Copyright # Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.
# SPDX-License-Identifier: MIT

export HPCC_VERSION=1.5.0

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
source ${PREFIX}/scripts/env.sh 7 1
#----------------------------------------------------------------------------
LOGDIR=${PREFIX}/log
HPCC_LOG=${LOGDIR}/mpirun_${SARCH}_${HPC_COMPILER}_${HPC_MPI}_hpcc-${HPCC_VERSION}.log

mkdir -p ${LOGDIR}

JOBDIR=${PREFIX}/spooler/hpcc
mkdir -p ${JOBDIR}
cd ${JOBDIR}

#----------------------------------------------------------------------------
if [ "X$SLURM_JOB_NUM_NODES" = "X" ]
then
        SLURM_JOB_NUM_NODES=1
fi

if [ "X$MPI_NUM_THREADS" = "X" ]
then
        MPI_NUM_THREADS=$(($(nproc) * $SLURM_JOB_NUM_NODES))
fi

# HPL.dat generation
# http://pic.dhe.ibm.com/infocenter/lnxinfo/v3r0m0/index.jsp?topic=%2Fliaai.hpctune%2Fbaselinehpcc_gccatlas.htm
# https://netlib.org/benchmark/hpl_oldest/faqs.html

PQ=0
P=$(echo "scale=0;sqrt($MPI_NUM_THREADS)" |bc -l)
SYS_MEMORY_MB=$(free -m | grep ^Mem: | awk '{print $2}')
Q=$P
PQ=$(($P*$Q))

while [ $PQ -ne $MPI_NUM_THREADS ]; do
    Q=$(($MPI_NUM_THREADS/$P))
    PQ=$(($P*$Q))
    if [ $PQ -ne $MPI_NUM_THREADS ] && [ $P -gt 1 ]; then P=$(($P-1)); fi
done

if [ "X$N" = "X" ] || [ "X$NB" = "X" ]
then
        # SYS_MEMORY * about .62% of that, go from MB to bytes and divide by 8
        N=$(echo "scale=0;sqrt(${SYS_MEMORY_MB}*${SLURM_JOB_NUM_NODES}*0.62*1048576/8)" |bc -l)
        NB=$((256 - 256 % $MPI_NUM_THREADS))
        N=$(($N - $N % $NB))
fi

echo "HPLinpack benchmark input file
Innovative Computing Laboratory, University of Tennessee
HPL.out      output file name (if any)
6            device out (6=stdout,7=stderr,file)
1            # of problems sizes (N)
$N
1            # of NBs
$NB          NBs
0            PMAP process mapping (0=Row-,1=Column-major)
1            # of process grids (P x Q)
$P           Ps
$Q           Qs
16.0         threshold
1            # of panel fact
2            PFACTs (0=left, 1=Crout, 2=Right)
1            # of recursive stopping criterium
4            NBMINs (>= 1)
1            # of panels in recursion
2            NDIVs
1            # of recursive panel fact.
2            RFACTs (0=left, 1=Crout, 2=Right)
1            # of broadcast
1            BCASTs (0=1rg,1=1rM,2=2rg,3=2rM,4=Lng,5=LnM)
1            # of lookahead depth
0            DEPTHs (>=0)
1            SWAP (0=bin-exch,1=long,2=mix)
64           swapping threshold
0            L1 in (0=transposed,1=no-transposed) form
0            U  in (0=transposed,1=no-transposed) form
1            Equilibration (0=no,1=yes)
8            memory alignment in double (> 0)
##### This line (no. 32) is ignored (it serves as a separator). ######
0                               Number of additional problem sizes for PTRANS
1200 10000 30000                values of N
0                               number of additional blocking sizes for PTRANS
40 9 8 13 13 20 16 32 64        values of NB
" > HPL.dat
cp HPL.dat hpccinf.txt
#----------------------------------------------------------------------------

#ulimit -s unlimited
#export MKL_NUM_THREADS=1
export OMP_NUM_THREADS=1

HPC_MPI_DEBUG=1
# load MPI settings
source ${PREFIX}/scripts/mpi_settings.sh

echo "Running hpcc on $(date)"

START_DATE=$(date)
echo "zzz *** ${START_DATE} *** - JobStart - hpcc - ${HPC_COMPILER} - ${HPC_MPI}" >> ${HPCC_LOG} 2>&1

#export OMPI_MCA_coll_tuned_use_dynamic_rules=1
##export OMPI_MCA_coll_tuned_bcast_algorithm=1
ln -sfn ${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/hpcc-${HPCC_VERSION}/hpcc .
#srun ${MPI_SHOW_BIND_OPTS} --mpi=pmi2 ./hpcc >> ${HPCC_LOG} 2>&1
mpirun -n ${MPI_NUM_THREADS} ${MPI_SHOW_BIND_OPTS} ./hpcc >> ${HPCC_LOG} 2>&1
mv hpccoutf.txt hpccoutf_$(date +'%Y-%m-%d_%H-%M-%S').txt

END_DATE=$(date)
echo "zzz *** ${END_DATE} *** - JobEnd - hpcc - ${HPC_COMPILER} - ${HPC_MPI}" >> ${HPCC_LOG} 2>&1

JOB_FINISH_TIME=$(($(date -d "${END_DATE}" +%s)-$(date -d "${START_DATE}" +%s)))
echo "zzz *** $(date) *** - Job hpcc took ${JOB_FINISH_TIME} seconds($(echo "scale=5;${JOB_FINISH_TIME}/3600" | bc) hours)." >> ${HPCC_LOG} 2>&1
