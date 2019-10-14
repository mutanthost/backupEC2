# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/exadom0collect.pl /main/2 2017/08/11 05:02:21 llakkana Exp $
#
# exadom0collect.pl
# 
# Copyright (c) 2015, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      exadom0collect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     01/26/15 - Script to collect data for Exadata Dom0
#    bburton     01/26/15 - Creation
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


my $hostname;
my $command;

GetOptions ('hostname=s' => \$hostname);


open (LOG2, '>', $hostname . "_exaDom0Collect.log");
open (*STDERR, '>', $hostname . "_exaDom0Collect.err");
open (*STDOUT, '>', $hostname . "_exaDom0Collect.out");
print LOG2 localtime(time) . ": Running Exadata Dom0 collection scripts for TFA \n";

$command = "xm list > $hostname\_XMLIST";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "xm list -l >> $hostname\_XMLIST";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "ls -al /etc/xen/auto > $hostname\_XENAUTO";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);

# Collect the VM configuration information.
my $vmconfout="$hostname" . "_VMGUESTCONFIGS";
my $vmdir="/EXAVMIMAGES/GuestImages";
my $topdir;
my $dirfile;
my $infofile;
my $fulldir;
my $openok =  opendir(my $dir, $vmdir);
#Only try to open directory if it exists
if ( -d $vmdir ) {
  if ( $openok ) {
    my @dirs= readdir $dir;
    closedir $dir;

     open(WF, ">$vmconfout");

     foreach $topdir (@dirs) {
        if ( $topdir =~ /[0-9a-zA-Z]/ ) {
          $fulldir = catfile($vmdir,$topdir);
          print WF "### Collecting from Directory $fulldir ###\n";
          $openok = opendir( $dir, $fulldir);
          if ( $openok ) {
            my @files= readdir $dir;
            closedir $dir;
            foreach $dirfile (@files) {
              if ($dirfile =~ /\.(conf|cfg)/) {
                  $infofile = catfile($fulldir,$dirfile);
                  print LOG2 localtime(time) . ": Collecting $infofile into $vmconfout\n";
                  print WF "## File: $infofile \n";

                  $openok = open (RF, "$infofile");
                  if ($openok) { print LOG2 localtime(time) . ": Opened file $infofile for read\n";
                    while(<RF>) {
                    chomp();
                    print WF "$_\n";
                    }
                    close(RF);
                  } else {
                    print LOG2 localtime(time) . ": Failed to open file $infofile for read\n";
                  }
              }
            }
          }
        }
     }
     close(WF);
  } else {
     print LOG2 localtime(time) . ": Unable to open $vmdir files\n";
  }
}

# collect the conf xml files.

$vmconfout="$hostname" . "_VMCONFIGXML";
my $confdir="/EXAVMIMAGES/conf";
$openok = opendir( $dir, $confdir);
if ( $openok ) {
     my @files= readdir $dir;
     closedir $dir;
     open(WF, ">$vmconfout");
     foreach $dirfile (@files) {
       if ($dirfile =~ /\.xml/) {
          $infofile = catfile($confdir,$dirfile);
          print LOG2 localtime(time) . ": Collecting $infofile into $vmconfout\n";
          print WF "## File: $infofile \n";

          $openok = open (RF, "$infofile");
          if ($openok) { print LOG2 localtime(time) . ": Opened file $infofile for read\n";
              while(<RF>) {
                chomp();
                print WF "$_\n";
              }
              close(RF);
          } else {
                 print LOG2 localtime(time) . ": Failed to open file $infofile for read\n";
          }
       }
    }
    close(WF);
}

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
    `$command`;
    alarm 0;
};
if ($@) {
    print LOG2 localtime(time) . ": $command timed out.\n";
    return(99);
} else {
    print LOG2 localtime(time) . ": $command successful.\n" ;
    return(0);
}
}
