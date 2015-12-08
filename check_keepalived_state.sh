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
SOCKET=$3 # e.g. socket we're "keeping alive", e.g. 103.242.49.20:25

if [ -z $MASTER ]; then
	echo "UNKNOWN: No master specified"
	exit ${E_UNKNOWN}
fi

if [ -z $SLAVE ]; then
	echo "UNKNOWN: No slave specified"
	exit ${E_UNKNOWN}
fi

if [ -z $SOCKET ]; then
	echo "UNKNOWN: No socket specified"
	exit ${E_UNKNOWN}
fi

# egrep's return codes
ACTIVE="1"
INACTIVE="0"

MASTER_OUTPUT=$(ssh $MASTER -l root "ipvsadm -Ln")
SLAVE_OUTPUT=$(ssh $SLAVE -l root "ipvsadm -Ln")

MASTER_SOCKETS=`echo "$MASTER_OUTPUT" | grep TCP | awk '{print $2}'`
SLAVE_SOCKETS=`echo "$SLAVE_OUTPUT" | grep TCP | awk '{print $2}'`

MASTER_IS=$(echo "$MASTER_SOCKETS" | egrep -c "^$SOCKET\$")
SLAVE_IS=$(echo "$SLAVE_SOCKETS" | egrep -c "^$SOCKET\$")

if ([ "$MASTER_IS" = "$ACTIVE" ] && [ "$SLAVE_IS" = "$INACTIVE" ]); then
	echo "OK: $SOCKET active on master only"
	exit ${E_SUCCESS}
fi

if ([ "$MASTER_IS" = "$INACTIVE" ] && [ "$SLAVE_IS" = "$ACTIVE" ]); then
	echo "WARNING: $SOCKET has fallen over to slave"
	exit ${E_WARNING}
fi

if ([ "$MASTER_IS" = "$ACTIVE" ] && [ "$SLAVE_IS" = "$ACTIVE" ]); then
	echo "CRITICAL: $SOCKET active on both master and slave"
	exit ${E_CRITICAL}
fi

if ([ "$MASTER_IS" = "$INACTIVE" ] && [ "$SLAVE_IS" = "$INACTIVE" ]); then
	echo "CRITICAL: $SOCKET not active on neither master nor slave"
	exit ${E_CRITICAL}
fi

exit ${E_UNKNOWN}
