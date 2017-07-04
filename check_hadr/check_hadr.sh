#!/bin/sh

usage () {
        echo "usage: check_hadr [database]"
        return 0
}

# connstat returns nil if the output of the db2pd command a known 'working'
# high availability connection state, or 1 (error) otherwise.
connstat () {
        stat=`db2pd -db $DB -hadr | awk \
        '$1 == "HADR_CONNECT_STATUS" {
                print $3;
        }'`

        if test $stat = "CONNECTED"; then
                return 0
        else
                echo "DB2 high availability status is $stat"
                return 1
        fi
}


# peerstat returns nil if the output of the db2pd command contains a known
# 'working' peer connection state, or 1 (error) otherwise.
peerstat () {
        stat=`db2pd -db $DB -hadr | awk \
        '$1 == "HADR_STATE" {
                print $3;
        }'`

        if test $stat = "PEER"; then
                return 0
        else
                echo "Peer status is $stat"
                return 1
        fi
}

errmsg="Unexpected error"
EXITCODE=127

# Check input sanity
if [ $# -eq 0 ]; then
        usage
        exit $EXITCODE
fi

# A common error is trying to run db2 commands as a user who does not have
# privileges to query the DB2 instance. Check for this.
if which db2pd; then
	continue
else
	errmsg="db2pd not found in PATH.
	    check_hadr was run as `whoami`. Is this a DB2 instance user?"
	echo $errmsg
	exit $EXITCODE
fi

DB=$1
if connstat && peerstat; then
        errmsg="DB2 high availability and peer connection status ok"
        EXITCODE=0
else
        errmsg="DB2 servers high availability and/or peer connection failure"
        EXITCODE=2
fi

echo $errmsg
exit $EXITCODE
