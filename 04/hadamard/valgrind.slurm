#!/bin/bash

#SBATCH --output=valgrind.log
#SBATCH --exclusive

valgrind --tool=cachegrind --cache-sim=yes \
    --D1=32768,8,64 \
    --I1=32768,8,64 \
	--cachegrind-out-file=cachegrind.out.row.%p ./hadamard 1024 row

valgrind --tool=cachegrind --cache-sim=yes \
    --D1=32768,8,64 \
    --I1=32768,8,64 \
	--cachegrind-out-file=cachegrind.out.column.%p ./hadamard 1024 column