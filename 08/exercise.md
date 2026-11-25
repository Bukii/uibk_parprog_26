# Assignment 08

## Exercise 1

Signs of successful and unsuccessful vectorization:

- first loop (success):
    - `analysis.c:10:26: note:  LOOP VECTORIZED`
    - `analysis.c:10:26: optimized: loop vectorized using 16 byte vectors`
    - `analysis.c:10:26: note:  ***** Analysis succeeded with vector mode V4SI`
- second loop (fail):
    - `analysis.c:15:22: missed: not vectorized: more than one data ref in stmt: MEM <unsigned char[4096]> [(char * {ref-all})&b] = MEM <unsigned char[4096]> [(char * {ref-all})&a];`
- third loop (fail):
    - `analysis.c:19:24: missed: statement clobbers memory: __builtin_memmove (&a, _14, 4080);`
- fourth loop (fail due to data dependence):
    - `analysis.c:22:26: note:  ***** Analysis failed with vector mode V8QI`
    - `analysis.c:23:25: missed:   possible alias involving gather/scatter between a[_4] and a[i_47]`  
    `analysis.c:22:26: missed:  bad data dependence.`  
    `analysis.c:22:26: note:  ***** Analysis failed with vector mode V4QI`  
    `analysis.c:22:26: missed: couldn't vectorize loop`
- fifth loop (fail due to function calls):
    - `analysis.c:27:26: missed:  not vectorized: loop contains function calls or data references that cannot be analyzed`  
    `analysis.c:27:26: note:  ***** Analysis failed with vector mode VOID`  
    `analysis.c:27:26: note:  ***** The result for vector mode V16QI would be the same`  
    `analysis.c:27:26: note:  ***** The result for vector mode V8QI would be the same`  
    `analysis.c:27:26: note:  ***** The result for vector mode V4QI would be the same`  
    `analysis.c:27:26: missed: couldn't vectorize loop`  

Yes, the compiler also performs analysis beyond checking for dependencies and semantic correctness. The compiler also checks how to vectorize and whether it pays off:

- Loop shape and trip count: number of exits and iterations
- Alignment
- Cost model

## Exercise 2

### 1) Copy loop

```c
void copy(double* x, double* y) {
    for(int i = 0; i < 1024; i++) {
        x[i] = y[i];
    }
}
```

**Manually:** only if we know that `x` and `y` do not partially overlap.

**By the compiler:** not unconditionally. Looking only at this function, it cannot know whether the pointers alias.

- With `-O2 -ftree-parallelize-loops=4 -fdump-tree-parloops-details` the loop is not parallelized: `FAILED: data dependencies exist across iterations`.
- With `-O2 -ftree-vectorize` (and with `-O3`) it is still vectorized, but with a runtime check: `loop versioned for vectorization because of possible aliasing`.
- If we promise no aliasing with `double* restrict x, double* restrict y`, the compiler replaces the loop with a block copy (`split to 0 loops and 1 library calls`, in our object file a `rep movsq`).
- With `restrict` and additionally `-fno-tree-loop-distribute-patterns` (no block copy), it auto-parallelizes the loop: `parallelizing inner loop 1`.

### 2) Loop normalization

```c
for (int i=4; i<=N; i+=9) {
    for (int j=0; j<=N; j+=5) {
        A[i] = 0;
    }
}
```

Normalized loops start at 0 and have step 1. The old index variables are computed as `i = 9*ii + 4` and `j = 5*jj`:

```c
for (int ii = 0; ii < (N+5)/9; ii++) {
    for (int jj = 0; jj < (N+5)/5; jj++) {
        A[9*ii + 4] = 0;
    }
}
```

- Trip count of the outer loop: `floor((N-4)/9) + 1 = floor((N+5)/9)` for `N >= 4`, otherwise 0.
- Trip count of the inner loop: `floor(N/5) + 1 = floor((N+5)/5)` for `N >= 0`, otherwise 0.
- We use `(N+5)/9` instead of `(N-4)/9 + 1`, because C rounds integer division towards zero. The latter would wrongly execute one iteration for e.g. `N = 3`.
- We checked that the original and the normalized loops visit the same `(i, j)` pairs in the same order for all `N` from -50 to 1999.

Side note: `A[i]` does not depend on `j`, so the inner loop writes the same element repeatedly (output dependence carried by the inner loop, distance `(0, d)` with `d > 0`, direction `(=, <)`). The outer loop carries no dependence and could be parallelized.

### 3) 3D loop nest

```c
for(int i = 1; i < N; i++) {
    for(int j = 1; j < M; j++) {
        for(int k = 1; k < L; k++) {
            a[i+1][j][k-1] = a[i][j][k] + 5;
        }
    }
}
```

Yes, there is a dependency. The element written in iteration `(i, j, k)` is `a[i+1][j][k-1]`. It is read in iteration `(i', j', k')` if `i' = i+1`, `j' = j` and `k' = k-1`.

- Type: flow (true) dependence, since the write happens before the read (for `N >= 3` and `L >= 3`)
- Distance vector: `(1, 0, -1)`
- Direction vector: `(<, =, >)`

The dependence is carried by the outermost `i` loop (first non-`=` entry), so the `i` loop cannot be parallelized as it is. The `j` and `k` loops carry no dependence and can be parallelized. Since the direction for `j` is `=`, we can move the `j` loop to the outside, which gives coarser tasks and only one fork/join:

```c
#pragma omp parallel for
for(int j = 1; j < M; j++) {
    for(int i = 1; i < N; i++) {
        for(int k = 1; k < L; k++) {
            a[i+1][j][k-1] = a[i][j][k] + 5;
        }
    }
}
```

Interchanging `i` and `k` would not be legal, as the direction vector would become `(>, =, <)`.
