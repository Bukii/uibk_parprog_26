# Assignment 03

## Exercise 1

- Can you think of a way to parallelize this algorithm?
    - Each parsed row/column can take it's own thread
    - calculations doesn't depend on each other

## Exercise 2

- Open the two code versions in false_sharing/ and compare them. What are the differences in the source code and what are the implications?
    - `false_sharing_2.c` has a const named FACTOR
    - this factor is used to create a padding between thread counters
    - improving cache validity
- What does the execution time show, and why?
    - running on different processors is generally slower
    - false sharing 2, which improves cache coherence, is a lot faster

```bash
Running 6 threads on 6 cores of the same processor
false sharing:
Total sum: 600000000
Time taken: 0.311778 seconds

false sharing 2:
Total sum: 600000000
Time taken: 0.206857 seconds


Running 6 threads on 6 cores of different processor
false sharing:
Total sum: 600000000
Time taken: 0.390700 seconds

false sharing 2:
Total sum: 600000000
Time taken: 0.207196 seconds
```

- Analyze the cache behavior of the two programs using `perf`. Can you spot any significant differences in the measurements?
    - Clear performance difference
    - mainly caused by waiting instead of compute time
    - almost the same number of branches and instructions but huge difference in elapsed time and cycles

| Measurement | `false_sharing` | `false_sharing_2` |
|---|---:|---:|
| Elapsed time | 0.869 s | 0.243 s |
| Task-clock | 13.98 s | 5.69 s |
| Cycles | 40.54 billion | 16.44 billion |
| Instructions | 9.67 billion | 9.65 billion |
| Instructions per cycle | 0.24 | 0.59 |
| Backend stalls | 31.89% | 8.86% |
| Frontend stalls | 88.59% | 71.19% |
| Branches | 2.421 billion | 2.416 billion |

- Get more detailed information by specifically looking at cache events. Can you spot any significant differences?
    - significant differences in cache misses

| Cache event | `false_sharing` | `false_sharing_2` |
|---|---:|---:|
| LLC load misses | 2,017,628 | 833,258 |
| LLC store misses | 947,612 | 1,854,164 |
| L1 data-cache load misses | 25,977,501 | 1,457,988 |
| L1 data-cache store misses | 10,383,551 | 616,641 |
