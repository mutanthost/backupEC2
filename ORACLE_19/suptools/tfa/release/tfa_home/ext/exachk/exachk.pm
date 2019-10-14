# 
# $Header: tfa/src/v2/ext/exachk/exachk.pm /main/8 2018/02/09 09:04:29 bburton Exp $
#
# exachk.pm
# 
# Copyright (c) 2014, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      exachk.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     12/20/17 - set rat output prior to checking version
#    bburton     12/14/17 - Not working out the version to use correctly
#    bburton     11/15/17 - Handle using oeda supplied exacheck if not shipped with
#                           TFA
#    bburton     09/26/17 - Run fromorachk dir now so as to only ship one
#                           version
#    bburton     09/22/16 - Remove Posixly_correct due to orachk bug
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    gadiga      03/24/15 - fix 20666289. dont show help from remote node
#    gadiga      11/03/14 - Creation
# 
package exachk;
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

my $tool = "exachk";
my $tfa_base = tfactlshare_get_repository_location($tfa_home);
my $tool_dir = catfile($tfa_base, "suptools", "$hostname", $tool);
my $tool_base = catfile($tfa_base, "suptools", "$hostname", $tool, $current_user);
my $crs_home = get_crs_home($tfa_home);

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
  print "Exachk is not running in daemon mode. Please use exachk daemon commands.\n";
  return 0;
}

sub run
{
  my $tfa_home = shift;
  my @flags = @_;
  my $orachk = catfile($tfa_home, "ext", "orachk", "exachk");
  my $ship_ochk = catfile("","opt","oracle.SupportTools","exachk","exachk");
  if ( (! -f $orachk) and (! -f $ship_ochk))
  {
    print "Error: exachk is not deployed under TFA or Oracle Home.\n";
    return 1;
  }
  #set RAT_OUTPUT
  $ENV{RAT_DISABLE_STALENESS_VALIDATION} = 1;
  $ENV{RAT_OUTPUT} = $tool_base;
  delete $ENV{POSIXLY_CORRECT};
  # determine which orachk to use.
  if ( ! -f $orachk ) { # use the shiphome orachk
    $orachk = $ship_ochk;
    print "Using exachk : $orachk \n";
  } elsif ( ! -f $ship_ochk ) {
    print "Using exachk : $orachk \n";
  } else {
    # Work out the newest one
    # exachk in TFA
    my @arr_orachk_vers = split(/\n/,`$orachk -v`);
    my $orachk_vers = 0;
    $orachk_vers = $arr_orachk_vers[0] if ( length $arr_orachk_vers[0] );
    $orachk_vers =~ s/.*_//;
    print "tfa exachk : $orachk has version $orachk_vers\n";
    # exachk in suptools
    my @arr_ship_ochk_vers = split(/\n/,`$ship_ochk -v`);
    my $ship_ochk_vers = 0;
    $ship_ochk_vers = $arr_ship_ochk_vers[0] if ( length $arr_ship_ochk_vers[0] );
    $ship_ochk_vers =~ s/.*_//;
    print "suptools exachk : $ship_ochk has version $ship_ochk_vers\n";
    if ( $ship_ochk_vers > $orachk_vers ) {
      $orachk = $ship_ochk;
    }
    print "TFA using exachk : $orachk \n";
  }
  chdir($tool_base);
  system($orachk, @flags);
  $ENV{POSIXLY_CORRECT} = 1;
  return 0;
}

sub help
{
  my $tfa_home = shift;
  run($tfa_home, "-h");
}

1;
