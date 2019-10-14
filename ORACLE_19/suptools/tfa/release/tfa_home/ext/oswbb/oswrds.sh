#!/bin/sh
#
# RDS Diagnostics
#
#
echo "zzz ***"`date` >> $1
echo "RDS Diagnostics" >> $1
echo "" >> $1
echo "Display the IB connections which the IB transport is using to provide RDS connections..." >> $1
rds-info -I xdorlscpriv1 >> $1
echo "" >> $1
echo "Display all RDS connections. RDS connections are maintained between nodes by transports..." >> $1
rds-info -n >> $1
echo "" >> $1
echo "Display all the RDS sockets in the system..." >> $1
rds-info -k >> $1
echo "" >> $1
echo "Display global counters. Each counter increments as its event occurs..." >> $1
rds-info -c >> $1
echo "" >> $1
echo "Test whether a remote node is reachable over RDS. Using the alias for the IB interface..." >> $1
for i in `grep priv /etc/hosts|awk '{print $3}'`; do echo $i; rds-ping -c 1 $i;done >> $1
echo "" >> $1
rm locks/rdslock.file


