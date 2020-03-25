#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "khatus_lib_log.h"
#include "khatus_lib_sensor.h"
#include "khatus_lib_time.h"

void
loop(
    struct timespec *ti,
    char *fifo,
    char *buf,
    int fun(char *, void *),
    void *params)
{
	int fd = -1;
	int w  = -1;  /* written */
	int r  = -1;  /* remaining */
	int i  = -1;  /* buffer position */

	for (;;) {
		debug("openning \"%s\"\n", fifo);
		fd = open(fifo, O_WRONLY);
		if (fd < 0)
			fatal("Failed to open FIFO file: \"%s\". Error: %s\n",
			    fifo,
			    strerror(errno));
		debug("openned. fd: %d\n", fd);
		r = fun(buf, params);
		buf[r] = END_OF_MESSAGE;
		for (i = 0; (w = write(fd, buf + i++, 1)) && r; r--)
			;
		if (w < 0)
			switch (errno) {
			case EPIPE:
				error("Broken pipe. Msg buf: %s\n", buf);
				break;
			default:
				fatal(
				    "Failed to write to %s. "
				    "Err num: %d, Err msg: %s\n",
				    fifo,
				    errno,
				    strerror(errno));
			}
		if (close(fd) < 0)
			fatal("Failed to close %s. Err num: %d, Err msg: %s\n",
			    fifo,
			    errno,
			    strerror(errno));
		fd = -1;
		debug("closed. fd: %d\n", fd);
		snooze(ti);
	}
}
