khatus
======
![mascot](mascot.jpg)

Experimental system-monitor and status (bar) reporter I use with
[dwm](https://dwm.suckless.org/) on GNU/Linux.

![screenshot](screenshot.jpg)

Usage
-----

### Build

`make build`

### Install

To copy everything from `./bin` to `$HOME/bin`:

`make install`

### Use

In my `~/.xinitrc` I have something like the following:

```sh
( $BIN/khatus \
    --wifi_interface      'wlp3s0' \
    --interval_bluetooth  5 \
    --interval_net_wifi   5 \
    --interval_disk_space 5 \
| stdbuf -o L tee \
    >(stdbuf -o L "$BIN"/khatus_bar \
        -v Opt_Mpd_Song_Max_Chars=10 \
        -v Opt_Pulseaudio_Sink=0 \
        -v GC_Interval=1800 \
        -f <("$BIN"/khatus_gen_bar_make_status \
                -v Status_Fmt=' E=%s%% M=%d%% P=[%s %sr %sd %st %si %sz] C=[%s %s°C %srpm] D=[%s%% %s▲ %s▼] W=[%s %s▲ %s▼] B=%s *=%s%% (%s) [%s] %s°F %s ' \
                -v Status_Args='@energy_percent,@memory_percent,@processes_count_all,@processes_count_r,@processes_count_d,@processes_count_t,@processes_count_i,@processes_count_z,@cpu_loadavg,@cpu_temp,@cpu_fan_speed,@disk_space,@disk_io_w,@disk_io_r,@net_wifi:wlp3s0,@net_io_w:wlp3s0,@net_io_r:wlp3s0,@bluetooth_power,@backlight_percent,@volume_pa_sink:0,@mpd,@weather_temp_f,@datetime' \
            ) \
    | "$BIN"/khatus_actuate_status_bar_to_xsetroot_name \
    ) \
    >(stdbuf -o L "$BIN"/khatus_monitor_energy \
    | "$BIN"/khatus_actuate_alert_to_notify_send \
    ) \
    >(stdbuf -o L "$BIN"/khatus_monitor_errors \
    | "$BIN"/khatus_actuate_alert_to_notify_send \
    ) \
    >(stdbuf -o L "$BIN"/khatus_monitor_devices \
    | "$BIN"/khatus_actuate_alert_to_notify_send \
    ) \
    >(stdbuf -o L "$BIN"/khatus_actuate_device_add_to_automount \
    | "$BIN"/khatus_actuate_alert_to_notify_send \
    ) \
) \
2> >($BIN/twrap >> $KHATUS_LOGS_DIR/main.log) \
1> /dev/null \
&
```
(where `twrap` is a simple script which prefixes a timestamp to each line)

The idea is to support appending any number of ad-hoc, experimental monitors by
giving maximum flexibility for what to do with the sensor outputs, while
maintaining some uniformity of msg formats (again, to ease ad-hoc combinations
(e.g. Does the CPU get hotter when MPD is playing Wu-Tang?)).  `khatus_bar`,
`khatus_monitor_energy` and `khatus_monitor_errors` are just some initial
examples.

Design
------

### 2.0

In an effort to simplify the components and their interfaces, I removed the
concept of a global controller from the previous design (which, at least for
now, is superfluous), so now it is essentially a pub-sub - parallel publishers
(sensors) write to a pipe, which is then copied to any number of interested
subscribers that can filter-out what they need and then do whatever they want
with the data. Status bar is one such subscriber:

`P1 > pipe&; P2 > pipe&; ... PN > pipe&; tail -f pipe | tee >(S1) >(S2) ... >(SN) > /dev/null`

The cool thing is that, because the pipe is always read (`tail -f ... > /dev/null`),
the publishers are never blocked, so we get a live stream of events to which we
can attach any number of interested subscribers (` ... tee ... `) and, because
the pipe is named, if a subscriber needs to - it too can publish something to
the pipe without being blocked.

```
parallel    +----------+  +----------+          +----------+
stateless   | sensor_1 |  | sensor_2 |    ...   | sensor_n |
collectors  +----------+  +----------+          +----------+
                 |             |           |         |
               data          data        data      data
                 |             |           |         |
                 V             V           V         V
multiplexing     +-------------+-----------+---------+
to a pipe                      |
                               |
                               V
copying to       +-------------+-+---------+---------+
subscribers      |               |         |         |
                 V               V         V         V
              +------------+         ...      +----------------+
any number of | status bar |                  | energy monitor |
parallel      +------------+                  +----------------+
subscribers      |                                    |
                 V                                    V
              +----------------+              +-------------+
              | xsetroot -name |              | notify-send |
              +----------------+              +-------------+
```

### 1.0

This was an improvement of having everything in one script, but the controller
was still way too complicated for no good reason.

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

### 0.x

A single script, re-executed in a loop at some intervals, serially grabbing all
the needed data and outputting a status bar string, then passed to `xsetroot -name`,
while saving state in files (e.g. previous totals, to be converted to deltas).

This actually worked surprisingly-OK, but had limitations:

- I use an SSD and want to minimize disk writes
- not flexible-enough to support my main goal - easy experimentation with
  various ad-hoc monitors:
    - I want to set different update intervals for different data sources
    - I don't want long-running data collectors to block the main loop

### Actuator
Actuator is anything that takes action upon controller messages. A few generic
ones are included:

- `khatus_actuate_alert_to_notify_send`
- `khatus_actuate_status_bar_to_xsetroot_name`

and, by default, are left disconnected from the data feed, so if desired - need
to be manually attached when starting `khatus`. See usage section.

### Errors
Any errors encountered by any sensor are propagated as alerts by the
controller, which are in turn actualized as desktop notifications by the
`khatus_actuate_alert_to_notify_send` actuator:

![screenshot-self-error-propagation](screenshot-self-error-propagation.jpg)

FIXME
-----
- handle multiple batteries

TODO
----

- formalize message format and protocol
- tests (design is starting to take shape, so it is time)
- show how many Debian package updates are available
- show how many Debian package security-updates are available
- monitor disk usage rate of change and alert if suspiciously fast
- bring back CPU usage monitor
- actual METAR parser, to replace the flaky `metar` program
- status bar templating language
- retry/cache for sensors fetching flaky remote resources (such as weather)
- throttling of broken sensors (constantly returns errors)
- alert specification language
    - trigger threshold
    - above/bellow/equal to threshold value
    - priority
    - snooze time (if already alerted, when to re-alert?)
    - text: subject/body
- monitor processes
    - totals (grand and per state)
    - zombies
    - threads
    - CPU hogs
    - memory hogs
    - memory leaks (if some process consistently grows)
    - is select process up?
    - log resource usage of select processes
- monitor arbitrary HTTP endpoint availability
    - is status within expected range?
    - response time
        - is responce time within acceptable range?
- report detailed status upon request (to a terminal)
    - use color to indicate age of data
- monitor logins
    - totals (per time period)
        - failures
        - successes
    - most recent
        - success
        - failure
- monitor battery time remaining
    - monitor accuracy (is percentage change rate on track to meet estimate?)
    - adjust estimate based on observed inaccuracies in past estimates (Kalman?)

Redesign notes
--------------

- controller should not do formatting
- need in-memory db for diskless feedback/throttling and cache
- decouple sensor execution from sleep, i.e. a sensor is blocked not by sleep
  process directly, but by reading of a pipe, to where a sleep process will
  write a message announcing interval completion and thus signaling execution.
  This will allow us to manually signal a sensor to update (concretely - I just
  openned my laptop from sleep and want to force the weather to update
  immediately); likewise, the sleep process should be blocked on pipe-read
  until sensor execution is complete - this will allow us to reconfigure
  intervals at runtime (which seems like a better idea than the above in-memory
  DB one).

Idea grab bag
-------------

- track devices:
    - alert when never before seen device is plugged-in
    - report history and trends on when and how-often each
      device/category is plugged-in, how-long it stays plaugged-in, etc.
- daemonize `khatus`, so we don't have to re-launch `X11` to re-launch `khatus`
- interoperate with other khatus nodes
    - prefix machine ID to each data source
      (What should that ID be? Hostname? Pub key?)
    - fetch remote data and process locally
    - what transport to use?
        - ssh + rsync + cache dumps per some interval?
    - `A` can setup self penetration testing, by setting up probe of `A` on `B`
      and fetching results from `B` to `A`
- offline mode - quick disable all network-using subsystems (sensors, monitors, etc)
- classify each sensor as either "local" or "remote" (what about `iwconfig`, et al?)
- store data with rrdtool
- some kind of personal calendar thing integration
- monitor tracking numbers (17track should be easiest to get started with)
- monitor password digests against known leaked password databases
- monitor stock prices
- monitor some item price(s) at some store(s) (Amazon, etc.)
    - https://docs.aws.amazon.com/AWSECommerceService/latest/DG/EX_RetrievingPriceInformation.html
    - https://docs.aws.amazon.com/AWSECommerceService/latest/DG/ReturningPrices.html
    - https://developer.amazonservices.com/
- monitor Amazon order status
    - https://developer.amazonservices.com/gp/mws/api.html?group=orders&section=orders
- monitor eBay order status
    - http://developer.ebay.com/DevZone/XML/docs/Reference/eBay/GetOrders.html
- monitor eBay auctions (https://en.wikipedia.org/wiki/EBay_API)
- monitor PayPal (https://www.programmableweb.com/api/paypal)
- monitor bank account balance and transactions
    - https://communities.usaa.com/t5/Banking/Banking-via-API-Root/m-p/180789/highlight/true#M50758
    - https://plaid.com/
    - https://plaid.com/docs/api/
    - https://plaid.com/docs/api/#institution-overview
    - https://github.com/plaid
    - https://www.bignerdranch.com/blog/online-banking-apis/
- monitor/log road/traffic conditions
    - travel times for some route over a course of time
    - https://msdn.microsoft.com/en-us/library/hh441725
    - https://cloud.google.com/maps-platform/
    - https://cloud.google.com/maps-platform/routes/
    - https://developer.mapquest.com/documentation/traffic-api/
    - https://developer.here.com/api-explorer/rest/traffic/traffic-flow-bounding-box
- monitor news sources for patterns/substrings
    - http://developer.nytimes.com/
    - https://news.ycombinator.com/
    - https://lobste.rs/
    - https://www.undeadly.org/
    - http://openbsdnow.org/
    - https://lwn.net/
- monitor a git repository
    - General
        - total branches
        - age of last change per branch
        - change set sizes
    - GitHub
        - pull requests
        - issues
- monitor CI
    - Travis
    - Jenkins
- pull/push data from/to other monitoring systems (Nagios, Graphite, etc.)
- monitor file/directory age (can be used for email and other messaging systems)
- monitor mailboxes for particular patterns/substrings
- monitor IRC server(s)/channel(s) for particular patterns/substrings (use `ii`)
- monitor iptables log
    - auto-(un)block upon some threshold of violations
- monitor changes in an arbitrary web resource
    - deletions
    - insertions
    - delta = insertions - deletions
- monitor/log LAN/WAN configurations (address, router, subnet)
- monitor/log geolocation based on WAN IP address
- correlate iptables violations with network/geolocation
- monitor vulnerability databases
    - https://nvd.nist.gov/
    - https://vuldb.com/
    - http://cve.mitre.org/
- vacation planning optimization
    - I want to visit a set of places within some time period. Given the
      current set of prices, a set of constraints (I need to stay some amount
      of days at each, I must be in X at Y date, etc), which visiting dates for
      each are cheapest?
- browse https://www.programmableweb.com/ for some more ideas
- GC trick: instead of actually doing GC, do a dummy run of building a status
  bar at `BEGIN`, to fill-in the atimes for keys we need, then use the atimes
  keys to build a regular expression to accept messages only from keys we
  actually use

Many of the above will undoubtedly need non-standard-system dependencies
(languages, libraries, etc.), in which case - would they be better off as
separate projects/repos?

With all these ideas, it is starting to sound very noisy, but no worries - to
quickly and temporarily shut everything up - just kill `dunst` and or toggle
the status bar (`Alt` + `B` in `dwm`). For a permanent change - just don't
turn-on the unwanted monitors/sensors.
