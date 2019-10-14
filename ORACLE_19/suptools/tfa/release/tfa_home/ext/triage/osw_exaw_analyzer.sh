#!/bin/bash
#
# $Header: tfa/src/v2/ext/triage/osw_exaw_analyzer.sh /main/2 2015/11/30 01:08:07 bibsahoo Exp $
#
# osw_exaw_analyzer.sh
#
# Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      osw_exaw_analyzer.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bibsahoo    11/19/15 - FIX BUG 22186000 - SOLSP64-12.2-TFA:NEED MORE
#                           MEANINGFUL AND CLEAR MESSAGE FOR TRIAGE
#    gadiga      08/04/15 - Run oswatcher,exawatcher analyzer
#    gadiga      08/04/15 - Creation
#
##############################################################
#
#  osw.sh created   rordona   04/09/2013
#         modified  rordona   04/14/2015  [ exawatcher ]
#
##############################################################

host=`hostname`
script=$0

base=`basename $0`
basedir=`echo $script|sed "s/$base//g"`

if [ "${basedir}" == "./"  -o "${basedir}" == "" ]; then
   script=`pwd`/$base

fi

echo "Today's server date: " `date`


exa_archive=/opt/oracle.ExaWatcher/archive
git_archive=/var/log/ops/os-watcher/archive
eis_archive=/opt/oracle.oswatcher/osw/archive
working_dir=/u03/AIA/triage/osw

if [ -f /proc/sys/vm/min_free_kbytes ] ; then
  min_kbytes_free=`cat /proc/sys/vm/min_free_kbytes`
else
 echo "File /proc/sys/vm/min_free_kbytes not present"
 exit;
fi

if [ -n $OSW_DIR ] ; then
  eis_archive=$OSW_DIR
fi

############### Function Calls ################################################



usage() {

cat<<eof!

  usage: osw.sh -t <datetime> -d <duration> -w <working directory> [-a] [-c] [-h]
    where date     = YY.MM.DD.HH00>
    where duration = number of hours

  To print usage:

  e.g      osw.sh -h

  To print available dates in oswatcher

  e.g      osw.sh -a

  To run report:

  e.g      osw.sh -t 13.03.15.0400 -d 2 -w /u03/AIA/triage/osw

  To show activity of a specific process

  e.g      osw.sh -t 13.03.15.0400 -d 2 -w /u03/AIA/triage/osw -p <pid>

  To copy archives to working directory first, then run report:

  e.g      osw.sh -t 13.03.15.0400 -d 2 -w /u03/AIA/triage/osw -c



eof!
}

get_archive_dir() {

   if [ -d $exa_archive ]; then

     arch_dir=$exa_archive

   elif [ -d $eis_archive ]; then

     arch_dir=$eis_archive

   elif [ -d $git_archive ]; then

     arch_dir=$git_archive

   fi
}

uNzip() {
  local osw_file="$1"
  local local_file=""
  local jfile=""
 for oswf in `ls ${osw_file}*`; do

  if [ -f "${oswf}" -a `echo "$oswf"|grep -c "bz2$"` -gt 0  ]; then
        bunzip2 -f ${oswf}
        jfile=`echo $oswf}|sed -e "s/\.bz2$//g"`
        local_file=`echo "$local_file ${jfile}"`
  elif [ -f "${oswf}" -a `echo "$oswf"|grep -c "gz$"` -gt 0 ]; then
        gunzip -f ${oswf}
        jfile=`echo $oswf}|sed -e "s/\.gz$//g"`
        local_file=`echo "$local_file ${jfile}"`
  elif [ -f "${oswf}" ]; then
        local_file=`echo "$local_file ${oswf}"`
  fi

 done
  if [ "${local_file}" == "" ]; then
     echo "empty"
  else
    echo "$local_file"
  fi
}


get_exa_range() {
  ## note this is a simple hour range calculation and won't work with epoc and leap years
  ## example if you specify hour to be 23:00 and you want duration of 2 hours, date will not wrap
  local atype=$1
  local sdate=$2
  local typeset int duration=$3
  local ddate=`echo $sdate| gawk -F. '{print $1"_"$2"_"$3}'`
  local typeset int dhour=`echo $sdate| gawk -F. '{print $4}'`

  if [ ! -n "$dhour" -o "$dhour" == "" ]; then
    echo "exit"

  else

     local typeset int dlhour=`expr $dhour  +  \( $duration - 1 \)`
     local dat=''

      for h in `seq --format="%02g" $dhour $dlhour`; do
       dat=`echo "$dat ${ddate}_${h}_??_??_${atype}ExaWatcher_${host}.dat"`
       done

    echo "$dat"

 fi

}


getrange() {
  ## note this is a simple hour range calculation and won't work with epoc and leap years
  ## example if you specify hour to be 23:00 and you want duration of 2 hours, date will not wrap
  local atype=$1
  local sdate=$2
  local typeset int duration=$3
  local ddate=`echo $sdate| gawk -F. '{print $1"."$2"."$3}'`
  local typeset int dhour=`echo $sdate| gawk -F. '{print $4}'`

  if [ ! -n "$dhour" -o "$dhour" == "" ]; then
    echo "exit"

  else

     local typeset int dlhour=`expr $dhour  +  \( $duration - 1 \) \* 100`
     local dat=''

      for h in `seq --format="%04g" $dhour 100 $dlhour`; do
       dat=`echo "$dat ${host}_${atype}_${ddate}.${h}.dat"`
       done

    echo "$dat"

 fi
}

show_exa_available_dates() {


  echo "Available Dates:"


if  [ -d /opt/oracle.ExaWatcher/archive ]; then



   ls -1f  /opt/oracle.ExaWatcher/archive/Top.ExaWatcher | egrep "dat(|.bz2|.gz)$"|  gawk -F"_" '{ print $1"."$2"."$3" "$4}'|sort|uniq|gawk  '
      BEGIN {  cnt_dd=0; cnt_hh=0  }
            {
                if (a[$1]==$1) { cnt_hh++ } else { cnt_hh=0; d[cnt_dd++]=$1  }
                 a[$1]=$1
		 b[$1, cnt_hh ]=$2; 
		 e[$1]=cnt_hh; 
             }
      END { 
		for (x = 0; x <cnt_dd; x++) {
                  r=d[x]
                  mc=e[r]
                  printf "    " a[r];
		  for (y = 0; y <=mc; y++) {
                     printf "."b[a[r],y];
                  }
                  print "";
		}
          }
        ' 

else

  for h in `ls -1f $arch_dir/* | egrep "dat(|.bz2|.gz)$" | gawk -F"_" '{ print $1"."$2"."$3" "$4}'|sort|uniq|gawk '
      BEGIN { d=$1; c=$1 }
            {
              if (d==$1) { c=c"."$2; p=1 } else { print c; d=$1; c=$1; p=0 }
             }
      END { if (p==1) print c }
        '`; do

    echo "   $h"

  done

fi

}

