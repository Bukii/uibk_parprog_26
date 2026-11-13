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
