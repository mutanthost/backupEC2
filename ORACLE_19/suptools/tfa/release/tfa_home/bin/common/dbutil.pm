# 
# $Header: tfa/src/v2/tfa_home/bin/common/dbutil.pm /main/17 2018/07/09 23:34:54 bibsahoo Exp $
#
# dbutil.pm
# 
# Copyright (c) 2017, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      dbutil.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bibsahoo    06/28/18 - Adding functions to get running database details
#    recornej    05/02/18 - 27210703 - TFA : CANNOT SET CONTEXT TO DBNAME
#    manuegar    04/17/18 - XbranchMerge manuegar_oratopfx from
#                           st_tfa_pt-quarterly.12.2.1.2.0
#    recornej    03/05/18 - Fix dbutil_setOraEnv in AIX
#    recornej    01/26/18 - XbranchMerge recornej_bug-27361815 from
#                           st_tfa_12.2.1.3.1
#    recornej    01/29/18 - Adding +ASM and MGMTDB services in
#                           dbutil_iswindbrunning
#    recornej    01/17/18 - XbranchMerge recornej_aix18_1bug from st_tfa_18.1
#    recornej    12/14/17 - Bug 27223032 - AIX-18.1-TFA:DIAGCOLLECT PRINTS
#                           INTERNAL ERROR MSGS
#    manuegar    11/16/17 - manuegar_oratopfx.
#    recornej    01/24/18 - Bug 27387871 - SOLX64-18.1-TFA:RUN TFACTL
#                           DIAGCOLLECT AS GI USER HIT PMAP: CANNOT EXAMINE
#                           4717
#    recornej    10/26/17 - Fix Exiting subroutine via next error
#    recornej    01/17/18 - Bug 27361815 - SRDC COLLECTION IS NOT WORKING IN
#                           LATEST TFA VERSION(12.2.1.3.1)
#    manuegar    11/16/17 - manuegar_oratopfx.
#    bburton     11/02/17 - Fix unintialized dbhome
#    recornej    11/02/17 - Add parsefiles before read timeline
#    recornej    10/30/17 - Return only previous month dbshutdowns/startups
#    recornej    10/27/17 - Change message in dbutil_errorstack
#    recornej    10/23/17 - Fix get_alertlog
#    bburton     10/20/17 - Add code to get dbunique name
#    manuegar    10/11/17 - manuegar_diffs_permdenied_pt.
#    recornej    10/06/17 - Fixing exiting from subrutine in dbutil_setOraEnv
#    recornej    10/06/17 - Fixing dereferencing errors in some versions of
#                           perl in the errorstack module.
#    bburton     10/02/17 - fix OH retrieval for non ADE
#    recornej    09/22/17 - Fixing Use of uninitialized value when PRCD-1229
#                           error occurs
#    recornej    09/21/17 - Removing unnecessary code.
#    manuegar    09/20/17 - manuegar_ips_diff.
#    recornej    09/14/17 - Fixing uninitialize value
#    recornej    09/13/17 - Adding errorstack module
#    recornej    09/04/17 - Adding sub dbutil_lastShutdownStartUp.
#    manuegar    08/14/17 - Bug 26619915 - LNX64-12.2-TFA:ORATOP DOES NOT WORK
#                           WHEN DB UNIQUE NAME DIFFERS FROM DBNAME.
#    manuegar    05/08/17 - XbranchMerge manuegar_srdcwin03 from
#                           st_tfa_12.2.1.1.01
#    bburton     05/11/17 - improve messaging
#    manuegar    05/04/17 - manuegar_srdcwin03.
#    manuegar    04/28/17 - manuegar_srdcwin01.
#    manuegar    04/21/17 - manuegar_srdcwin_shared.
#    bburton     03/27/17 - Fix issue with line return in ohome
#    manuegar    04/07/17 - manuegar_windows_srdc01.
#    bburton     03/10/17 - This file contains functions for tfa to use
#                           tohandle connecting to Oracle Databases
#    bburton     03/10/17 - Creation
# 
#########################
package dbutil;

BEGIN {
use Exporter();
our (@ISA, @EXPORT);
@ISA = qw(Exporter);

my @exp_func = qw(dbutil_setOraEnv dbutil_get_dbhome_version dbutil_iswindbrunning dbutil_getDbsRunning
                  dbutil_errorstack dbutil_lsEventsSet dbutil_lastShutdownStartups dbutil_get_alert_log
                  dbutil_hanganalyze dbutil_get_dbunqname);  
push @EXPORT,@exp_func;
}

use strict;
use warnings;
use English;
use File::Spec::Functions;
use File::Copy;
use Time::Local;
use POSIX;
use tfactlglobal;
use tfactlshare; # Need to break this out as we only need a couple of functions.
use cmdlocation;
use tfactlwin;
use osutils;

our $tfa_home;
our $db_name;
our $truedb_name;
our $ohome = "";
our $ouser = "";
our $osid = "";
our $db_running = 0;
our $running_local = 0;
our $orabase = "";
our $LOG;
our $setenv;

#########
#
## Name :  dbutil_get_dbunqname
#
## Description: Gets the database unique name from v$database
#
## Input.
# tfa_home - TFA Home directory 
# db - database name 
#
## Returns.
#  On Success - Database unique Name
#  On Failure - 1
###############
sub dbutil_get_dbunqname
{
  my $tfa_home = shift; 
  my $db = shift;
  my $sql = "";
  my $retval;
  
  #Verify user access
  #--------------------------------------------------------
  if ( $current_user eq "root" && not $IS_WINDOWS ){
    print "get_dbunqname cannot be run as root!\n";
    return 1;
  } else {
     $retval = dbutil_setOraEnv($tfa_home,$db,"",TRUE);
     if ( $retval eq 0 ) {
       my $grantaccess = tfactlshare_isuserindbagrp($current_user,$ENV{"ORACLE_HOME"});
       if ( ! $grantaccess ) {
         print "Error: $current_user not in dbagroup\n";
         return 1;
       }
     
     } else {
       print "Unable to find database $db \n";
       return 1;
     }

  }# end if current_user is root 
  #------------------------------------------------------------
  $sql = "set heading off echo off feedback off pagesize 0 \nselect DB_UNIQUE_NAME from v\$database;";
  my @out = tfactlshare_run_a_sql("sql",$sql);
  my $ret = $out[0];
  print "Database Unique name $ret found for db name $db\n";
  return $ret;
}
sub dbutil_getDbsRunning
{
  my $cmd = "";
  my $db_sid;
  my $db_home = "";
  my $db_user;
  my $db_name;
  my $pid;
  my $sids;
  my $outcmd;
  my @ohomes;

  # Searching for running databases
  if ( $IS_WINDOWS ) {
     return @ohomes;
  }
  $cmd = "ps -ef |grep ora_pmon|grep -v grep";
  $sids = `$cmd`;

  foreach my $line (split /\n/, $sids) {
    if ( $line =~ /.*ora_pmon_(.*)/ ) {
      $db_sid = $1;
    }
    $db_name = $db_sid;   #since in SI, dbname is same as the instance name
    if ( $line =~ /\w+\s+([0-9]+)\s+.*/ ) {
      $pid = $1;
    }

    if ( not $IS_ADE_HOST ) {
      if ( $osname eq "AIX" ){ 
        $cmd = "procmap  $pid | grep lib | grep -v usr | awk '{print \$NF}'";
      } else {
        $cmd = "pmap -help";
        $outcmd = `$cmd 2>&1`;
        if ( $outcmd =~ /\-\-show\-path/ ) {
          $cmd = "pmap -p $pid 2>&1 | grep oracle | awk '{print \$NF}'";
        } else {
          $cmd = "pmap $pid 2>&1 | grep oracle | awk '{print \$NF}'";
        } 
      }
    } else {
      $cmd = "ps -ef |grep '$db_sid/oracle/bin/ocssd'| grep -v grep | awk '{print \$NF}'";
    }

    $db_home = `$cmd`;
    my @tmp = split /\n/, $db_home;
    $db_home = $tmp[0];
    #print "DBHOME before edit:$db_home\n";
    if ( length $db_home ) {
      if ( $IS_ADE_HOST ) {
         $db_home =~ s/\/rdbms\/bin\/oracle/\/oracle/g;
         $db_home =~ s/\/bin\/ocssd//g;
      } else {
         $db_home =~ s/\/bin\/oracle//g;
         $db_home =~ s/\/lib\/.*//g;
      }
    chomp($db_home);
    #print "DBHOME after edit:$db_home\n";
    } else {
      next;#Do not skip oracle homes when errors like 'pmap: cannot examine <pid>' appear.
      #return @ohomes;
    } # end if length $db_home

    if ( $line =~ /(\w+)\s+[0-9]+\s+.*/ ) {
      $db_user = $1;
    }
   
    if ( $IS_ADE ) {
      $db_home = catdir("","ade","$db_user" ."_" . $db_name,"oracle");
    }
    push @ohomes, $db_home;
  } # end foreach 

  #### print "DETAILS: $db_name $db_sid $db_home $db_user $pid\n";
  return @ohomes;
} # end if dbutil_getDbsRunning

