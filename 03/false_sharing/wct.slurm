#!/bin/bash

# Redirect output stream to this file
#SBATCH --output=./wct.log
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
# Enforce exclusive node allocation, do not share with other jobs
#SBATCH --exclusive

OMP_NUM_THREADS=2 srun ./false_sharing 100000000
OMP_NUM_THREADS=2 srun ./false_sharing_2 100000000

srun ./false_sharing 100000000
srun ./false_sharing_2 100000000