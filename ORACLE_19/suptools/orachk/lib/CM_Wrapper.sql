 declare
  l_workspace_id number;
  l_app_id number;
  l_schema varchar2(120);
  l_random number;
begin
  select workspace_id into l_workspace_id
  from apex_workspaces  where rownum < 2;
        SELECT application_id into l_app_id
FROM
  (SELECT application_id
  FROM APEX_APPLICATIONS
  WHERE lower(error_handling_function) LIKE '%rca13%'
  )
WHERE rownum < 2; 
SELECT SYS_CONTEXT('USERENV','CURRENT_SCHEMA') into l_schema FROM DUAL; 
SELECT DBMS_RANDOM.RANDOM into l_random from dual;
  apex_application_install.set_workspace_id( l_workspace_id );
  apex_application_install.set_application_id(l_app_id);
  apex_application_install.set_schema(l_schema);
  apex_application_install.set_application_alias(l_random);
  apex_application_install.generate_offset;
end;
/
set define '^'
column APEX_SCRIPT_FILE new_val APEX_SCRIPT_FILE
select case 
         when version_no like '5.%' then '$RAT_TOOLPATH/Apex5_CollectionManager_App.sql'
         else '$RAT_TOOLPATH/CollectionManager_App.sql'
       end APEX_SCRIPT_FILE
  from apex_release
/
prompt APEX_SCRIPT_FILE: "^APEX_SCRIPT_FILE."
@@^APEX_SCRIPT_FILE.
prompt ...Installing Upgrade Scripts
@@CM_UpgradeScript.sql
prompt ...Wrapper Execution ends
whenever oserror  exit 1 rollback
whenever sqlerror exit 1 rollback
commit;
exit











