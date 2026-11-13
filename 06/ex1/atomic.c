#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <omp.h>

int main(void) {
    const long n = 700000000;
    long count = 0;
    double pi;
    double startTime, endTime;

    startTime = omp_get_wtime();

    // Keep a separate random-number seed for each thread.
    #pragma omp parallel
    {
        unsigned int seed = (unsigned int) time(NULL)^(unsigned int) (omp_get_thread_num() + 1);

        #pragma omp for
        for (long i = 0; i < n; i++) {
            double x = (double) rand_r(&seed) / RAND_MAX;
            double y = (double) rand_r(&seed) / RAND_MAX;

            if (x * x + y * y <= 1) {
                // Atomically increment the shared count without a critical section.
                #pragma omp atomic
                count++;
            }
        }
    }

    endTime = omp_get_wtime();

    pi = 4.0 * count / n;
    printf("Approximate value of pi: %f\n", pi);
    printf("time: %2.4f seconds\n", endTime - startTime);

    return 0;
}
