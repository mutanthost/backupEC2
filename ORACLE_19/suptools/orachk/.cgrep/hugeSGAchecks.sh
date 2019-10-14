#!/bin/bash
#
# Objective: To verify and recommend certain initialization parameters when SGA >= 100GB
#
# Team: Oracle RAC Assurance Development Team
# Author: Shirdivas Dharmabhotla
# Date: 18-Sep-2017
# Version: v7
# Platforms supported: Linux & Solaris at the moment.  

# functions

function do_math { 

 $v_awk "BEGIN { print "$*" }";

}

function get_os_and_cpu_info {

 if [ `uname -s` = "Linux" ] ; then
    v_nproc=$(cat /proc/cpuinfo | grep -wc processor)
    v_awk=/bin/awk
 elif [ `uname -s` = "SunOS" ] ; then
   v_nproc=$(/usr/sbin/psrinfo | wc -l | tr -d ' ')
   v_awk=/usr/xpg4/bin/awk
 else
   report_command=$(echo "${report_command}\n Only Linux and Solaris are supported currently")
   v_status=1
 fi

 if [[ ! -z ${v_nproc} ]] ; then 
  # per mos note: 558185.1 total lms can be one less than total process count. However with asm also using one lms process, this needs to be two less than
  v_nproc_lesstwo=$(do_math $v_nproc-2)
 else
  report_command=$(echo "${report_command}\n Unable to obtain processor count")
  v_status=1
 fi

}

