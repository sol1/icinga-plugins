#!/bin/bash
#

# Standard Icinga return codes
E_SUCCESS="0"
E_WARNING="1"
E_CRITICAL="2"
E_UNKNOWN="3"

# Check arguments
MASTER=$1
SLAVE=$2
IP=$3 # e.g. floating IP we're "keeping alive", e.g. 103.242.49.20

if [ -z $MASTER ]; then
	echo "UNKNOWN: No master specified"
	exit ${E_UNKNOWN}
fi

if [ -z $SLAVE ]; then
	echo "UNKNOWN: No slave specified"
	exit ${E_UNKNOWN}
fi

if [ -z $IP ]; then
	echo "UNKNOWN: No IP address specified"
	exit ${E_UNKNOWN}
fi

# egrep's return codes
ACTIVE="1"
INACTIVE="0"

# ip -4 -o a | awk '{print $4}' | cut -d'/' -f1

MASTER_OUTPUT=$(ssh $MASTER -l root "ip -4 -o a")
SLAVE_OUTPUT=$(ssh $SLAVE -l root "ip -4 -o a")

MASTER_IPS=`echo "$MASTER_OUTPUT" | awk '{print $4}' | cut -d'/' -f1`
SLAVE_IPS=`echo "$SLAVE_OUTPUT" | awk '{print $4}' | cut -d'/' -f1`

MASTER_IS=$(echo "$MASTER_IPS" | egrep -c "^$IP\$")
SLAVE_IS=$(echo "$SLAVE_IPS" | egrep -c "^$IP\$")

if ([ "$MASTER_IS" = "$ACTIVE" ] && [ "$SLAVE_IS" = "$INACTIVE" ]); then
	echo "OK: $IP active on master only"
	exit ${E_SUCCESS}
fi

if ([ "$MASTER_IS" = "$INACTIVE" ] && [ "$SLAVE_IS" = "$ACTIVE" ]); then
	echo "WARNING: $IP has fallen over to slave"
	exit ${E_WARNING}
fi

if ([ "$MASTER_IS" = "$ACTIVE" ] && [ "$SLAVE_IS" = "$ACTIVE" ]); then
	echo "CRITICAL: $IP active on both master and slave"
	exit ${E_CRITICAL}
fi

if ([ "$MASTER_IS" = "$INACTIVE" ] && [ "$SLAVE_IS" = "$INACTIVE" ]); then
	echo "CRITICAL: $IP not active on neither master nor slave"
	exit ${E_CRITICAL}
fi

exit ${E_UNKNOWN}
