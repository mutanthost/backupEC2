#!/bin/sh
######################################################################
# psmemswsub.sh
# This script is called by OSWatcher.sh. This script is the ps 
# data collector shell. $1 is the output filename for the data
# collector. $2 is the data collector shell script to execute.
# $3 fixes timestamp date to be OSWg compliant.
######################################################################
echo "" >> $1
if [ $3 != 0 ]; then
  echo "zzz ***"`date '+%a %b %e %T %Z %Y'` >> $1
else
  echo "zzz ***"`date` >> $1
fi
PLATFORM=`/bin/uname`
case $PLATFORM in
      Linux)
ps -aeo    user,pid,ppid,pri,pcpu,pmem,vsize,rssize,wchan,s,start,cputime,command | head -1 >> $1
ps -aeo    user,pid,ppid,pri,pcpu,pmem,vsize,rssize,wchan,s,start,cputime,command | sort -nr -k 6 >> $1
      ;;
      HP-UX|HI-UX)
UNIX95=1 ps -e -o user,pid,ppid,pri,pcpu,cpu,vsz,sz,wchan,state,etime,args | head -1 >> $1
UNIX95=1 ps -e -o user,pid,pcpu,ppid,pri,cpu,vsz,sz,wchan,state,etime,args | sort -nr -k 7 >> $1
      ;;
      AIX)
ps -ae -o user,pid,ppid,pri,pcpu,pmem,vsz,rssize,wchan,stat,etime,time,args | head -1 >> $1
ps -ae -o user,pid,ppid,pri,pcpu,pmem,vsz,rssize,wchan,stat,etime,time,args | sort -nr -k 6 >> $1
      ;;
      *)
ps -ae -o user,pid,ppid,pri,pcpu,pmem,vsz,rss,wchan,s,stime,time,args |  head -1 >> $1
ps -ae -o user,pid,ppid,pri,pcpu,pmem,vsz,rss,wchan,s,stime,time,args | sort -nr -k 6 >> $1
      ;;
    esac
rm locks/pslock.file
