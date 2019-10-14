#!/bin/sh
#
# $Header: tfa/src/v2/tfa_home/resources/scripts/srdc_agent_cpu.sh /main/1 2018/08/15 16:55:52 bburton Exp $
#
# srdc_agent_cpu.sh
#
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      srdc_agent_cpu.sh 
#
#    DESCRIPTION
#      Called by emagentperf SRDC collection
#      Extracted from agent_cpu.zip in Doc ID 2100437.1: SRDC - Collect Diagnostic Data for EM Agent Performance Issues.
#	Usage: srdc_agent_cpu.sh <emagent_home> <emagent_pid>
#
#    NOTES
#      None 
#
#    MODIFIED   (MM/DD/YY)
#    xiaodowu    06/15/18 - Called by emagentperf SRDC collection
#    xiaodowu    06/15/18 - Creation
#
/bin/echo " Running Agent 12c Perf Problem Type Script Version 2"

#echo "Enter the path for Agent Home:"
#read entered_agent_oh_path

export entered_agent_oh_path=$1

#echo "Enter Agent PID use <ps -ef | grep -i tmmain> or ./emctl status agent : "
#read entered_agent_pid
export entered_agent_pid=$2

SCRIPT_USER=`id | /bin/awk '{print $1}' | /bin/cut -d'(' -f2 | /bin/cut -d')' -f1`
/bin/echo You entered ORACLE_HOME as : $entered_agent_oh_path
/bin/echo "Validating the ORACLE_HOME entered"

if [ ! -z "$entered_agent_oh_path" ] ; then

  if [ -d "${entered_agent_oh_path}" ] ; then
	
    if [ -s "${entered_agent_oh_path}/bin/emctl" ] ;  then
      OH_OWNER=`/bin/ls -l $entered_agent_oh_path/bin/emctl | /bin/awk {'print $3}'`
      if [ $SCRIPT_USER = $OH_OWNER ]; then
	EM_VERSION=`$entered_agent_oh_path/bin/emctl getversion agent | /usr/bin/tail -1 | /bin/awk '{print $3}'`
	if [ "$EM_VERSION" = "10g" ] ; then
	  /bin/echo "Enter a valid 11g or 12c agent Oracle Home!"
	  exit 1
	else
	  /bin/echo "Running cp -p $entered_agent_oh_path/bin/emctl $entered_agent_oh_path/bin/emctl_env.sh"
	  /bin/cp -p $entered_agent_oh_path/bin/emctl $entered_agent_oh_path/bin/emctl_env.sh
	  /bin/sed 's%$PERL_BIN/perl $ORACLE_HOME/bin/emctl.pl "$@"%#$PERL_BIN/perl $ORACLE_HOME/bin/emctl.pl "$@"%g' $entered_agent_oh_path/bin/emctl_env.sh > $entered_agent_oh_path/bin/emctl_env.sh.tmp && mv $entered_agent_oh_path/bin/emctl_env.sh.tmp $entered_agent_oh_path/bin/emctl_env.sh
	  /bin/sed 's%cmdexitcode=$?%#cmdexitcode=$?%g' $entered_agent_oh_path/bin/emctl_env.sh > $entered_agent_oh_path/bin/emctl_env.sh.tmp && mv $entered_agent_oh_path/bin/emctl_env.sh.tmp $entered_agent_oh_path/bin/emctl_env.sh
	  /bin/sed 's%exit $cmdexitcode%#exit $cmdexitcode%g' $entered_agent_oh_path/bin/emctl_env.sh > $entered_agent_oh_path/bin/emctl_env.sh.tmp && mv $entered_agent_oh_path/bin/emctl_env.sh.tmp $entered_agent_oh_path/bin/emctl_env.sh
	  chmod u+x $entered_agent_oh_path/bin/emctl_env.sh
	  . $entered_agent_oh_path/bin/emctl_env.sh
								
	  /bin/echo "Collecting jstack "
								
								
	  /bin/echo "Running perl script agent_cpu_datacollection.pl/emd_cpu_dc.pl"
	  #MY_PERL_CMD="$PERL_BIN/perl $entered_agent_oh_path/agent_cpu_datacollection.pl"
	  MY_PERL_CMD="$PERL_BIN/perl $entered_agent_oh_path/emd_cpu_dc.pl"
	  $MY_PERL_CMD
					
	fi
				
      else 
        /bin/echo "Owning user is different than script execution user. Please run the script as OS user owning OMS Installation"
	exit 1
      fi
		
    else
      /bin/echo "Entered Directory does not have valid emctl file. Either it does not exist or it is a zero byte file."
      /bin/echo "Re-run the script with valid Oracle Home / ensure that the emctl file is not corrupted!"
      exit 1
    fi	
  else
    /bin/echo "Enter a valid directory"
    exit 1
  fi
else 
  /bin/echo "You entered an empty string. Retry the script with valid directory!"
  exit 1
fi	
