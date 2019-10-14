#!/bin/sh
######################################################################
# Copyright (c)  2013 by Oracle Corporation
# tarupfiles.sh
# This script tars up entire archive directory. 
#
# INPUTS:
# $1 = fully qualified path of archive dir
#
# OUTPUTS:
# The output of this utility is osw_archive_MMDDYYHHMM.tar
#######################################################################

test $1
if [ $? != 1 ]; then
  if [ ! -d $1 ]; then
    echo "The archive directory you specified :"$1" does not exist."
    exit
  else
   ARCHIVE_FOUND=1
   OSWBB_ARCHIVE_DEST=$1
  fi
else
  echo "Please rerun with archive directory specified"
  exit
fi

tar cvf osw_archive.tar archive
hour=`date +'%m%d%y%H%M.tar'`
mv osw_archive.tar osw_archive_$hour
