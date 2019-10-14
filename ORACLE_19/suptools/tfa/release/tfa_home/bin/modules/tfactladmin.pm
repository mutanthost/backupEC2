# 
# $Header: tfa/src/v2/tfa_home/bin/modules/tfactladmin.pm /st_tfa_19/4 2019/03/04 14:02:26 gadiga Exp $
#
# tfactladmin.pm
# 
# Copyright (c) 2014, 2019, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactladmin.pm
#
#    DESCRIPTION
#      Admin commands
#
#    NOTES
#     
#
#    MODIFIED   (MM/DD/YY)
#    bibsahoo    01/31/19 - commons-io upgrade to version 2.6
#    llakkana    11/25/18 - XbranchMerge gadiga_bug-28927439 from main
#    gadiga      11/22/18 - fix 28927439
#    gadiga      11/22/18 - fix 28927439
#    bburton     09/19/18 - Add updateciphersuite
#    cnagur      08/14/18 - ADW Upload Changes
#    manuegar    08/05/18 - XbranchMerge manuegar_dbutils16 from main
#    manuegar    07/31/18 - manuegar_dbutils16.
#    recornej    07/19/18 - Fix exit codes.
#    recornej    07/13/18 - Add setup of tools when the repository is being
#                           changed
#    manuegar    07/13/18 - manuegar_multibug_01.
#    bburton     07/05/18 - 28221576 - upload -h returns exit code 1
#    bibsahoo    07/03/18 - FIX BUG 28095265
#    recornej    06/25/18 - Revert IS_OFFLINEMODE changes
#    gadiga      06/25/18 - add atp config
#    recornej    06/01/18 - Fix changereposize = 0 message .
#    migmoren    05/22/18 - Enh 28012990 - TFAT: RESTART (OR RELOAD) COMMAND
#                           NOT AVAILABLE (INSTEAD OF STOP AND START)
#    manuegar    05/10/18 - Bug 27805084 - TFAT: MULTIPLE UPLOAD COMMANDS
#                           RETURN EXIT CODE 0 EVEN WHEN FAIL.
#    cnagur      05/08/18 - Notification using smtp.properties
#    cnagur      05/02/18 - Support for Orachk Autostart
#    cnagur      05/02/18 - Support for Orachk Autostart
#    manuegar    04/30/18 - Bug 27948675 - LNX-18.1-TFA:TFACTL EXIT CODE DOES
#                           NOT MATCH TFACTL.PL EXIT CODE.
#    rramdath    04/23/18 - FIX BUG 27217590
#    manuegar    04/19/18 - Bug 27685558 - TFAT: SET COMMAND RETURNS EXIT CODE
#                           0 EVEN WHEN FAILS.
#    migmoren    04/16/18 - Bug 27605951 - VARIOUS TYPOS IN TFACTL MESSAGING
#    cnagur      04/09/18 - Fix for Bug 27812635
#    cnagur      04/13/18 - Updated Lucene jars from 6.1 to 6.6
#    bburton     03/19/18 - Bug 27665984 - remove use of POSIX::tmpnam
#    cnagur      03/15/18 - Removed jdev-rt.jar and jewt4.jar
#    bburton     02/28/18 - Add jars for Event Watching
#    bburton     02/26/18 - XbranchMerge bburton_bug-27459642 from
#                           st_tfa_12.2.1.3.1
#    migmoren    02/13/18 - BUG 27390888 - LNX-18.1-TFACTL STATUS GENERATE
#                           ERROR WHEN IS EXECUTED BY A NON-ROOT USER
#    gadiga      01/09/18 - accept wrap file
#    cnagur      01/30/18 - TFA REST API and ORDS Support
#    bburton     11/08/17 - Add Confif set from rsp file
#    cnagur      11/07/17 - Configure Cipher Suite
#    bburton     01/29/18 - 27459642 - fix regression to use UseGetTimeOfDay in
#                           Java command line on HP/UX
#    bburton     10/25/17 - Fix issue finding oraclepki even though we include
#                           it
#    llakkana    10/24/17 - Upload files to MOS changes
#    bibsahoo    10/12/17 - Add Oraclepki.jar
#    gadiga      09/15/17 - receiver autostart
#    gadiga      09/13/17 - stop receiver first
#    gadiga      09/12/17 - fix 24501109
#    gadiga      09/07/17 - move help block above the root check
#    gadiga      08/22/17 - bug26475318. Start receiver only if ACFS is running
#    chchoudh    08/21/17 - removing code to stop tomcat on syncnodes -help
#    cnagur      08/01/17 - TFA ND uninstall changes
#    cnagur      07/14/17 - Fix for Bug 26398759
#    bburton     07/06/17 - Adjust Xmx due to OOM issues
#    llakkana    07/03/17 - upload to SR support
#    bburton     06/23/17 - adjust memory for very large systems
#    chchoudh    06/22/17 - changing ownership of r.properties file to receiver
#                           non-root user
#    bburton     06/15/17 - Allow for smaller Xmx
#    anmathad    06/05/17 - Bug 25874088-Fix: Can set unlimited maxCoreFileSize
#                           and maxCoreCollectionSize
#    llakkana    06/05/17 - Clean duplicates like get_install_type etc
#    bburton     05/25/17 - Do not show dbperf in toolstatus for now.
#    bibsahoo    05/18/17 - FIX BUG 26093490
#    bibsahoo    05/05/17 - TFACTL SYNCNODES FOR WINDOWS
#    gadiga      05/04/17 - show only available tools
#    gadiga      04/25/17 - fix 25941751. strong password
#    chchoudh    04/20/17 - adding functions for starting and stopping receiver
#                           connection acceptor
#    cpujar      04/19/17 - ReadKey Module with require - Bug 25915975 
#    cnagur      04/13/17 - Fix for Bug 25817452
#    cnagur      04/07/17 - Removed Error Message 103 - Bug 24971982
#    cnagur      04/04/17 - Upload Script Changes - Bug 24413317
#    cnagur      03/09/17 - Copy Buildid after patching - Bug 25385434
#    bburton     03/09/17 - XbranchMerge bburton_remove_activation_jar_txn from
#                           st_tfa_12.2.0.1.0 - activation.jar removal only.
#    manuegar    03/07/17 - Bug 25671034 - AIX-12.2-TFA: RAN TFACTL AS ROOT
#                           USER SEEING "CHGRP ERRORS".
#    cnagur      02/14/17 - Non Root Daemon Changes
#    chchoudh    01/31/17 - changing tomcat location from tfa_home to crs_home
#    cnagur      01/25/17 - Changes to update TFA Ports - Bug 20986039
#    gadiga      01/17/17 - fix 25396478. only accept strong key
#    cpujar      12/13/16 - Added set jvmflags jvmXmxMB
#    gadiga      12/06/16 - update jsch
#    cnagur      11/24/16 - Added -silent to host add
#    manuegar    11/01/16 - Bug 24948477 - WS2012_122_TFA: HELP INFORMATION FOR
#                           'TFACTL RUN GREP' INCORRECT.
#    arupadhy    10/13/16 - Changed Xmx Params from 512 to 256
#    chchoudh    09/15/16 - fix for BUG 24358789 - LNX64-12.2-TFA: NEED HELP
#                           MESSAGE FOR 'TFACTL CLIENT' TO MANAGE/LIST MC
#                           CLIENTS
#    gadiga      09/13/16 - set jvmxmx based on RAM size
#    cpujar      09/06/16 - Bug fix : 21298035 , 20637797 - support tool status update 
#    manuegar    08/31/16 - Bug 24555932 - SOLSP64-12.2-TFA: IPS COLLECTION BY
#                           TFA WAS TERNIMATED AUTOMATICALLY.
#    ahmehta     08/30/16 - Bug : 24459910 - <tfactl receiver start> will not
#                           start receiver if TFA is not up
#    gadiga      08/26/16 - fix 24528012
#    gadiga      08/23/16 - secure config files
#    llakkana    08/02/16 - XbranchMerge manuegar_bug-24357697 from main
#    ahmehta     08/18/16 - Bug fix : 24374170 lnx64-12.2-tfa:ask running reset
#                           webadmin cmd when login rweb after restart tfa
#    sgoggi      08/02/16 - use silent for update of webadmin
#    manuegar    07/28/16 - Bug 24357697 - WS2012_122_TFA: DIAGCOLLECT -IPS
#                           HANG.
#    sgoggi      07/26/16 - use silent for update of webadmin
#    cnagur      07/19/16 - Removed command updatetfaclustermode
#    gadiga      07/17/16 - remove kafka
#    cnagur      07/13/16 - Changes to add publicIp
#    gadiga      07/12/16 - use /mnt/oracle.tfa
#    sgoggi      07/12/16 - adding receiver jars by default
#    sgoggi      07/07/16 - store topic in tfametadata entity instead of topic.txt
#    arupadhy    07/07/16 - Enabled toolstatus for windows
#    arupadhy    07/04/16 - Added managelogs autopurge support
#    arupadhy    06/21/16 - Handling invalid options for set
#    cnagur      06/21/16 - Fix for Bug 23624186
#    sgoggi      06/17/16 - start/stop receiver services
#    manuegar    06/09/16 - Bug 23249404 - LNX64-12.2-TFA:DIAGCOLLECT -IPS WITH
#                           ASM ADRPATH DID NOT COLLECT ASM ALERT LOG.
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    manuegar    06/02/16 - Bug 22025835 - LNX64-12.2-TFA:SAME IPS COLLECT CMD
#                           ON LOCAL AND REMOTE GOT DIFFERENT RESULT.
#    sgoggi      06/01/16 - tfactladmin_update_rprop, generate r properties on install
#    bburton     05/27/16 - use classpath env instead of commandline
#    gadiga      05/25/16 - list clients clusterwide
#    llakkana    05/24/16 - Remove oracle.com as it is sec issue
#    ahmehta     05/23/16 - BUG 20462210 - Added show Producer Status <tfactl producer status>
#    arupadhy    05/13/16 - Added support for disk usage monitor and it's
#                           interval
#    gadiga      05/11/16 - receiver reset webadmin
#    gadiga      05/09/16 - start tomcat automatically
#    gadiga      04/28/16 - add r.port
#    gadiga      04/22/16 - hostname with -
#    cnagur      04/19/16 - Fix nonroot pidfile permissions
#    manuegar    04/19/16 - Dynamic help.
#    sgoggi      04/14/16 - remove kafka and zookeeper logs on uninstall
#    ahmehta     04/11/16 - Bug 22933121 - LNX64-12.2-TFA:TFA STOPWEB COMMAND DID NOT WORK 
#    sgoggi      04/11/16 - monitor_filetypes, tfactl start/stop
#    amchaura    04/06/16 - replace checkTFAMain with isTFARunning to check for
#                           TFA process
#    arupadhy    03/30/16 - Removing cyclic calling of TFAService stop as
#                           stopTFAFromInit is called when TFAService is
#                           stopped
#    amchaura    03/28/16 - configurable deafult collection time range
#    arupadhy    03/21/16 - Added messages for
#                           start/stop/enable/disable/shutdown commands for
#                           windows
#    arupadhy    03/21/16 - Windows uninstall fix
#    manuegar    03/18/16 - Bug 22907263 - LNX64-12.2-TFA-MSG: HIT "ERROR: 13:
#                           PERMISSION DENIEDADDITIONAL INFORMATION: 1".
#    sgoggi      03/14/16 - fix 22904963
#    gadiga      03/08/16 - update lucene
#    amchaura    02/23/16 - Upgrade BDB version to 6.4.25
#    manuegar    02/23/16 - Change TFA IPS destination to suptools directory.
#    manuegar    02/18/16 - Support ips collections on windows (part 2).
#    sgoggi      02/17/16 - tfactl_write_topic,koption
#    manuegar    02/17/16 - Fix tfactl set command.
#    arupadhy    02/05/16 - referring tfactlwin_get_tfa_main_pid for checking
#                           tfa process id
#    bburton     02/03/16 - add back missing brackets
#    bburton     02/02/16 - XbranchMerge bburton_initrestart_fix from
#                           st_tfa_12.1.2.6
#    manuegar    01/28/16 - Report errors/warning during ips package creation.
#    arupadhy    01/22/16 - refactored windows process management functions
#                           tfadiagnostics fix on startup and patch
#    sgoggi      01/20/16 - processbug support
#    gadiga      01/18/16 - receiver monitor self
#    cnagur      01/14/16 - Changes for Java 8
#    gadiga      01/14/16 - get full path of wrap file
#    gadiga      01/14/16 - add receiver
#    arupadhy    01/10/16 - Added support for changing AUTO_START registry key
#                           on enable and disable command
#    manuegar    01/07/16 - Added support for integration tfa option all_files.
#    llakkana    12/29/15 - Fix 21140109: Meaningful msg when running
#                           diagnosetfa as non root
#    bibsahoo    12/18/15 - FIX BUG 22318970 - LNX64-12.2-TFA: CAN'T USE TFACTL
#                           SET LOGSIZE=100 -C TO SET VALUE ON ALL NODES
#    amchaura    12/14/15 - 22315724 CONFIGURABLE MINIMUM SECURITY LEVEL FOR
#                           TFA
#    manuegar    12/14/15 - Added pool for TFA IPS Parallel Processing.
#    manuegar    12/09/15 - Support CRS when specifying the full ADR homepath
#                           for the -adrhomepath switch.
#    arupadhy    12/07/15 - Changes related to stopTFAFromInit for windows
#    amchaura    11/26/15 - Fix BUG 22142600 - TFA : AUTODIAGCOLLECT EVENT
#                           TRIGGERING FOR 'SYSTEM STATE DUMP'
#    sgoggi      11/23/15 - support pluginadd for receiver,tfactladmin_addplugin
#    gadiga      11/09/15 - dont print message
#    arupadhy    11/02/15 - Diagnose tfa related branching for windows
#    manuegar    10/23/15 - Bug 21943932 - LNX64-12.2-TFA:TFAC HIT DIA-49428:
#                           NO SUCH DIRECTORY OR DIRECTORY NOT ACCESSIBLE.
#    llakkana    10/22/15 - Cleanup addReceiver
#    bibsahoo    10/20/15 - FIX BUG 21977617 - [12201-LIN64-TFA] TFACTL
#                           DIAGNOSETFA GIVE CONFUSED MSG WITH -H OPTION
#    manuegar    10/14/15 - Bug 21768769 - LNX64-12.2-TFA: IPS FILES SHOULD BE
#                           COLLECTED IN PARALLEL.
#    gadiga      10/13/15 - create tfajson
#    arupadhy    10/07/15 - changes related to tfactl start and stop commands
#    cnagur      12/03/15 - Added minSpaceForRTScan
#    cnagur      11/12/15 - Added -local to set tfa_base
#    cnagur      10/07/15 - Option to sync TFA Nodes - 21964456
#    manuegar    09/28/15 - Bug 21665468 - TFA : ERROR: UNAUTHORIZED TFA
#                           COMMAND : SU < USER > -C TFACTLIPS.
#    cnagur      09/25/15 - Remove SIGAR
#    gadiga      09/24/15 - support export
#    arupadhy    09/21/15 - Change in uninstallTFA routine to accommodate
#                           windows uninstall
#    gadiga      09/20/15 - receiver start and webstart
#    cnagur      09/18/15 - Fix for Bug 21840634
#    sgoggi      09/07/15 - Bug# 21546218 - LNX64-12.2-TFA:COLLECTOR WAS NOT ABLE TO ADD RECEIVERS
#    manuegar    09/07/15 - Bug 21785398 - TFA : INCORRECT DIR STRUCTURE IN TFA
#                           ZIP FILE.
#    arupadhy    09/01/15 - extra sleep time not required for windows
#    cnagur      08/31/15 - Fix for Bug 21745495
#    manuegar    08/26/15 - Bug 21643708 - LNX64-12.2-TFA-IPS:IPS WAS NOT ABLE
#                           TO SHOW AND COLLECT PKGS IN ANOTHER ADRBASE.
#    bibsahoo    08/23/15 - Adding Error Statements when certificates are not
#                           generated
#    cnagur      08/23/15 - Fix for Bug 20380506
#    arupadhy    08/20/15 - Replaced linux specific path in certain areas, date
#                           system command change for windows, conditioned
#                           receiver code for windows for normal TFA startup on
#                           windows
#    bburton     08/20/15 - change jsch name
#    manuegar    07/31/15 - Bug 21471902 - LNX64-12.2-TFA-IPS:DIAGCOLLECT HUNG
#                           AT WAITING FOR IPS RESULT OF REMOTE NODE.
#    arupadhy    07/24/15 - Fix for Bug 21364908
#    gadiga      07/21/15 - add parseevents
#    gadiga      07/21/15 - stop tools on tfactl stop
#    cnagur      07/17/15 - XbranchMerge cnagur_tfa_bug_21312262_txn from
#                           st_tfa_12.1.0.2.4psu
#    manuegar    07/14/15 - Bug 21352560 - LNX64-12.2-TFA:DIAGCOLLECT -IPS HUNG
#                           AT WAITING IPS RESULT.
#    llakkana    06/24/15 - Replace commons io 2.2 with 2.1
#    llakkana    06/18/15 - Don't call start receiver function after stopping
#                           kafka server
#    manuegar    06/17/15 - Map remote ADR homepaths.
#    amchaura    06/17/15 - log4j config
#    cnagur      06/16/15 - Added sticky bit to repository
#    gadiga      06/09/15 - XbranchMerge gadiga_tfa_in_dbaas_12124 from
#    cnagur      06/24/15 - Fix for Bug 21312262
#                           st_tfa_12.1.2.4
#    bburton     06/02/15 - XbranchMerge bburton_secure_tfa_fix from
#                           st_tfa_12.1.0.2.4psu
#    manuegar    05/28/15 - TFA/Ips collection Logic 2.
#    cnagur      05/22/15 - Copy Files using Tags
#    manuegar    05/11/15 - Bug 21070215 - LNX64-12.1-TFA-SCS:SET
#                           LOGSIZE/LOGCOUNT COMMANDS TAKE ABOUT 2+ MINS TO
#                           EXECUTE.
#    manuegar    05/11/15 - Bug 18814579 - LNX64-12.1-TFA-SCS:SET
#                           LOGSIZE/LOGCOUNT NEED CLEAR WARNING WHEN TFA IS
#                           DOWN.
#    bburton     05/11/15 - Fix bug for upgrading tfa_directories.txt
#    manuegar    05/05/15 - Bug 18769012 - SOLX64-12.1-TFA-SCS:NO ERROR MSG
#                           REJECTING INCORRECT TFACTL SET COMMAND.
#    gadiga      04/09/15 - windows
#    cnagur      03/30/15 - Fix for Bug 20796717
#    cnagur      02/26/15 - Support for TFA on Cloud
#    gadiga      05/04/15 - SR upload
#    gadiga      04/09/15 - windows
#    cnagur      02/26/15 - Support for TFA on Cloud
#    gadiga      02/24/15 - enable non-root for tools
#    cnagur      02/13/15 - Fix for Bug 20462247
#    bburton     02/06/15 - Bug 20454050 Trying to set properties for a Table
#                           Column that does not exist
#    cnagur      02/03/15 - Fix for Bug 20380473
#    cnagur      01/21/15 - Fix for Bug 20341915
#    gadiga      01/16/15 - topology collection
#    gadiga      01/14/15 - disable clusterwide
#    bburton     01/14/15 - Bug 20351923 - Do not do addRowLine (---) before a
#                           row exists.
#    cnagur      01/07/15 - Added updateautodiagcollect
#    cnagur      12/18/14 - Fix for Bug 20225813
#    manuegar    12/18/14 - 19543941 - LNX64-12.2-TFA-SCS:NOT EXPECTED RESULT FOR
#                           SETTING INVALID REPOSIZE VALUE
#    gadiga      12/15/14 - stop suptools only for patching and uninstall
#    manuegar    12/12/14 - Ips collection logic
#    gadiga      12/11/14 - stop suptools before tfa shutdowbn
#    gadiga      12/09/14 - tool can be started as other user
#    gadiga      12/09/14 - toolstatus error
#    cnagur      12/08/14 - Fix for Bug 20050943
#    amchaura    12/03/14 - set/get NLS parameters
#    gadiga      12/01/14 - tool status for only daemon tools
#    cnagur      11/23/14 - Fix for Bug 19985667
#    llakkana    11/21/14 - Start receiver and producers
#    gadiga      11/19/14 - start and stop tools
#    amchaura    11/06/14 - Bug 19954370 - LNX64-12.2-TFA:AUTODIAGCOLLECT
#                           SUPPORT SCRIPT EXECUTION BASED ON SEARCH STRINGS
#    manuegar    11/05/14 - Implement <action> <toolname> <flags> for support
#                           tools.
#    cnagur      11/04/14 - Changes for AutoPurge - Bug 19941391
#    cnagur      10/14/14 - Fix for Bug 19794651
#    llakkana    09/25/14 - View files of local/remote node
#    amchaura    09/12/14 - Fix 19585579 - HPI_12102_TFA:TFACTL NOT COLLECT CRS
#                           LOGS WHEN RUNNING TFACTL DIAGCOLLECT -ALL
#    cnagur      09/02/14 - Changes for config.properties
#    cnagur      08/27/14 - Added updateMaxCoreFileSize & updateMaxCoreCollectionSize
#    llakkana    08/25/14 - bug fix 19464967
#    cnagur      08/06/14 - Integration of SIGAR - 19352380
#    manuegar    07/22/14 - Relocate tfactl_lib
#    manuegar    07/04/14 - Creation
#
############################ Functions List #################################
#
# startTFA
# stopTFA
# shutdownTFA
# enableTFA
# disableTFA
# startTFAFromInit
# stopTFAFromInit
# uninstallTFA
# sendUninstallUpdate
# collectTFADiagnostics
# runGUI
# checkAutoPatching
# checkKeyStores
# executeCommandInHost
# executeCommandInHostAndPrint
# cleanTFAMain
# addReceiver
# startService
# removeReceiver
# isReceiverRegistered
# addDom0IP
# removeDom0IP
# printDom0IP
# changeRepository
# updateMaxLogSize
# updateMaxLogCount
# runTest
# validateFileTypePattern
# zipFilesForDate
# deleteDatabase
# tfactladmin_restrictProtocol
#
#############################################################################

package tfactladmin;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(tfactladmin_init
                 );

use strict;
use IPC::Open2;
use File::Copy;
use File::Path;
use File::Find;
use File::Basename;
use File::Basename  qw( dirname );
use File::Spec::Functions;
use Cwd 'abs_path';
use Getopt::Long;
use Sys::Hostname;
use POSIX;
use POSIX qw(:termios_h);
use POSIX qw/strftime/;
use Carp;
use Config;
use Data::Dumper;
use Socket;
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
use constant TOOLNOTRUNNING            => 0;
use constant TOOLRUNNING               => 1;
use constant TOOLSTOPPED               => 2;
use constant TOOLDISABLED              => 2;
use constant TOOLNOTDAEMON             => 3;
use constant TOOLNOTAVAILABLE          => 10;

use tfactlglobal;
use tfactlshare;
use osutils;
use tfactlwin;

#################### tfactladmin Global Constants ####################
my $to;
my $port;
my $tfa_base;
my $onlylocal = 0;
my $addHostSilent = 1;
my $java_home;
my $tdinterval;
my $tdfrequency;
my $DIAGNOSEARGS;
my $SYNCTFANODES = 0;
my $syncpatch = 0;
my $configfromresp = 0;
my $rspfile = "";
my $prevadrcihomepath = "";
my $rest;
my $stopords;
my $smtp = 0;
my $startorachkdaemon;
my $stoporachkdaemon;
my $debugips = FALSE;
my @FLAGS_GENERIC = ();

my (%tfactladmin_cmds) = (start      => {},
                          stop       => {},
                          restart    => {},
                          deploy     => {},
                          sslrestart => {},
                          status     => {},
                          shutdown   => {},
                          local      => {},
                          localade   => {},
                          startall   => {},
                          stopall    => {},
                          toolstatus => {},
                          disable    => {},
                          enable     => {},
                          initstart  => {},
                          initstop   => {},
                          rest       => {},
                          stopords   => {},
                          startorachkdaemon => {}, 
                          stoporachkdaemon => {}, 
                          executecommand => {},
                          executecommandprint => {},
                          createtntprop  => {},
                          check      => {},
                          checkautopatching => {},
                          checkkeystores => {},
                          clean       => {},
                          deletedb    => {},
                          gui         => {},
                          generatecookie => {},
                          generatecerts => {},
                          setsslkey => {},
                          uninstall   => {},
                          diagnosetfa => {},
                          syncnodes   => {},
                          syncpatch   => {},
                          sendmail    => {},
                          configfromresp    => {},
                          set         => {},
                          host        => {},
                          zipfiles    => {},
                          createTfaSetup => {},
                          updateJDKInTFASetup => {},
                          recreateFileEntitiesInBDB => {},
                          fixInitTfa  => {},
                          fixTfactl   => {},
                          fixTfadiagnostics => {},
                          copytfactl  => {},
                          updatepropertiesfile  => {},
                          updatedirectoriesfile  => {},
                          updateautodiagcollect  => {},
                          updateciphersuite  => {},
                          checkfileaccessusingsu => {},
                          checkfileaccess => {},
                          runtest     => {},
                          senduninstallupdate => {},
                          stop_suptools => {},
                          parseevents => {},
                          checkfiletypepattern => {},
                          receiver     => {},
                          producer     => {},
                          client     => {},
                          dom0IP       => {},
                          restrictprotocol	=> {},
                          collectzips  => {},
                          generatefilelist => {},
                          tvi		=> {},
                          upload => {},                          
                          setupmos => {},
                          setupsudocmds => {},
                          cloudcheck => {}
                         );


#################### tfactladmin Global Variables ####################

sub is_tfactl
{
  return 1;
}


########
# NAME
#   tfactladmin_init
#
# DESCRIPTION
#   This function initializes the tfactladmin module.  For now it 
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
  push (@tfactlglobal_command_callbacks, \&tfactladmin_process_cmd);
  push (@tfactlglobal_help_callbacks, \&tfactladmin_process_help);
  push (@tfactlglobal_command_list_callbacks, \&tfactladmin_get_tfactl_cmds);
  push (@tfactlglobal_is_command_callbacks, \&tfactladmin_is_cmd);
  push (@tfactlglobal_is_wildcard_callbacks, \&tfactladmin_is_wildcard_cmd);
  push (@tfactlglobal_syntax_error_callbacks, \&tfactladmin_syntax_error);
  push (@tfactlglobal_no_instance_callbacks, \&tfactladmin_is_no_instance_cmd);
  %tfactlglobal_cmds = (%tfactlglobal_cmds, %tfactladmin_cmds);

  #Perform TFACTL consistency check if enabled
  if($tfactlglobal_hash{'consistchk'} eq 'y')
  {
     if(!tfactlshare_check_option_consistency(%tfactladmin_cmds))
     {   
       exit 1;
     }
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactladmin init", 'y', 'n');

}

