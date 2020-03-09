#include <fcntl.h>
#include <unistd.h>
#include <sys/select.h>
#include <sys/stat.h>
#include <X11/Xlib.h>

#include <assert.h>
#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define debug(args...) {fprintf(stderr, "[debug] " args);}
#define info( args...) {fprintf(stderr, "[info] "  args);}
#define error(args...) {fprintf(stderr, "[error] " args);}
#define fatal(args...) {fprintf(stderr, "[fatal] " args); exit(EXIT_FAILURE);}
#define usage(args...) {print_usage(); fatal("[usage] " args);}

char *argv0;

/* TODO: Convert file list to file array. */
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
	File * files;
	int    file_count;
	int    total_width;
	int    output_to_x_root_window;
} defaults = {
	.interval    = 1,
	.separator   = "|",
	.files       = NULL,
	.file_count  = 0,
	.total_width = 0,
	.output_to_x_root_window = 0,
};

void
file_print_one(File *f)
{
	debug(
		"File "
		"{"
			" name = %s,"
			" fd = %d,"
			" width = %d,"
			" last_read = %d,"
			" ttl = %d,"
			" pos = %d,"
			" next = %p,"
		" }\n",
		f->name,
		f->fd,
		f->width,
		f->last_read,
		f->ttl,
		f->pos,
		f->next
	);
}

void
file_print_all(File *head)
{
	for (File *f = head; f; f = f->next) {
		file_print_one(f);
	}
}

void
config_print(Config *c)
{
	debug(
		"Config "
		"{"
			" interval = %d,"
			" separator = %s,"
			" file_count = %d,"
			" total_width = %d,"
			" files = ..."
		" }\n",
		c->interval,
		c->separator,
		c->file_count,
		c->total_width
	);
	file_print_all(c->files);
}

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
		cfg->separator = calloc((strlen(argv[i]) + 1), sizeof(char));
		strcpy(cfg->separator, argv[i]);
		opts_parse_any(cfg, argc, argv, ++i);
	} else {
		usage("Option -s parameter is missing.\n");
	}
}

void
parse_opts_opt(Config *cfg, int argc, char *argv[], int i)
{
	switch (argv[i][1]) {
		case 'i': parse_opts_opt_i(cfg, argc, argv, ++i); break;  /* TODO: Generic set_int */
		case 's': parse_opts_opt_s(cfg, argc, argv, ++i); break;  /* TODO: Generic set_str */
		case 'x': {
			cfg->output_to_x_root_window = 1;
			opts_parse_any(cfg, argc, argv, ++i);
			break;
		}
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
	File *f = calloc(1, sizeof(struct File));
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
opts_parse(Config *cfg, int argc, char *argv[])
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
read_one(File *f, char *buf)
{
	ssize_t current;
	ssize_t total;
	char *b;
	char c;

	current = 0;
	total = 0;
	c = '\0';
	b = buf + f->pos;
	memset(b, ' ', f->width);
	while ((current = read(f->fd, &c, 1)) && c != '\n' && c != '\0' && total++ < f->width)
		*b++ = c;
	if (current == -1)
		error("Failed to read: \"%s\". Error: %s\n", f->name, strerror(errno));
	/* TODO Record timestamp read */
	close(f->fd);
	f->fd = -1;
}

void
read_all(Config *cfg, char *buf)
{
	fd_set fds;
	int maxfd;
	int ready;
	struct stat st;

	FD_ZERO(&fds);
	/* TODO: Check TTL */
	for (File *f = cfg->files; f; f = f->next) {
		/* TODO: Create the FIFO if it doesn't already exist. */
		if (lstat(f->name, &st) < 0)
			fatal("Cannot stat \"%s\". Error: %s\n", f->name, strerror(errno));
		if (!(st.st_mode & S_IFIFO))
			fatal("\"%s\" is not a FIFO\n", f->name);
		debug("opening: %s\n", f->name);
		if (f->fd < 0)
			f->fd = open(f->name, O_RDONLY | O_NONBLOCK);
		if (f->fd == -1)
			/* TODO: Consider backing off retries for failed files. */
			fatal("Failed to open \"%s\"\n", f->name);
		if (f->fd > maxfd)
			maxfd = f->fd;
		FD_SET(f->fd, &fds);
	}
	debug("selecting...\n");
	ready = select(maxfd + 1, &fds, NULL, NULL, NULL);
	debug("ready: %d\n", ready);
	assert(ready != 0);
	if (ready < 0)
		fatal("%s", strerror(errno));
	for (File *f = cfg->files; f; f = f->next) {
		if (FD_ISSET(f->fd, &fds)) {
			debug("reading: %s\n", f->name);
			read_one(f, buf);
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
	Display *display;

	argv0 = argv[0];

	opts_parse(cfg, argc, argv);
	debug("argv0 = %s\n", argv0);
	config_print(cfg);
	if (cfg->files == NULL)
		usage("No file specs were given!\n");

	width  = cfg->total_width;
	seplen = strlen(cfg->separator);

	/* 1st pass to make space for separators */
	for (File *f = cfg->files; f; f = f->next) {
		f->pos += prefix;
		prefix += seplen;
		nfiles++;
	}
	width += (seplen * (nfiles - 1));
	buf = calloc(1, width + 1);
	if (buf == NULL)
		fatal("[memory] Failed to allocate buffer of %d bytes", width);
	memset(buf, ' ', width);
	buf[width] = '\0';
	/* 2nd pass to set the separators */
	for (File *f = cfg->files; f; f = f->next) {
		if (f->pos) {  /* Skip the first, left-most */
			/* Copying only seplen ensures we omit the '\0' byte. */
			strncpy(buf + (f->pos - seplen), cfg->separator, seplen);
		}
	}

	if (cfg->output_to_x_root_window && !(display = XOpenDisplay(NULL)))
		fatal("XOpenDisplay failed with: %p\n", display);
	/* TODO: nanosleep and nano time diff */
	for (;;) {
		/* TODO: Check TTL and maybe blank-out */
		/* TODO: How to trigger TTL check? On select? Alarm signal? */
		/* TODO: Set timeout on read_all based on diff of last time of
		 *       read_all and desired time of next TTL check.
		 * */
		read_all(cfg, buf);
		if (cfg->output_to_x_root_window) {
			if (XStoreName(display, DefaultRootWindow(display), buf) < 0)
				fatal("XStoreName failed.\n");
			XFlush(display);
		} else {
			puts(buf);
			fflush(stdout);
		}
	}
}
