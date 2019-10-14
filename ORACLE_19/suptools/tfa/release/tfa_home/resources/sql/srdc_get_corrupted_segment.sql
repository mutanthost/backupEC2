Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_get_corrupted_segment.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_get_corrupted_segment.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_get_corrupted_segment.sql 
Rem
Rem    DESCRIPTION
Rem      Query for corrupted segments. 
Rem
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_get_corrupted_segment.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    03/28/18 - Called by srdc_dbundocorruption.xml
Rem    xiaodowu    03/28/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
spool corrupt_segments.log


set echo on;
set pagesize 2000
set linesize 280

spool

select systimestamp
from dual;

SELECT e.owner, e.segment_type, e.segment_name, e.partition_name, c.file#
     , greatest(e.block_id, c.block#) corr_start_block#
     , least(e.block_id+e.blocks-1, c.block#+c.blocks-1) corr_end_block#
     , least(e.block_id+e.blocks-1, c.block#+c.blocks-1)
       - greatest(e.block_id, c.block#) + 1 blocks_corrupted
     , corruption_type description
  FROM dba_extents e, v$database_block_corruption c
 WHERE e.file_id = c.file#
   AND e.block_id <= c.block# + c.blocks - 1
   AND e.block_id + e.blocks - 1 >= c.block#
UNION
SELECT s.owner, s.segment_type, s.segment_name, s.partition_name, c.file#
     , header_block corr_start_block#
     , header_block corr_end_block#
     , 1 blocks_corrupted
     , corruption_type||' Segment Header' description
  FROM dba_segments s, v$database_block_corruption c
 WHERE s.header_file = c.file#
   AND s.header_block between c.block# and c.block# + c.blocks - 1
UNION
SELECT null owner, null segment_type, null segment_name, null partition_name, c.file#
     , greatest(f.block_id, c.block#) corr_start_block#
     , least(f.block_id+f.blocks-1, c.block#+c.blocks-1) corr_end_block#
     , least(f.block_id+f.blocks-1, c.block#+c.blocks-1)
       - greatest(f.block_id, c.block#) + 1 blocks_corrupted
     , 'Free Block' description
  FROM dba_free_space f, v$database_block_corruption c
 WHERE f.file_id = c.file#
   AND f.block_id <= c.block# + c.blocks - 1
   AND f.block_id + f.blocks - 1 >= c.block#
order by file#, corr_start_block#; 

spool off

@?/rdbms/admin/sqlsessend.sql
