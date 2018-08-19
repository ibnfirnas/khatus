#! /bin/sh

set -e

dir_bin="$1"
disk_io_device="$2"

"$dir_bin"/khatus_parse_sys_block_stat "/sys/block/$disk_io_device/stat"
