#include <omp.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "../../03/mandelbrot/stb_image_write.h"

#define X 1280
#define Y 720
#define MAX_ITER 10000

static void calc_mandelbrot(uint8_t image[Y][X]) {
	#pragma omp parallel for schedule(runtime) default(none) shared(image)
	for (int y_pixel = 0; y_pixel < Y; y_pixel++) {
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

			image[y_pixel][x_pixel] =
				(uint8_t)(iteration * 255 / MAX_ITER);
		}
	}
}

int main(int argc, char *argv[]) {
	if (argc > 2) {
		fprintf(stderr, "Usage: %s [thread-count]\n", argv[0]);
		return EXIT_FAILURE;
	}

	if (argc == 2) {
		char *endptr;
		const long thread_count = strtol(argv[1], &endptr, 10);

		if (*argv[1] == '\0' || *endptr != '\0' || thread_count <= 0 ||
		    thread_count > Y) {
			fprintf(stderr, "Thread count must be an integer between 1 and %d\n",
				Y);
			return EXIT_FAILURE;
		}

		omp_set_num_threads((int)thread_count);
	}

	uint8_t image[Y][X];
	const double start = omp_get_wtime();
	calc_mandelbrot(image);
	const double elapsed = omp_get_wtime() - start;

	fprintf(stderr, "Mandelbrot calculation: %.3f s\n", elapsed);

	const int channel_nr = 1;
	const int stride_bytes = 0;
	if (!stbi_write_png("mandelbrot.png", X, Y, channel_nr, image,
			    stride_bytes)) {
		fprintf(stderr, "Failed to write mandelbrot.png\n");
		return EXIT_FAILURE;
	}

	return EXIT_SUCCESS;
}
