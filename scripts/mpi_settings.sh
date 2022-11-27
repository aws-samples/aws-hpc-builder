#!/bin/bash
# Copyright (C) 2022 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.
# SPDX-License-Identifier: MIT

HPC_MPI_DEBUG=${HPC_MPI_DEBUG:-0}

hpc_enable_efa()
{
    #if [ ${USE_EFA} -eq 1 ]
    #then
    #export FI_PROVIDER="efa"
    #export FI_EFA_USE_DEVICE_RDMA=1
    #export OMPI_MCA_pml=ob1
    #export OMPI_MCA_btl=tcp,vader,self
    #else
    #export OMPI_MCA_pml=ob1
    #export OMPI_MCA_btl=tcp,vader,self
    #fi

    case ${HPC_MPI} in
	"intelmpi")
	    export I_MPI_FABRICS=ofi
	    export I_MPI_OFI_PROVIDER=efa
	    #export I_MPI_FABRICS="shm:ofi"
	    ###export FI_PROVIDER=efa
	    ;;
	"openmpi")
	    # more details see: ompi_info
	    export OMPI_MCA_mtl=ofi
	    export OMPI_MCA_pml=cm
	    export OMPI_MCA_mtl_ofi_provider_include=efa
	    ;;
	"mpich")
	    FI_PROVIDER=efa
	    ;;
	"mvapich")
	    FI_PROVIDER=efa
	    ;;
	*)
	    FI_PROVIDER=efa
    esac
}

hpc_set_mpi()
{
    case ${HPC_MPI} in
	"intelmpi")
	    continue
	    #export I_MPI_FABRICS=ofi
	    #export I_MPI_OFI_PROVIDER=tcp
	    ;;
	"openmpi")
	    # more details see: ompi_info
	    export OMPI_MCA_btl=tcp,vader,self
	    export OMPI_MCA_pml=ob1
	    ;;
	"mpich")
	    FI_PROVIDER=udp
	    ;;
	"mvapich")
	    FI_PROVIDER=udp
	    ;;
	*)
	    FI_PROVIDER=sockets
    esac
}

#Report bindings
#    Intel MPI: -print-rank-map
#    MVAPICH2: MV2_SHOW_CPU_BINDING=1
#    OpenMPI: --report-bindings
hpc_enable_mpi_debug()
{
    case ${HPC_MPI} in
	"intelmpi")
	    export I_MPI_DEBUG=5
	    MPI_SHOW_BIND_OPTS="-print-rank-map"
	    ;;
	"openmpi")
	    MPI_SHOW_BIND_OPTS="--report-bindings"
	    export OMPI_MCA_pml_base_verbose=10
	    export OMPI_MCA_mtl_base_verbose=10
	    export OMPI_MCA_btl_base_verbose=10
	    ;;
	"mpich")
	    # more details, see README.envvar
	    export MPIR_CVAR_DEBUG_SUMMARY=1
	    ;;
	"mvapich")
	    export MV2_SHOW_CPU_BINDING=1
	    ;;
	*)
	    continue
    esac
}

# EFA Detector
if (fi_info -p efa > /dev/null 2>&1)
then
    hpc_enable_efa
else
    hpc_set_mpi
fi

if [ ${HPC_MPI_DEBUG} -eq 1 ]
then
    hpc_enable_mpi_debug
fi
