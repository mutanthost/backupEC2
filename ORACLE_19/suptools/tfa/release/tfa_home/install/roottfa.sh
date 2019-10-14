#!/bin/sh
#
# $Header: tfa/src/v2/tfa_home/install/roottfa.sh /st_tfa_19/2 2018/09/26 20:28:10 cnagur Exp $
#
# roottfa.sh
#
# Copyright (c) 2015, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      roottfa.sh - Setup Trace File Analyzer during root.sh in single instance installation.
#
#    DESCRIPTION
#      Driver script to setup TFA in SI install
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    cnagur      09/26/18 - Fix for Bug 28705997
#    cnagur      09/20/18 - Fix for Bug 28673448
#    cnagur      01/17/18 - Fix for Bug 27366823
#    cnagur      07/19/17 - Fix for Bug 26084129
#    cnagur      01/28/16 - Added Help Message
#    cnagur      10/20/15 - Added getCommandLocation()
#    gadiga      05/13/15 - bug 21086422.. less verbose
#    gadiga      04/17/15 - support silent and installtfla
#    gadiga      03/17/15 - install TFA during root.sh run
#    gadiga      03/17/15 - Creation
#

# Variables from silent install
# $SILENT
# $INSTALL_TFA
# $LOG

# Decision matrix
# Decision matrix
# $SILENT     $INSTALL_TFA
#       0               0  -> Prompt for installation with default answer no
#       1               0  -> Silent install. Dont prompt user. Assume no as answer and just print message.
#       0               1  -> Assume answer is yes and setup TFA.
#       1               1  -> Assume answer is yes and setup TFA in complete silent mode and redirect log to $LOG.

# Function to get the location of commands
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

# Print Help Function
printhelp() {

$ECHO ""
$ECHO "   Usage for $SCRIPT :"
$ECHO ""
$ECHO "   $SCRIPT [-h] [-help]"
$ECHO ""
$ECHO "   	This script will install Oracle Trace File Analyzer (TFA) in ORACLE_BASE"
$ECHO "   	Note : Please set ORACLE_HOME before running this script"
$ECHO ""

}

SCRIPT=${0};
AWK=`getCommandLocation "awk"`;
DATE=`getCommandLocation "date"`;
ECHO=`getCommandLocation "echo"`;
LN=`getCommandLocation "ln"`;
LS=`getCommandLocation "ls"`;
RM=`getCommandLocation "rm"`;
SU=`getCommandLocation "su"`;
UNAME=`getCommandLocation "uname"`;

# Parse Arguments
while [ $# -gt 0 ]
do
	case $1 in
		-help) HELP=$1;; 	# print the help and exit
		-h) HELP=$1;;   	# print the help and exit
		*) $ECHO "Invalid Option $1 for TFA"; printhelp ; exit 1
	esac;
	shift;
done

if [ $HELP ]
then
	printhelp;
	exit 1;
fi

if [ -z "${ORACLE_HOME}" ]
then
	$ECHO "ERROR: ORACLE_HOME is not set";
	exit 1;
fi

if [ ! -d "${ORACLE_HOME}" ]
then
	$ECHO "Provided ORACLE_HOME directory $ORACLE_HOME does not exist";
	exit 1;
fi

if [ -f "$ORACLE_HOME/crs/install/crsconfig_params" ]
then
	$ECHO "This script should only be used to install TFA in a valid RDBMS Home.";
	$ECHO "ORACLE_HOME directory $ORACLE_HOME appears to be a Grid Infrastructure Home.";
	exit 1;
fi

if [ ! -f "$ORACLE_HOME/suptools/tfa/release/tfa_home/bin/tfactl" ]
then
	$ECHO "Provided ORACLE_HOME directory $ORACLE_HOME is not valid. Please verify once again.";
	exit 1;
fi

if [ -z "$SILENT" ]
then
	SILENT=0;
fi

if [ -z "$LOG" ]
then 
	LOG=${ORACLE_HOME}/install/root_`$UNAME -n`_`$DATE +%F_%H-%M-%S`.log ; export LOG
fi

if [ -z "$INSTALL_TFA" ]
then
	INSTALL_TFA=0; 
fi

tfa_silent_flag="";

if [ $SILENT -eq 0 ]
then
	$ECHO "Oracle Trace File Analyzer (TFA - Standalone Mode) is available at :";
	$ECHO "    $ORACLE_HOME/bin/tfactl";
	$ECHO "";
	$ECHO "Note :";
	$ECHO "1. tfactl will use TFA Service if that service is running and user has been granted access";
	$ECHO "2. tfactl will configure TFA Standalone Mode only if user has no access to TFA Service or TFA is not installed";
	$ECHO "";
else
        $ECHO "Oracle Trace File Analyzer (TFA) is available at : $ORACLE_HOME/bin/tfactl " >> $LOG 2>&1
fi

LINK=1;

# GET ORACLE User
ORACLE_USER=`$LS -ld $ORACLE_HOME | $AWK '{ print $3}'`;

if [ -n "$ORACLE_USER" ]
then
	if [ -f "$ORACLE_HOME/bin/tfactl" ]
	then
		if [ -L "$ORACLE_HOME/bin/tfactl" ]
		then
			# Do not link tfactl in ORACLE_HOME
			LINK=0;
		else
			# Remove existing tfactl file
			$SU $ORACLE_USER -c "$RM -f $ORACLE_HOME/bin/tfactl" > /dev/null 2>&1;
		fi
	fi

	if [ $LINK -eq 1 ]
	then
		# Link tfactl in $ORACLE_HOME/bin
		$SU $ORACLE_USER -c "$LN -s $ORACLE_HOME/suptools/tfa/release/tfa_home/bin/tfactl $ORACLE_HOME/bin/tfactl" > /dev/null 2>&1;
	fi
fi

exit 0;