########
# NAME
#   tfactladmin_process_cmd
#
# DESCRIPTION
#   This routine calls the appropriate routine to process the command 
#   specified by $tfactlglobal_hash{'cmd'}.
#
# PARAMETERS
#   dbh       (IN) - initialized database handle, must be non-null.
#
# RETURNS
#   1 if command is found in the tfactladmin module; 0 if not.
#
# NOTES
#   Only tfactl_shell() calls this routine.
########
sub tfactladmin_process_cmd 
{
  my ($retval) = 0;
  my ($succ)   = 0;

  # Get current command from global value, which is set by 
  # tfactladmin_parse_tfactl_args()and by tfactl_shell().
  my ($cmd) = $tfactlglobal_hash{'cmd'};

  # Declare and initialize hash of function pointers, each designating a 
  # routine that processes an tfactladmin command.
  my (%cmdhash) = ( admin               => \&tfactladmin_process_command,
                    start               => \&tfactladmin_process_command, 
                    stop                => \&tfactladmin_process_command,
                    restart             => \&tfactladmin_process_command,
                    deploy              => \&tfactladmin_process_command,
                    sslrestart          => \&tfactladmin_process_command,
                    status              => \&tfactladmin_process_command,
                    shutdown            => \&tfactladmin_process_command,
                    local               => \&tfactladmin_process_command,
                    localade            => \&tfactladmin_process_command,
                    startall            => \&tfactladmin_process_command,
                    stopall             => \&tfactladmin_process_command,
                    toolstatus          => \&tfactladmin_process_command,
                    disable             => \&tfactladmin_process_command,
                    enable              => \&tfactladmin_process_command,
                    initstart           => \&tfactladmin_process_command,
                    initstop            => \&tfactladmin_process_command,
                    rest                => \&tfactladmin_process_command,
                    stopords            => \&tfactladmin_process_command,
                    startorachkdaemon   => \&tfactladmin_process_command,
                    stoporachkdaemon    => \&tfactladmin_process_command,
                    executecommand      => \&tfactladmin_process_command,
                    executecommandprint => \&tfactladmin_process_command,
                    createtntprop       => \&tfactladmin_process_command,
                    check               => \&tfactladmin_process_command,
                    checkautopatching   => \&tfactladmin_process_command,
                    checkkeystores      => \&tfactladmin_process_command,
                    clean               => \&tfactladmin_process_command,
                    deletedb            => \&tfactladmin_process_command,
                    gui                 => \&tfactladmin_process_command,
                    generatecookie      => \&tfactladmin_process_command,
                    generatecerts       => \&tfactladmin_process_command,
                    setsslkey           => \&tfactladmin_process_command,
                    uninstall           => \&tfactladmin_process_command,
                    diagnosetfa         => \&tfactladmin_process_command,
                    syncnodes           => \&tfactladmin_process_command,
                    syncpatch           => \&tfactladmin_process_command,
                    sendmail            => \&tfactladmin_process_command,
                    configfromresp      => \&tfactladmin_process_command,
                    set                 => \&tfactladmin_process_command, 
                    host                => \&tfactladmin_process_command, 
                    zipfiles            => \&tfactladmin_process_command, 
                    createTfaSetup      => \&tfactladmin_process_command, 
                    updateJDKInTFASetup => \&tfactladmin_process_command, 
                    recreateFileEntitiesInBDB => \&tfactladmin_process_command, 
                    fixInitTfa          => \&tfactladmin_process_command, 
                    fixTfadiagnostics   => \&tfactladmin_process_command, 
                    fixTfactl           => \&tfactladmin_process_command, 
                    copytfactl          => \&tfactladmin_process_command, 
                    updatepropertiesfile   => \&tfactladmin_process_command,
                    updatedirectoriesfile  => \&tfactladmin_process_command,
                    updateautodiagcollect  => \&tfactladmin_process_command,
                    updateciphersuite  => \&tfactladmin_process_command,
                    checkfileaccessusingsu => \&tfactladmin_process_command, 
                    checkfileaccess     => \&tfactladmin_process_command, 
                    runtest             => \&tfactladmin_process_command, 
                    senduninstallupdate => \&tfactladmin_process_command, 
                    stop_suptools       => \&tfactladmin_process_command, 
                    parseevents         => \&tfactladmin_process_command, 
                    checkfiletypepattern => \&tfactladmin_process_command, 
                    receiver            => \&tfactladmin_process_command,
                    producer            => \&tfactladmin_process_command,
                    client              => \&tfactladmin_process_command,
                    dom0IP              => \&tfactladmin_process_command,
                    restrictprotocol    => \&tfactladmin_process_command,
                    collectzips         => \&tfactladmin_process_command,
                    generatefilelist    => \&tfactladmin_process_command,		    
                    tvi	 		=> \&tfactladmin_process_command,
                    upload    => \&tfactladmin_process_command,		    
                    setupmos    => \&tfactladmin_process_command,
                    setupsudocmds => \&tfactladmin_process_command,
                    cloudcheck => \&tfactladmin_process_command
                  );





  if (defined ( $cmdhash{ $cmd } ))
  {    # If user specifies a known command, then call routine to process it. #
    $retval = $cmdhash{ $cmd }->();
    $succ = 1;
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactladmin tfactladmin_process_cmd", 'y', 'n');

  return ($succ, $retval);
}

########
# NAME
#   tfactladmin_process_command
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
#   Only tfactladmin_process_cmd() calls this function.
########
sub tfactladmin_process_command
{
  my $retval = 0;

  tfactlshare_trace(3, "tfactl (PID = $$) tfactladmin tfactladmin_process_command", 'y', 'n');
  # Read the commands
  @ARGV = @tfactlglobal_argv;
  my $clustercommand = "true";
  if ( lc($ARGV[0]) eq "local" ) {
    $clustercommand = shift(@ARGV);
    $tfactlglobal_hash{'localcmd'} = "true";
    # Unmarshall special chars
    for my $ndx ( 0..$#ARGV ) {
       $ARGV[$ndx] =~ s/quote/'/g;
       $ARGV[$ndx] =~ s/colon/:/g;
       $ARGV[$ndx] =~ s/dash/-/g;
    }
  } elsif ( lc($ARGV[0]) eq "localade" ) {
    $clustercommand = shift(@ARGV); 
    $tfactlglobal_hash{'localcmd'} = "true";
    $tfactlglobal_hash{'adecmd'} = "true";
  } else {
    $tfactlglobal_hash{'localcmd'} = "false";
  }
  my $command1 = shift(@ARGV);
  my $command2 = shift(@ARGV);
  my $switch_val = $command1;

  tfactlshare_trace(5, "tfactl (PID = $$) tfactladmin_process_command " .
                    "command1 $command1, command2 $command2", 'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) tfactladmin_process_command " .
                    "CLUSTERCOMMAND $clustercommand", 'y', 'y');

  if ( $switch_val eq "ips" ) {
    #$tfactlglobal_hash{'srcmod'} = "tfactladmin"; # src mod
    #$tfactlglobal_hash{'cmd'}    = "ips";        # ips
    shift @tfactlglobal_argv;
    tfactlshare_trace(5, "tfactl (PID = $$) tfactladmin_process_command " .
                       "calling local ips Array @tfactlglobal_argv", 'y', 'y'); 
    # local ips ping
    if ( lc($command2) eq "ping" ) {
      print "ACK";
      return;
    }

    # Unmarshall special chars
    for my $ndx ( 0..$#tfactlglobal_argv ) {
       $tfactlglobal_argv[$ndx] =~ s/quote/'/g;
       $tfactlglobal_argv[$ndx] =~ s/colon/:/g;
       $tfactlglobal_argv[$ndx] =~ s/dash/-/g;
       $tfactlglobal_argv[$ndx] =~ s/space/ /g;
       $tfactlglobal_argv[$ndx] =~ s/paropen/\(/g;
       $tfactlglobal_argv[$ndx] =~ s/parclose/\)/g;
       $tfactlglobal_argv[$ndx] =~ s/underscore/\_/g;
    }
    # Call ips command
    ###
    my $debugtime = strftime('%m.%d.%Y-%H.%M.%S',localtime);
    my $localhost=tolower_host();
    $debugips = tfactlshare_getdebugips($tfa_home);
    open (my $fh, ">>", catfile($tfactlglobal_trace_path,"tfactladmin_ips_$localhost.log") ) or die 
    "Could not open " . catfile($tfactlglobal_trace_path,"tfactladmin_ips_$localhost.log") . "\n" if $debugips;
    shift @tfactlglobal_argv;
    $TFAIPS_TARGETHOMEPATH  = shift @tfactlglobal_argv;
    $TFAIPS_ADRCIHOMEPATH   = shift @tfactlglobal_argv;
    $TFAIPS_ADRCIORACLEHOME = shift @tfactlglobal_argv;
    $TFAIPS_ADRBASE         = shift @tfactlglobal_argv;

    # Is $TFAIPS_ADRCIHOMEPATH a valid ADR homepath in remote node ?
    my $ipsoutput = "";
    my $mapped_adrhomepath;
    $ipsoutput = tfactlshare_call_adrci("show homepath", "yes","no","","","no",
                           $TFAIPS_ADRBASE,"no");

    # No ADR homes are available
    if ( $ipsoutput =~ /No ADR homes are set/ ) {
       print $ipsoutput;
       return;
    }
    ###
    print $fh "\n\n--------------------- Begin @tfactlglobal_argv ----------------\n" if $debugips;
    print $fh "$debugtime ipsout show homepath $ipsoutput \n" if $debugips;
    foreach my $line (split /\n/, $ipsoutput) {
      if ( $line =~ m/^(diag.*)/ ) {
        my $diagpath = $1;
        my $dbpart1_src = "";
        my $dbpart2_src = "";
        my $dbpart1_dst = "";
        my $dbpart2_dst = "";

        ###
        print $fh "$debugtime Prepare def homepath $diagpath\n" if $debugips;
        if ( $TFAIPS_ADRCIHOMEPATH =~ m/.*[\/\\]rdbms[\/\\](.*)[\/\\](.*)\_[0-9]+/ ) {
          $dbpart1_src = $1;
          $dbpart2_src = $2;
        } elsif ( $TFAIPS_ADRCIHOMEPATH =~ m/.*[\/\\]rdbms[\/\\](.*)[\/\\].*[0-9]+/ ) {
          my $basewd = $1;
          if ( $TFAIPS_ADRCIHOMEPATH =~ m/.*[\/\\]rdbms[\/\\]$basewd[\/\\]$basewd([0-9]+)/ ) {
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

        if ( $TFAIPS_ADRCIHOMEPATH eq $diagpath ) {
          $mapped_adrhomepath = $diagpath;
          last;
        }

       if ( ($TFAIPS_ADRCIHOMEPATH =~ m/.*[\/\\]\+ASM[0-9]+/ &&
             $diagpath =~ m/.*[\/\\]\+ASM[0-9]+/)                     ||
            ($TFAIPS_ADRCIHOMEPATH =~ m/.*[\/\\]\+APX[0-9]+/ &&
             $diagpath =~ m/.*[\/\\]\+APX[0-9]+/)                     ||
            ($TFAIPS_ADRCIHOMEPATH =~ m/.*[\/\\]\+IOS[0-9]+/ &&
             $diagpath =~ m/.*[\/\\]\+IOS[0-9]+/)                     ||
            ($TFAIPS_ADRCIHOMEPATH =~ m/.*[\/\\]diag[\/\\]crs[\/\\].*/ &&
             $diagpath =~ m/.*[\/\\]diag[\/\\]crs[\/\\].*/)                   ||
            ( length $dbpart1_src && length $dbpart1_dst &&
               $dbpart1_src eq $dbpart1_dst && $dbpart2_src eq $dbpart2_dst )  )  {
         $mapped_adrhomepath = $diagpath;
       } elsif (
             $TFAIPS_ADRCIHOMEPATH =~
             m/.*[\/\\](asmtool|clients|asm|afdboot|diagtool)[\/\\]user_(.*)[\/\\](host|adrci)_.*/  ) {
         my $diagtype = $1;
         my $username = $2;
         print $fh "$debugtime diagtype $diagtype\n" if $debugips;
         print $fh "$debugtime username $username\n" if $debugips;
         # (asmtool|clients|asm|afdboot|diagtool)
         if ( $diagpath =~ m/.*[\/\\]$diagtype[\/\\]user_$username[\/\\](host|adrci)_.*/ ) {
           $mapped_adrhomepath = $diagpath;
         }
       }

      } # end if $line =~ m/^(diag.*)/
    } # end foreach $ipsoutput

    ###
    if ( $debugips ) {
      print $fh "\n\n------------------ MAPPING @tfactlglobal_argv  --------------------------\n";
      print $fh "$debugtime MAPPED adrhomepath $mapped_adrhomepath \n";
      print $fh "$debugtime Before TFAIPS_TARGETHOMEPATH $TFAIPS_TARGETHOMEPATH \n";
      print $fh "$debugtime Before TFAIPS_ADRCIHOMEPATH $TFAIPS_ADRCIHOMEPATH \n";
      print $fh "$debugtime BeforeTFAIPS_ADRCIORACLEHOME $TFAIPS_ADRCIORACLEHOME \n";
      print $fh "$debugtime Before TFAIPS_ADRBASE $TFAIPS_ADRBASE \n";
    }

    # non matching adrhomepath
    print $fh "$debugtime  ===> mapped_adrhomepath $mapped_adrhomepath \n" if $debugips;
    if ($mapped_adrhomepath eq "" ) {
      print $fh "$debugtime Returning non matching adrhomepath\n" if $debugips;
      print "non matching adrhomepath";
      return;
    }

    if ( $TFAIPS_TARGETHOMEPATH ne $mapped_adrhomepath ) {
      $prevadrcihomepath = $TFAIPS_ADRCIHOMEPATH;
      $TFAIPS_TARGETHOMEPATH =~ s/$TFAIPS_ADRCIHOMEPATH/$mapped_adrhomepath/;
      $TFAIPS_ADRCIHOMEPATH = $mapped_adrhomepath;      
    }

    # Map target homepath to $mapped_adrhomepath
    # ==========================================
    if ( $TFAIPS_TARGETHOMEPATH =~ /(.*)ipscoll_$localhost[\/\\].*/ ) {
      # su section
      if ( $current_user eq "root" && not $IS_WINDOWS ) {
        # Get osowner
        my $osowner = getFileOwner(catfile($TFAIPS_ADRBASE,$TFAIPS_ADRCIHOMEPATH));
        $TFAIPS_TARGETHOMEPATH = catfile($1 . "ipscoll_$localhost","user_$osowner",$TFAIPS_ADRCIHOMEPATH);
      } else {
        $TFAIPS_TARGETHOMEPATH = catfile($1 . "ipscoll_$localhost",$TFAIPS_ADRCIHOMEPATH);
      }
    }

    if ( $debugips ) {
      print $fh "$debugtime After TFAIPS_TARGETHOMEPATH $TFAIPS_TARGETHOMEPATH \n";
      print $fh "$debugtime After TFAIPS_ADRCIHOMEPATH $TFAIPS_ADRCIHOMEPATH \n";
    }

    # Create target homepath
    # ======================
    # tfactlshare_create_dir("$TFAIPS_TARGETHOMEPATH", "740") if ( ! -d "$TFAIPS_TARGETHOMEPATH" );

    my $cmd;
    my $keyfile = catfile($TFAIPS_TARGETHOMEPATH,"remkeyfile.xml");
    if ( not $IS_WINDOWS ) {
      $cmd = `ls $keyfile`;
    } else {
      $cmd = `DIR $keyfile`; 
    }
    print $fh "ls/DIR $keyfile => $cmd \n" if $debugips;
    if ( ! -e $keyfile ) {
      # remote ips_base location
      if ( $TFAIPS_TARGETHOMEPATH =~ /(.*[\/\\]suptools[\/\\]ips[\/\\]user_.*)[\/\\].*ipscoll_.*[\/\\](diag[\/\\].*)/ ) {
        my $dgpath = $prevadrcihomepath;
        my $srcpath = $1;
        $dgpath =~ s/(\/|\\)/_/g;
        $dgpath =~ s/\+/plus/g;
        my $remfilename = "remkeyfile_" . $dgpath . ".xml";
        my $remaux;
        $remfilename =~ s/$localhost/\*/;
        $remaux = catfile($srcpath,$remfilename);

        if ( not $IS_WINDOWS ) {
          $remfilename = `ls $remaux`;
        } else {
          my @retlines = `DIR $remaux`;
          foreach my $line (@retlines) {
            if ( $line =~ /.*(remkeyfile_.*\.xml).*/ ) {
              $remfilename = $1;
            }
          } # end foreach
        } # end if not $IS_WINDOWS
        chomp($remfilename);
        $remfilename =~ s/\n//g;

        ###
        if ( $debugips ) {
          print $fh "$debugtime srcpath $srcpath \n";
          print $fh "$debugtime prevadrcihomepath $prevadrcihomepath \n";
          print $fh "$debugtime dgpath $dgpath \n";
          print $fh "$debugtime remfilename ($remfilename) \n";
          print $fh "$debugtime remaux ($remaux) \n";
          print $fh "$debugtime copy src $remfilename dest $TFAIPS_TARGETHOMEPATH/remkeyfile.xml \n";
        } # end if $debugips

        # remaux = catfile($srcpath,$remfilename)
        copy( $remaux, catfile($TFAIPS_TARGETHOMEPATH,"remkeyfile.xml"));
        # remove $remfilename "remkeyfile_" . $dgpath . ".xml"
        unlink ( $remaux ) if ! $debugips;
      }
    }
    eval {
       my $path2make = catfile($TFAIPS_TARGETHOMEPATH,"incpkg");
       mkpath($path2make) if ( ! -d $path2make );
       if ( $TFAIPS_TARGETHOMEPATH =~ /(.*[\/\\])diag[\/\\].*/ ) {
         if ( $current_user eq "root" && not $IS_WINDOWS ) {
           # su section
           # Get osowner
           my $osowner = getFileOwner(catfile($TFAIPS_ADRBASE,$TFAIPS_ADRCIHOMEPATH));
           `$CHOWN -R $osowner $1`;
           my $pgroup = getgrgid $(;
           `$CHGRP -R $pgroup $1`;
         } else {
           host("$CHMOD -R 700 " . catfile($1,"diag")) if not $IS_WINDOWS;
         } 
       }
    };
    if ( $@ ) {
      print "Error while creating  $TFAIPS_TARGETHOMEPATH.\n";
      print $fh "$debugtime Error while creating  $TFAIPS_TARGETHOMEPATH.\n" if $debugips;
      print "$@\n";
      exit 1;
    }

    # purge
    # su section
    my $osowner = getFileOwner(catfile($TFAIPS_ADRBASE,$TFAIPS_ADRCIHOMEPATH));
    if ( defined $tfactlglobal_argv[0] && $tfactlglobal_argv[0] eq "purgecolldir" ) {
      print $fh "$debugtime Trying purgecolldir TFAIPS_TARGETHOMEPATH $TFAIPS_TARGETHOMEPATH\n" if $debugips;
      if ( $TFAIPS_TARGETHOMEPATH =~ /(.*)ipscoll_$localhost[\/\\](user_$osowner[\/\\])?diag[\/\\].*/ ) {
        my $purgedir = $1 . "ipscoll_$localhost";
        eval {
             if ( not $IS_WINDOWS ) {
               print $fh "$debugtime $RM -rf $purgedir\n" if $debugips;
               host("$RM -rf $purgedir") if ! $debugips;
             } else {
               my $rmcmd = 'rmdir /s /q "' . $purgedir . '"';
               # Windows purge
               print $fh "$debugtime purgecmd remote $rmcmd\n" if $debugips;
               host($rmcmd) if ! $debugips;
               # Remove associated keyfile
               # su section
               if ( $TFAIPS_TARGETHOMEPATH =~ /(.*[\/\\]suptools[\/\\]ips[\/\\]user_.*)[\/\\].*ipscoll_.*[\/\\](user_$osowner[\/\\])?(diag[\/\\].*)/ ) {
                 my $dgpath = $2;
                 my $srcpath = $1;
                 $dgpath =~ s/(\/|\\)/_/g;
                 $dgpath =~ s/\+/plus/g;
                 my $remfilename = "remkeyfile_" . $dgpath . ".xml";
                 $remfilename =~ s/$localhost/\*/;
                 host("$RM " . catfile($srcpath,$remfilename));
               } # end if $TFAIPS_TARGETHOMEPATH =~
             }
        };   
        if ( $@ ) {
          print "Error while removing  $purgedir.\n";
          print $fh "$debugtime Error while removing  $purgedir.\n" if $debugips;
          print "$@\n";
          exit 1;
        }
      } # end if $TFAIPS_TARGETHOMEPATH =~ /(.*)ipscoll_$localhost\/diag\/.*/
    } # end if defined $tfactlglobal_argv[0] && $tfactlglobal_argv[0] eq "purgecolldir"


    # starttimeips cmd ?
    my $starttimeips;
    if ( defined $tfactlglobal_argv[0] && $tfactlglobal_argv[0] eq "starttimeips" ) {
      shift @tfactlglobal_argv; # remove starttimeips
      $starttimeips = shift @tfactlglobal_argv;
      ###
      print $fh "$debugtime starttimeips $starttimeips \n" if $debugips;
    }

    my $ipscmd = "ips " . join(" ",@tfactlglobal_argv);
    ###
    print $fh "$debugtime ipscmd $ipscmd\n" if $debugips;
    my $ipsout;
    if ( defined $tfactlglobal_argv[0] && $tfactlglobal_argv[0] ne "dummy" &&
         $tfactlglobal_argv[0] ne "purgecolldir" ) {
    $ipsout = tfactlshare_call_adrci($ipscmd, "yes","no",$TFAIPS_ADRCIHOMEPATH,
              $TFAIPS_ADRCIORACLEHOME, "no",
              $TFAIPS_ADRBASE,"no");
    # Handle DIA-51705 during IPS package generation
    if ( $ipsout =~ /DIA-51705/ ) {
      $ipsout = tfactlshare_call_adrci($ipscmd.";".$ipscmd, "yes","no",$TFAIPS_ADRCIHOMEPATH,
                $TFAIPS_ADRCIORACLEHOME, "no",
                $TFAIPS_ADRBASE,"no");
      $ipsout =~ s/DIA\-51705\: XML XPATH error\: [0-9]* \"XmlXPathEval\"\n//g;
    }

    if ( $ipsout =~ /Package .* ready under/ ) {
      my $ipspkgnmbr;
      my $ips_base;
      foreach my $line (split /\n/ , $ipsout) {
         print $fh "$debugtime Package ready line ($line).\n" if $debugips;
         if ( $line =~ /Package .* ready under/ ) {
           if ( $ipscmd =~ /ips generate package ([0-9]+) in (.*)/ ) {
             $ipspkgnmbr = $1;
             $ips_base   = $2;
           }
           $ipsout  = "Package $ipspkgnmbr ready under TFA ips directory:\n";
           $ipsout .= "$ips_base\n";
         } elsif ( $line =~ m/^(([\/\\][\w\s\.\_\-\+]+)+)$/ || $line =~ m/^[\w\:]*([\/\\][\w\s\.\_\-\+]+)+$/ ) {
           my $srcpath = $1;
           if ( $srcpath =~ /(.*)[\/\\].*$/ ) {
             host("$CP -r $1 " . catfile($ips_base,"incpkg"));
             # Parse manifest file
             my @retfiles;
              # catfile("/","pkg_manifest_$ipspkgnmbr\.xml")
             @retfiles = tfactlshare_parse_pkgmanifest( catfile("$ips_base","manifest.xml") );
             print $fh "$debugtime Parsing manifest file pkg_manifest_$ipspkgnmbr\.xml ...\n" if $debugips ; 

             my $ipssrcdir;
             # -------------- process files --------------------- begin
             for my $ndx ( 0 .. $#retfiles ) {
               my $filesdetref = $retfiles[$ndx];
               my @filesdet    = @$filesdetref;
               print $fh "$debugtime checking ... $filesdet[MFILE_NAME] \n" if $debugips;

               my $srcdir = catfile($filesdet[MADR_HOME],$filesdet[MLOCATION]);
               my $dstdir = catfile($ips_base,$filesdet[MLOCATION]);
               my $srcfile = catfile($srcdir,$filesdet[MFILE_NAME]);
               my $dstfile = catfile($dstdir,$filesdet[MFILE_NAME]);
               $srcdir =~ s/\/\//\//g;
               $srcdir =~ s/\\\\/\\/g;
               $dstdir =~ s/\/\//\//g;
               $dstdir =~ s/\\\\/\\/g;
               $ipssrcdir = $srcdir;
               print $fh "$debugtime name $filesdet[MFILE_NAME] $filesdet[MLOCATION] $filesdet[MADR_HOME] \n" if $debugips ;
               eval {
                 mkpath( $dstdir ) if ( ! -d $dstdir );
                 if ( not $IS_WINDOWS ) {
                   host("$CP $srcfile $dstfile") if not -e $dstfile;
                 } else {
                   host("$CP \"$srcfile\" \"$dstfile\"");
                 }
                 print $fh "$debugtime $CP $srcfile $dstfile\n" if $debugips;
               };
               if ( $@ ) {
                 print "Error while creating  $TFAIPS_TARGETHOMEPATH.\n";
                 print $fh "$debugtime Error while creating $TFAIPS_TARGETHOMEPATH.\n" if $debugips;
                 print "$@\n";
                 exit 1;
               }
             } # end for $#retfiles
             # -------------- process files --------------------- end
             my $srcalertxml;
             my $srcalert;
             my $dstdiralertxml = catfile($ips_base,"alert");
             my $dstdiralert    = catfile($ips_base,"trace");
             my $dstalertxml = catfile($dstdiralertxml,"log.xml");
             my $dstalert;
             my $auxreldiagpath = $mapped_adrhomepath; # $reldiagpath;
             my $auxins;
             $auxreldiagpath =~ s/\+/\\\+/g;
             if ( $ipssrcdir =~ /(.*[\/\\]$auxreldiagpath)[\/\\].*/ ) {
               $ipssrcdir = $1;
               $srcalertxml = catfile($ipssrcdir,"alert","log.xml");
             }
             # $reldiagpath
             if ( $mapped_adrhomepath =~ /.*[\/\\](.*)$/ ) {
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

             unlink( catfile("/","pkg_manifest_$ipspkgnmbr\.xml") ) 
             if -e catfile("/","pkg_manifest_$ipspkgnmbr\.xml");
             unlink( catfile("/","remote_key_$ipspkgnmbr\.xml") )
             if -e catfile("/","pkg_manifest_$ipspkgnmbr\.xml");

             if ( -e catfile("$ips_base","remkeyfile.xml") ) {
               unlink( catfile("$ips_base","remkeyfile.xml") ) if ! $debugips;
               print $fh "$debugtime unlinked " . catfile("$ips_base","remkeyfile.xml")  . " \n" if $debugips ;
             }
             unlink( catfile("$ips_base","manifest.xml") )
             if (-e catfile("$ips_base","manifest.xml") && ( ! $debugips) );
             
             # su section
             if ( $current_user eq "root" && not $IS_WINDOWS ) {
               # Get osowner
               my $osowner = getFileOwner(catfile($TFAIPS_ADRBASE,$TFAIPS_ADRCIHOMEPATH));
               `$CHOWN -R $osowner $ips_base`;
               my $pgroup = getgrgid $(;
               `$CHGRP -R $pgroup $ips_base`;
             } else {
               host("$CHMOD -R 700 " . catfile($ips_base,"incpkg","pkg_$ipspkgnmbr")) if not $IS_WINDOWS;
             }

             if ( not $IS_WINDOWS ) {
               host("$FIND " . catfile($ips_base,"pkg_$ipspkgnmbr") . " -exec $TOUCH -d $starttimeips {} \\\;") if
               defined $starttimeips && length $starttimeips;
             }
           }
         }
      } # end foreach
    }
    print $ipsout;
    } elsif ( defined $tfactlglobal_argv[0] && $tfactlglobal_argv[0] eq "dummy" ) {
      $ipsout = $mapped_adrhomepath;
      print $ipsout;
    } 
    ###
    if ( $debugips ) {
      print $fh "$debugtime ipsout $ipsout\n";
      print $fh "-------------------------  Finish $ipscmd -----------------------\n\n\n";
      close $fh;
    }
    return;

  } elsif ( $switch_val eq "sslrestart" ) {
          if ( ! $IS_TFA_ADMIN ) {
            print "\nAccess Denied: Only TFA Admin can run this command\n\n";
            exit 1;
          }
	  $SSLRESTART = 1;
  } elsif ( $switch_val eq "start"   || $switch_val eq "stop" ||
       $switch_val eq "restart" || $switch_val eq "deploy" || 
       $switch_val eq "status" ) 
        {    
          if ( ! $IS_TFA_ADMIN && ! $command2 ) {
            if ( $switch_val ne "status" ) {
              print "\nAccess Denied: Only TFA Admin can run this command\n\n";
              exit 1;
            }
          }
          tfactlshare_trace(5, "tfactl (PID = $$) tfactladmin_process_command " .
                          "Requested action $command1", 'y', 'y');

          if ( $switch_val eq "status" ) {
              if ( $switch_val eq "status" && defined $command2 ) {
                print_help("status");     
                return;
              } else {
                # handle  status 
                unshift @tfactlglobal_argv, "print";
                $tfactlglobal_hash{'cmd'} = "print";
             }
          } elsif (defined $command2) {
            tfactlshare_trace(5, "tfactl (PID = $$) tfactladmin_process_command " .
                          "Verifying the existence of tool $command2", 'y', 'y');
            if ( exists $tfactlglobal_exttools{$command2}  ) {
              tfactlshare_trace(5, "tfactl (PID = $$) tfactladmin_process_command " .
                          "Processing command $command1 for tool $command2",
                          'y', 'y');
              tfactlshare_trace(5, "tfactl (PID = $$) tfactladmin_process_command " .
                          "Tool version = $tfactlglobal_exttools{$command2}->{VERSION}", 
                          'y', 'y');
              tfactlshare_trace(5, "tfactl (PID = $$) tfactladmin_process_command " .
                  "Tool clusterwide = $tfactlglobal_exttools{$command2}->{CLUSTERWIDE}",
                          'y', 'y');
              tfactlshare_trace(5, "tfactl (PID = $$) tfactladmin_process_command " .
                      "Tool autostart = $tfactlglobal_exttools{$command2}->{AUTOSTART}",
                          'y', 'y');
              $tfactlglobal_hash{'srcmod'} = "tfactladmin"; # src mod
              $tfactlglobal_hash{'cmd'} = $command2; # toolname
              if ( $clustercommand eq "local" ) {
                shift @tfactlglobal_argv;
              };
              $tfactlglobal_argv[0] = $command2;
              $tfactlglobal_argv[1] = $command1;
              # Execute command clusterwide
              if ( $clustercommand eq "true-disable" && 
                   $tfactlglobal_exttools{$command2}->{CLUSTERWIDE} eq "true-disable" ) {
                tfactlshare_execute_clusterwide("local $command1 $command2", "@ARGV" );
             } # end if clusterwide tools

            } else {
              if ($switch_val eq "start") {
                print_help("start");
                return;
              }
              if ($switch_val eq "stop") {
                print_help("stop");
                return;
              }
              if ($switch_val eq "restart") {
                print_help("restart");
                return;
              }
              if ($switch_val eq "deploy") {
                print_help("deploy");
                return;
              }
            } # end if exists $tfactlglobal_exttools{$command2}
          }
          else {
            $START = 1 if $switch_val eq "start"; 
            $STOP = 1 if $switch_val eq "stop";
            if ($switch_val eq "restart") {
              if (isTFARunning($tfa_home) == FAILED) {
                startTFA($tfa_home,$paramfile); $START=0;
              }
              else {
                stopTFA($tfa_home); $STOP=0;
                startTFA($tfa_home,$paramfile); $START=0;
              }
            }
            if ($switch_val eq "deploy") {
              print_help("deploy");
              return;
            }
          }
        }
  elsif ( $switch_val eq "deployext" ) {
          if ( defined $command2 && ( $command2 eq "-h" ||
               $command2 eq "-help") ) {
            print_help("deployext");
            return;
          }
          if ( $clustercommand eq "local" ) {
            shift @tfactlglobal_argv;
          };
          $tfactlglobal_hash{'srcmod'} = "tfactladmin"; # src mod
          $tfactlglobal_hash{'cmd'} = $switch_val;
          }
  elsif ( $switch_val eq "toolstatus" ) {
          if ( defined $command2 && ( $command2 eq "-h" ||
               $command2 eq "-help" || $command2 ne "") ) {
            print_help("toolstatus");
            return;
          } else 
          {
            my %ext_tools_category;
            my $tooltype;
            foreach my $tool (keys %tfactlglobal_exttools){
              # Check is this Exadata Server
              my $cellloc = "/etc/oracle/cell/network-config/cellip.ora";
              next if(($tool eq "exachk") and (!-e $cellloc));
              next if(($tool eq "orachk") and (-e $cellloc));

              # Collect Tool Type                
              $tooltype = $tfactlglobal_exttools{$tool}{TOOLTYPE};
              push( @ { $ext_tools_category{$tooltype}},$tool);
            }

            # Print Table for Eatch Tool Type
            my $tb = Text::ASCIITable->new();
            $tb->setCols("Tool Type", "Tool", "Version", "Status");
            $tb->setOptions({"outputWidth" => $tputcols,
                             "headingText" => "TOOLS STATUS - HOST : ".tolower_host()});

            foreach my $tool_type ( sort keys %ext_tools_category){
              my $tool_name = join '', map { ucfirst lc } split /(\s+)/, $tool_type;
              $tool_name =~ s/Tfa/TFA/g;
              my @ext_tools = @{$ext_tools_category{$tool_type}};
              foreach my $tool (sort @ext_tools) {
                next if $tool eq "dbperf";
                my $toollabel = $tool;
                my $runstatus = tfactlshare_manage_ext("runstatus",$tool, $tfa_home);
                my $toolversion = $tfactlglobal_exttools{$tool}{VERSION};
                my $statusmsg = "";

                if ( $tfactlglobal_exttools{$tool}{ALIASES} && $IS_WINDOWS ) {
                  $toollabel = trim($tfactlglobal_exttools{$tool}{ALIASES});
                }

                if ( $runstatus == TOOLNOTRUNNING ) {
                  $statusmsg = "NOT RUNNING";
                } elsif ( $runstatus == TOOLRUNNING ) {
                  $statusmsg = "RUNNING";
                } elsif ( $runstatus == TOOLSTOPPED ) {
                  $statusmsg = "STOPPED";
                } elsif ( $runstatus == TOOLDISABLED ) {
                  $statusmsg = "DISABLED";
                } elsif ( $runstatus == TOOLNOTAVAILABLE ) {
                	$statusmsg = "NOTAVAILABLE";
                }

                $statusmsg = "DEPLOYED" unless ( $runstatus != TOOLNOTDAEMON );
                if ( $statusmsg ne "NOTAVAILABLE" ) {
                	$tb->addRow($tool_name, $toollabel, $toolversion, $statusmsg);
                }
                $tool_name = '';
              } # end for ext_tools 
              $tb->addRowLine() 
             
              # Execute clusterwide
              #if ( $clustercommand eq "true" ) {
              #  tfactlshare_execute_clusterwide("local toolstatus", "" );
              #} # end if execute clusterwide
            } # end of tool type 
            print "\n",$tb,"\n";
            print "Note :-\n";
            print "  DEPLOYED    : Installed and Available - To be configured or run interactively.\n";
            print "  NOT RUNNING : Configured and Available - Currently turned off interactively.\n";
            print "  RUNNING     : Configured and Available.\n\n";
          }
        }
  elsif ( $switch_val eq "startall" || $switch_val eq "stopall" ) {

          foreach my $tool (keys %tfactlglobal_exttools)
          {
             my $runstatus = tfactlshare_manage_ext("runstatus",$tool);
             my $autostart = $tfactlglobal_exttools{$tool}->{AUTOSTART};

             tfactlshare_trace(5, "tfactl (PID = $$) tfactladmin_process_command " .
                    "Command $switch_val runstatus $runstatus", 'y', 'y');

             if ( $switch_val eq "startall" && $autostart eq "true" &&
                  $runstatus == TOOLNOTRUNNING ) {
               tfactlshare_manage_ext("start",$tool);
             } elsif ( $switch_val eq "stopall" && 
                       $runstatus == TOOLRUNNING ) {
               tfactlshare_manage_ext("stop",$tool);
            }
          } # end for %tfactlglobal_exttools

          # Execute clusterwide
          if ( $clustercommand eq "true-disable" ) {
            tfactlshare_execute_clusterwide("local $switch_val", "" );
          } # end if execute clusterwide 
          }
  elsif ( $clustercommand eq "local" && $switch_val ne "run" &&
          $switch_val ne "start" && $switch_val ne "stop" &&
          $switch_val ne "restart" && $switch_val ne "deploy" &&
          $switch_val ne "status" ) {
          print_help("main");
          return;
          }
  elsif ( $clustercommand eq "local" && $switch_val eq "run" ) {
            $tfactlglobal_hash{'srcmod'} = "tfactladmin"; # src mod
            $tfactlglobal_hash{'cmd'} = $command2; # toolname
            shift @tfactlglobal_argv; # remove local
            $tfactlglobal_argv[0] = $command2;
            $tfactlglobal_argv[1] = $command1;
        }
  elsif ($switch_val eq "shutdown")
        {
          if ( ! $IS_TFA_ADMIN ) {
                  print "\nAccess Denied: Only TFA Admin can run this command\n\n";
                  exit 1;
          }

          if (defined $command2) {
                print_help("shutdown");
                return;
          }
          else  {
                $SHUTDOWN = 1;
          }
        }
  elsif ($switch_val eq "disable")
        {
          if ( ! $IS_TFA_ADMIN ) {
                  print "\nAccess Denied: Only TFA Admin can run this command\n\n";
                  exit 1;
          }

          if (defined $command2) {
                print_help("disable");
                return;
          }
          else  {
                $DISABLE = 1;
          }
        }
  elsif ($switch_val eq "enable" )
        {
          if ( ! $IS_TFA_ADMIN ) {
                  print "\nAccess Denied: Only TFA Admin can run this command\n\n";
                  exit 1;
          }

          if (defined $command2) {
                print_help("enable");
                return;
          }
          else  {
                $ENABLE = 1;
          }
        }
  elsif ($switch_val eq "initstart" )
        {
            $STARTFROMINIT = 1;
        }
  elsif ($switch_val eq "initstop" )
        {
             $STOPFROMINIT = 1;
        }
  elsif ($switch_val eq "rest" )
        {
            if ( $current_user ne "root" ) {
		print "\nAccess Denied: Only TFA Admin can run this command\n\n";
		exit 1;
            }
	    $rest = "$command2 @ARGV";
        }
  elsif ($switch_val eq "stopords" )
        {
            if ( $current_user ne "root" ) {
		print "\nAccess Denied: Only TFA Admin can run this command\n\n";
		exit 1;
            }
            $stopords = 1;
        }
  elsif ($switch_val eq "startorachkdaemon" )
        {
            if ( $current_user ne "root" ) {
		print "\nAccess Denied: Only TFA Admin can run this command\n\n";
		exit 1;
            }
            $startorachkdaemon = 1;
        }
  elsif ($switch_val eq "stoporachkdaemon" )
        {
            if ( ! $IS_TFA_ADMIN ) {
		print "\nAccess Denied: Only TFA Admin can run this command\n\n";
		exit 1;
            }
            $stoporachkdaemon = 1;
        }
  elsif ($switch_val eq "executecommand" )
        {
          if ( ! $IS_TFA_ADMIN ) {
                  print "\nAccess Denied: Only TFA Admin can run this command\n\n";
                  exit 1;
          }

          $EXECUTEINHOST = $command2;

          for (my $c=0; $c<scalar(@ARGV); $c++) {
            my $arg = @ARGV[$c];
            $arg = trim($arg);
            $COMMANDTOEXECUTE .= " $arg";
          }
          @ARGV = ();
        }
  elsif ($switch_val eq "executecommandprint" )
        {
          if ( ! $IS_TFA_ADMIN && $ARGV[0] ne "tfactlruntool" && $ARGV[0] ne "tfactlips" ) {
                  print "\nAccess Denied: Only TFA Admin can run this command\n\n";
                  exit 1;
          }
          $EXECUTEINHOST_PRINT = $command2;
          $PROGRAM_PRINT = $ARGV[0];
          for (my $c=1; $c<scalar(@ARGV); $c++) {
            my $arg = @ARGV[$c];
            $arg = trim($arg);
            $COMMANDTOEXECUTE_PRINT .= " $arg";
          }
          @ARGV = ();
          tfactlshare_trace(5, "tfactl (PID = $$) tfactladmin_process_command " .
                    "Catching executecommandprint", 'y', 'y');
          tfactlshare_trace(5, "tfactl (PID = $$) tfactladmin_process_command " .
                    "EXECUTEINHOST_PRINT $EXECUTEINHOST_PRINT", 'y', 'y');
          tfactlshare_trace(5, "tfactl (PID = $$) tfactladmin_process_command " .
                    "PROGRAM_PRINT $PROGRAM_PRINT", 'y', 'y');
          tfactlshare_trace(5, "tfactl (PID = $$) tfactladmin_process_command " .
                    "COMMANDTOEXECUTE_PRINT $COMMANDTOEXECUTE_PRINT", 'y', 'y');

        }
  # Deprecated $switch_val eq "status"  moved to tfactlbase.pm
  # $switch_val eq "access" moved to tfactlaccess.pm
  elsif ($switch_val eq "createtntprop" )
        {
          $TNTPROP = 1;
          my $tz = shift;
          $INVFILE = "$command2:$tz";
        }
  elsif ($switch_val eq "checkautopatching" )
        {
                $CHECKAUTOPATCHING = 1;
        }
  elsif ($switch_val eq "checkkeystores" )
        {
                $CHECKKEYSTORES = 1;
        }
  elsif ($switch_val eq "clean" )
        { $CLEAN = 1 }
  elsif ($switch_val eq "deletedb" )
        {
          if (defined $command2 && ($command2 eq "-h" || $command2 eq "-help")) {
                print_help("deletedb");
                return;
          }
          else {
                 $DELETEDB = 1;
          }
        }
  elsif ($switch_val eq "gui" )
        { $MANAGER = 1 }
  elsif ($switch_val eq "generatecookie" )
        { $GENERATECOOKIE = 1 }
  elsif ($switch_val eq "generatecerts" )
        { $GENCERTS = 1;
          $TEMP_TFAHOME = $command2;
          my $command3 = shift(@ARGV);
          $TFA_JHOME = $command3;
	  my $command4 = shift(@ARGV);
	  if ( $command4 eq "receiver" ) {
	    $GENCERTS = 2;
	  }
          $SSLKEY = $command4; 
	}
  elsif ($switch_val eq "sslrestart" ) {
		
          	if ( ! $IS_TFA_ADMIN ) {
                        print "\nAccess Denied: Only TFA Admin can run this command\n\n";
                        exit 1;
                }
		$SSLRESTART = 1;
	}
  elsif ($switch_val eq "setsslkey" )
	{ #$SSLKEY = 1; 
	}
  elsif ($switch_val eq "generatefilelist" )
        { $FILELISTDIRECTORY = $command2;
	  my $command3 = shift(@ARGV);
          $FILELISTLASTINV = $command3; }
  elsif ($switch_val eq "uninstall" )
        {
          	if ( ! $IS_TFA_ADMIN ) {
                        print "\nAccess Denied: Only TFA Admin can run this command\n\n";
                        exit 1;
                }

                if (defined $command2 && ($command2 eq "-h" || $command2 eq "-help")) {
                        print_help ("uninstall", "");
			return;
                }

                $UNINSTALL = 1;
                $UNINSTALLARGS = $command2;
        }
  elsif ($switch_val eq "diagnosetfa" )
	{
	  if ( ! $ISCLOUD ) {
            if ( ! $IS_TFA_ADMIN ) {
              print "\nAccess Denied: Only TFA Admin can run this command\n\n";
              exit 1;
            }
	  }
	  $DIAGNOSETFA = 1;
	  $DIAGNOSEARGS = "$command2 @ARGV";
	}
  elsif ($switch_val eq "syncnodes" )
	{
		if ( ! $IS_TFA_ADMIN ) {
			print "\nAccess Denied: Only TFA Admin can run this command\n\n";
			exit 1;
                }
		$SYNCTFANODES = "$command2 @ARGV";
	}
  elsif ($switch_val eq "syncpatch" )
	{
		if ( $current_user ne "root" ) {
			print "\nAccess Denied: Only TFA Admin can run this command\n\n";
			exit 1;
		}
		$syncpatch = 1;
	}
  elsif ($switch_val eq "configfromresp" )
	{
		if ( $current_user ne "root" ) {
			print "\nAccess Denied: Only TFA Admin can run this command\n\n";
			exit 1;
		}
		$configfromresp = 1;
                $rspfile = $command2;
	}
  elsif ($switch_val eq "sendmail" )
	{
		$to = $command2;
		$SENDMAIL = 1;
	}
  elsif ($switch_val eq "set" )
        {
          my $invalidsetcmd = FALSE;
	  if ( ! $IS_TFA_ADMIN && $command2 !~ /^(blackout|blackout.timeout|redact)/) {
		if ( ! isTFAOnCloud($tfa_home) ) {
			print "\nAccess Denied: Only TFA Admin can run this command\n\n";
                  	exit 1;
		}
          }

          tfactlshare_trace(5, "tfactl (PID = $$) tfactladmin_process_command " .
                            "Processing set command, command2 $command2", 'y', 'y');

          if ( ! $command2 ) {
            print_help ("set", "");
            return;
          }

          if (defined $command2 && ($command2 eq "-h" || $command2 eq "-help")) {
                print_help("set");
                return;
          }
           
          if ($command2 =~ /^jvmflags$/) {
               	my $command3 = shift(@ARGV);
                if(defined $command3) {
                	$RESTARTTFA=1;
                	$CLUSTERWIDE=1; 
               		if(($command3 =~ /^jvmXmxMB=/) or ($command3 =~ /^jvmLineOther=/))
                	{
                		if ($command3 =~ /^jvmXmxMB=/) {
                        		$command3 =~ s/^jvmXmxMB=//;
                       			$CHANGEJVMMEMSIZE= $command3;
                		} 
                		if ($command3 =~ /^jvmLineOther=/) {
                        		$command3 =~ s/^jvmLineOther=//;
                        		$CHANGEJVMOTHER= $command3;
                		} 
             		} else {
                       		$invalidsetcmd = TRUE;
                	}
		} else {
			$invalidsetcmd = TRUE;   
		}
               	my $command4 = shift(@ARGV);
                if(defined $command4) {
                	if(($command4 =~ /^jvmXmxMB=/) or 
                	   ($command4 =~ /^jvmLineOther=/) or 
                	   ($command4 eq "-c") or 
                	   ($command4 eq "-norestarttfa") or 
         		   ($command4 eq "-local")) { 
                	        if ($command4 =~ /^jvmXmxMB/) {
                        		$command4 =~ s/^jvmXmxMB=//;
                       			$CHANGEJVMMEMSIZE= $command4;
                		} 
                		if ($command4 =~ /^jvmLineOther/) {
                        		$command4 =~ s/^jvmLineOther=//;
                        		$CHANGEJVMOTHER= $command4;
                		}	 
                        	if($command4 eq "-local"){
                          		$CLUSTERWIDE=0;
                        	} 
                        	if($command4 eq "-norestarttfa"){
                        		$RESTARTTFA=0;
                        	}
            	 	} else {
                	       $invalidsetcmd = TRUE;
               		}
                }

                my $command5 = shift(@ARGV);
                if(defined $command5) {
                        if(($command5 eq "-c") or
                           ($command5 eq "-norestarttfa") or
                           ($command5 eq "-local")) { 
                                if($command5 eq "-local"){
                                        $CLUSTERWIDE=0;
                                }
                                if($command5 eq "-norestarttfa"){
                                        $RESTARTTFA=0;
                                }
                        } else {
                               $invalidsetcmd = TRUE;
                        }
                }
                my $command6 = shift(@ARGV);
                if(defined $command6) {
                        if($command6 eq "-norestarttfa") {
                        	$RESTARTTFA=0;
                        } else {
                        	$invalidsetcmd = TRUE;
                        }
                }
                if($RESTARTTFA == 1){
 			print "\nSetting Following JVMFLAGS and Restarting TFA Daemon ";
                	if($CLUSTERWIDE == 1){
				print "Clusterwide\n";
			} else {
				print "On Local Node\n";
			}
 			print "  jvmXmxMB     : -Xmx${CHANGEJVMMEMSIZE}m\n" if($CHANGEJVMMEMSIZE);
                        if(defined $CHANGEJVMOTHER){
                                print "  jvmLineOther : ";
				my @jvm_other_parameters = split(/\s+/,$CHANGEJVMOTHER);
				foreach my $jvm_other_parameter(@jvm_other_parameters){
					if($jvm_other_parameter =~ m/^-XX:\+UseGCLogFileRotation$/ or 
					   $jvm_other_parameter =~ m/^-XX:NumberOfGCLogFiles=.+$/ or 
					   $jvm_other_parameter =~ m/^-XX:GCLogFileSize=.+$/ or 
                                           $jvm_other_parameter =~ m/^-XX:ParallelGCThreads=.+$/ ) {
						print "$jvm_other_parameter ";
					} else {
						print "\n\n[ERROR] JVM FLAG '$jvm_other_parameter' Not Supported\n";
						$invalidsetcmd = TRUE;
					}
				}
				print "\n";
			}
         	}
 	  }
          elsif ($command2 =~ /^reposizeMB/) {
                $command2 =~ s/^reposizeMB=//;
                $CHANGEREPOSIZE= $command2;
                my $command3 = shift(@ARGV);
                if (defined $command3) {
			if ($command3 =~ /^repositorydir/) {
                        	$command3 =~ s/^repositorydir=//;
                        	$CHANGEREPO=$command3;
			} elsif ( $command3 =~ /^-force/) {
				$FORCE = $command3;
			} else {
                                $invalidsetcmd = TRUE;
                        }
                }

		my $command4 = shift(@ARGV);
		if (defined $command4) {
                        if ($command4 =~ /^-force/) {
		    		$FORCE = $command4;
			} else {
                        	$invalidsetcmd = TRUE;
			}
                }
          }
          elsif ($command2 =~ /^repositorydir/) {
                $command2 =~ s/^repositorydir=//;
                $CHANGEREPO=$command2;
                my $command3 = shift(@ARGV);
                if (defined $command3) {
			if ($command3 =~ /^reposizeMB/) {
                        	$command3 =~ s/^reposizeMB=//;
                        	$CHANGEREPOSIZE=$command3;
			} elsif ( $command3 =~ /^-force/) {
				$FORCE = $command3;
			} else {
				$invalidsetcmd = TRUE;
			}
                }

		my $command4 = shift(@ARGV);
		if (defined $command4) {
			if ($command4 =~ /^-force/) {
				$FORCE = $command4;
			} else {
				$invalidsetcmd = TRUE;
			}
		}
          }

	  if ( $command2 eq "smtp") {
		$smtp = 1;
	  }

	  if ( $command2 =~ /^port=/ ) {
		$command2 =~ s/^port=//;
		$port = $command2;

		my $command3 = shift(@ARGV);
		if ( defined $command3 ) {
          		if ($command2 eq "-h" || $command2 eq "-help") {
				print_help ("set");
			} else {
				print_help ("set", "Invalid option $command3");
			}
			return;
		}

		if ( $port ) {
			my @ports = split(/,/, $port);
			my $p;
			foreach $p (@ports) {
				if ( $p =~ /\D+/ ) {
					print "Invalid Port number specified $p.\n";
					return;
				}
			}
		} else {
			print "Please enter valid port number.\n";
			return;
		}
	  }

	  if ( $command2 =~ /^tfa_base=/ ) {
		$command2 =~ s/^tfa_base=//;
		$tfa_base = $command2;

		my $islocal = shift(@ARGV);

		if ( $islocal =~ /-local/ ) {
			$onlylocal = 1;
		}
	  }

	  if ( $command2 =~ /^java_home=/ ) {
		$command2 =~ s/^java_home=//;
		$java_home = $command2;

		my $islocal = shift(@ARGV);

		if ( $islocal =~ /-local/ ) {
			$onlylocal = 1;
		}
	  }

	  if ( $command2 =~ /^threaddumpinterval=/ ) {
		$command2 =~ s/^threaddumpinterval=//;
		$tdinterval = $command2;

		my $islocal = shift(@ARGV);

		if ( $islocal =~ /-local/ ) {
			$onlylocal = 1;
		}
	  }

	  if ( $command2 =~ /^threaddumpfrequency=/ ) {
		$command2 =~ s/^threaddumpfrequency=//;
		$tdfrequency = $command2;

		my $islocal = shift(@ARGV);

		if ( $islocal =~ /-local/ ) {
			$onlylocal = 1;
		}
	  }

          if ( $command2 =~ /^logsize/ ) {
                $command2 =~ s/^logsize=//;
                $MAXLOGSIZE = trim ($command2);

                # Check if contains anything other than numbers
                if ( $MAXLOGSIZE =~ /\D[\D]?/ ) {
                        print_help("set","Enter a valid number for max log size");
			return;
                }

                # check the mimimum and maximum size values [ 10 MB and 500 MB ]
                if ( $MAXLOGSIZE < 10 ) {
                        print_help("set","Log size must be more than minimum value [10 MB]");
			return;
                }

                if ( $MAXLOGSIZE > 500 ) {
                        print_help("set","Log size must be less than maximum value [500 MB]");
                        return;
                }

                # Check local or clusterwide
                my $islocal = shift(@ARGV);

		if ( defined $islocal) {
                	if ( $islocal eq "-local" ) {
                        	$ACCESSLOCAL = "-l";
	                }
		}

                if ( $islocal && $islocal ne "-local" && $islocal ne "-c" ) {
                        print_help("set", "Invalid flag $islocal passed\n");
			return;
                }
          } # end if $command2 =~ /^logsize/

          if ( $command2 =~ /^logcount/ ) {
                $command2 =~ s/^logcount=//;
                $MAXLOGCOUNT = $command2;

                # Check if contains anything other than numbers
                if ( $MAXLOGCOUNT =~ /\D[\D]?/ ) {
                        print_help("set","Enter a valid number for max number of TFA Logs");
			return;
                }

                # Check minimum and maximum values [ 5 and 10 ]
                if ( $MAXLOGCOUNT < 5 ) {
                        print_help("set","Max TFA Log count must be more than minimum value [5]");
			return;
                }

                if ( $MAXLOGCOUNT > 50 ) {
                        print_help("set","Max TFA Log count must be less than maximum value [50]");
			return;
                }

                # Check local or clusterwide
                my $islocal = shift(@ARGV);

                if ( $islocal eq "-local" ) {
                        $ACCESSLOCAL = "-l";
                }

                if ( $islocal && $islocal ne "-local" && $islocal ne "-c" ) {
                        print_help("set", "Invalid flag $islocal passed\n");
			return;
                }
          }

          if ( $command2 =~ /^maxcorefilesize/ ) {
                $command2 =~ s/^maxcorefilesize=//;
                $maxCoreFileSize = $command2;

                # Check if contains anything other than numbers
                if ( $maxCoreFileSize =~ /\D[\D]?/ ) {
                        print_help("set","Enter a valid number for max size for a Core File");
			return;
                }

                # Check minimum and maximum values [ 0 and 50 ]
                if ( $maxCoreFileSize < 0 ) {
                        print_help("set","Max Core file size must be more than minimum value [0 MB]");
			return;
                }


                # Check local or clusterwide
                my $islocal = shift(@ARGV);

                if ( $islocal eq "-local" ) {
                        $ACCESSLOCAL = "-l";
                }

                if ( $islocal && $islocal ne "-local" && $islocal ne "-c" ) {
                        print_help("set", "Invalid flag $islocal passed\n");
			return;
                }
          }

          if ( $command2 =~ /^maxcorecollectionsize/ ) {
                $command2 =~ s/^maxcorecollectionsize=//;
                $maxCoreCollectionSize = $command2;

                # Check if contains anything other than numbers
                if ( $maxCoreCollectionSize =~ /\D[\D]?/ ) {
                        print_help("set","Enter a valid number for max collection size of Core Files");
			return;
                }

                # Check minimum and maximum values [ 0 and 200 ]
                if ( $maxCoreCollectionSize < 0 ) {
                        print_help("set","Max collection size of Core Files must be more than minimum value [0 MB]");
			return;
                }


                # Check local or clusterwide
                my $islocal = shift(@ARGV);

                if ( $islocal eq "-local" ) {
                        $ACCESSLOCAL = "-l";
                }

                if ( $islocal && $islocal ne "-local" && $islocal ne "-c" ) {
                        print_help("set", "Invalid flag $islocal passed\n");
			return;
                }
          }

  	  if ($command2 =~ /blackout=/) {
	    for (my $i=0;$i<=$#ARGV;++$i) {
              if ($ARGV[$i] eq "-c") {
                $CLUSTERWIDE=1;
                splice @ARGV,$i,1; $i--;
              }
	      elsif ($ARGV[$i] eq "-target") {
	        #target can be db,gi etc
	        $SET_CMD_ARGS .= "_TFAARGSEP_target=$ARGV[$i+1]";
	        splice @ARGV,$i,2; $i--;
	      }  
              elsif ($ARGV[$i] eq "-timeout") {
                $SET_CMD_ARGS .= "_TFAARGSEP_timeout=$ARGV[$i+1]";
                splice @ARGV,$i,2; $i--;
              }
              elsif ($ARGV[$i] eq "-reason") {
                $SET_CMD_ARGS .= "_TFAARGSEP_reason=$ARGV[$i+1]";
                splice @ARGV,$i,2; $i--;
              }
            }
  	  }
	  
          if (defined $CHANGEREPOSIZE) {
                if ($CHANGEREPOSIZE =~ /\D[\D]?/) {
                  print_help("set","Enter a valid number for repository size");
		  return;
                }
          }
          if ( (defined $CHANGEJVMOTHER ||defined $CHANGEJVMMEMSIZE || defined $CHANGEREPO || defined $CHANGEREPOSIZE || defined $MAXLOGSIZE || defined $MAXLOGCOUNT  || defined $maxCoreFileSize || defined $maxCoreCollectionSize || defined($port) || defined($tfa_base) || defined($java_home) || defined($tdinterval) || defined($tdfrequency) || $smtp ) ) {
          tfactlshare_trace(5, "tfactl (PID = $$) tfactladmin_process_command " .
                            "Matched any of: CHANGEREPO, CHANGEREPOSIZE, MAXLOGSIZE, MAXLOGCOUNT, CHANGEJVMMEMSIZE, CHANGEJVMOTHER " .
                            "maxCoreFileSize, maxCoreCollectionSize, tfa_base, java_home, tdinterval, tdfrequency, jvmXmxMB , jvmLineOther", 'y', 'y');
          }
          else {
          my $command3 = shift(@ARGV);
          if ($command3) {
            if($command3 eq "-c"){
              $CLUSTERWIDE=1;
            }else{
              print_help ("set", "Invalid option $command3");
              return;
            }
          }

          tfactlshare_trace(5, "tfactl (PID = $$) tfactladmin_process_command " .
                            "Processing other commands. command2 $command2, command3 $command3", 'y', 'y');
          if ( $command2 && ($command2 =~ /rtscan=/ ||
                             $command2 =~ /diskUsageMon=/ ||
                             $command2 =~ /manageLogsAutoPurge=/ ||
                             $command2 =~ /bugsftpurl=/ ||
                             $command2 =~ /firediagcollect=/ ||
                             $command2 =~ /firediagcollectOD=/ ||
                             $command2 =~ /firediagcollectRT=/ ||
                             $command2 =~ /autodiagcollect=/ ||
                             $command2 =~ /autopurge=/ ||
                             $command2 =~ /minagetopurge=/ ||
                             $command2 =~ /internalSearchString=/ ||
                             $command2 =~ /ignoreEventsInADE=/ ||
                             $command2 =~ /notificationAddress=/ ||
                             $command2 =~ /chanotification=/ ||
                             $command2 =~ /chaautocollect=/ ||
                             $command2 =~ /trimfiles=/ ||
                             $command2 =~ /tracelevel=/ ||
                             $command2 =~ /trimsize=/ ||
                             $command2 =~ /collectionPeriod=/ ||
                             $command2 =~ /fileCountInventorySwitch=/ ||
                             $command2 =~ /inventoryThreadPoolSize=/ ||
                             $command2 =~ /collectAllDirsByFile=/ ||
                             $command2 =~ /cookie=/ ||
                             $command2 =~ /minSpaceForRTScan=/ ||
                             $command2 =~ /diskUsageMonInterval=/ ||
                             $command2 =~ /manageLogsAutoPurgeInterval=/ ||
                             $command2 =~ /manageLogsAutoPurgePolicyAge=/ ||
                             $command2 =~ /minTimeForAutoDiagCollection=/ ||
                             $command2 =~ /odscan=/ ||
                             $command2 =~ /walletpassword=/ ||
                             $command2 =~ /buildversion/ ||
                             $command2 =~ /secureadd=/ ||
                             $command2 =~ /language=/ ||
                             $command2 =~ /encoding=/ ||
                             $command2 =~ /country=/  ||
                             $command2 =~ /debugips=/ ||
                             $command2 =~ /tfaIpsPoolSize=/ ||
                             $command2 =~ /tfaDbUtlPurgeAge=/ ||
                             $command2 =~ /tfaDbUtlPurgeMode=/ ||
                             $command2 =~ /sslconfig/ ||
                             $command2 =~ /AlertLogLevel=/ ||
                             $command2 =~ /UserLogLevel=/  ||
                             $command2 =~ /publicip=/  ||
                             $command2 =~ /ciphersuite=/ ||
                             $command2 =~ /BaseLogPath/ ||
                             $command2 =~ /blackout=/ ||
                             $command2 =~ /blackout.timeout=/ ||
                             $command2 =~ /tfaweb\.env=/ ||
                             $command2 =~ /tfaweb\.url=/ ||
                             $command2 =~ /oss\.url=/ ||
                             $command2 =~ /oss\.type=/ ||
                             $command2 =~ /oss\.user=/ ||
                             $command2 =~ /oss\.password=/ ||
                             $command2 =~ /oss\.proxy=/ ||
                             $command2 =~ /wallet\.location=/ ||
                             $command2 =~ /logstash\.host=/ ||
                             $command2 =~ /logstash\.port=/ ||
                             $command2 =~ /redact=/)
             )
          {
            $SET_FLAG = "$command2";
            tfactlshare_trace(5, "tfactl (PID = $$) tfactladmin_process_command " .
                              "SET_FLAG $SET_FLAG", 'y', 'y');
          }
          elsif ( $command2 && ( $command2 =~ /r\.repository=/ || $command2 =~ /r\.port=/ ||
				 $command2 =~ /r\.send\.collections/ ) ) {
	    #R parameters. By defalut set r params clusterwide
	    if ( $command2 && ! $command3 ) {
	      $CLUSTERWIDE = 1;
            }
	    $SET_FLAG = "$command2";
          }
           else
          {
            print_help ("set", "Invalid option $command2") if defined($command2) && ($command2 ne "-h") && ($command2 ne "-help");
            return FAILED;
          }
          }
          # Validate set command
          ###print "Remaining argv @ARGV \n";
          if ( @ARGV || $invalidsetcmd ) {
            print_help("set");
            return FAILED; 
          }
        }
  elsif ($switch_val eq "host" )
        {
	  if ( ! $IS_TFA_ADMIN ) {
                  print "\nAccess Denied: Only TFA Admin can run this command\n\n";
                  exit 1;
          }

          if ( ! $command2 ) {
            print_help ("host", "");
            return FAILED;
          }

          if (defined $command2 && ($command2 eq "-h" || $command2 eq "-help")) {
            print_help("host");
            return SUCCESS;
          }
          #In R-Mode both should be receivers .. check in Java
          $switch_val = $command2; {
            if ($switch_val eq "add")
            {
                $ADDHOST = shift(@ARGV);
                if ( ! $ADDHOST ) {
                  #print_help ("host", "Host name is missing from input")
                  print_help ("host", "add");
                  return FAILED;
                }
		if ( $ADDHOST eq "-h" || $ADDHOST eq "-help") {
                  print_help("host","add");
                  return SUCCESS;
		}

		my $arg = shift(@ARGV);
		if ( $arg ) {
		  if ($arg eq "-silent") {
		    $addHostSilent = 0;
		  } else {
		    print_help("host","add");
		    return FAILED;	
		  }
		}
            }
            elsif ($switch_val eq "remove" )
            {
                $RMHOST = shift(@ARGV);
                if ( ! $RMHOST ) {
                  #print_help ("host", "Host name is missing from input")
                  print_help ("host", "remove");
                  return FAILED;
                }
		if ( $RMHOST eq "-h" || $RMHOST eq "-help") {
                  print_help("host","remove");
                  return SUCCESS;
		}
            }
            else { #print_help ("host", "Invalid argument $command2")
                   print_help ("host", "remove") if defined($command2) && ($command2 ne "-h") && ($command2 ne "-help");
                   return FAILED;  }
          }
        }
  elsif ($switch_val eq "zipfiles" )
        {
          $ZIPFILESFORDATE = 1;
        }
  elsif ($switch_val eq "collectzips" ) 
        {
          $COLLECTZIPS = $command2 if defined($command2);
        }
  elsif ($switch_val eq "createTfaSetup" )
        {
          $CREATETFASETUP = 1;
        }
  elsif ($switch_val eq "updateJDKInTFASetup" )
        {
          $UPDATEJDKINTFASETUP = 1;
        }
  elsif ($switch_val eq "recreateFileEntitiesInBDB" )
        {
          $RECREATEFILEENTITIESINBDB = 1;
        }
  elsif ($switch_val eq "createTfaDirectories" )
        {
          $CREATETFADIRECTORIES = 1;
        }
  elsif ($switch_val eq "fixInitTfa" )
        {
          $FIXINITTFA = 1;
        }
  elsif ($switch_val eq "fixTfactl" )
        {
          $FIXTFACTL = 1;
        }
  elsif ($switch_val eq "fixTfadiagnostics" )
        {
          $FIXTFADIAGNOSTICS = 1;
        }
  elsif ($switch_val eq "upload" )
        {
          $UPLOAD = 1;
          @UPLOAD_FLAGS = ($command2, @ARGV);
        }
  elsif ($switch_val eq "setupmos" )
        {
          $SETUPMOS = 1;
	  @FLAGS_GENERIC = ($command2, @ARGV);
        }
  elsif ($switch_val eq "setupsudocmds" )
        {
          $SETUPSUDOCMDS = 1;
        }
  elsif ($switch_val eq "copytfactl" )
        {
          $COPYTFACTL = 1;
        }
  elsif ($switch_val eq "updatepropertiesfile" )
        {
          $UPDATEPROPERTIESFILE = 1;
        }
  elsif ($switch_val eq "updatedirectoriesfile" )
        {
          $UPDATEDIRECTORIESFILE = 1;
        }
  elsif ($switch_val eq "updateautodiagcollect" )
	{
	  $UPDATEAUTODIAGCOLLECT = 1;
	}
  elsif ($switch_val eq "updateciphersuite" )
	{
	  $UPDATECIPHERSUITE = 1;
	}
  elsif ($switch_val eq "checkfileaccessusingsu" )
        {
                $CHECKFILEACCESSUSINGSU = 1;
                $INPUTFILE = $command2;
                $TFAUSER = shift(@ARGV);
        }
  elsif ($switch_val eq "checkfileaccess" )
        {
                $CHECKFILEACCESS = 1;
                $INPUTFILE = $command2;
                $TFAUSER = shift(@ARGV);
        }
  elsif ($switch_val eq "runtest" )
        {
          $RUNTEST = 1;
        }
  elsif ($switch_val eq "senduninstallupdate" )
        {
          $SENDUNINSTALLUPDATE = 1;
        }
  elsif ($switch_val eq "stop_suptools" )
        {
          $STOPSUPTOOLS = 1;
        }
  elsif ($switch_val eq "parseevents" )
        {
          $PARSEEVENTS = 1;
        }
  elsif ($switch_val eq "checkfiletypepattern" )
        {
          $CHECKFILETYPEXML = 1;
        }
  elsif ( $switch_val eq "producer" ) {
    my $producer  = "producer";
    #Make sure action host is Collector
    #if ( getTFARunMode($tfa_home) eq "RECEIVER" ) {
    #  print "\nYou can not run this command in receiver cluster\n";
    #  exit 1;
    #}
    if ( ! $IS_TFA_ADMIN ) {
      print "\nAccess Denied: Only TFA Admin can run this command\n\n";
      exit 1;
    }
    if ( ! $command2 ) {
      print_help ("producer", "");
      return;
    }

    if ( defined $command2 && ($command2 eq "-h" || $command2 eq "-help") ) {
      print_help("producer");
      return;
    }

    my $command3 = shift(@ARGV);
    $switch_val = $command2;

    if (defined($command3) && (($command3 eq "-h") || ($command3 eq "-help"))) {
      if ( $switch_val eq "start" ) {
        print_help("producer","start");
      } elsif ( $switch_val eq "stop" ) {
        print_help("producer","stop");
      }
      return;
    }

    #Make sure atleast one receiver registered to run this command
    my @receivers = tfactlshare_getListOfAllRececivers($tfa_home);
    if ( scalar(@receivers) <= 0 ) {
      print "There should be at least one receiver registered to start/stop $producer\n";
      exit 1;
    }


    {
       if ( $switch_val eq "start" ) {
         $RACTION = "start";
       }
       elsif ( $switch_val eq "stop" ) {
         $RACTION = "stop";
       }
       elsif ( $switch_val eq "status" ) {
         $RACTION = "status";
       }
       elsif ( $switch_val eq "monitor_filetypes" ) {
         my $val = $command3;
         $FTYPES = $val;
       }
       else {
         if ( defined($command2) && ($command2 ne "-h") && ($command2 ne "-help") ) {
           print_help ($producer, "Invalid argument $switch_val");
           return;
         }
       }
    }
  }
  elsif ( $switch_val eq "client" || $switch_val eq "webadmin" ) {
    my $collector  = "client";
    my $cmd_name = $switch_val;
    #Make sure action host is Receiver
    #if ( getTFARunMode($tfa_home) eq "COLLECTOR" ) {
    #  tfactlshare_error_msg(500,undef);
    #  exit 1;
    #}
    my $crs_home = get_crs_home($tfa_home);
    my $is_crs_user = 0;
    if ( $crs_home )
    {#fix 28927439. Read crs owner from crsconfig_params key=ORACLE_OWNER
      my $crsconfig_params = catfile($crs_home, "crs", "install", "crsconfig_params");
      my $crsuser = "";
      if ( -r "$crsconfig_params" )
      {
        open(CPF, "$crsconfig_params");
        while(<CPF>)
        {
          chomp;
          if ( /^ORACLE_OWNER=(\w+)/ )
          {
            $crsuser = $1;
          }
        }
        close(CPF);
      }
      if ( $crsuser eq $current_user )
      {
        $is_crs_user = 1;
      }
    }

    #print_help ($collector, "") if ( ! $command2 );
    if ( defined $command2 && ($command2 eq "-h" || $command2 eq "-help") ) {
      print_help($collector);
      return;
    }
    
    if ( ! $IS_TFA_ADMIN && $is_crs_user == 0 ) {
       tfactlshare_error_msg(507,undef);
       return FAILED;
    }

    $switch_val = $command2; {
      if ( ($switch_val eq "add") or ($switch_val eq "reset") ) {
        $CACTION = "add";
        $CTYPE = "node";
        $CollectorNode = shift(@ARGV);

        if ( $CollectorNode eq "-h" || $CollectorNode eq "-help" ) {
           print_help("client","add");
           return;
         }
        
	if(!( $CollectorNode =~ m/^[a-zA-Z_][a-zA-Z\d_\.\-]*$/ ))
	{
		print_help("client");
        	return;
	}

        if ($cmd_name eq "client" && $CollectorNode eq "tfarcv" ) {
	  $CTYPE = "dummy";
	}

        if($cmd_name eq "webadmin" || $CollectorNode eq "webadmin" ) {
    	      if ( ! $IS_TFA_ADMIN ) {
                  tfactlshare_error_msg(507,undef);
                  return FAILED;
              }
            $CTYPE = "dummy";
            $CollectorNode = "tfarweb";
        }	
	my $cversion = "";
        my $cwfile = "";
        my $cguid = "";
        if ( @ARGV )
        {
          for ( my $i = 0 ; $i <= $#ARGV; $i++ )
          {
            if ( $ARGV[$i] eq "-version" )
            {
              $cversion = $ARGV[++$i];
              my @d = split(/\./, $cversion);
              $cversion = "";
              for(my $i = 0; $i <= 4; $i++)
              {
                $d[$i] = 0 if ( ! $d[$i] );
                $cversion .= $d[$i] . ".";
              }
              $cversion =~ s/\.$//;
            }
             elsif ( $ARGV[$i] eq "-export" )
            {
              $cwfile =  File::Spec->rel2abs($ARGV[++$i]);
              if ( -e $cwfile && ! -w $cwfile )
              {
                print "Error: $cwfile is not writable\n";
                tfactlshare_error_msg(511,undef);
                return FAILED;
              }
              $CTYPE = "mc";
            }
             elsif ( $ARGV[$i] eq "-guid" )
            {
              $cguid = $ARGV[++$i];
            }
          }
        }
        if ( ! $CollectorNode ) {
           tfactlshare_error_msg(512,undef);
           return FAILED;
        }

	$roption = "n";
	$koption = "n";
	
	if( isCollectorNodeRegistered($tfa_home,$CollectorNode) == FAILED )
	{
	  if ( ! $cwfile )
          {
            require Term::ReadKey;
            import Term::ReadKey;
            $Cpassword = tfactladmin_read_password();
            return FAILED if ( ! $Cpassword );
          }
           else
          {
            $Cpassword = tfactlshare_generate_password(16);
          }
	  $roption = "y";
	}
         elsif ( $cwfile )
        {
          $CACTION = "export";
          $Cpassword = tfactladmin_get_key($tfa_home, $CollectorNode);
          if ( ! $Cpassword )
          {
            $Cpassword = tfactlshare_generate_password(16);
          }
          $roption = "y";
        }
	else {
	  tfactlshare_error_msg(516,undef);
          return ;
       }
       $cwfile = "export=$cwfile" if ( $cwfile );
       $cguid = "MYCLUSTERGUID" if ( ! $cguid );
       if ( ! $cversion )
       {
         my $crs_home = get_crs_home($tfa_home);
         $ENV{ORACLE_HOME} = $crs_home;
         my $ORACLE_HOME = $crs_home;
         $ENV{LD_LIBRARY_PATH} = $ORACLE_HOME."/lib";
         $cversion = `$ORACLE_HOME/jdk/bin/java -cp $tfa_home/jlib/RATFA.jar:$ORACLE_HOME/jlib/clscred.jar:$ORACLE_HOME/jlib/srvm.jar oracle.rat.tfa.uc.TFAManageCredentials -printccversion`;
         chomp($cversion);
       }
       $roption = "$roption\[$cversion\[$cwfile\[$cguid";
     }
      elsif ($switch_val eq "cleanup" ) {
        $CollectorNode = shift(@ARGV);
        tfactladmin_cleanup_client($CollectorNode);
     }
      elsif ($switch_val eq "remove" ) {
        $CollectorNode = shift(@ARGV);
	if ( $CollectorNode eq "-h" || $CollectorNode eq "-help" ) {
           print_help("client","remove");
           return;
         }
       
	 if($cmd_name eq "webadmin" || $CollectorNode eq "webadmin") {
            $CollectorNode = "tfarweb";
        }
        my $removed = tfactladmin_rm_key ($tfa_home, $CollectorNode);
        if ( $removed == 1 )
        {
          print "Removed client $CollectorNode\n";
        }
         else
        {
          tfactlshare_error_msg(517,undef);
          exit 1;
        }
     }
      elsif ($switch_val eq "list" ) {
        #print "List of registered clients : \n";
        my $show_details = 0;
	my $command3=$ARGV[0];
	if($command3 eq "-h" || $command3 eq "-help") {
	  print_help("client","list");
	  return;
	}
	 if ( @ARGV )
        {
          for ( my $i = 0 ; $i <= $#ARGV; $i++ )
          {
            if ( $ARGV[$i] eq "-details" )
            {
              $show_details = 1;
            }
             elsif ( ! $CollectorNode && $ARGV[$i] !~ /^-/ )
            {
              $CollectorNode = $ARGV[$i];
            }
          }
        }

        tfactladmin_list_clients ($tfa_home, $CollectorNode, $show_details);
     }
     else {
         if ( defined($command2) && ($command2 ne "-h") && ($command2 ne "-help") ) { 
           print_help ($collector, "Invalid argument $switch_val");
           return;
         }
     }
   }
  }

  elsif ($switch_val eq "receiver" ) {
    if($IS_WINDOWS){
      print "\nReceiver is not supported on TFA for Windows\n\n.";
      return;
    }
    my $lhost=tolower_host();
    chomp($lhost);
    #print_help ("receiver", "") if ( ! $command2 );
    if (defined $command2 && ($command2 eq "-h" || $command2 eq "-help")) {
      print_help("receiver");
      return;
    }
    if ( ! $IS_TFA_ADMIN ) {
      tfactlshare_error_msg(507,undef);
      return FAILED;
    }

    $switch_val = $command2; {
    if ($switch_val eq "add") {
	$receiverNode = shift(@ARGV);
	if ( $receiverNode eq "-h" || $receiverNode eq "-help" ) {
	  print_help("receiver","add");
	  return;
	}
	#if ( getTFARunMode($tfa_home) eq "RECEIVER" ) {
	#  tfactlshare_error_msg(501,undef);
	#  return FAILED;
	#}
        if ( $receiverNode eq "-manifest" )
        {
          $receiverNode = shift(@ARGV);
        }
	if ( ! $receiverNode) {
	  tfactlshare_error_msg(502,undef);
	  return FAILED;
	}
        if ( ! -f $receiverNode ) 
        {
	  my @parts = split /:/,$receiverNode;
	  my $rnode = $parts[0];
	  my $rport = $parts[1];
	  if(! $rnode) {
	    tfactlshare_error_msg(503,undef);
	    return FAILED;
	  }
	  if( ! $rport) {
	    tfactlshare_error_msg(504,undef);
	    return FAILED;
	  }
          if(($rnode eq $lhost) or (!tfactlshare_isReceiverRegistered($tfa_home,$rnode)))
	  {
	    system "stty -echo";
	    print "Enter Key: ";
	    chomp($Rpassword = <STDIN>);
	    print "\n";
	    system "stty echo";
	  }
	  else {
	     tfactlshare_error_msg(505,undef);
	     return FAILED;
	  }      
        }

    }
    elsif ($switch_val eq "remove" ) {
      $RMRECEIVER = shift(@ARGV);
      if ( $RMRECEIVER eq "-h" || $RMRECEIVER eq "-help" ) {
        print_help("receiver","remove");
        return;
      }
      if ( getTFARunMode($tfa_home) eq "RECEIVER" ) {
        tfactlshare_error_msg(506,undef);
        return FAILED;
      }
      if ( ! $RMRECEIVER ) {
        tfactlshare_error_msg(502,undef);
        return FAILED;
      }
    }
    elsif ( $switch_val eq "stop") {
       $MANAGE_RECEIVER = "stop";
    }
    elsif ( $switch_val eq "start") {
      # add a check if receiver services are already started
      # add a check if location in acfs for DSC mode
      $MANAGE_RECEIVER = "start";
    }
    elsif ( $switch_val eq "pluginadd") {
        $pluginadd = shift(@ARGV);
        if ( $pluginadd eq "-h" || $pluginadd eq "-help" ) {
          print_help("receiver");
          return;
        }    
        if ( getTFARunMode($tfa_home) eq "RECEIVER" ) {
          tfactlshare_error_msg(501,undef);
          return FAILED;
        }    
        if ( ! $pluginadd) {
          tfactlshare_error_msg(502,undef);
          return FAILED;
        }    
     
        my @pparts = split /:/,$pluginadd;
        my $pluginname = $pparts[0];
        my $pluginpath = $pparts[1];
        if(! $pluginname) {
          tfactlshare_error_msg(503,undef);
          return FAILED;
        }    
        if( ! $pluginpath) {
          tfactlshare_error_msg(504,undef);
          return FAILED;
        }   
        my @receivers1 = tfactlshare_getListOfAllRececivers($tfa_home);
        if ( scalar(@receivers1) <= 0 ) {
          print "There should be atleast one receiver registered to start/stop\n";
          return FAILED;
        }
    }
    elsif ( $switch_val eq "processbug") {
        $processbug= shift(@ARGV);
        if ( $processbug eq "-h" || $processbug eq "-help" ) {
          print_help("receiver");
          return;
        }
        if ( ! $processbug) {
          tfactlshare_error_msg(502,undef);
          return FAILED;
        }

        my @pparts = split /:/,$processbug;
        my $bugname = $pparts[0];
        my $bugnum = $pparts[1];
        if(! $bugname) {
          tfactlshare_error_msg(503,undef);
          return FAILED;
        }
        if( ! $bugnum) {
          tfactlshare_error_msg(504,undef);
          return FAILED;
        }
    }
   
    elsif ( $switch_val eq "reset") {
      my $nextflag = shift(@ARGV);
      my $web_pass;
      my $web_port;

      if ( $nextflag eq "-h" )
      {
        print_help("receiver","reset");
        return FAILED;
      }
      elsif ( $nextflag eq "webadmin" )
      {
            # this code will not add rweb as robject and it everytime updates password
            #$MANAGE_RECEIVER = "webadmin:$web_pass";
      }
      elsif ($nextflag eq "webport" )
      {
            print "Enter a port to be used for tomcat\n";
            system "stty -echo";
            print "Port: ";
            chomp($web_port= <STDIN>);
            print "\n";
            system "stty echo";

	    $MANAGE_RECEIVER = "webport:$web_port";
      }
      else
      {
        tfactlshare_error_msg(502,undef);
        return FAILED;
      }

    }
    elsif ( $switch_val eq "startweb") {
      my $nextflag = shift(@ARGV);
      my $RPORT;

      if ( $nextflag eq "-h" )
      {
	print_help("receiver","startweb");
	return FAILED;
      }	 

      print "Starting receiver web..\n";

      if ( $nextflag eq "-port" )
      {
        $RPORT = shift(@ARGV);
      }
      if ( ! $RPORT )
      {
        tfactlshare_error_msg(502,undef);
        return FAILED;
      }
      $MANAGE_RECEIVER = "startweb:$RPORT";
    }
    elsif ( $switch_val eq "stopweb") {
      my $nextflag = shift(@ARGV);
      if ( $nextflag eq "-h" )
      {
	print_help("receiver","stopweb");
	return FAILED;
      }
      print "Stopping receiver web..\n";
      $MANAGE_RECEIVER = "stopweb";
	
    }
    elsif ($switch_val eq "send") {
      $FILETOSEND = shift(@ARGV);
    }
    elsif ( $switch_val = "info" )
    {
      my $nextflag = shift(@ARGV);
      if (defined $nextflag && ($nextflag eq "-h" || $nextflag eq "-help") )
      {
	print_help("receiver","info");
	return;
      }
      tfactladmin_receiverinfo();
    }
    else {
      if ( defined($command2) && ($command2 ne "-h") && ($command2 ne "-help") ) {
        print_help ("receiver", "Invalid argument $switch_val");
        return;
      }
    }
    }
  }
  elsif ($switch_val eq "restrictprotocol" ) {
          if ( ! $command2 ) {
            print_help ("restrictprotocol", "");
            return;
          }
          if (defined $command2 && ($command2 eq "-h" || $command2 eq "-help")) {
             print_help("restrictprotocol");
             return;
          }
	  $switch_val = $command2;
          if ($switch_val eq "-force")
          {
             $RESTRICTPROTOCOL = shift(@ARGV);
	     $FORCERESTRICT = 1;
             if ( ! $RESTRICTPROTOCOL ) {
                print_help ("restrictprotocol", "Protocol to be restricted is missing from input");
                return;
             }
	  }
          else {
             $RESTRICTPROTOCOL = $command2;
	  }
 
  }
  elsif ($switch_val eq "dom0IP" )
        {
          if ( ! $command2 ) {
            print_help ("dom0IP", "");
            return;
          }
          if (defined $command2 && ($command2 eq "-h" || $command2 eq "-help")) {
             print_help("dom0IP");
             return;
          }
          $switch_val = $command2; {
            if ($switch_val eq "add")
            {
                $ADDDOM0IP = shift(@ARGV);
                if ( ! $ADDDOM0IP || $ADDDOM0IP eq "-h" || $ADDDOM0IP eq "-help") {
                  #print_help ("dom0IP", "IPAddress is missing from input");
                  print_help ("dom0IP","add");
                  return;
                }
            }
            elsif ($switch_val eq "remove" )
            {
                $RMDOM0IP = shift(@ARGV);
                if ( ! $RMDOM0IP || $RMDOM0IP eq "-h" || $RMDOM0IP eq "-help" ) {
                    #print_help ("dom0IP", "IPAddress is missing from input");
                    print_help ("dom0IP", "remove");
                    return;
                }
            }
            else { if ( defined($command2) && ($command2 ne "-h") && ($command2 ne "-help") ) {
                     print_help ("dom0IP", "Invalid argument $command2");
                     return;
                   }
                 }
          }
        }
  elsif ( $switch_val eq "tail" || $switch_val eq "tvi" ) 
	{
	   $VIEW_LOG = 1;
	   $LOG_TYPE = $switch_val . " $command2 " . join(" ", @ARGV);
	}

  # Dispatch the command
  tfactlshare_pre_dispatch();
  $retval = tfactladmin_dispatch();

  return $retval;
}

########
# NAME
#   tfactladmin_dispatch
#
# DESCRIPTION
#   Dispatch de command.
#
# PARAMETERS
#
# RETURNS
#
########
sub tfactladmin_dispatch
{
 my $retval = SUCCESS;

 if ($CHECK) { $retval = exit checkTFAMain($tfa_home); $CHECK=0; }
 elsif ($START) { $retval = exit startTFA($tfa_home,$paramfile); $START=0; }
 elsif ($STOP) { $retval = exit stopTFA($tfa_home); $STOP=0; }
 elsif ($SHUTDOWN) { $retval = shutdownTFA($tfa_home); $SHUTDOWN=0; }
 elsif ($SSLRESTART) { $retval = sslRestart($tfa_home); $SSLRESTART=0; }
 elsif ($ENABLE) { $retval = enableTFA($tfa_home); $ENABLE=0; }
 elsif ($DISABLE) { $retval = disableTFA($tfa_home); $DISABLE=0; }
 elsif ($STARTFROMINIT) { $retval = startTFAFromInit($tfa_home); $STARTFROMINIT=0; }
 elsif ($STOPFROMINIT) { $retval = stopTFAFromInit($tfa_home); $STOPFROMINIT=0; }
 elsif ($smtp) { $retval = updateSmtpProperties($tfa_home); $smtp=0; }
 elsif ($rest) { $retval = restServices($tfa_home, $rest); $rest=0; }
 elsif ($stopords) { $retval = stopORDS($tfa_home); $stopords=0; }
 elsif ($startorachkdaemon) { $retval = tfactlshare_runOrachkDaemon($tfa_home, "start"); $startorachkdaemon=0; }
 elsif ($stoporachkdaemon) { $retval = tfactlshare_runOrachkDaemon($tfa_home, "stop"); $stoporachkdaemon=0; }
 elsif ($UNINSTALL) { $retval = uninstallTFA($tfa_home, $UNINSTALLARGS ); $UNINSTALL=0; }
 elsif ($DIAGNOSETFA) { $retval = collectTFADiagnostics($tfa_home); $DIAGNOSETFA=0; undef $DIAGNOSEARGS; }
 elsif ($SYNCTFANODES) { $retval = syncTFANodes($tfa_home, $SYNCTFANODES); $SYNCTFANODES = 0; }
 elsif ($syncpatch) { $retval = syncPatchFiles($tfa_home); $syncpatch = 0; }
 elsif ($SENDMAIL) { $retval = tfactlshare_sendMail($tfa_home, $to); $SENDMAIL = 0; }
 elsif ($configfromresp) { $retval = configFromResp($tfa_home, $rspfile); $configfromresp = 0; }
 elsif ($MANAGER) { exit runGUI($tfa_home); $MANAGER=0; }
 elsif ($CHECKAUTOPATCHING) { $retval = checkAutoPatching($tfa_home); $CHECKAUTOPATCHING=0; }
 elsif ($CHECKKEYSTORES) { $retval = checkKeyStores($tfa_home); $CHECKKEYSTORES=0; }
 elsif ($COMMANDTOEXECUTE && $EXECUTEINHOST) { $retval = executeCommandInHost($tfa_home, $COMMANDTOEXECUTE, $EXECUTEINHOST); }
 elsif ($PROGRAM_PRINT && $EXECUTEINHOST_PRINT) { 
      $retval = executeCommandInHostAndPrint($tfa_home, $PROGRAM_PRINT, 
                                   $COMMANDTOEXECUTE_PRINT, 
                                   $EXECUTEINHOST_PRINT); 
      undef $PROGRAM_PRINT; undef $COMMANDTOEXECUTE_PRINT;
      undef $EXECUTEINHOST_PRINT;
 }
 elsif ($CLEAN) { exit cleanTFAMain(); $CLEAN=0; }
 elsif ($ADDHOST) { $retval = addHost($tfa_home, $ADDHOST, $addHostSilent, -1); undef($ADDHOST); }
 elsif ($receiverNode) {
  if ( -f $receiverNode )
  {
   $retval = tfactlshare_addReceiver_wrapfile($tfa_home, $receiverNode);
  }
   else
  {
   $retval = tfactlshare_addReceiver($tfa_home, $receiverNode, 1, -1,$Rpassword);
   my $localhost=tolower_host();
   my $configfile = catfile("$tfa_home","internal","config.properties");
   if ( tfactlshare_getConfigValue($configfile,"startronadd") eq "true" ) {
     #start receiver at the time of install on R side
     #startService("receiver",$ADDRECEIVER, $ADDRECEIVER,1); 
     #startService("producer",$localhost, $receiverNode,1);
   }
  }
   undef($receiverNode); 
   undef($Rpassword);
 }
 elsif ($receiverNode) {
   $retval = tfactlshare_addReceiver($tfa_home, $receiverNode, 1, -1,$Rpassword);
   undef($receiverNode); undef($Rpassword);
 }
 elsif ($pluginadd) {
   $retval = tfactladmin_addplugin($pluginadd);
   undef($pluginadd);
 }
 elsif ($processbug) {
   $retval = tfactladmin_processbug($processbug);
   undef($processbug);
 }
 elsif ($CACTION) { $retval = tfactladmin_managecollector($CACTION,$CollectorNode,$Cpassword,$tfa_home,$roption,$koption,$CTYPE); 
                    undef($CACTION);undef($CollectorNode);undef($Cpassword);undef($roption);undef($koption);undef($CTYPE);
}
 elsif ($FILETOSEND) { $retval = sendFileToReceiver($tfa_home, $FILETOSEND,1,-1); undef($FILETOSEND); }
 elsif ($RACTION) {
   $retval = tfactladmin_manageService($RACTION);
   undef($RACTION);
 }
 elsif ($FTYPES) {	
   $retval = tfactladmin_addFileTypes($tfa_home,$FTYPES);	
   undef($FTYPES);	
 } 	
 elsif ($MANAGE_RECEIVER) {	
   $retval = tfactladmin_manage_receiver($MANAGE_RECEIVER);	
   undef($MANAGE_RECEIVER);	
 } 	
 elsif ($ADDDOM0IP) { $retval = addDom0IP($tfa_home, $ADDDOM0IP); }	
 elsif ($RESTRICTPROTOCOL) { $retval = tfactladmin_restrictProtocol($tfa_home, $RESTRICTPROTOCOL, $FORCERESTRICT); $RESTRICTPROTOCOL=0; $FORCERESTRICT = 0 }	
 elsif ($RMHOST) { $retval = removeHost($tfa_home, $RMHOST); }	
 elsif ($RMRECEIVER) { $retval = removeReceiver($tfa_home, $RMRECEIVER); undef($RMRECEIVER); }	
 elsif ($RMDOM0IP) { $retval = removeDom0IP($tfa_home, $RMDOM0IP); }	
 elsif ($SENDUNINSTALLUPDATE) { $retval = sendUninstallUpdate($tfa_home); $SENDUNINSTALLUPDATE=0; }	
 elsif ($STOPSUPTOOLS) { $retval = tfactlshare_stop_all_tools ($tfa_home); $STOPSUPTOOLS=0; }	
 elsif ($PARSEEVENTS) { $retval = tfactlshare_parse_files ($tfa_home); $PARSEEVENTS=0; }
 elsif ($FIXTFACTL) { $retval = fixTfactl($tfa_home); $FIXTFACTL=0; }
 elsif ($FIXTFADIAGNOSTICS) { $retval = tfactlshare_fixTfadiagnostics($tfa_home); $FIXTFADIAGNOSTICS=0; }
 elsif ($UPLOAD) { $retval = upload_tfaweb($tfa_home, @UPLOAD_FLAGS);$UPLOAD=0;} 
 elsif ($SETUPMOS) { $retval = tfactladmin_setupmos($tfa_home,@FLAGS_GENERIC); undef($SETUPMOS); }
 elsif ($COPYTFACTL) { $retval = copytfactl( $tfa_home); $COPYTFACTL=0; }
 elsif ($UPDATEPROPERTIESFILE) { $retval = updatePropertiesFile( $tfa_home); $UPDATEPROPERTIESFILE=0; }
 elsif ($UPDATEDIRECTORIESFILE) { $retval = updateDirectoriesFile( $tfa_home); $UPDATEDIRECTORIESFILE=0; }
 elsif ($UPDATEAUTODIAGCOLLECT) { $retval = tfactlshare_updateAutoDiagcollect( $tfa_home ); $UPDATEAUTODIAGCOLLECT=0; }
 elsif ($UPDATECIPHERSUITE) { $retval = tfactlshare_updateCipherSuite( $tfa_home ); $UPDATECIPHERSUITE=0; }
 elsif ($CHECKFILEACCESSUSINGSU) { $retval = checkFileAccessUsingSu( $tfa_home, $INPUTFILE, $TFAUSER ); $CHECKFILEACCESSUSINGSU=0; }
 elsif ($CHECKFILEACCESS) { $retval = checkFileAccess( $tfa_home, $INPUTFILE, $TFAUSER ); $CHECKFILEACCESS=0; }
 elsif ($FIXINITTFA) { $retval = fixInitTfa($tfa_home); $FIXINITTFA=0; }
 elsif ($UPDATEJDKINTFASETUP)  { $retval = updateJDKInTFASetup($tfa_home); $UPDATEJDKINTFASETUP=0; }
 elsif ($RECREATEFILEENTITIESINBDB) { $retval = recreateFileEntitiesInBDB($tfa_home); $RECREATEFILEENTITIESINBDB=0; }
 #elsif ($CREATETFASETUP) { $retval = createTFASetup($tfa_home); }
 elsif ($CREATETFADIRECTORIES) { $retval = createTFADirectories($tfa_home); $CREATETFADIRECTORIES=0; }
 elsif ($GENERATECOOKIE) { $retval = generateTFACookie($tfa_home); $GENERATECOOKIE=0; }
 elsif ($GENCERTS) { 
   if ( $GENCERTS == 2 ) {
     $retval = generateReceiverCerts($TEMP_TFAHOME,$TFA_JHOME);  
   }
   else { 
     $retval = generateCerts($TEMP_TFAHOME,$TFA_JHOME,$SSLKEY); 
   }
   $GENCERTS=0; 
 } 
 elsif (defined($CHANGEJVMMEMSIZE) || defined($CHANGEJVMOTHER)) {
   $retval = tfactladmin_setJVMFlags($tfa_home,$CHANGEJVMMEMSIZE,$CHANGEJVMOTHER,$CLUSTERWIDE,$RESTARTTFA);
   undef($CHANGEJVMMEMSIZE);
   undef($CHANGEJVMOTHER);
   undef($CLUSTERWIDE);
   undef($RESTARTTFA); 
 } 
 elsif ($CHANGEREPO || defined($CHANGEREPOSIZE)) { 
    $CHANGEREPOSIZE = getRepositoryMaxSize($tfa_home) if ( (! defined $CHANGEREPOSIZE));
    $retval = changeRepository($tfa_home, $CHANGEREPO, $CHANGEREPOSIZE, $FORCE);
    undef($CHANGEREPO);
    undef($CHANGEREPOSIZE);
    undef($FORCE);
 }
 elsif ($port) { $retval = updateTFAPort($tfa_home, $port); undef($port); }
 elsif ($tfa_base) { $retval = updateTFABase($tfa_home, $tfa_base, $onlylocal); undef($tfa_base); $onlylocal = 0; }
 elsif ($java_home) { $retval = updateJavaHome($tfa_home, $java_home, $onlylocal); undef($java_home); $onlylocal = 0; }
 elsif ($tdinterval) { $retval = tfactlshare_updateThreadDumpInterval($tfa_home, $tdinterval, $onlylocal); undef($tdinterval); $onlylocal = 0; }
 elsif ($tdfrequency) { $retval = tfactlshare_updateThreadDumpFrequency($tfa_home, $tdfrequency, $onlylocal); undef($tdinterval); $onlylocal = 0; }
 elsif ($MAXLOGSIZE) { $retval = updateMaxLogSize( $tfa_home, $MAXLOGSIZE, $ACCESSLOCAL );
                       $MAXLOGSIZE = 0; $ACCESSLOCAL = "-c"; }
 elsif ($MAXLOGCOUNT) { $retval = updateMaxLogCount( $tfa_home, $MAXLOGCOUNT, $ACCESSLOCAL ); $MAXLOGCOUNT = 0; $ACCESSLOCAL = "-c"; }
 elsif (defined $maxCoreFileSize) { $retval = updateMaxCoreFileSize( $tfa_home, $maxCoreFileSize, $ACCESSLOCAL ); undef($maxCoreFileSize); $ACCESSLOCAL="-c"; }
 elsif (defined $maxCoreCollectionSize) { $retval = updateMaxCoreCollectionSize( $tfa_home, $maxCoreCollectionSize, $ACCESSLOCAL ); undef($maxCoreCollectionSize); $ACCESSLOCAL="-c"; }
 elsif ($RUNTEST) { $retval = runTest($tfa_home); $RUNTEST=0; }
 elsif ($CHECKFILETYPEXML) { $retval = validateFileTypePattern($tfa_home); $CHECKFILETYPEXML=0; }
 elsif ($ZIPFILESFORDATE)  { $retval = zipFilesForDate($tfa_home,$STARTDATE,$ENDDATE,
                            $OUTFILE,$CLUSTERWIDE,$SINCE,$FOR); $ZIPFILESFORDATE=0; 
                            undef($STARTDATE); undef($ENDDATE); undef($OUTFILE);
                            undef($CLUSTERWIDE); undef($SINCE); undef($FOR); }
 elsif ($COLLECTZIPS) { $retval = requestZipTransfers($COLLECTZIPS); undef($COLLECTZIPS); }
 elsif ($DELETEDB)  { $retval = deleteDatabase($tfa_home); $DELETEDB=0; }
 elsif ($SET_FLAG)  { $retval = setFlag($tfa_home, $SET_FLAG, $CLUSTERWIDE, 0, $SET_CMD_ARGS); 
                      undef $SET_FLAG; undef $CLUSTERWIDE; undef $SET_CMD_ARGS;
                      #exit 1 if ($retval == FALSE); 
                      }
 elsif ($TNTPROP) { $retval = createTNTprop($tfa_home, $INVFILE); $TNTPROP=0; undef($INVFILE); }
 elsif ($FILELISTDIRECTORY) { $retval = generateFileList($tfa_home, $FILELISTDIRECTORY, $FILELISTLASTINV); undef($FILELISTDIRECTORY); undef($FILELISTLASTINV); }
 elsif ($VIEW_LOG) { $retval = viewLog($tfa_home, $LOG_TYPE); undef($VIEW_LOG); undef($LOG_TYPE)}
 elsif ($SETUPSUDOCMDS ) { $retval = tfactlshare_setsudo_cmds(); $SETUPSUDOCMDS = 0; }


 return $retval; 
}




########
# NAME
#   tfactladmin_process_help
#
# DESCRIPTION
#   This function is the help function for the tfactladmin module.
#
# PARAMETERS
#   command     (IN) - display the help message for this command.
#
# RETURNS
#   1 if command found; 0 otherwise.
########
sub tfactladmin_process_help 
{
  my ($command) = shift;       # User-specified argument; show help on $cmd. #

  my ($desc);                                # Command description for $cmd. #
  my ($succ) = 0;                         # 1 if command found, 0 otherwise. #

  if (tfactladmin_is_cmd ($command)) 
  {                              # User specified a command name to look up. #
    $desc = tfactlshare_get_help_desc($command);
    tfactlshare_print "$desc\n";
    $succ = 1;
  }

  return $succ;
}

########
# NAME
#   tfactladmin_is_cmd
#
# DESCRIPTION
#   This routine checks if a user-entered command is one of the known
#   TFACTL internal commands that belong to the tfactladmin module.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is one of the known commands, false otherwise.
########
sub tfactladmin_is_cmd 
{
  my ($arg) = shift;

  return defined ($tfactladmin_cmds {$arg});

}

########
# NAME
#   tfactladmin_is_wildcard_cmd
#
# DESCRIPTION
#   This routine determines if an tfactladmin command allows the use 
#   of wild cards.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is a command that can take wildcards as part of its argument, 
#   false otherwise.
########
sub tfactladmin_is_wildcard_cmd 
{
  my ($arg) = shift;

  return defined ($tfactladmin_cmds{ $arg }) &&
    (tfactlshare_get_cmd_wildcard($arg) eq "True" ) ;
}

########
# NAME
#   tfactladmin_is_no_instance_cmd
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
#   The tfactladmin module currently supports no command that can run 
#   without an TFAMain instance.
########
sub tfactladmin_is_no_instance_cmd 
{
  my ($arg) = shift;

  return !defined ($tfactladmin_cmds{ $arg }) ||
    (tfactlshare_get_cmd_noinst($arg) ne "True" ) ;
}

########
# NAME
#   tfactladmin_syntax_error
#
# DESCRIPTION
#   This function prints the correct syntax for a command to STDERR, used 
#   when there is a syntax error.  This function is responsible for 
#   only tfactladmin commands.
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
sub tfactladmin_syntax_error 
{
  my ($cmd) = shift;
  my ($cmd_syntax);                               # Correct syntax for $cmd. #
  my ($succ) = 0;


  #display syntax only for commands in this module.
  if (tfactladmin_is_cmd($cmd))
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
#   tfactladmin_get_tfactl_cmds
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
sub tfactladmin_get_tfactl_cmds 
{
  return tfactlshare_filter_invisible_cmds(%tfactladmin_cmds);
}

#############################################################
#Function to Start TFA using init.tfa start
#############################################################

sub startTFA {
    my $tfa_home = shift;

    if ( $IS_WINDOWS ) {
      print "Starting TFA from the Command Line\n";
      tfactlwin_start_tfa($tfa_home);
      print "Successfully started TFA\n";
    } else {
        my $INITTFA = catfile($INITDIR, "init.tfa" );

        if ( -f "$INITTFA" ) {
            my $startcmd = "$INITTFA start cmdline";
            system( $startcmd );
            tfactlshare_managestart($tfa_home);
            my $is_receiver = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "RUN_MODE");
            if($is_receiver eq "receiver") {
              tfactladmin_startReceiverServices($tfa_home);
            }

        } else {
                my $tfactl = catfile($tfa_home, "bin", "tfactl");
		my $startcmd = "$tfactl -initstart";
		system($startcmd);
        }
    }       
}

#############################################################
#Function to Stop TFA using init.tfa stop
#############################################################

sub stopTFA {
    my $tfa_home = shift;
    if($IS_WINDOWS){
      print "Stopping TFA from the Command Line\n";
      tfactlwin_stop_tfa($tfa_home);
      print "Successfully stopped TFA\n";
    }else{
        my $INITTFA = catfile($INITDIR, "init.tfa" );
        #stop tomcat if its in receiver mode
        my $is_receiver = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "RUN_MODE");
        if($is_receiver eq "receiver") {
           tfactladmin_stopReceiverServices($tfa_home);
        }
        tfactlshare_managestop($tfa_home);
        if ( -f "$INITTFA" ) {
            my $stopcmd = "$INITTFA stop cmdline";
            system( $stopcmd );
        } else {
            my $tfactl = catfile($tfa_home, "bin", "tfactl");
	    my $stopcmd = "$tfactl -initstop";
	    system($stopcmd);
        }
    }
}

#############################################################
#Function to Shutdown TFA using init.tfa shutdown
#############################################################

sub shutdownTFA {
        my $tfa_home = shift;

        if($IS_WINDOWS){
          print "Shutting down TFA from the Command Line\n";
          tfactlwin_shutdown_tfa($tfa_home);
          print "Successfully shutdown TFA\n";
        }else{
          my $INITTFA = catfile($INITDIR, "init.tfa" );

          if ( -f "$INITTFA" ) {
                  my $shutdowncmd = "$INITTFA shutdown";
                  system( $shutdowncmd );
          } else {
		my $tfactl = catfile($tfa_home, "bin", "tfactl");
		my $stopcmd = "$tfactl -initstop";
		system($stopcmd);
          }
        }
}

#############################################################
#Function to Enable TFA using init.tfa enable
#############################################################

sub enableTFA {
  if($IS_WINDOWS){
    print "Enabling TFA from the Command Line\n";
    tfactlwin_enableTFA();
    print "Successfully enabled TFA\n";
  }else{
    my $INITTFA = catfile($INITDIR, "init.tfa" );

    if ( -f "$INITTFA" ) {
            my $shutdowncmd = "$INITTFA enable ";
            system( $shutdowncmd );
    } else {
            print "Unable to locate $INITTFA.\n";
    }
  }
}

#############################################################
#Function to Disable TFA using init.tfa disable
#############################################################

sub disableTFA {
  if($IS_WINDOWS){
    print "Disabling TFA from the Command Line\n";
    tfactlwin_disableTFA();
    print "Successfully disabled TFA\n";
  }else{
    my $INITTFA = catfile($INITDIR, "init.tfa" );

    if ( -f "$INITTFA" ) {
            my $shutdowncmd = "$INITTFA disable";
            system( $shutdowncmd );
    } else {
            print "Unable to locate $INITTFA.\n";
    }
  }
}

#======================= startTFAFromInit ==========================#
sub startTFAFromInit
# 
#  Set the start flag in the status.txt file then ..
#  Builds the start command line for the Java and then execs it so that 
#  We do not wait for a return
#  Once that is done we retry to connect to TFA to make sure it is started.
{
  dbg(DBG_VERB, "In Start TFA\n");
  my $localhost=tolower_host();
  my ($tfa_home, $paramfile) = @_;
  my $statusfile = catfile("$tfa_home","internal","runstatus.txt");
  my $initfile = catfile("$tfa_home","install","TFAMainrun");
  my $command;
  my $tfapid;
  my $inittfapid;
  my $tfaprocess;
  my $isChild = 0;

  # check if TFAMain is already running
  #$tfapid=`ps -ef | grep "TFAMain"| grep -v grep | awk '{print \$2}'`;
  $tfapid=get_tfa_pid($tfa_home);
  if (defined $tfapid && $tfapid ne '') {
    if ( $IS_WINDOWS )
    {
      my $exists = tfactlwin_get_tfa_main_pid();
      $tfaprocess = "TFAMain" if ( $exists );
    } 
     else
    {
      $tfaprocess = `ps -f -p $tfapid | grep -v PID`;
    }
    print "In startTFA : $tfaprocess\n";
  }
  
  if ( $^O eq "MSWin32" )
  { # Check if service is running
    $inittfapid = "running";
  }
   else
  {
    $inittfapid=`ps -ef | grep "init\.tfa" | grep -v grep | awk '{print \$2}'`;
  }
  if (defined $tfaprocess && $tfaprocess ne '') {
    print "TFA is already running with PID : $tfapid";
  }
  else {
	  # Set the statusflag to allow us to run.
	  $command = "echo run > $statusfile";
	  system($command);
	   if ($inittfapid ne '') {
	     # Make  init try to start TFA ( which will call back in here 
	     dbg(DBG_NOTE, "Starting TFA out of init, Should be running in 10 seconds\n");
	     $command = "echo start > $initfile";
	     system($command);
	   }

	  tfactladmin_update_config_on_cluster_class($tfa_home);

	  tfactlshare_set_jvm_xmx ($tfa_home);

	  tfactlshare_updateClusterMode($tfa_home);

	  #Build the command line for TFA java

	  my $tfa_jar = catfile("$tfa_home","jlib","RATFA.jar");
	  my $tfa_bd_jar = catfile("$tfa_home","jlib","je-6.4.25.jar");
	  my $jdbc_jar = catfile("$tfa_home","jlib","ojdbc5.jar");
	  my $commons_io_jar = catfile("$tfa_home","jlib","commons-io-2.6.jar");
	  my $mail_jar = catfile("$tfa_home","jlib","javax.mail.jar");
	  
	  my $lc_jar = catfile("$tfa_home","jlib","lucene-core-6.6.0.jar");
	  my $la_jar = catfile("$tfa_home","jlib","lucene-analyzers-common-6.6.0.jar");
	  my $lq_jar = catfile("$tfa_home","jlib","lucene-queryparser-6.6.0.jar");
	  my $lcd_jar = catfile("$tfa_home","jlib","lucene-codecs-6.6.0.jar");
	  my $lqu_jar = catfile("$tfa_home","jlib","lucene-queries-6.6.0.jar");
	  my $lfa_jar = catfile("$tfa_home","jlib","lucene-facet-6.6.0.jar");
	  my $lex_jar = catfile("$tfa_home","jlib","lucene-expressions-6.6.0.jar");
	  my $json_jar = catfile("$tfa_home","jlib","javax.json-1.0.4.jar");
	  my $lgp_jar = catfile("$tfa_home","jlib","lucene-grouping-6.6.0.jar");
	  my $lhr_jar = catfile("$tfa_home","jlib","lucene-highlighter-6.6.0.jar");

	  #Add Oracle Wallet Jars
	  my $crs_home = get_crs_home($tfa_home);
	  my $walletJars;
	  my $oraclepki = catfile($tfa_home,"jlib","oraclepki.jar");

	  #it will pick jars from tfa_home and if not present then from grid_home
	  if (! -e $oraclepki) {
		if ( -d $crs_home) {
			$oraclepki = catfile($crs_home,"jlib","oraclepki.jar");
		}
	  } 

	  $walletJars = "$PSEP$oraclepki";
	  
          #Add SRVM and Event Jars 
	  my $eventJars;
          if ( catfile($crs_home,"jlib","srvm.jar") and catfile($crs_home,"jlib","clsce.jar")) {
	     $eventJars = "$PSEP". catfile($crs_home,"jlib","srvm.jar");
	     $eventJars = $eventJars . "$PSEP". catfile($crs_home,"jlib","clsce.jar");
	     $eventJars = $eventJars . "$PSEP". catfile($crs_home,"jlib","cha-diag-msg.jar");
             $ENV{LD_LIBRARY_PATH} = $ENV{LD_LIBRARY_PATH} . ":$crs_home/lib:$crs_home/srvm/lib:/etc/ORCLcluster/lib";
          }

      my $addRJars = 1;

	  my $java = catfile("$tfa_home","jre","bin","java$EXE");
	  if ( ! -e "$java" )
	  {
	    my $java_home = get_java_home ($tfa_home);
	    $java = catfile("$java_home","bin","java");

	    # Changes for SunOS 64 bit server
	    if ( $osname eq "SunOS" ) {
		$java = getJavaOnSunOS($java_home, "java");
	    }
	  }
	  my $classpath = "";
	  if ( $addRJars ) {
	    $classpath = "$tfa_jar$PSEP$tfa_bd_jar$PSEP$jdbc_jar$PSEP$commons_io_jar$PSEP$lc_jar$PSEP$la_jar$PSEP$lq_jar$PSEP$lfa_jar$PSEP$lqu_jar$PSEP$lcd_jar$PSEP$lex_jar$PSEP$json_jar$PSEP$mail_jar$PSEP$lgp_jar$PSEP$lhr_jar$walletJars$eventJars";
	  }
	  else {
	    $classpath = "$tfa_jar$PSEP$tfa_bd_jar$PSEP$jdbc_jar$PSEP$commons_io_jar$PSEP$mail_jar$walletJars$eventJars";
	  }
	  my $class =  "oracle.rat.tfa.TFAMain";
	  my $sysoutid;
	  if ( $^O eq "MSWin32" )
	  {
	    $sysoutid = strftime('%m.%d.%Y-%H.%M.%S',localtime);
	  }else{
	    $sysoutid = `date +%m.%d.%Y-%H.%M.%S`;
	  }
	  $sysoutid =~ s/\s+$//; # remove space at the end

	  my $output = " > ".catfile($tfa_home,"log","syserrorout.$sysoutid"). " 2>&1 &";
	  my $localhost = tolower_host();
	  my $oracle_base = get_oracle_base($tfa_home);

	  if ( $crs_home && $oracle_base && $tfa_home eq catfile($crs_home,"tfa",$localhost,"tfa_home")) {
	    $output = " > ". catfile($oracle_base,"tfa","$localhost","log","syserrorout.$sysoutid")." 2>&1 &";
	  }
	  elsif ( $oracle_base && -d catfile($oracle_base,"tfa",$localhost,"log") ) {
	    $output = " > ". catfile($oracle_base,"tfa",$localhost,"log","syserrorout.$sysoutid")." 2>&1 &";
	  }


	  $ENV{CLASSPATH} = $classpath;
	  my $commandline;
          my $jvmXms = "-Xms32m";

	  # Read from config.properties
	  my $tfajar = catfile($tfa_home, "jlib", "RATFA.jar");
	  my $config = catfile($tfa_home, "internal", "config.properties");
	  my $jvmXmx_value = tfactlshare_getConfigValue($config, "jvmXmx");
	  my $jvmLineOther_value = tfactlshare_getConfigValue($config, "jvmLineOther");
	  if($jvmLineOther_value !~ /-XX:ParallelGCThreads=/g){
	    my $number_of_cpu = `$java -cp $tfajar oracle.rat.tfa.util.SysInfo processorcount`;
	    chomp($number_of_cpu);
	    if($number_of_cpu >= 5){
	      if($jvmLineOther_value ne "null"){
	        $jvmLineOther_value = $jvmLineOther_value . " -XX:ParallelGCThreads=5 ";
	      } else {
	        $jvmLineOther_value = " -XX:ParallelGCThreads=5 ";
	      }
	    }
	  }
          $jvmXms = "-Xms64m" if ( $jvmXmx_value == 128 );
          $jvmXms = "-Xms128m" if ( $jvmXmx_value == 256 );
          $jvmXms = "-Xms256m" if ( $jvmXmx_value == 512 );
          $jvmXms = "-Xms512m" if ( $jvmXmx_value > 512 );
	  
	  my $jvmXmx_parameter;
	  my $jvmLineOther_parameter;
          my $defline = "-Djava.awt.headless=true -Ddisable.checkForUpdate=true";

	  $jvmXmx_parameter = "-Xmx${jvmXmx_value}m" if(defined $jvmXmx_value);
	  $jvmLineOther_parameter = "$jvmLineOther_value" if($jvmLineOther_value ne "null");

	  if ( $IS_WINDOWS ) {
	    $commandline = "cmd /c START \"\" /B $java -server $jvmXms $jvmXmx_parameter $defline $jvmLineOther_parameter $class $tfa_home $output";
	    $commandline =~ s/\\/\\\\/g;
	  } elsif ( $^O eq "hpux" ) {
	        $jvmLineOther_parameter = $jvmLineOther_parameter . " -XX:+UseGetTimeOfDay";
		$commandline = "$java -server $jvmXms $jvmXmx_parameter $defline $jvmLineOther_parameter $class $tfa_home $output";
	  } else {
	  	$commandline = "$java -server $jvmXms $jvmXmx_parameter $defline $jvmLineOther_parameter $class $tfa_home $output";
	  }
	  dbg(DBG_VERB, "$commandline\n");

	  system($commandline);

	  sleep(5);
	  checkTFAMain($tfa_home);
	  
	  # Update the permissions pidfile
	  my $pidfile = catfile($tfa_home, "internal", ".pidfile");
	  if ( -s "$pidfile" ) {
	    chmod(0755, $pidfile);
	  }
	  # init trace dirs if needed
	  tfactlshare_init_trace($tfa_home);

	  if ( ! $IS_WINDOWS ) {
	  	tfactlshare_autostart_tools($tfa_home);
	  }
	  
	  if ( !$IS_WINDOWS ) {  
	    #If TFA is running in receiver mode, start tomcat & Receiver process as nonroot user
	    my $tfa_setup_file = catfile($tfa_home,"tfa_setup.txt");
	    my $is_receiver = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "RUN_MODE");
	    my $file = catfile($tfa_home,"receiver","internal","rport.txt");
	    if ( ($is_receiver eq "receiver") && (! -e $file) ) {
	      tfactladmin_startReceiverServices($tfa_home);
	    }
	  }
  }
}

#======================= stopTFAFromInit ==========================#
sub stopTFAFromInit
{
  dbg(DBG_VERB, "In Stop TFA\n");
  my $tfa_home = shift;
  my $statusfile = catfile($tfa_home,"internal","runstatus.txt");
  my $initfile = catfile($tfa_home,"install","TFAMainrun");
  my $line;
  my $command;
  my $tfapid;
  my $tfaprocess;

  # Stop the tools first
  tfactlshare_stop_all_tools ($tfa_home); 

  # If its a receiver node, first stop the receiver
  my $is_receiver = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "RUN_MODE");
  if ( $is_receiver eq "receiver" ) { 
    tfactladmin_manage_receiver("stopweb");
  } 

  # Set the statusflag to stop TFA
  # before we do anything else lets make sure it is not already stopped

  open (IN, '<', $statusfile) or die "Can't open file $statusfile: $!\n";
  read IN, $line, 20;
  if ($line =~ /stopped/) {
      $tfapid=get_tfa_pid($tfa_home);
      $tfaprocess = '';
      if (!$IS_WINDOWS && ($tfapid ne '')) {
          $tfaprocess = `ps -f -p $tfapid | grep -v PID`;
      }
      if ( $tfaprocess ne '' && $tfaprocess ne "null"){
          dbg(DBG_WHAT, "TFA Process Still running : stopped in $statusfile\n");
          dbg(DBG_WHAT, "Killing TFAMain process with ID $tfapid\n");
          stop_pid($tfapid);
          dbg(DBG_NOTE, "TFAmain Force Stopped Successfully : status mismatch\n");
      }
      dbg(DBG_NOTE, "TFA Stopped Successfully\n");
      return SUCCESS;
  }
  close IN;

  $command = "echo stop > $statusfile";
  my $counter = 0;
  my $stopped = 0;
  system($command);

  if($IS_WINDOWS){
    #Kill the TFAMain process 
    tfactlwin_stop_tfa($tfa_home);
  }else{
    sleep(5);
    while (checkTFAMain($tfa_home) == SUCCESS && $counter lt 3 ) {
      dbg(DBG_NOTE, "TFA is running  - Will wait 5 seconds (up to 3 times)  \n");
      sleep 5;
      $counter++;
    }
    if ($counter le 3) {
      dbg( DBG_WHAT , "Reading the status file to check for stopped\n");
      sleep(10);
      open (IN, '<', $statusfile) or die "Can't open file $statusfile: $!\n";
      read IN, $line, 20;
      close IN;
      #$tfapid=`ps -ef | grep "TFAMain"| grep -v grep | awk '{print \$2}'`;
      $tfapid=get_tfa_pid($tfa_home);
      if ($tfapid ne '') {
        $tfaprocess = `ps -f -p $tfapid | grep -v PID`;
      }

      if ($line =~ /stopped/) {
       if ($tfaprocess ne '') {
         dbg(DBG_WHAT, "TFA Failed to stop Cleanly\n");
       } else {
         dbg(DBG_NOTE, "TFA Stopped Successfully\n");
         return SUCCESS;}
      }
    } else {
       dbg(DBG_WHAT, "TFAMain Failed to respond to stop action\n");
    }
    #$tfapid=`ps -ef | grep "TFAMain"| grep -v grep | awk '{print \$2}'`;
    $tfapid=get_tfa_pid($tfa_home);
    $tfaprocess = '';
    if ($tfapid ne '') {
      $tfaprocess = `ps -f -p $tfapid | grep -v PID`;
    }
    if ( $tfaprocess ne '' && $tfaprocess ne "null"){
      dbg(DBG_WHAT, "Killing TFAMain process with ID $tfapid\n");
      stop_pid($tfapid);
      dbg(DBG_NOTE, "TFAmain Force Stopped Successfully\n");
    }
    dbg(DBG_NOTE, "TFA Stopped Successfully\n");
  }
  return SUCCESS;
}

sub stop_pid
{
  my $pid = shift;
  if ($^O eq 'MSWin32') # Windows
  {
    system("taskkill /F /PID $pid");
  }
  else # Unix
  {
    kill 9, $pid || warn "could not kill process $pid: $!";
  }
}

sub saveSmtpProperties {
	my $tfa_home = shift;
	my $ref = shift;
	my %data = %{$ref};

	my $properties = catfile($tfa_home, "internal", "smtp.properties");
	sysopen(SMTP, $properties, O_WRONLY|O_TRUNC|O_CREAT, 0600) or return "Couldn't open file $properties : $!\n";
	my $key;
	my $value;
	while ( ( $key, $value ) = each %data ) {
		$value = "" if ($value eq "-");
		$value = "" if ($key eq "smtp.password");
		print SMTP "$key=$value\n";
	}
	close(SMTP);	

	my $localhost = tolower_host();
	my $message = "$localhost:savesmtpproperties";
	my $command = buildCLIJava($tfa_home, $message);
	my $line;
	my @cli_output = tfactlshare_runClient($command);

	foreach $line ( @cli_output ) {
		if ($line eq "DONE") {
		} else {
			print "$line\n";
		}
	}
}

sub saveSmtpPaswd {
	my $tfa_home = shift;

	# Check if TFA is running by connecting to TFA Server
	if ( checkTFAMain($tfa_home) == FAILED) {
		return;
	}

	# Prepare TFA Server Message
	my $localhost = tolower_host();
	my $message = "$localhost:smtppaswd";
	my $command = buildCLIJava($tfa_home, $message);

	# Prompt Password
	my $paswd = promptForPassword("SMTP Server", 1);
	my $properties = catfile($tfa_home, "internal", ".smtp.paswd");
	sysopen(SMTP, $properties, O_WRONLY|O_TRUNC|O_CREAT, 0600) or return "Couldn't open file $properties : $!\n";
	print SMTP "smtp.password=$paswd\n";
	close(SMTP);	

	# Send Notification to TFA Daemon
	my $line;
	my $status = 0;
	my @cli_output = tfactlshare_runClient($command) or die "Failed to save SMTP Password $properties : $!\n";

	foreach $line ( @cli_output ) {
		if ($line eq "DONE") {
			$status = 1;
		} else {
			print "$line\n";
		}
	}
	
	if ($status) {
		print "\n\nSMTP Password successfully updated\n";
	} else {
		print "\n\nFailed to update SMTP Password. Please try again\n";
	}

	# Remove File
	END {
		if ( -f $properties ) {
			unlink($properties) or print "Could not remove $properties : $!\n";
		}
	}
}

sub updateSmtpProperties {
	my $tfa_home = shift;

	if (isTFARunning($tfa_home) == FAILED) {
		return;
	}

	my $ref = tfactlshare_getSmtpProperties($tfa_home);
	my %data = %{$ref};
	my ($key, $value);

	my $update = 0;
	my $continue = 1;
	do {
		tfactlshare_printSmtpProperties($tfa_home, \%data);
		print "\nEnter the SMTP property you want to update : ";
      		chomp($key = <STDIN>);
		if (exists($data{$key})) {
			if ( $key eq "smtp.password" ) {
				print "\n";
				saveSmtpPaswd($tfa_home);
			} else {
				print "\nEnter value for $key : ";
				chomp($value = <STDIN>);
				if ( $value ) {
					$data{$key} = $value;
					print "\nSMTP Property $key updated with $value\n";
					$update = 1;					
				}
			}
		} else {
			if ($key) {
				print "\nSMTP Property $key not found\n";
			} else {
				print "\nSMTP Property can't be NULL\n";
			}
		}

		print "\nDo you want to continue ? [Y]|N : ";
		chomp($continue = <STDIN>);

		if ( $continue eq "n" || $continue eq "N" ) {
			$continue = 0;
		} else {
			$continue = 1;
		}
	} while ($continue != 0);

	if ($update == 1) {
		saveSmtpProperties($tfa_home, \%data);
	}
}

sub restServices {
	my $tfa_home = shift;
	my $args = shift;
	my $cmd;
	my $retval = SUCCESS;

	my $script = catfile($tfa_home, "bin", "restServices.pl");

        if ( -f $script ) {
		my $perl = tfactlshare_getPerl($tfa_home);
		$args = "-tfa_home $tfa_home $args";
        	$cmd = "$perl $script $args";
        }

	my $pid = fork ();
	if ($pid == 0) {
		exec("$cmd");
	} else {
		waitpid($pid,0);
		exit(1) if ( $? != 0 );
	}
	$retval = $? >> 8;
	return $retval;
}

sub stopORDS {
	my $pid = `ps -ef | grep 'ords.war standalone' | grep -v grep | awk '{print \$2}'`;
	if ( $pid > 0 ) {
		print "Stopping TFA ORDS Process $pid";
		stop_pid($pid);
	}
}

sub uninstallTFA {

        my $tfa_home = shift;
        my $uninistallArgs = shift;

        if ( ! $uninistallArgs ) {
                $uninistallArgs = "-local";
        }

	if ( $ISCLOUD ) {
		my $localhost = tolower_host();
		print "\nDe-configuring TFA Non-Daemon on $localhost :\n\n";
		my $homedir = getHomeDirectory();
		my $home_tfa = catdir($homedir, ".tfa");
		my $paramfile = catfile($home_tfa, "tfa_setup.txt");

		my $tfa_base;
		if ( -f $paramfile ) {
			$tfa_base = getTFABase($paramfile);
		}

		if ( -d "$tfa_base" ) {
			print "Removing TFA_BASE $tfa_base...\n";
			rmtree "$tfa_base";
		}
		
		if ( -d "$home_tfa" ) {
			print "Removing $home_tfa...\n";
			rmtree "$home_tfa";
		}

		if ( $IS_ADE ) {
			if ( -d "$homedir" ) {
				print "Removing $homedir...\n";
				rmtree "$homedir";
			}

			my $tfactl = catfile($ENV{ORACLE_HOME}, "bin", "tfactl" );
			unlink $tfactl if ( -f "$tfactl" );
		}
		return;	
	} 

	$uninistallArgs = "$uninistallArgs -tfa_home $tfa_home";

        my $uninstallScript;
        my $command;

        if ( getTFARunMode($tfa_home) eq "RECEIVER" ) {
              tfactladmin_manage_receiver("stopweb");
              tfactlshare_stop_TFARMain($tfa_home);
	}     
        if($IS_WINDOWS){
          $uninstallScript = catfile($tfa_home,"bin","uninstall.pl");
        }else{
          $uninstallScript = catfile($tfa_home,"bin","uninstalltfa");  
        }
        if ( -f $uninstallScript ) {
          if($IS_WINDOWS){
            my $PERL = tfactlshare_getPerl($tfa_home);
            $command = "$PERL $uninstallScript $uninistallArgs -silent";
            system($command);
          }else{
            $command = "$uninstallScript $uninistallArgs -silent";
            open( UNINSTALL, "| $command") or die "\nUnable to run TFA Uninstall Script. Please try later.\n";

            while ( <UNINSTALL> ) {
                    print "$_\n";
            }
            close (UNINSTALL);
          }
        }
        exit 0;
}

############## Send Uninstall Update ###################
sub sendUninstallUpdate
{
  my $tfa_home = shift;
  my $localhost = tolower_host();

  if (isTFARunning($tfa_home) == FAILED) {
        print "Unable to update other nodes about TFA Uninstall\n";
        return FAILED;
  }

  my $message ="$localhost:sendselfuninstalltohost:";
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

#
# Subroutine to collect TFA Diagnostics
#
sub collectTFADiagnostics {
	my $tfa_home = shift;
  my $diagnoseScript;
  if($IS_WINDOWS){
    $diagnoseScript = catfile($tfa_home, "bin", "tfadiagnosticsDriver.pl");
    if ( -f $diagnoseScript ) {
      if ( lc($DIAGNOSEARGS)  !~ /-h[^\S]/ && lc($DIAGNOSEARGS) !~ /-help/ ) {
        print "\nRunning TFA Diagnostics...\n";
      }
      my $PERL = tfactlshare_getPerl($tfa_home);
      my $diagnostics = "$PERL $diagnoseScript -tfa_home $tfa_home $DIAGNOSEARGS";
      system($diagnostics);
    }
  }else{
    $diagnoseScript = catfile($tfa_home, "bin", "tfadiagnostics.sh");
    if ( -f $diagnoseScript ) {

      if ( lc($DIAGNOSEARGS)  !~ /-h[^\S]/ && lc($DIAGNOSEARGS) !~ /-help/ ) {
        print "\nRunning TFA Diagnostics...\n";
      }

      my $pid = fork ();

      if ($pid == 0) {
        my $SH = catfile("", "bin", "sh");
        exec("$SH $diagnoseScript -tfa_home $tfa_home $DIAGNOSEARGS");
      } else {
        waitpid($pid,0);
        exit(1) if ( $? != 0 );
      }
    }
  }
}

#
# Subroutine to Sync TFA Nodes
#
sub syncTFANodes {
	my $tfa_home = shift;
	my $args = shift;
	$args = "$args -tfa_home $tfa_home";

	my $syncScript;
	my $cmd;

	if ($IS_WINDOWS) {
		$syncScript = catfile($tfa_home, "bin", "synctfanodes.pl");
		if (-f $syncScript) {
			my $perl = tfactlshare_getPerl($tfa_home);
			$cmd = $perl . " " . $syncScript . " " . $args;			
			#print "$cmd";
		}
	} else {
		$syncScript = catfile($tfa_home, "bin", "synctfanodes.sh");

        if ( -f $syncScript ) {
        	$cmd = catfile("", "bin", "sh") . " $syncScript $args";
        }
    }

    my $pid = fork ();
	if ($pid == 0) {
		exec("$cmd");
	} else {
		waitpid($pid,0);
		exit(1) if ( $? != 0 );
	}
}

sub configFromResp {
   my $tfa_home = shift;
   my $rspfile = shift;
   my $PERL = tfactlshare_getPerl($tfa_home);
   my @force = ('repositorydir','reposizeMB');
   my $forceflag = "";
   my $command = "";

   tfactlshare_trace(3, "tfactl (PID = $$) tfactladmin configFromResp file $rspfile PERL $PERL", 'y', 'y');

   $rspfile = catfile("","etc","oracle","tfa.rsp") if (not length $rspfile); 

   if ( -f $rspfile ) {
      print "Setting COnfiguration using file : $rspfile\n";
      open (RSPFILE, "<", "$rspfile");
      while (<RSPFILE>) {
         if ($_ !~ /^#|^install_|^\s*$/) {
           chomp;
           $_ = trim ($_);
           my  ($key, $val) = split ('=');
           tfactlshare_trace(3, "tfactl (PID = $$) tfactladmin configFromResp key $key val $val", 'y', 'y');
           $forceflag = "-force" if (grep /^$key$/, @force); 
           tfactlshare_trace(3, "tfactl (PID = $$) tfactladmin configFromResp forceflag $forceflag", 'y', 'y');
           $command = "$PERL $tfa_home/bin/tfactl.pl set $key=$val $forceflag";
           tfactlshare_trace(3, "tfactl (PID = $$) tfactladmin configFromResp command $command", 'y', 'y');
           print "Running Command $command\n";
           system($command);
         }
         $forceflag = "";
      }
      close (RSPFILE);
   } else {
     print "Unable to open Configuration file : $rspfile\n";
   }
}

sub syncPatchFiles {
	my $tfa_home = shift;

	if (isTFARunning($tfa_home) == FAILED) {
		print "Unable to sync files across cluster after upgrading TFA\n";
		return FAILED;
	}

	my $localhost = tolower_host();
	my $message ="$localhost:syncpatch";
	my $command = buildCLIJava($tfa_home, $message);
	my $line;
	my @cli_output = tfactlshare_runClient($command);

	foreach $line ( @cli_output ) {
		if ($line eq "DONE") {
			return SUCCESS;
		} else {
			print "$line\n";
		}
	}
	return FAILED;
}

#======================= runGUI ==========================#
sub runGUI
# 
#  Set the start flag in the status.txt file then ..
#  Builds the start command line for the Java and then execs it so that 
#  We do not wait for a return
#  Once that is done we rty to connect to TFA to make sure it is started.
{
  dbg(DBG_WHAT, "In runGUI TFA\n");
  my ($tfa_home, $paramfile) = @_;

  #my $flag = 1;
  #while ($flag eq 1) {
  #  if ( sockConnect($PORT) eq CONNFAIL ) {
  #    print "Port : $PORT was not in use\n";
  #    $flag=0;
  #  } else {
  #    $PORT ++;
  #  }
  #}
  # Noe set the port into the parameter file.
  #$^I = '.bak'  # Call for in-place editing; make backups with a .bak suffix

  #while (<$paramfile>) {
  #  s/PORT=.*/PORT=$PORT/;
  #  print;
  #}

  #Build the command line for GUI java

  my $tfa_jar = catfile("$tfa_home","jlib","RATFA.jar");
  my $tfa_bd_jar = catfile("$tfa_home","jlib","je-6.4.25.jar");
  my $jdbc_jar = catfile("$tfa_home","jlib","ojdbc5.jar");
  my $oraclepkiJar = catfile("$tfa_home","jlib","oraclepki.jar");
  my $shareJar = catfile("$tfa_home","jlib","share.jar");
  my $commonsJar = catfile("$tfa_home","jlib","commons-io-2.6.jar");

  #  my $java = "$tfa_home/jre/bin/java";
  my $java = "/usr/bin/java";
  my $classpath = "$tfa_jar$PSEP$tfa_bd_jar$PSEP$jdbc_jar$PSEP$oraclepkiJar$PSEP$shareJar$PSEP$commonsJar";
  my $class =  "oracle.rat.tfa.view.TraceFileAnalyzer";
  my $output = " > ".catfile($tfa_home,"log","guilog") ." 2>&1 &";

  $ENV{CLASSPATH}=$classpath;
  my $commandline = "$java -Xms32m -Xmx256m $class $tfa_home  $output";

  dbg(DBG_VERB,"command used : $commandline\n");
  system ($commandline);
}
# End runGUI

sub checkAutoPatching 
{
  my $tfa_home = shift;
  my $localhost=tolower_host();
  my $message ="$localhost:checkautopatchingenabled";
  dbg(DBG_VERB, "Running Check through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$message);
  my $line;

  my $tb = Text::ASCIITable->new();
  $tb->setCols("Host", "Auto Patching");
  $tb->setOptions({"outputWidth" => $tputcols});
  print "\n";
  my $nodename;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
    my ($hostname, $value) = split(/!/, $line);
    if ($value eq "true") {
      $tb->addRow($hostname, "ON");
    }
    elsif ($value eq "false") {
      $tb->addRow($hostname, "OFF");
    }
  }
  print $tb;
  return SUCCESS;
}

sub checkKeyStores
{
  my $tfa_home = shift;
  my $localhost=tolower_host();
  my $message ="$localhost:checkkeystoresupdated";
  dbg(DBG_VERB, "Running Check through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$message);
  my $line;

  my $tb = Text::ASCIITable->new();
  $tb->setCols("Host", "Key Stores Updated");
  $tb->setOptions({"outputWidth" => $tputcols});
  print "\n";
  my $nodename;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
    #if ($line eq "DONE") {
    #  print $tb;
    #  return SUCCESS;
    #}
    #else {
    my ($hostname, $value) = split(/!/, $line);
    if ($value eq "true") {
      $tb->addRow($hostname, "ON");
    }
    elsif ($value eq "false") {
      $tb->addRow($hostname, "OFF");
    }
    #}
  }
  print $tb;
  return SUCCESS;
}

#
#======================= cleanTFAMain ==========================#
#
sub cleanTFAMain
{
  dbg(DBG_VERB, "In Clean TFA\n");
}

sub isCollectorNodeRegistered
{
  my ($tfa_home,$cnode) = @_;
  my $localhost=tolower_host();
  my $message = "$localhost:getcollectornodes";
  dbg(DBG_VERB, "Running Check through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$message);
  my $line;
  #Run the command in local node and work on output
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output ) {
    #print "$line\n";
    my @p = split /:/,$line;
    my $key = $p[1];
    chomp($key);
    chomp($cnode);
    #print "localhost $cnode\n"; 
    dbg(DBG_WHAT,"We got : $line\n");
    if (trim($key) eq trim($cnode)) {
      return SUCCESS;
    }
  }
  return FAILED;
}

#
#==== Send File to Receiver ====#
#
sub sendFileToReceiver
{
  my ($tfa_home, $fileName, $is_commandline, $remoteport) = @_;
  dbg(DBG_WHAT,  "In sendFileToReceiver for :: $fileName\n");
  my $localhost=tolower_host();
  #Check whether TFA Main is running or not on receiver NODE
  if (isTFARunning($tfa_home) == FAILED) {
    exit 0;
  }
  my $localhost=tolower_host();
  my $hostName = $localhost;
  if ($hostName =~ /\./) {
    my @values = split(/\./, $hostName);
    $hostName = @values[0];
  }
  if ($is_commandline == 1) {
    my $sudo_user = $ENV{SUDO_USER};
    my $sudo_command = $ENV{SUDO_COMMAND};
    if ( $sudo_user && $sudo_command =~ /tfactl/ ) {
      print "User $sudo_user does not have permissions to add receiver. Please run the command as root\n";
      return FAILED;
    }
  }
  my $actionmessage = "$localhost:sendfiletor:$fileName:$hostName:$is_commandline:$remoteport\n";
  dbg(DBG_WHAT, "Running sendFileToReceiver through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$actionmessage);
  dbg(DBG_VERB, "$command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output ) {
    if ( $line eq "SUCCESS") { 
       return SUCCESS;
    }
  }
  dbg(DBG_WHAT,"Could not add receiver\n");
  return FAILED;
}

#==================================#
sub tfactladmin_addplugin
{
  my $args = shift;
  my $localhost = tolower_host();

  my @parts = split(":", $args);
  my $pluginname = $parts[0];
  my $pluginpath = $parts[1];

  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  my $tool_dir = catfile($tfa_base, "suptools", "$hostname", "oswbb");
  my $tool_base = catfile($tfa_base, "suptools", "$hostname", "oswbb", $current_user);
  my $adir = catfile($tool_base, "archive");

  system("$pluginpath > $adir/$pluginname.tfajson.out & ");
}

  
#==================================#
sub tfactladmin_processbug
{
  my $args = shift;
  my $localhost = tolower_host();

  my @parts = split(":", $args);
  my $bugname = $parts[0];
  my $bugnum = $parts[1];

  my $actionargs="processbug=$bugnum~nthreads=5";
  my $actionmessage = "$localhost:processbug:$localhost";
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
         print "success";
         return SUCCESS;
     }
     elsif ($line eq "DONE"){
        print "Success\n";
     } else {
         print "FAIL\n";
     }
  }
  dbg(DBG_WHAT,"Could not add receiver\n");
  return FAILED;

}

########
## NAME
##   tfactladmin_is_receiver_setup
##
## DESCRIPTION
##   This sub checks for ssl setup and acfs mount as repository for DSC mode
##
## PARAMETERS
##   tfa_home
## RETURNS
#    1 if acfs is not setup as repsoditory for DSC mode
##   0 if its regular install ( non dsc)
## NOTES/USAGE
##
#########
sub tfactladmin_is_receiver_setup
{
  #Start receiver services only after generating C & R certs
  #For DSC, check for acfs setup also
  my $tfa_home = shift;
  my $rstatus = 0;
  my $sslfile = catfile($tfa_home, "internal", "ssl.properties");
  my $rsslfile = catfile($tfa_home, "receiver", "internal", "r.ssl.properties");
  my $sslKey = 0;
  #For now check only existance of rsslfile as sslkey is not there in it
  if ( -r $sslfile && -r $rsslfile ) {
    $sslKey = tfactlshare_getConfigValue($sslfile,"sslKey");
  }
  if ( $sslKey == 1 ) {
    my $cc = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "CLUSTER_CLASS");
    if ($cc eq "DOMAINSERVICES") {
      if ( -f catfile($tfa_home, "internal", ".tfa_acfs_setup_finished" )) {
        $rstatus = 1;
      } 
    }
    else {
      $rstatus = 1;
    }
  }
  print "Receiver setup status: $rstatus\n";
  return $rstatus;
}

########
## NAME
##   tfactladmin_startReceiverServices
##
## DESCRIPTION
##   This sub starts all the receiver services which include Receiver connection acceptor,
#    zookeeper, kafka and consumer threads
##
## PARAMETERS
##   tfa_home
## RETURNS
##  none
## NOTES/USAGE
##
#########
sub tfactladmin_startReceiverServices
{
    my $tfa_home = shift;
    my $localhost = tolower_host();
    if ( checkTFAMain($tfa_home) != SUCCESS ) {

      dbg(DBG_VERB, "Not starting receiver services as TFAMain is not running\n");
      return;
    }
    if ( !tfactladmin_is_receiver_setup($tfa_home) ) {
      dbg(DBG_VERB, "Not starting receiver services as receiver configuration is not set\n");
      return;
    }

    my $crs_home =  get_crs_home($tfa_home);
    my $cc = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "CLUSTER_CLASS");

    if ($cc eq "DOMAINSERVICES" &&  ! tfactlshare_check_acfs($crs_home, "/mnt/oracle/tfa") )
    {

      print "ERROR: ACFS is not running. Failed to start TFA receiver services.\n";
      return;
    }

    dbg(DBG_VERB, "Starting receiver services\n");
    my $tfa_setup_file = catfile($tfa_home,"tfa_setup.txt");
    my $java_home = get_java_home($tfa_home, $tfa_setup_file);
    $ENV{"JAVA_HOME"} = $java_home;
    tfactlshare_start_TFARMain($tfa_home);
    tfactlshare_autostart_tomcat_in_dsc($tfa_home);
    startService("receiver",$localhost,$localhost,1);
    tfactladmin_generate_rprop($tfa_home);
}

########
# NAME
#  tfactladmin_stopReceiverServices 
#
# DESCRIPTION
#   This sub stops all the receiver services which include Reciver connection acceptor,
#    zookeeper, kafka and consumer threads
### PARAMETERS
#   tfa_home
# RETURNS
#  none
# NOTES/USAGE
#
########

sub tfactladmin_stopReceiverServices
{
  my $tfa_home = shift;
  my $localhost = tolower_host();
  tfactladmin_stopService("receiver",$localhost, $localhost,1);
  tfactladmin_manage_receiver("stopweb");
  tfactlshare_stop_TFARMain($tfa_home);
}

#==== Manage receiver actions =====#
#
sub tfactladmin_manage_receiver
{
  my $args = shift;
  my $localhost = tolower_host(); 
  my $crs_home;
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");
  #it will pick tomcat jars from tfa_home or GI_home depending on the type of installation
  if ( $install_type eq "GI" ){
    $crs_home =  get_crs_home($tfa_home);
  } 
  else {
    $crs_home = $tfa_home;
  }

  my @flags = split(":", $args);

  if ( $flags[0] eq "start" )
  { # Start receiver
     tfactladmin_startReceiverServices($tfa_home);
  }
   elsif ( $flags[0] eq "stop" )
  {
     tfactladmin_stopReceiverServices($tfa_home);
  }
   elsif ( $flags[0] eq "starttomcat" )
  {
    my $port = $flags[1];
    my $tfa_setup_file = catfile($tfa_home,"tfa_setup.txt");
    my $is_receiver = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "RUN_MODE");
    if ( $is_receiver eq "receiver" ) {
      tfactlshare_start_tomcat($tfa_home);
    }
     else
    {
      print "Not running in receiver mode\n";
    }

  }
   elsif ( $flags[0] eq "webadmin" )
  {
    my $cc = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "CLUSTER_CLASS");
   # if( $cc ne "DOMAINSERVICES") {
    #   print "This command is applicable only in DSC mode\n";
    #   return FAILED;
   # }
  
    my $key = $flags[1];
    my $is_receiver = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "RUN_MODE");
    if ( $is_receiver eq "receiver" ) {
      my $tfa_base = tfactlshare_get_repository_location($tfa_home);
      if ( $cc eq "DOMAINSERVICES") {
        $tfa_base = "/mnt/oracle/tfa";
      }
      my $java_home = get_java_home ($tfa_home);
      my $java = catfile("$java_home","bin","java");
      $ENV{"CATALINA_HOME"} = catfile($tfa_home, "tomcat");
      $ENV{"CATALINA_BASE"} = catfile($tfa_home, "tomcat");
      my $CATALINA_HOME = $ENV{"CATALINA_HOME"};
      my $CATALINA_BASE = $ENV{"CATALINA_BASE"};
      my $file = catfile($CATALINA_BASE,"r.properties");
      tfactlshare_update_rprop($tfa_home,"r.key","$key"); 
      tfactladmin_setperm_rprop($file);
    }
     else
    {
      print "Not running in receiver mode\n";
    }

  }
   elsif ( $flags[0] eq "webport" )
  {
    my $rweb_port = $flags[1];
    my $is_receiver = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "RUN_MODE");
    if ( $is_receiver eq "receiver" ) {
      # update new port in rweb_port.txt
      my $rwp = catfile($tfa_home,"internal","rweb_port.txt");
      if (-e $rwp) {
	 system("rm -f $rwp");
      }
      open(WF,">$rwp");
      print WF $rweb_port;
      close(WF);
      # update port in tomcats server.xml
      my @kv = ("TFA_SSL_PORT", $rweb_port);

      my $serverxml = "$tfa_home/tomcat/conf/server.xml";
      my $tmp_serverxml = "$tfa_home/tomcat/conf/server.xml.tmpl";
      tfactladmin_update_server_xml($tmp_serverxml,$serverxml,@kv);


      #update new port in r.properties
      my $tfa_base = tfactlshare_get_rbase($tfa_home);
      $ENV{"CATALINA_HOME"} = catfile($tfa_home, "tomcat");
      $ENV{"CATALINA_BASE"} = catfile($tfa_home, "tomcat");
      my $CATALINA_HOME = $ENV{"CATALINA_HOME"};
      my $CATALINA_BASE = $ENV{"CATALINA_BASE"};
      my $localhost = tolower_host();
      my $rp = catfile($tfa_home,"receiver","internal","rport.txt");
      my $r_port = `cat $rp`;
      my $file = catfile($CATALINA_BASE,"r.properties");
      if (-e $file) {
	#get thekey from r.properties
	my $key = tfactlshare_getConfigValue($file,"r.key");
	chomp($key);

	# remove the old r.properties
	system("rm -f $file");
      
	# create new r.properties file 
	open(WF, ">$file");
	print WF "r.cname=tfarweb\n";
	print WF "r.host=$localhost\n";
	print WF "r.port=$r_port\n";
	print WF "r.port_rweb=$rweb_port\n";
	print WF "r.key=\n";
	print WF "r.tfa_home=$tfa_home\n";
        print WF "r.tfa_base=$tfa_base\n";
	close(WF);
        tfactladmin_setperm_rprop($file);
      }
      #restart tomcat 
      tfactladmin_manage_receiver("stopweb");
      
    }
     else
    {
      print "Not running in receiver mode\n";
    }

  }
   elsif ( $flags[0] eq "startweb" )
  { # Start tomcat
    my $port = $flags[1];
    my $is_receiver = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "RUN_MODE");
    if ( $is_receiver eq "receiver" ) {
      my $tfa_base = tfactlshare_get_rbase($tfa_home);
      my $java_home = get_java_home ($tfa_home);
      my $java = catfile("$java_home","bin","java");
      my $CATALINA_BASE = catfile($tfa_home, "tomcat");
      my $localhost = tolower_host();
      my $key = tfactladmin_get_key($tfa_home, "tfarweb");
      my $rp = catfile($tfa_home,"receiver","internal","rport.txt");
      my $r_port = `cat $rp`;
      my $file = catfile($CATALINA_BASE,"r.properties");
      open(WF, ">$file");
      print WF "r.cname=tfarweb\n";
      print WF "r.host=$localhost\n";
      print WF "r.port=$r_port\n";
      print WF "r.port_rweb=$port\n";
      print WF "r.key=\n";
      print WF "r.tfa_home=$tfa_home\n";
      print WF "r.tfa_base=$tfa_base\n";
      close(WF);
      tfactladmin_setperm_rprop($file);
      tfactlshare_start_tomcat($tfa_home);
    }
     else
    {
      print "Not running in receiver mode\n";
    }
  }
   elsif ( $flags[0] eq "stopweb" )
  {
    my $CATALINA_BASE = catfile($tfa_home, "tomcat");
    my $tomcat_lck = catfile($tfa_home,"tomcat","internal", ".tomcat.lck");
    if ( ! -r $tomcat_lck )
    {
      print "Receiver web is not running\n";
    }
     else
    {
      
      my $pid = `cat $tomcat_lck`;
      system("rm -f $tomcat_lck");
      chomp($pid);
      if ( $pid )
      {
        my $cnt = kill 15, $pid;
		my $retvalue ;	
		for(my $i = 0 ; $i < 3 ; $i++)
		{
			$retvalue = kill 0, $pid;
			if ( $retvalue == 1 )
			{	sleep(1);	}
			else
			{	last;		}	
		}
		$retvalue = kill 0, $pid;
		if ( $retvalue != 0 )
		{	$cnt = kill 9, $pid;	}
	    print "Killed web process ($cnt)\n";
	  }
      unlink ($tomcat_lck);
    }
  
  }
}

