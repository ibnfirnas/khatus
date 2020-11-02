#! /bin/sh

set -e

dir_bin="$1"

echo show | bluetoothctl | "$dir_bin"/khatus_parse_bluetoothctl_show
