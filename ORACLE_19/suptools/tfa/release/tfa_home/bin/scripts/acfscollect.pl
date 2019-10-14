# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/acfscollect.pl /main/4 2018/05/28 15:06:27 bburton Exp $
#
# acfscollect.pl
# 
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      acfscollect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     11/01/17 - Add get_acfs_info.sh short term for Linux only
#    bburton     05/04/16 - Script to gather specific acfs data
#    bburton     05/04/16 - Creation
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

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME).'/..';
  push @INC, dirname($PROGRAM_NAME).'/../common';
  push @INC, dirname($PROGRAM_NAME).'/../modules';
  push @INC, dirname($PROGRAM_NAME).'/../common/exceptions';
}

use tfactlglobal;
use cmdlocation;


use Getopt::Long qw(:config no_auto_abbrev);


# Set up local variables
my $PLATFORM = $^O;
my $hostname;
my $crshome;
my $tfahome;
my $command;
my $crsbindir;
my $UNAME;

# setup Variables for Commands..
my $ACFSUTIL = cmdlocation_get("acfsutil");

# Parse command line args

GetOptions('crshome=s'    => \$crshome,
           'hostname=s'    => \$hostname);

if(@ARGV) {
   print "\nInvalid Options specified: @ARGV\n";
   exit(1);
}

#Open a log file for this collection script to write to
open (LOG2, '>', $hostname . "_acfs_collection.log");
open (*STDERR, '>', $hostname . "_acfs_collection.err");
open (*STDOUT, '>', $hostname . "_acfs_report");
print LOG2 localtime(time) . ": Running ACFS collection scripts for TFA \n";
print LOG2 "hostname: $hostname\n";
print LOG2 "crshome: $crshome\n";

if (!$crshome) {
    print LOG2 localtime(time) . ": CRS Home Not Specified Exiting.\n";
    exit(1);
} elsif (! -d $crshome ) {
    print LOG2 localtime(time) . ": CRS Home $crshome  does not exist.\n";
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

#Get acfsutil data
if ( -e $ACFSUTIL ) {
   runtimedcommand("$ACFSUTIL registry > $hostname"."_ACFSREGISTRY");
   runtimedcommand("$ACFSUTIL info fs > $hostname"."_ACFSINFOFS");
   runtimedcommand("$ACFSUTIL log");
   move("oks.log","$hostname"."_ACFSUTILLOG") if -e "oks.log"  
}

# Get tunables file  contents.
my @tunablesarray;
push (@tunablesarray,"acfstunables");
push (@tunablesarray,"advmtunables");
foreach my $tunfile (@tunablesarray) {
    print "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n";
    my $tunables = catfile($crshome,"acfs","tunables",$tunfile);
    my $desc = "Contents of $tunfile";
    my $command = "$CAT $tunables";
    if ( -e $tunables  ) {
       print "$desc :  \n\n";
       runtimedcommand($command);
    } else {
       print "$tunables not found on this system";
    }
    print "\n";
}  

# Run get_acfs_info.sh if Linux
if ( $PLATFORM eq "linux" ) {
    my $command = "get_acfs_info.sh";
    runtimedcommand($command,60);
}

#Close files
close(LOG2);
close(*STDERR);
close(*STDOUT);

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
