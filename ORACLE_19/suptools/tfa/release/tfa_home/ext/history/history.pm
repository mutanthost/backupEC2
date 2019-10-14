# 
# $Header: tfa/src/v2/ext/history/history.pm /main/8 2018/08/09 22:22:30 recornej Exp $
#
# history.pm
# 
# Copyright (c) 2015, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      history.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    07/19/18 - Fix exit codes.
#    bibsahoo    01/19/18 - FIX BUG 27405792
#    manuegar    11/02/16 - Bug 24948477 - WS2012_122_TFA: HELP INFORMATION FOR
#                           'TFACTL RUN GREP' INCORRECT.
#    arupadhy    07/04/16 - Help fix
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    gadiga      03/24/15 - fix 20666289. dont show help from remote node
#    gadiga      03/24/15 - fix 20752868. show help
#    gadiga      02/23/15 - update help text
#    gadiga      01/28/15 - command history in session
#    gadiga      01/28/15 - Creation
# 
package history;
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

my $tool = "history";
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
  print "$tool does not run in daemon mode\n";
  return 0;
}

sub run
{
  my $tfa_home = shift;
  my @options = @_;
  if ( $options[0] )
  {
    help();
    return 0 if ($options[0] eq "-help" || $options[0] eq "-h" );
    return 1;
  }
  if ( $ENV{TFA_SESSION_ID} )
  {
    tfactlshare_session_history ($ENV{TFA_SESSION_ID}) ;
  } else {
    help();
    return 1;
  }
  return 0;
}

sub help
{
  print "Usage : tfactl> [run] history\n";
  print "\n      Lists commands executed in current TFA shell session\n\n";
  print "e.g:\n";
  print "   tfactl> history\n";
  print "   tfactl> run history\n";
  return 0;
}

