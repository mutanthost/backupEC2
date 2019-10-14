#!/bin/sh
######################################################################
# oswnet.sh
# This script is called by OSWatcher.sh. This script runs the two
# netstat commands back to back.
#
######################################################################
if [ $2 != 0 ]; then
  echo "zzz ***"`date '+%a %b %e %T %Z %Y'` >> $1
else
  echo "zzz ***"`date` >> $1
fi
netstat -a -i -n >> $1
netstat -s >> $1
rm locks/netlock.file
