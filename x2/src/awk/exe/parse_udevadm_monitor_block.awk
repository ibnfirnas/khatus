BEGIN {
    Re_Begin = "^UDEV + \[ *[0-9]+\.[0-9]+\] +"
}

($0 ~ Re_Begin) {
    handle_event($0)
    next
}

function handle_event(payload,    payload_parts, event,
                                  path, n_path_parts,
                                  devname \
) {
    sub(Re_Begin, "", payload)
    split(payload, payload_parts, " +")
    event = payload_parts[1]
    path = payload_parts[2]
    if (event == "add" || event == "change") {
        devname = devname_lookup(path)
    } else {
        n_path_parts = split(path, path_parts, "/")
        devname = path_parts[n_path_parts]
    }
    print(event, devname)
}

function devname_lookup(path,    cmd, line_parts, devname) {
    cmd = "udevadm info --path=" path
    while (cmd | getline line) {
        if (line ~ /^E: +DEVNAME/) {
            split(line, line_parts, "=")
            devname = line_parts[2]
            break
        }
    }
    close(cmd)
    return devname
}
