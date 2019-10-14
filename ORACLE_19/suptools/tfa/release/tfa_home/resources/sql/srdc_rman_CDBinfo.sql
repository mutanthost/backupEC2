Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_rman_CDBinfo.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_rman_CDBinfo.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_rman_CDBinfo.sql 
Rem
Rem    DESCRIPTION
Rem      Query for RMAN CDB information.
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_rman_CDBinfo.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    03/29/18 - Changed the output file name to be used for consolidated dbrman SRDC collection
Rem    xiaodowu    01/18/18 - For dbrmanrr SRDC collection
Rem    xiaodowu    01/18/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
REM srdc_rman_restore_dbinfo.sql - collect RMAN datafile information for restore/recover.
define SRDCNAME='RMAN_CDBINFO'
SET MARKUP HTML ON spool on

set TERMOUT off;

COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'||
     to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;

REM
spool &&SRDCSPOOLNAME..htm
set HEADING off;
select '+----------------------------------------------------+' from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp:       '||to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
union all
select '| Machine:         '||host_name from v$instance
union all
select '| Version:         '||version from v$instance
union all
select '| DBName:          '||name from v$database
union all
select '| Instance:        '||instance_name from v$instance
union all
select '+----------------------------------------------------+' from dual
/
set HEADING on;
set echo on
set linesize 200 trimspool on
col name form a60
col dbname form a15
col member form a80
col inst_id form 999
col resetlogs_time form a25
col created form a25
col db_unique_name form a15
col stat form 9999999999
col thr form 99999
col "Uptime" form a80
col file# form 999999
col checkpoint_change# form 999999999999999
col first_change# form 999999999999999
col change# form 999999999999999
set numwidth 30;
set pagesize 50000;
alter session set nls_date_format = 'DD-MON-RRRR HH24:MI:SS';

show user

select o.output
from v$rman_output o, v$rman_backup_job_details d 
where O.session_recid=d.session_recid 
and o.session_stamp=d.session_stamp
and d.end_time > sysdate-5;

select   inst_id, instance_name, status, startup_time || ' - ' ||
trunc(SYSDATE-(STARTUP_TIME) ) || ' day(s), ' || trunc(24*((SYSDATE-STARTUP_TIME) -
trunc(SYSDATE-STARTUP_TIME)))||' hour(s), ' || mod(trunc(1440*((SYSDATE-STARTUP_TIME) - trunc(SYSDATE-STARTUP_TIME))), 60) ||' minute(s), ' || mod(trunc(86400*((SYSDATE-STARTUP_TIME) - trunc(SYSDATE-STARTUP_TIME))), 60) ||' seconds' "Uptime"
from     gv$instance
order by inst_id
/

select dbid, name, db_unique_name, database_role, created, resetlogs_change#, resetlogs_time, open_mode, log_mode, checkpoint_change#, controlfile_type, controlfile_change#, controlfile_time from v$database;

archive log list;

select * from v$controlfile;

select distinct(status), count(*)  from V$BACKUP group by status;


select v1.thread#, v1.group#, v1.sequence#, v1.first_change#, v1.first_time,
v1.archived, v1.status,v2.member
from v$log v1, v$logfile v2 where v1.group#=v2.group#
order by v1.first_time;

select * from v$recover_file order by 1;

select distinct(status)from v$datafile;

select round(sum(bytes)/1024/1024/1024,0) db_size_GB from v$datafile;

select 'ROOT', d.con_id, file#,  d.name, t.name, status, creation_change#, creation_time
from v$datafile d, v$tablespace t
where d.con_id=1 and d.ts#=t.ts# and
d.con_id=t.con_id
UNION
select c.name, d.con_id, file#,  d.name, t.name, status, creation_change#, creation_time
from v$datafile d, v$tablespace t, v$pdbs c
where d.con_id=c.con_id and d.ts#=t.ts# and t.con_id=c.con_id
order by 2;

select 'ROOT', d.con_id, file#, status, checkpoint_change#, checkpoint_time, resetlogs_change#, resetlogs_time, fuzzy
from v$datafile_header d
where d.con_id=1 
UNION
select c.name, d.con_id, file#, status, checkpoint_change#, checkpoint_time, resetlogs_change#, resetlogs_time, fuzzy 
from v$datafile_header d, v$pdbs c
where d.con_id=c.con_id 
order by 2;

select * from v$tempfile;

select status,checkpoint_change#,checkpoint_time, resetlogs_change#,
resetlogs_time, count(*), fuzzy from v$datafile_header h
group by status,checkpoint_change#,checkpoint_time, resetlogs_change#,
resetlogs_time, fuzzy;

select name, con_id, dbid, con_uid, guid from v$containers order by con_id;

select * from v$pdbs;

select FHTHR Thread, FHRBA_SEQ Sequence, count(1)
from X$KCVFH
group by FHTHR, FHRBA_SEQ
order by FHTHR, FHRBA_SEQ;

select hxfil file#, substr(hxfnm, 1, 50) name, fhscn checkpoint_change#, fhafs Absolute_Fuzzy_SCN, 
max(fhafs) over () Min_PIT_SCN
from x$kcvfh where fhafs!=0 ;

select substr(FHTNM,1,20) ts_name, HXFIL File_num,FHSCN SCN, FHSTA status , substr(HXFNM,1,80) name, FHRBA_SEQ Sequence, FHTIM checkpoint_time, FHBCP_THR Thread
from X$KCVFH;

select con_id, HXFIL File_num, FHSCN SCN, FHSTA status, FHDBI DBID, FHRBA_SEQ Sequence 
from X$KCVFH
order by con_id;

select FHTNM ts_name, HXFIL File_num,FHSCN SCN, FHSTA status, 
HXFNM name, FHRBA_SEQ Sequence, FHBCP_THR Thread from X$KCVFH;

select fhsta, count(*) from X$KCVFH group by fhsta;
select distinct(FHRBA_SEQ) Sequence, count(*) from X$KCVFH group by FHRBA_SEQ;
select min(fhrba_Seq), max(fhrba_Seq) from X$KCVFH;

select 'IF THE FOLLOWING QUERIES FAIL, THE DATABASE IS NOT OPEN IN READ WRITE MODE' from dual;

select pdb_id, pdb_name, status from dba_pdbs order by pdb_id;

select p.pdb_id, p.pdb_name, u.username from dba_pdbs p, cdb_users u
where  p.pdb_id=u.con_id order by p.pdb_id;

select p.pdb_id, p.pdb_name, d.file_id, d.tablespace_name, d.file_name 
from dba_pdbs p, cdb_data_files d 
where p.pdb_id=d.con_id
order by p.pdb_id;

select con_id, file_id, tablespace_name, file_name 
from cdb_temp_files order by con_id;

select tablespace_name, contents 
from dba_tablespaces where contents = 'UNDO';

select pdb, network_name, con_id 
from cdb_services 
where pdb is not null and con_id > 2 order by pdb;

select con_id, file_id, tablespace_name, file_name from cdb_temp_files order by con_id;

SELECT tablespace_name, contents from dba_tablespaces where contents = 'UNDO';

select db_name, con_id, pdb_name, operation, op_timestamp, cloned_from_pdb_name 
from cdb_pdb_history order by con_id;

set markup html off spool off

@?/rdbms/admin/sqlsessend.sql
