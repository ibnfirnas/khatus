#include <assert.h>
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include "khatus_lib_log.h"
#include "khatus_lib_sensor.h"
#include "khatus_lib_time.h"

#define usage(...) {print_usage(); fprintf(stderr, "Error:\n    " __VA_ARGS__); exit(EXIT_FAILURE);}

#define MAX_LEN 20
#define END_OF_MESSAGE '\n'

char *argv0 = NULL;

double opt_interval = 1.0;
char *opt_fmt = "%a %b %d %H:%M:%S";
char *fifo_name = NULL;

void
print_usage()
{
	printf(
	    "%s: [OPT ...] FIFO\n"
	    "\n"
	    "FIFO = string    # path to fifo file\n"
	    "OPT = -i int     # interval\n"
	    "    | -f string  # format string\n"
	    "    | -h         # help message (i.e. what you're reading now :) )\n",
	    argv0);
}

void
opt_parse(int argc, char **argv)
{
	char c;

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
			print_usage();
			exit(EXIT_SUCCESS);
		case '?':
			if (optopt == 'f' || optopt == 'i')
				fprintf(stderr,
					"Option -%c requires an argument.\n",
					optopt);
			else if (isprint(optopt))
				fprintf (stderr,
					"Unknown option `-%c'.\n",
					optopt);
			else
				fprintf(stderr,
					"Unknown option character `\\x%x'.\n",
					optopt);
			exit(EXIT_FAILURE);
		default:
			assert(0);
		}
	fifo_name = argv[optind];
	debug("fifo_name: %s\n", fifo_name);
	if (!fifo_name)
		usage("No filename was provided\n");
}

int
get_time(char *buf, char *fmt)
{
	time_t t;

	t = time(NULL);
	strftime(buf, MAX_LEN, fmt, localtime(&t));
	return strlen(buf);
}

int
main(int argc, char **argv)
{
	argv0 = argv[0];

	struct timespec ti;
	char buf[MAX_LEN];

	opt_parse(argc, argv);

	signal(SIGPIPE, SIG_IGN);  /* Handled in loop */

	memset(buf, '\0', MAX_LEN);
	ti = timespec_of_float(opt_interval);
	loop(
	    &ti,
	    fifo_name,
	    buf,
	    (SENSOR_FUN_T)    get_time,
	    (SENSOR_PARAMS_T) opt_fmt
	);
	return EXIT_SUCCESS;
}
