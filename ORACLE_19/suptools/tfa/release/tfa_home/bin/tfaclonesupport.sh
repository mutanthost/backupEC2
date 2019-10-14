#!/bin/sh
#
# $Header: tfa/src/v2/tfa_home/bin/tfaclonesupport.sh /main/5 2016/10/24 09:33:30 cnagur Exp $
#
# tfaclonesupport.sh
#
# Copyright (c) 2016, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfaclonesupport.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    cnagur      10/23/16 - Fix for Bug 24935220
#    cnagur      09/14/16 - Removed init.tfa start
#    cnagur      08/19/16 - TFA JRE Changes
#    cnagur      08/10/16 - Fix for Bug 24414115
#    cnagur      03/22/16 - Creation
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
        elif [ -f "/usr/local/bin/$COMMAND" ]
        then
                CMDLOC="/usr/local/bin/$COMMAND";
        else
                CMDLOC="$COMMAND";
        fi

        echo "$CMDLOC";
}

UNAME=`getCommandLocation "uname"`;
PLATFORM=`$UNAME`;
AWK=`getCommandLocation "awk"`;
CP=`getCommandLocation "cp"`;
CUT=`getCommandLocation "cut"`;
ECHO=`getCommandLocation "echo"`;
GREP=`getCommandLocation "grep"`;
MV=`getCommandLocation "mv"`;
PERL=`getCommandLocation "perl"`;
RM=`getCommandLocation "rm"`;
SED=`getCommandLocation "sed"`;

if [ -f "/bin/logger" ]
then      
	LOGGER="/bin/logger -p daemon.notice -t oracle-tfa:clone";
else
	LOGGER="$ECHO";
fi                                                       

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
*)     $LOGGER "TFA-00000: Oracle Trace File Analyzer (TFA) is not supported on this platform."
       exit -1
       ;;
esac

TFASTART=1;

if [ -r "$ID/init.tfa" ]
then
	tfa_home=`$GREP '^TFA_HOME=' $ID/init.tfa | $AWK -F"=" '{print $2}'`;
fi

$LOGGER "Moving TFA to New TFA_HOME due to Cloning";

if [ -f "$tfa_home/tfa_setup.txt" ]
then
	if [ `$GREP -c "^PERL=" $tfa_home/tfa_setup.txt` -ge 1 ]
	then
		PERL=`$GREP '^PERL=' $tfa_home/tfa_setup.txt | $AWK -F"=" '{print $2}'`;
		$LOGGER "PERL in tfa_setup.txt : $PERL";
	fi
fi

