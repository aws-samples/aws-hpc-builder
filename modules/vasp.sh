#!/bin/sh

VASP_VERSION=${2:-6.3.0}
VASP_SRC=vasp.${VASP_VERSION}.tgz
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_vasp()
{
    # packages for build vasp
    if [ ${VERSION_ID} -eq 2 ]
    then
        sudo yum -y update
        sudo yum -y install rsync
    elif [ ${VERSION_ID} -eq 2022 ]
    then
        sudo $(dnf check-release-update 2>&1 | grep "dnf update --releasever" | tail -n1) -y 2> /dev/null
        sudo dnf -y update
        sudo dnf -y install rsync
    else
        exit 1
    fi
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
