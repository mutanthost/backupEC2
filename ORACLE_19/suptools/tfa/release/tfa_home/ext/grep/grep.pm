# 
# $Header: tfa/src/v2/ext/grep/grep.pm /main/14 2018/08/09 22:22:30 recornej Exp $
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
#    manuegar    11/02/16 - Bug 24948477 - WS2012_122_TFA: HELP INFORMATION FOR
#                           'TFACTL RUN GREP' INCORRECT.
#    arupadhy    07/04/16 - Added windows compatibility
#    llakkana    06/21/16 - Decode .SPACE. in arguments
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    llakkana    04/13/16 - Bug 23097133 - Fix help
#    gadiga      04/02/15 - fix 20810752
#    gadiga      03/24/15 - fix 20666289. dont show help from remote node
#    gadiga      03/12/15 - fix message
#    gadiga      01/08/15 - change to grep and support all flags
#    gadiga      12/15/14 - support db context for any file
#    gadiga      12/15/14 - permission
#    gadiga      11/03/14 - Creation
# 
package grep;
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

my $tool = "grep";
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
  print "grep does not run in daemon mode\n";
  return 0;
}

sub run
{
  my $tfa_home = shift;
  my @args = @_;
  my $db;

  if ( $args[0] eq "-h" || $args[0] eq "-help")
  {
    help();
    return 0;
  } elsif ( ! $args[0] || ! $args[1] ){
    help();
    return 1;
  }

  my $fpat = "";
  my $spat = "";
  #my @gflags = ("-n", "-i");
  my @gflags;
  if($IS_WINDOWS){
    @gflags = ("/N");
  }else{
    @gflags = ("-n");
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
  }

  $fpat = pop @args;
  $spat = pop @args;
  #Decode .SPACE. to space if any in the search pattern
  $spat =~ s/\.SPACE\./ /g;
  if ( @args )
  {
    @gflags = @args;
  }

  if ( ! $spat || ! $fpat )
  {
    help();
    return 1;
  } 

  $db = $ENV{"TFA_SESSION_DB"} if ( ! $db && defined $ENV{"TFA_SESSION_DB"} );

  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  chdir($tool_base);
  my $localhost = tolower_host();
  my $inventoryDirectory = getInventoryLocation( $tfa_home, $hostname );
  my $inv = catfile($inventoryDirectory, "inventory.xml");

  #my @alerts = `grep file_name $inv |grep '$fpat'`;
  my @alerts = tfactlshare_get_files ($tfa_home, $fpat, "", "", $tfactlglobal_ctx{"db"},
                                      $tfactlglobal_ctx{"inst"}, "",
                                      $tfactlglobal_ctx{"time"},
                                      $tfactlglobal_ctx{"start-time"},
                                      $tfactlglobal_ctx{"end-time"});

  chomp(@alerts);
  my @dbs = split(/\,/, $db);

  $spat =~ s/^\"//;
  $spat =~ s/\"$//;
  print "Searching '$spat' in $fpat\n";
  foreach my $afile (@alerts)
  {
    $afile =~ s/.file_name.//;
    $afile =~ s/..file_name.//;
    my $run = 1;
    if ( $dbs[0] )
    {
      $run = 0;
      foreach $db ( @dbs )
      {
        $run = 1 if ( $afile =~ /$db/i );
      }
    }

    if ( $run == 1 )
    {
      if ( -r $afile )
      {
        print "\n\nSearching $afile \n";
        print "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-\n\n";
        if($IS_WINDOWS){
          system("findstr @gflags /c:\"$spat\" $afile");
        }else{
          system("grep @gflags '$spat' $afile");
        }
      }
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
    $func = "findstr";
  }else{
    $func = "grep";
  }
  print "Usage : $cmd [run] $func <flags> <search string> <file name pattern>\n";
  print "\n      $func for <search string> in all files matching input pattern\n\n";
  print "\n      <flags> All $func flags are supported.\n\n";
  print "e.g:\n";
  print "   $cmd $func \"Starting oracle instance\" alert\n";
  print "   $cmd run $func \"Starting oracle instance\" alert\n";
  print "   Which will $func for \"Starting oracle instance\" in all files like %alert%\n\n";
  return 0;
}    

