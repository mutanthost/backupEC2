#!/bin/sh
#
# $Header: gitools/src/racassurance/tfa/v2/tfa_home/bin/profiling.sh /main/1 2012/08/06 13:43:56 bburton Exp $
#
# profiling.sh
#
# Copyright (c) 2012, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      profiling.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     07/30/12 - Creation
#
#!/bin/bash
perl_pid=$1
file_name=$2
echo "Perl pid : $perl_pid"

while kill -0 $perl_pid
do
  pids=`pstree -p $perl_pid | grep -o '[0-9]\{2,5\}'`
  date >> $file_name
  for pid in $pids
  do
    top -b -n 1 | grep $pid | awk '{print $1, $9}' >> $file_name
  done
  sleep 10
done

#echo "Looking for java pid : pstree -p $perl_pid | egrep -o java([0-9]+ | cut -c6-"
#java_pid=`pstree -p $perl_pid | egrep -o "java\([0-9]+" | cut -c6-`
#echo "Java pid : $java_pid\n"


#file_name="../output/inventory/inv.txt"
#status=`kill -0 $java_pid`
#echo $status
#while kill -0 $java_pid 
#do
#  date >> $file_name
 # top -b -n 1 | grep $java_pid | awk '{print $1, $9}' >> $file_name
 # sleep 10
#done
