#!/bin/sh

######################################################################
# Copyright (c)  2005 by Oracle Corporation
# startOSW.sh
# This is the script that starts the OSWatcher program. It accepts 4
# arguments which control the frequency that data is collected and the
# number of hours worth of data to archive.
#
# $1 = snapshot interval in seconds.
# $2 = the number of hours of archive data to store.
# $3 = (optional) the name of the zip or compress utility you want
#      OSWbb to use to zip up the archive files upon completion. If
#      no zipping is desired set this parameter = NONE. This will
#      allow for the $4 parameter below to be recognized as both $3 
#      and $4 are optional parameters.
# $4 = (optional) the fully qualified name of the archive directory
#      where you want oswbb to save your data. This option can be used
#      instead of setting the UNIX environment variable OSWBB_ARCHIVE_DEST
#      If this parameter is not set oswbb will look for the UNIX
#      environment variable OSWBB_ARCHIVE_DEST. If neither are set
#      the archive directory will remain in the default location under
#      the oswbb directory
#
# If you do not enter any arguments the script runs with default values
# of 30 and 48 meaning collect data every 30 seconds and store the last
# 48 hours of data.
######################################################################
# Modifications Section:
######################################################################
##     Date        File            Changes
##
##  07/24/2007     startOSW.sh      Added optional 3rd parameter to
##  V2.1.0                          compress files
##  01/8/12        startOSWbb.sh    Added optional 4th parameter to 
##  V6.0                            set OSWBB_ARCHIVE_DEST
######################################################################
# First check to see if oswbb is already running
######################################################################
ps -ef | grep OSWatcher  | grep -v grep > /dev/null
if [ $? -eq 0 ]; then
        echo "An OSWatcher process has been detected."
        echo "Please stop it before starting a new OSWatcher process."
        exit
fi
######################################################################
# set LANG environment
######################################################################
LC_ALL=C
export LC_ALL 
######################################################################
# Start OSW
######################################################################
./OSWatcher.sh $1 $2 $3 $4 &
