## AWS HPC Builder - HPC Application Builder for Cloud

[![License](https://img.shields.io/badge/License-MIT--0-blue)](https://opensource.org/licenses/MIT-0)

AWS HPC Builder is a universal HPC application(which is called module for the builder) build and management system that make it easy for you to compile and deploy HPC applications on Amazon Linux 2 and Amazon Linux 2022, which support all major platforms that are Intel/AMD/Graviton. This tool compiles HPC applications(WRF, VASP etc.) and their dependencies with vendor compilers or GNU compilers. It standardizes and modularizes the build procedure across all supported platforms. 

## Quick Start

**IMPORTANT**: you will need root the **root permission or sudo** to use this tool compile and deploy HPC applications.

AWS HPC Builder can be used through a command line interface with options and parameters, it requires sudo(recommended) or root permission to build and install the applications. Run ./hpc_build.sh -h to see all available options and parameters.

List all available modules

```
$ ./hpc_build.sh -l
aocl
compiler
hdf5
mpich
netcdf-c
netcdf-fortran
openmpi
osu
pnetcdf
scalapack
vasp
wps
```

List installed modules

```
$ ./hpc_build.sh -p /data -L
icc-openmpi-compiler-2022.2.0.262
icx-openmpi-compiler-2022.2.0.262
icc-mpich-compiler-2022.2.0.262
icx-mpich-compiler-2022.2.0.262
icc-intelmpi-compiler-2022.2.0.262
icx-intelmpi-compiler-2022.2.0.262
icc-openmpi-openmpi-4.1.4
icc-openmpi-osu-6.1
```

Build application and its dependencies with vendor's compilers(ARM's gcc/g++/gfortran on aarch64, AMD's AOCC(clang/flang/ on amd64, Intel's OneAPI(icc/ipsc/ifort), i.e build WRF version 4.2.2.

```
$ ./hpc_build.sh -p /data -m wrf -M 4.2.2
```

Build application and its dependencies with GNU/gcc/g++/gfortran compilers

```
$ ./hpc_build.sh -p /data -c gcc -m wrf -M 4.2.2
```
Build application and its dependencies with Intel compilers and Intel MPI, i.e build VASP 6.3.0 on AMD machine with Intel compilers and Intel MPI

```
$ ./hpc_build.sh -p /fsx -m vasp -M 6.3.0 -i intelmpi
```

More options see:

```
$ ./hpc_build.sh -h
Usage: hpc_build.sh [-p PREFIX] [-c COMPILER] [-m MODULE] [-i MPI] [-M MOD_VERSION] [-l] [-L]
Description:
  -p PREFIX
     specify installation prefix(default /fsx)
  -c COMPILER
     specify HPC compilers(icc|icx|amdclang|armgcc|armclang|gcc|clang, default vendor's)
  -i MPI
     specify mpi(supported MPIs: openmpi|intelmpi|mpich, default=openmpi)
  -m MODULE
     specify module(default compiler)
  -M MODULE_VERSION
  -l
     list all available modules
     specify module version
  -L
     List installed modules
  -h
     display this page
```


## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## Changes

New features released regularly, which you can read about in the [Change Log](CHANGELOG.md)

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

