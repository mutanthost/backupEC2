#
# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/racdbcloudcollect.pl /main/3 2017/03/01 08:11:28 bburton Exp $
#
# racdbcloudcollect.pl
# 
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      racdbcloudcollect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     12/16/16 - remove /tmp
#    bburton     02/19/16 - fix bug 22762046 (hostname -f on Non Linux)
#    bburton     01/19/16 - Script to collect RAC DB Cloud diagnostics
#    bburton     01/19/16 - Creation
# 
###################

#BEGIN {
#  # Add the directory of this file to the search path
#  push @INC, "/opt/oracle.RecoveryAppliance/lib";
#  $ENV{PATH} = "/usr/local/bin:".$ENV{PATH};
#}

use warnings;
use strict;
use File::Copy;
use File::Path;
use File::Find;
use File::Basename;
use File::Spec::Functions;
use Getopt::Long;



my $hostname;
my $osname = `uname`;
chomp($osname);
my $opcdir = catfile("","opt","oracle","opc");

GetOptions (
            'hostname=s' => \$hostname
             );

open (LOG2, '>', $hostname . "_dbcloudcollection.log");
print LOG2 localtime(time) . ": Running DB Cloud collection scripts for TFA \n";
print LOG2 "hostname: $hostname\n";
print LOG2 "osname: $osname\n";

if ($osname eq "Linux" && -d $opcdir) {
   print LOG2 localtime(time) . " : Running on Linux and $opcdir exists\n";
} else {
   print LOG2 localtime(time) . " : Not a Linux system or Not a RAC DBaaS system - exiting\n";
   exit 0;
}

open (*STDERR, '>', $hostname . "_dbcloudcollection.err");
open (*STDOUT, '>', $hostname . "_dbcloudcollection.out");

my $tempdir = "tfaracdbcsdir$$";
my $tempfile = catfile($tempdir,"racdbcs$$.out");
my $command = "";

if ( -d $tempdir ) {
   print LOG2 localtime(time) . ":Unable to create temp rac dbcs output directory\n";
   exit 0;
}

mkdir $tempdir, 0700;
open (OF, ">", "$tempfile") or
           die("\nFailed to open $tempfile for writing get script \n");
   print OF "/opt/zookeeper/bin/zkCli.sh << EOF\n";
   print OF "ls /dcs-request-rw-locks \n";
   print OF "EOF\n";
close(OF);

$command = "/bin/sh $tempfile > $hostname\_DCS_REQ_RW_LOCKS";
print LOG2 localtime(time) . ": Running $command  for gathering dcs_request-rw-locks\n";
runtimedcommand($command);
unlink($tempfile);

open (OF, ">", "$tempfile") or
           die("\nFailed to open $tempfile for writing get script 2\n");
   print OF "for i in `curl -s -m 5 --retry 15 --retry-delay 3 --noproxy 192.0.0.192 http://192.0.0.192/latest/attributes/`
\n";
   print OF "do \n";
   print OF "echo -n \"\$i: \" \n";
   print OF "curl -s -m 5 --retry 15 --retry-delay 3 --noproxy 192.0.0.192 http://192.0.0.192/latest/attributes/\$i;echo -e \n";
   print OF "done \n";
close(OF);

$command = "/bin/sh $tempfile > $hostname\_LATEST_ATTRIB";
print LOG2 localtime(time) . ": Running $command  for gathering latest attributes with curl\n";
runtimedcommand($command);
unlink($tempfile);

$command = "cat /root/setupenv.out > $hostname\_SETUPENV";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "cat /var/log/sshkey-injection.log > $hostname\_SSHKEY_INJ_LOG";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "cat /zookeeper.out > $hostname\_ZOOKEEPER_OUT";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "cat /root/.imagelabel > $hostname\_IMAGELABEL";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "uname -a > $hostname\_UNAME-A";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "cat /etc/grub.conf > $hostname\_GRUBCONF";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "rpm -qa | grep dcs > $hostname\_DCS_RPMS";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
if ($osname eq "Linux") {
   $command = " hostname -f > $hostname\_HOSTNAME-F";
   print LOG2 localtime(time) . ": Running $command \n";
   runtimedcommand($command);
}
$command = "df -h > $hostname\_DF-H";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "ifconfig -a > $hostname\_IFCONFIG";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "lscpu > $hostname\_LSCPU";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "fdisk -l > $hostname\_FDISK-L";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "cat /etc/sysconfig/network > $hostname\_SYSCON_NETWORK";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "cat /etc/resolv.conf > $hostname\_RESOLV_CONF";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "/opt/oracle/dcs/client/bin/raccli list jobs > $hostname\_RACCLI_LIST_JOBS";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "/opt/oracle/dcs/client/bin/raccli list backup > $hostname\_RACCLI_LIST_BACKUP";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "/opt/oracle/dcs/client/bin/raccli list recovery > $hostname\_RACCLI_LIST_RECOVERY";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "/opt/oracle/dcs/client/bin/raccli list backupconfig > $hostname\_RACCLI_LIST_BACKUPCONFIG";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "/opt/oracle/dcs/client/bin/raccli describe system > $hostname\_RACCLI_DESC_SYS";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "ps -ef | grep dcs > $hostname\_PS";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "ps -ef | grep zoo >> $hostname\_PS";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "ps -ef | grep pmon >> $hostname\_PS";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);
$command = "/opt/zookeeper/bin/zkServer.sh status > $hostname\_ZKSERVER_STATUS";
print LOG2 localtime(time) . ": Running $command \n";
runtimedcommand($command);

# zip up the derby db
my $dbdir1 = catfile("","opt","oracle","dcs","repo","node_1");
my $dbdir2 = catfile("","opt","oracle","dcs","repo","node_2");
if ( -d $dbdir1 ) {
   $command = "/usr/bin/zip -r $hostname\_DERBY_DB_NODE1 $dbdir1";
   runtimedcommand($command);
}
if ( -d $dbdir2 ) {
   $command = "/usr/bin/zip -r $hostname\_DERBY_DB_NODE2 $dbdir2";
   runtimedcommand($command);
}


rmdir($tempdir);

print LOG2 localtime(time) . ": Completed Running racdbcloudcollect.pl for TFA \n";
close(LOG2);
close(*STDERR);
close(*STDOUT);

sub formatdate {
  my $time = shift;
  if ( $time =~ /(\d+)-(\d+)-(\d+) (\d+:\d+:\d+)/ )
  {
    return "$1/$2/$3.$4";
  }
   else
  {
    print LOG2 localtime(time) . "Error: Date format unexpected : $time\n";
    return;
  }
}

sub runtimedcommand  {
my $command = shift;
my $timeout = shift;
my $ktree_level = 0;

if ( !$timeout ) { $timeout = 10 };
print LOG2 localtime(time) . ": Running " . $command . " as a timed command for $timeout seconds.\n";
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
