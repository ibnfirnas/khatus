#! /bin/sh

set -e

dir_bin="$1"
weather_station_id="$2"

curl \
    -X GET \
    -H "accept: application/vnd.noaa.obs+xml" \
    "https://api.weather.gov/stations/${weather_station_id}/observations/latest?require_qc=false" \
| hxpipe \
| "$dir_bin"/khatus_parse_noaa_api
