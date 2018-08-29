BEGIN {
    # Typically some file manager (thunar, pcmanfm, etc.), but can be whatever.
    Execute_On_Mount = Execute_On_Mount ? Execute_On_Mount : ""
}

$1 == "OK" && \
$2 == "khatus_sensor_devices" && \
$3 == "add" && \
$4 ~ /[0-9]$/ {
    mount_device($4)
}

function mount_device(path,    cmd, line, lines, line_count, status, i,
                               path_dev, path_mnt) {
    cmd="udisksctl mount --block-device " path " --no-user-interaction; echo $?"
    while(cmd | getline line) {
        lines[++line_count] = line
    }
    close(cmd)
    status = lines[line_count]
    line_count--
    if (status == 0) {
        for (i=1; i<=line_count; i++) {
            line = lines[i]
            if (line ~ /^Mounted /) {
                split(line, parts, " +")
                path_dev=parts[2]
                path_mnt=line
                sub("^Mounted " path_dev " at ", "", path_mnt)
                sub("\.$", "", path_mnt)
                alert("low", "successfully-mounted", path_dev " to " path_mnt)
                if (Execute_On_Mount) {
                    system(Execute_On_Mount " '" path_mnt "'")
                }
            } else {
                alert("hi", "unexpected-success-line", line)
            }
        }
    } else {
        alert("hi", "failed-to-mount-device", path)
    }
}
