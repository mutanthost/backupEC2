#!/usr/local/bin/perl
# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/dcslogscollect.pl /main/1 2018/07/17 04:50:46 bburton Exp $
#
# dcscollect.pl
# 
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      dcslogscollect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     01/10/18 - Collection script for DatabaseCloudService Base
#                           Logs
#    bburton     01/10/18 - Creation
# 
#####
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

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME).'/..';
  push @INC, dirname($PROGRAM_NAME).'/../common';
  push @INC, dirname($PROGRAM_NAME).'/../modules';
  push @INC, dirname($PROGRAM_NAME).'/../common/exceptions';
  }

use tfactlglobal;
use osutils;

use constant TRUE                      =>  "1";
use constant FALSE                     =>  "0";

my $hostname;
my $osname = `uname`;
chomp($osname);

GetOptions (
            'hostname=s' => \$hostname
             );

open (LOG2, '>', $hostname . "_dcslogs_collect.log");
print LOG2 localtime(time) . ": Running DCS LOGS Ccollection scripts for TFA \n";
print LOG2 "hostname: $hostname\n";
print LOG2 "osname: $osname\n";

if ($osname eq "Linux" && $IS_ODALITE) {
   print LOG2 localtime(time) . " : Running on Linux and This is an ODALITE type $ODALITE_TYPE\n";
} else {
   print LOG2 localtime(time) . " : Not a Linux system or Not an ODA Lite- exiting\n";
   exit 0;
}

open (*STDERR, '>', $hostname . "_dcslogs_collect.err");
open (*STDOUT, '>', $hostname . "_dcslogs_collect.out");

if ( -f "/zookeeper.out" ) {
  osutils_runtimedcommand("cat /zookeeper.out > $hostname"."_ZOOKEEPER_OUT",10,FALSE,\*LOG2);
}
if ( -f "/opt/zookeeper/bin/zookeeper.out" ) {
  osutils_runtimedcommand("cat /opt/zookeeper/bin/zookeeper.out > $hostname"."_BIN_ZOOKEEPER_OUT",10,FALSE,\*LOG2);
}
print LOG2 localtime(time) . ": Completed Running dcslogscollect.pl for TFA \n";
close(LOG2);
close(*STDERR);
close(*STDOUT);
