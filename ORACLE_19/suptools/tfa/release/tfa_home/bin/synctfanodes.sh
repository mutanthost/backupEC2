#!/bin/sh
#
# $Header: tfa/src/v2/tfa_home/bin/synctfanodes.sh /main/24 2018/05/28 15:06:28 bburton Exp $
#
# synctfanodes.sh
#
# Copyright (c) 2015, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      synctfanodes.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    cnagur      05/14/18 - Fix for bug 27993246
#    cnagur      10/31/17 - Fix for Bug 27003629
#    chchoudh    07/11/17 - fix for bug #26375074
#    cnagur      06/22/17 - Fix for Bug 26267241
#    chchoudh    06/22/17 - syncing receiver certificates
#    cnagur      02/14/17 - Non Root Daemon Changes
#    cnagur      01/27/17 - Support comma separated Node List - Bug 25426459
#    cnagur      12/21/16 - Added flag -regenerate - Bug 25250496
#    bburton     11/20/16 - ensure host has no invalid characters
#    cnagur      11/24/16 - Create .initRestartTFA for Shared File Systems
#    cnagur      09/02/16 - Fix for Bug 24526392
#    llakkana    05/03/16 - Exit on enter of wrong password
#    cnagur      04/05/16 - Fix for Bug 23051926
#    cnagur      04/04/16 - Fixed Issue with JAVA_HOME
#    llakkana    02/17/16 - Escape special chars in PASS like [,]
#    cnagur      02/16/16 - Fix for Bug 22545045
#    cnagur      01/14/16 - Changes for Java 8
#    cnagur      10/08/15 - Added Help Message
#    cnagur      08/30/15 - Fix for Bug 21421160
#    cnagur      08/21/15 - Fix for Bug 21665128
#    cnagur      08/12/15 - Support on Shared FS
#    cnagur      06/25/15 - Creation
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

SCRIPT="synctfanodes.sh";
UNAME=`getCommandLocation "uname"`;
PLATFORM=`$UNAME`;
AWK=`getCommandLocation "awk"`;
CAT=`getCommandLocation "cat"`;
CUT=`getCommandLocation "cut"`;
CHOWN=`getCommandLocation "chown"`;
CP=`getCommandLocation "cp"`;
ECHO=`getCommandLocation "echo"`;
EXPECT=`getCommandLocation "expect"`;
EXPR=`getCommandLocation "expr"`;
GREP=`getCommandLocation "grep"`;
PERL=`getCommandLocation "perl"`;
RUID=`getCommandLocation "id"`;
RM=`getCommandLocation "rm"`;
SCP=`getCommandLocation "scp"`;
SCP="$SCP -q";
SED=`getCommandLocation "sed"`;
SLEEP=`getCommandLocation "sleep"`;
SSH=`getCommandLocation "ssh"`;
SSH="$SSH -q";
SSH_USER="root";
TOUCH=`getCommandLocation "touch"`;
RUN_MODE="collector";
DAEMON_OWNER="root";

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

runstatus=$?
if [ $runstatus -ne 0 ]; then
  exit 1;
fi

}

# print help function
printhelp() {
	$ECHO "";
	$ECHO "   Usage :";
	$ECHO "";
	$ECHO "   This will generate and copy TFA Certificates to other TFA Nodes"
	$ECHO "";
	$ECHO "   $SCRIPT [-regenerate] [-help]";
	$ECHO "";
	$ECHO "     -regenerate   Regenerate TFA Certificates";
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
*)     $ECHO "ERROR: Unknown Operating System";
       exit -1
       ;;
esac

while [ $# -gt 0 ]
do
	case $1 in
		-tfa_home) 	shift; tfa_home=$1;;
		-regenerate) 	REGENERATE=$1;;
		-help) 		HELP=$1;;
		-h) 		HELP=$1;;
		*) 		$ECHO "Invalid Option $1 for TFA"; printhelp ; exit 1
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

