#include <assert.h>
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <limits.h>
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

char *argv0;

double  opt_interval = 1.0;
char   *opt_battery  = "BAT0";
char   *opt_fifo     = NULL;

void
print_usage()
{
	printf(
	    "%s: [OPT ...] FIFO\n"
	    "\n"
	    "FIFO = string    # path to fifo file\n"
	    "OPT = -i int     # interval\n"
	    "    | -b string  # battery file name from /sys/class/power_supply/\n"
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
			opt_battery = calloc(strlen(optarg), sizeof(char));
			strcpy(opt_battery, optarg);
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
	opt_fifo = argv[optind];
	debug("opt_fifo: %s\n", opt_fifo);
	if (!opt_fifo)
		usage("No filename was provided\n");
}

int
get_capacity(char *buf, char *path)
{
	FILE *fp;
	int cap;

	if (!(fp = fopen(path, "r")))
		fatal("Failed to open %s. errno: %d, msg: %s\n",
		    path, errno, strerror(errno));

	switch (fscanf(fp, "%d", &cap)) {
	case -1: fatal("EOF\n");
	case  0: fatal("Read 0\n");
	case  1: break;
	default: assert(0);
	}
	fclose(fp);
	return snprintf(buf, 6, "%3d%%\n", cap);
}

int
main(int argc, char **argv)
{
	argv0 = argv[0];

	char  buf[10];
	char path[PATH_MAX];
	char *path_fmt = "/sys/class/power_supply/%s/capacity";
	struct timespec ti = timespec_of_float(opt_interval);

	opt_parse(argc, argv);

	memset(path, '\0', PATH_MAX);
	snprintf(path, PATH_MAX, path_fmt, opt_battery);
	loop(
	    &ti,
	    opt_fifo,
	    buf,
	    (SENSOR_FUN_T)    get_capacity,
	    (SENSOR_PARAMS_T) path
	);
}
