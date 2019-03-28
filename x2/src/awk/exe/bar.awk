# Naming convention:
#     Variables:
#         - global, builtin : ALLCAPS
#         - global, public  : Camel_Snake_Man_Bear_Pig
#         - global, private : _snake_case_prefixed_underscore
#         - local           : snake_case
#     Functions:
#         - global, public  : snake_case

# -----------------------------------------------------------------------------
# Input
# -----------------------------------------------------------------------------
{
  delete msg
  msg_parse(msg, $0)
}

msg["type"] == "data" {
    cache_update(msg["node"], msg["module"], msg["key"], msg["val"])
}

msg["node"]   == Node && \
msg["module"] == "khatus_sensor_datetime" && \
msg["type"]   == "data" {
    # Code for bar_make_status is expected to be passed as an
    # additional source file, using  -f  flag.
    msg_out_status_bar(bar_make_status())
}

# -----------------------------------------------------------------------------
# Energy
# -----------------------------------------------------------------------------

function bar_make_status_energy_percent() {
    return cache_get_fmt_def("khatus_sensor_energy", "battery_percentage", 0, "%d")
}

function bar_make_status_energy_direction(    state, direction_of_change) {
    cache_get(state, "khatus_sensor_energy", "battery_state", 0)
    if (state["value"] == "discharging") {
        direction_of_change = "<"
    } else if (state["value"] == "charging") {
        direction_of_change = ">"
    } else {
        direction_of_change = "="
    }
    return direction_of_change
}

# -----------------------------------------------------------------------------
# Memory
# -----------------------------------------------------------------------------

function bar_make_status_mem_percent(    total, used, percent, percent_str) {
    cache_get(total, "khatus_sensor_memory", "total", 5)
    cache_get(used , "khatus_sensor_memory", "used" , 5)
    # Checking total["value"] to avoid division by zero when data is missing
    if (!total["is_expired"] && \
        !used["is_expired"] && \
        total["value"] \
        ) {
        percent = num_round((used["value"] / total["value"]) * 100)
        percent_str = sprintf("%d", percent)
    } else {
        percent_str = "__"
    }
    return percent_str
}

# -----------------------------------------------------------------------------
# Processes
# -----------------------------------------------------------------------------
# From man ps:
#   D    uninterruptible sleep (usually IO)
#   R    running or runnable (on run queue)
#   S    interruptible sleep (waiting for an event to complete)
#   T    stopped by job control signal
#   t    stopped by debugger during the tracing
#   W    paging (not valid since the 2.6.xx kernel)
#   X    dead (should never be seen)
#   Z    defunct ("zombie") process, terminated but not reaped by its parent
#
# Additionally, not documented in ps man page:
#   I    Idle

function bar_make_status_procs_count_all() {
    return cache_get_fmt_def("khatus_sensor_procs", "total_procs", 15, "%d")
}

function bar_make_status_procs_count_r(    src) {
    src = "khatus_sensor_procs"
    return cache_get_fmt_def(src, "total_per_state" Kfs "R", 15, "%d", "0")
}

function bar_make_status_procs_count_d(    src) {
    src = "khatus_sensor_procs"
    return cache_get_fmt_def(src, "total_per_state" Kfs "D", 15, "%d", "0")
}

function bar_make_status_procs_count_t(    src) {
    src = "khatus_sensor_procs"
    return cache_get_fmt_def(src, "total_per_state" Kfs "T", 15, "%d", "0")
}

function bar_make_status_procs_count_i(    src) {
    src = "khatus_sensor_procs"
    return cache_get_fmt_def(src, "total_per_state" Kfs "I", 15, "%d", "0")
}

function bar_make_status_procs_count_z(    src) {
    src = "khatus_sensor_procs"
    return cache_get_fmt_def(src, "total_per_state" Kfs "Z", 15, "%d", "0")
}

# -----------------------------------------------------------------------------
# CPU
# -----------------------------------------------------------------------------

function bar_make_status_cpu_loadavg(    src) {
    src = "khatus_sensor_loadavg"
    return cache_get_fmt_def(src, "load_avg_1min", 5, "%4.2f")
}

function bar_make_status_cpu_temperature() {
    return cache_get_fmt_def("khatus_sensor_temperature", "temp_c", 5, "%d")
}

function bar_make_status_cpu_fan_speed() {
    return cache_get_fmt_def("khatus_sensor_fan", "speed", 5, "%4d")
}

# -----------------------------------------------------------------------------
# Disk
# -----------------------------------------------------------------------------

function bar_make_status_disk_space(    src) {
    src = "khatus_sensor_disk_space"
    return cache_get_fmt_def(src, "disk_usage_percentage", 10, "%s")
}

function bar_make_status_disk_io_w(    src) {
    src = "khatus_sensor_disk_io"
    return cache_get_fmt_def(src, "sectors_written", 5, "%0.3f")
}

function bar_make_status_disk_io_r(    src) {
    src = "khatus_sensor_disk_io"
    return cache_get_fmt_def(src, "sectors_read", 5, "%0.3f")
}

# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------

