set define off
set verify off
set feedback off
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
prompt ...start executing the upgrade supporting objects
prompt ...CM_Upgrade_Mode_On

DECLARE
l_id NUMBER := 999;
isUpgradeExists number;
BEGIN
  select count(1) into isUpgradeExists from rca13_intrack_preferences where PREFERENCE_NAME='CM_UPGRADE_MODE';
   if isUpgradeExists = 0 then
  INSERT INTO RCA13_INTRACK_PREFERENCES ( id,preference_name, preference_value,
      preference_description
    )
    VALUES
    ( l_id,
      'CM_UPGRADE_MODE',
      'Y',
      'CM upgrading to recent version'
    );
    else 
    UPDATE RCA13_INTRACK_PREFERENCES SET PREFERENCE_VALUE='Y' where PREFERENCE_NAME='CM_UPGRADE_MODE';
    end if;  
  COMMIT;
EXCEPTION
WHEN dup_val_on_index THEN
  NULL;
END;
/
--Release Specific Details
declare
  rBuildId number; --Latest build Id
  isColExists number;
begin
 for rec in ( select build_id from rca13_release_info order by build_id desc ) loop
   rBuildId := rec.build_id;
   exit;
 end loop;

 if rBuildId = 20160916000000 then --Always put the latest number here manually      
  -- You are using latest version.
  RETURN;
 end if;
 

 begin
  insert into RCA13_RELEASE_INFO(BUILD_ID,APP_VERSION) values(to_number('20140530000000'),'2.2.5');
  commit;
  exception when dup_val_on_index then null;
 end;

 begin
  insert into RCA13_RELEASE_INFO(BUILD_ID,APP_VERSION) values(to_number('20140930000000'),'12.1.0.2.1');
  commit;
  exception when dup_val_on_index then null;
 end;

 begin
  insert into RCA13_RELEASE_INFO(BUILD_ID,APP_VERSION) values(to_number('20141114000000'),'12.1.0.2.2');
  commit;
  exception when dup_val_on_index then null;
 end;
--No CM changes for the release 12.1.0.2.3
 begin
  insert into RCA13_RELEASE_INFO(BUILD_ID,APP_VERSION) values(to_number('20150703000000'),'12.1.0.2.4');
  commit;
  exception when dup_val_on_index then null;
 end;

begin
  insert into RCA13_RELEASE_INFO(BUILD_ID,APP_VERSION) values(to_number('20151014000000'),'12.1.0.2.5');
  commit;
  exception when dup_val_on_index then null;
 end;
 
 begin
  insert into RCA13_RELEASE_INFO(BUILD_ID,APP_VERSION) values(to_number('20160115000000'),'12.1.0.2.6');
  commit;
  exception when dup_val_on_index then null;
 end;

 begin
insert into RCA13_RELEASE_INFO(BUILD_ID,APP_VERSION) values(to_number('20160516000000'),'12.1.0.2.7');
commit;
exception when dup_val_on_index then null;
 end;
 
 begin
insert into RCA13_RELEASE_INFO(BUILD_ID,APP_VERSION) values(to_number('20160831000000'),'12.2.0.1.1(BETA)');
commit;
exception when dup_val_on_index then null;
end;
 
 begin
insert into RCA13_RELEASE_INFO(BUILD_ID,APP_VERSION) values(to_number('20160916000000'),'12.2.0.1.1');
commit;
exception when dup_val_on_index then null;
end;

 begin
insert into RCA13_RELEASE_INFO(BUILD_ID,APP_VERSION) values(to_number('20181119000000'),'18.4.0');
commit;
exception when dup_val_on_index then null;
end;
 --Before upgrade stop all jobs
begin
    dbms_scheduler.stop_job('RCA13_PROCESS_DATA', force=>true);
    exception when others then null;
end;

begin
    dbms_scheduler.stop_job('RCA13_NOTIFICATIONS_JOB', force=>true);
    exception when others then null;
end;
 
 for rec in ( select build_id bid from rca13_release_info where build_id > rBuildId order by build_id asc ) loop
  -- Upgrade app version by version
  if rec.bid = 20140530000000  then
   EXECUTE IMMEDIATE 'alter table rca13_collections
   add (
   FAIL_COMMENT VARCHAR2(1000 BYTE),  
   TOOL_VERSION VARCHAR2(100 BYTE),
   CURRENT_USER VARCHAR2(100 BYTE),
   SKIPPED_CHECKS NUMBER DEFAULT 0,
   IS_EXALOGIC NUMBER DEFAULT 0
   )';

   EXECUTE IMMEDIATE 'CREATE TABLE RCA13_MAIL_SERVER
   (    
    ID VARCHAR2(40 BYTE),
    SERVER_NAME VARCHAR2(200 BYTE),
    PORT NUMBER(*,0) DEFAULT 25
   )';
   
   EXECUTE IMMEDIATE 'CREATE TABLE RCA13_EMAIL_FAILURE
   (
    EMAIL_FAILURE_ID VARCHAR2(40 BYTE),
    DATE_ADDED DATE,
    EMAIL_ADDRESS VARCHAR2(1000 BYTE),
    SUBJECT VARCHAR2(1000 BYTE),
    MESSAGE_TEXT VARCHAR2(4000 BYTE),
    MESSAGE_LENGTH NUMBER,
    ERROR_TEXT CLOB
   )';

   EXECUTE IMMEDIATE 'CREATE TABLE RCA13_EMAIL_SENT
   (    
    EMAIL_SENT_ID VARCHAR2(40 BYTE),
    USER_ID VARCHAR2(40 BYTE),
    EMAIL_ADDRESS VARCHAR2(4000 BYTE),
    SENT_DATE DATE,
    MESSAGE_TEXT CLOB
   )';

   EXECUTE IMMEDIATE 'CREATE TABLE RCA13_USER_DETAILS
   (    
    EMAIL_ADDRESS VARCHAR2(40 BYTE) NOT NULL ENABLE,
    USER_ID VARCHAR2(40 BYTE) NOT NULL ENABLE,
    IS_NOTIFIED NUMBER DEFAULT 0,
    CONSTRAINT RCA13_USER_DETAILS_PK PRIMARY KEY (USER_ID)
   )';

   EXECUTE IMMEDIATE 'CREATE TABLE RCA13_COLLECTIONS_DIFF
   (    
    JOB_ID VARCHAR2(40 BYTE),
    LOB_ID VARCHAR2(40 BYTE),
    SYSTEM_ID VARCHAR2(40 BYTE),
    DIFF CLOB,
    LOB_NAME VARCHAR2(256 BYTE),
    SYSTEM_NAME VARCHAR2(256 BYTE)
   )';

   EXECUTE IMMEDIATE 'CREATE TABLE RCA13_NOTIFICATION_JOBS
   (    
    JOB_ID VARCHAR2(40 BYTE) NOT NULL ENABLE,
    START_TIME DATE,
    END_TIME DATE,
    CONSTRAINT RCA13_NOTIFICATION_JOBS_PK PRIMARY KEY (JOB_ID)
   )';

   EXECUTE IMMEDIATE 'CREATE TABLE RCA13_NOTIFICATION_JOB_DETAILS
   (
    JOB_ID VARCHAR2(40 BYTE),
    SYSTEM_ID VARCHAR2(40 BYTE),
    START_CDATE TIMESTAMP (6),
    END_CDATE TIMESTAMP (6)
   )';
 
   EXECUTE IMMEDIATE 'CREATE INDEX RCA13_NOTIF_JOB_DTLS_IND1 ON RCA13_NOTIFICATION_JOB_DETAILS (JOB_ID)';
   
   EXECUTE IMMEDIATE 'CREATE TABLE RCA13_APEX_DETAILS
   (    
    URL VARCHAR2(1000 BYTE),
    APP_ID NUMBER
   )';
 elsif rec.bid = 20140930000000 then
   --DDL changes done for 12.1.0.2.1
   select count(1) into isColExists from user_tab_columns where table_name = 'AUDITCHECK_RESULT' and column_name in ('TARGET_TYPE','TARGET_VALUE');
   if isColExists = 0 then
     EXECUTE IMMEDIATE 'ALTER TABLE AUDITCHECK_RESULT add("TARGET_TYPE" VARCHAR2(128 BYTE),"TARGET_VALUE" VARCHAR2(256 BYTE))';
   end if;  
   
   select count(1) into isColExists from user_tab_columns where table_name = 'AUDITCHECK_PATCH_RESULT' and column_name ='UPLOAD_COLLECTION_NAME';
   if isColExists = 0 then
     EXECUTE IMMEDIATE 'alter table auditcheck_patch_result add (UPLOAD_COLLECTION_NAME VARCHAR2(256))';
   end if;

   EXECUTE IMMEDIATE 'alter table rca13_collections add (PROFILES VARCHAR2(2000))';

   EXECUTE IMMEDIATE 'alter table rca13_ignored_checks add (COLLECTION_NAME VARCHAR2(256))';   

   EXECUTE IMMEDIATE 'CREATE TABLE RCA13_PARAMETERS
   (    
    COLLECTION_ID VARCHAR2(40 BYTE),
    DB_NAME VARCHAR2(128 BYTE),
    INSTANCE_NAME VARCHAR2(128 BYTE),
    PARAM_NAME VARCHAR2(256 BYTE),
    VALUE VARCHAR2(512 BYTE)
   )';        

  EXECUTE IMMEDIATE 'DROP SEQUENCE RCA13_JOB_SEQ';

  EXECUTE IMMEDIATE 'CREATE SEQUENCE RCA13_JOB_SEQ  MINVALUE 1 MAXVALUE 9999999999999999999 INCREMENT BY 1 CACHE 20 CYCLE';
 elsif rec.bid = 20141114000000 then
   --DDL changes done for 12.1.0.2.2
   EXECUTE IMMEDIATE 'alter table rca13_docs add (SR_BUG_NUM VARCHAR2(2000))';
   EXECUTE IMMEDIATE 'alter table rca13_collections add (SR_BUG_NUM VARCHAR2(2000))';
   begin
    insert into RCA13_INTRACK_PREFERENCES (id,preference_name,preference_value,preference_description) values (12,'SHOW_SR_BUG_INFO','N','It is Y for internal usage and always N for customers');
    commit;
   exception when dup_val_on_index then null;
   end;
 elsif rec.bid = 20150703000000 then
   --DDL changes done for 12.1.0.2.4  
   EXECUTE IMMEDIATE 'alter table rca13_homes modify (USER_NAME varchar2(128))';

 elsif rec.bid=20151014000000 then
    -- DDL changes done for 12.1.0.2.5
     EXECUTE IMMEDIATE 'CREATE TABLE RCA13_ORACHK_AUDIT_CHECKS
 (CHECK_ID VARCHAR2(40 BYTE) DEFAULT SYS_GUID() NOT NULL ENABLE,
    AUDIT_CHECK_NAME VARCHAR2(100 BYTE),  
    ACTION_TYPE VARCHAR2(20),
    ON_HOLD NUMBER,
 PARAM_PATH VARCHAR2(4000 BYTE), -- parampath<seq> (add change the seq, else hold the same number)
  COMMAND VARCHAR2(4000 BYTE),
  COMMAND_REPORT VARCHAR2(4000 BYTE),
  OPERATOR_STRING VARCHAR2(10 BYTE),
  COMPARE_VALUE VARCHAR2(4000 BYTE),    
  COMPONENT_DEPENDENCY VARCHAR2(4000 BYTE),
  ORACLE_HOME_TYPE VARCHAR2(20 BYTE),
  ALERT_LEVEL VARCHAR2(20 BYTE),
  PASS_MSG VARCHAR2(4000 BYTE),
  FAIL_MSG VARCHAR2(4000 BYTE),
  BENEFIT_IMPACT VARCHAR2(4000 BYTE),
  RISK VARCHAR2(4000 BYTE),
  ACTION_REPAIR VARCHAR2(4000 BYTE),
  CREATE_USER VARCHAR2(40 BYTE),
  CREATE_DATE DATE DEFAULT SYSDATE,
  MODIFY_USER VARCHAR2(40 BYTE),
  MODIFY_DATE DATE DEFAULT SYSDATE,
 CONSTRAINT AUDITCHECK_UNQ1 UNIQUE (CHECK_ID),
 CONSTRAINT AUDITCHECKNAME_UNQ1 UNIQUE (AUDIT_CHECK_NAME))';

   EXECUTE IMMEDIATE 'COMMENT ON COLUMN RCA13_ORACHK_AUDIT_CHECKS.ACTION_TYPE IS ''SQL,OS''';
   EXECUTE IMMEDIATE 'COMMENT ON COLUMN RCA13_ORACHK_AUDIT_CHECKS.PARAM_PATH IS ''PARAM_PATH is not required for OS AUDIT CHECKS''';
   EXECUTE IMMEDIATE 'COMMENT ON COLUMN RCA13_ORACHK_AUDIT_CHECKS.OPERATOR_STRING IS ''-eg,-ne,-gt,-lt,-ge,-le,=,!=,-n,-z''';
   EXECUTE IMMEDIATE 'COMMENT ON COLUMN RCA13_ORACHK_AUDIT_CHECKS.COMPARE_VALUE IS ''WHATEVER SINGLE RETURN NUMERIC OR STRING VALUE''';
   EXECUTE IMMEDIATE 'COMMENT ON COLUMN RCA13_ORACHK_AUDIT_CHECKS.COMPONENT_DEPENDENCY IS ''Valid entries are ASM, CRS, RDBMS''';
   EXECUTE IMMEDIATE 'COMMENT ON COLUMN RCA13_ORACHK_AUDIT_CHECKS.ORACLE_HOME_TYPE IS ''Valid entries are ASM, CRS, RDBMS''';
   EXECUTE IMMEDIATE 'COMMENT ON COLUMN RCA13_ORACHK_AUDIT_CHECKS.ALERT_LEVEL IS ''WARN,FAIL,INFO''';
   
   
    EXECUTE IMMEDIATE 'CREATE TABLE RCA13_ORACHK_CHK_TYPE
   (NAME VARCHAR2(40 BYTE) NOT NULL ENABLE,  
    VALUE VARCHAR2(40 BYTE)
   )';
   
   
    EXECUTE IMMEDIATE 'CREATE TABLE RCA13_ORACHK_DB_TYPES_MASTER
   (DATABASE_TYPE_ID VARCHAR2(40 BYTE) DEFAULT SYS_GUID() NOT NULL ENABLE,  
    DATABASE_TYPE VARCHAR2(40 BYTE),
   CONSTRAINT RCA13_DB_TYPE_PK PRIMARY KEY (DATABASE_TYPE_ID))';
   EXECUTE IMMEDIATE 'COMMENT ON COLUMN RCA13_ORACHK_DB_TYPES_MASTER.DATABASE_TYPE IS ''Valid entries are CDB,PDB,NORMAL''';
   
   
    EXECUTE IMMEDIATE 'CREATE TABLE RCA13_ORACHK_DB_ROLES_MASTER
   (    DATABASE_ROLE_ID VARCHAR2(40 BYTE) DEFAULT SYS_GUID() NOT NULL ENABLE,  
    DATABASE_ROLE VARCHAR2(40 BYTE),
    CONSTRAINT RCA13_DB_ROLE_PK PRIMARY KEY (DATABASE_ROLE_ID))';
    EXECUTE IMMEDIATE 'COMMENT ON COLUMN RCA13_ORACHK_DB_ROLES_MASTER.DATABASE_ROLE IS ''Valid entries are PRIMARY,PHYSICAL_STANDBY,LOGICAL_STANDBY''';
    
    EXECUTE IMMEDIATE 'CREATE TABLE RCA13_ORACHK_DB_MODES_MASTER
   (    DATABASE_MODE_ID VARCHAR2(40 BYTE) DEFAULT SYS_GUID() NOT NULL ENABLE,  
    DATABASE_MODE VARCHAR2(40 BYTE),
    CONSTRAINT RCA13_DATABASE_MODE_PK PRIMARY KEY (DATABASE_MODE_ID))';
    EXECUTE IMMEDIATE 'COMMENT ON COLUMN RCA13_ORACHK_DB_MODES_MASTER.DATABASE_MODE IS ''1 = NOMOUNT, 2 = MOUNT, 3 = OPEN''';
    
    EXECUTE IMMEDIATE 'CREATE TABLE RCA13_ORACHK_COMP_DEP
   (COMP_DEP_ID VARCHAR2(40 BYTE) DEFAULT SYS_GUID() NOT NULL ENABLE,  
    COMP_DEP_NAME VARCHAR2(40 BYTE)
   )';
   EXECUTE IMMEDIATE 'COMMENT ON COLUMN RCA13_ORACHK_COMP_DEP.COMP_DEP_NAME IS ''Valid entries are  ASM, CRS, RDBMS''';
   
   EXECUTE IMMEDIATE 'CREATE TABLE RCA13_ORACHK_ORACLE_HOME_TYPE
   (ORA_HOME_ID VARCHAR2(40 BYTE) DEFAULT SYS_GUID() NOT NULL ENABLE,  
    ORA_HOME_NAME VARCHAR2(40 BYTE)
   )';
   EXECUTE IMMEDIATE 'COMMENT ON COLUMN RCA13_ORACHK_ORACLE_HOME_TYPE.ORA_HOME_NAME IS ''Valid entries are ASM, CRS, RDBMS''';
   
   
    EXECUTE IMMEDIATE 'CREATE TABLE RCA13_ORACHK_CAND_SYS
     (CAND_SYS_ID VARCHAR2(40 BYTE) DEFAULT SYS_GUID() NOT NULL ENABLE,  
    CAND_SYS_NAME VARCHAR2(40 BYTE),
  CONSTRAINT RCA13_SF_CANDSYS_PK PRIMARY KEY (CAND_SYS_ID))';  
  EXECUTE IMMEDIATE 'COMMENT ON COLUMN RCA13_ORACHK_CAND_SYS.CAND_SYS_NAME IS ''Valid entries are RACCHECK, SIDB''';
   
    EXECUTE IMMEDIATE 'CREATE TABLE RCA13_ORACHK_OP_STRING
   (NAME VARCHAR2(150 BYTE) NOT NULL ENABLE,
    VALUE VARCHAR2(40 BYTE)
   )';
   
    EXECUTE IMMEDIATE 'CREATE TABLE RCA13_ORACHK_ALERT_LEVEL
   (ALERT_LEVEL VARCHAR2(150 BYTE),
    ALERT_TYPE VARCHAR2(150 BYTE)
   )';
   
    EXECUTE IMMEDIATE 'CREATE TABLE RCA13_VERSION
   (VERSION_ID VARCHAR2(40 BYTE) DEFAULT SYS_GUID() NOT NULL ENABLE,
    VERSION_NAME VARCHAR2(30 BYTE) NOT NULL ENABLE,
    IS_PREFERRED NUMBER(1,0) DEFAULT 0,
    DATE_ADDED DATE DEFAULT sysdate NOT NULL ENABLE,
   CONSTRAINT RCA13_VERSION_PK PRIMARY KEY (VERSION_ID))';
   
    EXECUTE IMMEDIATE 'CREATE TABLE RCA13_DISTRIBUTION
   (DISTRIBUTION_OS_ID VARCHAR2(40 BYTE) NOT NULL ENABLE,
    PLATFORM_ID VARCHAR2(40 BYTE) NOT NULL ENABLE,
    OSDIST VARCHAR2(40 BYTE),
    OSVERSION VARCHAR2(40 BYTE) NOT NULL ENABLE,
    OSKERNEL VARCHAR2(40 BYTE),
    OSDIST_REP_KERNEL NUMBER,
     CONSTRAINT RCA13_DISTRIBUTION_OS_UK UNIQUE (PLATFORM_ID, OSDIST, OSVERSION, OSKERNEL),
     CONSTRAINT RCA13_DISTRIBUTION_OS_PK PRIMARY KEY (DISTRIBUTION_OS_ID))';
     
      EXECUTE IMMEDIATE 'CREATE TABLE RCA13_PLATFORM
  (PLATFORM_ID VARCHAR2(40 BYTE) NOT NULL ENABLE,  
    NAME VARCHAR2(100 BYTE) NOT NULL ENABLE,
    PRODUCT_LINE_ID          NUMBER,
    IS_PREFERRED NUMBER(1,0) DEFAULT 0,
    CONSTRAINT RCA13_PLATFORM_REF_UNQ_NAME UNIQUE (NAME),
    CONSTRAINT RCA13_PLATFORM_REF_PK PRIMARY KEY (PLATFORM_ID))';
    
    EXECUTE IMMEDIATE 'CREATE TABLE RCA13_ORACHK_LINK
   (SF_LINK_ID VARCHAR2(40 BYTE) DEFAULT SYS_GUID() NOT NULL ENABLE,
    NAME VARCHAR2(200 BYTE) NOT NULL ENABLE,
    LINK VARCHAR2(1000 BYTE),
    TYPE  NUMBER,
   CONSTRAINT RCA13_SF_LINK_PK PRIMARY KEY (SF_LINK_ID))';
   
      -- For detail based on check_id
   EXECUTE IMMEDIATE 'CREATE TABLE RCA13_ORACHK_CHECKS_DB_TYPES
   (CHECK_ID VARCHAR2(40 BYTE) NOT NULL ENABLE,  
    DATABASE_TYPE_ID VARCHAR2(40 BYTE),   
   CONSTRAINT RCA13_dbtype_fk FOREIGN KEY (DATABASE_TYPE_ID) REFERENCES RCA13_ORACHK_DB_TYPES_MASTER(DATABASE_TYPE_ID))';
   
 
 
   EXECUTE IMMEDIATE 'CREATE TABLE RCA13_ORACHK_CHECKS_DB_ROLES
   (CHECK_ID VARCHAR2(40 BYTE) NOT NULL ENABLE,  
    DATABASE_ROLE_ID VARCHAR2(40 BYTE),  
    CONSTRAINT RCA13_dbrole_fk FOREIGN KEY (DATABASE_ROLE_ID) REFERENCES RCA13_ORACHK_DB_ROLES_MASTER(DATABASE_ROLE_ID))';
   
   
 
  EXECUTE IMMEDIATE 'CREATE TABLE RCA13_ORACHK_CHECKS_DB_MODES
   (CHECK_ID VARCHAR2(40 BYTE) NOT NULL ENABLE,  
    DATABASE_MODE_ID VARCHAR2(40 BYTE),
    CONSTRAINT RCA13_dbmode_fk FOREIGN KEY (DATABASE_MODE_ID) REFERENCES RCA13_ORACHK_DB_MODES_MASTER(DATABASE_MODE_ID)    
   )';
   
 
   EXECUTE IMMEDIATE 'CREATE TABLE RCA13_ORACHK_CHECKS_LINK
   (CHECK_ID VARCHAR2(40 BYTE) NOT NULL ENABLE,  
    SF_LINK_ID VARCHAR2(40 BYTE),
    CONSTRAINT RCA13_sflink_fk FOREIGN KEY (SF_LINK_ID) REFERENCES RCA13_ORACHK_LINK(SF_LINK_ID)
   )';
   
   EXECUTE IMMEDIATE 'CREATE TABLE RCA13_ORACHK_CHECKS_PLATFORM
   (CHECK_ID VARCHAR2(40 BYTE) NOT NULL ENABLE,  
    PLATFORM_ID VARCHAR2(40 BYTE),
    DISTRIBUTION_OS_ID VARCHAR2(40 BYTE),
    CONSTRAINT RCA13_platform_fk FOREIGN KEY (PLATFORM_ID) REFERENCES RCA13_PLATFORM(PLATFORM_ID),
    CONSTRAINT RCA13_distribution_fk FOREIGN KEY (DISTRIBUTION_OS_ID) REFERENCES RCA13_DISTRIBUTION(DISTRIBUTION_OS_ID)
   )';
   
      EXECUTE IMMEDIATE 'CREATE TABLE RCA13_ORACHK_CHECKS_VERSION
   (CHECK_ID VARCHAR2(40 BYTE) NOT NULL ENABLE,  
    VERSION_ID VARCHAR2(40 BYTE),
    CONSTRAINT RCA13_version_fk FOREIGN KEY (VERSION_ID) REFERENCES RCA13_VERSION(VERSION_ID)
   )';

     EXECUTE IMMEDIATE 'CREATE TABLE RCA13_ORACHK_CHECKS_CAND_SYS
(CHECK_ID VARCHAR2(40 BYTE) NOT NULL ENABLE,  
CAND_SYS_ID VARCHAR2(40 BYTE),
CONSTRAINT RCA13_candsys_fk FOREIGN KEY (CAND_SYS_ID) REFERENCES RCA13_ORACHK_CAND_SYS(CAND_SYS_ID)
)';     
   
   EXECUTE IMMEDIATE 'CREATE SEQUENCE PARAMPATHSEQ
      INCREMENT BY 1
      START WITH 1
      MAXVALUE   999999999999999999
      NOCACHE
      NOCYCLE';
      
elsif rec.bid=20160115000000 then
    -- DDL changes done for 12.1.0.2.6
   EXECUTE IMMEDIATE 'alter table rca13_orachk_audit_Checks add USER_COMMENTS VARCHAR2(4000)';    
   EXECUTE IMMEDIATE 'alter table rca13_user_details add emailalert varchar2(50)';    
   EXECUTE IMMEDIATE 'alter table rca13_user_details add tablespacealert varchar2(50)';  
   EXECUTE IMMEDIATE 'ALTER TABLE RCA13_COLLECTIONS_DIFF ADD DIFF_TYPE VARCHAR2(50)';
   EXECUTE IMMEDIATE 'CREATE TABLE RCA13_EXCEPTION_LOG(TEXT VARCHAR2(4000),LOG_DATE TIMESTAMP DEFAULT SYSTIMESTAMP)';

elsif rec.bid=20160516000000 then
    -- Introduced purging job in 12.1.0.2.7
   begin
   insert into rca13_intrack_preferences(id,preference_name,preference_value,preference_description) values(14,'PURGE_JOB_INTERVAL',3,'MONTHLY');
   insert into rca13_intrack_preferences(id,preference_name,preference_value,preference_description) values(15,'CAPTURE_USER_DETAIL','Y','Capture user detail when they login,if yes(Y)');
   commit;
   exception when dup_val_on_index then null;
   end;
       
elsif rec.bid = 20160831000000 then
         --Introduced the theme in beta of 12.2.0.1.1
    null;
elsif rec.bid = 20160916000000 then
    null;
    
 end if;    
end loop;
end;
/

--- checking COLLECTION_DATE column datatype in AUDITCHECK_PATCH_RESULT table--------   
declare
isDataType number;
begin
select count(1) into isDataType from user_tab_columns where table_name = 'AUDITCHECK_PATCH_RESULT'
and column_name ='COLLECTION_DATE' and data_type='TIMESTAMP(9) WITH LOCAL TIME ZONE';
if isDataType = 1 then
     EXECUTE IMMEDIATE 'alter table auditcheck_patch_result rename column COLLECTION_DATE to COLLECTION_DATE_TEMP';
     EXECUTE IMMEDIATE 'alter table auditcheck_patch_result add (COLLECTION_DATE TIMESTAMP(6))';
     end if;
end;
/
declare
isColExists number;
begin
select count(1) into isColExists from user_tab_columns where table_name = 'AUDITCHECK_PATCH_RESULT'
and column_name ='COLLECTION_DATE_TEMP';
if isColExists = 1 then
     EXECUTE IMMEDIATE 'update auditcheck_patch_result set COLLECTION_DATE = COLLECTION_DATE_TEMP';                                    
     commit;                                                                                                       
     EXECUTE IMMEDIATE 'alter table auditcheck_patch_result modify COLLECTION_DATE NOT NULL';                      
     EXECUTE IMMEDIATE 'alter table auditcheck_patch_result drop column COLLECTION_DATE_TEMP';
 end if;
end;
/
DECLARE
  A NUMBER(1) := 0;    
begin
  SELECT CASE WHEN EXISTS(SELECT * FROM USER_INDEXES WHERE INDEX_NAME = 'AUDITCHECK_PATCH_RESULT_CD')
         THEN 1
         ELSE 0
         END CASE INTO A
    FROM DUAL;
  
  IF A = 0 THEN
    execute immediate ' CREATE INDEX AUDITCHECK_PATCH_RESULT_CD ON AUDITCHECK_PATCH_RESULT  ("COLLECTION_DATE") ';
  END IF;  
end;
/    
--manage parameters 
create or replace PACKAGE RCA13_MANAGE_PARAMS AS 
 procedure processParamFiles(collectionId varchar2);
END RCA13_MANAGE_PARAMS;
/

create or replace PACKAGE BODY RCA13_MANAGE_PARAMS AS

--------------------------------------------------------------------------------
procedure processParamFiles(collectionId varchar2) is 
  CURSOR cur IS SELECT COLLECTION_FILE_ID cfid,short_file_name sfn FROM rca13_COLLECTION_FILES
  WHERE COLLECTION_ID = collectionId and short_file_name like 'd_v_parameter_%.out' 
  and short_file_name not like 'd_v_parameter_u_%.out'
  ORDER BY short_file_name;
  dbName varchar2(128);
  instName varchar2(128);
  nameF varchar2(256);
  valueF varchar2(512);
BEGIN
  for rec1 in cur loop
    --Get db name
    dbName := substr(rec1.sfn,15,length(rec1.sfn)-18);
    for line in ( select line_text lt from rca13_collection_file_data where collection_file_id = rec1.cfid order by line_number ) loop 
      nameF  := trim(substr(line.lt,1,(instr(line.lt ,'=',1,1)-1)));
      valueF := trim(substr(line.lt,(instr(line.lt , '=' ,1,1)+1)));       
      -- Get db instName from name      
      instName :=  substr(nameF,1,instr(nameF,'.',1,1)-1);
      nameF := substr(nameF,(instr(nameF,'.',1,1)+1));
      continue when nameF is null OR instName is null;
      insert into rca13_parameters(collection_id,DB_NAME,INSTANCE_NAME,PARAM_NAME,VALUE)
      values (collectionId,dbName,instName,nameF,valueF);
    end loop;
    commit;
  end loop;
END;
--------------------------------------------------------------------------------
END RCA13_MANAGE_PARAMS;
/
    
    
--Manage Zips
create or replace PACKAGE RCA13_MANAGE_ZIPS AS 
  type file_list is table of clob;
  function file2blob    ( p_dir varchar2    , p_file_name varchar2    )  return blob;
  function get_file_list    ( p_dir varchar2    , p_zip_file varchar2    , p_encoding varchar2 := null    )  return file_list;
  function get_file_list    ( p_zipped_blob blob    , p_encoding varchar2 := null    )  return file_list;
  function get_file    ( p_dir varchar2    , p_zip_file varchar2    , p_file_name varchar2    , p_encoding varchar2 := null    )  return blob;
  function get_file    ( p_zipped_blob blob    , p_file_name varchar2    , p_encoding varchar2 := null    )  return blob;
  procedure add1file    ( p_zipped_blob in out blob    , p_name varchar2    , p_content blob    );
  procedure finish_zip( p_zipped_blob in out blob );
 
  function blob2num( p_blob blob, p_len integer, p_pos integer )  return number;
  
  function raw2varchar2( p_raw raw, p_encoding varchar2 )  return varchar2;
  
  function little_endian( p_big number, p_bytes pls_integer := 4 ) return raw;
END RCA13_MANAGE_ZIPS;

/

create or replace 
PACKAGE BODY RCA13_MANAGE_ZIPS AS
 --
  c_LOCAL_FILE_HEADER        constant raw(4) := hextoraw( '504B0304' ); -- Local file header signature
  c_END_OF_CENTRAL_DIRECTORY constant raw(4) := hextoraw( '504B0506' ); -- End of central directory signature
--
  function blob2num( p_blob blob, p_len integer, p_pos integer )
  return number
  is
  begin
    return utl_raw.cast_to_binary_integer( dbms_lob.substr( p_blob, p_len, p_pos ), utl_raw.little_endian );
  end;
--
  function raw2varchar2( p_raw raw, p_encoding varchar2 )
  return varchar2
  is
  begin
    return coalesce( utl_i18n.raw_to_char( p_raw, p_encoding )
                   , utl_i18n.raw_to_char( p_raw, utl_i18n.map_charset( p_encoding, utl_i18n.GENERIC_CONTEXT, utl_i18n.IANA_TO_ORACLE ) )
                   );
  end;
--
  function little_endian( p_big number, p_bytes pls_integer := 4 )
  return raw
  is
  begin
    return utl_raw.substr( utl_raw.cast_from_binary_integer( p_big, utl_raw.little_endian ), 1, p_bytes );
  end;
--
  function file2blob    ( p_dir varchar2    , p_file_name varchar2    )
  return blob
  is
    file_lob bfile;
    file_blob blob;
  begin
    file_lob := bfilename( p_dir, p_file_name );
    dbms_lob.open( file_lob, dbms_lob.file_readonly );
    dbms_lob.createtemporary( file_blob, true );
    dbms_lob.loadfromfile( file_blob, file_lob, dbms_lob.lobmaxsize );
    dbms_lob.close( file_lob );
    return file_blob;
  exception
    when others then
      if dbms_lob.isopen( file_lob ) = 1
      then
        dbms_lob.close( file_lob );
      end if;
      if dbms_lob.istemporary( file_blob ) = 1
      then
        dbms_lob.freetemporary( file_blob );
      end if;
      raise;
  end;
--
  function get_file_list     ( p_zipped_blob blob , p_encoding varchar2 := null    )
  return file_list
  is
    t_ind integer;
    t_hd_ind integer;
    t_rv file_list;
    t_encoding varchar2(32767);
  begin
    t_ind := dbms_lob.getlength( p_zipped_blob ) - 21;
    loop
      exit when t_ind < 1 or dbms_lob.substr( p_zipped_blob, 4, t_ind ) = c_END_OF_CENTRAL_DIRECTORY;
      t_ind := t_ind - 1;
    end loop;
--
    if t_ind <= 0
    then
      return null;
    end if;
--
    t_hd_ind := blob2num( p_zipped_blob, 4, t_ind + 16 ) + 1;
    t_rv := file_list();
    t_rv.extend( blob2num( p_zipped_blob, 2, t_ind + 10 ) );
    for i in 1 .. blob2num( p_zipped_blob, 2, t_ind + 8 )
    loop
      if p_encoding is null
      then
        if utl_raw.bit_and( dbms_lob.substr( p_zipped_blob, 1, t_hd_ind + 9 ), hextoraw( '08' ) ) = hextoraw( '08' )
        then  
          t_encoding := 'AL32UTF8'; -- utf8
        else
          t_encoding := 'US8PC437'; -- IBM codepage 437
        end if;
      else
        t_encoding := p_encoding;
      end if;
      t_rv( i ) := raw2varchar2
                     ( dbms_lob.substr( p_zipped_blob
                                      , blob2num( p_zipped_blob, 2, t_hd_ind + 28 )
                                      , t_hd_ind + 46
                                      )
                     , t_encoding
                     );
      t_hd_ind := t_hd_ind + 46
                + blob2num( p_zipped_blob, 2, t_hd_ind + 28 )  -- File name length
                + blob2num( p_zipped_blob, 2, t_hd_ind + 30 )  -- Extra field length
                + blob2num( p_zipped_blob, 2, t_hd_ind + 32 ); -- File comment length
    end loop;
--
    return t_rv;
  end;
--
  function get_file_list     ( p_dir varchar2    , p_zip_file varchar2    , p_encoding varchar2 := null    )
  return file_list
  is
  begin
    return get_file_list( file2blob( p_dir, p_zip_file ), p_encoding );
  end;
