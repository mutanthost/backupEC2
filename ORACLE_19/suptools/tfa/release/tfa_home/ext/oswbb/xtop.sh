#!/bin/sh
######################################################################
# Copyright (c)  2007 by Oracle Corporation
# xtop.sh
# This script is called by OSWatcher.sh. This script is the generic
# data collector shell for collecting top data. $1 is the output
# filename for the data collector. This script takes 2 samples of top
# but disregards the first sample, sending only the last sample to the
# file
######################################################################

lineCounter=1
lineStart=1
lineRange=1
offset=1

#determine offset based on os top command
PLATFORM=`/bin/uname`
if [ $2 != 0 ]; then
  echo "zzz ***"`date '+%a %b %e %T %Z %Y'` >> $1
else
  echo "zzz ***"`date` >> $1
fi

case $PLATFORM in
      Linux)
      top -b -n2 -d1 > tmp/xtop.tmp
      ;;
      HP-UX|HI-UX)
        top -d 2 -f tmp/xtop.tmp
      ;;
      AIX)
        top -d 2 > tmp/xtop.tmp 
      ;;
      *)
        if [ $3 != 0 ]; then
          prstat 1 2 > tmp/xtop.tmp
        else
          top -d2 -s1 > tmp/xtop.tmp
        fi
    ;;
    esac
lineCounter=`cat tmp/xtop.tmp | wc -l | awk '{$1=$1;print}'`
lineStart=`expr $lineCounter / 2`
lineStart=`expr $lineStart + $offset`
lineRange=`expr $lineCounter - $lineStart `

case $PLATFORM in
      Linux)
       tail -$lineRange tmp/xtop.tmp >> tmp/ltop.tmp
       head -50 tmp/ltop.tmp >> $1
       rm tmp/ltop.tmp
      ;;
      *)
       tail -$lineRange tmp/xtop.tmp >> $1
      ;;

esac
rm tmp/xtop.tmp
rm locks/toplock.file


