Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_db_undo_recommendation_10g.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_db_undo_recommendation_10g.sql
Rem
Rem Copyright (c) 2017, 2018, Oracle and/or its affiliates. 
Rem All rights reserved.
Rem
Rem    NAME
Rem      srdc_db_undo_recommendation_10g.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_db_undo_recommendation_10g.sql
Rem    SQL_SHIPPED_FILE:
Rem    SQL_PHASE:
Rem    SQL_STARTUP_MODE: NORMAL
Rem    SQL_IGNORABLE_ERRORS: NONE
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bburton     09/22/17 - check the current undo configuration and provides
Rem                           recommendation based on the previous workload.
Rem    bburton     09/22/17 - Created
Rem

@@?/rdbms/admin/sqlsessstart.sql
REM srdc_undo_recommendation_10g.sql
REM check the current undo configuration and provides recommendation based on the previous workload..
define SRDCNAME='DB_Undo_Recommendation_10g'
set pagesize 200 verify off sqlprompt "" term off entmap off echo off
set markup html on spool on
COLUMN SRDCSPOOLNAME NOPRINT NEW_VALUE SRDCSPOOLNAME
select 'SRDC_'||upper('&&SRDCNAME')||'_'||upper(instance_name)||'_'|| to_char(sysdate,'YYYYMMDD_HH24MISS') SRDCSPOOLNAME from v$instance;
spool &&SRDCSPOOLNAME..htm
select 'Diagnostic-Name ' "Diagnostic-Name ", '&&SRDCNAME' "Report Info" from dual
union all
select 'Time ' , to_char(systimestamp, 'YYYY-MM-DD HH24MISS TZHTZM' ) from dual
union all
select 'Machine ' , host_name from v$instance
union all
select 'Version ',version from v$instance
union all
select 'DBName ',name from v$database
union all
select 'Instance ',instance_name from v$instance
/

SET SERVEROUTPUT ON
SET LINES 600
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

DECLARE
    v_analyse_start_time    DATE := SYSDATE - 7;
    v_analyse_end_time      DATE := SYSDATE;
    v_cur_dt                DATE;
    v_undo_info_ret         BOOLEAN;
    v_cur_undo_mb           NUMBER;
    v_undo_tbs_name         VARCHAR2(100);
    v_undo_tbs_size         NUMBER;
    v_undo_autoext          BOOLEAN;
    v_undo_retention        NUMBER(5);
    v_undo_guarantee        BOOLEAN;
    v_instance_number       NUMBER;
    v_undo_advisor_advice   VARCHAR2(100);
    v_undo_health_ret       NUMBER;
    v_problem               VARCHAR2(1000);
    v_recommendation        VARCHAR2(1000);
    v_rationale             VARCHAR2(1000);
    v_retention             NUMBER;
    v_utbsize               NUMBER;
    v_best_retention        NUMBER;
    v_longest_query         NUMBER;
    v_required_retention    NUMBER;
