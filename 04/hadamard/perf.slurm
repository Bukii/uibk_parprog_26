#!/bin/bash

#SBATCH --output=perf.log
#SBATCH --exclusive

perf stat \
	-e L1-dcache-loads \
	-e L1-dcache-load-misses \
	-e L1-dcache-stores \
	-e L1-dcache-store-misses \
	-e LLC-load-misses \
	-e LLC-store-misses \
	./hadamard 1024 row

perf stat \
	-e L1-dcache-loads \
	-e L1-dcache-load-misses \
	-e L1-dcache-stores \
	-e L1-dcache-store-misses \
	-e LLC-load-misses \
	-e LLC-store-misses \
	./hadamard 1024 column