#!/bin/env bash
#
# $Header: tfa/src/orachk/src/filechecker.sh /main/1 2016/04/04 11:05:10 rkchaura Exp $
#
# filechecker.sh
#
# Copyright (c) 2016, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      filechecker.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    rkchaura    03/10/16 - Filechecker Integration
#    rkchaura    03/10/16 - Creation
#


OPERATION=$1 ;



# Usage Help
help_usage ()
{
  echo "====================================================================="
  echo "           We can use this script to do some critical file attribute checks  "
  echo
  echo "====================================================================="
  echo
  echo "Usage:"
  echo "     filechecker.sh {start|remove|check}"
  echo "             start     Takes the snapshot of discovered or given directory"
  echo "             remove    Removes all the snapshots"
  echo "             check     Checks critical file parameter changes"
  echo
  return 0;
}


# Resource name shows from clusterware stack
  RESOURCE_NAME="FileChecker" ;
  SOURCE_HOME=`dirname $0` ;

# Following coded added by Rajeev to support its intgration in orachk/exachk
  SCRIPTPATH=`pwd`
  SCRIPT_LOCATION=$SCRIPTPATH/.cgrep ;
  SCRIPT_FILECHECKER="$SCRIPT_LOCATION/rac_file_checker.pl" ;
  SCRIPT_MODULE="$SCRIPT_LOCATION/rac_lib.pm" ;
  SCRIPT_MAIN="$SCRIPT_LOCATION/rac_main.pl" ;
 #perl_exe=$(which perl|tr -d '\r');
  perl_exe=`which perl|tr -d '\r'` ;
  DEFAULT_CHECK_DIRS="$DISCOVERED_DIRS"
  

if [ $# -ne "1" ]; then
  help_usage ;
  exit 1 ;
fi



# Item1: System Dependent Variables
OS=`/bin/uname` ;
HOST=`/bin/hostname` ;


# Need wrap in the subroutine
case $OS in
Linux )
  INST_IN="/etc/oraInst.loc"
  ORA_TAB="/etc/oratab"
  ORA_LOC="/etc/oracle"
  TEMP="/tmp"
  CONF="/etc/init.d"
  LOCALBIN="/usr/local/bin"

  CP="/bin/cp "
  ID="/usr/bin/id "
  PSEF="/bin/ps -ef "
  AWK="/bin/awk "
  SED="/bin/sed "
  GREP="/bin/grep "
  EGREP="/bin/egrep "
  CAT="/bin/cat "
  CUT="/usr/bin/cut "
  CHOWN="/bin/chown "
  CHMOD="/bin/chmod "
  LS="/bin/ls "
  RMRF="/bin/rm -rf "
  MV="/bin/mv "
  DD="/bin/dd "
  RSH="/usr/bin/rsh "
  SSH="/usr/bin/ssh "
  INITQ="/sbin/init q"
  SU="/bin/su "

  LSOF="/usr/sbin/lsof ";
  FUSER="/sbin/fuser ";
  MAIL="/bin/mailx ";
  ;;
AIX )
  INST_IN="/etc/oraInst.loc"
  ORA_TAB="/etc/oratab"
  ORA_LOC="/etc/oracle"
  TEMP="/tmp"
  CONF="/etc"
  LOCALBIN="/usr/local/bin"

  CP="/bin/cp "
  ID="/bin/id "
  PSEF="/bin/ps -ef "
  AWK="/bin/awk "
  SED="/bin/sed "
  GREP="/bin/grep "
  EGREP="/bin/egrep "
  CAT="/bin/cat "
  CUT="/bin/cut "
  CHOWN="/bin/chown "
  CHMOD="/bin/chmod "
  LS="/bin/ls "
  RMRF="/bin/rm -rf "
  MV="/bin/mv "
  DD="/bin/dd "
  RSH="/bin/rsh "
  SSH="/bin/ssh "
  RMITAB="rmitab "
  INITQ="/usr/sbin/init q"
  SU="/usr/bin/su "

  LSOF=" "    # Default location of lsof
  FUSER="/etc/fuser "
  MAIL="/bin/mailx "
  ;;
