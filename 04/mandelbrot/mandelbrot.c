#include <stdint.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// Include that allows to print result as an image
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

// Default size of image
#define X 1280
#define Y 720
#define MAX_ITER 10000

typedef struct {
	uint8_t (*image)[X];       // Shared output image
	int next_row;               // Next row that a thread may claim
	pthread_mutex_t mutex;      // Protects next_row from concurrent access
} work_queue;

// Worker function: each thread repeatedly claims and calculates one image row
void *calculate_rows(void *arg) {
	work_queue *queue = arg;

	while (1) {
		// Claiming a row must be atomic so two threads never calculate the
		// same row. The mutex is released before doing the expensive work
		pthread_mutex_lock(&queue->mutex);
		const int y_pixel = queue->next_row++;
		pthread_mutex_unlock(&queue->mutex);

		// There are no more rows. Every thread checks this after claiming one
		if (y_pixel >= Y)
			break;

		// From assignment 03
		// Nothing new here
		const double cy = -1.0 + 2.0 * y_pixel / Y;

		for (int x_pixel = 0; x_pixel < X; x_pixel++) {
			const double cx = -2.5 + 3.5 * x_pixel / X;
			double x = 0.0;
			double y = 0.0;
			int iteration = 0;

			while (x * x + y * y <= 4.0 && iteration < MAX_ITER) {
				const double x_tmp = x * x - y * y + cx;
				y = 2.0 * x * y + cy;
				x = x_tmp;
				iteration++;
			}

			queue->image[y_pixel][x_pixel] =
				(uint8_t)(iteration * 255 / MAX_ITER);
		}
	}

	return NULL;
}

int calc_mandelbrot(uint8_t image[Y][X], int thread_count) {
	// Store the thread handles so all workers can be joined before returning
	pthread_t *threads = calloc((size_t)thread_count, sizeof(*threads));
	if (threads == NULL)
		return -1;

	// All threads share the image and the row counter
	work_queue queue = {
		.image = image,
		.next_row = 0
	};

	// pthread_mutex_init(pointer to mutex, mutex attributes (NULL = default))
	if (pthread_mutex_init(&queue.mutex, NULL) != 0) {
		free(threads);
		return -1;
	}

	int created_threads = 0;
	int creation_failed = 0;
	// Start the requested number of workers. They share the row work queue
	for (; created_threads < thread_count; created_threads++) {
		// pthread_create(pointer to thread handle, thread attributes (NULL = default), function to run, argument to function)
		if (pthread_create(&threads[created_threads], NULL,
				   calculate_rows, &queue) != 0) {
			creation_failed = 1;
			break;
		}
	}

	// Wait until every started worker has finished calculating its assigned rows.
	for (int i = 0; i < created_threads; i++) {
		pthread_join(threads[i], NULL);
	}

	pthread_mutex_destroy(&queue.mutex);
	free(threads);
	return creation_failed ? -1 : 0;
}

int main(int argc, char *argv[]) {
	if (argc != 2) {
		fprintf(stderr, "Usage: %s <thread-count>\n", argv[0]);
		return EXIT_FAILURE;
	}

	char *endptr;
	const long parsed_thread_count = strtol(argv[1], &endptr, 10);
	if (*argv[1] == '\0' || *endptr != '\0' ||
	    parsed_thread_count <= 0 || parsed_thread_count > Y) {
		fprintf(stderr, "Thread count must be an integer between 1 and %d\n",
			Y);
		return EXIT_FAILURE;
	}

	uint8_t image[Y][X];
	const int thread_count = (int)parsed_thread_count;

	struct timespec start, end;
	clock_gettime(CLOCK_MONOTONIC, &start);
	if (calc_mandelbrot(image, thread_count) != 0) {
		fprintf(stderr, "Failed to calculate Mandelbrot image\n");
		return EXIT_FAILURE;
	}
	clock_gettime(CLOCK_MONOTONIC, &end);

	const double elapsed_ms =
		(end.tv_sec - start.tv_sec) * 1000.0 +
		(end.tv_nsec - start.tv_nsec) / 1000000.0;
	const double elapsed_s = elapsed_ms / 1000.0;
	fprintf(stderr, "Mandelbrot calculation: %.3f s\n", elapsed_s);

	const int channel_nr = 1, stride_bytes = 0;
	stbi_write_png("mandelbrot.png", X, Y, channel_nr, image, stride_bytes);
	return EXIT_SUCCESS;
}