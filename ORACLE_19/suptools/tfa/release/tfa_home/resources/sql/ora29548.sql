Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/ora29548.sql /main/1 2018/05/28 15:06:26 bburton Exp $
Rem
Rem ora29548.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      ora29548.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/ora29548.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    xiaodowu    01/29/18 - For SRDC ORA29548 collection
Rem    xiaodowu    01/29/18 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
column comp_name format a40
column version format a20
column status format a15
column owner format a30
column object_name format a30
column object_type format a15
column long_name format a75
column role format a40

set pagesize 500
set linesize 150
set trimspool on
set serveroutput on
set echo on

spool jvm_info.log

------ REGISTRY INFO ------

SELECT comp_name, version, status
  FROM dba_registry
 ORDER BY comp_name;

SELECT *
  FROM dba_registry_history
 ORDER BY action_time DESC;

------ JAVA OBJECT INFO ------

SELECT owner, object_type, status, COUNT(*)
  FROM dba_objects
 WHERE object_type LIKE '%JAVA%'
 GROUP BY owner, object_type, status
 ORDER BY owner, object_type, status;

SELECT owner, object_name, object_type, status
  FROM dba_objects
 WHERE object_name LIKE '%DBMS_JAVA%'
    OR object_name LIKE '%INITJVMAUX%'
 ORDER BY owner, object_name, object_type;

SELECT owner, NVL(longdbcs,object_name) long_name, object_type, status
  FROM dba_objects, sys.javasnm$
 WHERE object_type LIKE '%JAVA%'
   AND status <> 'VALID'
   AND short (+) = object_name
 ORDER BY owner, long_name, object_type;

------ JAVA ROLE INFO ------

SELECT role
  FROM dba_roles
 WHERE role LIKE '%JAVA%'
 ORDER BY role;

------ MEMORY INFO ------

SELECT *
  FROM v$sgastat
 WHERE pool = 'java pool' OR name = 'free memory'
 ORDER BY pool, name;

------ DATABASE PARAMETER INFO ------

show parameter pool_size

show parameter target

show parameter sga

------ TEST JAVAVM USAGE ------

SELECT dbms_java.longname('TEST') long_name FROM dual;

spool off

@?/rdbms/admin/sqlsessend.sql
 
