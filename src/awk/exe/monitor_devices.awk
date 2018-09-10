{
  delete msg
  msg_parse(msg, $0)
}

msg["module"] == "khatus_sensor_devices" && \
msg["type"]   == "data" \
{
    msg_out_alert_low( \
        "BlockDeviceEvent",
        msg["key"] " " msg["val"] " on " msg["node"]\
    )
}
