Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/db_dg_lsby_progress.sql /main/1 2018/05/28 15:06:26 bburton Exp $
Rem
Rem db_dg_lsby_progress.sql
Rem
Rem Copyright (c) 2017, 2018, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      db_dg_lsby_progress.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/db_dg_lsby_progress.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bburton     09/22/17 - -- This script is to be used to assist in
Rem                           collection information to help-- troubleshoot
Rem                           Data Guard issues involving a Logical Standby.
Rem    bburton     09/22/17 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
-- ------------------------------------------------------------------------
--
-- Usage: @dg_lsby_progress
-- ------------------------------------------------------------------------
-- PURPOSE:
-- This script is to be used to assist in collection information to help
-- troubleshoot Data Guard issues involving a Logical Standby.
-- ------------------------------------------------------------------------
-- DISCLAIMER:
-- This script is provided for educational purposes only. It is NOT
-- supported by Oracle World Wide Technical Support.
-- The script has been tested and appears to work as intended.
-- You should always run new scripts on a test instance initially.
-- ------------------------------------------------------------------------
-- Script output is as follows:

set echo off 
set feedback off 
column timecol new_value timestamp 
column spool_extension new_value suffix 
select to_char(sysdate,'Mondd_hhmiss') timecol, '.out' spool_extension from sys.dual; 
column output new_value dbname 
select value || '_' output 
from v$parameter where name = 'db_name'; 
spool dg_lsby_progress_&&dbname&&timestamp&&suffix 

set linesize 132
set pagesize 180
set long 2000
set trim on 
set trims on 
set numwidth 12
alter session set nls_date_format = 'Mon-DD HH24:MI:SS'; 

column sid format 99999
column pid format a8
column type format a12
column P-Name format a7 heading "Process|Name"
column event format a40 wrap
column blockingI format 9999 heading "Blk|Inst"
column blockingS format 9999999 heading "Blk|Session"
column blocking_session_status format a15 heading "Blocking|Status"
column primary_xid format a16
column PrimaryXID format a15 heading "Primary XID"
column XID format a12 heading "Local XID"

set feedback on 
select to_char(sysdate) time from dual; 

set echo on 
--
-- output of v$logstdby_progress
-- 
select * from v$logstdby_progress;

--
-- LOGSTDBY process wait events/objects/blocker information. 
-- transaction (from Primary) executing and the local transaction in the logical standby
--
select s.sid, l.type, l.pid, substr(s.program,instr(s.program,'(')+1,4) "P-Name", s.event, s.p1, s.p2, s.p3, s.wait_time
from v$session s, v$process p, v$logstdby l where s.paddr=p.addr and p.spid=l.pid;

select s.sid, l.pid, s.blocking_instance "BlockingI", s.blocking_session "BlockingS", s.blocking_session_status, s.row_wait_obj# "Object ID", s.row_wait_file# "File#", s.row_wait_block# "Block#", s.row_wait_row# "Row#" 
from v$session s, v$process p, v$logstdby l where s.paddr=p.addr and p.spid=l.pid;


-- For version < 11g
select sid, apply_status, primary_xid from v$logstdby_transaction order by sid;

-- For version >=11g
select sid, apply_status, primary_xid, primary_xidusn||'.'||primary_xidslt||'.'||primary_xidsqn PrimaryXID
from v$logstdby_transaction order by sid;

--
-- Local Transaction
--
select s.sid, t.xidusn||'.'||t.xidslot||'.'||t.xidsqn XID, t.status, t.log_io, t.phy_io, t.cr_get, t.cr_change 
from v$transaction t, v$session s 
where t.ses_addr=s.saddr;



--
-- Show the current SQL and explain plan (if any) is executing by LOGSTDBY processes
--
select sid, s.sql_id, s.sql_child_number, sql_fulltext
from v$session s, v$process p, v$logstdby l, v$sql a 
where s.paddr=p.addr and p.spid=l.pid and s.sql_id=a.sql_id and s.sql_child_number=a.child_number;

select t.* 
from v$session s, v$process p, v$logstdby l, v$sql a, table(DBMS_XPLAN.DISPLAY_CURSOR(a.sql_id, a.child_number, 'BASIC')) t
where s.paddr=p.addr and p.spid=l.pid and s.sql_id=a.sql_id and s.sql_child_number=a.child_number;

select sql_id, parse_calls, disk_reads, direct_writes, buffer_gets, rows_processed, fetches, executions, loads, version_count,
cpu_time, elapsed_time, sorts, sharable_mem, total_sharable_mem
from v$sqlstats where sql_id in ( 
select s.sql_id from v$session s, v$process p, v$logstdby l where s.paddr=p.addr and p.spid=l.pid);
spool off
@?/rdbms/admin/sqlsessend.sql
