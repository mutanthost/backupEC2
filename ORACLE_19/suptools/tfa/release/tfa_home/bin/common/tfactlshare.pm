# 
# $Header: tfa/src/v2/tfa_home/bin/common/tfactlshare.pm /st_tfa_19/5 2019/03/11 22:30:19 gadiga Exp $
#
# tfactlshare.pm
# 
# Copyright (c) 2014, 2019, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlshare.pm - Shared Functionality Module
#
#    DESCRIPTION
#      Trace File Analyzer Control Utility 
#
#    NOTES
#      tfactl [-verbose {errors|warnings|normal|info|debug|none}] [command] 
#
#    MODIFIED   (MM/DD/YY)
#    gadiga      03/11/19 - wait for CRS to start from new home
#    gadiga      11/27/18 - wait for securethread
#    gadiga      11/07/18 - handle client add failues
#    gadiga      10/11/18 - tomcat certificates
#    bburton     09/24/18 - Fix diag/rdbms issues
#    cnagur      09/24/18 - Add DB Owner to ACL after DB Discovery
#    bibsahoo    01/31/19 - commons-io upgrade to version 2.6
#    llakkana    11/27/18 - Add orachk staleness check
#    bburton     09/19/18 - Add update cipher suite
#    bburton     09/13/18 - Fix some file permissions bug 28605375
#    cnagur      08/14/18 - ADW Upload Changes
#    llakkana    08/13/18 - Append discovery output to tfa setup file instead
#    manuegar    08/05/18 - XbranchMerge manuegar_dbutils16 from main
#    recornej    08/03/18 - Add permissions to dbversions.json
#    manuegar    07/30/18 - manuegar_dbutils16.
#    gadiga      07/23/18 - handle special characters
#    bburton     07/17/18 - Bug 28100803 - ODA: SUPPORT ACR (REDACTION) OPTIONS
#    recornej    07/17/18 - Fix returning codes from runOratop
#    recornej    07/17/18 - Add tfactlshare_setup_tool_dir_for_all_users to the
#    manuegar    07/11/18 - Bug 28250934 - LNX-191-TFA:THE NORMAL RETURN CODE
#                           OF TFACTL DIAGCOLLECT -EXAMPLE IS NON-ZERO =1.
#    manuegar    07/09/18 - Bug 28250972 - OGG:SHD:TFACTL DIAGCOLLECT FAILS W/
#                           CAN'T CREATE..COMMON/TFACTLSHARE.PM LINE.
#    cnagur      07/09/18 - Fix for Bug 28255625
#    bburton     07/05/18 - change our debugging flags so tools can use -v flag
#                           - 27981844
#    manuegar    07/05/18 - manuegar_dbutils14.
#    bibsahoo    07/03/18 - FIX BUG 28095265
#    bibsahoo    06/27/18 - Fix Bug 28255236
#    recornej    06/25/18 - Replacing IS_OFFLINEMODE for isOfflineMode since
#                           some code does not go through tfactl and
#                           IS_OFFLINEMODE does not get set
#    gadiga      06/25/18 - add atp config
#    bibsahoo    06/19/18 - FIX BUG 28206670
#    recornej    05/31/18 - Adding SUPPORT_MODE=TRUE tfa_setup.txt to detect 
#                           that we are in NON_DAEMON when running as root
#    bibsahoo    05/31/18 - Removing events and search from tfa external tools
#                           and fix bug 27908189
#    bburton     05/29/18 - XbranchMerge bburton_1820_rel_fixes_txn from
#                           st_tfa_18.2.0.0.0
#    bburton     05/28/18 - check for responsefile existance before trying scp
#    bburton     05/21/18 - Do not run in background for stop action as may be
#                           part of uninstall
#    bibsahoo    05/18/18 - FIX BUG 27845377
#    recornej    05/21/18 - Adding dbcheck.
#    recornej    05/10/18 - Remove extra " and add ORACLE_HOME to timeline.out
#    recornej    05/08/18 - Bug 27913251 - TFAT: SEVERAL TFACTL SET COMMANDS
#                           ACCEPTS INVALID VALUES
#    manuegar    05/10/18 - manuegar_secure_validate_db_account.
#    bburton     05/10/18 - Ensure serialized data files are accessible after
#                           patching.
#    cnagur      05/07/18 - Notification using smtp.properties
#    cnagur      05/02/18 - Support for Orachk Autostart
#    manuegar    05/04/18 - Bug 27963911 - LNX-18.1-TFA:TRACKING BUG IN ORDER
#                           TO SOLVE DIFFS IN SHORT REGRESS (SREGRESS).
#    cnagur      05/02/18 - Support for Orachk Autostart
#    recornej    04/30/18 - Bug 27802752 - TFAT: DIAGCOLLECT -FROM YYYY-MM-DD
#                           ACCEPTS OTHER COMMANDS AS LS -L
#    manuegar    04/24/18 - Bug 27669677 - TFAT: INSTALLING TFA -JAVAHOME IS
#                           IGNORED.
#    recornej    04/23/18 - Prevent awk: cmd. line:1: {printawk: cmd. line:1: ^
#                           unexpected newline or end of string.
#    manuegar    04/19/18 - BUG 27630414 - TFAT: RUNNING TFACTL RUN COMMANDS AS
#                           NON-ROOT RETURNS AN INVALID EXIT CODE.
#    manuegar    04/17/18 - XbranchMerge manuegar_oratopfx from
#                           st_tfa_pt-quarterly.12.2.1.2.0
#    recornej    04/16/18 - Adding sudocmds routines.
#    recornej    04/16/18 - LNX-191-TFA:ANALYZE ORATOP HIT PERMISSION ISSUE
#                           ABOUT LOG FILE
#    cnagur      04/13/18 - Updated Lucene jars from 6.1 to 6.6
#    bibsahoo    04/05/18 - clusterwide tfactl search fix
#    recornej    04/02/18 - Bug 27707652 - TFA SRDC DBPERF NOT COLLECTING AWR
#                           OR STATSPACK ON WINDOWS
#    llakkana    04/02/18 - Support blackout
#    bibsahoo    03/19/18 - Adding messagehandler compatibility for
#    bibsahoo    03/19/18 - Adding messagehandler compatibility for
#                           TFAIndexSearcher
#    bburton     03/19/18 - Bug 27665984 - remove use of POSIX::tmpnam
#    bburton     03/19/18 - Bug 27700626 - set offset for scan to 0 if saved offset greater than filesize.
#    recornej    03/16/18 - Add help for availability.
#    recornej    03/05/18 - Fix /dev/stdout: Permission denied in AIX.
#    manuegar    03/05/18 - XbranchMerge manuegar_bug-27426241 from st_tfa_18.1
#    bburton     02/28/18 - Add jars for Event Watching
#    migmoren    02/23/18 - Bug 27016008 - WS2012_18.1_TFA: TFACTL SUMMARY HUNG
#                           WITH SPECIFIC PARAMETERS??
#    manuegar    02/12/18 - manuegar_shared_dbutils03.
#    migmoren    02/09/18 - Bug 26372349 - TFACTL MANAGELOGS -SHOW USAGE
#                           -DATABASE NOT PRODUCING ANY OUTPUT
#    recornej    02/08/18 - Bug 26985786 - WS2012_18.1_TFA: UNEXPECTED WARNING
#                           FOR 'TFACTL SUMMARY -NODE
#    bburton     02/07/18 - 27510341 - not setting up orachk correctly
#    manuegar    02/02/18 - manuegar_shared_dbutils01.
#    recornej    02/02/18 - Bug 26261699 - AIX TFA SRDC ORA600 NOT SHOWING ALL
#                           ORA600 EVENTS
#    bibsahoo    01/31/18 - tfactl events lucene support
#    cnagur      01/15/18 - Fix for Bug 27366823
#    gadiga      01/09/18 - add receiver using cred file
#    recornej    12/15/17 - Adding permissions for tfactldbutlcmds.xml and
#                           tfactldbutlschedule.xml
#    manuegar    11/16/17 - manuegar_oratopfx.
#    bburton     11/08/17 - Allow for responsefile
#    recornej    11/07/17 - Fix parser when a line does not match.
#    bburton     11/03/17 - Fix indent
#    bburton     11/02/17 - Sort SRDC's in the help print
#    bburton     11/02/17 - bug 26662651
#    cnagur      10/25/17 - Fix for Bug 27003625
#    recornej    10/24/17 - Add world read permission to tfa_directories.
#    recornej    10/18/17 - Adding -L to tfactlshare_run_a_sql.
#    manuegar    10/12/17 - manuegar_diffs_permdenied_pt.
#    recornej    10/09/17 - Fix tfactlshare_run_a_sql for file type.
#    gadiga      12/06/17 - fix LIBPATH
#    migmoren    11/30/17 - Bug 27169539 - UNMATCHED BRACKET IN THE SYNTAX OF
#                           "TFACTL ANALYZE -HELP
#    manuegar    01/26/18 - Bug 27426241 - AIX-18.1-TFA:COLLECT IPS FILE FAILED
#                           WITH INTERNAL ERROR.
#    gadiga      11/27/17 - add ora.tfa after receiver starts
#    gadiga      11/16/17 - umask
#    cnagur      11/07/17 - Configure Cipher Suite
#    migmoren    11/03/17 - Bug 26430655 18.1: ENABLING ACCESS FOR NON-ROOT
#                           USERS ERROR DURING TFA FOR SINGLE INSTANCE DB
#    migmoren    10/26/17 - Bug 24593985 - LNX64-12.2-TFA: TFA ANALYZE DID NOT
#                           CATCH ORA-07445 IN IOS ALERT LOG
#    manuegar    11/16/17 - manuegar_oratopfx.
#    cnagur      10/25/17 - Fix for Bug 27003625
#    cnagur      10/23/17 - Fix for Bug 26967090
#    gadiga      10/17/17 - fix 26950849. add jaspic-api.jar
#    cnagur      10/25/17 - Fix for Bug 27003625
#    bburton     10/12/17 - fix su issues
#    manuegar    10/09/17 - Bug 26891075 - ERROR: CAN NOT RUN 'FINDSTR' AS USER
#    manuegar    10/09/17 - Bug 26891075 - ERROR: CAN NOT RUN 'FINDSTR' AS USER
#                           DIRECTORIES ARE NOT YET SETUP.
#    bibsahoo    09/29/17 - FIX BUG 26885894
#    bburton     09/29/17 - Stop error message when dbparams does not exist
#    manuegar    09/27/17 - manuegar_bug-26030846.
#    recornej    09/20/17 - Adding errorstack module to srdc parser
#    bburton     09/26/17 - Fix orachk for exachk on Exadata
#    manuegar    09/20/17 - manuegar_ips_diffs.
#    bibsahoo    09/19/17 - FIX BUG 26817718
#    anmathad    09/17/17 - Clear ACFS
#    gadiga      09/14/17 - setup metadata directory for clients
#    gadiga      09/13/17 - su issue
#    gadiga      09/12/17 - fix 24486169
#    gadiga      09/07/17 - add missing clients
#    migmoren    09/01/17 - Bug 26739287 - LNX64-12.2-TFA:FARM DIFFS IN
#                           SREGRESS/TFATEVENTS.TSC
#    bburton     08/29/17 - fixtfactl need to correct the slashes on windows
#    recornej    08/24/17 - Adding windows support for tfactlshare_run_a_sql
#    bibsahoo    08/24/17 - FIX BUG 25985303
#    gadiga      08/23/17 - solaris changes
#    gadiga      08/23/17 - try adding user with shell
#    chchoudh    08/23/17 - changing permissions for tfaosutils.pl file for
#                           tomcat
#    gadiga      08/22/17 - export tfactlshare_check_acfs
#    recornej    08/18/17 - Bug 25578876 - LNX64-12.2-CALOG: THE NORMAL RETURN
#                           CODE OF "TFACTL RUN CALOG" IS NON-ZERO = 255 (added 
#                           tfactlshare_getReferenceName to get name of a 
#                           reference). 
#    cnagur      08/18/17 - Fix for Bug 26650090
#    bburton     08/16/17 - bug 26227144 summary -h running scripts
#    manuegar    08/16/17 - Bug 26638658 - LNX64-12.2-TFA:TFA-00404 XML FILE IS
#                           NOT WELL FORMED WHEN RUNNING -SRDC DBPERF.
#    manuegar    08/14/17 - Bug 26619915 - LNX64-12.2-TFA:ORATOP DOES NOT WORK
#                           WHEN DB UNIQUE NAME DIFFERS FROM DBNAME.
#    gadiga      08/09/17 - fix issue opening rconfig
#    recornej    08/07/17 - Bug 24957744 - TFACTL PARAM FOR DATABASE NOT
#                           WORKING AS EXPECTED
#    cnagur      08/07/17 - Fix for Bug 26581956
#    migmoren    08/03/17 - Bug 26542624 - LNX-18.1-TFACTL: UNMATCHED BRACKET
#                           IN THE SYNTAX OF "TFACTL ANALYZE -HELP"
#    cnagur      08/01/17 - ADE ND Changes - Bug 26544813
#    bibsahoo    07/26/17 - FIX BUG 26536025
#    manuegar    07/26/17 - Bug 26522767 - LNX-18.1-TFA:IPS GET
#                           METADATA/MENIFEST HIT SYNTAX ERROR.
#    bibsahoo    07/24/17 - FIX BUG 26517864
#    cnagur      01/02/18 - Update perms of GIHOME/bin/tfactl
#    bburton     07/25/17 - Add dbua specific
#    manuegar    07/21/17 - manuegar_srdc_xmlparser.
#    cnagur      07/21/17 - Set publicIp to true in ODA Dom0 - Bug 26502871
#    recornej    07/19/17 - Adding file permission to sqlhc.sql
#    manuegar    07/19/17 - Bug 26270696 - LNX64-12.2-TFA:NON ROOT INSTALL,
#                           DIAGCOLLECT -ALL DID NOT COLLECT CRS/ASM FILES.
#    recornej    07/17/17 - Adding tfactlshare_is_statspack_installed sub
#    bibsahoo    07/17/17 - WINDOWS 12.2.1.2.0 FIX
#    manuegar    07/14/17 - Bug 25913670 - LNX64-12.2-TFA:PLS REMOVE MSG OF
#                           BUNDLED TOOLS FROM HELP.
#    bibsahoo    07/12/17 - FIX BUG 26413598
#    bburton     07/10/17 - Need to handle non daemon using tfa_base for
#                           discovery
#    chchoudh    07/10/17 - getting repository location in TFARMain_start
#                           depending on cluster type
#    chchoudh    07/06/17 - returning repository based on cluster type
#    bburton     07/06/17 - adjust Xmx again due to OOM issues
#    cnagur      06/28/17 - Fix for Bug 26359311
#    cnagur      06/28/17 - Fix for Bug 26364006
#    manuegar    06/27/17 - Bug 25873130 - LNX64-12.2-TFA: JAVA EXCEPTION WHEN
#                           RUNNING TFACTL DUE TO LINK FOLDER.
#    manuegar    06/27/17 - Bug 26255668 - LNX64-12.2-TFA:IPS UNPACK WITH ROOT
#                           USER HIT CP MISSING FILE OPERAND.
#    bburton     06/26/17 - 26148204 - TFACTL DIAGCOLLECT HIT ALARM CLOCK
#    gadiga      06/25/17 - use srvctl instead of crsctl for tfa resource
#    bburton     06/23/17 - adjust memory for very large systems
#    manuegar    06/23/17 - Bug 26321595 - LNX64-12.2-TFA:TFA IPS DID NOT GET
#                           METADATA FROM THE IPS PACKAGE.
#    chchoudh    06/22/17 - generating random password for receiver.jks and
#                           receiver client and encrypting it
#    manuegar    06/21/17 - Bug 24603499 - LNX64-112-CMT: TFA SHOULD IMPROVE
#                           THE ERROR MEG OF EXACHK TOOL ON ODALITE.
#    bibsahoo    06/19/17 - FIX BUG 25901835
#    chchoudh    06/16/17 - adding tfarcv client to receiver
#    bburton     06/15/17 - JVM change under 16GB use 64, 16 to 64 use 128
#                           above that use 256M
#    bibsahoo    06/09/17 - FIX BUG 26245066
#    bburton     06/05/17 - changes for no bash
#    gadiga      06/05/17 - print stb help only when it exists
#    bibsahoo    05/30/17 - tfa_windows_fix
#    manuegar    05/29/17 - Bug 26081910 - LNX64-12.2-TFA-IPS:THE PACKAGE WAS
#                           NOT GENERATED IN PROPER PATH.
#    bburton     05/26/17 - No Receiver Jars
#    cnagur      05/24/17 - Fix for Bug 24971982
#    llakkana    05/24/17 - Fix issue with cloud dirs add
#    manuegar    05/24/17 - manuegar_srdcwin09.
#    bibsahoo    05/23/17 - FIX BUG 26127514
#    cpujar      05/23/17 - XbranchMerge cpujar_bug-26117592 from
#                           st_tfa_12.2.1.1.01
#    bibsahoo    05/23/17 - FIX BUG 26127514
#    cpujar      05/22/17 - Summary bug 26117592
#    llakkana    05/24/17 - Fix issue with cloud dirs add
#    cpujar      05/22/17 - Summary bug 26117592 
#    bburton     05/22/17 - Not copying buildid correctly on ND upgrade
#    cpujar      05/19/17 - XbranchMerge cpujar_bug-26090405 from
#                           st_tfa_12.2.1.1.01
#    bibsahoo    05/18/17 - FIX BUG 26093490 
#    bburton     05/22/17 - Not copying buildid correctly on ND upgrade
#    bburton     05/18/17 - Get PERL from correct tfa_setup in Non Daemon
#    cpujar      05/17/17 - Summary bug 26090405
#    recornej    05/16/17 - Bug 26035086 - TFA NON-DAEMON MODE : TFACTL
#                           DIAGCOLLECT -IPS -INCIDENT HANGS
#    bibsahoo    05/16/17 - FIX BUG 26084594
#    bibsahoo    05/16/17 - FIX BUG 26084594
#    bibsahoo    05/15/17 - FIX BUG 26077963
#    gadiga      05/15/17 - exception handling
#    bibsahoo    05/15/17 - FIX BUG 26077963
#    bibsahoo    05/11/17 - FIX BUG 26043844 - WS2012_122_TFA: TFA INSTALLATION
#                           FAILING ABRUPTLY IN WINDOWS
#    manuegar    05/10/17 - manuegar_srdcwin07.
#    bburton     05/09/17 - Use our JRE on Cloud
#    manuegar    05/08/17 - XbranchMerge manuegar_srdcwin03 from
#                           st_tfa_12.2.1.1.01
#    manuegar    05/04/17 - manuegar_srdcwin03.
#    chchoudh    04/20/17 - generating and exporting certificates for receiver,
#                           functions for starting and stopping receiver
#                           process, and moved rconfig.properties file to
#                           tfahome/receiver/internal
#    manuegar    04/27/17 - manuegar_srdcwin01
#    gadiga      04/25/17 - fix 25941751. strong password
#    cnagur      04/21/17 - Fix for Bug 25921131
#    manuegar    04/20/17 - manuegar_srdcwin_shared.
#    cnagur      04/19/17 - Remove tfar.jar - Bug 25915789
#    manuegar    04/18/17 - Bug 25879789 - LNX64-12.2-TFA:DBPERF ABORT, CAN'T
#                           LOCATE ASCIITABLE.PM.
#    cnagur      04/07/17 - TFA Syncnode Message - Bug 24971982
#    bburton     04/07/17 - add getorainvloc
#    manuegar    04/06/17 - manuegar_windows_srdc01.
#    manuegar    04/05/17 - Bug 25717009 - LNX64-12.2-TFA-FCF: DIAG DIRECTORY
#                           WAS CREATED IN TFA_HOME FOR GI INSTALL.
#    bibsahoo    04/05/17 - TFA_WIN_NONDAEMON_SUPPORT
#    cnagur      04/04/17 - ADE ND Patch Issue - Bug 24424884
#    gadiga      04/04/17 - fix tomcat startup
#    bburton     03/27/17 - Fix debug print
#    manuegar    03/24/17 - emsrdc01
#    cnagur      03/21/17 - Bug 25549984 - Add Dir Issue for /net /opt
#    cnagur      03/17/17 - Fix for Bug 25459702
#    bibsahoo    03/10/17 - FIX BUG 25602989 - WS2012_122_TFA: TFACTL
#                           REDISCOVER IN WINDOWS SHOWS SHELL ERRORS
#    bburton     03/09/17 - XbranchMerge bburton_remove_activation_jar_txn from
#                           st_tfa_12.2.0.1.0 - activation.jar removal only.
#    bburton     02/27/17 - remove ref to runCellODScan
#    manuegar    02/24/17 - Bug 25616726 - WS2012_122_TFA: NO ADR HOMEPATHS
#                           WERE PROCESSED.
#    recornej    02/23/17 - CData support to XML Parser
#    manuegar    02/23/17 - Bug 25605875 - WS2012_122_TFA: TFACTL IPS
#                           <IPS_COMMAND> RETURNS TFA-00207.
#    bibsahoo    02/21/17 - TFA_WINDOWS_ANALYZE_OPTION
#    cnagur      02/13/17 - Non-Root Daemon Changes
#    llakkana    02/09/17 - API for buildCLIJava call
#    chchoudh    02/01/17 - Adding jars to classpath, and updating
#                           logging.properties in tfa_home/tomcat instead of
#                           crs_home/tomcat.
#    chchoudh    01/31/17 - moving tomcat base from tfa_home to crs_home
#    manuegar    01/24/17 - EM SRDC.
#    cnagur      01/22/17 - Added getTFABuild and printTFAVersion
#    bburton     01/16/17 - SRDC changes
#    cnagur      01/04/17 - Non Daemon Perl Issues - Bug 25349797
#    manuegar    01/03/17 - Bug 25208337 - LNX64-12.2-TFA: DID NOT COLLECT IPS
#                           PACKAGE,ORACLE_HOME ENV VARIABLE NOT SET.
#    cnagur      01/03/17 - Fix for Bug 25047967
#    manuegar    01/02/17 - Bug 25208337 - LNX64-12.2-TFA: DID NOT COLLECT IPS
#                           PACKAGE,ORACLE_HOME ENV VARIABLE NOT SET.
#    manuegar    01/02/17 - Bug 25290118 - WS2012_122_TFA: DUPLICATE 'IPS' IN
#                           HELP INFORMATION FOR 'TFACTL DIAGCOLLECT'.
#    cnagur      12/21/16 - Added flag -sigalg to keytool - Bug 25250496
#    gadiga      12/20/16 - add scriptagent timeout
#    cpujar      12/13/16 - Added set jvmXmxMB
#    cnagur      12/12/16 - Support for Open JDK - Bug 25237278
#    llakkana    11/30/16 - XbranchMerge bburton_fix_nslookup from
#                           st_tfa_12.1.2.8
#    manuegar    11/29/16 - Bug 25160573 - HPI-122-TFA:NEED TFACTL DIAGCOLLECT
#                           -DATABASE USAGE WHEN COLLECTING DATABASE LOG.
#    llakkana    11/29/16 - Fail if the running user is not the TFA_HOME owner
#                           or has keys
#    cnagur      11/24/16 - TFA ADE Install Changes
#    cnagur      11/17/16 - Fix for Bug 25104870
#    manuegar    11/17/16 - Bug 25107736 - LNX64-12.2-TFA:COMMAND NOT FOUND
#                           WHEN EXECUTING "TFACTL IPS SHOW INCIDENTS".
#    manuegar    11/15/16 - Bug 25100004 - LNX64-12.2-TFA: DIA-48458 WHEN
#                           EXECUTION TFACTL IPS SHOW INCIDENTS.
#    manuegar    11/10/16 - Bug 25067812 - TFA NON-DAEMON MODE : 'TFACTL IPS
#                           SHOW PROBLEMS' NEEDS ORACLE_HOME INPUT TWICE.
#    cnagur      11/09/16 - Fix for Bug 25046805
#    cnagur      11/03/16 - Fix for Bug 25039956 and 25039605
#    manuegar    11/01/16 - Bug 24948477 - WS2012_122_TFA: HELP INFORMATION FOR
#                           'TFACTL RUN GREP' INCORRECT.
#    manuegar    10/31/16 - Bug 24948455 - WS2012_122_TFA: 'TFACTL RUN EXACHK'
#                           DOES NOT WORK.
#    bburton     10/27/16 - run_a_sql not tmp
#    manuegar    10/27/16 - manuegar_srdc_14.
#    gadiga      10/26/16 - changes for scriptagent. bug 24929232
#    manuegar    10/25/16 - manuegar_extract_tfa_03. Added -setup to support
#                           first time ND configuration.
#    manuegar    10/24/16 - Bug 24944080 - LNX64-12.2-TFA:PRINT_HELP IS NOT
#                           PRINTING THE ERROR MESSAGE.IT ONLY PRINTS USAGE.
#    manuegar    10/20/16 - Bug 24924277 - TFA NON-DAEMON MODE : ERROR: LIST OF
#                           PROCESS IDS MUST FOLLOW -P.
#    manuegar    10/18/16 - Bug 24901215 - SOLSP-12.2-TFA:TFACTL DIAGCOLLECT
#                           HIT MANY SHELL-INIT:ERROR RETRIEVING CWD:GETCW.
#    bibsahoo    10/14/16 - Removing variable CURRENT_USER
#    cnagur      10/14/16 - Fix for Bug 24749005
#    arupadhy    10/13/16 - Changed Xmx Params from 512 to 256
#    bburton     10/11/16 - fix adding CRS_HOME - no line feed - 24830439
#    cpujar      10/04/16 - Bug 22575820 - CHANGIN OSWBB INTERVAL 
#                           IS NOT PROPOAGATED TO THE CLUSTER.
#    cnagur      10/03/16 - Disable Non-Daemon Mode for root
#    bburton     09/29/16 - fix scripts permissions
#    cnagur      09/27/16 - Added tfactlshare_getConfiguredComputeNodes
#    manuegar    09/27/16 - Bug 24744769 - TFA NON-DAEMON MODE: SH: - : INVALID
#                           OPTION DURING INSTALLATION (-EXTRACTTO).
#    bibsahoo    09/26/16 - GI HOME INCONSISTENCY AND TFA INSTALLATION ORDER IN
#                           NODES OF A CLUSTER
#    bburton     09/22/16 - changes for odalite
#    cpujar      09/20/16 - 22004118 - TFA INSTALL SHOULD CHK JAVA HOME 
#                           IN SAME PATH ON ALL NODES
#    manuegar    09/20/16 - Bug 24509905 - WS2012_122_TFA: NO HELP INFORMATION
#                           FOR TFA TOOLS.
#    manuegar    09/19/16 - Bug 24593717 - LNX64-12.2-TFA: IPS UNPACK PACKAGE
#                           GOT DIFFERENT RESULT WITH ADRCI IPS UNPACK.
#    chchoudh    09/15/16 - fix for BUG 24358789 - LNX64-12.2-TFA: NEED HELP
#                           MESSAGE FOR 'TFACTL CLIENT TO MANAGE/LIST MC
#                           CLIENTS
#    cnagur      09/14/16 - TFA Client Logging
#    arupadhy    09/14/16 - Added rdbms/trace for intermidiate dump of trace
#                           files done by database
#    cpujar      09/07/16 - handle tooltype
#    bibsahoo    09/06/16 - WINDOWS TYPICAL INSTALL BUGS
#    manuegar    08/30/16 - Bug 24555932 - SOLSP64-12.2-TFA: IPS COLLECTION BY
#                           TFA WAS TERNIMATED AUTOMATICALLY.
#    gadiga      08/30/16 - fix mount issue
#    manuegar    08/25/16 - Support the -extractto switch in the TFA installer.
#    gadiga      08/24/16 - use globals
#    arupadhy    08/23/16 - added fix for 24503359 - for windows path matching
#                           while comparing files listed in inventory
#    gadiga      08/23/16 - permissions on server.xml
#    gadiga      08/23/16 - secure cred management
#    manuegar    08/17/16 - Bug 24424939 - TFA NON-DAEMON MODE : NEWLY ADDED
#                           DIRECTORY NOT GETTING LISTED.
#    gadiga      08/09/16 - update jvmXmx parameter based on system
#    cnagur      08/04/16 - Fix for Bug 24406363
#    bburton     08/02/16 - Handle ASMIO alert log
#    cnagur      08/02/16 - XbranchMerge cnagur_tfa_bug_24331821_txn from main
#    sgoggi      08/02/16 - remove quotes inn java_home, update tfactlshare_get_clients 
#    bibsahoo    07/26/16 - FIX BUG 24351183
#    manuegar    07/26/16 - Bug 23142090 - [DB12.2]TFA: FAIL TO EXECUTE TFACTL
#                           ANALYZE COMP DB SEARCH ORA.
#    sgoggi      07/26/16 - remove quotes inn java_home
#    manuegar    07/25/16 - BUG 24307398 - LNX64-12.2-TFA:OUTPUTS OF TFACTL
#                           DIAGCOLLECT -EXAMPLES IS INCOMPLETE AND TRIMMED.
#    cnagur      07/22/16 - Fix for Bug 24331821
#    gadiga      07/19/16 - remove kafka
#    cnagur      07/19/16 - Updated tfactlshare_updateClusterMode
#    cnagur      07/13/16 - Fix for Bug 23747476
#    
#    cnagur      07/13/16 - Updated printConfig and setFlag
#    gadiga      07/12/16 - use /mnt/oracle.tfa
#    manuegar    07/11/16 - Support IPS in non daemon mode.
#    arupadhy    07/07/16 - print receiver node to be connected on client add
#    arupadhy    07/07/16 - Added support for aliases and platform for support
#                           tool
#    cnagur      07/07/16 - ADE Non-Daemon Mode Changes
#    arupadhy    07/04/16 - Added managelogs autopurge support
#    arupadhy    07/01/16 - Checking base address for oracle home exists before
#                           writing into the file, fix for BUG - 23713531
#    gadiga      06/28/16 - fix 23623021
#    arupadhy    06/27/16 - Creating a file for windows usergroups , so that
#                           tfaservice.exe which runs with NT AUTHORITY\SYSTEM
#                           is able to obtain the user details using the group
#                           names
#    arupadhy    06/24/16 - Made support tool framework compatible with windows
#    cnagur      06/23/16 - Fix for Bug 23639817
#    sgoggi      06/22/16 - create log location for tomcat and zk processes
#    arupadhy    06/21/16 - Appropriate message for unsupported tools on Windows
#    manuegar    06/20/16 - Dynamic help part 4.
#    gadiga      06/14/16 - use PERL
#    amchaura    06/14/16 - get repository location from config.properties
#    llakkana    06/13/16 - File Permission changes
#    manuegar    06/10/16 - Dynamic help part 3.
#    arupadhy    06/09/16 - Added getcommandlocation support for windows
#    cnagur      06/21/16 - Fix for Bug 23624186
#    bburton     06/08/16 - add time comparison function
#    manuegar    06/08/16 - Handle no adr basepaths for TFA IPS.
#    manuegar    06/08/16 - Fixed getValidDateFromString.
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    bburton     06/06/16 - remove some unneeded execute permissions
#    cnagur      06/01/16 - SI Changes for TFA 121280
#    bibsahoo    06/02/16 - Windows Typical Install
#    gadiga      06/02/16 - setup acfs
#    manuegar    06/02/16 - Performance improvement for TFA IPS.
#    sgoggi      06/01/16 - tfactlshare_update_rprop, monitor tfar_monitor only if producer
#    bburton     06/01/16 - Fix MTS Issue
#    llakkana    05/30/16 - ADE Non-Daemon changes
#    bburton     05/27/16 - use classpath env instead of commandline
#    cnagur      05/27/16 - XbranchMerge cnagur_tfa_121260_cell_issues_txn from
#                           st_tfa_12.1.2.6
#    gadiga      05/25/16 - get robjects
#    sgoggi      05/25/16 - monitor tfar_monitor output directory
#    ahmehta     05/24/16 - Bug Fixed 23311344 : <tfactl print receivers> will
#                           not display receiver information in DSC mode
#    gadiga      05/24/16 - start tomcat in nonssl mode also
#    manuegar    05/23/16 - Bug 23274045 - WS2012_122_TFA: NO WARNING FOR
#                           INCORRECT PARAMETERS ON TFACTL PROMPT.
#    manuegar    05/23/16 - Bug 23280916 - LNX64-12.2-TFA: SHOULD UPGRADE THE
#                           EXAMPLE IN DIAGCOLLECT HELP MSGS.
#    arupadhy    05/18/16 - Component duplicate ignore validation and removal
#                           of ALL option
#    manuegar    05/17/16 - Disable the RDA callout for ips pack.
#    arupadhy    05/16/16 - Enabled full discovery for windows
#    arupadhy    05/16/16 - Help fix and added specific .bat extension
#    arupadhy    05/13/16 - Added support for disk usage monitor and it's
#                           interval, change in tfactlshare_get_users as it was
#							not providing correct details
#    manuegar    05/12/16 - Xbr a few SRDC validations from 121280 to Main.
#    manuegar    05/12/16 - Bug 23249612 - LNX64-12.2-TFA:IPS PACK LIST
#                           DUPLICATE ORACLE HOMES
#    bburton     05/12/16 - also look in sbin for commands
#    bburton     05/11/16 - add a function to check a user is a dba for a given
#                           db (ORAHOME)
#    manuegar    04/29/16 - SRDC validations.
#    bibsahoo    04/29/16 - TFA DISCOVERY TO PERL
#    gadiga      04/28/16 - add r.port
#    amchaura    04/21/16 - Fix Bug 20459386 - LNX64-12.2-TFA:UNEXPECTED RESULT
#                           WITH TFACTL HOST ADD/REMOVE
#    amchaura    04/18/16 - Fix nonroot pidfile permissions
#    cnagur      04/14/16 - Added tfactlshare_getCommandLocation
#    manuegar    04/13/16 - Bug 23082552 - SOLSP-12.2-TFA:TFACTL DIAGCOLLECT
#                           HIT MANY SHELL-INIT:ERROR RETRIEVING.
#    manuegar    04/12/16 - Bug 23094679 - LNX64-12.2-TFA:NO SUCH FILE OR
#                           DIRECTORY WHEN RUNNING DIAGCOLLECT FOR PRE 12.2.
#    manuegar    04/11/16 - Setup user directories for support tools.
#    ahmehta     04/11/16 - Bug 22855636 - LNX64-12.2-TFA:NEED HELP MESSAGE FOR START/STOP RWEB 
#    amchaura    04/11/16 - tfactlshare_managestop tfactlshare_managestart
#    amchaura    04/10/16 - add isTFARunning
#    manuegar    04/08/16 - Bug 23001722 - LNX64-12.2-TFA-FPF:DIAGCOLLECT EXIT
#                           WITH NOT FOUND ADR HOMEPATHS WITH STACK DOWN.
#    arupadhy    04/06/16 - Oracle Home identification in windows through
#                           registry
#    amchaura    04/06/16 - replace checkTFAMain with isTFARunning to check for
#                           TFA process
#    bburton     04/06/16 - add srdc tools directory
#    cnagur      04/04/16 - Fixed perm issues with cell logs
#    manuegar    03/31/16 - Performance improvement for tfactl.
#    amchaura    03/28/16 - configurable deafult collection time range
#    amchaura    03/25/16 - Report failure in adding non root access
#    arupadhy    03/24/16 - add_to_scan_db made compatible with windows
#    manuegar    03/22/16 - Capture errors for ips show incidents.
#    arupadhy    03/24/16 - add_to_scan_db made compatible with windows
#    manuegar    03/23/16 - Dynamic help.
#    arupadhy    03/21/16 - Proper directory creation in case of windows using
#                           escaped username
#    cnagur      03/21/16 - Fix for Bug 22917407
#    manuegar    03/18/16 - Bug 22907263 - LNX64-12.2-TFA-MSG: HIT "ERROR: 13:
#                           PERMISSION DENIEDADDITIONAL INFORMATION: 1".
#    amchaura    03/17/16 - Fix 22892392, 22960013
#    manuegar    03/16/16 - Bug 22907263 - LNX64-12.2-TFA-MSG: HIT "ERROR: 13:
#                           PERMISSION DENIEDADDITIONAL INFORMATION: 1".
#    manuegar    03/14/16 - Fix diag directories for non root users.
#    cnagur      03/08/16 - Fix for Bug 22892392
#    gadiga      03/08/16 - update lucene
#    gadiga      03/08/16 - update lucene.
#    manuegar    03/03/16 - Run TFA Ips collections as ADR homepath owner.
#    manuegar    03/02/16 - Bug 21886221 - [12201-LIN64-TFA]OUTPUT OF PRINT
#                           DIRECTORIES IS NOT FRIENDLY.
#    bburton     03/02/16 - chomp what we read from cellips - bug 22861051
#    cnagur      02/29/16 - Fix for Bug 22670738
#    cnagur      02/29/16 - Fix for Bug 22841096
#    amchaura    02/26/16 - Fix Bug 18474041 - LNX64-12.1-TFA-SCS:REFUSE
#                           COLLECTION WHEN LOCAL NODE DID NOT CREATE THIS DB
#    amchaura    02/23/16 - Upgrade BDB version to 6.4.25
#    manuegar    02/23/16 - Change TFA IPS destination to suptools directory.
#    arupadhy    02/22/16 - added sleep after tfa_win_startup for avoiding race
#                           with initstart
#    cnagur      02/18/16 - Copy JRE and Perl for SI
#    sgoggi      02/17/16 - koption
#    cnagur      02/15/16 - Changes for JAVA_HOME on Cells
#    bburton     02/12/16 - fix rhp
#    amchaura    02/10/16 - sync certificates through sockets if non GI TFA
#                           Install
#    bibsahoo    02/08/16 - FIX BUG 21311855 - TFA : DATE NEW FORMAT SUPPORT
#    amchaura    02/08/16 - collect only valid also-collect component
#    cnagur      02/08/16 - Updated addDirectory - removed -l check
#    arupadhy    02/05/16 - getting tfa process id directly from tasklist
#    gadiga      02/05/16 - remove da
#    llakkana    02/04/16 - Fix 22626841
#    cnagur      02/03/16 - TFA SI Changes - Bug 22647922
#    bburton     02/02/16 - remove reference to NLS config vars for now
#    amchaura    02/01/16 - 22636619 - TFA AUTO COLLECT ENHANCEMENTS
#                           CLUSTERWIDE AND NOTIFICATION
#    manuegar    01/28/16 - Bug 22601081 - LNX64-12.2-TFA:TFA ACCESS ACCOUNTS
#                           ARE NOT BEING CREATED PROPERLY.
#    arupadhy    01/22/16 - refactored windows process management functions
#    arupadhy    01/17/16 - file permission change, directory/file
#                           identification handled in the permission changing
#                           perl routine itself.file permission changes for non
#                           root access.added function which provides escaped
#                           windows non root user name which allows proper file
#                           and folder creation
#    llakkana    01/28/16 - Fix 21892988: Issue with Blocked users
#    bburton     01/26/16 - write debug on install to logfile
#    manuegar    01/25/16 - Support ips collections on windows.
#    manuegar    01/25/16 - Bug 22573000 - AIX-12.2-TFA: TFACTL IPS PACK FAILED
#                           TO LIST ADR HOME.
#    arupadhy    01/22/16 - refactored windows process management functions
#    bburton     01/21/16 - fix bad opc path
#    cnagur      01/21/16 - Changes for JCS Dumps
#    bburton     01/19/16 - add RACDBCLOUD
#    arupadhy    01/17/16 - file permission change, directory/file
#                           identification handled in the permission changing
#                           perl routine itself.file permission changes for non
#                           root access.added function which provides escaped
#                           windows non root user name which allows proper file
#                           and folder creation
#    manuegar    01/19/16 - Bug 22537346 - TFA : TFA DIAGCOLLECT FAILS WHEN
#                           DIAG DIR IS IN NON-DEFAULT LOC $ORACLE_HOME/LOG.
#    cnagur      01/18/16 - Fix for Bug 22563770
#    gadiga      01/17/16 - start tfar monitor job
#    cnagur      01/14/16 - Changes for Java 8
#    amchaura    01/12/16 - Fix Bug 22520253 - TFA FAILS TO INSTALL ON ODA DOM0
#    gadiga      01/14/16 - moe common receiver functions
#    manuegar    01/13/16 - TFA IPS Windows porting.
#    llakkana    01/12/16 - Performacne: Call java process directly instead of
#                           calling from perl
#    arupadhy    01/10/16 - Added registry key AUTO_START for enable/disable,
#                           and auto reboot support for TFAService.exe if it
#                           stops by any reason.
#    manuegar    01/11/16 - Declare help inside XML files.
#    llakkana    01/08/16 - JDK8 Related changes
#    cnagur      01/07/16 - JCS help cleanup
#    bburton     01/07/16 - change -nomonitor to -silent
#    manuegar    01/07/16 - Added support for integration tfa option all_files.
#    arupadhy    01/04/16 - Setting proper device null for windows
#    llakkana    12/29/15 - Add tfactlshare_trim_nodelist
#    cnagur      12/23/15 - Fix for Bug 22064626
#    bibsahoo    12/17/15 - FIX BUG 22064785 - LNX64-12.2-TFA:ACCESS LSUSERS
#                           PRINT INCORRECT STATUS OF REMOTE NODES
#    manuegar    12/17/15 - Bug 21552846 - LNX64-12.2-TFA-IPS:GENERATE PACKAGE
#                           REPORT EXECUTION OF IPS TIMED OUT.
#    amchaura    12/15/15 - 22315724 - CONFIGURABLE MINIMUM SECURITY LEVEL FOR
#                           TFA
#    cnagur      12/14/15 - Changes to update JAVA_HOME
#    manuegar    12/14/15 - Added pool for TFA IPS Parallel Processing.
#    manuegar    12/09/15 - Support CRS when specifying the full ADR homepath
#                           for the -adrhomepath switch.
#    arupadhy    12/07/15 - windows specfic changes for copytfactl, fixTfactl,
#                           updatepropertiesfiles,
#                           tfactlshare_updateAutoDiagcollect
#    manuegar    12/07/15 - Bug 21648528 - LNX64-12.2-TFA-IPS:IPS PACK DID NOT
#                           WORK.
#    manuegar    12/04/15 - Bug 22193743 - TFA : ADR BASE SELECTION FROM
#                           MULTIPLE ADR BASE.
#    cnagur      12/03/15 - Updated setFlag
#    manuegar    12/02/15 - Bug 22274156 - SOLX64-12.2-TFA:UNEXPECTED MESSAGE
#                           SH:ORACLE_HOME=XXX: IS NOT AN INDENTIFIER.
#    manuegar    12/01/15 - Allow TFA IPS pack manipulation for non root users.
#    cnagur      11/30/15 - Fix for Bug 21948793
#    manuegar    11/30/15 - Bug 22283921 - TFA : TFA DIAGCOLLECT NOT WORKING
#                           FOR AN INCIDENT WHEN THERE ARE > 50 INC.
#    amchaura    11/26/15 - Fix BUG 22142600 - TFA : AUTODIAGCOLLECT EVENT
#                           TRIGGERING FOR 'SYSTEM STATE DUMP'
#    manuegar    11/26/15 - Bug 22274372 - TFA: ADR HOMES ON LOCAL STORAGES FOR
#                           RAC DATABASE NOT RECOGNIZED ON SOLARIS.
#    amchaura    11/16/15 - Fix Bug 22215978 - LNX64-12.2-TFA:DID NOT PRINT
#                           RDBMS COMPONENT
#    manuegar    11/12/15 - Bug 22148186 - TFA : ISSUE WITH TFA DIAGCOLLECTION
#                           ON REMOTE NODES FOR AN INCIDENT.
#    llakkana    11/10/15 - Fix merge conflicts issues of bibsahoo_bug-21913831
#    cnagur      10/20/15 - Changes for SI
#    gadiga      11/09/15 - ade env
#    manuegar    11/06/15 - Bug 22162809 - TFA : INCIDENT DIAG COLLECT NOT
#                           WORKING.
#    cnagur      11/12/15 - Updated updateTFABase for JCS
#    cnagur      11/03/15 - Changes for .buildversion
#    llakkana    10/28/15 - Fix 22089037. Show run help conditionally
#    manuegar    10/27/15 - Bug 22103108 - TFA :DIAGCOLLCTION FOR ASM INCIDENT
#                           DON'T CONTAIN ALERT,TRACE AND INCIDENT FILES.
#    manuegar    10/26/15 - Bug 22077161 - TFA: INCIDENT BASED DIAGCOLLECTION
#                           FROM DEFAULT $ORACLE_HOME/DIAG DIR.
#    arupadhy    10/23/15 - made getlistofothernodes compatible with windows
#    manuegar    10/23/15 - Bug 21943932 - LNX64-12.2-TFA:TFAC HIT DIA-49428:
#                           NO SUCH DIRECTORY OR DIRECTORY NOT ACCESSIBLE.
#    cnagur      10/22/15 - Added NODE_TYPE in ADE Env
#    gadiga      10/20/15 - XbranchMerge gadiga_osw_fixes_12126 from
#                           st_tfa_12.1.2.6
#    amchaura    10/19/15 - Fix Bug 22067005 - USER GENERATED CERTIFICATES NEED
#                           TO BE SET TO ROOT READ ONLY
#    amchaura    10/16/15 - Fix Bug 22006135 - TFA : ISSUE WITH DEFAULT
#                           DIAGNOSTIC_DEST LOCATION TFA MONITORING
#    arupadhy    10/16/15 - crs_discovery generic path structure
#    manuegar    10/16/15 - Bug 22006571 - LNX64-12.2-TFA:TFA IPS DID NOT GET
#                           ADR_HOME WITH DIFFERENT USER.
#    manuegar    10/15/15 - Bug 21983649 - TFA : TFA DIAGCOLLECT FOR AN
#                           INCIDENT COLLECTING TOO MANY TRACE FILES.
#    bibsahoo    10/15/15 - FIX BUG 21913831 - [12201-LIN64-TFA] TFACTL ACCESS
#                           DISABLE SHOULD GIVE CONSISTENT MSG
#    llakkana    10/13/15 - Add help for oratop -d option
#    cnagur      10/08/15 - Added syncnodes to tfactl
#    arupadhy    10/07/15 - chmod changes, added default path in C drive for
#                           temp location in windows, changes related to
#                           updateSSLConfig to accomodate windows ssl update as
#                           oneliner perl was not executing properly on
#                           windows, changed code to get list of all nodes
#                           which was working on grep and awk, change related
#                           to ssl restart for windows by killing the TFAMain
#                           PIDs
#    arupadhy    10/07/15 - Default behaviour for capturing interrupt signal,
#                           issue was caused when there was a child process in
#                           action, when INTERRUPT signal was sent
#    gadiga      10/01/15 - print correct status in case TFA is not running
#    gadiga      10/20/15 - enable/disable loc change
#    gadiga      09/28/15 - dont spool oratop interactive
#    gadiga      09/28/15 - fix 21054368
#    gadiga      09/26/15 - shell pattern support
#    cnagur      09/25/15 - Remove SIGAR
#    amchaura    09/23/15 - Fix Bug 21886027 - [12201-LIN64-TFA]PRINT CONFIG
#                           GIVE WRONG RESULT RESPONSE TO -NAME OPTION
#    manuegar    09/24/15 - Bug 21768769 - LNX64-12.2-TFA: IPS FILES SHOULD BE
#                           COLLECTED IN PARALLEL.
#    cnagur      09/23/15 - XbranchMerge cnagur_tfa_jcs_support_txn from
#                           st_tfa_12.1.2.5
#    arupadhy    09/21/15 - Branching at File ownership change for windows
#                           inserting TFA_HOME path hardcoded in tfactl.bat,
#                           function to get perl from tfahome_setup.txt
#    arupadhy    09/16/15 - Added double quote which led to path mismatch
#    bburton     09/11/15 - XbranchMerge bburton_bug-21517312 from
#                           st_tfa_12.1.2.5
#    bburton     09/11/15 - XbranchMerge bburton_bug-21517347 from
#                           st_tfa_12.1.2.5
#    arupadhy    09/11/15 - added robocopy routines, changed parent to base
#                           while using Win32, start of windows service,
#                           getting directory size for windows, service
#                           management routines
#    amchaura    09/09/15 - Fix Bug 21811849 - MISSPELLED WORD WHEN VIEWING
#                           ORATOP OPTIONS
#    manuegar    09/08/15 - Bug 21761611 - SOLSP-12.2-APPCRS-TFA: DUPLICATE
#                           MESSAGE HAPPENS WHEN COLLECTING TFA LOGS.
#    manuegar    09/07/15 - Bug 21785398 - TFA : INCORRECT DIR STRUCTURE IN TFA
#                           ZIP FILE.
#    llakkana    09/04/15 - Fix 21783633
#    manuegar    09/03/15 - Bug 21787033 - LNX64-12.2-TFA-IPS:SUPPORT ADR
#                           BASEPATH FOR ADE ENVIRONMENTS.
#    cnagur      09/03/15 - Fix for Bug 21774120
#    cnagur      08/31/15 - Fix for Bug 21745495
#    cnagur      08/26/15 - Support for JCS
#    manuegar    08/25/15 - Bug 21643708 - LNX64-12.2-TFA-IPS:IPS WAS NOT ABLE
#                           TO SHOW AND COLLECT PKGS IN ANOTHER ADRBASE.
#    cnagur      08/25/15 - Fix for Bug 21692106
#    bibsahoo    08/23/15 - Adding Error Statements when certificates are not
#                           generated
#    manuegar    08/21/15 - Bug 21641720 - LNX64-12.2-TFA-IPS:DID NOT COLLECT
#                           IPS PKG ON LOCAL WITH MULTIPLE ADR HOMES.
#    arupadhy    08/20/15 - certain windows specific change related to catfile,
#                           catdir, perl chmod function
#    cnagur      08/12/15 - Fix for Bug 21557964
#    manuegar    08/10/15 - Bug 21552014 - LNX64-12.2-TFA-IPS:DIAGCOLLECT -IPS
#                           DID NOT WORK.
#    gadiga      08/10/15 - dbname during start
#    cnagur      08/06/15 - Fix for Bug 21529435
#    llakkana    08/05/15 - Sticky bit on tools dirs
#    cnagur      08/03/15 - Fix for Bug 21471195
#    manuegar    07/31/15 - Bug 21471902 - LNX64-12.2-TFA-IPS:DIAGCOLLECT HUNG
#                           AT WAITING FOR IPS RESULT OF REMOTE NODE.
#    manuegar    07/30/15 - Bug 21463833 - TFA : INCIDENT BASED TFA DIAGCOLLECT
#                           DIR STRUCTURE ISSUE
#    cnagur      07/28/15 - Fix for Bug 21312627
#    cnagur      07/27/15 - Fix for Bug 18068445
#    cnagur      07/24/15 - Copy usableNonRootports.txt to Cells
#    gadiga      07/23/15 - Persist oracle_base in lite rediscovery
#    gadiga      07/21/15 - parse events
#    cnagur      07/21/15 - Fix for Bug 21455054
#    gadiga      07/21/15 - stop tools
#    gadiga      07/21/15 - Add osw directory from TFA_BASE
#    gadiga      07/21/15 - dbaas sqlt issue
#    gadiga      07/21/15 - scan only last 50MB
#    manuegar    07/17/15 - Bug 21461623 - TRACE AND ALERT FILES FOR TFACTL
#                           HAVE READ WORLD PERMISSION.
#    cnagur      07/17/15 - XbranchMerge cnagur_tfa_bug_21312262_txn from
#                           st_tfa_12.1.0.2.4psu
#    cnagur      07/16/15 - Added updateKeyPermissions
#    manuegar    07/10/15 - Bug 21426172 - TFA: PROBLEM / PROBLEM KEY BASED TFA
#                           DIAGCOLLECT.
#    manuegar    07/03/15 - Bug 21347986 - SOLX64-12.2-TFA-IPS:DID NOT FOUND
#                           ANY ADRHOME WHEN CREATE PACKAGE.
#    manuegar    07/03/15 - Bug 21221209 - LNX64-12.2-TFA:IPS SHOW
#                           CONFIGURATION DID NOT WORK AS EXPECTED.
#    manuegar    07/02/15 - Bug 21355765 - TFA DIAGCOLLECT BASED ON INCIDENT
#                           MISSING ALERT LOG, INCIDENT AND TRACE FILES.
#    amchaura    06/28/15 - write env TZ to tfa_setup.txt
#    gadiga      06/26/15 - show help for tool only in MOS
#    llakkana    06/24/15 - Replace commons io 2.2 with 2.1
#    gadiga      06/24/15 - 20986610
#    cnagur      06/24/15 - Fix for Bug 21312262
#    manuegar    06/23/15 - Bug 21261716 - TFA: INCIDENT BASED TFA DIAGCOLLECT.
#    manuegar    06/18/15 - Allow control+c for interactive IPS.
#    amchaura    06/17/15 - log4j config
#    cnagur      06/16/15 - Added sticky bit to repository
#    manuegar    06/16/15 - Define default IPS collection and support -noips
#                           switch.
#    amchaura    06/09/15 - XbranchMerge amchaura_tfa_debugkey from
#                           st_tfa_12.1.2.5
#    gadiga      06/09/15 - rotate timeline
#    cnagur      06/09/15 - Added updateSSLPermissions
#    amchaura    06/08/15 - XbranchMerge amchaura_tfa_debug_key from
#                           st_tfa_12.1.0.2.4psu
#    amchaura    06/08/15 - create keys for nonroot users on patching
#                           st_tfa_12.1.2.5
#    gadiga      06/04/15 - XbranchMerge gadiga_tfa_message_nonroot_2 from
#    gadiga      06/04/15 - run as user
#                           st_tfa_12.1.0.2.4psu
#    bburton     06/02/15 - permisisons for cert files and keys
#    bburton     06/02/15 - XbranchMerge bburton_secure_tfa_fix from
#    cnagur      05/22/15 - Copy Files using Tags
#    manuegar    05/20/15 - TFA/Ips collection Logic 2.
#    gadiga      05/19/15 - run as oracle user
#    gadiga      05/19/15 - 20803006
#    manuegar    05/15/15 - Bug 18708663 - LNX64-121-CMT: PLEASE IMPROVE HELP
#                           MESSAGES ABOUT 'TFACTL ENABLE/DISABLE'.
#    manuegar    05/13/15 - Bug 18220041 -LNX64-12.1-TFA:ADD OPTION TO SHOW
#                           STATUS OF ALL NODES WITH TFACTL ACCESS LSUSER.
#    cnagur      05/13/15 - Update perm of tfa_base/bin/tfactl
#    cnagur      05/12/15 - Added tfactlshare_upgradeTFABase()
#    gadiga      05/12/15 - change a+x to 755
#    bburton     05/11/15 - Fix bug for upgrading tfa_directories.txt
#    cnagur      05/11/15 - XbranchMerge cnagur_tfa_base_perm_txn from main
#    manuegar    05/07/15 - Fix tracing issue during TFA install.
#    manuegar    05/05/15 - Bug 19843599 - LNX64-12.1-TFA-FCS:DIAGCOLLECT
#                           SHOULD ENHANCE NODELIST CHECKING.
#    manuegar    05/04/15 - Validate the default attribute for the subcomponent
#                           element.
#    manuegar    05/04/15 - Add a filter to "print components" option.
#    gadiga      04/29/15 - fix opatch user
#    manuegar    04/23/15 - Setup IPS directories for non root users.
#    manuegar    04/23/15 - Fix help in diagcollect.
#    llakkana    04/22/15 - rconfig.properties file change
#    manuegar    04/21/15 - Bug 20913912 - DIAG TFA: TFACTL IPS SHOW INCIDENTS
#                           NOT WORKING.
#    amchaura    04/21/15 - XbranchMerge amchaura_tfa_customer_ssl from main
#    cnagur      04/21/15 - XbranchMerge cnagur_tfa_non_root_perm_txn from main
#    gadiga      04/02/15 - XbranchMerge gadiga_fix_file_pattern_match from
#                           main
#    gadiga      03/25/15 - XbranchMerge
#                           gadiga_bugs_20752964_20752868_20666289_20666280_20658249
#                           from main
#    cnagur      03/25/15 - Fix for Bug 20775621
#    cnagur      03/24/15 - XbranchMerge cnagur_tfa_purge_silent_txn from main
#    cnagur      04/21/15 - Fix for Bug 20920884
#    gadiga      04/16/15 - fix 20893141
#    manuegar    04/15/15 - Bug 20351399 - LNX64-12.2-TFA-FCS:DIAGCOLLECT HELP
#                           MESSAGE NEED DESCRIPTIONS FOR NEW OPTIONS.
#    cnagur      04/14/15 - Fix for Bug 20879023
#    manuegar    04/13/15 - Bug 20811395 - LNX64-12.2-TFA-EXADATA:TYPO ERROR IN
#                           DIAGCOLLECT HELP MSG.
#    gadiga      04/01/15 - fix pattern match for full file
#    gadiga      03/30/15 - windows
#    cnagur      03/30/15 - Fix for Bug 20796717
#    cnagur      03/26/15 - XbranchMerge cnagur_tfa_121240_sunos_grep_txn from
#                           st_tfa_12.1.2.4
#    gadiga      03/24/15 - fix 20666280. add all commands in help
#    gadiga      03/24/15 - fix 20666289. dont print o/p from remote if cmd
#                           fails local
#    gadiga      03/24/15 - bug 20752964. show msg for localhost
#    manuegar    03/20/15 - 20747322 - TFA XML PARSER SUPPORT SPECIAL CHARACTERS
#                           IN ATTRIBUTE VALUES AND COMMENTS
#    cnagur      03/25/15 - Fix for Bug 20775621
#    cnagur      03/06/15 - Fix for Bug 20652958
#    manuegar    03/05/15 - Bug 20415329 - LNX64-12.2-TFA:NO IPS IN TFACTL HELP
#                           MESSAGE RUNNING AS NON ROOT USER
#    manuegar    02/13/15 - Support additional tags for components.xml
#    gadiga      03/03/15 - read db params from internal
#    gadiga      03/03/15 - osw start
#    gadiga      03/03/15 - dont run toolstatus clusterwide
#    bburton     03/03/15 - add /var/log/xen for ODADOm0
#    cnagur      02/27/15 - Fix for Bug 20561433
#    gadiga      02/24/15 - run as user
#    amchaura    02/24/15 - Fix odadom0 install errors
#    gadiga      02/13/15 - parser improvements
#    cnagur      02/11/15 - Fix for lsmod issues
#    manuegar    02/10/15 - Bug 20509555 - LNX64-12.2-TFA:DBGLEVEL COMMANDS
#                           PRINT LOTS OF "COMMAND NOT FOUND
#    manuegar    02/06/15 - Secure IPS commands.
#    manuegar    02/05/15 - Modular tracing.
#    manuegar    02/05/15 - 20480500 - Create diag directory for allowed os groups.
#    manuegar    02/03/15 - 20466755 -Support params in tfactlshare_error_msg.
#    gadiga      02/04/15 - handle group in diag dir creation
#    gadiga      02/04/15 - permission for new perl modules
#    gadiga      02/03/15 - alert log parser
#    amchaura    01/30/15 - Fix javahome for exadom0 install
#    gadiga      01/28/15 - use global cache
#    gadiga      01/23/15 - collect toplogy
#    gadiga      01/22/15 - get list of files from inventory based on filters
#    gadiga      01/20/15 - run oratop from oracle_home
#    amchaura    01/19/15 - 20380630 - TFA SUPPORT FOR EXADATA VM/DOM0
#    gadiga      01/16/15 - fix srvctl
#    gadiga      01/16/15 - fix 20355376
#    gadiga      01/14/15 - use clusterwide
#    gadiga      01/14/15 - run clusterwide
#    bburton     01/14/15 - Bug 20351923 - Do not do addRowLine (---) before a
#                           row exists.
#    manuegar    01/12/15 - Bug 20347777 - TFA-00405 MULTIPLE ROOT ELEMENTS WERE FOUND
#    amchaura    01/12/15 - Fix Bug 20024861 - TFA_SETUP RUNS BUT TFAMAIN HANGS
#                           INDEFINITELY IN JAVA THREAD DEADLOCK
#    manuegar    01/09/15 - CRS log profiles
#    cnagur      01/07/15 - Added updateAutoDiagcollect and getTFAVersion
#    amchaura    01/05/15 - Bug 20251356 - LNX64-12.2-TFA-FCS:MESSAGE IS NOT
#                           CORRECT AFTER MODIFY DIRECTORY
#    gadiga      12/23/14 - fix oratop output for db user
#    manuegar    12/18/14 - LNX64-12.2-TFA-MSG:THE DEFAULT COLLECTION TIME IN
#                           TFACTL HELP SHOULD BE 24 HOURS
#    cnagur      12/18/14 - Fix for Bug 20180447
#    cnagur      12/17/14 - Added function checkUpgradeStatus()
#    cnagur      12/16/14 - Added getNodeType
#    gadiga      12/15/14 - change oratop output
#    manuegar    12/11/14 - Ips collection logic
#    amchaura    12/11/14 - Fix Bug 19828977 - LNX64-12.1-TFA:COLLECT RESULT IS
#                           INCONSISTENT WITH DEFINE OF DIR WITH COLLECTALL
#    gadiga      12/11/14 - help for tools for non-root users
#    cnagur      12/10/14 - Non-root Access to TFA Tools - Bug 20189395
#    gadiga      12/10/14 - remove help for -search
#    gadiga      12/09/14 - remove deployext
#    gadiga      12/04/14 - add tool help
#    amchaura    12/03/14 - set/get NLS parameters
#    gadiga      12/02/14 - change tool_dir
#    amchaura    11/30/14 - BUG 20056015 - LNX64-12.2-TFA:PRINT CONFIG SHOW
#                           INCORRECT MESSAGE OF REMOTE NODES
#    cnagur      11/27/14 - Fix for Bug 20021225
#    cnagur      11/24/14 - Fix for Bug 19985667
#    manuegar    11/21/14 - Bug 19909906, help messages for tfactl ips -h.
#    gadiga      11/21/14 - add prompt sub
#    gadiga      11/19/14 - Fix for Bug 18894663
#    cnagur      11/07/14 - Fix for Bug 19955513
#    manuegar    11/07/14 - Fix 19988863 Comments tag comes before closing tag.
#    cnagur      11/06/14 - Fix for Bug 19380147
#    amchaura    11/06/14 - Bug 19954370 - LNX64-12.2-TFA:AUTODIAGCOLLECT
#                           SUPPORT SCRIPT EXECUTION BASED ON SEARCH STRINGS
#    manuegar    11/05/14 - Implement <action> <toolname> <flags> for support
#                           tools.
#    cnagur      11/04/14 - Changes for AutoPurge - Bug 19941391
#    manuegar    10/28/14 - Enable TFA/IPS under ADE.
#    bburton     10/21/14 - 19508749 - TFA NEEDS TO COLLECT CHMOS NODE EVICTION
#                           EMERGENCY DUMPS Adding GIHOME/crf/db/<hostname>/
#                           directory as it holds the emergency dump files.
#    manuegar    10/21/14 - Additional functionality for xmlparser.
#    manuegar    10/16/14 - Support multiple attributes for xmlparser.
#    manuegar    10/15/14 - Handle dynamic components.
#    cnagur      10/14/14 - Added -force to repositorydir
#    manuegar    10/03/14 - tfa external tools support
#    amchaura    09/29/14 - add supprt for ZDLRA
#    manuegar    09/22/14 - Add support for xml parsing.
#    gadiga      09/22/14 - oratop: enable db user
#    cnagur      09/15/14 - Added updateNonRootAccess - Bug 19607799
#    cnagur      08/27/14 - Added support for core files
#    cnagur      09/02/14 - Added updatePropertiesFile()
#    amchaura    08/27/14 - Fix 18296461 LNX64-12.1-TFA-SCS:NEED A WAY TO INTERRUPT RUNNING DIAGNOSTIC COLLECTIONS
#    llakkana    08/26/14 - bug fix 19465702.
#    amchaura    08/26/14 - ER: 19504818 XML DRIVEN MAPPINGS AND COMPONENTS
#    amchaura    08/13/14 - Fix 19425079  TFACTL -NOCHMOS DOESN'T COLLECT ANYTHING
#    manuegar    08/12/14 - tfa/ips integration
#    cnagur      08/06/14 - Integration of SIGAR - 19352380
#    manuegar    08/05/14 - 19365340: send screen debug to console only
#    manuegar    07/21/14 - Relocate tfactl_lib
#    amchaura    07/17/14 - Fix #19238165
#    manuegar    06/30/14 - Creation 
#
############################ Functions List#################################
# Error Routines
#   tfactlshare_error_msg
#   tfactlshare_signal_exception
#   tfactlshare_assert
#   tfactlshare_signal_handler
#
# Tracing
#   tfactlshare_trace
#
# Diagnostics
#   tfactlshare_check_trace
#   tfactlshare_init_trace
#   tfactlshare_init_tracebasepath
#   tfactlshare_check_tfauser_diag
#   tfactlshare_get_diag_directory
#
# Command parsing & help
#   tfactlshare_parse_command
#   tfactlshare_token_type
#   tfactlshare_get_help_message
#
# XML parsing
#   tfactlshare_populate_tagsarray
#   tfactlshare_get_element
#   tfactlshare_parse_xmlcomp
#   tfactlshare_dump_xmlcomp
#   tfactlshare_load_xmlcomp
#   tfactlshare_parse_pkgmanifest
#   tfactlshare_parse_srdcfile
#   tfactlshare_buildHelp
#   tfactlshare_check_cdata_content
#   tfactlshare_parser_content 
#   tfactlshare_parser_tagopen
#   tfactlshare_parser_capture_attributes
#
# Deploy external support tools
#   tfactlshare_read_ext_xml
#   tfactlshare_manage_ext
#
# Clusterwide commands
#   tfactlshare_execute_clusterwide
#   tfactlshare_execute_tfactl_cmd_withstatusonly
#
# Misc Routines
#   tfactlshare_get_user
#   tfactlshare_set_verbose
#   tfactlshare_validate_user_by_key
#   tfactlshare_get_choice
#   tfactlshare_input_date
#   tfactlshare_isnodelist_duplicated
#   tfactlshare_cat
#   tfactlshare_look4regex
#   tfactlshare_look4regexarr
#   tfactlshare_get_adrbase
#   tfactlshare_isuserindbagrp
#   tfactlshare_awrsnaps
#
# String Trimming Routines
#   tfactlshare_trim_str
#
# Migrated Routines from tfactl/tfactl_lib
#
# print_help
# doVars
# dbg
# tolower_host
# trim
# checkTFAMain
# checkTFAStatus
# zipFilesForDate
# runTFAInventory
# requestZipTransfers
# printCookie
# printTfaHome
# printWalletPassword
# fixTfactl
# fixInitTfa
# updateJDKInTFASetup
# recreateFileEntitiesInBDB
# createTFASetup
# createTFADirectories
# runCellInventory
# runInventoryInCells
# printCellInventoryRunStatus
# printCellDiagCollectRunStatus
# checkVersion
# generateCerts
# getClusterUid
# printHosts
# checkDbExistence
# checkRepositoryIsOpen
# isNodePartOfCluster
# addHost
# removeHost
# executeCommandInHost
# executeCommandInHostAndPrint
# executeCommandInHostAndGetOutput
# setSR
# addDirectory
# sockConnect
# deployTFA
# checkUserAccess
#
#############################################################################

package tfactlshare;
#require Exporter;

our @exp_vars;
our $CFG;

BEGIN {
use Exporter ();
our($VERSION, @ISA, @EXPORT, @EXPORT_OK);
  $VERSION = 1.00;
  @ISA = qw(Exporter);

  my @exp_const = qw(TRUE FALSE ERROR FAILED SUCCESS CONNFAIL DBG_HOST DBG_VERB DBG_WHAT DBG_NOTE);

  our @exp_vars = qw($DEBUG $PORT $SUPPORTMODE $SR $TFA_HOME $NODE_NAMES $CRS_HOME $tputcols);

  my @exp_func = qw(runAutoSetup runExtracttoSetup confirmDiscovery deployTFA tfactlshare_getTFADaemonOwner 
                    sockConnect dbg isODA isODAVMGuest isODADom0 isOfflineMode doVars doVarsWrap 
                    trim tfactlshare_getCommandLocation tfactlshare_uniqList setSR tfactlshare_isAdminUser
                    requestZipTransfers runTFAInventory tolower_host tfactlshare_printTFAVersion
                    isExadataConfigured tfactlshare_getTFAVersion tfactlshare_getTFABuild tfactlshare_updateAutoDiagcollect
                    printOnlineCells printCellInventoryRunStatus printCellDiagCollectRunStatus
                    runDiagCollectCell isExadata get_crs_home isExadataDom0 tfactlshare_updateCipherSuite
                    get_oracle_base tfactlshare_get_adrbase
                    checkTFAMain isTFARunning checkTFAStatus printCookie copyTagFile getJavaOnSunOS
                    printTfaHome printWalletPassword printBuildVersion createTNTprop
                    fixTfactl fixInitTfa createTFASetup recreateFileEntitiesInBDB 
                    updateJDKInTFASetup runCellInventory runInventoryInCells runCellODScan 
                    runDiagcollectionInCells createTFADirectories 
                    printCmd checkVersion generateTFACookie generateCerts generateKeystores generateReceiverCerts getClusterUid  
		    tfactlshare_checkUpgradeStatus printRepository printConfig printInternalConfig 
                    printHosts printReceivers zipFilesForDate checkDbExistence 
                    checkRepositoryIsOpen isNodePartOfCluster addHost removeHost
                    addDirectory tfactlshare_getdebugips tfactlshare_getTfaIpsPoolSize setFlag printLocalRepository getRepositoryMaxSize
                    checkUserAccess listTFAUsers addTFAUser addTFAGroup resetTFAUsers removeTFAUser
                    removeAllUsers addNonRootAccess updateNonRootAccess removeNonRootAccess removeTFAUserFromGroup
                    addDefaultAccessList blockTFAUser blockTFAGroup unblockTFAUser unblockTFAGroup copytfactl checkFileAccess 
                    getCurrentRepository checkFileAccessUsingSu tfactlshare_checksu
                    getTFARunMode printCollectors updatePropertiesFile updateDirectoriesFile
                    buildCLIJava checkNonRootAccess runOraTop getListOfAllNodes tfactlshare_getConfiguredComputeNodes
                    printReDiscoveryStats getOngoingCollections get_tfa_pid tfactlshare_get_pid host
                    get_java_home get_valid_input checkForAvailableSpaceInFileSystem getTfactlPath
                    getFileOwner getSymlinkOwner printLocalDirectories isPresentInArray
                    getLogDirectory tfactlshare_get_diag_directory 
                    read_inv_and_update_tfa_setup get_base_dir
                    get_trc_dirs add_new_directory find_new_databases 
                    runDiscovery addReDiscDirectories set_new_crshome check_new_directories tfactlshare_get_tfadirectories
                    currentTime collectFromInventory tfactlshare_runOrachkDaemon
                    getOnlineCells checkSSHSetup runCommandOnRemoteWithStatus
                    runCommandOnRemote getInventoryLocation processJobsOnCell
                    getListOfOtherNodes preChecks isValidDate getTimeForDate getValidDateFromString tfactlshare_convertValidDateString
                    tfactlshare_cmp_timestamps getActiveListOfNodes isNodeActive checkUserAccessOnRemote tfactlshare_convertDateStringforCRS
                    getReplacedHostName checkWallet getWalletPasswordFromDB
                    getCellInvStartTime getCellInvEndTime pingHost
                    configureCells syncWallet promptForPassword checkWalletPassword
                    updateWalletPasswordInDB removeWalletPasswordFromDB removeWallet
                    tfactlshare_error_msg tfactlshare_signal_exception tfactlshare_assert
                    tfactlshare_signal_handler tfactlshare_getpswd tfactlshare_print_cmds
                    tfactlshare_check_option_consistency tfactlshare_handle_deprecation
                    tfactlshare_get_help_desc tfactlshare_get_help_syntax tfactlshare_adjust_time_by_seconds
                    tfactlshare_get_cmd_wildcard tfactlshare_get_cmd_noinst
                    tfactlshare_is_cmd_visible tfactlshare_trace tfactlshare_trim_str
                    tfactlshare_print tfactlshare_printstderr tfactlshare_printprompt
                    tfactlshare_readstdin tfactlshare_execute_tool tfactlshare_get_instance_name
                    tfactlshare_filter_invisible_cmds tfactlshare_signalhandler
                    tfactlshare_check_reqd_priv %tfactlshare_unix_os %tfactlshare_trace_levels
                    $tfactlshare_logheader $tfactlshare_siguser1 print_help 
                    tfactlshare_pre_dispatch tfactlshare_check_trace tfactlshare_check_type_base
                    tfactlshare_check_tfauser_diag tfactlshare_set_verbose
                    tfactlshare_init_tracebasepath tfactlshare_init_trace tfactlshare_get_user
                    tfactlshare_parse_command tfactlshare_get_help_message tfactlshare_call_adrci tfactlshare_get_oracle_home
                    tfactlshare_validate_db_account tfactlshare_validate_db tfactlshare_validate_remdb
                    tfactlshare_validate_tns tfactlshare_runsecsql
                    tfactlshare_get_oracle_homes tfactlshare_get_adr_bases tfactlshare_get_homepaths
                    tfactlshare_parse_xmlcomp tfactlshare_dump_xmlcomp tfactlshare_populate_tagsarray tfactlshare_check_cdata_content
                    tfactlshare_invalid_chars 
                    tfactlshare_get_element tfactlshare_load_xmlcomp tfactlshare_load_srdc_help tfactlshare_parse_pkgmanifest
                    tfactlshare_parser_content tfactlshare_parser_tagopen tfactlshare_parser_capture_attributes
                    tfactlshare_parse_srdcfile tfactlshare_retrieve_serobj tfactlshare_store_serobj
                    tfactlshare_multistore_serobj
                    tfactlshare_get_attribute tfactlshare_get_hash_attributes tfactlshare_validate_user_by_key
                    tfactlshare_read_ext_xml tfactlshare_manage_ext tfactlshare_awrsnaps
                    tfactlshare_buildHelp tfactlshare_isuserindbagrp
                    executeCommandInHost executeCommandInHostAndPrint
                    executeCommandInHostAndGetOutput
                    tfactlshare_execute_clusterwide tfactlshare_execute_tfactl_cmd_withstatusonly tfactlshare_setup_ext_out_dir
                    tfactlshare_get_repository_location tfactlshare_disable_tool 
                    tfactlshare_enable_tool tfactlshare_tool_status tfactlshare_autostart_tools 
                    tfactlshare_stop_all_tools tfactlshare_add_prompt 
                    tfactlshare_create_dir tfactlshare_mkpath tfactlshare_getConfigValue 
                    tfactlshare_getListOfAllRececivers tfactlshare_printRObjects  tfactlshare_get_ctime
                    tfactlshare_get_choice tfactlshare_get_choice_yn 
                    tfactlshare_get_choice_array tfactlshare_input_date
                    getHomeDirectory configureTFABase getTFABase isTFAOnCloud updateTFABase updateJavaHome
                    tfactlshare_get_files tfactlshare_collect_topology tfactlshare_run_a_os_cmd
                    tfactlshare_session_trace tfactlshare_session_history tfactlshare_run_a_sql
                    tfactlshare_get_tfa_output_loc tfactlshare_get_tfa_metadata_loc tfactlshare_get_date
                    tfactlshare_sendMail tfactshare_find_string tfactlshare_upgradeTFABase
                    tfactlshare_win32_check_if_admin tfactlshare_get_val4key_in_tfa_setup
                    tfactlshare_getNodeListOnCloud tfactlshare_isTFAOnJCS tfactlshare_isTFAOnFMW
                    tfactlshare_isnodelist_duplicated sslRestart
                    tfactlshare_parse_files tfactlshare_setup_alltool_dir_for_user tfactlshare_getPerl
                    tfactlshare_getLatestPerl
                    tfactlshare_cat tfactlshare_look4regex tfactlshare_look4regexarr tfactlshare_uniq 
                    tfactlshare_trim_nodelist
                    tfactlshare_isReceiverRegistered  tfactlshare_addReceiver tfactlshare_addReceiver_wrapfile tfactlshare_addCollector
                    tfactlshare_fixTfadiagnostics tfactlshare_write_array_to_open_file
                    tfactlshare_runThreadDumpsOnJCS tfactlshare_runHeapDumpsOnJCS
                    tfactlshare_updateThreadDumpInterval tfactlshare_updateThreadDumpFrequency
                    tfactlshare_managestop tfactlshare_managestart tfactlshare_start_TFARMain
                    tfactlshare_autostart_tomcat_in_dsc tfactlshare_start_bgprocess tfactlshare_stop_TFARMain
                    tfactlshare_start_tomcat tfactlshare_get_dir_file_owner get_base_dir
                    tfactlshare_updateTFAConfig tfactlshare_getSetupFilePath tfactlshare_get_clients tfactlshare_setup_acfs
                    tfactlshare_update_rprop tfactlshare_getOraInstLocation tfactlshare_updateClusterMode tfactlshare_set_jvm_xmx
                    tfactlshare_get_rbase tfactlshare_runClient tfactlshare_getEscapedUserName tfactlshare_getUserName                    
                    tfactlshare_getorainvloc tfactlshare_generate_password tfactlshare_has_blacklisted_chrs tfactlshare_is_crs_installed tfactlshare_getTFAAge 
                    tfactlshare_is_statspack_installed  tfactlshare_get_awrlicense tfactlshare_is_rac
		    tfactlshare_printSmtpProperties tfactlshare_getSmtpProperties
                    tfactlshare_check_acfs tfactlshare_check_node_validity
                    tfactlshare_getReferenceName
                    tfactlshare_printSyncnodeMessage
                    tfactlshare_setsudo_cmds tfactlshare_tag2spl
                    tfactlshare_setup_tool_dir_for_all_users 
                  );

  @EXPORT  = qw($CFG);
  push @EXPORT, @exp_const, @exp_func, @exp_vars;

}

use strict;
use English;
use IPC::Open2;
use File::Copy;
use File::Path;
use File::Find;
use File::Basename;
use File::Basename  qw( dirname );
use File::Spec::Functions;
use File::Temp qw(tempfile);
use Cwd 'abs_path';
use Getopt::Long;
use Sys::Hostname;
use POSIX;
use POSIX qw(:termios_h);
use Carp;
use Config;
use Data::Dumper;
use Storable;
use Socket;
use Term::ANSIColor;
use B;
BEGIN {
  push @INC, dirname($PROGRAM_NAME).'/..';
  push @INC, dirname($PROGRAM_NAME).'/../common/exceptions';
}

use Text::ASCIITable;
use Text::Wrap;
use Time::Local;
use Date::Manip qw(ParseDate UnixDate);

use constant ERROR                     => "-1";
use constant FAILED                    =>  1;
use constant SUCCESS                   =>  0;
use constant TRUE                      =>  "1";
use constant FALSE                     =>  "0";
use constant CONNFAIL                  =>  "99";
use constant DBG_NOTE => "1";              # Notes to the user
use constant DBG_WHAT => "2";              # Explain what you do
use constant DBG_VERB => "4";              # Be verbose
use constant DBG_HOST => "8";              # print command executed on local host

use tfactlexceptions;
use tfactlglobal;
use cmdlocation;
use osutils;
use dbutil;
use tfactlwin;
use tfactlsumreport;
use tfactlsummaryinterface;
use tfactlsumcollection;
use tfactlstore;

if ($IS_WINDOWS)
{
  eval q{use base 'Win32'; 1} or die $@;
}

############################ Global Constants ###############################
my ($TFACTLSHARE_CSET) = '[\w .\-#$]';  # C-set for alphanumeric, '_', ' ', #
                                                    #  '.', '-', '#', '$' . #

my ($TFACTLSHARE_N_CSET) = '[^\w .\-#$]';  # Char-set for all chars except  #
                                             #  those in $TFACTLSHARE_CSET. #

my ($TFACTLSHARE_CSET_W_WCARD) = '[\w %*.\-#$]';        # Char-set for all  #
                               # $TFACTLSHARE_CSET chars plus $WCARD_CHARS. #

my ($TFACTLSHARE_N_CSET_W_WCARD) = '[^\w %*.\-#$]'; # C-set for all except  #
                                               # $TFACTLSHARE_CSET_W_WCARD. #

my ($TFACTLSHARE_MAXPASSWD) = 256;      # Max length of user passwd input   #

# List of possible platforms.
our (%tfactlshare_unix_os) = ( aix          => 'aix',
                               bsdos        => 'bsdos',
                               dgux         => 'dgux',
                               dynixptx     => 'dynixptx',
                               freebsd      => 'freebsd',
                               linux        => 'linux',
                               hpux         => 'hpux',
                               irix         => 'irix',
                               openbsd      => 'openbsd',
                               dec_osf      => 'dec_osf',
                               sco_sv       => 'sco_sv',
                               svr4         => 'svr4',
                               unicos       => 'unicos',
                               unicosmk     => 'unicosmk',
                               solaris      => 'solaris',
                               sunos        => 'sunos',
                             );

our (%tfactlshare_trace_levels) = ( errors  => '0',
                                    warnings=> '1',
                                    normal  => '2',
                                    info    => '3',
                                    debug   => '4',
                                    screen  => '5',
                                    xmldet  => '6',
                                    all     => '7'
                                  );
                      
# Global hash to store parameter values and build timeline
our (%tfactlshare_timeline);

######
#Global variables used in connection pooling
######
our ($tfactlshare_logheader);             # A header string to be prepended to
                                          # logs. Different for Foreground and
                                          # Background
our ($tfactlshare_siguser1)         = 0;  # Signal to invoke BG process waiting
                                          # IO 



######
# Globals used for parsing.
######
my ($cmdName)="";
my ($text)= "" ;
my ($helpcmd) = "";
my ($cmdNode) = "command";
my ($inCmdNode) = "FALSE";
my ($isWildcard) = "FALSE" ;
my ($isNoinstance) = "FALSE" ;
my ($isVisible) = "true" ;
my ($privReqd) = "syspriv";

# hash table of data for each commands
my (%hCmdDesc) = ();
my (%hSyntax) = () ;
my (%hExample) = () ;
my (%hOptDesc) = ();
my (%hSeeAlso) = () ;
my (%hWildcard) = () ;
my (%hNoInst) = () ;
my (%hisvisible) = () ;
my (%hPrivSysPriv) = ();
my (%hPrivSysOther) = ();

# Help msg topics
my ($synopStr) = "Synopsis";
my ($descStr)  = "Description";
my ($exampStr) = "Examples";
my ($excepStr) = "Exceptions" ;
my ($enhanStr) = "Enhancements" ;
my ($verStr) = "Version" ;
my ($seeAlsoStr) = "See Also";

# Globals used for exit status
my ($exit) = 0;

#  Variables, previously located in tfactl_lib

my @nodes;
my $nodecount;
my $inf;
my $command;
my $localhost = tolower_host();

my $cmd_host;
my @cmd_result;
my @cmd_result_local;
my $mcast_binary;
my $tfaarchive="tfahome_full.tar";

our $instlog;

############################# Error Routines #################################
########
# NAME
#   tfactlshare_error_msg
#
# DESCRIPTION
#   This function provides the main interface for recorded errors.  All
#   modules must call this function to record an error.
#   This routine prints error and exception messages to STDERR.
#
# PARAMETERS
#   err_num   (IN) - TFACTL internal error number.
#   args_ref  (IN) - (Optional) Reference to array of error arguments
#
# RETURNS
#   Null.
########
sub tfactlshare_error_msg 
{
  my ($err_num, $args_ref) = @_;
  my ($module);
  my (@eargs);                                   # Array of error arguments. #
  my ($argument, $stack, $buf);
  my ($exit) = 0;      # Whether to exit TFACTL at the end of this function. #
  my ($err_msg);       # Error message corresponding to $err_num             #

  # Lookup error message
  $err_msg = $tfactlglobal_error_message{$err_num};

  if ( defined $args_ref ) {
    @eargs = @$args_ref; 
    for my $ndx ( 0 .. $#eargs ) {
       $err_msg =~ s/\{$ndx\}/$eargs[$ndx]/ ;
    }    
  } else {
    @eargs = ( "" );
  }

  if ( ! defined $err_msg )
  {
    $err_msg = ""; 
  }

  $buf =  "TFA-".sprintf("%05d",$err_num)." $err_msg";
  chomp($buf);
  if (defined($buf) && ($buf ne ''))
  {
    # Assert that $err_num is valid. 
    @eargs = ("tfactlshare_error_msg_05", $err_num);
    tfactlshare_assert( defined($err_msg) , \@eargs);

    tfactlshare_printstderr ("$buf\n");
    tfactlshare_trace(1,"$buf", 'y', 'n');

    if($tfactlglobal_hash{'verbose'} eq 'debug')
    {
      $stack = Carp::longmess("The stack trace");
      $stack =~ s/\t//g;
      tfactlshare_trace(5, "$stack", 'y', 'n');
        }
  }

  if ($tfactlglobal_hash{'mode'} eq 'n')
  {
   $tfactlglobal_hash{'e'} = -1;
   $|++;
  }

  if ($exit)
  {
    exit 1;
  }
  return;
}

########
# NAME
#   tfactlshare_signal_exception
#
# DESCRIPTION
#   This function provides the main interface for signaled exceptions.
#   All modules must call this function to record an error.
#
# PARAMETERS
#   exception_num   (IN) - TFACTL internal error/exception number.
#   args_ref        (IN) - (Optional) Reference to array of error arguments
#
# RETURNS
#   Never returns; always exits 1.
#
# NOTES
#   Only call this routine for exceptions.  This routine always exits 1.
#
#   Usually, each error type has a fixed number of error arguments that are 
#   displayed, if the error is an external error.  If the error is internal, 
#   then arbitrary number of arguments can be included.
########
sub tfactlshare_signal_exception 
{
  my ($exception_num, $args_ref) = @_;
  my ($module);

  # Assert that $exception_num is within 1-402, inclusive.
  if (($exception_num < 1) || ($exception_num > 402))
  {
    tfactlshare_trace(1, "tfactl: [tfactlshare_signal_exception_05] "
               ."[$exception_num] ", 'y', 'y');
    die "\n";
  }
 
  tfactlshare_error_msg($exception_num, $args_ref);

  # All exceptions end session.
  exit 1;
}

########
# NAME
#   tfactlshare_assert
#
# DESCRIPTION
#   This function assert that first argument is true, or signals exception.
#
# PARAMETERS
#   is_true     (IN) - assert that this argument is TRUE.
#   args_ref    (IN) - (Optional) Reference to array of assert arguments
#
# RETURNS
#   Null if is_true is TRUE; signals internal error otherwise.
#
# NOTES
#   The assert error arguments get displayed when the error is signaled.  The
#   following is the convention:
#     argument 0 - the function name plus a number, e.g. tfactlshare_assert_05
#     argument 1 and onward - values of variables that are being evaluated
#                             for truth.
########
sub tfactlshare_assert
{
  my ($is_true, $args_ref) = @_;

  # Assert that this is true or signal exception.
  if (!$is_true)
  {
    my @eargs = @{$args_ref};
    # Assert that first argument is not true
    tfactlshare_signal_exception(403, \@eargs);
  }

  return;
}

########
# NAME
#   tfactlshare_signal_handler
#
# DESCRIPTION
#   This routine catches and handles OS signals.
#
# PARAMETERS
#   sigtype (IN) - string: type of signal caught.
#
# RETURNS
#   Null.
#
# NOTES
#   Currently, this routine catches SIGINT and SIGUSR1.
########
sub tfactlshare_signal_handler
{
   my ($sigtype) = shift;
   tfactlshare_trace(1, "Proc: [$$] SIG: [$sigtype]", 'y', 'n');
   
   if($sigtype eq 'INT')
   {
      tfactlshare_trace(3, "$tfactlshare_logheader Received an INT " .
                                 "signal. Exiting.",
                                 'y', 'n');
      #exit(0);
   }
   elsif ($sigtype eq 'USR1')
   { 
       tfactlshare_trace(3,"$tfactlshare_logheader Received signal SIGUSR1 ". 
         "from Foregroung Process",'y', 'n');
       $tfactlshare_siguser1 = 1;
   }
   elsif ($sigtype eq 'QUIT')
   {
     tfactlshare_trace(1, "Received signal 'quit'", 'y', 'n');
   }
   return;
}

############################## MISC Routines #################################

########
# NAME
#   tfactlshare_trace
#
# DESCRIPTION
#   This function prints the messages either in alert logs or trace levels 
#   depending on the trace level associated with the message. clsecho is a
#   tool which is used to write the messages in files. The default level of 
#   tracing is set to 'normal'.
#
# USAGE
# tfactl -verbose [ errors| warnings| normal| info| debug ]
#
# PARAMETERS
#   msg_level (IN) - The trace level associated with the message.
#   msg       (IN) - The message to be printed into files.
#   timestamp (IN) - The timestamp is printed along with msg if set to 'y'
#                    The timestamp is not printed along with msg if set to 'n'
#   console   (IN) - If set to 'y' the message is printed to console as well.
#   
# RETURNS
#   Null.
#
# NOTES
# There are 6 levels of tracing.
# Level 1 - ERRORS - Tracing errors in execution path.
# Level 2 - WARNINGS - Tracing warnings in execution path.
# Level 3 - NORMAL - Tracing normal messages such as success statements and
#                    sql queries.
# Level 4 - INFO - Tracing decision statements and loops.
# Level 5 - DEBUG - Tracing for debugging purposes.
# Level 6 - SCREEN - Trace levels 1-6, the output is sent to console.
# Level 7 - XMLDET - Tracing of XML components
#
# The messages in logfile are differentiated using NOTE, SUCCESS, ERROR and 
# WARNING. For error messages and sql statements, timestamps are also recorded
# in the logfiles along with the message. For each message printed in the trace 
# file i.e for levels INFO and DEBUG, the function name precedes the message.
########
sub tfactlshare_trace
{
  my($msg_level, $msg, $timestamp, $console ) = @_;
  my($clsecho_write);
  my($buf, $set_level);
  my ($stderrmsg);

  #print "CALLER 0 :             " . caller(0) . "\n";
  #print "CALLER 1 :             " . caller(1) . "\n";
  #print "CALLER 2 :             " . caller(2) . "\n";
  my $dbgcaller = caller(0);
  my $dbgcaller1 = caller(1);
  my $dbgmask = $tfactlglobal_hash{"debugmask"};
  my $dbginclude = FALSE;
  if ( (defined $dbgcaller && length $dbgcaller && 
       exists $tfactlglobal_mod_levels{$dbgcaller}) ||
       (defined $dbgcaller1 && length $dbgcaller1 && 
        exists $tfactlglobal_mod_levels{$dbgcaller1}) ) {
    $dbginclude = ($dbgmask & $tfactlglobal_mod_levels{$dbgcaller}) |
                  ($dbgmask & $tfactlglobal_mod_levels{$dbgcaller1});
    if ( not $dbginclude ) {
      return;
    }
  }

  $set_level = $tfactlshare_trace_levels{$tfactlglobal_hash{'verbose'}}; 
  if ($timestamp eq 'y')
  {
    $timestamp = '-t';
  }
  else
  {
    $timestamp = ' ';
  }
  
  # print "Global path $tfactlglobal_alert_path Set level $set_level" .
  #       " msg_level $msg_level \n";
  # print "Message $msg \n";
  $clsecho_write = strftime("%d %b %y %H:%M:%S %Z", localtime()) .
                " " .  uc($tfactlglobal_hash{'verbose'}) . " " . $msg . "\n";
  # print $clsecho_write;
  if ( $msg =~ /(tfactl \(PID = [0-9]+\) )(\w+)(\s.*)/ ) {
    my $prefix = $1;
    my $cmdline = "CommandLine";
    $cmdline = color("green") . "CommandLine" . color("reset") if not $IS_WINDOWS;
    my $srcmod = $2;
    my $prevcmdline = $3;
    if ( $srcmod =~ /tfactl/ && (not $IS_WINDOWS) ) {
      $srcmod = color("red") . $srcmod . color("reset");     
    }
    $prevcmdline =~ s/CommandLine/$cmdline/g;
    if ( not $IS_WINDOWS ) {
      $stderrmsg = color("yellow") . $prefix . color("reset") .
                   $srcmod .  $prevcmdline;
    } else {
      $stderrmsg = $prefix . $srcmod .  $prevcmdline;
    }
  }

  if ( $set_level >= $msg_level )
  {
     if ( $console eq 'y' || $set_level >= 
          $tfactlshare_trace_levels{"screen"} ) 
     {
        tfactlshare_printstderr("$stderrmsg\n");
     }
     $msg=~ s/\"/\"'\"'\"/g;
     # print "trace path $tfactlglobal_alert_path/tfactl_".$localhost."_alert.log\n";
     
     if ( not lc($tfactlglobal_hash{'verbose'}) eq "screen" ) {
       if ( $DIAGDIR && -d "$tfactlglobal_alert_path" ) {
         my $filename = catfile("$tfactlglobal_alert_path","tfactl_".
                        $localhost."_alert.log");

         open(my $th, '>>', "$filename")
              or die "Could not open file '$filename' $!";
         print $th $clsecho_write;
         close $th;

         my $mode = (stat($filename))[2];
         $mode = sprintf("%04o",$mode & 07777);
         # print "file $filename , mode $mode\n";

         if ( $mode ne "1640" ) {
           chmod(oct(1640),$filename);
         }

       } else {
              if ( $DIAGDIR ) {
                # unexpected error, diagnostic directory not found
                tfactlshare_signal_exception(201, undef);
              }
       }
     }
  }
  return;
}

##############################################################################

sub tfactlshare_session_trace
{
  my($sess_id, $type, $msg) = @_;
  my $clsecho_write = strftime("%d %b %y %H:%M:%S %Z", localtime()) .
                " $type " . $msg . "\n";

  # print "tfactlglobal_trace_path $tfactlglobal_trace_path \n";
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_session_trace " .
                    "tfactlglobal_trace_path $tfactlglobal_trace_path",'y', 'n');

  if ( $DIAGDIR && -d "$tfactlglobal_trace_path" ) {
         my $filename = catfile($tfactlglobal_trace_path,"tfactl_".$localhost."_session_$sess_id.log");

         open(my $th, '>>', "$filename")
              or die "Could not open file '$filename' $!";
         print $th $clsecho_write;
         close $th;

         my $mode = (stat($filename))[2];
         $mode = sprintf("%04o",$mode & 07777);
         #print "file $filename , mode $mode\n";
         tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_session_trace " .
                           "file $filename , mode $mode",'y', 'n');
         
         if ( $mode ne "1640" ) {
           chmod(oct("1640"),$filename);
         }         

  } else {
              if ( $DIAGDIR ) {
                # unexpected error, diagnostic directory not found
                tfactlshare_signal_exception(201, undef);
              }
  }

}

sub tfactlshare_session_history
{
  my($sess_id) = @_;
  my $file = catfile($tfactlglobal_trace_path,"tfactl_".$localhost."_session_$sess_id.log");
  if ( -r $file)
  {
    open(SRF, $file);
    while(<SRF>)
    {
      chomp;
      print "$_\n";
    }
    close(SRF);
  }
              
}

########
# NAME
#   tfactlshare_getpswd()
#
# DESCRIPTION
#   This routine prompts the user for a password
#
# PARAMETERS
#   None.
#
# RETURNS
#   The user entered password in a string.
#
# NOTES
########
sub tfactlshare_getpswd 
{
  my ($msg) = shift;
  my ($pswd) = '';
  my ($chrgot);
  my ($maxstringput) = $TFACTLSHARE_MAXPASSWD;
  my ($valid) = 0 ;

  $| = 1;

  while ($valid == 0)
  {
    $msg = 'Enter password: ' if (!defined($msg));

    print $msg;
    $maxstringput = $TFACTLSHARE_MAXPASSWD ;
 
    while ($maxstringput--)
    {
      ReadMode("raw");
      $chrgot = ''; # ReadKey(0);
      ReadMode("restore");
   
      # Accept All alpha-numeric, printable characters.
      # Stop - LineFeed/CR - stop accepting character
      if (ord($chrgot) == 13 || ord($chrgot) == 10)
      {
        last;
      }
      else
      { 

        ## No standard way to detect BACKSPACE pressed in LINUX/WINDOWS
        ## checks with '\b' does not work on LINUX, works good on Windows
        ## Also with -w it gives more warnings.
        ## Using ORD to keep it consistent.  
        ## ORD-127 is for DEL, and that cannot be supported as we do not support
        ## <- & -> keys.
        ##
        if (ord($chrgot) == 8 ) # BACKSPACE pressed
        {
          if (length($pswd) > 0)
          {
            $pswd = substr $pswd, 0, (length ($pswd) - 1);
            print "\b \b";

            ## BACKSPACE pressed, one char removed.  We can add one more.
            $maxstringput = $maxstringput + 2;
          }
        }
        elsif ($pswd eq '')         # first char
        {
          $pswd = $chrgot;
          print "*" ;
        }
        else
        {
          $pswd = $pswd . $chrgot;
          print "*";
        }
      }
    }

    print "\n";

    # check for any invalid characters. (one or more of these chars).
    if ($pswd =~ /[\t\$\%\^\&\*\(\)\<\>\"\']/ )
    {
      # Invalid character in password.
      tfactlshare_error_msg(301, undef) ;
      $pswd = '' ;  # to resetart clear.
    }
    else
    {
      $valid = 1 ;  # no invalid characters found.
    }
  }

  return $pswd;
}

######## 
# NAME
#   tfactlshare_print_cmds
# DESCRIPTION
#   This routine prints a list of commands in a formatted way for help.
# PARAMETERS
#   An array with the commands to print.
# RETURNS
#   A string with the formatted commands.
# NOTES
########
sub tfactlshare_print_cmds
{
  my (@cmds) = @_;

  my ($cmd, $t);
  my (@line);
  my ($str)    = '';
  my ($header) = '        ';

  foreach $cmd(@cmds)
  {
    push (@line, $cmd);
    $t = $header . join(', ', @line);
    if (length ($t) >= 60)
    {
      @line = ();
      $str = $str . $t . "\n";
    }
  }
  $str = $str . $t . "\n" if (@line);

  return ($str);
}

########
# NAME
#   tfactlshare_check_option_consistency
# DESCRIPTION
#
# PARAMETERS
# cmd(IN) - current command being processed
# $args_ref(IN) - reference to GetOptions result hash
#
# RETURNS
# None
#
# NOTES
########
sub tfactlshare_check_option_consistency
{ 
  my(%module_cmds) = @_;
  my ($opt);
  my ($cmd);
  my $return_val = 1;

  ######################################################
  # If option not present in global hash
  #   - Add it to global hash
  # Else if duplicate (k,V) pair
  #   - ignore and move to next option
  # Else if the value is different for same options (key with diff values)
  #   - Error out and exit(check Failed)
  #######################################################
  foreach $cmd(sort(keys %module_cmds))
  {
    foreach $opt (sort(keys %{$module_cmds{$cmd}{flags}}))
    {
      my $k = $opt;
      #remove the '=' in the options which take values
      $opt =~ s/=.//;

      if($tfactlglobal_options{$opt})
      {
        #handle duplicate options,error out if inconsistent
        if($tfactlglobal_options{$opt} ne $module_cmds{ $cmd }{ flags}{$k})
        {
          tfactlshare_trace(3, "Option '$opt' inconsistent while processing "
                    ."command:$cmd, correct the same to continue\n", 'n', 'y');
          $return_val=0;
          goto done;
        }
        next;
      }
      else
      {
         #if not already present add the current option to global options Hash
         $tfactlglobal_options{$opt} = $module_cmds{ $cmd }{ flags}{$k};

      }
    }
  }
  done: 
    return $return_val;
}


########
# NAME
#   tfactlshare_handle_deprecation
# DESCRIPTION
# This function checks whether the options for a command is deprecated
# If yes then print out a warning and set the new option for processing.
#
# PARAMETERS
# cmd(IN) - current command being processed
# $args_ref(IN) - reference to GetOptions result hash
# 
# RETURNS
# None
#
# NOTES
# This function is called only for commands which have deprecated
# options ie. find,ls,lsdsk,lsdg,md_restore,md_backup
########
sub tfactlshare_handle_deprecation
{
  my ($cmd,$args_ref) = @_;
  my $iter;
  my @string;
  my (%args_depr);
  my $depr_opt = \%{$tfactlglobal_deprecated_options{$cmd}};
  my @common_keys = grep { exists $depr_opt->{$_} } keys( %{ $args_ref } );

  #If there are deprecated options used.
  if($#common_keys >= 0) 
  {
    foreach $_(@common_keys)
    { 
       #Fetch the new option for current deprecated option
       my $option = $tfactlglobal_deprecated_options{$cmd}{$_}[1]; 

       # Set the new option if corresponding deprecated option was set
       # Special checks for 'lsdsk' and 'md_restore' since options expand
       if($cmd eq 'lsdsk' && $_ eq 'm')
       { 
         $$args_ref{'member'} = '1' if($$args_ref{$_} eq 'm');
         $$args_ref{'candidate'} ='1' if($$args_ref{$_} eq 'c'); 
       }
       elsif($cmd eq 'md_restore' && $_ eq 't')
       {
         $$args_ref{'full'} ='1' if($$args_ref{$_} eq 'full');
	 $$args_ref{'nodg'} =1 if($$args_ref{$_} eq 'nodg');
         $$args_ref{'newdg'} =1 if($$args_ref{$_} eq 'newdg');
       }
       else
       {
         $$args_ref{$option} = $$args_ref{$_};
       }

       # Note: There are corner cases where both new option and the 
       # corresponding deprecated options is used together in a 
       # command the value that appears later in the order takes 
       # precedence. 
       # for eg : TFACTL> md_backup -G DG1 -g DG2
       #          TFACTL> md_backup -G DG1 -G DG2
       #          TFACTL> md_backup -g DG1 -G DG2 
       # In the above examples md_backup will backup DG2 not DG1

       tfactlshare_trace(2, "WARNING:option '$_' is deprecated for '$cmd'",
                         'n', 'y');
       tfactlshare_trace(2, "please use '$option'\n", 'n',
                         'y') if($option ne 'NULL') ;
    }
  }
  return;
}

########
# NAME
#   tfactlshare_get_help_syntax
#
# DESCRIPTION
# This function obtains the synopsis for the specified command.
#
# PARAMETERS
# cmd(IN) - current command being processed
# 
# RETURNS
# syntax - syntax of the given command
########
sub tfactlshare_get_help_syntax
{
  $helpcmd = shift;      # given command
  
  print_help($helpcmd);

  return '';
}

########
# NAME
#   tfactlshare_get_cmd_wildcard
#
# DESCRIPTOIN
#   This function obtains flag - whether the give command supports wild card
#
# PARAMETERS
#   cmd(IN) - current command.
#
# RETURNS
#   True    - if wild card is supported
#   False   - otherwise
#   
########
sub tfactlshare_get_cmd_wildcard
{
  my $cmd = shift ;   # given command.
  my $ret = "False" ;

  if(defined $hWildcard{$cmd} && ($hWildcard{$cmd} eq "True" ) )
  {
    $ret = "True" ;
  }

  return $ret ;
}

########
# NAME
#   tfactlshare_get_cmd_noinst
#
# DESCRIPTOIN
#   This function obtains flag - whether the give command needs TFAMain Instance
#
# PARAMETERS
#   cmd(IN) - current command.
#
# RETURNS
#   True    - if instance is required
#   False   - otherwise
#   
########
sub tfactlshare_get_cmd_noinst
{
  my $cmd = shift ;   # given command.
  my  $ret = "False" ;

  if(defined $hNoInst{$cmd} && ($hNoInst{$cmd} eq "True" ) )
  {
    $ret = "True" ;
  }

  return $ret ;
}

########
# NAME
#   tfactlshare_is_cmd_visible
#
# DESCRIPTOIN
#   This function checks if the given command is visible or hidden
#
# PARAMETERS
#   cmd(IN) - current command.
#
# RETURNS
#   1    - if marked as visible
#   0    - otherwise
#
########
sub tfactlshare_is_cmd_visible
{
  my $cmd = shift ;   # given command.
  my  $ret = 1 ;

  if(defined $hisvisible{$cmd} && $hisvisible{$cmd} ne "true" ) 
  {
    $ret = 0 ;
  }

  return $ret ;
}

# NAME
#   tfactlshare_get_help_cmdDesc
#
# DESCRIPTION
# This function obtains the description of the command
#
# PARAMETERS
# cmd(IN) - current command being processed
# 
# RETURNS
# syntax - syntax of the given command
########
sub tfactlshare_get_help_cmdDesc
{
  $helpcmd = shift ;     #given command

  return $hCmdDesc{$helpcmd} ;
}

########
# NAME
#   tfactlshare_get_help_optDesc
#
# DESCRIPTION
# This function obtains the description for the option.
#
# PARAMETERS
# cmd(IN) - current command being processed
# 
# RETURNS
# description of the option for the command
########
sub tfactlshare_get_help_optDesc
{
  $helpcmd = shift ;    #given command

#  print "Opt Desc for $helpcmd \n $hOptDesc{$helpcmd}\n" ;
  return $hOptDesc{$helpcmd};
}


########
# NAME
#   tfactlshare_get_help_syntax
#
# DESCRIPTION
# This function obtains the synopsis for the specified command.
#
# PARAMETERS
# cmd(IN) - current command being processed
# 
# RETURNS
# example - example for the command.
########
sub tfactlshare_get_help_example
{
  $helpcmd = shift ; #given command

#  print "Example for $helpcmd : $hExample{$helpcmd}\n";
  return $hExample{$helpcmd};
}

########
# NAME
#   tfactlshare_get_help_seeAlso
#
# DESCRIPTION
# This function obtains the seeAlso for the specified command.
#
# PARAMETERS
# cmd(IN) - current command being processed
# 
# RETURNS
# seeAlso - seeAlso for the command.
########
sub tfactlshare_get_help_seeAlso
{
  $helpcmd = shift ; #given command
  return $hSeeAlso{$helpcmd};
}

########
# NAME
#   tfactlshare_trim_str
#
# DESCRIPTION
# This function trims the given string
#
# PARAMETERS
# string (IN) - given string
# 
# RETURNS
# string  - trimmed string
########
sub tfactlshare_trim_str
{
  my $string = shift ; # given string to trim.

  if (defined($string))
  {
    $string =~s/^\s+//;    # remove leading spaces
    $string =~s/\s+$//;    # remove trailing spaces.
  }
  else
  {
    $string ="";
  }
  
  return $string ;
}

########
# NAME
#   tfactlshare_get_help_desc
# DESCRIPTION
# This function is the entry point to the parse help string and return.
#
# PARAMETERS
# cmd(IN) - current command being processed
# 
# RETURNS
# helpstr - help description for the given command
########
sub tfactlshare_get_help_desc
{
  my $helpcmd = shift;   # given command for help.
  my $helpstr = "" ;

  print_help($helpcmd);

  return $helpstr ;
}

########
# NAME
#   tfactlshare_print
#
# DESCRIPTION
#   This function is a wrapper which calls tfactlshare_print_internal with 
#   correct parameters. 
#
# PARAMETERS
#   string (IN) - The string to be printed.
# 
# RETURNS
#   Nothing.
#
# NOTES
#   Ideally, each line being printed to the pipe should be terminated with a 
#   new line, "\n", i.e, $string should be terminatted by newline.
#
########
sub tfactlshare_print
{
   my $string = shift;
   tfactlshare_print_internal(1, $string);
}

########
# NAME
#   tfactlshare_printstderr
#
# DESCRIPTION
#   This function is a wrapper which calls tfactlshare_print_internal with 
#   correct parameters to print to STDERR. 
#
# PARAMETERS
#   string (IN) - The string to be printed.
# 
# RETURNS
#   Nothing.
#
# NOTES
#   Ideally, each line being printed to the pipe should be terminated with a new
#   line, "\n", i.e, $string should be terminatted by newline.
#
########
sub tfactlshare_printstderr
{
   my $string = shift;
   tfactlshare_print_internal(2, $string);
}

########
# NAME
#   tfactlshare_printprompt
#
# DESCRIPTION
#   This function is a wrapper which calls tfactlshare_print_internal with 
#   correct parameters. It is used to print a prompt (for confirmation from
#   the user or requesting more information from the user.) 
#   The string which will be printed to the pipe will be prepended with
#   "STDIN:" so that the foreground process prompts the user and accepts
#   further user input. The foreground process then provides this data back to 
#   the daemon.
#
# PARAMETERS
#   string (IN) - The string to be printed.
# 
# RETURNS
#   Nothing.
#
# NOTES
#   Ideally, each line being printed to the pipe should be terminated with a new
#   line, "\n", i.e, $string should be terminatted by newline.
#
########
sub tfactlshare_printprompt
{
   my $string = shift;
   tfactlshare_print_internal(0, $string);
}

########
# NAME
#   tfactlshare_print_internal
#
# DESCRIPTION
#   This function prints the string passed as argument to the 
#   appropriate STD outputs depending on the filehandle type.
#
# PARAMETERS
#   $filehandletype (IN) - 0, for PROMPT
#                        - 1, for STDOUT
#                        - 2, for STDERR
#   string          (IN) - The string to be printed.
# 
# RETURNS
#   Nothing.
#
# NOTES
#   Ideally, each line being printed to the pipe should be terminated with a new
#   line, "\n", i.e, $string should be terminatted by newline.
#
########
sub tfactlshare_print_internal
{
   my $filehandle = shift;
   my $string = shift;

   print $string if($filehandle <= 1);
   print STDERR $string if($filehandle == 2);
   return;
   
}

########
# NAME
#   tfactlshare_readstd
# DESCRIPTION
#   This function reads one line from the STDIN.
#
# PARAMETERS
#   None.
# 
# RETURNS
#   string (OUT) - The string that was read from the STDIN.
########
sub tfactlshare_readstdin
{
   my $string;
   $string = <STDIN>;

   return $string;
}

#########
# NAME
#   tfactlshare_execute_tool
#
# DESCRIPTION
#   To execute given tool with parameters and return the output
#
# PARAMETERS
#   $cmd(IN)         - command to execute
#   $winext(IN)      - suffix in Windows platform (EXE/BAT/...)
#   #dirs(IN)        - list of directories to search for.
#   #param           - parameter for the command.
#
# RETURNS
#   cmd output or execution error
###########
sub tfactlshare_execute_tool
{
  my ($cmd, $wext, $param, $dirs) = @_ ;
  my ($exec);
  my ($dir);
  my (@result);

  $tfactlglobal_hash{'spawnutil'} = "false" ;

  foreach $dir (@{$dirs})
  {
    $exec = $dir.$cmd;
    if ( $^O =~  /win/i)
    {
      $exec .= $wext;
    }

    if (-x $exec)
    {
      $exec .= " $param";
      #untaint
      $exec =~ /([^\n^\r^\t]+)/;
      $exec = $1;

      tfactlshare_trace(3,"NOTE: Executing $exec..", 'n', 'n');
      # execute the command
      eval
      {
        @result = `$exec`;
      };

      $tfactlglobal_hash{'spawnutil'} = "true" if ($@ eq '');
      @result = ($@) if ($@ ne '');      #execution error
    }
    if($tfactlglobal_hash{'spawnutil'} eq "true")
    {
      last;
    }
  }

  if ($tfactlglobal_hash{'spawnutil'} eq "false")
  {
    tfactlshare_trace (3, "NOTE: unable to execute $cmd...", 'n', 'n');
  }

  return @result;
}

########
# NAME
#   tfactlshare_get_instance_name
#
# DESCRIPTION
#   This function retrieves the instance name of the TFAMain instance to which the
#   TFACTL is connected to.
#
# PARAMETERS
#   dbh         (IN) - initialized database handle, must be non-null.
#
# RETURNS
#   The instance name of the TFAMain instance.
########
sub tfactlshare_get_instance_name
{
  my ($dbh) = shift;                                      # Database handle. #
  my ($inst_name);                                  # TFAMain instance name. #

  $inst_name = "TFAMain";

  return $inst_name;
}

##############
# NAME
#   tfactlshare_filter_invisible_cmds
#
# DESCRIPTION
#   To filter invisble coomands. Only visible command Names are printed
#
# PARAMETER
#   cmdlist   - hash of command names from each module
#
# RETURNS
#   -None-
##############
sub tfactlshare_filter_invisible_cmds
{
  my %cmdlist = @_;

  foreach my $cmd (keys %cmdlist)
  {
    # exclude hidden commands
    if(!tfactlshare_is_cmd_visible($cmd))
    {
      delete($cmdlist{$cmd});
    }
  }

  return tfactlshare_print_cmds(sort(keys %cmdlist));
}

########
# NAME
#   tfactlshare_check_reqd_priv
#
# DESCRIPTION
#   This routine checks whether the current command can run in the privilege
#   specified.
#
# PARAMETERS
#   -NONE-
#
# RETURNS
#   1  - if the command can be executed.
#   0  - if the command can NOT be executed.
#
# NOTES
#   All commands can be executed in SYSPRIV privilege.  Not all commands can be
#   executed in SYSOTHER privilege.  Commands which can be executed in SYSOTHER 
#   privilege has an attribute "priv" set to "sysother" in tfactlcommand.xml
# 
########
sub tfactlshare_check_reqd_priv
{
  my ($cmd)    = $tfactlglobal_hash{'cmd'};
  my ($contyp) = $tfactlglobal_hash{'contyp'};
  my ($ret)    = 0 ;
 
  #print "tfactlshare_check_reqd_priv $cmd $contyp \n";
  #print "hPrivSysPriv{$cmd} $hPrivSysPriv{$cmd} \n" if defined($hPrivSysPriv{$cmd});

  # check to see if the given command can run as SYSPRIV, for SYSPRIV connections
  if ( (($contyp eq "syspriv") && (defined($hPrivSysPriv{$cmd}))) ||
       (($contyp eq "sysother") && (defined($hPrivSysOther{$cmd}))) )
  {
    $ret = 1;
  }
  return $ret;
  return 1;
}

# ###############################################################

########
## NAME
##   tfactlshare_buildHelp
##
## DESCRIPTION
##   This routine builds the Top Level menu,
##
## PARAMETERS
##   $tfa_home - TFA Home
##   $current_user - Current user
##
## RETURNS
##   $commands - Allowed commands
#########
sub tfactlshare_buildHelp {
  my $tfa_home      = shift;
  my $currentUser   = shift;
  my $cmdNameInp    = shift;
  my $cmdNameArgInp = shift;
  
  my $tfa_help_xml = catfile($tfa_home,"resources","tfactlhelp.xml");
  my @helptagsarray;
  my @command;
  my @commandList;
  my %commandInc;

  my $commands = "";
  my $attrname;
  my $cmdName;
  my $cmdNameMod;
  my $cmdLevel;
  my $cmdCategory;
  my $cmdParent;
  my $cmdSeq;
  my $rootOnly;
  my $isCloud;
  my $cloudRootOnly;
  my $isExadata;
  my $description;
  my $usage;
  my $descriptionret;
  my $l4descriptionret;
  my $l4usageret;
  my $l4optionsret;
  my $usageret;
  my $optionsret;
  my $examplesret;

  my $name;
  my $value;

  my $dispCategory="";

  if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_menu"} ) {
    print "cmdNameInp $cmdNameInp\n";
    print "cmdNameArgInp $cmdNameArgInp\n";
  }

  if ( -e "$tfa_help_xml" ) {
    # Parse xml file
    @helptagsarray = tfactlshare_populate_tagsarray($tfa_help_xml);
    @command       = tfactlshare_get_element(\@helptagsarray, 0,0);

    foreach my $cmdchild (@command) {
      $name  = @$cmdchild[ELEMNAME];
      $value = @$cmdchild[ELEMVAL];

      ### print "Level 0 $name $value\n";
      # Get the commands
      my @commandList = tfactlshare_get_element( \@helptagsarray,
                        @$cmdchild[ELEMLEVEL]+1 , @$cmdchild[ELEMNDX] );
      foreach my $child (@commandList) {
        $name  = @$child[ELEMNAME];
        $value = @$child[ELEMVAL]; 

        print "    Level 1 name $name, value $value , child \n" if ( $tfactlglobal_hash{"debugmask"} &
        $tfactlglobal_mod_levels{"tfactlshare_menu"} );

        # Get attributes
        ($attrname , $cmdName) = tfactlshare_get_attribute(
                                 @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL], "cmdName" );
        ($attrname , $cmdNameMod) = tfactlshare_get_attribute(
                                 @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL], "cmdNameMod" );
        ($attrname , $cmdLevel) = tfactlshare_get_attribute(
                                 @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL], "cmdLevel" );
        ($attrname , $cmdCategory) = tfactlshare_get_attribute(
                                 @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL], "cmdCategory" );
        ($attrname , $cmdParent) = tfactlshare_get_attribute(
                                 @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL], "cmdParent" );
        ($attrname , $cmdSeq) = tfactlshare_get_attribute(
                                 @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL], "cmdSeq" );

        # ------------------------------------------------------------------------
        if ( (length $cmdNameInp && $cmdName eq $cmdNameInp) || $cmdNameInp eq "" ) {

          # rootOnly
          ($attrname , $rootOnly) = tfactlshare_get_attribute(
                                   @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL], "rootOnly" );
          if (lc($rootOnly) eq "true") { 
            $rootOnly = TRUE;
          } else {
            $rootOnly = FALSE;
          }

          # isExadata
          ($attrname , $isExadata) = tfactlshare_get_attribute(
                                   @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL], "isExadata" );
          if (lc($isExadata) eq "true") { 
            $isExadata = TRUE;
          } else {
            $isExadata = FALSE;
          }

          # isCloud
          ($attrname , $isCloud) = tfactlshare_get_attribute(
                                   @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL], "isCloud" );
          if (lc($isCloud) eq "true") {
            $isCloud = TRUE;
          } else {
            $isCloud = FALSE;
          }

          # cloudRootOnly
          ($attrname , $cloudRootOnly) = tfactlshare_get_attribute(
                                   @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL], "cloudRootOnly" );
          if (lc($cloudRootOnly) eq "true") {
            $cloudRootOnly = TRUE; 
          } else {
            $cloudRootOnly = FALSE;
          }

          print "    Level 1 cmdName $cmdName \n" if ( $tfactlglobal_hash{"debugmask"} &
        $tfactlglobal_mod_levels{"tfactlshare_menu"} );
          # Get command detail
          my @cmdDetails = tfactlshare_get_element( \@helptagsarray,
                                @$child[ELEMLEVEL]+1 , @$child[ELEMNDX] );
          foreach my $cmddet (@cmdDetails) {
            $name  = @$cmddet[ELEMNAME];
            $value = @$cmddet[ELEMVAL];
            $value =~ s/\&lt\;/\</g;
            $value =~ s/\&gt\;/\>/g;

            print "       Level 2 name $name, value $value , command detail\n" if ( $tfactlglobal_hash{"debugmask"} &
        $tfactlglobal_mod_levels{"tfactlshare_menu"} );

            if ( lc($name) eq "description" ) {  # description
              $description = $value;
              $descriptionret = $description;
            } # end if lc($name) eq "description"

            if ( lc($name) eq "usage" ) {  # usage
              $usage = $value;
              $usageret = $usage;
            } # end if lc($name) eq "usage"

            if ( lc($name) eq "options") { # options
              $optionsret = $value;
            }

            if ( lc($name) eq "examples") { # examples
              $examplesret = $value;
            }

            if ( $cmdCategory ne $dispCategory ) {
              $dispCategory = $cmdCategory;
              # print "\n$dispCategory commands:\n";
            }
            my $failedflag = FALSE;

            if ( $rootOnly && ! $IS_TFA_ADMIN ) {
              $failedflag  = TRUE if (not $ISCLOUD);
            }

            if ( $ISCLOUD && $cloudRootOnly && ! $IS_TFA_ADMIN ) {
              $failedflag  = TRUE;
            }              

            if ( $ISCLOUD && (not $isCloud) ) {
              $failedflag = TRUE;
            }

            if ( $isExadata && (not $failedflag) ) {
              if ( not $EXADATA_SETUP ) {
                $failedflag = TRUE;
              }
            }

            #print "cmdParent $cmdParent\n";
            #print "currentuser $currentUser, rootonly $rootOnly, isexadata $isExadata, iscloud $isCloud, failedflag: $failedflag , $cmdName \n";
            if ( $cmdNameInp eq "" && (not $failedflag) && (not exists $commandInc{$cmdName}) ) {
              $commandInc{lc($cmdName)} = TRUE;
              # Don't display internal commands
              $commands .= $cmdName . "|" if ($cmdCategory ne "Internal");
            }

            # --------------------------------------------
            if ( length $cmdNameInp && length $cmdNameArgInp ) {
              if ( lc($name) eq "commands" ) {  # commands
                print "Inside Level 3 ...\n" if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_menu"} );
                my @cmdChildren = tfactlshare_get_element( \@helptagsarray,
                                  @$cmddet[ELEMLEVEL]+1 , @$cmddet[ELEMNDX] );
                foreach my $child (@cmdChildren) {
                  $name  = @$child[ELEMNAME];
                  $value = @$child[ELEMVAL];

                  print "            Level 3 name $name, value $value\n" if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_menu"} );
                  ($attrname , $cmdName) = tfactlshare_get_attribute(
                                           @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL], "cmdName" );

                  print "             Level 3 cmdName $cmdName\n" if ( $cmdName && ( $tfactlglobal_hash{"debugmask"} &
                  $tfactlglobal_mod_levels{"tfactlshare_menu"})  );

                  $commands .= $cmdName . "|";
                  # ----------------------------------------
                  if ( lc($name) eq "command" ) {  # command
                    # || ($cmdNameArgInp eq "all")
                    if ( ($cmdNameArgInp eq $cmdName)  ) {
                      my @cmdChildrenDet = tfactlshare_get_element( \@helptagsarray,
                                        @$child[ELEMLEVEL]+1 , @$child[ELEMNDX] );
                      # ---------------------------
                      foreach my $childdet (@cmdChildrenDet) {
                        $name  = @$childdet[ELEMNAME];
                        $value = @$childdet[ELEMVAL];

                        print "                 Level 4 name $name, value ($value)\n" if ( $tfactlglobal_hash{"debugmask"} &
        $tfactlglobal_mod_levels{"tfactlshare_menu"} );

                        if ( lc($name) eq "description" ) {  # description
                          my $detdesc = $value;
                          $l4descriptionret = $detdesc;
                          print "                 Level 4 detdesc $detdesc \n" if ( $tfactlglobal_hash{"debugmask"} &
        $tfactlglobal_mod_levels{"tfactlshare_menu"} );
                        } # end if lc($name) eq "description"

                        if ( lc($name) eq "usage") { # usage
                          $l4usageret = $value;
                        } # end if lc($name) eq "usage"

                        if ( lc($name) eq "options") { # options
                          $l4optionsret = $value;
                        }

                      } # end foreach @cmdChildrenDet
                      # ----------------------------
                    } # end if $cmdNameArgInp eq $cmdName 
                  } # end if lc($name) eq "command"
                  # ----------------------------------------

                } # end foreach @cmdChildren
              } # end if lc($name) eq "commands"

              # level 4 return
              # Used when addarg is present, e.g. print actions
              # return commands, usage, description, options
              # -----------------------------------------------
              $l4usageret =~ s/\&lt\;/\</g;
              $l4usageret =~ s/\&gt\;/\>/g;
              $l4optionsret =~ s/\&lt\;/\</g;
              $l4optionsret =~ s/\&gt\;/\>/g;
=head
              print "commands $commands\n";
              print "l4usageret $l4usageret\n";
              print "l4descriptionret $l4descriptionret\n";
              print "l4optionsret $l4optionsret\n";
=cut
              if ( $cmdNameArgInp eq "all" ) {
                return (substr($commands,0,-1), "", $descriptionret, "") if length $descriptionret && length $commands;
              } else {
                return ("", $l4usageret, $l4descriptionret, $l4optionsret) if length $l4usageret && length $l4descriptionret;
              }
            } # end if length $cmdNameInp && length $cmdNameArgInp
            # --------------------------------------------

            #my $formattedstr = sprintf("%10s%-39s %-30s","",$cmdName, $description);
            #print "$formattedstr\n" if not $failedflag;
            #print "cmd $name $cmdName : $cmdLevel : $cmdCategory : $cmdSeq : $description \n";
            #print "cmd $name root $rootOnly : isExadata $isExadata : isCloud $isCloud \n";

          } # end foreach @cmdDetails

          # Level 2 return, e.g. print 
          # return usage, description, options
          # ----------------------------------
          if ( (length $cmdNameInp && $cmdNameArgInp eq "") && length $usageret && length $descriptionret ) {
            $usageret =~ s/\&lt\;/\</g;
            $usageret =~ s/\&gt\;/\>/g;

            $optionsret =~ s/\&lt\;/\</g;
            $optionsret =~ s/\&gt\;/\>/g;
            $optionsret =~ s/\&amp\;/\&/g;
            $examplesret =~ s/\&lt\;/\</g;
            $examplesret =~ s/\&gt\;/\>/g;
            $examplesret =~ s/\&amp\;/\&/g;

            return ($usageret,$descriptionret,$optionsret,$examplesret);
          }
       } # end if (length $cmdNameInp && $cmdName eq $cmdNameInp) || undef $cmdName
         # ------------------------------------------------------------------------

      } # end foreach @commandList
    } # end foreach @command 
  } else {
    print "File $tfa_help_xml does not exist.\n";
    exit;
  } # end if exists $tfa_help_xml

  # return commands
  # ---------------
  return substr($commands,0,-1);
}

##############
## NAME
##   tfactlshare_sep2string
##
## DESCRIPTION
##   This routine returns a formatted string. 
##
## PARAMETERS
##   $separator  - opt | desc
##   $value      - tokenized string
##   $indent     - TRUE | FALSE
###  $extchanges - TRUE | FALSE
##
## RETURNS
##   none
# ##############
sub tfactlshare_sep2string {
  my $separator  = shift;
  my $value      = shift;
  my $indent     = shift;
  my $extchanges = shift;
  my $cmdreq     = shift;
  my $indentval = "";
  my $prevctx   = "";
  my $postctx   = "";
  my $oneday = 24 * 60 * 60;
  my $threehours = 3 * 60 * 60;
  my $currtime     = strftime "%b/%d/%Y", localtime();
  my $utscurrtime  = getValidDateFromString($currtime, "time");
  my $starttime    = strftime "%b/%d/%Y", localtime(time() - $oneday);
  my $endtime      = strftime "%b/%d/%Y %H:%M:%S", localtime($utscurrtime - $threehours);
  
  if ( $ISCLOUD ) {
    $separator = "cloud" . $separator;
  } elsif ( $EXADATA == 1 ) {
    $separator = "exadata" . $separator;
  } elsif ( isODADom0() == 1 ) {
    $separator = "odadom0" . $separator;
  } elsif ( $IS_ODA ) {
    $separator = "oda" . $separator;
  } elsif ( $IS_RACDBCLOUD ) {
    $separator = "racdbcloud" . $separator;
  } else {
  }

  $value =~ s/tfacmd/$tfacmd/g;
  $value =~ s/DIAG_TIME/$DIAG_TIME/g;
  $value =~ s/tfa_log/$tfactlglobal_log_path/g;
  $value =~ s/START_TIME/\"$starttime\"/g;
  $value =~ s/END_TIME/\"$endtime\"/g;
  $value =~ s/CURRENT_TIME/\"$currtime\"/g;

  if ( $indent ) {
    $indentval = "    "; 
  } else {
    print "\n"; # description case
  }
  if ( length $value ) {
    my $lastopt = FALSE;
    foreach my $line ( split /newline/ , $value ) {
      if ( $line =~ /_begin(.*?)_(.*)_end(.*)_/ ) {
        $prevctx = "_begin" . $1 . "_";
        $postctx = "_end" . $3 . "_";
      }
      if ( $line =~ /^\s*$/ ) {
        $line = $prevctx . $postctx; 
      }

      #print "separator => $separator , line => $line\n";
      if ( $line =~ /_begin$separator\_(.*)_end$separator\_/ ) {
        my $auxval = $1;
        ### print "if - line   $line\n";
        ### print "if - auxval $auxval\n";
        if ( $auxval =~ /nonwindowsplat(.*)/ && (not $IS_WINDOWS) ) {
          print "$indentval$1\n";
        } elsif ( $auxval =~ /windowsplat(.*)/ && ($IS_WINDOWS) ) {
          print "$indentval$1\n";
        } else {
         print "$indentval$auxval\n" if ($auxval !~ /windowsplat/);
        }
      } elsif ( lc($cmdreq) eq "run" && ( 
               ( $line =~ /\s*_begin.*?opt_noindent(nonwindowsplat)?(.*)\:(.*?)_endif(.*?)opt_/ && # Categories filter
                 # print("2:($2)\n") && print("3:($3)\n") && print ("4:($4)\n") &&
                 (not length $3) && (not exists $tfactlglobal_exttools_categories{lc($2)}) )  ||
               ( $line =~ /\s*_begin.*?opt_(nonwindowsplat)?(.*)\:(.*?)_endif(.*?)opt_/ && # Item description filter
                 # print("2:($2)\n") && print("3:($3)\n") && print ("4:($4)\n") &&
                 (length $3) && (not exists $tfactlglobal_exttools{trim(lc($2))}) &&
                 (-d catfile($tfa_home, "ext", trim(lc($2)))) )
                                        ) ) {
        next;
      } elsif ( ($extchanges && $line =~ /_beginif$separator\_(.*)_endif$separator\_/) ||
                ($extchanges && $line =~ /_beginrootif$separator\_(.*)_endrootif$separator\_/ &&
                 $current_user eq "root")  ) {
        my $auxval = $1;
        if ( $auxval =~ /noindent(.*)/ ) {
          $indentval = "";
          $auxval = $1;
        } else {
          $auxval = $1;
        }
        ### print "elsif - line $line\n";
        ### print "elsif - auxval $auxval\n";
        if ( $auxval =~ /^nonwindowsplat(.*)/ && (not $IS_WINDOWS) ) {
          print "$indentval$1\n";
          $lastopt = FALSE;
        } elsif ( $auxval =~ /^windowsplat(.*)/ && ($IS_WINDOWS) ) {
          print "$indentval$1\n";
          $lastopt = FALSE;
        } else {
          if ( ($auxval =~ /^nonwindowsplat(.*)/ && $IS_WINDOWS) ||
               ($auxval =~ /^windowsplat(.*)/    && (not $IS_WINDOWS)) ) {
            $lastopt = TRUE if length $auxval;
          }

          # length $auxval &&
          if ( (not length $auxval) && $lastopt ) {
            $lastopt = FALSE;
          } else {
            print "$indentval$auxval\n" if ($auxval !~ /windowsplat/);
          }
        }

      } elsif ( $line =~ /^\s*$/ ) {
        print "\n"; # newline detected
      }
    }
  } # end if length $value
  return;
}

# Routines migrated from tfactl.pl & tfactl_lib.pl

##############
# NAME
#   print_help
#
# DESCRIPTION
#   print_help 
#
# GLOBAL VARIABLES REFERENCED
#   $hostname
#   $current_user
#   $tfacmd
#   crs_home
#   $tfa_home
#   $EXADATA
#   $EXADATA_SETUP 
#   $HELP
#
# RETURNS
#   -None-
##############
sub print_help
{
  my $switch_val;
  my $addarg;
  my @addargarray;
  my $alladdargmatched = TRUE;
  my $IS_DEF_HLP = FALSE;
  my %compshash;

  # Testing for different platforms ?
  # just uncomment the desired platform

  # $EXADATA = 1;
  # $IS_ODADom0 = 1;
  # $IS_ODA = 1;
  # $IS_RACDBCLOUD = 1;
  # $ISCLOUD = 1; 
  # $IS_WINDOWS = 1;

  $switch_val = $_[0];
  if ( $_[1] ) {
    $addarg     = $_[1];
    $addarg =~ s/( -help| -h)//g;
    @addargarray = split /\s/, $addarg;    
  }

  my %helpargsl2 = ( "print", TRUE,
                      "directory", TRUE,
                      "access", TRUE,
                      "host", TRUE,
                      "receiver", TRUE,
                      "producer", TRUE,
                      "dom0IP", TRUE,
                      "cell", TRUE,
                      "client", TRUE,
                      "availability", TRUE,
                    );

  my %argsl2 = ( "print-status", TRUE,
                 "print-components", TRUE,
                 "print-config", TRUE,
                 "print-directories", TRUE,
                 "print-hosts", TRUE,
                 "print-receivers", TRUE,
                 "print-collectors", TRUE,
                 "print-robjects", TRUE,
                 "print-actions", TRUE,
                 "print-repository", TRUE,
                 "print-runmode", TRUE,
                 "print-suspendedips", TRUE,
                 "print-protocols", TRUE,
                 "directory-add", TRUE,
                 "directory-remove", TRUE,
                 "directory-modify", TRUE,
                 "access-lsusers", TRUE,
                 "access-add", TRUE,
                 "access-remove", TRUE,
                 "access-block", TRUE,
                 "access-unblock", TRUE,
                 "access-enable", TRUE,
                 "access-disable", TRUE,
                 "access-reset", TRUE,
                 "access-removeall", TRUE,
                 "host-add", TRUE,
                 "host-remove", TRUE,
                 "receiver-add", TRUE,
                 "receiver-remove", TRUE,
                 "receiver-startweb", TRUE,
                 "receiver-stopweb", TRUE,
                 "receiver-info", TRUE,
                 "producer-start", TRUE,
                 "producer-stop", TRUE,
                 "producer-status",TRUE,
                 "dom0IP-add", TRUE,
                 "dom0IP-remove", TRUE,
                 "cell-status", TRUE,
                 "cell-config", TRUE,
                 "cell-add", TRUE,
                 "cell-remove", TRUE,
                 "cell-invstat", TRUE,
                 "cell-diagstat", TRUE,
                 "cell-configure", TRUE,
                 "cell-deconfigure", TRUE,
                 "client-add", TRUE,
                 "client-remove", TRUE,
                 "client-list", TRUE,
                 "availability-enable",TRUE,
                 "availability-disable",TRUE,
               );

  my %helpargs = ( "collection", TRUE,
                   "start",TRUE,
                   "stop",TRUE,
                   "run",TRUE,
                   "enable",TRUE,
                   "disable",TRUE,
                   "status",TRUE,
                   "purge",TRUE,
                   "toolstatus", TRUE,
                   "uninstall", TRUE,
                   "deploy", TRUE,
                   "shutdown" , TRUE,
                   "restrictprotocol", TRUE,
                   "change", TRUE,
                   "set", TRUE,
                   "deletedb", TRUE,
                   "removecollection", TRUE,
                   "zipfiles", TRUE,
                   "deployext", TRUE,
                   "runtool", TRUE,
                   "diagcollect",TRUE,
                   "analyze",TRUE,
                   "setupmos",TRUE,
                   "upload",TRUE,
                   "events",TRUE,
                   "search",TRUE,
                   "changes",TRUE,
                   "isa",TRUE,
                  );

  ### print "addarg $addarg\n";

  if ( length $addarg ) {
    if ( (not exists $argsl2{$switch_val."-".$addarg}) && ($addarg !~ /\-[a-z]+/) && $addarg ne "examples" ) {
      print "\n$addarg\n";
      $addarg = "";
    } elsif ( $addarg =~ /-database/ ) {
      $compshash{"-database"} = "    -database <dbname> Collect Database logs";
    }
  }

  {
    my $usage;
    my $description;
    my $options;
    my $examples;
    my @compsarray;
    my $tracemsg;
    my $hlpdata = $ADDCOMPHLPSTRING;
    my $hlpdataexa = $ADDCOMPHLPSTRING_EXADATA;
    my $hlpdataoda = $ADDCOMPHLPSTRING_ODA;
    my $hlpdataracdbcloud = $ADDCOMPHLPSTRING_RACDBCLOUD;

     tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare print_help " .
                       "DESCRIPTION HELPERS (All,Exadata,Oda,RacDbCloud)", 'y', 'y');
     tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare print_help " .
                       "All ADDCOMPHLPDESC $ADDCOMPHLPDESC", 'y', 'y');
     tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare print_help " .
                       "Exadata ADDCOMPHLPDESC_EXADATA $ADDCOMPHLPDESC_EXADATA", 'y', 'y');
     tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare print_help " .
                       "Oda ADDCOMPHLPDESC_ODA $ADDCOMPHLPDESC_ODA", 'y', 'y');
     tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare print_help " .
                       "RACDBCLOUD ADDCOMPHLPDESC_RACDBCLOUD $ADDCOMPHLPDESC_RACDBCLOUD", 'y', 'y');

     ###print "DESCRIPTION HELPERS \n";
     ###print "All \n";
     ###print $ADDCOMPHLPDESC;
     ###print "Exadata \n";
     ###print $ADDCOMPHLPDESC_EXADATA;
     ###print "Oda \n";
     ###print $ADDCOMPHLPDESC_ODA;
     ###print "Rac Db Cloud \n";
     ###print $ADDCOMPHLPSTRING_RACDBCLOUD;

    if ( $EXADATA == 1 ) {
      @compsarray = split /\n/, $ADDCOMPHLPDESC_EXADATA;
      $hlpdata    = $ADDCOMPHLPSTRING . $ADDCOMPHLPSTRING_EXADATA;
      $hlpdata    = "| -ips" . $hlpdata;
      $tracemsg = "hlpdataexa"; 
    } elsif (isODA() == 1) {
       @compsarray = split /\n/, $ADDCOMPHLPDESC_ODA;
       $hlpdata    = $ADDCOMPHLPSTRING_ODA . $ADDCOMPHLPSTRING;
       $hlpdata    = "| -ips" . $hlpdata;
       $tracemsg = "hlpdataoda";
    } elsif ( $IS_RACDBCLOUD ) {
       @compsarray = split /\n/, $ADDCOMPHLPSTRING_RACDBCLOUD;
       $hlpdata    = $ADDCOMPHLPSTRING_RACDBCLOUD . $ADDCOMPHLPSTRING;
       $tracemsg   = "hlpdataracdbcloud";
    } elsif ( isODADom0() == 1 ) {
       $hlpdata    = "";
       $tracemsg   = "hlpdataodadom0";
    } else {
       @compsarray = split /\n/, $ADDCOMPHLPDESC;
       $hlpdata    = $ADDCOMPHLPSTRING;
       $hlpdata    = "| -ips" . $hlpdata;
       $tracemsg   = "hlpdata";
       $IS_DEF_HLP = TRUE;
    }

    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare print_help " .
                      "compsarray (@compsarray)",'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare print_help " .
                      "ADDCOMPHLPSTRING_EXADATA    ($ADDCOMPHLPSTRING_EXADATA)",'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare print_help " .
                      "ADDCOMPHLPSTRING_ODA        ($ADDCOMPHLPSTRING_ODA)",'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare print_help " .
                      "ADDCOMPHLPSTRING_RACDBCLOUD ($ADDCOMPHLPSTRING_RACDBCLOUD)",'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare print_help " .
                      "ADDCOMPHLPSTRING            ($ADDCOMPHLPSTRING)",'y', 'y');

    ###print "compsarray (@compsarray)\n";
    ###print "ADDCOMPHLPSTRING_EXADATA    ($ADDCOMPHLPSTRING_EXADATA)\n";
    ###print "ADDCOMPHLPSTRING_ODA        ($ADDCOMPHLPSTRING_ODA)\n";
    ###print "ADDCOMPHLPSTRING_RACDBCLOUD ($ADDCOMPHLPSTRING_RACDBCLOUD)\n";
    ###print "ADDCOMPHLPSTRING            ($ADDCOMPHLPSTRING)\n";

    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare print_help " .
                      "$tracemsg BEFORE CHANGE $hlpdata",'y', 'y');
    $hlpdata =~ s/\sor/ \|/g;
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare print_help " .
                      "$tracemsg AFTER CHANGE $hlpdata",'y', 'y');

    # Populate %compshash, used in the help for diagcollect components
    foreach my $line (@compsarray) {
       my $comp;
       my $compdesc;
       if ( $line =~ /\s+(\-[a-z]+)\s+(.*)/ ) {
         $comp = $1;
         $compdesc = $2;
         if ( not exists $compshash{$comp} ) {
           $compshash{$comp} = $line;
           ### print "Adding $comp : $compdesc\n";
         }
       } # end if $line =~ /\s+(\-[a-z]+)\s+(.*)/
    } # end foreach @compsarray

    # Checking if all $addarg items matched
    # If one didn't matched ->  $alladdargmatched = FALSE -> print general help
    foreach my $addargitem ( @addargarray ) {
      ### print "checking $addargitem ... \n";
      if ( not exists $compshash{lc($addargitem)} ) {
        $alladdargmatched = FALSE;
      }
    }
    ### print "allmatched $alladdargmatched\n";
          ###print "DESCRIPTION HELPERS \n";
          ###print "All \n";
          ###print $ADDCOMPHLPDESC . "\n";
          ###print "Exadata \n";
          ###print $ADDCOMPHLPDESC_EXADATA;
          ###print "Oda \n";
          ###print $ADDCOMPHLPDESC_ODA;
          ###print "Rac Db Cloud \n";
          ###print $ADDCOMPHLPSTRING_RACDBCLOUD;

    my $extchanges = FALSE;
    $extchanges = TRUE if ( -e catfile($tfa_home, "ext", "changes") );

    # $helpargs processing
    # --------------------

    if ( exists $helpargs{$switch_val}  ) {
      # Examples for diagcollect
      # ------------------------
      if ( ($switch_val eq "diagcollect" || $switch_val eq "analyze") && length $addarg && $addarg eq "examples" ) {
        my ($usage,$description,$options,$examples) = tfactlshare_buildHelp($tfa_home, $current_user,$switch_val);
        print "Examples:\n";
        tfactlshare_sep2string("eg",$examples,TRUE,TRUE,$switch_val);
        exit 0;
      } # end if examples for diagcollect

      # Help for diagcollect -ips -h/-help
      # ----------------------------------
      if ( $switch_val eq "diagcollect" && @addargarray && $#addargarray == 0 &&
           lc($addargarray[0]) eq "-ips" && ( ($EXADATA == 1) || (isODA() == 1) || $IS_DEF_HLP ) ) {
        my ($commands,$usage,$description,$options);
        ($commands,$usage,$description,$options) = tfactlshare_buildHelp($tfa_home, $current_user,$switch_val,$addargarray[0]);
        if ( length $description ) {
          print "\n$description\n";
          print "\nUsage : $tfacmd $usage\n";
          #tfactlshare_sep2string("opt",$options,TRUE,FALSE,$switch_val);
          tfactlshare_sep2string("opt",$options,TRUE,TRUE,$switch_val);
        } else {
          print "No description available\n";
        }
        return;
      } # end if -ips help

      # Help for diagcollect -srdc -h/-help
      # manuegar_srdc_14
      # ----------------------------------
      if ( $switch_val eq "diagcollect" && @addargarray && $#addargarray == 0 &&
           lc($addargarray[0]) eq "-srdc" && ( ($EXADATA == 1) || (isODA() == 1) || $IS_DEF_HLP ) ) { 
        my ($commands,$usage,$description,$options);
        ($commands,$usage,$description,$options) = tfactlshare_buildHelp($tfa_home, $current_user,$switch_val,$addargarray[0]);
        if ( length $description ) {
          print "\n$description\n";
          print "\nUsage : $tfacmd $usage\n";
          #tfactlshare_sep2string("opt",$options,TRUE,FALSE,$switch_val);
          tfactlshare_sep2string("opt",$options,TRUE,TRUE,$switch_val);
          print $SRDCHLPSTRING;
        } else {
          print "No description available\n";
        }     
        return;
      } # end if -srdc help

         ($usage,$description,$options,$examples) = tfactlshare_buildHelp($tfa_home, $current_user,$switch_val);

=head
      print "usage << $usage >>\n";
      print "description << $description >>\n";
      print "options << $options >>\n";
=cut
      if ( length $description ) {
        if ( $ISCLOUD && $usage =~ /.*_begincloud_(.*)_endcloud_.*/ ) {
          $usage = $1;
        } elsif ( ($EXADATA == 1) && $usage =~ /.*_beginexadata_(.*)_endexadata_.*/ ) {
          $usage = $1;
        } elsif ( (isODADom0() == 1) && $usage =~ /.*_beginodadom0_(.*)_endodadom0_.*/ ) {
          $usage = $1;
        } elsif ( (isODA() == 1) && $usage =~ /.*_beginoda_(.*)_endoda_.*/ ) {
          $usage = $1;
        } elsif ( $IS_RACDBCLOUD && $usage =~ /.*_beginracdbcloud_(.*)_endracdbcloud_.*/ ) {
          $usage = $1;
        } elsif ( $usage =~ /.*_begindef_(.*)_enddef_.*/ ) {
          $usage = $1;
        }

        #print "\n$description\n";
        tfactlshare_sep2string("desc",$description,FALSE,FALSE,$switch_val);
        print "\nUsage : $tfacmd $usage\n";
        # options for $helpargs
        tfactlshare_sep2string("opt",$options,TRUE,TRUE,$switch_val) if $switch_val ne "diagcollect";

        # List diagcollect options specific to platform
        if ( $switch_val eq "diagcollect" ) {
          #$hlpdata = "| -ips" . $hlpdata;
          $hlpdata =~ s/\| //;
          $hlpdata =~ s/-rdbms/-database/;
          $hlpdata =~ s/\s//g;

          my $cnt = 0;
          $hlpdata =~ s/(-ips\|)/++$cnt==2 ? "" : "$1"/ge;
          print "    components:$hlpdata\n" if not $IS_ODADom0;

          tfactlshare_sep2string("opt",$options,TRUE,TRUE,$switch_val);

          print "For detailed help on each component use:\n  $tfacmd $switch_val [component_name1] [component_name2] ... [component_nameN] -help\n" if ( (not $IS_ODADom0) && ((not length $addarg) || ( $alladdargmatched == FALSE )) );
          # Print help for dynamic components
          if ( $alladdargmatched ) {
            foreach my $addargitem ( @addargarray ) { 
              if ( $compshash{lc($addargitem)} =~ /\s+(\-\w+)\s+(.*)/ ) {
                my $formattedstring = sprintf("    %-15s %-40s",$1,$2);
                # print diagcollect help for dynamic components
                print "$formattedstring\n";
              }
            } # end foreach
          } # end if $alladdargmatched 
        } # end if $switch_val eq "diagcollect"

      } else {
        print "No description available\n";
      }
      return;
    }
   elsif ( exists $helpargsl2{$switch_val} )
    {
      # argsl2 processing
      # -----------------

      my $commands;
      my $usage;
      my $description;
      my $options;
      if ( length $addarg ) {
        if ( exists $argsl2{$switch_val."-".$addarg} ) {
          ($commands,$usage,$description,$options) = tfactlshare_buildHelp($tfa_home, $current_user,$switch_val,$addarg);
          if ( length $description ) {
            print "\n$description\n";
            print "\nUsage : $tfacmd $usage\n";
            #tfactlshare_sep2string("opt",$options,TRUE,FALSE,$switch_val);
            tfactlshare_sep2string("opt",$options,TRUE,TRUE,$switch_val);
          } else {
            print "No description available\n";
          }
        }
        return;
      }

      ($commands,$usage,$description,$options) = tfactlshare_buildHelp($tfa_home, $current_user,$switch_val,"all");
      if ( $ISCLOUD && ($usage =~ /.*_begincloud_(.*)_endcloud_.*/) ) {
        $usage = $1;
      } 
      if ( (not $ISCLOUD) && ($usage =~ /.*_begindef_(.*)_enddef_.*/ )) {
        $usage = $1;
      }

      tfactlshare_sep2string("desc",$description,FALSE,FALSE,$switch_val);
      print "\nUsage : $tfacmd $switch_val <command> [options]\n";
      print "    commands:$commands\n";
      print "For detailed help on each command use:\n  $tfacmd $switch_val <command> -help\n";
    }
    else
    {
      print "\nUsage : $tfacmd <command> [options]\n";

      my $commands = tfactlshare_buildHelp($tfa_home, $current_user);
      print "    commands:$commands\n";
      print "For detailed help on each command use:\n  $tfacmd <command> -help\n";
    }
  }
  print "\n";
  return;
  exit (0);
}


##############
# NAME
#   tfactlshare_pre_dispatch
#
# DESCRIPTION
#   tfactlshare_pre_dispatch 
#
# GLOBAL VARIABLES REFERENCED
#
# RETURNS
#   -None-
##############
sub tfactlshare_pre_dispatch 
{
###  Need to check directories exist and do morevalidation checking her estill
###

#
#
# MAIN SCRIPT BODY
#
#local $SIG{'__DIE__'} = sub { dietrap(@_); };
#local $SIG{INT} = sub { dietrap(@_); };

if ( $ENV{'TFA_DEBUG'} )
{
  $DEBUG = $ENV{'TFA_DEBUG'};
}
 else
{
  $DEBUG = 1;
}

### Set this host name (lower case and no domain name)
my $host = tolower_host();
dbg(DBG_VERB,"Running on Host : $host \n");


# run the required subroutine dependent on the parameters provided.
# Code moved to specific routines (e.g. tfactl<moduleName>_dispatch()


return;
}

### merged code from tfactl_lib

##
sub isODA {
 return $IS_ODA;
}

sub isODAVMGuest {
 my $FLAG = 0;
 if ( -d catfile("","opt","oracle","oak","bin") ) {
   my $xenblk = `/sbin/lsmod | grep xen_blkfront | awk '{print \$1}'`;
   my $xennet = `/sbin/lsmod | grep xen_netfront | awk '{print \$1}'`;
   #print "$xenblk $xennet";
   if ( $xenblk && $xennet ) {
      $FLAG = 1;
   }
 }
    return $FLAG;
}

sub isODADom0 {
 return $IS_ODADom0;
}

sub isExadataDom0 {
  my $FLAG = 0;
  if ( -d catfile("","opt","exadata_ovm") ) {
    my $xenblk = `/sbin/lsmod | grep xen_blkback | awk '{print \$1}'`;
    my $xennet = `/sbin/lsmod | grep xen_netback | awk '{print \$1}'`;
    #print "$xenblk $xennet";
    if ( $xenblk && $xennet ) {
      if ( -d catfile("","opt","oracle.ExaWatcher") ) {
        $FLAG = 1;
      }
    }
 }
 return $FLAG;
}

sub getTfactlPath {
  my $tfa_home = shift;
  my $hostname = tolower_host();
  if (!(-f catfile("","opt","oracle","oak","bin","oakd")) && $tfa_home =~ /$hostname/) {
    my $tfabase = $tfa_home;
    $tfabase =~ s/[\\\/]tfa_home//;
    my @dirs = split(/[\\\/]/, $tfabase);
    my $base;
    for (my $c=0; $c<scalar(@dirs)-1; $c++) {
	$base = catfile($base,"@dirs[$c]");
    }
    #$base .= "bin";
    return catfile($base,"bin","tfactl");
  }
  return catfile($tfa_home,"bin","tfactl");
}

sub getPortNumber {
  my $portfile = shift;
  dbg( DBG_VERB, "Opening Port file $portfile\n");

  open (PORTFILE, "<", "$portfile") or
	die("\nTFA-00001: Failed to start Oracle Trace File Analyzer (TFA) daemon. Please check TFA logs.\n");

  my $port_number;
  while(<PORTFILE>)
  {
    chomp;
    if ( /(.*)/ )
    {
      $port_number = $1;
      last;
    }
  }
  close(PORTFILE);
  dbg( DBG_VERB, "Read Port Number : $port_number from $portfile\n");
  return $port_number;
}

sub isOfflineMode {
my $paramfile = shift;
dbg( DBG_VERB, "Opening Parameter file $paramfile\n");
open (PARAMFILE, "<", "$paramfile") or
        die("ERROR: Unable to open file for reading $paramfile,  $!,");

  while (<PARAMFILE>) {
    if ( /SUPPORT_MODE\=TRUE/) 
    {
      close (PARAMFILE);
      return 1;
    }
  }
  close (PARAMFILE);
  return 0;
}
#
sub doVars {
my $paramfile = shift;
my @epgm;
dbg( DBG_VERB, "Opening Parameter file $paramfile\n");
open (PARAMFILE, "<", "$paramfile") or
        die("ERROR: Unable to open file for reading $paramfile,  $!,");

while (<PARAMFILE>) {
  if ($_ !~ /^#|^\s*$/) {
    # The magic below takes params of the form KEY=VAL and sets them as
    # variables in the perl context
    chomp;
    $_ = trim ($_);
    my ($key, $val) = split ('=');
    dbg(DBG_VERB,"key : $key val : $val\n");
    if(grep $_ eq "\$$key", @exp_vars)
    {
      if ((0 > index($val,'"'))) {
        $val =~ s!\\!\\\\!g;
        push @epgm, "\$$key=\"$val\";";
        #push @epgm, "my \$$key=\"$val\";";
      } else {
        $val =~ s!\'!\\'!g;
        push @epgm, "\$$key) {\$$key='$val';";
        #push @epgm, "my \$$key='$val';";
      }
    }
  }
}
close (PARAMFILE);
#print "@epgm\n";
eval ("@epgm");
}
#==============================tolower_host==================#
sub tolower_host
{
    my $host = hostname () or return "";

    # If the hostname is an IP address, let hostname remain as IP address
    # Else, strip off domain name in case /bin/hostname returns FQDN
    # hostname
    my $shorthost;
    if ($host =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
        $shorthost = $host;
    } else {
        ($shorthost,) = split (/\./, $host);
    }

    # convert to lower case
    $shorthost =~ tr/A-Z/a-z/;

    die "Failed to get non-FQDN host name for " if ($shorthost eq "");

    return $shorthost;
}
#====================== trim ===============================#
sub trim
################################################################################
# Function: Remove leading and trailing blanks.
#
# Arg     : string
#
# Return  : trimmed string
################################################################################
{
   my $str = $_;
   $str = shift;
   $str =~ s/^\s+//;
   $str =~ s/\s+$//;
   return $str ;
}

#
# Subroutine to remove duplicates from Array List
# Args : Array List
# Returns : Array List
#
sub tfactlshare_uniqList {
	my %seen;
	grep !$seen{$_}++, @_;
}

#####
# Name - tfactlshare_runClient
# DESCRIPTION - Execute client command resturns result
# PARAMETERS - command
# RETURNS - command output
#####
sub tfactlshare_runClient {
  my $command = shift;
  my $redir = shift; 
  my @output;
  @output = split(/\n/,`$command $redir`);
  if ( $output[0] =~ /WARNING - Certificate/ ) {
    print shift(@output) . "\n" if $PRINT_CERT_WARNING;
    $PRINT_CERT_WARNING = 0;
  } elsif ( $output[0] =~ /FAIL - Certificate/) {
    print shift(@output) . "\n";
    exit 1;
  } elsif ( $output[0] =~ /TFA is not yet secured to run all commands/ ) {
    tfactlshare_printSyncnodeMessage();
    exit 0;
  } elsif ( $output[0] =~ /Cannot establish connection to TFA on port/) {
    tfactlshare_error_msg(104, undef) ;
    exit 1;
  }
 return @output;
}

##################################################
# Name - tfactlshare_printSyncnodeMessage
# DESCRIPTION - Action message when 103 is occured
# PARAMETERS - None
# RETURNS - None
##################################################
sub tfactlshare_printSyncnodeMessage {
	tfactlshare_error_msg(103, undef) ;
	print "\nTFA has not synchronised across all nodes yet. \nIf an install or upgrade is in ";
	print "progress and the operation has not completed on all \nnodes then please wait for ";
	print "completion and allow TFA 10 minutes to synchronize.  \nIf no install or upgrade is ";
	print "in progress or you need TFA to synchronize now \nPlease run 'tfactl syncnodes' to ";
	print "generate and copy TFA Certificates.\n";
}

sub tfactlshare_sendMail {
	my $tfa_home = shift;
	my $to = shift;
	my $localhost = tolower_host();
	my $message ="$localhost:testmail:$to";
	my $command = buildCLIJava($tfa_home,$message);
	my $line;
	my @cli_output = tfactlshare_runClient($command);
	foreach $line ( @cli_output ) {
		if ( $line eq "DONE" ) {
			return SUCCESS;
		}
		print "$line\n";
	}
	return SUCCESS;
}

sub getCloudDirectories {
	my $ref = shift;
	my @dirs = @{$ref};
	@dirs = sort(@dirs);
	my @list = $dirs[0];

	my $dir;

	foreach $dir ( @dirs ) {
		my $length = scalar @list;
		my $add = 0;

		my $i;
		for ( $i = 0; $i < $length; $i = $i + 1 ) {
                        ## \Q used to skip the error of considering '\' as part of regular expression
			if ( $dir =~ /^\Q$list[$i]\E[\/|\\]/) {
				next;
			}
			if ( $list[$i] eq "$dir" ) {
				next;
			}
			$add = $add + 1;
		}
		if ( $add == $length ) {
			push(@list, $dir);
		}
	}
	return \@list;	
}

sub tfactlshare_getOraInstLocation {
	my $ora_inv;
	if ($IS_WINDOWS) {		
	    my $inst_loc = tfactlwin_query_registry("inst_loc");
	    #$ORACLE_INVENTORY =~ s// /g;
	    $ora_inv = (split /\s{2,}/, $inst_loc)[-1];
	    chomp($ora_inv);
	} elsif (-e catfile("", "etc", "oraInst.loc")) {
	    $ora_inv = catfile("", "etc", "oraInst.loc");
	} elsif (-e catfile("", "var", "opt", "oracle", "oraInst.loc")) {
		$ora_inv = catfile("", "var", "opt", "oracle", "oraInst.loc");
	} 
	return $ora_inv;
}

sub configureCloudComponents {
	my $tfa_home = shift;
	my $tfa_base = shift;
	my $xml;

	if ( $ISJCS ) {
		$xml = catfile($tfa_base, "resources", "components_jcs.xml");
	} elsif ( $ISFMW ) {
		$xml = catfile($tfa_base, "resources", "components_saas.xml");
	} else {
		$xml = catfile($tfa_base, "resources", "components.xml");
	}

	if ( ! -s $xml ) {
		print "Unable to find components.xml [$xml]\n";
	}
		
	my $iscomp = 0;
	my $id;
	my $desc;
	my $line;
	my $home;
	my $instance;
	my $dirs = 0;
	my $pattern;
        my $name;
        my $value;
        my $attrname;
        my $attrval;
	my %comp = ();

        # Parse xml file
        my @tagsarray = tfactlshare_populate_tagsarray($xml);

        # Parse components
        my @componentsList = tfactlshare_get_element(\@tagsarray, 1,0);

        foreach my $child (@componentsList)
        {	
          # Get component
          $name = @$child[ELEMNAME];

          # Get component details
         my @componentDetails = tfactlshare_get_element( \@tagsarray,
                                @$child[ELEMLEVEL]+1 , @$child[ELEMNDX] );
         foreach my $compdet (@componentDetails)
         {
            $name  = @$compdet[ELEMNAME];
            $value = @$compdet[ELEMVAL];
            # ------------------------------------------------------
            if ( lc($name) eq "name" ) {                # name
              $id = $value;
            # ------------------------------------------------------
            } elsif ( lc($name) eq "description" ) {    # description
              $desc = $value;
            } elsif ( lc($name) eq "instance_home" || lc($name) eq "domain_home" ) {
              $home = $name;
              $instance = $value;
            # ------------------------------------------------------
            } elsif ( lc($name) eq "directories" ) {    # directories
              my @directoriesList = tfactlshare_get_element( \@tagsarray,
                            @$compdet[ELEMLEVEL]+1 , @$compdet[ELEMNDX] );
              $pattern="";
              foreach my $directorieslst (@directoriesList)
              {
                $name = @$directorieslst[ELEMNAME];
                $value = @$directorieslst[ELEMVAL];
                
                # Get attribute "pattern"
                ($attrname , $attrval) = tfactlshare_get_attribute(
                                         @$directorieslst[ELEMATTRNAME] , @$directorieslst[ELEMATTRVAL],
                                         "pattern" );
                $pattern = join(",", $pattern, $attrval);
              } # end foreach @directoriesList
            }
            # ------------------------------------------------------
         } # end foreach @componentDetails
         $line=1;
         $comp{$id} = "$desc!!$home!!$line!!$instance!!$pattern";

         tfactlshare_trace(5, "tfactlshare (PID = $$) configureCloudComponents " .
                           "COMP $id => $desc!!$home!!$line!!$instance!!$pattern\n",
                           'y', 'y');
        } # end foreach @componentsList

	my $key;
	my $value;
	my @values;

	#printCloudDirectories(\%comp);

	#print "\nWould you like to update these default directories ? [y|n] [n] : ";
	my $option;
	#chomp( $option = <STDIN> );
	$option ||= "N";
	$option = get_valid_input ($option, "y|Y|n|N", "N");

	if ( $option =~ /[yY]/ ) {
		my $product = 1;
		while ( $product > 0 ) {
			print "\nPlease Enter the Product ID that you would like to update : ";
			chomp ( $product = <STDIN> );
			if ( ! $product ) {
				$product = 0;
			} else {
				$value = $comp{$product};
				if ( $value =~ /!!/ ) {
					@values = split(/!!/, $value);
					print "\nPlease Enter $values[1] for Product ID $product : ";
					my $optval;
					chomp( $optval = <STDIN> );
					$optval = trim($optval);
					$comp{$product} = "$values[0]!!$values[1]!!$values[2]!!$optval!!$values[4]";

					# Update the directory in components.xml
					$optval =~ s/\//\\\//g;
					my $command = "perl -pi -e 's/.*/\<$values[1]\>$optval\<\\\/$values[1]\>/ if \$. == $values[2]' $xml";
					qx($command);
					print "\nSuccessfully updated $values[1] for Product ID $product\n";
					printCloudDirectories(\%comp);
					
				} else {
					print "\nInvalid Product ID $product. Please try again.\n";
					$product = 1;
				}
			}
		}
	}

	my $dirstoadd = catfile($tfa_base, "resources", "directories.lst");

	open(ADD, ">", $dirstoadd);

	# Exract only directories from hash and add them to TFA
	while( ( $key, $value ) = each %comp ) {
		@values = split(/!!/, $value);
		$home = $values[1];
		$instance = $values[3]; 
		$pattern = $values[4];
                #print "\n\nID $key Desc $values[0] Home $home instance $instance pattern $pattern \n\n";
		
		if ( -d "$instance" ) {
			$pattern =~ s/$home/$instance/g;
                        $pattern =~ s/\%//g;
			my @dirs = split(/,/, $pattern);
			my $dir;
			foreach $dir ( @dirs ) {
				#print "Pattern Directory : $dir\n";
				my $out = qx(ls -d $dir 2> $DEVNULL);
				my @list = split(/\s/, $out);
				foreach $dir (@list) {
					#print "LS -D Directory : $dir\n";
					#addDirectory($tfa_home, $dir, 0);
					print ADD "$dir\n";
				}				
			}			
		}
	}

	my $orabasebin;
	my $orabase;
	# Add ORACLE_BASE directory to TFA on SI
	if ( $tfa_home =~ /$SI_REL_DIR$/ ) {
		my $db_home = $tfa_home;
		$db_home =~ s/$SI_REL_DIR//;
		if ($IS_WINDOWS) {
			$orabasebin = catfile($db_home, "BIN", "orabase.exe");
		} else {
			$orabasebin = catfile($db_home, "bin", "orabase");
		}

		if ( -f $orabasebin ) {
			if ($IS_WINDOWS) {
				#print "set ORACLE_HOME=$db_home; $orabasebin\n";
				$orabase = `set ORACLE_HOME=$db_home; $orabasebin`;
			} else {
				#print "ORACLE_HOME=$db_home; export ORACLE_HOME; $orabasebin";
				$orabase = qx(ORACLE_HOME=$db_home; export ORACLE_HOME; $orabasebin);
			}
			$orabase = trim($orabase);
			if ( -d $orabase ) {
				print ADD "$orabase\n";
			}
		}
	}

        # Add dir's for ade non-daemon run
	if ( $IS_ADE ) {
		my $db_home = $ENV{ORACLE_HOME};		
		if ($IS_WINDOWS) {
			$orabasebin = catfile($db_home, "BIN", "orabase.exe");
		} else {
			$orabasebin = catfile($db_home, "bin", "orabase");
		}

		if ( -f $orabasebin ) {
			if ($IS_WINDOWS) {
				#print "set ORACLE_HOME=$db_home; $orabasebin\n";
				$orabase = `set ORACLE_HOME=$db_home; $orabasebin`;
			} else {
				#print "ORACLE_HOME=$db_home; export ORACLE_HOME; $orabasebin";
				$orabase = qx(ORACLE_HOME=$db_home; export ORACLE_HOME; $orabasebin);
			}
			$orabase = trim($orabase);
			$orabase = abs_path($orabase);
			if ( -d $orabase ) { 
				print ADD catdir($orabase, "log", "diag")."\n";
			}
		}

		# Add SRCHOME to TFA
		my $ade_src = $ENV{SRCHOME};
		$ade_src = abs_path($ade_src);
		if ( -d $ade_src ) {
			print ADD catdir($ade_src, "log", "diag") . "\n";
			print ADD catdir($ade_src, "work") . "\n";
		}

		# Add ADR_BASE to TFA
		my $adr_base = $ENV{ADR_BASE};
		$adr_base = abs_path($adr_base);
		if ( -d $adr_base ) {
			print ADD catdir($adr_base, "diag", "rdbms")."\n";

			my $fileName = catfile($adr_base, "diag", "adrci_dir.mif");
			if ( -r $fileName ) {
				$adr_base = tfactlshare_cat($fileName);
				$adr_base = abs_path($adr_base);
				if ( -d $adr_base ) {
					print ADD catdir($adr_base, "diag", "rdbms")."\n";
				}
			}
		}
	}

	# Get ORACLE_HOME from inv and add orabase
	my $ora_inv = tfactlshare_getOraInstLocation();
        #print "INVENTORY: $ora_inv\n";
	
	if ( -r $ora_inv ) {
		my @db_homes = read_ohomes_in_inv($ora_inv);
		foreach my $db_home ( @db_homes ) {
			my $orabasebin;
			if ($IS_WINDOWS) {
				$orabasebin = catfile($db_home, "bin", "orabase.exe");
			} else {
				$orabasebin = catfile($db_home, "bin", "orabase");
			}

			#print "OBBIN: $orabasebin\n";
			if ( -r $orabasebin ) {
				$ENV{ORACLE_HOME} = $db_home;
				my $orabase = `$orabasebin`;
				
				$orabase = trim($orabase);
				if ( -d $orabase ) {
					print ADD "$orabase\n";
					#print "OB: $orabase\n";
				}
			}
		}
	}

	close (ADD);

	my @directories;
  	my $dir;

	open (RD, $dirstoadd);
	while (<RD>) {
		chomp;
		push(@directories, $_);
	}
	close (RD);

 	my $ref = getCloudDirectories(\@directories);
	@directories = @{$ref};

        open (WR, ">", $dirstoadd);
	foreach $dir ( @directories ) {
		print WR "$dir\n";
		#print "$dir\n";
	}
	close (WR);

        if ( $tfactlglobal_hash{"debugmask"} &
             $tfactlglobal_mod_levels{"tfactlshare_non_daemon"} ) {
          my $outdirs = `cat $dirstoadd`;
          tfactlshare_trace(5, "tfactl (PID = $$) " . "configureCloudComponents, contents of file $dirstoadd",
                            'y', 'y');
          tfactlshare_trace(5, "tfactl (PID = $$) " . "configureCloudComponents, content: $outdirs",
                            'y', 'y');
        }

	print "\nAdding directories to TFA. It might take couple of minutes. Please wait...\n\n";
	if ( -e "$dirstoadd" ) {
		addDirectoryUsingFile($tfa_home, $dirstoadd);
	}
} # end sub configureCloudComponents

sub tfactlshare_getNodeListOnCloud {
	my $tfa_base = shift;
	my @nodelist;

	if ( ! $tfa_base ) {
		my $homedir = getHomeDirectory();
		$homedir = catfile($homedir, ".tfa");
		$tfa_base = getTFABase(catfile($homedir, "tfa_setup.txt"));
	}

	my $nodefile = catfile($tfa_base, "internal", "cloudnodes.lst");

	open (RD, $nodefile) or print "ERROR: Unable to open file $nodefile in getNodesOnCloud().";

	while (<RD>) {
		chomp;
		push(@nodelist, $_);
	}
	close (RD);

	return \@nodelist;
}

##########################################
# NAME
#   discoverNodesOnCloud
#
# DESCRIPTION
#   This function discovers JCS Nodes
#
# PARAMETERS
#   $param1 - JCS Domain Config File
#
# RETURNS
#   retval - List of JCS Nodes
#
##########################################
sub discoverNodesOnCloud {
	my $config = shift;
	my @nodelist;

	my $domain;
	my $machine;
	my $node_manager;

	if ( ! $config ) {
		$config = getJCSDomainConfigFile();
	}

	open(XML, $config);

	while (<XML>) {
		chomp;

		if ( /<domain\s/ ) {
			$domain = 1;
		} elsif ($domain == 1) {
			if ( /<machine\s/ ) {
				$machine = 1;
			} elsif ( $machine == 1 ) {
				if ( /<node-manager>/ ) {
					$node_manager = 1;
				} elsif ( $node_manager == 1 ) {
					if ( /<listen-address>(.*)<\/listen-address>/ ) {
						push(@nodelist, trim($1));
					}
				}
			}
		}
	}
	close (XML);
	#print "NodeList in discoverNodesOnCloud : @nodelist\n";

	return \@nodelist;
}

##########################################
# NAME
#   getWLSNameList
#
# DESCRIPTION
#   This function will list Names of Oracle WLS on JCS
#
# PARAMETERS
#   $param1 - JCS Domain Config File (optional)
#
# RETURNS
#   retval - List of WLS Names
#
##########################################
sub getWLSNameList {
	my $config = shift;
	my @serverlist;
	my $domain;
	my $server;
	my $name;

	if ( ! $config ) {
		$config = getJCSDomainConfigFile();
	}

	open(XML, $config);

	while (<XML>) {
		chomp;

		if ( /<domain\s/ ) {
			$domain = 1;
		} elsif ($domain == 1) {
			if ( /<server>/ ) {
				$server = 1;
			} elsif ( $server == 1 ) {
				if ( /<name>(.*)<\/name>/ ) {
					push(@serverlist, $1);
					$server = 0;
				}
			}
		}
	}
	close (XML);
	return \@serverlist;
}

##########################################
# NAME
#   getWLSPIDList
#
# DESCRIPTION
#   This function will list PIDs of Oracle WLS on JCS
#
# PARAMETERS
#   $param1 - JCS Domain Config File (optional)
#
# RETURNS
#   retval - List of PIDs of WLS
#
##########################################
sub getWLSPIDList {
	my $config = shift;
	my @pids;
	
	if ( ! $config ) {
		$config = getJCSDomainConfigFile();
	}

	my $ref = getWLSNameList($config);
	my @servers = @{$ref};

	my $server;
	my $command;
	my $pid;

	foreach $server ( @servers ) {
		$command = 'ps -aef | grep java | grep weblogic.Name=' . $server . ' | grep -v grep | awk \'{ print $2 }\'';
		$pid = qx($command);
		push(@pids, trim($pid));
	}

	return \@pids;
}

##########################################
# NAME
#   getCloudSetupFile
#
# DESCRIPTION
#   This function returns the TFA setup (tfa_setup.txt) on Cloud Env
#
# RETURNS
#   retval - Location of tfa_setup.txt on Cloud Env
#
##########################################
sub getCloudSetupFile {
	my $home_dir = getHomeDirectory();	
	my $setup = catfile($home_dir, ".tfa", "tfa_setup.txt");
	return $setup;
}

##########################################
# NAME
#   getCloudConfigFile
#
# DESCRIPTION
#   This function returns the TFA Config File (config.properties) on Cloud Env
#
# RETURNS
#   retval - Location of config.properties on Cloud Env
#
##########################################
sub getCloudConfigFile {
	my $home_dir = getHomeDirectory();	
	my $config = catfile($home_dir, ".tfa", "config.properties");
	return $config;
}

##########################################
# NAME
#   getThreadDumpInterval
#
# DESCRIPTION
#   This function returns Interval of Thread Dump using TFA Config
#
# RETURNS
#   retval - Returns Thread Dump Interval in seconds
#
##########################################
sub getThreadDumpInterval {
	my $config = getCloudConfigFile();
	my $interval = tfactlshare_getConfigValue($config, "ThreadDumpInterval");

	if ( ! $interval ) {
		$interval = 60;
	}
	return $interval;
}

##########################################
# NAME
#   getThreadDumpFrequency
#
# DESCRIPTION
#   This function returns Frequency of Thread Dump using TFA Config
#
# RETURNS
#   retval - Returns Thread Dump Frequency
#
##########################################
sub getThreadDumpFrequency {
	my $config = getCloudConfigFile();
	my $frequency = tfactlshare_getConfigValue($config, "ThreadDumpFrequency");

	if ( ! $frequency ) {
		$frequency = 3;
	}
	return $frequency;
}

###############################################################
# NAME
#   tfactlshare_runThreadDumpsOnJCS
#
# DESCRIPTION
#   This function can be used to run/collect Thread Dumps on JCS
#
# PARAMETERS
#   $param1 - JCS Domain Config File (optional)
#
###############################################################
sub tfactlshare_runThreadDumpsOnJCS {
	my $config = shift;

	if ( ! $config ) {
		$config = getJCSDomainConfigFile();
	}

	my $ref = getWLSPIDList($config);
	my @pids = @{$ref};

	my $interval = getThreadDumpInterval();
	my $frequency = getThreadDumpFrequency();

	my $command;
	my $count = 0;

	print "\nCollecting Thread Dumps on JCS : \n";

	while ( $count < $frequency ) {
		$command = "kill -3 @pids";
		qx($command);
		sleep($interval);
		$count++;

		if ( $count == 1 ) {
			print "\nWaiting for Collection of Thread Dumps...\n";
		}
	}
}

############################################################
# NAME
#   tfactlshare_runHeapDumpsOnJCS
#
# DESCRIPTION
#   This function can be used to run/collect heap dumps on JCS
#
# PARAMETERS
#   $param1 - Repository Location
#   $param2 - JCS Domain Config File (optional)
#
############################################################
sub tfactlshare_runHeapDumpsOnJCS {
	my $repository = shift;
	my $config = shift;

	if ( ! $repository ) {
		use Cwd;
		$repository = getcwd();
	}

	if ( ! $config ) {
		$config = getJCSDomainConfigFile();
	}

	my $ref = getWLSPIDList($config);
	my @pids = @{$ref};
	my $count = 0;
	my $length = scalar(@pids);
	my $hostname = tolower_host();
	my $command;
	my $tag;
	my $pid;

	while ( $count < $length ) {
		$pid = $pids[$count];
		$tag = $hostname . "_" . $pid . "_HEAP_DUMP.hprof";
		$tag = catfile($repository, $tag);

		$command = "jmap -dump:format=b,file=" . $tag . " " . $pid;

		if ( ($count + 1) < $length ) {
			$command = $command . " &";
		}
		system($command);
		$count++;
	}
}

sub addDirectoryUsingFile {
	my $tfa_home = shift;
	my $file = shift;

	if ( isTFARunning($tfa_home) == FAILED ) {
		exit 0;
	}

	if ( ! -e $file ) {
		print "\nUnable to add directories to TFA, Directory File not found\n";
		return;
	}

	my $localhost = tolower_host();
	my $actionmessage = "$localhost:addclouddirectory:$file";
        if ( $tfactlglobal_hash{"debugmask"} &
             $tfactlglobal_mod_levels{"tfactlshare_non_daemon"} ) {
          tfactlshare_trace(5, "tfactl (PID = $$) " . "addDirectoryUsingFile actionmessage $actionmessage",
                            'y', 'y');
        }
	
	my $sudo_user = $ENV{SUDO_USER};
	my $sudo_command = $ENV{SUDO_COMMAND};
	if ($sudo_user && $sudo_command =~ /tfactl/) {
		$actionmessage .= ":$sudo_user";
	} else {
		$actionmessage .= ":$current_user";
	}

	my @tmp = tfactlshare_readFileToArray($file);
	my $lines = $#tmp+1;
	dbg(DBG_WHAT, "Running adddirectory through Java CLI\n");
	my $command = buildCLIJava($tfa_home,$actionmessage);
	my $line;

	my @cli_output = tfactlshare_runClient($command);
	foreach my $line (@cli_output) {
		if ( $line =~ /COUNT :/ ) {
			my $count = $line;
			$count =~ s/COUNT : //;
			$count = trim($count);
			local $| = 1; #flush immediately
			my $percent = int($count * 100 / $lines);
			print "Added $count/$lines directories to TFA... $percent%";
			print "\r";
		} elsif ( $line  =~ /SUCCESS/ ) {
			print "\n\nSuccessfully added directories to TFA\n";
			return SUCCESS;
		} elsif ($line =~ /FAILED : Directory is already present in TFA/) {
			print "No new directories were added to TFA\n";
			return SUCCESS;
		} elsif ($line =~ /No directories were added to TFA/) {
			print "No new directories were added to TFA\n";
			return SUCCESS;
		} elsif ($line eq "FAILED") {
			return FAILED;
		}
		elsif ( $line =~ /WARNING - Certificate/ ) {
		  print "$line\n";  
		}
		elsif ( $line =~ /FAIL - Certificate/) {
		  print "$line\n"; 
		  exit; 
		}
	}
	close(CMD);
}

sub printCloudDirectories {
	my $ref = shift;
	my %dirs = %{$ref};
	my $localhost = tolower_host();

	my $key;
	my $value;
	my @values;
	
	my $table = Text::ASCIITable->new();
	$table->setCols("Product ID", "Product Name", "Type", "Location");
	$table->setOptions({"outputWidth" => $tputcols, "headingText" => $localhost});

	while( ( $key, $value ) = each %dirs ) {
		@values = split(/!!/, $value);
		$table->addRow($key, $values[0], $values[1], $values[3]);
	}
	print "\n$table";
}

sub printHashAsTable {
	my $ref = shift;
	my %hash = %{$ref};
	my $heading = shift;

	if ( ! $heading ) {
		$heading  = tolower_host();
	}

	my $table = Text::ASCIITable->new();
	$table->setCols("Parameter", "Value");
	$table->setOptions({"outputWidth" => $tputcols, "headingText" => $heading});

	my $key;
	my $value;
	while ( ( $key, $value ) = each %hash ) {
		$table->addRow($key, $value);
	}
	print "\n$table";
}

sub printListAsTable {
	my $ref = shift;
	my @list = @{$ref};
	my $colname = shift;
	my $heading = shift;

	if ( ! $colname ) {
		$colname = "Value";
	}

	if ( ! $heading ) {
		$heading  = tolower_host();
	}

	my $table = Text::ASCIITable->new();
	$table->setCols("No.", "$colname");
	$table->setOptions({"outputWidth" => $tputcols, "headingText" => $heading});

	my $i = 1;
	my $item;
	foreach $item ( @list ) {
		$table->addRow($i, $item);
		$i = $i + 1;
	}
	print "\n$table";
}	

sub getJavaHomeOnCloud {
	my $java_home = get_java_home($tfa_home);
        my $javaexe;
        if ( $IS_WINDOWS ) {
           $javaexe = catfile($java_home,"bin","java.exe");
        } else {
           $javaexe = catfile($java_home,"bin","java");
        }
        return $java_home if -e $javaexe;
	my $command = "find /usr/lib -type d -name jre 2> $DEVNULL";
	my $output = qx($command);
	chomp($output);

	my @homes = split(/\n/, $output); 
	my $length = scalar @homes;
	my $default = 0;
	my $version;

	if ( $length > 0 ) {
		my $home;
		my $i = 1;
		my $option = 0;

		foreach $home ( @homes) {
			$version = tfactlshare_getJavaVersion($home);
			if ( $version >= 1.8 ) {
				$default = $i;
			}
			$i++;
		}
	}

	if ( $default > 0 ) {
		$default = $default - 1;
		$java_home = $homes[$default];
	} else {
		print "\nUnable to find JAVA_HOME\n";
		print "\nPlease Enter a Java Home that contains Java 1.8 or later : ";
		chomp ( $java_home = <STDIN> );
		$java_home = trim($java_home);
		if ( -d "$java_home" ) {
			$version = tfactlshare_getJavaVersion($java_home);
		} else {
			$version = 0;
		}

		while ( $version < 1.8 ) {
			print "\nPlease Enter valid JAVA_HOME : ";
			chomp ( $java_home = <STDIN> );
			$java_home = trim($java_home);

			if ( -d "$java_home" ) {
				$version = tfactlshare_getJavaVersion($java_home);
			} else {
				$version = 0;
			}
		}
	}
	return $java_home;
}

sub configureTFABase {
	my $tfa_home = shift;
	my $tfa_base = shift;

	if ( ! -f catfile($tfa_home, "tfa_setup.txt") ) {
		print "Unable to find TFA Configuration Files. Exiting now...\n";
		return -1;
	}

	# get TFA_BASE from home directory if it is null
	my $home_dir = getHomeDirectory();
	$home_dir = catfile($home_dir, ".tfa");

	if ( ! -d "$home_dir" ) {
		mkpath($home_dir);
	}
        tfactlshare_trace(5, "tfactl (PID = $$) " . "tfactlshare configureTFABase " .
                          "tfa_home $tfa_home", 'y', 'y');
        tfactlshare_trace(5, "tfactl (PID = $$) " . "tfactlshare configureTFABase " .
                          "home_dir $home_dir", 'y', 'y');

	my $java_home;

	if ( -f catfile($home_dir, "tfa_setup.txt") ) {
		$tfa_base = getTFABase( catfile($home_dir, "tfa_setup.txt") );
	} else {
		#TODO changes regarding windows path need to be done in this block
		#TODO kept as is right now
		$tfa_base = createTFABase($tfa_home);
                tfactlshare_trace(5, "tfactl (PID = $$) " . "tfactlshare configureTFABase " .
                                  "tfa_base $tfa_base", 'y', 'y');
                
                copy(catfile($tfa_home, "tfa_setup.txt"), $home_dir) or die "Couldn't Copy tfa_setup.txt: $!";
                copy(catfile($tfa_home, "internal", "config.properties"), $home_dir) or die "Couldn't Copy config.properties: $!";

		# Change Permissions of Config File
		chmod(0640, catfile($home_dir, "tfa_setup.txt")) or die "Couldn't chmod tfa_setup.txt : $!";
		chmod(0640, catfile($home_dir, "config.properties")) or die "Couldn't chmod config.properties : $!";

		tfactlshare_updateTFAConfig(catfile($home_dir, "tfa_setup.txt"), "TFA_BASE", $tfa_base, "silent");
                tfactlshare_updateTFAConfig(catfile($tfa_home, "tfa_setup.txt"), "SUPPORT_MODE","TRUE","silent");
                tfactlshare_updateTFAConfig(catfile($tfa_home, "tfa_setup.txt"), "DAEMON_OWNER",tfactlshare_getUserName(),"silent");
		open(RF, ">>", catfile($home_dir, "tfa_setup.txt")) or die "Can't open file tfa_setup.txt : $!\n";

		# TFA_HOME
		if ( $IS_ADE ) {
			print RF "TFA_HOME=$ENV{ADE_VIEW_ROOT}/oracle/tfa/lib/tfa_home\n";
		} else {
			print RF "TFA_HOME=$tfa_home\n";
		}
		print RF "SUPPORT_MODE=TRUE\n";

		# Node Type
		my $db_home;
		if ( $ISJCS ) {
			print RF "NODE_TYPE=JCS\n";
		} elsif ( tfactlshare_isTFAOnFMW() ) {
			print RF "NODE_TYPE=FMW\n";
                } elsif ( $IS_ADE ) {
			print RF "NODE_TYPE=ADE_ND\n";
		} else {
			print RF "NODE_TYPE=SI\n";
		}

		# JAVA Home
		my $javac = qx(which javac 2> $DEVNULL);
		$javac = trim($javac);

                if ( length $SETUPND_JAVAHOME && -r catdir($SETUPND_JAVAHOME,"bin","java") ) {
                  $java_home = catdir($SETUPND_JAVAHOME);
                }
                elsif ( -d catdir($tfa_home,"jre") ) {
		  $java_home = catdir($tfa_home,"jre");
		} 
		elsif ( $IS_ADE && $ENV{ORACLE_HOME} ) {
		  $db_home = $ENV{ORACLE_HOME}; 
		  $java_home = catdir($db_home, "jdk","jre");
		}
		elsif ( $tfa_home =~ /$SI_REL_DIR$/ ) {
			$db_home = $tfa_home;
			$db_home =~ s/$SI_REL_DIR//;
			$java_home = catdir($db_home, "jdk", "jre");
		}
		elsif ( -f "$javac" ) {
			if ( -l "$javac" ) {
				$javac = abs_path($javac);
			}
			$java_home = $javac;
			$java_home =~ s/\/bin\/javac//;
		}
		elsif ( $ENV{JAVA_HOME} ) {
                        my $javahomevar = $ENV{JAVA_HOME};
                        if ((length $javahomevar) && (-f catfile($javahomevar, "bin", "java"))) {
				$java_home = $javahomevar;
                        }
		}

		my $version = 0;
		if ( -d "$java_home" ) {
			$version = tfactlshare_getJavaVersion($java_home);
		}
		if ( $version < 1.8 ) {
			$java_home = getJavaHomeOnCloud();
		}

		if ( ! $IS_ADE ) {
			$java_home = abs_path($java_home);	
		}
		print "\nJAVA_HOME for running TFA : $java_home\n";
		print RF "JAVA_HOME=$java_home\n";

		# PERL 
		my $perl = "perl";
		if ( -f $ENV{PERL} ) {
		  $perl = $ENV{PERL};
		} else { 
			if ($IS_WINDOWS) {
                                my @defperl = split /\n/, `where perl 2>&1`;
                                if ( @defperl ) {
                                  $perl = tfactlshare_getLatestPerl(@defperl);
                                  $perl = "perl" if not length $perl;
                                }
			} else {
				if ( -f catfile("$ENV{ORACLE_HOME}","perl","bin","perl") ) {
                                  $perl = catfile($ENV{ORACLE_HOME},"perl","bin","perl");
                                } elsif ( -f catfile("", "usr", "bin", "perl") ) {
				  $perl = catfile("", "usr", "bin", "perl");
				}
			}
		}

		if ( ! $IS_ADE ) {
			$perl = abs_path($perl);
		}
		print RF "PERL=$perl\n";
		close(RF);

		# Copy tfactl to DB HOME
		if ( $tfa_home =~ /$SI_REL_DIR$/ || $IS_ADE ) {
			host("cp -f $tfa_home/bin/tfactl $db_home/bin/tfactl");
		}
	}
	
	# Copy Directories to TFA_BASE
	if ( ! -d catfile($tfa_base, "internal") ) {
		osutils_cp(catfile($tfa_home, "internal"), $tfa_base, 1);
		osutils_cp(catfile($tfa_home, "resources"), $tfa_base, 1);
		osutils_cp(catfile($tfa_home, "install"), $tfa_base, 1);

		if ( ! -d catdir($tfa_base, "database") ) {
			mkpath(catdir($tfa_base, "database", "BERKELEY_JE_DB"));
		}

		if ( ! -d catdir($tfa_base, "log") ) {
			mkpath(catdir($tfa_base, "log"));
		}

		if ( ! -d catdir($tfa_base, "output") ) {
			mkpath(catdir($tfa_base, "output", "inventory"));
		}

		if ( ! -d catdir($tfa_base, "input") ) {
			mkpath(catdir($tfa_base, "input"));
		}

		copy(catfile($home_dir, "tfa_setup.txt"), $tfa_base);
		copy(catfile($tfa_home, "tfa_directories.txt"), $tfa_base);
		copy(catfile($home_dir, "config.properties"), catfile($tfa_base, "internal"));

		# Configure directories
                if ( $tfactlglobal_hash{"debugmask"} &
                     $tfactlglobal_mod_levels{"tfactlshare_non_daemon"} ) {
                  tfactlshare_trace(5, "tfactl (PID = $$) " . "configureTFABase, about to run configureCloudComponents ...",
                                    'y', 'y');
                } 

	 	configureCloudComponents($tfa_home, $tfa_base);
	 	
                if ( $tfactlglobal_hash{"debugmask"} &
                     $tfactlglobal_mod_levels{"tfactlshare_non_daemon"} ) {
                  tfactlshare_trace(5, "tfactl (PID = $$) " . "configureTFABase, ran configureCloudComponents($tfa_home,$tfa_base)",
                                    'y', 'y');
                }

	}

	my $jaas_properties = getJCSPropertiesFile();

	if ( -f "$jaas_properties" ) {
		my $jaas_config = getJCSDomainConfigFile($jaas_properties);

		if ( -f "$jaas_config" ) {
			my $ref = discoverNodesOnCloud($jaas_config);
			my @nodelist = @{$ref};

			my $nodefile = catfile($tfa_base, "internal", "cloudnodes.lst");

			open (WR, ">", $nodefile);
			
			foreach my $node ( @nodelist ) {
				print WR "$node\n";
			}

			printListAsTable(\@nodelist, "Nodes", "Domain Node List");
		}
	} 

	my %summary = ('TFA HOME', $tfa_home, 'TFA_BASE', $tfa_base, 'JAVA_HOME', $java_home, 'Repository', "$tfa_base/repository");
	printHashAsTable(\%summary, "Summary of TFA Configuration");

	return $tfa_base;
} # end sub configureTFABase

sub getJCSPropertiesFile {
	my $jaas_properties = catfile("", "u01", "data", "domains", "jaas.properties");
	return $jaas_properties;
}

sub getJCSDomainConfigFile {
	my $jaas_properties = shift;
	my $jaas_config;

	if ( ! $jaas_properties ) {
		$jaas_properties = getJCSPropertiesFile();
	}

	if ( -f "$jaas_properties" ) {
		my $jaas_domain = tfactlshare_getConfigValue($jaas_properties, "DOMAIN_HOME");
		$jaas_config = catfile($jaas_domain, "config", "config.xml");
	}

	return $jaas_config;
}

sub tfactlshare_isTFAOnJCS {
	my $jaas_properties = getJCSPropertiesFile();

	if ( -f "$jaas_properties" ) {
		$ISJCS = 1;
		return 1;
 	} else {
		return 0;
	}
}

# Subroutine to check if TFA is on FMW/SaaS
# TODO : Need to verify for all FMW Products
sub tfactlshare_isTFAOnFMW {
	my $appltop = catfile("", "u01", "APPLTOP", "instance");
	if ( -f "$appltop" ) {
		$ISFMW = 1;
		return 1;
	} else {
		return 0;
	}
}

sub createTFABase {
	my $tfa_home = shift;
	my $localhost = tolower_host();
	my $username = tfactlshare_getUserName();
	if ($IS_WINDOWS) {
		$username = tfactlshare_getEscapedUserName($username);
	}
	my $tfa_base = $ENV{ORA_TFA_BASE};
        my $home_dir = getHomeDirectory();
        $home_dir = catfile($home_dir, ".tfa");

	if ( ! $tfa_base ) {
		if ( $ISJCS ) {
			$tfa_base = catfile("", "u01", "app", "oracle", "tools");
		} else {
			$tfa_base = getTFABase(catfile($home_dir, "tfa_setup.txt"));

			if ( ! $tfa_base ) {
				if($IS_WINDOWS){
					#NOTE : Kept C Drive path as default tmp path
					mkpath("C:\\");
					$tfa_base = catfile ("C:\\");
				}else{
                                        if ( $tfa_home =~ /(.*)\/tfa\/tfa_home.*/ ) {
                                          $tfa_base = catfile($1,"oracle.tfa");
                                        } else {
  					  $tfa_base = catfile ("", "tmp", "oracle.tfa");
                                        }
                                        # print "createTFABase tfa_base $tfa_base\n";
				}
			}
		}
	}

	# print "\nDefault TFA_BASE : $tfa_base\n";

	#print "\nTFA_BASE is the base directory for all the files generated by TFA";
	#print "\n/tmp is not recommended for TFA_BASE as we may loose data after reboot\n";

	#print "\nWould you like to update TFA_BASE ? [y|n] [y] : ";

	my $option;
	#chomp( $option = <STDIN> );
	$option ||= "n";
	$option = get_valid_input ($option, "y|Y|n|N", "Y");

	if ( $option =~ /[Yy]/ ) {
		print "\nPlease Enter location for TFA_BASE : ";
		chomp( $tfa_base = <STDIN> );
		$tfa_base = trim($tfa_base);

		while ( ! $tfa_base || $tfa_base =~ /^\./ ) {
			print "\nPlease Enter valid location for TFA_BASE : ";
			chomp( $tfa_base = <STDIN> );
			$tfa_base = trim($tfa_base);
		}

		if ( $tfa_base !~ /\/oracle\.tfa$/ ) {
			$tfa_base = catfile ($tfa_base, "oracle.tfa");
		}
	}

	if ( $tfa_base !~ /\/oracle\.tfa$/ ) {
		$tfa_base = catfile ($tfa_base, "oracle.tfa");
	}

	$tfa_base = catfile ($tfa_base, $localhost);

	if ( ! -d "$tfa_base" ) {
		eval {
			mkpath($tfa_base);
			chmod(oct(1755), $tfa_base);
		};
		if ( $@ ) {
			print "Error while creating TFA_BASE $tfa_base :\n";
			print "$@\n";
			exit 1;
		}
	}

	$tfa_base = catdir($tfa_base, $username);
	$tfa_base = catdir($tfa_base, $ENV{ADE_VIEW_NAME}) if ( $IS_ADE );
	print "\nTFA_BASE for user $username : $tfa_base\n";
	eval { mkpath($tfa_base); };
	if ( $@ ) {
		print "Error while creating TFA_BASE $tfa_base :\n";
		print "$@\n";
		exit 1;
	}
	return $tfa_base;
}

sub getTFABase {
	my $tfa_setup = shift;
	my $tfa_base = "";

	if ( ! -f "$tfa_setup" ) {
		my $home_dir = getHomeDirectory();
		$home_dir = catfile($home_dir, ".tfa");

		if ( -f catfile($home_dir, "tfa_setup.txt") ) {
			$tfa_setup = catfile($home_dir, "tfa_setup.txt");
		} else {
			return $tfa_base;
		}
	}

	open(RF, "$tfa_setup" ) or print "Unable to open file $tfa_setup...\n";

	while( <RF> ) {
		chomp;
		if ( /^TFA_BASE=(.*)/ ) {
			$tfa_base = $1;
			last;
		}
	}
	close(RF);

	if ( ! -d "$tfa_base" ) {
		if ( ! $ISCLOUD ) {
			tfactlshare_signal_exception(208, undef);
			exit;
		}
	}
	return $tfa_base;
}


########
# NAME
#   tfactlshare_getUserName()
#
# DESCRIPTION
#   This routine gets the current user
#
# PARAMETERS
#   None.
#
# RETURNS
#   The current user.
#
# NOTES
########
sub tfactlshare_getUserName {
	my $username;
        if ( $IS_WINDOWS )
        {
            $username = tfactlshare_get_user($<);
        }
         else
        {
          $username = (getpwuid($<))[0];
        }
	return $username;
}


########
# NAME
#   tfactlshare_getEscapedUserName()
#
# DESCRIPTION
#   This routine removes "\" from the current user
#
# PARAMETERS
#   $user 	: The username
#
# RETURNS
#   The trimmed username.
#
# NOTES
########
sub tfactlshare_getEscapedUserName {
	my $user = shift;

	if (index($user,"\\")!=-1) {
		$user =~ s/\\/__/g;
	}

	return $user;
} 

sub getHomeDirectory {
	my $noupdate = shift;
	my $homedir = $ENV{ORA_TFA_USER_HOME};

	if ($IS_WINDOWS) {
		my $homeDrive = $ENV{HOMEDRIVE};
		my $homePath = $ENV{HOMEPATH};
		$homedir = $homeDrive . $homePath;
	} else {
		if ( ! $homedir ) {
			$homedir = qx(echo \$HOME);
			$homedir = trim($homedir);

			if ( ! $homedir ) {
				my $username = tfactlshare_getUserName();
				$homedir = (getpwnam($username))[7];

				if ( ! $homedir ) {
					$homedir = catdir("", "home", $username );
				}
			}

			if ( $IS_ADE ) {
				if ( ! $noupdate ) {
					my $localhost = tolower_host();
					my $view_name = $ENV{ADE_VIEW_NAME};
					$homedir = catdir($homedir, $localhost, $view_name);
				}
			}
		}
	}
	return trim($homedir);
}



sub isTFAOnCloud {
	my $tfa_home = shift;

        tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare isTFAOnCloud ISCLOUD $ISCLOUD", 'y', 'n');
	return $ISCLOUD if ( $ISCLOUD );

	my $initFile = catfile($INITDIR, "init.tfa");
        tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare isTFAOnCloud initFile $initFile", 'y', 'n');

	# No Cloud Support for NON Root Daemon
        if ( $IS_NON_ROOT_DAEMON ) {
		$ISCLOUD = 0;
		return 0;
	}
        
        my $user = tfactlshare_getUserName();
        
	if ($IS_WINDOWS) {
		$user = tfactlshare_getEscapedUserName($user);
	}
                
	tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare isTFAOnCloud user $user", 'y', 'n');

	# No Cloud Support for root user - but need to allow root on windows as we consider that an Admin User.
	if ( $user eq "root" ) {
		my $homedir = getHomeDirectory();
		if ( -d catdir($homedir, ".tfa") )  {
			my $tfahomedir = catdir($homedir, ".tfa");
			my $owner = getFileOwner($tfahomedir);
			# Remove Non Daemon Setup if exists
			if ( $owner eq "root") {
				eval {
					rmtree($tfahomedir);
				};
			} else {
				eval {
					system(tfactlshare_checksu($owner,"rm -rf $tfahomedir"));
				};
			}
		}

		$ISCLOUD = 0;
		return 0;
	}

	if ( -f "$initFile" || tfactlwin_query_OracleTFAService_status()) {
		my $pub_key = catfile($tfa_home, ".$user", $user . "_mykey.rsa.pub");
                tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare isTFAOnCloud initFile present", 'y', 'n');
                tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare isTFAOnCloud pub_key $pub_key", 'y', 'n');

		if ( ! -f "$pub_key" ) {
			my $homedir = getHomeDirectory();
                        tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare isTFAOnCloud homedir $homedir", 'y', 'n');
			if ( -d catdir($homedir, ".tfa") )  {
				my $tfa_setup = catfile($homedir, ".tfa", "tfa_setup.txt");
                                tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare isTFAOnCloud $homedir/.tfa exist", 'y', 'n');
                                tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare isTFAOnCloud tfa_setup $tfa_setup", 'y', 'n');
				if ( -f "$tfa_setup" ) {
					my $nodeType = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "NODE_TYPE", $tfa_setup);
                                        tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare isTFAOnCloud nodeType $nodeType", 'y', 'n');
					if ( $nodeType eq "SI" || $nodeType eq "JCS" || $nodeType eq "ADE_ND" || $nodeType eq "FMW") {
						$ISCLOUD = 1;
					}
				}
			} else {
                                tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare isTFAOnCloud $homedir/.tfa does not exist", 'y', 'n');
                                my $nodeType = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "NODE_TYPE");
                                tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare isTFAOnCloud nodeType $nodeType", 'y', 'n');
				if ( $tfa_home =~ /$SI_REL_DIR$/ ) {
					$ISCLOUD = 1;
                                # Allow daemon (root) & non daemon (non root) installations to coexist
				} elsif ( $nodeType ne "CELL" ) {
                                        $ISCLOUD = 1;
                                }
			}
		}
	} else {
		my $nodeType = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "NODE_TYPE");
                tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare isTFAOnCloud Not initFile, nodeType $nodeType", 'y', 'n');
		if ( $nodeType ne "CELL" ) {
			$ISCLOUD = 1;
		}
	}

	if ( ! $ISCLOUD ) {
		$ISCLOUD = 0;
	}
	
        tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare isTFAOnCloud returning ISCLOUD $ISCLOUD", 'y', 'n');
	return $ISCLOUD;	
}

sub tfactlshare_upgradeTFABase {
	my $tfa_home = shift;
	my $tfa_base = shift;
	my $homedir = shift;
      
        print "\nTFA_HOME : $tfa_home\n";
        print "TFA_BASE : $tfa_base\n";

	# Take Backup
	print "\nTaking backup of configuration files...\n";
	my $res_dir = catfile($tfa_base, "resources");

	if ( $ISJCS ) {
		qx(cp -f $res_dir/components_jcs.xml $res_dir/components_jcs.xml.bkp);
		qx(cp -f $res_dir/directory_patterns_jcs.xml $res_dir/directory_patterns_jcs.xml.bkp);
	
		# Copy files and directories from TFA_HOME
		print "\nCopying new files for JCS...\n";
		qx(cp -f $tfa_home/resources/components_jcs.xml $res_dir);
		qx(cp -f $tfa_home/resources/directory_patterns_jcs.xml $res_dir);
	} elsif ( $ISFMW ) {
		qx(cp -f $res_dir/components_saas.xml $res_dir/components_saas.xml.bkp);
		qx(cp -f $res_dir/directory_patterns_saas.xml $res_dir/directory_patterns_saas.xml.bkp);

		# Copy files and directories from TFA_HOME
		print "\nCopying new files for FMW...\n";
		qx(cp -f $tfa_home/resources/components_saas.xml $res_dir);
		qx(cp -f $tfa_home/resources/directory_patterns_saas.xml $res_dir);
	} else {
		copy(catfile($res_dir,"components.xml"), catfile($res_dir,"components.xml.bkp"));
		copy(catfile($res_dir,"directory_patterns.xml"), catfile($res_dir,"directory_patterns.xml.bkp"));

		# Copy files and directories from TFA_HOME
		print "\nCopying new files...\n";
		copy(catfile($tfa_home,"resources","components.xml"), catfile($res_dir,"components.xml"));
		copy(catfile($tfa_home,"resources","directory_patterns.xml"), catfile($res_dir,"directory_patterns.xml"));
	}

	copy(catfile($tfa_home,"internal",".buildid"), catfile("$tfa_base","internal",".buildid"));
	copy(catfile($tfa_home,"internal",".buildversion"), catfile("$tfa_base","internal",".buildversion"));
	copy(catfile($tfa_home,"internal","config.properties"), catfile("$homedir","config.properties.old"));

	# Update Configuration files
	updatePropertiesFileNew($tfa_home, catfile("$homedir","config.properties"), catfile("$homedir","config.properties.old"));
	if ( $IS_ADE ) {
		tfactlshare_updateTFAConfig(catfile($homedir, "tfa_setup.txt"), "TFA_HOME", catdir($ENV{ADE_VIEW_ROOT}, "oracle", "tfa", "lib", "tfa_home"), "silent");
		tfactlshare_updateTFAConfig(catfile($homedir, "tfa_setup.txt"), "JAVA_HOME", catdir($ENV{ORACLE_HOME}, "jdk", "jre"), "silent");
		tfactlshare_updateTFAConfig(catfile($homedir, "tfa_setup.txt"), "PERL", catdir($ENV{ORACLE_HOME}, "perl", "bin", "perl"), "silent");
	} else {
		tfactlshare_updateTFAConfig(catfile($homedir, "tfa_setup.txt"), "TFA_HOME", $tfa_home, "silent");
	}
}

sub updateSSLConfig {
        my $config = shift;
        my $value = shift;
        my $prop = shift;
        my $tfa_home = shift;

        my $configFound = 0;

        open(FILE, '<', $prop) || die "File not found";
        my @lines = <FILE>;
        close(FILE);

        my @newlines;
        my $statement;
        foreach(@lines) {
                if (/^$config=/) {
                        $statement = "$config=$value";
                        $configFound = 1;
                }
                else {
                        $statement = $_;
                }
                push(@newlines,$statement);
        }
        if(!$configFound){
        	$statement = "$config=$value";
        	push(@newlines,$statement);
        }
        open(FILE, '>', $prop) || die "File not found";
        print FILE @newlines;
        close(FILE);      
}

sub updateConfigOnCloud {
	my $config = shift;
	my $value = shift;
	my $silent = shift;

	if ( $silent ) {
		$silent = "silent";
	} else {
		$silent = 0;
	}

	# Update Configuration in Home Directory
	my $tfa_setup = getCloudSetupFile();
	tfactlshare_updateTFAConfig($tfa_setup, $config, $value, $silent);

	# Update Configuration in TFA_BASE
	my $tfa_base = getTFABase($tfa_setup);
	$tfa_setup = catfile($tfa_base, "tfa_setup.txt");

	# if config is TFA_BASE use new value
	if ( "$config" eq "TFA_BASE" ) {
		$tfa_setup = catfile($value, "tfa_setup.txt");
	}

	if ( -f "$tfa_setup" ) {
		tfactlshare_updateTFAConfig($tfa_setup, $config, $value, $silent);
	}
}

sub updateTFABase {
	my $tfa_home = shift;
	my $dir = shift;
	my $local = shift;

	my $hostname = tolower_host();
	my $homedir = getHomeDirectory();
	my $username = tfactlshare_getUserName();
	if ($IS_WINDOWS) {
		$username = tfactlshare_getEscapedUserName($username);
	}
	my $tfa_setup = catfile($homedir, ".tfa", "tfa_setup.txt");

	my $tfa_base = getTFABase($tfa_setup);

	my $new_base = $dir;

	# Add Hostname
	if ( $new_base !~ /\/$hostname$/ ) {
		$new_base = catdir($new_base, $hostname);
	}

	if ( ! -d "$new_base" ) {
		mkpath($new_base);
	}

	# Add UserName
	$new_base = catdir($new_base, $username);

	if ( $IS_ADE ) {
		mkpath($new_base);
		$new_base = catdir($new_base, $ENV{ADE_VIEW_NAME});
	}

	# Move Directories from TFA_BASE
	# qx(mv -f $tfa_base $new_base);
	eval {
		move($tfa_base, $new_base);
	};
	if ( $@ ) {
		print "Error while moving TFA_BASE $tfa_base :\n";
		print "$@\n";
		exit 1;
	}

	# Update TFA Configuration Files
	updateConfigOnCloud("TFA_BASE", $new_base, 1);

	# Update repository
	updateRepositoryOnCloud($tfa_home, catdir($dir, "repository"), 1);

	if ( $ISJCS ) {
		if ( ! $local ) {
			updateConfigOnJCSNodes($tfa_home, "tfa_base", $dir);
		}
	}		

	print "\nSuccessfully updated TFA_BASE to $dir...\n";
}

sub updateRepositoryOnCloud {
	my $tfa_home = shift;
	my $dir = shift;
	my $silent = shift;
	my $localhost = tolower_host();

	if ( ! -d "$dir" ) {
		mkpath($dir);
	}

	my $actionmessage = "$localhost:changerepository:$dir";
	my $command = buildCLIJava($tfa_home,$actionmessage);
	my $line;
	my $status = 0;
	my @cli_output = tfactlshare_runClient($command);

	foreach $line ( @cli_output ) {
		dbg(DBG_VERB,"LINE : $line\n");
		if ( $line =~ /SUCCESS/ ) {
			$status = 1;
		}
	}

	if ( ! $silent ) {
		if ( $status ) {
			print "\nSuccessfully updated TFA Repository to $dir...\n";
		} else {
			print "\nUnable to update TFA Repository to $dir...\n";
		}
	}
}

sub updateConfigOnJCSNodes {
	my $tfa_home = shift;
	my $config = shift;
	my $value = shift;
	my $localhost = tolower_host();

	my $ref = tfactlshare_getNodeListOnCloud();
	my @nodelist = @{$ref};

	foreach my $node ( @nodelist ) {
		next if ( $node eq $localhost );
		my $tfactl = catfile($tfa_home, "bin", "tfactl");
		my $command = "$SSH $node \"$tfactl set $config=$value -local\"";
		system($command);
	}
}

##########################################
# NAME
#   tfactlshare_updateThreadDumpInterval
#
# DESCRIPTION
#   This function is to update Thread Dump Interval on JCS
#
# PARAMETERS
#   $param1 - tfa_home
#   $param2 - value of thread dump interval
#   $param3 - is only on localhost or on all JCS Nodes
#
##########################################
sub tfactlshare_updateThreadDumpInterval {
	my $tfa_home = shift;
	my $interval = shift;
	my $local = shift;

	my $homedir = getHomeDirectory();
	my $config = catfile($homedir, ".tfa", "config.properties");
	tfactlshare_updateTFAConfig($config, "ThreadDumpInterval", $interval);
	
	if ( ! $local ) {
		updateConfigOnJCSNodes($tfa_home, "ThreadDumpInterval", $interval);
	}
}

##########################################
# NAME
#   tfactlshare_updateThreadDumpFrequency
#
# DESCRIPTION
#   This function is to update Thread Dump Frequency on JCS
#
# PARAMETERS
#   $param1 - tfa_home
#   $param2 - value of thread dump Frequency
#   $param3 - is only on localhost or on all JCS Nodes
#
##########################################
sub tfactlshare_updateThreadDumpFrequency {
	my $tfa_home = shift;
	my $frequency = shift;
	my $local = shift;

	my $homedir = getHomeDirectory();
	my $config = catfile($homedir, ".tfa", "config.properties");
	tfactlshare_updateTFAConfig($config, "ThreadDumpFrequency", $frequency);
	
	if ( ! $local ) {
		updateConfigOnJCSNodes($tfa_home, "ThreadDumpFrequency", $frequency);
	}
}

sub updateJavaHome {
	my $tfa_home = shift;
	my $java_home = shift;
	my $local = shift;

	if ( -d "$java_home" ) {
		if ( ! -f catfile($java_home, "bin", "java") ) {
			print "\nUnable to find Java Binaries under $java_home. Please try again.\n";
		}
	} else {
		print "\nUnable to find directory $java_home. Please try again.\n";
		return;
	}

	if ( $ISCLOUD ) {
		updateConfigOnCloud("JAVA_HOME", $java_home);
	} else {

		my $java = catfile($java_home, "bin", "java");
		my $owner = getFileOwner($java);

		if ( $owner ne "root" ) {
			print "\nJava Binaries $java need to owner by root. Please try again.\n";
			return;
		}
		# Compare Java Versions
		my $newJavaVer = tfactlshare_getJavaVersion($java_home);

		my $currentJavaHome = get_java_home($tfa_home);
		my $currentJavaVer = tfactlshare_getJavaVersion($currentJavaHome);

		if ( $newJavaVer > $currentJavaVer ) {
			tfactlshare_updateTFAConfig(catfile($tfa_home, "tfa_setup.txt"), "JAVA_HOME", $java_home);
			tfactlshare_updateTFAConfig(catfile($tfa_home, "internal", "config.properties"), "JAVA_HOME", $java_home);
			tfactlshare_updateTLSProtocol($tfa_home, $newJavaVer);

			if ( ! $local ) {
				my $localhost = tolower_host();
				my $message ="$localhost:updateJavaHome:$java_home";
				my $command = buildCLIJava($tfa_home, $message);
				my $line;
				my @cli_output = tfactlshare_runClient($command);
				foreach $line ( @cli_output ) {
					if ( $line eq "SUCCESS" ) {
						print "\nSuccessfully updated JAVA_HOME on remote nodes...\n";
					} else {
						print "\nUnable to update JAVA_HOME on remote nodes...\n";
					}
				}

				print "\nSleeping for 60 Seconds...\n";
				sleep(60);
			}

			print "\nRestarting TFA on locahost...\n";
			my $inittfa = catfile($INITDIR, "init.tfa");
			my $restartcmd = "$inittfa restart";
			qx($restartcmd);
		} else {
			print "Unable to update Java Home as TFA is already running latest Java Version [$currentJavaVer]";
		}
	}
}

sub tfactlshare_updateTLSProtocol {
	my $tfa_home = shift;
	my $version = shift;
	my $protocol = "TLS";

	if ( ! $version ) {
		my $java_home = get_java_home($tfa_home);
		$version = tfactlshare_getJavaVersion($java_home);
	}

	if ( $version >= 1.7 ) {
		$protocol = "TLSv1.2";
	}

	tfactlshare_updateTFAConfig(catfile($tfa_home, "internal", "config.properties"), "protocol", $protocol);
}

sub tfactlshare_getJavaVersion {
	my $java_home = shift;
	my $version = "1.4";

	my $java;
	if ($IS_WINDOWS) {
		$java = catfile($java_home, "bin", "java.exe");
	} else {
		$java = catfile($java_home, "bin", "java");
	}

	if ( -f "$java" ) {
		my $cmd;
		my $ver;

		if ($java =~ /\s{1,}/) {
			$java = "\"" . $java . "\"";
		}

		if ($IS_WINDOWS) {
			$cmd = "$java -version";
			$ver = `$cmd 2>&1`;
		} else {
			$ver = qx($java -version 2>&1 > $DEVNULL);
		}
		$ver = (split(/\n/, $ver))[0];

		if ( $ver =~ /version \"(\d)\.(\d)/ ) {
			$version = "$1.$2";
		}
	}
	return $version;
}

##########################################
# NAME
#   tfactlshare_updateClusterMode
#
# DESCRIPTION
#   This function will check CRS_HOME and update tfaClusterMode and publicIp in config.properties
#
# PARAMETERS
#   $param1 - tfa_home
#
##########################################
sub tfactlshare_updateClusterMode {
	my $tfa_home = shift;

	my $clusterMode = tfactlshare_getConfigValue(catfile($tfa_home, "internal", "config.properties"), "tfaClusterMode");
	$clusterMode = trim($clusterMode);

	if ( ! $clusterMode || ( $clusterMode && $clusterMode eq "false" ) || $IS_ODADom0 ) {
		my $crs_home = get_crs_home($tfa_home);
		$crs_home = trim($crs_home);

		if ( ($crs_home && -d "$crs_home" ) || $IS_ODADom0 || $IS_ODA ) {
			if ( ! $IS_ODADom0 ) {
				tfactlshare_updateTFAConfig(catfile($tfa_home, "internal", "config.properties"), "tfaClusterMode", "true", "silent");
			}

			# Remove port.txt and portmapping.txt if already running on Loopback IP Address
			my $publicIp = tfactlshare_getConfigValue(catfile($tfa_home, "internal", "config.properties"), "publicIp");
			$publicIp = trim($publicIp);

			if ( $publicIp && $publicIp eq "false" ) {
				my $portFile = catfile($tfa_home, "internal", "port.txt");
				if ( -f "$portFile" ) {
					unlink $portFile;
				}

				my $portMapping = catfile($tfa_home, "internal", "portmapping.txt");
				if ( -f "$portMapping" ) {
					unlink $portMapping;
				}

				# Update publicIp in config.properties
				tfactlshare_updateTFAConfig(catfile($tfa_home, "internal", "config.properties"), "publicIp", "true", "silent");
			}
		}
	}
}

sub tfactlshare_updateTFAConfig {
	my $tfa_setup = shift;
	my $config = shift;
	my $value = shift;
	my $silent = shift;
	
    	my $PERL;
    	if ( (-f $tfa_setup) && 
        	length ($PERL=tfactlshare_getConfigValue(catfile($tfa_home,"tfa_setup.txt"),"PERL")) ) {
    	} elsif ($ENV{PERL}) {
    		$PERL = $ENV{PERL};
    	} else {
    		$PERL = "perl";
    	}
    	tfactlshare_trace(5, "tfactl (PID = $$) " . "tfactlshare_updateTFAConfig " .
                          "PERL $PERL", 'y', 'y');

	if ( -w "$tfa_setup" ) {
	        tfactlshare_trace(5, "tfactl (PID = $$) " . "tfactlshare_updateTFAConfig " .
                          "tfa_setup $tfa_setup", 'y', 'y');

	        if ($IS_WINDOWS) {
		  #Calling the script to update the key-value pair since perl sometimes delays the flush of the changes into the properties file in the secondary memory.
		  my $command = $PERL . " " . catfile($tfa_home, "bin", "updateTFAConfig.pl") . " updateConfig $tfa_setup $config $value " . $tfa_home;
		  my $retVal = `$command`;
			 
		  if ( ! $silent && $retVal == 1) {
		    print "\nSuccessfully updated $config to $value in TFA...\n";
	      	  } elsif ( ! $silent && $retVal == 0) {
	            print "\nSuccessfully added $config to TFA...\n";
		  } else {
		    print "$retVal\n";
		  }
		} else {
			my $old_value;
			my $line = 0;

			open(RF, "$tfa_setup" ) or print "Unable to open file $tfa_setup...\n";
			while( <RF> ) {
				chomp;
				if ( /^$config=(.*)/ ) {
					$old_value = $1;
					$line = $.;
					last;
				}
			}
			close(RF);

			if ( $line > 0 ) {
				my $tmp_value = $value;
				$tmp_value =~ s/\\/\\\\/g;
				my $backup_file = $tfa_setup . "\.old";
				unlink($backup_file) if (-f $backup_file);
	
				my $command = "$PERL -p -i.old -e \"s{^$config=.*}{$config=$tmp_value}g\" $tfa_setup";
	                        tfactlshare_trace(5, "tfactl (PID = $$) " . "tfactlshare_updateTFAConfig " .
	                                          "command $command", 'y', 'y');
				qx($command);
				if ( ! $silent ) {
					print "\nSuccessfully updated $config to $value in TFA...\n";
				}
			} else {
				open(RF, ">>", "$tfa_setup" ) or print "Unable to open file $tfa_setup...\n";
				print RF "$config=$value\n";
				close(RF);
				if ( ! $silent ) {
					print "\nSuccessfully added $config to TFA...\n";
				}
			}
		}
	} else {
		print "\nUnable to update TFA Configuration file $tfa_setup\n";
	}
}
        
# Java on SunOS
sub getJavaOnSunOS
{
	my $java_home = shift;
	my $tool = shift;

	$tool = "java" if ( ! $tool );

	# Get version of JAVA
	my $java = catfile($java_home, "bin", "java");
	my $version = qx($java -version 2>&1 > $DEVNULL);
	$version = (split(/\n/, $version))[0];

	# Use Standard JAVA if version is 1.8
	if ( $version =~ /1\.8\./ ) {
		$tool = catfile($java_home, "bin", $tool);
	} elsif ( -e catfile("$java_home", "bin", "amd64", $tool) ) {
		$tool = catfile("$java_home", "bin", "amd64", $tool);
	} elsif ( -e catfile("$java_home", "bin", "sparcv9", $tool) ) {
		$tool = catfile("$java_home", "bin", "sparcv9", $tool);
	}
	return $tool;
}

sub tfactlshare_getSetupFilePath 
{
  my $tfa_home = shift;
  my $setupfile = catfile ($tfa_home, "tfa_setup.txt");
  if ( $ISCLOUD ) {
    my $homedir = getHomeDirectory();
    $homedir = catfile($homedir, ".tfa");
    if ( -f catfile($homedir, "tfa_setup.txt") ) {
      $setupfile = catfile($homedir, "tfa_setup.txt" );
    }
  }
  return $setupfile;
}

#======================= buildCLIJava =========================#
#
sub buildCLIJava
#
#
{
my ($tfa_home, $args) = @_;
#Added below line to make sure that Interrupt signals provided during the 
#execution of the java commands through backticks do not result into core dump. 
#Capturing signal and exiting. It is for handling coredump  on Solaris10.
$SIG{INT} = 'DEFAULT';
#Build the command line for TFA java

my $class = "oracle.rat.tfa.CommandLine";
my $paramfile = tfactlshare_getSetupFilePath($tfa_home);
my $tfa_jar = catfile($tfa_home, "jlib", "RATFA.jar");
my $tfa_bd_jar = catfile($tfa_home, "jlib","je-6.4.25.jar");
my $commons_io_jar = catfile($tfa_home,"jlib","commons-io-2.6.jar");
my $mail_jar = catfile("$tfa_home","jlib","javax.mail.jar");

my $lc_jar = catfile("$tfa_home","jlib","lucene-core-6.6.0.jar");
my $la_jar = catfile("$tfa_home","jlib","lucene-analyzers-common-6.6.0.jar");
my $lq_jar = catfile("$tfa_home","jlib","lucene-queryparser-6.6.0.jar");
my $lcd_jar = catfile("$tfa_home","jlib","lucene-codecs-6.6.0.jar");
my $lqu_jar = catfile("$tfa_home","jlib","lucene-queries-6.6.0.jar");
my $lfa_jar = catfile("$tfa_home","jlib","lucene-facet-6.6.0.jar");
my $lex_jar = catfile("$tfa_home","jlib","lucene-expressions-6.6.0.jar");
my $lgp_jar = catfile("$tfa_home","jlib","lucene-grouping-6.6.0.jar");
my $lhr_jar = catfile("$tfa_home","jlib","lucene-highlighter-6.6.0.jar");
my $json_jar = catfile("$tfa_home","jlib","javax.json-1.0.4.jar");

my $crs_home = get_crs_home($tfa_home);
#Add SRVM and Event Jars
my $eventJars = "";
if ( catfile($crs_home,"jlib","srvm.jar") and catfile($crs_home,"jlib","clsce.jar") ) {
   $eventJars = "$PSEP". catfile($crs_home,"jlib","srvm.jar");
   $eventJars = $eventJars . "$PSEP". catfile($crs_home,"jlib","clsce.jar");
}

my $addRJars = 0;
my $runmode = tfactlshare_getConfigValue($paramfile, "RUN_MODE");
if ( $runmode ) {
    $addRJars = 1;
}

chomp($args);
if ($args =~ /^RUN_EVENTS (.*)/) {
  $args = $1;
  $class = "oracle.rat.tfa.index.TFAIndexSearcher";
}
elsif ($args =~ /^RUN_ANALYZE (.*)/) {
  $args = $1;
  $class = "oracle.rat.tfa.index.TFAIndexSearcher";
}

my $java = catfile($tfa_home, "jre","bin","java$EXE");

if ( ! -e "$java" )
{
  my $java_home = get_java_home ($tfa_home, $paramfile);
  $java = catfile($java_home,"bin","java$EXE");

  # Changes for SunOS 64 bit server
  if ( $osname eq "SunOS" ) {
	$java = getJavaOnSunOS($java_home, "java");
  }
}

my $classpath = "";
if ( $addRJars ) {
   $classpath = "$tfa_jar$PSEP$tfa_bd_jar$PSEP$commons_io_jar$PSEP$lc_jar$PSEP$la_jar$PSEP$lq_jar$PSEP$lfa_jar$PSEP$lqu_jar$PSEP$lcd_jar$PSEP$lex_jar$PSEP$mail_jar$PSEP$lgp_jar$PSEP$lhr_jar$PSEP$json_jar$eventJars";
} else {
   $classpath = "$tfa_jar$PSEP$tfa_bd_jar$PSEP$commons_io_jar$PSEP$lc_jar$PSEP$la_jar$PSEP$lq_jar$PSEP$lfa_jar$PSEP$lqu_jar$PSEP$lcd_jar$PSEP$lex_jar$PSEP$mail_jar$PSEP$lgp_jar$PSEP$lhr_jar$PSEP$json_jar$eventJars";
}

my $portfile = catfile ("$tfa_home","internal", "port.txt");

if ( $current_user ne $DAEMON_OWNER ) {
  $portfile = catfile ("$tfa_home","internal", "NonRootport.txt");
}

if ( isOfflineMode($paramfile) ) {
  $class = "oracle.rat.tfa.OfflineMessageHandler";
  chomp $args;
  $args = "$args -tfaHome $tfa_home";
  #Add Oracle Wallet Jars
  my $oraclepki = catfile($tfa_home,"jlib","oraclepki.jar");
  if (-e $oraclepki) {
    $classpath = "$classpath$PSEP$oraclepki";
  }
} 
else {
  my $port_number = getPortNumber($portfile);
  chomp $args;
  if ($class !~ /TFAIndexSearcher/) { 
    $args = "$args -port $port_number -tfaHome $tfa_home";
  }
}

$ENV{CLASSPATH}=$classpath;
my $commandline;

if ( $^O eq "hpux" ) {
	$commandline = "$java -Xms128m -Xmx256m -XX:+UseGetTimeOfDay $class $args";
} else {
	$commandline = "$java -Xms128m -Xmx256m $class $args";
}

if ($HPROF_ON==1) {
        my $hprofargs = "-agentlib:hprof=cpu=samples,depth=10,thread=y,interval=20,file=";
        my $dumpfile;
	if ($args =~ /runinventory/) {
		$dumpfile = catfile($tfa_home,"output","inventory","invprof.txt");
	}
	if ($args =~ /runodscan/) {
		$dumpfile = catfile($tfa_home,"output","inventory","scanprof.txt");
	}
        $hprofargs = $hprofargs . "$dumpfile";
        $commandline = "$java -Xms128m -Xmx256m $hprofargs $class $args";
}

if ( $tfactlglobal_hash{"debugmask"} &
     $tfactlglobal_mod_levels{"buildCLIJava"} ) {
  tfactlshare_trace(5, "tfactl (PID = $$) " . "buildCLIJava classpath: $classpath",
                    'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) " . "buildCLIJava command: $commandline",
                    'y', 'y');
}
return $commandline;
}
# End buildCLIJava

#
#========= checkTFAMain
# 
# Try to connect to the socket and talk to tfamain ..
# If that fail then we have a problem
#
#==========
sub checkTFAMain
{
  my $tfa_home = shift;
  my $localhost=tolower_host();
  my $message ="$localhost:checkTFAMain";
  dbg(DBG_VERB, "Running Check through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$message);
  my $line;
  my $status_code = 2;
  my @cli_output = tfactlshare_runClient($command,"2>$DEVNULL");
  foreach $line ( @cli_output )
  {
    dbg(DBG_VERB,"We got : $line\n");
    if ( $line eq "CheckOK") {
      dbg(DBG_VERB,"\nTFA is running...\n");
      return SUCCESS;
    }
    elsif ( $line =~ /CommandLine : Failed in reading session id/ ) {
      $status_code = 521;
    }
  }
  my $statusfile = catfile("$tfa_home","internal","runstatus.txt");
  open (IN, '<', $statusfile) or die "Can't open file $statusfile: $!\n";
  read IN, $line, 20;
  if ($line =~ /stop/) {
    $status_code = 518;
  }
  close IN;
  tfactlshare_error_msg($status_code,undef);
  return FAILED;
}

sub isTFARunning
{
  my $tfa_home = shift;
  my $localhost=tolower_host();
  my $status_code = 2;
  my $tfapid;
  my $tfaprocess;
  my $setupfile = tfactlshare_getSetupFilePath($tfa_home);
  #Note: CELL run is not cloud and offline
  if ( $ISCLOUD || isOfflineMode($setupfile) ) {
    return SUCCESS;
  }
  $tfapid = get_tfa_pid($tfa_home);
  if ( $IS_WINDOWS ) {
      $tfaprocess = tfactlwin_check_tfa_main_pid_running($tfapid);
  } else {
      if ( defined($tfapid) && ($tfapid ne '') ) {
         $tfaprocess = `ps -f -p $tfapid | grep -v PID`;
     }
  }
  if (defined $tfaprocess && $tfaprocess ne '') {     
       return SUCCESS;
  }
  
  tfactlshare_error_msg($status_code,undef);
  return FAILED;
}

sub getTFARunMode #COLLECTOR/RECEIVER
{
  my $tfa_home = shift;
  my $mode;
  my $tfa_setup = catfile($tfa_home, "tfa_setup.txt");

  if ( -f $tfa_setup ) {
    $mode = tfactlshare_getConfigValue($tfa_setup, "RUN_MODE");
  }

  if ( not length $mode ) {
    $mode = "collector";
  }

  dbg(DBG_VERB,"\nTFA is running in $mode Mode\n");
  return trim(uc $mode);
}

# Abridged version of checkTFAStatus to be 
# used to print status during installation.
sub checkTFAStatusAbridged
{
  my $tfa_home = shift;
  my $localhost=tolower_host();
  if (isTFARunning($tfa_home) == FAILED) {
    exit 0;
  }
  my $message ="$localhost:checkTFAStatus:noinv";
  dbg(DBG_VERB, "Running Check through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$message);
  my $line;

  my $tb = Text::ASCIITable->new();
  $tb->setCols("Host", "Status of TFA", "PID", "Port", "Version", "Build ID");
  $tb->setOptions({"outputWidth" => $tputcols});
  print "\n";
  my $nodename;
  my @lines = tfactlshare_runClient($command);
  if ($lines[1] eq "Connection refused") {
    $tb->addRow($localhost, "NOT RUNNING", "-", "-", "-", "-");
    print $tb;
    return SUCCESS;
  }
  foreach $line (@lines)
  {
    dbg(DBG_VERB,"We got : $line\n");
    if ( $line =~ /Check/) {
      my ($output, $hostname, $tfapid, $tfaport, $tfaversion, $tfabuildid) = split(/!/, $line);
      if ($output eq "CheckOK") {
        $output = "RUNNING";
	if ( $tfaport =~ /OFFLINE/ ) {
	  $output = "AVAILABLE";
	}
      }
      if ($output eq "CheckFAIL") {
        $output = "NOT RUNNING";
      }
      $tb->addRow($hostname, $output, $tfapid, $tfaport, $tfaversion, $tfabuildid);
    }
  }
  print $tb;
  #dbg(DBG_NOTE,"TFA is not running\n");
  return SUCCESS;
}


#
#========= checkTFAStatus
# 
# Try to connect to the socket and talk to tfamain ..
# If that fail then we have a problem
#
#==========
sub checkTFAStatus
{
  my $tfa_home = shift;
  my $localhost=tolower_host();
  if (isTFARunning($tfa_home) == FAILED) {
    exit 0;
  }
  my $message ="$localhost:checkTFAStatus";
  dbg(DBG_VERB, "Running Check through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$message);
  my $line;

  my $tb = Text::ASCIITable->new();
  $tb->setCols("Host", "Status of TFA", "PID", "Port", "Version", "Build ID", "Inventory Status");
  $tb->setOptions({"outputWidth" => $tputcols});
  print "\n";
  my $nodename;
  my @lines = tfactlshare_runClient($command);
  if ($lines[1] eq "Connection refused") {
    $tb->addRow($localhost, "NOT RUNNING", "-", "-", "-", "-", "-");
    print $tb;
    return SUCCESS;
  }

  foreach $line (@lines)
  {
    dbg(DBG_VERB,"We got : $line\n");
    if ( $line =~ /Check/) {
      my ($output, $hostname, $tfapid, $tfaport, $tfaversion, $tfabuildid, $invrunstatus) = split(/!/, $line);
      if ($output eq "CheckOK") {
	$output = "RUNNING";
      }
      if ($output eq "CheckFAIL") {
	$output = "NOT RUNNING";
      }
      $tb->addRow($hostname, $output, $tfapid, $tfaport, $tfaversion, $tfabuildid, $invrunstatus);
    }
  }
  print $tb;
  #dbg(DBG_NOTE,"TFA is not running\n");
  return SUCCESS;
}

sub isNodePartOfCluster
{
  my ($tfa_home, $nodename) = @_;
  $nodename = trim($nodename);
  my $localhost=tolower_host();
  my $message ="$localhost:printhosts";
  dbg(DBG_VERB, "Running Check through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$message);
  my $line;

  my @lines = tfactlshare_runClient($command);
  foreach $line (@lines)
  {
    dbg(DBG_WHAT,"We got : $line\n");
    $line =~ s/Host Name : //;
    if (trim($line) eq trim($nodename)) {
      return 1;
    }
  }
  return 0;
}

sub isNodeActive
{
  my ($tfa_home, $nodename) = @_;
  my $localhost=tolower_host();
  my $message ="$localhost:checkTFAStatus";
  dbg(DBG_VERB, "Running Check through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$message);
  my $line;

  my @lines = tfactlshare_runClient($command);
  foreach $line (@lines)
  {
    dbg(DBG_VERB,"We got : $line\n");
    if ( $line =~ /Check/) {
      my ($output, $hostname, $tfapid) = split(/!/, $line);
      if (($output eq "CheckOK") && ($hostname eq $nodename)) {
	return 1;
      }
    }
  }
  return 0;
}

########
# NAME
#   tfactlshare_isnodelist_duplicated
#
# DESCRIPTION
#   return TRUE if $node_list has duplicate elements
#          FALSE if $node_list has unique elements
#
# PARAMETERS
#   $node_list
#
# RETURNS
#   TRUE or FALSE 
########
sub tfactlshare_isnodelist_duplicated
{
  my $node_list = shift;
  my @nodes = split(/\,/,$node_list); 
  my %uniquenodes;
  foreach my $nodename ( @nodes ) {
    if ( exists $uniquenodes{trim(lc($nodename))} ) {
      return TRUE;
    }
    $uniquenodes{trim(lc($nodename))} = TRUE;
  }
  return FALSE;
}

sub getActiveListOfNodes 
{
  my @listofnodes;
  my $tfa_home = shift;
  my $localhost=tolower_host();
  my $message ="$localhost:checkTFAStatus";
  dbg(DBG_VERB, "Running Check through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$message);
  my $line;

  my @lines = tfactlshare_runClient($command);
  foreach $line (@lines)
  {
    dbg(DBG_VERB,"We got : $line\n");
    if ( $line =~ /Check/) {
      my ($output, $hostname, $tfapid) = split(/!/, $line);
      if ($output eq "CheckOK") {
       push(@listofnodes, $hostname);
      }
    }
  }
  return @listofnodes;
}

#======================= zipFilesForDate ==================#
sub zipFilesForDate
{
  my ($tfa_home, $startdate, $enddate, $outfile, $clusterwide, $since, $for) = @_;
  dbg(DBG_VERB, "In Run zipFilesForDate for : \n");
  my $localhost=tolower_host();
  my $args = "";
  if (defined $startdate) {
    dbg(DBG_VERB, "start : $startdate\n");
    $args  = "-s $startdate ";
  }
  if (defined $enddate) {
    dbg(DBG_VERB, "end : $enddate\n");
    $args = "$args -e $enddate "
  }
  if (defined $outfile) {
    dbg(DBG_VERB, "zip : $outfile\n");
    $args = "$args -z $outfile "
  }
  if (defined $clusterwide) {
    dbg(DBG_VERB, "clu : $clusterwide\n");
    $args = "$args -c"
  }

  if (defined $since) {
    dbg(DBG_VERB, "since : $since\n");
    $args = "$args -since $since"
  }

  if (defined $for) {
    dbg(DBG_VERB, "for : $for\n");
    $args = "$args -for $for"
  }

  dbg(DBG_VERB, "args $args\n");
  my $actionmessage = "$localhost:ziptracesfordates:$args\n";
  my $endmessage = "$localhost:ActionDone\n";

  dbg(DBG_WHAT, "Running zipFilesForDate through Java CLI\n");
  my $command1 = buildCLIJava($tfa_home,$actionmessage);
  dbg(DBG_VERB, "$command1\n");
  my $command2 = buildCLIJava($tfa_home,$endmessage);
  dbg(DBG_VERB, "$command2\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command1);
  foreach $line ( @cli_output )
  {
    dbg(DBG_VERB, "$line\n");
    if ( $line eq "SUCCESS") {
      dbg(DBG_NOTE,"#### Action Added to TFA Server ####\n");
      return SUCCESS;
    }
  }
  dbg(DBG_NOTE,"Failed to add action to TFA server\n");
  return FAILED;

}

sub tfactlshare_getListOfAllRececivers {
  my $tfa_home = shift;
  my @nodes=();
  my $node;
  my $localhost;
  my $message;
  my $command;
  my $line;
  dbg(DBG_VERB, "Running getListOfAllRececivers through Java CLI\n");
  if (isTFARunning($tfa_home) == FAILED) {
    return @nodes;
  }
  $localhost = tolower_host();
  $message ="$localhost:printreceivers";
  $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "Command $command\n");
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output ) {
    if ( $line eq "DONE") {
      last;
    }
    elsif ( $line =~ /Receiver Name :(.*)/) {
      $node = trim($1);
      push @nodes,$node if $node ne "";
    }
    elsif ( $line =~ /TFA is not yet secured to run all commands/ ) {
      return @nodes;
    }
  }
  return @nodes;

}

# tfactlshare_getConfiguredComputeNodes
# This function will return list of nodes that configured Storge cells
# Returns list of compute nodes

sub tfactlshare_getConfiguredComputeNodes {
  my $tfa_home = shift;
  my @nodes=();
  my $node;
  my $localhost;
  my $message;
  my $command;
  my $line;

  dbg(DBG_VERB, "Running tfactlshare_getConfiguredComputeNodes through Java CLI\n");

  if (isTFARunning($tfa_home) == FAILED) {
    return @nodes;
  }  

  $localhost = tolower_host();
  $message ="$localhost:printconfiguredcomputenodes";
  $command = buildCLIJava($tfa_home,$message);

  dbg(DBG_VERB, "Command $command\n");  
  my @cli_output = tfactlshare_runClient($command);

  foreach $line ( @cli_output ) {
    if ( $line eq "DONE") {
      last;
    }
    elsif ( $line =~ /Compute Node :(.*)/) {
      $node = trim($1);
      push @nodes,$node if $node ne "";
    }
  }
  return @nodes; 
}

sub getListOfAllNodes {
  my $tfa_home = shift;
  my @nodes=();
  my $node;
  my $localhost;
  my $message;
  my $command;
  my $line;
  dbg(DBG_VERB, "Running getListOfAllNodes through Java CLI\n");
  if (isTFARunning($tfa_home) == FAILED) {
    return @nodes;
  }  
  $localhost = tolower_host();
  $message ="$localhost:printhosts";
  $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "Command $command\n");  
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output ) {
    if ( $line eq "DONE") {
      last;
    }
    elsif ( $line =~ /Host Name :(.*)/) {
      $node = trim($1);
      push @nodes,$node if $node ne "";
    }
  }
  return @nodes;
}


sub getListOfOtherNodes {
  my $tfa_home = shift;
  my @nodes=();
  my $node;
  my $localhost;
  my $message;
  my $command;
  my $line;
  dbg(DBG_VERB, "Running getListOfOtherNodes through Java CLI\n");
  if (isTFARunning($tfa_home) == FAILED) {
    return @nodes;
  }
  $localhost = tolower_host();
  $message ="$localhost:printhosts";
  $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "Command $command\n");
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output ) {
    if ( $line eq "DONE") {
      last;
    }
    elsif ( $line =~ /Host Name :(.*)/) {
      $node = trim($1);
      if ( $node ne $localhost ) {
        push @nodes,$node if $node ne "";
      }
    }
  }
  return @nodes;
}


sub preChecks {

	my $TFA_HOME = shift;

	my $WALLET = checkWallet( $TFA_HOME );
	return if ( $WALLET == 0 );

	my $WALLET_PASSWORD = getWalletPasswordFromDB( $TFA_HOME );
	my $CHECK;

	if ( $WALLET_PASSWORD ne "null" ) {
		$CHECK = checkWalletPassword( $TFA_HOME, $WALLET_PASSWORD );
		return if ( $CHECK == 0 );
	}

	my $AGAIN = 1;
	my $COUNT = 1;
	my $CHECK;

	print "\n";

	while ( $AGAIN == 1 && $COUNT <= 3 ) {

		$WALLET_PASSWORD = promptForPassword( "Oracle Wallet", 0 );
		$CHECK = checkWalletPassword( $TFA_HOME, $WALLET_PASSWORD );

		if ( $CHECK != 0 ) {
			print "\nOracle Wallet Password you Entered is incorrect. Please try again.\n";
			$COUNT += 1;
		} else {
			updateWalletPasswordInDB( $TFA_HOME, $WALLET_PASSWORD );
			$GLB_REMOVE_WALLET = 1;
			$AGAIN = 0;
			print "\nOracle Wallet Password will be removed after this Process is completed.\n\n";
		}
	}

	if ( $COUNT > 3 ) {
		print "\nOracle Wallet Password you Entered is incorrect. Please try later.\n";
		exit 1;
	}

}

#======================= runInventoryInCells =================#
sub runInventoryInCells
{
  my $tfa_home = shift;
  my $pid = fork;
  return if $pid;
  my $localhost = tolower_host();

  #Perform Oracle Wallet Pre Checks
  preChecks( $tfa_home );

  my $logdirectory = getLogDirectory( $tfa_home );

  my $logfile = catfile($logdirectory, "inventory_$localhost\_initiator.log");
  open (LOG, ">$logfile") or die "Can't open $logfile: $!\n";

  # Get list of all compute nodes
  my @computenodes = tfactlshare_getConfiguredComputeNodes($tfa_home);
  print LOG localtime(time) . " : Compute nodes : @computenodes\n";

  # Get list of all cells
  my @cells = getOnlineCells( $tfa_home );
  print LOG localtime(time) . " : Online cells : @cells\n";

  my $tfabase = $tfa_home;
  $tfabase =~ s/[\\\/]$localhost[\/\\]tfa_home//;
  print LOG localtime(time) . " : tfabase : $tfabase\n";

  my $len_nodes = scalar(@computenodes);
  print LOG localtime(time) . " : Number of compute nodes : $len_nodes\n";

  for (my $i=0; $i<scalar(@cells); $i++) {
    my $index = $i % $len_nodes;
    print LOG localtime(time) . " : $computenodes[$index] => $cells[$i] \n";
    my $computenode = $computenodes[$index];
    my $cell = $cells[$i];
    print LOG localtime(time) . " : $computenode calling Run Inventory for $cell\n";

    if ($computenode eq $localhost) {
      #my $result = `$tfa_home/bin/tfactl run cellinventory $cell`;
      my $log;
      runCellInventory($tfa_home, $cell, 1, $log, 1);
    }
    else {
      my $TFA_HOME = catfile($tfabase,$computenode,"tfa_home");
      my $remotecommand = catfile($TFA_HOME,"bin","tfactl"). " run cellinventory $cell";
      print LOG localtime(time) . " : $localhost sending $remotecommand to $computenode\n";
      my $tfaexe = catfile($tfa_home,"bin","tfactl");
      my $result = `$tfaexe executecommand $computenode $remotecommand`;
    }
  }
  close LOG;
  exit;
}

#======================= recreateFileEntitiesInBDB ==================#
sub recreateFileEntitiesInBDB
{
  my $tfa_home = shift;
  my $localhost = tolower_host();
  my $actionmessage = "$localhost:recreatefileentitiesinbdb\n";

  print "Running recreateFileEntitiesInBDB through Java CLI\n";
  my $command1 = buildCLIJava($tfa_home,$actionmessage);
  print "$command1\n";
  my @cli_output = tfactlshare_runClient($command1);
  my $line;
  foreach $line ( @cli_output )
  {
    print "$line\n";
    if ($line eq "SUCCESS") {
      return SUCCESS;
    }
  }
  return FAILED;
}

#======================= runCellInventory ==================#
#
#Subroutine for Cell Invetory using Expect and Oracle Wallet
#
sub runCellInventory {

        my ($tfa_home, $CELL, $RUNINVENTORY, $logfile, $runinbackground) = @_;

        my $LOCALHOST = tolower_host();
        my $tfa_base = $tfa_home;

        my $SSH_STATUS = checkSSHSetup ( $CELL );
        # SSH_STATUS will be 0 if SSH Setup Exists.

	#Check Oracle Wallet Password is working or not
	if ( $SSH_STATUS != 0 ) {

		my $CELL_PASSWORD = getPassword( $tfa_home, $CELL );

		my $PWD_STATUS = expectCheckRemotePassword( $tfa_home, $CELL, $CELL_PASSWORD );

		if ( $PWD_STATUS != 0 ) {
			print "Password from Oracle Wallet for $CELL is not working. Please Change it.\n";
			exit;
		}
	}

        if ( $tfa_base =~ /\/$LOCALHOST\/tfa_home/ ) {
                $tfa_base =~ s/\/$LOCALHOST\/tfa_home//;
        }
		
	if ($runinbackground) {
		my $pid = fork;
		return if $pid;
	}

	if ( ! defined $logfile) {
		my $logdirectory = getLogDirectory( $tfa_home );
		$logfile = "$logdirectory/inventory_$CELL.log\n";
	}
		
	open (LOG, ">>$logfile") or die "Can't open $logfile: $!\n";

        my $TFA_HOME = "$tfa_base/$CELL/tfa_home";

	my $CRS_HOME = get_crs_home( $tfa_home );

	# Check if there is already a lock on CELL. If Yes, then add the job to Queue.
	my $LOCK = runCommandOnRemoteWithStatus( $tfa_home, $CELL, "$SSH $CELL ls $TFA_HOME/internal/.$CELL.lock 2> $DEVNULL | wc -l", $CRS_HOME, $SSH_STATUS );
	$LOCK = trim( $LOCK );

	if ( $LOCK == 1 ) {

	   print LOG localtime(time) . " : Found TFA_HOME $TFA_HOME on $CELL...\n";

	   # Check if TFA is running on cell
	   my $tfa_status = runCommandOnRemoteWithStatus( $tfa_home, $CELL, "$SSH $CELL ps -ef | grep -i tfa | grep -v grep | wc -l", $CRS_HOME, $SSH_STATUS );
	   $tfa_status = trim( $tfa_status );

	   print LOG localtime(time) . " : No of TFA process running on $CELL: $tfa_status\n";

	   if ( $tfa_status != 0 ) {
	      print "Adding Command $TFA_HOME/bin/tfactl run inventory to $CELL Queue\n";
	      runCommandOnRemote( $tfa_home, $CELL, "$SSH $CELL \"echo $TFA_HOME/bin/tfactl run inventory >> $TFA_HOME/internal/.$CELL.job\"", $CRS_HOME, $SSH_STATUS );
	      exit 0;
	   } else {
	      # TFA is not running so remove TFA_BASE and continue
	      print LOG localtime(time) . " : Removing old TFA_BASE $tfa_base on $CELL...\n";
	      runCommandOnRemote( $tfa_home, $CELL, "$SSH $CELL $RM -rf $tfa_base", $CRS_HOME, $SSH_STATUS );
	   }
	}

	# Check space on cell before running inventory, exit if its less than 40 MB
	my $space;

	if ( $SSH_STATUS == 0) {
		$space = runCommandOnRemoteWithStatus( $tfa_home, $CELL, "$SSH $CELL df -P / | tail -1 | awk '{ print \$4 }'", $CRS_HOME, $SSH_STATUS );
	} else {
		$space = runCommandOnRemoteWithStatus( $tfa_home, $CELL, "$SSH $CELL df -P / | tail -1 | awk '{ print \\\$4 }'", $CRS_HOME, $SSH_STATUS );
	}
	$space = trim( $space );

	print LOG localtime(time) . " : Available space on $CELL under '/' [ TFA requires minimum 40MB ] : $space MB\n";

	if ( $space <= 40960 ) {
		print "There is not enough space [ 40MB under '/'] on $CELL to run TFA. Please verify and try again.\n";
		print LOG localtime(time) . " : There is not enough space [ 40MB under '/'] on $CELL to run TFA. Please verify and try again.\n";
		exit 0;
	}

	#my $TFA_HOSTS = `$tfa_home/bin/tfactl print hosts | grep "Host Name " | awk '{print \$NF}' | grep -v $LOCALHOST`;
	my @TFA_HOSTS = getListOfOtherNodes( $tfa_home );

        print LOG localtime(time) . " : tfa_home: $tfa_home\n";
        print LOG localtime(time) . " : tfa_base: $tfa_base\n";
        print LOG localtime(time) . " : TFA_HOME: $TFA_HOME\n";

	print LOG localtime(time) . " : Compute Nodes: @TFA_HOSTS\n";

	updateCellInvStartTime( $tfa_home, $CELL );

	my $REMOTE_NODE;
	foreach $REMOTE_NODE ( @TFA_HOSTS ) {
		print LOG localtime(time) . " : Copying .$CELL.inv to $REMOTE_NODE...\n";
		copyTagFile( $tfa_home, "cellinv-$CELL", $REMOTE_NODE);
	}

	print LOG localtime(time) . " : Creating $TFA_HOME/internal in $CELL\n";
        runCommandOnRemote( $tfa_home, $CELL, "$SSH $CELL $MKDIR -p $TFA_HOME/internal", $CRS_HOME, $SSH_STATUS );

	print LOG localtime(time) . " : Creating TFA Lock on $CELL\n";
	runCommandOnRemote( $tfa_home, $CELL, "$SSH $CELL $TOUCH ".catfile($TFA_HOME,"internal",".$CELL.lock"), $CRS_HOME, $SSH_STATUS );

	print LOG localtime(time) . " : Creating TFA Job Queue on $CELL\n";
	runCommandOnRemote( $tfa_home, $CELL, "$SSH $CELL $TOUCH ".catfile($TFA_HOME,"internal",".$CELL.job"), $CRS_HOME, $SSH_STATUS );

        print LOG localtime(time) . " : Creating $TFA_HOME/log in $CELL\n";
        runCommandOnRemote( $tfa_home, $CELL, "$SSH $CELL $MKDIR -p $TFA_HOME/log", $CRS_HOME, $SSH_STATUS );

        print LOG localtime(time) . " : Creating $TFA_HOME/database/BERKELEY_JE_DB in $CELL\n";
        runCommandOnRemote( $tfa_home, $CELL, "$SSH $CELL $MKDIR -p $TFA_HOME/database/BERKELEY_JE_DB", $CRS_HOME, $SSH_STATUS );

        print LOG localtime(time) . " : Creating $TFA_HOME/output/inventory in $CELL\n";
        runCommandOnRemote( $tfa_home, $CELL, "$SSH $CELL $MKDIR -p $TFA_HOME/output/inventory", $CRS_HOME, $SSH_STATUS );

        print LOG localtime(time) . " : Copying $tfa_home/bin from $LOCALHOST to $CELL\n";
        runCommandOnRemote( $tfa_home, $CELL, "$SSH $CELL $MKDIR -p $TFA_HOME/bin", $CRS_HOME, $SSH_STATUS );
        runCommandOnRemote( $tfa_home, $CELL, "$SCP -r $tfa_home/bin/ $CELL:$TFA_HOME/", $CRS_HOME, $SSH_STATUS );

        print LOG localtime(time) . " : Copying $tfa_home/resources from $LOCALHOST to $CELL\n";
        runCommandOnRemote( $tfa_home, $CELL, "$SCP -r $tfa_home/resources/ $CELL:$TFA_HOME/", $CRS_HOME, $SSH_STATUS );

        print LOG localtime(time) . " : Copying $tfa_home/jlib from $LOCALHOST to $CELL\n";
        runCommandOnRemote( $tfa_home, $CELL, "$SCP -r $tfa_home/jlib/ $CELL:$TFA_HOME/", $CRS_HOME, $SSH_STATUS );
        
        print LOG localtime(time) . " : Copying $tfa_home/install from $LOCALHOST to $CELL\n";
        runCommandOnRemote( $tfa_home, $CELL, "$SCP -r $tfa_home/install/ $CELL:$TFA_HOME/", $CRS_HOME, $SSH_STATUS );

        print LOG localtime(time) . " : Copying keystores from $LOCALHOST to $CELL\n";
        runCommandOnRemote( $tfa_home, $CELL, "$SCP $tfa_home/public.jks $CELL:$TFA_HOME/", $CRS_HOME, $SSH_STATUS );
        runCommandOnRemote( $tfa_home, $CELL, "$SCP $tfa_home/tfa.jks $CELL:$TFA_HOME/", $CRS_HOME, $SSH_STATUS );

	print LOG localtime(time) . " : Copying $tfa_home/internal/usableports.txt to $CELL\n";
        runCommandOnRemote( $tfa_home, $CELL, "$SCP $tfa_home/internal/usableports.txt $CELL:$TFA_HOME/internal/", $CRS_HOME, $SSH_STATUS );

	print LOG localtime(time) . " : Copying $tfa_home/internal/.buildid to $CELL\n";
        runCommandOnRemote( $tfa_home, $CELL, "$SCP $tfa_home/internal/.buildid $CELL:$TFA_HOME/internal/", $CRS_HOME, $SSH_STATUS );
       
	print LOG localtime(time) . " : Copying $tfa_home/internal/.buildversion to $CELL\n";
        runCommandOnRemote( $tfa_home, $CELL, "$SCP $tfa_home/internal/.buildversion $CELL:$TFA_HOME/internal/", $CRS_HOME, $SSH_STATUS );
       
        print LOG localtime(time) . " : Copying $tfa_home/internal/config.properties to $CELL\n";	
        runCommandOnRemote( $tfa_home, $CELL, "$SCP $tfa_home/internal/config.properties $CELL:$TFA_HOME/internal/", $CRS_HOME, $SSH_STATUS );

        print LOG localtime(time) . " : Creating $TFA_HOME/tfa_setup.txt and $TFA_HOME/tfa_directories.txt in $CELL\n";
	my $CELLTRACE;
	my $LOG_HOME;

	if ( $SSH_STATUS == 0) {
		$CELLTRACE = runCommandOnRemoteWithStatus( $tfa_home, $CELL, "$SSH $CELL echo \\\$CELLTRACE", $CRS_HOME, $SSH_STATUS );
		$LOG_HOME = runCommandOnRemoteWithStatus( $tfa_home, $CELL, "$SSH $CELL echo \\\$LOG_HOME", $CRS_HOME, $SSH_STATUS );
	} else {
		$CELLTRACE = runCommandOnRemoteWithStatus( $tfa_home, $CELL, "$SSH $CELL echo \\\$CELLTRACE", $CRS_HOME, $SSH_STATUS );
		$LOG_HOME = runCommandOnRemoteWithStatus( $tfa_home, $CELL, "$SSH $CELL echo \\\$LOG_HOME", $CRS_HOME, $SSH_STATUS );
	}

	$CELLTRACE = trim ( $CELLTRACE );
        $LOG_HOME = trim ( $LOG_HOME );

        createTFASetup( $tfa_home, $CELL, $TFA_HOME);
        createTFADirectories( $tfa_home, $CELL, $CELLTRACE, $LOG_HOME );

        runCommandOnRemote( $tfa_home, $CELL, "$SCP $tfa_home/tfa_setup_$CELL.txt $CELL:$TFA_HOME/", $CRS_HOME, $SSH_STATUS );
        runCommandOnRemote( $tfa_home, $CELL, "$SCP $tfa_home/tfa_directories_$CELL.txt $CELL:$TFA_HOME/", $CRS_HOME, $SSH_STATUS );
        qx ( rm -f $tfa_home/tfa_setup_$CELL.txt );
        qx ( rm -f $tfa_home/tfa_directories_$CELL.txt );
        runCommandOnRemote( $tfa_home, $CELL, "$SSH $CELL $MV $TFA_HOME/tfa_setup_$CELL.txt $TFA_HOME/tfa_setup.txt", $CRS_HOME, $SSH_STATUS );
        runCommandOnRemote( $tfa_home, $CELL, "$SSH $CELL $MV $TFA_HOME/tfa_directories_$CELL.txt $TFA_HOME/tfa_directories.txt", $CRS_HOME, $SSH_STATUS );

        print LOG localtime(time) .  " : Running fixTfactl on $CELL\n";
        runCommandOnRemote( $tfa_home,  $CELL, "$SSH $CELL $TFA_HOME/bin/tfactl.pl fixTfactl", $CRS_HOME, $SSH_STATUS );

        #print LOG "Updating JAVA_HOME in $TFA_HOME/tfa_setup.txt in $CELL\n";
        #runCommandOnRemote( $tfa_home,  $CELL, "$SSH $CELL $TFA_HOME/bin/tfactl updateJDKInTFASetup", $CRS_HOME, $SSH_STATUS );
        
	my $inventoryDirectory = getInventoryLocation( $tfa_home, $LOCALHOST );

        if ( -f "$inventoryDirectory/inventory_$CELL.xml" ) {
                print LOG localtime(time) . " : $inventoryDirectory/inventory_$CELL.xml exists...\n";
                print LOG localtime(time) . " : Copying $inventoryDirectory/inventory_$CELL.xml to $CELL\n";
                runCommandOnRemote( $tfa_home, $CELL, "$SCP $inventoryDirectory/inventory_$CELL.xml $CELL:$TFA_HOME/output/inventory/", $CRS_HOME, $SSH_STATUS );
                runCommandOnRemote( $tfa_home, $CELL, "$SSH $CELL cp $TFA_HOME/output/inventory/inventory_$CELL.xml $TFA_HOME/output/inventory/inventory.xml", $CRS_HOME, $SSH_STATUS );
                print LOG localtime(time) . " : Recreating FileEntities in BDB on $CELL\n";
                runCommandOnRemote( $tfa_home, $CELL, "$SSH $CELL $TFA_HOME/bin/tfactl recreateFileEntitiesInBDB", $CRS_HOME, $SSH_STATUS );
        }

        # When user calls tfactl run cellinventory <cell> we will do the following.
        # When runCellInventory() is called as part of diagcollection, we will
        # not run inventory and delete the tfabase in cell.

        print LOG localtime(time) . " : Running inventory in $CELL\n";
        runCommandOnRemote( $tfa_home, $CELL, "$SSH $CELL $TFA_HOME/bin/tfactl run inventory", $CRS_HOME, $SSH_STATUS );
		
        if ( $RUNINVENTORY == 1 ) {

                print LOG localtime(time) . " : Copying $TFA_HOME/output/inventory/inventory.xml to $LOCALHOST\n";
                runCommandOnRemote( $tfa_home, $CELL, "$SSH $CELL cp $TFA_HOME/output/inventory/inventory.xml $TFA_HOME/output/inventory/inventory_$CELL.xml", $CRS_HOME, $SSH_STATUS );
                runCommandOnRemote( $tfa_home, $CELL, "$SCP $CELL:$TFA_HOME/output/inventory/inventory_$CELL.xml $inventoryDirectory", $CRS_HOME, $SSH_STATUS );

		#Process Job Queue and remove TFA_BASE on Cell
		processJobsOnCell( $tfa_home, $CELL, $TFA_HOME, $CRS_HOME, $SSH_STATUS, $logfile );

                foreach $REMOTE_NODE ( @TFA_HOSTS ) {
                        print LOG localtime(time) . " : Copying inventory_$CELL.xml to $REMOTE_NODE...\n";
			copyTagFile($tfa_home, "cellinvxml-$CELL", $REMOTE_NODE);
                }
        }

	updateCellInvEndTime( $tfa_home, $CELL );

	foreach $REMOTE_NODE ( @TFA_HOSTS ) {
		print LOG localtime(time) . " : Copying .$CELL.inv to $REMOTE_NODE...\n";
		copyTagFile($tfa_home, "cellinv-$CELL", $REMOTE_NODE);
	}

        print LOG localtime(time) . " : Inventory completed for $CELL\n";

	close LOG;
		
	if ($runinbackground) {
		exit;
	}
}

sub processJobsOnCell {

	my $tfa_home = shift;
	my $CELL = shift;
	my $TFA_HOME = shift;
	my $CRS_HOME = shift;
	my $SSH_STATUS = shift;
	my $LOGFILE = shift;

	my $LOCALHOST = tolower_host();
	my $TFA_BASE = $tfa_home;

	if ( $TFA_BASE =~ /\/$LOCALHOST\/tfa_home/ ) {
		$TFA_BASE =~ s/\/$LOCALHOST\/tfa_home//;
	}

	open( LOG, ">>$LOGFILE" ) or print "\nUnable to open $LOGFILE\n";

	my $PID = fork();

	return if $PID;

	if ( $PID == 0 ) {
		print LOG localtime(time) . " : Created New Thread to process Job Queue on $CELL\n";
	} else {
		print LOG localtime(time) . " : Fork unable to create a new Thread. Current Thread is processing Job Queue on $CELL\n";
	}

	print LOG localtime(time) . " : Checking Job Queue on $CELL\n";

	my $TEMP = 1;

	while ( $TEMP == 1 ) {
	
		my $QUEUE = runCommandOnRemoteWithStatus( $tfa_home, $CELL, "$SSH $CELL cat $TFA_HOME/internal/.$CELL.job 2>$DEVNULL | wc -l", $CRS_HOME, $SSH_STATUS );
		$QUEUE = trim( $QUEUE );
	
		if ( $QUEUE >= 1 ) {
		print LOG localtime(time) . " : Found $QUEUE Job(s) in Queue on $CELL\n";

		my $JOB = runCommandOnRemoteWithStatus( $tfa_home, $CELL, "$SSH $CELL \"cd $TFA_HOME/internal 2>$DEVNULL; head -1 .$CELL.job 2>$DEVNULL; sed -i 1d .$CELL.job 2>$DEVNULL\"", $CRS_HOME, $SSH_STATUS );
		$JOB = trim ( $JOB );

		if ( $JOB && $JOB =~ /tfactl/ ) {

			#TODO: Add Inv or Diagcollect start and end time.

			print LOG localtime(time) . " : Running $JOB on $CELL\n";
			runCommandOnRemote( $tfa_home, $CELL, "$SSH $CELL $JOB", $CRS_HOME, $SSH_STATUS );

			my $SOURCE;
			my $DESTINATION;
	
			#For Diagcollect, get the copy of zip to compute node
			if ( $JOB =~ /diagcollect/ ) {
				my @DIAGOPTIONS = split(/\s\-/, $JOB);
				my $TAG;
				my $ZIP;
				my $COPYTONODE;
				my $LOGID;
				my $CURRENT;
	
				for( my $i = 0; $i < scalar( @DIAGOPTIONS ); $i++ ) {
	
					$CURRENT = $DIAGOPTIONS[$i];
					$CURRENT = trim($CURRENT);
					if ( $CURRENT =~ /^(\s*)$/ ) {
						next;
					}
	
					if ( $CURRENT =~ /^z / ) {
						$ZIP = $CURRENT;
						$ZIP =~ s/z //;
					}
	
					if ( $CURRENT =~ /tag / ) {
						$TAG = $CURRENT;
						$TAG =~ s/tag //;
					}
	
					if ( $CURRENT =~ /copytocomputenode / ) {
						$COPYTONODE = $CURRENT;
						$COPYTONODE =~ s/copytocomputenode //;
					}
	
					if ( $CURRENT =~ /logid / ) {
						$LOGID = $CURRENT;
						$LOGID =~ s/logid //;
					}
				}

				$TAG = trim( $TAG );
				$ZIP = trim( $ZIP );
				$LOGID = trim ( $LOGID );
				$COPYTONODE = trim ( $COPYTONODE );

				my $repository = tfactlshare_get_repository_location( $tfa_home, $LOCALHOST );
	
				$SOURCE = "$TFA_BASE/repository/$TAG/*";
				$DESTINATION = "$repository/$TAG/";

				if ( ! -d "$DESTINATION" ) {
					print LOG localtime(time) . " : Creating Directory $DESTINATION on $LOCALHOST\n";
					qx ( $MKDIR -p $DESTINATION );
				}

				print LOG localtime(time) . " : Copying $CELL:$SOURCE to $LOCALHOST:$DESTINATION\n";
	
				runCommandOnRemote( $tfa_home, $CELL, "$SCP root\@$CELL:$SOURCE $DESTINATION", $CRS_HOME, $SSH_STATUS );

				print LOG localtime(time) . " : COPYTOCOMPUTENODE: $COPYTONODE\t LOCALHOST: $LOCALHOST\n";

				if ( $COPYTONODE && $COPYTONODE ne $LOCALHOST) {
					#Copy the Zip File
					print LOG localtime(time) . " : Copying $CELL.$ZIP.zip to $COPYTONODE...\n";
					copyTagFile( $tfa_home, "repofile-TAG-$TAG-FILE-$CELL.$ZIP.zip", $COPYTONODE);

					#Copy Metadata File
					print LOG localtime(time) . " : Copying $CELL.$ZIP.zip.txt to $COPYTONODE...\n";
					copyTagFile( $tfa_home, "repofile-TAG-$TAG-FILE-$CELL.$ZIP.zip.txt", $COPYTONODE );

					#Copy Log File
					print LOG localtime(time) . " : Copying diagcollect_$LOGID\_$CELL.log to $COPYTONODE:$COPYTONODE\n";
					copyTagFile( $tfa_home, "repofile-TAG-$TAG-FILE-diagcollect_$LOGID\_$CELL.log", $COPYTONODE );
				}
			}

			#By default, get the copy of Inventory XML. Inventory will be run as a part of Diagcollect.
			print LOG localtime(time) . " : Copying $CELL:$TFA_HOME/output/inventory/inventory.xml to $LOCALHOST\n";
			runCommandOnRemote( $tfa_home, $CELL, "$SSH $CELL cp $TFA_HOME/output/inventory/inventory.xml $TFA_HOME/output/inventory/inventory_$CELL.xml", $CRS_HOME, $SSH_STATUS );

			my $inventoryDirectory = getInventoryLocation( $tfa_home, $LOCALHOST );
			runCommandOnRemote( $tfa_home, $CELL, "$SCP $CELL:$TFA_HOME/output/inventory/inventory_$CELL.xml $inventoryDirectory", $CRS_HOME, $SSH_STATUS );

			# Sync Inventory XML with Other Compute Nodes.
			my @TFA_HOSTS = getListOfOtherNodes( $tfa_home ); 

			my $REMOTE_NODE;
			foreach $REMOTE_NODE ( @TFA_HOSTS ) {
				copyTagFile( $tfa_home, "cellinvxml-$CELL", $REMOTE_NODE );
			}
		}
		} else {
			$TEMP = 0;
		}
	}
	
	print LOG localtime(time) . " : Deleting $TFA_BASE in $CELL...\n";
	runCommandOnRemote( $tfa_home, $CELL, "$SSH $CELL $RM -rf $TFA_BASE", $CRS_HOME, $SSH_STATUS );

	#Remove wallet Password if set
	if ( $GLB_REMOVE_WALLET == 1 ) {
		removeWalletPasswordFromDB( $tfa_home );
		$GLB_REMOVE_WALLET = 0;
	}

	close LOG;
	
	exit 0;
}
		
sub updateCellInvStartTime {

	my $TFA_HOME = shift;
	my $CELL = shift;

	my $INVFILE = "$TFA_HOME/internal/.$CELL.inv";
	#my $START = qx( date '+%b %d %H:%M:%S' );
	my $START = time;
	$START = trim ( $START );

	if ( ! -e "$INVFILE" ) {

		open( INV, ">$INVFILE" );
		print INV "$CELL|$START|0\n";
		close ( INV );

	} else {

		my $TEMP = "$TFA_HOME/internal/.$CELL.tmp";
		my $FOUND = 0;
		my $LINE;

		open ( TEMP, ">$TEMP" );
		open ( INV, "<$INVFILE" );

		while ( <INV> ) {

			$LINE = trim( $_ );

			if ( $LINE =~ /$CELL/ ) {
				$FOUND = 1;
				my @LIST = split( /\|/, $LINE );
				print TEMP "$CELL|$START|$LIST[2]\n";
			}
		}

		if ( $FOUND == 0 ) {
			print TEMP "$CELL|$START|\n";
		}

		close ( INV );
		close ( TEMP );

		unlink( $INVFILE );
		rename ( $TEMP, $INVFILE );
	}
}

sub updateCellInvEndTime {

        my $TFA_HOME = shift;
        my $CELL = shift;

	my $INVFILE = "$TFA_HOME/internal/.$CELL.inv";
	my $TEMP = "$TFA_HOME/internal/.$CELL.tmp";

	#my $END = qx( date '+%b %d %H:%M:%S' );
	my $END = time;
	$END = trim ( $END );

	my $LINE;
	my $FOUND = 0;

	open ( TEMP, ">$TEMP" );
	open ( INV, "<$INVFILE" );

	while ( <INV> ) {
		$LINE = trim( $_ );

		if ( $LINE =~ /$CELL/ ) {
			$FOUND = 1;
			my @LIST = split( /\|/, $LINE );
			print TEMP "$CELL|$LIST[1]|$END\n";
		}
	}

	if ( $FOUND == 0 ) {
		print "\nUnable to update Inventory End Time as we didn't find Start Time for $CELL\n";
	}

        close ( INV );
        close ( TEMP );

        unlink( $INVFILE );
        rename ( $TEMP, $INVFILE );
}

sub getCellInvStartTime {

	my $TFA_HOME = shift;
        my $CELL = shift;

	my $INVFILE = "$TFA_HOME/internal/.$CELL.inv";

	my $START;
	my $LINE;
	my $FOUND = 0;

	open ( INV, "<$INVFILE" );

	while ( <INV> ) {

		$LINE = trim( $_ );

		if ( $LINE =~ /$CELL/ ) {
			$FOUND = 1;
			my @LIST = split( /\|/, $LINE );
			$START = $LIST[1];
		}
	}
	close ( INV );

	if ( $FOUND == 0 ) {
		#print "\nUnable to get Inventory Start Time for $CELL\n";
	}

	return $START;
}

sub getCellInvEndTime {

        my $TFA_HOME = shift;
        my $CELL = shift;

        my $INVFILE = "$TFA_HOME/internal/.$CELL.inv";

        my $END;
        my $LINE;
        my $FOUND = 0;

        open ( INV, "<$INVFILE" );

        while ( <INV> ) {

                $LINE = trim( $_ );

                if ( $LINE =~ /$CELL/ ) {
                        $FOUND = 1;
                        my @LIST = split( /\|/, $LINE );
                        $END = $LIST[2];
                }
        }
        close ( INV );

        if ( $FOUND == 0 ) {
                #print "\nUnable to get Inventory End Time for $CELL\n";
        }

        return $END;
}


sub getFileModTime {

	use POSIX;

	my $FILE = shift;
	my $FORMAT = shift;

	if ( ! defined ( $FORMAT ) ) {
		$FORMAT = "%a %b %e %H:%M:%S %Y";
	}

	my $MODTIME = strftime $FORMAT, localtime( (stat( $FILE ))[9] );

	return $MODTIME;
}


sub updateJDKInTFASetup
{
  my $tfa_home = shift;
  use Cwd 'abs_path';
  my $file = `which java`;
  chomp($file);
  my $jdkpath = abs_path("$file");
  chomp($jdkpath);
  $jdkpath =~ s/\/bin\/java//;
  print "JAVA_HOME : $jdkpath\n";
  my $outfile = catfile($tfa_home, "tfa_setup.txt");
  open (OUT, ">>$outfile") or die "Can't open file $outfile: $!\n";
  print OUT "JAVA_HOME=$jdkpath\n";
  close OUT;
}

sub createTFASetup
{
  my ($tfa_home, $cell, $TFA_HOME) = @_;
  my $outfile = catfile($tfa_home, "tfa_setup_$cell.txt");
  open (OUT, ">$outfile") or die "Can't open file $outfile: $!\n";
  print OUT "TRACE_LEVEL=1\n";
  print OUT "SUPPORT_MODE=TRUE\n";
  print OUT "TFA_HOME=$TFA_HOME\n";
  #my $val = `rpm -qi jdk | grep Version | awk '{print \$3}'`;
  my $java_home = "/usr/java/default";
  print OUT "JAVA_HOME=$java_home\n";
  print OUT "NODE_TYPE=CELL\n";
  close OUT;
}

sub createTFADirectories
{
my ($tfa_home, $cell, $celltrace, $loghome ) = @_;
    my $dirsfile = catfile($tfa_home, "tfa_directories_$cell.txt");
  open (OUT, ">$dirsfile") or die "Can't open file $dirsfile: $!\n";
  print OUT "localnode%12345%OS%DIAGDEST=/var/log\n";
  print OUT "localnode%12345%OS%DIAGDEST=/var/log/sa\n";
  print OUT "localnode%12345%OS%DIAGDEST=/var/log/cellos\n";
  print OUT "localnode%12345%OS%DIAGDEST=/var/spool/compaq\n";
  print OUT "localnode%12345%OS%DIAGDEST=/opt/oracle.oswatcher/osw/archive\n";
  print OUT "localnode%12345%OS%DIAGDEST=/opt/oracle.ExaWatcher/archive\n";
  print OUT "localnode%12345%OS%DIAGDEST=/var/log/cellos/sosreports\n";
  print OUT "localnode%12345%CELL%DIAGDEST=$celltrace\n";
  print OUT "localnode%12345%CELL%DIAGDEST=$loghome\n";
  close OUT;
}


#======================= runTFAInventory ==================#
sub runTFAInventory
{
  my ($tfa_home, $clusterwide, $silent) = @_;
  my $args = "-c";
  if (isTFARunning($tfa_home) == FAILED) {
	exit 0;
  }
  dbg(DBG_VERB, "In Run TFAInventory for All Directories\n");
  my $localhost=tolower_host();

  #if (defined $clusterwide) {
  #  dbg(DBG_VERB, "clu : $clusterwide\n");
  #  $args = "-c"
  #}

  my $actionmessage = "$localhost:runinventory:$args\n";
  my $endmessage = "$localhost:ActionDone\n";

  dbg(DBG_VERB, "Running runTFAInventory through Java CLI\n");
  my $command1 = buildCLIJava($tfa_home,$actionmessage);
  dbg(DBG_VERB, "$command1\n");
  my $command2 = buildCLIJava($tfa_home,$endmessage);
  dbg(DBG_VERB, "$command2\n");

  if ( -e "$BASH" ) {
    if ($PROFILING_ON==1) {
      dbg(DBG_VERB, "calling profiling script : $tfa_home/bin/profiling.sh \n");
      my $pid = $$;
      dbg(DBG_VERB, "pid : $pid \n");
      system("$BASH $tfa_home/bin/profiling.sh $pid $tfa_home/output/inventory/inventory_cpu_usage.txt > $DEVNULL 2>&1 &");
    }
  }
  my @cli_output = tfactlshare_runClient($command1);
  my $line;
  foreach $line ( @cli_output )
  {
    dbg(DBG_VERB, "$line\n");
    if ( $line eq "SUCCESS") {
      if (! $silent) {
        my $tfactl = getTfactlPath($tfa_home);
        print "Run Inventory process started...\n";
        #print "1. To check the inventory statistics, run the following command:\n";
        #print " $tfactl print log\n";
        print "To check the status of inventory process, run the following command:\n";
        print " $tfactl print actions\n";
      }
      dbg(DBG_VERB,"#### Action added to TFA Server ####\n");
      return SUCCESS;
    }
  }
  dbg(DBG_NOTE,"Could not add action to TFA server\n");
  return FAILED;

}
#======================= requestZipTransfers ==================#
sub requestZipTransfers
{
  my $filename = shift;
  dbg(DBG_VERB, "In requestZipTransfers\n");
  my $localhost=tolower_host();
  my $remote = sockConnect();
  dbg(DBG_VERB, "Connected to ", $remote->peerhost, " on port: ", $remote->peerport, "\n");

  my $returnmessage;
  my $actionmessage = "$localhost:requestzipstransfer:$filename\n";
  my $endmessage = "$localhost:ActionDone\n";
  $remote->send($actionmessage);
  $remote->send($endmessage);
  $remote->recv($returnmessage,1024);
  if ($returnmessage eq "SUCCESS\n") {
    dbg(DBG_WHAT, "Action added to TFA server\n");}
  else {
    dbg(DBG_WHAT, "Failed to Add Action to TFA server\n");}
  $remote->close();
}

sub printCookie
{
  my $tfa_home = shift;
  my $localhost = tolower_host();
  my $message ="$localhost:printcookie";
  my $command = buildCLIJava($tfa_home,$message);

  my $sudo_user = $ENV{SUDO_USER};
  my $sudo_command = $ENV{SUDO_COMMAND};

  if ( $sudo_user && $sudo_command =~ /tfactl/ ) {
	print "User $sudo_user does not have permissions to print cookie. Please run the command as root\n";
	return FAILED;
  }

  dbg(DBG_VERB, "$command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
    if ($line eq "DONE") {
	return SUCCESS;
    }
    else {
  	print "$line\n";
    }
  }
  return FAILED;
}

sub printTfaHome
{
  my $tfa_home = shift;
  my $localhost = tolower_host();
  my $message ="$localhost:printtfahome";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "$command\n");
  print("$command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
    if ($line eq "DONE") {
       return SUCCESS;
    }
    else {
     print "$line\n";
    }
  }
  return FAILED;
}

sub printWalletPassword
{
  my $tfa_home = shift;
  my $localhost = tolower_host();
  my $message ="$localhost:printwalletpassword";
  my $command = buildCLIJava($tfa_home,$message);

  my $sudo_user = $ENV{SUDO_USER};
  my $sudo_command = $ENV{SUDO_COMMAND};

  if ( $sudo_user && $sudo_command =~ /tfactl/ ) {
        print "User $sudo_user does not have permissions to print Oracle Wallet Password. Please run the command as root\n";
        return FAILED;
  }

  dbg(DBG_VERB, "$command\n");
  my @cli_output = tfactlshare_runClient($command);
  my $line;
  foreach $line ( @cli_output )
  {
    if ($line eq "DONE") {
        return SUCCESS;
    }
    else {
        print "$line\n";
    }
  }
  return FAILED;
}

################## Print Build Version ###################
sub printBuildVersion
{
  my $tfa_home = shift;
  my $localhost = tolower_host();
  my $message ="$localhost:printbuildversion";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "$command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
    if ($line eq "DONE") {
        return SUCCESS;
    }
    else {
        print "$line\n";
    }
  }
  return FAILED;
}

############### Get Ongoing Collections ##############

sub getOngoingCollections
{
	my $tfa_home = shift;
	my $localhost = tolower_host();
	my $message ="$localhost:printOngoingCollections";
	my $command = buildCLIJava($tfa_home,$message);
	dbg(DBG_VERB, "$command\n");
	my $line;
	my @collections;
	my $status = 1;
	my @cli_output = tfactlshare_runClient($command);
	foreach $line ( @cli_output )
	{
		if ($line eq "DONE") {
			return ($status, @collections);
		}
		else {
			if ( $line =~ /Connection refused/) {
				# Dont do anything
			}
			elsif ( $line =~ /!/ ) {
				my @list = split( /!/, $line );
				my $cname = $list[0];
				my $chost = $list[1];
				my $cstatus = $list[2];
				my @comments = split( /\s-/, $list[3]);
				my $czip;
				my $ctag;
		
				for( my $i = 0; $i < scalar(@comments); $i++) {
					if ( $comments[$i] =~ /^z/ ) {
						$czip = (split(/\s/, $comments[$i]))[1];
					}
					elsif ( $comments[$i] =~ /^tag/ ) {
						$ctag = (split(/\s/, $comments[$i]))[1];
					}
				}
		
				push ( @collections, join("!", $cname, $chost, $cstatus, $ctag, $czip));
				$status = 0;
			}
		}
	}
	return ERROR;
}

######## To check the pattern is present in Array #############

sub isPresentInArray
{
	my $pattern = shift;
	my @source = @{$_[0]};
	my $isPresent = 0;

	foreach ( @source ) {
        	if( "$_" eq "$pattern" ) {
            		$isPresent = 1;
	        	last;
        	}
	}

	return $isPresent;
}

sub printConfig 
{
  my $tfa_home = shift;
  my $metadata = shift;
  my $localhost=tolower_host();

  if (isTFARunning($tfa_home) == FAILED) {
	exit 0;
  }
  my @nodelist;
  my $nodename;
  my %kv = ();
  my @temp = ();
  foreach my $row ( split (/~/,$metadata) ) {
    @temp = split("=",$row);
    $kv{$temp[0]} = $temp[1];
  }
  if ( defined $kv{"node"} ) {
    if ( $kv{"node"} eq "local" || $kv{"node"} eq "") {
      @nodelist[0]=$localhost;
    }
    elsif( $kv{"node"} eq "all" ) {
      @nodelist = getListOfAllNodes( $tfa_home );
    }
    else{
      # checking validity of nodes
      $kv{"node"} =~ tr/A-Z/a-z/;
      @nodelist = split(/\,/,$kv{"node"});
      foreach $nodename (@nodelist) {
        if (isNodePartOfCluster($tfa_home, $nodename)) {
        }
        else {
          print "Node $nodename is not part of TFA cluster\n";
          exit 0;
        }
      }
    }
  }
  
  dbg(DBG_WHAT, "Running printConfig through Java CLI\n");
  my $message ="$localhost:printconfig:$metadata";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "$command\n");
  my $line;
  dbg(DBG_WHAT,"#### Printing All Requested Lines ####\n");
  
  my %TABLES;
  my $nodeName;
  my @DIRS;
  foreach (@nodelist) {
        $nodeName = $_;
 	my $tb = Text::ASCIITable->new();
 	$tb->setCols("Configuration Parameter", "Value");
  	$tb->alignCol("Value","left");
  	$tb->setColWidth("Value", $tputcols-30);
	$tb->setOptions({"outputWidth" => $tputcols, "headingText" => $nodeName});
        $TABLES{$nodeName} = $tb;
  }

  $Text::Wrap::columns = $tputcols-45;

  my $table;
  my %configMap = ();
  $configMap{"tfaversion"} = "TFA Version";
  $configMap{"javaVersion"} = "Java Version";
  $configMap{"firezipsinrt"} = "Automatic Diagnostic Collection";
  $configMap{"rtscan"} = "Alert Log Scan";
  $configMap{"publicIp"} = "Public IP Network";
  $configMap{"diskUsageMon"} = "Disk Usage Monitor";
  $configMap{"manageLogsAutoPurge"} = "Managelogs Auto Purge";
  $configMap{"trimmingon"} = "Trimming of files during diagcollection"; 
  $configMap{"currentsizemegabytes"} = "Repository current size (MB)";
  $configMap{"maxsizemegabytes"} = "Repository maximum size (MB)";
  $configMap{"inventorytracelevel"} = "Inventory Trace level";
  $configMap{"collectiontracelevel"} = "Collection Trace level";
  $configMap{"scantracelevel"} = "Scan Trace level";
  $configMap{"othertracelevel"} = "Other Trace level";
  $configMap{"maxlogSize"} = "Max Size of TFA Log (MB)";
  $configMap{"maxlogcount"} = "Max Number of TFA Logs";
  $configMap{"maxcorefilesize"} = "Max Size of Core File (MB)";
  $configMap{"maxcorecollectionsize"} = "Max Collection Size of Core Files (MB)";
  $configMap{"minSpaceForRTScan"} ="Minimum Free Space to enable Alert Log Scan (MB)";
  $configMap{"diskUsageMonInterval"} ="Time interval between consecutive Disk Usage Snapshot(minutes)";
  $configMap{"manageLogsAutoPurgeInterval"} ="Time interval between consecutive Managelogs Auto Purge(minutes)";
  $configMap{"manageLogsAutoPurgePolicyAge"} ="Logs older than the time period will be auto purged(days[d]|hours[h])";
  $configMap{"autopurge"} = "Automatic Purging";
  $configMap{"minfileagetopurge"} = "Age of Purging Collections (Hours)";
  #$configMap{"language"} = "Language";
  #$configMap{"encoding"} = "Encoding";
  #$configMap{"country"} = "Country";
  #$configMap{"AlertLogLevel"} = "AlertLogLevel";
  #$configMap{"UserLogLevel"} = "UserLogLevel";
  #$configMap{"BaseLogPath"} = "BaseLogPath";
  $configMap{"tfaIpsPoolSize"} = "TFA IPS Pool Size";
  $configMap{"tfaDbUtlPurgeMode"} = "TFA ISA Purge Mode";
  $configMap{"tfaDbUtlPurgeAge"} = "TFA ISA Purge Age (seconds)";
  

  # ATP Config parameters
  $configMap{"logstash.host"} ="Logstash hostname";
  $configMap{"logstash.port"} ="Logstash port";
  $configMap{"tfaweb.url"} ="tfaweb url";
  $configMap{"tfaweb.env"} ="tfaweb env"; # demo or oci
  $configMap{"oss.type"} ="Object Store Type"; # casper or oss
  $configMap{"oss.url"} ="Object Store URL";
  $configMap{"oss.user"} ="Object Store User";
  $configMap{"oss.password"} ="Object Store Password";
  $configMap{"oss.proxy"} ="Object Store Proxy";
  $configMap{"wallet.location"} ="Wallet Location";

  #Receiver params
  $configMap{"r.repository"} = "Receiver repository";
  $configMap{"r.port"} = "Receiver port";
  $configMap{"r.send.collections"} = "Send collectionns to receiver";
  $configMap{"r.send.data.realtime"} = "Send data to receiver real time";
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output ) {
    if ( $line eq "DONE") {
       my $key_entry;
       my $value;
       while (($key_entry, $value) = each(%TABLES)) {
             print $TABLES{$key_entry}."\n";
        }
      dbg(DBG_WHAT,"#### All Lines Printed ####\n");
      #print $table;
      return SUCCESS;
    }
    elsif ($line =~ /Config Parameter not supported with -name flag/) {
	tfactlshare_error_msg(520,undef);
	exit 1;
    }
    else {
      if ($line =~ /Connection refused/) {
    	my ($msg, $hostname) = split(/!/, $line);
        delete $TABLES{$hostname};
      }
      else {
	my @configflags = split(/!/, $line);
	my $key;
	my $value;
        foreach my $row ( @configflags ) {
	  @temp = split("=",$row);
	  $key = $temp[0];
	  $value = $temp[1];
	  if ( $key eq "host" ) {
	    $table = $TABLES{$value};
    	  }
	  else {
	    $table->addRow($configMap{$key},$value) if ( $configMap{$key} );
	  } 
        }
      }
    }
  }#End of for
  dbg(DBG_NOTE,"Could not print config details\n");
  return FAILED;
}

sub printInternalConfig{
  my $tfa_home = shift;
  my $localhost=tolower_host();
  if (isTFARunning($tfa_home) == FAILED) {
        exit 0;
  }
  dbg(DBG_WHAT, "Running printConfig through Java CLI\n");
  my $message ="$localhost:printinternalconfig";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "$command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command); 
  dbg(DBG_WHAT,"#### Printing All Requested Lines ####\n");
  foreach $line ( @cli_output )
  {
    if ( $line eq "DONE") {
       dbg(DBG_WHAT,"#### All Lines Printed ####\n");
       return SUCCESS;
    } else {
      print "$line\n";
    }
  }
  dbg(DBG_NOTE,"Could not print config details\n");
  return FAILED;
}

sub printCmd
{
  my $tfa_home = shift;
  my $printcmd = shift;

  my $localhost=tolower_host();

  dbg(DBG_WHAT, "Running $printcmd through Java CLI\n");
  my $message ="$localhost:$printcmd";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "$command\n");
  my $line;
  dbg(DBG_WHAT,"#### Printing All Requested Lines ####\n");
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
    #print "$line\n";
    if ( $line eq "DONE") {
      dbg(DBG_WHAT,"#### All Lines Printed ####\n");
      return SUCCESS;
    } else {
      print "$line\n";
    }
  }
  dbg(DBG_NOTE,"Could not print $printcmd\n");
  return FAILED;
}

#======================= tfactlshare_getdebugips  ===========================#

sub tfactlshare_getdebugips
{
  my $tfa_home = shift;
  my $debugips = tfactlshare_getConfigValue(catfile($tfa_home, "internal", "config.properties"), "debugips");
  if ( (not length $debugips) || lc($debugips) eq "false" ) {
    return FALSE;
  } else {
    return TRUE;
  }
}

#======================= tfactlshare_getTfaIpsPoolSize  ===========================#

sub tfactlshare_getTfaIpsPoolSize
{
  my $tfa_home = shift;
  my $poolsize = tfactlshare_getConfigValue(catfile($tfa_home, "internal", "config.properties"), "tfaIpsPoolSize");
  if ( (not length $poolsize) || $poolsize !~ /[0-9]+/ ) {
    return $TFAIPS_POOLSIZE;
  } else {
    return $poolsize; 
  }
}

#======================= setFlag ===========================#

sub setFlag
{
  my $tfa_home = shift;
  my $flag = shift;
  my $cluster_wide = shift;
  my $during_install = shift;
  my $set_cmd_args = shift;
  my $localhost=tolower_host();
  my $key;

  if (isTFARunning($tfa_home) == FAILED) {
	exit 0;
  }
  
  if ($flag !~ /cookie=/) {
  	dbg(DBG_WHAT, "Running setconfig:$flag through Java CLI\n");
  }

  my @res = split(/=/,$flag);
  if (scalar(@res)==2) {
	my $val = @res[1];
	$key = @res[0];
        if ($key eq "cookie" && $during_install != 1) {
	  my $sudo_user = $ENV{SUDO_USER};
	  my $sudo_command = $ENV{SUDO_COMMAND};

	  if ( $sudo_user && $sudo_command =~ /tfactl/ ) {
		print "User $sudo_user does not have permissions to set the cookie. Please run the command as root\n";
	        return FAILED;
	  }
        }	
	if (!$tfactlglobal_set_commands{$key} ) {
          print "Invalid option specified: $key\n";
          return FAILED;
        }

	if ($key eq "tracelevel") {
           my @trace = split(/:/,$val);
           my $tracefac;
           my $traceval;
           if (scalar(@trace)==2) {
             $tracefac=@trace[0];
             $traceval=@trace[1];
             dbg(DBG_WHAT,"Trace setting : Facility : $tracefac "." Level : $traceval");
           } else {
	     print "Invalid option specified: $flag\n";
	     return FAILED;
           }

	   if ( $tracefac ne "COLLECT" && $tracefac ne "SCAN" && $tracefac ne "INVENTORY" && $tracefac ne "OTHER" ) {
		print "Invalid option specified for tracelevel: $tracefac\n";
		return FAILED;
	   }
        
	   if (!($traceval == 1 || $traceval == 2 || $traceval == 3 || $traceval == 4)) {
	    print "Invalid option specified for @res[0]: @res[1]\n";
	    return FAILED;
	   }	
	   $traceval = int($traceval);
           $flag = "$key=$tracefac:$traceval";
        }
    if ($key eq "diskUsageMonInterval") {
    		$val = trim($val);
    		if($val =~ /^(\d+)$/){
                  if ( $val > MAX_DSKUSG_MON_INT ){
                      print "Invalid value specified: $val \n".
                      "diskUsageMonInterval value should not be grater than ".MAX_DSKUSG_MON_INT."\n";
                      return FAILED;
                  }
                  $flag = $key."=".$val;		
    		}else{
    			print "Invalid option specified for diskUsageMonInterval: $val\n";
				return FAILED;
    		}
        }
    if ($key eq "manageLogsAutoPurgeInterval") {
    		$val = trim($val);
    		if($val =~ /^(\d+)$/) {
                  if ( $val > MAX_DSKUSG_MON_INT ) {
                      print "Invalid value specified :$val \n".
                      "manageLogsAutoPurgeInterval value should not be greater than ".MAX_DSKUSG_MON_INT."\n";
                      return FAILED;
                  }
                  $flag = $key."=".$val;
    		}else{
    			print "Invalid option specified for manageLogsAutoPurgeInterval: $val\n";
				return FAILED;
    		}
    }
    if ($key eq "manageLogsAutoPurgePolicyAge") {
              if($val =~ /^(\d+)h{1}$/){
                  if ( $1 > MAX_HOURS ) {
                    print "Invalid value specified : $val\n".
                    "manageLogsAutoPurgePolicyAge value in hours should not be greater than ". MAX_HOURS."\n";
                    return FAILED;
                  }
                  $flag = $key."=".$val;
              } elsif ( $val =~ /^(\d+)d{1}$/ ) {
                  if ( $1 > MAX_DAYS ) {
                      print "Invalid value specified : $val\n".
                      "manageLogsAutoPurgePolicyAge value in hours days should not be greater than ".MAX_DAYS."\n";
                      return FAILED;
                  }
                  $flag = $key."=".$val;
              } else{
                  print "Invalid option specified for manageLogsAutoPurgePolicyAge: $val\n";
                  return FAILED;
              }
    }
    if ($key eq "blackout.timeout") {
		$val = trim($val);
		if ($val =~ /^\d+./){
			$flag = $key."=".$val;
		} 
		else {
			print "Invalid option specified for $key: $val\n";
			return FAILED;
		}
	}
	if ($key eq "trimsize") {
          $val = int($val);
          $flag = $key."=".$val;
        }
	if ($key eq "collectionPeriod") {
          $val = int($val);
          $flag = $key."=".$val;
        }
 	if ($key eq "inventoryThreadPoolSize") {
          $val = int($val);
          if($val <= 0){
	    print "InventoryThreadPoolSize should be greater than zero.\n";
            return FAILED;
          }
          $flag = $key."=".$val;
        }
        if ($key eq "fileCountInventorySwitch") {
          $val = int($val);
          $flag = $key."=".$val;
        }
        if ($key eq "bugsftpurl") {
          $flag = $key."=".$val;
        }
	
        if ( !($key eq "tracelevel" || $key eq "minSpaceForRTScan" || 
	       $key eq "diskUsageMonInterval" || $key eq "manageLogsAutoPurgeInterval" || 
	       $key eq "manageLogsAutoPurgePolicyAge" || $key eq "minagetopurge" || 
	       $key eq "trimsize" || $key eq "collectionPeriod" || 
	       $key eq "fileCountInventorySwitch" || $key eq "inventoryThreadPoolSize" || 
	       $key eq "minTimeForAutoDiagCollection" || $key eq "cookie" || 
	       $key eq "buildversion" || $key eq "walletpassword" || 
	       $key eq "r.repository" || $key eq "r.port" || $key eq "r.send.collections" || 
  	       $key eq "notificationAddress" || $key eq "tfaIpsPoolSize" || $key eq "bugsftpurl" ||
               $key eq "tfaDbUtlPurgeMode" || $key eq "tfaDbUtlPurgeAge" ||
	       $key eq "ciphersuite" || $key eq "blackout.timeout" || $key =~ /logstash\./ ||
               $key =~ /oss\./ || $key =~ /tfaweb\./ || $key eq "redact" || $key eq "wallet.location" )
	       && !(uc($val) eq "ON" || uc($val) eq "OFF") ) {
	  print "Invalid option specified for @res[0]: @res[1]\n";
	  return FAILED;
        }

        # Replace special characters with tags 
        if ($key =~ /logstash\./ || $key =~ /tfaweb\./ || $key =~ /oss\./ ) {
          $val = tfactlshare_spl_chr2tag($val);
	  if ($key eq "oss.password" && uc($val) eq "NULL") {
	    storeOSSEnvInTFA($tfa_home);
	  }
          $flag = $key."=".$val;
        }

	if ( $key eq "r.repository" || $key eq "r.port" ) {
	  #Settable from R node only. If -c flag provided set clusterwide
	  if ( getTFARunMode($tfa_home) eq "RECEIVER" ) { 
	    $flag = $key."=".$val;
	  }
	  else {
	    print "You can not set the property $key from non Receiver node\n";
	    return FAILED;
	  }
	}
        elsif ( $key eq "r.send.collections" ) {
          #Settable from C node only. If -c flag provided set clusterwide
          if ( getTFARunMode($tfa_home) ne "RECEIVER" ) {
            $flag = $key."=".$val;
          }
          else {
            print "You can not set the property $key from non collector node\n";
            return FAILED;
          }
        }
 
        if ($key eq "autodiagcollect") {
          if (uc($val) eq "ON") {
	    $flag = "firediagcollectRT=true";
          }
	  else {
	    $flag = "firediagcollectRT=false";
	  }
        }
        if ($key eq "chaautocollect") {
          if (uc($val) eq "ON") {
	    $flag = "chaautocollect=true";
          }
	  else {
	    $flag = "chaautocollect=false";
	  }
        }
        if ($key eq "chanotification") {
          if (uc($val) eq "ON") {
	    $flag = "chanotification=true";
          }
	  else {
	    $flag = "chanotification=false";
	  }
        }
        if ($key eq "rtscan") {
          if (uc($val) eq "ON") {
	    $flag = "rtscan=true";
          }
	  else {
	    $flag = "rtscan=false";
	  }
        }
        if ($key eq "diskUsageMon") {
          if (uc($val) eq "ON") {
	    $flag = "diskUsageMon=true";
          }
	  else {
	    $flag = "diskUsageMon=false";
	  }
        }
        if ($key eq "manageLogsAutoPurge") {
          if (uc($val) eq "ON") {
	    $flag = "manageLogsAutoPurge=true";
          }
	  else {
	    $flag = "manageLogsAutoPurge=false";
	  }
        }
	if ($key eq "ciphersuite" ) {
	   $flag = "cipherSuite=" . $val;
	   $cluster_wide = "0";
	}
        if ($key eq "publicip") {
          if ( uc($val) eq "ON" ) {
	    $flag = "publicIp=true";
          }
	  else {
	    $flag = "publicIp=false";
	  }
        }
        if ($key eq "autopurge") {
          if (uc($val) eq "ON") {
	    $flag = "autoPurge=true";
          }
	  else {
	    $flag = "autoPurge=false";
	  }
        }
        if ($key eq "minagetopurge") {
	  $val = int($val);
	  my $ossurl = tfactlshare_getConfigValue(catfile($tfa_home, "internal", "config.properties"), "oss.url");
	  if ( $ossurl eq "null" ) { # If not ATP
	    if ($val < 12 ) {
              print "Purge Period should be greater than 11 Hours.\n"; 
              return FAILED;
            }
            if ($val > MAX_AGE_PURGE) {
              print "Purge Period should not be greater than " . MAX_AGE_PURGE . " Hours.\n";
              return FAILED;
            }
	  } else {  # If ATP
	    my $maxval = tfactlshare_getConfigValue(catfile($tfa_home, "internal", "config.properties"), "maxFileAgeToPurge");
	    $maxval = int($maxval);
	    if ($val > $maxval) {
	      $val = $maxval;
	    }
	  }
	  $flag = "minFileAgeToPurge=".$val;
        }
	if ($key eq "internalSearchString") {
          if (uc($val) eq "ON") {
            $flag = "internalSearchString=true";
          }
          else {
            $flag = "internalSearchString=false";
          }
        }
	if ($key eq "ignoreEventsInADE") {
          if (uc($val) eq "ON") {
            $flag = "ignoreEventsInADE=true";
          }
          else {
            $flag = "ignoreEventsInADE=false";
          }
        }
        if ($key eq "collectAllDirsByFile") {
	   if (uc($val) eq "ON") {
              $flag = "collectAllDirsByFile=true";
           }
           else {
             $flag = "collectAllDirsByFile=false";
           }
         }

	if ($key eq "trimfiles") {
	  if (uc($val) eq "ON") {
	    $flag = "trimfiles=true";
	  }
	  else {
	    $flag = "trimfiles=false";
	  }
	}
        if ($key eq "secureadd") {
          if (uc($val) eq "ON") {
            $flag = "secureadd=true";
          }
          else {
            $flag = "secureadd=false";
          }
        }
	if ($key eq "notificationAddress") {
	   if ($key =~ /:/) {
	      my @userval = split(/:/,$val);
              my $user;
              my $email;
              if (scalar(@userval)==2) {
                 $user=@userval[0];
                 $email=@userval[1];
                 dbg(DBG_WHAT,"Notification setting : User : $user "." email : $email");
              } else {
                 print "Invalid option specified: $flag\n";
                 return FAILED;
              }
		#validate user
              $flag = "$key=$user:$email";
	    } else { 
              $flag = $key."=".$val;
	    }
        }
        #if ($key eq "language") {
        #  $flag = $key."=".$val;
        #}
	#if ($key eq "encoding") {
        #  $flag = $key."=".$val;
        #}
	#if ($key eq "country") {
        #  $flag = $key."=".$val;
        #}
        if ($key eq "debugips") {
          if (uc($val) eq "ON") {
            $flag = "debugips=true";
          }
          else {
            $flag = "debugips=false";
          }
        }
	if ($key eq "blackout") {
	  if (uc($val) eq "ON") {
            $flag = "blackout=true";
          }
          else {
            $flag = "blackout=false";
          }
        }
	if ($key eq "redact") {
          if (uc($val) eq "SANITIZE") {
            $flag = "redact=sanitize";
          }
          elsif (uc($val) eq "MASK") {
            $flag = "redact=mask";
          }
          else {
            $flag = "redact=none";
          }
        }
        if ($key eq "tfaIpsPoolSize") {
          $val = int($val);
          if ($val < $TFAIPS_MINPOOLSIZE || $val> $TFAIPS_MAXPOOLSIZE) {
            print "tfaIpsPoolSize should be between $TFAIPS_MINPOOLSIZE & $TFAIPS_MAXPOOLSIZE.\n";
            return FAILED;
          }
          $flag = $key."=".$val;
        }
        if ($key eq "tfaDbUtlPurgeAge") {
          $val = int($val);
          if ($val < 604800 || $val> 2592000) {
            print "tfaDbUtlPurgeAge should be between 604800 (1 week) & 2592000 (1 month).\n";
            return FAILED;
          }
          $flag = $key."=".$val;
        }
        if ($key eq "tfaDbUtlPurgeMode") {
          if (uc($val) eq "SIMPLE") {
            $flag = "tfaDbUtlPurgeMode=simple";
          }     
          elsif (uc($val) eq "RESOURCE") {
            $flag = "tfaDbUtlPurgeMode=resource";
          } else {
            print "Allowed values for tfaDbUtlPurgeMode: simple/resource.\n";
            return FAILED;
          }     
        }
	#if ($key eq "AlertLogLevel") {
        #  $flag = $key."=".$val;
        #}
        #if ($key eq "UserLogLevel") {
        #  $flag = $key."=".$val;
        #}
        #if ($key eq "BaseLogPath") {
        #  $flag = $key."=".$val;
        #}
  }
  elsif ($flag eq "sslconfig") {
      	print "Please Enter server certificate path : ";
	my $serverCert = <>;
	chomp($serverCert);
	my $serverKeyStorePass = promptForPassword("server keystore keypass ", 1);
	print "\n";
	my $serverTrustStorePass = promptForPassword("server keystore storepass ", 1);
	print "\n";
	print "Please Enter client certificate path? : ";
	my $clientCert = <>;
	chomp($clientCert);
	my $clientKeyStorePass = promptForPassword("client keystore keypass ", 1);
        print "\n";
	my $clientTrustStorePass = promptForPassword("client keystore storepass ", 1);
	print "\n";
	#print "$serverCert , $serverKeyStorePass , $serverTrustStorePass , $clientCert , $clientKeyStorePass , $clientTrustStorePass\n";
	my $message ="$localhost:setconfig:$flag:$cluster_wide:$serverCert:$serverKeyStorePass:$serverTrustStorePass:$clientCert:$clientKeyStorePass:$clientTrustStorePass";
  	my $command = buildCLIJava($tfa_home,$message);
  	dbg(DBG_VERB, "$command\n");
  	my $line;
  	dbg(DBG_VERB,"#### Setting $flag####\n");
        my @cli_output = tfactlshare_runClient($command);
  	foreach $line ( @cli_output )
  	{
    		if ( $line eq "DONE") {
		   print "SSL certificate details successfully set\n";
		   print "The certificates are restricted to root read only\n";
		   return SUCCESS;
		   #$tfa_home/bin/tfactl stop;
		   #$tfa_home/bin/tfactl start;
		}
	}
  }
  else {
	print "Invalid option specified: $flag\n";
	return FAILED;
  }
  
  my $message ="$localhost:setconfig:$flag:$cluster_wide";
  if ($set_cmd_args ne "") {
    $message ="$message:$set_cmd_args";
  } 
  my $command = buildCLIJava($tfa_home,$message);
  if ($flag !~ /cookie=/) {
  	dbg(DBG_VERB, "$command\n");
  }
  my $line;
  if ($flag !~ /cookie=/) {
  	dbg(DBG_VERB,"#### Setting $flag####\n");
  }
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {  
    if ( $line eq "DONE") {
      if ($during_install == 0) {
        $flag =~ s/firediagcollectRT/autodiagcollect/;
        $flag =~ s/true/ON/;
        $flag =~ s/false/OFF/;

        if ( $key ne "walletpassword" ) {
	  print "Successfully set $flag\n";
        }

        if ($key eq "cookie") {
 	  print "TFA Cookie: ";
	  printCookie($tfa_home);
        }
        elsif ($key eq "walletpassword") {
	  #print "Oracle Wallet Password for $localhost: ";
	  #printWalletPassword($tfa_home);
        }
	elsif ( $key eq "r.repository" || $key eq "r.send.collections" || $key eq "r.port" ) {
      	  printConfig($tfa_home, "node=local~name=$key");
   	}
        else {
      	  printConfig($tfa_home, "node=local~name=all");
        }
      }
      dbg(DBG_VERB,"#### Done ####\n");
      return SUCCESS;
    }
    else {
      print "$line\n";
    }
  }
  dbg(DBG_NOTE,"Could not set $flag\n");
  return FAILED;

}

#
# This will store OSS Environment Variables in internal directory
# TFA Daemon will remove this after using it

sub storeOSSEnvInTFA {
	my $tfa_home = shift;

	my $osspswd = $ENV{TFA_OSS_PASSWORD};
	my $walpswd = $ENV{TFA_WALLET_PASSWORD};

	if ( $osspswd || $walpswd ) {
		my $ossenv = catfile($tfa_home, "internal", ".oss.env");
		sysopen(OSS, $ossenv, O_WRONLY|O_TRUNC|O_CREAT, 0600) or return "Couldn't create file $ossenv : $!\n";
		if ( $osspswd ) {
			$osspswd = tfactlshare_spl_chr2tag($osspswd);
			print OSS "oss.password=$osspswd\n";
		}
		if ( $walpswd ) {
			print OSS "wallet.password=$walpswd\n";
		}
		close(OSS);
	}
}

#
#======================= checkVersion ===========================#
#
sub checkVersion {
  my $tfa_home = shift;
  my $localhost = tolower_host();
  dbg(DBG_WHAT, "Running checkVersion through Java CLI \n");
  my $message = "$localhost:checkversion";
  my $command = buildCLIJava($tfa_home, $message);
  #print "$command \n";
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output ) {
    if ($line eq "DONE") {
	return SUCCESS;
    }
    else {
	print "$line\n";
    }
  }
  dbg(DBG_WHAT, "Could not print version");
  return FAILED;
}

#
# Subroutine to check TFA Upgrade Status
#
sub tfactlshare_checkUpgradeStatus {
	my $tfa_home = shift;
	my $upgradedversion = shift;
	my $localhost = tolower_host();

	if (isTFARunning($tfa_home) == FAILED) {
		exit 0;
	}

	my $message = "$localhost:checkTFAStatus";
	my $command = buildCLIJava($tfa_home, $message);

	my $tb = Text::ASCIITable->new();
	$tb->setCols("Host", "TFA Version", "TFA Build ID", "Upgrade Status");
	$tb->setOptions({"outputWidth" => $tputcols});

	my $line;
	my $status;
	my @lines = tfactlshare_runClient($command);
	my ($output, $hostname, $tfapid, $tfaport, $version, $buildid, $invrunstatus);

	if ( ! $upgradedversion ) {
		($output, $hostname, $tfapid, $tfaport, $version, $buildid, $invrunstatus) = split(/!/, $lines[0]);

		if ( $localhost eq $hostname) {
			$upgradedversion = $version;
			$upgradedversion =~ s/\.//g;
		}
	}

	foreach $line ( @lines ) {
		$status = "NOT UPGRADED";
		($output, $hostname, $tfapid, $tfaport, $version, $buildid, $invrunstatus) = split(/!/, $line);

		my $tfaversion = $version;
		$tfaversion =~ s/\.//g;

		if ( $output eq "CheckOK") {
			if ( $upgradedversion eq $tfaversion ) {
				$status = "UPGRADED";
			}
		} else {
			$version = "-";
			$buildid = "-";
		}

		if ( $hostname && $version && $buildid ) {
			$tb->addRow($hostname, $version, $buildid, $status);
		}
	}

	print "$tb\n";
	return SUCCESS;
}


sub runTasks {
  my ($tfa_home, $option) = @_;
  my $localhost = tolower_host();

  my $message = "$localhost:runtasks:$option";
  my $command = buildCLIJava($tfa_home, $message);
  my $executeCommand = 0;
  my $line;
  
  $ENV{TFA_HOME} = $tfa_home;
  #chdir("");
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output ) {
    if ($line eq "DONE") {
      return "SUCCESS";
    }
    elsif ($line =~ /The following commands will be executed/) {
      $executeCommand = 1;
    }
    else {
      if ($executeCommand == 1) {
        print "Executing $line ...\n";
        system($line);
      }
      else {
        print "$line\n";
      }
    }
  }
  return FAILED;
}

sub getRepositoryMaxSize
{
  my $tfa_home = shift;
  dbg(DBG_WHAT, "In getRepositoryMaxSize\n");
  my $localhost=tolower_host();
  
  dbg(DBG_WHAT, "Running getRepositoryMaxSize through Java CLI\n");
  my $message ="$localhost:printmaxsizeofrepository";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "$command\n");
  
  
  my $line;
  my $reposize;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
    if ( $line eq "DONE") {
      return $reposize;
    }
    else {
      $reposize = $line;
      #return $reposize;
    }
  }
  return FAILED;
}

sub getCurrentRepository
{
  my $tfa_home = shift;
  dbg(DBG_WHAT, "In getCurrentRepository\n");
  my $localhost=tolower_host();
  
  my $repo = tfactlshare_getConfigValue(catfile($tfa_home, "internal", "config.properties"), "repository");
  if ( ! -d $repo ) {
   dbg(DBG_WHAT, "Running getCurrentRepository through Java CLI\n");
   my $message ="$localhost:printlocationofrepository";
   my $command = buildCLIJava($tfa_home,$message);
   dbg(DBG_VERB, "$command\n"); 
   my $line;
   my $repos;
   my @cli_output = tfactlshare_runClient($command);
   foreach $line ( @cli_output )
   {
    if ( $line eq "DONE") {
      return $repos;
    }
    else {
      $repos = $line;
      #return $repos;
    }
   }
  } else {
  return $repo;
  }
  return FAILED;
}


sub printLocalRepository
{
  my $tfa_home = shift;
  dbg(DBG_WHAT, "In printLocalRepository\n");
  my $localhost=tolower_host();
  
  dbg(DBG_WHAT, "Running printRepository through Java CLI\n");
  my $message ="$localhost:printrepository";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "$command\n");
  
  my $tb = Text::ASCIITable->new();
  $tb->setCols("Repository Parameter", "Value");
  $tb->alignCol("Value","left");
  $tb->setColWidth("Value", $tputcols-30);
  $tb->setOptions({"outputWidth" => $tputcols, "headingText" => $localhost});
  
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
  if ( $line eq "DONE") {
  	print $tb;
          dbg(DBG_WHAT,"#### Stored Trace Repository Printed ####\n");
          return SUCCESS;
  }
  else {
      if ($line =~ /Connection refused/) {
      }
      else {
        my ($rloc,$rmaxmb,$rcurmb,$rcurb,$status,$rhost) = split(/!/, $line);
        if ($rhost eq $localhost) {

	      my $freespace = 0;
	
	      if ( $rmaxmb >= $rcurmb ) {
		$freespace = $rmaxmb - $rcurmb;
	      }
  	      $tb->addRow("Location", $rloc);
  	      $tb->addRow("Maximum Size (MB)", $rmaxmb);
  	      $tb->addRow("Current Size (MB)", $rcurmb);
  	      $tb->addRow("Free Space (MB)", $freespace);
  	      $tb->addRow("Status", $status);
        }
      }
  }
  }
  dbg(DBG_WHAT,"Could not print stored trace repository\n");
  return FAILED;
}

#
#======================= printRepository ===========================#
#
sub printRepository
{
  my $tfa_home = shift;
  my $host = shift;
  dbg(DBG_WHAT, "In printRepository\n");
  my $localhost=tolower_host();
  if (isTFARunning($tfa_home) == FAILED) {
	exit 0;
  }
  my $message;
  dbg(DBG_WHAT, "Running printRepository through Java CLI\n");
  if(defined($host)){
    $message ="$localhost:printrepository:$host";
  } else {
    $message ="$localhost:printrepository";
  }
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "$command\n");

  #my @nodelist = split("\,",$NODE_NAMES);
  my @nodelist;
  if (defined($host)){
   @nodelist = ($host);
  } else {
   @nodelist = getListOfAllNodes( $tfa_home );
  }

  my %TABLES;
  foreach (@nodelist) {
	my $tb = Text::ASCIITable->new();
	$tb->setCols("Repository Parameter", "Value");
	$tb->alignCol("Value","left");
	$tb->setOptions({"headingText" => $_ });
	$TABLES{$_} = $tb;
  }

  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
  if ( $line eq "DONE") {
	my $key_entry;
	my $value;
	while (($key_entry, $value) = each(%TABLES)) {
		print $TABLES{$key_entry}."\n";
	}
    	dbg(DBG_WHAT,"#### Stored Trace Repository Printed ####\n");
    	return SUCCESS;
  }
  else {
    if ($line =~ /Connection refused/) {
    	my ($msg, $hostname) = split(/!/, $line);
    	delete $TABLES{$hostname};
    }
    else {
      my ($rloc,$rmaxmb,$rcurmb,$rcurb,$status,$rhost) = split(/!/, $line);
      my $table = $TABLES{$rhost};
      if (defined($table)) {
	my $freespace = 0;
	
	if ( $rmaxmb >= $rcurmb ) {
		$freespace = $rmaxmb - $rcurmb;
	}

	my $length = length( $rloc );
	if ( (length($status)) > $length ) {
		$length = length($status);
	}
	$table->setColWidth("Value", $length);
	$table->setOptions({"outputWidth" => $length });

        $table->addRow("Location", $rloc);
        $table->addRow("Maximum Size (MB)", $rmaxmb);
        $table->addRow("Current Size (MB)", $rcurmb);
        $table->addRow("Free Size (MB)", $freespace);
        $table->addRow("Status", $status);
      }
    }
  }
  }
  dbg(DBG_WHAT,"Could not print stored trace repository\n");
  return FAILED;

}
#
#======================= printHosts ===========================#
#
sub printHosts
{
  my $tfa_home = shift;
  dbg(DBG_VERB, "In printHosts\n");
  my $localhost=tolower_host();
  if (isTFARunning($tfa_home) == FAILED) {
	exit 0;
  }

  dbg(DBG_VERB, "Running printHosts through Java CLI\n");
  my $message ="$localhost:printhosts";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "Command $command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
  if ( $line eq "DONE") {
    dbg(DBG_WHAT,"#### All Stored Hosts Printed ####\n");
    return SUCCESS;
  }
  else {
  print "$line\n";
  }
  }
  dbg(DBG_WHAT,"Could not print stored hosts\n");
  return FAILED;

}

#
#======================= printRObjects ===========================#
#
sub tfactlshare_printRObjects
{
  my $tfa_home = shift;
  dbg(DBG_VERB, "In tfactlshare_printRObjects\n");
  my $localhost=tolower_host();
  #Check whether TFA Main is running or not
  if (isTFARunning($tfa_home) == FAILED) {
        exit 0;
  }

  dbg(DBG_VERB, "Running printRObjects through Java CLI\n");
  my $message ="$localhost:printrobjects:show";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "Command $command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output ) {
    if ( $line eq "DONE") {
      dbg(DBG_WHAT,"#### All Stored R Objects Printed ####\n");
      return SUCCESS;
    }
    else {
      print "$line\n";
    }
  }
  dbg(DBG_WHAT,"Could not print stored R Objects\n");
  return FAILED;
}

sub tfactlshare_get_clients
{
  my $tfa_home = shift;
  my $details = shift;

  my @out = ();

  dbg(DBG_VERB, "In tfactlshare_get_clients\n");
  my $localhost=tolower_host();
  #Check whether TFA Main is running or not
  if (isTFARunning($tfa_home) == FAILED) {
        exit 0;
  }

  dbg(DBG_VERB, "Running printRObjects through Java CLI\n");
  my $message ="$localhost:printrobjects:showtype";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "Command $command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output ) {
    if ( $line eq "DONE") {
      dbg(DBG_WHAT,"#### All Stored R Objects Printed ####\n");
      return @out;
    }
    else {
      if ( $line =~ /\s([^\s\~]+)~group=([^\~]+)\~/ )
      {
        if($details == 1 && (index($line, "type=mc") != -1)) {
          push(@out, $1);
        }
        elsif( $details == 0 ) {
          push(@out, $1);
        }
      }
    }
  }
  dbg(DBG_WHAT,"Could not print stored R Objects\n");
  return FAILED;
}

#
#======================= printReceivers ===========================#
#
sub printReceivers
{
  my $tfa_home = shift;
  dbg(DBG_VERB, "In printReceivers\n");
  my $localhost=tolower_host();
  #Check whether TFA Main is running or not
  if (isTFARunning($tfa_home) == FAILED) {
        exit 0;
  }

  my $is_receiver = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "RUN_MODE");  
  if ( $is_receiver eq "receiver" ){
    print "This command is not supported under Receiver Mode\n" ;
    exit 0;
  }

  dbg(DBG_VERB, "Running printReceivers through Java CLI\n");
  my $message ="$localhost:printreceivers";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "Command $command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
  if ( $line eq "DONE") {
    dbg(DBG_WHAT,"#### All Stored Receivers Printed ####\n");
    return SUCCESS;
  }
  else {
  print "$line\n";
  }
  }
  dbg(DBG_WHAT,"Could not print stored receivers\n");
  return FAILED;

}

#
#======================= printCollectors===========================#
#
sub printCollectors
{
  my $tfa_home = shift;
  dbg(DBG_VERB, "In printCollectors\n");
  my $localhost=tolower_host();
  #Check whether TFA Main is running or not
  if (isTFARunning($tfa_home) == FAILED) {
        exit 0;
  }

  my $is_receiver = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "RUN_MODE");  
  if ( $is_receiver ne "receiver" ){
        print "This command is not supported under Collector Mode\n" ;
        exit 0;
  }

  dbg(DBG_VERB, "Running printCollectors through Java CLI\n");
  
  #my $message ="$localhost:printcollectors";
  my $message ="$localhost:printcollectors:false";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "Command $command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
  if ( $line eq "DONE") {
    dbg(DBG_WHAT,"#### All Stored Collectors Printed ####\n");
    return SUCCESS;
  }
  else {
  print "$line\n";
  }
  }
  dbg(DBG_WHAT,"Could not print stored collectors\n");
  return FAILED;

}

sub checkForAvailableSpaceInFileSystem
{
  my ($repos, $size) = @_;
  my $space_requested;

  my $space_available = osutils_check_available_space($repos,"true");
  
  my $space_requested = ($size * 1024);
  dbg(DBG_WHAT,"Space Requested for repository in kB : $space_requested\n");
  dbg(DBG_WHAT,"Space Available in filesystem in kB : $space_available\n");
  if ($space_requested >= $space_available) {
    print "Not enough space in filesystem to allocate $size MB to repository.\n";
    return "NOT AVAILABLE";
  }
  elsif ($space_requested > (0.5 * $space_available)) {
    print "Repository size will consume more than 50% of available space in filesystem.\n";
    print "Do you wish to continue with the new size ? [Y/y/N/n] [N] ";
    chomp( my $changesize = <STDIN> );
    $changesize ||= 'N';
    $changesize = get_valid_input ($changesize, "Y|y|N|n", "N");
    if ($changesize=~ /[Yy]/) {
	return "AVAILABLE";
    }
    else {
	return "NOT AVAILABLE";
    }
  }
  return "AVAILABLE";
}

#
# Subroutine to remove host from TFA
#
sub removeHost {
	my ($tfa_home, $host) = @_;
	my $hostname = $host;
	dbg(DBG_WHAT,  "In removeHost for :: $host\n");
	my $localhost=tolower_host();

	if (isTFARunning($tfa_home) == FAILED) {
		exit 0;
	}

	if ($host =~ /\./) {
           print "Please provide hostname without domain name\n";
        }

	$host =~ tr/A-Z/a-z/;
	if ($host eq $localhost) {
		print "Cannot remove host $host from TFA\n";
		return FAILED;
	}

	if (isNodePartOfCluster($tfa_home, $host)) {
	}
	else {
		print "Cannot remove host $host from TFA as it is not part of TFA cluster.\n";
		return FAILED;
	}

	my $actionmessage = "$localhost:removehost:$host\n";
	dbg(DBG_WHAT, "Running removeHost through Java CLI\n");
	my $command = buildCLIJava($tfa_home,$actionmessage);
	dbg(DBG_VERB, "$command\n");
	my $line;
	my @cli_output = tfactlshare_runClient($command);
	foreach $line ( @cli_output ) {
	dbg(DBG_WHAT, "Line : $line\n");
		if ( $line eq "SUCCESS") {
			print "Successfully removed host : $hostname\n\n";
			print "List of hosts in TFA : \n";
			printHosts($tfa_home);
			dbg(DBG_WHAT,"#### Removed Host ####\n");
			return SUCCESS;
		}
	}

	dbg(DBG_WHAT,"Could not remove host\n");
	return FAILED;
}

sub generateTFACookie
{
 my $tfa_home = shift;
 use Digest::MD5  qw(md5_hex);
 my $t=localtime();
 my $md5_data = "TFA.$t";
 my $cookie = md5_hex( $md5_data );
 setFlag($tfa_home,"cookie=$cookie",1,1);
 return $cookie;
}

sub sslRestart {
	my $tfa_home = shift;
	my $tfactl;
	if($IS_WINDOWS){
		$tfactl = catfile($tfa_home, "bin", "tfactl.bat");
	}else{
		$tfactl = catfile($tfa_home, "bin", "tfactl");
	}
	

	# Bug 22064626
	my $dbs = catfile($tfa_home, "internal", "dbs.txt");
	my $count = 0;

	while ( $count < 12 ) {
		if ( -f $dbs ) {
			last;
		} else {
			sleep(5);
			$count++;
		}
	}

	if ( -f $tfactl ) {
		updateSSLConfig("sslKey","1",catfile($tfa_home,"internal","ssl.properties"),$tfa_home);
	
		if ($IS_WINDOWS) {
			my $file = catfile($tfa_home,"internal",".pidfile");
			my $PID = trim(qx(type $file));

			if(defined($PID) && ($PID ne '')){
				qx(taskkill /F /PID $PID);
			}
		} else {
			my $qxCommand = "$TOUCH ".catfile($tfa_home,"internal",".initRestartTFA");
			qx($qxCommand); 
		}
	}
}

sub generateCerts
{
  my $temp_tfahome = shift;
  my $tfa_jhome = shift;
  my $sslkey = shift;
  my $clusteruid = tfactlshare_generate_password(16);
  generateKeystores($temp_tfahome, $tfa_jhome, $clusteruid);
  my $class = "oracle.rat.tfa.util.WriteSSLConfig";
  my $args = $temp_tfahome . " " . $clusteruid . " " . $sslkey;
  my $command = buildJava($tfa_jhome, $temp_tfahome, $class, $args);
  `$command`;
  my $sslprop = catfile($temp_tfahome,"internal","ssl.properties");
  chmod(0600, $sslprop) or die "Couldn't chmod $sslprop: $!";
  #Generate receiver certificates if TFA R Mode
  generateReceiverCerts($temp_tfahome, $tfa_jhome);
}

sub generateKeystores
{
 
 my $temp_tfahome = shift;
 my $tfa_jhome = shift;
 my $clusteruid = shift;
 my $keytool = catfile("$tfa_jhome","bin","keytool");
 if ( $osname eq "SunOS" ) {
	$keytool = getJavaOnSunOS($tfa_jhome, "keytool");
  }
 my $serverjks = catfile($temp_tfahome,"server.jks");
 my $clientjks = catfile($temp_tfahome,"client.jks");
 my $serverCert = catfile($temp_tfahome,"server_pub.crt");
 my $clientCert = catfile($temp_tfahome,"client_pub.crt");

 my $genServer = "$keytool -genkey -dname \"cn=ORACLE CORPORATION, ou=ST, o=ORACLE CORPORATION, l=REDWOOD SHORES, st=CALIFORNIA, c=US\" -alias server_full -keyalg RSA -sigalg SHA256withRSA -keysize 2048 -validity 18263 -keystore $serverjks -keypass $clusteruid -storepass $clusteruid 2>&1";
 my $cmd_out = qx($genServer);
 
 my $genClient = "$keytool -genkey -dname \"cn=ORACLE CORPORATION, ou=ST, o=ORACLE CORPORATION, l=REDWOOD SHORES, st=CALIFORNIA, c=US\" -alias client_full -keyalg RSA -sigalg SHA256withRSA -keysize 2048 -validity 18263 -keystore $clientjks -keypass $clusteruid -storepass $clusteruid 2>&1";
 $cmd_out = qx($genClient); 

 qx($keytool -export -alias server_full -file $serverCert -keystore $serverjks -storepass $clusteruid 2>$DEVNULL);
 qx($keytool -export -alias client_full -file $clientCert -keystore $clientjks -storepass $clusteruid 2>$DEVNULL);
 qx($keytool -import -alias cerver_pub -file $serverCert -keystore $clientjks -storepass $clusteruid -noprompt 2>$DEVNULL);
 qx($keytool -import -alias client_pub -file $clientCert -keystore $serverjks -storepass $clusteruid -noprompt 2>$DEVNULL);
 chmod(0600, $serverjks) or die "Couldn't chmod $serverjks: $!";
 chmod(0600, $clientjks) or die "Couldn't chmod $clientjks: $!";
 chmod(0600, $serverCert) or die "Couldn't chmod $serverCert: $!";
 chmod(0600, $clientCert) or die "Couldn't chmod $clientCert: $!";
}

## This function generates keystore for receiver process
sub generateReceiverCerts
{
  my $tfa_home = shift;
  my $tfa_jhome = shift;
  my $runmode;
  my $paramfile = catfile($tfa_home,"tfa_setup.txt");

  #Generate receiver certificates only if TFA is installed in RECEIVER mode
  if (-s $paramfile) {
    $runmode = tfactlshare_getConfigValue($paramfile, "RUN_MODE");
  }
  if ($runmode ne "receiver") {
    dbg( DBG_WHAT , "Not generating receiver certificates as TFA is not in R Mode\n");
    return;
  }
  
  dbg( DBG_WHAT , "Generating receiver certificates\n");
  my $passwd = tfactlshare_generate_password(16);
  my $keytool = catfile("$tfa_jhome","bin","keytool");
  if ( $osname eq "SunOS" ) {
    $keytool = getJavaOnSunOS($tfa_jhome, "keytool");
  }
	
  my $receiverjks = catfile($tfa_home,"receiver","receiver.jks");
  my $rsslprop = catfile($tfa_home,"receiver","internal","r.ssl.properties");
  my $genReceiver = "$keytool -genkey -dname \"cn=ORACLE CORPORATION, ou=ST, o=ORACLE CORPORATION, l=REDWOOD SHORES, st=CALIFORNIA, c=US\" -alias receiver_full -keyalg RSA -sigalg SHA256withRSA -keysize 2048 -validity 18263 -keystore $receiverjks -keypass $passwd -storepass $passwd";
  my $cmd_out = qx($genReceiver);
  if($cmd_out ne "" ) {
    die "Failed to generate receiver certificates: $cmd_out\n";
  }

  my $class = "oracle.rat.tfa.util.WriteSSLReceiverConfig";
  my $args = $tfa_home . " " . $passwd . " receiver";
  my $command = buildJava($tfa_jhome, $tfa_home, $class, $args);
  `$command`;

  chmod(0600, $receiverjks) or die "Couldn't chmod $receiverjks: $!";
  chmod(0600, $rsslprop) or die "Couldn't chmod $rsslprop: $!";
}

sub buildJava
{
 my $tfa_jhome = shift;
 my $temp_tfahome = shift;
 my $class = shift;
 my $args = shift;
 my $java = catfile($tfa_jhome,"bin","java$EXE");
 if ( $osname eq "SunOS" ) {
	$java = getJavaOnSunOS($tfa_jhome, "java");
  }
 my $tfa_jar = catfile($temp_tfahome, "jlib", "RATFA.jar");
 my $classpath = "";
 $classpath = "$tfa_jar";
 my $commandline = "$java -Xms128m -Xmx256m -classpath \"$classpath\" $class $args";
 return $commandline;
}

sub checkDbExistence
{
  my ($tfa_home, $database, $nodelist) = @_;
  my $localhost=tolower_host();
  my $actionmessage = "$localhost:checkdbexistence:$database:$nodelist\n";
  my $command = buildCLIJava($tfa_home,$actionmessage);
  dbg(DBG_VERB, "$command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
  #print "$line\n";
  if ($line =~ /DB EXISTS/) {
    return SUCCESS;
  }
  elsif ($line =~ /DB DOES NOT EXIST/) {
    return FAILED;
  }
  }
  return FAILED;
}

sub checkRepositoryIsOpen
{
 my $tfa_home = shift;
 my $localhost=tolower_host();
 my $actionmessage = "$localhost:checkrepositoryisopen\n";
 my $command = buildCLIJava($tfa_home,$actionmessage);
 dbg(DBG_VERB, "$command\n");
 my $line;
 my @cli_output = tfactlshare_runClient($command);
 foreach $line ( @cli_output )
 {
   if ($line =~ /Repository is open/) {
     return SUCCESS;
   }
   elsif ($line =~ /Repository is full and closed/) {
     return FAILED;
   }
 }
 return FAILED;
}

#
# Subroutine to add host to TFA
#
sub addHost
{
	my ($tfa_home, $host, $is_commandline, $remoteport) = @_;
	my $hostname = $host;
	dbg(DBG_WHAT,  "In addHost for :: $host\n");
	my $localhost = tolower_host();

	if (isTFARunning($tfa_home) == FAILED) {
  		exit 0;
	}

	if ($host =~ /\./) {
           print "Please provide hostname without domain name\n";
        }

  	$host =~ tr/A-Z/a-z/;
  	if ($host eq $localhost) {
    		print "Host $host is already added to TFA\n";
    		return FAILED;
  	}

  	if (isNodePartOfCluster($tfa_home, $host)) {
		if ($is_commandline == 1) {
                        print "Host $host is part of TFA cluster\n";
                }
                return FAILED;
	}
  
  	if ($is_commandline == 1) {
  		my $sudo_user = $ENV{SUDO_USER};
  		my $sudo_command = $ENV{SUDO_COMMAND};
  
    		if ( $sudo_user && $sudo_command =~ /tfactl/ ) {
  			print "User $sudo_user does not have permissions to add host. Please run the command as root\n";
          		return FAILED;
    		}
  	}

  	my $actionmessage = "$localhost:addhost:$host:$is_commandline:$remoteport\n";
  	dbg(DBG_WHAT, "Running addHost through Java CLI\n");
  	my $command = buildCLIJava($tfa_home,$actionmessage);
  	dbg(DBG_VERB, "$command\n");
  	my $line;
	my @cli_output = tfactlshare_runClient($command);
  	foreach $line ( @cli_output ) {
  		if ( $line eq "SUCCESS") {
      			if ($is_commandline == 1) {
      				dbg(DBG_NOTE, "Successfully added host: $hostname\n\n");
      				print "List of hosts in TFA : \n";
      				printHosts($tfa_home);
      				dbg(DBG_WHAT,"#### Added Host ####\n");
      			}
      			return SUCCESS;
  		}
  		elsif ($line =~ /FAILED - Cookies do not match/) {
		      	my $tfactl = getTfactlPath($tfa_home);
		      	my @values = split(/\|/, $line);
		      	my $remotetfactl = @values[1];
		      	print "Failed to add host: $host as the TFA cookies do not match.\n";
		      	print "To add the host successfully, try the following steps:\n";
		      	print "1. Get the cookie in $localhost using:\n";
		      	print " $tfactl print cookie\n";
		      	print "2. Set the cookie from Step 1 in $host using:\n";
		      	print "  $remotetfactl set cookie=<COOKIE>\n";
		      	print "3. After Step 2, add host again:\n";
			print " $tfactl host add $host\n";
		}
		elsif ($line =~ /FAILED - Connection refused/) {
			print "Connection refused to host: $host\n";
  		}
		elsif ($line =~ /FAILED - Could not determine TFA port/) {
			print "Unable to determine port on which TFA is listening in $host\n";
		}
		else {
			print "Failed to add host: $host\n";
		}
	}
	dbg(DBG_WHAT,"Could not add host\n");
	return FAILED;
}

#
#==== executeCommandInHost  ====#
#
sub executeCommandInHost
{
  my ($tfa_home, $command, $remotenode) = @_;
  my $localhost=tolower_host();
  my $actionmessage = "$localhost:executecommand:$remotenode:$command";
  my $command = buildCLIJava($tfa_home,$actionmessage);
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
        if ($line eq "DONE") {
          return SUCCESS;
        }
        #print "Received from $remotenode: $line\n";
  }
  return FAILED;
}

#
#==== executeCommandInHostAndPrint  ====#
#
sub executeCommandInHostAndPrint
{
  my ($tfa_home, $program, $command, $remotenode) = @_;
  my $localhost=tolower_host();
  my $actionmessage = "$localhost:executecommandprint:$remotenode:$program:$command";
  my $command = buildCLIJava($tfa_home,$actionmessage);
  my $line; 
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare executeCommandInHostAndPrint " .
                      "COMMAND $command",
                      'y', 'y');
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
        if ($line eq "DONE") {
          return SUCCESS;
        }
        print "$line\n";
  }
  return FAILED;
}

#
#==== executeCommandInHostAndGetOutput  ====#
#
sub executeCommandInHostAndGetOutput
{
  my ($tfa_home, $program, $command, $remotenode) = @_;
  my $localhost=tolower_host();
  my $actionmessage = "$localhost:executecommandprint:$remotenode:$program:$command";
  my $command = buildCLIJava($tfa_home,$actionmessage);
  my $line;
  my $output = "";
  #print "Program $program Command $command\n";
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare executeCommandInHostAndPrint " .
                      "COMMAND $command",
                      'y', 'y');
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
        if ($line eq "DONE") {
          return $output;
        }
        print "$line\n";
        $output .= $line;
  }
  return "FAILED";
}

#
#==== tfactlshare_execute_clusterwide  ====#
#
sub tfactlshare_execute_clusterwide {
  my ($command, $args) = @_;

  my $localhost = tolower_host();
  # getListOfAllNodes
  my @hostlist = getListOfOtherNodes( $tfa_home );
  my $tfa_base = $tfa_home;
  my $remote_home;
  my $remote_node;

  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_execute_clusterwide " .
                      "command: $command , args: $args", 'y', 'y');

  if ( $tfa_base =~ /(\\|\/)$localhost(\\|\/)tfa_home/ ) {
    $tfa_base =~ s/(\\|\/)$localhost(\\|\/)tfa_home//;
  }

  foreach $remote_node ( @hostlist ) {
    $remote_home = catdir($tfa_base,$remote_node,"tfa_home");
    my $runmsg = "\nRunning command $command on $remote_node ...\n";
    $runmsg =~ s/local//;
    print $runmsg;
    executeCommandInHostAndPrint(
        $tfa_home,
        catfile($tfa_home,"bin","tfactl") . " " . $command,
        $args,
        $remote_node );
  } # end foreach


  return SUCCESS;
}

sub tfactlshare_execute_tfactl_cmd_withstatusonly {
  my ($print_command,$clusterwide, $command, $status_message, @expected_output_strings) = @_;
  my $localhost = tolower_host();
  my @hostlist;
  @hostlist = getListOfOtherNodes( $tfa_home ) if($clusterwide);
  push(@hostlist,$localhost);
  
  my $tfa_base = $tfa_home;
  my $remote_home;
  my $remote_node;
  my $cpid = $$;

  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_execute_tfactl_cmd_withstatusonly " . "command: $command on Nodes : $#hostlist", 'y', 'y');

  if ( $tfa_base =~ /(\\|\/)$localhost(\\|\/)tfa_home/ ) {
    $tfa_base =~ s/(\\|\/)$localhost(\\|\/)tfa_home//;
  }

  my $temp_log_loc = catfile($TMP,"cw_$localhost.$cpid.out");
  print "\nRunning Command 'tfactl $command' On :\n" if($print_command eq "yes");
  $command =~ s/-XX:/-XX#/g;
  foreach $remote_node ( @hostlist ) {
    print "Node : $remote_node : ";
    $remote_home = catdir($tfa_base,$remote_node,"tfa_home");

    my $status;
    my $version_output;
    my $found ="false";
    my @TMP;

    if($command eq "restarttfa"){
       my $restart_command = catfile($INITDIR, "init.tfa")." start oracle-tfa";
       ($version_output,$status) = host_remote($remote_node,$restart_command,$localhost, 'OUTPUT_REDIRECT');
       @TMP = @$version_output;      
    }else {
      $status = executeCommandInHost(
      $tfa_home,
      catfile($remote_home,"bin","tfactl") . " $command > $temp_log_loc 2>&1",
      $remote_node );

      open(TMP,"<$temp_log_loc");
      @TMP = <TMP>;
      unlink("$temp_log_loc");
      close(TMP);
    }

    foreach my $line ( @expected_output_strings){
      if (grep /$line/, @TMP) {
        $found = "true";
      } else {
        $found = "false";
      }
    }
    if($found eq "true") {
      print "$status_message\n";
    } else {
      print "FAILED\n";
      print "     ---------------------------\n";
      print "     Detailed Command Output : \n";
      foreach my $line ( @TMP){
        next if($line =~ m/^$/);
        print "     $line\n";
      } 
      print "     ---------------------------\n";
    }
  } 
}
#
#==== setSR  ====#
#
sub setSR
{
my $srnum = shift;
dbg(DBG_WHAT, "In setSR for :: $srnum\n");
my $localhost=tolower_host();
my $remote = sockConnect();
dbg(DBG_WHAT, "Connected to ", $remote->peerhost, " on port: ", $remote->peerport, "\n");

my $returnmessage;
my $actionmessage = "$localhost:sr:$srnum\n";
$remote->send($actionmessage);
$remote->recv($returnmessage,1024);
print "$returnmessage";
if ($returnmessage eq "SUCCESS\n") {
print "Modified SR\n";}
else {
print "Failed to set SR\n";}
$remote->close();
}

#
#
#==== get_user_input  ====#
#
sub get_user_input
{
  my ($count) = 3;
  my ($user_input) = "";

  while ($count != 0 && $user_input )
  {
    $count--;
    $user_input = <STDIN>;
    chomp($user_input);
    print "Invalid input. Please enter again ($count tries remaining) : " if ( ! $user_input );
  }
}

sub get_valid_input
{
  my $ip = shift;
  my $str_to_check = shift;
  my $default_on_empty = shift;
  my $valid_input = 0;
  my @valid_inputs = split(/\|/, $str_to_check);
  my ( $str2 );

  while ( $valid_input == 0 )
  {
    foreach $str2 (@valid_inputs)
    {
      if ( $ip eq $str2 )
      {
        $valid_input = 1;
        return $ip;
      }
    }
    print "Invalid input. Please enter again : $str_to_check [$default_on_empty] ";
    $ip = <STDIN>;
    chomp($ip);
    $ip = $default_on_empty if ( ! $ip );
  }
}

sub get_os_prefix_oratop
{
  my $uname = `which uname`;
  chomp($uname);
  if ( ! $uname )
  {
    $uname = "/usr/bin/uname" if ( -f "/usr/bin/uname" );
    $uname = "/bin/uname" if ( -f "/bin/uname" );
  }
  my $c_platform = `$uname -s 2> $DEVNULL`;
  chomp($c_platform);
  my $c_arch = `$uname -m 2> $DEVNULL`;
  chomp($c_arch);
  my $c_p = `$uname -p 2> $DEVNULL`;
  chomp($c_p);
  my $c_prefix = "";
  
  my $len = length(pack('P', -1)); # 4 for 32, 8 for 64
  my $bits = "64";
  $bits = 32 if ( $len == 4 );

  if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_oratop"} ) {
    tfactlshare_trace(5, "tfactl (PID = $$) " . "tfactlshare get_os_prefix_oratop c_platform $c_platform", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) " . "tfactlshare get_os_prefix_oratop c_arch     $c_arch", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) " . "tfactlshare get_os_prefix_oratop c_p        $c_p", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) " . "tfactlshare get_os_prefix_oratop bits       $bits", 'y', 'y');
  }

  if ( uc($c_platform) eq "LINUX" )
  {
    $c_prefix = "LINUX.X$bits";
  }
   elsif ( uc($c_platform) eq "AIX" )
  {
    $c_prefix = "AIX.PPC64";
  }
   elsif ( uc($c_platform) eq "HP-UX" )
  {
    if ( $c_arch eq "ia64" )
    {
      $c_prefix = "HPUX.IA64";
    }
     else
    {
      $c_prefix = "HPUX.PARISC64";
    }
  }
   elsif ( uc($c_platform) eq "SUNOS" )
  {
    if ( $c_p eq "sparc" )
    {
      $c_prefix = "SOLARIS.SPARC64";
    }
     else
    {
      $c_prefix = "SOLARIS.X64";
    }
  }

  return ($c_prefix, "$c_platform $c_arch $c_p");
}

sub runOraTop
{
  my ($tfa_home, $db_name, $oflags, $out, $tcase) = @_;
  my ($ohome, $ouser, $oversion, $osid, $oratop);
  my $localhost=tolower_host();
  my $running_local = 0;
  my $db_running = 0;
  my (@running) = ();
  my %rethash = ();
  my $retcode = 1;
  my $tmpfile;
  (undef,$tmpfile) = tempfile();
  $tmpfile .="_".$$."oratop.run";

  if ( ! $db_name )
  {
    print "Error : Database name missing. Please specify database using -database option\n";
    exit 1;
  }

  # Check platform first and exit if its not supported
  my ($os_prefix, $myos) = get_os_prefix_oratop();

  if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_oratop"} ) {
    tfactlshare_trace(5, "tfactl (PID = $$) " . "tfactlshare runOraTop os_prefix $os_prefix", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) " . "tfactlshare runOraTop myos      $myos", 'y', 'y');
  }

  if ( ! $os_prefix )
  {
    print "Error: oratop is not supported on $myos\n";
    exit 1;
  }

  # Retrieve DB settings
  # --------------------
  ($retcode, %rethash) = dbutil_setOraEnv($tfa_home,$db_name,undef,FALSE);

  if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_oratop"} ) {
    tfactlshare_trace(5, "tfactl (PID = $$) " . "tfactlshare runOraTop retcode $retcode", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) " . "tfactlshare runOraTop rethash ==>", 'y', 'y');
    foreach my $key ( keys %rethash ) {
      tfactlshare_trace(5, "tfactl (PID = $$) " . "tfactlshare runOraTop key $key = " . $rethash{$key}, 'y', 'y');
    } # end foreach
  } # end if tracing oratop

  $ohome = $rethash{"ORACLE_HOME"};
  $ouser = $rethash{"TFA_ORACLE_USER"};
  $oversion = $rethash{"TFA_ORACLE_VERSION"};
  $osid = $rethash{"ORACLE_SID"};
  $db_running = $rethash{"TFA_DB_RUNNING"};
  $running_local = $rethash{"TFA_RUNNING_LOCAL"};

  if ( ! $ohome )
  {
    print "Error: Could not find oracle_home for $db_name\n";
    return 1;
  }

  # Farm called
  if ( $tcase ) {
    if ( not length $oversion ) {
      $oversion = dbutil_get_dbhome_version($ENV{"ORACLE_HOME"});
    }
    if ( length $ohome && length $ouser && length $osid &&
         $db_running && length $oversion ) {
      print "Oratop successfully tested.\n";
      print "ohome $ohome\n";
      print "ouser $ouser\n";
      print "osid $osid\n";
      print "db_running $db_running\n";
      print "running_local $running_local\n";
      print "oversion $oversion\n";
      return 0;
    } else {
      print "Oratop failed.\n";
      print "ohome $ohome\n";
      print "ouser $ouser\n";
      print "osid $osid\n";
      print "db_running $db_running\n";
      print "running_local $running_local\n";
      print "oversion $oversion\n";
      return 1;
    }
  } # end if $tcase

  if ( ! $oversion )
  {
    print "Error: Could not find version\n";
    return 1;
  }

  #oratop supports version 11.2 and above databases
  my $o_ver = 999;
  $o_ver = $1.$2 if ( $oversion =~ /^(\d+)\.(\d+)\..*/ );  
  if ( $o_ver < 112 ) {
    print "Error: oratop is only supported for database 11.2 and above\n";
    return 1;
  }

  my $oratop_pfx;
  if ( $oversion =~ /11\.2\.0\.3/ || $oversion =~ /11\.2\.0\.4/ )
  {
    $oratop_pfx = "oratop.RDBMS_11.2_$os_prefix";
  }
   elsif ( $oversion =~ /12\.1\./ )
  {
    $oratop_pfx = "oratop.RDBMS_12.1_$os_prefix";
  }
   elsif ( -f catfile($ohome, "suptools", "oratop", "oratop") )
  {
    $oratop_pfx = "";
  }
   else
  {
    print "Error: oratop is not supported on $oversion\n";
    return 1;
  }

  if ( -f catfile($ohome, "suptools", "oratop", "oratop") )
  {
    $oratop = catfile($ohome, "suptools", "oratop", "oratop");
  }
   else
  {
    $oratop = catfile($tfa_home, "ext", "oratop" , $oratop_pfx);
  }

  if ( $db_running == 0 )
  {
    print "Error: $db_name is not running.\n";
    return 1;
  }
  my $beq = 1;
  if ( $oflags =~ /\@/ && $oflags =~ /\// )
  {
    $beq = 0;
    $running_local = 1;
  }

  if ( $running_local == 1 )
  {

    my $repos = getCurrentRepository($tfa_home);
    my $oratop_outdir = catfile("$repos", "oratop");
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                localtime(time);
    $year += 1900;
    my $month = sprintf("%02d", $mon+1);
    mkdir("$oratop_outdir") if ( ! -d "$repos/oratop");
    if ( $ENV{TFA_ORATOP_OUTPUT} )
    {
      $oratop_outdir = $ENV{TFA_ORATOP_OUTPUT};
    }
    my $oratop_out = catfile($oratop_outdir, "oratop-$db_name-$year-$month-$mday-$hour-$min-$sec.out");
    if ( $oflags =~ /-d/ )
    {
      $oratop_out = "/dev/null";
    }
    if ( ! $ouser )
    {
      print "Error: Could not find owner for $db_name\n";
      return 1;
    }

    # Check if current user is root.. this command can be run by root or oracle owner
    my $runflag = "-bn1";
    if ( $oflags )
    {
      $runflag = $oflags;
    }
    my $tee_cmd = ""; # Spool only in non-interactive
    if ( $runflag =~ /b/ )
    {
      $tee_cmd = "| tee $oratop_out 2>/dev/null";
    }

    if ( $current_user eq "root" )
    {
        system ("echo '#!/bin/sh' > $tmpfile");
        system ("echo 'ORACLE_HOME=$ohome; export ORACLE_HOME; LD_LIBRARY_PATH=$ohome/lib; export LD_LIBRARY_PATH; ORACLE_SID=$osid; export ORACLE_SID;' >> $tmpfile");
        system ("chmod 755 $tmpfile");
      if ( $beq == 0 )
      {
        system ("echo '$oratop $runflag' >> $tmpfile");
        system(tfactlshare_checksu($ouser,"$tmpfile $tee_cmd"));
      }
       else
      {
        system ("echo '$oratop $runflag \"/ as sysdba\"' >> $tmpfile");
        system(tfactlshare_checksu($ouser,"$tmpfile $tee_cmd"));
      }
      unlink("$tmpfile");
    }   
     elsif ( $current_user eq $ouser )
    {
      #print "Error: Can't run oratop for $db_name as $current_user\n";
      if ( $beq == 0 )
      {
        system("ORACLE_HOME=$ohome; export ORACLE_HOME; LD_LIBRARY_PATH=$ohome/lib; export LD_LIBRARY_PATH; ORACLE_SID=$osid; export ORACLE_SID; $oratop $runflag $tee_cmd");
      }
       else
      {
        system("ORACLE_HOME=$ohome; export ORACLE_HOME; LD_LIBRARY_PATH=$ohome/lib; export LD_LIBRARY_PATH; ORACLE_SID=$osid; export ORACLE_SID; $oratop $runflag \"/ as sysdba\" $tee_cmd");
      }

    }
     else
    {
      print "Error: Can't run oratop for $db_name as $current_user\n";
      return 1;
    }
    system("rm -f $tmpfile");
  }
   elsif ( $current_user eq "root" )
  {
    print "\nRunning on $running[0] as instance is not running on localnode\n";
    if ( $oflags =~ /-d/ )
    {
      $oflags =~ s/-d//;
      print "\n";
      print "+=======================================================================================+\n";
      print "| Note: Interative mode (-d) is supported only when database instance is running on     |\n";
      print "| localnode. Oratop will run in batch mode now on remote node. If you want to invoke    |\n";
      print "| interative mode, either execute command from node where instance is running or        |\n";
      print "| specify connection information like below.                                            |\n";
      print "| tfactl analyze -comp oratop -database db -d user/password\@host[:port]/[service_name]  |\n";
      print "+=======================================================================================+\n\n";
    }
    system("$tfa_home/bin/tfactl executecommandprint $running[0] tfactloratop \"-database $db_name $oflags\""); 
  }
   else
  {
    print "\nInstance is not running on locanode. Cannot run command in remote node as non-root user \n";
    print "Either execute command from node where instance is running or specify connection information like below.|\n";
    print "tfactl analyze -comp oratop -database db -d user/password\@host[:port]/[service_name]\n";
    return 1;
  }
  system("setterm -cursor  on 2> $DEVNULL > $DEVNULL");
}

sub createTNTprop
{
  my ($tfa_home, $inv_file_tz) = @_;
  my $tnt_home = catfile($tfa_home, "ext", "tnt");
  my $tmp_conf_file = catfile($tnt_home, "conf", "$$.prop");
  my $tnt_conf_tmpl = catfile($tnt_home, "conf", "tnt.prop.tmpl");
  my $tnt_conf = catfile($tnt_home, "conf", "tnt.prop");

  my $java = catfile($tfa_home, "jre","bin","java$EXE");
  my ($inv_file, $timezone) = split(/:/, $inv_file_tz);
  if ( ! -e "$java" )
  {
    my $java_home = get_java_home ($tfa_home);
    $java = catfile($java_home,"bin","java$EXE");
  }

  if ( -r "$tnt_conf_tmpl" )
  {
    open(RF, "$tnt_conf_tmpl" );
    open(WF, ">$tmp_conf_file" );
    while (<RF>)
    {
      chomp;
      if ($IS_WINDOWS && $_ =~ /tnt.script.classpath=/) {
      	s/:/;/g;
      }
      
      s/\%TNT_HOME\%/$tnt_home/g;
      s/\%JAVAEXE\%/$java/g;
      print WF "$_\n";
    }
    close(RF);
    #Add CRS logs
    #Add DB logs
    #Add ASM logs
    my %ftype = ();
    my $file = "";
    my $allcnt = 1;
    my $oswtop = "";
    my $oswslabinfo = "";
    print WF "all.title=Analysis of Alert,System Logs\n";
    if ( -r "$inv_file")
    {
      open(RF, "$inv_file");
      while(<RF>)
      {
        chomp;
        if ( /<file_name>(.*\/oswslabinfo)\/.*\.dat.*<\/file_name>/ ||
             /<file_name>(.*\/Slabinfo.ExaWatcher)\/.*\.dat.*<\/file_name>/)
        {
          $oswslabinfo = $1;
        }
        elsif ( /<file_name>(.*\/oswtop)\/.*\.dat.*<\/file_name>/ ||
                /<file_name>(.*\/Top.ExaWatcher)\/.*\.dat.*<\/file_name>/)
        {
          $oswtop = $1;
        }
        elsif ( /<file_name>(.*)<\/file_name>/ )
        {
          $file = $1;
        }
         elsif ( /file_type>System Messages Log</ )
        {
          if ( ! defined $ftype{OS} )
          {
            $ftype{OS} = 0;
            print WF "os.title=System Messages Log\n";
          }
          if ( ! defined $ftype{ACFS} )
          {
            $ftype{ACFS} = 0;
            print WF "acfs.title=ACFS Messages Log\n";
          }
          $ftype{OS}++;
          $ftype{ACFS}++;

          my $cnt = $ftype{OS};
          my $dir = dirname($file);
          my $fn = basename($file);
          print WF "os.$cnt.fileset.dir=$dir\n";
          print WF "os.$cnt.fileset.filename=$fn\n";
          print WF "os.$cnt.fileset.type=oracle.rat.tfa.tnt.parsers.UnixSystemLogParser\n";
          print WF "os.$cnt.fileset.timezone=$timezone\n" if ( $timezone );

          print WF "acfs.$cnt.fileset.dir=$dir\n";
          print WF "acfs.$cnt.fileset.filename=$fn\n";
          print WF "acfs.$cnt.fileset.type=oracle.rat.tfa.tnt.parsers.ACFSLogParser\n";
          print WF "acfs.$cnt.fileset.timezone=$timezone\n" if ( $timezone );

          print WF "all.$allcnt.fileset.dir=$dir\n";
          print WF "all.$allcnt.fileset.filename=$fn\n";
          print WF "all.$allcnt.fileset.type=oracle.rat.tfa.tnt.parsers.UnixSystemLogParser\n";
          print WF "all.$allcnt.fileset.timezone=$timezone\n" if ( $timezone );
          $allcnt++;
        }
         elsif ( /file_type>CRS Alert Log</ )
        {
          if ( ! defined $ftype{CRS} )
          {
            $ftype{CRS} = 0;
            print WF "crs.title=CRS Alert Logs\n";
          }
          $ftype{CRS}++;
          my $cnt = $ftype{CRS};
          my $dir = dirname($file);
          my $fn = basename($file);
          print WF "crs.$cnt.fileset.dir=$dir\n";
          print WF "crs.$cnt.fileset.filename=$fn\n";
          print WF "crs.$cnt.fileset.type=oracle.rat.tfa.tnt.parsers.CRSAlertLogParser\n";
          print WF "crs.$cnt.fileset.timezone=$timezone\n" if ( $timezone );
          print WF "all.$allcnt.fileset.dir=$dir\n";
          print WF "all.$allcnt.fileset.filename=$fn\n";
          print WF "all.$allcnt.fileset.type=oracle.rat.tfa.tnt.parsers.CRSAlertLogParser\n";
          print WF "all.$allcnt.fileset.timezone=$timezone\n" if ( $timezone );
          $allcnt++;
        }
         elsif ( /file_type>Alert Log - (DB)</ || /file_type>Alert Log - (ASM)</ || /file_type>Alert Log - (ASMIO)</ || /file_type>Alert Log - (ASMPROXY)</)
        {
          my $ftype = $1;
          my $ad = lc($1);
          if ( ! defined $ftype{$ad} )
          {
            $ftype{$ad} = 0;
            print WF "$ad.title=$ftype Alert Logs\n";
          }     
          $ftype{$ad}++;
          my $cnt = $ftype{$ad};
          my $dir = dirname($file);
          my $fn = basename($file);
          print WF "$ad.$cnt.fileset.dir=$dir\n";
          print WF "$ad.$cnt.fileset.filename=$fn\n";
          print WF "$ad.$cnt.fileset.type=oracle.rat.tfa.tnt.parsers.DBAlertLogParser\n";
          print WF "$ad.$cnt.fileset.timezone=$timezone\n" if ( $timezone );
          print WF "all.$allcnt.fileset.dir=$dir\n";
          print WF "all.$allcnt.fileset.filename=$fn\n";
          print WF "all.$allcnt.fileset.type=oracle.rat.tfa.tnt.parsers.DBAlertLogParser\n";
          print WF "all.$allcnt.fileset.timezone=$timezone\n" if ( $timezone );
          $allcnt++;
        }
      }
      if ( ! $oswtop )
      { # Add oswbb started by TFA
        my $tfa_base = tfactlshare_get_repository_location($tfa_home);
        my $tool_dir = catfile($tfa_base, "suptools", "$hostname", "oswbb");
        if ( -d "$tool_dir" )
        {
          my @dirs = `find $tool_dir -name "archive" -type d`;
          chomp(@dirs);
          if ( $dirs[0] )
          {
            $oswtop = "$dirs[0]/oswtop" if ( -d "$dirs[0]/oswtop" );
            $oswslabinfo = "$dirs[0]/oswslabinfo" if ( -d "$dirs[0]/oswslabinfo" );
          }
        }
      }
      if ( $oswtop )
      {
        print WF "osw.title=OSW top logs\n";
        print WF "osw.1.fileset.dir=$oswtop\n";
        print WF "osw.1.fileset.filename=*.dat*\n";
        print WF "osw.1.fileset.subdirlevel=1\n";
        print WF "osw.1.fileset.type=OSW\n";
        print WF "osw.1.fileset.timezone=$timezone\n" if ( $timezone );
      }
      if ( $oswslabinfo )
      {
        print WF "oswslabinfo.title=OSW slabinfo logs\n";
        print WF "oswslabinfo.1.fileset.dir=$oswslabinfo\n";
        print WF "oswslabinfo.1.fileset.filename=*.dat*\n";
        print WF "oswslabinfo.1.fileset.subdirlevel=1\n";
        print WF "oswslabinfo.1.fileset.type=OSW\n";
        print WF "oswslabinfo.1.fileset.timezone=$timezone\n" if ( $timezone );
      }
      close(RF);
    }
    close(WF);
    unlink($tnt_conf) if ( -e "$tnt_conf" );
    rename($tmp_conf_file, $tnt_conf);
  }
  
}

sub copyTagFile {
	my $tfa_home = shift;
	my $tag = shift;
	my $remotenode = shift;
	my $localhost = tolower_host();

	my $actionmessage = "$localhost:copytagfile:$tag:$remotenode";
	my $command = buildCLIJava($tfa_home,$actionmessage);

	my $line;
        my @cli_output = tfactlshare_runClient($command);
	foreach $line ( @cli_output ) {
		if ($line eq "DONE") {
			return SUCCESS;
		}
	}
	return FAILED;	
}

# Subroutine to get Owner of Symlink File

sub getSymlinkOwner {
	my $file = shift;
	my $owner;

	if ( -l $file && !$IS_WINDOWS) {
		$owner = qx(ls -l $file | awk '{print \$3}');
		$owner = trim($owner);
	} else {
		$owner = getFileOwner($file);
	}
	return $owner;
}

# Subroutine to get Owner of file or directory

sub getFileOwner {

	my $file = shift;

	my $ownerid = (stat $file)[4];
	my $owner;
        if ($IS_WINDOWS)
        {
          $owner = tfactlshare_get_user($ownerid);
        } 
         else 
        { 
          $owner = (getpwuid $ownerid)[0]; 
        } 

	return $owner;
}

#
#
#==== addDirectory  ====#
#
sub addDirectory
{
  #my ($tfa_home, $directory, $dbname, $instance_name) = @_;
  my ($tfa_home, $directory, $private_directory, $exclusion, $collect_all, $nodelist) = @_;
  if (isTFARunning($tfa_home) == FAILED) {
	exit 0;
  }
  dbg(DBG_WHAT, "In addDirectory for :: $directory\n");

  my $userdir = $directory;

  $directory = abs_path($directory);

  if ( -d $directory ) {
        dbg(DBG_VERB, "$directory directory exists.\n");
  }
  elsif ( -e $directory ) {
        print "$directory is a file. Enter a valid directory location.\n";
        return FAILED;
  }
  else {
        print "$directory does not exist. Failed to add directory to TFA.\n";
        return FAILED;
  }
  if ( $directory =~ /^\/$/ || $directory =~ /^\/tmp/
        || $directory =~ /^\/bin/ || $directory =~ /^\/boot/ || $directory =~ /^\/dev/
        || $directory =~ /^\/lib/ || $directory =~ /^\/lib64/ || $directory =~ /^\/media/
        || $directory =~ /^\/misc/ || $directory =~ /^\/root/
        || $directory =~ /^\/proc/ || $directory =~ /^\/sbin/ || $directory =~ /^\/srv/ || $directory =~ /^\/selinux/
        || ($directory =~ /^\/var/ && $directory !~ /^\/var\/log/ && $directory !~ /^\/var\/opt/ && $directory !~ /^\/var\/adm/ && $directory !~ /^\/var\/adm\/syslog/ && $directory !~ /^\/var\/opt\/oracle/)
        || ($directory =~ /^\/etc/ && $directory !~ /^\/etc\/oracle/)
	|| $directory =~ /^\/usr$/ || $directory =~ /^\/usr\/bin$/ || $directory =~ /^\/usr\/sbin$/ || $directory =~ /^\/usr\/local$/ || $directory =~ /^\/usr\/local\/bin$/
        ) {
        print "\n$directory is not valid directory to add to TFA\n";
        return FAILED;
   }

  # checking validity of nodes
  $nodelist =~ tr/A-Z/a-z/;
  my @nodelist = split(/\,/,$nodelist);
  my $nodename;
  foreach $nodename (@nodelist) {
     if (isNodePartOfCluster($tfa_home, $nodename)) {
     }
     else {
         print "Node $nodename is not part of TFA cluster\n";
         exit 0;
     }
  }
  my $has_permission = 0;
  my $sudo_user = $ENV{SUDO_USER};
  my $sudo_uid = $ENV{SUDO_UID};
  my $sudo_gid = $ENV{SUDO_GID};
  my $sudo_command = $ENV{SUDO_COMMAND};
  my $owner_gid;
  my $owner_uid;
  my $groups;
  my $users;

  $directory = abs_path($userdir);

  my $dirowner = getFileOwner($directory);

  if ( $directory =~ /^\/net/ || $directory =~ /^\/opt/ ) {
        if ( $dirowner eq "root" ) {
        	print "\n$directory not valid directory to add to TFA as its owned by root\n";
	        return FAILED;
	}
  } 

  if ( $sudo_user && $sudo_command =~ /tfactl/ ) {
        print "Running as sudo user : $sudo_user\n";
        print "Checking if $sudo_user is the owner of $directory...\n";

	if ( $dirowner eq $sudo_user ) {
		$has_permission = 1;
	} else {
		print "User '$sudo_user' does not have permission to add the directory : $directory\n";
	}

#        my $mode = sprintf '%04o', (stat $directory)[2] & 07777;
#        print "Directory permissions are : $mode\n";
#        $owner_uid = (stat($directory))[4];
#        $owner_gid = (stat($directory))[5];
#        my @permissions = split("", $mode);
#        my $others = @permissions[3];
#        $groups = @permissions[2];
#        $users = @permissions[1];
#        if ($others >= 4) {
#          print "Everyone has read permission\n";
#          $has_permission = 1;
#        }
#        elsif ($groups >= 4) {
#          my $member;
#          foreach $member (split (/ /,(getgrgid $owner_gid)[3])){
#             #print "$member\n";
#             if($sudo_user eq $member){
#                 print "$sudo_user has read permission\n";
#                 $has_permission = 1;
#                 last;
#             }
#          }
#        }
#	elsif ($users >= 4) {
#          if ($owner_uid == $sudo_uid) {
#            print "$sudo_user has read permission\n";
#            $has_permission = 1;
#          }
#        }
  }
  elsif (  $current_user ne "root" ) {
        if ( $dirowner eq $current_user ) {
                $has_permission = 1;
        } else {
                print "User '$current_user' does not have permission to add the directory : $directory\n";
        }
  }
  else {
        $has_permission = 1;
  }

  if ($has_permission == 0) {

#        print "User $sudo_user does not have permission to add the directory : $directory\n";
#	if ($groups >= 4) {
#           my $owner_gname = (getgrgid $owner_gid)[0];
#           print "Only this group has read permission - ";
#           print "Group Id : $owner_gid | Group Name : $owner_gname\n";
#        }
#        elsif ($users >= 4) {
#           my $owner_uname = (getpwuid $owner_uid)[0];
#           print "Only this user has read permission - ";
#	   print "User Id : $owner_uid | User Name : $owner_uname\n";
#        }

        print "Failed to add directory $directory\n";
        return FAILED;
  }
  $directory = $userdir;
  my $localhost=tolower_host();
  my $actionmessage = "$localhost:adddirectory:$directory";
  if ($private_directory == 1) {
    $actionmessage = "$localhost:adddirectory:$directory:-private";
  }
  if (defined($exclusion)) {
	$actionmessage .= ":$exclusion";
  }
  if ($collect_all == 1) {
	$actionmessage .= ":-collectall";
  }
  if (defined($nodelist) && !($nodelist eq "")) {
        $actionmessage .= ":-node $nodelist";
  }
  if ($sudo_user && $sudo_command =~ /tfactl/) {
    $actionmessage .= ":-owner $sudo_user";
  } elsif ( $current_user ne "root" ) {
    $actionmessage .= ":-owner $current_user";
  }

  my $run_cmd = 1;
  my $run_cnt = 0; # Avoid infinite loop
  my $dbname;
  my $instance_name;
  my $comp;
  my %component_selection = ();

  while ( $run_cmd == 1 && $run_cnt < 2)
  { # Run again after user input
    $run_cnt++;
    #print "run_cmd $run_cmd\n";
    #print "run_cnt $run_cnt\n";
    $actionmessage .= ":-d $dbname" if ( defined $dbname );
    $actionmessage .= ":-i $instance_name" if ( defined $instance_name );
    $actionmessage .= ":-r $comp" if ( defined $comp );
    dbg(DBG_WHAT, "Running addHost through Java CLI\n");
    my $command = buildCLIJava($tfa_home,$actionmessage);
    dbg(DBG_WHAT, "$command\n");
    my $line;
    my @cli_output = tfactlshare_runClient($command);
    foreach $line ( @cli_output )
    {
      #print "$line\n";
      if ( $line eq "SUCCESS") 
      {
        print "Successfully added directory to TFA\n";
	#printLocalDirectories($tfa_home);
        dbg(DBG_WHAT,"#### Added Directory ####\n");
        return SUCCESS;
      }
      elsif ($line =~ /FAILED : Directory is already present in TFA/) {
	print "No new directories were added to TFA\n";
        #printLocalDirectories($tfa_home);
	return SUCCESS;
      }
      elsif ($line =~ /No directories were added to TFA/) {
	print "No new directories were added to TFA\n";
        #printLocalDirectories($tfa_home);
	return SUCCESS;
      }
      elsif ($line =~ /FAILED. Unable to determine component/) {
  	 my $tfa_components;
         if(isODADom0() == 1){
           $tfa_components = "ODA|OS|IPS";
         } elsif (isODA() == 1) {
           $tfa_components = "ODA|RDBMS|CRS|ASM|INSTALL|OS|CFGTOOLS|TNS|DBWLM|ACFS|IPS"
         } else {
           $tfa_components = "RDBMS|CRS|ASM|INSTALL|OS|CFGTOOLS|TNS|DBWLM|ACFS|IPS";
         }
         #my @tfa_components = split(/\|/, $tfa_components);
	 print "Unable to determine component for directory: $directory\n\n";
         my $more = "Y";
         while($more =~ /^[Yy]/){
	 my ($database, $instance);
         print "Please choose a component for this Directory [$tfa_components] : ";
         $more = "N"; 
         my $input = <STDIN>;
         chomp($input);
	 $input = get_valid_input ($input, $tfa_components, "CRS");
	 if( ! exists($component_selection{$input} ) ){
	 	$component_selection{$input} = 1;

	 	$comp .= ",$input";
	 if ( $input eq "RDBMS" )
	 { # We need database and instance names
           print "Please enter database name for this Directory :";
           while ( ! $database )
   	   {
	     $database = <STDIN>;
	     chomp($database);
             $comp .= "%database-$database";
	   }
	   print "Please enter instance name for this Directory :";
	   while ( ! $instance )
	   {
	     $instance = <STDIN>;
	     chomp($instance);
             $comp .= "%instance-$instance";
	   }
	 }
	 if ( $input eq "ASM" )
	 { # We need instance name
	   print "Please enter instance name for this Directory :";
	   while ( ! $instance )
	   {
	     $instance = <STDIN>;
	     chomp($instance);
             $comp .= "%instance-$instance";
	   }
	 }
         if ($database) {
		$dbname = $database;
	 } 

	 if ($instance)  {
		$instance_name = $instance;
	 }

	 }else{
	 	print "'$input' has been already added as a component.\n\n";
	 }
	 
         
       #print "comp $comp\n";
       print "Do you wish to assign more components to this Directory ? [Y/y/N/n] [N] ";
              chomp ( $more = <STDIN> );
              $more ||= "N";
              $more = get_valid_input ($more, "Y|y|N|n", "N");
	}
      }
      elsif ($line eq "FAILED") {
	return FAILED;
      }
      else
      { # Stop loop
	print "$line\n";
        $run_cmd = 0;
      }
    } # End of foreach
  } # End of while $run_cmd == 1 

  dbg(DBG_WHAT,"Could not add directory\n");
  return FAILED;
}

sub getTFADirectories
{
my ($tfa_home,$hostname) = @_;
dbg(DBG_VERB, "In getTFADirectories\n");
my $localhost=tolower_host();

dbg(DBG_VERB, "Running getTFADirectories through Java CLI\n");
my $message ="$localhost:printdirectories";
my $command = buildCLIJava($tfa_home,$message);
dbg(DBG_VERB, "$command\n");
my $line;
my @tfadirs;
my @cli_output = tfactlshare_runClient($command);
foreach $line ( @cli_output )
{
if ( $line eq "DONE") {
        return @tfadirs;
}
else {
  if ($line =~ /Connection refused/) {
  }
  else {
    my ($dirpath, $host, $databasename, $instancename) = split(/!/, $line);
    if ($hostname eq $host) {
      push(@tfadirs, $dirpath);
    }
  }
}
}
return @tfadirs;
}

sub printLocalDirectories
{
my $tfa_home = shift;
dbg(DBG_VERB, "In printDirectories\n");
my $localhost=tolower_host();
dbg(DBG_VERB, "Running printDirectories through Java CLI\n");
my $message ="$localhost:printdirectories";
my $command = buildCLIJava($tfa_home,$message);
dbg(DBG_VERB, "$command\n");
my $line;
my $tb = Text::ASCIITable->new();
$tb->setCols("Trace Directory", "Component", "Permission", "Added By");
$tb->setColWidth("Trace Directory", $tputcols-45);
$tb->setOptions({"outputWidth" => $tputcols});
$Text::Wrap::columns = $tputcols-45;
my @cli_output = tfactlshare_runClient($command);
foreach $line ( @cli_output )
{
if ( $line eq "DONE") {
        print $tb;
        dbg(DBG_WHAT,"#### All Stored Scan Directories Printed ####\n");
        return SUCCESS;
}
else {
  if ($line =~ /Connection refused/) {
  }
  else {
    my ($dirpath, $hostname, $component, $permission, $owner, $collectionpolicy, $collectall) = split(/!/, $line);
    if ($hostname eq $localhost) {
        $tb->addRow(wrap("","",$dirpath), $component, $permission, $owner);
      #$tb->addRow("Permission: $permission","","");
      #$tb->addRow("Added By: $owner","","");
      if ($collectionpolicy eq "exclusions") {
        $tb->addRow("Collection policy : Exclusions");
      }
      elsif ($collectionpolicy eq "noexclusions") { 
        $tb->addRow("Collection policy : No Exclusions");
      }
      elsif ($collectionpolicy eq "collectall") {
        $tb->addRow("Collection policy : Collect All");
      }
      #$tb->addRow("Collect All : $collectall");
      $tb->addRowLine();
    }
  }
}
}

dbg(DBG_NOTE,"Could not print stored directories\n");
return FAILED;
}

sub printReDiscoveryStats
{
my $tfa_home = shift;
my $localhost=tolower_host();
my $message ="$localhost:lastrediscoveryrun";
my $command = buildCLIJava($tfa_home,$message);

my $line;
my @cli_output = tfactlshare_runClient($command);
foreach $line ( @cli_output )
{
  if ($line eq "DONE") {
	return SUCCESS;
  }
  else {
    print "Last Rediscovery Run on $localhost : $line\n";
  }
}
return FAILED;
}

#======================= socketConnect ==================#
sub sockConnect
{
my $localhost=tolower_host();
dbg( DBG_WHAT , "In Socket Connect for $localhost at port $PORT\n");
my $sock = new IO::Socket::INET ( 
 PeerAddr =>  $localhost,
 PeerPort => $PORT, 
 Proto => 'tcp', 
 ); 
if (!$sock) {
    dbg(DBG_NOTE,  "Unable to connect to Socket $PORT &!\n"); 
    return CONNFAIL; }
return $sock;
}

#========== dbg 
# 
# print debug info
#
#==========
sub dbg
{
    my ($level, $line) = @_;
    if( $level & $DEBUG) {
        print "$line";
    }
    if ( $instlog && -f $instlog ) {
       my $datestring = strftime "%Y-%m-%d %H:%M:%S", localtime;
       if ( $line =~ /^\n/ ) {
           print $instlog "\n";
           $line =~ s/^\n//;
       }
       print $instlog "[" . $datestring ."] " . "$line";
    }
    
}

# Execute a command on the local host

sub host
{
    $cmd_host = shift;
    my $output_type = shift;
    dbg( DBG_HOST, "EXE: $cmd_host\n");
    my $last;
    my $output_flag;
    $output_flag = '2>&1' if($output_type eq 'OUTPUT_REDIRECT');
    $output_flag = '2>' if($output_type ne 'OUTPUT_REDIRECT');
    
    my @cmd_result = qx($cmd_host $output_flag $DEVNULL);
    my $last = $?;
    foreach my $l (@cmd_result) {
        chomp( $l);
        dbg( DBG_HOST, "...: $l\n");
    }
    dbg( DBG_HOST, "RET: $last\n");
    return \@cmd_result,$last if($output_type eq 'OUTPUT_REDIRECT');
    return $last if($output_type ne 'OUTPUT_REDIRECT');
}


########
# NAME
#   copy_remote
#
# DESCRIPTION
#   Copies the contents of a folder in localhost to a location in remotehost.
#
# PARAMETERS
#	$node        (IN) - remote node name
#	$from        (IN) - localnode folder location
#	$to          (IN) - Folder location in remote node to which the file shall be transferred
#
# RETURNS
#
# NOTES/USAGE
#	Works for both windows and linux.
#
########
sub copy_remote
{
    my ($node,$from,$to,$temp_dir) = @_;
    my $cmd;
    dbg( DBG_WHAT, "Distributing $from to node '$node'\n");
    #if we are on the local host we don't need remote access
    if ($IS_WINDOWS) {
    	if( $localhost =~ /$node/ ) {
	        tfactlwin_robocopy(catfile($from), catfile($to));
	    }
	    else {
	    	if (-f $from){
	    		mkpath($temp_dir);
			tfactlwin_robocopy(catfile($from), catfile($temp_dir));
			tfactlwin_remote_win_copy_without_cred($localhost,catfile($temp_dir),$node,catfile($to));
			rmtree($temp_dir);
	    	} elsif (-d $from){
			tfactlwin_remote_win_copy_without_cred($localhost,catfile($from),$node,catfile($to));
		}
	    }
	    return;
    } else {
       if( $localhost =~ /$node/ ) {
        $cmd = "$CP $from \"$to\"";
       }
       else {
    	$cmd = "$SCP -p $from $node:\"$to\"";
       }
       return host( $cmd);
    }
}
sub check_node
{
    my $node = shift;
    my $pingcommand;

    dbg( DBG_WHAT, "Checking node access '$node'\n");
    if ( $osname eq "HP-UX" ) {
       $pingcommand = "ping $node $pingflag 1"}
    else {
       $pingcommand = "ping $pingflag 1 $node"}

    if( host( $pingcommand ) ne 0) {
        fatal( "Node '$node' not reachable.");
    }
}
sub check_login
{
    my $node = shift;

    dbg( DBG_WHAT, "Checking node login '$node'\n");
    if( host( "$SSH -o NumberOfPasswordPrompts=0 $node pwd") ne 0) {
        dbg( DBG_WHAT, "SSH failed to $node : Please set up SSH and try again\n");
        fatal( "Failed to login to node '$node'");
    }
}
# Create a directory path on a node. 
sub mkdir_path
{
    my ($node,$dir) = @_;

    if ( $IS_WINDOWS ){
      tfactlwin_ssh_without_cred($node, "cmd /c $MKDIR $dir");
    }else{
      my @subs = split( /[\\\/]/, $dir);
      my $path = '';
      dbg( DBG_WHAT, "Checking/Creating Directory $dir for binary on node '$node'\n");
      foreach my $p ( @subs ) {
          if( $p ne '') {
              $path = $path . $FSEP . $p;
              if( host_remote( $node, "$LS -d $path") != 0) {
                  dbg( DBG_VERB, "$MKDIR '$path' on '$node'\n");
                  if( host_remote( $node, "$MKDIR $path")) {
                      fatal( "Failed to make path '$path' on '$node'");
                  }
              }
              else {
                  dbg( DBG_VERB, "'$path' on '$node' exists\n");
              }
          }
      }
    }
}

# Execute a command on a remote host. If the host specified is the local node
# execute local instead

sub host_remote
{
    my $host = shift;
    $cmd_host = shift;
    my $localhost = shift;
    my $output_type = shift;

    $localhost = tolower_host() if(!defined $localhost);
    dbg( DBG_HOST, "Localhost:$localhost\n");
    dbg( DBG_HOST, "Host:$host\n");

    if ($IS_WINDOWS) { # Windows
      return host( "cmd /c $cmd_host",$output_type) if( $localhost eq lc($host) );  # Local
      return tfactlwin_ssh_without_cred($host, "cmd /c $cmd_host ",$localhost,$output_type); # Remote
    } else {           # Non Windows 
      return host( $cmd_host,$output_type) if( $localhost eq lc($host) );  # Local
      return host_force_remote( $host, $cmd_host,$output_type); # Remote 
    }
}

# Execute a command on a remote host.

sub host_force_remote
{
    my $host = shift;
    $cmd_host = shift;
    my $output_type = shift;
    my $last;
    my $output_flag; 
    $output_flag = '2>&1' if ($output_type eq 'OUTPUT_REDIRECT');
    $output_flag = '2>' if ($output_type ne 'OUTPUT_REDIRECT');
    dbg( DBG_HOST, "EXE ($host): $cmd_host\n");
    my @cmd_result = qx($SSH $host '$cmd_host; echo \$\?' $output_flag  $DEVNULL);
    foreach my $l (@cmd_result) {
        chomp( $l);
        dbg( DBG_HOST, "...: $l\n");
        $l =~ s/ $DEVNULL//g if($output_type eq 'OUTPUT_REDIRECT');
        $last = trim($l);
    }
    dbg( DBG_HOST, "RET: $last\n");
    return \@cmd_result,$last if($output_type eq 'OUTPUT_REDIRECT');
    return $last if($output_type ne 'OUTPUT_REDIRECT');
}

#==========
#Print fatal error and die
#==========
sub fatal
{
    my $line = shift;

    if( $cmd_host ne "") {
        print "\nResult of last host command:\n";
        print "EXE: $cmd_host\n";
        foreach my $l (@cmd_result) {
            chomp( $l);
            print "...: $l\n";
        }
    }
    die "FATAL: $line\n";
}

#========== deployTFA
#
sub deployTFA
{
 my ($tfa_base,$local_tfa_home,$node) = @_;

 my $base_dir = $tfa_base;

 if ( ! $IS_ODA && ! $IS_ODADom0 && ! $IS_EXADATADom0 ) {
   $base_dir =~ s/$node//i;
 }
 my $tfa_home = catfile($tfa_base,"tfa_home");
 my $create_dir = $tfa_home;  
 
 #my $tfaarchive_fq = "$tfa_home/$tfaarchive";
 my $tfaarchive_fq = catfile($local_tfa_home,$tfaarchive);
 my $tfaarchive_fqr = catfile($tfa_base,$tfaarchive);
 dbg( DBG_WHAT, "Create Dir is $tfa_base \n");
 # First run some checks and create the directory..
 chomp($node);
 if( ! $localhost =~ /$node/ ) {
   check_node($node);
   check_login($node);
 }
 
 if ( ! $IS_ODA && ! $IS_ODADom0 && ! $IS_EXADATADom0 ) {
    my $bin_dir = catdir($base_dir, "bin");
    my $rep_dir = catdir($base_dir, "repository"); 
    mkdir_path($node, $bin_dir);
    mkdir_path($node, $rep_dir);
 }

 mkdir_path($node, catfile($tfa_base));
 if ($IS_WINDOWS) {
 	my $tfahome_build = $ENV{tfahome_build};
 	#print "TFA_HOME BUILD: $tfahome_build\n";
 	my $tfahome_folder = catfile($tfahome_build, "tfa_home");
	tfactlwin_remote_win_copy_without_cred($localhost,$tfahome_folder,$node,catfile($tfa_home));
 } else {   
	copy_remote($node,$tfaarchive_fq,$tfa_base);
	host_remote($node,"cd $tfa_base; $TAR xfo $tfaarchive_fqr");
 }

 # Change the permission for TFA_HOME to 750 on remote node
 host_remote($node, "cd $tfa_base; chmod -R 750 tfa_home");
 
 # Create .<node>.shared under TFA_HOME on Remote Nodes
 my $TFAHOME_SHARED = catfile($tfa_home, ".$node.shared");
 if ($IS_WINDOWS) {
	tfactlwin_ssh_without_cred($node, "cmd /c copy NUL $TFAHOME_SHARED");
 } else {   
	host_remote($node, "$TOUCH $TFAHOME_SHARED");
 }
 
 # if GI_HOME install then move the database and log directories to 
 # ORACLE_BASE/<hostName>/tfa
 if ( $INSTALL_TYPE eq "GI") {
       if (defined  $ORACLE_BASE) {
 	 my $db_dir = catfile($ORACLE_BASE, "tfa", $node, "database", "BERKELEY_JE_DB");
	 dbg(DBG_WHAT,"Creating database directory : $db_dir on $node\n");
	 mkdir_path($node, $db_dir);
         my $log_dir = catfile($ORACLE_BASE, "tfa", $node, "log");
	 dbg(DBG_WHAT,"Creating log directory : $log_dir on $node\n");
	 mkdir_path($node, $log_dir);

	 my $output_dir = catfile($ORACLE_BASE, "tfa", $node, "output");
	 dbg(DBG_WHAT,"Creating Output directory : $output_dir on $node\n");
	 mkdir_path($node, $output_dir);
	
	 my $dbzip_dir = catfile($output_dir, "dbzip");
	 mkdir_path($node, $dbzip_dir);
	
	 my $inventory_dir = catfile($output_dir, "inventory");
	 mkdir_path($node, $inventory_dir);
	
	 my $tracefiles_dir = catfile($output_dir, "tracefiles");
 	 mkdir_path($node, $tracefiles_dir);

	 #create .<node>.shared under <ORACLE_BASE>/tfa for GI Install on Remote Nodes
	 my $SHARED_FILE = catfile($ORACLE_BASE,"tfa",".$node.shared");
	 host_remote($node, "$TOUCH $SHARED_FILE");

       }
 }
}

sub removeSSH
{
  my $tfa_home = shift;
  dbg(DBG_WHAT,"Removing SSH if it was added by this process\n");
  if ( -e "$BASH" ) { # Need to check this as .pl should not do ssh 
    if ( -f "tfa_ssh_nodes" )
    { # if nodes had equivelency, we wont have tfa_ssh_nodes
      my $pid = fork ();
      if ($pid == 0) {
        exec("bash $tfa_home/bin/discover_ora_stack.sh -deleteSSH");
      } else {
        waitpid($pid,0);
      }
    }
    system("rm -f tfa_ssh_nodes tfa_ssh_nodes.saved");
  }
}

# Read inventory xml file for oracle_home's and add new homes to tfa_setup.txt
sub read_inv_and_update_tfa_setup 
{
  my $tfa_home = shift;
  my $tfasetup = catfile($tfa_home, "tfa_setup.txt");

  if ( $ISCLOUD ) {
	my $homedir = getHomeDirectory();
	$homedir = catfile($homedir, ".tfa");
	if ( -f catfile($homedir, "tfa_setup.txt") ) {
		$tfasetup = catfile($homedir, "tfa_setup.txt" );
	}
  }

  my %home_dirs = ();
  my @ohomes = ();
  if ( -f "$tfasetup" )
  {
    open(RF, "$tfasetup");
    while(<RF>)
    {
      chomp;
      if ( /^CRS_HOME=(.*)/ )
      {
        my $home = $1;
        $home_dirs{$home} = 1 if ( $home );
      }
       elsif (/^RDBMS_ORACLE_HOME=(.*?)\|/ )
      {
        my $home = $1;
        $home_dirs{$home} = 1 if ( $home );
      }
    }
    close(RF);
  }

  if($IS_WINDOWS){
  	my $result = tfactlwin_query_registry("ORACLE_HOME");
  	my @lines = split(/\n/,$result);
  	my $CRS_HOME = get_crs_home($tfa_home);
	my $ORA_HOME;
  	foreach my $line (@lines){
		my @tokens = split(/\s+/,$line);
		my $tokenArrLength = scalar @tokens;
		if($tokenArrLength>=4){
			$ORA_HOME=trim($tokens[3]);
		}
		if(-e catfile($ORA_HOME,"bin","oracle.exe") && (lc($CRS_HOME) ne lc($ORA_HOME))){
			push(@ohomes,$ORA_HOME);
		}
	}
  }else{
	if ( -e "/etc/oraInst.loc" )
	{
		@ohomes = read_ohomes_in_inv ("/etc/oraInst.loc");
	}
	if ( -e "/var/opt/oracle/oraInst.loc" )
	{
		@ohomes = read_ohomes_in_inv ("/var/opt/oracle/oraInst.loc");
	} 
  }

  my $ohome;
  my $flag = 0;
  foreach $ohome (@ohomes)
  {
    if ( ! exists $home_dirs{$ohome} )
    {
      if ( ! $flag )
      {
        $flag = 1;
        open(WF, ">>$tfasetup");
      }
      print WF "RDBMS_ORACLE_HOME=$ohome||\n";
      print "Found new ORACLE_HOME $ohome\n";
      my $adrbase = tfactlshare_get_adrbase($ohome);
      if ( $adrbase ne "invalid" ) {
        print WF "localnode\%ADRBASE=$adrbase\n";
      }
    }
  }
  close(WF) if ( $flag);
}

# Get all homes in inventory.xml
# If <home>/bin/oracle exists and <home>/bin/crsd does not exists then its a  database home

sub read_ohomes_in_inv
{
  my $inst_file = shift;
  my $inv_loc = "";
  my @ohomes = ();

  if ($IS_WINDOWS) {
  	$inv_loc = catfile($inst_file, "ContentsXML", "inventory.xml");
  } else {
	  open (RF, $inst_file);
	  while(<RF>)
	  {
	    chomp;
	    if ( /^inventory_loc=(.*)$/ )
	    {
	      $inv_loc = catfile($1, "ContentsXML", "inventory.xml");
	    }
	  }
	  close(RF);
  }

  if ( $inv_loc && -e "$inv_loc" )
  {
    open(RF, "$inv_loc");
    while(<RF>)
    {
      chomp;
      if ( /\<HOME NAME=\"[^\"]+\" LOC=\"([^\"]+)\"/ )
      {
        my $ohome = $1;
        my $obin;
		my $cbin;
		if ($IS_WINDOWS) {
			$obin = catfile($ohome, "bin", "oracle.exe"); # ORACLE_HOME
        	$cbin = catfile($ohome, "bin", "crsd.exe"); # CRS_HOME
		} else {
        	$obin = catfile($ohome, "bin", "oracle"); # ORACLE_HOME
        	$cbin = catfile($ohome, "bin", "crsd"); # CRS_HOME
        }
        if ( -d "$ohome" && -e "$obin" && ! -e $cbin )
        {
          @ohomes = (@ohomes, $ohome);
        }
      }
    }
    close(RF);
  }
  return @ohomes;
}

sub get_trc_dirs
{
  my $dir = shift;
  my $comp = shift;
  my $tidir = shift;
  my @dirs = ();
  my @trcdirs = ();
#print "Checking $dir\n";
  # check if $dir/*/*/trace exists and add to array
  opendir ( DIR, $dir ) || return;
  while( (my $filename = readdir(DIR)))
  {
    next if ( $filename eq "." || $filename eq ".." );
    push (@dirs, catfile($dir,$filename)) if ( -d catfile($dir,$filename) );
  }
  closedir(DIR);

  my @idirs = ();
  if ( $comp eq "CRS" )
  {
    @idirs = @dirs;
  }
  else
  {
    foreach my $idir (@dirs)
    {
      opendir ( DIR, $idir ) || return;
      while( (my $filename = readdir(DIR)))
      {
        next if ( $filename eq "." || $filename eq ".." );
        push (@idirs, catfile($idir,$filename)) if ( -d catfile($idir,$filename) );
      }
      closedir(DIR);
    }
  }

  foreach my $tdir (@idirs)
  {
    opendir ( DIR, $tdir ) || return;
    while( (my $filename = readdir(DIR)))
    {
      next if ( $filename eq "." || $filename eq ".." );
#print "== " . catfile($tdir,$filename) . "\n";
      push (@trcdirs, $comp . ":" . catfile($tdir,$filename)) if ( -d catfile($tdir,$filename) && ( $tidir eq "-" || $filename eq "$tidir" ));
    }
    closedir(DIR);
  }
  return @trcdirs;
}

sub add_new_directory
{
  my $tfa_home = shift;
  my $dir = shift;
  my $comp = shift;
  # Directory name will be like diag/[asm|rdbms]/<db>/<inst>/trace
  # Append rws3060022%ASM|+ASM2%DIAGDEST=/u01/app/oragrid/diag/asm/+asm/+ASM2/trace
  my $tfa_dir_file = catfile($tfa_home, "tfa_directories.txt");
  my ($db, $inst);
  my $hostname = tolower_host();
  open (WF, ">>$tfa_dir_file");
  #print "add_new_directory $dir\n";
  if ( $dir =~ /[\\\/]diag[\\\/]asm[\\\/]user(.*?)[\\\/](.*?)[\\\/]/ )
  {
    $comp = "ASMCLIENT";
    $db = $1;
    $inst = $2;
    print WF "$hostname\%$comp|$inst\%DIAGDEST=$dir\n";
  }
  elsif ( $dir =~ /[\\\/]diag[\\\/]asm[\\\/](.*?)[\\\/](.*?)[\\\/]/ )
  {
    $comp = "ASM";
    $db = $1;
    $inst = $2;
    print WF "$hostname\%$comp|$inst\%DIAGDEST=$dir\n";
  }
   elsif ( $dir =~ /[\\\/]diag[\\\/]rdbms[\\\/](.*?)[\\\/](.*?)[\\\/]/ )
  {
    $comp = "RDBMS";
    $db = $1;
    $inst = $2;
    print WF "$hostname\%$comp|$db|$inst\%DIAGDEST=$dir\n";
  }
   elsif ( $comp eq "CRS" )
  {
    print WF "$hostname\%CRS\%DIAGDEST=$dir\n";
  }
   elsif ( $dir =~ /ExaWatcher/ ) 
  {
    print WF "$hostname\%OS\%DIAGDEST=$dir\n";
  }
   elsif ( $dir =~ /[\\\/]diag[\\\/]\w+[\\\/](.*?)[\\\/](.*?)[\\\/]/ )
  { 
    $db = $1;
    $inst = $2;
    print WF "$hostname\%$comp|$inst\%DIAGDEST=$dir\n";
  }
   elsif ($comp eq "ACFS" )
  {
    print WF "$hostname\%ACFS\%DIAGDEST=$dir\n";
  }
   else
  { 
    print WF "$hostname\%$comp\%DIAGDEST=$dir\n";
  }
  close(WF);
}

sub tfactlshare_get_dir_file_owner
{
  my $ohome = shift;
  my $ouser = "";
  if ($IS_WINDOWS)
  {
    $ouser = tfactlshare_get_user((stat($ohome))[4]);
  }
   else
  {
    $ouser = getpwuid((stat($ohome))[4]);
  }
  return $ouser;
}

sub get_base_dir
{
  my $home = shift;

  my $cfile = catfile($tfa_home, "internal", "cached_kv.out");
  if ( -f "$cfile" )
  {
    open(CF1, "$cfile");
    while(<CF1>)
    {
      chomp;
	  if ( index($_, "orabase.$home") !=-1)
	  {
	  	my @tokens = split(/=/,$_);
	  	my $tokenArrLength = scalar @tokens;
	  	if($tokenArrLength>=1){
		    return trim($tokens[1]);
	  	}
	  }
    }
    close(CF1);
  }
  my $cmd;
  if($IS_WINDOWS){
  	$cmd = catfile($home, "bin", "orabase.exe");
  }else{
  	$cmd = catfile($home, "bin", "orabase");
  }

  if ( -f $cmd)
  {
    $ENV{ORACLE_HOME} = $home;
    if ( $current_user eq "root" && !$IS_WINDOWS) 
    {
      my $ouser = tfactlshare_get_dir_file_owner($home);
      $cmd = tfactlshare_checksu($ouser,"$cmd"); 
    }
    my $retry = 0;
    while($retry <=3){
    	my $out = `$cmd`;
	    chomp($out);
	    if(-d $out){
	    	open(CF1, ">>$cfile");
		    print CF1 "orabase.$home=$out\n";
		    close(CF1);
		    return $out;
	    }
	    $retry = $retry +1 ;
    }
  }
  return "";
}

sub set_new_crshome
{
  my $tfa_home = shift;
  my $paramfile;
  if ( $ISCLOUD ) {
     $paramfile = getCloudSetupFile();
  } else {
     $paramfile = catfile($tfa_home,"tfa_setup.txt");
  }
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare set_new_crshome " .
     "tfa_home : $tfa_home paramfile : $paramfile", 'y', 'y');
  my $infile = "final_tfa_discovery.out";
  if ( -r "$paramfile" )
  {
    
    open(RF, "$infile");
    open(WF, ">>$paramfile");
    while(<RF>)
    {
      chomp;
      if (/CRS_HOME=/) { 
         print WF "$_\n"; 
         tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare set_new_crshome " .
         "Added CRS_HOME=$_ to paramfile : $paramfile", 'y', 'y');
      }
    }
    close(RF);
    close(WF);
  }
}

########
# NAME
#   tfactlshare_get_tfadirectories
#
# DESCRIPTION
#   This function is used to retrieve entries
#   from tfa_directories.txt file.
#
# PARAMETERS
#   $tfa_home
#   $comp
#   $key
#   $emdir
#
# ENTRY EXAMPLE
#   hostname%EMAGENT%ORACLE_HOME=/u01/app/oracle/product/agenthome/agent_13.2.0.0.0 
#
# RETURNS
#   The tfa_directories.txt entry or "" if not found.
#
########
sub tfactlshare_get_tfadirectories
{
  my $tfa_home = shift;
  my $comp     = shift;
  my $key      = shift;
  my $emdir    = shift;
  my $infile = catfile($tfa_home,"tfa_directories.txt");
  my $localhost = tolower_host();
  my @emret = ();
  if ( not $emdir ) {
    $emdir = FALSE;
  }
  $infile = catfile($tfa_home,"resources","tfa_emdirectories.txt") if $emdir;

  if ( -r "$infile" )
  {
    open(RF, "$infile");
    while(<RF>)
    {
      chomp;
      my @a = split(/=/);
      if ( $a[0] =~ /$localhost\%$comp\%$key/ )
      {
         if ( not $emdir ) {
           return $a[1];
         } else {
           push @emret, $a[1];
         }
      }
    }
    close(RF);
  }
  if ( not $emdir ) {
    return "";
  } else {
    return @emret;
  }
} # end sub tfactlshare_get_tfadirectories

sub check_new_directories
{
  my $tfa_home = shift;
  my $tfa_dir_file;
  my $tfasetup;
  if ( ! $ISCLOUD ) {
        $tfa_dir_file = catfile($tfa_home, "tfa_directories.txt");
  } else {
        $tfasetup = getCloudSetupFile();
        my $tfa_base = getTFABase($tfasetup);
        $tfa_dir_file = catfile($tfa_base, "tfa_directories.txt");
  }

  my $file_new = "final_tfa_discovery.out";
  my %cdirs = ();
  my $ndirs = ();
  if ( -r "$tfa_dir_file" )
  {
    open(RF, "$tfa_dir_file");
    while(<RF>)
    {
      chomp;
      my @a = split(/=/);
      $cdirs{$a[1]} = $a[0];
    }
    close(RF);
  }

  if ( -r "$file_new" )
  {
    open(WF, ">>$tfa_dir_file");
    open(RF, "$file_new");
    while(<RF>)
    {
      chomp;
      my $line = $_;
      my @a = split(/=/, $line);
      if ( ! exists $cdirs{$a[1]} )
      {
        print WF "$line\n";
      }
    }
    close(RF);
    close(WF);
    add_to_scanned_dbs($tfa_home, "final_tfa_discovery.out");
    unlink("final_tfa_discovery.out");
    unlink("ora_stack_status_pct.out");
    unlink("ora_stack_status.out");
  }
}

sub addReDiscDirectories
{
  my $tfa_home = shift;
  my (@nodelist, @diagdest, @fields);
  my $infile = "ora_stack_status_pct.out";
  my $outfile = "final_tfa_discovery.out";
  my $nodescorrect = "false";
  my $dirscorrect = "false";
  my $crshome;
  my $nodelistline;
  my %crsinstalled;
  my $clustername;
  my %diagdesttmp;
  my $validentry = "false";


 # Start off by reading what we need from the file.
 # file comes with dots which causes me split problems so I need to adjust it
 replaceDotsInDisc();
 # We will create a new file to hold updated values
 open (IN, '<', $infile) or die "Can't open file $infile: $!\n";
 open (OUT, '>', $outfile) or die "Can't open file $outfile: $!\n";
 while (<IN>) {
   chomp;
   my ($key , $val) = split("=");
   if ($key =~ /CLUSTER_NAME/) { $clustername = $val; print OUT "$_\n"}
   elsif ($key =~ /NODE_NAMES/) { @nodelist = split /\,/,$val; print OUT "$_\n"}
   # for the diagdest we only want one for each host.db.dir
   # so we will push it into a hash to remove duplicates
   # also the diagnostic_dest is for multiple resources so it's no good
   # if we find one though we will hold on to it as it might be useful later.
   elsif ($key =~ /diagnostic_dest|background_dump_dest|user_dump_dest/)
   { if ($key =~ /diagnostic_dest/ ) {
         if ( $val !=~ /[diag|diag\/]$/){
            $val = catfile($val,"diag");
            if ( -d catfile($val,"tnslsnr") ) {
               # build a string to havethe listener diag dest
               @fields = split /\%/, $key ;
               $key = "$fields[0]\%TNS\%DIAGDEST\%".catfile($val,"tnslsnr");
               $diagdesttmp{"$key\%$val"} = "1";
            } elsif ( -d catdir($val, "rdbms")) {
		$key =~ s/diagnostic_dest/DIAGDEST/;
		$val = catdir($val, "rdbms");
		$diagdesttmp{"$key\%$val"} = "1";
	    }
         }
     } else {
     # do not search for diagnostic dest as it's weeded out above ..
     # this may change if they ever deprecate user_dump_dest, bdump etc
     $key =~ s/background_dump_dest|user_dump_dest/DIAGDEST/;
     $diagdesttmp{"$key\%$val"} = "1";
     }
   }
   elsif ($key =~ /CRS_HOME/) { $crshome = $val;  print OUT "$_\n";}
   elsif ($key =~ /CRS_INSTALLED/)
   { my @tmp = split /\%/, $key;
     $crsinstalled{@tmp[0]} = "$val" ;
     print OUT "$_\n";
   }
   else { print OUT "$_\n";}
 }
 close IN;
 # We have pulled all we need out of the file
 # if crs is installed ona node then set the crs diag dir
 foreach ( keys %crsinstalled ) {
   if ( $crsinstalled{$_} eq "1") {
      $diagdesttmp{"$_\%CRS\%DIAGDEST\%".catfile($crshome,"log")} = "1";
   }
 }

 # Load the diagnostic destination array with what we have found.
 @diagdest = keys %diagdesttmp;
 my @diagdestsorted = reformatDiagDest(@diagdest);

 my %adrbases;
 foreach (@diagdestsorted) {
    #print "$_\n";
    @fields = split /\%/, $_ ;
    print OUT "$fields[1]\%$fields[2]\%DIAGDEST=$fields[0]\n";
    my $adrbase;
    if ( $fields[0] =~ m/(.*)[\/\\](diag[\/\\]rdbms[\/\\].*[\/\\].*\_[0-9]+)/ || 
         $fields[0] =~ m/(.*)[\/\\](diag[\/\\]rdbms[\/\\].*[\/\\].*[0-9]+)/   ||
         $fields[0] =~ m/(.*)[\/\\](diag[\/\\](crs|apx)[\/\\].*[\/\\].*)/     ||
         $fields[0] =~ m/(.*)[\/\\](crsdata[\/\\].*[\/\\].*)/                 ||
         $fields[0] =~ m/(.*)[\/\\](diag[\/\\]tnslsnr.*)/                     ||
         $fields[0] =~ m/(.*)[\/\\](diag[\/\\].*[\/\\]\+ASM[0-9]+)/           ||
         $fields[0] =~ m/(.*)[\/\\](diag[\/\\].*[\/\\]\+APX[0-9]+)/           ||
         $fields[0] =~ m/(.*)[\/\\](diag[\/\\].*[\/\\]\+IOS[0-9]+)/           ||
         $fields[0] =~ m/(.*)[\/\\](diag[\/\\](asmtool|clients|asm|afdboot|diagtool)[\/\\]user_.*[\/\\](host|adrci)_.*)/ ) {
      $adrbase = $1;
      if ( not exists $adrbases{$fields[1] . "," . $adrbase} ) {
        $adrbases{$fields[1] . "," . $adrbase} = TRUE;
        #print "adr base $adrbase , $fields[1] $fields[0] \n";
      }
    }
 }

 # write out discovered ADR BASEs
 foreach ( keys(%adrbases) ) {
   @fields = split /\,/, $_ ;
   print OUT "$fields[0]\%ADRBASE=$fields[1]\n";
 }

 close OUT;
 return SUCCESS;
}

sub runDiscovery 
{
  my $tfa_home = shift;
  my $discfile = shift;
  my $perl = shift;
  my $addtee;

  ## PATH WITH SPACES IN BETWEEN AND " AT THE START AND END FAIL THE "if (-f $path)" CHECK
  my $perl_cpy = $perl;
  $perl_cpy =~ s/"//g;
  
  if (! -f $perl_cpy) {
  	$perl = tfactlshare_getPerl($tfa_home);
  }
  
  $addtee = " | tee -a $INSTLOGFILE" if ( $INSTLOGFILE && -f $INSTLOGFILE ) ;
  if(!$IS_WINDOWS){
  	dbg(DBG_NOTE, "\nDiscovering Nodes and Oracle resources\n");
	 my $pid = fork ();
	 #print "PID: $pid => PERL: $perl\n";
	 if ($pid == 0) {
           ### print "discfile $discfile\n";
           exec("$perl $tfa_home/bin/discoverOraStack.pl");
	 } else {
	 waitpid($pid,0);
	  if ( $? != 0 )
	  {
	    exit(1);
	  }
	 }
  } else {
  	my $discFile = catfile($tfa_home, "bin", "discoverOraStack.pl");
        system("$perl $discFile -perl $perl");
  }
 # The discovery should have created a file with all the info we need to make a
 # decent start at the configuration.
}
# end sub runDiscovery

sub discoverMore
{
  
 if ( 1 == 0 ) {
   print "No way\n"
 }
}
#End sub discoverMore
sub confirmDiscovery
{
 my $discfile = shift; 
 my (@nodelist, @diagdest, @fields);
 my $infile = "ora_stack_status_pct.out";
 my $outfile = "final_tfa_discovery.out";
 my $nodescorrect = "false";
 my $dirscorrect = "false";
 my $crshome;
 my $nodelistline;
 my %crsinstalled;
 my $clustername;
 my %diagdesttmp;
 my $validentry = "false";
 
 replaceDotsInDisc();
 # We will create a new file to hold updated values
 open (IN, '<', $infile) or die "Can't open file $infile: $!\n";
 open (OUT, '>', $outfile) or die "Can't open file $outfile: $!\n";
 while (<IN>) {
   chomp;
   my ($key , $val) = split("=");
   if ($key =~ /CLUSTER_NAME/) { $clustername = $val; print OUT "$_\n"}
   elsif ($key =~ /NODE_NAMES/) { @nodelist = split /\,/,$val; print OUT "$_\n"}
   # for the diagdest we only want one for each host.db.dir
   # so we will push it into a hash to remove duplicates 
   # also the diagnostic_dest is for multiple resources so it's no good
   # if we find one though we will hold on to it as it might be useful later.
   elsif ($key =~ /diagnostic_dest|background_dump_dest|user_dump_dest/) 
   { if ($key =~ /diagnostic_dest/ ) {
         if ( $val !=~ /[diag|diag\/]$/){
            $val = catfile($val,"diag");
            if ( -d catfile($val,"tnslsnr") ) {
               # build a string to havethe listener diag dest
               @fields = split /\%/, $key ;
               $key = "$fields[0]\%TNS\%DIAGDEST\%".catfile($val,"tnslsnr");
               $diagdesttmp{"$key\%$val"} = "1";
            } elsif ( -d catdir($val, "rdbms")) {
		$key =~ s/diagnostic_dest/DIAGDEST/;
		$val = catdir($val, "rdbms");
		$diagdesttmp{"$key\%$val"} = "1";
	    }
         }
     } else {
     # do not search for diagnostic dest as it's weeded out above ..
     # this may change if they ever deprecate user_dump_dest, bdump etc
     $key =~ s/background_dump_dest|user_dump_dest/DIAGDEST/;
     $diagdesttmp{"$key\%$val"} = "1";
     }
   }
   elsif ($key =~ /CRS_HOME/) { $crshome = $val;  print OUT "$_\n";} 
   elsif ($key =~ /CRS_INSTALLED/)
   { my @tmp = split /\%/, $key;
     $crsinstalled{@tmp[0]} = "$val" ; 
     print OUT "$_\n";
   }   
   else { print OUT "$_\n";
          if ( $key =~ /RDBMS_ORACLE_HOME/ ) {
            my $ohome = $val;
            if ($discfile eq "sh") {
            	if ( $val =~ /(.*)\|.*\|.*/ ) {
	              $ohome = $1;
	            }
            } else {
	            if ( $val =~ /(.*)\|.*\|.*\|/ ) {
	              $ohome = $1;
	            }
	        }
            my $adrbase = tfactlshare_get_adrbase($ohome);
            if ( $adrbase ne "invalid" ) {
              print OUT "localnode\%ADRBASE=$adrbase\n";
            } # end if $adrbase ne "invalid"
          }
   }
 }
 close IN;
 # We have pulled all we need out of the file
 # if crs is installed ona node then set the crs diag dir
 foreach ( keys %crsinstalled ) {
   if ( $crsinstalled{$_} eq "1") {
      $diagdesttmp{"$_\%CRS\%DIAGDEST\%".catfile($crshome,"log")} = "1";
   }
 }
 
 # Load the diagnostic destination array with what we have found.
 @diagdest = keys %diagdesttmp;

 while ($nodescorrect eq "false") {
   print "\n\n";

   #Check the no of nodes.
   my $noofnodes = scalar @nodelist;

   if ( $noofnodes == "1" ) {
	dbg(DBG_NOTE, "TFA Will be Installed on $nodelist[0]...\n");
	$nodescorrect = "true";
   }
   else {
	dbg(DBG_NOTE, "TFA Will be Installed on the Following Nodes:\n");
	dbg(DBG_NOTE, "++++++++++++++++++++++++++++++++++++++++++++\n\n");
   	dbg(DBG_NOTE, "Install Nodes\n"); 
   	dbg(DBG_NOTE, "=============\n");

   	foreach (@nodelist)
   	{
    	   dbg(DBG_NOTE, "$_\n");
   	}

   	my $changenode;
	
	if ( ! $SILENT )
   	{
     		print "\nDo you wish to make changes to the Node List ? [Y/y/N/n] [N] ";
     		chomp( $changenode = <STDIN> );
   	}

	$changenode ||= 'N';
   	$changenode = get_valid_input ($changenode, "Y|y|N|n", "N");

   	if ($changenode =~ /[Yy]/) {
      		print "\nPlease restart the tfasetup to change the node list\n";
      		print "You can either:-\n";
      		print "1) Enter all nodes into a file tfa_nodemap in the directory this is executed from\n";
      		print "2) Ensure Oracle GI/CRS is running so we can discover the cluster nodes\n";
 		#print "3) Supply the node names at runtime during the discovery stage of tfasetup\n";
      		exit 100;
   	} else {
     		$nodescorrect = "true";
   	} # End of if change Node
   } #End of if noofnodes
 } # End While user unhappy about nodes
 # reformat the diagdest into the format I want

 # Checking JAVA Status on all nodes
 if ( ! -d catdir($BASEDIR, "tfa_home", "jre") ) {
 my $java_home_path;
 my $local_java_only;
 if(defined $ENV{'JAVA_HOME'}){
   $java_home_path = $ENV{'JAVA_HOME'};
 } else {
   $java_home_path = get_java_home_defer();
 }	
 my $javabin = catfile($java_home_path,"bin","java$EXE");

 $local_java_only = "true" if( $java_home_path eq catdir($BASEDIR, "tfa_home", "jre"));

 if($local_java_only eq "true"){
   dbg(DBG_WHAT,"Checking JAVA Status on Local Node ...\n");
 }  else {
   print "\nChecking JAVA Status on all nodes ...\n";
   dbg(DBG_WHAT,"Checking JAVA Status on all nodes ...\n");
 }
 dbg(DBG_WHAT, "++++++++++++++++++++++++++++++++++++++++++++\n");
 dbg(DBG_WHAT,"JAVAHOME : $java_home_path\n");
 dbg(DBG_WHAT,"JAVA : $javabin\n");
 my $jtb = Text::ASCIITable->new();
 $jtb->setCols("Host", "Status","Version");
 $jtb->setOptions({"outputWidth" => $tputcols, "headingText" => "JAVA Status on all Nodes"});

 my $java_mismatch = "false";
 foreach my $host (@nodelist) {
   next if(($local_java_only eq "true" ) and ($host ne $localhost));
   my $version;
   my $version_output;
   my $status = 0;
   my @version_output;
   my $line;

   ($version_output,$status) = host_remote($host,"$javabin -version",$localhost, 'OUTPUT_REDIRECT');
   @version_output = @$version_output;
   chomp(@version_output);
   if ($IS_WINDOWS) {
      foreach $line (@version_output) {
        if ( $line =~ /not recognized as an internal or external command/ ) {
         $status = 1;
         last;
        }
      } 
   }

   if( $status ){
     $status = "Not Exists";
     $version = "N/A";
     $java_mismatch = "true";
   } else {
     $status = "Exists";
     my $java_version = 0;
     foreach $line (@version_output) {
       if ( $line =~ /version \"(\d)\.(\d)/ ) {
         $java_version = "$1$2";
         $java_mismatch = "true" if ( $java_version < 18);
         $line =~ /version \"(.*)\"/;
         $version = $1; 
         last;
       }
     }
   }
   $jtb->addRow($host,$status,$version);
 }

 if ( $java_mismatch eq "true"){
   dbg(DBG_NOTE,"\n\n$jtb\n");
   dbg(DBG_NOTE,"Following criteria does not meet on all cluster nodes\n");
   dbg(DBG_NOTE,"ERROR : TFA needs Java 1.8 or higher in all Nodes\n");
   dbg(DBG_NOTE,"ERROR : JAVAHOME location should exists in all Nodes\n");
   dbg(DBG_NOTE,"\nPlease restart the tfasetup either by :-\n");
   dbg(DBG_NOTE,"1] Change node list accordingly\n");
   dbg(DBG_NOTE,"2] Provide correct -javahome path\n");
   exit 100; 
 } else {
   dbg(DBG_WHAT, "\n\n$jtb\n"); 
 }
 } 
 # End of Checking JAVA Status on all nodes

 my $localhost = tolower_host();
 my @diagdestsorted = reformatDiagDest(@diagdest);
  my $tfa_components = "RDBMS|CRS|ASM|INSTALL|OS";
  my @tfa_components = split(/\|/, $tfa_components);

 while ($dirscorrect eq "false") {
   dbg(DBG_NOTE, "\nTFA will scan the following Directories\n");
   dbg(DBG_NOTE, "++++++++++++++++++++++++++++++++++++++++++++\n\n");
   #print "\nTrace Directories\n";
   
   my %TABLES;
   my $tb = Text::ASCIITable->new();
   $tb->setCols("Trace Directory", "Resource");
   $tb->setColWidth("Trace Directory", $tputcols-20);
   $tb->setColWidth("Resource", 20);
   $tb->setOptions({"outputWidth" => $tputcols, "headingText" => $localhost});
   $TABLES{$localhost} = $tb;
   
   my @linefields;
   my $direc;
   my $node_name;
   my $resource;
   my $table;
   my $key_entry;
   my $value;
   foreach (@diagdestsorted) {
        @linefields = split /\%/, $_;
	$direc = @linefields[0];
	$node_name = @linefields[1];
	$resource = @linefields[2];
	next if ($node_name ne $localhost);
	if ($resource =~ /\|/) {
	  my @fields = split(/\|/, $resource);
	  $resource = @fields[0];
	}
	$table = $TABLES{$node_name};
	if (defined($table)) {
       	  $table->addRow(wrap("","",$direc),$resource);
	}
   }
   while (($key_entry, $value) = each(%TABLES)) {
	dbg(DBG_NOTE, $TABLES{$key_entry}."\n");
   }
   my ($selectednodes,$allnodes);
   #printDiagDest(@diagdestsorted);
   #print "\n\n";
   my $changetrace = "N";

   #Removed Option to Change the Trace Directory List
   #if ( ! $SILENT )
   #{
   #  print "Do you wish to change the Trace Directory List ? [Y/y/N/n] [N] ";
   #  chomp( $changetrace = <STDIN> );
   #}
   #  $changetrace ||= "N";
   #  $changetrace = get_valid_input ($changetrace, "Y|y|N|n", "N");
     if ($changetrace =~ /[Yy]/) {
        $validentry = "false";
        while ( $validentry eq "false") {
          print "Do you wish to Add/Delete a Trace Directory, or Cancel ? [A/D/Cancel] [Cancel] ";
          chomp( my $whatchange = <STDIN> );
          $whatchange ||= "Cancel";
          $whatchange = get_valid_input ($whatchange, "A|D|Cancel", "Cancel");
          if ($whatchange =~ /^[Aa]/) {
              # Add an Entry ..
              $validentry = "true";
              print "Enter the full Directory Path to add : ";
              chomp ( my $newdir = <STDIN> );
	      while (!(defined $newdir) || ($newdir eq "")) {
		print "Please enter a valid directory path : ";
		chomp($newdir = <STDIN>);
	      }
              while ( ! -d $newdir ) {
                 #print "Directory does not exist on local node. Still Add  ? [Y/y/N/n] [N] ";
                 #chomp ( my $stilladd = <STDIN> );
                 #$stilladd ||= "N";
                 #$stilladd = get_valid_input ($stilladd, "Y|y|N|n", "N");
                 #if ( ! $stilladd =~ /^[Yy]/ ) {
                 #    last;
                 #}
		print "Directory does not exist on local node: $newdir\n";
		#print "Do you wish to add it on other nodes ? [Y|y|N|n] [N] ";
		#chomp (my $addforothernodes = <STDIN>);
		#$addforothernodes ||= "N";
		#$addforothernodes = get_valid_input($addforothernodes, "Y|y|N|n", "N");
		print "Please enter a valid directory path : ";
		chomp($newdir = <STDIN>);
		
              }
              # Check if the directory exists already in our list #TODO
              # newdir does exist locally .
              print "Add this directory for All Nodes ? [Y/y/N/n] [N] ";
              chomp ( $allnodes = <STDIN> );
              $allnodes ||= "N";
              $allnodes = get_valid_input ($allnodes, "Y|y|N|n", "N");
	      my $validnodes;
              if ( $allnodes =~ /^[Yy]/ ) {
                 $allnodes = "Y";
              } else {
                 print "Please enter a comma seperated list of nodes for this Directory\n";
                 chomp ( $selectednodes = <STDIN> );
		 $validnodes = getValidNodes($selectednodes, @nodelist);
 		 #print "valid nodes: $validnodes\n";
              } # End of if allnodes 
              if ( $allnodes eq "Y" || $validnodes )
              {
		 my $nodes_where_dir_exists = checkExistenceOfDirectory($allnodes, $validnodes, $newdir, @nodelist);
		 if (! defined $nodes_where_dir_exists ) {
		    print "Directory does not exist on any of the nodes\n";
		 }
		 else  {
                 print "Please enter component for this Directory [$tfa_components] : ";
                 my ($database, $instance);
                 my $comp = <STDIN>;
                 chomp($comp);
                 $comp = get_valid_input ($comp, $tfa_components, "CRS");   
                 if ( $comp eq "RDBMS" )
                 { # We need database and instance names
                   print "Please enter database name for this Directory :";
                   while ( ! $database ) 
                   {
                     $database = <STDIN>;
                     chomp($database);
                   }
                   print "Please enter instance name for this Directory :";
                   while ( ! $instance )
                   {
                     $instance = <STDIN>;
                     chomp($instance);
                   }
                 }
                 if ( $comp eq "ASM" )
                 { # We need instance name
                   print "Please enter instance name for this Directory :";
                   while ( ! $instance )
                   {
                     $instance = <STDIN>;
                     chomp($instance);
                   }
                 }
                 my @diagtmp;
                 #foreach $node (@nodelist)
                 #{
                  #if ( $allnodes eq "Y" || $selectednodes =~ /$node/ )
                   #{
                    # @diagtmp = @diagdestsorted;
                   #  push @diagtmp, "$newdir\%$node\%$comp";
                  #   @diagdestsorted = sort @diagtmp;
                 #  }
                # }
		 foreach $node (split(/\,/, $nodes_where_dir_exists)) {
                     @diagtmp = @diagdestsorted;
                     push @diagtmp, "$newdir\%$node\%$comp";
                     @diagdestsorted = sort @diagtmp;
		 }
		 }
              }
              
          } elsif ( $whatchange =~ /^[Dd]/) { 
              $validentry = "true";
              # Loop through each one and see if they want to delete it.
              my $numdel = 0;
              my $count = $#diagdestsorted;
              open(RWF, ">>removed_directories.txt");
              foreach (0..$count) {
                @fields = split /\%/, $diagdestsorted[$_-$numdel];
                print "Do you wish to Delete the Entry for \n";
                print "$fields[0] on $fields[1] for resource $fields[2]?  [Y/y/N/n] [N] ";
                chomp( my $deletethis = <STDIN>);
                $deletethis ||= "N";
                $deletethis = get_valid_input ($deletethis, "Y|y|N|n", "N");
                if ( $deletethis =~ /^[Yy]/) {
                   print RWF "$fields[1]%$fields[0]\n";
                   splice @diagdestsorted, $_-$numdel, 1;
                   $numdel ++;
                print "$numdel\n";
                } # End of changing this trace line
              } # End foreach diagdest -- Delete
              close(RWF);
              
          # } No Modify right now ..
              #elsif ( $whatchange =~ /^[Mm]/) { 
              #$validentry = "true";
                
              # Loop through each one and see if they want to change it.

              #foreach (0..$#diagdestsorted) {
              #  @fields = split /\%/, $diagdestsorted[$_];
              #  print "Do you wish to Change the Entry for \n";
              #  print "@fields[0] ?  [Y/y/N/n] [N] ";
              #  chomp( my $changethis = <STDIN>);
              #  if ($changethis =~ /[Yy]/) {
              #     print "This destination is set for these nodes\n\n";
              #  } # End of changing this trace line
              #} # End of foreach diagdest - Modify      
          } elsif ( $whatchange =~ /Cancel/) { 
              $validentry = "true";
          } else {
              print "Invalid option Entered\n";
          }
        
        } # End of while not a valid change      
     } else {
       $dirscorrect = "true";
     } # End of if change trace
 } # End while dirs correct
 # write out those directories
 my %adrbases;
 foreach (@diagdestsorted) {
    #print "$_\n";
    @fields = split /\%/, $_ ;
    print OUT "$fields[1]\%$fields[2]\%DIAGDEST=$fields[0]\n";
    my $adrbase;
    if ( $fields[0] =~ m/(.*)[\/\\](diag[\/\\]rdbms[\/\\].*[\/\\].*\_[0-9]+)/ ||
         $fields[0] =~ m/(.*)[\/\\](diag[\/\\]rdbms[\/\\].*[\/\\].*[0-9]+)/   ||
         $fields[0] =~ m/(.*)[\/\\](diag[\/\\](crs|apx)[\/\\].*[\/\\].*)/     ||
         $fields[0] =~ m/(.*)[\/\\](crsdata[\/\\].*[\/\\].*)/                 ||
         $fields[0] =~ m/(.*)[\/\\](diag[\/\\]tnslsnr.*)/                     ||
         $fields[0] =~ m/(.*)[\/\\](diag[\/\\].*[\/\\]\+ASM[0-9]+)/           ||
         $fields[0] =~ m/(.*)[\/\\](diag[\/\\].*[\/\\]\+APX[0-9]+)/           ||
         $fields[0] =~ m/(.*)[\/\\](diag[\/\\].*[\/\\]\+IOS[0-9]+)/           ||
         $fields[0] =~ m/(.*)[\/\\](diag[\/\\](asmtool|clients|asm|afdboot|diagtool)[\/\\]user_.*[\/\\](host|adrci)_.*)/ ) {
      $adrbase = $1;
      if ( not exists $adrbases{$fields[1] . "," . $adrbase} ) {
        $adrbases{$fields[1] . "," . $adrbase} = TRUE;
        #print "adr base $adrbase , $fields[1] $fields[0] \n";
      }
    }
 }

 # write out discovered ADR BASEs
 foreach ( keys(%adrbases) ) {
   @fields = split /\,/, $_ ;
   print OUT "$fields[0]\%ADRBASE=$fields[1]\n";
 }
  
 close OUT;
 return SUCCESS;
}
# end sub confirmDiscovery

sub getValidNodes {
  my $validnodes;
  my ($selectednodes, @nodenames) = @_;
  my $node;
  my @list_of_nodes = split(/,/, $selectednodes);
  my %allnodes = map { $_ => 1 } @nodenames;
  foreach $node (@list_of_nodes) {
    $node = trim($node);
    if(exists($allnodes{$node})) {
	$validnodes .= $node.",";
    }
    else {
	print "Node $node does not exist\n";
    }
  }
  $validnodes =~ s/,$//;
  return $validnodes;
}

sub checkExistenceOfDirectory
{
  my ($option, $selectednodes, $direc, @nodenames) = @_;
  my $localnode = tolower_host();
  my $node;
  my $final_list_of_nodes;
  if ($option eq "Y") {
        foreach $node (@nodenames) {
          if ($localnode =~ /$node/) {
                if ( -d $direc ) {
                  $final_list_of_nodes .= $localnode.",";
                }
                else {
                  print "Directory does not exist in $node\n";
                }
          }
          else {
                my $a =  `$SSH $node "if [ -d $direc ]; then echo exists; fi" | grep -ic exists`;
                chomp($a);
                if ($a > 0) {
                  $final_list_of_nodes .= $node.",";
                }
                else {
                  print "Directory does not exist in $node\n";
                }
          }
        } # end of for loop
  } # end of option = "Y"
  elsif ($selectednodes) {
        my @list_of_nodes = split(/,/, $selectednodes);
        foreach $node (@list_of_nodes) {
                if ($localnode =~ /$node/) {
                  if ( -d $direc ) {
                    $final_list_of_nodes .= $localnode.",";
                  }
                  else {
                    print "Directory does not exist in $node\n";
                  }
                }
                else {
                  my $a =  `$SSH $node "if [ -d $direc ]; then echo exists; fi" | grep -ic exists`;
                  chomp($a);
                  if ($a > 0) {
                    $final_list_of_nodes .= $node.",";
                  }
                  else {
                    print "Directory does not exist in $node\n";
                  }
                }
        } # end of for loop
  } # end of elsif
  $final_list_of_nodes =~ s/,$//;
  return $final_list_of_nodes; 
}

sub replaceDotsInDisc
{
my $infile = "ora_stack_status.out";
my $outfile = "ora_stack_status_pct.out";

 open (IN, '<', $infile) or die "Can't open file $infile: $!\n";
 open (OUT, '>', $outfile) or die "Can't open file $outfile: $!\n";
 while (<IN>) {
   chomp;
   my ($key , $val) = split("=");
   $key =~ s/\./\%/g;
   print OUT "$key=$val\n";
 }
 close IN;
 close OUT;
}
# End sub replaceDotsInDis
sub reformatDiagDest
{ my @diagdest = @_;
  my @newdiag;
  my $newdiagline;
  my @diagsorted; 
  my @linefields;
  
  #sort thedata how I want it ..
  foreach (@diagdest) {
    @linefields = split /\%/, $_;
    $newdiagline = "$linefields[3]\%$linefields[0]\%$linefields[1]";
    push @newdiag, $newdiagline;
    @diagsorted = sort @newdiag;
  }
  return @diagsorted;

}
# End sub reformatDiagDest

sub printDiagDest
{ my (@diagsorted, @nodelist) = @_;
  print "---->>>>>".scalar(@nodelist)."\n";
  my $currentdir;
  my $currentnode;
  my @linefields;
  my %tables;
  my $key;
  my $value;
  foreach (@nodelist){
	my $tb = Text::ASCIITable->new();
	$tables{$_} = $tb;
  }
  while (($key, $value) = each(%tables)) {
	print "$key\n";
  }
  
  
  # print it By Directory as that is the most unique and then find all nodes
  # and DB's for that.
  my $t;
  foreach (@diagsorted) {
    @linefields = split /\%/, $_;
    if ( $currentnode ne @linefields[1] ) {
       $currentnode = @linefields[1];
       $t = Text::ASCIITable->new({headingText => $currentnode});
       $t->setCols('Trace Directory','Resource');
       $t->setColWidth('Trace Directory', $tputcols-20);
       $t->setColWidth('Resource',20);
       $t->setOptions('outputWidth',$tputcols);
       $Text::Wrap::columns = $tputcols-20;
       #print "    Node         : @linefields[1]\n";
    }
    if ( $currentdir ne @linefields[0] ) { # new directory
       $currentdir = @linefields[0];
       $t->addRow(wrap("","",$currentdir),@linefields[2]);
       $t->addRowLine();
       #print "Trace Directory  : @linefields[0]\n";
    }
    #print $t;
       #print "        Resource : @linefields[2]\n";
  }    
}
# End sub printDiagDest

sub check_java_installation
{
  my $SILENT = shift;
  my $scr_path = dirname($0);
  my $tfa_home = dirname($scr_path);
  my $java_home = "";

  if ( -d catdir($tfa_home, "jre") ) {
	$java_home = catdir($tfa_home, "jre");
  } else {
	my $cnt = 0;
    	while ( ! $java_home ) {

		if ( $ENV{"JAVA_HOME"} && $cnt == 0 ) {
			# First time check env
			$java_home = $ENV{JAVA_HOME};
			print "Using JAVA_HOME : $java_home\n";
		} elsif ( $SILENT == 1 ) {
			print "ERROR: Could not find valid Java Home. Exiting TFA Install...\n";
			exit 1;
		} else {
			print "Enter a Java Home that contains Java 1.8 or later : ";
			chomp ( $java_home = <STDIN> );
			$java_home = trim($java_home);
		}

		if ( $java_home ) {
			if ( -e catfile($java_home, "jre", "bin", "java$EXE" )) {
				$java_home = catdir($java_home, "jre");
			}

			if ( ! -e catfile($java_home, "bin", "java$EXE") ) {
				print "ERROR : Could not find java executables in $java_home/bin/java$EXE\n";
				$java_home = "";
			} else {
          			my $javabin = catfile($java_home, "bin", "java");
				my @out = `\"$javabin\" -version 2>&1`;
				chomp(@out);
				my $line;
				my $java_version = 0;

				foreach $line (@out) {
					if ( $line =~ /version \"(\d)\.(\d)/ ) {
						$java_version = "$1$2";
						last;
					}
				}

				if ( $java_version < 18 && $INSTALL_TYPE ne "GI" ) {
					print "ERROR : TFA needs Java 1.8 or higher\n";
					$java_home = "";
				}
			}
		}

		$cnt ++;
		if ( $cnt == 3 && ! $java_home ) {
			print "ERROR: Could not find valid Java Home. Exiting TFA Install...\n";
			exit 1;
		}
	}
  }

  open(WF, ">java_install.out" );
  print WF "JAVA_HOME=$java_home\n";
  close(WF);

  print "\n";
}


#========== runExtracttoSetup

sub runExtracttoSetup
{
  $BASEDIR     = shift;
  my $tfa_home = catdir("$BASEDIR","tfa_home");
  my $local_tfa_home = $tfa_home;
  my $tfa_base = $tfa_home;

  # print "runExtracttoSetup BASEDIR $BASEDIR";
  # print "runExtracttoSetup CURRENT_USER $current_user";

  if ( $current_user eq "root" ) {
          dbg(DBG_NOTE, "TFA-00###: TFA setup is running as the root user...\n");
          dbg(DBG_NOTE, "Running Extractto Setup for TFA as user $current_user is not allowed...\n\n");
          exit 1;
  } else {
          dbg(DBG_NOTE, "Running Extractto Setup for TFA as user $current_user ...\n\n"); 
  }

  print "\nEnabling Access for user $current_user on $localhost...\n";

  tfactlshare_chmod("-path=$tfa_home -perm=750 -r");
  tfactlshare_fixTfadiagnostics($tfa_home);
  if ($IS_WINDOWS){
    tfactlshare_chmodAddPerm(0111,catfile($tfa_home,"bin","tfactl.bat"));
  } else{
    tfactlshare_chmodAddPerm(0111,catfile($tfa_home,"bin","tfactl"));
  }
  tfactlshare_chmodAddPerm(0111,catfile($tfa_home,"install","init.tfa"));

  $tfa_base =~ s/(\/|\\)tfa(\/|\\)$localhost(\/|\\)tfa_home//;
  $tfa_base = catfile($tfa_base, "tfa");

  # Set permissions for Directories:
  tfactlshare_chmod("-perm=751 -path=$tfa_home");
  tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home,"bin"));
  tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home,"internal"));
  tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home,"jlib"));
  tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home,"bin","common"));
  tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"bin","modules"));
  tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"bin","scripts"));
  tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home,"bin","common","exceptions"));
  tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home,"bin","Text"));
  tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home,"bin","Text","ASCIITable"));
  tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home,"ext"));
  tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"ext")." -r");
  tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"resources"));
  tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"resources","sql"));

  # Set Permissions for files:
  tfactlshare_chmod("-perm=755 -path=".catfile($tfa_home,"bin","tfactl"));
  tfactlshare_chmod("-perm=755 -path=".catfile($tfa_home,"bin","tfactl.pl"));
  if ( -f catfile($tfa_home,"bin","tfa_upload_files.pl") ) {
    tfactlshare_chmod("-perm=755 -path=".catfile($tfa_home,"bin","tfa_upload_files.pl"));
  }
  tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"bin","common")." -pattern=.pm");
  tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"bin","modules")." -pattern=.pm");
  tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"bin","scripts")." -pattern=.pm");
  tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"bin","scripts")." -pattern=.pl");
  tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"bin","common","exceptions")." -pattern=.pm");
  tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"tfa_setup.txt"));
  tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"tfa_directories.txt"));
  tfactlshare_chmod("-perm=600 -path=".catfile($tfa_home,"public.jks"));
  tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"internal","runstatus.txt"));
  tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"internal","dbversions.json"));
  tfactlshare_chmod("-perm=644 -path=".catdir($tfa_home,"jlib")." -pattern=.jar");
  tfactlshare_chmod("-perm=755 -path=".catfile($tfa_home,"bin","Text","ASCIITable.pm"));
  tfactlshare_chmod("-perm=755 -path=".catfile($tfa_home,"bin","Text","ASCIITable","Wrap.pm"));
  tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"bin","Date")." -r");
  tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"bin","Term")." -r");
  tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"resources","components.xml"));
  tfactlshare_chmod("-perm=644 -path=".catdir($tfa_home,"resources")." -pattern=srdc_");
  tfactlshare_chmod("-perm=644 -path=".catdir($tfa_home,"resources","sql")." -pattern=.sql");
  tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"resources","tfactlhelp.xml"));
  tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"resources","tfactldbutlcmds.xml"));
  tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"resources","tfactldbutlschedule.xml"));
  if ( -f catfile($tfa_home, "resources", "tfa_emdirectories.txt") ) {
    tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"resources","tfa_emdirectories.txt"));
  }

  my $base_tfactl;
  if ($IS_WINDOWS){
    $base_tfactl = catfile($tfa_base, "bin", "tfactl.bat");
  } else {
    $base_tfactl = catfile($tfa_base, "bin", "tfactl");
  }
  tfactlshare_chmod("-perm=755 -path=".catfile($base_tfactl)) if ( -f "$base_tfactl");
  # print "done runExtracttoSetup\n";
} # end sub runExtracttoSetup


#========== runAutoSetup

sub runAutoSetup
{
	$BASEDIR = shift;
	$SILENT = shift;
	my $crshome = shift;
	$DEFERDISC = shift;
	my $localonly = shift;
	my $ohome = shift;
	my $obase = shift;
	my $RUNMODE = shift;
	my $discfile = shift;
        my $respfile = shift;
    
=head
        print "BASEDIR   $BASEDIR\n".
              "SILENT    $SILENT\n".
              "crshome   $crshome\n".
              "DEFERDISC $DEFERDISC\n".
              "localonly $localonly\n".
              "ohome     $ohome\n".
              "obase     $obase\n".
              "RUNMODE   $RUNMODE\n".
              "discfile  $discfile \n";
=cut
	
    dbg(DBG_WHAT, " opening $INSTLOGFILE for write \n");
	open $instlog, '>>', $INSTLOGFILE or print "Failed to open file $INSTLOGFILE";

	$SILENT = 0 if ( ! $SILENT );
	$DEFERDISC = 0 if ( ! $DEFERDISC );
	$localonly = 0 if ( ! $localonly );

	$DAEMON_OWNER = $current_user;

	if ( ! $crshome && ! $ohome ) {
		$INSTALL_TYPE = "TYPICAL";
	} elsif ( $ohome ) {
		$INSTALL_TYPE = "DB";
	} else {
   		$INSTALL_TYPE = "GI";
	}

	check_java_installation ($SILENT);

    dbg(DBG_NOTE, "Running Auto Setup for TFA as user $DAEMON_OWNER...\n\n");

	#if ( $current_user eq "root" ) {
    	#	dbg(DBG_NOTE, "Running Auto Setup for TFA as user $current_user...\n\n");
	#} else {
	#	dbg(DBG_NOTE, "TFA-00101: TFA setup is not running as the root user...\n");
	#	dbg(DBG_NOTE, "Non root setup will only allow for access to that users trace files\n");
	#	dbg(DBG_NOTE, "This will mean installing TFA for all users you wish to Analyze traces for\n"); 
	#	exit 1;
	#}

    if ( -d catfile("", "opt", "oracle", "opc") ) {
        $IS_RACDBCLOUD=TRUE;
    }

    if ( $INSTALL_TYPE ne "GI" && -f catfile("", "opt", "oracle", "oak", "bin", "oakd") ) {
	$IS_ODA=TRUE;
	$BASEDIR = "/opt/oracle/tfa" if ( ! $BASEDIR );
    }

    my $isDom = isODADom0();
    if ( $isDom == 1 ) {  
	$IS_ODADom0=TRUE;
	$BASEDIR = "/opt/oracle/tfa" if ( ! $BASEDIR );
    }

    if ( isExadataDom0 == 1 ) {
		$IS_EXADATADom0=TRUE;
        $BASEDIR = "/opt/oracle.tfa" if ( ! $BASEDIR );
    }

    my $install_option;
    dbg(DBG_VERB,"Silent: $SILENT, Local: $localonly and Defer Discovery: $DEFERDISC\n");

    if ( $localonly || $DEFERDISC || $IS_ODADom0 || $IS_EXADATADom0 ) {
        $install_option = "L";
	$ENV{RAT_LOCALONLY} = 1;
    } else {
	$install_option = "C";
    }

    if ( ! $SILENT && ! $localonly && ! $DEFERDISC && ! $IS_ODADom0  && ! $IS_EXADATADom0 ) {
	print "Would you like to do a [L]ocal only or [C]lusterwide installation ? [L|l|C|c] [C] : ";
	chomp( $install_option = <STDIN> );
	$install_option ||= "C";
	$install_option = get_valid_input ($install_option, "L|l|C|c", "C");

	if ( $install_option !~ /[Cc]/) {
		$ENV{RAT_LOCALONLY} = 1;
        }
    }

    if ( $install_option =~ /[Cc]/) {
	print "\nThe following installation requires temporary use of SSH.\n";
	print "If SSH is not configured already then we will remove SSH \n";
	print "when complete.\n  ";
    }

    if ( ! $SILENT &&  $install_option =~ /[Cc]/ ) {
	print "Do you wish to Continue ? [Y|y|N|n] [Y] ";
	chomp( my $continue = <STDIN> );
        $continue ||= "Y";
	$continue = get_valid_input ($continue, "Y|y|N|n", "Y");

	if ( $continue !~ /[Yy]/) {
		exit 1;
	}
    } 

    # TODO: Work out tfa_home -- ask right now
    
    dbg(DBG_NOTE, "Installing TFA now...\n");
    # girish: auto setup. install in same directory in all hosts
    
    my $localhost = tolower_host();
    my $tfa_home = catdir("$BASEDIR","tfa_home");
    my $local_tfa_home = $tfa_home; 	
    my $PERL = $ENV{PERL};

    #print "TFA_BASE: $BASEDIR\tTFA_Home: $tfa_home\n\n";
 
    dbg(DBG_WHAT, "Install Type : $INSTALL_TYPE\n");
    if ( $INSTALL_TYPE eq "GI" ) {
        dbg(DBG_WHAT, "Runnning CRS Discovery\n");
	crs_discovery ($crshome, $BASEDIR);
        if ( $IS_RACDBCLOUD ) {
           dbg(DBG_WHAT, "Runnning RACDBCLOUD Discovery\n");
           racdbcloud_discovery ();
        }
        if ( $IS_ODALITE ) {
	    dbg(DBG_WHAT, "Runnning RACDBCLOUD Discovery for ODA Lite\n");
	    racdbcloud_discovery ();
        }
    } elsif ( $INSTALL_TYPE eq "DB" ) {
	dbg(DBG_WHAT, "Runnning DB Discovery\n");
	db_discovery ($ohome, $obase, $BASEDIR);
    } elsif ( $DEFERDISC ) {
        dbg(DBG_WHAT, "Defering Discovery\n");
	defer_discovery ();
    } elsif ( $IS_ODADom0 ) {
        dbg(DBG_WHAT, "Runnning ODADom0 Discovery\n");
	odaDom0_discovery ();
    } elsif ( $IS_EXADATADom0 ) {
        dbg(DBG_WHAT, "Runnning EXADATADom0 Discovery\n");
	exadataDom0_discovery ();
    } else {
	dbg(DBG_WHAT, "Runnning TYPICAL Discovery\n");
	dbg(DBG_WHAT, "tfa_home : $tfa_home\n");
	dbg(DBG_WHAT, "discfile : $discfile\n");
	dbg(DBG_WHAT, "PERL     : $PERL\n");
	runDiscovery($tfa_home,$discfile,$PERL);
    }

    dbg(DBG_WHAT, "Confirming Discovery\n");
	confirmDiscovery($discfile);

	if ( -f "removed_directories.txt" ) {
		move("removed_directories.txt", catfile($tfa_home,"internal","removed_directories.txt"));
	}

	my $paramfile = catfile ($tfa_home, "tfa_setup.txt");
	my $discovery_results = "final_tfa_discovery.out";
	my $stack_status = "ora_stack_status.out";
	my $stack_status_pct = "ora_stack_status_pct.out";
        my $java_install = "java_install.out";

	chmod(0640,$discovery_results) if -f $discovery_results;
  	chmod(0640,$paramfile) if -f $paramfile;
  	chmod(0640,$stack_status) if -f $stack_status;
  	chmod(0640,$stack_status_pct) if -f $stack_status_pct;
  	chmod(0640,$java_install) if -f $java_install;

	dbg(DBG_WHAT,"Running AutoSetup for TFA_HOME $tfa_home on host $localhost\n");

	if ($IS_WINDOWS){
		# update usergroup list (as NT AUTHORITY\SYSTEM is unable to query the groups)
		my $win_user_group = catfile($tfa_home,"internal","win_user_groups.txt");
		if (-e $win_user_group){
			unlink $win_user_group;
		}
		system("net localgroup > $win_user_group");
	}

	# we have deployed locally and now need to get the setup file sorted
	# from the discovery.
        open(RF_DR,$discovery_results) or print "Failed to open $discovery_results"; 
        open(WF_PF,">>$paramfile") or print "Failed to open $paramfile";
	while(<RF_DR>) {
	  print WF_PF $_;
	}
	close(RF_DR); 
	close(WF_PF); 

	#Check if $BASEDIR=$CRS_HOME in case if its not a GI Install
	if ( $INSTALL_TYPE ne "GI" && $INSTALL_TYPE ne "DB" ) {
	    my $crs_home = get_crs_home($tfa_home);
	    my $oracle_base = get_oracle_base($tfa_home);
	    $BASEDIR = catdir($BASEDIR);

	    dbg(DBG_WHAT,"\nInside INSTALL_TYPE not equal to GI");
	    dbg(DBG_WHAT,"\nCRS_HOME: $crs_home");
	    dbg(DBG_WHAT,"\nORACLE_BASE: \"$oracle_base\"");
	    dbg(DBG_WHAT,"\nBASE_DIR: $BASEDIR");

	    my $crshome_cpy = $crs_home;
	    $crshome_cpy =~ s/\\/\\\\/g;
	    #print "CRS CPY = $crshome_cpy\n";

	    if ( length($oracle_base) == 0 && $crs_home && ( $BASEDIR =~ /^$crshome_cpy/ ) ) {
		dbg(DBG_WHAT,"\nBASEDIR [$BASEDIR] is under CRS_HOME [$crs_home]\n");
		$INSTALL_TYPE = "GI";

		if ( -f catfile($crs_home,"crs","install","crsconfig_params") ) {
		    open(RF, catfile($crs_home,"crs","install","crsconfig_params") );
		    while(<RF>) {
		        if ( /^ORACLE_BASE=(.*)/ ) {
	    		    $ORACLE_BASE = $1;
			    dbg(DBG_WHAT,"ORACLE_BASE inside BASEDIR=CRS_HOME is: $ORACLE_BASE\n");
		        }
		    }
		    close(RF);
	        }
	
		if ( ! -d "$ORACLE_BASE" ) {
		    # Get ORACLE_BASE using $crs_home/bin/orabase
		    dbg(DBG_WHAT, "Checking ORACLE_BASE using $crs_home/bin/orabase\n");
		    $ORACLE_BASE = qx($crs_home/bin/orabase);
		    $ORACLE_BASE = trim( $ORACLE_BASE );
		    dbg(DBG_WHAT, "Oracle Base: '$ORACLE_BASE'\n");
		}

		if ( -d "$ORACLE_BASE" ) {
		    my $outfile = catfile ($tfa_home, "tfa_setup.txt");
		    open (OUT, ">>$outfile") or die "Can't open file $outfile: $!\n";
		    print OUT "ORACLE_BASE=$ORACLE_BASE\n";
		    close OUT;
		} else {
		    dbg(DBG_NOTE, "\nTFA-00102: Unable to determine ORACLE_BASE. Exiting Installation now...\n");
		    exit 1;
		}
	    }
 	}
 
	if ( $INSTALL_TYPE eq "DB" ) {
	    my $outfile = catfile ($tfa_home, "tfa_setup.txt");
	    $ORACLE_BASE = $obase;
	    open (OUT, ">>$outfile") or die "Can't open file $outfile: $!\n";
	    print OUT "ORACLE_BASE=$ORACLE_BASE\n";
	    close OUT;
	}

  	tfactlshare_chmod("-path=$tfa_home -perm=750 -r");

	fixInitTfa($tfa_home);
	fixTfactl($tfa_home);
	tfactlshare_fixTfadiagnostics($tfa_home);
	fixExachk($tfa_home) if (isExadata());
	
	if ( $IS_WINDOWS ) {
		tfactlshare_chmodAddPerm(0111,catfile($tfa_home,"bin","tfactl.bat"));
	} else {
		tfactlshare_chmodAddPerm(0111,catfile($tfa_home,"bin","tfactl"));
	}

	tfactlshare_chmodAddPerm(0111,catfile($tfa_home,"install","init.tfa"));

	# Set NodeType in tfa_setup.txt 
	my $outfile = catfile ( $tfa_home, "tfa_setup.txt");
	open (OUT, '>>', $outfile) or die "Can't open file $outfile: $!\n";
	print OUT "TRACE_LEVEL=1\n";
	print OUT "INSTALL_TYPE=$INSTALL_TYPE\n";
	print OUT "DAEMON_OWNER=$DAEMON_OWNER\n";

    if ( ! $PERL ) {
	my $rc = eval {
            require File::Which;
            which("perl");
            1;
	};

	if ( $rc ) {
	    $PERL = which("perl");
	} else {
	    $PERL = "perl";
	}
    }
	print OUT "PERL=$PERL\n";

	my $TZ = $ENV{TZ};
	if ( $TZ ) {
		print OUT "TZ=$TZ\n";
	}
  
	my $isVMGuest = isODAVMGuest();
	if ( -f catfile("", "opt","oracle","oak","bin","oakd") && $isVMGuest == 0) {
            dbg(DBG_WHAT, "NODE_TYPE is ODA\n");
		print OUT "NODE_TYPE=ODA\n";
	}
 
	if ( $isVMGuest == 1 ) {   
        dbg(DBG_WHAT, "NODE_TYPE is ODAVMGuest\n");
		print OUT "NODE_TYPE=ODAVMGuest\n";  
	} 

	if ( $IS_ODADom0 ) {   
        dbg(DBG_WHAT, "NODE_TYPE is ODADom0\n");
		print OUT "NODE_TYPE=ODADom0\n";   
	}
  
    if ( $IS_EXADATADom0 ) {
        dbg(DBG_WHAT, "NODE_TYPE is ExadataDom0\n");
		print OUT "NODE_TYPE=ExadataDom0\n";
	}

	if ( $IS_RACDBCLOUD ) {
		dbg(DBG_WHAT, "NODE_TYPE is RACDBCLOUD\n");
		print OUT "NODE_TYPE=RACDBCLOUD\n";
	}
	
	my $TFA_ADE = $ENV{TFA_ADE};
	if ( $TFA_ADE eq "-ade" ) {
		dbg(DBG_WHAT, "INSTALLING in ADE env :: CSS_CLUSTER : $ENV{CSS_CLUSTERNAME}\n");
		print OUT "ADE_USER=$ENV{USER}\n";
		print OUT "NODE_TYPE=ADE\n";
		print OUT "CSS_CLUSTERNAME=$ENV{CSS_CLUSTERNAME}\n";

		# Add CRS_HOME ($ORACLE_HOME) if ocr.loc exists
		my $ocr_loc = $ENV{OCR_LOC};
		if ( -e "$ocr_loc" ) {
			print OUT "CRS_HOME=". $ENV{ORACLE_HOME} . "\n";
		}

		my $ADE_ORACLE_SID = $ENV{ORACLE_SID};
		my $ADE_SRCHOME = $ENV{SRCHOME};

		if ( $ADE_ORACLE_SID ) {
			print OUT "localnode\%RDBMS\.$ADE_ORACLE_SID\.$ADE_ORACLE_SID\%DIAGDEST\=$ADE_SRCHOME/log/diag\n";
			print OUT "localnode\%RDBMS\.$ADE_ORACLE_SID\.$ADE_ORACLE_SID\%DIAGDEST\=$ADE_SRCHOME/work\n";
		}
	}

	if ( $RUNMODE ) {
        dbg(DBG_WHAT, "INSTALLING in Receiver Mode");
		print OUT "RUN_MODE=receiver\n";
	}
	close OUT;
	# Create tfa_directories.txt from tfa_setup.txt
	copy(catfile($tfa_home,"directories.txt"), catfile($tfa_home,"tfa_directories.txt")) if ( -r catfile($tfa_home,"directories.txt"));

	open(TFASETUP, $outfile);
	open(TFADIR, ">>".catfile($tfa_home,"tfa_directories.txt"));
	print TFADIR grep(/\%DIAGDEST/, <TFASETUP>);
	close(TFASETUP);
	close(TFADIR); 
	#Exadata Support: 
	my $EXADATA_SETUP = isExadata();

	if ( $EXADATA_SETUP == 1 ) {
        dbg(DBG_WHAT, "Exadata Setup: Configure Cells unless GI install");
		# Do not configure Cells for Grid Install
		if ( $INSTALL_TYPE ne "GI" ) {
            dbg(DBG_WHAT, "Exadata Setup: Calling configureCells");
			configureCells( $tfa_home, $SILENT );
		}
	}

 	my $EXADATA_CONFIGURED = isExadataConfigured( $tfa_home );

	my $GIHOME = get_crs_home($tfa_home);
    dbg(DBG_WHAT, "Retrieved CRS HOME :  $GIHOME\n");

	# Get the file ownership of crsctl and assign the same to GIHOME/bin/tfactl
	my $GITFACTL;
	if ( $GIHOME ) {
		if ( $IS_WINDOWS ) {
			#TODO need to provide proper ownership to tfactl.bat file
	  	} else {
			my $crsctl = catfile($GIHOME, "bin", "crsctl");
			$GITFACTL = qx(ls -ld $crsctl | awk '{print "root:"\$4}');
			$GITFACTL = trim( $GITFACTL );
			dbg( DBG_WHAT, "Ownership of crsctl: \'$GITFACTL\'\n");
    	}
	}

	# Now deploy to all those hosts..
	doVars($paramfile);
	dbg( DBG_VERB, "TFA_HOME is currently : $tfa_home\n");
	dbg( DBG_VERB, "Hostnames :: $NODE_NAMES\n");
	dbg( DBG_VERB, "CRS HOME :: $GIHOME\n");

	my $genCert = 1;
	if ( $IS_ODADom0  || $IS_ODA ) {
		$genCert = 0;
	}
	if ( $INSTALL_TYPE eq "GI" && $install_option !~ /[Cc]/ ) {
		$genCert = 0;
	}
	if ( $GIHOME && $install_option !~ /[Cc]/ ) {
		$genCert = 0;
	}

	# get Java Home
	my $tfa_jhome;
	if ( -d catdir($tfa_home,"jre") ) {
        	$tfa_jhome = catdir($tfa_home,"jre");
	} elsif ( -f catfile($tfa_home, "tfa_setup.txt") ) {
        	$tfa_jhome = get_java_home($tfa_home);
    }

    if ( ! $tfa_jhome ) {
    	$tfa_jhome = get_java_home_defer();
    }

    if ( ! $tfa_jhome ) {
    	$tfa_jhome = catfile($tfa_home, "bin", "java");
    }

	if ( $genCert == 1 ) {
		dbg( DBG_WHAT , "Generating certificates\n");
        generateCerts($tfa_home, $tfa_jhome, 1);
    }

	my @nodes = split("\,",$NODE_NAMES);

	foreach (@nodes) {
		my $currenthost = $_;
		my $tfa_base = $BASEDIR;
		my $base_dir = $BASEDIR;

		if ( ! $IS_ODA && ! $IS_ODADom0 && ! $IS_EXADATADom0 ) {
			my $str1 = catfile("tfa",$localhost);
			my $str2 = catfile("tfa",$currenthost);
			$tfa_base =~ s/\Q$str1/$str2/g;
			$base_dir =~ s/\Q$str1/tfa/g;
		}
   
		my $tfa_home = catdir("$tfa_base","tfa_home");

		#print "TFA Home: $tfa_home\n";
		#print "Localhost: $localhost\nCurrent Host: $currenthost\n";
		#print "TFA BASE: $tfa_base\nBASE DIR: $base_dir\n";
		#print "BASEDIR: $BASEDIR\nIS ODA: $IS_ODA\n\n";

		dbg( DBG_NOTE, "\nInstalling TFA on $currenthost:\n");
		dbg( DBG_NOTE, "HOST: $currenthost\tTFA_HOME: $tfa_home\n");
		dbg( DBG_VERB, "Single host is :: $_\n");

		if ( $localhost =~ /$_/ ) {
	    	dbg( DBG_WHAT , "Already deployed to localhost  $_\n");

		    # Copy TFA_HOME/bin/tfactl to GIHOME/bin/
		    if ( $GIHOME ) {
				my $fileName;
				if ($IS_WINDOWS){
					$fileName = "tfactl.bat";
				} else {
					$fileName = "tfactl";
				}
				
				host_remote($currenthost,tfactlshare_get_cp_cmd(catfile($tfa_home,"bin",$fileName),catfile($GIHOME,"bin")));
				
				if ($IS_WINDOWS){
					#TODO need to provide proper ownership to tfactl.bat file
				} else {
					host_remote($currenthost,"chown $GITFACTL ".catfile($GIHOME,"bin",$fileName));
				}
		   }

	  	   # Create .<node>.shared under TFA_HOME on Localhost
		   my $TFAHOME_SHARED = catfile($tfa_home, ".$localhost.shared");
		   host_remote($currenthost, "$TOUCH $TFAHOME_SHARED");

		   # if GI_HOME install then move the database and log directories to 
		   # ORACLE_BASE/<hostName>/tfa
		   if ( $INSTALL_TYPE eq "GI" || $INSTALL_TYPE eq "DB" ) {
		      if (defined  $ORACLE_BASE) {
			my $db_dir = catdir($ORACLE_BASE, "tfa", $localhost, "database", "BERKELEY_JE_DB");
			dbg( DBG_WHAT ,"Creating database directory : $db_dir\n");
			mkpath($db_dir);
			my $log_dir = catdir($ORACLE_BASE, "tfa", $localhost, "log");
			dbg( DBG_WHAT ,"Creating log directory : $log_dir\n");
			mkpath($log_dir);
			my $output_dir = catdir($ORACLE_BASE, "tfa", $localhost, "output");
			dbg( DBG_WHAT ,"Creating Output directory : $output_dir\n");
			mkpath($output_dir);

			my $dbzip_dir = catdir($output_dir, "dbzip");
			dbg( DBG_WHAT ,"Creating dbzip directory : $dbzip_dir\n");
			mkpath($dbzip_dir);
	
			my $inventory_dir = catdir($output_dir, "inventory");
			dbg( DBG_WHAT ,"Creating Inventory directory : $inventory_dir\n");
			mkpath($inventory_dir);

			my $index_dir = catdir($output_dir, "index");
			dbg( DBG_WHAT ,"Creating Index directory : $index_dir\n");
			mkpath($index_dir);

			my $tracefiles_dir = catdir($output_dir, "tracefiles");
			dbg( DBG_WHAT ,"Creating Tracefiles directory : $tracefiles_dir\n");
			mkpath($tracefiles_dir);

			#create .<node>.shared under <ORACLE_BASE>/tfa for GI Install on Localhost.
			my $SHARED_FILE = catfile($ORACLE_BASE,"tfa",".$localhost.shared");
			dbg( DBG_WHAT ,"Creating Shared file to show shared fs : $SHARED_FILE\n");
		 	host_remote($currenthost, "$TOUCH $SHARED_FILE");
             	      }
		   }
 
			if ( $current_user eq "root" ) {
				dbg( DBG_VERB, "TFA_HOME is currently : $tfa_home\n");
				dbg( DBG_WHAT , "Starting TFA out of inittab on node  $_\n");

				if ( $IS_WINDOWS ) {
					#init entries are not required for windows.
					tfactlwin_start_tfa($local_tfa_home);
					sleep(10);
				} else {
					host_remote($_, "$CP ".catfile($local_tfa_home,"install","init.tfa")." $INITDIR");
					host_remote($_, catfile($INITDIR,"init.tfa")." start");
				}

				if ( ! $IS_ODA && ! $IS_ODADom0 && ! $IS_EXADATADom0 ) {
					if ( $IS_WINDOWS ) {
      					if (! -d catdir($base_dir, "bin")) {
      						mkpath(catdir($base_dir, "bin"));
      					}
						host_remote($currenthost, tfactlshare_get_cp_cmd(catfile($tfa_home,"bin","tfactl.bat"),catdir($base_dir,"bin")));
						fixBinTfaHome($currenthost, $base_dir, $base_dir, "bin", "tfactl.bat");  
				  	} else {
    						host_remote($currenthost, "$CP ".catfile($tfa_home,"bin","tfactl")." ".catdir($base_dir,"bin"));
	    					fixBinTfaHome($currenthost, $base_dir, $base_dir, "bin", "tfactl");
					}
				}
			} else {
				if ( $IS_WINDOWS ) {
					#TODO
				} else {
	    			host_remote($currenthost, "$CP ".catfile($tfa_home,"bin","tfactl")." ".catdir($base_dir,"bin"));
		    		fixBinTfaHome($currenthost, $base_dir, $base_dir, "bin", "tfactl");
					host_remote($currenthost, catfile($tfa_home, "bin", "tfactl") . " -initstart");
				}
			}
		   next;
		}

		deployTFA($tfa_base,$local_tfa_home,$currenthost);
    
		if ( ! $IS_ODA && ! $IS_ODADom0 && ! $IS_EXADATADom0 ) {
	           if ( $IS_WINDOWS ){
		     host_remote($currenthost,tfactlshare_get_cp_cmd(catfile($local_tfa_home,"bin","tfactl.bat"),catdir($base_dir,"bin")));
	             fixTfaHome($currenthost, $tfa_home, $local_tfa_home, "bin", "tfactl.bat");
	             fixBinTfaHome($currenthost, $base_dir, $base_dir, "bin", "tfactl.bat");
	           }else{
		     host_remote($currenthost,"$CP ".catfile($local_tfa_home,"bin","tfactl")." ".catdir($base_dir,"bin"));
	             fixTfaHome($currenthost, $tfa_home, $local_tfa_home, "bin", "tfactl");
	             fixTfaHome($currenthost, $tfa_home, $local_tfa_home, "install", "init.tfa");
	             fixBinTfaHome($currenthost, $base_dir, $base_dir, "bin", "tfactl");
	           }
		} else {
			copy_remote($_,catfile($local_tfa_home,"bin","tfactl"),catdir($tfa_home,"bin"));
			host_remote($_,"$CHMOD a+x ".catfile($tfa_home,"bin","tfactl"));
			copy_remote($_,catfile($local_tfa_home,"install","init.tfa"),catdir($tfa_home,"install"));
			host_remote($_,"$CHMOD a+x ".catfile($tfa_home,"install","init.tfa"));
		}
                if ( isExadata() ) {
		   dbg(DBG_WHAT, "\n\n Copying orachk to exachk on $currenthost in $tfa_home\n");
                   my $ochkpy = catfile($tfa_home,"ext","orachk","orachk.pyc");
                   my $echkpy = catfile($tfa_home,"ext","orachk","exachk.pyc");
                   my $ochk = catfile($tfa_home,"ext","orachk","orachk");
                   my $echk = catfile($tfa_home,"ext","orachk","exachk");
                   host_remote($currenthost,"$CP $ochk $echk"),
                   host_remote($currenthost,"$CP $ochkpy $echkpy"),
                }
		copy_remote($currenthost,catfile($local_tfa_home,"tfa_setup.txt"),"$tfa_home",catdir($local_tfa_home, "transfer_remote"));
		copy_remote($currenthost,catfile($local_tfa_home,"tfa_directories.txt"),"$tfa_home",catdir($local_tfa_home, "transfer_remote"));
		
		if(( -f catfile($local_tfa_home,"server.jks")) && ( -f catfile($local_tfa_home,"client.jks")) && ( -f catfile($local_tfa_home,"internal","ssl.properties"))){
		   dbg(DBG_WHAT, "\n\n $currenthost $local_tfa_home $tfa_home\n");
		   copy_remote($currenthost,catfile($local_tfa_home,"server.jks"),"$tfa_home",catdir($local_tfa_home, "transfer_remote"));
		   copy_remote($currenthost,catfile($local_tfa_home,"client.jks"),"$tfa_home",catdir($local_tfa_home, "transfer_remote"));
		   copy_remote($currenthost,catfile($local_tfa_home,"internal","ssl.properties"),catdir($tfa_home,"internal"),catdir($local_tfa_home, "transfer_remote"));
		}
		
		# Syncing receiver certificates and files to other nodes of cluster
		if(( -f catfile($local_tfa_home,"receiver","receiver.jks")) && ( -f catfile($local_tfa_home,"receiver","internal","r.ssl.properties"))){
		   dbg(DBG_WHAT, "\n\n $currenthost $local_tfa_home $tfa_home\n");
		   copy_remote($currenthost,catfile($local_tfa_home,"receiver","receiver.jks"),catfile($tfa_home,"receiver"),catdir($local_tfa_home, "transfer_remote"));
		   copy_remote($currenthost,catfile($local_tfa_home,"receiver","internal","r.ssl.properties"),catdir($tfa_home,"receiver","internal"),catdir($local_tfa_home, "transfer_remote"));
		}

		# Copy TFA_HOME/bin/tfactl to GIHOME/bin/
		if ( $GIHOME ) {
			if ($IS_WINDOWS) {
				host_remote($currenthost,"$CP ".catfile($tfa_home,"bin","tfactl")." ".catdir($GIHOME,"bin"));
				host_remote($currenthost,"takeown $GITFACTL ".catfile($GIHOME,"bin","tfactl"));
			} else {
				host_remote($currenthost,"cp -f ".catfile($tfa_home,"bin","tfactl")." ".catdir($GIHOME,"bin"));
				host_remote($currenthost,"chown $GITFACTL ".catfile($GIHOME,"bin","tfactl"));
			}
		}

		if ( -f catfile($local_tfa_home,"internal","removed_directories.txt" )) {
		   copy_remote($currenthost,catfile($local_tfa_home,"internal","removed_directories.txt"), catdir($tfa_home,"internal"),catdir($local_tfa_home, "transfer_remote"));
		}

		#EXADATA SUPPORT:
		if ( $EXADATA_CONFIGURED == 1 ) {
			copy_remote($currenthost,catfile($local_tfa_home,"internal","cellnames.txt"), catdir($tfa_home,"internal"));
			copy_remote($currenthost,catfile($local_tfa_home,"internal","cellips.txt"), catdir($tfa_home,"internal" ));

			if ( -d catdir($local_tfa_home, "internal", "tfawallet")) {
				my $qxCommand = "$SCP -r ".catdir($local_tfa_home,"internal","tfawallet")," $currenthost:".catdir($tfa_home,"internal");
				`$qxCommand`;
				#copy_remote($currenthost,"$local_tfa_home/internal/.wallet.pwd", "$tfa_home/internal" );
			}
		}

	    if ( $current_user eq "root" ) {
			if ( $IS_WINDOWS ) {
				# Unsetting PERL5LIB env variable on remote node
				`setx /s $currenthost PERL5LIB ""`;
				#init entries are not required for windows.
				tfactlwin_ssh_without_cred($currenthost, "cmd /c $PERL ".catfile($tfa_home, "bin", "tfaosutils.pl")." configureTFA start ".$tfa_home);
				print "Waiting for TFA to start on remote nodes...\n";
				sleep(30);
			} else {
				dbg( DBG_WHAT, "Starting TFA out of inittab on node  $_\n");
				host_remote($currenthost,"$CP ".catfile($tfa_home,"install","init.tfa")." $INITDIR");
				dbg( DBG_WHAT, "Command executed ".catfile($INITDIR,"init.tfa")."start\n");
				host_remote($currenthost,catfile($INITDIR,"init.tfa")." start");
			}
	    } else {
			if ( $IS_WINDOWS ) {
				#TODO
			} else {
				host_remote($currenthost, catfile($tfa_home, "bin", "tfactl") . " -initstart");
			}
	    }
	}
	

	# now the software is in place we can 
	# 1) if root then add init.tfa and start

	# TODO: Need to see if CRS is up on any of the nodesi, and add on the first
	# one we find to be runnign   ,, It it is not then all
	# we can do is write the command to a file and tell them to run it ..

	#if ( $current_user eq "root" ) {
		dbg (DBG_VERB, "TFA will be run out of init\n");
	#}
 
	# TODO - Make sure it is started OK before running the add hosts.
	# We could have fun here with the ports so we need to code the handshake 
	# to make sure we talk to the right host on the right port.
	sleep(5);

	@nodes = split("\,",$NODE_NAMES);

	if ( isTFARunning($tfa_home) == SUCCESS ) {
		foreach (@nodes) {   
			my $currenthost = $_;
			my $tfa_base = $BASEDIR;
			my $base_dir = $BASEDIR;

			if ( ! $IS_ODA && ! $IS_ODADom0 && ! $IS_EXADATADom0 ) {
				my $str1 = catfile("tfa",$localhost);
				my $str2 = catfile("tfa",$currenthost);
				$tfa_base =~ s/\Q$str1/$str2/g;
				$base_dir =~ s/\Q$str1/tfa/g;
			} 

			my $tfa_home = catdir("$tfa_base","tfa_home");

			dbg( DBG_VERB, "Single host is :: $currenthost\n");
			if( $localhost =~ /$currenthost/ ) {
				dbg( DBG_WHAT , "Already added localhost to DB - skipping $_\n");
				next;
			}
			my $qxCommand;
			my $remoteport;

			if ($IS_WINDOWS) {
				sleep(10);
				mkpath(catfile($local_tfa_home, "transfer_remote"));
				tfactlwin_remote_win_copy_without_cred($currenthost,catfile($tfa_home,"internal"),$localhost,catfile($local_tfa_home, "transfer_remote"));
				my @tmp = tfactlwin_readFileToArray(catfile($local_tfa_home, "transfer_remote", "port.txt"));
				$remoteport = $tmp[0];
				chomp($remoteport);
				#rmtree(catfile($local_tfa_home, "transfer_remote"));
			} else {
				$qxCommand = "$SSH $currenthost cat ".catfile($tfa_home,"internal","port.txt");
				$remoteport = `$qxCommand`;
			}

			dbg(DBG_VERB, "Port on which $currenthost is listening : $remoteport\n");
			addHost($local_tfa_home,$currenthost,0,$remoteport);

			if ( $current_user eq "root" ) {
				# Open File Permissions on remote nodes for Non-root Access
				host_remote($currenthost,catfile($tfa_home,"bin","tfactl")." access enable -local");

				# Add Default users on remote nodes for Non-root Access
				host_remote($currenthost,catfile($tfa_home,"bin","tfactl")." access adddefaultusers -local");
                        }
                        # if we specified a responsefile
                        if ( $respfile and -r $respfile ) {
                           # Copy responsefile to remote host and use it ..
                           dbg(DBG_VERB, "Copying responsefile to remote and setting config\n");
	         	   copy_remote($currenthost,"$respfile", "$tfa_home/internal" );
                           my $respfile_short = $respfile;
		           $respfile_short =~ s/.*\///;
			   host_remote($currenthost,"$CHMOD 600 $tfa_home/internal/$respfile_short") if (not $IS_WINDOWS);
			   host_remote($currenthost,catfile($tfa_home,"bin","tfactl")."  configfromresp $tfa_home/internal/$respfile_short");
                        }
  		}

		checkTFAStatusAbridged($tfa_home);
		dbg(DBG_VERB, "Setting TFA cookie in all nodes\n");
		generateTFACookie($tfa_home); 
  
		dbg(DBG_NOTE, "\nRunning Inventory in All Nodes...\n");
		runTFAInventory ($tfa_home,1,1);

		# Sync Wallet and Run Inventory on Storage Cells
		if ( $INSTALL_TYPE ne "GI" && $EXADATA_CONFIGURED == 1 ) {
			my $WALLET = checkWallet( $tfa_home );
			if ( $WALLET == 1 ) {
				dbg(DBG_NOTE, "\nSynchronizing TFA Wallet with Other Nodes...\n");
				syncWallet( $tfa_home );
			}

			dbg(DBG_NOTE, "\nRunning Inventory in Storage Cells...\n");
			runInventoryInCells($tfa_home);
		}
	} else {
		dbg ( DBG_NOTE , "TFA was not started properly\n" );
	}

	if ( $current_user eq "root" ) {
		addNonRootAccess( $local_tfa_home, "-l" );
		addDefaultAccessList( $local_tfa_home, "-l" );
	}

 	#Remove execute permissions on non-executalbe files
 	tfactlshare_chmodRemovePerm(0666,catdir($tfa_home));

	my $node_name;
	my @tfadirs;
	dbg(DBG_NOTE, "\nSummary of TFA Installation:\n");

	my @nodeList = split("\,",$NODE_NAMES);
	$Text::Wrap::columns = $tputcols-40;

	my $startOrachk = 0;
	if ( -f catfile($tfa_home, "ext", "orachk", "lib", "autostart") ) {
		if ( ! $ENV{'TFA_SKIP_ORACHK'} ) {
			$startOrachk = 1;
		}
	}

	foreach (@nodeList) {
		$node_name = $_;
		my $tfa_base = $BASEDIR;
		my $base_dir = $BASEDIR;

		if ( ! $IS_ODA && ! $IS_ODADom0 && ! $IS_EXADATADom0 ) {
			my $str1 = catfile("tfa",$localhost);
			my $str2 = catfile("tfa",$node_name);
			$tfa_base =~ s/\Q$str1/$str2/g;
			$base_dir =~ s/\Q$str1/tfa/g;
		}

		my $tfa_home = catdir($tfa_base,"tfa_home");

		my $rep_dir;
		if ( ! $IS_ODA && ! $IS_ODADom0 && ! $IS_EXADATADom0 ) {
			$rep_dir = catdir($base_dir, "repository");

			if ( $INSTALL_TYPE eq "GI" || $INSTALL_TYPE eq "DB" ) {
				if ( $ORACLE_BASE ) {
					#print "ORACLE_BASE before setting Repository: $ORACLE_BASE\n";
					$rep_dir = catdir($ORACLE_BASE, "tfa","repository");
				}
			}
		}
		else {
			$rep_dir = catdir($tfa_home, "repository");
		}
		
        	if ($localhost eq $node_name) {
			tfactlshare_check_trace($tfa_home,$current_user,$rep_dir);
			if ( not length $hostname ) {
				$hostname = tolower_host();
				$hostname = trim($hostname);
			}
			# Init tfa_ext_xml file
			$tfactlglobal_tfa_ext_xml = catfile($tfa_home, "ext", "tfaext.xml");
			%tfactlglobal_exttools = tfactlshare_read_ext_xml($tfa_home, $tfactlglobal_tfa_ext_xml);
			tfactlshare_setup_alltool_dir_for_user ($tfa_home, $current_user, $rep_dir); 

			if ( $startOrachk ) {
				tfactlshare_runOrachkDaemon($tfa_home, "start");
			}
        	} else {
			host_remote($node_name, catfile($tfa_home,"bin","tfactl")." access setuptracedir -user $current_user");

			if ( $startOrachk ) {
				my $orachk_command = "$SSH $node_name " . catfile($tfa_home,"bin","tfactl") . " startorachkdaemon > $DEVNULL 2>&1 &";
				dbg( DBG_HOST, "Running $orachk_command\n");
				qx($orachk_command);
			}
        	}

		my $col_width = length( $tfa_home );

		my $tb = Text::ASCIITable->new();
		$tb->setCols("Parameter", "Value");
		#$tb->setColWidth("Parameter", $tputcols-50);
		$tb->setColWidth("Value", $col_width);
		$tb->setOptions({"outputWidth" => $col_width, "headingText" => $node_name});
		$tb->addRow("Install location", $tfa_home);
		#@tfadirs = getTFADirectories($tfa_home, $node_name); 
		#if (scalar(@tfadirs) > 0) {
		#  $tb->addRow("Trace directories",wrap("","",@tfadirs[0]));
		#}
		#for (my $c=1; $c<scalar(@tfadirs); $c++) {
		#$tb->addRow("",wrap("","",@tfadirs[$c]));
		#}

		$tb->addRow("Repository location", "$rep_dir");
		my $repo = getCurrentRepository($local_tfa_home);
		if ( $repo ne FAILED ) {
			my $localnode = tolower_host();
			my $cmd;
			my $repousage;
			if ( $IS_WINDOWS ){
				if ($localnode =~ $node_name) {
					$repousage = int(osutils_du($repo,1)/1000000);
				} else {
					#TODO sending remote commands for windows needs to be figured out.
					#$cmd = "$SSH $node_name \"du -k $repo\"";
				}
			} else {
				if ($localnode =~ $node_name) {
					$cmd = "du -k $repo";
				} else {
					$cmd = "$SSH $node_name \"du -k $repo\"";
				}
	
				my @out = split(/\s/, `$cmd`);
				$repousage = int(@out[0]/1000);
			}
      
			my $repomaxsize = getRepositoryMaxSize($local_tfa_home);

			if ( $repomaxsize ne FAILED ) {
				$tb->addRow("Repository usage", "$repousage MB out of $repomaxsize MB");
			}
		} else {
			print "\nTFA-00102: Unable to create TFA Repository: $rep_dir. Exiting TFA Installation...\n";
			exit 1;
		}
		dbg(DBG_NOTE, $tb."\n");
	}

	# finally remove ssh - it should not happen if we did not set it up initially
	if ( ! $SILENT ) {
	    if ( ! $IS_WINDOWS ) {
			removeSSH($tfa_home);
	    }
	}
    	close $instlog;
	add_to_scanned_dbs($tfa_home, catfile("$tfa_home", "tfa_setup.txt"));
}


#
# Subroutine to check if current user is TFA Admin
#
sub tfactlshare_isAdminUser {
	my $status = 0;
	if ( $DAEMON_OWNER eq $current_user ) {
		$status = 1;
	}
	return $status;
}

#
# Subroutine to get TFA Daemon Owner
#
sub tfactlshare_getTFADaemonOwner {
	my $tfa_home = shift;
	my $owner = "root";

	open (RF, catfile($tfa_home, "tfa_setup.txt")) || die "Cant open ".catfile($tfa_home,"tfa_setup.txt")."\n";

	while(<RF>) {
		chomp;
		if ( /^DAEMON_OWNER=(.*)/ ) {
			$owner = $1;
			last;
		}
	}
	close(RF);

	$owner = trim($owner);

	if ( $owner ne "root" ) {
		$IS_NON_ROOT_DAEMON = 1;
	}

	return $owner;
}

# Function to add access to non-root users

sub addNonRootAccess {
	my $tfa_home = shift;
	my $clusterwide = shift;
	my $localhost = tolower_host();
        my $repodir = tfactlshare_get_repository_location($tfa_home);

	my $status = checkNonRootAccess( $tfa_home );

	if ( $status == 1 ) {
		print "\nTFA has already enabled access for Non-root Users.\n";
		return;
	}

	print "\nEnabling Access for Non-root Users on $localhost...\n";

	my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");

	# Check permissions of directory above TFA_BASE
	my $tfa_base = $tfa_home; 
	if ( $IS_ODA && $install_type ne "GI" ) {
           $tfa_base = catdir("","opt","oracle");
        }
	$tfa_base =~ s/(\/|\\)tfa(\/|\\)$localhost(\/|\\)tfa_home//;
	my $perm = sprintf "%o", (stat($tfa_base))[2] & 07777;
	if ( $perm lt "751" ) {
		print "\nPlease add world execute permissions for all directories above $tfa_base to enable TFA Non-Root Access\n";
	}
	$tfa_base = catfile($tfa_base, "tfa");

	# Set permissions for Directories:
        tfactlshare_chmod("-perm=751 -path=$tfa_base"); # required in case root user umask not 022
        tfactlshare_chmod("-perm=751 -path=".catdir($tfa_base,$localhost)) if (-e catdir($tfa_base,$localhost)); # reqd if root user umask not 022
	tfactlshare_chmod("-perm=751 -path=$tfa_home");
	tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home,"bin"));
	tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home,"internal"));
	tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"internal","dbparams")) if (-e catdir($tfa_home,"internal","dbparams"));
  tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home,"jlib"));
	tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home,"bin","common"));
	tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"bin","modules"));
	tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"bin","scripts"));
	tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home,"bin","common","exceptions"));
	tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home,"bin","Text"));
	tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home,"bin","Text","ASCIITable"));
	tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home,"ext"));
	tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"ext")." -r");
	tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"resources"));
        tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"resources","sql"));

	my $database = catdir( $tfa_home, "database");
	my $outputdir = catfile ( $tfa_home, "output");
	if ( $install_type eq "GI" || $install_type eq "DB" ) {
		my $oracle_base = get_oracle_base($tfa_home);
		my $oracle_base_tfa = catdir($oracle_base,"tfa");
		tfactlshare_chmod("-perm=751 -path=".catdir($oracle_base_tfa));
                tfactlshare_chmod("-perm=751 -path=".catdir($oracle_base,"tfa",$localhost)); # umask not 022
		$outputdir = catdir ($oracle_base,"tfa",$localhost,"output");
		$database = catdir($oracle_base,"tfa",$localhost, "database");
	}
        tfactlshare_chmod("-perm=700 -path=".catdir($database)." -r");
        tfactlshare_chmod("-perm=751 -path=".catdir($outputdir));
        tfactlshare_chmod("-perm=751 -path=".catdir($outputdir,"inventory"));
        tfactlshare_chmod("-perm=700 -path=".catdir($outputdir,"index"));

	# Permissions for metadata directory for timeline
        if ( -d catdir($outputdir,"metadata" ) ) {
	    tfactlshare_chmod("-perm=751 -path=".catdir($outputdir,"metadata")." -r");
	    tfactlshare_chmod("-perm=644 -path=".catdir($outputdir,"metadata")." -pattern=.out");
	    tfactlshare_chmod("-perm=644 -path=".catdir($outputdir,"metadata")." -pattern=.out.mv");
        }

	# Permissions for TFA JAVA
	if ( -d catdir($tfa_home,"jre") ) {
		tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home,"jre"));
		tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"jre","bin")." -r");
		tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"jre","lib")." -r");
	}

	# Permissions for TFA PERL
	if ( -d catdir($tfa_home, "perl") ) {
		tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home, "perl"));
		tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home, "perl", "bin")." -r");
		tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home, "perl", "lib")." -r");
	}

	my $repodir = getCurrentRepository( $tfa_home );

	if ( -d "$repodir" ) {
		tfactlshare_chmod("-perm=1755 -path=".catdir($repodir));
	}

	# Set Permissions for files:
	tfactlshare_chmod("-perm=755 -path=".catfile($tfa_home,"bin","tfactl"));
	tfactlshare_chmod("-perm=755 -path=".catfile($tfa_home,"bin","tfactl.pl"));
        if ( -f catfile($tfa_home,"bin","tfa_upload_files.pl") ) {
	  tfactlshare_chmod("-perm=755 -path=".catfile($tfa_home,"bin","tfa_upload_files.pl"));
        }
	tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"bin","common")." -pattern=.pm");
	tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"bin","modules")." -pattern=.pm");	
	tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"bin","scripts")." -pattern=.pm");	
	tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"bin","scripts")." -pattern=.pl");	
	tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"bin","common","exceptions")." -pattern=.pm");
	tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"tfa_setup.txt"));
	tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"tfa_directories.txt"));
	tfactlshare_chmod("-perm=600 -path=".catfile($tfa_home,"public.jks"));
	tfactlshare_chmod("-perm=600 -path=".catfile($tfa_home,"tfa.jks"));
	tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"internal","NonRootport.txt"));
	tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"internal","port.txt"));
	tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"internal","runstatus.txt"));
	tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"internal","dbversions.json"));
	tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"internal",".pidfile"));
	tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"internal",".buildid"));
	tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"internal",".buildversion"));
	tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"internal","config.properties"));
	tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"internal","config.properties.old"));
	tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"internal","cached_kv.out"));
	tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"internal","timezones_mapping"));
	tfactlshare_chmod("-perm=600 -path=".catfile($tfa_home,"internal","smtp.properties"));
        # Ensure .ser files in the internal directory can be read by all users after patching.
	tfactlshare_chmod("-perm=644 -path=".catdir($tfa_home,"internal")." -pattern=.ser");
	tfactlshare_chmod("-perm=644 -path=".catdir($tfa_home,"jlib")." -pattern=.jar");
	tfactlshare_chmod("-perm=755 -path=".catfile($tfa_home,"bin","Text","ASCIITable.pm"));
	tfactlshare_chmod("-perm=755 -path=".catfile($tfa_home,"bin","Text","ASCIITable","Wrap.pm"));
	tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"bin","Date")." -r");
	tfactlshare_chmod("-perm=755 -path=".catdir($tfa_home,"bin","Term")." -r");
	tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"resources","components.xml"));
	tfactlshare_chmod("-perm=644 -path=".catdir($tfa_home,"resources")." -pattern=srdc_");
	tfactlshare_chmod("-perm=644 -path=".catdir($tfa_home,"resources","sql")." -pattern=.sql");
	tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"resources","tfactlhelp.xml"));
	tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"resources","tfactldbutlcmds.xml"));
	tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"resources","tfactldbutlschedule.xml"));

	if( -f catfile($tfa_home,"resources","tfa_emdirectories.txt")) {
	        tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"resources","tfa_emdirectories.txt"));
	}
	if(-f catfile($outputdir,"inventory","inventory.xml")){
		tfactlshare_chmod("-perm=644 -path=".catfile($outputdir,"inventory","inventory.xml"));
	}
	my $base_tfactl;
	if($IS_WINDOWS){
		$base_tfactl = catfile($tfa_base, "bin", "tfactl.bat");
	}else{
		$base_tfactl = catfile($tfa_base, "bin", "tfactl");
	}
	tfactlshare_chmod("-perm=755 -path=".catfile($base_tfactl)) if ( -f "$base_tfactl");

	my $crs_home = get_crs_home($tfa_home);
	my $crs_tfactl;
	if($IS_WINDOWS){
		$crs_tfactl = catfile($crs_home, "bin", "tfactl.bat");
	}else{
		$crs_tfactl = catfile($crs_home, "bin", "tfactl");
	}
	tfactlshare_chmod("-perm=755 -path=".catfile($crs_tfactl)) if ( -f "$crs_tfactl");

	# Add access on other nodes
	if ( $clusterwide eq "-c" ) {

		my @hostlist = getListOfOtherNodes( $tfa_home );
		my $tfa_base = $tfa_home;
		my $remote_home;
		my $remote_node;

		if ( $tfa_base =~ /(\/||\\)$localhost(\/||\\)tfa_home/ ) {
			$tfa_base =~ s/(\/||\\)$localhost(\/||\\)tfa_home//;
		}

		foreach $remote_node ( @hostlist ) {
			print "\nEnabling Access for Non-root Users on $remote_node...\n";
			$remote_home = catdir($tfa_base,$remote_node,"tfa_home");
			my $qxCommand = catfile($tfa_base,"bin","tfactl")." executecommand $remote_node \"".catfile($tfa_base,"bin","tfactl")." access enable -local\"";
			qx($qxCommand);
		}
	}
}

# Returns 1 if already the permissions are opened up else 0.

sub checkNonRootAccess {

	my $tfa_home = shift;

	# For permission 750, stat is 33256
	# For permission 755, stat is 33261
	
	my $status = 1;	
	my $file = catfile($tfa_home, "bin", "tfactl.pl");

	if ( -f $file ) {
		my $perm = (stat($file))[2];

		if ( $perm == 33256 ) {
			$status = 0;
		} 
	}

	return $status;
}

# Update permissions of TFA certificates:
sub updateSSLPermissions {
	my $tfa_home = shift;
	tfactlshare_chmod("-perm=600 -path=".catfile($tfa_home,"server.jks")) if ( -f catfile($tfa_home,"server.jks"));
	tfactlshare_chmod("-perm=600 -path=".catfile($tfa_home,"client.jks")) if ( -f catfile($tfa_home,"client.jks"));
	tfactlshare_chmod("-perm=600 -path=".catfile($tfa_home,"receiver","receiver.jks")) if ( -f catfile($tfa_home,"receiver","receiver.jks"));
	tfactlshare_chmod("-perm=600 -path=".catfile($tfa_home,"server_pub.crt")) if ( -f catfile($tfa_home,"server_pub.crt"));
	tfactlshare_chmod("-perm=600 -path=".catfile($tfa_home,"client_pub.crt")) if ( -f catfile($tfa_home,"client_pub.crt"));
	tfactlshare_chmod("-perm=600 -path=".catfile($tfa_home,"receiver","receiver_pub.crt")) if ( -f catfile($tfa_home,"receiver","receiver_pub.crt"));
	tfactlshare_chmod("-perm=600 -path=".catfile($tfa_home,"receiver","internal","r.ssl.properties")) if ( -f catfile($tfa_home,"receiver","internal","r.ssl.properties"));
	tfactlshare_chmod("-perm=600 -path=".catfile($tfa_home,"internal","ssl.properties")) if ( -f catfile($tfa_home,"internal","ssl.properties"));
	if ( -d catdir($tfa_home,"internal",".root")) {
		tfactlshare_chmod("-perm=700 -path=".catdir($tfa_home,"internal",".root"));
		tfactlshare_chmod("-perm=400 -path=".catdir($tfa_home,"internal",".root")." -pattern=_mykey");
	}
}

# Update permissions of TFA user keys :
sub updateKeyPermissions {
	my $tfa_home = shift;
	my $localhost = tolower_host();
	my $actionmessage = "$localhost:listtfausers:-l\n";
	my $command = buildCLIJava($tfa_home,$actionmessage);
	my $line;
	my $username;
	my $usertype;
	my @list;
	my @cli_output = tfactlshare_runClient($command);
	foreach $line ( @cli_output ) {
		if ( $line =~ /!/ ) {
			@list = split( /!/, $line );
			$username = $list[1];
			$usertype = $list[2];

			if ( lc($usertype) eq "user" ) {
				tfactlshare_chmod("-perm=700 -path=".catdir($tfa_home,".$username")." -r") if ( -d catdir($tfa_home,".$username") );
			}
		}
	}
}

#
# Function to check and update access for non-root users
# Description: This will update the permissions of new files/libraries
# for Non-root Access if enabled after patching TFA
#
sub updateNonRootAccess {
	my $tfa_home = shift;
	my $clusterwide = shift;
	my $localhost = tolower_host();
        my $actionmessage;
	my $command;
	my $line;

	my $status = checkNonRootAccess( $tfa_home );

	# Update the permissions of tfa_home
	tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home)." -r");

	# If enabled, then update the permissions for non-root access
	if ( $status == 1 ) {
		addNonRootAccess($tfa_home, $clusterwide);
	}

	updateSSLPermissions($tfa_home);

	$actionmessage = "$localhost:createuserkey\n";
        $command = buildCLIJava($tfa_home,$actionmessage);
	my @cli_output = tfactlshare_runClient($command);
        foreach $line ( @cli_output ) {
                if ( $line eq "SUCCESS" ) {
                        #$status = 1;
                } elsif ( $line eq "FAIL" ) {
		     print "\nFailed to add access for Non-root users\n";
		}
        }

	updateKeyPermissions($tfa_home);

 	# Remove execute permissions on non-executalbe files
 	tfactlshare_chmodRemovePerm(0666, catdir($tfa_home));

	# Update access on other nodes
	if ( $clusterwide eq "-c" ) {

		my @hostlist = getListOfOtherNodes( $tfa_home );
		my $tfa_base = $tfa_home;
		my $remote_home;
		my $remote_node;

		if ( $tfa_base =~ /(\/|\\)$localhost(\/|\\)tfa_home/ ) {
			$tfa_base =~ s/(\/|\\)$localhost(\/|\\)tfa_home//;
		}

		foreach $remote_node ( @hostlist ) {
			print "\nUpdating Access for Non-root Users on $remote_node...\n";
			$remote_home = catdir($tfa_base,$remote_node,"tfa_home");
			my $qxCommand = catfile($tfa_home,"bin","tfactl")." executecommand $remote_node \"".catfile($remote_home,"bin","tfactl")." access update -local\"";
			qx($qxCommand);
		}
	}	
}

# Function to remove access to non-root users
sub removeNonRootAccess {
	my $tfa_home = shift;
	my $clusterwide = shift;
	my $localhost = tolower_host();
        my $repodir = tfactlshare_get_repository_location($tfa_home);

	my $status = checkNonRootAccess( $tfa_home );

        if ( $status == 0 ) {
                print "\nTFA has already disabled access for Non-root Users\n";
                return;
        }

	print "\nDisabling Access for Non-root Users on $localhost...\n";

	my $tfa_base = $tfa_home;
	$tfa_base =~ s/\/$localhost\/tfa_home//;

	# Set permissions for Directories:
	tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home));
	tfactlshare_chmod("-perm=751 -path=".catdir($tfa_home,"bin"));
	tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"internal"));
	tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"jlib"));
	tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"bin","common"));
	tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"bin","modules"));
	tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"bin","scripts"));
	tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"bin","common","exceptions"));
	tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"bin","Text"));
	tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"bin","Text","ASCIITable"));
	tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"ext"));
	tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"ext")." -r");
	tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"resources"));
	tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"resources","sql"));

	my $outputdir = catfile ( $tfa_home, "output");
	my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");
	if ( $install_type eq "GI") {
	  $outputdir = catfile ( get_oracle_base($tfa_home), "tfa", $localhost, "output");
	}
	tfactlshare_chmod("-perm=750 -path=".catdir($outputdir));
	tfactlshare_chmod("-perm=750 -path=".catdir($outputdir,"inventory"));

	# Permissions for metadata directory for timeline
        if ( -d catdir($outputdir,"metadata" ) ) {
	    tfactlshare_chmod("-perm=750 -path=".catdir($outputdir,"metadata"));
        }

	# Permissions for TFA JAVA
	if ( -d catdir($tfa_home, "jre") ) {
		tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"jre"));
		tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"jre","bin")." -r");
		tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"jre","lib")." -r");
	}

	# Permissions for TFA PERL
	if ( -d catdir($tfa_home, "perl") ) {
		tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home, "perl"));
		tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home, "perl", "bin")." -r");
		tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home, "perl", "lib")." -r");
	}

	my $repodir = getCurrentRepository( $tfa_home );

        if ( -d "$repodir" ) {
        	tfactlshare_chmod("-perm=1755 -path=".catdir($repodir));
        }

	# Set Permissions for files:
	if($IS_WINDOWS){
		tfactlshare_chmod("-perm=751 -path=".catfile($tfa_home,"bin","tfactl.bat"));
	}else{
		tfactlshare_chmod("-perm=751 -path=".catfile($tfa_home,"bin","tfactl"));
	}
	tfactlshare_chmod("-perm=750 -path=".catfile($tfa_home,"bin","tfactl.pl"));
        if ( -f catfile($tfa_home,"bin","tfa_upload_files.pl") ) {
	  tfactlshare_chmod("-perm=750 -path=".catfile($tfa_home,"bin","tfa_upload_files.pl"));
        }
	tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"bin","common")." -pattern=.pm");
	tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"bin","modules")." -pattern=.pm");
	tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"bin","scripts")." -pattern=.pm");
	tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"bin","scripts")." -pattern=.pl");
	tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"bin","common","exceptions")." -pattern=.pm");
	tfactlshare_chmod("-perm=640 -path=".catfile($tfa_home,"tfa_setup.txt"));
	tfactlshare_chmod("-perm=640 -path=".catfile($tfa_home,"tfa_directories.txt"));
	tfactlshare_chmod("-perm=600 -path=".catfile($tfa_home,"public.jks"));
	tfactlshare_chmod("-perm=600 -path=".catfile($tfa_home,"tfa.jks"));
	tfactlshare_chmod("-perm=640 -path=".catfile($tfa_home,"internal","NonRootport.txt"));
	tfactlshare_chmod("-perm=640 -path=".catfile($tfa_home,"internal","port.txt"));
	tfactlshare_chmod("-perm=640 -path=".catfile($tfa_home,"internal","runstatus.txt"));
  	tfactlshare_chmod("-perm=640 -path=".catfile($tfa_home,"internal","dbversions.json"));
	tfactlshare_chmod("-perm=640 -path=".catfile($tfa_home,"internal","config.properties"));
	tfactlshare_chmod("-perm=640 -path=".catfile($tfa_home,"internal","config.properties.old"));
	tfactlshare_chmod("-perm=640 -path=".catfile($tfa_home,"internal","cached_kv.out"));
	tfactlshare_chmod("-perm=640 -path=".catfile($tfa_home,"internal","timezones_mapping"));
	tfactlshare_chmod("-perm=640 -path=".catfile($tfa_home,"internal",".pidfile"));
	tfactlshare_chmod("-perm=750 -path=".catdir($tfa_home,"jlib")." -pattern=.");
	tfactlshare_chmod("-perm=750 -path=".catfile($tfa_home,"bin","Text","ASCIITable.pm"));
	tfactlshare_chmod("-perm=750 -path=".catfile($tfa_home,"bin","Text","ASCIITable","Wrap.pm"));
	tfactlshare_chmod("-perm=640 -path=".catfile($tfa_home,"resources","components.xml"));
	tfactlshare_chmod("-perm=640 -path=".catfile($tfa_home,"resources")." -pattern=srdc_*xml");
	tfactlshare_chmod("-perm=640 -path=".catfile($tfa_home,"resources","sql")." -pattern=*sql");
  tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"resources","tfactlhelp.xml"));
  tfactlshare_chmod("-perm=640 -path=".catfile($tfa_home,"resources","tfactldbutlcmds.xml"));
  tfactlshare_chmod("-perm=640 -path=".catfile($tfa_home,"resources","tfactldbutlschedule.xml"));

	if ( -f catfile($tfa_home,"resources","tfa_emdirectories.txt")) {
		tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"resources","tfa_emdirectories.txt"));
	}
	if( -f catfile($outputdir,"inventory","inventory.xml")){
		tfactlshare_chmod("-perm=640 -path=".catfile($outputdir,"inventory","inventory.xml"));
	}
	
	my $base_tfactl;
	if($IS_WINDOWS){
		$base_tfactl = catfile($tfa_base, "bin", "tfactl.bat");
	}else{
		$base_tfactl = catfile($tfa_base, "bin", "tfactl");
	}
	tfactlshare_chmod("-perm=751 -path=".catfile($base_tfactl)) if ( -f "$base_tfactl");

	# Remove access on other nodes
	if ( $clusterwide eq "-c" ) {

		my @hostlist = getListOfOtherNodes( $tfa_home );
		my $tfa_base = $tfa_home;
		my $remote_home;
		my $remote_node;

		if ( $tfa_base =~ /(\/|\\)$localhost(\/|\\)tfa_home/ ) {
			$tfa_base =~ s/(\/|\\)$localhost(\/|\\)tfa_home//;
		}

		foreach $remote_node ( @hostlist ) {
			print "\nDisabling Access for Non-root Users on $remote_node...\n";
			$remote_home = catdir($tfa_base,$remote_node,"tfa_home");
			my $qxCommand = catfile($tfa_home,"bin","tfactl")." executecommand $remote_node \"".catfile($remote_home,"bin","tfactl")." access disable -local\"";
			qx($qxCommand);
		}
	}
}

# Function to check user accessibility
sub checkUserAccess {
        my $tfa_home = shift;

        my @details;
        if ($IS_WINDOWS)
        { 
          @details = tfactlshare_get_user( $< );
        } 
         else 
        { 
          @details = getpwuid( $< ); 
        }
        my $username = $details[0];
        #my $userid = $details[2];
        #my $usergrpid = $details[3];
        my $usergrpname;

        if($IS_WINDOWS){
        	$usergrpname = "";
        }else{
			$usergrpname = getgrgid( $details[3] );
        }

        my $localhost = tolower_host();
        my $actionmessage;
        my $command;
        my $line;

	my $useraccess = 0;

        $actionmessage = "$localhost:checkuseraccess:$username:$usergrpname\n";
        $command = buildCLIJava($tfa_home,$actionmessage);
	my @cli_output = tfactlshare_runClient($command);
        foreach $line ( @cli_output ) {
		if ( $line eq "ACCESS GRANTED" ) {
			$useraccess = 1;
			last;
		} elsif ( $line eq "FAIL" ) {
			$useraccess = 2;
			last;
		}
        }

	if ( $useraccess == 2 ) {
		print "TFA-00002 : Oracle Trace File Analyzer (TFA) is not running\n";
		print "Please start Oracle Trace File Analyzer (TFA) before running tfactl commands\n";
		exit 1;
	}

	if ( $useraccess == 0 ) {
		print "\nUser \'$username\' does not have permissions to run tfactl. Please check with TFA Admin(root).\n\n";
		exit 1;
	}

	return $useraccess;
}

# Subroutine to check TFA access for Non-root user on remote node
# Returns 1 if success else 0

sub checkUserAccessOnRemote {

	my $tfa_home = shift;
	my $remotenode = shift;
	my $username = shift;
	my $groupname = shift;

	if ( ! $username ) {
		my @details ;
                if ($IS_WINDOWS)
                {
                  @details = tfactlshare_get_user( $< );
                  $groupname = "";
                }
                 else
                {
                  @details = getpwuid( $< );
                  $groupname = getgrgid( $details[3] );
                }
		$username = $details[0];
	}

	my $localhost = tolower_host();
	my $actionmessage;
	my $command;
	my $line;

	my $useraccess = 0;

	$actionmessage = "$localhost:checkaccessonremote:$remotenode:$username:$groupname\n";
	$command = buildCLIJava($tfa_home,$actionmessage);
	my @cli_output = tfactlshare_runClient($command);
	foreach $line ( @cli_output ) {
		if ( $line eq "SUCCESS" ) {
			$useraccess = 1;
			last;
		} elsif ( $line =~ /TFA is not yet secured to run all commands/ ) {
			$useraccess = 2;
			last;
		}
	}

	return $useraccess;
}

sub addDefaultAccessList {

	my $tfa_home = shift;
	my $isLocal = shift;
        my $localhost = tolower_host();
        my $actionmessage;
        my $command;
        my $line;
	my $status = 0;

        # init trace dirs if needed
        tfactlshare_init_trace($tfa_home);

        $actionmessage = "$localhost:defaultusers:$isLocal\n";
        $command = buildCLIJava($tfa_home,$actionmessage);
	my @cli_output = tfactlshare_runClient($command);
        foreach $line ( @cli_output ) {
                if ( $line eq "SUCCESS" ) {
			$status = 1;
		}
        }

	if ( $status == 1 ) {
		print "\nAdding default users to TFA Access list...\n";
	}
}

###############################################################
# NAME
#   tfactlshare_printSmtpproperties
#
# DESCRIPTION
#   Subroutine to print SMTP Properties in tabular format
#
# PARAMETERS
#   tfa_home - TFA HOME
#   smtp hash - hash containing smtp properties (optional)
#
###############################################################
sub tfactlshare_printSmtpProperties {
	my $tfa_home = shift;
	my $ref = shift;
	my %data = ();

	$ref = tfactlshare_getSmtpProperties($tfa_home) if ( ! $ref );
	%data = %{$ref};
	printHashAsTable(\%data, "SMTP Server Configuration");
}

###############################################################
# NAME
#   tfactlshare_getSmtpProperties
#
# DESCRIPTION
#   Subroutine to get SMTP Properties in hash
#
# PARAMETERS
#   tfa_home - TFA HOME
#
# RETURNS
#   Hash containing SMTP Properties
#
###############################################################
sub tfactlshare_getSmtpProperties {
	my $tfa_home = shift;
	my $properties = catfile($tfa_home, "internal", "smtp.properties");

	if ( ! -f "$properties" ) {
		print "SMTP Properties not found\n";
		return;
	}

	my %data = ();
	my ($line, $key, $value);
	open(SMTP, "<", $properties) or return "Couldn't open file smtp.properties : $!\n";
	while(<SMTP>) {
		chomp($_);
		$line = $_;
		($key, $value)  = split(/=/, $line);
		$value = "-" if ( ! $value );
		$value = "*******" if ($key eq "smtp.password");
		$data{$key} = $value;
	}
	close(SMTP);
	return \%data;
}

###############################################################
# NAME
#   tfactlshare_runOrachkDaemon
#
# DESCRIPTION
#   Subroutine to start or stop  Orachk Daemon
#
# PARAMETERS
#   tfa_home - TFA HOME
#   arg - start or stop Orachk Daemon
#   log - Log File to store the output of command
#
###############################################################
sub tfactlshare_runOrachkDaemon {

	my $tfa_home = shift;
	my $arg = shift;
	my $log = shift;

	my $pid = fork;
	return if $pid;

	my $autostart = catfile($tfa_home, "ext", "orachk", "lib", "autostart");

	if ( -f "$autostart" ) {
		my $action;
		if ( $arg eq "start" || $arg eq "stop" ) {
			$action = $arg;
		} else {
			print "Invalid option for Orachk Autostart : $arg\n";
			exit -1;
		}

  		my $hostname = tolower_host();
		my $config = catfile($tfa_home, "internal", "config.properties");
		my $repository = tfactlshare_getConfigValue($config, "repository");
		my $output = catdir($repository, "suptools", $hostname, "orachk", $current_user);

		if ( ! -d "$output" ) {
			mkpath($output);
		}

		if ( ! -f "$log" ) {
			$log = catfile($output, "tfa_orachk_daemon_" . $action . "_" . $$ . ".log");
		}

		qx(echo "Started at : `date`" >> $log);
		
		$ENV{"RAT_OUTPUT"} = $output;
		$ENV{"RAT_DISABLE_STALENESS_VALIDATION"} = 1;
		$ENV{"RAT_INSTALLATION_LOC"} = catdir($tfa_home, "ext", "orachk");
		$ENV{"RAT_PURGE_SIZE"} = 4096;
		qx($autostart $action >> $log 2>&1);
		my $status = $?;

		qx(echo "Completed at : `date`" >> $log);
		qx(echo "Command : $autostart, Action : $action, Exit Status : $status" >> $log);
	}
	exit;
}

sub tfactlshare_getConfigValue {
  my $configfile = shift;
  my $parameter = shift;
  my $value;
  my $line;

  open ( CONFIG, "<$configfile" );
  while ( <CONFIG> ) {
    $line = $_;
    chomp($line);
    if ( $line =~ /^$parameter=(.*)/ ) {
      $value = $1;
      last;
    }
  }
  if ($value) {
    $value =~ s/\\\\/\\/g;
    $value =~ s/\\:/:/g;
    $value =~ s/\\=/=/g;
  }
  close (CONFIG);
  return $value;
}

sub tfactlshare_checksu {
  my $requser = shift;
  my $cmd     = shift;
  my $double  = shift;

  if ( ($current_user eq "root") && (not $IS_WINDOWS) ) {
    if ( $double ) {
       return "su $requser -c \"" . $cmd . "\"";
    } else {
       return "su $requser -c '" . $cmd . "'"; 
    }
  } else {
    return $cmd;
  }
}

sub checkFileAccessUsingSu {

	my $tfa_home = shift;
	my $infile = shift;
	my $nonrootuser = shift;

	#print "Inside function checkFileAccessUsingSU\n";
        #print " 1: $infile 2:$nonrootuser 3:$tfa_home\n";

	if ( ! -f "$infile" ) {
                print "CheckFileAccess: Unable to open file $infile\n";
                return;
        }

        if ( ! $nonrootuser ) {
                print "CheckFileAccess: Please pass Non-root user as an argument\n";
                return;
        }

	my $outfile = $infile;
	$outfile =~ s/\.lst$/\.out/;

	qx($TOUCH $outfile);
	chmod(0777, $outfile) or die "Couldn't chmod $outfile: $!";
	#qx(chmod 777 $outfile);	

        my $command = catfile($tfa_home,"bin","tfactl")." checkfileaccess $infile $nonrootuser";
        my $su_cmd; 
        if ( $current_user eq "root" and not $IS_WINDOWS) {
          $su_cmd = "/bin/su -c \"$command\" $nonrootuser";
        } else {
          $su_cmd = "$command $nonrootuser";
        }
        my $cmd_out = qx($su_cmd);
	#my $exit_status = $?;
	#print "Exit Status from checkFileAccessUsingSu: $exit_status\n";
}

sub checkFileAccess {

	my $tfa_home = shift;
	my $infile = shift;
	my $nonrootuser = shift;

	#print "Inside function checkFileAccess\n";

	if ( ! -f "$infile" ) {
		print "CheckFileAccess: Unable to open file $infile\n";
		return;
	}

	if ( ! $nonrootuser ) {
		print "CheckFileAccess: Please pass Non-root user as an argument\n";
		return;
	}

	my $outfile = $infile;
	$outfile =~ s/\.lst$/\.out/;

	open( INPUT, "<$infile" ) or die "Couldn't open file $infile...\n";
	open( OUTPUT, ">$outfile" ) or die "Couldn't open file $outfile...\n";

	my $file;

	while( <INPUT> ) {
		$file = trim( $_ );

		# If unable to read then, write to outfile
		
		# Check symlink files
		if ( -l "$file" ) {
			my $real = readlink($file);
			if ( ! -r "$real" ) {
				print OUTPUT "$file\n";
			}
		} elsif ( ! -r "$file" ) {
			print OUTPUT "$file\n";
		}
	}
	close( INPUT );
	close( OUTPUT );
}


sub add_to_scanned_dbs
{
  my $tfa_home = shift;
  my $fname = shift;

  if ( ! -f catfile($tfa_home,"internal","scanned_dbs.txt"))
  {
    system("$TOUCH ".catfile($tfa_home,"internal","scanned_dbs.txt"));
  }

  if($IS_WINDOWS){
	my @db_list;
	my @db_list_new;
	my @filter_content;

	@filter_content = `type $fname | findstr INSTANCE_NAME`;

	foreach my $line (@filter_content){
	my @tokens = split(/\%/, $line);
	push(@db_list,trim($tokens[1]));
	}

	@db_list = tfactlshare_uniq(@db_list);
	@db_list = sort @db_list;

	my $dbs_files = catfile($tfa_home,"internal","dbs.txt"); 

	tfactlshare_write_array_to_file($dbs_files,\@db_list);

	my $scanned_db_file = catfile($tfa_home,"internal","scanned_dbs.txt");

	open (RF, $scanned_db_file) || die "Cant open $scanned_db_file\n";
	while(<RF>){
	push(@db_list_new,trim($_));
	}
	close(RF);

	push @db_list_new, @db_list;

	@db_list_new = tfactlshare_uniq(@db_list_new);
	@db_list_new = sort @db_list_new;

	my $scanned_db_file_new = catfile($tfa_home,"internal","scanned_dbs.txt.new"); 

	tfactlshare_write_array_to_file($scanned_db_file_new,\@db_list_new);
	system("$MV /Y $scanned_db_file_new $scanned_db_file > $DEVNULL");
  }else{
  	system("grep INSTANCE_NAME $fname | awk -F\"\%\" '{print \$2}'|sort -u > $tfa_home/internal/dbs.txt");
	system("cat $tfa_home/internal/scanned_dbs.txt $tfa_home/internal/dbs.txt | sort -u > $tfa_home/internal/scanned_dbs.txt.new");
	system("$MV -f ".catfile($tfa_home,"internal","scanned_dbs.txt.new")." ".catfile($tfa_home,"internal","scanned_dbs.txt"));
  }

}


sub find_new_databases
{
# This code is to see if a new discovery needs to run as we have added databases.
  my $tfa_home = shift;
  my %sdbs = ();
  my $sf = catfile($tfa_home,"internal","scanned_dbs.txt");
  my $osw_file = catfile($tfa_home,"internal","osw_dirs.txt");

  if ( -r "$sf" )
  { # Read the already scanned list
    open(RF, "$sf" );
    while(<RF>)
    {
      chomp;
      $sdbs{$_} = 1;
    }
    close(RF);
  }
  
  # Get current list of databases in OCR
  my $crshome = get_crs_home($tfa_home);
  my $srvctlFile;
  if($IS_WINDOWS){
  	$srvctlFile = catfile($crshome,"bin","srvctl.bat");
  }else{
  	$srvctlFile = catfile($crshome,"bin","srvctl");
  }
  my @dbs = `$srvctlFile config database`;
  chomp(@dbs);

  my $db;
  # Do diff
  foreach $db (@dbs)
  {
    if ( ! exists $sdbs{$db} )
    {
      print "Found a new database ". $db . "\n";
      return 1;
    }
  }
  
  if ( ! -e $osw_file && !$IS_WINDOWS)
  {
    my @osw = `ps -ef |grep 'OSW[A-Za-z]*\.sh' | grep -v grep`;
    if ( defined $osw[0] )
    {
      system("echo \"$osw[0]\" > $osw_file");
      return 1;
    }
  }
  return 0;
}

#========= fixInitTfa
#
sub fixInitTfa
{
  my $tfa_home = shift;
  my $r_node = shift;
  my $r_tfa_home = shift;
  my $tfa_home_to_replace = $tfa_home;
  dbg( DBG_VERB, "Fixing the init.tfa script for TFA_HOME : $tfa_home\n");
  my $infile = catfile ($tfa_home,"install","init.tfa.tmpl");
  my $outfile;
  if (defined $r_node && length $r_node) {
    $outfile = catfile ($tfa_home,"install","init.tfa.$r_node");
    $tfa_home_to_replace = $r_tfa_home;
  }
  else {
    $outfile = catfile ($tfa_home,"install","init.tfa");
  }
  my $isSuSE = isSUSELinux();
  my $tag1 = "### BEGIN INIT INFO\n# Provides: oracle_tfa\n# Required-Start: \$network \$syslog \n# Required-Stop: \$network \$syslog";
  my $tag2 = "# Default-Start: 3 5\n# Default-Stop: 0 1 2 6\n# Description: Start and Stop Oracle TFA service\n### END INIT INFO";
 
  open (IN, '<', $infile) or die "Can't open file $infile: $!\n";
  open (OUT, '>', $outfile) or die "Can't open file $outfile: $!\n";
 
  while (<IN>) {
    if (/TFA_HOME=/) {
      print OUT "TFA_HOME=$tfa_home_to_replace\n";
    } elsif ( $isSuSE == 0 && /#SUSE_TAGS/ ) {
      print OUT "$tag1\n$tag2\n";
    } else {
      print OUT $_;
    }
  }
  close IN;
  close OUT;
}

####
#
#  Function fixexachk
#
####
sub fixExachk 
{
  
   my $tfa_home = shift;
   dbg( DBG_VERB, "Copying orachk tool to be exachk as we are on Exadata : $tfa_home\n");
   my $ochkdir = catdir($tfa_home,"ext","orachk");
   my $ochkpy = catfile($tfa_home,"ext","orachk","orachk.pyc");
   my $echkpy = catfile($tfa_home,"ext","orachk","exachk.pyc");
   my $ochk = catfile($tfa_home,"ext","orachk","orachk");
   my $echk = catfile($tfa_home,"ext","orachk","exachk");
   if ( -f $ochkpy ) {
      copy($ochkpy, $echkpy);
   }     
   if ( -f $ochk ) {
      copy($ochk, $echk);
   }     
} # End sub fixExachk
#========= fixTfactl
#
sub fixTfactl
{
	my $tfa_home = shift;
	dbg( DBG_VERB, "Fixing the tfactl script for TFA_HOME : $tfa_home\n");

	my $infile;
	my $outfile;
	
	if ($IS_WINDOWS) {
		$infile = catfile ( $tfa_home,"bin","tfactl.bat.tmpl");
		$outfile = catfile ( $tfa_home,"bin","tfactl.bat");
	} else {
		$infile = catfile ( $tfa_home,"bin","tfactl.tmpl");
		$outfile = catfile ( $tfa_home,"bin","tfactl");
	}

	open (IN, '<', $infile) or die "Can't open file $infile: $!\n";
	open (OUT, '>', $outfile) or die "Can't open file $outfile: $!\n";

	while (<IN>) {
		 if (/TFA_HOME=/) {
		     if ($IS_WINDOWS) {
                        $tfa_home =~ s/\//\\\\/g;
		     	print OUT "set TFA_HOME=$tfa_home\n";
		     } else {
		     	print OUT "TFA_HOME=$tfa_home\n";
		     }
		 } else {
			 print OUT $_;
		 }
	}
	close IN;
	close OUT;
}

#
# Subroutine to copy tfactl to TFA_BASE
#
sub copytfactl {
	my $tfa_home = shift;
	my $hostname = tolower_host();
	my $tfa_base;

	if ( $tfa_home =~ /(.*)[\/|\\]$hostname[\/|\\]tfa_home$/ ) {
		$tfa_base = $1;
	}

	if ( -f catfile($tfa_base,"bin","tfactl") ) {
		#print "\nCopying tfactl to $tfa_base/bin/tfactl...\n";
		host(tfactlshare_get_cp_cmd(catfile($tfa_home,"bin","tfactl"),catdir($tfa_base,"bin")));
	}

	my $crs_home = get_crs_home( $tfa_home );

	if ( $crs_home && -d catdir($crs_home,"bin") ) {

		host(tfactlshare_get_cp_cmd(catfile($tfa_home,"bin","tfactl"),catfile($crs_home,"bin","tfactl")));
		# update the ownership of $crs_home/bin/tfactl:
		if($IS_WINDOWS){
			#TODO Need to add ownership for tfactl
		}else{
			my $crsctl = catfile($crs_home, "bin", "crsctl");
			my $crsctl_perm = qx(ls -ld $crsctl | awk '{print "root:"\$4}');
			$crsctl_perm = trim ( $crsctl_perm );
			host("chown $crsctl_perm $crs_home/bin/tfactl");
			host("chmod 755 $crs_home/bin/tfactl");
		}
	}
}

#
# Subroutine to find a string in a file.
#

sub tfactlshare_find_string {
   my ($file , $string ) = @_;

   open ( INFILE, "<$file" );


   while (<INFILE>) {
      return 1 if ( /\Q$string/ ) ;
   }
   close (INFILE);
   return 0;
}


#
# Subroutine to update tfa_directories.txt
#
sub updateDirectoriesFile {
   my $tfa_home = shift;
   my $dirfile = "";     # Existing tfa_directories file
   my $dirfilenew = "";  # File coming from the patch
   $dirfile = catfile( $tfa_home,"tfa_directories.txt");
   $dirfilenew = catfile( $tfa_home,"tfa_directories.txt.bkp");

  if ( ! -e $dirfilenew ) {
    print "File $dirfilenew not found\n";
    return;
  }

  my $value;
  my $line;
  my $status;

  #print "Updating TFA Directories...\n";

  open ( DIRNEW, "<$dirfilenew" );
  open ( DIRFIL, ">>$dirfile" );

  # For each line in the patch file check to see if it exists in the current file.
  # If there is no record then we can add it.

  while (<DIRNEW>) {
    $line = trim($_);
    $value = (split(/=/, $line))[1];
    chomp($value);

    if ( -d $value ) {
       $status = tfactlshare_find_string($dirfile,$value);

       if ( $status eq 0 ) {
         print DIRFIL "$line\n";
       }
    }
  }

  close (DIRNEW);
  close (DIRFIL);

  unlink ($dirfilenew);
  tfactlshare_chmod("-perm=644 -path=".catfile($tfa_home,"tfa_directories.txt"));
}

#
# Subroutine to update config.properties
#
sub updatePropertiesFile {
	my $tfa_home = shift;

	my $config = catfile($tfa_home, "internal", "config.properties");
	my $configbkp = catfile($tfa_home, "internal", "config.properties.patch");
	updatePropertiesFileNew($tfa_home, $config, $configbkp);
	$config = catfile($tfa_home, "internal", "smtp.properties");
	$configbkp = catfile($tfa_home, "internal", "smtp.properties.patch");
	updatePropertiesFileNew($tfa_home, $config, $configbkp);
	$config = catfile($tfa_home, "internal", "timezones_mapping");
	$configbkp = catfile($tfa_home, "internal", "timezones_mapping.patch");
	updatePropertiesFileNew($tfa_home, $config, $configbkp);
	#Following is not needed for now(18.1)
	#$config = catfile($tfa_home,"receiver", "internal", "rconfig.properties");
	#$configbkp = catfile($tfa_home,"receiver", "internal", "rconfig.properties.old");
	#updatePropertiesFileNew($tfa_home, $config, $configbkp);
}

sub updatePropertiesFileNew {
	my $tfa_home = shift;
	my $config = shift;
	my $configbkp = shift;

	$config = catfile($tfa_home, "internal", "config.properties") if ( ! "$config" );
	$configbkp = catfile($tfa_home, "internal", "config.properties.old") if ( ! "$configbkp" );

	if ( ! -e "$config" ) {
		# Move config.properties.old to config.properties
		if ( -e "$configbkp" ) {
			rename($configbkp, $config);
		}
		return;
	}

	if ( ! -e "$configbkp" ) {
		print "File $configbkp not found\n";
		return;
	}

	my $key;
	my $line;
	my $status;
	my @addlines;

	#print "Upgrading TFA Configuration...\n";

	open ( CFGBKP, "<$configbkp" );

	while (<CFGBKP>) {
		$line = trim($_);
		$key = (split(/=/, $line))[0];

		$status = tfactlshare_getConfigValue($config, $key);

		if ( ! $status ) {
			push(@addlines, $line);
		}
	}

	close (CFGBKP);

	# Update config.properties
	open ( CONFIG, ">>$config" );

	foreach $line ( @addlines ) {
		print CONFIG "$line\n";
	}

	close (CONFIG);
        chmod(0644, $config) if -f $config;

	unlink ($configbkp);
}

#
# Subroutine to Enable TFA AutoDiagcollect
#
sub tfactlshare_updateAutoDiagcollect {
	my $tfa_home = shift;
	my $configFile = catfile($tfa_home, "internal", "config.properties");
	my $tfaversion = tfactlshare_getTFAVersion($tfa_home);

	# If TFA Version is less than 12.2 then enable AutoDiagcollect
	if ( -s "$configFile" && $tfaversion < 122000 ) {
		print "Enabling TFA AutoDiagcollect...\n";
		tfactlshare_updateTFAConfig($configFile, "firediagcollectRT", "true");
	}
}

#
# Subroutine to Enable TFA AutoDiagcollect
#
sub tfactlshare_updateCipherSuite {
	my $tfa_home = shift;
	my $configFile = catfile($tfa_home, "internal", "config.properties");
	my $patchconfigFile = catfile($tfa_home, "internal", "config.properties.patch");
        my $value = tfactlshare_getConfigValue($patchconfigFile,"cipherSuite");
        if ( length $value ) {
		print "Setting TFA Cipher Suite to $value...\n";
		tfactlshare_updateTFAConfig($configFile, "cipherSuite", $value);
                return SUCCESS;
        } else {
            print "Cannot set TFA Cipher Suite as no value set in patch config.properties\n";
            return FAILED;
        }
}

sub isSUSELinux {

	my $status = -1;

	if ($osname eq "Linux") {
		my $rpm_cmd = "rpm -q sles-release";
		my $rpm_out = qx( $rpm_cmd );
		my $rpm_status = $?;

		if ( $rpm_status == 0 ) {
			$status = 0;
		}
	} 
	return $status;
}

########################## fixTfaHome ##############################
sub fixTfaHome
{
  my $node = shift;
  my $tfa_home = shift;
  my $local_tfa_home = shift;
  my $path = shift;
  my $filename = shift;
 
  dbg( DBG_VERB, "Fixing the $filename script for TFA_HOME : $tfa_home\n");
  my $infile = catfile ($local_tfa_home,$path,"$filename.tmpl");
  my $outfile = catfile ($local_tfa_home,$path,"$filename.$node");
  if ($filename eq "init.tfa") {
    fixInitTfa($local_tfa_home,$node,$tfa_home);
  }
  else {
    open (IN, '<', $infile) or die "Can't open file $infile: $!\n";
    open (OUT, '>', $outfile) or die "Can't open file $outfile: $!\n";
    while (<IN>) {
      if (/TFA_HOME=/) {
        if ($IS_WINDOWS) {
          $tfa_home =~ s/\//\\\\/g;
          print OUT "set TFA_HOME=$tfa_home\n";
        } else {
          print OUT "TFA_HOME=$tfa_home\n";
        }
      }
      else {
        print OUT $_;
      }
    }
    close IN;
    close OUT;
  }
  tfactlshare_chmodAddPerm(0111,catfile($local_tfa_home,$path,"$filename.$node"));
  copy_remote($node,catfile($local_tfa_home,$path,"$filename.$node"),catdir($tfa_home,$path),catdir($local_tfa_home, "transfer_remote"));
  host_remote($node,"$MV ".catfile($tfa_home,$path,"$filename.$node")." ".catfile($tfa_home,$path,"$filename"));
  if ( $IS_WINDOWS ){
    host("$RM ".catfile($local_tfa_home,$path,"$filename.$node"));
  }else{
    host("$RM -rf $local_tfa_home/$path/$filename.$node"); 
  }
}


########################## fixBinTfaHome ##############################
sub fixBinTfaHome
{
 my $node = shift;
 my $base_dir = shift;
 my $local_base_dir = shift;
 my $path = shift;
 my $filename = shift;

 #print "\nFIXTFAHOME  Node: $node Source Path: $local_tfa_home Dest Path: $tfa_home File Name: $filename\n";

 dbg( DBG_VERB, "Fixing the $filename script for BASE Directory : $base_dir\n");
 
 my $infile = catfile ( "$local_base_dir","$path", "$filename");
 my $outfile = catfile ( "$local_base_dir","$path", "$filename.$node");

 open (IN, '<', $infile) or die "Can't open file $infile: $!\n";
 open (OUT, '>', $outfile) or die "Can't open file $outfile: $!\n";
 
 my $replace_str;
 if ( $IS_WINDOWS )
 {   
   #$replace_str = tolower_host();
   $replace_str = $node."\\tfa_home";
 }else{
   $replace_str = "`hostname | cut -d. -f1 | \$AWK '{print tolower(\$0)}'`/tfa_home";
 }
 

 while (<IN>) {

        if (/TFA_HOME=/) {
         $base_dir = catdir($base_dir); #Removes trailing slashes
         if ($IS_WINDOWS) {
         	print OUT "set TFA_HOME=".catdir($base_dir,$replace_str)."\n";
         } else {
         	print OUT "TFA_HOME=".catdir($base_dir,$replace_str)."\n";   
         }

        }
        else {
             print OUT $_;
        }
 }

 close IN;
 close OUT;
 tfactlshare_chmodAddPerm(0111,catfile($local_base_dir,$path,"$filename.$node"));
 copy_remote($node,catfile($local_base_dir,$path,"$filename.$node"),catdir($base_dir,$path),catdir($local_base_dir, "transfer_remote"));#TODO remote copy for windows needs to be updated
 
 host_remote($node,"$MV ".catfile($base_dir,$path,"$filename.$node")." ".catfile($base_dir,$path,"$filename"));
 if ( $IS_WINDOWS )
 {
  host("$RM /F ".catfile($local_base_dir,$path,"$filename.$node"));
 }else{
  host("$RM -rf ".catfile($local_base_dir,$path,"$filename.$node"));
 }
}

sub get_java_home
{
  my $tfa_home  = shift;
  my $paramfile = tfactlshare_getSetupFilePath($tfa_home);
  my $java_home = "";

  if ( -d catdir($tfa_home, "jre") ) {
	$java_home = catdir($tfa_home, "jre");
	return $java_home;
  }

  if ( ! -f "$paramfile" ) {
	$paramfile = catfile($tfa_home, "tfa_setup.txt");
  }
	
  open (RF, "$paramfile") || die "Cant open $paramfile\n";
  while(<RF>)
  {
    chomp;
    if ( /JAVA_HOME=(.*)/ )
    {
       if ( $IS_WINDOWS ) {
           $java_home = "\"".$1."\"";
       } else {
               $java_home = "$1";
       }
      last;
    }
  }
  close(RF);
  return $java_home;
}

sub get_java_home_defer
{
  my $java_home = "";
  if(open (RF, "java_install.out")) {
  
  while(<RF>)
  {
    chomp;
    if ( /JAVA_HOME=(.*)/ )
    {
      $java_home = $1;
      last;
    }
  }
  close(RF);
  }
  return $java_home;
}

sub get_tfa_pid 
{
	my $tfa_home = shift;
	my $tfapid = '';
	open (RF, catfile("$tfa_home","internal",".pidfile"));
	while(<RF>) {
		chomp;
		if ( /(.*)/ ) {
			$tfapid = $1;
		}
		last;
	}
		close(RF);
	
	return $tfapid;
}

########
## NAME:   
##	tfactlshare_get_pid
## PARAMETERS
##	FileName which has pid	
## RETURNS
##      pid
#########
sub tfactlshare_get_pid 
{
  my $pidfile = shift;
  my $pid = -1;
  if ( $IS_WINDOWS ) {
    $pid = -1;
  }
  elsif ( -f $pidfile )  { 
    open (RF,"$pidfile");
    while(<RF>) {
      chomp;
      if ( /(.*)/ ) {
        $pid = $1;
      }
      last;
    }
    close(RF);
  }
  return $pid;
}

sub get_crs_home
{
  my $tfa_home = shift;
  my $crs_home = "";
  open (RF, catfile($tfa_home,"tfa_setup.txt")) || die "Cant open ".catfile($tfa_home,"tfa_setup.txt")."\n";
  while(<RF>)
  {
    chomp;
    if ( /^CRS_HOME=(.*)/ )
    {
      $crs_home = $1;
      last;
    }
  }
  close(RF);
  return $crs_home;
}

sub tfactlshare_is_crs_installed 
{
  my $tfa_home = shift;
  my $crs_home = get_crs_home($tfa_home);
  if ($crs_home && -d $crs_home) {
    return 1;
  } else {
    return 0;
  }
}

sub get_oracle_base
{
  my $tfa_home = shift;
  my $oracle_base = "";
  open (RF, catfile($tfa_home,"tfa_setup.txt")) || die "Cant open ".catfile($tfa_home,"tfa_setup.txt")."\n";
  while(<RF>)
  {
    chomp;
    if ( /^ORACLE_BASE=(.*)/ )
    {
      $oracle_base = $1;
      last;
    }
  }
  close(RF);
  return $oracle_base;
}

########
## NAME
##   tfactlshare_get_adrbase
##
## DESCRIPTION
##   This function returns the ADR base for the given ORACLE_HOME.
##
## PARAMETERS
##   oracle_home (in) - ORACLE_HOME
##
## RETURNS
##   ADR base.
#########
sub tfactlshare_get_adrbase
{
  my $oracle_home = shift;
  my $adrbase = "invalid";
  my $line;
  my $orabasebin = catfile($oracle_home,"bin",$ORABASE);
  my $cmdline = "";
  ### print "shell $OSSHELL get_adrbase \n";
  if ( not $IS_WINDOWS ) {
    if ( $CSH ) {
      $cmdline = "setenv ORACLE_HOME $oracle_home; $orabasebin";
      $cmdline = $cmdline . " >& /dev/stdout" if ( !$IS_AIX );
      $cmdline = "/bin/csh -c '$cmdline'";
    } else {
      $cmdline = "ORACLE_HOME=$oracle_home; export ORACLE_HOME; $orabasebin 2>&1";
    }
  } else {
    $cmdline = "(set ORACLE_HOME=$oracle_home) && ($orabasebin 2>&1)";
  }
  #### print "tfactlshare_get_adrbase cmdline $cmdline\n";
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_get_adrbase " .
                    "[ga00] cmdline $cmdline",'y', 'y');
  foreach $line (split /\n/, `$cmdline`) {
    #### print "line $line\n";
    if ( $line =~ m/^([\/\\][\w\s\.\_\-]+)+$/ || $line =~ m/^[\w\:]*([\/\\][\w\s\.\_\-]+)+$/ ) {
      $adrbase = $line;
      #### print "tfactlshare_get_adrbase adrbase $adrbase\n";
      tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_get_adrbase " .
                        "adrbase $adrbase",'y', 'y');
    }
  } # end foreach $commandline

  return $adrbase;
}

sub tfactlshare_get_val4key_in_tfa_setup
{
  my $tfa_home  = shift;
  my $key       = shift;
  my $setupfile = shift;
  my $val = "";

  # manuegar_extract_tfa_03
  if ( not length $setupfile ) {
    $setupfile = catfile($tfa_home,"tfa_setup.txt");
  }

  #Set default values for some
  if ( $key eq "NODE_TYPE" ) {
    $val = "TYPICAL";
  }

  open (RF, $setupfile) || die "Cant open $setupfile.\n";
  while(<RF>)
  {
    chomp;
    if ( /^$key=(.*)/ )
    {
      $val = $1;
      last;
    }
  }
  close(RF);
  return $val;
}

#
# Subroutine to get TFA Version [ 121230 ]
#
sub tfactlshare_getTFAVersion {
	my $tfa_home = shift;
	my $buildfile = catfile($tfa_home, "internal", ".buildid");
	my $buildid;
	my $version = 0;

	my $buildversion = catfile($tfa_home, "internal", ".buildversion");

	if ( -r $buildversion) {
		$version = tfactlshare_cat($buildversion);
		$version = trim($version);
	} elsif ( -r $buildfile ) {
		$buildid = tfactlshare_cat($buildfile);
		$buildid = trim($buildid);
		$version = substr($buildid, 0, 6);
	}

	return $version;
}

#
# Subroutine to get TFA Build Date
#
sub tfactlshare_getTFABuild {
	my $tfa_home = shift;
	my $buildid = 0;

	my $buildfile = catfile($tfa_home, "internal", ".buildid");

	if ( -r $buildfile ) {
		$buildid = tfactlshare_cat($buildfile);
		$buildid = trim($buildid);
	}

	return $buildid;
}

#
# Subroutine to print TFA Version
#
sub tfactlshare_printTFAVersion {
	my $tfa_home = shift;

	my $version = tfactlshare_getTFAVersion($tfa_home);
	if ( $version ) {
		print "TFA Version : $version\n";
	} else {
		print "Unable to detect TFA Version\n";
	}

	my $buildid = tfactlshare_getTFABuild($tfa_home);
	if ( $buildid ) {
		print "TFA Build ID : $buildid\n";
	}
}

#######
# NAME:   
#      tfactlshare_getTFAAge 
# PARAMETERS
#      tfa_home
# RETURNS
#      Age of current installed TFA software
#######
sub tfactlshare_getTFAAge {
  my $tfa_home = shift;
  my $age = 0;
  my $installDate = tfactlshare_getTFABuild($tfa_home);
  my $installTime;
  my $curDate = strftime("%Y%m%d%H%M%S", localtime());
  my $curTime;
  if (length($installDate) == 14) {
    if ( $installDate =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/ ) {
      $installTime = timelocal($6,$5,$4,$3,$2-1,$1);
    }
    if ( $curDate =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/ ) {
      $curTime = timelocal($6,$5,$4,$3,$2-1,$1);
    }
    $age = ( $curTime - $installTime ) / 86400; #In days
  }
  return $age;
}

########
# NAME
#   tfactlshare_validate_remdb
#
# DESCRIPTION
#   This function validates connectivity to remote database
#
# PARAMETERS
#   $db_name     - DB NAME
#   $rem_host    - Remote hostname
#   $rem_port    - Remote port
#   $rem_service - Remote service
#
# RETURNS
#   DBNOTFOUND
#   TNSPINGNOTFOUND
#   VALIDREMDATA
#   INVALIDREMDATA
#   INVALIDHOST
#   NOLISTENER
#
########
sub tfactlshare_validate_remdb
{
  my $tfa_home    = shift;
  my $db_name     = shift;
  my $rem_host    = shift;
  my $rem_port    = shift;
  my $rem_service = shift;
  my $ohome       = "";
  my $osid        = "";
  my $tnsping     = "";
  my $cmd         = "";
  my $cmdout      = "";

  if ( $db_name =~ /(.*?)\..*/ ) {
    $db_name = $1;
  }

  if ( not (length $rem_host && length $rem_port && length $rem_service) ) {
    return "INVALIDREMDATA";
  }

  ($ohome,$osid) = tfactlshare_get_oracle_home($tfa_home,$db_name);

  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_validate_remdb " .
                    "ohome $ohome",'y', 'y');
  ### print "ohome $ohome\n";

  if ( $ohome eq "NOT FOUND" ) {
    return "DBNOTFOUND";
  }

  $tnsping = catfile($ohome,"bin","tnsping");
  if ( not -f "$tnsping" ) {
    return "TNSPINGNOTFOUND";
  }

  $ENV{"ORACLE_SID"} = $osid;
  $ENV{"ORACLE_HOME"} = $ohome;
  $ENV{"LD_LIBRARY_PATH"} = catfile($ohome,"lib");

  $cmd = "$tnsping $rem_host\:$rem_port\/$rem_service";

  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_validate_remdb " .
                    "cmd $cmd",'y', 'y');
  ### print "Cmd $cmd\n";

  $cmdout = `$cmd`;

  ### print "cmdout $cmdout\n";

  if ( $cmdout =~ /OK \([0-9]+ msec\)/ ) {
    return "VALIDREMDATA";
  } elsif ( $cmdout =~ /TNS\-03505\: Failed to resolve name/ ) {
    return "INVALIDHOST";
  } elsif ( $cmdout =~ /TNS\-12541\: TNS:no listener/ ) {
    return "NOLISTENER";
  } else {
    return "INVALIDREMDATA";
  }
}

########
# NAME
#   tfactlshare_validate_tns
#
# DESCRIPTION
#   This function validates the TNS alias
#
# PARAMETERS
#   $db_name - DB NAME to be validated
#   $tns_alias - The TNS Alias to be validated
#
# RETURNS
#   TNSVALID - TNS Alias is valid
#   TNSINVALID - Failed to resolve TNS alias
#
########
sub tfactlshare_validate_tns {
  my $ohome       = shift;
  my $tns_alias   = shift;
  my $tnsout;
  my $tnsping;

  ### print "tfactlshare_validate_tns ohome $ohome\n";

  if ( not -d "$ohome" ) {
    return "TNSINVALID";
  }

  $ENV{"ORACLE_HOME"} = $ohome;
  $ENV{"LD_LIBRARY_PATH"} = catfile($ohome,"lib");
  $tnsping = catfile($ohome,"bin","tnsping");
  $tnsout = `$tnsping $tns_alias`;

  ### print "tfactlshare_validate_tns tnsout $tnsout\n";

  if ( $tnsout =~ /TNS-03505\: Failed to resolve name/ || 
       $tnsout =~ /TNS-12535\: TNS\:operation timed out/ ||
       $tnsout =~ /TNS-12541\: TNS\:no listener/ ) {
    return "TNSINVALID";
  }

  return "TNSVALID";
}

########
# NAME
#   tfactlshare_validate_db
#
# DESCRIPTION
#   This function validates the database
#
# PARAMETERS
#   $db_name - DB NAME to be validated
#
# RETURNS
#   ORACLE_HOME NOT FOUND -
#   LISTENER IS NOT RUNNING -
#   LISTENER HAS NO HANDLER
#   DBVALID - Database valid and running
#
########
sub tfactlshare_validate_db
{
  my $tfa_home    = shift;
  my $db_name     = shift;
  my $lsnrctl;
  my $lsnrctlout;
  my $ohome;
  my $osid;

  if ( $db_name =~ /(.*?)\..*/ ) {
    $db_name = $1;
  }

  ($ohome,$osid) = tfactlshare_get_oracle_home($tfa_home,$db_name);
  ### print "ohome $ohome\n";
  if ( not -d "$ohome" ) {
    return "ORACLE_HOME NOT FOUND";
  }

  ### print "tfactlshare_validate_db ohome $ohome\n";

  $ENV{"ORACLE_SID"} = $osid;
  $ENV{"ORACLE_HOME"} = $ohome;
  $ENV{"LD_LIBRARY_PATH"} = catfile($ohome,"lib");
  $lsnrctl = catfile($ohome,"bin","lsnrctl");
  $lsnrctlout = `$lsnrctl status`;

  ### print "tfactlshare_validate_db lsnrctlout $lsnrctlout\n";

  $db_name =~ s/\+/\\\+/g;
  if ( $lsnrctlout =~ /[Nn]o listener/ ) {
    return "LISTENER IS NOT RUNNING";
  }
  if ( $lsnrctlout !~ /.*Instance \"$db_name([.]?.*)?\", status READY.*/i ) {
    return "LISTENER HAS NO HANDLER";
  }

  return "DBVALID",$ohome;
}

########
# NAME
#   tfactlshare_procsqldta 
#
# DESCRIPTION
#   This function execute sql scripts
#   in a secure fashion.
#
# PARAMETERS
#   $writerref   - Writer reference
#   $type        - array/file
#   $objref      - @sqlarray ref or scriptname    
#   $rephashref  - hash used for content replacement
#
# RETURNS
#
########
sub tfactlshare_procsqldta
{
  my $writerref  = shift;
  my $type       = shift;
  my $objref     = shift;
  my $rephashref = shift;
  my %rephash    = %$rephashref;
  my $exitfound  = FALSE;
  local (*Writer) = *$writerref;

  if ( lc($type) eq "array" ) {
    my $flatrep = join("\n", @$objref);
    $objref = \$flatrep;
  }

  open (SCRIPT, "<", $objref) or die("Could not open scriptfile $objref.");
  while (<SCRIPT>) {
    $exitfound = TRUE if ( $_ =~ /exit/i );
    foreach my $testtr (keys %rephash) {
        $_ =~ s/\%$testtr\%/$rephash{$testtr}/;
    }
    $_ = $_ . "\n" if ( $_ !~ /[\n\r]/ );
    ### print "Writer $_";
    print Writer $_;
  } # end while

  if ( not $exitfound ) {
    print Writer "exit\n";
  }

  return;
}

########
# NAME
#   tfactlshare_runsql_array
#
# DESCRIPTION
#   This function execute sql scripts
#   in a secure fashion.
#
# PARAMETERS
#   $sqlplus     - sqlplus binary
#   $rephashref  - hash used for content replacement
#   $type        - array/file
#   $objref      - sqlarray ref or sqlscript filename
#
# RETURNS
#   $cmdout      - sql out
#
########
sub tfactlshare_runsecsql
{
  my $sqlplus    = shift;
  my $rephashref = shift;
  my $type       = shift;
  my $objref     = shift;
  my $genoutfile = shift;
  my %rephash    = %$rephashref;
  my $cmdout     = "";
  my $cmd        = "$sqlplus /nolog";
  my $exitfound  = FALSE;
  my $open3needed = FALSE;

  if (undef $genoutfile) {
    $genoutfile = FALSE;
  } else {
    $genoutfile = TRUE;
  }

  if ( lc($type) eq "file" ) {
    return "Scriptfile $objref does not exist or is not accessible." if (not -r $objref);
    if ( $genoutfile ) {
      $cmd .= " > $objref.out 2>&1";
    }
  }

  if ( $IS_WINDOWS ) {
    $open3needed = TRUE;
  }

  eval {
    local $SIG{ALRM} = sub { die "alarm\n" };
    alarm 120;
 
    if ( not $open3needed ) {
      use IPC::Open2;
      local (*Reader, *Writer);
      my $pid = open2(\*Reader, \*Writer, "$cmd");

      ### print "calling tfactlshare_procsqldta ...\n"; 
      tfactlshare_procsqldta(\*Writer,$type,$objref,\%rephash);

      close Writer;

      while (<Reader>) {
           $cmdout .= $_;
      }
    } else {
      # Windows, $open3needed => TRUE
      my $rdrfile  = tempfile() . "rdrsql.log";
      my $errfile  = tempfile() . "errsql.log";
      require IO::File;
      use IO::File;
      local (*Wrtr, *Rdr, *Err);
      *Rdr = IO::File->new($rdrfile,"w");
      *Err = IO::File->new($errfile,"w");

      require IPC::Open3;
      use IPC::Open3;
      my $pid = open3(\*Wrtr, ">&Rdr", ">&Err", "$cmd");

      tfactlshare_procsqldta(\*Wrtr,$type,$objref,\%rephash);

      close Wrtr;

      waitpid $pid,0;
      close Rdr;
      close Err;
      $cmdout = tfactlshare_cat($rdrfile);
      unlink $rdrfile;
      unlink $errfile;

    } # end if $open3needed
    alarm 0;
  }; # end eval()

  return $cmdout;

} # end tfactlshare_runsql_array

########
# NAME
#   tfactlshare_validate_db_account
#
# DESCRIPTION
#   This function validates the database account
#
# PARAMETERS
#   $db_name     - DB NAME
#   $db_sername  - DB username
#   $db_password - DB user password
#   $rem_host    - Remote hostname
#   $rem_port    - Remote port
#   $rem_service - Remote service
#
# RETURNS
#   SQLPLUSNOTFOUND - sqlplus not available
#   ACCOUNTLOCKED - Account locked
#   PASSWORDEXPIRED - Password expired
#   INVALIDPWD - Invalid password
#   DBNOTFOUND - Database not found
#   VALID      - Valid password
#
########
sub tfactlshare_validate_db_account
{
  my $tfa_home    = shift;
  my $db_name     = shift;
  my $db_username = shift;
  my $db_password = shift;
  my $rem_host    = shift;
  my $rem_port    = shift;
  my $rem_service = shift;
  my $ohome       = "";
  my $osid        = "";
  my $sqlplus     = "";
  my $cmd         = "";
  my $cmdout      = "";
  my $remdata     = FALSE;

  if ( $db_name =~ /(.*?)\..*/ ) {
    $db_name = $1;
  }

  if ( length $rem_host && length $rem_port && length $rem_service ) {
    $remdata = TRUE;
  }

  $db_password = "none" if not length $db_password;
  ($ohome,$osid) = tfactlshare_get_oracle_home($tfa_home,$db_name);

  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_validate_db_account " .
                    "db_name $db_name : db_username : $db_username",'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_validate_db_account " .
                    "ohome $ohome",'y', 'y');
  ### print "db_name $db_name , db_username : $db_username\n";
  ### print "ohome $ohome , osid $osid\n";

  if ( $ohome eq "NOT FOUND" ) {
    return "DBNOTFOUND";
  }
  
  if ( ! $IS_WINDOWS ) {
    $sqlplus = catfile($ohome,"bin","sqlplus");
  } else {
    $sqlplus = catfile($ohome,"bin","sqlplus.exe");  
  }  

  if ( not -f "$sqlplus" ) {
    return "SQLPLUSNOTFOUND";
  }

  $ENV{"ORACLE_SID"} = $osid;
  $ENV{"ORACLE_HOME"} = $ohome;
  $ENV{"LD_LIBRARY_PATH"} = catfile($ohome,"lib");

  if ( not $remdata ) {
    $cmd = "$sqlplus /nolog";
  } else {
    $db_password =~ s/\!/\\\!/g;
    if ( not $IS_WINDOWS ) {
      $cmd = "echo \"exit\" | $sqlplus $db_username/$db_password@//$rem_host:$rem_port/$rem_service";
    } else {
      $cmd = "echo exit | $sqlplus $db_username/$db_password@//$rem_host:$rem_port/$rem_service";
    }
  }

  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_validate_db_account " .
                    "cmd $cmd",'y', 'y');

  my @sqlarray = ( "connect %db_username%/%db_password%",
                   "exit" );
  my %rephash = ( "db_username" => $db_username,
                  "db_password" => $db_password );

  $cmdout = tfactlshare_runsecsql($sqlplus,\%rephash, "array", \@sqlarray);

  ### print "Cmd $cmd\n";
  ###  print "cmdout $cmdout\n";

  if ( not length $cmdout ) {
    return "INVALID";
  } elsif ( $cmdout =~ /invalid username\/password/ ) {
    return "INVALIDPWD";
  } elsif ( $cmdout =~ /the account is locked/ ) {
    return "ACCOUNTLOCKED";
  } elsif ( $cmdout =~ /ORA\-28001/ ) {
    return "PASSWORDEXPIRED";
  } else {
    if ( not $remdata ) {
      return "VALID";
    } else {
      if ( $cmdout =~ /Last Successful login time/ ) {
        return "VALID";
      } elsif ( $cmdout =~ /TNS\:could not resolve the connect identifier specified/ ) {
        print "Remote repository DB was not located on host $rem_host.\n";
      } elsif ( $cmdout =~ /TNS\:no listener/ ) {
        print "No listener on port $rem_port.\n";
      } elsif ( $cmdout =~ /TNS\:listener does not currently know of service requested in connect/ ) {
        print "TNS:listener does not currently know of service $rem_service requested.\n";
      }
      exit 1;
    }
  } 
}

########
# NAME
#   tfactlshare_get_oracle_home
#
# DESCRIPTION
#   This function gets the oracle home for a given database
# PARAMETERS
#
# RETURNS
#   the oracle_home
#
########
sub tfactlshare_get_oracle_home
{
  my $tfa_home = shift;
  my $db_name  = shift;
  my $ohome    = "";
  my $osid     = "";
  my %osidhash;
  my $crshome = get_crs_home($tfa_home);
  my $oratab  =  catfile("","etc","oratab");
  my $srvctl  = "";
  my $command = "";
  my @out;
  my @sidsarray;
  my @nodes;

  if ( not $IS_WINDOWS ) {
    if ( $IS_SOLARIS ) {
      $oratab = catfile("var","opt","oracle","oratab");
    }
    if ( -e $oratab ) {
      $ohome = `cat $oratab |grep ":/" |grep -v "^#"|grep -iw "$db_name:" |cut -d: -f2| head -1`;
      chomp($ohome);
    }
    $osid = `$PS -ef | grep -i "ora_pmon_$db_name" | grep -v grep | sed 's/.*ora_pmon_//'`;
    chomp($osid);
  } else {
    # $IS_WINDOWS
    # Get ORACLE_HOME
    @out = `sc qc OracleService$db_name 2>&1`;
    foreach my $line (@out) {
      if ( $line =~ /.*BINARY_PATH_NAME\s+\:\s(.*)\\bin\\ORACLE\.EXE\s(.*)/ ) { 
        $ohome = $1;
        $osid  = $2;
        last;
      }   
    } # end foreach @out
    ### print "win: ohome $ohome, osid $osid\n";
    return ($ohome, $osid) if length $ohome && length $osid;
  } # end if not $IS_WINDOWS

  if ( ((not -d $ohome) || (not length $osid)) && (-d $crshome) ) {
    $srvctl = catfile($crshome,"bin","srvctl");
    $command = "$srvctl config database -d $db_name";
    @out = `$command 2>&1`;
    chomp(@out);

    foreach my $line(@out)   {
      if ( $line =~ /Oracle home: (.*)/ ) {
        $ohome = $1; 
      }     
      if ( $line =~ /Database instance: (.*)/ ) {
        $osid = $2;
      }
      if ( $line =~ /Database instances: (.*)/ ) {
        @sidsarray = split /\,/ , $1; 
      } 
      if ( $line =~ /Configured nodes: (.*)/ ) {
        @nodes = split /\,/ , $1;
        for ( my $ndx=0; $ndx<=$#nodes;$ndx++ ) {
           if ( lc($nodes[$ndx]) eq $localhost ) {
             $osid = $sidsarray[$ndx];
             last;
           }
        }
      }
    } # end foreach
  } # end if -d $crshome

  ### print "ohome $ohome, osid $osid\n";
  if ( (not -d "$ohome") && (not length $osid) ) {
    return ("NOT FOUND","");
  } else {
    return ($ohome,$osid);
  }
} # end if tfactlshare_get_oracle_home

########
# NAME
#   tfactlshare_get_oracle_homes
#
# DESCRIPTION
#   This function gets the available oracle homes
#   in tfa_setup.txt
# PARAMETERS
#
# RETURNS
#   tfactlglobal_oracle_homes
#
########
sub tfactlshare_get_oracle_homes
{
  my $tfa_home = shift;
  my $ndx = 0;
  my $oracle_home = $ENV{'ORACLE_HOME'};
  my %ohhash;
  my $tfasetup = tfactlshare_getSetupFilePath($tfa_home);
  ### print "shell $OSSHELL get_oracle_homes \n";

  return if @tfactlglobal_oracle_homes;

  open (RF, $tfasetup) || die "Can't open $tfasetup.\n";
  while(<RF>)
  {
    chomp;
    if ( (/^.*ORACLE_HOME=([\w\/\.\\\:]*)\|.*/ && -d $1 && -e catfile($1,"bin","$ADRCI") &&
         not /agenthome[\/\\]agent/) ||
         /^.*CRS_HOME=([\w\/\.\\\:]*)/        && -d $1 && -e catfile($1,"bin","$ADRCI") )
    {
      if ( not exists $ohhash{$1} ) {
        $tfactlglobal_oracle_homes[$ndx++] = $1;
        $ohhash{$1} = TRUE;
        #print "Oracle home $1 \n";
      } # end if not exists $ohhash{$1}
    }
  }
  close(RF);
  # Use ORACLE_HOME environment variable if set
  if ( defined $oracle_home && length $oracle_home && -d $oracle_home &&
       (not exists $ohhash{$oracle_home}) && -e catfile($oracle_home,"bin","$ADRCI") ) {
       $tfactlglobal_oracle_homes[$ndx] = $oracle_home;
  }

  # Look for additional oracle_homes
  my @ohomesrunning;
  @ohomesrunning = dbutil_getDbsRunning();
  foreach my $oh (@ohomesrunning) {
    if ( not exists $ohhash{$oh} ) {
      $tfactlglobal_oracle_homes[$ndx++] = $oh;
      $ohhash{$oh} = TRUE;
     } # end if not exists $ohhash{$1}
  } # end foreach

  # Get ADRCI version for oracle_homes
  my $adrciout = "";
  my $ldlibpath = "";
  foreach my $oh (@tfactlglobal_oracle_homes) {
      if ( $CSH ) {
        $ldlibpath = "setenv LD_LIBRARY_PATH $oh/lib;";
      } else {
        $ldlibpath = "LD_LIBRARY_PATH=$oh/lib; export LD_LIBRARY_PATH;";
      }
      my $adrcicmd;
      my $adrcibin = catfile($oh,"bin",$ADRCI);
      if ( not $IS_WINDOWS ) {
        # $oh/bin/adrci
        if ( $CSH ) {
          if ( $IS_AIX ) {
          $adrcicmd = <<EOF;
                         setenv ORACLE_HOME $oh;setenv PATH \$ORACLE_HOME/bin:\$PATH;$ldlibpath
                         $adrcibin <<EOF1
                         exit
EOF1
EOF

          } else {
          $adrcicmd = <<EOF;
                         setenv ORACLE_HOME $oh;setenv PATH \$ORACLE_HOME/bin:\$PATH;$ldlibpath
                         $adrcibin >& /dev/stdout <<EOF1
                         exit
EOF1
EOF
          }
        } else {
          $adrcicmd = <<EOF2;
                         ORACLE_HOME=$oh;export ORACLE_HOME;PATH=\$ORACLE_HOME/bin:\$PATH;export PATH;$ldlibpath
                         $adrcibin 2>&1 <<EOF3
                         exit
EOF3
EOF2
        }
        if ( $CSH ) {
          tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_get_oracle_homes " .
                            "[goh00] adrcicmd $adrcicmd",'y', 'y');
          $adrciout = `/bin/csh -c '$adrcicmd'` if ( -r $adrcibin && -x $adrcibin );
        } else {
          $adrciout = `$adrcicmd` if ( -r $adrcibin && -x $adrcibin );
        }
      } else {
        use IPC::Open2;
        local (*Reader, *Writer);
        my $pid;
        if ( -e $adrcibin ) {
          $pid = open2(\*Reader, \*Writer, "$adrcibin");
          print Writer "exit\n";
          close Writer;

          while (<Reader>) {
             $adrciout .= $_;
          }
        } # end if -e $adrcibin
      }

      my $adrciversion="";
      foreach my $line (split /\n/, $adrciout) {
        if ( $line =~ /ADRCI\: Release ([0-9]+)\.([0-9]+)\..*/ ) {
          $adrciversion = $1 . "." . $2;
        }
      } # end foreach
      if ( not exists $tfactlglobal_oracle_homes_adrciversion{$oh} ) {
        $tfactlglobal_oracle_homes_adrciversion{$oh} = $adrciversion;
      }
      #### print "Version for O_H $oh, version $adrciversion \n";
      tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_get_oracle_homes " .
                        "Version for O_H $oh, version $adrciversion",'y', 'y');
  } # end for each @tfactlglobal_oracle_homes

  #### print "tfactlglobal_oracle_homes @tfactlglobal_oracle_homes\n";
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_get_oracle_homes " .
                    "tfactlglobal_oracle_homes @tfactlglobal_oracle_homes",'y', 'y');
  return;
}

########
# NAME
#   tfactlshare_get_adr_bases
#
# DESCRIPTION
#   This function gets the available ADR bases
#   in tfa_setup.txt
# PARAMETERS
#   $tfa_home
#   $host
#
# RETURNS
#   ADR bases for the requested host
#
########
sub tfactlshare_get_adr_bases
{
  my $tfa_home = shift;
  my $host     = shift;
  my $localhost = tolower_host();
  my @adrbases;
  my @candadrbases;
  my %adrbaseentry;
  my $adrcibin;
  my $tfasetup = tfactlshare_getSetupFilePath($tfa_home);
  ### print "shell $OSSHELL get_adr_bases \n";

  open (RF, $tfasetup) || die "Can't open $tfasetup.\n";
  while(<RF>)
  {
    chomp;
    if ( ( /^$host\%ADRBASE=(.*)/ && -d catdir($1,"diag") ) ||
         ( $host eq $localhost && /^localnode\%ADRBASE=(.*)/ && -d catdir($1,"diag") )  )
    {
      #print "ADR base $1 \n";
      push @candadrbases, $1;
    } elsif ( /^.*CRS_HOME=([\w\/\.\\\:]*)/ ) {
        if ( $1 && length $1 ) {
          my $orabase = tfactlshare_get_adrbase($1);
        push @candadrbases, $orabase if $orabase && length $orabase;
        } # end if $1 && length $1
    }
  }
  close(RF);

  if ( $IS_ADE ) {
    my $adebase = $ENV{'ADE_BASE'};
    my $adrbase = $ENV{'ADR_BASE'};
    my $oraclehome = $ENV{'ORACLE_HOME'};
    my $diagdest = "grep diagnostic_dest \$T_WORK/\*.ora 2\>/dev/null \|sed \'s/\.\*diagnostic_dest[[:space:]]\*\=[[:space:]]\*//\'";

=head
    print "ADE environment ...\n";
    print "ADE_BASE $adebase\n";
    print "ADR_BASE $adrbase\n";
    print "ORACLE_HOME $oraclehome\n";
    print "diagdest $diagdest\n";
=cut
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_get_adr_bases " .
                      "ADE environment ... ",'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_get_adr_bases " .
                      "ADE_BASE $adebase ",'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_get_adr_bases " .
                      "ADR_BASE $adrbase ",'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_get_adr_bases " .
                      "ORACLE_HOME $oraclehome ",'y', 'y');

    if ( not $IS_WINDOWS ) {
      for my $diagdestentry (split /\n/ , `$diagdest` ) {
        my $truepath;
        chomp ($truepath = `echo $diagdestentry`);
        push @candadrbases, trim($truepath);
        tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_get_adr_bases " .
                          "Diagdestentry from init $diagdestentry",'y', 'y');
        tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_get_adr_bases " .
                          "truepath from init  $truepath",'y', 'y');
        ###print "Diagdestentry from init $diagdestentry\n";
        ###print "truepath from init  $truepath\n";
      }
    } # end if not $IS_WINDOWS

    if ( $adebase && length $adebase ) {
      push @candadrbases, $adebase;  
    } 
    if ( $adrbase && length $adrbase ) {
      push @candadrbases, $adrbase;
    } 
    if ( $oraclehome && length $oraclehome ) {
      my $orabase = tfactlshare_get_adrbase($oraclehome);
      push @candadrbases, $orabase if $orabase && length $orabase;

      if ( not $IS_WINDOWS ) {
        my $commandline = "";
        $adrcibin = catfile($oraclehome,"bin","$ADRCI");
        if ( $CSH ) {
          $commandline = "setenv LD_LIBRARY_PATH " . catfile($oraclehome,"lib") . ";";
          $commandline .= "echo 'exit' |" . $adrcibin . " >& /dev/stdout";
          $commandline = "/bin/csh -c '$commandline'";
        } else {
          $commandline = "LD_LIBRARY_PATH=" . catfile($oraclehome,"lib") . ";export LD_LIBRARY_PATH;";
          $commandline .= "echo 'exit' |" . $adrcibin . " 2>&1";
        }
        tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_get_adr_bases " .
                          "[gabs00] commandline $commandline",'y', 'y');
        my $cmdout = "";
        $cmdout = `$commandline` if ( -r $adrcibin && -x $adrcibin );
        if ( $cmdout =~ /ADR base \= \"(.*)\"/ ) {
          push @candadrbases, $1 if $1 && length $1;
        }
      } # end if not $IS_WINDOWS
    } # end if $oraclehome && length $oraclehome
  } # end if $IS_ADE

  tfactlshare_get_oracle_homes($tfa_home);
  my $oh;
  my @ohomes;
  my @sohomes;
  for my $ohentry (@tfactlglobal_oracle_homes) {
     push @ohomes, $tfactlglobal_oracle_homes_adrciversion{$ohentry} . "==" . $ohentry;
  }
  my @sohomes = sort { $b <=> $a } @ohomes;
  if ( @sohomes ) {
    if ( $sohomes[0] =~ /.*\=\=(.*)/ ) {
      # return the newest ohome
      $oh = $1;
    } else {
      return @adrbases;
    }
  } else {
    return @adrbases;
  }

  foreach my $adrentry (@candadrbases) {
    my @hpaths = tfactlshare_get_homepaths($oh,$adrentry);
    next if not @hpaths;

    if ( not exists $adrbaseentry{$adrentry} ) { 
      $adrbaseentry{$adrentry} = TRUE; 
      push @adrbases, $adrentry;
    } # end if not exists $adrbaseentry{$adrentry}
  }

  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_get_adr_bases " .
                    "return adrbases @adrbases",'y', 'y');
  return @adrbases;
}

sub collectFromInventory
{
  my $tfa_home = shift;
  my $tag = shift;
  my $localhost = tolower_host();
  my $currtime = currentTime();
  my $currRepo = getCurrentRepository($tfa_home);
  my $ofile = catfile($tfa_home,"output","inventory","inventory.$$.txt");

  open(IF, catfile($tfa_home,"output","inventory","inventory.xml")) || 
               die "Can't open inventory\n";
  open(OF, ">$ofile") || die "Cant open file for writing\n";
  while(<IF>)
  {
    print OF "$1\n" if ( /file_name.(.*)\<\/file_name/ );
  }
  close(IF);
  close(OF);

  my $z_file = "logs_" . $localhost . "_" . $currtime . ".zip";
  if (defined $tag) {
    system("cat $ofile | zip $z_file -\@ > $tfa_home/log/invzip.log 2>&1");
  }
  else {
    system("cat $ofile | zip $z_file -\@ > $tfa_home/log/invzip.log 2>&1");
  }
  unlink($ofile); 
  system ("echo \"$z_file  ->  all logs\" > $tfa_home/log/diagcollect.log");
}

# From diagcollection.pl
sub currentTime   {

    my ($sec,$min,$hour,$day,$month,$year,$wday,$yday,$isdst) = localtime();

    $year += 1900;
    $month += 1;
    return sprintf("%4d%02d%02d_%02d%02d%02d", $year, $month, $day, $hour, $min, $sec);

}

sub getTimeForDate
{
  my $str = shift;
  my %months_dict_small = ("jan"=>1, "feb"=>2, "mar"=>3, "apr"=>4, "may"=>5, "jun"=>6, "jul"=>7, "aug"=>8, "sep"=>9, "oct"=>10, "nov"=>11, "dec"=>12);

  my %months_dict_caps = ("Jan"=>1, "Feb"=>2, "Mar"=>3, "Apr"=>4, "May"=>5, "Jun"=>6, "Jul"=>7, "Aug"=>8, "Sep"=>9, "Oct"=>
10, "Nov"=>11, "Dec"=>12);

  if ( $str =~ /(\w{3})\/(\d[\d]?)\/(\d{4}) (\d[\d]?):(\d[\d]?):(\d[\d]?)/ ||
       $str =~ /(\w{3})\/(\d[\d]?)\/(\d{4})/)
  {
    if (!($1 eq "Jan" || $1 eq "Feb" || $1 eq "Mar" || $1 eq "Apr" || $1 eq "May"
                  || $1 eq "Jun" || $1 eq "Jul" || $1 eq "Aug" || $1 eq "Sep"
                  || $1 eq "Oct" || $1 eq "Nov" || $1 eq "Dec" || $1 eq "jan"
                  || $1 eq "feb" || $1 eq "mar" || $1 eq "apr" || $1 eq "may"
                  || $1 eq "jun" || $1 eq "jul" || $1 eq "aug" || $1 eq "sep"
                  || $1 eq "oct" || $1 eq "nov" || $1 eq "dec")) {
        print "Invalid month : $1\n";
        return 0;
    }
    else  {
      my $month;
      if (exists($months_dict_small{$1})) {
        $month = $months_dict_small{$1};
      }
      elsif (exists($months_dict_caps{$1})) {
        $month = $months_dict_caps{$1};
      }
      #print "Month : $month\n";
      my $time;
      eval {
        if ($4 && $5 && $6) {
          $time = timelocal($6,$5,$4,$2,$month-1,$3);
        }
        else {
          $time = timelocal(0,0,0,$2,$month-1,$3);
	}
        return $time;
      };
    }
  }
}

########
# NAME
#   tfactlshare_convertDateStringforCRS
#
# DESCRIPTION
#
# PARAMETERS
#   $str     (IN) - date-time format(string)
#
# RETURNS
#   returns date-time format (string): YYYY-MM-DD HH:MI:SS
########

sub tfactlshare_convertDateStringforCRS {
  my $str = shift;
  my $newDate = $str;
  my %months_dict_small = ( "01"=>"jan", "02"=>"feb", "03"=>"mar", "04"=>"apr", "05"=>"may", "06"=>"jun", "07"=>"jul", "08"=>"aug", "09"=>"sep", "10"=>"oct", "11"=>"nov", "12"=>"dec");
  my %monthnum = reverse %months_dict_small;
  if ( $str =~ /([0-9]{4})-([0-9]{2})-([0-9]{2})\s([0-9]{2}):([0-9]{2}):([0-9]{2})/ ) {
    $newDate = $str;
  } elsif ( $str =~ /([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})/ ) {
    $newDate = $1."-".$2."-".$3." ".$4.":".$5.":".$6;
  } elsif (  $str =~ /([0-9]{4})-([0-9]{2})-([0-9]{2})/ ) {
    $newDate = $str;
  } elsif (  $str =~ /([A-Za-z]{3})\/([0-9]{2})\/([0-9]{4})\s([0-9]{2}):([0-9]{2}):([0-9]{2})/ ) {
    $newDate = $3."-".$monthnum{lc($1)}."-".$2." ".$4.":".$5.":".$6;
  } elsif (  $str =~ /([A-Za-z]{3})\/([0-9]{2})\/([0-9]{4})/ ) {
    $newDate = $3."-".$monthnum{lc($1)}."-".$2;
  }
  return $newDate;
}

########
## NAME
##   tfactlshare_adjust_time_by_seconds
##
## DESCRIPTION
##   This function takes a time and adds or subtracts a number of seconds ..
##
## PARAMETERS
##   $str     (IN) - date-time format(string)
##
## RETURNS
#########

sub tfactlshare_adjust_time_by_seconds {
  my $str = shift;
  my $func = shift;
  my $numsecs = shift;
  my $timeuts;
  my $timeout = $str;

  my $timeuts = getValidDateFromString($str,"time");

  $timeuts = $timeuts + $numsecs if ( $func eq "add" );
  $timeuts = $timeuts - $numsecs if ( $func eq "subtract" );
  $timeout = strftime "%Y-%m-%d %H:%M:%S", localtime $timeuts;

  return $timeout;
}


########
# NAME
#   tfactlshare_convertValidDateString
#
# DESCRIPTION
#   This function takes different date-time formats as input and outputs a unique format that TFA understands
#
# PARAMETERS
#   $str     (IN) - date-time format(string)
#
# RETURNS
#   returns date-time format (string): Mon/dd/yyyy hh:mm:ss
########

sub tfactlshare_convertValidDateString {
  my $str = shift;
  my $newDate = $str;
  my %months_dict_small = ( "01"=>"jan", "02"=>"feb", "03"=>"mar", "04"=>"apr", "05"=>"may", "06"=>"jun", "07"=>"jul", "08"=>"aug", "09"=>"sep", "10"=>"oct", "11"=>"nov", "12"=>"dec");

  if ( $str =~ /^([0-9]{4})-([0-9]{2})-([0-9]{2})\s([0-9]{2}):([0-9]{2}):([0-9]{2})$/ ) {
    $newDate = $months_dict_small{$2}."/".$3."/".$1." ".$4.":".$5.":".$6;
  } elsif ( $str =~ /^([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})$/ ) {
    $newDate = $months_dict_small{$2}."/".$3."/".$1." ".$4.":".$5.":".$6;
  } elsif (  $str =~ /^([0-9]{4})-([0-9]{2})-([0-9]{2})$/ ) {
    $newDate = $months_dict_small{$2}."/".$3."/".$1;
  }
  return $newDate;
}

#
## Subroutine to compare two Date/Time stamps
## Parameters: DateStrings (Date1, Date2)
## Returns :  1 if date1 greater than date2
##         :  2 if date1 equals date2
##         :  0 if date2 greater than date1
##         : -1 if either date is invalid
##
#
sub tfactlshare_cmp_timestamps {
my $ts1 = shift;
my $ts2 = shift;
my $uts1;
my $uts2;
my $validts;

$validts = getValidDateFromString($ts1, "startdate");
return -1 if $validts eq "invalid";
$validts = getValidDateFromString($ts2, "startdate");
return -1 if $validts eq "invalid";

$uts1 = getValidDateFromString($ts1, "time");
$uts2 = getValidDateFromString($ts2, "time");

return 1 if $uts1 gt $uts2;
return 2 if $uts1 eq $uts2;
return 0;

}

#
# Subroutine to get valid Date from String
# Parameters: DateString and type(startDate, endDate, time)
#
sub getValidDateFromString {
	my $str = shift;
	my $type = shift; # could be "startdate" , "enddate" or "time" or "date"
	my $year = "00";
	my $month = "00";
	my $day = "00";
	my $hour = "00";
	my $minute = "00";
	my $second = "00";
	my $time = 0;
	my @dateComponents;
	my ($i, $j);

	if ( $str =~ /\s+/ ) {
		$str =~ s/\s+/ /g;
	}

	$str =~ s/"//g;

	$str = tfactlshare_convertValidDateString($str);

	if ( lc($type) eq "enddate" ) {
		$hour = "23";
		$minute = "59";
		$second = "59";
	}
	
	if ( $str =~ /\// && $str =~ /\s/ ) {
		my @datetime = split(/\s/, $str);
		my @arr1 = split(/\//, $datetime[0]);
		my @arr2 = split(/\:/, $datetime[1]);

		for($i = 0; $i < (scalar @arr1); $i++) {
			$dateComponents[$i] = $arr1[$i];
		}
		
		for($j = 0; $j < (scalar @arr2); $j++) {
			$dateComponents[$i + $j] = $arr2[$j];
		}
		
	} elsif ( $str =~ /\// ) {
		my @datetime = split(/\s/, $str);		
		my @arr1 = split(/\//, $datetime[0]);
		
		for($i = 0; $i < (scalar @arr1); $i++) {
			$dateComponents[$i] = $arr1[$i];
		}
	}
	
	my $length = (scalar @dateComponents);
	
	if ($length > 0) {
		my %months_dict_small = ("jan"=>1, "feb"=>2, "mar"=>3, "apr"=>4, "may"=>5, "jun"=>6, "jul"=>7, "aug"=>8, "sep"=>9, "oct"=>10, "nov"=>11, "dec"=>12);
		if (exists($months_dict_small{lc($dateComponents[0])})) {
			$month = $months_dict_small{lc($dateComponents[0])};
		}
		
		if ($month == 0) {
			#print "Invalid Month: $dateComponents[0]\n";
			return "invalid";
		}
	}
	
	if ($length > 1) { 
		$day = $dateComponents[1];
	}
	
	if ($length > 2) { 
		$year = $dateComponents[2];
                if ( $year !~ /(19[789]\d|20\d\d)/ ) {
                  return "invalid";
                }
	}
	
	if ($length > 3) { 
		$hour = $dateComponents[3];
                if ( $hour !~ /([01]\d|2[0-3])/ ) {
                  return "invalid";
                }
	}
	
	if ($length > 4) { 
		$minute = $dateComponents[4];
                if ( $minute !~ /[0-5]\d/ ) {
                  return "invalid";
                }
	}
	
	if ($length > 5) { 
		$second = $dateComponents[5];
                if ( $second !~ /[0-5]\d/ ) {
                  return "invalid";
                }
	}
	
	eval {	
		$time = timelocal( $second, $minute, $hour, $day, $month - 1, $year );
	};
	
	if (my $err = $@) {
		#print "$err";
		#print "This is an invalid date.\n";
		return "invalid";
	}

	if ( lc($type) eq "time" ) {
		return $time;
	} elsif ( lc($type) eq "date" ) {
		return "$dateComponents[0]/$day/$year";
	} elsif ( lc($type) eq "eventdate" ) {
		my %months_dict = ("jan"=>"01", "feb"=>"02", "mar"=>"03", "apr"=>"04", "may"=>"05", "jun"=>"06", "jul"=>"07", "aug"=>"08", "sep"=>"09", "oct"=>"10", "nov"=>"11", "dec"=>"12");
		return $months_dict{lc($dateComponents[0])} . "/$day/$year $hour:$minute:$second";
	} else {	
		return "$dateComponents[0]/$day/$year $hour:$minute:$second";
	}
}

sub isValidDate 
{
  my $str = shift;
  my %months_dict_small = ("jan"=>1, "feb"=>2, "mar"=>3, "apr"=>4, "may"=>5, "jun"=>6, "jul"=>7, "aug"=>8, "sep"=>9, "oct"=>10, "nov"=>11, "dec"=>12);

  my %months_dict_caps = ("Jan"=>1, "Feb"=>2, "Mar"=>3, "Apr"=>4, "May"=>5, "Jun"=>6, "Jul"=>7, "Aug"=>8, "Sep"=>9, "Oct"=>10, "Nov"=>11, "Dec"=>12);

  if ( $str =~ /(\w{3})\/(\d[\d]?)\/(\d{4}) (\d[\d]?):(\d[\d]?):(\d[\d]?)/ ||
       $str =~ /(\w{3})\/(\d[\d]?)\/(\d{4})/)
  { # eg: "Oct/25/2013 09:09:09" or "Oct/25/2013"
    #print "Valid pattern\n";
    if (!($1 eq "Jan" || $1 eq "Feb" || $1 eq "Mar" || $1 eq "Apr" || $1 eq "May"
                  || $1 eq "Jun" || $1 eq "Jul" || $1 eq "Aug" || $1 eq "Sep"
                  || $1 eq "Oct" || $1 eq "Nov" || $1 eq "Dec" || $1 eq "jan"
                  || $1 eq "feb" || $1 eq "mar" || $1 eq "apr" || $1 eq "may"
                  || $1 eq "jun" || $1 eq "jul" || $1 eq "aug" || $1 eq "sep"
                  || $1 eq "oct" || $1 eq "nov" || $1 eq "dec")) {
        print "Invalid month : $1\n";
	return 0;
    }
    else  {
      my $month;
      if (exists($months_dict_small{$1})) {
        $month = $months_dict_small{$1};
      }
      elsif (exists($months_dict_caps{$1})) {
        $month = $months_dict_caps{$1};
      }
      #print "Month : $month\n";
      my $time;
      eval {
	if ($4 && $5 && $6) {
          $time = timelocal($6,$5,$4,$2,$month-1,$3);
	}
	else {
	  $time = timelocal(0,0,0,$2,$month-1,$3);
	}
      };
      if (my $err = $@) {
        print "$err\n";
        print "This is an invalid date.\n";
	return 0;
      } else {
	return 1;
      };
    }
  }
  elsif ($str =~ /(\d{4})-(\d[\d]?)-(\d[\d]?) (\d[\d]?):(\d[\d]?):(\d[\d]?)/ || $str =~ /(\d{4})-(\d[\d]?)-(\d[\d]?)/) 
  { # eg: "2013-10-25 21:03:09" or "2013-10-25"
    my $time;
    eval {
        if ($4 && $5 && $6) {
          $time = timelocal($6,$5,$4,$3,$2-1,$1);
        }
        else {
          $time = timelocal(0,0,0,$3,$2-1,$1);
        }
    };
    if (my $err = $@) {
        print "$err\n";
        print "This is an invalid date.\n";
        return 0;
    } else {
        return 1;
    };
  }
  else
  {
    print "Invalid pattern\n";
    return 0;
  }
}

#
#Diagcollect for Exadata Cell
#ARGUMENTS: 
#RETURNS:
#
sub runDiagCollectCell {

	my $TFA_HOME = shift;
	my $EXADATACELLS = shift;
	my $DSCRIPT_OPTS = shift;
	

	print "TFA_HOME: $TFA_HOME\n";
	print "EXADATA CELLS: $EXADATACELLS\n";
	print "DSCRIPT_OPTS: $DSCRIPT_OPTS\n";

}

sub defer_discovery
{
                         
       my $localhost = tolower_host();
       my $java_home = get_java_home_defer();
       my $outfile = "./ora_stack_status.out";
       open (OUT, ">$outfile") or die "Can't open file $outfile: $!\n";

       #print "Creating Output File: $outfile\n";

       print OUT "NODE_NAMES=$localhost\n";
       print OUT "JAVA_HOME=$java_home\n";


       close OUT;
}

sub racdbcloud_discovery
{
	my $outfile = "./ora_stack_status.out";
	my @dirs;
        my $dir;
        my $COMPONENT = "RACDBCLOUD";
        $COMPONENT = "ODALITE" if $IS_ODALITE;
	push (@dirs, catfile("","opt","zookeeper","log"));
	push (@dirs, catfile("","opt","oracle","dcs","log"));
	push (@dirs, catfile("","home","oracle","bkup","logs"));
	open (OUT, ">>$outfile") or die "Can't open file $outfile: $!\n";

	foreach $dir (@dirs) {
   	  if ( -d $dir ) {
             print OUT "$localhost.$COMPONENT.user_dump_dest=$dir\n";
  	  }
	}
        close(OUT);
}

sub odaDom0_discovery
{
        my $tfa_base = shift;
        my $localhost = tolower_host();
        #my $java_home = get_java_home_defer();
        my $outfile = "./ora_stack_status.out";
        open (OUT, ">$outfile") or die "Can't open file $outfile: $!\n";

        #print "Creating Output File: $outfile\n";
        print OUT "NODE_NAMES=$localhost\n";
	#print OUT "JAVA_HOME=$java_home\n";
        print OUT "$localhost.OS.user_dump_dest=/var/log\n";
        print OUT "$localhost.OS.user_dump_dest=/var/log/xen\n";
        print OUT "$localhost.ODA.user_dump_dest=/opt/oracle/oak/log";

        close OUT;
} 

sub exadataDom0_discovery
{
	my $tfa_base = shift;
	my $localhost = tolower_host();
	my $outfile = "./ora_stack_status.out";
	my $java_home = get_java_home_defer();
        open (OUT, ">$outfile") or die "Can't open file $outfile: $!\n";
	print OUT "NODE_NAMES=$localhost\n";
	print OUT "JAVA_HOME=$java_home\n";
	print OUT "$localhost.OS.user_dump_dest=/var/log\n";
        print OUT "$localhost.OS.user_dump_dest=/opt/oracle.ExaWatcher\n";
	close OUT;
}
       

#####################################  SSH APIs #####################################

#
#Subroutine to ping a Remote Host
#ARGUMENTS: REMOTE_HOST
#RETURNS: 0 if successfull else some positive Integer
#
sub pingHost {

        my $REMOTE_HOST = shift;
        #print "REMOTE HOST: $REMOTE_HOST\n";
        
	my $PLATFORM = $^O;
	my $HOSTNAME = tolower_host();

        my $PING;
        my $PING_CMD;

        if ( $PLATFORM eq "linux" ) {
                $PING = "/bin/ping";
        } else {
                $PING = "/usr/sbin/ping";
        }

        if ( $REMOTE_HOST ne $HOSTNAME ) {
                if ( $PLATFORM eq "solaris" ) {
                        $PING_CMD = "$PING -s $REMOTE_HOST 5 5 > $DEVNULL 2>&1";
                } elsif ( $PLATFORM eq "hpux" ) {
                        $PING_CMD = "$PING $REMOTE_HOST -n 5 -m 5 > $DEVNULL 2>&1";
                } else {
                        $PING_CMD = "$PING -c 1 -w 5 $REMOTE_HOST > $DEVNULL 2>&1";
                }
        } else {
		print "\nPING: REMOTE HOST[$REMOTE_HOST] IS THIS MACHINE[$HOSTNAME]\n";
		return 0;
	}

        my $PING_OUT = qx( $PING_CMD );
        my $PING_EXIT_STATUS = $?;

        dbg(DBG_WHAT, "PING OUTPUT FOR REMOTE HOST: $REMOTE_HOST\n$PING_OUT\n");
        dbg(DBG_WHAT, "\nPING EXIT STATUS: $PING_EXIT_STATUS\n");

        return $PING_EXIT_STATUS;
}

#
#Subroutine to check SSH Equivalency on Remote Host
#ARGUMENTS: REMOTE_HOST, REMOTE_USER (root)
#RETURNS: 0 if successfull else some positive Integer
#
sub checkSSHSetup {

        my $REMOTE_HOST = shift;
	my $REMOTE_USER = shift;

	if ( ! $REMOTE_USER ) {
		$REMOTE_USER = "root";
	}
	dbg(DBG_WHAT, "Checking SSH setup for $REMOTE_HOST\n");
        dbg(DBG_WHAT, "REMOTE HOST: $REMOTE_HOST\n");

        my $SSH_CMD = "$SSH -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -l $REMOTE_USER $REMOTE_HOST ls > $DEVNULL 2>&1";
	dbg(DBG_WHAT, "SSH COMMAND : $SSH_CMD\n");

        my $SSH_OUT =  qx( $SSH_CMD );
        my $SSH_EXIT_STATUS = $?;

        dbg(DBG_WHAT, "SSH OUTPUT: $SSH_OUT\n");
        dbg(DBG_WHAT, "SSH EXIT STATUS: $SSH_EXIT_STATUS\n");

        if ( $SSH_EXIT_STATUS == 0 ) {
                dbg(DBG_VERB, "$REMOTE_HOST is configured for ssh user equivalency for $REMOTE_USER user\n");
        } else {
                dbg(DBG_VERB, "$REMOTE_HOST is not configured for ssh user equivalency for $REMOTE_USER user\n");
        }
	dbg(DBG_WHAT, "Done checking SSH status for $REMOTE_HOST\n");
        return $SSH_EXIT_STATUS;
}

#
#Subroutine to get Cell Password from DB
#ARGUMENTS: TFA_HOME, REMOTE_HOST
#RETURNS: Password of REMOTE_HOST
#
sub getPassword {

	my $TFA_HOME = shift;
        my $REMOTE_HOST = shift;
	my $CRS_HOME = shift;
	#my $TFA_HOME = getTFAHome();

	my $PASSWORD = getSecretFromWallet( $TFA_HOME, $REMOTE_HOST, $CRS_HOME );

        return $PASSWORD;
}

#
#Subroutine to store Cell Password in DB
#ARGUMENTS: TFA_HOME, REMOTE_HOST, PASSWORD
#RETURNS: 0 if successfull
#
sub setPassword {

        my $REMOTE_HOST = shift;
        my $PASSWORD = shift;
        my $FILE = "/tmp/.$REMOTE_HOST.pwd";

        open ( FILE, ">$FILE" ) or print "\nUnable to store password to DB\n";
        print FILE "PASSWORD=$PASSWORD\n";
        close ( FILE );

        return 0;
}

#
#Subroutine to get Cell Password from user and store it in DB
#ARGUMENTS: TFA_HOME, REMOTE_HOST
#RETURNS: 0 if successfull
#
sub readPassword {

        my $REMOTE_HOST = shift;
        my $PASSWORD;
        my $CONF_PASS;

        print "Please Enter the password for HOST $REMOTE_HOST: ";
        system("stty", "-echo");
        chomp( $PASSWORD = <STDIN> );

        system("stty", "echo");
        print "\nPlease Confirm the password for HOST $REMOTE_HOST: ";
        system("stty", "-echo");
        chomp( $CONF_PASS = <STDIN> );
        system("stty", "echo");

        print "\n";

        if ( $PASSWORD eq $CONF_PASS ) {
                setPassword( $REMOTE_HOST, $PASSWORD );
        } else {
                print "Both Password should be same. Exiting now.\n";
                exit 1;
        }
}

#
#Subroutine to create Expect to run on REMOTE_HOST
#ARGUMENTS: EXPFILE, HOST, USER, PASS
#
sub expectConnect {

        my $EXPFILE = shift;
        my $HOST = shift;
        my $USER = shift;
        my $PASS = shift;

        open ( EXPFILE, ">$EXPFILE" ) or print "\nUnable to open Expect File $EXPFILE\n";

        print EXPFILE <<EOF
#! /usr/bin/expect

set timeout 3
set prompt "(%|#|\\\\\$) \$";
catch {set prompt \$env(EXPECT_PROMPT)}

spawn $SSH $USER\@$HOST;

expect {
        "no)?" {
                send -- "yes\\n"
                exp_continue
        }
        "*?assword:*" {
                send -- "$PASS\\n"
                exp_continue
        }
        "Permission denied *" {
                exit 2;
        }
        LoginSuccessfull {
                exit 0;
        }
        -re \$prompt  {
        }
        timeout {
                send_error "Connect to $HOST was timed out.\\n"
                exit 3
        }
}
EOF
;
        close ( EXPFILE );
        return 0;
}

#
#Subroutine to close Expect
#ARGUMENTS: EXPFILE
#
sub expectClose {
        my $EXPFILE = shift;

        open ( EXPFILE, ">>$EXPFILE" ) or print "\nUnable to open Expect File $EXPFILE\n";

        print EXPFILE <<EOF

expect -re \$prompt;
send -- "exit\\n";
send_user "\\n";
EOF
;
        close ( EXPFILE );
        return 0;
}

#
#Subroutine to place command in expect
#ARGUMENTS: EXPFILE, COMMAND
#
sub expectCommand {
        my $EXPFILE = shift;
        my $COMMAND = shift;

        open ( EXPFILE, ">>$EXPFILE" ) or print "\nUnable to open Expect File $EXPFILE\n";

        print EXPFILE <<EOF

expect -re \$prompt;
send -- "$COMMAND\\n";
EOF
;
        close ( EXPFILE );
        return 0;
}

#
#Subroutine to run Expect using system
#ARGUMENTS: EXPFILE
#
sub expectRun {

        my $EXPFILE = shift;

        if ( -f $EXPFILE ) {
                qx ( chmod 600 $EXPFILE );
                print "Running $EXPFILE...\n\n";
                system ( $EXPFILE );
        } else {
                print "Unable to locate $EXPFILE...\n";
        }
}

#
#Subroutine to run Expect using pipe
#ARGUMENTS: EXPFILE
#
sub expectRunUsingPipe {

        my $EXPFILE = shift;

        if ( -f $EXPFILE ) {
                qx ( chmod 600 $EXPFILE );

                my $EXPECT_COMMAND = "$EXPFILE";

                open ( EXPECT_COMMAND, "| $EXPECT_COMMAND " ) or
                         print "Unable to Execute Command: $EXPECT_COMMAND\n";

                while (<EXPECT_COMMAND>) {
                        print "EXPECT_COMMAND LINE: $_\n";
                }
                close (EXPECT_COMMAND);

        } else {
                print "Unable to locate $EXPFILE...\n";
        }
}

#
#Subroutine to run Expect using qx and send the result to file
#ARGUMENTS: EXPFILE, OUTFILE
#
sub expectRunUsingqx {

        my $EXPFILE = shift;
        my $OUTFILE = shift;

        if ( -f $EXPFILE ) {
                qx ( chmod 600 $EXPFILE );

                my $EXP = qx ( $EXPFILE );

                open ( OUTFILE, ">$OUTFILE" ) or print "\nUnable to open file $OUTFILE\n";
                print OUTFILE "$EXP";
                close (OUTFILE);
        } else {
                print "Unable to locate $EXPFILE...\n";
        }
}

#
#Subroutine to remove Expect
#ARGUMENTS: EXPFILE
#
sub expectRemove {

        my $EXPFILE = shift;

        if ( -f "$EXPFILE" ) {
                #print "Removing $EXPFILE...\n";
                unlink "$EXPFILE";
        } else {
                print "Unable to remove $EXPFILE\n";
        }
}

#
#Subroutine to run command on REMOTE_HOST using Expect
#ARGUMENTS: REMOTE_HOST, COMMAND to run like scp
#RETURNS: 0 on Success
#
sub expectRunCommand {

	my $TFA_HOME = shift;
	my $REMOTE_HOST = shift;
        my $COMMAND = shift;
	my $CRS_HOME = shift;
	my $OUTFILE = shift;

	if ( ! defined( $OUTFILE ) )  {
		$OUTFILE = $DEVNULL;
	}

        my $PASS = getPassword( $TFA_HOME, $REMOTE_HOST, $CRS_HOME );
        my $PROCESSID = $$;
        my $EXPECTFILE = "$TFA_HOME/tmp/.$PROCESSID.exp";

        open ( EXPFILE, ">$EXPECTFILE" ) or print "\nUnable to open Expect File\n";

        print EXPFILE <<EOF
#! /usr/bin/expect

set timeout -1
set prompt "(%|#|\\\\\$) \$";
catch {set prompt \$env(EXPECT_PROMPT)}

spawn -noecho $COMMAND

expect {
        "no)?" {
                send -- "yes\\n"
                exp_continue
        }
        "*?assword:*" {
                send -- "$PASS\\n"
                exp_continue
        }
        "Permission denied *" {
                #send_error "\\nPermission denied. Please check the password of Remost Host.\\n";
                exit 2;
        }
        LoginSuccessfull {
                exit 0;
        }
        -re \$prompt  {
        }
        timeout {
                send_error "Connect to REMOTE HOST was timed out.\\n"
                exit 3
        }
}
EOF
;
        close ( EXPFILE );

        qx ( chmod 600 $EXPECTFILE );
        system ( "$EXPECTFILE > $OUTFILE" );

	my $EXIT_STATUS = $?;

	unlink ( $EXPECTFILE );

        return $EXIT_STATUS;
}


#
#Subroutine to check Password of Remote Host
#ARGUMENTS: TFA_HOME, REMOTE_HOST, PASSWORD
#RETURNS 0 if password is correct else some positive interger.
#
sub expectCheckRemotePassword {

	my $TFA_HOME = shift;
	my $REMOTE_HOST = shift;
	my $PASS = shift;
        my $COMMAND = "$SSH root\@$REMOTE_HOST ls";
	dbg(DBG_WHAT, "command in expectCheckRemotePasswd : $COMMAND\n");
        my $PROCESSID = $$;
        my $EXPECTFILE = "$TFA_HOME/tmp/.$PROCESSID.exp";

        open ( EXPFILE, ">$EXPECTFILE" ) or print "\nUnable to open Expect File\n";

        print EXPFILE <<EOF
#! /usr/bin/expect

set timeout 10
set prompt "(%|#|\\\\\$) \$";
catch {set prompt \$env(EXPECT_PROMPT)}

spawn -noecho $COMMAND

expect {
        "no)?" {
                send -- "yes\\n"
                exp_continue
        }
        "*?assword:*" {
                send -- "$PASS\\n"
                exp_continue
        }
        "Permission denied *" {
                #send_error "\\nPermission denied. Please check the password of Remost Host.\\n";
                exit 2;
        }
        LoginSuccessfull {
                exit 0;
        }
        -re \$prompt  {
        }
        timeout {
                send_error "Connect to REMOTE HOST was timed out.\\n"
                exit 3
        }
}
EOF
;
        close ( EXPFILE );

        qx ( chmod 600 $EXPECTFILE );
        system ( "$EXPECTFILE > $DEVNULL" );

	my $EXIT_STATUS = $?;

        unlink ( $EXPECTFILE );
	dbg(DBG_WHAT, "exit status : $EXIT_STATUS\n");
        return $EXIT_STATUS;

}


########################### APIs for EXADATA Support ###############################

#
#Subroutine to determine if node has a Exadata setup
#ARGUMENTS:
#RETURNS: 1 if Exadata Setup else 0
#
sub isExadata {

	my $CELLIPFILE = "/etc/oracle/cell/network-config/cellip.ora";
	my $FLAG = 0;

	if ( -f "$CELLIPFILE" ) {
		$FLAG = 1;
	}

	return $FLAG;
}

#
#Subroutine to determine if TFA has configured Exadata Setup
#ARGUMENTS:
#RETURNS: 1 if Exadata Setup is configured in TFA else 0
#
sub isExadataConfigured {

	my $TFA_HOME = shift;
	my $CELLFILE = "$TFA_HOME/internal/cellnames.txt";
	my $FLAG = 0;

	if ( -f "$CELLFILE" ) {
		$FLAG = 1;
	}

	return $FLAG;
}

#
#Subroutine to get Exadata Cell IPs
#ARGUMENTS: 
#RETURNS: Array containing Cell IP
#
sub getCellIpList {

        my $CELLIPFILE = "/etc/oracle/cell/network-config/cellip.ora";
        my @IPLIST;

	if ( ! -f "$CELLIPFILE" ) {
		print "\nUnable to find cellip.ora[$CELLIPFILE]\n";
		exit 1;
	}

        open ( FILE, "<$CELLIPFILE" ) or print "Unable to open $CELLIPFILE\n";

        while ( <FILE> ) {
                chomp();
                if ( /cell=\"(.*)\"/ ) {
                        push( @IPLIST, (split( /;/, $1))[0] );
                }
        }
        close (FILE);

        return @IPLIST;
}

sub getHostNameUsingSSH {

	my $REMOTE_HOST = shift;
	
	my $COMMAND = "$SSH root\@$REMOTE_HOST hostname";

	my $HOSTNAME = qx ( $COMMAND );

	$HOSTNAME = trim( $HOSTNAME );

        if ( $HOSTNAME =~ /\./ ) {
                $HOSTNAME = (split( /\./, $HOSTNAME ))[0];
        }

	dbg(DBG_WHAT, "IP: $REMOTE_HOST HOSTNAME: $HOSTNAME\n");

        return $HOSTNAME;
}


sub getHostNameUsingExpect {

	my $TFA_HOME = shift;
	my $REMOTE_HOST = shift;
	my $PASSWORD = shift;
	my $HOSTNAME;
	my $PROCESSID = $$;
	my $REMOTE_USER = "root";
	my $EXPECTFILE = "$TFA_HOME/tmp/.$REMOTE_HOST.$PROCESSID.exp";
	my $TEMP = "$TFA_HOME/tmp/.$REMOTE_HOST.$PROCESSID.out";
	my $COMMAND = "$SSH $REMOTE_USER\@$REMOTE_HOST hostname";

	open ( EXPFILE, ">$EXPECTFILE" ) or print "\nUnable to open Expect File\n";

	print EXPFILE <<EOF
#! /usr/bin/expect

set timeout 10
set prompt "(%|#|\\\\\$) \$";
catch {set prompt \$env(EXPECT_PROMPT)}

spawn -noecho $COMMAND

expect {
        "no)?" {
                send -- "yes\\n"
                exp_continue
        }
        "*?assword:*" {
                send -- "$PASSWORD\\n"
                exp_continue
        }
        "Permission denied *" {
                send_error "\\nPermission denied. Please check the password of Remost Host.\\n";
                exit 2;
        }
        LoginSuccessfull {
                exit 0;
        }
        -re \$prompt  {
        }
        timeout {
                send_error "Connect to REMOTE HOST was timed out.\\n"
                exit 3
        }
}
EOF
;

	close ( EXPFILE );

	qx ( chmod 600 $EXPECTFILE );
	system ( "$EXPECTFILE > $TEMP" );

	$HOSTNAME = qx ( tail -1 $TEMP );

	unlink "$EXPECTFILE";
	unlink "$TEMP";

	$HOSTNAME = trim( $HOSTNAME );

        if ( $HOSTNAME =~ /\./ ) {
                $HOSTNAME = (split( /\./, $HOSTNAME ))[0];	
	}
		
	return $HOSTNAME;
}

sub tempgetHostNameUsingExpect {

	my $TFA_HOME = getTFAHome();
	my $REMOTE_HOST = shift;
	my $PASSWORD = shift;
	my $HOSTNAME;
	my $COMMAND = "hostname";
	my $PROCESSID = $$;
	my $REMOTE_USER = "root";
	my $EXPECTFILE = "$TFA_HOME/tmp/.$REMOTE_HOST.$PROCESSID.exp";
	my $OUTFILE = "$TFA_HOME/tmp/.$REMOTE_HOST.$PROCESSID.out";
	my $FLAG = 0;

	expectConnect ( $EXPECTFILE, $REMOTE_HOST, $REMOTE_USER, $PASSWORD );
	expectCommand ( $EXPECTFILE, $COMMAND );
	expectClose ( $EXPECTFILE );
	expectRunUsingqx ( $EXPECTFILE, $OUTFILE );
	expectRemove ( $EXPECTFILE );

	open ( OUTFILE, "<$OUTFILE" ) or print "\nUnable to open file $OUTFILE\n";

	while (<OUTFILE>) {

		if ( $FLAG == 1 ) {
			$HOSTNAME = $_;
			last;
		}

		if ( /(.*)$COMMAND/ ) {
			$FLAG = 1;
		}
	}

	close (OUTFILE);
	unlink "$OUTFILE";

        if ( $HOSTNAME =~ /\s/ ) {
                $HOSTNAME =~ s/\s//g;
        }

        if ( $HOSTNAME =~ /\./ ) {
                $HOSTNAME = (split( /\./, $HOSTNAME ))[0];
        }

        return $HOSTNAME;

}
#
#Subroutine to get HOSTNAME using IP Address
#ARGUMENTS: REMOTE_HOST( IP ADDRESS)
#RETURNS: HOSTNAME for that IP ADDRESS
#
sub getRemoteHostName {

	my $TFA_HOME = shift;
        my $REMOTE_HOST = shift;
	my $REMOTE_PASS = shift;
	my $SSH_STATUS = shift;
        my $REMOTE_USER = "root";
        my $COMMAND = "hostname";
        my $HOSTNAME;

	if ( ! defined $SSH_STATUS ) {
		$SSH_STATUS = checkSSHSetup( $REMOTE_HOST );
	}

        #my $PING_STATUS = pingHost( $REMOTE_HOST );

        #if ( $PING_STATUS != 0 ) {
        #        print "\nUNABLE TO PING HOST $REMOTE_HOST\n";
        #        exit 1;
        #}

        #my $SSH_STATUS = checkSSHSetup( $REMOTE_HOST );

        if ( $SSH_STATUS == 0 ) {
                $HOSTNAME = getHostNameUsingSSH ( $REMOTE_HOST );
        } else {
		$HOSTNAME = getHostNameUsingExpect( $TFA_HOME, $REMOTE_HOST, $REMOTE_PASS );
        }

        return $HOSTNAME;
}

#
#Subroutine to Exadata Cells Names
#ARGUMENTS:
#RETURNS: Array containing Exadata Cell Names
#
sub getOnlineCells {

	my $TFA_HOME = shift;
	my @CELLS;

	if ( ! defined( $TFA_HOME ) ) {
		$TFA_HOME = getTFAHome ();
	}

	my $FILE = catfile($TFA_HOME, "internal", "cellnames.txt");
	my $CELL;

	open ( FILE, "<$FILE" ) or print "\nUnable to open file $FILE\n";

	while ( <FILE> ) {

		$CELL = $_;

		if ( $CELL ) {
			$CELL = trim( $CELL );
			push ( @CELLS, $CELL );
		}
	}

	@CELLS = tfactlshare_uniqList(@CELLS);
        return @CELLS;
}

#
#Subroutine to store Exadata Cell Names to TFA_HOME/internal/cellnames.txt
#ARGUMENTS: TFA_HOME
#RETURNS: 0 if successfull
#
sub storeExadataCells {

	my $TFA_HOME = shift;
	my @CELLS = @{ @_[0] };

	my $FILE = "$TFA_HOME/internal/cellnames.txt";

	open ( FILE, ">>$FILE" ) or print "\nUnable to create file $FILE\n";

	foreach ( @CELLS ) {
		print FILE "$_\n";
	}
	close ( FILE );

	return 0;
}

#
#Subroutine to store Exadata Cell IPs to TFA_HOME/internal/cellips.txt
#ARGUMENTS: TFA_HOME
#RETURNS: 0 if successfull
#
sub storeExadataCellIps {

	my $TFA_HOME = shift;
	my @CELLIPLIST = @{ @_[0] };

	my $FILE = "$TFA_HOME/internal/cellips.txt";

	open ( FILE, ">>$FILE" ) or print "\nUnable to create file $FILE\n";

	foreach ( @CELLIPLIST ) {
		print FILE "$_\n";
	}
	close ( FILE );

	return 0;
}

#
#Subroutine to print Exadata Cells Names
#ARGUMENTS:
#RETURNS:
#
sub printOnlineCells {

        my @CELLS = getOnlineCells();

        foreach ( @CELLS ) {
                print "CELL NAME: $_\n";
        }
}

#
# Subroutine to print Exadata Cells using cellnames.txt without Ping
#
sub printConfiguredCells {

        my $TFA_HOME = shift;

        my $EXADATA = isExadataConfigured( $TFA_HOME );

        if ( $EXADATA == 0 ) {
                print "\nStorage Cells are not configured with TFA. Please Configure it using 'tfactl cell configure'.\n";
                exit 1;
        }

        my $COUNT = 1;
	my $STATUS = "ONLINE";
	my $CELL;
        my $TABLE = Text::ASCIITable->new();
        $TABLE->setCols('','EXADATA CELL','CURRENT STATUS');

	my @CELLS = getOnlineCells();

        foreach $CELL ( @CELLS ) {
                $TABLE->addRow( $COUNT, $CELL, $STATUS );
                $COUNT += 1;
        }

        print "$TABLE\n"
}

sub printCellInventoryRunStatus {

        use POSIX;

        my $TFA_HOME = shift;

        my $EXADATA = isExadataConfigured( $TFA_HOME );

        if ( $EXADATA == 0 ) {
                print "\nStorage Cells are not configured with TFA. Please Configure it.\n";
                exit 1;
        }

        my @CELLS = getOnlineCells( $TFA_HOME );

        my $TABLE = Text::ASCIITable->new();
        $TABLE->setCols("STORAGE CELL", "LAST RUN STARTED", "LAST RUN ENDED", "STATUS");
        $TABLE->setOptions({"outputWidth" => $tputcols, "headingText" => "Storage Cell Inventory Run Statistics"});

        my $CELL;
        my $STATUS;
        my $START;
        my $END;
        my $FORMAT = "%b %e %H:%M:%S";

        foreach $CELL ( @CELLS ) {
                $STATUS = "COMPLETE";

                $START = getCellInvStartTime( $TFA_HOME, $CELL );
                $END = getCellInvEndTime( $TFA_HOME, $CELL );

                if ( $START > $END ) {
                        $STATUS = "RUNNING";
                }

                if ( $START != 0 ) {
                        $START = strftime $FORMAT, localtime( $START );
                } else {
                        $START = "-";
                }

                if ( $END != 0 ) {
                        $END = strftime $FORMAT, localtime( $END );
                } else {
                        $END = "-";
                }

                $TABLE->addRow( $CELL, $START, $END, $STATUS );
        }

        print $TABLE;
}

sub printCellDiagCollectRunStatus {

        my $TFA_HOME = shift;

        my $EXADATA = isExadataConfigured( $TFA_HOME );

        if ( $EXADATA == 0 ) {
                print "\nStorage Cells are not configured with TFA. Please Configure it.\n";
                exit 1;
        }

        my @CELLS = getOnlineCells( $TFA_HOME );

        my $TABLE = Text::ASCIITable->new();
        $TABLE->setCols("STORAGE CELL","CURRENT STATUS");
        $TABLE->setOptions({"outputWidth" => $tputcols, "headingText" => "Cell Diagcollect Run Statistics"});

        my $CELL = $CELLS[0];
        my $STATUS;
        my $CRS_HOME = get_crs_home( $TFA_HOME );
        my $PING_STATUS;
        my $SSH_STATUS = checkSSHSetup( $CELL );

        foreach $CELL ( @CELLS ) {
                $STATUS = "-";

                $PING_STATUS = pingHost( $CELL );

                if ( $PING_STATUS != 0 ) {
                        $STATUS = "CELL IS OFFLINE";
                } else {
                        my $COUNT = runCommandOnRemoteWithStatus( $TFA_HOME, $CELL, "$SSH $CELL ps -ef | grep tfa | grep -v grep | wc -l", $CRS_HOME, $SSH_STATUS );

                        if ( $COUNT > 0 ) {
                                $STATUS = "RUNNING";
                        }
                }

                $TABLE->addRow( $CELL, $STATUS );
        }

        print $TABLE;
}

#
#Subroutine to get files from REMOTE_HOST
#ARGUMENTS: REMOTE_HOST, SOURCE, DESTINATION, REMOTE_USER ( optional )
#RETURNS: 0 on success
#
sub getRemoteFiles {

	my $REMOTE_HOST = shift;
	my $SOURCE = shift;
	my $DESTINATION = shift;
	my $REMOTE_USER = shift;

	if ( ! $REMOTE_USER ) {
		$REMOTE_USER = "root";
	}

	my $COMMAND = "$SCP $REMOTE_USER\@$REMOTE_HOST:$SOURCE $DESTINATION";

	my $SSH_STATUS = checkSSHSetup( $REMOTE_HOST );

	if ( $SSH_STATUS == 0 ) {
		qx( $COMMAND );
	} else {
		expectRunCommand ( $REMOTE_HOST, $COMMAND );
	}

	return 0;
}

#
#Subroutine to send files to REMOTE_HOST
#ARGUMENTS: REMOTE_HOST, SOURCE, DESTINATION, REMOTE_USER ( optional )
#RETURNS: 0 on success
#
sub sendFilesToRemote {

        my $REMOTE_HOST = shift;
        my $SOURCE = shift;
        my $DESTINATION = shift;
        my $REMOTE_USER = shift;

        if ( ! $REMOTE_USER ) {
                $REMOTE_USER = "root";
        }

        my $COMMAND = "$SCP $SOURCE $REMOTE_USER\@$REMOTE_HOST:$DESTINATION";

        my $SSH_STATUS = checkSSHSetup( $REMOTE_HOST );

        if ( $SSH_STATUS == 0 ) {
                qx( $COMMAND );
        } else {
                expectRunCommand ( $REMOTE_HOST, $COMMAND );
        }

        return 0;
}

#
#Subroutine to run command on REMOTE_HOST. It uses Oracle Wallet if SSH is not set.
#Arguments: TFA_HOME, REMOTE_HOST, COMMAND, SSH_STATUS( optional )
#Returns: This will not return anything.
#
sub runCommandOnRemote {

	my $TFA_HOME = shift;
	my $REMOTE_HOST = shift;
	my $COMMAND = shift;
	my $CRS_HOME = shift;
	my $SSH_STATUS = shift;

	if ( ! defined($SSH_STATUS) ) {
		$SSH_STATUS = checkSSHSetup( $REMOTE_HOST );
	}

	if ( $SSH_STATUS == 0 ) {
		qx( $COMMAND );
	} else {
		expectRunCommand ( $TFA_HOME, $REMOTE_HOST, $COMMAND, $CRS_HOME );
	}	
}

#
#Subroutine to run command on REMOTE_HOST. It uses Oracle Wallet if SSH is not set.
#Arguments: TFA_HOME, REMOTE_HOST, COMMAND, OUTFILE, SSH_STATUS( optional )
#Returns: The output of command will be in OUTFILE
#
sub runCommandOnRemoteWithStatus {

        my $TFA_HOME = shift;
        my $REMOTE_HOST = shift;
        my $COMMAND = shift;
	my $CRS_HOME = shift;
	my $SSH_STATUS = shift;

	my $OUTFILE = "$TFA_HOME/tmp/$$.$REMOTE_HOST.tmp";
	my $COMMAND_OUTPUT;

        if ( ! defined($SSH_STATUS) ) {
                $SSH_STATUS = checkSSHSetup( $REMOTE_HOST );
        }

        if ( $SSH_STATUS == 0 ) {
                qx( $COMMAND > $OUTFILE );
		$COMMAND_OUTPUT = qx( cat $OUTFILE );
		unlink ( $OUTFILE );
        } else {
                expectRunCommand ( $TFA_HOME, $REMOTE_HOST, $COMMAND, $CRS_HOME, $OUTFILE );
		#$COMMAND_OUTPUT = qx( tail -1 $OUTFILE );
		$COMMAND_OUTPUT = qx( sed -n '2,\$'p $OUTFILE );
		unlink ( $OUTFILE );
        }

	return $COMMAND_OUTPUT;
}

sub promptForPassword {

	my $DESC = shift;
	my $CONFIRM = shift;
	my $PASSWORD;
	my $CONFPASS;
	my $AGAIN = 1;
	my $COUNT = 1;

	while ( $AGAIN == 1 && $COUNT <= 3) {

		print "Please Enter Password for $DESC: ";
		system("stty", "-echo");
		chomp( $PASSWORD = <STDIN> );
		system("stty", "echo");

		if ( $CONFIRM == 1 ) {

			print "\nPlease Confirm Password for $DESC: ";
			system("stty", "-echo");
			chomp( $CONFPASS = <STDIN> );
			system("stty", "echo");

			if ( ! $PASSWORD ) {
				print "\n\nPassword cannot be NULL\n\n";
			} elsif ( $PASSWORD eq $CONFPASS ) {
				$AGAIN = 0;
			} else {
				print "\n\nBoth Passwords should be the same...!!!\n\n";
			}
		} elsif ( $PASSWORD ) {
			$AGAIN = 0;
		} else {
			print "\n\nPassword cannot be NULL\n\n";
		}

		$COUNT += 1;
	}

	if ( $COUNT > 3 ) {
		print "\nMax Count Reached. Please try later.\n";
		exit 1;
	}

	return $PASSWORD;
}

#
#Subroutine to Configure Exadata Cells while installing TFA
#ARGUMENTS: TFA_HOME
#
sub configureCells {

	my $TFA_HOME = shift;
	my $SILENT = shift;
	my @CELLIPLIST = getCellIpList();
        dbg(DBG_WHAT, "Cell ip list : @CELLIPLIST\n");
	my $HOSTNAME;
	my $STORECELL;
	my $OPTION;
	my $CELLPASSWORD;
	my $WALLETPWD;
	my $IP = $CELLIPLIST[0];
	my @CELLNAMES;
	my $PING_STATUS = 1;
	my $SSH_STATUS = 1;
	my @SSHIPLIST;
	my @PINGIPLIST;
	my @NONIPLIST;

	# Check SSH Setup for all Cell IPs
	foreach $IP ( @CELLIPLIST ) {		

		$SSH_STATUS = -1;
		$PING_STATUS = pingHost( $IP );

		if ( $PING_STATUS == 0 ) {
			$SSH_STATUS = checkSSHSetup( $IP );

			if ( $SSH_STATUS == 0 ) {
				push( @SSHIPLIST, $IP );
			} else {
				push( @PINGIPLIST, $IP );
			}

		} else {
			push( @NONIPLIST, $IP );
		}

		dbg(DBG_WHAT, "IP: $IP\tPing Status: $PING_STATUS\tSSH Status: $SSH_STATUS\n");
	}

	my $SSHIPSIZE = scalar @SSHIPLIST;
	my $PINGIPSIZE = scalar @PINGIPLIST;
	my $NONIPSIZE = scalar @NONIPLIST;

	dbg(DBG_WHAT, "SSH List: @SSHIPLIST\nPING List: @PINGIPLIST\nNON-IP List: @NONIPLIST\n");

	# Return if SSH List is empty and Silent is enabled
	if ( $SILENT && $SSHIPSIZE == 0 ) {
		print "TFA will not configure Storage Cells as silent is enabled.\n";
		return;
	}

	# Process SSH List
	if ( $SSHIPSIZE > 0 ) {

		print "TFA will configure Storage Cells using SSH Setup:\n\n";

		foreach $IP ( @SSHIPLIST ) {

			$HOSTNAME = getHostNameUsingSSH ( $IP );
			$HOSTNAME = trim( $HOSTNAME );
			if ( $HOSTNAME ) {
				push ( @CELLNAMES, $HOSTNAME );
			}
		}

		storeExadataCells ( $TFA_HOME, \@CELLNAMES );
		storeExadataCellIps ( $TFA_HOME, \@SSHIPLIST );

		# Print the Cell Name and return if Silent is enabled
		if ( $SILENT ) {
			printConfiguredCells( $TFA_HOME );
			return;
		}
	}
		
	# Empty the Cell Name List
	@CELLNAMES = ();

	# Return if both Ping list and Non-IP list are empty
	if ( $PINGIPSIZE == 0 && $NONIPSIZE == 0 ) {
		# Print configured cells when silent is not enabled
                if ( $SSHIPSIZE > 0 ) {
                        printConfiguredCells( $TFA_HOME );
                }
		return;
	}

	# Process Ping List and Non-Ip List
	if ( $NONIPSIZE > 0 ) {

		my $MANUAL;
		print "Unable to determine the Storage Cells. Do you want to Enter Cells manually. [Y|y|N|n] [Y]: ";
		chomp( $MANUAL = <STDIN> );
		$MANUAL ||= "Y";
		$MANUAL = get_valid_input ( $MANUAL, "Y|y|N|n", "Y");

		if ( $MANUAL =~ /[Yy]/ ) {

			my $CELL_NAMES;
			my $CELL;
			my @CELLS;
			print "\nPlease Enter Cells seperated by (,) like CELL_1,CELL_2.\n\nCELLS: ";
			chomp( $CELL_NAMES = <STDIN> );

			foreach $CELL (split /,/ , $CELL_NAMES) {
				push (@CELLS, trim($CELL));
			}

			@CELLIPLIST = @CELLS;
			print "\n";

		} else {
			print "\n\nPlease Configure Storage Cells later.\n";
			return;
		}
	} elsif ( $PINGIPSIZE > 0 ) {
		@CELLIPLIST =  @PINGIPLIST;
	} else {
		return;
	}

	dbg(DBG_WHAT, "CELL IP List: @CELLIPLIST\n");
		
	print "Do you want us to store the Password for Cells in Oracle Wallet: [Y|y|N|n] [Y]: ";
	chomp( $STORECELL = <STDIN> );
	$STORECELL ||= "Y";
	$STORECELL = get_valid_input ( $STORECELL, "Y|y|N|n", "Y");

	if ( $STORECELL =~ /[Yy]/ ) {

	   my $PWD_STATUS;
	   my $CRS_HOME = get_crs_home( $TFA_HOME );

	   if ( ! $CRS_HOME ) {
		print "Unable to determine CRS_HOME/GI_HOME. Please try again later.\n";
		return;
	   }

	   my $AGAIN = 1;
	   my $COUNT = 1;

	   # Create a wallet here

	   dbg(DBG_WHAT, "Creating Oracle Wallet: $TFA_HOME/internal/tfawallet\n");

	   while ( $AGAIN == 1 && $COUNT <= 3 ) {

		print "\n";
		$WALLETPWD = promptForPassword( "Oracle Wallet", 1 );
		setWalletPassword( $TFA_HOME, $WALLETPWD );
		my $WALLET_STATUS = createWallet( $TFA_HOME, $CRS_HOME );

		if ( $WALLET_STATUS != 0 ) {
			print "\n\nUnable to create Oracle Wallet. Password should be Alphanumeric.\n";
			removeWalletPassword( $TFA_HOME );
			rmtree "$TFA_HOME/internal/tfawallet";
			$COUNT += 1;
		} else {
			$AGAIN = 0;
		}
	   }

	   if ( $COUNT > 3 ) {
		print "\n\nCreation of Oracle Wallet was unsuccessful. Please Configure Storage Cells later.\n";
		return;
	   }

	   $AGAIN = 1;
	   $COUNT = 1;

	   print "\n\nIs password the same for all Storage Cells: [Y|y|N|n] [Y]: ";
	   chomp( $OPTION = <STDIN> );
	   $OPTION ||= "Y";
	   $OPTION = get_valid_input ( $OPTION, "Y|y|N|n", "Y");

	   if ( $OPTION =~ /[Yy]/ ) {

		$IP = $CELLIPLIST[0];

		print "\n";

		while ( $AGAIN == 1 && $COUNT <= 3 ) {

			$CELLPASSWORD = promptForPassword( "Cell", 1 );

			print "\n\nVerifying Password...\n";

			$PWD_STATUS = expectCheckRemotePassword( $TFA_HOME, $IP, $CELLPASSWORD );

			if ( $PWD_STATUS != 0 ) {
				print "\nPassword provided for Cell [IP: $IP ] is incorrect. Please try again.\n";
				$COUNT += 1;
			} else {
				$AGAIN = 0;
			}
		}

		if ( $COUNT > 3 ) {
			print "\nPassword provided for Cell [IP: $IP ] is incorrect. Please try later..\n";
			return;
		}

		print "\n";

		foreach $IP ( @CELLIPLIST ) {

			$HOSTNAME = getHostNameUsingExpect ( $TFA_HOME, $IP, $CELLPASSWORD );

			if ( $HOSTNAME ) {
				# Verify the Hostname again by pinging
				$PING_STATUS = pingHost( $HOSTNAME );

				if ( $PING_STATUS == 0 ) {
					push ( @CELLNAMES, $HOSTNAME );
					addEntryInWallet( $TFA_HOME, $HOSTNAME, $CELLPASSWORD, $CRS_HOME );
				} else {
					print "Unable to determine the hostname for Storage Cell IP [$IP]. Please check manually.\n\n";
				}
			}
		}

	   } else {

		# Handle all the different password for all cells
		foreach $IP ( @CELLIPLIST ) {

			$AGAIN = 1;
			print "\n";

			while ( $AGAIN == 1 && $COUNT <= 3 ) {
				$CELLPASSWORD = promptForPassword( "Cell [ IP: $IP ]", 0 );
				print "\n\nVerifying Password for Cell [ IP: $IP ]...";
				$PWD_STATUS = expectCheckRemotePassword( $TFA_HOME, $IP, $CELLPASSWORD );

				if ( $PWD_STATUS != 0 ) {
					print "\n\nPassword provided for Cell [IP: $IP ] is incorrect. Please try again.\n\n";
					$COUNT += 1;
				} else {
					$AGAIN = 0;
				}
			}

			if ( $COUNT > 3 ) {
				print "Password provided for Cell [IP: $IP ] is incorrect. Please try later..\n";
				return;
			}

			print "\n";

			$HOSTNAME = getHostNameUsingExpect ( $TFA_HOME, $IP, $CELLPASSWORD );

			if ( $HOSTNAME ) {
				# Verify the Hostname again by pinging
				$PING_STATUS = pingHost( $HOSTNAME );

				if ( $PING_STATUS == 0 ) {
					push ( @CELLNAMES, $HOSTNAME );
					addEntryInWallet( $TFA_HOME, $HOSTNAME, $CELLPASSWORD, $CRS_HOME );
				} else {
					print "Unable to determine the hostname for Cell IP[$IP]. Please check manually.\n\n";
				}
			}
		}
	   }

	   storeExadataCells ( $TFA_HOME, \@CELLNAMES );
	   storeExadataCellIps ( $TFA_HOME, \@CELLIPLIST );

	   printConfiguredCells ( $TFA_HOME );

	} else {
		print "\nPassword for Cells are not stored in Oracle Wallet.\n";
		print "This can be configured later using \"tfactl cell configure\".\n";
	}
}


sub configureSwitches {

	my $TFA_HOME = shift;
	my $SILENT = shift;

}

sub addWalletPasswordByUser {

	my $TFA_HOME = shift;

	my $WALLET = checkWallet( $TFA_HOME );

	if ( $WALLET != 1 ) {
		print "\nTFA is not configured with Oracle Wallet.\n";
		exit 1;
	}

	my $CUR_PASS;

	$CUR_PASS = promptForPassword( "Oracle Wallet", 0 );

	my $CHECK = checkWalletPassword( $TFA_HOME, $CUR_PASS );

	if ( $CHECK != 0 ) {
		print "\nOracle Wallet Password you Entered is incorrect. Please try again.\n";
		exit 1;
	}

	updateWalletPasswordInDB( $TFA_HOME, $CUR_PASS );

	print "\nOracle Wallet Password is successfully added.\n";
}

sub getTFAHome {

	use Cwd;
	use File::Basename;

	my $BASEDIR =  dirname ($0);

	if ( $BASEDIR =~ /^\./ ) {
		my $cwd = getcwd;
		$BASEDIR =~ s/\./$cwd/;
	}

	if ( $BASEDIR =~ /\/bin/ ) {
		$BASEDIR =~ s/\/bin//;
	} elsif ( $BASEDIR eq "bin" ) {
		$BASEDIR = getcwd;
	}

	my $TFA_HOME;

	if ( $ENV{TFA_HOME} ) {
		$TFA_HOME = $ENV{TFA_HOME};
	} else {
		$TFA_HOME = $BASEDIR;
	}

	#print "\nBASEDIR: $BASEDIR\n";
	#print "\nTFA_HOME: $TFA_HOME\n";

	return $TFA_HOME;
}



############################ Oracle Wallet APIs ###########################

sub createWallet {

        my $TFA_HOME = shift;
	my $CRS_HOME = shift;

        my $PASSWORD = getWalletPassword ( $TFA_HOME );

	if ( ! defined ( $CRS_HOME ) ) {
		$CRS_HOME = get_crs_home( $TFA_HOME );
	}

        my $WALLET_CMD = "$CRS_HOME/bin/orapki wallet create -wallet $TFA_HOME/internal/tfawallet";

        open( CREATE, "| $WALLET_CMD > $DEVNULL" );
        print CREATE "$PASSWORD\n";
        print CREATE "$PASSWORD\n";
        close ( CREATE );

	my $STATUS = $?;

	return $STATUS;
}

sub removeWallet {

        my $TFA_HOME = shift;
        my $CRS_HOME = shift;

        my $PASSWORD = getWalletPassword ( $TFA_HOME );

        if ( ! defined ( $CRS_HOME ) ) {
                $CRS_HOME = get_crs_home( $TFA_HOME );
        }

        my $WALLET_CMD = "$CRS_HOME/bin/mkstore -nologo -wrl $TFA_HOME/internal/tfawallet -delete";

        open( DELETE, "| $WALLET_CMD > $DEVNULL" );
        print DELETE "$PASSWORD\n";
        close ( DELETE );

        my $STATUS = $?;

        return $STATUS;
}


sub checkWallet {

        my $TFA_HOME = shift;
	my $FLAG = 0;

	if ( -d "$TFA_HOME/internal/tfawallet" ) {
		$FLAG = 1;
	}

	return $FLAG;
}

sub checkWalletPassword {

	my $TFA_HOME = shift;
	my $PASSWORD = shift;
	my $CRS_HOME = shift;

	if ( ! defined ( $CRS_HOME ) ) {
		$CRS_HOME = get_crs_home( $TFA_HOME );
	}

	my $WALLET_CMD = "$CRS_HOME/bin/mkstore -nologo -wrl $TFA_HOME/internal/tfawallet -list";

	open( CHECK, "| $WALLET_CMD > $DEVNULL" );
	print CHECK "$PASSWORD\n";
	close ( CHECK );

	my $STATUS = $?;

	return $STATUS;
}


sub syncWallet {

        my $TFA_HOME = shift;
	my $PASSWORD = getWalletPassword ( $TFA_HOME );
	setFlag( $TFA_HOME, "walletpassword=$PASSWORD", 1 );
	removeWalletPassword( $TFA_HOME );
}


sub setWalletPassword {

	my $TFA_HOME = shift;
	my $PASSWORD = shift;
	my $FILE = "$TFA_HOME/internal/.wallet.pwd";

	open ( FILE, ">$FILE" ) or print "\nUnable to store Oracle Wallet Password to DB\n";
	print FILE "$PASSWORD\n";
	close ( FILE );

	chmod(0600, $FILE);
	return 0;
}

sub removeWalletPassword {

	my $TFA_HOME = shift;
	my $FILE = "$TFA_HOME/internal/.wallet.pwd";

	if ( -e $FILE ) {
		unlink ( $FILE );
	}
}


sub getWalletPassword {

	my $TFA_HOME = shift;

	my $FILE = "$TFA_HOME/internal/.wallet.pwd";
	my $PASSWORD;

	if ( -e "$FILE" ) {
		$PASSWORD = qx ( cat $TFA_HOME/internal/.wallet.pwd );
	} else {
		#$PASSWORD = qx ( $TFA_HOME/bin/tfactl print walletpassword );
		$PASSWORD = getWalletPasswordFromDB( $TFA_HOME );
	}

	$PASSWORD = trim( $PASSWORD );

	return $PASSWORD;
}

sub getWalletPasswordFromDB {

	my $TFA_HOME = shift;
	my $LOCALHOST = tolower_host();
	my $MESSAGE = "$LOCALHOST:printwalletpassword";
	my $command = buildCLIJava( $TFA_HOME, $MESSAGE );
	
	my $LINE;
	my $FLAG = 0;
	my $PASSWORD;
	my @cli_output = tfactlshare_runClient($command);
	foreach $LINE ( @cli_output ) {
		if ( $LINE eq "DONE" ) {
			$FLAG = 1;
		} else {
			$PASSWORD = $LINE;
		}
	}

	if ( $FLAG == 1 ) {
		#print "\nWallet Password from DB: $PASSWORD\n";
		return $PASSWORD;
	} else {
		return FAILED;
	}
}

sub updateWalletPasswordInDB {

	my $TFA_HOME = shift;
	my $PASSWORD = shift;

	setFlag( $TFA_HOME, "walletpassword=$PASSWORD", 1 );

}

sub removeWalletPasswordFromDB {

	my $TFA_HOME = shift;
	setFlag( $TFA_HOME, "walletpassword=null", 1 );
}

sub addEntryInWallet {

        my $TFA_HOME = shift;
	my $ALIAS = shift;
	my $SECRET = shift;
	my $CRS_HOME = shift;

        my $PASSWORD = getWalletPassword ( $TFA_HOME );

	if ( ! defined ( $CRS_HOME ) ) {
		$CRS_HOME = get_crs_home( $TFA_HOME );
	}

        my $WALLET_CMD = "$CRS_HOME/bin/mkstore -nologo -wrl $TFA_HOME/internal/tfawallet -createEntry $ALIAS";

        open( ENTRY, "| $WALLET_CMD > $DEVNULL" );
        print ENTRY "$SECRET\n";
        print ENTRY "$SECRET\n";
        print ENTRY "$PASSWORD\n";
        close ( ENTRY );
}


sub listEntriesInWallet {

        my $TFA_HOME = shift;
	my $CRS_HOME = shift;

        if ( ! defined ( $CRS_HOME ) ) {
                $CRS_HOME = get_crs_home( $TFA_HOME );
        }

        my $PASSWORD = getWalletPassword ( $TFA_HOME );

        my $WALLET_CMD = "$CRS_HOME/bin/mkstore -nologo -wrl $TFA_HOME/internal/tfawallet -list";

        my $OUTFILE = "$TFA_HOME/internal/.temp.out";

        open( LIST, "| $WALLET_CMD > $OUTFILE" );
        print LIST "$PASSWORD\n";
        close ( LIST );

        open ( TEMP, "<$OUTFILE" );

        while ( <TEMP> ) {
                #print "OUTPUT: $_";
        }
        close ( TEMP );
        unlink ( $OUTFILE );

}


sub getSecretFromWallet {

        my $TFA_HOME = shift;
	my $ALIAS = shift;
	my $CRS_HOME = shift;

        my $PASSWORD = getWalletPassword ( $TFA_HOME );
        my $CELLPASS;

        if ( ! defined ( $CRS_HOME ) ) {
                $CRS_HOME = get_crs_home( $TFA_HOME );
        }

        my $WALLET_CMD = "$CRS_HOME/bin/mkstore -nologo -wrl $TFA_HOME/internal/tfawallet -viewEntry $ALIAS";

        my $OUTFILE = "$TFA_HOME/internal/.$ALIAS.out";

        open( SECRET, "| $WALLET_CMD > $OUTFILE " );
        print SECRET "$PASSWORD\n";
        close ( SECRET );

        open ( TEMP, "<$OUTFILE" );

        while ( <TEMP> ) {
                #print "OUTPUT: $_";

                if ( /$ALIAS = (.*)/ ) {
                        $CELLPASS = $1;
                }
        }
        close ( TEMP );
        unlink ( $OUTFILE );

        #print "PASSWORD FOR CELL $ALIAS: \"$CELLPASS\"\n";

	return $CELLPASS;
}

sub updateSecretInWallet {

        my $TFA_HOME = shift;
        my $ALIAS = shift;
        my $SECRET = shift;
        my $CRS_HOME = shift;

	my $PASSWORD = getWalletPassword ( $TFA_HOME );

        if ( ! defined ( $CRS_HOME ) ) {
                $CRS_HOME = get_crs_home( $TFA_HOME );
        }

        my $WALLET_CMD = "$CRS_HOME/bin/mkstore -nologo -wrl $TFA_HOME/internal/tfawallet -modifyEntry $ALIAS";

        open( ENTRY, "| $WALLET_CMD > $DEVNULL" );
        print ENTRY "$SECRET\n";
        print ENTRY "$SECRET\n";
        print ENTRY "$PASSWORD\n";
        close ( ENTRY );

}

sub removeEntryFromWallet {

        my $TFA_HOME = shift;
        my $ALIAS = shift;
        my $CRS_HOME = shift;

        my $PASSWORD = getWalletPassword ( $TFA_HOME );

        if ( ! defined ( $CRS_HOME ) ) {
                $CRS_HOME = get_crs_home( $TFA_HOME );
        }

        my $WALLET_CMD = "$CRS_HOME/bin/mkstore -nologo -wrl $TFA_HOME/internal/tfawallet -deleteEntry $ALIAS";

	open( REMOVE, "| $WALLET_CMD > $DEVNULL" );
	print REMOVE "$PASSWORD\n";
	close ( REMOVE );
}

# Subroutine to get the replacedHostName of any node in a cluster
# # Arguments: TFA_HOME and Node

 sub getReplacedHostName {

        my $tfa_home = shift;
        my $node = shift;
        my $localhost = tolower_host();
        my $replacedHostName;
        my $line;
        if (isTFARunning($tfa_home) == FAILED) {
                exit 0;
        }
        if ( ! $node ) {
            $node = $localhost;
        }

        dbg(DBG_WHAT, "Running printReplacedHostName through Java CLI in getReplacedHostName\n");
        my $message = "$localhost:getReplacedHostName:$node";
        my $command = buildCLIJava($tfa_home,$message);
        dbg(DBG_VERB, "$command\n");
	my @cli_output = tfactlshare_runClient($command);
        foreach $line ( @cli_output ) {
                if ( $line =~ /!/ ) {
                     $replacedHostName = (split(/!/, $line))[0];
                }
         }
                                                                                                                                                                                          return $replacedHostName;
                                                                                                                                                                                 }

sub getInventoryLocation {

        my $tfa_home = shift;
	my $node = shift;
        my $localhost = tolower_host();
        my $inventory;
        my $line;
        my $paramfile = tfactlshare_getSetupFilePath($tfa_home);

	if ( ! $node ) {
		$node = $localhost;
	}

        if (isTFARunning($tfa_home) == FAILED) {
                exit 0;
        }

	if ( $ISCLOUD || isOfflineMode($paramfile) ) {
		my $tfa_base = getTFABase();
		$inventory = catfile($tfa_base, "output", "inventory");
	} else {
	        dbg(DBG_WHAT, "Running getInventoryLocation through Java CLI in getInventoryLocation\n");
        	my $message = "$localhost:getInventoryLocation:$node";
	        my $command = buildCLIJava($tfa_home,$message);
        	dbg(DBG_VERB, "$command\n");
		my @cli_output = tfactlshare_runClient($command);
	        foreach $line ( @cli_output ) {
        	        if ( $line =~ /!/ ) {
                	        $inventory = (split(/!/, $line))[0];
	                }
        	}
	}

	return $inventory;
}

sub getLogDirectory {

        my $tfa_home = shift;
        my $localhost = tolower_host();
        my $logdir;
        my $line;

        if (isTFARunning($tfa_home) == FAILED) {
                exit 0;
        }

        dbg(DBG_WHAT, "Running getLogDirectory through Java CLI in getLogDirectory\n");
        my $message = "$localhost:getLogDirectory";
        my $command = buildCLIJava($tfa_home,$message);
        dbg(DBG_VERB, "$command\n");
	my @cli_output = tfactlshare_runClient($command);
        foreach $line ( @cli_output ) {
                if ( $line =~ /!/ ) {
                        $logdir = (split(/!/, $line))[0];
                }
        }

        return $logdir;
}

sub tfactlshare_get_diag_directory {
        my $tfa_home = shift;
        my $tfa_base = tfactlshare_parentDirectory($tfa_home);
        my $localhost = tolower_host();
        my $diagdir;
        my $logdir;
        my $crs_home;
        my $oracle_base;
        my $tfapath;

        if ( not -d $tfa_home ) {
          # TFA_HOME is not set correctly
          tfactlshare_signal_exception(200, undef);
        }

        $crs_home = get_crs_home( $tfa_home );
        $oracle_base = get_oracle_base($tfa_home);
        if (length($crs_home) != 0) { 
	        $tfapath = catfile($crs_home,"tfa",$localhost,"tfa_home");
		$tfapath =~ s/\\/\\\\/g;
		$tfapath = abs_path($tfapath) if ( -d $tfapath );
    	}	
        $tfa_home = abs_path($tfa_home);

        ### print "crs_home    $crs_home \n";
        ### print "oracle_base $oracle_base\n";
        ### print "tfapath     $tfapath\n";
        ### print "tfa_home    $tfa_home\n";

        if ( $crs_home && $oracle_base && 
             $tfa_home =~ /\Q$tfapath/ ) {
          $diagdir = catfile($oracle_base,"tfa","$localhost","diag","tfa");
          $logdir = catfile($oracle_base,"tfa","$localhost","log");
        }
        elsif ( $oracle_base && -d catfile($oracle_base,"tfa",$localhost,"diag") ) {
          $diagdir = catfile($oracle_base,"tfa","$localhost","diag","tfa");
          $logdir  = catfile($oracle_base,"tfa","$localhost","log");
        }
	elsif ( $ISCLOUD ) {
	  my $homedir = getHomeDirectory();
	  $homedir = catfile($homedir, ".tfa");
	  $tfa_base = getTFABase(catfile($homedir, "tfa_setup.txt"));
	  my $user = tfactlshare_getUserName();	  
	  if ($IS_WINDOWS) {
		$user = tfactlshare_getEscapedUserName($user);
	  }

	  if ( -d "$tfa_base" ) {
	    $diagdir = catfile($tfa_base, "diag", "tfa"); 
            $logdir  = catfile($tfa_base, "log");
	  } else {
	    $diagdir = catfile("", "tmp", "oracle.tfa", $localhost, $user, "diag", "tfa");
            $logdir  = catfile("", "tmp", "oracle.tfa", $localhost, $user, "log");
	  }
	}
        else {
          $diagdir = catfile($tfa_base,"diag","tfa");
          $logdir  = catfile($tfa_base,"log");
        }

        tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_get_diag_directory ". 
                          "diagdir: $diagdir ", 'y', 'n');
        tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_get_diag_directory ".
                          "logdir: $logdir ", 'y', 'n');
        tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_get_diag_directory ". 
                          "tfa_base: $tfa_base ", 'y', 'n');
        tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_get_diag_directory ".
                          "tfa_home: $tfa_home ", 'y', 'n');


        return ($diagdir,$logdir);
}

# Subroutine to get OLR Location
sub getOLRLocation {
	my $olrLocation;
	if ( -f catfile("", "etc", "oracle", "olr.loc") ) {
		$olrLocation = catfile("", "etc", "oracle", "olr.loc");
	} elsif ( -f catfile("", "var", "opt", "oracle", "olr.loc") ) {
		$olrLocation = catfile("", "var", "opt", "oracle", "olr.loc");
	}
	return $olrLocation;
}

# Subroutine to get CRS_HOME from OLR
sub getCRSFromOLR {
	my $olr = getOLRLocation();
	my $crs_home = "";

	if ( -f "$olr") {
		open(RF, "$olr");
		while (<RF>) {
			chomp;
			if ( /^crs_home=(.*)/ ) {
				$crs_home = $1;
				last;
			}
		}
		close (RF);
	}
	return $crs_home;
}

############################ TFA Setup without Discovery ###########################
sub db_discovery
{
  my $ohome = shift;
  my $obase = shift;
  my $tfa_base = shift;
  my $localhost = tolower_host();

  my $outfile = "ora_stack_status.out";
  open (OUT, ">$outfile") or die "Can't open file $outfile: $!\n";

  my $crs_home = getCRSFromOLR();
  if ( -f catfile($crs_home, "crs", "install", "crsconfig_params") ) {
    print OUT "CRS_HOME=$crs_home\n";
  }

  print OUT "NODE_NAMES=$localhost\n";
  print OUT "$localhost.CFGTOOLS.user_dump_dest=".catdir($obase,"cfgtoollogs")."\n";
  print OUT "$localhost.RDBMS.user_dump_dest=".catdir($obase,"diag")."\n";
  print OUT "$localhost.CFGTOOLS.user_dump_dest=".catdir($ohome,"cfgtoollogs")."\n";
  print OUT "$localhost.INSTALL.user_dump_dest=".catdir($ohome,"install")."\n";
  print OUT "$localhost.RDBMS.user_dump_dest=".catdir($ohome,"rdbms","log")."\n";
  print OUT "$localhost.RDBMS.user_dump_dest=".catdir($ohome,"rdbms","trace")."\n";

  if ( -f "$ohome/oraInst.loc" )
  {
    open(RF, "$ohome/oraInst.loc");
    my $inv_loc = "";
    while (<RF>)
    {
      chomp;
      if ( /inventory_loc=(.*)/ )
      {
        $inv_loc = $1;
      }
    }
    close(RF);
    if ( $inv_loc )
    {
      print OUT "$localhost.INSTALL.user_dump_dest=$inv_loc/ContentsXML\n";
      print OUT "$localhost.INSTALL.user_dump_dest=$inv_loc/logs\n";
    }
  }
  print OUT "JAVA_HOME=$tfa_base/tfa_home/jre\n";
  if ( $ORACLE_BASE ) {
    print OUT "ORACLE_BASE=$ORACLE_BASE\n";
  }

  close(OUT);
}

sub crs_discovery
{
        my $crs_home = shift;
        my $tfa_base = shift;
        my $localhost = tolower_host();

        my $cwd = getcwd;
        my $outfile = catfile($cwd,"ora_stack_status.out");
        open (OUT, ">$outfile") or die "Can't open file $outfile: $!\n";

        #print "Creating Output File: $outfile\n";

        print OUT "CRS_HOME=$crs_home\n";
        print OUT "$localhost.CRS_INSTALLED=1\n";
        print OUT "NODE_NAMES=$localhost\n";
        print OUT "$localhost.INSTALL.user_dump_dest=".catdir($crs_home,"install")."\n";
        print OUT "$localhost.CFGTOOLS.user_dump_dest=".catdir($crs_home,"cfgtoollogs")."\n";
        print OUT "$localhost.ASM.user_dump_dest=".catdir($crs_home,"rdbms","log")."\n";
        print OUT "$localhost.ASM.user_dump_dest=".catdir($crs_home,"rdbms","trace")."\n";
        print OUT "$localhost.DBWLM.user_dump_dest=".catdir($crs_home,"oc4j","j2ee","home","log")."\n";
        print OUT "$localhost.CRS.user_dump_dest=".catdir($crs_home,"log")."\n";
        print OUT "$localhost.CRS.user_dump_dest=".catdir($crs_home,"cv","log")."\n";
        print OUT "$localhost.CRS.user_dump_dest=".catdir($crs_home,"opmn","logs")."\n";
        print OUT "$localhost.CRS.user_dump_dest=".catdir($crs_home,"OPatch","crs","log")."\n";
        print OUT "$localhost.CRS.user_dump_dest=".catdir($crs_home,"evm","log")."\n";
        print OUT "$localhost.CRS.user_dump_dest=".catdir($crs_home,"evm","admin","logger")."\n";
        print OUT "$localhost.CRS.user_dump_dest=".catdir($crs_home,"evm","admin","log")."\n";
        print OUT "$localhost.CRS.user_dump_dest=".catdir($crs_home,"racg","log")."\n";
        print OUT "$localhost.CRS.user_dump_dest=".catdir($crs_home,"scheduler","log")."\n";
        print OUT "$localhost.CRS.user_dump_dest=".catdir($crs_home,"srvm","log")."\n";
        print OUT "$localhost.CRS.user_dump_dest=".catdir($crs_home,"crs","log")."\n";
        print OUT "$localhost.CRS.user_dump_dest=".catdir($crs_home,"network","log")."\n";
        print OUT "$localhost.CRS.user_dump_dest=".catdir($crs_home,"crf","db","$localhost")."\n";

	if ( -f catfile($crs_home,"oraInst.loc") )
	{
	  open(RF, catfile($crs_home,"oraInst.loc"));
	  my $inv_loc = "";
	  while (<RF>)
	  {
	    chomp;
	    if ( /inventory_loc=(.*)/ )
	    {
	      $inv_loc = $1;
	    }
	  }
	  close(RF);
	  if ( $inv_loc )
	  {
	    print OUT "$localhost.INSTALL.user_dump_dest=".catdir($inv_loc,"ContentsXML")."\n";
	    print OUT "$localhost.INSTALL.user_dump_dest=".catdir($inv_loc,"logs")."\n";
	  }
	}

	if ( -f catfile($crs_home,"crs","install","crsconfig_params") )
	{
	  open(RF, catfile($crs_home,"crs","install","crsconfig_params") );
	  while(<RF>)
	  {
	    chomp;
	    if ( /^ORACLE_BASE=(.*)/ )
	    {
	       dbg(DBG_WHAT, "\n$_");
	       $ORACLE_BASE = $1;
	       dbg(DBG_WHAT, "ORACLE_BASE inside crs_discovery: $ORACLE_BASE\n");
	       last;
            }
	  }
	  close(RF);
	}

	if ( ! $ORACLE_BASE ) {
		# Get ORACLE_BASE using $crs_home/bin/orabase
		dbg(DBG_WHAT, "Checking ORACLE_BASE using ".catfile($crs_home,"bin","orabase")."\n");
		my $cmdFile = catfile($crs_home,"bin","orabase");
		$ORACLE_BASE = qx($cmdFile);
		$ORACLE_BASE = trim( $ORACLE_BASE );
		dbg(DBG_WHAT, "Oracle Base: '$ORACLE_BASE'\n");
	}

	if ( -d $ORACLE_BASE ) {	
           if( -d catdir($ORACLE_BASE,"crsdata",$localhost,"acfs") ) {
	      print OUT "$localhost.ACFS.user_dump_dest=".catdir($ORACLE_BASE,"crsdata",$localhost,"acfs")."\n";
	   }
	   if( -d catdir($ORACLE_BASE,"crsdata",$localhost,"output") ) {
              print OUT "$localhost.CRS.user_dump_dest=".catdir($ORACLE_BASE,"crsdata",$localhost,"output")."\n";
           }
	   if( -d catdir($ORACLE_BASE,"crsdata",$localhost,"cvu") ) {
              print OUT "$localhost.CRS.user_dump_dest=".catdir($ORACLE_BASE,"crsdata",$localhost,"cvu")."\n";
           }
	   if( -d catdir($ORACLE_BASE,"crsdata",$localhost,"rhp") ) {
              print OUT "$localhost.RHP.user_dump_dest=".catdir($ORACLE_BASE,"crsdata",$localhost,"rhp")."\n";
           }
	   if( -d catdir($ORACLE_BASE,"crsdata",$localhost,"evm") ) {
              print OUT "$localhost.CRS.user_dump_dest=".catdir($ORACLE_BASE,"crsdata",$localhost,"evm")."\n";
           }
	   if( -d catdir($ORACLE_BASE,"crsdata",$localhost,"crsconfig") ) {
              print OUT "$localhost.CRS.user_dump_dest=".catdir($ORACLE_BASE,"crsdata",$localhost,"crsconfig")."\n";
           }
	   if( -d catdir($ORACLE_BASE,"crsdata",$localhost,"afd") ) {
	       print OUT "$localhost.ASM.user_dump_dest=".catdir($ORACLE_BASE,"crsdata",$localhost,"afd")."\n";
           }
	   if( -d catdir($ORACLE_BASE,"crsdata",$localhost,"chad") ) {
              print OUT "$localhost.CRS.user_dump_dest=".catdir($ORACLE_BASE,"crsdata",$localhost,"chad")."\n";
           }
	   if( -d catdir($ORACLE_BASE,"crsdata",$localhost,"core") ) {
              print OUT "$localhost.CRS.user_dump_dest=".catdir($ORACLE_BASE,"crsdata",$localhost,"core")."\n";
           }
	   if( -d catdir($ORACLE_BASE,"crsdata",$localhost,"trace") ) {
              print OUT "$localhost.CRS.user_dump_dest=".catdir($ORACLE_BASE,"crsdata",$localhost,"trace")."\n";
           }
	   if( -d catdir($ORACLE_BASE,"crsdata",$localhost,"crsdiag") ) {
              print OUT "$localhost.CRS.user_dump_dest=".catdir($ORACLE_BASE,"crsdata",$localhost,"crsdiag")."\n";
           }
	   print OUT "ORACLE_BASE=$ORACLE_BASE\n";
	} else {
		print "\nTFA-00102: Unable to determine ORACLE_BASE. Exiting Installation now...\n";
		close OUT;
		exit 1;
	}

        print OUT "JAVA_HOME=".catdir($crs_home,"jdk","jre")."\n";

        close OUT;

}

########
# NAME
#   tfactlshare_init_tracebasepath
#
# DESCRIPTION
#   This function creates tfactl/ directory under 
#   ($TFA_HOME)/log/diag/ directory if it does not exist.
#   This is to allow trace directories to be created under tfactl 
#   for any user
#
# PARAMETERS
#   $basepath   - base directory where tfactl/ will be created.
#
# RETURNS
#    NULL
#
# NOTE:  $TFA_HOME/log/diag is assumed to exist
#        only tfactl/ will be created underneath.
########
sub tfactlshare_init_tracebasepath
{
  my ($basepath) = shift ;
  my $perm = "1741";
  if ( $basepath =~ /user_/ ) {
    $perm = "1740";
  }
  
  eval { tfactlshare_mkpath("$basepath", $perm);
       };
  if ($@)
  {
    tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_init_tracebasepath " .
                     "Can not create path $basepath",'y', 'n') if
    defined $DIAGDIR;
    $DIAGDIR = 0;
  }

  return;
}

########
## NAME
##  tfactlshare_check_type_base
##
## DESCRIPTION
##  This routine checks type_base.
##
## PARAMETERS
##   $tfa_home - TFA_HOME
##   $type     - ips, srdc or ddu
##
## RETURNS
##   Null.
##
#########
sub tfactlshare_check_type_base
{
  my ($tfa_home) = shift;
  my ($type)     = shift;
  if ( lc($type) ne "ips" && lc($type) ne "srdc" && lc($type) ne "ddu" ) {
    print "Error, type must be ips, srdc or ddu.\n";
    print "Directories not initialized.\n";
    return;
  } 
  my $tfa_base  = tfactlshare_get_repository_location($tfa_home);
  my $tool_base = catfile($tfa_base, "suptools");
  tfactlshare_create_dir("$tool_base", "1741") if ( ! -d "$tool_base" );
  my $type_base = catfile($tfa_base, "suptools", $type);
  tfactlshare_create_dir("$type_base", "1741") if ( ! -d "$type_base" );

  return;
}

########
# NAME
#  tfactlshare_init_trace
#
# DESCRIPTION
#  This routine initializes the tracing - creates trace directory with
#  appropriate owner/group/permission.  Also parses command line arguments
#  for "verbose".  If "verbose", trace-level specified in ARGV, 
#  this routine removes it.
#
# PARAMETERS
#   GLOBAL: @ARGV (IN/OUT) - list of all command line arguments for tfactl.
#   $tfa_home - TFA_HOME
#
# RETURNS
#   Null.
#
########
sub tfactlshare_init_trace
{
  my ($tfa_home) = shift;
  my ($user, $host);
  my $diagdir;
  my $logdir;

  $user = tfactlshare_get_user();
  $host = hostname();

  #print "tfactlshare_init_trace user $user host $host \n";

  if (! $DIAGDIR ) {
    # Set base trace path
    ($diagdir,$logdir) = tfactlshare_get_diag_directory($tfa_home);

    if ( not (defined $tfactlglobal_diag_base &&
              ($tfactlglobal_diag_base ne "") &&
              (-d $tfactlglobal_diag_base)) )
    {
      $tfactlglobal_diag_base = catdir($diagdir,"tfactl");
    }

    my $mode = (stat("$diagdir"))[2];
    $mode = sprintf("%04o",$mode & 07777);
    eval { chmod(oct(1741),$diagdir) if $mode ne "1741"; };

    tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_init_trace " .
                      "Current mode for $diagdir -> $mode",'y', 'n');

    tfactlshare_init_tracebasepath ($tfactlglobal_diag_base);
    $tfactlglobal_log_path   = $logdir;
    my $escaped_user = $user;
    if($IS_WINDOWS){
    	$escaped_user = tfactlshare_getEscapedUserName($escaped_user);
    }
    $tfactlglobal_trace_path = catdir("$tfactlglobal_diag_base","user_$escaped_user","trace");
    $tfactlglobal_alert_path = catdir("$tfactlglobal_diag_base","user_$escaped_user","alert");

    $tfactlglobal_trace_path =~ /([^\n^\r^\t]+)/;
    $tfactlglobal_trace_path =$1;

    eval { tfactlshare_mkpath("$tfactlglobal_trace_path", "1740") if ( ! -d "$tfactlglobal_trace_path" );
         };
    #print "Trying to create $tfactlglobal_trace_path\n";
    if ($@)
    {
      # print STDERR "Can not create path $tfactlglobal_trace_path \n";
      tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_init_trace " .
                        "Can not create path $tfactlglobal_trace_path , DIAGDIR $DIAGDIR",'y', 'n');
      $DIAGDIR = 0;
    }
    eval { tfactlshare_mkpath("$tfactlglobal_alert_path", "1740") if ( ! -d "$tfactlglobal_alert_path" );
         };
    #print "Trying to create $tfactlglobal_alert_path\n";
    if ($@)
    {
      # print STDERR "Can not create path $tfactlglobal_alert_path \n";
      tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_init_trace " .
                        "Can not create path $tfactlglobal_alert_path , DIAGDIR $DIAGDIR",'y', 'n');
      $DIAGDIR = 0;
    }

    $DIAGDIR = 1;
  }

  #print "tfactlglobal_trace_path $tfactlglobal_trace_path \n";
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_init_trace " .
                    "user: $user, host: $host",'y', 'n');
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_init_trace " .
                    "tfactlglobal_trace_path: $tfactlglobal_trace_path",'y', 'n');
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_init_trace " .
                    "tfactlglobal_alert_path: $tfactlglobal_alert_path",'y', 'n');
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_init_trace " .
                    "tfactlglobal_diag_base: $tfactlglobal_diag_base",'y', 'n');
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_init_trace " .
                    "tfactlglobal_log_path: $tfactlglobal_log_path",'y', 'n');
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_init_trace " .
                    "Completed setting up DIAGDIR for user $user in host $host",'y', 'n');

  return;
}

########
# NAME
#   tfactlshare_validate_user_by_key()
#
# DESCRIPTION
#   This routine checks the user is valid to run tfa by checking user keys exist.
#
# PARAMETERS
#   None.
#
# RETURNS
#
# NOTES
########
sub tfactlshare_validate_user_by_key
{
  # manuegar_extract_tfa_03
  my $setupfile = tfactlshare_getSetupFilePath($tfa_home);
  my $ndmode    = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"SUPPORT_MODE",$setupfile);
  # print "tfactlshare_validate_user_by_key setupfile $setupfile\n";
  # print "tfactlshare_validate_user_by_key ndmode    $ndmode\n";

  my $tfauser = tfactlshare_get_user();
  if($IS_WINDOWS && !($tfauser eq "root")){
  	$tfauser = tfactlshare_getEscapedUserName($tfauser);
  }

  my $keyfile = catfile($tfa_home,".$tfauser",$tfauser . "_mykey.rsa.pub");
  my $bidfile = catfile($tfa_home,"internal",".buildid");

  # If we are not the home owner or have valid keys then we should not be running from this home.
  if ((not -e $keyfile) && (not -r $bidfile)) {
    print "User $tfauser does not have keys to run TFA from $tfa_home. Please check with TFA Admin(root)\n";
    return "FAIL";
  }

  # Check the user key files exists - if not we are not a valid TFA user.
  # print "tfactlshare_validate_user_by_key keyfile : $keyfile \n";
  if ((not -e $keyfile) && ($DAEMON_OWNER ne $tfauser) && ( $ndmode ne "TRUE" ) && ($SETUPND != 1)) {
    print "User $tfauser does not have keys to run TFA. Please check with TFA Admin(root)\n";
    return "FAIL";
  }
}

########
# NAME
#   tfactlshare_set_verbose()
# 
# DESCRIPTION
#   This routine sets the verbose mode
# 
# PARAMETERS
#   None.
#
# RETURNS
#
# NOTES
########
sub tfactlshare_set_verbose
{
  my ($i);

  ###print "Array before : @ARGV  .. \n";

  # Default tracing is errors
  $tfactlglobal_hash{'verbose'} ='errors';

  for ($i = 0; $i < $#ARGV+1; )
  {
    if ($ARGV[$i] eq '-verbose')
    { # -verbose check
      #remove the option from ARGV array if found
      splice(@ARGV,$i,1);
      if (defined($ARGV[$i]))
      {
        if (defined($tfactlshare_trace_levels{$ARGV[$i]}))
        {
          $tfactlglobal_hash{'verbose'} =$ARGV[$i];
        }
        else
        {
          print STDERR "WARNING: Specified tracing level '$ARGV[$i]' does".
                                                " not exist.\n";
          $tfactlglobal_hash{'verbose'} ='normal';
          print STDERR "Default level of tracing is enabled.\n";
        }
        #remove the value  of trace level from ARGV array if found
        splice(@ARGV,$i,1);
      }
      else
      {
        print STDERR "WARNING: Tracing level not specified\n";
        $tfactlglobal_hash{'verbose'} ='normal';
        print STDERR "Default level of tracing is enabled.\n";
      }
      #last;
      next;
    } elsif ($ARGV[$i] eq '-debugmask') {
      # -debugmask check
      #remove the option from ARGV array if found
      splice(@ARGV,$i,1);
      if (defined($ARGV[$i]))
      {
        my $dbgmask;
        eval {
           $dbgmask = hex $ARGV[$i];
        };
        if ( $@ || $dbgmask == 0 ) {
          print "The debug mask provided is invalid.\n";
          print "Setting Debug Mask to default value.\n";
        }
        $tfactlglobal_hash{'debugmask'} = $dbgmask;
        ###print "Hex value : " . $dbgmask . " \n";
        #remove the value  of debug mask from ARGV array if found
        splice(@ARGV,$i,1);
      }
      else
      {
        print STDERR "WARNING: Debug Mask not specified\n";
        #$tfactlglobal_hash{'verbose'} ='normal';
        print STDERR "Default Debug Mask is enabled.\n";
      }
      #
      next; 
    } elsif ($ARGV[$i] eq '-setupnd_java') {
      # manuegar_bug-27669677
      #remove the option from ARGV array if found
      splice(@ARGV,$i,1);

      if (defined($ARGV[$i]) && (not -d $ARGV[$i]) ) {
        print "-setupnd_java switch expects a valid JAVA_HOME.\n";
        print $ARGV[$i] . "is not a valid directory.\n";
        print "Please try again with a valid JAVA_HOME.\n";
        exit 1;
      }

      $SETUPND_JAVAHOME = $ARGV[$i];
      splice(@ARGV,$i,1);

      if (defined($ARGV[$i]) && lc($ARGV[$i]) ne "-help" && lc($ARGV[$i]) ne "-h")
      {     
        print "-setupnd switch only supports -setupnd_java.\n";
        print "Additional argument detected -> " . $ARGV[$i] . " \n";
        print "Please try again w/o additional arguments.\n";
        exit 1;
      }
    } elsif ($ARGV[$i] eq '-setupnd') {
      # manuegar_extract_tfa_03
      #remove the option from ARGV array if found
      splice(@ARGV,$i,1);
      # print "-setupnd detected ...\n";
      $SETUPND = 1;
      
      if (defined($ARGV[$i]) && lc($ARGV[$i]) ne "-setupnd_java" &&
          lc($ARGV[$i]) ne "-help" && lc($ARGV[$i]) ne "-h")
      {
        print "-setupnd switch only supports -setupnd_java.\n";
        print "Additional argument detected -> " . $ARGV[$i] . " \n";
        print "Please try again w/o additional arguments.\n";
        exit 1;
      }
    } else {
      $i++;
    } # end if, -m check
  } # end for

  ###print "Array after : @ARGV  .. \n";

  tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_init_trace " .
                    "Verbose mode: $tfactlglobal_hash{'verbose'}",'y', 'n');

return;
}

########
# NAME
#   tfactlshare_get_user
#
# DESCRIPTION
#   This function is used to get the effective user name
#
# PARAMETERS
#
# RETURNS
#    Effective user 
#
########
sub tfactlshare_get_user {
  my $os = $^O;
  my $user;

  # This is to get the effective user name
  if($IS_WINDOWS)
  {
    if(Win32::IsAdminUser()){
      $user = "root";
    }else{
      $user = getlogin;
      my $domainName = `echo %userdomain%`;
      $domainName = trim($domainName);
      if($domainName ne ""){
      	$user = $domainName."\\".$user;
      }
    }
  }
  else  
  {
    $user = getpwuid($>) || getlogin;
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_get_user OS: $os, user: $user",'y', 'n');

  return $user;
}

########
# NAME
#   tfactlshare_check_trace
#
# DESCRIPTION
#   This function is used to validate if diag directory exists
#   And some other directories such as srdc and ips base in suptools
#
# PARAMETERS
#   $tfa_home - TFA_HOME
#   $tfauser - user to be validated
# RETURNS
#
########
sub tfactlshare_check_trace {
  my ($tfa_home) = shift;
  my ($tfauser) = shift;
  my ($tfa_base) = shift;
  my $repodir;

  if ( length $tfa_base ) {
    $repodir = $tfa_base;
  } else {
    $repodir = tfactlshare_get_repository_location($tfa_home);
  }
  my $tracebasepath = catdir($tfactlglobal_diag_base,"user_$tfauser");
  my $tfa_base = tfactlshare_get_repository_location($tfa_home);

  my $ips_base = catfile($repodir,"suptools","ips");
  my $ips_user = catfile($ips_base,"user_$tfauser");
  my $srdc_base = catfile($repodir,"suptools","srdc");
  my $srdc_user = catfile($srdc_base,"user_$tfauser");

  # $tfactlglobal_diag_base/user_$tfauser
  my $mode = (stat($tracebasepath))[2];
  $mode = sprintf("%04o",$mode & 07777);
  eval { chmod(oct(1740),$tracebasepath) if $mode ne "1740"; };

  tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_check_trace " .
                    "Current mode for $tracebasepath -> $mode",'y', 'n');

  # Setup tfa-ddu if needed
  tfactlshare_check_type_base($tfa_home,"ddu");
  # Setup tfa-ips if needed
  tfactlshare_check_type_base($tfa_home,"ips");
  # Setup tfa-srdc if needed
  tfactlshare_check_type_base($tfa_home,"srdc");
 
  if ( not $DIAGDIR ) {
    tfactlshare_init_trace($tfa_home);
  }

  # Create tfa-srdc user directory
  eval { tfactlshare_mkpath("$srdc_user", "1741") if ( ! -d "$srdc_user" );
       };
  if ($@)
  {
    tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_check_trace " .
                      "Can not create path $srdc_user, DIAGDIR $DIAGDIR",'y', 'n');
  }

  tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_check_trace " .
                    "Trying $CHOWN -R $tfauser $srdc_user",'y', 'n');
  eval {
         if($IS_WINDOWS){
           #TODO Need to change for windows
         }else{
                host("$CHOWN -R $tfauser $srdc_user");
         }
       };
  if ($@) {
            tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_check_trace " .
                              "Error, $CHOWN -R $tfauser $srdc_user",'y', 'n');
          }


  # Create tfa-ips user directory
  eval { tfactlshare_mkpath("$ips_user", "1741") if ( ! -d "$ips_user" ); 
       };
  if ($@)
  {
    # print STDERR "Can not create path $ips_user \n";
    tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_check_trace " .
                      "Can not create path $ips_user, DIAGDIR $DIAGDIR",'y', 'n');
    $DIAGDIRIPS = FALSE;
  }

  tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_check_trace " .
                    "Trying $CHOWN -R $tfauser $ips_user",'y', 'n');
  eval { 
         if($IS_WINDOWS){
         	#TODO Need to change for windows
         }else{
         	host("$CHOWN -R $tfauser $ips_user");	
         }
       };
  if ($@) {
            tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_check_trace " .
                              "Error, $CHOWN -R $tfauser $ips_user",'y', 'n');
          }

  # Create log directory for user
  tfactlshare_init_tracebasepath($tracebasepath);

  eval { tfactlshare_mkpath(catdir($tracebasepath,"alert"), "1740") if ( ! -e catfile($tracebasepath,"alert") );
       };
  if ($@) 
  {
    # print STDERR "Can not create path $tracebasepath/alert \n";
    tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_check_trace " .
                      "Can not create path ".catdir($tracebasepath,"alert")." , DIAGDIR $DIAGDIR",'y', 'n');
    $DIAGDIR = 0;
  }

  eval { 
         tfactlshare_mkpath(catdir($tracebasepath,"trace"), "1740") if ( ! -e catfile($tracebasepath,"trace") );
        };
  if ($@) 
  {
    # print STDERR "Can not create path $tracebasepath/trace \n";
    tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_check_trace " .
                      "Can not create path ".catdir($tracebasepath,"trace")." , DIAGDIR $DIAGDIR",'y', 'n');
    $DIAGDIR = 0;
  }

  if($IS_WINDOWS){
  	#TODO Need to change for windows
  }else{
  	tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_check_trace " .
                    "Trying chown -R $tfauser $tracebasepath",'y', 'n');
  }
  eval {
		if($IS_WINDOWS){
			#TODO Need to change for windows
		}else{ 
         host("$CHOWN -R $tfauser $tracebasepath");
     	}
       };
  if ($@) {
  			if($IS_WINDOWS){
				#TODO Need to change for windows
			}else{ 
            	tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_check_trace " .
                              "Error, chown -R $tfauser $tracebasepath",'y', 'n');
            }
          }

  tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_check_trace " .
                      "tfauser: $tfauser tracebasepath: $tracebasepath",'y', 'n');
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_check_trace " .
                      "ips_base $ips_base",'y', 'n');
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_check_trace " .
                      "ips_user $ips_user",'y', 'n');

return;
}

########
# NAME
#   tfactlshare_check_tfauser_diag
#
# DESCRIPTION
#   This function is used create diag dir for tfauser if not yet created.
#
# PARAMETERS
#
# RETURNS
#
########
sub tfactlshare_check_tfauser_diag {
        my $tfa_home = shift;
        my $localhost = tolower_host();
        my $actionmessage;
        my $command;
        my $line;
        my $userhost;
        my $username;
        my $usertype;
        my $userstatus;

        my @list;
        my $status = 0; 
        my $portfile = catfile ("$tfa_home","internal", "port.txt");

        my $user = tfactlshare_get_user();

        tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_check_tfauser_diag" .
                          "Connected user : $user",
                          'y', 'n');
        
        if ( $user ne "root" ) {
          #tfactlshare_init_trace($tfa_home);
          tfactlshare_check_trace($tfa_home,$user);
          tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_check_tfauser_diag" .
                            "Non root user, exiting sub.",
                            'y', 'n');
          return;
        }

        open (PORTFILE, "<", "$portfile") or return;
        close(PORTFILE);

        tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_check_tfauser_diag" .
                          "Running listtfausers through Java CLI in tfactlshare_check_tfauser_diag",
                          'y', 'n');

        dbg(DBG_WHAT, "Running listtfausers through Java CLI in tfactlshare_check_tfauser_diag\n");
        $actionmessage = "$localhost:listtfausers:-l\n";
        $command = buildCLIJava($tfa_home,$actionmessage);
        dbg(DBG_VERB, "$command\n");
 	my @cli_output = tfactlshare_runClient($command);
        foreach $line ( @cli_output ) {
                tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_check_tfauser_diag" .
                          "line $line", 'y', 'n'); 
                if ( $line =~ /!/ ) {
                        $status = 1; 
                        @list = split( /!/, $line );
                        $userhost = $list[TFAUSER_HOST];
                        $username = $list[TFAUSER_NAME];
                        $usertype = $list[TFAUSER_TYPE];
                        if ( lc($list[TFAUSER_ALLOWED]) eq "true" ) {
                           $userstatus = "Allowed";
                        } else {
                               $userstatus = "Disabled";
                        }

                        if ( lc($usertype) eq "user" &&
                             lc($userstatus) eq "allowed" ) {
                          # print "diagdir $DIAGDIR $username $usertype $userstatus \n";
                          tfactlshare_init_trace($tfa_home);
                          tfactlshare_check_trace($tfa_home,$username);
                          tfactlshare_trace(3, "tfactl (PID = $$) " .
                                            "tfactlshare_check_tfauser_diag " .
                                            "username: $username , usertype $usertype , " . 
                                            "userstatus $userstatus",'y', 'n');
                        } elsif ( lc($usertype) eq "group" && 
                             lc($userstatus) eq "allowed" ) {
                          if($IS_WINDOWS){
                            #TODO By passing group permissions for windows which will be added subsequently
                          }else{
                            my @osusers;
                            my $usersingroup = `grep "^$username:" /etc/group | head -1`;
                            my $osuser;
                            if ( $usersingroup =~ /.*\:(.*)/ ) {
                              @osusers = split(",",$1);
                            }
                            # print "osusers @osusers\n";
                            push @osusers, "root";
                            foreach (@osusers) {
                              $osuser = $_;
                              tfactlshare_init_trace($tfa_home);
                              tfactlshare_check_trace($tfa_home,$osuser);
                              tfactlshare_trace(3, "tfactl (PID = $$) " .
                                              "tfactlshare_check_tfauser_diag " .
                                              "osuser: $osuser",'y', 'n');
                            } # end foreach
                          }
                        } # end if  lc($usertype) eq "user"
                }
        }
        tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_check_tfauser_diag " .
                          "tfa_home: $tfa_home",'y', 'n');

return;
}

########
# NAME
#   tfactlshare_token_type
#
# DESCRIPTION
#   This function analyzes the provided token
# 
# PARAMETERS
#
# RETURNS
#   The token type,
#   <integer>
#   text
#
########
sub tfactlshare_token_type {
  my $token = shift;
  # print "token ($token)\n";

  if ( $token =~ m/^\d+$/ ) {
    $TFAIPS_NMBR = $token;
    return "<integer>";
  } elsif ( $token =~ m/^[a-zA-Z]+$/ || $token =~ m/^-help$/ ||
            $token =~ m/^-h$/ ) {
    return $token;
  } elsif ( $token eq "<integer>" || $token eq "<path>" || $token eq "<filename>" 
           || $token eq "<newfilename>" || $token eq "<packname>" ) {
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_token_type " .
                      "Special cases $token", 'y', 'y');
    return $token;
  } elsif ( $token =~ m/^\'?\s*(19|20)\d\d[-](0[1-9]|1[012])[-](0[1-9]|[12][0-9]|3[01])\s*(([01]?[0-9]|2[0-3])[:\.][0-5][0-9])(([:\.][0-5][0-9])([:\.][0-9]{1,6})?)\s*([\-\+]([01]?[0-9]|2[0-3])[:\.][0-5][0-9])?\'?$/ ) {
    $TFAIPS_TIME = $token;
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_token_type " .
                      "Time matched", 'y', 'y');
    return "<time>";
  } elsif ( $token =~ m/(\^<[aA][dD][rR]\_[hH][oO][mM][eE]\>|<[aA][dD][rR]\_[bB][aA][sS][eE]\>)?(\/[\w\s\.\_\-\\\:]+)+(\.\w+)$/ || $token =~ m/^([\w\s\.\_\-\\\:]+)(\.\w+)$/ ) {
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_token_type " .
                      "Checking for filename, Token $token", 'y', 'y');
    if ( defined $TFAIPS_FILENAME && length($TFAIPS_FILENAME) == 0 ) {
      $TFAIPS_FILENAME = $token;
      tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_token_type " .
                        "Filter 1", 'y', 'y');
    } elsif ( defined $TFAIPS_NEWFILENAME  && length($TFAIPS_NEWFILENAME) == 0 
              && not $TFAIPS_LEFTCHK )  {
            $TFAIPS_NEWFILENAME = $token;
            tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_get_help_message " .
                              "Filter 2", 'y', 'y');
            return '<newfilename>';
    } elsif ( defined $TFAIPS_NEWFILENAME  && length($TFAIPS_NEWFILENAME) > 0 ) {
            tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_get_help_message " .
                              "Filter 3", 'y', 'y');
            return '<newfilename>';
    }
    return '<filename>';
  } elsif ( $token =~ m/^([\/\\][\w\s\.\_\-]+)+$/ || $token =~ m/^[\w\:]*([\/\\][\w\s\.\_\-]+)+$/ ) {
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_get_help_message " .
                      "Checking for path", 'y', 'y');
     $TFAIPS_FILEPATH = $token;
    return '<path>';
    # m/^\'([a-zA-Z] | \d | [\s\(\)\+\[\]] )+\'$/
  } #                      (     ORA-00600                )  s ( [word()+228                       ])  s
    elsif ( $token =~ m/^\'(\s*|[oO][rR][aA](-?|\s+)\d+\:?)*\s*(\[([\w\s]+(\:\s\d+|(\(\)\+\d+))?)*\])?\s*\'$/ ||
            $token =~ m/\s*[oO][rR][aA]\s*\d+\s*(\[\w+\])?\s*/ ) {
    $TFAIPS_PRBKEY = $token;
    #print "matched problem_key $TFAIPS_PRBKEY\n";
    return "<problem_key>";
  } elsif ( $token =~ /\w+\_[0-9]+/ ) {
    $TFAIPS_PACKNAME = $token;
    return '<packname>';
  } elsif ( $token eq "<none>" ) {
    return "<none>";
  } elsif ( $token =~ /^\-.*/ ) {
    return $token;
  }

  return "<unknown>";

}

########
# NAME
#   tfactlshare_get_help_message 
#
# DESCRIPTION
#   This function returns the corresponding help
#   message.
#
# PARAMETERS
#
# RETURNS
#   Help message
#
########
sub tfactlshare_get_help_message {
  my ($command, $hlpcommand) = (shift, shift);
  my ($retmessage) = "Help not available for command\n";

  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_get_help_message " .
                    "Command $command, Hlpcommand $hlpcommand", 'y', 'y');

  my $arrayref = $tfactlglobal_help_messages{$command};
  my @tmparray = @$arrayref;
  foreach (@tmparray) {
    my $arrayref = $_;
    my @helparray = @$arrayref;
    if ( lc($helparray[HLPCMD]) eq lc($hlpcommand) ) {
      $retmessage = $helparray[HLPMSG];
      last; 
    }
  } 

  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_get_help_message " . 
                    "Retmessage $retmessage", 'y', 'y');
  return $retmessage;
}

########
# NAME
#   tfactlshare_parse_command
#
# DESCRIPTION
#   This function parses tfa commands
#
# PARAMETERS
#
# RETURNS
#
########
sub tfactlshare_parse_command {
  my ($commandtype, @ARGVCPY) = (shift, @_);
#  my $command1 = $ARGVCPY[0];  # shift(@ARGVCPY);
#  my $switch_val = $command1;
  my @commandopt;
  my $commandline = join(' ',@ARGVCPY);

  my $syntaxok = FALSE; 
  my $completed = FALSE;
  my $moretokens = FALSE;
  my $helpcommand = FALSE;
  my $currenttoken;
  my $prevtoken;
  my $retcommand;
  my $token;
  my $ndx = 0;

  # Is it a single command (w/no args, like ips <none>
  if ( $#ARGVCPY == 0 ) {
    $ARGVCPY[1] = "<none>";
  }

  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command Cmdtype $commandtype",
                      'y', 'n');
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command HlpArray @ARGVCPY",
                      'y', 'n');

  if ( lc($commandtype) eq "cmd" ) {
    @commandopt = $tfactlglobal_commands{ lc($ARGVCPY[0]) };
  } elsif ( lc($commandtype) eq "hlp" ) {
    @commandopt = $tfactlglobal_help_commands{ lc($ARGVCPY[0]) };
    $helpcommand = TRUE;
  } else {
   return "none";
  }

  my $currpos = 0;
  for my $ndx (1 .. $#ARGVCPY) {
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command ---------------------",
                      'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command Token $ARGVCPY[$ndx] ",
                      'y', 'y'); 
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command ---------------------",
                      'y', 'y');
    $TFAIPS_LEFTCHK = TRUE;
    $prevtoken = tfactlshare_token_type( $ARGVCPY[$ndx-1] );
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command --- prevtoken     calling " .
                     "tfactlshare_token_type\( $ARGVCPY[$ndx-1] \)  ==> $prevtoken",
                      'y', 'y');
    ###print "calling tfactlshare_token_type \( $ARGVCPY[$ndx-1] \) ==> prevtoken $prevtoken\n";

    $TFAIPS_LEFTCHK = FALSE;
    $currenttoken = tfactlshare_token_type( $ARGVCPY[$ndx] );
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command --- currenttoken  calling " .
                     "tfactlshare_token_type\( $ARGVCPY[$ndx] \)  ==> $currenttoken",
                      'y', 'y');
    ###print "calling tfactlshare_token_type \( $ARGVCPY[$ndx] \) ==> currenttoken $currenttoken\n\n";


chkcommands:
  for my $ndxcmdopt (0 .. $#commandopt) {
      my $arrayref = $commandopt[$ndxcmdopt];
      my @tmparray = @$arrayref;
=head
      tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command chkcommand " .
                        "Array ref: $_", 'y', 'n');
      tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command chkcommand " .
                        "Deref array: @tmparray", 'y', 'n');
=cut
      for my $ndxcmdopt ($currpos .. $#tmparray) {
        my $arrayref = $tmparray[$ndxcmdopt];
        my @tokenarray = @$arrayref;
=head
        tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command chkcommand " .
                          "ndx $ndxcmdopt currpos $currpos", 'y', 'y');
        tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command chkcommand " .
                          "$tokenarray[PREVCMD] $tokenarray[NXTCMD] $tokenarray[COMPCMD] " .
                          "$tokenarray[MORECMD]", 'y', 'y');
        tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command chkcommand " .
                          " tokenarray: @tokenarray", 'y', 'n');
=cut
        # Logic
        if ( $tokenarray[PREVCMD] eq '<start_time>' && $prevtoken eq '<time>' ) {
         $prevtoken = '<start_time>'; 
         $TFAIPS_STTIME = $TFAIPS_TIME;
        } elsif ( $tokenarray[NXTCMD] eq '<start_time>' && $currenttoken eq '<time>' ) {
         $currenttoken = '<start_time>';
         $TFAIPS_STTIME = $TFAIPS_TIME;
        } elsif ( $tokenarray[PREVCMD] eq '<end_time>' && $prevtoken eq '<time>' ) {
          $prevtoken = '<end_time>';
          $TFAIPS_ENDTIME = $TFAIPS_TIME;
        }  elsif ( $tokenarray[NXTCMD] eq '<end_time>' && $currenttoken eq '<time>' ) {
          $currenttoken = '<end_time>';
          $TFAIPS_ENDTIME = $TFAIPS_TIME;
        }
        my $outcmd;
        if ( lc($prevtoken) eq $tokenarray[PREVCMD] &&  lc($currenttoken) eq $tokenarray[NXTCMD] &&
             $tokenarray[COMPCMD] == MARKED ) {
          if ( $ndx == $#ARGVCPY ) {
            $syntaxok = TRUE; 
          }
          #
          $outcmd = $tokenarray[RETCMD];
          tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command " .
                            "---------------------", 'y', 'y');
          tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command " .
                           "outcmd before  $outcmd", 'y', 'y');
          if ( $outcmd =~ m/package \<integer\>/ ) {
             $TFAIPS_PACKNUMBER = $TFAIPS_NMBR;
          } elsif ( $outcmd =~ m/\<integer\>/ ) {
             $TFAIPS_NUMBER = $TFAIPS_NMBR;
          }

          $outcmd =~ s/\<integer\>/\Q$TFAIPS_NMBR/;
          $outcmd =~ s/\<problem_key\>/$TFAIPS_PRBKEY/;
          $outcmd =~ s/\<start_time\>/$TFAIPS_STTIME/;
          $outcmd =~ s/\<end_time\>/$TFAIPS_ENDTIME/;
          $outcmd =~ s/\<filename\>/\Q$TFAIPS_FILENAME/;
          $outcmd =~ s/\<newfilename\>/\Q$TFAIPS_NEWFILENAME/;
          if ( not $IS_WINDOWS ) {
            $outcmd =~ s/\<path\>/\Q$TFAIPS_FILEPATH/;
          } else {
            $outcmd =~ s/\<path\>/$TFAIPS_FILEPATH/;
          }
          $outcmd =~ s/\<packname\>/\Q$TFAIPS_PACKNAME/;
          $outcmd =~ s/\\//g if ( not $IS_WINDOWS );
          if ( $outcmd =~ m/set base/ ) {
             tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command " .
                               "ips set base detected ...", 'y', 'y');
             $TFAIPS_ADRBASE = $TFAIPS_FILEPATH;
          } elsif ( $outcmd =~ m/set homepath/ ) {
             tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command " .
                               "ips set homepath detected ...", 'y', 'y');
             $TFAIPS_ADRHOMEPATH = $TFAIPS_FILEPATH;
          }

          tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command " .
                               "outcmd after  $outcmd", 'y', 'y');
          tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command " .
                         "Global filename $TFAIPS_FILENAME path $TFAIPS_FILEPATH", 'y', 'n');
          if ( $helpcommand ) {
            $retcommand = $outcmd;
          } else {
            $retcommand .= " " . $outcmd;
          }
          tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command " .
                               "Original $tokenarray[RETCMD], Helpcommand $helpcommand, Outcommand $outcmd , Retcommand prev  $retcommand", 'y', 'y');
          last; # chkcommands;
        } elsif ( lc($prevtoken) eq $tokenarray[PREVCMD] &&  lc($currenttoken) eq $tokenarray[NXTCMD] &&
                  $tokenarray[COMPCMD] == UNMARKED  && $tokenarray[MORECMD] == MARKED ) {
               $completed = FALSE;
               $moretokens = TRUE;
               tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command " .
                         "Retcommand $tokenarray[RETCMD]", 'y', 'y');
               if ( $tokenarray[RETCMD] ne 'none' ) {
                 if ( $helpcommand ) {
                   $retcommand = $tokenarray[RETCMD];
                 } else {
                   $retcommand .= " " . $tokenarray[RETCMD];
                 }
               }
               last; # chkcommands;
        } 
        $currpos = $ndxcmdopt+1;
      }
  }
  }
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_parse_command " .
                    "====> SYNTAX OK  $syntaxok retcmd $retcommand TFAIPS_NMBR $TFAIPS_NMBR",
                    'y', 'y');
  #print "sintax ok  $syntaxok retcmd $retcommand TFAIPS_NMBR $TFAIPS_NMBR \n";
  if (not $syntaxok) {
    if ($commandline eq "ips") {
      $retcommand = 'ips -help';
    } else {
      tfactlshare_error_msg(303, [ "[" , $commandline  , "]" ] );  
      $retcommand = 'none';
    }
    # Reset globals to default values
    $TFAIPS_NMBR = 0;
    $TFAIPS_NUMBER = 0;
    $TFAIPS_PACKNUMBER = 0;
    $TFAIPS_PACKNAME = "";
    $TFAIPS_PRBKEY = "";
    $TFAIPS_STTIME = ""; 
    $TFAIPS_ENDTIME = ""; 
    $TFAIPS_TIME = ""; 
    $TFAIPS_FILENAME = ""; 
    $TFAIPS_NEWFILENAME = ""; 
    $TFAIPS_FILEPATH = ""; 
    $TFAIPS_OPERATION = ""; 
    $TFAIPS_OVERWRITE = "";
  }

  return $retcommand;

}

########
## NAME
##   tfactlshare_get_homepaths
#
# DESCRIPTION
#   This function returns the homepaths for
#   the given ADR base
#
# PARAMETERS
#   $oracle_home
#   $adr_base
#
# RETURNS
#   @adrhomepaths
#
########
sub tfactlshare_get_homepaths {

  my $oracle_home = shift;
  my $adr_base    = shift;
  my @homepatharray = (); 
  my $setadrbase  = "set base $adr_base;";
  my $commandline;
  ### print "shell $OSSHELL get_homepaths \n";
  my $adrcibin = catfile($oracle_home,"bin","$ADRCI");
  
  if ( not $IS_WINDOWS ) {
    if ( $CSH ) {
      $commandline = "setenv ORACLE_HOME " . $oracle_home . ";setenv LD_LIBRARY_PATH " . catfile($oracle_home,"lib") . ";";
      $commandline .= $adrcibin ." exec=\"" . "$setadrbase" . "show homepath" . ";" . "\"";
      $commandline = "/bin/csh -c '$commandline'";
    } else {
      $commandline = "ORACLE_HOME=" . $oracle_home . ";export ORACLE_HOME;LD_LIBRARY_PATH=" . catfile($oracle_home,"lib") . ";export LD_LIBRARY_PATH;";
      $commandline .= $adrcibin ." exec=\"" . "$setadrbase" . "show homepath" . ";" . "\"";
    }
  }
  if ( $IS_WINDOWS ) {
     $commandline = $adrcibin ." exec=\"" . "$setadrbase" . "show homepath" . ";" . "\"";
     $commandline =~ s/\\/\\\\/g;
  } # end if $IS_WINDOWS
  ###print "commandline $commandline\n";
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_get_homepaths " .
                    "[ghp00] commandline $commandline", 'y', 'y');

  if ( -e $adrcibin ) {
    foreach my $line (split /\n/, `$commandline`) {
      if ( $line =~ /DIA\-48447/ ) {
        last;
      } elsif ( $line =~ m/^(diag.*)/ ) {
        push  @homepatharray, $1;
      }
    }
  } # end if -e $adrcibin

  ###print "\n\nhomepatharray @homepatharray\n";
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_get_homepaths " .
                    "homepatharray @homepatharray", 'y', 'y');
  return @homepatharray;
}

########
# NAME
#   tfactlshare_call_adrci
#
# DESCRIPTION
#   This function executes adrci commands
#
# PARAMETERS
#   $adrci_command
#   $silent_mode
#   $print_mode - default 'yes'
#   $adrci_homepath
#   $adrci_oraclehome
#   $adrci_multiselect - default 'no'
#   $adrci_base
#   $adrci_adrbase_multiselect - default 'no'
#
# RETURNS
#
########
sub tfactlshare_call_adrci {
  my $adrci_command     = shift;
  my $adrci_silent_mode = shift;
  my $adrci_print_mode  = shift;
  my $adrci_homepath    = shift;
  my $adrci_oraclehome  = shift;
  my $adrci_multiselect = shift;
  my $adrci_adrbase     = shift;
  my $adrci_adrbase_multiselect = shift;
  my $localhost = tolower_host();
  my $adrci_homepath_match = FALSE;
  my $adrci_oraclehome_match = FALSE;
  my $adrci_invalid_homepath = "";
  my $adrcibin = "";
  my $commandprefix = "";
  my $commandline = "";
  my $cshcommandline = "";
  my $oraclehome = "";
  my $totndx = 0;
  my $optselected = -1;
  my $ldlibpath;
  my $cshldlibpath;
  my $ipsoutput = "";
  my $oneadrhomepath = FALSE;
  my $oneadrbasepath = FALSE;
  my @adrbaseselected;

=head
  print "adrci_command     : $adrci_command\n" .
        "adrci_silent_mode : $adrci_silent_mode\n" .
        "adrci_print_mode  : $adrci_print_mode\n" .
        "adrci_homepath    : $adrci_homepath\n" .
        "adrci_oraclehome  : $adrci_oraclehome\n" .
        "adrci_multiselect : $adrci_multiselect\n" .
        "adrci_adrbase     : $adrci_adrbase\n" .
        "adrci_adrbase_multiselect : $adrci_adrbase_multiselect\n";
=cut
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                    "adrci_command     : $adrci_command\n" .
                    "adrci_silent_mode : $adrci_silent_mode\n" .
                    "adrci_print_mode  : $adrci_print_mode\n" .
                    "adrci_homepath    : $adrci_homepath\n" .
                    "adrci_oraclehome  : $adrci_oraclehome\n" .
                    "adrci_multiselect : $adrci_multiselect\n", 'y', 'y');

  if ( not (defined $adrci_print_mode and length $adrci_print_mode) ) {
    $adrci_print_mode = "yes";
  }

  if ( not (defined $adrci_multiselect && length $adrci_multiselect) ) {
    $adrci_multiselect = "no";
  }

  if ( not (defined $adrci_adrbase_multiselect && length $adrci_adrbase_multiselect) ) {
    $adrci_adrbase_multiselect = "no";
  }

  if ( defined $adrci_homepath && length $adrci_homepath ) {
    $TFAIPS_ADRHOMEPATH = $adrci_homepath;
  }

  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                       "tfa_home $tfa_home", 'y', 'y');
  # Verify if ADRCI binary is already set
  if ( $TFAIPS_OHOME eq "" ) {
     tfactlshare_get_oracle_homes($tfa_home);
     # Verify if adrci_oraclehome provided is valid
     if ( defined $adrci_oraclehome && length $adrci_oraclehome ) {
       foreach my $oh ( @tfactlglobal_oracle_homes ) {
         if ( $oh eq $adrci_oraclehome ) {
           $adrci_oraclehome_match = TRUE;
           $TFAIPS_OHOME = $oh;
           last;
         }
       } # end foreach $oh
     } # end if, verify adrci_oraclehome

     if ( @tfactlglobal_oracle_homes ) {
       $totndx = $#tfactlglobal_oracle_homes;
       ###
       if ( $adrci_oraclehome_match ) {
       } elsif ( $totndx == 0 || (defined $adrci_silent_mode && 
            lc($adrci_silent_mode) eq "yes") || 
            $adrci_command =~ m/^show (incidents|problems|homepath|base|homes)$/ || 
            $adrci_command =~ m/ips show package/ ) {
         # If available choose a 12.2 adrci binary
         my $matched=FALSE;
         for my $ndx ( 0..$#tfactlglobal_oracle_homes ) {
            if ( exists $tfactlglobal_oracle_homes_adrciversion{$tfactlglobal_oracle_homes[$ndx]} &&
                 $tfactlglobal_oracle_homes_adrciversion{$tfactlglobal_oracle_homes[$ndx]} eq "12.2" ) {
              $TFAIPS_OHOME = $tfactlglobal_oracle_homes[$ndx];
              $matched = TRUE;
              last;
            } # end if
         } # end foreach
         if ( not $matched ) {
           $TFAIPS_OHOME = $tfactlglobal_oracle_homes[0];
         } # end if not $matched
       } else {
       print "\nMultiple ORACLE HOMES were found, please select one ...\n\n";
       for my $ndx ( 0..$totndx ) {
         print "option[$ndx] $tfactlglobal_oracle_homes[$ndx] \n";
       }
       while ( not ( int($optselected) - $optselected == 0 &&
                     $optselected >= 0 && $optselected <= $totndx ) ) {
         $optselected = 0;
         print "\nPls select an ORACLE_HOME to be used for the ADRCI binary [$optselected] ?";
         {     
           local($SIG{INT}) = sub { print "Cancelling...\n"; exit 0; }; 
           $optselected =<STDIN>;
         }
         chomp($optselected);
         if ( length($optselected) == 0 ) {
           $optselected = 0;
         }
       }
       print "$tfactlglobal_oracle_homes[$optselected] was selected \n\n";
       $TFAIPS_OHOME = $tfactlglobal_oracle_homes[$optselected];
       }
     } else {
       #print "No ORACLE_HOME was found, ADRCI commands disabled !\n";
       return $tfactlglobal_error_message{202};
     }
  }

  # Enable TFA/IPS under ADE
  $tfactlglobal_hash{'adecmd'} = "true";
  # (defined $adrci_silent_mode && lc($adrci_silent_mode) eq "yes")
  if ( $IS_ADE || $tfactlglobal_hash{'adecmd'} eq "true" ) {
    $ldlibpath = "LD_LIBRARY_PATH=$TFAIPS_OHOME/lib;export LD_LIBRARY_PATH;";
    $cshldlibpath = "setenv LD_LIBRARY_PATH $TFAIPS_OHOME/lib;";
  } else {
    $ldlibpath = "";
  }

  ### print "TFAIPS_OHOME : $TFAIPS_OHOME \n";
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                    "TFAIPS_OHOME : $TFAIPS_OHOME", 'y', 'y');


  # -------------------
  # Check ADR basepaths
  # -------------------

  my @adrbases = tfactlshare_get_adr_bases($tfa_home, $localhost);
  $optselected = -1 ;
  $totndx = $#adrbases;

  # No ADR basepaths were discovered.
  if (not @adrbases) {
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                    "No ADR basepaths were discovered.", 'y', 'y');
    if ( not (length $DSCRIPT_OPTS) ) {
      tfactlshare_signal_exception(207, undef);
    } else {
      return "No ADR basepaths were discovered.";
    } # end if not (length $DSCRIPT_OPTS)
  }

  if ( $adrci_adrbase ) {
    my @adrciadrbasesarray = split /,/ , $adrci_adrbase;
    # Insert into %tfactlglobal_adrbaseselected ADR basepaths
    # feeded using the -adrbasepath switch
    foreach my $localadrbase (@adrciadrbasesarray) {
         if ( not exists $tfactlglobal_adrbaseselected{$localadrbase} ) {
           $tfactlglobal_adrbaseselected{$localadrbase} = TRUE; 
         }
    } # end foreach @adrciadrbasearray
    if ( $#adrciadrbasesarray == 0 ) {
      $TFAIPS_ADRBASE = $adrci_adrbase;
    } else {
      $TFAIPS_ADRBASE = $adrciadrbasesarray[0];
    }
  } elsif ( $totndx == 0 && @adrbases ) {
    $TFAIPS_ADRBASE = $adrbases[0];
    $tfactlglobal_adrbaseselected{$TFAIPS_ADRBASE} = TRUE;
  } else {
    my $iterationdone = FALSE;
    my %optionshash;
    $oneadrbasepath = FALSE;
    my $countsel;
    my $multiselect = $adrci_adrbase_multiselect eq "yes";

    # -----------------------
    while ( ! $iterationdone ) {
       my $optionsndx = 0;
       print "\nMultiple ADR basepaths were found, please select one ...\n\n" if $adrci_adrbase_multiselect eq "no";
       print "\nMultiple ADR basepaths were found, please select one or more...\n\n" if $adrci_adrbase_multiselect eq "yes";
       for my $ndx ( 0..$totndx ) {
          if ( exists $optionshash{$adrbases[$ndx]} ) {
            print "(*) option[$ndx] $adrbases[$ndx] \n";
          } else {
            print "( ) option[$ndx] $adrbases[$ndx] \n";
          }
       }
       print "    option[" . ($totndx + 1) . "] Done\n" if $adrci_adrbase_multiselect eq "yes";

       while ( not ( int($optselected) - $optselected == 0 &&
                      $optselected >= 0 && $optselected <= $totndx + $multiselect) ) {
          $optselected = 0;
          print "\nPls select an ADR basepath [0.." . ($totndx + $multiselect) . "] ?";
          {
            local($SIG{INT}) = sub { print "Cancelling...\n"; exit 0; };
            $optselected =<STDIN>;
          }
          chomp($optselected);
          if ( length($optselected) == 0 ) {
            if ( $adrci_adrbase_multiselect eq "yes" ) {
              $optselected = $totndx + $multiselect;
            } else {
              $optselected = $totndx + 1;  # multiselect eq "no", prompt
            }
          }
        } # end while not ( int($optselected) ...

        if ( $optselected <= $totndx ) {
          print "$adrbases[$optselected] was selected \n\n";
          $TFAIPS_ADRBASE = $adrbases[$optselected];
          $oneadrbasepath = TRUE;
        }

        # Multi selection for ADR basepath
        if ( length $adrbases[$optselected] && not exists $optionshash{$adrbases[$optselected]} &&
             $optselected <= $totndx ) {
          $optionshash{$adrbases[$optselected]} = TRUE;
        } else {
          delete $optionshash{$adrbases[$optselected]} if $optselected <= $totndx;
        }

       $countsel = keys %optionshash;
        
        ### print "adrbases countsel $countsel optselected $optselected \n";
        if ( ($optselected == $totndx + 1 && $countsel >= 1) ||
             ($adrci_adrbase_multiselect eq "no" && $optselected <= $totndx) ) {
          $iterationdone = TRUE;
          $oneadrbasepath = TRUE;
        } else {
          print "Please select at least one ADR basepath.\n";
        }
        $optselected = -1;

        if ( $adrci_adrbase_multiselect eq "no" && $oneadrbasepath ) {
          $iterationdone = TRUE;
        }
        ### print "iterationdone $iterationdone\n";

    } # end while $iterationdone
      # -----------------------------------
    
    # Set @adrbaseselected
    if ( $countsel >= 0 ) {
      for my $key ( keys (%optionshash) ) {
         push @adrbaseselected, $key;
         if ( not exists $tfactlglobal_adrbaseselected{$key} ) {
           $tfactlglobal_adrbaseselected{$key} = TRUE;
         }
      }
    }

  } # end if $adrci_adrbase

  if ( not @adrbaseselected  ) {
    @adrbaseselected = map $_ , keys %tfactlglobal_adrbaseselected;
  }
  ### print "adrbaseselected @adrbaseselected\n";

  # Make sure that only one ADR homepath is available
  # with the exception for the show incidents/problems/homepath/base/homes commands
  ### print "ips command $adrci_command\n";
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                    "[mksone00] Making sure that only one ADR homepath is available, for loop", 'y', 'y');
  
  # ========== Begin - Make sure that only one ADR homepath is available =============
  if ( $TFAIPS_ADRHOMEPATH eq "" &&
       $adrci_command !~ m/^show (incidents|problems|homepath|base|homes)/ &&
       $adrci_command !~ m/show version/ ) {
    my $line;
    my $ndx = 0;
    my $totndx = 0;
    $commandline .= "ORACLE_HOME=$TFAIPS_OHOME;export ORACLE_HOME;" .
                    "PATH=\$ORACLE_HOME/bin:\$PATH;export PATH;" .
                    $ldlibpath;
    $cshcommandline .= "setenv ORACLE_HOME $TFAIPS_OHOME;" .
                       "setenv PATH \$ORACLE_HOME/bin:\$PATH;" .
                       $cshldlibpath;
    my $adrbase = "set base ";
    if ( $TFAIPS_ADRBASE ) {
      $adrbase .= $TFAIPS_ADRBASE . ";";
    } elsif ( $TFAIPS_OHOME =~ /(.*)[\/\\]product[\/\\].*/ ) {
      $adrbase .= $1 . ";";
    } else {
      $adrbase = "";
    }
    $adrcibin = catfile($TFAIPS_OHOME,"bin",$ADRCI);
    # Validate adrcibin
    if ( not -e $adrcibin ) {
      $ipsoutput = "ADRCI bin does not exist: $adrcibin";
      print $ipsoutput if lc($adrci_print_mode) eq "yes";
      return $ipsoutput;
    }

    if ( not $IS_WINDOWS ) {
      $commandline .= "$adrcibin exec=\"" . "$adrbase" . "show homepath" . ";" . "\"";
      $cshcommandline .= "$adrcibin exec=\"" . "$adrbase" . "show homepath" . ";" . "\"";
      $cshcommandline = "/bin/csh -c '$cshcommandline'";
    } else {
      $commandline = "$adrcibin exec=\"" . "$adrbase" . "show homepath" . ";" . "\"";
    }

    # Prefix was used before relative ADR homepath
    my $alt_adrci_homepath = "";
    if ( $adrci_homepath =~ m/.*[\/\\](diag[\/\\]rdbms[\/\\].*[\/\\].*\_[0-9]+)/ || 
         $adrci_homepath =~ m/.*[\/\\](diag[\/\\]rdbms[\/\\].*[\/\\].*[0-9]+)/   ||
         $adrci_homepath =~ m/.*[\/\\](diag[\/\\]rdbms[\/\\].*[\/\\].*)/         ||
         $adrci_homepath =~ m/.*[\/\\](diag[\/\\].*[\/\\]\+ASM[0-9]+)/       ||
         $adrci_homepath =~ m/.*[\/\\](diag[\/\\].*[\/\\]\+APX[0-9]+)/       ||
         $adrci_homepath =~ m/.*[\/\\](diag[\/\\].*[\/\\]\+IOS[0-9]+)/       ||
         $adrci_homepath =~ m/.*[\/\\](diag[\/\\](asmtool|clients|asm|afdboot|diagtool)[\/\\]user_.*[\/\\](host|adrci)_.*)/ ||
         $adrci_homepath =~ m/(.*)[\/\\](diag[\/\\]crs[\/\\].*)/ ) {
      $alt_adrci_homepath = $1;
    }

    if ( $CSH ) {
      $commandline = $cshcommandline;
    }
    # only one ADR homepath is available

    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                      "[mksone00] commandline $commandline", 'y', 'y');

    foreach $line (split /\n/, `$commandline`) {
      if ( $line =~ m/^(diag.*)/ ) {
        my $diagpath = $1;
        my $diagpath = $1;
        my $dbpart1_src = "";
        my $dbpart2_src = "";
        my $dbpart1_dst = "";
        my $dbpart2_dst = "";

        if ( $adrci_homepath =~ m/.*[\/\\]rdbms[\/\\](.*)[\/\\](.*)\_[0-9]+/ ) { 
          $dbpart1_src = $1;
          $dbpart2_src = $2;
        } elsif ( $adrci_homepath =~ m/.*[\/\\]rdbms[\/\\](.*)[\/\\].*[0-9]+/ ) {
          my $basewd = $1;
          if ( $adrci_homepath =~ m/.*[\/\\]rdbms[\/\\]$basewd[\/\\]$basewd([0-9]+)/ ) {
            $dbpart1_src = $basewd;
            $dbpart2_src = $basewd;
          }
        }

        if ( $diagpath =~ m/.*[\/\\]rdbms[\/\\](.*)[\/\\](.*)\_[0-9]+/ ) {
          $dbpart1_dst = $1;
          $dbpart2_dst = $2;
        } elsif ( $diagpath =~ m/.*[\/\\]rdbms[\/\\](.*)[\/\\].*[0-9]+/ ) {
          my $basewd = $1;
          if ( $diagpath =~ m/.*[\/\\]rdbms[\/\\]$basewd[\/\\]$basewd([0-9]+)/ ) {
            $dbpart1_dst = $basewd; 
            $dbpart2_dst = $basewd;
          }
        }

        ###
        # print "Comparing against ... $diagpath\n";
        tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                         "for loop, Comparing against ... $diagpath", 'y', 'y');
        $tfactlglobal_adr_homes[$ndx++] = $diagpath;
        if ( defined $adrci_homepath && length $adrci_homepath ) {

          if ( $diagpath eq $adrci_homepath ||
               ( length $alt_adrci_homepath && $diagpath eq $alt_adrci_homepath )  ) {
            $adrci_homepath_match = TRUE;
            $TFAIPS_ADRHOMEPATH = $diagpath;
            last;
          } elsif ( ($adrci_homepath =~ m/.*[\/\\]\+ASM[0-9]+/ && $diagpath =~ m/.*[\/\\]\+ASM[0-9]+/) ||
                    ($adrci_homepath =~ m/.*[\/\\]\+APX[0-9]+/ && $diagpath =~ m/.*[\/\\]\+APX[0-9]+/) ||
                    ($adrci_homepath =~ m/.*[\/\\]\+IOS[0-9]+/ && $diagpath =~ m/.*[\/\\]\+IOS[0-9]+/) ||
                    ( length $dbpart1_src && length $dbpart1_dst       &&
                      $dbpart1_src eq $dbpart1_dst && $dbpart2_src eq $dbpart2_dst   )      ) {
            $adrci_homepath_match = TRUE;
            $adrci_homepath = $diagpath;
            $TFAIPS_ADRHOMEPATH = $diagpath;
          } elsif ( $adrci_homepath =~ 
                    m/.*[\/\\](asmtool|clients|asm|afdboot|diagtool)[\/\\]user_(.*)[\/\\](host|adrci)_.*/ ) {
            my $diagtype = $1;
            my $username = $2;
            # (asmtool|clients|asm|afdboot|diagtool)
            ###print "username $username\n";
            if ( $diagpath =~ m/.*[\/\\]$diagtype[\/\\]user_$username[\/\\](host|adrci)_.*/ ) { 
              $adrci_homepath_match = TRUE;
              $adrci_homepath = $diagpath;
              $TFAIPS_ADRHOMEPATH = $diagpath;
              #last;
            }
          } else {
            $adrci_invalid_homepath = "ADR homepath provided is invalid.";
          }
        } # end if defined $adrci_homepath && length $adrci_homepath
        ###
        # print "Diag $1\n";
      }
    } # end foreach $commandline

    ### print "\n\nTFAIPS_ADRHOMEPATH $TFAIPS_ADRHOMEPATH \n\n";
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                      "AFTER for loop, TFAIPS_ADRHOMEPATH $TFAIPS_ADRHOMEPATH", 'y', 'y');

    if ( $adrci_command !~ /show/ && 
         length $adrci_homepath &&
         not $adrci_homepath_match ) {
      ###print $adrci_command;
      tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                        "non matching adrhomepath", 'y', 'y');
      return "non matching adrhomepath";
    }

    # -------------------
    # Check ADR homepaths
    # -------------------

    $optselected = -1 ;

    my $totaladrbaseselected = $#adrbaseselected;
    my @homes; 
    @homes = tfactlshare_get_homepaths($TFAIPS_OHOME, $adrbaseselected[0]) if
             defined $adrbaseselected[0];

    if ( $adrci_homepath_match ) {
      $TFAIPS_ADRHOMEPATH = $adrci_homepath;
    } elsif ( $totaladrbaseselected == 0 && $#homes == 0 ) {
         # Support ADE environments
         if ( not exists $tfactlglobal_adrbasepaths{$adrbaseselected[0]} ) {
           $tfactlglobal_adrbasepaths{$adrbaseselected[0]} = $homes[0];
         }
    } else {
      # ---------------------------------------
      undef %tfactlglobal_adrbasepaths;
      for my $localadrbase ( @adrbaseselected) {
      @tfactlglobal_adr_homes = ();
      @tfactlglobal_adr_homes = tfactlshare_get_homepaths($TFAIPS_OHOME,$localadrbase);
      $totndx = $#tfactlglobal_adr_homes;
      ### print "\n\ntfactlglobal_adr_homes @tfactlglobal_adr_homes\n";
      tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                        "tfactlglobal_adr_homes @tfactlglobal_adr_homes", 'y', 'y');
      $TFAIPS_ADRBASE = $localadrbase;

      # Mutiple homepaths found, select one
      $TFAIPS_MULTIHOMEPATH = TRUE;
       print "$adrci_invalid_homepath" if length $adrci_invalid_homepath;
       my $iterationdone = FALSE;
       my %optionshash;

       while ( ! $iterationdone ) {
          my $optionsndx = 0;
          print "\nMultiple ADR homepaths were found for $localadrbase, please select one ...\n\n" if $adrci_multiselect eq "no";
          print "\nMultiple ADR homepaths were found for $localadrbase, please select one or more...\n\n" if $adrci_multiselect eq "yes";
          for my $ndx ( 0..$totndx ) {
            if ( exists $optionshash{$tfactlglobal_adr_homes[$ndx]} ) {
              print "(*) option[$ndx] $tfactlglobal_adr_homes[$ndx] \n";
            } else {
              print "( ) option[$ndx] $tfactlglobal_adr_homes[$ndx] \n";
            }
          }
          print "    option[" . ($totndx + 1) . "] Done\n";

          while ( not ( int($optselected) - $optselected == 0 &&
                        $optselected >= 0 && $optselected <= $totndx + 1) ) {
            $optselected = 0;
            print "\nPls select a homepath [" . ($totndx + 1) . "] ?";
            {
              local($SIG{INT}) = sub { print "Cancelling...\n"; exit 0; };
              $optselected =<STDIN>;
            }
            chomp($optselected);
            if ( length($optselected) == 0 ) {
              $optselected = $totndx + 1;
            }
          }

          if ( $optselected <= $totndx ) {
            print "$tfactlglobal_adr_homes[$optselected] was selected \n\n";
            $TFAIPS_ADRHOMEPATH = $tfactlglobal_adr_homes[$optselected];
            $oneadrhomepath = TRUE;
          }

          if ( length $tfactlglobal_adr_homes[$optselected] && 
               not exists $optionshash{$tfactlglobal_adr_homes[$optselected]} &&
               $optselected <= $totndx ) {
            $optionshash{$tfactlglobal_adr_homes[$optselected]} = TRUE;
          } else {
            delete $optionshash{$tfactlglobal_adr_homes[$optselected]} if $optselected <= $totndx;
          }

          my $countsel = keys %optionshash;
          ###print "countsel $countsel optselected $optselected \n";

          if ( ($optselected == $totndx + 1 && $countsel) ||
               ($adrci_multiselect eq "no" && $optselected <= $totndx) ) {
            $iterationdone = TRUE;
            $oneadrhomepath = TRUE;
          } else {
            print "Please select at least one ADR homepath.\n";
          }
          $optselected = -1;

          ###$TFAIPS_ADRHOMEPATH = $tfactlglobal_adr_homes[$optselected];
          # -------
          if ( $adrci_multiselect eq "no" && $oneadrhomepath ) {
            $iterationdone = TRUE;
          }
      } # end while
      my @items;
      for my $key ( keys %optionshash ) {
         if ( length $key ) {
           push @items, $key;
           #print "call adrci $key \n";
           
         }
      } # end for keys %optionshash
      $TFAIPS_ADRHOMEPATH_MULTI = join(",",@items);
      # Prepare adrbase/adrhomepaths for tfactldiagcollect_ips
      if ( not exists $tfactlglobal_adrbasepaths{$TFAIPS_ADRBASE} ) {
        $tfactlglobal_adrbasepaths{$TFAIPS_ADRBASE} = join(",",@items);
      } # end if not exists $tfactlglobal_adrbasepaths{$TFAIPS_ADRBASE}
 
      } # end for @adrbaseselected
        # ------------------------

    } # end else
    $commandline    = "";
    $cshcommandline = "";
  }
  # ========== End - Make sure that only one ADR homepath is available =============


  # Check if ADR homepath is already defined
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                       "Adrci command $adrci_command", 'y', 'y');
  if ( $TFAIPS_ADRHOMEPATH ne "" && 
       $adrci_command !~ m/^show (base|homes)$/  && 
       $adrci_command !~ m/^(set homepath|show base|show homes)$/ &&
       $adrci_command !~ m/show version/ ) {
    if ( $TFAIPS_MULTIHOMEPATH  && $adrci_command =~ m/^show (incidents|problems)/ &&
         $adrci_silent_mode eq "no" ) {
      my $showmsg = "$1";
      print "\nMultiple homepaths are available ... \n";
      while ( $optselected !~ m/[yYnN]/ ) {
        $optselected = "n";
        print "Do you want to show the $showmsg for all available homepaths (y/n) [$optselected] ?";
        {     
          local($SIG{INT}) = sub { print "Cancelling...\n"; exit 0; }; 
          $optselected =<STDIN>;
        }
        chomp($optselected);
        if ( length($optselected) == 0 ) {
          $optselected = "n";
        }
      }
      if ( lc($optselected) ne "y" ) {
        $commandprefix = "set homepath " . $TFAIPS_ADRHOMEPATH . ";";
      }
    } else {
      $commandprefix = "set homepath " . $TFAIPS_ADRHOMEPATH . ";";
    }
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                      "Setting homepath ...", 'y', 'y');
  }

  my $adrbase = "set base "; 
  if ( $TFAIPS_ADRBASE ) {
    $adrbase .= $TFAIPS_ADRBASE . ";";
  } elsif ( $TFAIPS_OHOME =~ /(.*)[\/\\]product[\/\\].*/ ) {
    $adrbase .= $1 . ";";
  } else {
    $adrbase = "";
  }

  $adrcibin = catfile($TFAIPS_OHOME,"bin",$ADRCI);
  # Validate adrcibin
  if ( not -e $adrcibin ) {
    $ipsoutput = "ADRCI bin does not exist: $adrcibin";
    print $ipsoutput if lc($adrci_print_mode) eq "yes";
    return $ipsoutput;
  }

  my $open3needed = FALSE;
  if ( $adrci_command !~ m/show version/ ) {
    # Assemble ADRCI commandline, integration tfa options
    if ( lc($adrci_command) =~ /options\s*\(\s*all_files\s*\=\s*(true|false)\s*\)/ ) {
      if ( not $IS_WINDOWS ) {
        $commandline = <<EOF;
        ORACLE_HOME=$TFAIPS_OHOME;export ORACLE_HOME;PATH=\$ORACLE_HOME/bin:\$PATH;export PATH;$ldlibpath
        $adrcibin <<EOF1
        $adrbase$commandprefix$adrci_command;
        exit
EOF1
EOF
        $cshcommandline = <<EOF2;
        setenv ORACLE_HOME $TFAIPS_OHOME;setenv PATH \$ORACLE_HOME/bin:\$PATH;$cshldlibpath
        $adrcibin <<EOF3
        $adrbase$commandprefix$adrci_command;
        exit
EOF3
EOF2
      } else {
        # Assemble ADRCI commandline, integration tfa options (windows only)
        $commandline = "$adrbase$commandprefix$adrci_command;\nexit\n";
        $open3needed = TRUE;
      } # end if not $IS_WINDOWS
    } else {
      # Assemble ADRCI commandline def
      if ( not $IS_WINDOWS ) {
        $commandline  = "ORACLE_HOME=$TFAIPS_OHOME;export ORACLE_HOME;" .
                        "PATH=\$ORACLE_HOME/bin:\$PATH;export PATH;" .
                        $ldlibpath;
        $cshcommandline  = "setenv ORACLE_HOME $TFAIPS_OHOME;" .
                           "setenv PATH \$ORACLE_HOME/bin:\$PATH;" .
                           $cshldlibpath;
        $commandline .= "$adrcibin exec=\"" . $adrbase . $commandprefix . $adrci_command . ";" . "\"";
        $cshcommandline .= "$adrcibin exec=\"" . $adrbase . $commandprefix . $adrci_command . ";" . "\"";
      } else {
        # Assemble ADRCI commandline def (windows only)
        $commandline .= "$adrcibin exec=\"" . $adrbase . $commandprefix . $adrci_command . ";" . "\"";
        $commandline =~ s/\\/\\\\/g;
      } # end if not $IS_WINDOWS
    }

  } else {
    # show version
    if ( not $IS_WINDOWS ) {
      $commandline = <<EOF;
      ORACLE_HOME=$TFAIPS_OHOME;export ORACLE_HOME;PATH=\$ORACLE_HOME/bin:\$PATH;export PATH;$ldlibpath
      $adrcibin <<EOF1
      exit
EOF1
EOF

      $cshcommandline = <<EOF2;
      setenv ORACLE_HOME $TFAIPS_OHOME;setenv PATH \$ORACLE_HOME/bin:\$PATH;$cshldlibpath
      $adrcibin <<EOF3
      exit
EOF3
EOF2
    } else {
      # show version (windows only)
      $commandline = "exit\n";
      $open3needed = TRUE;
    } # end if not $IS_WINDOWS
    ###print "ADRCI version cmdline $commandline\n";
  }

  ### print "[ca00] commandline: $commandline\n";
  ###  print "[ca00] open3needed $open3needed\n";
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                    "[ca00] commandline: $commandline", 'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                    "[ca00] open3needed $open3needed", 'y', 'y');
  my $line;
  my $pid;
  my $procoutput="";
  my $precmd="";
  my $postcmd="";
  my $cmdlineout;
  my $repodir = tfactlshare_get_repository_location($tfa_home);

  my $ips_base = catfile($repodir,"suptools", "ips");
  my $rdrfile  = catfile($ips_base,"rdrips.log");
  my $errfile  = catfile($ips_base,"errips.log");
  require IO::File;
  use IO::File;
  local (*Wrtr, *Rdr, *Err);
  #local (*Wrtr);
  *Rdr = IO::File->new($rdrfile,"w");
  *Err = IO::File->new($errfile,"w");

  eval {
    local $SIG{ALRM} = sub { die "alarm\n" };
    if ( $IS_ADE ) {
      alarm $TFAIPS_ADETIMEOUT;
    } else {
      alarm $TFAIPS_NONADETIMEOUT;
    }

    if ( not $open3needed ) {
      ### print "Commandline not open3needed $commandline\n";
      tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                        "[ca01] Commandline not open3needed $commandline", 'y', 'y');
      tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                        "[ca01] adrci_command $adrci_command", 'y', 'y');
      if ( not $IS_WINDOWS ) {
        my $cwd = getcwd();
        my $ipszipfile = "";
        my $reppath = "";
        my $cmdprefix="none"; 
        my %cmdbypasssu = ( 'ips pack' => TRUE,
                            'ips unpack' => TRUE );
        my $ips_base;
        my $usrips_base;

        if ( $adrci_command =~ /(\w+\s\w+)\s.*/ || $adrci_command =~ /(\w+\s\w+)/ ) {
          $cmdprefix = $1;
        }
        if ( exists $cmdbypasssu{$cmdprefix} ) {
          $reppath = $TFAIPS_FILEPATH;
          tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                            "TFAIPS_FILEPATH $TFAIPS_FILEPATH", 'y', 'y');
          tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                            "cwd $cwd", 'y', 'y');
        }
        # su section
#TODO check this su
        my $adrhpath="";
        $adrhpath=$TFAIPS_ADRHOMEPATH if $TFAIPS_ADRHOMEPATH ne "dummy"; 
        my $osowner = getFileOwner(catfile($TFAIPS_ADRBASE,$adrhpath)); 
        my $hdir = (getpwnam($osowner))[7];
        ### print "TFAIPS_ADRBASE $TFAIPS_ADRBASE, TFAIPS_ADRHOMEPATH $TFAIPS_ADRHOMEPATH\n";
        ### print "osowner $osowner hdir $hdir\n";
        tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                          " cmdprefix $cmdprefix", 'y', 'y');
        if ( $current_user eq "root" && $osowner ne "root" ) {
          if ( exists $cmdbypasssu{$cmdprefix} ) {
            my $tfa_base = tfactlshare_get_repository_location($tfa_home);
            # ips_base location
            $ips_base = catfile($tfa_base,"suptools","ips");
            $usrips_base = catfile($ips_base,"user_$osowner");

            tfactlshare_check_type_base($tfa_home,"ips");
            # Create $usrips_base when running in non daemon mode.
            eval { tfactlshare_mkpath("$usrips_base", "1741") if ( ! -d "$usrips_base" );
                 };   
            if ($@) 
            {    
              # print STDERR "Can not create path $usrips_base \n";
              tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                                "Can not create path $usrips_base, DIAGDIRIPS = FALSE",'y', 'y');
              $DIAGDIRIPS = FALSE;
            } else {
              $DIAGDIRIPS = TRUE;
            }

            tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                              "cmdprefix $cmdprefix", 'y', 'y');
            tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                              "usrips_base $usrips_base", 'y', 'y');
            tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                              "reppath $reppath", 'y', 'y');
            if ( length $reppath ) {
              $commandline =~ s/$reppath\;\"$/$usrips_base\;\"/;
              $cshcommandline =~ s/$reppath\;\"$/$usrips_base\;\"/;
            } else {
              if ( lc($cmdprefix) eq "ips pack" ) {
                $commandline =~ s/\;\"$/ in $usrips_base\;\"/;
                $cshcommandline =~ s/\;\"$/ in $usrips_base\;\"/;
              }
              if ( lc($cmdprefix) eq "ips unpack" ) {
                $commandline =~ s/\;\"$/ into $usrips_base\;\"/;
                $cshcommandline =~ s/\;\"$/ into $usrips_base\;\"/;
              }
            }
            tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                              "[ca02] Commandline  after replace $commandline", 'y', 'y');
          } # end if exists $cmdbypasssu{$cmdprefix}

          tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                            "[ca02] Current user $current_user, osowner $osowner, executing command using su $osowner -c ...", 'y', 'y');
          $commandline =~ s/\"/\\\"/g;
          $cshcommandline =~ s/\"/\\\"/g;
          if ( lc($cmdprefix) eq "ips unpack" ) {
            my $packname ="";
            my $srcpack  =""; 
            my $srcdiag=catfile($usrips_base,"diag");
            if ( $commandline =~ /.*ips unpack package (\w+) into.*/ ) {
              $packname = $1 . "_COM_1.zip";
              $srcpack  = catfile($cwd,$packname);
              $precmd="su $osowner -c \"cd $usrips_base;$CP $srcpack $usrips_base;";
              $postcmd=";$RM -rf $packname\"";
            } elsif ( $commandline =~ /.*ips unpack file (.*) into.*/ ) {
              $srcpack  = $1;
              $packname = $srcpack;
              $precmd="su $osowner -c \""; 
              $postcmd="\"";
            }
            tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                              "ips unpack, packname $packname", 'y', 'y'); 
            tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                              "ips unpack, srcpack $srcpack", 'y', 'y');
            # check sushell section
            my $sushell = "";
            if ( $IS_AIX ) {
              $sushell = `su $osowner -c "env|grep -i '^shell='"`;
            } else {
              $sushell = `su - $osowner -c "env|grep -i '^shell='"`;
            }
            ### print "res $sushell\n";
            ### print "commandline $commandline\n";
            ### print "cshcommandline $cshcommandline\n";

            if ( $IS_SOLARIS ) {
              my $cwd = getcwd();
              chdir($hdir);
              if ( $sushell =~ /\/bin\/t?csh/ ) {
                $procoutput = `$precmd$cshcommandline$postcmd`;
              } else {
                $procoutput = `$precmd$commandline$postcmd`;
              }
              chdir($cwd);
            } else {
              if ( $sushell =~ /\/bin\/t?csh/ ) {
                $procoutput = `$precmd$cshcommandline$postcmd`;
              } else {
                $procoutput = `$precmd$commandline$postcmd`;
              }
            }
            if ( $procoutput =~ /Unpacking file.*into target.*/ ) {
               if ( length $reppath ) {
                 `$CP -r $srcdiag $reppath;$RM -rf $srcdiag`;
                 $procoutput = "Unpacking file $packname into target $reppath\n";
               } else {
                 `$CP -r $srcdiag $cwd;$RM -rf $srcdiag`;
                 $procoutput = "Unpacking file $packname into target $cwd\n";
               }
            }
          } else {
            # check sushell section
            my $sushell = "";
            if ( $IS_AIX ) {
              $sushell = `su $osowner -c "env|grep -i '^shell='"`;
            } else {
              $sushell = `su - $osowner -c "env|grep -i '^shell='"`;
            }
             ### print "res $sushell\n";
             ### print "commandline $commandline\n";
             ### print "cshcommandline $cshcommandline\n";
            if ( $IS_SOLARIS ) {
              my $cwd = getcwd();
              chdir($hdir);
            }
            if ( lc($cmdprefix) eq "ips get" ) {
              if ( $sushell =~ /\/bin\/t?csh/ ) {
                $cshcommandline =~ s/\\//g;
                $procoutput = `$cshcommandline`;
              } else {
                $commandline =~ s/\\//g;
                $procoutput = `$commandline`;
              }
            } else {
              if ( $sushell =~ /\/bin\/t?csh/ ) {
                $procoutput = `su $osowner -c "$cshcommandline"`;
              } else {
                $procoutput = `su $osowner -c "$commandline"`;
              }
            } # end if lc($cmdprefix) eq "ips get"
            chdir($cwd) if $IS_SOLARIS;
          } # end if lc($cmdprefix) eq "ips unpack"
          tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                            "command output $procoutput", 'y', 'y');
          if ( exists $cmdbypasssu{$cmdprefix} && length $procoutput && 
               $procoutput =~ /Generated package [0-9]+ in file (.*)\, mode.*/ ) {
            $ipszipfile = $1; 
            if ( length $reppath ) {
              move($ipszipfile,$reppath);
            }
            tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                              "ipszipfile $ipszipfile", 'y', 'y');
          }
        } else {
          tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                            " [ca03] Current user $current_user, osowner $osowner, executing command w/o using su", 'y', 'y');
          # print "shell $OSSHELL  call_adrci 1 \n";
          if ( $CSH ) {
            tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                              "[ca03] commandline: $commandline", 'y', 'y');
            $procoutput = `/bin/csh -c '$cshcommandline'`;
          } else {
            $procoutput = `$commandline`;
          }
          my $ipslogfh;
          my $debugtime = strftime('%m.%d.%Y-%H.%M.%S',localtime);
          my $fname = catfile($tfactlglobal_trace_path,"tfaips.$debugtime.$localhost.log");
          if ( -e $tfactlglobal_trace_path ) {
            open ($ipslogfh, ">>",$fname ) or die
            "Could not open " . $fname . "\n";
            foreach my $line ( split /\n/,$procoutput ) {
              # Redirect errors to to user's ips trace log
              if ( ($line =~ /(.*DIA\-.*)/) ||
                   ($line =~ /(.*Additional information.*)/) ||
                   ($line =~ /(.*Linux\-.*)/) )  { 
                my $match = $1;
                print $ipslogfh "$debugtime tfactlshare_call_adrci " . $match . "\n";
                $match =~ s/\[/\\\[/g;
                $match =~ s/\]/\\\]/g;
                $match =~ s/\//\\\//g;
                $match =~ s/\./\\\./g;
                $procoutput =~ s/$match\n//;
              } # end if
            } # end foreach
            close $ipslogfh;
            my $fsize = osutils_getFileSize($fname);
            unlink $fname if $fsize == 0;
          } # end if -e $tfactlglobal_trace_path
        }
      } else {
        tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                          "[ca04] Windows open3needed = FALSE, commandline $commandline", 'y', 'y');
        $procoutput = `$commandline`;
      }
    } else {
      # Windows, $open3needed => TRUE
      require IPC::Open3;
      use IPC::Open3;
      $pid = open3(\*Wrtr, ">&Rdr", ">&Err", "$adrcibin");
      #### print "Commandline open3needed $commandline\n";
      tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                        "[ca05] adrcibin $adrcibin\n", 'y', 'y');
      tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                        "[ca05] Commandline open3needed $commandline", 'y', 'y');
      print Wrtr $commandline;
      close Wrtr;

      waitpid $pid,0;
      close Rdr;
      close Err;
      $procoutput = tfactlshare_cat($rdrfile);
      #### print "Content: $procoutput\n";
      tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                        "rdrfile $rdrfile\n");
      tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                        "Content open3needed: $procoutput", 'y', 'y');      

      unlink $rdrfile;
      unlink $errfile;
    } # end if windows processing

    if ( lc($commandline) =~ /options\s*\(\s*all_files\s*\=\s*(true|false)\s*\)/ ) { 
      $procoutput =~ s/ADRCI\:.*\n//;
      $procoutput =~ s/Copy.*\n//;
      $procoutput =~ s/adrci\>\s*//g;
      $procoutput =~ s/ADR base\s\=.*\n//;
      $procoutput =~ s/\n//g;
    }  elsif ( $open3needed ) {
      $procoutput =~ s/ADRCI\:.*\n// if ( $adrci_command !~ m/show version/ );
      $procoutput =~ s/Copy.*\n//;
      $procoutput =~ s/adrci\>\s*//g;
      $procoutput =~ s/ADR base\s\=.*\n//;
    } # end if lc($commandline) =~

    alarm 0;
  }; # end eval()
  if ( $@ ) {
    if ( not $IS_WINDOWS ) {
      my $pidinfo = `ps -f -p $pid`;
      ###print "pidinfo $pidinfo\n";
      if ( $pidinfo =~ /local ips/ || $pidinfo =~ /tfactl.pl ips/ ) {
        ###print "About to kill $pid , pidinfo $pidinfo ...\n";
        kill 9, $pid;
      }

      # Handle related adrci proc
      ###print "adrci_command $adrci_command\n";
      my $adrciinfo = `ps awwx | grep \"$adrci_command\" | grep adrci | grep -v \"grep\"`;
      my $adrpid;
      if ( $adrciinfo =~ /([0-9]+)\s.*/ ) {
        $adrpid = $1;
        ###print "About to kill adrci pid $adrpid, adrciinfo $adrciinfo ...\n";
      }
      kill 9, $adrpid;
    } else {
      # Handle windows timeout
      my $pidinfo = `WMIC process where "commandline like '%adrci%'" get commandline, processid`;
      foreach my $wmic ( split '\n' , $pidinfo ) {
         #### print "wmic -> $wmic\n";
         if ( $wmic =~ /.*\s+([0-9]+).*/ ) {
           if ( $1 eq $pid ) {
             #### print "pid $1 matched, terminating process.\n";
             kill ( -9, $pid);
           } # end if $1 eq $pid
         } # end if $wmic =~ /.*\s+([0-9]+).*/
      } # end foreach split '\n' , $pidinfo
    }

    $ipsoutput = "The execution of remote IPS command timed out";
  } else {
    $ipsoutput="";
    #print "out $procoutput \n";
    my $debugtime = strftime('%m.%d.%Y-%H.%M.%S',localtime);
    my $fname = catfile($tfactlglobal_trace_path,"tfaips.$debugtime.$localhost.log");
    my $traceavailable = TRUE;
    open (my $ipslogfh, ">>",$fname ) or $traceavailable = FALSE;
    foreach $line (split /\n/, $procoutput ) {
      # Don't filter DIA- messages
      # /(.*DIA\-.*)/
      if ( ($line =~ /(.*Additional information.*)/) ||
           ($line =~ /(.*Linux\-.*)/) ) {
        print $ipslogfh "$debugtime tfactlshare_call_adrci $line\n" if $traceavailable;
      } else {
        $ipsoutput .= "$line\n";
      }
    } # end foreach
    if ( $traceavailable ) {
      close $ipslogfh;
      my $fsize = osutils_getFileSize($fname);
      unlink $fname if $fsize == 0;
    }
  } # end else

  if ( $ipsoutput =~ m/DIA\-48321\: ADR Relation \[ADR_CONTROL\] not found/ || 
       $ipsoutput =~ m/DIA\-48210\: Relation Not Found/ ) {
    # tfactlshare_error_msg(203, undef) ;
  } elsif ( $ipsoutput =~ m/DIA\-48447/ ) { 
    print "The input path does not contain any ADR homes\n" if lc($adrci_print_mode) eq "yes";
  } else {
    print $ipsoutput if lc($adrci_print_mode) eq "yes";
  } 

  # For silent mode reset preferred O_H and ADR homepath
  if ( defined $adrci_silent_mode && lc($adrci_silent_mode) eq "yes" ) {
    #undef @tfactlglobal_oracle_homes;
    #undef @tfactlglobal_adr_homes;
    #$TFAIPS_OHOME = "";
    #$TFAIPS_ADRHOMEPATH = "";
    $TFAIPS_MULTIHOMEPATH = "FALSE";
  }

  #### print "ipsoutput $ipsoutput\n";
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_call_adrci " .
                    "return ipsoutput $ipsoutput", 'y', 'y');
  return $ipsoutput;
}

sub tfactlshare_parser_content {

  my $tagcontent        = shift;
  my $ndxref            = shift;
  my $levelref          = shift;
  my $lineNumref        = shift;
  my $isincrement       = shift;
  my $aref              = shift;
  
  # Content
  ++$$ndxref if $isincrement;
  $aref->[$$ndxref][XMLARRLEVEL] = $$levelref;
  $aref->[$$ndxref][XMLARRTAG]   = $tagcontent;
  $aref->[$$ndxref][XMLARRTAGMODE]   = "content";
  $aref->[$$ndxref][XMLLINENUM] = $$lineNumref;

  return;
} # end sub tfactlshare_parser_content

sub tfactlshare_parser_tagopen {
  my $prevtag           = shift;
  my $prevtagbefcomment = shift;
  my $tagopen           = shift;
  my $ndxref            = shift;
  my $levelref          = shift;
  my $lineNumref        = shift;
  my $aref              = shift;

  # Tag open
  ++$$levelref if ( $prevtag eq "open" || $prevtagbefcomment eq "open" );
  $aref->[$$ndxref][XMLARRLEVEL] = $$levelref;
  $aref->[$$ndxref][XMLARRTAG] = $tagopen;
  $aref->[$$ndxref][XMLARRTAGMODE] = "open";
  $aref->[$$ndxref][XMLLINENUM] = $lineNumref;

  return;
} # end sub tfactlshare_parser_tagopen

sub tfactlshare_parser_capture_attributes {
  my $attributes = shift;
  my $tagopen    = shift;
  my $ndxref     = shift;
  my $levelref   = shift;
  my $lineNumref = shift;
  my $matchedref = shift;
  my $prevtagref = shift;
  my $ismatch    = shift;
  my $aref       = shift;
  my $attribname;
  my $attribval;

  # Capture attributes

  if ( $tfactlglobal_hash{"debugmask"} &
       $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
    tfactlshare_trace(5, "tfactl (PID = $$) " .
                      "tfactlshare_populate_tagsarray " .
                      "TAG open/close => $tagopen , " .
                      "ATTRIBUTES => $attributes",
                      'y', 'y');
  }

  while($attributes =~ /$XMLATTRIBUTES/g) {
    $attribname = $1;
    $attribval  = $2;
    $attribval =~ s/"//g;
    $attribval =~ s/'//g;

    if ( $tfactlglobal_hash{"debugmask"} &
        $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
      tfactlshare_trace(5, "tfactl (PID = $$) " .
                        "tfactlshare_populate_tagsarray " .
                        "<$attribname> => <$attribval>", 'y', 'y');
    }

    # Attribute name
    $aref->[++$$ndxref][XMLARRLEVEL] = $$levelref;
    $aref->[$$ndxref][XMLARRTAG] = $attribname;
    $aref->[$$ndxref][XMLARRTAGMODE] = "attribname";
    $aref->[$$ndxref][XMLLINENUM] = $$lineNumref;
    # Attribute val
    $aref->[++$$ndxref][XMLARRLEVEL] = $$levelref;
    $aref->[$$ndxref][XMLARRTAG] = $attribval;
    $aref->[$$ndxref][XMLARRTAGMODE] = "attribval";
    $aref->[$$ndxref][XMLLINENUM] = $$lineNumref;
    if ( $ismatch ) {
      $$matchedref = 1;
      $$prevtagref = "open";
    }

  } # End while, attribute capture

 return;
} # end sub tfactlshare_parser_capture_attributes

########
# NAME
#   tfactlshare_populate_tagsarray
# 
# DESCRIPTION
#   This function populates @tagsarray
#   containing,
#   XMLARRLEVEL XMLARRTAG XMLARRTAGMODE
#                           open
#                           attribname
#                           attribval
#                           content
#                           close
#
# PARAMETERS 
#   $file_path - xml file to parse
# 
# RETURNS
#   @tagsarray
#
# NOTES
#   Look for special chars /\\;\\:
#   
########
sub tfactlshare_populate_tagsarray {

  my $file_path = shift;
  my $tagopen;
  my $tagclose;
  my $tagcontent;
  my $attribname;
  my $attribval;
  my @tagsarray;
  my $level = 0;
  my $ndx = 0;
  my $matched = 0;
  my $prevtag;
  my $prevtagbefcomment;
  my @elementsarray;
  my $cdatatag="cdataclose";
  my $lineNum=0;
  open my $fh, '<', $file_path
  or die "Can't open '$file_path' for reading - $!\n";

  $prevtag = "";
  while( my $line = <$fh> ) {
        undef $tagopen;
        undef $tagclose;
        undef $tagcontent;
        undef $attribname;
        undef $attribval;
        $lineNum++;

        if ( $line =~ m/^$XMLCOMMENTOPEN$/ ){
                                                              # comment open
          if ( defined $prevtag and $prevtag ne "" ) {
            $prevtagbefcomment = $prevtag;
          }
          $prevtag = "commentopen";
          $matched = 2;
          if ( $tfactlglobal_hash{"debugmask"} & 
                      $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                tfactlshare_trace(5, "tfactl (PID = $$) " .
                                  "tfactlshare_populate_tagsarray comment open ",
                                  'y', 'y');
          } 

        } elsif ( $line =~ m/^$XMLHEADER$/ ) {                #xml header 
          $matched = 2; 
          if ( $tfactlglobal_hash{"debugmask"} & 
                      $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                tfactlshare_trace(5, "tfactl (PID = $$) " .
                                  "tfactlshare_populate_tagsarray xml header ",
                                  'y', 'y');
          } 

        } elsif ( $line =~ m/^$XMLCOMMENTCLOSE$/ ){
                                                              # comment close
          $prevtag = "commentclose";
          $matched = 2;
          if ( $tfactlglobal_hash{"debugmask"} & 
                      $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                tfactlshare_trace(5, "tfactl (PID = $$) " .
                                  "tfactlshare_populate_tagsarray $2 $3 $4 comment close ",
                                  'y', 'y');
          } 

        } elsif ( $line =~ m/^$XMLCOMMENTOPEN.*$XMLCOMMENTCLOSE$/ ) {
          $matched = 2;                                       #comment open commment content comment close
          if ( $tfactlglobal_hash{"debugmask"} & 
                      $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                tfactlshare_trace(5, "tfactl (PID = $$) " .
                                  "tfactlshare_populate_tagsarray comment open comment content comment close ",
                                  'y', 'y');
          } 
        } elsif ( $line =~ m/^$XMLEMPTYLINE$/ && $cdatatag ne "cdataopen" ){
          $matched = 2;                                       # empty line
          if ( $tfactlglobal_hash{"debugmask"} & 
                      $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                tfactlshare_trace(5, "tfactl (PID = $$) " .
                                  "tfactlshare_populate_tagsarray empty line ",
                                  'y', 'y');
          } 

        } elsif ( $line =~ m/^$XMLCOMMENTCONTENT$/ && $cdatatag ne "cdataopen" && $prevtag eq "commentopen" ) { 
          $matched = 2;                                       #comment content 
          if ( $tfactlglobal_hash{"debugmask"} & 
                      $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                tfactlshare_trace(5, "tfactl (PID = $$) " .
                                  "tfactlshare_populate_tagsarray xml comment content  ",
                                  'y', 'y');
          } 
        } elsif( $line =~ m/^($XMLCONTENT*)$/ && $cdatatag ne "cdataopen" ){ #content
              $tagcontent = $1;
              $tagcontent =~ s/\n//g;
              $tagcontent =~ s/\r//g;
              if ( $tagcontent ne "" && $prevtag ne "commentopen" ) {
                if ( $prevtag ne "content" ) {
                  #print "CONTENT MATCHED \"$tagcontent\" \n ";
                  #print "ndx $ndx level $level content $tagcontent \n";
                  tfactlshare_parser_content($tagcontent, \$ndx, \$level, \$lineNum, FALSE, \@tagsarray);
                } else {
                  # concatenate multiline content
                  # add \n after each new content line
                  --$ndx;
                  $tagsarray[$ndx][XMLARRTAG]   .= "\n" . $tagcontent;
                }
                $matched = 1;
                $prevtag = "content";
              }
         } elsif($line =~ m/^(($XMLCONTENT*)($XMLCDATAOPEN$XMLCDATACONTENT$XMLCDATACLOSE$XMLCONTENT*))$XMLTAGCLOSE$/ && $prevtag ne "commentopen" && $cdatatag ne "cdataopen" ){
                                                  #content cdata open cdata content cdata close content tag close  
                                                  #content <![CDATA[ CDATAContent ]]> content </tag>

              $tagcontent = $2;
              $tagcontent .= tfactlshare_check_cdata_content($3,\$cdatatag,$lineNum);
              $tagclose   = $4;
              if ( $prevtag ne "content" ){
                tfactlshare_parser_content($tagcontent, \$ndx, \$level, \$lineNum, FALSE, \@tagsarray);
              }else{
                --$ndx;
                $tagsarray[$ndx][XMLARRTAG] .= " " .$tagcontent;
                $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              }
              
              $tagsarray[++$ndx][XMLARRLEVEL] = $level;
              $tagsarray[$ndx][XMLARRTAG] = $tagclose;
              $tagsarray[$ndx][XMLARRTAGMODE] = "close";
              $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              $prevtag = "close";
              $prevtagbefcomment = "";
              $matched = 1;
              if ( $tfactlglobal_hash{"debugmask"} & 
                      $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                tfactlshare_trace(5, "tfactl (PID = $$) " .
                                  "tfactlshare_populate_tagsarray $2 $3 $4 content+cdata close ",
                                  'y', 'y');
              } 

          } elsif($line =~ m/^(($XMLCONTENT*)($XMLCDATAOPEN$XMLCDATACONTENT$XMLCDATACLOSE$XMLCONTENT*))$XMLTAGCLOSE$XMLTAGCLOSE$/ && $prevtag ne "commentopen" && $cdatatag ne "cdataopen" ){         
                                                            #content cdata open cdata content cdata close content tag close tag close 
                                                            #content <![CDATA[ CDATAContent ]]> content </tag></tag>
          
            $tagcontent = $2;
            $tagcontent .= tfactlshare_check_cdata_content($3,\$cdatatag,$lineNum);
            $tagclose = $4;
            my $tag1close = $5;
            if ( $prevtag ne "content" ){
              tfactlshare_parser_content($tagcontent, \$ndx, \$level, \$lineNum, FALSE, \@tagsarray);
            }else{
               --$ndx;
               $tagsarray[$ndx][XMLARRTAG] .= " " .$tagcontent;
               $tagsarray[$ndx][XMLLINENUM] = $lineNum;
            }
              
              $tagsarray[++$ndx][XMLARRLEVEL] = $level;
              $tagsarray[$ndx][XMLARRTAG] = $tagclose;
              $tagsarray[$ndx][XMLARRTAGMODE] = "close";
              $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              --$level;
              $tagsarray[++$ndx][XMLARRLEVEL] = $level;
              $tagsarray[$ndx][XMLARRTAG] = $tag1close;
              $tagsarray[$ndx][XMLARRTAGMODE] = "close";
              $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              $prevtag = "close";
              $prevtagbefcomment = "";
              $matched = 1;
              if ( $tfactlglobal_hash{"debugmask"} & 
                      $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                tfactlshare_trace(5, "tfactl (PID = $$) " .
                                  "tfactlshare_populate_tagsarray $2 $3 $4 $5 content+cdata close close ",
                                  'y', 'y');
              } 
          
          } elsif($line =~ m/^($XMLCONTENT*$XMLCDATAOPEN$XMLCDATACONTENT)$/ && $cdatatag ne "cdataopen"){
                                                                      # content cdata open cdata content 
                                                                      # content <![CDATA[ CDATAContent
             $tagcontent = $1;
             $tagcontent = tfactlshare_check_cdata_content($tagcontent,\$cdatatag,$lineNum);
             if($prevtag ne "content" ){
              tfactlshare_parser_content($tagcontent, \$ndx, \$level, \$lineNum, FALSE, \@tagsarray);
             }
             else{
              --$ndx;
              $tagsarray[$ndx][XMLARRTAG] .= " ". $tagcontent;
              $tagsarray[$ndx][XMLLINENUM] = $lineNum;

             }
             $matched =1;
             $prevtag ="content";
            

         }elsif ( $line =~ m/^$XMLTAGOPEN$/ 
                      && $prevtag ne "commentopen"
                      && $cdatatag ne "cdataopen" ) {              
                                                              # tag open
                                                              # <tag>
              $tagopen = $1;
              # Tag open
              tfactlshare_parser_tagopen($prevtag, $prevtagbefcomment, $tagopen,
                                         \$ndx, \$level, \$lineNum, \@tagsarray );
              $matched = 1;
              $prevtag = "open";
              if ( $tfactlglobal_hash{"debugmask"} & 
                      $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                tfactlshare_trace(5, "tfactl (PID = $$) " .
                                  "tfactlshare_populate_tagsarray $1 open",
                                  'y', 'y');
              }
            } elsif ( $line =~ m/^$XMLTAGOPENCLOSE$/ 
                      && $prevtag ne "commentopen" && $cdatatag ne "cdataopen" ) {   
                                                        # tag open close
                                                        # <tag />
              $tagopen = $1;
              # Tag open
              tfactlshare_parser_tagopen($prevtag, $prevtagbefcomment, $tagopen,
                                         \$ndx, \$level, \$lineNum, \@tagsarray );
              $matched = 1;
              $prevtag = "open";

              $tagsarray[++$ndx][XMLARRLEVEL] = $level;
              $tagsarray[$ndx][XMLARRTAG]   = ""; # $tagcontent;
              $tagsarray[$ndx][XMLARRTAGMODE]   = "content";
              $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              $prevtag = "content";

              $tagclose = $1;
              --$level if ( $prevtag eq "close" || $prevtagbefcomment eq "close" );
              $tagsarray[++$ndx][XMLARRLEVEL] = $level;
              $tagsarray[$ndx][XMLARRTAG] = $tagclose;
              $tagsarray[$ndx][XMLARRTAGMODE] = "close";
              $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              $matched = 1;
              $prevtag = "close";
              $prevtagbefcomment = "";

              if ( $tfactlglobal_hash{"debugmask"} &
                  $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                tfactlshare_trace(5, "tfactl (PID = $$) " .
                                  "tfactlshare_populate_tagsarray $1 open close shrcut",
                                  'y', 'y');
              }
            
            } elsif( $line =~ m/^$XMLTAGOPENATTRIBUTESCLOSE$/ && $prevtag ne "commentopen" && $cdatatag ne "cdataopen"){
                                                      # tag open + attrib + close
                                                      # <tag attr1 ... />
              $tagopen = $1;

              # Tag open
              tfactlshare_parser_tagopen($prevtag, $prevtagbefcomment, $tagopen,
                                         \$ndx, \$level, \$lineNum, \@tagsarray );


              # Capture attributes
              my $attributes = $2;
              tfactlshare_parser_capture_attributes($attributes,$tagopen,\$ndx,\$level,\$lineNum,
                    \$matched,\$prevtag,TRUE,\@tagsarray);

              $tagsarray[++$ndx][XMLARRLEVEL] = $level;
              $tagsarray[$ndx][XMLARRTAG]   = ""; # $tagcontent;
              $tagsarray[$ndx][XMLARRTAGMODE]   = "content";
              $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              $prevtag = "content";

              $tagclose = $tagopen;
              --$level if ( $prevtag eq "close" || $prevtagbefcomment eq "close" );
              $tagsarray[++$ndx][XMLARRLEVEL] = $level;
              $tagsarray[$ndx][XMLARRTAG] = $tagclose;
              $tagsarray[$ndx][XMLARRTAGMODE] = "close";
              $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              $matched = 1;
              $prevtag = "close";
              $prevtagbefcomment = "";
            
            } elsif ( $line =~  m/^$XMLTAGOPENATTRIBUTES$/ && 
              $prevtag ne "commentopen" &&
              $cdatatag ne "cdataopen" ) {
                                                  # tag open + attrib
                                                  # <tag attr1 ... attrN> 
              $tagopen = $1;

              # Tag open
              tfactlshare_parser_tagopen($prevtag, $prevtagbefcomment, $tagopen,
                                         \$ndx, \$level, \$lineNum, \@tagsarray );

              # Capture attributes
              my $attributes = $2;
              tfactlshare_parser_capture_attributes($attributes,$tagopen,\$ndx,\$level,\$lineNum,
                    \$matched,\$prevtag,TRUE,\@tagsarray);
            } elsif ( $line =~ m/^$XMLTAGCLOSE$/ 
                      && $prevtag ne "commentopen" && $cdatatag ne "cdataopen" ) {                  
                                                                        # tag close
                                                                        # </tag>
              $tagclose = $1;
              --$level if ( $prevtag eq "close" || $prevtagbefcomment eq "close" );
              $tagsarray[$ndx][XMLARRLEVEL] = $level;
              $tagsarray[$ndx][XMLARRTAG] = $tagclose;
              $tagsarray[$ndx][XMLARRTAGMODE] = "close";
              $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              $matched = 1;
              $prevtag = "close";
              $prevtagbefcomment = "";
              if ( $tfactlglobal_hash{"debugmask"} &
                  $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                tfactlshare_trace(5, "tfactl (PID = $$) " .
                                  "tfactlshare_populate_tagsarray $1 close",
                                  'y', 'y');
              }
            } elsif ( $line =~ m/^$XMLTAGCLOSE$XMLTAGCLOSE$/ && $prevtag ne "commentopen" && $cdatatag ne "cdataopen" ) {
                                                                # tag close close
                                                                # </tag> </tag1>
                                                                                                                
              $tagclose     = $1;
              my $tag1close = $2;
              --$level if ( $prevtag eq "close" || $prevtagbefcomment eq "close" );
              $tagsarray[$ndx][XMLARRLEVEL] = $level;
              $tagsarray[$ndx][XMLARRTAG] = $tagclose;
              $tagsarray[$ndx][XMLARRTAGMODE] = "close";
              $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              --$level;
              $tagsarray[++$ndx][XMLARRLEVEL] = $level;
              $tagsarray[$ndx][XMLARRTAG] = $tag1close;
              $tagsarray[$ndx][XMLARRTAGMODE] = "close";
              $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              $matched = 1;
              $prevtag = "close";
              $prevtagbefcomment = "";
              if ( $tfactlglobal_hash{"debugmask"} &
                  $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                tfactlshare_trace(5, "tfactl (PID = $$) " .
                                  "tfactlshare_populate_tagsarray $1 close " .
                                  "$2 close", 'y', 'y');
              }
            } elsif( $line =~ m/^($XMLCONTENT*)$XMLTAGCLOSE$XMLTAGCLOSE$/
              && $prevtag ne "commentopen"
              && $cdatatag ne "cdataopen" ) {
                                                        # tag content close close
                                                        # content </tag> </tag1>
              $tagcontent   = $1;
              $tagclose     = $2;
              my $tag1close = $3;

              # Check if previous tag was content
              if ( $prevtag ne "content" ) {
                tfactlshare_parser_content($tagcontent, \$ndx, \$level, \$lineNum, FALSE, \@tagsarray);
              } else {
                # concatenate content
                --$ndx;
                $tagsarray[$ndx][XMLARRTAG]   .= " " . $tagcontent;
                $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              }

              $tagsarray[++$ndx][XMLARRLEVEL] = $level;
              $tagsarray[$ndx][XMLARRTAG] = $tagclose;
              $tagsarray[$ndx][XMLARRTAGMODE] = "close";
              $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              --$level;
              $tagsarray[++$ndx][XMLARRLEVEL] = $level;
              $tagsarray[$ndx][XMLARRTAG] = $tag1close;
              $tagsarray[$ndx][XMLARRTAGMODE] = "close";
              $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              $matched = 1;
              $prevtag = "close";
              $prevtagbefcomment = "";

              if ( $tfactlglobal_hash{"debugmask"} &
                  $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                tfactlshare_trace(5, "tfactl (PID = $$) " .
                                  "tfactlshare_populate_tagsarray $tagcontent content " .
                                  "$2 close $3 close", 'y', 'y');
              }
            } elsif ( $line =~ m/^$XMLTAGOPEN($XMLCONTENT*)$/ && $prevtag ne "commentopen" && $cdatatag ne "cdataopen" ) { 
                                                        # tag open content
                                                        # <tag> content
              $tagopen    = $1;
              $tagcontent = $2;
              $tagcontent =~ s/\n//g;
              $tagcontent =~ s/\r//g;
              # Tag open
              tfactlshare_parser_tagopen($prevtag, $prevtagbefcomment, $tagopen,
                                         \$ndx, \$level, \$lineNum, \@tagsarray );

              $tagsarray[++$ndx][XMLARRLEVEL] = $level;
              $tagsarray[$ndx][XMLARRTAG]   = $tagcontent;
              $tagsarray[$ndx][XMLARRTAGMODE]   = "content";
              $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              $matched = 1;
              $prevtag = "content";

              if ( $tfactlglobal_hash{"debugmask"} &
                $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                tfactlshare_trace(5, "tfactl (PID = $$) " .
                              "tfactlshare_populate_tagsarray $1 $2 " .
                              "open content", 'y', 'y');
              }
            } elsif ( $line =~ m/^\s*($XMLCONTENT*)$XMLTAGCLOSE$/ && $prevtag ne "commentopen" && $cdatatag ne "cdataopen" ) { 
                                                            #     content close
                                                            #     content </tag>
              $tagcontent = $1;
              $tagclose   = $2;
              
              # Check if previous tag was content
              if ( $prevtag ne "content" ) {
                tfactlshare_parser_content($tagcontent, \$ndx, \$level, \$lineNum, TRUE, \@tagsarray);
              } else {
                # concatenate content
                --$ndx;
                $tagsarray[$ndx][XMLARRTAG]   .= " " . $tagcontent;
                $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              }
              $tagsarray[++$ndx][XMLARRLEVEL]  = $level;
              $tagsarray[$ndx][XMLARRTAG]      = $tagclose;
              $tagsarray[$ndx][XMLARRTAGMODE]  = "close";
              $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              $prevtag = "close";
              $prevtagbefcomment = "";
              $matched = 1;

              if ( $tfactlglobal_hash{"debugmask"} &
                  $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                tfactlshare_trace(5, "tfactl (PID = $$) " .
                                  "tfactlshare_populate_tagsarray $1 $2 " .
                                  "content close", 'y', 'y');
              }
            } elsif ( $line =~ m/^$XMLTAGOPEN($XMLCONTENT*)$XMLTAGCLOSE$/ && $prevtag ne "commentopen" && $cdatatag ne "cdataopen") { 
                                                            #    tag open content close
                                                            #     <tag> content </tag>
            $tagopen    = $1;
            $tagcontent = $2;
            $tagclose   = $3;
            # Tag open
            tfactlshare_parser_tagopen($prevtag, $prevtagbefcomment, $tagopen,
                                       \$ndx, \$level, \$lineNum, \@tagsarray );

            $tagsarray[++$ndx][XMLARRLEVEL] = $level;
            $tagsarray[$ndx][XMLARRTAG]   = $tagcontent;
            $tagsarray[$ndx][XMLARRTAGMODE]   = "content";
            $tagsarray[$ndx][XMLLINENUM] = $lineNum;
            $tagsarray[++$ndx][XMLARRLEVEL] = $level;
            $tagsarray[$ndx][XMLARRTAG]   = $tagclose;
            $tagsarray[$ndx][XMLARRTAGMODE]   = "close";
            $tagsarray[$ndx][XMLLINENUM] = $lineNum;
            $matched = 1;
            $prevtag = "close";
            $prevtagbefcomment = "";

            if ( $tfactlglobal_hash{"debugmask"} &
                 $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
              tfactlshare_trace(5, "tfactl (PID = $$) " .
                               "tfactlshare_populate_tagsarray $1 $2 $3 " .
                               "open content close", 'y', 'y');
            }             
        } elsif ( $line =~ m/^$XMLTAGOPENATTRIBUTES($XMLCONTENT*)$/ && $prevtag ne "commentopen" && $cdatatag ne "cdataopen" ) {
                                              # tag open + attrib content
                                              # <tag attr1 ...> content
              $tagopen    = $1;
              $tagcontent = $3;
              # Tag open
              tfactlshare_parser_tagopen($prevtag, $prevtagbefcomment, $tagopen,
                                         \$ndx, \$level, \$lineNum, \@tagsarray );

              # Capture attributes
              my $attributes = $2;
              tfactlshare_parser_capture_attributes($attributes,$tagopen,\$ndx,\$level,\$lineNum,
                    \$matched,\$prevtag,FALSE,\@tagsarray);

              # Content
              tfactlshare_parser_content($tagcontent, \$ndx, \$level, \$lineNum, TRUE, \@tagsarray);
              $matched = 1;
              $prevtag = "content";

        } elsif ( $line =~ m/^$XMLTAGOPENATTRIBUTES($XMLCONTENT*)$XMLTAGCLOSE$/ && $prevtag ne "commentopen" && $cdatatag ne "cdataopen" ) {
                                              # tag open + attrib content close
                                              # <tag attr1 ...> content </tag>
              $tagopen    = $1;
              $tagcontent = $3;
              $tagclose   = $4;
              # Tag open
              tfactlshare_parser_tagopen($prevtag, $prevtagbefcomment, $tagopen,
                                         \$ndx, \$level, \$lineNum, \@tagsarray );

              # Capture attributes
              my $attributes = $2;
              tfactlshare_parser_capture_attributes($attributes,$tagopen,\$ndx,\$level,\$lineNum,
                    \$matched,\$prevtag,FALSE,\@tagsarray);

              # Content
              tfactlshare_parser_content($tagcontent, \$ndx, \$level, \$lineNum, TRUE, \@tagsarray);

              $tagsarray[++$ndx][XMLARRLEVEL] = $level;
              $tagsarray[$ndx][XMLARRTAG]   = $tagclose;
              $tagsarray[$ndx][XMLARRTAGMODE]   = "close";
              $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              $matched = 1;
              $prevtag = "close";
              $prevtagbefcomment = "";

            } elsif( $line =~ m/$XMLTAGOPEN($XMLCONTENT*($XMLCDATAOPEN$XMLCDATACONTENT$XMLCDATACLOSE)+$XMLCONTENT*)$XMLTAGCLOSE$/ && $prevtag ne "commentopen" && $cdatatag ne "cdataopen"){
                                                              #tag open content cdata open cdata content cdata close content tag close
                                                              #<tag> content <![CDATA[ CDATAContent ]]> content </tag>
              $tagopen    = $1;
              $tagcontent = $2;
              $tagclose   = $4;
              $tagcontent = tfactlshare_check_cdata_content($tagcontent,\$cdatatag,$lineNum);
              # Tag open
              tfactlshare_parser_tagopen($prevtag, $prevtagbefcomment, $tagopen,
                                         \$ndx, \$level, \$lineNum, \@tagsarray );

              tfactlshare_parser_content($tagcontent, \$ndx, \$level, \$lineNum, TRUE, \@tagsarray);

              $tagsarray[++$ndx][XMLARRLEVEL] = $level;
              $tagsarray[$ndx][XMLARRTAG]   = $tagclose;
              $tagsarray[$ndx][XMLARRTAGMODE]   = "close";
              $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              $matched = 1;
              $prevtag = "close";
              $prevtagbefcomment = "";

              if ( $tfactlglobal_hash{"debugmask"} &
                $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                tfactlshare_trace(5, "tfactl (PID = $$) " .
                              "tfactlshare_populate_tagsarray $1 $2 $4 " .
                              "open content+cdata close ", 'y', 'y');
              }

            } elsif($line =~ m/^$XMLTAGOPENATTRIBUTES($XMLCONTENT*($XMLCDATAOPEN$XMLCDATACONTENT$XMLCDATACLOSE)+$XMLCONTENT*)$XMLTAGCLOSE$/ && $prevtag ne "commentopen" && $cdatatag ne "cdataopen"){
                                                      #tag + attrib open content cdata open cdata content cdata close content tag close 
                                                      #<tag  attrib1 ... > content <![CDATA[CDATAContent ]]> content </tag>
             $tagopen    = $1;
             $tagcontent = $3;
             $tagclose   = $5;
             
             # Tag open
              tfactlshare_parser_tagopen($prevtag, $prevtagbefcomment, $tagopen,
                                         \$ndx, \$level, \$lineNum, \@tagsarray );

              # Capture attributes
              my $attributes = $2;
              tfactlshare_parser_capture_attributes($attributes,$tagopen,\$ndx,\$level,\$lineNum,
                    \$matched,\$prevtag,FALSE,\@tagsarray);

              # Content
              $tagsarray[++$ndx][XMLARRLEVEL] = $level;
              $tagsarray[$ndx][XMLARRTAG]   = tfactlshare_check_cdata_content($tagcontent,\$cdatatag,$lineNum);
              $tagsarray[$ndx][XMLARRTAGMODE]   = "content";
              $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              $tagsarray[++$ndx][XMLARRLEVEL] = $level;
              $tagsarray[$ndx][XMLARRTAG]   = $tagclose;
              $tagsarray[$ndx][XMLARRTAGMODE]   = "close";
              $tagsarray[$ndx][XMLLINENUM] = $lineNum;
              $matched = 1;
              $prevtag = "close";
              $prevtagbefcomment = "";

            
            }  elsif( $line =~ m/^$XMLTAGOPEN($XMLCDATACONTENT)/ && $prevtag ne "commentopen" && $cdatatag ne "cdataopen"){
                                                                    #tag open content 
                                                                    #<tag>content <![CDATA[ CDATAContent ]]> content
                                                                    #content <![CDATA[ CDATAContent ]]> content 
                                                                    #is handle in tfactlshare_check_cdata_content  
              $tagopen = $1;
              $tagcontent = $2;
              $tagcontent = tfactlshare_check_cdata_content($tagcontent,\$cdatatag,$lineNum);
              # Tag open
              tfactlshare_parser_tagopen($prevtag, $prevtagbefcomment, $tagopen,
                                         \$ndx, \$level, \$lineNum, \@tagsarray );

              tfactlshare_parser_content($tagcontent, \$ndx, \$level, \$lineNum, TRUE, \@tagsarray);

              $matched = 1;
              $prevtag = "content";

              if ( $tfactlglobal_hash{"debugmask"} &
                $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                tfactlshare_trace(5, "tfactl (PID = $$) " .
                              "tfactlshare_populate_tagsarray $1 $2 " .
                              "open content+cdata", 'y', 'y');
              }

            } elsif($cdatatag eq "cdataopen" && $prevtag ne "commentopen"){ #CDATAOpen 
                --$ndx;
                if($line =~ m/^([$XMLCDATACONTENT$XMLCDATACLOSE)$XMLTAGCLOSE$/g){
                                                          #cdata content cdata close tag close
                                                          #CDATAcontent ]]></tag>
                  $tagcontent =$1;
                  $tagclose=$2;

                  $tagsarray[$ndx][XMLARRLEVEL]=$level;
                  $tagsarray[$ndx][XMLARRTAG].= tfactlshare_check_cdata_content($tagcontent,\$cdatatag,$lineNum);
                  $tagsarray[$ndx][XMLARRTAGMODE] = "content";
                  $tagsarray[$ndx][XMLLINENUM] = $lineNum;

                  $tagsarray[++$ndx][XMLARRLEVEL]=$level;
                  $tagsarray[$ndx][XMLARRTAG] = $tagclose;
                  $tagsarray[$ndx][XMLARRTAGMODE] ="close";
                  $tagsarray[$ndx][XMLLINENUM] = $lineNum;
                  $prevtag = "close";


                  if ( $tfactlglobal_hash{"debugmask"} &
                    $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                    tfactlshare_trace(5, "tfactl (PID = $$) " .
                              "tfactlshare_populate_tagsarray $1 $2 " .
                              "content+cdata close", 'y', 'y');
                  }


                } elsif($line =~ m/^([$XMLCDATACONTENT$XMLCDATACLOSE)$XMLTAGCLOSE$XMLTAGCLOSE$/g){
                                                                                    #cdata content cdata close tag close tag close 
                                                                                    #CDATAcontent ]]></tag></tag>
                  $tagcontent = $1;
                  $tagclose =$2;
                  my $tag1close =$3;
                  
                  $tagsarray[$ndx][XMLARRLEVEL]=$level;
                  $tagsarray[$ndx][XMLARRTAG].= tfactlshare_check_cdata_content($tagcontent,\$cdatatag,$lineNum);
                  $tagsarray[$ndx][XMLARRTAGMODE]="content";
                  $tagsarray[$ndx][XMLLINENUM] = $lineNum;

                  $tagsarray[++$ndx][XMLARRLEVEL]=$level;
                  $tagsarray[$ndx][XMLARRTAG] = $tagclose;
                  $tagsarray[$ndx][XMLARRTAGMODE] ="close";
                  $tagsarray[$ndx][XMLLINENUM] = $lineNum;
                  --$level;
                  $tagsarray[$ndx][XMLARRLEVEL]=$level;
                  $tagsarray[$ndx][XMLARRTAG] = $tag1close;
                  $tagsarray[$ndx][XMLARRTAGMODE]="close";
                  $tagsarray[$ndx][XMLLINENUM] = $lineNum;
                  $prevtag = "close";
                  $prevtagbefcomment="";

                  if ( $tfactlglobal_hash{"debugmask"} &
                    $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                    tfactlshare_trace(5, "tfactl (PID = $$) " .
                              "tfactlshare_populate_tagsarray $1 $2 $3 " .
                              "cdata content close close", 'y', 'y');
                  }


                } elsif($line =~ m/^($XMLCDATACONTENT$XMLCDATACLOSE)$/g){
                                                        #cdata content cdata close
                                                        #CDATAContent]]>
                 
                 $tagcontent = $1;
                 $tagsarray[$ndx][XMLARRLEVEL]=$level;
                 $tagsarray[$ndx][XMLARRTAG].= tfactlshare_check_cdata_content($tagcontent,\$cdatatag,$lineNum);
                 $tagsarray[$ndx][XMLARRTAGMODE]="content";
                 $tagsarray[$ndx][XMLLINENUM] = $lineNum;
                 
               } elsif($line =~ m/^($XMLCDATACONTENT$XMLCDATACLOSE)($XMLCONTENT+)$/g){
                                                                        #cdata content cdata close content
                                                                        #CDATAContent]]>content 
                 $tagcontent = $1;
                 $tagcontent = tfactlshare_check_cdata_content($tagcontent,\$cdatatag,$lineNum);
                 my $cont = $2;
                 $cont =~ s/\r//;
                 $cont =~ s/\n//;
                 $tagcontent .= " ".$cont;
                 $tagsarray[$ndx][XMLARRLEVEL]=$level;
                 $tagsarray[$ndx][XMLARRTAG].=$tagcontent;
                 $tagsarray[$ndx][XMLARRTAGMODE]="content";
                 $tagsarray[$ndx][XMLLINENUM] = $lineNum;


             } elsif($line =~ m/^($XMLCDATACONTENT$XMLCDATACLOSE)(\s*$XMLCDATAOPEN($XMLCDATACONTENT))$/g){
                                                                    #cdata content cdataclose cdata open cdata content
                                                                    #CDATAContent]]><![CDATA[CDATAContent
               $tagcontent = tfactlshare_check_cdata_content($1,\$cdatatag,$lineNum);
               $cdatatag="cdataopen";
               $tagcontent.= tfactlshare_check_cdata_content($3,\$cdatatag,$lineNum);
               $tagsarray[$ndx][XMLARRLEVEL]=$level;
               $tagsarray[$ndx][XMLARRTAG].=$tagcontent;
               $tagsarray[$ndx][XMLARRTAGMODE]="content";
               $tagsarray[$ndx][XMLLINENUM] = $lineNum;
               

             } elsif($line =~ m/^($XMLCDATACONTENT$XMLCDATACLOSE)($XMLCONTENT+)($XMLCDATAOPEN($XMLCDATACONTENT))$/g){
                                                                      #cdata content cdata close content cdata open cdata content
                                                                      #CDATAContent]]>content<![CDATA[CDATAContent
               $tagcontent= tfactlshare_check_cdata_content($1,\$cdatatag,$lineNum);
               my $cont = $2;
               $cont =~ s/\r//;
               $cont =~ s/\n//;
               $tagcontent .= $cont;
               $cdatatag = "cdataopen";
               $tagcontent.= tfactlshare_check_cdata_content($4,\$cdatatag,$lineNum);
               $tagsarray[$ndx][XMLARRLEVEL]=$level;
               $tagsarray[$ndx][XMLARRTAG].=$tagcontent;
               $tagsarray[$ndx][XMLARRTAGMODE]="content";
               $tagsarray[$ndx][XMLLINENUM] = $lineNum;
               
             } else{
                                                                 #CDATAContent
               $tagcontent = tfactlshare_check_cdata_content($line,\$cdatatag,$lineNum);
               $tagsarray[$ndx][XMLARRLEVEL]=$level;
               $tagsarray[$ndx][XMLARRTAG].=$tagcontent;
               $tagsarray[$ndx][XMLARRTAGMODE]="content";
               $tagsarray[$ndx][XMLLINENUM] = $lineNum;
               
              
             }
             $matched = 1;
           }
           if ( $matched == 1 ) {
                ++$ndx;
                if ( $tfactlglobal_hash{"debugmask"} &
                    $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} ) {
                  tfactlshare_trace(5, "tfactl (PID = $$) " .
                                  "tfactlshare_populate_tagsarray Index value $ndx",
                                  'y', 'y');
                }
                $matched = 0;
           } else {
             if ( ! $matched ){
               tfactlshare_error_msg(404, undef);
               print "XML error, invalid character at line $lineNum.\n\n";
               exit;
            }

           }
      } # End while main
     
      # Validate tags array
      my @validator;
      my $tag;
      my $tagmode;
      my $taglevel;
      my $poppedtag;
      my $debugmsg;
      my $rootnodescnt = 0;
      my $line;

      for $ndx ( 0 .. $#tagsarray ) { 
        # Process item
        $tag = lc($tagsarray[$ndx][XMLARRTAG]);
        $tagmode = $tagsarray[$ndx][XMLARRTAGMODE];
        $taglevel = $tagsarray[$ndx][XMLARRLEVEL];
        $line = $tagsarray[$ndx][XMLLINENUM];
        $debugmsg = "tfactlshare_populate_tagsarray ";

        ++$rootnodescnt if ( $taglevel == 0 && $tagmode ne "attribname" &&
                            $tagmode ne "attribval");
        if ( $tfactlglobal_hash{"debugmask"} &
            $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"} &&
            $tfactlglobal_hash{'verbose'} eq "xmldet" ) {
          print "VALROOT => $tag $tagmode $taglevel rootnodes $rootnodescnt \n";
        }
        if ( $rootnodescnt > 2 ) {
            # Multiple root elements were found.
            tfactlshare_error_msg(405, ["first", "second", "third" ] );
            print "at line $line \n";
            exit;
        }

        if ( $tagmode eq "open" ) {
          push @validator, $tag;
          $debugmsg .= "PUSHING $tag ";
        } elsif ( $tagmode eq "close" ) {
          $poppedtag = pop @validator;
          $debugmsg .= "POPPED $poppedtag ";
          if ( $tag ne $poppedtag ) {
            tfactlshare_error_msg(404, undef);
            print "XML error, expected $poppedtag found $tag at line $line .\n\n";
            exit;
          }
        } # end elsif

        if ( ($tfactlglobal_hash{"debugmask"} &
            $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"}) &&
            $tfactlglobal_hash{'verbose'} eq "xmldet" &&
            ($tagmode eq "open" || $tagmode eq "close" )) {
          $debugmsg .= "=> taglevel $taglevel \n";
          print $debugmsg;
        }
      } # end for validate tags array

      if ( $tfactlglobal_hash{"debugmask"} &
          $tfactlglobal_mod_levels{"tfactlshare_populate_tagsarray"}  ) {
        print "\n\n tfactlshare_populate_tagsarray tagsarray \n\n";
        for $ndx ( 0 .. $#tagsarray ) {
          print "$ndx: $tagsarray[$ndx][XMLARRLEVEL] $tagsarray[$ndx][XMLARRTAG] $tagsarray[$ndx][XMLARRTAGMODE] $tagsarray[$ndx][XMLLINENUM] \n";
        }
      }

      return @tagsarray;
    }

    #######
    # NAME
    #   tfactlshare_check_cdata_content
    # DESCRIPTION
    #    This fuction checks if CDATA content is valid
    # PARAMETERS
    #     $allcontent - content to check includes content <![CDATA[ CDATAContent ]]> content
    #     $cdatatagref  -reference to the cdatatag
    #     $lineNum      -current line of the XML File
    # RETURNS
    #    $retcontent -content 
    ####### 
    sub tfactlshare_check_cdata_content{
      my $retcontent="";
      my $allcontent = shift;
      my $cdatatagref = shift;
      my $lineNum = shift;

      while($allcontent =~ /(($XMLCDATACONTENT?)$XMLCDATACLOSE)|($XMLCDATACONTENT)/ && length($allcontent)>0){
        if( $1 ne "" && $$cdatatagref eq "cdataopen" ) {
          $$cdatatagref = "cdataclose";
          $retcontent.=$2;
          $allcontent = substr($allcontent,length($1));
        } elsif( $1 ne "" && $1 ne "]]>" ) {
          my $cont = $2;
          if( $cont =~ /^($XMLCDATAOPEN)($XMLCDATACONTENT)/ ) {
            $$cdatatagref="cdataopen";
            $allcontent = substr($allcontent,length($1));
          } elsif($cont =~ /^$XMLCONTENT+$/){ 
            $retcontent .= " ".$cont;
            $allcontent= substr($allcontent,length($cont));
          } elsif($cont =~ /^($XMLCONTENT+)$XMLCDATAOPEN$XMLCDATACONTENT$/){
            $retcontent .= " ".$1;
            $allcontent = substr($allcontent,length($1));
          } else {
            tfactlshare_error_msg(404, undef);
            print "Sequence ]]> not allowed at line $lineNum\n";
            exit;
          }
        } elsif( $3 ne "" && $$cdatatagref eq "cdataopen" ){
          $retcontent.=$3;
          $allcontent = substr($allcontent,length($3));
        } elsif( $3 ne "" ){
          my $cont = $3;
          if( $cont =~ /^($XMLCDATAOPEN)($XMLCDATACONTENT)/ ){
            $$cdatatagref="cdataopen";
            $allcontent = substr($allcontent,length($1));
          } elsif( $cont =~ /^$XMLCONTENT+$/ ){
            $retcontent .= " ".$cont;
            $allcontent= substr($allcontent,length($cont));
          } elsif( $cont =~ /^($XMLCONTENT+)$XMLCDATAOPEN$XMLCDATACONTENT$/){
            $retcontent .= " ".$1;
            $allcontent = substr($allcontent,length($1));
          } else {
            tfactlshare_error_msg(404, undef);
            print "Invalid content \' $cont \' at line $lineNum\n";
            exit;
          }
        } else{
              tfactlshare_error_msg(404, undef);
              print "Invalid content \' $allcontent \' at line $lineNum\n";
              exit;
        }
      }#end while
      if( length($allcontent)>0 ){
        tfactlshare_error_msg(404, undef);
        print "Invalid content \'$allcontent\' at line $lineNum\n";
        exit;
      }
      return $retcontent;
    }


    ########
    # NAME
    #   tfactlshare_validate_tagsarray
    # 
    # DESCRIPTION
    #   This function validates @tagsarray
    #   containing,
    #   XMLARRLEVEL XMLARRTAG XMLARRTAGMODE
    #                           open
    #                           attribname
    #                           attribval
    #                           content
    #                           close
    #
    # PARAMETERS 
    #   $tagsarrayref
    #   $targetlevel = shift;
    #   $initpos
    # 
    # RETURNS
    #   @tagsarray
    #   
    ########
    sub tfactlshare_validate_tagsarray {

      my $tagsarrayref = shift;
      my @tagsarray = @$tagsarrayref;
      my $targetlevel = shift;
      my $initpos = shift;
      my @validator;
      my $tag;
      my $taglevel;
      my $tagmode;
      my $poppedtag;
      my $debugmsg;

      for my $ndx ( $initpos .. $#tagsarray ) {
        # Last if arraylevel == $targetlevel - 1
        $taglevel = $tagsarray[$ndx][XMLARRLEVEL];

        if ( $taglevel == $targetlevel - 1 ) {
          last;
        } 

        # Process item
        $tag = lc($tagsarray[$ndx][XMLARRTAG]);
        $tagmode = $tagsarray[$ndx][XMLARRTAGMODE];
        $debugmsg = "tfactlshare_validate_tagsarray ";

        if ( $tagmode eq "open" ) {
          push @validator, $tag;
          $debugmsg .= "PUSHING $tag ";
        } elsif ( $tagmode eq "close" ) {
          $poppedtag = pop @validator;
          $debugmsg .= "POPPED $poppedtag ";
          if ( $tag ne $poppedtag ) {
            tfactlshare_error_msg(404, undef);
            print "XML error, expected $poppedtag found $tag.\n\n";
            exit;
            #last;
          }
        }

        if ( ($tfactlglobal_hash{"debugmask"} &
            $tfactlglobal_mod_levels{"tfactlshare_validate_tagsarray"}) && 
              $tfactlglobal_hash{'verbose'} eq "xmldet" &&
            ($tagmode eq "open" || $tagmode eq "close") ) {
          $debugmsg .= "=> targetlevel $targetlevel taglevel $taglevel \n";
          print $debugmsg;
        }


      } # end for tagsarray

      return;
    }


    ########
    # NAME
    #   tfactlshare_get_element
    #
    # DESCRIPTION
    #   Get element from @tagsarray
    #   This function populates @retelementsarray
    #   containing $elementname, $elementvalue,
    #   $elementvaluetype, $elementndx,
    #   $elementlevel, $elementattrname &
    #   $elementattrval
    #
    #   $elementname:  <elemente_name>
    #   $elementvalue: element content, nodata, attribute name / value
    #   $elementvaluetype: cdata, nodata, children, attribname, attribval
#   $elementndx: ndx where children can be found
#   $elementlevel: element level
#   $elementtattrname: attribute name if $elementvaluetype = attribname
#   $$elementattrval: attribute value if $elementvaluetype = attribval
#
# PARAMETERS
#    $targetlevel - 
#    $initpos - initpos to start
# RETURNS
#    @retelementsarray
#                ELEMNAME
#                ELEMVAL
#                ELEMVALTYPE
#                ELEMNDX
#                ELEMLEVEL
#                ELEMATTRNAME -> @attrnamearray
#                ELEMATTRVAL  -> @attrvalarray
#
########
sub tfactlshare_get_element {

  my $tagsarrayref = shift;
  my @tagsarray = @$tagsarrayref;
  my $targetlevel = shift;
  my $initpos = shift; 
  my $cntelem = 0; # Track level
  # tag data
  my $tagopen;
  my $tagclose;
  my $taglevel;
  my $tagcontent;
  my $tagcontenttype;
  my $tagattrname;
  my $tagattrval;

  my $tagopenndx = 0;
  my $tagclosendx = 0;

  # Element's detail
  my $elementname;
  my $elementvalue;
  my $elementvaluetype;
  my $elementlevel;
  my $elementattrname;
  my $elementattrval;

  my $elementndx = 0;

  my @retelementsarray;
  my $ndx = 0;
  my @attrnamearray;
  my @attrvalarray;
  my $attrndx = 0;
  my $attributecnt = 0;

  # There's no need to traverse empty content
  return @retelementsarray if $initpos <0;

  # validate xml
  tfactlshare_validate_tagsarray(\@tagsarray, $targetlevel, $initpos);

  # Get Components
  for $ndx ( $initpos .. $#tagsarray ) {
    # Last if arraylevel == $targetlevel - 1
    if ( $tagsarray[$ndx][XMLARRTAGMODE] ne "attribval" &&
         $tagsarray[$ndx][XMLARRTAGMODE] ne "attribname" &&
         $tagsarray[$ndx][XMLARRLEVEL] == $targetlevel - 1 && $cntelem ) {
      last;
    } elsif ( $tagsarray[$ndx][XMLARRTAGMODE] ne "attribval" &&
              $tagsarray[$ndx][XMLARRTAGMODE] ne "attribname" &&
              $tagsarray[$ndx][XMLARRLEVEL] == $targetlevel - 1 && not $cntelem ) {
      ++$cntelem;
    }

    if ( $tagsarray[$ndx][XMLARRLEVEL] == $targetlevel ) {
      if ( $tagsarray[$ndx][XMLARRTAGMODE] eq "open" ) {
        $tagopen = $tagsarray[$ndx][XMLARRTAG];
        $taglevel = $tagsarray[$ndx][XMLARRLEVEL];
        $tagopenndx = $ndx;
      } elsif ( $tagsarray[$ndx][XMLARRTAGMODE] eq "close" ) {
        $tagclose = $tagsarray[$ndx][XMLARRTAG];
        $tagclosendx = $ndx;
        if ( $tagopen eq $tagclose ) {
           $elementname = $tagopen;
           $elementlevel = $taglevel;
           if ( defined $tagcontenttype && $tagcontenttype eq "cdata" ) {
             $elementvalue = $tagcontent;
             $elementvaluetype = "cdata";
             $elementndx = $tagopenndx + 1;
           } elsif ( $tagclosendx == $tagopenndx + 1 ) {
             $elementvaluetype = "nodata";
             $elementndx = -1;
           } else {
             $elementvaluetype = "children";
             $elementndx = $tagopenndx + 1;
           }
           if ( $attributecnt > 0 ) {
             $elementndx += $attributecnt * 2;
             $attributecnt = 0;
           }

           undef $tagopen;
           $tagopenndx = 0;
           undef $tagcontent;
           undef $tagcontenttype;
           undef $tagattrname;
           undef $tagattrval;
           undef $tagclose;
           undef $taglevel;
           $tagclosendx = 0;
        }
      } elsif ( $tagsarray[$ndx][XMLARRTAGMODE] eq "content" ) {
        $tagcontent = $tagsarray[$ndx][XMLARRTAG];
        $tagcontenttype = "cdata";
      } elsif ( $tagsarray[$ndx][XMLARRTAGMODE] eq "attribname" ) {
        $tagattrname = $tagsarray[$ndx][XMLARRTAG];
        $attrnamearray[$attrndx] = $tagattrname;
        $elementndx++;
      } elsif ( $tagsarray[$ndx][XMLARRTAGMODE] eq "attribval" ) {
        $tagattrval = $tagsarray[$ndx][XMLARRTAG];
        $attrvalarray[$attrndx++] = $tagattrval;
        $elementndx++;
        $attributecnt++;
      }

      if ( defined $elementname ) {
         push @retelementsarray, [ $elementname, $elementvalue,
                                   $elementvaluetype, $elementndx,
                                   $elementlevel, [@attrnamearray],
                                   [@attrvalarray] ];
         if ( defined $elementvalue && defined $elementattrname &&
              defined $elementattrval ) {
            if ( $tfactlglobal_hash{"debugmask"} &
                 $tfactlglobal_mod_levels{"tfactlshare_get_element"} ) {
              tfactlshare_trace(5, "tfactl (PID = $$) " .
                                "tfactlshare_get_element ELEMENT ===> " .
                                " $elementname , " .
                                "$elementvalue , $elementvaluetype , " .
                                "$elementndx , $elementlevel , $elementattrname , " .
                                "$elementattrval ", 'y', 'y');
            }
         }
         if ( @attrnamearray && @attrvalarray ) {
           if ( $tfactlglobal_hash{"debugmask"} &
                $tfactlglobal_mod_levels{"tfactlshare_get_element"} ) {
             tfactlshare_trace(5, "tfactl (PID = $$) " .
                               "tfactlshare_get_element ATTRNAMEARRAY ===> [" .
                               " @attrnamearray ], ATTRVALARRAY ===> [" .
                               " @attrvalarray ]", 'y', 'y');
           }
         }
         undef $elementname;
         undef $elementvalue;
         undef $elementvaluetype;
         undef $elementndx;
         undef $elementlevel;
         undef $elementattrname;
         undef $elementattrval;
         undef @attrnamearray;
         undef @attrvalarray;
         $attrndx = 0;
      } # end if defined $elementname
     # print "$tagsarray[$ndx][XMLARRLEVEL] $tagsarray[$ndx][XMLARRTAG] $tagsarray[$ndx][XMLARRTAGMODE] \n";
    } # end if $tagsarray[$ndx][XMLARRLEVEL] == $targetlevel
  } # end for
  return @retelementsarray;
}


########
# NAME
#   tfactlshare_parse_xmlcomp
#
# DESCRIPTION
#   This function parses components.xml and
#   loads the contents into global array
#   @xmlcompsarray
#
# PARAMETERS
#
# RETURNS
#   @xmlcompsarray
#       [ $compname, $compvalidate, $compaltname, $compdescription,
#         $compinstancehome, $comptype, [@subxmlcompsarray],
#         $compconfig, [@scriptsarray],
#         [@alsocollectarray] ]
#
#   Array holding components/subcomponents where validation="true"
#   @validatexmlcompsarray
#       [ $compname, $compvalidate, $comptype, [@subxmlcompsarray],
#         $compconfig, [@scriptsarray], [@alsocollectarray] ]
########
sub tfactlshare_parse_xmlcomp {
  my $tfa_home = shift;
  my $componentsFile = $tfactlglobal_components_file;
  my $name;
  my $value;
  my $compname;
  my $compvalidate;
  my $compaltname;
  my $compdescription;
  my $compinstancehome;
  my $comptype;
  my $compconfig;
  my $attrname;
  my $attrval;
  my @typesarray;
  my @subxmlcompsarray;
  my $subcompname;
  my $subcompidx;
  my $subcomprequired;
  my $subcompdefault;
  my @alsocollectarray;
  my @scriptsarray;
  my $ndx;
  my @tagsarray;
  my $tfa_base;

  if ( $ISCLOUD ) {
	$tfa_base = getTFABase();
	if ( $ISJCS ) {
		$componentsFile = catfile($tfa_base, "resources", "components_jcs.xml");
	} elsif ( $ISFMW ) {
		$componentsFile = catfile($tfa_base, "resources", "components_saas.xml");
	} else {
		$componentsFile = catfile($tfa_base, "resources", "components.xml");
	}
  }

  # empty $tfa_base
  # manuegar_extract_tfa_03
  if ( not length $tfa_base ) {
    $componentsFile = catfile($tfa_home, "resources", "components.xml");
  }
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare " .
                    "tfactlshare_parse_xmlcomp tfa_home $tfa_home tfa_base $tfa_base", 'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare " .
                    "tfactlshare_parse_xmlcomp componentsFile $componentsFile", 'y', 'y');

  # Parse xml file
  @tagsarray = tfactlshare_populate_tagsarray($componentsFile);

  if ( ($tfactlglobal_hash{"debugmask"} &
       $tfactlglobal_mod_levels{"tfactlshare_parse_xmlcomp"}) &&
       $tfactlglobal_hash{'verbose'} eq "xmldet" ) {
    print "\n\n tfactlshare_parse_xmlcomp elementsarray \n\n";
    my @elementsarray;
    @elementsarray = tfactlshare_get_element(\@tagsarray, 1,0);
     for $ndx ( 0 .. $#elementsarray ) {
        print " name value  $elementsarray[$ndx][ELEMNAME] " .
              "$elementsarray[$ndx][ELEMVAL] \n";
        print " type index  $elementsarray[$ndx][ELEMVALTYPE] " .
              "$elementsarray[$ndx][ELEMNDX] \n";
        print " level attrname attrval $elementsarray[$ndx][ELEMLEVEL] " .
              "$elementsarray[$ndx][ELEMATTRNAME] " .
              "$elementsarray[$ndx][ELEMATTRVAL] \n";
     } 

     @elementsarray = tfactlshare_get_element(\@tagsarray, 2,0);
     for $ndx ( 0 .. $#elementsarray ) {
        print " name value  $elementsarray[$ndx][ELEMNAME] " .
              "$elementsarray[$ndx][ELEMVAL] \n";
        print " type index  $elementsarray[$ndx][ELEMVALTYPE] " .
              "$elementsarray[$ndx][ELEMNDX] \n";
        print " level attrname attrval $elementsarray[$ndx][ELEMLEVEL] " .
              "$elementsarray[$ndx][ELEMATTRNAME] " .
              "$elementsarray[$ndx][ELEMATTRVAL] \n";
     }
    print "=================\n";

    my @componentsList = tfactlshare_get_element(\@tagsarray, 1,0);
    foreach my $child (@componentsList)
    {
       print "child : @$child[0] @$child[1] @$child[2] @$child[3] \n";
    }
  }

  # Parse components
  my @componentsList = tfactlshare_get_element(\@tagsarray, 1,0);

  foreach my $child (@componentsList)
  {
    # Get component
    my $name = @$child[ELEMNAME];

    # Get attribute "validate"
    ($attrname , $attrval) = tfactlshare_get_attribute(
     @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL],
     "validate" );
    $compvalidate = $attrval;
    ###print "Validate attribute = $compvalidate \n";

    # Get component details
    my @componentDetails = tfactlshare_get_element( \@tagsarray, 
                            @$child[ELEMLEVEL]+1 , @$child[ELEMNDX] );
    foreach my $compdet (@componentDetails)
    {
      $name = @$compdet[ELEMNAME];
      $value = @$compdet[ELEMVAL];

        # ------------------------------------------------------
      if ( lc($name) eq "name" ) {                # name
        $compname = $value;
        if ( $tfactlglobal_hash{"debugmask"} &
             $tfactlglobal_mod_levels{"tfactlshare_parse_xmlcomp"} ) {
          tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare " .
                            "tfactlshare_parse_xmlcomp NAME $name $value",
                            'y', 'y');
        }
        # ------------------------------------------------------
      } elsif ( lc($name) eq "alt_name" ) {       # alt_name
        $compaltname = $value;
        if ( $tfactlglobal_hash{"debugmask"} &
             $tfactlglobal_mod_levels{"tfactlshare_parse_xmlcomp"} ) {
          tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare " .
                            "tfactlshare_parse_xmlcomp ALT_NAME $name $value",
                            'y', 'y');
        }
        # ------------------------------------------------------
      } elsif ( lc($name) eq "description" ) {    # description
        $compdescription = $value;
        if ( $tfactlglobal_hash{"debugmask"} &
             $tfactlglobal_mod_levels{"tfactlshare_parse_xmlcomp"} ) {
          tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare " .
                          "tfactlshare_parse_xmlcomp DESCRIPTION $name $value",
                          'y', 'y');
        }
        # ------------------------------------------------------
      } elsif ( lc($name) eq "instance_home" ) {   # INSTANCE_HOME
        $compinstancehome = $value;
        if ( $tfactlglobal_hash{"debugmask"} &
             $tfactlglobal_mod_levels{"tfactlshare_parse_xmlcomp"} ) {
          tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare " .
                          "tfactlshare_parse_xmlcomp INSTANCE_HOME $name $value",
                          'y', 'y');
        }
        # ------------------------------------------------------
      } elsif ( lc($name) eq "types" ) {           # type
        $comptype = $value;
        if ( $tfactlglobal_hash{"debugmask"} &
             $tfactlglobal_mod_levels{"tfactlshare_parse_xmlcomp"} ) {
          tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare " .
                           "tfactlshare_parse_xmlcomp TYPE $name $value",
                           'y', 'y');
        }
        my @typesList = tfactlshare_get_element( \@tagsarray,
                            @$compdet[ELEMLEVEL]+1 , @$compdet[ELEMNDX] );
        $ndx = 0;
        foreach my $typedet (@typesList)
        { 
          $name  = @$typedet[ELEMNAME];
          $value = @$typedet[ELEMVAL];
          $typesarray[$ndx++] = lc($value);
        } # end foreach
        # ------------------------------------------------------
      } elsif ( lc($name) eq "sub-components" ) { # sub-components
        my @subcompList = tfactlshare_get_element( \@tagsarray,
                            @$compdet[ELEMLEVEL]+1 , @$compdet[ELEMNDX] ); 
        $ndx = 0;
        foreach my $subcompdet (@subcompList)
        {
          undef $subcompidx;
          $name = @$subcompdet[ELEMNAME];
          $value = @$subcompdet[ELEMVAL];

          # Get attribute "idx"
          ($attrname , $attrval) = tfactlshare_get_attribute(
                       @$subcompdet[ELEMATTRNAME] , @$subcompdet[ELEMATTRVAL],
                       "idx" );
          $subcompidx = $attrval; 
          # Get attribute "name"
          ($attrname , $attrval) = tfactlshare_get_attribute(
                       @$subcompdet[ELEMATTRNAME] , @$subcompdet[ELEMATTRVAL],
                       "name" );
          $subcompname = $attrval;
          # Get attribute "required"
          ($attrname , $attrval) = tfactlshare_get_attribute(
                       @$subcompdet[ELEMATTRNAME] , @$subcompdet[ELEMATTRVAL],
                       "required" );
          $subcomprequired = $attrval;
          # Get attribute "default"
          ($attrname , $attrval) = tfactlshare_get_attribute(
                       @$subcompdet[ELEMATTRNAME] , @$subcompdet[ELEMATTRVAL],
                       "default" );
          $subcompdefault = $attrval;
          my $regex = eval { qr/$subcompdefault/ };
          if ( $@ ) {
            tfactlshare_error_msg(406, undef);
            print "$@\n";
            exit;
          }
          ###print "Sub $subcompname $subcomprequired $subcompdefault \n";

          $subxmlcompsarray[$ndx++] = [ $value, $subcompidx, $subcompname, 
                                        $subcomprequired, $subcompdefault ];


          if ( $tfactlglobal_hash{"debugmask"} &
               $tfactlglobal_mod_levels{"tfactlshare_parse_xmlcomp"} ) {
            tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare " .
                              "tfactlshare_parse_xmlcomp SUBCOMP $name $value",
                              'y', 'y');
          }
        } # end foreach $subcompList
        # ------------------------------------------------------
      } elsif ( lc($name) eq "config" ) {         # config
        $compconfig = $value;
        if ( $tfactlglobal_hash{"debugmask"} &
             $tfactlglobal_mod_levels{"tfactlshare_parse_xmlcomp"} ) {
          tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare " .
                            "tfactlshare_parse_xmlcomp CONFIG $name $value",
                            'y', 'y');
        }
        # ------------------------------------------------------
      } elsif ( lc($name) eq "scripts" ) {          # scripts
        my @scriptsList = tfactlshare_get_element( \@tagsarray,
                            @$compdet[ELEMLEVEL]+1 , @$compdet[ELEMNDX] );

        if ( ($tfactlglobal_hash{"debugmask"} &
             $tfactlglobal_mod_levels{"tfactlshare_parse_xmlcomp"}) &&
             $tfactlglobal_hash{'verbose'} eq "xmldet" ) {
          print "\n\n tfactlshare_parse_xmlcomp scriptsList  \n\n";
          for $ndx ( 0 .. $#scriptsList ) {
             print "------------------------------------------\n";
             print "tfactlshare_parse_xmlcomp scripts \n";
             print "------------------------------------------\n";
             print " name value  $scriptsList[$ndx][ELEMNAME] " . 
                   "$scriptsList[$ndx][ELEMVAL] \n";
             print " type index  $scriptsList[$ndx][ELEMVALTYPE] " .
                   "$scriptsList[$ndx][ELEMNDX] \n";
             print " attrname attrval $scriptsList[$ndx][ELEMATTRNAME] " .
                   "$scriptsList[$ndx][ELEMATTRVAL] \n";
             print "------------------------------------------\n";
          }
        }

        $ndx = 0;
        foreach my $scriptslst (@scriptsList)
        {
          my $scriptrunuser = "";
          my $scriptinterpreter = "";
          my $scriptparameter = "";

         # Get attribute "name"
         ($attrname , $attrval) = tfactlshare_get_attribute(
                      @$scriptslst[ELEMATTRNAME] , @$scriptslst[ELEMATTRVAL],
                      "name" );

          if ( $tfactlglobal_hash{"debugmask"} &
               $tfactlglobal_mod_levels{"tfactlshare_parse_xmlcomp"} ) {
            tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare " .
                             "tfactlshare_parse_xmlcomp AttrName $attrname " .
                             " AttrVal $attrval", 'y', 'y');
          }
          my @scriptDetail = tfactlshare_get_element( \@tagsarray,
                              @$scriptslst[ELEMLEVEL]+1 , 
                              @$scriptslst[ELEMNDX] ); 
          my @allparameters;
          my $ndxparameters = 0;
          foreach my $scriptdet (@scriptDetail)     # script detail
          {
            $name = @$scriptdet[ELEMNAME];
            $value = @$scriptdet[ELEMVAL];

            if ( lc($name) eq "runuser" ) {             # runuser
               $scriptrunuser = $value;
            } elsif ( lc($name) eq "interpreter" ) {    # interpreter
               $scriptinterpreter = $value;
            } elsif ( lc($name) eq "parameter" ) {      # parameter
               $scriptparameter = $value;
               $allparameters[$ndxparameters++] = $scriptparameter;
            }
          } # end foreach scriptDetail

          # Populate script details
          $scriptsarray[$ndx][COMPSCRIPTNAME] = $attrval;        # Script Name
          $scriptsarray[$ndx][COMPSCRIPTRUSER] = $scriptrunuser; # runuser
          $scriptsarray[$ndx][COMPSCRIPTINT] = $scriptinterpreter; # interp.
          $scriptsarray[$ndx][COMPSCRIPTPARAMS] = [@allparameters];  # parameters
          $ndx++;
          if ( $tfactlglobal_hash{"debugmask"} &
               $tfactlglobal_mod_levels{"tfactlshare_parse_xmlcomp"} ) {
            tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare " .
                              "tfactlshare_parse_xmlcomp PARAM $attrval " .
                              "$scriptrunuser $scriptinterpreter",
                              'y', 'y');
          }
        } # end foreach $scriptsList
        # ------------------------------------------------------
      } elsif ( lc($name) eq "also-collects" ) { # also-collects
        my @alsocollectList = tfactlshare_get_element( \@tagsarray,
                                @$compdet[ELEMLEVEL]+1 , 
                                @$compdet[ELEMNDX] );
        $ndx = 0;
        foreach my $alsocompdet (@alsocollectList)
        {
          $name = @$alsocompdet[ELEMNAME];
          $value = @$alsocompdet[ELEMVAL];
          $alsocollectarray[$ndx++] = $value;
          if ( $tfactlglobal_hash{"debugmask"} &
               $tfactlglobal_mod_levels{"tfactlshare_parse_xmlcomp"} ) {
            tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare " .
                            "tfactlshare_parse_xmlcomp ALSOCOLL $name $value",
                            'y', 'y');
          }
        } # end foreach $alsocollectList
      } # end if eq scripts
     } # end foreach componentDetails
     
     if ( $tfactlglobal_hash{"debugmask"} &
          $tfactlglobal_mod_levels{"tfactlshare_parse_xmlcomp"} ) {
       tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare " .
                       "tfactlshare_parse_xmlcomp #####################",
                       'y', 'y');
     }

     # If not running on Cloud then ignore validation component
     if ( (! $ISCLOUD) || $SUPPORTMODE ) {
        if ( $compvalidate eq "true" ) {
          $compvalidate = "ignore";
        } else {
          $compvalidate = "false";
        }
     }


     if ( lc($compname) ne "cell" ) {
        push @xmlcompsarray, [ $compname, $compvalidate, $compaltname, $compdescription,
                               $compinstancehome, [@typesarray], [@subxmlcompsarray],
                               $compconfig, [@scriptsarray],
                               [@alsocollectarray] ];
        $tfactlglobal_xmlcompshash{lc($compname)} = TRUE;
       # Component with additional validation
       if ( defined $compvalidate && lc($compvalidate) eq "true" ) {
         # Get array of subcomponents
         for my $idx ( 0 .. $#subxmlcompsarray ) {
           # Get subcomponents
           my $subxmlcompsarrayref = $subxmlcompsarray[$idx];
           my @subcompsderef = @$subxmlcompsarrayref;

           push @validatexmlcompsarray, [ $compname, $subcompsderef[SUBCOMPIDX],
                                          $subcompsderef[SUBCOMPNAME], 
                                          $subcompsderef[SUBCOMPREQUIRED],
                                          $subcompsderef[SUBCOMPDEFAULT] ];
         } # enf for $#subxmlcompsarray
       } # end if validation component
     }
     undef @alsocollectarray;
     undef @subxmlcompsarray;
     undef @scriptsarray;
     undef $compvalidate;
     undef $compaltname;
     undef $compdescription;
     undef $compinstancehome;
     undef @typesarray;
  } # end foreach componentsList

  return;
}

########
# NAME
#   tfactlshare_get_hash_attributes
#
# DESCRIPTION
#   This function returns a hash containing
#   all the attributes discovered.
#
# PARAMETERS
#   attrnamearrayref , $attrvalarrayref
# RETURNS
#   Hash of attributes
########
sub tfactlshare_get_hash_attributes {
  my $attrnamearrayref = shift;
  my $attrvalarrayref  = shift;
  my $attrname;
  my $attrval;
  my %rethash = ();

  # Deref attrnamearray & attrvalarray
  my @attrnamearrayderef = @$attrnamearrayref;
  my @attrvalarrayderef  = @$attrvalarrayref;

  for my $tmpndx ( 0 .. $#attrnamearrayderef ) {
    $attrname = $attrnamearrayderef[$tmpndx];
    $attrval  = $attrvalarrayderef[$tmpndx];
    $attrval =~ s/\&lt\;/\</g;
    $attrval =~ s/\&gt\;/\>/g;
    $attrval =~ s/\&\#40\;/\(/g;
    $attrval =~ s/\&\#41\;/\)/g;
    $attrval =~ s/\&\#91\;/\[/g;
    $attrval =~ s/\&\#92\;/\\/g;
    $attrval =~ s/\&\#93\;/\]/g;
    $attrval =~ s/\&\#123\;/\{/g;
    $attrval =~ s/\&\#124\;/\|/g;
    $attrval =~ s/\&\#125\;/\}/g;
    $attrval =~ s/\&\#64\;/\@/g;
    if ( not exists $rethash{$attrname} ) { 
      $rethash{$attrname} = $attrval;
    }
  }

return ( %rethash );
}

########
# NAME
#   tfactlshare_get_attribute
#
# DESCRIPTION
#   This function retrieves the
#   attribute
#
# PARAMETERS
#   attrnamearrayref , $attrvalarrayref, $lookfor
# RETURNS
#   attribute name
########
sub tfactlshare_get_attribute {
  my $attrnamearrayref = shift;
  my $attrvalarrayref  = shift;
  my $lookfor          = shift;
  my $attrname;
  my $attrval;

  # Deref attrnamearray & attrvalarray
  my @attrnamearrayderef = @$attrnamearrayref;
  my @attrvalarrayderef   = @$attrvalarrayref;

  for my $tmpndx ( 0 .. $#attrnamearrayderef ) {
    if ( lc($attrnamearrayderef[$tmpndx]) eq lc($lookfor) ) {
      $attrname = $attrnamearrayderef[$tmpndx];
      $attrval  = $attrvalarrayderef[$tmpndx];
      last;
    }
  }

  $attrval =~ s/\&lt\;/\</g;
  $attrval =~ s/\&gt\;/\>/g;
  $attrval =~ s/\&\#40\;/\(/g;
  $attrval =~ s/\&\#41\;/\)/g;
  $attrval =~ s/\&\#91\;/\[/g;
  $attrval =~ s/\&\#92\;/\\/g;
  $attrval =~ s/\&\#93\;/\]/g;
  $attrval =~ s/\&\#123\;/\{/g;
  $attrval =~ s/\&\#124\;/\|/g;
  $attrval =~ s/\&\#125\;/\}/g;
  $attrval =~ s/\&\#64\;/\@/g;

return ( $attrname, $attrval );
}

########
# NAME
#   tfactlshare_dump_xmlcomp
#
# DESCRIPTION
#   This function dumps global array
#   @xmlcompsarray
#
# PARAMETERS
#
# RETURNS
#
########
sub tfactlshare_dump_xmlcomp {
  my $ndx;

  # Navigate thru components
  for $ndx ( 0 .. $#xmlcompsarray ) {
    my $typeref = $xmlcompsarray[$ndx][COMPTYPE];
    my @typesarray = @$typeref;
    print " name $xmlcompsarray[$ndx][COMPNAME] \n";
    print " types array @typesarray\n";
    print " validate config $xmlcompsarray[$ndx][COMPVALIDATE] " .
          "$xmlcompsarray[$ndx][COMPCONFIG] \n";
    print " alt name  $xmlcompsarray[$ndx][COMPALTNAME] \n";
    print " description  $xmlcompsarray[$ndx][COMPDESCRIPTION] \n";
    print " instance home  $xmlcompsarray[$ndx][COMPINSTANCEHOME] \n";

    # Get components
    my $subxmlcompsarrayref = $xmlcompsarray[$ndx][COMPSUB];
    my @subcompsderef = @$subxmlcompsarrayref;
    for my $idx ( 0 .. $#subcompsderef ) {
       my $subcompref = $subcompsderef[$idx];
       my @subcomps = @$subcompref;
       print "subcomps $idx -> @subcomps \n";
    }

    # Get scripts
    my $scriptsarrayref = $xmlcompsarray[$ndx][COMPSCRIPTS];
    my @scriptsderef = @$scriptsarrayref;
    for my $idx ( 0 .. $#scriptsderef ) {
        print "scripts $scriptsderef[$idx][COMPSCRIPTNAME] $scriptsderef[$idx][COMPSCRIPTRUSER] $scriptsderef[$idx][COMPSCRIPTINT]\n";

        # Get parameters if any
        my $scriptsparamsref = $scriptsderef[$idx][COMPSCRIPTPARAMS];
        my @paramsderef = @$scriptsparamsref;
        print "Parameters ";
        for my $idxparam ( 0 .. $#paramsderef ) {
          print " $paramsderef[$idxparam]";
        } # end for @paramsderef
        print "\n";
    } # end for @scriptsderef

    # Get also-collects
    my $alsocollectarrayref = $xmlcompsarray[$ndx][COMPALSO];
    my @alsocollectderef = @$alsocollectarrayref;
    print "also-collect-component @alsocollectderef \n";
    print "------------------------------------\n";

  } # end for @xmlcompsarray navigation

return;
}

########
# NAME
#   tfactlshare_load_srdc_help
#   manuegar_srdc_14
#
# DESCRIPTION
#   This function loads the srdc help
#
# PARAMETERS
#   $tfa_home
#
# RETURNS
#   $SRDCHLPSTRING
########
sub tfactlshare_load_srdc_help {
  my $tfa_home = shift;
  my $resdir = catfile($tfa_home,"resources");
  my $desc;
  my $id;
  my @srdcs;
  my %helpinfo;
  $SRDCHLPSTRING = "";

  # print "resdir $resdir\n";
  @srdcs = osutils_getRecursiveFolderContents($resdir);
  @srdcs = grep{/srdc_.*\.xml/i} @srdcs;
  # print "srdcs @srdcs\n";
  @srdcs = sort { $a <=> $b } @srdcs;
  foreach my $srdcfile ( @srdcs ) {
    # print "srdcfile $srdcfile\n";
    open(my $fh, '<', $srdcfile) or die "Could not open file $srdcfile";
    while (<$fh>) {
       chomp $_;
       if ( $_ =~ /.*\<collection\s+id\s*\=\s*\"(.*)\"\s*\>/ ) {
         $id = $1;
       } elsif ( $_ =~ /.*\<description\>(.*)\<\/description\>/ ) {
         $desc = $1;
       }
    } # end while
    # print "desc     $desc\n";
    # print "id       $id\n";
    $helpinfo{$id} = $desc;
  } # end if foreach
  foreach my $srdcid (sort keys %helpinfo) {
    $SRDCHLPSTRING .= sprintf("    %-20s %-50s",$srdcid,$helpinfo{$srdcid}) . "\n";
  }
  return;
}

########
# NAME
#   tfactlshare_load_xmlcomp
#
# DESCRIPTION
#   This function loads xml components
#   @xmlcompsarray 
#
# PARAMETERS
#   $tfa_home
#
# RETURNS
#   Array of dynamic components,
#   @retcomparray 
#       [ RETCOMPNAME, RETCOMPTYPE, RETCOMPCONFIG, RETCOMPVALIDATE ] 
########
sub tfactlshare_load_xmlcomp {
  my $tfa_home = shift;
  undef @retcomparray;
  my $ndx = 0;

  my $addcompstring            = "";
  my $addcomphlpstring         = "";
  my $addcomphlpdesc           = "";

  my $addcompstring_exadata    = "";
  my $addcomphlpstring_exadata = "";
  my $addcomphlpdesc_exadata   = ""; 

  my $addcompstring_oda        = "";
  my $addcomphlpstring_oda     = "";
  my $addcomphlpdesc_oda       = "";

  my $addcompstring_racdbcloud        = "";
  my $addcomphlpstring_racdbcloud     = "";
  my $addcomphlpdesc_racdbcloud       = "";

  # Also-collects  
  for my $ndx ( 0 .. $#xmlcompsarray ) {
    #print "comptype " . $xmlcompsarray[$ndx][COMPTYPE] . "\n";
    my $compname = lc($xmlcompsarray[$ndx][COMPNAME]);
    my $compdescription = $xmlcompsarray[$ndx][COMPDESCRIPTION];
    my $typeref = $xmlcompsarray[$ndx][COMPTYPE];
    my @typesarray = @$typeref;
    my $compconfig = lc($xmlcompsarray[$ndx][COMPCONFIG]);
    my $compvalidate = lc($xmlcompsarray[$ndx][COMPVALIDATE]);

    my %typehash = map { $_ => 1 } @typesarray;
        
    foreach my $key ( keys %typehash ) {
      #print "compname $compname Key $key \n";
    }
    # Additional components, type=collection & config=all
    if ( (exists $typehash{"collection"} || exists $typehash{"action"} ) &&
         $compname ne "asmio" && $compname ne "asmproxy" &&
         $compname ne "exadata" && $compname ne "computenode" &&
         $compname ne "cell"  && $compname ne "chmos" ) {

      if ( $tfactlglobal_hash{"debugmask"} &
           $tfactlglobal_mod_levels{"tfactlshare_load_xmlcomp"} ) {
        tfactlshare_trace(5, "tfactl (PID = $$) " .
                         "tfactlshare_load_xmlcomp " .
                         "Looping through xmlcompsarray, " .
                         "compname $compname compvalidate $compvalidate", 'y', 'y');
      }

      # Validata availability for the component in the
      # current platform
      if ( $compconfig eq "exadata" ) {        # EXADATA
        $addcomphlpstring_exadata .= " or -" . $compname;
        $addcompstring_exadata    .= " -" . $compname;
        $addcomphlpdesc_exadata   .= sprintf("%-11s  Collect $compdescription\n",
                                             "  -$compname");
      } elsif ( $compconfig eq "racdbcloud" ) {       # RACDBCLOUD
        $addcomphlpstring_racdbcloud .= " or -" . $compname;
        $addcompstring_racdbcloud    .= " -" . $compname;
        $addcomphlpdesc_racdbcloud   .= sprintf("%-11s  Collect $compdescription\n",
                                         "  -$compname");
      } elsif ( $compconfig eq "oda" ) {       # ODA
        $addcomphlpstring_oda .= " or -" . $compname;
        $addcompstring_oda    .= " -" . $compname;
        $addcomphlpdesc_oda   .= sprintf("%-11s  Collect $compdescription\n",
                                         "  -$compname");
      } elsif ( $compconfig eq "all" ) {       # ALL 
        ###$addcomphlpstring .= " or -" . $compname;
        ###$addcompstring    .= " -" . $compname;
        if ( $ISCLOUD && (not $SUPPORTMODE) ) {
          if ( defined $compvalidate && $compvalidate eq "true" ) {
            $addcomphlpdesc   .= sprintf("%-11s  Collect $compdescription\n",
                                         "  -$compname");    
            $addcomphlpstring .= " or -" . $compname;
            $addcompstring    .= " -" . $compname;
          }
        } else {
          if ( defined $compvalidate && $compvalidate eq "false" ) {
            $addcomphlpdesc   .= sprintf("%-11s  Collect $compdescription\n",
                                         "  -$compname");
            $addcomphlpstring .= " or -" . $compname;
            $addcompstring    .= " -" . $compname;
          }
        } # end if isTFAOnCloud
      }
      $addcomphlpdesc =~ s/-rdbms/-database/g;

      # Populate return array
      push @retcomparray, [ $compname , [@typesarray], $compconfig, $compvalidate ]; 

      if ( $tfactlglobal_hash{"debugmask"} &
           $tfactlglobal_mod_levels{"tfactlshare_load_xmlcomp"} ) {
        tfactlshare_trace(5, "tfactl (PID = $$) " .
                        "tfactlshare_load_xmlcomp " .
                        "Add comp list $compname @typesarray $compconfig",
                        'y', 'y');
      }
    } # End if, Additional components
  } # end for @xmlcompsarray

  $ADDCOMPSTRING            = $addcompstring;
  $ADDCOMPHLPSTRING         = $addcomphlpstring;
  $ADDCOMPHLPDESC           = $addcomphlpdesc;
  $ADDCOMPSTRING_EXADATA    = $addcompstring_exadata;
  $ADDCOMPHLPSTRING_EXADATA = $addcomphlpstring_exadata;
  $ADDCOMPHLPDESC_EXADATA   = $addcomphlpdesc_exadata;
  $ADDCOMPSTRING_ODA        = $addcompstring_oda;
  $ADDCOMPHLPSTRING_ODA     = $addcomphlpstring_oda;
  $ADDCOMPHLPDESC_ODA       = $addcomphlpdesc_oda;
  $ADDCOMPSTRING_RACDBCLOUD        = $addcompstring_racdbcloud;
  $ADDCOMPHLPSTRING_RACDBCLOUD     = $addcomphlpstring_racdbcloud;
  $ADDCOMPHLPDESC_RACDBCLOUD       = $addcomphlpdesc_racdbcloud;

  if ( $tfactlglobal_hash{"debugmask"} &
       $tfactlglobal_mod_levels{"tfactlshare_load_xmlcomp"} ) {
    print "\n\n tfactlshare_load_xmlcomp retcomparray \n\n";
    for $ndx ( 0 .. $#retcomparray ) {
      my $typesref = $retcomparray[$ndx][RETCOMPTYPE];
      my @typesarray = @$typesref;
      print "$ndx: $retcomparray[$ndx][RETCOMPNAME] @typesarray $retcomparray[$ndx][RETCOMPCONFIG] \n";
    }
  }

}

########
# NAME
#   tfactlshare_read_ext_xml
# 
# DESCRIPTION
#   This function reads the ext tools configuration file
#
# PARAMETERS
#   $tfa_home        (IN) - TFA Home
#   $tfa_ext_xml     (IN) - configuration file
#   
# RETURNS
#   %tools
#
########
sub tfactlshare_read_ext_xml
{
  my $tfa_home = shift;
  my $tfa_ext_xml = shift;
  my %tools = ();
  my @toolstagsarray;
  my $attrname;
  my $toolname;
  my $toolversion;
  my $toolbuildid;
  my $toolaliases;
  my $toolplatforms;
  my $toolclusterwide;
  my $toolautostart;
  my $toolneedinv;
  my $tooltype;
  my $name;
  my $value;

  if ( -e "$tfa_ext_xml" )
  {

    # Parse xml file
    @toolstagsarray = tfactlshare_populate_tagsarray($tfa_ext_xml);

    # Parse tools 
    my @toolsList = tfactlshare_get_element(\@toolstagsarray, 1,0);

    foreach my $child (@toolsList)
    {
      # Get component
      my $name = @$child[ELEMNAME];
      # Get attributes
      ($attrname , $toolname) = tfactlshare_get_attribute(
                   @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL],
                   "name" );
      ($attrname , $toolversion) = tfactlshare_get_attribute(
                   @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL],
                   "version" );
      ($attrname , $toolbuildid) = tfactlshare_get_attribute(
                   @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL],
                   "buildid" );
      ($attrname , $toolaliases) = tfactlshare_get_attribute(
                   @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL],
                   "aliases" );
      ($attrname , $toolplatforms) = tfactlshare_get_attribute(
                   @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL],
                   "platforms" );

      if ( $tfactlglobal_hash{"debugmask"} &
           $tfactlglobal_mod_levels{"tfactlshare_read_ext_xml"} ) {
        tfactlshare_trace(5, "tfactl (PID = $$) " .
                          "tfactlshare_read_ext_xml " .
                          "Name $name $toolname $toolversion $toolbuildid",
                          'y', 'y');
      }
      if ( $tfactlglobal_hash{"debugmask"} &
           $tfactlglobal_mod_levels{"tfactlshare_read_ext_xml"} ) {
        tfactlshare_trace(5, "tfactl (PID = $$) " .
                        "tfactlshare_read_ext_xml " .
                        "Level " . @$child[ELEMLEVEL] . " Ndx " .
                        @$child[ELEMNDX], 'y', 'y');
      }

      # Validate that the tool exists
      my $tool_pm = catfile($tfa_home, "ext", $toolname, "$toolname.pm");
      if ( -e "$tool_pm" )
      {
        # Defaults
        $toolclusterwide = "false";

        # Get details about the tool
        my @toolDetails = tfactlshare_get_element( \@toolstagsarray,
                                @$child[ELEMLEVEL]+1 , @$child[ELEMNDX] );
        foreach my $tooldet (@toolDetails)
        {
          $name = @$tooldet[ELEMNAME];
          $value = @$tooldet[ELEMVAL];
          $tooltype='other tools';

          # ------------------------------------------------------
          if ( lc($name) eq "clusterwide" ) {                # clusterwide
            $toolclusterwide = lc($value);
          # ------------------------------------------------------
          } elsif ( lc($name) eq "autostart" ) {             # autostart
            $toolautostart = lc($value);
          # ------------------------------------------------------
          }
	  elsif ( lc($name) eq "needinventory" ) {
	    $toolneedinv = lc($value);
          }
          elsif ( lc($name) eq "tooltype" ) {
            $tooltype = lc($value);
            if ( not exists $tfactlglobal_exttools_categories{$tooltype} ) {
              $tfactlglobal_exttools_categories{$tooltype} = trim($tooltype);
            }
          }

          if(tfactlshare_check_platform_compatibility($toolplatforms,$toolname)){
                        $tools{$toolname}->{BASENAME} = $toolname;           # tool base name
			$tools{$toolname}->{VERSION} = $toolversion;         # tool version
			$tools{$toolname}->{ID} = $toolbuildid;              # tool buildid
			$tools{$toolname}->{UPDATE} = 1;                     # update
			$tools{$toolname}->{CLUSTERWIDE} = $toolclusterwide; # clusterwide
			$tools{$toolname}->{AUTOSTART} = $toolautostart;     # autostart
			$tools{$toolname}->{NEEDINVENTORY} = $toolneedinv;   # tool need inventory
			$tools{$toolname}->{ALIASES} = $toolaliases;		 # tool aliases
			$tools{$toolname}->{PLATFORMS} = $toolplatforms;     # tool platforms
                        $tools{$toolname}->{TOOLTYPE} = $tooltype;           # tool Type
          }
          
        } # end foreach @toolDetails
      } # endif -e $tool_pm

    } # end foreach @toolsList
  } # end if exists $tfa_ext_xml

  return %tools;
}

########
# NAME
#   tfactlshare_manage_ext
# 
# DESCRIPTION
#   This function manages ext tools
#
# PARAMETERS
#   command     (IN) - deploy/run
#   
# RETURNS
#   Null.
#
# NOTES
#   This routine calls the callbacks from each module to display the 
#   correct syntax for $command.
########
sub tfactlshare_manage_ext
{
  my ($cmd) = shift;
  my ($tool) = shift;
  my ($tfa_home) = shift;
  my (@args) = @_;
  my $retval;
  my @hosts = ();
  my $localnode = ();
  my $nodelist = "";
  my @nodelist = ();
  my $cpid = $$;
  my %nonwindowstools = ( "exachk",TRUE,
                          "orachk",TRUE,
                          "oratop",TRUE,
                          "oswbb" ,TRUE,
                          "prw"   ,TRUE,
                          "sqlt"  ,TRUE,
                          "tail"  ,TRUE );
  my $consolidated_output = 0;
  my $current_time = tfactlshare_get_time();
  my $driverhost; 
  my $summary_silent;
  my $view;
  my $recoverhostctx = FALSE;
  my $bkphostctx = "";
  if (lc($cmd) eq "run" && $tool eq "exachk" && ! (isExadataDom0() || isExadata())){
     print "exachk is only supported on Exadata systems.Please run orachk.\n";
     exit 1;
  } elsif (lc($cmd) eq "run" and $tool eq "dbcheck" && !(isExadataDom0() || isExadata())) {
    if ( not (isExadataDom0() || isExadata())){
      print "\nERROR: dbhceck is only supported on Exadata Systems\n";
      exit 1;
    } elsif ( $current_user ne "root"){
      print "ERROR: TFA dbcheck must be run as root user\n";
      exit 1;
    }
  } elsif(lc($cmd) eq "run" and $tool eq "summary"){
  	my $username = tfactlshare_getUserName();
	if (lc($username) ne "root") {
		print "ERROR: TFA Summary must be run as root user\n";
                exit 1;
	}
    if(grep(/^\-history$/ , @args )){
      my $arg_str = join " ", @args;
      #print "ARGS: $arg_str\n";
      if ($#args > 0) {
      	if ($arg_str !~ /-help(\s|$)|-h(\s|$)/) {
      		print "[ERROR] Invalid Combination of Flags\n";
                exit 1;
      	} else {
      		@args = grep(!/-history/, @args);
      	}
      } else {
		my @tmp_args = @args;
		$view = 10; # default
		while(1) { 
			if(shift @tmp_args eq "-history"){ $view = shift @tmp_args; last;}
		}  
		$view =10 if ( $view !~ /^[0-9,.E]+$/ or $view < 0);
	  }
    }
    $driverhost = 1 if(grep(/-driverhost/ , @args ));
    $summary_silent = 1 if(grep(/-silent/ , @args ));
    push(@args,"-consolidated") if(!grep(/-consolidated/ , @args ));
    $SUMMARY_NODE_LIST_REF = \@hosts;

    if(!defined $driverhost){
      $SUMMARY_TIME_PROFILE_HREF->{'TOOL'}->{'SUMMARY'}->{'START'} = time;
      $consolidated_output = 1;
      my $dir_tfa_base = tfactlshare_get_repository_location($tfa_home);
      
      if(defined $view){
        my $tool_base = catfile($dir_tfa_base, "suptools", "$hostname", $tool,$current_user);
        opendir(DIR,"$tool_base");
        my @files = grep ! /^\./, readdir DIR;
        my $rep_count = 1;
        my %dir_list;
        @files = reverse sort @files;
        @files = @files[0..$view-1];  
        for my $file (@files) {
          next if($file eq "" or $file =~ /\D/);  
          my $dir_path = catfile($tool_base,$file);
          next if(!-d $dir_path);
          print "\nList of Existing Summary Collection : \n" if($rep_count == 1);
          print "    $rep_count => $file\n";
          $dir_list{$rep_count} = "$file";  
          $rep_count++;
        }
        closedir(DIR);
        my $size = keys %dir_list;
        if($size == 0){
          print "\n[ERROR] Summary Collections Not found for View\n\n"; 
          exit 1;
        }  
        my $input_command = 0;
        print "\n";
        while(!exists $dir_list{$input_command}){
          print "Please Select Collection To View [or q to quit]: ";
          $input_command = <STDIN>;
          chomp($input_command);
          $input_command =~ s/^\s+|\s+$//g;
          exit 0 if($input_command =~ m/^(q|quit)$/);   
          next if($input_command eq ""); 
          if($input_command <= 0 or $input_command >= $rep_count){
            print "  [ERROR] Collection Time Stamp Not Found,Please select again..\n\n";
          } 
        }
        print "Time Stamp Selected : $dir_list{$input_command}\n";
        $current_time = $dir_list{$input_command};
         
        push(@args,"-history");
        push(@args,"$view");
      } else {
        my $dir_base = catfile($dir_tfa_base, "suptools", "$hostname", $tool,$current_user,$current_time);
        my $summary_tmp_dir = catfile($dir_tfa_base, "suptools", "$hostname", $tool,$current_user,$current_time,"temp");
        eval { tfactlshare_mkpath("$dir_base", "1740") if ( ! -d "$dir_base" );  };
        if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $dir_base","tfactlshare",1 ); }
        eval { tfactlshare_mkpath("$summary_tmp_dir", "1740") if ( ! -d "$summary_tmp_dir" );  };
        if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $summary_tmp_dir","tfactlshare",1 ); }
      }
      push(@args,"-time");
      push(@args,"$current_time");
      push(@args,"-driverhost");
      push(@args,"$hostname");
    } 
  } elsif ( lc($cmd) eq "run" and $tool eq "param" ){
    #Search for -host switch to add it to the context.  
     my $host;
     my $db;
     my $inst;
     my @bkp_argv = @ARGV;
     my @bkp_args = @args;
     shift(@args);#This should be the param name, so ignore it.
     @ARGV = @args;
     GetOptions (
       'host=s' => \$host,
       'db=s' => \$db,
       'database=s' =>\$db,
       'inst=s' =>\$inst
     ) or die ("Unknown option");
     if ( $host ){
       if ( $host ne $hostname ){
         my @listOfNodes = getListOfOtherNodes ( $tfa_home );
         if ( scalar(@listOfNodes) > 0 ) {
           if (! ( grep { /$host/ } @listOfNodes ) ){
             print "Error: Failed to find $host\n";
             return 2;
           }
         } else {
           print "Error: Failed to find host $host\n";
           return 2;
         }
       }
       #If we have a current host context and we provide a
       #-host switch give priority to the switch
       #save the current host context  and set up the new one
       if ( $tfactlglobal_ctx{"host"} ){
          $bkphostctx = $tfactlglobal_ctx{"host"}; 
       }
      $tfactlglobal_ctx{"host"} = $host;
      $recoverhostctx = TRUE;
     }
     #Recover args and continue with normal execution
     @ARGV = @bkp_argv;
     @args = @bkp_args;
  }
  # Disable de execution of %nonwindowstools on Windows
  if ( $IS_WINDOWS && lc($cmd) eq "run" && exists $nonwindowstools{$tool} ) {
    print_help("run");
    return;
  }

  #Most of the tools are depending on inventory file. So make sure that atleast 
  #inventory happened first time before running the tools. If not, do run inventory
  if ( $tfactlglobal_exttools{$tool}->{NEEDINVENTORY} eq "true" && 
       ! tfactlshare_isInventoryRunOnce($tfa_home) )  {
    print "The tool $tool requires initial inventory run\n";
    runTFAInventory($tfa_home,1,0);
    print "It is recommended to run the tool $tool after completing inventory\n";
    exit 1;
  }
  my $run_clusterwide = 1;
  if ( $args[0] eq "-remotetfarun" )
  {
    $run_clusterwide = 0;
    splice @args, 0, 1;
    $ENV{"TFA_REMOTE_RUN"} = 1;
    my $tfagctx = "";
    my $g = 0;
    foreach my $a (@args)
    {
      if ( $a eq "-tfagctx" )
      {
        $tfagctx = ";";
      }
       elsif ( $tfagctx )
      {
        $tfagctx .= " $a";
      }
       else 
      {
        $g++;
      }
    }
    if ( $tfagctx )
    {
      splice @args, $g;
    }
    if ( $tfagctx )
    {
      my @tmp = split(".TFASEP.", $tfagctx);
      foreach my $tmp (@tmp)
      {
        if ( $tmp =~ /([\w\-]+)=(.*)/ )
        {
          my $key = $1;
          my $val = $2;
          $val =~ s/.COLON./:/g;
          if ( $key eq "current_user" )
          {
          	if(!$IS_WINDOWS){
      			my $uid   = getpwnam($val);
	            if ( $uid > 0 && $current_user eq "root" )
	            {
	              $> = $uid;
	            }
      		}
          }
           elsif ( $key ne "tfa-outloc" && $key ne "tfa-repos" )
          {
            $tfactlglobal_ctx{$key} = $val;
          }
        }
      }
    }
  }

  if ( $tfactlglobal_exttools{$tool}->{CLUSTERWIDE} ne "true" )
  { # Dont run clusterwide
    $run_clusterwide = 0;
  }
  if ( $cmd eq "start" || $cmd eq "stop" || $cmd eq "status" )
  {
    $run_clusterwide = 0;
  }

  if ( $cmd eq "runstatus" || $cmd eq "autostart" )
  {
    $run_clusterwide = 0;
  }

  my $oswbb_start_stop_run_clusterwide = 0;
  # -c => clusterwide start/stop support for oswbb
  if (($tool eq "oswbb") and (map {m/^-c$/i} @args) and (($cmd eq "start") || ($cmd eq "stop"))){ 
    @args = grep { $_ ne '-c' } @args;
    $oswbb_start_stop_run_clusterwide = 1;
    print "Run Clusterwide Enabled : tfactl $cmd $tool @args\n";
  }

  # Start running in local node
  tfactlshare_trace(5, "tfactl (PID = $$) " .
                    "tfactlshare_manage_ext " .
                    "CMD $cmd TOOL $tool TFAHOME $tfa_home ARGS @args",
                    'y', 'y');

  if ( exists $tfactlglobal_exttools{$tool} )
  {
    if ( $cmd eq "run"  || $cmd eq "deploy" || $cmd eq "start" )
    {
      tfactlshare_setup_tool_dir($tfa_home, $tool);
    }

    my @runhosts = ();
    if ( defined $tfactlglobal_ctx{"host"} )
    {
      @runhosts = split(",", $tfactlglobal_ctx{"host"});
    }
    my $tfagctx = "";
    # First send the command to all nodes in cluster
    if (($run_clusterwide == 1) or ($oswbb_start_stop_run_clusterwide == 1))
    {
      my @rargs = ();
      my $capture_nodelist = 0;
      foreach my $rarg (@args)
      {
      	if($rarg eq "-node"){
      		$capture_nodelist = 1;
      		next;
      	}
      	if($capture_nodelist) {
          if ( $rarg !~ /^\-/ ) { #If argument starts with - assume is a switch
            $nodelist = $rarg;
          } else {
            print "\n[ERROR] Node name or list of nodes is required for -node\n\n";
            exit 1;
          }
      		$capture_nodelist = 0;
      		next;
      	}
        if ( $rarg =~ /\s/ )
        {
          $rarg =~ s/\s/.SPACE./g;
        }
        push(@rargs, $rarg);
      }

      # Serialize global context
      $tfagctx = "-tfagctx current_user=$current_user";
      foreach my $tmp (keys %tfactlglobal_ctx)
      {
        $tfagctx = "-tfagctx " if ( ! $tfagctx );
        my $val = $tfactlglobal_ctx{$tmp};
        $val =~ s/\:/.COLON./g; # TFA MessageHandler splits by colon
        $tfagctx .= ".TFASEP.$tmp=$val";
      }
      if ( defined $tfactlglobal_ctx{"tfa-nodes"} )
      {
        @hosts = split(".TFANSEP.", $tfactlglobal_ctx{"tfa-nodes"});
        $localnode = $tfactlglobal_ctx{"tfa-localnode"};
      }
       else
      {
        @hosts = getListOfAllNodes($tfa_home);
        $localnode = tolower_host();
        $tfactlglobal_ctx{"tfa-nodes"} = join(".TFANSEP.", @hosts);
        $tfactlglobal_ctx{"tfa-localnode"} = $localnode;
      }
      # If nodelist is provided remove nodes not present in nodelist
      # Node list passed as args
      if ($nodelist ne "") {
      	$nodelist =~ tr/A-Z/a-z/;
      	$nodelist = trim($nodelist);
      	if((lc($nodelist) eq "all") || ($nodelist eq "")){
      		# Allow clusterwide to continue
      	}elsif(lc($nodelist) eq "local"){
      		# Clear @hosts and add local hostname
      		@hosts = ();
      		push(@hosts, tolower_host());
      	}else{
      		@nodelist = split(/\,/,$nodelist);
		    my %hosts=map{lc($_) =>1} @hosts;
			my %nodelist=map{lc($_) =>1} @nodelist;

			foreach my $node (@nodelist){
				if (! exists $hosts{lc($node)} ) {
 					print "\n[ERROR] Node \'$node\' is not part of TFA cluster\n\n";
				}
			}

			# the intersection of @nodelist and @hosts:
			@hosts = grep( $hosts{$_}, @nodelist );
      	}
      }
      $localnode = tolower_host() if ( ! $localnode );
      my $tfacmd = catfile ($tfa_home, "bin", "tfactl");
      foreach my $host (@hosts)
      {
        #print "Running on $host\n";
        if ( $host ne $localnode )
        {
          my $pid;
         # copyTagFile($tfa_home,"summaryfile-FILE-profile.xml-USER-${current_user}-TIME-${current_time}",$host) if(grep(/-profile/ , @args ));
          if ( ! $tfactlglobal_ctx{"host"} ||
              grep { lc($_) eq lc($host) } @runhosts
              )
          {
            next if $pid = fork;
            die "fork failed: $!" unless defined $pid;
            if($IS_WINDOWS && !(-d $TMP)){
            	mkdir($TMP);
            }
                         
            if($oswbb_start_stop_run_clusterwide == 1){
              my $tfa_base = $tfa_home;
              my $remote_home;
              my $temp_log_loc = catfile($TMP,"$host.$cpid.out");
              $tfa_base =~ s/(\/||\\)$localhost(\/||\\)tfa_home// if ( $tfa_base =~ /(\/||\\)$localhost(\/||\\)tfa_home/ );
              $remote_home = catdir($tfa_base,$host,"tfa_home","bin","tfactl");
              system("$tfacmd executecommand $host \"$remote_home $cmd $tool @args > $temp_log_loc \"");
            } else {  
              if(lc($cmd) eq "run" and $tool eq "summary") {
                push(@rargs, "-silent");
                push(@rargs, "-json")
              } elsif(lc($cmd) eq "run" and $tool eq "search") {
              	for(my $i = 0; $i <= $#rargs; $i++) {
              		if ($rargs[$i] =~ /-json/) {
              			$rargs[$i+1] =~ s/\"/\\\\\\\"/g;              			
              			$rargs[$i+1] =~ s/{/\\{/g;            			
              			$rargs[$i+1] =~ s/}/\\}/g;
              			$rargs[$i+1] = "'\"" . $rargs[$i+1] . "\"'";
              		}
              	}
              }
	      #print("$tfacmd executecommandprint $host tfactlruntool $tool -remotetfarun @rargs $tfagctx > ".catfile($TMP,"$host.$cpid.out")." 2>&1");
	      system("$tfacmd executecommandprint $host tfactlruntool $tool -remotetfarun @rargs $tfagctx > ".catfile($TMP,"$host.$cpid.out")." 2>&1");
            }
            exit;
          }
        }
      }
    }

    my @rargs = ();
	my $capture_nodelist = 0;
	foreach my $rarg (@args)
	{
		if($rarg eq "-node"){
			$capture_nodelist = 1;
			next;
		}
		if($capture_nodelist) {
      if ( $rarg !~ /^\-/ ) { #If argument starts with - assume is a switch
        $nodelist = $rarg;
      } else {
        print "\n[ERROR] Node name or list of nodes is required for -node\n\n";
        exit 1;
      }
			$capture_nodelist = 0;
			next;
		}
	if ( $rarg =~ /\s/ )
	{
	  $rarg =~ s/\s/.SPACE./g;
	}
	push(@rargs, $rarg);
	}

	@args = @rargs;

    # If nodelist is provided remove nodes not present in nodelist
	# Node list passed as args
	my $is_localhost_in_nodelist = 1;
	if ($nodelist ne "") {
		$nodelist =~ tr/A-Z/a-z/;
		$nodelist = trim($nodelist);
		if((lc($nodelist) eq "all") || ($nodelist eq "")){
      		# Allow clusterwide to continue
      	}elsif(lc($nodelist) eq "local"){
      		# Clear @hosts and add local hostname
      		@hosts = ();
      		push(@hosts, tolower_host());
      	}else{
      		@nodelist = split(/\,/,$nodelist);
			my %hosts=map{lc($_) =>1} @hosts;
			my %nodelist=map{lc($_) =>1} @nodelist;

			if (exists $nodelist{lc($localnode)}) {
			    $is_localhost_in_nodelist = 1;
			} else {
			    $is_localhost_in_nodelist = 0;
			}

			# the intersection of @nodelist and @hosts:
			@hosts = grep( $hosts{$_}, @nodelist );
      	}
	}

    if ( ($is_localhost_in_nodelist || ($run_clusterwide == 0)) && ($run_clusterwide == 0 || ! $tfactlglobal_ctx{"host"} ||
              grep { lc($_) eq lc($localnode) } @runhosts)
        )
    {
      # Run on local node
      $tool = $tfactlglobal_exttools{$tool}->{BASENAME};
      # Validate tool pm
      my $tool_pm = catfile($tfa_home, "ext", $tool, "$tool.pm");
      if ( -e "$tool_pm" )
      {
        unshift(@INC,catdir($tfa_home,"ext","$tool"));
      }

      ### print "about to run $tool \n";
      eval "use $tool";

      if ( $@ ) {
         tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_manage_ext " .
                      "Loading $tool from $tfa_home, Errors : $@",
                      'y', 'y');
      }
      my %options = ( run       => \&run,
                    runstatus => \&runstatus,
                    deploy    => \&deploy,
                    start     => \&start,
                    stop      => \&stop,
                    status    => \&status);

      tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_manage_ext " .
                      "Running $cmd for $tool in $tfa_home, args=@args",
                      'y', 'y');

      if (($consolidated_output == 0 ) and ($run_clusterwide == 1) or ($oswbb_start_stop_run_clusterwide == 1))
      {
        print "\n\nOutput from host : $localnode\n";
        print "------------------------------\n";
      }

      my $helprequest = grep( /^-h(elp$|$)/, @args);
      #print "helpreq:$helprequest\n";

      if ( $helprequest and $tool eq "summary" ) {
           s/^-h$/-help/ for @args; #summary does not support -h ...
      }

      if(lc($cmd) eq "run" and $tool eq "summary" and $#hosts != 0 and !defined $view and !$helprequest){
        print "\n";
        print "  Executing Summary in Parallel on Following Nodes: \n";
        foreach my $host (@hosts){ 
          print "    Node : $host\n";
        }
        print "\n";
      }        
      $retval = $options{$cmd}($tfa_home, @args);
    }

    if (($run_clusterwide == 1) or ($oswbb_start_stop_run_clusterwide == 1))
    { 
      1 while (wait() != -1);
      foreach my $host (@hosts)
      {

        if ( $host ne $localnode )
        {
          if ( ! $tfactlglobal_ctx{"host"} ||
              grep { lc($_) eq lc($host) } @runhosts
              )
          {
            if ( $retval == 2 )
            { #print help
              system("$RM ".catfile($TMP,"$host.$cpid.out"));
            }
             else
            {

              if(lc($cmd) eq "run" and $consolidated_output == 1 and $tool eq "summary"){
                my $tfa_base = tfactlshare_get_repository_location($tfa_home);
                my $dep_hash_repository_loc = catfile($SUMMARY_REPOSITORY,"summaryfile-${host}.hash");
                my $dep_hashref;
                if(!defined $view){   
                  print "  - Data Collection From Node - $host .. ";
                  sleep(5);   
                  if(-e $dep_hash_repository_loc and !-z $dep_hash_repository_loc){
                    $dep_hashref = tfactlstore_retrieve_json_to_hash($dep_hash_repository_loc);
                    $SUMMARY_REMOTE_DATA_REF->{$host} = $dep_hashref;
                  }
                  if($IS_WINDOWS){
                    system("$RM /Q /F ".catfile($TMP,"$host.$cpid.out"));
                  }else{
                    system("$RM -f ".catfile($TMP,"$host.$cpid.out"));
                  }
                  print "Done.\n";
                } else {
                  if(-e $dep_hash_repository_loc and !-z $dep_hash_repository_loc){
                    $dep_hashref = tfactlstore_retrieve_json_to_hash($dep_hash_repository_loc);
                    $SUMMARY_REMOTE_DATA_REF->{$host} = $dep_hashref;
                  }
                }
              } else {
                print "\n\nOutput from host : $host\n";
                print "------------------------------\n";
                if($IS_WINDOWS){
                  system("$CAT ".catfile($TMP,"$host.$cpid.out")."\& $RM /Q /F ".catfile($TMP,"$host.$cpid.out"));
                }else{
                  system("$CAT ".catfile($TMP,"$host.$cpid.out")."; $RM -f ".catfile($TMP,"$host.$cpid.out"));
                }
              }
            }
          }
        }
      }
    }

    #=========================tfactl param section===================
    #Recover host context if necessary
    undef $tfactlglobal_ctx{"host"} if ( $recoverhostctx );
    $tfactlglobal_ctx{"host"} = $bkphostctx  if ( $bkphostctx );
    #================================================================

    if(lc($cmd) eq "run" and $consolidated_output == 1 and $retval != 2 ){
      if($tool eq "summary" and defined $SUMMARY_REPOSITORY){
        my $complete_overview = $SUMMARY_OVERVIEW_TYPE;
        my $REPOSITORY = catfile($SUMMARY_REPOSITORY,"$hostname");
        if(!defined $view){
          print "\n  Prepare Clusterwide Summary Overview ... ";
          my @comp_order = ();
          foreach my $comp (@{$SUMMARY_COMPONENT_ORDER_REF}) {
          	next if ($comp eq "overview");
          	push @comp_order, $comp;
          }
          push @comp_order, "overview";
          my $local_compoment_order = \@comp_order;

          # tfasimplerep
          print "\n=====> [tfactlshare_manage_ext] comp_order array @comp_order\n" if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} );

          foreach my $component ( grep { exists $SUMMARY_COMPONENTS_REF->{$_} } @{$local_compoment_order}){
            next if ($SUMMARY_COMPONENTS_REF->{$component} != 1);
            $component = $component."overview" if ( $component ne "overview");
            next if ( $component eq "overviewoverview");
            my $hashdatadir = catfile("$REPOSITORY","hashdata",$component);
            my $datadir = catfile("$REPOSITORY","data",$component);
            my $reportdir = catfile("$REPOSITORY","report",$component);
            eval { tfactlshare_mkpath("$hashdatadir", "1740") if ( ! -d "$hashdatadir" );  };
            if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $hashdatadir","tfactlshare",1 ); }
            eval { tfactlshare_mkpath("$datadir", "1740") if ( ! -d "$datadir" );  };
            if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $datadir","tfactlshare",1 ); }
            eval { tfactlshare_mkpath("$reportdir", "1740") if ( ! -d "$reportdir" );  };
            if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $reportdir","tfactlshare",1 ); }

            print "    - Preparing ".uc($component)." Summary ... \n" if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} );
            my @command_array;
            foreach my $command ( keys %{$SUMMARY_PROFILE_HASHREF->{$component}} ){
              push(@command_array,$command);
            }

            # tfasimplerep
            print "=====> [tfactlshare_manage_ext] command_array: @command_array\n" if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} );

            summaryinterface_execute_profile_normal($tfa_home, \@command_array, $component, $REPOSITORY,$SUMMARY_PROFILE_HASHREF);
            summaryinterface_process_collection($component, $REPOSITORY, $SUMMARY_PROFILE_HASHREF, $SUMMARY_REPORTTYPE,$hostname,\@command_array,$complete_overview);
            #print "Done\n";
          }
          print "Done\n";

          my $COMPLETE_SUMMARY_COMPONENTS_REF;
          foreach my $component ( keys %{$SUMMARY_COMPONENTS_REF}){
            if($SUMMARY_COMPONENTS_REF->{$component} == 1){
              $COMPLETE_SUMMARY_COMPONENTS_REF->{$component} = 1;
              next if($component eq "overview");
              $COMPLETE_SUMMARY_COMPONENTS_REF->{"${component}overview"} = 1;  
            }
          }
          summaryinterface_consolidated_collection_reports($tfa_home, $SUMMARY_TIME, $REPOSITORY, $SUMMARY_REPORTTYPE,$COMPLETE_SUMMARY_COMPONENTS_REF);
          sumreport_create_console_report_consolidated_forall_nodes($tfa_home, $SUMMARY_TIME, $SUMMARY_REPOSITORY, $SUMMARY_COMPONENTS_REF,\@hosts);
          if($SUMMARY_REPORTTYPE =~ /json/) {
            sumreport_create_json_report_consolidated_forall_nodes($tfa_home, $SUMMARY_TIME, $SUMMARY_REPOSITORY, $SUMMARY_COMPONENTS_REF, \@hosts);
          }
          if($SUMMARY_REPORTTYPE =~ /html/) {
            sumreport_create_html_report_consolidated_forall_nodes($tfa_home, $SUMMARY_TIME, $SUMMARY_REPOSITORY, $SUMMARY_COMPONENTS_REF, \@hosts);
          }
        } 

        # tfasimplerep
        # Supress "SUMMARY_OVERVIEW:"
        # Uncomment next line in order to display "SUMMARY_OVERVIEW:" section.
        # sumreport_display_summary_report_consolidated_forall_nodes($SUMMARY_REPORTTYPE, $SUMMARY_REPOSITORY, $SUMMARY_DISPLAY_TABLE,$SUMMARY_COMPONENTS_REF,\@hosts);


  # ##############################################################################
  # tfactl summary simple report (tfasimplerep)
  # %hashref            ==>
  #   $hashref{$component_name}{$command_name}{$attribute_name} = $attribute_value;
  # summary_profile.xml ==>
  #   <component name="crs">
  #      <command name="crs_status_summary" clusterwide="yes" html="yes" json="yes" console="yes" sequence="1"> </command>
  # $hashref{}          ==>
  #   $hashref{"crs"}{"crs_status_summary"}{"clusterwide"} = "yes";
  #   $hashref{"crs"}{"crs_status_summary"}{"html"}        = "yes";
  #   ...
  # ##############################################################################

  my $hashref = $SUMMARY_PROFILE_HASHREF;
  my %components = %$SUMMARY_COMPONENTS_REF;

  # #################################################################
  # tfactl summary simple report, (tfasimplerep)
  # @comp_order: Include nodewise/clusterwide ($comp.overview) reports
  #                                         $ c o m p . o v e r v i e w
  #                               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  # For clusterwide reports,
  #   - There's no entry $components{$comp."overview"}.
  # For nodewise reports,
  #   - There's an entry in $components{$comp}
  #   -                     $components{$comp} = 1
  # ##################################################################

  my @comp_order = ();

  foreach my $comp (@{$SUMMARY_COMPONENT_ORDER_REF}) {
    # tfasimplerep
    # comment next line if level="1" needs to be included
    ### next if ($comp eq "overview");
    push @comp_order, $comp;
    push @comp_order, $comp."overview"; # =====> INCLUDE clusterwide SUMMARIES
  } # end foreach

  my $local_compoment_order = \@comp_order;
  # tfasimplerep
  print "=====> [tfactlshare_manage_ext] Components included in summary reports (comp_order array) :  @comp_order \n" if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} );

  # ---------------------------
  #    (tfasimplerep)
  # exclude clusterwide reports
  #   $_ !~ /overview$/
  # include clusterwide reports
  #   $_ =~ /overview$/
  # ---------------------------
  # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  foreach my $component_name ( grep { exists $components{$_} || $_ =~ /overview$/ } @{$local_compoment_order} )
  #                                                             ^^^^^
  #       tfasimplerep                                         change this
  {
    next if ( $components{$component_name} != 1  && $component_name !~ /overview$/ ); # INCLUDE clusterwide SUMMARIES

    # tfasimplerep
    if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} ) {
      print " =================================================== \n";
      print "    - Reporting " . uc($component_name) . " details ... \n";
    }

    my @command_array;

    # -------------------------------------------------------------------------------
    #    (tfasimplerep)
    # Retrieve {$command_name} collection,
    # %hashref            ==>
    #   $hashref{$component_name}{$command_name}{$attribute_name} = $attribute_value;
    #                            ^^^^^^^^^^^^^^^
    # nodewise commands      ==> clusterwide="yes"
    # $compOverview commands ==> clusterwinde="no"
    # -------------------------------------------------------------------------------
    foreach my $command_name ( keys %{ $hashref->{$component_name} } )
    {
      # tfasimplerep
      print "level ==> " . $hashref->{$component_name}->{$command_name}->{'level'} . "\n" if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} );

      # tfasimplerep
      # Uncomment next two lines for full version
      #if ( ( $hashref->{$component_name}->{$command_name}->{'clusterwide'} eq "yes" ) or ( $hostname eq $driverhost ) or 
      #       $command_name =~ /clusterwide/ ) 
      # For the tfactl summary simple report include only the
      # first level
      if ( ( $hashref->{$component_name}->{$command_name}->{'level'} eq "1" ) )
      {
        push( @command_array, $command_name );

       # =====================================
       # main tfactl summary reporting code
       # main tfasimplerep
       # =====================================
       my $node_name = $hostname;
       my $repository_base_nodewise = catfile( $SUMMARY_REPOSITORY, $node_name );
       my $status;
       my $data;

       if ( $node_name ne $hostname ) {
         ( $status, $data ) = get_dependent_remote_data( $node_name, $component_name, $command_name );
       } else {
         my $get_dependent_data_loc =
            catfile( $repository_base_nodewise, "data", $component_name, "$command_name.json" );
         $status = "false" if ( !-e $get_dependent_data_loc );
       }

       # tfasimplerep
       if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} ) {
         print "[tfactlshare_manage_ext] $component_name details ...\n";
         print "component_name            $component_name\n";
         print "command_name              $command_name\n";
         print "node_name                 $node_name\n";
         print "repository_base_nodewise  $repository_base_nodewise\n";
         print "status                    $status\n";
         print "data                      $data\n";
         print "calling ... sumreport_create_console_report() ... \n";
       }

       print "      $command_name\n";

       # -------------------------------------------------------------------------------------------------------------
       # tfactl summary simple report (tfasimplerep)
       sumreport_create_console_report( $component_name, $repository_base_nodewise, ["$command_name"], $node_name, $data->{'DETAILS'} );
       # -------------------------------------------------------------------------------------------------------------

      } # end if ( $hashref->{$component_name}->{$command}->{'clusterwide'} eq "yes" ) or ( $hostname eq $driverhost ) ...
    } # end foreach keys %{ $hashref->{$component_name} }

    ### print "component_name $component_name, command_array @command_array.\n";
  } # end foreach
  # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>


  # tfasimplerep shell
  # tfactl summary shell entrance code
        if(!defined $summary_silent and $SUMMARY_DISPLAY_TABLE eq "yes" ){
          $INTERACTIVE_SUMMARY = "yes";
          sumreport_display_summary_report($SUMMARY_REPORTTYPE, $SUMMARY_REPOSITORY, $SUMMARY_DISPLAY_TABLE,$SUMMARY_COMPONENTS_REF);
          print "        ### Entering in to SUMMARY Command-Line Interface ### \n\n";
          my $myshell = "tfactl_summary";
          # tfasimplerep , call component shell
          &component_shell($tfa_home,$SUMMARY_TIME,$SUMMARY_REPORTTYPE,$SUMMARY_DISPLAY_TABLE,$SUMMARY_PROFILE_HASHREF, $myshell, $SUMMARY_COMPONENTS_REF,$complete_overview);
          print "\n        ### Exited From SUMMARY Command-Line Interface ### \n\n";
        }

        print "--------------------------------------------------------------------\n"; 
        print "REPOSITORY  : $REPOSITORY\n";
        if(!defined $view){
          print "HTML REPORT : <REPOSITORY>/report/Consolidated_Summary_Report_${current_time}.html\n" if($SUMMARY_REPORTTYPE =~ /html/);
          print "JSON REPORT : <REPOSITORY>/report/Consolidated_Summary_Report_${current_time}.json\n" if($SUMMARY_REPORTTYPE =~ /json/);
        } else {
          my $html_file = catfile($REPOSITORY,"report","Consolidated_Summary_Report_${current_time}.html"); 
          my $json_file = catfile($REPOSITORY,"report","Consolidated_Summary_Report_${current_time}.json"); 
          print "HTML REPORT : <REPOSITORY>/report/Consolidated_Summary_Report_${current_time}.html\n" if(-e $html_file);
          print "JSON REPORT : <REPOSITORY>/report/Consolidated_Summary_Report_${current_time}.json\n" if(-e $json_file);
        }
        print "--------------------------------------------------------------------\n"; 
        print "\n"; 
      }
    }
  }

  return $retval;
}

# tfasimplerep
# used in level 1 reports
sub get_dependent_remote_data
{
  my $host      = shift;
  my $component = shift;
  my $command   = shift;
  my $status    = "false";
  my $data ="";
  my $command_table ="";
  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  my $dep_hash_repository_loc = catfile($SUMMARY_REPOSITORY, "summaryfile-${host}.hash");
  my $dep_hashref;
  my $SUMMARY_REMOTE_DATA;
  if(-e $dep_hash_repository_loc and !-z $dep_hash_repository_loc){
    $dep_hashref = tfactlstore_retrieve_json_to_hash($dep_hash_repository_loc);
    $SUMMARY_REMOTE_DATA->{$host} = $dep_hashref;
  }

  foreach my $comp_details ( @{ $SUMMARY_REMOTE_DATA->{$host}->{"DETAILS"} } )
  {
    if ( $comp_details->{"COMPONENT"} eq "$component" )
    {
      foreach my $command_table ( @{ $comp_details->{"DETAILS"} } )
      {
        if ( $command_table->{"COMMAND"} eq "$command" )
        {
          $status = "true";
          my %command_tab = %{$command_table};
          $data = \%command_tab;
        }
      }
    }
  }
  return ( $status, $data );
}

sub tfactlshare_get_users
{
  my $tfa_home = shift;
  return $tfactlglobal_ctx{"tfa-validusers"} if ( defined $tfactlglobal_ctx{"tfa-validusers"} );

  my $localhost = tolower_host();
  my $actionmessage = "$localhost:listtfausers:-l\n";
  my $command = buildCLIJava($tfa_home,$actionmessage);
  my $line;
  my $username;
  my $usertype;
  my @list;

  my $all_users = "root";
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output ) {
    if ( $line =~ /!/ ) {
      @list = split( /!/, $line );
      $username = $list[1];
      $usertype = $list[2];

      if ( lc($usertype) eq "user" ) {
        $all_users .= ",$username";
      }
    }
  }
  $tfactlglobal_ctx{"tfa-validusers"} = $all_users;
  return $all_users;

}

sub tfactlshare_setup_alltool_dir_for_user
{
  my $tfa_home = shift;
  my $tfauser  = shift;
  my $tfa_base = shift;

  if ( not length $tfa_base ) {
    $tfa_base = tfactlshare_get_repository_location($tfa_home);
  }

  # Init trace directories for user
  tfactlshare_check_trace($tfa_home,$tfauser,$tfa_base);

  foreach my $tool ( keys %tfactlglobal_exttools )
  {
    tfactlshare_setup_tool_dir_for_user ( $tfa_home, $tool, $tfauser, $tfa_base);
  }
}

sub tfactlshare_setup_tool_dir_for_all_users
{
  my $tfa_home = shift;
  my $tool = shift;
  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  my $all_users = tfactlshare_get_users ($tfa_home);
  my @users = split(/,/, $all_users);
  foreach my $tfauser (@users)
  {
    tfactlshare_setup_tool_dir_for_user ( $tfa_home, $tool, $tfauser, $tfa_base);
  }
}

sub tfactlshare_setup_tool_dir_for_user
{
  my $tfa_home = shift;
  my $tool = shift;
  my $tfauser = shift;
  my $tfa_base = shift;
  my $tool_base1 = catfile($tfa_base, "suptools");
  tfactlshare_create_dir("$tool_base1", "1741") if ( ! -d "$tool_base1" );
  $tool_base1 = catfile($tfa_base, "suptools", "$hostname");
  tfactlshare_create_dir("$tool_base1", "1741") if ( ! -d "$tool_base1" );
  $tool_base1 = catfile($tfa_base, "suptools", "$hostname", $tool);
  tfactlshare_create_dir("$tool_base1", "1741") if ( ! -d "$tool_base1" );
  my $tool_base = catfile($tfa_base, "suptools", "$hostname", $tool, $tfauser);
  if ( ! -d "$tool_base" )
  {
    tfactlshare_create_dir("$tool_base", "740");
    if(!$IS_WINDOWS){
    	host("$CHOWN -R $tfauser $tool_base");
    }
  }
  if ( $tool eq "prw" )
  {
    my $prwdir = catfile($tfa_base, "suptools", "prw");
    tfactlshare_create_dir("$prwdir", "1741") if ( ! -d "$prwdir" );
    $prwdir = catfile($tfa_base, "suptools", "prw", $tfauser);
    if ( ! -d "$prwdir" )
    {
      tfactlshare_create_dir("$prwdir", "740");
      if(!$IS_WINDOWS){
      	host("$CHOWN -R $tfauser $prwdir");
      }
    }
  }

  my $suptools = catfile($tfa_base, "suptools");
  my $mode = sprintf '%04o', (stat $suptools)[2] & 07777;
  if ( $mode !~ /1$/ )
  {
    tfactlshare_suptool_permission ( $tfa_home, $tool, $tfauser);
  }
  return $tool_base;
}

sub tfactlshare_suptool_permission
{
  my $tfa_home = shift;
  my $tool = shift;
  my $tfauser = shift;
  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  my $tool_base1 = catfile($tfa_base, "suptools");
  chmod(oct("1741"),$tool_base1);
  $tool_base1 = catfile($tfa_base, "suptools", "$hostname");
  chmod(oct("1741"),$tool_base1);
  $tool_base1 = catfile($tfa_base, "suptools", "$hostname", $tool);
  chmod(oct("1741"),$tool_base1);
  my $tool_base = catfile($tfa_base, "suptools", "$hostname", $tool, $tfauser);
  chmod(oct("0740"),$tool_base);
  if(!$IS_WINDOWS){
  	host("$CHOWN -R $tfauser $tool_base");
  }

  if ( $tool eq "prw" )
  {
    my $prwdir = catfile($tfa_base, "suptools", "prw");
    chmod(oct("1741"),$prwdir);
    $prwdir = catfile($tfa_base, "suptools", "prw", $tfauser);
    chmod(oct("0740"),$prwdir);
    if(!$IS_WINDOWS){
    	host("$CHOWN -R $tfauser $prwdir");
    }
  }
  return $tool_base;
}

sub tfactlshare_setup_tool_dir
{
  my $tfa_home = shift;
  my $tool = shift;
  $tool = $tfactlglobal_exttools{$tool}->{BASENAME};
  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  my $tool_base1 = catfile($tfa_base, "suptools", $hostname, $tool, $current_user);
  tfactlshare_setup_tool_dir_for_user($tfa_home, $tool,$current_user,$tfa_base) if ( ! -d $tool_base1 && $IS_WINDOWS );
  if ( ! -d $tool_base1 )
  {
    print "Error: Can not run '$tool' as user directories are not yet setup. Please wait for setup to complete. Contact administrator if the problem persists after TFA setup is complete.\n";
    exit;
  }
  return $tool_base1;
}

sub tfactlshare_create_dir
{
  my $dir = shift;
  my $perm = shift;
  if ( ! -d "$dir" ) {
    mkdir($dir);
    chmod(oct($perm),$dir);
  }
  else {
    my $mode = (stat($dir))[2];
    $mode = sprintf("%04o",$mode & 07777);
    tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_create_dir " .
                      "$dir -> current $mode , changing to $perm", 'y', 'n');

    eval { chmod(oct($perm),$dir) if $perm ne $mode; };
  }
}

sub tfactlshare_mkpath
{
  my $dir = shift;
  my $perm = shift;
  if ( ! -d "$dir" ) {
    mkpath($dir);
    host("$CHMOD $perm $dir");
    chmod(oct($perm), $dir);
  } else {
    my $mode = (stat($dir))[2];
    $mode = sprintf("%04o",$mode & 07777);

    tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_mkpath " .
                      "$dir -> current $mode , changing to $perm", 'y', 'n');

    eval { chmod(oct($perm), $dir) if $perm ne $mode; };
  }
}

########
# NAME
#   tfactlshare_enable_tool
#
# DESCRIPTION
#   enable a tool 
# 
# PARAMETERS
# $tfa_home $tool_name
#   
# RETURNS
#    
########

sub tfactlshare_enable_tool
{
  my $tfa_home = shift;
  my $tool_name = shift;
  my $usern = shift;
  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  my $tool_dir = catfile($tfa_base, "suptools", "$hostname", $tool_name);
  unlink ("$tool_dir/$usern/$tool_name.stopped");
}

########
# NAME
#   tfactlshare_disable_tool
#
# DESCRIPTION
#   disable a tool 
# 
# PARAMETERS
# $tfa_home $tool_name
#   
# RETURNS
#    
########

sub tfactlshare_disable_tool
{
  my $tfa_home = shift;
  my $tool_name = shift;
  my $usern = shift;
  return if ( $ENV{TFA_STOP_ALL_TOOL} );
  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  my $tool_dir = catfile($tfa_base, "suptools", "$hostname", $tool_name);
  system ("touch $tool_dir/$usern/$tool_name.stopped");
}

########
# NAME
#   tfactlshare_setup_ext_out_dir
#
# DESCRIPTION
#   Setup the output directory for the tools
# 
# PARAMETERS
# $tfa_home $tool_name
#   
# RETURNS
#    
########

sub tfactlshare_setup_ext_out_dir
{
  my $tfa_home = shift;
  my $tool_name = shift;
  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  my $odir = "$tfa_base/suptools/$tool_name";
  if ( ! -d $odir )
  {
    tfactlshare_create_dir("$tfa_base/suptools", "1741") if ( ! -d "$tfa_base/suptools");
    tfactlshare_create_dir("$tfa_base/suptools/$tool_name", "1741");
  }
}

########
# NAME
#   tfactlshare_autostart_tools
#
# DESCRIPTION
#   Start all tools during TFA startup
# 
# PARAMETERS
# $tfa_home
#   
# RETURNS
#    
########
sub tfactlshare_autostart_tools
{
  # Start all tools where autostart=true, tool_status=notrunning
  my $tfa_home = shift;
  if(!$IS_WINDOWS){
  		my $lckfile = catfile($tfa_home, "internal", ".tfarmonitor.pid");
        if ( -f $lckfile )
        {
          my $tfarpid = `cat $lckfile`;
          chomp ($tfarpid);
          if ( $tfarpid )
          {
            my $tfar_running = `ps -ef |grep -w "$tfarpid" |grep -v grep|grep -c tfar_mon`;
            chomp($tfar_running);
            if ( $tfar_running == 0 )
            {
              unlink($lckfile);
            }
          }
        }
        
        if ( ! -f $lckfile )
        {
        	my $tfa_base = tfactlshare_get_repository_location($tfa_home);
		my $tfa_base2 = dirname($tfa_base);
        	my $hostname = tolower_host();
        	my $crshome = get_crs_home($tfa_home);
        	my $outputdir = catfile($tfa_base2,$hostname,"output","metadata");

        	if ( ! -d "$tfa_base2/$hostname/output/metadata" ) {
            		mkpath($outputdir);
			my $rwp = catfile($tfa_home,"receiver","internal","rconfig.properties");
			if ( -w "$rwp" ) {
				tfactlshare_updateTFAConfig($rwp, "r.tfar_monitor.output", $outputdir);
			}
		   }
	
		   my $tfactl = catfile($tfa_home,"bin","tfactl");
		   my $rconfig = catfile($tfa_home, "receiver","internal", "rconfig.properties");
		   if ( -r $rconfig ) {
			 open (FILE, $rconfig);
  			 my $producer_running = 0;
			 while (<FILE>) {
			 	chomp;
				$producer_running = 1 if ( /r.send.data.realtime=true/ );
			 }
			 close FILE;
			 if ( $producer_running == 1 ) {
			 	my $perl = tfactlshare_getPerl($tfa_home);
			 	system("$perl $tfa_home/bin/tfar_monitor.pl run $tfa_home $tfa_base $crshome 2> $tfa_base2/$hostname/output/metadata/tfar_metrics.err &");
			 } 

		   }
		}
		
		foreach my $tool ( keys %tfactlglobal_exttools )
		{
                        # Validate tool pm
                        my $tool_pm = catfile($tfa_home, "ext", $tool, "$tool.pm");
                        if ( -e "$tool_pm" )
                        {       
                          unshift(@INC,catdir($tfa_home,"ext","$tool"));
                        }
			eval "use $tool";
			tfactlshare_trace(5, "tfactl (PID = $$) autostart_tools " .
			              "Running autostart for $tool in $tfa_home",
			              'y', 'y');
			my $retval = deploy($tfa_home);
			tfactlshare_setup_tool_dir_for_all_users($tfa_home, $tool);
			my $retval = autostart($tfa_home);
		}
	}
}

########
# NAME
#   tfactlshare_stop_all_tools
#
# DESCRIPTION
#   Stop all tools during TFA shutdown
# 
# PARAMETERS
# $tfa_home
#   
# RETURNS
#    
########

sub tfactlshare_stop_all_tools
{
  my $tfa_home = shift;
  my $perl = tfactlshare_getPerl($tfa_home);
  if(!$IS_WINDOWS){
	$ENV{TFA_STOP_ALL_TOOL} = 1;
	system("$perl $tfa_home/bin/tfar_monitor.pl stop $tfa_home");
	foreach my $tool ( keys %tfactlglobal_exttools )
	{
                # Validate tool pm
                my $tool_pm = catfile($tfa_home, "ext", $tool, "$tool.pm");
                if ( -e "$tool_pm" )
                {
                  unshift(@INC,catdir($tfa_home,"ext","$tool"));
                }
		eval "use $tool";
		tfactlshare_trace(5, "tfactl (PID = $$) autostart_tools " .
		                  "Running autostart for $tool in $tfa_home",
		                  'y', 'y');
		if ( tfactlshare_tool_status($tfa_home, $tool) eq "running" )
		{
		  my $retval = stop($tfa_home);
		}
	}
  }
}

########
# NAME
#   tfactlshare_get_tfa_output_loc
# 
# DESCRIPTION
#   TFA output location
#   
# PARAMETERS
# $tfa_home
#   
# RETURNS
#    
########

sub tfactlshare_get_tfa_output_loc
{
  my $tfa_home = shift;
  return $tfactlglobal_ctx{"tfa-outloc"} if ( defined $tfactlglobal_ctx{"tfa-outloc"} );

  my $inventoryDirectory;
  $inventoryDirectory = getInventoryLocation( $tfa_home, $hostname );
  $inventoryDirectory =~ s/\/inventory//;
  $tfactlglobal_ctx{"tfa-outloc"} = $inventoryDirectory;
  return $inventoryDirectory;
}

########
# NAME
#   tfactlshare_get_tfa_metadata_loc
# 
# DESCRIPTION
#   TFA metadata location
#   
# PARAMETERS
# $tfa_home
#   
# RETURNS
#    
########

sub tfactlshare_get_tfa_metadata_loc
{
  my $tfa_home = shift;

  my $output_loc = tfactlshare_get_tfa_output_loc($tfa_home);
  $output_loc = catfile($output_loc, "metadata");

  if ( ! -d $output_loc )
  {
    system("$MKDIR $output_loc");
    chmod(oct(1755),$output_loc);
  }
  return $output_loc;
}

########
# NAME
#   tfactlshare_get_repository_location
# 
# DESCRIPTION
#   TFA Repository location
#   
# PARAMETERS
# $tfa_home
#   
# RETURNS
#    
########

sub tfactlshare_get_repository_location
{
  my $tfa_home = shift;
  my $node = shift;
  my $repos_saved_file = catfile($tfa_home, "internal", ".reposloc.dmp");
  my $REPOSITORY;
  my $line;
  return $tfactlglobal_ctx{"tfa-repos"} if ( defined $tfactlglobal_ctx{"tfa-repos"} );
  my $paramfile = tfactlshare_getSetupFilePath($tfa_home);

  if ( $ISCLOUD || isOfflineMode($paramfile) ) {
    my $tfa_base = getTFABase();
    $REPOSITORY = catfile($tfa_base, "repository");
  } elsif (isTFARunning($tfa_home) == FAILED ) {
    if ( $current_user eq "root" && -r $repos_saved_file )
    {
  	  open(RF, $repos_saved_file);
      $REPOSITORY = <RF>;
      chomp($REPOSITORY);
      close(RF);
	  if ( -d "$REPOSITORY" ) {
        $tfactlglobal_ctx{"tfa-repos"} = $REPOSITORY;
        return $REPOSITORY;
      } else {
        eval {
          unlink $repos_saved_file;
        };
        tfactlshare_signal_exception(201, undef);
        exit;
      }
    } else {
      exit;
    }
  } else {
    if ( ! $node ) {
	$node = $localhost;
    }
    dbg(DBG_WHAT, "Running printRepository through Java CLI in getRepositoryLocation\n");
    my $message = "$localhost:getRepositoryLocation:$node";
    my $command = buildCLIJava($tfa_home,$message);
    dbg(DBG_VERB, "$command\n");
    my @cli_output = tfactlshare_runClient($command);
    foreach $line ( @cli_output ) {
      if ( $line =~ /!/ ) {
        $REPOSITORY = (split(/!/, $line))[0];
        open(RF, ">$repos_saved_file");
        print RF $REPOSITORY;
        chomp($REPOSITORY);
        close(RF);
      }
    }
  }
  if ( -d "$REPOSITORY" ) {
  	$tfactlglobal_ctx{"tfa-repos"} = $REPOSITORY;
    return $REPOSITORY;
  } else {
  	tfactlshare_signal_exception(201, undef);
    exit;
  }
}

########
# NAME
#   tfactlshare_get_rbase
#
# DESCRIPTION
#   Get TFA repository path based on type of installation
#
# PARAMETERS
#   tfa_home
#
# RETURNS
#   tfa_base
########

sub tfactlshare_get_rbase
{
    my $tfa_home = shift ; 
    my $cc = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"CLUSTER_CLASS");
    my $tfa_base = tfactlshare_get_repository_location($tfa_home);

    if ( $cc eq "DOMAINSERVICES") {
    	$tfa_base = "/mnt/oracle/tfa";
    }
    return $tfa_base;
}

########
# NAME
#   tool_status
#
# DESCRIPTION
#   This function checks tool status
#
# PARAMETERS
# $tfa_home $tool_name
#
# RETURNS
#    nodaemon, starting, running, notrunning, stopping, stopped
########

sub tfactlshare_tool_status
{
  my $tfa_home = shift;
  my $tool_name = shift;
  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  if ( -f "$tfa_base/suptools/$tool_name/$tool_name.stopped" )
  {
    return "stopped";
  }
  # Validate tool pm
  my $tool_pm = catfile($tfa_home, "ext", $tool_name, "$tool_name.pm");
  if ( -e "$tool_pm" )
  {
    unshift(@INC,catdir($tfa_home,"ext","$tool_name"));
  }
  eval "use $tool_name";
  my $retval = is_running($tfa_home);
  if ($retval == 1)
  {
    return "running";
  }
   elsif ( $retval == 0 )
  {
    return "notrunning";
  }
   elsif ( $retval == 2 )
  {
    return "nodaemon";
  }
   elsif ( $retval == 3 )
  {
    return "stopped";
  }
   else
  {
    return "unknown";
  }
}

########
# NAME
#   tfactlshare_add_prompt
#
# DESCRIPTION
#   Change prompt of tfactl based on session
#
# PARAMETERS
# 
#
# RETURNS
#    
########

sub tfactlshare_add_prompt
{
   my $prompt = shift;
   my %ctx = shift;
   my $prompt_now = "";
   #my %ctx = %{$ctxref};

   foreach my $key (keys %ctx)
   {
     if ( $ctx{$key} )
     {
       $prompt_now .= $ctx{$key} . " ";
     }
   }
   $prompt_now .= $prompt;
   return $prompt_now;
}

########
# NAME
#   tfactlshare_get_choice
#
# DESCRIPTION
#   Get selection among a range of values
#
# PARAMETERS
#  $minvalue
#  $maxvalue
#  $prompt
#  $defaultvalue
#
# RETURNS
#    
########
sub tfactlshare_get_choice {
  my $minvalue = shift;
  my $maxvalue = shift;
  my $prompt = shift;
  my $defaultvalue = shift;
  my $optselected = -1;

  while ( not ( int($optselected) - $optselected == 0 &&
          $optselected >= $minvalue && $optselected <= $maxvalue ) ) {
     $optselected = 0;
     print "$prompt";
     {     
        local($SIG{INT}) = sub { print "Cancelling...\n"; exit 0; }; 
        $optselected =<STDIN>;
     }
     chomp($optselected);
     if ( length($optselected) == 0 ) {
       $optselected = $defaultvalue;
     } elsif ( length $optselected ) {
       if ( $optselected !~ /[0-9]+/ ) {
         $optselected = -1;
       } 
     }
  } # end while $optselected

  return $optselected;
}

########
# NAME
#   tfactlshare_get_choice_yn
#
# DESCRIPTION
#   Get selection
#
# PARAMETERS
#  $yesvalue
#  $novalue
#  $prompt
#  $defaultvalue
#
# RETURNS
#    
########
sub tfactlshare_get_choice_yn {
  my $yesvalue = shift;
  my $novalue  = shift;
  my $prompt = shift;
  my $selectiondefval = lc(shift);
  my $selection = "";

  while ( not ( lc($selection) eq lc($yesvalue) ||
                lc($selection) eq lc($novalue) ) ) {
     print $prompt;
     {     
        local($SIG{INT}) = sub { print "Cancelling...\n"; exit 0; }; 
        $selection =<STDIN>;
     }
     chomp($selection);
     if ( length($selection) == 0 ) {
       $selection = $selectiondefval;
     }
  } # end while $optselected
  return lc($selection);
}

sub tfactlshare_get_choice_array {
  my $inparrayref = shift;
  my $multimsg    = shift;
  my $selmsg      = shift;
  my @inputarray  = @$inparrayref;
  my $optselected = -1;
  my $totndx;
  my $retndx;

  if ( @inputarray ) {
    if ( $#inputarray > 0 ) { 
      print "\n$multimsg\n\n";
      $totndx = $#inputarray;
      for my $ndx ( 0..$totndx ) {
         print "option[$ndx] $inputarray[$ndx] \n";
      }
      while ( not ( int($optselected) - $optselected == 0 && 
              $optselected >= 0 && $optselected <= $totndx ) ) {
         $optselected = 0;
         print "\n$selmsg [$optselected] ?";
         {
           local($SIG{INT}) = sub { print "Cancelling...\n"; exit 0; };
           $optselected =<STDIN>;
         }
         chomp($optselected);
         if ( length($optselected) == 0 ) {
           $optselected = 0;
         }
       } # end while
       print "$inputarray[$optselected] was selected \n\n";
       return ($optselected,$inputarray[$optselected]);
    } else {
      return (0,$inputarray[0]);
    } # end if $#inputarray > 0
  } else {
    return (-1,"");
  } # end if @inputarray
} # end sub tfactlshare_get_choice_array

########
# NAME
#   tfactlshare_input_date
#
# DESCRIPTION
#   Input date/time
#
# PARAMETERS
#  $prompt - Prompt
#  $invmsg - Invalid message
#
# RETURNS
#  Valid date/time or empty string
#    
########
sub tfactlshare_input_date {
  my $prompt = shift;
  my $invmsg = shift;
  my $firstevent = shift;
  my $lastevent = shift;
  my $firsttime = shift;
  my $lasttime  = shift;
  my $uts;
  my $checktime = FALSE;
  $checktime = TRUE if ( $firstevent && $lastevent && $firsttime && $lasttime );

  my $fxval   = "invalid";
  my $userinp = " ";
  my $retval  = "";

  while ( $fxval eq "invalid" && length $userinp) {
       print "$prompt";
       {
        local($SIG{INT}) = sub { print "Cancelling...\n"; exit 0; }; 
        $userinp =<STDIN>;
       }
       chomp($userinp);
       #print "userinp ($userinp) \n";
       if (length $userinp) {
         $fxval = getValidDateFromString($userinp, "startdate");
         #print "fxval $fxval\n";
         if ( $fxval eq "invalid" ) {
           print "$invmsg";
         } else {
           if ( $checktime ) {
             $uts = getValidDateFromString($userinp, "time");
             if ( not ($uts < $firstevent || $uts > $lastevent) ) {
               $retval = $fxval; 
             } else {
               $fxval = "invalid";
             } # end if $uts < $firstevent || $uts > $lastevent
           } else { 
             $retval = $fxval;
           } # end if $checktime
         }
       }
  } # end while $retval eq "invalid" && length $userinp
  #print "Returning Retval\n";
  return $retval;
}

########
# NAME
#   tfactlshare_get_ctime
#
# DESCRIPTION
#   return current time
#
# PARAMETERS
# 
#
# RETURNS
#    
########
sub tfactlshare_get_ctime
{
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                localtime(time);
  $year += 1900;
  my $month = sprintf("%02d", $mon+1);
  return "$year-$month-$mday-$hour-$min-$sec";
}

########
# NAME
#   tfactlshare_get_files
#
# DESCRIPTION
#   return list of files from inventory matching filters
#
# PARAMETERS
#  multiple values are passed in parameter separated by |
#
# RETURNS
#   array of files matching filters 
########

sub tfactlshare_get_files
{
  my $tfa_home = shift;
  my $filelike = shift;
  my $dirlike = shift;
  my $file_type = shift;
  my $db = shift;
  my $inst = shift;
  my $comp = shift;
  my $itime = shift;
  my $stime = shift;
  my $etime = shift;
  my @matches = ();

  my $inventoryDirectory = getInventoryLocation( $tfa_home, $hostname );
  my $inv = catfile($inventoryDirectory, "inventory.xml");

  if ( ! -r  $inv )
  {
    print "Error: Failed to read database ($inv)\n";
    return;
  }

  my ($stime_ts, $etime_ts);
  if ( $stime )
  {
    $stime_ts = getValidDateFromString($stime, "time");
    if ( $stime_ts eq "invalid" ) {
      print "$stime is not a valid time.\n";
      return;
    }
    $etime_ts = getValidDateFromString($etime, "time");
    if ( $etime_ts eq "invalid" ) {
      print "$etime is not a valid time.\n";
      return;
    }
  }

  if ( $itime )
  {
    my $istime_ts = getValidDateFromString($itime, "time");
    if ( $istime_ts eq "invalid" ) {
      print "$itime is not a valid time.\n";
      return;
    }
    $stime_ts = $istime_ts - (1*60*60);
    $etime_ts = $istime_ts + (1*60*60);
  }
  
  open(INV, $inv);
  my $matched = 0;
  my $cfile = "";
  my $utime_i = "";
  my $ftime_i = "";
  my $etime_i = "";

  my %matches = ("filename" => 2,
              "dirname" => 2,
              "file_type" => 2,
              "db" => 2,
              "inst" => 2,
              "comp" => 2,
              "time" => 2
             );
  $matches{"filename"} = 0 if ( $filelike );
  $matches{"dirname"} = 0 if ( $dirlike );
  $matches{"file_type"} = 0 if ( $file_type );
  $matches{"db"} = 0 if ( $db );
  $matches{"inst"} = 0 if ( $inst );
  $matches{"comp"} = 0 if ( $comp );
  $matches{"time"} = 0 if ( $stime || $itime );

  if($IS_WINDOWS){
  	$filelike =~ s{\\}{\\\\}g;
  	$filelike =~ s{/}{\\\\}g;
  }
  
  $filelike =~ s/[^\.]\*/\.*/g;
  $filelike =~ s/^\+/\\\+/g;
  $filelike =~ s/(\w)\+/$1\\\+/g;

  my %fmatches = ();
  while(<INV>)
  {
    chomp;
    if ( /^\<file_name\>(.*)\<\/file_name/ )
    {
      $matched = 0;
      $utime_i = "";
      %fmatches = %matches;

      $cfile = $1;
      if ( ( $filelike && $cfile =~ /$filelike[^\/]*?$/i ) || 
           ( $dirlike && $cfile =~ /$dirlike/i ) )
      {
        $matched = 1;
        $fmatches{"filename"} = 1;
        $fmatches{"dirname"} = 1;
      }
    }
     elsif ( $fmatches{"filename"} && $fmatches{"dirname"} && 
             $file_type && /^\<file_type\>(.*)\<\/file_type/i )
    {
      if ( lc($1) eq lc($file_type) )
      {
        $matched = 1;
        $fmatches{"file_type"} = 1;
      }
    }
     elsif ( $fmatches{"filename"} && $fmatches{"dirname"} && $fmatches{"file_type"} &&
             $db && /^\<database\>(.*)\<\/database/i )
    {
      if ( lc($1) eq lc($db) )
      {
        $matched = 1;
        $fmatches{"db"} = 1;
      }
    }
     elsif ( $fmatches{"filename"} && $fmatches{"dirname"} && $fmatches{"file_type"} &&
             $fmatches{"db"} && $inst && /^\<instance\>(.*)\<\/instance/i )
    {
      if ( lc($1) eq lc($inst) )
      {
        $matched = 1;
        $fmatches{"inst"} = 1;
      }
    }
     elsif ( $fmatches{"filename"} && $fmatches{"dirname"} && $fmatches{"file_type"} &&
             $fmatches{"db"} && $fmatches{"inst"} &&
             $stime_ts && /\<last_modified\>(.*)\<\/last_modified/ )
    {
      $utime_i ="";
      $utime_i = get_unix_date($1) if ( $1 );
    }
     elsif ( $fmatches{"filename"} && $fmatches{"dirname"} && $fmatches{"file_type"} &&
             $fmatches{"db"} && $fmatches{"inst"} &&
             $stime_ts && /\<first_timestamp\>(.*)\<\/first_timestamp/ )
    {
      $ftime_i = "";
      $ftime_i = get_unix_date($1) if ( $1 );
    }
     elsif ( $fmatches{"filename"} && $fmatches{"dirname"} && $fmatches{"file_type"} &&
             $fmatches{"db"} && $fmatches{"inst"} &&
             $stime_ts && /\<last_timestamp\>(.*)\<\/last_timestamp/ )
    {
      $etime_i = "";
      $etime_i = get_unix_date($1) if ( $1 );
    }
     elsif ( /^\<\/file\>/ )
    {
      if ( $utime_i && $stime_ts )
      {
        $fmatches{"time"} = 1 if ( $utime_i >= $stime_ts && $utime_i <= $etime_ts );
        $fmatches{"time"} = 1 if ( $stime_ts <= $etime_i && $etime_ts >= $ftime_i );
        $matched = 1 if ( $fmatches{"time"} == 1 );
      }
      if ( $matched == 1 ) {
        foreach my $key (keys %fmatches )
        {
          if ( $fmatches{$key} == 0 )
          {
            #print "match failed for $key in $cfile\n  $utime_i/$ftime_i/$etime_i - $stime_ts/$etime_ts\n" if ( $cfile =~ /$filelike/ );
            $matched = 0;
            last;
          }
        }
      }
      push @matches, $cfile if ( $matched);
    }
  }
  close(INV);
  return @matches;
}


# Fri Jan 30 04:42:57 PST 2015
# o/p unix time
sub get_unix_date
{
  my $ip = shift;
  my $str = "";
  if ( $ip =~ /\w+ (\w+) (\d+) ([\d\:]+) \w+ (\d+)/ )
  {
    $str = "$1/$2/$4 $3";
    return getValidDateFromString($str, "time");
  }
}

########
# NAME
#   collect_topology
# 
# DESCRIPTION
#   This function collects system topology
# 	node names
#		@nodelist = getListOfAllNodes( $tfa_home );
#		os params
#			sysctl -a
#		os packages
#			rpm -qa --queryformat "%{NAME}|%{VERSION}|%{RELEASE}|%{ARCH}\n"
#		os patches
#			
#		crs_home & oracle_home's
#			- patches
#				$ORACLE_HOME/OPatch/opatch lsinventory -oh $ORACLE_HOME -local
#			- version
#				$ORACLE_HOME/bin/sqlplus -v
#			- databases and instance names
#				- run status
#					- tfactlshare_set_ora_env
#				- last startup time
#					- SELECT TO_CHAR (startup_time, 'dd-mon-yyyy hh24:mi:ss') start_time from V$instance;
#					- or in alert_ log
#				- db parameters
#					select i.instance_name||'.'||p.name || ' = ' || value from gv$parameter p,gv$instance i where p.inst_id = i.inst_id order by p.name,i.instance_name;
#					select ksppinm || ' = ' || ksppstdvl from sys.x$ksppi n,sys.x$ksppsv v where n.indx = v.indx and instr(ksppinm,'_') = 1;
#				- init parameters
#					- alert_
#				- pids and procs for each startup
#					- alert_
#   
# PARAMETERS
# $tfa_home $tool_name
# 
# RETURNS
#    nodaemon, starting, running, notrunning, stopping, stopped
######## 

sub tfactlshare_collect_topology
{
  my $tfa_home = shift;

  my $output_loc = tfactlshare_get_tfa_metadata_loc($tfa_home);
  chdir($output_loc);

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
                                                localtime(time);
  $year += 1900;
  my $month = sprintf("%02d", $mon+1);
  $hour = sprintf("%02d", $hour);
  $min = sprintf("%02d", $min);
  $sec = sprintf("%02d", $sec);
  $mday = sprintf("%02d", $mday);
  $tfactlshare_timeline{"ctime"} = "$year-$month-$mday $hour:$min:$sec";

  # Discover 
  my $dscript = catfile($tfa_home, "bin", "discover_ora_stack.pl");
  my $perl = tfactlshare_getPerl($tfa_home);
  chomp($perl);
  $perl = "perl" if ( ! $perl ); 
  tfactlshare_run_a_os_cmd("$perl $dscript -tfahome $tfa_home -from sc", "discovery.log");
  my $dout = catfile($tfa_home, "internal", "ora_stack_status.out");
  system("$MV $dout ora_stack_status.out") if ( -r $dout );
  
  # Nodes
  my @nodelist = getListOfAllNodes( $tfa_home );
  open(WF, ">nodes.out");
  foreach my $node ( @nodelist )
  {
    print WF "$node\n";
  }
  close(WF);

  if ( $^O eq "hpux" ) 
  {
    tfactlshare_run_a_os_cmd("/usr/sbin/kctune |sed 's/ / =/'", "sysctl.out");
    tfactlshare_add_key_eq_val_to_timeline($tfa_home, "osparam", "sysctl.out");
  }
   elsif ( $^O eq "sunos" || $^O eq "solaris" )
  {
    tfactlshare_run_a_os_cmd("getconf  -a |sed 's/: */ = /'", "sysctl.out");
    tfactlshare_add_key_eq_val_to_timeline($tfa_home, "osparam", "sysctl.out");
    tfactlshare_run_a_os_cmd("cat /etc/system |grep '^set ' |sed 's/set //'|sed 's/=/ = /'", "sysctl.out");
    tfactlshare_add_key_eq_val_to_timeline($tfa_home, "osparam", "sysctl.out");
  }
  # TODO need to add condition for Windows parameter collection.
  if ($osname eq "Linux")
  {
    # Collect OS params
    tfactlshare_run_a_os_cmd("/sbin/sysctl -a", "sysctl.out");
    tfactlshare_add_key_eq_val_to_timeline($tfa_home, "osparam", "sysctl.out");

    # Collect RPM's
    tfactlshare_run_a_os_cmd("rpm -qa --queryformat \"(\%{INSTALLTIME:date}): \%{NAME}|\%{VERSION}|\%{RELEASE}|\%{ARCH}\\n\"", "rpms.out");
    if ( -r "rpms.out" )
    {
      open(SF, "rpms.out");
      while(<SF>)
      {
        chomp;
        if ( /\((.*)\): (.*)/ )
        {
          tfactlshare_add2timeline($tfa_home, "$1", "ospkg.$2", 1, "PARAM");
        }
      }
      close(SF);
    }
  }

  # Collect oracle software home's
  my @homes = tfactlshare_read_homes ($tfa_home);

  # Collect info about running software's (crs/db)
  tfactlshare_stack_status ($tfa_home, @homes);
  
  # Read database param files and add to timeline
  opendir(DIR, ".") or die $!;
  while (my $file = readdir(DIR)) 
  {
    if ($file =~ /(.*)\.param.out/ )
    {
      tfactlshare_add_key_eq_val_to_timeline($tfa_home, "dbparam.$1", "$file");
    }
  }
  closedir(DIR);

  opendir(DIR, catdir($tfa_home,"internal","dbparams")) or die $!;
  while (my $file = readdir(DIR))
  {
    if ($file =~ /(.*)\.param.out/ )
    {
      tfactlshare_add_key_eq_val_to_timeline($tfa_home, "dbparam.$1", catfile($tfa_home,"internal","dbparams","$file"));
    }
  }
  closedir(DIR);


  # Collect patch and version of each home
  my $i = 0;
  open(PF, ">opatches.out");
  foreach my $home (@homes)
  {
    $i ++;
    # Get patch level
    my @ohi = split(":", $home);
    if ( -d $ohi[1] )
    {
      $ENV{ORACLE_HOME} = $ohi[1];
      $ENV{LD_LIBRARY_PATH} = catfile($ohi[1], "lib");
      my $opatch = catfile($ENV{ORACLE_HOME}, "OPatch", "opatch");
      my $ouser;
      my @out;
      my $suneeded = TRUE;
      if ($IS_WINDOWS) 
      {
        $ouser = tfactlshare_get_user((stat($opatch))[4]);
      }
       else
      {
        $ouser = getpwuid((stat($opatch))[4]);
      }
      if ( $IS_WINDOWS or $current_user ne "root" ) {
        $suneeded = FALSE;
      }
      if ( $suneeded ) {
        tfactlshare_run_a_os_cmd(tfactlshare_checksu($ouser,"cd $ENV{ORACLE_HOME}; $opatch lsinventory -oh $ENV{ORACLE_HOME} -local", "patches_$i.out"));
        @out = tfactlshare_run_a_os_cmd(tfactlshare_checksu($ouser,"$ENV{ORACLE_HOME}/bin/sqlplus -v"));
      } else {
        tfactlshare_run_a_os_cmd("cd $ENV{ORACLE_HOME}; $opatch lsinventory -oh $ENV{ORACLE_HOME} -local", catfile($output_loc,"patches_$i.out"));
        @out = tfactlshare_run_a_os_cmd("$ENV{ORACLE_HOME}/bin/sqlplus -v");
      }

      my $v = "";
      foreach my $line(@out)
      {
        if ( $line =~ /Release ([\d\.]+) / )
        {
          $v = $1;
        }
      }
      print PF "HOME : " .  $ohi[1] ."\n";
      my $patchlist = read_patches($tfa_home, $ohi[1], "patches_$i.out");
      print PF "PATCHLIST : " .  $ohi[1] ."|$v|$patchlist\n";
    }
  }
  close(PF);

  # Parse alert logs
  tfactlshare_parse_files($tfa_home);
}

sub tfactlshare_add_key_eq_val_to_timeline
{
  my ($tfa_home, $pre, $file) = @_;
  if ( -r "$file" )
  {
    open(SF, "$file");
    while(<SF>)
    {
      chomp;
      s/\t/ /g;
      if ( /(.*) = (.*)/ )
      {
        tfactlshare_add2timeline($tfa_home, "", "$pre.$1", $2, "PARAM");
      }
    }
    close(SF);
  }
}

# Read existsing key -> value in internal/timeline.out to tfactlshare_timeline hash
# If its changed, add with timestamp
# else return
sub tfactlshare_add2timeline
{
  my $tfa_home = shift;
  my $time = shift;
  my $key = shift;
  my $val = shift;
  my $type = shift;
  
  $type = "INFO" if ( ! $type );
  my $outfile = "timeline.out";
  if ( $type eq "PARAM" )
  {
    $outfile = "params.out";
  }

  my $output_loc = tfactlshare_get_tfa_metadata_loc($tfa_home);
  my $timeline_f = catfile($output_loc, $outfile);

  if ( -f $timeline_f )
  {
    my $filesize = (stat("$timeline_f"))[7];
    if ( $filesize > 26214400 )
    {
      if ( $filesize > 27214400 )
      { # Truncate file
        open(F1, $timeline_f);
        open(MF1, ">$timeline_f.mv");
        seek F1, -26214400, 2;
        while(<F1>)
        {
          print MF1 $_;
        }
        close(F1);
        close(MF1);
        unlink("$timeline_f");
      }
       else
      {
        unlink("$timeline_f.mv");
        move($timeline_f, "$timeline_f.mv");
      }
    }
  }

  # TODO 
  # If type is param then check if its changed
  # else just append

  if ( ! exists $tfactlshare_timeline{"initialized"} )
  {
    if ( -r $timeline_f )
    {
      open(TF, $timeline_f);
      while(<TF>)
      {
        chomp;
        if ( /^(\w+\/\d+\/\d+ \d+:\d+:\d+) (\w+): (.*) = (.*)$/ )
        {
          push @{$tfactlshare_timeline{$3}->{TS}}, $1;
          push @{$tfactlshare_timeline{$3}->{VAL}}, $4;
          $tfactlshare_timeline{$3}->{CTS} = $1;
          $tfactlshare_timeline{$3}->{CVAL} = $4;
          #print " Test $3 $1 $4 \n";
        }
      }
      close(TF);
      $tfactlshare_timeline{"initialized"} = 1;
    }
  }

  my $update = 0;
  if ( ! exists $tfactlshare_timeline{$key} )
  {
    $update = 1;
  }
   elsif ( exists $tfactlshare_timeline{$key} && ($tfactlshare_timeline{$key}->{CVAL} ne $val || 
         ($tfactlshare_timeline{$key}->{CVAL} eq $val && $tfactlshare_timeline{$key}->{TS} ne $time )))
  { # Already in timeline
    $update = 1;
  } 

  if ( $update == 1 )
  {
    $time = $tfactlshare_timeline{"ctime"} if ( ! $time );
    my $ts = tfactlshare_get_date($time);
    push @{$tfactlshare_timeline{$key}->{TS}}, $time;
    push @{$tfactlshare_timeline{$key}->{VAL}}, $val;
    $tfactlshare_timeline{$key}->{CTS} = $time;
    $tfactlshare_timeline{$key}->{CVAL} = $val;
    open(my $th, '>>', $timeline_f)
              or die "Could not open file '$timeline_f' $!";
    print $th "$ts $type: $key = $val\n";
    close $th;
  }
}

sub tfactlshare_get_date
{
  my $str = shift;
  my $date = ParseDate(join(" ", $str));
  if (!$date)
  {
    print "Sorry. Could not parse date string: $str\n";
    return "";
  }
   else
  {
    my ($year, $month, $day, $ts) = UnixDate($date, "%Y", "%b", "%d", "%T");
    return "$month/$day/$year $ts";
  }
}


sub read_patches
{
  my $tfa_home = shift;
  my $ohome = shift;
  my $file = shift;
  my %patches = ();
  my $patchno = ();
  my $patchlist = "";
  if ( -r "$file" )
  {
    open(PRF, $file);
    while(<PRF>)
    {
      chomp;
      if ( /^Patch\s+(\d+)\s+: applied on (.*)/ )
      {
        $patchno = $1;
        $patches{$1}->{APPLIEDON} = $2;
        $patchlist .= ",$patchno";
        tfactlshare_add2timeline($tfa_home, $2, "home.$ohome.patch.$patchno", "applied", "PARAM");
      }
       elsif ( /^Patch description:\s+\"(.*)\"/ )
      {
        $patches{$patchno}->{DESC} = $1;
        tfactlshare_add2timeline($tfa_home, $2, "home.$ohome.patch.$patchno.desc", "$1", "PARAM");
      }
    }
    close(PRF);
  }
  foreach my $patchno (keys %patches)
  {
    print PF $patches{$patchno}->{APPLIEDON} . " : $patchno - " . $patches{$patchno}->{DESC} ."\n";
  }
  return $patchlist;
}

# Stack status
sub tfactlshare_stack_status
{
  my $tfa_home = shift;
  my @homes = @_;
  my @tmp = grep { $_ =~ /CRS:/} @homes;
  my $crs_home = $tmp[0];
  $crs_home =~ s/CRS://;
}

# OS commands

sub tfactlshare_run_a_os_cmd
{
  my $cmd = shift;
  my $outfile = shift;
  if ( $outfile )
  {
    system("$cmd > $outfile 2>&1");
  }
   else
  {
    my @out = qx($cmd 2>&1);
    chomp (@out);
    return @out;
  }
}

# Run SQL Command
sub tfactlshare_run_a_sql
{
  my $iptype = shift;
  my $sql = shift;
  my $runsqlsh = shift;
   
  my $ORACLE_HOME = $ENV{ORACLE_HOME};
  my $ORACLE_SID = $ENV{ORACLE_SID};
  my $OH_dbOwner = $ENV{TFA_ORACLE_USER};

  if ( ! $runsqlsh ) {
    ( undef , $runsqlsh) = tempfile();
    $runsqlsh.=$$.time().".sh";
  }

  my $count = 0;
  while ($count le 3) {
     last if ( ! -e $runsqlsh ) ;
     $runsqlsh =~ s/runsql/runsql$count/;
     $count++;
  }
  if ( -e $runsqlsh ) {
     print "SQL file already exists too many times\n";
     exit;
  }

  # escape the $ for v$ tables.
  $sql =~ s/v\$/v\\\$/g if ( ! $IS_WINDOWS );
  if ( $IS_WINDOWS) {
    $sql =~ s/\\\$/\$/g;
    $sql =~ s/\)/\^\^\^\)/g;
    $sql =~ s/\(/\^\(/g;
    $sql =~ s/\'/\^\'/g;
    $sql =~ s/\%/\%\%/g;
    $sql =~ s/\"/\^\"/g;
    $sql =~ s/\</\^\^\^\</g;
    $sql =~ s/\>/\^\^\^\>/g;
    $sql =~ s/\=/\^\=/g;
    $runsqlsh =~ s/\.sh/\.bat/ ;
  }
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_run_a_sql " .
                    "Type $iptype, file $runsqlsh, HOME $ORACLE_HOME, SID $ORACLE_SID, USER $OH_dbOwner ",
                   'y', 'y');
  open (SF, ">$runsqlsh");
  if ( ! $IS_WINDOWS) {
    print SF "#!/bin/sh\n";
    print SF "ORACLE_SID=$ORACLE_SID; export ORACLE_SID\n";
    print SF "ORACLE_HOME=$ORACLE_HOME; export ORACLE_HOME\n";
    print SF "ORA_SERVER_THREAD_ENABLED=FALSE; export ORA_SERVER_THREAD_ENABLED\n";
    print SF "LD_LIBRARY_PATH=$ORACLE_HOME/lib; export LD_LIBRARY_PATH\n";
  } else {
    print SF "\@echo off\n";
    print SF "SET ORACLE_SID=$ORACLE_SID\n";
    print SF "SET ORACLE_HOME=$ORACLE_HOME\n";
    print SF "SET ORA_SERVER_THREAD_ENABLED=FALSE\n";
    print SF "SET LD_LIBRARY_PATH=$ORACLE_HOME\\lib\n";

  }
  if ( $iptype eq "file" )
  {
    if ( $IS_WINDOWS ) {
      print SF "$ORACLE_HOME\\bin\\sqlplus -s -L / as sysdba @"."$sql \n";
    } else {
      print SF "$ORACLE_HOME/bin/sqlplus -s -L / as sysdba  @"."$sql << EOF\n";
      print SF"EOF";
    } 
  } 
   else
  {
    if ( $IS_WINDOWS ){
      print SF "( ";
      print SF " echo ".$_."\n" for split '\n', $sql;
      print SF " echo exit\n";
      print SF ") | ";
      print SF "$ORACLE_HOME\\bin\\sqlplus -s -L \"/ as sysdba\"\n";
    } else {
      print SF "$ORACLE_HOME/bin/sqlplus -s -L / as sysdba << EOF\n";
      print SF "$sql\n";
      print SF "EOF";
    }
  }
  close(SF);
  chmod(oct("0755"),$runsqlsh);
  my @out;
  if ( $current_user eq "root" && ! $IS_WINDOWS )
  {
    #print("Running $runsqlsh as $OH_dbOwner\n");
    @out = `su $OH_dbOwner -c "$runsqlsh" 2>&1`;
  }
   else
  {
    #print("Running $runsqlsh\n");
    @out = `$runsqlsh 2>&1`;
  }
  unlink($runsqlsh);
  chomp(@out);
  return @out;
}


# Read tfasetup and return array with <comp>:<home>
sub tfactlshare_read_homes
{
  my $tfa_home = shift;
  my $tfa_setup;
  if ( $ISCLOUD ) {
     $tfa_setup = getCloudSetupFile();
  } else {
     $tfa_setup = catfile($tfa_home, "tfa_setup.txt");
  }

  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_read_homes " .
                        "tfa_setup file to read  $tfa_setup", 'y', 'y');

  my @homes = ();
  if ( -r "$tfa_setup" )
  {
    open(RF, "$tfa_setup");
    while(<RF>)
    {
      chomp;
      if ( /CRS_HOME=(.*)/ )
      {
        push @homes, "CRS:$1";
        tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_read_homes " .
                        "Adding CRS:$1 to homes", 'y', 'y');
      }
       elsif ( /RDBMS_ORACLE_HOME=([^\|]+)/ )
      {
        push @homes, "DB:$1";
        tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_read_homes " .
                        "Adding DB:$1 to homes", 'y', 'y');
      }
    }
    close(RF);
  }
  return @homes;
}


# Parse database alert_ log and extract 
# pid -> process mapping
# Startup, shutdown, ORA- errors
# init params


sub tfactlshare_parse_files
{
  my $tfa_home = shift;
  my $setupfile = tfactlshare_getSetupFilePath($tfa_home);

  if ( ($current_user ne "root") && (not isOfflineMode($setupfile)) ) 
  {
    print "Only admin user can run this command.\n";
    return;
  }

  # Check if its already running.. if so just wait for 5 mins and return.
  my $lckfile = catfile ($tfa_home, "internal", ".parser.running");
  if ( -f $lckfile )
  {
    my $cnt = 0;
    while ($cnt++ < 300 )
    {
      last if ( ! -f $lckfile );
      sleep(1);
    }
    if ( -f $lckfile )
    {
      print "Error: Failed to get latest events\n"; 
    }
    return;
  }
   else
  {
    open(LWF, ">$lckfile");
    print LWF $$;
    close(LWF);
  }
  my $inventoryDirectory = getInventoryLocation( $tfa_home, $hostname );
  my $inv = catfile($inventoryDirectory, "inventory.xml");

  if ( ! -r  $inv )
  {
    unlink($lckfile);
    print "Error: Failed to read database ($inv)\n";
    return;
  }

  open(INV, $inv);
  my %callback_funcs = ( "Alert Log - DB"       => \&tfactlshare_parse_db_asm_alert,
                    "Alert Log - ASM" => \&tfactlshare_parse_db_asm_alert,
                    "Alert Log - ASMPROXY"    => \&tfactlshare_parse_db_asm_alert,
                    "Alert Log - ASMIO"    => \&tfactlshare_parse_db_asm_alert,
                    "CRS Alert Log"    => \&tfactlshare_parse_crs_alert);

  my ($file, $db, $inst, $file_type);
  while(<INV>)
  { 
    chomp;
    if ( /file_name\>(.*)\<\/file_name/ )
    {
      $file = $1;
    }
     elsif ( /file_type\>(.*)\<\/file_type/i )
    {
      $file_type = $1;
    }
     elsif ( /database\>(.*)\<\/database/i )
    {
      $db = $1;
    }
     elsif ( /instance\>(.*)\<\/instance/i )
    {
      $inst = $1;
    }
     elsif ( /\<\/file\>/ )
    {
      if ( defined $callback_funcs{$file_type} )
      {
        my $retval = $callback_funcs{$file_type}($tfa_home, $file, $db, $inst);
      }
    }
  }
  close(INV);  
  unlink($lckfile);
}

sub tfactlshare_write_file_offset
{
  my $tfa_home = shift;
  my $file = shift;
  my $offset = shift;
  my $output_loc = tfactlshare_get_tfa_metadata_loc($tfa_home);
  my $offset_f = catfile($output_loc, ".offset.dmp");
  my $offset_f_tmp = catfile($output_loc, ".offset.tmp");

  unlink($offset_f_tmp) if ( -f $offset_f_tmp );
  system("$TOUCH $offset_f") if ( ! -f $offset_f );

  open(OF, ">$offset_f_tmp");
  open(RF, "$offset_f");
  my $found = 0;
  my $f2m = quotemeta($file);
  while(<RF>)
  {
    chomp;
    if ( /^$f2m.offset=/ )
    {
      print OF "$file.offset=$offset\n";
      $found = 1;
    }
     else
    {
      print OF "$_\n";
    }
  }
  if ( ! $found )
  {
    print OF "$file.offset=$offset\n";
  }
  close(OF);
  close(RF);
  move($offset_f_tmp, $offset_f);
  unlink($offset_f_tmp);
}

sub tfactlshare_read_file_offset
{
  my $tfa_home = shift;
  my $file = shift;
  my $output_loc = tfactlshare_get_tfa_metadata_loc($tfa_home);
  my $offset_f = catfile($output_loc, ".offset.dmp");
  # Read only last 50 MB
  my $readlimit = 52428800;
  my $filesize = (stat("$file"))[7];
  if (  ! -f $offset_f )
  {
    if ( $filesize > $readlimit )
    {
      return $filesize - $readlimit;
    }
    return 0;
  }
  my $offset = 0;
  my $f2m = quotemeta($file);
  open(RF, "$offset_f");
  while(<RF>)
  {
    chomp;
    if ( /^$f2m.offset=(\d+)/ )
    {
      $offset = $1;
      last;
    }
  }
  close(RF);
  # If the offset saved is greater than than the current file size then it's likely the file was truncated.
  # this is a temporary fix as we will just use the Scanned events from Lucene.
  if ( $offset > $filesize )
  {
    $offset = 0;
  }
  my $toread = $filesize - $offset;
  if ( $toread > $readlimit )
  {
    $offset = $filesize - $readlimit;
  }
  return $offset;
}

# Parse DB/ASM logs
sub tfactlshare_parse_db_asm_alert
{
  my $tfa_home = shift;
  my $file = shift;
  my $db = shift;
  my $inst = shift;
  open(AF, "$file");
  my $ctime = "";
  my %mons = ( "01" => "Jan", "02" => "Feb", "03" => "Mar",
               "04" => "Apr", "05" => "May", "06" => "Jun",
               "07" => "Jul", "08" => "Aug", "09" => "Sep",
               "10" => "Oct", "11" => "Nov", "12" => "Dec");
  my $offset = tfactlshare_read_file_offset($tfa_home, $file);
  seek(AF, $offset, 0);
  while(<AF>)
  {
    chomp;
    if ( /^\w+ (\w+) (\d+) ([\d\:]+) (\d+)/ )
    { #Fri Jan 30 03:50:38 2015    
      $ctime = "$1/$2/$4 $3";
    }
     elsif ( /(\d+)-(\d+)-(\d+)T([\d\:]+)\./ )
    { #2015-02-02T20:00:45.731220+00:00
      $ctime = $mons{$2}."/$3/$1 $4";
    }
     elsif ( /Starting ORACLE instance/ )
    { # Startup
      tfactlshare_add2timeline($tfa_home, $ctime, "db.$db.$inst.startup", "$_", "INFO");
    }
     elsif ( /Shutting down instance/ )
    { # Shutdown
      tfactlshare_add2timeline($tfa_home, $ctime, "db.$db.$inst.shutdown", "$_", "INFO");
    }
     elsif ( /^(\w+) started with pid=\d+, OS id=(\d+)/ )
    { # GEN0 started with pid=5, OS id=1655
      tfactlshare_add2timeline($tfa_home, $ctime, "db.$db.$inst.$1.pid", "$2", "META");
    }
     elsif ( /^([\s\w]+)=(.*)/ || 
             /^(System name):\s+(.*)/ ||
             /^(Node name):\s+(.*)/ ||
             /^(Release):\s+(.*)/ ||
             /^(Version):\s+(.*)/ ||
             /^(Machine):\s+(.*)/ ||
             /^(VM name):\s+(.*)/ ||
             /^(ORACLE_HOME):\s+(.*)/
           )
    {
      my $key = $1;
      my $val = $2;
      $key =~ s/ //g;
      tfactlshare_add2timeline($tfa_home, $ctime, "db.$db.$inst.$key.value", $val, "META");
    }
     elsif ( /ORA-/ ||
             /Linux.*Error/ ||
             /IPC Send timeout detected. Sender: ospid.*/ ||
             /Direct NFS: channel id .* path .* to filer .* PING timeout/ ||
             /Direct NFS: channel id .* path .* to filer .* is DOWN.*/ ||
             /ospid: .* has not called a wait for .* secs/ ||
             /IPC Send timeout to .* inc .* for msg type .* from opid/ ||
             /IPC Send timeout: Terminating pid/ ||
             /Receiver: inst .* binc .* ospid/ ||
             /terminating instance due to error/ ||
             /terminating the instance due to error/ ||
             /Global Enqueue Services Deadlock detected/ ||
             /TNS-/ ||
             /Instance terminated by/ )
    { # ORA-, Errors in file, Linux.*Error, TNS-12535:, Instance terminated by
      tfactlshare_add2timeline($tfa_home, $ctime, "db.$db.$inst.error", $_, "ERROR");
    }
     elsif ( /NOTE: process .* initiating offline of disk/ ||
             /WARNING: cache read a corrupted block group/ ||
             /NOTE: a corrupted block from group FRA was dumped/
           )
    {
      tfactlshare_add2timeline($tfa_home, $ctime, "db.$db.$inst.error", $_, "WARNING");
    }

  }
  my $curpos = tell(AF);
  close(AF);
  tfactlshare_write_file_offset($tfa_home, $file, $curpos);
}

sub tfactlshare_parse_crs_alert
{   
  my $tfa_home = shift;
  my $file = shift;
  my $db = shift;
  my $inst = shift;
  open(AF, "$file");
  my $ctime = "";
  my %mons = ( "01" => "Jan", "02" => "Feb", "03" => "Mar",
               "04" => "Apr", "05" => "May", "06" => "Jun",
               "07" => "Jul", "08" => "Aug", "09" => "Sep",
               "10" => "Oct", "11" => "Nov", "12" => "Dec");
  my $offset = tfactlshare_read_file_offset($tfa_home, $file);
  seek(AF, $offset, 0);
  while(<AF>)
  {
    chomp;
    if ( /(\d+)-(\d+)-(\d+) ([\d\:]+)\./ )
    { #2015-02-02T20:00:45.731220+00:00
      $ctime = $mons{$2}."/$3/$1 $4";
    }

    if ( /CRS-5818:/ ||
             /CRS-5014:/ ||
             /CRS-8011:/ ||
             /CRS-8013:/ ||
             /CRS-1607:/ ||
             /CRS-1615:/ ||
             /CRS-1714:/ ||
             /CRS-1656:/ ||
             /PRVF-5305:/ ||
             /CRS-1601:/ ||
             /CRS-1610:/ ||
             /CRS-2765:/ ||
             /PANIC. CRSD exiting:/ ||
             /Fatal Error from AGFW Proxy:/ )
    { # error
      tfactlshare_add2timeline($tfa_home, $ctime, "crs.$hostname.error", "$_", "ERROR");
    }
     elsif ( /CRS-1603:/ ||
             /CRS-10051:/ ||
             /CRS-1625:/ )
    { # warning
      tfactlshare_add2timeline($tfa_home, $ctime, "crs.$hostname.error", "$_", "WARNING");
    }
  }
  my $curpos = tell(AF);
  close(AF);
  tfactlshare_write_file_offset($tfa_home, $file, $curpos);
}

sub tfactlshare_win32_check_if_admin
{
  eval 
  { 
    open my $fh, "> C:/windows/system32/perl_check_if_windows_admin" or die; 1; 
    close($fh);
  } && 1;
}

########
### NAME
###   tfactlshare_parse_pkgmanifest
###
### DESCRIPTION
###   This routine parses the ADR package manifest files
###
### PARAMETERS
###
### RETURNS
###
### NOTES
###
##########
sub tfactlshare_parse_pkgmanifest {
  my $manifestfile = shift;
  my @manifesttagsarray;
  my @retfiles;
  my $package_id;
  my $attrname;
  my $name;
  my $value;
  my $pfile_name;
  my $plocation;
  my $psize;
  my $pfile_time;
  my $pincident_id;
  my $padr_base;
  my $padr_home;

  tfactlshare_trace(5, "tfactl (PID = $$) " .
                    "tfactldiagcollect_parse_pkgmanifest " .
                    "ADR manifest file $manifestfile",
                    'y', 'y');
  if ( -e "$manifestfile" )
  {
    # Parse xml file
    @manifesttagsarray = tfactlshare_populate_tagsarray($manifestfile);
    #simulate error;
    #tfactlshare_error_msg(404, undef);
    #exit;

    # ==============================================================
    # Parse manifest, NOTE 0,0 is very important in order to get the
    # Attributes at root element
    # ==============================================================
    my @manifest = tfactlshare_get_element(\@manifesttagsarray, 0,0);

    foreach my $child (@manifest)
    {
      # Get the profile
      my $name = @$child[ELEMNAME];
      # Get attributes
      ($attrname , $package_id) = tfactlshare_get_attribute(
                   @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL],
                   "PACKAGE_ID" );
      ###print "\nName $name\n";
      ###print "\nPkg Id $package_id\n";

      # Get manifest children
      my @manifestList = tfactlshare_get_element( \@manifesttagsarray,
                        @$child[ELEMLEVEL]+1 , @$child[ELEMNDX] );
      foreach my $manifestchild (@manifestList)
      {
        $name = @$manifestchild[ELEMNAME];
        $value = @$manifestchild[ELEMVAL];

        # -----------------------------------         # ADR_DETAILS
        if ( $name eq "ADR_DETAILS" ) {
          # Get the details
          my @adrList = tfactlshare_get_element( \@manifesttagsarray,
                            @$manifestchild[ELEMLEVEL]+1 , @$manifestchild[ELEMNDX] );

          foreach my $adrdet (@adrList)
          {
            $name = @$adrdet[ELEMNAME];
            $value = @$adrdet[ELEMVAL];

            if ( $name eq "ADR_BASE" ) {
              $padr_base = $value;
            } elsif ( $name eq "ADR_HOME" ) {
              $padr_home = $value;
            }
          } # end foreach @adrList
        # -----------------------------------         # FILES
        } elsif ( $name eq "FILES" ) {
          # Get the files
          my @filesList = tfactlshare_get_element( \@manifesttagsarray,
                            @$manifestchild[ELEMLEVEL]+1 , @$manifestchild[ELEMNDX] );

          foreach my $files (@filesList)
          {
            $name = @$files[ELEMNAME];
            $value = @$files[ELEMVAL];

            # Get file details
            my @filesdetList = tfactlshare_get_element( \@manifesttagsarray,
                                @$files[ELEMLEVEL]+1 , @$files[ELEMNDX] );
            undef $pfile_name;
            undef $plocation;
            undef $psize;
            undef $pfile_time;
            undef $pincident_id;

            foreach my $filedet (@filesdetList)
            {
              $name = @$filedet[ELEMNAME];
              $value = @$filedet[ELEMVAL];
              ###print "name $name , value $value \n";

              # ---------------------
              if ( $name eq "FILE_NAME" ) {
                $pfile_name = $value;
              } elsif ( $name eq "LOCATION" ) {
                $plocation = $value;
              } elsif ( $name eq "SIZE" ) {
                $psize = $value;
              } elsif ( $name eq "FILE_TIME" ) {
                $pfile_time = $value;
              } elsif ( $name eq "INCIDENT_ID" ) {
                $pincident_id = $value;
              }
              # ---------------------
            } # end foreach @filesdetList
              $plocation =~ s/&lt;ADR_HOME\>//g;
              ###print "$pfile_name $plocation $padr_home\n";
              push @retfiles, [ $pfile_name, $plocation, $psize, $pfile_time, $pincident_id,
                                $padr_base, $padr_home, $package_id ];
          } # end foreach @filesList
        } # end if lc($name) eq "files"
        # -----------------------------------

      } # end foreach @manifestList
    } # end foreach @manifest
  } else {
    print "ADR Manifest file doesn't exists ...\n";
  } # end if exists $manifestfile 

  return @retfiles;
}

sub tfactlshare_parentDirectory{
  my @dirs   = File::Spec->splitdir($_[0]);       # parse directories
  pop @dirs;                                      # remove top dir
  my $newdir = File::Spec->catdir(@dirs);         # create new path
  return $newdir;
}

# parse srdcfile
########
### NAME
###   tfactlshare_parse_srdcfile
###
### DESCRIPTION
###   This routine parses SRDC metadata files
###
### PARAMETERS
###
### RETURNS
###
### NOTES
###
##########
sub tfactlshare_parse_srdcfile {
  my $srdcfile = shift;
  my @srdctagsarray;
  my $attrname;
  my $name;
  my $value;
  my %srdc = ();
  my $collection_id;

  tfactlshare_trace(5, "tfactl (PID = $$) " .
                    "tfactlshare_parse_srdcfile " .
                    "SRDC file $srdcfile",
                    'y', 'y');
  ### print "srdcfile $srdcfile\n";
  if ( -e "$srdcfile" )
  {
    # Parse xml file
    @srdctagsarray = tfactlshare_populate_tagsarray($srdcfile);

    # ==============================================================
    # Parse srdc file, NOTE 0,0 is very important in order to get the
    # Attributes at root element
    # ==============================================================
    my @collections = tfactlshare_get_element(\@srdctagsarray, 0,0);

    foreach my $child (@collections)
    {
      # Get the tag
      my $name = @$child[ELEMNAME];
      ###print "\nName $name\n";

      # Get collections children
      my @collectionsList = tfactlshare_get_element( \@srdctagsarray,
                            @$child[ELEMLEVEL]+1 , @$child[ELEMNDX] );
      foreach my $collectionschild (@collectionsList)
      {
        $name = @$collectionschild[ELEMNAME];
        $value = @$collectionschild[ELEMVAL];

        # -----------------------------------         # collection begin
        if ( $name eq "collection" ) {
          ($attrname , $collection_id) = tfactlshare_get_attribute(
                                         @$collectionschild[ELEMATTRNAME] , @$collectionschild[ELEMATTRVAL],
                                         "id" );
          ### print "collection_id $collection_id\n";

          # Get the collection details
          my @collectionList = tfactlshare_get_element( \@srdctagsarray,
                               @$collectionschild[ELEMLEVEL]+1 , @$collectionschild[ELEMNDX] );

          foreach my $collectiondet (@collectionList)
          {
            $name = @$collectiondet[ELEMNAME];
            $value = @$collectiondet[ELEMVAL];

            if ( $name eq "description" ) {				# description
									# ===========
              $srdc{$collection_id}->{description} = $value;
            } elsif ( $name eq "alias" ) {				# alias
									# =====
              $srdc{$collection_id}->{alias} = $value;
            } elsif ( $name eq "onevents" ) {				# onevents
									# ========
              # Get the events
              my @eventList = tfactlshare_get_element( \@srdctagsarray,
                              @$collectiondet[ELEMLEVEL]+1 , @$collectiondet[ELEMNDX] );
              foreach my $event (@eventList) {
                $name = @$event[ELEMNAME];
                $value = @$event[ELEMVAL];
                if ( $name eq "event" ) { 
                  my @eventinnerList = tfactlshare_get_element( \@srdctagsarray,
                                    @$event[ELEMLEVEL]+1 , @$event[ELEMNDX] );
                  my @events = ();
                  my @excludeevents = ();
                  foreach my $eventinner (@eventinnerList) {
                    $name = @$eventinner[ELEMNAME];
                    $value = @$eventinner[ELEMVAL];
                    if ( $name eq "onerror" ) { 			# onevents - onerror
                      push @events, $value; 
                    } elsif ( $name eq "excludeevent" ) {		# onevents - excludeeven
                      push @excludeevents, $value;
                    }
                  } # end foreach @eventinnerList
                  $srdc{$collection_id}->{events} = \@events;
                  $srdc{$collection_id}->{excludeevents} = \@excludeevents;
                  ### print "events @events\n";
                  ### print "ecludeevents @excludeevents\n";
                } # end if $name eq "event"
              } # end foreach @eventList
            } elsif ( $name eq "user_inputs" ) {			# user_inputs
									# ===========
              # Get the user inputs
              my @userinputsList = tfactlshare_get_element( \@srdctagsarray,
                                   @$collectiondet[ELEMLEVEL]+1 , @$collectiondet[ELEMNDX] );
              my %inputshash  = ();
              my $origvalue;
              my @userinputsarray = ();
              foreach my $userinput (@userinputsList) {
                $name = @$userinput[ELEMNAME];
                $value = @$userinput[ELEMVAL];
                $origvalue = $value;
                $value =~ s/USERINPUT\-//;
                my %retattribs = ();
                %retattribs = tfactlshare_get_hash_attributes(@$userinput[ELEMATTRNAME] , @$userinput[ELEMATTRVAL]);
                # Add user_inputs content
                $retattribs{"content"} = $origvalue;
                if ( not exists $inputshash{$value} ) {
                  $inputshash{$value} = \%retattribs;
                  push @userinputsarray, $value;
                }
              } # end foreach @userinputsList
              # Assign arrays
              $srdc{$collection_id}->{user_inputs} = \%inputshash;
              $srdc{$collection_id}->{user_inputs_array} = \@userinputsarray;

            } elsif ( $name eq "error_stack" ){     #error_stack
                                                    #==========
              
              #Get errors 
              my @errors = tfactlshare_get_element ( \@srdctagsarray,
                           @$collectiondet[ELEMLEVEL]+1, @$collectiondet[ELEMNDX] );
              my @errorstack;
              foreach my $error (@errors) {
                $name  = @$error[ELEMNAME];
                $value = @$error[ELEMVAL];
                my %retattribs = tfactlshare_get_hash_attributes(@$error[ELEMATTRNAME] , @$error[ELEMATTRVAL] );
                $retattribs{"content"} = $value;
                push @errorstack , \%retattribs;
              }
              $srdc{$collection_id}->{error_stack} =\@errorstack;


            } elsif ( $name eq "duration" ) {				# duration
									# ========
              if ( length $value && $value =~ /([0-9]+)[hH]/ ) {
                $srdc{$collection_id}->{duration} = $value;
              } else {
                $srdc{$collection_id}->{duration} = 1;
              }
            } elsif ( $name eq "awrduration" ){     #awrduration
                                                    #========
              if ( length $value && $value =~ /([0-9]+)[hH]/ ) {
                $srdc{$collection_id}->{awrduration} = $value;
              } else {
                $srdc{$collection_id}->{awrduration} = 1;
              }
            } elsif ( $name eq "clusterwide" ) {			# clusterwide
									# ===========
              $srdc{$collection_id}->{clusterwide} = $value;
            } elsif ( $name eq "filter_files" ) {			# filter_files
									# ============
              my @filterfilesinnerList = tfactlshare_get_element( \@srdctagsarray,
                                         @$collectiondet[ELEMLEVEL]+1 , @$collectiondet[ELEMNDX] );
              foreach my $filterfilesinner (@filterfilesinnerList) {
                $name = @$filterfilesinner[ELEMNAME];
                $value = @$filterfilesinner[ELEMVAL];
                if ( $name eq "filter_file_patterns" ) {		# filter_files - filter_file_patterns
                   my @ffpatternList = tfactlshare_get_element( \@srdctagsarray,
                                       @$filterfilesinner[ELEMLEVEL]+1 , @$filterfilesinner[ELEMNDX] );
                   my @filter_file_patterns = ();
                   foreach my $ffpattern (@ffpatternList) {
                     $name = @$ffpattern[ELEMNAME];
                     $value = @$ffpattern[ELEMVAL];
                     if ( $name eq "filter_file_pattern" ) {
                       push @filter_file_patterns, $value;
                     }
                   } # end foreach @ffpatternList
                   $srdc{$collection_id}->{filter_file_patterns} = @filter_file_patterns;
                   ### print "filter_file_patterns @filter_file_patterns\n";
                } elsif ( $name eq "filter_file_exclude_patterns" ) { 	# filter_files - filter_file_exclude_patterns
                   my @ffepatternList = tfactlshare_get_element( \@srdctagsarray,
                                        @$filterfilesinner[ELEMLEVEL]+1 , @$filterfilesinner[ELEMNDX] );
                   my @filter_file_exclude_patterns = ();
                   foreach my $ffepattern (@ffepatternList) {
                     $name  = @$ffepattern[ELEMNAME];
                     $value = @$ffepattern[ELEMVAL];
                     if ( $name eq "filter_file_exclude_pattern" ) {
                       push @filter_file_exclude_patterns, $value;
                     }
                   } # end foreach @ffpatternList
                   $srdc{$collection_id}->{filter_file_exclude_patterns} = @filter_file_exclude_patterns;
                   ### print "filter_file_exclude_patterns @filter_file_exclude_patterns\n";
                }
              } # end foreach @filterfilesinnerList
            } elsif ( $name eq "components" ) {                         # components
                                                                        # ============
              my @componentsList = tfactlshare_get_element( \@srdctagsarray,
                                   @$collectiondet[ELEMLEVEL]+1 , @$collectiondet[ELEMNDX] );
              my @components = ();
              foreach my $component (@componentsList) {
                $name  = @$component[ELEMNAME];
                $value = @$component[ELEMVAL];
                if ( $name eq "component" ) {
                  push @components, $value;
                }
              } # end foreach @componentsList
              $srdc{$collection_id}->{components} = \@components;
              ### print "components @components\n";
            } elsif ( $name eq "commands" ) {				# commands
									# ========
              my @scriptList = tfactlshare_get_element( \@srdctagsarray,
                               @$collectiondet[ELEMLEVEL]+1 , @$collectiondet[ELEMNDX] );
              my %scriptshash  = ();
              my %contenthash  = ();
              my @scriptsarray = ();
              foreach my $script (@scriptList) {
                $name  = @$script[ELEMNAME];
                $value = @$script[ELEMVAL];
                if ( $name eq "script" ) {				# commands - script
                   my %retattribs = ();
                   %retattribs = tfactlshare_get_hash_attributes(@$script[ELEMATTRNAME] , @$script[ELEMATTRVAL]);
                    my $scrname = $retattribs{"name"};
                   if ( not exists $scriptshash{$scrname} ) {
                     $scriptshash{$scrname} = \%retattribs;
                     push @scriptsarray, $scrname;
                   }
                   if ( not exists $contenthash{$scrname} ) {
                     $contenthash{$scrname} = $value; 
                     # print "content $value for $scrname _______________ \n";
                   }
                } # end if $name eq "script"
              } # end foreach @scriptList
              $srdc{$collection_id}->{scripts} = \%scriptshash;
              $srdc{$collection_id}->{scripts_content} = \%contenthash;
              $srdc{$collection_id}->{scripts_array} = \@scriptsarray;
            } elsif ( $name eq "runtime_flags" ) {			# runtime_flags
              $srdc{$collection_id}->{runtime_flags} = $value;
            }

          } # end foreach @collectionList
        } # end if $name eq "collection"
        # -----------------------------------         # collection end
      } # end foreach @collectionsList
    } # end foreach @collections
  } # end if -e "$srdcfile"

  ### print "ret collection_id $collection_id \n";
  return ($collection_id, %srdc);

} # end sub tfactlshare_parse_srdcfile 

########
### NAME
###   tfactlshare_retrieve_serobj 
###
### DESCRIPTION
###   This routine retrieves the serialized version
###   of a hash. 
###
### PARAMETERS
###
### RETURNS
###   TRUE  - Serialized hash object found
###   FALSE - Serialized hash object not found
###
### NOTES
###
##########
sub tfactlshare_retrieve_serobj {
  my $tfa_home   = shift;
  my $objref     = shift;
  my $serobjfile = shift;
  my $objtype    = shift;

  return FALSE if (not $SERIALIZEMETADATA);

  $serobjfile    = catfile($tfa_home,"internal",$serobjfile .".ser");

  if ( (not $objtype) || ($objtype ne "hash" && $objtype ne "array") ) {
    $objtype = "hash";
  }

  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_retrieve_serobj " .
                    "Trying to retrieve serobjfile $serobjfile (objtype=$objtype)...", 'y', 'y');

  if ( -e $serobjfile ) {
    if ( $objtype eq "hash" ) {
      %$objref = ();
      %$objref = %{retrieve($serobjfile)};
    } elsif ( $objtype eq "array" ) {
      @$objref = ();
      @$objref = @{retrieve($serobjfile)};
    }
    
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_retrieve_serobj " .
                      "Returning serialized version...", 'y', 'y');
    return TRUE;
  }
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_retrieve_serobj " .
                    "serobjfile not found.", 'y', 'y');
  return FALSE;
} # end sub tfactlshare_retrieve_serobj

########
### NAME
###   tfactlshare_store_serobj 
###
### DESCRIPTION
###   This routine stores the serialized version
###   of a hash. 
###
### PARAMETERS
###
### RETURNS
###
### NOTES
###
##########
sub tfactlshare_store_serobj {
  my $tfa_home   = shift;
  my $objref     = shift;
  my $serobjfile = shift;

  return FALSE if (not $SERIALIZEMETADATA);

  $serobjfile    = catfile($tfa_home,"internal",$serobjfile .".ser");

  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_retrieve_serobj " .
                    "Trying to store serobjfile $serobjfile ...", 'y', 'y');
  store $objref, $serobjfile;
  chmod(0644,$serobjfile);
  return;
} # end sub tfactlshare_store_serobj

########
### NAME
###   tfactlshare_multistore_serobj 
###
### DESCRIPTION
###   This routine stores the serialized version
###   of multiple array objects  
###
### PARAMETERS
###
### RETURNS
###
### NOTES
###
##########
sub tfactlshare_multistore_serobj {
  my $tfa_home   = shift;
  my $arrayref   = shift;
  my $serobjfile = shift;
  my @array      = @$arrayref;

  return if (not $SERIALIZEMETADATA);

  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_multistore_serobj " .
                    "Trying to multistore ...", 'y', 'y');
  for (my $ndx=0; $ndx<=$#array; ++$ndx) {
     tfactlshare_store_serobj($tfa_home, $array[$ndx], $serobjfile . "_$ndx");
  }

  return;
} # end sub tfactlshare_store_serobj


########
#### NAME
####  tfactlshare_isInventoryRunOnce 
####
#### DESCRIPTION
####   This routine returns 1 if inventory runs atleast once otherwise 0
####
###########

sub tfactlshare_isInventoryRunOnce {
  my $tfa_home = shift;
  my $status = 1;
  if ( ! -e catfile(getInventoryLocation($tfa_home, $hostname),"inventory.xml") ) {
    $status = 0;
  } 
  return $status;
}

# Adds Permission of a File
# Parameters : $modifiedPermission for eg. a+x -> 0111, $filename - path to the file
# No return value, file permissions are modified
sub tfactlshare_chmodAddPerm{
  my $modifiedPermission = shift;
  my $filename = shift;
  
  my $mode = (stat($filename))[2];
  $mode = $mode &07777;
  my $new_mode = $mode | $modifiedPermission;
  chmod ($new_mode, $filename);
}

################
## NAME  
##	tfactlshare_chmodRemovePerm	
## DESCRIPTION 
##	Remove execute permissions of non-executable files from a given dir
## INPUT
##	Directory
################
sub tfactlshare_chmodRemovePerm
{
  my $perm = shift;
  my $path = shift;
  my $file;
  my @files = ();
  my $mode;
  my $new_mode;
  my $matched = 0;

  if ( ! -e $path ) {
    print "ERROR: $path does not exists \n";
  }
  @files = osutils_getRecursiveFolderContents($path); 
  foreach ( @files ) {
    $file = $_;
    $matched = 0;
    if ( (/\/tfa_home\/jlib\/kafka\// ) && ( /\.properties$/ || /\.jar\.asc$/ || 
	  /\.jar$/ || /\/NOTICE$/ || /\/LICENSE/) ) {
      $matched = 1;
    }    
    elsif ( /\/tfa_home\/tomcat\/conf\// || /\/tfa_home\/tomcat\/webapps\/tfa\/css\// ||
            /\/tfa_home\/tomcat\/webapps\/tfa\/jet\// ) {
      $matched = 1;
    }
    elsif ( /\.xml$/ || /\.html$/ || /\.htm$/ || /\.sql$/ || /\.txt$/ || /\.jar$/ || /\.dat$/ 
	 || /\.prf$/ || /\.awk$/ || /\.json/ || /\.js$/ || /\.png/ ) {
      $matched = 1;
    }
    if ( $matched ) { 
      $mode = (stat($file))[2];
      $mode = $mode &07777;
      chmod ($mode & $perm, $file);
    }
  }
}

sub tfactlshare_get_cp_cmd{
  my $source = shift;
  my $destination = shift;

  my $file;
  my $folderName;
  my $newFile;
  my $cmd;

  if ( $IS_WINDOWS ){
    if((-f $source) && (-d $destination)){
      $file = basename($source);
      $source = dirname($source);
      $destination = $destination;
      $cmd = "robocopy $source $destination $file /NFL /NDL /NJH /NJS /nc /ns /np";
    }elsif((-d $source) && (-d $destination)){
      $folderName = basename($source);
      $destination = catdir($destination,$folderName);
      $cmd = "robocopy $source $destination /MIR /S /E /NFL /NDL /NJH /NJS /nc /ns /np";
    }else{
      $file = basename($source);
      $newFile = basename($destination);
      $source = dirname($source);
      $destination = dirname($destination);
      $cmd = "robocopy $source $destination $file /NFL /NDL /NJH /NJS /nc /ns /np; $MV ".catfile($destination,$file)." ".catfile($destination,$newFile);    
    }
  }else{
    $cmd = "$CP $source $destination";
  } 

  return $cmd;
}

########
## NAME
##   tfactlshare_look4regex
##
## DESCRIPTION
##   Looks for a regex in the given input file
##
## PARAMETERS
##   $inpfile  - Input file
##   $regex    - Regular expression
##
## RETURNS
##   @outarray - Output array
#########
sub tfactlshare_look4regex {
  my $inpfile  = shift;
  my $regex    = shift;
  my @lines    = (); 

  @lines = split /\n/ , tfactlshare_cat($inpfile);
  @lines = grep { $_ =~ s/$regex/$1/i} @lines;  
  return @lines;
}

########
## NAME
##   tfactlshare_look4regexarr
##
## DESCRIPTION
##   Looks for a regex in the given input file
##
## PARAMETERS
##   $inparr   - Input array
##   $regex    - Regular expression
##
## RETURNS
##   @outarray - Output array
#########
sub tfactlshare_look4regexarr {
  my @inparr   = shift;
  my $regex    = shift;

  @inparr = grep { $_ =~ s/$regex/$1/} @inparr;
  return @inparr;
}

########
## NAME
##   tfactlshare_cat
##
## DESCRIPTION
##   cat file
##
## PARAMETERS
##   $filename
##
## RETURNS
##   String representing file contents
#########
sub tfactlshare_cat {
  my $filename = shift;
  my $content = "";
  
  #tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_cat " .
  #                  "filename $filename", 'y', 'y');
  open my $fh, '<', $filename or $content="file not found\n";
  while (<$fh>) {
    $content .= $_;
  }
  close $fh;

  #tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare tfactlshare_cat " .
  #                  "Returning: $content\n", 'y', 'y');
  return $content;
}

########
## NAME
##   tfactlshare_findrep
##
## DESCRIPTION
##   Find and replace keeping metacharacters into account
##
## PARAMETERS
##   str - String where a substring needs to be found and replaced
##   find - String that needs to found in str
##   replace - String that needs to replaced for matched substring
##
## RETURNS
##   ...
#########
sub tfactlshare_findrep{
	my $str = shift;
	my $find = shift;
	my $replace = shift;
	$find = quotemeta $find; # escape regex metachars if present

	$str =~ s/$find/$replace/g;
	return $str;
}

sub tfactlshare_getPerl{
  my $tfa_home = shift;
  my $PERL = "perl";
  my $paramfile = tfactlshare_getSetupFilePath($tfa_home);
  if(-f $paramfile){
     $PERL=tfactlshare_getConfigValue(catfile($paramfile),"PERL");
  }
  return $PERL if (length $PERL);
  return "perl";
}

########
## NAME
##   tfactlshare_getLatestPerl
##
## DESCRIPTION
##   This routine returns the latest perl binary
##   amount multiple options.
##
## PARAMETERS
##   @perlarr - Array containing the candidate perls.
##
## RETURNS
##   Latest perl binary.
#########
sub tfactlshare_getLatestPerl {
  my @defperl = shift;
  my $perl    = "";

  if ( @defperl ) {
    if ( $#defperl > 0 ) {
      my $ndx = 0;
      my $version    = "";
      my $auxversion = "";
      foreach my $cnt ( 0..$#defperl ) {
         my $path = $defperl[$cnt];
         my @versionarray = split /\n/, `$path --version 2>&1`;
         foreach my $line ( @versionarray ) {
           if ( $line =~ /.*This is perl, v(.*) built for MSWin32.*/ ) {
             $auxversion = $1;
             if ( not length $version ) {
               $version = $auxversion;
             } else {
               # Newer version located
               my $d1;
               my $d2;
               my $d3;
               my $d1_;
               my $d2_;
               my $d3_;
               if ( $version =~ /([0-9]+)\.([0-9]+)\.([0-9]+)/ ) {
                 $d1 = $1;
                 $d2 = $2;
                 $d3 = $3;
               }
               if ( $auxversion =~ /([0-9]+)\.([0-9]+)\.([0-9]+)/ ) {
                 $d1_ = $1;
                 $d2_ = $2;
                 $d3_ = $3;
               }
               if ( ($d1_ == $d1 && $d2_ > $d2) || ($d1_ > $d1) ||
                    ($d1_ == $d1 && $d2_ == $d2 && $d3_ > $d3)  ) {
                 $version = $auxversion;
                 $ndx = $cnt;
               }
             } # end if not length $version
           } # end if line =~ /.*This is perl, v
         } # end foreach @defperl
      } # end foreach @defperl
      $perl = $defperl[$ndx];
    } else {
      $perl = $defperl[0];
    } # end if $#defperl > 0
  } # end if @defperl
  return $perl;
} # end sub tfactlshare_getLatestPerl

sub tfactlshare_uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

########
# NAME
#   tfactlshare_trim_nodelist
#
# DESCRIPTION
#   This function removes leading spaces from each node
#
# PARAMETERS
#   node_list     (IN) - list of nodes 
#
# RETURNS
#   returns node list as a string
########   
sub tfactlshare_trim_nodelist {
  my $node_list = shift;
  my @nodes = split(/\,/,$node_list);
  my $node_list_new = "";
  my $node;
  foreach my $rec ( @nodes ) {
    $node = trim ($rec);
    if ( $node ) { 
      if ( $node_list_new ) {
        $node_list_new = $node_list_new.",".$node;
      }
      else {
	$node_list_new = $node;
      } 
    }
  }
  return $node_list_new;
}

########

sub tfactlshare_autostart_tomcat_in_dsc
{
  my $tfa_home = shift;
  my $keypass = tfactlshare_generate_tomcat_keystore($tfa_home);
  my $serverxml = "$tfa_home/tomcat/conf/server.xml";
  if ( ! -f $serverxml )
  {
    my $rweb_port = 7070;
    my $rweb_port_ssl = 7071;
    my $rweb_max = 9000;
    my $pstate = 0;
    for(my $i = $rweb_port; $i <= $rweb_max; $i++ )
    {
      if ( tfactlshare_is_port_free($i) )
      {
        if ( $pstate == 0 )
        {
          $rweb_port = $i;
          $pstate = 1;
        }
         elsif ( $pstate == 1 )
        {
          $rweb_port_ssl = $i;
          $pstate = 2;
          last;
        }
      }
    }

    # write the port it will run to internal rweb_port.txt no need for clusterwide transfer of this file?
    my $rwp = catfile($tfa_home,"internal","rweb_port.txt");
    open(WF,">$rwp");
    print WF $rweb_port;
    close(WF);
    my $rwp_ssl = catfile($tfa_home,"internal","rweb_port_ssl.txt");
    open(WF,">$rwp_ssl");
    print WF $rweb_port_ssl;
    close(WF);

    my @kv = ( "TFA_HOME", $tfa_home, 
               "TFA_NON_SSL_PORT", $rweb_port, 
               "TFA_SSL_PORT", $rweb_port_ssl, 
               "TFA_TOMCAT_KEYSTORE_PASSWORD", $keypass);
    my $serverxml = "$tfa_home/tomcat/conf/server.xml";
    my $tmp_serverxml = "$tfa_home/tomcat/conf/server.xml.tmpl";
    tfactlshare_update_server_xml($tmp_serverxml,$serverxml,@kv);
  }
  tfactlshare_start_tomcat($tfa_home);
  
}

sub tfactlshare_is_port_free
{
  my $port = shift;
  my @out = `netstat -an | grep -w '$port ' | grep 'LISTEN'`;
  chomp(@out);
  return 0 if ( $out[0] =~ /$port/ );
  return 1;
}

sub tfactlshare_get_random_key
{
  my $Cpassword;
  $Cpassword = tfactlshare_generate_password(16);
  return $Cpassword;
}

sub tfactlshare_generate_tomcat_keystore
{
  my $tfa_home = shift;
  my $internal_dir = catfile($tfa_home,"tomcat","internal");
  if(! -d $internal_dir) {
  	mkdir($internal_dir);
  }
  my $keyfile = catfile($internal_dir,".tomcat_keystore");
  my $keypass = tfactlshare_get_random_key();
  my $rcv_pass = tfactlshare_get_receiver_keystore_pass($tfa_home);

  my $keytool = "";
  my $paramfile = catfile ($tfa_home, "tfa_setup.txt");
  my $java_home = get_java_home ($tfa_home, $paramfile);
  my $keytool = catfile($java_home, "bin", "keytool");

  if (! -f $keyfile ) { # generate tomcat keystore if it doesn't exist already

  	my $cmd_out = qx($keytool -genkey -alias tomcat -keyalg RSA -dname \"cn=ORACLE CORPORATION, ou=ST, o=ORACLE CORPORATION, l=REDWOOD SHORES, st=CALIFORNIA, c=US\" -keysize 2048 -validity 18263 -keystore $keyfile -keypass \"$keypass\" -storepass \"$keypass\" 2>&1);
  	chmod(0600, $keyfile);	
  } else { # else get keystore passwd from server.xml
  	  if( -f "$tfa_home/tomcat/conf/server.xml" ) {
  	  	$keypass = tfactlshare_get_keypass_from_server_xml($tfa_home);
  	  }
  }
    
  my $args = $tfa_home . " " . $keypass . " tomcat";
  my $class = "oracle.rat.tfa.util.WriteSSLReceiverConfig";
  my $command = buildJava($java_home, $tfa_home, $class, $args);
  `$command`;
  
  return $keypass;
}

## returns receiver keystore password
sub tfactlshare_get_receiver_keystore_pass
{
  my $tfa_home = shift;
  my $val;
  my $rcvfile = catfile($tfa_home,"receiver","internal","r.ssl.properties");
  open (RF, $rcvfile) || die "Cant open $rcvfile.\n";
  while(<RF>)
  {
    chomp;
    if ( /^serverKeyStorePass=(.*)/ )
    {
      $val = $1;
      last;
    }
  }
  return $val;
}

sub tfactlshare_get_keypass_from_server_xml
  {	
   my $tfa_home = shift;
    my $serverxml = "$tfa_home/tomcat/conf/server.xml";
    open(SF, $serverxml);
    while(<SF>)
    {
      chomp;
      return $1 if ( /keystorePass=\"(.*)\"/ );
    }
    close(SF);
 }

sub tfactlshare_update_server_xml
{
  my $ip_file = shift;
  my $out_file = shift;
  my @kv = @_;
  my %kvhash = ();

  for(my $i = 0; $i <= $#kv; $i++ )
  {
    $kvhash{$kv[$i]} = $kv[$i+1];
    $i++;
  }
  open(R1F, $ip_file);
  open(W1F, ">$out_file");
  while(<R1F>)
  {
    chomp;
    foreach my $k (keys %kvhash)
    {
      my $v = $kvhash{$k};
      s|$k|$v|g;
    }
    print W1F "$_\n";
  }
  close(R1F);
  close(W1F);
  system("$CHMOD 600 $out_file");
}

sub tfactlshare_update_rprop
{
  my $tfa_home = shift;
  my $key = shift;
  my $val = shift;
  my $actionargs = "key=$key~val=$val";
  my $actionmessage = "$localhost:resetwebadmin:$localhost";
  $actionmessage = "$actionmessage~$actionargs";
  dbg(DBG_WHAT, "Running addReceiver through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$actionmessage);
  dbg(DBG_VERB, "$command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
     #print "$line\n";
     if ( $line eq "SUCCESS" ) {
          print "webadmin successful\n";
            dbg(DBG_NOTE, "webadmin change successfull\n\n");
         return SUCCESS;
     }
     elsif ($line eq "DONE"){
        print "Success\n";
     } else {
         print "FAIL\n";
     }
  }
  return FAILED;
}

## starting the receiver process, similar to tfactlshare_start_tomcat function
## creates a non root user, registers it to TFA and starts the receiver process as that user
#######
# NAME
#  tfactlshare_start_TFARMain 
# DESCRIPTION
#   This function starts TFARMain daemon as non-root user like oratfa
# PARAMETERS
#   tfa_home
# RETURNS
#  none
# NOTES/USAGE
#
#########

sub tfactlshare_start_TFARMain
{
  my $tfa_home = shift;
  my $localhost = tolower_host();
  my $actionmessage;
  my $command;
  my $line;
  my $status = 0;
  my $tfa_setup_file = catfile($tfa_home,"tfa_setup.txt");
  my $java_home = get_java_home ($tfa_home, $tfa_setup_file);
  my $java = catfile("$java_home","bin","java");
  my $rconfig = catfile($tfa_home, "receiver", "internal", "rconfig.properties");
  my $tfauser = tfactlshare_getConfigValue($rconfig,"r.user");
  my $userexists = `id -u $tfauser 2>&1`;
  chomp($userexists);
  if ( $userexists !~ /\d+/) {
    my $cmd_out = qx(/usr/sbin/useradd -r -s /sbin/nologin -g nobody $tfauser 2>&1);
    if($cmd_out ne "") {
      $cmd_out = qx(/usr/sbin/useradd -s /bin/sh -g nobody $tfauser 2>&1);
    }
    if($cmd_out ne "") {
		print "Failed adding user: $?";
	}
  }

  ## add new user to TFA Access List
  $actionmessage = "$localhost:addtfauser:-c:$tfauser:USER:true\n";
  $command = buildCLIJava($tfa_home,$actionmessage);
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output ) {
    if ($line =~ /TFA is not yet secured to run all commands/) {
      tfactlshare_error_msg(103, undef) ;
      exit 1;
    }
  }

  my $tfar_home = catfile("$tfa_home","receiver");
  my $cmd_out = qx($CHOWN -R $tfauser:root $tfar_home 2>&1);
  if($cmd_out ne "") {
  	print "Failed to change $tfar_home permissions: $cmd_out\n";
  }
  my $logdir = catfile($tfa_home,"log");
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "INSTALL_TYPE");
  if( $install_type eq "GI") {
  	my $oracle_base = get_oracle_base($tfa_home);
  	my $hostname = tolower_host();
  	$logdir = catfile($oracle_base,"tfa",$hostname,"log");
  }
  chmod(0751,$logdir) or print "Failed to change $logdir permissions: $!";
  my $rcv_logdir = catfile($logdir,"receiver");
  mkdir($rcv_logdir);
  $cmd_out = qx($CHOWN $tfauser:root $rcv_logdir 2>&1);
  if($cmd_out ne "") {
  	print "Failed while running chown for $rcv_logdir: $cmd_out\n";
  }

  my $rcv_start = "$java -Djavax.net.debug=handshake oracle.rat.tfa.TFARMain $tfa_home";
  #set r.repository in config file
  my $tfa_base = tfactlshare_get_rbase($tfa_home);
  my $repository = catfile($tfa_base,"receiver");
  if ( ! -d "$repository" ) {
    mkpath($repository);
  }
  tfactlshare_updateTFAConfig($rconfig, "r.host", $hostname);
  $cmd_out = qx(perl -p -i -e 's%r.repository=NONE%r.repository=$tfa_base%' $rconfig 2>&1);
  if($cmd_out ne "" ) {
	print "Failed to update repository in $rconfig: $cmd_out\n";
  }
  $cmd_out = qx($CHOWN -R $tfauser:root $repository 2>&1);
  if($cmd_out ne "" ) {
	print "Failed to set ownership of $repository to $tfauser: $cmd_out\n";
  }
  chmod(0751,catfile($tfa_home,"jlib")) or print "couldn't change permissions of jlib\n";
  $cmd_out = qx($CHMOD 0644 $tfa_home/jlib/* 2>&1);
  if($cmd_out ne "" ) {
	print "couldn't change permissions of RATFA.jar: $cmd_out\n";
  }
  chmod(0644,catfile($tfa_home,"tfa_setup.txt")) or print "couldn't change permissions of tfa_setup.txt\n";
  #bin/tfaosutils.pl used by tomcat
  $cmd_out = qx($CHMOD 0755 $tfa_home/bin/tfaosutils.pl 2>&1);
  my $statusfile = catfile("$tfa_home","receiver","internal","receiver_runstatus.txt");
  $command = "echo run > $statusfile";
  system($command);
  tfactlshare_start_bgprocess($tfa_home, "receiver", $rcv_start, "","",$tfauser);
  sleep(5);
  #register client with receiver
  my $rclient = tfactlshare_getConfigValue($rconfig,"r.cname");
  my $pass = tfactlshare_generate_password(8);
  
  tfactlshare_addCollector("client",$rclient,$pass,1,"add",$tfa_home,"y\[1\[\[tfarcv1", "add","n","dummy");
}

sub tfactlshare_start_tomcat
{
  my $tfa_home = shift;
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");
  my $crs_home;
  # it will pick jars from tfa_home or grid_home depending on the type of installation
  if ( $install_type eq "GI" ) {
    $crs_home = get_crs_home($tfa_home);
  }
  else {
    $crs_home = $tfa_home;
  }
  
  my $rwp = catfile($tfa_home,"internal","rweb_port.txt");
  my $port = `cat $rwp`;
  my $localhost=tolower_host();
  my $tfa_setup_file = catfile($tfa_home,"tfa_setup.txt");
  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  my $tomcat = catfile($tfa_base,"receiver",$localhost,"logs","tomcat-logs");

  if ( ! -d "$tomcat" )
  {
    system("$MKDIR -p $tomcat");
  }
  my $rconfig = catfile($tfa_home, "receiver", "internal", "rconfig.properties");
  my $tfauser = tfactlshare_getConfigValue($rconfig,"r.user");
  my $cmd_out = qx($CHOWN -R $tfauser:root $tfa_home/tomcat 2>&1);
  if($cmd_out ne "") {
  	print "Failed while running chown for $tfa_home/tomcat: $cmd_out\n";
  }
  $cmd_out = qx($CHOWN $tfauser:root $tomcat 2>&1);
  if($cmd_out ne "") {
  	print "Failed while running chown for $tomcat: $cmd_out\n";
  }
  my $tom_log_conf = catfile($crs_home, "tomcat","conf","logging.properties");
  my $tom_log_conf_tmp = catfile($tfa_home, "tomcat","conf","logging.properties");
  
  my @kv1  = ( "catalina.base","tfa.repos");
  tfactlshare_update_server_xml($tom_log_conf,$tom_log_conf_tmp,@kv1);


  my $java_home = get_java_home ($tfa_home, $tfa_setup_file);
  my $java = catfile("$java_home","bin","java");
  my $ann_jar = catfile("$crs_home","tomcat","lib","annotations-api.jar");
  my $catalina_jar = catfile("$crs_home","tomcat","lib","catalina.jar");
  my $api_jar = catfile("$crs_home","tomcat","lib","tomcat-api.jar");
  my $jni_jar = catfile("$crs_home","tomcat","lib","tomcat-jni.jar");
  my $util_jar = catfile("$crs_home","tomcat","lib","tomcat-util.jar");
  my $bootstrap_jar = catfile("$crs_home","tomcat","lib","bootstrap.jar");
  my $servlet_jar = catfile("$crs_home","tomcat","lib","servlet-api.jar");
  my $coyote_jar = catfile("$crs_home","tomcat","lib","tomcat-coyote.jar");
  my $juli_jar = catfile("$crs_home","tomcat","lib","tomcat-juli.jar");
  my $scan_jar = catfile("$crs_home","tomcat","lib","tomcat-util-scan.jar");
  my $jaspic_jar = catfile("$crs_home","tomcat","lib","jaspic-api.jar");

  my $classpath = "$ENV{CLASSPATH}$PSEP$ann_jar$PSEP$catalina_jar$PSEP$api_jar$PSEP$jni_jar$PSEP$util_jar$PSEP$bootstrap_jar$PSEP$servlet_jar$PSEP$coyote_jar$PSEP$juli_jar$PSEP$scan_jar$PSEP$jaspic_jar"; 
  $ENV{"CATALINA_HOME"} = catfile($tfa_home, "tomcat");
  $ENV{"CATALINA_BASE"} = catfile($tfa_home, "tomcat");
  $ENV{CLASSPATH} = $classpath;
  my $CATALINA_HOME = $ENV{"CATALINA_HOME"};
  my $CATALINA_BASE = $ENV{"CATALINA_BASE"};
  $cmd_out = qx($CHMOD -R 0750 $tfa_home/tomcat/webapps 2>&1);
  my $tom_start = "$java -Dcatalina.home=$CATALINA_HOME -Dcatalina.base=$CATALINA_BASE -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager -Djava.util.logging.config.file=$tfa_home/tomcat/conf/logging.properties -Dtfa.repos=$tomcat org.apache.catalina.startup.Bootstrap";
  tfactlshare_start_bgprocess ($tfa_home, "tomcat", $tom_start, "", "$tomcat/out.log.$$",$tfauser);
  my @out = `ps -ef |grep org.apache.catalina.startup.Bootstrap |grep tfa_home|grep -v grep | sed 's/^ *//' |awk '{print $2}' > $tfa_home/tomcat/.tomcat_pidfile`;

}

#tfactlshare_start_bgprocess <tfa_home> <process name> <command> <options> <out file> <user>
sub tfactlshare_start_bgprocess
{
  my $tfa_home = shift;
  my $name = shift;
  my $cmd = shift;
  my $opts = shift;
  my $outfile = shift;
  my $user = shift;
  my $lckfile = catfile($tfa_home,$name,"internal", ".$name.lck");
  my $retVal = 0;
  my $file = catfile($tfa_home,"debug.txt");
  dbg(DBG_WHAT, "starting $name");
  $outfile = "/dev/null" if ( ! $outfile );

  my $start_process = 1;
  if ( -f $lckfile )
  {
	my $pid = `cat $lckfile`;
    chomp($pid);
    if ( $pid )
    {
      my $exists = kill 0, $pid;
      if ( $exists )
      {
        dbg(DBG_WHAT,"$name is already running with pid : $pid\n");
        if($pid == 0 ) {
          $start_process = 1;
        } else {
          $start_process = 0;
        }
      }
    }
  }
  if ( $start_process == 1 )
  {

    # Check that java permissions are set
    my $java_home = get_java_home ($tfa_home);
    my $java = catfile("$java_home","bin","java");
 
    my $loop_cnt = 0 ;
    while ( $loop_cnt < 20 )
    { # Wait for 20 seconds for permissions to be changed
      my $mode = sprintf '%04o', (stat $java)[2] & 00007;
      my $mode_num = $mode + 0;
      if ( $mode_num == 0 )
      { # Other user does not have permission to run java
        tfactlshare_trace(3, "tfactl (PID = $$) startService " .
                      "$loop_cnt Waiting for permissions on $java",
                     'y', 'y');
        $loop_cnt ++;
        sleep(1);
      }
       else
      {
        last;
      }
    }

    chmod(0751, $tfa_home) or print "couldn't change permission for $tfa_home\n";
    my $shfile = catfile($tfa_home,$name,"internal",".start_$name.sh");
    open(C1F, ">$shfile") or print "Can't write $shfile for write.\n";
    print C1F "#!/bin/sh\n";
    print C1F "CLASSPATH=\$CLASSPATH:$ENV{CLASSPATH}\n";
    print C1F "export CLASSPATH\n";
    print C1F "umask 0077\n";
    print C1F "\n$cmd $opts >$outfile 2>&1 &\n";
    print C1F "echo \$!\n";
    close(C1F);
    chmod(0755,$shfile) or print "Failed to change permission for $shfile\n";

    my $npid = fork();
    my @cpid;
    if ( $npid == 0 )
    {
      $retVal = 1; #In child
      if($user eq "root") {
    	@cpid = `$shfile`;
      } else {
#TODO Check this code.
         if ( $osname eq "SunOS" ) {
      	   @cpid = `su $user -c $shfile`;
         } else {
      	   @cpid = `su -s /bin/sh $user -c $shfile`;
        }
      }
      chomp(@cpid);
      system("echo $cpid[0] > $lckfile");
      dbg(DBG_WHAT,"Started $name with pid : $cpid[0]\n");
      print "Started $name with pid : $cpid[0]\n";
      exit;
    }
  }

  return $retVal;
}

########
# NAME
#  tfactlshare_stop_TFARMain 
# DESCRIPTION
#   This function stops TFARMain service which is spawned by TFAMain as non root user
# PARAMETERS
#   tfa_home
# RETURNS
#  none
# NOTES/USAGE
#
########
sub tfactlshare_stop_TFARMain
{
  my $tfa_home = shift;
  my $rcv_lck = catfile($tfa_home,"receiver","internal", ".receiver.lck");
  if(! -r $rcv_lck) {
  	print "TFA Receiver is not running\n";
  	return;
  }
  my $pid = tfactlshare_cat($rcv_lck);
  unlink($rcv_lck) or warn "Could not unlink $rcv_lck: $!";
  chomp($pid);
  if ( $pid ) {
    my $cnt;
    my $retvalue;
    $cnt = kill 0, $pid;
    my $statusfile = catfile("$tfa_home","receiver","internal","receiver_runstatus.txt");
	my $command = "echo stop > $statusfile";
	system($command);
    for (my $i = 0 ; $i < 5 ; $i++) {
      $retvalue = kill 0, $pid;
      if ( $retvalue == 1 ) {
         sleep(3);	
      }
      else {
        last;
      }	
    }
    $retvalue = kill 0, $pid;
    if ( $retvalue != 0 ) {
      $cnt = kill 9, $pid;	
    }   
    print "Successfully stopped TFA Receiver process ($cnt)\n";
  }
}

sub tfactlshare_isReceiverRegistered
{
  my ($tfa_home, $receivername) = @_;
  $receivername = trim($receivername);
  if ($receivername eq "all" || $receivername eq "local") {
    return 1;
  }
  my $localhost=tolower_host();
  my $message ="$localhost:printreceivers";
  dbg(DBG_VERB, "Running Check through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$message);
  my $line;
  #Run the command in local node and work on output
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output ) {
    dbg(DBG_WHAT,"We got : $line\n");
    $line =~ s/Receiver Name : //;
    if (trim($line) eq trim($receivername)) {
      return SUCCESS;
    }
  }
  return FAILED;
}

sub tfactlshare_isAnyReceiverRegistered
{
  my ($tfa_home) = @_;
  my $localhost=tolower_host();
  my $message ="$localhost:printreceivers";
  dbg(DBG_VERB, "Running Check through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$message);
  my $line;
  #Run the command in local node and work on output
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output ) {
    dbg(DBG_WHAT,"We got : $line\n");
    if ($line =~ /Receiver Name/) {
      return SUCCESS;
    }
  }
  return FAILED;
}

sub tfactlshare_isAnyCollectorRegistered
{
  my ($tfa_home) = @_;
  my $localhost=tolower_host();
  my $message ="$localhost:printcollectors:true";
  dbg(DBG_VERB, "Running Check through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$message);
  my $line;
  #Run the command in local node and work on output
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output ) {
    dbg(DBG_WHAT,"We got : $line\n");
    if ($line =~ /Collector Name/) {
      return SUCCESS;
    }
  }
  return FAILED;
}

# Setup tfactlshare_setup_metadata if it does not exists.
sub tfactlshare_setup_metadata
{
  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  my $tfa_base2 = dirname($tfa_base);
  my $hostname = tolower_host();
  my $outputdir = catfile($tfa_base2,$hostname,"output","metadata");

  if ( ! -d "$tfa_base2/$hostname/output/metadata" )
  {
    mkpath($outputdir);
    my $rwp = catfile($tfa_home,"receiver","internal","rconfig.properties");
    if ( -w "$rwp" ) {
      tfactlshare_updateTFAConfig($rwp, "r.tfar_monitor.output", $outputdir);
    }
  }

}

sub tfactlshare_addReceiver_wrapfile
{
  my $tfa_home = shift;
  my $rconfigfile = shift;
  my $rconfigout = catfile($tfa_home, "internal", "rconfig.out");

  my $crsup = 0;
  my $crshome = get_crs_home($tfa_home);
  if ( $crshome ) {
    $crsup = 1 if ( osutils_isCRSRunning($crshome) );
  }
  if ( $crsup == 1 )
  {
    $ENV{ORACLE_HOME} = $crshome;
    my $ORACLE_HOME = $crshome;
    $ENV{LD_LIBRARY_PATH} = catfile($crshome, "lib");
    system("$ORACLE_HOME/jdk/bin/java -cp $tfa_home/jlib/RATFA.jar:$ORACLE_HOME/jlib/clscred.jar:$ORACLE_HOME/jlib/srvm.jar oracle.rat.tfa.uc.TFAManageCredentials -import $rconfigfile  -out $rconfigout");
    if ( -f "$rconfigout" )
    {
        # tfactl receiver add host:port
      my $hosts = "";
      my $key = "";
      my $cname = "";
      my $guid = "";
      open(RCF, "$rconfigout");
      while(<RCF>)
      {
        chomp;
        if ( /SERVER_HOSTS\>([^\<]+)\<\/SERVER_HOSTS.*CLIENT_NAME\>(.*)\<\/CLIENT_NAME.*CLIENT_GUID\>(.*)\<\/CLIENT_GUID.*CLIENT_KEY\>([^\<]+)\<\/CLIENT_KEY/ )
        {
            $hosts = $1;
            $cname = $2;
            $guid = $3;
            $key = $4;
        }
      }
      close(RCF);
      unlink("$rconfigout");
      if ( $hosts && $key )
      {
          my @hosts_arr = split(/,/, $hosts);
          #Right now we don't know that on which node of R cluster the CRED file generated
          #So go through each node till it gets succeed
          my $addr_status;
          foreach my $h ( @hosts_arr ) {
            $addr_status = tfactlshare_addReceiver($tfa_home, $h, 1, -1,$key,"$cname,$guid");
            next if (!$addr_status);
            system("$tfa_home/bin/tfactl producer stop");
            system("$tfa_home/bin/tfactl producer start");
            last;
          }
      }
    }
  }
}

sub tfactlshare_addReceiver
{
  my ($tfa_home, $receiver, $is_commandline, $remoteport,$rpass, $cdetails) = @_;
  my $receivername = $receiver;
  my $localhost=tolower_host();
  my $cname = "";
  my $guid = "";
  if ( $cdetails =~ /(.*),(.*)/ )
  {
    $cname = $1;
    $guid = $2;
  }
  if ( ! $cname )
  {
    $cname = $localhost;
    $guid = $localhost;
  }

  dbg(DBG_WHAT,  "In tfactlshare_addReceiver for :: $receiver\n");
  #Check whether TFA Main is running or not on receiver NODE
  if (isTFARunning($tfa_home) == FAILED) {
        exit 0;
  }
  if ($receiver =~ /\./) {
    my @values = split(/\./, $receiver);
    $receiver = @values[0];
  }
  #if (tfactlshare_isReceiverRegistered($tfa_home, $receiver)) {
  #  if ($is_commandline == 1) {
  #     tfactlshare_error_msg(505,undef);
  #  }
  #  return FAILED;
  #}
  if ($is_commandline == 1) {
  my $sudo_user = $ENV{SUDO_USER};
  my $sudo_command = $ENV{SUDO_COMMAND};

  if ( $sudo_user && $sudo_command =~ /tfactl/ ) {
      tfactlshare_error_msg(507,undef);
      return FAILED;
    }
  }
  my @parts = split /:/,$receiver;
  my $rnode = $parts[0];
  my $rport = $parts[1];

  my $file = catfile($tfa_home,"internal","rcollectorkey.store");
  if( -e $file) {
    my $fileout = "$file"."bkp";
    open INP, "$file" or die $!;
    open OUT, ">>$fileout" or die $!;
    my @lines = <INP>;
    foreach my $rec (@lines) {
      if($rec =~ /$rnode/){
      }
      else {
        print OUT "$rec";
      }
    }
    close(OUT);
    close(INP);
    copy($fileout,$file);
    host("$RM -f $fileout");
  }
  open OUT,">>$file" or die $!;
  print OUT "$rnode=$rpass\n";
  close(OUT);
  host("$CHMOD 600 $file");
  chomp($roption);
  my $actionargs = "receiver=$rnode~is_commandline=$is_commandline~pollport=$rport~onhost=-1~remoteport=-1~cname=$cname~guid=$guid";
  my $actionmessage = "$localhost:addreceiver:$receiver";
  $actionmessage = "$actionmessage~$actionargs";
  dbg(DBG_WHAT, "Running addReceiver through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$actionmessage);
  dbg(DBG_VERB, "$command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
     #print "$line\n";
     if ( $line eq "SUCCESS" ) {
         if ($is_commandline == 1) {
         dbg(DBG_NOTE, "Successfully added receiver: $receivername\n\n");
         print "List of receivers: \n";
         printReceivers($tfa_home);
         dbg(DBG_WHAT,"#### Added Receiver ####\n");
         }
         system("$RM -f $file");
         return SUCCESS;
     }
     elsif ($line eq "DONE"){
        print "Success\n";
     }
     elsif ($line =~ /FAILED - Connection refused/) {
        tfactlshare_error_msg(513,undef);
     }
     elsif ($line =~ /FAILED - Could not determine TFA port/) {
        tfactlshare_error_msg(508,undef);
     }
     elsif ($line =~ /FAILED - Passwords do not match/) {
        tfactlshare_error_msg(509,undef);
     } else {
         print "FAIL\n";
     }
  }
  dbg(DBG_WHAT,"Could not add receiver\n");
 system("$RM -f $file");
  return FAILED;

}

#########################################################
##tfactl 
##########################################################


sub tfactlshare_managestop
{
  my ($tfa_home) = @_;
  my $localhost=tolower_host();
  #get run mode
  if ( getTFARunMode($tfa_home) eq "COLLECTOR" ) {
    # check if receiver registered
    if (tfactlshare_isAnyReceiverRegistered($tfa_home)){
	my $file_name = catfile($tfa_home, "internal","producer_files.prop");
	if ( -e $file_name){
           # this is a re stop just return
           print "$file_name  found\n";
           return SUCCESS;
	}
      print "Sending stoptfa\n";
      # send message to stop producer and dump file list
      my $actionmessage = "$localhost:stoptfa:client";
      dbg(DBG_WHAT, "Running addReceiver through Java CLI\n");
      my $command = buildCLIJava($tfa_home,$actionmessage);
      dbg(DBG_VERB, "$command\n");
      my $line;
      my @cli_output = tfactlshare_runClient($command);
      foreach $line ( @cli_output )
      {
         #print "$line\n";
         if ( $line eq "SUCCESS" ) {
             return SUCCESS;
         }
         elsif ($line eq "DONE"){
            print "Success\n";
         } else {
             print "FAIL\n";
         }
      }
      # returning always success not to affect TFAC
      return SUCCESS;
    }
  }
  else {
   # Action to stop producer on collector side and wit for 40 secs
   # stop indexer 
      my $actionmessage = "$localhost:stoptfa:receiver";
      dbg(DBG_WHAT, "Running addReceiver through Java CLI\n");
      my $command = buildCLIJava($tfa_home,$actionmessage);
      dbg(DBG_VERB, "$command\n");
      my $line;
      my @cli_output = tfactlshare_runClient($command);
      foreach $line ( @cli_output )
      {
         #print "$line\n";
         if ( $line eq "SUCCESS" ) {
             return SUCCESS;
         }
         elsif ($line eq "DONE"){
            print "Success\n";
         } else {
             print "FAIL\n";
         }
      }
      # returning always success not to affect TFAC
      return SUCCESS;

  }
}

sub tfactlshare_checkifexists
{
  my ($fpath) = @_;
  if (-e $fpath) {
      return 1;
  }
  else {
      return 0;
  }
}

sub tfactlshare_managestart
{
  my ($tfa_home) = @_;
  my $localhost=tolower_host();
  my $dump = catfile($tfa_home,"internal","producer_files.prop");
  #get run mode
  if ( getTFARunMode($tfa_home) eq "COLLECTOR" ) {
    # check if receiver registered
    if (tfactlshare_isAnyReceiverRegistered($tfa_home) && tfactlshare_checkifexists($dump)){
      tfactlshare_setup_metadata();
      my @temp = tfactlshare_getListOfAllRececivers($tfa_home);
      my $server=$temp[0];
      chomp($server);
      my $is_commandline = 1;
      chomp($is_commandline);
      chomp($localhost);
      my $actionargs = "server=$server~is_commandline=$is_commandline~remoteport=-1";
      my $actionmessage = "$localhost:startproducer:$localhost";
      # send message to stop producer and dump file list
      my $actionmessage = "$actionmessage~$actionargs";
      dbg(DBG_WHAT, "Running addReceiver through Java CLI\n");
      my $command = buildCLIJava($tfa_home,$actionmessage);
      dbg(DBG_VERB, "$command\n");
      my $line;
      my @cli_output = tfactlshare_runClient($command);
      foreach $line ( @cli_output )
      {
         #print "$line\n";
         if ( $line eq "SUCCESS" ) {
             return SUCCESS;
         }
         elsif ($line eq "DONE"){
            print "Success\n";
         } else {
             print "FAIL\n";
         }
      }
      # remove the file after startup
        my $file_name = catfile($tfa_home, "internal","producer_files.prop");
        if ( -e $file_name){
            system("rm -f $file_name");
        }

      # returning always success not to affect TFAC
      return SUCCESS;
    }
  }
  else {
   # Action to stop monitor on collector side with wait of 40 secs
   if (tfactlshare_isAnyCollectorRegistered($tfa_home)) {
      my $actionmessage = "$localhost:starttfa:receiver";
      dbg(DBG_WHAT, "Running starttfa through Java CLI\n");
      my $command = buildCLIJava($tfa_home,$actionmessage);
      dbg(DBG_VERB, "$command\n");
      my $line;
      my @cli_output = tfactlshare_runClient($command);
      foreach $line ( @cli_output )
      {
         #print "$line\n";
         if ( $line eq "SUCCESS" ) {
             return SUCCESS;
         }
         elsif ($line eq "DONE"){
            print "Success\n";
         } else {
             print "FAIL\n";
         }
      }
      # returning always success not to affect TFAC
      return SUCCESS;
   }
  }
}


#########################################################
#tfactl 
#########################################################
sub tfactlshare_addCollector
{
  
  my ($type,$collector,$cpass,$is_commandline,$query,$tfa_home,$ropt, $action,$kopt,$ctype) = @_;
  my $localhost=tolower_host();
  my $hostName;
  if ($localhost =~ /\./) {
    my @values = split(/\./, $localhost);
    $hostName = @values[0];
  }
  $hostName = $localhost;
  my $rnode;

  chomp($hostName);
  dbg(DBG_WHAT,  "addCollector: Add $type in $hostName\n");
  if ($is_commandline == SUCCESS) {
    my $sudo_user = $ENV{SUDO_USER};
    my $sudo_command = $ENV{SUDO_COMMAND};
    if ( $sudo_user && $sudo_command =~ /tfactl/ ) {
      tfactlshare_error_msg(507,undef);
      return FAILED;
    }
  }
  chomp($ropt);

  my $add_option = "user"; # Normal user 
  if ( $ropt =~ /export=/ )
  {
    $add_option = "auto"; # Wrap file
  }
  my $crs_home;
  if ( $add_option eq "auto" )
  {
    $crs_home = get_crs_home($tfa_home);
    if ( ! $crs_home )
    {
      print "This command is supported only in CRS installations with version >= 12.2\n";
      return;
    }
  }

  my $ctime = time;
  my $opt_r = "n.$add_option.$ctime";
  my $opt_file = "";
  my $file = "";
  if($ropt =~ /^y/)
  {
    $opt_r = "y.$add_option.$ctime";
    $file = catfile($tfa_home,"internal","collectorkey.store");
    $opt_file = catfile($tfa_home,"internal","$ctime.opts");
    if ( $current_user ne "root" )
    {
      $file = catfile($tfa_home, ".$current_user", "collectorkey.store");
      $opt_file = catfile($tfa_home, ".$current_user", "$ctime.opts");
    }
    if ( $add_option eq "auto" )
    {
      open W1F, ">$opt_file"  || die "Can't open $opt_file for writing\n";
      print W1F "crshome=$crs_home\n";
      print W1F "tfahome=$tfa_home\n";
      print W1F "client=$collector\n";
      print W1F "keyfile=$file\n";
      print W1F "ropt=$ropt\n";
    }

    close(W1F);
    if( -e $file) {
      dbg(DBG_WHAT,  "addCollector: key store exists\n");
      my $fileout = "$file"."bkp";
      open INP, "$file" or die $!;
      open OUT, ">>$fileout" or die $!;
      my @lines = <INP>;
      foreach my $rec (@lines) {
	if($rec =~ /^$collector/i || $rec =~ /^detailsof.$collector/i ){
	  dbg(DBG_WHAT,  "Overwrite client with new key in collectorkey.store\n");
	}
	else {
	  print OUT "$rec";
	}
      }
      close(OUT);
      close(INP);
      copy($fileout,$file);
      host("$RM -f $fileout");
    }
    open OUT,">>$file" or die $!;
    print OUT "detailsof.$collector:$ropt\n";
    print OUT "$collector=$cpass\n";
    close(OUT);
    host("$CHMOD 600 $file");
  }
  my $actionargs = "collector=$collector~is_commandline=$is_commandline~pollport=-1~query=$query~onhost=-1~koption=$kopt~roption=$opt_r~ctype=$ctype";
  my $actionmessage;
  if ( $type eq "client" ) {
    if($query =~ /add/i) {
      $actionmessage = "$localhost:addcollector:$hostName";
    }else {
      tfactlshare_error_msg(510,undef);
      return FAILED;
    }
    #should we syncronize this node with all other nodes in r cluster
    $actionmessage = "$actionmessage~$actionargs";
    dbg(DBG_WHAT, "Adding $type through Java CLI\n");
    my $command = buildCLIJava($tfa_home,$actionmessage);
    dbg(DBG_VERB, "$command\n");
    my $line;
    my $port;
    my @parts;
    my $rhosts = "";
    my $failed = 0;
    my @cli_output = tfactlshare_runClient($command);
    foreach $line ( @cli_output ) {
      if( $line =~ /PORT/ ) {
          @parts = split /:/,$line;
          $rnode = $parts[1];
          $port = $parts[2];
      }
       elsif( $line =~ /RHOSTS=(.*)/ ) {
          $rhosts = $1;
          chomp($rhosts);
      }
      elsif ( $line eq "DONE") {
	if ($is_commandline == 1) {
          if ( $action eq "add" )
          {
	    dbg(DBG_NOTE,"Successfully added $type in $rnode listening requests on port $port\n\n");
          }
	}
        #print "Successfully Added $type in $hostName listening requests on port $port \n\n";
        if ( $add_option eq "auto" )
        {
          if ( $action eq "export" )
          {
            tfactlshare_error_msg (516, undef);
          }
          my @r = split(/\[/, $roption);
          my $cwfile = $r[2];
          $cwfile =~ s/export=//;
          if ( ! -e $cwfile || $failed )
          {
            tfactlshare_error_msg(511,undef);
            tfactlshare_cleanup_files($opt_file, $file);
            exit 1;
          }
        }
        if ( $current_user eq "root" )
        {
          tfactlshare_export2wrapfile ($tfa_home, $collector, $ropt, $rhosts);
        }
        tfactlshare_cleanup_files($opt_file, $file);
	return SUCCESS;
      }
      elsif ( $line =~ /RUNNING/ ) {
	print "$type is already running\n";
        tfactlshare_cleanup_files($opt_file, $file);
	return SUCCESS;
      }
      elsif ($line =~ /ERROR/) {
        print "$line\n";
        $failed = 1;
      }
      elsif ($line =~ /FAILED/) {
        print "$line\n";
        $failed = 1;
        tfactlshare_cleanup_files($opt_file, $file);
        tfactlshare_error_msg(511,undef);
      }
    }
    tfactlshare_cleanup_files($opt_file, $file);
    return FAILED;
  }

}

sub tfactlshare_cleanup_files
{
  my $file = shift;
  my $keyfile = shift;
  if ( -r $file )
  {
    unlink ($file);
  }

  open(WKF, ">$keyfile.new");
  open(RKF, "$keyfile");
  while(<RKF>)
  {
    print WKF $_ if ( /^detailsof\./ );
  }
  close(RKF);
  close(WKF);
  system("$RM -f $keyfile");
  system("$CP -f $keyfile.new $keyfile");
  system("$RM -f $keyfile.new");
  system("$CHMOD 600 $keyfile");

}

sub tfactlshare_export2wrapfile
{
  my $tfa_home = shift;
  my $cname = shift;
  my $ropts = shift;
  my $servers = shift;
  my @r = split(/\[/, $ropts);

  return if ( ! $r[2] );

  my ($cversion, $cwfile, $cguid, $keyfile);
  $keyfile = catfile($tfa_home,"internal","collectorkey.store");
  $cversion = $r[1];
  $cwfile = $r[2];
  $cguid = $r[3];

  if ( $current_user ne "root" )
  {
    $keyfile = catfile($tfa_home, ".$current_user", "collectorkey.store");
  }

  # Get CRS_HOME
  my $crs_home = get_crs_home($tfa_home);
  if ( ! $crs_home )
  {
    print "This command is supported only in CRS installations with version >= 12.2\n";
    return;
  }
  $ENV{ORACLE_HOME} = $crs_home;
  my $ORACLE_HOME = $crs_home;
  $ENV{LD_LIBRARY_PATH} = catfile($ORACLE_HOME, "lib");
  system("$ORACLE_HOME/jdk/bin/java -cp $tfa_home/jlib/RATFA.jar:$ORACLE_HOME/jlib/clscred.jar:$ORACLE_HOME/jlib/srvm.jar oracle.rat.tfa.uc.TFAManageCredentials -export \"$cwfile\" -client \"$cname\" -guid \"$cguid\" -servers \"$servers\"  -version \"$cversion\" -keyfile \"$keyfile\"");

  print "Successfully exported TFA credentials for $cname to $cwfile\n";
}

sub tfactlshare_fixTfadiagnostics{
	my $tfa_home = shift;
	if($IS_WINDOWS){
	  my $file = catfile ( $tfa_home,"bin","tfadiagnostics.bat");
	  open(FILE, '<', $file) || die "File not found";
	  my @lines = <FILE>;
	  close(FILE);

	  $tfa_home = tfactlshare_findrep($tfa_home,"/","\\");

	  my @newlines;
	  my $line;
	  foreach(@lines) {
	    if (/set TFA_HOME=/) {
	     $line = "set TFA_HOME=$tfa_home\n";
	    }
	    else {
	     $line = $_;
	    }
	     push(@newlines,$line);
	  }
	  open(FILE, '>', $file) || die "File not found";
	  print FILE @newlines;
	  close(FILE);
	 }
}


sub tfactlshare_chmod{
	my $arguments = shift;
	osutils_chmod(join($osutil_sep, split(/\s+/, $arguments)));
}
#################
###
## Name tfactlshare_write_array_to_open_file
##
## Desription : write an array to a file opened already .
##
## IN : file handle of open file
##
#################
sub tfactlshare_write_array_to_open_file {
  my ($filehandle,$array_ref) = @_;
  my @array = @{$array_ref};
  foreach(@array){
    print $filehandle "$_\n";
  }
}


sub tfactlshare_write_array_to_file{
  my ($filename,$array_ref) = @_;
  my @array = @{$array_ref};
  open (OUT, ">$filename") || die "Cant open $filename\n";
  foreach(@array){
    print OUT "$_\n";
  }
  close(OUT);
}

###########################
## Name : tfactlshare_isuserindbagrp
## Description : checks if the passed user is in the DBA group for a given Oracle HOME.
## Param
##     unsername
##     oracle_home
##
## Returns 1 for True, 0 for false
##
## #######################
sub tfactlshare_isuserindbagrp {
  my $username = shift;
  my $oraclehome = shift;
  my $osdbaexe = catfile($oraclehome,"bin","osdbagrp");

  if ( $IS_WINDOWS ) {
  	return 1;
  }

  # get owner of the osdbagrp file
  my $ownerid = (stat $osdbaexe)[4];
  my $owner = (getpwuid $ownerid)[0];
  chomp($owner);
 
  # it the user owns this executable then we are good.
  if ( $owner eq $username ) {
    return 1;
  }
 
  # get the osdbagrp 
  my $command = tfactlshare_checksu($username,"$osdbaexe");
  my $osdba = `$command`;
  chomp ($osdba);

  # get the group members for the osdbagrp
  my $name;
  my $passwd;
  my $gid;
  my $members;
  my $member;

  while( ($name,$passwd,$gid,$members) = getgrent ) {
     if ( $name eq $osdba ) {
       last; 
     }
  }

  # check if the passed user is a member of the group
  my @mem = split(/ /,$members);
  foreach $member ( @mem ) {
    chomp();
    return 1 if ( $member eq $username );
  }
  return 0;
}

###########
# Name: tfactlshare_invalid_chars
#
# Descriptions.
# Checks for $;&` in a string that we might want t use to execute an os command
#
# parameters
# instring - String to check
# 
# returns TRUe if any of the chanracters are found
#
sub tfactlshare_invalid_chars {
  my $instring = shift ;
  if ( $instring =~ /[\$\;\&\`\(\)]/ ) {
     return TRUE;
  } else {
     return FALSE;
  }
}

sub tfactlshare_dg_size
{
  my $oh = shift;
  my $dgname = shift;
  my @lsdsk = `$oh/bin/asmcmd lsdg $dgname --suppressheader`;
  chomp(@lsdsk);
  my ($totmb, $freemb);
  my $total_k = "Total_MB";
  my $total_kn = 7;
  my $free_k = "Usable_file_MB";
  my $free_kn = 10;

  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_dg_size " .
                    "running $oh/bin/asmcmd lsdg $dgname --suppressheader",
                   'y', 'y');

  foreach my $lsdsk (@lsdsk)
  {
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_dg_size " .
                    "o/p $lsdsk", 'y', 'y');
    $lsdsk =~ s/^\s+//;
    my @d = split(/\s+/, $lsdsk);
    $totmb = $d[$total_kn];
    $freemb = $d[$free_kn];
  }
  return ($totmb, $freemb);
}

# Rule is : 
# 1) dont go beyond what can be allocated to TFA
# 2) Atleast 20% free space is available.
# 3) Min 1GB should be free
sub tfactlshare_get_max_space_in_mb
{
  my $crshome = shift;
  my $dgname = shift;
  my @mb = tfactlshare_dg_size($crshome, $dgname);
  my $minfree = "1024"; # 1 GB
  return 0 if ( $mb[1] < $minfree );  # Free space is less than min free needed
  my $buffer = int(0.2 * $mb[0]);
  return 0 if ( $mb[1] < $buffer ); # Free space is less than 20% of total
  return $mb[1] - $buffer;
}

sub tfactlshare_cleanup_acfs_repos
{
  my $oh = shift;
  my $dgname = shift;
  my $acfslog = shift;

  system("$oh/bin/srvctl stop filesystem  -volume TFAREPOS  -diskgroup $dgname -force >>$acfslog 2>&1");
  system("$oh/bin/srvctl remove filesystem  -volume TFAREPOS  -diskgroup $dgname -force >>$acfslog 2>&1");
  my $crsusr = getFileOwner( "$oh/bin/oracle" );
#TODO check this su
  system("/bin/su $crsusr -c \"$oh/bin/asmcmd voldelete -G $dgname TFAREPOS\" >>$acfslog 2>&1");
}

sub tfactlshare_is_acfs_setup
{
  return 1 if ( -f catfile($tfa_home, "internal", ".tfa_acfs_setup_finished" ));
  return 0;
}

sub tfactlshare_extend_acfs
{
  my $size = shift;
  my $acfsutil = "/sbin/acfsutil";
  if ( ! -f $acfsutil )
  {
    print "Error: Can not extend TFA repository as $acfsutil does not exists\n";
    return;
  }
  system("$acfsutil size +$size /mnt/oracle/tfa");
}

sub tfactlshare_check_acfs
{
  my $oracle_home = shift;
  my $name = shift;
  my $mount_op = `$oracle_home/bin/crsctl stat res |grep -i tfarepos.acfs`;
  chomp($mount_op);
  if ( $mount_op =~ /tfa/ )
  {
    return 1;
  }
  return 0;
}

# Check clients in CRS and add any missing clients to TFA
# Since 12.2 did not enable TFA Service, when DSC is upgraded from 12.2 to 18.1 
# the Member Clusters added in 12.2 will not be in TFA
sub tfactlshare_add_crs_clients
{
  my $crshome = shift;
  my $cmd = "$crshome/bin/crsctl query member_cluster_configuration";
  my @out = `$cmd 2>&1`;
  my $l = "";
  my @crs_clients = ();
  foreach $l (@out)
  {
     if ( $l = /^\s+(\w+[^\s]+)\s+/ && $l !~ /NAME/ )
     {
       push @crs_clients, $1;
     }
  }

  my $crsusr = getFileOwner( "$crshome/bin/oracle" );
  foreach my $cnode (@crs_clients)
  {
    tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_add_crs_clients " .
                    "Adding client $cnode from previous client setup, command: su $crsusr -c $crshome/bin/tfactl client add $cnode -export $tfa_home/.$crsusr/$cnode.xml",
                   'y', 'y');
#TODO check this su
    my @log = qx(su $crsusr -c "$crshome/bin/tfactl client add $cnode -export $tfa_home/.$crsusr/$cnode.xml" 2>&1);
    chomp (@log);
    foreach my $l (@log)
    {
      tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_add_crs_clients " .
                    "$l",
                   'y', 'y');
    }
    system("rm -f $tfa_home/.$crsusr/$cnode.xml");
  }
}

# During install time setup acfs for TFA Receiver repository
# By default allocate for dsc cluster only
# Extend during member cluster add
# while extending make sure 20% for disk group is free after extend. else fail the client add.
# tfactl receiver extendrepos

sub tfactlshare_setup_acfs
{

  return if ( tfactlshare_is_acfs_setup() );
  return if ( tfactlshare_get_val4key_in_tfa_setup($tfa_home, "RUN_MODE") ne "receiver");
  return if ( tfactlshare_get_val4key_in_tfa_setup($tfa_home, "CLUSTER_CLASS") ne "DOMAINSERVICES");
  my $sslfile = catfile($tfa_home, "internal", "ssl.properties" );
  my $sslKey = 0;
  if ( -r $sslfile ) 
  {
    $sslKey = tfactlshare_getConfigValue($sslfile,"sslKey");
  }
  if ( -r $sslfile && $sslKey == 1 && checkTFAMain($tfa_home) == SUCCESS ) 
  {
    if ( ! -r "$tfa_home/internal/.tfa_acfs_setup_first" )
    { # Wait for second run as secure thread 
      open(TF, ">$tfa_home/internal/.tfa_acfs_setup_first");
      print TF "";
      close(TF);
      return;
    }
    my $crsup = 0;
    my $crshome = get_crs_home($tfa_home);
    if ( $crshome ) {
      $crsup = 1 if ( osutils_isCRSRunning($crshome) );
      if ( $crsup == 1 )
      {
        my $crs_running_home = `$PS -ef |grep crsd.bin|grep -v grep | grep -c $crshome`;
        chomp($crs_running_home);
        $crs_running_home =~ s/\s//g;
        if ( $crs_running_home == 0 )
        { # CRS is not running from $crshome. This happens during upgrade as TFA gets upgraded first.
          $crsup = 0;
        }
      }
    }
    if ( $crsup == 1 )
    {
      my $dgname = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "CDATA_BACKUP_DISK_GROUP");
      $ENV{ORACLE_HOME} = $crshome;
      my $ORACLE_HOME = $crshome;
      $ENV{LD_LIBRARY_PATH} = catfile($crshome, "lib");
      $ENV{LIBPATH} = catfile($crshome, "lib");
      my $repos_size_mb = 200*1024;
      my @mb = tfactlshare_dg_size($crshome, $dgname);
      my $dg_free = $mb[1];
      tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_setup_acfs " .
                    "Diskgroup $dgname, dg_free = $dg_free",
                   'y', 'y');
      if ( $dg_free < $repos_size_mb )
      {
        $repos_size_mb = int($dg_free / 2);
      }
      tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_setup_acfs " .
                    "Diskgroup $dgname, dg_free = $dg_free, repos_size_mb=$repos_size_mb",
                   'y', 'y');
      my ($diagdir,$logdir) = tfactlshare_get_diag_directory($tfa_home);
      my $acfslog = catfile($logdir, "tfa_setup_acfs.log");
      my $acfslog_1 = catfile($logdir, "tfa_setup_acfs.1.log");
      if ( -f $acfslog && ! -f $acfslog_1 )
      {
        system("$MV -f $acfslog $acfslog_1");
      }
      open(WF, ">$acfslog");
      close(WF);
      my $nodescnt;
      $nodescnt = `$ORACLE_HOME/bin/olsnodes 2>>$acfslog |wc -l`;
      chomp($nodescnt);
      $nodescnt =~ s/\s//g;
      $nodescnt = 1 if ( ! $nodescnt );
      if ( ! tfactlshare_check_acfs($ORACLE_HOME, "/mnt/oracle/tfa") )
      {
        my $rcnt = 0;
        if ( -f "$tfa_home/internal/.tfa_acfs_setup_try")
        {
          open(TF, "$tfa_home/internal/.tfa_acfs_setup_try");
          my @o = <TF>;
          close(TF);
          chomp(@o);
          $rcnt = $o[0];
          if ( $rcnt > 10 )
          {
            return;
          }
           else
          {
            tfactlshare_cleanup_acfs_repos($crshome, $dgname, $acfslog);
            $rcnt ++;
            open(TF, ">$tfa_home/internal/.tfa_acfs_setup_try");
            print TF "$rcnt";
            close(TF);
          }
        }
         else
        {
            open(TF, ">$tfa_home/internal/.tfa_acfs_setup_try");
            print TF "1";
            close(TF);
        }
        system("$ORACLE_HOME/jdk/bin/java -cp $ORACLE_HOME/jlib/netcfg.jar:$ORACLE_HOME/jlib/srvm.jar:$ORACLE_HOME/jlib/srvmasm.jar:$ORACLE_HOME/jlib/srvmhas.jar:$tfa_home/jlib/RATFA.jar oracle.rat.tfa.uc.SetupRepositoryInACFS $dgname tfarepos /mnt/oracle/tfa $repos_size_mb >>$acfslog 2>&1");
      }

      if ( tfactlshare_check_acfs($ORACLE_HOME, "/mnt/oracle/tfa") )
      {
      	my $dgname_lc = lc($dgname);
        system("$ORACLE_HOME/bin/srvctl stop tfa >>$acfslog 2>&1");
        system("$ORACLE_HOME/bin/srvctl remove tfa >>$acfslog 2>&1");

        system("touch " . catfile($tfa_home, "internal", ".tfa_acfs_setup_finished" ));
        my $rconfig = catfile($tfa_home, "receiver", "internal", "rconfig.properties");

		if ( -w $rconfig ) {
	          system("perl -p -i -e 's%r.repository=.*%r.repository=/mnt/oracle/tfa%' $rconfig");
		}
		
        my $inittfa = catfile($INITDIR, "init.tfa");
        my $restartcmd = "$tfa_home/bin/tfactl stop >>$acfslog 2>&1";
        qx($restartcmd);
        sleep(10);
        $restartcmd = "$tfa_home/bin/tfactl start >>$acfslog 2>&1";
        qx($restartcmd);

        # Add ora.tfa resource
        system("$ORACLE_HOME/bin/srvctl add tfa -diskgroup $dgname_lc >>$acfslog 2>&1"); 
        system("$ORACLE_HOME/bin/srvctl start tfa >>$acfslog 2>&1");
        tfactlshare_add_crs_clients($crshome);
      }
       else
      {
        print "Error: Failed to create TFA repository on ACFS.\n";
      }
    }
  }
}

########
## NAME
##   tfactlshare_set_jvm_xmx
##
## DESCRIPTION
##   Set the value of jvmXmx used for starting TFA JVM
##
## PARAMETERS
##       $val : Set to $val. If its null, set to default value.
## RETURNS
##       Returns 0 if success and 1 if failed
## NOTES/USAGE
##
#########
sub tfactlshare_set_jvm_xmx
{
  my $tfa_home = shift;
  my $val = shift;
  my $jvmLineOther = shift;

  my $java_home = get_java_home($tfa_home);
  my $java = catfile($java_home, "bin", "java");
  my $tfajar = catfile($tfa_home, "jlib", "RATFA.jar");
  my $config = catfile($tfa_home, "internal", "config.properties");

  if( defined $jvmLineOther){
    tfactlshare_updateTFAConfig($config, "jvmLineOther", $jvmLineOther);
  }

  if ( $val )
  {
    tfactlshare_updateTFAConfig($config, "jvmXmxDefault", "false");
    tfactlshare_updateTFAConfig($config, "jvmXmx", $val);
  }
   else
  {
    # Check if jvmxmxdefault=true, if so calculate. else user changed it.
    #
    my $jvmxmxdefault = tfactlshare_getConfigValue($config, "jvmXmxDefault");
    if ( $jvmxmxdefault ne "true" )
    { # No need to calculate as user has changed it.
      return;
    }

    my $ram_size = `$java -cp $tfajar oracle.rat.tfa.util.SysInfo ramsize`; # RAM size in MB
    chomp($ram_size);
    if ( $ram_size )
    {
      my $ram_size_gb = $ram_size/1024;
  
      my $jvmmax = 2048;

      if ( $ram_size_gb < 8 )
      {
        $jvmmax = 64;
      }
      elsif ( $ram_size_gb < 16 )
      {
        $jvmmax = 128;
      }
      elsif ( $ram_size_gb < 64 )
      {
        $jvmmax = 256;
      }
      elsif ( $ram_size_gb < 256 )
      {
        $jvmmax = 512;
      }
      elsif ( $ram_size_gb < 1024 )
      {
        $jvmmax = 1024;
      }
      tfactlshare_updateTFAConfig($config, "jvmXmx", $jvmmax);
    }
  }
}

########
# NAME
#   tfactlshare_check_platform_compatibility
#
# DESCRIPTION
#   This subroutine checks whether the tool is compatible 
#	with the given operating system
#
# PARAMETERS
#	toolplatforms - Value of platforms attribute of corresponding tool
#       toolname      - Value of toolname
# RETURNS
#	Returns 1 if compatible and 0 if incompatible
# NOTES/USAGE
#
########
sub tfactlshare_check_platform_compatibility{
  my $toolplatforms = shift;
  my $toolname      = shift;
  
  if($toolplatforms){
    my @platforms = split(/-/,$toolplatforms);
    my $PLATFORM = $^O;
    foreach my $platform_option (@platforms){
      if ( (not ($toolname eq "exachk" && not (isExadataDom0() || isExadata()))) &&
           (( lc($platform_option) eq "all" ) || 
            ( (lc($platform_option) eq "linux") && (lc($PLATFORM) eq "linux") ) || 
            ( (lc($platform_option) eq "windows") && ($PLATFORM eq "MSWin32") ) || 
            ( (lc($platform_option) eq "unix") && ($PLATFORM ne "MSWin32") ) )
         ) {
        return 1;
      }
    }
  }

  return 0;
}

###########
# NAME: tfactlshare_countsnaps
#
# DESCRIPTION
# Counts the number of AWR snapshots between -from time and -to time for a given database
#
# Parameters
# -from  starty time for search
# -to end time for search
# -db dataase name 
# 
# Return the number of snaps fouind for count
# Return all snapshots for print.
# #####################
#
sub tfactlshare_awrsnaps {

  my $tfa_home = shift;
  my $func = shift;
  my $db = shift;
  my $from = shift;
  my $to = shift;
  my $sqlstring1 = "";
  my $sqlstring2 = "";

  if ( $current_user eq "root" && (not $IS_WINDOWS) )
  {
     print "tfactlshare_awrsnaps only runs as DB owner users - not root\n";
  }
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_awrsnap " .
                    "running function $func for db $db, from $from, to $to",
                   'y', 'y');

  $from = tfactlshare_convertDateStringforCRS($from) if ( $from );
  $to = tfactlshare_convertDateStringforCRS($to) if ( $to );

  if ( $func eq "listall" ) {
     $sqlstring1 = "set linesize 1000";
     $sqlstring2 = "select snap_id,dbid,instance_number, begin_interval_time, end_interval_time " .
                   "from dba_hist_snapshot " .
   		   "order by 3,1 ASC;";
  } else { 
     $sqlstring1 = "set heading off echo off feedback off pagesize 0";
     $sqlstring2 = "select snap_id,dbid,instance_number from (".
              "select a.snap_id,a.dbid,a.instance_number,a.end_interval_time " .
              "from dba_hist_snapshot a,v\$instance b " .
              "where ((a.begin_interval_time < to_date('" . $from . "','YYYY-MM-DD HH24:MI:SS') " . 
              "and a.end_interval_time > to_date('" . $from . "','YYYY-MM-DD HH24:MI:SS')) " .
              "or (a.begin_interval_time < to_date('" . $to . "','YYYY-MM-DD HH24:MI:SS') " .
              "and a.end_interval_time > to_date('" . $to . "','YYYY-MM-DD HH24:MI:SS')) " .
              "or (a.begin_interval_time > to_date('" . $from . "','YYYY-MM-DD HH24:MI:SS') " .
              "and a.end_interval_time < to_date('" . $to . "','YYYY-MM-DD HH24:MI:SS'))) " .
              "and a.instance_number=b.instance_number " .
              "order by 3,1 ASC )".
              "where end_interval_time <= to_date('". $to . "','YYYY-MM-DD HH24:MI:SS');\n";
  }
  my $sqlstring = $sqlstring1 . "\n" . $sqlstring2;
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_awrsnap " .
                    "sql string for $func is $sqlstring1 , $sqlstring2",
                   'y', 'y');
  dbutil_setOraEnv($tfa_home,$db,"",TRUE);
  #dbutil_setOraEnv($tfa_home,$db);
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_awrsnap " .
                    "ENV Set for db $db HOME $ENV{ORACLE_HOME} SID $ENV{ORACLE_SID} ",
                   'y', 'y');
  my @snaps = tfactlshare_run_a_sql("sql",$sqlstring);
  if ( $func eq "listall" ) {
     return @snaps;
  } else {
     return  scalar(@snaps);
  }
} 

sub tfactlshare_get_time{
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  $year += 1900;
  my $month = sprintf("%02d", $mon+1);
  $hour = sprintf("%02d", $hour);
  $min = sprintf("%02d", $min);
  $sec = sprintf("%02d", $sec);
  $mday = sprintf("%02d", $mday);
  return "$year$month$mday$hour$min$sec";
}

sub tfactlshare_getorainvloc {
    my $val = "";
    if ( $IS_WINDOWS ) {
      my @invloc = `reg query HKEY_LOCAL_MACHINE\\Software\\Oracle /v "inst_loc" /s 2>&1`;
      foreach my $line (@invloc) {
        if ( $line =~ /.*inst_loc.*REG_SZ\s+(.*)/ ) {
          $val = $1;
          last;
        }    
      }  
    } else {
      my $orainv = tfactlshare_getOraInstLocation();
      return 0 if ( !-e $orainv );
      open( FH, "<", $orainv ) or return 0;
      while(<FH>) {
        chomp;
        if ( /^inventory_loc=(.*)/ ) {
          $val =  $1;
        }
      }
      close(FH);
    }
    return $val;
}

#Conversion for shell command 'cat <filename>' and returns the contents in an array
sub tfactlshare_readFileToArray {
  my $filename = shift;
  my @arr;
  open FILE, "$filename" or die "Could not open $filename!\n";
  while(<FILE>) {
    push @arr, $_;
  }
  close FILE;
  return @arr;
}

########
### NAME
###   tfactlshare_Generate_password
###
### DESCRIPTION
###   Generate a random password with minimum length 8
###   Printable acsii characters 33 .. 254
### PARAMETERS
### RETURNS
### 
### NOTES/USAGE
###
##########
sub tfactlshare_generate_password
{
  my $len = shift;
  my $Cpassword = undef;
  my @chrs = tfactlshare_get_valid_chrs();
  if($len<8) {
  	$len = 8;
  }

  my @lower_case = ('a'..'z');
  my @upper_case = ('A'..'Z');
  my @special_char = ('#','@');
  my @digits = (0..9);
 
  for(my $i = 0;$i<$len-4; $i++){
	$Cpassword .= $chrs[rand (@chrs)];
  }

  $Cpassword .= $lower_case[rand (@lower_case)];
  $Cpassword .= $upper_case[rand (@upper_case)];
  $Cpassword .= $special_char[rand (@special_char)];
  $Cpassword .= $digits[rand (@digits)];
  
  return $Cpassword;
}

######
## NAME
##   tfactlshare_get_valid_chrs
##
## DESCRIPTION
##   Return array of characters except for \$\`;\<\>\&\| characters 
##   which are not accepted in TFA daemon
##
## PARAMETERS
## RETURNS
## 
## NOTES/USAGE
##
#########

sub tfactlshare_get_valid_chrs
{
  my @chrs = ();
  for (my $i = 33; $i < 126; $i++)
  {
    my $c = chr($i);
    if ( ! tfactlshare_has_blacklisted_chrs($c) )
    {
      push @chrs, $c;
    }
  }
  return @chrs;
}

########
### NAME
###   tfactlshare_has_blacklisted_chrs
###
### DESCRIPTION
###   Check for \$\`;\<\>\&\| characters which are not accepted in TFA daemon
###
### PARAMETERS
### RETURNS
### 
### NOTES/USAGE
###
##########

sub tfactlshare_has_blacklisted_chrs
{
  my $pass = shift;
  if ( $pass =~ /[\$\`;\<\>\&\|\)\(\'\"#\!^]/ )		## '^' breaks the password into 2 parts in windows
  {
    return 1;
  }
  return 0;
}


########
### NAME
###   tfactlshare_getReferenceName
###
### DESCRIPTION
###   This function gets the name of a reference. 
###
### PARAMETERS
###      (IN)     \&<variable name>.
### RETURNS  
###     "NOT A VALID REFERENCE" | reference name
### 
### NOTES/USAGE
### This function uses core module B.
### This module is available in Perl versions 5.8.8 
### and greater as per perldoc. Not sure if available in
### older versions of perl.
### 
###
##########

sub tfactlshare_getReferenceName
{
    eval {
      my $obj = B::svref_2object(shift());
      $obj->GV->STASH->NAME ."::".$obj->GV->NAME;

    } || "NOT A VALID REFERENCE";
}

#############
##  NAME
##    tfactlshare_is_statspack_installed
##
##  DESCRIPTION
##    
##    This function checks if statspack is installed 
##
##  PARAMS
##    $tfa_home       (IN)      tfa_home 
##    $db             (IN)      Database name
##
##  RETURNS
##    TRUE|FALSE
##
##  NOTES
##    NONE
###############
sub tfactlshare_is_statspack_installed
{
  my $tfa_home =shift; 
  my $db = shift ;
  my $IS_STATSPACK = FALSE;

  my $sql = "set heading off echo off feedback off\n";
  $sql .="select count(*) TOTAL_TABLES from ALL_OBJECTS WHERE object_name like 'STATS\\\$%' and owner = 'PERFSTAT' and object_name in ('STATS\\\$SNAPSHOT_ID',";
  $sql .="'STATS\\\$SYSSTAT','STATS\\\$SNAPSHOT','STATS\\\$SNAPSHOT_PK','STATS\\\$PARAMETER','STATS\\\$SQL_STATISTICS','STATS\\\$SGA'";
  $sql .=",'STATS\\\$PGASTAT','STATS\\\$OSSTAT','STATS\\\$LATCH');";

  tfactlshare_trace(5,"tfactl (PID=$$) tfactlshare_is_statspack_install "."sql string is $sql");
  dbutil_setOraEnv($tfa_home, $db, "", TRUE);

  my @out = tfactlshare_run_a_sql("sql",$sql);
  @out = grep{$_ ne ''} @out;
  chomp(@out);

  #10 is the number of statspack reference tables to check existance 
  if( $out[0] == 10){
    $IS_STATSPACK = TRUE;
  }
  return $IS_STATSPACK;
}

#############
##  NAME
##    tfactlshare_get_awrlicense
##
##  DESCRIPTION
##    
##    This function queries the db parameter control_management_pack access
##    and returns the license type;
##
##  PARAMS
##    $tfa_home       (IN)      tfa_home 
##    $db             (IN)      Database name
##
##  RETURNS
##    License DIAGNOSTIC+TUNNING|DIAGNOSTIC|NONE
##
##  NOTES
##    NONE
###############

sub tfactlshare_get_awrlicense
{
  my $tfa_home=shift;
  my $db = shift;
  my $license;
  my $sql = "set heading off;\n";
  $sql.="show parameter CONTROL_MANAGEMENT_PACK_ACCESS;\n";
  tfactlshare_trace(5,"tfactl (PID=$$) tfactlshare_get_awrlicense "."sql string is $sql");
  dbutil_setOraEnv($tfa_home, $db, "", TRUE);
  my @out = tfactlshare_run_a_sql("sql",$sql);
  chomp(@out);
  @out = grep {$_ ne ''} @out;
  my $row =$out[0];
  my @columns = split ' ',$row;
  $license = $columns[2];
  return $license;
}

###################
## NAME
##   tfactlshare_is_rac
##    
## DESCRIPTION
##    This functions determines if environment is rac or not.
##
## PARAMS
##     NONE
##
## RETURNS 
##    TRUE|FALSE
##
## NOTES
##     NONE
##
###################
#
sub tfactlshare_is_rac
{
  my $IS_RAC=FALSE;
  my $sql = "select name, value from gv\$parameter where name = \'cluster_database\';";
  my @out = tfactlshare_run_a_sql("sql",$sql);
  chomp(@out);
  @out = grep{$_ ne '' } @out;

  if (scalar(@out) > 0 ){
      $IS_RAC= TRUE if($out[scalar(@out)-1] eq "TRUE");
  } else {
    print "Error running sql at is_rac fuction\n";
  }
  return $IS_RAC;
}

###################
## NAME
##   tfactlshare_parse_tfactlsudocmds
##    
## DESCRIPTION
##    This function parses the tfactlsudocmds.xml
##
## PARAMS
##     NONE
##
## RETURNS 
##    @cmds
##
## NOTES
##     NONE
##
###################
sub tfactlshare_parse_tfactlsudocmds {
  my @cmds = ();
  my $file = catfile($tfa_home,"resources","tfactlsudocmds.xml");
  my @tagsarray;
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlshare_parse_tfactlsudocmds " .
                    "file  $file", 'y', 'y');
  if ( -e "$file" ) {
    @tagsarray = tfactlshare_populate_tagsarray($file);
    my @commands = tfactlshare_get_element(\@tagsarray,0,0);
    foreach my $child ( @commands) {
     my @cmdslist = tfactlshare_get_element (\@tagsarray, 
                    @$child[ELEMLEVEL]+1, @$child[ELEMNDX] );
     foreach my $cmd ( @cmdslist ) {
       my %attribs = ();
       %attribs = tfactlshare_get_hash_attributes(@$cmd[ELEMATTRNAME],@$cmd[ELEMATTRVAL]);
       push ( @cmds, \%attribs );
     } 
    }
    return @cmds;
  } else {
    print "$file does not exist \n";
    exit 1;
  }
  
}
###################
## NAME
##   tfactlshare_setsudo_cmds
##    
## DESCRIPTION
##    This functions adds the sudo commands in the sudoers file 
##    if user wants that TFA add these commands automatically.
##    In case that the  user decides to do it by himself it will
##    print the lines that need to be added to the sudoers file
##
## PARAMS
##     NONE
##
## RETURNS 
##    TRUE|FALSE
##
## NOTES
##     NONE
##
###################
#
sub tfactlshare_setsudo_cmds {
  
  my $SUDO = cmdlocation_get("sudo");
  if ( $current_user ne "root" ) {
    if ( $IS_TFA_ADMIN and $IS_NON_ROOT_DAEMON ) {
      #==============================
      # Parse sudo commands
      #==============================
      my @cmds = tfactlshare_parse_tfactlsudocmds();
      my @expcmds; #Expanded commands
      my $crs_home = get_crs_home($tfa_home);
      foreach my $cmd ( @cmds ){
        my %attribs = %{$cmd};
        my $command = $attribs{"command"};
        my $flags   = $attribs{"flags"};
        if ( $command =~ /\%GRID_HOME\%/ ) {
          if ( $crs_home && -d $crs_home ) {
            $command =~ s/\%GRID_HOME\%/$crs_home/g;
            $command .= " $flags" if ( $flags );
            push @expcmds, $command;
          }
        } elsif ($command =~ /\%TFA_HOME\%/ ) {
          $command =~ s/\%TFA_HOME\%/$tfa_home/g;
          $command .= " $flags" if ( $flags );
        } else {
          $command = cmdlocation_get($command); 
          $command .= " $flags" if ( $flags );
          push @expcmds, $command;
        }
      }
      local($SIG{INT}) = sub { print "Cancelling...\n"; exit 0; }; 
      #=================================
      my $val = tfactlshare_get_choice_yn("Y","N", 
      "Do you want TFA to add the sudo commands automatically to the sudoers file ? [Y|N] [N]: ", "N");
      if ( $val =~ /y/i ) {
        $val = tfactlshare_get_choice_yn("Y","N",
               "TFA will require $current_user to have sudo permissions and it will requests the sudo credentials\n".
               "Do you want to proceed ? [Y|N] [N]: ","N");
        return if ($val =~ /n/i);
        #==============================
        # Check sudo access 
        #==============================
        my $access = `$SUDO -nv`;
        if ( $access =~ /not run sudo/ ){
          print "$access \n";
          print "TFA was not able to setup sudo commands\n";
          return;
        }
      
        #==========================================
        # Get commands that have been already added
        #==========================================
        my @out = `$SUDO $CAT /etc/sudoers | $GREP $current_user`;
        chomp(@out);
        my $string = "echo \"";
        foreach  my $cmd ( @expcmds ) {
          my $line = "$current_user ALL=(root) NOPASSWD:$cmd";
          my $qline = quotemeta($line);
          $string .= $line."\n" if ( ! grep { /$qline/ } @out );
        }
        $string.= "\"";
        #==========================================
        # Check whether we need to add new commands
        # or is not necessary
        #==========================================
        if ( $string eq "echo \"\"" ) {
          print "\n Nothing to do! All TFA sudo commands were added previously! \n";
          `$SUDO -k`;
          return;
        }
        #==========================================
        # Generate script to add commands to the 
        # sudoers file
        #==========================================
        my $fname;
        (undef,$fname ) = tempfile();
        open ( FH, ">",$fname ) or die ( "Could not open file \n");
        print FH "$CHMOD 640 /etc/sudoers\n";
        print FH "$string >> /etc/sudoers\n";
        print FH "$CHMOD 440 /etc/sudoers\n";
        close (FH);
        print "The following lines will be added to the sudoers file: \n\n";
        $string =~ s/echo \"//;
        $string =~ s/\"$//;
        print "$string\n";
        $val = tfactlshare_get_choice_yn("Y","N",
               "Please confirm that you would like to proceed ? [Y|N] [N]:","N");
        if ($val =~ /n/i) {
          unlink($fname);
          `$SUDO -k`;
          return;
        }
        `$SUDO sh $fname`;
        `$SUDO -k`;
        unlink($fname);
        print "\nTFA has succesfully added the commands\n";
      } else {
        print "Please add the following lines to the sudoers file \n";
        foreach my $cmd ( @expcmds ){
         print "$current_user ALL=(root) NOPASSWD: $cmd\n";
        }
      }
    } else {
      print "\nAccess Denied: Only TFA Admin can run this command\n\n" if ( ! $IS_TFA_ADMIN );
      print " This command is only valid for NON ROOT DAEMON installation\n" if ( ! $IS_NON_ROOT_DAEMON );
      print " Unable to setup sudo commands \n";
      return;
    }
  } else {
    print "No need to setup sudo commands \n";
    return ;
  }
}

################
# NAME
##   tfactlshare_spl_chr2tag
##    
## DESCRIPTION
##   Replace special characters with tag which cause issues 
##   in Message handler or cause command injection
## PARAMS
##     NONE
##
## RETURNS 
##    TRUE|FALSE
##
## NOTES
##     NONE
##
###################
#
sub tfactlshare_spl_chr2tag
{
  my $val = shift;
  $val =~ s/\:/.COLON./g;
  $val =~ s/\!/.BANG./g;
  $val =~ s/\(/.OPENB./g;
  $val =~ s/\)/.CLOSEB./g;
  $val =~ s/\&/.AMP./g;
  $val =~ s/\$/.DOLLAR./g;
  $val =~ s/\#/.HASH./g;
  $val =~ s/\~/.TILDA./g;
  $val =~ s/\*/.STAR./g;
  $val =~ s/\</.LESS./g;
  $val =~ s/\>/.GREATER./g;
  $val =~ s/\@/.AT./g;
  $val =~ s/\;/.SEMICOLON./g;
  $val =~ s/\|/.PIPE./g;
  $val =~ s/\`/.BT./g;
  return $val;
}

# NAME
##   tfactlshare_tag2spl
##    
## DESCRIPTION
##   Replace special characters with tag which cause issues 
##   in Message handler or cause command injection
## PARAMS
##     NONE
##
## RETURNS 
##    TRUE|FALSE
##
## NOTES
##     NONE
##
###################
#
sub tfactlshare_tag2spl
{
  my $val = shift;
  $val =~ s/\.COLON\./\:/g;
  $val =~ s/\.BANG\./\!/g;
  $val =~ s/\.OPENB\./\(/g;
  $val =~ s/\.CLOSEB\./\)/g;
  $val =~ s/\.AMP\./\&/g;
  $val =~ s/\.DOLLAR\./\$/g;
  $val =~ s/\.HASH\./\#/g;
  $val =~ s/\.TILDA\./\~/g;
  $val =~ s/\.STAR\./\*/g;
  $val =~ s/\.LESS\./\</g;
  $val =~ s/\.GREATER\./\>/g;
  $val =~ s/\.AT\./\@/g;
  $val =~ s/\.SEMICOLON\./\;/g;
  $val =~ s/\.PIPE\./\|/g;
  $val =~ s/\.BT\./\`/g;
  return $val;

}

################
# NAME
##   tfactlshare_check_node_validity
##    
## DESCRIPTION
##   Check node validity
##
## PARAMS
##     $node - Node name(s)
##     $help - Display the help if node is not valid
##
## RETURNS 
##    @nodes - TFA nodes requested
##
## NOTES
##     NONE
##
###################
#
sub tfactlshare_check_node_validity
{
  my $tfa_home  = shift;
  my $node      = shift;
  my $help      = shift;
  my $localhost = tolower_host();
  my $nodename;
  my @nodes = ();
  my @nodes_list = ();

  # checking validity of nodes
  $node =~ tr/A-Z/a-z/;
  $node =~ s/localhost/$localhost/g;
  $node =~ s/local/$localhost/g;

  if ( $node eq "all" ) {
    @nodes_list = getListOfAllNodes( $tfa_home );
  } else {
    @nodes_list = split(/\,/,$node);
  }

  if ( $#nodes_list >= 1 &&   (grep { /all/ } @nodes_list) ) {
    print "all cannot be combined with any other node name.\n";
    print_help("$help", "") if length $help;
    exit 1;
  }
  
  if ( tfactlshare_isnodelist_duplicated($node) ) {
     print "No node can be used more than once, please correct the node list and retry.\n";
     print_help("$help", "") if length $help;
     exit 1;
  }
  
  foreach $nodename (@nodes_list) {
    ($nodename,) = split (/\./, $nodename);
    if (isNodePartOfCluster($tfa_home, $nodename)) {
      push @nodes, $nodename;
    } else {
      print "Node $nodename is not part of TFA cluster.\n";
      print_help("$help", "") if length $help;
      exit 1;
    }     
  } # end foreach
  return @nodes;
} # end sub tfactlshare_check_node_validity

1;
