#! /bin/sh

set -e

thermal_zone="$1"

awk '
    BEGIN {
        OFS = msg_fs ? msg_fs : "|"
        Kfs = key_fs ? key_fs : ":"
    }

    {print("temp_c", $1 / 1000)}
' \
"/sys/class/thermal/thermal_zone${thermal_zone}/temp"