function get_db_ver {

  v_dbver=$(echo -e "set heading off feedback off linesize 500 timing off \nselect version from product_component_version where product like 'Oracle Database%';"|$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" | $v_awk -F. '{print $1$2$3$4}' | tr -d ' ')

 v_db_ver=$(echo $v_dbver| $v_awk -F. '{print $1$2$3}' | tr -d ' ')

}

function get_recommended_vals {

 # recommended values per mos note: 1619155.1
 r_gc_policy_min=15000
 r_lm_sync_tout=1200
 r_lm_tickets=5000

}

function get_vars_and_vals {

 # get from instance 

 v_get_params=$(echo -e "set heading off feedback off linesize 500 timing off \nselect name||'='||value from v\$parameter where name in ('_lm_tickets','_lm_sync_timeout','_gc_policy_minimum','shared_pool_size','gcs_server_processes','sga_target');"|$ORACLE_HOME/bin/sqlplus -s "/ as sysdba")

 v_get_hidden_params=$(echo -e "set heading off feedback off linesize 500 timing off \nselect ksppinm||'='||ksppstvl from x\$ksppi a, x\$ksppsv b where a.indx=b.indx and substr(ksppinm,1,1)='_' and ksppinm in ('_lm_sync_timeout','_gc_policy_minimum','_lm_tickets');"|$ORACLE_HOME/bin/sqlplus -s "/ as sysdba")

 v_lms_modified=$(echo -e "set heading off feedback off linesize 500 timing off \nselect to_number(decode(ismodified,'FALSE',1,0)) from v\$parameter where name='gcs_server_processes';" |$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" | tr -d ' ')

 #  derive

 # lms
 v_gcs_server_processes=$(echo "$v_get_params" | sed 's/ /\n/g' | grep -i gcs_server_processes | $v_awk -F= '{print $2}')

 # sga target
 v_sga_target=$(echo "$v_get_params" | sed 's/ /\n/g' | grep -i sga_target | $v_awk -F= '{print $2}')
 v_sga_target_gb=$(do_math $v_sga_target/$v_1gb | $v_awk '{print ($0-int($0)<0.499)?int($0):int($0)+1}')

 # shared pool 
 v_shared_pool_size=$(echo "$v_get_params" | sed 's/ /\n/g' | grep -i shared_pool_size | $v_awk -F= '{print $2}' | $v_awk '{print ($0-int($0)<0.499)?int($0):int($0)+1}')

 if [[ $v_shared_pool_size -eq 0 ]] || [[ -z $v_shared_pool_size ]] ; then
  v_shared_pool_size=$(echo -e "set heading off feedback off linesize 500 timing off \nselect sum(bytes) from v\$sgastat where pool='shared pool';"|$ORACLE_HOME/bin/sqlplus -s "/ as sysdba" | tr -d ' ')
  v_shared_pool_size_gb=$(do_math $v_shared_pool_size/$v_1gb | $v_awk '{print ($0-int($0)<0.499)?int($0):int($0)+1}')
 else
  v_shared_pool_size_gb=$(do_math $v_shared_pool_size/$v_1gb | $v_awk '{print ($0-int($0)<0.499)?int($0):int($0)+1}')
 fi

 # gc policy min 
 v_gc_policy_minimum=$(echo "$v_get_params" | sed 's/ /\n/g' | grep -i _gc_policy_minimum | $v_awk -F= '{print $2}')

 if [[ $v_gc_policy_minimum -eq 0 ]] || [[ -z $v_gc_policy_minimum ]] ; then
  v_gc_policy_minimum=$(echo "$v_get_hidden_params" | sed 's/ /\n/g' | grep -i _gc_policy_minimum | $v_awk -F= '{print $2}')
 fi

 # lm sync timeout  
 v_lm_sync_timeout=$(echo "$v_get_params" | sed 's/ /\n/g' | grep -i _lm_sync_timeout | $v_awk -F= '{print $2}')

 if [[ $v_lm_sync_timeout -eq 0 ]] || [[ -z $v_lm_sync_timeout ]] ; then
  v_lm_sync_timeout=$(echo "$v_get_hidden_params" | sed 's/ /\n/g' | grep -i _lm_sync_timeout | $v_awk -F= '{print $2}')
 fi

 # lm tickets 
 v_lm_tickets=$(echo "$v_get_params" | sed 's/ /\n/g' | grep -i _lm_tickets | $v_awk -F= '{print $2}')

 if [[ $v_lm_tickets -eq 0 ]] || [[ -z $v_lm_tickets ]] ; then
  v_lm_tickets=$(echo "$v_get_hidden_params" | sed 's/ /\n/g' | grep -i _lm_tickets | $v_awk -F= '{print $2}')
 fi
  
}

function validate_params {

 if [[ ${v_sga_target_gb} -ge ${tv_sga_target_gb} ]] ; then

   # shared_pool_size needs to be atleast 15% of sga_target when sga is >= tv_sga_target_gb
   c_shared_pool_size_gb=$(do_math ${v_sga_target_gb}*15/100 | $v_awk '{print ($0-int($0)<0.499)?int($0):int($0)+1}')

   if [[ ${v_shared_pool_size_gb} -lt ${c_shared_pool_size_gb} ]] ; then  
     v_status=1 
     report_command=$(echo "${report_command}\n")
     report_command=$(echo "${report_command}\nSummary:")
     report_command=$(echo "${report_command}\n--------------------------------------------------------------------------------")
     report_command=$(echo "${report_command}\nNode Name: `uname -n`")
     report_command=$(echo "${report_command}\nTotal CPUs: $v_nproc")
     report_command=$(echo "${report_command}\n")
     report_command=$(echo "${report_command}\nInstance Name: $ORACLE_SID")
     report_command=$(echo "${report_command}\n Present value for sga_target is: ${v_sga_target_gb} gb.") 
     report_command=$(echo "${report_command}\n Present value for shared_pool_size is: ${v_shared_pool_size_gb} gb. Recommended value is: ${c_shared_pool_size_gb} gb")
   else
     report_command=$(echo "${report_command}\n")
     report_command=$(echo "${report_command}\nSummary:")
     report_command=$(echo "${report_command}\n--------------------------------------------------------------------------------")
     report_command=$(echo "${report_command}\n`uname -n`: Total CPUs: $v_nproc")
     report_command=$(echo "${report_command}\n")
     report_command=$(echo "${report_command}\n Present value for sga_target is: ${v_sga_target_gb} gb.")
     report_command=$(echo "${report_command}\n Present value for shared_pool_size is: ${v_shared_pool_size_gb} gb meets the recommendation ") 
   fi

   if [[ ${v_gc_policy_minimum} -lt ${r_gc_policy_min} ]] ; then
     v_status=1
     report_command=$(echo "${report_command}\n Present value for _gc_policy_minimum is: ${v_gc_policy_minimum}. Recommended value is: ${r_gc_policy_min}")
   else
     report_command=$(echo "${report_command}\n Present value for _gc_policy_minimum is: ${v_gc_policy_minimum} meets the recommendation ")
   fi

   if [[ ${v_lm_sync_timeout} -lt ${r_lm_sync_tout} ]] ; then
     v_status=1
     report_command=$(echo "${report_command}\n Present value for _lm_sync_timeout is: ${v_lm_sync_timeout}. Recommended value is: ${r_lm_sync_tout}")
   else
     report_command=$(echo "${report_command}\n Present value for _lm_sync_timeout is: ${v_lm_sync_timeout} meets the recommendation ")
   fi

   if [[ ${v_lm_tickets} -lt ${r_lm_tickets} ]] ; then
     v_status=1
     report_command=$(echo "${report_command}\n Present value for _lm_tickets is: ${v_lm_tickets}. Recommended value is: ${r_lm_tickets}")
   else
     report_command=$(echo "${report_command}\n Present value for _lm_tickets is: ${v_lm_tickets} meets the recommendation ")
   fi

   # lms calc

   get_db_ver

   if [[ $v_db_ver -eq 1120 ]] || [[ $v_db_ver -eq 1210 ]] ; then
     v_lms_max=36
   elif [[ $v_db_ver -ge 1220 ]] ; then
     v_lms_max=100
   else
     # for old releases 10.2
     v_lms_max=20
   fi

   dbl_lms=$(do_math 2*$v_gcs_server_processes | tr -d ' ')

   if [[ $dbl_lms -le $v_nproc_lesstwo ]] && [[ $dbl_lms -le $v_lms_max ]] && [[ $v_lms_modified -eq 1 ]] ; then
     r_gcs_server_processes=$(echo $dbl_lms)
   else
     v_status=1
     report_command=$(echo "${report_command}\nUnable to recommend gcs_server_processes")
   fi

   # check for existance of other instances with LMS process(es)
   v_num_inst=$(ps -ef| grep -i ora_lms0 | grep -v grep | wc -l | tr -d ' ')

   # get the total lms count on this node
   v_tot_lms_cnt=$(ps -ef| grep -i ora_lms | grep -v grep | wc -l | tr -d ' ')

   # double them
   v_dbl_lms_cnt=$(do_math 2*$v_tot_lms_cnt | tr -d ' ') 

   if [[ v_dbver -lt 11203 ]] && [[ ${v_num_inst}  -gt 1 ]] ; then
     report_command=$(echo "${report_command}\n Present value for gcs_server_processes: ${v_gcs_server_processes}. Recommended value is: ${r_gcs_server_processes}")
     report_command=$(echo "${report_command}\n")

     if [[ 2*$v_tot_lms_cnt -le $v_nproc_lesstwo ]] ; then

      report_command=$(echo "${report_command}\n")
      report_command=$(echo "${report_command}\n Note: With ${v_num_inst} instances running on `uname -n`, if they too use sga_target (gb) >= ${tv_sga_target_gb} total recommended lms processes ${v_dbl_lms_cnt} will be within the limit of ${v_nproc_lesstwo}")
     else
      report_command=$(echo "${report_command}\n")
      report_command=$(echo "${report_command}\n Note: With ${v_num_inst} instances running on `uname -n`, if they too use sga_target (gb) >= $tv_sga_target_gb please ensure total recommended lms processes ${v_dbl_lms_cnt} <= ${v_nproc_lesstwo}")
     fi
  
   else
     report_command=$(echo "${report_command}\n Present value for gcs_server_processes: ${v_gcs_server_processes}. Recommended value is: ${r_gcs_server_processes} ")
   fi

 else
    report_command=$(echo "${report_command}\n Present value for sga_target: ${v_sga_target_gb} gb is less than ${tv_sga_target_gb} gb. No action needed.")
    v_status=0 
 fi

}

# set variables

# for testing please set ORACLE_SID, ORACLE_HOME, PATH and tv_sga_target_gb.
#export ORACLE_SID=rac12c1
#export ORACLE_HOME=/u01/app/oracle/product/12.1.0.2/dbhome_1
#export PATH=$ORACLE_HOME/bin:$PATH
#tv_sga_target_gb=12

if [[ -z $ORACLE_SID ]] ; then
 report_command=$(echo "${report_command}\nORACLE_SID is not found.")
 v_status=1
 echo -e $report_command
 exit 1
fi

if [[ -z $ORACLE_HOME ]] ; then
 report_command=$(echo "${report_command}\nORACLE_HOME is not found.")
 v_status=1
 echo -e $report_command
 exit 1
fi

v_status=0
v_1gb=1073741824

# pre-req to trigger the validation (enable this for production)
tv_sga_target_gb=100

#
# main section
#

get_os_and_cpu_info

if [[ ${v_status} -ne 1 ]] ; then
 get_vars_and_vals
 get_recommended_vals
 validate_params
fi

echo ${v_status}
echo -e "$report_command"
 
