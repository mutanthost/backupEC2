#!/bin/sh

######################################################################
# Copyright (c)  2013 by Oracle Corporation
# tar_up_partial_archive.sh
# This script tars up some files from an archive directory. You
# can select which files to tar up and send to Oracle Support reducing
# the size of the files which need to be uploaded.
#
# INPUTS:
# $1 = fully qualified path of archive dir
#
# OUTPUTS:
# The output of this utility is osw_archive_MMDDYYHHMM.tar
#######################################################################

count=1

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

echo "Your archive directory contains the following hourly logs"
echo ""

ls -1tr $OSWBB_ARCHIVE_DEST/oswvmstat | \

  while read line
  do
     echo $count:  $line
     count=`expr $count + 1 `
  done

finished=0

while [ $finished != 1 ]
do

  echo ""
  echo "Please enter starting number of log to select for zipping"
  read start
  echo "You selected "$start
  echo ""
  echo "Please enter ending number of log to select for zipping"
  read stop 
  echo "You selected "$stop

  if [ $start -le 0 ]; then
    echo "The value for starting log must be > 0 "
    finished=0
  else
    finished=1

    if [ $stop -le $start ]; then
      echo "The value for ending log must be > value of starting log" 
      finished=0
    else
      finished=1
    fi
  fi
done

rm -rf archive_tmp
mkdir archive_tmp
mkdir archive_tmp/oswvmstat
mkdir archive_tmp/oswiostat
mkdir archive_tmp/oswtop
mkdir archive_tmp/oswmpstat
mkdir archive_tmp/oswnetstat
mkdir archive_tmp/oswmeminfo
mkdir archive_tmp/oswprvtnet
mkdir archive_tmp/oswps
mkdir archive_tmp/oswslabinfo

count=1

ls -1tr archive/oswvmstat | \
while read line
do
  echo $count:  $line
  if [ $count -ge $start ]; then
    if [ $count -le $stop ]; then
       cp archive/oswvmstat/$line archive_tmp/oswvmstat
    fi
  fi
  count=`expr $count + 1 `

done

count=1

ls -1tr archive/oswiostat | \
while read line
do
  echo $count:  $line
  if [ $count -ge $start ]; then
    if [ $count -le $stop ]; then
       cp archive/oswiostat/$line archive_tmp/oswiostat
    fi
  fi
  count=`expr $count + 1 `

done

count=1

ls -1tr archive/oswmpstat | \
while read line
do
  echo $count:  $line
  if [ $count -ge $start ]; then
    if [ $count -le $stop ]; then
       cp archive/oswmpstat/$line archive_tmp/oswmpstat
    fi
  fi
  count=`expr $count + 1 `

done

count=1

ls -1tr archive/oswtop | \
while read line
do
  echo $count:  $line
  if [ $count -ge $start ]; then
    if [ $count -le $stop ]; then
       cp archive/oswtop/$line archive_tmp/oswtop
    fi
  fi
  count=`expr $count + 1 `

done

count=1

ls -1tr archive/oswnetstat | \
while read line
do
  echo $count:  $line
  if [ $count -ge $start ]; then
    if [ $count -le $stop ]; then
       cp archive/oswnetstat/$line archive_tmp/oswnetstat
    fi
  fi
  count=`expr $count + 1 `

done

count=1

ls -1tr archive/oswmeminfo | \
while read line
do
  echo $count:  $line
  if [ $count -ge $start ]; then
    if [ $count -le $stop ]; then
       cp archive/oswmeminfo/$line archive_tmp/oswmeminfo
    fi
  fi
  count=`expr $count + 1 `

done

count=1

ls -1tr archive/oswprvtnet | \
while read line
do
  echo $count:  $line
  if [ $count -ge $start ]; then
    if [ $count -le $stop ]; then
       cp archive/oswprvtnet/$line archive_tmp/oswprvtnet
    fi
  fi
  count=`expr $count + 1 `

done

count=1

ls -1tr archive/oswps | \
while read line
do
  echo $count:  $line
  if [ $count -ge $start ]; then
    if [ $count -le $stop ]; then
       cp archive/oswps/$line archive_tmp/oswps
    fi
  fi
  count=`expr $count + 1 `

done

count=1

ls -1tr archive/oswslabinfo | \
while read line
do
  echo $count:  $line
  if [ $count -ge $start ]; then
    if [ $count -le $stop ]; then
       cp archive/oswslabinfo/$line archive_tmp/oswslabinfo
    fi
  fi
  count=`expr $count + 1 `

done

tar cvf osw_archive.tar archive_tmp
rm -rf archive_tmp

hour=`date +'%m%d%y%H%M.tar'`
mv osw_archive.tar osw_archive_$hour



