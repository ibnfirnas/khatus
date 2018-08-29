# Naming convention:
#     Variables:
#         - global, builtin : ALLCAPS
#         - global, public  : Camel_Snake_Man_Bear_Pig
#         - global, private : _snake_case_prefixed_underscore
#         - local           : snake_case
#     Functions:
#         - global, public  : snake_case

BEGIN {
    GC_Interval = GC_Interval ? GC_Interval : 3600  # seconds

    _total_to_diff["khatus_sensor_net_addr_io", "bytes_read"     ] = 1
    _total_to_diff["khatus_sensor_net_addr_io", "bytes_written"  ] = 1
    _total_to_diff["khatus_sensor_disk_io"    , "sectors_read"   ] = 1
    _total_to_diff["khatus_sensor_disk_io"    , "sectors_written"] = 1

    # (x * y) / z = x * w
    #   ==> w = y / z
    # (x * bytes_per_sector) / bytes_per_mb = x * scaling_factor
    #   ==> scaling_factor = bytes_per_sector / bytes_per_mb
    _bytes_per_sector = 512
    _bytes_per_mb     = 1024 * 1024
    _scale["khatus_sensor_disk_io", "sectors_written"] = _bytes_per_sector / _bytes_per_mb
    _scale["khatus_sensor_disk_io", "sectors_read"   ] = _bytes_per_sector / _bytes_per_mb
    # (x / y) = x * z
    #   ==> z = 1 / y
    # x / bytes_per_mb = x * scaling_factor
    #   ==> scaling_factor = 1 / bytes_per_mb
    _scale["khatus_sensor_net_addr_io", "bytes_written"] = 1 / _bytes_per_mb
    _scale["khatus_sensor_net_addr_io", "bytes_read"   ] = 1 / _bytes_per_mb
}

function cache_update(    src, key, val, len_line, len_head, len_val, time) {
    src = $2
    key = $3
    # Not just using $4 for val - because an unstructured value (like name of a
    # song) might contain a character identical to FS
    len_line = length($0)
    len_head = length($1 FS $2 FS $3 FS)
    len_val  = len_line - len_head
    val = substr($0, len_head + 1, len_val)
    val = cache_maybe_total_to_diff(src, key, val)
    val = cache_maybe_scale(src, key, val)
    _cache[src, key] = val
    time = cache_get_time()
    _cache_mtime[src, key] = time
    if (time % GC_Interval == 0) {
        cache_gc()
    }
}

function cache_get(result, src, key, ttl,    time, age, is_expired) {
    time = cache_get_time()
    _cache_atime[src, key] = time
    age = time - _cache_mtime[src, key]
    result["is_expired"] = ttl && age > ttl  # ttl = 0 => forever
    result["value"] = _cache[src, key]
}

function cache_res_fmt_or_def(result, format, default) {
    return result["is_expired"] ? default : sprintf(format, result["value"])
}

function cache_get_fmt_def(src, key, ttl, format, default,    result) {
    default = default ? default : "--"
    cache_get(result, src, key, ttl)
    return cache_res_fmt_or_def(result, format, default)
}

function cache_get_time(    src, key, time) {
    src = "khatus_sensor_datetime"
    key = "epoch"
    time = _cache[src, key]
    _cache_atime[src, key] = time
    return time
}

function cache_gc(    src_and_key, parts, src, key, unused_for) {
    for (src_and_key in _cache) {
        split(src_and_key, parts, SUBSEP)
        src = parts[1]
        key = parts[2]
        val = _cache[src, key]
        unused_for = cache_get_time() - _cache_atime[src, key]
        if (unused_for > GC_Interval) {
            msg_out_info(\
                "cache_gc",
                sprintf(\
                    "Deleting unused data SRC=%s KEY=%s VAL=%s",
                    src, key, val\
                ) \
            )
            delete _cache[src, key]
        }
    }
}

function cache_maybe_total_to_diff(src, key, val,    key_parts) {
    split(key, key_parts, Kfs)
    if (_total_to_diff[src, key_parts[1]]) {
        _prev[src, key] = _curr[src, key]
        _curr[src, key] = val
        return (_curr[src, key] - _prev[src, key])
    } else {
        return val
    }
}

function cache_maybe_scale(src, key, val,    key_parts) {
    split(key, key_parts, Kfs)
    if ((src SUBSEP key_parts[1]) in _scale) {
        return val * _scale[src, key_parts[1]]
    } else {
        return val
    }
}
