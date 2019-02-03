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

function cache_update(node, module, key, val,    time) {
    # TODO: Use node value
    val = cache_maybe_total_to_diff(module, key, val)
    val = cache_maybe_scale(module, key, val)
    _cache[module, key] = val
    time = cache_get_time()
    _cache_mtime[module, key] = time
    if (time % GC_Interval == 0) {
        cache_gc()
    }
}

function cache_get(result, module, key, ttl,    time, age, is_expired) {
    time = cache_get_time()
    _cache_atime[module, key] = time
    age = time - _cache_mtime[module, key]
    result["is_expired"] = ttl && age > ttl  # ttl = 0 => forever
    result["value"] = _cache[module, key]
}

function cache_res_fmt_or_def(result, format, default) {
    return result["is_expired"] ? default : sprintf(format, result["value"])
}

function cache_get_fmt_def(module, key, ttl, format, default,    result) {
    default = default ? default : "--"
    cache_get(result, module, key, ttl)
    return cache_res_fmt_or_def(result, format, default)
}

function cache_get_time(    module, key, time) {
    module = "khatus_sensor_datetime"
    key = "epoch"
    time = _cache[module, key]
    _cache_atime[module, key] = time
    return time
}

function cache_gc(    module_and_key, parts, module, key, unused_for) {
    for (module_and_key in _cache) {
        split(module_and_key, parts, SUBSEP)
        module = parts[1]
        key = parts[2]
        val = _cache[module, key]
        unused_for = cache_get_time() - _cache_atime[module, key]
        if (unused_for > GC_Interval) {
            msg_out_log_info(\
                "cache_gc",
                sprintf(\
                    "Deleting unused data MODULE=%s KEY=%s VAL=%s",
                    module, key, val\
                ) \
            )
            delete _cache[module, key]
        }
    }
}

function cache_maybe_total_to_diff(module, key, val,    key_parts) {
    split(key, key_parts, Kfs)
    if (_total_to_diff[module, key_parts[1]]) {
        _prev[module, key] = _curr[module, key]
        _curr[module, key] = val
        return (_curr[module, key] - _prev[module, key])
    } else {
        return val
    }
}

function cache_maybe_scale(module, key, val,    key_parts) {
    split(key, key_parts, Kfs)
    if ((module SUBSEP key_parts[1]) in _scale) {
        return val * _scale[module, key_parts[1]]
    } else {
        return val
    }
}
