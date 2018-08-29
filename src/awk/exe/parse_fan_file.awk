{
    key = $1
    sub(":$", "", key)
    val = $2
    print(key, val)
}
