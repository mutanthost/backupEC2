# 
# $Header: tfa/src/v2/tfa_home/bin/modules/tfactldiagcollect.pm /st_tfa_19/1 2019/03/04 14:02:26 gadiga Exp $
#
# tfactldiagcollect.pm
# 
# Copyright (c) 2014, 2019, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactldiagcollect.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      Diagnostic collection commands
#
#    NOTES
#     
#
#    MODIFIED   (MM/DD/YY)
#    gadiga      11/27/18 - wait for secureadd to finish
#    cnagur      07/31/18 - Bug 28078228 - Upload TFA Collections to PAR URL
#    bburton     08/07/18 - Do not prompt for issue time when silent
#    xiaodowu    07/31/18 - Add multiword validate type and make validate="" default to multiword, which would accept any input such as multi word command line
#    recornej    08/06/18 - Change SUCCESS and FAILED values.
#    recornej    08/02/18 - Add dbversion validate
#    recornej    07/30/18 - Fix exit code.
#    recornej    07/19/18 - Add validate sqlid
#    bburton     07/18/18 - 28002826 - MAKE <ONERROR> DEPENDABLE TO USER INPUT
#    recornej    07/18/18 - Fix validate_input
#    bburton     07/18/18 - 28002826 - MAKE <ONERROR> DEPENDABLE TO USER INPUT
#    bburton     07/17/18 - Bug 28100803 - ODA: SUPPORT ACR (REDACTION) OPTIONS
#    recornej    07/13/18 - Do not allow future dates as valid
#    manuegar    07/13/18 - manuegar_multibug_01.
#    recornej    07/13/18 - Do not allow future dates as valid
#    bburton     07/05/18 - Add supported DB version Array - bug 27889149
#    recornej    07/05/18 - Allowing ora600 to run in auto collection
#    xiaodowu    07/05/18 - Add entries for emomscrash, emomsheap
#                           and emomshungcpu collections
#    recornej    06/29/18 - Enh 27344898 - ENHANCE SCRIPT TYPE TAG TO ALLOW
#                           SCRIPT TO BE RUN MULTIPLE TIMES WITH INTERVAL.
#    recornej    06/28/18 - 27700655 - TFA SRDC SCRIPT TYPE EXECUTION ORDER
#                           ISSUE
#    migmoren    06/27/18 - 28201272 - TFAT: TFACTL -SINCE OPTION RETURNS A
#                           MISLEADING MESSAGGE
#    recornej    06/25/18 - Revert IS_OFFLINEMODE changes.
#    xiaodowu    06/15/18 - Add emagentperf collection to EM SRDC list
#    recornej    06/14/18 - Bug 28187526 - TFACTL DIAGCOLLECT NON DAEMON IS NOT
#                           ABLE TO RUN ON THE REMOTE NODES
#    recornej    06/01/18 - Rediscover for offline tfa.
#    bburton     05/21/18 - change default collection message
#    manuegar    05/17/18 - manuegar_adrbasechk
#    manuegar    05/15/18 - manuegar_secure_validate_db_account.
#    recornej    05/14/18 - Allow skip nested dependent user inputs.
#    manuegar    05/09/18 - Bug 27535858 - TFACTL DIAGCOLLECT -SR -H FAILING
#                           WITH MOS SETUP IS NOT DONE ERROR.
#    recornej    04/30/18 - Bug 27802752 - TFAT: DIAGCOLLECT -FROM YYYY-MM-DD
#                           ACCEPTS OTHER COMMANDS AS LS -L
#    manuegar    04/30/18 - 27948675 - LNX-18.1-TFA:TFACTL EXIT CODE DOES NOT
#                           MATCH TFACTL.PL EXIT CODE.
#    manuegar    04/19/18 - Bug 27746546 - TFAT: DIAGCOLLECT COMMAND RETURNS
#                           EXIT CODE 0 EVEN WHEN FAILS.
#    manuegar    04/18/18 - Bug 27760088 - TFAT: DIAGCOLLECT DISPLAYS MISSING
#                           MANIFEST COMMAND OUTPUT.
#    recornej    04/17/18 - Bug 27624400 - TFAT: WRONG ENVIRONMENT VARIABLES
#                           PRODUCE A MALFORMED SCRIPT
#    migmoren    04/16/18 - Bug 27605951 - VARIOUS TYPOS IN TFACTL MESSAGING
#    recornej    04/19/18 - Bug 27874177 - LNX-191-TFA:SRDC DID NOT COLLECT ASM
#                           TRACE FILES WHEN SPECIFY ASM EVENT
#    recornej    04/09/18 - 27833718 - TFA DIAGCOLLECT REQUEST EVENT TIME FOR
#                           DEFAULT COLLECTION
#    recornej    03/23/18 - Allow parsing prompt entry with equal sign and
#                           dollar sign.
#    bburton     03/19/18 - Bug 27665984 - remove use of POSIX::tmpnam
#    recornej    03/16/18 - Enh 27700719 - ADD PERLPATH IN TFA SRDC CODE
#    migmoren    03/09/18 - Bug 27630459 - TFACTL: RETURNS EXIT CODE 0 PASSING
#                           AN INVALID COMMAND
#    xiaodowu    02/27/18 - XbranchMerge xiaodowu_addxmls from
#                           st_tfa_12.2.1.3.1
#    xiaodowu    02/27/18 - XbranchMerge xiaodowu_newtxn from st_tfa_12.2.1.3.1
#    bburton     02/26/18 - XbranchMerge bburton_bug-27344806 from
#                           st_tfa_12.2.1.3.1
#    bibsahoo    02/15/18 - importing dateutils.pm
#    manuegar    02/02/18 - manuegar_shared_dbutils01.
#    xiaodowu    01/26/18 - Replace scn with dbscn
#    xiaodowu    01/24/18 - Add TFA_HOME discovery
#    recornej    01/19/18 - XbranchMerge recornej_bug-27364130 from
#                           st_tfa_12.2.1.3.1
#    manuegar    01/18/18 - XbranchMerge manuegar_bug-27344815 from
#                           st_tfa_12.2.1.3.1
#    xiaodowu    01/18/18 - Replace exalogic with esexalogic.
#    bburton     01/18/18 - Add prompt option to exit from SRDC - 27344806
#    recornej    01/17/18 - Bug 27364130 - SRDC COLLECTION FAILS WITH SYNTAX
#    xiaodowu    01/08/18 - Enh 27344795 - REMOVE ROOT EXECUTOR BLOCKER TO
#                           ALLOW TFA SRDC COLLECTION TO BE EXEUTED BY ROOT
#    recornej    01/08/18 - Add functionality to the cmdline attribute in the
#                           SRDC XML.
#    recornej    01/30/18 - Make srdc and components cannot be used together
#    recornej    01/30/18 - Prevent crash when after SRDC parsing when tags are
#                           not included
#    bburton     01/12/18 - Use DCSLOGS for DCS and zookeeper intead of
#                           racdbcloud and odalite
#    cnagur      01/03/18 - Fix for Bug 27320494
#    manuegar    12/14/17 - manuegar_em_dbdisc03.
#    recornej    11/27/17 - Adding MSG attribute.
#    bburton     11/16/17 - Fix bug 27087058 - We do nto need Time::HiRes
#    recornej    11/03/17 - Fix typo deppatt for deppattern
#    recornej    11/02/17 - Fix deppinput
#    manuegar    11/02/17 - manuegar_em_dbdisc02.
#    recornej    11/02/17 - Bug 27048735 - LNX-181-TFA:SRDC DID NOT COLLECT
#                           APX/IOS LOGS
#    bburton     11/01/17 - Fix collecting IOS and APX when event in those instances
#    bburton     11/01/17 - Fix start and end time when from and to are passed
#    recornej    10/30/17 - Adjustments in dbstartup
#    recornej    10/27/17 - Change message when timeline.out does not exists.
#    bburton     10/12/17 - fix Admin only Issues
#    recornej    10/12/17 - BUG 26951219 - LNX-18.1-TFA:SRDC DID NOT COLLECT
#                           ASM LOGS
#    cnagur      10/24/17 - Fix for Bug 27003548
#    recornej    10/23/17 - Validate to string when validate attribute is
#                           empty.
#    recornej    10/23/17 - Fix dbshutdown startup when alert log not found.
#    recornej    10/20/17 - Add srdc prefix to the errorstack calls from srdc
#    cnagur      10/24/17 - Fix for Bug 27003548
#    recornej    10/12/17 - BUG 26951219 - LNX-18.1-TFA:SRDC DID NOT COLLECT
#    recornej    10/06/17 - Fixing dereferencing errors in some versions of
#                           perl in the errorstack module.
#    recornej    09/26/17 - Fixing syntax error when running srdc ora600
#    recornej    09/25/17 - Bug 26649413 - ASM PROFILE REQUIRED FOR EXECUTING
#                           ASM SCRIPTS IN ASM INSTANCE
#    manuegar    09/20/17 - manuegar_ips_diffs.
#    manuegar    09/26/17 - Bug 26030846 - AUTOMATE DATA COLLECTION FOR
#                           DBDISCOVERY - DOC ID 2206581.1.
#    recornej    09/14/17 - Bug 25372609 - LNX64-12.2-TFA: SRDC DID NOT WORK
#                           WITH ORA EVENTS FOR ASM
#    recornej    09/13/17 - Adding errorstack module.
#    recornej    09/12/17 - Fixing license comparison.
#    recornej    08/31/17 - SRDC DBADMIN SHUTDOWN
#    manuegar    08/25/17 - manuegar_pmap_disc.
#    manuegar    08/24/17 - Bug 26474385 - SOLSP64-181-TFA: TFACTL DIAGCOLLECT
#                           ALL WILL HUNG.
#    cnagur      08/17/17 - Fix for Bug 20812024
#    manuegar    08/16/17 - Bug 26638658 - LNX64-12.2-TFA:TFA-00404 XML FILE IS
#                           NOT WELL FORMED WHEN RUNNING -SRDC DBPERF.
#    recornej    07/28/17 - Bug 26541341 - LNX64- TFA SRDC DBPERF OPTIONS -LAST
#                           AND -SINCE NO WORKING
#    manuegar    07/25/17 - manuegar-srdc_xmlparser.
#    bburton     07/24/17 - Allow for prompts dependent on previous input
#    manuegar    07/20/17 - Bug 26496985 - LNX64-12.2-TFA: DIAGCOLLECT -ALL
#                           -(SINCE|FOR|FROM|TO) DUPLICATE COMPONENTS.
#    manuegar    07/19/17 - Bug 26270696 - LNX64-12.2-TFA:NON ROOT INSTALL,
#                           DIAGCOLLECT -ALL DID NOT COLLECT CRS/ASM FILES.
#    recornej    07/13/17 - Adding srdc issue now changes
#    recornej    06/30/17 - BUG 25985797 - SRDC AUTOMATION: ENHANCE DBPERF SRDC
#                           TO INCLUDE OTHER COLLECTIONS
#    bburton     07/12/17 - bug 26431907
#    bburton     07/11/17 - support setenvs on Windows
#    bburton     07/07/17 - Do not check for new databases for full discovery
#    chchoudh    07/05/17 - excluding receiver folder from purging in manual
#                           purge
#    llakkana    07/03/17 - Upload collection to MOS changes
#    bburton     06/26/17 - 20868470 - TFA COLLECTOR CANT HANDLE FULL NODE
#                           NAMES
#    bibsahoo    06/20/17 - FIX BUG 26310064
#    bburton     06/12/17 - Need to handle the same script being valid for
#                           multiple versions.
#    bburton     06/09/17 - Not checking script versions before running
#    manuegar    05/24/17 - manuegar_srdcwin10.
#    llakkana    05/24/17 - NonDaemon Fix
#    manuegar    05/23/17 - manuegar_srdcwin09.
#    bburton     05/18/17 - ignoring duration from xmlfiles
#    manuegar    05/24/17 - manuegar_srdcwin10.
#    llakkana    05/24/17 - NonDaemon Fix
#    manuegar    05/23/17 - manuegar_srdcwin09.
#    bburton     05/18/17 - ignoring duration from xmlfiles
#    recornej    05/17/17 - Bug 26035086 - TFA NON-DAEMON MODE : TFACTL
#                           DIAGCOLLECT -IPS -INCIDENT HANGS
#    cnagur      05/16/17 - Removed -rdbms and -chmos for cells
#    manuegar    05/08/17 - XbranchMerge manuegar_srdcwin02_122 from
#                           st_tfa_12.2.1.1.01
#    manuegar    05/08/17 - XbranchMerge manuegar_srdcwin03 from
#                           st_tfa_12.2.1.1.01
#    llakkana    05/07/17 - 25860298 - Exit if database name is passed along
#                           with ash/awr html/text component
#    manuegar    05/11/17 - manuegar_srdcwin08.
#    bburton     05/09/17 - not passing baseline time to sql for dbperf
#    manuegar    05/08/17 - manuegar_srdcwin05.
#    bburton     05/08/17 - ReadKey Not required
#    bburton     05/05/17 - Do not have cfgtools as a collectall
#    manuegar    05/04/17 - manuegar_srdcwin03.
#    manuegar    05/03/17 - manuegar_srdcwin02.
#    manuegar    04/26/17 - manuegar_srdcwin01.
#    gadiga      04/25/17 - fix 25941751. strong password
#    chchoudh    04/20/17 - moving rconfig.properties and rport.txt to
#                           tfa_home/receiver/internal
#    manuegar    04/20/17 - manuegar_srdcwin_shared.
#    bburton     04/07/17 - Add validate option and Default NULL for srdc
#    manuegar    04/06/17 - manuegar_windows_srdc01.
#    manuegar    03/22/17 - emsrdc01
#    manuegar    03/21/17 - Bug 25710128 - HPI-122-TFA:FAILED COLLECT PACKAGE
#                           USING OPTION "-PROBLEMKEY".
#    manuegar    03/10/17 - Bug 25347502 - LNX64-12.2-TFA:
#                           TFA_HOME/OUTPUT/METADATA/TIMELINE.OUT: NO SUCH FILE
#                           OR DIRECTORY.
#    manuegar    03/07/17 - Bug 25671034 - AIX-12.2-TFA: RAN TFACTL AS ROOT
#                           USER SEEING "CHGRP ERRORS".
#    manuegar    02/24/17 - Bug 25616726 - WS2012_122_TFA: NO ADR HOMEPATHS
#                           WERE PROCESSED.
#    bibsahoo    02/15/17 - FIX BUG 25543588 - TFA: CHMOS DIAGCOLLECTION
#                           COLLECTS ALL THE COMPONENTS LOGS IN WINDOWS TFA
#    bburton     02/13/17 - changes to allow for local script to run and use
#                           variables
#    manuegar    01/20/17 - EM srdc.
#    manuegar    12/14/16 - Bug 25254885 - LNX64-12.2-TFA:TFACTL DIAGCOLLECT
#                           -DATABASE <VALID_DBNAME> DISPLAYS THE HELP.
#    manuegar    11/29/16 - Bug 25160573 - HPI-122-TFA:NEED TFACTL DIAGCOLLECT
#                           -DATABASE USAGE WHEN COLLECTING DATABASE LOG.
#    bburton     11/20/16 - verify homes
#    manuegar    11/07/16 - Bug 25026684 - LNX64-12.2-CRS-FCF:IT PRINT USAGE
#                           MSG DURING TFA COLLECTING LOG.
#    cnagur      11/03/16 - Fix for Bug 25039956 and 25039605
#    bburton     10/27/16 - Validate snapshots for good period
#    manuegar    10/27/16 - manuegar_srdc_14.
#    bibsahoo    10/14/16 - Removing variable CURRENT_USER
#    bburton     10/10/16 - XBR SRDC work from 12.1.2.8.3
#    manuegar    09/28/16 - Bug 24740735 - WS2012_122_TFA: TFACTL DIAGCOLLECT
#                           FAILED WITH OPTION -SILENT.
#    manuegar    09/28/16 - manuegar_srdc_12.
#    cnagur      09/27/16 - Use tfactlshare_getConfiguredComputeNodes - Bug 23320593
#    bburton     09/22/16 - changes for odalite
#    arupadhy    09/14/16 - Added rdbms/trace for intermidiate dump of trace
#                           files done by database
#    manuegar    08/31/16 - Support the -extractto switch in the TFA installer.
#    manuegar    08/31/16 - Bug 24555932 - SOLSP64-12.2-TFA: IPS COLLECTION BY
#                           TFA WAS TERNIMATED AUTOMATICALLY.
#    manuegar    08/23/16 - Clean TFA Ips logs.
#    gadiga      08/23/16 - remove setup files with sensitve data
#    manuegar    08/10/16 - srdc_11 enhancements.
#    manuegar    08/10/16 - XbranchMerge manuegar_bug-23747430 from
#                           st_tfa_12.2.0.1.0
#    manuegar    08/09/16 - Bug 23747430 - WS2012_122-TFA:TFACTL DIAGCOLLECT
#                           COMMAND HANG.
#    bburton     08/02/16 - Discover ASMIO
#    llakkana    08/02/16 - XbranchMerge manuegar_bug-24357697 from main
#    manuegar    07/28/16 - Bug 24357697 - WS2012_122_TFA: DIAGCOLLECT -IPS
#                           HANG.
#    manuegar    07/12/16 - Prompt for the AWR duration for -srdc dbperf.
#    manuegar    07/11/16 - Support IPS in non daemon mode.
#    manuegar    07/04/16 - Bug 23728090 - LNX64-12.2-TFA:HIT YNTAX ERROR NEAR
#                           UNEXPECTED TOKEN `(' WHEN COLLECTING LOGS.
#    manuegar    06/29/16 - Bug 23701024 - LNX64-12.2-TFA: MAY NOT COLLECT LOG
#                           WHEN S/W ONLY GI HOME CO-EXISTS W/ ACTIVE GI.
#    bburton     06/22/16 - get awr for zdlra
#    manuegar    06/22/16 - Added USERINPUT-PERFORM_OK.
#    manuegar    06/17/16 - Support labels in user_inputs.
#    manuegar    06/16/16 - Bug 23273091 - LNX64-12.2-TFA:CONFUSING TIME RANGE
#                           WHEN USING TFACTL DIACOLLECT INCIDENTS.
#    llakkana    06/14/16 - Fix 23582359 - Issues with collectdir flag
#    llakkana    06/14/16 - Fix 23581845 - Don't delete receiverconfig file
#                           when crs is down
#    manuegar    06/10/16 - Dynamic help part 3.
#    bburton     06/09/16 - Do not collect PROCINFO by default
#    manuegar    06/09/16 - Bug 23249404 - LNX64-12.2-TFA:DIAGCOLLECT -IPS WITH
#                           ASM ADRPATH DID NOT COLLECT ASM ALERT LOG.
#    manuegar    06/08/16 - Bug 23557806 - LNX64-12.2-TFA:DIAGCOLLECT IPS NULL
#                           ENTRIES SHOWN FOR NON MATCHING REMOTE HPATHS.
#    cnagur      06/07/16 - Run Cell Collection on all Compute Nodes
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    manuegar    06/02/16 - Bug 22025835 - LNX64-12.2-TFA:SAME IPS COLLECT CMD
#                           ON LOCAL AND REMOTE GOT DIFFERENT RESULT.
#    bburton     06/01/16 - fix ulimit call
#    gadiga      05/31/16 - cleanup acfs repository
#    gadiga      05/31/16 - GIMRDG
#    llakkana    05/30/16 - ADE Non-Daemon changes
#    amchaura    05/30/16 - configurable collection wait time for diagcollect
#                           log creation
#    amchaura    05/30/16 - XbranchMerge amchaura_configure_diag_waittime from
#                           st_tfa_12.1.2.8
#    cnagur      05/27/16 - XbranchMerge cnagur_tfa_121260_cell_issues_txn from
#                           st_tfa_12.1.2.6
#    manuegar    05/25/16 - Support silent mode in srdc.
#    bburton     05/20/16 - fix for dbperf srdc
#    manuegar    05/19/16 - Take into account the input timestamp & duration
#                           when matching events.
#    bburton     05/18/16 - support old srdc
#    manuegar    05/16/16 - Disable the RDA callout for ips pack.
#    amchaura    05/16/16 - Fix Bug 19133987 - LNX64-12.1-TFA-SCS:DID NOT
#                           INCLUDE THE NEW DB LOG LOCATION INTO REDISCOVER DIR
#    gadiga      05/16/16 - fix typo
#    manuegar    05/13/16 - Bug 23280612 - WS2012_122_TFA: "TFACTL DIAGCOLLECT
#                           -RESUMEIPS" COMMAND HANG FOREVER.
#    manuegar    05/13/16 - Bug 23273103 - WS2012_122_TFA: TFACTL DIAGCOLLECT
#                           FAILED WITH LONG TFA FILENAME.
#    bburton     05/13/16 - make duration read from the xml instead of user
#                           input
#    manuegar    05/12/16 - Xbr a few SRDC validations from 121280 to Main.
#    bburton     05/11/16 - get user env for srdc
#    manuegar    04/28/16 - SRDC validations.
#    bburton     04/28/16 - add afdboot to discovery
#    gadiga      04/27/16 - add rdbms/log and base/cfgtoollogs
#    bburton     04/26/16 - Second TX for SRDC - first is ORA-600
#    manuegar    04/18/16 - Bug 23097347 - WS2012_122_TFA: DIAGCOLLECT HIT IPS
#                           ERROR WITH -NOIPS OPTION.
#    manuegar    04/15/16 - Bug 23094988 - WS2012_122_TFA: TFACTL DIAGCOLLECT
#                           FAILED.
#    cnagur      04/14/16 - Added bash check for runReDiscovery
#    amchaura    04/06/16 - replace checkTFAMain with isTFARunning to check for
#                           TFA process
#    arupadhy    04/06/16 - Bypassing non windows related file checks in
#                           rediscoverylite
#    cnagur      04/04/16 - Fixed perm issues with cell logs
#    llakkana    03/28/16 - Bug 23007658: Use crsctl check crs instead of
#                           crs_stat -t
#    amchaura    03/28/16 - configurable deafult collection time range
#    arupadhy    03/24/16 - Allowing rediscovery to run for windows
#    manuegar    03/22/16 - Capture errors for ips show incidents.
#    manuegar    03/16/16 - Bug 22907263 - LNX64-12.2-TFA-MSG: HIT "ERROR: 13:
#                           PERMISSION DENIEDADDITIONAL INFORMATION: 1".
#    manuegar    03/14/16 - Fix diag directories for non root users.
#    manuegar    03/04/16 - Run TFA Ips collections as ADR homepath owner.
#    manuegar    03/01/16 - Exec IPS code only when -ips or DSCRIPT_DEF. 
#    amchaura    02/26/16 - Fix Bug 18474041 - LNX64-12.1-TFA-SCS:REFUSE
#                           COLLECTION WHEN LOCAL NODE DID NOT CREATE THIS DB
#    llakkana    02/25/16 - Fix osutils_cp call
#    llakkana    02/25/16 - Fix 22810666 - add receiver on sslKey = 1
#    manuegar    02/23/16 - Change TFA IPS destination to suptools directory.
#    bibsahoo    02/19/16 - DISCOVERY SCRIPT TO PERL
#    manuegar    02/18/16 - Support ips collections on windows (part 2).
#    bburton     02/12/16 - correctly set rhp directory
#    gadiga      02/09/16 - dont add receiver
#    bburton     01/28/16 - don't do awr or ash reports by default
#    manuegar    01/28/16 - Report errors/warning during ips package creation.
#    manuegar    01/26/16 - Add hidden diagcollect switch to control all_files
#                           IPS flag.
#    manuegar    01/25/16 - Support ips collections on windows.
#    cnagur      01/21/16 - Changes for JCS Dumps
#    sgoggi      01/20/16 - move tfajson_lite to internal dir
#    bburton     01/19/16 - add racdbcloud
#    gadiga      01/18/16 - restart producer if there more dirs
#    gadiga      01/14/16 - add receiver
#    manuegar    01/13/16 - Bug 22537346 - TFA : TFA DIAGCOLLECT FAILS WHEN
#                           DIAG DIR IS IN NON-DEFAULT LOC $ORACLE_HOME/LOG.
#    amchaura    01/11/16 - Added Collection Summary at the end of diagcollect
#    bburton     01/07/16 - Move to viewing a console log
#    manuegar    01/06/16 - Added support for integration tfa option all_files.
#    manuegar    12/18/15 - Support ADR paths containing special chars.
#    manuegar    12/10/15 - Added pool for TFA IPS Parallel Processing.
#    manuegar    12/09/15 - Support CRS when specifying the full ADR 
#                           homepath for the -adrhomepath switch.
#    manuegar    12/09/15 - Avoid dups in remote package completed msg for TFA
#                           IPS.
#    arupadhy    12/08/15 - Conditional execution of exec in begin block for
#                           windows, due to command difference of env - linux
#                           and set - windows
#    manuegar    12/03/15 - Bug 22178674 - HPI-122-TFA:TIME RANGE FOR IPS
#                           PACKAGE COLLECTION IS NOT CONSISTENT.
#    manuegar    12/01/15 - Allow TFA IPS pack manipulation for non root users.
#    manuegar    11/30/15 - Bug 22283921 - TFA : TFA DIAGCOLLECT NOT WORKING
#                           FOR AN INCIDENT WHEN THERE ARE > 50 INC.
#    manuegar    11/29/15 - Bug 22283193 - LNX64-12.2-TFA-IPS: ALLOW TFA IPS
#                           PACKAGE MANIPULATION FEATURE.
#    manuegar    11/25/15 - Bug 22266767 - TFA : ADR DIAGCOLLECT IS FAILING FOR
#                           LARGE NO OF INCIDENTS.
#    sgoggi      11/23/15 - tfactldiagcollect_add_topology_tfar
#    arupadhy    11/18/15 - Setting nocell variable when user is non root
#                           and machine is exadata, providing appropriate 
#                           warning message.
#    manuegar    11/09/15 - Bug 22148186 - TFA : ISSUE WITH TFA DIAGCOLLECTION
#                           ON REMOTE NODES FOR AN INCIDENT.
#    manuegar    11/06/15 - Bug 22162809 - TFA : INCIDENT DIAG COLLECT NOT
#                           WORKING.
#    manuegar    10/27/15 - Bug 22103108 - TFA :DIAGCOLLCTION FOR ASM INCIDENT
#                           DON'T CONTAIN ALERT,TRACE AND INCIDENT FILES.
#    manuegar    10/26/15 - Bug 22077161 - TFA: INCIDENT BASED DIAGCOLLECTION
#                           FROM DEFAULT $ORACLE_HOME/DIAG DIR.
#    arupadhy    10/23/15 - added readkey for windows, generic datetime in
#                           name, osutils_get_oracle_home_path, windows
#                           conditional tail
#    manuegar    10/22/15 - Bug 21943932 - LNX64-12.2-TFA:TFAC HIT DIA-49428:
#                           NO SUCH DIRECTORY OR DIRECTORY NOT ACCESSIBLE.
#    bibsahoo    10/21/15 - FIX BUG 21931573 - -CHMOS OPTION SHOULD BE REMOVED
#                           FROM DIAGCOLLECT
#    amchaura    10/21/15 - Fix Bug 21982899 - LNX64-12.2-TFA:COLLECTION
#                           FAILED, COULD NOT READ DIAGCOLLECT LOG
#    amchaura    10/16/15 - Fix Bug 22006135 - TFA : ISSUE WITH DEFAULT
#                           DIAGNOSTIC_DEST LOCATION TFA MONITORING
#    manuegar    10/15/15 - Bug 21983649 - TFA : TFA DIAGCOLLECT FOR AN
#                           INCIDENT COLLECTING TOO MANY TRACE FILES.
#    manuegar    09/29/15 - Bug 21854581 - LNX64-12.2-TFA:DIAGCOLLECT DID NOT
#                           WORK ON RAC SOFTWARE ONLY ENV.
#    cnagur      11/12/15 - Fixed Issues on JCS
#    cnagur      09/23/15 - XbranchMerge cnagur_tfa_jcs_support_txn from
#                           st_tfa_12.1.2.5
#    amchaura    09/21/15 - Fix BUG 20225347 - SOLARIS_121022GIPSU: TFA SHOULD
#                           ALLOW USER TO COLLECT LOGS AFTER CURRENT SYSTEM
#    bburton     09/17/15 - add discover of diagsnap directory
#    manuegar    09/14/15 - Bug 21768769 - LNX64-12.2-TFA: IPS FILES SHOULD BE
#                           COLLECTED IN PARALLEL.
#    bburton     09/11/15 - XbranchMerge bburton_fix_invalid_zdlra_flag from
#                           st_tfa_12.1.2.5
#    cnagur      09/09/15 - Support for JCS
#    manuegar    09/07/15 - Bug 21785398 - TFA : INCORRECT DIR STRUCTURE IN TFA
#                           ZIP FILE.
#    gadiga      09/03/15 - run discovery for non-crs also
#    manuegar    08/21/15 - Bug 21641720 - LNX64-12.2-TFA-IPS:DID NOT COLLECT
#                           IPS PKG ON LOCAL WITH MULTIPLE ADR HOMES.
#    manuegar    08/21/15 - Bug 21619229 - TFA : INCIDENT TFA DIAGNOSTIC DATA
#                           COLLECTION.
#    manuegar    08/10/15 - Bug 21552014 - LNX64-12.2-TFA-IPS:DIAGCOLLECT -IPS
#                           DID NOT WORK.
#    gadiga      08/05/15 - call autostart tools
#    bibsahoo    08/05/15 - FIX FOR BUG 21180072: -FOR <FUTURE_DATE> NOT
#                           ALLOWED
#    cnagur      08/03/15 - Fix for Bug 21471195
#    manuegar    07/31/15 - Bug 21471902 - LNX64-12.2-TFA-IPS:DIAGCOLLECT HUNG
#                           AT WAITING FOR IPS RESULT OF REMOTE NODE.
#    manuegar    07/28/15 - Bug 21463833 - TFA : INCIDENT BASED TFA DIAGCOLLECT
#                           DIR STRUCTURE ISSUE.
#    bburton     07/31/15 - allow zdlra when Exadata without cell set up
#    cnagur      07/27/15 - Fix for Bug 18068445
#    bburton     07/23/15 - increase wait time
#    gadiga      07/21/15 - refresh events
#    amchaura    07/20/15 - Fix BUG 21461656 - IT IS POSSIBLE TO OVERWRITE ANY
#                           FILE AS ROOT (STARTDIAGCOLLECTION)
#    manuegar    07/16/15 - Added tracing just before startdiagcollection.
#    bburton     07/15/15 - do not allow comman in tag
#    manuegar    07/14/15 - Bug 21352560 - LNX64-12.2-TFA:DIAGCOLLECT -IPS HUNG
#                           AT WAITING IPS RESULT.
#    bburton     07/10/15 - do not send the -user flag
#    manuegar    07/10/15 - Bug 21426172 - TFA: PROBLEM / PROBLEM KEY BASED TFA
#                           DIAGCOLLECT.
#    manuegar    07/08/15 - Fix diagcollect all.
#    manuegar    07/07/15 - Bug 21352578 - LNX64-12.2-TFA:COLLECT -IPS OF LOCAL
#                           WOULD TRY TO COLLECT IPS PKG OF REMOTE NODE.
#    manuegar    07/02/15 - Bug 21355765 - TFA DIAGCOLLECT BASED ON INCIDENT
#                           MISSING ALERT LOG, INCIDENT AND TRACE FILES.
#    cnagur      07/03/15 - Fix for Bug 21354489
#    manuegar    06/22/15 - Bug 21261716 - TFA: INCIDENT BASED TFA DIAGCOLLECT.
#    manuegar    06/17/15 - Map remote ADR homepaths.
#    cnagur      06/16/15 - Update permissions of tag dir
#    manuegar    06/16/15 - Define default IPS collection and support -noips
#                           switch.
#    manuegar    05/20/15 - TFA/Ips collection Logic 2.
#    manuegar    05/08/15 - Bug 21058787 - SOL64-12.2-TFA: DIAGCOLLECT DOES NOT
#                           WORK AT ALL.
#    manuegar    05/05/15 - Bug 19843599 - LNX64-12.1-TFA-FCS:DIAGCOLLECT
#                           SHOULD ENHANCE NODELIST CHECKING.
#    manuegar    04/23/15 - Setup IPS directories for non root users.
#    amchaura    04/20/15 - diagcollect -collectdir -nocomponent -pattern
#    manuegar    04/20/15 - Suppress dups from getsubcompvalues before
#                           processing.
#    manuegar    04/16/15 - Bug 20351399 - LNX64-12.2-TFA-FCS:DIAGCOLLECT HELP
#                           MESSAGE NEED DESCRIPTIONS FOR NEW OPTIONS.
#    manuegar    03/20/15 - Support types element in diagcollect.
#    gadiga      03/12/15 - enable support for upload
#    cnagur      03/05/15 - Fix for Bug 20652958
#    gadiga      03/03/15 - add osw dir
#    manuegar    02/17/15 - Support additional tags for components.xml
#    manuegar    02/06/15 - Secure IPS commands.
#    amchaura    02/04/15 - Fix ExaDom0 collection of remote VMGuest
#    gadiga      01/23/15 - collect toplogy
#    gadiga      01/23/15 - read time from global setting
#    cnagur      01/21/15 - Fix for Bug 20300401
#    gadiga      01/14/15 - disable clusterwide
#    gadiga      12/22/14 - add suptools to lite discovery
#    bburton     12/15/14 - Bug 20214797 - rediscovery must be silent
#    cnagur      12/15/14 - Fix for Bug 20212417
#    amchaura    12/11/14 - missed change to 24h
#    manuegar    12/10/14 - Ips collection logic
#    amchaura    12/02/14 - ER 20128119 - TFA: SET DEFAULT DIAGCOLLECT TIME
#                           RANGE TO 24HRS
#    amchaura    12/02/14 - Fix BUG 20014036 - LNX64-12.2-TFA:INCORRECT MESSAGE
#                           OF ZIPS LOC IF REMOTE REPOS IS DIFF FROM LOCAL
#    cnagur      11/25/14 - Fix for Bug 20057679
#    cnagur      11/17/14 - Fix for Bug 19380147
#    bburton     11/12/14 - 19508749 - TFA NEEDS TO COLLECT CHMOS NODE EVICTION
#                           EMERGENCY DUMPS
#    manuegar    11/06/14 - Implement <action> <toolname> <flags> for support
#                           tools.
#    amchaura    10/15/14 - Fix 19805198 - LNX64-12.2-TFA-FCS:WAIT FOR THE
#                           RESPONSE FROM TFA RESTARTING NODE FOREVER
#    manuegar    10/15/14 - Handle dynamic components.
#    cnagur      10/15/14 - Fix for Bug 19794651
#    bburton     09/26/14 - add zdlra
#    manuegar    09/25/14 - Add support for xml parsing.
#    amchaura    09/16/14 - Fix 19593632 - LNX64-12.1-TFA-SCS:RETURN INCORRECT
#                           FILENAME WHEN VALUE OF -Z WITH POSTFIX .ZIP
#    cnagur      09/09/14 - Fix for Bug 19522836
#    cnagur      08/27/14 - Added -nocores
#    amchaura    08/27/14 - Fix 18296461 LNX64-12.1-TFA-SCS:NEED A WAY TO INTERRUPT RUNNING DIAGNOSTIC COLLECTIONS
#    amchaura    08/13/14 - Fix 19425079 TFACTL -NOCHMOS DOESN'T COLLECT ANYTHING
#    manuegar    07/22/14 - Relocate tfactl_lib
#    manuegar    07/04/14 - Creation
#
############################ Functions List #################################
#
# purgeRepository
# runRacCheckDiscovery
# runODScan
# runODScanInCells
# runCellODScan
# runReDiscovery
# runReDiscoveryLite
# runReDiscoveryFull
# runDiagCollect
# runDiagcollectionInCells
# runCellDiagcollection
# runDiagCollectUser
# 
#############################################################################
BEGIN {
unless ($ENV{BEGIN_BLOCK}) {
  $ENV{POSIXLY_CORRECT} = 1;
  $ENV{BEGIN_BLOCK} = 1;
  if($^O eq "MSWin32"){
    exec 'set',"$^X",$0,@ARGV;
  }else{
    exec 'env',"$^X",$0,@ARGV;
  }
}
 $ENV{LC_ALL} = C;
}

package tfactldiagcollect;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(tfactldiagcollect_init
                 );

use Date::Manip qw(ParseDate UnixDate);

use strict;
#use warnings;
#use diagnostics;
use IPC::Open2;
use Socket;
use IO::Handle;
use File::Copy;
use File::Path;
use File::Find;
use File::Basename;
use File::Basename  qw( dirname );
use File::Spec::Functions;
use Getopt::Long;
Getopt::Long::Configure("prefix_pattern=(-|--)");
use Pod::Usage;
use Sys::Hostname;
use POSIX;
use POSIX qw(strftime);
use POSIX qw(:termios_h);
use Carp;
use Config;
use Data::Dumper;
use Socket;
use Term::ANSIColor;
use Text::ASCIITable;
use Text::Wrap;
use Time::Local;
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

use tfactlglobal;
use tfactlshare;
use osutils;
use cmdlocation;
use dbutil;
use dateutils;
use tfactlparser;

#if ($IS_WINDOWS)
#{
#  eval q{use Term::ReadKey; 1} or die $@;
#}

#################### tfactldiagcollect Global Constants ####################
my $diag_args;
my $onlyjcs = 0;
my $purge_force = 0;
my (%tfactldiagcollect_cmds) = (
                                purge            => {},
                                run              => {},
                                rediscover       => {},
                                collect          => {},
                                diagcollect      => {},
                                rundiagcollect   => {},
                         );


#################### tfactldiagcollect Global Variables ####################
my @parallelpids = ();
my $parallelndx = 0; 
my %parallelfiles = ();
my %parallelfilesdesc = ();

my @mstr_parallelpids = ();
my $mstr_parallelndx = 0;
my %mstr_parallelfiles = ();
my %mstr_parallelfilesdesc = ();

my %all_adrci_incidents;
my %all_adrci_problems;
my %all_adrci_problemkeys;

my $debugips = FALSE;
my $tfaIpsPoolSize = $TFAIPS_POOLSIZE;
my $ipsfh;
my $ipslogfh;
my $ipslogfname;
my $debugtime = strftime('%m.%d.%Y-%H.%M.%S',localtime);
my $localhost=tolower_host();

my $ipsmanageips;
my $ipsresumeips;
my $ipsdropips;
my %ipsresumeips_createpack;

my $ipspre122 = FALSE;

my $currentdir = getcwd();

my $PERL = tfactlshare_getPerl($tfa_home);

my @set_collectall_dirs;

my $ohomereq;
my $ohomereq_db;

sub is_tfactl
{
  return 1;
}


########
# NAME
#   tfactldiagcollect_init
#
# DESCRIPTION
#   This function initializes the tfactldiagcollect module.  For now it 
#   simply registers its callbacks with the tfactlglobal module.
#
# PARAMETERS
#   None
#
# RETURNS
#   Null
#
# NOTES
#   Only tfactl_main() calls this routine.
########
sub init
{
  # All of the arrays defined in the tfactlglobal module must be 
  # initialized here.  Otherwise, an internal error will result.
  push (@tfactlglobal_command_callbacks, \&tfactldiagcollect_process_cmd);
  push (@tfactlglobal_help_callbacks, \&tfactldiagcollect_process_help);
  push (@tfactlglobal_command_list_callbacks, \&tfactldiagcollect_get_tfactl_cmds);
  push (@tfactlglobal_is_command_callbacks, \&tfactldiagcollect_is_cmd);
  push (@tfactlglobal_is_wildcard_callbacks, \&tfactldiagcollect_is_wildcard_cmd);
  push (@tfactlglobal_syntax_error_callbacks, \&tfactldiagcollect_syntax_error);
  push (@tfactlglobal_no_instance_callbacks, \&tfactldiagcollect_is_no_instance_cmd);
  %tfactlglobal_cmds = (%tfactlglobal_cmds, %tfactldiagcollect_cmds);

  #Perform TFACTL consistency check if enabled
  if($tfactlglobal_hash{'consistchk'} eq 'y')
  {
     if(!tfactlshare_check_option_consistency(%tfactldiagcollect_cmds))
     {   
       exit 1;
     }
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactldiagcollect init", 'y', 'n');

}

########
# NAME
#   tfactldiagcollect_process_cmd
#
# DESCRIPTION
#   This routine calls the appropriate routine to process the command 
#   specified by $tfactlglobal_hash{'cmd'}.
#
# PARAMETERS
#   dbh       (IN) - initialized database handle, must be non-null.
#
# RETURNS
#   1 if command is found in the tfactldiagcollect module; 0 if not.
#
# NOTES
#   Only tfactl_shell() calls this routine.
########
sub tfactldiagcollect_process_cmd 
{
  my ($retval) = 0;
  my ($succ)   = 0;

  # Get current command from global value, which is set by 
  # tfactldiagcollect_parse_tfactl_args()and by tfactl_shell().
  my ($cmd) = $tfactlglobal_hash{'cmd'};

  # Declare and initialize hash of function pointers, each designating a 
  # routine that processes an tfactldiagcollect command.
  my (%cmdhash) = (
                    purge             => \&tfactldiagcollect_process_command,
                    run               => \&tfactldiagcollect_process_command,
                    rediscover        => \&tfactldiagcollect_process_command,
                    collect           => \&tfactldiagcollect_process_command,
                    diagcollect       => \&tfactldiagcollect_process_command,
                    rundiagcollect    => \&tfactldiagcollect_process_command,
                  );

  if (defined ( $cmdhash{ $cmd } ))
  {    # If user specifies a known command, then call routine to process it. #
    $retval = $cmdhash{ $cmd }->();
    $succ = 1;
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_process_cmd", 'y', 'n');

  return ($succ, $retval);
}

#========== printc
#
sub printc
{
  my $text = shift;
  if ( not $IS_WINDOWS ) {
    print color("green") . $text . color("reset");
  } else {
    print $text;
  }
  return;
}

########
# NAME
#   tfactldiagcollect_match_event
#
# DESCRIPTION
#   This function matches the event
#
# PARAMETERS
#   $events2listref
#   $starttime
#   $endtime
#   $database
#
# RETURNS
#   Timestamp,  db.<dbname>.<DBNAME>.error, ["1",">1","all"]
#   event_time, event_key
#
########
sub tfactldiagcollect_match_event {
  my $events2listref = shift;
  my $starttime      = shift;
  my $endtime        = shift;
  my $database       = shift;
  my $starttimeuts   = getValidDateFromString($starttime, "time");
  my $endtimeuts     = getValidDateFromString($endtime, "time");
  my @events2list    = @$events2listref;
  my $firsttime;
  my $lasttime;

  my $uts;
  my $timestamp;
  my $db;
  my $error;
  my @ipsm;
  my @keysm;
  my @entriesm;
  my @ips;
  my @keys;
  my @entries;
  my $i=0;
  my $im=0;
  my $imallmatched = TRUE;
  my $prevdbval = "";
  my $prevdbvalndx = -1;
  my $max_events = 10;
  my $selval = "";
  $max_events = $ENV{TFA_EVENTS_TO_LIST} if ( $ENV{TFA_EVENTS_TO_LIST} );

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_match_event " .
                    "Input ( starttime $starttime endtime $endtime database $database )", 'y', 'y');

  # removex
  foreach my $row (@events2list) {
    if ( $row =~ /(\d+) (.*)\|(.*) = (.*)/ ) {
      # $1 = uts
      # $2 = timestamp
      # $3 = database - db._mgmtdb.-MGMTDB.error
      #                 0  1       2       3
      $uts       = $1; 
      $timestamp = $2;

=head
      $ips[$i] = $2;
      $keys[$i] = $3;
=cut

      my @a = split(/\./, $3);

      my $k;
      if ( $a[0] eq "db" ) {
        if (length $a[1] ) {
          $k = $a[1];
        } elsif (length $a[2] ) {
          $k = $a[2]; # Support APX & ASM.
        } else {
          next;
        }
      }
      $k = "CRS" if ( $a[0] eq "crs" );

      $ips[$i] = $2;
      $keys[$i] = $3;

      if ( not length $prevdbval ) {
        $prevdbval = $k;
        $prevdbvalndx = $i;
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_match_event " .
                          "Comparing against ... $prevdbval", 'y', 'y');
      } else {
        if ( $prevdbval ne $k ) {
          $imallmatched = FALSE;
        }
      }
      # index. Timestamp : [database] Error
      $entries[$i] = ($i+1) . ". $timestamp : [$k] $4\n";
      $i++;

      # if $database provided try to match
      if ( ($uts >= $starttimeuts && $uts <= $endtimeuts) ) {
        if ( length $database && $database ne $k ) {
          $imallmatched = FALSE; 
        }
        $ipsm[$im] = $2;
        $keysm[$im] = $3;
        my $plus1 = $im+1;
        $entriesm[$im] = "$plus1. $timestamp : [$k] $4\n";
        ### print "match\n";
        ### print "$plus1. $timestamp : [$k] $4\n";
        $im++;
      } # end if $uts >= $starttimeuts && $uts <= $endtimeuts

    } # end if $row =~ /(\d+) (.*)\|(.*) = (.*)/
    last if ( $im == $max_events );
  } # end foreach @events2list

  if ( $im == 1 ) {
    $selval = $entriesm[0];
    $selval =~ s/\R//g;
    print "Selected value is : ( " . $selval . " )\n";
    return ($ipsm[0], $keysm[0],"1");
  } elsif ( $im > 1 ) {
    if ( (not $imallmatched) || (not $SRDCSILENT) ) {
      foreach my $ndx ( 0 .. ($im-1) ) {
        print "$entriesm[$ndx]";
      }
      my $ans = tfactlshare_get_choice ( 1, $im, "\nPlease choose the event : 1-$im [1] ", 1 );
      if ( $ans =~ /\d+/ && $ans <= $im ) {
        $selval = $entriesm[$ans-1];
        $selval =~ s/\R//g;
        print "Selected value is : ( " . $selval . " )\n";
        # Return Timestamp, db.<dbname>.<DBNAME>.error
        if ( $keysm[$ans-1] =~ /^db\.(\w+)\./ ) {
          $db = $1;
        }
        return ($ipsm[$ans-1], $keysm[$ans-1],">1 not all matched");
      } else {
        print "Error: Invalid input\n";
        exit;
      } # end if $ans =~ /\d+/ && $ans <= $im
    } else {
      print "Selected values:\n";
      foreach my $ndx ( 0 .. ($im-1) ) {
        $selval = $entriesm[$ndx];
        $selval =~ s/\R//g;
        print "(" . $selval . ")\n";
      } 
      return ($starttime, $keysm[0]  , ">1 all matched");
    } # end if not $imallmatched
  } else {
    my $maxval;
    if ( $i <= $max_events ) {
      $maxval = $i;
    } else {
      $maxval = $max_events;
    }

    print "No events matching the timestamp $starttime-$endtime.\n";
    if ( $entries[$maxval-1] =~ /\d+\.\s(.*) \: \[.*/ ) {
      $firsttime = $1;
    }
    if ( $entries[0] =~ /\d+\.\s(.*) \: \[.*/ ) {
      $lasttime = $1;
    }
    print "Could not find any events\n" if( $maxval == 0);
    exit 0 if ( $maxval == 0 ); #There are no events. No need to continue with the collection.
    print "The timestamp must be between $firsttime and $lasttime.\n";

    # If running in silent mode then abort execution
    if ( $SRDCSILENT ) {
      exit 0;
    }

    foreach my $ndx ( 0 .. ($maxval-1) ) {
      print "$entries[$ndx]";
    }
    my $ans = tfactlshare_get_choice ( 1, $maxval, "\nPlease choose the event : 1-$maxval [1] ", 1 );
    if ( $ans =~ /\d+/ && $ans <= $maxval ) {
      $selval = $entries[$ans-1];
      $selval =~ s/\R//g;
      print "Selected value is : ( " . $selval . " )\n";
      # Return Timestamp,  db.<dbname>.<DBNAME>.error
      #        event_time, event_key
      if ( $keys[$ans-1] =~ /^db\.(\w+)\./ ) {
        $db = $1;
      }
      return ($ips[$ans-1], $keys[$ans-1],"all");
    } else {
      print "Error: Invalid input\n";
      exit;
    }

  } # end if $im == 1
}

########
# NAME
#   tfactldiagcollect_match_event_check
#
# DESCRIPTION
#   This function does a match event check
#
# PARAMETERS
#   $intimestamp
#   $intimestamp2
#   $splitval
#   $events2listref
#   $defsplitval
#   $database
#
# RETURNS
#   ($starttime, $endtime,$event_time, $event_key)
#
########
sub tfactldiagcollect_match_event_check {
  my $intimestamp    = shift;
  my $intimestamp2   = shift;
  my $splitval       = shift;
  my $events2listref = shift;
  my $defsplitval    = shift;
  my $database       = shift;
  my @events2list    = @$events2listref;
  my $uts;
  my $starttime;
  my $endtime;
  my $event_time;
  my $event_key;
  my $nmatches; # Number of matches "1", ">1", "all"

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_match_event_check " .
                  "intimestamp $intimestamp , intimestamp2 $intimestamp2", 'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_match_event_check " .
                  "database $database", 'y', 'y');

  $uts = getValidDateFromString($intimestamp, "time");
  if ( not length $intimestamp2 ) {
    $starttime = strftime "%b/%d/%Y %H:%M:%S", localtime( $uts - $splitval );
    $endtime   = strftime "%b/%d/%Y %H:%M:%S", localtime( $uts + $splitval );
  } else {
    $starttime = $intimestamp;
    $endtime   = $intimestamp2;
  }
  ($event_time, $event_key, $nmatches) = tfactldiagcollect_match_event(\@events2list,$starttime,$endtime,$database);

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_match_event_check " .
                    "nmatches returned by tfactldiagcollect_match_event() -> $nmatches", 'y', 'y');

  if ( $nmatches eq "1" || $nmatches eq "all" || $nmatches eq ">1 not all matched" ) {
    $uts = getValidDateFromString($event_time, "time");
    $starttime = strftime "%b/%d/%Y %H:%M:%S", localtime( $uts - $defsplitval );
    $endtime   = strftime "%b/%d/%Y %H:%M:%S", localtime( $uts + $defsplitval );
  } else {
    $starttime = $intimestamp;
    $endtime   = $intimestamp2;
  }

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_match_event_check " .
                    "uts $uts splitval $splitval", 'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_match_event_check " .
                    "returning (starttime $starttime endtime $endtime event_time $event_time event_key $event_key)", 'y', 'y');
  return ($starttime, $endtime,$event_time, $event_key);
}

########
# NAME
#   tfactldiagcollect_match_event_check_all
#
# DESCRIPTION
#   This function list all the events
#
# PARAMETERS
#   $splitval
#   $eventsref
#   $database
#
# RETURNS
#   ($starttime, $endtime, $event_time, $event_key)
########
sub tfactldiagcollect_match_event_check_all {
  my $splitval  = shift;
  my $eventsref = shift;
  my $database  = shift;
  my @events    = @$eventsref;
  my $uts;
  my $starttime;
  my $endtime;
  my $event_time;
  my $event_key;

  ($event_time, $event_key) = tfactldiagcollect_get_event_time($tfa_home, \@events, $database);
  $uts = getValidDateFromString($event_time, "time");
  $starttime = strftime "%b/%d/%Y %H:%M:%S", localtime( $uts - $splitval );
  $endtime   = strftime "%b/%d/%Y %H:%M:%S", localtime( $uts + $splitval );

  return ($starttime, $endtime, $event_time, $event_key);
}

########
# NAME
#   tfactldiagcollect_validate_event
#
# DESCRIPTION
#   This function validates the event
#   when using the switches from/to/for/since/duration
#
# PARAMETERS
#   $firstevent
#   $lastevent
#   $from
#   $to
#   $for
#   $since
#   $duration
#   $events_ref
#   $database
#   $events2listref
#
# RETURNS
#   ($from, $to, $for, $since, $duration)
########
sub tfactldiagcollect_validate_event {
  my $firstevent = shift;
  my $lastevent  = shift;
  my $from       = shift;
  my $to         = shift;
  my $for        = shift;
  my $since      = shift;
  my $duration   = shift;
  my $events_ref  = shift;
  my $database   = shift;
  my $events2listref = shift;
  my @events     = @$events_ref;
  my @events2list = @$events2listref;
  my $userinp    = "";
  my $userinp2   = "";
  my $event_time;
  my $event_key;

  my $uts;
  my $splitval;
  my $localsplitval;
  my $validts;
  my $firsttime = strftime "%b/%d/%Y %H:%M:%S", localtime $firstevent;
  my $lasttime  = strftime "%b/%d/%Y %H:%M:%S", localtime $lastevent;
  my $starttime;
  my $endtime;

  my $checkmatchevent = TRUE;

  if ( $duration ) {
    my $timeval;
    if ( $duration =~ /^(\d+?)h{1}$/ ) {
      $timeval = $1 * 60 * 60;
    } elsif ( $duration =~ /^(\d+)d{1}$/ ) {
      $timeval = $1 * 24 * 60 * 60;
    }
    $splitval = $timeval / 2;
  } else {
     $splitval = (12 * 60 * 60) / 2;
  } # end if $duration

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_validate_event " .
                  "Input (from,to,for,since,duration) - ($from,$to,$for,$since,$duration)", 'y', 'y');

  {
  if ( $from && not $to) {
    $validts = getValidDateFromString($from, "startdate");
    if ( $validts eq "invalid") {
      print "The timestamp $from used in the -from switch is invalid.\n";
      exit 1;
    }    
    $endtime   = strftime "%b/%d/%Y %H:%M:%S", localtime( time() );
    if ( $checkmatchevent ) {
      ($starttime, $endtime, $event_time, $event_key) = tfactldiagcollect_match_event_check($from,$endtime,$splitval,\@events2list,$splitval,$database);
      $from = $starttime;
      $to   = $endtime;
    }
    last;
  } # end if $from && not $to

  if ( $from && $to) {
    $validts = getValidDateFromString($from, "startdate");
    if ( $validts eq "invalid") {
      print "The timestamp $from used in the -from switch is invalid.\n";
      exit 1;
    }
    $validts = getValidDateFromString($to, "startdate");
    if ( $validts eq "invalid") {
      print "The timestamp $to used in the -to switch is invalid.\n";
      exit 1;
    }

    if ( $checkmatchevent ) {
      ($starttime, $endtime, $event_time, $event_key) = tfactldiagcollect_match_event_check($from,$to,$splitval,\@events2list,$splitval,$database);
      $from = $starttime;
      $to   = $endtime;
    }
    last;
  } # end if $from && $to

  if ( $since ) {
    my $timeval;
    if ( $since  =~ /([0-9]+)[hH]/ ) {
      $timeval = $1 * 60 * 60;
    } elsif ( $since  =~ /([0-9]+)[dD]/ ) {
      $timeval = $1 * 24 * 60 * 60;
    }
    $localsplitval = $timeval / 2;
    $starttime = strftime "%b/%d/%Y %H:%M:%S", localtime( time() - $timeval );
    $endtime   = strftime "%b/%d/%Y %H:%M:%S", localtime( time() );
    if ( $checkmatchevent ) {
      ($starttime, $endtime, $event_time, $event_key) = tfactldiagcollect_match_event_check($starttime,$endtime,$localsplitval,\@events2list,$splitval,$database);
      $since  = "";
      $from   = $starttime;
      $to     = $endtime;
    }
    last;
  } # end for since

  if ( $for ) {
    $validts = getValidDateFromString($for, "startdate");
    if ( $validts eq "invalid") {
      print "The timestamp $for used in the -for switch is invalid.\n";
      print "The timestamp must be between $firsttime and $lasttime.\n";
      $userinp = tfactlshare_input_date("Enter timestamp [YYYY-MM-DD HH24:MI:SS,<RETURN>=10 LAST EVENTS] : ", "The timestamp format used is invalid.\n", $firstevent, $lastevent, $firsttime, $lasttime);
      if ( not length $userinp ) {
        ($starttime, $endtime, $event_time, $event_key) = tfactldiagcollect_match_event_check_all($splitval,\@events, $database);
        $for  = "";
        $from = $starttime;
        $to   = $endtime;
        $checkmatchevent = FALSE;
      } else {
        $for = $userinp;
      }
    } # end if $validts eq "invalid"

    if ( $checkmatchevent ) { 
      ($starttime, $endtime, $event_time, $event_key) = tfactldiagcollect_match_event_check($for,"",$splitval,\@events2list,$splitval,$database);
      $for  = "";
      $from = $starttime;
      $to   = $endtime;
    } 
  }  # end if $for

  }

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_validate_event " .
                    "Output (from,to,for,since,duration) - ($from,$to,$for,$since,$duration)", 'y', 'y');

  return ($from, $to, $for, $since, $duration, $event_time, $event_key);
}

########
# NAME
#   tfactldiagcollect_validate_prevcurr
#
# DESCRIPTION
#   This function compares the previous and current values 
#   of input parameters in order to determine $DSCRIPT_OPTS value
#
# PARAMETERS
#   $pfor
#   $for
#   $pfrom
#   $from
#   $pto
#   $to
#   $psince
#   since 
#   $dscript_opts_ref
#   $DSCRIPT_OPTS
#
# RETURNS
#   $DSCRIPT_OPTS
########
sub tfactldiagcollect_validate_prevcurr {
  my $pfor = shift;
  my $for = shift;
  my $pfrom = shift;
  my $from = shift;
  my $pto = shift;
  my $to = shift;
  my $psince = shift;
  my $since = shift;
  my $DSCRIPT_OPTS = shift;

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_validate_prevcurr " .
                    "Input DSCRIPT_OPTS $DSCRIPT_OPTS", 'y', 'y');

  # ---- for ----
  if ( (length $pfor && length $for) && ($pfor ne $for ) ) {
    $DSCRIPT_OPTS =~ s/ -for $pfor/ -for $for/;
  }
  if ( (not length $pfor) && (length $for) ) {
    $DSCRIPT_OPTS .= " -for $for";
  }
  if ( (length $pfor) && (not length $for) ) {
    $DSCRIPT_OPTS =~ s/ -for $pfor//;
  }

  # ---- from ----
  if ( (length $pfrom && length $from) && ($pfrom ne $from) ) {
    $DSCRIPT_OPTS =~ s/ -from $pfrom/ -from $from/;
  }
  if ( (not length $pfrom) && (length $from) ) {
    $DSCRIPT_OPTS .= " -from $from";
  }
  if ( (length $pfrom) && (not length $from) ) {
    $DSCRIPT_OPTS =~ s/ -from $pfrom//;
  }

  # ---- to ----
  if ( (length $pto && length $to) && ($pto ne $to) ) {
    $DSCRIPT_OPTS =~ s/ -to $pto/ -to $to/;
  }
  if ( (not length $pto) && (length $to) ) {
    $DSCRIPT_OPTS .= "  -to $to";
  }
  if ( (length $pto) && (not length $to) ) {
    $DSCRIPT_OPTS =~ s/ -to $pto//;
  }

  # ---- since ----
  if ( (length $psince && length $since) && ($psince ne $since) ) {
    $DSCRIPT_OPTS =~ s/ -since $psince/ -since $since/;
  }
  if ( (not length $psince) && (length $since) ) {
    $DSCRIPT_OPTS .= " -since $since";
  }
  if ( (length $psince) && (not length $since) ) {
    $DSCRIPT_OPTS =~ s/ -since $psince//;
  }

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_validate_prevcurr " .
                    "Output DSCRIPT_OPTS $DSCRIPT_OPTS", 'y', 'y');

  return $DSCRIPT_OPTS;
}

########
# NAME
#   tfactldiagcollect_getrange_for_event
#
# DESCRIPTION
#   This function returns the time range
#   for the event_time when the duration
#   switch is used
#
# PARAMETERS
#   $event_time
#   $duration
# RETURNS
#   ( $starttime, $endtime )
########
sub tfactldiagcollect_getrange_for_event {
  my $event_time = shift;
  my $duration   = shift;
  my $starttime;
  my $endtime;

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_getrange_for_event " .
                    "Input (event_time,duration) - ($event_time,$duration) ", 'y', 'y');

  if ( $event_time ) {
    my $uts;
    my $validts;

    $validts = getValidDateFromString($event_time, "startdate");
    if ( $validts eq "invalid") {
      print "The timestamp $event_time is invalid.\n";
      exit 1;
    }
    $uts = getValidDateFromString($event_time, "time");

    if ( length $duration ) {
      my $timeval;
      my $splitval;
      if ( $duration =~ /^(\d+?)h{1}$/ ) {
        $timeval = $1 * 60 * 60;
      } elsif ( $duration =~ /^(\d+)d{1}$/ ) {
        $timeval = $1 * 24 * 60 * 60;
      }
      $splitval = $timeval / 2;
      $starttime = strftime "%b/%d/%Y %H:%M:%S", localtime( $uts - $splitval );
      $endtime   = strftime "%b/%d/%Y %H:%M:%S", localtime( $uts + $splitval );
    }
  } # end if $event_time  

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_getrange_for_event " .
                    "Return (starttime,endtime) - ($starttime,$endtime) ", 'y', 'y');

  return ($starttime, $endtime);
}

########
# NAME
#   tfactldiagcollect_process_command
#
# DESCRIPTION
#   This function ...
#
# PARAMETERS
#
# RETURNS
#   Null.
#
# NOTES
#   Only tfactldiagcollect_process_cmd() calls this function.
########
sub tfactldiagcollect_process_command
{
my $exitcode = 0;
dscriptoptions:
{
  tfactlshare_trace(3, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_process_command", 'y', 'n');
  @ARGV = @tfactlglobal_argv;

$debugips = tfactlshare_getdebugips($tfa_home);
$tfaIpsPoolSize = tfactlshare_getTfaIpsPoolSize($tfa_home);
open ($ipsfh, ">>", catfile($tfactlglobal_trace_path,"tfactldiagcollect_ips_$localhost.log") ) or die  
"Could not open " . catfile($tfactlglobal_trace_path,"tfactldiagcollect_ips_$localhost.log") . "\n" if $debugips;
$ipslogfname = catfile($tfactlglobal_trace_path,"tfaips.$debugtime.$localhost.log");
open ($ipslogfh, ">>",$ipslogfname) or die
"Could not open " . $ipslogfname . "\n";

# We need to pass all flags to script in case of diagcollect
$DSCRIPT_OPTS  = "";
$DSCRIPT_DEF   = FALSE;
$DSCRIPT_NOIPS = FALSE;
$DSCRIPT_IPS   = FALSE;
if ( $ARGV[0] =~ /^diagcollect$/ || $ARGV[0] =~ /^collect$/ )
{ 
  my @diagoptions;
  my %diaghashoptions;
  my %componentshash;
  my @subcompvalsarray;
  my @matchedsubcompvalsarray;
  my @uniquematchedsubcompvalsarray;
  my %uniquesubcompvals;       # Unique subcomponents list
  my %notfoundsubcomps;        # Subcomponents not located
  my %notfoundsubcompswidx;    # Subcomponents not located w/index
  my %foundsubcomps;           # Subcomponents located
  my %inptypeforsubcomp;       # Input type for subcomponent,
                               # input, default or selected
  my $componentmatch = FALSE;  # Is there at least one validation component match ?
  my $validatecomponentsused = FALSE; # Validation components used in cmdline ?
  my $addcompstring;
  my $addcomphlpstring;
  my $addcompstring_exadata;
  my $addcomphlpstring_exadata;
  my $addcompstring_oda;
  my $addcomphlpstring_oda;
  my $addcompstring_racdbcloud;
  my $addcomphlpstring_racdbcloud;

  my $isaddcomp = 0;
  my $database;
  my $em_targetdbname;
  my $em_targetasminstance;
  my $em_repositorydbname;
  my $em_remdata = FALSE;
  my $em_repositorydb_provided = FALSE;
  my $em_repositorydb_repvfy = "";
  my $em_repositorydb_ohome  = "";
  my $em_repositorydb_tns    = "";
  my $em_hostrepodb;
  my $em_portrepodb;
  my $em_servicerepodb;
  my $em_dbsnmppwd;
  my $em_sysmanpwd;
  my @emtargets;
  my %emtargets;
  my $since;
  my $last;
  my $from;
  my $to;
  my $for;
  my $baselineto;
  my $baselinefrom;
  my $baselinefor;
  my $nochmos;
  my $noextra;
  my $nocores;
  my $collectalldirs;
  my $collectdir;
  my $nocomponent;
  my $pattern;
  my $asmio;
  my $asmproxy;
  my $exadata;
  my $computenode;
  my $all;
  my $node;
  my $exadatacell;
  my $nocell;
  my $copy;
  my $copytocomputenode;
  my $cluster;
  my $help;
  my $output;
  my $symlink;
  my $tag;
  my $logid;
  my $monitor;
  my $nomonitor;
  my $notrim;
  my $sanitize;
  my $mask;
  my $ips;
  my $defips;
  my @ipsflag;
  my $ipsfound = "not found";
  my $adrbasepath;
  my $adrhomepath;
  my $adrcorrlvl;
  my $oraclehome;
  my $ipsincident;
  my $ipsproblem;
  my $ipsproblemkey;
  my $ipsallfiles;
  my $examplesreq;
  my $event;
  my $duration;
  my $awrduration;
  my $cmd1 = $ARGV[0];
  my $arg;
  my $paramfile = tfactlshare_getSetupFilePath($tfa_home);
  my $unknownopt = 0;
  my $xmlstring;
  my $xmlfilters;
  my $xmlcontent = FALSE;
  my $firstargv;
  my $allargv;
  my %discemcomp;
  my $emcomps="";
  my $par;
  my $event_time;

  my $localhost=tolower_host();

  #my @tolist;
  #my @fromlist;

# Reset TFA-IPS environment
  $TFAIPS_ADRCIHOMEPATH   = "";
  $TFAIPS_ADRCIORACLEHOME = "";
  $TFAIPS_ADRHOMEPATH     = "";
  $TFAIPS_CORRLVL         = "basic";
  $TFAIPS_INCIDENTNMBR    = "";
  $TFAIPS_PROBLEMNMBR     = "";
  $TFAIPS_PROBLEMKEY      = "";
  $TFAIPS_UNDO_ADRBASEPATH = "";
  $TFAIPS_UNDO_ADRHOMEPATH = "";
  undef %tfactlglobal_adrbasepaths;

  shift @ARGV;
  $firstargv = $ARGV[0];
  $allargv   = "@ARGV";
  foreach $arg (@ARGV) {
      #Replace -- with - if present in argument list
      if ( $arg =~ /^--/ ) {
        $arg =~ s/^--/-/;
      }
      $DSCRIPT_OPTS .= " $arg" if lc($arg) ne "-help" && lc($arg) ne "-examples" && lc($arg) ne "-h";
  }

  if ( $DSCRIPT_OPTS =~ /\s{2,}/ ) {
    $DSCRIPT_OPTS =~ s/\s{2,}/ /g;
  }

  # add the -procinfo component if -acfs is specifically requested..
  $DSCRIPT_OPTS =~ s/-acfs/-acfs -procinfo/;
  $diag_args = $DSCRIPT_OPTS;

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                    		"BEFORE GetOptions $DSCRIPT_OPTS",
                    'y', 'y');

  # GetOptions setup
  @diagoptions = ( 'database=s', 'since=s', 'last=s', 'duration=s', 'from=s', 'event_time=s',
                   'to=s', 'for=s', 'baselinefrom=s', 'baselineto=s', 'baselinefor=s', 
		    'nochmos!',     'noextra!', 'sr=s',
                   'collectalldirs!',       'collectdir=s', 'nocomponent!', 'all!',
                   'node=s',     'cell=s',  'onlycell!', 'pattern=s', 'nocell!',
                   'help|h!',    'copy!',   'copytocomputenode=s',
                   'c!',         'z=s',     'symlink!',     'tag=s',
                   'logid=s',    'event=s', 'monitor!',     'onlyjcs!',   'upload_user=s',
                   'comment=s',    'bug=s', 'bugsftp!', 'upload!', 'srdc=s',
                   'silent!', 'notrim!', 'sanitize!', 'mask!', 'nocores!', 'ips!', 'defips!', 'adrbasepath=s', 'adrhomepath=s',
                   'oraclehome=s', 'incident=s', 'problem=s', 'problemkey=s', 'manageips!',
                   'dropips=s', 'resumeips=s', 'level=s', 'ipsallfiles!', 'par=s', 'examples!' );

  # Retrieve components
  for my $ndx ( 0 .. $#xmlcompsarray ) {
    my $typeref = $xmlcompsarray[$ndx][COMPTYPE];
    my @typesarray = @$typeref;
    # Validation component ?
    if ( lc($xmlcompsarray[$ndx][COMPVALIDATE]) eq "true" ) {
      push @diagoptions, lc($xmlcompsarray[$ndx][COMPNAME]) . "!";
      # Get subcomponents
      my $subxmlcompsarrayref = $xmlcompsarray[$ndx][COMPSUB];
      my @subcompsderef = @$subxmlcompsarrayref;
      for my $idx ( 0 .. $#subcompsderef ) {
         my $subcompref = $subcompsderef[$idx];
         my @subcomps = @$subcompref;
         push @diagoptions, lc($xmlcompsarray[$ndx][COMPNAME]) . "_" . 
                            $subcomps[SUBCOMPNAME] . "=s";
         # Initialize components hash 
         # Associate component for a given component_subcomponent
         $componentshash{lc($xmlcompsarray[$ndx][COMPNAME])."_".$subcomps[SUBCOMPNAME]} = 
                         lc($xmlcompsarray[$ndx][COMPNAME]);
         push @retcomparray, [ lc($xmlcompsarray[$ndx][COMPNAME]) ."_".
                               $subcomps[SUBCOMPNAME] , 
                               [@typesarray], 
                               lc($xmlcompsarray[$ndx][COMPCONFIG]), 
                               "subcomponent" ];
      } # end for $#subcompsderef
    } else {
      # If not on cloud, ignore validation component
      if ( lc($xmlcompsarray[$ndx][COMPVALIDATE]) ne "ignore"  ) {
        push @diagoptions, lc($xmlcompsarray[$ndx][COMPNAME]) . "!";
      }
    }
  } # end for $#xmlcompsarray

  my $omit_comp = 'rdbms!';
  @diagoptions = grep {$_ ne $omit_comp} @diagoptions;
  $omit_comp = 'chmos!';
  @diagoptions = grep {$_ ne $omit_comp} @diagoptions;
  ###print "diagoptions array @diagoptions \n\n";
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                                "diagoptions array @diagoptions",
                    'y', 'y');

  %diaghashoptions = (
        'database'       =>\$database,
        'since'          =>\$since,
        'last'           =>\$last,
        'duration'       =>\$duration,
        'from'           =>\$from,
        'to'             =>\$to,
        'for'            =>\$for,
        'nochmos'        =>\$nochmos,
        'noextra'        =>\$noextra,
        'nocores'        =>\$nocores,
        'collectalldirs' =>\$collectalldirs,
        'collectdir'     =>\$collectdir,
        'pattern'        =>\$pattern,
        'exadata'        =>\$exadata,
        'asmproxy'       =>\$asmproxy,
        'asmio'          =>\$asmio,
        'computenode'    =>\$computenode,
        'all'            =>\$all,
        'nocomponent'    =>\$nocomponent,
        'node'           =>\$node,
        'cell'           =>\$exadatacell,
        'onlycell'       =>\$onlycell,
        'onlyjcs'        =>\$onlyjcs,
        'nocell'         =>\$nocell,
        'help'           =>\$help,
        'h'              =>\$help,
        'copy'           =>\$copy,
        'copytocomputenode'=>\$copytocomputenode,
        'c'              =>\$cluster,
        'z'              =>\$output,
        'symlink'        =>\$symlink,
        'tag'            =>\$tag,
        'logid'          =>\$logid,
        'event'          =>\$event,
        'monitor'        =>\$monitor,
        'upload_user'    =>\$TFAUSER,
        'bug'            =>\$TFABUG,
        'sr'             =>\$TFASR,
        'upload'         =>\$TFAUPLOAD,
        'bugsftp'        =>\$TFABUGSFTP ,
        'comment'        =>\$TFACMT ,
        'silent'         =>\$nomonitor,
        'srdc'           =>\$xmlfilters,
        'baselineto'     =>\$baselineto,
        'baselinefrom'   =>\$baselinefrom,
        'baselinefor'    =>\$baselinefor,
        'notrim'         =>\$notrim,
        'sanitize'         =>\$sanitize,
        'mask'           =>\$mask,
        #'ips'            =>\$ips,
        'ips'            =>\@ipsflag,
        'defips'         =>\$defips,
        'incident'       =>\$ipsincident,
        'problem'        =>\$ipsproblem,
        'problemkey'     =>\$ipsproblemkey,
        'adrbasepath'    =>\$adrbasepath,
        'adrhomepath'    =>\$adrhomepath,
        'manageips'      =>\$ipsmanageips,
        'dropips'        =>\$ipsdropips,
        'resumeips'      =>\$ipsresumeips,
        'level'          =>\$adrcorrlvl,
        'oraclehome'     =>\$oraclehome,
        'ipsallfiles'    =>\$ipsallfiles,
        'par' 		 =>\$par,
        'examples'       =>\$examplesreq,
        'event_time'     =>\$event_time
      );
  {
    my $warning;
    local $SIG{__WARN__} = sub {$warning = $_[0];};# Supress warnings
    GetOptions( \%diaghashoptions, @diagoptions )
    or $unknownopt = 1;
    if ( $xmlfilters ) { 
      #If SRDC dont show error message check if arguments are valid 
      #for this particular SRDC        
      $unknownopt = 0;
      if ( length $warning != 0 ) {
        my $option = $warning;
        $option =~ s/Unknown option://g;
        $option =~ s/^\s+|\s+$//g;
        $option = "-".$option;
        unshift(@ARGV,$option);
      }
    } elsif ( $unknownopt ) {
      print "$warning"; #Show Warning if the warning was present and it is not an SRDC
    }
  }
  if ( $unknownopt )
  {
    print "arg $arg\n" if length $arg;
    print_help("diagcollect", "$arg");
    $exitcode = 1;
    last dscriptoptions;
  }
  if ( $mask && $sanitize ) {
    print "-sanitize & -mask switch cannot be used at the same time.\n";
    print "Please try again.\n";
    $exitcode = 1;
    last dscriptoptions;
  }

  #Do not process anything else if any date is invalid
  #===================================================
  if ( $to ) {
    my $to2 = $to; 
    $to = getValidDateFromString($to, "date" );
    if ( $to eq "invalid" ){
     print "The date entered is invalid: $to2 \n";
     exit 1;
    }
  }
  if ( $from ) {
    my $from2 = $from;
    $from = getValidDateFromString($from, "date");
    if ($from eq "invalid" ) {
      print "The date entered is invalid: $from2 \n";
      exit 1;
    }
  }

  # Run in Background if PAR
  # Dont copy remote collections
  if ( $par ) {
    print "Running collection is silent mode as option -par is set\n";
    $nomonitor = 1;
    $copy = 0;
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                     "par : $par , nomonitor : $nomonitor ", 'y', 'y');
  }

  #===================================================
  #For now we are not collecting awrhtml/awrtext and ashhtml/ashtext reports by default
  #If awrhtml/awrtext/ashhtml/ashtext flag passed, database name has to be specified
  if ( exists $diaghashoptions{awrhtml} || exists $diaghashoptions{awrtext} ||
       exists $diaghashoptions{ashhtml} || exists $diaghashoptions{ashtext} ) {
    if ( !$database && $database ne "all" ) {
      print "TFA Error: Database name or a comma separated list of database names has to be passed (using -database flag) to gather AWR and/or ASH reports\n";
      $exitcode = 1;
      last dscriptoptions;
    }
  }

  if ( $examplesreq ) {
    if ( length $DSCRIPT_OPTS ) {
      print "-examples switch cannot be combined with any other switches (except -help).\n";
      print_help("diagcollect","");
      $exitcode = 1;
      last dscriptoptions;
    } # end if length $DSCRIPT_OPTS
    print_help("diagcollect", "examples");
    $exitcode = 1;
    last dscriptoptions;
  } # end if $examplesreq

  # Check TFA IPS package manipulation switches
  if ( length $ipsresumeips ) {
    $DSCRIPT_OPTS =~ s/ -resumeips .*ipscoll_$localhost//g;
    my $optslen = length $DSCRIPT_OPTS;
    if ( $optslen ) {
      print "When the switch -resumeips is used no other switch can be used at the same time.\n";
      $exitcode = 1;
      last dscriptoptions;
    }
  }
  if ( $debugips ) {
    print $ipsfh "$debugtime tfactldiagcollect_process_cmd DSCRIPT_OPTS $DSCRIPT_OPTS\n",
                 "$debugtime tfactldiagcollect_process_cmd ipsresumeips $ipsresumeips\n",
                 "$debugtime tfactldiagcollect_process_cmd ipsmanageips $ipsmanageips\n";
  }

  if ( not length $ipsresumeips ) {
  print $ipsfh "$debugtime tfactldiagcollect_process_cmd Normal processing, not length ipsresumeips\n" if $debugips;
  $addcompstring            = $ADDCOMPSTRING;
  $addcomphlpstring         = $ADDCOMPHLPSTRING;
  $addcompstring_exadata    = $ADDCOMPSTRING_EXADATA;
  $addcomphlpstring_exadata = $ADDCOMPHLPSTRING_EXADATA;
  $addcompstring_oda        = $ADDCOMPSTRING_ODA;
  $addcomphlpstring_oda     = $ADDCOMPHLPSTRING_ODA;
  $addcompstring_racdbcloud        = $ADDCOMPSTRING_RACDBCLOUD;
  $addcomphlpstring_racdbcloud     = $ADDCOMPHLPSTRING_RACDBCLOUD;

  $isaddcomp        = 0;  # Check additional options availability

  $ipsfound = "found" if exists $diaghashoptions{'ips'} &&
         ref($diaghashoptions{'ips'}) ne "SCALAR";
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                   "Component ips detected ... $ipsfound", 'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                   "Arr ipsflag @ipsflag , count: " . $#ipsflag, 'y', 'y');

  my $ipscount = 0;
  my $noipscount = 0;
  if ( @ipsflag ) {
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                   "ipsflag was used ...", 'y', 'y');
    foreach my $val ( @ipsflag ) {
       $ipscount++ if $val == 1;
       $noipscount++ if $val == 0;
    }
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                   "ipscount $ipscount , noipscount $noipscount", 'y', 'y');

    if ( $ipscount >= 1 && $noipscount >= 1 ) {
      print "-ips and -noips flag cannot be used at the same time.\n";
      print_help("diagcollect", "");
      $exitcode = 1;
      last dscriptoptions;
    } elsif ( $ipscount > 1 && $noipscount == 0 ) {
      print "-ips switch cannot be used more than once.\n";
      print_help("diagcollect", "");
      $exitcode = 1;
      last dscriptoptions;
    } elsif ( $noipscount > 1 && $ipscount == 0 ) {
      print "-noips switch cannot be used more than once.\n";
      print_help("diagcollect", "");
      $exitcode = 1;
      last dscriptoptions;
    } elsif ( $ipscount >= 1 && $defips ) {
      print "-defips and -ips flags cannot be used at the same time.\n";
      print_help("diagcollect", "");
      $exitcode = 1;
      last dscriptoptions;
    } elsif ( $noipscount >= 1 && $defips ) {
      print "-defips and -noips flags cannot be used at the same time.\n";
      print_help("diagcollect", "");
      $exitcode = 1;
      last dscriptoptions;
    } else {
        if ( $ipscount == 1 ) {
          $ips = 1;
          $DSCRIPT_IPS = TRUE;
        } elsif ( $noipscount == 1 ) {
          $DSCRIPT_NOIPS = TRUE;
          delete $diaghashoptions{'ips'};
          tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                            "Deleting hash entry for ips", 'y', 'y');
        } else {
          delete $diaghashoptions{'ips'};
          tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                            "Deleting hash entry for ips", 'y', 'y');
        }
    }
  } else {
    delete $diaghashoptions{'ips'};
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "Deleting hash entry for ips", 'y', 'y');
  } # end if @ipsflag

  # defips section
  if ( $defips ) {
    $DSCRIPT_RUNDEF=1;
    if ( $DSCRIPT_OPTS =~ /\-defips/ ) {
      $DSCRIPT_OPTS =~ s/\-defips //g;           
    }
  } else {
    $DSCRIPT_RUNDEF=0;
  }

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                    "ips $ips", 'y', 'y');

  # Also-collects  
  $xmlstring = "-xmlstring ";
  $xmlstring .= '[components]';
  my $loopingtrc = "";
  for my $ndx ( 0 .. $#retcomparray ) {
    # sensitive compname
    my $compname = $retcomparray[$ndx][RETCOMPNAME];
    my $typesref = $retcomparray[$ndx][RETCOMPTYPE];
    my @typesarray = @$typesref;
    my $compconfig = lc($retcomparray[$ndx][RETCOMPCONFIG]);
    my $compvalidate = lc($retcomparray[$ndx][RETCOMPVALIDATE]);
    # print "diagcollect name $compname type @typesarray config $compconfig \n";

    my $cmdlineoption = 0;
    # Was this component sent in the cmdline ?
    if ( defined $compvalidate && $compvalidate ne "subcomponent" && 
         exists $diaghashoptions{$compname} &&
         ref($diaghashoptions{$compname}) ne "SCALAR" ) {
      # Yes, component included
      ###print "compname sent in cmd line $compname \n";
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "==========> compname sent in cmd line $compname", 'y', 'y');
      if ( $xmlfilters ) { #Make SRDC and components mutually exclusive 
        print "SRDC Collection cannot be run along with any component \n";
        print "Exiting ...\n";
        return;
      }
      push @DSCRIPT_COMP_CMDLINE, $compname if $compname ne "ips";
      
      if ( $compvalidate eq "true" ) {
      my @inputsubcomps;
      my %inputsubcompshash;
      my %originalinputsubcompshash;
      my %defaultsubcompshash;
      my %selectedsubcompshash;
      my %requiredsubcomp;
      my %requiredsubcompnotincmdline;
      my %allsubcomps;

      # RESET ARRAY/HASH STRUCTS
      undef @subcompvalsarray;
      undef @matchedsubcompvalsarray;
      undef @uniquematchedsubcompvalsarray;
      undef %uniquesubcompvals;
      undef %notfoundsubcomps; 
      undef %notfoundsubcompswidx;
      undef %foundsubcomps;
      undef %inptypeforsubcomp;
      $validatecomponentsused = TRUE; # Validation component used in cmdline

      # --------------------------------------
      # Validation components check
      # Validate that the right sumcomponents are being used.
      # Set $requiredsubcomp{}
      #     $requiredsubcompnotincmdline{}
      ### print "Diagcollect validate components array @validatexmlcompsarray \n";
      # --------------------------
      for my $ndx ( 0 .. $#validatexmlcompsarray ) {
        my $validatecomp;
        my $arrayref = $validatexmlcompsarray[$ndx];
        my @derefsubcomps = @$arrayref;
        $validatecomp = $derefsubcomps[VALIDATECOMP] ."_". $derefsubcomps[VALIDATESUBCOMPNAME];
        ### print "Diagcollect, subcomponent array $ndx @derefsubcomps \n";
        
        if ( $compname eq $derefsubcomps[VALIDATECOMP] ) { 
          # Store required components
          if (  lc($derefsubcomps[VALIDATESUBCOMPREQUIRED]) eq "true" ) {
            $requiredsubcomp{$derefsubcomps[VALIDATESUBCOMPNAME]} = 1;
          }
          # Store default subcomphash
          $defaultsubcompshash{ $derefsubcomps[VALIDATESUBCOMPNAME] } =
                        $derefsubcomps[VALIDATESUBCOMPDEFAULT];
          # Store all available subcomponents
          $allsubcomps{ $derefsubcomps[VALIDATESUBCOMPNAME] } =
                        $derefsubcomps[VALIDATESUBCOMPIDX];

          if ( exists $diaghashoptions{$validatecomp} &&
               ref($diaghashoptions{$validatecomp}) ne "SCALAR" ) {
               if (  lc($derefsubcomps[VALIDATESUBCOMPREQUIRED]) eq "true" ) {
                 ####print "Trying to use the value " . $diaghashoptions{$validatecomp} .
                 ####      " for the required subcomponent " . $validatecomp . "...\n"; 
               } else {
                 ####print "Trying to use the value " . $diaghashoptions{$validatecomp} .
                 ####      " for the subcomponent " . $validatecomp . "...\n";
               }
               ### print "Diagcollect, subcomponent exists $validatecomp \n";
               # Subcomponents entered in comdline, name/value
               push @inputsubcomps, [ $derefsubcomps[VALIDATESUBCOMPNAME],
                                          $diaghashoptions{$validatecomp} ] ;
               # Input values entered in cmdline for sobcomponents
               $inputsubcompshash{ $derefsubcomps[VALIDATESUBCOMPNAME] } =
                        $diaghashoptions{$validatecomp};
               $originalinputsubcompshash{ $derefsubcomps[VALIDATESUBCOMPNAME] } =
                        $diaghashoptions{$validatecomp};
               ###print "Validatecomp passed val " . $diaghashoptions{$validatecomp} . " \n";
          } else {
            ### print "Diagcollect, subcomponent does not exists $validatecomp \n";
            if (  lc($derefsubcomps[VALIDATESUBCOMPREQUIRED]) eq "true" ) {
              ###print "Required subcomponent $validatecomp was not included " .
              ###      "for component $compname in command line\n";
              $requiredsubcompnotincmdline{$derefsubcomps[VALIDATESUBCOMPNAME]} = 1;
              ####print "Input value not provided for required subcomponent $validatecomp" .
              ####       "...\n";
              ###return;
            } # end if subcomp is required
          } # end if exists $diaghashoptions{$validatecomp}
        } # end if check subcomponents for validation component
      } # end for $#validatexmlcompsarray
      # --------------------------
      ###print "Required check passed for component $compname \n";
      # Get validation tuples
      dbg(DBG_WHAT, "Running getsubcompvalues through Java CLI in purgeRepository\n");
      my $localhost=tolower_host();
      my $message ="$localhost:getsubcompvalues:$compname\n";
      my $command = buildCLIJava($tfa_home,$message);
      my $ltime = localtime();
      dbg(DBG_VERB, "$command\n");
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "Running getsubcompvalues, message $message",
                        'y', 'y');

      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "============== Begin call getsubcompvalues =============",
                        'y', 'y');
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "============== Start time $ltime =============",
                        'y', 'y');

      my %inlist;
      my @cli_output = tfactlshare_runClient($command);
      foreach my $line ( @cli_output )
      {
        #print "Line getsubcompvalues $line\n";
        if ( $line =~ /node=(.*),component=([\w]*),(.*)/ ) {
          if ( not exists $inlist{$1.$2.$3} ) {
            $inlist{$1.$2.$3} = TRUE;
            $ltime = localtime(); 
            tfactlshare_trace(5, "tfactl (PID = $$,$ltime) tfactldiagcollect_process_command " .
                              "=> Node $1 component $2 rest $3",
                              'y', 'y');
            my @subcompvals = split(",",$3);
            my %subcompvalshash;
            foreach my $val (@subcompvals) {
              if ( $val =~ /(.*)=(.*)/ ) {
                $subcompvalshash{$1} = $2;
                # Build options lists for all sumcomponents
                if ( not exists $uniquesubcompvals{$1} ) {
                  $uniquesubcompvals{$1} = [ $2 ]; 
                } else {
                  # Add to array
                  my $refleftarray = $uniquesubcompvals{$1};
                  my @leftarray = @$refleftarray;
                  my @rightarray = ( $2 );
                  push @leftarray, @rightarray;
                  #print "Left array ==> @leftarray \n";
                  $uniquesubcompvals{$1} = \@leftarray;
                }
              }
            } # end foreach
            # Store validation tuple
            push @subcompvalsarray, [ $1 , $2 , \%subcompvalshash ];
          } # end if, supress dups
        } # end if, match node-component-other
      } # end foreach $command
      undef %inlist;

      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "============== End call getsubcompvalues =============",
                        'y', 'y');

      # ------------------------------------------------------------------
      # Avoid dups in option lists
      # Find out input type for subcomponent
      # Validate if input/default values is contained in option lists 
      # Set $foundsubcomps{$key}
      #     $inptypeforsubcomp{$key} 
      # -------------------------------------------------------------------

      # ---------------- Begin foreach %uniquesubcompvals -----------------
      foreach my $key ( keys %uniquesubcompvals ) {
         tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                           "Processing avoid dups in options lists, key $key",
                           'y', 'y');
         my $ref = $uniquesubcompvals{$key};
         my @subcomps = @$ref;
         my %auxhash = map { $_ => 1 } @subcomps;
         @subcomps = keys %auxhash;
         @subcomps = sort @subcomps;
         $uniquesubcompvals{$key} = \@subcomps;

         # Validate if input subcompval matches any item in the list (subcompshash),
         # If not try => default, option lists
         my %subcompshash = map { $_ => 1 } @subcomps;

         my $inputvalue = $inputsubcompshash{$key};
         my $usinginpvalue = FALSE;
         my $defval = $defaultsubcompshash{$key};
         my $usingdefval = FALSE;
         my $requiredcomp;

         if ( exists $requiredsubcomp{$key} ) {
           $requiredcomp = "required";
         } else {
            $requiredcomp = "";
         }

         ###print "defaval " . $defval . " \n";
         ###print "inputval " . $inputvalue . " \n";

         if ( defined $inputvalue && length $inputvalue && 
              (grep /$inputvalue/, keys %subcompshash) ) {
           tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                           "Input value $inputvalue is contained in list, key $key",
                           'y', 'y');
           ####print "Using the input value $inputvalue for the $requiredcomp subcomponent ".
           ####      $compname . "_" . $key . "...\n";
           $foundsubcomps{$key}     = $inputvalue;
           $inptypeforsubcomp{$key} = "input";
           if ( not exists $inputsubcompshash{$key} ) {
             $inputsubcompshash{$key} = $inputvalue;     # introduced as input
             push @inputsubcomps, [ $key, $inputvalue ]; # introduced as input
           }
           $usinginpvalue = TRUE;
         } elsif ( defined $defval && length $defval && 
                   (grep /$defval/, keys %subcompshash) && not $usinginpvalue )  {
           tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                           "Default value $defval is contained in list, key $key",
                           'y', 'y');
           ####print "Using the default value $defval for the $requiredcomp subcomponent ".
           ####      $compname . "_" . $key . "...\n";
           $foundsubcomps{$key} = $defval;
           $inptypeforsubcomp{$key} = "default";
           if ( not exists $inputsubcompshash{$key} ) {
             $inputsubcompshash{$key} = $defval;     # introduced as input
             push @inputsubcomps, [ $key, $defval ]; # introduced as input
           }
           $usingdefval = TRUE;
         } else {
           tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                           "The default value nor the input value matches " .
                           "the subcomponent key $key",
                           'y', 'y');
           my $idxforkey = $allsubcomps{$key};
           $notfoundsubcompswidx{$idxforkey.".".$key} = "notfound";
           $notfoundsubcomps{$key} = "notfound";
         } # end if

         # Not valid messages
         # Signal not valid values
         if ( defined $inputvalue &&
              not (grep /$inputvalue/, keys %subcompshash) && length $inputvalue ) {
           print "Requested $key $inputvalue is not valid for product " .
                 "$compname on this system\n\n";
         }
         if ( defined $defval && not (grep /$defval/, keys %subcompshash) && 
              length $defval && $usinginpvalue == FALSE )  {
           print "Default $key $defval is not valid for product " .
                 "$compname on this system\n\n";
         }


      } # end foreach %uniquesubcompvals, avoid dups in option lists
      # ---------------- End   foreach %uniquesubcompvals -----------------


      # -----------------------------------------------------
      # Begin, check if notfoundsubcomps are viable 
      # -----------------------------------------------------

      my $countnotfound = keys %notfoundsubcomps;
      my $countsubcomps = keys %uniquesubcompvals;

      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "Begin, check if optional values is viable. Countnotfound " . 
                        "$countnotfound",
                        'y', 'y');

      if ( $countnotfound ) { 
        foreach my $nfkey (sort keys %notfoundsubcompswidx ) {
        my $key;
        if ( $nfkey =~ /([0-9]+)\.(.*)/ ) {
          $key = $2;
        }
        ###
        ###print "\n\nNot found key: index $nfkey , key $key \n\n";


        # ===================================
        # clean unique arrays
        foreach my $nfskey (keys %notfoundsubcomps ) {
          delete $uniquesubcompvals{$nfskey};
        }

        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                          "Begin Loop through tuples, viable values.",
                          'y', 'y');

        # Prepare viable values for unmatched subcomponent
        ### Rebuild unique subcomponents arrays
        ### with filtered values

        # ------- Begin Loop through tuples, viable values
        for my $idx ( 0 .. $#subcompvalsarray ) {
          my $refflevel = $subcompvalsarray[$idx];
          my @flevel = @$refflevel;              # flevel = node, component
          my $sref = $flevel[SUBCOMPVALSKVHASH]; # kvintuples = hash of subcomponent pairs
          my %kvintuples = %$sref;
          my $matchedfound = TRUE; 

          #### to check
          foreach my $foundkey ( keys %foundsubcomps ) {
               my $cmpval = $foundsubcomps{$foundkey};
               ###
               ###print "\n\nChecking foundkey: key $foundkey, cmpval $cmpval\n\n";
               # cmp vs input
               if ( $kvintuples{$foundkey} =~
                    /^$cmpval$/ ) {
                  ###
                  ###print "Match input value $cmpval \n";
               # cmp vs default
               } else {
                 $matchedfound = FALSE;
               }
          } # end foreach %foundsubcomps

          if ( $matchedfound  ) {
            foreach my $notfoundkey (keys %notfoundsubcomps ) {
               ###
               ###print "Match found, notfoundsubcomps $notfoundkey ...\n";
               ### Rebuild unique subcomponents arrays
               ### with filtered values
               my $subcompval = $kvintuples{ $notfoundkey };
               if ( not exists $uniquesubcompvals{$notfoundkey} ) {
                $uniquesubcompvals{$notfoundkey} = [ $subcompval ];
               } else {
                # Add to array
                my $refleftarray = $uniquesubcompvals{$notfoundkey};
                my @leftarray = @$refleftarray;
                my @rightarray = ( $subcompval );
                push @leftarray, @rightarray;
                #print "Left array ==> @leftarray \n";
                $uniquesubcompvals{$notfoundkey} = \@leftarray;
               }
            } # end forach %notfoundsubcomps
          } # end if $matchedfound

        } # end for $#subcompvalsarray
        # ------- End Loop through tuples, viable values

        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                          "End Loop through tuples, viable values",
                          'y', 'y');

        # avoid dups in filtered options lists and sort
        foreach my $uskey ( keys %uniquesubcompvals ) {
          ###print "Avoid dups, subcomponent $uskey, \n";
          my $ref = $uniquesubcompvals{$uskey};
          my @subcomps = @$ref;
          my %auxhash = map { $_ => 1 } @subcomps;
          @subcomps = keys %auxhash;
          @subcomps = sort @subcomps;
          ###print "Values : @subcomps \n";
          $uniquesubcompvals{$uskey} = \@subcomps;
        } # end foreach %uniquesubcompvals
        # ===================================

        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                          "Completed, avoid dups in filtered options lists and sort.",
                          'y', 'y');
      
        my $ref;
        my @subcomps;

        if ( exists $uniquesubcompvals{$key} ) {
          $ref = $uniquesubcompvals{$key};
          @subcomps = @$ref;
        } else {
          @subcomps = ();
        }

        my $itemscounter = 0;
        my $formattedstring = "";
        my $ndx = 0;
        my $totndx = $#subcomps;
        my $optmaxval = $totndx + 1; 
        my $optselected = -1;
        my @optionsarray;

        if ( @subcomps ) {
        print "\n\nSelection list for subcomponent $key,\n\n";
        foreach my $subndx ( 0..$#subcomps ) {
          $formattedstring .= sprintf("%-40s ","$ndx) $subcomps[$subndx]");
          if ( ++$itemscounter % 2 == 0  || $subndx == $#subcomps ) {
            if ( $subndx == $#subcomps && not $itemscounter % 2 == 0 ) {
              print "$formattedstring";
            } else {
              print "$formattedstring\n";
            }
            $formattedstring = "";
          } # end if change line
          $optionsarray[$ndx++] = $subcomps[$subndx];
        } # end foreach @subcomps
        print "$ndx) None \n" if $totndx || $totndx == 0;

        # Desired option
        $optselected = tfactlshare_get_choice ( 0, $optmaxval, 
                         "\nPlease select an option for subcomponent $key " .
                         " [0-$optmaxval, default $optmaxval] ?", $optmaxval );
        if ( $optselected == ($totndx + 2) ) {
          # None
          print "Option selected, None \n\n";
          if ( not exists $inputsubcompshash{$key} ) {
            push @inputsubcomps, [ $key, "none" ]; # introduced as input
            $inputsubcompshash{$key} = "none";     # introduced as input
          }
          $inptypeforsubcomp{$key} = "none";
        } else {
          print "Option selected $optselected, $optionsarray[$optselected] \n\n";
          $selectedsubcompshash{ $key } = $optionsarray[$optselected];
          $inptypeforsubcomp{$key} = "selected";
          $foundsubcomps{$key} = $optionsarray[$optselected];
          $inputsubcompshash{$key} = $optionsarray[$optselected];     # introduced as input
          push @inputsubcomps, [ $key, $optionsarray[$optselected] ]; # introduced as input
          delete $notfoundsubcomps{$key};
         }
        } # end if @subcomps 

        } # end foreach, %notfoundsubcomps
      } # End if $countnotfound, options viable
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "Completed, End if $countnotfound, options viable",
                        'y', 'y');
      # -----------------------------------------------------
      # End, check if optional values is viable
      # -----------------------------------------------------



      my $tuplematched = FALSE;
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "Begin, validate component/subcomponent input vs ret tuples.",
                       'y', 'y');

       my $inpsubstr = "";
       $inpsubstr .= "inputsubcomps array => ";
       for my $idx ( 0..$#inputsubcomps) {
          my $ref = $inputsubcomps[$idx];
          my @compvalidsub = @$ref;
          $inpsubstr .= "@compvalidsub " . ",";
       }
       tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                         "$inpsubstr", 'y', 'y');

      # Validate component/subcomponent input vs ret tuples (%subcompvalshash for a match)
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "BEGIN validate comp/subcomp input vs ret tuples", 'y', 'y');

      # ------------------------------------
      #      Begin Loop through tuples
      #      Validate ret tuples
      # ------------------------------------
      for my $idx ( 0 .. $#subcompvalsarray ) { 
         my $ref = $subcompvalsarray[$idx];
         my @flevel = @$ref;    # flevel[SUBCOMPVALSNODE] = node, flevel[SUBCOMPVALSCOMP]=component

         my $sref = $flevel[SUBCOMPVALSKVHASH]; # kvintuples = hash of subcomponent pairs
         my %kvintuples = %$sref;
         ###
         my $matchingtuple = "";
         foreach my $tuplekey ( keys %kvintuples ) {
            $matchingtuple .= $tuplekey . ":" . $kvintuples{$tuplekey} . " ";
         }
         tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                           "Idx $idx $flevel[SUBCOMPVALSNODE] $flevel[SUBCOMPVALSCOMP]. " .
                           " Try tuple ==> $matchingtuple\n",
                           'y', 'y');

         my $allmatched = TRUE;
         for my $vsidx ( 0 .. $#inputsubcomps ) { # Loop through input subcomps
            my $ref = $inputsubcomps[$vsidx];
            my @compvalidsub = @$ref; # compvalidsub[0] subcompname, compvalidsub[1] subcompval
            ###
            tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                              "Valid subcomps for component $compname -> @compvalidsub", 
                              'y', 'y');
            if ( exists $kvintuples{$compvalidsub[COMPVALIDSUBNAME]} ) {
              ###
              tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                                "subcomp $compvalidsub[COMPVALIDSUBNAME] exists " .
                                "kvintuples => $kvintuples{$compvalidsub[COMPVALIDSUBNAME]} ", 
                                'y', 'y');

               # Check contents of input vs. tuple
               my $cmpval = $compvalidsub[COMPVALIDSUBVALUE];

               # Alternatively check contents of default
               my $defval = $defaultsubcompshash{$compvalidsub[COMPVALIDSUBNAME]};

               # or Selected val
               my $selectedval = $selectedsubcompshash{$compvalidsub[COMPVALIDSUBNAME]};

               ###
               tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                                "cmpval $cmpval , defval $defval , selectedval $selectedval",
                                'y', 'y');
               # cmp vs input
               if ( defined $cmpval && $kvintuples{$compvalidsub[COMPVALIDSUBNAME]} =~ 
                    /^$cmpval$/ && 
                    $inptypeforsubcomp{$compvalidsub[COMPVALIDSUBNAME]} eq "input" &&
                    length $cmpval ) {
                  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                                    "Match input value cmpval $cmpval",
                                    'y', 'y');
               # cmp vs default
               } elsif ( defined $defval && $kvintuples{$compvalidsub[COMPVALIDSUBNAME]} =~ 
                         /^$defval$/ &&
                         $inptypeforsubcomp{$compvalidsub[COMPVALIDSUBNAME]} eq "default" && 
                         length $defval ) {
                 tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                                    "Match default value $defval",
                                    'y', 'y');
               # cmp vs alternatives
               } elsif ( defined $selectedval && $kvintuples{$compvalidsub[COMPVALIDSUBNAME]} =~
                         /^$selectedval$/ &&
                         $inptypeforsubcomp{$compvalidsub[COMPVALIDSUBNAME]} eq "selected" &&
                         length $selectedval ) {
                 tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                                    "Match selected value $selectedval",
                                    'y', 'y');
                 # cmp vs selected
               } else {
                  # Check if there are available options as an alternative
                  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                                    "=== Setting to FALSE, $compvalidsub[COMPVALIDSUBNAME]",
                                    'y', 'y');
                  $allmatched = FALSE;
               }
            } else {
              $allmatched = FALSE; # Incomplete tuple
            } # end if exists $kvintuples{$compvalidsub[COMPVALIDSUBNAME]}
         } # end for $#inputsubcomps
         if ( $allmatched ) {
           ###
           my $matchingtuple = "";
           foreach my $tuplekey ( keys %kvintuples ) {
             $matchingtuple .= $tuplekey . ":" . $kvintuples{$tuplekey} . " ";
           }
           ###print "Matching tuple Idx $idx $flevel[SUBCOMPVALSNODE] $flevel[SUBCOMPVALSCOMP] fmwhost " . $kvintuples{"fmwhost"} .
           ###      " " . $kvintuples{"fmwdomain"} . " mtupled -> $matchingtuple \n";
           tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                             "Matching tuple-> $matchingtuple",
                             'y', 'y');
           $tuplematched = TRUE;

           # Store match tuple (node, comp, subcomps kv hash)
           push @matchedsubcompvalsarray, [ $flevel[SUBCOMPVALSNODE],
                    $flevel[SUBCOMPVALSCOMP],
                    $flevel[SUBCOMPVALSKVHASH]  ];

           # last;, now support multiple rows
         }
      } # end for subcompvalsarray
      # --------------------------------------
      # ========== End Loop through tuples
      # --------------------------------------

      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "End, validate component/subcomponent input vs ret tuples.",
                        'y', 'y');
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "Tuplematched $tuplematched.",
                        'y', 'y');

      if ( not $tuplematched ) {
        ###print "Please review component configuration.\n";
        ###return;
        # Removed cmdline component from DOPTIONS

        ###print "DSCRIPT_OPTS bef , \"$DSCRIPT_OPTS\"\n";
        ###print "Compname $compname\n";
        $DSCRIPT_OPTS =~ s/-$compname\s?//;
        ###print "DSCRIPT_OPTS aft , $DSCRIPT_OPTS\n";

      } else {
        $componentmatch = TRUE;

     my %noduphash;
     # -------- Begin eliminate dups from matched --------------
     # Eliminate dups from @matchedsubcompvalsarray
     for my $matchidx ( 0 .. $#matchedsubcompvalsarray ) {
        my $ref = $matchedsubcompvalsarray[$matchidx];
        my @tuple = @$ref;
        my $refkv = $tuple[SUBCOMPVALSKVHASH];
        my %kvpairs = %$refkv;

        # Avoid dup tuples
        my $nodupkey;
        foreach my $kvkey (keys %kvpairs) {
          $nodupkey .= $kvkey . $kvpairs{$kvkey};
        }

         if ( not exists $noduphash{ $nodupkey } ) {
           # write that this key was used
           $noduphash{ $nodupkey } = "nodup";
           # Store match tuple (node, comp, subcomps kv hash)
           push @uniquematchedsubcompvalsarray, [ $tuple[SUBCOMPVALSNODE],
                $tuple[SUBCOMPVALSCOMP],
                $tuple[SUBCOMPVALSKVHASH]  ];
         } # end if , not exists $noduphash{ $nodupkey }
     } # end for $#matchedsubcompvalsarray
     # -------- End eliminate dups from matched --------------


        ###print "DSCRIPT_OPTS bef xml, \"$DSCRIPT_OPTS\"\n";
        ###print "Compname $compname\n";
        $DSCRIPT_OPTS =~ s/-$compname\s?//;
        ###print "DSCRIPT_OPTS aft xml, $DSCRIPT_OPTS\n";
        ####my $xmlstring = "-xmlstring ";
	####$xmlstring .= '[components]';

        # Loop through matched tuples
        print "Selected:\n" if @uniquematchedsubcompvalsarray;
        $xmlcontent = TRUE if @uniquematchedsubcompvalsarray;
        for my $matchidx ( 0 .. $#uniquematchedsubcompvalsarray ) {
            my $ref = $uniquematchedsubcompvalsarray[$matchidx];
            my @tuple = @$ref;
            my $refkv = $tuple[SUBCOMPVALSKVHASH];
            my %kvpairs = %$refkv;

            print "Component:$compname ";
            ###$xmlstring .= '[component][name]'.$compname.'[/name]';
            ###$xmlstring .= '[sub-components]';

            $xmlstring .= '[component][name]'.$compname.'[/name]';
            $xmlstring .= '[sub-components]';

            ### print "$tuple[SUBCOMPVALSNODE] $tuple[SUBCOMPVALSCOMP] \n";
            ### print "kv pairs, \n";
            foreach my $key ( keys %kvpairs ) {
              my $subcompname = $key;
              my $subcompval = $kvpairs{$key};
              print "$subcompname:$subcompval ";
              #my $subcompvalsearch = $inputsubcompshash{$key};
              my $subcompvalsearch = $originalinputsubcompshash{$key}; 
              # print $key . " -> " . $kvpairs{$key} . "\n";
              my $doption     = $compname . "_" . $subcompname;
              if ( defined $subcompvalsearch && length $subcompvalsearch ) {
                $subcompvalsearch =~ s/\./\\\./g;
                $subcompvalsearch =~ s/\*/\\\*/g;
                $subcompvalsearch =~ s/\[/\\\[/g;
                $subcompvalsearch =~ s/\]/\\\]/g;
                $subcompvalsearch =~ s/\-/\\\-/g;
                $subcompvalsearch =~ s/\?/\\\?/g;
                $subcompvalsearch =~ s/\+/\\\+/g;
              }
              ###print "subcompvalsearch  $subcompvalsearch\n";
              if ( defined $doption && length $doption &&
                   defined $subcompvalsearch && length $subcompvalsearch ) {
                $DSCRIPT_OPTS =~ s/-$doption $subcompvalsearch//;
              }
              $xmlstring .= '[subcomponent name=\"' . $subcompname .
                            '\"]'.$subcompval.'[/subcomponent]';
            } # end foreach, keys %kvpairs
            print "\n";
            $xmlstring .= '[/sub-components][/component]';
        } # End loop through matched tuples
	####$xmlstring .= '[/components]';

        ####$DSCRIPT_OPTS = $xmlstring . $DSCRIPT_OPTS;
        ####$DSCRIPT_OPTS =~ s/ +/ /g;
      }
      # --------------------------------------
      } # end if  $compvalidate = "true"


      tfactlshare_trace(5, "tfactl (PID = $$) " .
                        "tfactldiagcollect_process_command " .
                        "Add comp inc in cmdline $compname",
                        'y', 'y');
      $cmdlineoption = 1;
      $isaddcomp = 1; # Signaled that an add comp was included in cmdline
    } # end if, Was this component sent in the cmdline ?

    # ---------------------------------------------------------
    # No validation components were sent, just subcomponents -> signal error 
    if ( $compvalidate eq "subcomponent" &&
         exists $diaghashoptions{$compname} &&
         ref($diaghashoptions{$compname}) ne "SCALAR" ) {
      my $component; 
      if ( exists $componentshash{$compname} &&
           ref($componentshash{$compname}) ne "SCALAR" ) {
        $component = $componentshash{$compname};
        ###print "Component $component is associated with subcomponent $compname \n";
        if ( not (exists $diaghashoptions{$component} &&
             ref($diaghashoptions{$component}) ne "SCALAR"
           ) ) {
           print "Component $component was not included in command line.\n";
           print "Please add -$component and try again !\n";
           return;
        }
      } else {
        print "Subcomponent $compname is not associated with any component, exiting !\n";
        return;
      }
    }
    # -----------------------------------------------------------


    # Validata availability for the component in the
    # current platform
    if ( $compconfig eq "exadata" ) {        # EXADATA
      if ( $EXADATA_SETUP != 1 && $NODE_TYPE ne "CELL" && $cmdlineoption ) {
        print "\nInvalid component for non EXADATA platform: $compname\n";
        print_help("diagcollect", "");
        $exitcode = 1;
        last dscriptoptions;
      }
    } elsif ( $compconfig eq "oda" ) {       # ODA
      if ( isODA() != 1 && $cmdlineoption ) {
        print "\nInvalid component for non ODA platform: $compname\n";
        print_help("diagcollect", "");
        $exitcode = 1;
        last dscriptoptions;
      }
    } elsif ( $compconfig eq "racdbcloud" ) { # RACDBCLOUD
      if ( ! $IS_RACDBCLOUD && $cmdlineoption ) {
        print "\nInvalid component for non RAC DB Cloud platform: $compname\n";
        print_help("diagcollect", "");
        $exitcode = 1;
        last dscriptoptions;
      }
    } elsif ( $compconfig eq "all" ) {       # ALL 
    }

    $loopingtrc .= "$compname ";
    if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_load_xmlcomp"} ) {
      tfactlshare_trace(5, "tfactl (PID = $$) " . "tfactldiagcollect_process_command " .
            "Looping $ndx, name:$compname type:@typesarray compconfig:$compconfig. Add comp list typesarr:@typesarray",
            'y', 'y');
    } # end if $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_load_xmlcomp"}

  } # end for @retcomparray

  tfactlshare_trace(5, "tfactl (PID = $$) " .
                      "tfactldiagcollect_process_command " . "components: $loopingtrc", 'y', 'y');

  # If validate components were used in the command line
  # validate if there's at least one componentmatch
  if ( $validatecomponentsused && not $componentmatch ) {
    print "Please review component configuration.\n";
    return;
  } # end if 

  tfactlshare_trace(5, "tfactl (PID = $$) " .
                    "tfactldiagcollect_process_command " .
                    "\n\nFinished processing retcomparray\n\n", 'y', 'y');

  tfactlshare_trace(5, "tfactl (PID = $$) " .
                    "tfactldiagcollect_process_command " .
                    "xmlcontent $xmlcontent", 'y', 'y');

  tfactlshare_trace(5, "tfactl (PID = $$) " .
                    "tfactldiagcollect_process_command " .
                    "xmlstring $xmlstring", 'y', 'y');

  # Prepare -xmlstring
  if ( $xmlcontent ) {
    $xmlstring .= '[/components]';
    $DSCRIPT_OPTS = $xmlstring . $DSCRIPT_OPTS;
    $DSCRIPT_OPTS =~ s/ +/ /g;
  }

  if ( $addcompstring =~/ -awrhtml -awrtext/ ) {
      $addcompstring =~ s/ -awrhtml -awrtext//;
      $addcomphlpstring =~ s/ -awrhtml -awrtext//;
      tfactlshare_trace(5, "tfactl (PID = $$) " .
                        "tfactldiagcollect_process_command " .
                        "removed -awrhtml and -awrtext from default all collection",
                        'y', 'y');
  }

  if ( $addcompstring =~/ -ashhtml -ashtext/ ) {
      $addcompstring =~ s/ -ashhtml -ashtext//;
      $addcomphlpstring =~ s/ -ashhtml -ashtext//;
      tfactlshare_trace(5, "tfactl (PID = $$) " .
                        "tfactldiagcollect_process_command " .
                        "removed -ashhtml and -ashtext from default all collection",
                        'y', 'y');
  }
  
  # Deal with not having procinfo by default but add for -acfs
  
  if ( $addcompstring =~/ -procinfo/ ) {
     $addcompstring =~ s/ -procinfo//;
     $addcomphlpstring =~ s/ -procinfo//;
     tfactlshare_trace(5, "tfactl (PID = $$) " .
                      "tfactldiagcollect_process_command " .
                      "removed -procinfo from default all collection",
                        'y', 'y');
  }
  if ( exists $diaghashoptions{"acfs"} ) {
     $diaghashoptions{"procinfo"} = 1; 
     tfactlshare_trace(5, "tfactl (PID = $$) " .
                      "tfactldiagcollect_process_command " .
                      "added -procinfo as -acfs was in the commandline",
                        'y', 'y');
  }


  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                   "EXADATA (cells configured) $EXADATA " .
                   "EXADATA_SETUP  $EXADATA_SETUP " .
                   "ODA " . isODA(), 'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                   "addcompstring $addcompstring " .
                   "addcomphlpstring $addcomphlpstring", 'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                   "addcompstring_oda $addcompstring_oda " .
                   "addcomphlpstring_oda $addcomphlpstring_oda", 'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                   "addcompstring_racdbcloud $addcompstring_racdbcloud " .
                   "addcomphlpstring_racdbcloud $addcomphlpstring_racdbcloud", 'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                   "addcompstring_exadata $addcompstring_exadata " .
                   "addcomphlpstring_exadata $addcomphlpstring_exadata", 
                   'y', 'y');

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                   "AFTER GetOptions $DSCRIPT_OPTS", 'y', 'y');

  #if(@fromlist) { $from = join(" ", @fromlist); }
  #if(@tolist)   { $to = join(" ", @tolist); }

  #Chandru: Added below when user tries with options like "all" instead of "-all".
  if(@ARGV and not $xmlfilters) { # If not SRDC is an error, if SRDC process arguments to check if they are valid 
        print "\nInvalid Option for diagcollect: @ARGV\n";
        print_help("diagcollect", "");
        $exitcode = 1;
        last dscriptoptions;
  }

  # Need to run srdc as the DB owner - not root.
  if ($xmlfilters && $current_user eq "root" && not $IS_WINDOWS) {
	if ($xmlfilters !~ /esexalogic/) {        #remove root blocker for esexalogic collection
    		print "\nSRDC diagostic collections must be run as an oracle privileged user - not root\n";
    		exit 1;
	}
  } 

  # manuegar_srdc_14
  if ( lc($xmlfilters) eq "-h" || lc($xmlfilters) eq "-help") {
    $help = 1;
  }

  # EM SRDC, EM node type
  # -------------------------------------------------------------------------
  if ( lc($xmlfilters) =~ /em(tbsmetric|metricalert|debugon|debugoff|procdisc|gendisc|clusdisc|cliadd|dbsys|restartoms|agentperf|omscrash|omsheap|omshungcpu)/ ) {

    my @emagentret;
    my @emagentiret;
    my @emomsret;
    my $retndx;

    @emagentret = tfactlshare_get_tfadirectories($tfa_home,"EMAGENT","ORACLE_HOME",TRUE);
    @emagentiret = tfactlshare_get_tfadirectories($tfa_home,"EMAGENT","INSTANCE_HOME",TRUE);
    @emomsret    = tfactlshare_get_tfadirectories($tfa_home,"OMS","ORACLE_HOME",TRUE);
    ### print "emagentret @emagentret , emomsret @emomsret, emagentiret @emagentiret\n";

    ($retndx,$EMAGENTIHOME) = tfactlshare_get_choice_array( \@emagentiret,
                    "Multiple EMAGENT INSTANCE HOMES were found, please select one ...",
                    "Please select an EMAGENT INSTANCE HOME to be used");
    if (length $EMAGENTIHOME) {
      $EMAGENTOHOME = $emagentret[$retndx] if $retndx <= $#emagentret;
    }
    ($retndx,$EMOMSOHOME) = tfactlshare_get_choice_array( \@emomsret,
                    "Multiple OMS HOMES were found, please select one ...",
                    "Please select the OMS HOME to be used");


    if ( length $EMAGENTOHOME ) {
      my $emctl = catfile($EMAGENTOHOME,"bin","emctl");
      $discemcomp{"EMAGENT"} = $EMAGENTOHOME;
      # Retrieve all the available EM targets
      $ENV{ORACLE_HOME} = $EMAGENTOHOME;
      @emtargets = split /\n/ , `$emctl config agent listtargets`;
      @emtargets = grep { $_ =~ s/\[(.*), (oracle_database|rac_database)\]/$1/} @emtargets;
      %emtargets = map { $_ => TRUE } @emtargets;
      
    }
    if ( length $EMAGENTIHOME ) {
      $discemcomp{"EMAGENTI"} = $EMAGENTIHOME;
    }
    if ( length $EMOMSOHOME ) {
      $discemcomp{"OMS"} = $EMOMSOHOME;
    }

    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "After adding to discemcomp EMAGENTOHOME=$EMAGENTOHOME:EMAGENTIHOME=$EMAGENTIHOME:EMOMSOHOME=$EMOMSOHOME",
                      'y', 'y');
  } # end if lc($xmlfilters) =~ /em(tbsmetric|metricalert|debugon|debugoff)/
  # -------------------------------------------------------------------------

  my $comps="";
  if ( $EXADATA == 1 ) {
    $comps  = $ADDCOMPHLPDESC_EXADATA;
  } elsif (isODA() == 1) {
    $comps = $ADDCOMPHLPDESC_ODA;
  } elsif ( $IS_RACDBCLOUD ) {
    $comps = $ADDCOMPHLPSTRING_RACDBCLOUD;
  } elsif ( isODADom0() == 1 ) {
  } else {
    $comps = $ADDCOMPHLPDESC;
  }

  if ( length $database ) {
    if ( lc($database) eq "-h" || lc($database) eq "-help" ) {
      $help = 1;
    } elsif ( not( ($database !~ /-/  && $comps =~ /-$database /) || ($database =~ /-/  && $comps =~ /$database /) )  ) {
      $allargv =~ s/-database $database/-database/g;
    }
    my @allargv = split / / , $allargv;
    $allargv = "";
    foreach my $item (@allargv) {
      $allargv .= $item . " " if ($item !~ /^\s+$/ && $comps =~ /$item /);
    }
  }

  if ($help) {
        ### print "firstargv $firstargv\n";
        ### print "allargv   $allargv\n";
        print_help("diagcollect", "$allargv");
        last dscriptoptions;
  }

  if (isTFARunning($tfa_home) == FAILED) {
        print "Please start TFA before running collections\n";
        exit 1;
  }

  # checking if repository is open
  my $repoOpen = checkRepositoryIsOpen($tfa_home);
  if ($repoOpen == SUCCESS) {
  }
  else {
     print "Not enough space in Repository or TFA_BASE to run collections\n";
     printLocalRepository($tfa_home);
     print "Collection job failed.\n";
     exit 1;
  }

  # checking validity of nodes
  my $nodename;
  $node =~ tr/A-Z/a-z/;
  if ( tfactlshare_isnodelist_duplicated($node) ) {
     print "No node can be used more than once, please correct the node list and retry.\n";
     print_help("diagcollect", "");
     $exitcode = 1;
     last dscriptoptions;
  }
  
  my @nodes_list = split(/\,/,$node);
  foreach $nodename (@nodes_list) {
         ($nodename,) = split (/\./, $nodename);
	 if ( $nodename eq "local" || $nodename eq "all" ) {
         } else {
  	   if (isNodePartOfCluster($tfa_home, $nodename)) {
  	   }
	   else {
  		print "Node $nodename is not part of TFA cluster. Cannot collect files from that node.\n";
        	exit 1;
           }
         }
  }

  # checking validity of database flag
  my $db;
  my %catchdupdbs;
  foreach $db (split /\,/ , $database) {
    if ( not exists $catchdupdbs{$db} ) {
      $catchdupdbs{$db} = TRUE;
    } else {
      print "Database $db appears more than once in the -database switch.\n";
      print "Please correct and try again.\n";
      exit 1;
    }

    if ( $db =~ /~/ ) {
      $db = (split(/~/,$db))[0]; 
      #print "db $db\n";
    }
    if ($db eq "all") {
    }
    else {
      my $dbexists = checkDbExistence($tfa_home, $db, $node);
      if ($dbexists !=  SUCCESS ) {
        print "Database $db does not exist.\n";
        $exitcode = FAILED;
        last dscriptoptions;  
      }
    }
  }

  if ( $TFABUG ) {
	$TFAUPLOAD = 1 if ( ! $TFAUPLOAD );
	$TFABUGSFTP = 1 if ( ! $TFABUGSFTP );
	if ( ! $TFAUSER ) {
	  print "\nBugsftp User ID : ";
	  $TFAUSER = <STDIN>;
	  chomp($TFAUSER);
	}
  }

  if ( $TFASR )
  {
    if ($help || lc($TFASR) eq "-h" || lc($TFASR) eq "-help") {
      print_help("diagcollect", "");
      exit 0;
    }

    #Setup Mos if not done. It is mandatory to upload collections to MOS SR
    if ( ! -f catfile($tfa_home,"ewallet.p12") ) {
      print "MOS setup is not done. It is needed to upload collection to SR\n";
      print "Run: tfactl setupmos\n"; 
      exit 1;
    }
    #$TFAUPLOAD = 1 if ( ! $TFAUPLOAD );
    #if ( ! $TFAUSER ) {
    #  print "\nMOS User ID : ";
    #      $TFAUSER = <STDIN>;
    #      chomp($TFAUSER);
    #}
    #tfactldiagcollect_readMode(0);
    #print "MOS Password : ";
    #my $pass = <STDIN>;
    #chomp($pass);
    #tfactldiagcollect_readMode(1);
    #$ENV{"TFA_BUGSFTP_PASS"} = $pass;
    #print "\n";
  }

  if ( $last ) {
	if ( $since ) {
		print "\n-last flag cannot be combined with -since flag\n";
		print_help("diagcollect", "");
                $exitcode = 1;
		last dscriptoptions;
	}
	$since = $last;
	$DSCRIPT_OPTS =~ s/-last\s/-since /;
  }

 

  if ( $TFABUGSFTP )
  {
    tfactldiagcollect_readMode(0);
    print "Bugsftp Password : ";
    my $pass = <STDIN>;
    chomp($pass);
    tfactldiagcollect_readMode(1);
    $ENV{"TFA_BUGSFTP_PASS"} = $pass;
    print "\n";
  }

  # Check silent switch in the context of srdc
  if ( $nomonitor && $xmlfilters ) {
    $SRDCSILENT = TRUE;
  }

  # check duration switch
  if ($duration) {
    if (!($duration =~ /^(\d+)d{1}$/ || $duration =~ /^(\d+?)h{1}$/)) {
      print "The -duration entered is invalid: $duration\n";
      print "Some examples of valid duration entries : 2h, 10d\n";
      $exitcode = 1;
      last dscriptoptions;
    }    
    # For now $duration is only valid when -event & -for switch are active
    if (  ($xmlfilters || $event) && ( $from || $to || $since ) ) {
      print "The duration switch can only be used with -for and when the switches -srdc or -event are included in the command line.\n";
      $exitcode = 1;
      last dscriptoptions;
    }
  }

  if ( ! $nomonitor && ! $from && ! $to && ! $since && !$for && ! $xmlfilters ) {
    my $VALID = FALSE;
    #print "\nBy default TFA will collect diagnostics for the last 12 hours. This can result in large collections\n";
    #print "Please enter the time of the incident you wish to collect diagnostics for [YYYY-MM-DD HH24:MI:SS,<RETURN>=Collect for last 12 hours] : ";
    print "\nBy default TFA will collect diagnostics for the last 12 hours. This can result in large collections\n";
    print "For more targeted collections enter the time of the incident, otherwise hit <RETURN> to collect for the last 12 hours\n";
    print "[YYYY-MM-DD HH24:MI:SS,<RETURN>=Collect for last 12 hours] : ";
    do {
      my $input = <STDIN>;
      chomp($input);
      if ( $input ) {
        $input = getValidDateFromString($input,"time");
        if ( $input eq "invalid"){
          print "Not a valid event time. Please try again \n";
        } else {
          $from  = strftime "%Y-%m-%dT%H:%M:%S",localtime($input - 14400); #Four hours before the event time
          $to    = strftime "%Y-%m-%dT%H:%M:%S",localtime($input + 3600); # An hour after the event time;
          $DSCRIPT_OPTS .= " -from $from -to $to ";
          $VALID = TRUE;
        } 
      } else {
        $VALID = TRUE; 
        #Continue with the last 12 hours collection 
      }
    } while ( ! $VALID );
  }
  # --------------------------
  # xmlfilters procesing
  # -------------------------
  if ( $xmlfilters && $event ) {
    print "-srdc & -event switch cannot be used at the same time.\n";
    print "Please try again.\n";
    exit 1;
  }
  my $oldumask = umask;

  if ( $xmlfilters )
  {
    
    # Allow multiple versions of error codes.
    $xmlfilters = lc($xmlfilters);
    if ( $xmlfilters =~ /ora-/ ) {
         $xmlfilters =~ s/ora-[0]*//;
         $xmlfilters = "ora" . $xmlfilters;
    }
    
    my $warndbdown = FALSE;
    # Setup srdc dirs if needed
    tfactlshare_check_trace($tfa_home,"root") if ($current_user eq "root") ;
    my $tfa_base = tfactlshare_get_repository_location($tfa_home);
    my $srdcdir = catfile($tfa_base, "suptools", "srdc","user_" . $current_user);
    if (! -d $srdcdir ) 
    { 
       print "Error: suptools/srdc directory does not exist for $current_user\n";
       exit;
    }
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                   "in xmlfilters srdcdir : $srdcdir  ",
                   'y', 'y');

    # $xmlfilters_orig = template file
    # $xmlfilters_fp   = customized file 
    # ----------------------------------
    my $xmlfilters_orig = catfile($tfa_home,"resources","srdc_$xmlfilters.xml");
    my $xmlfilters_tag = time()."_srdc_$xmlfilters";
    my $xmlfilters_fp = catfile($srdcdir,"tfa_" . $xmlfilters_tag . ".xml"); # Goes in Main directory
    $srdcdir = catfile($srdcdir,$xmlfilters_tag); # For all pre processing work files
    # Set usmask to 0077 to ensure all files created are only available to SRDC user
    umask 0077;
    if ( ! -d $srdcdir ) {
      mkdir($srdcdir);
    }
    chmod(0700,$srdcdir);
    chdir($srdcdir);
    my $env_file = catfile($srdcdir,"tfa_" . $xmlfilters_tag . "userenv");
    my $srdc_log = catfile($srdcdir,"tfa_" . $xmlfilters_tag . "srdc_user_log");
    open ($srdc_log_fh, "> $srdc_log") || die "Cant open $srdc_log for writing\n";
    print $srdc_log_fh "ARGS: DSCRIPT_OPTS(1) : $DSCRIPT_OPTS \n";

    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "in xmlfilters xmlfilters:$xmlfilters _tag:$xmlfilters_tag _fp:$xmlfilters_fp _orig:$xmlfilters_orig",
                      'y', 'y');
    if ( -f  catfile($tfa_home,"resources","srdc_$xmlfilters.xml"))
    {
      $DSCRIPT_OPTS .= " -xmlfilters $xmlfilters_tag";
    }
     else
    {
      print "Error: Failed to find rules for $xmlfilters\n";
      exit 1;
    }
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                   "in xmlfilters DSCRIPT_OPTS:$DSCRIPT_OPTS ",
                   'y', 'y');

    # EM SRDC
    if ( $xmlfilters =~ /emtbsmetric/ ) {
      $database = "";
    }
    if ( $xmlfilters =~ /dbasm/ ) { 
      $database = "+ASM";
      my $retval = (dbutil_setOraEnv($tfa_home,"$database","",FALSE))[0];
      if ( $retval ne 0 ) {
        print "No +ASM database was found. Unable to run this SRDC.\nExiting....\n"; 
        $exitcode = 1;
        last dscriptoptions;
      }
    }

    # Have to use proper perl for processing file - no grep.
    my @events;
    my @excludeevents;
    my @validforarray;
    my @inputs;
    my @comps;
    my @scriptsarray;
    my @userinputsarray;
    my $cluster_flag="no";
    my $awrdurationvalid = FALSE;
    my $scriptsmsg = "Scripts to be run by this srdc: ";
    my $scriptfile;
    my $scriptoutfile;
    my $scriptname;
    my $scripttype;
    my $scriptplatform;
    my $scriptversion;
    my $scripttimeout;
    my $scriptread = 0;
    my @scriptstorun;
    my $excludeevent;
    my $collection_id;
    my @errorstack;
    my %cmdlineopts;
    my @cmdlineOpts;
    my %cmdlineoptsvals;
    # parse srdcfile
    # --------------
    ($collection_id,%tfactlglobal_srdc) = tfactlshare_parse_srdcfile($xmlfilters_orig);
    $cluster_flag = $tfactlglobal_srdc{$collection_id}->{clusterwide};
    @events = @{$tfactlglobal_srdc{$collection_id}->{events}} if ( $tfactlglobal_srdc{$collection_id}->{events} );
    @excludeevents = @{$tfactlglobal_srdc{$collection_id}->{excludeevents}} if ( $tfactlglobal_srdc{$collection_id}->{excludeevents} );
    $awrdurationvalid = $tfactlglobal_srdc{$collection_id}->{awrduration};
    @comps = @{$tfactlglobal_srdc{$collection_id}->{components}} if ( $tfactlglobal_srdc{$collection_id}->{components} );
    @scriptsarray = @{$tfactlglobal_srdc{$collection_id}->{scripts_array}} if ( $tfactlglobal_srdc{$collection_id}->{scripts_array});
    @userinputsarray = @{$tfactlglobal_srdc{$collection_id}->{user_inputs_array}} if ( $tfactlglobal_srdc{$collection_id}->{user_inputs_array} );
    @errorstack = @{$tfactlglobal_srdc{$collection_id}->{error_stack}} if ( $tfactlglobal_srdc{$collection_id}->{error_stack} );
    
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "processing cmdline available options for SRDC",
                      'y', 'y');
    #Process cmdline attribute to check command line syntax for the current SRDC
    #--------------------------------------------------------------------------
    foreach my $keyinput ( @userinputsarray ) {
      my $inputhashref = $tfactlglobal_srdc{$collection_id}->{user_inputs};
      my %inputhash = %$inputhashref;
      my $hashattribsref = $inputhash{$keyinput};
      my %hashattribs = %$hashattribsref;

      my $cmdline     = $hashattribs{"cmdline"};
      my $defaultval  = $hashattribs{"default"};
      my $content     = $hashattribs{"content"};
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "Adding cmdline user input option  $cmdline for GetOptions.",
                      'y', 'y');
      print $srdc_log_fh "Adding cmdline user input option  $cmdline for GetOptions.\n";
      print $srdc_log_fh "       defaultval $defaultval, content $content\n";
      if ( $cmdline ) {
        my $opt = $cmdline."=s";
        push(@cmdlineOpts,$opt);
        $cmdlineopts{$cmdline} = \$cmdlineoptsvals{$cmdline};
      }
    }
    $unknownopt = 0;
    GetOptions( \%cmdlineopts, @cmdlineOpts ) or $unknownopt = 1 if (@ARGV);
    if(@ARGV or $unknownopt) {
      print "\nInvalid Option for this SRDC: @ARGV\n" if (@ARGV);
      print_help("diagcollect", "");
      last dscriptoptions;
    }
    #------------------------------------------------------------------------------
    #Check duration
    if ( $tfactlglobal_srdc{$collection_id}->{duration} ) {
      if ( not $last and not $since and not $from and not $to) {
        $duration = $tfactlglobal_srdc{$collection_id}->{duration};
      }
    }

    # Validate awrdurationvalid
    if ( not $awrduration ) {
      if ( length $awrdurationvalid && $awrdurationvalid =~ /([0-9]+)[hH]/ ) {
        $awrduration = $1;
      } else {
        $awrduration = 1;
      }
    } # end if not $awrduration

    ### print "collection_id $collection_id\n";
    ### print "events @events\n";
    ### print "excludeenvents @excludeevents\n";
    ### print "comps @comps\n";
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "parse srdcfile collection_id $collection_id", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "parse srdcfile events @events", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "parse srdcfile excludeenvents @excludeevents", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "parse srdcfile comps @comps", 'y', 'y');

    #Get a list of the scripts and add validfors
    foreach my $keyinput ( @scriptsarray ) {
      ### print "key $keyinput\n";

      # my %hashattribs = %{%{$tfactlglobal_srdc{$collection_id}->{scripts}}{$keyinput}};
      my $scriptshashref = $tfactlglobal_srdc{$collection_id}->{scripts};
      my %scriptshash = %$scriptshashref;
      my $hashattribsref = $scriptshash{$keyinput};
      my %hashattribs = %$hashattribsref;

      my $platform = $hashattribs{"platform"};
      my $validfor = $hashattribs{"validfor"};
      my $name     = $hashattribs{"name"};

      if ( ! length $platform or $platform eq $osname  or 
           ( $platform eq "allux" and (!$IS_WINDOWS))) {
              $scriptsmsg .= $name . " ";
      }
      if (length $validfor) {
            print $srdc_log_fh "Considering $validfor for validforarray\n";
            if ( (uc($validfor) ne "TARGETDB") && (uc($validfor) ne "REPOSITORYDB") ) {
              print $srdc_log_fh "Added $validfor to validforarray\n";
              push(@validforarray,$validfor);
            }
      }
    } # end foreach $keyinput


    # EM SRDC, validate if all the EM components are available locally
    if ( lc($xmlfilters) =~ /em(tbsmetric|metricalert|debugon|debugoff|procdisc|gendisc|clusdisc|cliadd|dbsys|restartoms|agentperf|omscrash|omsheap|omshungcpu)/ ) {
      @validforarray = keys %{{ map{$_=>1}@validforarray}};
      foreach my $key (keys %discemcomp) {
         ### print "key $key\n";
         $emcomps .= $key . " ";
      }
      $emcomps = trim($emcomps);
      # manuegar_em_dbdisc02
      print "SRDC $xmlfilters uses the following TFA EM components : @validforarray\n" if @validforarray;
      my $notallvalidfor = FALSE;
      foreach my $srdcvalidfor (@validforarray) {
         if ( not exists $discemcomp{$srdcvalidfor} ) {
           $notallvalidfor = TRUE;
           last;
         }
      }
      if ( $notallvalidfor ) {
        print "Warning, all the TFA EM components needed by $xmlfilters are not available on this host.\n";
        print "It will only execute the scripts for the available components.\n";
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                          "in xmlfilters, Warning, all the EM components needed by $xmlfilters are not available on this host.", 'y', 'y');
        print "TFA EM components found on this host: $emcomps.\n";
        my $selectionval = tfactlshare_get_choice_yn("y","n",
                           "Do you want to continue [y,n, default y]?", "y" );
        if ( uc($selectionval) eq "N" ) {
          exit 0;
        }

      } else {
        ### print "All the EM components are available locally.\n";
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                          "in xmlfilters, All the EM components are available locally.", 'y', 'y');
      }
    }

    # Prepare customized file on local node
    my @cp_args = ("$xmlfilters_orig","$xmlfilters_fp","1");
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                          "in xmlfilters copying filters to :$xmlfilters_fp ", 'y', 'y');
    osutils_cp(@cp_args);
    chmod(0700,$xmlfilters_fp);

    if ( lc($cluster_flag) !~ /yes/ ) {
      if ( $DSCRIPT_OPTS !~ /\-node\s+local/ ) { # Not already in $DSCRIPT_OPTS
        $DSCRIPT_OPTS .= " -node local";
        $node = "local";
      }
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "in xmlfilters cluster_flag no DSCRIPT_OPTS:$DSCRIPT_OPTS ", 'y', 'y');
    } else { # Clusterwide srdc request
      if ( $DSCRIPT_OPTS !~ /\-node\s+all/ ) { # -node all  Not already in $DSCRIPT_OPTS
        $DSCRIPT_OPTS .= " -node all";
      }
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "in xmlfilters cluster_flag no DSCRIPT_OPTS:$DSCRIPT_OPTS ", 'y', 'y');
    } # end if lc($cluster_flag) !~ /yes/

# Processing user inputs
# If a User input is required then it will be in the XML but will utilize diagcollect command line options when supplied.
# xml always has USERINPUT- followed by the input required.
# Valid options
# EVENT_TIME - equivalent to -for 
# EVENT_START_TIME equivalent to -from
# EVENT_END_TIME equivalent to -to
# EVENT_BASELINE_START_TIME -- for use in perf analysis 
# EVENT_BASELINE_END_TIME -- for use in perf analysis
# DATABASE_NAME 
# SID_NAME
#

    # Accept CTRL-C for all inputs
    local($SIG{INT}) = sub { print "Cancelling...\n"; exit 0; };

    # When using the -silent flag make sure that all the
    # USER-INPUTS were provided
    # --------------------------------------------------
    # String example
    # <user_input cmdline="for-from-since" 
    # cmdline="for" default="" showprompt="1" setenv="NO" validate="" prompt="Enter the time of the ">USERINPUT-EVENT_TIME</user_input>
    #
    # if showprompt is 0 use default and do not show prompt unless overridden at the command line. 
    # if showprompt is 1 prompt for the value using the prompt given if not provided on the command line.
    # if setenv is YES then set an ENV variable of name after USERINPUT- to the value provided or on the command line.
    # if default is set and nothing is entered at the prompt then use it.
    # if validate is set then ensure the entry matches the requirement.
    # print "inputs @inputs\n";
    my %xmlfilterinputs;
    my @inputs_list; # required for ordering of inputs.
    my $xmlcmdline;
    my $xmldefault;
    my $xmlvalidfor="";
    my $xmlvalidate="";
    my $xmlshowprompt;
    my $xmlsetenv;
    my $xmlprompt;
    my $xmlinp;
    my $xmldepinp;
    my $xmldeppattern;
    my $xmlmsg;
    my $xmlrequired;
    my $awrdurationflag =FALSE;
    my $eventtimeflag =FALSE;
    # parse srdcfile
    # --------------
    foreach my $keyinput ( @userinputsarray ) {
      ### print "key $keyinput\n";

      # my %hashattribs = %{%{$tfactlglobal_srdc{$collection_id}->{user_inputs}}{$keyinput}};

      my $inputhashref = $tfactlglobal_srdc{$collection_id}->{user_inputs};
      my %inputhash = %$inputhashref;
      my $hashattribsref = $inputhash{$keyinput};
      my %hashattribs = %$hashattribsref;

      $xmlcmdline     = $hashattribs{"cmdline"};
      $xmldefault     = $hashattribs{"default"};
      $xmlvalidfor    = $hashattribs{"validfor"};
      $xmlshowprompt  = $hashattribs{"showprompt"};
      $xmlsetenv      = $hashattribs{"setenv"};
      $xmlvalidate    = $hashattribs{"validate"};
      $xmlprompt      = $hashattribs{"prompt"};
      $xmldepinp      = $hashattribs{"depinput"};
      $xmldeppattern  = $hashattribs{"deppattern"};
      $xmlmsg         = $hashattribs{"msg"};
      $xmlrequired    = $hashattribs{"required"};
      $xmlinp         = $keyinput;

      # Load Hash of arrays for inputs.
      $xmlfilterinputs{$xmlinp} = [$xmlcmdline,$xmldefault,$xmlvalidfor,$xmlshowprompt,$xmlsetenv,$xmlvalidate,$xmlprompt,$xmldepinp,$xmldeppattern,$xmlmsg,$xmlrequired];
      push @inputs_list, $xmlinp;

      ### print "prompt $xmlprompt\n";

    } # end foreach $keyinput


    # SRDCSILENT
    # ----------

    if ( $SRDCSILENT ) {
      my @notsupplied;
      foreach my $key ( keys %xmlfilterinputs ) {
        #TODO Use the cmdline opts to work this out ...
        if ( ($key =~ /EVENT_TIME/  && not ($for || $from || $since) ) ||
             ($key =~ /EVENT_START_TIME/  && not $from) ||
             ($key =~ /EVENT_END_TIME/ && not $to) ||
             ($key =~ /EVENT_BASELINE_START_TIME/ && not $baselinefrom) ||
             ($key =~ /EVENT_BASELINE_END_TIME/ && not $baselineto) ||
             ($key =~ /DATABASE_NAME/ && not $database) ||
             ($key =~ /DBSNMP_PWD/ && not $xmlfilterinputs{"TARGET_DBNAME"}) ||
             ($key =~ /SYSMAN_PWD/ && not $xmlfilterinputs{"REPOSITORY_DBNAME"}) ) {
          push @notsupplied, $key;
        } # end if
      } # end foreach keys %xmlfilterinputs
      if ( @notsupplied ) {
        print "@notsupplied must be supplied for $xmlfilters When using the -silent switch.\n";
        exit 1;
      }

      # Validate that the input dates are valid
      my $validts;
      if ( $for ) {
        $validts = getValidDateFromString($for, "startdate");
        if ( $validts eq "invalid") {
          print "The timestamp $for used in the -for switch is invalid.\n";
          exit 1;
        } # end if $validts eq "invalid"
      }
      if ( $from ) {
        $validts = getValidDateFromString($from, "startdate");
        if ( $validts eq "invalid") {
          print "The timestamp $from used in the -from switch is invalid.\n";
          exit 1;
        } # end if $validts eq "invalid"
      } # end if $from
      if ( $to ) {
        $validts = getValidDateFromString($to, "startdate");
        if ( $validts eq "invalid") {
          print "The timestamp $to used in the -to switch is invalid.\n";
          exit 1;
        } # end if $validts eq "invalid"
      } # end if $to
      if ( $baselinefrom ) {
        $validts = getValidDateFromString($baselinefrom, "startdate");
        if ( $validts eq "invalid") {
          print "The timestamp $baselinefrom used in the -baselinefrom switch is invalid.\n";
          exit 1;
        } # end if $validts eq "invalid"
      } # end if $baselinefrom
      if ( $baselineto ) {
        $validts = getValidDateFromString($baselineto, "startdate");
        if ( $validts eq "invalid") {
          print "The timestamp $baselineto used in the -baselineto switch is invalid.\n";
          exit 1;
        } # end if $validts eq "invalid"
      } # end if $baselineto
      if ( $since ) {
        if (!($since =~ /^(\d+)d{1}$/ || $since =~ /^(\d+?)h{1}$/)) {
          print "The -since value entered is invalid: $since\n";
        }
      } # end if $since
    } # end if $nomonitor

    my $issuenow        = FALSE;
    my $performok       = FALSE;
    my $isemrepodblocal = FALSE;
    my $licenseflag = FALSE;
    my $reproduce = FALSE;
    my $errorstackflag = FALSE;
    my $starttime;
    my $endtime;
    my $starttimegood;
    my $endtimegood;
    my $isrunning;
    my %dbenv;
    
    # Print the args to the log file.

    print $srdc_log_fh "ARG: xmlfilters $xmlfilters \n";
    print $srdc_log_fh "ARG: DSCIPT_OPTS(2) $DSCRIPT_OPTS \n";

 
    # ---------------------------------------------------------------------------
    # Go through the hash of the user input lines and gather the required inputs
    # Processing inputs
    # ---------------------------------------------------------------------------
    my $prompt;
    my $isoptional;
    my $default;
    my $required;
    my $defaultmsg = "";
    my $validfor;
    my $validate;
    my $showprompt;
    my $isvalidinput;
    my $depinput;
    my $deppattern;
    my $msg;
    my %savedinputs;
    my %env;
    my $oh;
    my %dbadmindata; 
    my $cmdline;

    $awrdurationflag = TRUE if( grep /AWR_DURATION/, @inputs_list );
    foreach my $input (@inputs_list)
    {
      $prompt = $xmlfilterinputs{$input}[XMLFILTER_PROMPT];
      $prompt =~ s/LBREAK/\ \n/g;
      $prompt = "Enter value for $input" if not length $prompt;
      $cmdline = $xmlfilterinputs{$input}[XMLFILTER_CMDLINE];
      $default = $xmlfilterinputs{$input}[XMLFILTER_DEFAULT];
      $validfor = $xmlfilterinputs{$input}[XMLFILTER_VALIDFOR];
      $validate = $xmlfilterinputs{$input}[XMLFILTER_VALIDATE];
      $showprompt = $xmlfilterinputs{$input}[XMLFILTER_SHOWPROMPT];
      $depinput = $xmlfilterinputs{$input}[XMLFILTER_DEPINPUT];
      $deppattern = $xmlfilterinputs{$input}[XMLFILTER_DEPPATTERN];
      $msg = $xmlfilterinputs{$input}[XMLFILTER_MSG];
      $required = $xmlfilterinputs{$input}[XMLFILTER_REQUIRED];
      #--------------------------------------------------------------------------------------
      #default works for dynamic USERINPUTS since the other USERINPUTS handle its own inputs
      #-------------------------------------------------------------------------------------
=head
      print "prompt $prompt\n";
      print "default $default\n";
      print "validfor $validfor\n";
      print "validate $validate\n";
      print "showprompt $showprompt\n";
      print "depinput $depinput\n";
      print "deppattern $deppattern\n";
=cut
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "in xmlfilters looping inputs array \n prompt:$prompt default:$default validfor:$validfor validate:$validate \n " .
                        "showprompt:$showprompt  depinput: $depinput deppattern: $deppattern cmdline: $cmdline",'y','y');
      if ( lc($required) eq "opt" or lc($required) eq "null") {
        $defaultmsg = "Optional";
        $isoptional = TRUE;
      } else {
        $defaultmsg = "Required";
        $isoptional = FALSE;
      }
      # Check to see if this prompt has a dependency on a previous input and match
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
            "in xmlfilters checking depinput against saved depinput: $depinput saved:" . $savedinputs{$depinput} ,'y','y');
      if ( length $depinput && exists $savedinputs{$depinput}) {
            tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                   "in xmlfilters checking deppattern: $deppattern against saved:" . $savedinputs{$depinput} ,'y','y');
         if ( $savedinputs{$depinput} =~ /$deppattern/ ) {
            # this is a valid prompt for the previous input
            print $srdc_log_fh "Valid dependent input:$depinput value $savedinputs{$depinput} match: $deppattern\n";
         } else {
            print $srdc_log_fh "Invalid dependent input:$depinput value $savedinputs{$depinput} match: $deppattern\n";
            #If we have a default value and we are skipping the USERINPUT take the default value for further dependencies
            if ( $default ) {
             if ( $input !~ /_PWD/i ) {
                system("$PERL -p -i.orig -e \"s/-$input:?/-$input=$default/\" $xmlfilters_fp");
                $savedinputs{$input} = $default;
             }
            }
            next;
         }
      }
      # EM SRDC
      # skip input if attribute validfor present and that EM
      # component was not discovered
      if ( length $validfor ) {
        ### print "prompt $prompt, validfor $validfor\n";
        if ( not exists $discemcomp{$validfor} ) {
          next;
        }
      } # end if length $validfor
      chomp($input);
      ### print "input $input prompt $prompt\n";
      my $userinp;
      if ( $input eq "ORACLE_HOME" )
      {
        print $srdc_log_fh "DIS: Requesting ORACLE_HOME\n";
        print $srdc_log_fh "DIS: validating ORACLE_HOME\n";
        $userinp = tfactldiagcollect_get_oracle_home_ip($tfa_home);
        $oh = $userinp;
        print $srdc_log_fh "INP: ORACLE_HOME supplied : $userinp\n";
      # --------------------------
      } elsif ( $input =~ /STOP/ ) {
      # --------------------------
        my $stopnow;
        my $stopnow_opt;
        print "$prompt [Y|y|N|n] [Y]: ";
        print $srdc_log_fh "DIS: $prompt [Y|y|N|n] [Y]: \n";
        chomp( $stopnow_opt = <STDIN> );
        print $srdc_log_fh "INP: stopnow_opt $stopnow_opt \n";
        $stopnow_opt ||= "Y";
        $stopnow_opt = get_valid_input ( $stopnow_opt, "Y|y|N|n", "Y");
        $stopnow = TRUE if lc($stopnow_opt) eq "y";
        if ($stopnow) {
           print "Exiting this SRDC....\n";
           exit(0);
        }
      # --------------------------
      } elsif ( $input =~ /TFA_HOME/ ) {
      # --------------------------
        $userinp = $tfa_home;
      # -------------------------
      }elsif ( $input =~ /ISSUE_NOW/ ) {
      # --------------------------
        my $issuenow_opt;
        print "$prompt [Y|y|N|n] [Y]: ";
        print $srdc_log_fh "DIS: $prompt [Y|y|N|n] [Y]: \n";
        chomp( $issuenow_opt = <STDIN> );
        print $srdc_log_fh "INP: issuenow_opt $issuenow_opt \n";
        $issuenow_opt ||= "Y";
        $issuenow_opt = get_valid_input ( $issuenow_opt, "Y|y|N|n", "Y");
        $issuenow = TRUE if lc($issuenow_opt) eq "y";
        if ($issuenow){
          $userinp = "true";
          if( ! $awrdurationflag ){
            while (not $awrdurationvalid) {
              $awrduration = 1 if( ! $awrduration );
              print "Enter duration of the issue in hours [<RETURN>=$awrduration" . "h] : ";
              print $srdc_log_fh "DIS: Enter duration of the issue in hours [<RETURN>=$awrduration" . "h] : \n";
              chomp( $userinp = <STDIN> );
              if ( length $userinp == 0 ) {
                $awrdurationvalid = TRUE;
              } else {
                if ( $userinp =~ /([0-9]+)[hH]/ ) {
                  $awrduration = $1;
                  $awrdurationvalid = TRUE;
                } else {
                  print "The duration $userinp is not valid.\n";
                }
              } # end if length $userinp == 0
            } # end while
            my $currtime     = strftime "%b/%d/%Y %H:%M:%S", localtime();
            my $utscurrtime  = getValidDateFromString($currtime, "time");
            my $awrhours = $awrduration * 60 * 60;
            $endtime   = strftime "%b/%d/%Y %H:%M:%S", localtime($utscurrtime);
            $starttime = strftime "%b/%d/%Y %H:%M:%S", localtime($utscurrtime - $awrhours);
          }

        } else {
          $userinp = "false";
        }
        ###print "opt $issuenow_opt issuenow $issuenow\n";
      # --------------------------
      }elsif ( $input =~ /LICENSE/){
        my $license = tfactlshare_get_awrlicense($tfa_home,$database);
        if( $license !~ /DIAGNOSTIC/){
          #Check for false negative in case they have a license but is not set up.
          my $license_opt;
          print "$prompt [Y|y|N|n] [Y]: ";
          print $srdc_log_fh "DIS: $prompt [Y|y|N|n] [Y]: \n";
          chomp($license_opt =<STDIN>);
          print $srdc_log_fh "INP: license_opt $license_opt \n";
          $license_opt ||="Y";
          $license_opt = get_valid_input( $license_opt ,"Y|y|N|n", "Y");
          if( lc($license_opt) eq "y"){
            print "Select your corresponding license DIAGNOSTIC+TUNNING T or DIAGNOSTIC D  [T|t|d|D] [D] : ";
            chomp($license_opt = <STDIN>);
            $license_opt ||= "D";
            $license_opt = get_valid_input( $license_opt ,"T|t|d|D", "D");
            $userinp =  "DIAGNOSTIC+TUNNING" if( uc($license_opt) eq "T" );
            $userinp =  "DIAGNOSTIC" if ( uc($license_opt) eq "D" );
          } else {
            $userinp = "NONE";
          }
        } else {
            $userinp = $license;
        }
        if ( $userinp =~/DIAGNOSTIC/ ){
          $licenseflag = TRUE;
        }
      } elsif ( $input eq "ERROR_STACK" ) {
        my $eventsset = FALSE;
        my @set;
        #Check if events are set
        if ( @errorstack ) {
          my @events = dbutil_lsEventsSet($tfa_home,$database);
          if ( @events ) {
            $eventsset = TRUE;
            foreach my $error ( @errorstack) { #Check if events provided in the xml are set.
              my %errstckhash = %$error;
              my $code  = $errstckhash{"error_code"};
              my @found =  grep {$_ =~ /$code/ }@events;
              if ( ! @found ) {
                $eventsset = FALSE;
              } else {
                 push @set, $code;
              }
            }
          }
        }
        if ( $eventsset ){
          print "This SRDC was run and the following events were set.\n";
          print "@set \n";
          print "Please ensure that the issue was reproduced in order to collect the right information.";
          print "Do you want to continue ? Y|N [N]: ";
          my $opt;
          chomp($opt = <STDIN>);
          $opt ||="N";
          $opt = get_valid_input ( $opt , "Y|y|N|n","N");
          if ( uc($opt) eq "N" ){
            exit(0);
          }
          #Disable errorstack and continue with the  collection.
          dbutil_errorstack($tfa_home,$database,\@errorstack,"OFF");

        } else {
          #Events are not set,
          #check if they want to set error stack
          my $opt;
          print "$prompt [Y|y|N|n ] [N]: ";
          print $srdc_log_fh "DIS: $prompt [Y|y|N|n] \n";
          chomp($opt = <STDIN>);
          print $srdc_log_fh "INP: errorstack $opt \n";
          $opt ||="N";
          $opt = get_valid_input( $opt, "Y|y|N|n", "N" );
          $errorstackflag = TRUE if ( uc ($opt) eq "Y");
          if ( $errorstackflag ) {
            if ( ! @errorstack ){
              print "ERROR: No errorstack section provided in the XML \n";
              exit 0; 
            }
          }
        }
      } elsif ( $input eq "REPRODUCE" ) {
        if ( $errorstackflag ) {
          my $opt; 
          print "$prompt [Y|y|N|n] [N]: ";
          print $srdc_log_fh "DIS: $prompt [Y|y|N|n] \n";
          chomp($opt = <STDIN>);
          print $srdc_log_fh "INP : reproduce  $opt \n";
          $opt ||="N";
          $opt = get_valid_input ( $opt , "Y|y|N|n","N");
          $reproduce = TRUE if (uc($opt) eq "Y");
        }
      } elsif ( $input eq "SQL_FILE" ) {
        my $sqlfile ;
        if ( $errorstackflag ){
          if ( $reproduce ) { 
            my $valid_sql = FALSE;
            while ( ! $valid_sql ) {
              print "$prompt : ";
              chomp($sqlfile = <STDIN>);
              if ( -e $sqlfile ) {
                $valid_sql = TRUE;
              } else { 
                print " SQL File does not exists please provide a valid SQL File and try again!\n";
                }
            }
            dbutil_errorstack($tfa_home,$database,\@errorstack,"ON",$sqlfile,"file",uc("srdc_".$collection_id));
          } else {
            #Cannot be reproduce set errorstack at SYSTEM level.
            dbutil_errorstack($tfa_home,$database,\@errorstack,"ON","","",uc("srdc_".$collection_id));
            print "Please wait until the issue reproduces, once the issue reproduces re-run this SRDC\n";
            exit 0;
          }
        }
      }elsif ( $input =~ /SQL_SLOW/ ) {
        my $slow_sql;
        print "$prompt [<RETURN>=NO_SQL_ID] : ";
        print $srdc_log_fh "DIS: $prompt [<RETURN>=NO_SQL_ID] : \n";
        chomp($slow_sql = <STDIN> );
        $userinp = $slow_sql if ( length $slow_sql);

      } elsif ( $input =~ /SIMULATE/ ) {
        dbutil_setOraEnv($tfa_home,$database,"",TRUE);
        my $opt;
        print "$prompt [Y|y|N|n] [Y] : ";
        print $srdc_log_fh "DIS: $prompt [Y|y|N|n] [Y] : \n";
        chomp($opt = <STDIN>);
        $opt ||="Y";
        $opt = get_valid_input( $opt , "Y|y|N|n", "Y");
        if ( lc($xmlfilters) eq "dbshutdown" ) {
          if( uc($opt) eq "Y") {
            print "NOTE: This SRDC is intended for customers that are unable to shutdown the database,\n";
            print "please confirm that you would like to proceed [Y/N] [N] :";
            chomp($opt = <STDIN> );
            $opt||="N";
            $opt = get_valid_input( $opt, "Y|y|N|n","N");
            if ( uc($opt) eq "Y" ) {
              #Get tablespace and blocksize;
              #--------------------------------------------------
              my @tbs  = tfactlshare_run_a_sql("sql","set heading off;\n select value from v\$parameter where name=\'undo_tablespace\';");
              chomp(@tbs);
              @tbs = grep {$_ ne ''} @tbs; 
              my @block_size = tfactlshare_run_a_sql("sql", "set heading off;\n select block_size from dba_tablespaces where tablespace_name=\'$tbs[0]\';");
              chomp(@block_size);
              @block_size = grep{$_ ne '' } @block_size;
              #-------------------------------------------------
              if ( ! $IS_WINDOWS ){

                #Option #1 
                if ( ! $dbadmindata{"completed"} ) {
                  print "Please open a sqlplus session and do the following steps:  \n";
                  print " 1- shutdown abort\n";
                  print " 2- startup restrict\n";
                  print "Can you complete this task at this moment ? Y/N [N]";
                  chomp($opt = <STDIN> );
                  $opt||="N";
                  $opt = get_valid_input($opt,"Y|y|N|n","N");
                  if ( uc($opt) ne "Y" ){
                      print "Exiting this SRDC....\n";
                      exit(0);
                  }
                  print "Press <Enter> when the above steps are complete.\n";
                  <STDIN>;
                }
                    
                #Enable errorstack if any errors.
                my @errstck;
                if ( $dbadmindata{"ora_errors"} ){
                  my %errstckhash;
                  $errstckhash{"level"} = "3";
                  $errstckhash{"context"} ="errorstack";
                  my @oraerrors = @{$dbadmindata{"ora_errors"}};
                  foreach my $err ( @oraerrors ) {
                    $errstckhash{"error_code"} = $err;
                    push @errstck, \%errstckhash;  
                  }
                  dbutil_errorstack($tfa_home,$database,\@errstck,"ON","","",uc("srdc_".$collection_id));
                }#end if ora_errors 
                    
                #Check for long running transactions of rollback;
                print "Running scripts for long running transactions of rollback...\n";
                open (my $fh , '>', $hostname."_long_running_txns.out");
                my $script = "select count (*) from v\$session_longops where time_remaining > 0;\n";
                $script .= " select sum (used_ublk) * $block_size[0] from v\$transaction;\n";
                $script .= " select * from x\\\$ktuxe where ktuxecfl = \'DEAD\';\n";
                my @out = tfactlshare_run_a_sql("sql",$script);
                foreach (@out) {
                  print $fh $_ ."\n";
                }
                close ($fh);
                
                #Run srdc_transaction_recovery.sql 
                print "Running transaction recovery SQL script.......\n";
                my $sqlfile = catfile($tfa_home,"resources",,"sql","srdc_transaction_recovery.sql");
                @out = tfactlshare_run_a_sql("file",$sqlfile);
               
                if ( $dbadmindata{"ora_errors"} ){
                  dbutil_errorstack($tfa_home,$database,\@errstck,"OFF");
                }

                #Enable 10046 and SSD and then initiate Shutdown.
                print " Please execute the following in a sqlplus session\n";
                print "alter session set events \'10046 trace name context forever, level 12\';\n";
                print "alter session set events \'10400 trace name context forever, level 1\';\n";
                print "shutdown immediate\n";
                print "Wait for 15 minutes\n";
                print "Press <Enter> when complete\n";
                <STDIN>;

                
                #Check active processes for sid
                print "Checking active processes for $database\n";
                open ( my $fh, '>',$hostname."_".$database."_active_processes.out");
                open ( my $fh2, '>',$hostname."_".$database."_pstack.out");
                my @processes = `$PS -fea | $GREP $database | $GREP -v grep`;
                foreach my $proc (@processes) {
                  chomp($proc);
                  print $fh $proc."\n";
                  my @cols = split(/\s+/,$proc);
                  print $fh2  "PSTACK FOR PROCESS $cols[1] $cols[7] \n";
                  print $fh2 "___________________________________________________\n";
                  my @out  = `pstack $cols[1]`;
                  print  $fh2 "@out \n";
                }#end foreach process
                close($fh);
                close($fh2);
              }else {
                #WINDOWS 

                #Enable errorstack if any errors.
                my @errstck;
                if ( $dbadmindata{"ora_errors"} ){
                  my %errstckhash;
                  $errstckhash{"level"} = "3";
                  $errstckhash{"context"} ="errorstack";
                  my @oraerrors = @{$dbadmindata{"ora_errors"}};
                  foreach my $err ( @oraerrors ) {
                    $errstckhash{"error_code"} = $err;
                    push @errstck, \%errstckhash;  
                  }
                  dbutil_errorstack($tfa_home,$database,\@errstck,"ON","","",uc("srdc_".$collection_id));
                }#end if ora_errors 
                    
                #Check for long running transactions of rollback;
                print "Running scripts for long running transactions of rollback...\n";
                open (my $fh , '>', $hostname."_long_running_txns.out");
                my $script = "select count (*) from v\$session_longops where time_remaining > 0;\n";
                $script .= " select sum (used_ublk) * $block_size[0] from v\$transaction;\n";
                $script .= " select * from x\\\$ktuxe where ktuxecfl = \'DEAD\';\n";
                my @out = tfactlshare_run_a_sql("sql",$script);
                foreach (@out) {
                  print $fh $_ ."\n";
                }
                close ($fh);
               
                #Run srdc_transaction_recovery.sql
                print "Running transaction recovery SQL script.......\n";
                my $sqlfile = catfile($tfa_home,"resources",,"sql","srdc_transaction_recovery.sql");
                @out = tfactlshare_run_a_sql("file",$sqlfile);
               
                if ( $dbadmindata{"ora_errors"} ){
                  dbutil_errorstack($tfa_home,$database,\@errstck,"OFF");
                }

                #Enable 10046 and SSD and then initiate Shutdown.
                print "Please execute the following in a sqlplus session\n";
                print "alter session set events \'10046 trace name context forever, level 12\';\n";
                print "alter session set events \'10400 trace name context forever, level 1\';\n";
                print "shutdown immediate\n";
                print "Wait for 15 minutes\n";
                print "Press <Enter> when complete\n";
                <STDIN>;

              }
            } else {
              print "Exiting this SRDC .... \n";
              exit (0);
            }
          } else { 
            if (! $dbadmindata{"completed"} ){
              if ( ! $IS_WINDOWS ){
                open ( my $fh, '>',$hostname."_".$database."_active_processes.out");
                open ( my $fh2, '>',$hostname."_".$database."_pstack.out");
                my @processes = `$PS -fea | $GREP $database | $GREP -v grep`;
                foreach my $proc (@processes) {
                  chomp($proc);
                  print $fh $proc."\n";
                  my @cols = split(/\s+/,$proc);
                  print $fh2  "PSTACK FOR PROCESS $cols[1] $cols[7] \n";
                  print $fh2 "___________________________________________________\n";
                  my @out  = `pstack $cols[1]`;
                  print  $fh2 "@out \n";
                }#end foreach process
                close($fh);
                close($fh2);
              }
            }
          }
        } else {
          #STARTUP
          if( uc($opt) eq "Y") {
            #Option I 
            ##Enable errorstack if any errors.
            my @errstck;
            if ( $dbadmindata{"ora_errors"} ){
              my %errstckhash;
              $errstckhash{"level"} = "3";
              $errstckhash{"context"} ="errorstack";
              my @oraerrors = @{$dbadmindata{"ora_errors"}};
              foreach my $err ( @oraerrors ) {
                $errstckhash{"error_code"} = $err;
                push @errstck, \%errstckhash;  
              }
              dbutil_errorstack($tfa_home,$database,\@errstck,"ON","","",uc("srdc_".$collection_id));
            }#end if ora_errors 
            if ( ! $IS_WINDOWS ) {
              #Enable strace 
              print "Please execute the following commands:\n";
              my $cwd = getcwd();
              if ( $IS_SOLARIS || $osname eq "AIX" ) {
                print "truss -eafo $cwd/start_trace.out /nolog\n";
              } elsif( $osname eq "Linux" ) {
                print "strace -ftT -o $cwd/start_trace.out sqlplus /nolog\n";
              } elsif( $osname eq "HP-UX" ) {
                print "tusc -aef -o $cwd/start_trace.out -T \"%H%M%S\" sqlplus /nolog\n"; 
              }
              print "SQL>conn / as sysdba;\n";
              print "SQL>startup\n";
              print "Wait 5-10 minutes then kill process and do shutdown immediate if necessary\n";
              print "Press <Enter> when complete\n";
              <STDIN>;
            }
            print "Please execute the following script in a sqlplus session.\n";
            print "startup nomount\n";
            print "alter session set events \'10046 trace name context forever, level 12';\n";
            print "alter database mount;\n";
            print "alter database open;\n";
            print "Wait for 10 minutes.\n";
            print "Press <Enter> when complete\n";
            <STDIN>;
            
            dbutil_setOraEnv($tfa_home,$database,"",TRUE);

            ###Collect hanganalyze
            print "Running hanganalyze....\n";
            my @out = dbutil_hanganalyze();
            print "Hang analysis in $out[scalar(@out)-1] \n";

            ##Run srdc_transaction_recovery.sql at least 3 times in a interval of 5 minutes 
            print "Running transaction recovery SQL script.......\n";
            my $sqlfile = catfile($tfa_home,"resources",,"sql","srdc_transaction_recovery.sql");
            @out = tfactlshare_run_a_sql("file",$sqlfile);
            sleep(100);
            @out = tfactlshare_run_a_sql("file",$sqlfile);
            sleep(100);
            @out = tfactlshare_run_a_sql("file",$sqlfile);
            sleep(100);
            @out = tfactlshare_run_a_sql("file",$sqlfile);
            
            if ( $dbadmindata{"ora_errors"} ){
              dbutil_errorstack($tfa_home,$database,\@errstck,"OFF");
            }


          } else {
             if ( ! $dbadmindata{"completed"} ) {
               #OPTION II
               ##Enable errorstack if any errors.
               my @errstck;
               if ( $dbadmindata{"ora_errors"} ){
                 my %errstckhash;
                 $errstckhash{"level"} = "3";
                 $errstckhash{"context"} ="errorstack";
                 my @oraerrors = @{$dbadmindata{"ora_errors"}};
                 foreach my $err ( @oraerrors ) {
                   $errstckhash{"error_code"} = $err;
                   push @errstck, \%errstckhash;  
                 }
                 dbutil_errorstack($tfa_home,$database,\@errstck,"ON","","",uc("srdc_".$collection_id));
               }#end if ora_errors
               my $script =   "alter session set tracefile_identifier=\'SSD\';\n";
               $script.= "alter session setevents \'10046 trace name context forever, level 12\'\n";
               $script .=   "alter session setevents \'10400 trace name context forever, level 1\'\n";
               tfactlshare_run_a_sql("sql",$script);

               print "Running hanganalyze....\n";
               my @out = dbutil_hanganalyze();
               print "Hang analysis in $out[scalar(@out)-1] \n";

               ##Run srdc_transaction_recovery.sql at least 3 times in a interval of 5 minutes 
               print "Running transaction recovery SQL script.......\n";
               my $sqlfile = catfile($tfa_home,"resources",,"sql","srdc_transaction_recovery.sql");
               @out = tfactlshare_run_a_sql("file",$sqlfile);
               sleep(100);
               @out = tfactlshare_run_a_sql("file",$sqlfile);
               sleep(100);
               @out = tfactlshare_run_a_sql("file",$sqlfile);
               sleep(100);
               @out = tfactlshare_run_a_sql("file",$sqlfile);

               if ( $dbadmindata{"ora_errors"} ){
                 dbutil_errorstack($tfa_home,$database,\@errstck,"OFF");
               }

             } 
          }
        }
        #Proceeed 
      } elsif ( $input =~ /AWR_DURATION/ ) {
      # --------------------------
        if ( $issuenow ) {
          while (not $awrdurationvalid) {
             $awrduration = 1 if( ! $awrduration );
             print "$prompt [<RETURN>=$awrduration" . "h] : ";
             print $srdc_log_fh "DIS: $prompt [<RETURN>=$awrduration" . "h] : \n";
             chomp( $userinp = <STDIN> );
             if ( length $userinp == 0 ) {
               $awrdurationvalid = TRUE;
             } else {
               if ( $userinp =~ /([0-9]+)[hH]/ ) {
                 $awrduration = $1;
                 $awrdurationvalid = TRUE;
               } else {
                 print "The duration $userinp is not valid.\n";
               }
             } # end if length $userinp == 0
          } # end while

          my $currtime     = strftime "%b/%d/%Y %H:%M:%S", localtime();
          my $utscurrtime  = getValidDateFromString($currtime, "time");
          my $awrhours = $awrduration * 60 * 60;
          $endtime   = strftime "%b/%d/%Y %H:%M:%S", localtime($utscurrtime);
          $starttime = strftime "%b/%d/%Y %H:%M:%S", localtime($utscurrtime - $awrhours);
          ###print "issue now, start time $starttime, end time $endtime\n";

        } # end if $issuenow
      # --------------------------
      } elsif ( $input =~ /EVENT_TIME/ ) {
      # --------------------------
        if ( $event_time ) {
          $userinp = $event_time;
        } elsif ( $for ) {
          tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                            "in xmlfilters got passed $input from commandline : DSCRIPT_OPTS:$DSCRIPT_OPTS ",
                            'y', 'y');
          $userinp = $for;
        } else {
          if ( not ($from || $to || $since ) ) {
            $userinp = tfactlshare_input_date("$prompt [YYYY-MM-DD HH24:MI:SS,<RETURN>=ALL] : ",
                                              "The timestamp format used for $input is invalid.\n");
            $for = $userinp;
            $DSCRIPT_OPTS .= " -for $userinp" if length $userinp;
            tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                              "in xmlfilters input is $input: DSCRIPT_OPTS:$DSCRIPT_OPTS ",
                              'y', 'y');
          } # end if not ($from || $to || $since
        }
        # -------------------------------------
      } elsif ( $input =~ /EVENT_START_TIME/ ) {
        # -------------------------------------
        if ( $from ) {
          tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                            "in xmlfilters got passed $input from commandline : DSCRIPT_OPTS:$DSCRIPT_OPTS ",
                            'y', 'y');
          $userinp = $from;
          $starttime = $from;
        } else {
          if ( $issuenow ) {
            $userinp = $starttime;
            #$DSCRIPT_OPTS .= " -from $userinp";
            #$from = $userinp;
            $starttime = $userinp;
          } else {
            my $fromvalid = FALSE;
            while ( ! $fromvalid ) {
               $userinp = tfactlshare_input_date("$prompt [YYYY-MM-DD HH24:MI:SS] : ",
                                                 "The timestamp format used for $input is invalid.\n");
               if ( length $userinp ) {
                 #$DSCRIPT_OPTS .= " -from $userinp";
                 #$from = $userinp;
                 $starttime = $userinp;
                 $fromvalid = TRUE;
                 tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                                   "in xmlfilters input is $input : DSCRIPT_OPTS:$DSCRIPT_OPTS ",
                                   'y', 'y');
               } else {
                 print "The timestamp is mandatory for this SRDC\n";
               } # end if length $userinp
            } # end while ( ! $fromvalid )
          } # end if $issuenow
        }
        #Check date for very old  and future dates
        my $age = dateutils_valid_date_age(getValidDateFromString($starttime,"time"));
        if ( $age != 0 ) {
          if( $age == 1 ) {
            print "Invalid date, date cannot be in the future\n";
          } else {
            print "Invalid date, date cannot be older than ".MAX_OLD_DATE." days\n";
          }
          $exitcode = 1;
          last dscriptoptions;
        }
        if ( $issuenow ) {
          print "As you have indicated that the performance issue is currently happening,\n";
          print "will be collecting snapshots for the following periods: \n";      
        }
        print "$msg $starttime \n";
        # -----------------------------------
      } elsif ( $input =~ /EVENT_END_TIME/ ) {
        # -----------------------------------
        if ( $to ) {
          tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                            "in xmlfilters got passed $input from commandline : DSCRIPT_OPTS:$DSCRIPT_OPTS ",
                            'y', 'y');
          $userinp = $to;
          $endtime = $to;
        } else {
          if ( $issuenow ) {
            $userinp = $endtime;
            #$DSCRIPT_OPTS .= " -to $userinp";
            #$to = $userinp;
            $endtime = $userinp;
          } else {
            my $tovalid = FALSE;
            while ( ! $tovalid ) {
               $userinp = tfactlshare_input_date("$prompt [YYYY-MM-DD HH24:MI:SS] : ",
                                                 "The timestamp format used for $input is invalid.\n");
               if ( length $userinp ) {
                 if ( tfactlshare_cmp_timestamps($userinp,$starttime) eq 1 ) {
                   #$DSCRIPT_OPTS .= " -to $userinp";
                   #$to = $userinp;
                   $endtime = $userinp;
                   $tovalid = TRUE;
                   tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                                     "in xmlfilters input is $input : DSCRIPT_OPTS:$DSCRIPT_OPTS ",
                                     'y', 'y'); 
                 } else {
                   print "End time must be greater than start time : $from\n"; 
                 } # end if tfactlshare_cmp_timestamps()
               } else {
                 print "The timestamp is mandatory for this SRDC\n";
               } # end if length $userinp
            } # end while ( ! $tovalid )
          } # end if $issuenow
        }
        #Check date for very old and future dates
        my $age = dateutils_valid_date_age(getValidDateFromString($endtime,"time"));
        if ( $age != 0 ) {
          if( $age == 1 ) {
            print "Invalid date, date cannot be in the future\n";
          } else {
            print "Invalid date, date cannot be older than ".MAX_OLD_DATE." days\n";
          }
          $exitcode = 1;
          last dscriptoptions;
        }
        print "$msg  $endtime \n";
        # -------------------------------
      } elsif ( $input =~ /PERFORM_OK/ ) {
        # -------------------------------
        my $performokvalid = FALSE;
        while ( ! $performokvalid ) {
           print "$prompt [<RETURN> to provide other time range] : ";
           $userinp = <>;
           chomp($userinp);
           if ( length $userinp && $userinp !~ /^[0-9]+$/ ) {
             print "$userinp is not a valid number, please try again.\n";
           } else {
             $performokvalid = TRUE;
           } # end if $userinp !~ /$[0-9]+^/
        } # end while ( ! $performokvalid )

        if ( length $userinp ) {
          $performok = TRUE;
          ### print "start $starttime end $endtime\n";
          my $utsstarttime = getValidDateFromString($starttime, "time");
          my $utsendtime   = getValidDateFromString($endtime, "time");
          my $timeadjust = $userinp * 24 * 60 * 60;
          $starttimegood = strftime "%b/%d/%Y %H:%M:%S", localtime($utsstarttime - $timeadjust);
          $endtimegood   = strftime "%b/%d/%Y %H:%M:%S", localtime($utsendtime - $timeadjust);
          ### print "starttimegood $starttimegood, endtimegood $endtimegood\n";
        }
        # ----------------------------------------------
      } elsif ( $input =~ /EVENT_BASELINE_START_TIME/ ) {
        # ----------------------------------------------
        if ( $baselinefrom ) {
           tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                            "in xmlfilters got passed $input from commandline : DSCRIPT_OPTS:$DSCRIPT_OPTS ",
                            'y', 'y');
           $userinp = $baselinefrom;
        } else {
           if ( $performok ) {
             $userinp = $starttimegood;
             $DSCRIPT_OPTS .= " -baselinefrom $userinp";
             $baselinefrom = $userinp;
           } else {
             my $basefromvalid = FALSE;
             while ( ! $basefromvalid ) {
                $userinp = tfactlshare_input_date("$prompt [YYYY-MM-DD HH24:MI:SS] : ",
                                                  "The timestamp format used for $input is invalid.\n");
                if ( length $userinp ) {
                   $DSCRIPT_OPTS .= " -baselinefrom $userinp";
                   $baselinefrom = $userinp;
                   tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                                     "in xmlfilters input is $input : DSCRIPT_OPTS:$DSCRIPT_OPTS ",
                                     'y', 'y');
                   $basefromvalid = TRUE;
               } else {
                  print "Baseline From time is mandatory for this SRDC\n";
               }
             } # End while ( ! $basefromvalid )
             if ( length $baselinefrom ) {
               ### print "start $starttime end $endtime\n";
               my $utsstarttime = getValidDateFromString($baselinefrom, "time");
               $starttimegood = strftime "%b/%d/%Y %H:%M:%S", localtime($utsstarttime);
               ### print "starttimegood $starttimegood, endtimegood $endtimegood\n";
             }
           } # end if $performok
        }
        #Check date for very old and future dates
        my $age = dateutils_valid_date_age(getValidDateFromString($starttimegood,"time"));
        if ( $age != 0 ) {
          if( $age == 1 ) {
            print "Invalid date, date cannot be in the future\n";
          } else {
            print "Invalid date, date cannot be older than ".MAX_OLD_DATE." days\n";
          }
          $exitcode = 1;
          last dscriptoptions;
        }
        print "$msg $starttimegood\n" if length $starttimegood;
        # --------------------------------------------
      } elsif ( $input =~ /EVENT_BASELINE_END_TIME/ ) {
        # --------------------------------------------
       if ( $baselineto ) {
           tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                            "in xmlfilters got passed $input from commandline : DSCRIPT_OPTS:$DSCRIPT_OPTS ",
                            'y', 'y');
           $userinp = $baselineto;
        } else {
           if ( $performok ) {
             $userinp = $endtimegood;
             $DSCRIPT_OPTS .= " -baselineto $userinp";
             $baselineto = $userinp;
           } else {
             my $basetovalid = FALSE;
             while ( ! $basetovalid ) {
               $userinp = tfactlshare_input_date("$prompt [YYYY-MM-DD HH24:MI:SS] : ",
                                                 "The timestamp format used for $input is invalid.\n");
               if ( length $userinp ) {
                  if ( tfactlshare_cmp_timestamps($userinp,$baselinefrom) eq 1 ) {
                    $DSCRIPT_OPTS .= " -baselineto $userinp";
                    $baselineto = $userinp;
                    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                                      "in xmlfilters input is $input : DSCRIPT_OPTS:$DSCRIPT_OPTS ",
                                      'y', 'y');
                    $basetovalid = TRUE;
                  } else {
                    print "Baseline End time must be greater than baseline start time : $baselinefrom\n";
                  } # end if tfactlshare_cmp_timestamps()
               } else {
                  print "Baseline End time is mandatory for this SRDC\n";
               } # end if length $userinp
             } # End while ( $basetonotvalid )
             if ( length $baselineto ) {
               ### print "start $starttime end $endtime\n";
               my $utsendtime   = getValidDateFromString($baselineto, "time");
               $endtimegood = strftime "%b/%d/%Y %H:%M:%S", localtime($utsendtime);
               ### print "starttimegood $starttimegood, endtimegood $endtimegood\n";
             }
           } # end if $performok
        }
        #Check date for very old and future dates
        my $age = dateutils_valid_date_age(getValidDateFromString($endtimegood,"time"));
        if ( $age != 0 ) {
          if( $age == 1 ) {
            print "Invalid date, date cannot be in the future\n";
          } else {
            print "Invalid date, date cannot be older than ".MAX_OLD_DATE." days\n";
          }
          $exitcode = 1;
          last dscriptoptions;
        }
        print "$msg $endtimegood \n" if ( length $endtimegood );
          # ----------------------------------
      } elsif ( $input =~ /DBSNMP_PWD/ ) {
          # ---------------------------------- 
          # EM SRDC
          my $dbsnmp_notvalid = TRUE;
          my $validout = "";
          while ( $dbsnmp_notvalid ) {
             print "$prompt [Required for this SRDC] : ";
             system "stty -echo" if not $IS_WINDOWS;
             $userinp = <>;
             chomp($userinp);
             system "stty echo" if not $IS_WINDOWS;
             print "\n";

             # validate password
             $validout = tfactlshare_validate_db_account($tfa_home,$em_targetdbname,"dbsnmp",$userinp);
             if ( $validout eq "VALID" ) {
               $dbsnmp_notvalid = FALSE;
             } else {
               if ( $validout eq "SQLPLUSNOTFOUND" ) {
                 print "sqlplus binary not found.\n";
                 exit 1;
               } elsif ( $validout eq "INVALIDPWD" ) {
                 print "Invalid password for user dbsnmp, please provide the correct value.\n";
               } elsif ( $validout eq "ACCOUNTLOCKED" ) {
                 print "The account is locked. Please unlock it and re run this srdc.\n";
                 exit 1;
               } elsif ( $validout eq "PASSWORDEXPIRED" ) {
                 print "The password has expired, please change the password.\n";
                 exit 1;
               } elsif ( $validout eq "INVALID" ) {
                 print "Could not validate credentials.\n";
                 exit 1;
               }
             } # end if $validout eq "VALID"

          } # end while
          $em_dbsnmppwd = $userinp;
          # srdc sec
          $EMDBSNMPPWD = $em_dbsnmppwd;
          # ----------------------------------
        } elsif ( $input =~ /SYSMAN_PWD/ ) {
          # ---------------------------------- 
          # EM SRDC
          my $sysman_notvalid = TRUE;
          my $validout = "";
          while ( $sysman_notvalid ) {
             print "$prompt [Required for this SRDC] : ";
             system "stty -echo" if not $IS_WINDOWS;
             $userinp = <>;
             chomp($userinp);
             system "stty echo" if not $IS_WINDOWS;
             print "\n";

             if ( $em_repositorydb_provided ) {
               # validate password
               if (not $em_remdata) {
                 $validout = tfactlshare_validate_db_account($tfa_home,$em_repositorydbname,"sysman",$userinp);
               } else {
                 ### print "em_hostrepodb $em_hostrepodb\n em_portrepodb $em_portrepodb\n em_servicerepodb $em_servicerepodb\n";
                 $validout = tfactlshare_validate_db_account($tfa_home,$em_targetdbname,"sysman",$userinp,
                                    $em_hostrepodb, $em_portrepodb, $em_servicerepodb);
               }
               if ( $validout eq "VALID" ) {
                 $sysman_notvalid = FALSE;
               } else {
                 if ( $validout eq "SQLPLUSNOTFOUND" ) {
                   # Try to validate sysman password using emctl
                   if ( exists $discemcomp{"OMS"} ) {
                     if ( length $userinp ) {
                       # secure sysman pwd
                       my $emctl = catfile($EMOMSOHOME,"bin","emctl");
                       my $cmd   = "$emctl get property -name log4j.appender.emtrcAppender.File";
                       my $cmdout;

                       use IPC::Open2;
                       local (*Reader, *Writer);
                       my $pid = open2(\*Reader, \*Writer, "$cmd");
                       print Writer "$userinp\n";
                       close Writer;

                       while (<Reader>) {
                         $cmdout .= $_;
                       }

                       # print "cmdout $cmdout\n";
                       if ( $cmdout =~ /Invalid username\/password/ ) {
                         print "Invalid sysman password, please provide the correct value.\n";
                       } else {
                         $sysman_notvalid = FALSE;
                         next;
                       }
                     } else{
                       print "Null password for user sysman, please provide the correct value.\n";
                     }
                   } else {
                     print "sqlplus binary not found.\n";
                     exit 1;
                   } # end if exists $discemcomp{"OMS"}
                 } elsif ( $validout eq "INVALIDPWD" ) {
                   print "Invalid password for user sysman, please provide the correct value.\n";
                 } elsif ( $validout eq "ACCOUNTLOCKED" ) {
                   print "The account is locked. Please unlock it and re run this srdc.\n";
                   exit 1;
                 } elsif ( $validout eq "PASSWORDEXPIRED" ) {
                   print "The password has expired, please change the password.\n";
                   exit 1;
                 } elsif ( $validout eq "DBNOTFOUND" ) {
                   print "DBNOTFOUND, cannot validate sysman password.\n";
                   exit 1;
                 } elsif ( $validout eq "INVALID" ) {
                   print "Could not validate credentials.\n";
                   exit 1;
                 } else {
                   print "validout $validout.\n";
                 }
               } # end if $validout eq "VALID"
             } else {
               if ( exists $discemcomp{"OMS"} ) {
                 if ( length $userinp ) {
                   # secure sysman pwd
                   my $emctl = catfile($EMOMSOHOME,"bin","emctl");
                   my $cmd   = "$emctl get property -name log4j.appender.emtrcAppender.File";
                   my $cmdout; 
 
                   use IPC::Open2; 
                   local (*Reader, *Writer);
                   my $pid = open2(\*Reader, \*Writer, "$cmd");
                   print Writer "$userinp\n";
                   close Writer;

                   while (<Reader>) {
                     $cmdout .= $_;
                   }

                   # print "cmdout $cmdout\n";
                   if ( $cmdout =~ /Invalid username\/password/ ) {
                     print "Invalid sysman password, please provide the correct value.\n";
                   } else {
                     $sysman_notvalid = FALSE;
                     next;
                   }
                 } else{
                   print "Null password for user sysman, please provide the correct value.\n";
                 }
               } else {
                 $sysman_notvalid = FALSE; # No OMS, sysman not needed
               } # end if exists $discemcomp{"OMS"}
             } # end if $em_repositorydb_provided

          } # end while
          if ( $em_repositorydb_provided && $em_remdata ) {
            $em_sysmanpwd = $userinp . "@//$em_hostrepodb:$em_portrepodb/$em_servicerepodb";
            $userinp = $em_sysmanpwd;
          } else {
            $em_sysmanpwd = $userinp;
          }
          # srdc sec
          $EMSYSMANPWD = $em_sysmanpwd;
          # ----------------------------------
        } elsif ( $input =~ /TARGET_ASMINSTANCE/ ) {
          # ----------------------------------
          # EM SRDC
          my $targetasm_notvalid = TRUE;
          my $validout = "";
          my $ohome    = "";
          while ( $targetasm_notvalid ) {
             print "$prompt [$defaultmsg for this SRDC] : ";
             $userinp = <>;
             chomp($userinp);
             if ( (not length $userinp) && $isoptional) {
               $targetasm_notvalid = FALSE;
               next;
             }

             ($validout,$ohome) = tfactlshare_validate_db($tfa_home,$userinp);
             if ($validout eq "DBVALID") {
               $targetasm_notvalid = FALSE;
             } else {
               if ( $validout eq "ORACLE_HOME NOT FOUND" ) {
                 print "ORACLE_HOME not found for target DB.\n";
                 print "Please specify a valid database.\n";
               } elsif ( $validout eq "LISTENER IS NOT RUNNING" ) {
                 print "Listener is not running.\n";
                 exit 1;
               } elsif ( $validout eq "LISTENER HAS NO HANDLER" ) {
                 print "Listener has no handler for target database.\n";
                 exit 1;
               }
             } # end if $validout eq "DBVALID"

          } # end while
          $em_targetasminstance= $userinp;
          # ----------------------------------
        } elsif ( $input =~ /TARGET_DBNAME/ ) {
          # ----------------------------------
          # EM SRDC
          my $targetdb_notvalid = TRUE;
          my $validout = "";
          my $ohome    = "";
          while ( $targetdb_notvalid ) {
             print "$prompt [$defaultmsg for this SRDC] : ";
             $userinp = <>;
             chomp($userinp);
             if ( (not length $userinp) && $isoptional) {
               $targetdb_notvalid = FALSE;
               next;
             }
             if ( not exists $emtargets{$userinp} ) {
               print "$userinp is not a valid EM target name.\n";
               print "Valid target names: @emtargets\n";
               print "Please try again...\n";
               next;
             }

             ($validout,$ohome) = tfactlshare_validate_db($tfa_home,$userinp);
             if ($validout eq "DBVALID") {
               $targetdb_notvalid = FALSE;
             } else {
               if ( $validout eq "ORACLE_HOME NOT FOUND" ) {
                 print "ORACLE_HOME not found for target DB.\n";
                 print "Please specify a valid database.\n";
               } elsif ( $validout eq "LISTENER IS NOT RUNNING" ) {
                 print "Listener is not running.\n";
                 exit 1;
               } elsif ( $validout eq "LISTENER HAS NO HANDLER" ) {
                 print "Listener has no handler for target database.\n";
                 exit 1;
               }
             } # end if $validout eq "DBVALID"

          } # end while
          $em_targetdbname= $userinp;
        # --------------------------
        } elsif ( $input =~ /DEBUGON_RAN/ ) {
        # --------------------------
          my $isdebugon_opt;
          print "$prompt [Y|y|N|n] [Y]: ";
          print $srdc_log_fh "DIS: $prompt [Y|y|N|n] [Y]: \n";
          chomp( $isdebugon_opt = <STDIN> );
          print $srdc_log_fh "INP: isdebugon_opt $isdebugon_opt \n";
          $isdebugon_opt ||= "Y";
          $isdebugon_opt = get_valid_input ( $isdebugon_opt, "Y|y|N|n", "Y"); 
          exit if lc($isdebugon_opt) eq "n";
          ### print "opt isemrepodblocal_opt $isemrepodblocal_opt, isemrepodblocal $isemrepodblocal\n";
        # --------------------------
        } elsif ( $input =~ /REPODB_LOCAL/ ) {
        # --------------------------
          my $isemrepodblocal_opt;
          print "$prompt [Y|y|N|n] [Y]: ";
          print $srdc_log_fh "DIS: $prompt [Y|y|N|n] [Y]: \n";
          chomp( $isemrepodblocal_opt = <STDIN> );
          print $srdc_log_fh "INP: isemrepodblocal_opt $isemrepodblocal_opt \n";
          $isemrepodblocal_opt ||= "Y";
          $isemrepodblocal_opt = get_valid_input ( $isemrepodblocal_opt, "Y|y|N|n", "Y");
          $isemrepodblocal = TRUE if lc($isemrepodblocal_opt) eq "y";
          ### print "opt isemrepodblocal_opt $isemrepodblocal_opt, isemrepodblocal $isemrepodblocal\n";
          # ----------------------------------
        } elsif ( $input =~ /REPOSITORY_DBNAME/ ) {
          # ----------------------------------
          # EM SRDC
          my $repositorydb_notvalid = TRUE;
          my $validout    = "";
          my $ohomerep    = "";
          my $validremout = "";
          my $trying_remdata = FALSE;
          # If no OMS available then
          # this input is not optional
          if ( not length $EMOMSOHOME ) {
            $isoptional = FALSE;
            $defaultmsg = "Required"; 
          }
          while ( $repositorydb_notvalid ) {
             # not $trying_remdata
             if ( $isemrepodblocal ) {
               print "$prompt [$defaultmsg for this SRDC] : ";
               $userinp = <>;
               chomp($userinp);

               if ( (not length $userinp) && $isoptional ) {
                 $repositorydb_notvalid = FALSE;
                 next;
               }

               ($validout,$ohomerep) = tfactlshare_validate_db($tfa_home,$userinp) if length $userinp;

               if ($validout eq "DBVALID") {
                 $repositorydb_notvalid = FALSE;
               } elsif ( length $validout ) {
                 print "Repository DB was not found on the local node.\n";
                 print "Please try again.\n";
               } else {
                 print "Local Repository DB was not provided.\n";
                 print "Please try again.\n";
               } # end if $validout eq "DBVALID"
             } elsif ( not $isemrepodblocal ) {
               # Try repository DB in remote host
               $trying_remdata = TRUE;
               print "Enter host for the Repository Database : ";
               $em_hostrepodb = <>;
               chomp($em_hostrepodb);
               print "Enter the port for the Repository Database : ";
               $em_portrepodb = <>;
               chomp($em_portrepodb);
               print "Enter the service for the Repository Database : ";
               $em_servicerepodb = <>;
               chomp($em_servicerepodb);
               if ( not (length $em_hostrepodb && length $em_portrepodb && length $em_servicerepodb ) ) {
                 if ( $isoptional ) {
                   $repositorydb_notvalid = FALSE;
                   next;
                 } else {
                   print "Please provide all required information and try again.\n";
                 } # end if not (length $em_hostrepodb && ...
               } else {
               # host, port and service provided
                 $validremout = tfactlshare_validate_remdb($tfa_home,$em_targetdbname,$em_hostrepodb,$em_portrepodb,$em_servicerepodb);
                 if ( $validremout eq "VALIDREMDATA" ) {
                   $em_remdata = TRUE;
                   $repositorydb_notvalid = FALSE;
                 } else {
                   print "Invalid remote connection details.\n";
                   print "Returned error message: $validremout.\n";
                   print "Please try again ...\n";
                 } 
               } # end if not (length $em_hostrepodb && ...
             } # end if not $isemrepodblocal 
             # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
          } # end while

          if ( $em_remdata ) {
            $em_repositorydbname = $em_targetdbname;
            $userinp = $em_targetdbname;
          } else {
            $em_repositorydbname = $userinp;
          }
          $em_repositorydb_provided = TRUE;
          if ( length $ohomerep ) {
            my $repvfy = catfile($ohomerep,"emdiag","bin");
            $em_repositorydb_ohome = $ohomerep;
            if ( -e catfile($repvfy,"repvfy") ) {
              $em_repositorydb_repvfy = $repvfy;
            }
          }
          # ----------------------------------
        } elsif ( $input =~ /REPOSITORY_REPVFY/ ) {
          # ----------------------------------
          if ( length $em_repositorydb_repvfy ) {
            $userinp = $em_repositorydb_repvfy;
          } else {
            $userinp = "";
          }
          # ----------------------------------
        } elsif ( $input =~ /REPOSITORY_OHOME/ ) {
          # ----------------------------------
          if ( length $em_repositorydb_ohome ) {
            $userinp = $em_repositorydb_ohome;
          } else {
            $userinp = "";
          }
          # ----------------------------------
        } elsif ( $input =~ /REPOSITORY_TNS/ ) {
          # ----------------------------------
          my $validout;
          my $tns_notvalid = TRUE;

          while ( $tns_notvalid ) {
              print "$prompt [$defaultmsg for this SRDC] : ";
              $userinp = <>;
              chomp($userinp);

              if ( (not length $userinp) && $isoptional) {
                $tns_notvalid = FALSE;
                next;
              }

              # print "em_repositorydb_ohome $em_repositorydb_ohome userinp $userinp\n";
              $validout = tfactlshare_validate_tns($em_repositorydb_ohome,$userinp);
              # print "validout $validout\n";
              if ($validout eq "TNSVALID") {
                $tns_notvalid = FALSE;
              } else {
                if ( $validout eq "TNSINVALID" ) {
                  print "TNS Alias is not valid for the EM Repository DB.\n";
                  print "Please specify a valid TNS Alias.\n";
                }
              } # end if $validout eq "TNSVALID"
           } # end while

          if ( length $userinp ) {
            $em_repositorydb_tns = $userinp;
          } else {
            $em_repositorydb_tns = "";
          }

          # ----------------------------------
        } elsif ( $input =~ /ONERROR_VERIFY/ ) {
          # ----------------------------------
          # For each @events check if that event is valid.
          #print "events before:  @events\n";
          tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                              "in xmlfilters got passed ONERROR_VERIFY ",
                              'y', 'y');
          my @checkedevents;
          foreach my $vfyevent (@events) {
            tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                              "in xmlfilters ONERROR_VERIFY : Event : $vfyevent ",
                              'y', 'y');
            print "Is the failure related to " . $vfyevent . " Error " ;
            $userinp = tfactlshare_get_choice_yn("y","n",
                      "[y,n, default y]?", "y" );
            if ( lc($userinp) eq "y") {
                              tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                              "in xmlfilters ONERROR_VERIFY : Adding $vfyevent to checkedevents",
                              'y', 'y');
               push @checkedevents, $vfyevent;
            } 
          }
          @events = @checkedevents;
          #print "events after: @events\n";
          # ----------------------------------
        } elsif ( $input =~ /DATABASE_NAME/ ) {
          # ----------------------------------
          my $retselected = FALSE;
          if ( $database && $database ne "all" ) {
            my @dbentries = split /,/ , $database;
            if ( $#dbentries >= 1 ) {
              print "Only one database is allowed when using the -srdc switch.\n";
              exit;
            }
            tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                              "in xmlfilters got passed DATABASE_NAME from commandline : DATABASE_NAME : $database ",
                              'y', 'y');
            $userinp = $database;
          } else {
             my $dbnotvalid = TRUE;
             while ( $dbnotvalid ) {
               if ( @events ) {
                  print "$prompt [<RETURN>=ALL] : ";
               }
               else
               {
                  print "$prompt [Required for this SRDC] : ";
               }
               $userinp = <>;
               chomp($userinp);
               if ( length $userinp ) {
                 my $dbexists;
                 if ( $userinp =~ /\+\w+/ ){
                   $dbexists = (dbutil_setOraEnv($tfa_home, $userinp,"" ,FALSE ))[0];
                 } else {
                    $dbexists =  checkDbExistence($tfa_home, $userinp, $localhost);
                 }
                 if ( $dbexists ==  SUCCESS ) {
                   $dbnotvalid = FALSE;
                 } else {
                   print "Database $userinp does not exist, please try again.\n";
                 } # end if $dbexists == SUCCESS
               } else {
                 if ( @events ) {
                   $dbnotvalid = FALSE;
                   $retselected = TRUE;
                 }
               }
             } # end while
             $database = $userinp;
             tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                               "in xmlfilters input is DATABASE_NAME : $database ",
                               'y', 'y');
          }
          # For ora4031 check if db is running
          if ( ( lc($xmlfilters) eq "ora4031" || lc($xmlfilters) eq "dbperf" || lc($xmlfilters) =~ /emtbsmetric/ || lc($xmlfilters) eq "dbscn" || lc($validate) eq "dbrunning" ) &&
               (not $retselected) ) {
               
            tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                               "validate if database ->  $database  is running ",
                               'y', 'y');

            $isrunning = "";
            if ( ! $IS_WINDOWS ) {
              #$isrunning = `ps -ef | grep -i pmon_$database | grep -v grep`; # Need to make this more reliable.
              #Check if database is running;
              my $exists;
              ($exists,%dbenv) = dbutil_setOraEnv($tfa_home, $database, "", FALSE );
              $isrunning = $dbenv{"TFA_RUNNING_LOCAL"};
            } else {
              my $osid = "";
              my $running_local = 0;
              my $db_running    = 0;
              ($osid,$db_running,$running_local) = dbutil_iswindbrunning($database);
              $isrunning = "running" if $db_running; 
            } # end if ! $IS_WINDOWS
            if ( not length $isrunning ) {
              print "Warning: database $database is not running on the node, Database reports will not be generated.\n";
              $warndbdown = TRUE;
            } else {
              tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                               " DATABASE_NAME : $database is running",
                               'y', 'y');
              #print "DB is running $database.\n";
            } 
          } # end if lc($xmlfilters) eq "ora4031" ...
          elsif ( lc($xmlfilters) eq "dbshutdown" || lc($xmlfilters) eq "dbstartup" ) {
            #Determine whether most recent shutdown or startup is complete or not
            my $type = lc($xmlfilters) eq "dbshutdown" ? "shutdown" : "startup";
            my @data = dbutil_lastShutdownStartups( $database, $type ,$tfa_home );
            $dbadmindata{"data"} = \@data if ( @data );
            $dbadmindata{"alertlog"} = dbutil_get_alert_log($tfa_home,$database);
            if ( $dbadmindata{"alertlog"} =~ /Error/ ){
               print $dbadmindata{"alertlog"}."Exiting....\n";
               exit (1);
            }
            if ( $dbadmindata{"data"} ) {
                my @shutdowns = @{$dbadmindata{"data"}};
                my $start;
                my $problem = scalar(@shutdowns);
                my $ref = @shutdowns[scalar(@shutdowns)-1];#Get the last shutdown or startup
                my %hash = %$ref;
                my @matches;
                if ( ! $IS_WINDOWS ){
                  @matches= `$GREP -n \"$hash{"date"}\" $dbadmindata{"alertlog"}`;
                  @matches= `$GREP -n \"$hash{"date2"}\" $dbadmindata{"alertlog"}` if ( ! @matches);
                } else {
                  @matches = `findstr /NIRC:"$hash{"date"}" $dbadmindata{"alertlog"}`;
                  @matches = `findstr /NIRC:"$hash{"date2"}" $dbadmindata{"alertlog"}` if ( ! @matches);;
                }
               #This should never happen unless the alert_log we are looking at is not the right one
               #or we have a different timestamp in the alert_log and is not being considered. 
               if (! @matches ){
                 print "Not maching events found in the alert log\n";
                 exit(1);
               }
                $start = $matches[0];
                chomp($start);
                $start =~ s/(.*?)\:.*/$1/;
                #Check if shutdown or startup is completed! 
                my $complete;
                if ( ! $IS_WINDOWS ){
                  if ( $type eq "shutdown" ){
                    $complete = `sed -n '$start,\$p' $dbadmindata{"alertlog"} | grep -ni "Instance shutdown complete"`;
                  } else {
                    $complete = `sed -n '$start,\$p' $dbadmindata{"alertlog"} | grep -ni "Completed: ALTER DATABASE OPEN"`;
                  }
                } else {

                  if ( $type eq "shutdown" ) {
                    $complete = `more +$start $dbadmindata{"alertlog"} | findstr /NRIC:"Instance shutdown complete"`;
                  } else {
                    $complete = `more +$start $dbadmindata{"alertlog"} | findstr /NRIC:"Completed: ALTER DATABASE OPEN"`;
                  }
                }
                chomp($complete);
                # $complete = "0";
                if ($complete ) {
                  print "Instance shutdown was completed in the very last shutdown\n" if ( $type eq "shutdown" );
                  print "Instance startup was completed in the very last startup\n" if( $type eq "startup" );
                  $dbadmindata{"completed"} = 1;
                  my $validInput = FALSE;
                  while ( ! $validInput ) {
                    my $indx = 1;
                    foreach my $stdwn (@shutdowns) {
                      my %hash = %$stdwn;
                      print "[ $indx ]". $hash{"date2"} . "\n";
                      $indx++;
                    }
                    print "Please choose the problematic $type [1..".scalar(@shutdowns)."] [$problem] : ";
                    my $opt = <STDIN>;
                    chomp($opt);
                    $opt ||= $problem;
                    $opt-=1;
                    if ($opt < 0  || $opt > ($problem-1)){
                      print "Not a valid option, please try again..\n";
                    } else { 
                      $validInput = TRUE;
                      $ref = @shutdowns[$opt];
                    } #end if valid input
                  }#end while validInput
                  #Process the chunk of the shutdown to search for messages. 
                  #-------------------------------------------------------
                  %hash = %$ref;
                  if ( ! $IS_WINDOWS ) {
                    @matches  = `$GREP -n \"$hash{"date"}\" $dbadmindata{"alertlog"}`;
                    @matches  = `$GREP -n \"$hash{"date2"}\" $dbadmindata{"alertlog"}` if ( ! @matches);
                  } else {
                    @matches = `findstr /RINC:\"$hash{"date"}\" $dbadmindata{"alertlog"}`;
                    @matches = `findstr /RINC:\"$hash{"date2"}\" $dbadmindata{"alertlog"}` if ( ! @matches);
                  }
                  #This should never happen unless the alert_log we are looking at is not the right one
                  #or we have a different timestamp in the alert_log and is not being considered. 
                  if ( ! @matches ){
                    print "Not maching events found in the alert log\n";
                    exit(1);
                  }
                  $start = $matches[0];
                  chomp($start);
                  $start =~ s/(.*?)\:.*/$1/;
                  my @lines;
                  if ( ! $IS_WINDOWS ){
                    @lines = `sed -n '$start,/Completed: ALTER DATABASE OPEN/p' $dbadmindata{"alertlog"}` if( $type eq "startup");
                    @lines = `sed -n '$start,/Instance shutdown complete/p' $dbadmindata{"alertlog"}` if ( $type eq "shutdown" );
                  } else { 
                    my $pattern; 
                    $pattern = "Completed: ALTER DATABASE OPEN" if ( $type eq "startup" );
                    $pattern = "Instance shutdown complete" if ( $type eq "shutdown" );
                    my $count = 1; 
                    open ( FILE, "<", $dbadmindata{"alertlog"} );
                    while ( <FILE> ) {
                      if ( $count >= $start ) {
                        push @lines,$_;
                        if ( $_ =~ /$pattern/i ){
                          last;
                        }
                      }
                      $count++;
                    }
                    close(FILE);

                  }
                  
                  my @ora_errors = grep { /ORA\-\d+/i } @lines;
                  my @recovery_errors = grep { /tx recovery/i } @lines;
                  my @processes_preventing;
                  push @processes_preventing, grep { /Active process \d+ \'\w+\' program .*/i } @lines;
                  push @processes_preventing, grep { /SHUTDOWN: waiting for logins to complete/i } @lines;
                  push @processes_preventing, grep { /SHUTDOWN: waiting for active calls to complete/i }@lines;
                  push @processes_preventing, grep { /ACTIVE PROCESSES PREVENT SHUTDOWN OPERATION/i } @lines;
                  push @processes_preventing, grep { /SHUTDOWN: waiting for detached processes \'.*\' to terminate/i } @lines;
                  open ( my $fh, '>', $hostname."_".$type."_errors_messages.out");
                  if ( @recovery_errors ) {
                    print $fh "===============RECOVERY ERRORS==================\n";
                    foreach (@recovery_errors){
                      print $fh $_."\n";
                    }
                  }
                  if ( @processes_preventing ) {
                    print $fh "===============ACTIVE PROCESSES PREVENTING SHUTDOWN==================\n";
                    foreach (@processes_preventing){
                      print $fh $_."\n";
                    }

                  }
                  if ( @ora_errors ) {
                    print $fh "===============ORA ERRORS==================\n";
                    foreach (@ora_errors){
                      print $fh $_."\n";
                    }
                  }
                  @ora_errors = grep{ s/.*ORA\-(\d+).*/$1/g } @ora_errors;
                  @ora_errors = grep{ s/\s+//g } @ora_errors;
                  my %seen;
                  @ora_errors = grep{ !$seen{$_}++}@ora_errors;
                  $dbadmindata{"ora_errors"}=\@ora_errors;
                  close($fh);
                  #---------------------------------------------------------------------
                } else {
                  #Shutdown  or startup is not completed it means issue is happening at that moment!
                  $dbadmindata{"compleated"} = 0;
                  my @lines;
                  if( ! $IS_WINDOWS ){
                    @lines = `sed -n '$start,\$p' $dbadmindata{"alertlog"}`;
                  } else {
                    @lines = `\@echo off & for /F "delims=" %i IN ('more +$start $dbadmindata{"alertlog"}') do echo( %i )`;
                    `\@echo on`;
                  }
                  my @ora_errors = grep { /ORA\-\d+/i } @lines;
                  my @recovery_errors = grep { /tx recovery/i } @lines; 
                  my @processes_preventing;
                  push @processes_preventing ,grep { /Active process \d+ \'\w+\' program .*/i } @lines;
                  push @processes_preventing, grep { /SHUTDOWN: waiting for logins to complete/i } @lines;
                  push @processes_preventing, grep { /SHUTDOWN: waiting for active calls to complete/i }@lines;
                  push @processes_preventing, grep { /ACTIVE PROCESSES PREVENT SHUTDOWN OPERATION/i } @lines;
                  push @processes_preventing, grep { /SHUTDOWN: waiting for detached processes \'.*\' to terminate/i } @lines;
                  open ( my $fh, '>', $hostname."_".$type."_errors_messages.out");
                    if ( @recovery_errors ) {
                      print $fh "===============RECOVERY ERRORS==================\n";
                      foreach (@recovery_errors){
                        print $fh $_."\n";
                      }
                    }
                    if ( @processes_preventing ) {
                      print $fh "===============ACTIVE PROCESSES PREVENTING SHUTDOWN==================\n";
                      foreach (@processes_preventing){
                        print $fh $_."\n";
                      }

                    }
                    if ( @ora_errors ) {
                      print $fh "===============ORA ERRORS==================\n";
                      foreach (@ora_errors){
                        print $fh $_."\n";
                      }
                    }
                    @ora_errors = grep{ s/.*ORA\-(\d+).*/$1/g } @ora_errors;
                    @ora_errors = grep{ s/\s+//g } @ora_errors;
                    my %seen;
                    @ora_errors = grep{ !$seen{$_}++}@ora_errors;
                    $dbadmindata{"ora_errors"}=\@ora_errors;
                    close($fh);
                } #end instance shutdown or startup complete 
                
              } else {
                print "No shutdowns found for database $database \n" if ($type eq "shutdown");
                print "No startups found for database $database \n" if ($type eq "startup");
                print "Exiting...\n";
                exit(0);
              }
          
        }
      #-------------------------------    
      } elsif ( $input =~ /INVLOC/ ) { # need inventory location - we can determien this.
        print $srdc_log_fh "INP: INVLOC determining inventory Location \n";
        $userinp =  tfactlshare_getorainvloc();      
        chomp($userinp);
        print $srdc_log_fh "INP: Determined inventory Location $userinp  : \n";
      #--------------------------------
      } elsif ( $input =~ /SID_NAME/ ) {
      # TODO check if this is used anywhere or wanted. Supports input via file. 
      } elsif ( -f $input )
      {
        $userinp = File::Spec->rel2abs( $userinp );
      } else {
        # -------------------------------
        # DYNAMIC INPUTS FOR SRDC
        # -------------------------------
        # We get here as this is just an effectively dynamic input which will be just to set a variable used in a script.
        ### print "Dynamic inpusts, input $input \n";
        $userinp="";
        $isvalidinput=FALSE;
        while (not $isvalidinput) {
             if ( lc($validate) ne "yn" ) {
               if ( $cmdline and $cmdlineoptsvals{$cmdline} ) {
                 tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                 "Using cmdline user input: $cmdline value: " . $cmdlineoptsvals{$cmdline} ,'y','y');
                 print $srdc_log_fh "Using cmdline user input: $cmdline value: " . $cmdlineoptsvals{$cmdline} . "\n";
                 $userinp = $cmdlineoptsvals{$cmdline};
               } else {
                 if ( $showprompt eq "0" && $default ) {
                   $userinp = $default;
                 } else {
                   print "$prompt [$defaultmsg for this SRDC]: ";
                   print $srdc_log_fh "DIS: $prompt [$defaultmsg for this SRDC] : \n";
                   chomp( $userinp = <STDIN> );
                   $userinp||= $default if ($default); #If we have a default value and user hit nothing get default value.
                 }
               }
               print $srdc_log_fh "INP: $userinp  : \n";
             } else {
               print "$prompt";
               $userinp = tfactlshare_get_choice_yn("y","n",
                          "Do you want to continue [y,n, default y]?", "y" );
             }
             if ( length $userinp ) {
		   $validate = "multiword" if ( length $validate == 0 );
                   if ( $validate eq "sqlid" ) {
                     $isvalidinput = tfactldiagcollect_validate_input($validate,$userinp,$database);
                   } else {
                     $isvalidinput = tfactldiagcollect_validate_input($validate,$userinp);
                   }
                   if ( $cmdline && (not $isvalidinput) ) {
                     print "The value: $userinp is not valid for cmdline user input $input.\n";
                     $exitcode = 1;
                     last dscriptoptions;
                   }
             } 
             if ( length $userinp == 0 and lc($defaultmsg) eq "required" )  {
               print "The value: $userinp is not valid for $input.\n";
             } elsif ( length $userinp == 0 and lc($defaultmsg) eq "optional" ) {
               print "You have not entered a value for $input. Any collections requiring this value will fail.\n";
               $isvalidinput = TRUE;
             }
        } # end while
      }
      #
      # Include user inputs in $xmlfilters_fp ($userinp) - write it to the next line in the file.
      # 
      # srdc sec
      # don't record any passwords in xmlfilters_fp
      # -------------------------------------------
      if ( $input !~ /_PWD/i ) {
        $userinp =~ s/\\/\\\\/g;
        $userinp =~ s/\//\\\//g;
        $userinp =~ s/\=/\\\=/g;
        $userinp =~ s/\$/\\\\\$/g if ( $userinp =~ /\w+\$$/ );
        
        system("$PERL -p -i.orig -e \"s/-$input:?/-$input=$userinp/\" $xmlfilters_fp") if length $userinp;
        #Restore actual input for dependency check.
        $userinp =~ s/\\\//\//g;
        $userinp =~ s/\\/\\\\/g;
        $userinp =~ s/\\\\\$/\$/g;
        $userinp =~ s/\\\=/\=/g;

        # Save the inputs in case they are needed for dependent prompts
        $savedinputs{$input} = $userinp;
      }
  } # End - foreach my $input ( keys %xmlfilterinputs)
  print $srdc_log_fh "ARG: DSCIPT_OPTS(3) $DSCRIPT_OPTS \n";

  # ---------------------
  # Need to check if there are required snapshots etc for dbperf.
  # For dbperf ensure DB is up and that snapshots exist for the good and bad timestamps.

  if ( $database and $from and $to ) { 
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
    "in xmlfilters check db and snaps for :" . lc($xmlfilters) . ": db $database, from $from, to $to",
    'y', 'y');
  } else { 
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
    "in xmlfilters check db and snaps - Null setting for DB, from, to",'y', 'y');
  }
  my $snapcount=0;
  if ( lc($xmlfilters) eq "dbperf" || lc($xmlfilters) eq "dbscn" ) {
      if ( not length $isrunning ) {
         print "Error: database $database is not running, Cannot Run SRDC Collection\n";
         exit; 
      }
      if ( $licenseflag ) {
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                          "in xmlfilters about to call bad tfactlshare_awrsnaps tfahome $tfa_home, count, db $database, from $starttime, to $endtime",
                          'y', 'y');
        $snapcount = tfactlshare_awrsnaps($tfa_home,"count",$database,$starttime,$endtime);
        print "Found $snapcount snapshot(s) for Bad Performance time range in  $database \n";
        if ( ! $snapcount ) {
          print "Error: No snapshots exist for Bad Performance time range in database $database, Please select a time AWR snapshots exist for the Bad Performance time range. \n";
          #exit;Continue with the collection to gather other stuff 
        }
        if ( $starttimegood && $endtimegood){
          tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                          "in xmlfilters about to call good tfactlshare_awrsnaps tfahome $tfa_home, count, db $database, from $starttimegood, to $endtimegood",
                          'y', 'y');
          $snapcount = tfactlshare_awrsnaps($tfa_home,"count",$database,$starttimegood,$endtimegood);
          print "Found $snapcount snapshot(s) for baseline range in  $database \n";
        }
        # Get all the snapshots info
        my $snap_file = catfile($srdcdir,"tfa_" . $xmlfilters_tag . "all_snapshots");
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                          "in xmlfilters about to call allsnaps tfactlshare_awrsnaps db $database output $snap_file",
                          'y', 'y');
        my @allsnaps = tfactlshare_awrsnaps($tfa_home,"listall",$database);
        open (OUTF, "> $snap_file");
        foreach my $snapline (@allsnaps) {
          print OUTF "$snapline\n";
        }
        close(OUTF);
        if (  ! $snapcount && $starttimegood) {
          print "Error: No snapshots exist for baseline time range in database $database, Please select a time AWR snapshots exist for the baseline (Good) Performance time range. \n";
          #exit; Continue with execution 
        }
        print "\"Automatic Workload Repository (AWR) is a licensed feature.Refer to My Oracle Support Document ID 1490798.1 for more information\"\n";

    } elsif ( not tfactlshare_is_statspack_installed($tfa_home,$database) ) {
      print "Statspack is not installed. Unable to generate statspack report\n";
      print "\"It is recommended to provide AWR reports. In case, you don't have a license, then install and enable Statspack using Document 1931103.1\"\n";
    }

  } # end if ( lc($xmlfilters) eq "dbperf" ) 

  # Get duration from xml if it is not in the command line 
  if ( not $duration ) {
    my $lduration = (tfactlshare_look4regex($xmlfilters_orig,".*<duration>([0-9]*[HhMmDd])<.duration>.*"))[0];
    if ( length $lduration ) {
      $duration = $lduration;
    } 
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
              "in xmlfilters get duration from xml duration $duration lduration $lduration: DSCIPT_OPTS: $DSCRIPT_OPTS \n",
              'y', 'y');
  } # end if not $duration

    # If we have had user input for times then we do not need to use events.
    # However we need to check if there are required events in the timeframe if the is onerror.
    # We must always have had a database supplied .. Not doing this for all databases...
 
    # my $event_time;
    my $event_key="";
    if ( not $event_time ) {

    if ( not @events ) {  # Some srdc's do no have events                                                                                    
       tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .                                                         
                    "in xmlfilters before get_event_time : No events to check for this SRDC",                                                
                    'y', 'y');                                                                                                               
       if (( !($since||$for||$from||$to)) && $xmlfilters && length $duration) {
          $DSCRIPT_OPTS .= " -since $duration";
          $since = $duration;
          $DSCRIPT_OPTS =~ s/ -duration $duration//;
          print $srdc_log_fh "ARG: DSCIPT_OPTS(3) $DSCRIPT_OPTS \n";
          tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                    "in xmlfilters No Events adding -since using duration $duration DSCIPT_OPTS: $DSCRIPT_OPTS \n",
                    'y', 'y');
       }
    }                                                                                                                                   
    else 
    {      
       tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                    "in xmlfilters before get_event_time events:@events database:$database excludeevents @excludeevents",
                    'y', 'y');

       my ($pfor, $pfrom, $pto, $psince);
       $pfor   = $for;
       $pfrom  = $from;
       $pto    = $to;
       $psince = $since;
       my @events2list;
       my ($firstevent, $lastevent);
       # -----------------------------------------------------
       # Check if the event exists in the the period or error.
       # -srdc switch in use & using ( since/for/from/to)
       # -----------------------------------------------------
       if ( ($since||$for||$from||$to) && $xmlfilters ) {
   
           tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .

                    "in xmlfilters (input srdc01) passed for:$for from:$from to:$to since:$since: Checking for @events ",
                    'y', 'y');
           tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                    "in xmlfilters (input srdc01) passed for:$for from:$from to:$to since:$since: Excluding for @excludeevents ",
                    'y', 'y');
   
           ($firstevent, $lastevent, @events2list) = tfactldiagcollect_get_event_time($tfa_home, \@events, $database, TRUE, \@excludeevents);
   
           ($from, $to, $for, $since, $duration, $event_time, $event_key) = tfactldiagcollect_validate_event($firstevent, $lastevent, $from, $to, $for, $since, $duration, \@events, $database, \@events2list);
   
           ($DSCRIPT_OPTS) = tfactldiagcollect_validate_prevcurr($pfor,$for,$pfrom,$from,$pto,$to,$psince,$since,$DSCRIPT_OPTS);
   
           tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                    "in xmlfilters (output srdc01) DSCRIPT_OPTS $DSCRIPT_OPTS", 'y', 'y');
           tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                             ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>",'y', 'y');
       } else {
          # ------------------------------------
          # -srdc switch in use, look for events
          # no since/for/to/from
          # ------------------------------------
   
          # TODO USe adrci to get events for database
          ($event_time, $event_key) = tfactldiagcollect_get_event_time($tfa_home, \@events, $database, FALSE, \@excludeevents);
   
          if ( $event_time )
          {
            if ( length $duration ) {
              my $starttime;
              my $endtime;
              ($starttime, $endtime) = tfactldiagcollect_getrange_for_event($event_time, $duration );
   
              $DSCRIPT_OPTS .= " -from $starttime -to $endtime";
              $DSCRIPT_OPTS =~ s/ -duration $duration//;
              $from = $starttime;
              $to   = $endtime; 
            } else {
              if ( $DSCRIPT_OPTS !~ /\-for $for/ ) { # Not already in $DSCRIPT_OPTS
               $for = $event_time;
               $DSCRIPT_OPTS .= " -for $for";
              }
            }
               tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "in xmlfilters after chosen event time $event_time : DSCRIPT_OPTS:$DSCRIPT_OPTS ",
                         'y', 'y');
          } # end if $event_time
       } # end if ($since||$for||$from||$to) && $xmlfilters
    } # End Some srdc's do no have events
  }
    # reset event time if not already set.
    if ( $event_time ) {
      system("$PERL -p -i.orig -e \"s|USERINPUT-EVENT_TIME|\nEVENT_TIME=$event_time\n|\" $xmlfilters_fp");
    }

    # --------------------------------------------------


    my $selected_db;
    if  ($database)
    {
       $selected_db = $database ;             #In case of ASM event key is db..+ASM...
    } elsif ( $event_key =~ /^db\.(\w+)\./ || $event_key =~/^db\.\.(\+\w+)\./ ) {
      $selected_db = $1;
      $database = $selected_db;
    }
    
    # For ora4031 check if db is running
    #print "database $database\n";
    if ( (not $IS_WINDOWS) && (lc($xmlfilters) eq "ora4031") &&
    (not $warndbdown) ) {
      #$isrunning = `ps -ef | grep -i pmon_$database | grep -v grep`;
      my $exists;
      ($exists,%dbenv ) = dbutil_setOraEnv($tfa_home, $database,"" ,FALSE );
      $isrunning = $dbenv{"TFA_RUNNING_LOCAL"};
       if ( not length $isrunning ) {
         print "Warning: database $database is not running, RDA report will not be generated.\n";
       } else {
         #print "DB is running $database.\n";
       }
    }
    #Show what scripts will be run 
    # print "$scriptsmsg\n";

    if ( $database =~ /\+(\w+)/ ){
      @comps = grep { $_ !~ /DATABASE/i}@comps;
      if ( $database =~ /\+ASM/ ) { 
        push  @comps, "ASM";
      } elsif ( $database =~ /\+APX/ ) {
        push  @comps, "ASMPROXY";
      } elsif ( $database =~ /\+IOS/ ) {
        push  @comps, "ASMIO";
      }
    }

    # Components included in srdc
    #print "Components included in this srdc: @comps\n";
    if ( lc($xmlfilters) =~ /emdebugon/ ) {
      print "Once this SRDC is completed please reproduce the issue and run the emdebugoff srdc" .
            " to turn off the debug and collect the relevant debug log files.\n";
    }

    foreach my $comp (@comps)
    {
      $comp = lc($comp);
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "in xmlfilters loop components : component $comp",
                        'y', 'y');

      if ( $comp eq "database" )
      {
        if ( $DSCRIPT_OPTS !~ /\-$comp\s+$selected_db/ ) { # Not already in $DSCRIPT_OPTS
          $DSCRIPT_OPTS .= " -$comp $selected_db";
        }
      }
       elsif ( $comp eq "nochmos" ) 
      { 
        $nochmos = 1;
        if ( $DSCRIPT_OPTS =~ /\-chmos/ ) {
           $DSCRIPT_OPTS =~ s/\-chmos/\-nochmos/; 
        }
      }
       else
      {
        if ( $DSCRIPT_OPTS !~ /\-$comp/ ) { # Not already in $DSCRIPT_OPTS
          $DSCRIPT_OPTS .= " -$comp";
        }
      }
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "in xmlfilters loop components : DSCRIPT_OPTS $DSCRIPT_OPTS",
                        'y', 'y');
    }

    # we need to gather environment information for the calling user and make avialable for collection.
    if ($current_user ne "root") {
       tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "in xmlfilters gether non root user env : user : $current_user",
                        'y', 'y');

       open my $EF, ">", $env_file || die "Cant open ".$env_file."\n";

       tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "in xmlfilters OPENED : $env_file",
                        'y', 'y');

       print $EF "Environment Information for user $current_user\n";
       print $EF "====================================================\n\n";
       # windows todo
       my $command = "sh -c \"ulimit -a\"";
       print $EF "User Limits : \n";
       print $EF "Command : $command : \n\n";
       my @lines = split(/\n/, `$command`);
       tfactlshare_write_array_to_open_file($EF,\@lines);
       print $EF "\n\n";
       $command = "env";
       print $EF "User Environment variables : \n";
       print $EF "Command : $command : \n\n";
       @lines = split(/\n/, `$command`);
       tfactlshare_write_array_to_open_file($EF,\@lines);
       close(EF);
    }

    if ( lc($cluster_flag) =~ /yes/ ) {
    # Copy updated file to remote nodes
     tfactldiagcollect_cp_xmlfilters_to_nodes($tfa_home, $xmlfilters_orig, $xmlfilters_tag, $xmlfilters_fp);
    } # end if lc($cluster_flag) =~ /yes/
    
    print $srdc_log_fh "ARG: DSCIPT_OPTS(4) $DSCRIPT_OPTS \n";

    # At this time the XML filters file has been processed for use across nodes.
    # Any Local script processing should happen here as the calling user.
   
    my @scr = ();
    my $scrname = "";
    my $scrtype = "";
    my $scrtimeout = 120;
    my $script_platform;
    my $validfor = "";
    my $in_user_input = 0;
    my $script_version;
    my $defaultval;
    my $showprompt;
    my $setenv;
    my %scriptenvs;
    my %scriptreplace;
    my %scriptwipe;
    my @dbusers;
    my $dbversion;
    my $inputorahome_dbv;
    my @oscp_files;
    my @emsql_scripts_params;
    my %emsql_scripts;
    my $command;
    my $cmdout;

    # ==============
    # parse srdcfile
    # ==============
    my $collection_id_fp;
    my %srdc_fp = ();
    my $user_inputs_content;
    my @userinputsarray_fp;
    ($collection_id_fp,%srdc_fp) = tfactlshare_parse_srdcfile($xmlfilters_fp);
    @userinputsarray_fp = @{$srdc_fp{$collection_id_fp}->{user_inputs_array}} if ( $srdc_fp{$collection_id_fp}->{user_inputs_array} );

    foreach my $keyinput ( @userinputsarray_fp ) {
      ### print "key % srdc_fp $keyinput\n";

     #  my %hashattribs = %{%{$srdc_fp{$collection_id_fp}->{user_inputs}}{$keyinput}};

      my $inputhashref = $srdc_fp{$collection_id_fp}->{user_inputs};
      my %inputhash = %$inputhashref;
      my $hashattribsref = $inputhash{$keyinput};
      my %hashattribs = %$hashattribsref;

      $in_user_input = 1;
      $defaultval = $hashattribs{"default"};    # $2;
      $showprompt = $hashattribs{"showprompt"}; # $3;
      $setenv     = $hashattribs{"setenv"};     # $4;
      $user_inputs_content = $hashattribs{"content"};
     
      print $srdc_log_fh localtime(time) . " : Reading user inputs default:$defaultval showprompt:$showprompt " .
            "setenv:$setenv user_inputs_content:$user_inputs_content\n";
      ### print " : Reading user inputs default:$defaultval showprompt:$showprompt " .
      ###       "setenv:$setenv user_inputs_content:$user_inputs_content\n";


      # ------------- $user_inputs_content ---------------  >>>>>>>>>>>>>

      # True input name, remove USERINPUT- prefix
      $user_inputs_content =~ s/USERINPUT-//g;

      if ( $user_inputs_content =~ /(.*?)=(.*)/ )
      {
        my $evar = $1;
        chomp($evar);
        my $evarval = $2;
        chomp($evarval);
        print $srdc_log_fh localtime(time) . " : Read Line : Key/Var $evar : Value $evarval\n" if (! $evar =~ /_PWD/);
        if ( $evar =~ /[\$\;\&\`\(\)]/ || $evar =~ /[\$\;\&\`\(\)]/ ) {
          print $srdc_log_fh localtime(time) . " Invalid characters in XML file \n";
          return(1);
        }
        if ( $setenv eq "YES" )
        {
           print $srdc_log_fh localtime(time) . "Added $evar with value $evarval to scriptenvs\n" if (! $evar =~ /_PWD/);
           $scriptenvs{$evar} = $evarval;
        }
        if ( $setenv eq "REPLACE" )
        {
           print $srdc_log_fh localtime(time) . "Added $evar with value $evarval to scriptreplace\n" if (! $evar =~ /_PWD/);
           ### print localtime(time) . "Added $evar with value $evarval to scriptreplace\n" if (! $evar =~ /_PWD/); 

           $scriptreplace{$evar} = $evarval;
           # EM SRDC PARAMS
           $EMREPOSITORYREPVFY = $evarval if uc($evar) eq "REPOSITORY_REPVFY";
           $EMREPOSITORYTNS    = $evarval if uc($evar) eq "REPOSITORY_TNS";
           $EMREPOSITORYOHOME  = $evarval if uc($evar) eq "REPOSITORY_OHOME";
           if ( $evar eq "UPGVERS" ) { #special case to have the first 3 characters of UPG Version
             my $utlver = substr($evarval,0,3);
             $scriptreplace{"UTLVERS"} = $utlver;
           print $srdc_log_fh localtime(time) . "Added UTLVERS with value $utlver to scriptreplace\n" if (! $evar =~ /_PWD/);
           }
        }
        if ( $evar =~ /TARGET_ASMINSTANCE/ )
        {
          $EMTARGETASMINSTANCE = $evarval;
        }
        elsif ( $evar =~ /TARGET_DBNAME/ )
        {
          $EMTARGETDBNAME = $evarval;
          if ( length $database ) {
            $database .= "," . $EMTARGETDBNAME;
          } else {
            $database = $EMTARGETDBNAME;
          }
        }
        elsif ( $evar =~ /REPOSITORY_DBNAME/ )
        {
          $EMREPOSITORYDBNAME = $evarval;
          if ( length $database ) {
            $database .= "," . $EMREPOSITORYDBNAME;
          } else {
            $database = $EMREPOSITORYDBNAME;
          }
        }
        elsif ( $evar =~ /ORACLE_HOME/ )
        {
          print $srdc_log_fh localtime(time) . "check dir : $evarval\n";
          if ( ! -d $evarval ) {
            print $srdc_log_fh localtime(time) . " Invalid ORACLE_HOME :$evarval: passed - Exitting\n";
            return(1);
          }
          $ENV{"ORACLE_HOME"} = $evarval;
          #my $filename = "$evarval/bin/oracle";
          #my $sqlplus = catfile($ENV{"ORACLE_HOME"}, "bin", "sqlplus");
          #my $cmd = "$sqlplus -v";
          #my @out = runtimedcommand($cmd,10,TRUE);
          #foreach my $line(@out)
          #{
          #  print $srdc_log_fh localtime(time) . "from out array : $line\n";
          #   if ( $line =~ /Release ([\d\.]+) / )
          #   {
          #      $inputorahome_dbv = $1;
          #   }
          #}
        }
        elsif ( $evar =~ /EVENT_TIME/ ) {
          $event_time = $evarval;
          chomp($event_time);
          print $srdc_log_fh localtime(time) . " Extracted event time $event_time from xml\n";
        }
        elsif ( $evar =~ /EVENT_BASELINE_START_TIME/ ) {
          $baselinefrom = $evarval;
          chomp($baselinefrom);
          print $srdc_log_fh localtime(time) . " Extracted baseline start time $baselinefrom from xml\n";
        }
        elsif ( $evar =~ /EVENT_BASELINE_END_TIME/ ) {
          $baselineto = $evarval;
          chomp($baselineto);
          print $srdc_log_fh localtime(time) . " Extracted baseline start time $baselineto from xml\n";
        }
      } # end if $user_inputs_content =~ /(.*)=(.*)/ )
      # ------------- $user_inputs_content ---------------  <<<<<<<<<<<<
    } # end foreach $keyinput


    # Paths adjustment
    $EMAGENTOHOME =~ s/\//\\\//g;
    $EMAGENTIHOME =~ s/\//\\\//g;
    $EMOMSOHOME   =~ s/\//\\\//g;
    $EMREPOSITORYREPVFY =~ s/\//\\\//g;
    $EMREPOSITORYOHOME  =~ s/\//\\\//g;

    $EMSYSMANPWD =~ s/\//\\\//g;
    $EMSYSMANPWD =~ s/\:/\\\:/g;
    $EMDBSNMPPWD =~ s/\//\\\//g;
    $EMDBSNMPPWD =~ s/\:/\\\:/g;

    my $lsysmanpwd = length $EMSYSMANPWD;
    my $ldbsnmppwd = length $EMDBSNMPPWD;
    my $astsysman = "*" x $lsysmanpwd;
    my $astdbsnmp = "*" x $ldbsnmppwd;

    # Add EM SRDC replacements 
    $scriptreplace{"EMAGENTOHOME"} = $EMAGENTOHOME if $EMAGENTOHOME;
    $scriptreplace{"EMAGENTIHOME"} = $EMAGENTIHOME if $EMAGENTIHOME;
    $scriptreplace{"EMHOSTNAME"}   = uc($localhost);
    $scriptreplace{"EMOMSOHOME"} = $EMOMSOHOME if $EMOMSOHOME;
    $scriptreplace{"EMTARGETDBNAME"}      = $EMTARGETDBNAME if $EMTARGETDBNAME;
    $scriptreplace{"EMTARGETASMINSTANCE"} = $EMTARGETASMINSTANCE if $EMTARGETASMINSTANCE;
    $scriptreplace{"EMREPOSITORYDBNAME"}  = $EMREPOSITORYDBNAME if $EMREPOSITORYDBNAME;
    $scriptreplace{"REPOSITORY_REPVFY"}   = $EMREPOSITORYREPVFY if $EMREPOSITORYREPVFY;
    $scriptreplace{"REPOSITORY_TNS"}      = $EMREPOSITORYTNS if $EMREPOSITORYTNS;
    $scriptreplace{"REPOSITORY_OHOME"}    = $EMREPOSITORYOHOME if $EMREPOSITORYOHOME; 
    $scriptreplace{"SYSMAN_PWD"}          = $EMSYSMANPWD if $EMSYSMANPWD;
    $scriptreplace{"DBSNMP_PWD"}          = $EMDBSNMPPWD if $EMDBSNMPPWD;

    print $srdc_log_fh localtime(time) . " : EM node type - EMAGENTOHOME=$EMAGENTOHOME\n";
    print $srdc_log_fh localtime(time) . " : EM node type - EMAGENTIHOME=$EMAGENTIHOME\n";
    print $srdc_log_fh localtime(time) . " : EM node type - EMOMSOHOME  =$EMOMSOHOME\n";

    print $srdc_log_fh localtime(time) . " : EMTARGETDBNAME $EMTARGETDBNAME\n";
    print $srdc_log_fh localtime(time) . " : EMTARGETASMINSTANCE $EMTARGETASMINSTANCE\n";

    print $srdc_log_fh localtime(time) . " : EMREPOSITORYDBNAME $EMREPOSITORYDBNAME\n";
    print $srdc_log_fh localtime(time) . " : EMREPOSITORYREPVFY $EMREPOSITORYREPVFY\n";
    print $srdc_log_fh localtime(time) . " : EMREPOSITORYTNS    $EMREPOSITORYTNS\n";
    print $srdc_log_fh localtime(time) . " : EMREPOSITORYOHOME  $EMREPOSITORYOHOME\n";

    print $srdc_log_fh localtime(time) . " : database $database\n";
    print $srdc_log_fh localtime(time) . " : EMSYSMANPWD $astsysman\n";
    print $srdc_log_fh localtime(time) . " : EMDBSNMPPWD $astdbsnmp\n";


    # ==============
    # parse srdcfile
    # ==============

    # ------------------- foreach my $keyinput --------------- <<<<<<<<<<<<<<<<<<<
    foreach my $keyinput ( @scriptsarray ) {
      ### print "--- key $keyinput\n";

      # my %hashattribs = %{%{$tfactlglobal_srdc{$collection_id}->{scripts}}{$keyinput}};

      my $scriptshashref = $tfactlglobal_srdc{$collection_id}->{scripts};
      my %scriptshash = %$scriptshashref;
      my $hashattribsref = $scriptshash{$keyinput};
      my %hashattribs = %$hashattribsref;


      # my %contenthash = %{$tfactlglobal_srdc{$collection_id}->{scripts_content}}{$keyinput};

      my $scripts_contenthashref = $tfactlglobal_srdc{$collection_id}->{scripts_content};
      my %scripts_contenthash = %$scripts_contenthashref;
      my $content = $scripts_contenthash{$keyinput};
      my @altcontent = split /\n/ , $scripts_contenthash{$keyinput};

      my $validrun = TRUE;

=head
      foreach my $c (@altcontent) {
         print "altcontent -> line =  $c\n";
      }
=cut

      ### print "content tfactldiagcollect for script $keyinput => $content\n";

      $scrtype         = $hashattribs{"type"};
      $scrname         = $hashattribs{"name"};
      $scrtimeout      = $hashattribs{"timeout"};
      $validfor        = $hashattribs{"validfor"};
      $script_platform = $hashattribs{"platform"};
      $script_version  = $hashattribs{"version"};
      $depinput        = $hashattribs{"depinput"};
      $deppattern      = $hashattribs{"deppattern"};
       # Check to see if this script  has a dependency on a previous input and match
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
            "in xmlfilters checking depinput against saved depinput: $depinput saved:" . $savedinputs{$depinput} ,'y','y');
      if ( length $depinput && exists $savedinputs{$depinput}) {
            tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                   "in xmlfilters checking deppattern: $deppattern against saved:" . $savedinputs{$depinput} ,'y','y');
         if ( $savedinputs{$depinput} =~ /$deppattern/ ) {
            # this is a valid prompt for the previous input
            print $srdc_log_fh localtime(time) . "Valid dependent input:$depinput value $savedinputs{$depinput} match: $deppattern\n";
         } else {
            print $srdc_log_fh "Invalid dependent input:$depinput value $savedinputs{$depinput} match: $deppattern\n";
            print $srdc_log_fh "Skipping script $scrname due to dependent input: $depinput value $savedinputs{$depinput} match: $deppattern\n";
            $scriptsmsg =~ s/$scrname//;
            next;
         }
      }
      print $srdc_log_fh localtime(time) . " : Reading Scripts to run from  $xmlfilters_orig\n";

      # If we have supplied a platform then make sure it matches
      print $srdc_log_fh localtime(time) . " : SRDC Found $scrname of type  $scrtype for platform $script_platform\n";

      if ( $script_platform eq $osname or !length($script_platform) or ((!$IS_WINDOWS) and $script_platform eq "allux") )
      # same platform or no platform supplied or os is not windows and script runs on allux.
      {
        @scr = ();
        # Add all the setenvs to the start of the script
        foreach my $key ( keys %scriptenvs ) {
           if ( $IS_WINDOWS ) {
              push @scr, "set " . $key . "=" . $scriptenvs{$key};
           } else {
              push @scr, $key . "=" . $scriptenvs{$key};
              push @scr, "export $key";
           }
        }
      } else {
        print $srdc_log_fh localtime(time) . " : SRDC $scrname of type  $scrtype for platform $script_platform does not run on $osname\n";
        next; # don't go any farther, script does not run in current platform
      }

      # ========================
      # SRDC Script replacements
      # using %scriptreplace
      # ========================
      foreach my $c (@altcontent) {
         foreach my $testtr (keys %scriptreplace) {
           # replace only non pwds params
           # -----------------------------------
           $c =~ s/\%$testtr\%/$scriptreplace{$testtr}/ if ( $testtr !~ /_PWD/ );
           $c =~ s/\&lt\;/\</g;
           $c =~ s/\&gt\;/\>/g;
           if ( $c =~ /\%PERL_PATH\%/ ) {
             $c =~ s/\%PERL_PATH\%/$PERL/g;
           } elsif ( $c =~ /\%CWD\%/ ) {
             my $cwd = $IS_AIX ? $ENV{'PWD'} : getcwd();
             $c =~ s/\%CWD\%/$cwd/g;
           }
         }
         push @scr, $c;
      } # end foreach my $c


      # Determine $validrun for OS(EM specific) commands
      # ------------------------------------------------
      if ( $scrtype eq "OS" ) {
         $validrun = TRUE;
         print $srdc_log_fh localtime(time) . " : script $scrname validfor $validfor\n";

         if ( uc($validfor) eq "EMAGENT" or uc($validfor) eq "OMS"  or uc($validfor) eq "REPVFY" ) {
            $validrun = FALSE;
         }

         # EMAGENT section will be executed only on the TARGET host
         if ( uc($validfor) eq "EMAGENT" ) {
            if ( length $EMAGENTOHOME ) {
               $validrun = TRUE;
               print $srdc_log_fh localtime(time) . " :  Valid run for EMAGENT\n";
            }
         } # end if $validfor eq "EMAGENT"

         if ( uc($validfor) eq "OMS" ) {
            if ( length $EMOMSOHOME ) {
               $validrun = TRUE;
               print $srdc_log_fh localtime(time) . " : Valid run for OMS\n";
            }
         } # end if $validfor eq "OMS"

         if ( uc($validfor) eq "REPVFY" ) {
            if ( length $EMREPOSITORYREPVFY && length $em_repositorydb_tns) {
               $validrun = TRUE;
               print $srdc_log_fh localtime(time) . " : Valid run for REPVFY\n";
            }
         } # end if $validfor eq "REPVFY"
         next if not $validrun; # Don't go any farther if not $validrun
      } # end if $scrtype eq "OS"


      ###############################
      #       script generation section
      ###############################
      #
      $scrname =~ s/ //g;
      my $sfname;
      if ( $scrtype eq "DB" || $scrtype eq "SQL" || $scrtype eq "EMSQL" ) {
         $sfname = $scrname;
         $sfname .= ".sql" if $scrname !~ /\.[sS][qQ][lL]/;
      } else {
        if ( $IS_WINDOWS ) {
           $sfname = "script_$scrname.bat";
         } else {
           $sfname = "script_$scrname.sh";
         }
      }

      my $tfactl = catfile($tfa_home,"bin","tfactl");
      open(SWF, ">$sfname");
      foreach my $line (@scr)
      {
        chomp($line);
          $line =~ s/tfactl /$tfactl /;
          if ( $scrtype eq "ORACHK") {
             if ( $database && $database ne "all" ) {
                my $newdb = $database;
                $newdb =~ s/\,$//;
                print SWF "$line -dbnames $newdb\n";
             } else {
               print SWF "$line\n";
             }
          } else {
            # Lookup for _PWD params needed in $sfname script
            # Store them in ==> $emsql_scripts{$sfname}
            # srdc security script generation => $sfname
            # ------------------------------------------
            if ( $scrtype eq "EMSQL" || $scrtype eq "OS" ) {
               my $eminput = "";
               ### print "emsql line ====> $line\n";
               if ( $line =~ /.*\%(.*?)\%.*/ ) {
                  $eminput = $1;
                  if ( $eminput =~ /_PWD/ ) {
                     push( @{$emsql_scripts{$sfname}}, $eminput);
                     ### print "eminput $eminput, sfname $sfname \n";
                     if ( $scrtype eq "EMSQL" ) {
                        # Disabling &$eminput
                        # $line =~ s/\%$eminput\%/\&$eminput/;
                     } else {
                       # OS replacement
                       $line =~ s/ -sysman_pwd \"?\%$eminput\%\"?//;
                     }
                  }
               }
            } # end if $scrtype eq "EMSQL" || $scrtype eq "OS"

            print SWF "$line\n"; # print line to $sfname script

          } # end if $scrtype eq "ORACHK"
      } # end if $scrtype eq "DB" || $scrtype eq "SQL" || $scrtype eq "EMSQL"
      close(SWF);
      chmod(0700,$sfname);

      $hashattribs{"sfname"} = $sfname;
      $hashattribs{"version"} = "all" if ( ! $script_version );
      ###############################
      # 	OS section
      ###############################
      #
      ### print "scrtype $scrtype, validfor $validfor, scrname $scrname\n";
      if ( $scrtype eq "OS" ) {

         if ( $validrun ) {
            if ( length $validfor ) {
               #collectfiles_patreplace($sfname);
            }
            my $runcmd = "";
            if ( $IS_WINDOWS ) {
               $runcmd = $sfname;
            } else {
              $runcmd = "sh $sfname";
            }
            $command = "$runcmd > $hostname"."_$scrname.out 2>&1";
            $hashattribs{"runcmd"} = $command;
            push @scriptstorun,\%hashattribs;

          } else {
            print $srdc_log_fh localtime(time) . " : Not valid $scrtype run, this section is only valid for $validfor.\n";
         } # end if $validrun
      } # end if $scrtype eq "OS"

      ###############################
      #       DB, SQL, SQLSCRIPT section
      ###############################
      #
      elsif ( $scrtype eq "DB" ||
              $scrtype eq "SQL" ||
              $scrtype eq "SQLSCRIPT" ) {
        push @scriptstorun, \%hashattribs;
      } # end elsif $scrtype eq "DB", "SQL" , "SQLSCRIPT"

      ###############################
      #       EMSQL section
      ###############################
      #
      elsif ( $scrtype eq "EMSQL" ) {
            push @scriptstorun, \%hashattribs;
      } else { # remove the script as it is not needed here 
        unlink( $sfname ) if ( -f $sfname ); 
      }
      $script_version = "";
    } # end foreach $keyinput
    # ------------------- foreach my $keyinput --------------- >>>>>>>>>>>>>>>>>>>
     print "$scriptsmsg\n";
     @comps = tfactlshare_uniq(@comps);
     print "Components included in this srdc: ". uc(join(' ',@comps))."\n";

    # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

    # Start processing the scripts to run here DB, SQL, SQLSCRIPT.
    # We have a dbname so should be able to get the Oracle Home

    my $scripttorun;
    my $scr = "";
    my $interval;
    my $freq ;
    foreach my $script ( @scriptstorun ) {
      my %scriptinfo = %{$script};
      $scr = $scriptinfo{"sfname"};
      $script_version = $scriptinfo{"version"};
      my $type = $scriptinfo{"type"};
      $interval =  $scriptinfo{"interval"};
      $freq = $scriptinfo{"frequency"};
      $freq||=1;
      #print Dumper (\%scriptinfo);
      print $srdc_log_fh localtime(time) . " : executing script $scr of type $type with frequency $freq and interval $interval \n";
      for (my $frq = 0; $frq < $freq; $frq++ ) {
        print $srdc_log_fh localtime(time) . " : executing script $scr current frecuency $frq \n";
        if ( $type eq "OS" ) {
          print $srdc_log_fh localtime(time) .  " : executing script $scr of type $type \n\n"; 
          # retrieve scripts params for $sfname script
          # srdc sec os section
          # ------------------------------------------
          my $ref;
          if ( exists $emsql_scripts{$scr} ) {
            $ref = $emsql_scripts{$scr};
            @emsql_scripts_params = @$ref;
          } else {
            @emsql_scripts_params = ();
          }
          # If the OS script requires ORACLE_HOME we should have database ..
          $ohomereq =  0;
          my @lines = split /\n/ , tfactlshare_cat($scr);
          $ohomereq = grep { $_ =~ /ORACLE_HOME/ } @lines;
          chomp($ohomereq);
          print $srdc_log_fh "ohome required in $scr: $ohomereq database:$database\n";
          if ( $ohomereq and length $database ) { 
            my $ret = dbutil_setOraEnv ($tfa_home, "$database", $srdc_log_fh,TRUE);
            print $srdc_log_fh localtime(time) .  " Set env for OS Script : dbutil_setOraEnv() retval -> $ret\n";
          }
          ### print "command $command\n";
          ### print "os emsql_scripts_params @emsql_scripts_params\n";
          # -----------------------------
          if ( @emsql_scripts_params ) {
            use IPC::Open2;
            local (*Reader, *Writer);
            my $pid = open2(\*Reader, \*Writer, $scriptinfo{"runcmd"});
            my $param = "";
            my $replaceval = "";
            for my $ndx ( 0..$#emsql_scripts_params ) {
              $param = $emsql_scripts_params[$ndx];
              if ( exists $scriptreplace{$param} ) {
                ### print "Replacing with " . $scriptreplace{$param} . "\n";
                print Writer $scriptreplace{$param} . "\n";
                sleep(2);
              } else {
                print Writer "\n";
                ### print "Replacing with new line \n";
              }
            }
            close Writer;
            
            while (<Reader>) {
              $cmdout .= $_;
            }
            ### print "cmdout $cmdout\n";
          } else {
            runtimedcommand($scriptinfo{"runcmd"}, $srdc_log_fh, $scriptinfo{"timeout"});
          } # end if @emsql_scripts_params
          # -----------------------------
        } else {
        # ############################
        # Workout env setting etc..
        # ############################
          my @dbs = split(/,/, $database);
          @dbs = keys %{{ map{$_=>1}@dbs}};
          foreach my $dbname (@dbs)
          {
            print $srdc_log_fh localtime(time) .  " : processing for database $dbname \n\n";
            my $ret = dbutil_setOraEnv ($tfa_home, "$dbname", $srdc_log_fh,TRUE);
            print $srdc_log_fh localtime(time) .  " : dbutil_setOraEnv() retval -> $ret\n";
            if ( $ret == 0 )
            {
              print $srdc_log_fh localtime(time) .  " : $dbname-ORACLE_HOME = " . $ENV{"ORACLE_HOME"} . "\n";
              print $srdc_log_fh localtime(time) .  " : $dbname-ORACLE_SID = " . $ENV{"ORACLE_SID"} . "\n";
              print $srdc_log_fh localtime(time) .  " : $dbname-ORACLE_OUSER = " . $ENV{"TFA_ORACLE_USER"} . "\n";
              print $srdc_log_fh localtime(time) .  " : $dbname-OVERSION = " . $ENV{"TFA_ORACLE_VERSION"} . "\n";
              my $sqlplus = catfile($ENV{"ORACLE_HOME"}, "bin", "sqlplus");
              my $cmd = "$sqlplus -v";
              my @out = `$cmd 2>&1`;
              foreach my $line(@out)
              {
                if ( $line =~ /Release ([\d\.]+) / )
                {
                  $dbversion = $1;
                }
              }
              print $srdc_log_fh localtime(time) .  " : executing script $scr on db $dbname of type $type \n\n"; 
              # ############################
              # Scripts of type DB
              # ############################
              if ( $type eq "DB" )
              {
                my $scr_orig = $scr;
                my $version_matched = FALSE;
                if ( ! -e $scr ) {
                  print $srdc_log_fh localtime(time) . " : SQL Script $scr does not exist \n";
                  next;
                }
                my @versions = split(",",$script_version);
                #print "@versions\n";
                foreach my $version (@versions) 
                {
                  if ( $version eq "all" || $dbversion =~ /^$version/ ) {
                      $version_matched = TRUE;
                  }
                }
                if ( $version_matched )
                {
                  print $srdc_log_fh localtime(time) . " : Building script to run $scr on $dbname-ORACLE_SID with \n\n";
                  if ( ! $IS_WINDOWS ) {
                    $scripttorun = "script_$scr.sh";
                  } else {
                    $scripttorun = "script_$scr.bat";
                  }
                  print $srdc_log_fh localtime(time) . " : Script to run $scripttorun\n\n";
                  if ( ! open(F1, '>',$scripttorun) ) {
                    warn "ERROR Unable to open file $scripttorun for writing: $!\n";
                    next;
                  }
                  print $srdc_log_fh localtime(time) . " : Script to run $scripttorun opened\n\n";
                  my $sqlplus = catfile($ENV{ORACLE_HOME},"bin","sqlplus");
                  print F1 "echo exit | $sqlplus \"/as sysdba\" \@$scr\n" if ( $database ne "+ASM" );
                  print F1 "echo exit | $sqlplus \"/as sysasm\" \@$scr\n" if ( $database eq "+ASM" );
      
                  close(F1);
                  chmod(0700,$scripttorun);
                  if ( ! $IS_WINDOWS ) {
                    $command = "sh $scripttorun";
                  } else {
                    $command = $scripttorun;
                  }
                  $cmdout = runtimedcommand($command ." 2>&1",$srdc_log_fh, 600 , TRUE);
                  print $srdc_log_fh localtime(time) . " : Finished executing $scr\n\n";
                  open(OUTF, ">" . $scr. ".out");
                  my $htmlscript = "no";
                  foreach my $line (split /\n/ , $cmdout) {
                    $htmlscript = "yes" if ( $line =~ /\<pre\>/ );
                    print OUTF "$line\n";
                  } # end foreach split /\n/ , $cmdout
                  close(OUTF);
                  move($scr . ".out", "$scr_orig.html") if ($htmlscript eq "yes");
                } else {
                  print $srdc_log_fh localtime(time) . " : DB script $scr does not run for ohome version $dbversion script valid version $script_version\n";
                }
              } # End if  db scripts 
              # ############################
              # Scripts of type SQLSCRIPTS
              # ############################
              if ( $type eq "SQLSCRIPT" || $type eq "SQL" )
              {
                  $scr = $scriptinfo{"name"};
                  my $scr_orig = $scr;
                  my $version_matched = FALSE;
                  $scr = catfile($tfa_home,"resources","sql",$scr);
                  print $srdc_log_fh localtime(time) . " : Processing SQL script $scr\n";
                  if ( ! -e $scr ) {
                    print $srdc_log_fh localtime(time) . " : SQL Script $scr  does not exist \n";
                    next;
                  }
                  my @versions = split(",",$script_version);
                  #print "@versions\n";
                  foreach my $version (@versions) 
                  {
                    if ( $version eq "all" || $dbversion =~ /^$version/ ) {
                      $version_matched = TRUE;
                    }
                  }
                  if ( $version_matched ) 
                  {
                    print $srdc_log_fh localtime(time) . " : Building script to run $scr on $dbname-ORACLE_SID with \n\n";
                    if ( ! $IS_WINDOWS ) {
                      $scripttorun = "script_$scr_orig.sh";
                    } else {
                      $scripttorun = "script_$scr_orig.bat";
                    }
                    print $srdc_log_fh localtime(time) . " : Script to run $scripttorun\n\n";
                    if ( ! open(F1, '>',$scripttorun) ) {
                      warn "ERROR Unable to open file $scripttorun for writing: $!\n";
                      next;
                    }
                    print $srdc_log_fh localtime(time) . " : Script to run $scripttorun opened\n\n";
                    my $sqlplus = catfile($ENV{ORACLE_HOME},"bin","sqlplus");
                    print F1 "echo exit | $sqlplus \"/as sysdba\" \@$scr\n" if ( $database ne "+ASM" );
                    print F1 "echo exit | $sqlplus \"/as sysasm\" \@$scr\n" if ( $database eq "+ASM" );
                    close(F1);
                    chmod(0700,$scripttorun);
                    if ( ! $IS_WINDOWS ) {
                      $command = "sh $scripttorun";
                    } else {
                      $command = $scripttorun;
                    }
                    $cmdout = runtimedcommand("$command > script_$scr_orig.out 2>&1",$srdc_log_fh, 600);
                    print $srdc_log_fh localtime(time) . " : Finished executing $scr\n\n";

                } else {
                  print $srdc_log_fh localtime(time) . " : SQLSCRIPT $scr does not run for ohome version $dbversion script valid version $script_version\n";
                }
              } # End if SQLSCRIPT || SQL
              # ######################################
              #              EMSQL section
              # ######################################
              if ( $type eq "EMSQL" ) {
                my $scr = $scriptinfo{"sfname"};              
                my $validfor = $scriptinfo{"validfor"};
                print $srdc_log_fh localtime(time) .  " : trying to execute  EMSQL Script $scr \n\n";
                my $ldbname = "";
                if ( uc($validfor) eq "TARGETDB" ) {
                  $ldbname = $EMTARGETDBNAME;
                } elsif ( uc($validfor) eq "REPOSITORYDB" ) {
                  $ldbname = $EMREPOSITORYDBNAME;
                }
                next if $ldbname ne $dbname;
                
                print $srdc_log_fh localtime(time) .  " : emsql_scripts validfor $validfor\n";
                print $srdc_log_fh localtime(time) .  " : emsql_scripts executing $scr on db $dbname\n";
                
                if ( -d $ENV{ORACLE_HOME} )
                {
                  $ENV{LD_LIBRARY_PATH} = catfile($ENV{ORACLE_HOME},"lib");
                  
                  print $srdc_log_fh localtime(time) . " : emsql_scripts Started executing $scr on $dbname SID :$ENV{ORACLE_SID}\n\n";
                  
                  my $ohome = $ENV{ORACLE_HOME};
                  my $sqlplus = catfile($ohome,"bin","sqlplus");
                  $command = "$sqlplus \"/as sysdba\" \@$scr > $scr.out 2>&1";

                  # srdc run secure emsql section
                  # ipc::open2/3

                  my $ref;
                  if ( exists $emsql_scripts{$scr} ) {
                    $ref = $emsql_scripts{$scr};
                    @emsql_scripts_params = @$ref;
                  } else {
                    @emsql_scripts_params = ();
                  }

                  ### print "command $command\n";
                  ### print "emsql emsql_scripts_params @emsql_scripts_params\n";
                  ### print "emsql script $scr\n";

                  if ( @emsql_scripts_params ) {
                    my %rephash = (); 
                    my $param = ""; 
                    for my $ndx ( 0..$#emsql_scripts_params ) {
                      $param = $emsql_scripts_params[$ndx];
                      if ( exists $scriptreplace{$param} ) {
                        $rephash{$param} = $scriptreplace{$param};
                      }
                    } # end for

                  $cmdout = tfactlshare_runsecsql($sqlplus,\%rephash, "file", $scr,TRUE);
                  ### print "cmdout $cmdout\n";
                  } else {
                    $command = "$sqlplus \"/as sysdba\" \@$scr > $scr.out 2>&1";
                    runtimedcommand($command,$srdc_log_fh,1800);
                  } # end if @emsql_scripts_params

                  ### print "finish executing emsql \n";
                  print $srdc_log_fh localtime(time) . " : Finished executing $scr\n\n";
                } # end if -d  $dbname-ORACLE_HOME
              } 
            } else { # no env as $ret was 1
              print $srdc_log_fh localtime(time) . " : Unable to set ENV for DB $dbname - Skipping DB EM and SQL scripts\n";
            } # End if $ret=0
          } #End for each database
        }# end if  OS script
        sleep($interval) if ( $interval );
      }#end frequency
    } #end foreach script
    close($srdc_log_fh);
    chdir($currentdir);
  }  # End of xmlfilters processing
  umask $oldumask;
# exit; #BBHERE
  # -------------------------------------------
  # -event <event_name> was used in the cmdline
  # and also (since/for/from/to)
  # e.g. -event "ORA-00600"
  # -------------------------------------------
  if ( $event ) {
    my @events = ($event);
    my $event_time;
    my $event_key="";
    my ($pfor, $pfrom, $pto, $psince);
    $pfor   = $for;
    $pfrom  = $from;
    $pto    = $to;
    $psince = $since;

    if ( ($since||$for||$from||$to) ) {

      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<",'y', 'y');
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
               "in xmlfilters (input -event) passed for:$for from:$from to:$to since:$since: Checking for @events ",
               'y', 'y');

      my ($firstevent, $lastevent) = tfactldiagcollect_get_event_time($tfa_home, \@events, $database, TRUE);
      
      ($from, $to, $for, $since, $duration, $event_time, $event_key) = tfactldiagcollect_validate_event($firstevent, $lastevent, $from, $to, $for, $since, $duration, \@events, $database);

      ($DSCRIPT_OPTS) = tfactldiagcollect_validate_prevcurr($pfor,$for,$pfrom,$from,$pto,$to,$psince,$since,$DSCRIPT_OPTS);

      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                       "in xmlfilters (output -event) DSCRIPT_OPTS $DSCRIPT_OPTS", 'y', 'y');
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>",'y', 'y');

    } else {
      # -------------------------------------------
      # -event <event_name> was used in the cmdline
      # no since/for/to/from
      # -------------------------------------------

      ($event_time, $event_key) = tfactldiagcollect_get_event_time($tfa_home, \@events, $database);

      if ( $event_time )
      {
        if ( length $duration ) {
          my $starttime;
          my $endtime;
          ($starttime, $endtime) = tfactldiagcollect_getrange_for_event($event_time, $duration );

          $DSCRIPT_OPTS .= " -from $starttime -to $endtime";
          $DSCRIPT_OPTS =~ s/ -duration $duration//;
          $from = $starttime;
          $to   = $endtime; 
        } else {
          if ( $DSCRIPT_OPTS !~ /\-for $for/ ) { # Not already in $DSCRIPT_OPTS
           $for = $event_time;
           $DSCRIPT_OPTS .= " -for $for";
          }
        }
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                          "in xmlfilters after chosen event time $event_time : DSCRIPT_OPTS:$DSCRIPT_OPTS ",
                         'y', 'y');
      } # end if $event_time
    } # end if ($since||$for||$from||$to)

      my $selected_db;
      if  ($database)
      {
         $selected_db = $database ;
      } elsif ( length $event_key and $event_key =~ /^db\.(\w+)\./ ) {
        $selected_db = $1;
        $database = $selected_db;
      }

      if ( $DSCRIPT_OPTS !~ /\-database $selected_db/ ) { # Not already in $DSCRIPT_OPTS
          $DSCRIPT_OPTS .= " -database $selected_db";
      }

      if ( $DSCRIPT_OPTS !~ /\-node\s+local/ ) { # Not already in $DSCRIPT_OPTS
        $DSCRIPT_OPTS .= " -node local";
        $node = "local";
      }

    $DSCRIPT_OPTS =~ s/ \-event $event//g if $event;
  } # end if $event

  # ==========================
  # Make EM SRDCs always local
  # ==========================
  ### print "xmlfilters $xmlfilters\n";
  if ( lc($xmlfilters) =~ /em(tbsmetric|metricalert|debugon|debugoff|procdisc|gendisc|clusdisc|cliadd|dbsys|restartoms|agentperf|omscrash|omsheap|omshungcpu)/ ) {
    if ( $DSCRIPT_OPTS !~ /-node .*/ ) {
      $DSCRIPT_OPTS .= " -node local";
    } else {
      $DSCRIPT_OPTS =~ s/ -node [^,\s]+(,[^,\s]+)*//g;
      $DSCRIPT_OPTS .= " -node local";
    }
  }

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
            "Before onlycell SCRIPT_OPTS $DSCRIPT_OPTS", 'y', 'y');    


  # TBD : checking validity of cells

  # if onlycel is set, then set RUNDIAGCOLLECTCELL
  # onlycell will be passed internally in runDiagcollectionInCells
  # Collection for cell should be done by local compute node
  if ( $onlycell == 1 && ($current_user eq "root") ) {
        $RUNDIAGCOLLECTCELL = 1;
  }
  if ( $exadatacell && $nocell ) {
        print "\n-nocell flag cannot be combined with -cell flag\n";
        print_help("diagcollect", "");
        $exitcode = 1;
        last dscriptoptions;
        #exit 0;
  }

  if($EXADATA == 1){
    if ( $current_user ne "root" ) {
      $nocell = 1;
      print "\nWARNING: User \'$current_user\' is not allowed to run Collections on Storage Cells (Run diagcollect as root user to collect files from Storage Cells).\n";
    }
  }
  
  if ( $exadatacell ) {
        if ( ($EXADATA == 1) && ($current_user eq "root")) {
          #if ($exadatacell eq "all" || $exadatacell =~ /,/) {
          $RUNDIAGCOLLECTINCELLS = 1;
          $DSCRIPT_OPTS =~ s/-cell $exadatacell//;
          $cells = $exadatacell;
        } else {
          $exadatacell = 0;
        }
  }

  if ($copytocomputenode) {
        print "Copy $cell zip to compute node : $copytocomputenode\n";
  }

  if ( $asmproxy || $asmio || $exadata || $computenode ) {
        print "\nUnsupported Options for diagcollect: -asmproxy or -asmio or -computenode or -exadata\n";
        print_help("diagcollect", "");
        $exitcode = 1;
        last dscriptoptions;
  }

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                    "========>  isaddcomp ... $isaddcomp", 'y', 'y');

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
            "Before if not database, all, event but sundiag or oda SCRIPT_OPTS $DSCRIPT_OPTS", 'y', 'y');    

  if ( $all ) {
     print "The -all switch is being deprecated as collection of all components is " .
           "the default behavior. TFA will continue to collect all components.\n";
     $DSCRIPT_OPTS =~ s/ -all//;
  }
  if (! ($database || $event || 
         exists $diaghashoptions{"sundiag"} || 
         exists $diaghashoptions{"oda"} || 
         exists $diaghashoptions{"odastorage"} || $isaddcomp ) ) {
        if (! ($nocomponent || $xmlfilters) ) {
           $DSCRIPT_OPTS .= " -all";
           $DSCRIPT_DEF   = TRUE;
	}
        if (! ($since || $for || $from || $to) ) {
          my $global_time_flags = tfactldiagcollect_get_time_flags();
          if ( $global_time_flags )
          {
            $DSCRIPT_OPTS .= $global_time_flags;
          }
           else
          { 
          	my $configFile = catfile($tfa_home, "internal", "config.properties" );
  		if ( -r $configFile ) {
    			$DIAG_TIME = tfactlshare_getConfigValue($configFile,"collectionPeriod");
  		}
		print "\nCollecting data for the last $DIAG_TIME hours for all components...\n";
            	# if no time restriction is mentioned, we collect from last x hours.
            	$DSCRIPT_OPTS .= " -since " . $DIAG_TIME . "h";
          }
        }
	if (! ($nocomponent || $xmlfilters) ) {
           if ( -f "/opt/oracle/oak/bin/oakd" ) {
              $DSCRIPT_OPTS =~ s/-all/-database all -asm -crs -dbwlm -acfs -os -install -ips -cfgtools -tns -oda/;
              $DSCRIPT_OPTS =~ s/-oda/-oda -odalite/ if $IS_ODALITE;
              $DSCRIPT_DEF  = TRUE;
           }
           elsif ( isODADom0() == 1 ) {
              # print "\nCollecting data for all components using above parameters...\n";
              $DSCRIPT_OPTS =~ s/-all/-os -oda -ips/;
              $DSCRIPT_DEF  = TRUE;
           }
	   elsif ( -d "/opt/oracle.RecoveryAppliance" ) {
              $DSCRIPT_OPTS =~ s/ -all//;
              $DSCRIPT_OPTS .=  $addcompstring . " -sundiag  -zdlra";

	      if ( $DSCRIPT_OPTS !~ /-awr/ ) {
		$DSCRIPT_OPTS .= " -awrhtml";
	      }
	   }
           else {
              # print "\nCollecting data for all components using above parameters...\n";
              $DSCRIPT_OPTS =~ s/-all/-database all/;
              $DSCRIPT_OPTS .=  $addcompstring . " -sundiag";
              $DSCRIPT_DEF  = TRUE;
              if ( $IS_RACDBCLOUD ) {
                 $DSCRIPT_OPTS .= $addcompstring_racdbcloud;
              }
           }
	}
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
            "After last chmos change SCRIPT_OPTS $DSCRIPT_OPTS", 'y', 'y');    
	if ( !$nochmos ) {
             $DSCRIPT_OPTS .= " -chmos";
        }
  }
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
            "before Adding since default if not passed SCRIPT_OPTS $DSCRIPT_OPTS", 'y', 'y');    

  #Adding -since 24h (default) if it was not passed along with options like -crs or -os etc.
  if ( ($database ||  $event ||
        exists $diaghashoptions{"sundiag"} || 
        exists $diaghashoptions{"oda"} || 
        exists $diaghashoptions{"odastorage"} || $isaddcomp) ) {
        if (! ($since || $for || $from || $to) ) {
          my $global_time_flags = tfactldiagcollect_get_time_flags();
          if ( $global_time_flags )
          {
            $DSCRIPT_OPTS .= $global_time_flags;
          }
           else
          {
	    my $configFile = catfile($tfa_home, "internal", "config.properties" );
            if ( -r $configFile ) {
	       $DIAG_TIME = tfactlshare_getConfigValue($configFile,"collectionPeriod");
            }

            my $msg;
            if ( $ipsincident && $ipsincident =~ /^([0-9]+)$/ ) {
              $msg = "incident $1 ...";
            } elsif ( $ipsproblem && $ipsproblem =~ /^([0-9]+)$/ ) {
              $msg = "problem $1 ...";
            } elsif ( $ipsproblemkey ) {
              $msg = "problemkey $ipsproblemkey ...";
            } else {
              $msg = "the last $DIAG_TIME hours for this component ...";
            }

            print "\nCollecting data for $msg\n";
            $DSCRIPT_OPTS .= " -since " . $DIAG_TIME . "h";
          }
        }
  } # end if ($database ||  $event || ...
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                  "before add chmos if os or crs DSCRIPT_OPTS $DSCRIPT_OPTS", 'y', 'y');    

  if ( exists $diaghashoptions{"os"} || exists $diaghashoptions{"crs"} ) {
        if ( !$nochmos ) {
	  $DSCRIPT_OPTS .= " -chmos";
        }
  }
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                  "After add chmos if os or crs DSCRIPT_OPTS $DSCRIPT_OPTS", 'y', 'y');    

  # checking for valid date/time
  if ($since) {
    if (!($since =~ /^(\d+)d{1}$/ || $since =~ /^(\d+?)h{1}$/)) {
      print "The time entered is invalid: $since\n";
      print "Some examples of valid time entries for -since flag : 2h, 10d\n";
      $exitcode = 1;
      last dscriptoptions;
    }

    if ( $since =~ /^(\d+)d{1}$/ ) {
        my $time = $since;
        $time =~ s/d$//;

        if ( $time > 30 ) {
                print "Number of days for -since flag should be less than or equal to 30\n";
                $exitcode = 1;
                last dscriptoptions;
        }
    }

    if ( $since =~ /^(\d+)h{1}$/ ) {
        my $time = $since;
        $time =~ s/h$//;

        if ( $time > 720 ) {
                print "Number of hours for -since flag should be less than or equal to 720\n";
                $exitcode = 1;
                last dscriptoptions;
        }
    }
  }

  if ( !($monitor || $nomonitor)) {
        $DSCRIPT_OPTS .= " -monitor";
  }

  if ( $nomonitor ) {
        print "\nPlease use \"$tfacmd print actions\" to monitor the status of this run.\n\n";
        $NOMONITOR = TRUE;
  }

  if ( $notrim ) {
        $DSCRIPT_OPTS .= " -notrim";
  }
  if ( $sanitize ) {
        $DSCRIPT_OPTS .= " -sanitize";
  }
  if ( $mask ) {
        $DSCRIPT_OPTS .= " -mask";
  }

  if ( ! $DSCRIPT_OPTS && $cmd1 eq "diagcollect" ) {
    print_help ("diagcollect", "");
    $exitcode = 1;
    last dscriptoptions;
  }

  # $cmd1  = diagcollect, collect
  @ARGV = ($cmd1);
  print $ipsfh "$debugtime tfactldiagcollect_process_cmd cmd1  = diagcollect, collect => ARGV @ARGV\n" if $debugips;

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                  "Before Check ipsallfiles switch DSCRIPT_OPTS $DSCRIPT_OPTS", 'y', 'y');    

  # Check ipsallfiles switch
  if ( $ipsallfiles ) {
    if ( $DSCRIPT_NOIPS ) {
      print "-ipsallfiles switch and -noips can not be used at the same time.\n";
      print_help("diagcollect", "");
      $exitcode = 1;
      last dscriptoptions;
    } elsif ( not defined $ips ) {
      print "-ipsallfiles switch can only be used for default/ips collections.\n";
      print_help("diagcollect", "");
      $exitcode = 1;
      last dscriptoptions;
    } else {
      $TFAIPS_ALLFILES = TRUE;
      $TFAIPS_ALLFILESTXT   = '(all_files = true) ';
    }
  } # end if $ipsallfiles

  # DSCRIPT_DEF=0,IPS=0 => $DSCRIPT_NOIPS = TRUE
  if ( not $DSCRIPT_RUNDEF ) {
    $DSCRIPT_DEF=0;
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "Not running the default IPS collection, DSCRIPT_RUNDEF => $DSCRIPT_RUNDEF", 'y', 'y');
  } else {
    if ( not $DSCRIPT_DEF ) { 
      print "-defips switch can only be used with default TFA collections.\n";
      print_help("diagcollect", "");
      $exitcode = 1;
      last dscriptoptions;
    }
  }
  if ( (not $DSCRIPT_DEF) && (not defined $ips) ) {
    $DSCRIPT_NOIPS = TRUE;
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "DSCRIPT_DEF=0,DSCRIPT_IPS=0 => DSCRIPT_NOIPS $DSCRIPT_NOIPS", 'y', 'y');
  } else {
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "DSCRIPT_DEF=$DSCRIPT_DEF,DSCRIPT_IPS=$DSCRIPT_IPS => DSCRIPT_NOIPS $DSCRIPT_NOIPS", 'y', 'y');
  }

  # Check TFA IPS package manipulation switches
  if ( $ipsmanageips ) {
    if ( (not defined $ips) && (not $DSCRIPT_DEF) ) {
      print "-manageips switch can only be used for default TFA IPS collections or \n";
      print "when the -ips switch is available.\n";
      $exitcode = 1;
      last dscriptoptions;
    } elsif ( $DSCRIPT_NOIPS ) {
      print "As there are not default TFA IPS collections the -manageips switch cannot be used.\n";
      $exitcode = 1;
      last dscriptoptions;
    }
    $DSCRIPT_OPTS =~ s/ -manageips//g;
  }

  # Prefix was used before relative ADR homepath, make it relative ADR homepath
  if ( $adrhomepath && length $adrhomepath                  &&   
      ( not $DSCRIPT_NOIPS )                                &&   
      ($adrhomepath =~ m/(.*)\/(diag\/rdbms\/.*\/.*\_[0-9]+)/ ||
       $adrhomepath =~ m/(.*)\/(diag\/rdbms\/.*\/.*[0-9]+)/   ||   
       $adrhomepath =~ m/(.*)\/(diag\/rdbms\/.*\/.*)/         ||
       $adrhomepath =~ m/(.*)\/(diag\/.*\/\+ASM[0-9]+)/       ||    
       $adrhomepath =~ m/(.*)\/(diag\/.*\/\+APX[0-9]+)/       ||
       $adrhomepath =~ m/(.*)\/(diag\/.*\/\+IOS[0-9]+)/       ||
       $adrhomepath =~ m/(.*)\/(diag\/(asmtool|clients|asm|afdboot|diagtool)\/user_.*\/(host|adrci)_.*)/ ||
       $adrhomepath =~ m/(.*)\/(diag\/crs\/.*)/ )  ) {
    $adrbasepath = $1;
    $adrhomepath = $2;  
    if ( $debugips ) {
      print $ipsfh "$debugtime tfactldiagcollect_process_cmd Prefix was used before relative ADR homepath, make it relative ADR homepath.\n",
                   "$debugtime tfactldiagcollect_process_cmd adrbasepath $adrbasepath\n",
                   "$debugtime tfactldiagcollect_process_cmd adrhomepath $adrhomepath\n";
    } # end if $debugips
  }

  ###print "DSCRIPT_DEF $DSCRIPT_DEF \n";
  ###print "adrbasepath $adrbasepath\n";
  ###print "adrhomepath $adrhomepath\n";
  ###print "adrcorrlvl   $adrcorrlvl\n";
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                    "DSCRIPT_DEF $DSCRIPT_DEF", 'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                    "adrbasepath $adrbasepath", 'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                    "adrhomepath $adrhomepath", 'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                    "adrcorrlvl $adrcorrlvl", 'y', 'y');

  # Set ADR Base for default IPS execution
  my @adrbases = ();
  @adrbases  = tfactlshare_get_adr_bases($tfa_home, $localhost) if $DSCRIPT_DEF;

  ###print "adrbases @adrbases\n";
  if ( $DSCRIPT_DEF && (not $DSCRIPT_NOIPS) ) {
    my @adrbases = tfactlshare_get_adr_bases($tfa_home, $localhost);
    ### print "adrbases @adrbases\n";
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                    "adrbases @adrbases", 'y', 'y');
    for my $adrbaselocal (@adrbases) {
       if ( not exists $tfactlglobal_adrbaseselected{$adrbaselocal} ) {
         $tfactlglobal_adrbaseselected{$adrbaselocal} = TRUE;
       }
    }
    if ( @adrbases ) {
      $TFAIPS_ADRBASE = $adrbases[0];
      $TFAIPS_ADRHOMEPATH = "dummy";
    }
  } # end if $DSCRIPT_DEF

  # Check if $adrbasepath was provided
  if ( $adrbasepath && length $adrbasepath && (not $DSCRIPT_NOIPS) ) {
    my @adrbasepathentries = split /\,/ , $adrbasepath;
    my @adrbases = tfactlshare_get_adr_bases($tfa_home, $localhost);
    my %adrbaseshash = map {$_ => TRUE} @adrbases;
    my $adrbasepathmatch = TRUE;

    # Validate adrbasepath entries provided in commandline
    # to be stored in %tfactlglobal_adrbasepaths
    foreach my $inpbasepath (@adrbasepathentries) {
      if ( not exists $adrbaseshash{$inpbasepath} ) {
        $adrbasepathmatch = FALSE;
      }
    } # end foreach @adrbasepathentries

    if ( $adrbasepathmatch ) {
      $TFAIPS_UNDO_ADRBASEPATH = $adrbasepath;
      $TFAIPS_ADRBASE = $adrbasepath;

      if ( $#adrbasepathentries > 0 && $adrhomepath && length $adrhomepath ) {
        print "When multiple adr homepaths are provided only one ADR basepath must be provided.\n";
        print_help("diagcollect", "");
        $exitcode = 1;
        last dscriptoptions;
      } elsif ( $#adrbasepathentries == 0 && $adrhomepath && length $adrhomepath ) {
        $tfactlglobal_adrbasepaths{$adrbasepath} = $adrhomepath;
      } elsif ( $#adrbasepathentries == 0 ) {
        $tfactlglobal_adrbasepaths{$adrbasepath} = "";
      }
    } else {
      print "ADR basepath(s) provided is(are) invalid ...\n";
      print_help("diagcollect", "");
      $exitcode = 1;
      last dscriptoptions;
    } # end if $adrbasepathmatch
  } # end if $adrbasepath && length $adrbasepath


  # Prepare ADR basepaths for incidents/problems/problemkeys
  # to be stored in %tfactlglobal_adrbaseselected
  my $ipsoutput;

  if ( $ipsincident ) {
       ###print "\n\nChecking ips incident \n\n";
       tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                         "Checking ips incident", 'y', 'y');
       if ( $DSCRIPT_NOIPS ) {
         print "-incident switch and -noips can not be used at the same time.\n";
         print_help("diagcollect", ""); 
         $exitcode = 1;
         last dscriptoptions;
       } elsif ( $ipsproblem || $ipsproblemkey ) {
         print "-incident switch and -problem/-problemkey can not be used at the same time.\n";
         print_help("diagcollect", ""); 
         $exitcode = 1;
         last dscriptoptions;
       } else {
         if ( $ipsincident =~ /^[0-9]+$/ ) {
           $TFAIPS_INCIDENTNMBR = $ipsincident;
         } else {
           print "The value for the -incident switch must be an integer.\n";
           print_help("diagcollect", ""); 
           $exitcode = 1;
           last dscriptoptions;
         }    
       }
  } # end if $ipsincident

  if ( $ipsproblem ) {
       if ( $DSCRIPT_NOIPS ) {
         print "-problem switch and -noips can not be used at the same time.\n";
         print_help("diagcollect", "");
         $exitcode = 1;
         last dscriptoptions;
       } elsif ( $ipsincident || $ipsproblemkey ) {
         print "-problem switch and -incident/-problemkey can not be used at the same time.\n";
         print_help("diagcollect", "");
         $exitcode = 1;
         last dscriptoptions;
       } else {
         if ( $ipsproblem =~ /^[0-9]+$/ ) {
           $TFAIPS_PROBLEMNMBR = $ipsproblem;
         } else {
           print "The value for the -problem switch must be an integer.\n";
           print_help("diagcollect", "");
           $exitcode = 1;
           last dscriptoptions;
         }
       }
  } # end if $ipsproblem

  if ( $ipsproblemkey ) {
       if ( $DSCRIPT_NOIPS ) {
         print "-problemkey switch and -noips can not be used at the same time.\n";
         print_help("diagcollect", "");
         $exitcode = 1;
         last dscriptoptions;
       } elsif ( $ipsincident || $ipsproblem ) {
         print "-problemkey switch and -incident/-problem can not be used at the same time.\n";
         print_help("diagcollect", "");
         $exitcode = 1;
         last dscriptoptions;
       } else {
         $TFAIPS_PROBLEMKEY = $ipsproblemkey;
       }
  } # end if $ipsproblemkey

  # ---------------------------------------
  # begin Populate incidents/problems/problemkeys
  # ---------------------------------------
  if ( ($ipsincident || $ipsproblem || $ipsproblemkey) && (not $DSCRIPT_NOIPS) ) {

    if ( $debugips ) {
      print $ipsfh "$debugtime Checking incident, adrbases: @adrbases \n",
                    "$debugtime ==============================================\n";
    }
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "begin Populate...checking incident @adrbases", 'y', 'y');

    foreach my $adrbaseitem (@adrbases) {
      $ipsoutput = tfactlshare_call_adrci("show homes", "yes","no","","","no",
                   $adrbaseitem,"yes");
      next if ( $ipsoutput =~ /DIA\-48447\: The input path/ || 
                $ipsoutput =~ /The input path does not contain any ADR homes/ );
      my @adrbasepaths = split /\n/ , $ipsoutput;
      shift @adrbasepaths;

      my $adrcicmd = "show incidents -all";
      if ( $ipsproblem ) {
        $adrcicmd = "show problems";
      } # end if $ipsproblem

      print $ipsfh "$debugtime tfactldiagcollect_process_cmd Homes for base $adrbaseitem, @adrbasepaths \n" if $debugips;
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "Homes for base $adrbaseitem, @adrbasepaths", 'y', 'y');

      foreach my $adrbasepathsitem (@adrbasepaths) {
         print $ipsfh "$debugtime foreach, adrbaseitem $adrbasepathsitem => adrcicmd $adrcicmd \n" if $debugips;
         $ipsoutput = tfactlshare_call_adrci($adrcicmd, "yes","no","$adrbasepathsitem","","no",
                      $adrbaseitem,"yes");
         print $ipsfh "$debugtime ipsoutput $ipsoutput\n" if $debugips; 
         next if ( $ipsoutput =~ /\n0 rows fetched/ );
         foreach my $line ( split /\n/ , $ipsoutput ) {

            # ----------------------------------
            # Look for incidents and problemkeys
            # ----------------------------------

            my $matcher = '^([0-9]+)\s+(.*)\s+[0-9][0-9][0-9][0-9]\-.*';
            $matcher = '^([0-9]+)\s+.*' if $ipsproblem;

            # $1 = incident, $2 = problemkey
            if ( $line =~/$matcher/ && $line !~ /^[0-9]+\s+rows? fetched/ ) {

              # ---------------
              # Store problems
              # ---------------
              if ( $ipsproblem && 
                   not exists $all_adrci_problems{$1 . $TFAIPS_KEYSEP . $adrbaseitem . $TFAIPS_KEYSEP . $adrbasepathsitem }  ) {
                $all_adrci_problems{$1 . $TFAIPS_KEYSEP . $adrbaseitem . $TFAIPS_KEYSEP . $adrbasepathsitem} = $1;
                print $ipsfh "$debugtime Problems for $adrbaseitem . $adrbasepathsitem \n\n$1\n" if $debugips;
                tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                                  "Problems for $adrbaseitem . $adrbasepathsitem \n\n$1", 'y', 'y');
              } # end if not exists $all_adrci_problems{..}

              # ---------------
              # Store incidents
              # ---------------
              if ( ($ipsincident || $ipsproblemkey) &&
                   not exists $all_adrci_incidents{$1 . $TFAIPS_KEYSEP . $adrbaseitem . $TFAIPS_KEYSEP . $adrbasepathsitem }  ) {
                $all_adrci_incidents{$1 . $TFAIPS_KEYSEP . $adrbaseitem . $TFAIPS_KEYSEP . $adrbasepathsitem} = $1;
                print $ipsfh "$debugtime Incident for $adrbaseitem . $adrbasepathsitem \n\n$1\n" if $debugips;
                tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                                  "Incident for $adrbaseitem . $adrbasepathsitem", 'y', 'y');
              } # end if not exists $all_adrci_incidents{..}

              # -----------------
              # Store problemkeys
              # -----------------
              if ( ($ipsincident || $ipsproblemkey) &&
                   not exists $all_adrci_problemkeys{trim($2) . $TFAIPS_KEYSEP . $adrbaseitem . $TFAIPS_KEYSEP . $adrbasepathsitem }  ) {
                $all_adrci_problemkeys{trim($2) . $TFAIPS_KEYSEP . $adrbaseitem . $TFAIPS_KEYSEP . $adrbasepathsitem} = trim($2);
                print $ipsfh "$debugtime Problemkey for $adrbaseitem . $adrbasepathsitem (" . trim($2) .")\n" if $debugips;
                tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                                  "Problemkey for $adrbaseitem . $adrbasepathsitem (" . trim($2) .")", 'y', 'y');
              } # end if not exists $all_adrci_problemkeys{..}

            } # end if $line =~/^([0-9]+)\s+.*/ ...
         } # end foreach $ipsoutput
      } # end foreach @adrbasepaths
    } # end foreach @adrbases
  } # end if ($ipsincident || $ipsproblem || $ipsproblemkey) ...
  # ---------------------------------------
  # end Populate incidents/problems/problemkeys
  # ---------------------------------------

  # ---------------------------
  # begin Validate incidents
  # ---------------------------
  if ( $debugips ) {
    print $ipsfh "$debugtime begin Validate incidents\n",
                 "$debugtime ========================\n";
  }
  if ( ($ipsincident || $ipsproblem || $ipsproblemkey ) && (not $DSCRIPT_NOIPS) ) {
    my $hdr1 = "Incident";
    my $hdr2 = "incidents";
    my $hdr3 = "incident";
    my $issue = $TFAIPS_INCIDENTNMBR;
    if ( $ipsproblem ) {
      $hdr1 = "Problem";
      $hdr2 = "problems";
      $hdr3 = "problem";
      $issue = $TFAIPS_PROBLEMNMBR;
    } elsif ( $ipsproblemkey ) {
      $hdr1 = "Problemkey";
      $hdr2 = "problemkeys";
      $hdr3 = "problemkey";
      $issue = $TFAIPS_PROBLEMKEY;
    }

    if ( $debugips ) {
      print $ipsfh "$debugtime Validating if $hdr3 $issue exists...\n",
                   "$debugtime issue $issue\n";
      foreach my $kkey ( keys %all_adrci_incidents ) {
         print $ipsfh "$debugtime kkey $kkey\n";
      }
    } # end if $debugips

    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "Validating if $hdr3 $issue exists...", 'y', 'y');

    my @keymatches;
    @keymatches =  grep { $_ =~ /^$issue$TFAIPS_KEYSEP/} keys %all_adrci_incidents;
    @keymatches =  grep { $_ =~ /^$issue$TFAIPS_KEYSEP/} keys %all_adrci_problems if $ipsproblem;
    @keymatches =  grep { $_ =~ /^$issue$TFAIPS_KEYSEP/} keys %all_adrci_problemkeys if $ipsproblemkey;

    if ( not @keymatches ) {
      print "$hdr1 $issue does not exist.\n";
      print "Plase run diagcollect again.\n";
      print "Valid $hdr2:\n";

      if ( $ipsincident || $ipsproblem ) {
        print sprintf("%10s %-30s  %-30s","$hdr1","ADR Base","ADR Homepath") . "\n";
        print sprintf("%10s %-30s  %-30s","--------","--------------------","--------------------") . "\n";
      } else {
        print sprintf("%-60s %-25s  %-15s","$hdr1","ADR Base","ADR Homepath") . "\n";
        print sprintf("%-60s %-25s  %-15s","--------","--------------------","--------------------") . "\n";
      }
      if ( $ipsincident ) {
        foreach my $keys 
               (sort { substr($a,0,index($a,$TFAIPS_KEYSEP)) <=> substr($b,0,index($b,$TFAIPS_KEYSEP)) } keys %all_adrci_incidents) {
          if ( $keys =~ /$TFAIPS_KEYMATCHER/ ) {
            print sprintf("%10s %-30s  %-30s",$1,$2,$3) . "\n";
          } # end if $keys =~ /$TFAIPS_KEYMATCHER/
        } # end foreach keys %all_adrci_incidents
      } elsif ( $ipsproblem ) {
        foreach my $keys 
               (sort { substr($a,0,index($a,$TFAIPS_KEYSEP)) <=> substr($b,0,index($b,$TFAIPS_KEYSEP)) } keys %all_adrci_problems) {
          if ( $keys =~ /$TFAIPS_KEYMATCHER/ ) {
            print sprintf("%10s %-30s  %-30s",$1,$2,$3) . "\n";
          } # end if $keys =~ /$TFAIPS_KEYMATCHER/
        } # end foreach keys %all_adrci_problems
      } elsif ( $ipsproblemkey ) {
        foreach my $keys
               (sort { substr($a,0,index($a,$TFAIPS_KEYSEP)) <=> substr($b,0,index($b,$TFAIPS_KEYSEP)) } keys %all_adrci_problemkeys) {
          if ( $keys =~ /$TFAIPS_KEYMATCHER/ ) {
            print sprintf("%-60s %-25s  %-15s",$1,$2,$3) . "\n";
          } # end if $keys =~ /$TFAIPS_KEYMATCHER/
        } # end foreach keys %all_adrci_problemkeys
      }

      last dscriptoptions;
      #print_help("diagcollect", "");
      last dscriptoptions;
    } elsif ( $#keymatches > 0 ) {
      my $matched = FALSE;
      if ( $adrbasepath && length $adrbasepath && $adrhomepath && length $adrhomepath ) {

        if ( $ipsincident ) {
          foreach my $key (keys %all_adrci_incidents) {
            if ( $key =~ /$TFAIPS_KEYMATCHER/ && $adrbasepath eq $2 &&
                 $adrhomepath eq $3 ) {
              @keymatches     = ();
              push @keymatches, $key;
              $matched = TRUE;
              last;
            } # end if $keys =~ /$TFAIPS_KEYMATCHER/
          } # end foreach keys %all_adrci_incidents
        } elsif ( $ipsproblem ) {
         foreach my $key (keys %all_adrci_problems) {
            if ( $key =~ /$TFAIPS_KEYMATCHER/ && $adrbasepath eq $2 &&
                 $adrhomepath eq $3 ) {
              @keymatches     = ();
              push @keymatches, $key;
              $matched = TRUE;
              last;
            } # end if $keys =~ /$TFAIPS_KEYMATCHER/
          } # end foreach keys %all_adrci_problems
        } elsif ( $ipsproblemkey ) {
         foreach my $key (keys %all_adrci_problemkeys) {
            if ( $key =~ /$TFAIPS_KEYMATCHER/ && $adrbasepath eq $2 &&
                 $adrhomepath eq $3 ) {
              @keymatches     = ();
              push @keymatches, $key;
              $matched = TRUE;
              last;
            } # end if $keys =~ /$TFAIPS_KEYMATCHER/
          } # end foreach keys %all_adrci_problemkeys
        }

      } # end if $adrbasepath && length $adrbasepath ...

      if ( not $matched ) {
        print "$hdr1 $issue exists in more than one ADR homepath.\n";
        print "Provided adrbasepath and/or homepath are not invalid for this $hdr3.\n" if 
        ( $adrbasepath && length $adrbasepath && $adrhomepath && length $adrhomepath); 
        print "Matching ADR homepaths for this $hdr3:\n";

       if ( $ipsincident || $ipsproblem ) {
         print sprintf("%10s %-30s  %-30s","$hdr1","ADR Base","ADR Homepath") . "\n";
         print sprintf("%10s %-30s  %-30s","--------","--------------------","--------------------") . "\n";
       } else {
         print sprintf("%-60s %-25s  %-15s","$hdr1","ADR Base","ADR Homepath") . "\n";
         print sprintf("%-60s %-25s  %-15s","--------","--------------------","--------------------") . "\n";
       }

       if ( $ipsincident ) {
         foreach my $keys 
              (sort { substr($a,0,index($a,$TFAIPS_KEYSEP)) <=> substr($b,0,index($b,$TFAIPS_KEYSEP)) } keys %all_adrci_incidents) {
           if ( $keys =~ /$TFAIPS_KEYMATCHER/ && $issue eq $1 ) {
             print sprintf("%10s %-30s  %-30s",$1,$2,$3) . "\n";
           } # end if $keys =~ /$TFAIPS_KEYMATCHER/
         } # end foreach keys %all_adrci_incidents
       } elsif ( $ipsproblem ) {
         foreach my $keys 
              (sort { substr($a,0,index($a,$TFAIPS_KEYSEP)) <=> substr($b,0,index($b,$TFAIPS_KEYSEP)) } keys %all_adrci_problems) {
           if ( $keys =~ /$TFAIPS_KEYMATCHER/ && $issue eq $1 ) {
             print sprintf("%10s %-30s  %-30s",$1,$2,$3) . "\n";
           } # end if $keys =~ /$TFAIPS_KEYMATCHER/
         } # end foreach keys %all_adrci_problems
       } elsif ( $ipsproblemkey ) {
         foreach my $keys
              (sort { substr($a,0,index($a,$TFAIPS_KEYSEP)) <=> substr($b,0,index($b,$TFAIPS_KEYSEP)) } keys %all_adrci_problemkeys) {
           if ( $keys =~ /$TFAIPS_KEYMATCHER/ && $issue eq $1 ) {
             print sprintf("%-60s %-25s  %-15s",$1,$2,$3) . "\n";
           } # end if $keys =~ /$TFAIPS_KEYMATCHER/
         } # end foreach keys %all_adrci_problemkeys
       }

        print "\nIn order to collect one of the above " . lc($hdr2)  . " please use,\n";
        print "tfactl diagcollect -ips -" . lc($hdr1) . " $issue -adrbasepath <adr_basepath> " .
              "-adrhomepath <adr_homepath>\n\n";
        #print_help("diagcollect", "");
        $exitcode = 1;
        last dscriptoptions;
      } # end if not $matched
    }

    if ( $debugips ) {
      print $ipsfh "$debugtime tfactldiagcollect_process_cmd keymatches @keymatches\n",
                   "$debugtime tfactldiagcollect_process_cmd =============================\n";
    }
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "keymatches @keymatches", 'y', 'y');

    # Prepare global elements for matched incident
    %tfactlglobal_adrbaseselected = ();
    %tfactlglobal_adrbasepaths    = ();
    if ( $keymatches[0] =~ /$TFAIPS_KEYMATCHER/ ) {
      if ( $adrbasepath && length $adrbasepath && $adrbasepath ne $2 ) {
        print "$hdr1 $issue is not associated with ADR basepath $adrbasepath.\n";
        print "ADR basepath for $hdr3 $issue is $2.\n";
        print "Please enter the correct -adrbasepath or just type the $hdr3 number.\n";
        $exitcode = 1;
        last dscriptoptions;
      }
      if ( $adrhomepath && length $adrhomepath && $adrhomepath ne $3 ) {
        print "$hdr1 $issue is not associated with ADR homepath $adrhomepath.\n";
        print "ADR homepath for $hdr3 $issue is $3.\n";
        print "Please enter the correct -adrhomepath or just type the $hdr3 number.\n";
        $exitcode = 1;
        last dscriptoptions;
      }
      $tfactlglobal_adrbaseselected{$2} = TRUE;
      $tfactlglobal_adrbasepaths{$2}    = $3;
      $adrbasepath    = $2;
      $TFAIPS_ADRBASE = $2;
      $adrhomepath    = $3;
    }

  } else {

    # Prepare ADR basepaths for interactive mode
    # to be stored in %tfactlglobal_adrbaseselected

    if ( $debugips ) {
      print $ipsfh "$debugtime Validate incidents, interactive mode: before show homepath \n",
                   "$debugtime ========================================================== \n";
    }
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "before show homepath", 'y', 'y');
    $ipsoutput = tfactlshare_call_adrci("show homepath", "yes","no","","","no",
                                        $TFAIPS_ADRBASE,"yes") if (not $DSCRIPT_NOIPS);
    if ( $debugips ) {
      print $ipsfh "$debugtime Validate incidents, ipsout $ipsoutput \n",
                   "$debugtime Validate incidents, after show homepath \n";
    }
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "after show homepath", 'y', 'y');
  } # end if $ipsincident && (not $DSCRIPT_NOIPS)
  # ---------------------------
  # end Validate incidents
  # ---------------------------

  if ( $debugips ) {
    print $ipsfh "$debugtime TFAIPS_ADRBASE $TFAIPS_ADRBASE \n",
                 "$debugtime ============================== \n";
  }
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                    "TFAIPS_ADRBASE $TFAIPS_ADRBASE", 'y', 'y');
  foreach my $key ( keys %tfactlglobal_adrbaseselected ) {
    print $ipsfh "$debugtime tfactlglobal_adrbaseselected.key => $key\n" if $debugips;
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "tfactlglobal_adrbaseselected.key => $key", 'y', 'y');
  }
  foreach my $key ( keys %tfactlglobal_adrbasepaths ) {
    print $ipsfh "$debugtime tfactlglobal_adrbasepaths.key => $key , value => " . $tfactlglobal_adrbasepaths{$key} .   " \n" 
    if $debugips;
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "tfactlglobal_adrbasepaths.key => $key , value => " . $tfactlglobal_adrbasepaths{$key} , 'y', 'y');
  }

  # No ADR homes found
  my @defadrhomepath;
  my $countadrhomepath = 0;
  if ( $ipsoutput =~ /No ADR homes are set/ && (not $DSCRIPT_NOIPS) ) {
    if ( $DSCRIPT_DEF ) {
      $DSCRIPT_NOIPS = TRUE;
    } else {
      print "No ADR homes are set\n";
      print_help("diagcollect", "");
      $exitcode = 1;
      last dscriptoptions;
    }
  } else {
    # --------------------------------------------------------------
    # Set default adrhomepaths when no -adrhomepath switch is present
    # ---------------------------------------------------------------
    if ( $debugips) {
      print $ipsfh "$debugtime tfactldiagcollect_process_cmd Set default adrhomepaths when no -adrhomepath switch is present (sdawhaip).\n",
                   "$debugtime tfactldiagcollect_process_cmd ========================================================================== \n",
                   "$debugtime tfactldiagcollect_process_cmd DSCRIPT_NOIPS $DSCRIPT_NOIPS\n",
                   "$debugtime tfactldiagcollect_process_cmd adrhomepath $adrhomepath\n",
                   "$debugtime tfactldiagcollect_process_cmd DSCRIPT_DEF $DSCRIPT_DEF\n";
    }

    if ( (not $DSCRIPT_NOIPS) && (not (defined $adrhomepath && length $adrhomepath)) ) {
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "Setting the default adrhomepaths when no -adrhomepath switch is present", 'y', 'y');
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "adrhomepath $adrhomepath", 'y', 'y');
      #print "adrhomepath $adrhomepath\n";

      for my $adrbaselocal ( keys (%tfactlglobal_adrbaseselected) ) {
        my @items;
        my $ipsoutput = tfactlshare_call_adrci("show homepath", "yes","no","","","no",
                                             $adrbaselocal,"no");
        my $trcdiagpath = "";
        ### print "$adrbaselocal -> $ipsoutput \n";
        foreach my $line (split /\n/, $ipsoutput) {
          if ( $line =~ m/^(diag.*)/ ) {
            my $diagpath = $1;
            $trcdiagpath .= $diagpath . " ";
            #print "Prepare def homepath $diagpath\n";
            # The default tfa ips collection includes
            # asm, crs & databases
            if ( $diagpath =~ m/diag[\/\\]asm[\/\\]\+asm[\/\\]\+(ASM|asm)[0-9]+/ ||
                 $diagpath =~ m/diag[\/\\]crs[\/\\].*[\/\\]crs/                  ||
                 $diagpath =~ m/diag[\/\\]rdbms[\/\\].*[\/\\].*/ ) {
              #push @defadrhomepath, $diagpath;
              push @items, $diagpath;
              $countadrhomepath++;
            }
          } # end if $line =~ m/^(diag.*)/
        } # end foreach $ipsoutput
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                              "If IPS available => Prepare def homepaths $trcdiagpath", 'y', 'y');

        # Store pairs for DSCRIPT_DEF
        $tfactlglobal_adrbasepaths{$adrbaselocal} = join(",",@items)
      } # end for keys (%tfactlglobal_adrbaseselected)
      # ---------------------------------------------------------------
    } else {
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "Setting the default adrhomepaths when -adrhomepath switch is present", 'y', 'y');
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "adrhomepath $adrhomepath", 'y', 'y');
      if ( defined $adrhomepath && length $adrhomepath ) {
        for my $adrbaselocal ( keys (%tfactlglobal_adrbaseselected) ) {
           $tfactlglobal_adrbasepaths{$adrbaselocal} = $adrhomepath;
        }
      }
    }# end if not $DSCRIPT_NOIPS
  } # end else $ipsoutput =~ /No ADR homes are set/

  if ( $countadrhomepath == 1 && $ips ) {
    $adrhomepath = $defadrhomepath[0];
  }

  # Prepare default adrhomepath for IPS if available
  # ---> @defadrhomepath
  # $adrhomepath was NOT PROVIDED

  if ( $DSCRIPT_DEF && not ($adrhomepath && length $adrhomepath) && (not $DSCRIPT_NOIPS) ) {
    print $ipsfh "$debugtime Array defadrhomepath @defadrhomepath\n" if $debugips;
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "If IPS available => Array defadrhomepath @defadrhomepath", 'y', 'y');
    if ( @defadrhomepath ) {
      $adrhomepath = join(",",@defadrhomepath);
      print $ipsfh "$debugtime Prepare def homepath $adrhomepath\n" if $debugips;
    } else {
      # No entries for default adrhomepaths
      $DSCRIPT_NOIPS = TRUE if (not $DSCRIPT_DEF);
      if ( $debugips ) {
        print $ipsfh "$debugtime No entries for default adrhomepaths.\n",
                     "DSCRIPT_NOIPS $DSCRIPT_NOIPS \n";
      }
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                        "No entries for default adrhomepaths, DSCRIPT_NOIPS $DSCRIPT_NOIPS",
                        'y', 'y');
    }
  } # end if Prepare default adrhomepath for IPS if available

  # Validate adrci version
  my $adrciversioncmd = "";
  my $adrciversion = "";
  my $adrciversion_lo; # e.g. 18.0 => lo=18, hi=0
  my $adrciversion_hi;
  $adrciversioncmd = tfactlshare_call_adrci("show version", "yes","no","","","no",
                                        $TFAIPS_ADRBASE,"no") if (not $DSCRIPT_NOIPS);
  foreach my $line (split /\n/, $adrciversioncmd) {
    if ( $line =~ /ADRCI\: Release ([0-9]+)\.([0-9]+)\..*/ ) {
      $adrciversion = $1 . "." . $2;
      $adrciversion_lo = $1;
      $adrciversion_hi = $2;
    } 
  }

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                    "ips $ips, adrciversion $adrciversion\n", 'y', 'y');  
  ###print "ips $ips, adrciversion $adrciversion\n";
  if ( defined $adrciversion && ($adrciversion_lo < 12 ||  ($adrciversion_lo == 12 && $adrciversion_hi < 2))  ) {
    $DSCRIPT_NOIPS = TRUE if not $ipspre122;
    #print "DSCRIPT_NOIPS $DSCRIPT_NOIPS \n";
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                      "adrciversion ne 12.2, DSCRIPT_NOIPS $DSCRIPT_NOIPS",
                      'y', 'y');
  }

  print $ipsfh "$debugtime ADRCI version $adrciversion\n" if $debugips;

  if ( $oraclehome && length $oraclehome ) {
       $TFAIPS_ADRCIORACLEHOME = $oraclehome;
  }

  # $adrhomepath was PROVIDED in the cmdline
  # set ---> $TFAIPS_ADRCIHOMEPATH
  #
  if ( $adrhomepath && length $adrhomepath ) {
       my @adrbasepathentries = split /\,/ , $TFAIPS_ADRBASE;
       my $ohome;
       if ( $#tfactlglobal_oracle_homes == -1) {
         tfactlshare_get_oracle_homes($tfa_home);
       }
       if ( defined $TFAIPS_ADRCIORACLEHOME && length $TFAIPS_ADRCIORACLEHOME ) {
         $ohome = $TFAIPS_ADRCIORACLEHOME;
       } else {
         $ohome = $tfactlglobal_oracle_homes[0] if defined $tfactlglobal_oracle_homes[0];
       }
       my @adrhpaths = tfactlshare_get_homepaths($ohome, $adrbasepathentries[0]);
       my %adrhpathshash = map {$_ => TRUE} @adrhpaths;

       my @adrhomepathentries = split /\,/ , $adrhomepath;
       my $adrhomepathmatch = TRUE;
       foreach my $hpentry (@adrhomepathentries) {
          if ( not exists $adrhpathshash{$hpentry} ) {
            $adrhomepathmatch = FALSE;
          }
       }

       if ( $debugips ) {
         print $ipsfh "$debugtime tfactldiagcollect_process_cmd Checking -adrhomepath switch ...\n",
                      "$debugtime tfactldiagcollect_process_cmd ================================\n",
                      "$debugtime adrbase $TFAIPS_ADRBASE\n",
                      "$debugtime adrhomepaths @adrhpaths\n";
       }
       tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                         "Checking -adrhomepath switch ...",'y', 'y');
       tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                         "adrbase $TFAIPS_ADRBASE",'y', 'y');
       tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                         "adrhomepaths @adrhpaths",'y', 'y');

       if ( $adrhomepathmatch ) {
         $TFAIPS_ADRCIHOMEPATH    = $adrhomepath;
         $TFAIPS_UNDO_ADRHOMEPATH = $adrhomepath;
       } else {
         print "ADR homepath(s) provided is(are) invalid ...\n";
         print_help("diagcollect", "");
         $exitcode = 1;
         last dscriptoptions;
       }
  }

  # Validate correlation level for -ips if provided
  if ( $adrcorrlvl && length $adrcorrlvl ) {
    $adrcorrlvl = lc($adrcorrlvl);
    if ( $adrcorrlvl ne "basic" && $adrcorrlvl ne "typical" &&
         $adrcorrlvl ne "all" ) {
      print "Warning: Allowed values for -level switch: basic, typical or all.\n";
      print "Defaulting correlation level to basic.\n";
      $adrcorrlvl = "basic";
    } 
    $TFAIPS_CORRLVL = $adrcorrlvl;
  } # end if $adrcorrlvl && length $adrcorrlvl

  # collect from clusterwide by default
  if (isOfflineMode($paramfile)) {
    $DSCRIPT_OPTS .= " -node local";
  } elsif (isODADom0() == 1) {
     if ($node) {
      print "ODA Dom0 can collect data from local node only.";
      $exitcode = 1;
      last dscriptoptions;
      #exit 0;
     }
     $DSCRIPT_OPTS .= " -node local";
  } else {
    if (!($node) && !($exadatacell) && ($EXADATA == 1) && !($nocell)) {
      print "Collecting data for all nodes and cells\n";
      $DSCRIPT_OPTS .= " -node all" if not ($event || $xmlfilters);
      $RUNDIAGCOLLECTINCELLS = 1;
      $cells = "all";
    }
    elsif ( !($node) && ($EXADATA == 1) && $nocell ) {
      print "Collecting data for all nodes\n";
      $DSCRIPT_OPTS .= " -node all" if not ($event || $xmlfilters);
    }
    elsif ( !($node) && ($EXADATA == 0) ) {
      print "Collecting data for all nodes\n";
      $DSCRIPT_OPTS .= " -node all" if not ($event || $xmlfilters);
    }
    elsif (!($node) && $exadatacell) {
      print "Collecting data for $exadatacell cell(s)\n";
      # Update $onlycell to 1 later at the end
      # $onlycell = 1;
    }
    elsif ($node && !($exadatacell)) {
      print "Collecting data for $node node(s)\n";
    }
    elsif ($node && $exadatacell) {
      print "Collecting data for $node node(s) and $exadatacell cell(s)\n";
    }
  }

  # appending -copy if there is no -copy or -nocopy flag
  # do not append -copy if just collecting from local node
  if (! ($copy) && ! ($copy eq 0) && !($node eq "local"))  {
    $DSCRIPT_OPTS .= " -copy";
  }

  # for -acfs then add the crsdata directory 
  if ( exists $diaghashoptions{"acfs"} ) {
     my $oracle_base = get_oracle_base($tfa_home);
     my $acfsdir = catfile($oracle_base,"crsdata",$hostname,"acfs");
     dbg(DBG_VERB,"Adding acfs directory : $acfsdir \n");
     if ( $collectdir ) {
       $DSCRIPT_OPTS =~ s/-collectdir /-collectdir $acfsdir,/;
     }
       else {
       $DSCRIPT_OPTS .= " -collectdir $acfsdir"
     }
     dbg(DBG_VERB,"DSCRIPT OPTS afer adding  acfs directory : $DSCRIPT_OPTS \n");

  }

  # zdlra specific
  if ( exists $diaghashoptions{"zdlra"} ) {
    my $ohome = get_crs_home($tfa_home);
    my $srvctl = catfile($ohome, "bin", "srvctl");
    my $command = "$srvctl config database";
    my @out = `$command 2>&1`;
    chomp(@out);
    my $dbs = join("," , @out);
    if ( $DSCRIPT_OPTS !~ /-database/ ) {
      $DSCRIPT_OPTS .= " -database $dbs";
    }
    if ( $DSCRIPT_OPTS !~ /-awr/ ) {
      $DSCRIPT_OPTS .= " -awrhtml";
    }
  }


  # assign output file name
  if (! $output ) {
        my $dateNtime = strftime "%a %b %d %H:%M:%S %Z %Y", localtime;
        $dateNtime =~ s/\s+/ /g;
        $dateNtime =~ s/\s+$//; # remove space at the end
        $dateNtime =~ s/\s/_/g;
        $dateNtime =~ s/:/_/g;
        if ($xmlfilters) {
          my $opt = "tfa_srdc_$xmlfilters" . "_$dateNtime";
          $DSCRIPT_OPTS .= " -z $opt";
        } else {
          $DSCRIPT_OPTS .= " -z tfa_$dateNtime";
        }
  }
  else {
        $DSCRIPT_OPTS =~ s/-z $output//;
        if (! ($output =~ /tfa_/) ) {
          $output =~ s/^/tfa_/;
        }
        $output =~ s/:/_/g;
        $output = lc($output);
        $DSCRIPT_OPTS .= " -z $output";
  }
  # assign unique tag name
  if (! $tag ) {
        my $dateNtime = strftime "%a %b %d %H:%M:%S %Z %Y", localtime;
        $dateNtime =~ s/\s+/ /g;
        $dateNtime =~ s/\s+$//; # remove space at the end
        $dateNtime =~ s/\s/_/g;
        $dateNtime =~ s/:/_/g;
        $dateNtime =~ s/\+|\-//g;
        if (!($node) && !($exadatacell) && ($EXADATA == 1) && !($nocell) ) {
          $dateNtime = "collection_".$dateNtime."_node_all_cell_all";
        }
        elsif ( !($node) && ($EXADATA == 1) && $nocell ) {
          $dateNtime = "collection_".$dateNtime."_node_all";
        }
        elsif ( !($node) && ($EXADATA == 0) ) {
          $dateNtime = "collection_".$dateNtime."_node_all";
        }
        elsif (!($node) && $exadatacell) {
          $dateNtime = "collection_".$dateNtime."_cell_".$exadatacell;
        }
        elsif ($node && !($exadatacell)) {
          $dateNtime = "collection_".$dateNtime."_node_".$node;
        }
        elsif ($node && $exadatacell)  {
          $dateNtime = "collection_".$dateNtime."_node_".$node."_cell_".$exadatacell;
        }
        $dateNtime =~ s/,/_/g;
        if ($xmlfilters) {
          my $change = "srdc_$xmlfilters" . "_";
          $dateNtime =~ s/^/$change/;
        }
        $DSCRIPT_OPTS .= " -tag $dateNtime";
  }
  else {
        $DSCRIPT_OPTS =~ s/-tag $tag//;

        # check tag
        $tag = trim($tag);
        if ( $tag =~ /[^a-zA-Z0-9_-]/ ) {
                print "\nError: Please enter a valid TFA tag [A-Za-z0-9_-]\n";
                print_help ("diagcollect", "");
                $exitcode = 1;
                last dscriptoptions;
        }

        $tag =~ s/:/_/g;
        my $repository = getCurrentRepository($tfa_home);
        if ( (-d catdir($repository,"$tag")) && ( ! $onlycell ) ) {
                print "\nTag already exists. ";
                 my $count;
                 for ($count = 1; $count <= 10; $count++) {
                     my $temp_tag = $tag."_".$count;
                     if (-d catdir($repository,"$temp_tag")) {
                        next;
                     }
                     else {
                        $tag = $temp_tag;
                        last;
                     }
                }
                if (-d catdir($repository,"$tag")) {
                   print "\nPlease specify a different tagname\n";
                   $exitcode = 1;
                   last dscriptoptions;
                }
                print "Using a new tag: $tag\n";
        }
        if (! $onlycell){
           #append 0 to distinguish the tagname as user specified
           $DSCRIPT_OPTS .= " -tag 0$tag";
        } else {
           $DSCRIPT_OPTS .= " -tag $tag";
        }
  }

  if (! $logid ) {
        my $dateNtime = strftime "%Y%m%d%H%M%S", localtime;
        $dateNtime =~ s/\s+/ /g;
        $dateNtime =~ s/\s+$//; # remove space at the end
        $dateNtime =~ s/\s/_/g;
        $dateNtime =~ s/:/_/g;
        $DSCRIPT_OPTS .= " -logid $dateNtime";
  }
  my $sudo_user = $ENV{SUDO_USER};
  my $sudo_command = $ENV{SUDO_COMMAND};
  if ( $sudo_command =~ /tfactl/ )
  {
    print_help ("diagcollect", "sudo is not supported for tfactl diagcollect");
    $exitcode = 1;
    last dscriptoptions;
  }
  if ( $symlink && ! ($for) ) {
    print_help ("diagcollect", "Missing time input -for");
    $exitcode = 1;
    last dscriptoptions;
  }

  if (!($node) && $exadatacell) {
    $onlycell = 1;
  }

  if ( $nocell ) {
    $DSCRIPT_OPTS =~ s/\s-nocell//;
  }

  # Remove any dup spaces
  $DSCRIPT_OPTS =~ s/ +/ /g;

  print $ipsfh "$debugtime tfactldiagcollect_process_cmd DIAGCOLLECT OPTIONS: $DSCRIPT_OPTS\n" if $debugips;
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
                                "AFTER PROCESSING $DSCRIPT_OPTS",
                    'y', 'y');

} else {
  # ipsresumeips section
  if ( $debugips ) {
    print $ipsfh "$debugtime tfactldiagcollect_process_cmd ipsresumeips section, collectionid $ipsresumeips\n",
                 "$debugtime tfactldiagcollect_process_cmd ------------------------------------------------\n";
    print "tfactldiagcollect_process_cmd ipsresumeips section, collectionid $ipsresumeips\n",
          "tfactldiagcollect_process_cmd ------------------------------------------------\n";
  }

  @ARGV = ( "diagcollect" );

  my $resumeok = FALSE;
  my $collectiondir;
  my $storedargs;
  my $message ="$localhost:resumeips:$ipsresumeips";
  my $command = buildCLIJava($tfa_home,$message);
  my @cli_output = tfactlshare_runClient($command);
  foreach my $line ( @cli_output ) {
    if ( $debugips ) {
      print $ipsfh "$debugtime tfactldiagcollect_process_cmd line $line\n";
      print "tfactldiagcollect_process_cmd line $line\n";
    } 
    if ( $line =~ /SUCCESS/ ) {
      $resumeok = TRUE;
    } elsif ( $line =~ /FAILED/ ) {
      $resumeok = FALSE;
    } elsif ( $line =~ /(\S*)\s(.*)/ ) {
      $collectiondir = catdir($1,$ipsresumeips);
      $storedargs = $2;
      $TFAIPS_COLLECTIONDIR = $collectiondir;
      # su section
      $TFAIPS_COLLECTIONDIR_REL = $collectiondir;
      $TFAIPS_COLLECTIONID  = $ipsresumeips;
      if ( $debugips ) {
        print $ipsfh "$debugtime tfactldiagcollect_process_cmd collectiondir $collectiondir\n",
                     "$debugtime tfactldiagcollect_process_cmd storedargs    $storedargs\n";
        print "tfactldiagcollect_process_cmd collectiondir $collectiondir\n",
              "tfactldiagcollect_process_cmd storedargs    $storedargs\n";
      }
    }
  }

  if ( $resumeok ) {
    if ( not -d $collectiondir ) {
      print "Directory $collectiondir does not exist.\n";
      print "Collection $ipsresumeips cannot be resumed.\n";
      $exitcode = 1;
      last dscriptoptions;
    }

    if ( $debugips ) {
      print $ipsfh "$debugtime tfactldiagcollect_process_cmd Completed - resumeips ...\n";
      print "tfactldiagcollect_process_cmd Completed - resumeips ...\n";
    }

    no strict 'refs';
    open (RF, catfile($collectiondir,"state.log")) || die "Cant open ".catfile($collectiondir,"state.log")."\n";
    while(<RF>) {
      chomp;
      if ( /(.*)=(.+)/ ) {
        my $var = $1;
        my $val = $2;
        #print "$1 = $2\n";
        if ( $var eq "tfactlglobal_adrbasepaths" ) {
          if ( $val =~ /(.*)\.(.*)/ ) {
            my $hashkey = $1;
            my $hashval = $2;
            $tfactlglobal_adrbasepaths{$hashkey} = $hashval;
          }
        } elsif ( $var eq "createpackage" ) {
          if ( $val =~ /(.*)\.(.*)\.(.*)/ ) {
            my $localbase = $1;
            my $localhomepath = $2;
            my $localmsg = $3;
            $ipsresumeips_createpack{$localbase . "." . $localhomepath} = $localmsg;
          }
        } else {
          $$var = $val;
        }
      }
   }
   use strict;
   close(RF);
   $DSCRIPT_OPTS = $storedargs;

   if ( $debugips ) {
     print $ipsfh "$debugtime tfactldiagcollect_process_cmd Read state.log file\n";
     print "tfactldiagcollect_process_cmd Read state.log file\n";
   }

   # Resume operation successful
   # Remove entry from TFAIps
   $resumeok = FALSE;
   my $message ="$localhost:removeips:$ipsresumeips";
   my $command = buildCLIJava($tfa_home,$message);
   my @cli_output = tfactlshare_runClient($command);
   foreach my $line ( @cli_output ) {
     print $ipsfh "$debugtime tfactldiagcollect_process_cmd line for msg removeips -> $line\n" if $debugips;
     if ( $line =~ /SUCCESS/ ) {
       $resumeok = TRUE;
     } elsif ( $line =~ /FAILED/ ) {
       $resumeok = FALSE;
     }
   } # end foreach
   if ( not $resumeok ) {
     print "Resume operation for TFA IPS collection $ipsresumeips failed.\n";
     return;
   }

  } else {
    print "Resume operation for TFA IPS collection $ipsresumeips failed.\n";
    return;
  } # end if $resumeok
    # ----------------

  if ( $debugips ) {
    print $ipsfh "$debugtime tfactldiagcollect_process_cmd resume operation ok ....\n",
                 "$debugtime tfactldiagcollect_process_cmd TFAIPS_COLLECTIONDIR $TFAIPS_COLLECTIONDIR\n",
                 "$debugtime tfactldiagcollect_process_cmd TFAIPS_COLLECTIONID $TFAIPS_COLLECTIONID\n";
    print "tfactldiagcollect_process_cmd resume operation ok ....\n";
  }

  if ( $IS_WINDOWS ) {
    my $manageipsfile;
    if ( $TFAIPS_COLLECTIONDIR =~ /(.*)[\/\\]$TFAIPS_COLLECTIONID.*/ ) {
      $manageipsfile    = catfile($1,$TFAIPS_COLLECTIONID . "_manageips_completed.log");
    }
    print $ipsfh "$debugtime tfactldiagcollect_process_cmd Trying to remove " . $manageipsfile . "\n" if $debugips;
    `$RM $manageipsfile` if -e $manageipsfile;
    # remove previous mstr_parrips*.log files if any
    my $prevmasterfiles = $TFAIPS_COLLECTIONDIR . '\mstr_parrips*.log';
    print $ipsfh "$debugtime tfactldiagcollect_process_cmd trying to remove $RM " . $prevmasterfiles . "\n" if $debugips;
    my $rmout = `$RM $prevmasterfiles` if $debugips;
  } # end if $IS_WINDOWS 

  if ( $debugips ) {
    print $ipsfh "$debugtime tfactldiagcollect_process_cmd collectiondir $collectiondir\n",
                 "$debugtime tfactldiagcollect_process_cmd storedargs $storedargs\n",
                 "$debugtime tfactldiagcollect_process_cmd DSCRIPT_OPTS $DSCRIPT_OPTS\n",
                 "$debugtime tfactldiagcollect_process_cmd TFAIPS_ADRCIHOMEPATH $TFAIPS_ADRCIHOMEPATH\n" .
                 "$debugtime tfactldiagcollect_process_cmd TFAIPS_ADRCIORACLEHOME $TFAIPS_ADRCIORACLEHOME\n" .
                 "$debugtime tfactldiagcollect_process_cmd TFAIPS_OHOME $TFAIPS_OHOME\n" .
                 "$debugtime tfactldiagcollect_process_cmd TFAIPS_ADRBASE $TFAIPS_ADRBASE\n" .
                 "$debugtime tfactldiagcollect_process_cmd TFAIPS_ADRHOMEPATH $TFAIPS_ADRHOMEPATH\n" .
                 "$debugtime tfactldiagcollect_process_cmd TFAIPS_CORRLVL $TFAIPS_CORRLVL\n" .
                 "$debugtime tfactldiagcollect_process_cmd TFAIPS_INCIDENTNMBR $TFAIPS_INCIDENTNMBR\n" .
                 "$debugtime tfactldiagcollect_process_cmd TFAIPS_PROBLEMNMBR $TFAIPS_PROBLEMNMBR\n" .
                 "$debugtime tfactldiagcollect_process_cmd TFAIPS_PROBLEMKEY $TFAIPS_PROBLEMKEY\n" .
                 "$debugtime tfactldiagcollect_process_cmd TFAIPS_UNDO_ADRBASEPATH $TFAIPS_UNDO_ADRBASEPATH\n" .
                 "$debugtime tfactldiagcollect_process_cmd TFAIPS_UNDO_ADRHOMEPATH $TFAIPS_UNDO_ADRHOMEPATH\n";
  } # end if $debugips
}# end if $ipsresumeips


} # end if $ARGV[0] =~ /^diagcollect$/ || $ARGV[0] =~ /^collect$/

  # Read th commands
  my $command1 = shift(@ARGV);
  my $command2 = shift(@ARGV);
  my $switch_val = $command1;

  if ($switch_val eq "purge" )
        {
                if ( ! $command2 ) {
			print_help ("purge", "");
			return 1;
                }

		if (defined $command2 && ($command2 eq "-h" || $command2 eq "-help")) {
			print_help ("purge", "");
			return;
		}

                if ( $command2 eq "-older" ) {
			my $command3 = shift(@ARGV);
			if ( $command3 ) {
				if ( !($command3 =~ /^(\d+)d{1}$/ || $command3 =~ /^(\d+?)h{1}$/)) {
					print "The time entered is invalid: $command3\n";
					print "Some examples of valid time entries for -older flag: 2h, 10d\n";
					return 1;
				} else {
					$purge_time = $command3;
				}
			} else {
				print_help ("purge", "");
				return 1;
			}

			my $command4 = shift(@ARGV);
			if ( $command4 ) {
				if ( $command4 eq "-force" ) {
					$purge_force = 1;
				} else {
					print_help ("purge", "");
					return 1;
				}
			}
		} else {
			print_help ("purge", "");
			return 1;
		}
                $PURGE = 1;
        }
  if ($switch_val eq "run" )
        {    
          if ( ! $command2 ) {
            print_help ("run", "");
            return 1;
          }
          if (defined $command2 && ($command2 eq "-h" || $command2 eq "-help")) {
                print_help("run");
          }
          $switch_val = $command2 ;
          {
            if ( exists $tfactlglobal_exttools{$command2}  ) {
              tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command"
                             . " Tool found  $command2", 'y', 'y');
              tfactlshare_trace(5, "tfactl (PID = $$) " . 
                            "tfactldiagcollect_process_command " .
                            "Processing command $command1 for tool $command2",
                            'y', 'y');
              $tfactlglobal_hash{'srcmod'} = "tfactladmin"; # src mod
              $tfactlglobal_hash{'cmd'} = $command2; # toolname
              $tfactlglobal_argv[0] = $command2;
              $tfactlglobal_argv[1] = $command1;
              if ( $tfactlglobal_exttools{$command2}->{CLUSTERWIDE} eq "true-disable" ) {
                tfactlshare_execute_clusterwide("local $command1 $command2", "@ARGV" );

              }
              tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command"
                             . " CHECK CLUSTERWIDE ...", 'y', 'y');
            } 
            elsif ($switch_val eq "inventory") { $RUNINVENTORY = 1 }
            elsif ($switch_val eq "cellinventory" ) {  
                $cell = shift(@ARGV);
                if ( ! $cell ) {
                  print "Cell name is missing from input.\n";
                  exit -1;
                }
                else {
                  trim($cell);
                  if ($cell eq "-all") {
                    $RUNINVENTORYINCELLS = 1; 
                  }
                  else {
                    $RUNCELLINVENTORY = 1; 
                  }
                }
            }
            elsif ($switch_val eq "discovery" ) { $RUNDISC = 1 }
            elsif ($switch_val eq "scan" ) { $RUNSCAN = 1 }
            elsif ($switch_val eq "cellscan" ) {
                $cell = shift(@ARGV);
                if ( ! $cell ) {
                  print "Cell name is missing from input.\n";
                  exit 1;
                }
                else {
                  trim($cell);
                  if ($cell eq "-all") {
                    $RUNODSCANINCELLS = 1;
                  }
                  else {
                    $RUNCELLODSCAN = 1;
                  }
                }
            }
            else { if ( defined($command2) && ($command2 ne "-h") && ($command2 ne "-help") ) {
                     print_help ("run", "Invalid argument $command2");
                     exit 1;
                   }
            } # end else
          }
        }
  elsif ($switch_val eq "rediscover" )
        {
	  # Disabled root check for Cloud Support
          if ( (not $ISCLOUD) && (not $IS_TFA_ADMIN) ) {
                  print "\nAccess Denied: Only TFA Admin can run this command\n\n";
                  exit 1;
          }

          $RUNREDISC = 1;
          $RDMODE = shift(@ARGV);
	  $RDAUTO = shift(@ARGV);
        }
  elsif ($switch_val eq "diagcollect" || $switch_val eq "collect" )
        {
          $DIAGCOLLECT = 1;
          if ($onlycell) {
            #print "$onlycell is set, so we run for $cell only\n";
            $DIAGCOLLECT = 0;
          }

          #if ( $RUNDIAGCOLLECTCELL || $RUNDIAGCOLLECTINCELLS) {
          #     print "Setting DIAGCOLLECT = 0\n";
          #     $DIAGCOLLECT = 0;
          #}
        }
 # elsif ($switch_val eq "rundiagcollect" )
 #       {
 #         $RUNDIAGCOLLECT = 1;
 #       }

  # Dispatch the command
  tfactlshare_pre_dispatch();
  tfactldiagcollect_dispatch();

} # last dscriptoptions:

  # Purge ipslogfname if needed
  my $fsize = osutils_getFileSize($ipslogfname);
  unlink $ipslogfname if $fsize == 0;

  return $exitcode;
} # end sub tfactldiagcollect_process_command

sub tfactldiagcollect_cp_xmlfilters_to_nodes
{
  my $tfa_home = shift;
  my $xmlfilters_orig = shift;
  my $xmlfilters_tag  = shift;
  my $xmlfilters_fp   = shift;

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
              "in cp_xmlfilters_to_tmp tfa_home:$tfa_home xmlfilters_orig:$xmlfilters_orig _tag:$xmlfilters_tag _fp:$xmlfilters_fp",
              'y', 'y');

  if ( not -e $xmlfilters_fp ) {
    my @cp_args = ("$xmlfilters_orig","$xmlfilters_fp","1");
    osutils_cp(@cp_args);
  }

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
              "Copied $xmlfilters_orig $xmlfilters_fp",
              'y', 'y');

  my @TFA_HOSTS = getListOfOtherNodes( $tfa_home );
  foreach my $node ( @TFA_HOSTS )
  {
    #print "Copying file $xmlfilters_fp to $node\n";
    copyTagFile($tfa_home,"srdcfile-TAG-$xmlfilters_tag", $node );
  }
}

sub tfactldiagcollect_get_oracle_home_ip
{
  my $tfa_home = shift;
  my @ohomes = ();
  @ohomes = osutils_get_oracle_home_path();
  chomp(@ohomes);

  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_process_command " .
              "tfactldiagcollect_get_oracle_home_ip Homes:@ohomes",
              'y', 'y');
  my $i;
  if ( $#ohomes > 0 )
  {
    for($i = 0; $i <= $#ohomes; $i++ )
    {
      if ( -d $ohomes[$i] ) {
        my $si = $i + 1;
        print "$si. $ohomes[$i]\n";
      }
    }
    print "Select ORACLE_HOME from above list : 1-$i [1] ";
    my $ans = <>;
    chomp($ans);
    $ans = 1 if ( ! $ans );
    if ( $ans =~ /\d+/ && $ans <= $i )
    {
      print "Selected value is : $ans ( " . $ohomes[$ans-1] . " )\n";
      return $ohomes[$ans-1];
    }
     else
    {
      print "Error: Invalid input\n";
      exit;
    }
  }
   elsif ( $ohomes[0] )
  {
    print "Selected ORACLE_HOME $ohomes[0]\n";
    return $ohomes[0];
  }
   else
  {
    my $invalid = 1;
    my $oraexe;
    my $ip;
    while ( $invalid ) {
       print "Enter value for ORACLE_HOME : ";
       $ip = <>;
       chomp($ip);
       $oraexe = catfile($ip,"bin","oracle");
       if ( -f $oraexe ) 
       { 
          $invalid = 0;
       } else {
          print "Invalid ORACLE_HOME entered please try again. \n";
       } 
    }
    return $ip;
  }
}

########
# NAME
#   tfactldiagcollect_get_event_time
#
# DESCRIPTION
#   This function gets the event.
#
# PARAMETERS
#   $eventsref - Reference to the events array (e.g. ORA-00600)
#   $grepfor   - Grep for this expression
#
# RETURNS
#   The tuple (Timestamp, db.<dbname>.<DBNAME>.error)
#
# NOTES
#   Only tfactl_main() calls this routine.
########
sub tfactldiagcollect_get_event_time
{
  my $tfa_home         = shift;
  my $eventsref        = shift;
  my $grepfor          = shift;
  my $checktimerange   = shift;
  my $excludeeventsref = shift;
  my @excludeevents =@$excludeeventsref;
  my @events =@$eventsref;
  my $firstevent;
  my $lastevent;

  if ( not length $checktimerange ) {
    $checktimerange = FALSE;
  }
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_get_event_time " .
               "in get_event_time events:@events grepfor:$grepfor ",
               'y', 'y');

  return if ( ! $events[0] );

  my @events2list = ();
  my $tfactl = catfile($tfa_home, "bin", "tfactl");
  $tfactl .= ".bat" if ( $IS_WINDOWS );
  foreach my $event (@events)
  {
    # e.g. $event = ORA-00600

    my @a = ();
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_get_event_time " .
               "command to search event: $tfactl events -search \"$event\" -node local -last 7d ",
               'y', 'y');

    @a = `$tfactl events -search \"$event\" -node local -last 7d`;
    @a = grep { $_ !~ /^\s*$/ } @a;
    @a = grep { $_ !~ /^\s*\-*$/ } @a;
    @a = grep { $_ !~ /^\s*Output from host.*$/ } @a;
    @a = grep { $_ !~ /^\s*Event.*$/ } @a;
    @a = grep { $_ !~ /INFO|ERROR|WARNING/ } @a;
    @a = tfactlshare_uniq(@a);
    
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_get_event_time " .
               "output search event: @a ",
               'y', 'y');
    my @atemp;
    foreach my $item ( @a ) {
      my @colums = split "]:", $item;
      $colums[0] =~ s/\.\d+/ ERROR:/g;
      $colums[0] =~ s/\[//g;
      $colums[1] =~ s/\[//g;
      if ( $colums[1] =~ /\+ASM/ ) {
        $colums[1] =~ s/asm\.(.*)/db\.\.$1/g;
      } elsif ( $colums[1] =~ /\+APX/ ) {
        $colums[1] =~ s/apx\.(.*)/db\.\.$1/g;
      } elsif ( $colums[1] =~ /\+IOS/ ) {
        $colums[1] =~ s/ios\.(.*)/db\.\.$1/g;
      }
      $colums[1] .= ".error =";
      push @atemp, join(" ",@colums);
    }

    @a = @atemp;
    chomp(@a);
    if ( $grepfor ) {
      $grepfor =~ s/\+/\\\+/g;
      @a = grep{/$grepfor/i} @a;
    }
   
    # remove any exclude patterns
    if ( @excludeevents ) {
       tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_get_event_time " .
                    "in checking for exclude events:@events excludeevents:@excludeevents ",
                    'y', 'y');
       foreach my $grepper ( @excludeevents ) {
           @a = grep{!/$grepper/i} @a;
       }
    }

    foreach my $row (@a)
    {
      # Format for $row Mon/dd/yyyy hh24:mi:sec ERROR: 

      if ( $row =~ /(\w+\/\d+\/\d+ \d+:\d+:\d+) \w+:  ([^=]+) =  (.*)/ )
      {
        #Sep/30/2014 04:05:12 ERROR: crs.rws3060021.error = [OCSSD(5568)]CRS-1610: Network communication with node rwsal05 (1) missing for 90% of timeout interval.  Removal of this node from cluster in 2.030 seconds
        my $uts = getValidDateFromString($1, "time");
        # Prepare events lists
        push @events2list, "$uts $1|$2 = $3" if $uts ne "invalid";
      }
    }
  }

  # sort events2list
  @events2list    = sort { $b <=> $a } @events2list;

  # checktimerange
  # ==============
  if ( $checktimerange ) {
    if ( @events2list ) {
      my $firstndx = 0;
      my $lastndx = @events2list - 1;
      # print "first $firstndx last $lastndx\n";
      if ( $events2list[$firstndx] =~ /(\d+) (.*)\|(.*) = (.*)/ ) {
        $lastevent = $1;
      }
      if ( $events2list[$lastndx] =~ /(\d+) (.*)\|(.*) = (.*)/ ) {
        $firstevent = $1;
      }
    } else {
      $firstevent = "invalid";
      $lastevent  = "invalid";
    }

    # print "returning ( $firstevent, $lastevent)\n";
    return ( $firstevent, $lastevent, @events2list);
  }


  my $max_events = 10;
  $max_events = $ENV{TFA_EVENTS_TO_LIST} if ( $ENV{TFA_EVENTS_TO_LIST} );
  my @ips = ();  # Timestamp
  my @keys = (); # db.<dbname>.<DBNAME>.error
  my $i = 0;
  print "\n";
  # ==============================================
  # foreach my $line (sort {$b <=> $a} @events2list)
  foreach my $line (@events2list)
  {
    # line format (order by uts desc),
    # uts Timestamp | db.<dbname>.<DBNAME>.error = <Error message>
    # $1     $2                $3                        $4
    # ------------------------------------------------------------
    # $2 = Timestamp
    # $3 = db..+ASM1.error
    #      db._mgmtdb.-MGMTDB.error
    # $4 = Error
    # removex
    if ( $line =~ /(\d+) (.*)\|(.*) = (.*)/ )
    {
=head
      $ips[$i] = $2;
      $keys[$i] = $3;
      $i++;
=cut
      my @a = split(/\./, $3);
      my $k;
      if ( $a[0] eq "db" ) {
        if (length $a[1] ) {
          $k = $a[1];
        } elsif (length $a[2] ) {
          $k = $a[2]; # Support APX & ASM.
        } else {
          next;
        }
      }

      $k = "CRS" if ( $a[0] eq "crs" );

      $ips[$i] = $2;
      $keys[$i] = $3;
      $i++;

      # index. Timestamp : [database] Error
      print "$i. $2 : [$k] $4\n";
    } # end if $line =~ /(\d+) (.*)\|(.*) = (.*)/
    last if ( $i == $max_events );
  } # end foreach my $line (sort {$b <=> $a} @events2list)
  # =====================================================

  if ( $i == 0 )
  {
    print "Could not find any events\n";
    exit;
  }

  my $ans = tfactlshare_get_choice ( 1, $i,
                 "\nPlease choose the event : " .
                 "1-$i [1] ", 1 );
  if ( $ans =~ /\d+/ && $ans <= $i )
  {
    print "Selected value is : $ans ( " . $ips[$ans-1] . " )\n";
    # Return Timestamp, db.<dbname>.<DBNAME>.error
    return ($ips[$ans-1], $keys[$ans-1]);
  }
   else
  {
    print "Error: Invalid input\n";
    exit;
  }
} # end sub tfactldiagcollect_get_event_time

########
# NAME
#   tfactldiagcollect_dispatch
#
# DESCRIPTION
#   Dispatch de command.
#
# PARAMETERS
#
# RETURNS
#
########
sub tfactldiagcollect_dispatch
{
 if ($PURGE) { purgeRepository( $tfa_home, $purge_time, $purge_force ); $PURGE=0; $purge_force = 0; }
 elsif ($RUNINVENTORY)  { runTFAInventory($tfa_home, $CLUSTERWIDE, $silent); $RUNINVENTORY=0; }
 elsif ($RUNINVENTORYINCELLS) {
       if ( $current_user eq "root" ) {
         runInventoryInCells($tfa_home);
       } else {
               print "\nWARNING: User \'$current_user\' is not allowed to ".
                     "run Inventory on Storage Cells\n"; }
       $RUNINVENTORYINCELLS=0; }
 elsif ($RUNDISC) { runRacCheckDiscovery($tfa_home); $RUNDISC=0; }
 elsif ($RUNSCAN)  { runODScan($tfa_home); $RUNSCAN=0; }
 elsif ($RUNODSCANINCELLS) {
       if ( $current_user eq "root" ) {
         runODScanInCells($tfa_home);
       } else {
               print "\nWARNING: User \'$current_user\' is not allowed to ".
                     "run On Demand Scan on Storage Cells\n"; }
       $RUNODSCANINCELLS=0; }
 elsif ($RUNCELLODSCAN) {
       if ( $current_user eq "root" ) {
         runCellODScan($tfa_home, $cell);
       } else {
               print "\nWARNING: User \'$current_user\' is not allowed to ".
                     "run On Demand Scan on Storage Cells\n"; }
       $RUNCELLODSCAN=0; }
 elsif ($RUNREDISC) { runReDiscovery($tfa_home, $RDMODE, $RDAUTO); $RUNREDISC=0; }
# elsif ($RUNDIAGCOLLECT)  { runDiagCollect($tfa_home,$CLUSTERWIDE,$DSCRIPT_OPTS); 
#                            $RUNDIAGCOLLECT=0; $CLUSTERWIDE = 0; undef($DSCRIPT_OPTS); }
 elsif ($RUNCELLINVENTORY) {
       if ( $current_user eq "root" ) {
         my $log;
         runCellInventory($tfa_home, $cell, 1, $log, 0);
       } else {
               print "\nWARNING: User \'$current_user\' is not allowed to ".
                     "run Inventory on Storage Cells\n"; }
       $RUNCELLINVENTORY=0; }

 #elsif ($RUNDIAGCOLLECTCELL) { runDiagCollectCell($tfa_home,$CLUSTERWIDE,$DSCRIPT_OPTS); }
 if ( $RUNDIAGCOLLECTCELL ) {
   if ( $current_user eq "root" ) {
     runCellDiagcollection($tfa_home, $cells, $DSCRIPT_OPTS);
   }
   $RUNDIAGCOLLECTINCELLS = 0;
   $RUNDIAGCOLLECTCELL=0;
 }

 ### print "\n\nDSCRIPT_IPS $DSCRIPT_IPS DSCRIPT_DEF $DSCRIPT_DEF \n\n";
 #if ($RUNDIAGCOLLECTINCELLS && not ($DSCRIPT_IPS || $DSCRIPT_DEF)) {
 if ( $RUNDIAGCOLLECTINCELLS ) {
  if ( $current_user eq "root" ) {
    if ( $DIAGCOLLECT ) {
      # run cell collection function in background
      runDiagcollectionInCells($tfa_home, $DSCRIPT_OPTS, $cells, 1);
    } else {
      # do not run cell collection function in background
      runDiagcollectionInCells($tfa_home, $DSCRIPT_OPTS, $cells, 0);
    }
  }
  $RUNDIAGCOLLECTINCELLS = 0;
}

 if ( $ISJCS && ! $onlyjcs ) {
	tfactldiagcollect_runDiagCollectOnJCSNodes($tfa_home, $diag_args, $DSCRIPT_OPTS);
 }  

 if ($DIAGCOLLECT)  { runDiagCollectUser($tfa_home,$CLUSTERWIDE,$DSCRIPT_OPTS); $DIAGCOLLECT=0; }

 return;
}


########
# NAME
#   tfactldiagcollect_process_help
#
# DESCRIPTION
#   This function is the help function for the tfactldiagcollect module.
#
# PARAMETERS
#   command     (IN) - display the help message for this command.
#
# RETURNS
#   1 if command found; 0 otherwise.
########
sub tfactldiagcollect_process_help 
{
  my ($command) = shift;       # User-specified argument; show help on $cmd. #

  my ($desc);                                # Command description for $cmd. #
  my ($succ) = 0;                         # 1 if command found, 0 otherwise. #

  if (tfactldiagcollect_is_cmd ($command)) 
  {                              # User specified a command name to look up. #
    $desc = tfactlshare_get_help_desc($command);
    tfactlshare_print "$desc\n";
    $succ = 1;
  }

  return $succ;
}

########
# NAME
#   tfactldiagcollect_is_cmd
#
# DESCRIPTION
#   This routine checks if a user-entered command is one of the known
#   TFACTL internal commands that belong to the tfactldiagcollect module.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is one of the known commands, false otherwise.
########
sub tfactldiagcollect_is_cmd 
{
  my ($arg) = shift;

  return defined ($tfactldiagcollect_cmds {$arg});

}

########
# NAME
#   tfactldiagcollect_is_wildcard_cmd
#
# DESCRIPTION
#   This routine determines if an tfactldiagcollect command allows the use 
#   of wild cards.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is a command that can take wildcards as part of its argument, 
#   false otherwise.
########
sub tfactldiagcollect_is_wildcard_cmd 
{
  my ($arg) = shift;

  return defined ($tfactldiagcollect_cmds{ $arg }) &&
    (tfactlshare_get_cmd_wildcard($arg) eq "True" ) ;
}

########
# NAME
#   tfactldiagcollect_is_no_instance_cmd
#
# DESCRIPTION
#   This routine determines if a command can run without an TFAMain instance.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is a command that can run without an TFAMain instance 
#   or does not exist, false otherwise.
#
# NOTES
#   The tfactldiagcollect module currently supports no command that can run 
#   without an TFAMain instance.
########
sub tfactldiagcollect_is_no_instance_cmd 
{
  my ($arg) = shift;

  return !defined ($tfactldiagcollect_cmds{ $arg }) ||
    (tfactlshare_get_cmd_noinst($arg) ne "True" ) ;
}

########
# NAME
#   tfactldiagcollect_syntax_error
#
# DESCRIPTION
#   This function prints the correct syntax for a command to STDERR, used 
#   when there is a syntax error.  This function is responsible for 
#   only tfactldiagcollect commands.
#
# PARAMETERS
#   cmd   (IN) - user-entered command name string.
#
# RETURNS
#   1 if the command belongs to this module; 0 if command not found.
#
# NOTES
#   These errors are user-errors and not internal errors.  They are of type
#   record, not signal.  
# 
#   N.B. Functions in this module can call this function directly, without
#   calling the tfactlshare::tfactlshare_syntax_error equivalent.  The
#   latter is used only by the tfactl module.
########
sub tfactldiagcollect_syntax_error 
{
  my ($cmd) = shift;
  my ($cmd_syntax);                               # Correct syntax for $cmd. #
  my ($succ) = 0;


  #display syntax only for commands in this module.
  if (tfactldiagcollect_is_cmd($cmd))
  {
    tfactlshare_get_help_syntax($cmd);
    $succ = 1;

    if ($tfactlglobal_hash{'mode'} eq 'n')
    {
      $tfactlglobal_hash{'e'} = -1;
    }
  }

  return $succ;
}

########
# NAME
#   tfactldiagcollect_get_tfactl_cmds
#
# DESCRIPTION
#   This routine constructs a string that contains a list of the names of all 
#   TFACTL internal commands and returns this string.
#
# PARAMETERS
#   None.
#
# RETURNS
#   A string contain a list of the names of all TFACTL internal commands.
#
# NOTES
#   Used by the help command and by the error command when the user enters
#   an invalid internal command.
#
#   IMPORTANT: the commands names must be preceded by eight (8) spaces of
#              indention!  This formatting is mandatory.
########
sub tfactldiagcollect_get_tfactl_cmds 
{
  return tfactlshare_filter_invisible_cmds(%tfactldiagcollect_cmds);
}

################## Purge Repository ###################
sub purgeRepository
{
  my $tfa_home = shift; 
  my $purge_time = shift; 
  my $force = shift;
  my $localhost=tolower_host();
  my $repo_dir;
  my $line;
  my $current_time;
  my $total_hours = 0;
  my $filemodtime = 0;
  my $file_created_before = 0;
  my @file_list;
  my $delete_option;

  if (isTFARunning($tfa_home) == FAILED) {
    exit 1;
  }
  
  dbg(DBG_WHAT, "Running printRepository through Java CLI in purgeRepository\n");
  my $message ="$localhost:printrepository";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "$command\n");
  my $hostname;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
          if ( $line =~ /!/ ) {
          my @values = split(/!/, $line);
          if ($values[0] eq "Connection refused") {
            $hostname = $values[1];
            if ($hostname eq $localhost) {
                print "Unable to determine the repository directory for $hostname\n";
                exit 1;
            }
          }
          else {
            $hostname = $values[5];
            if ($hostname eq $localhost) {
                  $repo_dir = $values[0];
            }
          }
          }
  }
  if (!(defined $repo_dir)) {
    exit 1;
  }
  if ( $purge_time =~ /(.*)h$/ ) {
          $total_hours = $1;
  }
  elsif ( $purge_time =~ /(.*)d$/ ) {
          $total_hours = ( $1 * 24 );
  }

  $current_time = time();

  opendir(DIR, $repo_dir ) or die "Unable to open Repository Directory";

  while (my $file = readdir(DIR)) {

	next if ($file =~ m/^\./);

	next if ($file =~ /^suptools$/);

  next if ($file =~ /^receiver$/);

	next if ($file =~ /^oratop-/);

	my $owner;
	my $realowner;

	if ( -l catfile($repo_dir,$file) ) {
		$owner  = getSymlinkOwner(catfile($repo_dir,$file));
		$realowner = getFileOwner(readlink(catfile($repo_dir,$file)));
		next if ( $owner ne $realowner );
	}

	if ( $current_user ne "root" ) {
		$owner  = getFileOwner(catfile($repo_dir,$file));
	  	next if ($current_user ne $owner);
	}

	$filemodtime = (stat(catfile($repo_dir,$file)))[9];

	$file_created_before = ($current_time - $filemodtime)/(60 * 60);

	if ( $file_created_before >= $total_hours ) {
		push( @file_list, catfile($repo_dir,$file) );
	}
  }
  closedir(DIR);

  # Get Ongoing Collections
  my @collections = getOngoingCollections( $tfa_home );
  my $collection_status = shift @collections;

  if ( $collection_status == -1 ) {
        print "Unable to determine running collections. Please verify before removing.\n";
  }

  if ( $collection_status == 0 ) {
          my @colltags;
          my $temp;
          my @finallist;
          my $isPresent;

          foreach ( @collections ) {
                  $temp = (split( /!/, $_))[3];
                  push( @colltags, catdir($repo_dir,"$temp") );
          }

          print "Checking the status of collections...\n";

          foreach( @file_list ) {

                  $isPresent = isPresentInArray( "$_", \@colltags);

                  if ( $isPresent == 1 ) {
                          next;
                  }

                  if ( $_ =~ /[\\\/]temp_/ ) {
                          next;
                  }

                  push( @finallist, "$_" );
          }

          @file_list = @finallist;
  }

  if ( @file_list ) {

	if ( $force == 0 ) {
        	print "\nList of files in the repository older than $purge_time:\n";

        	foreach ( @file_list ) {
			my $file = $_;
			if ( -l $file ) {
				$file = readlink($file);
				print "$_ [ Symlinked to $file ]\n";
			} else {
				print "$file\n";
			}
        	}

        	print "\nDo you want to delete the above files. [Y|y|N|n] [Y]: ";
        	chomp( $delete_option = <STDIN> );
	}

        $delete_option ||= "Y";
        $delete_option = get_valid_input ( $delete_option, "Y|y|N|n", "Y");

        print "\n";

        if ( $delete_option =~ /[Yy]/ ) {

                foreach ( @file_list ) {
                        print "Deleting $_";

                        if ( -d "$_" ) {
                                rmtree "$_";
                        } else {
                                unlink "$_";
                        }
                        print " .....Deleted.\n";
                }
        } else {
                print "Repository files are not deleted.\n";
        }
  } else {
      print "\nNo files found in the repository older than the specified time.\n";
  }
}

#========== runRacCheckScan 
# TODO: replace with perl or make it ksh ...
#==========
sub runRacCheckDiscovery
{
  my $tfa_home = shift;
  my $rc;
  $rc = system("$PERL $tfa_home/bin/discoverOraStack.pl -perl $PERL");
  print " returned :: $rc\n";
}

#======================= runODScan ===========================#
sub runODScan
{
  my $tfa_home = shift;
  dbg(DBG_WHAT, "In runODScan\n");
  my $localhost=tolower_host();

  my $actionmessage = "$localhost:runodscan:NONE\n";
  dbg(DBG_WHAT, "Running runODScan through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$actionmessage);
  dbg(DBG_WHAT, "$command\n");

  if ($PROFILING_ON==1) {
    dbg(DBG_WHAT, "calling profiling script : $tfa_home/bin/profiling.sh \n");
    my $pid = $$;
    dbg(DBG_WHAT, "pid : $pid \n");
    system("bash $tfa_home/bin/profiling.sh $pid $tfa_home/output/inventory/scan_cpu_usage.txt > /dev/null 2>&1 &");
  }

  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
    dbg(DBG_VERB, "$line\n");
    if ( $line eq "SUCCESS") {
      print "Running On Demand Scan...\n";
      print "1. To check the scan statistics, run the following command:\n";
      print " ".catfile($tfa_home,"bin","tfactl")." print log\n";
      print "2. To check the status of scan, run the following command:\n";
      print " ".catfile($tfa_home,"bin","tfactl")." print actions\n";
      dbg(DBG_VERB,"#### Requested one off scan ####\n");
      return SUCCESS;
    }
    elsif ($line eq "FAILED") {
      print "Failed to run On Demand Scan\n";
    }
    elsif ($line =~ /On Demand Scan is disabled/) {
      print "$line\n";
      print "To enable On Demand Scan run the following command:\n";
      print "  ".catfile($tfa_home,"bin","tfactl")." set odscan=true\n";
    }
    elsif ($line =~ /Real Time scan is running/) {
      print "Alert Log Scan is already running\n";
    }
    else {
      print "$line\n";
    }
  }
  dbg(DBG_WHAT,"Could not request one off scan\n");
  return FAILED;

}

sub runODScanInCells
{
  my $tfa_home = shift;
}

sub runCellODScan
{
  my ($tfa_home, $cell) = @_; 
  print "Running inventory on $cell\n";
  my $logdirectory = getLogDirectory( $tfa_home );
  my $logfile = "$logdirectory/odscan_$cell.log";
  runCellInventory($tfa_home, $cell, 0, $logfile, 0);
  print "Running OD scan on $cell\n";
  my $localhost = tolower_host();
  my $tfabase = $tfa_home;
  $tfabase =~ s/\/$localhost\/tfa_home//;
  my $TFA_HOME = "$tfabase/$cell/tfa_home";
  my $result = `$SSH $cell $TFA_HOME/bin/tfactl run scan`;
}

# Run discovery script on each node and add the files to 
# tfa_directories.txt on the node.
sub runReDiscovery
{
  my $tfa_home = shift;
  my $mode = shift;
  my $auto = shift;
  my $tfa_dir_file = catfile($tfa_home, "tfa_directories.txt");
  my $tfactl = catfile($tfa_home, "bin", "tfactl");
  my $tfactlpl = catfile($tfa_home, "bin", "tfactl.pl");

  my $tfa_dir_file_lcnt = 0;
  if ( -f $tfa_dir_file )
  {
    open (FILE, $tfa_dir_file);
    $tfa_dir_file_lcnt++ while (<FILE>);
    close FILE;
  }
  # Check if tfa_home/internal/receiverconfig.xml exists. If yes add receiver and move file.
  # Since while TFA is installing GI may not be up, we do that here.
  my $rconfigfile = catfile($tfa_home, "internal", "receiverconfig.xml" );
  my $rconfigfile_self = catfile($tfa_home, "internal", "receiverconfig_self_d.xml" );
  my $sslfile = catfile($tfa_home, "internal", "ssl.properties" );
  my $sslKey = 0;
  if ( -r $sslfile ) {
    $sslKey = tfactlshare_getConfigValue($sslfile,"sslKey");
  }

  tfactlshare_setup_acfs();
  if ( -r $sslfile && -f $rconfigfile_self && $sslKey == 1 )
  { # In receiver add self
    my $rconfig = catfile($tfa_home,"receiver", "internal", "rconfig.properties");
    my $producer_running = 0;
    if ( -r $rconfig ) 
    { # Check if producer is running
      open (FILE, $rconfig);
      while (<FILE>)
      {
        chomp;
        $producer_running = 1 if ( /r.send.data.realtime=true/ );
      }
      close FILE;
    }

    if ( $producer_running == 0 )
    {
      my $Cpassword = tfactlshare_generate_password(16);
      my $roption = "y\[\[\[";
      tfactlshare_addCollector("client",$hostname,$Cpassword,1,"add",$tfa_home,$roption, "add","","mc");
      my $rport = `cat $tfa_home/receiver/internal/rport.txt`;
      chomp($rport);
      tfactlshare_addReceiver($tfa_home, "$hostname:$rport", 1, -1,$Cpassword,"");
      system("$tfactl producer stop");
      system("$tfactl producer start");
    }
    unlink($rconfigfile_self);
  }
  if ( -f $rconfigfile && -f $sslfile && $sslKey == 1 )
  {
    my $crsup = 0;
    my $crshome = get_crs_home($tfa_home);

    if ( ! -r "$tfa_home/internal/.tfa_setup_first" )
    { # Wait for second run as secure thread 
      open(TF, ">$tfa_home/internal/.tfa_setup_first");
      print TF "";
      close(TF);
    }
     else
    {
      if ( $crshome ) {      
        $crsup = 1 if ( osutils_isCRSRunning($crshome) );
      }
    }
    if ( $crsup == 1 && -f $rconfigfile )
    {
      $ENV{ORACLE_HOME} = $crshome;
      my $ORACLE_HOME = $crshome;
      $ENV{LD_LIBRARY_PATH} = catfile($crshome, "lib");
      system("$ORACLE_HOME/jdk/bin/java -cp $tfa_home/jlib/RATFA.jar:$ORACLE_HOME/jlib/clscred.jar:$ORACLE_HOME/jlib/srvm.jar oracle.rat.tfa.uc.TFAManageCredentials -import $rconfigfile  -out $rconfigfile.out");
      if ( -f "$rconfigfile.out" )
      {
        # tfactl receiver add host:port
        my $hosts = "";
        my $key = "";
        my $cname = "";
        my $guid = "";
        open(RCF, "$rconfigfile.out");
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
        unlink("$rconfigfile.out");
        if ( $hosts && $key )
        {
          my @hosts_arr = split(/,/, $hosts);
	  #Right now we don't know that on which node of R cluster the CRED file generated
	  #So go through each node till it gets succeed
	  my $addr_status;
	  foreach my $h ( @hosts_arr ) {	    
            $addr_status = tfactlshare_addReceiver($tfa_home, $h, 1, -1,$key,"$cname,$guid");
	    next if (!$addr_status);
            system("$tfactl producer stop");
            system("$tfactl producer start");
	    last;
	  }
        }
      }
      unlink($rconfigfile) if ( -f $rconfigfile );
    }
  }

  if ( ! $mode )
  {
    $mode = "full";
  }

  if ( ! -e "$BASH" && !$IS_WINDOWS) {
	 $mode = "lite";
  }

  if(!$IS_WINDOWS){
    tfactlshare_autostart_tools($tfa_home);
  }

  if ( $mode eq "full" )
  {
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect runReDiscovery " .
    "Full Mode", 'y', 'y');
    runReDiscoveryFull($tfa_home);
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect runReDiscovery " .
    "Completed Full Mode Rediscovery", 'y', 'y');
    tfactlshare_collect_topology($tfa_home);
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect runReDiscovery " .
    "Completed Collect Topology", 'y', 'y');
  }
  else
  {
    my $outputdir = tfactlshare_get_tfa_metadata_loc($tfa_home);
    my $localhost = tolower_host();
    my $inventoryDirectory = getInventoryLocation( $tfa_home, $localhost );
    if ( ! -f catfile($outputdir, "nodes.out") && -f catfile($inventoryDirectory, "inventory.xml") )
    { # Run only if its first time
      tfactlshare_collect_topology($tfa_home);
    }
    runReDiscoveryLite($tfa_home);

  }
  my $tfa_dir_file_lcnt_after = 0;
  if ( -f $tfa_dir_file )
  {
    open (FILE, $tfa_dir_file);
    $tfa_dir_file_lcnt_after++ while (<FILE>);
    close FILE;
  }
 
  if (!defined $auto) {
  	my $localhost=tolower_host();
  	my $message = "$localhost:addDiscDirs";
  	my $command = buildCLIJava($tfa_home,$message);
	my @cli_output = tfactlshare_runClient($command);
	foreach my $line ( @cli_output )
  	{
    		last if ($line eq "DONE");
  	} 
  }
  # set some collectall dirs
  my $invlocdir = tfactlshare_getorainvloc();
  my $invloclogdir = catdir($invlocdir,"logs");
  my $invloccxmldir = catdir($invlocdir,"ContentsXML");
  system("$PERL $tfactlpl directory modify \"$invloclogdir\" -collectall -private") if -d $invloclogdir;
  system("$PERL $tfactlpl directory modify \"$invloccxmldir\" -collectall -private") if -d $invloccxmldir;
  foreach my $line ( @set_collectall_dirs ) {
    system("$PERL $tfactlpl directory modify \"$line\" -collectall -private");
  }
}


sub runReDiscoveryLite
{
  my $tfa_home = shift;

  # print "Running Lite rediscovery \n";
  # Read CRS_HOME and RDBMS_ORACLE_HOME from tfa_setup.txt
  # Run orabase and find distinct oracle_base directories
  # Find all directories upto 2 level and check if they are already in internal/scanned_directories.txt
  # Add any new directories and append directory name to internal/scanned_directories.txt

  my %base_dirs = ();
  my %scanned_dirs = ();
  my $crs_home = "";
  my $host = tolower_host();
  my $sfile;
  my $tfasetup;
  my $tfalite;
  my $tfa_dir_file;
  my $repository;
  my $setupfile = tfactlshare_getSetupFilePath($tfa_home);

  if ( ! $ISCLOUD && ! isOfflineMode($setupfile) ) {
  	$sfile = catfile($tfa_home, "internal", "scanned_directories.txt");
  	$tfasetup = catfile($tfa_home, "tfa_setup.txt");
        $tfalite = catfile($tfa_home, "internal","tfajson_lite.json" );
  	$tfa_dir_file = catfile($tfa_home, "tfa_directories.txt");
  	$repository = tfactlshare_get_repository_location( $tfa_home, $host );
  } else {
    my $homedir = getHomeDirectory();
    $homedir = catfile($homedir, ".tfa");
    $tfasetup = catfile($homedir, "tfa_setup.txt" );
    my $tfa_base = getTFABase($tfasetup);
    $tfa_dir_file = catfile($tfa_base, "tfa_directories.txt");
    $sfile = catfile($tfa_base, "internal", "scanned_directories.txt");
    $repository = catfile($tfa_base, "repository");
  }

  # Update new homes form inventory.xml
  read_inv_and_update_tfa_setup ($tfa_home);
  if ( -f "$sfile" )
  {
    open(RF, "$sfile");
    while(<RF>)
    {
      chomp;
      $scanned_dirs{$_} = 1;
    }
    close(RF);
  }
   elsif ( -f "$tfa_dir_file")  # first time read tfa_directories and initial;ize
  {
    open(SF, ">$sfile");
    open(TDF, "$tfa_dir_file");
    {
      while(<TDF>)
      {
        chomp;
        if ( /.*?=(.*)/ )
        {
          print SF "$1\n";
        }
      }
    }
    close(TDF);
    close(SF);
  }

  my @trcdirs = ();
  my $crsbasedir;
  if ( -f "$tfasetup" )
  {
    open(RF, "$tfasetup");
    while(<RF>)
    {
      chomp;
      if ( /^CRS_HOME=(.*)/ )
      {
        my $home = $1;
        $crs_home = $1;
        my $base_dir = get_base_dir($home);
        $crsbasedir = $base_dir; 
        $base_dirs{$base_dir} = 1 if ( $base_dir );
      }
       elsif (/^RDBMS_ORACLE_HOME=(.*?)\|/ )
      {
        my $home = $1;
        my $base_dir = get_base_dir($home);
        $base_dirs{$base_dir} = 1 if ( $base_dir );
        push(@trcdirs, "RDBMS:".catfile($home, "rdbms", "log")) if ( -d catfile($home, "rdbms", "log") );
        push(@trcdirs, "RDBMS:".catfile($home, "rdbms", "trace")) if ( -d catfile($home, "rdbms", "trace") );
        if ( -d catfile($home, "inventory", "ContentsXML") ) {
          push(@trcdirs, "INSTALL:".catfile($home, "inventory", "ContentsXML"));
          push(@set_collectall_dirs,catfile($home, "inventory", "ContentsXML"));
        }
        if ( -d catfile($home, "cfgtoollogs") ) {
          push(@trcdirs, "CFGTOOLS:".catfile($home, "cfgtoollogs")) if ( -d catfile($home, "cfgtoollogs") );
        }
      }
    }
    close(RF);
  }

  my $dir = "";
  # base_dir/diag/asm/*/*/trace
  # base_dir/diag/rdbms/*/*/trace
  foreach $dir (keys %base_dirs)
  {
    push(@trcdirs, "CFGTOOLS:".catfile($dir, "cfgtoollogs") ) if ( -d catfile($dir, "cfgtoollogs") ); 
    push(@trcdirs, "RDBMS:".catfile($dir, "cfgtoollogs","dbua") ) if ( -d catfile($dir, "cfgtoollogs","dbua") ); 
    push(@trcdirs, "RDBMS:".catfile($dir, "cfgtoollogs","dbca") ) if ( -d catfile($dir, "cfgtoollogs","dbca") ); 
    push(@trcdirs, get_trc_dirs(catfile($dir,"diag","asm"), "ASM", "trace")) if ( -d catfile($dir,"diag","asm") );
    push(@trcdirs, get_trc_dirs(catfile($dir,"diag","afdboot"), "AFD", "trace")) if ( -d catfile($dir,"diag","afdboot") );
    push(@trcdirs, get_trc_dirs(catfile($dir,"diag","rdbms"), "RDBMS", "trace")) if ( -d catfile($dir,"diag","rdbms") );
    push(@trcdirs, get_trc_dirs(catfile($dir,"diag","apx"), "ASMPROXY", "trace")) if ( -d catfile($dir,"diag","apx") );
    push(@trcdirs, get_trc_dirs(catfile($dir,"diag","ios"), "ASMIO", "trace")) if ( -d catfile($dir,"diag","ios") );
    if ( $dir eq $crsbasedir ) {
       push(@trcdirs, get_trc_dirs(catfile($dir,"diag","clients"), "CRSCLIENT", "trace")) if ( -d catfile($dir,"diag","clients") );
    } else {
       push(@trcdirs, get_trc_dirs(catfile($dir,"diag","clients"), "DBCLIENT", "trace")) if ( -d catfile($dir,"diag","clients") );
    }
    push(@trcdirs, get_trc_dirs(catfile($dir,"diag","asmtool"), "ASMTOOL", "trace" )) if ( -d catfile($dir,"diag","asmtool") );
    push(@trcdirs, get_trc_dirs(catfile($dir,"diag","listener"), "TNS", "trace" )) if ( -d catfile($dir,"diag","listener") );
    push(@trcdirs, get_trc_dirs(catfile($dir,"diag","tnslsnr"), "TNS", "trace" )) if ( -d catfile($dir,"diag","tnslsnr") );
    push(@trcdirs, get_trc_dirs(catfile($dir,"crsdata"), "CRS", "-" )) if ( -d catfile($dir,"crsdata") );
    push(@trcdirs, "CRS:" . catfile($dir,"diagsnap")) if ( -d catfile($dir,"diagsnap") );
 }

 if ( $crs_home )
 {
#print "Checking crs_home : $crs_home\n";
    push(@trcdirs, get_trc_dirs(catfile($crs_home,"log"), "CRS", "-" ));
    push(@trcdirs, get_trc_dirs(catfile($crs_home,"log", "diag","tnslsnr"), "TNS", "trace" )) if ( -d catfile($crs_home,"log", "diag","tnslsnr") );
    # Adding chm Emergency dump directory if it exists
    my $chmedumpdir=catfile($crs_home,"crf", "db", $host);
    if ( -d $chmedumpdir ) {
       push(@trcdirs, "CRS:". $chmedumpdir);
    }
  }
  # Add ExaWatcher archive dir once it is created.
  my $exawatcherdir = catfile("/opt/oracle.ExaWatcher/archive");
  if ( -d $exawatcherdir ) {
    push(@trcdirs,"OS:". $exawatcherdir);
  }

  # Check OSW 
  if(!$IS_WINDOWS){
     if ( -d catdir($repository,"suptools",$host,"oswbb") ) {
        my $oswbbDir = catdir($repository,"suptools",$host,"oswbb");
        my @oswdirs = `$FIND $oswbbDir -type d -name archive`;
        chomp(@oswdirs);
        foreach my $oswdir (@oswdirs)
        {
          push(@trcdirs,"OS:". $oswdir);
        }
     }
  }
  # Add RACDBCLOUD Dirs
  my $COMPONENT = "RACDBCLOUD";
  $COMPONENT = "ODALITE" if $IS_ODALITE;

  if ( $IS_RACDBCLOUD or $IS_ODALITE ) {
     my @racdbclouddirs;
     my $racdbclouddir;
     push (@racdbclouddirs, catfile("","opt","zookeeper","log")) if ( -d catfile("","opt","zookeeper","log"));
     push (@racdbclouddirs, catfile("","opt","oracle","dcs","log")) if ( -d catfile("","opt","oracle","dcs","log"));
     push (@racdbclouddirs, catfile("","home","oracle","bkup","logs")) if ( -d catfile("","home","oracle","bkup","logs"));
   
     foreach $racdbclouddir (@racdbclouddirs) {
       if ( -d $racdbclouddir ) {
          push(@trcdirs,$COMPONENT.":". $racdbclouddir);
       }
     }
  }

  # Add ZDLRA directories once it is created.
  if (!$IS_WINDOWS){
     my @zdlradirs;
     my $zdlradir;
     push(@zdlradirs,"/dbfs_obdbfs/OSB/tmp");
     push(@zdlradirs,"/dbfs_obdbfs/OSB/backup/admin/log");
     push(@zdlradirs,"/usr/tmp");
     push(@zdlradirs,"/radump");

     foreach $zdlradir (@zdlradirs) {
       if ( -d $zdlradir ) { 
          push(@trcdirs,"ZDLRA:". $zdlradir);
        }
     #print "$zdlradir\n";
     }
  }

  # Add suptools/prw
  if (!$IS_WINDOWS){
    my $tfa_base = tfactlshare_get_repository_location($tfa_home);
    my $prw_dir = catfile($tfa_base, "suptools", "prw");
    push(@trcdirs,"RDBMS:".$prw_dir);
  }
	  

  open (SF, ">>$sfile") || die "Cant open $sfile for writing\n";
  foreach $dir (@trcdirs)
  {
     my $comp;
     if ( $dir =~ /^(\w+?):(.*)/ )
     {
        $comp = $1;
        $dir = $2;
      }
      #print "---- $comp  : $dir\n";
      if ( ! defined $scanned_dirs{$dir} )
      {
         #print "Adding $dir ($sfile)\n";
         if ( $comp eq "CRS" ){
	    if ($dir =~ /$host(\\|\/)acfs/) {
	       add_new_directory ($tfa_home, $dir, "ACFS");
	       print SF "$dir\n";
	    }
	    elsif ($dir =~ /$host(\\|\/)afd/) {
	       add_new_directory ($tfa_home, $dir, "AFD");
	       print SF "$dir\n";
	    }
	    elsif ($dir =~ /$host(\\|\/)rhp/) {
               add_new_directory ($tfa_home, $dir, "RHP");
               print SF "$dir\n";
            }
            else {
               add_new_directory ($tfa_home, $dir, $comp);
               print SF "$dir\n";
            }
         }
         else {
            add_new_directory ($tfa_home, $dir, $comp);
            print SF "$dir\n";
         }
      }
   }
   close(SF);
   if(!$IS_WINDOWS){
     tfactldiagcollect_add_topology_tfar($tfalite,$tfasetup);
     # Ensure all TFA users have the correct trace and tools directory permisisons
     tfactlshare_check_tfauser_diag($tfa_home);
   }
}

sub tfactldiagcollect_add_topology_tfar
{
   my $tfalite = shift;
   my $tfasetup = shift;
   open (SF, ">>$tfalite") || die "Cant open $tfalite for writing\n";
   my $dt = `date`;
   my @p = `ps -ef | grep pmon`;
   my $rec;
   my $asm = 'asm:';
   my $db = 'db:';
   my $vasm = '';
   my $vdb = '';
   my $flower_open = "{";
   my $square_open = "[";
   my $flower_close = "}";
   my $square_close = "]";
   my $comma = ",";
   my $c = ",";
   my $ai = 1;
   my $di = 1;
   my $inv = '"';
   my $host = `hostname`;
   chomp($host);

   my $mc = "/Clusters/";
   my @cname = `grep CLUSTER_NAME $tfasetup`;
   my $ct = "";
   $ct = $cname[0];
   my $c_name;
   if(length($ct) == 0){
      $c_name = $host;
   }
   else {
      my @cparts = split/=/,$ct;
      chomp($cparts[0]);
      chomp($cparts[1]);
      $c_name = $cparts[1];
   }

   $mc = $mc.$c_name."/".$host."/";
   my $mcc = '"_mcluster":"';
   my $ml = '"_mleaf":"';
   my $top = '"_mtype":"topology"';
   my $json ;

   foreach $rec (@p)
   {
       chomp($rec);
       if($rec !~ /grep/ ){
         my @parts = split/\s+/,$rec;
         my $part = $parts[$#parts];
         my @sparts = split/_/,$part;
         my $v = $sparts[$#sparts];
         chomp($v);
         print $v;
         if($v =~ /ASM/){
           $vasm = $vasm.$v.$c;
           $ai = $ai + 1;
         }else {
           $vdb = $vdb.$v.$c;
           $di = $di + 1;
         }
       }
    }
    chop($vasm);
    chop($vdb);
    if($ai == 1) {
       $vasm = "NA";
    }
    if($di == 1){
       $vdb = "NA";
    }
    $json = $flower_open.$top.$comma.$mcc.$mc.$asm.$vasm.";".$db.$vdb.$inv.$flower_close;
    print SF "$json\n";
    close(SF);
}

# TODO : update the new RDBMS_ORACLE_HOME's in tfa_setup.txt from stack_status.out
sub runReDiscoveryFull
{
  my $tfa_home = shift;
  # add ORACLE_BASE/diag directory
  # get ORACLE_BASE from tfa_setup.txt
  my $infile = tfactlshare_getSetupFilePath($tfa_home);
  my $oracle_base;
  if ( -r "$infile" )
  {
    open(RF, "$infile");
    while(<RF>)
    {
      chomp;
      if (/ORACLE_BASE=/) { $oracle_base=$_; }
    }
    close(RF);
  }

  if (defined $oracle_base) {
    my @a = split(/=/, $oracle_base);
    $oracle_base=$a[1];
    print "In Rediscovery, adding ".catdir($oracle_base,"diag")." to TFA\n";
    addDirectory($tfa_home, catfile($oracle_base,"diag"), 0);
  }
  else {
    print "Could not find ORACLE_BASE in tfa_setup.txt\n";
  }
  
  my $CRS_HOME = get_crs_home($tfa_home);

  # check if CRS is up and running
  if(-d $CRS_HOME && osutils_isCRSRunning($CRS_HOME)){
    print "CRS is up and running\n";
  }else{
    print "CRS is not running\n";
  }
  
  # if Discovery was deferred on install then there will not as yet be a CRS_HOME set.
  # right now we need hat to chekc for new databases.
  #if (  $CRS_HOME )
  #{
  #   return if ( ! find_new_databases($tfa_home) );
  #}
  print "Running discovery and adding rediscovered directories ...\n";
  $ENV{RAT_LOCALONLY} = 1;
  $SILENT = 1;
  runDiscovery ($tfa_home);
  addReDiscDirectories ($tfa_home);

  if ( ! $CRS_HOME )
  {
     set_new_crshome($tfa_home);
  }

  check_new_directories ($tfa_home);
}

#======== runDiagCollect
# 
sub runDiagCollect
{
  my $tfa_home = shift;
  my $clusterwide = shift;
  my $opts = shift;
  my $currRepo = getCurrentRepository($tfa_home);
  my $crs_home = ""; 
  open (RF, catfile($tfa_home,"tfa_setup.txt")) || die "Cant open ".catfile($tfa_home,"tfa_setup.txt")."\n";
  while(<RF>)
  {
    chomp;
    if ( /CRS_HOME=(.*)/ )
    {
      $crs_home = $1; 
      last;
    }
  }
  close(RF);
  if ( ! $crs_home )
  {
    print STDERR "Could not find CRS_HOME. Exiting\n";
    exit(1);
  }
  my $local = 1;
  $local = 1 if ( $opts =~ /-frominventory/ );

  my $tag;
  if ($opts =~ /-tag/) {
      my @options = split(/\s\-/, $opts);
      for (my $c=0; $c<scalar(@options); $c++) {
        if ($options[$c] =~ /^tag/) {
          $tag = $options[$c];
          $tag =~ s/tag //;
          $tag = trim($tag);
          $tag =~ s/\s/_/g;
        }
      }
  }
  my $localhost = tolower_host();
  my $currtime = currentTime();
  my $zfile = "ALL_logs_" . $localhost . "_" . $currtime . ".zip";
  if ($opts =~ /-z/) {
    my @options = split(/\s\-/, $opts);
      for (my $c=0; $c<scalar(@options); $c++) {
        if ($options[$c] =~ /^z/) {
          $zfile = $options[$c];
          $zfile =~ s/z //;
          $zfile = trim($zfile);
          $zfile =~ s/\s/_/g;
          $zfile = $localhost.".".$zfile.".zip";
          print "output zip file : $zfile \n";
        }
      }
  }
  if ( $local == 0 )
  { # Call diagcollection.pl script
    my $diag_script = "$crs_home/bin/diagcollection.sh $opts > $tfa_home/log/diagcollect.log 2>&1";
    print "Running $diag_script\n";
    #chdir("$tfa_home/output/tracefiles");
    chdir($currRepo);
    system($diag_script);
  }
   else
  {
    # Collect chmos data
    #my $diag_script = "$crs_home/bin/diagcollection.sh --collect --chmos > $tfa_home/log/diagcollect.log 2>&1";
    my $chmfile = "CHMOS_" . $localhost . "_" . $currtime;
    my $diag_script = catfile($crs_home,"bin","oclumon")." dumpnodeview -n $localhost -last \"04:00:00\" -v > $chmfile";
    print "Running $diag_script\n";
    if (defined $tag) {
        mkdir(catdir($currRepo,"$tag"));
        mkdir(catdir($currRepo,$tag,$$));
        chdir(catdir($currRepo,$tag,$$));
    }
    else {
        mkdir(catdir($currRepo,$$));
        chdir(catdir($currRepo,$$));
    }
    system($diag_script);
    #`ls | awk '{print \$1 " -> chmos files"}' >> $tfa_home/log/diagcollect.log`;
    # Zip all files in inventory.xml
    print "Collecting all files listed in inventory.xml\n";
    collectFromInventory($tfa_home, $tag);

    #system("mv -f * ../");
    system("zip -r  $zfile .  > ".catfile($tfa_home,"log","allzip.log")." 2>&1");
    system("$MV $zfile ../");
    system ("echo \"$zfile  ->  master log\" >> ".catfile($tfa_home,"log","diagcollect.log"));
    if (defined $tag) {
        chdir(catdir($currRepo,$tag));
    }
    else {
        chdir("$currRepo");
    }
    #rmdir("$$");
    if($IS_WINDOWS){
      rmtree $$;
    }else{
      system("$RM -rf $$");  
    }
    
  }
  if (defined $tag) {
    print "Diag collection completed. Following files are created under ".catdir($currRepo,$tag)."\n";
  }
  else {
    print "Diag collection completed. Following files are created under $currRepo\n";
  }
  open(RF, catfile($tfa_home,"log","diagcollect.log")) || die "Can't open ".catfile($tfa_home,"log","diagcollect.log")."\n";
  while(<RF>)
  {
    print if ( / -\>  master/ );
  }
  close(RF);
}
#======================= runDiagcollectionInCells =================#
sub runDiagcollectionInCells
{   
  my ($tfa_home, $args, $cellnames, $runinbackground) = @_;
  if ($runinbackground == 1) {
    my $pid = fork; 
    return if $pid;
  }
  my $localhost = tolower_host();
  
  #Perform Oracle Wallet Pre Checks
  preChecks( $tfa_home );

  #Remove -rdbms and -chmos from arg list
  #print "Arguments for diagcollect before changes : $args\n";
  $args =~ s/-rdbms//g;
  $args =~ s/-zdlra//g;
  $args =~ s/-chmos//g;
  $args =~ s/-ips//g;

  #print "Arguments for diagcollect after changes : $args\n";

  my @options = split(/\s\-/, $args);
  my $LOGID;
  my $TAGNAME;
  my $COPYTONODE;
  
  for (my $c=0; $c<scalar(@options); $c++) {
    my $current = $options[$c];
    $current = trim($current);
    if ( $current =~ /logid/ ) {
        $LOGID = $current;
        $LOGID =~ s/logid //;
    }
    if ( $current =~ /tag / ) {
        $TAGNAME = $current;
        $TAGNAME =~ s/tag //;
        if ($TAGNAME =~ /^0/) {
           my $OLDTAG = $TAGNAME;
           $TAGNAME =~ s/0//;
           $args =~ s/-tag\s$OLDTAG/-tag $TAGNAME /;
        }
    }
    if ( $current =~ /copytocomputenode / ) {
        $COPYTONODE = $current;
        $COPYTONODE =~ s/copytocomputenode //;
     }
  }
  $LOGID = trim( $LOGID );
  $TAGNAME = trim( $TAGNAME );

  if ( $COPYTONODE ) {
        $COPYTONODE = trim( $COPYTONODE );
  } else {
        $COPYTONODE = "$localhost";
  }

  my $repository = tfactlshare_get_repository_location( $tfa_home, $localhost );
  #my $repository = getCurrentRepository($tfa_home);
  my $repdir = catfile($repository,$TAGNAME);
  if ( $DIAGCOLLECT ) {
     my $count = 0;
     do {
        sleep(3);
        $count++;
        if ( $count == 10 ) {
           last;
        }
     } while ( ! -d "$repdir");
  } else {
	`mkdir -p $repdir`;
  }
  my $logfile = catfile($repository, $TAGNAME, "diagcollect_$LOGID\_$localhost\_initiator.log");
  if ( -e $logfile ) {
    open (OUT, ">>$logfile") or die "Can't open $logfile: $!\n";
  }
  else {
    open (OUT, ">$logfile") or die "Can't open $logfile: $!\n";
  }

  # Get list of all compute nodes
  my @computenodes = tfactlshare_getConfiguredComputeNodes($tfa_home);
  my $len_nodes = scalar(@computenodes);
  print OUT localtime(time) . " : Compute Nodes : @computenodes\n";

  # Get PID of Master Node 
  my $parent_pid = $$;
  print OUT localtime(time) . " : Parent PID : $parent_pid\n";

  # Remove Cell Queue file if found
  my $queue_file;
  foreach my $node ( @computenodes ) {
        $queue_file = catfile($tfa_home, "internal", $node . "_cell_queue_" . $parent_pid);
        if ( -f $queue_file ) {
                unlink($queue_file);
        }
  }	

  # Get Storage Cell List
  $cellnames = trim($cellnames);
  my @cells;
  if ($cellnames eq "all") {
    # Get list of all cells
    @cells = getOnlineCells( $tfa_home );
  }
  else {
    @cells = split (/,/ , $cellnames);
  }
  print OUT localtime(time) . " : Online Cells : @cells\n";

  my $tfabase = $tfa_home;
  $tfabase =~ s/[\\\/]$localhost[\\\/]tfa_home//;
  print OUT localtime(time) . " : TFA_BASE : $tfabase\n";

  # Assign Cell Collection to Compute Nodes
  for (my $i=0; $i<scalar(@cells); $i++) {
    my $index = $i % $len_nodes;
    print OUT localtime(time) . " : $computenodes[$index] => $cells[$i] \n";
    my $computenode = $computenodes[$index];
    my $cell = $cells[$i];
    print OUT localtime(time) . " : $computenode is Cell Master for $cell\n";
    print "$computenode is Cell Master for $cell\n";

    $queue_file = catfile($tfa_home, "internal", $computenode . "_cell_queue_" . $parent_pid);
    qx(echo $cell >> $queue_file);

  } # end of for loop

  # Run Cell Collection on all Compute Nodes
  foreach my $node ( @computenodes ) {
	processCellQueue($tfa_home, $node, $tfabase, "$args -copytocomputenode $COPYTONODE", $logfile, $parent_pid);
  }

  close OUT;
  exit;
}

#
# Subroutine to run cell collection on Compute Node using cell queue
#
sub processCellQueue {
	my $tfa_home = shift;
	my $computenode = shift;
	my $tfa_base = shift;
	my $args = shift;
	my $logfile = shift;
	my $parent_pid = shift;

	my $pid = fork;
	return if $pid;

	open (OUT, ">>$logfile") or die "Can't open $logfile: $!\n";

	my $localhost = tolower_host();

	my $queue_file = catfile($tfa_home, "internal", $computenode . "_cell_queue_" . $parent_pid);
	print OUT localtime(time) . " : processCellQueue : $computenode : queue_file : $queue_file\n";

	# Get Cell List from Queue
	my @cells;
	open(QUEUE, "$queue_file" );
	while (<QUEUE>) {
		chomp;
		push(@cells, trim($_));
	}
	close (QUEUE);
	unlink($queue_file);

	print OUT localtime(time) . " : processCellQueue : $computenode : cells : @cells\n";

	my $tfaexe = catfile($tfa_home, "bin", "tfactl");
	my $TFA_HOME = catfile($tfa_base, $computenode, "tfa_home");
	my $remotecommand;

	# Run Cell Collection using executecommand ( Serial Mode )
	foreach my $cell ( @cells ) {
		$remotecommand = catfile($TFA_HOME, "bin", "tfactl") . " diagcollect -onlycell -cell $cell $args";
		print OUT localtime(time) . " : processCellQueue : $computenode : remotecommand : $remotecommand\n";
		qx($tfaexe executecommand $computenode $remotecommand);
		print OUT localtime(time) . " : processCellQueue : $computenode : Completed executecommand for cell $cell\n";
	}

	close OUT;
	exit;
}

#======================= runCellDiagcollection ==================#
sub runCellDiagcollection {

  my ($tfa_home, $cell, $args) = @_;

  my $pid = fork; 
  return if $pid; 

  my $localhost = tolower_host();
  my $tfabase = $tfa_home;
  $tfabase =~ s/[\\\/]$localhost[\\\/]tfa_home//;
  my $TFA_HOME = catfile($tfabase, $cell, "tfa_home");

  my @options = split(/\s\-/, $args);
  my $cellargs = catfile($TFA_HOME,"bin","tfactl")." diagcollect -node local -nocopy";
  my $ZIPFILE;
  my $TAGNAME;
  my $LOGID;
  my $COPYTOCOMPUTENODE;

  for (my $c = 0; $c < scalar(@options); $c++) {
        my $current = $options[$c];
        $current = trim($current);

        if ( $current =~ /^(\s*)$/ ) {
                next;
        }

        if( $current !~ /^node / && $current !~ /^cell / && $current !~ /^copy / && $current !~ /^nocopy/ && $current !~ /onlycell/ && $current !~ /^user / && $current !~ /^rdbms / && $current !~ /^chmos/) {
                if ( $current =~ /^for\s(.*)\s+(.*)/ ) {
                        $current = "for \\\"$1 $2\\\"";
                }
                if ( $current =~ /^from\s(.*)\s+(.*)/ ) {
                        $current = "from \\\"$1 $2\\\"";
                }
                if ( $current =~ /^to\s(.*)\s+(.*)/ ) {
                        $current = "to \\\"$1 $2\\\"";
                }
                $cellargs = "$cellargs \-$current";
        }

        if ( $current =~ /^z / ) {
                $ZIPFILE = $current;
                $ZIPFILE =~ s/z //;
        }

        if ( $current =~ /tag / ) {
                $TAGNAME = $current;
                $TAGNAME =~ s/tag //;
        }

        if ( $current =~ /copytocomputenode / ) {
                $COPYTOCOMPUTENODE = $current;
                $COPYTOCOMPUTENODE =~ s/copytocomputenode //;
        }

        if ( $current =~ /logid/ ) {
                $LOGID = $current;
                $LOGID =~ s/logid //;
        }
  }

  $TAGNAME = trim($TAGNAME);
  $ZIPFILE = trim($ZIPFILE);
  $LOGID = trim($LOGID);
  $COPYTOCOMPUTENODE = trim( $COPYTOCOMPUTENODE );

  my $repository = tfactlshare_get_repository_location($tfa_home, $localhost );
  my $repdir = catfile($repository, $TAGNAME);

  if ( $DIAGCOLLECT ) {
     my $count = 0;
     do {
        sleep(3);
        $count++;
        if ( $count == 10 ) {
           last;
        }
     } while ( ! -d "$repdir");
  } else {
	`mkdir -p $repdir`;
  }

  my $logfile = catfile($repository, $TAGNAME, "diagcollect_$LOGID\_$localhost\_initiator.log");
  if ( -e $logfile ) {
	open (LOG, ">>$logfile") or die "Can't open $logfile: $!\n";
  } else {
	open (LOG, ">$logfile") or die "Can't open $logfile: $!\n";
  }

  print LOG localtime(time) . " : Running diagcollection for cell $cell\n";
  print LOG localtime(time) . " : PID of Child (Storage Cell Diagcollect Thread) : $pid\n";
  print LOG localtime(time) . " : CELL DIAGCOLLECT PARAMS: $cellargs\n";
  print LOG localtime(time) . " : ZIP FILE: $ZIPFILE\n";
  print LOG localtime(time) . " : TAG NAME: $TAGNAME\n";

  my $CRS_HOME = get_crs_home( $tfa_home );
  my $SSH_STATUS = checkSSHSetup ( $cell );

  my $LOCK = runCommandOnRemoteWithStatus( $tfa_home, $cell, "$SSH $cell ls $TFA_HOME/internal/.$cell.lock 2>/dev/null | wc -l", $CRS_HOME, $SSH_STATUS );
  $LOCK = trim( $LOCK );

  if ( $LOCK == 1 ) {
        print LOG localtime(time) . " : Found TFA_HOME $TFA_HOME on $cell...\n";

        # Check if TFA is running on cell
        my $tfa_status = runCommandOnRemoteWithStatus( $tfa_home, $cell, "$SSH $cell ps -ef | grep -i tfa | grep -v grep | wc -l", $CRS_HOME, $SSH_STATUS );
        $tfa_status = trim( $tfa_status );

        print LOG localtime(time) . " : No of TFA process running on $cell: $tfa_status\n";

        if ( $tfa_status != 0 ) {
                print "Adding Command $cellargs to $cell Queue\n";
                runCommandOnRemote( $tfa_home, $cell, "$SSH $cell \"echo $cellargs >> $TFA_HOME/internal/.$cell.job\"", $CRS_HOME, $SSH_STATUS );
                exit 0;
        } else {
                # TFA is not running so need to remove TFA_BASE on CELL
                print LOG localtime(time) . " : Removing old TFA_BASE $tfabase on $cell...\n";
                runCommandOnRemote( $tfa_home, $cell, "$SSH $cell rm -rf $tfabase", $CRS_HOME, $SSH_STATUS );
        }
  }
  close LOG;

  # Run cell inventory first and get inventory_$cell.xml
  runCellInventory($tfa_home, $cell, 0, $logfile, 0);

  open (OUT, ">>$logfile") or die "Can't open $logfile: $!\n";
  my $result;

  my $CELLDIAGCMD = "$SSH $cell $cellargs";

  print OUT localtime(time) . " : Executing $CELLDIAGCMD\n";
  runCommandOnRemote( $tfa_home, $cell, "$CELLDIAGCMD", $CRS_HOME, $SSH_STATUS );

  my $SOURCE = "$tfabase/repository/$TAGNAME/*";
  my $DESTINATION = "$repository/$TAGNAME/";

  print OUT localtime(time) . " : Copying $cell:$SOURCE to $localhost:$DESTINATION\n";
  runCommandOnRemote( $tfa_home, $cell, "$SCP root\@$cell:$SOURCE $DESTINATION", $CRS_HOME, $SSH_STATUS );

  print OUT localtime(time) . " : COPYTOCOMPUTENODE: $COPYTOCOMPUTENODE\tlocalhost: $localhost\n";

  if ( $COPYTOCOMPUTENODE && $COPYTOCOMPUTENODE ne $localhost ) {

    # Copy zip file
    print OUT localtime(time) . " : Copying $cell.$ZIPFILE.zip to $COPYTOCOMPUTENODE\n";
    copyTagFile($tfa_home, "repofile-TAG-$TAGNAME-FILE-$cell.$ZIPFILE.zip", $COPYTOCOMPUTENODE);

    # Copy metadata file
    print OUT localtime(time) . " : Copying $cell.$ZIPFILE.zip.txt to $COPYTOCOMPUTENODE\n";
    copyTagFile($tfa_home, "repofile-TAG-$TAGNAME-FILE-$cell.$ZIPFILE.zip.txt", $COPYTOCOMPUTENODE);

    # Copy log file
    print OUT localtime(time) . " : Copying diagcollect_$LOGID\_$cell.log to $COPYTOCOMPUTENODE\n";
    copyTagFile($tfa_home, "repofile-TAG-$TAGNAME-FILE-diagcollect_$LOGID\_$cell.log", $COPYTOCOMPUTENODE);

    # Copy console log
    print OUT localtime(time) . " : Copying diagcollect_console_$LOGID\_$cell.log to $COPYTOCOMPUTENODE\n";
    copyTagFile($tfa_home, "repofile-TAG-$TAGNAME-FILE-diagcollect_console_$LOGID\_$cell.log", $COPYTOCOMPUTENODE);

    # Copy Initiator Log
    print OUT localtime(time) . " : Copying diagcollect_$LOGID\_$localhost\_initiator.log to $COPYTOCOMPUTENODE\n";
    copyTagFile($tfa_home, "repofile-TAG-$TAGNAME-FILE-diagcollect_$LOGID\_$localhost\_initiator.log", $COPYTOCOMPUTENODE);
  }

  # Update the permission of collections
  qx(chmod 700 $repository/$TAGNAME/\*\.\*);

  # As part of diagcollection, run inventory is called in Java.
  # At the end of diagcollection, we will copy the updated inventory_$cell.xml
  # to localhost and also sync with the remaining compute nodes.
  print OUT localtime(time) . " : Copying $TFA_HOME/output/inventory/inventory_$cell.xml to localhost\n";
  my $inventoryDirectory = getInventoryLocation( $tfa_home, $localhost );

  runCommandOnRemote( $tfa_home, $cell, "$SSH $cell cp $TFA_HOME/output/inventory/inventory.xml $TFA_HOME/output/inventory/inventory_$cell.xml", $CRS_HOME, $SSH_STATUS );
  runCommandOnRemote( $tfa_home, $cell, "$SCP $cell:$TFA_HOME/output/inventory/inventory_$cell.xml $inventoryDirectory", $CRS_HOME, $SSH_STATUS );

  #Process Job Queue and remove TFA_BASE on Cell
  processJobsOnCell( $tfa_home, $cell, $TFA_HOME, $CRS_HOME, $SSH_STATUS, $logfile );

  #Get list of all compute nodes
  my @tfahosts = getListOfOtherNodes( $tfa_home );
  print OUT localtime(time) . " : Compute nodes : @tfahosts\n";

  #Sync up this inventory_$cell.xml in all compute nodes
  my $remotenode;
  foreach $remotenode ( @tfahosts ) {
          print OUT localtime(time) . " : Copying inventory_$cell.xml to $remotenode\n";
	  copyTagFile($tfa_home, "cellinvxml-$cell", $remotenode);
  }

  print OUT localtime(time) . " : Diagcollection completed for $cell\n";
  close OUT;
  exit;
}

#========== tfactldiagcollect_ips
#
sub tfactldiagcollect_ips {
  my $tfa_home          = shift;
  my $listOfNodesref    = shift;
  my $opts              = shift;
  my $from              = shift;
  my $to                = shift;
  my $for               = shift;
  my $since             = shift;

  my @listOfNodes       =@$listOfNodesref;
  my $localhost=tolower_host(); 
  my @hostlist;
  my $localhostincluded = FALSE;
  my @collectiondirs;
  my %collectiondirscheck;

=head
  my @parallelpids;
  my $parallelndx = 0;
  my %parallelfiles;
  my %parallelfilesdesc;
=cut

  #print "List of nodes,\n";
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                    "List of nodes,", 'y', 'y');
  foreach my $node (@listOfNodes) {
    if ( $node ne $localhost ) {
      push @hostlist, $node;
      #print "Node $node\n";
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                        "Node $node", 'y', 'y');
    } else {
      $localhostincluded = TRUE;
    }
  } # end foreach @listOfNodes

  if ( not $localhostincluded ) {
    print "$localhost was not included in the node list.\n";
    print "For ips collections $localhost must be included in the list.\n";
    return ( "error", @collectiondirs  );
  }

  my $totalhomepaths;
  my $completedpaths;
  my $totcompletedpaths;

  # -ips checking
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                       "Before -ips checking ...", 'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                       "DSCRIPT_DEF $DSCRIPT_DEF DSCRIPT_NOIPS $DSCRIPT_NOIPS", 'y', 'y');

  if ( (not $DSCRIPT_NOIPS) && 
      ($opts =~ /-ips/ || $DSCRIPT_DEF) ) {
    my $ipscmd;
    my $mstripscmd;
    my $ipspkgnmbr;
    my $ipsrempkgnmbr;
    my $remote_home;
    my $remote_node;
    my $month;
    my $day;
    my $year;
    my $hour;
    my $min;
    my $sec;
    my $ipsoutput;
    my $ipscompletedout = "";
    my $execoutput;
    my $remotereldiag;
    my $integration_supported = FALSE;
    my $ips_create_pack_cmd;
    my @adrhomepatharray;
    my $starttimeips;
    my $collectionid = strftime("%Y%m%d%H%M%S", localtime()) . "ipscoll_$localhost";
    # Handle $ipsresumeips
    if ( length $ipsresumeips ) {
      $collectionid = $ipsresumeips;
    }

    $TFAIPS_COLLECTIONID = $collectionid;
    $TFAIPS_PACKTYPE = "timerange";

    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                          "-ips checking ...", 'y', 'y'); 

    # ========================
    # Validate IPS correlation level
    if ( $TFAIPS_CORRLVL ne "basic" && $TFAIPS_CORRLVL ne "typical" &&
         $TFAIPS_CORRLVL ne "all" ) {
      $TFAIPS_CORRLVL = "basic";
    }

    if ( $TFAIPS_INCIDENTNMBR && length $TFAIPS_INCIDENTNMBR || 
         $TFAIPS_PROBLEMNMBR  && length $TFAIPS_PROBLEMNMBR  ||
         $TFAIPS_PROBLEMKEY   && length $TFAIPS_PROBLEMKEY      ) {
      my $packtype_val;
      if ( $TFAIPS_INCIDENTNMBR ) {
        $TFAIPS_PACKTYPE = "incident";
        $packtype_val = $TFAIPS_INCIDENTNMBR;
      } elsif ( $TFAIPS_PROBLEMNMBR ) {
        $TFAIPS_PACKTYPE = "problem";
        $packtype_val = $TFAIPS_PROBLEMNMBR;
      } elsif ( $TFAIPS_PROBLEMKEY ) {
        $TFAIPS_PACKTYPE = "problemkey";
        $packtype_val = $TFAIPS_PROBLEMKEY;
        $packtype_val =~ s/\"/\'/g;
        if ( $packtype_val !~ /\'.*\'/ ) {
          $packtype_val = "'" . $packtype_val . "'";
        }
      }

      $ipscmd = "ips create package $TFAIPS_PACKTYPE $packtype_val correlate $TFAIPS_CORRLVL ";
      my $timeval; 
      if ( $since  =~ /([0-9]+)[hH]/ ) {
       $timeval = $1 * 60 * 60;  
      } elsif ( $since  =~ /([0-9]+)[dD]/ ) {
       $timeval = $1 * 24 * 60 * 60;
      }    
      my $starttime = strftime "%Y-%m-%d %H:%M", localtime( time() - $timeval );
      my $endtime = strftime "%Y-%m-%d %H:%M", localtime();
      $starttimeips = $endtime;

      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                          "$TFAIPS_PACKTYPE $packtype_val", 'y', 'y');
    } elsif ( defined $from && defined $to ) {
      my $convfrom;
      my $convto;
      if ( $from  =~ /([a-zA-Z]{3})\/([0-9]{1,2})\/([0-9]{4})\s+(.*)/ ) {
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                          "Pars. 1-4 $1 : $2 : $3 : $4", 'y', 'y');
        if (exists($dateutils_months_dict{lc($1)})) {
           $month = $dateutils_months_dict{lc($1)};
        }
        $convfrom = $3 . "-" . $month . "-" . $2 . " " . $4;
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                          "from $from convfrom $convfrom", 'y', 'y');
      }
      if ( $to  =~ /([a-zA-Z]{3})\/([0-9]{1,2})\/([0-9]{4})\s+(.*)/ ) {
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                          "Pars. 1-4 $1 : $2 : $3 : $4", 'y', 'y');
        if (exists($dateutils_months_dict{lc($1)})) {
           $month = $dateutils_months_dict{lc($1)};
        }
        $convto = $3 . "-" . $month . "-" . $2 . " " . $4;
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                          "to $to convto $convto", 'y', 'y');
      }
      $ipscmd = "ips create package time '" . $convfrom . "' to '". $convto . "'" .
                " correlate $TFAIPS_CORRLVL integration tfa $TFAIPS_ALLFILESTXT";
      $starttimeips = $convto;
    # end if defined $from && defined $to
    } elsif ( defined $for  ) {
      my $convfor;
      my $convto;
      if ( $for  =~ /([a-zA-Z]{3})\/([0-9]{1,2})\/([0-9]{4})\s+(.*)/ ) {
        $month = $1;
        $day   = $2;
        $year  = $3;
        if ( $4 =~ /(.*)\:(.*)\:(.*)/ ) {
          $hour = $1;
          $min  = $2;
          $sec  = $3;
        }
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                          "month:$month, day:$day, year:$year, hour:$hour, min:$min, sec:$sec", 'y', 'y');
        if (exists($dateutils_months_dict{lc($month)})) {
           $month = $dateutils_months_dict{lc($month)};
        }

        my $reftime = timelocal($sec,$min,$hour,$day,$month-1,$year);
        my $beftime = $reftime - 43200;
        my $afttime = $reftime + 43200;
        $convfor = strftime "%Y-%m-%d %H:%M:%S", localtime $beftime;
        $convto  = strftime "%Y-%m-%d %H:%M:%S", localtime $afttime;
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                          "for $for convfor $convfor", 'y', 'y');
      }
      $ipscmd = "ips create package time '" . $convfor . "' to '". $convto . "'" .
                " correlate $TFAIPS_CORRLVL integration tfa $TFAIPS_ALLFILESTXT";
      $starttimeips = $convto;
    # end if defined $for
    } elsif ( defined $since || defined $from ) {
      my $timeval;
      my $starttime="";
      my $endtime = strftime "%Y-%m-%d %H:%M", localtime();

      if ( $since  =~ /([0-9]+)[hH]/ ) {
       $timeval = $1 * 60 * 60;
      } elsif ( $since  =~ /([0-9]+)[dD]/ ) {
       $timeval = $1 * 24 * 60 * 60;
      }

      if ( defined $since ) {
        $starttime = strftime "%Y-%m-%d %H:%M", localtime( time() - $timeval );
      } elsif ( defined $from ) {

        if ( $from  =~ /([a-zA-Z]{3})\/([0-9]{1,2})\/([0-9]{4})\s+(.*)/ ) {
          tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                            "Pars. 1-4 $1 : $2 : $3 : $4", 'y', 'y'); 
          if (exists($dateutils_months_dict{lc($1)})) {
             $month = $dateutils_months_dict{lc($1)};
          }
          $starttime = $3 . "-" . $month . "-" . $2 . " " . $4;
          tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                            "from $from", 'y', 'y');                    
        }
      } # end if, defined $since

      $starttimeips = $endtime;
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                        "starttime $starttime endtime $endtime", 'y', 'y');
      $ipscmd = "ips create package time '" . $starttime . "' to '". $endtime . "'" .
                " correlate $TFAIPS_CORRLVL integration tfa $TFAIPS_ALLFILESTXT";
    } # end if defined $since
      # end for -from -to , -for , -since
      # =================================

    ###print "\n\nIps command $ipscmd \n\n";

    my $tfa_base = tfactlshare_get_repository_location($tfa_home);
    # ips_base location
    my $ips_base = catfile($tfa_base,"suptools","ips");
    my $tfauser = tfactlshare_get_user();
    my $usrips_base = catfile($ips_base,"user_$tfauser");
    my $mstrips_base;

    tfactlshare_check_type_base($tfa_home,"ips");
    # Create $usrips_base when running in non daemon mode.
    eval { tfactlshare_mkpath("$usrips_base", "1741") if ( ! -d "$usrips_base" );
         };
    if ($@)
    {
      # print STDERR "Can not create path $usrips_base \n";
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect_ips " .
                        "Can not create path $usrips_base, DIAGDIRIPS = FALSE",'y', 'y');
      $DIAGDIRIPS = FALSE;
    } else {
      $DIAGDIRIPS = TRUE;
    }

    $ips_base = catfile($ips_base,"user_$tfauser",$collectionid);
    $TFAIPS_COLLECTIONDIR_REL = $ips_base;

    print "tfactldiagcollect_ips usrips_baser $usrips_base\n" if $debugips;
    if ( not $DIAGDIRIPS ) {
      # unexpected error, TFA IPS diagnostic directory not found
      tfactlshare_signal_exception(206, undef);
    }

    # push collectiondirs for the master
    if ( not exists $collectiondirscheck{$ips_base} ) {
      push @collectiondirs, $ips_base;
      $collectiondirscheck{$ips_base} = TRUE;
    }

    #
    # Create a logical IPS package in the masternode specifying the keyfile.
    #
    ### $ipscmd .= $ips_base . "/keyfile.xml";

    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                      "ipscmd $ipscmd", 'y', 'y');
    print "Creating ips package in master node ...\n";

    #
    if ( defined $TFAIPS_ADRCIHOMEPATH && length $TFAIPS_ADRCIHOMEPATH ) {
      @adrhomepatharray = split /,/ , $TFAIPS_ADRCIHOMEPATH;
      ###print "adrhomepatharray @adrhomepatharray " . $#adrhomepatharray . "\n";
    } else {
      # Prepare ADR homepaths for interactive mode
      # to be stored in 
      # $tfactlglobal_adrbasepaths{$TFAIPS_ADRBASE} = join(",",@items)
=head
      print "before show package\n";
      print "TFAIPS_ADRBASE $TFAIPS_ADRBASE\n";
      print "TFAIPS_ADRHOMEPATH $TFAIPS_ADRHOMEPATH\n";
=cut
      tfactlshare_call_adrci("ips show package", "yes","no","","","yes",
                              $TFAIPS_ADRBASE,"no");
      #print "after show package\n";
      ###trace print "TFAIPS_ADRHOMEPATH_MULTI $TFAIPS_ADRHOMEPATH_MULTI \n";
      if ( defined $TFAIPS_ADRHOMEPATH_MULTI && length $TFAIPS_ADRHOMEPATH_MULTI ) {
           @adrhomepatharray = split /,/ , $TFAIPS_ADRHOMEPATH_MULTI;
      } else {
        if ( not @adrhomepatharray ) {
         push @adrhomepatharray, "";
        }
      }
    }

    # su section
    $mstripscmd = $ipscmd;

    ### ----------------------------------------------------
    ### Begin, Loop through homepath array
    ### ----------------------------------------------------
    $totalhomepaths = $#adrhomepatharray;
    $completedpaths = 0;
    $totcompletedpaths = 0 ;
    my %remreldiagpath;
    my @adrbasepatharray;

    # -------------------------
    # Assemble basepath entries
    # -------------------------
    print "tfactldiagcollect_ips Assemble basepath entries ...\n" if $debugips;
=head
    print "TFAIPS_ADRCIHOMEPATH $TFAIPS_ADRCIHOMEPATH\n";
    print "TFAIPS_ADRHOMEPATH   $TFAIPS_ADRHOMEPATH\n";
    print "TFAIPS_ADRHOMEPATH_MULTI $TFAIPS_ADRHOMEPATH_MULTI\n";
    print "TFAIPS_ADRBASE       $TFAIPS_ADRBASE\n";
=cut
    my $totkeys = keys (%tfactlglobal_adrbasepaths);
    # print "Number of keys $totkeys\n";
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                      "Number of keys $totkeys", 'y', 'y');
    foreach my $key ( keys (%tfactlglobal_adrbasepaths) ) {
       push @adrbasepatharray , $key;
       print "tfactldiagcollect_ips, key $key -> $tfactlglobal_adrbasepaths{$key} \n" if $debugips;
       tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                      "key $key -> $tfactlglobal_adrbasepaths{$key}", 'y', 'y');
    } # end foreach keys (%tfactlglobal_adrbasepaths)

    # =====================================================================
    # start loop for looping through $#adrbasepatharray
    # =====================================================================

    if ( $debugips ) {
      print "tfactldiagcollect_ips, start loop for looping through adrbasepatharray\n";
      print "----------------------------------------------------------------------\n";
      print "tfactldiagcollect_ips, debugips = tfactlglobal_diag_base $tfactlglobal_diag_base\n";
      print "tfactldiagcollect_ips, debugips = tfactlglobal_trace_path $tfactlglobal_trace_path\n";
    }

    # Pool processing vars
    my $poolsize  = $tfaIpsPoolSize;
    my $processed = 0;
    my %mstr_parallelfiles_lot;
    my $tot_primfor = $#adrbasepatharray;

    for my $ndx_adrbase ( 0 .. $#adrbasepatharray ) {
    # --------------------------
    # Assemble @adrhomepatharray
    # --------------------------
    $TFAIPS_ADRBASE = $adrbasepatharray[$ndx_adrbase];
    @adrhomepatharray = split /,/ , $tfactlglobal_adrbasepaths{$TFAIPS_ADRBASE};

    # Prepare $mstrips_base based on the owner of the ADR basepath
    # Map an ADR basepath to an os owner
    # ==================================================
    # ==================================================

    print "Trying ADR basepath $TFAIPS_ADRBASE\n";

    my $tot_secfor = $#adrhomepatharray;
    for my $ndx ( 0 .. $#adrhomepatharray ) {
    my $reldiagpath = $adrhomepatharray[$ndx];
    $TFAIPS_ADRCIHOMEPATH = $adrhomepatharray[$ndx];

    # su section
    my $osowner = getFileOwner(catfile($TFAIPS_ADRBASE,$TFAIPS_ADRCIHOMEPATH));

    if ( $current_user eq "root" && not $IS_WINDOWS ) {
      $ips_base = catfile($TFAIPS_COLLECTIONDIR_REL,"user_$osowner");
    } else {
      $ips_base = $TFAIPS_COLLECTIONDIR_REL;
    } # end if $current_user eq "root" && not $IS_WINDOWS
    $mstrips_base = $ips_base;
    $TFAIPS_COLLECTIONDIR = $mstrips_base;


    # Verify hpath dirs
    # Verify hpath ownership
    my $hpdir = catfile($mstrips_base,$reldiagpath);

    $TFAIPS_TARGETHOMEPATH = $hpdir;

    # ===================
    # Prepare MASTER NODE diag path
    # ===================
    eval {
       my $incpkgdir = catfile($hpdir,"incpkg");
       mkpath($incpkgdir) if ( ! -d $incpkgdir );
       # su section
       if (not $IS_WINDOWS ) {
         if ( $current_user eq "root" ) {
           `$CHOWN -R $osowner $ips_base`;
           my $pgroup = getgrgid $(;
           `$CHGRP -R $pgroup $ips_base`;
         } else {
           `$CHMOD -R 771 $ips_base`;
         }
       }
    };
    if ( $@ ) {
      print "Error while creating $hpdir.\n";
      print "$@\n";
      exit 1;
    }

    #tfactlshare_create_dir("$hpdir", "740") if ( ! -d "$hpdir" );
    $ips_base = $hpdir;
    $ipscmd = $mstripscmd . "manifest " . catfile($ips_base,"manifest.xml") . " keyfile " . 
              catfile($ips_base,"/keyfile.xml");

    if ( $IS_WINDOWS && $ipspre122 ) {
      $ipscmd = $mstripscmd;
    }

    print $ipsfh "$debugtime ipscmd $ipscmd \n" if $debugips;
    printc "Trying to use ADR homepath $TFAIPS_ADRCIHOMEPATH ...\n" if
          defined $TFAIPS_ADRCIHOMEPATH && length $TFAIPS_ADRCIHOMEPATH;

    # ------------------------------------------------------------------
    # call master ips processing
    #      remote ips processing is inside tfactldiagcollect_master_ips
    # ------------------------------------------------------------------
    my $retvalfrommaster;
    my $collectiondirsref;
    my $remreldiagpathref;
    my $adrhomepatharrayref;

=head
    ($retvalfrommaster, $collectiondirsref, $integration_supported, $ips_create_pack_cmd,
     $completedpaths,   $remreldiagpathref, $TFAIPS_PURGEREMOTE,    $TFAIPS_ADRCIORACLEHOME,
     $TFAIPS_ADRCIHOMEPATH,       $adrhomepatharrayref) = tfactldiagcollect_master_ips(
           $tfa_home,             $tfauser,                $localhost,       $starttimeips,         $collectionid,
           $ipscmd,               $reldiagpath,     $ips_base,             $mstrips_base,
           $hpdir,                \@hostlist,            \@collectiondirs,        
           \%collectiondirscheck, \@adrhomepatharray,
           $TFAIPS_ADRCIHOMEPATH, $TFAIPS_ADRCIORACLEHOME, $TFAIPS_ADRBASE,  $TFAIPS_ADRHOMEPATH,   $TFAIPS_OHOME,
           $TFAIPS_PACKTYPE,      $TFAIPS_TARGETHOMEPATH );

    @collectiondirs = @$collectiondirsref;
    %remreldiagpath = %$remreldiagpathref;
=cut

    # ---------------------------------------------------------------
    # start master ips submission
    # ---------------------------------------------------------------
    my $pid; 
    my $aux_commfile;

    eval {
      local $SIG{ALRM} = sub { die "alarm\n" };
      if ( $IS_ADE ) {
        alarm $TFAIPS_ADETIMEOUT;
      } else {
        alarm $TFAIPS_NONADETIMEOUT;
      }
      $mstr_parallelndx += 10;
      my $commfile = catfile($TFAIPS_COLLECTIONDIR_REL,"mstr_parrips" . $mstr_parallelndx . ".log");
      $aux_commfile = $commfile;
      if ( not exists $mstr_parallelfiles{$commfile} ) {
        $mstr_parallelfiles{$commfile} = FALSE;
        $mstr_parallelfilesdesc{$commfile} = catfile($TFAIPS_ADRBASE,$TFAIPS_ADRCIHOMEPATH);
        print "Submitting request to generate package for ADR homepath $mstr_parallelfilesdesc{$commfile}\n";
      }

      $pid = fork();
      if ( $pid ) {
        # master
        my $output;
        push @mstr_parallelpids, $pid;
      } else {
        # slave
        {
        ###print "File: " . catfile($TFAIPS_COLLECTIONDIR_REL,"mstr_parrips" . $mstr_parallelndx . ".log") . "\n";
        local *STDOUT;
        local *STDERR;
        open STDOUT, ">>", catfile($TFAIPS_COLLECTIONDIR_REL,"mstr_parrips" . $mstr_parallelndx . ".log") or die $!;
        open STDERR, ">>", catfile($TFAIPS_COLLECTIONDIR_REL,"mstr_parrips" . $mstr_parallelndx . ".log") or die $!;

        print "befretfrommaster:TFAIPS_ADRCIORACLEHOME_$TFAIPS_ADRCIORACLEHOME\n";
        # print "ips_base: $ips_base , mstrips_base $mstrips_base \n";
        ($retvalfrommaster, $collectiondirsref, $integration_supported, $ips_create_pack_cmd,
         $completedpaths,   $remreldiagpathref, $TFAIPS_PURGEREMOTE,    $TFAIPS_ADRCIORACLEHOME,
         $TFAIPS_ADRCIHOMEPATH,       $adrhomepatharrayref) = tfactldiagcollect_master_ips(
               $tfa_home,             $tfauser,                $localhost,       $starttimeips,         $collectionid,
               $ipscmd,               $reldiagpath,     $ips_base,             $mstrips_base,
               $hpdir,                \@hostlist,            \@collectiondirs,
               \%collectiondirscheck, \@adrhomepatharray,
               $TFAIPS_ADRCIHOMEPATH, $TFAIPS_ADRCIORACLEHOME, $TFAIPS_ADRBASE,  $TFAIPS_ADRHOMEPATH,   $TFAIPS_OHOME,
               $TFAIPS_PACKTYPE,      $TFAIPS_TARGETHOMEPATH,  $TFAIPS_CORRLVL, $TFAIPS_ALLFILES,
               $ipsmanageips, $ipsresumeips );

        print "retvalfrommaster:$retvalfrommaster\n";
        print "afterretfrommaster:TFAIPS_ADRCIORACLEHOME_$TFAIPS_ADRCIORACLEHOME\n";
        ###print "mstr_parallelfiles:@mstr_parallelfiles\n";
        if ( $retvalfrommaster eq "manageips" ) {
          print "completed slave\n";
          close STDOUT or die "Can't restore STDOUT\n";
          close STDERR or die "Can't restore STDERR\n";
          # manageips section
          if ( $IS_WINDOWS ) {
            my $manageipsfile;
            if ( $TFAIPS_COLLECTIONDIR_REL =~ /(.*)[\/\\]$TFAIPS_COLLECTIONID.*/ ) {
                 $manageipsfile = catfile($1,$TFAIPS_COLLECTIONID . "_manageips_completed.log");
              }
            while ( not -e $manageipsfile ) {
              sleep(2);
            }
          } # end if $IS_WINDOWS
          exit;
        }
        if ( $retvalfrommaster eq "error" ) {
          print "completed slave\n";
        } else {

        @collectiondirs = @$collectiondirsref;
        %remreldiagpath = %$remreldiagpathref;

        print "completedpaths:$completedpaths\n";
        print "collectiondirs:@collectiondirs\n";
        print "TFAIPS_PURGEREMOTE:$TFAIPS_PURGEREMOTE\n";
        print "remreldiagpath:%remreldiagpath\n";
        print "completed slave\n";
        }
        close STDOUT or die "Can't restore STDOUT\n";
        close STDERR or die "Can't restore STDERR\n";
        if ( $IS_WINDOWS ) {
          my $donefile;
          if ( $TFAIPS_COLLECTIONDIR_REL =~ /(.*)[\/\\]$TFAIPS_COLLECTIONID.*/ ) {
               $donefile = catfile($1,$TFAIPS_COLLECTIONID . "_mstr_completed.log");
            }    
          while ( not -e $donefile ) {
            sleep(2);
          }    
        } # end if $IS_WINDOWS
        exit;
        }
      }
      alarm 0;
      }; # end eval()
      if ( $debugips ) {
        print "tfactldiagcollect_ips completed slave submission for the master.\n";
        print "----------------------------------------------------------------\n";
      }

      # Pool processing
      ++$processed;
      ### print "aux_commfile $aux_commfile\n";

      if ( not exists $mstr_parallelfiles_lot{$aux_commfile} ) {
        $mstr_parallelfiles_lot{$aux_commfile} = FALSE;
      }

      if ( ( $processed % $poolsize == 0 ) || 
           ( $ndx_adrbase == $tot_primfor && $ndx == $tot_secfor ) ) {

        my $aux_ipscompletedout = "";
        my $collectiondirs_ref;
        my $completedpaths_ref;
        my $ipscompletedout_ref;

        if ( $debugips ) {
          print "Before tfactldiagcollect_ips_syncmaster() call ...\n";
          print" mstr_parallelfiles_lot keys \n";
          foreach my $key (keys %mstr_parallelfiles_lot) {
             print "lot key $key \n";
          }
        } # end if $debugips

        ( $collectiondirs_ref, $completedpaths_ref, $ipscompletedout_ref ) = tfactldiagcollect_ips_syncmaster(
                                \%mstr_parallelfiles_lot, \@collectiondirs, \$aux_ipscompletedout );
        @collectiondirs  = @$collectiondirs_ref;
        $completedpaths  = $$completedpaths_ref;
        $ipscompletedout .= $$ipscompletedout_ref;
        %mstr_parallelfiles_lot = (); # clear before processing next lot
        $totcompletedpaths += $completedpaths;

        print $ipsfh "$debugtime tfactldiagcollect_ips After tfactldiagcollect_ips_syncmaster()\n",
                     "$debugtime tfactldiagcollect_ips rec completedpaths $completedpaths\n",
                     "$debugtime tfactldiagcollect_ips rec ipscompletedout $ipscompletedout\n",
                     "$debugtime tfactldiagcollect_ips Lot completed ...\n\n",
                     "$debugtime tfactldiagcollect_ips ipscompletedout_ref " . $$ipscompletedout_ref . "\n" if $debugips;

        if ( $debugips ) {
          print "---------------------------------------\n";
          print "tfactldiagcollect_ips Lot completed ...\n"; 
          print "---------------------------------------\n";
          print "tfactldiagcollect_ips After tfactldiagcollect_ips_syncmaster() call ...\n";
          print "tfactldiagcollect_ips completedpaths $completedpaths\n";
          print "tfactldiagcollect_ips ipscompletedout $ipscompletedout\n";
          print "tfactldiagcollect_ips ipscompletedout_ref " . $$ipscompletedout_ref . "\n";
          print "---------------------------------------\n";
        }

      } # end if $processed % $poolsize == 0

      # ---------------------------------------------------------------
      # stop master ips submission
      # ---------------------------------------------------------------

      ### print "Completed master submission ...\n";

    } # end for $#adrhomepatharray  -  hpaths
    print "tfactldiagcollect_ips, completedpaths ==> $completedpaths for $TFAIPS_ADRBASE\n" if $debugips;
    } # end for $#adrbasepatharray
    ### $ipscompletedout = "";

    print "tfactldiagcollect_ips, totcompletedpaths ==> $totcompletedpaths\n" if $debugips;

    # =====================================================================
    # stop loop for looping through $#adrbasepatharray
    # =====================================================================

    # master ips parallel sync
    #-------------------------
    $debugips = tfactlshare_getdebugips($tfa_home);
    
    if ( $debugips ) {
      print "tfactldiagcollect_ips All lots completed ... \n";
      print "tfactldiagcollect_ips completedpaths $completedpaths\n";
      print "tfactldiagcollect_ips parallel array @parallelpids\n";

      print $ipsfh "$debugtime tfactldiagcollect_ips All lots completed ... \n",
                   "$debugtime tfactldiagcollect_ips completedpaths $completedpaths\n",
                   "$debugtime tfactldiagcollect_ips parallel array @parallelpids\n";
      print $ipsfh "$debugtime master ips parallel sync\n",
                   "$debugtime ips_base $ips_base\n",
                   "$debugtime mstrips_base $mstrips_base\n",
                   "$debugtime master parallel array @mstr_parallelpids\n" if $debugips;
    }

    # ===========================
    # remote ips parallel sync
    # ===========================

   # Pause for manageips
    if ( $ipsmanageips ) {
      #my $localhost = tolower_host();
      my $msgdir = $TFAIPS_COLLECTIONDIR_REL;
      $msgdir =~ s/[\/\\]$collectionid//g;
      my $message ="$localhost:manageips:$collectionid $msgdir $opts";
      my $command = buildCLIJava($tfa_home,$message);
      if ( $debugips ) {
        print "tfactldiagcollect_ips, pause 4 manageips. message $message\n";
        print "tfactldiagcollect_ips, pause 4 manageips. command $command\n";
        print $ipsfh "tfactldiagcollect_ips, pause 4 manageips. message $message\n",
                     "tfactldiagcollect_ips, pause 4 manageips. command $command\n";
      }
      my $suspendedok = FALSE;
      my @cli_output = tfactlshare_runClient($command);
      foreach my $line ( @cli_output ) {
         #print "line $line\n";
         if ( $line =~ /SUCCESS/ ) {
           $suspendedok = TRUE;
         }
      }
      if ( not $suspendedok ) {
        print "TFA IPS operation failed for pause.\n";
        # manageips section
        if ( $IS_WINDOWS ) {
          my $manageipsfile;
          my $manageipsfilecmd;
          if ( $TFAIPS_COLLECTIONDIR_REL =~ /(.*)[\/\\]$TFAIPS_COLLECTIONID.*/ ) {
            $manageipsfile    = catfile($1,$TFAIPS_COLLECTIONID . "_manageips_completed.log");
            $manageipsfilecmd = 'echo done >> ' . $manageipsfile;
          }
          `$manageipsfilecmd`;
          sleep(2);
        } # end if $IS_WINDOWS
        return ( "error", @collectiondirs  );
      }

      # Prepare state file
      # state file section
      my $statefile = "$TFAIPS_COLLECTIONDIR_REL/state.log";
      open(my $sfh, '>', $statefile) or die "Could not open file '$statefile' $!";

      if ( length $ipscompletedout ) {
        print "$ipscompletedout\n";
        my $localbase;
        my $localhomepath;
        my $localmsg;
        foreach my $line (split /\n/ , $ipscompletedout ) {
          if ( $line =~ /Master package completed for ADR homepath (.*)/ ) {
            if ( $1 =~ /(.*)[\/\\]diag[\/\\](.*)/ ) {
              $localbase = $1;
              if ( not $IS_WINDOWS ) {
                $localhomepath = "diag/" . $2;
              } else {
                $localhomepath = "diag\\" . $2;
              }
            }
          } elsif ( $line =~ /Created package .*/ ) {
            $localmsg = $line;
            $localmsg =~ s/\./\:/g;
          } elsif ( $line =~ /DIA\-[0-9]+/ ) {
            $localmsg = $line;
          }
          if (length $localbase && length $localhomepath && length $localmsg ) {
            print $sfh "createpackage=$localbase.$localhomepath.$localmsg\n";
            $localbase = "";
            $localhomepath = "";
            $localmsg = "";
          }
        } # end foreach
      }
      print "TFA IPS collection is now paused for package manipulation.\n";
      print "Once completed please run, tfactl diagcollect -resumeips $collectionid\n";
      print $ipsfh "$debugtime opts sent for msg manageips: $opts\n\n" if $debugips;

      foreach my $key ( keys (%tfactlglobal_adrbasepaths) ) {
         print $sfh "tfactlglobal_adrbasepaths=$key.$tfactlglobal_adrbasepaths{$key}\n";
      }

      print $sfh "TFAIPS_ADRCIHOMEPATH=$TFAIPS_ADRCIHOMEPATH\n" .
            "TFAIPS_ADRCIORACLEHOME=$TFAIPS_ADRCIORACLEHOME\n" .
            "TFAIPS_OHOME=$TFAIPS_OHOME\n" .
            "TFAIPS_ADRBASE=$TFAIPS_ADRBASE\n" .
            "TFAIPS_ADRHOMEPATH=$TFAIPS_ADRHOMEPATH\n" .
            "TFAIPS_CORRLVL=$TFAIPS_CORRLVL\n" .
            "TFAIPS_INCIDENTNMBR=$TFAIPS_INCIDENTNMBR\n" .
            "TFAIPS_PROBLEMNMBR=$TFAIPS_PROBLEMNMBR\n" .
            "TFAIPS_PROBLEMKEY=$TFAIPS_PROBLEMKEY\n" .
            "TFAIPS_UNDO_ADRBASEPATH=$TFAIPS_UNDO_ADRBASEPATH\n" .
            "TFAIPS_UNDO_ADRHOMEPATH=$TFAIPS_UNDO_ADRHOMEPATH\n";
      close $sfh;
      # sync with manageips
      if ( $IS_WINDOWS ) {
        my $manageipsfile;
        my $manageipsfilecmd;
        if ( $TFAIPS_COLLECTIONDIR_REL =~ /(.*)[\/\\]$TFAIPS_COLLECTIONID.*/ ) {
          $manageipsfile    = catfile($1,$TFAIPS_COLLECTIONID . "_manageips_completed.log");
          $manageipsfilecmd = 'echo done >> ' . $manageipsfile;
        }
        `$manageipsfilecmd`;
        sleep(2);
      } # end if $IS_WINDOWS 
      exit;
    } # end if $ipsmanageips

    %parallelfiles = ();
    my @remfileslistcmd;
    if ( not $IS_WINDOWS ) {
      @remfileslistcmd = `$FIND $TFAIPS_COLLECTIONDIR_REL -name rem_parrips*.log -print`;
    } else {
      my $winfind = "DIR " . $TFAIPS_COLLECTIONDIR_REL . "\\rem_parrips*.log";
      print "tfactldiagcollect_ips, winfind cmd " . $winfind . "\n" if $debugips;
      @remfileslistcmd = `$winfind 2> $DEVNULL`;
    }

    if ( $debugips ) {
      print "tfactldiagcollect_ips TFAIPS_COLLECTIONDIR " . $TFAIPS_COLLECTIONDIR . "\n";
      print "tfactldiagcollect_ips TFAIPS_COLLECTIONDIR_REL " . $TFAIPS_COLLECTIONDIR_REL . "\n";
      print "tfactldiagcollect_ips remfileslistcmd ( @remfileslistcmd )\n";
      print $ipsfh "remfileslistcmd @remfileslistcmd\n";
    }

    foreach my $remfile ( @remfileslistcmd ) {
       if ( not $IS_WINDOWS ) {
         $remfile = trim($remfile);
         print "tfactldiagcollect_ips linux remfile $remfile\n" if $debugips;
       } else {
         if ( $remfile =~ /.*rem_parrips(.*)\.log.*/ ) {
           $remfile = catfile($TFAIPS_COLLECTIONDIR_REL,"rem_parrips" . $1 . "\.log");
           print "tfactldiagcollect_ips windows remfile $remfile\n" if $debugips;
         } else {
           $remfile = "";
         }
       } # end else not $IS_WINDOWS
       if ( length $remfile && (not exists $parallelfiles{$remfile}) ) {
         $parallelfiles{$remfile} = FALSE;
       }
    } # end foreach @remfileslistcmd

    if ( @hostlist ) {
      # Wait for parallel remote package completion
      my @rhpatharray;
      my %rhpathhash;
      my $rempackdone = FALSE;
      my $rhpath;

      my $fname;
      my $totkeys = keys (%parallelfiles);
      my $prockeys = 0;

      print "tfactldiagcollect_ips totkeys $totkeys\n" if $debugips;

      my $checking = "none";
      my $cntr=0;
      while ( TRUE ) {
        last if $prockeys == $totkeys;
        foreach my $key ( keys (%parallelfiles) ) {
           next if $parallelfiles{$key} == TRUE;

           # bug 26474385
           $checking = $key if $checking eq "none";
           ++$cntr if $key eq $checking;
           if ($cntr >= $TFAIPS_MAXTRIES ) {
             ++$prockeys;
             $parallelfiles{$key} = TRUE;
             next;
           }

           #print "checking $key\n";
           $fname = $key;
           if ( $IS_WINDOWS ) {
             $fname =~ s/\\/\\\\/g;
           }
           sleep 1;
           my $cmdoutput = tfactlshare_cat($fname);
           if ( $cmdoutput =~ /completed slave/ ) {
             ++$prockeys;
             print "tfactldiagcollect_ips, processed keys prockeys $prockeys, totkeys $totkeys\n"
             if $debugips;
             my $remout = "";
             my $nonmatching = "";
             my $remerrors = "";
             my $dbg = "";
             @rhpatharray = ();
             foreach my $line (split /\n/ , $cmdoutput) {
               $dbg .= "<" . $line . ">\n";
               if ( $line =~ /Created package.*/ ) {
                  $remout .= $line . "\n";
               } elsif ( $line =~ /Finalized package.*/ ) {
                  $remout .= $line . "\n";
               } elsif ( $line =~ /Package.*ready.*:.*([\/\\]diag[\/\\].*)/ ) {
                  $rhpath = $1;
                  if ( not exists $rhpathhash{$rhpath} ) {
                    push @rhpatharray, $rhpath;
                    $rhpathhash{$rhpath} = TRUE;
                  }
                  $remout .= $line . "\n";
               } elsif ( $line =~ /Error\:(.*)/ ) {
                 $remerrors .= "Error:$1\n";
               } elsif ( $line =~ m/^([\/\\][\w\s\.\_\-]+)+$/ || $line =~ m/^\w*([\/\\][\w\s\.\_\-]+)+$/ ) {
                  $remout .= $line . "\n" if length $line;
               } elsif ( $line =~ m/Non matching adrhomepath/ ) {
                 $nonmatching .= $line . "\n";
               } elsif ( $line =~ /remotereldiag\s([\/\\].*)/ ) {
                 $rhpath = "$1";
                 if ( not exists $rhpathhash{$rhpath} ) {
                    push @rhpatharray, $rhpath;
                    $rhpathhash{$rhpath} = TRUE;
                  }
               }
             } # end foreach split /\n/ , $cmdoutput
             $parallelfiles{$key} = TRUE;
             if ( length $remerrors ) {
               # Remote errors -> $ipslogfh
               my $ipscompletedoutr = "";
               $ipscompletedoutr .= "$debugtime remotepack Errors found during the remote package generation for ADR homepath(s) " . join(',', @rhpatharray) ."\n";
               $ipscompletedoutr .= "$debugtime remotepack $remerrors\n";
               $ipscompletedoutr .= "$debugtime remotepack $nonmatching\n";
               print $ipslogfh $ipscompletedoutr;
             } else {
               my $remhpaths = join(',', @rhpatharray);
               $ipscompletedout .= "Remote package completed for ADR homepath(s) $remhpaths\n" if length $remhpaths;
               $ipscompletedout .= $nonmatching;
             } # end if lenght $remerrors 
             print $ipsfh "$debugtime Wait for parallel remote package completion\n",
                          "$debugtime Out dbg,\n$dbg\n" if $debugips; 
             ###$ipscompletedout .= "$remout";
             my $tmpremout = $remout;
             $tmpremout =~ s/\n/\,/g;
             tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                              "Remote package completed for ADR homepath $rhpath", 'y', 'y');
             tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                              "$tmpremout\n\n", 'y', 'y');
             # bug 26474385
             $checking = "none";
             $cntr = 0;
           } # end else , if $cmdoutput =~ /completed slave/
        } # end for each keys (%parallelfiles)
        #print "Waiting for completion ...\n";
      } # end while
    } # end if @hostlist

    foreach my $key ( keys (%parallelfiles) ) {
        print $ipsfh "$debugtime Trying to delete from parallelfiles $key ...\n" if $debugips;
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                          "Trying to delete from parallelfiles $key ...", 'y', 'y');
        unlink $key if (-e $key && (! $debugips));
    }

    # IPS processing output
    # ---------------------
    print "tfactldiagcollect_ips, IPS processing output\n" if $debugips;
    print "$ipscompletedout\n" if length $ipscompletedout;

    # Remove remkeyfiles
    ####
    my $remkeypath;
    if ( $mstrips_base =~ /(.*)[\/\\].*ipscoll.*/ ) {
      $remkeypath = $1;
    }
    print $ipsfh "$debugtime About to remove " . glob catfile ( $remkeypath, "remkeyfile_*.xml") . "\n" if $debugips;
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                      "About to remove " . glob (catfile ( $remkeypath, "remkeyfile_*.xml")) , 'y', 'y');
    unlink glob catfile ( $remkeypath, "remkeyfile_*.xml") if ! $debugips;

    ###return;
    ### -----------------------------

    #exit(0);
    # Reset TFA-IPS environment
    $TFAIPS_ADRCIHOMEPATH   = "";
    $TFAIPS_ADRCIORACLEHOME = "";
    $TFAIPS_ADRHOMEPATH     = "";
    $TFAIPS_INCIDENTNMBR    = "";
    $TFAIPS_PROBLEMNMBR     = "";
    $TFAIPS_PROBLEMKEY      = "";
  } # end if ips checking

  print "tfactldiagcollect_ips, checking totcompletedpaths => $totcompletedpaths ... DSCRIPT_COMP_CMDLINE @DSCRIPT_COMP_CMDLINE\n" if $debugips;
  if ( (not $DSCRIPT_DEF) && ($totcompletedpaths == 0 && $DSCRIPT_IPS && (not @DSCRIPT_COMP_CMDLINE)) ) {
    print $ipsfh "$debugtime No ADR homepaths were processed.\n",
                 "$debugtime In order to generate the TFA collection at least one ADR homepath must be processed.\n" if $debugips;
    return ("error", @collectiondirs );
  }

  return ("ok",@collectiondirs);
} # end sub tfactldiagcollect_ips

#========== tfactldiagcollect_ips_syncmaster
#
sub tfactldiagcollect_ips_syncmaster {
  my $mstr_parallelfiles_ref = shift;
  my $collectiondirs_ref     = shift;
  my $ipscompletedout_ref    = shift;

  my %mstr_parallelfiles = %$mstr_parallelfiles_ref;
  my @collectiondirs     = @$collectiondirs_ref;
  my $completedpaths     = 0;
  my $ipscompletedout    = $$ipscompletedout_ref;

  if ( $debugips ) {
    print $ipsfh "tfactldiagcollect_ips_syncmaster Processing lot ...\n";
    print $ipsfh "$debugtime Processing lot in tfactldiagcollect_ips_syncmaster ...\n";
    foreach my $key (keys %mstr_parallelfiles) {
       print $ipsfh "$debugtime key $key\n";
    }
  } # end if $debugips

    # Wait for parallel master package completion
    my $fname;
    my $totkeys = keys (%mstr_parallelfiles);
    my $prockeys = 0;

    print "tfactldiagcollect_ips_syncmaster totkeys $totkeys\n" if $debugips;

    my $checking = "none"; 
    my $cntr=0;
    while ( TRUE ) {
      last if $prockeys == $totkeys;
      foreach my $key ( keys (%mstr_parallelfiles) ) {
         next if $mstr_parallelfiles{$key} == TRUE;

         # bug 26474385
         $checking = $key if $checking eq "none"; 
         ++$cntr if $key eq $checking;
         if ($cntr >= $TFAIPS_MAXTRIES ) {
           ++$prockeys;
           $mstr_parallelfiles{$key} = TRUE; 
           $ipscompletedout .= "Master package timed out for ADR homepath $mstr_parallelfilesdesc{$key}\n";
           next;
         }

         #print "checking master $key\n";
         $fname = $key;
         if ( $IS_WINDOWS ) {
           $fname =~ s/\\/\\\\/g;
         }
         sleep 1;
         my $cmdoutput = tfactlshare_cat($fname);
         #print "cmdoutput $cmdoutput\n";
         if ( $cmdoutput =~ /completed slave/ ) {
           ++$prockeys;
           print "tfactldiagcollect_ips_syncmaster, processed keys prockeys $prockeys, totkeys $totkeys\n"
           if $debugips;
           my $masterout = "";
           my $mastercreate = "";
           foreach my $line (split /\n/ , $cmdoutput) {
             # print "ipssync line ( $line ) \n";
             if ( $line =~ /Created package.*/ ) {
               $masterout .= $line . "\n";
               $mastercreate = $line . "\n";
             } elsif ( $line =~ /Finalized package.*/ ) {
               $masterout .= $line . "\n";
             } elsif ( $line =~ /Package.*ready under/ ) {
               $masterout .= $line . "\n";
             } elsif ( $line =~ m/^([\/\\][\w\s\.\_\-]+)+$/ || $line =~ m/^\w*([\/\\][\w\s\.\_\-]+)+$/ ) {
               $masterout .= $line . "\n" if length $line;
             } elsif ( $line =~ /completedpaths:(.*)/ ) {
               $completedpaths += $1;
             } elsif ( $line =~ /collectiondirs:(.*)/ ) {
               # todo collectiondirs
               #print "collectiondirs:$1\n";
               @collectiondirs = split / /, $1;
             } elsif ( $line =~ /TFAIPS_PURGEREMOTE:(.*)/ ) {
              $TFAIPS_PURGEREMOTE = $1;
             } elsif ( $line =~ /(DIA\-.*)/ || $line =~ /(.*[Ee][Rr][Rr][Oo][Rr].*)/ ||
                       $line =~ /(.*Additional information.*)/ || $line =~ /(.*doesn\'t exists.*)/ ) {
               print $ipslogfh "$debugtime masterpack $1\n";
             }

           } # end foreach split /\n/ , $cmdoutput
           $mstr_parallelfiles{$key} = TRUE;
           ### print "key $key\n";
           $ipscompletedout .= "Master package completed for ADR homepath $mstr_parallelfilesdesc{$key}\n";
           $ipscompletedout .= "$mastercreate";
           ###$ipscompletedout .= "$masterout";
           ### print "collectiondirs:@collectiondirs\n";
           my $tmpmasterout = $masterout;
           $tmpmasterout =~ s/\n/\,/g;
           tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                            "Master package completed for ADR homepath $mstr_parallelfilesdesc{$key}", 'y', 'y');
           tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                            "$tmpmasterout", 'y', 'y');
           if ( $debugips ) {
             print "tfactldiagcollect_ips_syncmaster, done slave: " .
                   "Master package completed for ADR homepath $mstr_parallelfilesdesc{$key}\n";
             print "tfactldiagcollect_ips_syncmaster, processed keys $prockeys\n";
           }
           # bug 26474385
           $checking = "none";
           $cntr = 0;
         } # end if $cmdoutput =~ /completed slave/
         elsif ( $cmdoutput =~ /(TFA\-00404.*)/){
            print $ipslogfh "$debugtime Error: $1\n";
            $mstr_parallelfiles{$key} = TRUE;
            $ipscompletedout.="$1\n";
            ++$prockeys;
         }#end if XML Error Parser rises an error. 
      } # end for each keys (%mstr_parallelfiles)
      #print "Waiting for master completion ...\n";
    } # end while

    foreach my $key ( keys (%mstr_parallelfiles) ) {
      print $ipsfh "$debugtime Trying to delete from mstr_parallelfiles $key ...\n" if $debugips;
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_ips " .
                        "Trying to delete from mstr_parallelfiles $key ...", 'y', 'y'); 
      unlink $key if (-e $key && (! $debugips));
    }

  if ( $debugips ) {
    print "tfactldiagcollect_ips_syncmaster ret completedpaths $completedpaths\n";
    print "tfactldiagcollect_ips_syncmaster ret ipscompletedout $ipscompletedout\n";
    print "tfactldiagcollect_ips_syncmaster ret collectiondir @collectiondirs\n";
  }

  return (\@collectiondirs, \$completedpaths, \$ipscompletedout);
}

#========== tfactldiagcollect_master_ips
#
sub tfactldiagcollect_master_ips {

  my $tfa_home                    = shift;
  my $tfauser                     = shift;
  my $localhost                   = shift;
  my $starttimeips                = shift;
  my $collectionid                = shift;
  my $ipscmd                      = shift;
  my $reldiagpath                 = shift;
  my $ips_base                    = shift;
  my $mstrips_base                = shift;
  my $hpdir                       = shift;

  my $hostlistref                 = shift;
  my $collectiondirsref           = shift;
  my $collectiondirscheckref      = shift;
  my $adrhomepatharrayref         = shift;

  my $inp_TFAIPS_ADRCIHOMEPATH    = shift;
  my $inp_TFAIPS_ADRCIORACLEHOME  = shift;
  my $inp_TFAIPS_ADRBASE          = shift;
  my $inp_TFAIPS_ADRHOMEPATH      = shift;
  my $inp_TFAIPS_OHOME            = shift;
  my $inp_TFAIPS_PACKTYPE         = shift;
  my $inp_TFAIPS_TARGETHOMEPATH   = shift;
  my $inp_TFAIPS_CORRLVL          = shift;
  my $inp_TFAIPS_ALLFILES         = shift;

  my $ipsmanageips                = shift;
  my $ipsresumeips                = shift;

  my $completedpaths              = 0;
  my @adrhomepatharray      = @$adrhomepatharrayref;
  my %collectiondirscheck   = %$collectiondirscheckref;
  my @collectiondirs        = @$collectiondirsref;
  my @hostlist              = @$hostlistref;
  my %remreldiagpath;
  my $remreldiagpathref;
  my $integration_supported = FALSE;
  my $ips_create_pack_cmd;
  my $ipsoutput;
  my $ipsrempkgnmbr;
  my $ipspkgnmbr;
  my $remote_home;
  my $remote_node;
  my $remotereldiag;
  my $execoutput;
  my $exitstatus;
  my $ipssrcdir;

  my $int_TFAIPS_PURGEREMOTE;


    # Allow multiselect if $inp_TFAIPS_ADRCIHOMEPATH is null
    if ( $debugips ) {
      print $ipsfh "$debugtime tfactldiagcollect_master_ips\n",
                   "$debugtime debugmsg = master_ips ipscmd:$ipscmd\n",
                   "$debugtime debugmsg = inp_TFAIPS_ADRCIORACLEHOME:$inp_TFAIPS_ADRCIORACLEHOME\n",
                   "$debugtime debugmsg = inp_TFAIPS_ADRCIHOMEPATH:$inp_TFAIPS_ADRCIHOMEPATH\n",
                   "$debugtime debugmsg = inp_TFAIPS_ADRBASE:$inp_TFAIPS_ADRBASE\n";
    } # end if $debugips
    $ipsoutput = tfactlshare_call_adrci($ipscmd, "yes","no",$inp_TFAIPS_ADRCIHOMEPATH,
                 $inp_TFAIPS_ADRCIORACLEHOME,"yes",
                 $inp_TFAIPS_ADRBASE,"no") if not length $ipsresumeips;
    print $ipsfh "$debugtime debugmsg = master_ips ipscmd out:$ipsoutput\n" if $debugips;

    # Manage $ipsresumeips
    # --------------------
    if ( length $ipsresumeips ) {
      my $key = $inp_TFAIPS_ADRBASE . "." . $TFAIPS_ADRCIHOMEPATH;
      $ipsoutput = $ipsresumeips_createpack{$key};
    }

    if ( $ipsoutput =~ /No ORACLE_HOME was found/ ) {
      print "Please set ORACLE_HOME and try diagcollect again ...\n";
      ###return ( "error", @collectiondirs );
      return ( FAILED,\ @collectiondirs );
    }

    if ( defined $inp_TFAIPS_ADRHOMEPATH && length $inp_TFAIPS_ADRHOMEPATH && not 
         (defined $inp_TFAIPS_ADRCIHOMEPATH && length $inp_TFAIPS_ADRCIHOMEPATH) ) {
      $inp_TFAIPS_ADRCIHOMEPATH  = $inp_TFAIPS_ADRHOMEPATH;
      @adrhomepatharray = split /,/ , $inp_TFAIPS_ADRCIHOMEPATH;
    }

    if ( defined $inp_TFAIPS_OHOME && length $inp_TFAIPS_OHOME ) {
      $inp_TFAIPS_ADRCIORACLEHOME = $inp_TFAIPS_OHOME;
    }
    #print "Command mstr node $ipscmd ...\n";
    # Validate if integration TFA is supported
    if ( $ipsoutput =~ /DIA\-48415\: Syntax error/ ) {
       # Not supported, try plain style
       $ipscmd =~ s/integration tfa.*//;
       $ips_create_pack_cmd = $ipscmd;
       $ipsoutput = tfactlshare_call_adrci($ipscmd, "yes","yes",$inp_TFAIPS_ADRCIHOMEPATH,
                    $inp_TFAIPS_ADRCIORACLEHOME,"no",
                    $inp_TFAIPS_ADRBASE,"no");
    } elsif ( $ipsoutput =~ /DIA\-49431\: No such incident \[([0-9]+)\]/ ) {
      print "No such incident [$1].\n";
      print "Please select a valid incident for $inp_TFAIPS_ADRCIHOMEPATH and try again ...\n";
      my $tmpipscmd = "show incidents -all";
      my $tmpipsoutput = tfactlshare_call_adrci($tmpipscmd, "yes","no",$inp_TFAIPS_ADRCIHOMEPATH,
                         $inp_TFAIPS_ADRCIORACLEHOME,"no",
                         $inp_TFAIPS_ADRBASE,"no");
      print "$tmpipsoutput\n";
      ###return ( "error", @collectiondirs );
      return ( FAILED,\ @collectiondirs );
    } elsif ( $ipsoutput =~ /DIA\-49430\: No such problem \[([0-9]+)\]/ ) {
      print "No such problem [$1].\n";
      print "Please select a valid problem for $inp_TFAIPS_ADRCIHOMEPATH and try again ...\n";
      my $tmpipscmd = "show problems";
      my $tmpipsoutput = tfactlshare_call_adrci($tmpipscmd, "yes","no",$inp_TFAIPS_ADRCIHOMEPATH,
                         $inp_TFAIPS_ADRCIORACLEHOME,"no",
                         $inp_TFAIPS_ADRBASE,"no");
      print "$tmpipsoutput\n";
      ###return ( "error", @collectiondirs );
      return ( FAILED,\ @collectiondirs );
    } elsif ( $ipsoutput =~ /DIA\-49430\: No such problem \[(.*)\]/ ) {
      print "No such problem key [$1].\n";
      print "Please select a valid problem key for $inp_TFAIPS_ADRCIHOMEPATH and try again ...\n";
      my $tmpipscmd = "show problems";
      my $tmpipsoutput = tfactlshare_call_adrci($tmpipscmd, "yes","no",$inp_TFAIPS_ADRCIHOMEPATH,
                         $inp_TFAIPS_ADRCIORACLEHOME,"no",
                         $inp_TFAIPS_ADRBASE,"no");
      print "$tmpipsoutput\n";
      ###return ( "error", @collectiondirs );
      return ( FAILED,\ @collectiondirs );
    } elsif ( $ipsoutput =~ /DIA-48321\: ADR Relation/ ) {
      print "Warning, the required ADR relation is missing for $reldiagpath.\n";
      next;
    } else {
      $integration_supported = TRUE;
      $completedpaths = 1;
      # Print package created message
      # -----------------------------
      print $ipsoutput if not length $ipsresumeips;
    }

    # Verify if TFA IPS integration is supported by current ADR version
    if ( not $integration_supported ) {
      #print "TFA IPS integration is not supported for pre 12.2.0 versions.\n";
      #$tfactlglobal_error_message{205}
      tfactlshare_error_msg(205, undef) ;
      return ("error", @collectiondirs );
    }


    if ( $ipsoutput =~ /Created package ([0-9]+) .*/ ) {
      $ipspkgnmbr = $1;  # ips package number autogenerated
      tfactlshare_trace(5, "tfactl (PID = $$) tctldiagcollect factldiagcollect_master_ips " .
                        "pack $ipspkgnmbr", 'y', 'y');
    } else {
      # Error during create package
      $collectiondirsref = \@collectiondirs;
      return ("error", $collectiondirsref );
    }

    # Pause for manageips
    if ( $ipsmanageips ) {
      return ("manageips", @collectiondirs );
    }

    #
    # Send the keyfile to the other nodes in the cluster ($tfa_base/keyfile.xml)
    #
    print $ipsfh "$debugtime debugmsg = integration_supported:$integration_supported\n" if $debugips;
    if ( $integration_supported ) {
      # $remfilename = remkeyfile.xml specific to $reldiagpath
      my $dgpath = $reldiagpath;
      $dgpath =~ s/(\/|\\)/_/g;
      $dgpath =~ s/\+/plus/g;
      my $remfilename = "remkeyfile_" . $dgpath . ".xml";

      my $srcfile = catfile($ips_base, "keyfile.xml");
      ####
      my $dstfile;
      if ( $mstrips_base =~ /(.*)[\/\\].*ipscoll.*/ ) {
        $dstfile = catfile($1, "remkeyfile_" . $dgpath . ".xml");
      }
      ####my $dstfile = catfile($mstrips_base, "remkeyfile_" . $dgpath . ".xml");
      my $dstfilebk = $dstfile;

      copy($srcfile, $dstfile);
      print $ipsfh "$debugtime debugmsg = copied $srcfile to $dstfile in the local fs.\n" if $debugips;
      print $ipsfh "$debugtime debugmsg = remfilename $remfilename\n" if $debugips;
      foreach $remote_node ( @hostlist ) {
        # =================================
        # CREATE REMOTE NODE adrcihomepath
        # =================================
        my $args = $inp_TFAIPS_TARGETHOMEPATH . " " . $inp_TFAIPS_ADRCIHOMEPATH . " " . $inp_TFAIPS_ADRCIORACLEHOME . 
                   " " . $inp_TFAIPS_ADRBASE . " dummy";
        $int_TFAIPS_PURGEREMOTE = $args;
        $args =~ s/$localhost/$remote_node/g;
        if ( $debugips ) {
          print $ipsfh "$debugtime debugmsg = tfactldiagcollect_master_ips inp_TFAIPS_TARGETHOMEPATH $inp_TFAIPS_TARGETHOMEPATH\n",
                       "$debugtime debugmsg = tfactldiagcollect_master_ips inp_TFAIPS_ADRCIHOMEPATH $inp_TFAIPS_ADRCIHOMEPATH\n",
                       "$debugtime debugmsg = tfactldiagcollect_master_ips inp_TFAIPS_ADRCIORACLEHOME $inp_TFAIPS_ADRCIORACLEHOME\n",
                       "$debugtime debugmsg = tfactldiagcollect_master_ips inp_TFAIPS_ADRBASE $inp_TFAIPS_ADRBASE\n",
                       "$debugtime debugmsg = tfactldiagcollect_master_ips create remote node adrcihomepath $args\n";
        }
        {
          local *STDOUT;
          open STDOUT, '>/dev/null' or warn "Can't open /dev/null: $!"; 
          $execoutput = executeCommandInHostAndGetOutput(
                $tfa_home,
                "tfactlips",
                $args,
                $remote_node );
          $remotereldiag = $execoutput;
          close STDOUT;
        }
        ###
        # print "Returning from create remote node adrcihomepath ...\n";

        # No ADR homes available
        # during create remote node adrcihomepath
        if ( $execoutput =~ /No ADR homes are set/ ) {
          print "Warning No ADR homes are set in remote node $remote_node.\n";
          next;   
        } else {
          if ( $execoutput =~ /non matching adrhomepath/ ) {
            $remreldiagpath{$remote_node} = $execoutput . " for $inp_TFAIPS_ADRCIHOMEPATH";
          } else {
            $remreldiagpath{$remote_node} = $execoutput;
          }
          my $remips_base = $mstrips_base;
          $remips_base =~ s/$localhost/$remote_node/g;
          if ( not exists $collectiondirscheck{$remips_base} ) {
            push @collectiondirs, $remips_base;
            $collectiondirscheck{$remips_base} = TRUE;
          }
        }

        # Remote node home/dstfile
        $remote_home = $tfa_home;
        my $repodir  = tfactlshare_get_repository_location($tfa_home); 
        if ( not $IS_WINDOWS ) {
          $remote_home =~ s/\/$localhost\/tfa_home/\/$remote_node\/tfa_home/;
        } else {
          $remote_home =~ s/\\$localhost\\tfa_home/\\$remote_node\\tfa_home/;
        }
        # ips_base location
        $dstfile = catfile($repodir,"suptools","ips","user_$tfauser","$collectionid","$remfilename");
        ####$dstfile =~ s/\/$localhost/\/$remote_node/g;
        $dstfile =~ s/$localhost/$remote_node/g;
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_master_ips " .
                          "Real path $remotereldiag", 
                          'y', 'y');

        # Transfer remkeyfile from master node to remote nodes
        # "ipsfile-USER-user_$tfauser-FILE-remkeyfile.xml"
        ####my $cpytagfile = "ipsfile-USER-user_$tfauser/$collectionid/$remfilename";
        my $cpytagfile = "ipsfile-USER-user_$tfauser/$remfilename";
        $cpytagfile =~ s/\//\-FILE\-/g;
        copyTagFile($tfa_home, $cpytagfile, $remote_node);
        print $ipsfh "$debugtime debugmsg = after copyTagFile $srcfile from master node to $dstfile on remote node $remote_node.\n" if $debugips;
        print $ipsfh "$debugtime debugmsg = cpytagfile $cpytagfile\n" if $debugips;
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_master_ips " .
                          "Copied $srcfile from master node to $dstfile on remote node $remote_node", 
                          'y', 'y');
      } # end foreach @hostlist , create remote adrcihomepath
    } # end if $integration_supported


    # ========================================
    # remkeyfile available in remote nodes
    # start remote package generation
    # ========================================

    my $master_args = $inp_TFAIPS_TARGETHOMEPATH . " " . $inp_TFAIPS_ADRCIHOMEPATH . " " . $inp_TFAIPS_ADRCIORACLEHOME . " " .
                      $inp_TFAIPS_ADRBASE . " ";

    if ( $debugips ) {
    print $ipsfh "$debugtime debugmsg = start remote package generation\n",
                 "$debugtime debugmsg = before calling tfactldiagcollect_remote_ips()....\n",
                 "$debugtime debugmsg = tfa_home $tfa_home\n" .
                 "$debugtime debugmsg = tfa_user $tfauser\n" .
                 "$debugtime debugmsg = localhost $localhost\n" .
                 "$debugtime debugmsg = integration_supported $integration_supported\n" .
                 "$debugtime debugmsg = ips_create_pack_cmd $ips_create_pack_cmd\n" .
                 "$debugtime debugmsg = starttimeips $starttimeips\n" .
                 "$debugtime debugmsg = collectionid $collectionid\n" .
                 "$debugtime debugmsg = master_args $master_args\n";
    } # end if $debugips

  my $pid; 

  eval {
    local $SIG{ALRM} = sub { die "alarm\n" };
    if ( $IS_ADE ) {
      alarm $TFAIPS_ADETIMEOUT;
    } else {
      alarm $TFAIPS_NONADETIMEOUT;
    }
    $parallelndx += 10;
    my $commfile = catfile($TFAIPS_COLLECTIONDIR_REL,"parrips" . $parallelndx . ".log");
    if ( not exists $parallelfiles{$commfile} ) {
      $parallelfiles{$commfile} = FALSE;
      $parallelfilesdesc{$commfile} = catfile($inp_TFAIPS_ADRBASE,$inp_TFAIPS_ADRCIHOMEPATH);
      print "Submitting request to generate remote package for $parallelfilesdesc{$commfile} to @hostlist...\n";
    }

    $pid = fork();
    if ( $pid ) {
      # master
      my $output;
      push @parallelpids, $pid;
    } else {
      # slave
      my $t = time();
      my $fileid = strftime "%Y%m%d%H%M%S", localtime $t;
      $fileid .= sprintf ".%03d", ($t-int($t))*1000;
      { 
      local *STDOUT;
      local *STDERR;
      open STDOUT, ">", catfile($TFAIPS_COLLECTIONDIR_REL,"rem_parrips" . $fileid . ".log") or die $!;
      open STDERR, ">", catfile($TFAIPS_COLLECTIONDIR_REL,"rem_parrips" . $fileid . ".log") or die $!;
      tfactldiagcollect_remote_ips($tfa_home, $tfauser, $localhost, $integration_supported,
                                 $ips_create_pack_cmd, $starttimeips, $collectionid, $master_args,
                                 \@hostlist,\%remreldiagpath,$inp_TFAIPS_CORRLVL,$inp_TFAIPS_ALLFILES,
                                 $inp_TFAIPS_ADRBASE,$inp_TFAIPS_ADRCIHOMEPATH); 
      print "ips_create_pack_cmd:$ips_create_pack_cmd\n";
      print "childpid:$$\n";
      print "completed slave\n";
      close ( STDOUT );
      close ( STDERR );
      if ( $IS_WINDOWS ) {
        my $donefile;
        if ( $TFAIPS_COLLECTIONDIR_REL =~ /(.*)[\/\\]$TFAIPS_COLLECTIONID.*/ ) {
             $donefile = catfile($1,$TFAIPS_COLLECTIONID . "_mstr_completed.log");
          }
        while ( not -e $donefile ) {
          sleep(2);
        }
      } # end if $IS_WINDOWS
      exit;
      }
    }
    alarm 0;
    }; # end eval()
    #print "completed slave submission.\n";

    # ========================================
    # stop remote package generation
    # ========================================

    #
    # Finalize package in the master node
    #
    if ( not $ipspre122 ) {
      # 12.2 version windows & linux
      $ipscmd = "ips finalize package " . $ipspkgnmbr . " manifest " . catfile($ips_base,"manifest.xml");
    } else {
      # windows specific, pre 12.2
      $ipscmd = "ips finalize package " . $ipspkgnmbr;
    }
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_master_ips " .
                      "Finalizing package $ipspkgnmbr in the master node ...", 
                      'y', 'y');
    $ipsoutput = tfactlshare_call_adrci($ipscmd, "yes","yes",$inp_TFAIPS_ADRCIHOMEPATH,
                 $inp_TFAIPS_ADRCIORACLEHOME,"no",
                 $inp_TFAIPS_ADRBASE,"no");
    if ( $debugips ) {
       print $ipsfh "$debugtime Finalizing package $ipspkgnmbr in the master node ...\n",
                    "$debugtime ipscmd $ipscmd\n",
                    "$debugtime ipsoutput $ipsoutput\n";
    }
    
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_master_ips " .
                      "ipscmd $ipscmd", 'y', 'y');

    #              ================        ===========
    # Generate the PHYSICAL PACKAGE in the MASTER NODE
    #              ================        ===========
    my $winincident = FALSE; 
    if ( not $ipspre122 ) {
      # generic, 12.2
      $ipscmd = "ips generate package " . $ipspkgnmbr . " in " . $ips_base;
    } else {
      # windows specific, pre 12.2
      $ipscmd = "ips generate package " . $ipspkgnmbr . " in " . $mstrips_base;
      if ( $inp_TFAIPS_PACKTYPE eq "incident" ) {
        $winincident = TRUE;
      }
    }
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_master_ips " .
                      "Generating physical package $ipspkgnmbr in the master node ...", 
                      'y', 'y');
    if ( $inp_TFAIPS_PACKTYPE eq "timerange" || $winincident ) {
      $ipsoutput = tfactlshare_call_adrci($ipscmd, "yes","no",$inp_TFAIPS_ADRCIHOMEPATH,
                   $inp_TFAIPS_ADRCIORACLEHOME,"no",
                   $inp_TFAIPS_ADRBASE,"no");
      # Handle DIA-51705 during IPS package generation
      if ( $ipsoutput =~ /DIA-51705/ ) {
        $ipsoutput = tfactlshare_call_adrci($ipscmd.";".$ipscmd, "yes","no",$inp_TFAIPS_ADRCIHOMEPATH,
                     $inp_TFAIPS_ADRCIORACLEHOME,"no",
                     $inp_TFAIPS_ADRBASE,"no");
        $ipsoutput =~ s/DIA\-51705\: XML XPATH error\: [0-9]* \"XmlXPathEval\"\n//g;
      }
    } elsif ( $inp_TFAIPS_PACKTYPE eq "incident" ||
              $inp_TFAIPS_PACKTYPE eq "problem" ||
              $inp_TFAIPS_PACKTYPE eq "problemkey"    ) {
      $ipsoutput = "Package $ipspkgnmbr ready under TFA ips directory:\n";
    }
    ###print "command $ipscmd ipsoutput $ipsoutput \n\n";
    if ( $debugips ) {
      print $ipsfh "$debugtime Generating physical package $ipspkgnmbr in the master node ...\n",
            "$debugtime ipscmd $ipscmd\n",
            "$debugtime ipsoutput $ipsoutput\n",
            "$debugtime reldiagpath $reldiagpath\n",
            "$debugtime mstrips_base $mstrips_base\n",
            "$debugtime hpdir $hpdir\n";
    }

    print "$ipsoutput" if not $integration_supported;

    foreach my $line (split /\n/ , $ipsoutput) {
       print $ipsfh "$debugtime line $line\n" if $debugips;
       if ( $line =~ /Package .* ready under/ ) {
         print "Package $ipspkgnmbr ready under TFA ips directory:\n";
         print "$ips_base\n";
       } elsif ( $line =~ m/^(([\/\\][\w\s\.\_\-\+]+)+)$/ || $line =~ m/^[\w\:]*([\/\\][\w\s\.\_\-\+]+)+$/ ) {
         my $srcpath = $1;
         if ( $srcpath =~ /(.*)[\/\\].*$/ ) {
           ###print "\n\n cp -r source $1  dst $ips_base \n\n";
           print $ipsfh "$debugtime cp -r source $1  dst $ips_base\n" if $debugips;
           host("$CP -r $1 " . catfile($ips_base,"incpkg"));
         } # end if $srcpath =~ /(.*)[\/\\].*$/
       } elsif ( $line =~ /.*$TFAIPS_FILESEP$TFAIPS_FILESEP(.*)\.zip\,.*/ ) {
         # windows specifc, pre 12.2  
         my $zipname = "";
         $zipname = catfile($mstrips_base,$1 . ".zip");
         print $ipsfh "$debugtime zipname $zipname\n" if $debugips;
         `unzip -u -q $zipname -d $mstrips_base`;
         unlink ( $zipname );
         unlink ( catfile($mstrips_base,"metadata.xml") );
       } # end if $line =~ /Package .* ready under/
    } # end foreach
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_master_ips " .
                      "ipscmd $ipscmd", 'y', 'y');

    if ( not $ipspre122 ) {
    # Generic code for 12.2 only, bypass for pre 12.2
    # Parse manifest file
    my @retfiles;
    my $manifestfile = catfile($ips_base,"manifest.xml");
    ### print "manifest file $manifestfile \n";
    print $ipsfh "$debugtime manifest file $manifestfile \n" if $debugips;

    @retfiles = tfactlshare_parse_pkgmanifest( $manifestfile );
    print "Parsing manifest file manifest.xml ...\n";
    print $ipsfh "$debugtime Parsing manifest file manifest.xml ...\n" if $debugips;

    for my $ndx ( 0 .. $#retfiles ) {
      my $filesdetref = $retfiles[$ndx];
      my @filesdet    = @$filesdetref;
      ### print "checking ... $filesdet[MFILE_NAME] \n";
      print $ipsfh "$debugtime checking ... $filesdet[MFILE_NAME] \n" if $debugips;

     my $srcdir = catfile($filesdet[MADR_HOME],$filesdet[MLOCATION]);
     my $dstdir = catfile($ips_base,$filesdet[MLOCATION]);
     my $srcfile = catfile($srcdir,$filesdet[MFILE_NAME]);
     my $dstfile = catfile($dstdir,$filesdet[MFILE_NAME]);
     $srcdir =~ s/\/\//\//g;
     $srcdir =~ s/\\\\/\\/g;
     $dstdir =~ s/\/\//\//g;
     $dstdir =~ s/\\\\/\\/g;
     $ipssrcdir = $srcdir;

     if ( $debugips ) {
       print $ipsfh "$debugtime srcdir $srcdir , dstdir $dstdir\n";
       print $ipsfh "$debugtime srcfile $srcfile, dstfile $dstfile\n"; 
     }
     ### print "   name $filesdet[MFILE_NAME] $filesdet[MLOCATION] $filesdet[MADR_HOME] \n";
     tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_master_ips " .
                       "process manifest name $filesdet[MFILE_NAME] $filesdet[MLOCATION] " .
                       "$filesdet[MADR_HOME] ", 'y', 'y');
     eval {
       print "$CP \"$srcfile\" \"$dstfile\"\n";
       print "dstdir $dstdir\n";
       mkpath( $dstdir ) if ( ! -d $dstdir );
       if ( not $IS_WINDOWS ) {
         host("$CP $srcfile $dstfile") if ( not -e $dstfile );
       } else {
         host("$CP \"$srcfile\" \"$dstfile\"");
       }
       print $ipsfh "$debugtime $CP $srcfile $dstfile\n" if $debugips;
     };
     if ( $@ ) {
       print "Error while creating  $inp_TFAIPS_TARGETHOMEPATH.\n";
       print $ipsfh "$debugtime Error while creating  $inp_TFAIPS_TARGETHOMEPATH.\n" if $debugips;
       print "$@\n";
       exit 1;
     }

    } # end for $#retfiles

    #
    my $srcalertxml;
    my $srcalert;
    my $dstdiralertxml = catfile($ips_base,"alert");
    my $dstdiralert    = catfile($ips_base,"trace");
    my $dstalertxml = catfile($dstdiralertxml,"log.xml");
    my $dstalert;
    my $auxreldiagpath = $reldiagpath;
    my $auxins;
    $auxreldiagpath =~ s/\+/\\\+/g;
    my $pos = index($ipssrcdir,$auxreldiagpath);
    $ipssrcdir = substr($ipssrcdir,0,$pos) . $auxreldiagpath;
    $srcalertxml = catfile($ipssrcdir,"alert","log.xml");

    print $ipsfh "$debugtime Alertcopy\n" .
                 "$debugtime ipssrcdir $ipssrcdir \n" .
                 "$debugtime auxreldiagpath $auxreldiagpath\n" if $debugips;

    if ( $reldiagpath =~ /.*[\/\\](.*)$/ ) {
      $auxins = $1;
      $srcalert = catfile($ipssrcdir,"trace","alert_$auxins.log");
      $dstalert = catfile($dstdiralert,"alert_$auxins.log");
    }    

    if ( not -e $dstalertxml ) {
      mkpath( $dstdiralertxml ) if ( ! -d $dstdiralertxml );
      host("$CP $srcalertxml $dstalertxml") if ( -e $srcalertxml );
    }

    if ( not -e $dstalert ) {
      mkpath( $dstdiralert ) if ( ! -d $dstdiralert );
      host("$CP $srcalert $dstalert") if ( -e $srcalert );
    }

    print $ipsfh "$debugtime Before setting MASTER NODE permissions\n" if $debugips;
    ### print "Before setting MASTER NODE permissions\n";

    # Set MASTER NODE permissions
    eval {
       host("$CHMOD -R 771 $mstrips_base") if ( not $IS_WINDOWS );
       tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_master_ips " .
                         "hpdir $hpdir/pkg_$ipspkgnmbr", 
                         'y', 'y');
       tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_master_ips " .
                         "starttime $starttimeips", 
                         'y', 'y');
       tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_master_ips " .
                         "FIND find $hpdir/pkg_$ipspkgnmbr -exec touch -d \"$starttimeips\" \{\} \\\;", 
                         'y', 'y');
       # starttimeips check
       ###print "\nstarttimeips $starttimeips\n";
       host("$FIND $hpdir/pkg_$ipspkgnmbr -exec $TOUCH -d \"$starttimeips\" {} \\\;") if ( not $IS_WINDOWS );
    };
    if ( $@ ) {
      print "Error while changing permissions to $hpdir.\n";
      print "$@\n";
      exit 1;
    }
    } # end if not $IS_WINDOWS

    $remreldiagpathref = \%remreldiagpath;
    $collectiondirsref = \@collectiondirs;
    $adrhomepatharrayref = \@adrhomepatharray;

    print $ipsfh "$debugtime tfactldiagcollect_master_ips completed\n" if $debugips;

    return (SUCCESS,                   $collectiondirsref,
            $integration_supported,    $ips_create_pack_cmd, 
            $completedpaths,           $remreldiagpathref,
            $int_TFAIPS_PURGEREMOTE,   $inp_TFAIPS_ADRCIORACLEHOME,
            $inp_TFAIPS_ADRCIHOMEPATH, $adrhomepatharrayref);

} # end sub tfactldiagcollect_master_ips


#========== tfactldiagcollect_remote_ips
#
sub tfactldiagcollect_remote_ips {
  my $tfa_home              = shift;
  my $tfauser               = shift;
  my $localhost             = shift;
  my $integration_supported = shift;
  my $ips_create_pack_cmd   = shift;
  my $starttimeips          = shift;
  my $collectionid          = shift;
  my $master_args           = shift;
  my $hostlistref           = shift;
  my $remreldiagpathref     = shift;
  my $inp_TFAIPS_CORRLVL    = shift;
  my $inp_TFAIPS_ALLFILES   = shift;
  my $inp_TFAIPS_ADRBASE    = shift;
  my $inp_TFAIPS_ADRCIHOMEPATH = shift;
  my @hostlist              = @$hostlistref;
  my %remreldiagpath        = %$remreldiagpathref;
  my $ipsrempkgnmbr;
  my $remote_home;
  my $remote_node;
  my $remotereldiag;
  my $execoutput;
  my $ipscmd;

    # ============
    # REMOTE NODES, create a logical ips package (integration tfa)
    # ============
    if ( $inp_TFAIPS_ALLFILES ) {
      $TFAIPS_ALLFILESTXT = '(all_files = true)';
    } else {
      $TFAIPS_ALLFILESTXT = "";
    }

    if ( $integration_supported ) {
      $ipscmd = "create package correlate $inp_TFAIPS_CORRLVL integration tfa $TFAIPS_ALLFILESTXT";
      $ipscmd =~ s/\(/paropen/g;
      $ipscmd =~ s/\)/parclose/g;
      $ipscmd =~ s/\_/underscore/g;      
    } else {
      $ips_create_pack_cmd =~ s/ips //;
      $ips_create_pack_cmd =~ s/'/quote/g;
      $ips_create_pack_cmd =~ s/"/quote/g;
      $ips_create_pack_cmd =~ s/:/colon/g;
      $ips_create_pack_cmd =~ s/-/dash/g;
      $ipscmd = $ips_create_pack_cmd;
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_remote_ips " .
                        "Remote create package cmd, $ipscmd", 
                        'y', 'y');
    }
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_remote_ips " .
                      "ipscmd $ipscmd", 'y', 'y');
    my $args;
    ### Remote node invocation
    #$args = $TFAIPS_TARGETHOMEPATH . " " . $TFAIPS_ADRCIHOMEPATH . " " . $TFAIPS_ADRCIORACLEHOME . " " . 
    #        $TFAIPS_ADRBASE . " " . $ipscmd;
    $args = $master_args . $ipscmd;
    my $argscpy = $args;
    foreach $remote_node ( @hostlist ) {

      {
         local *STDOUT;
         open STDOUT, '>/dev/null' or warn "Can't open /dev/null: $!";
         $execoutput = executeCommandInHostAndGetOutput(
                 $tfa_home,
                 "tfactlips",
                 "ping",
                 $remote_node );
         close STDOUT;
      }
      if ( $execoutput =~ /User.*does not have keys to run TFA/ ||
           $execoutput =~ /User.*does not have permissions to run tfactl/ ) {
        next;
      }

      if ( exists $remreldiagpath{$remote_node} ) {
      $remotereldiag = $remreldiagpath{$remote_node};
      $remote_home = $tfa_home;
      # remote repository location
      my $remote_repository = tfactlshare_get_repository_location( $tfa_home, $remote_node );
      if ( not $IS_WINDOWS ) {
        $remote_home =~ s/\/$localhost\/tfa_home/\/$remote_node\/tfa_home/;
      } else {
        $remote_home =~ s/\\$localhost\\tfa_home/\\$remote_node\\tfa_home/;
      }
      # remote ips_base location
      # remote su section
      my $osowner = getFileOwner(catfile($inp_TFAIPS_ADRBASE,$inp_TFAIPS_ADRCIHOMEPATH));
      if ( $current_user eq "root" && not $IS_WINDOWS ) {
        $args = $argscpy . " manifest " . catfile($remote_repository,"suptools","ips","user_$tfauser",$collectionid,
                "user_$osowner",$remotereldiag, "manifest.xml") . " keyfile " .
                catfile($remote_repository,"suptools","ips","user_$tfauser",$collectionid, "user_$osowner",
                $remotereldiag, "keyfile.xml");
      } else {
        $args = $argscpy . " manifest " . catfile($remote_repository,"suptools","ips","user_$tfauser",$collectionid,
                $remotereldiag, "manifest.xml");
      }
      $args =~ s/$localhost/$remote_node/g;
      print "remotereldiag $remotereldiag\n";
      ### create package integration tfa $TFAIPS_ALLFILESTXT manifest ... in remote
      ### print "args $args\n";
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_remote_ips " .
                        "tfactlips $ipscmd remote $remote_node " .
                        "args $args", 'y', 'y');
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_remote_ips " .
                        "Creating ips package in remote node $remote_node ...", 
                        'y', 'y');
      {
        local *STDOUT;
        open STDOUT, '>/dev/null' or warn "Can't open /dev/null: $!";
        $execoutput = executeCommandInHostAndGetOutput(
                $tfa_home,
                "tfactlips",
                $args,
                $remote_node );
        close STDOUT;
     }
     if ( $execoutput =~ /timed out/ ) {
       print "Creating ips package in remote node $remote_node ... timed out.\n";
       next;
       ###return;
     } elsif ( $execoutput =~ /non matching adrhomepath/ ) {
       my $msg = $remotereldiag;
       if ( $msg =~ /non matching adrhomepath for (.*)/ ) {
         $msg = $1;
       }
       # Send message to rem_parrips*.log
       print "Non matching adrhomepath for $msg during the creation of ips package in remote node $remote_node.\n";
       next;
       ###return;
     } elsif ( $execoutput =~ /Error\:(.*)/ ) {
       ###remove
       # Don't continue remote IPS processing if warning/errors
       # are generated during package generation.
       print "Error:$1\n";
       next;
     }

      #print "\n\n$execoutput\n\n";
      if ( $execoutput =~ /Created package ([0-9]+) .*/ ) {
        $ipsrempkgnmbr = $1;  # ips package number autogenerated
        print "Created package $ipsrempkgnmbr in remote node $remote_node\n";
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_remote_ips " .
                          "rem pack $ipsrempkgnmbr", 'y', 'y');
    }

    $args = "";
      # ===========
      # REMOTE NODE, use the REMOTE KEYS file provided by the master
      # ===========
        $remote_repository = tfactlshare_get_repository_location($tfa_home, $remote_node);
        $remote_home = $tfa_home;
        if ( not $IS_WINDOWS ) {
          $remote_home =~ s/\/$localhost\/tfa_home/\/$remote_node\/tfa_home/;
        } else {
          $remote_home =~ s/\\$localhost\\tfa_home/\\$remote_node\\tfa_home/;
        }

        # Remote node, use remote keys file
        # remote ips_base location
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_remote_ips " .
                           "   integration_supported $integration_supported", 'y', 'y');
        if ( $integration_supported ) {
          # remote ips_base location
          # remote su section
          my $osowner = getFileOwner(catfile($inp_TFAIPS_ADRBASE,$inp_TFAIPS_ADRCIHOMEPATH));
          if ( $current_user eq "root" && not $IS_WINDOWS ) {
            $ipscmd = "use remote keys file " . catfile($remote_repository,"suptools","ips","user_$tfauser",
                      $collectionid, "user_$osowner", $remotereldiag, "remkeyfile.xml") . " package $ipsrempkgnmbr";
          } else {
            $ipscmd = "use remote keys file " . catfile($remote_repository,"suptools","ips","user_$tfauser",
                      $collectionid, $remotereldiag, "remkeyfile.xml") . " package $ipsrempkgnmbr";
           }
          #$args = $ipscmd;
          ### Remote node invocation
          #$args = $TFAIPS_TARGETHOMEPATH . " " . $TFAIPS_ADRCIHOMEPATH . " " . $TFAIPS_ADRCIORACLEHOME . " " . 
          #        $TFAIPS_ADRBASE . " " . $ipscmd;
          $args = $master_args . $ipscmd;
          $args =~ s/$localhost/$remote_node/g;
          tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_remote_ips " .
                           "ipscmd $ipscmd", 'y', 'y');
          tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_remote_ips " .
                            "Trying to use the remote key file " . catfile($remote_repository,"suptools","ips","user_$tfauser",
                            $collectionid, $remotereldiag, "remkeyfile.xml") . " in package ".
                            "$ipsrempkgnmbr in remote node $remote_node ...", 'y', 'y');
          {
             local *STDOUT;
             open STDOUT, '>/dev/null' or warn "Can't open /dev/null: $!";
             $execoutput = executeCommandInHostAndGetOutput(
                     $tfa_home,
                     "tfactlips",
                     $args,
                     $remote_node );
             close STDOUT;
          }

          print $ipsfh "$debugtime Trying to use the remote key file " . catfile($remote_repository,"suptools","ips",
                "user_$tfauser",$collectionid,$remotereldiag,"remkeyfile.xml") ." in package ".
                       "$ipsrempkgnmbr in remote node $remote_node ...",
                       "out use rem key file: $execoutput \n" if $debugips;

          if ( $execoutput =~ /timed out/ ) {
            print "Trying to use the remote key file in remote node $remote_node ... timed out.\n";
            next;
            ###return;
          } elsif ( $execoutput =~ /non matching adrhomepath/ ) {
            print "Non matching adrhomepath when trying to use the remote key file in remote node $remote_node.\n";
            next;
            ###return;
          }

        } # end if $integration_supported

        # Remote node, finalize the package
        # remote ips_base location
        # remote su section
        $osowner = getFileOwner(catfile($inp_TFAIPS_ADRBASE,$inp_TFAIPS_ADRCIHOMEPATH));
        if ( $current_user eq "root" && not $IS_WINDOWS ) {
          $ipscmd = "finalize package $ipsrempkgnmbr manifest " . catfile($remote_repository,"suptools","ips","user_$tfauser",
                    $collectionid,"user_$osowner",$remotereldiag,"manifest.xml");
        } else {
          $ipscmd = "finalize package $ipsrempkgnmbr manifest " . catfile($remote_repository,"suptools","ips","user_$tfauser",
                    $collectionid,$remotereldiag,"manifest.xml");
        }
        #$args = $ipscmd;
        ### Remote node invocation
        #$args = $TFAIPS_TARGETHOMEPATH . " " . $TFAIPS_ADRCIHOMEPATH . " " . $TFAIPS_ADRCIORACLEHOME . " " . 
        #        $TFAIPS_ADRBASE . " " . $ipscmd;
        $args = $master_args . $ipscmd;
        $args =~ s/$localhost/$remote_node/g;
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_remote_ips " .
                          "ipscmd $ipscmd", 'y', 'y');
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_remote_ips " .
                          "Finalizing package $ipsrempkgnmbr in remote node $remote_node ...", 
                          'y', 'y');
        {
           local *STDOUT;
           open STDOUT, '>/dev/null' or warn "Can't open /dev/null: $!";
           $execoutput = executeCommandInHostAndGetOutput(
                   $tfa_home,
                   "tfactlips",
                   $args,
                   $remote_node );
           close STDOUT;
        }

        if ( $execoutput =~ /timed out/ ) {
          print "Trying to finalize the package $ipsrempkgnmbr in remote node $remote_node ... timed out.\n";
          next;
          ###return;
        } elsif ( $execoutput =~ /non matching adrhomepath/ ) {
          print "Non matching adrhomepath during the finalization of package $ipsrempkgnmbr in remote node $remote_node.\n";
          next;
          ###return;
        } else {
          print "$execoutput\n";
        }

        # ===========
        # REMOTE NODE, generate the PHYSICAL PACKAGE
        # ===========
        # \"$starttimeips\"
        my $starttimemarshall = "\"$starttimeips\"";
        $starttimemarshall =~ s/'/quote/g;
        $starttimemarshall =~ s/"/quote/g;
        $starttimemarshall =~ s/:/colon/g;
        $starttimemarshall =~ s/-/dash/g;
        $starttimemarshall =~ s/ /space/g;
        # remote ips_base location
        # remote su section
        $osowner = getFileOwner(catfile($inp_TFAIPS_ADRBASE,$inp_TFAIPS_ADRCIHOMEPATH));
        if ( $current_user eq "root" && not $IS_WINDOWS ) {
          $ipscmd = "starttimeips $starttimemarshall generate package $ipsrempkgnmbr in " . 
                    catfile($remote_repository,"suptools","ips","user_$tfauser",$collectionid,
                            "user_$osowner",$remotereldiag);

        } else {
          $ipscmd = "starttimeips $starttimemarshall generate package $ipsrempkgnmbr in " . 
                    catfile($remote_repository,"suptools","ips","user_$tfauser",$collectionid,$remotereldiag);
        }
        #$args = $ipscmd;
        ### Remote node invocation
        #$args = $TFAIPS_TARGETHOMEPATH . " " . $TFAIPS_ADRCIHOMEPATH . " " . $TFAIPS_ADRCIORACLEHOME . " " . 
        #        $TFAIPS_ADRBASE . " " . $ipscmd;
        $args = $master_args . $ipscmd;
        $args =~ s/$localhost/$remote_node/g;
        ###print "ARGS $args \n\n";
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_remote_ips " .
                          "ipscmd $ipscmd", 'y', 'y');
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect tfactldiagcollect_remote_ips " .
                          "Generating package $ipsrempkgnmbr in remote node $remote_node ...", 
                          'y', 'y');

        {
           local *STDOUT;
           open STDOUT, '>/dev/null' or warn "Can't open /dev/null: $!";
           $execoutput = executeCommandInHostAndGetOutput(
                   $tfa_home,
                   "tfactlips",
                   $args,
                   $remote_node );
           close STDOUT;
        }

        if ( $execoutput =~ /timed out/ ) {
          print "Generating package $ipsrempkgnmbr in remote node $remote_node ... timed out.\n";
          next;
          #return;
        } elsif ( $execoutput =~ /non matching adrhomepath/ ) {
          print "Non matching adrhomepath during the generation of package $ipsrempkgnmbr in remote node $remote_node.\n";
          next;
          ###return;
        } else {
          print "$execoutput\n";
        }

        } # end if exists $remreldiagpath{$remote_node}
    } # end foreach hostlist

} # end sub tfactldiagcollect_remote_ips


#
# Run Collection on JCS Nodes
#
sub tfactldiagcollect_runDiagCollectOnJCSNodes {
	my $tfa_home = shift;
	my $user_args = shift;
	my $args = shift;
	my $localhost = tolower_host();

	my $ref = tfactlshare_getNodeListOnCloud();
	my @nodelist = @{$ref};

	foreach my $node ( @nodelist ) {
		next if ( $node eq $localhost );
		tfactldiagcollect_runDiagCollectOnJCSNode($tfa_home, $node, $user_args, $args);
	}
}

sub tfactldiagcollect_runDiagCollectOnJCSNode {
	my $tfa_home = shift;
	my $node = shift;
	my $user_args = shift;
	my $args = shift;
	my $localhost = tolower_host();

	my $pid = fork ();
	return if $pid;

	print "Running Diagcollect on JCS Node $node...\n";

	my $ssh_status = checkSSHSetup($node, $current_user);

	if ( $ssh_status != 0 ) {
		print "$node is not configured for ssh user equivalency for $current_user user.\n";
		exit;
	}

	my @options = split(/\s\-/, $args);
	my ($tag, $zip, $logid);

	foreach my $arg ( @options ) {
		$arg = trim ($arg);
		next if ( $arg =~ /^(\s*)$/ );

		if ( $arg =~ /tag / ) {
			$tag = $arg;
			$tag =~ s/tag //;
		}

		if ( $arg =~ /^z / ) {
			$zip = $arg;
			$zip =~ s/z //;
		}

		if ( $arg =~ /^logid / ) {
			$logid = $arg;
			$logid =~ s/logid //;
		}
	}

	# Get tag from user options
	my $user_tag = 0;
	if ( $user_args ) {
		@options = split(/\s\-/, $user_args);

		foreach my $arg ( @options ) {
			$arg = trim ($arg);
			next if ( $arg =~ /^(\s*)$/ );

			if ( $arg =~ /tag / ) {
				$tag = $arg;
				$tag =~ s/tag //;
				$user_tag = 1;
			}
		}
	}

	if ( $user_tag ) {
		$user_args = "$user_args -z $zip -logid $logid -onlyjcs";
	} else {
		$user_args = "$user_args -tag $tag -z $zip -logid $logid -onlyjcs";
	}

	my $tfactl = catfile ($tfa_home, "bin", "tfactl");
	$tfactl =~ s/\/$localhost\//\/$node\//g;
	my $command = "$SSH $node \"$tfactl diagcollect $user_args\"";
	#print "Command : $command\n";
	my $ssh_out = `$command`;

	my $repository = getCurrentRepository($tfa_home);

	my $remrepo = $repository;
	$remrepo =~ s/\/$localhost\//\/$node\//g;
	#print "Repository on $node : $remrepo\n";

	$command = "$SCP -r $node:$remrepo/$tag* $repository";
	#print "SCP Command : $command\n";
	my $scp_out = `$command`;
	exit;
}

#
#========== runDiagCollectUser
#
sub runDiagCollectUser
{
  my $tfa_home = shift;
  my $clusterwide = shift;
  my $opts = shift;  
  my $localhost=tolower_host();
  my $paramfile = tfactlshare_getSetupFilePath($tfa_home);
  my $ipsippflag = FALSE;

  if (isTFARunning($tfa_home) == FAILED) {
        exit 1;
  }

  if ( $debugips ) {
    print "runDiagCollectUser\n";
    print "runDiagCollectUser TFAIPS_COLLECTIONDIR_REL $TFAIPS_COLLECTIONDIR_REL \n";
  }

  my $from;
  my $to;
  my $for;
  my $since;

  # checking for valid date/time 
  if ($opts =~ /-for / || $opts =~ /-to / || $opts =~ /-from / || $opts =~ /-since /) {
    my @options = split(/\s/, $opts);
    for (my $c=0; $c<scalar(@options); $c++) {
        if ($options[$c] =~ /-for/ || $options[$c] =~ /-from/ || $options[$c] =~ /-to/) {
          my $t = $options[$c+1];
          if (scalar(@options)>$c+1) {
                if (!($options[$c+2] =~ /^-/)) {
                  $t .= " $options[$c+2]";
                }
          }
	  my $time;
          if ($options[$c] =~ /-from/) {
		$time = getValidDateFromString($t, "startdate");
                $from = $time;
		$opts =~ s/-from $t/-from $time/;
          }
          elsif ($options[$c] =~ /-to/) {
		$time = getValidDateFromString($t, "enddate");
                $to = $time;
		$opts =~ s/-to $t/-to $time/;
          }
          if ($options[$c] =~ /-for/) {
		if ( $t =~ /\s/ ) {
		  	$time = getValidDateFromString($t, "startdate");
		} else {
			$time = getValidDateFromString($t, "date");
		}
		$for = $time;
		$opts =~ s/-for $t/-for $time/;
          }

	  if ($time eq "invalid") {
                print "The date entered is invalid: $t\n";
                exit 1;
	  }
        }elsif ($options[$c] =~ /-since/) {
           my $t = $options[$c+1];
           $since = $t;
        }
    } # end of for loop
  }
  if ((defined($from) && defined($for)) || (defined($from) && defined($since)) || (defined($for) && defined($since))) {
        print "Please choose only one of these options for time range\n";
        print "1. -since\n";
        print "2. -from -to\n";
        print "3. -for\n";
        exit 1;
  }
  if (defined($for)) {
        print "Scanning files for $for\n";
	my $t1 = getValidDateFromString($for, "time");
        if ( $t1 eq "invalid" ) {
          print "$for is not a valid time.\n";
          exit 1;
        }
	my $t2 = time();
	my $diff = $t2 - $t1;
        if ($diff == 0 || $diff < 0) {
          print "Start time entered is after the current system time. \n";
          exit 1;
	 }
  }
  if (defined($from) && defined($to)) {
        print "Scanning files from $from to $to\n";
        my $t1 = getValidDateFromString($from, "time");
        if ( $t1 eq "invalid" ) {
          print "$from is not a valid time.\n";
          exit 1;
        }
        my $t2 = getValidDateFromString($to, "time");
        if ( $t2 eq "invalid" ) {
          print "$to is not a valid time.\n";
          exit 1;
        }
        my $t3 = time();
        if ($t1-$t3 >= 0) {
          print "Start time entered is after the current system time.\n";
          exit 1;
        }
        if ($t2-$t3 >= 0) {
          print "WARNING: End time entered is after the current system time.\n";
        }
        my $diff = $t2 - $t1;
        if ($diff == 0 || $diff < 0) {
          print "Time range entered for diagcollection is invalid. Start time should be before the end time.\n";
          exit 1;
        }
  }
  elsif (defined($from) && !(defined($to))) {
        print "Scanning files from $from to current system time\n";
        my $t1 = getValidDateFromString($from, "time");
        if ( $t1 eq "invalid" ) {
          print "$from is not a valid time.\n";
          exit 1;
        }
        my $t2 = time();
        my $diff = $t2 - $t1;
        if ($diff == 0 || $diff < 0) {
          print "Start time entered is after the current system time. \n";
          exit 1;
        }
  }
  elsif (!(defined($from)) && defined($to)) {
        print "Start time is missing from input. Please enter a start time using -from flag.\n";
        exit 1;
  }
  # done checking for valid date/time

  my @listOfNodes;
  if (isOfflineMode($paramfile)) {
       push(@listOfNodes, $localhost);
  }
  else {
  if ($opts =~ /-node/) {
    my @options = split(/\s/, $opts);
    my $nodes;
    for (my $c=0; $c<scalar(@options); $c++) {
          if ($options[$c] =~ /-node/) {
                # Get the node list entered by user in diagcollect
                $nodes = $options[$c+1];

                if ($options[$c+1] =~ /all/) {
                  @listOfNodes = getActiveListOfNodes($tfa_home);
                  if (scalar(@listOfNodes) == 0) {
                    print "TFA is not running. Cannot collect trace files from cluster\n";
                    exit 1;
                  }
                }
                elsif ($options[$c+1] =~  /local/) {
                  if (isNodeActive($tfa_home, $localhost)) {
                    push(@listOfNodes, $localhost);
                  }
                  else {
                    print "TFA is not running on $localhost. Cannot collect trace files\n";
                    exit 1;
                  }
                }
                else  {
                  $nodes =~ tr/A-Z/a-z/;
                  my @nodes_list = split(/\,/,$nodes);
                  foreach $node (@nodes_list) {
                        # remove domainname
                        ($node,) = split (/\./, $node);
                        if (isNodeActive($tfa_home, $node)) {
                                push(@listOfNodes, $node);
                        }
                        else {
                          print "TFA is not running on $node. Cannot collect trace files\n";
                        }
                  }
                  if (scalar(@listOfNodes) == 0) {
                    print "TFA is not running on all the nodes mentioned. Cannot collect trace files\n";
                    exit 1;
                  }
                }
          }
    } # end of for loop

    # Check the TFA Access for Non-root user on all remote nodes:
    if ( ! $IS_TFA_ADMIN ) {
        my $updated = 0;
        my @updatednodelist;
        foreach $node ( @listOfNodes ) {
                if ( $node ne $localhost ) {
                        my $status = checkUserAccessOnRemote( $tfa_home, $node );

                        if ( $status == 1 ) {
                                push( @updatednodelist, $node );
                        } elsif ( $status == 2 ) {
				$updated = 1;
				print "WARNING: TFA is not yet secured to run all commands on $node\n";
			} else {
                                $updated = 1;
                                print "WARNING: User '$current_user' do not have access to TFA on $node\n";
                        }
                } else {
                        push( @updatednodelist, $node );
                }
        }

        # if the node list is updated, then update the nodes in diagcollect opts
        if ( $updated == 1 ) {

                # Check if the updated node list is empty
                if ( scalar( @updatednodelist ) == 0) {
                        print "Diagcollection Node List is empty. Cannot collect trace files\n";
                        exit 1;
                }

                # Prepare the updated node list for diagcollect opts
                my $list = join(",", @updatednodelist );
    
                dbg(DBG_WHAT, "\nUpdated Node List after checking TFA Access: @updatednodelist\n");

                dbg(DBG_WHAT, "\nDiagcollect Opts before updating nodelist: $opts\n");

                # Replace the updated node list in opts
                $opts =~ s/-node\s$nodes\s/-node $list /;
                @listOfNodes = @updatednodelist;

                dbg(DBG_WHAT, "\nDiagcollect Opts after updating nodelist: $opts\n");
        }
    } # end if    Check the TFA Access for Non-root user on all remote nodes

  }
  }
  my %activenodes = map { $_ => 1 } @listOfNodes;


  my @flags = split(/ -/, $opts);
  my $tagname;
  my $logid;
  for (my $i=0; $i<scalar(@flags); $i++) {
        if ($flags[$i] =~ /^tag /) {
          $tagname = $flags[$i];
          $tagname =~ s/^ //;
          $tagname =~ s/ $//;
          $tagname =~ s/tag //;
          $tagname =~ s/ /_/g;
        }
        if ($flags[$i] =~ /^logid /) {
          $logid = $flags[$i];
          $logid =~ s/^ //;
          $logid =~ s/ $//;
          $logid =~ s/logid //;
        }
  }

  #check if user specified tagname exists on any requested diagcollect nodes
  if ($tagname =~ /^0/) {
     my $oldtag = $tagname;
     $tagname =~ s/0//;
     #replace the actual tag name specified by user in opts
     $opts =~ s/-tag\s$oldtag/-tag $tagname /;
     my $tagmessage = "$localhost:checktagexists:$tagname:@listOfNodes\n";
     my $tagcommand = buildCLIJava($tfa_home,$tagmessage);
     dbg(DBG_VERB, "$tagcommand\n");
     my $tagline;
     my @cli_output = tfactlshare_runClient($tagcommand);
     foreach $tagline ( @cli_output )
         {
            if ($tagline =~ /Tag already exists/) {
                print "\n$tagline ";
                print "\nPlease specify a different tagname\n";
                exit 1;
                }
        } 
  }

  # call ips
  my @collectiondirs;
  my $retval;
  
  my @adrbases = ();

  if ( not $DSCRIPT_NOIPS ) {
    @adrbases = tfactlshare_get_adr_bases($tfa_home, $localhost);
  }
  ###print "adrbases @adrbases\n";
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect runDiagCollectUser " .
                    "Before calling tfactldiagcollect_ips(), adrbases @adrbases", 'y', 'y');
  if ( (not $DSCRIPT_NOIPS) &&  
     ($opts =~ /-ips/ || $DSCRIPT_DEF) && @adrbases ) {
    if ( $opts =~ /-incident/ || $opts =~ /-problem/ || $opts =~ /-problemkey/ ) {
      $ipsippflag = TRUE;
    }
    ($retval, @collectiondirs) = tfactldiagcollect_ips($tfa_home, \@listOfNodes, $opts, $from, $to, $for, $since);
    ### print "retval after calling ips $retval\n";
    @collectiondirs = () if $retval eq "error";
  }

  close $ipsfh if $debugips;
  close $ipslogfh;
  my $fsize = osutils_getFileSize($ipslogfname);
  unlink $ipslogfname if $fsize == 0;

  my $colldirs = join(',',@collectiondirs);
  if ( defined $colldirs && length $colldirs ) {
    if ( $opts =~ /-collectdir / ) {
      $opts =~ s/-collectdir /-collectdir $colldirs,/;
    }
    else {
      $opts .= " -collectdir $colldirs";
    }
  }

  # remove unneeded options
  $opts =~ s/ \-incident [0-9]+//g;
  $opts =~ s/ \-problem [0-9]+//g;
  $opts =~ s/ \-problemkey .*? -/ -/g;
  $opts =~ s/ \-ips//g;
  $opts =~ s/ \-noips//g;
  $TFAIPS_UNDO_ADRBASEPATH =~ s/\\/\\\\/g;
  $TFAIPS_UNDO_ADRHOMEPATH =~ s/\\/\\\\/g;
  $opts =~ s/ \-adrbasepath $TFAIPS_UNDO_ADRBASEPATH//g;
  $opts =~ s/ \-adrhomepath $TFAIPS_UNDO_ADRHOMEPATH//g;

  $TFAIPS_UNDO_ADRBASEPATH = "";
  $TFAIPS_UNDO_ADRHOMEPATH = "";

  if ($RUNDIAGCOLLECTINCELLS) {
    if ( $current_user eq "root" ) {
      if ( $DIAGCOLLECT ) {
        # run cell collection function in background
        runDiagcollectionInCells($tfa_home, $DSCRIPT_OPTS, $cells, 1);
      } else {
        # do not run cell collection function in background
        runDiagcollectionInCells($tfa_home, $DSCRIPT_OPTS, $cells, 0);
      }
    }
    $RUNDIAGCOLLECTINCELLS = 0;
  }

  ###print "Collection dirs $colldirs\n";
  ###print "Diagcollect opts after IPS processing, $opts.\n";
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect runDiagCollectUser " .
                    "AFTER IPS PROCESSING $opts", 'y', 'y');

  my $logHostname = $localhost;
  if ( -f catfile($tfa_home,"resources","mask_strings.xml") ) {
     $logHostname =  getReplacedHostName($tfa_home);
  }
  my $collectionId = $logid . $logHostname;
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect runDiagCollectUser " .
                    "collectionId BEFORE calling startdiagcollection $collectionId", 'y', 'y');
  my $message = "$localhost:startdiagcollection";
  if ( $opts ) {
    $message = "$message:$opts:$collectionId";
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect runDiagCollectUser " .
                      "opts BEFORE calling startdiagcollection $opts", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect runDiagCollectUser " .
                      "message BEFORE calling startdiagcollection $message", 'y', 'y');
  }

  # Collect Thread Dumps on JCS
  if ( $ISJCS ) {
	tfactlshare_runThreadDumpsOnJCS();
  }

  #print "$message\n"; 
  my $command = buildCLIJava($tfa_home,$message);

  my $repository = getCurrentRepository($tfa_home);
  #qx(mkdir -p $repository/$tagname);
  #qx(chmod 700 $repository/$tagname);
  my $log_file = catfile($repository,$tagname,"diagcollect_console_$logid\_$logHostname.log");
  my $log_file_verbose = catfile($repository,$tagname,"diagcollect_$logid\_$logHostname.log");
  #open (OUT, ">$log_file") or die "Can't open $log_file: $!\n";
  #print OUT "Inside runDiagcollectUser for $localhost\n";
  #print OUT "\nCollection Id : $collectionId\n";
  #print OUT "\nRepository Location in $logHostname : $repository\n";
  #close OUT;
  print "\nCollection Id : $collectionId\n";
  my $DIAGSTART_WAIT = tfactlshare_getConfigValue(catfile($tfa_home, "internal", "config.properties"), "diagStartWait");
  if ( ! $DIAGSTART_WAIT ) {
         $DIAGSTART_WAIT = 60;
  }
  print "\nDetailed Logging at : $log_file_verbose\n";
  #print "\nRepository Location in $logHostname : $repository\n";
  #print "\nCollection monitor will wait up to $DIAGSTART_WAIT seconds for collections to start \n";
  my $line;
  my $failed = 0;

  open(CMD, "$command |");

  # donefile setup
  my $donefile;
  my $donefilecmd;
  if ( $TFAIPS_COLLECTIONDIR_REL =~ /(.*)[\/\\]$TFAIPS_COLLECTIONID.*/ ) {
    $donefile    = catfile($1,$TFAIPS_COLLECTIONID . "_mstr_completed.log");
    $donefilecmd = 'echo done >> ' . $donefile;
    if ( $debugips ) {
      print "runDiagCollectUser donefile $donefile\n";
      print "runDiagCollectUser donefilecmd $donefilecmd\n";
    }
  }

  #foreach $line (split /\n/ , `$command`)
  while (<CMD>)
  {
    $line = $_;
    if ( $line =~ /SUCCESS/ ) {
      if ($opts =~ /-monitor/) {
        #print "Diagcollection Started...\n";
        #sleep(10);
        #print "Tailing log...\n";
        for( $a = 0; $a < $DIAGSTART_WAIT; $a = $a + 1 ){
	   if ( -f "$log_file" ) {
              last;
	   }
	   sleep(1);
        }

        my $pid;
        my $pipe;

        if ( ! -f "$log_file" ) {
                print "\nCollection Failed. Could not read diagcollect log $log_file within $DIAGSTART_WAIT seconds\n";
                exit 1;
                #open LOG, ">>$log_file";
                #close LOG;
        }

        #sleep(10);

        my $machineOS = $^O;

        if ( $machineOS eq 'solaris' ) {
                $pid = open $pipe, "-|", "/usr/bin/tail", "-f", "$log_file" or
                        die "Could not start tail on $log_file: $!";
        } elsif($IS_WINDOWS){
              tfactldiagcollect_windows_conditional_tail($log_file);
              $pid = open $pipe, '<', catfile($log_file) or
                        die "Could not read $log_file: $!";
        } else {
                $pid = open $pipe, "-|", "/usr/bin/tail", "-f", "-n", "+1", "$log_file" or
                        die "Could not start tail on $log_file: $!";
        }
	my $tb = Text::ASCIITable->new();
	$tb->setCols("Host", "Status", "Size", "Time");
	$tb->setOptions({"outputWidth" => $tputcols, "headingText" => "Collection Summary"});
        while (<$pipe>)
        {
          ####print "      ==> Def var $_ \n";
          if (/Completed collection of zip files./ || /Completed submission of diagcollection request./) {
		if ( $failed == 0 && (scalar @listOfNodes) > 0 ) {
                	if(!$IS_WINDOWS){
				print $tb;
				#print;
			}
		}
                #close ($pipe);
                kill 9, $pid;
                last;
          }
          elsif (/Summary/) {
		if(!$IS_WINDOWS){
		  #print;
	          my @summary = split(/!/);
		  if(/Failed/){
			$tb->addRow($summary[1],$summary[2],"","");
		  } else{
	          	$tb->addRow($summary[1],$summary[4],$summary[2],$summary[3]);
		  }
		}
          }
          elsif (/:Failed/) {
		if(!$IS_WINDOWS){print;}
                my @str = split(/:/);
                my $size = @str;
                my $failedHost = trim($str[$size-2]);
                my $index = 0;
                foreach (@listOfNodes) {
                    if($_ eq $failedHost){
                          splice(@listOfNodes, $index, 1);
                    }
                    $index++;
               }

               if ( $failedHost eq $localhost ) {
			if ( /Repository is full and closed/) {
				print "\nNot enough space in Repository to complete this Collection\n\n";
				printLocalRepository($tfa_home);
			}
		}
	  }
	  elsif (/Failed Collection/) {
                 $failed = 1;
          }
          else {
                if ( /Getting list of files satisfying time range/ ) {
                  if(!$IS_WINDOWS){print if not $ipsippflag;}
                } else {
                  if(!$IS_WINDOWS){print;}
                }
          }
          if ($failed == 1){
           kill 9, $pid;
          }
        }
      }

      my $upload_dir = "";
      if ( $failed == 0 && (scalar @listOfNodes) > 0 ) {
        #print "Collection job submitted.\n";
        print "\nLogs are being collected to: ";
        my $currRepo = $repository;
        my @logfiles;
        my $dirLoc;
        if ($tagname) {
          $dirLoc = catdir($repository,"$tagname");
        } else {
	        $dirLoc = $repository;
        }
        print $dirLoc."\n";
        if ( not $NOMONITOR ) {
          if ($IS_WINDOWS){
            my $cmd = "dir $dirLoc | findstr \".zip\$\"";
            print `$cmd`;
            `$donefilecmd`;
            print "runDiagCollectUser location " . catfile($TFAIPS_COLLECTIONDIR_REL,"mstr_completed.log") . "\n" if $debugips;
          } else {
            print `$FIND $dirLoc -type f -name "*.zip"`;
          }
        }

	if ($tagname) {
            $upload_dir = catdir($repository,$tagname);
        } else {
            $upload_dir = $repository;
        }

        if ( $TFAUPLOAD )
        {
          my $command = catfile($tfa_home,"bin","tfactl")." upload";
          $command .= " -user ". $TFAUSER if ( $TFAUSER );
          $command .= " -bug ". $TFABUG if ( $TFABUG );
          $command .= " -sr ". $TFASR if ( $TFASR );
          $command .= " -comment '". $TFACMT . "'" if ( $TFACMT );
          $command .= " -bugsftp " if ( $TFABUGSFTP );
          $command .= " ". $upload_dir;
          open(CF, "$command|");
          while(<CF>)
          {
            print;
          }
          close(CF);
        }

        # $TFAIPS_COLLECTIONDIR
        my $execoutput;
        if ( $debugips ) {
          print $ipsfh "$debugtime Collection dir to purge, $TFAIPS_COLLECTIONDIR \n",
                       "$debugtime Remote collection to purge $TFAIPS_PURGEREMOTE \n";
        }
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect runDiagCollectUser " .
                            "Collection dir to purge, $TFAIPS_COLLECTIONDIR", 'y', 'y');
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect runDiagCollectUser " .
                            "Remote collection to purge $TFAIPS_PURGEREMOTE", 'y', 'y');

        if ( not $DSCRIPT_NOIPS ) {
          # print "List of nodes @listOfNodes\n";
          tfactlshare_trace(5, "tfactl (PID = $$) tfactldiagcollect runDiagCollectUser " .
                            "List of nodes @listOfNodes", 'y', 'y');

          # print "about to remove collectiondir ...\n";
          # print "TFAIPS_COLLECTIONDIR $TFAIPS_COLLECTIONDIR\n";
          # print "TFAIPS_COLLECTIONID  $TFAIPS_COLLECTIONID\n";
          # remove done file
          `$RM $donefile` if $IS_WINDOWS && osutils_getFileSize($donefile) >= 0;
          if ( $TFAIPS_COLLECTIONDIR_REL =~ /$TFAIPS_COLLECTIONID/ ) {
            if ( not $IS_WINDOWS ) {
              print $ipsfh "$RM -rf $TFAIPS_COLLECTIONDIR_REL" if $debugips;
              host("$RM -rf $TFAIPS_COLLECTIONDIR_REL") if ! $debugips;
            } else {
              # Windows purge
              my $rmcmd = 'rmdir /s /q ' . $TFAIPS_COLLECTIONDIR ;
              print $ipsfh "$debugtime purgecmd mstr $rmcmd\n" if $debugips;
              ### print "$debugtime purgecmd mstr $rmcmd\n";
              host($rmcmd) if ! $debugips;
            }
          } # end if $TFAIPS_COLLECTIONDIR =~ /$TFAIPS_COLLECTIONID/

          if ( $TFAIPS_PURGEREMOTE =~ /$TFAIPS_COLLECTIONID/ ) {
            $TFAIPS_PURGEREMOTE =~ s/dummy/purgecolldir/g;
            foreach my $remote_node ( @listOfNodes ) {
              next if $remote_node eq $localhost;
              my $purgecmd = $TFAIPS_PURGEREMOTE;
              $purgecmd =~ s/$localhost/$remote_node/g; 
              print $ipsfh "$debugtime purgecmd for host $remote_node $purgecmd\n" if $debugips;
              ### print "$debugtime purgecmd for host $remote_node $purgecmd\n";
              if ( ! $debugips )
              {
                local *STDOUT;
                open STDOUT, '>/dev/null' or warn "Can't open /dev/null: $!";
                $execoutput = executeCommandInHostAndGetOutput(
                      $tfa_home,
                      "tfactlips",
                      $purgecmd,
                      $remote_node );
                close STDOUT;
              }
            } # end foreach
          } # end if $TFAIPS_PURGEREMOTE =~ /$TFAIPS_COLLECTIONID/

        } # end if not $DSCRIPT_NOIPS
     }
    }
    elsif ($line eq "FAILED") {
      print "Collection job failed.\n";
    }
    elsif ($line =~ /Repository is full and closed/) {
      my $host = (split(/!/,$line))[1];
      print "Not enough space in Repository or TFA_BASE in $host\n";
      printRepository($tfa_home,$host);
    }
    elsif ( $line =~ /WARNING - Certificate/ ) {
      print "$line\n";
    }
    elsif ( $line =~ /FAIL - Certificate/) {
      print "$line\n";
      exit 1;
    }
    else {
      print "$line\n";
    }
  }
  close(CMD);
  if ( $IS_WINDOWS ) {
    `$donefilecmd`;

    # Remove master coll dir
    my $rmcmd = 'rmdir /s /q ' . $TFAIPS_COLLECTIONDIR ;
    ### print "purgecmd mstr $rmcmd\n";
    host($rmcmd);

    sleep(2);
    # remove done file
    `$RM $donefile` if $IS_WINDOWS && osutils_getFileSize($donefile) >= 0;
  }

  $TFAIPS_COLLECTIONDIR = "nodirectory";
  $TFAIPS_COLLECTIONID  = "none";
  $TFAIPS_PURGEREMOTE   = "none";

  return SUCCESS;
}

sub tfactldiagcollect_get_time_flags
{
  my $opts = "";
  my ($from, $to, $for);
  # Initialize time from global setting
  if ( defined $tfactlglobal_ctx{"start-time"} )
  {
    $from = $tfactlglobal_ctx{"start-time"};
    $opts .= " -from $from";
    $to = $tfactlglobal_ctx{"end-time"};
    $opts .= " -to $to";
  }

  if ( ! $from && ! $to && $tfactlglobal_ctx{"time"} )
  {
    $for = $tfactlglobal_ctx{"time"};
    $opts .= " -for $for";
  }
  return $opts;
}

sub tfactldiagcollect_windows_conditional_tail{
  my $the_file = shift;
  my @end_conditions = ("Completed collection of zip files.",
                        "Completed submission of diagcollection request.",
                        ":Failed",
                        "Repository is full and closed",
                        "Failed Collection");
  my $stop_tail = 0;
  open(FH,'<',$the_file) or die "Could not read $the_file: $!";
  for (;;) {
      while (<FH>) {
        print;
        foreach my $condition (@end_conditions){
          if (index($_, $condition) != -1) {
              $stop_tail = 1;
              last;
          } 
        }
        if($stop_tail){last;}
      }
      if($stop_tail){last;}
      sleep 1;
      seek FH, 0, 1
  }
}

sub tfactldiagcollect_readMode{
  my $mode =shift;
  if($IS_WINDOWS){
    if($mode){
      ReadMode(0);
    }else{
      ReadMode('noecho');
    }
  }else{
    if($mode){
      system('stty', 'echo');
    }else{
      system('stty', '-echo');
    }
  }
}

sub runtimedcommand  {
my $command = shift;
my $LOG = shift;
my $timeout = shift;
my $retoutput = shift;
my $cmdoutput = "";

if ( !$timeout ) { $timeout = 10 };
  eval {
      local $SIG{ALRM} = sub { die "Timeout\n" };
      alarm $timeout;
      if ( $retoutput ) {
        $cmdoutput = `$command`;
      } else {
       `$command`;
      }
      alarm 0;
  };
  if ($@) {
      print $LOG localtime(time) . ": $command timed out.\n";
      return(99);
  } elsif ($? != 0 && !$retoutput) {
      print $LOG localtime(time) . ": $command failed error $?.\n" ;
      return(1);
  } else {
      print $LOG localtime(time) . ": $command success.\n" ;
      return $cmdoutput if $retoutput;
      return(0);
  }
}

sub tfactldiagcollect_wipepat {
  my $filename = shift;
  my $scriptwiperef = shift;
  my %scriptwipe = %$scriptwiperef;
  my $val = "";

  if ( not -e $filename ) {
    # print LOG localtime(time) .  " : Filename $filename does not exist.\n";
    exit(1);
  }

  foreach my $key (keys %scriptwipe) {
    $val = $scriptwipe{$key};
    if ( length $val ) {
      system("$PERL -p -i.orig -e \"s|$val|\%$key\%|g\" $filename");
    }
  } # end foreach

  return;
} # end sub tfactldiagcollect_wipepat

sub tfactldiagcollect_validate_input {
  my $validate = shift;
  my $userinp = shift;
  my $db = shift;
  chomp($userinp);
  tfactlshare_trace(3, "tfactl (PID = $$) tfactldiagcollect_validate_input"."Validate -> $validate Userinp -> $userinp DB -> $db", 'y', 'n');
  if ( lc($validate) eq "file" ) {
       return TRUE if -f $userinp;
       print "Error: File $userinp not found !\n"; 
  }
  elsif ( lc($validate) eq "directory" ) {
       return TRUE if -d $userinp;
       print "Error: Directory $userinp not found !\n"; 
  }
  elsif ( lc($validate) eq "yn" ) {
       if ( uc($userinp) eq "N" ) {
         exit 0;
       }
       return TRUE;
  } elsif ( lc($validate) eq "number" ){
       return TRUE if $userinp =~ /^[0-9]+$/;
       print "Error: $userinp not a valid number !\n";
  } elsif ( lc($validate) eq "date" ) {
       my $valid = getValidDateFromString($userinp,"startdate");
       return TRUE if ($valid ne "invalid");
       print "Error: $userinp not a valid date !\n"; 
  } elsif ( lc($validate) eq "string") {
       return TRUE if $userinp =~ /^[A-Za-z0-9_]+$/;
       print "Error: $userinp not a valid string  !\n"; 
  } elsif ( lc($validate) eq "multiword") {
       return TRUE if $userinp =~ /^[A-Za-z0-9_=\- \/\.\?\*]+$/;
       print "Error: $userinp not a valid multi-word string  !\n"; 
  } elsif ( $validate =~ /^(dbversion|dbversion:(2digit|2d_noDots|withDots|noDots))$/ ){
       my $format = $2;
       $format = "2digit" if ( !$format ); #Make two digit default if not provided
       my $versions = tfactlparser_getJSONValues($format,$tfactlglobal_dbversions,\%tfactlglobal_versionsMap);
       my %vers = %{$versions};
       return TRUE if ( $vers{$userinp} eq "true" );
       print "Error: $userinp is not a valid version\n";
  } elsif ( lc($validate) eq "sqlid") {
      if ( $userinp =~ /\w+/ ) {
        if ( length $db == 0 ) {
          print "Error database was not provided and is needed to validate SQL_ID \n";
          exit(1);
        } else {
          my $retval  = dbutil_setOraEnv($tfa_home,"$db","",TRUE);
          if ( $retval ne 0 ) {
            print "Database $db is not running. Unable to validate SQL_ID. \nExiting....\n"; 
            exit (1);
          } else {
            my @out = tfactlshare_run_a_sql("sql","set heading off;\nselect count(*) from v\$sql where sql_id = \'$userinp\';\nquit;\n");
            @out = grep{ $_ ne ''} @out;
            if( $out[0] > 0 ){
              return TRUE;
            } else {
              print "Error: SQL_ID $userinp does not exist\n";
              return FALSE;
            }
          }
        }
      }
      print "Error: $userinp does not match  $validate\n";
      return FALSE;

  } else { #regex last 
       return TRUE if $userinp =~ /^$validate$/; 
       print "Error: $userinp does not match $validate !\n";
  }
  return FALSE;
} # end tfactldiagcollect_validate_input

1;
