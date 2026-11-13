#!/bin/bash
#SBATCH --job-name=monte-carlo-pi
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --exclusive
#SBATCH --time=01:00:00
#SBATCH --output=benchmark-%j.out
#SBATCH --error=benchmark-%j.err

set -euo pipefail

# Build the implementations on the allocated compute node.
make clean all

# Bind OpenMP threads to separate cores and use the same thread counts as
# required by the exercise.
export OMP_PLACES=cores
export OMP_PROC_BIND=close

for threads in 1 4 8 12; do
    for implementation in critical atomic reduction; do
        printf '\n=== implementation=%s threads=%d ===\n' \
            "$implementation" "$threads"
        OMP_NUM_THREADS="$threads" \
            srun --exclusive --cpu-bind=cores --ntasks=1 \
                 --cpus-per-task="$threads" "./$implementation"
    done
done