show_available_dates() {

  echo "Available Dates:"

  for h in `ls -1f $arch_dir/*| egrep "dat(|.bz2|.gz)$" | cut -d"_" -f3|gawk -F"." '{print $1"."$2"."$3" "$4}'|
    sort|uniq|gawk '
      BEGIN { d=$1; c=$1 }
            {
              if (d==$1) { c=c"."$2; p=1 } else { print c; d=$1; c=$1; p=0 }
             }
      END { if (p==1) print c }
        '`; do

    echo "   $h"

  done

}

show_pid() {
  local mypid=$1
  local topdat="$2"
  egrep -h "^ *$mypid |load average" $topdat | grep -B1 "^ *$mypid " | grep -v grep |
    gawk '/load average/ { d=$0 } !/load average/ { print d" "$0 }' |
    gawk ' BEGIN {
           printf("%8s %5s %5s %20s %6s %15s %5s %5s %6s %6s %6s %1s %5s %5s %8s %20s\n",
             "Time","Days","Users","Load_Average","PID","User","Pri","Ni","VIRT","RES","SHR","S","%CPU","%MEM","TIME+","Command");
         }
         {
           printf("%8s %5i %5i %6.2f %6.2f %6.2f %6i %15s %5i %5i %6s %6s %6s %1s %5.1f %5.1f %8s, %20s\n",
            $3, $5, $8, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26" "$27);

         }'
}


show_top_pids() {

   local pids="$1"
   local regex="$2"
   local ttle="$3"

    egrep -h "load average| (R|D|Z|S) " $topdat | grep -v grep |
    gawk  '/load average/ {d=$0} !/load average/ { print d" "$0 }' |
    gawk -v pids="$pids" -v ptrn="$regex" -v ttle="$ttle" '

       function nvl(fmt, v) {
           if (v==0) return  "-"
           if (match(v,"g$|m$|t$")) return v
           return sprintf(fmt,v)
       }

       function report (stat,tit, fmt, ttle) {
        print ""
        print "---- ( "ttle" )" tit" --------"
        lsp=length(spids)
        lre=length(sorted[1])
        nspids=""
        for (j=1; j<=lsp; j++) {
             n=spids[j]
             nspids=sprintf("%s %6s", nspids, n)
        }
        nsl=length(nspids)
        printf("\n%"lre"s %s snapshot\n", "Load Average", nspids)
        # printf("%"lre"s %"nsl"s delta\n", "", "")
        ostat=""; statcnt=0
        for (ix=0; ix<cnt; ix++) {
          i=sorted[ix]
          nstat=""
          for (j=1; j<=lsp; j++) {
             n=spids[j]
             vstat=nvl(fmt, stat[i,n])
             nstat=sprintf("%s %6s", nstat, vstat)
          }
          if ( nstat != ostat || ix==cnt-1) {
            # if ( ostat != "") printf(" ... ( %d ) ...\n", statcnt )
            printf("%s %s (%d)\n", i,  nstat, statcnt);
            ostat = nstat
            statcnt=0
          } else
          if ( ostat != "" ) {
             statcnt++
          }
        }
       }
       BEGIN { split (pids, spids, " "); cnt=0; xdat=""   }
          $6 ~/days/ { dat=sprintf("top %8s %5i %8.2f %8.2f %8.2f",$3, $8, $12, $13, $14); }
          $6 ~/min/ {  dat=sprintf("top %8s %5i %8.2f %8.2f %8.2f",$3, $7, $11, $12, $13); }
          $6 !~ /min|days/ {  dat=sprintf("top %8s %5i %8.2f %8.2f %8.2f",$3, $6, $10, $11, $12); }
             {
               if (dat != xdat) {
                sorted[cnt++]=dat
                xdat=dat
               }
             }
       $6 ~ /days/ && $15 ~ ptrn {
               virt_a[dat,$15]=$19
               rsz_a[dat,$15]=$20
               sz_a[dat,$15]=$21
               pcpu_a[dat,$15]=$23
               pmem_a[dat,$15]=$24
       }
       $6 ~ /min/ && $14 ~ ptrn {
               virt_a[dat,$14]=$18
               rsz_a[dat,$14]=$19
               sz_a[dat,$14]=$20
               pcpu_a[dat,$14]=$22
               pmem_a[dat,$14]=$23
       }
       $6 !~ /min|days/ && $13 ~ ptrn {
               virt_a[dat,$13]=$17
               rsz_a[dat,$13]=$18
               sz_a[dat,$13]=$19
               pcpu_a[dat,$13]=$21
               pmem_a[dat,$13]=$22
       }
       END {
           report(pcpu_a,"Percent CPU", "%6.2f", ttle)
           report(pmem_a,"Percent Memory", "%6.2f", ttle)
           report(rsz_a,"Resident","%6i", ttle)
           report(sz_a,"Size", "%6i", ttle)
           report(virt_a,"Virtual","%6i", ttle)
       }
       '

}

get_top_ps_cpu() {
   local topdat="$1"
   local cnt1=0
   local pids=""
   local regex=""

    echo "  "
    echo "--- Top 15 Running Processes with High CPU"
    echo "  "
     printf "    %8s %8s %s\n" "PID" "COUNT" "COMMAND"

   for h in `awk '$8=="R" && $9>0 { print $1":"$12 }' $topdat|
      sort -k1,1 -n|uniq -c | sort -k1,1 -rn | awk '{print $1" "$2}' | sed -e "s/ /:/g"`; do
      cnt=`echo $h|cut -d":" -f1`
      pid=`echo $h|cut -d":" -f2`
      cmd=`echo $h|cut -d":" -f3`
      cnt1=`expr $cnt1 + 1`
      pids=`echo $pids $pid`
      regex=`echo "$regex^$pid$|"`

      printf "    %8s %8s %s\n" $pid $cnt $cmd

      if [ $cnt1 -ge 15 ]; then
         regex=`echo $regex | sed -e "s/|$//g"`
         break
      fi
    done

    echo ""
    show_top_pids "$pids" "$regex" "Top CPU"
}

