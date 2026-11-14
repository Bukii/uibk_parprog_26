#!/bin/bash
#SBATCH --job-name=mandelbrot-openmp
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --exclusive
#SBATCH --time=01:00:00
#SBATCH --output=benchmark-%j.out
#SBATCH --error=benchmark-%j.err

set -euo pipefail

SCRIPT_DIR="${SLURM_SUBMIT_DIR:-$PWD}"
if [[ ! -f "$SCRIPT_DIR/mandelbrot.c" &&
	-f "$SCRIPT_DIR/06/mandelbrot/mandelbrot.c" ]]; then
	SCRIPT_DIR="$SCRIPT_DIR/06/mandelbrot"
fi
if [[ ! -f "$SCRIPT_DIR/mandelbrot.c" ]]; then
	echo "mandelbrot.c not found; submit from 06/mandelbrot or repository root" >&2
	exit 1
fi
THREAD_COUNTS=(1 4 8 12)
SCHEDULES=(static dynamic guided auto runtime)
RUNS="${RUNS:-5}"
WARMUP="${WARMUP:-1}"
RUNTIME_SCHEDULE="${RUNTIME_SCHEDULE:-dynamic}"
raw_data=$(mktemp)
trap 'rm -f "$raw_data"' EXIT

if ! [[ "$RUNS" =~ ^[1-9][0-9]*$ && "$WARMUP" =~ ^[0-9]+$ ]]; then
	echo "RUNS must be positive and WARMUP must be non-negative" >&2
	exit 1
fi

cc -std=gnu11 -Wall -Wextra -Werror -fopenmp -O3 \
	"$SCRIPT_DIR/mandelbrot.c" -o "$SCRIPT_DIR/mandelbrot"

export OMP_PLACES=cores
export OMP_PROC_BIND=close
printf '# Mandelbrot OpenMP benchmark\n'
printf '# schedules=%s runs=%s warmup=%s\n' "${SCHEDULES[*]}" "$RUNS" "$WARMUP"
printf '# runtime uses OMP_SCHEDULE=%s\n' "$RUNTIME_SCHEDULE"
printf 'schedule,threads,run,runtime_seconds\n'

for schedule in "${SCHEDULES[@]}"; do
	if [[ "$schedule" == runtime ]]; then
		export OMP_SCHEDULE="$RUNTIME_SCHEDULE"
	else
		export OMP_SCHEDULE="$schedule"
	fi

	for threads in "${THREAD_COUNTS[@]}"; do
		for ((run = 1; run <= WARMUP; run++)); do
			srun --exclusive --cpu-bind=cores --ntasks=1 \
				--cpus-per-task="$threads" "$SCRIPT_DIR/mandelbrot" \
				"$threads" >/dev/null
		done

		for ((run = 1; run <= RUNS; run++)); do
			output=$(srun --exclusive --cpu-bind=cores --ntasks=1 \
				--cpus-per-task="$threads" "$SCRIPT_DIR/mandelbrot" \
				"$threads" 2>&1 >/dev/null)
			runtime=$(printf '%s\n' "$output" |
				awk '/^Mandelbrot calculation:/ { print $3; exit }')

			if [[ -z "$runtime" ]]; then
				echo "Could not read runtime for $schedule/$threads threads, run $run" >&2
				exit 1
			fi

			printf '%s,%s,%s,%s\n' "$schedule" "$threads" "$run" "$runtime" |
				tee -a "$raw_data"
		done
	done
done

printf '# Summary (mean, minimum, maximum)\n'
printf 'schedule,threads,mean_seconds,min_seconds,max_seconds\n'
awk -F, '
{
	key = $1 "," $2
	count[key]++
	sum[key] += $4
	if (count[key] == 1 || $4 < min[key]) min[key] = $4
	if (count[key] == 1 || $4 > max[key]) max[key] = $4
}
END {
	for (key in count) {
		split(key, fields, ",")
		printf "%s,%s,%.6f,%.6f,%.6f\n", fields[1], fields[2],
			sum[key] / count[key], min[key], max[key]
	}
}' "$raw_data" | sort -t, -n -k1,1
