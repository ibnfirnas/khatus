#! /bin/sh

set -e

# TODO: Centralize the definitions of the constants, as in AWK code.
FS1='|'  # Fields separator, level 1 (a record's fields)
FS2=':'  # Fields separator, level 2 (a field's subfields)

count_powered_controllers() {
    echo show | bluetoothctl | grep -c 'Powered: yes'
}

count_connected_devices() {
    echo paired-devices \
    | bluetoothctl \
    | awk '/^Device +[0-9a-zA-Z][0-9a-zA-Z]:/ {print $2}' \
    | xargs -I % sh -c 'echo info % | bluetoothctl' \
    | grep -c 'Connected: yes'
}

printf "%s%s%d\n" 'count_powered_controllers' "$FS1" "$(count_powered_controllers)"
printf "%s%s%d\n" 'count_connected_devices'   "$FS1" "$(count_connected_devices)"
