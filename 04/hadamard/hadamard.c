#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

// Traverse columns first
// cache-unfriendly version for row-major matrices
void hadamard_column_major(size_t n, const int32_t a[n][n],
	const int32_t b[n][n], int32_t c[n][n])
{
	for (size_t j = 0; j < n; ++j) {
		for (size_t i = 0; i < n; ++i) {
			c[i][j] = a[i][j] * b[i][j];
		}
	}
}

// Traverse rows first
// cache-friendly version for row-major matrices
void hadamard_row_major(size_t n, const int32_t a[n][n],
	const int32_t b[n][n], int32_t c[n][n])
{
	for (size_t i = 0; i < n; ++i) {
		for (size_t j = 0; j < n; ++j) {
			c[i][j] = a[i][j] * b[i][j];
		}
	}
}

// Parse the optional matrix dimension while rejecting malformed or
// overflowing values
static int parse_size(const char *text, size_t *value)
{
	char *end;
	errno = 0;
	const uintmax_t parsed = strtoumax(text, &end, 10);
	if (errno != 0 || *text == '\0' || *end != '\0' ||
		parsed > SIZE_MAX) {
		return -1;
	}

	*value = (size_t)parsed;
	return 0;
}

int main(int argc, char **argv)
{
	// Use a large default size so cache behavior is measurable
	size_t n = 1024;
	if (argc > 2 || (argc == 2 && parse_size(argv[1], &n) != 0) ||
		n == 0) {
		fprintf(stderr, "usage: %s [positive matrix size]\n", argv[0]);
		return EXIT_FAILURE;
	}

	// Check the multiplication before calculating the allocation size
	if (n > SIZE_MAX / n || n * n > SIZE_MAX / sizeof(int32_t)) {
		fprintf(stderr, "matrix is too large\n");
		return EXIT_FAILURE;
	}

	const size_t elements = n * n;
	// A pointer to an n-element row gives these allocations a 2D-array type
	// Each allocation contains n contiguous rows in row-major order.
	int32_t(*a)[n] = calloc(n, sizeof(*a));
	int32_t(*b)[n] = calloc(n, sizeof(*b));
	int32_t(*column_result)[n] = malloc(n * sizeof(*column_result));
	int32_t(*row_result)[n] = malloc(n * sizeof(*row_result));

	// Not enough memory to allocate one or more matrices
	if (a == NULL || b == NULL || column_result == NULL ||
		row_result == NULL) {
		fprintf(stderr, "unable to allocate matrices\n");
		free(a);
		free(b);
		free(column_result);
		free(row_result);
		return EXIT_FAILURE;
	}

	// Initialize both input matrices with deterministic test data
	for (size_t index = 0; index < elements; ++index) {
		a[index / n][index % n] = (int32_t)(index % 97);
		b[index / n][index % n] = (int32_t)(index % 31);
	}

	// Run both loop orderings on the same input matrices
	hadamard_column_major(n, a, b, column_result);
	hadamard_row_major(n, a, b, row_result);

	// Verify that changing the traversal order does not change the result
	int valid = 1;
	for (size_t index = 0; index < elements; ++index) {
		if (column_result[index / n][index % n] != row_result[index / n][index % n]) {
			valid = 0;
			break;
		}
	}
	printf("n=%zu, results=%s\n", n, valid ? "equal" : "different");

	// Release all matrix storage before exiting
	free(a);
	free(b);
	free(column_result);
	free(row_result);
	return valid ? EXIT_SUCCESS : EXIT_FAILURE;
}