sub dbutil_get_dbhome_version
{
  my $orahome = shift;  
  my $oraversion = ""; 
  my $ldlibpath = "";
  my $altohome  = $orahome;
  if ( $IS_ADE ) {
    if ( -f catfile($orahome,"..","oracle",".dispatch","lib","libsqlplus.so") ) {
      $altohome = catfile($orahome,"..");
      $ldlibpath = catfile($altohome,"oracle",".dispatch","lib");
    } else {
      $ldlibpath = catfile($orahome,"lib");
    }
  } else {
    $ldlibpath = catfile($orahome,"lib");
  }
  my $sqlplus = catfile($orahome, "bin", "sqlplus");
  my $sqlcmd = "$sqlplus -v";

  my $louser = tfactlshare_get_dir_file_owner($orahome);
  if ( $current_user eq "root" && length $louser )
  {
    if ($IS_WINDOWS) {
        $sqlcmd = "$sqlcmd";
    } else {
        if ( $CSH ) {
          $sqlcmd = "su $louser -c \"setenv ORACLE_HOME $altohome; setenv LD_LIBRARY_PATH $ldlibpath; $sqlcmd\"";
        } else {
          $sqlcmd = "su $louser -c \"ORACLE_HOME=$altohome; export ORACLE_HOME; LD_LIBRARY_PATH=$ldlibpath; export LD_LIBRARY_PATH; $sqlcmd\"";
        }
    }
  } else {
    if ( $CSH ) { 
      $sqlcmd = "/bin/csh -c 'setenv ORACLE_HOME $altohome; setenv LD_LIBRARY_PATH $ldlibpath; $sqlcmd'";
    } else {
      $sqlcmd = "ORACLE_HOME=$altohome; export ORACLE_HOME; LD_LIBRARY_PATH=$ldlibpath; export LD_LIBRARY_PATH; $sqlcmd";
    }
  } # end if $current_user eq "root" && length $louser

  my @out = `$sqlcmd 2>&1`;
  foreach my $line(@out)
  {
    if ( $line =~ /Release ([\d\.]+) / )
    {
      $oraversion = $1;
    }
  }

  if ( !length $oraversion )
  {
    print $LOG localtime(time) . " : ERROR : dbutil_get_dbhome_version : Could not find version for home $orahome\n" if $LOG;
  }
  return $oraversion;
}
######################################
##
##  NAME 
##   dbutil_errorstack
##
##  DESCRIPTION
##   This function sets the error stack for a given database with the 
##   corresponding attributes, if sql provided means the issue can be 
##   reproduce so try to reproduce it. 
##
##  PARAMS
##    $tfa_home      IN      TFA_home
##    $db            IN      Database
##    @errors        IN      Array of hashes that contain,
##                           event_code, context, level;
##    $debug         IN      ON|OFF
##    $sql           IN      sql
##    $sqltype       IN      file|sqlstring
##    $id            IN      tracefile id 
##  RETURNS
##     NONE
##
####################
sub dbutil_errorstack
{
  my $tfa_home = shift; 
  my $db = shift;
  my $errorsref = shift;
  my $debug =shift;
  my $sql = shift ;
  my $sqltype = shift;
  my $traceid = shift;
  my $type = "SYSTEM";
  my @errors = @$errorsref;
  my @contextoff;
  my $errorstring;
  my $retval;
  
  #Verify user access
  #--------------------------------------------------------
  if ( $current_user eq "root" && not $IS_WINDOWS ){
    print "Error stack module cannot be run as root!\n";
    return;
  } else {
     my %env;
     ($retval, %env ) = dbutil_setOraEnv($tfa_home,$db,"",FALSE);
     if ( $retval eq 0 ) {
       my $ohome = $env{"ORACLE_HOME"};
       my $grantaccess = tfactlshare_isuserindbagrp($current_user,$ohome);
       if ( ! $grantaccess ) {
         print "Error: $current_user not in dbagroup\n";
         return;
       }
     
     } else {
       print "Database $db is either not found or is not running. \n";
       print "Unable to set the events\n";
       return;
     }

  }# end if current_user is root 
  #------------------------------------------------------------
  if ( $debug =~ /ON/i ) {
    if ( $sql ){
      #--------------------
      #Issue is reproducible 
      if ( $sqltype eq "file" ) {
        if ( ! -e $sql ){
              print " File $sql does not exists!\n";
              return;
          }
      }
      $type = "SESSION";
    }
    #Generic for all errorstacks 
    #--------------------------------------------------------------------------------------
    $errorstring = "ALTER $type SET max_dump_file_size=unlimited;\n";
    $errorstring .= "ALTER $type SET TIMED_STATISTICS=true;\n";
    $errorstring .= "ALTER SESSION SET tracefile_identifier=\'$traceid\';\n" if ( $traceid );
    #---------------------------------------------------------------------------------------
    foreach my $error (@errors) {
      my %errstckhash = %$error;
      my $level = $errstckhash{"level"};
      my $error_code = $errstckhash{"error_code"};
      my $context = $errstckhash{"context"};
      my $statement = "ALTER $type SET EVENTS \'$error_code TRACE NAME ";
      if ( $context ne "errorstack"){
        push (@contextoff, $statement."CONTEXT OFF\';");
        $statement .= "CONTEXT $context , ";
      } else {
        $statement .= "errorstack ";
        push (@contextoff, $statement." OFF\';");
      }
      $statement .= "level $level\';\n";
      $errorstring.= $statement;
    }
    if ( $sql ) {
      #-------------------
      #Issue is reproducible
      if ( $sqltype eq "file" ) {
        $errorstring .= "@".$sql.";\n";
      } else {
        $errorstring .= "$sql\n;";
      }
      $errorstring .= join("\n",@contextoff);
    }
  } else {  #DEBUG OFF DISABLE SYSTEM ERRORS.
    $errorstring .= "ALTER SESSION SET tracefile_identifier=\'$traceid\';\n" if ( $traceid );
    foreach my $error ( @errors) {
      my %errstckhash = %$error;
      my $level = $errstckhash{"level"};
      my $error_code = $errstckhash{"error_code"};
      my $context = $errstckhash{"context"};
      push @contextoff,"ALTER $type SET EVENTS \'$error_code OFF\';";
    }
    $errorstring .= join("\n",@contextoff);
  }

  $retval = dbutil_setOraEnv($tfa_home,$db,"",TRUE);
  if ( $retval eq 0 ) {
     my @out = tfactlshare_run_a_sql("sql",$errorstring);
  } else { 
    print "Database $db is either not found or is not running. \n";
    print "Unable to set the events\n";
  }
}