get_top_ps_mem() {
   local topdat="$1"
   local cnt1=0
   local pids=""
   local regex=""

    echo "  "
    echo "--- Top 15 Processes with High Memory Usage (Resident/Size)"
    echo " "
    printf "    %8s %8s %s\n" "PID" "COUNT" "COMMAND"

   for h in `awk '
      $8 ~/R|Z|D|S/ && ( $6 ~ /t$/ || $7 ~ /t$/ || $6 ~ /g$/ || $7 ~ /g$/ || ( $6 ~ /m$/ && $6 > 500)   || ( $7 ~ /m$/ && $7 > 500) )  { print $1":"$12 }' $topdat|
      sort -k1,1 -n|uniq -c | sort -k1,1 -rn | awk '{print $1" "$2}' | sed -e "s/ /:/g"`; do
      cnt=`echo $h|cut -d":" -f1`
      pid=`echo $h|cut -d":" -f2`
      cmd=`echo $h|cut -d":" -f3`
      cnt1=`expr $cnt1 + 1`
      pids=`echo $pids $pid`
      regex=`echo "$regex^$pid$|"`

      printf "    %8s %8s %s\n" $pid $cnt $cmd

      if [ $cnt1 -ge 15 ]; then
         regex=`echo $regex | sed -e "s/|$//g"`
         break
      fi
    done

     show_top_pids "$pids" "$regex" "Top Memory Usage"
}



get_top_ps_io() {
   local topdat="$1"
   local cnt1=0
   local pids=""
   local regex=""

   echo " "
   echo " "
   echo "--- Top 15 Processes with High Disk/Uninterruptible Sleep Count (I/O)"
   echo " "
   printf "    %8s %8s %s\n" "PID" "COUNT" "COMMAND"

   for h in `awk '
      $8=="D" { print $1":"$12 }' $topdat|
      sort -k1,1 -n|uniq -c | sort -k1,1 -rn | awk '{print $1" "$2}' | sed -e "s/ /:/g"`; do
      cnt=`echo $h|cut -d":" -f1`
      pid=`echo $h|cut -d":" -f2`
      cmd=`echo $h|cut -d":" -f3`
      cnt1=`expr $cnt1 + 1`
      pids=`echo $pids $pid`
      regex=`echo "$regex^$pid$|"`

      printf "    %8s %8s %s\n" $pid $cnt $cmd

      if [ $cnt1 -ge 15 ]; then
         regex=`echo $regex | sed -e "s/|$//g"`
         break
      fi
    done

    show_top_pids "$pids" "$regex" "Top Disk/Uninterruptible Sleep"
}

function MEMORY_STAT() {

memdat=$(uNzip "$memdat")


if [ $? -eq 0 -a "${memdat}" != "empty" ]; then
  echo ""
  echo ------ Meminfo -----
  egrep -h "(zzz|MemFree|Cached|Buffers|Active|Inactive|CommitLimit|Committed_AS|SwapFree|SwapTotal|HugePages_Total|HugePages_Free|HugePages_Rsvd|NFS_Unstable)" $memdat| grep -v grep  |
    gawk  '/zzz/ {d=$0} !/zzz/ { print d" "$0 }' |
    sed -e  "s/zzz \*\*\*//g" -re "s/zzz <([0-9]*)\/([0-9]*)\/([0-9]*) /\1 \2 \3 /g" -e  "s/> Count:[0-9]*/ TZ . /g"  |
    gawk -v mem="$min_kbytes_free" 'BEGIN { p=10000000000; cnt=0 }
               { dat=$1" "$2" "$3" "$4" "$5" "$6 }
               /MemFree/ {
                           sorted[cnt++]=dat
                           m1[dat]=$8
                           if ( $8<=mem ) p1[dat]=dat
                           if ($8<p)  { p1_k=dat ; p=$8 }
                          }
               /SwapCached/ { m2[dat]=$8 }
               / Cached/ {  m3[dat]=$8 }
               /Buffers/ {  m4[dat]=$8 }
               /Active/ {  m5[dat]=$8 }
               /Inactive/ {  m6[dat]=$8 }
               /CommitLimit/ {  cl=$8 }
               /Committed_AS/ {  pv7=$8/cl*100
                                 m7[dat]=pv7
                                 if (pv7>100) p7[dat]=dat
                               }
               /SwapTotal/ {  m8[dat]=$8; swt=$8 }
               /SwapFree/ {  pv9=$8/swt*100
                             m9[dat]=pv9
                             if (pv9<90) p9[dat]=dat
                             }
               /HugePages_Total/ {   m10[dat]=$8; hpt=$8 }
               /HugePages_Free/ {    if (hpt>0) { m11[dat]=$8/hpt*100 } else {  m11[dat]=-1 } }
               /HugePages_Rsvd/ {  m12[dat]=$8 }
               /NFS_Unstable/ {  m13[dat]=$8 }
         END   {
                  tlen=length(dat)
                  printf("%"tlen"s %10s %10s %10s %10s %10s %11s %12s\n",
                  "Time", "MemFree","SwapCached","Cached", "Buffers", "(%)Commit","(%)SwapFree","(%)Huge_Free");
                  for (ix=0; ix<cnt; ix++) {
                     i=sorted[ix]
                     peak=""
                     if (i == p1[i] ) peak="*** below minfree "
                     if (i == p1_k ) peak=peak"*** peak lowest "
                     if (i == p7[i] ) peak=peak"*** over-commit "
                     if (i == p9[i] ) peak=peak"*** swapping "
                     if (m11[i]== -1) m11s=sprintf("%12s", "N/A"); else m11s=sprintf("%12.2f", m11[i])
                     printf("%s %10i %10i %10i %10i %10.2f %11.2f %12s %s\n",
                      i,  m1[i],m2[i],m3[i],m4[i],m7[i],m9[i],m11s, peak);
                  }
               }'
fi

}


