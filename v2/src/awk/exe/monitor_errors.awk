{
  delete msg
  msg_parse(msg, $0)
}

msg["type"] == "error" {
    subject = "ERROR_IN_" msg["node"] ":" msg["module"]
    msg_out_alert_hi(subject, msg["line"])
}
