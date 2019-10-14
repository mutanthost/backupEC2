#!/bin/sh
#
# $Header: tfa/src/v2/tfa_home/bin/uninstalltfa /main/46 2018/06/28 00:30:24 cnagur Exp $
#
# uninstalltfa.sh
#
# Copyright (c) 2012, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      uninstalltfa.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    cnagur      06/25/18 - Fix for Bug 28191790
#    bburton     05/21/18 - Fix uninstall issues in HPUX
#    cnagur      05/14/18 - Fix for bug 27993246
#    cnagur      04/17/18 - Orachk Autostart
#    cnagur      04/17/18 - Orachk Autostart
#    cnagur      04/13/18 - TFA REST Support
#    cnagur      11/22/17 - Fix for RTI Bug 20647910
#    cnagur      11/06/17 - Fix for Bug 27074638
#    cnagur      10/31/17 - Fix for Bug 27003629
#    gadiga      09/12/17 - remove receiver if MC: 24501109
#    chchoudh    08/16/17 - removing receiver node related information from
#                           repository on DSC uninstall
#    gadiga      08/23/17 - solaris does not support -e
#    cnagur      07/19/17 - Fix for Bug 26179330
#    chchoudh    06/21/17 - stop receiver processes if still running
#    chchoudh    05/23/17 - removing receiver user on uninstall
#    cnagur      02/14/17 - Non Root Daemon Changes
#    cnagur      11/24/16 - Fix for Bug 25062850
#    manuegar    11/17/16 - manuegar_extract_tfa_04_complement.
#    manuegar    11/08/16 - manuegar_extract_tfa_04, uninstaller for TFA non daemon.
#    llakkana    10/04/16 - Fix 24620486 - syntax errors
#    cnagur      07/25/16 - Fix for Bug 23755617
#    bburton     02/02/16 - XbranchMerge bburton_initrestart_fix from
#                           st_tfa_12.1.2.6
#    bibsahoo    12/14/15 - FIX BUG 22071701: TFA : TFA REPOSITORY NOT GETTING
#                           DELETED AFTER TFA REMOVAL FROM ALL RAC NODES
#    bibsahoo    10/22/15 - BUG 21804887 - TFA DIR FROM GI HOME IS NOT GETTING
#                           REMOVED AFTER UN-INSTALLING TFA
#    gadiga      04/28/15 - fix 20971905
#    bburton     02/01/16 - remove symlinks to init.tfa for rc
#    cnagur      01/16/15 - Changes in messages
#    gadiga      12/11/14 - stop tools
#    cnagur      09/10/14 - Use PERL instead of AWk for hostname - Bug 19583163
#    cnagur      07/08/14 - Fix for Bug 19161558
#    cnagur      05/30/14 - Fix for Bug 18868259
#    cnagur      01/19/14 - Bug 18097520
#    cnagur      01/06/14 - Changes to remove TFA_BASE/bin directory
#    cnagur      12/30/13 - Replace -e with -f for SunOS
#    cnagur      12/12/13 - Removed redundant code
#    cnagur      11/07/13 - Added Help Message Bug-17739259
#    cnagur      10/30/13 - Added changes to remove GIHOME/bin/tfactl
#    cnagur      10/23/13 - Changes to remove output directory in ORACLE_BASE
#                           for GI Install
#    cnagur      09/27/13 - Prompt for user before Uninstalling
#    cnagur      08/01/13 - Fix for Bug: 17168390
#    cnagur      07/05/13 - Updated Scipt to remove .<node>.shared under
#                           <ORACLE_BASE>/tfa for GI Install
#    bburton     07/04/13 - change ORACLE_BASE/tfa ownership to stop failure in
#                           clusterware deinstallbug 17007709
#    cnagur      07/12/13 - Added function getCommandLocation()
#    bburton     06/26/13 - fix issues with sed where case insensitive match is
#                           not allowed
#    cnagur      06/19/13 - Fix for Bug 16973989
#    cnagur      06/18/13 - Updated Script to remove BDB and logs in case of GI
#                           Install
#    cnagur      05/24/13 - Added Support for -crshome
#    cnagur      05/22/13 - Changed code not to remove /bin if its local
#                           uninstall.
#    cnagur      05/16/13 - Added -clusterwide to differentiate between true
#                           local and clusterwide uninstall
#    cnagur      05/14/13 - Updated Script to remove <TFA_BASE>/bin and
#                           <TFA_BASE>/<NODE>
#    bburton     05/02/13 - add support for local uninstall when no ssh or with
#                           a flag
#    bburton     05/02/13 - Fix issues with leaving init.tfa on the calling
#                           node
#    bburton     01/22/13 - move init.tfa removal up as it is being left behind
#    bburton     01/16/13 - Change check for init file to work on all ports
#    bburton     07/30/12 - Creation
#


