#! /bin/sh

set -e

dir_bin="$1"
disk_space_device="$2"

df --output=pcent "$disk_space_device" | "$dir_bin"/khatus_parse_df_pcent
