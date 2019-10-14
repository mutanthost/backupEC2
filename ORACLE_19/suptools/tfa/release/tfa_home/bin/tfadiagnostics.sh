#!/bin/sh
#
# $Header: tfa/src/v2/tfa_home/bin/tfadiagnostics.sh /st_tfa_19/1 2018/09/20 22:37:16 cnagur Exp $
#
# tfadiagnostics.sh
#
# Copyright (c) 2015, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfadiagnostics.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    cnagur      09/18/18 - XbranchMerge cnagur_tfa_patch_exit_status from main
#    cnagur      09/07/18 - Disable TFA Warning Messages
#    cnagur      05/14/18 - Fix for bug 27993246
#    migmoren    04/17/18 - Bug 27864765 - LNX-191-TFA:DIAGNOSETFA HIT SYNTAX
#                           ERRORBug 27827269 - LNX-191-TFA:TFADIAGNOSTICS.SH:
#                           LINE 162: SYNTAX ERROR NEAR UNEXPECTED TOKEN `HEL
#    cnagur      10/31/17 - Fix for Bug 27003629
#    cnagur      02/14/17 - Non Root Daemon Changes
#    cnagur      01/13/17 - Fix for Bug 25391435
#    bburton     11/20/16 - ensure no invalid chars in hostname
#    arupadhy    06/21/16 - Updated help to make it consistent with other help
#                           messages
#    cnagur      06/10/16 - Fix for Bug 22856578
#    cnagur      06/08/16 - Create temp files under /tmp dir
#    cnagur      03/30/16 - Fix for Bug 23001480
#    llakkana    12/22/15 - XbranchMerge llakkana_bug-22450457 from
#                           st_tfa_12.1.2.6
#    bibsahoo    10/20/15 - FIX BUG 21977617 - [12201-LIN64-TFA] TFACTL
#                           DIAGNOSETFA GIVE CONFUSED MSG WITH -H OPTION
#    llakkana    12/22/15 - Fix 22450457
#    cnagur      09/14/15 - Fix for Bug 21789336
#    bibsahoo    09/07/15 - Fix BUG 21789281 - LNX64-12.2-TFA:DID NOT DELETE
#                           ZIP FROM REMOTE AFTER DIAGNOSETFA
#    amchaura    09/04/15 - Fix Bug 21789237 - NX64-12.2-TFA:DIAGNOSETFA SHOULD
#                           COLLECT LOCAL TFA FILES BY DEFAULT
#    cnagur      08/17/15 - Creation
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

SCRIPT=${0};
UNAME=`getCommandLocation "uname"`;
PLATFORM=`$UNAME`;
AWK=`getCommandLocation "awk"`;
CAT=`getCommandLocation "cat"`;
CUT=`getCommandLocation "cut"`;
CHMOD=`getCommandLocation "chmod"`;
ECHO=`getCommandLocation "echo"`;
EXPECT=`getCommandLocation "expect"`;
GREP=`getCommandLocation "grep"`;
MKDIR=`getCommandLocation "mkdir"`;
RUID=`getCommandLocation "id"`;
SCP=`getCommandLocation "scp"`;
SCP="$SCP -q";
SED=`getCommandLocation "sed"`;
SLEEP=`getCommandLocation "sleep"`;
SSH=`getCommandLocation "ssh"`;
SSH="$SSH -q";
PERL=`getCommandLocation "perl"`;
DAEMON_OWNER="root";

# Disable TFA Update Warning Message
export TFA_SUPPRESS_AGE_WARN="TRUE";

runUsingExpect() {

#echo "Command to Run : $COMMAND";

$EXPECT -f - << IBEOF
        set timeout 10
        log_user 0
        set prompt "(%|#|$) $";
        catch {set prompt $env(EXPECT_PROMPT)}

        spawn -noecho $COMMAND

        expect {
                "no)?" {
                        send -- "yes\n"
                        exp_continue
                }
                "*?assword:*" {
                        send -- "$PASS\n"
                        exp_continue
                }
                "Permission denied *" {
                        send_error "\nPermission denied. Please check the password of $REMOTE_HOST.\n";
                        exit 2;
                }
                LoginSuccessfull {
                        exit 0;
                }
                -re $prompt {
                        send_error "Prompt : $prompt\n";
                }
                timeout {
                        send_error "Connect to $REMOTE_HOST was timed out.\n"
                        exit 3;
                }
        }
IBEOF

}

