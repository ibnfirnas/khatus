#! /bin/sh

set -e

screen_brightness_device_path="$1"

awk '
    BEGIN {
        OFS = msg_fs ? msg_fs : "|"
        Kfs = key_fs ? key_fs : ":"
    }

    FILENAME ~ "/max_brightness$" {max = $1; next}
    FILENAME ~     "/brightness$" {cur = $1; next}
    END                           {print("percentage", (cur / max) * 100)}
' \
"$screen_brightness_device_path/max_brightness" \
"$screen_brightness_device_path/brightness"
