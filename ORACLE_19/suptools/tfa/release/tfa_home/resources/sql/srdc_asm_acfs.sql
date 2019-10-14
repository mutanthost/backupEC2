Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_asm_acfs.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_asm_acfs.sql
Rem
Rem Copyright (c) 2017, 2018, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_asm_acfs.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem     This script is intended to provide a user friendly output to diagonise
Rem    the ASM/ACFS Configuration.
Rem    This script does not make any DDL / DML modifications.
Rem
Rem    Reference taken ASM/ACFS SRDC collection originally Written by Esteban Bernal
Rem
Rem    Authors:
Rem    Santoshkumar Belchada - Oracle Support Services - RAC/STORAGE Group 
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_asm_acfs.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    recornej    09/25/17 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
define SRDCNAME='ASM_ACFS_INFORMATION'
SET MARKUP HTML ON PREFORMAT ON
set TERMOUT off FEEDBACK off VERIFY off TRIMSPOOL on HEADING off
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'||
        to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
set TERMOUT on MARKUP html preformat on
SET ECHO ON
SET PAGESIZE 200
ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS';
set HEADING on MARKUP html preformat off
set sqlprompt "#"
spool &&SRDCSPOOLNAME..htm
/*------------------------------------------------------------------------------------------------------------------*/
/*                                     ORACLE ASM /ACFS INFORMATION COLLECTION                                      */
/*------------------------------------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------------------------------------*/
/*CONTENT*/
/*------------------------------------------------------------------------------------------------------------------*/
/*Section 1: ASM DISK */
/*Section 2: ASM DISK PERFORMANCE STATS */
/*Section 3: ASM FILE ALIAS */
/*Section 4: ASM USER ACCESS */
/*Section 5: ASM ADVM VOLUME */
/*Section 6: ACFS */
/*Section 7: ASM OPERATION */
/*Section 8: ASM AUDIT */
/*Section 9: ASM SPFILE */
/*Section 10: ASM PARAMETERS FROM MEMORY */ 
/*------------------------------------------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------------------------------------------*/
select 'THIS ASM/ACFS REPORT WAS GENERATED AT: ==)> ' , sysdate " "  from dual;
SELECT * FROM V$VERSION;
SHOW SGA
SELECT * FROM V$INSTANCE;
SELECT * FROM GV$INSTANCE;
/*------------------------------------------------------------------------------------------------------------------*/
/* SECTION 1 : ASM DISK*/
/*------------------------------------------------------------------------------------------------------------------*/
SELECT * FROM V$ASM_DISKGROUP;
SELECT GROUP_NUMBER, DISK_NUMBER, MOUNT_STATUS, HEADER_STATUS, MODE_STATUS, STATE, OS_MB, TOTAL_MB, FREE_MB, NAME, FAILGROUP, PATH FROM V$ASM_DISK ORDER BY GROUP_NUMBER, FAILGROUP, DISK_NUMBER;
SELECT * FROM V$ASM_DISK ORDER BY GROUP_NUMBER,DISK_NUMBER;
SELECT SUBSTR(D.NAME,1,16) AS ASMDISK, D.MOUNT_STATUS, D.STATE,DG.NAME AS DISKGROUP FROM V$ASM_DISKGROUP DG, V$ASM_DISK D WHERE DG.GROUP_NUMBER = D.GROUP_NUMBER;
SELECT * FROM V$ASM_CLIENT;
SELECT DG.NAME AS DISKGROUP, SUBSTR(C.INSTANCE_NAME,1,12) AS INSTANCE,SUBSTR(C.DB_NAME,1,12) AS DBNAME, SUBSTR(C.SOFTWARE_VERSION,1,12) AS SOFTWARE,SUBSTR(C.COMPATIBLE_VERSION,1,12) AS COMPATIBLE FROM V$ASM_DISKGROUP DG, V$ASM_CLIENT C WHERE DG.GROUP_NUMBER = C.GROUP_NUMBER;
SELECT * FROM V$ASM_ATTRIBUTE;

/*------------------------------------------------------------------------------------------------------------------*/
/* SECTION 2 : ASM DISK PERFORMANCE STATS*/
/*------------------------------------------------------------------------------------------------------------------*/

SELECT * FROM V$ASM_DISKGROUP_STAT;
SELECT * FROM V$ASM_DISK_STAT;
SELECT * FROM V$ASM_DISK_IOSTAT;

/*------------------------------------------------------------------------------------------------------------------*/
/* SECTION 3 : ASM FILE ALIAS*/
/*------------------------------------------------------------------------------------------------------------------*/

