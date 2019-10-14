#!/bin/sh
# $Header: tfa/src/v2/tfa_home/bin/patchtfa.sh /st_tfa_19/4 2019/03/02 06:01:51 cnagur Exp $
#
# patchtfa.sh
#
# Copyright (c) 2012, 2019, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      patchtfa.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    cnagur      02/28/19 - Update jackson-annotations-2.9.8.jar
#    bibsahoo    01/31/19 - commons-io upgrade to version 2.6
#    cnagur      01/11/19 - Update jackson-databind-2.9.8.jar
#    llakkana    01/08/19 - Remove jsch jar
#    cnagur      12/04/18 - XbranchMerge
#                           cnagur_tfa_jackson_core-2.9.6_annotations-2.9.5_txn
#                           from main
#    cnagur      12/02/18 - Update jackson Jars
#    bburton     09/19/18 - add update of cipher suites on patch.
#    cnagur      09/18/18 - XbranchMerge
#    cnagur      09/07/18 - Stop Orachk Daemon before upgrading TFA
#    recornej    08/09/18 - Add dbversions.json to the patching.
#    bburton     08/08/18 - remove old serializable files
#    manuegar    08/09/18 - remove old serializable files.
#    cnagur      05/15/18 - Update Lucene Jars
#    cnagur      05/14/18 - Fix for bug 27993246
#    cnagur      05/10/18 - Notification using smtp.properties
#    bburton     05/10/18 - copy the Lucene Jars
#    cnagur      05/02/18 - Orachk Autostart
#    cnagur      04/09/18 - Fix for Bug 27812635
#    cnagur      02/11/18 - Fixed printing host while upgrading BDB
#    bburton     02/07/18 - 27510341 - not setting up orachk correctly
#    llakkana    12/11/17 - timezone mapping file changes
#    bburton     11/16/17 - Deal with patching new ora/exachk
#    cnagur      10/31/17 - Fix for Bug 27003629
#    bburton     10/25/17 - copy the oraclepki files
#    bburton     09/28/17 - set a variable to ensure tfactl commands do not
#                           state age limit whilst patching
#    cnagur      09/05/17 - Fix for Bug 26636362
#    gadiga      08/23/17 - solaris changes
#    llakkana    08/08/17 - TFA Receiver upgrade changes in DSC
#    cnagur      08/01/17 - Remove changes related certificates
#    cnagur      07/25/17 - Fix for Bug 26522376
#    cnagur      07/07/17 - Fix for Bug 26328304
#    bburton     06/05/17 - remote ssh fix from 12.1.2.8.4
#    cnagur      05/26/17 - Copy JRE to Remote Node
#    cnagur      05/19/17 - Remove inittab entries
#    bibsahoo    05/18/17 - FIX BUG 26093490
#    cnagur      05/26/17 - Copy JRE to Remote Node
#    cnagur      04/19/17 - Remove tfar.jar - Bug 25915789
#    cnagur      03/30/17 - Fix for Bug 25804785
#    cnagur      03/09/17 - Copy Buildid after patching - Bug 25385434
#    cnagur      09/26/16 - Ping Remote Nodes - Bug 23313514
#    cpujar      09/12/16 - Bug 23518126 - SED ERROR WHILE PATCHING TFA 121270 ON AIX
#    cnagur      08/17/16 - TFA_HOME JRE changes
#    cnagur      07/19/16 - Removed updatetfaclustermode changes
#    cnagur      07/14/16 - Fix for Bug 23860088
#    bburton     04/06/16 - ensure user directories at patch time
#    amchaura    03/17/16 - Fix 22892392, 22960013
#    amchaura    02/23/16 - Upgrade BDB version to 6.4.25
#    amchaura    02/10/16 - sync certificates through sockets if non GI TFA
#                           Install
#    cnagur      01/14/16 - Changes for Java 8
#    cnagur      12/30/15 - Fix for Bug 22361841
#    cnagur      12/21/15 - Added check for INSTALL_TYPE
#    cnagur      11/02/15 - Changes for .buildversion
#    cnagur      09/25/15 - Remove SIGAR
#    amchaura    06/28/15 - write env TZ to tfa_setup.txt
#    llakkana    06/24/15 - Replace commons io 2.2 with 2.1
#    cnagur      06/17/15 - Disable Socket Patching
#    bburton     06/09/15 - XbranchMerge bburton_fix_merge_port_file from
#                           st_tfa_12.1.0.2.4psu
#    bburton     05/11/15 - TFA was not patchinfg tfa_directories.txt
#    llakkana    04/21/15 - Copy rconfig file if not exist while upgrading
#    cnagur      03/23/15 - XbranchMerge cnagur_tfa_121240_patch_issues_txn
#                           from st_tfa_12.1.2.4
#    cnagur      02/27/15 - Fix for Bug 20615520
#    cnagur      01/16/15 - Changes to copy TFA 12102 Updated Jar
#    bburton     01/15/15 - patch local node last and use old execute method
#                           for patching 12.1.2.0.0 and older.
#    gadiga      01/14/15 - fix dev/null
#    cnagur      01/07/15 - Changes to enable AutoDiagcollect
#    cnagur      12/16/14 - Copy config.properties to remote nodes
#    gadiga      12/15/14 - stop suptools
#    llakkana    11/25/14 - tfar patch changes
#    amchaura    11/06/14 - Bug 19954370 - LNX64-12.2-TFA:AUTODIAGCOLLECT
#                           SUPPORT SCRIPT EXECUTION BASED ON SEARCH STRINGS
#    bburton     09/29/14 - XbranchMerge bburton_fix_patching from
#                           st_tfa_12.1.2
#    gadiga      09/22/14 - permission for oratop
#    bburton     09/22/14 - do not stop init.tfa
#    cnagur      09/22/14 - Added init checks for SunOS
#    cnagur      09/18/14 - Fix for Bug 19642614
#    cnagur      09/12/14 - Fix for Bug 19607799
#    cnagur      09/10/14 - Use PERL instead of AWk for hostname - Bug 19583163
#    cnagur      09/02/14 - Changes for config.properties
#    cnagur      08/06/14 - Integration of SIGAR - 19352380
#    amchaura    07/04/14 - changes for config.properties
#    cnagur      05/14/14 - Updated parameter for executecommand
#    amchaura    04/21/14 - Inventory perforamance enhancement
#    gadiga      03/31/14 - copy ext directory
#    cnagur      03/17/14 - Add PERL to tfa_setup.txt
#    cnagur      01/20/14 - Added -local to tfactl access enable
#    cnagur      01/09/14 - Changes for Certificate Issues
#    cnagur      01/08/14 - Changes for Non-root Access
#    cnagur      01/06/14 - Added .<node>.shared in TFA_HOME
#    cnagur      10/22/13 - Changes for 11204 to 12c Patching
#    cnagur      10/18/13 - Changes after renaming jar to jlib
#    cnagur      09/24/13 - Location for ZIP
#    cnagur      05/24/13 - Added Support for -local
#    bburton     01/22/13 - add platform support
#    sowsingh    09/19/12 - Creation
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

UNAME=`getCommandLocation "uname"`;
PLATFORM=`$UNAME`;
SLEEP=`getCommandLocation "sleep"`;
AWK=`getCommandLocation "awk"`;
CAT=`getCommandLocation "cat"`;
CHMOD=`getCommandLocation "chmod"`;
CUT=`getCommandLocation "cut"`;
CP=`getCommandLocation "cp"`;
ECHO=`getCommandLocation "echo"`;
GREP=`getCommandLocation "grep"`;
ID_CMD=`getCommandLocation "id"`;
JAVA=`getCommandLocation "java"`;
MKDIR=`getCommandLocation "mkdir"`;
MV=`getCommandLocation "mv"`;
RM=`getCommandLocation "rm"`;
SED=`getCommandLocation "sed"`;
TAIL=`getCommandLocation "tail"`;
TAR=`getCommandLocation "tar"`;
TOUCH=`getCommandLocation "touch"`;
ZIP=`getCommandLocation "zip"`;

# Variables for SSH
SSH=`getCommandLocation "ssh"`;
SSH="$SSH -q";
SCP=`getCommandLocation "scp"`;
SCP="$SCP -q";
SSH_KEYGEN=`getCommandLocation "ssh-keygen"`;
SSH_COPY_ID=`getCommandLocation "ssh-copy-id"`;
SSH_ENCR="rsa";
SSH_USER="root";
SSH_BITS="1024";
SSH_ID="id_rsa";
SSH_GEN_KEYS=0;
SSH_COUNT=0;
START_ORACHK=0;

# set TFAPATCHING to sto pthe 180 day warning when in patch.
TFA_SUPPRESS_AGE_WARN=TRUE
export TFA_SUPPRESS_AGE_WARN

# Function to generate keys
generateKeys() {

	# Remove Private Key
	if [ -f "$HOME/.ssh/$SSH_ID" ]
	then
		$RM -f $HOME/.ssh/$SSH_ID;
	fi

	# Remove Public Key
	if [ -f "$HOME/.ssh/$SSH_ID.pub" ]
	then
		$RM -f $HOME/.ssh/$SSH_ID.pub;
	fi

	if [ ! -d "$HOME/.ssh" ]
	then
		$MKDIR -p $HOME/.ssh;
	fi

	# Generate Keys
	$ECHO "Generating keys on $HOSTNAME...";
	$SSH_KEYGEN -t $SSH_ENCR -b $SSH_BITS -f $HOME/.ssh/$SSH_ID -N '' > /dev/null;
	SSH_GEN_KEYS=1;
}

# Function to configure SSH setup
configureSSH() {
	REMOTE_HOST=$1;

	# Generate keys only if not present
	if [ ! -f "$HOME/.ssh/$SSH_ID" ]
	then
		generateKeys;
		$ECHO "";
	fi

	# Copy keys to remote node
	$ECHO "Copying keys to $REMOTE_HOST...";
	$ECHO "";

	if [ -f "$SSH_COPY_ID" ]
	then
		$SSH_COPY_ID $SSH_USER@$REMOTE_HOST > /dev/null;
	else 
		$CAT $HOME/.ssh/$SSH_ID.pub | $SSH $SSH_USER@$REMOTE_HOST "$MKDIR -p $HOME/.ssh && $CAT >> $HOME/.ssh/authorized_keys";
	fi
}

