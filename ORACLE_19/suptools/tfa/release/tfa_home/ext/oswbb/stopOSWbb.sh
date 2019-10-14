#!/bin/sh
######################################################################
# stopOSW.sh
# This is the script which terminates all processes associated with
# the OSWatcher program.
######################################################################
# Kill the OSWatcher processes
######################################################################
PLATFORM=`/bin/uname`
case $PLATFORM in
  AIX)
    kill -15 `ps -ef | grep OSWatch | grep -v grep | awk '{print $2}'` 
    ;;
  *)
    kill -15 `ps -e | grep OSWatch | awk '{print $1}'`
    ;;
esac
