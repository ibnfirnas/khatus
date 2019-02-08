#! /bin/sh

set -e

dir_bin="$1"

# TODO: Convert mpd sensor to watcher from poller
#       Since we can just open the connection and send periodic requests.
#
# close
#     Closes the connection to MPD. MPD will try to send the remaining output
#     buffer before it actually closes the connection, but that cannot be
#     guaranteed. This command will not generate a response.
#
#     Clients should not use this command; instead, they should just close the socket.
#
# https://www.musicpd.org/doc/html/protocol.html#connection-settings
#
echo 'status\ncurrentsong\nclose' \
| nc 127.0.0.1 6600 \
| "$dir_bin"/khatus_parse_mpd_status_currentsong