#Function to get the location of commands
getCommandLocation() {

        COMMAND=$1;

        if [ -f "/bin/$COMMAND" ]
        then
                CMDLOC="/bin/$COMMAND";
        elif [ -f "/usr/bin/$COMMAND" ]
        then
                CMDLOC="/usr/bin/$COMMAND";
        else
                CMDLOC="$COMMAND";
        fi

        echo "$CMDLOC";
}

AWK=`getCommandLocation "awk"`;
CAT=`getCommandLocation "cat"`;
CHOWN=`getCommandLocation "chown"`;
CUT=`getCommandLocation "cut"`;
ECHO=`getCommandLocation "echo"`;
GREP=`getCommandLocation "grep"`;
KILL=`getCommandLocation "kill"`;
LN=`getCommandLocation "ln"`;
LNS="$LN -s";
LS=`getCommandLocation "ls"`;
NOHUP=`getCommandLocation "nohup"`;
PERL=`getCommandLocation "perl"`;
PWD=`getCommandLocation "pwd"`;
RUID=`getCommandLocation "id"`;
RM=`getCommandLocation "rm"`;
RSH=`getCommandLocation "rsh"`;
SED=`getCommandLocation "sed"`;
SLEEP=`getCommandLocation "sleep"`;
SSH=`getCommandLocation "ssh"`;
SSH="$SSH -q";
UNAME=`getCommandLocation "uname"`;
PLATFORM=`$UNAME`;
USERID=`getCommandLocation "id"`;
WC=`getCommandLocation "wc"`;
HEAD=`getCommandLocation "head"`;
DAEMON_OWNER="root";

case $PLATFORM in
Linux)
        ID=/etc/init.d
        RCKDIR="/etc/rc.d/rc0.d /etc/rc.d/rc1.d /etc/rc.d/rc2.d /etc/rc.d/rc4.d /etc/rc.d/rc6.d"
        RC_KILL=K17
        ;;
AIX)
        ID=/etc
	RCKDIR="/etc/rc.d/rc2.d"
        RC_KILL=K17
        ;;
SunOS)
        ID=/etc/init.d;
	RUID=/usr/xpg4/bin/id;
	GREP=/usr/xpg4/bin/grep;
	AWK=`getCommandLocation "gawk"`;
        RCKDIR="/etc/rc0.d /etc/rc1.d /etc/rc2.d /etc/rcS.d"
        RC_KILL=K17

        # if not able to find gawk then use nawk
        if [ `$ECHO $AWK | $GREP -c "^gawk$"` -eq 1 ]
        then
                AWK=`getCommandLocation "nawk"`;

                # if not found, then exit with proper message
                if [ `$ECHO $AWK | $GREP -c "^nawk$"` -eq 1 ]
                then
                        $ECHO "TFA-00051: Oracle Trace File Analyzer (TFA) requires GAWK or NAWK. Please install gawk or nawk and try again."
                fi
        fi
        ;;
HP-UX)
        ID=/sbin/init.d
        RCKDIR="/sbin/rc2.d"
        RC_KILL=K170
        ;;
*)     $ECHO "TFA-00052: Unknown Operating System"
       exit -1
       ;;
esac

ME=${0};
SILENT=0;
LOCAL=0;
CLUSTERWIDE=0;

# TFA ND Variables
NDSETUP=0;
USER_HOME=`$ECHO $HOME`;

# Print help function
printhelp() {
	$ECHO ""
	$ECHO "   Usage for $ME"
	$ECHO ""
	$ECHO "   $ME [-local] [-silent]"
	$ECHO ""
	$ECHO "        -local            -    Uninstall TFA only on the local node"
	$ECHO "        -silent           -    Do not ask any uninstall questions"
	$ECHO ""
        $ECHO ""
        $ECHO "   Note: Without parameters, this will uninstall TFA on all configured nodes."
        $ECHO ""
	$ECHO ""
}

