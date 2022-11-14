# Changelog
## * Version 1.0 *
support Amazon Linux 2 for building any WRF version on aarch64
## * Version 2.0 *
add support on Intel and AMD compiler on both aarch64 and x86_64(intel)
## * Version 2.1 *
fix Intel compiler dependencies
## * Version 2.2 *
add WRF double precision patch
## * Version 2.3 *
remove duplicated build_openmpi
## * Version 3.0 *
support Amazon Linux 2022 by solving tirpc path issue
## * Version 3.1 *
add command line build option 
## * Version 3.2 *
support build all or just the WRF
## * Version 3.3 *
add install_ncl.txt and backport tirpc support to 3.x
## * Version 3.5 *
patch with FCOPTIM for fortran optimization
## * Version 3.6 *
provide patches for ALL WRF versions
## * Version 3.7 *
disable nproc for avoiding build error for some circumstances
## * Version 3.9 *
add -j WRF build info
## * Version 5.0 *
remove unset_compiler_env from WRF version greater than 4.2
## * Version 5.1 *
add vendor's compiler LIBRARY_PATH to LD_LIBRARY_PATH avoiding missing library from the compiler
## * Version 5.2 *
add Intel icc/ifort support for all versions
## * Version 5.3 *
enable Amazon EFA libfabric(OFI) support
## * Version 5.5 *
automatically detect and enable Amazon EFA libfabric(OFI)
## * Version 6.0 *
add Clang/ARMClang support, also add the ability to build the latest version GNU/GCC
## * Version 6.1 *
remove build/host/target from packages to support all compilers, like clang/armclang
## * Version 6.2 *
add armclang/clang openmpi support
## * Version 6.3 *
remove flags "-march=native" for armclang/clang
## * Version 6.5 *
upgrade ARM compiler to v22.1
## * Version 6.6 *
fix $(which <command>), because ARM's gcc machine name is aarch64-linux-gnu, but the prefix of nm, as and ranlib is aarch64-linux-gnu-gcc
## * Version 6.7 *
disable threads for the first stage of gcc compiling
## * Version 6.8 *
add --with-sysroot to avoid No such file or directory of crti.o -lt  

```
/fsx/wrf-x86_64/tmp/${WRF_COMPILER}/x86_64-bing-linux/bin/ld: cannot find crti.o: No such file or directory
/fsx/wrf-x86_64/tmp/${WRF_COMPILER}/x86_64-bing-linux/bin/ld: cannot find -lc: No such file or directory
/fsx/wrf-x86_64/tmp/${WRF_COMPILER}/x86_64-bing-linux/bin/ld: cannot find crtn.o: No such file or directory
```
## * Version 6.9 *
change netcdf-fortran compiler from mpicc/mpif90/mipf77 to no wrappered, Add F77 as it is required for nf_test
## * Version 7.0 *
add multiple compilers support on one platform, all new program are installed into ${WRF_PREFIX}/${WRF_COMPILER}
## * Version 7.1 *
add command line options parsing with getopts
## * Version 7.2 *
pre-set WRF_COMPILER before set_wrf_build_env and set_compiler_env
## * Version 7.3 *
acquires version # after the command line parsing
## * Version 7.5 *
update history changelog
## * Version 7.6 *
support parallel compiling and logging with different compilers
## * Version 7.7 *
change "mpicc -cc=$(SCC)" to "mpicc" for fixing openmpi build issue
## * Version 7.8 *
install env.sh and test.sh to /fsx/scripts, update test.sh to support command line option with compiler vendor
## * Version 7.9 *
Amazon Linux 2 system with gcc10 installed will causing clang missing -lstdc++ and -lquadmath
## * Version 8.0 *
add support for building WPS
## * Version 8.1 *
add large file support set WRFIO_NCD_LARGE_FILE_SUPPORT=1

```
wrf.exe: ../../libsrc/posixio.c:294: px_pgout: Assertion `*posp == OFF_NONE || *posp == lseek(nciop->fd, 0, SEEK_CUR)' failed.
Program received signal SIGABRT: Process abort signal.
Backtrace for this error:
0  0x400039b4785b in ???
 ...
14  0x400039b7c01b in nf_put_vara_real_
        at ../../fortran/nf_varaio.F90:372
```
## * Version 8.2 *
increase OMP_STACKSIZE to 128M to avoid segment fault for binary compiled by icc/ifort

[WRF Benchmark, Recommended RAM per core](https://mailman.ucar.edu/pipermail/wrf-users/2016/004429.html)

[Why Segmentation fault is happening in this openmp code?](https://stackoverflow.com/questions/13264274/why-segmentation-fault-is-happening-in-this-openmp-code)
## * Version 8.3 *
Add Intel compilers support on AMD platform
## * Version 9.0 *
Rename project from WRF Builder to HPC builder, standardizes and modularizes the build procedure, add osu support
## * Version 9.1 *
Support build VASP on Aarch64(with new module scalapack) and update Intel compiler to 2022.4, AMD compiler to 4.0.0
