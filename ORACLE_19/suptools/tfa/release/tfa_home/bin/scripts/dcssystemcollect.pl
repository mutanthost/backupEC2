#!/usr/local/bin/perl
# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/dcssystemcollect.pl /main/1 2018/07/17 04:50:46 bburton Exp $
#
# dcssystemcollect.pl
# 
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      dcssystemcollect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     01/10/18 - Collection script for DB Cloud service SYSTEM
#                           component.
#    bburton     01/10/18 - Creation
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

GetOptions (
            'hostname=s' => \$hostname
             );

#Open a log file for this collection script to write to
open (STDOUT, '>', $hostname . "_odasystem_collect.log");
print localtime(time) . ": Running ODA SYSTEM Component collection scripts for TFA \n";
print "Hostname: $hostname\n";
print "osname: $osname\n";

if ($osname eq "Linux" && $IS_ODALITE) {
   print  localtime(time) . " : Running on Linux and This is an ODALITE type $ODALITE_TYPE\n";
} else {
   print  localtime(time) . " : Not a Linux system or Not an ODA Lite- exiting\n";
   exit 0;
}

open (STDERR, '>', $hostname . "_odasystem_collect.err");
open (REP, '>', $hostname . "_odasystem_report");

#set up command variables

my $LSCPU; my $RPM; my $PS; my $GREP; my $CAT; my $DF; my $UNAME; my $NVMEADM; my $HOSTNAME;
my $FWRP_TOPOLOGY; my $FWRP_DISCOVERY; my $ECHO; my $NC; 

$LSCPU = cmdlocation_get("lscpu");
$RPM = cmdlocation_get("rpm");
$PS = cmdlocation_get("ps");
$GREP = cmdlocation_get("grep");
$CAT = cmdlocation_get("cat");
$ECHO = cmdlocation_get("echo");
$NC = cmdlocation_get("nc");
$DF = cmdlocation_get("df");
$UNAME = cmdlocation_get("uname");
$NVMEADM = cmdlocation_get("nvmeadm");
$HOSTNAME = cmdlocation_get("hostname");
$FWRP_TOPOLOGY = cmdlocation_get("fwrp_topology");
$FWRP_DISCOVERY = cmdlocation_get("fwrp_discovery");

my $ODACLI = catfile("","opt","oracle","dcs","bin","odacli");
my $zkserversh = catfile ("","opt","zookeeper","bin","zkServer.sh");
my $command = "";
my $date = `date`;
chomp($date);

my @commandarray;
my $commandstring;
if ($osname eq "Linux") { 
  push (@commandarray,"$HOSTNAME -f~~host name -");
}
push (@commandarray,"$UNAME -a~~host info -");
if ( -f "/etc/grub.conf" ) {
  push (@commandarray,"$CAT /etc/grub.conf~~grub.conf -");
}
push (@commandarray,"$LSCPU~~lscpu -");
push (@commandarray,"$RPM -qa | $GREP dcs~~Dcs Version -");
push (@commandarray,"$RPM -qa | $GREP oda~~Oda Version -");
push (@commandarray,"$PS -eaf | $GREP java~~Java Process -");
push (@commandarray,"$PS -ef | $GREP pmon~~DB Process -");
push (@commandarray,"$PS -eaf | $GREP zkMonitor~~zkMonitor Process -");
push (@commandarray,"$ECHO status | $NC localhost 2181 | $GREP Zookeeper~~Zookeeper Version -");
push (@commandarray,"$zkserversh status~~zookeeper Status -");
if ( -f "/proc/meminfo" ) {
  push (@commandarray,"$CAT /proc/meminfo~~/proc/meminfo -");
}
push (@commandarray,"$DF -h~~FileSystem Info -");
push (@commandarray,"$PS -ef | $GREP crsd.bin~~Crs Status -");
push (@commandarray,"$NVMEADM getlog -h~~NVME info -");
push (@commandarray,"$NVMEADM list -v~~NVME info -");
push (@commandarray,"$FWRP_TOPOLOGY~~fwrp_topology -");
push (@commandarray,"$FWRP_DISCOVERY~~fwrp_discovery -");
push (@commandarray,"$ODACLI describe-appliance~~Describe Appiance -");
push (@commandarray,"$ODACLI describe-dbsystem~~Describe DB System -");
push (@commandarray,"$ODACLI describe-asr~~Describe ASR -");
push (@commandarray,"$ODACLI describe-component~~Describe Component -");
push (@commandarray,"$ODACLI list-jobs~~List Jobs -");
push (@commandarray,"$ODACLI list-dbhomes~~List dbhomes -");
push (@commandarray,"$ODACLI list-databases~~List databases -");
$ENV{"DEVMODE"} = "true";
push (@commandarray,"$ODACLI list-recovery~~List Recovery -");
push (@commandarray,"$ODACLI list-backupconfigs~~List Backup Configs -");

runcommandarray(\@commandarray);

#   Reading asm data from /tmp
my $outfile = $hostname . "_TMP_ASM_DATA";
my $procdir="/tmp";
my $openok =  opendir(my $dir, $procdir);
my $dirfile;
my $infofile;

if ( -d $procdir ) {
  if ( $openok ) {
    my @files = readdir $dir;
    closedir $dir;

    open(WF, ">$outfile");
    print WF "### Contents of /tmp/asm*(log|sql|out) at $date ###\n";

    foreach $dirfile (@files) {
      #Make sure it is a non symbolic file 
      if ( -f $dirfile && ! -l $dirfile && 
	   $dirfile =~ /asm.*(log|out|sql)/ || $dirfile eq "diskGroupInfo") {
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

print localtime(time) . ": Completed Running dcssystemcollect.pl for TFA \n";
close(*STDERR);
close(*STDOUT);
close(REP);

sub runcommandarray {
   my $array_ref = shift;
   my $commandstring;
   my @commandarray = @{$array_ref};
   print REP "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n";
   foreach $commandstring ( @commandarray ) {
      my ($command,$desc) = split(/~~/,$commandstring);
      print REP "$desc\n\n";
      my $commandfile = $command;
      $commandfile =~ s/\s.*//;
      if ( -e $commandfile ) {
        runtimedcommand($command);
      } else {
        print REP "$commandfile not found on this system";
      }
      print REP "\n";
      print REP "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n";
   }
}

sub runtimedcommand  {
my $command = shift;
my $timeout = shift;
my $cmdout;

if ( !$timeout ) { $timeout = 10 };
  eval {
      local $SIG{ALRM} = sub { die "Timeout\n" };
      alarm $timeout;
      $cmdout = `$command`;
      print REP "$cmdout\n";
      alarm 0;
  };
  if ($@) {
      print localtime(time) . ": $command timed out.\n";
      return(99);
  } elsif ($? != 0) {
      print localtime(time) . ": $command failed.\n" ;
      return(1);
  } else {
      print localtime(time) . ": $command success.\n" ;
      return(0);
  }
}
