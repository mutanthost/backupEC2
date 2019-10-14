# 
# $Header: tfa/src/v2/ext/alertsummary/alertsummary.pm /main/14 2018/08/09 22:22:30 recornej Exp $
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
#    recornej    07/31/18 - Fix exit codes.
#    manuegar    11/02/16 - Bug 24948477 - WS2012_122_TFA: HELP INFORMATION FOR
#                           'TFACTL RUN GREP' INCORRECT.
#    arupadhy    07/07/16 - Help correction
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    llakkana    04/09/16 - Use tline129 version
#    llakkana    01/05/16 - Fix 22488450
#    llakkana    10/08/15 - Fix 21478729
#    gadiga      06/24/15 - fix 21031777
#    gadiga      05/19/15 - fix 20880615
#    gadiga      03/24/15 - fix 20666289. dont show help from remote node
#    gadiga      12/15/14 - permission
#    gadiga      11/03/14 - Creation
# 
package alertsummary;
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
use Getopt::Long;
use List::Util qw[min max];
use POSIX qw(:termios_h);

use File::Basename;
use File::Spec::Functions;
use File::Path;

my $tool = "alertsummary";
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
  print "alertsummary does not run in daemon mode\n";
  return 0;
}

sub run
{
  my $tfa_home = shift;
  my @args = @_;
  my $db;
  my $help;
  my @args_bkp;

  @args_bkp = @ARGV;
  @ARGV = @args;
  GetOptions (
   "h" => \$help,
   "help" => \$help,
   "db=s" => \$db,
   "database=s" => \$db);
  @args = @ARGV;
  @ARGV = @args_bkp;

  my $argsleft = scalar(@args);

  if ( $help || $argsleft ) {
    print "Invalid option $args[0]\n" if $argsleft > 0;
    help();
    return 0 if ($help);
    return 1;
  }

  $db = $ENV{"TFA_SESSION_DB"} if ( ! $db && defined $ENV{"TFA_SESSION_DB"} );

  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  chdir("$tool_base");
  my $localhost = tolower_host();
  my $inventoryDirectory = getInventoryLocation( $tfa_home, $hostname );
  my $inv = catfile($inventoryDirectory, "inventory.xml");
  my @alerts = `grep alert_ $inv`;
  chomp(@alerts);
  my @dbs = split(/\,/, $db);

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
      if ( -r $afile )
      {
        print "\n\nReading $afile \n";
        print "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-\n\n";
        my $awk = `which gawk 2>/dev/null`;
        chomp($awk);
	#If Solaris10 does not has gawk use awk from /usr/xpg4/bin/awk instead of default awk
	my $sawk = catfile("","usr","xpg4","bin","awk");
        if ( ! -f $awk && -f $sawk ) {
	  $awk = $sawk;
        }
        if ( ! -f $awk )
        {
          $awk = "awk";
        }
        system("$awk -f $tfa_home/ext/alertsummary/tline.awk $afile|grep -v tline.awk ");
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
  print "Usage : $cmd [run] alertsummary [-database <dbname>|-db <dbname>]\n";
  print "\n      Prints summary of important events in database/ASM alert logs\n\n";
  print "e.g:\n";
  print "   $cmd alertsummary\n";
  print "   $cmd alertsummary -database testdb1\n\n";
  print "   $cmd run alertsummary\n";
  print "   $cmd run alertsummary -database testdb1\n\n";
  print "In tfactl shell, if a database context is set, only the alert log from database is analyzed.\n";
  return 0;
}