function TOP_STAT() {

topdat=$(uNzip "$topdat")
if [ $? -eq 0 -a "${topdat}" != "empty" ]; then
  echo ""
  echo ------ Top -----
  egrep -h  "load average|^Tasks|^Cpu" $topdat|sed -e "s/,//g" | grep -v grep |
    sed -e 's/%id//g' -e 's/%wa//g' -e 's/%us//g' -e 's/%sy//g' -e 's/%ni//g'  |
   gawk  'BEGIN { p3=0; p7=0; p11=0; pk_11_90=-1; pk_15=0; cnt=0 }
            /^top -/ {
                 dat=$3 ; sorted[cnt++]=dat  #; print "top:"$0"["$3"]"
                 t1[dat]=$5   # days
                 t2[dat]=$8   # users
                 t3[dat]=$12  # 1 min trend
                 t4[dat]=$13  # 5 min trend
                 t5[dat]=$14  # 10 min trend
                 if ($12>p3) { p3=$12;  pk_3=$12 }
                 ccnt=0
               }
           /^Tasks/ {  # print "task:"$0
                 t6[dat]=$2   # total
                 t7[dat]=$4   # running
                 t8[dat]=$6   # sleeping
                 t9[dat]=$8   # stopped
                 t10[dat]=$10  # zombie
                 if ($4>p7) { p7=$4;  pk_7=$4 }
               }
           /^Cpu[0-9]/ { # print "cpu:"$0
                 t11[dat]+=$3  # %us
                 t12[dat]+=$4  # %sy
                 t13[dat]+=$5  # %ni
                 t14[dat]+=$6  # %idle
                 t15[dat]+=$7  # %wa
                 t16[dat]+=$8  # %hi
                 t17[dat]+=$9  # %si
                 t18[dat]+=$10 # %st
                 x3=t11[dat]; x4=t12[dat];  x7=t15[dat]
                 if (x3+x4>p11) { p11=x3+x4; pk_11=x3+x4 }
                 if (x3+x4>90) { pk_11_90=x3+x4 }
                 if ( x7>p15 ) { p15=x7; pk_15=x7 }
                 ccnt++
               }
           /^Cpu\(s\)/ { # print "cpu:"$0
                 t11[dat]=$2   # %us
                 t12[dat]=$3   # %sy
                 t13[dat]=$4   # %ni
                 t14[dat]=$5   # %idle
                 t15[dat]=$6   # %wa
                 if ($2+$3>p11) { p11=$2+$3; pk_11=$2+$3 }
                 if ($2+$3>90) { pk_11_90=$2+$3 }
                 if ( $6>p15 ) { p15=$6; pk_15=$6 }
                 ccnt++
               }
         END   {
                printf("%8s %5s %5s %26s %5s %5s %5s %5s %6s %5s %5s %5s %5s %5s %5s %5s %5s\n",
                    "Time", "Days","Users","Average_Load","Total","Run","Sleep","Stop","Zombie","%us","%sy","%ni","%id","%wa",
                    "%hi","%si","%st" );
                 for (ix=0;ix <cnt; ix++) {
                    peak=""
                    i=sorted[ix]
                    if (t3[i]==pk_3) peak=" *** peak load"
                    if (t7[i]==pk_7) peak=peak" *** peak runqueue"
                    if (t11[i]+t12[i]==pk_11) peak=peak" *** peak usage"
                    if (t11[i]+t12[i]==pk_11_90) peak=peak" *** over 90 usage"
                    if (t15[i]==pk_15) peak=peak" *** peak iowait"

                    printf("%s %5i %5i %8.2f %8.2f %8.2f %5i %5i %5i %5i %6i %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f %5.1f %s\n", i,
                      t1[i],t2[i],t3[i],t4[i],t5[i],t6[i],t7[i],t8[i],t9[i],t10[i],
                      t11[i]/ccnt,t12[i]/ccnt,t13[i]/ccnt, t14[i]/ccnt, t15[i]/ccnt,
                      t16[i]/ccnt, t17[i]/ccnt, t18[i]/ccnt, peak);

                  }
               }'

   get_top_proc=1

fi

}

function PS_STAT(){

psdat=$(uNzip "$psdat")

if [ $? -eq 0 -a "${psdat}" != "empty" ]; then
  echo ""
  echo "------ PS summary (Histogram) -----"

   egrep -h "^zzz| (R|D|Z) " $psdat | sed "s/^.*zzz \*\*\*/zzz ***/" | grep -v grep |
    gawk  '/zzz/ {d=$0} !/zzz/ { print d" "$0 }'  |
    sed -e  "s/zzz \*\*\*//g" -re "s/zzz <([0-9]*)\/([0-9]*)\/([0-9]*) /\1 \2 \3 /g" -e  "s/> Count:[0-9]*/ TZ . /g"  |
    gawk '

          function nvl( v) {
           if (v==0) return  "-"
           return sprintf("%3i",v)
           }

     BEGIN  { p=0; pa=0; pp=0; pcpu=0; xdat=""; cnt=0 }
      {
          dat=$1" "$2" "$3" "$4" "$5" "$6
          if (dat != xdat) {


            if (r>p) { pk=xdat; p=r }
            if (ac>pa) { pk1=xdat; pa=ac }
            if (ac>pa && r > 1) { pk1=xdat; pa=ac }
            if (histr_95>pp) { pk2=xdat; pp=histr_95 }
            if (cpu>pcpu) { pk3=xdat; pcpu=cpu }

            r=0; z=0; d=0; cpu=0; ac=0
            histr_95=0;
            histr_90=0;
            histr_85=0;
            histr_80=0;
            histr_70=0;
            histr_60=0;
            histr_50=0;
            histr_40=0;
            histr_30=0;
            histr_20=0;
            histr_0=0;
            xdat=dat
            sorted[cnt++]= dat
          }
          if ( $8=="D" || $8=="R" || $8=="Z" ) {
              cpu=cpu+$12;
              if ( $12>=95 && $12<=100) histr_95++;
              if ( $12>=90 && $12<=94)  histr_90++ ;
              if ( $12>=85 && $12<=89)  histr_85++ ;
              if ( $12>=80 && $12<=84)  histr_80++ ;
              if ( $12>=70 && $12<=79)  histr_70++ ;
              if ( $12>=60 && $12<=69)  histr_60++ ;
              if ( $12>=50 && $12<=59)  histr_50++ ;
              if ( $12>=40 && $12<=49)  histr_40++ ;
              if ( $12>=30 && $12<=39)  histr_30++ ;
              if ( $12>=20 && $12<=29)  histr_20++ ;
              if ( $12<20 )             histr_0++ ;
            }
           if ($8=="R") r++;
           if ($8=="D") d++;
           if ($8=="Z") z++;
           if ($12>0) { if (r>0) ac=cpu/r  }

           arr[dat]= sprintf( "%s (%5iR %5iZ %5iD ) CPU( %5i/%3i ) Histogram( %3s %3s %3s %3s %3s %3s %3s %3s %3s %3s %3s )",
                 dat, r, z, d, cpu, ac,
                      nvl(histr_95), nvl(histr_90),
                      nvl(histr_85), nvl(histr_80),
                      nvl(histr_70), nvl(histr_60),
                      nvl(histr_50), nvl(histr_40),
                      nvl(histr_30), nvl(histr_20), nvl(histr_0))


      }
      END    {

            if (r>p) { pk=xdat; p=r }
            if (ac>pa) { pk1=xdat; pa=ac }
            if (histr_95>pp) { pk2=xdat; pp=histr_95 }

                for (ix=0; ix<cnt; ix++) {
                    peak=""
                    i=sorted[ix]
                    if (i==pk)  peak=" *** peak runqueue count ***"
                    if (i==pk1) peak=peak" *** peak cpu avg ***"
                    if (i==pk2) peak=peak" *** peak high cpu ***"
                    if (i==pk3) peak=peak" *** peak cpu util ***"
                    print arr[i]" "peak;
                }
        }' | sed  "s/zzz \*\*\*//g"

  get_ps_detail=1
fi

if [  -n "$get_top_proc" -a "${topdat}" != "empty" ]; then
  echo ""
  get_top_ps_cpu "$topdat"
  get_top_ps_mem "$topdat"
  get_top_ps_io  "$topdat"
fi

}



