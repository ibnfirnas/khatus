#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>

#include "khatus_lib_log.h"

LogLevel _khatus_lib_log_level = Debug;

void
_fatal(char *fmt, ...) {
	va_list ap;

	va_start(ap, fmt);
	fprintf(stderr, fmt, ap);
	va_end(ap);
	exit(EXIT_FAILURE);
}
