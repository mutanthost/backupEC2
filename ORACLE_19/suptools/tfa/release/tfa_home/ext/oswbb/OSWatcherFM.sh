#!/bin/sh
######################################################################
# OSWatcherFM.sh
# This is the file manager program called by OSWatcher.sh. This program
# wakes up once a minute to look to see if the hour has changed. If we
# are starting a new hour we look to see how many files we have in
# archive and remove any that are greated than what was specified by
# $1 archiveInterval
######################################################################
# Check each log subdirectory so that only the last archiveInterval number
# of hours of data are kept
######################################################################
#echo "Starting File Manager Process"
PLATFORM=`/bin/uname`
archiveInterval=$1
numberToDelete=0
archiveInterval=`expr $archiveInterval + 1`
check=0

######################################################################
# Loop indefinitely until killed by stopOSW
######################################################################
until [ $check -eq 1 ]
do
######################################################################
# Wake up every 60 seconds to see if hour rollover has occured
######################################################################
sleep 60

######################################################################
# VMSTAT
######################################################################
numberOfFiles=`ls -t $2/oswvmstat | wc -l`
numberToDelete=`expr $numberOfFiles - $archiveInterval`
if [ $numberOfFiles -gt $archiveInterval ]
  then
    ls -t $2/oswvmstat/* | tail -$numberToDelete | xargs rm
fi
######################################################################
# MPSTAT
######################################################################
numberOfFiles=`ls -t $2/oswmpstat | wc -l`
numberToDelete=`expr $numberOfFiles - $archiveInterval`
if [ $numberOfFiles -gt $archiveInterval ]
  then
    ls -t $2/oswmpstat/* | tail -$numberToDelete | xargs rm
fi
######################################################################
# NETSTAT
######################################################################
numberOfFiles=`ls -t $2/oswnetstat | wc -l`
numberToDelete=`expr $numberOfFiles - $archiveInterval`
if [ $numberOfFiles -gt $archiveInterval ]
  then
    ls -t $2/oswnetstat/* | tail -$numberToDelete | xargs rm
fi
######################################################################
# IOSTAT
######################################################################
numberOfFiles=`ls -t $2/oswiostat | wc -l`
numberToDelete=`expr $numberOfFiles - $archiveInterval`
if [ $numberOfFiles -gt $archiveInterval ]
  then
    ls -t $2/oswiostat/* | tail -$numberToDelete | xargs rm
fi
######################################################################
# TOP
######################################################################
numberOfFiles=`ls -t $2/oswtop | wc -l`
numberToDelete=`expr $numberOfFiles - $archiveInterval`
if [ $numberOfFiles -gt $archiveInterval ]
  then
    ls -t $2/oswtop/* | tail -$numberToDelete | xargs rm
fi
######################################################################
# PS -ELF
######################################################################
numberOfFiles=`ls -t $2/oswps | wc -l`
numberToDelete=`expr $numberOfFiles - $archiveInterval`
if [ $numberOfFiles -gt $archiveInterval ]
  then
    ls -t $2/oswps/* | tail -$numberToDelete | xargs rm
fi
######################################################################
# IFCONFIG
######################################################################
numberOfFiles=`ls -t $2/oswifconfig | wc -l`
numberToDelete=`expr $numberOfFiles - $archiveInterval`
if [ $numberOfFiles -gt $archiveInterval ]
  then
    ls -t $2/oswifconfig/* | tail -$numberToDelete | xargs rm
fi
######################################################################
# Private Networks
######################################################################
numberOfFiles=`ls -t $2/oswprvtnet | wc -l`
numberToDelete=`expr $numberOfFiles - $archiveInterval`
if [ $numberOfFiles -gt $archiveInterval ]
  then
    ls -t $2/oswprvtnet/* | tail -$numberToDelete | xargs rm
fi
######################################################################
# Infiniband
######################################################################
if [ -d $2/osw_ib_diagnostics ]; then
numberOfFiles=`ls -t $2/osw_ib_diagnostics | wc -l`
numberToDelete=`expr $numberOfFiles - $archiveInterval`
if [ $numberOfFiles -gt $archiveInterval ]
  then
    ls -t $2/osw_ib_diagnostics/* | tail -$numberToDelete | xargs rm
fi
fi
######################################################################
# RDS
######################################################################
if [ -d $2/osw_rds_diagnostics ]; then
numberOfFiles=`ls -t $2/osw_rds_diagnostics | wc -l`
numberToDelete=`expr $numberOfFiles - $archiveInterval`
if [ $numberOfFiles -gt $archiveInterval ]
  then
    ls -t $2/osw_rds_diagnostics/* | tail -$numberToDelete | xargs rm
fi
fi
######################################################################
# LINUX only
######################################################################
case $PLATFORM in
  Linux)
    numberOfFiles=`ls -t $2/oswmeminfo | wc -l`
    numberToDelete=`expr $numberOfFiles - $archiveInterval`
    if [ $numberOfFiles -gt $archiveInterval ]
     then
       ls -t $2/oswmeminfo/* | tail -$numberToDelete | xargs rm
    fi
    numberOfFiles=`ls -t $2/oswslabinfo | wc -l`
    numberToDelete=`expr $numberOfFiles - $archiveInterval`
    if [ $numberOfFiles -gt $archiveInterval ]
     then
       ls -t $2/oswslabinfo/* | tail -$numberToDelete | xargs rm
    fi
    if [ -d $2/oswnfs ]; then
    numberOfFiles=`ls -t $2/oswnfs | wc -l`
    numberToDelete=`expr $numberOfFiles - $archiveInterval`
    if [ $numberOfFiles -gt $archiveInterval ]
     then
       ls -t $2/oswnfs/* | tail -$numberToDelete | xargs rm
    fi    
    fi
esac

######################################################################
# Extras only
######################################################################
   if [ -f extras.txt ]; then

   EX_FILE=extras.txt
   for i in `grep -v ^# ${EX_FILE} | awk '{print $3}'`
   do

   numberOfFiles=`ls -t $2/$i | wc -l`
   numberToDelete=`expr $numberOfFiles - $archiveInterval`

   if [ $numberOfFiles -gt $archiveInterval ]
   then
      ls -t $2/$i/* | tail -$numberToDelete | xargs rm
   fi    

   done
   fi
done
