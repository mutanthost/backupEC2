#!/usr/bin/perl
# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/odaprovisioningcollect.pl /main/1 2018/07/17 04:50:46 bburton Exp $
#
# odaprovisioningcollect.pl
# 
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      odaprovisioningcollect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     06/20/18 - Collect Logs relevant to diagnose issues with ODA
#                           DCS Provisioning.
#    bburton     06/20/18 - Creation
# 
#####
use strict;
use English;
use File::Basename;
use File::Spec::Functions;
use File::Copy;
use Time::Local;
use Term::ANSIColor;
use Cwd;
use POSIX;

use Getopt::Long qw(:config no_auto_abbrev);

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME).'/..';
  push @INC, dirname($PROGRAM_NAME).'/../common';
  push @INC, dirname($PROGRAM_NAME).'/../modules';
  push @INC, dirname($PROGRAM_NAME).'/../common/exceptions';
}

use constant ERROR                     => "-1"; 
use constant FAILED                    =>  "0";  
use constant SUCCESS                   =>  "1";  
use constant TRUE                      =>  "1";
use constant FALSE                     =>  "0";

use tfactlglobal;
use tfactlshare;
use tfactlwin;
use collection;
use cmdlocation;

# Set up local variables

local *STDOUT;
local *STDERR;


my $hostname;
my $osname = `uname`;
chomp($osname);
my $date = `date`;
chomp($date);

GetOptions (
            'hostname=s' => \$hostname
             );

#Open a log file for this collection script to write to
open (STDOUT, '>', $hostname . "_odaprovisioning_collect.log");
print localtime(time) . ": Running ODA PROVISIONING Component collection scripts for TFA \n";
print "Hostname: $hostname\n";
print "osname: $osname\n";

if ($osname eq "Linux" && $IS_ODALITE) {
   print  localtime(time) . " : Running on Linux and This is an ODALITE type $ODALITE_TYPE\n";
} else {
   print  localtime(time) . " : Not a Linux system or Not an ODA Lite- exiting\n";
   exit 0;
}

open (STDERR, '>', $hostname . "_odaprovisioning_collect.err");

#   Reading asmnit data from /tmp
my $outfile = $hostname . "_TMP_ASMINIT_DATA";
my $procdir="/tmp";
my $openok =  opendir(my $dir, $procdir);
my $dirfile;
my $infofile;

if ( -d $procdir ) {
  if ( $openok ) {
    my @files = readdir $dir;
    closedir $dir;

    open(WF, ">$outfile");
    print WF "### Contents of /tmp/asminit* at $date ###\n";

    foreach $dirfile (@files) {
      #Make sure it is a non symbolic file 
      if ( -f $dirfile && ! -l $dirfile && 
	   $dirfile =~ /asminit.*/ ) {
        $infofile = catfile($procdir,$dirfile);
        print localtime(time) . ": Collecting $infofile into $outfile\n";

        print WF "\n####### $infofile ########\n";
        $openok = open (RF, "$infofile");
        if ($openok) {
          print localtime(time) . ": Opened file $infofile for read\n";
          while(<RF>) {
            chomp();
            print WF "$_\n";
          }
          close(RF);
        }
        else {
          print localtime(time) . ": Failed to open file $infofile for read\n";
        }
      }
    }
    close(WF);
  }
} else {
  print localtime(time) . ": Failed to open directory $procdir for read\n";
}
$outfile = $hostname . "_VMDB_SETUPENV";
collection_copy(catfile("","var","log","vmdb_setupenv.out"),$outfile);
$outfile = $hostname . "_SETUPNETWORK_LOG";
collection_copy(catfile("","root","setupnetwork.log"),$outfile);

print localtime(time) . ": Completed Running odaprovisioningcollect.pl for TFA \n";
close(*STDERR);
close(*STDOUT);
