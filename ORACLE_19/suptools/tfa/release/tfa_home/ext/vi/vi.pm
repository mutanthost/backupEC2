# 
# $Header: tfa/src/v2/ext/vi/vi.pm /main/9 2018/08/09 22:22:30 recornej Exp $
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
#    recornej    07/19/18 - Fix exit codes.
#    manuegar    11/01/16 - Bug 24948477 - WS2012_122_TFA: HELP INFORMATION FOR
#                           'TFACTL RUN GREP' INCORRECT.
#    arupadhy    07/04/16 - Added windows compatibility
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    gadiga      03/24/15 - fix 20666289. dont show help from remote node
#    gadiga      01/08/15 - change name to vi
#    gadiga      12/15/14 - support db context for any file
#    gadiga      12/15/14 - permission and editor
#    gadiga      11/03/14 - Creation
# 
package vi;
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

my $tool = "vi";
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
  print "vi does not run in daemon mode\n";
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

  if ( ! $args[0] )
  {
    print "Missing file name input\n";
    help ();
    return 1;
  }
   elsif ( $args[0] eq "-h" || $args[0] eq "-help" )
  {
    help();
    return 0;
  }

  my $editor;
  my $vi_installed;
  if($IS_WINDOWS){
    my @output = `where notepad | findstr notepad`;
    if(scalar(@output)>0){
      $editor = $output[0];
    }
  }else{
    $vi_installed = `which vi >/dev/null 2>&1; echo \$?`;
    chomp($vi_installed);
    if ( $vi_installed == 0 )
    {
      $editor = "vi";
    }
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

  $db = $ENV{"TFA_SESSION_DB"} if ( ! $db && defined $ENV{"TFA_SESSION_DB"} );

  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  chdir($tool_base);
  #my $inventoryDirectory = getInventoryLocation( $tfa_home, $hostname );
  #my $inv = catfile($inventoryDirectory, "inventory.xml");

  if ( ! $args[0] )
  {
    help();
    return 1;
  }

  my @alerts = ();
  #my @alerts = `grep $args[0] $inv |grep file_name `;
  my $fpat = $args[0];
  if ( -f $args[0] )
  {
    push @alerts, $args[0];
  }
   else
  {
    @alerts = tfactlshare_get_files ($tfa_home, $fpat, "", "", $tfactlglobal_ctx{"db"},
                                      $tfactlglobal_ctx{"inst"}, "",
                                      $tfactlglobal_ctx{"time"},
                                      $tfactlglobal_ctx{"start-time"},
                                      $tfactlglobal_ctx{"end-time"});
    chomp(@alerts);
  }

  my @dbs = split(/\,/, $db);

  if ( ! $alerts[0] )
  {
    print "Failed to find the file $args[0]\n\n";
    return 1;
  }
  my @files = ();
  foreach my $afile (@alerts)
  {
    $afile =~ s/.file_name.//;
    $afile =~ s/..file_name.//;
    my $run = 0;
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
    if($IS_WINDOWS){
      my $limit = 10;
      foreach my $file (@files){
        if($limit>0){
          system("$editor $file");
          $limit = $limit -1;
        }else{
          last;
        }
      }
    }else{
      system("$editor @files");
    }
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
    $func = "notepad";
  }else{
    $func = "vi";
  }
  print "Usage : $cmd [run] $func <file name pattern>\n";
  print "\n      Opens all files matching input pattern in $func\n\n";
  print "e.g:\n";
  print "   $cmd $func alert_\n";
  print "   $cmd $func testdb1_pmon_1234.trc\n\n";
  print "   $cmd run $func alert_\n";
  print "   $cmd run $func testdb1_pmon_1234.trc\n\n";
  return 0;
}

