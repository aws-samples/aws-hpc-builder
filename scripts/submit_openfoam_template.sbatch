#!/bin/bash
# Copyright # Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.
# SPDX-License-Identifier: MIT

#SBATCH --wait-all-nodes=1
#SBATCH --ntasks=128
#SBATCH --ntasks-per-node=64
#SBATCH --cpus-per-task=1
#SBATCH --ntasks-per-core=1
#SBATCH --export=ALL
#SBATCH --exclusive
#SBATCH -o XXPREFIXXX/log/openfoam.out

#--------------------------- customized Job env -----------------------------
#SBATCH --nodes=2
#SBATCH --partition=c6gn

PREFIX=XXPREFIXXX

export OPENFOAM_VERSION=2212
export JOB_DIR=${PREFIX}/spooler/motorBikeDemoArm
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
source ${PREFIX}/scripts/openfoam_env.sh

#----------------------------------------------------------------------------
LOGDIR=${PREFIX}/log
OPENFOAM_LOG=${LOGDIR}/mpirun_${SARCH}_${HPC_COMPILER}_${HPC_MPI}_OpenFOAM-${OPENFOAM_VERSION}.log
mkdir -p ${LOGDIR}

ulimit -s unlimited

HPC_MPI_DEBUG=0
# load MPI settings
source ${PREFIX}/scripts/mpi_settings.sh

cd ${JOB_DIR}

echo "Running OpenFOAM on $(date)"

START_DATE=$(date)
echo "zzz *** ${START_DATE} *** - JobStart - $(basename ${JOB_DIR}) - ${HPC_COMPILER} - ${HPC_MPI}" >> ${OPENFOAM_LOG} 2>&1

cp ${FOAM_TUTORIALS}/resources/geometry/motorBike.obj.gz constant/triSurface/
surfaceFeatureExtract  > ./log/surfaceFeatureExtract.log 2>&1
blockMesh  > ./log/blockMesh.log 2>&1
decomposePar -decomposeParDict system/decomposeParDict.hierarchical  > ./log/decomposePar.log 2>&1

mpirun ${MPI_SHOW_BIND_OPTS} snappyHexMesh -parallel -overwrite -decomposeParDict system/decomposeParDict.hierarchical   > ./log/snappyHexMesh.log 2>&1
mpirun ${MPI_SHOW_BIND_OPTS} checkMesh -parallel -allGeometry -constant -allTopology -decomposeParDict system/decomposeParDict.hierarchical > ./log/checkMesh.log 2>&1
mpirun ${MPI_SHOW_BIND_OPTS} redistributePar -parallel -overwrite -decomposeParDict system/decomposeParDict.ptscotch > ./log/decomposePar2.log 2>&1
mpirun ${MPI_SHOW_BIND_OPTS} renumberMesh -parallel -overwrite -constant -decomposeParDict system/decomposeParDict.ptscotch > ./log/renumberMesh.log 2>&1
mpirun ${MPI_SHOW_BIND_OPTS} patchSummary -parallel -decomposeParDict system/decomposeParDict.ptscotch > ./log/patchSummary.log 2>&1

ls -d processor* | xargs -i rm -rf ./{}/0
ls -d processor* | xargs -i cp -r 0.orig ./{}/0
mpirun ${MPI_SHOW_BIND_OPTS} potentialFoam -parallel -noFunctionObjects -initialiseUBCs -decomposeParDict system/decomposeParDict.ptscotch > ./log/potentialFoam.log 2>&1s
mpirun ${MPI_SHOW_BIND_OPTS} simpleFoam -parallel  -decomposeParDict system/decomposeParDict.ptscotch > ./log/simpleFoam.log 2>&1

END_DATE=$(date)
echo "zzz *** ${END_DATE} *** - JobEnd - $(basename ${JOB_DIR}) - ${HPC_COMPILER} - ${HPC_MPI}" >> ${OPENFOAM_LOG} 2>&1

JOB_FINISH_TIME=$(($(date -d "${END_DATE}" +%s)-$(date -d "${START_DATE}" +%s)))
echo "zzz *** $(date) *** - Job ${JOB_DIR} took ${JOB_FINISH_TIME} seconds($(echo "scale=2;${JOB_FINISH_TIME}/3600" | bc) hours)." >> ${OPENFOAM_LOG} 2>&1