sub tfactladmin_generate_rprop
{
      my $tfa_home = shift;
      my $tfa_base = tfactlshare_get_rbase($tfa_home);
      my $java_home = get_java_home ($tfa_home);
      my $java = catfile("$java_home","bin","java");
      $ENV{"CATALINA_HOME"} = catfile($tfa_home, "tomcat");
      $ENV{"CATALINA_BASE"} = catfile($tfa_home, "tomcat");
      my $CATALINA_HOME = $ENV{"CATALINA_HOME"};
      my $CATALINA_BASE = $ENV{"CATALINA_BASE"};
      my $localhost = tolower_host();
      my $rp = catfile($tfa_home,"receiver","internal","rport.txt");
      my $r_port = `cat $rp`;

      my $rwp = catfile($tfa_home,"internal","rweb_port.txt");
      my $port = `cat $rwp`;
      
      my $rwp_ssl = catfile($tfa_home,"internal","rweb_port_ssl.txt");
      my $port_ssl = `cat $rwp_ssl`;
      
      my $file = catfile($CATALINA_BASE,"r.properties");
      my $web_key= "";
      if (-e $file) {
         $web_key = tfactlshare_getConfigValue($file, "r.key");
         system("rm -f $file");
      }
      open(WF, ">$file");
      print WF "r.cname=tfarweb\n";
      print WF "r.host=$localhost\n";
      print WF "r.port=$r_port\n";
      print WF "r.port_rweb=$port\n";
      print WF "r.port_rweb_ssl=$port_ssl\n";
      print WF "r.key=$web_key\n";
      print WF "r.tfa_home=$tfa_home\n";
      print WF "r.tfa_base=$tfa_base\n";
      close(WF);
      tfactladmin_setperm_rprop($file);

}

