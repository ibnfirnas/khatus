#include <errno.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "khatus_lib_log.h"
#include "khatus_lib_time.h"

struct timespec
timespec_of_float(double n)
{
	double integral;
	double fractional;
	struct timespec t;

	fractional = modf(n, &integral);
	t.tv_sec = (int) integral;
	t.tv_nsec = (int) (1E9 * fractional);

	return t;
}

void
snooze(struct timespec *t)
{
	struct timespec remainder;
	int result;

	result = nanosleep(t, &remainder);

	if (result < 0) {
		if (errno == EINTR) {
			warn(
			    "nanosleep interrupted. Remainder: "
			    "{ tv_sec = %ld, tv_nsec = %ld }",
			    remainder.tv_sec, remainder.tv_nsec);
			/* No big deal if we occasionally sleep less,
			 * so not attempting to correct after an interruption.
			 */
		} else {
			fatal("nanosleep: %s\n", strerror(errno));
		}
	}
}
