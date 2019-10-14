#!/bin/bash
#
# $Header: tfa/src/orachk_py/scripts/workload_awr_mon.sh /main/1 2018/11/29 09:23:47 apriyada Exp $
#
# workload_awr_mon.sh
#
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      workload_awr_mon.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#         Purpose: 	To capture, analyze and report abnormal workload (cpu) thresholds
#
#         Author(s):  	Shirdivas Dharmabhotla: Design, Implementation (Scripting) and SQL enhancement
#	              	Peter Bach: Analytic Requirements, SQL logic that performs cpu workload computation and testing
#
#         Team:    	Oracle Autonomous Health and Machine Learning

#      <other useful comments, qualifications, etc.>
#    MODIFIED   (MM/DD/YY)
#    cgirdhar    11/20/18 - script to monitor workload using AWR data
#    cgirdhar    11/20/18 - Creation
#
#
#
#
#
#
compute_average() {

#declare -a v_array
#v_element_pos=4

sum_var=0
avg=0

for num in `seq 0 $v_element_pos` ; do
 sum_var=$(echo $sum_var+${v_array[$num]} | bc -l)
 num=$(echo $num+1 | bc -l)
done

v_avg=$(echo $sum_var/$num | bc -l)

}


# get db response time average from file

get_prev_dbresp_95_percentile() {

if [ -e $v_awr_config_file ] ; then
 v_prev_95_percentile=$(cat $v_awr_config_file | grep -i 'PREV_DBRESPTIME_AVG_'${each_inst_name} | awk -F= '{print $2}')
else
echo "AWR Config file does not exist. Exiting.."
exit 1
fi
}

# generate 95th percentile of db response time per call (ms)

gen_95th_percentile() {

 # read the awr config file
 parse_awr_config_file

 # declare an array to hold the values
 declare -a v_array

 # Get the number of Instances for this DB from os data file..
 v_inst_list=$(cat ${v_awr_data_file} | grep -v '#' | grep -vi inst_no | awk -F, '{print $25}' | sort | uniq | sed 's/ //g')

 if [[ -z $v_inst_list ]] ; then
  echo
  echo "No AWR Data to generate 95th Percentile..Exiting.."
  echo
  exit 1
 fi

 # loop through each instance
 for each_inst_name in $v_inst_list ; do

  # get previous 95 percentile for db response time per call (ms)
  get_prev_dbresp_95_percentile

  # get the number of records for a given instance. Here $5 is the inst_id and $6 is the snap_id
  v_num_rec=$(cat ${v_awr_data_file} | grep -v '#' | awk -v inst_name=$each_inst_name -F, '$25==inst_name {print $18}' | wc -l)

  # if no records found, exit..
  if [[ $v_num_rec -eq 0 ]] ; then
   echo "No new snap id's to analyze.Exiting.."
   exit 1
  fi

  # calculate the 95th percentile (rounded) for the above data
  v_95_percentile=$(awk -v numrec=$v_num_rec 'BEGIN {rounded = sprintf("%.0f", numrec * 0.95); print rounded }')

  # element position to look for. This will be one less since the array position starts from 0.
  v_element_pos=$((${v_95_percentile} - 1))

  # sort the records. $18 is db_resp_time. $25 is inst_name
  v_db_resp_time_vals=$(cat ${v_awr_data_file} | grep -v '#' | awk -v inst_name=$each_inst_name -F, '$25==inst_name {print $18}' | sort -n)

  # converting into an array so we can compute the average
  v_array=(${v_db_resp_time_vals})

  # array index starts from 0. Hence the element to look for is (v_95_percentile-1)
  # v_curr_95_percentile=$(echo ${v_array[$v_element_pos]})

  # instead of 95th percentile element, we will be better off with average of elements that fall within 95th element.
  compute_average

  # round up the value for easy computation
  v_avg_roundup=$(echo $v_avg | awk '{print int($1) + ( $1 != int($1) && $1 >= 0 )}') 

  echo
  echo "Average DB Response Time Per call (ms), rounded up: $v_avg_roundup"
  echo
  # update the awr config file with the average of values that fall within 95th percentile
  sed -i "s/PREV_DBRESPTIME_AVG_${each_inst_name}=$v_prev_95_percentile/PREV_DBRESPTIME_AVG_${each_inst_name}=$v_avg_roundup/" ${v_awr_config_file}

  echo "Done updating the AWR config file."
  echo
 done

}


