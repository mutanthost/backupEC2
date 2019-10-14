#!/usr/bin/perl
# 
# $Header: tfa/src/v2/tfa_home/bin/tfactl.pl /main/171 2018/08/16 22:59:22 recornej Exp $
#
# tfactl.pl
# 
# Copyright (c) 2012, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactl.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    08/09/18 - Verify existence of dbversions.json so that
#                           patching does not fail
#    recornej    08/07/18 - Add exit 1 when user does not have keys to run TFA.
#    recornej    08/03/18 - Load dbversions to tfactl
#    manuegar    07/13/18 - manuegar_multibug_01.
#    manuegar    07/10/18 - Bug 28250972 - OGG:SHD:TFACTL DIAGCOLLECT FAILS W/
#                           CAN'T CREATE..COMMON/TFACTLSHARE.PM LINE.
#    recornej    06/25/18 - Remove IS_OFFLINEMODE
#    recornej    05/30/18 - Do not create tfactlsession when running as root in
#                           an extractto installation
#    recornej    04/16/18 - Bug 27782895 - LNX-191-TFA:PRINT DIRECTORIES WITH
#                           CORRECT COMP DOES NOT WORK.Store and load 
#                           tfactlglobal_xmlcompshash.
#    bburton     04/10/18 - Load the retcomparray from serialization
#    recornej    03/14/18 - Adding tfactlglobal_tfa_dbutlresources.
#    manuegar    02/12/18 - manuegar_shared_dbutils03.
#    manuegar    01/08/18 - manuegar_shared_dbutils01.
#    manuegar    12/02/17 - manuegar_shared_dbutils.
#    bburton     09/28/17 - DO not warn on product age when patching
#    manuegar    08/22/17 - Bug 26619915 - LNX64-12.2-TFA:ORATOP DOES NOT WORK
#                           WHEN DB UNIQUE NAME DIFFERS FROM DBNAME.
#    recornej    08/18/17 - Bug 25578876 - LNX64-12.2-CALOG: THE NORMAL RETURN
#                           CODE OF "TFACTL RUN CALOG" IS NON-ZERO = 255
#    recornej    08/10/17 - Bug 24957744 - TFACTL PARAM FOR DATABASE NOT
#                           WORKING AS EXPECTED
#    manuegar    07/19/17 - Bug 26270696 - LNX64-12.2-TFA:NON ROOT INSTALL,
#                           DIAGCOLLECT -ALL DID NOT COLLECT CRS/ASM FILES.
#    cnagur      07/19/17 - Fix for Bug 26084129
#    cnagur      06/29/17 - Fix for Bug 26309164
#    bburton     05/08/17 - do not use parent.pm
#    cnagur      04/12/17 - Fix for Bug 25880916
#    bibsahoo    04/05/17 - TFA_WIN_NONDAEMON_SUPPORT
#    cnagur      03/28/17 - Fixed TFA_HOME issues - Bug 25804785 
#    cnagur      03/21/17 - TFA ND Reconfigure changes
#    cnagur      02/13/17 - Non-Root Daemon Changes
#    cnagur      01/23/17 - Changes to print TFA Version
#    bburton     11/20/16 - validate dbname
#    cnagur      11/03/16 - Fix for Bug 25039956 and 25039605
#    manuegar    10/27/16 - manuegar_srdc_14.
#    manuegar    10/25/16 - manuegar_extract_tfa_03. Added -setup to support
#                           first time ND configuration.
#    manuegar    10/20/16 - Bug 24924277 - TFA NON-DAEMON MODE : ERROR: LIST OF
#                           PROCESS IDS MUST FOLLOW -P.
#    bibsahoo    10/14/16 - Removing variable CURRENT_USER
#    cnagur      10/14/16 - Fix for Bug 24749005
#    manuegar    08/29/16 - Support the -extractto switch in the TFA installer.
#    cnagur      08/04/16 - Fix fro Bug 24406363
#    llakkana    07/18/16 - 24308220 - check TFA is running or not before
#                           checking non root user access
#    llakkana    05/02/16 - chdir when non root user in un accessible path
#    manuegar    03/31/16 - Performance improvement for tfactl.
#    llakkana    03/22/16 - 22961093: Make PERL5LIB null
#    arupadhy    12/08/15 - Conditional execution of exec in begin block for
#                           windows, due to command difference of env - linux
#                           and set - windows
#    cnagur      11/17/15 - Changes for SI
#    arupadhy    10/07/15 - catfile change
#    cnagur      09/23/15 - XbranchMerge cnagur_tfa_jcs_support_txn from
#                           st_tfa_12.1.2.5
#    bburton     09/11/15 - XbranchMerge bburton_bug-21517312 from
#                           st_tfa_12.1.2.5
#    cnagur      08/26/15 - Support for JCS
#    gadiga      08/10/15 - accept any db
#    bburton     07/30/15 - CHeck user is valid earlier and using keys -
#                           21517312
#    gadiga      07/21/15 - add parseevents
#    cnagur      05/12/15 - Changes to patch TFA in Cloud/SaaS env
#    manuegar    04/23/15 - Setup IPS directories for non root users.
#    manuegar    04/15/15 - Bug 20351399 - LNX64-12.2-TFA-FCS:DIAGCOLLECT HELP
#                           MESSAGE NEED DESCRIPTIONS FOR NEW OPTIONS.
#    cnagur      03/30/15 - Fix for Bug 20796717
#    gadiga      03/30/15 - windows
#    gadiga      03/12/15 - fix inst issue
#    gadiga      03/03/15 - ignore PERL_READLINE_NOWARN
#    cnagur      02/26/15 - Support for TFA on Cloud
#    gadiga      02/06/15 - move Readline after setting path
#    gadiga      01/28/15 - create session
#    gadiga      01/23/15 - time command
#    manuegar    01/14/15 - New tool
#    gadiga      01/08/15 - host add/remove fails in shell
#    cnagur      12/16/14 - Changes to get NODE_TYPE
#    gadiga      12/15/14 - correct user message
#    gadiga      12/11/14 - stop suptools before tfa shutdowbn
#    cnagur      11/24/14 - Fix for Bug 19985667
#    manuegar    11/05/14 - Implement <action> <toolname> <flags> for support
#                           tools.
#    manuegar    10/15/14 - Handle dynamic components.
#    manuegar    09/24/14 - Add support for xml parsing.
#    manuegar    08/14/14 - tfa/ips integration
#    manuegar    07/22/14 - Relocate tfactl_lib
#    cnagur      07/02/14 - Fix for Bug 19127261
#    manuegar    07/01/14 - 19176215: Modularize TFA
#    cnagur      07/01/14 - Fix for Bug 19068041
#    bburton     06/19/14 - Fix bug 18754405 - Ensure TFA uses GIHOME perl when
#                           available
#    bburton     05/29/14 - allow oda and add odastorage
#    amchaura    05/27/14 - collect all noexclusion directories
#    cnagur      05/23/14 - Fix for Bug 18814984
#    cnagur      05/20/14 - Added unblockTFAUser
#    bburton     05/19/14 - remove the Switch statements
#    cnagur      05/19/14 - Fix for bugs 18769166 and 18660440
#    cnagur      05/14/14 - Added some more checks in executecommand
#    amchaura    05/09/14 - Process dir files in parallel for large directories
#    cnagur      05/05/14 - Fix for Bug 18660665
#    gadiga      05/02/14 - oratop
#    cnagur      04/21/14 - Added checkfileaccessusingsu
#    cnagur      04/17/14 - Added analyze to tfactl help for non-root users
#    bburton     04/14/14 - Trace Level set by facility
#    bburton     04/14/14 - accept otion to change tracing at facility level
#    cnagur      03/26/14 - Added logsize and logcount
#    gadiga      03/19/14 - ER 18387610
#    gadiga      03/19/14 - fix 18418888
#    cnagur      03/17/14 - Updated access help
#    amchaura    03/17/14 - Fix duplicate tag clusterwide
#    cnagur      03/14/14 - Use same tag for storage cells
#    cnagur      03/13/14 - Fix for Bug 18387281
#    gadiga      03/12/14 - fix 18387575
#    gadiga      03/12/14 - fix 18381161
#    gadiga      03/11/14 - fix 18379896
#    gadiga      03/11/14 - fix 18374125
#    gadiga      03/10/14 - er 18374240
#    gadiga      03/10/14 - fix 18378871
#    cnagur      03/07/14 - Check TFAMain before running collections
#    bburton     03/03/14 - always collect crsdata/<node>/acfs for -acfs
#    cnagur      02/28/14 - Added -nocell
#    bburton     02/27/14 - add back the flag -notrim
#    amchaura    02/27/14 - Fix duplicate tagname
#    amchaura    02/26/14 - replace : in tagname and zipname to _
#    gadiga      02/24/14 - tnt components
#    amchaura    02/20/14 - Add diagcollect option -cfgtools
#    amchaura    02/19/14 - configure trimsize default 500K
#    amchaura    02/19/14 - Add noextra flag to diagcollect
#    bburton     02/13/14 - bug 18228410
#    amchaura    02/11/14 - Collect sundiag logs
#    cnagur      02/04/14 - Local and Silent to cell configure
#    cnagur      01/31/14 - Call runCellDiagcollection when -onlycell is passed
#    llakkana    01/26/14 - TFA-R Changes
#    amchaura    01/23/14 - Add acfs component
#    amchaura    01/20/14 - Add directory on local node by default and specify
#                           -node
#    cnagur      01/20/14 - Added enable and disable to access
#    amchaura    01/17/14 - Fixed directory modify options
#    cnagur      01/17/14 - Added user to diagcollect parser
#    amchaura    01/17/14 - Example for diagcollect with -collectdir
#    amchaura    01/16/14 - check file read permission for private files for
#                           nonroot diagcollect
#    cnagur      01/16/14 - Added checkfileaccess
#    amchaura    01/14/14 - Fixed tfactl dir help message
#    amchaura    01/14/14 - Set collectall flag to true when specified
#    cnagur      01/14/14 - TFA Exadata changes for Non-root users
#    cnagur      01/08/14 - Start and Stop for tfactl - Bug 18021085
#    cnagur      01/08/14 - Added copytfactl
#    gadiga      12/04/13 - TNT integration
#    cnagur      11/20/13 - Added tfactl uninstall
#    gadiga      11/19/13 - lite/full rediscovery
#    cnagur      11/19/13 - Changes for Non-root Access
#    cnagur      11/18/13 - Remove tfactlwrap changes
#    amchaura    11/13/13 - print local inventory by default
#    amchaura    11/04/13 - Fix for Bug 17719596
#    cnagur      10/22/13 - Added command to get Running Collections
#    cnagur      10/18/13 - TFA init.tfa start and shutdown functions for 12c
#    amchaura    10/18/13 - Fix for bug#17239522
#    amchaura    10/18/13 - Fix for Bug#17239463
#    amchaura    10/17/13 - Fix for bug#17607176
#    amchaura    10/16/13 - Fix for bug#17603744
#    amchaura    09/25/13 - TFA support for ODADom0
#    cnagur      09/12/13 - Support Functions for Storage Cells
#    sowsingh    10/09/13 - Addition of -dbwlm component to diagcollection
#    sowsingh    10/01/13 - Modification of collection policy of a directory
#    cnagur      08/12/13 - Fix for Bug: 17227707 [ Language Problem ]
#    cnagur      07/25/13 - Support for Exadata Cell Diagcollect
#    cnagur      07/24/13 - Exadata Support Functions
#    cnagur      07/15/13 - Fix for Bug 17026589
#    bburton     07/05/13 - Fix bug 17053993 - typo in diagcollect
#    cnagur      06/26/13 - Replace -- with - in DSCRIPT_OPTS
#    bburton     06/25/13 - Fix sudo issues
#    cnagur      06/24/13 - Missed keyword purge in purge help
#    cnagur      06/15/13 - Added purge to tfactl
#    cnagur      05/29/13 - Added Support for -nomonitor
#    cnagur      05/29/13 - Support for Build Version
#    cnagur      05/29/13 - Added Support for -chmos
#    bburton     01/18/13 - problem with exiting as root user
#    bburton     01/18/13 - deletedb -h was actually deleting the database
#    sowsingh    08/06/12 - bug 14374200
#    bburton     07/30/12 - Creation
# 
################ Documentation ################

