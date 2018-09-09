#! /bin/sh

set -e

dir_bin="$1"

pactl list sinks | "$dir_bin"/khatus_parse_pactl_list_sinks