SunOS )
  INST_IN="/var/opt/oracle/oraInst.loc"
  ORA_TAB="/var/opt/oracle/oratab"
  ORA_LOC="/var/opt/oracle"
  TEMP="/tmp"
  CONF="/etc/init.d"
  LOCALBIN="/usr/local/bin"

  CP="/usr/xpg4/bin/cp "
  ID="/usr/xpg4/bin/id "
  PSEF="/usr/bin/ps -ef "
  AWK="/usr/xpg4/bin/awk "
  SED="/usr/xpg4/bin/sed "
  GREP="/usr/xpg4/bin/grep "
  EGREP="/usr/xpg4/bin/egrep "
  TAIL="/usr/xpg4/bin/tail "
  CAT="/usr/bin/cat "
  CUT="/usr/bin/cut "
  CHOWN="/usr/bin/chown "
  CHMOD="/usr/bin/chmod "
  LS="/usr/bin/ls "
  RMRF="/usr/bin/rm -rf "
  MV="/usr/bin/mv "
  DD="/usr/bin/dd "
  RSH="/usr/bin/rsh "
  SSH="/usr/bin/ssh "
  INITQ="/sbin/init q"
  SU="/bin/su "

  LSOF="/usr/local/bin/lsof " # Default location of lsof
  FUSER="/usr/sbin/fuser "
  MAIL="/bin/mailx "
  ;;
HP-UX )
  INST_IN="/var/opt/oracle/oraInst.loc"
  ORA_TAB="/var/opt/oracle/oratab"
  ORA_LOC="/var/opt/oracle"
  TEMP="/tmp"
  CONF="/etc/init.d"
  LOCALBIN="/usr/local/bin"

  CP="/usr/bin/cp "
  ID="/usr/bin/id "
  PSEF="/usr/bin/ps -ef "
  AWK="/usr/bin/awk "
  SED="/usr/bin/sed "
  GREP="/usr/bin/grep "
  EGREP="/usr/bin/egrep "
  CAT="/usr/bin/cat "
  CUT="/usr/bin/cut "
  CHOWN="/usr/bin/chown "
  CHMOD="/usr/bin/chmod "
  LS="/usr/bin/ls "
  RMRF="/usr/bin/rm -rf "
  MV="/usr/bin/mv "
  DD="/usr/bin/dd "
  RSH="/usr/bin/remsh "
  SSH="/usr/bin/ssh "
  INITQ="/sbin/init q"
  SU="/usr/bin/su "

  LSOF=" "    # Default location of lsof
  FUSER="/usr/sbin/fuser "
  MAIL="/usr/bin/mailx "
  ;;
*)
  echo
  echo "Unknown OS system";
  echo
  exit 1;
  ;;
esac


read_input()
{
  while [ true ]; do
    printf "%b" "$1" ;
    read IN

    if [ -z "$IN" ]; then
      return ;
    fi

    if [ "$2" = "int" ]; then
      TMP=`echo $IN|$SED 's/[0-9]//g'` # Should be numbers
      if [ -n "$TMP" ]; then
        echo "Input should be integer !"
        continue;
      else
        eval $3="$IN"
        break;
      fi 
    else
      eval $3="$IN"
     break;
    fi
  done
}




# OS dependent SU command to run as oracle user
case $OS in
Linux )
  RUN_AS_USER="$SU $O_USER -c " ;
  ;;
SunOS)
  RUN_AS_USER="$SU $O_USER -c " ;
  ;;
AIX)
  RUN_AS_USER="$SU $O_USER -c " ;
  ;;
HP-UX)
  RUN_AS_USER="$SU $O_USER -c " ;
  ;;
esac




# Start the resource
start_resource ()
{
  $perl_exe $SCRIPT_MAIN start
  return_value=`echo $?`;
  if [[ $return_value -eq 0 ]];then
    return 0 ; 
  else
    return 1 ; 
  fi  
}

# Check the resource
check_resource ()
{
  $perl_exe $SCRIPT_MAIN check
  return_value=`echo $?`;
  if [[ $return_value -eq 0 ]];then
    return 0 ;
  else
    return 1 ;
  fi
}

# Main routine

  if [ -z "$CHECK_DIRS" ]; then
    #echo "Default Checking Directories will be used: $DEFAULT_CHECK_DIRS" ;
    CHECK_DIRS=$DEFAULT_CHECK_DIRS ;
   echo
  fi
  export CHECK_DIRS=$CHECK_DIRS ;
  export CHECK_NODES=$ALL_CRS_NODES_LIST ;



  if [ "$OPERATION" = "start" ]; then
    if start_resource ; then
      exit 0;
    else
      echo -e "\nFailed to start File attribute checker !"
      echo
      exit 1;
    fi
  elif [ "$OPERATION" = "check" ]; then
    check_resource ;
    exit 0;
  else
    echo "Error: Unknown option \"$OPERATION\""
    help_usage
    echo
    exit 1;
  fi

