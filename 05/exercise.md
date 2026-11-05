# Assignment 05

## Exercise 1

*<span style="color: green;">
What does the code do on a high-level perspective?
</span>*

The program starts two OpenMP threads. The first thread write data = 42 and sets flag to 1. The second thread repeatedly checks flag until it becomes 1, then prints flag and data.

Classic producer/consumer procedure.

*<span style="color: green;">
What can you observe when running this program?
</span>*

When compiled with `-O3`, the program consistently gets stuck in the
second thread's loop. In three separate exclusive Slurm jobs, all three
sets of 1000 executions timed out (`correct=0 hung=0 other=1000`), so no
output was printed. The compiler may keep `flag` in a register because
the program has a data race, meaning that the update made by the first
thread is not guaranteed to become visible to the second thread. This is
undefined behavior; the expected `flag=1 data=42` output is not
guaranteed.


*<span style="color: green;">
Does this code require any #pragma omp flush directives?
</span>*

Yes, because there's a potential data race. No guarentee about when thread 1 sees the new value. It could be that the `flag` is stored in a register. This could mean, that the loop never terminates. Same applies to data.

Thread 1 could possibly observe an old or indeterminate value at the point of reading `data`.

`#pragma omp flush`ensures that the data object is directly read from main memory.
It does the following:

- **Before the flush**: makes that thread’s prior shared-memory writes visible to other threads.
- **After the flush**: makes the thread reread shared values rather than relying on stale cached/register values.

Updated code:
```cs
#include <omp.h>
#include <stdio.h>

int main(void) {
    int data;
    int flag = 0;

    #pragma omp parallel num_threads(2)
    {
        if (omp_get_thread_num() == 0) {
            data = 42;

            #pragma omp flush
            flag = 1;

            #pragma omp flush
        } else {
            int flag_val = 0;

            while (flag_val < 1) {
                #pragma omp flush
                flag_val = flag;
            }

            #pragma omp flush
            printf("flag=%d data=%d\n", flag_val, data);
        }
    }

    return 0;
}
```

The atomic operations provide the required synchronization more explicitly and avoid relying on the older, easy-to-misuse flush mechanism

```cs
#pragma omp atomic write
flag = 1;
```
and
```cs
#pragma omp atomic read
flag_val = flag;
```

## Exercise 2

*<span style="color: green;">
For each example that already contains a pragma, investigate whether it is parallelized correctly or whether there are any compiler or runtime issues. If there are any, fix them while keeping the parallelism.
</span>*

1. **not correct**: every iteration is dependent on the one before

Corrected version:

```c
a[0] = 0;
#pragma omp parallel for
for (i = 1; i < N; i++) {
    a[i] = 2.0 * i * (i - 1);
}

#pragma omp parallel for
for (i = 1; i < N; i++) {
    b[i] = a[i] - a[i - 1];
}
```

The implicit barrier at the end of the first `parallel for` ensures that all
elements of `a` have been written before the second loop reads them. If this
is placed in one `parallel` region, an explicit barrier is needed between the
two `for` constructs.

2.  **not correct**: race because of `nowait`. The first worksharing loop
can finish on one thread while another thread has already entered the second
loop and reads elements of `a` that have not yet been written. Removing
`nowait` fixes it, because the first `omp for` then has its normal implicit
barrier:

```c
a[0] = 0;
#pragma omp parallel
{
    #pragma omp for
    for (i = 1; i < N; i++) {
        a[i] = 3.0 * i * (i + 1);
    }
    #pragma omp for
    for (i = 1; i < N; i++) {
        b[i] = a[i] - a[i - 1];
    }
}
```

Alternatively, use an explicit `#pragma omp barrier`.

3. **not valid**: with `default(none)` unless all variables whose
data-sharing attributes are not predetermined are listed explicitly. `a`, `b`
and `N` should be shared, while `x` must not be shared because every iteration
assigns and uses it independently. 
`default(none)` forces you to explicitely define the data-sharing attr. for each variable that is declared outside the scope.

Declaring `x` inside the loop is a particularly clear solution:

```c
#pragma omp parallel for default(none) shared(a, b, N)
for (i = 0; i < N; i++) {
    double x = sqrt(b[i]) - 1;
    a[i] = x * x + 2 * x + 1;
}
```

4. **two problems**: 
    - `private(f)` creates uninitialized private copies, so the expression `f * b[i]` uses an uninitialized value
    - a private `x` is not available as a meaningful value after the parallel loop; the original `x` is not updated by the threads. 
    
If the final assignment is intended to use the value from the lexically last loop iteration, `lastprivate(x)` expresses that:

```c
f = 2;
#pragma omp parallel for shared(f) lastprivate(x)
for (i = 0; i < N; i++) {
    x = f * b[i];
    a[i] = x - 7;
}
a[0] = x;
```

`lastprivate` makes `x` private during the loop and copies the value from
iteration `N - 1` back to the original `x` after the implicit loop barrier.

5. **data race**: multiple threads read, modify and write `sum` concurrently, so updates can be lost. 

The usual solution is a reduction:

```c
sum = 0;
#pragma omp parallel for reduction(+:sum)
for (i = 0; i < N; i++) {
    sum += b[i];
}
```

Here, `+` is the reduction operator: OpenMP combines the threads partial sums using addition. The `:` separates the operator from the variable being reduced, `sum`.

OpenMP creates a private partial sum for each thread and combines the partial
sums at the end. An `atomic` update or a `critical` section also produces a
correct result, but synchronizes every update and is normally slower. A
manually allocated per-thread array followed by a sequential combination is
another option when more control over the partial results is needed.

6. **invalid**: The outer `omp for` is already a worksharing construct, but the inner `omp for` is encountered only by the thread that received the current outer iteration. A worksharing construct must be encountered by all threads in its team, and worksharing regions may not be nested this way. Compilers can reject the nesting, and a runtime hang is possible.

Both dimensions can be distributed with one collapsed loop:

```c
#pragma omp parallel for collapse(2)
for (i = 0; i < N; i++) {
    for (j = 0; j < N; j++) {
        a[i][j] = b[i][j];
    }
}
```

`collapse(2)` combines the two perfectly nested loops into one iteration
space. It preserves parallelism without requiring nested parallel regions.

*<span style="color: green;">
For each example not already containing a pragma, investigate how to parallelize it correctly.
</span>*

The first and fifth examples are the examples that require adding or changing
parallelization. 

- The first is parallelized by separating the independent calculation of `a` from the dependent read of `a` used to calculate `b`, as shown above. 
- The fifth uses `reduction(+:sum)`, which is the OpenMP construct specifically intended for this pattern. 

*<span style="color: green;">
Are there multiple solutions and if so, what are their advantages and disadvantages?
</span>*

### Advantages

- Split loops with an implicit or explicit barrier: loop-carried dependency
  removed, all `a` values available before calculating `b`
- Local variables, `private`, and `lastprivate`: no races for temporaries,
  explicit ownership, optional access to the final iteration value
- `reduction`, per-thread partial sums, and `collapse(2)`: correct sum
  aggregation, scalable updates, balanced 2D iteration distribution

### Disadvantages

- Split loops and barriers: extra pass over `a`, synchronization overhead;
  genuine dependencies may still require a sequential scan or prefix scan
- `atomic` and `critical`: synchronization on every update, contention, and
  worse scalability than a reduction
- Per-thread arrays, `collapse(2)`, and nested alternatives: extra code or
  storage, possible load imbalance for irregular rows, thread-management
  overhead