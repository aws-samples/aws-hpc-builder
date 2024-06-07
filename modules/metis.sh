#o!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2024 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

#METIS_VERSION=git
METIS_VERSION=${2:-5.1.0}
DISABLE_COMPILER_ENV=false

METIS_SRC="metis-${METIS_VERSION}.tar.gz"

install_sys_dependency_for_metis()
{
    # packages for build metis
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y install libtiff-devel
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
	    sudo dnf -y install libtiff-devel
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
	    sudo apt-get -y install libtiff-dev
	    return
	    ;;
	*)
	    exit 1
	    ;;
    esac
}

download_metis() {
    echo "zzz *** $(date) *** Downloading source code ${METIS_SRC}"
    if [ "${METIS_VERSION}" == "git" ]
    then
	git clone https://github.com/KarypisLab/METIS.git
	return $?
    else
        if  [ -f ${METIS_SRC} ]
       	then
            return
	else
	    #curl --retry 3 -JLOk "https://github.com/KarypisLab/METIS/archive/refs/tags/v${METIS_VERSION}.tar.gz"
	    curl --retry 3 -JLOk "http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-${METIS_VERSION}.tar.gz"
	    return $?
       	fi
    fi
}

install_metis()
{
    echo "zzz *** $(date) *** Build metis-${METIS_VERSION}"
    if [ "${METIS_VERSION}" == "git" ]
    then
	mv METIS METIS-${METIS_VERSION}
    else
	sudo rm -rf ${METIS_SRC%.tar.gz}
	tar xf ${METIS_SRC}
    fi

    cd ${METIS_SRC%.tar.gz}

    if [ -f ../../patch/metis/metis-${METIS_VERSION}.patch ]
    then
	patch -Np1 < ../../patch/metis/metis-${METIS_VERSION}.patch
    fi

    make config shared=1 prefix=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI} && \
	make && \
        sudo --preserve-env=PATH,LD_LIBRARY_PATH,I_MPI_CC,I_MPI_CXX,I_MPI_FC,I_MPI_F77,I_MPI_F90,CC,CXX,F77,FC,AR,RANLIB,FFLAGS,FCFLAGS env make install && \
       	cd .. && \
       	sudo rm -rf ${METIS_SRC%.tar.gz} || exit 1
}

update_metis_version()
{
    MODULE_VERSION=${METIS_VERSION}
}