--
  function get_file
    ( p_zipped_blob blob
    , p_file_name varchar2
    , p_encoding varchar2 := null
    )
  return blob
  is
    t_tmp blob;
    t_ind integer;
    t_hd_ind integer;
    t_fl_ind integer;
    t_encoding varchar2(32767);
    t_len integer;
  begin
    t_ind := dbms_lob.getlength( p_zipped_blob ) - 21;
    loop
      exit when t_ind < 1 or dbms_lob.substr( p_zipped_blob, 4, t_ind ) = c_END_OF_CENTRAL_DIRECTORY;
      t_ind := t_ind - 1;
    end loop;
--
    if t_ind <= 0
    then
      return null;
    end if;
--
    t_hd_ind := blob2num( p_zipped_blob, 4, t_ind + 16 ) + 1;
    for i in 1 .. blob2num( p_zipped_blob, 2, t_ind + 8 )
    loop
      if p_encoding is null
      then
        if utl_raw.bit_and( dbms_lob.substr( p_zipped_blob, 1, t_hd_ind + 9 ), hextoraw( '08' ) ) = hextoraw( '08' )
        then  
          t_encoding := 'AL32UTF8'; -- utf8
        else
          t_encoding := 'US8PC437'; -- IBM codepage 437
        end if;
      else
        t_encoding := p_encoding;
      end if;
      if p_file_name = raw2varchar2
                         ( dbms_lob.substr( p_zipped_blob
                                          , blob2num( p_zipped_blob, 2, t_hd_ind + 28 )
                                          , t_hd_ind + 46
                                          )
                         , t_encoding
                         )
      then
        t_len := blob2num( p_zipped_blob, 4, t_hd_ind + 24 ); -- uncompressed length 
        if t_len = 0
        then
          if substr( p_file_name, -1 ) in ( '/', '\' )
          then  -- directory/folder
            return null;
          else -- empty file
            return empty_blob();
          end if;
        end if;
--
        if dbms_lob.substr( p_zipped_blob, 2, t_hd_ind + 10 ) = hextoraw( '0800' ) -- deflate
        then
          t_fl_ind := blob2num( p_zipped_blob, 4, t_hd_ind + 42 );
          t_tmp := hextoraw( '1F8B0800000000000003' ); -- gzip header
          dbms_lob.copy( t_tmp
                       , p_zipped_blob
                       ,  blob2num( p_zipped_blob, 4, t_hd_ind + 20 )
                       , 11
                       , t_fl_ind + 31
                       + blob2num( p_zipped_blob, 2, t_fl_ind + 27 ) -- File name length
                       + blob2num( p_zipped_blob, 2, t_fl_ind + 29 ) -- Extra field length
                       );
          dbms_lob.append( t_tmp, utl_raw.concat( dbms_lob.substr( p_zipped_blob, 4, t_hd_ind + 16 ) -- CRC32
                                                , little_endian( t_len ) -- uncompressed length
                                                )
                         );
          return utl_compress.lz_uncompress( t_tmp );
        end if;
--
        if dbms_lob.substr( p_zipped_blob, 2, t_hd_ind + 10 ) = hextoraw( '0000' ) -- The file is stored (no compression)
        then
          t_fl_ind := blob2num( p_zipped_blob, 4, t_hd_ind + 42 );
          dbms_lob.createtemporary( t_tmp, true );
          dbms_lob.copy( t_tmp
                       , p_zipped_blob
                       , t_len
                       , 1
                       , t_fl_ind + 31
                       + blob2num( p_zipped_blob, 2, t_fl_ind + 27 ) -- File name length
                       + blob2num( p_zipped_blob, 2, t_fl_ind + 29 ) -- Extra field length
                       );
          return t_tmp;
        end if;
      end if;
      t_hd_ind := t_hd_ind + 46
                + blob2num( p_zipped_blob, 2, t_hd_ind + 28 )  -- File name length
                + blob2num( p_zipped_blob, 2, t_hd_ind + 30 )  -- Extra field length
                + blob2num( p_zipped_blob, 2, t_hd_ind + 32 ); -- File comment length
    end loop;
--
    return null;
  end;
--
  function get_file
    ( p_dir varchar2
    , p_zip_file varchar2
    , p_file_name varchar2
    , p_encoding varchar2 := null
    )
  return blob
  is
  begin
    return get_file( file2blob( p_dir, p_zip_file ), p_file_name, p_encoding );
  end;
--
  procedure add1file     ( p_zipped_blob in out blob    , p_name varchar2    , p_content blob    )  is
    t_now date;
    t_blob blob;
    t_len integer;
    t_clen integer;
    t_crc32 raw(4) := hextoraw( '00000000' );
    t_compressed boolean := false;
    t_name raw(32767);
  begin
    t_now := sysdate;
    t_len := nvl( dbms_lob.getlength( p_content ), 0 );
    if t_len > 0
    then 
      t_blob := utl_compress.lz_compress( p_content );
      t_clen := dbms_lob.getlength( t_blob ) - 18;
      t_compressed := t_clen < t_len;
      t_crc32 := dbms_lob.substr( t_blob, 4, t_clen + 11 );       
    end if;
    if not t_compressed
    then 
      t_clen := t_len;
      t_blob := p_content;
    end if;
    if p_zipped_blob is null
    then
      dbms_lob.createtemporary( p_zipped_blob, true );
    end if;
    t_name := utl_i18n.string_to_raw( p_name, 'AL32UTF8' );
    dbms_lob.append( p_zipped_blob
                   , utl_raw.concat( c_LOCAL_FILE_HEADER -- Local file header signature
                                   , hextoraw( '1400' )  -- version 2.0
                                   , case when t_name = utl_i18n.string_to_raw( p_name, 'US8PC437' )
                                       then hextoraw( '0000' ) -- no General purpose bits
                                       else hextoraw( '0008' ) -- set Language encoding flag (EFS)
                                     end 
                                   , case when t_compressed
                                        then hextoraw( '0800' ) -- deflate
                                        else hextoraw( '0000' ) -- stored
                                     end
                                   , little_endian( to_number( to_char( t_now, 'ss' ) ) / 2
                                                  + to_number( to_char( t_now, 'mi' ) ) * 32
                                                  + to_number( to_char( t_now, 'hh24' ) ) * 2048
                                                  , 2
                                                  ) -- File last modification time
                                   , little_endian( to_number( to_char( t_now, 'dd' ) )
                                                  + to_number( to_char( t_now, 'mm' ) ) * 32
                                                  + ( to_number( to_char( t_now, 'yyyy' ) ) - 1980 ) * 512
                                                  , 2
                                                  ) -- File last modification date
                                   , t_crc32 -- CRC-32
                                   , little_endian( t_clen )                      -- compressed size
                                   , little_endian( t_len )                       -- uncompressed size
                                   , little_endian( utl_raw.length( t_name ), 2 ) -- File name length
                                   , hextoraw( '0000' )                           -- Extra field length
                                   , t_name                                       -- File name
                                   )
                   );
    if t_compressed
    then                   
      dbms_lob.copy( p_zipped_blob, t_blob, t_clen, dbms_lob.getlength( p_zipped_blob ) + 1, 11 ); -- compressed content
    elsif t_clen > 0
    then                   
      dbms_lob.copy( p_zipped_blob, t_blob, t_clen, dbms_lob.getlength( p_zipped_blob ) + 1, 1 ); --  content
    end if;
    if dbms_lob.istemporary( t_blob ) = 1
    then      
      dbms_lob.freetemporary( t_blob );
    end if;
  end;
--
  procedure finish_zip( p_zipped_blob in out blob )
  is
    t_cnt pls_integer := 0;
    t_offs integer;
    t_offs_dir_header integer;
    t_offs_end_header integer;
    t_comment raw(32767) := utl_raw.cast_to_raw( 'Implementation by Anton Scheffer' );
  begin
    t_offs_dir_header := dbms_lob.getlength( p_zipped_blob );
    t_offs := 1;
    while dbms_lob.substr( p_zipped_blob, utl_raw.length( c_LOCAL_FILE_HEADER ), t_offs ) = c_LOCAL_FILE_HEADER
    loop
      t_cnt := t_cnt + 1;
      dbms_lob.append( p_zipped_blob
                     , utl_raw.concat( hextoraw( '504B0102' )      -- Central directory file header signature
                                     , hextoraw( '1400' )          -- version 2.0
                                     , dbms_lob.substr( p_zipped_blob, 26, t_offs + 4 )
                                     , hextoraw( '0000' )          -- File comment length
                                     , hextoraw( '0000' )          -- Disk number where file starts
                                     , hextoraw( '0000' )          -- Internal file attributes => 
                                                                   --     0000 binary file
                                                                   --     0100 (ascii)text file
                                     , case
                                         when dbms_lob.substr( p_zipped_blob
                                                             , 1
                                                             , t_offs + 30 + blob2num( p_zipped_blob, 2, t_offs + 26 ) - 1
                                                             ) in ( hextoraw( '2F' ) -- /
                                                                  , hextoraw( '5C' ) -- \
                                                                  )
                                         then hextoraw( '10000000' ) -- a directory/folder
                                         else hextoraw( '2000B681' ) -- a file
                                       end                         -- External file attributes
                                     , little_endian( t_offs - 1 ) -- Relative offset of local file header
                                     , dbms_lob.substr( p_zipped_blob
                                                      , blob2num( p_zipped_blob, 2, t_offs + 26 )
                                                      , t_offs + 30
                                                      )            -- File name
                                     )
                     );
      t_offs := t_offs + 30 + blob2num( p_zipped_blob, 4, t_offs + 18 )  -- compressed size
                            + blob2num( p_zipped_blob, 2, t_offs + 26 )  -- File name length 
                            + blob2num( p_zipped_blob, 2, t_offs + 28 ); -- Extra field length
    end loop;
    t_offs_end_header := dbms_lob.getlength( p_zipped_blob );
    dbms_lob.append( p_zipped_blob
                   , utl_raw.concat( c_END_OF_CENTRAL_DIRECTORY                                -- End of central directory signature
                                   , hextoraw( '0000' )                                        -- Number of this disk
                                   , hextoraw( '0000' )                                        -- Disk where central directory starts
                                   , little_endian( t_cnt, 2 )                                 -- Number of central directory records on this disk
                                   , little_endian( t_cnt, 2 )                                 -- Total number of central directory records
                                   , little_endian( t_offs_end_header - t_offs_dir_header )    -- Size of central directory
                                   , little_endian( t_offs_dir_header )                        -- Offset of start of central directory, relative to start of archive
                                   , little_endian( nvl( utl_raw.length( t_comment ), 0 ), 2 ) -- ZIP file comment length
                                   , t_comment
                                   )
                   );
  end;
END RCA13_MANAGE_ZIPS;

/    
    

--Manage Collections
-- No harm in running packages in upgrade scripts

create or replace PACKAGE RCA13_MANAGE_COLLECTIONS AS
procedure process_collection(docId number);
function blob2clob( blobData BLOB ) return clob;
function blob_to_clob( blob_in BLOB ) return clob;
procedure parseRCFiles(collectionId varchar2,docId number);
procedure deleteCollection ( docId number,keep_zip number default 0);
function hasDiffWithPrevRun(cName varchar2,cDate timestamp) return varchar2;
function hasDiff (pcName varchar2,pcDate timestamp,cName varchar2,cDate timestamp) return number;
procedure submitJob(docId in number,user varchar2 default 'ORACHK.USER');
procedure submitJob4All;
procedure getChecksInfo ( fileId varchar2,source varchar2 );
procedure insertAuditChecks ( fileId varchar2,collectId varchar2,docId number );
procedure classifyCollections;
procedure classifyCollection(cDate timestamp,cName varchar2 );
procedure updateMDtable;
procedure afterColInUpActs( collectionDate timestamp,collectionName varchar2,flag number default 1 );
procedure purgeData(dat timestamp);
procedure submitDataPurgeJob(dat timestamp);
procedure processAuditData;
procedure monitorDiffType;
procedure ignoreReCalValues_AIAD(sysId varchar2,collectionDate timestamp,colName varchar2);
END RCA13_MANAGE_COLLECTIONS;
/
    
create or replace PACKAGE BODY rca13_MANAGE_COLLECTIONS AS
LOCAL_NODE varchar2(40);
RACCHECK_ENV_FILE_ID varchar2(40);
ISCRSINSTALLED number;
ISASMINSTALLED number;
ASMHOME varchar2(128);
APP_USER varchar2(64);
COLLECTION_NAME varchar2(256);
IS_UPGRADE_MODE number := 0;
TARGET_VERSION varchar2(40);
isExadata number;
kitId varchar2(40);
--------------------------------------------------------------------------------
PROCEDURE log_text(
    text         VARCHAR2,
    collectionId VARCHAR2,docId number default null)
IS
BEGIN
  INSERT INTO rca13_LOG (COLLECTION_ID,TEXT,INS_DATE,DOC_ID)
  VALUES (collectionId,text,LOCALTIMESTAMP,docId);
  COMMIT;
END;
--------------------------------------------------------------------------------
procedure update_collection_status ( collectionId varchar2,statusMsg varchar2,failComment varchar2 default null ) is
begin
 update rca13_collections set status = statusMsg,fail_comment = failComment where collection_id = collectionId;
 commit;
end;
--------------------------------------------------------------------------------
procedure getChecksInfo ( fileId varchar2, source varchar2 ) is
 cursor cur is select line_text lt,line_number ln from rca13_COLLECTION_FILE_DATA  
 where COLLECTION_FILE_ID = fileId order by line_number;
 readingOn number := 0;
 checkId varchar2(40);
 text clob;
 line varchar2(4000);
 cnt number;
 pLength number;
begin
  -- start line for each check <div id="E3508B6664085B53E04313C0E50AC2CA_contents">
  -- Get check id from above line
  -- Start of recommendation: after <td>Recommendation</td>, take <td> to </td>
  --dbms_output.put_line('fileId='||fileId);
 if source = 'HTML' then
  for rec in cur loop
    line := rec.lt;
    if line like '%<div id="%_contents">%' then
      SELECT regexp_substr(line,'"[^"]+_') into checkId FROM dual;
      --OP:"E3508B6664085B53E04313C0E50AC2CA_
      checkId := substr(checkId,2,length(checkId)-2);      
      --dbms_output.put_line('checkId='||checkId);
    end if;
    if line like '%<tr><td>Recommendation</td><td><pre>%' OR line like '%<tr><td scope="row">Recommendation</td><td scope="row"><pre>%' then
      text := replace(line,'<tr><td>Recommendation</td><td><pre>');
      text := replace(line,'<tr><td scope="row">Recommendation</td><td scope="row"><pre>');
      readingOn := 1;
      continue;
    end if;
    --Start getting the recommendation
    if readingOn = 1 then      
      if nvl(line,'z') like '%</pre>%' then
        readingOn := 0;
        --Inesrt data into table if not exists
        select count(1) into cnt from rca13_checks_info where check_id = checkId;        
        if cnt = 0 and checkId is not null then
          begin
           insert into rca13_checks_info ( check_id,recommendation) values(checkId,text);
           exception when dup_val_on_index then null;
          end;
        elsif cnt > 0 and checkId is not null then
          select dbms_lob.getlength(recommendation) into pLength from rca13_checks_info where check_id = checkId and rownum = 1;
          if dbms_lob.getlength(text) > pLength  then
            update rca13_checks_info set recommendation = text where check_id = checkId;
          end if;  
        end if;
        commit;
        --Reset all things
        text := NULL;
        checkId := NULL;
      else
        text := text||chr(10)||line;
      end if;
    end if;
  end loop;
 elsif source = 'XML' then
  for rec in cur loop
    line := rec.lt;
    if line like '%<Check id="%">%' then
      SELECT regexp_substr(line,'"[^"]+"') into checkId FROM dual;
      --OP:"E3508B6664085B53E04313C0E50AC2CA_
      checkId := substr(checkId,2,length(checkId)-2);      
      --dbms_output.put_line('checkId='||checkId);
      readingOn := 1;
      continue;
    end if;    
    --Start getting the recommendation
    if readingOn = 1 then      
      if nvl(line,'z') like '%</Check>%' then
        readingOn := 0;
        --Insert data into table if not exists
        select count(1) into cnt from rca13_checks_info where check_id = checkId;        
        if cnt = 0 and checkId is not null then
          begin
           insert into rca13_checks_info ( check_id,recommendation) values(checkId,text);
           exception when dup_val_on_index then null;
          end;
        elsif cnt > 0 and checkId is not null then
          select dbms_lob.getlength(recommendation) into pLength from rca13_checks_info where check_id = checkId and rownum = 1;
          if dbms_lob.getlength(text) > pLength  then
            update rca13_checks_info set recommendation = text where check_id = checkId;
          end if;  
        end if;
        commit;
        --Reset all things
        text := NULL;
        checkId := NULL;
      else
        if line like '%<Recommendation>%' then
          line := replace(line,'<Recommendation>');
        elsif line like '%</Recommendation>%' then   
          line := replace(line,'</Recommendation>');
        elsif line like '%<Links>%' then
          line := replace(line,'<Links>','<br>Links:<br>');
        elsif line like '%</Links>%' then
          line := replace(line,'</Links>');
        end if;
        --line := replace(line,'<![CDATA[');
        line := replace(line,']]>');
        text := text||chr(10)||line;
      end if;
    end if;
  end loop;
 end if;
end;
--------------------------------------------------------------------------------
procedure insertAuditChecks ( fileId varchar2,collectId varchar2,docId number ) is
 fileId_local varchar2(40) := TRIM(BOTH '''' FROM DBMS_ASSERT.ENQUOTE_LITERAL(fileId));
 collectionId varchar2(40) := TRIM(BOTH '''' FROM DBMS_ASSERT.ENQUOTE_LITERAL(collectId));
 docId_local number := docId;
 cursor cur is select line_text from rca13_collection_file_data where collection_file_id = fileId_local;
 statement varchar2(4000);
 cDate timestamp(6);
 cName varchar2(1000);
 cnt number;
 newScore number;
begin
 log_text('START: Started inserting AuditChecks into auditcheck_result table',collectionId,docId_local);
  if fileId is null or collectionId is null then
   return;
 end if;  
 --If checks inserted already then update collection_id column value
 select collection_date,collection_name into cDate,cName from rca13_collections where collection_id = collectionId;
  if cDate is not null and cName is not null then
   select count(1) into cnt from auditcheck_result where collection_date = cDate and upload_collection_name = cName;
 else
   --Depend on collection_date
   --select count(1) into cnt from auditcheck_result where upload_collection_name = cName;
   return;
 end if;
 
 if cnt > 0 then
  log_text('DUPLICATE: Audit checks are already inserted in auditcheck_result table, Just update collection_id and exit',collectionId,docId_local);
  --Just update the collection_id in rca13_collections and rca13_collections_md
  update auditcheck_result set collection_id = collectionId where collection_date = cDate and upload_collection_name = cName;  
  commit;
  update rca13_collections_md set collection_id = collectionId where collection_date = cDate and collection_name = cName;  
  commit;
  -- Since we are using skipped checks also to calculate score. recalculate the score value.
  newScore := RCA13_GET_DATA4COLUMNS.getCollectionScore(collectionId,cName,cDate);
  update rca13_collection_values set score = newScore where collection_date  = cDate and collection_name = cName;
  commit;
  return;
 end if;
  for rec in cur loop
   begin
     statement := rec.line_text;
     statement := trim(statement);
     -- Need to remove ; at the end of line   
     statement := rtrim(statement,';');
     -- To Avoid java script injections replace < and >
     if instr(statement,'<') > 0 or instr(statement,'>') > 0 then
       statement := replace(replace(statement,'<',chr(38)||'lt;'),'>',chr(38)||'gt;');
     end if;
     --Also, we need to change/add the table name.
     if instr(lower(statement),'auditcheck_result(') = 0 then
       statement := 'insert into auditcheck_result '||substr(statement,instr(statement,'(',1,1));
     end if;
     --To avoid sql injections check whether statement is started with insert into auditcheck_result or not
     continue when ( instr(lower(statement),'insert into auditcheck_result') != 1 );
     -- Add collection_id column value
     statement := regexp_replace(statement,'\)',',collection_id)',1,1);
     statement := regexp_replace(statement,'\)',','''||collectionId||''')',instr(statement,')',-1,1),1);
     execute immediate statement;
     exception when others then
       log_text('FAIL: Failed to execute: '||statement,collectionId,docId_local);  
   end;
 end loop;
 commit;
 log_text('INSERT: Finished inserting checks into auditcheck_result table',collectionId,docId_local);
 --Now insert into Metadata table -- Don't do it here .. do it from job
 --begin
 --  insert into RCA13_COLLECTIONS_MD(collection_date,collection_name,collection_id)
 --  values(cDate,cName,collectionId);
 --  commit;
 --  exception when dup_val_on_index then null;
 -- end;
 exception when others then
  log_text('FAIL: Audit checks insertion failed',collectionId,docId_local);
end;
--------------------------------------------------------------------------------
procedure insertAuditPatchChecks ( fileId varchar2,collectId varchar2,docId number ) is
 collectionId varchar2(40) := TRIM(BOTH '''' FROM DBMS_ASSERT.ENQUOTE_LITERAL(collectId));
 fileId_local varchar2(40) := TRIM(BOTH '''' FROM DBMS_ASSERT.ENQUOTE_LITERAL(fileId));
 cursor cur is select line_text from rca13_collection_file_data where collection_file_id = fileId_local;
 statement varchar2(4000);
 cDate timestamp(6);
 cName varchar2(1000);
 cnt number;
begin
 log_text('START: Started inserting AuditPatchChecks into auditcheck_patch_result table',collectionId,docId);
 if fileId_local is null or collectionId is null then
   return;
 end if;  
 --If checks inserted already then update collection_id column value
 select collection_date,collection_name into cDate,cName from rca13_collections where collection_id = collectionId;
  if cDate is not null then
   select count(1) into cnt from auditcheck_patch_result where collection_date = cDate;
 else
 return;
 end if;
 if cnt > 0 then
  --Just update the collection_id column
  --if cDate is not null then
  -- update auditcheck_patch_result set collection_id = collectionId where collection_date = cDate and upload_collection_name = cName;
  --else
   --update auditcheck_result set collection_id = collectionId where upload_collection_name = cName;
  --end if;
  --commit;
  log_text('DUPLICATE: Auditcheck patch results are already inserted into auditcheck_patch_result table, so exit',collectionId,docId);
  return;
 end if;
  for rec in cur loop
  begin
   statement := rec.line_text;
   statement := trim(statement);
   -- Need to remove ; at the end of line
   statement := rtrim(statement,';');
   -- To Avoid java script injections replace < and >
   if instr(statement,'<') > 0 or instr(statement,'>') > 0 then
     statement := replace(replace(statement,'<',chr(38)||'lt;'),'>',chr(38)||'gt;');
   end if;
   --Also, we need to change/add the table name.
   if instr(lower(statement),'auditcheck_patch_result(') = 0 then
     statement := 'insert into auditcheck_patch_result '||substr(statement,instr(statement,'(',1,1));
   end if;
   --To avoid sql injections check whether statement is started with insert into auditcheck_result or not
   continue when ( instr(lower(statement),'insert into auditcheck_patch_result') != 1 );    
   execute immediate statement;   
  exception when others then null;
  end;
 end loop;
 commit;
 log_text('FINISH: Finished inserting patch result checks into auditcheck_patch_result table',collectionId,docId);
 exception when others then
  log_text('FAIL: Audit Patch checks insertion failed',collectionId,docId);
end;
------------------------------------------------------------------------------------------
PROCEDURE process_collection  (  docId IN number  ) IS
  collectionId varchar2(40);  
  files rca13_manage_zips.file_list;
  colBlob BLOB;
  fileBlob BLOB;
  cFileId  VARCHAR2(40);
  fnShort  VARCHAR2(500);
  fSize    NUMBER;
  lCounter NUMBER := 0;
  fContent CLOB;
  lText      VARCHAR2(4000);
    lTextlong      VARCHAR2(4000);
  colName    VARCHAR2(2000);
  collectionName VARCHAR2(2000);
  cCount number;
  htmlRep    VARCHAR2(1000);
  xmlRecFileId varchar2(200) := NULL;
  browserRep VARCHAR2(1000);
  isHTMLLoaded number := 0;
  htmlFileId varchar2(40);
  checksSqlFileId varchar2(40);
  patchchecksSqlFileId varchar2(40);
  temp varchar2(1000);
  temp1 number;
  docName rca13_DOCS.FILENAME%TYPE;
  colStatus varchar2(100) := NULL;
  failComment varchar2(1000);
  tsName varchar2(256);
  freeSpace number := 999;
  minRequiredFreeSpace number := 100; -- Size in MB
  filesCnt number :=0;
  collectionType varchar2(40);
  srBugNum varchar2(20);
   v_start PLS_INTEGER  := 1;
    v_buffer PLS_INTEGER := 32760;
     text VARCHAR2(32767);
     textLeft varchar2(4000);
BEGIN
  commit; -- This commit is for seeing just inserted zip file
  begin
    select filename,collection_id,sr_bug_num into docName,collectionId,srBugNum from rca13_docs where doc_id = docId;
    colName := substr(docName,instr(docName,'/',-1,1)+1);    
    colName := REGEXP_REPLACE(colName,'\.zip','',1,1,'i');    
    --dbms_output.put_line('cid='||collectionId);
    If collectionId is not null then
      --Now check whether collection is processes successfully or not. Proceed next if status is failed      
       select status,fail_comment into colStatus,failComment from rca13_collections where collection_id = collectionId;
       --dbms_output.put_line('stats='||colStatus);
       if nvl(colStatus,'z') != 'Failed' then
        return;
       end if;       
       --dbms_output.put_line('call delete fun');
       if colStatus = 'Failed' and failComment != 'NO_ENOUGH_SPACE' then
         return;
       end if;
       --If collection is failed bcz of space issue try to reprocess it.
       deleteCollection(docId,1); -- 1 ==> Delete every thing except collection zip
       log_text('REATTEMPT: Re-Attempting to process the collection',collectionId,docId);
    end if;
    --dbms_output.put_line('delete done');
    insert into rca13_collections(collection_id,status,collection_name,doc_id,sr_bug_num) values(sys_guid(),'Processing',colName,docId,srBugNum)
    return collection_id into collectionId;
    --dbms_output.put_line('cid='||collectionId);
    update rca13_docs set collection_id = collectionId where doc_id = docId;    
    commit;
    exception when no_data_found then
    log_text('NODATA: No collection found with docId='||docId||'...exiting','NO COLLECTION ID',docId);
    return;
  end;  
  --Expected file names:
  -- orachk_cetrain19_sid11203_052214_165708.zip ==> Full Run
  -- orachk_033015_151240.zip ==> Patch results
  --Add some validations on fileName to check whther it is valid collection or not
  if ( upper(docName) not like 'EXACHK_%.ZIP' and upper(docName) not like 'RACCHECK_%.ZIP' and upper(docName) not like 'ORACHK_%.ZIP' ) then
    log_text('INVALIDNAME: Collection name is not valid. It should start with orachk/exachk/raccheck...exiting',collectionId,docId);
    update_collection_status(collectionId,'Failed');
    return;
  end if;  
  
  --We are processing patch results now
  /*if ( instr(docName,'_',1,3) <= 0 ) then
    -- For now we are not processing files of type orachk_052014_064245.zip as it is patch related run and we don't know from which home it came from.
    log_text('We are not processing collections if it is like orachk_052014_064245.zip. It is patch related run and we do not know from which host it is.',collectionId,docId);
    update_collection_status(collectionId,'Failed');
    return;
  end if;  
  */
  
  -- Get collection type
    if upper(docName) like 'EXACHK_%.ZIP' then
      collectionType := 'exachk';
    elsif upper(docName) like 'ORACHK_%.ZIP' then
      collectionType := 'orachk';
    elsif upper(docName) like 'RACCHECK_%.ZIP' then
      collectionType := 'raccheck';
    else
      log_text('INVALIDNAME: Collection name is not valid. It should start with orachk/exachk/raccheck...exiting',collectionId,docId);
      update_collection_status(collectionId,'Failed');
      return;
    end if;
  
  -- Check whether there is enough space to process collection or not  
  begin
   select tablespace_name into tsName from user_tables where table_name = 'RCA13_DOCS';
   SELECT sum(bytes)/1048576 into freeSpace FROM user_free_space  where tablespace_name = tsName;
   exception when others then null;
  end;
  if freeSpace < minRequiredFreeSpace then     
    log_text('MEMORYCRUNCH: Does not have enough space in data base to process collection...exiting.',collectionId,docId);
    update_collection_status(collectionId,'Failed','NO_ENOUGH_SPACE');
    return;    
  end if;
  
  log_text('START: Started processing collection',collectionId,docId);
  SELECT filename,  file_blob  INTO colName, colBlob  FROM rca13_docs WHERE doc_id = docId;
  collectionName := substr(colName,instr(colName,'/',-1,1)+1);
  collectionName := REGEXP_REPLACE(collectionName,'\.zip','',1,1,'i');
  colName := REGEXP_REPLACE(collectionName,'\_collect','',1,1,'i');
  htmlRep            := colName||'.html';
  browserRep         := regexp_replace(htmlRep,'_','_browse_',1,1);
  
  --log_text('HTML file='||htmlRep||',b='||browserRep,collectionId,docId);  
  --UPDATE rca13_collections  SET status          = 'Processing'  WHERE collection_id = collectionId;
  files              := rca13_manage_zips.get_file_list(colBlob);
  log_text('FINISH: Finished getting list of files from Zip archive',collectionId,docId);
  
  --In First round process non HTML files
  log_text('START: Started parsing non HTML/XML files',collectionId,docId);
  FOR i IN files.first() .. files.last   LOOP
   begin
    temp := files(i);
    -- files returns directories also. Don't insert directories
    CONTINUE  WHEN SUBSTR(files(i),LENGTH(files(i))) = '/';
    --Now a days seeing some zip files inside zip .. ignore them for now
    continue when upper(files(i)) like '%.ZIP';
    fnShort := SUBSTR(files(i),instr(files(i),'/',-1,1)+1);
    -- As part of minimal collection processing. Process only selective files of collection.
    if fnShort = 'upload_'||collectionType||'_result.sql' OR fnShort = 'upload_'||collectionType||'_patch_result.sql'
       OR fnShort = 'check_env.out' OR fnShort = 'o_host_list.out' OR fnShort = 'o_ibswitches.out'
       OR fnShort = 'cells.out' OR fnShort =  collectionType||'_skipped_checks.log'
         OR fnShort = 'total_checks_summary.out' then
      -- Basic files  
      null;
    elsif fnShort like 'd_v_parameter_%.out' then
      --Name = value files -- not sure what to do with these files.
      null;
    else
      continue;
    end if;
    INSERT INTO RCA13_COLLECTION_FILES(COLLECTION_FILE_ID,COLLECTION_ID,FILE_NAME,SHORT_FILE_NAME)
    VALUES(sys_guid(),collectionId,files(i),fnShort) RETURN COLLECTION_FILE_ID    INTO cFileId;        
   
    fileBlob := rca13_manage_zips.get_file(colBlob,files(i));  
    fContent                     := rca13_manage_collections.blob_to_clob(fileBlob);
    fContent                     := trim(both chr(10) FROM fContent);
    lCounter                     := 1;
   
    if fnShort = 'upload_'||collectionType||'_result.sql' then       
        checksSqlFileId := cFileId;
    end if;
    if fnShort = 'upload_'||collectionType||'_patch_result.sql' then       
        patchchecksSqlFileId := cFileId;
    end if;
    
    WHILE instr(fContent,chr(10)) > 0
    LOOP
      lText := SUBSTR(fContent,1,instr(fContent,chr(10)) - 1);
      INSERT INTO RCA13_COLLECTION_FILE_DATA(COLLECTION_FILE_DATA_ID,COLLECTION_FILE_ID,LINE_TEXT,LINE_NUMBER)
      VALUES(sys_guid(),cFileId,lText,lCounter);
      fContent := SUBSTR(fContent,instr(fContent,chr(10)) + 1);
      lCounter := lCounter                                +1;
    END LOOP;
    --Hanlde file with one line / insert last line of file
    IF instr(fContent,chr(10)) = 0 AND fContent IS NOT NULL THEN
      INSERT INTO RCA13_COLLECTION_FILE_DATA(COLLECTION_FILE_DATA_ID,COLLECTION_FILE_ID,LINE_TEXT,LINE_NUMBER)
      VALUES(sys_guid(),cFileId,fContent,lCounter);
    END IF;
    COMMIT;    
   exception when others then    
     log_text('FAIL: Failed to process the file'||temp,collectionId,docId);
     if fnShort = 'upload_'||collectionType||'_result.sql' then       
        filesCnt := filesCnt + 1;
     end if;
     if fnShort = 'upload_'||collectionType||'_patch_result.sql' then       
        filesCnt := filesCnt + 1;
     end if;
   end;
  END LOOP;
  
  -- There is no point of going a head if .sql files fails OR if no .sql files
  if filesCnt = 2 OR ( ( checksSqlFileId is null OR filesCnt = 1 ) and ( patchchecksSqlFileId is null OR filesCnt = 1 ) ) then  
    log_text('FAIL: *.sql files ( audit results ) not found or failed to process .. Exiting',collectionId,docId);
    update_collection_status(collectionId,'Failed');
    return;
  end if;
  
  log_text('FINISH: Finished parsing non HTML/XML files',collectionId,docId);
  
  -- Now Go through some of the files and popup tables
  rca13_manage_collections.parseRCFiles(collectionId,docId);
  commit;
  -- INsert auditchecks
  if checksSqlFileId is not null then
   insertAuditChecks(checksSqlFileId,collectionId,docId);
  end if;
  -- Insert patch results
  if patchchecksSqlFileId is not null then
   insertAuditPatchChecks(patchchecksSqlFileId,collectionId,docId);
  end if;
  --log_text('Finished inserting data into Audit check result tables',collectionId,docId);
  
  -- Now process HTML/XML files
  log_text('START: Started parsing HTML/XML files',collectionId,docId);
  isHTMLLoaded := 0;
  FOR i IN files.first() .. files.last   LOOP
   begin
    temp := files(i);
    fnShort := SUBSTR(files(i),instr(files(i),'/',-1,1)+1);
    continue when nvl(fnShort,'z') != nvl(htmlRep,'zz') and nvl(fnShort,'z') != nvl(collectionType||'_recommendations.xml','zz') ;
    continue when nvl(fnShort,'z') = nvl(htmlRep,'zz') and isHTMLLoaded = 1;
    --We are here only if file is HTML files
    INSERT INTO RCA13_COLLECTION_FILES(COLLECTION_FILE_ID,COLLECTION_ID,FILE_NAME,SHORT_FILE_NAME)
    VALUES(sys_guid(),collectionId,files(i),fnShort) RETURN COLLECTION_FILE_ID    INTO cFileId;        
    
    fileBlob := rca13_manage_zips.get_file(colBlob,files(i));  
    IF ( files(i) LIKE '%'||htmlRep and isHTMLLoaded = 0 ) THEN
      INSERT INTO RCA13_docs (doc_id,COLLECTION_ID,FILENAME, FILE_BLOB,attr1) VALUES
        ( rca13_file_seq.nextval,collectionId,htmlRep,fileBlob,'HTML_REP_FILE');
      COMMIT;
      isHTMLLoaded := 1;
      htmlFileId := cFileId;
      log_text('INSERT: Inserted HTML Report into rca13_docs',collectionId,docId);
    END IF;
    if ( files(i) LIKE '%'||collectionType||'_recommendations.xml' ) then
      xmlRecFileId := cFileId;
    end if;
    fContent                     := rca13_manage_collections.blob_to_clob(fileBlob);
    fContent                     := trim(both chr(10) FROM fContent);
    lCounter                     := 1;
   --  fileBlob := null;    
    log_text('STARTPRO: Started Processing '||files(i)||' file',collectionId,docId);
   /* WHILE instr(fContent,chr(10)) > 0
    LOOP
      lText := substr(SUBSTR(fContent,1,instr(fContent,chr(10)) - 1),1,4000);   
      INSERT INTO RCA13_COLLECTION_FILE_DATA
      (COLLECTION_FILE_DATA_ID,COLLECTION_FILE_ID,LINE_TEXT,LINE_NUMBER)
      VALUES(sys_guid(),cFileId,lText,lCounter);
      fContent := SUBSTR(fContent,instr(fContent,chr(10)) + 1);
      lCounter := lCounter+1;         
    END LOOP;
    --Handle file with one line / insert last line of file
    IF instr(fContent,chr(10)) = 0 AND fContent IS NOT NULL THEN
      INSERT INTO RCA13_COLLECTION_FILE_DATA
      (COLLECTION_FILE_DATA_ID,COLLECTION_FILE_ID,LINE_TEXT,LINE_NUMBER)
      VALUES(sys_guid(),cFileId,fContent,lCounter);
    END IF;
    COMMIT;  
   log_text('FINISHPRO: Finished processing '||files(i)||' file',collectionId,docId);
   exception
   when no_data_found then
   log_text('FAIL: Failed to process the file SQLCODE '||SQLCODE||'lCounter'||lCounter,collectionId,docId);
   log_text('FAIL: Failed to process the file SQLERRM '||SUBSTR(SQLERRM,1,64),collectionId,docId);   
   when others then
   log_text('FAIL: Failed to process the file SQLCODE '||SQLCODE||'lCounter'||lCounter,collectionId,docId);
   log_text('FAIL: Failed to process the file SQLERRM '||SUBSTR(SQLERRM,1,64),collectionId,docId);
   log_text('FAIL: Failed to process the file '||temp,collectionId,docId);
      end;
  END LOOP;*/
    v_start := 1;
for i in 1..ceil(DBMS_LOB.GETLENGTH(fContent)/v_buffer) loop
      text := null;
      dbms_lob.read(fContent,v_buffer,v_start,text);
      WHILE instr(text,chr(10)) > 0 LOOP
        lText := substr(SUBSTR(text,1,instr(text,chr(10)) - 1),1,4000);     
        if textLeft is not null then
          lText := textLeft || lText;
          textLeft := null;
        end if;
        INSERT INTO RCA13_COLLECTION_FILE_DATA(COLLECTION_FILE_DATA_ID,COLLECTION_FILE_ID,LINE_TEXT,LINE_NUMBER)
        VALUES(sys_guid(),cFileId,lText,lCounter);
        text := SUBSTR(text,instr(text,chr(10)) + 1);
        lCounter := lCounter + 1;          
      END LOOP;
      if text is not null then
        textLeft := text;
      end if;
      v_start := v_start + v_buffer;
    end loop;
      --Handle insert last line of file
    IF instr(fContent,chr(10)) = 0 AND fContent IS NOT NULL THEN
      INSERT INTO RCA13_COLLECTION_FILE_DATA
      (COLLECTION_FILE_DATA_ID,COLLECTION_FILE_ID,LINE_TEXT,LINE_NUMBER)
      VALUES(sys_guid(),cFileId,fContent,lCounter);
    END IF;
    COMMIT;  
    log_text('FINISHPRO: Finished processing '||files(i)||' file',collectionId,docId);
   exception when others then
    log_text('FAIL: Failed to process the file SQLCODE '||SQLCODE||'lCounter'||lCounter,collectionId,docId);
   log_text('FAIL: Failed to process the file SQLCODE '||SQLCODE,collectionId,docId);
   log_text('FAIL: Failed to process the file SQLERRM '||SUBSTR(SQLERRM,1,64),collectionId,docId);
   log_text('FAIL: Failed to process the file '||temp,collectionId,docId);
end;
  END LOOP;
       
  -- Now go through HTML report file and get checks recommendation data
  if xmlRecFileId is not null OR htmlFileId is not null then
   log_text('START: Started updating checks rationale Information',collectionId,docId);
   if xmlRecFileId is not null then
    getChecksInfo(xmlRecFileId,'XML');
   else
    getChecksInfo(htmlFileId,'HTML');
   end if;
   log_text('FINISH: Finished updating checks rationale Information',collectionId,docId);
  end if;
  
  --Process parameter files
  RCA13_MANAGE_PARAMS.processParamFiles(collectionId);
  commit;
  --Update the status to completed
  UPDATE rca13_collections  SET status = 'Processed'  WHERE collection_id = collectionId;
  commit;
  log_text('FINISH: Finished processing collection',collectionId,docId);    
  exception when others then
  UPDATE rca13_collections  SET status = 'Failed'  WHERE collection_id = collectionId;
  log_text('FAIL: Collection Failed to process with error '||DBMS_UTILITY.FORMAT_ERROR_STACK,collectionId,docId);
  commit;
END;
--------------------------------------------------------------------------------
procedure parseHostSwitchSSFile(shortFileName varchar2 , cFileId varchar2) is
cursor cur is select line_text from RCA13_COLLECTION_FILE_DATA  where COLLECTION_FILE_ID = cFileId;
lineText varchar2(256);
collectionId varchar2(40);
sourceName varchar2(40);
cellName varchar2(128);
begin
select collection_id into collectionId from RCA13_COLLECTION_FILES where COLLECTION_FILE_ID = cFileId;
select system_name into sourceName from rca13_collections  where collection_id = collectionId;
 
insert into rca13_files(file_id,collection_id,source_name,source_type,COLLECTION_FILE_ID)
  values (sys_guid(),collectionId,sourceName,decode(shortFileName,'o_host_list.out','HOSTS','o_ibswitches.out','SWITCH','cells.out','CELL','DB'),cFileId);
 
if shortFileName like 'o_host_list.out' then  
 for line in cur loop
 insert into rca13_hosts(host_id,host_name,collection_id) values
        (sys_guid(),line.line_text,collectionId);
 end loop;
elsif shortFileName like 'o_ibswitches.out' then
 for line in cur loop
 insert into rca13_ibs_ss(ibs_ss_id,name,collection_id,type) values
        (sys_guid(),line.line_text,collectionId,'S');
 end loop;
elsif shortFileName like 'cells.out' then
 for line in cur loop
  continue when ( instr(line.line_text,'=',1,1) = 0 );
  cellName := trim(substr(line.line_text,instr(line.line_text,'=',1,1)+1));
  --if cell name is not available in DNS store IP address
  if cellName is null then
   cellName := trim(substr(line.line_text,1,instr(line.line_text,'=',1,1)-1));    
  end if;
   insert into rca13_ibs_ss(ibs_ss_id,name,collection_id,type) values (sys_guid(),cellName,collectionId,'C');
 end loop;
end if;
commit;
end;
--------------------------------------------------------------------------------
procedure parseOsFiles(shortFileName varchar2, cFileId varchar2) is
flag number := 0;
begin
  if (shortFileName like '%inventory%' or shortFileName like '%comps%')  then
    --pgFromDarwinInventoryOrComps (shortFileName,cFileId);
    null;
  elsif shortFileName like 'o_host_list.out' or shortFileName like 'o_ibswitches.out' or shortFileName like 'cells.out' then
    parseHostSwitchSSFile(shortFileName,cFileId);
  elsif shortFileName like 'o_package%' then  
    --parseOsPackageFiles(shortFileName,cFileId);
    null;
  elsif shortFileName like 'o_actual_%' or shortFileName like 'c_actual.out' then
    --parseOsActualFiles(shortFileName,cFileId);
    null;
  else
   --parseOtherOsFiles(shortFileName,cFileId);
   null;
  end if;
end;
--------------------------------------------------------------------------------
function getVersionFromDbName(homePath varchar2,cFileId varchar2) return varchar2 is
cursor cur is select line_text from rca13_COLLECTION_FILE_DATA where COLLECTION_FILE_ID = cFileId and trim(line_text) like 'DB_NAME%';
nameField varchar2(512);
valueField varchar2(256);
begin
 -- this func return null if there is no DB_NAME entry in check_env.out file for the corresponding home.
 -- If user selects no databases then we will not see any DB_NAME entry in check_env.out file.
 for line in cur loop  
   nameField  := upper(trim(substr(line.line_text,1,(instr(line.line_text , '=' ,1,1)-1))));
   valueField := trim(substr(line.line_text,(instr(line.line_text , '=' ,1,1)+1)));
   continue when ( instr(line.line_text,'=',1,1) = 0 or nameField not like 'DB_NAME');
   if substr(valueField,instr(valueField,'|',-1,1)+1) = homePath then
    return substr(valueField,instr(valueField,'|',1,1)+1,instr(valueField,'|',1,2)-instr(valueField,'|',1,1)-1);
  end if;
 end loop;
 return null;
end;
--------------------------------------------------------------------------------
procedure combineHomes(collectionId varchar2) is
cursor cur is select * from rca13_homes where collection_id=collectionId and type not like 'ASM';
asmVersion varchar2(40) := NULL;
asmHomePath varchar2(128) := NULL;
asmHomeId varchar2(40):= NULL;
begin
-- crs version >= asm version >= rdbms version
-- for GI asm and crs share the same home
if ISASMINSTALLED = 1 then
 begin
    select home_id,home_path,version into asmHomeId,asmHomePath,asmVersion from rca13_homes
    where collection_id=collectionId and type like 'ASM';
 
    for rec in cur loop
      if rec.type like 'CRS' and ( asmVersion >= '11.2' or rec.version >= '11.2' or asmHomePath like rec.home_path ) then
        update rca13_homes set version=decode(rec.version,null,asmVersion,rec.version),type='GI',
       home_path=decode(rec.home_path,null,asmHomePath,rec.home_path) where home_id=rec.home_id;
        delete from rca13_homes where home_id=asmHomeId;
      end if;
      if rec.type like 'RDBMS' and asmHomePath like rec.home_path then
        update rca13_homes set version=decode(rec.version,null,asmVersion,rec.version),type='ASM & RDBMS' where home_id=rec.home_id;
        delete from rca13_homes where home_id=asmHomeId;
      end if;
    end loop;
    commit;
  exception when no_data_found then
   --Don't worry about it, there must not have been a separate ASM home, and nothing to combine
   --and nothing to update and nothing to delete
    null;
  end;
end if;
end;
--------------------------------------------------------------------------------
procedure parseEnvFile(shortFileName varchar2,cFileId varchar2) is
cursor cur is select line_text,line_number from rca13_COLLECTION_FILE_DATA  
 where COLLECTION_FILE_ID = cFileId order by line_number ASC;
nameField varchar2(512);
valueField varchar2(256);
collectionDate date;
dbName varchar2(40);
dbVersion varchar2(30);
rdbmsVersion varchar2(50);
rdbmsVersion1 varchar2(50);
asmVersion varchar2(50);
crsVersion varchar2(50);
osPlatform varchar2(50);
osDistribution varchar2(30);
osKernel rca13_collections.os_kernel%TYPE;
osVersion varchar2(30);
systemName varchar2(128);
collectionType varchar2(30);
collectionSource varchar2(30);
fileName varchar2(128);
fileType varchar2(100);
sourceName varchar2(40);
sourceType varchar2(40);
collectionId varchar2(40);
fileId varchar2(40);
instanceName varchar2(128);
instanceType varchar2(40);
counter number;
lineNumber number;
needsRunning varchar2(32);
collectionName varchar2(512);
oracleHomeid varchar2(40);
c1 number;
dbId varchar2(40);
version1 varchar2(48);
homeId1 varchar2(40);
dbId1 varchar2(40);
c2 number;
tempVar varchar2(40);
exadataVersion varchar2(40);
exadataRack varchar2(20);
count1 number;
c3 number;
hostId1 varchar2(40);
inFlag number;
hName varchar2(200);
grpStr varchar2(100);
customerId varchar2(200);
toolVersion varchar2(100);
curUser varchar2(100);
skippedChecksCnt number := 0;
isExalogic number := 0;
profs varchar2(2000);
begin
  select collection_id into collectionId from rca13_COLLECTION_FILES where collection_file_id=cFileId;
  if shortFileName not like 'check_env.out' then
   return;
  end if;
    --Stage1: Get some Info and fill rca13_homes
    for line in cur loop
     continue when ( instr(line.line_text,'=',1,1) = 0 );
     nameField  := upper(trim(substr(line.line_text,1,(instr(line.line_text , '=' ,1,1)-1))));
     valueField := trim(substr(line.line_text,(instr(line.line_text , '=' ,1,1)+1)));
     if nameField like 'LOCALNODE' then
      LOCAL_NODE := valueField;     
     elsif nameField like 'SWITCH' and valueField like '-u' then
      IS_UPGRADE_MODE := 1;
     elsif nameField like 'TARGET_VERSION' and valueField is not null then
      TARGET_VERSION := substr(valueField,1,2)||'.';
      for i in 3 .. length(valueField) loop
       TARGET_VERSION := TARGET_VERSION || substr(valueField,i,1)||'.';
      end loop;
      TARGET_VERSION := rtrim(TARGET_VERSION,'.');
     elsif nameField like 'RDBMS_ORACLE_HOME'  then
      if valueField is null or substr(valueField,1,instr(valueField,'|',1,1)-1) is null then                 
        continue;
      end if;
      rdbmsVersion := substr(valueField,instr(valueField,'|',1,1)+1,instr(valueField,'|',1,2)-1-instr(valueField,'|',1,1));
      if rdbmsVersion is null then
       rdbmsVersion := getVersionFromDbName(rtrim(substr(valueField,1,instr(valueField,'|',1,1)-1),'/'),cFileId);
       continue when (rdbmsVersion is null);
      end if;
      rdbmsVersion1 := substr(rdbmsVersion,1,2)||'.';
      for i in 3 .. length(rdbmsVersion) loop
       rdbmsVersion1 := rdbmsVersion1 || substr(rdbmsVersion,i,1)||'.';
      end loop;
      rdbmsVersion1 := rtrim(rdbmsVersion1,'.');
      -- Remove duplicate home paths...
      select count(1) into count1 from rca13_homes where collection_id=collectionId and type like 'RDBMS' and
       home_path = rtrim(substr(valueField,1,instr(valueField,'|',1,1)-1),'/');
      if count1 > 0 then
       continue;
      else
      insert into rca13_homes(home_id,collection_id,home_path,version,user_name,type)
       values(sys_guid(),collectionId,rtrim(substr(valueField,1,instr(valueField,'|',1,1)-1),'/'),rdbmsVersion1,
       nvl(substr(valueField,instr(valueField,'|',1,2)+1),'USER_NAME'),'RDBMS');
      end if;
      commit;     
     end if;
    end loop;
    
    -- Stage2:     
    for line in cur loop
     continue when ( instr(line.line_text,'=',1,1) = 0 );
     nameField  := trim(substr(line.line_text,1,(instr(line.line_text , '=' ,1,1)-1)));
     valueField := trim(substr(line.line_text,(instr(line.line_text , '=' ,1,1)+1)));
     
     if nameField like 'FILE_ID' and instr(valueField,' ',1,1) != 0 then
      valueField := substr(valueField,1,instr(valueField,' ',1,1)-1);
     end if;
     if nameField like 'DB_NAME' and instr(line.line_text , '|' ,1,1) != 0 then
      begin
        select home_id into oracleHomeId from rca13_homes
         where collection_id = collectionId and home_path = rtrim(substr(valueField,instr(valueField,'|',1,2)+1),'/');
         exception when no_data_found then
         -- Continue when entries are like DB_NAME = VPT3DB15||
         continue;
      end;   
      insert into rca13_databases(database_id,db_name,home_id,physical_standby,logical_standby,collection_id)
       values(sys_guid(),substr(valueField,1,instr(valueField,'|',1,1)-1),oracleHomeId,NULL,NULL,collectionId);
     else
        case          
         when nameField like 'FILE_ID' then kitId := valueField;
         when nameField like 'FILE_SIG' then customerId := valueField;
         when nameField like 'COLLECTION DATE' then
              begin
              collectionDate := to_date(valueField,'DD-MM-YYYY HH24:MI:SS');
              exception when others then collectionDate := null;
              end;
         when nameField like 'DB_NAME' then dbName := valueField;
         when nameField like 'DB_VERSION' then dbVersion := valueField;
         when nameField like 'ASM_VERSION' then asmVersion := valueField;
         when nameField like 'ASM_HOME' then ASMHOME := valueField;
         when nameField like 'CRS_VERSION' then crsVersion := valueField;
         when nameField like 'DB_PLATFORM' then osPlatform := valueField;
         when nameField like 'OS_DISTRO' then osDistribution := valueField;
         when nameField like 'OS_VERSION' then osVersion := valueField;
         when nameField like 'OS_KERNEL' then osKernel := valueField;
         when nameField like 'CLUSTER_NAME' then systemName := valueField;
         when upper(nameField) like upper(LOCAL_NODE)||'.CRS_ACTIVE_VERSION' then crsVersion := valueField;
         when upper(nameField) like upper(LOCAL_NODE)||'.%ASM%.VERSION' then asmVersion := valueField;
         when upper(nameField) like upper(LOCAL_NODE)||'.CRS_INSTALLED' then ISCRSINSTALLED := valueField;
         when upper(nameField) like upper(LOCAL_NODE)||'.ASM_INSTALLED' then ISASMINSTALLED := valueField;
         when upper(nameField) like '.%ASM%.VERSION' then asmVersion := nvl(valueField,asmVersion);
         when upper(nameField) = 'EXADATA_COMPUTE' then isExadata := nvl(valueField,0);
         when upper(nameField) = 'EXADATA_VERSION' then exadataVersion := valueField;
         when upper(nameField) = 'EXADATA_RACK'  then exadataRack := valueField;
         when upper(nameField) = 'GRP_STR'  then grpStr := valueField;
         when upper(nameField) = 'EXACHK_VERSION' OR upper(nameField) = 'ORACHK_VERSION'  then toolVersion := valueField;
         when upper(nameField) = 'CURRENT_USER'  then curUser := valueField;
         when upper(nameField) = 'IS_EXALOGIC_MACHINE'  then isExalogic := valueField;
         when upper(nameField) = 'PROFILE_NAMES'  then profs := replace(valueField,',',', ');
         else null;
         --dbms_output.put_line('do nothing');         
        end case;        
     end if;   
    end loop;
    -- get db instances    
    if osPlatform like 'AIX6 ( 64-BIT)' then
     osPlatform := 'AIX6 (64-BIT)';
    end if;
    if osPlatform like 'AIX5 ( 64-BIT)' then
     osPlatform := 'AIX5 (64-BIT)';
    end if;
    -- If platform name is 'SOLARIS  (SPARC 64-BIT)', then Replace it with 'SOLARIS (SPARC 64-BIT)'
    if osPlatform like 'SOLARIS  (SPARC 64-BIT)' or osPlatform like 'SOLARIS (SPARC64-BIT)' then
      osPlatform := 'SOLARIS (SPARC 64-BIT)';
    end if;
    if osPlatform = 'HPUX' and grpStr like 'HPUXItanium%' then
      osPlatform := 'HP-UX ITANIUM';
    end if;
    
    for line in cur loop    
     continue when ( instr(line.line_text,'=',1,1) = 0 );
     nameField  := upper(trim(substr(line.line_text,1,(instr(line.line_text , '=' ,1,1)-1))));
     valueField := trim(substr(line.line_text,(instr(line.line_text , '=' ,1,1)+1)));     
     -- Following works for both SDB and MDB, if we miss crs_home from SDB, we will add it later
     -- And we combine asm_home with other home( if applicable) later
     -- We are populating rca13_homes table in both the SDB and MDB cases
     if nameField like 'DB_NAME' and instr(valueField,'|',1,1) = 0 then
      insert into rca13_homes(home_id,collection_id,home_path,version,user_name,type,home_path_short)
       values(sys_guid(),collectionId,'RDBMS Home',dbVersion,'SITE.USER','RDBMS','RDBMS Home') return home_id into homeId1;
      insert into rca13_databases(database_id,db_name,home_id,physical_standby,logical_standby,collection_id)
       values(sys_guid(),valueField,homeId1,NULL,NULL,collectionId) return database_id into dbId1;
     elsif nameField like 'CRS_HOME' and ISCRSINSTALLED = 1 then
      insert into rca13_homes(home_id,collection_id,home_path,version,type)
       values(sys_guid(),collectionId,valueField,crsVersion,'CRS');
     elsif nameField like 'ASM_HOME' and ISASMINSTALLED = 1 then
      insert into rca13_homes(home_id,collection_id,home_path,version,user_name,type,home_path_short)
       values(sys_guid(),collectionId,decode(valueField,NULL,'ASM Home',valueField),asmVersion,'SITE.USER','ASM',decode(valueField,NULL,'ASM Home',NULL));
     end if;
    end loop;
-- get db instances and ASM instances     
    for line in cur loop    
     continue when ( instr(line.line_text,'=',1,1) = 0 );
     nameField  := upper(trim(substr(line.line_text,1,(instr(line.line_text , '=' ,1,1)-1))));
     valueField := trim(substr(line.line_text,(instr(line.line_text , '=' ,1,1)+1)));
     -- DB instances fetch
     if nameField like '%.INSTANCE_NAME' and valueField is not null then      
      if instr(nameField,'.',1,2 )!=0 then --works for MOH collections       
       begin
       select distinct database_id into dbId from rca13_databases where collection_id = collectionId
        and upper(db_name) like substr(nameField,instr(nameField,'.',1,1)+1,instr(nameField,'.',1,2)-instr(nameField,'.',1,1)-1);
       exception when NO_DATA_FOUND then continue; -- this exception is to handle if we don't have
       end;
       insert into rca13_db_instances(db_instance_id,database_id,instance_name,node_name,collection_id)
        values(sys_guid(),dbId,valueField,substr(nameField,1,instr(nameField,'.',1,1)-1),collectionId);                
      elsif dbName is not null then --works for SOH collections
       insert into rca13_db_instances(db_instance_id,database_id,instance_name,node_name,collection_id)
        values(sys_guid(),dbId1,valueField,substr(nameField,1,instr(nameField,'.',1,1)-1),collectionId);
      end if;
     end if;  
     -- ASM instances fetch
     if nameField like '%.ASM_INSTANCE' and valueField is not null then      
       insert into rca13_asm_instances(asm_instance_id,instance_name,node_name,collection_id)
        values(sys_guid(),valueField,substr(nameField,1,instr(nameField,'.',1,1)-1),collectionId);                
     end if;     
    end loop;
    commit;            
    --If collection date is null, get it from collection file name or initialize to sysdate
    if collectionDate is null then
     select filename into collectionName from rca13_collections where collection_id=collectionId;
     collectionName := substr(collectionName,instr(collectionName,'/',-1,1)+1,
                       instr(collectionName,'.',-1,1)-instr(collectionName,'/',-1,1)-1);
     collectionName := substr(collectionName,instr(collectionName,'_',1,2)+1);
     collectionName := substr(collectionName,1,2)||'-'||substr(collectionName,3,2)||'-'||substr(collectionName,5,2)||' '||
                       substr(collectionName,8,2)||':'||substr(collectionName,10,2)||':'||substr(collectionName,12,2);
     begin                       
      collectionDate:= to_date(collectionName,'DD-MON-YYYY HH24:MI:SS');
      exception when others then
      collectionDate := to_date(sysdate,'DD-MON-YYYY HH24:MI:SS');   
     end;
    end if;
        
    -- if osPlatform is null or crsVersion is null then
    if crsVersion is null and ISCRSINSTALLED = 1 and asmVersion is not null and asmVersion >= '11.2' then
     crsVersion := asmVersion;
    end if;
    if osPlatform is null or (crsVersion is null and ISCRSINSTALLED = 1) then    
      --raise_application_error(-20001,'Values of DB_PLATFORM(os platform) and CRS_VERSION should not be null',true);
      null;
    end if;
    -- Get skipped checks count
    begin
     select count(1) into skippedChecksCnt from rca13_collection_file_data a,rca13_collection_files b
     where b.collection_id = collectionId and b.short_file_name like '%_skipped_checks.log'
     and b.collection_file_id = a.collection_file_id;
     exception when others then null;
    end;
    update rca13_collections set collection_date = collectionDate,
     os_platform = osPlatform,os_dist = osDistribution,os_kernel = osKernel,
     os_version = osVersion,system_name = systemName,asm_version = asmVersion,crs_version = crsVersion,
     is_exadata = isExadata,exadata_version = exadataVersion,exadata_rack = exadataRack,kit_id = kitId,
     current_user = curUser,tool_version = toolVersion,skipped_checks = skippedChecksCnt,
     is_exalogic = isExalogic,profiles = profs where collection_id = collectionId;
    commit;
-- update rca13_homes table for type= crs,asm and rdbms
   update rca13_homes set version = asmVersion where collection_id = collectionId and type like 'ASM';
   select count(*) into c2 from rca13_homes where collection_id= collectionId and type like 'CRS';
   if c2 = 1 then
    update rca13_homes set version = crsVersion where collection_id = collectionId and type like 'CRS';
   else
    insert into rca13_homes(home_id,collection_id,home_path,version,user_name,type,home_path_short)
       values(sys_guid(),collectionId,'CRS Home',crsVersion,'SITE.USER','CRS','CRS Home');
   end if;
   
   combineHomes(collectionId);   
   
   select system_name into sourceName from rca13_collections where collection_id=collectionId;
  insert into rca13_files (file_id,collection_id,source_name,source_type,collection_file_id)
        values (sys_guid(),collectionId,sourceName,'DB',cFileId);
-- this is to get standby
   for line in cur loop
    continue when ( instr(line.line_text,'=',1,1) = 0 );
    nameField  := trim(substr(line.line_text,1,(instr(line.line_text , '=' ,1,1)-1)));
    valueField := trim(substr(line.line_text,(instr(line.line_text , '=' ,1,1)+1)));
    case
     when nameField like '%.PHYSICAL_STANDBY' then
      update rca13_databases set physical_standby = valueField
       where collection_id = collectionId and upper(db_name) = upper(substr(nameField,1,instr(nameField,'.',1,1)-1));
     when nameField like '%.LOGICAL_STANDBY'  then
      update rca13_databases set logical_standby = valueField
       where collection_id = collectionId and upper(db_name) = upper(substr(nameField,1,instr(nameField,'.',1,1)-1));
     when nameField like '%.DATABASE_ROLE' then
      update rca13_databases set DATABASE_ROLE = valueField
       where collection_id = collectionId and upper(db_name) = upper(substr(nameField,1,instr(nameField,'.',1,1)-1));       
     else null;
    end case;
   end loop;          
  commit;
end;
--------------------------------------------------------------------------------
procedure parseFile(cFileId varchar2 ) is
shortFileName rca13_COLLECTION_FILES.short_file_name%TYPE;
collectionId varchar2(40);
begin
 if cFileId is null then
  return;
 end if;
 select collection_id,short_file_name into collectionId,shortFileName from rca13_COLLECTION_FILES
 where COLLECTION_FILE_ID = cFileId;
  if ( shortFileName like 'o_%.out' or shortFileName like 'cells.out' or shortFileName like 'c_actual.out') and shortFileName not like '%_result%'  
       and shortFileName not like '%patchlist%'then
     -- parsing o_host_list.out,o_ibswithces.out and cells.out files in praseOsFiles() function.
     parseOsFiles(shortFileName, cFileId);
 elsif shortFileName like '%check_env.out' then
     parseEnvFile(shortFileName,cFileId);    
 elsif shortFileName like 'd_%.out' or shortFileName like 'a_%.out' then
     --parseDbAsmFiles(shortFileName,cFileId);
     null;
 elsif shortFileName like 's_%.out' then      
     --parseSwitchFiles(shortFileName,cFileId);     
     null;
 elsif shortFileName like '%audit_result%' then
     --parseResultFiles(shortFileName,cFileId,collectionId);
     null;
 end if;
end;
--------------------------------------------------------------------------------
PROCEDURE parseRCFiles(collectionId VARCHAR2,docId number) IS
  CURSOR cur IS SELECT COLLECTION_FILE_ID, SHORT_FILE_NAME FROM rca13_COLLECTION_FILES
    WHERE COLLECTION_ID = collectionId and ( short_file_name like '%_skipped_checks.log' OR
    short_file_name in ('check_env.out','o_host_list.out','o_ibswitches.out','cells.out') )
    ORDER BY short_file_name;
  shortFileName rca13_COLLECTION_FILES.short_file_name%TYPE;
  dCheckId       VARCHAR2(40);
  hostsFileId    VARCHAR2(40);
  noOfFiles      NUMBER := 0;
  currentFile    VARCHAR2(128);
  switchesFileId VARCHAR2(40);
  cellsFileId    VARCHAR2(40);
  c              NUMBER;
  cpFileId       VARCHAR2(40); --This is to store o_misc_clusterwide_checks.out file Id
  r              NUMBER;
  temp           VARCHAR2(40);
  colName        VARCHAR2(2000);
  INVALID_COLLECTION exception;
  emesg varchar2(2000);
BEGIN
  log_text('START: Started Processing files other than HTML file',collectionId,docId);
  SELECT COUNT(1)   INTO noOfFiles  FROM rca13_COLLECTION_FILES
  WHERE COLLECTION_ID = collectionId   AND ( short_file_name LIKE 'check_env.out'
  OR short_file_name LIKE 'o_host_list.out');
  
  IF noOfFiles = 0 OR noOfFiles = 1 THEN
    RAISE INVALID_COLLECTION;
  END IF;
  
  SELECT filename  INTO colName  FROM rca13_docs  WHERE doc_id = docId;
  SELECT COUNT(1)   INTO noOfFiles
  FROM rca13_COLLECTION_FILES
  WHERE COLLECTION_ID = collectionId
  AND ( short_file_name LIKE 'a_%.out'
  OR short_file_name LIKE 'd_%.out'
  OR short_file_name LIKE 'o_%.out'
  OR short_file_name LIKE 'check_env.out'
  OR short_file_name LIKE 'c_actual.out' );
  SELECT mod(noOfFiles,10) INTO r FROM dual;
  IF r = 0 THEN
    noOfFiles := noOfFiles + 1;
  END IF;
  c := 0;
  FOR rec IN cur LOOP
    --prevent processing duplicate file names and Get file Id's that we need to run
    -- in first and second stages
    shortFileName := rec.short_file_name;
    IF shortFileName != NVL(currentFile,'NONE') THEN
      currentFile    := shortFileName;
      IF shortFileName LIKE 'check_env.out' THEN        
        parseFile(rec.COLLECTION_FILE_ID);
        RACCHECK_ENV_FILE_ID := rec.COLLECTION_FILE_ID;
      elsif shortFileName LIKE 'o_host_list.out' THEN
        hostsFileId := rec.COLLECTION_FILE_ID;
      elsif shortFileName LIKE 'o_ibswitches.out' THEN
        switchesFileId := rec.COLLECTION_FILE_ID;
      elsif shortFileName LIKE 'cells.out' THEN
        cellsFileId := rec.COLLECTION_FILE_ID;
      elsif shortFileName LIKE 'o_misc_clusterwide_checks.out' THEN
        cpFileId := rec.COLLECTION_FILE_ID;
      END IF;
    END IF;
  END LOOP;  
  parseFile(hostsFileId);
  IF NVL(switchesFileId,'z') != 'z' THEN
    parseFile(switchesFileId);
  END IF;
  IF NVL(cellsFileId,'z') != 'z' THEN
    parseFile(cellsFileId);
  END IF;
  currentFile := NULL;
  FOR rec IN cur  LOOP
    shortFileName := rec.short_file_name;
    IF shortFileName != NVL(currentFile,'NONE') THEN
      currentFile    := shortFileName;
      IF rec.COLLECTION_FILE_ID != NVL(RACCHECK_ENV_FILE_ID,'z') AND rec.collection_file_id != NVL(hostsFileId,'z')
         AND rec.collection_file_id != NVL(cpFileId,'z') AND rec.collection_file_id != NVL(switchesFileId,'z')
         AND rec.collection_file_id != NVL(cellsFileId,'z') THEN        
             --parseFile(rec.COLLECTION_FILE_ID);
             NULL;
      END IF;
    END IF;
  END LOOP;
  COMMIT;
  log_text('FINISH: Finished processing files other than HTML file',collectionId,docId);
EXCEPTION
 WHEN INVALID_COLLECTION THEN
   log_text('NODATA: Collection does not have raccheck_env.out/check_env.out file ... exiting',collectionId);
 WHEN OTHERS THEN
   emesg := SQLERRM;
   log_text('FAIL: Error Occured:'||emesg,collectionId);
END;
--------------------------------------------------------------------------------
FUNCTION blob_to_clob
  (
    blob_in IN BLOB
  )
  RETURN CLOB
AS
  v_clob CLOB;
  v_varchar VARCHAR2(32767);
  v_start PLS_INTEGER  := 1;
  v_buffer PLS_INTEGER := 32767;
BEGIN
  IF ( blob_in IS NULL ) THEN
    RETURN NULL;
  END IF;
  IF ( LENGTH(blob_in)=0 ) THEN
    RETURN empty_clob();
  END IF;
  DBMS_LOB.CREATETEMPORARY(v_clob, TRUE);
  FOR i IN 1..CEIL
  (
    DBMS_LOB.GETLENGTH(blob_in) / v_buffer)
  LOOP
    v_varchar := UTL_RAW.CAST_TO_VARCHAR2(DBMS_LOB.SUBSTR(blob_in, v_buffer, v_start));
    DBMS_LOB.WRITEAPPEND(v_clob, LENGTH(v_varchar), v_varchar);
    v_start := v_start + v_buffer;
  END LOOP;
  RETURN v_clob;
END;
--------------------------------------------------------------------------------
FUNCTION blob2clob
  (
    blobData BLOB
  )
  RETURN CLOB
IS
  clobData CLOB;
  temp CLOB;
  LEN NUMBER;
  n   NUMBER;
BEGIN
  IF ( blobData IS NULL ) THEN
    RETURN NULL;
  END IF;
  IF ( LENGTH(blobData)=0 ) THEN
    RETURN empty_clob();
  END IF;
  dbms_lob.createtemporary(clobData,true);
  n               :=1;
  WHILE ( n+32767 <= LENGTH(blobData) )
  LOOP
    temp := utl_raw.cast_to_varchar2(dbms_lob.substr(blobData,32767,n));
    LEN  := dbms_lob.GETLENGTH(temp);
    dbms_lob.writeappend(clobData,LEN,temp); -- some thing is wrong that is why usng len variable instead of 32767
    n:=n+32767;
  END LOOP;
  dbms_lob.writeappend(clobData,LENGTH(blobData)-n+1,utl_raw.cast_to_varchar2(dbms_lob.substr(blobData,LENGTH(blobData)-n+1,n)));
  RETURN clobData;
END;
--------------------------------------------------------------------------------
procedure deleteCollection ( docId number,keep_zip number default 0) is
collectionId varchar2(40);
colDate timestamp;
colName varchar2(256);
temp varchar2(40);
begin
 --Delete based on collection zip doc id
 --Get collectionId from rca13_docs table
 select collection_id into collectionId from rca13_docs where doc_id = docId;
 --dbms_output.put_line('in delete fun:cid='||collectionId);
 if collectionId is null then
  --If process is failed before updating collection id in docs table get collectionId from collections table
  select collection_id into collectionId from rca13_collections where doc_id = docId and rownum = 1;
 end if;
 --dbms_output.put_line('in delete fun:cid2='||collectionId);
 if collectionId is null then
 --dbms_output.put_line('in delete fun: in if');
  --collection is not processed so just delete doc and we can't do any thing about the data inserted in result tables
  delete from rca13_docs where doc_id = docId;
  return;
 else --Delete whole data
 --dbms_output.put_line('in delete fun: in else');
  --Get collection date and collection name
  select collection_date,collection_name into colDate,colName from rca13_COLLECTIONS
  where collection_id = collectionId;
  if keep_zip = 1 then
    delete from rca13_docs where collection_id =  collectionId and attr1 != 'ZIP_FILE';
    update rca13_docs set collection_id = null where collection_id =  collectionId and doc_id = docId;
  else
    delete from rca13_docs where collection_id =  collectionId;
  end if;
  --update auditcheck_result set collection_id = null where collection_id =  collectionId;
  delete from rca13_collections_md where  collection_id =  collectionId;
  delete from auditcheck_result where  collection_id =  collectionId;  
  -- Data based on collection date --
  delete from auditcheck_patch_result where  collection_date =  colDate;
  delete from rca13_col2sys_mapping where collection_date = colDate and collection_name = colName;
  delete from rca13_collection_values where collection_date = colDate and collection_name = colName;
  delete from rca13_diff_info where cur_col_date = colDate and cur_col_name = colName;
  -- Delete All parsed data --
  delete from rca13_COLLECTIONS where collection_id =  collectionId;
  delete from rca13_DB_INSTANCES where collection_id =  collectionId;
  delete from rca13_DATABASES where collection_id =  collectionId;
  delete from rca13_IBS_SS where collection_id =  collectionId;
  delete from rca13_ASM_INSTANCES where collection_id =  collectionId;
  delete from rca13_HOSTS where collection_id =  collectionId;
  delete from rca13_HOMES where collection_id =  collectionId;
  delete from rca13_FILES where collection_id =  collectionId;
  -- Need order for the following 2 deletes
  delete from rca13_COLLECTION_FILE_DATA where collection_file_id in
  (select collection_file_id from rca13_COLLECTION_FILES where collection_id =  collectionId );
  delete from rca13_parameters where collection_id = collectionId;
  delete from rca13_COLLECTION_FILES where collection_id =  collectionId;
  delete from rca13_LOG where collection_id =  collectionId;
 end if;
 commit;
 -- Delete Ignored checks info
 delete from rca13_ignored_checks where COLLECTION_DATE is not null and COLLECTION_DATE = colDate and collection_name = colName;
 -- Delete Tickets info
 for rec in ( select ticket_id ti from rca13_ac_tickets where collection_date = colDate and collection_name = colName ) loop
     delete from rca13_intrack_incidents where id = rec.ti;
 end loop;              
 delete from  rca13_ac_tickets where collection_date = colDate and collection_name = colName;
 -- Deelte HIstory
 delete from rca13_track_actions where collection_date = colDate;
 commit;
 --Now do some thing about diff
 delete from rca13_diff_info where CUR_COL_DATE = colDate and CUR_COL_NAME = colName;
 commit;
 for rec in ( select CUR_COL_NAME cn,cur_col_date cd from rca13_diff_info where prev_col_date = colDate ) loop
  temp := hasDiffWithPrevRun(rec.cn,rec.cd);
 end loop;
 end;
--------------------------------------------------------------------------------
procedure purgeData(dat timestamp) is --delete data older than dat
begin
 --First delete based on docId  
 --Get all collections which are older than dat
 for rec in ( select doc_id did,collection_id cid from rca13_collections where collection_date <= dat ) loop
   deleteCollection(rec.did,0);
 end  loop;
 --Second delte based on date --THis data is not processed by zips
 --Don't delete sample data
 delete from rca13_collections_md where  collection_date <= dat and collection_name not in ('exachk_cetrain19_sidb_091913_151355','exachk_cetrain19_sidb_092713_163750');
 delete from auditcheck_result where  collection_date <= dat and upload_collection_name not in ('exachk_cetrain19_sidb_091913_151355','exachk_cetrain19_sidb_092713_163750');
 delete from auditcheck_patch_result where  collection_date <= dat;
 delete from rca13_col2sys_mapping where collection_date <= dat and collection_name not in ('exachk_cetrain19_sidb_091913_151355','exachk_cetrain19_sidb_092713_163750');
 delete from rca13_collection_values where collection_date <= dat and collection_name not in ('exachk_cetrain19_sidb_091913_151355','exachk_cetrain19_sidb_092713_163750');
 delete from rca13_diff_info where cur_col_date <= dat and collection_name not in ('exachk_cetrain19_sidb_091913_151355','exachk_cetrain19_sidb_092713_163750');
 commit;
 -- Delete Ignored checks info
 delete from rca13_ignored_checks where COLLECTION_DATE is not null and COLLECTION_DATE <= dat;
 -- Delete Tickets info
 for rec in ( select ticket_id ti from rca13_ac_tickets where collection_date <= dat
              and collection_name not in ('exachk_cetrain19_sidb_091913_151355','exachk_cetrain19_sidb_092713_163750') ) loop
     delete from rca13_intrack_incidents where id = rec.ti;
 end loop;              
 delete from  rca13_ac_tickets where collection_date <= dat and collection_name not in ('exachk_cetrain19_sidb_091913_151355','exachk_cetrain19_sidb_092713_163750');   
 -- Deelte HIstory
 delete from rca13_track_actions where collection_date <= dat;
 commit;
 --Now Re-caliculate every thing
 for rec in ( select collection_date cd,collection_name cn from rca13_collections_md ) loop
    rca13_manage_collections.afterColInUpActs(rec.cd,rec.cn,3);
 end loop;
end;
--------------------------------------------------------------------------------
procedure submitDataPurgeJob ( dat timestamp ) is
--Changing Jobname from RCA13_PURGE_DATA to RCA13_PUR
jobName varchar2(100) := 'RCA13_PUR_'|| RCA13_JOB_SEQ.nextval;
begin
--insert into a_temp_k (col) values('BEGIN rca13_manage_collections.purgeData(dat => to_timestamp('''||dat||''',''DD-MON-RR HH.MI.SS.FF AM'')); END;');
commit;
  DBMS_SCHEDULER.create_job (
    job_name   => jobName,
    job_type   => 'PLSQL_BLOCK',
    job_action => 'BEGIN rca13_manage_collections.purgeData(dat => to_timestamp('''||dat||''',''DD-MON-RR HH.MI.SS.FF AM'')); END;',
    start_date     => SYSTIMESTAMP,
    enabled => TRUE,
    comments => 'Purge Data Older than '||dat);
end;
--------------------------------------------------------------------------------
function hasDiff (pcName varchar2,pcDate timestamp,cName varchar2,cDate timestamp) return number is
rValue number;
cnt number := 0;
--Cursor for differed checks
cursor cur is select * from  (
select status1,hostname1,dbname1,instname1,c1,statusmsg1,
case when instr(StatusMsg1,'on infiniband switch',1,1) > 0 then substr(StatusMsg1,instr(StatusMsg1,'on infiniband switch',1,1)+21)
  else   null  end as switch1,
case when  regexp_count(StatusMsg1, '/' ) >4 or ct1='ORACLE_PATCH' then    substr(StatusMsg1,instr(StatusMsg1,' ',-1,1)+1)
  else    null  end as home1,
'<a id="'||c1||'" class="recommendation" style="cursor:pointer;" title="Recommendation" onclick="open_dialog('''||c1||''');">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</a>'||'<div id="'||c1||'_rec" style="display:none"></div>&nbsp;&nbsp;'||check_name as check_name,
status2,hostname2,dbname2,instname2,c2,sOrder1,statusmsg2,  
case   when instr(StatusMsg2,'on infiniband switch',1,1) > 0 then    substr(StatusMsg2,instr(StatusMsg2,'on infiniband switch',1,1)+21)
  else    null  end as switch2,
case   when  regexp_count(StatusMsg2, '/' ) >4 or ct2='ORACLE_PATCH' then    substr(StatusMsg2,instr(StatusMsg2,' ',-1,1)+1)
  else    null  end as home2    
from (
select  
a.status Status1,
a.hostname HostName1,a.db_name DBName1,a.instance_name InstName1,a.check_id c1,a.status_message StatusMsg1,a.check_type ct1,
decode(a.status,'FAIL',1,'WARNING',2,'INFO',3,'PASS',4,'INFO-PASS',5,'FAIL-IGNORED',6,7) sOrder1,
'<b>'||decode(a.check_type,'SQL_PARAM',a.PARAM_NAME,'OS_PARAM',a.PARAM_NAME,'OS_PACKAGE',a.PARAM_NAME,nvl(a.CHECK_NAME,a.PARAM_NAME))||'</b>' check_name,
b.status Status2,
b.hostname HostName2,b.db_name DBName2,b.instance_name InstName2,b.check_id c2,b.status_message StatusMsg2,b.check_type ct2
from  ( select * from auditcheck_result where collection_date = pcDate and upload_collection_name = pcName ) a,
      ( select * from auditcheck_result where collection_date = cDate and upload_collection_name = cName ) b
where
a.check_id = b.check_id
and nvl(a.hostname,'NA') = nvl(b.hostname,'NA')
and nvl(a.db_name,'NA') = nvl(b.db_name,'NA')
and nvl(a.instance_name,'NA') = nvl(b.instance_name,'NA')
) )
where Status1 != Status2
and nvl(switch1,'NA') = nvl(switch2,'NA')
and nvl(home1,'NA') = nvl(home2,'NA');
--Cursor for Checks only in collection 2
cursor cur2 is select  status,hostname,db_name,instance_name,check_id,status_message,
'<a id="'||check_id||'" class="recommendation" style="cursor:pointer;" title="Recommendation" onclick="open_dialog('''||check_id||''');">
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</a>'||'<div id="'||check_id||'_rec" style="display:none"></div>&nbsp;&nbsp;'||check_name as check_name
from (
select  a.status,a.hostname,a.db_name,a.instance_name,a.check_id,a.status_message,a.check_name
from  auditcheck_result a where collection_date = cDate and upload_collection_name = cName
MINUS
select status2 status ,hostname2 hostname,dbname2 db_name,instname2 instance_name,c2 check_id,statusmsg2 status_message,check_name from  (
select status2,hostname2,dbname2,instname2,c2,statusmsg2,check_name,
case when instr(StatusMsg1,'on infiniband switch',1,1) > 0 then substr(StatusMsg1,instr(StatusMsg1,'on infiniband switch',1,1)+21)
  else   null  end as switch1,
case when  regexp_count(StatusMsg1, '/' ) >4 or ct1='ORACLE_PATCH' then    substr(StatusMsg1,instr(StatusMsg1,' ',-1,1)+1)
  else    null  end as home1,
case when instr(StatusMsg2,'on infiniband switch',1,1) > 0 then substr(StatusMsg2,instr(StatusMsg2,'on infiniband switch',1,1)+21)
  else   null  end as switch2,
case when  regexp_count(StatusMsg2, '/' ) >4 or ct2='ORACLE_PATCH' then    substr(StatusMsg2,instr(StatusMsg2,' ',-1,1)+1)
  else    null  end as home2
from (
select  a.status Status1,a.hostname HostName1,a.db_name DBName1,a.instance_name InstName1,a.check_id c1,a.status_message StatusMsg1,a.check_name,a.check_type ct1,
        b.status Status2,b.hostname HostName2,b.db_name DBName2,b.instance_name InstName2,b.check_id c2,b.status_message StatusMsg2,b.check_type ct2
from  ( select * from auditcheck_result where collection_date = pcDate and upload_collection_name = pcName ) a,
      ( select * from auditcheck_result where collection_date = cDate and upload_collection_name = cName ) b
where
a.check_id = b.check_id
and nvl(a.hostname,'NA') = nvl(b.hostname,'NA')
and nvl(a.db_name,'NA') = nvl(b.db_name,'NA')
and nvl(a.instance_name,'NA') = nvl(b.instance_name,'NA')
) )
where nvl(switch1,'NA') = nvl(switch2,'NA')
and nvl(home1,'NA') = nvl(home2,'NA')
);
begin
  -- Now check whether it is good or bad diff ==> return 2 for good(green), 3 for bad(red), 4 for waring(orange)
  -- check for red
  rValue := 0;
  for rec in cur loop        
    if rec.Status2 = 'FAIL' then
       return 3; --Red --Return no need to go further
    elsif rec.Status2 = 'WARNING' then   
       rValue := 4; --Orange
    end if;
  end loop;  
  
  --dbms_output.put_line('2.rvalue='||rValue||' and '||cnt);
  if rValue != 4 then
    rValue := 2; --Diff not found, green
  end if;
   
  --dbms_output.put_line('2.rvalue='||rValue);
  --Now check checks only in collection2
  for rec in cur2 loop
    if rec.status = 'FAIL' then
      return 3; --Red
    elsif rec.status = 'WARNING' then
      cnt := 4;
    end if;    
  end loop;
  
  if rValue = 4 OR cnt = 4 then
    return 4; --Orange
  end if;  
  
  return 2; --Good Greem
  
end;
--------------------------------------------------------------------------------
function hasDiffWithPrevRun(cName varchar2,cDate timestamp) return varchar2 is
hName varchar2(100);
dPart varchar2(10);
tPart varchar2(10);
cTime date;
pcName varchar2(1000);
pcDate timestamp;
rVal varchar2(40);
attr1 varchar2(1000);
attr2 timestamp;
sysId varchar2(40);
PRAGMA AUTONOMOUS_TRANSACTION;
begin
 --Get system id
 begin
   select system_id into sysId from rca13_col2sys_mapping where collection_date = cDate and collection_name = cName;
   exception when others then null; --That is system not classified
 end;
 --Get previous collection name from the same system/hostname
 hname := substr(cName,instr(cName,'_',1,1)+1,instr(cName,'_',1,2)-instr(cName,'_',1,1)-1);
 if hname is not null then
   for rec in ( select a.collection_date,a.collection_name from rca13_collections_md a
                where sysId is null and a.collection_date < cDate and a.collection_name like '%\_'||hname||'\_%' escape '\'
                UNION
                select a.collection_date,a.collection_name from rca13_collections_md a,rca13_col2sys_mapping b
                where sysId is not null and a.collection_date < cDate and a.collection_name like '%\_'||hname||'\_%' escape '\'
                and a.collection_date = b.collection_date and a.collection_name = b.collection_name and b.system_id = sysId
                order by collection_date desc             
             ) loop
     pcName := rec.collection_name;
     pcDate := rec.collection_date;
     exit;
    end loop;
 elsif sysId is not null then --Get recent collection from system
     for rec in ( select a.collection_date,a.collection_name from rca13_collections_md a,rca13_col2sys_mapping b
                where a.collection_date < cDate and a.collection_date = b.collection_date
                and a.collection_name = b.collection_name and b.system_id = sysId
                order by collection_date desc             
             ) loop
      pcName := rec.collection_name;
      pcDate := rec.collection_date;
      exit;
     end loop;
 else -- No previous collection found
    return 0;
 end if;   
 
 -- check whether diff is already caliculate or not
 begin
  select diff_id,prev_col_name,prev_col_date into rVal,attr1,attr2 from rca13_diff_info
  where cur_col_name = cName and cur_col_date = cDate;
  exception when no_data_found then null;   
 end;
 --Return if the previous collection details are correct, else delete the entry and do fresh diff
 if rVal is not null then
  if (attr1 is null and attr2 is null ) or (attr1 = pcName  and attr2 = pcDate ) then
   return rVal;
  else
   delete from rca13_diff_info where diff_id = rVal;
   commit;
  end if;  
 end if;
 -- diff_types:
 --0 = prev col not found for the selected collection,
 --2 = diff found..but good( that is fail to pass, only region 1 ),Green,
 --3 = diff found, but bad ( some thing from good to fail, only region 1 ),Red
 --4 = diff found, Orange ( some thing from good to warning )
 if pcName is null OR pcDate is null then --No previous collection found
   insert into rca13_diff_info values(sys_guid(),cName,cDate,pcName,pcDate,0) return diff_id into rVal;
 else
   insert into rca13_diff_info values(sys_guid(),cName,cDate,pcName,pcDate,hasDiff(pcName,pcDate,cName,cDate)) return diff_id into rVal;
 end if;
 commit;    
 return rVal;
end;
--------------------------------------------------------------------------------
procedure submitJob(docId in number,user varchar2 default 'ORACHK.USER') is
--jobName varchar2(100) := 'RCA13_COL_' || docId || '_' || RCA13_JOB_SEQ.nextval;
--Remove docId from name as it is too big
jobName varchar2(100) := 'RCA13_COL_'|| RCA13_JOB_SEQ.nextval;
--PRAGMA AUTONOMOUS_TRANSACTION;
begin    
  DBMS_SCHEDULER.create_job (
    job_name   => jobName,
    job_type   => 'PLSQL_BLOCK',
    job_action => 'BEGIN rca13_manage_collections.process_collection(docId => '''||docId||'''); END;',
    start_date     => SYSTIMESTAMP,
    enabled => TRUE,
    comments => docId);
end;
--------------------------------------------------------------------------------
procedure submitJob4All is
jobName varchar2(100);
cnt number := 0;
begin    
 -- Limit Jobs population to 10. Otherwise there is a chance that it will fill job queue
 for rec in ( select doc_id docId from rca13_docs a where collection_id is null and attr1 = 'ZIP_FILE' and  
              not exists ( select 1 from rca13_collections b where a.doc_id = b.doc_id )
              UNION
              select doc_id docId from rca13_collections  where status = 'Failed' and fail_comment = 'NO_ENOUGH_SPACE'
              ) loop
   --Remove docId from name as it is too big           
   cnt := cnt + 1;
   exit when cnt > 10; -- Remaining collections will process in the next round
   --Changing job name from RCA13_COLLECTION to RCA13_COL to avoid job name lenght limit error
   jobName:= 'RCA13_COL_' ||RCA13_JOB_SEQ.nextval;
   DBMS_SCHEDULER.create_job(
    job_name   => jobName,
    job_type   => 'PLSQL_BLOCK',
    job_action => 'BEGIN rca13_manage_collections.process_collection(docId => '''||rec.docId||'''); END;',
    start_date     => SYSTIMESTAMP,
    enabled => TRUE,
    comments => rec.docId);
 end loop;   
end;
--------------------------------------------------------------------------------
procedure classifyCollection ( cDate timestamp,cName varchar2 ) is
cursor cur is select distinct cluster_name,hostname from auditcheck_result where collection_date = cDate
and upload_collection_name = cName order by hostname;
clusterName varchar2(256) := NULL;
cnt1 number;
sysId varchar2(40) := NULL;
flag number := 0;
cType varchar2(40) := 'Cluster';
defaultSid varchar2(40);
isNew number := 0;
begin
  --Get Cluster/system name
  for rec in cur loop
    if rec.cluster_name is not null then
      clusterName := rec.cluster_name;    
      exit;
    end if;  
  end loop;
  --If cluster name is null try to get host name from collection name
  if clusterName is null then
      clusterName := substr(cName,instr(cName,'_',1,1)+1,instr(cName,'_',1,2)-instr(cName,'_',1,1)-1);
      cType := 'Single Node';
  end if;
  --If cluster name is null, classify it as unknown
  if clusterName is null then
      clusterName := 'Unknown';
  end if;  
  --dbms_output.put_line('clusterName='||clusterName);
  select count(1) into cnt1 from rca13_systems where system_name = clusterName;
  --dbms_output.put_line('Is system already exists ?, cnt = '||cnt1);
  if cnt1 = 0 then --System not yet inserted
    insert into RCA13_SYSTEMS(system_id,system_name,system_type,created_by,created)
    values (sys_guid(),clusterName,'Cluster','USER',systimestamp) return system_id into sysId;
    isNew := 1;
  elsif cnt1 >= 1 then -- Find out correct system for which the collection belong to
    for rec in ( select system_id from rca13_systems where system_name = clusterName ) loop
      --dbms_output.put_line('sysId='||rec.system_id);
      for rec1 in ( select host_name from rca13_system_hosts where system_id = rec.system_id order by host_name ) loop
        --dbms_output.put_line('sysId and existing host name = '||rec.system_id||','||rec1.host_name);
        for rec2 in cur loop
           --dbms_output.put_line('new host name='||rec2.hostname);
           if rec2.hostname = rec1.host_name then
             --dbms_output.put_line('System found in table');
             sysId := rec.system_id;
             flag := 1;
             exit;
           end if;
        end loop;
        exit when flag = 1;
      end loop;
      exit when flag = 1;
    end loop;
  end if;
  --dbms_output.put_line('sysId='||sysId);
  if sysId is null then -- That is this system is new from existing systems
    insert into RCA13_SYSTEMS(system_id,system_name,system_type,created_by,created)
    values (sys_guid(),clusterName,cType,'USER',systimestamp) return system_id into sysId;
    isNew := 1;
    for rec in cur loop
      insert into rca13_system_hosts(SYS_HOST_ID,system_id,host_name) values(sys_guid(),sysId,rec.hostname);
    end loop;
  else
    -- Add new hosts to hosts table
    for rec in cur loop       
      begin
       insert into rca13_system_hosts(SYS_HOST_ID,system_id,host_name) values(sys_guid(),sysId,rec.hostname);
       --dbms_output.put_line('New hosts adding are:'||rec.hostname);
       exception when dup_val_on_index then null;
      end;
    end loop;
  end if;  
  -- Add collection to classification list
  --insert into rca13_col2sys_mapping(map_id,collection_date,collection_name,system_id) values(sys_guid(),TO_TIMESTAMP(cDate,'DD-MON-RR HH:MI:SS.FF AM'),cName,sysId);
  begin    
    insert into rca13_col2sys_mapping(map_id,collection_date,collection_name,system_id) values(sys_guid(),cDate,cName,sysId);
    exception when dup_val_on_index then null;
  end;  
  commit;
  --isNew = 1 ==> since system is new, map it to DEFAULT business unit by defalut(otherwise these collections will be invisible )
  if sysId != 'SAMPLE_SYSTEM' and isNew = 1 then
   insert into rca13_lob2sys_mapping(map_id,system_id,lob_id,created) values(sys_guid(),sysId,'DEFAULT','USER');
   commit;
  end if;
  exception when others then null;
end;    
--------------------------------------------------------------------------------
procedure classifyCollections is
cursor cur is select collection_date cd,collection_name ucn from rca13_collections_md a
  where not exists ( select 1 from rca13_col2sys_mapping b where a.collection_date  = b.collection_date and b.collection_name = a.collection_name );
begin
  for rec in cur loop
    --dbms_output.put_line('cDate='||rec.cd||' and cName='||rec.ucn);
    classifyCollection(rec.cd,rec.ucn);
  end loop;
end;
--------------------------------------------------------------------------------
procedure monitorDiffType is
temp varchar2(40);
begin
 for rec in ( select collection_date cDate,collection_name cName from rca13_collections_md
              where collection_date > sysdate - 90
              ) loop
   temp := hasDiffWithPrevRun(rec.cName,rec.cDate);
 end loop;
end;
--------------------------------------------------------------------------------
procedure updateMDtable is
cursor cur is select collection_date cd ,upload_collection_name ucn,collection_id ci from
   ( select distinct collection_date,upload_collection_name,collection_id from auditcheck_result ) a where
   a.collection_date is not null and upload_collection_name is not null and
   not exists ( select 1 from rca13_collections_md where collection_date = a.collection_date and collection_name = a.upload_collection_name );  
begin
 for rec in cur loop
   --Insert entry into rca13_collections_md table
   begin
    insert into rca13_collections_md(collection_date,collection_name,collection_id) values(rec.cd,rec.ucn,rec.ci);
    commit;    
    exception when dup_val_on_index then null;
   end;  
   --For each inserted row of rca13_collections_md, caliculate all stuff
   RCA13_MANAGE_COLLECTIONS.afterColInUpActs(rec.cd,rec.ucn);
 end loop;
 --There is a chance that collections can be added and removed in middle. So, make sure that diff_type is correct for each collection
 rca13_manage_collections.monitorDiffType();
 --Now, Process collections if any
 rca13_manage_collections.submitJob4All();   
end;
--------------------------------------------------------------------------------
procedure processAuditData is
jobName varchar2(100);
cnt number;
begin
   --If previous job is already running return
   begin
    select count(1) into cnt from user_scheduler_running_jobs where job_name like 'RCA13_PAD_%';
    exception when others then null;
   end;  
   if cnt > 0 then    return;   end if;
   --Changing job name from RCA13_PROCESS_DATA to RCA13_PAD to avoid jobname lenght limit error
   jobName  := 'RCA13_PAD_'|| RCA13_JOB_SEQ.nextval;
   DBMS_SCHEDULER.CREATE_JOB (
   job_name           =>  jobName,
   job_type           =>  'PLSQL_BLOCK',
   job_action         =>  'BEGIN rca13_manage_collections.updateMDtable; END;',
   start_date         =>   systimestamp,
   enabled            =>   TRUE,
   comments           =>  'ORAchk App:Process Audit Data');
end;
--------------------------------------------------------------------------------
--Trigger the following procedure if inserting on rca13_collection_md .. do the following
--1. Classify collection
--2. Caliculate score,fails count,pass count,warning count and diff info
procedure afterColInUpActs( collectionDate timestamp,collectionName varchar2,flag number default 1 ) is
score number;
fCount number;
wCount number;
pCount number;
iCount number; --Info
igCount number; --Ignored count
fixedCount number;
sysId varchar2(40);
diff number;
temp varchar2(40);
begin
 --flag = 1 => Collection is just inserted
 --flag = 2 => When check is ignored or ticket is closed on check/collection
 --flag = 3 ==> when data purged
 --Classify collection
 if flag = 1 then --For other flags no need to call it
  --This is one time job
  classifyCollection(collectionDate,collectionName);
 end if;
 --get system id for which the collection belongs to
 begin  
  select system_id into sysId from rca13_col2sys_mapping where collection_date = collectionDate and collection_name = collectionName;
  exception when no_data_found then return;
 end;  
 --caliculate collection Score
 score := RCA13_GET_DATA4COLUMNS.getCollectionScore(null,collectionName,collectionDate);
 --caliculate check counts
 --While caliculating fails,warning & info if check is ignored don't consider that check
 select count(1) into fCount from auditcheck_result a
 where a.collection_date = collectionDate and a.UPLOAD_COLLECTION_NAME = collectionName and a.status = 'FAIL'
 AND NOT EXISTS ( SELECT 1 FROM rca13_ignored_checks t1 WHERE a.check_id = t1.check_id
 AND t1.system_id =sysId AND ( t1.collection_date IS NULL OR ( t1.collection_date  = a.collection_date
 and t1.collection_name = a.UPLOAD_COLLECTION_NAME and acr_id is null )
 OR acr_id = a.auditcheck_result_id) );
 
 select count(1) into wCount from auditcheck_result a
 where a.collection_date = collectionDate and a.UPLOAD_COLLECTION_NAME = collectionName and a.status = 'WARNING'
 AND NOT EXISTS ( SELECT 1 FROM rca13_ignored_checks t1 WHERE a.check_id = t1.check_id
 AND t1.system_id =sysId AND ( t1.collection_date IS NULL OR ( t1.collection_date  = a.collection_date
 and t1.collection_name = a.UPLOAD_COLLECTION_NAME and acr_id is null )
 OR acr_id = a.auditcheck_result_id) );
 
 select count(1) into iCount from auditcheck_result a
 where a.collection_date = collectionDate and a.UPLOAD_COLLECTION_NAME = collectionName and a.status  = 'INFO'
 AND NOT EXISTS ( SELECT 1 FROM rca13_ignored_checks t1 WHERE a.check_id = t1.check_id
 AND t1.system_id =sysId AND ( t1.collection_date IS NULL OR ( t1.collection_date  = a.collection_date
 and t1.collection_name = a.UPLOAD_COLLECTION_NAME and acr_id is null )
 OR acr_id = a.auditcheck_result_id) );
 
 select count(1) into pCount from auditcheck_result where collection_date = collectionDate
 and UPLOAD_COLLECTION_NAME = collectionName and status in ('PASS','INFO-PASS');
 
 select count(1) into fixedCount from auditcheck_result a,rca13_col2sys_mapping b,rca13_ac_tickets c
 where a.collection_date = collectionDate and a.UPLOAD_COLLECTION_NAME = collectionName
 and a.collection_date = b.collection_date and a.UPLOAD_COLLECTION_NAME = b.collection_name and b.system_id = c.system_id
 and ( ( c.collection_date  = collectionDate and c.collection_name = collectionName ) OR c.attr1 = a.auditcheck_result_id );
 
 --TODO: If ticket is closed on collection all non passes should come under FIXED
 select count(1) into igCount from auditcheck_result a where a.collection_date = collectionDate
 and a.UPLOAD_COLLECTION_NAME = collectionName and a.status in ('FAIL','WARNING','INFO')
 AND EXISTS ( SELECT 1 FROM rca13_ignored_checks t1 WHERE a.check_id = t1.check_id
 AND t1.system_id =sysId AND ( t1.collection_date IS NULL OR ( t1.collection_date  = a.collection_date
 and t1.collection_name = a.UPLOAD_COLLECTION_NAME and acr_id is null )
 OR acr_id = a.auditcheck_result_id) );
 
 
 --Delete collection details from rca13_collection_values, if already exists
 delete from rca13_collection_values where collection_date = collectionDate and collection_name = collectionName;
 commit;
 insert into rca13_collection_values(score,f_count,w_count,p_count,collection_date,collection_name,i_count,ig_count)
 values(score,fCount,wCount,pCount,collectionDate,collectionName,iCount,igCount);
 commit;
 --Caliculate diff .. we call it for each insertion of row in rca13_collections_md
 --TODO: Handle it while deletion on row
 if flag = 1 OR flag = 3 then
  temp := hasDiffWithPrevRun(collectionName,collectionDate);
 end if;
 commit;
 --exception when others then
 --dbms_output.put_line('cd='||collectionDate||' , and cn='||collectionName);
 --null;
end;
--------------------------------------------------------------------------------
--After insert and after delete triggers
procedure ignoreReCalValues_AIAD(sysId varchar2,collectionDate timestamp,colName varchar2) is
cnt number;
begin
  select count(*) into cnt from rca13_ignored_checks where system_id = sysId;
  if collectionDate is not null then
    --select collection_name into colName from rca13_collections_md where collection_date = collectionDate;
    --If collection date is not null, that is ignore happended at collection level
    afterColInUpActs(collectionDate,colName,2);
  else -- that is check is ignored at system level
    for rec in ( select collection_date cd,collection_name cn from rca13_col2sys_mapping where system_id = sysId ) loop
      afterColInUpActs(rec.cd,rec.cn,2);
    end loop;
  end if;
  exception when others then null;
end;
--------------------------------------------------------------------------------
END rca13_MANAGE_COLLECTIONS;


/
--get data4columns
create or replace PACKAGE RCA13_GET_DATA4COLUMNS AS 
  function getIBSwitches(collectionId varchar2,cNo number) return varchar2;
  function getDatabases(collectionId varchar2,cNo number) return varchar2;
  function getStorageServers(collectionId varchar2,cNo number) return varchar2;
  function getCrsHome(collectionId varchar2) return varchar2;
  function getASMHome(collectionId varchar2) return varchar2;
  function getRdbmsHome(collectionId varchar2) return varchar2;
  function getDBServers(collectionId varchar2,cNo number) return varchar2;
  function getCollectionScore(collectionId varchar2,cName varchar2,cDate timestamp,flag number default 0 ) return number;
END RCA13_GET_DATA4COLUMNS;
/

create or replace PACKAGE BODY RCA13_GET_DATA4COLUMNS AS
--------------------------------------------------------------------------------
function getCrsHome(collectionId varchar2) return varchar2 as
home varchar2(1000);
begin
 select home_path||' - '||version into home from rca13_homes where collection_id = collectionId and type in ('CRS','GI');
 return home;
 exception when others then return null;
end;
--------------------------------------------------------------------------------
function getASMHome(collectionId varchar2) return varchar2 as
home varchar2(1000);
begin
 select home_path||' - '||version into home from rca13_homes where collection_id = collectionId and type in ('ASM');
 return home;
 exception when others then return null;
end;
--------------------------------------------------------------------------------
function getRdbmsHome(collectionId varchar2) return varchar2 as
home varchar2(1000);
begin
 for rec in ( select home_path||' - '||version h from rca13_homes where collection_id = collectionId and type in ('RDBMS') ) loop
  home := home ||rec.h||'<br>';
 end loop;
 return rtrim(home,'<br>');
 exception when others then return null;
end;
--------------------------------------------------------------------------------
function getDBServers(collectionId varchar2,cNo number) return varchar2 as
nodesList varchar2(4000);
begin
 for rec in ( select host_name hn from rca13_hosts where collection_id = collectionId ) loop
  nodesList := nodesList || rec.hn||', ';
 end loop;
  nodesList := rtrim(nodesList,', ');
 if length(nodesList) > 100 then 
  nodesList := substr(nodesList,1,100)||'<div id="nodesList'||cNo||'" style="DISPLAY: none">'|| 
              substr(nodesList,101)||' </div> <br> <a id="nodesList'||cNo||'_mh" href="javascript:;" onclick="javascript:ShowHide(''nodesList'||cNo||''')">...More</a>';
 end if;
return nodesList;
end;
--------------------------------------------------------------------------------
function getStorageServers(collectionId varchar2,cNo number) return varchar2 as
nodesList varchar2(4000);
begin
 for rec in ( select name hn from rca13_ibs_ss where collection_id = collectionId and type like 'C') loop
  nodesList := nodesList || rec.hn||', ';
 end loop;
 nodesList := rtrim(nodesList,', ');
 if length(nodesList) > 100 then 
  nodesList := substr(nodesList,1,100)||'<div id="cellsList'||cNo||'" style="DISPLAY: none">'|| 
              substr(nodesList,101)||' </div> <br> <a id="cellsList'||cNo||'_mh" href="javascript:;" onclick="javascript:ShowHide(''cellsList'||cNo||''')">...More</a>';
 end if;
return nodesList;
end;
--------------------------------------------------------------------------------
function getDatabases(collectionId varchar2,cNo number) return varchar2 as
nodesList varchar2(4000);
begin
 for rec in ( select db_name hn,database_role dr from rca13_databases where collection_id = collectionId) loop
   if rec.dr is null then
     nodesList := nodesList || rec.hn||', ';
   else
     nodesList := nodesList || rec.hn||'('||rec.dr||')'||', ';
   end if;  
 end loop;
 nodesList := rtrim(nodesList,', ');
 if length(nodesList) > 100 then 
  nodesList := substr(nodesList,1,100)||'<div id="databasesList'||cNo||'" style="DISPLAY: none">'|| 
              substr(nodesList,101)||' </div> <br> <a id="databasesList'||cNo||'_mh" href="javascript:;" onclick="javascript:ShowHide(''databasesList'||cNo||''')">...More</a>';
 end if;
return nodesList;
end;
--------------------------------------------------------------------------------
function getIBSwitches(collectionId varchar2,cNo number) return varchar2 as
nodesList varchar2(4000);
begin
 for rec in ( select name hn from rca13_ibs_ss where collection_id = collectionId and type like 'S') loop
  nodesList := nodesList || rec.hn||', ';
 end loop;
 nodesList := rtrim(nodesList,', ');
 if length(nodesList) > 100 then 
  nodesList := substr(nodesList,1,100)||'<div id="switchesList'||cNo||'" style="DISPLAY: none">'|| 
              substr(nodesList,101)||' </div> <br> <a id="switchesList'||cNo||'_mh" href="javascript:;" onclick="javascript:ShowHide(''switchesList'||cNo||''')">...More</a>';
 end if;
return nodesList;
end;
--------------------------------------------------------------------------------
function getCollectionScore(collectionId varchar2,cName varchar2,cDate timestamp,flag number default 0) return number as
crh_total_points number;
crh_err_points number;
crh_less_points number;
crh_health number;
G_TOTAL_CHECKS number := 0;
G_FAIL_CHECKS number := 0;
G_WARN_CHECKS number := 0;
G_INFO_CHECKS number := 0;
sysId varchar2(40);
cnt number;
skippedChecksCnt number := 0;
isExalogic number := 0;
PRAGMA AUTONOMOUS_TRANSACTION;
begin
   -- Get system id of collection
   select system_id into sysId from rca13_col2sys_mapping where collection_date = cDate and collection_name = cName;
   --If ticket is closed on collection, return score as 100%
   if flag = 1 then ---call from trigger
     select count(1) into cnt from rca13_ac_tickets a,rca13_intrack_incidents b 
     where a.collection_date = cDate and a.collection_name = cName and a.ticket_id = b.id;
   else 
     select count(1) into cnt from rca13_ac_tickets a,rca13_intrack_incidents b 
     where a.collection_date = cDate and a.collection_name = cName and a.ticket_id = b.id and b.status_code >= 80;
   end if;
   
   if cnt > 0 then 
     return 100;
   end if;   
   -- Following statement fails when result is inserted before collection is processed
   -- But we should update after collection is processed
   if collectionid is not null then 
    begin
     select skipped_checks,is_exalogic into skippedChecksCnt,isExalogic from rca13_collections where collection_id = collectionid;
     exception when others then null; -- Score will not consider skipped checks
    end; 
   end if; 
   select count(*) into G_TOTAL_CHECKS from auditcheck_result a where collection_date = cDate and upload_collection_name = cName  
   AND not exists ( SELECT 1 FROM rca13_ignored_checks t1 WHERE a.check_id = t1.check_id and a.status = 'FAIL'
   AND t1.system_id =sysId AND ( t1.collection_date IS NULL OR ( t1.collection_date  = a.collection_date 
   and t1.collection_name = a.UPLOAD_COLLECTION_NAME and acr_id is null ) 
   OR acr_id = a.auditcheck_result_id) ); 
   --If check is ignored, don't use it for caliculating score
   for rec in ( select status,auditcheck_result_id ari from auditcheck_result a where a.collection_date = cDate and a.UPLOAD_COLLECTION_NAME = cName 
                and a.status in ('FAIL','WARNING','INFO') and 
                not exists ( SELECT 1 FROM rca13_ignored_checks t1 WHERE a.check_id = t1.check_id and a.status = 'FAIL'
                AND t1.system_id =sysId AND ( t1.collection_date IS NULL OR ( t1.collection_date  = a.collection_date 
                and t1.collection_name = a.UPLOAD_COLLECTION_NAME and acr_id is null ) 
                OR acr_id = a.auditcheck_result_id ) ) ) loop 
     --If ticket is closed on check, use failed/warned check as pass and caliculate score
     cnt := 0;
     select count(1) into cnt from rca13_ac_tickets a,rca13_intrack_incidents b 
     where a.attr1 = rec.ari and a.ticket_id = b.id and b.status_code >= 80;
     continue when cnt > 0; 
     case 
        when rec.status = 'FAIL' then
          G_FAIL_CHECKS := G_FAIL_CHECKS + 1;
        when rec.status = 'WARNING' then
          G_WARN_CHECKS := G_WARN_CHECKS + 1; 
        when rec.status = 'INFO' then 
          G_INFO_CHECKS := G_INFO_CHECKS + 1;
        else
          G_FAIL_CHECKS := G_FAIL_CHECKS + 1;
     end case;
   end loop;
 crh_total_points := G_TOTAL_CHECKS*10;
 --dbms_output.put_line('total='||crh_total_points);
 if isExalogic = 1 then
   crh_err_points := G_FAIL_CHECKS*10+G_WARN_CHECKS*5+G_INFO_CHECKS*3+skippedChecksCnt*10;
 else
   crh_err_points := G_FAIL_CHECKS*10+G_WARN_CHECKS*5+G_INFO_CHECKS*3+skippedChecksCnt*3;
 end if;  
 --dbms_output.put_line(G_FAIL_CHECKS||'*10+'||G_WARN_CHECKS||'*5+'||G_INFO_CHECKS||'*3');
 crh_less_points := crh_total_points - crh_err_points;
 crh_health := 0;
  if crh_total_points > 0 then 
    crh_health := crh_less_points*100 / crh_total_points;    
  end if;
  return round(crh_health);
end;
--------------------------------------------------------------------------------
--Get check actual values
function getCheckDetails (cDate timestamp,checkId varchar2) return clob is
rValue clob;
collectionId varchar2(40);
cName varchar2(256);
htmlFileId varchar2(40) := NULL;
readingOn number := 0;
begin
 begin
   --For now we are not calling this fun anyware .. don't worry about collection_name column for now
   select collection_id,collection_name into collectionId,cName from rca13_collections where collection_date = cDate;
   exception when NO_DATA_FOUND then return null;  
 end;  
 -- Get file id of html file
 for rec in ( select collection_file_id cfi from rca13_collection_files a where short_file_name = cName||'.html' 
              and collection_id = collectionId 
              and (select count(1) from rca13_collection_file_data where collection_file_id = a.collection_file_id ) > 0 ) loop
   htmlFileId := rec.cfi;
 end loop; 
 if htmlFileId is null then 
   return null;
 end if;
 for rec in ( select line_text lt from rca13_collection_file_data where collection_file_id = htmlFileId order by line_number ) loop 
   if readingOn = 0 and instr(rec.lt,'id="'||checkId||'_contents"') > 0 then
     readingOn := 1;
   end if;
   if readingOn = 1 and instr(rec.lt,'<div id="') > 0 and  instr(rec.lt,'_contents">') > 0 then
     exit;
   end if;   
   if readingOn = 1 then 
     rValue := rValue || rec.lt;
   end if;
 end loop;
 return rValue;
end;
--------------------------------------------------------------------------------
END RCA13_GET_DATA4COLUMNS;
/
--Email
create or replace PACKAGE RCA13_EMAIL AS 
   this_package constant varchar2(33) := 'email.';
   "collection is not one based"    constant varchar2(65) := this_package || 'collection_is_not_one_based';
   "exception does not exist"       constant varchar2(65) := this_package || 'exception_does_not_exist';
   "exception outside user range"   constant varchar2(65) := this_package || 'exception_outside_user_range';
   "fatal html syntax error"        constant varchar2(65) := this_package || 'fatal_html_syntax_error';
   "generic exception"              constant varchar2(65) := this_package || 'generic_exception';
   "invalid user"                   constant varchar2(65) := this_package || 'invalid_user';
   "lookup table is corrupt"        constant varchar2(65) := this_package || 'lookup_table_is_corrupt';
   "mandatory decision tree failed" constant varchar2(65) := this_package || 'mandatory_decision_tree_failed';
   "package state undefined"        constant varchar2(65) := this_package || 'package_state_undefined';
   "parameter cannot be null"       constant varchar2(65) := this_package || 'parameter_cannot_be_null';
   "parameter did not conform"      constant varchar2(65) := this_package || 'parameter_did_not_conform';
   "security violation"             constant varchar2(65) := this_package || 'security_violation';
   "sparse collection not allowed"  constant varchar2(65) := this_package || 'sparse_collection_not_allowed';
   "string too large"               constant varchar2(65) := this_package || 'string_too_large';
   collection_is_not_one_based exception;
   exception_outside_user_range exception;
   exception_does_not_exist exception;
   fatal_html_syntax_error exception;
   generic_exception exception;
   invalid_user exception;
   lookup_table_is_corrupt exception;
   mandatory_decision_tree_failed exception;
   package_state_undefined exception;
   parameter_cannot_be_null exception;
   parameter_did_not_conform exception;
   security_violation exception;
   sparse_collection_not_allowed exception;
   string_too_large exception;
   pragma exception_init(security_violation, -20013);
   pragma exception_init(exception_does_not_exist, -20012);
   pragma exception_init(mandatory_decision_tree_failed, -20011);
   pragma exception_init(exception_outside_user_range, -20010);
   pragma exception_init(invalid_user, -20009);
   pragma exception_init(package_state_undefined, -20008);
   pragma exception_init(fatal_html_syntax_error, -20007);
   pragma exception_init(parameter_did_not_conform, -20006);
   pragma exception_init(lookup_table_is_corrupt, -20005);
   pragma exception_init(collection_is_not_one_based, -20004);
   pragma exception_init(sparse_collection_not_allowed, -20003);
   pragma exception_init(parameter_cannot_be_null, -20002);
   pragma exception_init(string_too_large, -20001);
   pragma exception_init(generic_exception, -20000);

TYPE CIO_PLSQL_STRING_ARRAY is table of varchar2(32767);
type error_stack_token_table_type is table of varchar2(4000) index by varchar2(256);
type attachment_rec_type is record( binary_file blob,file_name   varchar2(512));
type attachment_tbl_type is table of attachment_rec_type index by binary_integer;

procedure send ( toEmail in varchar2, fromEmail in varchar2,fromName in varchar2, 
                 subject in varchar2,messageText in clob,bccList in varchar2 default null);
   
END RCA13_EMAIL;
/

    
create or replace PACKAGE BODY RCA13_EMAIL AS
c_x_mailer constant varchar2(256) := 'CleverIdeasForOracle http://cleveridea.net';
procedure logError (emailAddress varchar2, subject varchar2, messageText clob, errorText varchar2) is
errorClob CLOB := errorText;
foo number;
begin
foo := length(messageText);
insert into rca13_email_failure (email_address, subject, message_text, message_length, error_text)
values (substr(emailAddress,1,900),substr(logError.subject,1,900), dbms_lob.substr(messageText,1,3900) , length(messageText), errorClob);
commit;
end;
-----------------------------------------------------------
procedure smtp_write ( c in out utl_smtp.connection, data in varchar2 ) is
begin
   --We need to include a carriage return or line feed (CRLF) every 1000 characters when sending HTML based e-mails from Oracle
   utl_smtp.write_data(c, data||utl_tcp.crlf);
end smtp_write;
-----------------------------------------------------------
procedure add_attachment (v_connection in out nocopy utl_smtp.connection,p_attachment in out blob
                          ,p_attachment_name in varchar2,p_boundary in varchar2  ) is
      C_BASE64_CHUNK_SIZE constant pls_integer := 78;
      v_base64_chunk      raw(32767);
      v_position          integer := 1;
      v_attachment_length integer;
      v_amount            binary_integer := 32767;
   begin
      smtp_write(v_connection, '');
      smtp_write(v_connection, '');
      smtp_write(v_connection, '--' || p_boundary);
      smtp_write(v_connection, 'Content-Type: application/octet-stream; name="' || p_attachment_name || '"');
      smtp_write(v_connection, 'Content-Disposition: attachment; filename="' || p_attachment_name || '"');
      smtp_write(v_connection, 'Content-Transfer-Encoding: base64');
      smtp_write(v_connection, '');
      smtp_write(v_connection, '');

      v_attachment_length := dbms_lob.getlength(p_attachment);
      if dbms_lob.isopen(p_attachment) = 0 then
         dbms_lob.open(p_attachment, dbms_lob.lob_readonly);
      end if;
      while v_position < v_attachment_length  loop
         v_amount := C_BASE64_CHUNK_SIZE;
         dbms_lob.read(p_attachment, v_amount, v_position, v_base64_chunk);
         utl_smtp.write_raw_data(v_connection, utl_encode.base64_encode(v_base64_chunk));
         v_position := v_position + C_BASE64_CHUNK_SIZE;
         smtp_write(v_connection, '');
      end loop;

      if dbms_lob.isopen(p_attachment) != 0
      then
         dbms_lob.close(p_attachment);
      end if;

      smtp_write(v_connection, '');
      smtp_write(v_connection, '');

   end add_attachment;
-------------------------------------------------------   
FUNCTION loopThroughClob (srcClob IN CLOB) return dbms_sql.varchar2a is
v_result        dbms_sql.varchar2a;
vBuffer    VARCHAR2 (32767);
l_amount   BINARY_INTEGER := 900;
startPosition BINARY_INTEGER := 1;
endingPosition number;
chunk varchar2(1000);
foo varchar2(32767);
arrayCounter number := 1;
emailDone number := 0;
BEGIN
--dbms_output.put_line('TOTAL SIZE: ' || dbms_lob.getlength(srcClob));
LOOP
  begin
   dbms_lob.read(srcClob, l_amount, startPosition, vBuffer); --loaded 900 new bytes, starting where we left off                
   exception when no_data_found then
   --dbms_output.put_line('EXIT');
   exit;
  end;   
  if (length(vBuffer) < 900) then
        chunk := vBuffer;
        emailDone := 1;
  else
        --find the last space in the string
        --dbms_output.put_line('*** BUFFER: ' || vBuffer);
        dbms_output.put_line('*** BUFFER LENGTH: ' || length(vBuffer));        
        endingPosition := instr(vBuffer,' ',-1,1);
        dbms_output.put_line('*** READ BUFFER FROM 1 to ' || endingPosition);
        dbms_output.put_line('*** READ SIZE: ' || length(substr(vBuffer,1,endingPosition)) );
        foo := substr(vBuffer,1,endingPosition);    
        dbms_output.put_line('*** FOO LENGTH: ' || LENGTHB(foo) );
        chunk := foo;
  end if;
  --the next loop will start where the last one ended off
  startPosition := startPosition + endingPosition;    
  endingPosition := null;
  v_result(arrayCounter) :=  chunk;
  arrayCounter := arrayCounter + 1;
  exit when arrayCounter = 99999; --protectino from runaways
  --exit when length(vBuffer) < 900;
  exit when emailDone = 1;
END LOOP;
return v_result;    
END;
--------------------------------------------------------------------------------
function clob_to_varchars ( p_clob in clob,p_chunk_size in integer) return dbms_sql.varchar2a is
v_result        dbms_sql.varchar2a;
v_cursor_id     integer;
v_cursor_result integer;
begin
for i in 0 .. trunc(dbms_lob.getlength(p_clob) / p_chunk_size) loop
  v_result(i + 1) := dbms_lob.substr(p_clob, p_chunk_size, (i * p_chunk_size) + 1);
end loop;
return v_result;
end clob_to_varchars;
--------------------------------------------------------------------------------
procedure sanity_check_on_seperator(p_separator in varchar2,v_tokens out error_stack_token_table_type) is
begin
if p_separator is null then
 v_tokens(1) := 'p_separator';
end if;
if length(p_separator) > 1 then
 v_tokens(1) := 'p_seperator';
 v_tokens(2) := 'of a single character';
end if;
end sanity_check_on_seperator;
--------------------------------------------------------------------------------
function list_to_table(p_list in varchar2,p_separator in varchar2 default ',') return cio_plsql_string_array is
c_max_elements constant binary_integer := 16384;
v_tokens error_stack_token_table_type;
v_return                  cio_plsql_string_array := new cio_plsql_string_array();
v_element_count           binary_integer;
v_previous_comma_position binary_integer;
v_next_comma_position     binary_integer;
begin
 sanity_check_on_seperator(p_separator, v_tokens);
 if p_list is null then
   return null;
 end if;
 v_previous_comma_position := 0;
 v_next_comma_position     := 0;
 v_element_count           := 1;
 for i in 1 .. c_max_elements loop
  v_next_comma_position := instr(p_list, p_separator, v_previous_comma_position + 1, 1);
  if v_next_comma_position = 0 then
   exit;
  end if;
  v_previous_comma_position := v_next_comma_position;
  v_element_count           := v_element_count + 1;
 end loop;
 v_previous_comma_position := 0;
 v_next_comma_position     := 0;
 for i in 1 .. v_element_count - 1 loop
  v_return.extend;
  v_next_comma_position := instr(p_list, p_separator, 1, i);
  dbms_output.put_line('v_next_comma_position     =' || v_next_comma_position);
  dbms_output.put_line('v_previous_comma_position =' || v_previous_comma_position);
  v_return(i) := substr(p_list, v_previous_comma_position + 1, v_next_comma_position - v_previous_comma_position - 1);
  v_previous_comma_position := v_next_comma_position;
 end loop;
 -- get the last element
 if v_element_count > 1 then
  v_return.extend;
  v_return(v_element_count) := substr(p_list, v_next_comma_position + 1);
 end if;
 return v_return;
 exception  
    when parameter_did_not_conform then null;
    when parameter_cannot_be_null then null;
end list_to_table;
----------------------------------------------------------------------------------
procedure send_email (
      p_from_email    in varchar2
     ,p_from_replyto  in varchar2
     ,p_to_list       in varchar2
     ,p_cc_list       in varchar2
     ,p_bcc_list      in varchar2
     ,p_subject       in varchar2
     ,p_text_message  in clob
     ,p_content_type  in varchar2
     ,p_attachments   in attachment_tbl_type
     ,p_priority      in varchar2
     ,p_auth_username in varchar2
     ,p_auth_password in varchar2
     ,p_mail_server   in varchar2
     ,p_port          in integer ) is
      c_default_content_type constant varchar2(512) := 'text/plain';
      v_connection   utl_smtp.connection;
      v_chunks       dbms_sql.varchar2a;
      v_blob         blob;
      v_boundary     varchar2(80) := 'CleverIdeasForOracleBoundary';
      v_from_replyto varchar2(4000);
      v_content_type varchar2(512);
      procedure send_rcpt(p_target in varchar2) is
         v_rcpt_array cio_plsql_string_array;
      begin
         if (instr(replace(p_target, ';', ','), ',') > 0)
         then
            v_rcpt_array := list_to_table(replace(p_target, ';', ','));
            for i in 1 .. v_rcpt_array.count
            loop
               utl_smtp.rcpt(v_connection, v_rcpt_array(i));
            end loop;
         else
            utl_smtp.rcpt(v_connection, p_target);
         end if;
      end send_rcpt;
begin
      --utl_tcp.close_all_connections;
      v_connection := utl_smtp.open_connection(p_mail_server, p_port);
      utl_smtp.helo(v_connection, p_mail_server);
      if (p_auth_username is not null or p_auth_password is not null)  then
         utl_smtp.command(v_connection, 'AUTH LOGIN');
         utl_smtp.command(v_connection, utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(p_auth_username))));
         utl_smtp.command(v_connection, utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(p_auth_password))));
      end if;
      utl_smtp.mail(v_connection, p_from_email);
      if trim(p_to_list) is not null then
         send_rcpt(trim(p_to_list));
      end if;
      if trim(p_cc_list) is not null then
         send_rcpt(trim(p_cc_list));
      end if;
      if trim(p_bcc_list) is not null then
         send_rcpt(trim(p_bcc_list));
      end if;
      utl_smtp.open_data(v_connection);
      v_from_replyto := nvl(trim(p_from_replyto), trim(p_from_email));
      if (v_from_replyto is not null) then
         smtp_write(v_connection, 'From:' || v_from_replyto);
         smtp_write(v_connection, 'ReplyTo:' || v_from_replyto);
         -- these are coupled because for the e-mail clients I tested, the ReplyTo:
         -- was simply ignored and the From: was used anyway.
      end if;
      if (trim(p_to_list) is not null) then
         smtp_write(v_connection, 'To:' || trim(p_to_list));
      end if;
      if (trim(p_cc_list) is not null) then
         smtp_write(v_connection, 'Cc:' || trim(p_cc_list));
      end if;      
      if (trim(p_bcc_list) is not null) then
         smtp_write(v_connection, 'Bcc:' || trim(p_bcc_list));
      end if;
      if (trim(p_subject) is not null) then
         smtp_write(v_connection, 'Subject:' || trim(p_subject));
      end if;
      smtp_write(v_connection, 'X-Mailer:' || c_x_mailer);
      if (trim(p_priority) is not null) then
         smtp_write(v_connection, 'X-Priority:' || trim(p_priority));
      end if;
      if p_attachments.count > 0  then
         smtp_write(v_connection, 'Content-Type:multipart/mixed;boundary=' || v_boundary);
         smtp_write(v_connection, '');
         smtp_write(v_connection, 'You are reading this because you are ');
         smtp_write(v_connection, 'using non-MIME compliant reader - this mail agent ');
         smtp_write(v_connection, c_x_mailer || ' expects you to be using one.');
         smtp_write(v_connection, '');
         smtp_write(v_connection, '--' || v_boundary);
      end if;

      v_content_type := nvl(trim(p_content_type), c_default_content_type);
      smtp_write(v_connection, 'Content-Type:' || v_content_type);
      smtp_write(v_connection, '');

      if (nvl(length(p_text_message), 0) > 0) then
         --v_chunks := clob_to_varchars(p_text_message, 900);
         v_chunks := loopThroughClob(p_text_message);
         for i in v_chunks.first .. v_chunks.last loop
            smtp_write(v_connection, replace(v_chunks(i), chr(10), chr(13)));
         end loop;
      end if;
      smtp_write(v_connection, '');
      smtp_write(v_connection, '');
      if p_attachments.count > 0 then
         for i in p_attachments.first .. p_attachments.last loop
            v_blob := p_attachments(i).binary_file;
            add_attachment(v_connection, v_blob, p_attachments(i).file_name, v_boundary);
         end loop;
      end if;
      smtp_write(v_connection, '');
      if p_attachments.count > 0 then
         smtp_write(v_connection, '--' || v_boundary || '--');
      end if;
      utl_smtp.close_data(v_connection);
      utl_smtp.quit(v_connection);
   exception
    when utl_smtp.transient_error or utl_smtp.permanent_error then
     begin
      utl_smtp.quit(v_connection);
      exception when others then null; -- the quit call will raise an exception that we can ignore.
     end;
     raise;
    when others then      
     begin
      
      logError (emailAddress => nvl(p_to_list,p_bcc_list), subject => p_subject, messageText => p_text_message, errorText => DBMS_UTILITY.FORMAT_ERROR_STACK || ' ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
      utl_smtp.quit(v_connection);
      exception when others then
        logError (emailAddress => nvl(p_to_list,p_bcc_list), subject => p_subject, messageText => p_text_message, errorText => DBMS_UTILITY.FORMAT_ERROR_STACK || ' ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        null; -- the quit call will raise an exception that we can ignore.
     end;
     raise;
end;
-----------------------------------------------------------------------------------------
procedure send( toEmail in varchar2, fromEmail in varchar2, fromName in varchar2,
subject in varchar2, messageText in clob,bccList in varchar2 default null) as
   v_attachments rca13_email.attachment_tbl_type;
   optedOut number;
   errorStack varchar2(4000);
   skipEmail exception;
   serverName varchar2(200);
   portNum integer;
   userId varchar2(40);
begin
   if (toEmail is null and bccList is null) then
      raise skipEmail;
   end if;
   begin
    select server_name,port into serverName,portNum from rca13_mail_server where rownum =1;
    exception when no_data_found then
    raise skipEmail;
   end;
   rca13_email.send_email(
           p_from_email    => fromEmail,
           p_from_replyto  => NULL,
           p_to_list       => toEmail,
           p_cc_list       => '',
           p_bcc_list      => bccList,
           p_subject       => subject,
           p_text_message  => messageText,
           p_content_type  => 'text/html;charset=UTF8',
           p_attachments   => v_attachments,
           p_priority      => '3',
           p_auth_username => '',
           p_auth_password => '',
           p_mail_server   => serverName,
           p_port          => portNum );
           
        insert into rca13_email_sent(EMAIL_SENT_ID, USER_ID, EMAIL_ADDRESS, SENT_DATE, MESSAGE_TEXT)
        values (SYS_GUID(),userId, substr(nvl(toEmail,bccList),1,3900), sysdate, messageText);
        commit;
    exception
     when skipEmail then null;
    when others then
     errorStack := substr(DBMS_UTILITY.FORMAT_ERROR_STACK || ' ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,1,4000);
     if (errorStack like '%is not an active email address in the system%') then
       logError (emailAddress => nvl(toEmail,bccList),subject => subject,messageText => messageText,errorText => errorStack);
       commit;
       NULL;
     else
       logError (emailAddress => nvl(toEmail,bccList),subject => subject,messageText => messageText,errorText => errorStack);
       commit;
     end if;      
end;
--------------------------------------------------------------------------------    
END RCA13_EMAIL;
/


--Manage Notifications
create or replace PACKAGE RCA13_MANAGE_NOTIFICATIONS AS
 procedure startEmailJob;
 procedure sendNotifications(jobId varchar2);
 function get_restriction_predicate(userId varchar2) return number;
 procedure getDiff(jobId varchar2 );
 procedure jobintervalconfiguration(ivl number,freq varchar2);
procedure purgejobintervalconfiguration(ivl number,freq varchar2);
END RCA13_MANAGE_NOTIFICATIONS;

/
    
create or replace PACKAGE BODY RCA13_MANAGE_NOTIFICATIONS AS
--------------------------------------------------------------------------------
PROCEDURE trace_log(text  VARCHAR2)
IS
BEGIN
  INSERT INTO RCA13_EXCEPTION_LOG(TEXT) VALUES (text);
  COMMIT;
END;
-- This job gets executed for every 4hrs
procedure startEmailJob is
previousEndTime date;
previousJobId varchar2(40);
previousEndCdate timestamp;
currentCdate timestamp;
jobId varchar2(40) := sys_guid();
cnt number := 0;
lobId varchar2(40);
newsystem number := 0;
curcolname varchar2(400);
diffflag varchar2(40);
begin
--Delete old diff details. It is just temp table
delete from rca13_collections_diff;
commit;
--For the first time the job runs just insert latest value in tables and exit.
select count(*) into cnt from rca13_notification_jobs;
if cnt = 0 then
 insert into rca13_notification_jobs(job_id,start_time,end_time) values(jobId,sysdate,sysdate);
 --Write code to insert values in details table
 for rec in ( select distinct system_id sId from rca13_col2sys_mapping where system_id != 'SAMPLE_SYSTEM' ) loop
  select  max(collection_date) into currentCdate from rca13_col2sys_mapping where system_id = rec.sId;
  insert into rca13_notification_job_details(job_id,system_id,start_cdate,end_cdate)
  values(jobId,rec.sId,currentCdate,currentCdate);
 end loop;
 commit;
end if;
--GET THE LAST END TIME FOR A COMPLETED JOB
select max(end_time) into previousEndTime from rca13_notification_jobs where end_time is not null;
--select job_id into previousJobId from rca13_notification_jobs where end_time = previousEndTime;
insert into rca13_notification_jobs(job_id,start_time) values(jobId,sysdate);
commit;
-- Go through each system of each business unit
for rec in ( select distinct system_id sId from rca13_col2sys_mapping where system_id != 'SAMPLE_SYSTEM'  ) loop         
   --Get previous end collection date for this system
    previousEndCdate := null;
    for rec1 in ( select end_cdate from rca13_notification_job_details
                  where system_id = rec.sId order by end_cdate desc ) loop
      previousEndCdate := rec1.end_cdate;
      exit;
    end loop;   
    diffflag := 1999;
    if previousEndCdate is null then --Means, New system added recently
      select  min(collection_date) into previousEndCdate from rca13_col2sys_mapping where system_id = rec.sId;        
    select count(*) into newsystem from rca13_col2sys_mapping where system_id = rec.sId;
    if (newsystem = 1) then
    select collection_name into curcolname from rca13_col2sys_mapping where system_id = rec.sId;
    select diff_type into diffflag from rca13_diff_info where cur_col_name=curcolname;
    end if;
       end if;
    
   -- Get latest collection date for the system
   select  max(collection_date) into currentCdate from rca13_col2sys_mapping where system_id = rec.sId;
   -- Insert row into details table
   if (previousEndCdate != currentCdate or diffflag=0) then -- Means no collections inserted after last job run
     insert into rca13_notification_job_details(job_id,system_id,start_cdate,end_cdate)
     values(jobId,rec.sId,previousEndCdate,currentCdate);
   end if;  
end loop;
commit;
RCA13_MANAGE_NOTIFICATIONS.getDiff(jobId);
RCA13_MANAGE_NOTIFICATIONS.sendNotifications(jobId);
--Update end time
update rca13_notification_jobs set end_time = sysdate where job_id = jobId;
commit;
exception when others then
 trace_log('startEmailJobException'||SQLCODE||SQLERRM);
end;
--------------------------------------------------------------------------------
procedure getDiff ( jobId varchar2 ) is
--messageText clob := NULL;
messageTextNew clob := NULL;
messageTextPass clob := NULL;
messageTextWarn clob := NULL;
messageTextFail clob := NULL;
lobName varchar2(256);
lobId varchar2(40);
sysName varchar2(256);
diffId varchar2(40);
diffType number;
prevColName varchar2(256);
curCcolName varchar2(256);
urlName varchar2(1000);
appId number;
link varchar2(1000);
newsystem number := 0;
curcolname varchar2(400);
diffflag varchar2(40);
begin
begin
  select url,app_id into urlName,appId from rca13_apex_details where rownum = 1;
  exception when others then null;
end;
 trace_log('getdiff');
  trace_log('jobId'||jobId);
for rec in ( select system_id,start_cdate,end_cdate from rca13_notification_job_details where job_id = jobId ) loop
  --messageText := NULL;
messageTextNew  := NULL;
messageTextPass := NULL;
messageTextWarn := NULL;
messageTextFail := NULL;
  select b.lob_name,b.lob_id into lobName,lobId from rca13_lob2sys_mapping a,rca13_lobs b
  where a.system_id = rec.system_id and a.lob_id = b.lob_id;
  select system_name into sysName from rca13_systems where system_id = rec.system_id;
  ---START: Mail notification construction for the new collecitons without comparisons
 diffflag := 1999;
    select count(*) into newsystem from rca13_col2sys_mapping where system_id = rec.system_id;
    if (newsystem=1) then
    select collection_name into curcolname from rca13_col2sys_mapping where system_id = rec.system_id;
    select diff_type into diffflag from rca13_diff_info where cur_col_name=curcolname;
    end if;
    
  for rec2 in ( select collection_date cd,collection_name cn from rca13_col2sys_mapping where system_id = rec.system_id and collection_date >= rec.start_cdate
                and collection_date <= rec.end_cdate and diffflag=0 order by collection_date ) loop
   begin
     messageTextNew  := NULL;       
      diffId := rca13_manage_collections.hasDiffWithPrevRun(rec2.cn,rec2.cd);
      select diff_type,prev_col_name,cur_col_name into diffType,prevColName,curCcolName from rca13_diff_info where diff_id = diffId;
       trace_log('I dont have difference'||diffId);
      if urlName is not null and appId is not null then
       link := '<a href="'||urlName||'f?p='||appId||':1003:::NO:1003:P1003_DIFF_ID:'||diffId||'">Click here</a> for details';
     else
       link := 'View CM App for details';
    end if;
     trace_log('messageTextNewCollections');
      messageTextNew := messageTextNew || '<tr><td>'||lobName||'</td><td>'||sysName||'</td><td>';
      messageTextNew := messageTextNew || prevColName||'</td><td>'||curCcolName||'</td><td>New Collections Without Comparisons</td><td>'||link||'</td></tr>';
   insert into rca13_collections_diff(job_id,lob_id,lob_name,system_id,system_name,diff,diff_type)
   values(jobId,lobId,lobName,rec.system_id,sysName,messageTextNew,'0');
  commit;   
      exception when others then
    trace_log('DiffComputationNewsystemException'||SQLCODE||SQLERRM);
      end;
    end loop;
---END: Mail notification construction for the new collections without comparisons
  -- 3 ==> Red flag
   -- diff_types:
 --0:NEW = prev col not found for the selected collection,
 --2:GOOD = diff found..but good( that is fail to pass, only region 1 ),Green,
 --3:FAIL = diff found, but bad ( some thing from good to fail, only region 1 ),Red
 --4:WARN = diff found, Orange ( some thing from good to warning )
  for rec1 in ( select collection_date cd,collection_name cn from rca13_col2sys_mapping where system_id = rec.system_id and collection_date > rec.start_cdate
                and collection_date <= rec.end_cdate order by collection_date ) loop
   begin      
     diffId := rca13_manage_collections.hasDiffWithPrevRun(rec1.cn,rec1.cd);
     select diff_type,prev_col_name,cur_col_name into diffType,prevColName,curCcolName from rca13_diff_info where diff_id = diffId;
messageTextPass := NULL;
messageTextWarn := NULL;
messageTextFail := NULL;
  trace_log('I have difference'||diffId);
    if (diffType = 0) then
      if urlName is not null and appId is not null then
        link := '<a href="'||urlName||'f?p='||appId||':1003:::NO:1003:P1003_DIFF_ID:'||diffId||'">Click here</a> for details';
      else
        link := 'View CM App for details';
      end if;
      messageTextNew := messageTextNew || '<tr><td>'||lobName||'</td><td>'||sysName||'</td><td>';
      messageTextNew := messageTextNew || prevColName||'</td><td>'||curCcolName||'</td><td>New Collections Without Comparisons</td><td>'||link||'</td></tr>';
    end if;
    
    if (diffType = 2) then
      if urlName is not null and appId is not null then
        link := '<a href="'||urlName||'f?p='||appId||':1003:::NO:1003:P1003_DIFF_ID:'||diffId||'">Click here</a> for details';
      else
        link := 'View CM App for details';
      end if;
       trace_log('messageTextPass');
      messageTextPass := messageTextPass || '<tr><td>'||lobName||'</td><td>'||sysName||'</td><td>';
      messageTextPass := messageTextPass || prevColName||'</td><td>'||curCcolName||'</td><td>Collections that Improved with Passes</td><td>'||link||'</td></tr>';
    end if;
    
    if (diffType = 4) then
      if urlName is not null and appId is not null then
        link := '<a href="'||urlName||'f?p='||appId||':1003:::NO:1003:P1003_DIFF_ID:'||diffId||'">Click here</a> for details';
      else
        link := 'View CM App for details';
      end if;
         trace_log('messageTextWarn');
      messageTextWarn := messageTextWarn || '<tr><td>'||lobName||'</td><td>'||sysName||'</td><td>';
      messageTextWarn := messageTextWarn || prevColName||'</td><td>'||curCcolName||'</td><td>Collections Regressed with Warnings</td><td>'||link||'</td></tr>';
    end if;
    
    if (diffType = 3) then
      if urlName is not null and appId is not null then
        link := '<a href="'||urlName||'f?p='||appId||':1003:::NO:1003:P1003_DIFF_ID:'||diffId||'">Click here</a> for details';
      else
        link := 'View CM App for details';
      end if;
       trace_log('messageTextFail');
      messageTextFail := messageTextFail || '<tr><td>'||lobName||'</td><td>'||sysName||'</td><td>';
      messageTextFail := messageTextFail || prevColName||'</td><td>'||curCcolName||'</td><td>Collections Regressed with Failures</td><td>'||link||'</td></tr>';
    end if;
    if messageTextNew is not null then
   insert into rca13_collections_diff(job_id,lob_id,lob_name,system_id,system_name,diff,diff_type)
   values(jobId,lobId,lobName,rec.system_id,sysName,messageTextNew,to_char(diffType));
  end if;
  commit;
  if messageTextPass is not null then
   insert into rca13_collections_diff(job_id,lob_id,lob_name,system_id,system_name,diff,diff_type)
   values(jobId,lobId,lobName,rec.system_id,sysName,messageTextPass,to_char(diffType));
  end if;
  commit;
  if messageTextWarn is not null then
   insert into rca13_collections_diff(job_id,lob_id,lob_name,system_id,system_name,diff,diff_type)
   values(jobId,lobId,lobName,rec.system_id,sysName,messageTextWarn,to_char(diffType));
  end if;
  commit;
  if messageTextFail is not null then
   insert into rca13_collections_diff(job_id,lob_id,lob_name,system_id,system_name,diff,diff_type)
   values(jobId,lobId,lobName,rec.system_id,sysName,messageTextFail,to_char(diffType));
  end if;
  commit;  
    exception when others then
    trace_log('DiffComputationException'||SQLCODE||SQLERRM);
   end;
  end loop;  
end loop;
end;
--------------------------------------------------------------------------------
procedure sendNotifications ( jobId varchar2 ) is
messageText clob := NULL;
rVal number := 1;
flag number := 0;
messageHeader clob := NULL;
messagespacecrunch clob := NULL;
messageFooter clob := NULL;
spaceflag  number := 0;
tsName varchar2(256);
freeSpace number := 999;
talert varchar2(50);
begin
 messageHeader := '
 <html><head>
 <style>
  table {    
    font-weight: bold;
    border-spacing: 0;
    outline: medium none;
    font-family: Lucida Grande,Lucida Sans,Arial,sans-serif;
    font-size: 12px;
  }
  th {
    background-image: linear-gradient(#F0F0F0, #DDDDDD);
    border-radius: 3px 3px 0 0;
    height: 30px;
    border-collapse: collapse;
    border-spacing: 0
    border-bottom: 1px solid #AAAAAA;
  }
  td {   
    font-weight: normal;
    padding: 5;
    border-collapse: collapse;
    border-spacing: 0;
    border-bottom: 1px solid #AAAAAA;
  }
 </style>
 </head><body>
 <h4>Found Diff for the following collections</h4>
 <table><thead><tr><th>BU Name</th><th>System Name</th><th>Previous Collection</th>
 <th>Current Collection</th><th>Collection DifferenceType</th><th>Comments</th><tr></thead><tbody>
 ';
 messageFooter := '</tbody></table></body></html>';
 --For each user we need to get the list of systems that he has access to and send that info only
 trace_log('sendnotificationsstart');
 for rec in ( select user_id,email_address mId,nvl(emailalert,999) emailalert from rca13_user_details where IS_NOTIFIED = 1 and email_address is not null) loop
  begin
   trace_log('user_id::'||rec.user_id||'mail_id::'||rec.mId);
    trace_log('emailalert::'||rec.emailalert);
   flag := 0;
   rVal := RCA13_MANAGE_NOTIFICATIONS.get_restriction_predicate(rec.user_id);   
   messageText := NULL;  
   for rec1  in ( select diff,diff_type from rca13_collections_diff where job_id = jobId and
                  (lob_id,system_id) in (
                  select lob_id,system_id from rca13_lob2sys_mapping where rVal = 1 and rca13_lob2sys_mapping.lob_id != 'SAMPLE'
                  UNION
                  select lob_id lId,system_id sId from rca13_lob2sys_mapping where rVal = 3 and exists ( select 1 from rca13_user_roles  
                  where user_id = rec.user_id and rca13_lob2sys_mapping.lob_id != 'SAMPLE' and  ( role_id = 1  OR  
                  ( role_id = 2 and lob_id = rca13_lob2sys_mapping.lob_id  ) OR
                  ( lob_id = rca13_lob2sys_mapping.lob_id and system_id = rca13_lob2sys_mapping.system_id ) ) ) )  
                  order by decode(diff_type,'3',1,'4',2,'2',3,'0',4),lob_name,system_name ) loop
     --Construct messageText.
      trace_log('I have access to system ondifftype::'||rec1.diff_type);
    if (rec1.diff_type = 0 and instr(rec.emailalert,'0') > 0) then
     messageText := messageText || rec1.diff;    
     flag := 1;
     end if;
      if (rec1.diff_type = 2 and instr(rec.emailalert,'2') > 0) then
     messageText := messageText || rec1.diff;    
     flag := 1;
     end if;
      if (rec1.diff_type = 3 and instr(rec.emailalert,'3') > 0) then
     messageText := messageText || rec1.diff;    
     flag := 1;
     end if;
      if (rec1.diff_type = 4 and instr(rec.emailalert,'4') > 0) then
     messageText := messageText || rec1.diff;    
     flag := 1;
     end if;
   end loop;
   begin
  
    SELECT nvl(tablespace_name,'XXX') into tsName from user_tables where table_name = 'RCA13_DOCS';
    trace_log('tablespace_name'||tsName);
    SELECT round(sum(bytes)/1048576) into freeSpace FROM user_free_space  where tablespace_name = tsName;
    trace_log('freeSpace'||freeSpace);
    SELECT nvl(tablespacealert,'0') into talert FROM rca13_user_details  where IS_NOTIFIED = 1 and email_address is not null and user_id=rec.user_id;
    trace_log('tablespacealertflag'||talert);  
    if (freeSpace < 500) then
    spaceflag := 1;
     messagespacecrunch := ' <html><h4>The ORAchk CM tablespace has  '||freeSpace||'MB of free space remaining. Each collection processed can consume a minimum 20MB - 100MB . <br> Check your Autoextensible enabled in dba_data_files table. If all free space is consumed, problems processing collections can occur. </h4></html>';
    else
     messagespacecrunch := NULL;      
    end if;
     exception when others then
 trace_log('TablespaceException'||SQLCODE||SQLERRM);
    end;
     
   if (flag = 1 and spaceflag = 1 and instr(talert,'1') > 0) then      
    messageText := messagespacecrunch ||messageHeader || messageText || messageFooter;
     rca13_email.send(rec.mId,rec.mId,'From CM Notification System','Collection Manager Notifications : Space in DB reached < 500MB Check your Autoextensible Enabled in dba_data_files table',messageText);
   elsif flag = 1 then
    trace_log('sendnotificationsconstructedmail');
     messageText := messageHeader || messageText || messageFooter;
     rca13_email.send(rec.mId,rec.mId,'From CM Notification System','Collection Manager Notifications',messageText);
   end if;  
  exception when others then
 trace_log('sendnotificationsaccessException'||SQLCODE||SQLERRM);
  end;
 end loop;
exception when others then
trace_log('sendnotificationsuserdetailsException'||SQLCODE||SQLERRM);
null;
end;
--------------------------------------------------------------------------------
FUNCTION get_restriction_predicate ( userId varchar2 ) RETURN number AS
cnt number := 0;
hasRole number := 0;
hasData number := 0;
vpdString varchar2(4000);
BEGIN
--Is user has atleast one role other than to SAMPLE data
select count(1) into hasRole from rca13_user_roles where user_id = userId and lob_id != 'SAMPLE';
--check whther there is non sample data
select count(1) into hasData from rca13_collections_md;
--If ACL system is not enabled then don't apply any security/vpd on data
select count(1) into cnt from rca13_intrack_preferences where preference_name = 'ACCESS_CONTROL_ENABLED' and preference_value = 'N';
if cnt > 0 then  
  if hasData > 2 then --display whole data other than sample( 2 rows for sample data )
   --return  '  rca13_lob2sys_mapping.lob_id != ''SAMPLE'' ';
   return 1;
  else  
   --return ' 1 = 1 ';
   return 2;
  end if;
end if;
--Check whether user has access to atleast one unit or not other than SAMPLE unit
--After first log in to app, user will become dba_manager to SAMPLE unit.
--By default we insert some SAMPLE data ( and hence systems which map to SAMPLE unit ) into app
if hasRole > 0 and hasData > 2 then --Exclude SAMPLE data
  vpdString :=
  '  exists ( select 1 from rca13_user_roles  where user_id = '''||userId||''' and rca13_lob2sys_mapping.lob_id != ''SAMPLE'' '||
  ' and  ( role_id = 1  OR  '||
  '  ( role_id = 2 and lob_id = rca13_lob2sys_mapping.lob_id  ) OR '||
  '  ( lob_id = rca13_lob2sys_mapping.lob_id and system_id = rca13_lob2sys_mapping.system_id ) ) ) ';
  return 3;
else --Which display only sample data
  vpdString :=
  '  exists ( select 1 from rca13_user_roles  where user_id = '''||userId||'''  and  ( role_id = 1  OR  '||
  '  ( role_id = 2 and lob_id = rca13_lob2sys_mapping.lob_id  ) OR '||
  '  ( lob_id = rca13_lob2sys_mapping.lob_id and system_id = rca13_lob2sys_mapping.system_id ) ) ) ';
  return 4;
end if;  
--RETURN vpdString;
return 1;
END;
--------------------------------------------------------------------------------
procedure jobintervalconfiguration(ivl number,freq varchar2) is
interval varchar2(5);
l_job_exists number := 0;
l_job_running number := 0;
frequency varchar2(15);
BEGIN
select count(1) into l_job_exists from user_scheduler_jobs where job_name = 'RCA13_NOTIFICATIONS_JOB';
  trace_log('Interval::'||ivl||'frequency::'||freq);  
   select decode(freq,'HOURS','hourly','DAYS','daily',freq) into frequency from dual;
   select count(*) into l_job_running
     from user_scheduler_running_jobs
    where job_name = 'RCA13_NOTIFICATIONS_JOB';
   if (l_job_running = 1) then   
      begin
      dbms_scheduler.stop_job('RCA13_NOTIFICATIONS_JOB');
      exception when others then
        trace_log('Stop NotificationJob Exception'||SQLCODE||SQLERRM);
      end;
    end if;
    if(l_job_exists = 1 ) then
      begin
      dbms_scheduler.drop_job('RCA13_NOTIFICATIONS_JOB');
       exception when others then
       trace_log('Drop NotificationJob Exception'||SQLCODE||SQLERRM);
      end;
    end if;
     begin
    DBMS_SCHEDULER.CREATE_JOB (
     job_name           => 'RCA13_NOTIFICATIONS_JOB',
     job_type           => 'PLSQL_BLOCK',
     job_action         => 'BEGIN rca13_manage_notifications.startEmailJob(); END;',
     start_date         =>   systimestamp,
     repeat_interval    => 'freq='||trim(frequency)||'; interval='||trim(ivl)||'; byminute=0; bysecond=0;', /*For every 4 hours */
     end_date           =>   NULL,
     enabled            =>   TRUE,
     auto_drop          =>   FALSE,
     comments           =>  'ORAchk App:Email Notification system');
     DBMS_SCHEDULER.enable ('RCA13_NOTIFICATIONS_JOB');
     exception when others then
     trace_log('Create Job Notification Exception'||SQLCODE||SQLERRM);
      end;
trace_log('Success JobInterval');
exception when others then
trace_log('JobIntervalException'||SQLCODE||SQLERRM);
END;
--------------------------------------------------------------------------------
procedure purgejobintervalconfiguration(ivl number,freq varchar2) is
interval varchar2(5);
l_job_exists number := 0;
l_job_running number := 0;
interval_value number := 0;
frequency varchar2(15);
conf_date date;
conf number := 0;
BEGIN
select count(1) into l_job_exists from user_scheduler_jobs where job_name = 'RCA13_PURGE_JOB';
select preference_value into interval_value from rca13_intrack_preferences where preference_name = 'PURGE_JOB_INTERVAL';
  trace_log('Interval::'||ivl||'frequency::'||freq);  
   select decode(freq,'HOURS','hourly','DAYS','daily','WEEKLY','weekly','MONTHLY','monthly',freq) into frequency from dual;
   select decode(freq,'DAYS',ivl*1,'WEEKLY',ivl*7,'MONTHLY',ivl*30,'YEARLY',ivl*365,freq) into conf from dual;
   --select sysdate-conf into conf_date from dual;
   update rca13_intrack_preferences set preference_value = ivl,preference_description=freq where preference_name='PURGE_JOB_INTERVAL';
   select count(*) into l_job_running
     from user_scheduler_running_jobs
    where job_name = 'RCA13_PURGE_JOB';
   if (l_job_running = 1) then   
      begin
      dbms_scheduler.stop_job('RCA13_PURGE_JOB');
      exception when others then
        trace_log('Stop PurgeJob Exception'||SQLCODE||SQLERRM);
      end;
    end if;
    if(l_job_exists = 1 ) then
      begin
      dbms_scheduler.drop_job('RCA13_PURGE_JOB');
       exception when others then
       trace_log('Drop PurgeJob Exception'||SQLCODE||SQLERRM);
      end;
    end if;
     begin
    DBMS_SCHEDULER.CREATE_JOB (
     job_name           => 'RCA13_PURGE_JOB',
     job_type           => 'PLSQL_BLOCK',
   --job_action         => 'BEGIN RCA13_MANAGE_COLLECTIONS.purgeData(dat => to_timestamp('''||conf_date||''',''DD-MON-RR HH.MI.SS.FF AM'')); END;',
     job_action         => 'BEGIN RCA13_MANAGE_COLLECTIONS.purgeData(dat => systimestamp - '||conf||'); END;', -- clean data on every day basis
     start_date         =>  systimestamp,     
     --repeat_interval    => 'freq='||trim(frequency)||'; interval='||trim(ivl)||'; byminute=0; bysecond=0;', /*For every submitted hours (rca13_intrack_preferences) */
     repeat_interval    => 'freq=daily; interval=1; byminute=0; bysecond=0;', /*daily job to preserve only the recent <interval> data in the database */
     end_date           =>   NULL,
     enabled            =>   TRUE,
     auto_drop          =>   FALSE,
     comments           =>  'Purge Data Older than '||conf_date);
     DBMS_SCHEDULER.enable ('RCA13_PURGE_JOB');
     exception when others then
     trace_log('Create Job Purge Exception'||SQLCODE||SQLERRM);
      end;
trace_log('Success PurgeJobInterval');
exception when others then
trace_log('PurgeJobIntervalException'||SQLCODE||SQLERRM);
END;
--------------------------------------------------------------------------------
END RCA13_MANAGE_NOTIFICATIONS;


/
--RCA13_INCIDENT_INTEGRATION
create or replace PACKAGE RCA13_INCIDENT_INTEGRATION AS 
  procedure addInfo2ITC ( acsTicketId varchar2 );
  procedure addLink2ITC( acsTicketId varchar2 );
  procedure update_collection_score(TicketId varchar2,flag number default 0 );
END RCA13_INCIDENT_INTEGRATION;
/

create or replace PACKAGE BODY RCA13_INCIDENT_INTEGRATION AS
--------------------------------------------------------------------------------
--ITC insident tracking system. acs - audit check sytem
procedure addInfo2ITC ( acsTicketId varchar2 ) is
addType varchar2(40);
attr1 varchar2(40);
ticketId varchar2(100);
text clob;
noTicket exception;

begin 
  
  begin
   select ticket_id,type,attr1 into ticketId,addType,attr1 from RCA13_AC_TICKETS 
   where acs_ticket_id = acsTicketId;  
   exception when no_data_found then raise noTicket;
  end; 
 
 if addType = 'CHECK' and attr1 is not null  then   
   for rec in ( select * from auditcheck_result where auditcheck_result_id = attr1 ) loop     
     text := 'Cluster Name: '||rec.CLUSTER_NAME||chr(10);
     text := text||'Collection Name: '||rec.UPLOAD_COLLECTION_NAME||chr(10);
     text := text||'Collection Date: '||rec.COLLECTION_DATE||chr(10);   
     text := text||'Check Name: '||nvl(rec.CHECK_NAME,rec.PARAM_NAME)||chr(10);
     text := text||'Check Status: '||rec.STATUS||chr(10);
     text := text||'Status Message: '||rec.STATUS_MESSAGE||chr(10);
     text := text||'Actuall Message: '||rec.ACTUAL_VALUE||chr(10);
     text := text||'Recommended Value: '||rec.RECOMMENDED_VALUE||chr(10);
     text := text||'Operator: '||rec.COMPARISON_OPERATOR||chr(10);
     text := text||'Host Name: '||rec.HOSTNAME||chr(10);
     text := text||'Instance Name: '||rec.INSTANCE_NAME||chr(10);
     text := text||'Check Type: '||rec.CHECK_TYPE||chr(10);
     text := text||'OS Platform: '||rec.DB_PLATFORM||chr(10);
     text := text||'DB version: '||rec.DB_VERSION||chr(10);
     text := text||'DB Name: '||rec.DB_NAME||chr(10);
     text := text||'DB Role: '||rec.DATABASE_ROLE||chr(10);
     text := text||'CRS Version: '||rec.CLUSTERWARE_VERSION||chr(10);
   end loop;
 elsif addType = 'COLLECTION' then 
   if attr1 is not null then   
     for rec in ( select * from rca13_collections where collection_id = attr1 ) loop
       text := 'Collection Name: '||rec.COLLECTION_NAME||chr(10);
       text := text||'Collection Date: '||rec.COLLECTION_DATE||chr(10);
       text := text||'OS Platform: '||rec.OS_PLATFORM||chr(10);    
       text := text||'OS Distribution: '||rec.OS_DIST||chr(10);        
       text := text||'OS Kernel: '||rec.OS_KERNEL||chr(10);      
       text := text||'OS Version: '||rec.OS_VERSION||chr(10);     
       text := text||'Collection Type: '||rec.COLLECTION_TYPE||chr(10);
       text := text||'System Name: '||rec.SYSTEM_NAME||chr(10);    
     end loop;
   else 
     text := 'Collection zip not found';
   end if;
 end if;
 if text is not null then
   insert into RCA13_INTRACK_NOTES (INCIDENT_ID, note) values (ticketId, text);
   commit;
 end if; 
 exception when noTicket then null;
end; 
--------------------------------------------------------------------------------
procedure addLink2ITC( acsTicketId varchar2) is 
addType varchar2(40);
attr1 varchar2(40);
ticketId varchar2(100);
text clob;
noTicket exception;
cDate timestamp;
begin
  begin
   select ticket_id,type,attr1 into ticketId,addType,attr1 from RCA13_AC_TICKETS 
   where acs_ticket_id = acsTicketId;
  exception when no_data_found then raise noTicket;
  end; 
  if addType = 'CHECK' then    
    --Get collection Date .. attr1 is either collectionId or auditcheck result Id
    select collection_date into cDate from auditcheck_result where auditcheck_result_id = attr1;
  elsif addType = 'COLLECTION' then  
    select collection_date into cDate from RCA13_AC_TICKETS where acs_ticket_id = acsTicketId;
  end if;    
  insert into RCA13_INTRACK_LINKS (INCIDENT_ID, LINK_TEXT, link_target, LINK_COMMENTS) 
  values (ticketId,'Link to collection','f?p=&APP_ID.:1002:&APP_SESSION.:::1002:P1002_COLLECTION_DATE:'||cDate,'Link to collection');
  exception when noTicket then null;
end;
--------------------------------------------------------------------------------
--When a ticket is closed on collection/check update the score of the collection
procedure update_collection_score ( ticketId varchar2,flag number default 0 ) is 
newScore number;
cName varchar2(40);
cDate timestamp;
acResultId varchar2(40);
tType varchar2(100);
attr1 varchar2(40);
collectionId varchar2(40);
PRAGMA AUTONOMOUS_TRANSACTION;
begin
 for rec in ( select type,attr1,collection_date,collection_name from RCA13_AC_TICKETS where ticket_id = ticketId ) loop
   tType := rec.type;
   if tType = 'CHECK' then 
     attr1 := rec.attr1;
   else 
     collectionId := rec.attr1;
   end if;
   cDate := rec.collection_date;
   cName := rec.collection_name;
   exit;
 end loop;
 if tType = 'CHECK' then 
  select collection_id,upload_collection_name,collection_date into collectionId,cName,cDate 
  from auditcheck_result where auditcheck_result_id = attr1; 
 end if;
 if cDate is null then
   return;
 end if;
   newScore := RCA13_GET_DATA4COLUMNS.getCollectionScore(collectionId,cName,cDate,flag);
  update rca13_collection_values set score = newScore where collection_date  = cDate and collection_name = cName;
 commit;
 exception when others then null;
end;
--------------------------------------------------------------------------------
END RCA13_INCIDENT_INTEGRATION;
/
--Incidents trigger
create or replace trigger rca13_intrack_incidents_trg
before insert or update on rca13_intrack_incidents
for each row
begin
   if :new.tags is not null then
      :new.tags := rca13_intrack_fw.tags_cleaner(:new.tags);
   end if;
   if inserting then
      if :NEW.ID is null then
         select to_number(sys_guid(),'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX')
           into :NEW.ID
           from dual;
      end if;
      if :new.CREATED is null then
           :NEW.CREATED := localtimestamp;
      end if;
      :NEW.CREATED_BY := nvl(v('APP_USER'),USER);
      :new.row_version_number := 1;
   end if;
   --
   if inserting or updating then
      :NEW.UPDATED    := localtimestamp;
      :NEW.UPDATED_BY := nvl(v('APP_USER'),USER);
   end if;
   if updating then
      :new.row_version_number := nvl(:old.row_version_number,1) + 1;
   end if;
   if :new.incident_number is null then
       for c1 in (select rca13_intrack_seq.nextval s from dual) loop
           :new.incident_number := rca13_intrack_fw.compress_int(c1.s);
       end loop;
   end if;
   if :new.severity_id is null then
      for c1 in (select id from rca13_intrack_severity order by sequence_number desc) loop
          :new.severity_id := c1.id;
          exit;
      end loop;
   end if;
   if nvl(:new.status_id,0) != nvl(:old.status_id,0) then
       for c2 in (select status_code from rca13_intrack_status where id = :new.status_id) loop
           :new.status_code := c2.status_code;
       end loop;
   end if;
       --
   if updating then
         if :new.status_id is not null then
          for c3 in (select STATUS_TYPE from RCA13_INTRACK_STATUS where id = :new.status_id ) loop
                  if c3.STATUS_TYPE = 'CLOSED' then
                      :new.DATE_CLOSED := localtimestamp;
                      RCA13_INCIDENT_INTEGRATION.update_collection_score(:NEW.ID,1);
                  elsif c3.STATUS_TYPE = 'OPEN' then
                      :new.DATE_CLOSED := null;
                  end if;
          end loop;
       end if;
       
       if :new.DATE_CLOSED is not null and :old.date_closed is null then
          insert into rca13_intrack_inc_followup
            (incident_id,follow_up_type,status_column,status_old_val,status_new_val )
            values
            (:new.id, 'CLOSE_DATE_CHANGE', 'DATE_CLOSED', null, 'Date closed automatically set');
       end if;
       if :new.DATE_CLOSED is  null and :old.date_closed is not null then
          insert into rca13_intrack_inc_followup
            (incident_id,follow_up_type,status_column,status_old_val,status_new_val )
            values
            (:new.id, 'CLOSE_DATE_CHANGE', 'DATE_CLOSED', 'Date closed automatically unset', null);
       end if;
       --
       if nvl(:new.status_code,'x') != nvl(:old.status_code,'x') then
          insert into rca13_intrack_inc_followup
            (incident_id,follow_up_type,status_column,status_old_val,status_new_val )
            values
            (:new.id, 'STATUS_CHANGE', 'STATUS_CODE', :old.status_id, :new.status_id);
       end if;
       if nvl(:new.ASSIGNED_TO_ID,0) != nvl(:old.ASSIGNED_TO_ID,0) then
            insert into rca13_intrack_inc_followup
            (incident_id,follow_up_type,status_column,status_old_val,status_new_val )
            values
            (:new.id, 'ASSIGNEE_CHANGE', 'ASSIGNED_TO_ID', :old.ASSIGNED_TO_ID, :new.ASSIGNED_TO_ID);
            :new.ASSIGNED_ON := systimestamp; 
       end if;
       if nvl(:new.URGENCY_ID,0) != nvl(:old.URGENCY_ID,0) then
            insert into rca13_intrack_inc_followup
            (incident_id,follow_up_type,status_column,status_old_val,status_new_val )
            values
            (:new.id, 'URGENCY_CHANGE', 'URGENCY_ID', :old.URGENCY_ID, :new.URGENCY_ID);
       end if;
       if nvl(:new.SEVERITY_ID,0) != nvl(:old.SEVERITY_ID,0) then
            insert into rca13_intrack_inc_followup
            (incident_id,follow_up_type,status_column,status_old_val,status_new_val )
            values
            (:new.id, 'SEVERITY_CHANGE', 'SEVERITY_ID', :old.SEVERITY_ID, :new.SEVERITY_ID);
       end if;
       if nvl(:new.CATEGORY_ID,0) != nvl(:old.CATEGORY_ID,0) then
            insert into rca13_intrack_inc_followup
            (incident_id,follow_up_type,status_column,status_old_val,status_new_val )
            values
            (:new.id, 'CATEGORY_CHANGE', 'CATEGORY_ID', :old.CATEGORY_ID, :new.CATEGORY_ID);
       end if;
       if nvl(:new.TAGS,'0') != nvl(:old.TAGS,'0') then
            insert into rca13_intrack_inc_followup
            (incident_id,follow_up_type,status_column,status_old_val,status_new_val )
            values
            (:new.id, 'TAG_CHANGE', 'TAGS', :old.TAGS, :new.TAGS);
       end if;
       if nvl(:new.PRODUCT_ID,0) != nvl(:old.PRODUCT_ID,0) then
            insert into rca13_intrack_inc_followup
            (incident_id,follow_up_type,status_column,status_old_val,status_new_val )
            values
            (:new.id, 'PRODUCT_CHANGE', 'PRODUCT_ID', :old.PRODUCT_ID, :new.PRODUCT_ID);
       end if;
       if nvl(:new.CUSTOMER_ID,0) != nvl(:old.CUSTOMER_ID,0) then
            insert into rca13_intrack_inc_followup
            (incident_id,follow_up_type,status_column,status_old_val,status_new_val )
            values
            (:new.id, 'CUSTOMER_CHANGE', 'CUSTOMER_ID', :old.CUSTOMER_ID, :new.CUSTOMER_ID);
       end if;
       if nvl(:new.PRODUCT_VERSION_ID,0) != nvl(:old.PRODUCT_VERSION_ID,0) then
            insert into rca13_intrack_inc_followup
            (incident_id,follow_up_type,status_column,status_old_val,status_new_val )
            values
            (:new.id, 'PRODUCT_VERSION_CHANGE', 'PRODUCT_VERSION_ID', :old.PRODUCT_VERSION_ID, :new.PRODUCT_VERSION_ID);
       end if;
       if nvl(:new.SUBJECT,'0') != nvl(:old.SUBJECT,'0') then
            insert into rca13_intrack_inc_followup
            (incident_id,follow_up_type,status_column,status_old_val,status_new_val )
            values
            (:new.id, 'SUBJECT_CHANGE', 'SUBJECT', :old.SUBJECT, :new.SUBJECT);
       end if;
       if nvl(:new.BUG_NUMBER,'0') != nvl(:old.BUG_NUMBER,'0') then
            insert into rca13_intrack_inc_followup
            (incident_id,follow_up_type,status_column,status_old_val,status_new_val )
            values
            (:new.id, 'BUG_CHANGE', 'BUG_NUMBER', :old.BUG_NUMBER, :new.BUG_NUMBER);
       end if;
   end if;
   --
   rca13_intrack_fw.tag_sync(
        p_new_tags      => :new.tags,
        p_old_tags      => :old.tags,
        p_content_type  => 'INCIDENT',
        p_content_id    => :new.id );
end;
/
--Triggers
--Nothing wrong in running this trigger regardless of version
create or replace TRIGGER "RCA13_DOCS_FILE_NAME"
BEFORE INSERT ON RCA13_DOCS
FOR EACH ROW
BEGIN
  :new.filename := substr(:new.filename,instr(:new.filename,'/',-1,1)+1);
END;
/
--Scheduled Jobs
declare
cnt number;
begin
for rec in ( select build_id bid from rca13_release_info order by build_id asc ) loop
  -- Upgrade app version by version
  if rec.bid = 20140530000000  then
   select count(1) into cnt from user_scheduler_jobs where job_name = 'RCA13_NOTIFICATIONS_JOB';
   if cnt = 0 then
    DBMS_SCHEDULER.CREATE_JOB (
     job_name           => 'RCA13_NOTIFICATIONS_JOB',
     job_type           => 'PLSQL_BLOCK',
     job_action         => 'BEGIN rca13_manage_notifications.startEmailJob(); END;',
     start_date         =>   systimestamp,
     repeat_interval    => 'freq=hourly; interval=4; byminute=0; bysecond=0;', /*For every 4 hours */
     end_date           =>   NULL,
     enabled            =>   TRUE,
     auto_drop          =>   FALSE,
     comments           =>  'ORAchk App:Email Notification system');
   end if;
  end if;       
 end loop;
end;
/

execute DBMS_SCHEDULER.enable ('RCA13_PROCESS_DATA');   
/
    
execute DBMS_SCHEDULER.enable ('RCA13_NOTIFICATIONS_JOB');
/



prompt ...notificationsenable
--rca13_cm_ui.css
 
begin
 
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '73656374696F6E2E754E6F48656164696E67206469762E75526567696F6E436F6E74656E74207B0D0A2020202070616464696E673A203070782021696D706F7274616E743B0D0A7D0D0A73656374696F6E2E75526567696F6E203E206469762E75526567';
wwv_flow_api.g_varchar2_table(2) := '696F6E436F6E74656E74207B0D0A2020202070616464696E673A203170782021696D706F7274616E743B0D0A7D0D0A23754F6E65436F6C2C20237554776F436F6C756D6E73207B2020200D0A202020206D617267696E3A203170782021696D706F727461';
wwv_flow_api.g_varchar2_table(3) := '6E743B0D0A7D0D0A0D0A7461626C652E666F726D6C61796F7574203E2074626F6479203E207472203E207464207B0D0A2020202070616464696E673A20307078203270783B0D0A7D0D0A0D0A7461626C652E666F726D6C61796F75742074642073656C65';
wwv_flow_api.g_varchar2_table(4) := '63742E73656C6563746C697374207B0D0A2020206D617267696E3A203270782030203270782021696D706F7274616E743B0D0A7D0D0A0D0A73656374696F6E2E75526567696F6E207B0D0A202020206D617267696E3A20302030203370782021696D706F';
wwv_flow_api.g_varchar2_table(5) := '7274616E743B200D0A7D0D0A73656374696F6E5B646174612D677269643D22636F6C5F32225D2C202E75477269642E636F6C5F32207B0D0A2020202077696474683A203530253B0D0A7D';
 
end;
/
prompt ...create_or_remove_file

declare
  l_name   varchar2(255);
begin
  l_name := 'rca13_cm_ui.css';
 
  wwv_flow_api.create_or_remove_file(
     p_name=> l_name,
     p_varchar2_table=> wwv_flow_api.g_varchar2_table,
     p_mimetype=> 'text/css',
     p_location=> 'WORKSPACE',
     p_notes=> 'Collection Manager CM',
     p_mode=> 'CREATE_OR_REPLACE',
     p_type=> 'CSS');
 
end;
/


prompt ...RCA13_ORACHK_CHK_TYPE
--Check Type For AUDIT_CHECK_NAME LIKE 'OS', 'SQL'-- Screen Display   

DELETE FROM RCA13_ORACHK_CHK_TYPE;
COMMIT;
/   
INSERT INTO RCA13_ORACHK_CHK_TYPE VALUES('OS Check','OS');
INSERT INTO RCA13_ORACHK_CHK_TYPE VALUES('SQL Check','SQL');
COMMIT;

 -- For DB types CDB,PDB,NORMAL -- Screen Display 
  declare
isdbtype number;
begin
select count(1) into isdbtype from RCA13_ORACHK_CHECKS_DB_TYPES;
if isdbtype < 1 then
DELETE FROM RCA13_ORACHK_DB_TYPES_MASTER;
COMMIT;
 
INSERT INTO RCA13_ORACHK_DB_TYPES_MASTER(DATABASE_TYPE) VALUES('CDB');
INSERT INTO RCA13_ORACHK_DB_TYPES_MASTER(DATABASE_TYPE) VALUES('PDB');
INSERT INTO RCA13_ORACHK_DB_TYPES_MASTER(DATABASE_TYPE) VALUES('NORMAL');
COMMIT;

end if;
end;
/
 -- For DB Roles PRIMARY,PHYSICAL_STANDBY,LOGICAL_STANDBY --Screen Display  
  declare
isdbrole number;
begin
select count(1) into isdbrole from RCA13_ORACHK_CHECKS_DB_ROLES;
if isdbrole < 1 then
DELETE FROM RCA13_ORACHK_DB_ROLES_MASTER;
COMMIT;

      
 INSERT INTO RCA13_ORACHK_DB_ROLES_MASTER(DATABASE_ROLE) VALUES('PRIMARY');
INSERT INTO RCA13_ORACHK_DB_ROLES_MASTER(DATABASE_ROLE) VALUES('PHYSICAL_STANDBY');
INSERT INTO RCA13_ORACHK_DB_ROLES_MASTER(DATABASE_ROLE) VALUES('LOGICAL_STANDBY');
COMMIT;
end if;
end;

/
-- For DB Mode 1 = NOMOUNT, 2 = MOUNT, 3 = OPEN --Screen Display  
declare
isdbmode number;
begin
select count(1) into isdbmode from RCA13_ORACHK_CHECKS_DB_MODES;
if isdbmode < 1 then
DELETE FROM RCA13_ORACHK_DB_MODES_MASTER;
COMMIT;


INSERT INTO RCA13_ORACHK_DB_MODES_MASTER(DATABASE_MODE) VALUES('NOMOUNT');
INSERT INTO RCA13_ORACHK_DB_MODES_MASTER(DATABASE_MODE) VALUES('MOUNT');
INSERT INTO RCA13_ORACHK_DB_MODES_MASTER(DATABASE_MODE) VALUES('OPEN');
COMMIT;
end if;
end;
/
  -- For Component_dependency ASM, CRS, RDBMS-- Screen Display    

DELETE FROM RCA13_ORACHK_COMP_DEP;
COMMIT;
/
  
    INSERT INTO RCA13_ORACHK_COMP_DEP(COMP_DEP_NAME) VALUES('ASM');
INSERT INTO RCA13_ORACHK_COMP_DEP(COMP_DEP_NAME) VALUES('CRS');
INSERT INTO RCA13_ORACHK_COMP_DEP(COMP_DEP_NAME) VALUES('RDBMS');
COMMIT;

/
 -- For ORACLE_HOME_TYPE ASM, CRS, RDBMS-- Screen Display

 DELETE FROM RCA13_ORACHK_ORACLE_HOME_TYPE;
COMMIT;
/   
    INSERT INTO RCA13_ORACHK_ORACLE_HOME_TYPE(ORA_HOME_NAME) VALUES('ASM');
INSERT INTO RCA13_ORACHK_ORACLE_HOME_TYPE(ORA_HOME_NAME) VALUES('CRS');
INSERT INTO RCA13_ORACHK_ORACLE_HOME_TYPE(ORA_HOME_NAME) VALUES('RDBMS');
COMMIT;
/
--For Candidate_Systems RACCHECK, SIDB, * -- Screen Display
declare
iscandsys number;
begin
select count(1) into iscandsys from RCA13_ORACHK_CHECKS_CAND_SYS;
if iscandsys < 1 then
DELETE FROM RCA13_ORACHK_CAND_SYS;
COMMIT;
Insert into RCA13_ORACHK_CAND_SYS (CAND_SYS_NAME) values ('X2-2');
Insert into RCA13_ORACHK_CAND_SYS (CAND_SYS_NAME) values ('X3-2');
Insert into RCA13_ORACHK_CAND_SYS (CAND_SYS_NAME) values ('X4-2');
Insert into RCA13_ORACHK_CAND_SYS (CAND_SYS_NAME) values ('X5-2');
Insert into RCA13_ORACHK_CAND_SYS (CAND_SYS_NAME) values ('X2-8');
Insert into RCA13_ORACHK_CAND_SYS (CAND_SYS_NAME) values ('X3-8');
Insert into RCA13_ORACHK_CAND_SYS (CAND_SYS_NAME) values ('X4-8');
Insert into RCA13_ORACHK_CAND_SYS (CAND_SYS_NAME) values ('X5-8');
Insert into RCA13_ORACHK_CAND_SYS (CAND_SYS_NAME) values ('SUPERCLUSTER');
Insert into RCA13_ORACHK_CAND_SYS (CAND_SYS_NAME) values ('SUPERCLUSTERX3-2');
Insert into RCA13_ORACHK_CAND_SYS (CAND_SYS_NAME) values ('SUPERCLUSTERX4-2');
Insert into RCA13_ORACHK_CAND_SYS (CAND_SYS_NAME) values ('SUPERCLUSTERX5-2');
Insert into RCA13_ORACHK_CAND_SYS (CAND_SYS_NAME) values ('DBM');
Insert into RCA13_ORACHK_CAND_SYS (CAND_SYS_NAME) values ('RACCHECK');
Insert into RCA13_ORACHK_CAND_SYS (CAND_SYS_NAME) values ('SIDB');
COMMIT;
end if;
end;
/
-- For -eg,-ne,-gt,-lt,-ge,-le,=,!=,-n,-z'-- Screen Display  

DELETE FROM RCA13_ORACHK_OP_STRING;
COMMIT;
/
  
INSERT INTO RCA13_ORACHK_OP_STRING VALUES('equal (integer comparison)','-eq');
INSERT INTO RCA13_ORACHK_OP_STRING VALUES('not equal  (integer comparison)','-ne');
INSERT INTO RCA13_ORACHK_OP_STRING VALUES('greater than  (integer comparison)','-gt');
INSERT INTO RCA13_ORACHK_OP_STRING VALUES('less than  (integer comparison)','-lt');
INSERT INTO RCA13_ORACHK_OP_STRING VALUES('greater than or equal  (integer comparison)','-ge');
INSERT INTO RCA13_ORACHK_OP_STRING VALUES('less than or equal  (integer comparison)','-le');
INSERT INTO RCA13_ORACHK_OP_STRING VALUES('equal (string comparison)','=');
INSERT INTO RCA13_ORACHK_OP_STRING VALUES('not equal  (string comparison)','!=');
INSERT INTO RCA13_ORACHK_OP_STRING VALUES('empty  (string comparison)','-z');
INSERT INTO RCA13_ORACHK_OP_STRING VALUES('not empty  (string comparison)','-n');
INSERT INTO RCA13_ORACHK_OP_STRING VALUES('file exists','-f');
INSERT INTO RCA13_ORACHK_OP_STRING VALUES('file does not exist','!-f');
INSERT INTO RCA13_ORACHK_OP_STRING VALUES('directory exists','-d');
INSERT INTO RCA13_ORACHK_OP_STRING VALUES('directory does not exist','!-d');
COMMIT;
/
 -- For 'WARN,FAIL,INFO'-- Screen Display   
DELETE FROM RCA13_ORACHK_ALERT_LEVEL;
COMMIT;
/

INSERT INTO RCA13_ORACHK_ALERT_LEVEL VALUES('WARN','WARN');
INSERT INTO RCA13_ORACHK_ALERT_LEVEL VALUES('FAIL','FAIL');
INSERT INTO RCA13_ORACHK_ALERT_LEVEL VALUES('INFO','INFO');
COMMIT;
/

 -- For Version --Screen Display  -- 102040:102050:111070:112010:112020:112030:112040:121010:121020 
declare
isversion number;
begin
select count(1) into isversion from RCA13_ORACHK_CHECKS_VERSION;
if isversion < 1 then
    
DELETE from RCA13_VERSION;
COMMIT;

     
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('12.2.99.0.0',0,to_date('04-SEP-14','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('4.2.0.0.0',0,to_date('07-OCT-13','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('2.6.0.0.0',0,to_date('29-NOV-12','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('4.4.0.0.0',0,to_date('30-MAR-12','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('2.3.1.0.0',0,to_date('06-FEB-12','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('11.1.2.3.0',0,to_date('12-JAN-12','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('12.1.0.2.0',1,to_date('04-JAN-12','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('3.0.1.0.0',0,to_date('30-SEP-11','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('2.4.0.0.0',0,to_date('02-AUG-11','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('12.1.0.1.0',1,to_date('27-JAN-11','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('11.1.2.2.0',0,to_date('29-JUN-10','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('2.4.1.0.0',0,to_date('15-JUN-10','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('4.1.0.0.0',0,to_date('06-MAY-10','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('4.3.0.0.0',0,to_date('07-DEC-09','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('12.2.0.1.0',0,to_date('25-SEP-09','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('11.2.0.4.0',1,to_date('18-SEP-09','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('2.3.0.0.0',0,to_date('26-FEB-09','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('2.2.0.0.0',0,to_date('26-FEB-09','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('3.1.0.0.0',0,to_date('26-JAN-09','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('3.0.0.0.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('4.0.0.0.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('11.2.0.1.0',1,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('2.2.1.0.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('2.1.0.0.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('10.1.0.6.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('10.2.0.2.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('9.2.0.4.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('11.2.0.2.0',1,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('11.2.0.3.0',1,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('2.0.1.0.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('2.5.0.0.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('2.1.1.0.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('11.1.2.0.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('11.1.0.7.0',1,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('10.2.0.4.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('9.2.0.5.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('9.2.0.8.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('10.1.0.4.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('10.1.0.5.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('10.2.0.1.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('9.2.0.7.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('10.2.0.3.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('9.2.0.6.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('10.2.0.5.0',1,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('11.1.0.6.0',0,to_date('30-NOV-02','DD-MON-RR'));
Insert into RCA13_VERSION (VERSION_NAME,IS_PREFERRED,DATE_ADDED) values ('12.2.0.0.0',0,to_date('30-NOV-02','DD-MON-RR'));

COMMIT;
end if;
end;
/
-- For DISTRIBUTIONs Screen Display
  declare
isdistribution number;
begin
select count(1) into isdistribution from RCA13_ORACHK_CHECKS_PLATFORM;
if isdistribution < 1 then
DELETE from RCA13_DISTRIBUTION;
COMMIT;

Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('59B0D2D2E5A4E309E0401490CACF613A','2E4EC61F3D83080BE040578C74063958',null,'10','Generic_118833-36',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('59B0D2D2E5A5E309E0401490CACF613A','2E4EC61F3D83080BE040578C74063958',null,'10','Generic_120011-14',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('59B0D2D2E5A6E309E0401490CACF613A','2E4EC61F3D83080BE040578C74063958',null,'10','Generic_137111-08',1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('59B0CAF1AA78421EE0401490CACF6154','2E4EC61F3D79080BE040578C74063958',null,'5.1',null,0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('59B0D2D2E5A7E309E0401490CACF613A','2E4EC61F3D79080BE040578C74063958',null,'5.2',null,1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('59B0CAF1AA79421EE0401490CACF6154','2E4EC61F3D79080BE040578C74063958',null,'5.3',null,1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('5A63FF5117670A52E0401490CACF0B39','2E4EC61F3D74080BE040578C74063958',null,'11.11',null,0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('5A63FF5117680A52E0401490CACF0B39','2E4EC61F3D76080BE040578C74063958',null,'11.31',null,1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('5A6AE6CE146C299CE0401490CACF35CB','2E4EC61F3D7B080BE040578C74063958','SUSE','9','2.6.5-7.308',1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('670BBB66A8C7C8ECE040E50A1EC06289','2E4EC61F3D7B080BE040578C74063958','OEL','4U5','2.6.9-55.0.0.0.2.ELsmp',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('670961A7F80EB397E040E50A1EC01DDC','2E4EC61F3D7B080BE040578C74063958','OEL','4U6','2.6.9-67.0.0.0.1.ELlargesmp',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('67100D8F794FAE95E040E50A1EC0194A','2E4EC61F3D7B080BE040578C74063958','OEL','5','2.6.18-8.el5',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('670AFCED9C42F728E040E50A1EC02E04','2E4EC61F3D7B080BE040578C74063958','OEL','5U2','2.6.18-92.el5xen',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('9C8FA60F85282A7BE040E50A1EC017C9','2E4EC61F3D7B080BE040578C74063958','OELRHEL','5','2.6.18-194.3.1.0.3.el5',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('A597CB32DC838C66E040E50A1EC050E8','2E4EC61F3D75080BE040578C74063958',null,'10',null,1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('C04D38618B5F3772E0431EC0E50AE367','2E4EC61F3D7B080BE040578C74063958','OEL/RHEL','6','2.6.32-100.28.5.el6',1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('AC4A1133EEDA7179E040E50A1EC02CAA','2E4EC61F3D7B080BE040578C74063958','SUSE','11','2.6.18-194.3.1.0.4.el5',1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('05DAEB97E03462B8E05312C0E50A3875','2E4EC61F3D82080BE040578C74063958','OEL/RHEL','7','3.8.13-35.3.1.el7uek.x86_64',1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('05E05142E8A923EDE05312C0E50A9DE4','2E4EC61F3D82080BE040578C74063958','SUSE','12','3.8.13-35.3.1.el7uek.x86_64',1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('5A69DD9F7B735E13E0401490CACF5C79','2E4EC61F3D7B080BE040578C74063958','SUSE','10','2.6.16.21',1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('670F736C79F73E0EE040E50A1EC07A1D','2E4EC61F3D7B080BE040578C74063958','OEL','4U4','2.6.9-42.0.0.0.1.ELlargesmp',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('670ACDDD506FA0E8E040E50A1EC077F5','2E4EC61F3D7B080BE040578C74063958','OEL','4U4','2.6.9-42.0.0.0.1.ELsmp',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('6709F163352A0DD9E040E50A1EC023CA','2E4EC61F3D7B080BE040578C74063958','OEL/RHEL','4','2.6.9-67.0.0.0.1.EL',1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('B42784FD152A52C1E0431EC0E50A4D89','2E4EC61F3D75080BE040578C74063958',null,'11','11.0',1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('C0514BA0CFE625CBE0431EC0E50ACAEB','2E4EC61F3D79080BE040578C74063958',null,'7.1',null,1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('FBA91EE4472054F5E04312C0E50A05DC','4E6E6FBC6FE7268EE0401490CACF2A02',null,'2008+',null,1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('59B0C14B60FB97DAE0401490CACF6158','2E4EC61F3D83080BE040578C74063958',null,'9','Generic_118558-39',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('5A5EE61AD1A60544E0401490CACF6310','2E4EC61F3D74080BE040578C74063958',null,'11.23',null,1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('5A6939D89F38E4CBE0401490CACF66FC','2E4EC61F3D74080BE040578C74063958',null,'11.31',null,1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('5A6939D89F39E4CBE0401490CACF66FC','2E4EC61F3D76080BE040578C74063958',null,'11.23',null,1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('5A687722639CE2B4E0401490CACF02E4','2E4EC61F3D85080BE040578C74063958','SUSE','10','2.6.16.21 ',1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('670BE60F8BCD2D72E040E50A1EC06655','2E4EC61F3D7B080BE040578C74063958','OEL','4U4','2.6.9-42.0.0.0.1.EL',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('670A36A7E49675F5E040E50A1EC072B4','2E4EC61F3D7B080BE040578C74063958','OEL','5','2.6.18-8.el5xen',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('670A36A7E49775F5E040E50A1EC072B4','2E4EC61F3D7B080BE040578C74063958','OEL','5U1','2.6.18-53.el5',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('C858E12A380711E0E0431EC0E50A5A9C','2E4EC61F3D83080BE040578C74063958',null,'11',null,1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('52BEAD4D981280D6E0401490CACF4410','2E4EC61F3D85080BE040578C74063958','RHEL','4','2.6.9-5.ELhugemem',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('52C5AF9C64474603E0401490CACF2453','2E4EC61F3D85080BE040578C74063958','RHEL','4u3','2.6.9-34.EL',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('52C28A537A356B7AE0401490CACF40A4','2E4EC61F3D85080BE040578C74063958','RHEL','4u3','2.6.9-34.ELhugemem',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('52D9E1B656AB2406E0401490CACF4801','2E4EC61F3D85080BE040578C74063958','RHEL','4u4','2.6.9-42.ELhugemem',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('52D5636D4158A305E0401490CACF3FBD','2E4EC61F3D85080BE040578C74063958','RHEL','4u4','2.6.9-42smp',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('52D9E1B656AC2406E0401490CACF4801','2E4EC61F3D85080BE040578C74063958','RHEL','4u5','2.6.9-55.EL',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('54D14C9D8FAB27CCE0401490CACF6427','2E4EC61F3D85080BE040578C74063958','OEL','4u4','2.6.9-42.0.0.0.1.hugemem',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('54D2915D2D30866CE0401490CACF2F02','2E4EC61F3D85080BE040578C74063958','OEL','4u4','2.6.9-42.0.0.0.1.smp',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('54D14C9D8FAC27CCE0401490CACF6427','2E4EC61F3D85080BE040578C74063958','OEL','4u5','2.6.9-55.0.0.0.2.hugemem',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('52003A5203F32648E0401490CACF18C3','2E4EC61F3D7B080BE040578C74063958','RHEL','4','2.6.9-55.ELsmp',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('52C0B5AB9C7A606BE0401490CACF0B54','2E4EC61F3D85080BE040578C74063958','RHEL','4u2','2.6.9-22.EL',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('53254C24A5D9EFE9E0401490CACF5017','2E4EC61F3D85080BE040578C74063958','RHEL','5','2.6.18-8.ELpae',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('532A4C0589A020B6E0401490CACF5FE5','2E4EC61F3D85080BE040578C74063958','RHEL','5u1','2.6.18-53.EL',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('53254C24A5DAEFE9E0401490CACF5017','2E4EC61F3D85080BE040578C74063958','RHEL','5u2','2.6.18-92.ELxen',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('53254C24A5DBEFE9E0401490CACF5017','2E4EC61F3D85080BE040578C74063958','OEL','5u1','2.6.9.18-53.EL',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('54D18E122526AECFE0401490CACF7CD9','2E4EC61F3D85080BE040578C74063958','OEL','4u6','2.6.9-67.0.0.0.1.hugemem',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('54CD933A29F076EAE0401490CACF1CA8','2E4EC61F3D85080BE040578C74063958','OEL','4u6','2.6.9-67.0.0.0.1.smp',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('52C4EAF0D3B9421CE0401490CACF0F9B','2E4EC61F3D85080BE040578C74063958','RHEL','4u2','2.6.9-22.ELhugemem',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('53287B3EFB325942E0401490CACF29E5','2E4EC61F3D85080BE040578C74063958','RHEL','5','2.6.18-8.EL',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('53248F75063BE4B8E0401490CACF555D','2E4EC61F3D85080BE040578C74063958','RHEL','5u2','2.6.18-92.EL',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('53248F75063CE4B8E0401490CACF555D','2E4EC61F3D85080BE040578C74063958','OEL','5','2.6.9.18-8.ELpae',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('532817542CA0A078E0401490CACF2139','2E4EC61F3D85080BE040578C74063958','OEL','5','2.6.9.18-8.ELxen',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('532817542CA1A078E0401490CACF2139','2E4EC61F3D85080BE040578C74063958','OEL','5u1','2.6.9.18-53.ELxen',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('54D063B81850A633E0401490CACF4E13','2E4EC61F3D85080BE040578C74063958','OEL','4u5','2.6.9-55.0.0.0.2.smp',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('54D0DAFDD08F5463E0401490CACF7495','2E4EC61F3D85080BE040578C74063958','OEL/RHEL','5','2.6.18-92.el5',1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('54CE160B99A8F121E0401490CACF0566','2E4EC61F3D85080BE040578C74063958','OEL','5u2','2.6.18-92.el5xen',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('54D0DAFDD0925463E0401490CACF7495','2E4EC61F3D85080BE040578C74063958','OEL/RHEL','4','2.6.9-67.0.0.0.1.EL',1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('52C4EC9DAA37BE35E0401490CACF0FC2','2E4EC61F3D85080BE040578C74063958','RHEL','4','2.6.9-5.EL',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('52BE9D3902C91C96E0401490CACF4CD1','2E4EC61F3D85080BE040578C74063958','RHEL','4','2.6.9-5.ELsmp',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('52BCEABA5CFF9376E0401490CACF214A','2E4EC61F3D85080BE040578C74063958','RHEL','4u1','2.6.9-11.ELsmp',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('52BF43ECBF941FBBE0401490CACF43BB','2E4EC61F3D85080BE040578C74063958','RHEL','4u1','2.6.9-11.ELhugemem',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('52D7EC4A350C9045E0401490CACF15AE','2E4EC61F3D85080BE040578C74063958','RHEL','4u5','2.6.9-55.ELsmp',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('53275B325544EC58E0401490CACF0801','2E4EC61F3D85080BE040578C74063958','RHEL','5u1','2.6.18-53.ELpae',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('53275B325545EC58E0401490CACF0801','2E4EC61F3D85080BE040578C74063958','RHEL','5u2','2.6.18-92.ELpae',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('53275B325546EC58E0401490CACF0801','2E4EC61F3D85080BE040578C74063958','OEL','5','2.6.9.18-8.EL',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('54D00821484C9B1AE0401490CACF39C2','2E4EC61F3D85080BE040578C74063958','OEL','4u5','2.6.9-55.0.0.0.2.EL ',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('54D128DB5143FD8EE0401490CACF5999','2E4EC61F3D85080BE040578C74063958','OEL','5u2','2.6.18-92.EL5PAE',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('52BDC9F97F2732A9E0401490CACF3581','2E4EC61F3D85080BE040578C74063958','RHEL','4u1','2.6.9-11.EL',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('52C2B8F5D0BCEAB0E0401490CACF4CCD','2E4EC61F3D85080BE040578C74063958','RHEL','4u2','2.6.9-22.ELsmp',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('52BDC9F97F2A32A9E0401490CACF3581','2E4EC61F3D85080BE040578C74063958','RHEL','4u3','2.6.9-34.ELsmp',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('52D90DBD8F4E2A07E0401490CACF1BEC','2E4EC61F3D85080BE040578C74063958','RHEL','4u4','2.6.9-42.EL',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('52D90DBD8F4F2A07E0401490CACF1BEC','2E4EC61F3D85080BE040578C74063958','RHEL','4u5','2.6.9-55.ELhugemem',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('5328CEED2F1BE4E9E0401490CACF5123','2E4EC61F3D85080BE040578C74063958','RHEL','5','2.6.18-8.ELxen',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('5328CEED2F1CE4E9E0401490CACF5123','2E4EC61F3D85080BE040578C74063958','RHEL','5u1','2.6.18-53.ELxen',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('5324FEDBBD751A1AE0401490CACF5A12','2E4EC61F3D85080BE040578C74063958','OEL','5u1','2.6.9.18-53.ELpae',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('54CFCF00759FF396E0401490CACF55F9','2E4EC61F3D85080BE040578C74063958','OEL','4u4','2.6.9-42.0.0.0.1.EL',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('554C05A06853B896E0401490CACF16CB','2E4EC61F3D83080BE040578C74063958',null,'10','Generic_118833-33',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('59B0C1BD99ECB395E0401490CACF6240','2E4EC61F3D83080BE040578C74063958',null,'9','Generic_112233-12',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('59B0C39770D8021DE0401490CACF60F9','2E4EC61F3D83080BE040578C74063958',null,'9','Generic_122300-31',1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('5A6A3BFAC16D4FE1E0401490CACF01A4','2E4EC61F3D85080BE040578C74063958','SUSE','9','2.6.5-7.308',1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('5A69E64D70E561CDE0401490CACF632C','2E4EC61F3D74080BE040578C74063958',null,'11.1',null,0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('5A6A3BFAC1614FE1E0401490CACF01A4','2E4EC61F3D74080BE040578C74063958',null,'11.22',null,0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('670FFD5B39386600E040E50A1EC022E1','2E4EC61F3D7B080BE040578C74063958','OEL','4U5','2.6.9-55.0.0.0.2.ELlargesmp',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('670FFD5B393C6600E040E50A1EC022E1','2E4EC61F3D7B080BE040578C74063958','OEl','5U1','2.6.18-53.el5xen',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('057D408246577BA0E05313C0E50AFF10','2E4EC61F3D7B080BE040578C74063958','OEL/RHEL','7','3.8.13-35.3.1.el7uek.x86_64',1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('05DF98A4D7662F27E05312C0E50A6F50','2E4EC61F3D7B080BE040578C74063958','SUSE','12','3.8.13-35.3.1.el7uek.x86_64',1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('59B0DC02840BE73DE0401490CACF626A','2E4EC61F3D83080BE040578C74063958',null,'10','Generic_127127-11',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('59B1E569F43AEB57E0401490CACF3073','2E4EC61F3D83080BE040578C74063958',null,'9','Generic_117171-17',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('59B0FB2818967B6AE0401490CACF6284','2E4EC61F3D79080BE040578C74063958',null,'6.1',null,1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('5A69E65BF12E9642E0401490CACF5572','2E4EC61F3D74080BE040578C74063958',null,'11.0',null,0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('5A6A273BC1741A8BE0401490CACF2BD6','2E4EC61F3D76080BE040578C74063958',null,'11.22',null,0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('5A692D6530C54E7EE0401490CACF640C','2E4EC61F3D85080BE040578C74063958','SUSE','9SP3','2.6.5-7.244',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('67093C4C7928050CE040E50A1EC02460','2E4EC61F3D7B080BE040578C74063958','OEL','4U5','2.6.9-55.0.0.0.2.EL',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('67093C4C7929050CE040E50A1EC02460','2E4EC61F3D7B080BE040578C74063958','OEL','4U6','2.6.9-67.0.0.0.1.ELsmp',0);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('670E0E1F77EC0BABE040E50A1EC01835','2E4EC61F3D7B080BE040578C74063958','OEL/RHEL','5','2.6.18-92.el5',1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('AC4B8B0629319AD8E040E50A1EC06F71','2E4EC61F3D85080BE040578C74063958','SUSE','11','2.6.18-194.3.1.0.4.el5',1);
Insert into RCA13_DISTRIBUTION (DISTRIBUTION_OS_ID,PLATFORM_ID,OSDIST,OSVERSION,OSKERNEL,OSDIST_REP_KERNEL) values ('05A87C9306422E7AE05312C0E50A93C1','2E4EC61F3D82080BE040578C74063958','OEL/RHEL','6','2.6.32-431.el6.s390x',1);
COMMIT;
end if;
end;
/
 -- For Platforms Screen Display  
   
declare
isplatform number;
begin
select count(1) into isplatform from RCA13_ORACHK_CHECKS_PLATFORM;
if isplatform < 1 then

DELETE FROM RCA13_PLATFORM;
COMMIT;

Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('340421D4149FE138E0401490CACF4CB5','APPLE MACINTOSH POWERPC',425,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('340421D414A3E138E0401490CACF4CB5','MICROSOFT WINDOWS VISTA (32-BIT)',245,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('50E9060C8A567763E0401490CACF11DA','AIX6 (64-BIT)',212,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('6B08DD50CDE0F20CE040E50A1EC02102','IBM ISERIES OS/400',null,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('D01669276C456319E0431EC0E50A3A68','AIX7 (64-BIT)',212,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3401747C5110A363E0401490CACF7963','HP 9000 SERIES HP-UX BLS (SECURE)',257,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3401747C5126A363E0401490CACF7963','FUJITSU GP7000 MODEL 800 UNIX (64-BIT)',45,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('37B7BCC83B4D8E6FE0401490CACF3622','HP 3000 SERIES MPE/IX',70,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3CA4FF041399F62BE0401490CACF0BAA','X86 64 BIT',null,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('7787658B8E2ACFB3E040E50A1EC0097D','APPLE MACINTOSH INTEL',null,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3049321C2CCA987AE040238228B43EA7','AIX 4.3 BASED SYSTEMS (64-BIT)',38,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2F0E69542CDCB259E040238228B448EE','AIX5L BASED SYSTEMS (32-BIT)',275,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2E4EC61F3D79080BE040578C74063958','AIX5L BASED SYSTEMS (64-BIT)',212,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('30491DEF245956F0E040238228B44890','APPLE MAC OS',421,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2E4EC61F3D81080BE040578C74063958','BULL ESCALA RL AIX (64-BIT)',33,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2E4EC61F3D78080BE040578C74063958','FUJITSU PRIMEPOWER SOLARIS',109,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2E4EC61F3D7C080BE040578C74063958','GENERIC 32/64',null,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3049321C2D31987AE040238228B43EA7','HAANSOFT LINUX X86-64',247,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3049321C2D01987AE040238228B43EA7','HP 9000 SERIES HP-UX CMW (SECURE)',731,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3049321C2D14987AE040238228B43EA7','HP OPENVMS ALPHA',89,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3048BF935CFDCCC6E040238228B468E1','HP OPENVMS ITANIUM',243,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2E4EC61F3D7A080BE040578C74063958','HP TRU64 UNIX',87,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2E4EC61F3D76080BE040578C74063958','HP-UX ITANIUM',197,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('310D5A1515D3F0A5E040238228B43993','HP-UX PA-RISC (32-BIT)',2,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2E4EC61F3D74080BE040578C74063958','HP-UX PA-RISC (64-BIT)',59,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3048BF935CC2CCC6E040238228B468E1','IBM POWER BASED LINUX',227,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('30490E8B3B447D8EE040238228B4441B','IBM SP AIX',610,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2F7D9562CCD2C0DCE040238228B41383','IBM Z/OS (OS/390)',30,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2E4EC61F3D82080BE040578C74063958','IBM ZSERIES BASED LINUX',209,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('302D660F06483978E040238228B44A3D','LINUX INTEL (64-BIT)',110,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2E4EC61F3D77080BE040578C74063958','LINUX ITANIUM',214,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2E4EC61F3D85080BE040578C74063958','LINUX X86',46,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2E4EC61F3D7B080BE040578C74063958','LINUX X86-64',226,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3049682B22E4AEABE040238228B448B3','MICROSOFT WINDOWS',176,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2E4EC61F3D87080BE040578C74063958','MICROSOFT WINDOWS (32-BIT)',912,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2F7D9A38FD1B86C7E040238228B41225','MICROSOFT WINDOWS 2000',100,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3049E279AABA3B50E040238228B44D7A','MICROSOFT WINDOWS NT TERMINAL SERVER',175,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2E4EC61F3D7E080BE040578C74063958','MICROSOFT WINDOWS SERVER 2003',215,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('302D6A1D1790B90DE040238228B44644','MICROSOFT WINDOWS SERVER 2003 (64-BIT AMD64 AND INTEL EM64T)',233,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2EE1611B101D9D5BE040238228B4063E','MICROSOFT WINDOWS SERVER 2003 (64-BIT ITANIUM)',208,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2E4EC61F3D80080BE040578C74063958','MICROSOFT WINDOWS SERVER 2003 R2 (32-BIT)',269,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3048BF935CD6CCC6E040238228B468E1','MICROSOFT WINDOWS SERVER 2003 R2 (64-BIT AMD64 AND INTEL EM64T)',268,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('302845CF27833147E040238228B40EDE','MICROSOFT WINDOWS XP',207,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3048BF935DF6CCC6E040238228B468E1','ORACLE ENTERPRISE LINUX 4.0',284,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2E4EC61F3D86080BE040578C74063958','RED HAT ADVANCED SERVER',213,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2EE1490D9CF44834E040238228B4085D','RED HAT ENTERPRISE LINUX ADVANCED SERVER ITANIUM',216,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('302D6A1D1781B90DE040238228B44644','RED HAT ENTERPRISE LINUX ADVANCED SERVER X86-64 (AMD OPTERON ARCHITECTURE)',225,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3048BF935DE4CCC6E040238228B468E1','RED HAT ENTERPRISE LINUX WORKSTATION',229,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3049321C2CF0987AE040238228B43EA7','REDFLAG X86-64',241,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2E4EC61F3D7F080BE040578C74063958','SOLARIS OPERATING SYSTEM (SPARC 32-BIT)',453,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2E4EC61F3D83080BE040578C74063958','SOLARIS OPERATING SYSTEM (SPARC 64-BIT)',23,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3049682B22F8AEABE040238228B448B3','SOLARIS OPERATING SYSTEM (X86)',173,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2E4EC61F3D75080BE040578C74063958','SOLARIS OPERATING SYSTEM (X86-64)',267,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3049682B22D3AEABE040238228B448B3','SUN SPARC SUN OS',451,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('2E4EC61F3D84080BE040578C74063958','SUSE \ UNITEDLINUX X86-64',219,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3048BDD7E5EEEAC3E040238228B4770F','UNISYS 1100 SERIES UNIX',192,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('33FDEA1DC0795D11E0401490CACF2821','UNITEDLINUX (32-BIT)',217,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('34002DD1C0928059E0401490CACF4030','MICROSOFT WINDOWS XP (64-BIT ITANIUM)',206,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('34002DD1C0E48059E0401490CACF4030','AIX BASED SYSTEMS (32-BIT)',319,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('4E6E6FBC6FE7268EE0401490CACF2A02','MICROSOFT WINDOWS X64 (64-BIT)',233,1);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3400251365DCB4C7E0401490CACF4A74','IBM S/390 BASED LINUX',211,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('34ED717A492CBEB7E0401490CACF0E7E','MICROSOFT WINDOWS XP (64-BIT AMD64 AND INTEL EM64T)',232,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('39451686C459F2AFE0401490CACF1857','IBM NUMA-Q DYNIX/PTX',198,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('39D23C90472C6318E0401490CACF73AE','SUN TRUSTED SOLARIS (SECURE)',258,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('7EC21A4F935D3FF0E040E50A1EC02B6F','HP-UX ITANIUM (32-BIT)',null,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('33FDE84E3026CCB2E0401490CACF2AFA','ASIANUX X86',234,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('33FE81669B29E1D1E0401490CACF3D84','MIRACLE LINUX X86',235,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3CB8C51A72CD6320E0401490CACF04D5','FUJITSU SIEMENS BS2000/OSD',null,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3D7FFAE997433881E0401490CACF2481','LINUX ON POWER',null,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3D7FFAE997443881E0401490CACF2481','ORACLE CERTIFICATION ENVIRONMENT',null,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('3E3487B83BB7C523E0401490CACF6971','MICROSOFT WINDOWS (64-BIT) ON INTEL ITANIUM',null,0);
Insert into RCA13_PLATFORM (PLATFORM_ID,NAME,PRODUCT_LINE_ID,IS_PREFERRED) values ('4951DC19DAD2842AE0401490CACF5953','MICROSOFT WINDOWS SERVER 2008 (32-BIT)',215,1);
COMMIT;
end if;
end;

/
CREATE OR REPLACE PACKAGE RCA13_UTILITY
AS
  FUNCTION clob_to_blob(
      c IN CLOB )
    RETURN BLOB;
END RCA13_UTILITY;
/

CREATE OR REPLACE PACKAGE BODY RCA13_UTILITY
AS
  FUNCTION clob_to_blob(
      c IN CLOB )
    RETURN BLOB
    -- typecasts CLOB to BLOB (binary conversion)
  IS
    pos PLS_INTEGER := 1;
    buffer RAW( 32767 );
    res BLOB;
    lob_len PLS_INTEGER := DBMS_LOB.getLength( c );
  BEGIN
    DBMS_LOB.createTemporary( res, TRUE );
    DBMS_LOB.OPEN( res, DBMS_LOB.LOB_ReadWrite );
    LOOP
      buffer                     := UTL_RAW.cast_to_raw( DBMS_LOB.SUBSTR( c, 8000, pos ) );
      IF UTL_RAW.LENGTH( buffer ) > 0 THEN
        DBMS_LOB.append( res, buffer );
      END IF;
      pos := pos + 8000;
      EXIT
    WHEN pos > lob_len;
    END LOOP;
    RETURN res; -- res is OPEN here
  END;
END RCA13_UTILITY;
/

CREATE OR REPLACE PACKAGE RCA13_DOCLIB
AS
  PROCEDURE create_document_from_text(
      docId OUT NUMBER,
      fileName VARCHAR2,
      fileContents CLOB,
      idValue  VARCHAR2,
      app_user VARCHAR2);
  PROCEDURE create_document_from_text(
      fileName VARCHAR2,
      fileContents CLOB,
      idValue  VARCHAR2,
      app_user VARCHAR2);
END RCA13_DOCLIB;
/
    
CREATE OR REPLACE PACKAGE BODY RCA13_DOCLIB
AS
  PROCEDURE create_document_from_text(
      docId OUT NUMBER,
      fileName VARCHAR2,
      fileContents CLOB,
      idValue  VARCHAR2,
      app_user VARCHAR2)
  IS
    blobContents BLOB := RCA13_UTILITY.clob_to_blob(fileContents);
  BEGIN
    INSERT
    INTO RCA13_DOCS
      (
        filename,
        file_mimetype,
        file_blob,
        attr1,
        uploaded_by
      )
      VALUES
      (
        fileName,
        'application/x-sh',
        RCA13_UTILITY.clob_to_blob(fileContents),
        idValue,
        app_user
      )
      RETURN doc_id
    INTO docId;
  END;
  PROCEDURE create_document_from_text
    (
      fileName VARCHAR2,
      fileContents CLOB,
      idValue  VARCHAR2,
      app_user VARCHAR2
    )
  IS
    blobContents BLOB := RCA13_UTILITY.clob_to_blob(fileContents);
    docId NUMBER;
  BEGIN
    create_document_from_text (docId, fileName, fileContents, idValue,app_user);
  END;
END RCA13_DOCLIB;
/
CREATE OR REPLACE PACKAGE "RCA13_MANAGE_AUDIT_CHECKS"
AS
  FUNCTION update_audit_check_info(
      p_check_id IN VARCHAR2,
      p_att1     IN VARCHAR2,
      p_type     IN VARCHAR2)
    RETURN VARCHAR2;
END RCA13_MANAGE_AUDIT_CHECKS;
/
CREATE OR REPLACE PACKAGE BODY "RCA13_MANAGE_AUDIT_CHECKS"
AS
  FUNCTION update_audit_check_info(
      p_check_id IN VARCHAR2,
      p_att1     IN VARCHAR2,
      p_type     IN VARCHAR2)
    RETURN VARCHAR2
  IS
    rStatus VARCHAR2(4000) := '';
    tStatus VARCHAR2(4000) := '';
  BEGIN
    IF ( p_type = 'DB_ROLE' ) THEN
      DELETE
      FROM RCA13_ORACHK_CHECKS_DB_ROLES
      WHERE check_id = p_check_id;
      FOR rec2 IN
      (SELECT regexp_substr(p_att1,'[^:]+', 1, level) col
      FROM dual
        CONNECT BY regexp_substr(p_att1, '[^:]+', 1, level) IS NOT NULL
      )
      LOOP
        INSERT
        INTO RCA13_ORACHK_CHECKS_DB_ROLES
          (
            check_id,
            DATABASE_ROLE_ID
          )
          VALUES
          (
            p_check_id,
            rec2.col
          );
      END LOOP;
    elsif p_type = 'DB_TYPE' THEN
      DELETE
      FROM RCA13_ORACHK_CHECKS_DB_TYPES
      WHERE check_id = p_check_id;
      FOR rec2 IN
      (SELECT regexp_substr(p_att1,'[^:]+', 1, level) col
      FROM dual
        CONNECT BY regexp_substr(p_att1, '[^:]+', 1, level) IS NOT NULL
      )
      LOOP
        INSERT
        INTO RCA13_ORACHK_CHECKS_DB_TYPES
          (
            check_id,
            DATABASE_TYPE_ID
          )
          VALUES
          (
            p_check_id,
            rec2.col
          );
      END LOOP;
    elsif p_type = 'DB_MODE' THEN
      DELETE
      FROM RCA13_ORACHK_CHECKS_DB_MODES
      WHERE check_id = p_check_id;
      FOR rec2 IN
      (SELECT regexp_substr(p_att1,'[^:]+', 1, level) col
      FROM dual
        CONNECT BY regexp_substr(p_att1, '[^:]+', 1, level) IS NOT NULL
      )
      LOOP
        INSERT
        INTO RCA13_ORACHK_CHECKS_DB_MODES
          (
            check_id,
            DATABASE_MODE_ID
          )
          VALUES
          (
            p_check_id,
            rec2.col
          );
      END LOOP;
    elsif p_type = 'CAND_SYS' THEN
      DELETE
      FROM RCA13_ORACHK_CHECKS_CAND_SYS
      WHERE check_id = p_check_id;
      FOR rec2 IN
      (SELECT regexp_substr(p_att1,'[^:]+', 1, level) col
      FROM dual
        CONNECT BY regexp_substr(p_att1, '[^:]+', 1, level) IS NOT NULL
      )
      LOOP
        INSERT
        INTO RCA13_ORACHK_CHECKS_CAND_SYS
          (
            check_id,
            CAND_SYS_ID
          )
          VALUES
          (
            p_check_id,
            rec2.col
          );
      END LOOP;
    elsif p_type = 'VERSION' THEN
      DELETE
      FROM RCA13_ORACHK_CHECKS_VERSION
      WHERE check_id = p_check_id;
      FOR rec2 IN
      (SELECT regexp_substr(p_att1,'[^:]+', 1, level) col
      FROM dual
        CONNECT BY regexp_substr(p_att1, '[^:]+', 1, level) IS NOT NULL
      )
      LOOP
        INSERT
        INTO RCA13_ORACHK_CHECKS_VERSION
          (
            check_id,
            VERSION_ID
          )
          VALUES
          (
            p_check_id,
            rec2.col
          );
      END LOOP;
    elsif p_type = 'PLATFORM' THEN
      DELETE
      FROM RCA13_ORACHK_CHECKS_PLATFORM
      WHERE check_id = p_check_id;
      FOR rec2 IN
      (SELECT regexp_substr(p_att1,'[^:]+', 1, level) col
      FROM dual
        CONNECT BY regexp_substr(p_att1, '[^:]+', 1, level) IS NOT NULL
      )
      LOOP
        INSERT
        INTO RCA13_ORACHK_CHECKS_PLATFORM
          (
            check_id,
            DISTRIBUTION_OS_ID
          )
          VALUES
          (
            p_check_id,
            rec2.col
          );
      END LOOP;
    elsif p_type = 'LINKS' THEN
      DELETE
      FROM RCA13_ORACHK_CHECKS_LINK
      WHERE check_id = p_check_id;
      FOR rec2 IN
      (SELECT regexp_substr(p_att1,'[^:]+', 1, level) col
      FROM dual
        CONNECT BY regexp_substr(p_att1, '[^:]+', 1, level) IS NOT NULL
      )
      LOOP
        INSERT
        INTO RCA13_ORACHK_CHECKS_LINK
          (
            check_id,
            SF_LINK_ID
          )
          VALUES
          (
            p_check_id,
            rec2.col
          );
      END LOOP;
      RETURN rStatus;
    END IF;
    COMMIT;
    RETURN 'Success';
  END;
------------------------------------------------------------------------------------
END RCA13_MANAGE_AUDIT_CHECKS;
/
CREATE OR REPLACE PROCEDURE UserDefPluginXml(
    app_user VARCHAR2)
IS
  checkId VARCHAR2(40);
  theFile CLOB;
  plname   VARCHAR2(4000);
  trimflag BOOLEAN := false;
  CURSOR USER_CHECKS
  IS
    SELECT CHECK_ID,
      AUDIT_CHECK_NAME,
      ON_HOLD,
      ACTION_TYPE,
      PARAM_PATH,
      COMMAND,
      COMMAND_REPORT,
      OPERATOR_STRING,
      COMPARE_VALUE,
      COMPONENT_DEPENDENCY,
      ORACLE_HOME_TYPE,
      ALERT_LEVEL,
      PASS_MSG,
      FAIL_MSG,
      BENEFIT_IMPACT,
      RISK,
      ACTION_REPAIR
    FROM RCA13_ORACHK_AUDIT_CHECKS
    ORDER BY create_date DESC;
  CURSOR DB_TYPES(checkId VARCHAR2)
  IS
    SELECT MST.DATABASE_TYPE
    FROM RCA13_ORACHK_AUDIT_CHECKS SF,
      RCA13_ORACHK_CHECKS_DB_TYPES DT,
      RCA13_ORACHK_DB_TYPES_MASTER MST
    WHERE SF.CHECK_ID       =DT.CHECK_ID
    AND MST.DATABASE_TYPE_ID=DT.DATABASE_TYPE_ID
    AND SF.CHECK_ID         = checkId
    ORDER BY MST.DATABASE_TYPE;
  CURSOR DB_MODES(checkId VARCHAR2)
  IS
    SELECT DECODE(DATABASE_MODE,'NOMOUNT',1,'MOUNT',2,'OPEN',3) DATABASE_MODE
    FROM RCA13_ORACHK_AUDIT_CHECKS SF,
      RCA13_ORACHK_CHECKS_DB_MODES DT,
      RCA13_ORACHK_DB_MODES_MASTER MST
    WHERE SF.CHECK_ID       =DT.CHECK_ID
    AND MST.DATABASE_MODE_ID=DT.DATABASE_MODE_ID
    AND SF.CHECK_ID         = checkId
    ORDER BY DATABASE_MODE;
  CURSOR DB_ROLES(checkId VARCHAR2)
  IS
    SELECT MST.DATABASE_ROLE
    FROM RCA13_ORACHK_AUDIT_CHECKS SF,
      RCA13_ORACHK_CHECKS_DB_ROLES DT,
      RCA13_ORACHK_DB_ROLES_MASTER MST
    WHERE SF.CHECK_ID       =DT.CHECK_ID
    AND MST.DATABASE_ROLE_ID=DT.DATABASE_ROLE_ID
    AND SF.CHECK_ID         = checkId
    ORDER BY MST.DATABASE_ROLE;
  CURSOR CAND_SYS(checkId VARCHAR2)
  IS
    SELECT MST.CAND_SYS_NAME
    FROM RCA13_ORACHK_AUDIT_CHECKS SF,
      RCA13_ORACHK_CHECKS_CAND_SYS DT,
      RCA13_ORACHK_CAND_SYS MST
    WHERE SF.CHECK_ID  =DT.CHECK_ID
    AND MST.CAND_SYS_ID=DT.CAND_SYS_ID
    AND SF.CHECK_ID    = checkId
    ORDER BY MST.CAND_SYS_NAME;
  CURSOR VERSIONS(checkId VARCHAR2)
  IS
    SELECT MST.VERSION_NAME
    FROM RCA13_ORACHK_AUDIT_CHECKS SF,
      RCA13_ORACHK_CHECKS_VERSION VER,
      RCA13_VERSION MST
    WHERE SF.CHECK_ID =VER.CHECK_ID
    AND MST.VERSION_ID=VER.VERSION_ID
    AND SF.CHECK_ID   = checkId
    ORDER BY MST.VERSION_NAME;
  CURSOR PLATFORMS(checkId VARCHAR2)
  IS
    SELECT DISTINCT RP.NAME,
      RP.PRODUCT_LINE_ID
    FROM RCA13_ORACHK_CHECKS_PLATFORM RCP,
      RCA13_PLATFORM RP,
      RCA13_DISTRIBUTION RD
    WHERE RP.PLATFORM_ID      =RD.PLATFORM_ID
    AND RCP.DISTRIBUTION_OS_ID=RD.DISTRIBUTION_OS_ID
    AND check_id              =checkId
    ORDER BY RP.NAME;
    
  CURSOR FLAVORS(checkId VARCHAR2,PRODUCTLINEID NUMBER)
  IS
    SELECT RD.OSDIST
      ||RD.OSVERSION FLAVOR
    FROM RCA13_ORACHK_CHECKS_PLATFORM RCP,
      RCA13_PLATFORM RP,
      RCA13_DISTRIBUTION RD
    WHERE RP.PLATFORM_ID      =RD.PLATFORM_ID
    AND RCP.DISTRIBUTION_OS_ID=RD.DISTRIBUTION_OS_ID
    AND check_id              =checkId
    AND RP.PRODUCT_LINE_ID    =PRODUCTLINEID
    ORDER BY FLAVOR;
  CURSOR LINKS(checkId VARCHAR2)
  IS
    SELECT MST.NAME,
      MST.LINK
    FROM RCA13_ORACHK_AUDIT_CHECKS SF,
      RCA13_ORACHK_LINK MST,
      RCA13_ORACHK_CHECKS_LINK LK
    WHERE SF.CHECK_ID =LK.CHECK_ID
    AND MST.SF_LINK_ID=LK.SF_LINK_ID
    AND SF.CHECK_ID   = checkId
    ORDER BY MST.NAME;
BEGIN
  theFile := '<?xml version="1.0" encoding="UTF-8"?> '||chr(10)||chr(10);
  dbms_lob.append(theFile,'<UserDefinedChecks' || chr(10));
  dbms_lob.append(theFile,'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'|| CHR(10) ||'xsi:noNamespaceSchemaLocation="user_defined_checks.xsd">' || chr(10));
  dbms_lob.append(theFile,chr(10));
  FOR REC IN USER_CHECKS
  LOOP
    checkId:=REC.check_id;
    dbms_lob.append(theFile,'<CHECK AUDIT_CHECK_NAME="' || rec.AUDIT_CHECK_NAME || '">'||chr(10));
    dbms_lob.append(theFile,'<DISABLED>' || rec.ON_HOLD || '</DISABLED>'||chr(10));
    dbms_lob.append(theFile,'<ORACLE_VERSION>');
    FOR verrec IN versions(checkId)
    LOOP
      dbms_lob.append(theFile, regexp_replace(verrec.version_name,'[[:punct:]]','') || ':' );
      trimflag := true;
    END LOOP;
    IF (trimflag) THEN
      dbms_lob.trim(theFile,dbms_lob.getlength(theFile)-1);
      trimflag := false;
    ELSE
      NULL;
    END IF;
    dbms_lob.append(theFile, '</ORACLE_VERSION>'||chr(10));
    dbms_lob.append(theFile,'<PLATFORMS>'||chr(10));
    FOR PL_NAME IN PLATFORMS(checkId)
    LOOP
      SELECT DECODE(PL_NAME.product_line_id, 23,'SOLARISSPARC64', 46,'LINUXX86', 226,'LINUXX8664', 59,'HPUX', 197,'HPUX', 212,'AIXPPC64', 267,'SOLARISX8664', 233,'MSWINDOWS', 209,'LINUXZX8664')
      INTO plname
      FROM dual;
      dbms_lob.append(theFile, '<PLATFORM TYPE="' || plname || '">'||chr(10));
      plname := NULL;
      dbms_lob.append(theFile,'<FLAVOR>');
      FOR FL_VER IN FLAVORS(checkId,PL_NAME.PRODUCT_LINE_ID)
      LOOP
        IF(PL_NAME.PRODUCT_LINE_ID=59) THEN
          dbms_lob.append(theFile, regexp_replace('PARISC'||FL_VER.FLAVOR,'[[:punct:]]','') || ':');
        elsif(PL_NAME.PRODUCT_LINE_ID=197) THEN
          dbms_lob.append(theFile, regexp_replace('ITANIUM'||FL_VER.FLAVOR,'[[:punct:]]','') || ':');
        elsif(PL_NAME.PRODUCT_LINE_ID=233) then
         dbms_lob.append(theFile, regexp_replace('64','[[:punct:]]','') || ':');
        else
          dbms_lob.append(theFile, regexp_replace(FL_VER.FLAVOR,'[[:punct:]]','') || ':');
        END IF;
        trimflag := true;
      END LOOP;
      IF (trimflag) THEN
        dbms_lob.trim(theFile,dbms_lob.getlength(theFile)-1);
        trimflag := false;
      ELSE
        trimflag := false;
      END IF;
      dbms_lob.append(theFile,'</FLAVOR>'||chr(10));
      dbms_lob.append(theFile, '</PLATFORM>'||chr(10));
    END LOOP;
    dbms_lob.append(theFile,'</PLATFORMS>'||chr(10));
    IF(REC.ACTION_TYPE='OS') THEN
      dbms_lob.append(theFile,'<OS_COMMAND>' || chr(10)||'  <![CDATA[   ' || rec.COMMAND || '   ]]>' || chr(10)||'  </OS_COMMAND>'||chr(10));
      dbms_lob.append(theFile,'<OS_COMMAND_REPORT> ' || chr(10)||'  <![CDATA[   ' || rec.COMMAND_REPORT || '   ]]>' || chr(10)||'  </OS_COMMAND_REPORT>'||chr(10));
     -- dbms_lob.append(theFile,'<PARAM_PATH>' || rec.PARAM_PATH || '</PARAM_PATH>'||chr(10));
    ELSIF (REC.ACTION_TYPE='SQL') THEN
      dbms_lob.append(theFile,'<PARAM_PATH>' || rec.PARAM_PATH || '</PARAM_PATH>'||chr(10));
      dbms_lob.append(theFile,'<SQL_COMMAND> ' || chr(10)||' <![CDATA[  ' ||SUBSTR(rec.COMMAND, 1, 7) || ''''|| rec.PARAM_PATH ||'=''||' || SUBSTR(rec.COMMAND, 8) || '   ]]>' || chr(10)||'  </SQL_COMMAND>'||chr(10));
      dbms_lob.append(theFile,'<SQL_COMMAND_REPORT> ' || chr(10)||' <![CDATA[   ' || rec.COMMAND_REPORT || '   ]]>' || chr(10)||'  </SQL_COMMAND_REPORT>'||chr(10));
    END IF;
    IF (rec.OPERATOR_STRING is not NULL) THEN
      dbms_lob.append(theFile,'<OPERATOR>' || rec.OPERATOR_STRING || '</OPERATOR>'||chr(10));
    ELSE
      NULL;
    END IF;
    IF (rec.COMPARE_VALUE is not NULL) THEN
    dbms_lob.append(theFile,'<COMPARE_VALUE>' || rec.COMPARE_VALUE || '</COMPARE_VALUE>'||chr(10));
    ELSE
      NULL;
    END IF;
    dbms_lob.append(theFile,'<CANDIDATE_SYSTEMS>');
    FOR C_SYS IN CAND_SYS(checkId)
    LOOP
      dbms_lob.append(theFile, C_SYS.CAND_SYS_NAME || ':' );
      trimflag := true;
    END LOOP;
    IF (trimflag) THEN
      dbms_lob.trim(theFile,dbms_lob.getlength(theFile)-1);
      dbms_lob.append(theFile,'</CANDIDATE_SYSTEMS>'||chr(10));
      trimflag := false;
    ELSE
      dbms_lob.trim(theFile,dbms_lob.getlength(theFile)-19);
      trimflag := false;
    END IF;    
    IF (rec.COMPONENT_DEPENDENCY IS NOT NULL) THEN
      dbms_lob.append(theFile,'<COMPONENT_DEPENDENCY>' || rec.COMPONENT_DEPENDENCY || '</COMPONENT_DEPENDENCY>'||chr(10));
    ELSE
      NULL;
    END IF;
    dbms_lob.append(theFile,'<DATABASE_MODE>');
    FOR DBMODES IN DB_MODES(checkId)
    LOOP
      dbms_lob.append(theFile, DBMODES.DATABASE_MODE || ':');
      trimflag := true;
    END LOOP;
    IF (trimflag) THEN
      dbms_lob.trim(theFile,dbms_lob.getlength(theFile)-1);
      dbms_lob.append(theFile,'</DATABASE_MODE>'||chr(10));
      trimflag := false;
    ELSE
      dbms_lob.trim(theFile,dbms_lob.getlength(theFile)-15);
      trimflag := false;
    END IF;   
    IF (rec.ORACLE_HOME_TYPE is not NULL) THEN
      dbms_lob.append(theFile,'<ORACLE_HOME_TYPE>' || rec.ORACLE_HOME_TYPE || '</ORACLE_HOME_TYPE>'||chr(10));
    ELSE
      NULL;
    END IF;
    dbms_lob.append(theFile,'<DATABASE_TYPE>');
    FOR DBTYPES IN DB_TYPES(checkId)
    LOOP
      dbms_lob.append(theFile, DBTYPES.DATABASE_TYPE || ':' );
      trimflag := true;
    END LOOP;
    IF (trimflag) THEN
      dbms_lob.trim(theFile,dbms_lob.getlength(theFile)-1);
      dbms_lob.append(theFile,'</DATABASE_TYPE>'||chr(10));
      trimflag := false;
    ELSE
      dbms_lob.trim(theFile,dbms_lob.getlength(theFile)-15);
       trimflag := false;
    END IF;    
    dbms_lob.append(theFile,'<DATABASE_ROLE>');
    FOR DBROLES IN DB_ROLES(checkId)
    LOOP
      dbms_lob.append(theFile, DBROLES.DATABASE_ROLE || ':');
      trimflag := true;
    END LOOP;
    IF (trimflag) THEN
      dbms_lob.trim(theFile,dbms_lob.getlength(theFile)-1);
      dbms_lob.append(theFile,'</DATABASE_ROLE>'||chr(10));
      trimflag := false;
    ELSE
      dbms_lob.trim(theFile,dbms_lob.getlength(theFile)-15);
       trimflag := false;
    END IF;
   
    dbms_lob.append(theFile,'<ALERT_LEVEL>' || rec.ALERT_LEVEL || '</ALERT_LEVEL>'||chr(10));
    dbms_lob.append(theFile,'<PASS_MSG>  <![CDATA[   ' || rec.PASS_MSG || '   ]]> </PASS_MSG>'|| chr(10));
    dbms_lob.append(theFile,'<FAIL_MSG>  <![CDATA[   ' || rec.FAIL_MSG || '   ]]> </FAIL_MSG>'|| chr(10));
     IF (rec.BENEFIT_IMPACT is not NULL) THEN
      dbms_lob.append(theFile,'<BENEFIT_IMPACT>' ||chr(10) ||' <![CDATA[   ' || rec.BENEFIT_IMPACT || '   ]]>' || chr(10)||' </BENEFIT_IMPACT>'||chr(10));
    ELSE
      NULL;
    END IF;
     IF (rec.RISK is not NULL) THEN
      dbms_lob.append(theFile,'<RISK>' || chr(10)||' <![CDATA[   ' || rec.RISK || '   ]]>' || chr(10)||' </RISK>'||chr(10));
    ELSE
      NULL;
    END IF;
     IF (rec.ACTION_REPAIR is not NULL) THEN
     dbms_lob.append(theFile,'<ACTION_REPAIR>' || chr(10)||'  <![CDATA[   ' || rec.ACTION_REPAIR || '   ]]>' || chr(10)||' </ACTION_REPAIR>'||chr(10));
    ELSE
      NULL;
    END IF; 
    dbms_lob.append(theFile,'<LINKS>' ||chr(10));
    FOR LK_NAME IN LINKS(checkId)
    LOOP
      dbms_lob.append(theFile,'<LINK>  <![CDATA[   ' || LK_NAME.NAME || ' - ' || LK_NAME.LINK|| '   ]]> </LINK>'||chr(10));
      trimflag := true;
    END LOOP;
    IF (trimflag) THEN
      dbms_lob.append(theFile,'</LINKS>'||chr(10));
      trimflag := false;
    ELSE
     dbms_lob.trim(theFile,dbms_lob.getlength(theFile)-8);
      trimflag := false;
    END IF;
    dbms_lob.append(theFile,chr(10));
    dbms_lob.append(theFile,'</CHECK>'||chr(10));
    dbms_lob.append(theFile,chr(10));
  END LOOP;
  dbms_lob.append(theFile,'</UserDefinedChecks>'||chr(10));
  UPDATE RCA13_DOCS
  SET FILENAME='user_defined_checks'
    ||parampathseq.nextval
    ||'.xml'
  WHERE FILENAME='user_defined_checks.xml';
  BEGIN
    RCA13_DOCLIB.create_document_from_text('user_defined_checks.xml',theFile,TO_CHAR(sysdate,'MM/DD/YYYY HH24:MI:SS'),app_user);
    COMMIT;
  EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20001,DBMS_UTILITY.FORMAT_ERROR_STACK || ' ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
  END;
