Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_rman_08137_info.sql /main/2 2018/09/05 08:07:35 recornej Exp $
Rem
Rem srdc_rman_08137_info.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_rman_08137_info.sql - RMAN_8137 Health check
Rem
Rem    DESCRIPTION
Rem      Checks RMAN_8137 health of a DB
Rem
Rem    NOTES
Rem      .
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_rman_08137_info.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    recornej    08/31/18 - Adding changes requested by SME.
Rem    xiaodowu    01/18/18 - For dbrman8137_8120 SRDC collection
Rem    xiaodowu    01/18/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
define SRDCNAME='RMAN_8137'
set pagesize 200 verify off sqlprompt "" term off entmap off echo off
set markup html on spool on
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
select 'Diagnostic-Name : ' || '&&SRDCNAME'  as "SRDC COLLECTION HEADER"  from dual
union all
select 'Time : ' || to_char(systimestamp, 'YYYY-MM-DD HH24MISS TZHTZM' ) from dual
union all
select 'Machine : ' || host_name from v$instance
union all
select 'Version : '|| version from v$instance
union all
select 'DBName : '||name from v$database
union all
select 'Instance : '||instance_name from v$instance
/
set echo on
set serveroutput on
alter session set nls_date_format = 'DD-MON-YYYY HH24:MI:SS'


show parameter dest_state 
set numwidth 30;
variable reqscn number; 
variable reqrls number; 
execute sys.dbms_rcvman.getRequiredSCN(:reqscn, :reqrls); 
print reqscn;
print reqrls;

select * from v$rman_configuration;
select name, scn, guarantee_flashback_database from v$restore_point; 
select min_required_capture_change#, database_role from v$database; 
select dest_id, status, target, dependency, valid_now, valid_type, valid_role 
 from v$archive_dest; 
select thread#, sequence#, first_change#, next_change#, first_time, applied, backup_count from 
 v$archived_log where first_time < sysdate-7 and status='A' 
 order by 1,2;
SELECT l.dest_id dest, l.thread# trd, l.sequence# seq, l.next_change# scn, l.applied, 
 l.resetlogs_change#, l.resetlogs_time 
 FROM v$archived_log l, v$archive_dest d, v$database_incarnation i 
 WHERE d.target = 'STANDBY' 
 AND (d.valid_now = 'YES' OR d.valid_now = 'UNKNOWN' OR 
      d.valid_now = 'INACTIVE') 
 AND d.status != 'DEFERRED' 
 AND d.status != 'ALTERNATE' 
 AND d.dependency = 'NONE' 
 AND d.dest_id = l.dest_id 
 AND l.standby_dest = 'YES' 
 AND l.resetlogs_time = i.resetlogs_time 
 AND l.resetlogs_change# = i.resetlogs_change# 
 AND i.status != 'ORPHAN' 
  UNION ALL -- Need one bogus row at end to make looping work. 
  SELECT max(dest_id)+1 dest, 1 trd, 1 seq, 1 scn, null applied, 
   0 resetlogs_change#, sysdate resetlogs_time 
   FROM v$archive_dest 
   ORDER BY 1,2,4; 





Rem===========================================================================================================================================
spool off
set markup html off spool off
set sqlprompt "SQL> " term on  echo off
PROMPT
PROMPT
PROMPT REPORT GENERATED : &SRDCSPOOLNAME..htm
set verify on echo on
Rem===========================================================================================================================================

@?/rdbms/admin/sqlsessend.sql
