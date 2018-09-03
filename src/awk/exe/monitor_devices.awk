$1 == "OK" && \
$2 == "khatus_sensor_devices" \
{
    msg_out_ok_alert("low", "BlockDeviceEvent", $3 " " $4)
}