#####################################################################
## NAME
##    dbutil_hanganalyze
##
## DESCRIPTION
## 
##    This function runs a hanganalyze, if the environment is RAC,
##    it will run a global hanganalyze.
##
## PARAMETERS 
##    NONE
##
## RETURNS
##    @output
##
## NOTES
##    In order to run this function the Oracle Environment must be set.
######################################################################
sub dbutil_hanganalyze
{
   my @output;  
   my $script= "oradebug setmypid;\n";
   if ( tfactlshare_is_rac() ) {
     $script.="oradebug setorapname diag;\n";
     $script.="oradebug setinst all;\n";
     $script.="oradebug -g all dump hanganalyze 3;\n";
     if ( ! $IS_WINDOWS ) {
       $script.="! sleep 60;\n";
     } else {
       $script.="host start /wait timeout 60;\n";
     }
     $script.="oradebug -g all dump hanganalyze 3;\n";
     $script.="oradebug tracefile_name;\n";
     $script.="exit;";
   } else {
     $script.="oradebug hanganalyze 3;\n";
     if ( ! $IS_WINDOWS){
       $script.="! sleep 60;\n";
     } else {
      $script.= "host start /wait timeout 60;\n"
     }
     $script.="oradebug hanganalyze 3;\n";
     $script.="oradebug tracefile_name;\n";
     $script.="exit;";
   }
   @output = tfactlshare_run_a_sql("sql",$script);
   return @output;
}

sub dbutil_lastShutdownStartups
{
  my $database = shift;
  my $type = shift; #shutdown startup 
  my $tfa_home = shift;
  my @shutdowns; 
  my $metadata_loc = tfactlshare_get_tfa_metadata_loc($tfa_home);
  my $file = catfile($metadata_loc,"timeline.out");
  if ( not -e $file ) {
      print "The initial TFA inventory has not yet been created or is in progress.\n";
      print "You can check the inventory status using the following command,\n";
      print "tfactl print status\n";
      exit 1;
  }
  #Refresh events
  my $localhost =tolower_host();
  my $actionmessage ="$localhost:parseevents";
  my $command = buildCLIJava($tfa_home,$actionmessage);
  my @cli_output = tfactlshare_runClient($command);
  foreach my $line ( @cli_output) {
    last if ($line eq "DONE");
  }

  my @shutdown;
  if ( $type eq "shutdown" ) {
    if ( ! $IS_WINDOWS ){
      @shutdown = `$GREP -i "db.$database.*shutting down instance (" $file`; #| tail -n 1`;#Get the last shutdown.
    } else {
      @shutdown = `findstr /IRC:"db.$database.*shutting down instance ("  $file`;
    }
  } elsif ( $type eq "startup" ) {
    if ( ! $IS_WINDOWS ){
      @shutdown = `$GREP -i "db.$database.*starting ORACLE instance (" $file`; #| tail -n 1`;#Get the last shutdown.
    } else {
      @shutdown = `findstr /IRC:"db.$database.*starting ORACLE instance ("  $file`;
    }
  } else {
    print "Not a valid option\n";
    return;
  }
  if ( not @shutdown ) {
      print "No $type was found in timeline\n";
      return;
  }
  my %seen;
  @shutdown = grep {!$seen{$_}++}@shutdown;
  my $limit = time() - 31*24*60*60;
  foreach my $shutdown ( @shutdown ) {
    if ( $shutdown =~ /(\w+\/\d+\/\d+\s\d+\:\d+\:\d+).*\=\s(.*)/ ){
      my $date = $1;
      my $msg = $2;
      my $date2;
      $date = getValidDateFromString($date, "time");
      $date2 = $date;
      next if ( $date < $limit );
      #Two possible datetime formats.
      $date = strftime( "%Y-%m-%dT%T", localtime($date));
      $date2 = strftime( "%a %b %d %H:%M:%S %Y", localtime($date2));
    
      push @shutdowns, { 'date'  =>$date, 'message' => $msg , 'date2' => $date2};
    }
  }
  return @shutdowns;
}
sub dbutil_get_alert_log
{ 
  my $tfa_home = shift;
  my $db = shift;
  my $alertlog;
  my $retval = "";
  my $tfa_directories = catfile($tfa_home,"tfa_directories.txt");
  if ( -e $tfa_directories ) {
     my @paths;
     if ( ! $IS_WINDOWS ) {
        @paths = `$GREP -i \"$db\" $tfa_directories | $GREP trace | $GREP -v repository`;
     } else {
       @paths  = `findstr /IRC:"$db" $tfa_directories | findstr /IRC:"trace" | findstr /IRVC:"repository"`;
     }
     if ( @paths ) {
       @paths = tfactlshare_uniq(@paths);
       my $ctime;
       my $ptime = 0;
       foreach my $path ( @paths) {
         chomp($path);
         if ( $path =~ /.*\=(.*)/ ) {
           $path = $1;
           next if ( ! -d $path );
           $path = catfile($path,"alert_*.log");
           if (!$IS_WINDOWS ) {
             $path = `$LS $path 2>/dev/null`;
           } else {
             $path = `dir /s/b $path 2>nul`;
           }
           chomp($path);
           next if ( ! $path  || ! -e $path);
           $ctime = (stat($path))[9];
           if ( $ptime < $ctime ) {
             $ptime = $ctime;
             $alertlog = $path; 
           }
         }
       }
       if ( $alertlog ){
         $retval = $alertlog;
       } else {
         $retval = "Error: alert log for database $db not found!\n";
       }
     } else {
       $retval = "Error: alert log for database  $db not found!\n";
     }
   } else {
     $retval = "Error: File tfa_directories.txt does not exists\n";
   }

  return $retval;
}

