$2 == "khatus_sensor_devices" && \
$3 == "data" \
{
    delete msg
    msg_in_parse(msg, $0)
    msg_out_alert_low( \
        "BlockDeviceEvent",
        msg["key"] " " msg["val"] " on " msg["node"]\
    )
}
