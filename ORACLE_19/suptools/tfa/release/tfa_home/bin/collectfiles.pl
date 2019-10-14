# 
# $Header: tfa/src/v2/tfa_home/bin/collectfiles.pl /main/85 2018/05/28 15:06:27 bburton Exp $
#
# collectfiles.pl
# 
# Copyright (c) 2013, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      collectfiles.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    05/14/18 - Move reports to awr_reports.
#    bburton     05/08/18 - Collect DB feature usage
#    bburton     04/10/18 - set umask 0077 to ensure minimum required privs
#    recornej    03/23/18 - Rename ora600600 zip file
#    cnagur      02/14/18 - TFA Non-Root Daemon Support
#    manuegar    01/18/18 - XbranchMerge manuegar_bug-27344815 from
#                           st_tfa_12.2.1.3.1
#    recornej    01/04/18 - Add input dependency for scripts
#    recornej    12/05/17 - Allow dbperf reports without baseline
#    bburton     11/01/17 - Allow larger timeout for tfactl dbperf
#    recornej    10/26/17 - Removing changes related to ASM srdc
#    bburton     10/18/17 - Add cloud metadata collection
#    bburton     10/05/17 - Only run OS script for OS
#    recornej    10/03/17 - Fixing replace script error.
#    recornej    09/25/17 - Fix dbutil_setOraEnv parameter needed to set ENV
#                           variables.
#    manuegar    08/28/17 - manuegar_pmap_disc.
#    recornej    08/24/17 - Bug 26260146 - TFA SRDC DBPERF NOT COLLECTING AWRS
#    bburton     08/16/17 - Fix issue with call to runtimedcommand in dbcsmon
#                           call
#    manuegar    08/16/17 - Bug 26638658 - LNX64-12.2-TFA:TFA-00404 XML FILE IS
#                           NOT WELL FORMED WHEN RUNNING -SRDC DBPERF.
#    manuegar    08/03/17 - manuegar_srdc_xmlparser.
#    recornej    07/28/17 - Bug 26541341 - LNX64- TFA SRDC DBPERF OPTIONS -LAST
#                           AND -SINCE NO WORKING
#    recornej    06/29/17 - BUG 25985797 - SRDC AUTOMATION: ENHANCE DBPERF SRDC
#                           TO INCLUDE OTHER COLLECTIONS
#    recornej    07/13/17 - Adding issuenow changes to run awr.
#    bburton     07/11/17 - support setenvs on Windows
#    manuegar    07/06/17 - Bug 25536278 - LNX64-121-CMT: NEED AN ALL-IN-ONE
#                           SCRIPT TO COLLECT ODA AND ODALITE LOGS FOR SR.
#    bburton     06/12/17 - Deal with multiple version for the same script
#    bburton     06/12/17 - Issue with platform check and allux
#    gadiga      06/05/17 - fix dbcscollect
#    llakkana    05/31/17 - XbranchMerge gadiga_dbcsmonitor from main
#    manuegar    05/26/17 - manuegar_srdcwin11.
#    bburton     05/26/17 - Make sure correct slashes for tfahome on win
#    bburton     05/18/17 - Need to check iscloud early
#    bburton     05/08/17 - bug 26024875 - SUmmary requires argument changes
#    manuegar    05/05/17 - manuegar_srdcwin04.
#    bburton     05/05/17 - Do not rename IPSPACK
#    bburton     05/03/17 - No needs to mess with temp repo dir permissions now
#                           Java has set them correctly.
#    manuegar    05/02/17 - manuegar_srdcwin01.
#    bburton     04/26/17 - Bug 25213466
#    manuegar    04/19/17 - manuegar_srdcwin_shared.
#    gadiga      04/18/17 - DBCS collection
#    cnagur      04/18/17 - Fix for Bug 25817520
#    bibsahoo    04/14/17 - FIX BUG 25784418 - <NODE>_CHMOSTAB AND <NODE>_CHMOS
#                           ARE THE SAME IN TFA COLLECTION
#    manuegar    04/06/17 - manuegar_windows_srdc01.
#    bburton     02/13/17 - get local run script output
#    bburton     02/08/17 - remove use or reference to use of tmp dir
#    bburton     01/17/17 - fix SRDC merge
#    bibsahoo    12/15/16 - FIX BUG 25264070 - WS2012_122_TFA: CHM DATA WAS NOT
#                           COLLECTED BY TFACTL DIAGCOLLECT
#    bburton     11/02/16 - pick up allsnaps
#    bburton     10/03/16 - use original xml for scripts and run from file
#    bburton     09/29/16 - run dbperf using tfactl dbperf
#    bburton     09/22/16 - changes for odalite
#    manuegar    09/03/16 - Support the -extractto switch in the TFA installer.
#    manuegar    08/12/16 - srdc_11 enhancements.
#    bburton     08/05/16 - Add more to summary
#    manuegar    06/24/16 - Bug 23517627 - SOLSP64-12.2-CRS:MANY OPATCH
#                           COREDUMP FILES GENERATED.
#    bburton     06/22/16 - fix issue with appending args
#    arupadhy    06/13/16 - Added windows support for collectfiles
#    manuegar    06/07/16 - XbranchMerge manuegar_srdc_ora600_07_12.1.2.8.0
#                           from st_tfa_12.1.2.8
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    manuegar    06/06/16 - Fixed issue in "db down" scenario.
#    bburton     06/01/16 - Deal with MTS issues
#    manuegar    05/27/16 - Discover down databases when running srdc.
#    bburton     05/25/16 - remove the rename of ips pack file for automation
#    bburton     05/25/16 - Include some fixes from 12.1.2.8.0 testing
#    bburton     05/18/16 - support call of old srdc tool
#    manuegar    05/16/16 - Disable the RDA callout for ips pack.
#    bburton     05/12/16 - fix issue we are passing SID to check osdba instead of Home
#    bburton     05/11/16 - add request user as parameter
#    manuegar    05/11/16 - Support ips pack for SRDC
#    bburton     05/09/16 - move some code to oscollect.pl
#    bburton     05/05/16 - Fix AWR collection for MGMTDB
#    llakkana    04/12/16 - Platform specific collection
#    bburton     02/18/16 - add xmlfilters driver
#    bburton     02/16/16 - accept list of nodes to collect chm for
#    bburton     02/11/16 - bug 19480620 - no need to write active vers twice
#    cnagur      01/21/16 - Changes for JCS Dumps
#    bburton     10/13/15 - Bug 21129001 - Call oclumon with tabular format
#                           where available as well as legacy
#    bburton     07/22/15 - fix bug 21455073
#    cnagur      06/18/15 - Added sticky bit to repository
#    bburton     05/15/15 - run fmwsaascollect.pl for FMW Cloud
#    bburton     12/17/14 - Code needs to handle when DBName is not part of SID
#    gadiga      12/15/14 - add suptools collection
#    bburton     12/10/14 - Fix env setup in SIHA where srvctl status shows
#                           Database is running
#    bburton     12/02/14 - Fix bug 20012990 - Ensure /proc files exist before
#                           trying to read them.
#    bburton     11/20/14 - Generic Changes to support AWR script running
#    bburton     09/24/14 - change to support calling scripts for components
#    bburton     09/08/14 - bug 19529537 incorrect name for lsscsi outout means
#                           previosu command output is lost. 
#    manuegar    08/11/14 - Relocate tfactl_lib
#    bburton     06/19/14 - extend timeout for opatch commands
#    bburton     06/12/14 - bug 18937826 - bad redirection for ipmi commands
#    bburton     05/28/14 - Changes for ODA Storage - 18727371
#    gadiga      05/26/14 - collect oratop & orachk
#    gadiga      05/22/14 - disable killtree
#    gadiga      05/21/14 - killtree
#    bburton     04/23/14 - fix bug 18643608 olsnodes invalid option
#    bburton     03/05/14 - run opatch commands from runtimecommands to avoid
#                           hang
#    bburton     02/26/14 - bug 18261118 - needs LIBPATH set
#    bburton     02/18/14 - add start and end timestamp
#    bburton     02/12/14 - add multiple new commands
#    amchaura    02/11/14 - Collect sundiag logs
#    amchaura    01/30/14 - Pass timezone flag if perl env TZ not set
#    bburton     01/27/14 - add errpt -a for AIX collections
#    bburton     09/12/13 - add -retry 0 for opatch lsinventory lock issue bug
#                           17447553
#    bburton     06/13/13 - Collect opatch lsinventory
#    bburton     06/12/13 - collect the chmos data if the flag is supplied
#    bburton     06/04/13 - Code to collect various CRS and O/S information for
#                           TFA diagcollection
#    bburton     06/04/13 - Creation
# 
###################################################################
#

use strict;
use English;
use File::Basename;
use File::Spec::Functions;
use File::Copy;
use Time::Local;
use Term::ANSIColor;
use Cwd;
use Cwd qw(abs_path);
use POSIX;

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME);
  push @INC, dirname($PROGRAM_NAME).'/common';
  push @INC, dirname($PROGRAM_NAME).'/modules';
  push @INC, dirname($PROGRAM_NAME).'/common/exceptions';
}

use Getopt::Long qw(:config no_auto_abbrev);
use tfactlglobal;
use tfactlshare;
use cmdlocation;
use osutils;
use dbutil;

my $cmdargs = join(' ', @ARGV);

# Set up local variables
my $timeduration="04:00:00";
my $starttime="";
my $endtime="";
my $chmos="";
my $repository;
my $overriderepo;
my $copydir = catdir($repository,"copydir");
my $hostname=tolower_host();
my $crshome="";
my $tfahome="";
my $basedir="";
my $command;
my $setupfile;
my $result=0;
my $timezone=""; 
my $sundiag="";
my $odastorage="";
my $actions="";
my $database = "";
my $xml_filter_file = "";
my $requser = "";
my $chmnodelist;
my $starttimeforcellmetrics;
my $endtimeforcellmetrics;
my %patrep;
my %wipepat;
# Parse command line args

# Set up full command paths

GetOptions('crshome=s'    => \$crshome,
           'hostname=s'    => \$hostname,
           'tfahome=s'    => \$tfahome,
           'repository=s'      => \$repository,
           'database=s'      => \$database,
           'chmos' => \$chmos,
           'overriderepo' => \$overriderepo,
           'chmNodelist=s' => \$chmnodelist,
	   'starttimeforcellmetrics=s' => \$starttimeforcellmetrics,
	   'endtimeforcellmetrics=s' => \$endtimeforcellmetrics,
           'starttime=s'    => \$starttime,
           'endtime=s'    => \$endtime,
	   'sundiag' => \$sundiag,
	   'odastorage' => \$odastorage,
	   'actions=s' => \$actions,
           'xmlfilters=s' => \$xml_filter_file,
           'requser=s' => \$requser,
	   'TZ=s'	=> \$timezone);
#  print "##### crshome: $crshome\n";
#  print "##### hostname: $hostname\n";
#  print "##### repository: $repository\n";
#  print "##### chmos: $chmos\n";
#  print "##### starttime: $starttime\n";
#  print "##### endtime: $endtime \n";
#  print "##### timezone: $timezone \n";
#  print "##### database: $database \n";
#  print "##### actions: $actions \n";
#  print "##### requser: $requser \n";
#  print "##### xmlfilters: $xml_filter_file \n";
#

#  set umask to 0077 to ensure we do not create files with too open permissions
umask(0077);

if ($starttime =~ /\s/ && $starttime !~ /"/) {
  $starttime = "\"" . $starttime . "\"";
}

if ($endtime =~ /\s/ && $endtime !~ /"/) {
  $endtime = "\"" . $endtime . "\"";
}

# Set for MTS connection to Database 
$ENV{ORA_SERVER_THREAD_ENABLED}="FALSE";

my $tz = $ENV{TZ};
if ( $tz eq "" ) {
   $ENV{'TZ'} = $timezone;
   tzset();
}

if(@ARGV) {
   print "\nInvalid Options specified: @ARGV\n";
   #print_help("diagcollect", "");
   exit(1);
}

# Determine the tfa_home directory if it was not supplied
# The java always calls the code with the full path.
# But we need to just be sure

