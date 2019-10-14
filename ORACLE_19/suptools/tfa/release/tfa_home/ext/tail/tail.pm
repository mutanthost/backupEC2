# 
# $Header: tfa/src/v2/ext/tail/tail.pm /main/10 2018/08/09 22:22:30 recornej Exp $
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
#    recornej    07/19/18 - Fix exit codes
#    llakkana    10/31/17 - Add support to tail file with full path
#    llakkana    02/02/17 - Add a flag to do exact match
#    manuegar    11/02/16 - Bug 24948477 - WS2012_122_TFA: HELP INFORMATION FOR
#                           'TFACTL RUN GREP' INCORRECT.
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    gadiga      03/24/15 - fix 20666289. dont show help from remote node
#    gadiga      12/15/14 - support db context for any file
#    gadiga      12/15/14 - check permission
#    gadiga      11/03/14 - Creation
# 
package tail;
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

my $tool = "tail";
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

sub runstatus 
{
  return 3;
}

sub is_running 
{
  return 2;
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
  print "tail cannot be started in daemon mode.\n";
  return 0;
}

sub run
{
  my $tfa_home = shift;
  my @args = @_;
  my $db;
  my @flags = ();
  my $exact_match = 0;
  my $short_fn;

  if ( $args[0] eq "-h" || $args[0] eq "-help" )
  {
    help();
    return 0;
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
    elsif ( $args[$i] eq "-exact" ) {
      $exact_match = 1;
      splice @args, $i, 1;
      $i--;
    }
     elsif ( $args[$i] =~ /^\-/ )
    { 
      push @flags, $args[$i];
      splice @args, $i, 1;
      $i--;
    }
  }

  if ( ! $args[0] )
  {
    print "Missing file name input @args\n";
    help();
    return 1;
  }
  $db = $ENV{"TFA_SESSION_DB"} if ( ! $db && defined $ENV{"TFA_SESSION_DB"} );

  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  chdir($tool_base);
  my $localhost = tolower_host();
  my $inventoryDirectory = getInventoryLocation( $tfa_home, $hostname );
  my $inv = catfile($inventoryDirectory, "inventory.xml");

  my @alerts = `grep '<file_name>' $inv | grep -i $args[0]`;
  chomp(@alerts);
  my @dbs = split(/\,/, $db);

  if ( ! $alerts[0] )
  {
    print "Failed to find the file $args[0] in $inv\n\n";
    return 1;
  }
  my @files = ();
  foreach my $afile (@alerts)
  {
    $afile =~ s/.file_name.//;
    $afile =~ s/..file_name.//;
    my $run = 0;
    $short_fn = $1 if $afile =~ /.*\/([^\/]+)$/;
    #&& condition in below if/else is to support tail a file with full path
    if ( $exact_match ) {
      next if $short_fn ne $args[0] && $afile ne $args[0];
    }
    else {
      #Results returned by tfactlshare_get_files are matching dir path also. 
      #But we have to match with only file name
      next if $short_fn !~ $args[0] && $afile ne $args[0];
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
        push @files, $afile;
      }
      #print "\n\nReading $afile \n";
      #print "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-\n\n";
    }
  }
  if ( ! $files[0] )
  {
    print "Error: Could not find the file\n";
    return 1;
  }
   else
  {
    system("tail @flags @files");
  }
  return 0;
}

sub help
{
  print "Usage : $0 [run] tail [-f] <file name pattern> [-exact]\n";
  print "\n      Tail all files matching input pattern\n";
  print "\n	 -exact : Do exact matching instead of pattern matching.\n\n";
  print "e.g:\n";
  print "   $0 tail alert_\n";
  print "   $0 tail -f alert_testdb1.log\n";
  print "   $0 run tail alert_\n";
  print "   $0 run tail -f alert_testdb1.log -exact\n";
  print "\nNote: -f flag is not supported on remote nodes\n";
  return 0;
}

