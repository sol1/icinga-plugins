#!/bin/bash
# check if voipmonitor's CDR table has recent call data

# Note, since this no longer queries the database directly,
# args $1 and $2 are superfluous - should update the icinga check to account for this at some stage
# Removed in icinga2 scripts


#in seconds
MAXAGE=$1

CDRTIME=`date -d "\`{ echo "sniffer_stat"; sleep 1; } | telnet -E 10.254.254.1 5029 2>/dev/null | grep "storingCdrLastWriteAt" | /usr/local/sbin/parse_json.py\`" +"%s"`
CURTIME=`date +"%s"`

TIMESINCE=`expr $CURTIME - $CDRTIME`

#TIMESINCE=`mysql voipmonitor -BN -h $1 -u $2 -e 'select cast((now() - max(calldate)) AS SIGNED) from cdr;'`

#date >> /var/log/sensor-test.log
#{ echo "sniffer_stat"; sleep 1; } | telnet -E 10.254.254.1 5029 2>/dev/null | grep "storingCdrLastWriteAt" | python -m json.tool >> /var/log/sensor-test.log

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