# print help function
printhelp() {
	$ECHO "";
	$ECHO "   Usage :";
	$ECHO "";
	$ECHO "      tfactl diagnosetfa [-repo <repository>] [-tag <tag_name>] [-local]";
	$ECHO "";
	$ECHO "		repository        Repository directory for TFA Diagnostic Collections";
	$ECHO "		tag_name          The files will be collected into tag_name directory";
	$ECHO "		local             Run TFA Diagnostics only on local node";
	$ECHO "";
}

case $PLATFORM in
Linux)
        ID=/etc/init.d
        ;;
AIX)
        ID=/etc
        ;;
SunOS)
        ID=/etc/init.d
	RUID=/usr/xpg4/bin/id;
        GREP=/usr/xpg4/bin/grep
        ;;
HP-UX)
        ID=/sbin/init.d
        ;;
*)     /bin/echo "ERROR: Unknown Operating System"
       exit -1
       ;;
esac

repository="/tmp";
tag="tfadiagnostics_`date '+%Y%m%d_%H%M%S'`";

while [ $# -gt 0 ]
do
	case $1 in
		-tfa_home)	shift; tfa_home=$1;;
		-repo) 		shift; repository=$1;;
		-tag)		shift; tag=$1;;
		-local)		LOCAL=$1;;
		-help)		HELP=$1;;
		-h) 		HELP=$1;;
		*)		$ECHO "Invalid Option $1 for TFA"; printhelp ; exit 1
	esac;
	shift;
done

if [ $HELP ]
then
	printhelp;
	exit 1;
fi

$ECHO "";

if [ ! -d "$tfa_home" ]
then
	if [ ! -r "$ID/init.tfa" ]
	then
        	$ECHO "TFA is not Installed on this machine. Exiting now...";
        	exit;
	fi

	tfa_home=`$GREP '^TFA_HOME=' $ID/init.tfa | $AWK -F"=" '{print $2}'`;
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

if [ $RUSER != $DAEMON_OWNER ]
then
	$ECHO "User '$RUSER' does not have permissions to run this script.";
	exit 1;
fi

SSH_USER="$DAEMON_OWNER";

if [ -d "$repository/$tag" ]
then
	$ECHO "Directory [$repository/$tag] already exists. Using new tag for collecting diagnostics...";
	$ECHO "";
	tag="tfadiagnostics_`date '+%Y%m%d_%H%M%S'`";
fi

HOSTNAME=`hostname | $CUT -d. -f1 | $PERL -ne 'print lc'`;

tfa_base=`$ECHO $tfa_home | $SED -e "s/\/[^\/]*$//"`;

# Check if TFA HOME contains HOSTNAME
if [ `$ECHO $tfa_home | $GREP -ic "$HOSTNAME"` -ge "1" ]
then
        tfa_base=`$ECHO $tfa_base | $SED -e "s/\/[^\/]*$//"`;
fi

$MKDIR -p "$repository/$tag";

node_list="/tmp/tfa_node_list_$$";

if [ -s "$node_list" ]
then
	rm -f $node_list;
fi

# Node List
if [ -n "$LOCAL" ]
then
	$ECHO "$HOSTNAME" >> $node_list;
else
	tfahosts=`$tfa_home/bin/tfactl print hosts | $GREP "Host Name " | awk '{print $NF}'`

	if [ -s "$CRS_HOME/crs/install/crsconfig_params" ]
	then
		NODELIST=`$GREP '^NODELIST=' $CRS_HOME/crs/install/crsconfig_params | $SED 's/[\$\`\;\(\)\&]//g' | $AWK -F"=" '{print $2}'`;

		NODELIST=`$ECHO $NODELIST | $SED 's/,/ /g'`;

		# Copy all the nodes to node list 
		for host in $NODELIST
		do
			$ECHO "$host" >> $node_list;
		done

		for host in $tfahosts
		do
			if [ `$ECHO $NODELIST | $GREP -c $host` -eq 0 ]
			then
				$ECHO "$host" >> $node_list;
			fi
		done
	fi