# Parse Arguments
while [ $# -gt 0 ]
do
	case $1 in
	    -silent)  		SILENT=1;;         # silent is set to true
	    -local)   		LOCAL=1;;
	    -clusterwide) 	LOCAL=1; CLUSTERWIDE=1;;
	    -tfa_home) 		shift; tfa_home=$1;;
	    -crshome) 		shift; CRSHOME=$1; LOCAL=1; export CRSHOME;;  # CRSHOME is set
	    -help)		HELP=$1;; # Print the help and exit
	    -h)			HELP=$1;; # Print the help and exit
	    *)			$ECHO "TFA-00053: Invalid Option $1 "; printhelp ; exit 1
	esac;
	shift
done

if [ -n "$HELP" ]
then
	printhelp
	exit 1;
fi

cd;

HOSTNAME=`hostname | $CUT -d. -f1 | $PERL -ne 'print lc'`;

# Uninstall TFA Non Daemon
if [ -r "$USER_HOME/.tfa/tfa_setup.txt" ]
then
        NDSETUP=1;

	$ECHO "TFA will be uninstalled on $HOSTNAME : "

	# Prompt user before uninstall
	if [ "$SILENT" -eq 0 ]
	then
		printf "Do you want to continue with TFA uninstall ? [Y|N] [Y]: ";
		read userinput;

		if [ "$userinput" = "n" ] || [ "$userinput" = "N" ]
		then
			$ECHO "";
			$ECHO "Exiting from TFA uninstall now.";
			exit 0;
		fi
		$ECHO "";
	fi

        tfa_home=`$GREP '^TFA_HOME=' $USER_HOME/.tfa/tfa_setup.txt | $AWK -F"=" '{ print $2 }'`
        tfa_base=`$GREP '^TFA_BASE=' $USER_HOME/.tfa/tfa_setup.txt | $AWK -F"=" '{ print $2 }'`
        tfabase=`$ECHO $tfa_base | $SED -e "s/oracle\.tfa.*/oracle\.tfa/"`
        tfadiag=`$ECHO $tfa_home | $SED -e "s/\/[^\/]*$/\/diag/"`

	$ECHO "Stopping TFA Support Tools..."; 
	$tfa_home/bin/tfactl.pl stop_suptools > /dev/null 2>&1

	if [ -d "$USER_HOME/.tfa" ]
	then
		$RM -rf $USER_HOME/.tfa
	fi

	if [ -d "$tfabase" ]
	then
		$ECHO "Removing $tfabase...";
		$NOHUP $RM -rf $tfabase > /dev/null 2> /dev/null;
	fi

	if [ -d "$tfadiag" ]
	then
		$ECHO "Removing $tfadiag...";
		$NOHUP $RM -rf $tfadiag > /dev/null 2> /dev/null;
	fi

	if [ -d "$tfa_home" ]
	then
		$ECHO "Removing $tfa_home...";
		$NOHUP $RM -rf $tfa_home > /dev/null 2> /dev/null;
	fi

	exit 0;
fi

if [ ! -d "$tfa_home" ]
then
	if [ ! -r "$ID/init.tfa" ]
	then
        	$ECHO "TFA-00054: TFA is not Installed on this machine. Exiting now...";
	        exit;
	fi

	tfa_home=`$GREP '^TFA_HOME=' $ID/init.tfa | $AWK -F"=" '{ print $2 }'`
fi

tfabase=`$ECHO $tfa_home | $SED -e "s/\/[^\/]*$//"`

if [ -n "$CRSHOME" ]
then
	if [ `$ECHO $tfa_home | $GREP -ic "$CRSHOME"` -eq "0" ]
	then
		$ECHO "TFA-00055: TFA_HOME not found in CRS_HOME. Exiting now...";
		exit;
	fi
fi

if [ ! -r "$tfa_home/bin/tfactl" ]
then
	$ECHO "TFA-00056: Unable not locate TFA binaries. Exiting now.";
	exit;
fi

