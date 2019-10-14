Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_rman_performance.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_rman_performance.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_rman_performance.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_rman_performance.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    01/18/18 - For dbrmanperf SRDC collection
Rem    xiaodowu    01/18/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
REM srdc_rman_performance.sql - collect RMAN performance information
define SRDCNAME='RMAN_PERFORMANCE'

set markup html on spool on

set TERMOUT off;

COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'||
     to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
REM
spool &&SRDCSPOOLNAME..htm
Set heading off;
select '+----------------------------------------------------+' from dual
union all
select '| Diagnostic-Name: '||'&&SRDCNAME' from dual
union all
select '| Timestamp: '||
to_char(systimestamp,'YYYY-MM-DD HH24:MI:SS TZH:TZM') from dual
union all
select '| Machine: '||host_name from v$instance
union all
select '| Version: '||version from v$instance
union all
select '| DBName: '||name from v$database
union all
select '| Instance: '||instance_name from v$instance
union all
select '+----------------------------------------------------+' from dual
/
set heading on;
set pagesize 50000;
set echo on;
set feedback on;
Column session_id format 999999999 heading "SESS|ID"
Column session_serial# format 99999999 heading "SESS|SER|#"
Column event format a40
Column total_waits format 9,999,999,999 heading "TOTAL|TIME|WAITED|MICRO"
alter session set NLS_DATE_FORMAT='DD-MON-YYYY HH24MISS';

SELECT sid, spid, client_info
FROM v$process p, v$session s
WHERE p.addr = s.paddr
AND client_info LIKE '%id=rman%';
select SID, START_TIME,TOTALWORK, sofar, (sofar/totalwork) * 100 done,
sysdate + TIME_REMAINING/3600/24 end_at
from v$session_longops
where totalwork > sofar
AND opname NOT LIKE '%aggregate%';

SELECT set_count, device_type, type, substr(filename,1,90) filename,
buffer_size, buffer_count, open_time, close_time
FROM v$backup_async_io
where type != 'AGGREGATE'
ORDER BY set_count,type, open_time, close_time;

SELECT set_count, device_type, type, substr(filename,1,0) filename,
buffer_size, buffer_count, open_time, close_time
FROM v$backup_sync_io
where close_time > sysdate-5
ORDER BY set_count,type, open_time, close_time;

Select session_id, session_serial#, Event, sum(time_waited) total_waits
From v$active_session_history
Where sample_time > sysdate - 1
And program like '%rman%'
And session_state='WAITING' And time_waited > 0
Group by session_id, session_serial#, Event
Order by session_id, session_serial#, total_waits desc;

COL in_sec FORMAT a10
COL out_sec FORMAT a10
COL TIME_TAKEN_DISPLAY FORMAT a10
COL in_size FORMAT a10
COL out_size FORMAT a10
SELECT SESSION_KEY,
OPTIMIZED,
COMPRESSION_RATIO,
INPUT_BYTES_PER_SEC_DISPLAY in_sec,
OUTPUT_BYTES_PER_SEC_DISPLAY out_sec,
TIME_TAKEN_DISPLAY
FROM V$RMAN_BACKUP_JOB_DETAILS
ORDER BY SESSION_KEY;

SELECT SESSION_KEY,
INPUT_TYPE,
COMPRESSION_RATIO,
INPUT_BYTES_DISPLAY in_size,
OUTPUT_BYTES_DISPLAY out_size
FROM V$RMAN_BACKUP_JOB_DETAILS
ORDER BY SESSION_KEY;

set markup html off spool off

@?/rdbms/admin/sqlsessend.sql
 