removeSSH() {
	REMOTE_HOST=$1;
	$SSH $SSH_USER@$REMOTE_HOST "$SED '/'$SSH_USER'@'$HOSTNAME'/d' $HOME/.ssh/authorized_keys > $HOME/.ssh/authorized_keys.tmp ; $MV -f $HOME/.ssh/authorized_keys.tmp $HOME/.ssh/authorized_keys";
	$ECHO "Removed SSH configuration on $REMOTE_HOST...";
}

# Orachk Autostart
orachk_autostart() {
	if [ "$RUID" -eq "0" ]
	then 
		if [ ! -n "$TFA_SKIP_ORACHK" ]
		then
			START_ORACHK=1;
		fi
	fi
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
	GREP=/usr/xpg4/bin/grep
        ;;
HP-UX)
        ID=/sbin/init.d
        ;;
*)     $ECHO "ERROR: Unknown Operating System"
       exit -1
       ;;
esac

SILENT=0
LOCAL=0

while [ $# -gt 0 ]
do
  case $1 in
    -silent)  SILENT=1;;         # silent is set to true
    -local)   LOCAL=1;;		 # Patch only on Local Node
  esac;
  shift
done

sleepdots() {
	sleeptime=$1
	count=0

	while [ $count -lt $sleeptime ]
	do
      		printf ". "
		$SLEEP 1
		count=`expr $count + 1`
	done
	printf "\n"
}

$ECHO "";

RUID=`$ID_CMD | $AWK -F\( '{print $1}' | $AWK -F= '{print $2}'`;

if [ ! -r "$ID/init.tfa" ]
then
	$ECHO "TFA is not setup. Unable to find $ID/init.tfa";
	exit;
fi

RUSER=`$ID_CMD | $AWK '{print $1}' | $AWK -F\( '{print $2}' | $AWK -F\) '{print $1}'`;

tfa_home=`$GREP '^export TFA_HOME=' $ID/init.tfa | $AWK -F"=" '{print $2}'`

if [ ! -n "$tfa_home" ]
then
	tfa_home=`$GREP '^TFA_HOME=' $ID/init.tfa | $AWK -F"=" '{print $2}'`
fi

if [ ! -f "$PERL" ] && [ -f "$tfa_home/tfa_setup.txt" ]
then
	TFA_PERL=`$GREP '^PERL=' $tfa_home/tfa_setup.txt | $AWK -F"=" '{print $2}'`;

	if [ -f "$TFA_PERL" ]
	then
		PERL="$TFA_PERL";
	else
		CRS_HOME=`$GREP '^CRS_HOME=' $tfa_home/tfa_setup.txt | $AWK -F"=" '{print $2}'`;

		if [ -d "$CRS_HOME" ]
		then
			PERL="$CRS_HOME/perl/bin/perl";
		fi
	fi
fi

HOSTNAME=`hostname | $CUT -d. -f1 | $PERL -ne 'print lc'`;

tfabase=`$ECHO $tfa_home | $SED -e "s/\/[^\/]*$//"`

#Check if TFA HOME contains HOSTNAME
if [ `$ECHO $tfa_home | $GREP -ic "$HOSTNAME"` -ge "1" ]
then
	tfabase=`$ECHO $tfabase | sed -e "s/\/[^\/]*$//"`
fi

e_tfabase=`pwd`

# If its a local patch then don't check the status of TFA in other nodes.

if [ "$LOCAL" -eq "0" ]
then
	tfahosts=`$tfa_home/bin/tfactl print hosts | $GREP "Host Name " | $AWK '{print $NF}' | $GREP -v "^$HOSTNAME$"`
	host_count=`$tfa_home/bin/tfactl print hosts | $GREP "Host Name :" | $GREP -v grep | wc -l`

	if [ "$host_count" -eq "0" ]
	then
		$ECHO "Unable to determine the status of TFA in other nodes."
		LOCAL=1;
	fi

	# If TFA is installed only on one Node then do local patch.
	if [ "$host_count" -eq "1" ]
	then
		LOCAL=1;
	fi
fi

if [ $LOCAL -eq 1 ]
then
	$ECHO "TFA will be Patched on Node $HOSTNAME:"
else
	$ECHO "TFA will be Patched on: "
	$ECHO "$HOSTNAME"
	$ECHO "$tfahosts"
fi

$ECHO "";

if [ $SILENT -eq "0" ]
then
	printf "Do you want to continue with patching TFA? [Y|N] [Y]: ";
	read userinput;

        if [ "$userinput" = "n" ] || [ "$userinput" = "N" ]
        then
		$ECHO "";
                $ECHO "Exiting from TFA Patching now.";
                exit 2;
        fi
	$ECHO "";
fi

orachk_autostart;

INSTALLED_BUILD=0;
INSTALLED_BLDDT=0;
INSTALLED_BLDVR=0;

if [ -f "$tfa_home/internal/.buildid" ]
then
	INSTALLED_BUILD=`$CAT $tfa_home/internal/.buildid`;

	# Extract Installed Build Version and Date
	INSTALLED_BLDDT=`$ECHO $INSTALLED_BUILD | $TAIL -15c`;
	INSTALLED_BLDVR=`$ECHO $INSTALLED_BUILD | $SED "s/$INSTALLED_BLDDT//"`;

	# Get Build Version from .buildversion
	if [ -f "$tfa_home/internal/.buildversion" ]
	then
		INSTALLED_BLDVR=`$CAT $tfa_home/internal/.buildversion`;
	fi

	# If Installed version is null then set it to 0
	if [ ! -n "$INSTALLED_BLDVR" ]
	then
		INSTALLED_BLDVR=0;
	fi
fi

ssh_list="tfa_ssh_patch_list";
nonssh_list="tfa_non_ssh_patch_list";
socket_list="tfa_socket_patch_list";

if [ -f "$ssh_list" ]
then
	$RM -f $ssh_list;
fi

if [ -f "$nonssh_list" ] 
then
	$RM -f $nonssh_list;
fi

if [ -f "$socket_list" ]
then
	$RM -f $socket_list;
fi

if [ "$LOCAL" -eq "0" ]
then
	PING="/usr/sbin/ping";
	if [ $PLATFORM = "Linux" ]
	then
		PING="/bin/ping";
	fi

	for host in $tfahosts
	do
		$ECHO "";

		if [ $PLATFORM = "SunOS" ]
		then
			$PING -s $host 5 5 > /dev/null 2>&1
		elif [ $PLATFORM = "HP-UX" ]
		then
			$PING $host -n 5 -m 5 > /dev/null 2>&1
		else
			$PING -c 1 -w 5 $host > /dev/null 2>&1
		fi

		PING_STATUS=$?

		if [ $PING_STATUS -ne 0 ]
		then
			$ECHO "Unable to ping Host $host. Please run local upgrade later.";
			continue;
		fi

		$ECHO "Checking for ssh equivalency in $host"

		if [ $host != $HOSTNAME ]
		then
			$SSH -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -l $SSH_USER $host ls 2>/dev/null 1>/dev/null
	           	ssh_status=$?
		   	#echo "SSH setup status for $host : $ssh_setup_status"

	           	if [ "$ssh_status" -eq "0" ]
        	   	then
                		$ECHO "$host is configured for ssh user equivalency for $SSH_USER user";
				$ECHO "$host" >> $ssh_list;
	           	else	
        	        	$ECHO "Node $host is not configured for ssh user equivalency";

				if [ "$INSTALLED_BLDVR" -le "121241" ]
				then
					keystoresupdated=`$PERL $tfa_home/bin/tfactl.pl checkkeystores | $GREP $host | $AWK '{print $4}'`

					if [ "$keystoresupdated" = "ON" ]
					then
						$ECHO "Key Stores are already updated in $host"
						$ECHO "$host" >> $socket_list;
					else
						$ECHO "$host" >> $nonssh_list;
					fi
				else
					$ECHO "$host" >> $nonssh_list;
				fi
			fi
		fi
	done
	$ECHO "";
fi #LOCAL IF

# SSH Setup
if [ "$LOCAL" -eq "0" ] && [ $SILENT -eq "0" ] && [ -s "$nonssh_list" ]
then
	$ECHO "SSH is not configured on these nodes : ";
	$CAT $nonssh_list;
	$ECHO "";
	printf "Do you want to configure SSH on these nodes ? [Y|N] [Y]: ";
	read userinput;

	if [ "$userinput" != "n" ] && [ "$userinput" != "N" ]
	then
		for host in `$CAT $nonssh_list`
		do
			$ECHO "";
			$ECHO "Configuring SSH on $host...";
			$ECHO "";
			configureSSH $host;
			rmsshlist="$rmsshlist $host";
			$ECHO "$host" >> $ssh_list;
		done

		# Remove Non-SSH List
		$RM -f $nonssh_list;
	else
		$ECHO "";
		# Use TFA Installer to patch remote nodes
		if [ -n "$TFA_INSTALLER" ]
		then
			$ECHO "Patching remote nodes using TFA Installer $TFA_INSTALLER...";
		else
			$ECHO "Patching only on local node...";
			LOCAL=1;
			$RM -f $nonssh_list;
		fi
	fi
	$ECHO "";
fi

# Update RATFA.jar for socket patching

if [ "$LOCAL" -eq "0" ] && [ "$INSTALLED_BLDVR" -eq "121200" ] && [ -s "$socket_list" ]
then
        # Stop tools first
        $ECHO "Stopping TFA Support Tools...";
        $tfa_home/bin/tfactl stop_suptools > /dev/null 2>&1
        $ECHO "";

	# Stop TFA
	if [ `ps -ef | $GREP $ID/init.tfa | $GREP -v grep | wc -l` -ge 1 ]
	then
		$ECHO "Shutting down TFA in $HOSTNAME...";
		$ECHO "";
		$ID/init.tfa shutdown
		$ECHO "";
	fi

	# Copy TFA 12102 Updated Jar
	$ECHO "Updating TFA Jars...";
	$CP -f $e_tfabase/tfa_home/jlib/RATFA_12102.jar $tfa_home/jlib/RATFA.jar > /dev/null 2>&1;

	# Start TFA
	$ECHO "";
	$ECHO "Starting TFA in $HOSTNAME...";
	$ECHO "";
	$ID/init.tfa start
	$ECHO "";
fi

# Get the TFA BDB 
BDB_DIR="$tfa_home/database";
INSTALL_TYPE="TYPICAL";

