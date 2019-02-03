A single script, re-executed in a loop at some intervals, serially grabbing all
the needed data and outputting a status bar string, then passed to `xsetroot -name`,
while saving state in files (e.g. previous totals, to be converted to deltas).

This actually worked surprisingly-OK, but had limitations:

- I use an SSD and want to minimize disk writes
- not flexible-enough to support my main goal - easy experimentation with
  various ad-hoc monitors:
    - I want to set different update intervals for different data sources
    - I don't want long-running data collectors to block the main loop