END UserDefPluginXml;
/
CREATE OR REPLACE FUNCTION rca13_getplatformlist(
    chk_id IN VARCHAR2)
  RETURN VARCHAR2
IS
  platform_list VARCHAR2(4000) := NULL;
BEGIN
  SELECT pname
  INTO platform_list
  FROM
    (SELECT check_id,
      listagg(rtrim(pname),',<br>') within GROUP (
    ORDER BY pname) pname
    FROM
      (SELECT check_id,
        pname
      FROM RCA13_ORACHK_CHECKS_PLATFORM acp,
        (SELECT DECODE(p.product_line_id, 23,'Solaris Sparc', 46,'Linuxx86', 226,'Linuxx8664', 59,'HP-UXPA-RISC', 197,'HP-UXItanium', 212,'AIX', 267,'Solarisx8664', 233,'MSWindowsx64(64-bit)', 209,'ZLinux(64-bit)')
          ||'-'
          ||rtrim(osdist)
          ||rtrim(osversion) pname,
          DISTRIBUTION_OS_ID
        FROM RCA13_DISTRIBUTION a,
          RCA13_PLATFORM p
        WHERE a.platform_id     = p.platform_id
        AND a.osdist_rep_kernel = 1
        ORDER BY pname
        ) t3
      WHERE acp.distribution_os_id = t3.distribution_os_id
      AND acp.check_id             = chk_id
      GROUP BY check_id,
        pname
      )ab
    GROUP BY CHECK_ID
    );
  dbms_output.put_line(platform_list);
  RETURN platform_list;
