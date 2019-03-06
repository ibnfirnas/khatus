BEGIN {
    FS1 = "|"  # Fields separator, level 1 (record to fields)
    FS2 = ":"  # Fields separator, level 2 (field to subfields

    OFS = FS1
    Kfs = FS2
}

function msg_parse(msg, line,    status, fields, type) {
    split(line, fields, FS1)
    msg["node"]   = fields[1]
    msg["module"] = fields[2]
    type          = fields[3]
    msg["type"]   = type

    status = 1
    if (type == "data") {
        msg["key"] = fields[4]
        msg["val"] = str_tail(str_join(fields, 1, 4, FS1) FS1, line)
    } else if (type == "error") {
        msg["line"] = str_tail(str_join(fields, 1, 3, FS1) FS1, line)
    } else if (type == "alert") {
        msg["priority"] = fields[4]
        msg["subject"]  = fields[5]
        msg["body"]     = str_tail(str_join(fields, 1, 5, FS1) FS1, line)
    } else if (type == "log") {
        msg["location"] = fields[4]
        msg["level"]    = fields[5]
        msg["msg"]      = str_tail(str_join(fields, 1, 5, FS1) FS1, line)
    } else if (type == "status_bar") {
        msg["status_bar"] = str_tail(str_join(fields, 1, 3, FS1) FS1, line)
    } else {
        msg_out_log_error(\
            "msg_parse",
            "Unexpected msg type: " type " in given input line: " line \
        )
        status = 0
    }
    return status
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
