#!/usr/bin/perl
# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/chacollect.pl /main/1 2018/05/28 15:06:27 bburton Exp $
#
# chacollect.pl
# 
# Copyright (c) 2017, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      chacollect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      The script should run on systems where GI 12.2 or greater are installed.
#      It will gather CHA repository in mdb format for the time period requested and move the generated file to the collection directory.
#      Finally it will gather any diagnosis data for the requested time period.
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     05/10/18 - increase timeout as the cha export and diagnosis
#                           can take more time
#    bburton     07/10/17 - Perl driver for Cluster Health Analyzer diagnostic
#                           data collection.
#    bburton     07/10/17 - Creation
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
use POSIX;

BEGIN {
  #Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME).'/..';
  push @INC, dirname($PROGRAM_NAME).'/../common';
  push @INC, dirname($PROGRAM_NAME).'/../modules';
  push @INC, dirname($PROGRAM_NAME).'/../common/exceptions';
}

use collection;
use osutils;
use tfactlshare;

if ( $^O eq "MSWin32" )
{
  eval q{use base 'Win32'; 1} or die $@;
}
use Getopt::Long qw(:config no_auto_abbrev);


# Set up local variables
my $hostname;
my $crshome;
my $tfahome;
my $command;
my $from;
my $to;
my $repository=getcwd();

my $IS_WINDOWS;
my $IS_SOLARIS;
my $chadumpfile;

if ( $^O eq "MSWin32" ) {
  $IS_WINDOWS = 1;
}
if ( $^O eq "solaris" ) {
  $IS_SOLARIS = 1; 
}

# Parse command line args

GetOptions('crshome=s'    => \$crshome,
           'from=s' => \$from,
           'to=s' => \$to,
           'hostname=s'    => \$hostname);

if(@ARGV) {
  
   exit(1);
}

my $scan_name;
my $output_file;

#Open a log file for this collection script to write to
open (*STDOUT, '>', $hostname . "_cha_collection.log");
open (*STDERR, '>', $hostname . "_cha_collection.err");
print localtime(time) . ": Running CHA collection scripts for TFA \n";
print "hostname: $hostname\n";
print "crshome: $crshome\n";
print "from: $from\n";
print "to: $to\n";

if (!$crshome) {
    print localtime(time) . ": CRS Home Not Specified : Not running CHA collections.\n";
    exit(1);
} else {
my $crsbindir = catfile ($crshome,"bin");

#TODO : DO not use a file here
$command = catfile ($crsbindir,"crsctl");
osutils_runtimedcommand("$command query crs activeversion > avtemp",20,FALSE,\*STDOUT);
# Check the CRS ACTIVE VERSION.
# If there is no CRS ACTIVE VERSION then do not run all the CRS file gets 
my $activeversion="0";
open (AV,"avtemp") or $activeversion = "0";
while (<AV>) {
   if (/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/) {
       $activeversion = $&;
       print localtime(time) . ": CRS ACTIVE VERSION is $activeversion\n";
   }
}
close(AV);
unlink("avtemp");

$command = catfile ($crsbindir,"chactl");

if ( $activeversion > 0 ) { # Only run these commands if active version was found.
   $activeversion =~ s/\.//g;
   print localtime(time) . ": CRS ACTIVE VERSION numeric $activeversion\n";
   my $activeversion4 = substr($activeversion,0,4);
   print localtime(time) . ": CRS ACTIVE VERSION substr $activeversion4\n";
   if ( $activeversion4 gt 1210 ) {
      print "\n".localtime(time) . ": Running Commands for 12cR2 and above installations\n";
      $command = catfile ($crsbindir,"chactl");

      # convert the date for file string
      my ($datef,$timef) = split (" ",$from);
      $datef =~ s/\-//g;
      $timef =~ s/\://g; 
      my ($datet,$timet) = split (" ",$to);
      $datet =~ s/\-//g;
      $timet =~ s/\://g; 
      # Gather the CHA repository in MDB format - parse the output file from output and move to collection.
      my @out = osutils_runtimedcommand("$command export repository -format mdb -start \"$from\" -end \"$to\"",300,TRUE,\*STDOUT);
      foreach my $line(@out) {
         print localtime(time) . " Output from chactl export repo : $line\n";
         if ( $line =~ /successfully dumped the CHA statistics to location(.*)/ ) {
            $chadumpfile = $1;
            $chadumpfile =~ s/\"//g;
            $chadumpfile =~ s/\s//g;
            chomp($chadumpfile);
            print localtime(time) . " Moving file $chadumpfile to $repository\n";
            move($chadumpfile,$repository); 
         } else {
            print localtime(time) . " failed to extract cha dump file from chactl command\n";
         }
      }
      # Gather any incident diagnosis from CHA for the time period with output to CWD
      osutils_runtimedcommand("$command query diagnosis -start \"$from\" -end \"$to\" > cha_diag_$datef"."_$timef"."_$datet"."_$timet.txt",300,FALSE,\*STDOUT);
   } else { # End of only run commands if active versionigreater than 12.1.
      print localtime(time) . ": CRS Active Version Less than 12.2 - No CHA Available\n";
   }
} 
else { # End of only run commands whe we have an active version.
   print localtime(time) . ": No CRS Active Version Found\n";
}
# End of collecting CHA related data .

} # End of only run if crshome is set.

print localtime(time) . ": Completed collecting CHA Specific Data \n";
