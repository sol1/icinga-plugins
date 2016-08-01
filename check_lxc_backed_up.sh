#!/bin/bash
#
# Check everything on a lxc server has a backup check
# Prerequsites: nagioschecker user and ssh keys on lxc host

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

BACKUP_DIR="/storage/backups"

exitCode=$STATE_UNKNOWN

if [ -n "$1" ]; then
	lxcServer="$1"
	exclude="$2"

	if [ `ssh -q nagioschecker@${lxcServer} exit ; echo $?` -eq 0 ]; then		# Can we login
		# Login a openvz server using the backup user and get list of running vm's
		lxcHosts=`ssh nagioschecker@${lxcServer} sudo lxc-ls -f | grep RUNNING | awk '{print $1}'`	
		# Add the openvz server itself
		checkHosts="${lxcHosts} ${lxcServer}"
	
		MESSAGE=""

		for host in ${checkHosts}; do 
			if ! echo $exclude | grep -q -w $host ; then	# Skip excluded hostnames

				if ! grep "vars.rdiffs" -A2 /etc/icinga2/conf.d/* | grep rdiff_repository | grep -q "${BACKUP_DIR}/${host}/" ; then	# Critical on missing backup checks for host

					MESSAGE="${host} ${MESSAGE}"
					exitCode=$STATE_CRITICAL
				fi
			fi 
		done

		if [ ${exitCode} -eq $STATE_CRITICAL ]; then
			MESSAGE="Missing backup checks for `echo $MESSAGE | sed -e 's/ *$//g'`"
		else
			exitCode=$STATE_OK
			MESSAGE="No missing backup checks"
		fi
		
		if [ -n "$2" ]; then
			MESSAGE="$MESSAGE ($exclude excluded)"
		fi

	else
	    MESSAGE="Unable to connect to $lxcServer"
	    exitCode=$STATE_WARNING
	fi
else
	MESSAGE="Null server paramater ($lxcServer)"
	exitCode=$STATE_UNKNOWN
fi

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
