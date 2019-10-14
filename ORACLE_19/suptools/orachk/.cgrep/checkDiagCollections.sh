#!/bin/bash
#
# checkDiagCollections.sh
#
# Copyright (c) 2015, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      checkDiagCollections.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      Known dependencies :
#			- exachk outfiles ( check_env.out, raccheck_env.out, d_v_parameters*.out , a_v_parameter_asm.out)
#           - the format of targets.xml from Oracle Agent directory
#			- jar files from CRS_HOME used to apply stylesheet to targets.xml	
#     
#
#    MODIFIED   (MM/DD/YY)
#    cmvasile    02/28/17 - replace the suggested syntax for Solaris 
#    cgirdhar    11/29/16 - removed two new lines and replace syntax - with
#                           syntax --
#    cmvasile    10/20/16 - creation
#


###########################################################################
#                                                                         #
#  Purpose: 															  #
#			- Incorrect status of Oracle monitoring agent and/or OS       #
#				settings on ADR diagnostic directories					  #
#           							     							  #
#           														      #
#                                                                         #
###########################################################################

## Variable declarations

AgentActiveStatus=0
DiagPermissionsStatus=0
ManifestExistanceStatus=0
MembershipStatus=0
AgentSynchronizedStatus=0
HeaderStatus=0
AgentActiveOutput=''
DiagPermissionsOutput=''
ManifestExistanceOutput=''
MembershipOutput=''
AgentSynchronizedOutput=''
SummaryMonitoredOutputt=''
HeaderOutput=''

SHORT_HOST=$(hostname | cut -d. -f1);
_check_env="${OUTPUTDIR}/check_env.out"
_raccheck_env="${OUTPUTDIR}/raccheck_env.out"
_agent_inst="/opt/OracleHomes/agent_home/agent_inst";

declare -a v_allIssues;  # raw array of all issues relate to Oracle monitoring issues
declare -a v_monitored_active; ## raw array of all monitored databases in Active status on system
declare -a v_monitored_not_active; ## raw array of all monitored databases in non Active status on system		
declare -a v_diff_oracle_homes; ## raw array of all monitored databases with a diff between oracle home from agent to system
declare -a v_diag_wrong_permissions; ##  raw array of all db nodes with missing g+rw permissions on diag directory		
declare -a v_wrong_existing_manifest; ##  raw array of all db nodes with manifest files into diag directories owned by other user than monitoring one
declare -a v_missing_required_groups; ##  raw array of all db nodes where monitoring user missing from required dba groups

## Variable declarations


## Function Definitions
usage()
{
  echo "Usage: checkDiagCollections.sh [-c Mandatory|Optional -o check|report] [-h]";
}

