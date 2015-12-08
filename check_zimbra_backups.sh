#!/bin/bash
# Zimbra per-account backup check.
# Vesion 1.3 rewritten by Oli
# Setup cron job to list accounts existing at 3AM for each server.
# Compares the backed up accounts against that list, rather than a new list each time which potentially contains new accounts
#59 02 * * * zimbra zmprov -l gaa -s subsoil.colo.sol1.net > /tmp/originalmailboxes.txt

rm -f /tmp/$SERVER-status.txt

if [ $# -eq 0 ]
  then
        echo "No arguments supplied - Specify the server to check for backups"
        exit 255

fi

SERVER=$1
CHECK=Unknown

checkexitstatus () {
        if [ "$?" != "0" ]
                then echo "Failed to check server $SERVER"
                exit 3
        fi
}

ssh zimbra@$SERVER "zmbackupquery -v $SERVER |grep @ | cut -d ' ' -f 3- | cut -d ':' -f 1| sort |uniq > /tmp/$SERVER-backups.txt"
checkexitstatus
ssh zimbra@$SERVER "comm -23 <(sort /tmp/originalmailboxes.txt) <(sort /tmp/$SERVER-backups.txt)" > /tmp/$SERVER-status.txt
checkexitstatus

if [ $(wc -l /tmp/$SERVER-status.txt |cut -f 1 -d " ") -gt 0 ]
        then
                echo "$SERVER: $(wc -l /tmp/$SERVER-status.txt |cut -f 1 -d " ") accounts do not have a backup: `cat /tmp/$SERVER-status.txt | sed ':a;N;$!ba;s/\n/ /g'`"
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
