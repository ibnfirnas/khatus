#! /bin/bash

set -e

# =============================================================================
# Private
# =============================================================================

# Defaults
prefix='/dev/shm/khatus'
host="$(hostname)"
sensor="$(basename $0)"
run_in='foreground'  # foreground | background
run_as='poller'      # poller | streamer
interval=1           # Only relevant if run_as poller, ignored otherwise.

set_common_options() {
    while :
    do
        case "$1"
        in '')
            break
        ;; -d|--daemon)
            run_in='background'
            shift 1
        ;; -i|--interval)
            case "$2"
            in '')
                printf "Option $1 requires and argument\n" >&2
                exit 1
            ;; *)
                interval="$2"
                shift 2
            esac
        ;; --)
            shift 1
            break
        ;; *)
            shift 1
        esac
    done
}

init_dirs() {
    work_dir="${prefix}/${host}/${sensor}"
    out_dir="${work_dir}/out"
    err_file="${work_dir}/err"
    pid_file="${work_dir}/pid"

    mkdir -p "$out_dir"
}

streamer() {
    sensor \
    | while read key val
        do
            printf "%s\n" "$val" > "${out_dir}/${key}"
        done
    >> "$err_file"
}

poller() {
    while :
    do
        streamer
        sleep "$interval"
    done
}

pid_file_create_of_parent() {
    printf "$$\n" > "$pid_file"
}

pid_file_create_of_child() {
    printf "$!\n" > "$pid_file"
}

pid_file_test() {
    if test -e "$pid_file"
    then
        printf "Error - $sensor already running (i.e. PID file exists at $pid_file)\n" 1>&2
        exit 1
    fi
}

pid_file_remove() {
    rm -f "$pid_file"
}

run_in_foreground() {
    # TODO: Why do INT and EXIT traps only work in combination?
    trap true INT
    trap exit TERM
    trap pid_file_remove EXIT
    $1
}

run_in_background_2nd_fork() {
    run_in_foreground $1 &
    pid_file_create_of_child
}

run_in_background() {
    run_in_background_2nd_fork $1 &
}

run() {
    case "$run_as"
    in 'poller' | 'streamer')
        true
    ;; *)
        printf "Error - illegal value for \$run_as: $run_in\n" 1>&2
        exit 1
    esac
    pid_file_test
    case "$run_in"
    in 'background')
        run_in_background $1
    ;; 'foreground')
        pid_file_create_of_parent
        run_in_foreground $1
    ;; *)
        printf "Error - illegal value for \$run_in: $run_in\n" 1>&2
        exit 1
    esac
}

# =============================================================================
# API
# -----------------------------------------------------------------------------
#   run_as_poller
#   run_as_streamer
# =============================================================================

run_as_poller() {
    run 'poller'
}

run_as_streamer() {
    run 'streamer'
}

set_common_options $@
init_dirs