sub tfactladmin_addFileTypes
{
my ($tfa_home,$ftypes) = @_;
print "tfa_home:$tfa_home\n";
print "ftypes:$ftypes\n";
my $localhost = tolower_host();
        my $file_name = catfile($tfa_home, "internal","producer_filetype.txt");
        if ( -e $file_name){
            system("rm -f $file_name");
        }
      my $actionmessage = "$localhost:changefiletypes:$ftypes";
      # send message to stop producer and dump file list
      dbg(DBG_WHAT, "Running addReceiver through Java CLI\n");
      my $command = buildCLIJava($tfa_home,$actionmessage);
      dbg(DBG_VERB, "$command\n");
      my $line;
      my @cli_output = tfactlshare_runClient($command);
      foreach $line ( @cli_output )
      {
         print "$line\n";
         if ( $line eq "SUCCESS" ) {
             return SUCCESS;
         }
         elsif ($line eq "DONE"){
            print "Success\n";
         } else {
             print "FAIL\n";
         }
      }

return SUCCESS;
}

#==== Start/stop service ====#
sub tfactladmin_manageService
{
  my ($action) = @_;
  my $localhost = tolower_host(); 
  my @temp = tfactlshare_getListOfAllRececivers($tfa_home);
  my @receivers = sort @temp;
  if ( scalar(@receivers) <= 0 ) { #Double check
    print "No receivers added. Please add receivers and then try start receiver.\n";
    return FAILED;
  }
  if ( $action eq "start" ) {
    #Get one of the receiver and use current machine as producer    
    #Start services. Start only Producer as consumer run on R side always.
    #startService("receiver",$receivers[0], $receivers[0],1);
    startService("producer",$localhost, $receivers[0],1);
    return SUCCESS;
  }
  elsif ( $action eq "stop" ) {
    #Stop only Producer as consumer run on R side always
    tfactladmin_stopService("producer",$localhost, $receivers[0],1);
    #stopService("receiver",$receivers[0], $receivers[0],1);
    return SUCCESS;
  }
  elsif ( $action eq "status" ) {
    #Show producer status
    tfactladmin_getProducerStatus();       
    return SUCCESS;
  }

  else {
    print "Receiver action $action not found\n";
    return FAILED;
  }
  return FAILED;
}


