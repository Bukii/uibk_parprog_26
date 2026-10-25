#!/bin/bash

# Redirect output stream to this file
#SBATCH --output=./output.log
# Enforce exclusive node allocation, do not share with other jobs
#SBATCH --exclusive

echo "Running 6 threads on 6 cores of the same processor"
echo "false sharing:"
OMP_NUM_THREADS=6 GOMP_CPU_AFFINITY=0,1,2,3,4,5 srun ./false_sharing 100000000
echo ""

echo "false sharing 2:"
OMP_NUM_THREADS=6 GOMP_CPU_AFFINITY=0,1,2,3,4,5 srun ./false_sharing_2 100000000
echo ""
echo ""

echo "Running 6 threads on 6 cores of different processor"
echo "false sharing:"
OMP_NUM_THREADS=6 GOMP_CPU_AFFINITY=0,1,2,6,7,8 srun ./false_sharing 100000000
echo ""

echo "false sharing 2:"
OMP_NUM_THREADS=6 GOMP_CPU_AFFINITY=0,1,2,6,7,8 srun ./false_sharing_2 100000000