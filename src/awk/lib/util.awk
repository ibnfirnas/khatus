function util_strip(s) {
    sub("^ *", "", s)
    sub(" *$", "", s)
    return s
}

function util_round(n) {
    return int(n + 0.5)
}

function util_ensure_numeric(n) {
    return n + 0
}

#------------------------------------
# Why do we need util_ensure_numeric?
#------------------------------------
# awk appears to be guessing the type of an inputted scalar based on usage, so
# if we read-in a number, but did not use it in any numeric operations, but did
# use as a string (even in just a format string!) - it will be treated as a
# string and can lead to REALLY SURPRISING behavior in conditional statements,
# where smaller number may compare as greater than the bigger ones, such as.
#
# Demo:
#
# $ awk 'BEGIN {x = "75"; y = "100"; sprintf("x: %d, y: %d\n", x, y); if (x > y) {print "75 > 100"} else if (x < y) {print "75 < 100"}}'
# 75 < 100
# $ awk 'BEGIN {x = "75"; y = "100"; sprintf("x: %s, y: %d\n", x, y); if (x > y) {print "75 > 100"} else if (x < y) {print "75 < 100"}}'
# 75 > 100

# However, once used as a number, seems to stay that way even after being
# used as string:
#
# $ awk 'BEGIN {x = "75"; y = "100"; x + y; sprintf("x: %s, y: %d\n", x, y); if (x > y) {print "75 > 100"} else if (x < y) {print "75 < 100"}}'
# 75 < 100
# 
# $ awk 'BEGIN {x = "75"; y = "100"; x + y; sprintf("x: %s, y: %d\n", x, y); z = x y; if (x > y) {print "75 > 100"} else if (x < y) {print "75 < 100"}}'
# 75 < 100
# 
# $ awk 'BEGIN {x = "75"; y = "100"; x + y; z = x y; if (x > y) {print "75 > 100"} else if (x < y) {print "75 < 100"}}'
# 75 < 100
# $ awk 'BEGIN {x = "75"; y = "100"; z = x y; if (x > y) {print "75 > 100"} else if (x < y) {print "75 < 100"}}'
# 75 > 100
