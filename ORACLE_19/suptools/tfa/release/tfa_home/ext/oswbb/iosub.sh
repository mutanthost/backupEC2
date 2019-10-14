#!/bin/sh
######################################################################
# iosub.sh
# This script is called by OSWatcher.sh. This script is the data
# collector shell for iostat. $1 is the output filename for the data
# collector. $2 is the data collector shell script to execute.
# $3 fixes timestamp date to be OSWg compliant.
######################################################################
lineCounter1=1
lineCounter2=1

if [ $3 != 0 ]; then
  echo "zzz ***"`date '+%a %b %e %T %Z %Y'` >> $1
else
  echo "zzz ***"`date` >> $1
fi

$2 >> tmp/iost.tmp
lineCounter1=`cat tmp/iost.tmp | wc -l | awk '{$1=$1;print}'`
lineCounter2=`expr $lineCounter1 / 3`
tail -$lineCounter2 tmp/iost.tmp >> $1
rm tmp/iost.tmp
rm locks/iolock.file
