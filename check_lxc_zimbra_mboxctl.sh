#!/bin/bash

# Sanity check
#if [ $# -ne 2 ]; then
#        echo "Usage: $0 commandline1 commandline2"
#        exit
#fi



lxc-attach -n mail -- /bin/su - zimbra -c "zmmailboxdctl status" >/tmp/zimbrastatus
RETURNCODE=$?


E_SUCCESS="0"
E_WARNING="1"
E_CRITICAL="2"
E_UNKNOWN="3"


if [ "$RETURNCODE" == "0" ] ; then
        echo "OK - Zimbra mailbox is working"
        exit ${E_SUCCESS}
        else
        echo "CRITICAL - Zimbra Mailbox not working"
        exit ${E_CRITICAL}
fi

