#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stddef.h>

#define I(a, p)  ((a) + (p))
#define ARR2(a)  (a), I(a, 1)
#define ARR4(a)  ARR2(a), ARR2(I(a, 2))
#define ARR8(a)  ARR4(a), ARR4(I(a, 4))
#define ARR16(a) ARR8(a), ARR8(I(a, 8))

#define ARR10(a) ARR8(a), ARR2(I(a, 8))
#define ARR26(a) ARR16(a), ARR8(I(a, 16)), ARR2(I(a, 24))

#define ARRLEN(a) (sizeof(a)/sizeof*(a))

static char base62[] = {
	ARR10('0'),
	ARR26('A'),
	ARR26('a'),
};
#undef I

int main(int argc, char ** argv) {
	if (argc != 2) {
		puts("Usage: base62 num");
		puts(" Prints num bytes of entropy in base62");
		return 1;
	}

	FILE * urandom = fopen("/dev/urandom", "r");
	if (!urandom) {
		perror("base62: /dev/urandom");
		return 1;
	}

	unsigned long length = strtoul(argv[1], NULL, 10);
	for (unsigned long i = 0; i < length; i++) {
		uint8_t entropy;
		do {
			size_t ret = fread(&entropy, 1, 1, urandom);
			if (ret < 1) {
				perror("base62: fread");
				goto done;
			}
		} while (entropy >= 248);
		putchar(base62[entropy % ARRLEN(base62)]);
	}

done:
	putchar('\n');
	fclose(urandom);
	return 0;
}
