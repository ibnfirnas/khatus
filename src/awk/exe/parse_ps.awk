{
    pid       = $1
    state     = $2
    Pids[pid] = 1
    Total_Per_State[state]++
}

END {
    print("total_procs", length(Pids))
    for (state in Total_Per_State) {
        print("total_per_state" Kfs state, Total_Per_State[state])
    }
}
