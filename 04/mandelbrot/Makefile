CFLAGS = -std=gnu11 -Wall -Wextra -O3
LDLIBS = -lm -pthread

.PHONY: all
all: mandelbrot

.PHONY: clean
clean:
	$(RM) mandelbrot mandelbrot.png

mandelbrot: mandelbrot.c
