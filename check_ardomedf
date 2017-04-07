#!/bin/sh
# On an ardome host, query the database for the free disk space value.

query='select sum(min_file_size) from ardome.min where min_svc_id=282'
out=`adt "$query"`

# The first field is just a status code; ignore it.
df=`echo $out | awk '{print $2}'`

warn=0
crit=0
while getopts 'w:c:' flag; do
        case "${flag}" in
                w) warn="${OPTARG}" ;;
                c) crit="${OPTARG}" ;;
                *) error "Unexpected option ${flag}" ;;
        esac
done

# Sanity checks. Both thresholds must be defined.
if [ $warn -eq 0 ]; then
        echo "UNKNOWN - warning threshold undefined"
        exit 3
fi
if [ $crit -eq 0 ]; then
        echo "UNKNOWN - critical threshold undefined"
        exit 3
fi

# Main routine
if [ "$df" -lt "$crit" ]; then
        echo "CRITICAL - Ardome reports $df bytes free"
        exit 2
elif [ "$df" -lt "$warn" ]; then
        echo "WARNING - Ardome reports $df bytes free"
        exit 1
if [ "$df" -gt "$warn" ]; then
        echo "OK - Ardome reports $df bytes free"
        exit 0
else
        echo "UNKNOWN - unexpected error"
        exit 3
fi