if [ -f "$tfa_home/tfa_setup.txt" ]
then
	if [ `$CAT $tfa_home/tfa_setup.txt | $GREP -c "^DAEMON_OWNER="` -ge 1 ]
	then
		DAEMON_OWNER=`$GREP '^DAEMON_OWNER=' $tfa_home/tfa_setup.txt | $AWK -F"=" '{print $2}'`;
	fi

	if [ `$CAT $tfa_home/tfa_setup.txt | $GREP -c "^PERL="` -ge 1 ]
	then
		PERL=`$GREP '^PERL=' $tfa_home/tfa_setup.txt | $AWK -F"=" '{print $2}'`;
	fi

	if [ `$CAT $tfa_home/tfa_setup.txt | $GREP -c "^CRS_HOME="` -ge 1 ]
	then
		CRS_HOME=`$GREP '^CRS_HOME=' $tfa_home/tfa_setup.txt | $AWK -F"=" '{print $2}'`;
	fi
fi

RUSER=`$RUID | $AWK '{print $1}' | $AWK -F\( '{print $2}' | $AWK -F\) '{print $1}'`;

if [ "$RUSER" != "$DAEMON_OWNER" ]
then
	$ECHO "User $RUSER does not have permissions to run this script.";
	exit 1;
fi

SSH_USER="$DAEMON_OWNER";

HOSTNAME=`hostname | $CUT -d. -f1 | $PERL -ne 'print lc'`;

# Disable TFA Update Warning Message - Bug 28191790
export TFA_SUPPRESS_AGE_WARN="TRUE";

HOST_COUNT=`$tfa_home/bin/tfactl print hosts | $GREP  "Host Name :" | $GREP -v grep | $WC -l`
NODE_LIST=`$tfa_home/bin/tfactl print hosts | $GREP "Host Name " | $AWK '{print $NF}' | $GREP -v "^$HOSTNAME$"`

if [ "$HOST_COUNT" -eq 0 ]   # TFA is probably not running
then
	$ECHO "Unable to determine a host list from TFA. So running local uninstall."
	$ECHO "";
fi

# if there is only one node in a cluster, set LOCAL to 1
# If host count is 0, set LOCAL to 1 which will do local uninstall

if [ "$HOST_COUNT" -eq 1 ] || [ "$HOST_COUNT" -eq 0 ]
then
	LOCAL=1; 
fi

# Prompt user before uninstall if its not a part of clusterwide uninstall
if [ "$CLUSTERWIDE" -eq 0 ]
then
	if [ "$LOCAL" -eq 1 ]
	then
		$ECHO "TFA will be uninstalled on $HOSTNAME : "
	else
		$ECHO "TFA will be uninstalled on: "
		$ECHO "$HOSTNAME"
		$ECHO "$NODE_LIST"
	fi

	$ECHO "";

	# This will prompt user when there is only one node and silent is not enabled.
	if [ "$SILENT" -eq 0 ]
	then
		printf "Do you want to continue with TFA uninstall ? [Y|N] [Y]: ";
		read userinput;

		if [ "$userinput" = "n" ] || [ "$userinput" = "N" ]
		then
			$ECHO "";
			$ECHO "Exiting from TFA uninstall...";
			exit 0;
		fi
		$ECHO "";
	fi
fi

# if there is only one node in the cluster, set CLUSTERWIDE to 1
if [ "$HOST_COUNT" -eq "1" ]
then
	CLUSTERWIDE=1;
fi

# If this is a local then we do not need to check further
# If it is remote and silent then we need to check ssh is OK
# If it is remote but not silent then we can prompt for passwords if required.

if [ "$LOCAL" -eq 0 ] && [ "$SILENT" -eq 1 ]
then
    for NODE in $NODE_LIST
    do
        platform=`$UNAME -s`
		
        if [ $platform = "Linux" ]
        then
            PING="/bin/ping"
        else
            PING="/usr/sbin/ping"
        fi
   
        $ECHO "Checking for ssh equivalency in $NODE"
        if [ "$NODE" != "$HOSTNAME" ]
        then
		if [ $platform = "SunOS" ]
		then
			$PING -s $NODE 5 5 >/dev/null 2>&1
		elif [ $platform = "HP-UX" ]
		then
			$PING $NODE -n 5 -m 5 >/dev/null 2>&1
		else
			$PING -c 1 -w 5 $NODE >/dev/null 2>&1
		fi
		exitcode=`$ECHO $?`
        fi

        if [ "$exitcode" -eq 0 ] && [ "$NODE" != "$HOSTNAME" ]
        then
		$SSH -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -l $SSH_USER $NODE $LS 2>/dev/null 1>/dev/null
		
		ssh_setup_status=$?
		
		if [ "$ssh_setup_status" -ne 0 ]
		then
			$RSH -l $SSH_USER $NODE $LS 2>/dev/null 1>/dev/null
			rsh_setup_status=$?
		fi
		
		if [ "$ssh_setup_status" -eq 0 ] || [ "$NODE" = "$HOSTNAME" ] || [ "$rsh_setup_status" -eq 0 ]
		then
			$ECHO "$NODE is configured for ssh user equivalency for $SSH_USER user"
		else
			$ECHO "Node $NODE is not configured for ssh user equivalency"
			LOCAL=1
		fi
        fi
    done
