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
#include "khatus_lib_log.h"
#include "khatus_lib_time.h"

#define usage(...) {print_usage(); fprintf(stderr, "Error:\n    " __VA_ARGS__); exit(EXIT_FAILURE);}
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
	struct timespec last_read;
	struct timespec ttl;
	int     pos_init;  /* Initial position on the output buffer. */
	int     pos_curr;  /* Current position on the output buffer. */
	int     pos_final; /* Final   position on the output buffer. */
	Fifo   *next;
};

typedef struct Config Config;
struct Config {
	double interval;
	char * separator;
	Fifo * fifos;
	int    fifo_count;
	int    total_width;
	int    output_to_x_root_window;
} defaults = {
	.interval    = 1.0,
	.separator   = "|",
	.fifos       = NULL,
	.fifo_count  = 0,
	.total_width = 0,
	.output_to_x_root_window = 0,
};

enum read_status {
	END_OF_FILE,
	END_OF_MESSAGE,
	RETRY,
	FAILURE
};

void
fifo_print_one(Fifo *f)
{
	info("Fifo "
	    "{"
	    " name = %s,"
	    " fd = %d,"
	    " width = %d,"
	    " last_read = {tv_sec = %ld, tv_nsec = %ld}"
	    " ttl = {tv_sec = %ld, tv_nsec = %ld},"
	    " pos_init = %d,"
	    " pos_curr = %d,"
	    " pos_final = %d,"
	    " next = %p,"
	    " }\n",
	    f->name,
	    f->fd,
	    f->width,
	    f->last_read.tv_sec,
	    f->last_read.tv_nsec,
	    f->ttl.tv_sec,
	    f->ttl.tv_nsec,
	    f->pos_init,
	    f->pos_curr,
	    f->pos_final,
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
config_print(Config *cfg)
{
	info(
	    "Config "
	    "{"
	    " interval = %f,"
	    " separator = %s,"
	    " fifo_count = %d,"
	    " total_width = %d,"
	    " fifos = ..."
	    " }\n",
	    cfg->interval,
	    cfg->separator,
	    cfg->fifo_count,
	    cfg->total_width
	);
	fifo_print_all(cfg->fifos);
}

int
is_pos_num(char *s)
{
	while (*s != '\0')
		if (!isdigit(*(s++)))
			return 0;
	return 1;
}

int
is_decimal(char *s)
{
	char c;
	int seen = 0;

	while ((c = *(s++)) != '\0')
		if (!isdigit(c)) {
			if (c == '.' && !seen++)
				continue;
			else
				return 0;
		}
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
	    "  DATA_TTL   = float  (* (positive) number of seconds *)\n"
	    "  OPTION     = -i INTERVAL\n"
	    "             | -s SEPARATOR\n"
	    "             | -x (* Output to X root window *)\n"
	    "             | -l LOG_LEVEL\n"
	    "  SEPARATOR  = string\n"
	    "  INTERVAL   = float  (* (positive) number of seconds *)\n"
	    "  LOG_LEVEL  = int  (* %d through %d *)\n"
	    "\n",
	    argv0,
	    Nothing,
	    Debug
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
	char *param;

	if (i >= argc)
		usage("Option -i parameter is missing.\n");
	param = argv[i++];
	if (!is_decimal(param))
		usage("Option -i parameter is invalid: \"%s\"\n", param);
	cfg->interval = atof(param);
	opts_parse_any(cfg, argc, argv, i);
}

void
parse_opts_opt_s(Config *cfg, int argc, char *argv[], int i)
{
	if (i >= argc)
		usage("Option -s parameter is missing.\n");
	cfg->separator = calloc((strlen(argv[i]) + 1), sizeof(char));
	strcpy(cfg->separator, argv[i]);
	opts_parse_any(cfg, argc, argv, ++i);
}

void
parse_opts_opt_l(Config *cfg, int argc, char *argv[], int i)
{
	char *param;
	int log_level;

	if (i >= argc)
		usage("Option -l parameter is missing.\n");
	param = argv[i++];
	if (!is_pos_num(param))
		usage("Option -l parameter is invalid: \"%s\"\n", param);
	log_level = atoi(param);
	if (log_level > Debug)
		usage("Option -l value (%d) exceeds maximum (%d)\n", log_level, Debug);
	_khatus_lib_log_level = log_level;
	opts_parse_any(cfg, argc, argv, i);
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
	case 'l':
		/* TODO: Generic set_int */
		parse_opts_opt_l(cfg, argc, argv, ++i);
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

	struct timespec last_read;

	if (!is_pos_num(w))
		usage("[spec] Invalid width: \"%s\", for fifo \"%s\"\n", w, n);
	if (!is_decimal(t))
		usage("[spec] Invalid TTL: \"%s\", for fifo \"%s\"\n", t, n);
	last_read.tv_sec  = 0;
	last_read.tv_nsec = 0;
	Fifo *f = calloc(1, sizeof(struct Fifo));
	if (f) {
		f->name      = n;
		f->fd        = -1;
		f->width     = atoi(w);
		f->ttl       = timespec_of_float(atof(t));
		f->last_read = last_read;
		f->pos_init  = cfg->total_width;
		f->pos_curr  = f->pos_init;
		f->pos_final = f->pos_init + f->width - 1;
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
fifo_expire_one(Fifo *f, struct timespec t, char *buf)
{
	struct timespec td;

	timespecsub(&t, &(f->last_read), &td);
	if (timespeccmp(&td, &(f->ttl), >=)) {
		/* TODO: Maybe configurable expiry character. */
		memset(buf + f->pos_init, '_', f->pos_final - f->pos_init);
		warn("Data source expired: \"%s\"\n", f->name);
	}
}

void
fifo_expire_all(Config *cfg, struct timespec t, char *buf)
{
	Fifo *f;

	for (f = cfg->fifos; f; f = f->next)
		fifo_expire_one(f, t, buf);
}

void
fifo_read_error(Fifo *f, char *buf)
{
	char *b;
	int i;

	b = buf + f->pos_init;
	/* Copy as much of the error message as possible.
	 * EXCLUDING the terminating \0. */
	for (i = 0; i < errlen && i < f->width; i++)
		b[i] = errmsg[i];
	/* Any remaining slots: */
	for (; i < f->width; i++)
		b[i] = '_';
}

enum read_status
fifo_read_one(Fifo *f, struct timespec t, char *buf)
{
	char c;  /* Character read. */
	int  r;  /* Remaining unused slots in buffer range. */

	for (;;) {
		switch (read(f->fd, &c, 1)) {
		case -1:
			error("Failed to read: \"%s\". errno: %d, msg: %s\n",
			    f->name, errno, strerror(errno));
			switch (errno) {
			case EINTR:
			case EAGAIN:
				return RETRY;
			default:
				return FAILURE;
			}
		case  0:
			debug("%s: End of FILE\n", f->name);
			f->pos_curr = f->pos_init;
			return END_OF_FILE;
		case  1:
			/* TODO: Consider making msg term char a CLI option */
			if (c == '\n' || c == '\0') {
				r = f->pos_final - f->pos_curr;
				if (r > 0)
					memset(buf + f->pos_curr, ' ', r);
				f->pos_curr = f->pos_init;
				f->last_read = t;
				return END_OF_MESSAGE;
			} else {
				if (f->pos_curr <= f->pos_final)
					buf[f->pos_curr++] = c;
				/* Drop beyond available range. */
			}
			break;
		default:
			assert(0);
		}
	}
}

void
fifo_read_all(Config *cfg, struct timespec *ti, char *buf)
{
	fd_set fds;
	int maxfd = -1;
	int ready = 0;
	struct stat st;
	struct timespec t;

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
		if (f->fd < 0) {
			debug("%s: closed. opening. fd: %d\n", f->name, f->fd);
			f->fd = open(f->name, O_RDONLY | O_NONBLOCK);
		} else {
			debug("%s: already openned. fd: %d\n", f->name, f->fd);
		}
		if (f->fd == -1) {
			/* TODO: Consider backing off retries for failed fifos. */
			error("Failed to open \"%s\"\n", f->name);
			fifo_read_error(f, buf);
			continue;
		}
		debug("%s: open. fd: %d\n", f->name, f->fd);
		if (f->fd > maxfd)
			maxfd = f->fd;
		FD_SET(f->fd, &fds);
	}
	debug("selecting...\n");
	ready = pselect(maxfd + 1, &fds, NULL, NULL, ti, NULL);
	debug("ready: %d\n", ready);
	assert(ready >= 0);
	clock_gettime(CLOCK_MONOTONIC, &t);
	while (ready) {
		for (Fifo *f = cfg->fifos; f; f = f->next) {
			if (FD_ISSET(f->fd, &fds)) {
				debug("reading: %s\n", f->name);
				switch (fifo_read_one(f, t, buf)) {
				/*
				 * ### MESSAGE LOSS ###
				 * is introduced by closing at EOM in addition
				 * to EOF, since there may be unread messages
				 * remaining in the pipe. However,
				 *
				 * ### INTER-MESSAGE PUSHBACK ###
				 * is also gained, since pipes block at the
				 * "open" call.
				 *
				 * This is an acceptable trade-off because we
				 * are a stateless reporter of a _most-recent_
				 * status, not a stateful accumulator.
				 */
				case END_OF_MESSAGE:
				case END_OF_FILE:
				case FAILURE:
					close(f->fd);
					f->fd = -1;
					ready--;
					break;
				case RETRY:
					break;
				default:
					assert(0);
				}
			}
		}
	}
	assert(ready == 0);
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

	ti = timespec_of_float(cfg->interval);

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
		f->pos_init  += prefix;
		f->pos_final += prefix;
		f->pos_curr = f->pos_init;
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
		if (f->pos_init) {  /* Skip the first, left-most */
			/* Copying only seplen ensures we omit the '\0' byte. */
			strncpy(buf + (f->pos_init - seplen), cfg->separator, seplen);
		}
	}

	if (cfg->output_to_x_root_window && !(display = XOpenDisplay(NULL)))
		fatal("XOpenDisplay failed with: %p\n", display);
	/* TODO: Handle signals */
	for (;;) {
		clock_gettime(CLOCK_MONOTONIC, &t0); // FIXME: check errors
		fifo_read_all(cfg, &ti, buf);
		if (cfg->output_to_x_root_window) {
			if (XStoreName(display, DefaultRootWindow(display), buf) < 0)
				fatal("XStoreName failed.\n");
			XFlush(display);
		} else {
			puts(buf);
			fflush(stdout);
		}

		/*
		 * This is a good place for expiry check, since we're about to
		 * sleep anyway and the time taken by the check will be
		 * subtracted from the sleep period.
		 */
		fifo_expire_all(cfg, t0, buf);

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
		} else {
			debug("snooze NO\n");
		}
	}

	return EXIT_SUCCESS;
}