function IO_STAT() {

iodat=$(uNzip "$iodat")
if [ $? -eq 0  -a "${iodat}" != "empty" ]; then
  echo ""
  echo ------ IOstat -----

 prta=`cat /proc/partitions|awk '{print $4}'|egrep -v "name|loop"|sort|xargs echo`
 prt=$(echo $prta|sed "s/ /\$\|^/g")

 gawk '/zzz/ { d=$0 } /^Time/ { d1=$0 } !/zzz/ && !/^Time/ { print d" "d1" "$0 } ' $iodat | sed "s/zzz \*\*\*//g" |
 gawk -v pattrn="^$prt\$" -v plist="$prta" '

       function nvl(fmt, v) {
           if (v==0) return  "-"
           return sprintf(fmt,v)
       }



   function report(iostat, tit, peakm, opeak) {
     print ""
     print "---- "tit" -----"
     split(plist,pdev," ")
     pdev_s=""; plen=length(pdev)

     ### get active devs
     xcnt=0
     for (iy=1; iy<=plen; iy++) {
         xfound=0
         for (ix=0; ix<cnt; ix++) {
             i=sorted[ix]
             idev=pdev[iy]
             u=iostat[i,idev]
             if (u>1) { xfound=1 }
         }
         if (xfound==1) { ldev[xcnt++]=pdev[iy] }
      }
      plen = xcnt - 1
     #split(plist,ldev," ")

     for (i=1; i<=plen; i++) {
       s=sprintf("%7s", ldev[i])
       pdev_s=pdev_s" "s
     }
     lte=length(dat)
     printf("%"lte"s %s\n", "Time",  pdev_s )


     for (ix=0; ix<cnt; ix++) {
      peak=""; opeakm=""
      i=sorted[ix]
      pdev_s=""
      for (iy=1; iy<=plen; iy++) {
       u=iostat[i,ldev[iy]]
       s=sprintf("%7s", nvl("%7.2f", u) )
       pdev_s=pdev_s" "s
       if (u>=70) peak=peakm
       if (u==opeak) opeakm=" top peak *** "
      }
      printf("%s %5s %s %s\n", i, pdev_s, peak, opeakm );
    }
   }

    BEGIN { xdat=""; cnt=0; pk_avg=0; pk_await=0; pk_svc=0; pk_util=0 }
   /Time/ {
      dat=$1" "$2" "$3" "$12" "$5" "$6

         if (dat != xdat ) {
            sorted[cnt++]=dat
            xdat = dat
         }

     }

    $13 ~ pattrn {
     dev[dat,$13]=$13
     avgqu[dat,$13]=$21
     await[dat,$13]=$22
     svctm[dat,$13]=$23
     util[dat,$13]=$24
     if ($21>pk_avg) pk_avg=$21
     if ($22>pk_await) pk_await=$22
     if ($23>pk_svc) pk_svc=$23
     if ($24>pk_util) pk_util=$24
    }

   END {

     report(util, "%Utilization"," peak i/o util *** ", pk_util)
     report(svctm, "Service Time", " peak i/o service *** ", pk_svc)
     report(await, "I/O Wait", " peak i/o wait *** ", pk_await)
     report(avgqu, "I/O Avg Queue", " peak i/o avg queue *** ", pk_avg)
   }

 '

fi


}

