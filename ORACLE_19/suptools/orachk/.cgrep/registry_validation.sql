Rem
Rem $Header: tfa/src/orachk/src/registry_validation.sql /main/2 2015/10/23 00:07:17 cgirdhar Exp $
Rem
Rem registry_validation.sql
Rem
Rem Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      registry_validation.sql - <one-line expansion of the name>
Rem
Rem    DESCRIPTION
Rem      <short description of component this file declares/defines>
Rem
Rem    NOTES
Rem      <other useful comments, qualifications, etc.>
Rem
Rem    BEGIN SQL_FILE_METADATA 
Rem    SQL_SOURCE_FILE: tfa/src/orachk/src/registry_validation.sql 
Rem    SQL_SHIPPED_FILE: 
Rem    SQL_PHASE: 
Rem    SQL_STARTUP_MODE: NORMAL 
Rem    SQL_IGNORABLE_ERRORS: NONE 
Rem    SQL_CALLING_FILE: 
Rem    END SQL_FILE_METADATA
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    cgirdhar    10/22/15 - Bug fix found in testing
Rem    cgirdhar    10/21/15 - script to check the consistency of database
Rem                           registory components
Rem    cgirdhar    10/21/15 - Created

SET SERVEROUTPUT ON format wrapped
SET LINE 80

BEGIN
  dbms_output.put_line(
    'SQL Registry validation script entry on ' || systimestamp);
END;
/


