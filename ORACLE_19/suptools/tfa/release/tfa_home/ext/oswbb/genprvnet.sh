#!/bin/sh

######################################################################
# Written by Rajendra Ghatge, Center of Expertise, Oracle.
# This script is to configure the private.net file for private Network 
# monitoring for RAC
# Depending on OS Platforms, the private.net file will be configured 
# appropriately.
# Make sure OS utilities traceroute, ifconfig are in your PATH and 
# that you have execute permission on them.
######################################################################


PATH="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/contrib/bin:/etc"
export PATH
PLATFORM=`uname`
TRACERT='traceroute'
IFCONFIG='ifconfig'
FILE=private.net

case $PLATFORM in
Linux)
# echo $PLATFORM
 HOME=`ps -ef |grep crsd.bin | grep -v grep | awk '{print $8}' | head -1`
 GRID_HOME=`echo $HOME | sed 's/\/bin\/crsd.bin//'`
 echo 'echo "zzz ***"`date`' >> $FILE
    for var in `$GRID_HOME/bin/olsnodes` 
      do
       for int in `$GRID_HOME/bin/oifcfg getif | grep cluster | awk '{print $1}'`
         do
           ipaddr=`ssh $var "PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/contrib/bin:/etc $IFCONFIG $int" | grep -i mask | grep -v 169 | awk '{print $2}' |  sed 's/^addr://'`
           echo "$TRACERT -r -F $ipaddr"  >> $FILE
         done 
     done
chmod +x $FILE
echo "rm locks/lock.file" >> $FILE
;;
SunOS)
# echo $PLATFORM
 HOME=`ps -ef |grep crsd.bin | grep -v grep | awk '{print $9}' | head -1`
 GRID_HOME=`echo $HOME | sed 's/\/bin\/crsd.bin//'`
   if [ "$GRID_HOME" = "reboot" ] || [ "GRID_HOME" = "restart" ]
     then
      HOME=`ps -ef |grep crsd.bin | grep -v grep | awk '{print $8}' | head -1`
      GRID_HOME=`echo $HOME | sed 's/\/bin\/crsd.bin//'`
   fi
  echo 'echo "zzz ***"`date`' >> $FILE
    for var in `$GRID_HOME/bin/olsnodes`
      do
        for int in `$GRID_HOME/bin/oifcfg getif | grep cluster | awk '{print $1}'`
          do
           ipaddr=`ssh $var "PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/contrib/bin:/etc $IFCONFIG $int" | grep -i mask | grep -v 169 | awk '{print $2}' |  sed 's/^addr://'`
            echo "$TRACERT -r -F $ipaddr"  >> $FILE
            echo "$TRACERT -I -r -F $ipaddr" >> $FILE
          done
     done
chmod +x $FILE
echo "rm locks/lock.file" >> $FILE
;;
HP-UX|HI-UX)
# echo $PLATFORM
   HOME=`ps -ef |grep crsd.bin | grep -v grep | awk '{print $9}' | head -1`
  GRID_HOME=`echo $HOME | sed 's/\/bin\/crsd.bin//'`
  if [ "$GRID_HOME" = "reboot" ] || [ "GRID_HOME" = "restart" ]
     then
       HOME=`ps -ef |grep crsd.bin | grep -v grep | awk '{print $8}' | head -1`
       GRID_HOME=`echo $HOME | sed 's/\/bin\/crsd.bin//'`
  fi
    echo 'echo "zzz ***"`date`' >> $FILE
   for var in `$GRID_HOME/bin/olsnodes`
     do
      for int in `$GRID_HOME/bin/oifcfg getif | grep cluster | awk '{print $1}'`
         do
          ipaddr=`ssh $var "PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/contrib/bin:/etc $IFCONFIG $int" | grep -i mask | grep -v 169 | awk '{print $2}' |  sed 's/^addr://'`
          echo "$TRACERT -r -F $ipaddr"  >> $FILE
        done
   done
chmod +x $FILE
echo "rm locks/lock.file" >> $FILE
;;
AIX)
# echo $PLATFORM
 HOME=`ps -ef |grep crsd.bin | grep -v grep | awk '{print $9}' | head -1`
 GRID_HOME=`echo $HOME | sed 's/\/bin\/crsd.bin//'`
   if [ "$GRID_HOME" = "reboot" ] || [ "GRID_HOME" = "restart" ]
      then
        HOME=`ps -ef |grep crsd.bin | grep -v grep | awk '{print $8}' | head -1`
        GRID_HOME=`echo $HOME | sed 's/\/bin\/crsd.bin//'`
  fi
  echo 'echo "zzz ***"`date`' >> $FILE
  for var in `$GRID_HOME/bin/olsnodes`
     do
       for int in `$GRID_HOME/bin/oifcfg getif | grep cluster | awk '{print $1}'`
         do 
           ipaddr=`ssh $var "PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/contrib/bin:/etc $IFCONFIG $int" | grep -i mask | grep -v 169 | awk '{print $2}' |  sed 's/^addr://'`
           echo "$TRACERT -r $ipaddr"  >> $FILE
        done
    done
chmod +x $FILE
echo "rm locks/lock.file" >> $FILE		 
;;
esac