if ( ! $tfahome )
{  
  if ( $0 =~ /^\// ) # It's the full path
  {
    $basedir = dirname ($0);
  }
  {
    $basedir = dirname ($0);
  
    if ($basedir =~ /^\./) {
      my $p = getcwd();
      $basedir =~ s/\./$p/;
    }
    if ($basedir =~ /\/bin/) {
      $basedir =~ s/\/bin//;
    }
    elsif ($basedir eq "bin") {
      $basedir = getcwd();
    }
  }
  $tfahome = $basedir;
}

$DAEMON_OWNER = tfactlshare_getTFADaemonOwner($tfahome);
my $iscloud = isTFAOnCloud($tfahome);
my $PERL = tfactlshare_getPerl($tfahome);

# All files from this and forked processes will write directly to this dir and TFA will pick it up.
if ($repository) { # repository was supplied - normal in a Java Call
   if ($overriderepo) { # we need this flag if not using a standard tfarepository
       print localtime(time) . ": Overriding Repo check for $repository \n";
   } else {
       my $repodir = tfactlshare_get_repository_location($tfahome);
       $repodir =~ s/\\/\\\\/g;
       if ( not $repository =~ /$repodir/ ) {
          print localtime(time) . ": Invalid repository Directory passed: $repository\n";
          print localtime(time) . ": Repository Directory should be under : $repodir\n";
          exit(1);
       }
   }
} else {
   $repository=getcwd();
}

if ( -e $repository ) {
   chdir($repository);
} else { 
   print localtime(time) . ": Invalid repository Directory $repository\n";
   exit(1);
}

# manuegar_srdcwin_shared
if ( not length $current_user ) {
  if ( ! $IS_WINDOWS ) {
    $current_user = getpwuid($<);
  } else {
    $current_user = getlogin();
  }
}

#Open a log file for this collection script to write to
open (LOG, '>', $hostname . "_collection.log"); 
open (*STDERR, '>', $hostname . "_collection.err");

print LOG localtime(time) . ": Running collection of Extra files for TFA \n";
print LOG "Command Line Arguments : $cmdargs\n";
print LOG "crshome: $crshome\n";
print LOG "tfahome: $tfahome\n";
print LOG "repository: $repository\n";
print LOG "hostname: $hostname\n";
print LOG "timezone: $timezone\n";
print LOG "actions: $actions\n";
print LOG "Request User: $requser\n";
print LOG "current_user: $current_user\n";
print LOG "XML Filter File: $xml_filter_file\n";
print LOG "chmNodelist: $chmnodelist\n";
print LOG "ENV TZ: $ENV{TZ}\n";
print LOG "database: $database \n";

#Uppercase databases like +asm
$database = uc($database) if ( $database =~ /\+\w+/ );

# run the TFA summary command
my $tfactl = catfile ($tfahome,"bin","tfactl");
my $summaryfile = "$hostname" . "_summary";
#$command = "$tfactl summary -silent -html -node local > $hostname" . "_summary 2>&1";
#my $sumout = osutils_runtimedcommand($command,1200,TRUE,\*LOG);
#my $repofile;
#my $sumfile;
# move Output file to $repository
# ----------------------------
#foreach my $line (split /\n/ , $sumout) {
#    # $lines .= "line << $line >>\n";
#    if ( $line =~ /.*REPOSITORY\s+\:(.*)/ ) {
#      $repofile = trim($1);
#      print LOG localtime(time) . " : extracted Summary repository $repofile\n";
#    }
#    if ( $line =~ /.*<REPOSITORY>(.*)/ && length $repofile) {
#      $sumfile = trim($1);
#      print LOG localtime(time) . " : extracted Summary file $sumfile\n";
#      $sumfile = $repofile . $sumfile;
#      print LOG localtime(time) . " : Final Summary file $sumfile\n";
#    }
#} # end foreach split /\n/ , $sumout
#print LOG localtime(time) . " : Moving $sumfile to $repository\n\n";
#move($sumfile,catfile($repository,"",".")) if ( -f $sumfile ) ;

# Collect DBCS diagnostics
if ( -f catfile ("", "var", "opt", "oracle", "misc", "dbcscollect.pl" ) )
{
  my $dbcs_collection = "$hostname" . "_dbcs_diag";
  $command = "$tfactl dbcsmon $repository > $dbcs_collection 2>&1";
  print LOG localtime(time) . ": Running $command\n";
  osutils_runtimedcommand($command,120,FALSE,\*LOG);
}

## Test to run just in component..
# run the O/S collection .
#$command = catfile($tfahome,"bin","scripts","oscollect.pl");
#$command = "$PERL $command -hostname $hostname";
#print LOG localtime(time) . ": Running $command\n";
#osutils_runtimedcommand($command,120,FALSE,\*LOG);

# run sundiag if requested
if ($sundiag && !$IS_WINDOWS) {
 print LOG localtime(time) . ": Collecting sundiag logs\n";
 if ( -e "/opt/oracle.SupportTools/sundiag.sh" ) {
    my $sundiagcommand = "/opt/oracle.SupportTools/sundiag.sh > $hostname\_sundiag_output";
    print LOG localtime(time) . ": Executing $sundiagcommand\n";
    osutils_runtimedcommand($sundiagcommand,300,FALSE,\*LOG);
    open (OUTPUT, "$hostname\_sundiag_output") || die "ERROR Unable to open file: $!\n";
    #Get sundiag zip location
    my $zipLocationLine = `grep tar.bz2 $hostname\_sundiag_output`;
    print LOG localtime(time) . ": zipLocationLine: $zipLocationLine\n";
    my $sundiagZip = (split(' ', $zipLocationLine))[-1];
    print LOG localtime(time) . ": sundiag zip: $sundiagZip\n";
    #copy to repository
    if ( -e $sundiagZip ) {
       `cp -r $sundiagZip .`;
       #Delete from original location after copying to repository;
       `rm -f $sundiagZip`;
    }
 }
 else {
    print LOG localtime(time) . ": Could not find sundiag.sh\n";
  }
}

# Gather cell storage metrics if requested
if ((defined $starttimeforcellmetrics) && (defined $endtimeforcellmetrics)) {
  print LOG localtime(time) . ": Start time for cell metrics : $starttimeforcellmetrics\n";
  print LOG localtime(time) . ": End time for cell metrics : $endtimeforcellmetrics\n";
  if ( -e "$tfahome/bin/metric_iorm.pl" ) {
    my $cellmetricscommand = "$PERL $tfahome/bin/metric_iorm.pl \"where collectionTime > '$starttimeforcellmetrics' and collectionTime < '$endtimeforcellmetrics'\" > $hostname\_metric_output";
    print LOG localtime(time) . ": Executing $cellmetricscommand\n";
    system($cellmetricscommand);
  }
  else {
    print LOG localtime(time) . ": Could not find metric_iorm.pl\n";
  }
}

# Run the script to Gather OPC/BMC Metadata info
my $command = catfile($tfahome, "bin", "scripts", "cloudmetadatacollect.pl");
$command = "$PERL $command -hostname $hostname";
print LOG localtime(time) . ": Running cloudmetadatacollect.pl\n"; 
print LOG localtime(time) . ": Full Command is: $command\n";
osutils_runtimedcommand($command,30,FALSE,\*LOG);
print LOG localtime(time) . ": Finished Running cloudmetadatacollect.pl\n"; 

# Run the next section if on Cloud.
# TODO Make sure this is only for fmwsaas and not any non daemon mode.
if ( isTFAOnCloud($tfahome) ) {
    print LOG localtime(time) . ": Running fmwsaascollect.pl for FMW/SaaS OS data\n";
    my $command = catfile($tfahome, "bin", "scripts", "fmwsaascollect.pl");
    $command = "$PERL $command -hostname $hostname";
    print LOG localtime(time) . ": Full Command is: $command\n";
    osutils_runtimedcommand($command,300,FALSE,\*LOG);
    print LOG localtime(time) . ": Finished Running fmwsaascollect.pl\n";

    if ( tfactlshare_isTFAOnJCS() ) {
    	print LOG localtime(time) . ": Collecting Heap Dumps on JCS\n";
	tfactlshare_runHeapDumpsOnJCS();

	# Collect IP Local Port Range
	$command = catfile("", "sbin", "sysctl");
	if ( -e $command ) {
		$command = $command . " net.ipv4.ip_local_port_range > $hostname" . "_IP_LOCAL_PORT_RANGE 2>&1";
		system($command);
	} else {
		my $filename = catfile("", "proc", "sys", "net", "ipv4", "ip_local_port_range");
		my $fileout = "$hostname" . "_IP_LOCAL_PORT_RANGE";
		if ( -e $filename ) {
			copy ($filename, $fileout);
		}
	}

	# Collect rpcinfo
	$command = catfile("", "usr", "sbin", "rpcinfo");
	if ( -e $command ) {
		$command = $command . " -p > $hostname" . "_JCS_RPCINFO 2>&1";
		system($command);
	}
    	print LOG localtime(time) . ": Finished collecting Heap Dumps\n";
    }
}

if ($chmos) {
  print LOG ": Collecting chmos data for :-\n";
  if ($starttime) {
      print LOG "starttime: $starttime\n";
      print LOG "endtime: $endtime\n";
  }
  else
  {
      print LOG "the last $timeduration hours\n";
  }
  if ($chmnodelist) {
     $chmnodelist =~ s/,/ /g;
     $chmnodelist = $chmnodelist . " " . $hostname;
     print LOG "Nodes : $chmnodelist\n";     
  }
}
else
{
  print LOG "Not collecting chmos data :-\n";
}

# Now determine all database homes to collect.
# read the tfa_setup file to get all homes

$setupfile = catfile ($tfahome, "tfa_setup.txt");

if ( -e $setupfile ) 
{
  print LOG localtime(time) . ": Reading RDBMS HOMES from $setupfile\n";
  open (RF,$setupfile) ;
  my %homes;
  my $home;
  while (<RF>) {
    if (/(RDBMS_ORACLE_HOME=)(.*?)(\|.*)/) {
      $homes{$2} = 1 if (not exists $homes{$2});
    }
  }
  close(RF);
  foreach (keys %homes){
      print LOG localtime(time) . ": Found RDBMS HOME : $_\n";
      $command = catfile ($_,"OPatch","opatch");
      if ( -e $command ) { 
        if($IS_WINDOWS){
          $command = "$command lsinventory -detail -retry 0 -oh $_ >> $hostname"."_OPATCH_DBHOMES 2>&1";
        }else{
          my $uid = (stat $command)[4];
          my $user = getpwuid($uid);
          chomp($user);
          $command = tfactlshare_checksu($user,"$command lsinventory -detail -retry 0 -oh $_") . " >> $hostname"."_OPATCH_DBHOMES 2>&1";
        }
        osutils_runtimedcommand($command,30,FALSE,\*LOG);
      }
      else 
      {
        print LOG localtime(time) . ": opatch file $command does not exist\n";
      }

      if($IS_WINDOWS){
        $command = catfile($_,"bin","orahomeuserctl.bat");
        if ( -e $command ) { 
          $command = "$command list >> $hostname"."_RDBMSUSERINFO 2>&1";
          system($command);
        }
        else 
        {
          print LOG localtime(time) . ": orahomeuserctl.bat file $command does not exist\n";
        }
      }
    }
}
else 
{
  print LOG localtime(time) . ": Unable to find tfa_setup file $setupfile\n";
}

# Copy oratop and orachk files
my $t1 = "";
my $t2 = "";
my $tfa_repository = tfactlshare_get_repository_location($tfahome);
print LOG localtime(time) . " : Collecting tool output from $starttime to $endtime\n";
if ( $starttime &&  $endtime )
{ 
  if ( $starttime =~ /(\d+)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)/ )
  {
    $t1 = timelocal($6, $5, $4, $3, $2-1, $1);
  }
  if ( $endtime =~ /(\d+)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)/ )
  {
    $t2 = timelocal($6, $5, $4, $3, $2-1, $1);
  }
}
 else
{ # Last4 hours
  $t1 = time;
  $t2 = $t1 - (4*60*60);
}

