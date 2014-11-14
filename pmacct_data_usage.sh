#!/bin/bash

# Sanity check
if [ $# -ne 4 ]; then
        echo "Usage: $0 quota-in-gb mysqluser mysqlpwd sshhost"
        exit
fi


QUOTA=$1
MYSQLUSER=$2
MYSQLPWD=$3
SSHHOST=$4


# echo "select *, sum(bytes) AS bytes_total from acct where ip_src != '0.0.0.0' and stamp_inserted > (NOW() - INTERVAL 1 HOUR) group by ip_src having bytes_total > $QUOTA order by bytes_total desc;"|ssh $SSHHOST mysql -N -u$MYSQLUSER -p$MYSQLPWD pmacct|awk '{print $1,"\t"$10}' > /tmp/pmacctusage.txt

echo "SELECT *, ROUND(SUM(bytes) / 1024 / 1024 / 1000, 2) AS gb_total FROM acct WHERE ip_src != '0.0.0.0' AND stamp_inserted > (NOW() - INTERVAL 1 HOUR) GROUP BY ip_src HAVING gb_total > $QUOTA ORDER BY gb_total DESC;" | ssh $SSHHOST mysql -N -u$MYSQLUSER -p$MYSQLPWD pmacct|awk '{print $1,"\t"$10}' > /tmp/pmacctusage.txt

# cat /tmp/pmacctusage.txt |awk '{print $1, system("/usr/local/bin/byteme.sh" FS $2)}'


E_SUCCESS="0"
E_WARNING="1"
E_CRITICAL="2"
E_UNKNOWN="3"


if [ "`cat /tmp/pmacctusage.txt |wc -l`" == "0" ]
  then
        echo "OK - No users exceeded usage threshold"
        exit ${E_SUCCESS}
        else
        echo "CRITICAL - Users exceeded quota `cat /tmp/pmacctusage.txt|sed -e :a -e N -e 's/\n/, /' -e ta`"
        exit ${E_CRITICAL}
fi

