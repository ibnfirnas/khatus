# When parsing 'upower --dump'
/^Device:[ \t]+/ {
    device["path"] = $2
    next
}

# When parsing 'upower --monitor-detail'
/^\[[0-9]+:[0-9]+:[0-9]+\.[0-9]+\][ \t]+device changed:[ \t]+/ {
    device["path"] = $4
    next
}

# BEGIN battery
/  battery/ && device["path"] {
    device["is_battery"] = 1
    next
}

/    state:/ && device["is_battery"] {
    device["battery_state"] = $2
    next
}

/    percentage:/ && device["is_battery"] {
    device["battery_percentage"] = $2
    sub("%$", "", device["battery_percentage"])
    next
}

/^$/ && device["is_battery"] {
    print("battery_state"     , device["battery_state"])
    print("battery_percentage", device["battery_percentage"])
}
# END battery

# BEGIN line-power
/  line-power/ && device["path"] {
    device["is_line_power"] = 1
    next
}

/    online:/ && device["is_line_power"] {
    device["line_power_online"] = $2
    next
}

/^$/ && device["is_line_power"] {
    print("line_power", device["line_power_online"])
}
# END line-power

/^$/ {
    delete device
    next
}
