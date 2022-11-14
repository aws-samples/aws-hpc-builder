#!/bin/bash
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.
# SPDX-License-Identifier: MIT

MCA_DEBUG=1

if [ ${MCA_DEBUG} -eq 1 ]
then
    export OMPI_MCA_pml_base_verbose=10
    export OMPI_MCA_mtl_base_verbose=10
    export OMPI_MCA_btl_base_verbose=10
fi

# EFA Detector
if (fi_info -p efa > /dev/null 2>&1)
then
    USE_EFA=1
else
    USE_EFA=0
fi

if [ ${USE_EFA} -eq 1 ]
then
    export FI_PROVIDER="efa"
    export FI_EFA_USE_DEVICE_RDMA=1
    export OMPI_MCA_pml=cm
    export OMPI_MCA_mtl=ofi
    #export OMPI_MCA_pml=ob1
    #export OMPI_MCA_btl=tcp,vader,self
else
    export OMPI_MCA_pml=ob1
    export OMPI_MCA_btl=tcp,vader,self
fi