if [ ! -d "$tfa_home" ]
then
	$ECHO "TFA is not Installed on this machine. Exiting now...";
	exit;
fi

if [ -f "$tfa_home/tfa_setup.txt" ]
then
	if [ `$GREP -c '^DAEMON_OWNER=' $tfa_home/tfa_setup.txt` -ge 1 ]
	then
	        DAEMON_OWNER=`$GREP '^DAEMON_OWNER=' $tfa_home/tfa_setup.txt | $AWK -F"=" '{print $2}'`;
	fi

	if [ `$GREP -c '^PERL=' $tfa_home/tfa_setup.txt` -ge 1 ]
	then
	        PERL=`$GREP '^PERL=' $tfa_home/tfa_setup.txt | $AWK -F"=" '{print $2}'`;
	fi

	if [ `$GREP -c '^CRS_HOME=' $tfa_home/tfa_setup.txt` -ge 1 ]
	then
	        CRS_HOME=`$GREP '^CRS_HOME=' $tfa_home/tfa_setup.txt | $AWK -F"=" '{print $2}'`;
	fi

	if [ `$GREP -c '^RUN_MODE=' $tfa_home/tfa_setup.txt` -ge 1 ]
	then
	        RUN_MODE=`$GREP '^RUN_MODE=' $tfa_home/tfa_setup.txt | $AWK -F"=" '{print $2}'`;
	fi
fi

RUSER=`$RUID | $AWK '{print $1}' | $AWK -F\( '{print $2}' | $AWK -F\) '{print $1}'`;

if [ $RUSER != $DAEMON_OWNER ]
then
	$ECHO "User '$RUSER' does not have permissions to run this script.";
	exit 1;
fi

SSH_USER="$DAEMON_OWNER";

HOSTNAME=`hostname | $CUT -d. -f1 | $PERL -ne 'print lc'`;

tfa_base=`$ECHO $tfa_home | $SED -e "s/\/[^\/]*$//"`;

# Check if TFA HOME contains HOSTNAME
if [ `$ECHO $tfa_home | $GREP -ic "$HOSTNAME"` -ge "1" ]
then
        tfa_base=`$ECHO $tfa_base | $SED -e "s/\/[^\/]*$//"`;
fi

if [ -n "$REGENERATE" ]
then
	if [ -f "$tfa_home/server.jks" ]
	then
		$RM -f $tfa_home/server.jks;
	fi

	if [ -f "$tfa_home/client.jks" ]
	then
		$RM -f $tfa_home/client.jks;
	fi

	if [ -f "$tfa_home/internal/ssl.properties" ]
	then
		$RM -f $tfa_home/internal/ssl.properties;
	fi

	# receiver keystore and ssl file
	if [ -f "$tfa_home/receiver/receiver.jks" ]
	then
		$RM -f $tfa_home/receiver/receiver.jks;
	fi

	if [ -f "$tfa_home/receiver/internal/r.ssl.properties" ]
	then
		$RM -f $tfa_home/receiver/internal/r.ssl.properties;
	fi
fi

if [ ! -s "$tfa_home/server.jks" ]
then
	if [ ! -n "$REGENERATE" ]
	then
		$ECHO "TFA has not yet generated any certificates on this Node.";
		$ECHO "";
		printf "Do you want to generate new certificates to synchronize across the nodes? [Y|N] [Y]: ";
		read userinput;
		$ECHO "";

		if [ "$userinput" = "n" ] || [ "$userinput" = "N" ]
		then	
			$ECHO "Exiting Now...";
			exit 1;
		fi
	fi

	# Get JAVA HOME
	if [ -d "$tfa_home/jre" ]
	then
		TFA_JHOME="$tfa_home/jre";
	elif [ -f "$tfa_home/tfa_setup.txt" ]
	then
		TFA_JHOME=`$GREP '^JAVA_HOME=' $tfa_home/tfa_setup.txt | $AWK -F"=" '{print $2}'`;

		if [ ! -n "$TFA_JHOME" ]
		then
			# Get JAVA_HOME from TFA_BASE/java_install.out
			if [ -f "$tfa_base/$HOSTNAME/java_install.out" ]
			then
				TFA_JHOME=`$GREP '^JAVA_HOME=' $tfa_base/$HOSTNAME/java_install.out | $AWK -F"=" '{print $2}'`;
			fi
		fi
	fi

	if [ -s "$TFA_JHOME/bin/java" ]
	then
		$ECHO "Generating new TFA Certificates...";
		$tfa_home/bin/tfactl generatecerts $tfa_home $TFA_JHOME 1;
		$ECHO "";

		$ECHO "Restarting TFA on $HOSTNAME...";
		$tfa_home/bin/tfactl shutdown;
		$SLEEP 5;
		$tfa_home/bin/tfactl start;
		$ECHO "";
	else
		$ECHO "Unable to determine JAVA HOME. Exiting Now...";
		exit 1;
	fi
