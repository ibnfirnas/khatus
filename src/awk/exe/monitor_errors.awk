$3 == "error" {
    delete msg
    msg_in_parse(msg, $0)
    subject = "ERROR_IN_" msg["node"] ":" msg["module"]
    msg_out_alert_hi(subject, msg["line"])
}
