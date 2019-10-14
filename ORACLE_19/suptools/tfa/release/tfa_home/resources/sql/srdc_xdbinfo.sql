Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_xdbinfo.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_xdbinfo.sql
Rem
Rem Copyright (c) 2017, 2018, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_xdbinfo.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_xdbinfo.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bburton     07/11/17 - SQL to gather xdb information from a database.
Rem    bburton     07/11/17 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
spool XDB_info.txt
set echo on;
set pagesize 10000
set linesize 200
col parameter format a25
col value format a35
col comp_name format a36
col version format a14
col status format a10
col action_time format a35
col action format a20
col comments format a45
col owner format a12
col object_name format a35
col object_type format a20
col name format a35
col table_name format a35
col column_name format a25
col index_name format a25
col grantee format a12
col privilege format a12
col schema_url format a60
alter session set NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS';
-- Instance and platform
select sysdate from dual;
select instance_name, version from v$instance;
select platform_name from v$database;
select * from nls_database_parameters
where parameter LIKE '%SET' ORDER BY 1;
-- Status of database components
select comp_name, version, status
from dba_registry
order by status, comp_name;
-- DB_Errors
select owner, name, type, text
from dba_errors
where owner in ('SYS', 'XDB')
order by owner, name;
-- Invalid objects
select owner, object_name, object_type, status
from dba_objects
where status = 'INVALID'
and owner in ('SYS', 'XDB')
order by owner, object_name;
-- Object errors
select owner, name, type, text
from dba_errors
where owner in ('SYS', 'XDB')
order by owner, name;
-- Do private synonyms for XDB objects exist?
select owner, object_name, object_type, status
from dba_objects
where object_name in (select object_name from dba_objects
where owner = 'XDB')
and owner not in ('PUBLIC', 'XDB');
-- Privileges
select owner, table_name, grantee, privilege
from dba_tab_privs
where table_name in ('DBMS_JOB','DBMS_LOB','DBMS_SQL','UTL_FILE')
and grantee in ('PUBLIC', 'XDB')
order by grantee, table_name;
-- XML type tables
select owner, storage_type, count(*) "TOTAL"
from dba_xml_tables
group by owner, storage_type;
-- XML type columns
select owner, storage_type, count(*) "TOTAL"
from dba_xml_tab_cols
group by owner, storage_type;
-- XDB Indexes
select index_name, status, domidx_status, domidx_opstatus
from dba_indexes
where index_name in ('XDBHI_IDX', 'XDB$RESOURCE_OID_INDEX');
-- Registered schemas
select owner, count(*) "TOTAL"
from dba_xml_schemas
group by owner;
select owner, schema_url
from dba_xml_schemas
order by 1,2;
-- User defined resources in the repository
select distinct (a.username) "USER", count (r.xmldata) "TOTAL"
from dba_users a, xdb.xdb$resource r
where sys_op_rawtonum (extractvalue (value(r),'/Resource/OwnerID/text()')) = a.USER_ID
group by a.username;
select any_path from resource_view;
-- Network ACLs
select aclid, host from dba_network_acls;
spool off;
@?/rdbms/admin/sqlsessend.sql
 
