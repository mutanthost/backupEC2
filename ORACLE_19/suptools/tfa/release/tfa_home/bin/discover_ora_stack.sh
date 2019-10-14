#!/bin/env bash
#
# $Header: tfa/src/v2/tfa_home/bin/discover_ora_stack.sh /st_tfa_19/1 2018/09/19 21:34:38 bburton Exp $
#
# discover_ora_stack.sh
#
# Copyright (c) 2012, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      discover_ora_stack.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     09/19/18 - Remove most of the code as it is no longer used.
#    cnagur      10/31/17 - Fix for Bug 27003629
#    bburton     06/20/17 - oc4j no longer used in 12.2 but check for older
#                           versions
#    arupadhy    07/21/16 - exported oracle_home and ld_library_path to avoid
#                           core dump through crsctl and added
#                           exec_in_bash_mode variable to execute commands in
#                           bash mode while switching user, useful in case of
#                           ade
#    bburton     06/01/16 - Deal with MTS
#    arupadhy    02/05/16 - added check to make sure an intermittent issue
#                           21783081 does not occur
#    manuegar    11/26/15 - Bug 22274372 - TFA: ADR HOMES ON LOCAL STORAGES FOR
#                           RAC DATABASE NOT RECOGNIZED ON SOLARIS.
#    manuegar    11/06/15 - Bug 22162809 - TFA : INCIDENT DIAG COLLECT NOT
#                           WORKING.
#    llakkana    09/12/15 - Fix 21790910
#    manuegar    09/09/15 - Bug 21812659 - LNX64-12.2-TFA-DISCOVER_ORA_STACK.SH
#                           ADR_BASE IS INITIALIZED INCORRECTLY.
#    amchaura    09/09/15 - Fix Bug 21811849 - MISSPELLED WORD WHEN VIEWING
#                           ORATOP OPTIONS
#    manuegar    09/07/15 - Bug 21785398 - TFA : INCORRECT DIR STRUCTURE IN TFA
#                           ZIP FILE.
#    gadiga      09/03/15 - check more files in ADE
#    gadiga      08/12/15 - ade fixes
#    gadiga      07/23/15 - fix su issue
#    bburton     07/23/15 - only add zdlra dirs if they exist
#    gadiga      07/22/15 - cleanup only keys setup by TFA
#    gadiga      07/02/15 - fix diag discovery in view
#    gadiga      06/24/15 - bug 21219583
#    gadiga      06/24/15 - remove ^M in tline
#    gadiga      06/09/15 - XbranchMerge gadiga_tfa_in_dbaas_12124 from
#                           st_tfa_12.1.2.4
#    gadiga      05/19/15 - add su for oh commands
#    cnagur      04/08/15 - Fix for Bug 20369589
#    gadiga      05/04/15 - fix dbaas permission issue
#    cnagur      04/08/15 - Fix for Bug 20369589
#    cnagur      02/13/15 - Fix for Bug 19831308
#    gadiga      02/13/15 - SR-3-9841699331. issue when more than 10 databases
#    gadiga      02/05/15 - handle cases when file/command does not exists
#    gadiga      12/10/14 - fix bug 19566407: errors on screen
#    gadiga      12/08/14 - no prompts in silent
#    bburton     10/21/14 - 19508749 - TFA NEEDS TO COLLECT CHMOS NODE EVICTION
#                           EMERGENCY DUMPS add GIHOME/crs/c
#    gadiga      09/23/14 - aix crs_home
#    cnagur      08/27/14 - Support for Core files
#    cnagur      08/07/14 - Fix for Bug 19161659
#    gadiga      07/23/14 - ade support
#    bburton     05/15/14 - bug 18549656 - add some more crsdata dirs
#    gadiga      05/09/14 - SI discovery
#    gadiga      02/26/14 - fix 18309727
#    amchaura    02/21/14 - Updated cfgtools,acfs,afd resource
#    gadiga      02/17/14 - remove iptables
#    bburton     02/14/14 - add ExaWatcher Dirs
#    amchaura    01/29/14 - added CVU adr trace dir
#    gadiga      01/21/14 - fix 18108047. add acfs dir
#    amchaura    01/14/14 - Change log file location to TFAHOME/tmp
#    gadiga      01/12/14 - fix 17987059
#    gadiga      01/05/14 - discover crs adr directories
#    gadiga      12/17/13 - fix GSI issue
#    gadiga      12/03/13 - fix asm discovery in 12.1
#    gadiga      11/20/13 - dont overwrite RAT_CRS_HOME
#    gadiga      11/13/13 - fix 17782389
#    amchaura    11/05/13 - Fix for Bug 17731629
#    sowsingh    10/01/13 - Changing CRSOC4J to DBWLM
#    gadiga      09/11/13 - 12c support
#    gadiga      09/09/13 - SI support
#    gadiga      08/13/13 - SIHA support
#    gadiga      07/15/13 - use oh owner for srvctl
#    gadiga      07/04/13 - fix sed issue
#    cnagur      06/20/13 - Converted hostname to lower case using awk
#    cnagur      06/12/13 - Changed RTEMPDIR to point to TFA_HOME/tmp/
#    cnagur      06/11/13 - Should not copy the orginal nodelist to after ssh
#                           setup if -silent is passed
#    gadiga      03/01/13 - system components
#    gadiga      01/30/13 - new iptables
#    gadiga      01/16/13 - fix minor install issues
#    gadiga      01/08/13 - dont add ignored hosts
#    sowsingh    11/07/12 - adding ASMIO and ASMPROXY dirs to discovery
#    sowsingh    10/09/12 - dont exit if no database
#    gadiga      08/26/12 - add directories from osw and orainv
#    gadiga      08/22/12 - add all trace directories from diag
#    bburton     07/30/12 - Creation
#    gadiga      09/30/11 - add delete ssh option
#    gadiga      09/21/11 - support root
#    gadiga      08/01/11 - discover oracle stack status for TFA
#    gadiga      08/01/11 - Creation
#

