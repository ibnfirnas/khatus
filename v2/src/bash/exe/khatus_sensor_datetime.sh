#! /bin/sh

set -e

date +'%s %a %b %d %H:%M:%S' \
| awk '
    BEGIN {
        OFS = msg_fs ? msg_fs : "|"
        Kfs = key_fs ? key_fs : ":"
    }

    {
        epoch = $1
        datetime = $0
        sub("^" epoch " +", "", datetime)
        print("epoch"   , epoch)
        print("datetime", datetime)
    }
    '
