BEGIN {
    FS1 = "|"  # Fiels separator, level 1 (record to fields)
    FS2 = ":"  # Fiels separator, level 2 (field to subfields

    OFS = FS1
    Kfs = FS2
}

# -----------------------------------------------------------------------------
# alert
# -----------------------------------------------------------------------------
function msg_out_alert_low(subject, body) {
    msg_out_alert("low", subject, body)
}

function msg_out_alert_med(subject, body) {
    msg_out_alert("med", subject, body)
}

function msg_out_alert_hi(subject, body) {
    msg_out_alert("hi", subject, body)
}

function msg_out_alert(priority, subject, body) {
    # priority : "low" | "med" | "hi"
    # subject  : string without spaces
    # body     : anything
    print(Node, Module, "alert", priority, subject, body)
}

# -----------------------------------------------------------------------------
# log
# -----------------------------------------------------------------------------
function msg_out_log_info(location, msg) {
    msg_out_log("info", location, msg)
}

function msg_out_log_error(location, msg) {
    msg_out_log("error", location, msg)
}

function msg_out_log(level, location, msg) {
    print(Node, Module, "log", location, level, msg) > "/dev/stderr"
}

# -----------------------------------------------------------------------------
# status_bar
# -----------------------------------------------------------------------------
function msg_out_status_bar(bar) {
    print(Node, Module, "status_bar", bar)
}

# -----------------------------------------------------------------------------
# data
# -----------------------------------------------------------------------------
function msg_out_data(key, val) {
    print(Node, Module, "data", key, val)
}