if ( $xml_filter_file && -r $xml_filter_file ) {
   print LOG localtime(time) . " : Skipping Old ORA/EXAchk file collection for SRDC driven collection\n";
} else {
   print LOG localtime(time) . " : Checking orachk and oratop files from $t1 to $t2\n";
   get_orachk_files("orachk", $t1, $t2);
   get_orachk_files("exachk", $t1, $t2);
}

my @dbs = split(/,/, $database);
foreach my $dbname (@dbs)
{
  get_oratop_files($dbname, $t1, $t2);
}

get_oswbba_files($t1, $t2);

# Collect suptools

collect_for_a_tool($tfa_repository, "sqlt", "sqlt", $t1, $t2);

my @db_scripts;
my @dbusers;
my @sql_scripts;
my @ipspack_scripts;
my @srdctool_scripts;
my @tfadbperf_scripts;
my %orachk_scripts;
my %tfactl_scripts;
my $event_time;
my $event_start_time;
my $event_end_time;
my $baselinefrom;
my $baselineto;
my $issuenow_flag;
my $license_flag;
my $slow_sqlID;
my $srdccode;
my $tfahome_srdc_dir = catdir($tfahome,"resources");
my $tfahome_srdc_file;
my $inputorahome_dbv;
# Filter processing
if ( $xml_filter_file && -r $xml_filter_file )
{

  # get srdc value from filename
  if ( $xml_filter_file =~ /.*_srdc_(.*)\.xml/ ) 
  {
     $srdccode = $1;
  }
  print LOG localtime(time) . " : SRDC Drive for $srdccode\n";

  $tfahome_srdc_file = catfile($tfahome_srdc_dir,"srdc_$srdccode.xml");
  if ( ! -r $tfahome_srdc_file ) {
     print LOG localtime(time) . " : Original SRDC file $tfahome_srdc_file not available - exitting\n";
     return 0;
  }
  
  $ENV{"TOOL_HOME"} = catfile($tfahome,"ext"); 
  $ENV{"TFACTL"}    = catfile($tfahome,"bin","tfactl");
  my $invloc = "";

  # Determine Oracle Inventory Location $invloc
  # -------------------------------------------
  if ( $IS_WINDOWS ) {
    my @invloc = `reg query HKEY_LOCAL_MACHINE\\Software\\Oracle /v "inst_loc" /s 2>&1`;
    foreach my $line (@invloc) {
       if ( $line =~ /.*inst_loc.*REG_SZ\s+(.*)/ ) {
         $invloc = $1;
         last;
       }    
    }    
    $ENV{"INV_LOC"} = $invloc;
  } else {
    if ( -e "/etc/oraInst.loc" )
    {    
      $invloc = `grep inventory_loc /etc/oraInst.loc |cut -d= -f2`;
      chomp($invloc);
      $ENV{"INV_LOC"} = $invloc;
    }    
  } # end if $IS_WINDOWS
  print LOG localtime(time) . " Oracle Inventory Location $invloc\n";

  my @scr = ();
  my $scrname = "";
  my $scrtype = "";
  my $scrtimeout = 120;
  my $script_platform;
  my $validfor = "";
  my $inpvalidfor = "";
  my $script_version;
  my $defaultval;
  my $showprompt;
  my $setenv;
  my $depinput;
  my $deppattern;
  my %scriptenvs;
  my %scriptreplace;
  my %savedinputs;

  my $runuser = "";

  # parse srdcfile
  # --------------
  my $collection_id_fp;
  my %srdc_fp = ();
  my @userinputsarray_fp;
  my $user_inputs_content;
  ($collection_id_fp,%srdc_fp) = tfactlshare_parse_srdcfile($xml_filter_file);
  @userinputsarray_fp = @{$srdc_fp{$collection_id_fp}->{user_inputs_array}};

  foreach my $keyinput ( @userinputsarray_fp ) {
    ###print "key % srdc_fp $keyinput\n";

    # my %hashattribs = %{%{$srdc_fp{$collection_id_fp}->{user_inputs}}{$keyinput}};

    my $inputhashref = $srdc_fp{$collection_id_fp}->{user_inputs};
    my %inputhash = %$inputhashref;
    my $hashattribsref = $inputhash{$keyinput};
    my %hashattribs = %$hashattribsref;

    $defaultval = $hashattribs{"default"};    # $2;
    $showprompt = $hashattribs{"showprompt"}; # $3;
    $setenv     = $hashattribs{"setenv"};     # $4;
    $user_inputs_content = $hashattribs{"content"};
    $user_inputs_content =~ s/USERINPUT\-//g;
    ###print LOG localtime(time) . " : Reading user inputs default:$defaultval showprompt:$showprompt " .
    ###      "setenv:$setenv user_inputs_content:$user_inputs_content\n";
    ###print " : Reading user inputs default:$defaultval showprompt:$showprompt " .
    ###      "setenv:$setenv user_inputs_content:$user_inputs_content\n";

    # ------------- $user_inputs_content ---------------  >>>>>>>>>>>>>
    if ( $user_inputs_content =~ /(.*)=(.*)/ ) {
       my $evar = $1;
       chomp($evar);
       my $evarval = $2;
       chomp($evarval);
       ###print LOG localtime(time) . " : Read Line : Key/Var $evar : Value $evarval\n" if (! $evar =~ /_PWD/);
       if ( $evar =~ /[\$\;\&\`\(\)]/ || $evar =~ /[\$\;\&\`\(\)]/ ) {
          print LOG localtime(time) . " Invalid characters in XML file \n";
          return(1);
       }
       $savedinputs{$evar} = $evarval;
       if ( $setenv eq "YES" ) {
          print LOG localtime(time) . "Added $evar with value $evarval to scriptenvs\n";
          $scriptenvs{$evar} = $evarval; 
       }        
       if ( $setenv eq "REPLACE" ) {
          print LOG localtime(time) . "Added $evar with value $evarval to scriptreplace\n";
          $scriptreplace{$evar} = $evarval; 
       }
       if ( $evar =~ /ORACLE_HOME/ ) {
          print LOG localtime(time) . "check dir : $evarval\n";
          if ( ! -d $evarval ) {
             print LOG localtime(time) . " Invalid ORACLE_HOME :$evarval: passed - Exitting\n";
             return(1);
          }
          $ENV{"ORACLE_HOME"} = $evarval;
          my $filename = catfile($evarval,"bin","oracle");
          # manuegar_srdcwin_shared
          if ( ! $IS_WINDOWS ) {
             my $uid = (stat $filename)[4];
             $runuser = (getpwuid $uid)[0];
          } else {
            $runuser = $current_user;
          }
          print LOG "Run User: $runuser\n";
          my $sqlplus = catfile($ENV{"ORACLE_HOME"}, "bin", "sqlplus");
          my $cmd = "$sqlplus -v";
          my @out = osutils_runtimedcommand(tfactlshare_checksu($requser,$cmd),10,TRUE,\*LOG);
          foreach my $line(@out) {
            print LOG localtime(time) . "from out array : $line\n";
            if ( $line =~ /Release ([\d\.]+) / ) {
               $inputorahome_dbv = $1;
            }
          }
       } # end if $evar =~ /ORACLE_HOME/

       if ( $evar =~ /DB_VERSION/ ) {
          $inputorahome_dbv = $evarval;
          chomp($inputorahome_dbv);
          print LOG localtime(time) . " Extracted event time $event_time from xml\n";
       }
       if ( $evar =~ /EVENT_TIME/ ) {
          $event_time = $evarval;
          chomp($event_time);
          print LOG localtime(time) . " Extracted event time $event_time from xml\n";
       }
       if ( $evar =~ /EVENT_START_TIME/ ) {
          $event_start_time = $evarval;
          chomp($event_start_time);
          print LOG localtime(time) . " Extracted event start time $event_start_time from xml\n";
       }
       if ( $evar =~ /EVENT_END_TIME/ ) {
          $event_end_time = $evarval;
          chomp($event_end_time);
          print LOG localtime(time) . " Extracted event start time $event_end_time from xml\n";
       }
       if ( $evar =~ /EVENT_BASELINE_START_TIME/ ) {
          $baselinefrom = $evarval;
          chomp($baselinefrom);
          print LOG localtime(time) . " Extracted baseline start time $baselinefrom from xml\n";
       }
       if ( $evar =~ /EVENT_BASELINE_END_TIME/ ) {
          $baselineto = $evarval;
          chomp($baselineto);
          print LOG localtime(time) . " Extracted baseline start time $baselineto from xml\n";
       }
      if ( $evar =~ /ISSUE_NOW/ ){
        $issuenow_flag = $evarval;
        chomp($issuenow_flag);
        print LOG localtime(time) . " Extracted issue now flag $issuenow_flag  from xml\n";
      }
      if ( $evar =~ /LICENSE/ ){
        $license_flag = $evarval;
        chomp($license_flag);
        print LOG localtime(time) . " Extracted license flag $license_flag from xml\n";
      }
      if( $evar =~ /SQL_SLOW/ ){
        $slow_sqlID = $evarval;
        chomp($slow_sqlID);
        print LOG localtime(time) . " Extracted sqlslow  $slow_sqlID from xml\n";
      } 
    } # end if $user_inputs_content =~ /(.*)=(.*)/ )
    # ------------- $user_inputs_content ---------------  <<<<<<<<<<<<
  } # end foreach $keyinput



  # parse srdcfile (original)
  # --------------------------
  my $collection_id;
  my %srdc_orig= ();
  my @scriptsarray;
  ($collection_id,%srdc_orig) = tfactlshare_parse_srdcfile($tfahome_srdc_file);
  @scriptsarray = @{$srdc_orig{$collection_id}->{scripts_array}};

  print LOG localtime(time) . " : Reading Scripts to run from  $tfahome_srdc_file\n";
  # ------------------- foreach my $keyinput --------------- <<<<<<<<<<<<<<<<<<<
  foreach my $keyinput ( @scriptsarray ) {
    ###print "--- key $keyinput\n";

    # my %hashattribs = %{%{$srdc_orig{$collection_id}->{scripts}}{$keyinput}};

    my $scriptshashref = $srdc_orig{$collection_id}->{scripts};
    my %scriptshash = %$scriptshashref;
    my $hashattribsref = $scriptshash{$keyinput};
    my %hashattribs = %$hashattribsref;

    # my %contenthash = %{$srdc_orig{$collection_id}->{scripts_content}}{$keyinput};

    my $scripts_contenthashref = $srdc_orig{$collection_id}->{scripts_content};
    my %scripts_contenthash = %$scripts_contenthashref;
    my $content = $scripts_contenthash{$keyinput};

    ###print "content for script $keyinput => $content\n";

    $scrtype         = $hashattribs{"type"};
    $scrname         = $hashattribs{"name"};
    $scrtimeout      = $hashattribs{"timeout"};
    $validfor        = $hashattribs{"validfor"};
    $script_platform = $hashattribs{"platform"};
    $script_version  = $hashattribs{"version"};
    $depinput        = $hashattribs{"depinput"};
    $deppattern      = $hashattribs{"deppattern"};
    

    # Discard scripts already processed in foreground (tfactldiagcollect)
    if ( $scrtype eq "DB" or $scrtype eq "SQL" or $scrtype eq "EMSQL" or 
            $scrtype eq "SQLSCRIPT" or $scrtype eq "OS" ) {
      print LOG localtime(time) . " : Skipping script $scrname as it has already been processed in FG\n";
      next;
    }
    if ( length $depinput && exists $savedinputs{$depinput} ) {
      print LOG localtime(time) ." : Checking deppattern : $deppattern against saved:".$savedinputs{$depinput}."\n";
      if ( $savedinputs{$depinput} =~ /$deppattern/ ) {
        print LOG localtime(time) ." : Valid dependent input:$depinput value $savedinputs{$depinput} match: $deppattern\n";
      } else { 
        print LOG localtime(time) ." : Invalid dependent input:$depinput value $savedinputs{$depinput} match: $deppattern\n";
        next;
      }
    }
    @scr = ();
    # Add all the setenvs to the start of the script
    # If we have supplied a platform then make sure it matches
    print LOG localtime(time) . " : SRDC Found $scrname of type  $scrtype for platform $script_platform\n";
    if ( $script_platform eq $osname or !length($script_platform) or ((!$IS_WINDOWS) and $script_platform eq "allux") ) 
       # same platform or no platform supplied.
    { 
      @scr = ();
      foreach my $key ( keys %scriptenvs ) {
         if ( $IS_WINDOWS ) {
            push @scr, "set " . $key . "=" . $scriptenvs{$key};
         } else {
            push @scr, $key . "=" . $scriptenvs{$key};
            push @scr, "export $key";
         }
      }
    } else {
      print LOG localtime(time) . " : SRDC $scrname of type  $scrtype for platform $script_platform does not run on $osname\n";
      next; # don't go any farther, script does not run in current platform
    }

    # Script replacements
    # -------------------
    foreach my $testtr (keys %scriptreplace) {
      # replace only non pwds params
      # -----------------------------------
      $content =~ s/\%$testtr\%/$scriptreplace{$testtr}/ if ( $testtr !~ /_PWD/ );
    }
    push @scr, $content;

    ###############################
    #       script generation section
    ###############################
    #
    $scrname =~ s/ //g;
    my $sfname;
    if ( $IS_WINDOWS ) {
       $sfname = "script_$scrname.bat";
    } else {
      $sfname = "script_$scrname.sh";
    }

    my $tfactl = catfile($tfahome,"bin","tfactl");
    open(SWF, ">$sfname");
    foreach my $line (@scr)
    {
      chomp($line);
      $line =~ s/tfactl /$tfactl /; 
      $line =~ s/^\s+//;
      if ( $line =~ /orachk/ && ( isExadata() || isExadataDom0() ) ) {
           $line =~ s/orachk/exachk/ ;
      }
      if ( $scrtype eq "CLUORACHK") {
         if ( $database && $database ne "all" ) {
            my $newdb = $database;
            $newdb =~ s/\,$//;
            print SWF "$line -dbnames $newdb\n";
         } else {
           print SWF "$line\n";
         }
      } else {
        print SWF "$line\n";
      }
    }
    close(SWF);
    chmod(0755,$sfname);

    # ##############################
    #          OS section
    # ##############################
    if ( $scrtype eq "CLUOS" ) {
       my $oreq = 0;
       my @lines = split /\n/ , tfactlshare_cat($sfname);
       $oreq = grep { $_ =~ /ORACLE_HOME/ } @lines;

       my $validrun = FALSE;
       chomp($oreq);
       print LOG "oreq: $oreq\n";
    } elsif ( $scrtype eq "CLUSQL" ) {
      push @sql_scripts, $sfname;
    } elsif ( $scrtype eq "CLUSQLSCRIPT" ) {
      push @sql_scripts, $scrname;
    } elsif ( $scrtype eq "IPSPACK" ) {
      push @ipspack_scripts, $sfname;
    } elsif ( $scrtype eq "TFADBPERF" ) {
      push @tfadbperf_scripts, $scrname;
    } elsif ( $scrtype eq "SRDCTOOL" ) {
      # use srdc identifier here ..
      push @srdctool_scripts, $scrname;
    } elsif ( $scrtype eq "CLUORACHK" ) {
      if ( $script_version ) {
         $orachk_scripts{$scrname} = $script_version ;
      } else {
        $orachk_scripts{$scrname} = "all" ;
      }
    } elsif ( $scrtype eq "TFACTL" ) {
      if ( $script_version ) {
         $tfactl_scripts{$scrname} = $script_version ; 
      } else {
        $tfactl_scripts{$scrname} = "all" ; 
      } 
    }
    chmod(0644,$sfname);

    $script_version = "";
  } # end foreach $keyinput
  # ------------------- foreach my $keyinput --------------- >>>>>>>>>>>>>>>>>>>



  # Copy the pre processing files.
  # ------------------------------
  my $srdcdir = $xml_filter_file;
  $srdcdir = dirname($xml_filter_file);
  my $srdctag = $xml_filter_file;
  my $uname;
  $srdctag =~ /.*tfa_(.*)\.xml/;
  $srdcdir = catdir($srdcdir,$1);
  print LOG localtime(time) . " Copying All files from $srdcdir ";
  opendir (D1, $srdcdir);
  foreach my $srdcfile ( readdir D1 ) {
     next if ( $srdcfile eq "." or $srdcfile eq ".." );
     $srdcfile = catfile($srdcdir,$srdcfile);
     print LOG localtime(time) . " : Copying file $srdcfile to $repository\n";
     # manuegar_srdcwin_shared
     if ( ! $IS_WINDOWS ) {
       my $fuid = (stat abs_path($srdcfile))[4];
       $uname = (getpwuid $fuid)[0]; 
     } else { 
       $uname = $current_user;
     }
     if ( $requser eq $uname ) {
        move($srdcfile,$repository);
     } else {
        print LOG localtime(time) . " : Unable to copy file $srdcfile to $repository\n";
     }
  }
  closedir(D1);
  # manuegar_srdcwin_shared
  if ( ! $IS_WINDOWS ) {
    my $duid = (stat abs_path($srdcdir))[4];
    $uname = (getpwuid $duid)[0];
  } else {
    $uname = $current_user;
  }
  if ( $requser eq $uname ) {
     rmdir($srdcdir);
  } else {
     print LOG localtime(time) . " : Unable to remove directory $srdcdir - Not owner Please check\n";
  }
  # Copy xml file
  print LOG localtime(time) . " : Copying file $xml_filter_file to $repository\n";
  # manuegar_srdcwin_shared
  if ( ! $IS_WINDOWS ) {
    my $xmlfuid = (stat abs_path($xml_filter_file))[4];
    $uname = (getpwuid $xmlfuid)[0];
  } else {
    $uname = $current_user;
  }
  if ( $requser eq $uname ) {
     move($xml_filter_file,$repository);
  } else {
     print LOG localtime(time) . " : Unable to copy file $xml_filter_file to $repository\n";
  }
  # Remove .orig file is left behind
  print LOG localtime(time) . " : Removing file $xml_filter_file.orig \n";
  if ( -f "$xml_filter_file.orig" ) {
    if ( ! $IS_WINDOWS ) {
      my $xmlfuid = (stat abs_path("$xml_filter_file.orig"))[4];
      $uname = (getpwuid $xmlfuid)[0];
    } else {
      $uname = $current_user;
    }
    if ( $requser eq $uname ) {
       unlink("$xml_filter_file.orig");
    } else {
       print LOG localtime(time) . " : Unable to Remove $xml_filter_file.orig \n";
    }
  } else {
    print LOG localtime(time) . " : File $xml_filter_file.orig did not exist\n";
  }

} # End if ( $xml_filter_file && -r $xml_filter_file )

# Run actions in components.xml file
read_comp_xml ($tfahome, $actions, $srdccode);

# Run chmos
my $activeversion="0";
open (AV,$hostname . "_ACTIVEVERSION") or $activeversion = "0";
while (<AV>) {
   if (/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/) {
       $activeversion = $&;
       print LOG localtime(time) . ": CRS ACTIVE VERSION is $activeversion\n";
   }
}
close(AV);

if ($activeversion == 0 && $crshome && -d $crshome) {
  my $command;
  if ($IS_WINDOWS) {
    $command = catfile($crshome, "bin", "crsctl.exe") . " query crs activeversion";
  } else {
    $command = catfile($crshome, "bin", "crsctl") . " query crs activeversion"; 
  }

  my $output = `$command`;
  if ($output =~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/) {
    $activeversion = $&;
    print LOG localtime(time) . ": CRS ACTIVE VERSION is $activeversion\n";
  }
}

if ($chmos) 
{
  my $chmoscommand;
  my $chmoscommandlegacy;
  my $chmoscommandtab;
  my $chmoscommandjson;
  my $fprefix;
  # collect chmos data using oclumon
  my $chmosexe;
  my $needchmlegacy = 0;
  if ($IS_WINDOWS) {
    $chmosexe = catfile ($crshome,"BIN","oclumon.exe");
  } else {
    $chmosexe = catfile ($crshome,"bin","oclumon");
  }
  if ($chmnodelist) {
    $chmoscommand = "$chmosexe dumpnodeview -n $chmnodelist -v";
    $chmoscommandlegacy = "$chmosexe dumpnodeview -format legacy -n $chmnodelist -v";
    $chmoscommandtab = "$chmosexe dumpnodeview -format tabular -n $chmnodelist -v";
    $chmoscommandjson = "$chmosexe dumpnodeview -format json -n $chmnodelist -v";
    $fprefix = $hostname . "_multi_node";
  } else {
    $chmoscommand = "$chmosexe dumpnodeview -n $hostname -v";
    $chmoscommandlegacy = "$chmosexe dumpnodeview -format legacy -n $hostname -v";
    $chmoscommandtab = "$chmosexe dumpnodeview -format tabular -n $hostname -v";
    $chmoscommandjson = "$chmosexe dumpnodeview -format json -n $hostname -v";
    $fprefix = $hostname;
  }
  my $libpath = catfile ($crshome,"lib");
  my $redolegacy = 0; 
  my $version_number = get_version_number($activeversion);  #12.2 has the default tabulaer format
  print LOG "VERSION NUMBER: $version_number\nACTIVE: $activeversion\n"; 

  if (-e $chmosexe)
    {
      $ENV{'LIBPATH'} = "$libpath:$ENV{'LIBPATH'}";
      if ( $starttime &&  $endtime ) {
         # Try to get JSON format 
         print LOG localtime(time) . ": Collecting CHMOS data in json form from $starttime to $endtime\n";
         $chmoscommandjson = "$chmoscommandjson -s $starttime -e $endtime > $fprefix" . "_CHMOSJSON 2>&1";
         osutils_runtimedcommand($chmoscommandjson, 1800,FALSE,\*LOG);
         if ( osutils_grep_file($fprefix . "_CHMOSJSON","CRS-9009") ) { # No json format support so remove and get legacy
            print LOG localtime(time) . ": CHMOS data in json format not supported at this version\n";
            unlink($fprefix . "_CHMOSJSON");
            $needchmlegacy = 1;
         }
         if ( $version_number >= 121020 ) {# Default is tabular in 121 and above
            print LOG localtime(time) . ": Collecting CHMOS data in tabular form from $starttime to $endtime\n";
            $chmoscommandtab = "$chmoscommandtab -s $starttime -e $endtime > $fprefix" . "_CHMOSTAB 2>&1";
            osutils_runtimedcommand($chmoscommandtab, 1800,FALSE,\*LOG);
            if ( $needchmlegacy ) { 
               print LOG localtime(time) . ": Collecting CHMOS data in legacy form from $starttime to $endtime\n";
               $chmoscommandlegacy = "$chmoscommandlegacy -s $starttime -e $endtime > $fprefix" . "_CHMOS 2>&1";
               osutils_runtimedcommand($chmoscommandlegacy, 1800,FALSE,\*LOG);
            }
         } else { 
            print LOG localtime(time) . ": Collecting CHMOS data in tabular form if available from $starttime to $endtime\n";
            $chmoscommandtab = "$chmoscommandtab -s $starttime -e $endtime > $fprefix" . "_CHMOSTAB 2>&1";
            osutils_runtimedcommand($chmoscommandtab, 1800,FALSE,\*LOG);
            if ( $needchmlegacy ) { 
               print LOG localtime(time) . ": Collecting CHMOS data in legacy form from $starttime to $endtime\n";
               $chmoscommand = "$chmoscommand -s $starttime -e $endtime > $fprefix" . "_CHMOS 2>&1";
               osutils_runtimedcommand($chmoscommand, 1800,FALSE,\*LOG);
            }
         }
      } else {
         # Try to get JSON format 
         print LOG localtime(time) . ": Collecting CHMOS data in json form for the last $timeduration\n";
         $chmoscommandjson = "$chmoscommandjson -last $timeduration > $fprefix" . "_CHMOSJSON 2>&1";
         osutils_runtimedcommand($chmoscommandjson, 1800,FALSE,\*LOG);
         if ( osutils_grep_file($fprefix . "_CHMOSJSON","CRS-9009") ) { # No json format support so remove and get legacy
            print LOG localtime(time) . ": CHMOS data in json format not supported at this version\n";
            unlink($fprefix . "_CHMOSJSON");
            $needchmlegacy = 1;
         }
        if ( $version_number >= 121020 ) {
           print LOG localtime(time) . ": Collecting CHMOS data in tabular form for the last $timeduration\n";
           $chmoscommandtab = "$chmoscommandtab -last $timeduration > $fprefix" ."_CHMOSTAB 2>&1";
           osutils_runtimedcommand($chmoscommandtab, 1800,FALSE,\*LOG);
           if ( $needchmlegacy ) { 
              print LOG localtime(time) . ": Collecting CHMOS data in legacy form for the last $timeduration\n";
              $chmoscommandlegacy = "$chmoscommandlegacy -last $timeduration > $fprefix" ."_CHMOS 2>&1";
              osutils_runtimedcommand($chmoscommandlegacy, 1800,FALSE,\*LOG);
           }
        } else {
            print LOG localtime(time) . ": Collecting CHMOS data in tabular form if available from $starttime to $endtime\n";
            $chmoscommandtab = "$chmoscommandtab -s $starttime -e $endtime > $fprefix" . "_CHMOSTAB 2>&1";
            osutils_runtimedcommand($chmoscommandtab, 1800,FALSE,\*LOG);
            if ( $needchmlegacy ) { 
               print LOG localtime(time) . ": Collecting CHMOS data in legacy form from $starttime to $endtime\n";
               $chmoscommand = "$chmoscommand -s $starttime -e $endtime > $fprefix" . "_CHMOS 2>&1";
               osutils_runtimedcommand($chmoscommand, 1800,FALSE,\*LOG);
            }
        }
      }
    } else {
       print LOG localtime(time) . ": Unable to collect chmos data Could not find $chmosexe\n";
    }
} # End of if chmos 

# Add information to Summary .
open(SUMMARY, ">> $summaryfile");
my $infile = "$hostname" . "_ACTIVEVERSION";
if ( -f $infile ) {
   print SUMMARY "\n\nGI information\n";
   print SUMMARY "==============\n\n";
   
   open (IF, $infile);
   while (<IF>) { 
      chomp;
      print SUMMARY "$_\n";
   }
   close(IF);
   $infile = "$hostname" . "_CLUSTERCONFIG";
   open (IF, $infile);
   while (<IF>) { 
      chomp;
      print SUMMARY "$_\n";
   }
   close(IF);
}
print LOG localtime(time) . ": Completed collecting extra files \n";
     
close(LOG);

sub get_loc
{
  my $file  = shift;
  my $loc = "";
  open(RF, $file);
  while(<RF>)
  {
    chomp;
    $loc = $1 if ( /^Output location = (.*)/);
  }
  close(RF);
  return $loc;
}

sub get_orachk_files
{
  my $scr = shift;
  my $t1 = shift;
  my $t2 = shift;

  my $locf = catfile("", "tmp", ".$scr.loc");
  my $outdir = "";
  if ( -r "$locf" )
  {
    $outdir = get_loc($locf);
    if ( -d "$outdir" )
    {
      print LOG "Found $scr files in $outdir\n";
    }
     else
    {
      print LOG "$scr output location $outdir does not exists\n";
      return;
    }
  }
   else
  {
    print LOG "Could not find $scr files\n";
    return;
  }
  if ( -d $outdir )
  {
    get_files_in_range ($outdir, $scr, $t1, $t2);
  }
  collect_for_a_tool($tfa_repository, $scr, $scr, $t1, $t2);
}

sub get_oswbba_files
{
  my $t1 = shift;
  my $t2 = shift;

  my $oswdir = catfile(dirname($repository), "oswbba");
  print LOG localtime(time) . " : Checking $oswdir\n";
  if ( -d "$oswdir")
  {
    get_files_in_range("$oswdir", "oswbba", $t1, $t2);
  }
}

sub get_oratop_files
{
  my $db = shift;
  my $t1 = shift;
  my $t2 = shift;

  my $oratopdir = catfile(dirname($repository), "oratop");
  print LOG localtime(time) . " : Checking $oratopdir\n";
  if ( -d "$oratopdir")
  {
    get_files_in_range("$oratopdir", $db, $t1, $t2);
  }
  collect_for_a_tool($tfa_repository, "oratop", $db, $t1, $t2);
}

# Collect suptools files generated during the input time period
sub collect_for_a_tool
{
  my $tfa_repository = shift;
  my $tool = shift;
  my $pat = shift;
  my $t1 = shift;
  my $t2 = shift;
  my $tool_dir = catfile($tfa_repository, "suptools", "$hostname", $tool);
  if ( -d $tool_dir )
  {
    opendir (TD1, $tool_dir);
    while (my $e = readdir(TD1) )
    {
      next if ( $e eq "." || $e eq "..");
      my $tool_base = catfile($tfa_repository, "suptools", "$hostname", $tool, $e);
      if ( -d $tool_base && -r $tool_base )
      {
        print LOG localtime(time) . " : Checking $tool_base\n";
        get_files_in_range($tool_base, $pat, $t1, $t2);
      }
    }
    closedir (TD1);
  }
}

sub get_files_in_range
{
  my $dir = shift;
  my $pat = shift;
  my $t1 = shift;
  my $t2 = shift;
  opendir (D1, $dir) or die "can't opendir $dir: $!";
  my $lastzip = "";
  my $lastzipdate = "";
  my @files2cp = ();

  while (my $e = readdir(D1) ) 
  {
    next if ( $e eq "." || $e eq "..");
    my $comp = "";
    my ($time, $time1);
    my $lmtime = (stat("$dir/$e"))[9];
    my ( $yr, $mon, $day, $hr, $mi, $ss);
    if ( $e =~ /$pat/i && $e =~ /.*_(\d\d)(\d\d)(\d\d)_(\d\d)(\d\d)(\d\d)\.zip/ )
    { # orachk
      $comp = "orachkzip";
      $yr = 2000 + $3;
      $mon = $1;
      $day = $2;
      $hr = $4;
      $mi = $5;
      $ss = $6;
      my $zipdate = "$yr$mon$day$hr$mi$ss";
      if ( ! $lastzipdate || $lastzipdate < $zipdate )
      {
        $lastzipdate = "$zipdate";
        $lastzip = "$e";
      }
    }
     elsif ( $e =~ /$pat/i && $e =~ /.*_(\d\d)(\d\d)(\d\d)_(\d\d)(\d\d)(\d\d)/ && -d "$dir/$e" )
    { # orachk
      $comp = "orachk";
      $yr = 2000 + $3;
      $mon = $1; 
      $day = $2;
      $hr = $4;
      $mi = $5;
      $ss = $6;
    }
     elsif ( $e =~ /$pat/i && $e =~ /(\d+)-(\d\d)-(\d\d)-(\d+)-(\d+)-(\d+)_(\d+)-(\d\d)-(\d\d)-(\d+)-(\d+)-(\d+)\.out/ )
    { # oswbba
      $comp = "oswbba";
      $yr = $1;
      $mon = sprintf("%02d", $2);
      $day = sprintf("%02d", $3);
      $hr = sprintf("%02d", $4);
      $mi = sprintf("%02d", $5);
      $ss = sprintf("%02d", $6);
      $time1 = timelocal($ss, $mi, $hr, $day, $mon-1, $yr);
      $yr = $7;
      $mon = sprintf("%02d", $8);
      $day = sprintf("%02d", $9);
      $hr = sprintf("%02d", $10);
      $mi = sprintf("%02d", $11);
      $ss = sprintf("%02d", $12);

    }
     elsif ( $e =~ /$pat/i && $e =~ /(\d+)-(\d\d)-(\d\d)-(\d+)-(\d+)-(\d+)\.out/ )
    { # oratop
      $comp = "oratop";
      $yr = $1;
      $mon = sprintf("%02d", $2);
      $day = sprintf("%02d", $3);
      $hr = sprintf("%02d", $4);
      $mi = sprintf("%02d", $5);
      $ss = sprintf("%02d", $6);
    }
     elsif ( $e =~ /${pat}_/ )
    { # sqlt etc.
      $comp = "$pat";
    }
    if ( $yr )
    {
      $time = timelocal($ss, $mi, $hr, $day, $mon-1, $yr);
    }
    my $copy_file = 0;
    if ( $time >=$t1 && $time <= $t2 )
    {
      $copy_file = 1;
    }
    elsif ( $lmtime >=$t1 && $lmtime <= $t2 )
    { 
      $copy_file = 1;
    } 
     elsif ( $time1 && $time1 >=$t1 && $time1 <= $t2 )
    { 
      $copy_file = 1; 
    } 
    $copy_file = 0 if ( ! $comp ); 

    if ( $copy_file == 1 )
    {
      print LOG "Copy $e\n";
      if ( $comp eq "oratop" || $comp eq "oswbba" || $comp eq $pat )
      {
        copy(catfile($dir, $e), $e);
      }
      elsif ( $comp eq "orachk" )
      {
        my $ehtml = "$e.html";
        my $elog = "$e.log";
        copy(catfile($dir, $e, $ehtml), $ehtml);
        copy(catfile($dir, $e, "log", "$pat.log"), $elog);
      }
    }
  }
  closedir (D1);
  if ( $lastzip )
  {
    print LOG "Copying last zip $lastzip\n";
    copy(catfile($dir, $lastzip), $lastzip);
  }
}

sub read_comp_xml
{
  my $tfa_home = shift;
  my $comps = shift;
  my $srdccode = shift;
  my %comps = map { lc($_) => 1 } split(/,/, $comps);
  my %actions = ();
  my $cxml = catfile($tfa_home, "resources", "components.xml");
  my $command;
  my $cmdout;
  my $dbversion;
  my $scripttorun;

  my %param_mapping = (
		"from" => "$starttime",
		"to" => "$endtime",
		"tfahome" => "$tfa_home",
		"noarg" => "null",
		"hostname" => "$hostname",
		"ohome" => "_ORACLE_HOME2REPLACE_",
		"crshome" => "_ORACLE_CRSHOME2REPLACE_",
		"ouser" => "_ORACLE_USER2REPLACE_",
		"osid" => "_ORACLE_SID2REPLACE_",
		"hostname" => "$hostname",
		"database" => "$database",
		"db" => "$database"
  	);

  $param_mapping{"from"} =~ s/\"//g;
  $param_mapping{"to"} =~ s/\"//g;

  if ( $database && $database ne "all" )
  {
    # Add the sql script to gather feature_usage statistics when we gather for a specific database.
    push @sql_scripts, "db_feature_usage.sql";
    foreach my $dbname (split(/,/, $database))
    {
      print LOG localtime(time) .  " : processing for database $dbname \n\n";
      my $ret = dbutil_setOraEnv ($tfa_home, "$dbname",\*LOG,TRUE);
      print LOG localtime(time) .  " : dbutil_setOraEnv() retval -> $ret\n";
      if ( $ret == 0 )
      {
        print LOG localtime(time) .  " : requser $requser \n";
        print LOG localtime(time) .  " : ORACLE_HOME = " . $ENV{"ORACLE_HOME"} . "\n";
        print LOG localtime(time) .  " : isUserInDbaGrp " . tfactlshare_isuserindbagrp($requser,$ENV{"ORACLE_HOME"}) . "\n";
        # only add to the list and hence execute for valid users or root
        if ( $requser eq "root" || tfactlshare_isuserindbagrp($requser,$ENV{"ORACLE_HOME"}) ) {
          $param_mapping{"$dbname-ORACLE_HOME"} = $ENV{"ORACLE_HOME"};
          $param_mapping{"$dbname-ORACLE_SID"} = $ENV{"ORACLE_SID"};
          $param_mapping{"$dbname-OUSER"} = $ENV{"TFA_ORACLE_USER"};
          $param_mapping{"$dbname-OVERSION"} = $ENV{"TFA_ORACLE_VERSION"};
          $dbversion = $ENV{"TFA_ORACLE_VERSION"};
          push @dbusers, $ENV{"TFA_ORACLE_USER"};
          print LOG localtime(time) .  " : $dbname-ORACLE_HOME = " . $ENV{"ORACLE_HOME"} . "\n";
          print LOG localtime(time) .  " : $dbname-ORACLE_SID  = " . $ENV{"ORACLE_SID"} . "\n";
          print LOG localtime(time) .  " : $dbname-OUSER       = " . $ENV{"TFA_ORACLE_USER"} . "\n";
          print LOG localtime(time) .  " : $dbname-OVERSION    = " . $ENV{"TFA_ORACLE_VERSION"} . "\n";
          print LOG localtime(time) .  " : TFA_ORACLE_USER     = " . $ENV{"TFA_ORACLE_USER"} . "\n";
        }
      } # end if $ret == 0
    }
  } # end if $database && $database ne "all"

  #If we do not have a version from the OH or the param mapping we may have one from input.
  $dbversion = $inputorahome_dbv if not length $dbversion;
  #  TFACTL dbperf Section
  # ======================# 
  if ( @tfadbperf_scripts )
  {
    foreach my $srdcname ( @tfadbperf_scripts ) {#Support multiple dbperf scripts. 
      #my $srdcname = $tfadbperf_scripts[0];
      my $tfa_repository = tfactlshare_get_repository_location($tfa_home);
      if ( $IS_WINDOWS ) {
        $scripttorun = catfile($repository,"script_$srdcname.bat");
      } else {
        $scripttorun = catfile($repository,"script_$srdcname.sh");
      }

      foreach my $dbname (split(/,/, $database))
      {
        print LOG localtime(time) .  " : Running tfactl dbperf $srdcname for database $dbname\n";
        if ( exists $param_mapping{"$dbname-ORACLE_HOME"} )
        {
          my $ohome    = $param_mapping{"$dbname-ORACLE_HOME"};
          my $runuser  = $param_mapping{"$dbname-OUSER"};
          my $osid     = $param_mapping{"$dbname-ORACLE_SID"};
          my $cmdout;
          my $lines;
          my $srcfile;
          print LOG localtime(time) .  " : Param Mapping ohome: $ohome runuser: $runuser osid: $osid for db $dbname \n";
          next if not length($osid); # no point running if we do not have a sid.
          $ENV{ORACLE_HOME} = $ohome;
          $ENV{ORACLE_SID}  = $osid;
          $ENV{LD_LIBRARY_PATH} = catfile($ohome,"lib");
          my $tfadbperf = catfile($tfa_home,"bin","tfactl");
          my $tool_base = catfile($tfa_repository, "suptools", "$hostname","dbperf", $runuser);
          my $now_string = strftime("%m-%d-%y-%H:%M:%S",localtime());
          my $tool_out_dir = catfile($tool_base,$dbname . "-" .$now_string);
    
          if ( $srdcname eq "dbhang" ) { #Requires only db
            print LOG localtime (time) . " tfactl dbperf name $srdcname processing for db $dbname sid $osid \n";
            $command ="$tfadbperf dbperf $srdcname -db \"$dbname\" -fromsrdc \"$now_string\" ";
          } elsif ( $srdcname eq "awr_reports" ) { #Needs db,starttime, endtime, baselinefrom,baselineto,awrlicense,issuenow
            $issuenow_flag = "false" if ( not $issuenow_flag );
            print LOG localtime(time) .  " : tfactl dbperf name $srdcname processing for db $dbname sid $osid".
            " from $event_start_time to $event_end_time basefrom $baselinefrom baseto $baselineto".
            " issuenow \"$issuenow_flag\" license \"$license_flag\" \n\n";
            $event_start_time = convert_time_for_srdc($event_start_time,"start time");
            $event_end_time = convert_time_for_srdc($event_end_time,"end time");
            $baselinefrom = convert_time_for_srdc($baselinefrom,"baseline start time") if($baselinefrom);
            $baselineto = convert_time_for_srdc($baselineto,"baseline end time") if ($baselineto);
            $command = "$tfadbperf dbperf $srdcname -fromsrdc \"$now_string\" -db \"$dbname\"";
            $command .=" -perf_good_st \"$baselinefrom\" -perf_good_et \"$baselineto\"" if($baselinefrom && $baselinefrom);
            $command .=" -perf_bad_st \"$event_start_time\" -perf_bad_et \"$event_end_time\"".
            " -issuenow $issuenow_flag -license $license_flag";        
          } else {

            if ( $event_time ){
              print LOG localtime (time) . " : tfactl dbperf name $srdcname processing for db $dbname sid $osid event_time $event_time\n\n";
              $event_time = convert_time_for_srdc($event_time,"event time");
              $command = "$tfadbperf dbperf $srdcname -fromsrdc \"$now_string\" -db \"$dbname\" -inc_time \"$event_time\"";
              
            }
            if($event_start_time && $event_end_time && ! $baselineto && ! $baselinefrom){
                print LOG localtime(time) .  " : tfactl dbperf name $srdcname processing for db $dbname sid $osid starttime $event_start_time endtime $event_end_time\n\n";    
                $event_start_time = convert_time_for_srdc($event_start_time,"start time");
                $event_end_time = convert_time_for_srdc($event_end_time,"end time");
                $command = "$tfadbperf dbperf $srdcname -fromsrdc \"$now_string\" -db \"$dbname\" -perf_bad_st \"$event_start_time\" -perf_bad_et \"$event_end_time\"";

            }
            if ( $baselineto && $baselinefrom ) {
                print LOG localtime(time) .  " : tfactl dbperf name $srdcname processing for db $dbname sid $osid".
                " from $event_start_time to $event_end_time basefrom $baselinefrom baseto $baselineto".
                " issuenow \"$issuenow_flag\" license \"$license_flag\" slowsql \"$slow_sqlID\" \n\n";
                $event_start_time = convert_time_for_srdc($event_start_time,"start time");
                $event_end_time = convert_time_for_srdc($event_end_time,"end time");
                $baselinefrom = convert_time_for_srdc($baselinefrom,"baseline start time");
                $baselineto = convert_time_for_srdc($baselineto,"baseline end time");
                $command = "$tfadbperf dbperf $srdcname -fromsrdc \"$now_string\" -db \"$dbname\"".
                " -perf_good_st \"$baselinefrom\" -perf_good_et \"$baselineto\"".
                " -perf_bad_st \"$event_start_time\" -perf_bad_et \"$event_end_time\"".
                " -issuenow $issuenow_flag -license $license_flag";
                $command .= " -sqlid $slow_sqlID" if (length $slow_sqlID);
            }
          }

          # write the command to a file to execute.
          # --------------------------------------
          open(F1, '>',"$scripttorun") || die "ERROR Unable to open file: $!\n";
          print F1 "$command\n";
          close(F1);
          chmod(0755,$scripttorun);

          if  ( $IS_WINDOWS ) {
            $command = $scripttorun;
          } else {
            $command = tfactlshare_checksu($runuser,"cd ~;sh $scripttorun");
          };

          print LOG localtime(time) . " : After checksu Command is : $command\n";
          $cmdout = osutils_runtimedcommand("$command 2>&1", 3600 , TRUE, \*LOG);
          chmod(0700,$scripttorun);

          my $fileswildcard = catfile($tool_out_dir,"*");
          print LOG localtime(time) . " : Moving all files from $fileswildcard to $repository for dbperf $srdcname\n\n";
          if ( -d $tool_out_dir ) {
            for my $file (glob $fileswildcard) {
                move($file,catfile($repository,""));
            }
          }
          #$command = "echo \"$cmdout\" >> $srdcname.out 2>&1";
          print LOG  localtime(time) . " $srdcname.out ::: $cmdout\n";
          #osutils_runtimedcommand($command,60);
          print LOG localtime(time) . " : Finished executing TFACTL dbperf $srdcname\n\n";
        } # End if ( exists $param_mapping{"$dbname-ORACLE_HOME"} )
        else
        {
          print LOG "Unable to find parameter mapping to run TFACTL dbperf $srdcname for databse $dbname\n";
        }
      } # End for each
    }# End for each tfactl dbperf script
  } # End if tfactl dbperf scripts

  # SRDCTOOL Section
  # Temporary need to handle old srdc 
  # =================================
  if ( @srdctool_scripts )
  {
    my $srdcname = $srdctool_scripts[0];
    if ( $IS_WINDOWS ) {
      $scripttorun = catfile($repository,"script_$srdcname.bat");
    } else {
      $scripttorun = catfile($repository,"script_$srdcname.sh");
    }

    foreach my $dbname (split(/,/, $database))
    {
      print LOG "Running srdc $srdcname for database $dbname\n";
      if ( exists $param_mapping{"$dbname-ORACLE_HOME"} )
      {
        my $ohome    = $param_mapping{"$dbname-ORACLE_HOME"};
        my $runuser  = $param_mapping{"$dbname-OUSER"};
        my $osid     = $param_mapping{"$dbname-ORACLE_SID"};
        my $cmdout;
        my $lines;
        my $srcfile;
        
        $ENV{ORACLE_HOME} = $ohome;
        $ENV{ORACLE_SID}  = $osid;
        $ENV{LD_LIBRARY_PATH} = catfile($ohome,"lib");
        my $tfasrdc = catfile($tfa_home,"bin","tfactl");

        if ( $event_time ) {
            print LOG localtime(time) .  " : old SRDC tool name $srdcname processing for db $dbname sid $osid event_time $event_time\n\n";
            $event_time = convert_time_for_srdc($event_time,"event time");
            my @time_arr = split(/\s/,$event_time);
            my $incdate = $time_arr[0];
            my $inctime = $time_arr[1];
            $command = "$tfasrdc srdc $srdcname -sid \"$osid\" -inc_date \"$incdate\" -inc_time \"$inctime\"";
        }
        if ( $baselineto && $baselinefrom ) {
            print LOG localtime(time) .  " : old SRDC tool name $srdcname processing for db $dbname sid $osid from $starttime to $endtime basefrom $baselinefrom baseto $baselineto \n\n";
            $starttime = convert_time_for_srdc($starttime,"start time");
            my @time_arr = split(/\s/,$starttime);
            my $pcsd = $time_arr[0];
            my $pcst = $time_arr[1];
            $endtime = convert_time_for_srdc($endtime,"end time");
            my @time_arr = split(/\s/,$endtime);
            my $pced = $time_arr[0];
            my $pcet = $time_arr[1];
            $baselinefrom = convert_time_for_srdc($baselinefrom,"baseline start time");
            my @time_arr = split(/\s/,$baselinefrom);
            my $pbsd = $time_arr[0];
            my $pbst = $time_arr[1];
            $baselineto = convert_time_for_srdc($baselineto,"baseline end time");
            my @time_arr = split(/\s/,$baselineto);
            my $pbed = $time_arr[0];
            my $pbet = $time_arr[1];
            $command = "$tfasrdc srdc $srdcname -sid \"$osid\" -perf_base_sd \"$pbsd\" -perf_base_st \"$pbst\" -perf_base_ed \"$pbed\" -perf_base_et \"$pbet\" -perf_comp_sd \"$pcsd\" -perf_comp_st \"$pcst\" -perf_comp_ed \"$pced\" -perf_comp_et \"$pcet\"";
        }

       # write the command to a file to execute.
       # --------------------------------------
        open(F1, '>',"$scripttorun") || die "ERROR Unable to open file: $!\n";
        print F1 "$command\n";
        close(F1);
        chmod(0755,$scripttorun);

        if ( $IS_WINDOWS ) {
          $command = $scripttorun;
        } else {
          $command = tfactlshare_checksu($runuser,"cd ~;sh $scripttorun");
        }

        print LOG localtime(time) . " : After checksu Command is : $command\n";
        $cmdout = osutils_runtimedcommand("$command 2>&1", 600 , TRUE,\*LOG);
        chmod(0700,$scripttorun);

        foreach my $line (split /\n/ , $cmdout) {
          $lines .= "line << $line >>\n";
          if ( $line =~ /\s*(\/.*da_srdc.*\.zip)\.*/ ) {
             $srcfile = trim($1);
          }
        } # end foreach split /\n/ , $cmdout
        move($srcfile,catfile($repository,"",".")) if ( -f $srcfile ) ;

        #$command = "echo \"$cmdout\" >> $srdcname.out 2>&1";
        print LOG  localtime(time) . " $srdcname.out ::: $cmdout\n";
        #osutils_runtimedcommand($command,60);
        print LOG localtime(time) . " : Finished executing $srdcname\n\n";
      } # End if ( exists $param_mapping{"$dbname-ORACLE_HOME"} )
      else
      {
         print LOG "Unable to find parameter mapping to run srdc $srdcname for databse $dbname\n";
      }
    } # End for each 
  } # End if srdctool scripts 
  
  # ORACHK section
  # ==============
  if ( %orachk_scripts )
  {
    my ($srcfile, $dstfile, $scrname, $script_version, $cmdout ) ;
    my $lines = "";
    while (($scrname, $script_version ) = each %orachk_scripts )
    {
       if ( $IS_WINDOWS ) {
         $scripttorun = catfile($repository,"script_$scrname.bat");
       } else {
         $scripttorun = catfile($repository,"script_$scrname.sh");
       }
       my $version_matched = FALSE;
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
          print LOG localtime(time) . " : Calling orachk script script_$scrname.sh ohome version $dbversion script valid version $script_version\n";
          my $newdb = $database;
          $newdb =~ s/\,$//;
          my $newdb2 = substr ($param_mapping{"$newdb-ORACLE_SID"}, 0, length $newdb );
          system("$PERL -p -i.orig -e \"s|$newdb|$newdb2|\" $scripttorun");
          chmod(0755,$scripttorun);

          if ( $IS_WINDOWS ) {
            $command = $scripttorun;
          } else {
            $command = tfactlshare_checksu($requser,"cd ~;sh $scripttorun");
          }

          print LOG localtime(time) . " : After checksu Command is : $command\n";
          $cmdout = osutils_runtimedcommand("$command 2>&1", 600 , TRUE,\*LOG);;
          chmod(0644,$scripttorun);
          open(OUTF, ">script_$scrname.sh.out");

          foreach my $line (split /\n/ , $cmdout) {
            $lines .= "line << $line >>\n";
            print OUTF "$line\n";
            if ( $line =~ /\s*UPLOAD\(if required\) \- (.*\.zip).*/ ) {
               $srcfile = trim($1);
               if ( $srcfile =~ /.*[\/\\](orachk_.*_)(.*)(_[0-9]+_[0-9]+\.zip).*/ ) {
                 $dstfile = catfile($repository, $1 . $srdccode . "_" . $2 . $3); 
               }
            }
          } # end foreach split /\n/ , $cmdout
          close(OUTF);
          print LOG localtime(time) . " : Moving $srcfile to repository directory\n";
          print LOG localtime(time) . " : Destination file $dstfile\n";
          move($srcfile,$dstfile) if ( -f $srcfile ) ;
       }
       else
       {
          print LOG localtime(time) . " : orachk script $scrname does not run for ohome version $dbversion script valid version $script_version\n";
          unlink($scripttorun);
       } # end if $script_version eq "all" || $dbversion =~ /^$script_version/
    } # end while
  } # end if %orachk_scripts

  # TFACTL section
  # ==============
  if ( %tfactl_scripts ) 
  { 
    $ENV{SCROLLABLE_UI} = "false";  # for darda script execution
    my ($srcfile, $scrname, $script_version, $cmdout ) ;
    my $lines = "";
    while (($scrname, $script_version ) = each %tfactl_scripts )
    {

       if ( $IS_WINDOWS ) {
         $scripttorun = catfile($repository,"script_$scrname.bat");
       } else {
         $scripttorun = catfile($repository,"script_$scrname.sh");
       }

       my $version_matched = FALSE;
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
          print LOG localtime(time) . " : Calling tfactl script script_$scrname.sh ohome version $dbversion script valid version $script_version\n";
          chmod(0755,$scripttorun);

          if ( $IS_WINDOWS ) {
            $cmdout = osutils_runtimedcommand($scripttorun . " 2>&1", 600 , TRUE,\*LOG);
          } else {
            $cmdout = osutils_runtimedcommand(tfactlshare_checksu($requser,"cd ~;sh $scripttorun") . " 2>&1", 600 , TRUE,\*LOG);
          }

          chmod(0644,$scripttorun);
          open(OUTF, ">script_$scrname.sh.out");
          foreach my $line (split /\n/ , $cmdout) {
            $lines .= "line << $line >>\n";
            print OUTF "$line\n";
            if ( $line =~ /\s*output to:\s*(.*rda_HCVE.*\.html)\.*/ ) {
               $srcfile = trim($1);
            }
          } # end foreach split /\n/ , $cmdout
          close(OUTF);
          print LOG localtime(time) . " : Moving $srcfile to repository directory\n";
          move($srcfile,catfile($repository,"",".")) if ( -f $srcfile ) ;
       }
       else
       {
          print LOG localtime(time) . " : tfactl script $scrname does not run for ohome version $dbversion script valid version $script_version\n";
          unlink($scripttorun);
       }
    }
  }

  # IPS pack section
  # ----------------
  if ( @ipspack_scripts ) 
  {
    print LOG localtime(time) .  " : Trying IPS pack section for database $database\n";
    my $scrname = $ipspack_scripts[0];
    foreach my $dbname (split(/,/, $database))
    {
      if ( exists $param_mapping{"$dbname-ORACLE_HOME"} )
      {
        my $ohome    = $param_mapping{"$dbname-ORACLE_HOME"};
        my $runuser  = $param_mapping{"$dbname-OUSER"};
        my $osid     = $param_mapping{"$dbname-ORACLE_SID"};
        my $adrbase  = "invalid";
        my $adrcibin;
        my $adrhomepath;
        my $content;
        my $command;
        my $ipscmd;
        my $cmdout;
        my $lines = ""; 
        my $sqlplus = catfile($ohome,"bin","sqlplus");
        my $srdcrunuserdir;
        my $srcfile;

        $ENV{ORACLE_HOME} = $ohome;
        $ENV{ORACLE_SID}  = $osid;
        $ENV{LD_LIBRARY_PATH} = catfile($ohome,"lib");
        if ( $IS_WINDOWS ) {
          $ENV{PATH} = catfile($ohome,"bin") . ";" . $ENV{PATH};
        } else {
          $ENV{PATH} = catfile($ohome,"bin") . ":" . $ENV{PATH};
        }


        print LOG localtime(time) . " : Started executing $scrname as $runuser on database $dbname with sid $osid.\n";

        $adrbase  = tfactlshare_get_adrbase($ohome); 
        print LOG localtime(time) . " : Initial ADRBASE using $ohome : $adrbase\n";

        # Retrieve ADR base from the running db
        # diagnostic_dest = ADR base
        # -------------------------------------
        if ( $adrbase eq "invalid" && length $osid ) {
          $content = "show parameter diagnostic_dest;";
          # $ENV{ORACLE_HOME}/bin/sqlplus
          if ( $IS_WINDOWS ) {
            $command = tfactlshare_checksu($runuser,"echo $content | $sqlplus \"/as sysdba\"") . " 2>&1";
          } else {
            $command = tfactlshare_checksu($runuser,"echo \"$content\" | $sqlplus \"/as sysdba\"") . " 2>&1";
          }
          $cmdout = osutils_runtimedcommand($command,1800,TRUE,\*LOG);
          foreach my $line (split /\n/ , $cmdout) {
            #lines .= "line << $line >>\n";
            if ( $line =~ /\s*diagnostic_dest\s*string\s*([\/\\].*)/ ) {
              $adrbase = trim($1);
              print LOG localtime(time) . " : setting adrbase to $adrbase\n";
            }
          } # end foreach split /\n/ , $cmdout
        }
        next if $adrbase eq "invalid";
        print LOG localtime(time) . " : Using ADRBASE: $adrbase\n";

        $adrcibin = catfile($ohome,"bin","$ADRCI"); 
        next if not -e $adrcibin;
        print LOG localtime(time) . " : Using ADRCIBIN: $adrcibin\n";

        if (not length $runuser) {
         $runuser = getFileOwner($adrbase);
        }
        next if not length $runuser;
        print LOG localtime(time) . " : Using runuser: $runuser\n";

        # set srdc' dir for $runuser
        # --------------------------
        print LOG localtime(time) . " : Using repository: $repository\n";
        if ( $repository =~ /(.*[\/\\]repository)[\/\\]temp.*/ ) {
          $runuser = "root" if $IS_WINDOWS;
          $srdcrunuserdir = catfile($1,"suptools","srdc","user_$runuser");
          print LOG localtime(time) . " : Using srdcrundir $srdcrunuserdir for IPS\n";
          # Make sure that $srdcrunuserdir exists
          if ( ! -e $srdcrunuserdir ) {
            eval { tfactlshare_mkpath("$srdcrunuserdir", "1741"); };
            if ($@) {
              print LOG localtime(time) . " : Can not create path $srdcrunuserdir.\n";
              next;
            } # end if $@
            host("$CHOWN -R $runuser $srdcrunuserdir") if not $IS_WINDOWS;
            if ($@) {
              print LOG localtime(time) . " : Error, $CHOWN -R $runuser $srdcrunuserdir.\n";
              next;
            } # end if $@
          } # end if ! -e $srdcrunuserdir
        }
        next if not length $srdcrunuserdir;
        print LOG localtime(time) . " : srdcrunuserdir $srdcrunuserdir\n";

        # Get ADR homepath for the given $adrbase
        # ---------------------------------------
        $content  = "set base $adrbase;show homes;";
        if ( $IS_WINDOWS ) {
          $command  = tfactlshare_checksu($runuser,"echo $content | $adrcibin") . " 2>&1";
        } else {
          $command  = tfactlshare_checksu($runuser,"echo \"$content\" | $adrcibin") . " 2>&1";
        }
        $cmdout = osutils_runtimedcommand($command,1800,TRUE,\*LOG);
        foreach my $hpath ( split /\n/ , $cmdout ) {
          if ( ( length $osid && $hpath =~ /diag[\/\\]rdbms[\/\\].*[\/\\]$osid/i ) || 
               ( $hpath =~ /diag[\/\\]rdbms[\/\\]$dbname[\/\\].*/i ) ) {
            $adrhomepath = $hpath;
            print LOG localtime(time) . " : set adrhomepath : $adrhomepath\n";
          }
        } # end if split /\n/ , $homescmd
        next if not length $adrhomepath;
        print LOG localtime(time) . " : Using adrhomepath : $adrhomepath\n";

        # Assemble IPS command
        # --------------------
        if ( $IS_WINDOWS ) {
          if ( $starttime !~ /\".*\"/ ) {
             $starttime = "\"" . $starttime . "\"";
          }
          if ( $endtime !~ /\".*\"/ ) {
            $endtime =  "\"" . $endtime . "\"";
          }
          $ipscmd = "ips pack time " . $starttime . " to ". $endtime . " in $srdcrunuserdir";
        } else {
          $ipscmd = "ips pack time \\\"" . $starttime . "\\\" to \\\"". $endtime . "\\\" in $srdcrunuserdir";
        } 
        $content  = "set base $adrbase;set homepath $adrhomepath;show homes;";
        $content .= "ips set config 20 1;ips set config 21 1;ips set config 22 1;ips set config 23 1;";
        $content .= "$ipscmd;ips set config 20 0;ips set config 21 0;ips set config 22 0;";
        $content .= "ips set config 23 0;";
        if ( $IS_WINDOWS ) {
          $command  = tfactlshare_checksu($runuser,"echo $content | $adrcibin");
        } else {
          $command  = tfactlshare_checksu($runuser,"echo \"$content\" | $adrcibin");
        }
        $cmdout = osutils_runtimedcommand($command,1800,TRUE,\*LOG);
        # move zip file to $repository
        # ----------------------------
        foreach my $line (split /\n/ , $cmdout) {
            # $lines .= "line << $line >>\n";
            if ( $line =~ /\s*Generated package.*in file\s+(.*\.zip)\, mode.*/ ) {
              $srcfile = trim($1);
            }
        } # end foreach split /\n/ , $cmdout
        print LOG localtime(time) . " : IPS Generated to $srcfile\n\n";
        my $dstfile = "";
        if ( $srcfile =~ /.*(IPSPKG_.*\.zip)/ ) {
           $dstfile = $1;
        } elsif ( $srcfile =~ /.*(ORA600600_.*\.zip)/ ) {
          $dstfile = $1;
          $dstfile =~ s/ORA600600/ORA600/g;
        }
        print LOG localtime(time) . " : IPS Destination file $dstfile\n\n";
        if ( length $dstfile ) {
          print LOG localtime(time) . " : Moving $srcfile to " . catfile($repository,$dstfile) . "\n\n";
          move($srcfile,catfile($repository,$dstfile)) if ( -f $srcfile ) ;
        } else {
          print LOG localtime(time) . " : Moving $srcfile to $repository\n\n";
          move($srcfile,catfile($repository,"",".")) if ( -f $srcfile ) ;
        }
        if ( $IS_WINDOWS ) {
          $command = "echo - $cmdout - $content - >> $scrname.out 2>&1";
        } else {
          $command = "echo \"<<< $cmdout >>> <<< $content >>>\" >> $scrname.out 2>&1";
        }
        osutils_runtimedcommand($command,1800,FALSE,\*LOG);
        print LOG localtime(time) . " : Finished executing $scrname\n\n";
      } # end if exists $param_mapping{"$dbname-ORACLE_HOME"} 
    } # end foreach split(/,/, $database
  } # end if @ipspack_scripts

  # windows todo
  # ######################################
  #              SQL section
  # ######################################
  if ( $db_scripts[0] || $sql_scripts[0] )
  {
    print LOG localtime(time) .  " : executing dbscripts @db_scripts on db \n\n";
    print LOG localtime(time) .  " : executing sqlscripts @sql_scripts on db \n\n";
    foreach my $dbname (split(/,/, $database))
    {
      print LOG localtime(time) .  " : Working on Database $dbname\n";
      if ( exists $param_mapping{"$dbname-ORACLE_HOME"} )
      {
        print LOG localtime(time) .  " : Parameter map exists for " . $param_mapping{"$dbname-ORACLE_HOME"} . " on Database $dbname\n";
        $ENV{ORACLE_HOME} = $param_mapping{"$dbname-ORACLE_HOME"};
        $ENV{ORACLE_SID} = $param_mapping{"$dbname-ORACLE_SID"};
        $ENV{LD_LIBRARY_PATH} = $param_mapping{"$dbname-ORACLE_HOME"} ."/lib";
        my $runuser = $param_mapping{"$dbname-OUSER"};
        # ##############################
        #      Process @db_scripts
        # ##############################
        foreach my $scr (@db_scripts)
        {
          my $scr_orig = $scr;
          if ( ! -e $scr ) {
             print LOG localtime(time) . " : SQL Script $scr \ does not exist \n";
             next;
          }
          print LOG localtime(time) . " : Building script to run $scr as $runuser on ".$param_mapping{"$dbname-ORACLE_SID"} ." with \n\n";
          $scripttorun = catfile($repository,"script_$scr.sh");
          print LOG localtime(time) . " : Script to run $scripttorun\n\n";
          if ( ! open(F1, '>',"$scripttorun") ) {
            warn "ERROR Unable to open file $scripttorun for writing: $!\n";
            next;
          }
          print LOG localtime(time) . " : Script to run $scripttorun opened\n\n";
          print F1 "$ENV{ORACLE_HOME}/bin/sqlplus \"/as sysdba\" << EOF1\n";
          if ( ! open(F2, '<',"$scr") ) {
            warn "ERROR Unable to open script file $scr for reading: $!\n";
            next;
          }
          while (<F2>) {
             print F1 "$_";
          }
          close(F2);
          #$content =~ s/\$/\\\$/g;
          #print F1 "$content";
          print F1 "\nEOF1\n";
          close(F1);
          chmod(0755,$scripttorun);
          $command = tfactlshare_checksu($runuser,"cd ~;sh $scripttorun");
          print LOG localtime(time) . " : After checksu Command is : $command\n";
          $cmdout = osutils_runtimedcommand("$command 2>&1", 600 , TRUE,\*LOG);
          chmod(0700,$scripttorun);
          print LOG localtime(time) . " : Finished executing $scr\n\n";
          open(OUTF, ">$scr.out");
          my $htmlscript = "no";
          foreach my $line (split /\n/ , $cmdout) {
            $htmlscript = "yes" if ( $line =~ /\<pre\>/ );
            print OUTF "$line\n";
          } # end foreach split /\n/ , $cmdout
          close(OUTF);
          move("$scr.out", "$scr_orig.html") if ($htmlscript eq "yes");
        }
        # ##############################
        #      Process @sql_scripts
        # ##############################
        foreach my $scr (@sql_scripts)
        {
          my $scr_orig = $scr;
          $scr = catfile($tfa_home,"resources","sql","$scr");
          if ( ! -e $scr ) {
             print LOG localtime(time) . " : SQL Script $scr \ does not exist \n";
             next;
          }
          print LOG localtime(time) . " : Building script to run $scr as $runuser on ".$param_mapping{"$dbname-ORACLE_SID"} ." with \n\n";
          if ( ! $IS_WINDOWS ) {
            $scripttorun = catfile($repository,"script_$scr_orig.sh");
          } else {
            $scripttorun = catfile($repository,"script_$scr_orig.bat");
          }
          print LOG localtime(time) . " : Script to run $scripttorun\n\n";
          if ( ! open(F1, '>',"$scripttorun") ) {
            warn "ERROR Unable to open file $scripttorun for writing: $!\n";
            next;
          }
          print LOG localtime(time) . " : Script to run $scripttorun opened\n\n";
          # manuegar_srdcwin_shared
          if ( ! $IS_WINDOWS ) {
            print F1 "$ENV{ORACLE_HOME}/bin/sqlplus \"/as sysdba\" << EOF1\n";
            print F1 "\@$scr\n";
            #$content =~ s/\$/\\\$/g;
            #print F1 "$content";
            print F1 "\nEOF1\n";
          } else {
            print F1 "$ENV{ORACLE_HOME}\\bin\\sqlplus \"/as sysdba\" \@$scr\n";
          }
          close(F1);
          chmod(0755,$scripttorun);
          $command = tfactlshare_checksu($runuser,"cd ~;sh $scripttorun");
          print LOG localtime(time) . " : After checksu Command is : $command\n";
          $cmdout = osutils_runtimedcommand("$command 2>&1", 600 , TRUE,\*LOG);
          chmod(0700,$scripttorun);
          print LOG localtime(time) . " : Finished executing $scr\n\n";
          open(OUTF, ">$scr_orig.out");
          my $htmlscript = "no";
          foreach my $line (split /\n/ , $cmdout) {
            next if ( $scr_orig =~ /db_feature_usage/ and $line !~ /dbid/ );
            $htmlscript = "yes" if ( $line =~ /\<pre\>/ );
            print OUTF "$line\n";
          } # end foreach split /\n/ , $cmdout
          close(OUTF);
          if ( $scr_orig =~ /db_feature_usage/ ) {
            move("$scr_orig.out", "db_feature_usage_statistics_$dbname");
 	  } else {
            move("$scr_orig.out", "$scr_orig.html") if ($htmlscript eq "yes");
          }
        } # End foreach my $scr sql_scripts
      } #End if exists param mapping
    } #End for each database
  } #End if dbscripts or sqlscripts

  # ######################################
  #              OSCP section
  # ######################################
  #if ( @oscp_files )
  #{
  #      # ##############################
  #      foreach my $file (@oscp_files) {
  #        copy($file,".");
  #        print LOG localtime(time) . " : Executing OSCP for file $file\n";
  #      }
  #}

  print LOG localtime(time) . ": Starting collect components by action\n";

  if ( -e "$cxml" )
  {
    my $run_this_comp = 0;
    my $scr = "";
    my $scr_short = "";
    my $runuser = "";
    my @args = ();
    my $args = ();
    my $runon = ();

    my $intp = "";

    open(CRF, "$cxml");
    while(<CRF>)
    {
      chomp;
      if ( /<name>(\w+)<\/name>/ )
      {
        my $c = lc($1);
        $run_this_comp = 0;
        if ( exists $comps{$c} )
        {
          $run_this_comp = 1;
        }
      } elsif ( $run_this_comp == 1 )
      {
        if ( /<script name=\"([^\"]+)\">/ )
        {
          $scr = catfile($tfa_home, "bin", "scripts", $1);
          $scr_short = $1;
          $intp = "$PERL" if ( $1 =~ /\.pl/ );
          $runuser = "";
          $runon = "";
          @args = ();
          $args = ();
        }
         elsif ( /<runuser>(\w+)</ )
        {
          $runuser = $1;
        }
         elsif ( /<requiresdbuser>(\w+)</ )
        {
          $runuser = $ENV{"TFA_ORACLE_USER"} if ( $1 eq "true" );
        }
         elsif ( /<requiresdb>(\w+)</ )
        {
          $runon = "db" if ( $1 eq "true" );
        }
         elsif ( /<interpreter>(.*)<\/interpreter/ )
        {
          $intp = $1 if ( -e $1 );
        }
         elsif ( /<parameter>(\w+)</ )
        {
          if ( exists $param_mapping{$1} )
          {
            push @args, "-$1";
            push @args, $param_mapping{$1} if ( $param_mapping{$1} ne "null");
            $args .= " -$1 ";
            $args .= " \"" . $param_mapping{$1} ."\"" if ( $param_mapping{$1} ne "null");
          } else {
            push @args, "-$1";
            $args .= " -$1";
          }
        }
        elsif ( /<\/script>/ )
        {
          if ( $runon eq "db" )
          {
            print LOG localtime(time) .  " : executing $scr on db \n\n";
            foreach my $dbname (split(/,/, $database))
            {
              if ( exists $param_mapping{"$dbname-ORACLE_HOME"} )
              {
                $args =~ s/_ORACLE_HOME2REPLACE_/$param_mapping{"$dbname-ORACLE_HOME"}/g;
                $args =~ s/_ORACLE_SID2REPLACE_/$param_mapping{"$dbname-ORACLE_SID"}/g;
                $args =~ s/_ORACLE_USER2REPLACE_/$param_mapping{"$dbname-OUSER"}/g;
                print LOG localtime(time) . " : Started executing $intp $scr as $runuser on ".$param_mapping{"$dbname-ORACLE_SID"} ." with $args\n\n";
                $command = "$intp $scr $args";
		osutils_runtimedcommand($command,1800,FALSE,\*LOG);
                print LOG localtime(time) . " : Finished executing $scr\n\n";
              }
               else
              {
                print LOG localtime(time) . " : Skipping $dbname\n";
              }
            }
          }
           else
          {
            #replace any other mappings that may be required.
            $args =~ s/_ORACLE_CRSHOME2REPLACE_/$crshome/g if ($crshome);

            print LOG localtime(time) . " : Started executing $scr as $runuser with $args\n\n";
            $command ="$intp $scr $args";
	    osutils_runtimedcommand($command,1800,FALSE,\*LOG);
            print LOG localtime(time) . " : Finished executing $scr\n\n";
          }
        }
      }
    }
    close(CRF);
  }
}

sub convert_time_for_srdc {
my $intime = shift;
my $type = shift;
print LOG localtime(time) .  " : intime passed $intime \n";
$intime =~ s/\"//g;
if ( $intime =~ /[a-zA-Z]{3}\/\d{1,2}\/\d{4}/)
   {
     my $intime_timeuts = getTimeForDate($intime);
     $intime = strftime "%Y-%m-%d %H:%M:%S", localtime $intime_timeuts;
     print LOG localtime(time) .  " :Converted $type to $intime\n";
  }
print LOG localtime(time) .  " : intime returned $intime \n";
return $intime
}

sub get_version_number {
  my $version = shift;
  $version =~ s/\.//g;
  my $y = $version;
  
  my $count = 0;
  $version = int($version / 10);

  while($version != 0) {
    $count++;
    $version = int($version / 10);
  }
  
  $count = 5 - $count;
  my $retNumber = $y * (10**$count);

  return $retNumber;
}

