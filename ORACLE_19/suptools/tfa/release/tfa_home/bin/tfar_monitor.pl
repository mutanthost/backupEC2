# 
# $Header: tfa/src/v2/tfa_home/bin/tfar_monitor.pl /main/7 2017/08/16 09:05:19 anmathad Exp $
#
# tfar_monitor.pl
# 
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfar_monitor.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    gadiga      08/09/17 - remove summary
#    gadiga      08/23/16 - security hardening
#    gadiga      06/14/16 - summary report by component
#    gadiga      06/07/16 - call dbcheck.sh
#    gadiga      01/19/16 - create files with time and clean old files
#    sgoggi      01/14/16 - Creation
#

use strict;
use English;
use File::Basename;
use File::Spec::Functions;
use File::Copy;
use File::Find;
use Time::Local;
use Term::ANSIColor;
use Cwd;
use POSIX qw(strftime);

use Getopt::Long qw(:config no_auto_abbrev);

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME).'/';
  push @INC, dirname($PROGRAM_NAME).'/common';
  push @INC, dirname($PROGRAM_NAME).'/modules';
  push @INC, dirname($PROGRAM_NAME).'/common/exceptions';
}

use tfactlglobal;
use tfactlshare;


my $action = $ARGV[0];
my $tfa_home = $ARGV[1];

my $lckfile = catfile($tfa_home, "internal", ".tfarmonitor.pid");
if ( $action eq "stop" )
{
  if ( -f $lckfile )
  {
    my $pid = `cat $lckfile`;
    chomp($pid);
    if ( $pid )
    {
      my $running = `ps -ef |grep -w $pid |grep -c tfar_m`;
      system("kill -9 $pid");
    }
  }
  unlink($lckfile) if ( $lckfile );
  exit;
}

my $tfa_base = dirname($ARGV[2]);
my $crshome = $ARGV[3];
if ( ! -d $tfa_home || ! -d "$tfa_base" )
{
  print "Usage : $0 <tfa_home> <tfa_base> [<crshome>]\n";
  exit;
}

if ( -f "$lckfile" )
{
  #print "Already running\n";
  exit;
}

open(WF, ">$lckfile");
print WF "$$";
close(WF);

my $hostname = `hostname |cut -d. -f1`;
chomp($hostname);

my $ts = "";

if ( ! -d "$tfa_base/$hostname/output/metadata" )
{
  system("mkdir -p $tfa_base/$hostname/output/metadata");
}

my $perl = tfactlshare_getPerl($tfa_home);

my $loopcnt = 0;
while(1){
  $loopcnt ++;
  $ts = strftime "%Y-%b-%d-%H:%M:%S", localtime;;
  my $ts_hr = strftime "%Y-%b-%d-%H:00:00", localtime;;
  my $tsext = $ts;
  $tsext =~ s/:/-/g;
  my $tsext_hr = $ts_hr;
  $tsext_hr =~ s/:/-/g;

  chdir("$tfa_base/$hostname/output/metadata");
  open(WF, ">$tfa_base/$hostname/output/metadata/tfar_metrics-$tsext.json");
  getvmstst();
  gethomes($tfa_home,$hostname);
  getmemory();
  crs_status() if ( $crshome );
  db_status();
  getdisc("/","ROOT");
  getdisc("$crshome","CRS") if ( $crshome );
  getdisc("$tfa_base","TFA_BASE");
  close(WF);
  if ( $loopcnt == 10 )
  {
    delete_older_files();
    $loopcnt = 0;
  }
  if ( ! -f "$tfa_base/$hostname/output/metadata/tfar_metrics-summary-$tsext_hr.out" )
  {
    my $dname  = "$tfa_base/$hostname/output/metadata/tfar_metrics-$tsext_hr";

    mkdir ("$dname");
    chdir ("$dname");
    system("$perl $tfa_home/bin/scripts/oscollect.pl");
    #system("$tfa_home/bin/tfactl summary -node local > $tfa_base/$hostname/output/metadata/tfar_metrics-summary-$tsext_hr.out");
  }
  sleep(90);
}

sub crs_status
{
  my $crsup = 0;
  my $check_crs_run = `$crshome/bin/crs_stat -t  >/dev/null 2>&1;echo \$?`;
  chomp($check_crs_run);
  $crsup = 1 if ( $check_crs_run == 0 );
  print WF "{\"metrics\" : \"status\", \"node\" : \"$hostname\", \"component\" : \"crs\", \"timestamp\" : \"$ts\", \"status\" : \"$crsup\"}\n";
}

sub db_status
{
  my @pmon = `ps -ef |grep pmon |grep -v grep |awk '{print \$NF}'`;
  chomp(@pmon);
  foreach my $p (@pmon)
  {
    if ( $p =~ /(\w+)_pmon_([\w\+\-]+)/ )
    {
      print WF "{\"metrics\" : \"status\", \"node\" : \"$hostname\", \"component\" : \"$1\", \"instance\" : \"$2\", \"timestamp\" : \"$ts\", \"status\" : \"1\"}\n";
    }
  }
}
sub getmemory {
  my $t = `free | grep Mem | awk '{print \$3/\$2 \* 100.0}'`;
  my $i = index($t,".");
  my $u =substr($t,0,$i);
  chomp($u);
  my $json_vm = "{\"metrics\" : \"vmstat\", \"node\" : \"$hostname\", \"timestamp\" : \"$ts\", ";
  $json_vm = $json_vm.'"memory_usage":"'.$u.'"}';
  print WF "$json_vm\n";
}

