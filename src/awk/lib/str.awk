function str_join(array, from, to, sep_given,    str, sep, i) {
    str = ""
    sep = ""
    for (i=from; i<=to; i++) {
        str = str sep array[i]
        sep = sep_given
    }
    return str
}

function str_tail(head, full,    tail, len_tail, len_head, len_full) {
    len_full = length(full)
    len_head = length(head)
    len_tail = len_full - len_head
    tail = substr(full, len_head + 1, len_tail)
    return tail
}

function str_strip(s) {
    sub("^ *", "", s)
    sub(" *$", "", s)
    return s
}