# Look for snaps with abnormally high cpu usage
#
analyze_awr_data() {

 # read the awr config file
 #echo "Reading the AWR Config file..."
 parse_awr_config_file

# Get abnormal factor to check for from the config file
 v_abnormal_factor=$(cat ${v_awr_config_file} | grep -v '#' | grep -i ABNORMAL_INCREASE | awk -F= '{print $2}')

 # Get the number of Instances for this DB from os data file..
 #echo "Obtaining the list of instances from the AWR data file..."
 v_inst_list=$(cat ${v_awr_data_file} | grep -v '#' | grep -vi inst_no | awk -F, '{print $25}' | sort | uniq | sed 's/ //g')

 if [[ -z $v_inst_list ]] ; then
  echo "No Instance Data to Analyze..Exiting.."
  exit 1
 fi

 # loop through each instance 
 for each_inst_name in $v_inst_list ; do

  # get prev max snap id from config file. If it's value is zero, it means capture_awr_data was not run yet.
  get_prev_max_snap_id

  if [[ ${v_prev_max_snap_id} -eq 0 ]] ; then
   echo "capture_awr_data step needs to be run prior to analyze_awr_data. Exiting.."
   exit 1
  fi

  # get the last analyzed snap id
  get_prev_snap_id_analyzed

  # get the number of records for a given instance. Here $5 is the inst_id and $6 is the snap_id
  v_num_rec=$(cat ${v_awr_data_file} | grep -v '#' | awk -v inst_name=$each_inst_name -v prev_snap_analyzed=$v_prev_snap_id_analyzed -F, '$25==inst_name && $6>prev_snap_analyzed {print $18}' | wc -l)

  # if no records found, exit..
  if [[ $v_num_rec -eq 0 ]] ; then
   echo "No new snap id's to analyze.Exiting.."
   exit 1
  fi

  # calculate the 95th percentile (rounded) for the above data
  get_prev_dbresp_95_percentile

  if [[ $v_prev_95_percentile -eq 0 ]] ; then
   echo "gen_95th_percentile wasn't run. Running it now..."
   gen_95th_percentile
   get_prev_dbresp_95_percentile
  fi

  # Abnormal cpu usage factor.
  v_abnormal_cpu_usage_factor=$(awk -v v_abnormal_factor=$v_abnormal_factor -v v_prev_95_percentile=$v_prev_95_percentile 'BEGIN {rounded = sprintf("%.0f", v_abnormal_factor * v_prev_95_percentile); print rounded}')

  # Get any snap ids that captures such abnormal cpu usage factor

  v_abnormal_cpu_usage_snap_ids=$(cat ${v_awr_data_file} | grep -v '#' | awk -v inst_name=$each_inst_name -v prev_snap_analyzed=$v_prev_snap_id_analyzed -v v_abnormal_cpu_usage_factor=$v_abnormal_cpu_usage_factor -F, '$25==inst_name && $6>prev_snap_analyzed && $18>v_abnormal_cpu_usage_factor {print $6}')

  if [[ x$v_abnormal_cpu_usage_snap_ids = 'x' ]] ;then

   echo
   echo "Analysis Summary (Beta):"
   echo "------------------------"
   echo
   echo "Instance $each_inst_name : No Abnormal Thresholds found "
   echo
   v_result=0

  else
   v_result=100
   echo
   echo "Analysis Summary (Beta):"
   echo "------------------------"
   echo
   echo "Instance $each_inst_name : Abnormal Thresholds found."
   echo
   echo -e "INST_NAME  SNAP_ID  SNAP_START_TIME\t\tAASPC\tAAS_CPU_PC\tDB_RESP_TIME_PC_MS\tUSER_CALLS_PS\tTPS\t  CPU_BOUND  DBWORKLOAD"

   # Also check if there are any CPU bound snap ids

   v_aas_cpu_per_core_threshold_100=$(echo $v_aas_cpu_per_core_threshold 100 | awk '{printf ("%.0f", $1*$2)}')

   for each_snap_id in ${v_abnormal_cpu_usage_snap_ids} ; do
      v_aas_cpu_pc=$(cat ${v_awr_data_file} | grep -v '#' | awk -v inst_name=$each_inst_name -v v_snap_id=$each_snap_id -F, '$25==inst_name && $6==v_snap_id {print $15}')

      # check for duplicate records with same snap id. If so, let user know and exit.

      # declare an array 
      declare -a v_snap_arr
      v_snap_arr=(${v_aas_cpu_pc})

      v_snap_cnt=${#v_snap_arr[@]}

      if [[ ${v_snap_cnt} -gt 1 ]] ; then
       echo "Duplicate records found for snap id: $each_snap_id. Exiting.."
       exit 100
      fi

      # convert into an integer for comparison 
      v_aas_cpu_pc_100=$(echo $v_aas_cpu_pc 100 | awk '{printf ("%.0f", $1*$2)}')

      v_read_rt=$(cat ${v_awr_data_file} | grep -v '#' | awk -v inst_name=$each_inst_name -v v_snap_id=$each_snap_id -F, '$25==inst_name && $6==v_snap_id {print $25,"  ",$6,"\t",$7,"  ",$14,"\t",$15,"\t\t",$18,"\t\t",$16,"\t\t",$17}')

      v_aaspc_rt=$(echo $v_read_rt | awk '{print $4}')
      v_aaspc_rt_100=$(echo $v_aaspc_rt 100 | awk '{printf ("%.0f", $1*$2)}')

      # convert AAS_PER_CORE_THRESHOLD into an integer for comparison
      v_aas_per_core_threshold_100=$(echo $v_aas_per_core_threshold 100 | awk '{printf ("%.0f", $1*$2)}')

     # cpu_bound & db workload high: yes or no


     if [[ $v_aas_cpu_pc_100 -gt $v_aas_cpu_per_core_threshold_100 ]] && [[ $v_aaspc_rt_100 -gt $v_aas_per_core_threshold_100 ]] ; then

        v_output=$(cat ${v_awr_data_file} | grep -v '#' | awk -v inst_name=$each_inst_name -v v_snap_id=$each_snap_id -v v_cpu_bound=Yes -v v_db_wl_high=High -F, '$25==inst_name && $6==v_snap_id {print $25,"  ",$6,"\t",$7,"  ",$14,"\t",$15,"\t\t",$18,"\t\t",$16,"\t\t",$17,"\t\t",v_cpu_bound,"  ",v_db_wl_high}')

         v_cb=true
         v_wlh=true

     elif [[ $v_aas_cpu_pc_100 -lt $v_aas_cpu_per_core_threshold_100 ]] && [[ $v_aaspc_rt_100 -lt $v_aas_per_core_threshold_100 ]] ; then

        v_output=$(cat ${v_awr_data_file} | grep -v '#' | awk -v inst_name=$each_inst_name -v v_snap_id=$each_snap_id -v v_cpu_bound=No  -v v_db_wl_high=Not_High  -F, '$25==inst_name && $6==v_snap_id {print $25,"  ",$6,"  ",$7,"\t",$14,"\t",$15,"\t\t",$18,"\t\t",$16,"\t\t",$17,"\t\t",v_cpu_bound,"  ",v_db_wl_high}')

        if [[ ! $v_cb == "true" ]] ; then 
          v_cb=false
        fi

        if [[ ! $v_wlh == "true" ]] ; then
          v_wlh=false
        fi

     elif [[ $v_aas_cpu_pc_100 -gt $v_aas_cpu_per_core_threshold_100 ]] && [[ $v_aaspc_rt_100 -lt $v_aas_per_core_threshold_100 ]] ; then

        v_output=$(cat ${v_awr_data_file} | grep -v '#' | awk -v inst_name=$each_inst_name -v v_snap_id=$each_snap_id -v v_cpu_bound=Yes  -v v_db_wl_high=Not_High  -F, '$25==inst_name && $6==v_snap_id {print $25,"  ",$6,"  ",$7,"\t",$14,"\t",$15,"\t\t",$18,"\t\t",$16,"\t\t",$17,"\t\t",v_cpu_bound,"  ",v_db_wl_high}')

	 v_cb=true

         if [[ ! $v_wlh == "true" ]] ; then
          v_wlh=false
         fi

     elif [[ $v_aas_cpu_pc_100 -lt $v_aas_cpu_per_core_threshold_100 ]] && [[ $v_aaspc_rt_100 -gt $v_aas_per_core_threshold_100 ]] ; then

        v_output=$(cat ${v_awr_data_file} | grep -v '#' | awk -v inst_name=$each_inst_name -v v_snap_id=$each_snap_id -v v_cpu_bound=No  -v v_db_wl_high=High  -F, '$25==inst_name && $6==v_snap_id {print $25,"  ",$6,"  ",$7,"\t",$14,"\t",$15,"\t\t",$18,"\t\t",$16,"\t\t",$17,"\t\t",v_cpu_bound,"  ",v_db_wl_high}')

        v_wlh=true

        if [[ ! $v_cb == "true" ]] ; then
         v_cb=false
        fi

     else

       echo "Unknown situation in calculating cpu_bound or db workload being high..Exiting.."
       exit 100

     fi

     # this is the variable that output anomaly data
     echo "$v_output"

   done

     echo
     echo "NOTE: Please review DB_RESP_TIME_PC_MS and capture AWR reports during this period to investigate."

     if [[ $v_cb == "true" ]] ; then
      echo "NOTE: If CPU_BOUND=Yes, then review relevant AWR report to identify SQL(s) by CPU time and optimize by reducing the number of calls or provision more CPU(s) to improve user experience/scalability."
     fi

     if [[ $v_wlh == "true" ]] ; then
      echo "NOTE: If DBWORKLOAD=High, then review relevant AWR report for optimization opportunities or validate current resource manager usage/setup."
     fi

  fi

  update_prev_snap_id_analyzed

 done

}

# get instances names

get_db_instances_names() {

v_db_inst_names=$($ORACLE_HOME/bin/sqlplus -S /nolog <<SQL
WHENEVER OSERROR EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;
connect / as sysdba
set head off
set feed off
select distinct instance_name from gv\$instance;
quit
SQL
)

# if for any reason, the sqlplus operation isn't successful, exit.
if [[ ! $? -eq 0 ]] ; then
 echo "Unable to get instance(s) from the database. Exiting.."
 exit 1
fi

}

# parse the awr config file for thresholds

parse_awr_config_file() {

if [ -e ${v_awr_config_file} ] ; then
 # get the snap interval
 v_awr_snap_interval=$(cat ${v_awr_config_file} | grep -v '#' | grep -i AWR_SNAP_INTERVAL | awk -F= '{print $2}')

 # get the aas per core threshold
 v_aas_per_core_threshold=$(cat ${v_awr_config_file} | grep -v '#' | grep -i AAS_PER_CORE_THRESHOLD | awk -F= '{print $2}')

 # get the avg active session cpu per core threshold
 v_aas_cpu_per_core_threshold=$(cat ${v_awr_config_file} | grep -v '#' | grep -i AAS_CPU_PER_CORE_THRESHOLD | awk -F= '{print $2}')

 # get the snap file location
 v_awr_snap_file_loc=$(cat ${v_awr_config_file} | grep -v '#' | grep -i AWR_SNAP_FILE_LOC | awk -F= '{print $2}')

 # get the snap data file location
 v_awr_snap_data_file=$(cat ${v_awr_config_file} | grep -v '#' | grep -i AWR_SNAP_DATA_FILE | awk -F= '{print $2}')

else
 echo "AWR Config file does not exist. Exiting..."
 exit 1
fi

}


# get prev max snap id from file

get_prev_max_snap_id() {

if [ -e $v_awr_config_file ] ; then
 v_prev_max_snap_id=$(cat $v_awr_config_file | grep -i 'PREV_MAX_SNAP_ID_'${each_inst_name} | awk -F= '{print $2}')
else
echo "AWR Config file does not exist. Exiting.."
exit 1
fi
}

get_prev_snap_id_analyzed() {

if [ -e $v_awr_config_file ] ; then
 # get the last snap id that was analyzed
v_prev_snap_id_analyzed=$(cat ${v_awr_config_file} | grep -i 'PREV_SNAP_ID_ANALYZED_'${each_inst_name} | awk -F= '{print $2}')
else
 echo "AWR Config file does not exist. Exiting.."
 exit 1
fi
}


# In a RAC environment, each instance will have it's own snap id. Get current max snap id for that instance

get_current_max_snap_id() {

v_curr_max_snap_id=$($ORACLE_HOME/bin/sqlplus -S /nolog <<SQL
WHENEVER OSERROR EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;
connect / as sysdba
set head off
set feed off
select max(snap_id) snap_id from dba_hist_snapshot where instance_number=(select distinct instance_number from gv\$instance where instance_name='${each_inst_name}');
quit
SQL
)

# if for any reason, the sqlplus operation isn't successful, exit. otherwise get the value.
if [[ $? -eq 0 ]] ; then
 v_curr_max_snap_id=$(echo ${v_curr_max_snap_id} | sed 's/ //g' )
else
 echo "Unable to get current max snap id. Exiting.."
 exit 1
fi

}

# update previous max snap id in file

update_prev_max_snap_id() {

get_prev_max_snap_id

if [[ ${v_curr_max_snap_id} -gt ${v_prev_max_snap_id} ]] ; then
 # get the previous max snap id from awr config file.
 sed -i "s/PREV_MAX_SNAP_ID_${each_inst_name}=$v_prev_max_snap_id/PREV_MAX_SNAP_ID_${each_inst_name}=$v_curr_max_snap_id/" ${v_awr_config_file}
else
 echo "        No change in previous max snap id. Hence no update done."
fi

}

# update previous snap id analyzed in file

update_prev_snap_id_analyzed() {

get_prev_snap_id_analyzed
#get_current_max_snap_id
get_prev_max_snap_id

if [[ ${v_prev_max_snap_id} -gt ${v_prev_snap_id_analyzed} ]] ; then
 # get the previous snap id that was analyzed..
 sed -i "s/PREV_SNAP_ID_ANALYZED_${each_inst_name}=$v_prev_snap_id_analyzed/PREV_SNAP_ID_ANALYZED_${each_inst_name}=$v_prev_max_snap_id/" ${v_awr_config_file}
else
 echo "No change in previous max snap id analyzed. Hence no update done." 
fi

}

# get awr data

capture_awr_data() {

# get the db name from db.
echo "Obtaining the database name..."
get_db_name

# read the parameters
echo "Reading AWR configuration file..."
parse_awr_config_file

# get the instances names from the database
echo "Obtaining the instances names from the database..."
get_db_instances_names

# enter for loop
for each_inst_name in $v_db_inst_names ; do

# from the awr config file
echo "${each_inst_name}:"
echo "	Obtaining previous max snap id for ${each_inst_name} from AWR config file..."
get_prev_max_snap_id

# we need to obtain this from DB prior to issuing the query so subsequent runs will pick up right snap id.
echo "	Obtaining current max snap id for ${each_inst_name} from the database..."
get_current_max_snap_id

# the following part will capture the snap data from db workload repository table.
echo "	Querying AWR history data as per thresholds for ${each_inst_name}. It could take time..."

v_awr_data=$($ORACLE_HOME/bin/sqlplus -S /nolog <<SQL
WHENEVER OSERROR EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;
connect / as sysdba
/*------------------------------------------------------------------------------
 *
 * This script is a PoC for AWR and workload analysis. and we will later
 * have to be re-write script to utilize PDB and con_id (12c).
 * 
 * Used LAG function to deal with none sequential snap id's and database startup 
 * time.  
 * snap = awr snap metadata data
 * osb   = os stat base begin snap variables
 * ose   = os stat base end snap variables
 * stmb = system time model base begin snap variables
 * stme = system time model base end snap variables
 * sysb   = sysstat base begin snap variables
 * syse   = sysstat base end snap variables
 * 
 * Notes to implementing Development team:
 * There will be additional metadata for cloud provisioning that needs to be added
 * like Customer, Region, Availability Domain, Rack, Cluster, Node, CDB, PDB.
 * This data is likely to be available on provisioned Cloud deployment in file-system.
 */
set head off
set feed off
set lines 20000
set pagesize 0
set pages 9999
set linesize 32000
set long 1000000

SELECT '${v_datetime},'||'${v_uname},'||'${v_dbname},'||DBID||','||INST_NO||','||SNAP_ID||','||SNAP_START_TIME||','||SNAP_END_TIME||','||SNAP_DUR_SEC||','||SNAP_DB_TIME_SEC||','||SNAP_DB_CPU_TIME_SEC||','||TOTAL_OS_CPU_SEC||','||AAS||','||AASPC||','||AAS_CPU_PC||','||USER_CALLS_PS||','||TPS_PS||','||DB_RESP_TIME_PER_CALL_MS||','||NO_CPU||','||CPU_CORES||','||OS_LOAD||','||OS_CPU_PCT||','||CPU_USR_PCT||','||CPU_SYS_PCT||','||'${each_inst_name}' FROM (
with snap_base 
  -- Get the AWR snap metadata data, one row for each snap id
  as (SELECT s.dbid,
             s.instance_number,
                s.snap_id,
             LAG(s.snap_id) OVER (PARTITION BY s.dbid, s.instance_number ORDER BY s.snap_id DESC) next_snap_id,
             s.startup_time,
             LAG(s.startup_time) OVER (PARTITION BY s.dbid, s.instance_number ORDER BY s.snap_id DESC) next_startup_time,           
             s.begin_interval_time,
                s.end_interval_time,
             s.snap_level,
             s.snap_timezone
        FROM dba_hist_snapshot s),
  stm_begin
  -- Get the AWR system time model base begin snap data
  as ( SELECT *
            FROM ( SELECT stm.dbid,
                          stm.instance_number,
                          stm.snap_id,
                          stm.stat_name,
                          stm.value
                     FROM dba_hist_sys_time_model stm )
                    PIVOT (sum (value)
                      FOR stat_name
                       IN ('DB time'                        AS db_time,
                           'DB CPU'                         AS db_cpu_time))), 
  stm_end
  -- Get the AWR system time model base end snap data
  as ( SELECT *
            FROM ( SELECT stm.dbid,
                          stm.instance_number,
                          stm.snap_id,
                          stm.stat_name,
                          stm.value
                     FROM dba_hist_sys_time_model stm )
                    PIVOT (sum (value)
                      FOR stat_name
                       IN ('DB time'                        AS db_time,
                           'DB CPU'                         AS db_cpu_time))),  
  osstat_base_begin
  -- Get the AWR OS statistics begin snap data 
  as ( SELECT * 
         FROM ( SELECT os.dbid,
                       os.instance_number,
                       os.snap_id,
                       os.stat_name,
                       os.value
                  FROM dba_hist_osstat os ) 
                 PIVOT (sum (value)
                   FOR stat_name
                    IN ('NUM_CPUS'               AS num_cpus,
                        'NUM_CPU_CORES'          AS num_cpu_cores,
                        'NUM_LCPUS'              AS num_logical_cpu,
                        'NUM_CPU_SOCKET'         AS num_cpu_sockets,
                        'LOAD'                   AS os_load,
                        'BUSY_TIME'              AS cpu_busy_time,
                        'IDLE_TIME'              AS cpu_idle_time,
                        'USER_TIME'              AS cpu_user_time,
                        'SYS_TIME'               AS cpu_sys_time,
                        -- 'IOWAIT_TIME'            AS cpu_io_wait_time,
                        'RSRC_MGR_CPU_WAIT_TIME' AS rsrc_mgr_cpu_wait_time, 
                        'OS_CPU_WAIT_TIME'       AS os_cpu_wait_time,
                        'PHYSICAL_MEMORY_BYTES'  AS physical_memory_bytes,   
                        'VM_IN_BYTES'            AS v_mem_paged_in_bytes,  
                        'VM_OUT_BYTES'           AS v_mem_paged_out_bytes ))),
   osstat_base_end
   -- Get the AWR OS statistics end snap data
   as ( SELECT * 
          FROM ( SELECT os.dbid,
                        os.instance_number,
                        os.snap_id,
                        os.stat_name,
                        os.value
                   FROM dba_hist_osstat os ) 
                  PIVOT (sum (value)
                    FOR stat_name
                     IN ('LOAD'                   AS os_load,
                         'BUSY_TIME'              AS cpu_busy_time,
                         'IDLE_TIME'              AS cpu_idle_time,
                         'USER_TIME'              AS cpu_user_time,
                         'SYS_TIME'               AS cpu_sys_time,
                         -- 'IOWAIT_TIME'            AS cpu_io_wait_time,
                         'RSRC_MGR_CPU_WAIT_TIME' AS rsrc_mgr_cpu_wait_time, 
                         'OS_CPU_WAIT_TIME'       AS os_cpu_wait_time,
                         'VM_IN_BYTES'            AS v_mem_paged_in_bytes,  
                         'VM_OUT_BYTES'           AS v_mem_paged_out_bytes ))),
   sysstat_base_begin
   -- Get the AWR system statistics begin snap data 
   as ( SELECT *
          FROM ( SELECT s2.dbid,
                        s2.instance_number,
                        s2.snap_id,
                        s2.stat_name,
                        s2.value
                   FROM dba_hist_sysstat s2)
                  PIVOT (sum (value)
                    FOR stat_name
                     IN ('DB time'               AS db_time,
                         'logons current'        AS sessions,
                         'execute count'         AS executions,
                         'redo size'             AS iops_redo_b,
                         'user calls'            AS user_calls,
                         'user commits'          AS user_commits,
                         'transaction rollbacks' AS rollbacks))),                       
   sysstat_base_end
   -- Get the AWR system statistics end snap data 
   as ( SELECT *
          FROM ( SELECT s3.dbid,
                        s3.instance_number,
                        s3.snap_id,
                        s3.stat_name,
                        s3.value
                   FROM dba_hist_sysstat s3)
                  PIVOT (sum (value)
                    FOR stat_name
                     IN ('DB time'               AS db_time,
                         'logons current'        AS sessions,
                         'execute count'         AS executions,
                         'redo size'             AS iops_redo_b,
                         'user calls'            AS user_calls,
                         'user commits'          AS user_commits,
                         'transaction rollbacks' AS rollbacks)))
  -- Join above AWR data views and get the delta values
  SELECT snap.dbid,
         snap.instance_number as inst_no,
         snap.snap_id,
         TO_CHAR(snap.begin_interval_time,'DD-Mon-YYYY_HH24:MI:SS') as snap_start_time,
         TO_CHAR(snap.end_interval_time,'DD-Mon-YYYY_HH24:MI:SS') as snap_end_time,
         ROUND( ( CAST( snap.end_interval_time AS DATE ) - CAST( snap.begin_interval_time AS DATE ) ) * 86400 ,2) as snap_dur_sec,
         ROUND( (stme.db_time - stmb.db_time) / 1000000 ,2 ) AS snap_db_time_sec,
         ROUND( (stme.db_cpu_time - stmb.db_cpu_time) / 1000000 ,2 ) AS snap_db_cpu_time_sec,
         (ose.cpu_busy_time - osb.cpu_busy_time) / 100 as total_os_cpu_sec,          
         ROUND((stme.db_time - stmb.db_time) / 1000000 / (( CAST( snap.end_interval_time AS DATE ) - CAST( snap.begin_interval_time AS DATE ) ) * 86400) ,2) as aas,
         ROUND((stme.db_time - stmb.db_time) / 1000000 / (( CAST( snap.end_interval_time AS DATE ) - CAST( snap.begin_interval_time AS DATE ) ) * 86400 * osb.num_cpu_cores) ,2) as aaspc, 
         ROUND((stme.db_cpu_time - stmb.db_cpu_time) / 1000000 / (( CAST( snap.end_interval_time AS DATE ) - CAST( snap.begin_interval_time AS DATE ) ) * 86400 * osb.num_cpu_cores) ,2) as aas_cpu_pc,
         ROUND( (syse.user_calls - sysb.user_calls) / (( CAST( snap.end_interval_time AS DATE ) - CAST( snap.begin_interval_time AS DATE ) ) * 86400 ) ,2) as user_calls_ps,
         ROUND( ((syse.user_commits - sysb.user_commits) + (syse.rollbacks - sysb.rollbacks)) / (( CAST( snap.end_interval_time AS DATE ) - CAST( snap.begin_interval_time AS DATE ) ) * 86400 ) ,2) tps_ps,
         ROUND( ((stme.db_time - stmb.db_time) / 1000 ) / (syse.user_calls - sysb.user_calls),4) as db_resp_time_per_call_ms,    -- SQL Trace to cross validate.
         osb.num_cpus as no_cpu,
         osb.num_cpu_cores as cpu_cores ,
         ROUND(ose.os_load,2) os_load,
         ROUND( ( ( (ose.cpu_busy_time - osb.cpu_busy_time) / 100 ) / ( ( CAST( snap.end_interval_time AS DATE ) - CAST( snap.begin_interval_time AS DATE ) ) * 86400 * osb.num_cpu_cores) * 100 ) ) as os_cpu_pct,
         ROUND( ( ( (ose.cpu_user_time - osb.cpu_user_time) / 100 ) / ( ( CAST( snap.end_interval_time AS DATE ) - CAST( snap.begin_interval_time AS DATE ) ) * 86400 * osb.num_cpu_cores) * 100 ) ) as cpu_usr_pct,
         ROUND( ( ( (ose.cpu_sys_time - osb.cpu_sys_time) / 100 ) / ( ( CAST( snap.end_interval_time AS DATE ) - CAST( snap.begin_interval_time AS DATE ) ) * 86400 * osb.num_cpu_cores) * 100 ) ) as cpu_sys_pct
         -- ROUND( ( ( (ose.cpu_io_wait_time - osb.cpu_io_wait_time ) / 100 ) / ( ( CAST( snap.end_interval_time AS DATE ) - CAST( snap.begin_interval_time AS DATE ) ) * 86400 * osb.num_cpu_cores) * 100 ) ) as "CPU IO Wait (%)" -- Feedback from GW, cpu io wait time figures from Linux are not accurate
    FROM snap_base snap, osstat_base_begin osb, osstat_base_end ose, stm_begin stmb, stm_end stme, sysstat_base_begin sysb, sysstat_base_end syse 
   WHERE snap.snap_id         = osb.snap_id
     AND snap.dbid            = osb.dbid
     AND snap.instance_number = osb.instance_number
     AND snap.next_snap_id    = ose.snap_id
     AND snap.dbid            = ose.dbid
     AND snap.instance_number = osb.instance_number
     AND snap.snap_id         = stmb.snap_id
     AND snap.dbid            = stmb.dbid
     AND snap.instance_number = stmb.instance_number
     AND snap.next_snap_id    = stme.snap_id
     AND snap.dbid            = stme.dbid
     AND snap.instance_number = stme.instance_number
     AND snap.snap_id         = sysb.snap_id
     AND snap.dbid            = sysb.dbid
     AND snap.instance_number = sysb.instance_number
     AND snap.next_snap_id    = syse.snap_id
     AND snap.dbid            = syse.dbid
     AND snap.instance_number = syse.instance_number 
     AND snap.startup_time    = snap.next_startup_time
	AND snap.snap_id IN (select distinct s.snap_id from dba_hist_snapshot s where s.snap_id > ${v_prev_max_snap_id})
     AND snap.instance_number = (select distinct instance_number from gv\$instance where instance_name='${each_inst_name}')
  ORDER BY snap.dbid, snap.instance_number, snap.snap_id DESC)
 WHERE aaspc >= ${v_aas_per_core_baseline}
 OR aas_cpu_pc >= ${v_aas_cpu_per_core_threshold} 
	;
quit
SQL
)

if [[ ! -z $v_awr_data ]] && [[ $? -eq 0 ]] ; then
 echo "        Spooling AWR data,if any, into $v_awr_snap_data_file"
 echo "$v_awr_data" >> $v_awr_snap_file_loc/$v_awr_snap_data_file
 echo "        Updating Max Snap Id into the config file."
 update_prev_max_snap_id
elif [[ -z $v_awr_data ]] ; then
 echo
 echo "	NOTE: There are no awr snapshots that match the baseline/thresholds.."
 echo "        Updating Max Snap Id into the config file."
 update_prev_max_snap_id
else
 echo " Unknown exception occurred while obtaining AWR data from database. Exiting.."
 exit 1
fi

done
echo
echo "Finished running AWR capture process..."
echo
}


# get help

help() {
 echo
 echo "HELP:"
 echo
 echo "01. Setup AWR:"
 echo "$0 setup \$ORACLE_SID \$ORACLE_HOME \$AWR_CONFIG_DIR"
 echo
 echo "02. Capture AWR snapshot data:"
 echo "$0 capture \$ORACLE_SID \$ORACLE_HOME \$AWR_CONFIG_DIR"
 echo
 echo "03. Generate Avg DB response time per call:"
 echo "$0 baseline \$ORACLE_SID \$ORACLE_HOME \$AWR_CONFIG_DIR"
 echo
 echo "04. Analyze AWR data:"
 echo "$0 analyze \$ORACLE_SID \$ORACLE_HOME \$AWR_CONFIG_DIR"
 echo
 echo "Disclaimer: "
 echo "This version of script will identify outliers based on functionality around DB workload and average DB response time per call.  This script should identify outliers well for OLTP and OLAP types of DB workloads, however there is a risk, that for mixed DB OLTP/OLAP workloads, the baseline will be skewed and OLAP DB workload would be identified as outliers.  This is a known behavior and it is the intention that it will be fixed in future release."
 echo
}


# get db name

get_db_name() {
v_dbname=$(${ORACLE_HOME}/bin/sqlplus -S /nolog <<SQL
WHENEVER OSERROR EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;
connect / as sysdba
set head off
select name from v\$database;
quit
SQL
)

# if you can't get the db name, exit..
if [[ $? -eq 0 ]] ; then
 v_dbname=$(echo ${v_dbname} | sed 's/ //g')
else
 echo "Unable to get db name. Exiting.."
 exit 1
fi

}


# check awr snap retention in days

check_awr_snap_retention() {

awr_snap_ret_req=14
awr_snap_ret_recomm=30

v_awr_snap_ret=$(${ORACLE_HOME}/bin/sqlplus -S /nolog <<SQL
WHENEVER OSERROR EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;
connect / as sysdba
set head off
select extract(day from retention) from dba_hist_wr_control;
quit
SQL
)

# if you can't get the interval in minutes, exit.
if [[ $? -eq 0 ]] ; then
 v_awr_snap_ret=$(echo $v_awr_snap_ret | sed 's/ //g')
else
 echo "Unable to get awr snap retention. Exiting.."
 exit 1
fi

# validate the retention requirement

if [[ $v_awr_snap_ret -lt $awr_snap_ret_req ]] ; then
 echo
 echo "Found AWR snapshot retention of $v_awr_snap_ret. Minimum required retention is $awr_snap_ret_req days for baseline. Exiting.."
 echo
 exit 1
elif [[ $v_awr_snap_ret -eq $awr_snap_ret_req ]] && [[ $v_awr_snap_ret -lt $awr_snap_ret_recomm ]] ; then
 echo
 echo "Found AWR snapshot retention of $v_awr_snap_ret days. We recommend >= $awr_snap_ret_recomm days for better results."
else
 echo
 echo "Found AWR snapshot retention of $v_awr_snap_ret days. Proceeding.."
fi

}



# get awr snap interval in minutes

get_awr_snap_interval() {

v_awr_snap_interval=$(${ORACLE_HOME}/bin/sqlplus -S /nolog <<SQL
WHENEVER OSERROR EXIT FAILURE;
WHENEVER SQLERROR EXIT FAILURE;
connect / as sysdba
set head off
select extract(day from snap_interval)*24*60 + extract(hour from snap_interval)*60 + extract(minute from snap_interval) from dba_hist_wr_control;
quit
SQL
)

# if you can't get the interval in minutes, exit.
if [[ $? -eq 0 ]] ; then
 v_awr_snap_interval=$(echo $v_awr_snap_interval | sed 's/ //g')
else
 echo "Unable to get awr snap interval. Exiting.."
 exit 1
fi

}


# create awr config file

generate_awr_files() {

echo
echo "Note: Please ensure all instances of a RAC DB are Online prior to generating the configuration files."
echo
sleep 1

if [ ! -e ${v_awr_config_file} ] ; then

get_db_name
get_db_instances_names
get_awr_snap_interval

echo
echo "Creating AWR Configuration file ${v_awr_config_file}"

echo "#==============================================================================#" >> ${v_awr_config_file}
echo "#AWR_WORKLOAD_CONFIG_FILE_"${v_dbname} | sed 's/ //g' >> ${v_awr_config_file}
echo "#" >> ${v_awr_config_file}
echo "#BEGIN: HEADER ZONE:" >> ${v_awr_config_file}
echo "#DO NOT EDIT. IT'S MAINTAINED PROGRAMATICALLY" >> ${v_awr_config_file}
echo "#" >> ${v_awr_config_file}

for each_inst_name in ${v_db_inst_names} ; do
 echo "PREV_MAX_SNAP_ID_${each_inst_name}=0" >> ${v_awr_config_file}
 echo "PREV_SNAP_ID_ANALYZED_${each_inst_name}=0" >> ${v_awr_config_file}
 echo "PREV_DBRESPTIME_AVG_${each_inst_name}=0" >> ${v_awr_config_file}
done

echo "AWR_SNAP_FILE_LOC=${v_config_dir}" >> ${v_awr_config_file}
echo "AWR_SNAP_DATA_FILE=${v_dbname}_awr_data.txt" >> ${v_awr_config_file}

echo "#" >> ${v_awr_config_file}
echo "#END: HEADER_ZONE" >> ${v_awr_config_file}
echo "#==============================================================================#" >> ${v_awr_config_file}
echo >> ${v_awr_config_file}
echo >> ${v_awr_config_file}

echo "#CUSTOMIZABLE ZONE BELOW" >> ${v_awr_config_file}
echo "#" >> ${v_awr_config_file}

echo "#AWR Snapshot Interval (in minutes) will be the scheduling frequency of this program" >> ${v_awr_config_file}
echo "AWR_SNAP_INTERVAL="${v_awr_snap_interval} | sed 's/ //g' >> ${v_awr_config_file}
echo >> ${v_awr_config_file}

echo "#Average Active Session per core baseline" >> $v_awr_config_file
echo "AAS_PER_CORE_BASELINE=${v_aas_per_core_baseline}" >> ${v_awr_config_file}
echo >> ${v_awr_config_file}

echo "#Average Active Session per core threshold (trigger level)" >> $v_awr_config_file
echo "AAS_PER_CORE_THRESHOLD=${v_aas_per_core_threshold}" >> ${v_awr_config_file}
echo >> ${v_awr_config_file}

echo "#Average Active session cpu per core" >> $v_awr_config_file
echo "AAS_CPU_PER_CORE_THRESHOLD=${v_aas_cpu_per_core_threshold}" >> ${v_awr_config_file}
echo >> ${v_awr_config_file}

echo "#db response time per call by a factor of (multiply)" >> ${v_awr_config_file}
echo "ABNORMAL_INCREASE=${v_abnormal_threshold}" >> ${v_awr_config_file}
echo >> ${v_awr_config_file}

else
echo "AWR Configuration file already exists. No action taken."
echo
exit 1
fi

if [ ! -e ${v_awr_data_file} ] ; then
echo
echo "Now Creating AWR Snapshot Data file ${v_awr_data_file} "

echo "#" >> ${v_awr_data_file}
echo "#${v_awr_data_file}" >> ${v_awr_data_file}
echo "#" >> ${v_awr_data_file}

echo "RUN_DATE_TIME_c1,NODE_NAME_c2,DB_NAME_c3,DBID_c4,INST_NO_c5,SNAP_ID_c6,SNAP_START_TIME_c7,SNAP_END_TIME_c8,SNAP_DUR_SEC_c9,SNAP_DB_TIME_SEC_c10,SNAP_DB_CPU_TIME_SEC_c11,TOTAL_OS_CPU_SEC_c12,AAS_c13,AASPC_c14,AAS_CPU_PC_c15,USER_CALLS_PS_c16,TPS_PS_c17,DB_RESP_TIME_PER_CALL_MS_c18,NO_CPU_c19,CPU_CORES_c20,OS_LOAD_c21,OS_CPU_PCT_c22,CPU_USR_PCT_c23,CPU_SYS_PCT_c24,INST_NAME_c25" >> ${v_awr_data_file}
echo

else
echo "AWR Data file already exists. No action taken."
exit 1
fi

}

# Validate the OS
v_uname_s=`uname -s`

if [ ${v_uname_s} != 'Linux' ] ; then
 echo "This script is currently supported on Linux only. Exiting"
 exit 1
fi


# Command line arguments validation

for args in "$@" ; do
 v_action=$1
 v_sid=$2
 v_ohome=$3
 v_config_dir=$4
done

if [ -z $v_action ] || [ -z $v_sid ] || [ -z $v_ohome ] || [ -z $v_config_dir ] ; then
 help
 exit 1
fi


# Variables

ORACLE_SID=$(echo ${v_sid})
export ORACLE_SID

ORACLE_HOME=$(echo ${v_ohome})
export ORACLE_HOME

PATH=$ORACLE_HOME/bin:$PATH
export PATH

# ensure ORACLE_SID is running on the node
v_orclsid=$(ps -ef | grep -iw ora_smon_$ORACLE_SID | grep -v grep | wc -l)

if [[ $v_orclsid -lt 1 ]] ; then
 echo "Instance $ORACLE_SID isn't running on this node..Exiting.."
 exit 1
fi

v_uname=`uname -n`
v_datetime=`date +%d-%b-%Y_%H:%M:%S`

#v_config_dir=$(/bin/pwd)

if [ x${v_dbname} = x ] ; then
 get_db_name
 v_awr_config_file=$(echo ${v_config_dir}/${v_dbname}_awr_config.txt | sed 's/ //g')
 v_awr_data_file=$(echo ${v_config_dir}/${v_dbname}_awr_data.txt | sed 's/ //g')
else
 v_awr_config_file=$(echo ${v_config_dir}/${v_dbname}_awr_config.txt | sed 's/ //g')
 v_awr_data_file=$(echo ${v_config_dir}/${v_dbname}_awr_data.txt | sed 's/ //g')
fi

# The following values are the defaults. They can be changed by customer in the AWR config file.
v_aas_per_core_baseline=0.65
v_aas_per_core_threshold=1.2
v_aas_cpu_per_core_threshold=0.85
v_abnormal_threshold=8

# main

case "$v_action" in
  help)
	help
	;;
  setup)
	generate_awr_files
	;;
  capture)
	capture_awr_data
	;;
  analyze)
	analyze_awr_data
	;;
  baseline)
	check_awr_snap_retention
	gen_95th_percentile
	;;
  *)
	help
	;;
 esac

exit $v_result
