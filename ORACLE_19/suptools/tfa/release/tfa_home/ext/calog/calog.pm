# 
# $Header: tfa/src/v2/ext/calog/calog.pm /main/8 2018/08/09 22:22:30 recornej Exp $
#
# calog.pm
# 
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      calog.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    07/19/18 - Fix exit code .
#    bburton     07/05/18 - 28251167 - calog showing debug messages.
#    recornej    04/16/18 - Bug 27857781 - LNX-191-TFA:TFACTL CAN NOT QUERY
#                           CALOG.
#    manuegar    11/02/16 - Bug 24948477 - WS2012_122_TFA: HELP INFORMATION FOR
#                           'TFACTL RUN GREP' INCORRECT.
#    arupadhy    07/07/16 - Help Correction, Windows Compatibility, 12.2
#                           validation
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    bburton     02/22/16 - Creation initial version just using shell range context or 24 hours.
#
#
#  TODO accept range parameters.. 
######################
#
package calog;
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
use Time::Local;
use tfactlglobal;
use tfactlshare;
use osutils;
use Getopt::Long;
use List::Util qw[min max];
use POSIX qw(:termios_h);
use POSIX;

use File::Basename;
use File::Spec::Functions;
use File::Path;

my $debug;
my $tool = "calog";
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
  print "calog does not run in daemon mode\n";
  return 0;
}

sub get_range
{
  my $start = "";
  my $end;
  my $duration;

  if ( ! $tfactlglobal_ctx{"time"} && ! $tfactlglobal_ctx{"start-time"} &&
       !  $tfactlglobal_ctx{"end-time"} )
  {
    # default last 24 hours
    return ("0", "0", "01 00:00:00"); 
  }
   elsif ( $tfactlglobal_ctx{"start-time"} )
  {
    $end = tfactlshare_convertDateStringforCRS($tfactlglobal_ctx{"end-time"}, "time");
    $start = tfactlshare_convertDateStringforCRS($tfactlglobal_ctx{"start-time"}, "time");
  }
   elsif ( $tfactlglobal_ctx{"time"} )
  {
    my $for = getValidDateFromString($tfactlglobal_ctx{"time"}, "time");
    $start = $for - 4*60*60;
    $end = $for + 4*60*60;
    $start = strftime '%Y-%m-%d %H:%M:%S', localtime $start;
    $end = strftime '%Y-%m-%d %H:%M:%S', localtime $end;
    return ($start, $end, "0"); 
  }

  return ($start, $end, $duration);
}

sub run
{
  my $tfa_home = shift;
  my @args = @_;
  my $db;
  my $help;
  my $command;
  my @args_bkp;

  @args_bkp = @ARGV;
  @ARGV = @args;
  GetOptions (
   "debug" => \$debug,
   "h" => \$help,
   "help" => \$help);
  @args = @ARGV;
  @ARGV = @args_bkp;

  my $argsleft = scalar(@args);

  if ( $help || $argsleft ) {
    print "Invalid option $args[0]\n" if $argsleft > 0;
    help();
    return 0 if ($help);
    return 1;
  }

  my $crshome = get_crs_home($tfa_home);
  print "CALOG:crshome:  $crshome\n" if ($debug);

  my $activeversion="0";
  if(osutils_isCRSRunning($crshome)){
    $command = catfile ($crshome,"bin","crsctl")." query crs activeversion";
    my @output = `$command`;
    chomp @output;
    foreach (@output) {
      if (/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/) {
           $activeversion = trim($&);
       }
    }
  }

  my $minversion = 12200; #12.2.0.0
  $activeversion =~ s/\.//g;
  if ( $activeversion >= $minversion ) {
    my ($start, $end, $duration) = get_range();
    print "CALOG:range:  start: $start end: $end\n" if ($debug);

    my $tfa_base = tfactlshare_get_repository_location($tfa_home);
    chdir("$tool_base");
    my $localhost = tolower_host();
    if ($duration) {
       $command = catfile($crshome,"bin","crsctl") . " query calog -duration \"$duration\""; 
    } else {
       $command = catfile($crshome,"bin","crsctl") . " query calog -aftertime \"$start\" -beforetime \"$end\""; 
    }
    print "CALOG:running command: $command \n" if ($debug);
    system($command);
  }else{
    print "CALOG is unavailable for CRS Version below 12.2 \n";
    return 1;
  }

  
  return 0;
}

sub help
{
  my $cmd;
  if ( $0 =~ /(.*)\.pl/ ) {
    $cmd = $1;
  }
  print "Usage : $cmd [run] calog \n";
  print "\n      Prints Clusterware activity logs\n\n";
  print "e.g:\n";
  print "   $cmd calog\n";
  print "   $cmd run calog\n";
  return 0;
}
