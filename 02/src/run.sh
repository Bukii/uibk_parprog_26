#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 0 ]]; then
    printf 'Usage: %s\n' "$0" >&2
    exit 1
fi

thread_count=$(nproc --all)
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
logs_dir="$script_dir/logs"
mkdir -p -- "$logs_dir"
log_file="$logs_dir/benchmark.log"

{
    printf 'OpenMP benchmark results\n'
    printf 'Started: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    printf 'Threads per program: 1-%d\n\n' "$thread_count"
} > "$log_file"

mapfile -d '' programs < <(
    find "$script_dir" -maxdepth 1 -type f -perm -111 ! -name "$(basename -- "$0")" -print0 | sort -z
)

if [[ ${#programs[@]} -eq 0 ]]; then
    printf 'No executable programs found in %s\n' "$script_dir" >&2
    exit 1
fi

for program in "${programs[@]}"; do
    program_name=$(basename -- "$program")

    {
        printf '\n\n'
        printf '========================================\n'
        printf 'Benchmark: %s\n' "$program_name"
        printf 'Program:   %s\n' "$program"
        printf 'Threads:   1-%d\n' "$thread_count"
        printf 'Started:   %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
        printf '========================================\n\n'
        printf '+---------+------------+----------------+\n'
        printf '| Threads | Sum        | Time (seconds) |\n'
        printf '+---------+------------+----------------+\n'

        for ((threads = 1; threads <= thread_count; threads++)); do
            set +e
            result=$(cd -- "$script_dir" && OMP_NUM_THREADS="$threads" "$program" 2>&1)
            status=$?
            set -e

            if [[ $status -eq 0 && $result =~ ^sum:[[:space:]]*(-?[0-9]+),[[:space:]]time:[[:space:]]*([0-9]+\.[0-9]+)[[:space:]]seconds$ ]]; then
                printf '| %7d | %10d | %14s |\n' \
                    "$threads" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
            else
                printf '| %7d | program failed or unexpected output |\n' "$threads"
                printf '  Output: %s\n' "$result"
            fi
        done

        printf '+---------+------------+----------------+\n'
    } >> "$log_file"

    printf 'Logged %-12s -> %s\n' "$program_name" "$log_file"
done