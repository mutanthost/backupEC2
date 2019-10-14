# 
# $Header: tfa/src/v2/ext/dbcheck/dbcheck.pm /main/1 2018/08/15 16:55:51 bburton Exp $
#
# dbcheck.pm
# 
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      dbcheck.pm
#
#    DESCRIPTION
#      DBcheck Tool
#
#    NOTES
#      NONE
#
#    MODIFIED   (MM/DD/YY)
#    recornej    05/28/18 - DBCheck Tool
#    recornej    05/28/18 - Creation
#
package dbcheck;
require Exporter;
our @ISA      = qw(Exporter);
our @EXPORT = qw(deploy
                   autostart
                   start
                   stop
                   restart
                   status
                   run
                   runstatus
                   is_running
                  );

use strict;
use warnings;
use Math::BigInt;
use Time::Local;
use File::Copy;
use File::Spec::Functions;
use File::Path;
use File::Basename;
use Getopt::Long qw(GetOptions);
use POSIX qw(:termios_h);
use POSIX qw(strftime);
use Data::Dumper;
use tfactlglobal;
use tfactlshare;
use cmdlocation;

#-------------------
my $tool        = "dbcheck";
my $toolversion = "20180528";
my $tfa_base    = tfactlshare_get_repository_location($tfa_home);
my $tool_dir    = catfile($tfa_base, "suptools","$hostname",$tool);
my $tool_base   = catfile($tfa_base, "suptools","$hostname",$tool, $current_user);

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
  my $help;
  my $dbcheck = catfile($tfa_home,"ext","dbcheck","dbcheck.sh");
  my $fname = "dbcheck_".strftime('%m%d%Y%H%M%S',localtime);
  my $outdir  = catfile($tool_base,$fname);
  
  GetOptions(
    "help"  =>\$help,
    "h"     =>\$help  
  );
  if ( $help ) {
    print_help("dbcheck");
    exit 2;
  }
  
  if ( -d $tool_base ) {
    eval {
      tfactlshare_mkpath("$outdir","1741") if ( ! -d "$outdir" );
    };
    if ( $@ ){
      tfactlshare_signal_exception(210,undef);
    }
    system ("$SH $dbcheck $outdir");
  } else {
    print "Unable to run dbcheck, $tool_base directory does not exist\n";
    exit 1;
  }
}
1;