DECLARE
  -- If which = 'patch_id', returns the patch ID for the given bundle ID for
  -- the given series.  If which = 'bundle_id', returns the bundle ID for the
  -- given patch ID for the given series
  FUNCTION bundle_patch_info(bundle_series IN VARCHAR2,
                             id IN VARCHAR2,
                             which IN VARCHAR2)
    RETURN NUMBER IS
  BEGIN
    -- This somewhat convoluted code allows us to not have any DDL in this
    -- script.  It would be nice to put this info into a database table, but
    -- not for this version.
    IF bundle_series = 'PSU' THEN
      IF which = 'patch_id' THEN
        CASE id 
          WHEN 1 THEN RETURN 19303936;
          WHEN 2 THEN RETURN 19769480;
          WHEN 3 THEN RETURN 20299023;
          WHEN 4 THEN RETURN 20831110;
          WHEN 5 THEN RETURN 21359755;
        END CASE;
      ELSIF which = 'bundle_id' THEN
        CASE id 
          WHEN 19303936 THEN RETURN 1;
          WHEN 19769480 THEN RETURN 2;
          WHEN 20299023 THEN RETURN 3;
          WHEN 20831110 THEN RETURN 4;
          WHEN 21359755 THEN RETURN 5;
        END CASE;
      END IF;
    ELSIF bundle_series = 'DBBP' THEN
      IF which = 'patch_id' THEN
        CASE id
          WHEN 1 THEN RETURN 19189240;
          WHEN 2 THEN RETURN 19649591;
          WHEN 3 THEN RETURN 19878106;
          WHEN 4 THEN RETURN 20075921;
          WHEN 5 THEN RETURN 20243804;
          WHEN 6 THEN RETURN 20415006;
          WHEN 7 THEN RETURN 20594149;
          WHEN 8 THEN RETURN 20788771;
          WHEN 9 THEN RETURN 20950328;
          WHEN 10 THEN RETURN 21125181;
          WHEN 11 THEN RETURN 21359749;
          WHEN 12 THEN RETURN 21527488;
          WHEN 13 THEN RETURN 21694919;
        END CASE;
      ELSIF which = 'bundle_id' THEN
        CASE id
          WHEN 19189240 THEN RETURN 1;
          WHEN 19649591 THEN RETURN 2;
          WHEN 19878106 THEN RETURN 3;
          WHEN 20075921 THEN RETURN 4;
          WHEN 20243804 THEN RETURN 5;
          WHEN 20415006 THEN RETURN 6;
          WHEN 20594149 THEN RETURN 7;
          WHEN 20788771 THEN RETURN 8;
          WHEN 20950328 THEN RETURN 9;
          WHEN 21125181 THEN RETURN 10;
          WHEN 21359749 THEN RETURN 11;
          WHEN 21527488 THEN RETURN 12;
          WHEN 21694919 THEN RETURN 13;
        END CASE;
      END IF;
    END IF;
  END bundle_patch_info;

  -- Scan the SQL registry for the given series, and report any entries for
  -- which the recorded bundle ID does not match the known bundle ID (as
  -- returned by bundle_patch_info).
  PROCEDURE validate_registry(validate_series IN VARCHAR2) IS

    TYPE error_rec IS RECORD (
      registry_rowid ROWID,
      registry_bundle_id NUMBER,
      registry_patch_id NUMBER,
      known_bundle_id NUMBER);

    TYPE error_rec_tab IS TABLE OF error_rec
      INDEX BY BINARY_INTEGER;

    error error_rec;
    errors error_rec_tab;
    error_cnt NUMBER := 0;

    known_patch_id NUMBER;
    known_bundle_id NUMBER;

    highest_patch_id NUMBER;
    highest_bundle_id NUMBER;
  BEGIN
    dbms_output.put(
      'Validating SQL registry entries for bundle series ' || 
      validate_series || '...');

    -- Loop through the SQL registry looking for sucessful applies for
    -- the given series
    FOR registry_rec IN
      (SELECT patch_id, bundle_id, flags, rowid, description
         FROM dba_registry_sqlpatch
         WHERE bundle_series = validate_series
         AND action = 'APPLY'
         AND status = 'SUCCESS'
         AND version =
           (SELECT substr(version, 1, instr(version, '.', 1, 4) - 1)
              FROM v$instance)
         ORDER BY action_time) LOOP

      -- An apply with force will either have 'F' in the flags or an
      -- empty description since we don't use queryable inventory for force
      IF (INSTR(registry_rec.flags, 'F') != 0 OR
          registry_rec.description IS NULL) THEN
        -- We have a force apply, delete any existing errors
        errors.DELETE;
        error_cnt := 0;
      END IF;

      -- For each successful apply, validate the patch ID and bundle ID
      -- against bundle_patch_info
      known_patch_id :=
        bundle_patch_info(validate_series, registry_rec.bundle_id, 'patch_id');

      IF registry_rec.patch_id != known_patch_id THEN
        known_bundle_id :=
          bundle_patch_info(validate_series, registry_rec.patch_id,
                            'bundle_id');

        -- Found an entry whose bundle ID does not match the known ID
        error.registry_rowid := registry_rec.rowid;
        error.registry_bundle_id := registry_rec.bundle_id;
        error.registry_patch_id := registry_rec.patch_id;
        error.known_bundle_id := known_bundle_id;
        error_cnt := error_cnt + 1;
        errors(error_cnt) := error;

      END IF;
    END LOOP;

    IF error_cnt = 0 THEN
      dbms_output.put_line('No errors found');
    ELSE
      dbms_output.put_line('Errors found!');
      dbms_output.new_line;
      FOR i IN 1 .. error_cnt LOOP
        dbms_output.put_line(
          '  For registry rowid ' || errors(i).registry_rowid || ':');
        dbms_output.put_line(
          '  Bundle ID ' || errors(i).registry_bundle_id || 
          ' does not match known bundle ID ' || errors(i).known_bundle_id ||
          ' for patch ' || errors(i).registry_patch_id);
      END LOOP;

      dbms_output.new_line;

      -- Determine the highest bundle ID applied on the system. That is the
      -- one which should now be applied with -force to resolve the
      -- inconcistencies.  The patch should be present on the system.
      SELECT MAX(bundle_id)
        INTO highest_bundle_id
        FROM dba_registry_sqlpatch
        WHERE bundle_series = validate_series
        AND version =
          (SELECT substr(version, 1, instr(version, '.', 1, 4) - 1)
             FROM v$instance);

      highest_patch_id :=
        bundle_patch_info(validate_series, highest_bundle_id, 'patch_id');

      dbms_output.put_line(
        'Action: Run the following datapatch command to reinstall ID ' ||
        highest_bundle_id || ' for series ' || validate_series || ':');
      dbms_output.new_line;
      dbms_output.put_line(
        'datapatch -verbose -apply ' || highest_patch_id ||
        ' -force -bundle_series ' || validate_series);
      dbms_output.new_line;
      dbms_output.put_line(
        'datapatch can be run from any node in a RAC cluster, without needing');
      dbms_output.put_line(
        'to take a downtime.  It is not necessary to bounce the database.');
    END IF;
  END validate_registry;

BEGIN
  -- Determine all bundle series in the current registry and call
  -- validate_registry for each
  FOR series_rec IN (
    SELECT DISTINCT bundle_series
      FROM dba_registry_sqlpatch
      WHERE version =
        (SELECT substr(version, 1, instr(version, '.', 1, 4) - 1)
           FROM v$instance)) LOOP
    validate_registry(series_rec.bundle_series);
  END LOOP;
END;
/

BEGIN
  dbms_output.put_line(
    'SQL Registry validation script complete on ' || systimestamp);
END;
/


