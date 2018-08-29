$1 == "OK" && \
$2 == "khatus_sensor_devices" \
{
    alert("low", "BlockDeviceEvent", $3 " " $4)
}
