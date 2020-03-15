khatus
======
![mascot](mascot.jpg)

Experimental system-monitor and status (bar) reporter I use with
[dwm](https://dwm.suckless.org/) on GNU/Linux.

![screenshot](screenshot.png)

Experiments
-----------
The approaches experimented-with so far (later versions do not _necessarily_
obsolete earlier ones, they're just different):

| Name   | Status              | Language  | Tested-on               | Description |
|--------|---------------------|-----------|-------------------------|-------------|
| __x1__ | Archive,   complete | Bash, AWK |            Ubuntu 16.04 | Single, synchronous script, saving state in text files |
| __x2__ | Legacy ,   complete | Bash, AWK | Debian 10, Ubuntu 18.04 | Parallel processes: collectors, cache and reporters; passing messages through a single named pipe |
| __x3__ | Archive, incomplete | OCaml     | Debian 10               | Re-write and refinement of __x2__ |
| __x4__ | Archive, incomplete | Dash, AWK | Debian 10               | Sensors are completely decoupled daemons, cache is a file tree |
| __x5__ | Current, incomplete | C         |            Ubuntu 18.04 | Sensors are completely decoupled daemons, writing to dedicated named pipes, bar repeatedly `select`s and reads the pipes. |