############################ Functions List #################################
#
# Top Level Routines
#   tfactl_main
#   tfactl_shell
#   tfactl_parse_tfactl_args
#   tfactl_module_driver
#   tfactl_process_help
#   tfactl_show_commands
#   tfactl_is_cmd
#   tfactl_check_global_callbacks
#   tfactl_syntax_error
#############################################################################

BEGIN {
unless ($ENV{BEGIN_BLOCK}) {
  $ENV{POSIXLY_CORRECT} = 1;
  $ENV{BEGIN_BLOCK} = 1;
  $ENV{PERL5LIB}="";
  if ( ! $^C ) {
    if ($^O eq "MSWin32") {
      exec 'set',"$^X",$0,@ARGV;
    } else {
      exec 'env',"$^X",$0,@ARGV;
    }
  }
}
 $ENV{LC_ALL} = C;
}

use strict;
use English;
use File::Basename;
use File::Spec::Functions;
use File::Path;
use Cwd 'abs_path';
use Cwd 'chdir';
use Sys::Hostname;
use Text::ParseWords;

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME);
  push @INC, dirname($PROGRAM_NAME).'/common';
  push @INC, dirname($PROGRAM_NAME).'/modules';
  push @INC, dirname($PROGRAM_NAME).'/common/exceptions';
  $ENV{"PERL_READLINE_NOWARN"} = 1;
}

if ( $OSNAME eq "MSWin32" ) {
  eval q{use base 'Win32'; 1} or die $@;
}

use Data::Dumper;
use Storable;

use Getopt::Long; # qw(:config no_auto_abbrev);
Getopt::Long::Configure("prefix_pattern=(-|--)");
use Pod::Usage;
use Term::ReadLine;

use Date::Manip qw(ParseDate UnixDate);

# Global variables
# Declared in common/tfactlglobal.pm

# load global modules
use tfactlglobal;
use tfactlshare;
use tfactlparser;
use dbutil;

##  Sort out the TFA Home
if ( -d "$ENV{TFA_HOME}" ) {  
	$tfa_home = $ENV{TFA_HOME};
} else {
	my $exepath = abs_path($0);
	chomp($exepath);

	if ( $exepath eq "" && $ENV{HOME} ) {
		#abs_path will be null when cwd is not accessible
		chdir $ENV{HOME};
		$exepath = abs_path($0);

		if ( $exepath eq "" ) {
			$exepath = $0;
		}
	}

	my $basedir = dirname ($exepath);

	if ( $basedir =~ /\/bin/ ) {
		$basedir =~ s/\/bin//;
	}
	$tfa_home = $basedir;
}

if ( $ARGV[0] eq "version" || $ARGV[0] eq "-version" ) {
  tfactlshare_printTFAVersion($tfa_home);
  exit 0;
}
#Set verbose mode first 
tfactlshare_set_verbose();


$DAEMON_OWNER = tfactlshare_getTFADaemonOwner($tfa_home);

# Check not to run tfactl from release directory using root access
if ( $tfa_home =~ /$SI_REL_DIR$/ ) {
  if ( $current_user eq "root" ) {
    tfactlshare_signal_exception(51, undef);
  } else {
    $SETUPND = 1;
  }
}

#Print warning message if TFA is older than 180 days
if ( tfactlshare_getTFAAge($tfa_home) > $TFA_AGE_WARNING ) {
  if ( $ENV{TFA_SUPPRESS_AGE_WARN} ) {
     tfactlshare_trace(3, "tfactl (PID = $$) Suppressing Age warning due to patching", 'y', 'y');
  } else {
     print "WARNING - TFA Software is older than $TFA_AGE_WARNING days. Please consider upgrading TFA to the latest version.\n";
  }
}

# Check if we are on Cloud Env, this will set $ISCLOUD to 1 or 0
isTFAOnCloud($tfa_home);

$paramfile = tfactlshare_getSetupFilePath($tfa_home);

if ($current_user eq "root" ) {
  if ( isOfflineMode($paramfile) ){
    tfactlshare_signal_exception(51, undef);
  }
}
tfactlshare_init_trace($tfa_home);

tfactlshare_trace(3, "tfactl (PID = $$) TFA Daemon Owner : $DAEMON_OWNER", 'y', 'n');
tfactlshare_trace(3, "tfactl (PID = $$) Initialized diagnostic directories", 'y', 'n');
tfactlshare_trace(3, "tfactl (PID = $$) Common modules loaded", 'y', 'n');

tfactlshare_trace(3, "tfactl (PID = $$) ISCLOUD $ISCLOUD", 'y', 'n');
tfactlshare_trace(3, "tfactl (PID = $$) tfa_home $tfa_home", 'y', 'n');

if ( $ISCLOUD ) {
  tfactlshare_isTFAOnJCS();
}

exit FAILED if (tfactlshare_validate_user_by_key($tfa_home) eq "FAIL");


# Load the contents of components.xml into
# in-memory data structures
$tfactlglobal_components_file = catfile($tfa_home,"resources","components.xml");
if ( not -e $tfactlglobal_components_file ) {
  # Fatal error components.xml not found
  tfactlshare_signal_exception(204, undef);
}
tfactlshare_trace(5, "tfactl (PID = $$) Components file $tfactlglobal_components_file", 'y', 'y');
#tfactlshare_parse_xmlcomp();
#tfactlshare_load_xmlcomp();
# tfactlshare_dump_xmlcomp();

# $SUPPORTMODE = TRUE  => Running in non daemon mode (-extractto installation)
# $SUPPORTMODE = FALSE => Running the daemon mode
my $setupfile = tfactlshare_getSetupFilePath($tfa_home);
my $ndmode    = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"SUPPORT_MODE",$setupfile);

if ( length $ndmode && lc($ndmode) eq "true" ) {
  $SUPPORTMODE = TRUE;
} else {
  $SUPPORTMODE = FALSE;
}
### print "SUPPORTMODE $SUPPORTMODE\n";
tfactlshare_trace(5, "tfactl (PID = $$) SUPPORTMODE = $SUPPORTMODE", 'y', 'y');

if ( -w catdir($tfa_home, "internal") ) {
  $SERIALIZEMETADATA = TRUE;
}

# Serialize metadata
# Init tfa_ext_xml file
$tfactlglobal_tfa_ext_xml = catfile($tfa_home, "ext", "tfaext.xml");
if ( not tfactlshare_retrieve_serobj($tfa_home, \%tfactlglobal_exttools,"tfactlglobal_exttools","hash") ) {
  %tfactlglobal_exttools =
         tfactlshare_read_ext_xml($tfa_home, $tfactlglobal_tfa_ext_xml);
  tfactlshare_store_serobj($tfa_home, \%tfactlglobal_exttools, "tfactlglobal_exttools");
}

# Parse DB Utilites commands
$tfactlglobal_tfa_dbutlcmds = catfile($tfa_home, "resources", "tfactldbutlcmds.xml");
if ( not tfactlshare_retrieve_serobj($tfa_home, \%tfactlglobal_tfa_dbutlcommands,"tfactlglobal_tfa_dbutlcommands","hash") ) {
  tfactlparser_parse_dbutilcmds($tfactlglobal_tfa_dbutlcmds);
  tfactlshare_store_serobj($tfa_home, \%tfactlglobal_tfa_dbutlcommands, "tfactlglobal_tfa_dbutlcommands");
}

