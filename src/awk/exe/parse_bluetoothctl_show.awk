/^Controller / {
    controller = $2
    controllers[++ctrl_count] = controller
}

/^\t[A-Z][A-Za-z]+:/ {
    key = $1
    sub(":$", "", key)
    sub("^\t" $1 " *", "")
    val = $0
    data[controller, key] = val
}

END {
    # Using the 1st seen controller. Should we select specific instead?
    power_status = data[controllers[1], "Powered"]
    if (ctrl_count > 0) {
        if (power_status == "no") {
            show = "off"
        } else if (power_status == "yes") {
            show = "on"
        } else {
            print_error("Unexpected bluetooth power status: " power_status)
            show = "ERROR"
        }
    } else {
        show = "n/a"
    }
    print("power_status", show)
}

function print_error(msg) {
    print(msg) > "/dev/stderr"
}
