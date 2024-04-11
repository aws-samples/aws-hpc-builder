#!/bin/bash

MT_DEGMM_VERSION=${2:-1.0.0}
MT_DEGMM_SRC=mt-dgemm-${MT_DEGMM_VERSION}.tar.gz
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_mt_dgemm()
{
    return
}

download_mt_dgemm()
{
    echo "zzz *** $(date) *** Downloading source code ${MT_DEGMM_SRC}"
    if [ -f ${MT_DEGMM_SRC} ]
    then
        return
    else
         #curl --retry 3 -JLk https://www.lanl.gov/projects/crossroads/_assets/docs/micro/mtdgemm-crossroads-v${MT_DEGMM_VERSION}.tgz -o ${MT_DEGMM_SRC}
         curl --retry 3 -JLk http://phoronix-test-suite.com/benchmark-files/mtdgemm-crossroads-v${MT_DEGMM_VERSION}.tgz -o ${MT_DEGMM_SRC}
         return $?
    fi
}

install_mt_dgemm()
{
    rm -rf ${MT_DEGMM_SRC%.tar.gz}
    tar xf ${MT_DEGMM_SRC}
    mv mt-dgemm ${MT_DEGMM_SRC%.tar.gz}
    cd ${MT_DEGMM_SRC%.tar.gz}/src
    cp ../../../patch/mt-dgemm/Makefile.${HPC_COMPILER} .
    make -f Makefile.${HPC_COMPILER} && cd ../../ && sudo mv "${MT_DEGMM_SRC%.tar.gz}" "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}/"
}

update_mt_dgemm_version()
{
    MODULE_VERSION=${MT_DEGMM_VERSION}
}
