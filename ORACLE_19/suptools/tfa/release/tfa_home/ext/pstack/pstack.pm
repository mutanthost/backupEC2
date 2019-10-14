# 
# $Header: tfa/src/v2/ext/pstack/pstack.pm /main/8 2018/08/09 22:22:30 recornej Exp $
#
# pstack.pm
# 
# Copyright (c) 2015, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      pstack.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    07/19/18 - Fix exit code.
#    manuegar    11/02/16 - Bug 24948477 - WS2012_122_TFA: HELP INFORMATION FOR
#                           'TFACTL RUN GREP' INCORRECT.
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    llakkana    08/07/15 - Bug 21551258 - HPI_122_TFA: TFACTL PSTACK HIT SH:
#                           PSTACK: NOT FOUND ON REMOTE NODE
#    gadiga      03/24/15 - fix 20666289. dont show help from remote node
#    gadiga      01/08/15 - list files
#    gadiga      01/08/15 - Creation
# 
package pstack;
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

my $tool = "pstack";
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
  print "pstack does not run in daemon mode\n";
  return 0;
}

sub run
{
  my $tfa_home = shift;
  my @args = @_;
  my $db;
  my @pids = ();
  my $cnt = 1;
  my $sleep = 0;
  my %pidinfo = ();

  my $pstack = `which pstack 2>/dev/null`;
  chomp($pstack);
  if ( ! $pstack || ! -f "$pstack" )
  {
    $pstack = "/usr/ccs/bin/pstack" if ( -f "/usr/ccs/bin/pstack" );
    $pstack = "/usr/bin/pstack" if ( -f "/usr/bin/pstack" );
  }

  if ( ! $pstack )
  {
    print "Error: pstack command not found in system. If its installed, please set the PATH and try again.\n";
    return 1;
  }
  for (my $i=0; $i <= $#args; $i++)
  {
    if ( $args[$i] eq "-database" || $args[$i] eq "-db" )
    {
      $db = $args[$i+1];
      splice @args, $i, 1;
      splice @args, $i, 1;
      $i--;
    }
     elsif ( $args[$i] eq "-n" )
    {
      $cnt = $args[$i+1];
      splice @args, $i, 1;
      splice @args, $i, 1;
      $i--;
    }
     elsif ( $args[$i] eq "-s" )
    {
      $sleep = $args[$i+1];
      splice @args, $i, 1;
      splice @args, $i, 1;
      $i--;
    }
     elsif ( $args[$i] =~ /^\d+$/ )
    {
      @pids = (@pids, $args[$i]);
      my @tmp = `ps -ef |sed 's/^ *//' | grep -w $args[$i]`;
      chomp(@tmp);
      $pidinfo{$args[$i]} = @tmp;
      splice @args, $i, 1;
      $i--;
    }
     elsif ( ! -f $args[$i] && $args[$i] !~ /^\-/ && $args[$i] !~ /^\d+$/ )
    {
      my @tmp = `ps -ef |sed 's/^ *//' | grep $args[$i] |grep -v grep | grep -v tfactl |grep -v executecommandprint |grep -v oracle.rat.tfa.CommandLine |grep -v " -remotetfarun"`;
      chomp(@tmp);
      foreach my $tmp (@tmp)
      {
        my @a = split(/\s+/, $tmp);
        @pids = (@pids, $a[1]);
        $pidinfo{$a[1]} = ($tmp);
      }
      splice @args, $i, 1;
      $i--;
    }
  }

  if ( $args[0] eq "-h" || $args[0] eq "-help" )
  {
    help();
    return 0;
  }

  $db = $ENV{"TFA_SESSION_DB"} if ( ! $db && defined $ENV{"TFA_SESSION_DB"} );

  my $ctime_prefix = tfactlshare_get_ctime();
  my $pstack_out = "pstack-$ctime_prefix.out";

  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  chdir($tool_base);
  time();
  for ( my $i = 0; $i < $cnt; $i++ )
  {
    $ctime_prefix = tfactlshare_get_ctime();
    system("echo '$ctime_prefix:' >> $pstack_out");
    print "\n# Loop ". ($i+1) ."\n" if ( $cnt > 1 );
    foreach my $pid (@pids)
    {
      print "\n# pstack output for pid : $pid\n";
      system("echo '# pstack output for pid : $pid' >> $pstack_out");
      system("echo '# $pidinfo{$pid}' >> $pstack_out");
      system("$pstack @args $pid 2>&1 | tee -a $pstack_out ");
    }
    sleep($sleep) if ( $sleep > 0 && $i < $cnt-1);
  }
  return 0;
}

sub help
{
  print "Usage : $0 [run] pstack <pid|process name> [-n <n>] [-s <secs>]\n";
  print "\n      Print stack trace of a running process <n> times. Sleep <secs> seconds between runs.\n\n";
  print "e.g:\n";
  print "   $0 pstack lmd\n";
  print "   $0 pstack 2345 -n 5 -s 5\n";
  print "   $0 run pstack lmd\n";
  print "   $0 run pstack 2345 -n 5 -s 5\n";
  return 0;
}

