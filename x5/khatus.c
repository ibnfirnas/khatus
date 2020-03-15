#include <sys/select.h>
#include <sys/stat.h>

#include <assert.h>
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <X11/Xlib.h>

#include "bsdtimespec.h"

#define debug(args...) {fprintf(stderr, "[debug] " args);}
#define info( args...) {fprintf(stderr, "[info] "  args);}
#define error(args...) {fprintf(stderr, "[error] " args);}
#define fatal(args...) {fprintf(stderr, "[fatal] " args); exit(EXIT_FAILURE);}
#define usage(args...) {print_usage(); fatal("[usage] " args);}

#define ERRMSG "ERROR"

static const char errmsg[] = ERRMSG;
static const int  errlen   = sizeof(ERRMSG) - 1;

char *argv0;

/* TODO: Convert fifo list to fifo array. */
typedef struct Fifo Fifo;
struct Fifo {
	char   *name;
	int     fd;
	int     width;
	int     last_read;
	int     ttl;
	int     pos;  /* Position on the output buffer. */
	Fifo   *next;
};

typedef struct Config Config;
struct Config {
	int    interval;
	char * separator;
	Fifo * fifos;
	int    fifo_count;
	int    total_width;
	int    output_to_x_root_window;
} defaults = {
	.interval    = 1,
	.separator   = "|",
	.fifos       = NULL,
	.fifo_count  = 0,
	.total_width = 0,
	.output_to_x_root_window = 0,
};

void
fifo_print_one(Fifo *f)
{
	debug(
		"Fifo "
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
fifo_print_all(Fifo *head)
{
	for (Fifo *f = head; f; f = f->next) {
		fifo_print_one(f);
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
			" fifo_count = %d,"
			" total_width = %d,"
			" fifos = ..."
		" }\n",
		c->interval,
		c->separator,
		c->fifo_count,
		c->total_width
	);
	fifo_print_all(c->fifos);
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
		case 'i':
			/* TODO: Generic set_int */
			parse_opts_opt_i(cfg, argc, argv, ++i);
			break;
		case 's':
			/* TODO: Generic set_str */
			parse_opts_opt_s(cfg, argc, argv, ++i);
			break;
		case 'x':
			cfg->output_to_x_root_window = 1;
			opts_parse_any(cfg, argc, argv, ++i);
			break;
		default :
			usage("Option \"%s\" is invalid\n", argv[i]);
	}
}

void
parse_opts_spec(Config *cfg, int argc, char *argv[], int i)
{
	if ((i + 3) > argc)
		usage("[spec] Parameter(s) missing for fifo \"%s\".\n", argv[i]);

	char *n = argv[i++];
	char *w = argv[i++];
	char *t = argv[i++];

	if (!is_pos_num(w))
		usage("[spec] Invalid width: \"%s\", for fifo \"%s\"\n", w, n);
	if (!is_pos_num(t))
		usage("[spec] Invalid TTL: \"%s\", for fifo \"%s\"\n", t, n);
	Fifo *f = calloc(1, sizeof(struct Fifo));
	if (f) {
		f->name      = n;
		f->fd        = -1;
		f->width     = atoi(w);
		f->ttl       = atoi(t);
		f->last_read = 0;
		f->pos       = cfg->total_width;
		f->next      = cfg->fifos;

		cfg->fifos        = f;
		cfg->total_width += f->width;
		cfg->fifo_count++;
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
			case '-':
				parse_opts_opt(cfg, argc, argv, i);
				break;
			default :
				parse_opts_spec(cfg, argc, argv, i);
		}
	}
}

void
opts_parse(Config *cfg, int argc, char *argv[])
{
	opts_parse_any(cfg, argc, argv, 1);

	Fifo *last = cfg->fifos;
	cfg->fifos = NULL;
	for (Fifo *f = last; f; ) {
		Fifo *next = f->next;
		f->next = cfg->fifos;
		cfg->fifos = f;
		f = next;
	}
}

void
fifo_read_error(Fifo *f, char *buf)
{
	char *b;
	int i;

	b = buf + f->pos;
	/* Copy as much of the error message as possible.
	 * EXCLUDING the reminating \0. */
	for (i = 0; i < errlen && i < f->width; i++)
		b[i] = errmsg[i];
	/* Any remaining slots: */
	for (; i < f->width; i++)
		b[i] = '_';
}

void
fifo_read_one(Fifo *f, char *buf)
{
	ssize_t current;
	ssize_t total;
	char *b;
	char c;

	current = 0;
	total = 0;
	c = '\0';
	b = buf + f->pos;
	while ((current = read(f->fd, &c, 1)) && c != '\n' && c != '\0' && total++ < f->width)
		*b++ = c;
	if (current == -1) {
		error("Failed to read: \"%s\". Error: %s\n", f->name, strerror(errno));
		fifo_read_error(f, buf);
	} else
		while (total++ < f->width)
			*b++ = ' ';
	/* TODO Record timestamp read */
	close(f->fd);
	f->fd = -1;
}

