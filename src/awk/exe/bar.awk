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
# Status bar
# -----------------------------------------------------------------------------

function bar_make_status_energy(    state, charge, direction_of_change) {
    cache_get(state , "khatus_sensor_energy", "battery_state"     , 0)
    cache_get(charge, "khatus_sensor_energy", "battery_percentage", 0)

    if (state["value"] == "discharging") {
        direction_of_change = "<"
    } else if (state["value"] == "charging") {
        direction_of_change = ">"
    } else {
        direction_of_change = "="
    }

    return sprintf("E%s%d%%", direction_of_change, charge["value"])
}

function bar_make_status_mem(    total, used, percent, status) {
    cache_get(total, "khatus_sensor_memory", "total", 5)
    cache_get(used , "khatus_sensor_memory", "used" , 5)
    # Checking total["value"] to avoid division by zero when data is missing
    if (!total["is_expired"] && \
        !used["is_expired"] && \
        total["value"] \
        ) {
        percent = util_round((used["value"] / total["value"]) * 100)
        status = sprintf("%d%%", percent)
    } else {
        status = "__"
    }
    return sprintf("M=%s", status)
}

function bar_make_status_procs() {
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
    #
    src = "khatus_sensor_procs"
    all = cache_get_fmt_def(src, "total_procs"            , 15, "%d")
    r   = cache_get_fmt_def(src, "total_per_state" Kfs "R", 15, "%d", "0")
    d   = cache_get_fmt_def(src, "total_per_state" Kfs "D", 15, "%d", "0")
    t   = cache_get_fmt_def(src, "total_per_state" Kfs "T", 15, "%d", "0")
    i   = cache_get_fmt_def(src, "total_per_state" Kfs "I", 15, "%d", "0")
    z   = cache_get_fmt_def(src, "total_per_state" Kfs "Z", 15, "%d", "0")
    return sprintf("P=[%s %sr %sd %st %si %sz]", all, r, d, t, i, z)
}

function bar_make_status_cpu(    l, t, f) {
    l_src = "khatus_sensor_loadavg"
    t_src = "khatus_sensor_temperature"
    f_src = "khatus_sensor_fan"
    l = cache_get_fmt_def(l_src, "load_avg_1min", 5, "%4.2f")
    t = cache_get_fmt_def(t_src, "temp_c"       , 5, "%d"   )
    f = cache_get_fmt_def(f_src, "speed"        , 5, "%4d"  )
    return sprintf("C=[%s %s°C %srpm]", l, t, f)
}

function bar_make_status_disk(    u, w, r, src_u, src_io) {
    src_u  = "khatus_sensor_disk_space"
    src_io = "khatus_sensor_disk_io"
    u = cache_get_fmt_def(src_u , "disk_usage_percentage", 10, "%s")
    w = cache_get_fmt_def(src_io, "sectors_written"      ,  5, "%0.3f")
    r = cache_get_fmt_def(src_io, "sectors_read"         ,  5, "%0.3f")
    return sprintf("D=[%s%% %s▲ %s▼]", u, w, r)
}

function bar_make_status_net(    \
    number_of_net_interfaces_to_show, \
    net_interfaces_to_show, \
    io, \
    wi, \
    i, \
    interface, \
    label, \
    wifi, \
    addr, \
    w, \
    r, \
    io_stat, \
    out, \
    sep \
) {
    number_of_net_interfaces_to_show = \
        split(Opt_Net_Interfaces_To_Show, net_interfaces_to_show, ",")
    io = "khatus_sensor_net_addr_io"
    wi = "khatus_sensor_net_wifi_status"
    out = ""
    sep = ""
    for (i = number_of_net_interfaces_to_show; i > 0; i--) {
        interface = net_interfaces_to_show[i]
        label = substr(interface, 1, 1)
        if (interface ~ "^w") {
            wifi = cache_get_fmt_def(wi, "status" Kfs interface, 10, "%s")
            label = label ":" wifi
        }
        addr = cache_get_fmt_def(io, "addr"          Kfs interface, 5, "%s", "")
        w    = cache_get_fmt_def(io, "bytes_written" Kfs interface, 5, "%0.3f")
        r    = cache_get_fmt_def(io, "bytes_read"    Kfs interface, 5, "%0.3f")
        io_stat = addr ? sprintf("%s▲ %s▼", w, r) : "--"
        out = out sep label ":" io_stat
        sep = " "
    }
    return sprintf("N[%s]", out)
}

function bar_make_status_bluetooth(    src, key) {
    src = "khatus_sensor_bluetooth_power"
    key = "power_status"
    return sprintf("B=%s", cache_get_fmt_def(src, key, 10, "%s"))
}

function bar_make_status_screen_brightness(    src, key) {
    src = "khatus_sensor_screen_brightness"
    key = "percentage"
    return sprintf("*%s%%", cache_get_fmt_def(src, key, 5, "%d"))
}

function bar_make_status_volume(    sink, mu, vl, vr, show) {
    sink = Opt_Pulseaudio_Sink
    cache_get(mu, "khatus_sensor_volume", "mute"      Kfs sink, 5)
    cache_get(vl, "khatus_sensor_volume", "vol_left"  Kfs sink, 5)
    cache_get(vr, "khatus_sensor_volume", "vol_right" Kfs sink, 5)
    show = "--"
    if (!mu["is_expired"] && !vl["is_expired"] && !vr["is_expired"]) {
             if (mu["value"] == "yes") {show = "X"}
        else if (mu["value"] == "no")  {show = vl["value"] " " vr["value"]}
        else {
            msg_out_error(\
                "bar_make_status_volume", \
                "Unexpected value for 'mute' field: " mu["value"] \
            )
        }
    }
    return sprintf("(%s)", show)
}

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

    return sprintf("[%s]", status)
}

function bar_make_status_mpd_state_known(symbol,    s, song, time, percentage) {
    s = "khatus_sensor_mpd"
    song    = cache_get_fmt_def(s, "song"                   , 5, "%s", "?")
    time    = cache_get_fmt_def(s, "play_time_minimal_units", 5, "%s", "?")
    percent = cache_get_fmt_def(s, "play_time_percentage"   , 5, "%s", "?")
    song    = substr(song, 1, Opt_Mpd_Song_Max_Chars)
    return sprintf("%s %s %s %s", symbol, time, percent, song)
}

function bar_make_status_weather(    src, hour, t_f) {
    src = "khatus_sensor_weather"
    hour = 60 * 60
    t_f = cache_get_fmt_def(src, "temperature_f", 3 * hour, "%d")
    return sprintf("%s°F", t_f)
}

function bar_make_status_datetime(    dt) {
    return cache_get_fmt_def("khatus_sensor_datetime", "datetime", 5, "%s")
}