fi

if [ -s "$node_list" ]
then
	$ECHO "Node List to collect TFA Diagnostics : ";
	$CAT -n $node_list;
	$ECHO "";
else 
	$ECHO "Unable to determine Node List. Please update manually.";
	$ECHO "";
fi

if [ ! -n "$LOCAL" ]
then
	printf "Do you want to update this node list? [Y|N] [N]: ";
	read userinput;
	$ECHO "";

	if [ "$userinput" = "y" ] || [ "$userinput" = "Y" ]
	then
		if [ -f $node_list ]
		then
			rm -f $node_list;
		fi

		$ECHO "Please Enter all the nodes you want to collect diagnostics...";
		$ECHO "";

		printf "Enter Node List (seperated by space) : ";
		read usernodelist;
		$ECHO "";

		for host in $usernodelist
		do
			$ECHO "$host" >> $node_list;
		done
	
		if [ -s $node_list ]
		then
			$ECHO "Node List to collect TFA Diagnostics : ";
			$CAT -n $node_list;
			$ECHO "";
		fi
	fi
fi

if [ ! -s $node_list ]
then
	$ECHO "Node List to collect TFA Diagnostics is Empty.";
	$ECHO "";
	$ECHO "$HOSTNAME" >> $node_list;
fi

SAME=0;
RUNONLOCAL=0;

for REMOTE_HOST in `$CAT $node_list`
do
	if [ $REMOTE_HOST = $HOSTNAME ]
	then
		RUNONLOCAL=1;
		continue;
	fi

	$ECHO "Running TFA Diagnostics on $REMOTE_HOST...";	
	$SSH -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -l $SSH_USER $REMOTE_HOST ls > /dev/null 2>&1
	SSH_STATUS=$?

	TFA_HOME=$tfa_home

	if [ `$ECHO $tfa_home | $GREP -ic "/tfa/$HOSTNAME/tfa_home"` -ge "1" ]
	then
		TFA_HOME=$tfa_base/$REMOTE_HOST/tfa_home;
	fi

	$ECHO "";
	$ECHO "TFA_HOME on $REMOTE_HOST : $TFA_HOME";

	command="$PERL $TFA_HOME/bin/scripts/tfadiagnostics.pl -tfahome $TFA_HOME -repository $repository -tag $tag";

	if [ "$SSH_STATUS" -eq "0" ]
	then
		$SSH $SSH_USER@$REMOTE_HOST "$command > /dev/null" &
		
	elif [ -f "$EXPECT" ]
	then
		if [ $SAME -ne 1 ]
		then
			$ECHO "";
			printf "Please Enter the password for $REMOTE_HOST : ";
			stty -echo;
			read PASS;
			stty echo;
			$ECHO "";

			if [ $SAME -ne 2 ]
			then
				$ECHO "";
				printf "Is password same for all the nodes? [Y|N] [Y]: ";
				read userinput;

				if [ "$userinput" != "n" ] && [ "$userinput" != "N" ]
				then
					SAME=1;
				else
					SAME=2;
				fi
			fi
		fi

		COMMAND="$SSH $SSH_USER@$REMOTE_HOST $command > /dev/null &";
		runUsingExpect;

	else 
		$SSH $SSH_USER@$REMOTE_HOST "$command > /dev/null &";
	fi
	$ECHO "";
done

if [ "$RUNONLOCAL" -eq "1" ]
then
	$ECHO "Running TFA Diagnostics on $HOSTNAME...";
	$ECHO "";
	$PERL $tfa_home/bin/scripts/tfadiagnostics.pl -tfahome $tfa_home -repository $repository -tag $tag;
	$ECHO "";
	$ECHO "Sleeping for 10 Seconds...";
	$SLEEP 10;
else
	$ECHO "Waiting for Remote Nodes to complete TFA diagnostics...";
	$SLEEP 30;
