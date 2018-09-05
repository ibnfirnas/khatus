BEGIN {
    FS1 = "|"  # Fiels separator, level 1 (record to fields)
    FS2 = ":"  # Fiels separator, level 2 (field to subfields)

     FS = FS1
    Kfs = FS2
}

function msg_in_parse(msg, line,    fields, type) {
    split(line, fields, FS1)
    msg["node"]   = fields[1]
    msg["module"] = fields[2]
    type          = fields[3]
    msg["type"]   = type

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
            "msg_in_parse",
            "Unexpected msg type: " type " in given input line: " line \
        )
        exit 1
    }
}