CheckMandatory()
{
	
	if [[ ! -r "${_check_env}" ]] ; then
		if [[ ! -r "${_raccheck_env}" ]] ; then
			DiagPermissionsOutput="\n[FAIL] Message: Incorrect Exachk environment defined.\n";			
			DiagPermissionsStatus='9196'; ### skip the check
			return 2; ### exit function
		else 
			_check_env="$OUTPUTDIR/raccheck_env.out"
		fi		
	fi
	
	### check if the Oracle EM Agent is installed
	
	#v_monitoring_emagent_installed=$(grep ${SHORT_HOST} ${_check_env} | grep -A 1 -B 2 "OracleHomes/agent_inst"|grep "EMAGENT_INSTALLED ="| awk '{print $3}'| head -1 | sed 's/ //g');
	if [[ -z "$v_monitoring_emagent_installed"  ||  "$v_monitoring_emagent_installed" != "1" ]];
	then
		if [ -d "${_agent_inst}" ]; then
			v_monitoring_emagent_installed="1";
		fi
	fi
	
	if [[ -z "$v_monitoring_emagent_installed"  ||  "$v_monitoring_emagent_installed" != "1" ]];
	then
		DiagPermissionsOutput="\n[FAIL] Message: Unable to find Oracle Monitoring Agent.\n\n";
		DiagPermissionsStatus='9196'; ### skip the check
		return 2; ### exit function
	fi
		
	## check if the exachk discovered Oracle EM Agent Home 
	#v_monitoring_emagent_home=$(grep ${SHORT_HOST} ${_check_env} | grep -A 1 -B 2 "OracleHomes/agent_inst"|grep "EMAGENT_INST ="| awk '{print $3}'| head -1 | sed 's/ //g');
	if [ -z "$v_monitoring_emagent_home" ]
        then
			if [ -d "${_agent_inst}" ]; then
				v_monitoring_emagent_home="${_agent_inst}";
			fi  
    fi
	
	if [ -z "$v_monitoring_emagent_home" ]
        then
			DiagPermissionsOutput="\n[FAIL] Message: Unable to find Oracle Monitoring Agent.\n\n";
			DiagPermissionsStatus='9196'; ### skip the check
            return 2; ### exit function  
    fi
		
	### get monitoring user
	if [ `uname -s` = "Linux" ]; then
		v_monitoring_user=$(stat -L -c "%U" ${v_monitoring_emagent_home} 2>/dev/null >&1);
		if [ -z ${v_monitoring_user} ]; then
			v_monitoring_user=$(ls -ld ${v_monitoring_emagent_home} 2>/dev/null >&1|awk '{print $3}');
		fi
	else
		v_monitoring_user=$(ls -ld ${v_monitoring_emagent_home} 2>/dev/null >&1|awk '{print $3}');
	fi				
	if [ -z "$v_monitoring_user" ]
        then
			DiagPermissionsOutput="\n[FAIL] Message: Unable to find Oracle Monitoring Agent.\n\n";
			DiagPermissionsStatus='9196'; ### skip the check
            return 2; ### exit function 
    fi
	
	### check if the Oracle EM Agent is up and running
	#v_monitoring_emagent_running=$(grep ${SHORT_HOST} ${_check_env} | grep -A 1 -B 2 "OracleHomes/agent_inst"|grep "EMAGENT_UP ="| awk '{print $3}'| head -1 | sed 's/ //g');
	if [[ -z "$v_monitoring_emagent_running"  ||  "$v_monitoring_emagent_running" != "1" ]];
	then
		v_agent_process=$(ps -ef | grep OracleHomes| grep agent_ | wc -l);
		if [[ ${v_agent_process} -ne 0 ]]; then
			v_monitoring_emagent_running="1";
		fi		
	fi
	
	### check if the Oracle EM Agent is up and running
	if [[ -z "$v_monitoring_emagent_running"  ||  "$v_monitoring_emagent_running" != "1" ]];
	then
		AgentActiveStatus=1;
		AgentActiveOutput="${AgentActiveOutput}\n\n4)[Status: FAIL] Message: Oracle Agent is not running.\n\nAction/Repair:";
		AgentActiveOutput="${AgentActiveOutput}\nAs root on ${SHORT_HOST}, run the following commands to start up the agent:\n# su - ${v_monitoring_user}\n# ${v_monitoring_emagent_home}/bin/emctl start agent";
	else
		AgentActiveStatus=0;
		AgentActiveOutput="${AgentActiveOutput}\n\n4)[Status: PASS] Message: Oracle Agent is up and running.\n";
	fi

	
	
	### get existing groups of monitoring user
	v_monGroups=($(groups "$v_monitoring_user"|cut -d':' -f2|xargs));
	
	
	
	### get Agent Monitored Targets				
	### get CRS HOME
	v_gridhome=`grep "CRS_HOME =" ${_check_env} | awk '{print $3}' | head -1 | sed 's/ //g'`;
		
	if [[ -z ${v_gridhome} ]] ; 
	then
		AgentActiveOutput="\n[Status: FAIL] Message: CRS_HOME not found within the exachk environment.\n";			
		AgentActiveStatus='1'; ### skip the check
		return 2; ### exit function		
	else
		### get targets from agent repository
		
		v_targets_xsl="${OUTPUTDIR}/targets.xsl";    
		### Try to determine the targets.xml of monitoring agent
		if [ ! -e "${v_monitoring_emagent_home}/sysman/emd/targets.xml" ]; then
		
			AgentActiveOutput="\n[Status: FAIL] Message: Oracle Agent is not installed properly.\n";			
			AgentActiveStatus='1'; ### skip the check
			return 2; ### exit function
			
		else
			v_targets_xml="${v_monitoring_emagent_home}/sysman/emd/targets.xml";
			cat >${v_targets_xsl} <<EOF
<?xml version="1.0"?>
<!--Get database:home from targets.xml-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="text" />
<xsl:strip-space elements="*"/>
<xsl:template match="Target[( @TYPE='rac_database' or @TYPE='oracle_database' or @TYPE='osm_instance' or @TYPE='osm_cluster') and ./Property[@NAME='SID'] and ./Property[@NAME='OracleHome']]">
  <xsl:for-each select="Property">
     <xsl:sort select="@NAME" order="descending" />
     <xsl:if test="@NAME='SID'">
       <xsl:value-of select="@VALUE"/><xsl:text>:</xsl:text>
     </xsl:if>
     <xsl:if test="@NAME='OracleHome'">
       <xsl:value-of select="@VALUE"/>
     </xsl:if>
  </xsl:for-each>
<xsl:text>
</xsl:text>
</xsl:template>
</xsl:stylesheet>
EOF
			# Apply stylesheet to targets.xml to get list of monitored databases and their homes
			# ex, resulting array would look something like this:
			# v_targets='([0]="db1:/u01/app/oracle/product/12.1.0.2/dbhome_1" [1]="db2:/u01/app/oracle/product/12.1.0.2/dbhome_2")'

			v_targets=($(CLASSPATHJ=${v_gridhome}/jdbc/lib/ojdbc.jar:${v_gridhome}/jlib/orai18n.jar CLASSPATH=.:${v_gridhome}/jdbc/lib/ojdbc.jar:${v_gridhome}/jlib/orai18n.jar:${v_gridhome}/lib/xmlparserv2.jar:${v_gridhome}/lib/xsu12.jar:${v_gridhome}/lib/xml.jar LD_LIBRARY_PATH=${v_gridhome}/lib:$LD_LIBRARY_PATH JAVA_HOME=${v_gridhome}/jdk PATH=${v_gridhome}/jdk/bin:$PATH ${v_gridhome}/bin/oraxsl  ${v_targets_xml} ${v_targets_xsl}))
			
		fi
	fi        

	if [[ ${#v_targets[@]} -gt 0 ]]; then
		for v_database in ${v_targets[@]}
		do
			v_oracle_home=${v_database#*:}
			v_oracle_database=${v_database%%:*}
			v_allIssues=("${v_allIssues[@]}" "${SHORT_HOST}:1:Agent_Oracle_Home::${v_oracle_database}:1:${v_oracle_home}:");
		done
	fi
	
	
	### get all oracle databases
	v_asm_instances=$(grep ${SHORT_HOST} ${_check_env} | grep 'ASM_INSTANCE'  | awk -F= '{print $2}' | sed 's/ //g');
	v_oracle_instances=$(grep ${SHORT_HOST} ${_check_env} | grep 'INSTANCE_NAME'  | awk -F= '{print $2}' | sed 's/ //g');
	v_all_instances=("${v_asm_instances[@]}" "${v_oracle_instances[@]}");
	
	### iniatialize temp arrays to get unique values
	declare -a temp_diff_diags=();
	declare -a temp_diff_manifest=();
	declare -a temp_diff_groups=();	
    for v_instance in ${v_all_instances[@]}					
    do
		### continue unless the Oracle agent monitors database instances
		if [[ ${#v_targets[@]} -eq 0 ]]; then
			continue;
		fi		
		### continue unless the Oracle agent monitors the database instance		
		if [[ ! " ${v_targets[@]} " =~ "${v_instance/+/}:" ]]; then
			continue;
		fi
		
		if [[ "${v_instance/+/}" =~ ASM[0-9]+ ]]; then
			if [[ -r "$OUTPUTDIR/a_v_parameter_asm.out" ]] ; then
				v_diag_dest=$(grep "${v_instance}.diagnostic_dest" $OUTPUTDIR/a_v_parameter_asm.out | awk -F= '{print $2}' | head -1 | sed 's/ //g' 2>/dev/null);
				v_rac_database='ASM';
				sys_oracle_home=$(grep "ASM_HOME" ${_check_env} | awk -F= '{print $2}' | head -1 | sed 's/ //g');	
				
			fi									
		else
			v_rac_database=$(grep "INSTANCE_NAME = ${v_instance}" ${_check_env} | awk -F. '{print $2}' | head -1 | sed 's/ //g' 2>/dev/null);			
			if [[ -r "$OUTPUTDIR/d_v_parameter_${v_rac_database}.out" ]] ; then
				v_diag_dest=$(grep "${v_instance}.diagnostic_dest" $OUTPUTDIR/d_v_parameter_${v_rac_database}.out | awk -F= '{print $2}' | head -1 | sed 's/ //g' 2>/dev/null);
				sys_oracle_home=$(grep "DB_NAME = ${v_rac_database}" ${_check_env} | awk -F= '{print $2}' |awk -F'|' '{print $3}'| head -1 | sed 's/ //g' 2>/dev/null);			
			fi						
		fi
		### get Oracle Home from Environment
		if [[ -z "${v_rac_database}"  ||  -z "${v_instance}" || -z "${v_diag_dest}" ]];
		then
			HeaderStatus=2;
			HeaderOutput="* Note that the check results can be incomplete because not all databases have been scanned or not all diagnostic directories were found.\n";
			continue;		
		fi
		
		v_allIssues=("${v_allIssues[@]}" "${SHORT_HOST}:1:System_Oracle_Home:${v_rac_database}:${v_instance}:1:${sys_oracle_home}:");
		
		### All checks based on diag directory
		v_diag_dest="${v_diag_dest}/diag";
		if [ -d "$v_diag_dest" ]; then
		
			# Control will enter here if diag directory exists.

			## Check diag permissions
			
			v_permissions_checked='';
			for temp_diff_diag in "${temp_diff_diags[@]}" ; do
				temp_diff_diag_key="${temp_diff_diag%%#*}";
				temp_diff_diag_value="${temp_diff_diag##*#}";
				if [[ ${temp_diff_diag_key} == ${v_diag_dest} ]]; then
					v_permissions_checked=${temp_diff_diag_value};
				fi
			done
			if [[ -z ${v_permissions_checked} ]]; then
				### Check Diag Permissions
				if [ `uname -s` = "Linux" ]; then
					if [ -n "$(find ${v_diag_dest} -type d ! -perm -g+rw -print -quit)" ]; then
						v_permissions_checked=0;					
					else
						v_permissions_checked=1;
					fi
				else
					if [ -n "$(find ${v_diag_dest} -type d ! -perm -g+rw -print | head -1)" ]; then
						v_permissions_checked=0;					
					else
						v_permissions_checked=1;
					fi
				fi
				
				
				temp_diff_diags=("${temp_diff_diags[@]} ${v_diag_dest}#${v_permissions_checked}");												
			fi
			v_allIssues=("${v_allIssues[@]}" "${SHORT_HOST}:1:Check_Diag:${v_rac_database}:${v_instance}:${v_permissions_checked}:${v_diag_dest}:");
			
			### Check existance of manifest.xsl file into diag directory owned by other user then monitoring user
			
			v_manifest_checked='';
			for temp_diff_manifest_item in "${temp_diff_manifest[@]}" ; do
				temp_diff_manifest_item_key="${temp_diff_manifest_item%%#*}";
				temp_diff_manifest_item_value="${temp_diff_manifest_item##*#}";
				if [[ ${temp_diff_manifest_item_key} == ${v_diag_dest} ]]; then
					v_manifest_checked=${temp_diff_manifest_item_value};
				fi
			done
			if [[ -z ${v_manifest_checked} ]]; then 

				no_manifest=$(find ${v_diag_dest} -name manifest.xsl ! -user ${v_monitoring_user} | wc -l);
				if [[ ${no_manifest} -eq 0 ]]; then
						v_manifest_checked=1;
				else
						v_manifest_checked=0;
				fi
				temp_diff_manifest=("${temp_diff_manifest[@]} ${v_diag_dest}#${v_manifest_checked}");									
			fi			
			v_allIssues=("${v_allIssues[@]}" "${SHORT_HOST}:1:Check_Manifest:${v_rac_database}:${v_instance}:${v_manifest_checked}:${v_diag_dest}:${v_monitoring_user}");
		
		else
			HeaderStatus=2;
			HeaderOutput="* Note that the check results can be incomplete because not all databases have been scanned or not all diagnostic directories were found.\n";
			
		fi
		
		### Check the membership of monitoring user
		### get group of database owner

		if [ `uname -s` = "Linux" ]
		then
			v_dbGroup=$(stat -L -c "%G" ${v_diag_dest} 2>/dev/null >&1);
			if [ -z ${v_dbGroup} ]; then
				v_dbGroup=$(ls -ld ${v_diag_dest} 2>/dev/null >&1|awk '{print $4}');
			fi
		else
			v_dbGroup=$(ls -ld ${v_diag_dest} 2>/dev/null >&1|awk '{print $4}');
		fi				
			
			
		if [ -n "$v_dbGroup" ]; then
			v_requiredGroups=("${v_requiredGroups[@]}" "${v_dbGroup}");
		fi
		if [ -n "$sys_oracle_home" ]; then
			### get DBA OS Groups					
			if [ -e ${sys_oracle_home}/bin/osdbagrp ]; then
				v_osdbagrp=$(${sys_oracle_home}/bin/osdbagrp -d 2> /dev/null);
			fi
			v_requiredGroups=("${v_requiredGroups[@]}" "${v_osdbagrp[@]}");
		fi;						
		### remove duplicates
		v_requiredGroups=($(echo "${v_requiredGroups[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '));
		v_inGroup=1;
		v_diffGroup='';
		for v_grp in ${v_requiredGroups[@]}
		do
			if [[ ! " ${v_monGroups[@]} " =~ " ${v_grp} " ]]; then
				v_inGroup=0;
				v_diffGroup="${v_diffGroup},${v_grp}";								
			fi					
		done
		### remove the first comma
		v_diffGroup=$(echo ${v_diffGroup}|awk '{print substr($0,2)}');
		v_allIssues=("${v_allIssues[@]}" "${SHORT_HOST}:1:Check_Groups:${v_rac_database}:${v_instance}:${v_inGroup}:${v_monitoring_user}:${v_diffGroup}");
	
	done
	
	
	### Check Diag, Manifest ,etc
	
	for v_issue in ${v_allIssues[@]}
	do
			v_check=$(echo ${v_issue} | awk -F: '{print $3}' | head -1 | sed 's/ //g');
			if [[ "${v_check}" == "Agent_Oracle_Home" ]]; then

				a_host=$(echo ${v_issue} | awk -F: '{print $1}' | head -1 | sed 's/ //g');
				a_instance=$(echo ${v_issue} | awk -F: '{print $5}' | head -1 | sed 's/ //g');
				a_oracle_home=$(echo ${v_issue} | awk -F: '{print $7}' | head -1 | sed 's/ //g');
				
				a_existance=0;
				
				for a_issue in ${v_allIssues[@]}				
				do
					i_host=$(echo ${a_issue} | awk -F: '{print $1}' | head -1 | sed 's/ //g');
					i_instance=$(echo ${a_issue} | awk -F: '{print $5}' | head -1 | sed 's/ //g');
					i_check=$(echo ${a_issue} | awk -F: '{print $3}' | head -1 | sed 's/ //g');	
					
					if [[ ("${i_host}" == "${a_host}") && ("${i_instance}" == "${a_instance}") && ("${i_check}" != "Agent_Oracle_Home") ]]; then
						## database instance found on the system
						a_existance=1;
						if [[ "${i_check}" == "System_Oracle_Home" ]]; then
							s_oracle_home=$(echo ${a_issue} | awk -F: '{print $7}' | head -1 | sed 's/ //g');
						fi
						if [[ "${i_check}" == "Check_Diag" ]]; then
							s_check_diag=$(echo ${a_issue} | awk -F: '{print $6}' | head -1 | sed 's/ //g');
							s_diag=$(echo ${a_issue} | awk -F: '{print $7}' | head -1 | sed 's/ //g');
						fi
						if [[ "${i_check}" == "Check_Manifest" ]]; then
							s_check_manifest=$(echo ${a_issue} | awk -F: '{print $6}' | head -1 | sed 's/ //g');
							s_diag_manifest=$(echo ${a_issue} | awk -F: '{print $7}' | head -1 | sed 's/ //g');
							s_monitoring_user_manifest=$(echo ${a_issue} | awk -F: '{print $8}' | head -1 | sed 's/ //g');
						fi
						if [[ "${i_check}" == "Check_Groups" ]]; then
							s_check_groups=$(echo ${a_issue} | awk -F: '{print $6}' | head -1 | sed 's/ //g');
							s_monitoring_user_groups=$(echo ${a_issue} | awk -F: '{print $7}' | head -1 | sed 's/ //g');
							s_required_groups=$(echo ${a_issue} | awk -F: '{print $8}' | head -1 | sed 's/ //g');
						fi
					fi		
				done
					
					### check if the instance is monitored by the agent
					if [[ "${a_existance}" == "0" ]]; then
						v_monitored_not_active=("${v_monitored_not_active[@]}" "${a_instance}:${a_oracle_home}");
					else
						v_monitored_active=("${v_monitored_active[@]}" "${a_instance}:${a_oracle_home}");
						if [[ "${a_oracle_home}" != "${s_oracle_home}" ]] && [[ -n "${s_oracle_home}" ]] ; then
							v_diff_oracle_homes=("${v_diff_oracle_homes[@]}" "${a_host}:${a_instance}:${a_oracle_home}:${s_oracle_home}");
						fi
						if [[ "${s_check_diag}" == "0" ]]; then
							v_diag_wrong_permissions=("${v_diag_wrong_permissions[@]}" "${a_host}:${s_diag}::");
						fi
						if [[ "${s_check_manifest}" == "0" ]]; then
							v_wrong_existing_manifest=("${v_wrong_existing_manifest[@]}" "${a_host}:${s_diag_manifest}:${s_monitoring_user_manifest}:");
						fi
						if [[ "${s_check_groups}" == "0" ]]; then
							v_missing_required_groups=("${v_missing_required_groups[@]}" "${a_host}:${s_monitoring_user_groups}:${s_required_groups}:");
						fi
					fi				
			fi		
	done
	
	#### Diag Permissions
		
	v_diag_issues='';
	
	### prepare arrays for aggregation 
	### remove duplicates
	v_diag_wrong_permissions=($(echo "${v_diag_wrong_permissions[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '));
	for v_diag_issue in ${v_diag_wrong_permissions[@]}
	do
		get_diag_host=`echo ${v_diag_issue} | awk -F: '{print $1}' | head -1 | sed 's/ //g'`;
		get_diag_directory=`echo ${v_diag_issue} | awk -F: '{print $2}' | head -1 | sed 's/ //g'`;
		v_diag_issues="${v_diag_issues} ${get_diag_directory}";
	done
	

	if [[ ${#v_diag_wrong_permissions[@]} -eq 0 ]]; then
		DiagPermissionsStatus=0;


		DiagPermissionsOutput="${DiagPermissionsOutput}\n1)[Status: PASS] Message: OS permissions on diagnostic directories are correct.\n";
        
	else
        DiagPermissionsStatus=1;


		DiagPermissionsOutput="${DiagPermissionsOutput}\n1)[Status: FAIL] Message: OS permissions on diagnostic directories are not correct.";
		v_diag_issues=$(echo ${v_diag_issues}|awk '{print substr($0,1)}');
		DiagPermissionsOutput="${DiagPermissionsOutput}\n\nAction/Repair:";		
		temp_arr=(${v_diag_issues});
		
		for v_diag_need_attention in "${temp_arr[@]}"
		do
			### remove diag directory for further arrays
			v_active_not_monitored_diag=( ${v_active_not_monitored_diag[@]/${v_diag_need_attention}/});				
			DiagPermissionsOutput="${DiagPermissionsOutput}\n	- As root on ${get_diag_host}, recursively backup the existing permissions of ${v_diag_need_attention} directory";
			DiagPermissionsOutput="${DiagPermissionsOutput}\n	- As root on ${get_diag_host}, recursively add permissions (rw to the group) to ${v_diag_need_attention} directory";
		done
		
		DiagPermissionsOutput="${DiagPermissionsOutput}\n\n---------- Suggested syntax -- test before execution ----------\n";
			
		if [ `uname -s` = "Linux" ]
		then			
			for v_diag_need_attention in "${temp_arr[@]}"
			do
				### remove diag directory for further arrays
				v_active_not_monitored_diag=( ${v_active_not_monitored_diag[@]/${v_diag_need_attention}/});				
				DiagPermissionsOutput="${DiagPermissionsOutput}\n	# getfacl --absolute-names -R ${v_diag_need_attention} > ${v_diag_need_attention}/backup_permissions.acl";
				DiagPermissionsOutput="${DiagPermissionsOutput}\n	# chmod -R g+rw ${v_diag_need_attention}";
			done
		else
			### means Solaris
			for v_diag_need_attention in "${temp_arr[@]}"
			do
				### remove diag directory for further arrays
				v_active_not_monitored_diag=( ${v_active_not_monitored_diag[@]/${v_diag_need_attention}/});				
				DiagPermissionsOutput="${DiagPermissionsOutput}\n	# find ${v_diag_need_attention}  -name \"*\" -exec ls -ld {} + > ${v_diag_need_attention}/backup_permissions.acl";
				DiagPermissionsOutput="${DiagPermissionsOutput}\n	# chmod -R g+rw ${v_diag_need_attention}";
			done
			
		fi
		
		DiagPermissionsOutput="${DiagPermissionsOutput}\n\n--------------------------------------------------------------";
	fi
	
	#### Manifest files
		
	v_manifest_issues='';
		
	### prepare arrays for aggregation 
	### remove duplicates
	v_wrong_existing_manifest=($(echo "${v_wrong_existing_manifest[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '));
	for v_manifest_issue in ${v_wrong_existing_manifest[@]}
	do
		get_manifest_host=`echo ${v_manifest_issue} | awk -F: '{print $1}' | head -1 | sed 's/ //g'`;
		get_manifest_directory=`echo ${v_manifest_issue} | awk -F: '{print $2}' | head -1 | sed 's/ //g'`;
		get_monitoring_user=`echo ${v_manifest_issue} | awk -F: '{print $3}' | head -1 | sed 's/ //g'`;
		v_manifest_issues="${v_manifest_issues} ${get_manifest_directory}:${get_monitoring_user}";
	done	

	if [[ ${#v_wrong_existing_manifest[@]} -eq 0 ]]; then
		ManifestExistanceStatus=0;
		ManifestExistanceOutput="${ManifestExistanceOutput}\n";
		ManifestExistanceOutput="${ManifestExistanceOutput}\n2)[Status: PASS] Message: All manifest.xsl files under diagnostic directories are owned by the monitoring user.\n";
        
	else
        ManifestExistanceStatus=1;
		ManifestExistanceOutput="${ManifestExistanceOutput}\n";
		ManifestExistanceOutput="${ManifestExistanceOutput}\n2)[Status: FAIL] Message: Manifest.xsl files (under diagnostic directories) are not owned by the monitoring user.";
		v_manifest_issues=$(echo ${v_manifest_issues}|awk '{print substr($0,1)}');
		ManifestExistanceOutput="${ManifestExistanceOutput}\n\nAction/Repair:";
		temp_arr=(${v_manifest_issues});
		for v_manifest_need_attention in "${temp_arr[@]}"
		do			
			temp_diag=$(echo ${v_manifest_need_attention} |awk -F: '{print $1}' | head -1 | sed 's/ //g');
			temp_user=$(echo ${v_manifest_need_attention} |awk -F: '{print $2}' | head -1 | sed 's/ //g');
			ManifestExistanceOutput="${ManifestExistanceOutput}\n	- As root on ${get_manifest_host}, remove the incorrectly owned manifest.xsl file from ${temp_diag} directory";
		done
		ManifestExistanceOutput="${ManifestExistanceOutput}\n\n---------- Suggested syntax -- test before execution ----------\n";
		temp_arr=(${v_manifest_issues});
		for v_manifest_need_attention in "${temp_arr[@]}"
		do			
			temp_diag=$(echo ${v_manifest_need_attention} |awk -F: '{print $1}' | head -1 | sed 's/ //g');
			temp_user=$(echo ${v_manifest_need_attention} |awk -F: '{print $2}' | head -1 | sed 's/ //g');
			
			ManifestExistanceOutput="${ManifestExistanceOutput}\n	# find ${temp_diag} -name manifest.xsl ! -user ${temp_user} -exec rm -f {} \;";
		done
		
		ManifestExistanceOutput="${ManifestExistanceOutput}\n\n--------------------------------------------------------------";
	fi
	
	#### Required groups
		
	v_group_issues='';
		
	### prepare arrays for aggregation 
	### remove duplicates
	v_missing_required_groups=($(echo "${v_missing_required_groups[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '));
	for v_group_issue in ${v_missing_required_groups[@]}
	do
		get_group_host=`echo ${v_group_issue} | awk -F: '{print $1}' | head -1 | sed 's/ //g'`;
		get_group_user=`echo ${v_group_issue} | awk -F: '{print $2}' | head -1 | sed 's/ //g'`;
		get_group_dba=`echo ${v_group_issue} | awk -F: '{print $3}' | head -1 | sed 's/ //g'`;
		v_group_issues="${v_group_issues} ${get_group_dba}:${get_group_user}";
	done		
	if [[ ${#v_missing_required_groups[@]} -eq 0 ]]; then
		MembershipStatus=0;
		MembershipOutput="${MembershipOutput}\n";
		MembershipOutput="${MembershipOutput}\n3)[Status: PASS] Message: The monitoring user is a member of required OS groups.\n";
        
	else
        MembershipStatus=1;
		MembershipOutput="${MembershipOutput}\n";
		MembershipOutput="${MembershipOutput}\n3)[Status: FAIL] Message: The monitoring user is not a member of required OS groups.";
		MembershipOutput="${MembershipOutput}\n\nAction/Repair:";
		
		v_group_issues=$(echo ${v_group_issues}|awk '{print substr($0,1)}');

		### initialize a temp array of groups to avoid duplicate commands
		declare -a tmp_user_group=();
		temp_arr=(${v_group_issues});
		for v_group_need_attention in "${temp_arr[@]}"
		do
			temp_groups=$(echo ${v_group_need_attention} |awk -F: '{print $1}' | head -1 | sed 's/ //g');
			temp_user=$(echo ${v_group_need_attention} |awk -F: '{print $2}' | head -1 | sed 's/ //g');
			for temp_group in $(echo $temp_groups | tr ',' "\n"); 
			do
				if [[ " ${tmp_user_group[@]} " =~ " ${temp_group} " ]]; then
					continue;
				fi
				tmp_user_group=("${tmp_user_group[@]}" "${temp_group}");
				MembershipOutput="${MembershipOutput}\n	- As root on ${get_group_host}, add user ${temp_user} to ${temp_group} OS groups";
			done
		done
		MembershipOutput="${MembershipOutput}\n\n---------- Suggested syntax -- test before execution ----------\n";	
		
		tmp_user_group=();
		if [ `uname -s` = "Linux" ]
		then			
			for v_group_need_attention in "${temp_arr[@]}"
			do
				temp_groups=$(echo ${v_group_need_attention} |awk -F: '{print $1}' | head -1 | sed 's/ //g');
				temp_user=$(echo ${v_group_need_attention} |awk -F: '{print $2}' | head -1 | sed 's/ //g');
				for temp_group in $(echo $temp_groups | tr ',' "\n"); 
				do
					if [[ " ${tmp_user_group[@]} " =~ " ${temp_group} " ]]; then
						continue;
					fi
					tmp_user_group=("${tmp_user_group[@]}" "${temp_group}");
					MembershipOutput="${MembershipOutput}\n	# usermod -a -G ${temp_group} ${temp_user};";
				done
			done
		else
			### means Solaris
			for v_group_need_attention in "${temp_arr[@]}"
			do
				temp_groups=$(echo ${v_group_need_attention} |awk -F: '{print $1}' | head -1 | sed 's/ //g');
				temp_user=$(echo ${v_group_need_attention} |awk -F: '{print $2}' | head -1 | sed 's/ //g');
				for temp_group in $(echo $temp_groups | tr ',' "\n"); 
				do
					if [[ " ${tmp_user_group[@]} " =~ " ${temp_group} " ]]; then
						continue;
					fi
					tmp_user_group=("${tmp_user_group[@]}" "${temp_group}");
					MembershipOutput="${MembershipOutput}\n	# usermod -G +${temp_group} ${temp_user};";
				done
			done
			
		fi
		
		MembershipOutput="${MembershipOutput}\n\n--------------------------------------------------------------";
	
		
	fi
	
	#### Oracle Agent outdated
		
	v_outdated_issues='';
	
	### prepare arrays for aggregation 
	### remove duplicates
	v_diff_oracle_homes=($(echo "${v_diff_oracle_homes[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '));
	for v_outdated_issue in ${v_diff_oracle_homes[@]}
	do
		get_outdated_host=`echo ${v_outdated_issue} | awk -F: '{print $1}' | head -1 | sed 's/ //g'`;
		get_outdated_instance=`echo ${v_outdated_issue} | awk -F: '{print $2}' | head -1 | sed 's/ //g'`;
		get_old_home=`echo ${v_outdated_issue} | awk -F: '{print $3}' | head -1 | sed 's/ //g'`;
		get_new_home=`echo ${v_outdated_issue} | awk -F: '{print $4}' | head -1 | sed 's/ //g'`;
		v_outdated_issues="${v_outdated_issues} ${get_outdated_instance}:${get_old_home}:${get_new_home}";
	done
		
	
	if [[ ${#v_diff_oracle_homes[@]} -eq 0 ]]; then
		AgentSynchronizedStatus=0;
		AgentSynchronizedOutput="${AgentSynchronizedOutput}\n";
		AgentSynchronizedOutput="${AgentSynchronizedOutput}\n5)[Status: PASS] Message: Monitored target property (Oracle Home) is valid.\n";
        
	else
        AgentSynchronizedStatus=1;
		AgentSynchronizedOutput="${AgentSynchronizedOutput}\n";
		AgentSynchronizedOutput="${AgentSynchronizedOutput}\n5)[Status: FAIL] Message: Monitored target property (Oracle Home) is not valid.";
		v_outdated_issues=$(echo ${v_outdated_issues}|awk '{print substr($0,1)}');		
		AgentSynchronizedOutput="${AgentSynchronizedOutput}\n\nAction/Repair:";
		AgentSynchronizedOutput="${AgentSynchronizedOutput}\nLog a Service Request (SR) to relevant service (Platinum, ADS, etc) Infrastructure team, providing the following details in the SR Description:";
		AgentSynchronizedOutput="${AgentSynchronizedOutput}\n\n---------Begin------------\n";			
		
		temp_arr=(${v_outdated_issues});
		
		if [[ ${#temp_arr[@]} -ne 0 ]]; then
			AgentSynchronizedOutput="${AgentSynchronizedOutput}\nOn ${get_outdated_host}, several Oracle Homes have been changed:";
			for v_outdated_need_attention in "${temp_arr[@]}"
			do			
				temp_instance=$(echo ${v_outdated_need_attention} |awk -F: '{print $1}' | head -1 | sed 's/ //g');
				temp_old_home=$(echo ${v_outdated_need_attention} |awk -F: '{print $2}' | head -1 | sed 's/ //g');
				temp_new_home=$(echo ${v_outdated_need_attention} |awk -F: '{print $3}' | head -1 | sed 's/ //g');
				AgentSynchronizedOutput="${AgentSynchronizedOutput}\n	- ${temp_instance}: from ${temp_old_home} to ${temp_new_home}";
			done
		fi
		AgentSynchronizedOutput="${AgentSynchronizedOutput}\n\nPlease update relevant monitoring attributes on the gateway.\n";
		
		AgentSynchronizedOutput="${AgentSynchronizedOutput}\n\n---------End------------\n";
	fi
	
	
	### Database instances monitored by Oracle Agent
	
	SummaryMonitoredOutput="${SummaryMonitoredOutput}\n";
	SummaryMonitoredOutput="${SummaryMonitoredOutput}\n6)[Status: INFO] Message: Database instances monitored by Oracle Agent.\n";
	SummaryMonitoredOutput="${SummaryMonitoredOutput}\nOn ${SHORT_HOST}:\n";
	if [[ ${#v_monitored_active[@]} -eq 0  && ${#v_monitored_not_active[@]} -eq 0 ]]; then		
		SummaryMonitoredOutput="${SummaryMonitoredOutput} 	- None\n";        
	else
		### get monitored and active databases
		for v_monitored_active_item in "${v_monitored_active[@]}"
		do	
			temp_instance=$(echo ${v_monitored_active_item} |awk -F: '{print $1}' | head -1 | sed 's/ //g');
			temp_home=$(echo ${v_monitored_active_item} |awk -F: '{print $2}' | head -1 | sed 's/ //g');
			SummaryMonitoredOutput="${SummaryMonitoredOutput}	- ${temp_instance} (HOME=${temp_home})\n";
		done
			
		if [[ ${#v_monitored_not_active[@]} -gt 0 ]]; then
			### get monitored and not active databases
			for v_monitored_not_active_item in "${v_monitored_not_active[@]}"
			do	
				temp_instance=$(echo ${v_monitored_not_active_item} |awk -F: '{print $1}' | head -1 | sed 's/ //g');
				temp_home=$(echo ${v_monitored_not_active_item} |awk -F: '{print $2}' | head -1 | sed 's/ //g');
				SummaryMonitoredOutput="${SummaryMonitoredOutput}	- ${temp_instance}** (HOME=${temp_home})\n";
			done
			SummaryMonitoredOutput="${SummaryMonitoredOutput}\nWARNING:";
			SummaryMonitoredOutput="${SummaryMonitoredOutput}\n** Database was not found on the system or has not been scanned.";
			SummaryMonitoredOutput="${SummaryMonitoredOutput}\n** Log a Service Request (SR) to relevant service (Platinum, ADS, etc) Infrastructure team to remove from monitoring if appropriate.";
		fi
	fi
}

print_result()
{
ResultToCheck=$1

case "${ResultToCheck}" in
    Mandatory)
	
		if [ $DiagPermissionsStatus == '9196' ]; then
			finalStatus="9196";  ### skip the checks ( supposed is not Platinum )
		else
			if (($(($AgentActiveStatus + $DiagPermissionsStatus + $ManifestExistanceStatus + $MembershipStatus + $AgentSynchronizedStatus)) > 0)); then
				finalStatus="1";				
			else
				if [[ ${HeaderStatus} -ne 0 ]]; then
					finalStatus="2";
					### means WARN ( not all monitored databases by Oracle Agents are scanned)	
				else				
					### means PASS
					finalStatus="0";					
				fi
			fi
		fi
		echo ${finalStatus};
        ;;
    *) echo "9196" ### skip check
       ;;
  esac
}

print_report()
{
  ReportToPrint=$1
  case "${ReportToPrint}" in
    Mandatory)
       echo -e "${HeaderOutput}${DiagPermissionsOutput}${ManifestExistanceOutput}${MembershipOutput}${AgentActiveOutput}${AgentSynchronizedOutput}${SummaryMonitoredOutput}";
       ;;
    *) echo "" ### skip check
       ;;
   esac
}



check_main()
{
	ChkToPerform=$1
	case "${ChkToPerform}" in
		Mandatory)
		   CheckMandatory;
		   ;;  
		*) echo "9196" ### skip check
		   ;;
	esac
}


## Main Body

NumArgs=$#

if [ $NumArgs -lt 1 ]
then
  echo "9196" ### skip check
fi

while getopts "c:o:h" opt;
do
  case "${opt}" in
    h) usage;
       return 0
       ;;
    c)
       chk=${OPTARG};
       ;;
    o)
       swch=${OPTARG};
       ;;
    *) echo "9196" ### skip check
       ;;
   esac
done

if [ $swch = "check" ]
then
   check_main $chk
   print_result $chk;
elif [ $swch == "report" ]
then
   check_main $chk
   print_report $chk;
else
  echo "9196" ### skip check
fi