current_dir=$(dirname $0)
if [ -f "$current_dir/../tfa_setup.txt" ]
then
        ts_crs_home=`grep "^CRS_HOME=" $current_dir/../tfa_setup.txt | awk -F"=" '{ print $2 }'`
	if [[ -z "$RAT_CRS_HOME" && -n "$ts_crs_home" ]] ; then
	  export RAT_CRS_HOME=$ts_crs_home
	fi
fi

#Function to get the location of commands
getCommandLocation() {

        COMMAND=$1;

        if [ -f "/bin/$COMMAND" ]
        then
                CMDLOC="/bin/$COMMAND";
        elif [ -f "/usr/bin/$COMMAND" ]
        then
                CMDLOC="/usr/bin/$COMMAND";
        elif [ -f "/usr/local/bin/$COMMAND" ]
        then
                CMDLOC="/usr/local/bin/$COMMAND";
        else
                CMDLOC="$COMMAND";
        fi

        echo "$CMDLOC";
}

removeSSH ()
{
  arr=`expr $arr - 1`
  while [[ -n $arr && $arr -ge 0 ]]
  do
    if [  ${hnameArr[$arr]} = $localnode ]
    then
      sed /root@$dhostn/d ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.new; cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.initsetup.tmp; mv ~/.ssh/authorized_keys.new ~/.ssh/authorized_keys
    else
      dhostn=$localnode
      $SSH -o StrictHostKeyChecking=no -x ${hnameArr[$arr]} "/bin/sh -c \"sed /root@$dhostn/d ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.new; cp ~/.ssh/authorized_keys ~/.ssh/authorized_keys.initsetup.tmp; mv ~/.ssh/authorized_keys.new ~/.ssh/authorized_keys;\" >/dev/null 2>&1"
    fi
    echo "Removed ssh equivalency setup on ${hnameArr[$arr]}";
    arr=`expr $arr - 1`
  done
  mv $ssh_node_file $ssh_node_file.saved
}

SILENT=0
if [[  -n "$1" && $1 -eq "1" ]]
then
  SILENT=1
fi

UNAME=`getCommandLocation "uname"`;
PLATFORM=`$UNAME`
AWK=`getCommandLocation "awk"`;
CUT=`getCommandLocation "cut"`;
ECHO=`getCommandLocation "echo"`;
GREP=`getCommandLocation "grep"`;
PERL=`getCommandLocation "perl"`;
SCP=`getCommandLocation "scp"`;
SCP="$SCP -q";
SSH=`getCommandLocation "ssh"`;
SSH="$SSH -q";


case $PLATFORM in
SunOS)
	AWK=`getCommandLocation "gawk"`;
	if [ -f "/usr/xpg4/bin/grep" ]
	then
		GREP=/usr/xpg4/bin/grep;
	fi

	# if not able to find gawk then use nawk
	if [ `$ECHO $AWK | $GREP -c "^gawk$"` -eq 1 ]
	then
		AWK=`getCommandLocation "nawk"`;
	fi
	;;
esac

HOSTNAME=`hostname | $CUT -d. -f1 | $PERL -ne 'print lc'`

ssh_node_file="tfa_ssh_nodes"

if [[ -n "$1" && $1 = "-deleteSSH" ]]
then
  localnode=$HOSTNAME
  if [ -r "$ssh_node_file" ]
  then
    arr=0
    while read hname
    do
      hnameArr[$arr]=$hname
      arr=`expr $arr + 1`
    done < "$ssh_node_file"

    removeSSH
    exit;
  else
    echo "Could not read host list from tfa_ssh_nodes. exiting.."
    exit 1
  fi
else 
  echo "Only Valid option id -deleteSSH"
fi