fi

# Check SSH Configuration before copying files
SSHD_CONFIG_FILE="/etc/ssh/sshd_config";

if [ -r "$SSHD_CONFIG_FILE" ]
then
	SSHD_ROOT_LOGIN=`$GREP "PermitRootLogin" $SSHD_CONFIG_FILE | $GREP -v "^#" | $AWK '{print $2}' | $GREP -c "^no$"`;

	if [ $SSHD_ROOT_LOGIN -eq 1 ]
	then
		$ECHO "Login using root is disabled in sshd config. Please enable it or";
		$ECHO "";
		$ECHO "Please copy these files manually to remote node and restart TFA";
		$ECHO "1. $tfa_home/server.jks";
		$ECHO "2. $tfa_home/client.jks";
		$ECHO "3. $tfa_home/internal/ssl.properties";
		$ECHO "";
		$ECHO "These files must be owned by root and should have 600 permissions.";
		$ECHO "";
		exit 1;
	fi
fi

COUNT=1;

tfahosts=`$tfa_home/bin/tfactl print hosts | $GREP "Host Name " | $AWK '{print $NF}' | $GREP -v "^$HOSTNAME$"`

$ECHO "";

$ECHO "Current Node List in TFA : ";
$ECHO "$COUNT. $HOSTNAME";

for host in $tfahosts
do
	COUNT=`$EXPR $COUNT + 1`;
	$ECHO "$COUNT. $host";
done

$ECHO "";

sync_list="/tmp/.tfa_node_sync_list_$$";
ping_list="/tmp/.tfa_node_ping_list_$$";

if [ -f "$sync_list" ]
then
	$RM -f $sync_list;
fi

if [ -f "$ping_list" ]
then
	$RM -f $ping_list;
fi

if [ -s "$CRS_HOME/bin/olsnodes" ]
then
	OLS_OUT=`$CRS_HOME/bin/olsnodes`;

	if [ $? -eq 0 ]
	then
		NODELIST="$OLS_OUT";
	fi
fi

if [ ! -n "$NODELIST" ]
then
	if [ -s "$CRS_HOME/crs/install/crsconfig_params" ]
	then
		NODELIST=`$GREP '^NODELIST=' $CRS_HOME/crs/install/crsconfig_params | $SED 's/[\$\`\;\(\)\&]//g' | $AWK -F"=" '{print $2}'`;
		NODELIST=`$ECHO $NODELIST | $SED 's/,/ /g'`;
	fi
fi

if [ -n "$NODELIST" ]
then
	$ECHO "Node List in Cluster :";
	COUNT=1;
	for host in $NODELIST
	do
		host=`$ECHO $host | $CUT -d. -f1 | $PERL -ne 'print lc'`;
		$ECHO "$COUNT. $host";
		COUNT=`$EXPR $COUNT + 1`;
	done
	$ECHO "";

	# Copy all the nodes to sync list 
	for host in $NODELIST
	do
		host=`$ECHO $host | $CUT -d. -f1 | $PERL -ne 'print lc'`;
		if [ $host != $HOSTNAME ]
		then
			$ECHO "$host" >> $sync_list;
		fi
	done

	for host in $tfahosts
	do
		if [ $host != $HOSTNAME ]
		then
			if [ `$ECHO $NODELIST | $GREP -ic $host` -eq 0 ]
			then
				$ECHO "$host" >> $sync_list;
			fi
		fi
	done
