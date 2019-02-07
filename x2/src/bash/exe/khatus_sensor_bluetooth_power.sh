#! /bin/sh

set -e

dir_bin="$1"

bluetoothctl -- show | "$dir_bin"/khatus_parse_bluetoothctl_show