function NET_STAT() {

netdat=$(uNzip "$netdat")
if [ $? -eq 0  -a "${netdat}" != "empty" ]; then
  echo ""
  echo "------ Netstat (Deltas) -----"
   egrep -hv "no statistics available" $netdat |
   gawk  '
    function capture(rec, ind) {
      #if ($1 > 0) dz[ind] = 1
      return $1
    }

       function nvl(fmt, v) {
           if (v==0) return  "-"
           return sprintf(fmt,v)
       }

       function report_int( tit, nstat) {
         print ""
         print "------ "tit" -------"
         print ""
         t19_nlen=length(t19_n)
         t19_s=""
         for (iy=0; iy < ncnt; iy++) {
               i=t19_n[iy]
               s=sprintf("%8s", i);
               t19_s=t19_s" "s
         }
         printf("\n%"tle"s %s snapshot\n", "", t19_s);

         ostat=""; ocnt=0;
         for (ix=0;ix <cnt; ix++) {
             i=sorted[ix]
             t19_s=""
            for (iy=0; iy < ncnt; iy++) {
                 inp=t19_n[iy]
                 if (ix==0) trx_d=nstat[i, inp]
                 if (ix!=0) { oi=sorted[ix-1]; trx_d = nstat[i, inp] - nstat[oi,inp]; }
                 s=sprintf("%8s", nvl("%8i", trx_d));
                 t19_s=t19_s" "s
            }
            if (t19_s != ostat || ix==cnt-1) { printf("%s %s (%i) \n", i,  t19_s, ocnt); ostat=t19_s; ocnt=0 } else
            { ocnt++ }
        }
    }

    BEGIN { cnt=0; xdat=""; ncnt=0; nchk=0
            for (i=1; i<=18; i++) dz[i]=0
           }
            /^zzz/ { dat=$2" "$3" "$4" "$5" "$6; tlen=length(dat)
                      if (dat != xdat) {
                      sorted[cnt++]=dat
                      xdat=dat
                      nchk++
                     }
                   }
    /total packets received/ { t1[dat]=capture($0, 1) }
    /with invalid addresses/   { t2[dat]=capture($0, 2) }
    /incoming packets discarded/  { t3[dat]=capture($0, 3) }
    /incoming packets delivered/  { t4[dat]=capture($0, 4) }
    /ICMP messages received/  { t5[dat]=capture($0, 5) }
    /input ICMP message failed/  { t6[dat]=capture($0, 6) }
    /active connections openings/  { t7[dat]=capture($0, 7) }
    /passive connection openings/  { t8[dat]=capture($0, 8) }
    /failed connection attempts/  { t9[dat]=capture($0, 9) }
    /connection resets received/  { t10[dat]=capture($0, 10) }
    /connections established/  { t11[dat]=capture($0, 11) }
    /segments retransmited/  { t12[dat]=capture($0, 12) }
    /bad segments received/  { t13[dat]=capture($0, 13) }
    /resets sent/  { t14[dat]=capture($0, 14) }
    /packets received/  { t15[dat]=capture($0, 15) }
    /packets to unknown port received/  { t16[dat]=capture($0, 16) }
    /packet receive errors/  { t17[dat]=capture($0, 17) }
    /ICMP messages failed/  { t18[dat]=capture($0, 18) }
    /^bond(eth|ib)|^eth[0-9]|^ib[0-9]/ {
             if (nchk==1) {
               t19_n[ncnt++]=$1
             }
             t19_r1[dat,$1]=$4  # RX-OK
             t19_r2[dat,$1]=$5  # RX-ERR
             t19_r3[dat,$1]=$6  # RX-DRP
             t19_r4[dat,$1]=$7  # RX-OVR
             t19_r5[dat,$1]=$8  # TX-OK
             t19_r6[dat,$1]=$9  # TX-ERR
             t19_r7[dat,$1]=$10 # TX-DRP
             t19_r8[dat,$1]=$11 # TX-OVR
         }
         END   {

            print " "
            print "   1 total packets received (k)        10 connection resets received"
            print "   2 with invalid addresses            11 connections established"
            print "   3 incoming packets discarded        12 segments retransmited"
            print "   4 incoming packets delivered (k)    13 bad segments received"
            print "   5 ICMP messages received            14 resets sent (k)"
            print "   6 input ICMP message failed         15 packets received (k)"
            print "   7 active connections openings       16 packets to unknown port received"
            print "   8 passive connection openings       17 packet receive errors"
            print "   9 failed connection attempts        18 ICMP messages failed"
            print " "
                printf("%"tlen"s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s\n",
                    "Time", "(1)", "(2)", "(3)","(4)","(5)","(6)","(7)","(8)","(9)","(10)","(11)",
                    "(12)", "(13)","(14)","(15)","(16)","(17)", "(18)");

                 for (ix=0;ix <cnt; ix++) {
                    peak=""
                    i=sorted[ix]

                    if (ix==0) {
                      t1_d=t1[i];
                      t2_d=t2[i];
                      t3_d=t3[i];
                      t4_d=t4[i];
                      t5_d=t5[i];
                      t6_d=t6[i];
                      t7_d=t7[i];
                      t8_d=t8[i];
                      t9_d=t9[i];
                      t10_d=t10[i];
                      t11_d=t11[i];
                      t12_d=t12[i];
                      t13_d=t13[i];
                      t14_d=t14[i];
                      t15_d=t15[i];
                      t16_d=t16[i];
                      t17_d=t17[i];
                      t18_d=t18[i]
                    } else {
                      oi=sorted[ix-1]
                      t1_d=t1[i]-t1[oi];
                      t2_d=t2[i]-t2[oi];
                      t3_d=t3[i]-t3[oi];
                      t4_d=t4[i]-t4[oi];
                      t5_d=t5[i]-t5[oi];
                      t6_d=t6[i]-t6[oi];
                      t7_d=t7[i]-t7[oi];
                      t8_d=t8[i]-t8[oi];
                      t9_d=t9[i]-t9[oi];
                      t10_d=t10[i]-t10[oi];
                      t11_d=t11[i]-t11[oi];
                      t12_d=t12[i]-t12[oi];
                      t13_d=t13[i]-t13[oi];
                      t14_d=t14[i]-t14[oi];
                      t15_d=t15[i]-t15[oi];
                      t16_d=t16[i]-t16[oi];
                      t17_d=t17[i]-t17[oi];
                      t18_d=t18[i]-t18[oi]

                    }

                    printf("%s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s %7s %s\n", i,
                      nvl("%7i", t1_d/1000),
                      nvl("%7i", t2_d),
                      nvl("%7i", t3_d),
                      nvl("%7i", t4_d/1000),
                      nvl("%7i", t5_d),
                      nvl("%7i", t6_d),
                      nvl("%7i", t7_d),
                      nvl("%7i", t8_d),
                      nvl("%7i", t9_d),
                      nvl("%7i", t10_d),
                      nvl("%7i", t11_d),
                      nvl("%7i", t12_d),
                      nvl("%7i", t13_d),
                      nvl("%7i", t14_d/1000),
                      nvl("%7i", t15_d/1000),
                      nvl("%7i", t16_d),
                      nvl("%7i", t17_d),
                      nvl("%7i", t18_d), peak);

                     tle=length(i)
                  }

                 report_int( "Netstat RX-ERR (Deltas)", t19_r2)
                 report_int( "Netstat RX-DRP (Deltas)", t19_r3)
                 report_int( "Netstat RX-OVR (Deltas)", t19_r4)
                 report_int( "Netstat TX-ERR (Deltas)", t19_r6)
                 report_int( "Netstat TX-DRP (Deltas)", t19_r7)
                 report_int( "Netstat TX-OVR (Deltas)", t19_r8)

                 report_int( "Netstat TX-OK (Deltas)", t19_r5)
                 report_int( "Netstat RX-OK (Deltas)", t19_r1)


               }'

fi


}

