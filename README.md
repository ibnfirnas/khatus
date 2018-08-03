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

### Actuator
By default, actuator is left disconnected from the controller's output, so if
desired - it needs to be manually attached when starting `khatus`. For example,
in my `.xinitrc` I have:

```sh
$BIN/khatus \
2> >($BIN/twrap.sh >> $HOME/var/log/khatus.log) \
| $BIN/khatus_actuator \
    -v pid="$$" \
    -v display=":0" \
2> >($BIN/twrap.sh >> $HOME/var/log/khatus-actuator.log) \
&
```

(`twrap.sh` is a simple script which prefixes a timestamp to each line)

The idea is to later have multiple, (some more-general and some more-specific)
actuators which can be selected as needed, say for example:

```sh
$BIN/khatus \
| tee \
>(awk '/^STATUS_BAR/ {sub("^" $1 " *", ""); system("xsetroot -name \" " $0 " \"")}') \
>(grep '^REPORT' | actuate_report_to_email) \
>(grep '^ALERT' | grep mpd | actuate_alert_to_email) \
>(grep '^ALERT' | grep IntrusionAttempt | actuate_intruder_to_iptables_drop) \
>(grep '^ALERT' | grep NewDevice | actuate_alert_to_notify_send)
>(grep '^ALERT' | grep DiskError | actuate_call_mom)
```

... and/or any other such fun you might imagine.

### Errors
Any errors encountered by any sensor are propagated as alerts by the
controller, which are in turn actualized as desktop notifications by the
actuator:

![screenshot-self-error-propagation](screenshot-self-error-propagation.jpg)