sub gethomes {
  my $tfa_home = shift;
  my $h= shift;
  my $tfa_setup = catfile($tfa_home,"tfa_setup.txt");
  my $json_vm = "{\"metrics\" : \"homes\", \"node\" : \"$hostname\", \"timestamp\" : \"$ts\", ";
  open INP, "$tfa_setup" or die $!;
  my @lines = <INP>;
  my $l = "";
  my $rec;
  foreach $rec (@lines){
    if(($rec =~ /^$h/) && ($rec =~ /ASM_INSTANCE/)){
       my @parts = split/=/,$rec;
       print $parts[1];
       chomp($parts[1]);
       $l = $l."ASM_INSTANCE=".$parts[1].";";
    }
elsif(($rec =~ /^$h/) && ($rec =~ /ASM_HOME/)){
   my @parts = split/=/,$rec;
   print $parts[1];
   chomp($parts[1]);
   $l = $l."ASM_HOME=".$parts[1].";";
}
elsif($rec =~ /CRS_HOME/) {
  my @parts = split/=/,$rec;
  print $parts[1];
   chomp($parts[1]);
   $l = $l."CRS_HOME=".$parts[1].";";
}
elsif(($rec =~ /^$h/) && ($rec =~ /CRS_ACTIVE_VERSION/)){
   my @parts = split/=/,$rec;
  print $parts[1];
     chomp($parts[1]);
     $l = $l."CRS_ACTIVE_VERSION=".$parts[1].";";

}
elsif($rec =~ /RDBMS_ORACLE_HOME/) {
  my @parts = split/=/,$rec;
  print $parts[1];
     chomp($parts[1]);
     $l = $l."RDBMS_ORACLE_HOME=".$parts[1].";";
}
elsif(($rec =~ /^$h/) && ($rec =~ /INSTANCE_NAME/)){
   my @parts = split/=/,$rec;
  print $parts[1];
  chomp($parts[1]);
  $l = $l."INSTANCE_NAME=".$parts[1].";";

}
elsif(($rec =~ /^$h/) && ($rec =~ /INSTANCE_VERSION/)){
   my @parts = split/=/,$rec;
  print $parts[1];
  chomp($parts[1]);
  $l = $l."INSTANCE_VERSION=".$parts[1].";";

}
}

$json_vm = $json_vm.'"homes":"'.$l.'"}';
print WF "$json_vm\n";

}
sub getvmstst {
  my $p = `vmstat 1 3`;
  my @chunks = split /\n/,$p;
  my $lastline = $chunks[-1];
  chomp($lastline);
  my @vals = split(/\s+/,$lastline);
  my $val = $#vals;
  my $json_vm = "{\"metrics\" : \"vmstat\", \"node\" : \"$hostname\", \"timestamp\" : \"$ts\", ";
  $json_vm = $json_vm.'"procs_r":"'.$vals[1].'",';
  $json_vm = $json_vm.'"procs_b":"'.$vals[2].'",';
  $json_vm = $json_vm.'"memory_swpd":"'.$vals[3].'",';
  $json_vm = $json_vm.'"memory_free":"'.$vals[4].'",';
  $json_vm = $json_vm.'"mem_buf":"'.$vals[5].'",';
  $json_vm = $json_vm.'"mem_cache":"'.$vals[6].'",';
  $json_vm = $json_vm.'"swap_si":"'.$vals[7].'",';
  $json_vm = $json_vm.'"swap_so":"'.$vals[8].'",';
  $json_vm = $json_vm.'"io_bi":"'.$vals[9].'",';
  $json_vm = $json_vm.'"io_bo":"'.$vals[10].'",';
  $json_vm = $json_vm.'"system_in":"'.$vals[11].'",';
  $json_vm = $json_vm.'"system_cs":"'.$vals[12].'",';
  $json_vm = $json_vm.'"cpu_us":"'.$vals[13].'",';
  $json_vm = $json_vm.'"cpu_sy":"'.$vals[14].'",';
  $json_vm = $json_vm.'"cpu_id":"'.$vals[15].'",';
  $json_vm = $json_vm.'"cpu_wa":"'.$vals[16].'",';
  $json_vm = $json_vm.'"cpu_st":"'.$vals[17].'"}';

  print WF "$json_vm\n";
}

sub getdisc {
  my $arg1 = shift;
  my $arg2 = shift;
  chomp($arg2);
  my $u = $arg2."_"."UsePercent";
  chomp($u);
  my $o = `df -k $arg1 |grep -v Filesystem`;
  chomp($o);
  my @vals = split /\s+/,$o;
  my $json_vm = "{\"metrics\" : \"diskusage\", \"disktype\" :  \"$arg2\", \"node\" : \"$hostname\", \"timestamp\" : \"$ts\", ";
  $json_vm = $json_vm.'"Filesystem":"'.$vals[0].'",';
  $json_vm = $json_vm.'"1Kblocks":"'.$vals[1].'",';
  $json_vm = $json_vm.'"Used":"'.$vals[2].'",';
  $json_vm = $json_vm.'"Available":"'.$vals[3].'",';
  $json_vm = $json_vm.'"'.$u.'":"'.$vals[4].'",';
  $json_vm = $json_vm.'"Mounted_on":"'.$vals[5].'"}';
  print  WF "$json_vm\n";
}
 
sub delete_older_files
{
  my @files = ();
  find(sub{push @files, $File::Find::name if /tfar_metrics/ && -M _ >= 1/24}, "$tfa_base/$hostname/output/metadata");

  foreach my $file (@files)
  {
    unlink($file);
  }
}
