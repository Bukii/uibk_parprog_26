# Assignment 02

## Exercise 1

NOTE: compiled with gcc version 11.4.0

First, get number of cores using `nproc --all`.
Then compile source code via 
```bash
gcc slow.c -o slow -fopenmp -Wall -Wextra -Werror -std=gnu11
```

### Benchmark Results

Execution times in seconds for each executable and thread count:

| Executable | 1 thread | 2 threads | 3 threads | 4 threads | 5 threads | 6 threads | 7 threads | 8 threads |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `fast_def` | 0.1800 | 0.0892 | 0.0662 | 0.0563 | 0.0387 | 0.0390 | 0.0490 | 0.0450 |
| `fast_o1` | 0.0255 | 0.0144 | 0.0099 | 0.0108 | 0.0108 | 0.0114 | 0.0129 | 0.0168 |
| `fast_o2` | 0.0000 | 0.0001 | 0.0001 | 0.0002 | 0.0003 | 0.0113 | 0.0151 | 0.0187 |
| `fast_o3` | 0.0000 | 0.0001 | 0.0001 | 0.0002 | 0.0003 | 0.0125 | 0.0174 | 0.0116 |
| `fast_ofast` | 0.0000 | 0.0001 | 0.0001 | 0.0001 | 0.0003 | 0.0002 | 0.0119 | 0.0183 |
| `medium_def` | 0.4658 | 1.9210 | 2.2552 | 2.5325 | 2.5778 | 2.4955 | 2.2278 | 2.3682 |
| `medium_o1` | 0.4306 | 2.3054 | 2.6165 | 1.4829 | 2.4716 | 2.5133 | 2.4032 | 2.7618 |
| `medium_o2` | 0.4186 | 2.4040 | 2.6447 | 2.7015 | 2.7725 | 2.8658 | 2.6058 | 2.7297 |
| `medium_o3` | 0.4316 | 2.1662 | 2.6469 | 2.7491 | 2.8053 | 2.7999 | 1.6592 | 1.4853 |
| `medium_ofast` | 0.4411 | 2.1786 | 2.7466 | 2.7772 | 2.7161 | 2.6670 | 2.8116 | 2.7363 |
| `slow_def` | 1.2115 | 2.0375 | 3.8816 | 4.9587 | 5.9374 | 6.3394 | 8.1172 | 8.3417 |
| `slow_o1` | 1.2360 | 1.9881 | 4.0863 | 5.2353 | 5.4210 | 6.9247 | 7.3945 | 7.3842 |
| `slow_o2` | 1.3066 | 2.5234 | 3.3492 | 5.4880 | 5.7278 | 6.5636 | 7.6952 | 6.7873 |
| `slow_o3` | 1.3334 | 2.4928 | 4.4225 | 5.1277 | 6.2370 | 6.3825 | 7.6058 | 8.2775 |
| `slow_ofast` | 1.1822 | 2.1493 | 3.6052 | 4.7457 | 5.2069 | 5.6745 | 6.9321 | 7.8694 |

**Q**: How stable are the measurements when running the experiments multiple times?

**A**: they vary significantly HOLY