fi

if [ "$LOCAL" -eq 1 ]
then
	if [ "$CLUSTERWIDE" -eq 0 ]
	then
		$ECHO "Removing TFA from $HOSTNAME only"
		$ECHO "Please remove TFA locally on any other configured nodes"
	else
		$ECHO "Removing TFA from $HOSTNAME...";
	fi
	$ECHO "";
fi

# Send uninstall update to other nodes if its local uninstall.
if [ "$LOCAL" -eq 1 ] && [ "$CLUSTERWIDE" -eq 0 ]
then
	$ECHO "Notifying Other Nodes about TFA Uninstall..."; 
	$tfa_home/bin/tfactl senduninstallupdate

	$ECHO "Sleeping for 10 seconds...";
	$SLEEP 10;
	$ECHO "";
fi

if [ "$RUSER" = "$DAEMON_OWNER" ]
then
	if [ -f "$tfa_home/ext/orachk/lib/autostart" ]
	then
    		$tfa_home/bin/tfactl stoporachkdaemon;
	fi
fi

if [ -f "$tfa_home/internal/rest.properties" ]
then
	$ECHO "Stopping TFA REST Services...";
	$tfa_home/bin/tfactl rest -uninstall > /dev/null;
	$ECHO "";
fi

# Stop Support Tools
$ECHO "Stopping TFA Support Tools..."; 
$tfa_home/bin/tfactl stop_suptools > /dev/null 2>&1
$ECHO "";

# Stop tfa in localhost
$ECHO "Stopping TFA in $HOSTNAME..."
$ECHO "";
$tfa_home/bin/tfactl shutdown
$ECHO "";

RUN_MODE="collector";

if [ -f "$tfa_home/tfa_setup.txt" ]
then
  if [ `$GREP -c '^RUN_MODE=' "$tfa_home/tfa_setup.txt"` -ge 1 ]
  then
    RUN_MODE=`$GREP '^RUN_MODE=' $tfa_home/tfa_setup.txt | $AWK -F"=" '{print $2}'`;
  fi
fi

if [ "$RUN_MODE" = "receiver" ]
then
  # remove receiver user
  if [ -f "$tfa_home/receiver/internal/rconfig.properties" ]
  then
    RCV_USR=`$CAT $tfa_home/receiver/internal/rconfig.properties | $GREP r.user | $AWK -F'=' '{print $2}'`;

    if [ "$USERID $RCV_USR" > /dev/null 2>&1 ]
    then
      `/usr/sbin/userdel -f $RCV_USR >/dev/null 2>&1`
    fi
  fi

  # if receiver is running, stop it
  if [ -f "$tfa_home/receiver/internal/.receiver.lck" ]
  then
    $tfa_home/bin/tfactl receiver stop
  fi

  # If clusterwide uninstall, remove entire receiver repository, else remove this nodes' folder from repository
  RCV_REPOS=`$CAT $tfa_home/receiver/internal/rconfig.properties | $GREP r.repository | $AWK -F'=' '{print $2}'`;

  if [ \( "$LOCAL" -eq 0 -a "$CLUSTERWIDE" -eq 0 \) -o  "$CLUSTERWIDE" -eq 1 ]
  then
    $ECHO "Removing receiver repository...";
    if [ -d "$RCV_REPOS/receiver" ]
    then
      $RM -rf "$RCV_REPOS/receiver" 2> /dev/null;
    fi
  else
    $ECHO "Removing index data for local node from receiver repository...";
    if [ -d "$RCV_REPOS/receiver/$HOSTNAME" ]
    then
      $RM -rf "$RCV_REPOS/receiver/$HOSTNAME" 2> /dev/null;
    fi
  fi
