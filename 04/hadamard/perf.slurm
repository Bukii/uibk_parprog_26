#!/bash/bin

#SBATCH --output=perf.log
#SBATCH --exclusive

perf stat -e LLC-load-misses -e LLC-store-misses .hadamard