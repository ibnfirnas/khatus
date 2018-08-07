khatus
======
![mascot](mascot.jpg)

Experimental, system monitor and status (bar) reporter I use with
[dwm](https://dwm.suckless.org/) on GNU/Linux.

![screenshot](screenshot.jpg)


Design
------

```
parallel    +----------+  +----------+          +----------+
stateless   | sensor_1 |  | sensor_2 |    ...   | sensor_n |
collectors  +----------+  +----------+          +----------+
                 |             |           |         |
               data          data        data      data
                 |             |           |         |
                 V             V           V         V
serial      +----------------------------------------------+
stateful    |                controller                    |
observer    +----------------------------------------------+
                               |
                       decision messages
decision                       |
messages                       |
copied to                      |
any number                     |
of interested                  |
filter/actuator                |
combinations                   |
                               |
                               V
                 +-------------+-+---------+---------+
                 |               |         |         |
                 V               V         V         V
parallel    +------------+ +------------+     +------------+
stateless   | filter_1   | | filter_2   | ... | filter_n   |
filters     +------------+ +------------+     +------------+
                 |               |         |         |
                 V               V         V         V
parallel    +------------+ +------------+     +------------+
stateless   | actuator_1 | | actuator_2 | ... | actuator_n |
executors   +------------+ +------------+     +------------+
                 |              |          |         |
              commands       commands   commands  commands
                 |              |          |         |
                 V              V          V         V
            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            ~~~~~~~~~~~~~ operating system ~~~~~~~~~~~~~~~~~
            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

### Actuator
Actuator is anything that takes action upon controller messages. A few generic
ones are included:

- `khatus_actuate_alert_to_notify_send`
- `khatus_actuate_status_bar_to_xsetroot_name`

and, by default, are left disconnected from the controller's output, so if
desired - it needs to be manually attached when starting `khatus`. For example,
in my `.xinitrc` I have:

```sh
$BIN/khatus \
2> >($BIN/twrap >> $HOME/var/log/khatus.log) \
| tee \
    >($BIN/khatus_actuate_status_bar_to_xsetroot_name) \
    >(grep -v MpdNowPlaying | $BIN/khatus_actuate_alert_to_notify_send) \
2> >($BIN/twrap >> $HOME/var/log/khatus-actuators.log) \
&
```
(where `twrap` is a simple script which prefixes a timestamp to each line)

The idea is to give maximum flexibility for what to do with the controller
output, say, for instance:

```sh
$BIN/khatus \
| tee \
... \
>(grep '^REPORT' | actuate_report_to_email) \
>(grep '^ALERT' | grep mpd | actuate_alert_to_email) \
>(grep '^ALERT' | grep IntrusionAttempt | actuate_intruder_to_iptables_drop) \
>(grep '^ALERT' | grep NewDevice | actuate_alert_to_notify_send)
>(grep '^ALERT' | grep DiskError | actuate_call_mom)
...
```
... and so on, for any other such fun you might imagine.

### Errors
Any errors encountered by any sensor are propagated as alerts by the
controller, which are in turn actualized as desktop notifications by the
`khatus_actuate_alert_to_notify_send` actuator:

![screenshot-self-error-propagation](screenshot-self-error-propagation.jpg)

TODO
----

- retry/cache for sensors fetching flaky remote resources (such as weather)
- throttling of broken sensors (constantly returns errors)
- alert specification language
    - trigger threshold
    - above/bellow/equal to threshold value
    - priority
    - snooze time (if already alerted, when to re-alert?)
    - text: subject/body
- Reduce wireless sensor resource footprint:
    - use `nmcli monitor`, instead of polling, for state changes
    - use `iwconfig`, instead of `nmcli`, for SSID and signal strength