else
  # If its a client node remove the receiver.
  RCV=`$tfa_home/bin/tfactl print robjects | $HEAD -1 | $AWK -F":" '{print $2}' | $AWK -F~ '{print $1}' | $SED 's/ //g'`
  if [ -n "$RCV" ]
  then
    $ECHO "Removing Receiver $RCV"
    $tfa_home/bin/tfactl receiver remove $RCV
  fi
fi

# Stop and delete tfa_home on remote hosts
if [ "$LOCAL" -eq 0 ]
then
	for NODE in $NODE_LIST
	do
		$ECHO "";

		if [ `$ECHO $tfa_home | grep -ic "/tfa/$HOSTNAME/tfa_home"` -eq "1" ]
		then		
			rem_tfa_home=`$ECHO $tfa_home | $SED 's%/tfa/'$HOSTNAME'/tfa_home%/tfa/'$NODE'/tfa_home%'`;

			if [ -z "$rem_tfa_home" ]
			then
				$ECHO "Unable to determine TFA_HOME on $NODE";
			else
				$ECHO "Stopping TFA in $NODE and removing $rem_tfa_home...";
				$SSH $NODE "$rem_tfa_home/bin/uninstalltfa -clusterwide"
			fi
		else
			$ECHO "Stopping TFA in $NODE and removing $tfa_home..."
			$SSH $NODE "$tfa_home/bin/uninstalltfa -clusterwide"
		fi
	done
fi

# Delete TFA files in local
$ECHO "Deleting TFA support files on $HOSTNAME:"

# Remove BDB and logs for GI/DB Install
if [ -f "$tfa_home/tfa_setup.txt" ]
then
	INSTALL_TYPE=`$GREP '^INSTALL_TYPE=' $tfa_home/tfa_setup.txt | $AWK -F"=" '{ print $2 }'`;

	if [ "$INSTALL_TYPE" = "GI" ] || [ "$INSTALL_TYPE" = "DB" ]
	then
        	ORACLE_BASE=`$GREP '^ORACLE_BASE=' $tfa_home/tfa_setup.txt | $AWK -F"=" '{ print $2 }'`

                if [ -n "$ORACLE_BASE" ] && [ -d "$ORACLE_BASE" ] 
                then
                        BDB_DIR="$ORACLE_BASE/tfa/$HOSTNAME/database";
                        LOG_DIR="$ORACLE_BASE/tfa/$HOSTNAME/log";
			OUT_DIR="$ORACLE_BASE/tfa/$HOSTNAME/output";

                        if [ -d "$BDB_DIR" ]
                        then
                                $ECHO "Removing $BDB_DIR...";
                                $RM -rf $BDB_DIR;
                        fi

                        if [ -d "$LOG_DIR" ]
                        then
                                $ECHO "Removing $LOG_DIR...";
                                $RM -rf $LOG_DIR;
                        fi

			if [ -d "$OUT_DIR" ]
			then
				$ECHO "Removing $OUT_DIR...";
				$RM -rf $OUT_DIR;
			fi

                        if [ -d "$ORACLE_BASE/tfa/$HOSTNAME" ]
                        then
                                $ECHO "Removing $ORACLE_BASE/tfa/$HOSTNAME...";
                                $RM -rf $ORACLE_BASE/tfa/$HOSTNAME;
                        fi

			#Added below to remove .<node>.shared under <ORACLE_BASE>/tfa
			SHARED_FILE="$ORACLE_BASE/tfa/.$HOSTNAME.shared";

			if [ -f "$SHARED_FILE" ]
			then
				#$ECHO "Removing $SHARED_FILE...";
				$RM -rf $SHARED_FILE;
			fi

			SHARED_COUNT=`$LS -a $ORACLE_BASE/tfa/.*.shared 2> /dev/null | $WC -l`;

			if [ "$SHARED_COUNT" -eq "0" ]
			then
				if [ -d "$ORACLE_BASE/tfa" ]
				then
					$ECHO "Removing $ORACLE_BASE/tfa...";
					$RM -rf $ORACLE_BASE/tfa;
				fi
			fi
                        
                        if [ -d "$ORACLE_BASE/tfa" ]
                        then
                                NEWOWNER=`$LS -ld $ORACLE_BASE/. | $AWK '{print $3":"$4}'`;

				if [ -n "$NEWOWNER" ]
				then
                                	$ECHO "Changing ownership of $ORACLE_BASE/tfa to $NEWOWNER.";
					$CHOWN -R $NEWOWNER $ORACLE_BASE/tfa;
				else
                                	$ECHO "Unable to change ownership of $ORACLE_BASE/tfa";
				fi
                        fi
                fi
        fi