END;
/
CREATE OR REPLACE FUNCTION rca13_getversionlist(
    chk_id IN VARCHAR2)
  RETURN VARCHAR2
IS
  version_list VARCHAR2(4000) := NULL;
BEGIN
  SELECT vname
  INTO version_list
  FROM
    (SELECT check_id,
      listagg(vname,',<br>') within GROUP (
    ORDER BY vname) vname
    FROM
      (SELECT cv.check_id,
        vname
      FROM RCA13_ORACHK_CHECKS_VERSION cv,
        ( SELECT VERSION_NAME vname,version_id FROM RCA13_VERSION vv ORDER BY vname
        ) a
      WHERE cv.version_id = a.version_id
      AND check_id        = chk_id
      GROUP BY cv.check_id,
        vname
      ) ab
    GROUP BY CHECK_ID
    );
  RETURN version_list;
END;
/


CREATE OR REPLACE FUNCTION rca13_getcandsyslist(
    chk_id IN VARCHAR2)
  RETURN VARCHAR2
IS
  cand_sys_list VARCHAR2(4000) := NULL;
BEGIN
  SELECT cname
  INTO cand_sys_list
  FROM
    (SELECT check_id,
      listagg(cname,',<br>') within GROUP (
    ORDER BY cname) cname
    FROM
      (SELECT ccs.check_id,
        cname
      FROM RCA13_ORACHK_CHECKS_CAND_SYS ccs,
        (SELECT decode(cand_sys_name,'RACCHECK','RAC',
'SIDB','SINGLE INSTANCE',
'X2-2','EXADATA X2-2',
'X3-2','EXADATA X3-2',
'X4-2','EXADATA X4-2',
'X5-2','EXADATA X5-2',
'X2-8','EXADATA X2-8',
'X3-8','EXADATA X3-8',
'X4-8','EXADATA X4-8',
'X5-8','EXADATA X5-8',
'DBM','EXADATA V2',cand_sys_name) cname,
          cand_sys_id
        FROM RCA13_ORACHK_CAND_SYS cs
        ORDER BY cname
        ) a
      WHERE a.CAND_SYS_ID = ccs.CAND_SYS_ID
      AND check_id        = chk_id
      GROUP BY ccs.check_id,
        cname
      ) ab
    GROUP BY CHECK_ID
    );
  RETURN cand_sys_list;
