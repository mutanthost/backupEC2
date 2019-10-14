#!/bin/env bash
#
# $Header: tfa/src/orachk/src/zonecores.sh /main/1 2016/05/05 20:16:56 cgirdhar Exp $
#
# zonecores.sh
#
# Copyright (c) 2016, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      zonecores.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    cgirdhar    05/05/16 - script to check core configurations in local zones
#                           in supercluster
#    cgirdhar    05/05/16 - Creation
#

issues=0

#
# We only want to run in global zones.  Check that first
#
if [ `ps -ef|grep /usr/sbin/init|grep -v grep|awk '{print $2}'|sort -n|head -1` != '1' ] ; then
   echo 9196
   exit 1
fi

#
# check if any core is used by less than 8 strands
#
function check_whole_core {
if [ $opmode == report ]; then
   printf "#\n# Checking Whole Core Assignments\n#\n"
fi
for zone in $zones
do
   if [ ${psetidofzone[$zone]} -gt 0 ] ; 
   then
      for c in `cat $tmpdir/${zone}.cores|sort -u`
      do
         strandcount=`wc -l $tmpdir/${zone}.${c}.strands|awk '{print $1}'`
         if [ $strandcount -ne 8 ] ;
         then
            if [ $opmode == report ]; then
                printf "FAIL - only %s strands of core %s in use for zone %s.\n" $strandcount $c $zone
            fi
            issues=1 
         else
            if [ $opmode == report ]; then
               printf "OK - Zone %s using all 8 strands of core %s.\n" $zone $c
            fi
         fi
      done
   else
      if [ $opmode == report ]; then
         printf "OK - Zone %s using default pool.\n" $zone
      fi
   fi
done
} # end function check_whole_core

usage () {
   printf "usage: zonecores -d workdir -o check|report \n"
   exit 1
}

if [ $# -ne 4 ] ;
then
   usage 
else
   args="$@"
fi

while getopts ":d:o:" opt $args ; do
  case "$opt" in
     d) 
       tmpdir=${OPTARG}/zonecores_$$
       if ! ( mkdir -p $tmpdir > /dev/null 2>&1 && touch $tmpdir/testfile > /dev/null 2>&1 )  ; then
          echo Error using working directory $tmpdir
          exit 1
       fi
       ;;
     o) 
       opmode=$OPTARG
       case "$opmode" in
          check);;
          report);;
          *)
            usage
          ;;
       esac
       ;;
     :) 
       usage
       ;;
     *) 
       usage 
       ;;
  esac
done

#
# load a table of thread to core translation into array "core"
# load a table of core to socket translation into array "socket"
#

declare -A core
declare -A socket

tmpthreadmap=$tmpdir/threadmapfile.$$
kstat -m cpu_info -s core_id|\
nawk '/module/{printf ("%s ",$NF)} /core_id/{printf ("%s \n",$NF)}'|sort -n -k 2 > $tmpthreadmap

while read -r key value;
do
   core[$key]=$value
done < $tmpthreadmap

kstat -m cpu_info -s chip_id|\
nawk '/module/{printf ("%s ",$NF)} /chip_id/{printf ("%s \n",$NF)}'|sort -n -k 2 > $tmpthreadmap

while read -r key value;
do
   c=${core[$key]}
   socket[${c}]=$value
done < $tmpthreadmap

corespersocket=`cut -d " " -f 2 $tmpthreadmap|grep ${socket[$c]}|wc -l|awk '{print $NF/8}'`

rm $tmpthreadmap

#
# get psetid for each zone
#
declare -A psetidofzone
zones=`zoneadm list -ivc|egrep -v "NAME|global" |awk '{print $2}'`
for zone in $zones
do

   pool=`zonecfg -z $zone info pool|awk '{print $2}'`
   if [ X${pool}X == "XX" ] ; 
   then
      pool=`pooladm|grep "pool SUNWtmp_${zone}"|cut -d " " -f 2`
      if [ X${pool}X == "XX" ] ; 
      then
         pool=pool_default
     fi    
   fi

   if [ "$pool" == "pool_default" ] ;
   then
      psetidofzone[$zone]=-1
   else
      if poolcfg -dc "info pool $pool" > /dev/null 2>&1  ;
      then
         pset=`poolcfg -dc "info pool $pool" |\
              grep "pset "|cut -d " " -f 2`
         psetidofzone[$zone]=`pooladm|nawk -v pset=$pset \
                             -v found=0 '$2 == pset { found=1 ; next } \
         {if (found == 1) {printf ("%s %s %s\n",pset,$2,$3);found=0; next}}'|\
           grep pset.sys_id | awk '{print $NF}'`
       else
          if [ $opmode == report ]; then
             echo Pool $pool for 
             echo zone $zone defined but not configured!
             echo Broken system configuration - bailing out.
          else
             echo 1
          fi
          exit 1
       fi
    fi
done

# get cpu ids for each zone
#

touch $tmpdir/cores.used  # in case we dont have any pools...

for zone in $zones
do
   if [ ${psetidofzone[$zone]} -gt 0 ] ;
   then
      psrset -i ${psetidofzone[$zone]} |cut -f 2 -d :|cut -d " " -f 3-999|gsed -e 's/\s\+/\n/g'|
      while read strand
      do
         c=${core[$strand]}
         s=${socket[${c}]}
         echo $strand >> $tmpdir/${zone}.${c}.strands
         echo $c $zone >> $tmpdir/cores.used
         echo $c >> $tmpdir/${zone}.cores
         echo $s >> $tmpdir/${zone}.sockets
         echo $strand $c $s >> $tmpdir/${zone}.sockets.all
         echo $zone >> $tmpdir/corezones.$c
      done
   fi
done

#
# main
#

check_whole_core
if [ $opmode == check ]; then
   echo $issues
fi
rm -rf $tmpdir  2>/dev/null

