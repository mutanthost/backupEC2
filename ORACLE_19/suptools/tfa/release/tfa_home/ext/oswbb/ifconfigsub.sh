#!/bin/sh
######################################################################
# ifconfigsub.sh
# This script is called by OSWatcher.sh. This script is the ifconfig
# data collector shell. $1 is the output filename for the data
# collector. $2 is the data collector shell script to execute.
# $3 fixes timestamp date to be OSWg compliant.
######################################################################
if [ $3 != 0 ]; then
  echo "zzz ***"`date '+%a %b %e %T %Z %Y'` >> $1
else
  echo "zzz ***"`date` >> $1
fi

PLATFORM=`/bin/uname`

case $PLATFORM in
      HP-UX|HI-UX)
       for i in `netstat -rn|egrep -v "Interface|Routing"|awk '{print $5}'`;do /usr/sbin/ifconfig $i;done  >> $1 
      ;;
      *)
       $2 >> $1
    ;;
    esac
rm locks/ifconfiglock.file
