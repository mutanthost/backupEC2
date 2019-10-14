#!/bin/sh
######################################################################
# topaix.sh
# This script is called by OSWatcher.sh. This script runs in place of
# top on aix platforms. This script could also be used in place of top
# on other unix platforms.
#
######################################################################
if [ $2 != 0 ]; then
  echo "zzz ***"`date '+%a %b %e %T %Z %Y'` >> $1
else
  echo "zzz ***"`date` >> $1
fi
ps -elk | head -1 >> $1
ps -elk | sort -rn +5 | head -20 >> $1
rm locks/toplock.file