fi

if [ `$ECHO $tfa_home | grep -ic "/tfa/$HOSTNAME/tfa_home"` -eq "1" ]
then
	local_base_dir=`$ECHO $tfabase | $SED -e "s/\/[^\/]*$//"`;

	# Remove init.tfa and it's rc sym links
	for rc in $RCKDIR
	do
		if [ -f "$rc/$RC_KILL"init.tfa ]
		then
			$ECHO "Removing $rc/"$RC_KILL"init.tfa"
			$RM -f $rc/"$RC_KILL"init.tfa
		fi
	done
         
	if [ -f "$ID/init.tfa" ] 
	then
		$ECHO "Removing $ID/init.tfa..."
		$RM -f $ID/init.tfa
	fi

        # This will remove GIHOME/bin/tfactl
        if [ -n "$CRS_HOME" ] && [ ! -n "$ADE_VIEW_NAME" ]
        then
            if [ -f "$CRS_HOME/bin/tfactl" ]
            then
		$ECHO "Removing $CRS_HOME/bin/tfactl...";
		$RM -f $CRS_HOME/bin/tfactl;
            fi
        fi

	# Added below to remove .<node>.shared under TFA_HOME
	SHARED_FILE="$tfa_home/.$HOSTNAME.shared";

	if [ -f "$SHARED_FILE" ]
	then
		#$ECHO "Removing $SHARED_FILE...";
		$RM -f $SHARED_FILE;
	fi

	SHARED_COUNT=`$LS -a $tfa_home/.*.shared 2> /dev/null | $WC -l`;

	if [ "$SHARED_COUNT" -eq "0" ]
	then
		if [ -d "$local_base_dir/bin" ]
		then
			# Check Shared TFA Homes
			if [ `$LS $local_base_dir/*/tfa_home/bin/tfactl.pl 2> /dev/null | $GREP -v "$HOSTNAME/tfa_home" | $WC -l | $SED 's/ //g'` -eq "0" ]
			then
				$ECHO "Removing $local_base_dir/bin...";
				if [ -f "$local_base_dir/bin/tfactl" ]
				then
					$RM -f $local_base_dir/bin/tfactl;
				fi

				$RM -rf $local_base_dir/bin;
			fi
		fi
	fi

	if [ -d "$tfabase" ]
	then
		$ECHO "Removing $tfabase...";
		(sleep 1;$NOHUP $RM -rf $tfabase > /dev/null 2> /dev/null) &
	fi

	if [ "$INSTALL_TYPE" = "GI" ] && [ -d "$CRS_HOME/tfa" ]
	then
		$ECHO "Removing $CRS_HOME/tfa...";
		$RM -rf $CRS_HOME/tfa;
	fi
else
	if [ -f "$tfabase/final_tfa_discovery.out" ]
	then
		$RM -f $tfabase/final_tfa_discovery.out
	fi

	if [ -f "$tfabase/ora_stack_status.out" ]
	then
		$RM -f $tfabase/ora_stack_status.out
	fi

	if [ -f "$tfabase/ora_stack_status_pct.out" ]
	then
		$RM -f $tfabase/ora_stack_status_pct.out
	fi

	# This will remove GIHOME/bin/tfactl
	if [ -f "$CRS_HOME/bin/tfactl" ]
	then
		$ECHO "Removing $CRS_HOME/bin/tfactl...";
		$RM -f $CRS_HOME/bin/tfactl;
	fi

	if [ -f "$ID/init.tfa" ]
	then	
		$ECHO "Removing $ID/init.tfa..."
		$RM -f $ID/init.tfa
	fi

	if [ -d "$tfa_home" ]
	then	
		$ECHO "Removing $tfa_home...";
		(sleep 1; $NOHUP $RM -rf $tfa_home > /dev/null 2> /dev/null )&
	fi
fi

$ECHO "";
