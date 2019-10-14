# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/odadom0collect.pl /main/3 2017/08/11 05:02:21 llakkana Exp $
#
# odadom0collect.pl
# 
# Copyright (c) 2015, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      odadom0collect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    manuegar    07/05/17 - Bug 25536278 - LNX64-121-CMT: NEED AN ALL-IN-ONE
#                           SCRIPT TO COLLECT ODA AND ODALITE LOGS FOR SR.
#    bburton     03/03/15 - This script runs on ODA Dom0 to run extra commands
#                           for diagnostic use.
#    bburton     03/03/15 - Creation
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

open (LOG2, '>', $hostname . "_odaDom0Collect.log");
print LOG2 localtime(time) . ": Running ODA Dom0 collection scripts for TFA \n";
print LOG2 "hostname: $hostname\n";
print LOG2 "osname: $osname\n";

if ($osname eq "Linux" && $IS_ODADom0) {
   print LOG2 localtime(time) . " : Running on Linux and This is an ODADom0\n";
} else {
   print LOG2 localtime(time) . " : Not a Linux system or Not an ODADom0- exiting\n";
   exit 0;
}

open (*STDERR, '>', $hostname . "_odaDom0Collect.err");
open (*STDOUT, '>', $hostname . "_odaDom0Collect.out");

osutils_runtimedcommand("xm list > $hostname"."_XMLIST",10,FALSE,\*LOG2);
osutils_runtimedcommand("xm list -l >> $hostname"."_XMLIST",10,FALSE,\*LOG2);
osutils_runtimedcommand("xm info >> $hostname"."_XMINFO",10,FALSE,\*LOG2);
osutils_runtimedcommand("ls -al /etc/xen/auto > $hostname"."_XENAUTO",10,FALSE,\*LOG2);
osutils_runtimedcommand("mount > $hostname"."_MOUNT",10,FALSE,\*LOG2);
osutils_runtimedcommand("df -k > $hostname"."_DF",10,FALSE,\*LOG2);

# Collect the VM configuration information.
my $vmconfout="$hostname" . "_VMGUESTCONFIGS";
my $vmdir="/OVS/Repositories";
my $topdir;
my $dirfile;
my $infofile;
my $fulldir;
my $openok =  opendir(my $dir, $vmdir);
#Only try to open directory if it exists
if ( -d $vmdir ) {
  open(WF, ">$vmconfout");
  # For each directory under /OVS/Repositories look for cfg files and oakres.xml
  find(\&wanted,$vmdir);
  close(WF);
}

close(LOG2);
close(*STDERR);
close(*STDOUT);

sub wanted {
  if ( -d "$File::Find::name/.ACFS/snaps") {
     find(\&wanted,"$File::Find::name/.ACFS/snaps");
  } else {
    if ( /\.(conf|cfg|xml)/) {
        print LOG2 localtime(time) . ": Collecting $File::Find::name into $vmconfout\n";
        print WF "## File: $File::Find::name  \n";
  
        open (RF, "$File::Find::name") or die "cannot open $File::Find::name  : $!";;
        while(<RF>) {
          chomp();
          print WF "$_\n";
        }
        close(RF);
    }
  }
}
