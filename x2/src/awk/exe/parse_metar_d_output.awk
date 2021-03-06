# Qualifying the name as "_d_output" lest it be mistaken for parser of actual
# metar format.

/METAR pattern not found in NOAA data/ {
    failures++
    exit
}

/[A-z][a-z]+ *: / {
    split($0, line, ":")
    key = str_strip(line[1])
    val = str_strip(line[2])
    values[NR] = val
    first[key] = NR
    last[key] = NR
}

/^ +/ {
    values[NR] = str_strip($0)
    last[key] = NR
}

END {
    if (failures) {
        print "metar fetch failed" > "/dev/stderr"
    } else {
        temp_string = values[first["Temperature"]]
        split(temp_string, temp_parts, " +")
        temp_celsius = temp_parts[1]
        temp_fahrenheit = (temp_celsius * (9 / 5)) + 32
        print("temperature_c", temp_celsius)     # °C
        print("temperature_f", temp_fahrenheit)  # °F
        for (i=first["Phenomena"]; i<=last["Phenomena"]; i++) {
            phenomenon = values[i]
            if (phenomenon) {
                print("phenomenon" Kfs i, phenomenon)
            }
        }
    }
}
