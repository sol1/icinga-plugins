#!/bin/bash
# check if corvus has ingested anything from voipmonitor recently

#in seconds
SQL_HOST_IP=$1
SQL_USER=$2
MAXAGE=$3

TIMESINCE=`mysql voipmonitor -BN -h $SQL_HOST_IP -u $SQL_USER -e 'select cast((now() - max(created_at)) AS SIGNED) from calls;'`

RES=$(($MAXAGE < $TIMESINCE))

E_SUCCESS="0"
E_WARNING="1"
E_CRITICAL="2"
E_UNKNOWN="3"

if [ "$RES" -eq "1" ]
	then echo "CRITICAL: No Corvus CDR data within $MAXAGE seconds, last call $TIMESINCE seconds ago"
	exit ${E_CRITICAL}
fi

if [ "$RES" -eq "0" ]
	then echo "OK: Recent Corvus CDR data found, last call $TIMESINCE seconds ago"
	exit ${E_SUCCESS}
fi

exit ${E_UNKNOWN}
