#!/bin/bash

# Sanity check
if [[ ! $# =~ [5-6] ]]; then
        echo "Usage: $0 quota-in-gb period-in-hours mysqluser mysqlpwd sshhost [specificip]"
        exit
fi

QUOTA=$1
TIMEPERIOD=$2
MYSQLUSER=$3
MYSQLPWD=$4
SSHHOST=$5
SPECIFICIP=$6

E_SUCCESS="0"
E_WARNING="1"
E_CRITICAL="2"
E_UNKNOWN="3"

if [ `echo $SPECIFICIP | grep -oP "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"` ]; then
	echo  "SELECT *, ROUND(SUM(bytes) / 1024 / 1024 / 1000, 2) AS gb_total FROM acct WHERE ip_src = '$SPECIFICIP' AND stamp_inserted > (NOW() - INTERVAL $TIMEPERIOD HOUR) GROUP BY ip_src HAVING gb_total > $QUOTA ORDER BY gb_total DESC;" | ssh $SSHHOST mysql -N -u$MYSQLUSER -p$MYSQLPWD pmacct|awk '{print $1,"\t"$10"GB"}' > /tmp/pmacctspecificip.txt

		if [ "`cat /tmp/pmacctspecificip.txt |wc -l`" == "0" ]; then
			echo "OK - $SPECIFICIP usage below threshold"
			exit ${E_SUCCESS}
		else
			echo "CRITICAL - $SPECIFICIP exceeded quota `cat /tmp/pmacctspecificip.txt|sed -e :a -e N -e 's/\n/, /' -e ta`"
			exit ${E_CRITICAL}
		fi
else
	echo "SELECT *, ROUND(SUM(bytes) / 1024 / 1024 / 1000, 2) AS gb_total FROM acct WHERE ip_src != '0.0.0.0' AND ip_src != '10.1.13.14' AND ip_src != '10.1.13.12' AND ip_src NOT LIKE '10.1.%.1' AND stamp_inserted > (NOW() - INTERVAL $TIMEPERIOD HOUR) GROUP BY ip_src HAVING gb_total > $QUOTA ORDER BY gb_total DESC;" | ssh $SSHHOST mysql -N -u$MYSQLUSER -p$MYSQLPWD pmacct|awk '{print $1,"\t"$10"GB"}' > /tmp/pmacctusage.txt
		 if [ "`cat /tmp/pmacctusage.txt |wc -l`" == "0" ]; then
                        echo "OK - No users exceeded threshold"
                        exit ${E_SUCCESS}
                else
                        echo "CRITICAL - Users exceeded quota `cat /tmp/pmacctusage.txt|sed -e :a -e N -e 's/\n/, /' -e ta`"
                        exit ${E_CRITICAL}
                fi
fi

# echo "select *, sum(bytes) AS bytes_total from acct where ip_src != '0.0.0.0' and stamp_inserted > (NOW() - INTERVAL $TIMEPERIOD HOUR) group by ip_src having bytes_total > $QUOTA order by bytes_total desc;"|ssh $SSHHOST mysql -N -u$MYSQLUSER -p$MYSQLPWD pmacct|awk '{print $1,"\t"$10"GB"}' > /tmp/pmacctusage.txt

# cat /tmp/pmacctusage.txt |awk '{print $1, system("/usr/local/bin/byteme.sh" FS $2)}'
