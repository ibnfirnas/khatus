BEGIN {
    # Set the correct value as any other AWK variable:
    #
    #   khatus_actuate_alert_to_notify_send -v Display="$CORRECT_DISPLAY"
    #
    Display = Display ? Display : ":0"
}



$3 == "alert" {
    delete msg
    msg_in_parse(msg, $0)
    body = msg["body"]
    sep = body ? "\n" : ""
    body = body sep "--" msg["node"] ":" msg["module"]
    urgency = msg["priority"]
    sub("hi" , "critical", urgency)
    sub("med", "normal"  , urgency)

    cmd = \
        sprintf(\
            "DISPLAY=%s notify-send -u %s %s \" %s\"",
            Display, urgency, msg["subject"], body \
        )
    system(cmd)
    next
}
