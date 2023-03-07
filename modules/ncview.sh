#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

NCVIEW_VERSION=${2:-2.1.8}
NCVIEW_SRC="ncview-${NCVIEW_VERSION}.tar.gz"
DISABLE_COMPILER_ENV=false

install_sys_dependency_for_ncview()
{
    case ${S_VERSION_ID} in
	7)
	    sudo yum -y update
	    case  "${S_NAME}" in
		"Alibaba Cloud Linux (Aliyun Linux)"|"Oracle Linux Server"|"Red Hat Enterprise Linux Server"|"CentOS Linux")
		    sudo yum -y install libXaw-devel udunits2-devel xorg-x11-fonts-ISO8859-14-75dpi xorg-x11-fonts-ISO8859-14-100dpi
		    ;;
		"Amazon Linux")
		    sudo yum -y install libXaw-devel udunits2-devel xorg-x11-fonts-ISO8859-14-75dpi xorg-x11-fonts-ISO8859-14-100dpi
		    ;;
	    esac
	    ;;
	8)
	    sudo $(dnf check-release-update 2>&1 | grep "dnf update --releasever" | tail -n1) -y 2> /dev/null
	    sudo dnf -y update
	    sudo dnf -y install libXaw-devel udunits2-devel xorg-x11-fonts-ISO8859-14-75dpi xorg-x11-fonts-ISO8859-14-100dpi
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
	    sudo apt-get -y update
	    sudo apt-get -y install libxaw7-dev libudunits2-dev xfonts-75dpi xfonts-100dpi
	    ;;
	*)
	    exit 1
	    ;;
    esac
}

download_ncview()
{
    if [ -f ${NCVIEW_SRC} ]
    then
        return
    else
	wget "ftp://cirrus.ucsd.edu/pub/ncview/ncview-${NCVIEW_VERSION}.tar.gz" -O ${NCVIEW_SRC}
	return $?
    fi
}

install_ncview()
{
    echo "zzz *** $(date) *** Build ${NCVIEW_SRC%.tar.gz}"
    sudo rm -rf "${NCVIEW_SRC%.tar.gz}"
    tar xf "${NCVIEW_SRC}"
    cd "${NCVIEW_SRC%.tar.gz}"
    export PREFIX=${HPC_PREFIX}/${HPC_COMPILER}/${HPC_MPI}
    ./configure \
	--prefix=${PREFIX} \
	--with-udunits2_incdir=/usr/include/udunits2
	
    make
    sudo --preserve-env=PATH,LD_LIBRARY_PATH,CC,CXX,F77,FC,AR,RANLIB,PREFIX make install && \
	cd ..
}

update_ncview_version()
{
    MODULE_VERSION=${NCVIEW_VERSION}
}