######################################
##
##  NAME 
##   dbutil_lsEventsSet
##
##  DESCRIPTION
##   This function returns the list of events set
##   for a given database at system level. 
##
##  PARAMS
##    $tfa_home      IN      TFA_home
##    $db            IN      Database
##  RETURNS
##     NONE| @events 
##
####################
sub dbutil_lsEventsSet
{
  my $tfa_home = shift;
  my $db = shift;
  my $retval;
  
  #Verify user access
  #--------------------------------------------------------
  if ( $current_user eq "root" && not $IS_WINDOWS ){
    print "dbutil_lsEventsSet cannot be run as root!\n";
    return;
  } else {
     my %env;
     ($retval, %env ) = dbutil_setOraEnv($tfa_home,$db,"",FALSE);
     if ( $retval eq 0 ) {
       my $ohome = $env{"ORACLE_HOME"};
       my $grantaccess = tfactlshare_isuserindbagrp($current_user,$ohome);
       if ( ! $grantaccess ) {
         print "Error: $current_user not in dbagroup\n";
         return;
       }
     
     } else {
       print "Unable to find database $db \n";
     }
  }# end if current_user is root 
  #------------------------------------------------------------
  $retval = dbutil_setOraEnv ($tfa_home, $db,"",TRUE);
  if ( $retval eq 0 ) {
    my @events; 
    my $sql;
    $sql  = " ORADEBUG setmypid;\n";
    $sql .= " ORADEBUG eventdump system;\n";
    $sql .= " exit;\n";
    @events = tfactlshare_run_a_sql("sql", $sql );
    @events = grep { $_ !~ /^Statement processed\./}@events;
    return @events;
  } else {
    print "Unable to set env for database $db \n";
  }
}

sub dbutil_iswindbrunning 
{
  my $db_name = shift;
  my $osid          = "";
  my $db_running    = 0;
  my $running_local = 0;
  my @out;
  my $oracle_service = "OracleService$db_name";
  my $pattern = '.*SERVICE_NAME: OracleService(.*)';
  if ( $db_name =~ /\+ASM/ ){
     $oracle_service = "OracleASMService";
     $pattern = '.*SERVICE_NAME: OracleASMService(.*)';
  } elsif ($db_name =~ /MGMTDB/i){
    $oracle_service = "OracleMGMTDBService";
    $pattern = '.*SERVICE_NAME: OracleMGMTDBService(.*)';
  }
  # --------------------------------------
  # Windows, check if DB is running
  # Find out the ORACLE_SID for $db_name
  # --------------------------------------
    @out = `sc query state= all | find "SERVICE_NAME" | find /i "$oracle_service" 2>&1`;
    foreach my $line (@out) {
      if ( $line =~ /$pattern/ ) {
        if ( length $1 ) {
          $osid = $1;
          last;
        }
      }
    } # end foreach @out
    if ( not length $osid ) {
      print $LOG localtime(time) . " : ERROR : dbutil_iswindbrunning: Could not find ORACLE_SID.\n" if $LOG;
      return ($osid,$db_running,$running_local);
    }
    
    # Check if db is running
    $oracle_service = "OracleService$osid";
    $oracle_service = "OracleASMService$osid" if ( $osid =~ /\+ASM/ );
    $oracle_service = "OracleMGMTDBService$osid" if ( $osid =~ /MGMTDB/);
    @out = `sc query $oracle_service 2>&1`;
    foreach my $line (@out) {
      if ( $line =~ /.*STATE\s+: [0-9]+\s+RUNNING.*/ ) {
        $db_running = 1;
        $running_local = 1;
        last;
      }
    } # end foreach @out
    return ($osid,$db_running,$running_local);
} # end sub dbutil_iswindbrunnning

##########################################
# NAME
#   dbutil_setOraEnv
#
# DESCRIPTION
#   This function returns the DB settings
#   for the given database.
#
# PARAMETERS
#   $tfa_home - TFA home
#   $db_name    - Database name
#   $LOG        - Log file reference (optional)
#   $setenv     - FALSE = do not set environment variables
#               - TRUE  = set environment variables
#                         $ENV{"ORACLE_SID"}
#                         $ENV{"ORACLE_HOME"}
#                         $ENV{"TFA_ORACLE_USER"}
#                         $ENV{"TFA_ORACLE_VERSION"}
#                         $ENV{"TFA_DB_RUNNING"}
#                         $ENV{"TFA_RUNNING_LOCAL"}
#
# RETURNS
#   ret - 0 = DB settings found
#         1 - DB settings not found
#   %rethash - only returned if $setenv = FALSE
#
##########################################
sub dbutil_setOraEnv 
{
  ($tfa_home, $db_name, $LOG, $setenv) = @_;
  $truedb_name = $db_name;
  my %rethash = ();
  if ( not $setenv ) {
    $setenv = FALSE;
  }
  #### print "setenv $setenv\n";

  print $LOG localtime(time) . " : In setOraEnv for db $db_name using tfahome $tfa_home\n" if $LOG;
  my $ret = 1;
  if ( ! $db_name )
  {
    print $LOG localtime(time) . " : ERROR : dbutil_setOraEnv: Database name missing. Please specify database\n" if $LOG;
    return $ret;
  }

  $ret = dbutil_setOraEnv_1();
  if ( $ret == 0 ) { 
    print $LOG localtime(time) . " : Set environment - DB config is available  on this node\n" if $LOG;
    if ( $running_local ) {
      print $LOG localtime(time) . " : Set environment - DB is running on this node\n" if $LOG;
    } else { 
      print $LOG localtime(time) . " : Set environment - DB is NOT running  on this node\n" if $LOG;
      $ret = 1;
    }
  } else { # Cannot get DB info at first try .. 
    print $LOG localtime(time) . " : Unable to set DB ENV in Try 1 - Trying other options\n" if $LOG;
    $ret = dbutil_setOraEnv_2();
    print $LOG localtime(time) .  " : Db down -> orabase $orabase ouser $ouser \n" if $LOG;
    print $LOG localtime(time) .  " : setOraEnv_2 retval -> $ret\n" if $LOG;
  }
  if ( $ret == 0 ) {
    $ouser =~ s/nt authority\\system/root/i;
    $ouser = "root" if (( not length $ouser) and $IS_WINDOWS);
    if ( $setenv ) {
      $ENV{"ORACLE_SID"} = $osid;
      $ENV{"ORACLE_HOME"} = $ohome;
      $ENV{"TFA_ORACLE_USER"} = $ouser;
      $ENV{"TFA_ORACLE_VERSION"} = dbutil_get_dbhome_version($ohome);
      $ENV{"TFA_DB_NAME"} = $truedb_name;
      $ENV{"TFA_DB_RUNNING"} = $db_running;
      $ENV{"TFA_RUNNING_LOCAL"} = $running_local;
      print $LOG localtime(time) .  " : setOraEnv set :HOME $ohome:SID $osid:USER $ouser:LOCAL $running_local\n" if $LOG;
    } else {
      $rethash{"ORACLE_SID"} = $osid;
      $rethash{"ORACLE_HOME"} = $ohome;
      $rethash{"TFA_ORACLE_USER"} = $ouser;
      $rethash{"TFA_ORACLE_VERSION"} = dbutil_get_dbhome_version($ohome);
      $rethash{"TFA_DB_NAME"} = $truedb_name;
      $rethash{"TFA_DB_RUNNING"} = $db_running;
      $rethash{"TFA_RUNNING_LOCAL"} = $running_local; 
    } # end if $setenv
  } # end if $ret == 0

  if ( $setenv ) {
    return $ret;
  } else {
    return ($ret, %rethash);
  }
} # end sub dbutil_setOraEnv