# Parse tfactldbutlschedule.xml
$tfactlglobal_tfa_dbutlsched = catfile($tfa_home, "resources", "tfactldbutlschedule.xml");
if ( not tfactlshare_retrieve_serobj($tfa_home, \@tfactlglobal_tfa_dbutlschedarr,"tfactlglobal_tfa_dbutlschedarr","array") ) {
  tfactlparser_parse_dbutilschedule($tfactlglobal_tfa_dbutlsched);
  tfactlshare_store_serobj($tfa_home, \@tfactlglobal_tfa_dbutlschedarr, "tfactlglobal_tfa_dbutlschedarr");
}
$tfactlglobal_tfa_dbutlresources = catfile($tfa_home,"resources","tfactldbutlresources.xml");

#Load dbversions to memory
my $dbversions_file = catfile("$tfa_home","internal","dbversions.json");
if ( -e $dbversions_file ) {
  $tfactlglobal_dbversions = tfactlparser_decodeJSON($dbversions_file,"file");
  %tfactlglobal_versionsMap = %tfactlglobal_jsonMap;
}
# include all the tfactl modules
my (%tfaModules);
my @staleMods;

foreach (@INC)
{
  if (-d $_)
  {
    my ($dir)   = $_;
    my (@files) = ();

    opendir (MODDIR, $dir);
    @files = readdir(MODDIR);
    foreach (@files)
    {    
      if ( $_ =~ /^tfactl/ && $_ =~ /pm$/ )
      {    
        # Load the modules only if the symlinks(if there are any) are
        # not stale.
        if(defined(open(TMPFILE  , "$dir/$_")))
        {
          close(TMPFILE);
          my (@temp) = (split(/\./, $_))[0];
          $tfaModules{$temp[0]} = $dir . '/' . $_;
        }
        else
        {
          push(@staleMods, "$dir/$_");
        }
      }    
    }    
    closedir(MODDIR);
  }
}
tfactlshare_trace(3, "tfactl (PID = $$) tfactl modules loaded", 'y', 'n');

delete($tfaModules{'tfactlglobal'});
delete($tfaModules{'tfactlshare'});

# If the module does not belong to tfactl, remove it
my @not_mod = ();
my ($module);   
foreach $module(keys %tfaModules)
{
  if ( "$module.pm" ne "tfactl_lib.pm" )
  { 
    require "$module.pm";
  } 
  my ($is_tfa) = $module. "::is_tfactl()";

  eval ($is_tfa);
  push (@not_mod, $module) if ($@);
}

foreach (@not_mod)
{
  delete ($tfaModules{$_});
}
tfactlshare_trace(3, "tfactl (PID = $$) removed modules that don't belong to tfactl", 'y', 'n');

# import modules
foreach $module(sort(keys %tfaModules))
{
  $module->import;
}
tfactlshare_trace(3, "tfactl (PID = $$) import modules", 'y', 'n');

######################## tfactlCORE Global Variables ########################
#                                                                           #
# Each module needs to specify its initialization function here.
my (@tfactl_init_modules) = ();

foreach $module(sort(keys %tfaModules))
{
  push (@tfactl_init_modules, $module . "::init()");
}
our (%tfactl_cmds) = (tfactl  => {}
                         );
  %tfactlglobal_cmds = (%tfactlglobal_cmds, %tfactl_cmds);


my ($command1, $command2);
my ($switch_val);

$tfacmd = $0;
$tfacmd =~ s/\.pl$//;

$hostname = tolower_host();
$hostname = trim($hostname);
tfactlshare_trace(3, "tfactl (PID = $$) Sort out the tfa_home: $tfa_home", 'y', 'n');

