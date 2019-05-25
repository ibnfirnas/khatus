#include <assert.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define  MAX_TOT_WIDTH  1024

#define debug(   args...) {fprintf(stderr, "[debug] " args);}
#define error(   args...) {fprintf(stderr, "[error] " args); errors++;}
#define fatal(n, args...) {fprintf(stderr, "[fatal] " args); exit(n);}
#define usage(   args...) {print_usage(); fatal(1, "[usage] " args);}


typedef struct file * File;

struct file {
	char *  name;
	int     width;
	int     ttl;
	File    next;
};

struct options {
	char * argv0;
	int    interval;
	File   files;
} options = {
	.argv0    = NULL,
	.interval = 1,
	.files    = NULL
};

typedef struct options * Options;

Options opts   = &options;
int     errors = 0;


int
is_pos_num(char *s)
{
	while (*s != '\0')
		if (!isdigit(*(s++)))
			return 0;
	return 1;
}

void
print_usage()
{
	assert(opts->argv0);
	fprintf(
		stderr,
		"\n"
		"Usage: %s [OPTIONS ...] SPEC [SPEC ...]\n"
		"\n"
		"\tSPEC       = FILE_PATH DATA_WIDTH DATA_TTL\n"
		"\tFILE_PATH  = string\n"
		"\tDATA_WIDTH = int  (* (positive) number of characters *)\n"
		"\tDATA_TTL   = int  (* (positive) number of seconds *)\n"
		"\tOPTION     = -i INTERVAL\n"
		"\tINTERVAL   = int  (* (positive) number of seconds *)\n"
		"\n",
		opts->argv0
	);
	fprintf(
		stderr,
		"Example: %s -i 1 /dev/shm/khatus/khatus_sensor_x 4 10\n"
		"\n",
		opts->argv0
	);
}

void parse_opts(int, char *[], int);  /* For mutually-recursive calls. */

void
parse_opts_opt_i(int argc, char *argv[], int i)
{
	if (i < argc) {
		char *param = argv[i++];

		if (is_pos_num(param)) {
			opts->interval = atoi(param);
			parse_opts(argc, argv, i);
		} else {
			usage("Option -i parameter is invalid: \"%s\"\n", param);
		}
	} else {
		usage("Option -i parameter is missing.\n");
	}
}

void
parse_opts_opt(int argc, char *argv[], int i)
{
	switch (argv[i][1]) {
		case 'i': parse_opts_opt_i(argc, argv, ++i); break;  /* TODO: Generic set_int */
		default : usage("Option \"%s\" is invalid\n", argv[i]);
	}
}

void
parse_opts_spec(int argc, char *argv[], int i)
{
	if ((i + 3) > argc)
		usage("[spec] Parameter(s) missing for file \"%s\".\n", argv[i]);

	char *n = argv[i++];
	char *w = argv[i++];
	char *t = argv[i++];

	if (!is_pos_num(w))
		usage("[spec] Invalid width: \"%s\", for file \"%s\"\n", w, n);
	if (!is_pos_num(t))
		usage("[spec] Invalid TTL: \"%s\", for file \"%s\"\n", t, n);
	File f = malloc(sizeof(struct file));
	if (f) {
		f->name     = n;
		f->width    = atoi(w);
		f->ttl      = atoi(t);
		f->next     = opts->files;
		opts->files = f;
	} else {
		fatal(2, "[memory] Allocation failure.");
	}
	parse_opts(argc, argv, i);
}

void
parse_opts(int argc, char *argv[], int i)
{
	if (i < argc) {
		switch (argv[i][0]) {
			case '-': parse_opts_opt(argc, argv, i); break;
			default : parse_opts_spec(argc, argv, i);
		}
	}
}

int
main(int argc, char **argv)
{
	opts->argv0 = argv[0];
	parse_opts(argc, argv, 1);
	assert(!errors);
	debug("[options] argv0 = %s\n", opts->argv0);
	debug("[options] interval = %d\n", opts->interval);
	if (opts->files == NULL)
		usage("No file specs were given!\n");
	for (File f = opts->files; f; f = f->next) {
		debug(
			"[options] file = { name = %s, width = %d, ttl = %d }\n",
			f->name,
			f->width,
			f->ttl
		);
	}
}
