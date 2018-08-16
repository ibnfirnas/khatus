#! /bin/sh

set -e

dir_bin="$1"

stdbuf -o L upower --dump           | stdbuf -o L "$dir_bin"/khatus_parse_upower
stdbuf -o L upower --monitor-detail | stdbuf -o L "$dir_bin"/khatus_parse_upower
