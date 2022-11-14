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
netcdf-c
netcdf-fortran
openmpi
osu
pnetcdf
vasp
wps
wrf
```

List installed modules

```
$ ./hpc_build.sh -p /fsx -L
clang-compiler-3.2.0
clang-openmpi-4.1.0
clang-osu-5.9
clang-osu-6.1
clang-hdf5-1.12.2
clang-pnetcdf-1.12.3
clang-netcdf-c-1.12.3
clang-netcdf-fortran-4.5.4
clang-wrf-4.2.2
icc-compiler-2022.2.0.262
```

Build application and its dependencies with vendor's compilers(ARM's gcc/g++/gfortran on aarch64, AMD's AOCC(clang/flang/ on amd64, Intel's OneAPI(icc/ipsc/ifort), i.e build WRF version 4.2.2.

```
$ ./hpc_build.sh -p /fsx -m wrf -M 4.2.2
```

Build application and its dependencies with GNU/gcc/g++/gfortran compilers

```
$ ./hpc_build.sh -p /fsx -g -m wrf -M 4.2.2
```
Build application and its dependencies with Intel compilers and Intel MPI, i.e build VASP 6.3.0 on AMD machine with Intel compilers and Intel MPI

```
$ ./hpc_build.sh -p /fsx -m vasp -M 6.3.0 -i -I
```

More options see:

```
$ ./hpc_build.sh -h
```


## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## Changes

New features released regularly, which you can read about in the [Change Log](CHANGELOG.md)

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

