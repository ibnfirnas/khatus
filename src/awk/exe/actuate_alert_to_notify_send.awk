BEGIN {
    # Set the correct value as any other AWK variable:
    #
    #   khatus_actuate_alert_to_notify_send -v Display="$CORRECT_DISPLAY"
    #
    Display = Display ? Display : ":0"
}

$1 == "OK" && \
$3 == "alert" {
    src      = $2
    priority = $4
    subject  = $5

    # Not just using $6 for body - because body might contain a character
    # identical to FS
    len_line = length($0)
    len_head = length($1 FS $2 FS $3 FS $4 FS $5 FS)
    len_body = len_line - len_head
    body = substr($0, len_head + 1, len_body)

    sep = body ? "\n" : ""
    body = body sep "--" src
    urgency = priority
    sub("hi" , "critical", urgency)
    sub("med", "normal"  , urgency)

    cmd = \
        sprintf(\
            "DISPLAY=%s notify-send -u %s %s \" %s\"",
            Display, urgency, subject, body \
        )
    system(cmd)
    next
}
