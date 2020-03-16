#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include "khatus_lib_log.h"
#include "khatus_lib_time.h"

char *argv0;

void
usage()
{
	printf(
	    "%s: [OPT ...]\n"
	    "\n"
	    "OPT = -i int     # interval\n"
	    "    | -f string  # format string\n"
	    "    | -h         # help message (i.e. what you're reading now :) )\n",
	    argv0);
	fatal("usage\n");
}

int
main(int argc, char **argv)
{
	argv0 = argv[0];

	double opt_interval = 1.0;
	char *opt_fmt = "%a %b %d %H:%M:%S";

	time_t t;
	struct timespec ti;
	char buf[128];
	char c;

	memset(buf, '\0', 128);
	while ((c = getopt(argc, argv, "f:i:h")) != -1)
		switch (c) {
		case 'f':
			opt_fmt = calloc(strlen(optarg), sizeof(char));
			strcpy(opt_fmt, optarg);
			break;
		case 'i':
			opt_interval = atof(optarg);
			break;
		case 'h':
			usage();
			break;
		default:
			usage();
		}
	ti = timespec_of_float(opt_interval);
	for (;;) {
		t = time(NULL);
		strftime(buf, sizeof(buf), opt_fmt, localtime(&t));
		puts(buf);
		fflush(stdout);
		snooze(&ti);
	}
	return EXIT_SUCCESS;
}
