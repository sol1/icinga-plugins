#!/bin/bash
#check for no change in backup

CHECK=Unknown

rm -f /tmp/barone/nochange.txt

ssh silo.sol1.net "cd /storage/backups/baronepharmacy/" ; for i in `find . -maxdepth 3 -mtime 0 -name *session_stat*|grep lots`; do cat $i |grep -e ChangedFiles\ 0;done | wc -l > /tmp/barone/nochange.txt

if [ `cat /tmp/barone/nochange.txt`  -gt 0 ];
	then 
		echo "*** Did not succeeed - no files changed"
		CHECK=Failed
	else
		echo "*** Success - found changed files"
		CHECK=OK
fi

if [[ "$CHECK" == "OK" ]]; then
   exit 0
elif [[ "$CHECK" == "Failed" ]]; then
   exit 2
else
   exit 3
fi