#==== Start Receiver/Producer ====#
#Receiver receiver in R. Producer start in C.
sub startService
{
  my ($type,$hostName,$server,$is_commandline) = @_;
  dbg(DBG_WHAT,  "startService: Start $type in $hostName( $server )\n");
  my $localhost=tolower_host();

  if ($hostName =~ /\./) {
    my @values = split(/\./, $hostName);
    $hostName = @values[0];
  }
  
  if ($is_commandline == 1) {
    my $sudo_user = $ENV{SUDO_USER};
    my $sudo_command = $ENV{SUDO_COMMAND};
    if ( $sudo_user && $sudo_command =~ /tfactl/ ) {
      print "User $sudo_user does not have permissions to run the command. Please run the command as root\n";
      return FAILED;
    }
  }
  my $actionargs = "server=$server~is_commandline=$is_commandline~remoteport=-1";
  my $actionmessage;
  if ( $type eq "producer" ) {
    $actionmessage = "$localhost:startproducer:$hostName";
  }
  elsif ( $type eq "receiver" ) {
    $actionmessage = "$localhost:startreceiver:$hostName";
  }
  else {
    print "Failed to start service $type in $hostName\n";
    return FAILED;
  }

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

  $actionmessage = "$actionmessage~$actionargs";
  dbg(DBG_WHAT, "Starting $type through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$actionmessage);
  dbg(DBG_VERB, "$command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command,"2>&1");
  foreach $line ( @cli_output ) {
    #print "output = $line\n";
    #if($line eq "FAIL") sleep(10) ??
    if ( $line eq "DONE") {
      if ($is_commandline == 1) {
        dbg(DBG_NOTE, "Successfully Started service $type in $hostName\n\n");
      }
      return SUCCESS;
    }
    elsif ( $line =~ /RUNNING/ ) {
      print "$type is already running\n";
      return SUCCESS;
    }
    elsif ($line =~ /FAILED/) {
      print "Failed to start service $type in $hostName\n";
    }
  }
  return FAILED;  
}

#==== Stop Receiver/Producer ====#
sub tfactladmin_stopService
{
  my ($type,$hostName,$server,$is_commandline) = @_;
  dbg(DBG_WHAT,  "stopService: Stop $type in $hostName( $server )\n");
  print "Stoping $type service: Node=$hostName, Server=$server\n";
  my $localhost=tolower_host();
  if ($hostName =~ /\./) {
    my @values = split(/\./, $hostName);
    $hostName = @values[0];
  }
  
  if ($is_commandline == 1) {
    my $sudo_user = $ENV{SUDO_USER};
    my $sudo_command = $ENV{SUDO_COMMAND};
    if ( $sudo_user && $sudo_command =~ /tfactl/ ) {
        print "User $sudo_user does not have permissions to run the command. Please run the command as root\n";
          return FAILED;
    }
  }
  my $actionargs = "server=$server~is_commandline=$is_commandline~remoteport=-1";
  my $actionmessage;
  if ( $type eq "producer" ) {
    $actionmessage = "$localhost:stopproducer:$hostName";
  } 
  elsif ( $type eq "receiver" ) {
    $actionmessage = "$localhost:stopreceiver:$hostName";
  }
  else {
    print "Failed to stop service $type in $hostName\n";
    return FAILED;
  }
  $actionmessage = "$actionmessage~$actionargs";
  dbg(DBG_WHAT, "Starting $type through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$actionmessage);
  dbg(DBG_VERB, "$command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output ) {
    if ( $line eq "DONE") {
      if ($is_commandline == 1) {
        dbg(DBG_NOTE, "Successfully Stopped service $type in $hostName\n\n");
      }
      return SUCCESS;
    }
    elsif ($line =~ /FAILED/) {
      print "Failed to stop service $type in $hostName\n";
    }
  }
  return FAILED;
}

#==== Stop Receiver/Producer ====#
sub tfactladmin_getProducerStatus {
   my $localhost=tolower_host();
   my $actionmessage = "$localhost:getproducerstatus";
   my $command = buildCLIJava($tfa_home,$actionmessage);

   dbg(DBG_VERB, "$command\n");
   my $line;
   
   my $table = Text::ASCIITable->new();
   $table->setCols("Host Name", "Status of Producer");    
   my $tableRowAdded = 0;
  my @cli_output = tfactlshare_runClient($command);  
  foreach $line ( @cli_output ) {
    if ( $line ne "DONE" && $line ne /FAILED/ ) {
	 my @mystr = split(/!/, $line);    
         $table->addRow($mystr[1],$mystr[0]);
         $tableRowAdded = 1;   
    }
    if ( $line eq "DONE") {    
      print "$table";
      return SUCCESS;
    }
    elsif ($line =~ /FAILED/) {
     print "Failed to execute command\n";
    }
  }
  return FAILED;
}

#######removeReceiver############
sub removeReceiver {
  my ($tfa_home, $receiver) = @_;

  if ( $receiver eq "-c" )
  {
    my $rmainf = "$tfa_home/internal/mainreceiver.txt";
    if ( ! -r $rmainf )
    {
      print "ERROR: Failed to read receiver information.\n";
      return FAILED;
    }
    open(RRF, $rmainf);
    while(<RRF>)
    {
      chomp;
      if ( /\w+/ )
      {
        $receiver = $_;
      }
    }
    close(RRF);
  }
  my $receivername = $receiver;
  dbg(DBG_WHAT, "In removeReceiver for :: $receiver\n");
  my $localhost=tolower_host();
  if (isTFARunning($tfa_home) == FAILED) {
        exit 1;
  }
  if ($receiver=~ /\./) {
    my @values = split(/\./, $receiver);
    $receiver = @values[0];
  }
  if ($receiver eq $localhost) {
    print "Cannot remove node itself\n";
    return FAILED;
  }
  #Check whether the receiver you are going to remove is 
  #registered in node where you fired action
  if (tfactlshare_isReceiverRegistered($tfa_home, $receiver)) {
  }
  else {
    print "Cannot remove receiver $receiver as it is not part of TFA receiver cluster.\n";
    return FAILED;
  }
  my $actionmessage = "$localhost:removereceiver:$receiver\n";

  dbg(DBG_WHAT, "Running removeReceiver through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$actionmessage);
  dbg(DBG_VERB, "$command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
    if ( $line eq "SUCCESS") {
      print "Successfully removed receiver : $receivername\n\n";
      print "List of receivers in TFA after remove action: \n";
      printReceivers($tfa_home);
      dbg(DBG_WHAT,"#### Removed Receiver ####\n");
      return SUCCESS;
    }
  }
  dbg(DBG_WHAT,"Could not remove receiver\n");
  return FAILED;
}

sub printDom0IP
{
  my $tfa_home = shift;
  dbg(DBG_VERB, "In printDom0IP\n");
  my $localhost=tolower_host();
  if (isTFARunning($tfa_home) == FAILED) {
        return FAILED;
  }

  dbg(DBG_VERB, "Running printDom0IP through Java CLI\n");
  my $message ="$localhost:printdom0ip";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "Command $command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
    if ( $line eq "DONE") {
      dbg(DBG_WHAT,"#### All Stored Dom0 Private IPs Printed ####\n");
      return SUCCESS;
    }
    else {
      print "$line\n";
    }
  }
  dbg(DBG_WHAT,"Could not print stored Dom0 Private IPs\n");
  return FAILED;

}

sub tfactladmin_restrictProtocol
{
   my ($tfa_home, $protocol, $force) = @_;
    if (isTFARunning($tfa_home) == FAILED) {
      return FAILED;
   }
   my $localhost=tolower_host();
   my $actionmessage = "$localhost:restrictprotocol:$protocol:$force\n";
    dbg(DBG_WHAT, "Running tfactladmin_restrictProtocol through Java CLI\n");
    my $command = buildCLIJava($tfa_home,$actionmessage);
    dbg(DBG_VERB, "$command\n");
    my $line;
    my @cli_output = tfactlshare_runClient($command);
    foreach $line ( @cli_output )
    {
      if ( $line eq "SUCCESS") {
	print "Protocol $protocol restricted from TFA Cluster\n";;
	return SUCCESS;
    }
    else {
      print "$line\n";
    }
  }
  dbg(DBG_WHAT,"Could not restrict protocol\n");
  return FAILED;

}


#
#==== addDom0IP  ====#
#
sub addDom0IP
{
   my ($tfa_home, $host) = @_;
   my $hostname = $host;
   my $localhost=tolower_host();
   dbg(DBG_WHAT,  "In addDom0IP for :: $host\n");
   if (isTFARunning($tfa_home) == FAILED) {
      return FAILED;
   }
   if ( isODAVMGuest() != 1 ) {
    print "Add Dom0 IP allowed only on ODAVMGuest\n";
    return FAILED;
   }

    my $actionmessage = "$localhost:adddom0ip:$host\n";
    dbg(DBG_WHAT, "Running addDom0IP through Java CLI\n");
    my $command = buildCLIJava($tfa_home,$actionmessage);
    dbg(DBG_VERB, "$command\n");
    my $line;
    my @cli_output = tfactlshare_runClient($command);
    foreach $line ( @cli_output )
    {
     if ( $line eq "SUCCESS") {
      dbg(DBG_NOTE, "Successfully added dom0IP: $hostname\n\n");
      print "List of Dom0 Private IPAddresses in TFA : \n";
      printDom0IP($tfa_home);
      dbg(DBG_WHAT,"#### Added Dom0IP ####\n");
      return SUCCESS;
    }
    else {
      print "Failed to add dom0IP: $host\n";
    }
  }
  dbg(DBG_WHAT,"Could not add host\n");
  return FAILED;

}

sub removeDom0IP {
 my ($tfa_home, $host) = @_;
 my $hostname = $host;
 my $localhost=tolower_host();
 dbg(DBG_WHAT,  "In removeDom0IP for :: $host\n");
 if (isTFARunning($tfa_home) == FAILED) {
        return FAILED;;
 }
 if ( isODAVMGuest() != 1 ) {
  print "Remove Dom0 IP allowed only on ODAVMGuest\n";
  return FAILED;
 }
 my $actionmessage = "$localhost:removedom0ip:$host\n";
 dbg(DBG_WHAT, "Running removeHost through Java CLI\n");
 my $command = buildCLIJava($tfa_home,$actionmessage);
 dbg(DBG_VERB, "$command\n");
 my $line;
 my @cli_output = tfactlshare_runClient($command);
 foreach $line ( @cli_output )
 {
   if ( $line eq "SUCCESS") {
      print "Successfully removed dom0IP : $hostname\n\n";
      print "List of Dom0 Private IPAddresses in TFA : \n";
      printDom0IP($tfa_home);
      dbg(DBG_WHAT,"#### Removed Host ####\n");
      return SUCCESS;
   }
 }
   dbg(DBG_WHAT,"Could not remove host\n");
   return FAILED;
}

#
#==== changeRepository  ====#
#
sub changeRepository
{
  my ($tfa_home, $repos, $size, $flag)  = @_; 

  if (isTFARunning($tfa_home) == FAILED) {
        return FAILED;
  }

  my $force = 0;
  $force = 1 if ($flag eq "-force");

  $repos =~ s/[\\\/]$//;
  my $repositoryDir = getCurrentRepository($tfa_home);
  $repositoryDir =~ s/[\\\/]$//;
  my $repositoryMaxSize = getRepositoryMaxSize($tfa_home);
  my $defaultRepoSize = 10;  # 10 GB
  my $msg = "changerepositorydir";

  if ( ! $repos ) {
    $msg = "changerepositorysize";
    # check whether user is trying to change size to same old value
    if ($size == $repositoryMaxSize) {
        print "Repository size is already $size MB. No changes made to repository size.\n";
        printLocalRepository($tfa_home);
        return FAILED;
    }
  }
  elsif (!$size && $repos) {
    # check whether user is trying to change repository to same 
    # old location without specifying any size
    if ($repos && !$size) {
      if ($repos eq $repositoryDir) {
        print "Repository location is already $repos. No change made to repository location.\n";
        printLocalRepository($tfa_home);
        return FAILED;
      }
    }
  }
  elsif ($repos && $size) {
    # check whether user is trying to change repository to same old location
    if ($repos eq $repositoryDir) {
        $msg = "changerepositorysize";
    }

    # check whether user is trying to change size to same old value for same directory
    if ($msg eq "changerepositorysize" && $size == $repositoryMaxSize) {
        print "Repository location is already $repos and size is already $size MB. No changes made to repository location and size.\n";
        printLocalRepository($tfa_home);
        return SUCCESS;
    }
  }

  if ($repos) {
    # check whether the user entered a valid directory name
    if ( -d $repos ) {
      dbg(DBG_VERB, "$repos directory exists.\n");
    }
    elsif ( -e $repos ) {
      print "$repos is a file. Enter a valid directory location for repository.\n";
      return FAILED;
    }
    else {
      print "$repos does not exist. Failed to modify repository path.\n";
      return FAILED;
    }
  }

  $repos = $repositoryDir if ( ! $repos );
  #$repos = "CURRENT" if ( ! $repos );

  #$size = 10*1024 if ( ! defined($size) ); # setting default repository size to 10 GB
  $size = $repositoryMaxSize if ( ! defined($size) ); # setting default repository size to RepoMaxSize

  if ($size == 0 || $size < 0) {
        print "Invalid size specified for repository : $size. No changes made to repository size.\n";
        printLocalRepository($tfa_home);
        return FAILED;
  }
  $size = int($size); # convert to integer
  if ($size == 0) {
        print "The size specified for repository is less than 1 MB. No changes made to the repository size.\n";
        printLocalRepository($tfa_home);
        return FAILED;
  }

  if ($size < $defaultRepoSize*1024) {
    print "The minimum recommended repository size is $defaultRepoSize GB.\n";

    if ( ! $force ) {
      print "Do you wish to continue with current repository size ? [Y/y/N/n] [N] ";
      chomp( my $changesize = <STDIN> );
      $changesize ||= 'N';
      $changesize = get_valid_input ($changesize, "Y|y|N|n", "N");
      if ($changesize=~ /[Yy]/) {
      }
      else {
        print "Enter the new repository size: ";
	$size =<STDIN>;
	chomp($size);
        #printLocalRepository($tfa_home);
        #return FAILED;
      }
    }
  }

  if ( ! $force ) {
    my $directoryCurrentSize = int(osutils_du($repos,"true")/(1024*1024));
    if ($directoryCurrentSize >= $size){
      print "Repository Max size ($size MB) should be greater than Current Repository Size ($directoryCurrentSize MB)\n";
      print "No changes made to repository size.\n";
      printLocalRepository($tfa_home);
      return FAILED;
    }

    my $availability = checkForAvailableSpaceInFileSystem($repos, $size);
    if ($availability eq "NOT AVAILABLE")  {
	print "\nUse -force to skip these initial checks (Not Recommended)\n";
        printLocalRepository($tfa_home);
        return FAILED;
    }
  }

  dbg(DBG_WHAT, "In changeRepository to :: $repos for size :: $size MB\n");
  my $localhost=tolower_host();
  my $oldsize = $repositoryMaxSize;
  my $oldrepo = $repositoryDir;
  my $actionmessage = "$localhost:$msg:$repos $size $oldsize $oldrepo\n";
  dbg(DBG_WHAT, "Running changeRepository to :: $repos for size :: $size MB\n");
  my $command = buildCLIJava($tfa_home,$actionmessage);

  my $oldrepos;
  my $oldmaxreposize;
  if ($msg eq "changerepositorydir") {
        $oldrepos = getCurrentRepository($tfa_home);
  }
  elsif ($msg eq "changerepositorysize") {
        $oldmaxreposize = getRepositoryMaxSize($tfa_home);
  }

  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
    if ( $line eq "SUCCESS") {
      dbg(DBG_WHAT,"#### changeRepository done ####\n");
      my $tb = Text::ASCIITable->new();
      $tb->setCols("Repository Parameter", "Value");
      $tb->setColWidth("Value", $tputcols - 30);
      $tb->alignCol("Value","left");
      $tb->setOptions({"outputWidth" => $tputcols});
      my $currRepoSize = int(osutils_du($repos,"true")/(1024*1024));
      my $repostatus;
      if ($currRepoSize >= $size) {
        $repostatus = "FULL & CLOSED";
      }
      else {
        $repostatus = "OPEN";
      }

      if ($msg eq "changerepositorydir") {
        print "Successfully changed repository\n";
        $tb->addRow("Old Location", wrap("","",$oldrepos));
        $tb->addRow("New Location", wrap("","",$repos));
        $tb->addRow("Current Maximum Size (MB)", $size);
        $tb->addRow("Current Size (MB)", $currRepoSize);
        $tb->addRow("Status", $repostatus);

        # Change Repository permissions for Non-root users
        host("$CHMOD 1755 $repos");
        # Create suptools directories for new repository
        foreach my $tool ( keys %tfactlglobal_exttools ){
          # Validate tool pm
          my $tool_pm = catfile($tfa_home, "ext", $tool, "$tool.pm");
          if ( -e "$tool_pm" ) {
            tfactlshare_setup_tool_dir_for_all_users($tfa_home, $tool);
          }
        }
      }
      else {
        print "Successfully changed repository size\n";
        $tb->addRow("Location", wrap("","",$repos));
        $tb->addRow("Old Maximum Size (MB)",$oldmaxreposize);
        $tb->addRow("New Maximum Size (MB)", $size);
        $tb->addRow("Current Size (MB)", $currRepoSize);
        $tb->addRow("Status", $repostatus);
      }
      print $tb;
      if ($repostatus eq "FULL & CLOSED") {
        my $tfactl = getTfactlPath($tfa_home);
        print "\nThe current repository is full and no more files can be added to it.\n\n";
        print "To open the repository for new files, one of the following steps can be taken:\n\n";
        print "1. Increase the repository size to preserve current files\n";
        print "\t $tfactl set reposizeMB=<n> \n\n";
        print "2. Delete some files from directory $repos\n\n";
        #print "3. Set the -override flag to purge the old files automatically.\n";
        #print "\t $tfa_home/bin/tfactl modify -override \n\n";
      }
      return SUCCESS;
    }
    elsif ($line eq "FAILED") {
        print "Failed to change repository location to $repos\n";
        print "To change the repository location, one of the following steps can be taken:\n";
        print "1. Set location to empty directory\n";
        print "2. Set location to previously used repository location\n";
	print "3. Set location to the default TFA repository location\n";
        printLocalRepository($tfa_home);
        return FAILED;
    }
  }
  dbg(DBG_WHAT,"Could not changeRepository\n");
  return FAILED;
}

sub updateMaxLogSize {

        my $tfa_home = shift;
        my $logSize = shift;
        my $isLocal = shift;
        my $localhost = tolower_host();
        my $actionmessage;
        my $command;
        my $line;
        my $status = 0;

        if (isTFARunning($tfa_home) == FAILED) {
          return FAILED;
        }

        $actionmessage = "$localhost:updateMaxLogSize:$logSize:$isLocal\n";
        $command = buildCLIJava($tfa_home, $actionmessage);
	my @cli_output = tfactlshare_runClient($command);
        foreach $line ( @cli_output ) {
                if ( $line eq "UPDATED" ) {
                        $status = 1;
                }
        }

        if ( $status == 1 ) { 
                print "\nSuccessfully updated TFA log size to $logSize MB\n\n";
                printConfig($tfa_home, "node=local~name=all");
        } else {
                print "\nUnable to update TFA log size to $logSize MB. Please try later\n";
        }
}
sub tfactladmin_setJVMFlags {
  my $tfa_home = shift;
  my $jvmXmxMB = shift;
  my $jvmLineOther = shift;
  my $clusterwide = shift;
  my $restart_tfa = shift;
     
  my $jvmXmxMB_ARG = '';
  my $jvmLineOther_ARG = '';
  my $localhost = tolower_host();
  $jvmLineOther =~ s/-XX#/-XX:/g;

  $jvmXmxMB_ARG = "jvmXmxMB=$jvmXmxMB" if(defined $jvmXmxMB); 
  $jvmLineOther_ARG = "jvmLineOther=\\\"$jvmLineOther\\\"" if(defined $jvmLineOther); 
  my $command1 = "set jvmflags $jvmXmxMB_ARG $jvmLineOther_ARG -local -norestarttfa";
  print "\nRunning Command to set jvmflags On :\n";

  if($clusterwide){
    my $print_command = "no";
    my $status_message = "Successfully added/updated jvmflags";
    my @expected_output_strings;

    push(@expected_output_strings,"Successfully (added|updated) jvmXmx") if(defined $jvmXmxMB);
    push(@expected_output_strings,"Successfully (added|updated) jvmLineOther") if(defined $jvmLineOther);
    tfactlshare_execute_tfactl_cmd_withstatusonly($print_command,$clusterwide, $command1, $status_message, @expected_output_strings);
  } else {
    print "Node : $localhost :";
    tfactlshare_set_jvm_xmx($tfa_home,$jvmXmxMB,$jvmLineOther);
  }
  tfactladmin_restartTFA($clusterwide) if($restart_tfa);
  print "\n";
}

sub tfactladmin_restartTFA {
  my $clusterwide = shift;
  my $command1 = "restarttfa";
  my $print_command = "no";

  print "\nRunning Command to Restart TFA On :\n";
  my $status_message = "Successfully Restarted TFA Process";
  my @expected_output_strings;
  push(@expected_output_strings,"Successfully started TFA Process..");
  push(@expected_output_strings,"TFA Started and listening for commands");

  tfactlshare_execute_tfactl_cmd_withstatusonly($print_command,$clusterwide, "$command1", $status_message, @expected_output_strings);
}

sub updateTFAPort {

	my $tfa_home = shift;
	my $port = shift;

        if (isTFARunning($tfa_home) == FAILED) {
        	return FAILED;
        }

        my $localhost = tolower_host();
        my $actionmessage;
        my $command;
        my $line;
        my $status = 0;
	
        $actionmessage = "$localhost:updatePort:$port\n";
        $command = buildCLIJava($tfa_home, $actionmessage);
	print "\n";
	my @cli_output = tfactlshare_runClient($command);
        foreach $line ( @cli_output ) {
		if ( $line =~ /^Updated Port on / ) {
			print "$line\n";
		}
		elsif ( $line eq "UPDATED" ) {
                        $status = 1;
			last;
		}
        }

        if ( $status == 1 ) {
                print "\nSuccessfully updated TFA Ports. TFA will use new ports after restart.\n\n";
        } else {
                print "\nUnable to update TFA Ports. Please try later\n";
        }
}

sub updateMaxLogCount {

        my $tfa_home = shift;
        my $logCount = shift;
        my $isLocal = shift;
        my $localhost = tolower_host();
        my $actionmessage;
        my $command;
        my $line;
        my $status = 0;

        if (isTFARunning($tfa_home) == FAILED) {
          return FAILED;
        }

        $actionmessage = "$localhost:updateMaxLogCount:$logCount:$isLocal\n";
        $command = buildCLIJava($tfa_home,$actionmessage);
	my @cli_output = tfactlshare_runClient($command);
        foreach $line ( @cli_output ) {
                if ( $line eq "UPDATED" ) {
                        $status = 1;
			last;
                }
        }

        if ( $status == 1 ) {
                print "\nSuccessfully updated TFA log count to $logCount\n\n";
                printConfig($tfa_home, "node=local~name=all");
        } else {
                print "\nUnable to update TFA log count to $logCount. Please try later\n";
        }
}

sub updateMaxCoreFileSize {

        my $tfa_home = shift;
        my $coreFileSize = shift;
        my $isLocal = shift;
        my $localhost = tolower_host();
        my $actionmessage;
        my $command;
        my $line;
        my $status = 0;

        if (isTFARunning($tfa_home) == FAILED) {
          return FAILED;
        }

        $actionmessage = "$localhost:updateMaxCoreFileSize:$coreFileSize:$isLocal\n";
        $command = buildCLIJava($tfa_home,$actionmessage);
	my @cli_output = tfactlshare_runClient($command);
        foreach $line ( @cli_output ) {
                if ( $line eq "UPDATED" ) {
                        $status = 1;
			last;
                }
        }

        if ( $status == 1 ) {
                print "\nSuccessfully updated Core file Size to $coreFileSize\n\n";
                printConfig($tfa_home, "node=local~name=all");
        } else {
                print "\nUnable to update Core file Size to $coreFileSize. Please try later\n";
        }
}

sub updateMaxCoreCollectionSize {

        my $tfa_home = shift;
        my $coreCollectionSize = shift;
        my $isLocal = shift;
        my $localhost = tolower_host();
        my $actionmessage;
        my $command;
        my $line;
        my $status = 0;

        if (isTFARunning($tfa_home) == FAILED) {
          return FAILED;;
        }

        $actionmessage = "$localhost:updateMaxCoreCollectionSize:$coreCollectionSize:$isLocal\n";
        $command = buildCLIJava($tfa_home,$actionmessage);
	my @cli_output = tfactlshare_runClient($command);
        foreach $line ( @cli_output ) {
                if ( $line eq "UPDATED" ) {
                        $status = 1;
                        last;
                }
        }

        if ( $status == 1 ) {
                print "\nSuccessfully updated collection size of Core Files to $coreCollectionSize\n\n";
                printConfig($tfa_home, "node=local~name=all");
        } else {
                print "\nUnable to update collection size of Core Files to $coreCollectionSize. Please try later\n";
        }
}

sub generateFileList {
        my $tfa_home = shift;
        my $dir = shift;
        my $lastInventoryTime = shift;
	my $fileList = catfile($tfa_home,"internal","filelist");
	open (WF, "+>$fileList") or die "Can't open $fileList: $!\n";;
        find( sub {
                if (!(-d $_) ){
                   my $file = $_;
                   my $mTime = -M $file; #in days
		   if (($mTime*24*60) < $lastInventoryTime) {
			#print "File $File::Find::dir/$file $mTime localtime((stat($file))[9])\n";
                   	print WF "$File::Find::dir/$file\n";
                   }
                 }
             },"$dir");
         close (WF);
}

sub runTest
{
  my $tfa_home=shift;
  print "Running tests in current installation $tfa_home\n";
  system("sh $tfa_home/test/sosd/testdriver.sh $tfa_home");
}

sub validateFileTypePattern {
        my $TFA_HOME = shift;
        my $localhost = tolower_host();
        dbg(DBG_WHAT, "Running validateFileTypePattern through Java CLI \n");
        my $message = "$localhost:validatefiletypepattern";
        my $command = buildCLIJava($TFA_HOME, $message);
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
         dbg(DBG_WHAT, "Could not validate fileTypePatternXML");
        return FAILED;
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

#
######################## deleteDatabase
#
sub deleteDatabase
{
  dbg(DBG_VERB, "In Delete Database\n");
  my $tfa_home = shift;
  #my $tfapid = `ps -ef | grep "TFAMain" | grep -v grep | awk '{print \$2}'`;
  my $tfapid = get_tfa_pid($tfa_home);
  print "tfapid : $tfapid\n";
  if ($tfapid ne '') {
    my $tfaprocess = `ps -f -p $tfapid | grep -v PID`;
    if ($tfaprocess ne '') {
      print "TFA is running with PID : $tfapid\n";
      print "Cannot delete database when TFA is running\n";
      print "To stop TFA use: /etc/init.d/init.tfa shutdown\n";
      return FAILED;
    }
  }
  my $dbdir = catfile($tfa_home,"database","BERKELEY_JE_DB");
  dbg(DBG_VERB, "removing : $dbdir\n");
  unlink glob("$dbdir$FSEP*");
}

#########################################################
sub tfactladmin_updatehost{
  my $inp = shift;
  my $key = shift;
  my $val = shift;
  my $inp_bkp = $inp."bkp";
  my $inp_out = $inp."out";
  copy($inp,$inp_bkp);
  my $localhost=tolower_host();
  chomp($localhost);
  chomp($key);
  chomp($val);
  open INP,"$inp_bkp" or die $!;
  open OUT, ">>$inp_out" or die $!;
  my @lines = <INP>;
  my $rec;
  foreach $rec (@lines) {
   chomp($rec);
   if($rec =~ /^host.name/) {
      print OUT "host.name=$localhost\n";
   }else {
     print OUT "$rec\n";
   }
  }
  close(OUT);
  close(INP);
  copy($inp_out,$inp);
  unlink($inp_bkp);
  unlink($inp_out);
}

####################### Log Viewer ########################
########## input ==> vi|tail logtype1[,logtype2...]
sub viewLog 
{
   my ($tfa_home, $input) = @_;
   my $flag;
   my $localhost=tolower_host();   
   if (isTFARunning($tfa_home) == FAILED) {
	print "TFA Main is not running. Exiting ...\n";
        return FAILED;
   }
   my $ENV_HOST_KEY = "TFA_SESSION_HOST";
   my $ENV_DB_KEY   = "TFA_SESSION_DB";
   my $targetNodes = "all";
   my $targetDB    = ""; 
   if ( exists $ENV{$ENV_HOST_KEY} ) {
     $targetNodes = $ENV{$ENV_HOST_KEY};
   }
   if ( exists $ENV{$ENV_DB_KEY} ) {
     $targetDB = $ENV{$ENV_DB_KEY};
   }

   my @args = split(/\s+/, $input);
   my $tags = "";
   my $tail = "";    
   if ( $args[0] ne "tvi" && $args[0] ne "tail" ) {
     print "Invalid command $args[0]\n";
     return FAILED;;
   }
   my $cmd = $args[0];
   my $logs = "";
   for ( my $i=1; $i <= $#args; $i++ ) {
       $logs .= ",$args[$i]";
   }
   $logs =~ s/^,//;
   if ( ! $logs ) {
     print "Error : Please pass log detils which you wanted to view/tail\n";
     return FAILED;
   }
   #Create topic/session for each view/tail
   my $session_name = "session".time();
   chomp($session_name);
   #print "Creating topic : $session_name\n";
   my $khlist;
   my $zhlist;

   my $metadata = "session_name=$session_name~khlist=$khlist~zhlist=$zhlist~log_type=$logs";
   if ( $targetNodes ) {
     $metadata .= "~nodes=$targetNodes";
   }
   if ( $targetDB ) {
     $metadata .= "~db_name=$targetDB";
   } 
   my $actionmessage = "$localhost:$cmd:$metadata\n";
   my $command = buildCLIJava($tfa_home,$actionmessage);
   #print "Command: ($command)\n";
   open(CMDF, "$command|");
   while(<CMDF>) {
     if ( /WARNING - Certificate/ ) {
       print "$_\n";
     }
     elsif ( /FAIL - Certificate/) {
       print "$_\n";
       return FAILED;
     }
     print $_;
   }
   close(CMDF);
}

######################################################
# Manage Collector
######################################################
sub tfactladmin_managecollector
{
  #print " In tfactladmin_managecollector\n";
  my $action = $_[0];
  my $cnode = $_[1];
  my $cpass = $_[2];
  my $tfa_home = $_[3];
  my $ropt = $_[4];
  my $kopt = $_[5];
  my $ctype = $_[6];
  my $localhost = tolower_host();
  #print "action=$ropt";
  chomp($action);
  if( $action eq "add") {
     #print "calling add";
     tfactlshare_addCollector("client",$cnode,$cpass,1,$action,$tfa_home,$ropt, $action,$kopt,$ctype);
     if($cnode eq "tfarweb"){
       tfactladmin_manage_receiver("webadmin:$cpass");
     }
  }
   elsif ( $action eq "export" )
  {
    tfactlshare_addCollector("client",$cnode,$cpass,1,"add",$tfa_home,$ropt, $action,$kopt,$ctype);
  }
  else {
     tfactlshare_error_msg(515,undef); 
     return FAILED;
  }
}



sub tfactladmin_list_clients
{
  my $tfa_home = shift;
  my $cname = shift;
  my $details = shift;

  my $file = catfile($tfa_home,"internal","collectorkey.store");
  if ( $current_user ne "root" )
  {
    $file = catfile($tfa_home, ".$current_user", "collectorkey.store");
  }

  my @all_clients = tfactlshare_get_clients($tfa_home,$details);
  my %clients_hash = ();
  foreach my $c (@all_clients)
  {
    $clients_hash{$c} = 1 if ( $c ne "null" );
  }

  my $cname_printed = 0;

  if( -e $file)
  {
    dbg(DBG_WHAT,  "addCollector: key store exists");
    open INP, "$file" or die $!;
    my @lines = <INP>;
    chomp(@lines);
    foreach my $rec (@lines)
    {
      if($rec =~ /detailsof\.([^:]+):(.*)/)
      {
        my $c1 = $1;
        my $c2 = $2;
        my @r = split(/\[/, $c2);
        if ( exists $clients_hash{$c1} )
        {
          $clients_hash{$c1} = 2;
          if ( $cname )
          {
            if ( lc($c1) eq lc($cname) )
            {
              if ( $details == 0 )
              {
                print "$c1\n";
              }
               else
              {
                print "$c1   ". $r[1] . "    " . $r[3] ."\n";
              }
              $cname_printed = 1;
            }
          }
           else
          {
              if ( $details == 0 )
              {
                print "$c1\n";
              }
               else
              {
                print "$c1   ". $r[1] . "    " . $r[3] ."\n";
              }
          }
        }
      }
    }
    close(INP);
  }

  foreach my $c1 (keys %clients_hash)
  {
    my @r = ("", "12.2.0.1.0", "", "MYCLUSTERGUID");
    if ( $clients_hash{$c1} == 1 )
    {# Not printed 
          if ( $cname )
          {
            if ( lc($c1) eq lc($cname) )
            {
              if ( $details == 0 )
              {
                print "$c1\n";
              }
               else
              {
                print "$c1   ". $r[1] . "    " . $r[3] ."\n";
              }
              $cname_printed = 1;
            }
          }
           else
          {
              if ( $details == 0 )
              {
                print "$c1\n";
              }
               else
              {
                print "$c1   ". $r[1] . "    " . $r[3] ."\n";
              }
          }
    }
  }
  if ( $cname && $cname_printed == 0 )
  {
    tfactlshare_error_msg(517,undef);
  }

}

sub  tfactladmin_rm_key
{
  my $tfa_home = shift;
  my $collector = shift;
  my $file = catfile($tfa_home,"internal","collectorkey.store");
  if ( $current_user ne "root" )
  {
    $file = catfile($tfa_home, ".$current_user", "collectorkey.store");
  }

  my $ofile = "$file.bkup";
  my $ckey = "";
  my $removed = 1;
  if( -e $file)
  {
    dbg(DBG_WHAT,  "addCollector: key store exists");
    open INP, "$file" or die $!;
    open ONP, ">$ofile" or die $!;
    my @lines = <INP>;
    chomp(@lines);
    foreach my $rec (@lines)
    {
      if($rec =~ /$collector=(.*)/i || $rec =~ /detailsof.$collector:/i )
      {
        $ckey = $1;
        chomp($ckey);
      }
       else
      {
        print ONP "$rec\n";
      }
    }
    close(INP);
    close(ONP);
    copy($ofile,$file);
    unlink($ofile);
  }
  # remove object only if removed from file
  if( $removed == 1) {
  my $localhost=tolower_host();
  my $actionargs = "collector=$collector~is_commandline=1~pollport=-1~query=.~onhost=-1~roption=y";
  my $actionmessage = "$localhost:removecollector:$localhost";
  $actionmessage = "$actionmessage~$actionargs";
  $actionmessage = "$localhost:removecollector:$collector";
  dbg(DBG_WHAT, "Removing client through Java CLI\n");
  my $command = buildCLIJava($tfa_home,$actionmessage);
  dbg(DBG_VERB, "$command\n");
  my $line;
  my $rhosts = "";
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output ) {
    if ( $line =~ /DONE/ )
    {
      dbg(DBG_VERB, "We got $line\n");
      tfactladmin_cleanup_client($collector);
    }
    if ( $line =~ /FAILED/ )
    {
      $removed = 0;
    }
  }
  }
  return $removed;
}

sub tfactladmin_cleanup_client
{
  my $node = shift;
  return if ( ! $node );
  my $rconfig = catfile($tfa_home, "receiver", "internal", "rconfig.properties");
  my $repos = tfactlshare_getConfigValue($rconfig,"r.repository");
  if ( -d "$repos" )
  {
    my $rdir = catfile($repos, "receiver", $node);
    if ( -d $rdir )
    {
      tfactlshare_trace(3, "tfactl (PID = $$) tfactladmin_cleanup_client " .
                    "Cleaning up client $node repository $rdir",
                   'y', 'y');
      system("$RM -rf $rdir");
    }
  }
}

sub tfactladmin_setperm_rprop
{
  my $rfile = shift;
  my $rconfig = catfile($tfa_home, "receiver", "internal", "rconfig.properties"); 
  my $ruser= tfactlshare_getConfigValue($rconfig,"r.user");
  my $rfile_info = "$rfile.info";
  open(WRF, ">$rfile_info");
  open(RRF, "$rfile");
  while(<RRF>)
  {
    chomp;
    if ( ! /r\.key/ )
    {
      print WRF "$_\n";
    }
  }
  close(RRF);
  close(WRF);
  chmod(0700,$rfile);
  chmod(0700,$rfile_info);
  `$CHOWN $ruser $rfile`;
  `$CHOWN $ruser $rfile_info`;
}

sub tfactladmin_receiverinfo
{
  my $CATALINA_BASE = "$tfa_home/tomcat";
  my $rwp = catfile($tfa_home,"internal","rweb_port.txt");
  my $rprop = catfile($CATALINA_BASE,"r.properties.info");
  if ( !-e $rprop) {
     print "The TFA Web is not yet configured. Please run 'tfactl client reset webadmin' first.\n";
  }else {
    my ($rhost, $wport, $wport_ssl, $rport, $repos, $mcnt);
    open(RF, "$rprop");
    while(<RF>)
    {
      chomp;
      $rhost = $1 if ( /r.host=(.*)/ );
      $wport = $1 if ( /r.port_rweb=(.*)/ );
      $wport_ssl = $1 if ( /r.port_rweb_ssl=(.*)/ );
      $rport = $1 if ( /r.port=(.*)/ );
      $repos = $1 if ( /r.tfa_base=(.*)/ );
    }
    close(RF);
    print "TFA Service URL          : http://$rhost:$wport/tfa/index.html\n";
    print "TFA Service URL (https)  : https://$rhost:$wport_ssl/tfa/index.html\n";
    print "TFA Service Admin User   : admin\n";
    print "TFA Service Admin Status : active\n";
    print "TFA Service Repository   : $repos\n";
    print "TFA Service Port         : $rport\n";
    print "TFA Service Members      : $mcnt\n";
  }

}
sub  tfactladmin_get_key
{
  my $tfa_home = shift;
  my $collector = shift;
  my $file = catfile($tfa_home,"internal","collectorkey.store");
  if ( $current_user ne "root" )
  {
    $file = catfile($tfa_home, ".$current_user", "collectorkey.store");
  }

  my $ckey = "";
  if( -e $file) 
  {
    dbg(DBG_WHAT,  "addCollector: key store exists");
    open INP, "$file" or die $!;
    my @lines = <INP>;
    foreach my $rec (@lines) 
    {
      if($rec =~ /$collector=(.*)/i)
      {
        $ckey = $1;
        chomp($ckey);
      }
    }
    close(INP);
  }
  return $ckey;
}

###################################################################
# tfactl upload -user first.last -bug <> -comment <>
# run flags = tfa_upload_files.pl -u first.last -
sub upload_tfaweb
{
  my ($tfa_home, @args) = @_;
  my $command = "";
  my $bug = "";
  my $bugno = "";
  my $user = "";
  my $flname = "";
  my $comment = "";
  my @files = ();
  my $bugsftp = 0;
  my $mos = 0;
  my $sr = 0;
  my $wallet = 0;
  my $bugsftpurl;
  my $configfile = catfile("$tfa_home","internal","config.properties");
  my $home_configfile = catfile(getHomeDirectory(1), ".config.tfa");
  my $retval = SUCCESS;

  my $tfa_setup = catfile($tfa_home, "tfa_setup.txt");

  #Atleast 3 arguments needs to be passed in case of MOS upload
  if ((grep {/^(-help|-h)$/i} @args)) {
    print_help("upload");
    return SUCCESS;
  }
  if ( $#args < 2){
    print_help("upload");
    return FAILED;
  }

  if ( isTFAOnCloud($tfa_home) ) {
    my $homedir = getHomeDirectory();
    if ( -f catfile($homedir, ".tfa", "tfa_setup.txt") ) {
      $tfa_setup = catfile($homedir, ".tfa", "tfa_setup.txt");
    }
  }

  for (my $i = 0; $i <= $#args; $i ++)
  {
    if ( $args[$i] eq "-bug" ) 
    {
      if ( $args[$i+1] !~ /^[0-9]{6,12}$/ ) {
        print $args[$i+1] . " is not a valid bug number.\n";
        return FAILED;
      }
      $bugno = $args[$i+1]; 
      $bug = "-b ".$args[$i+1]; $i++;
    } 
     elsif ( $args[$i] eq "-user" ) 
    {
      $flname = $args[$i+1];
      $i++;
    }
     elsif ( $args[$i] eq "-comment" )
    {
      $comment = "-s '".$args[$i+1] . "'"; $i++;
    }
     elsif ( $args[$i] eq "-bugsftp" )
    {
      $bugsftp = 1;
    }
     elsif ($args[$i] eq "-wallet") {
      $wallet = 1;
    }
     elsif ( $args[$i] eq "-sr" )
    {
      $mos = 1;
      if ( $args[$i+1] !~ /^[0-9]\-[0-9]{6,14}$/ ) {
        print $args[$i+1] . " is not a valid SR number.\n";
        return FAILED;
      }
      $sr = $args[$i+1]; $i++;
    }
     elsif ( -e $args[$i] )
    {
      @files = (@files, $args[$i]);
    }
     else
    {
      #Intentionally not exiting here for now
      print "Ignoring invalid argument : $args[$i]\n";
    }
  }

  #There can be 3 cases here when trying to upload files manually
  #1. Upload to MOS/SR using -sr 
  #2. Upload to both bug and TFAWeb using -bugsftp -bug
  #3. Upload to only TFAWeb using -bug
  #Note: Have a restriction that 1 can not be clubbed with any other options

  if ($mos && ($bugsftp || $bugno)) { 
    print "-sr flag is not supported with -bugsftp or -bug\n";
    return FAILED;
  }

  if (($mos && !$wallet) || $bugsftp || $bugno) {
    if ( ! $flname ) {
      print "Error: Missing -user argument\n";
      return FAILED;
    }
    #Validate username
    if ( $flname !~ /.+@.+/ ) {
      print "Enter valid user name. Example: firstname.lastname\@domain.com\n";
      return FAILED;
    }
    if ( $flname =~ /(.+)@.+/ ) {
      $user = "-u ".$1;
    }  
  }

  if ( ! $files[0] )
  {
    print "Error: No files to upload\n";
    print_help("upload");
    return FAILED;
  }
  
  if ( $bugsftp ) {
    #Order of getting url: config file, home file,User input
    $bugsftpurl = tfactlshare_getConfigValue($configfile, "bugsftpurl");
    if ( !$bugsftpurl ) {
      $bugsftpurl = tfactlshare_getConfigValue($home_configfile, "bugsftpurl");
    }
    if ( !$bugsftpurl ) {
      print "Note: You can set bugsftpurl at any time using \"tfactl set bugsftpurl=<url>\"\n";
      print "Please enter bugsftpurl(Ex bugsftp.domain.com):\n";
      chomp($bugsftpurl = <STDIN>);
      if ( !$bugsftpurl ) { 
        print "Please set valid bugsftpurl and try again\n";
        return FAILED;
      }
      #Write to config file      	
      if ( $current_user eq "root" ) {
        setFlag($tfa_home, "bugsftpurl=$bugsftpurl", 1, 1);
      }
      #Write to user home dir
      if ( ! -f $home_configfile ) {
	eval {
	  system("$TOUCH $home_configfile");
	};
	if ( $@ ) {
	  print "Unable to create $home_configfile\n";
          return FAILED;
	}
      }
      tfactlshare_updateTFAConfig($home_configfile, "bugsftpurl", $bugsftpurl);
    }
  }

  my $java_home = get_java_home ($tfa_home);
  my $java = catfile("$java_home","bin","java");
  my $pass;

  if ($bugsftp == 1) {
    if ( $ENV{"TFA_BUGSFTP_PASS"} ) {
      $pass = $ENV{"TFA_BUGSFTP_PASS"};
    }
    if (!$pass) {
      system('stty', '-echo');
      print "Bugsftp Password:";
      $pass = <STDIN>;
      chomp($pass);
      system('stty', 'echo');
    }
    #Validdate password/session
    if ( $bugsftp == 1 ) {
      $command = "$java -cp $tfa_home/jlib/RATFA.jar oracle.rat.tfa.ssh.SftpTo $bugsftpurl $flname '/$bugno' 'validate_creds'";
      my $tmpfile = "/tmp/.$$.pass";
      system("echo $pass > $tmpfile; chmod 500 $tmpfile");
      open(RF, "$command < $tmpfile 2>&1 |");
      system("rm -f $tmpfile");
      while(<RF>) {
        if ( $_ =~ /FAIL/ ) {
          print "\nInvalid username or password. Please try again.\n";
          return FAILED;
        }
      }
    }
  }
  print "\n";
  my $pid;
  if ( $mos == 0 ) {
    my $upload_script = "$ENV{ADE_VIEW_ROOT}/oracle/tfa/src/v2/tfa_home/bin/tfa_upload_files.pl";
    if ( -f "$upload_script" ) {
      $pid = fork();
      if ( $pid == 0 ) {
	#In child process
        my $perl = tfactlshare_getConfigValue($tfa_setup, "PERL");
        $command = "$perl $upload_script -noupdate $bug $user $comment -f ". join(" ", @files);
        #print "Running $command\n";
        print "\nStarted uploading files to tfaweb.. It may take a while.. please wait..\n";
        open(CMDF, "$command|");
        while(<CMDF>) {
          print;
        }
        close(CMDF);
        return;
      }
    }
    elsif (!$bugsftp) {
      print "Failed to upload to TFA Web as tfa_upload script is not available\n";
      return FAILED;
    }
  }

  my @out = ();
  my $fl = join (" ", @files);
  my @f = `find $fl -type f`;
  chomp(@f);
  my $af;
  if ( $mos == 1 || $bugsftp == 1 )
  {
    if ( $mos == 1 && $wallet) {
      #Send request to daemon to make it work for both root and non root
      #Pass files with full path
      my $tfile;
      foreach my $file (@files) {
        $tfile = abs_path($file); 
	if (-f $tfile) {
          $af = $af .":". $tfile;
	}
	else {
	  print "File $file does not exists\n";
          return FAILED;
	}
      }
      $af =~ s/^://;
      my $localhost = tolower_host();
      my $message = "$localhost:uploadtomos:$sr~$af";
      $command = buildCLIJava($tfa_home, $message);
      dbg(DBG_VERB, "UploadTOSR: Client command - $command\n");
      print "Started uploading files to SR - $sr\n\n";
      my @cli_output = tfactlshare_runClient($command);
      my $line;
      foreach $line (@cli_output) {
        if ($line eq "DONE") {
          last;
        }
        else {
          push(@out,$line);
        }
      }
    } 
    else {
      $af = join(" ", @f);
      if ($mos == 1) {
        $command = "$java -cp $tfa_home/jlib/RATFA.jar:$tfa_home/jlib/commons-io-2.6.jar oracle.rat.tfa.ssh.SRUpload upload -u $flname -sr $sr -f $af";
        system("$command");
        $retval = $? >> 8;
      }
      else {
        $command = "$java -cp $tfa_home/jlib/RATFA.jar oracle.rat.tfa.ssh.SftpTo $bugsftpurl $flname '/$bugno' $af";
        my $tmpfile = "/tmp/.$$.pass";
        system("echo $pass > $tmpfile; chmod 500 $tmpfile");
        open(CMDF, "$command < $tmpfile 2>&1 |");
        system("rm -f $tmpfile");
        while(<CMDF>) {
          if ( $_ !~ /Password/ && $_ !~ /Done/ ) {
            push(@out, $_);
          }
        }
        close(CMDF);
      }
    }
  }
  while (wait() != -1) {}
  if ($bugsftp) {
    print "\nUploading files to bugsftp...\n";
  }
  #Print command output if any thing is there 
  foreach my $line (@out) {
    $retval = FAILED if ( $line =~ /Run: tfactl setupmos|FAIL/ );
    print "$line\n";
  }
  return $retval;
}

##################################################################
# NAME
#  tfactladmin_setupmos 
#
# DESCRIPTION
#   This subroutine create/updates MOS config details in Wallet
#
# PARAMETERS
#   NULL
#
# RETURNS
# 
# NOTES/USAGE
#   tfactl setupmos. It will prompt for the details.
# 
##################################################################

sub tfactladmin_setupmos
{
  my ($tfa_home,@args) = @_;
  my $command;
  my $java_home;
  my $java;
  my $crs_home;
  my $status = 1;
  my $debug_setupmos;
  my $oraclepki;
  my $setupfile;
  my $offlineMode;
  my $offline_flags;
  my $user = tfactlshare_get_user();
  my $tfa_owner = tfactlshare_get_dir_file_owner($tfa_home);

  $setupfile = tfactlshare_getSetupFilePath($tfa_home);
  $offlineMode = isOfflineMode($setupfile);

  if (($user ne "root" && !$offlineMode) || ($offlineMode && $user ne $tfa_owner)) {
    print "\nAccess Denied: Only TFA Admin can run this command\n"; 
    return;
  }

  if (grep {/^(-help|-h)$/i} @args) {
    print_help("setupmos");
    return SUCCESS;
  }
 
  $oraclepki = catfile($tfa_home,"jlib","oraclepki.jar");
  if ( -f $oraclepki ) {
    tfactlshare_trace(3, "tfactl (PID = $$) tfactladmin setupmos using oraclepki $oraclepki", 'y', 'y');
  } else {
    tfactlshare_trace(3, "tfactl (PID = $$) tfactladmin setupmos no oraclepki in TFA_HOME trying CRS_HOME", 'y', 'y');
    $crs_home = get_crs_home($tfa_home);
    $oraclepki = catfile($crs_home,"jlib","oraclepki.jar");
    if ( ! -f $oraclepki ) {
      print "FAIL - Could not find oraclepki and it's dependent jars required to setup mos configuration.\n";
      return FAILED;
    } else {
      tfactlshare_trace(3, "tfactl (PID = $$) tfactladmin setupmos using oraclepki $oraclepki", 'y', 'y');
    }
  }
 
  #For non daemon mode do not check client.jks
  if ( ! -f catfile($tfa_home,"client.jks") && !$offlineMode) {
    tfactlshare_printSyncnodeMessage();
    return FAILED;
  }
  $java_home = get_java_home($tfa_home);  
  $java = catfile("$java_home","bin","java");
  if ($ENV{'TFA_DEBUG'} && $ENV{'TFA_DEBUG'} > 0) {
    $debug_setupmos = "-debug";
  }   
  if ($offlineMode) {
    $offline_flags = "-offline";
  }
  $command = "$java -cp $tfa_home/jlib/RATFA.jar:$oraclepki:$tfa_home/jlib/commons-io-2.6.jar oracle.rat.tfa.ssh.SRUpload setupmos -tfahome $tfa_home $debug_setupmos $offline_flags";
  dbg(DBG_VERB,"SETUPMOS: Executing $command\n");
  $status = system($command);
  #Setup clusterwide
  if ($status == 0 && !$offlineMode) {
    if (isTFARunning($tfa_home) == FAILED) {
      print "Failed to sync MOS setup across cluster. Try later\n";
      return FAILED;
    }
    my $localhost = tolower_host();
    my $message ="$localhost:setupmos";
    my $command = buildCLIJava($tfa_home, $message);
    my $line;
    dbg(DBG_VERB, "SETUPMOS: Client command - $command\n");
    my @cli_output = tfactlshare_runClient($command);
    foreach $line ( @cli_output ) {
      if ($line eq "DONE") {
        return SUCCESS;
      } 
      else {
        print "$line\n";
      }
    }
    print "MOS setup done clusterwide\n";
  }
  else {
    print "Failed to sync MOS setup to remote nodes\n" if (!$offlineMode);
  } 
}

########
# NAME
#   tfactladmin_update_config_on_cluster_class
#
# DESCRIPTION
#   This subroutine updates config property value before TFA Main starts
#
# PARAMETERS
#   tfa_home - TFA Home path
# RETURNS
# 
# NOTES/USAGE
#
########
sub tfactladmin_update_config_on_cluster_class{
  my $tfa_home = shift;
  my $cc = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "CLUSTER_CLASS");
  my $enabledMLAutoPurgeDSC = tfactlshare_getConfigValue(catfile($tfa_home, "internal","config.properties"),"enableManageLogsAutoPurgeOnDSC");
  if((lc($cc) eq "domainservices") && !(lc(trim($enabledMLAutoPurgeDSC)) eq "true")) {
    tfactlshare_updateTFAConfig(catfile($tfa_home, "internal","config.properties"), "manageLogsAutoPurge", "true");
    tfactlshare_updateTFAConfig(catfile($tfa_home, "internal","config.properties"), "enableManageLogsAutoPurgeOnDSC", "true");
  }  
}

########
## NAME
##   tfactladmin_read_password
##
## DESCRIPTION
##   Prompt user for password and verify
##
## PARAMETERS
## RETURNS
## 
## NOTES/USAGE
##
#########

sub tfactladmin_read_password
{
  my $MINIMUM_LENGTH = 8;
  my $TRIES = 3;
  my $Cpassword = undef;
  for (my $i = 0; $i < $TRIES; $i++)
  {
    print "Enter a password to be used for Authentication\n";
    ReadMode('noecho');
    print "Password: ";
    chomp($Cpassword = <STDIN>);
    print "\n";
    ReadMode(0);
    if (  $Cpassword =~ /[a-z]/ && $Cpassword =~ /[A-Z]/ &&
                   $Cpassword =~ /[0-9]/ && $Cpassword =~ /[\!\@\#\%\*\(\)\-\+]/ && length($Cpassword) >= $MINIMUM_LENGTH )
    {
      if (  ! tfactlshare_has_blacklisted_chrs($Cpassword) )
      {
        last;
      }
       else
      {
        print "Error: Password must be at least $MINIMUM_LENGTH characters including uppercase, ".
              "lowercase, special characters (should not contain \$\`;<>\&\| ) and number\n";
        undef ($Cpassword);
      }
    }
     else
    {
      print "Error: Password must be at least $MINIMUM_LENGTH characters including uppercase, ".
            "lowercase, special characters (should not contain \$\`;<>\&\| ) and number\n";
      undef ($Cpassword);
    }
  }
  return $Cpassword;
}


