Rem
Rem $Header: tfa/src/v2/tfa_home/resources/sql/srdc_get_dead_txn.sql /main/1 2018/05/28 15:06:27 bburton Exp $
Rem
Rem srdc_get_dead_txn.sql
Rem
Rem Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
Rem
Rem    NAME
Rem      srdc_get_dead_txn.sql 
Rem
Rem    DESCRIPTION
Rem      Query for dead transactions.
Rem
Rem    BEGIN SQL_FILE_METADATA
Rem    SQL_SOURCE_FILE: tfa/src/v2/tfa_home/resources/sql/srdc_get_dead_txn.sql
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
set echo on;
spool dead.log

select u.inst# instid, u.name, u.status$, x.ktuxeusn usn, x.ktuxeslt slt, x.ktuxesqn wrp, x.ktuxesiz undoblocks
from   x$ktuxe x, undo$  u
where  x.ktuxeusn = u.us#
and    x.ktuxesta = 'ACTIVE'
and    x.ktuxecfl like '%DEAD%' ;

spool off
@?/rdbms/admin/sqlsessend.sql
