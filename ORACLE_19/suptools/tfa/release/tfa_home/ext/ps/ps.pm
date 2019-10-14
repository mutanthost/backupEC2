# 
# $Header: tfa/src/v2/ext/ps/ps.pm /main/7 2018/08/09 22:22:30 recornej Exp $
#
# ps.pm
# 
# Copyright (c) 2015, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      ps.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    07/19/18 - Fix exit codes
#    manuegar    11/01/16 - Bug 24948477 - WS2012_122_TFA: HELP INFORMATION FOR
#                           'TFACTL RUN GREP' INCORRECT.
#    arupadhy    07/04/16 - Added windows compatibility
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    gadiga      03/24/15 - fix 20666289. dont show help from remote node
#    gadiga      01/08/15 - list files
#    gadiga      01/08/15 - Creation
# 
package ps;
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

my $tool = "ps";
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
  print "ps does not run in daemon mode\n";
  return 0;
}

sub run
{
  my $tfa_home = shift;
  my @args = @_;
  my $db;
  for (my $i=0; $i <= $#args; $i++)
  {
    if ( $args[$i] eq "-database" || $args[$i] eq "-db" )
    {
      $db = $args[$i+1];
      splice @args, $i, 1;
      splice @args, $i, 1;
      $i--;
    }
  }

  if ( $args[0] eq "-h" || $args[0] eq "-help" )
  {
    help();
    return 0;
  }

  my $fpat = pop @args;
  if ( ! $fpat )
  {
    print "Missing pattern input\n";
    help ();
    return 1;
  }

  if ( !($IS_WINDOWS) && (! $args[0]) ) 
  {
    $args[0] = "-ef";
  }

  $db = $ENV{"TFA_SESSION_DB"} if ( ! $db && defined $ENV{"TFA_SESSION_DB"} );

  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  chdir($tool_base);

  if($IS_WINDOWS){    
    system("Wmic process where \"Name like \'\%$fpat\%\'\" get caption, name, commandline, ProcessId");
  }else{
    system("ps @args |grep $fpat |grep -v grep |grep -v ' -remotetfarun' | grep -v tfactl |grep -v oracle.rat.tfa.CommandLine |grep -v executecommandprint ");
  }
  return 0;
}

sub help
{
  my $cmd;
  if ( $0 =~ /(.*)\.pl/ ) {
    $cmd = $1;
  }
  my $func;
  if($IS_WINDOWS){
    $func = "tasklist";
  }else{
    $func = "ps";
  }
  print "Usage : $cmd [run] $func <flags> <pattern>\n";
  print "\n      Lists all processes matching input pattern\n\n";
  print "e.g:\n";
  if($IS_WINDOWS){
    print "   $cmd $func TFA\n";
    print "   $cmd run $func TFA\n";
  }else{
    print "   $cmd $func lmd\n";
    print "   $cmd $func aux pmon\n\n";
    print "   $cmd run $func lmd\n";
    print "   $cmd run $func aux pmon\n\n";
  }
  return 0;
}

