# 
# $Header: tfa/src/v2/ext/ls/ls.pm /main/8 2018/08/09 22:22:30 recornej Exp $
#
# ls.pm
# 
# Copyright (c) 2015, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      ls.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    07/19/18 - Fix exit codes
#    manuegar    10/09/17 - Bug 26891075 - ERROR: CAN NOT RUN 'FINDSTR' AS USER
#                           DIRECTORIES ARE NOT YET SETUP.
#    llakkana    02/02/17 - Add a flag to do exact match as it is doing reqex
#                           match right now
#    manuegar    11/01/16 - Bug 24948477 - WS2012_122_TFA: HELP INFORMATION FOR
#                           'TFACTL RUN GREP' INCORRECT.
#    arupadhy    07/04/16 - Added windows compatibility
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    gadiga      03/24/15 - fix 20666289. dont show help from remote node
#    gadiga      01/08/15 - list files
#    gadiga      01/08/15 - Creation
# 
package ls;
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

my $tool = "ls";
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
  print "ls does not run in daemon mode\n";
  return 0;
}

sub run
{
  my $tfa_home = shift;
  my @args = @_;
  my $db;
  my $exact_match = 0;
  my $short_fn;

  for (my $i=0; $i <= $#args; $i++)
  {
    if ( $args[$i] eq "-database" || $args[$i] eq "-db" )
    {
      $db = $args[$i+1];
      splice @args, $i, 1;
      splice @args, $i, 1;
      $i--;
    }
    elsif ( $args[$i] eq "-exact" ) {
      $exact_match = 1; 
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
    print "Missing file name input\n";
    help ();
    return 1;
  }

  $db = $ENV{"TFA_SESSION_DB"} if ( ! $db && defined $ENV{"TFA_SESSION_DB"} );

  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  chdir($tool_base);
  my $inventoryDirectory = getInventoryLocation( $tfa_home, $hostname );
  my $inv = catfile($inventoryDirectory, "inventory.xml");

  if ( ! $fpat )
  {
    help();
    return 1;
  }

  my @alerts = tfactlshare_get_files ($tfa_home, $fpat, "", "", $tfactlglobal_ctx{"db"}, 
                                      $tfactlglobal_ctx{"inst"}, "",
                                      $tfactlglobal_ctx{"time"}, 
                                      $tfactlglobal_ctx{"start-time"}, 
                                      $tfactlglobal_ctx{"end-time"});
  chomp(@alerts);
  my @dbs = split(/\,/, $db);

  if ( ! $alerts[0] )
  {
    print "Failed to find the file $fpat in $inv\n\n";
    return 1;
  }
  my @files = ();
  foreach my $afile (@alerts)
  {
    $afile =~ s/.file_name.//;
    $afile =~ s/..file_name.//;    
    my $run = 0;
    $short_fn = $1 if $afile =~ /.*[\/\\]([^\/^\\]+)$/;
    if ( $exact_match ) {
      next if $short_fn ne $fpat;
    }
    else {
      #Results returned by tfactlshare_get_files are matching dir path also. 
      #But we have to match with only file name
      next if $short_fn !~ $fpat;
    }

    if ( ! $dbs[0] )
    {
      $run = 1;
    }
     else
    {
      foreach $db ( @dbs )
      {
        $run = 1 if ( $afile =~ /$db/i );
      }
    }
    if ( $run == 1 )
    {
      if ( ! -r $afile )
      {
        print "Ignoring $afile as file does not have read permission to user.\n";
      }
       else
      {
        if ( @args )
        {
          my $l = `$LS @args $afile`;
          chomp($l);
          print "$l\n";
        }
         else
        {
          print "$afile\n";
        }
        push @files, $afile;
      }
    }
  }
  if ( ! $files[0] )
  {
    print "Error: Could not find the file\n";
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
  my $func;
  if($IS_WINDOWS){
    $func = "dir";
  }else{
    $func = "ls";
  }
  print "Usage : $cmd [run] $func <flags> <file name pattern> [-exact]\n";
  print "\n      Lists all files matching input pattern in $func\n";
  print "\n      <flags> All $func flags are supported.\n";
  print "\n	 -exact : Do exact matching instead of pattern matching.\n\n";
  print "e.g:\n";
  print "   $cmd $func alert_\n";
  print "   $cmd $func <flags> testdb1_pmon_1234.trc\n";
  print "   $cmd run $func alert_\n";
  print "   $cmd run $func <flags> testdb1_pmon_1234.trc\n";
  print "   $cmd $func <flags> alert.log -exact\n\n";
  return 0;
}

