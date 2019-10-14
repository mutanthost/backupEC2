# 
# $Header: tfa/src/v2/ext/prw/prw.pm /main/12 2018/08/09 22:22:30 recornej Exp $
#
# prw.pm
# 
# Copyright (c) 2014, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      prw.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    07/31/18 - Fix exit codes.
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    gadiga      08/05/15 - change default permissions for files to 740
#    llakkana    07/30/15 - Bug 21517280 - TFACTL: UNABLE TO START PROCWATCHER
#                           AS A NON-ROOT USER
#    gadiga      03/24/15 - fix 20666289. dont show help from remote node
#    gadiga      12/22/14 - create prw in suptools
#    gadiga      11/03/14 - Creation
# 
package prw;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(deploy
                 autostart
                 start
                 stop
                 restart
                 status
                 runstatus
                 run
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

my $tool = "prw";
my $tfa_base = tfactlshare_get_repository_location($tfa_home);
my $tool_dir = catfile($tfa_base, "suptools", "$hostname", $tool);
my $tool_base = catfile($tfa_base, "suptools", "$hostname", $tool, $current_user);
my $tool_base_new = "NONE";

sub deploy 
{
  my $tfa_home = shift;

  $tool_base = catfile($tfa_base, "suptools", $tool);
  if ( ! -d $tool_base )
  { # Procwatcher should not have host name in path
    setup_prw($tfa_home, $tool_base, "");
  }
  return 0;
}

sub autostart 
{
  $tool_base = catfile($tfa_base, "suptools", $tool);
  if ( ! -d $tool_base )
  { # Procwatcher should not have host name in path
    setup_prw($tfa_home, $tool_base, "");
  }

  return 0;
}

sub is_running
{
  my $tfa_home = shift;
  if ( is_prw_running($tfa_home) )
  {
    return 1;
  }
  return 0;
}

sub is_prw_running
{
  my $tfa_home = shift;
  my $prw = `$tfa_home/ext/prw/prw.sh status 2>/dev/null |grep -c 'Procwatcher is currently running on '`;
  return 1 if ( $prw > 0 ); # running
  return 0;
}

sub start 
{
  my $tfa_home = shift;
  if ( is_prw_running($tfa_home) )
  {
    print "Procwatcher is already running\n\n";
    return 1;
  }

  run($tfa_home, "start");
  if ( ! is_prw_running($tfa_home) )
  {
    print "\n\nERROR: Failed to start Procwatcher\n\n";
    return 1;
  }

  return 0;
}

sub stop 
{
  my $tfa_home = shift;
  if ( ! is_prw_running($tfa_home) )
  {
    print "Procwatcher is NOT running\n\n";
    return 1;
  }
  run($tfa_home, "stop");
  if ( is_prw_running($tfa_home) )
  {
    print "\n\nERROR: Failed to stop Procwatcher\n\n";
    return 1;
  }

  return 0;
}

sub restart 
{
  my $tfa_home = shift;
  stop($tfa_home);
  start($tfa_home);
  return 0;
}

sub runstatus
{
  my $tfa_home = shift;
  if ( is_prw_running($tfa_home) )
  {
    return 1;
  }
  return 0;
}

sub status
{
  my $tfa_home = shift;
  if ( is_prw_running($tfa_home) )
  {
    print "Procwatcher is running\n\n";
  }
   else
  {
    print "Procwatcher is NOT running\n\n";
  }
  return 0;
}

sub user_running_prw
{
  my $puser = `ps -ef | grep "prw.sh run" | sed 's/^ *//' | grep -v grep | cut -d" " -f1|head -1`;
  chomp($puser);
  return $puser;
}

sub get_prw_runuser
{
  my $tfa_home = shift;

  # If prw is running return user running
  my $puser = user_running_prw ();
  return $puser if ( $puser );

  # # Env
  if ( $ENV{TFA_PRW_RUNUSER} )
  {
    return $ENV{TFA_PRW_RUNUSER};
  }

  # Return the crs user if crs is installed
  my $crs_home = get_crs_home($tfa_home);
  if ( ! $crs_home )
  {
    print "ERROR: Could not find CRS_HOME\n";
    return "";
  }
  my $ofile = catfile($crs_home, "bin", "oracle");
  my $guser = getpwuid((stat($ofile))[4]);
  return "$guser";
}

sub edit_prw_conf
{
  my $tfa_home = shift;
  my $runuser = shift;
  my $cfile = shift;
  my @flags = @_;
  my $editor;

  if ( ! -w $cfile )
  {
    print "Error: The init file $cfile does not exists. Run init first\n";
    return 1; 
  }

  if ( ! $flags[0] )
  {
    my $vi_installed = `which vi >/dev/null 2>&1; echo \$?`;
    chomp($vi_installed);
    if ( $vi_installed == 0 )
    {
      $editor = "vi";
    }
    $editor = $tfactlglobal_ctx{"ed"} if ( $tfactlglobal_ctx{"ed"} );
    if ( ! $editor && $ENV{"TFA_EDITOR"} )
    {
      $editor = $ENV{"TFA_EDITOR"};
    }
    if ( ! $editor )
    {
      print "Error: Could not find vi in path. Please set editor in TFA_EDITOR\n";
      return 1;
    }
     else
    {
      if ( $runuser )
      {
        system("su $runuser -c \"$editor $cfile\"");
      }
       else
      {
        system("$editor $cfile");
      }
    }
  }
   else
  {
    for (my $i=0; $i <= $#flags; $i++)
    { # prw edit [name=val]
      if ( $flags[$i] =~ /^(\w+)\=(.*)/ )
      {
        my $key = $1;
        my $val = $2;
        $val =~ s/\"/\\\"/g;
        system("perl -p -i -e 's/^$key=.*/$key=$val/i' $cfile");
      }
    }
  }
}

sub setup_prw
{
  my $tfa_home = shift;
  my $tool_base = shift;
  my $runuser = shift;
  my $initfile = "";
  if ( $runuser )
  {    
    system("cp -f $tfa_home/ext/prw/prw.sh $tool_base/$runuser/prw.sh");
    system("chmod 740 $tool_base/$runuser/prw.sh");
    system("chown $runuser $tool_base/$runuser/prw.sh");
    system("su $runuser -c \"$tool_base/$runuser/prw.sh init $tool_base/$runuser\"");
    $initfile = "$tool_base/$runuser/prwinit.ora";
  }
   else
  {
    system("cp -f $tfa_home/ext/prw/prw.sh $tool_base/$current_user/prw.sh");
    system("chmod 740 $tool_base/$current_user/prw.sh");
    system("$tool_base/$current_user/prw.sh init $tool_base/$current_user");
    $initfile = "$tool_base/$current_user/prwinit.ora";
  }
  edit_prw_conf($tfa_home, $current_user, "$initfile", "PRWPERM=740");
}

sub run
{
  my $tfa_home = shift;
  my @flags = @_;
  my $runuser = "";
  my $retval = 0;

  if ( grep { $_ =~ /^(-h|-help)$/ } @flags ) {
    $retval = 0;
  }
  if ( ! $flags[0] )
  {
    $flags[0] = "-h";
    $retval = 1;
  }

  my $editfile = 0;
  for (my $i=0; $i <= $#flags; $i++)
  { # prw editconf [name=val]
    if ( $flags[$i] eq "editconf" )
    {
      $editfile = 1;
      splice @flags, $i, 1;
      $i--;
    }
  }
 
  if ( $current_user eq "root" &&  $ENV{AUTOSTART_TOOLS} == 1 )
  {
    $runuser = get_prw_runuser($tfa_home);
    if ( ! $runuser )
    {
      print "Error: Could not find user to run ProcWatcher\n";
      return 1;
    }
    #$tool_base = catfile($tfa_base, "suptools", "$hostname", $tool, $runuser);
    $tool_base = catfile($tfa_base, "suptools", $tool);
    if ( ! -f catfile($tool_base, $runuser, "prwinit.ora") )
    { # Procwatcher should not have host name in path
      setup_prw($tfa_home, $tool_base, $runuser);
    }
    $tool_base = catfile($tool_base, $runuser);
    chdir($tool_base);
    $ENV{PRWDIR} = $tool_base;
    if ( $flags[0] eq "init" && -f "$tool_base/prwinit.ora" )
    {
      my $bkfile = "prwinit.ora.". time();
      system("su $runuser -c \"cp -f $tool_base/prwinit.ora $tool_base/$bkfile\"");
      print "Backed up existing prwinit.ora as $tool_base/$bkfile\n";
    }

    if ( $editfile == 0 )
    {
      system("su $runuser -c \"$tool_base/prw.sh @flags\"");
    }
     else
    {
      edit_prw_conf($tfa_home, $runuser, "$tool_base/prwinit.ora", @flags);
    }
  }
   else
  {
    
    my $puser = user_running_prw ();
    if ( $puser && $puser ne $current_user )
    {
      print "Error: Can't run ProcWatcher as '$current_user' as it is running as a different user.\n";
      return 1;
    }
    $tool_base = catfile($tfa_base, "suptools", $tool);
    $tool_base_new = catfile($tool_base, $current_user);
    if ( ! -f catfile($tool_base_new, "prwinit.ora") )
    { # Procwatcher should not have host name in path
      setup_prw($tfa_home, $tool_base, "");
    }
    $tool_base = $tool_base_new;
    chdir($tool_base);
    $ENV{PRWDIR} = $tool_base;
    if ( $flags[0] eq "init" && -f "$tool_base/prwinit.ora" )
    {
      my $bkfile = "prwinit.ora.". time();
      system("cp -f $tool_base/prwinit.ora $tool_base/$bkfile");
      print "Backed up existing prwinit.ora as $tool_base/$bkfile\n";
    }

    if ( $editfile == 0 )
    {
      system("$tool_base/prw.sh @flags");
    }
     else
    {
      edit_prw_conf($tfa_home, $runuser, "$tool_base/prwinit.ora", @flags);
    }

  }
  return $retval;
}

sub help 
{
  my $tfa_home = shift;
  run($tfa_home, "-h");
}
