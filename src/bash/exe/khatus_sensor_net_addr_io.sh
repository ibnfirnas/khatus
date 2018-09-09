#! /bin/sh

set -e

dir_bin="$1"

ip -s addr | "$dir_bin"/khatus_parse_ip_addr