if [ `$ECHO $tfa_home | $GREP -ic "\/var\/opt\/oracle\/tfa\/.*\/tfa_home$"` -ge 1 ]
then
        CLONE=`$ECHO $tfa_home | $SED -e 's/\/var\/opt\/oracle\/tfa\/\(.*\)\/tfa_home/\1/'`;

	if [ -d "$tfa_home/database/BERKELEY_JE_DB" ]
	then
	        HOSTNAME=`hostname | $CUT -d. -f1 | $PERL -ne 'print lc'`;
        	$LOGGER "HOSTNAME : $HOSTNAME";

		if [ -z "$HOSTNAME" ] || [ `$ECHO $HOSTNAME | $GREP -c "^(none)$"` -ge 1 ]
		then
			$LOGGER "TFA-00091: Invalid Hostname [$HOSTNAME]";
			TFASTART=0;
			HOSTNAME="tfatemphost";
        		$LOGGER "HOSTNAME : $HOSTNAME";
		fi

	        if [ "$CLONE" != "$HOSTNAME" ]
        	then
                	tfa_base=`$ECHO $tfa_home | $SED -e "s/\/$CLONE\/tfa_home//g"`;
	                $LOGGER "TFA_BASE : $tfa_base";

			TFA_HOME="$tfa_base/$HOSTNAME/tfa_home";
			$LOGGER "New TFA_HOME : $TFA_HOME";

			$LOGGER "Moving TFA_BASE";
			$MV -f $tfa_base/$CLONE $tfa_base/$HOSTNAME;

			# Remove TFA BDB
			if [ -d "$TFA_HOME/database/BERKELEY_JE_DB" ]
			then
				$LOGGER "Removing TFA BDB";
				$RM -f $TFA_HOME/database/BERKELEY_JE_DB/*;
			fi

			# Remove TFA Collections
			if [ -d "$tfa_base/repository" ]
			then
				$LOGGER "Removing TFA Collections";
				$RM -rf $tfa_base/repository/*;
			fi

			# Remove TFA Logs
			if [ -d "$TFA_HOME/log" ]
			then
				$LOGGER "Removing TFA Logs";
				$RM -f $TFA_HOME/log/*;
			fi

			# Remove TFA Inventory and Metadata
			if [ -d "$TFA_HOME/output/inventory" ]
			then
				$LOGGER "Removing TFA Inventory Files";
				$RM -f $TFA_HOME/output/inventory/*;
				$RM -f $TFA_HOME/output/metadata/*;
			fi

			# Remove TFA Certificates
			if [ -f "$TFA_HOME/server.jks" ]
			then
				$LOGGER "Removing server.jks";
				$RM -f $TFA_HOME/server.jks;
			fi

			if [ -f "$TFA_HOME/client.jks" ]
			then
				$LOGGER "Removing client.jks";
				$RM -f $TFA_HOME/client.jks;
			fi

			# Remove Discovery Files
			if [ -f "$tfa_base/$HOSTNAME/ora_stack_status.out" ]
			then
				$RM -f $tfa_base/$HOSTNAME/ora_stack_status.out;
				$RM -f $tfa_base/$HOSTNAME/final_tfa_discovery.out;
				$RM -f $tfa_base/$HOSTNAME/ora_stack_status_pct.out;
			fi

			# Remove ssl.properties
			if [ -f "$TFA_HOME/internal/ssl.properties" ]
			then
				$LOGGER "Removing ssl.properties";
				$RM -f $TFA_HOME/internal/ssl.properties;
			fi

			$LOGGER "Updating TFA Configuation Files";

			# Update tfa_setup.txt
			if [ -f "$TFA_HOME/tfa_setup.txt" ]
			then
				$PERL -p -i -e "s{$CLONE}{$HOSTNAME}g" $TFA_HOME/tfa_setup.txt;
			fi

			# Update tfa_directories.txt
			if [ -f "$TFA_HOME/tfa_directories.txt" ]
			then
				$PERL -p -i -e "s{$CLONE}{$HOSTNAME}g" $TFA_HOME/tfa_directories.txt;
			fi

			# Update scanned_directories.txt
			if [ -f "$TFA_HOME/internal/scanned_directories.txt" ]
			then
				$PERL -p -i -e "s{$CLONE}{$HOSTNAME}g" $TFA_HOME/internal/scanned_directories.txt;
			fi

			# Update rconfig.properties
			if [ -f "$TFA_HOME/internal/rconfig.properties" ]
			then
				$PERL -p -i -e "s{$CLONE}{$HOSTNAME}g" $TFA_HOME/internal/rconfig.properties;
			fi

			# Update tfactl
			if [ -f "$TFA_HOME/bin/tfactl" ]
			then
				$LOGGER "Updating TFA_HOME/bin/tfactl";
				$PERL -p -i -e "s{^TFA_HOME=.*}{TFA_HOME=$TFA_HOME}g" $TFA_HOME/bin/tfactl;
			fi

			# Update init.tfa
			if [ -f "$TFA_HOME/install/init.tfa" ]
			then
				$LOGGER "Updating init.tfa";
				$PERL -p -i -e "s{^TFA_HOME=.*}{TFA_HOME=$TFA_HOME}g" $TFA_HOME/install/init.tfa;
			fi

			# Remove Port Mapping File
			if [ -f "$TFA_HOME/internal/portmapping.txt" ]
			then
				$LOGGER "Removing TFA Port Mapping Files";
				$RM -f $TFA_HOME/internal/portmapping.txt;
			fi

			# Copy init.tfa to init.d directory
			$LOGGER "Copying init.tfa to $ID";
			$CP -f $TFA_HOME/install/init.tfa $ID/init.tfa;

			# Get JAVA_HOME from tfa_setup.txt
			if [ `$GREP -c "^JAVA_HOME=" $TFA_HOME/tfa_setup.txt` -ge 1 ]
			then
				TFA_JAVA_HOME=`$GREP '^JAVA_HOME=' $TFA_HOME/tfa_setup.txt | $AWK -F"=" '{print $2}'`;
				$LOGGER "JAVA_HOME in tfa_setup.txt : $TFA_JAVA_HOME";
			fi

			# Generate TFA Certificates
			if [ -n "$TFASTART" ] && [ "$TFASTART" -eq 1 ]
			then
				if [ -d "$TFA_JAVA_HOME" ]
				then
					$LOGGER "Generating Certificates...";
					$TFA_HOME/bin/tfactl generatecerts $TFA_HOME $TFA_JAVA_HOME 1;
				fi
			fi
        	fi
	fi
fi

exit 0;
