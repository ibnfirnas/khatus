#! /usr/bin/awk -f

BEGIN {
    aliases["@energy_percent"]      = "bar_make_status_energy_percent()"
    aliases["@energy_direction"]    = "bar_make_status_energy_direction()"

    aliases["@memory_percent"]      = "bar_make_status_mem_percent()"

    aliases["@processes_count_all"] = "bar_make_status_procs_count_all()"
    aliases["@processes_count_r"]   = "bar_make_status_procs_count_r()"
    aliases["@processes_count_d"]   = "bar_make_status_procs_count_d()"
    aliases["@processes_count_t"]   = "bar_make_status_procs_count_t()"
    aliases["@processes_count_i"]   = "bar_make_status_procs_count_i()"
    aliases["@processes_count_z"]   = "bar_make_status_procs_count_z()"

    aliases["@cpu_loadavg"]         = "bar_make_status_cpu_loadavg()"
    aliases["@cpu_temp"]            = "bar_make_status_cpu_temperature()"
    aliases["@cpu_fan_speed"]       = "bar_make_status_cpu_fan_speed()"

    aliases["@disk_space"]          = "bar_make_status_disk_space()"
    aliases["@disk_io_w"]           = "bar_make_status_disk_io_w()"
    aliases["@disk_io_r"]           = "bar_make_status_disk_io_r()"

    aliases["@net_addr"]            = "bar_make_status_net_addr(\"%s\")"
     params["@net_addr"]            = 1
    aliases["@net_io_w"]            = "bar_make_status_net_io_w(\"%s\")"
     params["@net_io_w"]            = 1
    aliases["@net_io_r"]            = "bar_make_status_net_io_r(\"%s\")"
     params["@net_io_r"]            = 1
    aliases["@net_wifi"]            = "bar_make_status_net_wifi(\"%s\")"
     params["@net_wifi"]            = 1
    aliases["@net_iface_status"]    = "bar_make_status_net_iface_status(\"%s\")"
     params["@net_iface_status"]    = 1

    aliases["@bluetooth_power"]     = "bar_make_status_bluetooth_power()"

    aliases["@backlight_percent"]   = "bar_make_status_backlight_percent()"

    aliases["@volume"]              = "bar_make_status_volume_alsa_device(%d)"
     params["@volume"]              = 1

    aliases["@mpd"]                 = "bar_make_status_mpd()"

    aliases["@weather_temp_f"]      = "bar_make_status_weather_temp_f()"

    aliases["@datetime"]            = "bar_make_status_datetime()"

    out = "function bar_make_status() {\n"
    n_args = split(Status_Args, args_arr, ",")
    for (i=1; i<=n_args; i++) {
        arg = args_arr[i]
        split(arg, arg_parts, ":")
        alias = arg_parts[1]
        n_expected_params = params[alias]
        if (n_expected_params == 0) {
            function_call = aliases[alias]
        } else if (n_expected_params == 1) {
            function_call = sprintf(aliases[alias], arg_parts[2])
        # TODO: Support params > 1
        } else {
            printf(\
                "Unsupported number of params: %d in %s\n",
                n_expected_params, alias) \
                > "/dev/stderr"
            exit(1)
        }
        if (function_call) {
            args_str = args_str ", " function_call
        } else {
            printf("Unexpected status bar component alias: \"%s\"\n", alias) \
                > "/dev/stderr"
            exit(1)
        }
    }
    out = out "    return sprintf(\"" Status_Fmt "\"" args_str ");\n}";
    print out
}