#Changed this as we can do GI Install on ODA
#if (!( -f "/opt/oracle/oak/bin/oakd" ) && $tfa_home =~ /$hostname/) {
if ( $tfa_home =~ /tfa\/$hostname\/tfa_home/ ) {
my $tfabase = $tfa_home;
$tfabase =~ s/\/tfa_home//;
my @dirs = split(/\//, $tfabase);
my $base;
for (my $c=0; $c<scalar(@dirs)-1; $c++) {
 $base .= "@dirs[$c]/";
}
$base .= "bin";
$tfacmd="$base/tfactl";
}

# Use crshome/bin/tfactl in help if it is present
$crs_home = get_crs_home($tfa_home);
tfactlshare_trace(3, "tfactl (PID = $$) crs_home $crs_home", 'y', 'n');

my $tfactl_file;
if($IS_WINDOWS){
  $tfactl_file = catfile($crs_home,"bin","tfactl.bat");
}else{
  $tfactl_file = catfile($crs_home,"bin","tfactl");
}
if ( -f $tfactl_file ) {
  $tfacmd = catfile($crs_home,"bin","tfactl");
}

tfactlshare_trace(3, "tfactl (PID = $$) tfacmd: $tfacmd", 'y', 'n');

# Check Access for non-root users
$current_user = tfactlshare_getUserName();
if ($IS_WINDOWS) {
  $current_user = tfactlshare_getEscapedUserName($current_user);
}

tfactlshare_trace(3, "tfactl (PID = $$) Current user executing TFA $current_user", 'y', 'n');

$IS_TFA_ADMIN = tfactlshare_isAdminUser();

tfactlshare_trace(3, "tfactl (PID = $$) IS_TFA_ADMIN : $IS_TFA_ADMIN", 'y', 'n');

if ( ! $IS_TFA_ADMIN ) {
	if ( ! $ISCLOUD ) {
		if ( isTFARunning($tfa_home) == FAILED ) {
      tfactlshare_trace(3, "tfactl (PID = $$) TFA daemon is not running, exiting...", 'y', 'n');
      exit FAILED;;
    }
    my $access = checkUserAccess( $tfa_home ); 
    tfactlshare_trace(3, "tfactl (PID = $$) Checking user access, $access", 'y', 'n');
  }
}

#$paramfile = catfile ($tfa_home, "tfa_setup.txt");
$paramfile = tfactlshare_getSetupFilePath($tfa_home);
if ( $ISCLOUD ) {
  my $homedir = getHomeDirectory();
  $homedir = catfile($homedir, ".tfa");
  #$paramfile = catfile($homedir, "tfa_setup.txt");
  my $tfa_base;

  if ( -f $paramfile ) {
    $tfa_base = getTFABase($paramfile);
  }

	# Auto Setup ND in ADE View
	if ( $IS_ADE || $tfa_home =~ /$SI_REL_DIR$/ ) {
		if ( ! -d "$homedir" ) {
			$SETUPND = 1;
		} else {
			$SETUPND = 0;
		}
	}

        # manuegar_extract_tfa_03
        # -setupnd section

        # TFA Non Daemon setup / Reconfigure 
        if ( $SETUPND || ! -d catdir($tfa_base, "database") ) {
            configureTFABase($tfa_home);
            my $rep = tfactlshare_get_repository_location($tfa_home);
            tfactlshare_check_trace($tfa_home, $current_user, $rep);
            tfactlshare_setup_alltool_dir_for_user ($tfa_home, $current_user, $rep);
            print "\nRun Inventory process started... It might take a couple of minutes.\n";
            runTFAInventory($tfa_home,0,1);
            print "\nRun Inventory process completed.\n";
            my $perl = tfactlshare_getPerl($tfa_home);
            system("$perl $tfa_home/bin/tfactl.pl rediscover -mode lite");
            
            $tfactlglobal_hash{'iscloud'} = "1";
            $tfa_base = getTFABase($paramfile);
            $tfactlglobal_hash{'tfa_base'} = $tfa_base;
        } else {
            my $ibid_file = catfile($tfa_base, "internal", ".buildid");
            if ( -r "$ibid_file" ) {
              my $ibid = tfactlshare_cat($ibid_file);
              $ibid = trim($ibid);
              $ibid = 0 if ( ! $ibid );

              my $bid = 0;
              my $bid_file = catfile($tfa_home, "internal", ".buildid");

              if ( -r $bid_file ) {
                $bid = tfactlshare_cat($bid_file);
                $bid = trim($bid);
              }
              $bid = 0 if ( ! $bid );

              if ( $bid > $ibid ) {
                print "\nTFA Build ID : $bid\tInstalled Build ID : $ibid\n";
                print "\nUpgrading TFA to $bid...\n";
                tfactlshare_upgradeTFABase($tfa_home, $tfa_base, $homedir);
              } # end if $bid > $ibid
            } # end if -r "$ibid_file"
        } # end if # TFA non daemon setup
}

# Serialize metatada
my $serobjfile = catfile($tfa_home,"internal","tfaxmlcomponents");
my @objarray = ();
my @addcomparray = ();

if ( $SERIALIZEMETADATA && (-e $serobjfile . "_0.ser") ) {
  @xmlcompsarray = ();
  @validatexmlcompsarray = ();
  @retcomparray = ();
  %tfactlglobal_xmlcompshash = ();
  my $ADDCOMPSTRING_ref;
  my $ADDCOMPHLPSTRING_ref;
  my $ADDCOMPHLPDESC_ref;
  my $ADDCOMPSTRING_EXADATA_ref;
  my $ADDCOMPHLPSTRING_EXADATA_ref;
  my $ADDCOMPHLPDESC_EXADATA_ref;
  my $ADDCOMPSTRING_ODA_ref;
  my $ADDCOMPHLPSTRING_ODA_ref;
  my $ADDCOMPHLPDESC_ODA_ref;
  my $ADDCOMPSTRING_RACDBCLOUD_ref;
  my $ADDCOMPHLPSTRING_RACDBCLOUD_ref;
  my $ADDCOMPHLPDESC_RACDBCLOUD_ref;

  (@xmlcompsarray) = @{ retrieve $serobjfile . "_0.ser" };
  (@validatexmlcompsarray) = @{ retrieve $serobjfile . "_1.ser" };
  (@addcomparray) = @{ retrieve $serobjfile . "_2.ser" };
  (@retcomparray) = @{ retrieve $serobjfile . "_3.ser" };
  (%tfactlglobal_xmlcompshash ) = %{ retrieve $serobjfile . "_4.ser" };

  ( $ADDCOMPSTRING_ref, $ADDCOMPHLPSTRING_ref,
    $ADDCOMPHLPDESC_ref, $ADDCOMPSTRING_EXADATA_ref, $ADDCOMPHLPSTRING_EXADATA_ref, 
    $ADDCOMPHLPDESC_EXADATA_ref, $ADDCOMPSTRING_ODA_ref, $ADDCOMPHLPSTRING_ODA_ref,
    $ADDCOMPHLPDESC_ODA_ref, $ADDCOMPSTRING_RACDBCLOUD_ref, $ADDCOMPHLPSTRING_RACDBCLOUD_ref,
    $ADDCOMPHLPDESC_RACDBCLOUD_ref) = @addcomparray;

  $ADDCOMPSTRING = $$ADDCOMPSTRING_ref;
  $ADDCOMPHLPSTRING = $$ADDCOMPHLPSTRING_ref;
  $ADDCOMPHLPDESC = $$ADDCOMPHLPDESC_ref;
  $ADDCOMPSTRING_EXADATA = $$ADDCOMPSTRING_EXADATA_ref;
  $ADDCOMPHLPSTRING_EXADATA = $$ADDCOMPHLPSTRING_EXADATA_ref;
  $ADDCOMPHLPDESC_EXADATA = $$ADDCOMPHLPDESC_EXADATA_ref;
  $ADDCOMPSTRING_ODA = $$ADDCOMPSTRING_ODA_ref;
  $ADDCOMPHLPSTRING_ODA = $$ADDCOMPHLPSTRING_ODA_ref;
  $ADDCOMPHLPDESC_ODA = $$ADDCOMPHLPDESC_ODA_ref;
  $ADDCOMPSTRING_RACDBCLOUD = $$ADDCOMPSTRING_RACDBCLOUD_ref;
  $ADDCOMPHLPSTRING_RACDBCLOUD = $$ADDCOMPHLPSTRING_RACDBCLOUD_ref; 

  ### print "Retrieving ...\n";
} else {
  tfactlshare_parse_xmlcomp($tfa_home);
  tfactlshare_load_xmlcomp($tfa_home);

  if ( $SERIALIZEMETADATA ) {
    @addcomparray = ( \$ADDCOMPSTRING, \$ADDCOMPHLPSTRING, \$ADDCOMPHLPDESC,
          \$ADDCOMPSTRING_EXADATA, \$ADDCOMPHLPSTRING_EXADATA, \$ADDCOMPHLPDESC_EXADATA, \$ADDCOMPSTRING_ODA,
          \$ADDCOMPHLPSTRING_ODA, \$ADDCOMPHLPDESC_ODA, \$ADDCOMPSTRING_RACDBCLOUD, \$ADDCOMPHLPSTRING_RACDBCLOUD,
          \$ADDCOMPHLPDESC_RACDBCLOUD);

    @objarray = ( \@xmlcompsarray, \@validatexmlcompsarray, \@addcomparray, \@retcomparray, \%tfactlglobal_xmlcompshash ); 
    # Not root users cannot store this data.
    if ( $current_user eq "root" or $current_user eq $DAEMON_OWNER ) {
      tfactlshare_multistore_serobj($tfa_home, \@objarray, "tfaxmlcomponents");
    }
  } # end if $SERIALIZEMETADATA

  ### print "storing ....\n";
}

=head
  print "xmlcompsarray @xmlcompsarray \n";
  print "validatexmlcompsarray @validatexmlcompsarray\n";
  print "ADDCOMPSTRING $ADDCOMPSTRING\n";
  print "ADDCOMPHLPSTRING $ADDCOMPHLPSTRING\n";
=cut

# manuegar_srdc_14
tfactlshare_load_srdc_help($tfa_home);

#print "Checking current user...\n";
#my $current_user = getpwuid($<);
#print "currUser = $current_user\n";

#if ( !isODA() && !isOfflineMode($paramfile))
#{
#  if ( ! -r "$tfa_home/bin/tfactlwrap" )
#  {
#    print "TFA is not setup. Running setup now...\n";
#    system("$tfa_home/bin/tfasetup.pl");
#  }
#}


#EXADATA SETUP:
$NODE_TYPE = tfactlshare_get_val4key_in_tfa_setup($tfa_home, "NODE_TYPE");
$EXADATA = isExadataConfigured( $tfa_home );
$EXADATA_SETUP = isExadata( $tfa_home );
tfactlshare_trace(3, "tfactl (PID = $$) Checking EXADATA: $EXADATA, ".
                  " EXADATA_SETUP: $EXADATA_SETUP", 'y', 'n');

doVars($paramfile);

# See if we have the ssocket set yet 
#print "set TFAHOME to : $tfa_home and sock: $PORT\n";
# TODO -- this is some stuff for the support version..
if ($tfa_home =~ /TFA\/base/)  {
  print "You must run this code from your SR directory\n";
  exit 1;
}

# Send errors to log
#tfactlshare_trace(3, "tfactl (PID = $$) Initializing diagnostic directories", 'y', 'n');
#tfactlshare_check_tfauser_diag($tfa_home);
#tfactlshare_init_trace($tfa_home);

# Validate if command line options were provided
my $before_argv = @ARGV;
my $after_argv;

#Do not allow newline in arguments
foreach (@ARGV) {
  if ($_ =~ /[\n\r]+/ ) {
    print "Invalid Argument passed:$_\n";
    print "New line character is not allowed \n";
    exit(1);
  }
}

GetOptions('start'         => \$START,
           'stop'          => \$STOP,
           'shutdown'    => \$SHUTDOWN,
           'enable'    => \$ENABLE,
           'disable'     => \$DISABLE,
           'initstart'     => \$STARTFROMINIT,
           'initstop'    => \$STOPFROMINIT,
           'manager'          => \$MANAGER,
           'check'          => \$CHECK,
           'clean'          => \$CLEAN,
           'adddirectory=s'  => \$ADDDIR,
           #'d=s'  => \$DBNAME,
           #'i=s'  => \$INSTANCE_NAME,
           'addhost=s'  => \$ADDHOST,
           'removehost=s'  => \$RMHOST,
           'adddom0ip=s' => \$ADDDOM0IP,
           'removedom0ip' => \$RMDOM0IP,
           'h=s'  => \$HOST,
           'removedirectory=s' => \$RMDIR,
           'rundiscovery' => \$RUNDISC,
           'printdirectories' => \$PRINTDIRS,
           'repositorydir=s' => \$CHANGEREPO,
           'reposizeMB=s' => \$CHANGEREPOSIZE,
           'printrepository' => \$PRINTREPO,
           'printconfig' => \$PRINTCONFIG,
           'printinternalconfig' => \$PRINTINTERNALCONFIG,
           'printhosts' => \$PRINTHOSTS,
           'printdom0ip' => \$PRINTIP,
           'printactions' => \$PRINTACTIONS,
           'printcookie' => \$PRINTCOOKIE,
           'printtfahome' => \$PRINTTFAHOME, 
           'printwalletpassword' => \$PRINTWALLETPASSWORD,
           'printcells' => \$PRINTCELLS,
           'printonlinecells' => \$PRINTONLINECELLS,
           'printbuildversion' => \$PRINTBUILDVERSION,
           'printongoingcoll' => \$PRINTONGOINGCOLL,
           'senduninstallupdate' => \$SENDUNINSTALLUPDATE,
           'stop_suptools' => \$STOPSUPTOOLS,
           'parseevents' => \$PARSEEVENTS,
           'printlog' => \$PRINTTFALOG,
           'runinventory' => \$RUNINVENTORY,
           'printinventory' => \$PRINTINVENTORY,
           'printinvrunstatus' => \$PRINTINVRUNSTAT,
           'printadrincidents' => \$PRINTADRINCIDENTS,
           'printcellinvrunstatus' => \$PRINTCELLINVRUNSTAT,
           'printcelldiagstatus' => \$PRINTCELLDIAGSTAT,
           'configurecells' =>$CONFIGURECELLS,
           'checkfiletypepattern' => \$CHECKFILETYPEXML,
           'printstartups' => \$PRINTSTARTUPS,
           'printshutdowns' => \$PRINTSHUTDOWNS,
           'printparameters' => \$PRINTPARAMETERS,
           'printerrors' => \$PRINTERRORS,
           'printcollections' => \$PRINTCOLLECTIONS,
           'checkversion' => \$CHECKVERSION,
           'collectzips=s' => \$COLLECTZIPS,
           'deletedb'   => \$DELETEDB,
           'zipfilesfordate'   => \$ZIPFILESFORDATE,
           'startdate=s'   => \$STARTDATE,
           'enddate=s'   => \$ENDDATE,
           'from=s'   => \$STARTDATE,
           'to=s'   => \$ENDDATE,
           'since=s'   => \$SINCE,
           'for=s'   => \$FOR,
           'outfile=s'   => \$OUTFILE,
           'o=s'   => \$OUTFILE,
           'mode=s'   => \$RDMODE,
           'clusterwide' => \$CLUSTERWIDE,
           'c' => \$CLUSTERWIDE,
           'runscan'     => \$RUNSCAN,
           'purge'       => \$PURGE,
           'uninstall'   => \$UNINSTALL,
           'diagnosetfa'   => \$DIAGNOSETFA,
           'sendmail'    => \$SENDMAIL,
           'h'     => \$HELP,
           'help'          => \$HELP) or print_help ("main");
 $after_argv = @ARGV;
 tfactlshare_trace(3, "tfactl (PID = $$) Command line options validated, GetOptions()", 'y', 'n');

 # Command line options were provided
 if ($before_argv != $after_argv) {
   if ( $HELP ) {
     print_help ("main");
   } else {
           if ( $START ) { $ARGV[0] = "start"; }
           elsif ( $STOP ) { $ARGV[0] = "stop"; }
           elsif ( $SHUTDOWN ) { $ARGV[0] = "shutdown"; }
           elsif ( $ENABLE ) { $ARGV[0] = "enable"; }
           elsif ( $DISABLE ) { $ARGV[0] = "disable"; }
           elsif ( $STARTFROMINIT ) { $ARGV[0] = "initstart"; }
           elsif ( $STOPFROMINIT ) { $ARGV[0] = "initstop"; }
           elsif ( $MANAGER ) { $ARGV[0] = "gui"; }
           elsif ( $CHECK ) { $ARGV[0] = "check"; }
           elsif ( $CLEAN ) { $ARGV[0] = "clean"; }
           elsif ( defined($ADDDIR) ) { $ARGV[0] = "directory"; $ARGV[1] = "add";
                                        $ARGV[2] = $ADDDIR; }
           elsif ( defined($RMDIR) ) { $ARGV[0] = "directory"; $ARGV[1] = "remove";
                                        $ARGV[2] = $RMDIR }
           elsif ( defined($ADDHOST) ) { $ARGV[0] = "host"; $ARGV[1] = "add";
                                        $ARGV[2] = $ADDHOST; } 
           elsif ( defined($RMHOST) ) { $ARGV[0] = "host"; $ARGV[1] = "remove";
                                        $ARGV[2] = $RMHOST; }
           elsif ( defined($ADDDOM0IP) ) { $ARGV[0] = "dom0IP"; $ARGV[1] = "add";
                                        $ARGV[2] = $ADDDOM0IP; }
           elsif ( defined($RMDOM0IP) ) { $ARGV[0] = "dom0IP"; $ARGV[1] = "remove";
                                        $ARGV[2] = $RMDOM0IP; }
           elsif ( $PRINTDIRS ) { $ARGV[0] = "print"; $ARGV[1] = "directories"; }
           elsif ( defined($CHANGEREPOSIZE) ) { $ARGV[0] = "set"; 
                                                $ARGV[1] = "reposizeMB=".$CHANGEREPOSIZE; }
           elsif ( $PRINTREPO ) { $ARGV[0] = "print"; $ARGV[1] = "repository"; }
           elsif ( $PRINTCONFIG ) { $ARGV[0] = "print"; $ARGV[1] = "config"; }
           elsif ( $PRINTINTERNALCONFIG ) { $ARGV[0] = "print"; $ARGV[1] = "internalconfig"; } 
           elsif ( $PRINTHOSTS ) { $ARGV[0] = "print"; $ARGV[1] = "hosts"; }
           elsif ( $PRINTIP ) { $ARGV[0] = "print"; $ARGV[1] = "dom0IP"; }
           elsif ( $PRINTACTIONS ) { $ARGV[0] = "print"; $ARGV[1] = "actions"; }
           elsif ( $PRINTCOOKIE ) { $ARGV[0] = "print"; $ARGV[1] = "cookie"; }
           elsif ( $PRINTTFAHOME ) { $ARGV[0] = "print"; $ARGV[1] = "tfahome"; }
           elsif ( $PRINTWALLETPASSWORD ) { $ARGV[0] = "print"; $ARGV[1] = "walletpassword"; }
           elsif ( $PRINTCELLS ) { $ARGV[0] = "print"; $ARGV[1] = "cells"; }
           elsif ( $PRINTONLINECELLS ) { $ARGV[0] = "print"; $ARGV[1] = "onlinecells"; }
           elsif ( $PRINTBUILDVERSION ) { $ARGV[0] = "print"; $ARGV[1] = "buildversion"; } 
           elsif ( $PRINTONGOINGCOLL ) { $ARGV[0] = "print"; $ARGV[1] = "collections";
                       $ARGV[2] = "-status"; $ARGV[3] = "running"; }
           elsif ( $SENDUNINSTALLUPDATE ) { $ARGV[0] = "senduninstallupdate"; }
           elsif ( $STOPSUPTOOLS ) { $ARGV[0] = "stop_suptools"; }
           elsif ( $PARSEEVENTS ) { $ARGV[0] = "parseevents"; }
           elsif ( $PRINTTFALOG ) { $ARGV[0] = "print"; $ARGV[1] = "log"; }
           elsif ( $RUNINVENTORY ) { $ARGV[0] = "run"; $ARGV[1] = "inventory"; }
           elsif ( $PRINTINVENTORY ) { $ARGV[0] = "print"; $ARGV[1] = "inventory"; }
           elsif ( $PRINTINVRUNSTAT ) { $ARGV[0] = "print"; $ARGV[1] = "invrunstat"; }
           elsif ( $PRINTADRINCIDENTS ) { $ARGV[0] = "print"; $ARGV[1] = "adrincidents"; }
           elsif ( $PRINTCELLINVRUNSTAT ) { $ARGV[0] = "print"; $ARGV[1] = "cellinvrunstat"; }
           elsif ( $PRINTCELLDIAGSTAT ) { $ARGV[0] = "print"; $ARGV[1] = "celldiagstat"; }
           elsif ( $CONFIGURECELLS ) { $ARGV[0] = "configurecells"; }
           elsif ( $CHECKFILETYPEXML ) { $ARGV[0] = "checkfiletypepattern"; }
           elsif ( $PRINTSTARTUPS ) { $ARGV[0] = "print"; $ARGV[1] = "startups"; }
           elsif ( $PRINTSHUTDOWNS ) { $ARGV[0] = "print"; $ARGV[1] = "shutdowns"; }
           elsif ( $PRINTPARAMETERS ) { $ARGV[0] = print""; $ARGV[1] = "parameters"; }
           elsif ( $PRINTERRORS ) { $ARGV[0] = "print"; $ARGV[1] = "errors"; }
           elsif ( $PRINTCOLLECTIONS ) { $ARGV[0] = "print"; $ARGV[1] = "collections"; }
           elsif ( $CHECKVERSION ) { $ARGV[0] = "print"; $ARGV[1] = "version"; }
           elsif ( $COLLECTZIPS ) { $ARGV[0] = "collectzips"; $ARGV[1] = $COLLECTZIPS; }
           elsif ( $DELETEDB ) { $ARGV[0] = "deletedb"; }
           elsif ( $ZIPFILESFORDATE && $STARTDATE && $ENDDATE && 
                   $OUTFILE && $CLUSTERWIDE && $SINCE && $FOR ) { $ARGV[0] = "zipfiles"; }
           elsif ( $RUNDISC ) { $ARGV[0] = "run"; $ARGV[1] = "discovery"; }
           elsif ( $RUNSCAN ) { $ARGV[0] = "run"; $ARGV[1] = "scan"; }
           elsif ( $PURGE ) { $ARGV[0] = "purge"; }
           elsif ( $UNINSTALL ) { $ARGV[0] = "uninstall"; }
           elsif ( $DIAGNOSETFA ) { $ARGV[0] = "diagnosetfa"; }
           elsif ( $SENDMAIL ) { $ARGV[0] = "sendmail"; }
           elsif ( defined($RDMODE) ) { $ARGV[0] = "rediscover"; $ARGV[1] = $RDMODE; }
           elsif ( $HELP ) { $ARGV[0] = "help"; }

           
           @tfactlglobal_argv = @ARGV;
           tfactl_main();
           return; 
           #tfactlshare_pre_dispatch();
           }
 }
 else
 {
  # Call entry point
  @tfactlglobal_argv = @ARGV;
  tfactlshare_trace(3, "tfactl (PID = $$) Calling tfactl_main()", 'y', 'n');
  tfactl_main();
  return;
 }

 exit 0;
############################ Top Level Routines ##############################
#
# Routines that calls exit():
#   tfactl_main                  - exit 0
#   tfactl_syntax_error          - exit 0
#   tfactlshare_signal_exception - exit 1
#   tfactl_shell                 - exit -1

########
# NAME
#   tfactl_main
#
# DESCRIPTION
#   This function is the main function of tfactl.  It is the first
#   function that is called.
#
# PARAMETERS
#   None.
#
# RETURNS
#   Null.
#
########
sub tfactl_main 
{
  my ($module);
  my ($mypath);
  my ($cmd);

  $mypath = $ENV{'PATH'};
  chomp($mypath);
  $tfactlglobal_hash{'tempdir'} = File::Spec->tmpdir();

  # Parse for consistency check option before calling init_modules
  tfactl_consistency_check();

  # Print warnings about the stale links
  if(scalar(@staleMods) > 0)
  {
    foreach(@staleMods)
    {
      tfactlshare_trace(2, "$_ either does not exist or it is a stale link",
                           "Y", "N");
    }
  }

  # Initialize modules.
  tfactlshare_trace(3, "tfactl (PID = $$) tfactl_main Initializing modules", 'y', 'n');
  for $module (@tfactl_init_modules)
  {
    eval($module);
  }

  # Check to see if all the modules have initialized the global callbacks
  # correctly.
  tfactl_check_global_callbacks();
  tfactl_get_system_endian();
  tfactl_parse_tfactl_args();

  # Process the commands.
  tfactlshare_trace(3, "tfactl (PID = $$) tfactl_main calling tfactl_shell($mypath)", 'y', 'n');
  tfactl_shell($mypath);

  # Always exit zero here.  Exiting non-zero is done only from exception 
  # routine.  See tfactl_signal_exception().
  exit 0;
}

########
# NAME
#   tfactl_get_system_endian
#
# DESCRIPTION
#   This routine gets the system's endianness and stores it in a global
#   variable.
#
# PARAMETERS
#    None.
#
# RETURNS
#   Null.
#
# NOTES
########
sub tfactl_get_system_endian
{
  # The first bit of a little endian system is 1, and for big endian
  # system is 0.
  if (unpack("b*", pack("s", 1)) =~ /^1/)
  {
    # System is little endian.
    $tfactlglobal_hash{'endn'} = 1;
  }
  else
  {
    # System is big endian.
    $tfactlglobal_hash{'endn'} = 0;
  }
}

########
# NAME
#   tfactl_shell
#
# DESCRIPTION
#   This routine contains the top-level shell loop that prompts the user for
#   for commands and calls other routines to process them.
#
# PARAMETERS
#   mypath (IN) - $path env variable for supporting os commands
#                 in interactive mode
#
# RETURNS
#   Null.
#
# NOTES
#
########
sub tfactl_shell 
{
  my ($line);                                 # One line of input from user. #
  my ($prompt) = 'tfactl> ';                  # tfactl user prompt value.    #
  my ($term);
  my (@eargs);
  my ($lastflag) = 0;        #Flag to indicate last iteration of while loop
  my ($mypath) = shift;
  my ($cmd);

  # Set initial src mod
  $tfactlglobal_hash{'srcmod'} = "tfactl";

  # This is the right place for registering the signal handler. Initially it
  # was registered when the modules where loaded in global scope. Handling 
  # the ctrl-C signal before connecting to the TFAMain instance (and starting 
  # TFAMain command prompt)

  $SIG{INT} = \&tfactlshare_signal_handler;# Signal handler for tfactl       #
  $tfactlshare_logheader = "tfactl (PID = $$): ";

  # If non-interactive mode, process command and return.
  if ($tfactlglobal_hash{'mode'} eq 'n')
  {
    # Construct the command arguments from ARGV and log it
    my ($i,$token);
    my (@args) = ();
    for( $i = 0; $i<= $#ARGV; $i++)
    {
       $token = $ARGV[$i];
       if($token !~ /^-/ && $token =~ /\W/ && $token !~ /'/)
       {
          $args[$i] = "'$token'"; # Put back the single quotes for tokens like 
                                  # patterns, etc. The quotes are stripped by
                                  # the shell.
       }
       else
       {
          $args[$i] = $token;
       }
    }
    $line = join(" ", @args);
    if($line)
    {
        ##print "Given command $line \n";
        tfactlshare_trace(3, "tfactl (PID = $$) tfactl_shell Given command - ".
                              " $line", 'y', 'n');
    }

    # Call module driver for non interactive session
    {
      eval
      {
         tfactlshare_trace(3, "tfactl (PID = $$) tfactl_shell Calling tfactl_module_driver() for non interactive session", 'y', 'n');
         tfactl_module_driver();
      };
      if(tfactlexceptions::catch())
      {
        my $err = tfactlexceptions::getExceptionstring ();
        tfactlshare_trace (3,
                           "tfactl_shell Unhandled Exception non-interactive mode $err",
                           'y', 'n');
         # Set the exit status to -1
         $tfactlglobal_hash{'e'} = -1;
      }
    }

    exit $tfactlglobal_hash{'e'};
  } # non interactive session end

  if (-e "/dev/tty")
  {
    $term = new Term::ReadLine("", \*STDIN, \*STDOUT);
  }
  else
  {
    $term = new Term::ReadLine("CON", \*STDIN, \*STDOUT);
  }

  if ($term->Features->{ornaments})
  {
    local $Term::ReadLine::termcap_nowarn = 1;
    $term->ornaments(0);
  }

  # Create a session in trace directory
  my $sessionid = time;
  $ENV{TFA_SESSION_ID} = $sessionid;

  tfactlshare_session_trace ($sessionid, "INFO", "Started session");
  while (1)
  {
    if ($lastflag == 1)
    {
      $lastflag = 0;   #Reset flag (which is reduandant as of now)
      last;
    }

    my $prompt_now = "";
    foreach my $key (keys %tfactlglobal_ctx)
    {
      my $env_key = "TFA_SESSION_" . uc($key);
      $ENV{$env_key} = $tfactlglobal_ctx{$key};

      if ( $key !~ /\-/ && $tfactlglobal_ctx{$key} )
      {
        $prompt_now .= $tfactlglobal_ctx{$key} . " ";
      }
    }
    $prompt_now .= $prompt;
    eval
    {
      my (@token);# Need fresh array of parsed tokens of arguments from $line. #

      select STDERR;
      $|++;
      select STDOUT;
      $|++;

      $line = $term->readline($prompt_now);
      # print "Line $line \n";

      if (defined($line))
      {
        chomp($line);                           # Remove newline character.    #
        $line =~ s,^\s+,,g;                     # Remove initial spaces.       #
        $line =~ s,\s+$,,g;                     # Remove trailing spaces.      #
        # $tfactlglobal_hash{'cmd'}
        ## print "Given command $line \n";
        tfactlshare_trace(3, "tfactl (PID = $$) tfactl_shell Given command - ".
                       " $line", 'y', 'n');
      }
      tfactlshare_session_trace ($sessionid, "COMMAND", "$line");

      # Terminate if EOF or 'exit'.
      if (! defined($line))
      {
        $line = 'exit';
        print "exit\n";
      }

      #last if ($line eq 'exit');
      #last if ($line eq 'quit');
      if (lc($line) eq 'exit' || lc($line) eq 'quit')
      {
        $lastflag = 1;
        die;
      }

      my @words = split(/\s+/, $line);
      my $dup_command = 0;  # host add is a TFA command. So shell should ignore such commands.
      $dup_command = tfactl_check_dup_commands(@words);
      # Support external os commands
      if ( $line =~ /^!/ )
      {
        $ENV{'PATH'} = $mypath;
        $line =~ s/^!//;

        my $cmd;
        my $os = $^O;

        if($os eq "MSWin32")
        {
          $cmd = "$line";
        }
        else
        {
          $cmd="$line 1>&1";
        }

        system($cmd);

      }
       elsif ( $dup_command == 0 && defined $words[0] && exists $tfactlglobal_ctx_commands{$words[0]} )
       {
         my $a_key = $words[0];
         $a_key = $tfactlglobal_ctx_commands{$words[0]} if ( $tfactlglobal_ctx_commands{$words[0]} ne "1" );
         if ( $#words == 0 )
         {
           $tfactlglobal_ctx{$a_key} = "";
           print "Removed $a_key from analysis context.\n";
         }
          else
         {
           shift(@words);
           my $val = tfactl_validate_ctx($a_key, @words);
           if ( $val )
           {
             $tfactlglobal_ctx{$a_key} = $val;
             print "Set $a_key to $val\n";
           }
         }
       }
      else
      {
        # Parse $line into an array of arguments.
        if (tfactlbase_parse_int_cmd_line($line, \@token))
        {
          # tfactl_parse_int_cmd_line() returned error. #
          tfactlshare_error_msg(307, undef);
          #next;
          # Error, so done with this command, move on to next comand. #
          die;
        }

        die if ($token[0] eq '');           # Empty line, so skip command. #

        # Save command name intsess. #
        $cmd = $tfactlglobal_hash{'cmd'} = shift(@token);
        @ARGV = @token; # Save in global @ARGV for internal command parsing. #

        # Call module driver for interactive session
        {
          # Need to enclose this call to module_driver() in eval block, since
          # an exception could be thrown.
          # Here, the mode is interactive, hence no need to set exit status.
          # Catch the exception, check if it isn't an tfactlexceptions 
          # exception issue a die statement. (Propogate other exceptions up)
          eval
            {
              @tfactlglobal_argv = parse_line('\s+', 1, $line);
              ##print "Line $line \n";
              ##print "Global array  @tfactlglobal_argv \n";
              # call module driver
              tfactlshare_trace(3, "tfactl (PID = $$) tfactl_shell CAlling tfactl_module_driver() for interactive session", 'y', 'n');
              tfactl_module_driver();
            };
          if(tfactlexceptions::catch())
          {
            my $err = tfactlexceptions::getExceptionstring ();
            tfactlshare_trace (3,
                                 "Unhandled Exception interactive mode $err",
                                 'y', 'n');
            die;
          }
        }

        $term->addhistory($line);

      }
    };
  }

  return;
}

########
# NAME
#  tfactl_consistency_check
#
# DESCRIPTION
#  This routine parses command line arguments only for consistency check option
#  not anyother the arguments  related to tfactl or commands internal to tfactl.
#
# PARAMETERS
#   GLOBAL: @ARGV (IN/OUT) - list of all command line arguments for tfactl.
#
# RETURNS
#   Null.
#
#  Note also that this routine removes the consistency check option if found in
#  ARGV
########
sub tfactl_consistency_check
{
  my $i;
  for ($i = 0; $i < $#ARGV+1; $i++)
  {
    if ($ARGV[$i] eq '-check')
    {
      #remove the option from ARGV array if found
      splice(@ARGV,$i,1);

      #set the global to denote that consistency check is ON
      #later used in init() function in all perl modules
      $tfactlglobal_hash{'consistchk'} = 'y';
      print STDERR "WARNING: tfactl consistency check enabled\n";
      last;
    }
  }

  return;  
}

########
# NAME
#   tfactl_parse_tfactl_args
#
# DESCRIPTION
#   This routine parses the command line arguments for tfactl.
#
# PARAMETERS
#   GLOBAL: @ARGV (IN/OUT) - list of all command line arguments for tfactl.
#
# RETURNS
#   Null.
#
#  Note also that this routine *modifies* @ARGV; all parsed arguments are
#  removed from this array.
########
sub tfactl_parse_tfactl_args 
{
  my ($args_ref);
  my (%args) = ();
  my ($i, $len);
  my (@tfactl_arg) = ();
  my (@cmd_arg) = ();
  my ($cmd) = @ARGV[0]; # 'tfactl';
  my (@string);
  my ($key);

  # chop off the @ARGV array, so we process tfactl arguments
  for ($i = 0; $i < $#ARGV+1; $i++)
  {
    if (defined ($tfactlglobal_cmds{$ARGV[$i]}))
    {
      last;
    }
  }
  $len = $#ARGV;
  @tfactl_arg = @ARGV[0..$i-1] if (defined(@ARGV[0..$i-1]));
  @cmd_arg    = @ARGV[$i..$len] if (defined(@ARGV[$i..$len]));

  @ARGV = @tfactl_arg;

   #build the list of options to parse using GetOptions
  if($tfactl_cmds{ $cmd }{ flags })
  {
    foreach $key(keys %{$tfactl_cmds{ $cmd }{ flags }})
    {
      push(@string, $key);
    }
  }

  #include deprecated options if any
  if($tfactlglobal_deprecated_options{ $cmd })
  {
    foreach my $key(keys %{$tfactlglobal_deprecated_options{ $cmd }})
    {
      push(@string, $tfactlglobal_deprecated_options{$cmd}{$key}[0]);
    }
  }

  if ( $cmd eq '' ) {
    return;
  } else {
          $tfactlglobal_hash{'cmd'} = $cmd;
          if ( !tfactl_validate_command() ) {
            print_help("main");
            exit 0;
          }
  }

  if(defined $args{'tfactl'})
  {
    if (!defined($tfactlglobal_cmds{${$args{'tfactl'}}[0]}))
    {
      tfactl_show_commands('exit', \*STDERR);
      return;
    }
  }

  #Set the correct options if deprecated options were used and print WARNING.
  #tfactlshare_handle_deprecation($tfactlglobal_hash{ 'cmd'},\%args);
  tfactlshare_handle_deprecation($cmd, \%args);

  # reconstruct @ARGV for the command arguments
  @ARGV = @cmd_arg;
  # if a command is passed, check that it is a valid one
  if (defined($ARGV[0]))
  {
    if (!defined($tfactlglobal_cmds{$ARGV[0]}))
    {
      tfactl_show_commands('exit', \*STDERR);
      return;
    }
  }

  if (defined($args{'V'}))
  {
    print 'tfactl version ' . $tfactlglobal_hash{'acver'}. "\n";
    exit 0;
  }

  #default is syspriv
  $tfactlglobal_hash{'contyp'} = 'syspriv';
  if (defined($args{'privilege'}))
  {
    if (($args{'privilege'} =~ /^syspriv$/i) ||
        ($args{'privilege'} =~ /^sysother$/i))
    {
      $tfactlglobal_hash{'contyp'} = $args{'privilege'};
    }
    else
    {
      tfactl_syntax_error('help');
      return;
    }
  }

  if (defined($ARGV[0]))
  {
    $tfactlglobal_hash{'mode'} = 'n';
    if (tfactl_is_cmd($ARGV[0]))
    {
      # nonintsess cmd
      $tfactlglobal_hash{'cmd'} = shift @ARGV;
      return;
    }
    else
    {
      tfactl_show_commands('exit', \*STDERR);
    }
  }
  print "tfactl_parse_tfactl_args \n";

  return;
}

########
# NAME
#   tfactl_module_driver
#
# DESCRIPTION
#   This function calls in each module the respective function that 
#   processes commands responsible by the said module.  All tfactl
#   commands must pass through this function before being processed
#   by the modules.
#
# PARAMETERS
#
# RETURNS
#   Null.
#
########
sub tfactl_module_driver
{
  my ($succ) = 0;
  my ($retval) = 0;
  my ($module);
  my (@eargs);                                   # Array of error arguments. #

  foreach $module (@tfactlglobal_command_callbacks)
  {
    my ($retsucc) = 0;
    # Process command
    # For help commands, $succ = 0
    ($retsucc,$retval) = $module->();

    if ($retsucc)
    {  
      $tfactlglobal_hash{'e'} = $retval;  
      $succ = 0 if ( tfactlshare_getReferenceName($module) =~ /tfactlexttools_process_cmd/ );      
      tfactlshare_trace(3, "tfactl (PID = $$) tfactl_module_driver process command for module " . tfactlshare_getReferenceName($module), 'y', 'n');
      tfactlshare_trace(3, "tfactl (PID = $$) tfactl_module_driver process command retval -> $retval", 'y', 'n');
      # Assert that we find only one occurrence of this command in
      # the modules.
      @eargs = ("tfactl_module_driver_05", $tfactlglobal_hash{'cmd'});
      tfactlshare_assert(($succ == 0), \@eargs);
      $succ = 1;
    }
  }

  # Process help commands
  # $tfactlglobal_hash{'cmd'} = help
  if ($tfactlglobal_hash{'cmd'} eq 'help')
  {
    tfactlshare_trace(3, "tfactl (PID = $$) tfactl_module_driver process help command", 'y', 'n'); 
    # Assert that we find only one occurrence of this command in
    # the modules.
    @eargs = ("tfactl_module_driver_10", $tfactlglobal_hash{'cmd'});
    tfactlshare_assert(($succ == 0), \@eargs);
    tfactl_process_help();
    $succ = 1;
  }
  if ( ! $succ )
  {
    #tfactl_show_commands(undef, \*STDERR);
    print_help("main");
  }

  return;
}

########
# NAME
#   tfactl_validate_command
#
# DESCRIPTION
#   This routine validates the command.
#
# PARAMETERS
#   None.
#
# RETURNS
#   1 Success
#   0 Not success
#
########
sub tfactl_validate_command
{
  my ($succ) = 0;
  my $key;

 foreach $key (keys %tfactlglobal_cmds)
 {
   #print "Key: $key ";
   if ( $key eq $tfactlglobal_hash{'cmd'} ) {
     $succ=1;
     last;
   }
 }

 tfactlshare_trace(3, "tfactl (PID = $$) tfactl_validate_command", 'y', 'n');
 return $succ;

}


########
# NAME
#   tfactl_process_help
#
# DESCRIPTION
#   This top-level routine processes the help command.
#
# PARAMETERS
#   None.
#
# RETURNS
#   Null.
#
########
sub tfactl_process_help 
{
  my (%args);                             # Argument hash used by getopts(). #
  my ($cmd);      # User-specified command-name argument; show help on $cmd. #
  my ($syntax);                                   # Command syntax for $cmd. #
  my ($desc);                                # Command description for $cmd. #
  my ($module);                                  # A module's help function. #
  my ($succ) = 0;                        # 1 if command exists, 0 otherwise. #
  my (@eargs);                                   # Array of error arguments. #
  @tfactlglobal_help_argv = @ARGV;

  # Check if number of non-option parameters are correct.
  #if (@ARGV > 1)
  #{
  #  print "Arguments passed to help @ARGV \n";
  #  tfactl_syntax_error($tfactlglobal_hash{'cmd'});
  #  return;
  #}

  # Argument passed to help (if any, e.g. help command)
  $cmd = shift (@ARGV);

  if (defined ($cmd))
  {
    # Search each module for the command's help message.
    foreach $module (@tfactlglobal_help_callbacks)
    {
      if ($module->($cmd) == 1)
      {
        # Assert that we find only one occurrence of this command in
        # the modules.
        @eargs = ("tfactl_process_help_05", $cmd);
        tfactlshare_assert(($succ == 0), \@eargs);

        # We found the command's help message.
        $succ = 1;
      }
    }
  }

  if (! defined ($cmd))
  {                       # No command name specified, or command not found; #
                          #       show help on tfactl and list all commands. #
    print_help("main");
  }
  elsif ($succ == 0)
  {
    @eargs = $cmd;
    print_help("main");
  }

  tfactlshare_trace(3, "tfactl (PID = $$) tfactl_process_help help command:$cmd", 'y', 'n');
  return;
}

########
# NAME
#   tfactl_show_commands
#
# DESCRIPTION
#   This routine prints a list of all valid internal commands, used
#   as an error message when the user has entered an invalid command name.
#   If $exit is set to 'exit', then also call exit(0).  This option is to 
#   accommodate the non-interactive option, when quitting tfactl is necessary.
#   The caller can specify whether he wants to direct the output to
#   STDOUT or STDERR.
#
# PARAMETERS
#   exit        (IN) - flag: causes tfactlbase_show_commands() to call exit() 
#                      iff value is 'exit'.
#   IO_handle   (IN) - handle where to print output: STDOUT or STDERR.
#
# RETURNS
#   Null.
#
########
sub tfactl_show_commands
{
  my ($exit, $output_handle) = @_;
  my ($tfactl_cmds) = '';
  my ($module);

  # Not affected by connection pooling since this function is called before
  # tfactl determines whether connection pooling can be done or not
  print $output_handle "        commands:\n";
  print $output_handle "        --------\n\n";

  # For each registered module get_tfactl_cmd
  foreach $module (@tfactlglobal_command_list_callbacks)
  {
    my $out = $module->();

    #in case of invisible commands, we get empty string, ignore it.
    if($out ne "")
    {
      $tfactl_cmds .= $out . "\n";
    }
  }

  print $output_handle $tfactl_cmds;
  tfactlshare_trace(3, "tfactl (PID = $$) tfactl_show_commands tfactl_cmds:$tfactl_cmds", 'y', 'n');

  exit 0 if (defined($exit) && ($exit eq 'exit'));

  return;
}

########
# NAME
#   tfactl_is_cmd
#
# DESCRIPTION
#   This routine checks if a user-entered command is one of the known tfactl
#   internal commands.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   1 if $arg is one of the known commands, 0 otherwise.
#
# NOTES
#   This routine calls the callbacks from each module to check if $arg
#   belongs to any of the modules.  It asserts that the command is found
#   in only one module.
########
sub tfactl_is_cmd
{
  my ($command) = shift;
  my ($module);
  my ($succ) = 0;
  my ($count) = 0;
  my (@eargs);

  foreach $module (@tfactlglobal_is_command_callbacks)
  {
    if ($module->($command))
    {
      $succ = 1;
      $count++;
    }
  }

  tfactlshare_trace(3, "tfactl (PID = $$) tfactl_is_cmd count:$count", 'y', 'n');
  # Assert that $count is at most 1 and at least 0.
  @eargs = ("tfactl_is_cmd_05", $tfactlglobal_hash{'cmd'}, $count);
  tfactlshare_assert( (($count == 1) || ($count == 0)), \@eargs);

  return $succ;
}

########
# NAME
#   tfactl_check_global_callbacks
#
# DESCRIPTION
#   This function checks to see if the global callback arrays have been
#   initialized correctly. 
#
# PARAMETERS
#   None
#
# RETURNS
#   Null if the assertion passes; signals exception otherwise.
#
# NOTES
#   This function asserts that all the callback arrays, including
#   tfactl_init_modules, have the same number of elements.
########
sub tfactl_check_global_callbacks
{
  my (@eargs);                             # Error arguments for the assert. #
  my ($temp);

  @eargs = ("tfactl_check_global_callbacks_05",
            scalar(@tfactl_init_modules),
            scalar(@tfactlglobal_command_callbacks),
            scalar(@tfactlglobal_help_callbacks),
            scalar(@tfactlglobal_command_list_callbacks),
            scalar(@tfactlglobal_is_command_callbacks),
            scalar(@tfactlglobal_is_wildcard_callbacks),
            scalar(@tfactlglobal_syntax_error_callbacks),
            scalar(@tfactlglobal_no_instance_callbacks));

  $temp = scalar(@tfactl_init_modules);

  tfactlshare_assert(((scalar(@tfactlglobal_command_callbacks) == $temp) &&
              (scalar(@tfactlglobal_help_callbacks) == $temp) &&
              (scalar(@tfactlglobal_command_list_callbacks) == $temp) &&
              (scalar(@tfactlglobal_is_command_callbacks) == $temp) &&
              (scalar(@tfactlglobal_is_wildcard_callbacks) == $temp) &&
              (scalar(@tfactlglobal_syntax_error_callbacks) == $temp) &&
              (scalar(@tfactlglobal_no_instance_callbacks) == $temp)),
                                  \@eargs);

  tfactlshare_trace(3, "tfactl (PID = $$) tfactl_check_global_callbacks global callback arrays have been initialized correctly", 'y', 'n');
  return;
}

########
# NAME
#   tfactl_syntax_error
#
# DESCRIPTION
#   This function calls into each module to display the correct syntax
#   for a given tfactl command.
#
# PARAMETERS
#   command     (IN) - the user-specified tfactl command
#
# RETURNS
#   Null.
#
# NOTES
#   This routine calls the callbacks from each module to display the 
#   correct syntax for $command.
########
sub tfactl_syntax_error
{
  my ($command) = shift;
  my ($module);
  my ($count) = 0;
  my (@eargs);                                   # Array of error arguments. #

  foreach $module (@tfactlglobal_syntax_error_callbacks)
  {
    if ($module->($command))
    {
      $count++;
    }
  }

  tfactlshare_trace(3, "tfactl (PID = $$) tfactl_syntax_error count:$count", 'y', 'n');
  # Assert that $count is at most 1 and at least 0.
  @eargs = ("tfactl_syntax_error_05", $tfactlglobal_hash{'cmd'}, $count);
  tfactlshare_assert( (($count == 1) || ($count == 0)), \@eargs);

  return;
}

########
# NAME
#   tfactl_check_dup_commands
#
# DESCRIPTION
#   This function cheks if a short command in TFA shell is a duplicate command in tfactl. 
#   ex: host add <hostname>  -> this should add host (pass to tfactl)
#       host <hostname>  -> sets hostname in context
#
# PARAMETERS
#   command     (IN) - the user-specified tfactl command
#
# RETURNS
#   1 -> duplicate command.
#   0 -> otherwise
#
# NOTES
#   This routine calls the callbacks from each module to display the 
#   correct syntax for $command.
########

sub tfactl_check_dup_commands
{
  my @words = @_;
  if ( defined $words[0] && $words[0] eq "host" )
  {
    if ( $words[1] eq "add" || $words[1] eq "remove" || $words[1] =~ /^\-h/ )
    {
      return 1;
    }
  }
  return 0;
}

########
# NAME
#   tfactl_validate_ctx
#
# DESCRIPTION
#   Check that setting is correct and value exists
#
# PARAMETERS
#   command     (IN) - the user-specified tfactl command
#
# RETURNS
#   value
#
# NOTES
########
sub tfactl_validate_ctx
{
  my $key = shift; 
  my @words = @_; 
  if ( $key eq "time" )
  { 
    $tfactlglobal_ctx{"start-time"} = "";
    $tfactlglobal_ctx{"end-time"} = "";
    if ((grep {lc($_) eq "to"} @words) || 
        (grep {lc($_) eq "last"} @words) || 
        (grep {lc($_) eq "past"} @words) ) 
    {
      my ($date_s, $date_e);
      my $to_found = 0;
      my $last_found = 0;
      foreach my $w (@words)
      {
        if ( lc($w) eq "to" )
        {
          $to_found = 1;
        }
         elsif ( lc($w) eq "past" || lc($w) eq "last" )
        {
          $last_found = 1;
        }
         else
        {
          $date_s .= " $w" if ( $to_found == 0 );
          $date_e .= " $w" if ( $to_found == 1 );
        }
      }
      if ( $last_found == 1 )
      {
        $date_s .= " ago";
        $date_e = "now";
      }
      $tfactlglobal_ctx{"start-time"} = tfactl_get_date($date_s);
      $tfactlglobal_ctx{"end-time"} = tfactl_get_date($date_e);
      if ( $tfactlglobal_ctx{"start-time"} && $tfactlglobal_ctx{"end-time"} )
      {
        return $tfactlglobal_ctx{"start-time"} . " to " . $tfactlglobal_ctx{"end-time"};
      }
       else
      {
        return "";
      }
    }
     else
    {  
      return tfactl_get_date(join(" ", @words) );
    }
  }
   elsif ( $key eq "host" )
  {
    my @hosts;
    my $localnode;
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

    my $hostlist = "";
    my @ihosts = split(/,/, $words[0]);
    foreach my $host (@ihosts )
    {
      if ( ! grep { lc($_) eq lc($host) } @hosts ) 
      {
        print "Error: Failed to find host $host\n";
      }
       else
      {
        $hostlist .= ",$host";
      }
    }
    $hostlist =~ s/^,//;
    return $hostlist;
  }
   elsif ( $key eq "db" )
  {
    my @db = split(/,/, $words[0]);
    my $dblist = "";
    foreach my $db (@db)
    {
      $db = uc($db);
      my $pfile = catfile($tfa_home, "internal","dbparams", "$db.param.out");
      if ( -f $pfile )
      {
        $dblist .= ",$db";
      }
       else
      {
        my $retcode;
        my %rethash = ();
        my $dbname;
        ($retcode, %rethash) = dbutil_setOraEnv($tfa_home,$db,undef,FALSE);
        if ( $retcode == 1 ) {
          print "Error: Failed to find database $db\n";
        }
         else
        {
          $db = $rethash{"TFA_DB_NAME"}; 
          $dblist .= ",$db";
        } # end if $retcode == 1
      } # end if -f $pfile
    }
    $dblist =~ s/^,//;
    return $dblist;
  }
   elsif ( $key eq "inst" )
  {
    my @inst = split(/,/, $words[0]);
    $tfactlglobal_ctx{"host"} = "";
    $tfactlglobal_ctx{"db"} = "";

    my $path = catfile ($tfa_home,"internal","dbparams","*.param.out");
    foreach my $inst (@inst)
    {
      my @out=();
      if ( ! $IS_WINDOWS ){
        @out = `grep -i '\.$inst\.' $tfa_home/internal/dbparams/*.param.out 2>/dev/null |head -1`;
      } else {
        @out = `findstr /I "\.$inst\." "$path" > head && set /p line=<head && del head && echo %line%`;
      }
      chomp(@out);
      $out[0] =~ s/\.[^.]*$//; #dbparam.db.node1
      $out[0] =~ s/.*://i; #dbparam.db.node1
      if ( $out[0] =~ /(.*)\.(.*)\.(.*)/ )
      {
        $tfactlglobal_ctx{"host"} .= ",$1";
        $tfactlglobal_ctx{"db"} .= ",$2";
      }
       else
      {
        print "Error: Failed to find instance $inst\n";
      }
    }
    $tfactlglobal_ctx{"host"} =~ s/^,//;
    $tfactlglobal_ctx{"db"} =~ s/^,//;
    if ( $tfactlglobal_ctx{"host"} )
    {
      return $words[0];
    }
     else
    {
      return;
    }
  }
   else
  {
    return $words[0];
  }
}

sub tfactl_get_date
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

##############################################################################
0;
