#!/usr/bin/perl
# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/dcsconfigcollect.pl /main/1 2018/07/17 04:50:46 bburton Exp $
#
# dcsconfigcollect.pl
# 
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      dcsconfigcollect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     01/12/18 - Script to collect dcs config data
#    bburton     01/12/18 - Creation
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
use osutils;

# Set up local variables

local *STDOUT;
local *STDERR;


my $hostname;
my $osname = `uname`;
chomp($osname);

GetOptions (
            'hostname=s' => \$hostname
             );

#Open a log file for this collection script to write to
open (STDOUT, '>', $hostname . "_odaconfig.log");
print localtime(time) . ": Running DCSCONFIG Component collection scripts for TFA \n";
print "Hostname: $hostname\n";
print "osname: $osname\n";

if ($osname eq "Linux" && $IS_ODALITE) {
   print  localtime(time) . " : Running on Linux and This is an ODALITE type $ODALITE_TYPE\n";
} else {
   print  localtime(time) . " : Not a Linux system or Not an ODA Lite- exiting\n";
   exit 0;
}

open (STDERR, '>', $hostname . "_odaconfig.err");
open (REP, '>', $hostname . "_odaconfig");

#set up command variables

my $CAT;
my $FIND; 

$CAT = cmdlocation_get("cat");
$FIND = cmdlocation_get("find");

my $outfile = $hostname . "_UDEV_RULES";
osutils_runtimedcommand("$FIND /etc/udev/rules.d -type f -print -exec $CAT {} \\; > $outfile",10,FALSE,\*STDOUT);
my $outfile = $hostname . "_DCS_CONFIG_JSON";
osutils_runtimedcommand("$FIND /opt/oracle/dcs/conf -type f -name '*.json' -print -exec $CAT {} \\; > $outfile",10,FALSE,\*STDOUT);
$outfile = $hostname . "_DCS_DCSCLI_CONF";
osutils_runtimedcommand("$FIND /opt/oracle/dcs/dcscli -type f -name '*.conf' -print -exec $CAT {} \\; > $outfile",10,FALSE,\*STDOUT);
$outfile = $hostname . "_DCS_ASMAPPL.CONFIG";
osutils_runtimedcommand("$CAT /opt/oracle/extapi/asmappl.config > $outfile",10,FALSE,\*STDOUT);


print localtime(time) . ": Completed Running ODACONFIG Component collection scripts for TFA \n";