END;
/
CREATE OR REPLACE FUNCTION rca13_getdbtypelist(
    chk_id IN VARCHAR2)
  RETURN VARCHAR2
IS
  dbtype_list VARCHAR2(4000) := NULL;
BEGIN
  SELECT dbname
  INTO dbtype_list
  FROM
    (SELECT check_id,
      listagg(dbname,', ') within GROUP (
    ORDER BY dbname) dbname
    FROM
      (SELECT cv.check_id,
        dbname
      FROM RCA13_ORACHK_CHECKS_DB_TYPES cv,
        (SELECT decode(database_type,'CDB','CONTAINER_DATABASE','PDB','PLUGGABLE_DATABASE',database_type) dbname,
          DATABASE_TYPE_ID
        FROM RCA13_ORACHK_DB_TYPES_MASTER vv
        ORDER BY dbname
        ) a
      WHERE cv.DATABASE_TYPE_ID = a.DATABASE_TYPE_ID
      AND check_id              = chk_id
      GROUP BY cv.check_id,
        dbname
      ) ab
    GROUP BY CHECK_ID
    );
  RETURN dbtype_list;
END;
/
CREATE OR REPLACE FUNCTION rca13_getdbrolelist(
    chk_id IN VARCHAR2)
  RETURN VARCHAR2