function bar_make_status_net_iface_status(interface,    is_plugged_in) {
    # TODO: Integrate connection/address status into the symbol somehow.
    cache_get(is_plugged_in, "khatus_sensor_net_carrier", interface, 5)
    if (!is_plugged_in["is_expired"] && is_plugged_in["value"] == 1)
        return "<>"
    else
        return "--"
}

function bar_make_status_net_addr(interface,    src) {
    src = "khatus_sensor_net_addr_io"
    addr = cache_get_fmt_def(src, "addr" Kfs interface, 5, "%s")
    return addr ? addr : "--"
}

function bar_make_status_net_io_w(interface,    src) {
    src = "khatus_sensor_net_addr_io"
    return cache_get_fmt_def(src, "bytes_written" Kfs interface, 5, "%0.3f")
}

function bar_make_status_net_io_r(interface,    src) {
    src = "khatus_sensor_net_addr_io"
    return cache_get_fmt_def(src, "bytes_read" Kfs interface, 5, "%0.3f")
}

function bar_make_status_net_wifi(interface,    src) {
    src = "khatus_sensor_net_wifi_status"
    return cache_get_fmt_def(src, "status" Kfs interface, 10, "%s")
}

function bar_make_status_net_wifi_link(interface,    link) {
    cache_get(link, "khatus_sensor_net_wifi_status", "link" Kfs interface, 10)
    if (!link["is_expired"] && link["value"] > 0)
        return sprintf("%d%%", link["value"])
    else
        return "--"
}

# -----------------------------------------------------------------------------
# Bluetooth
# -----------------------------------------------------------------------------

function bar_make_status_bluetooth(    src, controllers, devices) {
    src = "khatus_sensor_bluetooth"
    controllers = cache_get_fmt_def(src, "count_powered_controllers", 10, "%d")
    devices     = cache_get_fmt_def(src, "count_connected_devices"  , 10, "%d")
    # Using %s format bellow because default value is a string
    return sprintf("%s:%s", controllers, devices)
}

function bar_make_status_bluetooth_power(    src) {
    src = "khatus_sensor_bluetooth_power"
    return cache_get_fmt_def(src, "power_status", 10, "%s")
}

# -----------------------------------------------------------------------------
# Backlight (screen brightness)
# -----------------------------------------------------------------------------

function bar_make_status_backlight_percent(    src) {
    src = "khatus_sensor_screen_brightness"
    return cache_get_fmt_def(src, "percentage", 5, "%d")
}

# -----------------------------------------------------------------------------
# Volume
# -----------------------------------------------------------------------------

function bar_make_status_volume_alsa_device(device,    m, l, r, show) {
    cache_get(m, "khatus_sensor_volume", "mute"      Kfs device, 5)
    cache_get(l, "khatus_sensor_volume", "vol_left"  Kfs device, 5)
    cache_get(r, "khatus_sensor_volume", "vol_right" Kfs device, 5)
    show = "--"
    if (!m["is_expired"] && !l["is_expired"] && !r["is_expired"]) {
        if (m["value"] == "yes")
            show = "X"
        else if (m["value"] == "no")
            show = l["value"] #" " r["value"]
        else
            msg_out_log_error(\
                "bar_make_status_volume_alsa_device: " device ". ", \
                "Unexpected value for 'mute' field: " m["value"] \
            )
    }
    return show
}

# -----------------------------------------------------------------------------
# MPD
# -----------------------------------------------------------------------------

function bar_make_status_mpd(    state, status) {
    cache_get(state, "khatus_sensor_mpd", "state", 5)
    if (!state["is_expired"] && state["value"]) {
        if (state["value"] == "play") {
            status = bar_make_status_mpd_state_known("▶")
        } else if (state["value"] == "pause") {
            status = bar_make_status_mpd_state_known("⏸")
        } else if (state["value"] == "stop") {
            status = bar_make_status_mpd_state_known("⏹")
        } else {
            msg_out_log_error(\
                "bar_make_status_mpd", \
                "Unexpected value for 'state' field: " state["value"] \
            )
            status = "--"
        }
    } else {
        status = "--"
    }
    return status
}

function bar_make_status_mpd_state_known(symbol,    s, song, time, percentage) {
    s = "khatus_sensor_mpd"
    #song    = cache_get_fmt_def(s, "song"                   , 5, "%s", "?")
    time    = cache_get_fmt_def(s, "play_time_minimal_units", 5, "%s", "?")
    percent = cache_get_fmt_def(s, "play_time_percentage"   , 5, "%s", "?")
    #song    = substr(song, 1, Opt_Mpd_Song_Max_Chars)
    return sprintf("%s %s %s", symbol, time, percent)
}

# -----------------------------------------------------------------------------
# Weather
# -----------------------------------------------------------------------------

function bar_make_status_weather_temp_f(    src, hour) {
    src = "khatus_sensor_weather"
    hour = 60 * 60
    return cache_get_fmt_def(src, "temperature_f", 3 * hour, "%d")
}

# -----------------------------------------------------------------------------
# Datetime
# -----------------------------------------------------------------------------

function bar_make_status_datetime(    dt) {
    return cache_get_fmt_def("khatus_sensor_datetime", "datetime", 5, "%s")
}
