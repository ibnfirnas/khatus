/^ERROR/ {
    src = $2
    # Not just using $3 for body - because body might contain a character
    # identical to FS
    len_line = length($0)
    len_head = length($1 FS $2 FS)
    len_body = len_line - len_head
    body = substr($0, len_head + 1, len_body)
    msg_out_ok_alert("hi", "ERROR_IN_" src, body)
}
