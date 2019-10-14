# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/afdcollect.pl /main/5 2018/05/28 15:06:27 bburton Exp $
#
# afdcollect.pl
# 
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      afdcollect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     03/05/18 - XbranchMerge bburton_tfa_122131_fixes_txn from
#                           st_tfa_12.2.1.3.1
#    bburton     12/12/17 - asmcmd must run as grid user
#    llakkana    05/04/17 - Update afdtool -KSTATE command
#    bburton     04/28/16 - Driver to collect non trace file data for AFD
#                           collections.
#    bburton     04/28/16 - Creation
# 
######################################
#
use strict;
use English;
use File::Basename;
use File::Spec::Functions;
use File::Copy;
use Time::Local;
use Term::ANSIColor;
use Cwd;
use POSIX;
use constant TRUE                      =>  "1";
use constant FALSE                     =>  "0";


use Getopt::Long qw(:config no_auto_abbrev);

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME).'/..';
  push @INC, dirname($PROGRAM_NAME).'/../common';
  push @INC, dirname($PROGRAM_NAME).'/../modules';
  push @INC, dirname($PROGRAM_NAME).'/../common/exceptions';
}

use dbutil;
use cmdlocation;

# Set up local variables
my $PLATFORM = $^O;
my $IS_WINDOWS;
if ( $PLATFORM eq "MSWin32" ) {
   $IS_WINDOWS = 1;
}
my $SU = cmdlocation_get("su");
my $hostname;
my $crshome;
my $tfahome;
my $command;
my $crsbindir;
my $UNAME;

# Parse command line args

GetOptions('crshome=s'    => \$crshome,
           'hostname=s'    => \$hostname,
           'tfahome=s'    => \$tfahome);

if(@ARGV) {
   print "\nInvalid Options specified: @ARGV\n";
   exit(1);
}

#Open a log file for this collection script to write to
open (LOG2, '>', $hostname . "_afd_collection.log");
open (*STDERR, '>', $hostname . "_afd_collection.err");
open (*STDOUT, '>', $hostname . "_afd_report");
print LOG2 localtime(time) . ": Running AFD collection scripts for TFA \n";
print LOG2 "hostname: $hostname\n";
print LOG2 "crshome: $crshome\n";
print LOG2 "tfahome: $tfahome\n";

if ( !($PLATFORM eq "linux" || $PLATFORM eq "solaris")) {
   print LOG2 localtime(time) . ": AFD Collection is on Supported on Solaris and Linux not $PLATFORM";
   exit(1);
}
if (!$crshome) {
    print LOG2 localtime(time) . ": CRS Home Not Specified Exiting.\n";
    exit(1);
} else {
    $crsbindir = catfile ($crshome,"bin");
}

# Get ORACLE_BASE using $crs_home/bin/orabase
my $cmdFile = catfile($crshome,"bin","orabase");
$ENV{ORACLE_HOME}=$crshome;
my $ORACLE_BASE = qx($cmdFile);
chomp($ORACLE_BASE);
print LOG2 localtime(time) . ": CRS Base Dir : $ORACLE_BASE\n";

# need to run asmcmd with ENV set and as grid user
my $filename = catfile($crshome,"bin","oracle");
my $ownerid;
my $crsowner;
if (! $IS_WINDOWS ) {
  #Get crsowner
  $ownerid = (stat $filename)[4];
  $crsowner = (getpwuid $ownerid)[0];
}
my $retval = dbutil_setOraEnv($tfahome,"+ASM",\*LOG2,TRUE);

if ( $retval ne 0 ){
  print LOG2 localtime(time) ." ASM database was not found or is not running locally exiting...\n";
  exit(1);
}

print LOG2 localtime(time) . ": Running ASM Configuration script for TFA\n";
print LOG2 localtime(time) . ": crshome  => $crshome\n";
print LOG2 localtime(time) . ": crsowner => $crsowner\n";
print LOG2 localtime(time) . ": ORACLE_HOME =>  ".$ENV{"ORACLE_HOME"}."\n";
print LOG2 localtime(time) . ": ORACLE_SID =>   ".$ENV{"ORACLE_SID"}."\n";


# Commands ..
my $ZIP = catfile($crshome,"bin","zip");
my $FIND = catfile("","usr","bin","find");
if ( $PLATFORM eq "linux" ) {
   $UNAME = catfile("","bin","uname");
   
} else {
   $UNAME = catfile("","usr","bin","uname");
}

# Get uname -a ( also collected on O/S ) 
   $command = "$UNAME -a";
   print "\nOutput From Command : $command\n\n";
   runtimedcommand($command);
   print "\n";