if [ -f "$tfa_home/tfa_setup.txt" ]
then
	CRS_HOME=`$GREP '^CRS_HOME=' $tfa_home/tfa_setup.txt | $AWK -F"=" '{print $2}'`;
	ORACLE_BASE=`$GREP '^ORACLE_BASE=' $tfa_home/tfa_setup.txt | $AWK -F"=" '{print $2}'`;

	if [ -n "$CRS_HOME" ]
	then
		#Check if TFA_HOME is under CRS_HOME [ GI Install ]
		if [ `$ECHO $tfa_home | $GREP -c "$CRS_HOME"` -eq 1 ]
		then
			INSTALL_TYPE="GI";

			if [ -n "$ORACLE_BASE" ]
			then
				BDB_DIR="$ORACLE_BASE/tfa/$HOSTNAME/database";
				LOG_DIR="$ORACLE_BASE/tfa/$HOSTNAME/log";
			fi
		fi
	fi
fi

if [ -d "$BDB_DIR" ]
then
	BDB_HOME="$BDB_DIR/BERKELEY_JE_DB/";
fi

# Copy JRE from zip
if [ -d "$e_tfabase/tfa_home/jre" ]
then
	$CP -rf $e_tfabase/tfa_home/jre $tfa_home/;
	$PERL -p -i -e "s{^JAVA_HOME=.*}{JAVA_HOME=$tfa_home/jre}g" $tfa_home/tfa_setup.txt;
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
		#Get JAVA_HOME from TFA_BASE/java_install.out
		if [ -f "$tfabase/$HOSTNAME/java_install.out" ]
		then
			TFA_JHOME=`$GREP '^JAVA_HOME=' $tfabase/$HOSTNAME/java_install.out | $AWK -F"=" '{print $2}'`;
		fi
	fi
fi

# Check MD5withRSA Signature in TFA Certificates
if [ -f "$tfa_home/server.jks" ]
then
	KEYTOOL="$TFA_JHOME/bin/keytool";
	if [ -x "$KEYTOOL" ]
	then
		if [ -s "$tfa_home/internal/port.txt" ]
		then
			PORT=`$CAT $tfa_home/internal/port.txt`;

			if [ `$KEYTOOL -printcert -sslserver $HOSTNAME:$PORT | $GREP -i "Signature algorithm" | $GREP -ic "MD5withRSA"` -eq 1 ]
			then
				# Exit TFA Patch if User Generated Certificates
				if [ -f "$tfa_home/internal/ssl.properties" ]
				then
					if [ `$GREP -ic "^userCert=1" $tfa_home/internal/ssl.properties` -eq 1 ]
					then
						$ECHO "TFA-00075: Invalid User Certificates as it uses MD5withRSA Signature. Exiting from TFA Patching now.";
						$ECHO "1" > /tmp/.tfa.patch;
						exit 0;
					fi
				fi

				RM_TFA_CERTIFICATES="1";
			fi
		fi
	fi
fi

# Remove TFA Certificates
if [ -n "$RM_TFA_CERTIFICATES" ] && [ "$RM_TFA_CERTIFICATES" -eq "1" ]
then
        # Shutdown TFA if its running:
        if [ `ps -ef | $GREP $ID/init.tfa | $GREP -v grep | wc -l` -ge 1 ]
        then
                # Stop tools first
                $ECHO "Stopping TFA Support Tools..."; 
                $tfa_home/bin/tfactl stop_suptools > /dev/null 2>&1

                $ECHO "";
                $ECHO "Shutting down TFA for Patching...";
                $ECHO "";
                $ID/init.tfa shutdown
                $ECHO "";
        fi

        if [ -f "$tfa_home/server.jks" ]
        then
                $ECHO "Moving existing TFA Certificates due to MD5withRSA Signature...";
                $MV -f $tfa_home/server.jks $tfa_home/server.jks.patch;
        fi

        if [ -f "$tfa_home/client.jks" ]
        then
                $MV -f $tfa_home/client.jks $tfa_home/client.jks.patch;
        fi

        if [ -f "$tfa_home/internal/ssl.properties" ]
        then
                $MV -f $tfa_home/internal/ssl.properties $tfa_home/internal/ssl.properties.patch;
        fi
fi

if [ -d "$TFA_JHOME" ]
then
	JAVA="$TFA_JHOME/bin/java";
fi

if [ ! -f "$tfa_home/server.jks" ] 
then
	if [ `$ECHO $INSTALL_TYPE | $GREP -c "GI"` -eq 1 ] 
	then 
		if [ $LOCAL -eq 0 ]
		then
			temp_tfahome="$e_tfabase/tfa_home";
			$PERL $e_tfabase/tfa_home/bin/tfactl.pl generatecerts $temp_tfahome $TFA_JHOME 1;
		fi
	else
		temp_tfahome="$e_tfabase/tfa_home";
                $PERL $e_tfabase/tfa_home/bin/tfactl.pl generatecerts $temp_tfahome $TFA_JHOME 1;   
	fi
fi

#Generate R certs if GI/Non-GI clusterwide upgrade from <18.1 to >=18.1
RUN_MODE=`$GREP '^RUN_MODE=' $tfa_home/tfa_setup.txt | $AWK -F"=" '{print $2}'`
if [ "$RUN_MODE" = "receiver" ] && [ ! -f "$tfa_home/receiver/receiver.jks" ]; then
  cert_home="$e_tfabase/tfa_home/receiver";
  if [ `$ECHO $INSTALL_TYPE | $GREP -c "GI"` -eq 1 ]; then
    if [ $LOCAL -eq 0 ]; then
      $PERL $e_tfabase/tfa_home/bin/tfactl.pl generatecerts $cert_home $TFA_JHOME receiver;
    fi
    #Incase of GI local upgrade let Secure TFA JAVA thread generate and sync certs
  else
    $PERL $e_tfabase/tfa_home/bin/tfactl.pl generatecerts $cert_home $TFA_JHOME receiver;
  fi
fi

# Create zip or tar if not local
if [ "$LOCAL" -eq "0" ]
then
	ZIPSTATUS=0;
	ZIPHELP=`$ZIP -h > /dev/null 2>&1; echo $?`;
	TARSTATUS=0;

	#Check if machine has zip or tar:
	if [ "$ZIPHELP" -eq "0" ]
	then
		ZIPSTATUS=1;
	elif [ -f "$TAR" ]
	then
		TARSTATUS=1;
	else
		$ECHO "Unable to find ZIP or TAR on this System. Running local patch...";
		LOCAL=1;
	fi

	if [ "$ZIPSTATUS" -eq "1" ]
	then
		zipfile="$tfa_home/internal/tfapatch.zip";
		#$ECHO "Creating ZIP: $zipfile";
		$ZIP -r -q $zipfile $e_tfabase/tfa_home/jlib $e_tfabase/tfa_home/bin $e_tfabase/tfa_home/resources $e_tfabase/tfa_home/ext $e_tfabase/tfa_home/install $e_tfabase/tfa_home/internal/usableports.txt $e_tfabase/tfa_home/internal/.buildid $e_tfabase/tfa_home/internal/.buildversion $e_tfabase/tfa_home/internal/config.properties $e_tfabase/tfa_home/tfa.jks $e_tfabase/tfa_home/public.jks $e_tfabase/tfa_home/server.jks $e_tfabase/tfa_home/client.jks $e_tfabase/tfa_home/internal/ssl.properties $e_tfabase/tfa_home/internal/rconfig.properties $e_tfabase/tfa_home/tfa_directories.txt $e_tfabase/tfa_home/receiver $e_tfabase/tfa_home/tomcat $e_tfabase/tfa_home/receiver/receiver.jks $e_tfabase/tfa_home/receiver/internal/r.ssl.properties $e_tfabase/tfa_home/internal/timezones_mapping $e_tfabase/tfa_home/internal/smtp.properties $e_tfabase/tfa_home/internal/dbversions.json
	fi

	if [ "$TARSTATUS" -eq "1" ]
	then
		tarfile="$tfa_home/internal/tfapatch.tar";
		$ECHO "Creating TAR: $tarfile"
		$TAR -cf $tarfile $e_tfabase/tfa_home/jlib $e_tfabase/tfa_home/bin $e_tfabase/tfa_home/resources $e_tfabase/tfa_home/ext $e_tfabase/tfa_home/install $e_tfabase/tfa_home/internal/usableports.txt $e_tfabase/tfa_home/internal/.buildid $e_tfabase/tfa_home/internal/.buildversion $e_tfabase/tfa_home/internal/config.properties $e_tfabase/tfa_home/tfa.jks $e_tfabase/tfa_home/public.jks $e_tfabase/tfa_home/server.jks $e_tfabase/tfa_home/client.jks $e_tfabase/tfa_home/internal/ssl.properties $e_tfabase/tfa_home/internal/rconfig.properties $e_tfabase/tfa_home/tfa_directories.txt $e_tfabase/tfa_home/receiver $e_tfabase/tfa_home/tomcat $e_tfabase/tfa_home/receiver/receiver.jks $e_tfabase/tfa_home/receiver/internal/r.ssl.properties $e_tfabase/tfa_home/internal/timezones_mapping $e_tfabase/tfa_home/internal/smtp.properties $e_tfabase/tfa_home/internal/dbversions.json 
	fi
fi

# If SSH equivalency present then we use SSH to patch TFA to remote nodes.

