#!/bin/bash
# Zimbra per-account backup check.
# Vesion 1.3 rewritten by Oli
# Setup cron job to list accounts existing at 3AM for each server.
# Compares the backed up accounts against that list, rather than a new list each time which potentially contains new accounts
# 	Does a remote check by default (relies on the host running this script having ssh keys to zimbra@remote_host)
# 	Does a local check if the server is set as "localhost"
#59 02 * * * zimbra zmprov -l gaa -s subsoil.colo.sol1.net > /tmp/originalmailboxes.txt


if [ $# -eq 0 ]
  then
        echo "No arguments supplied - Specify the server to check for backups"
        exit 255

fi

CHECK=Unknown
SERVER=$1
BACKUP_TXT="/tmp/$SERVER-backups.txt"
STATUS_TXT="/tmp/$SERVER-status.txt"
MAILBOXES_TXT="/tmp/originalmailboxes.txt"


checkexitstatus () {
        if [ "$?" != "0" ]
                then echo "Failed to check server $SERVER"
                exit 3
        fi
}


rm -f ${STATUS_TXT}


if [ "$SERVER" == "localhost" ] ; then
	su zimbra -l -c "zmbackupquery -v $SERVER |grep @ | cut -d ' ' -f 3- | cut -d ':' -f 1| sort |uniq > ${BACKUP_TXT}"
	checkexitstatus
	su zimbra -l -c "comm -23 <(sort ${MAILBOXES_TXT}) <(sort ${BACKUP_TXT})" > ${STATUS_TXT}
	checkexitstatus
else
	ssh zimbra@$SERVER "zmbackupquery -v $SERVER |grep @ | cut -d ' ' -f 3- | cut -d ':' -f 1| sort |uniq > ${BACKUP_TXT}"
	checkexitstatus
	ssh zimbra@$SERVER "comm -23 <(sort ${MAILBOXES_TXT}) <(sort ${BACKUP_TXT})" > ${STATUS_TXT}
	checkexitstatus

fi

if [ $(wc -l ${STATUS_TXT} |cut -f 1 -d " ") -gt 0 ]
        then
                echo "$SERVER: $(wc -l ${STATUS_TXT} |cut -f 1 -d " ") accounts do not have a backup: `cat ${STATUS_TXT} | sed ':a;N;$!ba;s/\n/ /g'`"
                CHECK=Failed
        else
                echo "$SERVER: all accounts have a backup"
                CHECK=OK
fi

if [[ "$CHECK" == "OK" ]]; then
   exit 0
elif [[ "$CHECK" == "Failed" ]]; then
   exit 2
else
   exit 255
fi
