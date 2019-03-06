#! /bin/sh

for interface in $(ls /sys/class/net)
do
    printf "%s %d\n" $interface $(cat /sys/class/net/$interface/carrier)
done
