#! /bin/sh

set -e

dir_bin="$1"

echo 'status\ncurrentsong' \
| nc 127.0.0.1 6600 \
| "$dir_bin"/khatus_parse_mpd_status_currentsong
