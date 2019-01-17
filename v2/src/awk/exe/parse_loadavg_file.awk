# 0.71 1.04 1.12 1/325 2409
{
    split($4, sched, "/")
    print("load_avg_1min"             , $1)
    print("load_avg_5min"             , $2)
    print("load_avg_15min"            , $3)
    print("kern_sched_queue_runnable" , sched[1])
    print("kern_sched_queue_total"    , sched[2])
    print("kern_sched_latest_pid"     , $5)
}
