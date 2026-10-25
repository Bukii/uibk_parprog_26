#!/bin/bash

# Redirect output stream to this file
#SBATCH --output=./perf.log
# Enforce exclusive node allocation, do not share with other jobs
#SBATCH --exclusive

perf stat ./false_sharing 100000000

echo ""

perf stat ./false_sharing_2 100000000