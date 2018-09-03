BEGIN {
    # TODO: Read spec from a file
    bat_alert_spec[100] = "low|Energy_Bellow_Full|Must have perfection!"
    bat_alert_spec[50] = "low|Energy_Bellow_Half|Where is the charger?"
    bat_alert_spec[20] = "med|Energy_Low|Get the charger."
    bat_alert_spec[15] = "med|Energy_Low|Get the charger!"
    bat_alert_spec[10] = "hi|Energy_Low|Plug it in, ASAP!"
    bat_alert_spec[5]  = "hi|Energy_CRITICALLY_Low|CHARGE NOW!!! GO GO GO!!!"
}

$1 == "OK" && \
$2 == "khatus_sensor_energy" && \
$3 == "line_power" {
    line_power_prev = line_power_curr
    line_power_curr = $4
    if (line_power_curr == "no" && line_power_prev != "no") {
        msg_out_ok_alert("low", "PowerUnplugged", "")
    }
}

$1 == "OK" && \
$2 == "khatus_sensor_energy" && \
$3 == "battery_state" {
    battery_state_prev = battery_state_curr
    battery_state_curr = $4
}

$1 == "OK" && \
$2 == "khatus_sensor_energy" && \
$3 == "battery_percentage" {
    # TODO: Re-think the spec - can't rely on order of keys
    battery_percentage = util_ensure_numeric($4)
    if (battery_state_curr == "discharging") {
        for (threshold in bat_alert_spec) {
            threshold = util_ensure_numeric(threshold)
            if (battery_percentage <= threshold && !_alerted[threshold]) {
                split(bat_alert_spec[threshold], msg, "|")
                priority = msg[1]
                subject = msg[2]
                body = sprintf("%d%% %s", battery_percentage, msg[3])
                msg_out_ok_alert(priority, subject, body)
                _alerted[threshold]++
            }
        }
    } else {
        delete _alerted
    }
}