sub dbutil_setOraEnv_1 
{
  my %outhash = ();

  print $LOG localtime(time) . " dbutil_setOraEnv_1 : INFO  :Setting environment for database $db_name\n" if $LOG;

  my $CRS_HOME = get_crs_home( $tfa_home );
  if ( ! $CRS_HOME )
  {
    if($IS_WINDOWS){
      my $result = tfactlwin_query_registry("crs_home");
      my @lines = split(/\n/,$result);
      foreach my $line (@lines){
        my @tokens = split(/\s+/,$line);
        my $tokenArrLength = scalar @tokens;
        if($tokenArrLength>=4){
          $CRS_HOME=trim($tokens[3]);
        }
      }
    }else{
      my $crsd_proc_line = `$PS -ef |$GREP bin/crsd.bin | $GREP -v grep | $SED 's/crsd\.bin.*/crsd.bin/' 2>/dev/null`;
      chomp($crsd_proc_line);
      my @a = split(/\s/, $crsd_proc_line);
      my $crsd_bin = $a[$#a];
      if ( $crsd_bin )
      {
        $crsd_bin =~ s/\/bin\/crsd\.bin//;
        $CRS_HOME = $crsd_bin;
      }
    }
  }
  print $LOG localtime(time) . " dbutil_setOraEnv_1 : CRS_HOME  $CRS_HOME\n" if $LOG;

  my (@out, @error);
  my ($srvctl, $cmd);
  # ---------------------------------
  # $CRS_HOME check begin
  # ---------------------------------
  #### print "CRS_HOME $CRS_HOME\n";
  if ( -d "$CRS_HOME" )
  {
    if ( $db_name eq "+ASM" )
    {
      $ohome = $CRS_HOME;
      $ENV{"ORACLE_HOME"} = $ohome;
      if($IS_WINDOWS){
        $ouser = tfactlwin_get_username_from_service_identifier("OracleASMService");
      }else{
        $ouser = `$PS -ef |$GREP asm_pmon_ |$GREP -v grep |$CUT -d" " -f1`;
        chomp($ouser);
      }
      $srvctl = catfile($CRS_HOME, "bin", "srvctl");
      print $LOG localtime(time) . ": Env for ASM Using ohome:$ohome ouser:$ouser srvctl:$srvctl\n" if $LOG;
    }
     elsif ( lc($db_name) eq "_mgmtdb" )
    {
      $ohome = $CRS_HOME;
      $ENV{"ORACLE_HOME"} = $ohome;
      if($IS_WINDOWS){
        $ouser = tfactlwin_get_username_from_service_identifier("OracleMGMTDBService");
      }else{
        $ouser = `$PS -ef |$GREP mdb_pmon_ |$GREP -v grep |$CUT -d" " -f1`;
        chomp($ouser);
      }
      $srvctl = catfile($CRS_HOME, "bin", "srvctl");
      print $LOG localtime(time) . ": Env for MGMTDB Using ohome:$ohome ouser:$ouser srvctl:$srvctl\n" if $LOG;
    }
     else
    {
      $srvctl = catfile($CRS_HOME, "bin", "srvctl");
      $cmd = "$srvctl config database -d $db_name";
      @out = `$cmd 2>&1`;
      chomp(@out);
      %outhash = map {$_ => 1} @out;
      # PRCD-1229
      @error = grep { /PRCD-/ } @out;
      # PRKR-1078
      @error = (@error, grep { /PRKR-/ } @out );
      @error = (@error, grep { /PRCR-/ } @out );
      print $LOG localtime(time) . " dbutil_setOraEnv_1 : cmd $cmd , out @out, error @error\n" if $LOG;
    }

    #### print "error @error \n";
    #### print "out   @out \n";

    #### foreach my $key (keys %outhash ) {
    ####  print "key $key ..... \n";
    #### }
    
    my @array = grep { $_ =~ s/.*Instead run the program from (.*)\./$1/i} keys %outhash;
    @array = ( @array,grep { $_ =~ s/.*Instead run srvctl from (.*)/$1/i} keys %outhash );
    if ( @array  ){
        $ohome = $array[0];
        $srvctl = catfile($ohome, "bin", "srvctl");
        $cmd = "$srvctl config database -d $db_name -a";
        $ENV{"ORACLE_HOME"} = $ohome;
        if ( $current_user eq "root" )
        {
          my $ouser = tfactlshare_get_dir_file_owner($ohome);
          if($IS_WINDOWS){
          	$cmd = "$cmd";
          }else{
          	$cmd = "su $ouser -c \"$cmd\"";
          }
        }
        @out = `$cmd 2>&1`;
        chomp(@out);
        print $LOG localtime(time) . " dbutil_setOraEnv_1 : cmd $cmd , out @out\n" if $LOG;
    } elsif ( (grep { $_ =~ /The resource for database .*? could not be found/i} keys %outhash) ||
              (grep { $_ =~ /Resource .*? does not exist/i} keys %outhash) ) {
        #### print "==> PRCD-1120\n";
        $srvctl = catfile($CRS_HOME, "bin", "srvctl");
        $cmd = "$srvctl config database";
        @out = `$cmd 2>&1`;
        chomp(@out);
        %outhash = map {uc($_) => 1} @out;      
        foreach my $key ( keys %outhash ) {
           if ( $key =~ /$db_name/i ) {
             #### print "Adjusting db to $key\n";
             $db_name = $key;
             # Retry srvctl command using correct db name
             $cmd = "$srvctl config database -d $db_name -a";
             @out = `$cmd 2>&1`;
             chomp(@out);
           } # end if $key =~ /$db_name/i
        } # end foreach keys %outhash
    } # end if grep ...
  }
  # ---------------------------------
    # else, if ( -d "$CRS_HOME" )
    else
  {
    if ( ! $IS_WINDOWS ) {
      if ( -e "/etc/oratab" )
      {
        $ohome = `$CAT /etc/oratab |$GREP ":/" |$GREP -v "+"|$GREP -v "^#"|$GREP -iw "$db_name:" |$CUT -d: -f2| $HEAD -1`;
        chomp($ohome);
        if ( -d "$ohome" )
        {
          $srvctl = catfile($ohome, "bin", "srvctl");
          $cmd = "$srvctl config database -d $db_name -a";
          $ENV{"ORACLE_HOME"} = $ohome;
          if ( $current_user eq "root" )
          {
            my $ouser = tfactlshare_get_dir_file_owner($ohome);
            $cmd = "su $ouser -c \"$cmd\"";
          }
          @out = `$cmd 2>&1`;
          chomp(@out);
          print $LOG localtime(time) . " dbutil_setOraEnv_1 : cmd $cmd , out @out\n" if $LOG;
        }
      } # end if -e "/etc/oratab"
      if ( ! $ohome && -f "/var/opt/oracle/oratab" )
      {
        $ohome = `$CAT /var/opt/oracle/oratab |$GREP ":/" |$GREP -v "+"|$GREP -v "^#"|$GREP -iw "$db_name:" |$CUT -d: -f2| $HEAD -1`;
        chomp($ohome);
        if ( -d "$ohome" )
        {
          $srvctl = catfile($ohome, "bin", "srvctl");
          $cmd = "$srvctl config database -d $db_name -a";
          $ENV{"ORACLE_HOME"} = $ohome;
          if ( $current_user eq "root" )
          {
            my $ouser = tfactlshare_get_dir_file_owner($ohome);
            $cmd = "su $ouser -c \"$cmd\"";
          }
          @out = `$cmd 2>&1`;
          chomp(@out);
          print $LOG localtime(time) . " dbutil_setOraEnv_1 : cmd $cmd , out @out\n" if $LOG;
        }
      } # end if ! $ohome && -f "/var/opt/oracle/oratab"
    } # end if ! $IS_WINDOWS
  } # end if -d "$CRS_HOME"
  # ---------------------------------
  # $CRS_HOME check end
  # ---------------------------------

  # Retrive DB settings
  foreach my $line(@out)
  {
    if ( $line =~ /Oracle home: (.*)/ )
    {
      $ohome = $1;
    }
     elsif ( $line =~ /ORACLE_HOME: (.*)/ )
    {
      $ohome = $1;
    }
     elsif ( $line =~ /Oracle user: (.*)/ )
    {
      $ouser = $1;
    }
     elsif ( $line =~ /Database instance: (.*)/ )
    {
      $osid = $1;
    }
     elsif ( $line =~ /Database name: (.*)/ )
    {
      $truedb_name = $1;
    }
  } # end foreach @out

  if ( $IS_WINDOWS ) {
      @out = `sc qc OracleService$db_name 2>&1`;
      print $LOG localtime(time) . ": INFO : share_set_ora_env: Gathering service data for OracleService$db_name\n" if $LOG;
      foreach my $line (@out) {
        if ( $line =~ /.*BINARY_PATH_NAME\s+\:\s(.*)\\bin\\ORACLE\.EXE\s(.*)/ ) {
          $ohome = $1;
          chomp($ohome);
          $osid  = $2;
          print localtime(time) . ": INFO : share_set_ora_env: OHOME $ohome and OSID $osid extracted from  OracleService$db_name\n";
          last;
        }
      } # end foreach @out
      $ouser = tfactlwin_get_username_from_service_identifier("OracleService$db_name");
      print localtime(time) . ": INFO : share_set_ora_env : OUSER $ouser extracted from  OracleService$db_name\n";
      ### print "win: ohome $ohome, osid $osid , ouser $ouser\n";
      #
  } # end if $IS_WINDOWS

  # ------------------------
  # ! $ohome begin
  # ------------------------
  if ( ! $ohome )
  {
    #oratab did not offer us any Oracle Home - try other places
    #First try pmap
    #
    # -----------------------
    if(!$IS_WINDOWS){
      my $oracle_proc =`$PS -ef | $GREP -i \"ora_pmon_$db_name\" | $GREP -v grep |$AWK '{print \$2}'`;
      chomp($oracle_proc);
      if ( $IS_AIX ) {
        print $LOG localtime(time) . "Using procmap to determine ORACLE_HOME for DB $db_name\n" if $LOG;
        $ohome = `procmap $oracle_proc | $GREP  lib | $GREP -v usr | $AWK '{print \$NF}'`;
        my @tmp = split /\n/,$ohome;
        $ohome = $tmp[0];
        $ohome =~ s/\/lib\/.*//g;
        if ( -d $ohome ) { 
          print $LOG localtime(time) . "ORACLE_HOME  $ohome found for DB $db_name\n" if $LOG;
        } else {
          print $LOG localtime(time) . "ORACLE_HOME $ohome does not exists \n" if $LOG;
          $ohome = "";
        }
      } else {
        my $pmap_found=`which pmap >/dev/null 2>&1;echo $?`;
        if ( $oracle_proc gt 0 ) { # We found a pmon process for this DB
          if ( $pmap_found == 0 && $oracle_proc gt 0 ) 
          {
            print $LOG localtime(time) . ": Using pmap to determine ORACLE_HOME for DB $db_name\n" if $LOG;
            $ohome=`pmap $oracle_proc | $GREP 'bin\/oracle' | $AWK '{print \$NF}' | $SORT -u | $SED 's/\\/bin\\/oracle//'`; 
            chomp($ohome);
          }
          # Now try pwdx
          my $pwdx_found=`which pwdx >/dev/null 2>&1;echo $?`;
          if ( ! $ohome && $pwdx_found == 0 )
          {
            print $LOG localtime(time) . ": Using pwdx to determine ORACLE_HOME for DB $db_name\n" if $LOG;
            $ohome=`pwdx $oracle_proc | $AWK '{print \$2}' | $SED 's/\\/dbs//'`;
            chomp($ohome);
          }
        }  
      }
    } else {
      # else if !$IS_WINDOWS
      @out = `sc qc OracleService$db_name 2>&1`;
      print $LOG localtime(time) . ": INFO : dbutil_setOraEnv_1: Gathering service data for OracleService$db_name\n" if $LOG;
      foreach my $line (@out) {
        if ( $line =~ /.*BINARY_PATH_NAME\s+\:\s(.*)\\bin\\ORACLE\.EXE\s(.*)/ ) {
          $ohome = $1;
          chomp($ohome);
          $osid  = $2;
          print $LOG localtime(time) . ": INFO : dbutil_setOraEnv_1: OHOME $ohome and OSID $osid extracted from  OracleService$db_name\n" if $LOG;
          last;
        }
      } # end foreach @out
      $ouser = tfactlwin_get_username_from_service_identifier("OracleService$db_name");
      print $LOG localtime(time) . ": INFO : dbutil_setOraEnv_1 : OUSER $ouser extracted from  OracleService$db_name\n" if $LOG;
      ### print "win: ohome $ohome, osid $osid , ouser $ouser\n";
    } # end if !$IS_WINDOWS
    # -----------------------
     
    if ( ! $ohome )
    {
       print $LOG localtime(time) . ": ERROR : dbutil_setOraEnv_1: Could not find oracle_home for $db_name\n" if $LOG;
       return 1;
    } # end if ! $ohome
  }
  # ------------------------
  # ! $ohome end
  # ------------------------

  if ( ! $ouser )
  {
    if ( $IS_WINDOWS )
    {
      $ouser = tfactlshare_get_user((stat($ohome))[4]);
    }
     else
    {
      $ouser = getpwuid((stat($ohome))[4]);
    }
  } # end if ! $ouser

  my $localhost=tolower_host();

  # ---------------------
  # !$IS_WINDOWS begin
  # ---------------------
  if(!$IS_WINDOWS){

    if ( $db_name eq "+ASM" )
    {
      $cmd = "$srvctl status asm";
      @out = `$cmd 2>&1`;
      chomp(@out);
      print $LOG localtime(time) . " dbutil_setOraEnv_1 : cmd $cmd , out @out\n" if $LOG;
      foreach my $line (@out)
      {
         $db_running = 1;
         if ( $line =~ /running on (.*)/ )
         {
           my $hosts = $1;
           my @hosts = split(/,/, $hosts);
           foreach my $ahost (@hosts)
           {
             if ( $localhost eq lc($ahost) )
             {
               $running_local = 1;
               $osid = `$PS -ef |$GREP "asm_pmon_+"| $GREP -v grep | $SED 's/.*asm_pmon_//'`;
               chomp($osid);
               print $LOG localtime(time) . ": SID: $osid for ASM running on local node\n" if $LOG;
             }
            
          }
        }
      }
      #Check if ASM instance is running  but is not well configured via srvctl
      if ( $running_local != 1 ) {
        $osid = `$PS -ef |$GREP "asm_pmon_+"| $GREP -v grep | $SED 's/.*asm_pmon_//'`;
        chomp($osid);
        if ( $osid ) {
          print $LOG localtime(time) . ": ASM instance is not recognized in this node via \'$srvctl status asm\' there might be a configuration issue\n" if $LOG;
          my $sql = "set feedback off heading off lines 120\n";
          $sql .= "select instance_name from v\$instance;\nexit;\n";
          $ENV{"ORACLE_SID"} = $osid;
          my @out  = tfactlshare_run_a_sql("sql",$sql);
          @out = grep { $_ ne "" }@out;
          $osid = $out[0];
          chomp($osid);
          if ( $osid and $osid =~ /\+ASM/ ) {
            $running_local = 1;
            $db_running = 1;
            print $LOG localtime(time) . ": SID: $osid for ASM running on local node\n" if $LOG;
          } else {
            print  $LOG localtime(time) . ": No ASM instance running on local node\n" if $LOG;
          }
        } else {
          print  $LOG localtime(time) . ": No ASM instance running on local node\n" if $LOG;
        }
      }
    }
     elsif ($db_name eq "_mgmtdb" )
    {
      $cmd = "$srvctl status mgmtdb";
      @out = `$cmd 2>&1`;
      chomp(@out);
      print $LOG localtime(time) . " dbutil_setOraEnv_1 : cmd $cmd , out @out\n" if $LOG;
      foreach my $line (@out)
      {
         $db_running = 1;
         if ( $line =~ /running on node (.*)/ )
         {
           my $hosts = $1;
           my @hosts = split(/,/, $hosts);
           foreach my $ahost (@hosts)
           {
             chomp($ahost);
             chomp($localhost);
             if ( $localhost eq lc($ahost) )
             {
               $running_local = 1;
               $osid = `$PS -ef |$GREP "mdb_pmon_-"| $GREP -v grep | $SED 's/.*mdb_pmon_//'`;
               chomp($osid);
               print $LOG localtime(time) . ": SID: $osid for MGMTDB running on local node\n" if $LOG;
             }
          }
        }
      }

    }
     elsif ( ! $CRS_HOME )
    { #SI database
       my $db_running_check = `$PS -ef |$GREP -v grep | $GREP -iw ora_pmon_$db_name`;
       chomp($db_running_check);
       $db_running_check =~ s/^\s+//;
       if ($db_running_check)
       {
         $db_running = 1;
         $running_local = 1;
         #osid could be upper or lower case so need to take it from pmon process
         if ( $db_running_check =~ /ora_pmon_(\w+)/ )
         {
           $osid = $1;
         }
          else
         {
           $osid = $db_name;
         }
         my @a = split(/\s/, $db_running_check);
         $ouser = $a[0];
       } # end if $db_running_check
    }
     else
    {
      $cmd = "$srvctl status database -d $db_name |$GREP \"is running\"";
      @out = `$cmd 2>&1`;
      chomp(@out);
      print $LOG localtime(time) . " dbutil_setOraEnv_1 : cmd $cmd , out @out\n" if $LOG;
      foreach my $line (@out)
      {
         $db_running = 1;
         if ( $line =~ /Instance (.*) is running on node (.*)/ )
         {
           if ( $localhost eq lc($2) )
           {
             $running_local = 1;
             $osid = $1;
           } 
         }
       #in SIHA srvctl status shows Database is running
        elsif ( $line =~ /Database is running/ )
        {
          $running_local = 1;
          #but the instance might not be part of the db_name
          $cmd = "$srvctl config database -d $db_name |$GREP \"Database instance:\"";
          $osid = `$cmd 2>&1`;
          $osid =~ s/Database instance: //;
          chomp($osid);
        }
      }
    } # end if $db_name eq "+ASM"
  } else {
    # --------------------------------------
    # Windows, check if DB is running
    # Find out the ORACLE_SID for $db_name
    # --------------------------------------
    ($osid,$db_running,$running_local) = dbutil_iswindbrunning($db_name);

  } # end if !$IS_WINDOWS
  # ---------------------
  # !$IS_WINDOWS end
  # ---------------------

  if ( $db_running == 0 )
  {
    print $LOG localtime(time) . " : ERROR : dbutil_setOraEnv_1: $db_name is not running.\n" if $LOG;
    return 1;
  }

  return 0;
} #End sub dbutil_setOraEnv_1

sub dbutil_setOraEnv_2 
{
   # DB is down try to find details
   print $LOG localtime(time) .  " : Database $db_name is down  trying other methods to determine ENV.\n" if $LOG;
   my $inventoryDirectory = getInventoryLocation( $tfa_home, $hostname );
   my $metadataDirectory;
   my $inv = catfile($inventoryDirectory, "inventory.xml");
   my $timeline;
   my $alertfile="";
   my $cmdout="";
   my $command="";

   if ( $IS_WINDOWS ) {
     $command = "type $inv | findstr /r \"diag[\\/\\\\]rdbms[\\/\\\\].*alert.*\\.log\" 2>&1";
   } else {
     $command = "$CAT $inv | $GREP 'diag[\/\\]rdbms[\/\\].*alert.*\.log'";
     $command .= " 2>&1" if ( !$CSH );
   }
   $cmdout = "";
   $cmdout = osutils_runtimedcommand($command,100,TRUE,$LOG) if -f $inv;

   my @lines = split /\n/ ,$cmdout;

   if ( @lines ) {
     # First alternative,
     # Look for ORACLE_HOME in rdbms alert.log file
     foreach my $auxalertfile (@lines) {
       if ( $auxalertfile =~ /.*\<file_name\>(.*diag[\/\\]rdbms[\/\\]$db_name[\/\\].*[\/\\].*\.log)\<\/file_name\>.*/i ) {
         $alertfile = $1;
         if ( $alertfile =~ /.*diag[\/\\]rdbms[\/\\]$db_name[\/\\](.*)[\/\\]trace[\/\\].*\.log/i ) {
           $osid = $1;
         }
         if ( $IS_WINDOWS ) {
           my @lines;
           $command = "type $alertfile | findstr /i \"ORACLE_HOME=\" 2>&1";
           $cmdout = "";
           $cmdout = osutils_runtimedcommand($command,100,TRUE,$LOG) if -r $alertfile;
           @lines = split /\n/ ,$cmdout;
           $cmdout = $lines[0];
         } else {
           $command = "$CAT $alertfile | $GREP -m 1 \"ORACLE_HOME=\"";
           $command .= " 2>&1" if ( !$CSH );
           $cmdout = osutils_runtimedcommand($command,100,TRUE,$LOG);
         }
         if ( $cmdout =~ /.*ORACLE_HOME\s*[\:\=]\s+(.*)/ ) {
           $ohome = trim($1);
         }
       } # end if $auxalertfile =~ ...
     } # end foreach
     print $LOG localtime(time) .  " dbtil_setOraEnv_2 : Db down - first alternative -> inv $inv osid $osid alert $alertfile ohome $ohome db_name $db_name.\n" if $LOG;
   } else {
     print $LOG localtime(time) .  " dbtil_setOraEnv_2 : Db down - Unable to open inventory\n" if $LOG;
   } # end if @lines 

   if ( ! (length $ohome and length $osid )) { # second alternative - check timeline
     # Second alternative,
     # Look for ORACLE_HOME in timeline.out
     # ------------------------------------

     if ( $inventoryDirectory =~ /(.*)[\/\\]inventory/ ) {
       $metadataDirectory = $1;
       $timeline = catfile($metadataDirectory,"metadata","timeline.out");
     }
      my @lines;
      if ( -e "$timeline" ) {
        if ( $IS_WINDOWS ) {
          $command = "type $timeline | findstr /i /r \"db\.$db_name\..*\.ORACLE_HOME\.value\" 2>&1";
          $cmdout = "";
          $cmdout = osutils_runtimedcommand($command,100,TRUE,$LOG) if -r $timeline;
          @lines = split /\n/ , $cmdout;
          $cmdout = $lines[0] if $lines[0];
        } else {
          $command = "$CAT $timeline | $GREP -i -m 1 'db\.$db_name\..*\.ORACLE_HOME\.value'";
          $command .= " 2>&1" if ( !$CSH );
          $cmdout = osutils_runtimedcommand($command,100,TRUE,$LOG);
        }
      } else {
        print "File $timeline is not yet created so please wait until this file is created \n";
      }
      if ( $cmdout =~ /db\.$db_name\..*\.ORACLE_HOME\.value\s+[\=]\s+(.*)/i ) {
        $ohome = $1;
        chomp($ohome);
      }

      if ( -e $inv ){
        if ( $IS_WINDOWS ) {
          $command = "type $inv | findstr /i /r \"\<base_directory\>.*[\\/\\\\]diag[\\/\\\\]rdbms[\\/\\\\]" . $db_name . "[\\/\\\\].*\" 2>&1";
          $cmdout = "";
          $cmdout = osutils_runtimedcommand($command,100,TRUE,$LOG) if -r $inv;
          @lines = split /\n/ , $cmdout;
          $cmdout = $lines[0] if $lines[0];
        } else {
          $command = "$CAT $inv | $GREP -i -m 1 '\<base_directory\>.*[\/\\]diag[\/\\]rdbms[\/\\]" . $db_name . "[\/\\].*'";
          $command .= " 2>&1" if ( !$CSH );
          $cmdout = osutils_runtimedcommand($command,100,TRUE,$LOG);
        }
        if ( $cmdout =~ /\<base_directory\>.*[\/\\]diag[\/\\]rdbms[\/\\]$db_name[\/\\](.*)[\/\\].*\<\/base_directory\>/i ) {
          $osid = $1;
          chomp($osid);
        }
     } else {
       print "File $inv does not exist\n";
     }
   } #End if ( ! (length $ohome and length $osid )


   if (length $ohome and length $osid){
     print $LOG localtime(time) .  " dbtil_setOraEnv_2 : Db down - second alternative -> inv $inv ohome $ohome sid $osid.\n" if $LOG;

     if ( $IS_WINDOWS ) {
       $command = "set ORACLE_HOME=$ohome && \$ORACLE_HOME\\bin\\orabase 2>&1";
       $orabase = osutils_runtimedcommand($command,100,TRUE,$LOG);
       chomp($orabase);
       $ouser = "root";
     } else {
       $command = "export ORACLE_HOME=$ohome; \$ORACLE_HOME/bin/orabase";
       $command .= " 2>&1" if ( !$CSH );
       $orabase = osutils_runtimedcommand($command,100,TRUE,$LOG);
       chomp($orabase);
       $ouser = getFileOwner($orabase);
     }
     return 0;
   } else {
     print $LOG localtime(time) .  " dbtil_setOraEnv_2 : Db down - second alternative unable to set environment for $db_name\n" if $LOG;
   } # end if length $ohome and length $osid

   print $LOG localtime(time) .  " dbtil_setOraEnv_2 : Db down - completed alternatives.\n" if $LOG;
   return 1;
} #End dbtil_setOraEnv_2

sub dbutil_get_database_details {
  my $tfa_setup = shift;
  my $dbName = "";
  my $dbDetails = "";
  my @retArr;

  if ( ! -f "$tfa_setup" ) {
    my $home_dir = getHomeDirectory();
    $home_dir = catfile($home_dir, ".tfa");

    if ( -f catfile($home_dir, "tfa_setup.txt") ) {
      $tfa_setup = catfile($home_dir, "tfa_setup.txt");
    } else {
      return \@retArr;
    }
  }

  my @tfasetup_contents = tfactlshare_readFileToArray($tfa_setup);

  for (my $i = 0; $i <= $#tfasetup_contents; $i++) {
    my $line = $tfasetup_contents[$i];
    chomp($line);
    my %db_hash;

    if ($line =~ /^DB_NAME=(.*)$/) {      
      $dbDetails = $1;
      $dbName =  (split /\|/, $dbDetails)[0];
      $db_hash{"NAME"} = $dbName;
      $db_hash{"HOME"} = (split /\|/, $dbDetails)[2];
      $db_hash{"SID"} = "";

      my $j;
      for ($j = $i; $tfasetup_contents[$j] !~ /$dbName\%ISDBRUNNING=/ && $j <= $#tfasetup_contents; $j++) {
        if ($tfasetup_contents[$j] =~ /$hostname%$dbName%INSTANCE_NAME=(.*)/) {
          $db_hash{"SID"} = $1;
        } 
      }

      $db_hash{"USER"} = dbutil_getHomeOwner($db_hash{"HOME"});
      
      push @retArr, \%db_hash;
      $i = $j;
    }
  }

  return \@retArr;
}
 
sub dbutil_getHomeOwner {
  my $dbHome = shift;
  my $oracle_user = "";

  if (-d $dbHome) {
    if ($IS_WINDOWS) {

    } else {
      my $PLATFORM = $^O;
      if ( $PLATFORM eq "linux" ) {
            my $loc = catfile($dbHome, "bin", "oracle");
            $oracle_user = `$STAT -L -c "%U" $loc`;
          } else {
            my $loc = catfile($dbHome, "bin", "oracle");
            $oracle_user = `$LS -l $loc|$AWK '{print \$3}'`;
          }
      }
      chomp($oracle_user);
  }

  return $oracle_user;
}

1;