# Get permissions of /dev/oracleafd/admin
my $devafdfile = catfile("","dev","oracleafd","admin");
if ( -e $devafdfile ) { 
   $command = "/bin/ls -l $devafdfile ";
   print "\nOutput From Command : $command\n\n";
   runtimedcommand($command);
   print "\n";
} 
# Take a copy of oracleafd.conf
my $oracleafdconf = catfile("","etc","oracleafd.conf");
if ( -e $oracleafdconf ) {
   print LOG2 localtime(time) . ": Copying $oracleafdconf to $hostname"."_ORACLEAFD_CONF\n";
   copy($oracleafdconf,"$hostname"."_ORACLEAFD_CONF");
}
# Get a directory listing of oracleafd/disks
my $oracleafddisks;
if ( $PLATFORM eq "linux" ) {
   $oracleafddisks = catfile("","dev","oracleafd","disks")
} else {
   $oracleafddisks = catfile("","var","opt","oracle","oracleafd","disks");
}
if ( -d $oracleafddisks ) {
   $command = "/bin/ls -al $oracleafddisks";
   print "\nOutput From Command : $command\n\n";
   runtimedcommand($command);
   print "\n";
}

# Get asmcmd afd_lsdsk
my $asmcmd = catfile($crsbindir,"asmcmd");
$command = checksu($crsowner,"$asmcmd afd_lsdsk");
print "\nOutput From Command : $command\n\n";
runtimedcommand($command);
print "\n";
# Get asmcmd afd_dsget
$command = checksu($crsowner,"$asmcmd afd_dsget");
print "\nOutput From Command : $command\n\n";
runtimedcommand($command);
print "\n";

# Get afdtool -log -q
my $afdtool = catfile($crsbindir,"afdtool");
$command = "$afdtool -log -q";
print "\nOutput From Command : $command\n\n";
runtimedcommand($command);
print "\n";
# Get afdtool -getdevlist -di
$command = "$afdtool -getdevlist -di";
print "\nOutput From Command : $command\n\n";
runtimedcommand($command);
print "\n";
# Get afdtool -getdevlist -tp
$command = "$afdtool -getdevlist -tp";
print "\nOutput From Command : $command\n\n";
runtimedcommand($command);
print "\n";
# Get afdtool -kstate -all
$command = "$afdtool -kstate -all -file $hostname\_AFDTOOL_KSTATE";
print LOG2 localtime(time) . ": Collecting output of \"afdtool -kstate -all\" to $hostname\_AFDTOOL_KSTATE\n\n";
runtimedcommand($command);
print "\n";
my $afddir = catdir($ORACLE_BASE,"crsdata",$hostname,"afd");
my $afdzipdir = "crsdata_afd";
mkdir ($afdzipdir);
my $afdzip = catfile($afdzipdir,"crsdata_afd.zip");
print "\n Collecting afd logs following kstate -all\n\n";
print "Collecting from $afddir to $afdzip\n";
$command = "$FIND $afddir -cmin -10 | $ZIP -j -r $afdzip -@";
runtimedcommand($command);

# Get acfsdriverstate supported
my $acfsdriverstate = catfile($crsbindir,"acfsdriverstate");
$command = "$acfsdriverstate supported";
print "\nOutput From Command : $command\n\n";
runtimedcommand($command);
print "\n";
# Get acfsdriverstate installed
$command = "$acfsdriverstate installed";
print "\nOutput From Command : $command\n\n";
runtimedcommand($command);
print "\n";
# Get acfsdriverstate loaded
$command = "$acfsdriverstate loaded";
print "\nOutput From Command : $command\n\n";
runtimedcommand($command);
print "\n";

# Get afdroot version_check
my $afdroot = catfile($crsbindir,"afdroot");
$command = "$afdroot version_check";
print "\nOutput From Command : $command\n\n";
runtimedcommand($command);
print "\n";

sub runtimedcommand  {
my $command = shift;
my $timeout = shift;
if ( !$timeout ) { $timeout = 10 };
  eval {
      local $SIG{ALRM} = sub { die "Timeout\n" };
      alarm $timeout;
      system($command);
      alarm 0;
  };
  if ($@) {
      print LOG2 localtime(time) . ": $command timed out.\n";
      return(99);
  } elsif ($? != 0) {
      print LOG2 localtime(time) . ": $command failed.\n" ;
      return(1);
  } else {
      print LOG2 localtime(time) . ": $command success.\n" ;
      return(0);
  }
}

sub checksu {
  my $requser    = shift;
  my $cmd        = shift;
  my $IS_WINDOWS = 0;
  my $current_user;
  if ( $^O eq "MSWin32" ) {
    $IS_WINDOWS = 1;
    $current_user = Win32::LoginName();
    if ( Win32::IsAdminUser() ) {
      $current_user = "root";
    }
  } else {
    $current_user = getpwuid($<);
  }

  if ( ($current_user eq "root") && (not $IS_WINDOWS) ) {
    return "$SU $requser -c '" . $cmd . "'";
  } else {
    return $cmd;
  }
}
