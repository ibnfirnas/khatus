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

/  native-path:/ && device["path"] {
    device["native_path"] = $2
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

/    energy:/ && device["is_battery"] {
    device["energy"] = $2
    next
}

/    energy-full:/ && device["is_battery"] {
    device["energy_full"] = $2
    next
}

/    percentage:/ && device["is_battery"] {
    device["battery_percentage"] = $2
    sub("%$", "", device["battery_percentage"])
    next
}

/^$/ && device["is_battery"] {
    print("battery_state"     , aggregate_battery_state())
    print("battery_percentage", aggregate_battery_percentage())
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

function aggregate_battery_percentage(    bat, curr, full) {
    _battery_energy[device["native_path"]] = device["energy"]
    _battery_energy_full[device["native_path"]] = device["energy_full"]
    for (bat in _battery_energy) {
        curr = curr + _battery_energy[bat]
        full = full + _battery_energy_full[bat]
    }
    return ((curr / full) * 100)
}

function aggregate_battery_state(    curr, bat, new) {
    _battery_state[device["native_path"]] = device["battery_state"]
    curr = device["battery_state"]
    for (bat in _battery_state) {
        new = _battery_state[bat]
        if (new == "discharging") {
            curr = new
        } else if (curr != "discharging" && new == "charging") {
            curr = new
        }
    }
    return curr
}
