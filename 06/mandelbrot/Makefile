CFLAGS = -std=gnu11 -Wall -Wextra -Werror -fopenmp -O3

.PHONY: all
all: mandelbrot

.PHONY: clean
clean:
	$(RM) mandelbrot mandelbrot.png

mandelbrot: mandelbrot.c ../../03/mandelbrot/stb_image_write.h
	$(CC) $(CFLAGS) $< -o $@
