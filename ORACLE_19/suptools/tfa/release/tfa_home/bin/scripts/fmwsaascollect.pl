# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/fmwsaascollect.pl /main/2 2017/08/11 05:02:21 llakkana Exp $
#
# fmwsaascollect.pl
# 
# Copyright (c) 2015, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      fmwsaascollect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     05/12/15 - Script to collect various operating system details
#                           where doing a collection for FMW- Saas
#    bburton     05/12/15 - Creation
# 
#!/usr/bin/perl

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


open (LOG2, '>', $hostname . "_fmwSaaSCollect.log");
open (*STDERR, '>', $hostname . "_fmwSaaSCollect.err");
open (*STDOUT, '>', $hostname . "_fmwSaaSCollect.out");
print LOG2 localtime(time) . ": Running FMW SaaS collection scripts for TFA \n";

$command = "ps -aef > $hostname\_PS";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "dmesg >> $hostname\_DMESG";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "netstat -a -n -p >> $hostname\_NETSTAT";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "/usr/sbin/lsof > $hostname\_LSOF";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "mount > $hostname\_MOUNT";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "df -k > $hostname\_DF";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "cat /proc/sys/kernel/random/entropy_avail > $hostname\_ENTROPY_AVAIL";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "uptime > $hostname\_UPTIME";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "last reboot > $hostname\_LAST_REBOOT";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);


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
