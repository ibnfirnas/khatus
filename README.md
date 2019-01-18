khatus
======
![mascot](mascot.jpg)

Experimental system-monitor and status (bar) reporter I use with
[dwm](https://dwm.suckless.org/) on GNU/Linux.

![screenshot](screenshot.jpg)

The approaches experimented-with so far, numbered in chronological order of
origin (i.e. later versions do not _necessarily_ obsolete earlier ones, they're
just different):

### v1
A single, synchronous script, saving state in text files (Bash and AWK).

### v2
Parallel processes: collectors, cacher and reporters; passing messages over pipes
(Bash and AWK).

### v3
Clean-up, polish and further development of main ideas learned in v2.
