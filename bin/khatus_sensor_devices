#! /bin/bash

set -e

dir_bin="$1"

stdbuf -o L -- \
    udevadm monitor --udev -s block \
| stdbuf -o L -- \
    "$dir_bin"/khatus_parse_udevadm_monitor_block
