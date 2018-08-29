$1 == "OK" && \
$2 == "khatus_bar" && \
$3 == "status_bar" {
    # Not just using $4 for val - because val might contain a character
    # identical to FS
    len_line = length($0)
    len_head = length($1 FS $2 FS $3 FS)
    len_val  = len_line - len_head
    val = substr($0, len_head + 1, len_val)
    system("xsetroot -name \"" val "\"")
    next
}