BEGIN
    select sysdate into v_cur_dt from dual;
    DBMS_OUTPUT.PUT_LINE(CHR(9));
    DBMS_OUTPUT.PUT_LINE('- Undo Analysis started at : ' || v_cur_dt || ' -');
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------');

    v_undo_info_ret := DBMS_UNDO_ADV.UNDO_INFO(v_undo_tbs_name, v_undo_tbs_size, v_undo_autoext, v_undo_retention, v_undo_guarantee);
    select sum(bytes)/1024/1024 into v_cur_undo_mb from dba_data_files where tablespace_name = v_undo_tbs_name;

    DBMS_OUTPUT.PUT_LINE('NOTE:The following analysis is based upon the database workload during the period -');
    DBMS_OUTPUT.PUT_LINE('Begin Time : ' || v_analyse_start_time);
    DBMS_OUTPUT.PUT_LINE('End Time   : ' || v_analyse_end_time);
    
    DBMS_OUTPUT.PUT_LINE(CHR(9));
    DBMS_OUTPUT.PUT_LINE('Current Undo Configuration');
    DBMS_OUTPUT.PUT_LINE('--------------------------');
    DBMS_OUTPUT.PUT_LINE(RPAD('Current undo tablespace',55) || ' : ' || v_undo_tbs_name);
    DBMS_OUTPUT.PUT_LINE(RPAD('Current undo tablespace size (datafile size now) ',55) || ' : ' || v_cur_undo_mb || 'M');
    DBMS_OUTPUT.PUT_LINE(RPAD('Current undo tablespace size (consider autoextend) ',55) || ' : ' || v_undo_tbs_size || 'M');
    IF V_UNDO_AUTOEXT THEN
        DBMS_OUTPUT.PUT_LINE(RPAD('AUTOEXTEND for undo tablespace is',55) || ' : ON');  
    ELSE
        DBMS_OUTPUT.PUT_LINE(RPAD('AUTOEXTEND for undo tablespace is',55) || ' : OFF');  
    END IF;
    DBMS_OUTPUT.PUT_LINE(RPAD('Current undo retention',55) || ' : ' || v_undo_retention);

    IF v_undo_guarantee THEN
        DBMS_OUTPUT.PUT_LINE(RPAD('UNDO GUARANTEE is set to',55) || ' : TRUE');
    ELSE
        dbms_output.put_line(RPAD('UNDO GUARANTEE is set to',55) || ' : FALSE');
    END IF;
    DBMS_OUTPUT.PUT_LINE(CHR(9));

    SELECT instance_number INTO v_instance_number FROM V$INSTANCE;

    DBMS_OUTPUT.PUT_LINE('Undo Advisor Summary');
    DBMS_OUTPUT.PUT_LINE('---------------------------');

    v_undo_advisor_advice := dbms_undo_adv.undo_advisor(v_analyse_start_time, v_analyse_end_time, v_instance_number);
    DBMS_OUTPUT.PUT_LINE(v_undo_advisor_advice);

    DBMS_OUTPUT.PUT_LINE(CHR(9));
    DBMS_OUTPUT.PUT_LINE('Undo Space Recommendation');
    DBMS_OUTPUT.PUT_LINE('-------------------------');

    v_undo_health_ret := dbms_undo_adv.undo_health(v_analyse_start_time, v_analyse_end_time, v_problem, v_recommendation, v_rationale, v_retention, v_utbsize);
    IF v_undo_health_ret > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Minimum Recommendation           : ' || v_recommendation);
        DBMS_OUTPUT.PUT_LINE('Rationale                        : ' || v_rationale);
        DBMS_OUTPUT.PUT_LINE('Recommended Undo Tablespace Size : ' || v_utbsize || 'M');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Allocated undo space is sufficient for the current workload.');
    END IF;
    
    SELECT dbms_undo_adv.best_possible_retention(v_analyse_start_time, v_analyse_end_time) into v_best_retention FROM dual;
    SELECT dbms_undo_adv.longest_query(v_analyse_start_time, v_analyse_end_time) into v_longest_query FROM dual;
    SELECT dbms_undo_adv.required_retention(v_analyse_start_time, v_analyse_end_time) into v_required_retention FROM dual;

    DBMS_OUTPUT.PUT_LINE(CHR(9));
    DBMS_OUTPUT.PUT_LINE('Retention Recommendation');
    DBMS_OUTPUT.PUT_LINE('------------------------');
    DBMS_OUTPUT.PUT_LINE(RPAD('The best possible retention with current configuration is ',60) || ' : ' || v_best_retention || ' Seconds');
    DBMS_OUTPUT.PUT_LINE(RPAD('The longest running query ran for ',60) || ' : ' || v_longest_query || ' Seconds');
    DBMS_OUTPUT.PUT_LINE(RPAD('The undo retention required to avoid errors is ',60) || ' : ' || v_required_retention || ' Seconds');

END;
/

set echo off 
set sqlprompt "SQL> " term on 
set verify on 
set markup html off 
PROMPT
PROMPT
PROMPT REPORT GENERATED : &SRDCSPOOLNAME..htm
set verify on echo on
@?/rdbms/admin/sqlsessend.sql
 
