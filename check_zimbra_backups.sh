#!/bin/bash
# Zimbra per-account backup check.
# Vesion 1.4 update by Matt
# - Add file checks
# - Add check boilerplate
# Vesion 1.3 rewritten by Oli
# Setup cron job to list accounts existing at 3AM for each server.
# Compares the backed up accounts against that list, rather than a new list each time which potentially contains new accounts
# 	Does a remote check by default (relies on the host running this script having ssh keys to zimbra@remote_host)
# 	Does a local check if the server is set as "localhost"
#59 02 * * * zimbra zmprov -l gaa -s subsoil.colo.sol1.net > /tmp/originalmailboxes.txt


function checkParam() {
	local name="$1"
	local param="$2"

	if [ -z "$param" ] ; then
		MESSAGE="${MESSAGE} $name"
	fi
}

function trimMessage() {
	MESSAGE="$(echo -e "${MESSAGE}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' )"
}

function checkexitstatus () {
        if [ "$?" != "0" ] ; then 
		echo "UNKNOWN - Failed to check server $SERVER"
                exit $STATE_UNKNOWN
        fi
}

function checkfileage () {
	local file="$1"
	local warn="$2"
	local crit="$3"
	local message=""
	
	# If we have a remote target use it
	if [ -n "$4" ] ; then
		message=`ssh $4 "/usr/lib/nagios/plugins/check_file_age -w $warn -c $crit -f ${file}"`
	else
		message=`/usr/lib/nagios/plugins/check_file_age -w $warn -c $crit -f "$file"`
	fi


	if [ "$?" != "0" ] ; then
		echo "$message"
		exit $?
	fi
}

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

exitCode=$STATE_UNKNOWN
MESSAGE=""

if [ -n "$1" ] ; then
	SERVER=$1

	BACKUP_TXT="/tmp/$SERVER-backups.txt"
	STATUS_TXT="/tmp/$SERVER-status.txt"
	MAILBOXES_TXT="/tmp/originalmailboxes.txt"

	rm -f ${STATUS_TXT}


	if [ "$SERVER" == "localhost" ] ; then
		su zimbra -l -c "zmbackupquery -v $SERVER |grep @ | cut -d ' ' -f 3- | cut -d ':' -f 1| sort |uniq > ${BACKUP_TXT}"
		checkexitstatus
		checkfileage ${BACKUP_TXT} 60 60
		checkfileage ${MAILBOXES_TXT} $((25 * 60 * 60)) $((32 * 60 * 60))

		su zimbra -l -c "comm -23 <(sort ${MAILBOXES_TXT}) <(sort ${BACKUP_TXT})" > ${STATUS_TXT}
		checkexitstatus
	else
		ssh zimbra@$SERVER "zmbackupquery -v $SERVER |grep @ | cut -d ' ' -f 3- | cut -d ':' -f 1| sort |uniq > ${BACKUP_TXT}"
		checkexitstatus
		checkfileage ${BACKUP_TXT} 60 60 zimbra@$SERVER
		checkfileage ${MAILBOXES_TXT} $((25 * 60 * 60)) $((32 * 60 * 60)) zimbra@$SERVER

		ssh zimbra@$SERVER "comm -23 <(sort ${MAILBOXES_TXT}) <(sort ${BACKUP_TXT})" > ${STATUS_TXT}
		checkexitstatus

	fi
	checkfileage ${STATUS_TXT} 60 60


	if [ $(wc -l ${STATUS_TXT} |cut -f 1 -d " ") -gt 0 ] ; then
		MESSAGE="$SERVER: $(wc -l ${STATUS_TXT} |cut -f 1 -d " ") accounts do not have a backup: `cat ${STATUS_TXT} | sed ':a;N;$!ba;s/\n/ /g'`"
		exitCode=$STATE_CRITICAL
	else
		MESSAGE="$SERVER: all accounts have a backup"
		exitCode=$STATE_OK
	fi

else
    exitCode=$STATE_UNKNOWN

    checkParam "server" "$1"
 
    trimMessage
    MESSAGE="Missing paramaters ${MESSAGE} ($@)"
fi

trimMessage

if [ $exitCode -eq $STATE_UNKNOWN ]; then
    echo "UNKNOWN - $MESSAGE"
elif [ $exitCode -eq $STATE_CRITICAL ]; then
    echo "CRITICAL - $MESSAGE"
elif [ $exitCode -eq $STATE_WARNING ]; then
    echo "WARNING - $MESSAGE"
elif [ $exitCode -eq $STATE_OK ]; then
    echo "OK - $MESSAGE"
fi

exit $exitCode
