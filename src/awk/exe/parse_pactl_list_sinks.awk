/^Sink \#[0-9]+$/ {
    sub("^#", "", $2)
    sink = $2
    next
}

/^\t[A-Z].+:/ {
    section = $1
}

section == "Properties:" {
    read_property()
}

/\tState:/ {
    state[sink] = $2
    next
}

/\tMute:/ {
    mute[sink] = $2
    next
}

# Volume: front-left: 45732 /  70% / -9.38 dB,   front-right: 45732 /  70% / -9.38 dB
/\tVolume:/ {
    delete vol_parts
    delete left_parts
    delete right_parts
    sub("^\t+Volume: +", "")
    split($0, vol_parts, ", +")
    sub("^front-left: +", "", vol_parts[1])
    sub("^front-right: +", "", vol_parts[2])
    split(vol_parts[1], left_parts, " +/ +")
    split(vol_parts[2], right_parts, " +/ +")
    vol_left[sink] = left_parts[2]
    vol_right[sink] = right_parts[2]
    next
}

END {
    for (sink in state) {
        device = properties[sink, "alsa.device"]
        print("state"     Kfs device, state[sink])
        print("mute"      Kfs device, mute[sink])
        print("vol_left"  Kfs device, vol_left[sink])
        print("vol_right" Kfs device, vol_right[sink])
    }
}

function read_property() {
    key = $1
    # Yes, the sequence (x-1+1) is redundant, but it keeps the variable names
    # true to their meaning:
    val_begin = index($0, "\"") + 1       # +1 to exclude first quote
    val_end   = length($0) - 1            # -1 to exclude last quote
    val_len   = (val_end - val_begin) + 1 # +1 to include final character
    val       = substr($0, val_begin, val_len)
    properties[sink, key] = val
}
