#! /bin/sh

set -e

dir_bin="$1"
wifi_interface="$2"

iwconfig "$wifi_interface" \
| "$dir_bin"/khatus_parse_iwconfig -v requested_interface="$wifi_interface"
