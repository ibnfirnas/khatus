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

| Name   | Status   | Language  | Tested-on               | Description |
|--------|----------|-----------|-------------------------|-------------|
| __x1__ | Archived | Bash, AWK |            Ubuntu 16.04 | Single, synchronous script, saving state in text files. |
| __x2__ | Archived | Bash, AWK | Debian 10, Ubuntu 18.04 | Sensors are child processes, IPC via parent pipe. |
| __x3__ | Archived | OCaml     | Debian 10               | Re-write and refinement of __x2__ |
| __x4__ | Archived | Dash, AWK | Debian 10               | Sensors are opaque daemons, cache is a file tree |
| __x5__ | [Graduated](https://github.com/xandkar/pista) | C         |            Ubuntu 18.04 | Sensors are opaque daemons, IPC via [pselect](https://en.wikipedia.org/wiki/Select_(Unix))ed FIFOs. |
