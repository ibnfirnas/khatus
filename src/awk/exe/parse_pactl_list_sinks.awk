/^Sink \#[0-9]+$/ {
    sub("^#", "", $2)
    sink = $2
    next
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
        print("state"     Kfs sink, state[sink])
        print("mute"      Kfs sink, mute[sink])
        print("vol_left"  Kfs sink, vol_left[sink])
        print("vol_right" Kfs sink, vol_right[sink])
    }
}
