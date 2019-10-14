SET SERVEROUTPUT ON

DECLARE
   v_num_disks    NUMBER;
   v_group_number   NUMBER;
   v_max_total_mb   NUMBER;

   v_required_free_mb   NUMBER;
   v_usable_mb      NUMBER;
   v_cell_usable_mb   NUMBER;
   v_one_cell_usable_mb   NUMBER;   
   v_enuf_free      BOOLEAN := FALSE;
   v_enuf_free_cell   BOOLEAN := FALSE;
   
   v_req_mirror_free_adj_factor   NUMBER := 1.10;
   v_req_mirror_free_adj         NUMBER := 0;
   v_one_cell_req_mir_free_mb     NUMBER  := 0;
   
   v_disk_desc      VARCHAR(10) := 'SINGLE';
   v_offset      NUMBER := 50;
   
   v_db_version   VARCHAR2(8);
   v_inst_name    VARCHAR2(1);
   
BEGIN

   SELECT substr(version,1,8), substr(instance_name,1,1)    INTO v_db_version, v_inst_name    FROM v$instance;
   
   IF v_inst_name <> '+' THEN
      DBMS_OUTPUT.PUT_LINE('ERROR: THIS IS NOT AN ASM INSTANCE!  PLEASE LOG ON TO AN ASM INSTANCE AND RE-RUN THIS SCRIPT.');
      GOTO the_end;
   END IF;

    DBMS_OUTPUT.PUT_LINE('------ DISK and CELL Failure Diskgroup Space Reserve Requirements  ------');
    DBMS_OUTPUT.PUT_LINE(' This procedure determines how much space you need to survive a DISK or CELL failure. It also shows the usable space ');
    DBMS_OUTPUT.PUT_LINE(' available when reserving space for disk or cell failure.  ');
   DBMS_OUTPUT.PUT_LINE(' Please see MOS note 1551288.1 for more information.  ');
   DBMS_OUTPUT.PUT_LINE('.  .  .');      
    DBMS_OUTPUT.PUT_LINE(' Description of Derived Values:');
    DBMS_OUTPUT.PUT_LINE(' One Cell Required Mirror Free MB : Required Mirror Free MB to permit successful rebalance after losing largest CELL regardless of redundancy type');
    DBMS_OUTPUT.PUT_LINE(' Disk Required Mirror Free MB     : Space needed to rebalance after loss of single or double disk failure (for normal or high redundancy)');
    DBMS_OUTPUT.PUT_LINE(' Disk Usable File MB              : Usable space available after reserving space for disk failure and accounting for mirroring');
    DBMS_OUTPUT.PUT_LINE(' Cell Usable File MB              : Usable space available after reserving space for SINGLE cell failure and accounting for mirroring');
   DBMS_OUTPUT.PUT_LINE('.  .  .');   

   IF v_db_version = '11.2.0.3' THEN
      v_req_mirror_free_adj_factor := 1.10;
      DBMS_OUTPUT.PUT_LINE('ASM Version: 11.2.0.3');
   ELSE
      v_req_mirror_free_adj_factor := 1.5;
      DBMS_OUTPUT.PUT_LINE('ASM Version: '||v_db_version||'  - WARNING DISK FAILURE COVERAGE ESTIMATES HAVE NOT BEEN VERIFIED ON THIS VERSION!');   
   END IF;
   
   DBMS_OUTPUT.PUT_LINE('.  .  .');      
      
   FOR dg IN (SELECT name, type, group_number, total_mb, free_mb, required_mirror_free_mb FROM v$asm_diskgroup ORDER BY name) LOOP

      v_enuf_free := FALSE;
     
     v_req_mirror_free_adj := dg.required_mirror_free_mb * v_req_mirror_free_adj_factor;
      
      -- Find largest amount of space allocated to a cell   
      SELECT sum(disk_cnt), max(max_total_mb), max(sum_total_mb)*v_req_mirror_free_adj_factor
     INTO v_num_disks, v_max_total_mb, v_one_cell_req_mir_free_mb
      FROM (SELECT count(1) disk_cnt, max(total_mb) max_total_mb, sum(total_mb) sum_total_mb 
      FROM v$asm_disk 
     WHERE group_number = dg.group_number 
     GROUP BY failgroup);     
     
      -- Eighth Rack
      IF dg.type = 'NORMAL' THEN
      
         -- Eighth Rack
         IF (v_num_disks < 36) THEN
            -- Use eqn: y = 1.21344 x+ 17429.8
            v_required_free_mb :=  1.21344 * v_max_total_mb + 17429.8;
            IF dg.free_mb > v_required_free_mb THEN v_enuf_free := TRUE; END IF;
         
         -- Quarter Rack
         ELSIF (v_num_disks >= 36 AND v_num_disks < 84) THEN 
            -- Use eqn: y = 1.07687 x+ 19699.3
            v_required_free_mb := 1.07687 * v_max_total_mb + 19699.3;
            IF dg.free_mb > v_required_free_mb THEN v_enuf_free := TRUE; END IF;
         
         -- Half Rack
         ELSIF (v_num_disks >= 84 AND v_num_disks < 168) THEN 
            -- Use eqn: y = 1.02475 x+53731.3
            v_required_free_mb := 1.02475 * v_max_total_mb + 53731.3;
            IF dg.free_mb > v_required_free_mb THEN v_enuf_free := TRUE; END IF;

         -- Full rack is most conservative, it will be default
         ELSE
            -- Use eqn: y = 1.33333 x+83220.
            v_required_free_mb := 1.33333 * v_max_total_mb + 83220;
            IF dg.free_mb > v_required_free_mb THEN v_enuf_free := TRUE; END IF;      
         
         END IF;
         
         -- DISK usable file MB
         v_usable_mb := ROUND((dg.free_mb - v_required_free_mb)/2);
         v_disk_desc := 'ONE disk';
         
         -- CELL usable file MB
         v_cell_usable_mb := ROUND( (dg.free_mb - v_one_cell_req_mir_free_mb)/2 );
         v_one_cell_usable_mb := v_cell_usable_mb;
       
      ELSE
         -- HIGH redundancy
         
         -- Eighth Rack
         IF (v_num_disks <= 18) THEN
            -- Use eqn: y = 4x + 0
            v_required_free_mb :=  4.0 * v_max_total_mb;
            IF dg.free_mb > v_required_free_mb THEN v_enuf_free := TRUE; END IF;
         
         -- Quarter Rack
         ELSIF (v_num_disks > 18 AND v_num_disks <= 36) THEN 
            -- Use eqn: y = 3.87356 x+417692.
            v_required_free_mb := 3.87356 * v_max_total_mb + 417692;
            IF dg.free_mb > v_required_free_mb THEN v_enuf_free := TRUE; END IF;
         
         -- Half Rack
         ELSIF (v_num_disks > 36 AND v_num_disks <= 84) THEN 
            -- Use eqn: y = 2.02222 x+56441.6
            v_required_free_mb := 2.02222 * v_max_total_mb + 56441.6;
            IF dg.free_mb > v_required_free_mb THEN v_enuf_free := TRUE; END IF;

         -- Full rack is most conservative, it will be default
         ELSE
            -- Use eqn: y = 2.14077 x+54276.4
            v_required_free_mb := 2.14077 * v_max_total_mb + 54276.4;
            IF dg.free_mb > v_required_free_mb THEN v_enuf_free := TRUE; END IF;      
         
         END IF;
      
         -- DISK usable file MB
         v_usable_mb := ROUND((dg.free_mb - v_required_free_mb)/3);      
         v_disk_desc := 'TWO disks';   
         
         -- CELL usable file MB
         v_one_cell_usable_mb := ROUND( (dg.free_mb - v_one_cell_req_mir_free_mb)/3 );
       
      END IF;
      
      DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------------------');
      DBMS_OUTPUT.PUT_LINE('DG Name: '||LPAD(dg.name,v_offset-9));
      DBMS_OUTPUT.PUT_LINE('DG Type: '||LPAD(dg.type,v_offset-9));
      DBMS_OUTPUT.PUT_LINE('Num Disks: '||LPAD(TO_CHAR(v_num_disks),v_offset-11));
      DBMS_OUTPUT.PUT_LINE('Disk Size MB: '||LPAD(TO_CHAR(v_max_total_mb,'999,999,999,999'),v_offset-14));  
      DBMS_OUTPUT.PUT_LINE('.  .  .');
      DBMS_OUTPUT.PUT_LINE('DG Total MB: '||LPAD(TO_CHAR(dg.total_mb,'999,999,999,999'),v_offset-13));
      DBMS_OUTPUT.PUT_LINE('DG Used MB: '||LPAD(TO_CHAR(dg.total_mb - dg.free_mb,'999,999,999,999'),v_offset-12));
      DBMS_OUTPUT.PUT_LINE('DG Free MB: '||LPAD(TO_CHAR(dg.free_mb,'999,999,999,999'),v_offset-12));
      DBMS_OUTPUT.PUT_LINE('.  .  .');     
      DBMS_OUTPUT.PUT_LINE('One Cell Required Mirror Free MB: '||LPAD(TO_CHAR(ROUND(v_one_cell_req_mir_free_mb),'999,999,999,999'),v_offset-34));
      DBMS_OUTPUT.PUT_LINE('.  .  .');          
      DBMS_OUTPUT.PUT_LINE('Disk Required Mirror Free MB: '||LPAD(TO_CHAR(ROUND(v_required_free_mb),'999,999,999,999'),v_offset-30));
      DBMS_OUTPUT.PUT_LINE('.  .  .');          
      DBMS_OUTPUT.PUT_LINE('Disk Usable File MB: '||LPAD(TO_CHAR(ROUND(v_usable_mb),'999,999,999,999'),v_offset-21));   
      DBMS_OUTPUT.PUT_LINE('Cell Usable File MB: '||LPAD(TO_CHAR(ROUND(v_one_cell_usable_mb),'999,999,999,999'),v_offset-21));   
      DBMS_OUTPUT.PUT_LINE('.  .  .');
      
      IF v_enuf_free THEN 
         DBMS_OUTPUT.PUT_LINE('Enough Free Space to Rebalance after loss of '||v_disk_desc||': PASS');
      ELSE
         DBMS_OUTPUT.PUT_LINE('Enough Free Space to Rebalance after loss of '||v_disk_desc||': FAIL');
      END IF;   

     IF dg.type = 'NORMAL' THEN
        -- Calc Free Space for Rebalance Due to Cell Failure
        IF v_req_mirror_free_adj < dg.free_mb THEN 
          DBMS_OUTPUT.PUT_LINE('Enough Free Space to Rebalance after loss of ONE cell: PASS');
        ELSE
          DBMS_OUTPUT.PUT_LINE('Enough Free Space to Rebalance after loss of ONE cell: WARNING (cell failure is very rare)');
        END IF;         
   ELSE
        -- Calc Free Space for Rebalance Due to Single Cell Failure
        IF v_one_cell_req_mir_free_mb < dg.free_mb THEN 
          DBMS_OUTPUT.PUT_LINE('Enough Free Space to Rebalance after loss of ONE cell: PASS');
        ELSE
          DBMS_OUTPUT.PUT_LINE('Enough Free Space to Rebalance after loss of ONE cell: WARNING (cell failure is very rare and high redundancy offers ample protection already)');
        END IF;
        
   END IF;
      
   END LOOP;
   
   <<the_end>>
   DBMS_OUTPUT.PUT_LINE('.  .  .');  
   DBMS_OUTPUT.PUT_LINE('Script completed.');
   
END;
/