fi

if [ -s "$sync_list" ]
then
	$ECHO "Node List to sync TFA Certificates : ";
	$CAT -n $sync_list;
	$ECHO "";
else 
	$ECHO "Unable to determine Node List to be synced. Please update manually.";
	$ECHO "";
fi

printf "Do you want to update this node list? [Y|N] [N]: ";
read userinput;
$ECHO "";

if [ "$userinput" = "y" ] || [ "$userinput" = "Y" ]
then
	if [ -f $sync_list ]
	then
		$RM -f $sync_list;
	fi

	$ECHO "Please Enter all the remote nodes you want to sync...";
	$ECHO "";

	printf "Enter Remote Node List (separated by space) : ";
	read usernodelist;
	$ECHO "";

	if [ `$ECHO $usernodelist | $GREP -c ','` -ge "1" ]
	then
		usernodelist=`$ECHO $usernodelist | $SED 's/,/ /g'`;
	fi

	for host in $usernodelist
	do
		host=`$ECHO $host | $CUT -d. -f1 | $PERL -ne 'print lc'`;
		if [ $host != $HOSTNAME ]
		then
			$ECHO "$host" >> $sync_list;
		fi
	done
	
	if [ -s $sync_list ]
	then
		$ECHO "Node List to sync TFA Certificates : ";
		$CAT -n $sync_list;
		$ECHO "";
	fi
fi

if [ ! -s $sync_list ]
then
	$ECHO "Node List to sync TFA Certificates is Empty. Exiting Now...";
	exit 1;
fi

SAME=0;
COPY_CERT=0;

PING="/usr/sbin/ping";
if [ $PLATFORM = "Linux" ]
then
	PING="/bin/ping";
fi

