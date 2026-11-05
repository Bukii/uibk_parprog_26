#!/bin/bash
#SBATCH --job-name=omp-flush-experiment
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --exclusive
#SBATCH --time=00:10:00
#SBATCH --output=run_experiment.out
#SBATCH --error=run_experiment.err

set -u

for batch in 1 2 3; do
    correct=0
    hung=0
    other=0

    for i in $(seq 1 1000); do
        output=$(timeout 0.1s ./ex1 2>/dev/null)
        status=$?

        if [ "$status" -eq 0 ] && [ "$output" = "flag=1 data=42" ]; then
            correct=$((correct + 1))
        elif [ "$status" -eq 124 ]; then
            hung=$((hung + 1))
        else
            other=$((other + 1))
        fi
    done

    printf 'batch %d: correct=%d hung=%d other=%d\n' \
        "$batch" "$correct" "$hung" "$other"
done
