/*

- [ ] Switch from regular files to named pipes
	- [ ] poll with select

*/

#include <assert.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <fcntl.h>
#include <unistd.h>

#define debug(args...) {fprintf(stderr, "[debug] " args);}
#define info( args...) {fprintf(stderr, "[info] "  args);}
#define error(args...) {fprintf(stderr, "[error] " args);}
#define fatal(args...) {fprintf(stderr, "[fatal] " args); exit(EXIT_FAILURE);}
#define usage(args...) {print_usage(); fatal("[usage] " args);}

char *argv0;

typedef struct File File;
struct File {
	char   *name;
	int     fd;
	int     width;
	int     last_read;
	int     ttl;
	int     pos;  /* Position on the output buffer. */
	File   *next;
};

typedef struct Config Config;
struct Config {
	int    interval;
	char * separator;
	char * timefmt;
	File * files;
	int    file_count;
	int    total_width;
} defaults = {
	.interval    = 1,
	.separator   = "|",
	.timefmt     = "%Y-%m-%d %H:%M:%S",
	.files       = NULL,
	.file_count  = 0,
	.total_width = 0,
};


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
	assert(argv0);
	fprintf(
		stderr,
		"\n"
		"Usage: %s [OPTION ...] SPEC [SPEC ...]\n"
		"\n"
		"  SPEC       = FILE_PATH DATA_WIDTH DATA_TTL\n"
		"  FILE_PATH  = string\n"
		"  DATA_WIDTH = int  (* (positive) number of characters *)\n"
		"  DATA_TTL   = int  (* (positive) number of seconds *)\n"
		"  OPTION     = -i INTERVAL\n"
		"             | -s SEPARATOR\n"
		"  SEPARATOR  = string\n"
		"  INTERVAL   = int  (* (positive) number of seconds *)\n"
		"\n",
		argv0
	);
	fprintf(
		stderr,
		"Example: %s -i 1 /dev/shm/khatus/khatus_sensor_x 4 10\n"
		"\n",
		argv0
	);
}

void opts_parse_any(Config *, int, char *[], int);  /* For mutually-recursive calls. */

void
parse_opts_opt_i(Config *cfg, int argc, char *argv[], int i)
{
	if (i < argc) {
		char *param = argv[i++];

		if (is_pos_num(param)) {
			cfg->interval = atoi(param);
			opts_parse_any(cfg, argc, argv, i);
		} else {
			usage("Option -i parameter is invalid: \"%s\"\n", param);
		}
	} else {
		usage("Option -i parameter is missing.\n");
	}
}

void
parse_opts_opt_s(Config *cfg, int argc, char *argv[], int i)
{
	if (i < argc) {
		cfg->separator = malloc((strlen(argv[i]) + 1) * sizeof(char));
		strcpy(cfg->separator, argv[i]);
		opts_parse_any(cfg, argc, argv, ++i);
	} else {
		usage("Option -s parameter is missing.\n");
	}
}

void
parse_opts_opt_t(Config *cfg, int argc, char *argv[], int i)
{
	if (i < argc) {
		cfg->timefmt = malloc((strlen(argv[i]) + 1) * sizeof(char));
		strcpy(cfg->timefmt, argv[i]);
		opts_parse_any(cfg, argc, argv, ++i);
	} else {
		usage("Option -t parameter is missing.\n");
	}
}

void
parse_opts_opt(Config *cfg, int argc, char *argv[], int i)
{
	switch (argv[i][1]) {
		case 'i': parse_opts_opt_i(cfg, argc, argv, ++i); break;  /* TODO: Generic set_int */
		case 's': parse_opts_opt_s(cfg, argc, argv, ++i); break;  /* TODO: Generic set_str */
		case 't': parse_opts_opt_t(cfg, argc, argv, ++i); break;  /* TODO: Generic set_str */
		default : usage("Option \"%s\" is invalid\n", argv[i]);
	}
}

void
parse_opts_spec(Config *cfg, int argc, char *argv[], int i)
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
	File *f = malloc(sizeof(struct File));
	if (f) {
		f->name      = n;
		f->fd        = -1;
		f->width     = atoi(w);
		f->ttl       = atoi(t);
		f->last_read = 0;
		f->pos       = cfg->total_width;
		f->next      = cfg->files;

		cfg->files        = f;
		cfg->total_width += f->width;
		cfg->file_count++;
	} else {
		fatal("[memory] Allocation failure.");
	}
	opts_parse_any(cfg, argc, argv, i);
}

void
opts_parse_any(Config *cfg, int argc, char *argv[], int i)
{
	if (i < argc) {
		switch (argv[i][0]) {
			case '-': parse_opts_opt(cfg, argc, argv, i); break;
			default : parse_opts_spec(cfg, argc, argv, i);
		}
	}
}

void
opts_parse(Config *cfg, int argc, char *argv[], int i)
{
	opts_parse_any(cfg, argc, argv, 1);

	File *last = cfg->files;
	cfg->files = NULL;
	for (File *f = last; f; ) {
		File *next = f->next;
		f->next = cfg->files;
		cfg->files = f;
		f = next;
	}
}

void
read_all(Config *cfg, char *buf)
{
	/* TODO: stat then check TTL */
	for (File *f = cfg->files; f; f = f->next) {
		if (f->fd < 0)
			f->fd = open(f->name, O_RDONLY);
		if (f->fd == -1) {
			/* TODO: Consider backing off retries for failed files. */
			fatal("Failed to open \"%s\"\n", f->name);
		} else {
			lseek(f->fd, 0, 0);
			ssize_t n = read(f->fd, buf + f->pos, f->width);
			int lasti = n + f->pos - 1;
			char lastc = buf[lasti];
			if (lastc == '\n')
				buf[lasti] = ' ';
		}
	}
}

int
main(int argc, char *argv[])
{
	int width;
	int nfiles = 0;
	int seplen;
	int prefix = 0;
	char *buf;
	Config *cfg = &defaults;

	argv0 = argv[0];

	opts_parse(cfg, argc, argv, 1);
	debug("argv0 = %s\n", argv0);
	debug("[config] interval    = %d\n", cfg->interval);
	debug("[config] separator   = %s\n", cfg->separator);
	debug("[config] file_count  = %d\n", cfg->file_count);
	debug("[config] total_width = %d\n", cfg->total_width);
	if (cfg->files == NULL)
		usage("No file specs were given!\n");
	for (File *f = cfg->files; f; f = f->next) {
		debug(
			"[config] file = "
			"{"
				" name = %s,"
				" pos = %d,"
				" width = %d,"
				" ttl = %d,"
				" last_read = %d,"
			" }\n",
			f->name,
			f->pos,
			f->width,
			f->ttl,
			f->last_read
		);
	}

	width  = cfg->total_width;
	seplen = strlen(cfg->separator);

	/* 1st pass to make space for separators */
	for (File *f = cfg->files; f; f = f->next) {
		f->pos += prefix;
		prefix += seplen;
		nfiles++;
	}
	width += (seplen * (nfiles - 1));
	buf = malloc(width + 1);
	if (buf == NULL)
		fatal("[memory] Failed to allocate buffer of %d bytes", width);
	memset(buf, ' ', width);
	buf[width] = '\0';
	/* 2nd pass to set the separators */
	for (File *f = cfg->files; f; f = f->next) {
		if (f->pos) {  /* Skip the first, left-most */
			strcpy(buf + (f->pos - seplen), cfg->separator);
		}
	}

	/* TODO: nanosleep and nano time diff */
	for (;;) {
		read_all(cfg, buf);
		printf("%s\n", buf);
		sleep(cfg->interval);
	}
}
