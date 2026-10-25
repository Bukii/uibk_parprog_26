#!/bin/bash

# Redirect output stream to this file
#SBATCH --output=./perf_cache.log
# Enforce exclusive node allocation, do not share with other jobs
#SBATCH --exclusive

perf stat -e LLC-load-misses -e LLC-store-misses ./false_sharing 100000000
perf stat -e LLC-load-misses -e LLC-store-misses ./false_sharing_2 100000000

echo ""

perf stat -e L1-dcache-load-misses -e L1-dcache-store-misses ./false_sharing 100000000
perf stat -e L1-dcache-load-misses -e L1-dcache-store-misses ./false_sharing_2 100000000