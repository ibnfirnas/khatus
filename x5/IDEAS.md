IPC
---

### 1 file per sensor
A sensor writes to a file, bar reads it.

#### problems
- Race condition: a sensor's message needs multiple `write` calls to complete
  and bar reads in between those calls.

This might not be so bad in practice, since we expect sensor messages to be
small and this to complete in a single `write` call.


### 1 pipe per sensor
A sensor produces a message to a named pipe, bar consumes it.

#### problems
- Cannot accommodate multiple readers (besides bar, I want other tools to be
  able to read sensor data, like the `today` script (akin to `motd`));
- Writer blocked when no consumers, though this is irrelevant since only 1
  consumer is possible :)


### N pipes per sensor
A sensor monitors a `subscribers` directory for named pipes and produces
messages for all subscribers.

#### problems
- Reader blocked (which is fine for bar, but not for today/motd)


### 1 file + lock per sensor

#### problems
- Lock contentions


### 1 pipe + 1 file per sensor
A sensor writes message to file, then to pipe, bar reads pipe, others can read
file.
