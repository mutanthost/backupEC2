#!/bin/sh
#
# $Header: tfa/src/v2/tfa_home/bin/scripts/tfar_crs.sh /main/9 2017/11/17 16:21:50 gadiga Exp $
#
# tfar_crs.sh
#
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfar_crs.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    gadiga      11/13/17 - fix cleanup issue
#    gadiga      10/16/17 - stop receiver before shutdown
#    gadiga      08/22/17 - Check and start TFAC if its not running
#    gadiga      06/25/17 - stop only receiver service
#    gadiga      12/20/16 - dont wait for TFA to start completely during crs
#                           startup
#    gadiga      10/26/16 - changes for scriptagent. bug 24929232
#    gadiga      08/26/16 - Stop TFA
#    gadiga      06/28/16 - fix 23623071
#    gadiga      05/03/16 - Receiver as CRS resource
#    gadiga      05/03/16 - Creation
#
 

UNAME=/bin/uname
PLATFORM=`$UNAME`
AWK=/bin/awk
ECHO=/bin/echo
CAT=/bin/cat


case $PLATFORM in
Linux)
        ID=/etc/init.d
;;
AIX)
        ID=/etc
        ;;
SunOS)
        ID=/etc/init.d
        ;;
HP-UX)
        ID=/sbin/init.d
        ;;
*)     /bin/echo "ERROR: Unknown Operating System"
       exit 1
       ;;
esac

TFA_HOME=`grep ^TFA_HOME= $ID/init.tfa | cut -d= -f2`
PIDFILE=$TFA_HOME/receiver/internal/.receiver.lck
PIDFILE_C=$TFA_HOME/internal/.pidfile

checkrunning()
{
  tfapid=0
  getpid
  if [ $tfapid -gt 0 ]; then
        tfarunning=1
  else
        tfarunning=0
  fi
}

checkrunning_c()
{
  tfapid_c=0
  getpid_c
  if [ $tfapid_c -gt 0 ]; then
        tfarunning_c=1
  else
        tfarunning_c=0
  fi
}

getpid ()
{
  if [ -r "$PIDFILE" ]; then
    tfapidfromfile=`$CAT $PIDFILE 2>/dev/null`
    if [ ! -z "$tfapidfromfile" ]; then
      tfapid=`ps -f -p $tfapidfromfile | grep -v PID | $AWK '{print $2}'`
      if [ -z "$tfapid" ]; then
          tfapid=0
      fi
    fi
  fi
}

getpid_c ()
{
  if [ -r "$PIDFILE_C" ]; then
    tfapidfromfile=`$CAT $PIDFILE_C 2>/dev/null`
    if [ ! -z "$tfapidfromfile" ]; then
      tfapid_c=`ps -f -p $tfapidfromfile | grep -v PID | $AWK '{print $2}'`
      if [ -z "$tfapid_c" ]; then
          tfapid_c=0
      fi
    fi
  fi
}


check_proc_status()
{
  proc_pid=0
  lck_file=$1

  if [ -r "$lck_file" ]; then
    tfapidfromfile=`$CAT $lck_file 2>/dev/null`
    if [ ! -z "$tfapidfromfile" ]; then
      proc_pid=`ps -f -p $tfapidfromfile |grep tfa_home |grep -v grep | grep -v PID | $AWK '{print $2}'`
      if [ -z "$proc_pid" ]; then
          proc_pid=0
      fi
    fi
  fi
}


get_running_pid()
{
  mypid=$1
  proc_pid=`ps -f -p $mypid |grep tfa_home |grep -v grep | grep -v PID | $AWK '{print $2}'`
  if [ -z "$proc_pid" ]; then
    proc_pid=0
  fi
}

cleanup_r_procs()
{
  tfa_pid_file=$TFA_HOME/receiver/internal/.receiver.lck
  tomcat_pid_file=$TFA_HOME/tomcat/internal/.tomcat.lck
  
  check_proc_status $tfa_pid_file
  if [ ! -z "$proc_pid" ] ; then
    if [ $proc_pid -ne 0 ] ; then
      echo "Killing TFA Process $proc_pid with -15"
      kill -15 $proc_pid
    fi
  fi

  # Check and kill using -9
  check_proc_status $tfa_pid_file
  if [ ! -z "$proc_pid" ] ; then
    if [ $proc_pid -ne 0 ] ; then
      echo "Killing TFA Process $proc_pid with -9"
      kill -9 $proc_pid
    fi
  fi

  check_proc_status $tomcat_pid_file
  if [ ! -z "$proc_pid" ] ; then
    if [ $proc_pid -ne 0 ] ; then
      echo "Killing tomcat Process $proc_pid with -15"
      kill -15 $proc_pid
    fi
  fi

  # Check and kill using -9
  check_proc_status $tomcat_pid_file
  if [ ! -z "$proc_pid" ] ; then
    if [ $proc_pid -ne 0 ] ; then
      echo "Killing tomcat Process $proc_pid with -9"
      kill -9 $proc_pid
    fi
  fi

  # Check g_ pid's saved before stopping TFA Receiver
  if [ ! -z "$g_tfar_pid" ] ; then
    get_running_pid "$g_tfar_pid"
    if [ ! -z "$proc_pid" ] ; then
      if [ $proc_pid -ne 0 ] ; then
        echo "Killing TFA Process $proc_pid ($g_tfar_pid) with -9"
        kill -9 $proc_pid
      fi
    fi
  fi
  if [ ! -z "$g_tomcat_pid" ] ; then
    get_running_pid "$g_tomcat_pid"
    if [ ! -z "$proc_pid" ] ; then
      if [ $proc_pid -ne 0 ] ; then
        echo "Killing tomcat Process $proc_pid ($g_tomcat_pid) with -9"
        kill -9 $proc_pid
      fi
    fi
  fi

}

read_pids()
{
  g_tfar_pid=
  g_tomcat_pid=
  tfa_pid_file=$TFA_HOME/receiver/internal/.receiver.lck
  tomcat_pid_file=$TFA_HOME/tomcat/internal/.tomcat.lck

  check_proc_status $tfa_pid_file
  g_tfar_pid=$proc_pid
  check_proc_status $tomcat_pid_file
  g_tomcat_pid=$proc_pid
}

if [ -d "$TFA_HOME" ] ; then
  case $1 in
    'start')
        checkrunning_c
        if [ $tfarunning_c -eq 1 ]
        then # TFA Collector is running. Just start receiver.
	  $TFA_HOME/bin/tfactl receiver stop;
	  $TFA_HOME/bin/tfactl receiver start
        else # Start TFA which wil start TFA Receiver too
	  $TFA_HOME/bin/tfactl stop;
	  $TFA_HOME/bin/tfactl start
        fi
        ;;
    'stop')
        read_pids
	$TFA_HOME/bin/tfactl receiver stop
        cleanup_r_procs
        ;;
    'clean')
        read_pids
        cleanup_r_procs
	$TFA_HOME/bin/tfactl receiver stop
        ;;
    'check')
   	checkrunning
   	if [ $tfarunning -eq 1 ]
	then
		exit 0
	else
		exit 1
	fi

        ;;
    *)
       exit 1
        ;;
  esac 
fi
exit 0
