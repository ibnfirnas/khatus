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
$1 == "OK" {
    cache_update()
}

$1 == "OK" && \
$2 == "khatus_sensor_datetime" {
    # Code for bar_make_status is expected to be passed as an
    # additional source file, using  -f  flag.
    msg_out_ok("status_bar", bar_make_status())
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
        percent = util_round((used["value"] / total["value"]) * 100)
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

function bar_make_status_net_addr(interface,    src) {
    src = "khatus_sensor_net_addr_io"
    return cache_get_fmt_def(src, "addr" Kfs interface, 5, "%s", "")
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

# -----------------------------------------------------------------------------
# Bluetooth
# -----------------------------------------------------------------------------

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

function bar_make_status_volume_pulseaudio_sink(sink,    mu, vl, vr, show) {
    cache_get(mu, "khatus_sensor_volume", "mute"      Kfs sink, 5)
    cache_get(vl, "khatus_sensor_volume", "vol_left"  Kfs sink, 5)
    cache_get(vr, "khatus_sensor_volume", "vol_right" Kfs sink, 5)
    show = "--"
    if (!mu["is_expired"] && !vl["is_expired"] && !vr["is_expired"]) {
             if (mu["value"] == "yes") {show = "X"}
        else if (mu["value"] == "no")  {show = vl["value"] " " vr["value"]}
        else {
            msg_out_error(\
                "bar_make_status_volume_pulseaudio_sink: " sink ". ", \
                "Unexpected value for 'mute' field: " mu["value"] \
            )
        }
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
            status = bar_make_status_mpd_state_known("❚❚")
        } else if (state["value"] == "stop") {
            status = bar_make_status_mpd_state_known("⬛")
        } else {
            msg_out_error(\
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
    song    = cache_get_fmt_def(s, "song"                   , 5, "%s", "?")
    time    = cache_get_fmt_def(s, "play_time_minimal_units", 5, "%s", "?")
    percent = cache_get_fmt_def(s, "play_time_percentage"   , 5, "%s", "?")
    song    = substr(song, 1, Opt_Mpd_Song_Max_Chars)
    return sprintf("%s %s %s %s", symbol, time, percent, song)
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
