#! /bin/sh

set -e

dir_bin="$1"

free | "$dir_bin"/khatus_parse_free