function RDS_STAT() {

rdsdat=$(uNzip "$rdsdat")

if [ $? -eq 0  -a "${rdsdat}" != "empty" ]; then

  if [ -f $oswh ]; then

  param=`cat $script|gawk '/--BEGIN_RDS--/,/--END_RDS--/ { print $0}'|grep -v "RDS--"|grep -v "^#"`

  cnt=0
  ##### Print list of RDS counters
  echo ""
  echo ------ IB Counters -----
  echo $param | awk '
      {
        split($0,arr," ")
        n=length(arr)
        l=int(n/3)
        for (i=0;i<n;i++) {
           z=i%l
           str=sprintf("%2i %-30s", i+1,  arr[i+1])
           prm[z]=prm[z]" "str
        }
      }
      END {
      print ""
       for (i=0;i<l;i++) {
         print prm[i]
       }

      }'

  echo ""
  echo ------ Top Active IB Counters -----
  param=`echo $param|sed -e "s/ /\|/g"`
    egrep -h "zzz|$param" $rdsdat|gawk '/zzz/ {d=$0} !/zzz/ { print d" "$0}'| grep -v grep |
     sed -e  "s/zzz \*\*\*//g" -re "s/zzz <([0-9]*)\/([0-9]*)\/([0-9]*) /\1 \2 \3 /g" -e  "s/> Count:[0-9]*/ TZ . . /g"  |
      gawk -v param="$param" '

          function nvl(fmt, v) {
           if (v==0) return  "-"
           return sprintf(fmt,v)
           }


              BEGIN {
                      p=0; xdat=""; cnt=0 ; cntp=0
                      split(param,parama,"|")
                      l=length(parama)
                      for (n=0;n<l;n++) { parcount[n]=0 }
                 }
             { dat=$1" "$2" "$3" "$4" "$5" "$6" "$7
               arr[dat,$8]=$9
               if (xdat!=dat) {
                  sorted[cnt++]=dat
                  xdat=dat
               }
               if (arr[dat,$8]!=arr[xdat,$8] || $9>0) {
                    parlist[$8]=$8
               }
             }
            END {
              pcnt=0
              for (n=0;n<l;n++) {
                m=n+1
                p=parama[m]
                if (p==parlist[p]) {
                    z=pcnt%10
                    if (z==0) {
                      if (pcnt>0)  {
                         print ""
                         printf("%27s %s\n", "Time", arrt);
                         oarff=""; ocnt=0
                         for (ix=0;ix<cnt;ix++) {
                           i=sorted[ix]
                           if (arrf[i] != oarff || ix==cnt-1 ){  print i" "arrf[i]" ("ocnt")"; oarff=arrf[i]; ocnt=0 } else { ocnt++ }
                         }
                         arrt=""
                         for (ix=0;ix<cnt;ix++) {
                            i=sorted[ix]
                            arrf[i]=""
                         }
                       }
                     }
                    s=sprintf("%8s ", "("m")")
                    arrt=arrt" "s
                    for (ix=0;ix<cnt;ix++) {
                         i=sorted[ix]

                          #s=sprintf("%8i ", arr[i,p])


                         ## compute for deltas instead
                         if (ix==0) delta=arr[i,p]
                         if (ix!=0) {
                             oi=sorted[ix-1]
                             old=arr[oi,p]
                             delta=arr[i,p]-old
                             parcount[p]=parcount[p]+delta
                         }
                         s=sprintf("%8s ", nvl("%8i", delta))

                         arrf[i]=arrf[i]" "s
                    }
                  pcnt++
                }
              }
              if (arrt!="") {
                      print ""
                      printf("%27s %s\n", "Time", arrt);
                      oarff=""; ocnt=0
                      for (ix=0;ix<cnt;ix++) {
                         i=sorted[ix]
                         if (arrf[i] != oarff || ix==cnt-1){  print i" "arrf[i]" ("ocnt")"; oarff=arrf[i]; ocnt=0 } else { ocnt++ }
                      }
              }
              print ""
              print "--- Summary of active IB Counters---"
              for (n=0;n<l;n++) {
                m=n+1
                p=parama[m]
                x=parcount[p]
                if (x>0 || x < 0) printf("%10i %-30s: %8i\n", m, p,x )
              }
            }
           ' |  sed  "s/zzz \*\*\*//g"


   echo ""
   echo " ------ IB connections (lowest traffic or no traffic ) -----"
   for h in `ifconfig -a|egrep -A1 "bondib(0|1|2|3) "|grep "inet addr"|gawk '{print $2}'|cut -d":" -f2`; do

   echo ""
   echo "*** IB interface: $h"
   echo ""
   egrep -h "zzz|^( )*$h" $rdsdat|gawk '/zzz/ { d=$0} !/zzz/ { print d" "$0}'|
   sed -e  "s/zzz \*\*\*//g" -re "s/zzz <([0-9]*)\/([0-9]*)\/([0-9]*) /\1 \2 \3 /g" -e  "s/> Count:[0-9]*/ TZ . . /g"  |grep -v grep | grep -|sort -k9,9 |
   gawk -v bond="$h" 'BEGIN {h=0; r=0;s=0; xdat=""; cnt=0 }
       {
           dat=$1" "$2" "$3" "$4" "$5" "$6" "$7
           if (xdat!=dat) {
               sorted[cnt++]=dat
               xdat=dat
           }
           net2[$9]=$9
           net2_cnt[$9]++
           ncnt=net2_cnt[$9]
           comm[dat,$9]= $10":"$11
           comm_sorted[ncnt,$9]=dat

       }
      END {



          for (h in net2) {
                 printf("\n")
                 printf(" * Between %s <-> %s \n", bond, h)

                 cnt=net2_cnt[h]
                 for (ix=1;ix<=cnt;ix++) {

                    old_r=0
                    old_s=0

                    if (ix>1) {
                      dat=comm_sorted[ix-1,h]
                      split(comm[dat,h], d, ":")
                      old_r=int(d[1])
                      old_s=int(d[2])
                    }

                    dat=comm_sorted[ix,h]
                    split(comm[dat,h], d, ":")
                    r=int(d[1])
                    s=int(d[2])
                    delta_r=r-old_r
                    delta_s=s-old_s

                    if (delta_r==0 || delta_s==0 || ix==1)
                    printf("%30s %15s %15s %15i TX  %12i RX\n", dat, bond, h, delta_r, delta_s)
                 }

          }
      }
   ' |  sed  "s/zzz \*\*\*//g"
   done


   echo ""
   echo " ------ RDS connections (highest ping - above 500usec) -----"
   for h in `ifconfig -a|egrep -A1 "bondib(0|1|2|3) "|grep "inet addr"|gawk '{print $2}'|cut -d":" -f2`; do

   echo ""
   echo "*** IB interface: $h"
   echo ""

   egrep -h "zzz|rds-ping" $rdsdat|gawk -v host="$h" '
          /zzz/ { d=$0} $4 ~/rds-ping/ && $10~host { print d" "$0}'|grep -v grep |
    sed -e  "s/zzz \*\*\*//g" -re "s/zzz <([0-9]*)\/([0-9]*)\/([0-9]*) /\1 \2 \3 /g" -e  "s/> Count:[0-9]*/ TZ . .  /g"  |
   awk '{ print $1" "$2" "$3" "$4" "$5" "$6" "$7" "$(NF-4)" "$(NF-3)" "$(NF-1)" "$NF}' |
   gawk -v bond="$h" 'BEGIN {h=0; r=0;s=0; xdat=""; cnt=0 }
       {
           dat=$1" "$2" "$3" "$4" "$5" "$6" "$7
           if (xdat!=dat) {
               sorted[cnt++]=dat
               xdat=dat
           }
           net2[$8]=$8
           net2_cnt[$8]++
           ncnt=net2_cnt[$8]
           comm[dat,$8]= $10
           #comm_date[dat,$8]= $8
           comm_sorted[ncnt,$8]=dat

       }
      END {



          for (h in net2) {
                 printf("\n")
                 printf(" * Between %s <-> %s \n", bond, h)

                 cnt=net2_cnt[h]
                 for (ix=1;ix<=cnt;ix++) {

                    old_s=0

                    if (ix>1) {
                      dat=comm_sorted[ix-1,h]
                      old_s=comm[dat,h]
                    }

                    dat=comm_sorted[ix,h]
                    s=comm[dat,h]
                    delta_s=s-old_s


                   # cdate=comm_date[dat,h]

                    if ( s > 50 || delta_s > 50 )
                    printf("%30s %15s %15s %12i usec %12i usec (delta)\n", dat, bond, h, s, delta_s)
                   # printf("%30s %15s %15s %12i usec %12i usec (delta) %30s\n", dat, bond, h, s, delta_s, cdate)
                 }

          }
      }
   ' |  sed  "s/zzz \*\*\*//g"
  done

  fi


fi

}

