#!/usr/bin/perl
# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/odastoragecollect.pl /main/1 2017/07/13 09:00:08 manuegar Exp $
#
# odastoragecollect.pl
# 
# Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      odastoragecollect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    manuegar    07/06/17 - Creation
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

open (LOG2, '>', $hostname . "_odastoragecollection.log");
print LOG2 localtime(time) . ": Running ODASTORAGE Specific Commands\n";
print LOG2 "hostname: $hostname\n";
print LOG2 "osname: $osname\n";

if ($osname eq "Linux" && $IS_ODA) {
   print LOG2 localtime(time) . " : Running on Linux and This is an ODA\n";
} else {
   print LOG2 localtime(time) . " : Not a Linux system or Not an ODA- exiting ODASTORAGE Specific Commands\n";
   exit 0;
}

open (*STDERR, '>', $hostname . "_odastoragecollection.err");
open (*STDOUT, '>', $hostname . "_odastoragecollection.out");

my $oakcli = catfile ("","opt","oracle","oak","bin","oakcli");
my $odaadmcli = catfile ("","opt","oracle","oak","bin","odaadmcli");
my $lsiutil = catfile ("","opt","oracle","oak","bin","lsiutil");

osutils_runtimedcommand("$lsiutil -s > $hostname"."_LSIUTIL",300,FALSE,\*LOG2);
if ( -f $oakcli ) { 
  osutils_runtimedcommand("$oakcli validate -d > $hostname"."_OAKCLIVALIDATE",300,FALSE,\*LOG2);
}

# Now we have to detemine the generated log if any add that here
open (OP,$hostname."_OAKCLIVALIDATE") ;
while (<OP>) {
   if (/(.*Storage Topology.*file=)(.*)/) {
     print LOG2 localtime(time) . ": Collecting $2\n";
     copy ( $2,"." );
   }    
}    
close(OP);
print LOG2 localtime(time) . ": Finished Running ODASTORAGE Specific Commands\n";

close(LOG2);
close(*STDERR);
close(*STDOUT);
