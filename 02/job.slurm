#!/bin/bash

# Execute job in the partition "lva" unless you have special requirements.
#SBATCH --partition=lva
# Name your job to be able to identify it later
#SBATCH --job-name 02_cb761085
# Redirect output stream to this file
#SBATCH --output=./02/src/logs/output.log
# Request 1 node with 12 cores
#SBATCH --cpus-per-task=12
# Enforce exclusive node allocation, do not share with other jobs
#SBATCH --exclusive

OMP_NUM_THREADS=12 srun ./02/src/slow_Ofast