{
  delete msg
  msg_parse(msg, $0)
}

msg["node"]   == Node && \
msg["module"] == "khatus_bar" && \
msg["type"]   == "status_bar" {
    system("xsetroot -name \"" msg["status_bar"] "\"")
    next
}
