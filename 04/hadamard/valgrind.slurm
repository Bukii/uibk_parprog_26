#!/bash/bin

#SBATCH --output=valgrind.log
#SBATCH --exclusive

valgrind --tool=cachegrind ./hadamard