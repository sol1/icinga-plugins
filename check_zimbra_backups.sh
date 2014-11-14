#!/bin/bash
# backup query and checker 1.2 by sean

SERVER=$1
CHECK=Unknown

checkexitstatus () {
        if [ "$?" != "0" ]
                then echo "Failed to check server $SERVER"
                exit 3
        fi
}

rm -f /tmp/$SERVER-status.txt

if [ $# -eq 0 ]
  then
	echo "No arguments supplied"
	exit 255

fi

ssh zimbra@$SERVER "rm -f /tmp/$SERVER.txt"
ssh zimbra@$SERVER "zmprov -s $SERVER gqu $SERVER | cut -d ' ' -f 1| sort > /tmp/$SERVER.txt"
checkexitstatus                
ssh zimbra@$SERVER "zmbackupquery -v $SERVER |grep @ | cut -d ' ' -f 3- | cut -d ':' -f 1| sort |uniq > /tmp/$SERVER-backups.txt"
checkexitstatus
ssh zimbra@$SERVER "comm -23 /tmp/$SERVER.txt /tmp/$SERVER-backups.txt" > /tmp/$SERVER-status.txt

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
   exit 3
fi
