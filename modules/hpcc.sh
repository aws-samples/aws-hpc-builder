#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#HPCC_VERSION=git
HPCC_VERSION=${2:-1.5.0}
DISABLE_COMPILER_ENV=false

HPCC_SRC="hpcc-${HPCC_VERSION}.tar.gz"

install_sys_dependency_for_hpcc()
{
    # packages for build hpcc
    case ${S_VERSION_ID} in
	7)
	    return
	    case  "${S_NAME}" in
		"Alibaba Cloud Linux (Aliyun Linux)"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		    return
		    ;;
		"Amazon Linux")
		    return
		    ;;
	    esac
	    ;;
	8)
	    return
	    case  "${S_NAME}" in
		"Alibaba Cloud Linux"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		    return
		    ;;
		"Amazon Linux")
		    return
		    ;;
	    esac
	    ;;
	18|20)
	    return
	    ;;
	*)
	    exit 1
	    ;;
    esac
}

download_hpcc() {
    echo "zzz *** $(date) *** Downloading source code ${HPCC_SRC}"
    if [ "${HPCC_VERSION}" == "git" ]
    then
	git clone https://github.com/icl-utk-edu/hpcc.git
	return $?
    else
        if  [ -f ${HPCC_SRC} ]
       	then
            return
	else
	    curl --retry 3 -JLOk "https://hpcchallenge.org/projectsfiles/hpcc/download/hpcc-${HPCC_VERSION}.tar.gz"
	    #curl -JLOk "https://github.com/icl-utk-edu/hpcc/archive/refs/tags/${HPCC_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_hpcc()
{
    echo "zzz *** $(date) *** Build hpcc-${HPCC_VERSION}"
    if [ "${HPCC_VERSION}" == "git" ]
    then
	mv hpcc hpcc-${HPCC_VERSION}
    else
	sudo rm -rf ${HPCC_SRC%.tar.gz}
	tar xf ${HPCC_SRC}
    fi

    cd ${HPCC_SRC%.tar.gz}

    if [ -f ../../patch/hpcc/hpcc-${HPCC_VERSION}.patch ]
    then
	patch -Np1 < ../../patch/hpcc/hpcc-${HPCC_VERSION}.patch
    fi

    sed -e s"%^LAlib.*%LAlib        = ${HPC_LLIBS}%g" \
	-e s"%^LAinc.*%LAinc        = ${HPC_INCS}%g" \
	-e s"%^CCFLAGS      = $(HPL_DEFS).*%CCFLAGS      = \$(HPL_DEFS) ${HPC_CFLAGS}%g" \
	hpl/setup/Make.LinuxIntelIA64Itan2_eccMKL > hpl/Make.Linux

    make -j $(nproc) arch=Linux && \
	cd .. && \
	sudo mv "hpcc-${HPCC_VERSION}" "${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}" || exit 1
}

update_hpcc_version()
{
    MODULE_VERSION=${HPCC_VERSION}
}
