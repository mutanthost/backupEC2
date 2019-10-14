# 
# $Header: tfa/src/v2/ext/dbperf/dbperf.pm /main/12 2018/05/28 15:06:26 bburton Exp $
#
# dbperf.pm
# 
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      dbperf.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    05/14/18 - Change report to awr_reports.
#    recornej    03/06/18 - Fix permission denied  when getcwd is used in AIX.
#    recornej    12/05/17 - Adjust reports to allow generation of AWR without
#                           baseline time range
#    recornej    10/11/17 - Moving hanganalyze to dbutil module
#    manuegar    08/14/17 - Bug 26619915 - LNX64-12.2-TFA:ORATOP DOES NOT WORK
#                           WHEN DB UNIQUE NAME DIFFERS FROM DBNAME.
#    recornej    07/31/17 - Fixed srdc_ora4031 uses incident time to run awr.
#    recornej    07/04/17 - BUG 25985797 - SRDC AUTOMATION:ENHANCE DBPERF SRDC
#                           TO INCLUDE OTHER COLLECTIONS
#    recornej    07/13/17 - Adding runawr changes
#    recornej    06/21/17 - Bug 25989266 - LNX64-12.2-TFA:DBPERF DBSLOW HIT
#                           USE OF UNINITIALIZED VALUE
#    bburton     05/25/17 - Do not run ash for 12.2
#    bburton     03/21/17 - Convert SPACE to an actual space
#    bburton     03/07/17 - fix perl
#    bburton     01/17/17 - Fix for SRDC call
#    bburton     11/09/16 - add options to just runawr
#    manuegar    11/02/16 - Bug 24948477 - WS2012_122_TFA: HELP INFORMATION FOR
#                           'TFACTL RUN GREP' INCORRECT.
#    bburton     11/01/16 - Fix issue with get base/repository
#    bburton     09/22/16 - Make work for srdc dbperf
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    bburton     01/25/16 - Database Performance tool driver
#    bburton     01/25/16 - Creation
# 
#
########
#
package dbperf;
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
use Math::BigInt;
use Time::Local;
use tfactlglobal;
use tfactlshare;
use dbutil;
use Getopt::Long;
use List::Util qw[min max];
use POSIX qw(:termios_h);
use POSIX qw(strftime);
use Cwd;
use Cwd qw(chdir);
use File::Basename;
use File::Spec::Functions;
use File::Path;

my $tool = "dbperf";
my $toolversion = "20170331";
my $tfa_base = tfactlshare_get_repository_location($tfa_home);
my $tool_dir = catfile($tfa_base, "suptools", "$hostname", $tool);
my $tool_base = catfile($tfa_base, "suptools", "$hostname", $tool, $current_user);
my $PERL = tfactlshare_getPerl($tfa_home);


