BEGIN {
    # TODO: Read spec from a file
    bat_alert_spec[100] = "low|Energy_Bellow_Full|Must have perfection!"
    bat_alert_spec[50] = "low|Energy_Bellow_Half|Where is the charger?"
    bat_alert_spec[20] = "med|Energy_Low|Get the charger."
    bat_alert_spec[15] = "med|Energy_Low|Get the charger!"
    bat_alert_spec[10] = "hi|Energy_Low|Plug it in, ASAP!"
    bat_alert_spec[5]  = "hi|Energy_CRITICALLY_Low|CHARGE NOW!!! GO GO GO!!!"
}

{
  delete msg
  msg_parse(msg, $0)
}

msg["node"]   == Node && \
msg["module"] == "khatus_sensor_energy" && \
msg["type"]   == "data" && \
msg["key"]    == "line_power" {
    line_power_prev = line_power_curr
    line_power_curr = msg["val"]
    if (line_power_curr == "no" && line_power_prev != "no") {
        msg_out_alert_low("PowerUnplugged", "")
    }
}

msg["node"]   == Node && \
msg["module"] == "khatus_sensor_energy" && \
msg["type"]   == "data" && \
msg["key"]    == "battery_state" {
    battery_state_prev = battery_state_curr
    battery_state_curr = msg["val"]
}

msg["node"]   == Node && \
msg["module"] == "khatus_sensor_energy" && \
msg["type"]   == "data" && \
msg["key"]    == "battery_percentage" {
    # TODO: Re-think the spec - can't rely on order of keys
    battery_percentage = num_ensure_numeric(msg["val"])
    if (battery_state_curr == "discharging") {
        for (threshold in bat_alert_spec) {
            threshold = num_ensure_numeric(threshold)
            if (battery_percentage <= threshold && !_alerted[threshold]) {
                split(bat_alert_spec[threshold], alert, "|")
                priority = alert[1]
                subject = alert[2]
                body = sprintf("%d%% %s", battery_percentage, alert[3])
                msg_out_alert(priority, subject, body)
                _alerted[threshold]++
            }
        }
    } else {
        delete _alerted
    }
}