fi

$ECHO "";

retry_list="/tmp/tfa_retry_list_$$";

if [ -f "$retry_list" ]
then
	rm -f $retry_list;
fi

# Try to get zips from remote nodes
for COUNT in 0 1 2
do
	# Sleep for another 10 sec if Retry List is not empty
	if [ -s "$retry_list" ]
	then
		$ECHO "Waiting for Remote Nodes to complete TFA diagnostics...";
		$SLEEP 10;
		$ECHO "";
		$CAT $retry_list > $node_list;
		rm -f $retry_list;
	fi

	for REMOTE_HOST in `$CAT $node_list`
	do
		if [ $REMOTE_HOST = $HOSTNAME ]
		then
			continue;
		fi

		$ECHO "Copying TFA Diagnostics from $REMOTE_HOST...";
		$SSH -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -l $SSH_USER $REMOTE_HOST ls > /dev/null 2>&1
		SSH_STATUS=$?

		source="$repository/$tag/*.*";
		destination="$repository/$tag/";

		if [ "$SSH_STATUS" -eq "0" ]
		then
			$SCP $SSH_USER@$REMOTE_HOST:$source $destination > /dev/null;

			if [ -f "$repository/$tag/$REMOTE_HOST.zip" ]
			then
				$SSH $SSH_USER@$REMOTE_HOST "rm -rf $repository/$tag" > /dev/null &
			else
				if [ $COUNT -ne 2 ]
				then
					rm -f $repository/$tag/$REMOTE_HOST*;
				fi
				$ECHO "$REMOTE_HOST" >> $retry_list;
			fi
		elif [ -f "$EXPECT" ]
		then
			if [ $SAME -ne 1 ]
			then
				$ECHO "";
				printf "Please Enter the password for $REMOTE_HOST : ";
				stty -echo;
				read PASS;
				stty echo;
				$ECHO "";

				if [ $SAME -ne 2 ]
				then
					$ECHO "";
					printf "Is password same for all the nodes? [Y|N] [Y]: ";
					read userinput;

					if [ "$userinput" != "n" ] && [ "$userinput" != "N" ]
					then
						SAME=1;
					else
						SAME=2;
					fi
				fi
			fi

			COMMAND="$SCP $SSH_USER@$REMOTE_HOST:$source $destination";
			runUsingExpect;

			if [ -f "$repository/$tag/$REMOTE_HOST.zip" ]
			then
				COMMAND="$SSH $SSH_USER@$REMOTE_HOST \"rm -rf $repository/$tag\" > /dev/null &";
				runUsingExpect;
			else
				if [ $COUNT -ne 2 ]
				then
					rm -f $repository/$tag/$REMOTE_HOST*;
				fi
				$ECHO "$REMOTE_HOST" >> $retry_list;
			fi

		else 
			$SCP $SSH_USER@$REMOTE_HOST:$source $destination > /dev/null;

			if [ -f "$repository/$tag/$REMOTE_HOST.zip" ]
			then
				$SSH $SSH_USER@$REMOTE_HOST "rm -rf $repository/$tag > /dev/null &" > /dev/null;
			else
				if [ $COUNT -ne 2 ]
				then
					rm -f $repository/$tag/$REMOTE_HOST*;
				fi
				$ECHO "$REMOTE_HOST" >> $retry_list;
			fi
		fi
		$ECHO "";
	done

	# Break if retry list is empty
	if [ ! -s "$retry_list" ]
	then
		break;
	fi
done

# Change permissions of all the zips to 700
if [ -d "$repository/$tag" ]
then
	$CHMOD -R 700 "$repository/$tag";

	$ECHO "TFA Diagnostics are being collected to $repository/$tag :"
	ls -1 $repository/$tag/*.zip 2> /dev/null;
else
	$ECHO "Unable to collect TFA Diagnostics. Please try later...";
fi

# Remove temp files
if [ -f "$node_list" ]
then
	rm -f $node_list;
fi

if [ -f "$retry_list" ]
then
	rm -f $retry_list;
fi

$ECHO "";

