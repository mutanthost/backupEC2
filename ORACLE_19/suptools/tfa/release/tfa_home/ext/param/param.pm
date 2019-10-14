# 
# $Header: tfa/src/v2/ext/param/param.pm /main/9 2018/08/09 22:22:30 recornej Exp $
#
# param.pm
# 
# Copyright (c) 2015, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      param.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    07/19/18 - Fix exit codes.
#    recornej    08/02/17 - Bug 24957744 - TFACTL PARAM FOR DATABASE NOT
#                           WORKING AS EXPECTED
#    manuegar    11/02/16 - Bug 24948477 - WS2012_122_TFA: HELP INFORMATION FOR
#                           'TFACTL RUN GREP' INCORRECT.
#    arupadhy    07/04/16 - Added windows compatibility
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    gadiga      06/09/15 - read .mv files also
#    gadiga      03/24/15 - fix 20666289. dont show help from remote node
#    gadiga      02/23/15 - update help text
#    gadiga      01/28/15 - print parameter
#    gadiga      01/28/15 - Creation
# 
package param;
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
use Text::ASCIITable;
use File::Basename;
use File::Spec::Functions;
use File::Path;

my $tool = "param";
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
  my $db;
  my $help;
  my $host;
  my $instance;
  my @args;

  if ( scalar(@_) == 0 ){
    help();
    return 1;
  } 
  my $pname = shift;

  if ( $pname eq "-h" || $pname eq "-help" ) {
    help();
    return 0;
  }

  @args = @_;
  my @args_bkp = @ARGV;
  @ARGV = @args;

  GetOptions (
    "help" => \$help,
    "h"=> \$help,
    "db=s" => \$db,
    "database=s" => \$db,
    "host=s"=>\$host,
    "inst=s"=>\$instance
  );
  @args = @ARGV;
  @ARGV = @args_bkp;

  if ( $help ) {
    help();
    return 0;
  }
  if ( not $pname ) {
    print "<name pattern> missing!\n";
    help();
    return 1;
  }
  if ( ($instance  and $db)
    || ($instance and $host)
    || ($instance and $db and $host)){
    print "Instance implies db and host so ignoring db and/or host if provided!\n";
    $db = "";
    $host ="";
  }
  #Check  global context, giving priority to the switches.
  if ( $db ){
     my $pfile = catfile($tfa_home, "internal","dbparams","$db.param.out");
     if ( ! -e "$pfile" ) {
       my $ohome = tfactlshare_get_oracle_home($tfa_home, $db);
       if ( $ohome eq "NOT FOUND" || $ohome eq ""){
         print "Error: Failed to find database $db\n";
         return 1;
       }
     } 
  }
  if ( $host ) {
    if ( $host ne $hostname ){
      my @listOfNodes = getListOfOtherNodes ( $tfa_home );
      if ( scalar(@listOfNodes) > 0 ) {
         if (! ( grep { /$host/ } @listOfNodes ) ){
            print "Error: Failed to find $host\n";
            return 1;
         }
      } else {
        print "Error: Failed to find host $host\n";
        return 1;
      }
    }
  }

  if ( $instance ) {

    my $path = catfile($tfa_home,"internal","dbparams","*.params.out");
    my @out = ();
    if ( ! $IS_WINDOWS){
      @out = `grep -i '\.$instance\.' $tfa_home/internal/dbparams/*.param.out 2>/dev/null | head -1`;
    } else { 
      @out = `findstr /I "\.$instance\." "$path" > head && set /p line=<head && del head && echo %line%`;
    }
    chomp(@out);
    $out[0] =~ s/\.[^.]*$//; #dbparam.db.node1
    $out[0] =~ s/.*://i; #dbparam.db.node1
    if ( $out[0] =~ /(.*)\.(.*)\.(.*)/ )
    {
      $db = $2;
      $host = $1;
      $instance = $3;
    }
      else
    {
      print "Error: Failed to find instance $instance\n";
      return 1;
    }
  }

  $host = $tfactlglobal_ctx{"host"} if ( not $host and defined $tfactlglobal_ctx{"host"} );
  $db = $tfactlglobal_ctx{"db"} if ( not $db and defined $tfactlglobal_ctx{"db"} );
  $instance = $tfactlglobal_ctx{"inst"} if ( not $instance and defined $tfactlglobal_ctx{"inst"} );

  my $outputdir = tfactlshare_get_tfa_metadata_loc($tfa_home);
  chdir("$outputdir");
  my @pfiles = ("params.out", "params.out.mv");
  my @pfiles_e = ();
  foreach my $pfile (@pfiles )
  {
    push @pfiles_e, $pfile if ( -f "$pfile" );
  }
  my @out = ();
  if ( $pfiles_e[0] )
  {
    if($IS_WINDOWS){
      @out = `findstr /I '$pname' @pfiles_e`;
    }else{
      @out = `grep -i '$pname' @pfiles_e`;
    }
  }
  chomp(@out);
  my $T_HASROWS  = FALSE;
  my $T2_HASROWS = FALSE;
  my $T3_HASROWS = FALSE;
  my %params =();
  #============Table that contains dbparams ===================
  my $table = Text::ASCIITable->new({headingText => 'DBPARAMS'});
  $table->setCols("DATABASE","HOST","INSTANCE","PARAM","VALUE");
  $table->setOptions({"outputWidth" => $tputcols});

  #======Table that contains other params distinct that dbparams and ospkg========
  my $table2 = Text::ASCIITable->new();#{headingText => 'OSPARAMS'});
  $table2->setCols("PARAM","VALUE");
  $table2->setOptions({"outputWidth" => $tputcols});

  #========Table that contains OSPKG parameters================
  my $table3 = Text::ASCIITable->new({headingText => 'OSPKG'});
  $table3->setCols("VALUE");
  $table3->setOptions({"outputWidth" => $tputcols});

  foreach my $line (@out)
  {
    if ( $line =~ /(.*) PARAM: (\w+)\.(.*) = (.*)/ )
    {
      my $tsp = $1;
      my $typ = $2;
      my $key = $3;
      my $val = $4;
      if ( $key =~ /$pname/i )
      { 
        if ( $typ eq "ospkg" )
        { 
          #print "$key\n";
          $table3->addRow($key);
          $table3->addRowLine();
          $T3_HASROWS = TRUE if ( ! $T3_HASROWS );
        } 
         else 
        { 
          #Filter contexts 
          if ($typ eq "dbparam"){
            my ($dbp,$hostp,$dbp1,$instp,$param) = split /\./ ,$key ;
            my $valid = TRUE;
            if ( $db ){
              $valid = FALSE if ( $db !~ /^$dbp$/i );
            }
            if ( $host ) {
              $valid = FALSE if ( $host !~ /^$hostp$/i );
            }
            if ( $instance ) {
              $valid = FALSE if ( $instance !~ /^$instp$/i );
            }
            if ( $valid){
              $table->addRow($dbp,$hostp,$instp,$param,$val);
              $table->addRowLine();
              $T_HASROWS = TRUE if ( ! $T_HASROWS );
            }
          } else {
            if ( not defined $params{$typ}){
              $params{$typ}=$typ;
            }
            $table2->addRow($key,$val);
            $table2->addRowLine();
            $T2_HASROWS = TRUE if ( ! $T2_HASROWS);
          }
        } 
      } 
    }
  }
  if ($T_HASROWS){
    print $table;
  }
  if ( $T2_HASROWS) {
    my $keys = join(',',keys %params);
    $keys = uc($keys);
    $table2->setOptions({headingText => $keys });
    print $table2;
  }
  if ( $T3_HASROWS ) {
    print $table3;
  }
  return 0;
}

sub help
{
  my $cmd;
  if ( $0 =~ /(.*)\.pl/ ) {
    $cmd = $1;
  }
  print "Usage : $cmd [run] param <name pattern>\n";
  print "\n      Show value of OS/DB parameters matching input\n\n";
  print "e.g:\n";
  print "   $cmd param sga_max\n";
  print "   $cmd param shmmax\n\n";
  print "   $cmd run param sga_max\n";
  print "   $cmd run param shmmax\n\n";
  return 0;
}

