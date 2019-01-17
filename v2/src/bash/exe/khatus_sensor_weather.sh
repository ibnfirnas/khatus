#! /bin/sh

set -e

dir_bin="$1"
weather_station_id="$2"

metar -d "$weather_station_id" 2>&1 | "$dir_bin"/khatus_parse_metar_d_output