void
fifo_read_all(Config *cfg, char *buf)
{
	fd_set fds;
	int maxfd = -1;
	int ready;
	struct stat st;

	FD_ZERO(&fds);
	for (Fifo *f = cfg->fifos; f; f = f->next) {
		/* TODO: Create the FIFO if it doesn't already exist. */
		if (lstat(f->name, &st) < 0) {
			error("Cannot stat \"%s\". Error: %s\n", f->name, strerror(errno));
			fifo_read_error(f, buf);
			continue;
		}
		if (!(st.st_mode & S_IFIFO)) {
			error("\"%s\" is not a FIFO\n", f->name);
			fifo_read_error(f, buf);
			continue;
		}
		debug("opening: %s\n", f->name);
		if (f->fd < 0)
			f->fd = open(f->name, O_RDONLY | O_NONBLOCK);
		if (f->fd == -1) {
			/* TODO: Consider backing off retries for failed fifos. */
			error("Failed to open \"%s\"\n", f->name);
			fifo_read_error(f, buf);
			continue;
		}
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
	for (Fifo *f = cfg->fifos; f; f = f->next) {
		if (FD_ISSET(f->fd, &fds)) {
			debug("reading: %s\n", f->name);
			fifo_read_one(f, buf);
		}
	}
}

void
snooze(struct timespec *t)
{
	struct timespec remainder;
	int result;

	result = nanosleep(t, &remainder);

	if (result < 0) {
		if (errno == EINTR) {
			info(
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

int
main(int argc, char *argv[])
{
	int width  = 0;
	int nfifos = 0;
	int seplen = 0;
	int prefix = 0;
	int errors = 0;
	char *buf;
	Config cfg0 = defaults;
	Config *cfg = &cfg0;
	Display *display = NULL;
	struct stat st;
	struct timespec
		t0,  /* time stamp. before reading fifos */
		t1,  /* time stamp. after  reading fifos */
		ti,  /* time interval desired    (t1 - t0) */
		td,  /* time interval measured   (t1 - t0) */
		tc;  /* time interval correction (ti - td) when td < ti */

	argv0 = argv[0];

	opts_parse(cfg, argc, argv);
	debug("argv0 = %s\n", argv0);
	config_print(cfg);

	/* TODO: Support interval < 1. i.e. implement timespec_of_float */
	ti.tv_sec  = cfg->interval;
	ti.tv_nsec = 0;

	if (cfg->fifos == NULL)
		usage("No fifo specs were given!\n");

	/* 1st pass to check file existence and type */
	for (Fifo *f = cfg->fifos; f; f = f->next) {
		if (lstat(f->name, &st) < 0) {
			error("Cannot stat \"%s\". Error: %s\n", f->name, strerror(errno));
			errors++;
			continue;
		}
		if (!(st.st_mode & S_IFIFO)) {
			error("\"%s\" is not a FIFO\n", f->name);
			errors++;
			continue;
		}
	}
	if (errors)
		fatal("Encountered errors with the given file paths. See log.\n");

	width  = cfg->total_width;
	seplen = strlen(cfg->separator);

	/* 2nd pass to make space for separators */
	for (Fifo *f = cfg->fifos; f; f = f->next) {
		f->pos += prefix;
		prefix += seplen;
		nfifos++;
	}
	width += (seplen * (nfifos - 1));
	buf = calloc(1, width + 1);
	if (buf == NULL)
		fatal("[memory] Failed to allocate buffer of %d bytes", width);
	memset(buf, ' ', width);
	buf[width] = '\0';
	/* 3rd pass to set the separators */
	for (Fifo *f = cfg->fifos; f; f = f->next) {
		if (f->pos) {  /* Skip the first, left-most */
			/* Copying only seplen ensures we omit the '\0' byte. */
			strncpy(buf + (f->pos - seplen), cfg->separator, seplen);
		}
	}

	if (cfg->output_to_x_root_window && !(display = XOpenDisplay(NULL)))
		fatal("XOpenDisplay failed with: %p\n", display);
	/* TODO: Handle signals */
	for (;;) {
		clock_gettime(CLOCK_MONOTONIC, &t0); // FIXME: check errors
		/* TODO: Cache expiration. i.e. use the TTL */
		/* TODO: How to trigger TTL check? On select? Alarm signal? */
		/* TODO: Set timeout on fifo_read_all based on diff of last time of
		 *       fifo_read_all and desired time of next TTL check.
		 */
		/* TODO: How long to wait on IO? Max TTL? */
		fifo_read_all(cfg, buf);
		if (cfg->output_to_x_root_window) {
			if (XStoreName(display, DefaultRootWindow(display), buf) < 0)
				fatal("XStoreName failed.\n");
			XFlush(display);
		} else {
			puts(buf);
			fflush(stdout);
		}
		clock_gettime(CLOCK_MONOTONIC, &t1); // FIXME: check errors
		timespecsub(&t1, &t0, &td);
		debug("td {tv_sec = %ld, tv_nsec = %ld}\n", td.tv_sec, td.tv_nsec);
		if (timespeccmp(&td, &ti, <)) {
			/* Pushback on data producers by refusing to read the
			 * pipe more frequently than the interval.
			 */
			timespecsub(&ti, &td, &tc);
			debug("snooze YES\n");
			snooze(&tc);
		} else
			debug("snooze NO\n");
	}

	return EXIT_SUCCESS;
}
