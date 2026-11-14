# Assignment 06

## Exercise 1

### *<span style="color: green;">What can you observe? How and why do these constructs differ?</span>*

The benchmark runs 700 million Monte Carlo samples for estimating pi. The
results are shown in [benchmark-410180.out](./benchmark-410180.out).

| Threads | `critical` | `atomic` | `reduction` |
|---:|---:|---:|---:|
| 1 | 16.4660 s | 14.1151 s | 10.3609 s |
| 4 | 76.4810 s | 11.9504 s | 2.7006 s |
| 8 | 142.7014 s | 16.7990 s | 1.3494 s |
| 12 | 164.3327 s | 22.5012 s | 0.9012 s |

#### Observations

- `critical` becomes much slower as more threads are added
- `atomic` is faster than `critical`, but does not scale well. It gets slower again beyond four threads
- `reduction` scales very well: its runtime decreases from 10.36 seconds with one thread to 0.90 seconds with twelve threads

#### Explanation

In *critical*, every successful sample enters an OpenMP critical section to increment the shared counter. Only one thread can perform this update at a time. Since most samples are successful, this results in hundreds of millions of lock acquisitions. Additional threads therefore mostly wait for the same lock, and lock contention makes the program slower.

Atomic updates are usually cheaper than entering and leaving a critical section, which explains the better performance. However, all threads still update the same memory location. The resulting contention and cache-coherence traffic limit scalability.

In reduction, each thread maintains a private counter while processing its part of the loop. OpenMP combines these counters only at the end of the parallel region. The loop therefore contains no synchronization on every iteration, so the reduction version has much lower overhead and achieves the best speedup.

## Exercise 2

### Findings

The Mandelbrot implementation was benchmarked with the `static` OpenMP
scheduling policy. Each configuration was run five times after one warmup run.
The measurements are available in
[benchmark-410185.out](./mandelbrot/benchmark-410185.out).

| Threads | Mean runtime | Minimum | Maximum | Speedup |
|---:|---:|---:|---:|---:|
| 1 | 9.8068 s | 9.804 s | 9.814 s | 1.00x |
| 4 | 4.1622 s | 4.155 s | 4.165 s | 2.36x |
| 8 | 2.5606 s | 2.559 s | 2.562 s | 3.83x |
| 12 | 1.7696 s | 1.769 s | 1.771 s | 5.54x |

Runtime decreases consistently with more threads, but scaling is sublinear: 12 threads achieve a 5.54x speedup instead of the ideal 12x. Thread and scheduling overhead, memory access, and uneven pixel workloads limit the speedup.

### Loop scheduling comparison

- `static` divides the iteration space into predetermined chunks.
    - very low scheduling overhead, but it cannot react to uneven work
- `dynamic` assigns another chunk to a thread whenever it becomes available
    - improving load balancing at the cost of more scheduling and synchronization overhead
- `guided` also assigns work dynamically, but starts with large chunks and gradually reduces their size.
    - usually reduces scheduling overhead
    - while retaining better balancing near the end of the loop
- `auto` leaves the scheduling decision to the OpenMP runtime.
    - behavior and performance are implementation-dependent
    - it may select a strategy similar to one of the explicit policies
- `runtime` is not an independent scheduling algorithm: it makes the loop use the policy selected by `OMP_SCHEDULE` at runtime. In the benchmark script, the `runtime` row uses `RUNTIME_SCHEDULE=dynamic` by default, which allows it to be compared with the explicit `dynamic` row.

For this Mandelbrot calculation, the work per row is uneven because points inside or near the set require many more iterations. Therefore, dynamic or guided scheduling may outperform static scheduling with several threads if the static row distribution leaves one thread with expensive rows. The benchmark results confirm this for `dynamic`, but not for `guided`:

| Schedule | 1 thread | 4 threads | 8 threads | 12 threads |
|---|---:|---:|---:|---:|
| `static` | 9.8256 s | 4.1568 s | 2.5600 s | 1.7720 s |
| `dynamic` | 9.8234 s | 2.5550 s | 1.2654 s | 0.8530 s |
| `guided` | 9.8160 s | 3.0426 s | 1.5570 s | 1.0312 s |
| `auto` | 9.8066 s | 2.5644 s | 1.2874 s | 0.8640 s |
| `runtime` | 9.8192 s | 2.5562 s | 1.2754 s | 0.8560 s |

The table shows mean runtimes from five runs. 

- With one thread, all policies are nearly identical
- With 12 threads, `dynamic` is fastest at 0.8530 seconds, about 2.1 times faster than `static`, because it balances the unequal row workloads
    - `guided` improves on `static` but remains slower than `dynamic`. 
    - `auto` behaves similarly to `dynamic` on this OpenMP runtime
    - `runtime` also matches `dynamic` because it was run with `OMP_SCHEDULE=dynamic`. 
    
Overall, dynamic scheduling gives the best performance for this Mandelbrot workload.