sub deploy 
{
  my $tfa_home = shift;
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

sub autostart
{
  return 0;
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
  print "Noting to do!\n";
  return 0;
}

sub status
{
  print "DBPERF does not run in daemon mode\n";
  return 0;
}

sub run
{
  my $tfa_home = shift;
  my $cmd = ""; 
  my $help;
  my $exp_cmd="";
  my $db="";
  my $database="";
  my $perf_good_st;
  my $perf_good_et;
  my $perf_bad_st;
  my $perf_bad_et;
  my $inc_time;
  my $fromsrdc;
  my $tool_out_dir;
  my $now_string;
  my $issuenow;
  my $awrlicense;
  my $slow_sqlID;

  my @args;

  
  if ( scalar(@_) == 0 ) {
    help();
    return 2;
  }

  my $dbperf = shift;

  if ( $dbperf eq "-h" || $dbperf eq "-help" ) {
    help();
    return 2;
  }elsif($dbperf ne "dbslow" 
      && $dbperf ne "dbhang"
      && $dbperf ne "runawr"
      && $dbperf ne "slowsql"
      && $dbperf ne "awr_reports"){
    print "Not a valid dbperf option. Exiting...\n";
    exit 0;
  }

  @args = @_;

  
  my @args_bkp;

  @args_bkp = @ARGV;
  @ARGV = @args;
  GetOptions (
    "h" => \$help,
    "help" => \$help,
    "db=s" => \$db,
    "fromsrdc=s" => \$fromsrdc,
    "database=s" => \$db,
    "inc_time=s" => \$inc_time,
    "perf_good_st=s" => \$perf_good_st,
    "perf_good_et=s" => \$perf_good_et,
    "perf_bad_st=s" => \$perf_bad_st,
    "perf_bad_et=s" => \$perf_bad_et,
    "license=s" =>\$awrlicense,
    "issuenow=s" =>\$issuenow,
    "sqlid=s" =>\$slow_sqlID,
  ) or die("Unknown option");
  @args = @ARGV;
  @ARGV = @args_bkp;  

  if ( $help ) {
    help();
    return 2;
  } 
  
  # Check to see if ENV is set up ..
  if ( ! $ENV{TFA_ORACLE_USER} ) {
    # set up the env for a database 
    if ( $database ) {
          $db = $database;
    } 
    if ( ! $db ) {
        print "Please enter Database Name:\n";
        chomp ($db = <STDIN>);
     }
     my $ret = dbutil_setOraEnv($tfa_home, $db,"",TRUE);
     if ( $ret != 0 ) {
      print "Database $db is not running unable to run performance collection \n";
      exit 0;
     }
  }

  if ( ! $ENV{TFA_ORACLE_USER} ) {
    print "Failed to set Database Environment for Database $db. Exiting ...\n";
    return 0;
  }

  # Create a directory for this run if needed and cd to it
  if ( $fromsrdc ) {
    print "Using $fromsrdc for now_string due to SRDC Driven execution\n";
    $now_string = $fromsrdc;
  } else {
    $now_string = strftime("%m-%d-%y-%H:%M:%S",localtime());
  }
  $tool_out_dir = catfile($tool_base,$db . "-$now_string");
  mkdir($tool_out_dir);  
  chdir($tool_out_dir);
  print "Using $tool_out_dir for dbperf $dbperf\n";

  # remove the .SPACE. if it is in the args
  $inc_time =~ s/.SPACE./ /g if length $inc_time; 
  $perf_bad_st =~ s/.SPACE./ /g if length $perf_bad_st; 
  $perf_bad_et =~ s/.SPACE./ /g if length $perf_bad_et; 
  $perf_good_st =~ s/.SPACE./ /g if length $perf_good_st; 
  $perf_good_et =~ s/.SPACE./ /g if length $perf_good_et; 
  # runawr
  if ( $dbperf eq "runawr") {
    if( $inc_time ){
      $inc_time = tfactlshare_convertDateStringforCRS($inc_time);
      $perf_bad_st = tfactlshare_adjust_time_by_seconds($inc_time,"subtract",1800);
      $perf_bad_et = tfactlshare_adjust_time_by_seconds($inc_time,"add", 1800); 
    }
    runawr($fromsrdc,$perf_bad_st,$perf_bad_et, $issuenow,$tool_out_dir);

  } 
  #dbslow 
  if ( $dbperf eq "dbslow") {
    dbslow($fromsrdc,$perf_good_st,$perf_good_et,$perf_bad_st,$perf_bad_et, $db, $issuenow, $awrlicense,$slow_sqlID,$tool_out_dir);
  }
  if($dbperf eq "slowsql") {
    #Check that contains sqlid
    slowsql($slow_sqlID,$tfa_home,$db,$awrlicense);
  }
  if($dbperf eq "dbhang"){

    my @out = dbutil_hanganalyze();
    my @errors = grep{$_ =~ /ORA\-[0-9]+/} @out;
    if( scalar(@out) > 0 && scalar(@errors) == 0 ){
      my $dir =  $IS_AIX ? $ENV{'PWD'} : getcwd(); # getcwd() in AIX returns permission denied even though user has the right permissions
      my $filename = fileparse($out[scalar(@out)-1]);
      $dir = catfile("$dir",$filename);
      system("$CP $out[scalar(@out)-1] $dir");
    }
    print "Hanganalyze errors @errors\n"  if ( scalar(@errors) > 0 );
    print "Finished running hanganalyze\n"; 
  }
  if($dbperf eq "awr_reports"){#Only support this option from srdc from now. 
    if ($fromsrdc){
      my $statspack = FALSE;
      generate_reports($tfa_home,$fromsrdc,$awrlicense,$db,$perf_bad_st,$perf_bad_et,$perf_good_st,$perf_good_et,$issuenow,\$statspack);
    } else {
      print "Not a valid dbperf option. Exiting ...!\n";
      exit 0;
    }
  }
    return 0;

}

sub help 
{
  #print "Usage: ./tfactl dbperf [-problem dbslow | dbhang | procslow | prochang | highcpu | slowsql] [ -db | -database <dbName> ]  \n
  print "Usage: ./tfactl dbperf [dbslow | dbhang | slowsql | runawr ] [ -db | -database <dbName> ]  \n
    Example:\n 
    ./tfactl dbperf dbslow  -db orcl 
    ./tfactl dbperf slowsql -db orcl
    ./tfactl dbperf dbhang  -db orcl
    ./tfactl dbperf runawr  -db oracl\n\n";
}

#################
## NAME
##    generate_reports
##
## DESCRIPTION
## 
##    This function creates AWR Reports if a DIAGNOSTIC license is present 
##    if there is not a DIAGNOSTIC license it will look for Statspack, if 
##    statspack is installed it will create a statspack report, otherwise no report 
##    will be generated.
##
## PARAMETERS 
##    $tfa_home          (IN)  TFA_HOME
##    $license           (IN)  Awr license 
##    $db                (IN)  Database Name
##    $dbperf_bad_st     (IN)  Start Date-Time when performance was bad. 
##    $dbperf_bad_et     (IN)  End   Date-Time when performance was bad.
##    $dbperf_good_st    (IN)  Start Date-Time when performance was good.
##    $dbperf_good_et    (IN)  End   Date-Time when performance was good.
##    $issuenow          (IN)  Issue Now flag.
##
## RETURNS
##    NULL
##
## NOTES
##    NONE
#################

sub generate_reports
{ 
  my $tfa_home =shift;
  my $fromsrdc =shift;
  my $license = shift;
  my $db = shift; 
  my $dbperf_bad_st=shift;
  my $dbperf_bad_et=shift;
  my $dbperf_good_st=shift;
  my $dbperf_good_et=shift;
  my $issuenow = shift; 
  my $statspack = shift;

  if( $license =~ /DIAGNOSTIC/ ){
       print "Running AWR ... \n";
       #Check snapshots 
       #tfactlshare_trace(5,"tfactl (PID =$$) tfactldbperf ".  "in dbslow about to call bad tfactlshare_awrsnaps tfahome $tfa_home ,count, db $db, from $dbperf_bad_st to $dbperf_bad_et",'y','y');
       my $snapcount = 0;
       $snapcount = tfactlshare_awrsnaps($tfa_home,"count",$db,$dbperf_bad_st,$dbperf_bad_et);
       print "Found $snapcount snapshot(s) for Bad Performance time range in $db \n";
       if( !$snapcount ){
         print "Error: No snapshots exist for Bad Performance time range in database $db, Please select a time AWR snapshots exist for the Bad Performance time range\n";
         #goto CONTINUE;
         return;
       }
       my $snap_file = "tfa_dbperf_awr_all_snapshots";
       if ( $dbperf_good_st && $dbperf_good_et ) {
         $snapcount = tfactlshare_awrsnaps($tfa_home, "count", $db,$dbperf_good_st,$dbperf_good_et);
         print "Found $snapcount snapshot(s) for baseline time range in $db \n";
       }
       if (not $fromsrdc){
          my @allsnaps = tfactlshare_awrsnaps($tfa_home,"listall",$db);
          open ( OUTF, "> $snap_file");
          foreach my $snapline (@allsnaps) {
            print OUTF "$snapline\n";
          }
          close(OUTF);
        }
       if (  ! $snapcount && $dbperf_good_st ) {
         print "Error: No snapshots exist for baseline time range in database $db, Please select a time AWR snapshots exist for the baseline (Good) Performance time range. \n";
         #goto CONTINUE;
         return;
       }

       runscript("runawr.pl","-bad",$dbperf_bad_st,$dbperf_bad_et);
       runscript("runawr.pl","-good",$dbperf_good_st,$dbperf_good_et) if ( $dbperf_good_st && $dbperf_good_et );
       runscript("runawrcompare.pl","",$dbperf_good_st,$dbperf_good_et,$dbperf_bad_st,$dbperf_bad_et) if ($dbperf_good_st && $dbperf_good_et);
       my $minversion = 12200;
       my $activeversion = $ENV{"TFA_ORACLE_VERSION"};
       $activeversion =~ s/\.//g;
       if ( $activeversion >= $minversion ) {
         print "Not Running ASH reports for DB12.2 and higher as ASH is in AWR report\n";
       } else {
         runscript("runash.pl","-bad",$dbperf_bad_st,$dbperf_bad_et);
         runscript("runash.pl","-good",$dbperf_good_st,$dbperf_good_et)if( $dbperf_good_st && $dbperf_good_et );
       }    
       runscript("runaddm.pl","",$dbperf_bad_st,$dbperf_bad_et);
   } else {
     #Statspack Report
     if ( tfactlshare_is_statspack_installed($tfa_home,$db) ){
         my @out = generate_statspack_report($tfa_home,$dbperf_bad_st,$dbperf_bad_et,$db,"bad",$issuenow);
         @out = generate_statspack_report($tfa_home,$dbperf_good_st,$dbperf_good_et,$db,"baseline",$issuenow) if ( $dbperf_good_st && $dbperf_good_et);
         $$statspack = TRUE; 
     } else {
        print "Statspack is not installed. Unable to generate statspack report\n";
     }
   }

}

sub runawr
{
      my $fromsrdc = shift;
      my $starttime = shift;
      my $endtime =shift;
      my $issuenow =shift;
      my $tool_out_dir=shift;
      if(not $fromsrdc){
        if( !length $issuenow ){
        print "Do you have a performance issue now ? [Y|y|N|N] [Y] : ";
        chomp($issuenow = <STDIN>);
        $issuenow ||= "Y";
        $issuenow = get_valid_input( $issuenow, "Y|y|N|n", "Y");
        if( uc($issuenow) eq "Y"){;
          $issuenow="true";
        } else{
          $issuenow="false";
        }
      }#end if empty issuenow
      #---------------------------ISSUE NOW------------------------------------------------#
      if ($issuenow eq "true" && ! length $starttime ){ 
        my $currtime    = strftime "%b/%d/%Y %H:%M:%S", localtime();
        my $utscurrtime = getValidDateFromString($currtime, "time");
        #Enter period of hours the performance was bad awrduration 
        print "Enter the awrduration in hours : <RETURN>=1 \n";
        my $validinp    = FALSE;
        my $userinp;
        my $awrduration;
        while(! $validinp){
          $userinp = <STDIN>;
          chomp($userinp);
          if (length $userinp && $userinp !~ /^[0-9]+$/){
            print "$userinp is not a valid number, please try again.\n";
          } else {
            $validinp = TRUE;
          }
        }
        if( length $userinp){
          $awrduration = $userinp;
        } else {
          $awrduration = 1;
        }
        
        my $awrhours    = $awrduration * 60 *60;
        $endtime  = strftime "%b/%d/%Y %H:%M:%S", localtime($utscurrtime);
        $starttime  = strftime "%b/%d/%Y %H:%M:%S", localtime($utscurrtime - $awrhours);
        print"Start time : $starttime\n";
        print"End time   : $endtime\n";
      } else {
        my $validbaseline = FALSE;
        my $userinp;
        
        #Prompt for start
        while( ! $validbaseline ){
          $userinp = tfactlshare_input_date("Enter start time [YYYY-MM-DD HH24:MI:SS] :", "The timestamp format used is invalid.\n");
          if ( length $userinp){
            $starttime = $userinp;
            $validbaseline = TRUE;
          } else {
            print "Start time for running awr is mandatory, please try again.";
          }
        }#end while baseline not valid 
        if(length $starttime){
          my $utsstarttime = getValidDateFromString($starttime,"time");
          $starttime = strftime "%b/%d/%Y %H:%M:%S", localtime($utsstarttime);
        }
        print "Start time: $starttime \n";
        #Prompt end time performance was bad
        $validbaseline = FALSE;
        while( ! $validbaseline ){
          $userinp = tfactlshare_input_date("Enter end time [YYYY-MM-DD HH24:MI:SS] :", "The timestamp format used is invalid.\n");
          if ( length $userinp){
            if( tfactlshare_cmp_timestamps( $userinp, $starttime) eq 1){
              $endtime = $userinp;
              $validbaseline = TRUE;
            } else {
              print "End time for running awr must be greater than start time : $starttime";
            }#end if tfactlshare_cmp_timestamps();
          } else {
            print "End time for running awr  is mandatory, please try again.";
          }
        }#end while baseline not valid 
        if(length $endtime){
          my $utsendtime = getValidDateFromString($endtime,"time");
          $endtime = strftime "%b/%d/%Y %H:%M:%S", localtime($utsendtime);
        }
        print "Stop time when performance was bad: $endtime \n";
      }
    }#-------------------------------------End not from srdc------------------------------------------#
    print "Running runawr performance collection for range $starttime to $endtime\n";
    runscript("runawr.pl","",$starttime,$endtime);
    system("ls $tool_out_dir");
}

sub slowsql
{
  my $slow_sqlID = shift;
  my $tfa_home = shift;
  my $db = shift;
  my $license = shift;

  if ( ! length $slow_sqlID){
    print "If any particular SQL causes the Database to be slow enter the SQL_ID? [<RETURN>= NO SQL_ID] :";
    chomp($slow_sqlID = <STDIN>);
  }
  if ( ! length $license ) {
    $license = tfactlshare_get_awrlicense($tfa_home,$db);
    if ( $license !~ /DIAGNOSTIC/ ) {
      print "Do you have an AWR license? (Refer to Doc 1490798.1 for more information) [Y|y|N|n] [Y]: ";
      chomp($license = <STDIN>);
      $license ||="Y";
      $license = get_valid_input( $license, "Y|y|N|n", "Y");
      if ( uc($license) eq "Y"){
        print "Select your corresponding license DIAGNOSTIC+TUNNING T or DIAGNOSTIC D  [T|t|d|D] [D] : ";
        chomp($license = <STDIN>);
        $license ||= "D";
        $license = get_valid_input( $license ,"T|t|d|D", "D");
        $license =  "DIAGNOSTIC+TUNNING" if( uc($license) eq "T" );
        $license =  "DIAGNOSTIC" if ( uc($license) eq "D" );

      } else {
        $license = "NONE";
      }
    }

  }  

  $license = "T" if($license eq "DIAGNOSTIC+TUNING");
  $license = "D" if($license eq "DIAGNOSTIC");
  $license = "N" if($license eq "NONE");
  #Process slowsql
  ###Make sure that we have the sql health check script up to date.
  my $sqlhc_path =catfile($tfa_home,"resources","sql","sqlhc.sql");
  my $sql = "@"."$sqlhc_path $license $slow_sqlID";
  print "Running SQLHC......\n";
  my @out = tfactlshare_run_a_sql("sql",$sql);
}
sub dbslow
{
   my $fromsrdc =shift;
   my $dbperf_good_st = shift;
   my $dbperf_good_et = shift;
   my $dbperf_bad_st = shift;
   my $dbperf_bad_et = shift;
   my $db = shift;
   my $issuenow = shift;
   my $license = shift;
   my $slow_sqlID = shift;
   my $tool_out_dir=shift;
   my $statspack = FALSE;
   
   print "Running dbslow performance collection\n";

   #---------------------Block when dbperf dbslow is not run from srdc------------------------------------#
   if( not $fromsrdc){
     if ( ! length $license) {
       $license = tfactlshare_get_awrlicense($tfa_home,$db);
       if ( $license !~ /DIAGNOSTIC/ ) {
          print "Do you have an AWR license? (Refer to Doc 1490798.1 for more information) [Y|y|N|n] [Y]: ";
          chomp($license = <STDIN>);
          $license ||="Y";
          $license = get_valid_input( $license, "Y|y|N|n", "Y");
          if ( uc($license) eq "Y"){
            print "Select your corresponding license DIAGNOSTIC+TUNNING T or DIAGNOSTIC D  [T|t|d|D] [D] : \n";
            chomp($license);
            $license ||= "D";
            $license = get_valid_input( $license ,"T|t|d|D", "D");
            $license =  "DIAGNOSTIC+TUNNING" if( uc($license) eq "T" );
            $license =  "DIAGNOSTIC" if ( uc($license) eq "D" );

          } else {
            $license = "NONE";
          }
        }
     }#end if empty license 
     if( !length $issuenow ){
       print "Do you have a performance issue now ? [Y|y|N|N] [Y] : ";
       chomp($issuenow = <STDIN>);
       $issuenow ||= "Y";
       $issuenow = get_valid_input( $issuenow, "Y|y|N|n", "Y");
       if( uc($issuenow) eq "Y"){;
         $issuenow="true";
       } else{
         $issuenow="false";
       }
     }#end if empty issuenow
     #-----------------------------ISSUE NOW -------------------------------------# 
     if ($issuenow eq "true" && ! length $dbperf_bad_st ){ 
       my $currtime    = strftime "%b/%d/%Y %H:%M:%S", localtime();
       my $utscurrtime = getValidDateFromString($currtime, "time");
       #Enter period of hours the performance was bad awrduration 
       print "Enter the duration in hours when the performance was bad : <RETURN>=1 \n";
       my $validinp    = FALSE;
       my $userinp;
       my $awrduration;
       while(! $validinp){
         $userinp = <STDIN>;
         chomp($userinp);
         if (length $userinp && $userinp !~ /^[0-9]+$/){
           print "$userinp is not a valid number, please try again.\n";
         } else {
           $validinp = TRUE;
         }
       }
       if( length $userinp){
         $awrduration = $userinp;
       } else {
         $awrduration = 1;
       }
       
       my $awrhours    = $awrduration * 60 *60;
       $dbperf_bad_et  = strftime "%b/%d/%Y %H:%M:%S", localtime($utscurrtime);
       $dbperf_bad_st  = strftime "%b/%d/%Y %H:%M:%S", localtime($utscurrtime - $awrhours);
       print "As you have indicated that the performance issue is currently happening,\n";
       print "will be collecting snapshots for the following periods:\n";
       print "Start time when the performance was bad: $dbperf_bad_st \n";
       print "Stop  time when the performance was bad: $dbperf_bad_et \n";
       print "For comparison, it is useful to gather data from another period with similar load where problems are not seen.Typically this is likely to be the same time period on a previous day. To compare to the same time period on a previous day enter the number of days ago you wish to use. [<RETURN> to provide other time range] : ";
       
       $validinp = FALSE;
       while ( ! $validinp ){
         $userinp = <STDIN>;
         chomp($userinp);
         if ( length $userinp && $userinp !~ /^[0-9]+$/ ){
           print "$userinp is not a valid number, please try again.\n";  
         } else {
           $validinp = TRUE;
         }#end if userinp not a valid number 
       }#end while input is not valid! 
       if(length $userinp){
         my $utsstarttime = getValidDateFromString($dbperf_bad_st, "time");
         my $utsendtime   = getValidDateFromString($dbperf_bad_et, "time");
         my $timeadjust   = $userinp * 24 * 60 * 60;
         $dbperf_good_st  = strftime "%b/%d/%Y %H:%M:%S", localtime($utsstarttime - $timeadjust);
         $dbperf_good_et  = strftime "%b/%d/%Y %H:%M:%S", localtime($utsendtime - $timeadjust);
         print "Start time when performance was good: $dbperf_good_st\n";
         print "Stop  time when performance was good: $dbperf_good_et\n";
       } else { # Chose a different time range..
         #Prompt start time performance was good
         my $validbaseline = FALSE;
         while( ! $validbaseline ){
           $userinp = tfactlshare_input_date("Enter start time when the performance was good [YYYY-MM-DD HH24:MI:SS] :", "The timestamp format used is invalid.\n");
           if ( length $userinp){
              $dbperf_good_st = $userinp;
              $validbaseline = TRUE;

           } else {
             print "Start time when performance was good is mandatory, please try again.";
           }
          }#end while baseline not valid 
          if(length $dbperf_good_st){
            my $utsstarttime = getValidDateFromString($dbperf_good_st,"time");
            $dbperf_good_st = strftime "%b/%d/%Y %H:%M:%S", localtime($utsstarttime);
          }
          print "Start time when performance was good: $dbperf_good_st \n";

        #Prompt end time performance was good
        $validbaseline = FALSE;
        while( ! $validbaseline ){
          $userinp = tfactlshare_input_date("Enter stop time when the performance was good [YYYY-MM-DD HH24:MI:SS] :", "The timestamp format used is invalid.\n");
            if ( length $userinp){
              if( tfactlshare_cmp_timestamps( $userinp, $dbperf_good_st) eq 1 ){
                $dbperf_good_et = $userinp;
                $validbaseline = TRUE;
              }else {
                print "Stop time when performance was good must be greater than start time : $dbperf_good_st";
              }#end if tfactlshare_cmp_timestamps();

           } else {
             print "Stop time when performance was good is mandatory, please try again.";
           }
          }#end while baseline not valid 
          if(length $dbperf_good_et){
            my $utsendtime = getValidDateFromString($dbperf_good_et,"time");
            $dbperf_good_et = strftime "%b/%d/%Y %H:%M:%S", localtime($utsendtime);
          }
          print "Start time when performance was good: $dbperf_good_et \n";

     
     }#end different time range
   } else{ 
     #No issue now prompt for ranges
     my $validbaseline = FALSE;
     my $userinp;

     #Prompt for bad time ranges
     while( ! $validbaseline ){
       $userinp = tfactlshare_input_date("Enter start time when the performance was bad [YYYY-MM-DD HH24:MI:SS] :", "The timestamp format used is invalid.\n");
       if ( length $userinp){
         $dbperf_bad_st = $userinp;
         $validbaseline = TRUE;
       } else {
         print "Start time when performance was good is mandatory, please try again.";
       }
     }#end while baseline not valid 
     if(length $dbperf_bad_st){
       my $utsstarttime = getValidDateFromString($dbperf_bad_st,"time");
       $dbperf_bad_st = strftime "%b/%d/%Y %H:%M:%S", localtime($utsstarttime);
     }
     print "Start time when performance was bad: $dbperf_bad_st \n";
     #Prompt end time performance was bad
     $validbaseline = FALSE;
     while( ! $validbaseline ){
       $userinp = tfactlshare_input_date("Enter stop time when the performance was bad [YYYY-MM-DD HH24:MI:SS] :", "The timestamp format used is invalid.\n");
       if ( length $userinp){
         if( tfactlshare_cmp_timestamps( $userinp, $dbperf_bad_st) eq 1){
           $dbperf_bad_et = $userinp;
           $validbaseline = TRUE;
         }else {
           print "Stop time when performance was bad must be greater than start time : $dbperf_bad_st";
         }#end if tfactlshare_cmp_timestamps();
       } else {
         print "Stop time when performance was bad is mandatory, please try again.";
       }
     }#end while baseline not valid 
     if(length $dbperf_bad_et){
       my $utsendtime = getValidDateFromString($dbperf_bad_et,"time");
       $dbperf_bad_et = strftime "%b/%d/%Y %H:%M:%S", localtime($utsendtime);
     }
     print "Stop time when performance was bad: $dbperf_bad_et \n";

     #Prompt for good time ranges 
     $validbaseline = FALSE;
     while( ! $validbaseline ){
       $userinp = tfactlshare_input_date("Enter start time when the performance was good [YYYY-MM-DD HH24:MI:SS] :", "The timestamp format used is invalid.\n");
       if ( length $userinp){
         $dbperf_good_st = $userinp;
         $validbaseline = TRUE;
       } else {
         print "Start time when performance was good is mandatory, please try again.";
       }
     }#end while baseline not valid 
     if(length $dbperf_good_st){
       my $utsstarttime = getValidDateFromString($dbperf_good_st,"time");
       $dbperf_good_st = strftime "%b/%d/%Y %H:%M:%S", localtime($utsstarttime);
     }
     print "Start time when performance was good: $dbperf_good_st \n";
     #Prompt end time performance was good
     $validbaseline = FALSE;
     while( ! $validbaseline ){
       $userinp = tfactlshare_input_date("Enter stop time when the performance was good [YYYY-MM-DD HH24:MI:SS] :", "The timestamp format used is invalid.\n");
       if ( length $userinp){
         if( tfactlshare_cmp_timestamps( $userinp, $dbperf_good_st) eq 1){
           $dbperf_good_et = $userinp;
           $validbaseline = TRUE;
         }else {
           print "Stop time when performance was good must be greater than start time : $dbperf_good_st";
         }#end if tfactlshare_cmp_timestamps();
       } else {
         print "Stop time when performance was good is mandatory, please try again.";
       }
     }#end while baseline not valid 
     if(length $dbperf_good_et){
       my $utsendtime = getValidDateFromString($dbperf_good_et,"time");
       $dbperf_good_et = strftime "%b/%d/%Y %H:%M:%S", localtime($utsendtime);
     }
     print "Stop time when performance was good: $dbperf_good_et \n";
   }
   if ( ! length $slow_sqlID){
     print "If any particular SQL causes the Database to be slow enter the SQL_ID ?(Refer to Doc 1627387.1 for more information on how to determine SQL_ID) [<RETURN>= NO SQL_ID] :";
     chomp($slow_sqlID = <STDIN>);

   }
 }#----------------------------End of block when running dbperf without srdc ---------------------------------#
   #AWR or STATASPACK REPORTS.
   generate_reports($tfa_home,$fromsrdc,$license,$db,$dbperf_bad_st,$dbperf_bad_et,$dbperf_good_st,$dbperf_good_et,$issuenow,\$statspack);
   #Slow SQL Provided 
   if( length $slow_sqlID ) {
      slowsql($slow_sqlID,$tfa_home,$db,$license);
   }
   if( $issuenow eq "true" ){
     print "Running hanganalyze....\n";
     my @out = dbutil_hanganalyze();
     my @errors = grep{$_ =~ /ORA\-[0-9]+/} @out;
     if( scalar(@out) > 0 && scalar(@errors) == 0 ){
       my $dir = $IS_AIX ? $ENV{'PWD'} : getcwd(); # getcwd() in AIX returns permission denied even though user has the right permissions
       my $filename = fileparse($out[scalar(@out)-1]);
       $dir = catfile("$dir",$filename);
       system("$CP $out[scalar(@out)-1] $dir");
     }
     print "Hanganalyze errors @errors\n"  if ( scalar(@errors) > 0 );
     print "Finished running hanganalyze\n"; 
   }
   if ( $license =~ /DIAGNOSTIC/ ) {
     print "\"Automatic Workload Repository (AWR) is a licensed feature.Refer to My Oracle Support Document ID 1490798.1 for more information\"\n";
       
   } elsif ( not $statspack ) {
     print "\"It is recommended to provide AWR reports. In case, you don't have a license, then install and enable Statspack using Document 1931103.1\"\n";  
   }
}

#################
## NAME
##    generate_statspack_report
##
## DESCRIPTION
## 
##    This function creates a statspack report if 
##    statspack is installed and configured
## PARAMETERS 
##
##    $tfa_home       (IN)    TFA_HOME
##    $starttime      (IN)    Start Date-Time from when to  generate report
##    $endtime        (IN)    End   Date-Time to generate report 
##    $db             (IN)    Database name
##    $type           (IN)    bad/baseline 
## RETURNS
##    NULL
##
## NOTES
##    NONE
#################
sub generate_statspack_report
{
  my $tfa_home = shift;
  my $starttime = shift;
  my $endtime = shift;
  my $db = shift;
  my $type =shift;
  my $issuenow = shift;
  my @out;
  my @snaps = get_statspacksnaps($tfa_home,$starttime,$endtime,$db,"ids",$issuenow);
  if ( scalar(@snaps) == 0 ) {
    print "No snapshots found, unable to create statspack report!\n";
  } else {
    if(scalar(@snaps) == 1){#Only one snapshot adjust to get a previous one
      print "Adjusting startime $starttime by an hour to get previous snapshot\n";
      @snaps = get_statspacksnaps($tfa_home,$starttime,$endtime,$db,"ids","true");
    }
    if(scalar(@snaps) < 2 ){
      print "No enough snapshots to generate statspack report\n";
      return ;
    }
    my @errors = grep{ $_ =~ /ORA\-[0-9]+/}@out;
    if ( @errors ){
      print "Could not create statspack report due to the following error(s): @errors";
    } else {
      my $count = scalar(@snaps);
      print "Found $count snapshots between $starttime and $endtime period\n";
      print "Generating statspack report\n";
      chomp(@snaps);
      my $beginSnap = $snaps[scalar(@snaps)-2];#very previous one. 
      my $endSnap = $snaps[scalar(@snaps)-1];
      my $stats_report = "$hostname"."_$type"."_statspack_report";
      print "Report name : $stats_report\n";
      my $sql;
      $sql = "set echo off feedback off\n";
      $sql .= "set termout off\n";
      $sql .= "define begin_snap=$beginSnap;\n";
      $sql .= "define end_snap=$endSnap;\n";
      $sql .= "define report_name=$stats_report;\n";
      if(  $IS_WINDOWS ){
        $sql .="@@%ORACLE_HOME%\\rdbms\\admin\\spreport";
      } else {
        $sql .= "@@?/rdbms/admin/spreport";
      }
      @out =tfactlshare_run_a_sql("sql",$sql);
    } 
  }
  my $statssnaps_file = "tfa_dbperf_statspack_all_snapshots";
  open(OUTF, "> $statssnaps_file" );
  @snaps = get_statspacksnaps($tfa_home,$starttime,$endtime,$db,"list","false");
  foreach my $line (@snaps){
    print OUTF "$line\n";
  }
  close(OUTF);
  return @out;
}
##########################
##  NAME
##    get_statspacksnaps  
##
##  DESCRIPTION
##    This function gathers statspack snapshots,
##    this function has two options :
##    -ids which returns only the snapshots IDS 
##    -anything else gathers all snapshots for the database provided. 
##  PARAMS
##    $tfa_home     (IN)   tfa_home
##    $starttime    (IN)   Start time to gather snaps 
##    $endtime      (IN)   End time to gather snaps 
##    $db           (IN)   Database name
##    $func         (IN)   Function to execute ids|*
##
##  RETURNS 
##    @snaps        Snapshots gathered. 
##
##
#########################
sub get_statspacksnaps
{
   my $tfa_home= shift;
   my $starttime = shift;
   my $endtime = shift;
   my $db = shift;
   my $func = shift;
   my $adjust =shift;
   my $sqlstring;
   if( $adjust eq "true"){
     #$starttime = getValidDateFromString($starttime,"time");
     $starttime = tfactlshare_adjust_time_by_seconds($starttime,"subtract",1*60*60); #adjust by one hour to ensure we have a snapshot if there is enough 
   }
   $starttime = tfactlshare_convertDateStringforCRS($starttime);
   $endtime = tfactlshare_convertDateStringforCRS($endtime);

   if ( $func eq "ids" ) {
     $sqlstring = "set heading off echo off feedback off\n";
     $sqlstring .= "set linesize 500;\n";
     $sqlstring .= "select snap_id from (select distinct snap_id, snap_time from stats\\\$snapshot , gv\$database";
     $sqlstring .=" WHERE  snap_time >= to_date('$starttime','YYYY-MM-DD HH24:MI:SS') ";  
     $sqlstring .=" and snap_time <= to_date('$endtime','YYYY-MM-DD HH24:MI:SS')"; 
     $sqlstring .= " and name='".uc($db)."'  and instance_number=(select instance_number from v\\\$instance)) ORDER BY snap_time;";
     #print "$sqlstring\n";

  } else {
     $sqlstring = "set echo off feedback off\n";
     $sqlstring .= "set linesize 500;\n";
     $sqlstring .= "select * from (select distinct name,snap_id,to_char(snap_time,'YYYY-MM-DD HH24:MI:SS') \"DATE/TIME\", instance_number from stats\\\$snapshot, gv\$database";
     $sqlstring .= " WHERE name='".uc($db)."' ) ORDER by 3;";
     #print "$sqlstring\n";
   }
   tfactlshare_trace(5,"tfactl (PID=$$)  get_statspacksnaps "." sql string for $func is $sqlstring");
   dbutil_setOraEnv($tfa_home,$db,"",TRUE);
   tfactlshare_trace(5,"tfactl ( PID=$$) get_stataspacksnaps ".
                      "ENV Set for db $db HOME $ENV{ORACLE_HOME} SID $ENV{ORACLE_SID} ",
                      'y','y');
   my @snaps = tfactlshare_run_a_sql("sql",$sqlstring);
   @snaps = grep{ $_ ne ''} @snaps;
   return @snaps;
 }
###############
## NAME 
##     runscript
##
## DESCRIPTION 
##
##      This function executes the perl scripts needed 
##      for the dbperf collections.
##
## PARAMETERS 
## 
##      $script         (IN)     Name of the script to run
##      $flag           (IN)     -good, -bad, ""
##      $perf_good_st   (IN)     Start Date-Time when performance was good.
##      $perf_good_et   (IN)     End   Date-Time when performance was good.
##      $perf_bad_st    (IN)     Start Date-Time when performance was bad. (Optional)
##      $perf_bad_et    (IN)     End   Date-time when performance was bad. (Optional)
##
##  RETURNS
##  
##      NULL
##
##  NOTES 
##     
##      Currently this function supports runawrcompare.pl, runawr.pl, runaddm.pl and runash.pl 
##      Some adjustments might be needed if other perl scripts want to be added. 
##
###############
sub runscript
{
  my ($script,$flag, $perf_good_st, $perf_good_et, $perf_bad_st, $perf_bad_et) = @_;
  my $cmd = "$PERL " . catfile($tfa_home,"bin","scripts",$script) . " -ohome $ENV{ORACLE_HOME} -osid $ENV{ORACLE_SID} -ouser $ENV{TFA_ORACLE_USER}";
  
  if ( $script eq "runawrcompare.pl" ) {
     $cmd.=" -from \"$perf_bad_st\" -to \"$perf_bad_et\" -baselinefrom \"$perf_good_st\" -baselineto \"$perf_good_et\" -html -hostname \"$hostname\"";
  } elsif ( $script eq "runaddm.pl" ) {
    $cmd.=" -from \"$perf_good_st\" -to \"$perf_good_et\" -hostname \"$hostname\"";
  } else {
    $cmd.=" -from \"$perf_good_st\" -to \"$perf_good_et\" -html $flag -hostname \"$hostname\"";
  }
  print "Running Command: $cmd\n";
  system($cmd);
}

