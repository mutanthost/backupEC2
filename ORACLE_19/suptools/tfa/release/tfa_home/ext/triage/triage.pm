# 
# $Header: tfa/src/v2/ext/triage/triage.pm /main/6 2018/08/09 22:22:30 recornej Exp $
#
# triage.pm
# 
# Copyright (c) 2015, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      triage.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    07/19/18 - Fix exit codes
#    llakkana    05/11/17 - Fix 25693266
#    llakkana    11/28/16 - Add help for -a/-c
#    manuegar    11/02/16 - Bug 24948477 - WS2012_122_TFA: HELP INFORMATION FOR
#                           'TFACTL RUN GREP' INCORRECT.
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    gadiga      08/04/15 - Run osw,exawatcher analyzer
#    gadiga      08/04/15 - Creation
# 
package triage;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(deploy
                 autostart
                 start
                 stop
                 restart
                 status
                 run
                 runstatus
                 is_running
                 help
                );

use strict;
use Math::BigInt;
use tfactlglobal;
use tfactlshare;

use List::Util qw[min max];
use POSIX qw(:termios_h);

use File::Basename;
use File::Spec::Functions;
use File::Path;

my $tool = "triage";
my $tfa_base = tfactlshare_get_repository_location($tfa_home);
my $tool_dir = catfile($tfa_base, "suptools", "$hostname", $tool);
my $tool_base = catfile($tfa_base, "suptools", "$hostname", $tool, $current_user);

sub deploy 
{
  my $tfa_home = shift;
  return 0;
}

sub autostart
{
  return 0;
}

sub is_running 
{
  return 2;
}

sub runstatus 
{
  return 3;
}

sub start 
{
  print "Nothing to do !\n";
  return 0;
}

sub stop 
{
  print "Nothing to do !\n";
  return 0;
}

sub restart 
{
  print "Nothing to do !\n";
  return 0;
}

sub status
{
  print "triage does not run in daemon mode\n";
  return 0;
}

sub run
{
  my $tfa_home = shift;
  my @args = @_;

  #Triage need atleast one arguement
  if ( $#args < 0 )
  {
    print "Error: Start Date should be provided along with -t flag\n\n";
    help();
    return 1;
  }

  if ( $args[0] eq "-h" || $args[0] eq "-help" )
  {
    help();
    return 0;
  }

  chdir($tool_base);

  my $time = $tfactlglobal_ctx{"time"};
  my $stime = $tfactlglobal_ctx{"start-time"}, 
  my $etime = $tfactlglobal_ctx{"end-time"};

  my $script = catfile($tfa_home, "ext", "triage", "osw_exaw_analyzer.sh");

  my $bash = `which bash`;
  chomp($bash);
  if ( ! $bash || ! -f $bash )
  {
    print "Error : This command requires BASH shell. Could not find bash in PATH. Please set PATH and try again\n";
    return 1;
  }

  my @oswdirs = `ps -ef |grep OSWatcher |grep archive`;
  chomp(@oswdirs);
  my $oswdir = $oswdirs[0];
  if ( $oswdirs[0] =~ /archive/ )
  {
    my @a = split(/\s+/, $oswdirs[0]);
    $oswdir = $a[$#a];
  }
  if ( $oswdir && -d $oswdir )
  {
    $ENV{"OSW_DIR"} = "$oswdir";
  }
  system("bash $script -w $tool_base @args");
  return 0;
}

sub help
{
  print "Usage : $0 [run] triage -t <datetime> -d <duration> [-a] [-p <pid>] [-h]\n";
  print "        where datetime format is YY.MM.DD.HH00>\n";
  print "              duration = number of hours\n";
  print "              -a prints available dates in oswatcher\n";
  print "              -p <pid> show activity of a specific process\n";
  print "              -h display this help and exit\n";
  print "\nSummarize oswatcher/exawatcher data.\n\n";
  print "e.g:\n";
  print "   To print available dates in oswatcher\n";
  print "   $0 triage -a\n";
  print "   $0 run triage -a\n";
  print "   To run report:\n";
  print "   $0 triage -t 13.03.15.0400 -d 2\n";
  print "   $0 run triage -t 13.03.15.0400 -d 2\n";
  print "   To show activity of a specific process\n";
  print "   $0 triage -t 13.03.15.0400 -d 2 -p <pid>\n";
  print "   $0 run triage -t 13.03.15.0400 -d 2 -p <pid>\n";
  return 0;
}

