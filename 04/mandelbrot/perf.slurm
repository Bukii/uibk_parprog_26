#!/bin/bash

#SBATCH --output=perf2.log
#SBATCH --exclusive

set -euo pipefail

THREAD_COUNTS=(1 2 4 8 12)
RUNS="${RUNS:-5}"
WARMUP="${WARMUP:-1}"
raw_data=$(mktemp)
trap 'rm -f "$raw_data"' EXIT

if ! [[ "$RUNS" =~ ^[1-9][0-9]*$ && "$WARMUP" =~ ^[0-9]+$ ]]; then
	echo "RUNS and WARMUP must be non-negative integers; RUNS must be positive" >&2
	exit 1
fi

printf '# Mandelbrot performance measurements\n'
printf '# runs=%s warmup=%s\n' "$RUNS" "$WARMUP"
printf 'threads,run,runtime_seconds\n'

for threads in "${THREAD_COUNTS[@]}"; do
	for ((run = 1; run <= WARMUP; run++)); do
		./mandelbrot "$threads" >/dev/null
	done

	for ((run = 1; run <= RUNS; run++)); do
		output=$(./mandelbrot "$threads" 2>&1 >/dev/null)
		runtime=$(printf '%s\n' "$output" |
			awk '/^Mandelbrot calculation:/ { print $3; exit }')

		if [[ -z "$runtime" ]]; then
			echo "Could not read runtime for $threads threads, run $run" >&2
			exit 1
		fi

		printf '%s,%s,%s\n' "$threads" "$run" "$runtime" | tee -a "$raw_data"
	done
done

printf '# Summary (mean, minimum, maximum, standard deviation)\n'
printf 'threads,mean_seconds,min_seconds,max_seconds,stddev_seconds\n'
awk -F, '
{
	count[$1]++
	sum[$1] += $3
	if (count[$1] == 1 || $3 < min[$1]) min[$1] = $3
	if (count[$1] == 1 || $3 > max[$1]) max[$1] = $3
}
END {
	for (threads in count) {
		mean = sum[threads] / count[threads]
		sumsq = 0
		# Re-read the raw measurements to calculate standard deviation.
		while ((getline line < "'"$raw_data"'") > 0) {
			split(line, fields, ",")
			if (fields[1] == threads)
				sumsq += (fields[3] - mean) ^ 2
		}
		close("'"$raw_data"'")
		printf "%s,%.6f,%.6f,%.6f,%.6f\n", threads, mean, min[threads],
			max[threads], sqrt(sumsq / count[threads])
	}
}' "$raw_data" | sort -t, -n -k1,1