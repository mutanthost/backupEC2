#!/usr/bin/perl
# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/odacollect.pl /main/1 2017/07/13 09:00:08 manuegar Exp $
#
# odacollect.pl
# 
# Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      odacollect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    manuegar    07/05/17 - Creation
# 
#####################################################################
#

use warnings;
use strict;
use File::Copy;
use File::Path;
use File::Find;
use File::Basename;
use File::Spec::Functions;
use Getopt::Long;
use English;
use Time::Local;
use Cwd;
use POSIX;
use constant ERROR                     => "-1"; 
use constant FAILED                    =>  "0";  
use constant SUCCESS                   =>  "1";  
use constant TRUE                      =>  "1";
use constant FALSE                     =>  "0";

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME).'/..';
  push @INC, dirname($PROGRAM_NAME).'/../common';
  push @INC, dirname($PROGRAM_NAME).'/../modules';
  push @INC, dirname($PROGRAM_NAME).'/../common/exceptions';
  }

use tfactlglobal;
use osutils;

my $hostname;
my $osname = `uname`;
chomp($osname);
my $command;

GetOptions ('hostname=s' => \$hostname);

open (LOG2, '>', $hostname . "_odacollection.log");
print LOG2 localtime(time) . ": Running ODA Specific Commands collection scripts for TFA \n";
print LOG2 "hostname: $hostname\n";
print LOG2 "osname: $osname\n";

if ($osname eq "Linux" && $IS_ODA) {
   print LOG2 localtime(time) . " : Running on Linux and This is an ODA\n";
} else {
   print LOG2 localtime(time) . " : Not a Linux system or Not an ODA- exiting\n";
   exit 0;
}

open (*STDERR, '>', $hostname . "_odacollection.err");
open (*STDOUT, '>', $hostname . "_odacollection.out");

my $oakcli = catfile ("","opt","oracle","oak","bin","oakcli");
my $odaadmcli = catfile ("","opt","oracle","oak","bin","odaadmcli");
my $lsiutil = catfile ("","opt","oracle","oak","bin","lsiutil");
my $rpmoda = "";
my $odaversion = "2.6";
# odaversion = a.b.c.d.e
# a.b.c.d.e = 12.1.2.11.0
# a = 12, b = 1, c = 2, d = 11 & e = 0
my $aversion = "2";
my $bversion = "6";
my $minversion = FALSE;

# Get ODA version
$rpmoda = `rpm -qa|grep oak`;
chomp($rpmoda);
if ( $rpmoda =~ /oak-(.*?)_.*/ ) {
  $odaversion = $1; 
  if ( $odaversion =~ /([0-9]+)\.([0-9]+)\..*/ ) {
    $aversion = $1;
    $bversion = $2;
    if ( ($aversion == 2 && $bversion >= 7 ) ||
         ($aversion > 2 ) ) {
      $minversion = TRUE; # ODA version >= 2.7
    }
  }
}
#print "ODA version = $odaversion, aversion = $aversion, bversion = $bversion, minversion = $minversion\n";

if ( -f $oakcli ) {
  osutils_runtimedcommand("$oakcli show disk > $hostname"."_OAKCLISHOWDISK",60,FALSE,\*LOG2);
  osutils_runtimedcommand("$oakcli show env_hw > $hostname"."_OAKCLISHOWENVHW",10,FALSE,\*LOG2) if $minversion;
}    

if ( -f $odaadmcli ) {
  osutils_runtimedcommand("$odaadmcli show disk > $hostname"."_OAKCLISHOWDISK",60,FALSE,\*LOG2);
}

osutils_runtimedcommand("echo \"$rpmoda\" > $hostname"."_RPMOAK",10,FALSE,\*LOG2);
osutils_runtimedcommand("echo $odaversion > $hostname"."_ODAVERSION",10,FALSE,\*LOG2);

if ( not $minversion ) {
  osutils_runtimedcommand("lsmod|grep net > $hostname"."_LSMODNET",10,FALSE,\*LOG2);
  osutils_runtimedcommand("/usr/bin/ipmitool fru 2>&1 > $hostname"."_IPMITOOLFRU",10,FALSE,\*LOG2);
}

osutils_runtimedcommand("ls -al /dev/mapper > $hostname"."_DEVMAPPERDIR",10,FALSE,\*LOG2);
osutils_runtimedcommand("multipath -ll > $hostname"."_MULTIPATH",10,FALSE,\*LOG2);
osutils_runtimedcommand("fwupdate list disk > $hostname"."_FWUPDATE",10,FALSE,\*LOG2);
osutils_runtimedcommand("lspci > $hostname"."_LSPCI",10,FALSE,\*LOG2);
osutils_runtimedcommand("lsscsi -lg > $hostname"."_LSSCSI",10,FALSE,\*LOG2);

print LOG2 localtime(time) . ": Finished Running ODA Specific Commands collection scripts for TFA\n";

close(LOG2);
close(*STDERR);
close(*STDOUT);
