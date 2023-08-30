#!/bin/python3
# SPDX-License-Identifier: MIT
# Copyright (C) 2023 by Amazon.com, Inc. or its affiliates.  All Rights Reserved.

import lief
import argparse

parser = argparse.ArgumentParser(description='This program fix AOCL could not find GLIBC_2.27 on Amazon Linux')
parser.add_argument('-p', '--prefix', type=str, help='prefix name(default: /fsx/amd64)', default='/fsx/amd64')
parser.add_argument('-a', '--aversion', type=str, help='aocl version', default='4.1.0')
args = parser.parse_args()

binary = lief.parse(args.prefix + '/opt/' + args.aversion + '/aocc/lib/libscalapack.so')

glibc_aux = None

for b in binary.imported_symbols:
    if b.name == 'printf':
        glibcsym = b
        break

glibc_aux = glibcsym.symbol_version.symbol_version_auxiliary

bin_aux = {}

funcs = ['expf', 'logf', 'powf']

for func in funcs:
    for i in binary.imported_symbols:
        if i.name == func:
            bin_aux[i.name] = i.symbol_version.symbol_version_auxiliary
            break

# 复制 GLIBC_X.X.X 记录 name 和 hash 至 expf, logf, powf 记录对应字段中。
if glibc_aux:
    for k in funcs:
        bin_aux[k].name = glibc_aux.name
        bin_aux[k].hash = glibc_aux.hash

binary.add_library('libm.so.6')  # 相当于 patchelf --add-needed libm.so.6
binary.write('libscalapack.so')
