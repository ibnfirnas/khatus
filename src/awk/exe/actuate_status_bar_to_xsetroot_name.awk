$1 == Node && \
$2 == "khatus_bar" && \
$3 == "status_bar" {
    delete msg
    msg_in_parse(msg, $0)
    system("xsetroot -name \"" msg["status_bar"] "\"")
    next
}
