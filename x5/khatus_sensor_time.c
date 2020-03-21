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
#include "khatus_lib_time.h"

#define usage(...) {print_usage(); fprintf(stderr, "Error:\n    " __VA_ARGS__); exit(EXIT_FAILURE);}

#define MAX_LEN 20
#define END_OF_MESSAGE '\n'

char *argv0;

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

int
main(int argc, char **argv)
{
	argv0 = argv[0];

	double opt_interval = 1.0;
	char *opt_fmt = "%a %b %d %H:%M:%S";

	time_t t;
	struct timespec ti;
	char buf[MAX_LEN];
	char c;

	char *fifo_name;
	int   fifo_fd = -1;

	int n = 0;  /* written */
	int r = 0;  /* remaining */
	int i = 0;  /* buffer position */

	signal(SIGPIPE, SIG_IGN);  /* Handling manually */

	memset(buf, '\0', MAX_LEN);
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
			return 0;
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
			return 1;
		default:
			assert(0);
		}
	fifo_name = argv[optind];
	debug("fifo_name: %s\n", fifo_name);
	if (!fifo_name)
		usage("No filename was provided\n");
	ti = timespec_of_float(opt_interval);
	for (;;) {
		debug("openning \"%s\"\n", fifo_name);
		fifo_fd = open(fifo_name, O_WRONLY);
		if (fifo_fd < 0)
			fatal("Failed to open FIFO file: \"%s\". Error: %s\n",
			    fifo_name,
			    strerror(errno));
		debug("openned. fd: %d\n", fifo_fd);
		t = time(NULL);
		strftime(buf, MAX_LEN, opt_fmt, localtime(&t));
		r = strlen(buf);
		buf[r] = END_OF_MESSAGE;
		for (i = 0; (n = write(fifo_fd, buf + i++, 1)) && r; r--)
			;
		if (n < 0)
			fatal("Failed to write to %s. Err num: %d, Err msg: %s\n",
			    fifo_name,
			    errno,
			    strerror(errno));
		if (close(fifo_fd) < 0)
			fatal("Failed to close %s. Err num: %d, Err msg: %s\n",
			    fifo_name,
			    errno,
			    strerror(errno));
		fifo_fd = -1;
		debug("closed. fd: %d\n", fifo_fd);
		snooze(&ti);
	}
	return EXIT_SUCCESS;
}