if [ "$LOCAL" -eq "0" ] && [ -s "$ssh_list" ]
then
	$ECHO "";
	#echo -e "\nSSH equivalency is present. Using SSH to patch TFA to remote nodes"
	echo "Using SSH to patch TFA to remote nodes :";

	for host in `$CAT $ssh_list`
	do
		echo "";
		echo "Applying Patch on $host:";
		echo "";

		TFA_HOME=$tfa_home

		# if tfa_home in local host contains hostname, then the tfa_home in 
		# remote node will also contain hostname

		if [ `echo $tfa_home | $GREP -ic "/tfa/$HOSTNAME/tfa_home"` -ge "1" ]
		then
			TFA_HOME=$tfabase/$host/tfa_home;
			echo "TFA_HOME: $TFA_HOME";
		fi

		# Stop TFA Tools first
		$ECHO "Stopping TFA Support Tools...";
		$SSH $host "$TFA_HOME/bin/tfactl stop_suptools > /dev/null 2>&1"

		$SSH $host $TFA_HOME/bin/tfactl stoporachkdaemon & > /dev/null 2>&1;

		$SSH $host "$ID/init.tfa shutdown"
		echo "Copying files from $HOSTNAME to $host..."

		#TFA BDB on Remote Node:

		if [ `echo $BDB_HOME | $GREP -ic "/tfa/$HOSTNAME"` -ge "1" ]
		then
			REMOTE_BDB_HOME=`echo $BDB_HOME | $SED 's%/tfa/'$HOSTNAME'/%/tfa/'$host'/%'`;
		fi

		if [ -d "$e_tfabase/tfa_home/jre" ]
		then
			$SCP -r $e_tfabase/tfa_home/jre $host:$TFA_HOME/;
			$SSH $host "$PERL -p -i -e \"s{^JAVA_HOME=.*}{JAVA_HOME=$TFA_HOME/jre}g\" $TFA_HOME/tfa_setup.txt";
		fi

		#TFA JAVA on Remote Node:
		if [ `echo $TFA_JHOME | $GREP -ic "$HOSTNAME"` -ge "1" ]
		then
			REM_JHOME=`$ECHO $TFA_JHOME | $SED 's%/'$HOSTNAME'/%/'$host'/%'`;
			JAVA="$REM_JHOME/bin/java";
		fi

		#echo "REMOTE_BDB_HOME: $REMOTE_BDB_HOME";
		#echo "JAVA: $JAVA";

		# Changes for Patching 11204 to 12c in Remote Node using SSH
		REM_JAR_DIR="$TFA_HOME/jar";
		REM_JLIB_DIR="$TFA_HOME/jlib";
		REM_OB_OUT_DIR="$ORACLE_BASE/tfa/$host/";
		REM_TFA_OUT_DIR="$TFA_HOME/output/";

		$SSH $host "if [ -d \"$REM_JAR_DIR\" ]; then $ECHO \"Renaming $REM_JAR_DIR to $REM_JLIB_DIR on $host\"; $MV -f $REM_JAR_DIR $REM_JLIB_DIR; $ECHO \"Adding INSTALL_TYPE = $INSTALL_TYPE to tfa_setup.txt on $host\"; $ECHO \"INSTALL_TYPE=$INSTALL_TYPE\" >> $TFA_HOME/tfa_setup.txt; if [ \`$ECHO $INSTALL_TYPE | $GREP -c \"GI\"\` -eq 1 ]; then $ECHO \"Copying $REM_TFA_OUT_DIR to $REM_OB_OUT_DIR on $host\"; $CP -rf $REM_TFA_OUT_DIR $REM_OB_OUT_DIR; fi; fi";

		$ECHO "";

		$SSH $host "if [ \`$GREP -c \"^PERL=\" $TFA_HOME/tfa_setup.txt\` -eq \"0\" ]; then $ECHO \"PERL=$PERL\" >> $TFA_HOME/tfa_setup.txt; fi";
		$SSH $host "if [ -n \"$TZ\" ] && [ \`$GREP -c \"^TZ=\" $TFA_HOME/tfa_setup.txt\` -eq \"0\" ]; then $ECHO \"TZ=$TZ\" >> $TFA_HOME/tfa_setup.txt; fi";
		$SSH $host "if [ \`$GREP -c \"^DAEMON_OWNER=\" $TFA_HOME/tfa_setup.txt\` -eq \"0\" ]; then $ECHO \"DAEMON_OWNER=$RUSER\" >> $TFA_HOME/tfa_setup.txt; fi";

		$SCP $e_tfabase/tfa_home/jlib/RATFA.jar $host:$TFA_HOME/jlib/RATFA.jar
		$SCP $e_tfabase/tfa_home/jlib/je-*.jar $host:$TFA_HOME/jlib/
		$SCP $e_tfabase/tfa_home/jlib/commons-io-2.6.jar $host:/$TFA_HOME/jlib/
		$SCP $e_tfabase/tfa_home/jlib/oraclepki.jar $host:/$TFA_HOME/jlib/
		$SCP $e_tfabase/tfa_home/jlib/ojmisc.jar $host:/$TFA_HOME/jlib/
		$SCP $e_tfabase/tfa_home/jlib/ojpse.jar $host:/$TFA_HOME/jlib/
		$SCP $e_tfabase/tfa_home/jlib/osdt_cert.jar $host:/$TFA_HOME/jlib/
		$SCP $e_tfabase/tfa_home/jlib/osdt_core.jar $host:/$TFA_HOME/jlib/
		$SCP $e_tfabase/tfa_home/jlib/owm-3_0.jar $host:/$TFA_HOME/jlib/
		$SCP $e_tfabase/tfa_home/jlib/tfarest.jar $host:/$TFA_HOME/jlib/
		$SCP $e_tfabase/tfa_home/jlib/jackson-*.jar $host:/$TFA_HOME/jlib/
		$SCP $e_tfabase/tfa_home/jlib/log4j-*.jar $host:/$TFA_HOME/jlib/
		$SCP -r $e_tfabase/tfa_home/bin/* $host:$TFA_HOME/bin/.
		$SCP -r $e_tfabase/tfa_home/resources/* $host:$TFA_HOME/resources/.
		$SCP -r $e_tfabase/tfa_home/ext/ $host:$TFA_HOME/.
		$SCP -r $e_tfabase/tfa_home/install/* $host:$TFA_HOME/install/.
		$SCP $e_tfabase/tfa_home/internal/usableports.txt $host:$TFA_HOME/internal
		$SCP $e_tfabase/tfa_home/internal/config.properties $host:$TFA_HOME/internal/config.properties.patch
		$SCP -p $e_tfabase/tfa_home/internal/smtp.properties $host:$TFA_HOME/internal/smtp.properties.patch
		$SCP $e_tfabase/tfa_home/internal/timezones_mapping $host:$TFA_HOME/internal/timezones_mapping.patch
		$SCP $e_tfabase/tfa_home/internal/dbversions.json $host:$TFA_HOME/internal
		$SCP $e_tfabase/tfa_home/tfa.jks $host:$TFA_HOME/
		$SCP $e_tfabase/tfa_home/public.jks $host:$TFA_HOME/
                # From TFA 18.2 We need Lucene jars for all TFA.
		$SCP $e_tfabase/tfa_home/jlib/lucene*.jar $host:$TFA_HOME/jlib/
		$SCP $e_tfabase/tfa_home/jlib/javax.json-1.0.4.jar $host:$TFA_HOME/jlib/
		
  		#Updates from 12.2.0.1.0(TFAV-12.2.1.1.0) to 18.1(TFAV-181000) 
		if [ "$INSTALLED_BLDVR" -le "181000" ]; then
                  if [ -d $e_tfabase/tfa_home/tomcat ]; then
		     $SCP -r $e_tfabase/tfa_home/receiver $host:$TFA_HOME/
		     $SCP -r $e_tfabase/tfa_home/tomcat $host:$TFA_HOME/
                  fi
		fi
		
                if [ ! -f "$tfa_home/receiver/receiver.jks" ]; then
                  if [ -f $e_tfabase/tfa_home/receiver/receiver.jks ]; then
                    $SCP $e_tfabase/tfa_home/receiver/receiver.jks $host:$TFA_HOME/receiver/
                  fi
                  if [ -f $e_tfabase/tfa_home/receiver/internal/r.ssl.properties ]; then
                    $SCP $e_tfabase/tfa_home/receiver/internal/r.ssl.properties $host:$TFA_HOME/receiver/internal/
                  fi
                fi

		if [ ! -f "$tfa_home/server.jks" ]
		then
			$SCP $e_tfabase/tfa_home/server.jks $host:$TFA_HOME/
                	$SCP $e_tfabase/tfa_home/client.jks $host:$TFA_HOME/
			$SCP $e_tfabase/tfa_home/internal/ssl.properties $host:$TFA_HOME/internal
		fi
		
		$SCP $e_tfabase/tfa_home/tfa_directories.txt $host:$TFA_HOME/tfa_directories.txt.bkp 
		$SSH $host "if [ ! -d \"$TFA_HOME/internal/scripts\" ] ; then mkdir $TFA_HOME/internal/scripts; fi";
  
		$SSH $host "if [ -s \"$TFA_HOME/jlib/je-4.0.103.jar\" ]; then echo \"Current version of Berkeley DB is 4.0.103 in $host\"; echo \"Running DbPreUpgrade_4_1 utility\"; output=\`$JAVA -jar $TFA_HOME/jlib/je-4.1.27.jar DbPreUpgrade_4_1 -h $REMOTE_BDB_HOME 2>&1\`; echo \"Output of upgrade : \$output\"; else echo \"Current version of Berkeley DB in $host is 5 or higher, so no DbPreUpgrade required\"; fi"
                $SSH $host "$PERL $TFA_HOME/bin/tfactl.pl updateciphersuite"
		$SSH $host "$PERL $TFA_HOME/bin/tfactl.pl updatepropertiesfile"
		$SSH $host "$PERL $TFA_HOME/bin/tfactl.pl updatedirectoriesfile"
                $SSH $host "$PERL $TFA_HOME/bin/tfactl.pl updateautodiagcollect"
		$SCP $e_tfabase/tfa_home/internal/.buildid $host:$TFA_HOME/internal/.buildid.bkp
		$SCP $e_tfabase/tfa_home/internal/.buildversion $host:$TFA_HOME/internal/.buildversion.bkp
		echo "Running commands to fix init.tfa and tfactl in $host..."
		$SSH $host "$PERL $TFA_HOME/bin/tfactl.pl fixInitTfa"
		$SSH $host "$PERL $TFA_HOME/bin/tfactl.pl fixTfactl"
		$SSH $host "$PERL $TFA_HOME/bin/tfactl.pl copytfactl"
                #If this is Exadata then make orachk -> exachk
                if [ -f "/etc/oracle/cell/network-config/cellip.ora" ]
                then
                  $SSH $host "$CP $TFA_HOME/ext/orachk/orachk.pyc $TFA_HOME/ext/orachk/exachk.pyc"
                  $SSH $host "$CP $TFA_HOME/ext/orachk/orachk $TFA_HOME/ext/orachk/exachk"
                fi
		$SSH $host "chmod a+x $TFA_HOME/ext $TFA_HOME/ext/oratop $TFA_HOME/ext/oratop/* 2>/dev/null"
		echo "Updating init.tfa in $host..."
		$SSH $host "$CP -f $TFA_HOME/install/init.tfa $ID/init.tfa"
		$SSH $host "$RM -f $TFA_HOME/install/inittab"
		$SSH $host "$RM -f $TFA_HOME/internal/rconfig.properties"
                
                
		echo "Removing old version serializale files in $host..."
		$SSH $host "$RM -f $TFA_HOME/internal/*.ser"
		
		echo "Starting TFA in $host..."
		$SSH $host "$ID/init.tfa start"
		$SSH $host "if [ -f \"$TFA_HOME/jlib/lucene-core-6.1.0.jar\" ] ; then \`rm -f $TFA_HOME/jlib/lucene-*-6.1.0.jar 2>&1\`; fi"
		$SSH $host "if [ -f \"$TFA_HOME/jlib/jackson-core-2.9.4.jar\" ] ; then \`rm -f $TFA_HOME/jlib/jackson-core-2.9.4.jar 2>&1\`; fi"
		$SSH $host "if [ -f \"$TFA_HOME/jlib/jackson-databind-2.9.5.jar\" ] ; then \`rm -f $TFA_HOME/jlib/jackson-databind-2.9.5.jar 2>&1\`; fi"
		$SSH $host "if [ -f \"$TFA_HOME/jlib/jackson-annotations-2.9.4.jar\" ] ; then \`rm -f $TFA_HOME/jlib/jackson-annotations-2.9.4.jar 2>&1\`; fi"
		$SSH $host "if [ -f \"$TFA_HOME/jlib/jackson-annotations-2.9.5.jar\" ] ; then \`rm -f $TFA_HOME/jlib/jackson-annotations-2.9.5.jar 2>&1\`; fi"
		$SSH $host "if [ -f \"$TFA_HOME/jlib/je-4.0.103.jar\" ] ; then echo \"Removing $TFA_HOME/jlib/je-4.0.103.jar\"; \`rm -f $TFA_HOME/jlib/je-4.0.103.jar 2>&1\`; fi"
		$SSH $host "if [ -f \"$TFA_HOME/jlib/je-5.0.84.jar\" ] ; then echo \"Removing $TFA_HOME/jlib/je-5.0.84.jar\"; \`rm -f $TFA_HOME/jlib/je-5.0.84.jar 2>&1\`; fi"
		$SSH $host "if [ -f \"$TFA_HOME/jlib/commons-io-2.1.jar\" ] ; then echo \"Removing $TFA_HOME/jlib/commons-io-2.1.jar\"; \`rm -f $TFA_HOME/jlib/commons-io-2.1.jar 2>&1\`; fi"
		$SSH $host "if [ -f \"$TFA_HOME/jlib/commons-io-2.5.jar\" ] ; then echo \"Removing $TFA_HOME/jlib/commons-io-2.5.jar\"; \`rm -f $TFA_HOME/jlib/commons-io-2.5.jar 2>&1\`; fi"
		$SSH $host "if [ -d \"$TFA_HOME/jre1.6.0_18\" ] ; then echo \"Removing $TFA_HOME/jre1.6.0_18\"; \`rm -rf $TFA_HOME/jre1.6.0_18 2>&1\`; fi"
		$SSH $host "$TFA_HOME/bin/tfactl access setuptracedir -user root";
		$SSH $host "$TFA_HOME/bin/tfactl access update -local";
		$SSH $host "if [ ! -f \"$TFA_HOME/.$host.shared\" ]; then $TFA_HOME/bin/tfactl access enable -local; $TFA_HOME/bin/tfactl access adddefaultusers -local; $TOUCH $TFA_HOME/.$host.shared; fi";

		if [ "$START_ORACHK" -eq "1" ]
		then
			$SSH $host $TFA_HOME/bin/tfactl startorachkdaemon & > /dev/null 2>&1;
		fi

		echo "";
	done
fi

# If SSH equivalency is not present and autoPatchingEnabled=true, we use Secure 
# Sockets to patch to remote nodes.
# Stop and delete tfa_home on remote hosts
if [ "$LOCAL" -eq "0" ] && [ "$INSTALLED_BLDVR" -le "121241" ] && [ -s "$socket_list" ]
then
	for host in `$CAT $socket_list`
	do
		echo "";
		echo "Applying Patch on $host:";
		echo "";
		echo "Auto patching is enabled in $host. Patching TFA via Secure Sockets to $host."
		executeCmd="$PERL $tfa_home/bin/tfactl.pl executecommand $host"
		echo "";

		patchScript=$tfa_home/internal/patchScript.sh
		patchScriptWrapper=$tfa_home/internal/patchScriptWrap


		## if tfa_home of local host contains hostname, tfa_home in remote node
		## will also contain hostname.
		TFA_HOME=$tfa_home
		patchlog="$tfa_home/log/patchTFA.log"

		if [ `$ECHO $tfa_home | $GREP -ic "/tfa/$HOSTNAME/tfa_home"` -ge "1" ]
		then
			TFA_HOME=$tfabase/$host/tfa_home
			patchlog="$TFA_HOME/log/patchTFA.log"
			echo "TFA_HOME in $host : $TFA_HOME"
		fi

		if [ `$ECHO $INSTALL_TYPE | $GREP -c "^GI$"` -eq 1 ]
		then
			REM_LOG_DIR=`echo $LOG_DIR | $SED 's%/tfa/'$HOSTNAME'/%/tfa/'$host'/%'`;
			patchlog="$REM_LOG_DIR/patchTFA.log";
		fi

		#TFA BDB on Remote Node:
		if [ `echo $BDB_HOME | $GREP -ic "/tfa/$HOSTNAME"` -ge "1" ]
		then
			REMOTE_BDB_HOME=`echo $BDB_HOME | $SED 's%/tfa/'$HOSTNAME'/%/tfa/'$host'/%'`;
		fi

		#TFA JAVA on Remote Node:
		if [ `echo $TFA_JHOME | $GREP -ic "$HOSTNAME"` -ge "1" ]
		then
			REM_JHOME=`$ECHO $TFA_JHOME | $SED 's%/'$HOSTNAME'/%/'$host'/%'`;
			JAVA="$REM_JHOME/bin/java"
		fi

		#echo "REMOTE_BDB_HOME: $REMOTE_BDB_HOME";
		#echo "JAVA: $JAVA";
  
		echo "Creating patchScript in local host"
		echo "#!/bin/sh -x" > $patchScript
		echo "date >> $patchlog" >> $patchScript

		if [ "$ZIPSTATUS" -eq "1" ]
		then
			echo "echo \"Extracting $TFA_HOME/internal/tfapatch.zip to $TFA_HOME/internal/\" >> $patchlog" >> $patchScript
			echo "unzip -q $TFA_HOME/internal/tfapatch.zip -d $TFA_HOME/internal/" >> $patchScript
		else
			echo "echo \"Extracting $TFA_HOME/internal/tfapatch.tar to $TFA_HOME/internal/\" >> $patchlog" >> $patchScript
			echo "cd $TFA_HOME/internal ; tar -xf $TFA_HOME/internal/tfapatch.tar; cd -;" >> $patchScript
		fi

		REM_JAR_DIR="$TFA_HOME/jar";
		REM_JLIB_DIR="$TFA_HOME/jlib";
		REM_OB_OUT_DIR="$ORACLE_BASE/tfa/$host/";
		REM_TFA_OUT_DIR="$TFA_HOME/output/";

		echo "if [ -d \"$REM_JAR_DIR\" ]; then $ECHO \"Renaming $REM_JAR_DIR to $REM_JLIB_DIR on $host\" >> $patchlog; $MV -f $REM_JAR_DIR $REM_JLIB_DIR; $ECHO \"Adding INSTALL_TYPE = $INSTALL_TYPE to tfa_setup.txt on $host\" >> $patchlog; $ECHO \"INSTALL_TYPE=$INSTALL_TYPE\" >> $TFA_HOME/tfa_setup.txt; if [ \`$ECHO $INSTALL_TYPE | $GREP -c \"GI\"\` -eq 1 ]; then $ECHO \"Copying $REM_TFA_OUT_DIR to $REM_OB_OUT_DIR\ on $host\" >> $patchlog; $CP -rf $REM_TFA_OUT_DIR $REM_OB_OUT_DIR; fi; fi" >> $patchScript;

		echo "if [ \`$GREP -c \"^PERL=\" $TFA_HOME/tfa_setup.txt\` -eq \"0\" ]; then $ECHO \"PERL=$PERL\" >> $TFA_HOME/tfa_setup.txt; fi" >> $patchScript;
		echo "if [ -n \"$TZ\" ] && [ \`$GREP -c \"^TZ=\" $TFA_HOME/tfa_setup.txt\` -eq \"0\" ]; then $ECHO \"TZ=$TZ\" >> $TFA_HOME/tfa_setup.txt; fi" >> $patchScript;

		echo "echo \" Updating $TFA_HOME/jlib/RATFA.jar \" >> $patchlog" >> $patchScript
		echo "cp -f $TFA_HOME/internal$e_tfabase/tfa_home/jlib/RATFA.jar $TFA_HOME/jlib/RATFA.jar" >> $patchScript
		echo "echo \" Updating $TFA_HOME/jlib/commons-io-2.6.jar \" >> $patchlog" >> $patchScript
		echo "cp -f $TFA_HOME/internal$e_tfabase/tfa_home/jlib/commons-io-2.6.jar $TFA_HOME/jlib/commons-io-2.6.jar" >> $patchScript
		echo "echo \" Updating $TFA_HOME/jlib/oraclepki.jar \" >> $patchlog" >> $patchScript
		echo "cp -f $TFA_HOME/internal$e_tfabase/tfa_home/jlib/oraclepki.jar $TFA_HOME/jlib/oraclepki.jar" >> $patchScript
		echo "echo \" Updating $TFA_HOME/jlib/ojmisc.jar \" >> $patchlog" >> $patchScript
		echo "cp -f $TFA_HOME/internal$e_tfabase/tfa_home/jlib/ojmisc.jar $TFA_HOME/jlib/ojmisc.jar" >> $patchScript
		echo "echo \" Updating $TFA_HOME/jlib/ojpse.jar \" >> $patchlog" >> $patchScript
		echo "cp -f $TFA_HOME/internal$e_tfabase/tfa_home/jlib/ojpse.jar $TFA_HOME/jlib/ojpse.jar" >> $patchScript
		echo "echo \" Updating $TFA_HOME/jlib/osdt_cert.jar \" >> $patchlog" >> $patchScript
		echo "cp -f $TFA_HOME/internal$e_tfabase/tfa_home/jlib/osdt_cert.jar $TFA_HOME/jlib/osdt_cert.jar" >> $patchScript
		echo "echo \" Updating $TFA_HOME/jlib/osdt_core.jar \" >> $patchlog" >> $patchScript
		echo "cp -f $TFA_HOME/internal$e_tfabase/tfa_home/jlib/osdt_core.jar $TFA_HOME/jlib/osdt_core.jar" >> $patchScript
		echo "echo \" Updating $TFA_HOME/jlib/owm-3_0.jar \" >> $patchlog" >> $patchScript
		echo "cp -f $TFA_HOME/internal$e_tfabase/tfa_home/jlib/owm-3_0.jar $TFA_HOME/jlib/owm-3_0.jar" >> $patchScript
		echo "echo \" Copying BDB jar \" >> $patchlog" >> $patchScript
		echo "cp -f $TFA_HOME/internal$e_tfabase/tfa_home/jlib/je-*.jar $TFA_HOME/jlib/" >> $patchScript
		echo "echo \" Updating $TFA_HOME/bin \" >> $patchlog" >> $patchScript
		echo "cp -rf $TFA_HOME/internal$e_tfabase/tfa_home/bin/* $TFA_HOME/bin/." >> $patchScript
		echo "echo \" Updating $TFA_HOME/resources \" >> $patchlog" >> $patchScript
		echo "cp -rf $TFA_HOME/internal$e_tfabase/tfa_home/resources/* $TFA_HOME/resources/." >> $patchScript
		echo "echo \" Updating $TFA_HOME/ext \" >> $patchlog" >> $patchScript
		echo "cp -rf $TFA_HOME/internal$e_tfabase/tfa_home/ext/ $TFA_HOME/." >> $patchScript
		echo "echo \" Updating $TFA_HOME/install \" >> $patchlog" >> $patchScript
		echo "cp -rf $TFA_HOME/internal$e_tfabase/tfa_home/install/* $TFA_HOME/install/." >> $patchScript
		echo "echo \" Updating $TFA_HOME/internal/usableports.txt \" >> $patchlog" >> $patchScript
		echo "cp $TFA_HOME/internal$e_tfabase/tfa_home/internal/usableports.txt $TFA_HOME/internal/" >> $patchScript
		echo "echo \" Updating $TFA_HOME/tfa_directories.txt \" >> $patchlog" >> $patchScript
		echo "cp $TFA_HOME/internal$e_tfabase/tfa_home/tfa_directories.txt $TFA_HOME/tfa_directories.txt.bkp" >> $patchScript
		echo "echo \" Updating $TFA_HOME/internal/config.properties \" >> $patchlog" >> $patchScript
		echo "cp $TFA_HOME/internal$e_tfabase/tfa_home/internal/config.properties $TFA_HOME/internal/config.properties.patch" >> $patchScript
		echo "echo \" Updating $TFA_HOME/internal/timezones_mapping \" >> $patchlog" >> $patchScript
		echo "cp $TFA_HOME/internal$e_tfabase/tfa_home/internal/timezones_mapping $TFA_HOME/internal/timezones_mapping.patch" >> $patchScript
		echo "echo \" Updating $TFA_HOME/internal/dbversions.json \" >> $patchlog" >> $patchScript
		echo "cp $TFA_HOME/internal$e_tfabase/tfa_home/internal/dbversions.json $TFA_HOME/internal/" >> $patchScript
		echo "echo \" Updating $TFA_HOME/internal/rconfig.properties \" >> $patchlog" >> $patchScript
		echo "echo \" Removing old version serializale files \" >> $patchlog" >> $patchScript
		echo "rm -f $TFA_HOME/internal/*.ser" >> $patchScript
		#echo "echo \" Updating $TFA_HOME/internal/.buildid \" >> $patchlog" >> $patchScript
		#echo "cp $TFA_HOME/internal$e_tfabase/tfa_home/internal/.buildid $TFA_HOME/internal/" >> $patchScript
		echo "echo \" Updating TFA Certificates \" >> $patchlog" >> $patchScript
		echo "cp $TFA_HOME/internal$e_tfabase/tfa_home/tfa.jks $TFA_HOME/" >> $patchScript
		echo "cp $TFA_HOME/internal$e_tfabase/tfa_home/public.jks $TFA_HOME/" >> $patchScript
		if [ ! -f "$tfa_home/server.jks" ]
		then
			echo "cp $TFA_HOME/internal$e_tfabase/tfa_home/server.jks $TFA_HOME/" >> $patchScript
                	echo "cp $TFA_HOME/internal$e_tfabase/tfa_home/client.jks $TFA_HOME/" >> $patchScript
			echo "cp $TFA_HOME/internal$e_tfabase/tfa_home/internal/ssl.properties $TFA_HOME/internal/" >> $patchScript
		fi
		echo "if [ ! -d $TFA_HOME/internal/scripts ] ; then echo \" Creating $TFA_HOME/internal/scripts \" >> $patchlog; mkdir \"$TFA_HOME/internal/scripts\"; fi" >> $patchScript
		echo "if [ -s $TFA_HOME/jlib/je-4.0.103.jar ] ; then echo \" The current version of Berkeley DB is 4.0.103.\" >> $patchlog; echo \" Running DbPreUpgrade_4_1 utility\" >> $patchlog; output=\`$JAVA -jar $TFA_HOME/jlib/je-4.1.27.jar DbPreUpgrade_4_1 -h $REMOTE_BDB_HOME 2>&1\`; echo \" Output of upgrade : \$output\" >> $patchlog; else echo \" The current version of Berkeley DB is 5 or higher, so no DbPreUpgrade required.\" >> $patchlog; fi" >> $patchScript
                echo "$PERL $TFA_HOME/bin/tfactl.pl updateciphersuite" >> $patchScript
		echo "$PERL $TFA_HOME/bin/tfactl.pl updatepropertiesfile" >> $patchScript
		echo "$PERL $TFA_HOME/bin/tfactl.pl updatedirectoriesfile" >> $patchScript
                echo "$PERL $TFA_HOME/bin/tfactl.pl updateautodiagcollect" >> $patchScript
                echo "echo \" Updating $TFA_HOME/internal/.buildid \" >> $patchlog" >> $patchScript
                echo "cp -f $TFA_HOME/internal$e_tfabase/tfa_home/internal/.buildid $TFA_HOME/internal/.buildid.bkp" >> $patchScript
                echo "echo \" Updating $TFA_HOME/internal/.buildversion \" >> $patchlog" >> $patchScript
                echo "cp -f $TFA_HOME/internal$e_tfabase/tfa_home/internal/.buildversion $TFA_HOME/internal/.buildversion.bkp" >> $patchScript
		echo "echo \" Running fixTfactl and copying file\" >> $patchlog" >> $patchScript
		echo "$PERL $TFA_HOME/bin/tfactl.pl fixInitTfa" >> $patchScript
		echo "$PERL $TFA_HOME/bin/tfactl.pl fixTfactl" >> $patchScript
		echo "$PERL $TFA_HOME/bin/tfactl.pl copytfactl" >> $patchScript
                if [ -f "/etc/oracle/cell/network-config/cellip.ora" ]
                then
                  echo "echo \" Copying $TFA_HOME/ext/orachk to exachk on Exadata\" >> $patchlog" >> $patchScript
                  echo "$CP $TFA_HOME/ext/orachk/orachk.pyc $TFA_HOME/ext/orachk/exachk.pyc" >> $patchScript
                  echo "$CP $TFA_HOME/ext/orachk/orachk $TFA_HOME/ext/orachk/exachk" >> $patchScript
                fi
		echo "chmod a+x $TFA_HOME/ext $TFA_HOME/ext/oratop $TFA_HOME/ext/oratop/* 2>/dev/null" >> $patchScript

		echo "echo \" Updating $ID/init.tfa \" >> $patchlog" >> $patchScript
		echo "echo \"Deleting $TFA_HOME/internal/tfapatch.zip in $host\" >> $patchlog" >> $patchScript

		echo "if [ -f \"$TFA_HOME/jlib/je-4.0.103.jar\" ]; then echo \"Removing $TFA_HOME/jlib/je-4.0.103.jar\"; \`rm -f $TFA_HOME/jlib/je-4.0.103.jar 2>&1\`; fi" >> $patchScript
		echo "if [ -f \"$TFA_HOME/jlib/je-5.0.84.jar\" ]; then echo \"Removing $TFA_HOME/jlib/je-5.0.84.jar\"; \`rm -f $TFA_HOME/jlib/je-5.0.84.jar 2>&1\`; fi" >> $patchScript
		echo "$TFA_HOME/bin/tfactl access setuptracedir -user root;" >> $patchScript
		echo "$TFA_HOME/bin/tfactl access update -local;" >> $patchScript
		echo "if [ ! -f \"$TFA_HOME/.$host.shared\" ]; then $TFA_HOME/bin/tfactl access enable -local; $TFA_HOME/bin/tfactl access adddefaultusers -local; $TOUCH $TFA_HOME/.$host.shared; fi" >> $patchScript;

		echo "Creating patchScriptWrapper in local host"
		echo "#!/bin/sh -x" > $patchScriptWrapper
		echo "echo \" Running fixInitTfa \" >> $patchlog.wrapper" >> $patchScriptWrapper
		echo "$PERL $TFA_HOME/bin/tfactl.pl fixInitTfa " >> $patchScriptWrapper
		echo "echo \" Copying init.tfa to etc \" >> $patchlog.wrapper" >> $patchScriptWrapper
		echo "$CP -f $TFA_HOME/install/init.tfa $ID/init.tfa" >> $patchScriptWrapper
		echo "$RM -f $TFA_HOME/install/inittab" >> $patchScriptWrapper
		echo "echo \"Killing init.tfa process in $host\" >> $patchlog.wrapper" >> $patchScriptWrapper
		echo "tfapid=\`ps -ef | $GREP init.tfa | $GREP -v grep | $AWK '{print \$2}'\`"  >> $patchScriptWrapper
		echo "if [ ! -z \"\$tfapid\" ] ; then kill -9 \$tfapid; fi"  >> $patchScriptWrapper
		echo "echo \" Making the patchScript executable \" >> $patchlog.wrapper" >> $patchScriptWrapper
		echo "chmod +x $TFA_HOME/internal/patchScript.sh " >> $patchScriptWrapper
		echo "echo \" Running init.tfa patchrestart \" >> $patchlog.wrapper" >> $patchScriptWrapper
		echo "$ID/init.tfa patchrestart " >> $patchScriptWrapper
  
		echo ""
		if [ "$ZIPSTATUS" -eq "1" ]
		then
			echo "Sending $zipfile to $host"
			$PERL $tfa_home/bin/tfactl.pl copyfiles $zipfile "$TFA_HOME/internal/tfapatch.zip" $host
		else 
			echo "Sending $tarfile to $host"
			$PERL $tfa_home/bin/tfactl.pl copyfiles $tarfile "$TFA_HOME/internal/tfapatch.tar" $host
		fi
  
		echo "Sending $patchScript to $host"
		$PERL $tfa_home/bin/tfactl.pl copyfiles $patchScript "$TFA_HOME/internal/patchScript.sh" $host
		echo "Sending $patchScriptWrapper to $host"
		$PERL $tfa_home/bin/tfactl.pl copyfiles $patchScriptWrapper "$TFA_HOME/internal/patchScriptWrap" $host
		echo "Sending init.tfa to $host"
		$PERL $tfa_home/bin/tfactl.pl copyfiles $e_tfabase/tfa_home/install/init.tfa.tmpl "$TFA_HOME/install/init.tfa.tmpl" $host

		# Need to delete files from localhost after patching all the remote hosts
		#echo "Deleting $zipfile in localhost"
		#rm -f $zipfile 
		#echo "Deleting $patchScript in localhost"
		#rm -f $patchScript

                if [ "$INSTALLED_BLDVR" -lt "121200" ]
                then
                        echo "Executing patchScriptWrapper using old format in $host"
                        $executeCmd "sh $TFA_HOME/internal/patchScriptWrap"
                else
                        echo "Executing patchScriptWrapper in $host"
                        $executeCmd "patchScriptWrap";
                fi

		echo "Sleeping for 35 seconds while TFA is patched in $host"
		sleepdots 35 
		echo "Waiting up to 120 seconds for TFA to be restarted in $host"
		counter=0
		while [ $counter -lt 12 ]
		do
			sleepdots 10
			status=`$PERL $tfa_home/bin/tfactl.pl print status | $GREP $host | $AWK '{print $4}'`
			if [ "$status" = "RUNNING" ]
			then
				echo "Successfully restarted TFA in $host";
				#exit 1
				break;
			fi
			counter=`expr $counter + 1`
		done

		if [ "$status" != "RUNNING" ]
		then
			echo "Failed to restart TFA in $host"
		fi

		#else
		#echo "Auto patching is disabled in $host. Install TFA locally in $host." 
		#fi
	done
fi

# Patch Non-SSH remote nodes using TFA Installer
if [ "$LOCAL" -eq "0" ] && [ -s "$nonssh_list" ]
then
	REM_TFA_INSTALLER="/tmp/tfa_setup_`date '+%Y%m%d_%H%M%S'`";

	for host in `$CAT $nonssh_list`
	do
		$ECHO "";
		$ECHO "Copying TFA Installer to $host...";
		$SCP $TFA_INSTALLER $host:$REM_TFA_INSTALLER;
		$ECHO "";
		$ECHO "Starting TFA Installer on $host...";
		$SSH $host "$REM_TFA_INSTALLER -local -silent -patch; $RM -f $REM_TFA_INSTALLER";
	done
fi

TFA_HOME=$tfa_home;

$ECHO "";
$ECHO "Applying Patch on $HOSTNAME:";
$ECHO "";

# Stop Orachk Daemon
if [ -f "$tfa_home/ext/orachk/lib/autostart" ]
then
	$tfa_home/bin/tfactl stoporachkdaemon;
fi

#Shutdown TFA if its running:
if [ `ps -ef | $GREP $ID/init.tfa | $GREP -v grep | wc -l` -ge 1 ]
then
        # Stop tools first
        $ECHO "Stopping TFA Support Tools..."; 
        $tfa_home/bin/tfactl stop_suptools > /dev/null 2>&1

        $ECHO "";
        $ECHO "Shutting down TFA for Patching...";
	$ECHO "";
        $ID/init.tfa shutdown
        $ECHO "";
fi

if [ -f "$tfa_home/tfa_setup.txt" ]
then
	if [ -n "$TZ" ]
	then
		if [ `$GREP -c "^TZ=" $tfa_home/tfa_setup.txt` -eq "0" ]
		then
	        	$ECHO "TZ=$TZ" >> $tfa_home/tfa_setup.txt;
		fi
	fi

	if [ `$GREP -c "^DAEMON_OWNER=" $tfa_home/tfa_setup.txt` -eq "0" ]
	then
	       	$ECHO "DAEMON_OWNER=$RUSER" >> $tfa_home/tfa_setup.txt;
	fi
fi

JAR_DIR="$tfa_home/jar";

if [ -d "$JAR_DIR" ]
then
        JLIB_DIR="$tfa_home/jlib";
        $ECHO "Renaming $JAR_DIR to $JLIB_DIR";
        $MV -f $JAR_DIR $JLIB_DIR;

	if [ `$GREP -c "^INSTALL_TYPE=" $tfa_home/tfa_setup.txt` -eq "0" ]
	then
        	$ECHO "Adding INSTALL_TYPE = $INSTALL_TYPE to tfa_setup.txt";
	        $ECHO "INSTALL_TYPE=$INSTALL_TYPE" >> $tfa_home/tfa_setup.txt;
	fi

        # Only for GI Install move Output Dir to ORACLE_BASE
        if [ `$ECHO $INSTALL_TYPE | $GREP -c "GI"` -eq 1 ]
        then
                if [ -n "$ORACLE_BASE" ]
                then
                        OB_OUT_DIR="$ORACLE_BASE/tfa/$HOSTNAME/";
                        TFA_OUT_DIR="$tfa_home/output/";

                        $ECHO "Copying $TFA_OUT_DIR to $OB_OUT_DIR";
                        $CP -rf $TFA_OUT_DIR $OB_OUT_DIR;
                fi
        fi

        # Don't rename Uninstall Script for 11204 PSU1
        #if [ -f "$tfa_home/bin/uninstalltfa.sh" ]
        #then
        #       $MV -f $tfa_home/bin/uninstalltfa.sh $tfa_home/bin/uninstalltfa;
        #fi

        $ECHO "";
fi

if [ `$GREP -c "^PERL=" $tfa_home/tfa_setup.txt` -eq "0" ]
then
        $ECHO "PERL=$PERL" >> $tfa_home/tfa_setup.txt;
fi

$CP -f $e_tfabase/tfa_home/jlib/RATFA.jar $tfa_home/jlib/RATFA.jar > /dev/null 2>&1
$CP -f $e_tfabase/tfa_home/jlib/oraclepki.jar $tfa_home/jlib/oraclepki.jar > /dev/null 2>&1
$CP -f $e_tfabase/tfa_home/jlib/ojmisc.jar $tfa_home/jlib/ojmisc.jar > /dev/null 2>&1
$CP -f $e_tfabase/tfa_home/jlib/ojpse.jar $tfa_home/jlib/ojpse.jar > /dev/null 2>&1
$CP -f $e_tfabase/tfa_home/jlib/osdt_cert.jar $tfa_home/jlib/osdt_cert.jar > /dev/null 2>&1
$CP -f $e_tfabase/tfa_home/jlib/osdt_core.jar $tfa_home/jlib/osdt_core.jar > /dev/null 2>&1
$CP -f $e_tfabase/tfa_home/jlib/owm-3_0.jar $tfa_home/jlib/owm-3_0.jar > /dev/null 2>&1

# TFA REST Jars
$CP -f $e_tfabase/tfa_home/jlib/tfarest.jar $tfa_home/jlib/tfarest.jar > /dev/null 2>&1
$CP -f $e_tfabase/tfa_home/jlib/jackson-*.jar $tfa_home/jlib/  > /dev/null 2>&1
$CP -f $e_tfabase/tfa_home/jlib/log4j-*.jar $tfa_home/jlib/  > /dev/null 2>&1

if [ ! -f "$tfa_home/jlib/commons-io-2.6.jar" ]
then
        $CP -f  $e_tfabase/tfa_home/jlib/commons-io-2.6.jar $tfa_home/jlib/commons-io-2.6.jar > /dev/null 2>&1
fi

if [ -f "$tfa_home/jlib/commons-io-2.1.jar" ]
then
	$RM -f  $tfa_home/jlib/commons-io-2.1.jar
fi

if [ -f "$tfa_home/jlib/commons-io-2.5.jar" ]
then
	$RM -f  $tfa_home/jlib/commons-io-2.5.jar
fi

if [ -f "$tfa_home/jlib/jackson-core-2.9.4.jar" ]
then
	$RM -f $tfa_home/jlib/jackson-core-2.9.4.jar;
fi

if [ -f "$tfa_home/jlib/jackson-databind-2.9.5.jar" ]
then
	$RM -f $tfa_home/jlib/jackson-databind-2.9.5.jar;
fi

if [ -f "$tfa_home/jlib/jackson-annotations-2.9.4.jar" ]
then
	$RM -f $tfa_home/jlib/jackson-annotations-2.9.4.jar;
fi

if [ -f "$tfa_home/jlib/jackson-annotations-2.9.5.jar" ]
then
	$RM -f $tfa_home/jlib/jackson-annotations-2.9.5.jar;
fi

if [ -d "$tfa_home/jre1.6.0_18" ]
then
	$RM -rf $tfa_home/jre1.6.0_18
fi

# For bdb upgrade check if current version of BDB is 4.0.103
if [ -s "$tfa_home/jlib/je-4.0.103.jar" ] ;
then
        $ECHO "The current version of Berkeley DB is 4.0.103"
        $ECHO "Copying je-4.1.27.jar to $tfa_home/jlib/"
        $CP -f $e_tfabase/tfa_home/jlib/je-4.1.27.jar $tfa_home/jlib/

	$ECHO "Copying je-6.4.25.jar to $tfa_home/jlib/"
        $CP -f $e_tfabase/tfa_home/jlib/je-6.4.25.jar $tfa_home/jlib/

        $ECHO "Running DbPreUpgrade_4_1 utility"
        output=`$JAVA -jar $tfa_home/jlib/je-4.1.27.jar DbPreUpgrade_4_1 -h $BDB_HOME`

        $ECHO "Output of upgrade : $output"
        #rm -f $tfa_home/jlib/je-4.1.27.jar
elif [ -s "$tfa_home/jlib/je-5.0.84.jar" ] ;
then
	$ECHO "Copying je-6.4.25.jar to $tfa_home/jlib/"
        $CP -f $e_tfabase/tfa_home/jlib/je-6.4.25.jar $tfa_home/jlib/
else
        $ECHO "No Berkeley DB upgrade required"
fi

$CP -rf $e_tfabase/tfa_home/bin/* $tfa_home/bin/. > /dev/null 2>&1
$CP -rf $e_tfabase/tfa_home/resources/* $tfa_home/resources/. > /dev/null 2>&1
$CP -rf $e_tfabase/tfa_home/ext/ $tfa_home/ > /dev/null 2>&1
$CP -rf $e_tfabase/tfa_home/install/* $tfa_home/install/. > /dev/null 2>&1
$CP -f $e_tfabase/tfa_home/internal/usableports.txt $tfa_home/internal/ > /dev/null 2>&1
$CP -f $e_tfabase/tfa_home/internal/config.properties $tfa_home/internal/config.properties.patch > /dev/null 2>&1
$CP -fp $e_tfabase/tfa_home/internal/smtp.properties $tfa_home/internal/smtp.properties.patch > /dev/null 2>&1
$CP -f $e_tfabase/tfa_home/internal/timezones_mapping $tfa_home/internal/timezones_mapping.patch > /dev/null 2>&1
$CP -f $e_tfabase/tfa_home/internal/dbversions.json $tfa_home/internal/ > /dev/null 2>&1
$CP -f $e_tfabase/tfa_home/internal/.buildid $tfa_home/internal/.buildid.bkp > /dev/null 2>&1
$CP -f $e_tfabase/tfa_home/internal/.buildversion $tfa_home/internal/.buildversion.bkp > /dev/null 2>&1
$CP -f $e_tfabase/tfa_home/tfa_directories.txt $tfa_home/tfa_directories.txt.bkp > /dev/null 2>&1

if [ ! -d "$tfa_home/internal/scripts" ]
then
	$MKDIR $tfa_home/internal/scripts > /dev/null 2>&1
fi

# Copy ceritificates
$ECHO "";
$ECHO "Copying TFA Certificates...";
$CP -f $e_tfabase/tfa_home/tfa.jks $tfa_home/tfa.jks > /dev/null 2>&1
$CP -f $e_tfabase/tfa_home/public.jks $tfa_home/public.jks > /dev/null 2>&1

if [ ! -f "$tfa_home/server.jks" ]
then
	$CP -f $e_tfabase/tfa_home/server.jks $tfa_home/server.jks > /dev/null 2>&1
	$CP -f $e_tfabase/tfa_home/client.jks $tfa_home/client.jks > /dev/null 2>&1
	$CP -f $e_tfabase/tfa_home/internal/ssl.properties $tfa_home/internal/ssl.properties > /dev/null 2>&1
fi

$PERL $tfa_home/bin/tfactl.pl updateautodiagcollect
$PERL $tfa_home/bin/tfactl.pl updateciphersuite
$PERL $tfa_home/bin/tfactl.pl updatepropertiesfile
$PERL $tfa_home/bin/tfactl.pl updatedirectoriesfile

$ECHO "";
$ECHO "Running commands to fix init.tfa and tfactl in localhost"
$PERL $tfa_home/bin/tfactl.pl fixInitTfa
$PERL $tfa_home/bin/tfactl.pl fixTfactl
$PERL $tfa_home/bin/tfactl.pl copytfactl
$CHMOD a+x $tfa_home/ext $tfa_home/ext/oratop $tfa_home/ext/oratop/* 2>/dev/null
$CP -f $tfa_home/install/init.tfa $ID/init.tfa
$RM -f $tfa_home/install/inittab

#If this is Exadata then make orachk -> exachk
if [ -f "/etc/oracle/cell/network-config/cellip.ora" ]
then
  if [ -f "$tfa_home/ext/orachk/orachk.pyc" ]
  then
    $CP -f $tfa_home/ext/orachk/orachk.pyc $tfa_home/ext/orachk/exachk.pyc;
  fi

  if [ -f "$tfa_home/ext/orachk/orachk" ]
  then
    $CP -f $tfa_home/ext/orachk/orachk $tfa_home/ext/orachk/exachk;
  fi
fi

# From TFA 18.2 We need Lucene jars for TFA.
$CP -rf $e_tfabase/tfa_home/jlib/lucene*.jar $tfa_home/jlib 
$CP -rf $e_tfabase/tfa_home/jlib/javax.json-1.0.4.jar $tfa_home/jlib 

#Receiver is introduced first in 12.2.0.2.0/18.1
#Since code base is same for C & R, add Receiver code to both C & R as 
#it helps swithing modes easy. R certs generate only in R cluster
$ECHO ""
#Updates from 12.2.0.1.0(TFAV-12.2.1.1.0) to 18.1(TFAV-181000)
if [ "$INSTALLED_BLDVR" -le "181000" ]; then
  if [ -d $e_tfabase/tfa_home/tomcat ]; then
    $CP -rf $e_tfabase/tfa_home/receiver $tfa_home/
    $CP -rf $e_tfabase/tfa_home/tomcat $tfa_home/
  fi
  $RM -f $tfa_home/internal/rconfig.properties  
fi

$ECHO "";
$ECHO "Starting TFA in $HOSTNAME...";
$ECHO  "";
$ID/init.tfa start

if [ -f "$tfa_home/jlib/lucene-core-6.1.0.jar" ]
then
	$RM -f $tfa_home/jlib/lucene-*-6.1.0.jar;
fi

if [ -f "$tfa_home/jlib/je-4.0.103.jar" ]
then
	$ECHO "Removing $tfa_home/jlib/je-4.0.103.jar";
	$RM -f $tfa_home/jlib/je-4.0.103.jar;
fi

if [ -f "$tfa_home/jlib/je-5.0.84.jar" ]
then
        $ECHO "Removing $tfa_home/jlib/je-5.0.84.jar"
        $RM -f $tfa_home/jlib/je-5.0.84.jar
fi

if [ -f "$tfa_home/jlib/jewt4.jar" ]
then
	$RM -f $tfa_home/jlib/jewt4.jar;
fi

if [ -f "$CRS_HOME/suptools/tfa/release/tfa_home/jlib/jewt4.jar" ]
then
	$RM -f $CRS_HOME/suptools/tfa/release/tfa_home/jlib/jewt4.jar;
	$ECHO "Empty JAR - Not used but need to keep due to HAS patching issues" > $CRS_HOME/suptools/tfa/release/tfa_home/jlib/jewt4.jar;
fi

if [ -f "$tfa_home/jlib/jdev-rt.jar" ]
then
	$RM -f $tfa_home/jlib/jdev-rt.jar;
fi

if [ -f "$CRS_HOME/suptools/tfa/release/tfa_home/jlib/jdev-rt.jar" ]
then
	$RM -f $CRS_HOME/suptools/tfa/release/tfa_home/jlib/jdev-rt.jar;
	$ECHO "Empty JAR - Not used but need to keep due to HAS patching issues" > $CRS_HOME/suptools/tfa/release/tfa_home/jlib/jdev-rt.jar;
fi

if [ -f "$tfa_home/jlib/jsch-0.1.54.jar" ]
then
        $RM -f $tfa_home/jlib/jsch-0.1.54.jar;
fi

if [ -f "$CRS_HOME/suptools/tfa/release/tfa_home/jlib/jsch-0.1.54.jar" ]
then
        $RM -f $CRS_HOME/suptools/tfa/release/tfa_home/jlib/jsch-0.1.54.jar;
        $ECHO "Empty JAR - Not used but need to keep due to HAS patching issues" > $CRS_HOME/suptools/tfa/release/tfa_home/jlib/jsch-0.1.54.jar;
fi

if [ -f "$CRS_HOME/suptools/tfa/release/tfa_home/jlib/commons-io-2.5.jar" ]
then
        $RM -f $CRS_HOME/suptools/tfa/release/tfa_home/jlib/commons-io-2.5.jar;
        $ECHO "Empty JAR - Not used but need to keep due to HAS patching issues" > $CRS_HOME/suptools/tfa/release/tfa_home/jlib/commons-io-2.5.jar;
fi

if [ -f "$CRS_HOME/suptools/tfa/release/tfa_home/ext/tnt/lib/commons-cli-1.3.1.jar" ]
then
        $RM -f $CRS_HOME/suptools/tfa/release/tfa_home/ext/tnt/lib/commons-cli-1.3.1.jar;
        $ECHO "Empty JAR - Not used but need to keep due to HAS patching issues" > $CRS_HOME/suptools/tfa/release/tfa_home/ext/tnt/lib/commons-cli-1.3.1.jar;
fi

if [ -f "$CRS_HOME/suptools/tfa/release/tfa_home/ext/tnt/lib/commons-logging-1.2.jar" ]
then
        $RM -f $CRS_HOME/suptools/tfa/release/tfa_home/ext/tnt/lib/commons-logging-1.2.jar;
        $ECHO "Empty JAR - Not used but need to keep due to HAS patching issues" > $CRS_HOME/suptools/tfa/release/tfa_home/ext/tnt/lib/commons-logging-1.2.jar;
fi

# ensure root trace, srdc file dirs
$tfa_home/bin/tfactl access setuptracedir -user root;

# Update File Permissions for Non-root Access
$tfa_home/bin/tfactl access update -local;

# Changes for Non-root Access
if [ ! -f "$tfa_home/.$HOSTNAME.shared" ]
then
        # Open File Permissions for Non-root Access
        $tfa_home/bin/tfactl access enable -local;

        # Add Default users for Non-root Access
        $tfa_home/bin/tfactl access adddefaultusers -local;

        $TOUCH $tfa_home/.$HOSTNAME.shared;
fi

# restrict TLSv1 and TLSv1.1
$tfa_home/bin/tfactl restrictprotocol "TLSv1" > /dev/null;
$tfa_home/bin/tfactl restrictprotocol "TLSv1.1" > /dev/null;

if [ "$START_ORACHK" -eq "1" ]
then
	if [ -f "$tfa_home/ext/orachk/lib/autostart" ]
	then
		$tfa_home/bin/tfactl startorachkdaemon;
	fi
fi

$ECHO "";

# Remove SSH Keys and Configurations
if [ "$SSH_GEN_KEYS" -eq "1" ]
then
	# Remove Private Key
	if [ -f "$HOME/.ssh/$SSH_ID" ]
	then
		$RM -f $HOME/.ssh/$SSH_ID;
	fi

	# Remove Public Key
	if [ -f "$HOME/.ssh/$SSH_ID.pub" ]
	then
		$RM -f $HOME/.ssh/$SSH_ID.pub;
	fi
fi

for rmhostssh in $rmsshlist
do
	removeSSH $rmhostssh
	$ECHO "";
done

$ECHO "0" > /tmp/.tfa.patch;

exit 0;
