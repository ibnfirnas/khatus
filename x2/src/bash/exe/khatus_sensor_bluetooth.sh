#! /bin/sh

set -e

# TODO: Centralize the definitions of the constants, as in AWK code.
FS1='|'  # Fields separator, level 1 (a record's fields)
FS2=':'  # Fields separator, level 2 (a field's subfields)

count_powered_controllers() {
    bluetoothctl -- show | grep -c 'Powered: yes'
}

count_connected_devices() {
    bluetoothctl -- paired-devices \
    | awk '{print $2}' \
    | xargs -I % bluetoothctl -- info % \
    | grep -c 'Connected: yes'
}

printf "%s%s%d\n" 'count_powered_controllers' "$FS1" "$(count_powered_controllers)"
printf "%s%s%d\n" 'count_connected_devices'   "$FS1" "$(count_connected_devices)"
