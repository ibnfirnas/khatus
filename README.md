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

Any errors encountered by any sensor are propagated as alerts by the
controller, which are in turn actualized as desktop notifications by the
actuator:
![screenshot-self-error-propagation](screenshot-self-error-propagation.jpg)
