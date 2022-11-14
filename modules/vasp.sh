#!/bin/sh

VASP_VERSION=${2:-6.3.0}
VASP_SRC=vasp.${VASP_VERSION}.tgz
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_vasp()
{
    return
}

download_vasp()
{
    if [ -f ${VASP_SRC} ]
    then
        return
    else
        echo "Please put ${VASP_SRC} to $(pwd) and run the installation again" >&2 
        exit 1
    fi
}

install_vasp()
{
    rm -rf ${VASP_SRC%.tgz}
    tar xf ${VASP_SRC}
    cd ${VASP_SRC%.tgz}
    cp ../../patch/vasp/makefile.include.${SARCH}.${HPC_COMPILER} makefile.include
    make && cd .. && sudo mv "${VASP_SRC%.tgz}" "${HPC_PREFIX}/${HPC_COMPILER}/"
}

update_vasp_version()
{
    MODULE_VERSION=${VASP_VERSION}
}