function PS_STAT_DETAIL() {
psdat=$(uNzip "$psdat")

#if [  -n "$get_ps_detail" -a "${psdat}" != "empty" ]; then
if [  "${psdat}" != "empty" ]; then
  echo ""
  echo ------ ps details -----
   egrep -h "^zzz| (R|D|Z) " $psdat
fi

}


############### Start ########################################################

while getopts p:t:d:w:cha opt; do
 case $opt in
   p) PID=$OPTARG;;
   d) duration=$OPTARG;;
   t) sdate=$OPTARG;;
   w) wd=$OPTARG;;
   c) copy=1;;
   a) avail=1;;
   h)
    usage $OPTARG
    exit 2
    ;;
   \?)
    usage $OPTARG
   exit 2
  ;;
  esac
 done


get_archive_dir


typeset int EXAWATCH=0
if [ -d /opt/oracle.ExaWatcher/archive ]; then
    typeset int exacnt=`ls -1f /opt/oracle.ExaWatcher/archive/*.ExaWatcher/* | egrep -c "dat(|.bz2|.gz)$"`
    if [ $exacnt -gt 5 ]; then
        EXAWATCH=1
    fi
fi

if [  -n "$avail" ]; then

 if [ -d /opt/oracle.ExaWatcher/archive ]; then
    if [ $exacnt -gt 5 ]; then
     show_exa_available_dates
    else
     show_available_dates
    fi
  else
     show_available_dates
 fi
 exit;

fi


### validation
#######################################
if [ -d "${wd}" ]; then

    working_dir=$wd
    cd $working_dir

  else

   echo "Working directory does not exist: $wd"
   exit 2

fi


if [  ! -n "$sdate" ]; then

  echo "Error: Start Date should be provided along with -t flag."
  usage;
  exit
fi

if [  ! -n "$duration" ]; then

  duration=1;

fi

if [ $duration -le 0 ]; then

  duration=1;

fi

if [ ! -n "$copy" ]; then

  copy=0

fi


#### calculate date range
##########################################



if [  $EXAWATCH -eq 1 ]; then

osw=$(get_exa_range "*" $sdate $duration)
[ "$osw" == "exit" ] && exit 2

memdat=$(get_exa_range Meminfo $sdate $duration)

topdat=$(get_exa_range Top $sdate $duration)

psdat=$(get_exa_range Ps $sdate $duration)

netdat=$(get_exa_range Netstat $sdate $duration)

iodat=$(get_exa_range Iostat $sdate $duration)

rdsdat=$(get_exa_range RDSinfo $sdate $duration)

else

osw=$(getrange "*" $sdate $duration)
[ "$osw" == "exit" ] && exit 2

memdat=$(getrange meminfo $sdate $duration)

topdat=$(getrange top $sdate $duration)

psdat=$(getrange ps $sdate $duration)

netdat=$(getrange netstat $sdate $duration)

iodat=$(getrange iostat $sdate $duration)

rdsdat=$(getrange ExadataRDS $sdate $duration)

fi

#### copy archives to working directory
########################################


if [ ${copy} -eq 1 ]; then

 for oswf in `echo $osw`; do

   scp $arch_dir/*/${oswf}{,.bz2,.gz} $working_dir 2>/dev/null
   #scp $arch_dir/*/${oswf}* $working_dir 2>/dev/null

 done

fi

if [ -n "$PID" ]; then
  topdat=$(uNzip "$topdat")
  if [ $? -eq 0 ]; then

  show_pid $PID "$topdat"
   exit

  fi

fi

MEMORY_STAT
TOP_STAT
PS_STAT
##IO_STAT
#PS_STAT_DETAIL
#NET_STAT
RDS_STAT


exit

--BEGIN_RDS--
conn_reset
recv_drop_bad_checksum
recv_drop_old_seq
recv_drop_no_sock
recv_drop_dead_sock
recv_deliver_raced
#recv_delivered
#recv_queued
recv_immediate_retry
recv_delayed_retry
#recv_ack_required
recv_rdma_bytes
#recv_ping
#send_queue_empty
send_queue_full
#send_lock_contention
#send_lock_queue_raced
send_immediate_retry
#send_delayed_retry
send_drop_acked
#send_ack_required
#send_queued
send_rdma
send_rdma_bytes
#send_pong
#page_remainder_hit
#page_remainder_miss
#copy_to_user
#copy_from_user
cong_update_queued
cong_update_received
cong_send_error
cong_send_blocked
ib_connect_raced
ib_listen_closed_stale
#ib_tx_cq_call
#ib_tx_cq_event
ib_tx_ring_full
ib_tx_throttle
ib_tx_sg_mapping_failure
ib_tx_stalled
ib_tx_credit_updates
#ib_rx_cq_call
#ib_rx_cq_event
ib_rx_ring_empty
ib_rx_refill_from_cq
ib_rx_refill_from_thread
ib_rx_alloc_limit
ib_rx_credit_updates
#ib_ack_sent
ib_ack_send_failure
ib_ack_send_delayed
ib_ack_send_piggybacked
#ib_ack_received
ib_rdma_mr_alloc
#ib_rdma_mr_free
#ib_rdma_mr_used
#ib_rdma_mr_pool_flush
ib_rdma_mr_pool_wait
ib_rdma_mr_pool_depleted
ib_atomic_cswp
ib_atomic_fadd
iw_connect_raced
iw_listen_closed_stale
iw_tx_cq_call
iw_tx_cq_event
iw_tx_ring_full
iw_tx_throttle
iw_tx_sg_mapping_failure
iw_tx_stalled
iw_tx_credit_updates
iw_rx_cq_call
iw_rx_cq_event
iw_rx_ring_empty
iw_rx_refill_from_cq
iw_rx_refill_from_thread
iw_rx_alloc_limit
iw_rx_credit_updates
iw_ack_sent
iw_ack_send_failure
iw_ack_send_delayed
iw_ack_send_piggybacked
iw_ack_received
iw_rdma_mr_alloc
iw_rdma_mr_free
iw_rdma_mr_used
iw_rdma_mr_pool_flush
iw_rdma_mr_pool_wait
iw_rdma_mr_pool_depleted
--END_RDS--
 

