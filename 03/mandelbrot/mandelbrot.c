#include <stdint.h>
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

// mandelbrot formula: z_{n+1} = z_n^2 + c
void calc_mandelbrot(uint8_t image[Y][X]) {
	for (int y_pixel = 0; y_pixel < Y; y_pixel++) {
		const double cy = -1.0 + 2.0 * y_pixel / Y;

		for (int x_pixel = 0; x_pixel < X; x_pixel++) {
			// Map pixel coordinates to complex plane
			// -2.5 to 1.0 with a width of 3.5 and -1.0 to 1.0 with a height of 2.0
			const double cx = -2.5 + 3.5 * x_pixel / X;
			double x = 0.0;
			double y = 0.0;
			int iteration = 0;

			// compute next value of z until it escapes or reaches the maximum number of iterations
			while (x * x + y * y <= 4.0 && iteration < MAX_ITER) {
				const double x_tmp = x * x - y * y + cx;
				y = 2.0 * x * y + cy;
				x = x_tmp;
				iteration++;
			}

			// Map the number of iterations to a grayscale value (0-255)
			image[y_pixel][x_pixel] =
				(uint8_t)(iteration * 255 / MAX_ITER);
		}
	}
}

int main() {
	uint8_t image[Y][X];

	struct timespec start, end;
	clock_gettime(CLOCK_MONOTONIC, &start);
	calc_mandelbrot(image);
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