#!/bin/bash
# check if voipmonitor's CDR table has recent call data

#in seconds
MAXAGE=$3

TIMESINCE=`mysql voipmonitor -BN -h $1 -u $2 -e 'select cast((now() - max(calldate)) AS SIGNED) from cdr;'`

RES=$(($MAXAGE < $TIMESINCE))

E_SUCCESS="0"
E_WARNING="1"
E_CRITICAL="2"
E_UNKNOWN="3"

if [ "$RES" -eq "1" ]
	then echo "CRITICAL: No Voipmonitor CDR data within $MAXAGE seconds, last call $TIMESINCE seconds ago"
	exit ${E_CRITICAL}
fi

if [ "$RES" -eq "0" ]
	then echo "OK: Recent Voipmonitor CDR data found, last call $TIMESINCE seconds ago"
	exit ${E_SUCCESS}
fi

exit ${E_UNKNOWN}
