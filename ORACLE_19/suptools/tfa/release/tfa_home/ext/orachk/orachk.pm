# 
# $Header: tfa/src/v2/ext/orachk/orachk.pm /main/11 2018/05/28 15:06:26 bburton Exp $
#
# orachk.pm
# 
# Copyright (c) 2014, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      orachk.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     05/21/18 - check we can execute orachk
#    cnagur      05/09/18 - Fixed Orachk Version Issue
#    bburton     12/20/17 - set rat output prior to checking version
#    bburton     12/14/17 - Not working out the version to use correctly
#    bburton     11/15/17 - Handle when orachk is not bundled
#    bburton     04/26/17 - Bug 25961789 - Fix issues with setting RAT_OUTPUT
#                           for SRDC
#    bburton     04/13/17 - SRDC wants output in it's running directory
#    bburton     09/22/16 - Remove Posixly_correct due to orachk bug
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    gadiga      03/24/15 - fix 20666289. dont show help from remote node
#    gadiga      11/03/14 - Creation
# 
package orachk;
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
use warnings;
use Cwd;
use Math::BigInt;
use tfactlglobal;
use tfactlshare;

use List::Util qw[min max];
use POSIX qw(:termios_h);

use File::Basename;
use File::Spec::Functions;
use File::Path;

my $tool = "orachk";
my $tfa_base = tfactlshare_get_repository_location($tfa_home);
my $tool_dir = catfile($tfa_base, "suptools", "$hostname", $tool);
my $tool_base = catfile($tfa_base, "suptools", "$hostname", $tool, $current_user);
my $crs_home = get_crs_home($tfa_home);

sub getOrachkVersion {
  my $orachk = shift;
  return 0 if (! -e $orachk);
  my @arr_orachk_vers = split(/\n/,`$orachk -v`);
  my $version = 0;
  my $i;
  foreach $i (@arr_orachk_vers) {
    $version = $i if ( $i =~ /VERSION/ );
  }
  $version =~ s/.*_//;
  return $version;
}

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
  print "Please use Orachk daemon commands to check daemon status\n";
  return 0;
}

sub run
{
  my $tfa_home = shift;
  my @flags = @_;
  my $orachk = catfile($tfa_home, "ext", "orachk", "orachk");
  my $ship_ochk = catfile($crs_home,"suptools","orachk","orachk");
  if ( (! -f $orachk) and (! -f $ship_ochk))
  {
    print "Error: orachk is not deployed under TFA or Oracle Home.\n";
    return 1;
  }
  #set RAT_OUTPUT
  $ENV{RAT_DISABLE_STALENESS_VALIDATION} = 1;
  if ( $ENV{FROMSRDC} ) { # SRDC wants to write to it's CWD
    $ENV{RAT_OUTPUT} = getcwd();
    print "Set RAT_OUTPUT to : $ENV{RAT_OUTPUT} \n";
  } else {
    $ENV{RAT_OUTPUT} = $tool_base;
    chdir($tool_base);
  }
  delete $ENV{POSIXLY_CORRECT};
  # determine which orachk to use.
  if ( ! -f $orachk ) { # use the shiphome orachk
    $orachk = $ship_ochk;
    print "Using Orachk : $orachk \n"; 
  } elsif ( ! -f $ship_ochk ) {
    print "Using Orachk : $orachk \n";
  } else {
    # Work out the newest one 
    # orachk in TFA
    my $orachk_vers = getOrachkVersion($orachk);
    print "TFA Orachk : $orachk has version $orachk_vers\n";

    # orachk in suptools
    my $ship_ochk_vers = getOrachkVersion($ship_ochk);
    print "Suptools Orachk : $ship_ochk has version $ship_ochk_vers\n";

    if ( $ship_ochk_vers > $orachk_vers ) {
      $orachk = $ship_ochk;
    }
    print "TFA using Orachk : $orachk \n";
  }
    
  #print "\n\n++++++++++++++ running $orachk, @flags\n\n";
  system($orachk, @flags);
  $ENV{POSIXLY_CORRECT} = 1;
  return 0;
}

1;
