#!/bin/sh
######################################################################
# oswsub.sh
# This script is called by OSWatcher.sh. This script is the generic
# data collector shell. $1 is the output filename for the data
# collector. $2 is the data collector shell script to execute.
# $3 fixes timestamp date to be OSWg compliant.
######################################################################
if [ $3 != 0 ]; then
  echo "zzz ***"`date '+%a %b %e %T %Z %Y'` >> $1
else
  echo "zzz ***"`date` >> $1
fi
$2 >> $1