SELECT CONCAT('+'||GNAME, SYS_CONNECT_BY_PATH(ANAME, '/')) FULL_PATH, SYSTEM_CREATED, ALIAS_DIRECTORY, FILE_TYPE FROM ( SELECT B.NAME GNAME, A.PARENT_INDEX PINDEX,A.NAME ANAME, A.REFERENCE_INDEX RINDEX,A.SYSTEM_CREATED,A.ALIAS_DIRECTORY,C.TYPE FILE_TYPE FROM V$ASM_ALIAS A, V$ASM_DISKGROUP B, V$ASM_FILE C WHERE A.GROUP_NUMBER = B.GROUP_NUMBER AND A.GROUP_NUMBER = C.GROUP_NUMBER(+) AND A.FILE_NUMBER = C.FILE_NUMBER(+) AND A.FILE_INCARNATION = C.INCARNATION(+)) START WITH (MOD(PINDEX, POWER(2, 24))) = 0 CONNECT BY PRIOR RINDEX = PINDEX;
SELECT * FROM v$ASM_ALIAS;
SELECT * FROM v$ASM_FILE;
SELECT * FROM V$ASM_FILESYSTEM;

/*------------------------------------------------------------------------------------------------------------------*/
/* SECTION 4 : ASM USER ACESS*/
/*------------------------------------------------------------------------------------------------------------------*/

SELECT * FROM V$ASM_USER;
SELECT * FROM V$ASM_USERGROUP;
SELECT * FROM V$ASM_USERGROUP_MEMBER;

/*------------------------------------------------------------------------------------------------------------------*/
/* SECTION 5 : ASM ADVM VOLUME*/
/*------------------------------------------------------------------------------------------------------------------*/
SELECT * FROM V$ASM_VOLUME;
SELECT * FROM V$ASM_VOLUME_STAT;

/*------------------------------------------------------------------------------------------------------------------*/
/* SECTION 6 : ACFS*/
/*------------------------------------------------------------------------------------------------------------------*/
SELECT * FROM V$ASM_ACFSSNAPSHOTS;
SELECT * FROM V$ASM_ACFSVOLUMES;
SELECT * FROM V$ASM_ACFS_ENCRYPTION_INFO;
SELECT * FROM V$ASM_ACFSREPL;
SELECT * FROM V$ASM_ACFSREPLTAG;
SELECT * FROM V$ASM_ACFS_SEC_ADMIN;
SELECT * FROM V$ASM_ACFS_SEC_CMDRULE;
SELECT * FROM V$ASM_ACFS_SEC_REALM;
SELECT * FROM V$ASM_ACFS_SEC_REALM_FILTER;
SELECT * FROM V$ASM_ACFS_SEC_REALM_GROUP;
SELECT * FROM V$ASM_ACFS_SEC_REALM_USER;
SELECT * FROM V$ASM_ACFS_SEC_RULE;
SELECT * FROM V$ASM_ACFS_SEC_RULESET;
SELECT * FROM V$ASM_ACFS_SEC_RULESET_RULE;
SELECT * FROM V$ASM_ACFS_SECURITY_INFO;
SELECT * FROM V$ASM_ACFSTAG;

/*------------------------------------------------------------------------------------------------------------------*/
/* SECTION 7 : ASM OPERATION*/
/*------------------------------------------------------------------------------------------------------------------*/
SELECT * FROM V$ASM_OPERATION;
SELECT * FROM V$ASM_ESTIMATE;

/*------------------------------------------------------------------------------------------------------------------*/
/* SECTION 8 : ASM AUDIT*/
/*------------------------------------------------------------------------------------------------------------------*/
SELECT * FROM V$ASM_AUDIT_CLEAN_EVENTS;
SELECT * FROM V$ASM_AUDIT_CLEANUP_JOBS;
SELECT * FROM V$ASM_AUDIT_CONFIG_PARAMS;
SELECT * FROM V$ASM_AUDIT_LAST_ARCH_TS;

/*------------------------------------------------------------------------------------------------------------------*/
/* SECTION 9 : ASM SPFILE*/
/*------------------------------------------------------------------------------------------------------------------*/
SELECT * FROM V$SPPARAMETER ORDER BY 2;

/*------------------------------------------------------------------------------------------------------------------*/
/* SECTION 10 : ASM PARAMETERS FROM MEMORY*/
/*------------------------------------------------------------------------------------------------------------------*/
SELECT * FROM V$SYSTEM_PARAMETER ORDER BY 2;
SPOOL OFF
set sqlprompt "SQL>"
exit

@?/rdbms/admin/sqlsessend.sql
 
