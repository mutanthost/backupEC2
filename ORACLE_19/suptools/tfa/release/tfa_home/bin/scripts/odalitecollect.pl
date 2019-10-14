# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/odalitecollect.pl /main/7 2018/07/17 04:50:46 bburton Exp $
#
# odalitecollect.pl
# 
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      odalitecollect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     01/12/18 - remove work now done in dbcloudsystemcollect
#    bburton     07/12/17 - bug 26431907
#    manuegar    07/05/17 - Bug 25536278 - LNX64-121-CMT: NEED AN ALL-IN-ONE
#                           SCRIPT TO COLLECT ODA AND ODALITE LOGS FOR SR.
#    bburton     12/16/16 - remove /tmp
#    bburton     08/25/16 - Collect Extra data for ODA Lite on top of a normal
#                           ODA collection
#    bburton     08/25/16 - Creation
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

GetOptions (
            'hostname=s' => \$hostname
             );

open (LOG2, '>', $hostname . "_odalitecollection.log");
print LOG2 localtime(time) . ": Running ODA Lite collection scripts for TFA \n";
print LOG2 "hostname: $hostname\n";
print LOG2 "osname: $osname\n";
print LOG2 localtime(time) . ": Please also check the dbcloud_system_report for data previously collected under odalite \n";

if ($osname eq "Linux" && $IS_ODALITE) {
   print LOG2 localtime(time) . " : Running on Linux and This is an ODALITE type $ODALITE_TYPE\n";
} else {
   print LOG2 localtime(time) . " : Not a Linux system or Not an ODA Lite- exiting\n";
   exit 0;
}

open (*STDERR, '>', $hostname . "_odalitecollection.err");
open (*STDOUT, '>', $hostname . "_odalitecollection.out");

my $odacli = catfile("","opt","oracle","dcs","bin","odacli");
my $odaadmcli = catfile ("","opt","oracle","oak","bin","odaadmcli");
my $tempdir = "tfaodalitedir$$";
my $tempfile = catfile($tempdir,"odalite$$.out");
my $command = "";
my $date = `date`;
chomp($date);


if ( -d $tempdir ) {
   print LOG2 localtime(time) . ":Unable to create temp oda lite output directory\n";
   exit 0;
}

mkdir $tempdir, 0700;
open (OF, ">", "$tempfile") or
           die("\nFailed to open $tempfile for writing get script \n");
   print OF "/opt/zookeeper/bin/zkCli.sh << EOF\n";
   print OF "ls /dcs-request-rw-locks \n";
   print OF "EOF\n";
close(OF);

osutils_runtimedcommand("/bin/sh $tempfile > $hostname"."_DCS_REQ_RW_LOCKS",10,FALSE,\*LOG2);
unlink($tempfile);
osutils_runtimedcommand("cat /root/setupenv.out > $hostname"."_SETUPENV",10,FALSE,\*LOG2);
if ( -f "/root/.imagelabel" ) {
  osutils_runtimedcommand("cat /root/.imagelabel > $hostname"."_IMAGELABEL",10,FALSE,\*LOG2);
}
osutils_runtimedcommand("ifconfig -a > $hostname"."_IFCONFIG",10,FALSE,\*LOG2);
osutils_runtimedcommand("fdisk -l > $hostname"."_FDISK-L",10,FALSE,\*LOG2);
osutils_runtimedcommand("cat /etc/sysconfig/network > $hostname"."_SYSCON_NETWORK",10,FALSE,\*LOG2);
osutils_runtimedcommand("cat /opt/oracle/extapi/asmappl.config > $hostname"."_ASMAPPL.CONFIG",10,FALSE,\*LOG2);
osutils_runtimedcommand("find /etc/udev/rules.d -type f -print -exec cat {} \\; > $hostname"."_UDEV_RULES",10,FALSE,\*LOG2);
osutils_runtimedcommand("cat /etc/resolv.conf > $hostname"."_RESOLV_CONF",10,FALSE,\*LOG2);
osutils_runtimedcommand("cat /etc/hosts > $hostname"."_ETC_HOSTS",10,FALSE,\*LOG2);

if ( -f $odacli ) {
  osutils_runtimedcommand("$odacli list-networks > $hostname"."_ODACLI_LIST_NETWORKS",10,FALSE,\*LOG2);
  osutils_runtimedcommand("$odacli list-networkinterfaces > $hostname"."_ODACLI_LIST_NETWORKINTERFACES",10,FALSE,\*LOG2);
  osutils_runtimedcommand("$odacli describe-latestpatch > $hostname"."_ODACLI_DESC_LATESTPATCH",10,FALSE,\*LOG2);
}

if ( -f $odaadmcli ) {
  osutils_runtimedcommand("$odaadmcli show env_hw > $hostname"."_ODAADMCLI_SHOWENVHW",60,FALSE,\*LOG2);
}

osutils_runtimedcommand("ps -ef | grep zoo >> $hostname"."_PS",10,FALSE,\*LOG2);

# zip up the derby db
my $dbdir0 = catfile("","opt","oracle","dcs","repo","node_0");
if ( -d $dbdir0 ) {
   osutils_runtimedcommand("/usr/bin/zip -r $hostname\_DERBY_DB_NODE0 $dbdir0",10,FALSE,\*LOG2);
}

# Collection /root/*.log 
my $rootfile;
my $rootdir="/root";
if ( -d $rootdir ) {
  my @files = ("imaging_status.log","install.log","install.log.syslog","post-ks-chroot.log","post-ks-nochroot.log");
  foreach my $dirfile (@files) {
    $rootfile = catfile($rootdir,$dirfile);
    if ( -r $rootfile ) {
      my $outfile = $hostname . "_root_$dirfile";
      print LOG2 localtime(time) . ": Copying $rootfile into $outfile\n";
      copy($rootfile,$outfile);
    } else {
      print LOG2 localtime(time) . ": $dirfile not in $rootdir\n";
    }
  }
} #  End  if -d rootdir

rmdir($tempdir);

print LOG2 localtime(time) . ": Completed Running odalitecollect.pl for TFA \n";
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