IS
  dbrole_list VARCHAR2(4000) := NULL;
BEGIN
  SELECT dbrole
  INTO dbrole_list
  FROM
    (SELECT check_id,
      listagg(dbrole,', ') within GROUP (
    ORDER BY dbrole) dbrole
    FROM
      (SELECT cv.check_id,
        dbrole
      FROM RCA13_ORACHK_CHECKS_DB_ROLES cv,
        (SELECT DATABASE_ROLE dbrole,
          DATABASE_ROLE_ID
        FROM RCA13_ORACHK_DB_ROLES_MASTER vv
        ORDER BY dbrole
        ) a
      WHERE cv.DATABASE_ROLE_ID = a.DATABASE_ROLE_ID
      AND check_id              = chk_id
      GROUP BY cv.check_id,
        dbrole
      ) ab
    GROUP BY CHECK_ID
    );
  RETURN dbrole_list;
END;
/
CREATE OR REPLACE FUNCTION rca13_getdbmodelist(
    chk_id IN VARCHAR2)
  RETURN VARCHAR2
IS
  dbmode_list VARCHAR2(4000) := NULL;
BEGIN
  SELECT dbmode
  INTO dbmode_list
  FROM
    (SELECT check_id,
      listagg(dbmode,', ') within GROUP (
    ORDER BY dbmode) dbmode
    FROM
      (SELECT cv.check_id,
        dbmode
      FROM RCA13_ORACHK_CHECKS_DB_MODES cv,
        (SELECT DATABASE_MODE dbmode,
          DATABASE_MODE_ID
        FROM RCA13_ORACHK_DB_MODES_MASTER vv
        ORDER BY dbmode
        ) a
      WHERE cv.DATABASE_MODE_ID = a.DATABASE_MODE_ID
      AND check_id              = chk_id
      GROUP BY cv.check_id,
        dbmode
      ) ab
    GROUP BY CHECK_ID
    );
  RETURN dbmode_list;