for REMOTE_HOST in `$CAT $sync_list`
do
	if [ $PLATFORM = "SunOS" ]
	then
		$PING -s $REMOTE_HOST 5 5 > /dev/null 2>&1
	elif [ $PLATFORM = "HP-UX" ]
	then
		$PING $REMOTE_HOST -n 5 -m 5 > /dev/null 2>&1
	else
		$PING -c 1 -w 5 $REMOTE_HOST > /dev/null 2>&1
	fi

	PING_STATUS=$?

	if [ $PING_STATUS -ne 0 ]
	then
		$ECHO "Unable to ping Host $REMOTE_HOST. Please verify.";
		$ECHO "";
		continue;
	fi

	$ECHO "$REMOTE_HOST" >> $ping_list;	

	$ECHO "Syncing TFA Certificates on $REMOTE_HOST :"
	$SSH -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -l $SSH_USER $REMOTE_HOST ls > /dev/null 2>&1
	SSH_STATUS=$?

	TFA_HOME="$tfa_home";

	if [ `$ECHO $tfa_home | $GREP -ic "/tfa/$HOSTNAME/tfa_home"` -ge "1" ]
	then
		TFA_HOME=$tfa_base/$REMOTE_HOST/tfa_home;
	fi

	$ECHO "";
	$ECHO "TFA_HOME on $REMOTE_HOST : $TFA_HOME";
	$ECHO "";

	TFACTL="$TFA_HOME/bin/tfactl";

	if [ -d "$TFA_HOME" ]
	then
		$ECHO "Copying TFA Certificates to $REMOTE_HOST...";
		$CP -f $tfa_home/server.jks $TFA_HOME/server.jks;
		$CP -f $tfa_home/client.jks $TFA_HOME/client.jks;
		$CP -f $tfa_home/internal/ssl.properties $TFA_HOME/internal/ssl.properties;

		if [ "$RUN_MODE" = "receiver" ]
		then
			$ECHO "Copying TFA Receiver Certificates to $REMOTE_HOST...";
			$CP -f $tfa_home/receiver/receiver.jks $TFA_HOME/receiver/receiver.jks;
			$CP -f $tfa_home/receiver/internal/r.ssl.properties $TFA_HOME/receiver/internal/r.ssl.properties;
			$ECHO "";
		fi

		$ECHO "";

		if [ ! -f "$ID/init.tfa" ]
		then
			$ECHO "Please restart TFA on $REMOTE_HOST using below commands :";
			$ECHO "1. $TFACTL shutdown";
			$ECHO "2. $TFACTL start";
		else
			$TOUCH $TFA_HOME/internal/.initRestartTFA; 
		fi
		COPY_CERT=1;
		
	elif [ "$SSH_STATUS" -eq "0" ]
	then
		$ECHO "Shutting down TFA on $REMOTE_HOST...";
		$SSH $SSH_USER@$REMOTE_HOST $TFACTL shutdown > /dev/null;
		$ECHO "Copying TFA Certificates to $REMOTE_HOST...";
		$SCP $tfa_home/server.jks $SSH_USER@$REMOTE_HOST:$TFA_HOME/ > /dev/null;
		$SCP $tfa_home/client.jks $SSH_USER@$REMOTE_HOST:$TFA_HOME/ > /dev/null;
		$ECHO "Copying SSL Properties to $REMOTE_HOST...";
		$SCP $tfa_home/internal/ssl.properties $SSH_USER@$REMOTE_HOST:$TFA_HOME/internal/ > /dev/null;
		if [ "$RUN_MODE" = "receiver" ]
		then
			$ECHO "Copying TFA Receiver Certificates to $REMOTE_HOST...";
			$SCP $tfa_home/receiver/receiver.jks $SSH_USER@$REMOTE_HOST:$TFA_HOME/receiver/ > /dev/null;
			$ECHO "Copying Receiver SSL Properties to $REMOTE_HOST...";
			$SCP $tfa_home/receiver/internal/r.ssl.properties $SSH_USER@$REMOTE_HOST:$TFA_HOME/receiver/internal/ > /dev/null;

		fi
		$ECHO "Shutting down TFA on $REMOTE_HOST...";
		$SSH $SSH_USER@$REMOTE_HOST  $TFACTL shutdown > /dev/null;
		$ECHO "Sleeping for 5 seconds...";
		$SLEEP 5;
		$ECHO "Starting TFA on $REMOTE_HOST...";
		$SSH $SSH_USER@$REMOTE_HOST $TFACTL start > /dev/null;
	else
		if [ -f "$EXPECT" ]
		then
			if [ $SAME -ne 1 ]
			then
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
					$ECHO "";

					if [ "$userinput" != "n" ] && [ "$userinput" != "N" ]
					then
						SAME=1;
					else
						SAME=2;
					fi
				fi
			fi

			#Escape spl chars [,],"
			PASS=`$ECHO "$PASS" | $SED 's/\[/\\\[/g' | $SED 's/\]/\\\]/g' | $SED 's/\"/\\\"/g'`;

			$ECHO "Shutting down TFA on $REMOTE_HOST...";
			COMMAND="$SSH $SSH_USER@$REMOTE_HOST $TFACTL shutdown > /dev/null";
			runUsingExpect;
			$ECHO "Copying TFA Certificates to $REMOTE_HOST...";
			COMMAND="$SCP $tfa_home/server.jks $SSH_USER@$REMOTE_HOST:$TFA_HOME/";
			runUsingExpect;
			COMMAND="$SCP $tfa_home/client.jks $SSH_USER@$REMOTE_HOST:$TFA_HOME/";
			runUsingExpect;
			$ECHO "Copying SSL Properties to $REMOTE_HOST...";
			COMMAND="$SCP $tfa_home/internal/ssl.properties $SSH_USER@$REMOTE_HOST:$TFA_HOME/internal/";
			runUsingExpect;
			if [ "$RUN_MODE" = "receiver" ]
			then
				$ECHO "Copying TFA Receiver Certificates to $REMOTE_HOST...";
				COMMAND="$SCP $tfa_home/receiver/receiver.jks $SSH_USER@$REMOTE_HOST:$TFA_HOME/receiver/";
				runUsingExpect;
				$ECHO "Copying Receiver SSL Properties to $REMOTE_HOST...";
				COMMAND="$SCP $tfa_home/receiver/internal/r.ssl.properties $SSH_USER@$REMOTE_HOST:$TFA_HOME/receiver/internal/";
				runUsingExpect;
			fi
			$ECHO "Shutting down TFA on $REMOTE_HOST...";
			COMMAND="$SSH $SSH_USER@$REMOTE_HOST  $TFACTL shutdown > /dev/null";
			runUsingExpect;
			$ECHO "Sleeping for 5 seconds...";
			$SLEEP 5;
			$ECHO "Starting TFA on $REMOTE_HOST...";
			COMMAND="$SSH $SSH_USER@$REMOTE_HOST $TFACTL start > /dev/null";
			runUsingExpect;
			
		else 
			# Non Rot Daemon
			if [ ! -f "$ID/init.tfa" ]
			then
				$ECHO "Shutting down TFA on $REMOTE_HOST...";
				$SSH $SSH_USER@$REMOTE_HOST $TFACTL shutdown;
				$ECHO "";
			fi

			$ECHO "Copying TFA Certificates to $REMOTE_HOST...";
			$SCP $tfa_home/server.jks $tfa_home/client.jks $SSH_USER@$REMOTE_HOST:$TFA_HOME/ > /dev/null;
			$ECHO "Copying SSL Properties to $REMOTE_HOST...";
			$SCP $tfa_home/internal/ssl.properties $SSH_USER@$REMOTE_HOST:$TFA_HOME/internal/ > /dev/null;
			$ECHO "";
			if [ "$RUN_MODE" = "receiver" ]
			then
				$ECHO "Copying TFA Receiver Certificates to $REMOTE_HOST...";
				$SCP $tfa_home/receiver/receiver.jks $SSH_USER@$REMOTE_HOST:$TFA_HOME/receiver/ > /dev/null;
				$ECHO "Copying Receiver SSL Properties to $REMOTE_HOST...";
				$SCP $tfa_home/receiver/internal/r.ssl.properties $SSH_USER@$REMOTE_HOST:$TFA_HOME/receiver/internal/ > /dev/null;
				$ECHO "";
			fi
			$ECHO "Restarting TFA on $REMOTE_HOST...";

			if [ ! -f "$ID/init.tfa" ]
			then
				$ECHO "Starting TFA on $REMOTE_HOST...";
				$SSH $SSH_USER@$REMOTE_HOST $TFACTL start;
			else
				$ECHO "Restarting TFA on $REMOTE_HOST...";
				$SSH $SSH_USER@$REMOTE_HOST $ID/init.tfa restart;
			fi
		fi
	fi
	$ECHO "";
done

if [ "$COPY_CERT" -eq "1" ]
then
	$ECHO "Sleeping for 60 seconds...";
	$SLEEP 60;
fi

# Add Nodes if not already added
tfahosts=`$tfa_home/bin/tfactl print hosts | $GREP "Host Name " | $AWK '{print $NF}' | $GREP -v "^$HOSTNAME$"`

for REMOTE_HOST in `$CAT $ping_list`
do
	if [ `$ECHO $tfahosts | $GREP -ic $REMOTE_HOST` -eq 0 ]
	then
		$ECHO "Trying to add $REMOTE_HOST to TFA...";
		$tfa_home/bin/tfactl host add $REMOTE_HOST -silent;
		$ECHO "";
	fi
done

$tfa_home/bin/tfactl print status;

if [ -f "$sync_list" ]
then
	$RM -f $sync_list;
fi

if [ -f "$ping_list" ]
then
	$RM -f $ping_list;
fi

$ECHO "";

