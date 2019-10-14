#!/usr/local/bin/perl
# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/cloudmetadatacollect.pl /main/1 2018/05/28 15:06:27 bburton Exp $
#
# cloudmetadatacollect.pl
# 
# Copyright (c) 2017, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      cloudmetadatacollect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#
#  On Bare Metal we can attach to
#      curl http://169.254.169.254/opc/v1/instance/
#      but  http://169.254.169.254/latest gets a 404
#      and  http://192.0.0.192/latest hangs in network timeout.
#  On OPC ( VM ) we can attach to
#      curl http://192.0.0.192/latest or
#      curl http://169.254.169.254/latest
#
#    MODIFIED   (MM/DD/YY)
#    bburton     11/05/17 - Fix url on OPC systems
#    bburton     10/18/17 - Collects Cloud service metadata
#    bburton     10/18/17 - Creation
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

exit 0 if ( $IS_WINDOWS ) ; # No need to even try on windows

my $hostname = `hostname`;
chomp($hostname);
my $osname = `uname`;
chomp($osname);
my $command;

GetOptions ('hostname=s' => \$hostname);

open (LOG2, '>', $hostname . "_cloudmetadata.log");
print LOG2 localtime(time) . ": Running Cloud Metadata collection scripts for TFA \n";
print LOG2 "hostname: $hostname\n";
print LOG2 "osname: $osname\n";

if ($osname eq "Linux" ) { #TODO Work out the Cloud system bit
   print LOG2 localtime(time) . " : Running on Linux\n";
} else {
   print LOG2 localtime(time) . " : Not a Linux system or Not a Cloud System- exiting\n";
   exit 0;
}

open (*STDOUT, '>', $hostname . "_cloudmetadata.out");

my $curlcommand = "curl -s -S --connect-timeout 5 --max-time 10";
my $opcbaseurl = "http://192.0.0.192/latest/";
my %opcmd = ( "Local Hostname"=>"meta-data/local-hostname",
              "Instance ID"=>"meta-data/instance-id",
              "Machine Memory/CPU"=>"meta-data/instance-type",
              "Local IP Address"=>"meta-data/local-ipv4",
              "Nimbula Orchestration" =>"attributes/nimbula_orchestration");
              

my $bmibaseurl = "http://169.254.169.254/opc/v1/instance/";
my $isopc = 0;
my $isbm = 0;

# Check if we are on OPC or BM ..

$command = $curlcommand . " " . $bmibaseurl . " 2>&1";
#print "$command\n";
my @output = osutils_runtimedcommand($command,30,TRUE,\*LOG2);
#my @output = `$command 2>&1`;
#print "@output\n";
foreach my $line (@output) {
  if ( $line =~ /timed out/ or $line =~ /couldn\'t connect to host/ ) {
     print LOG2 localtime(time) . " : Tried $bmibaseurl : failed : $line \n";
     $command = $curlcommand . " " . $opcbaseurl . " 2>&1";
     @output = osutils_runtimedcommand($command,30,TRUE,\*LOG2);
     foreach my $line (@output) {
        if ( $line =~ /timed out/ or $line =~ /couldn\'t connect to host/ ) {
           print LOG2 localtime(time) . " : Not a Cloud System : $line \n";
           close(LOG2);
           exit 0;
        } else {
           $isopc = 1;
           last;
        }
     }
  }  
  if ( $isopc or $line =~ /No such metadata item/ ) {
     $isopc = 1;
     last;
  } else {
     $isbm = 1;
     last;
  }
}
my $instanceid = "";
my $compartmentid = "";
my $displayname = "";
my $availdomain = "";
my $image = "";
my $region = "";
my $shape = "";
my $state = "";

if ( $isbm ) {
   print "Running ON BM\n";
   foreach my $out ( @output )
   {
      chomp($out);
      #print "$out\n";
      $out =~ m/\s*\"(.*)\"\s:\s\"(.*)\".*/;
      $instanceid = $2 if $1 eq "id" ;
      $compartmentid = $2 if $1 eq "compartmentId";
      $displayname = $2 if $1 eq "displayName";
      $availdomain = $2 if $1 eq "availabilityDomain";
      $image = $2 if $1 eq "image";
      $region = $2 if $1 eq "region";
      $shape = $2 if $1 eq "shape";
      $state = $2 if $1 eq "state";
   }
   print "Cloud Type          | Bare Metal\n";
   print "Instance Id         | $instanceid\n";
   print "Compartment Id      | $compartmentid\n";
   print "Display Name        | $displayname\n";
   print "Availability Domain | $availdomain\n";
   print "Image               | $image\n";
   print "Region              | $region\n";
   print "Shape               | $shape\n";
   print "State               | $state\n";
}
if ( $isopc ) {
   print "Running ON OPC\n";
   print "Cloud Type          | OPC\n";
   foreach my $dc ( keys %opcmd )
   {
      my $line = sprintf "%-24s |", $dc;
      #print "$line";
      $command = $curlcommand . " " . $opcbaseurl . $opcmd{$dc};
      #print "$command\n";
      my $out = osutils_runtimedcommand($command,30,TRUE,\*LOG2);
      #my $out = `$command`;
      chomp($out);
      print "$line:$out\n";
   }
}
print LOG2 localtime(time) . ": Finished Running Cloud Metadata collection scripts for TFA\n";
close(LOG2);
close(*STDOUT);