END;
/
CREATE OR REPLACE FUNCTION blob_to_xmltype (blob_in IN BLOB)
RETURN XMLTYPE
AS
v_clob CLOB;
v_varchar VARCHAR2(32767);
v_start PLS_INTEGER := 1;
v_buffer PLS_INTEGER := 32767;
BEGIN
DBMS_LOB.CREATETEMPORARY(v_clob, TRUE);

FOR i IN 1..CEIL(DBMS_LOB.GETLENGTH(blob_in) / v_buffer)
LOOP
v_varchar := UTL_RAW.CAST_TO_VARCHAR2(DBMS_LOB.SUBSTR(blob_in, v_buffer, v_start));
DBMS_LOB.WRITEAPPEND(v_clob, LENGTH(v_varchar), v_varchar);
v_start := v_start + v_buffer;
END LOOP;

RETURN XMLTYPE(v_clob);
END blob_to_xmltype;

/

CREATE OR REPLACE PROCEDURE bulkupload
IS
  x XMLType ;
   l_lob    NUMBER := 0;
BEGIN
  SELECT blob_to_xmltype(file_blob)
  INTO x
  FROM rca13_docs
  WHERE doc_id= (select doc_id from (select doc_id from rca13_docs where attr1='MAP_FILE' order by uploaded_on desc) where rownum<2);
  -- dbms_output.put_line(x);
  FOR r IN
  (SELECT ExtractValue(Value(p),'/mapping/systems/text()') AS system ,
    ExtractValue(Value(p),'/mapping/businessunit/text()')  AS lob
  FROM TABLE(XMLSequence(Extract(x,'/cm/mapping'))) p
  )
  LOOP
   SELECT COUNT(1) INTO l_lob FROM rca13_lobs WHERE upper(lob_name)=upper(r.lob);
    BEGIN
      IF l_lob = 0 THEN
        INSERT
        INTO rca13_lobs
          (
            lob_id,
            lob_name,
            created_by,
            created
          )
          VALUES
          (
            sys_guid(),
            r.lob,
            'MAPPING_USER',
            systimestamp
          );
        COMMIT;
      END IF;
    EXCEPTION
    WHEN dup_val_on_index THEN
       raise_application_error(-20001,DBMS_UTILITY.FORMAT_ERROR_STACK || ' ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    END;
    UPDATE rca13_lob2sys_mapping
    SET lob_id =
      (SELECT lob_id FROM rca13_lobs WHERE lob_name=upper(r.lob)
      )
    WHERE system_id =
      (SELECT system_id FROM rca13_systems WHERE system_name=r.system
      );
  END LOOP;
END;

/
prompt ...generate_currentmapping_xml
CREATE OR REPLACE PROCEDURE generate_currentmapping_xml( app_user VARCHAR2)
IS
  theFile CLOB;

  CURSOR cur_map
  IS
    SELECT upper(b.lob_name) lob_name,
      c.system_name system_name
    FROM rca13_lob2sys_mapping a,
      rca13_lobs b,
      rca13_systems c
    WHERE a.lob_id  = b.lob_id
    AND a.system_id = c.system_id
    ORDER BY LOB_NAME,
      system_name;
      
      begin

   theFile := '<?xml version="1.0" ?> '||chr(10);
  dbms_lob.append(theFile,'<cm>' || chr(10));
   FOR REC IN cur_map
  LOOP
   dbms_lob.append(theFile,'<mapping>' || chr(10));
   dbms_lob.append(theFile,'<systems>' || rec.system_name || '</systems>'||chr(10));
   dbms_lob.append(theFile,'<businessunit>' || rec.lob_name || '</businessunit>'||chr(10));
   dbms_lob.append(theFile,'</mapping>' || chr(10));
END LOOP;
dbms_lob.append(theFile,'</cm>'||chr(10));
  UPDATE RCA13_DOCS
  SET FILENAME='mapping'
    ||parampathseq.nextval
    ||'.xml'
  WHERE FILENAME='mapping.xml';
  BEGIN
    RCA13_DOCLIB.create_document_from_text('mapping.xml',theFile,TO_CHAR(sysdate,'MM/DD/YYYY HH24:MI:SS'),app_user);
    COMMIT;
  EXCEPTION
  WHEN OTHERS THEN
    raise_application_error(-20001,DBMS_UTILITY.FORMAT_ERROR_STACK || ' ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
  END;
END generate_currentmapping_xml;

/
declare
cnt number;
l_job_running number;
begin
for rec in ( select build_id bid from rca13_release_info order by build_id asc ) loop
  -- Upgrade app version by version
  if rec.bid = 20160516000000 then
   select count(1) into cnt from user_scheduler_jobs where job_name = 'RCA13_PURGE_JOB';
   if cnt = 0 then
   DBMS_SCHEDULER.CREATE_JOB (
   job_name           =>  'RCA13_PURGE_JOB',
   job_type           =>  'PLSQL_BLOCK',
   job_action         =>  'BEGIN RCA13_MANAGE_COLLECTIONS.purgeData(dat => systimestamp); END;',
   start_date         =>   systimestamp,
   repeat_interval    =>  'freq=monthly; interval=3; byminute=0; bysecond=0;', /*For every 3 months default */
   end_date           =>   NULL,
   enabled            =>   TRUE,
   auto_drop          =>   FALSE,
   comments           =>  'ORAchk App: Purge Job ');
   end if;
  end if;
  if rec.bid = 20160831000000 then
   select count(*) into l_job_running
     from user_scheduler_running_jobs
    where job_name = 'RCA13_PURGE_JOB';
   if (l_job_running = 1) then   
      begin
      dbms_scheduler.stop_job('RCA13_PURGE_JOB');
      exception when others then 
        null;
      end;
    end if;
    if(cnt = 1 ) then
      begin
      dbms_scheduler.drop_job('RCA13_PURGE_JOB');
       exception when others then 
       null;
      end;
    end if;
     begin
    DBMS_SCHEDULER.CREATE_JOB (
     job_name           => 'RCA13_PURGE_JOB',
     job_type           => 'PLSQL_BLOCK',
      job_action         => 'BEGIN RCA13_MANAGE_COLLECTIONS.purgeData(dat => systimestamp - 90); END;', -- clean data on every day basis
     start_date         =>  systimestamp,     
     repeat_interval    => 'freq=daily; interval=1; byminute=0; bysecond=0;', /*daily job to preserve only the recent <interval> data in the database */
     end_date           =>   NULL,
     enabled            =>   TRUE,
     auto_drop          =>   FALSE,
     comments           =>  'Purge Data Older than the specified interval');
     DBMS_SCHEDULER.enable ('RCA13_PURGE_JOB');
     exception when others then 
     null;
          end;
      end if;
 end loop;
end;
/ 
prompt ...done executing the upgrade supporting objects
-- Always this should get executed at last. 
prompt ...CM_Upgrade_Mode_Off
BEGIN
  UPDATE RCA13_INTRACK_PREFERENCES SET PREFERENCE_VALUE='N' WHERE PREFERENCE_NAME='CM_UPGRADE_MODE';
  COMMIT;
EXCEPTION
WHEN OTHERS THEN
  NULL;
END;
/
