khatus
======
![mascot](mascot.jpg)

Experimental, system monitor and status (bar) reporter I use with
[dwm](https://dwm.suckless.org/) on GNU/Linux.

![screenshot](screenshot.jpg)


Design
------

```
 parallel   +----------+  +----------+     +----------+
 stateless  | sensor_1 |  | sensor_2 | ... | sensor_n |
 collectors +----------+  +----------+     +----------+
                |             |                 |
              data          data              data
                |             |                 |
                V             V                 V
 serial     +-----------------------------------------+
 stateful   |              controller                 |
 observer   +-----------------------------------------+
                              |
                          decisions
                              |
                              V
 serial     +-----------------------------------------+
 stateless  |              actuator                   |
 executor   +-----------------------------------------+
                              |
                        system commands
                              |
                              V
                            ~~~~~~
                            ~ OS ~
                            ~~~~~~
```
