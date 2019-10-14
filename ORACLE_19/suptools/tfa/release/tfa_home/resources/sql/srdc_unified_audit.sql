Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_unified_audit.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_unified_audit.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_unified_audit.sql 
Rem
Rem    DESCRIPTION
Rem      Query unified audit information.
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_unified_audit.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    03/29/18 - Called by srdc_dbaudit.xml
Rem    xiaodowu    03/29/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
SET LINESIZE 200
COLUMN object_schema FORMAT A15
COLUMN object_name FORMAT A15
COLUMN policy_name FORMAT A25
COLUMN audit_option FORMAT A30
COLUMN audit_option_type FORMAT A20
COLUMN audit_condition FORMAT A20
COLUMN parameter format A20
COLUMN value format A10
COLUMN user_name format a10
COLUMN success format a10
COLUMN failure format a10

spool srdc_unified_audit.log

prompt
prompt Unified auditing option

select parameter,value from v$option where parameter = 'Unified Auditing';

prompt
prompt Unified auditing options enabled in the database

select user_name,policy_name,enabled_opt,success,failure from audit_unified_enabled_policies;

prompt
prompt Unified auditing options across the database

select policy_name,audit_option,object_schema,object_name,audit_option_type,audit_condition FROM audit_unified_policies where object_schema not in ('DVSYS','DVF','LBACSYS');

spool off

@?/rdbms/admin/sqlsessend.sql
 
