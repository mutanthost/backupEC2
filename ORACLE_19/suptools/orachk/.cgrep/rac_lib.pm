#!/usr/bin/perl -w
# $Header: tfa/src/orachk_py/scripts/rac_lib.pm /main/2 2017/09/13 22:55:20 rojuyal Exp $
#
# rac_lib.pm
# 
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      rac_lib.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    rkchaura    03/10/16 - Filechecker Integration
#    rkchaura    03/10/16 - Creation
# 



package rac_lib ;

$VERSION = "1.0" ;

use Exporter;
use English;
use File::Copy;
use File::Path;
use File::Find;
use File::Basename;
use File::Spec::Functions ;
use File::Spec::Functions qw(rel2abs catfile catdir) ;
use List::Util qw(max);
use POSIX qw(strftime);
use Sys::Hostname;
use Cwd;    # getcwd, abs_path($f), realpath($f)
use Time::Local;
use Config;
use Data::Dumper;


use vars qw(@DoW @MoY %MoY);

use constant TRUE  => "1" ;
use constant FALSE => "0" ;

our @ISA = qw(Exporter);

# Exported functions and variables
our @EXPORT = qw (
  $ME
  $HOST
  $PLATFORM
  $SCRIPT_NAME
  $CWD
  $INST_LOC
  $ORA_TAB
  $INIT_OHASD
  $ACFSUTL
  $PSP
  $PS
  $DF
  $CAT
  $CUT
  $AWK
  $SED
  $GREP
  $EGREP
  $ECHO
  $LS
  $HEAD
  $TAIL
  $ID
  $SU
  $TAR
  $RMF
  $GZIP
  $MV
  $SSH
  $LSOF
  $FUSER
  $MAIL

  $ORA_INVENTORY
  $CRS_HOME
  $CRS_BASE
  $CRS_OWNER
  $CRS_GROUP
  $CLUSTER_NAME
  $ORA_DBA_GROUP
  $ORA_ASM_GROUP
  $ORAINST
  $ORATAB
  $OCR_LOC
  $OCR_LOC_DIR
  $LASTGASP_DIR
  $OPROCD_DIR
  $SCLS_SCR_DIR
  $ASMLIB_DIR
  $VAR_TMP_DIR
  $TMP_DIR

  $CRSCTL
  $ACFSUTIL
  $LSOF
  $FUSER
  $LOGSUFFIX
  $ASM_SID
  %TAGFILES
  %OPENFILES
  $TAGNAME
  $TAG_SUPPORT
  $AGE
  $SPACE_OS
  $SPACE_ACFS
  $PERCENT_OS
  $FORCE_PERCENT_OS
  $PERCENT_ACFS
  $FORCE_PERCENT_ACFS
  $FORCE_DELETION_OS
  $FORCE_DELETION_ACFS
  $CHECK_INTERVAL
  $SIZE
  $RES_NMAE
  $EMAIL_ADDRESS
  $EMAIL_TXT
  $EMAIL_FLAG
  $RESOURCE_RUNNING_FLAG
  $TAGNAME
  $PIDFILE
  $PSP
  $ALERT_LOG

  $RESMON_PROC_LST
  $RESMON_RT_LST
  $RESMON_INTERVAL
  $RESMON_COUNT
  $SCRIPT_RESMONITOR
  $FILE_CHECKER_SCRIPT
  $OCLUMON
  @NODE_LST
  $CRS_VER

  $RESOURCE_NAME
  $CHECK_DIRS
  $UNCHECK_DIRS
  $SCRIPT_INSTMONITOR
  $SCRIPT_NODEMONITOR
  $NODEMON_INTERVAL
  $INSTMON_INTERVAL
  $NODEMON_TIMESTEP
  $INSTMON_TIMESTEP
  %INSTANCE2NODE
  %DB2ALERTLOG
  @DB4DUMP



  @del_file
  exec_OS_cmd
  get_attribute_value_from_env
  get_attribute_value_of_resource
  get_output_dir
  get_db_list
  get_partition_size
  is_on_acfs
  coreanalyze
  get_ASM_log_dest
  get_DB_log_dest
  send_mail
  open_files
  is_opened
  get_age_acfs
  get_delfile_acfs
  is_taged
  get_tag_files
  wrap_set_tag_acfs
  set_tag_acfs
  get_policy_setting
  set_pid_record
  get_pid_numbers
  remove_pid_record
  do_file_deletion
  start_set_tag
  check_space
  dietrap_mon
  check_user

  unique
  SetDiff
  SetIntersect
  SetUnion
  SetXor
  get_current_time
  str2time
  Logger
  read_file
  write_file
  append_file

  proc_analyse
  proc_monitor_handler
  killall_pids

  node_monitor_handler
  inst_monitor_handler
);

# Subroutine test usage if set to TRUE
my $debug = FALSE;

my ($PDEBUG)    = $ENV{RAT_PDEBUG}||0; #Rajeev

# These variables are needed by str2time of HTTP:Date
@DoW       = qw(Sun Mon Tue Wed Thu Fri Sat);
@MoY       = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
@MoY{@MoY} = ( 1 .. 12 );
our %GMT_ZONE = ( GMT => 1, UTC => 1, UT => 1, Z => 1 );

our $LOGSUFFIX = '(\.trc)|(\.trm)|(\.log)|(\.l\d\d)';
our ( $AGE, $SPACE_OS, $SPACE_ACFS, $PERCENT_OS, $PERCENT_ACFS, $SIZE,
  $CHECK_INTERVAL );
our (
  $FORCE_PERCENT_OS,  $FORCE_PERCENT_ACFS,
  $FORCE_DELETION_OS, $FORCE_DELETION_ACFS
);

#below global defined for proc_snapshot and rt_monitor function
our ($RESMON_PROC_LST, $RESMON_RT_LST, @NODE_LST) ;
our $FILE_CHECKER_SCRIPT = ".cgrep/rac_file_checker.pl" ;     #This line changed by Rajeev for orachk integration.
our $VERSION_12_1 = 120000 ;
our ($NODEMON_INTERVAL, $NODEMON_TIMESTEP,@DB4DUMP);
our ($INSTMON_INTERVAL, $INSTMON_TIMESTEP, %INSTANCE2NODE, %DB2ALERTLOG);



# The resource name we added
our $RESOURCE_NAME = "FileChecker" ;
our $CHECK_DIRS = "" ; #Rajeev
our $UNCHECK_DIRS = "" ;



our $ME = (getpwuid($<))[0] ;
our $SCRIPT_NAME = rel2abs($0) ;   # the absolute path of this script name
our $CWD = dirname($SCRIPT_NAME) ; # the directory where this script resides


# May set the Email address here to receive the notification
our $EMAIL_ADDRESS ;
our $TAGNAME = "AGEDFILE" ;

# Send Email or not
our $EMAIL_FLAG;

# Support TAG or not
our $TAG_SUPPORT;

#Added by Rajeev
sub get_output_dir {
   my $FILECHECK_OUTPUT_DIR = shift|| $ENV{FILECHECK_OUTPUT_DIR};
   if ( $FILECHECK_OUTPUT_DIR eq "" )
   {
     $FILECHECK_OUTPUT_DIR = getcwd();
  }
  return $FILECHECK_OUTPUT_DIR;
}

     


# Record files of script
our $PIDFILE ;
our $ALERT_LOG = catfile(get_output_dir(), "alert.log") ; #Rajee


# Email body File
our $EMAIL_TXT = catfile(get_output_dir(), "Email_Warning") ;


our $RESOURCE_RUNNING_FLAG = catfile(get_output_dir(), "${RESOURCE_NAME}_RESOURCE_FLAG") ;

chomp(our $HOST = hostname) ;

#Record CRS version
our $CRS_VER ;

# If the hostname is an IP address, let hostname remain as IP address
# Else, strip off domain name in case /bin/hostname returns FQDN
# hostname
unless ( $HOST =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ ) {
  ( $HOST, ) = split( /\./, $HOST );
}
# convert to lower case
$HOST =~ tr/A-Z/a-z/ ;



# Platform info
our $PLATFORM = $^O ;



#key is node name, value is position of starter line of new records
our %NODE2LINE;

#This var save line postion for cluster/rdbms alert line read last time
our $ALERTLINE;

#threshold of memory growth rate is 0.2MB/s
$MEMORY_LEAK_RATE_THRESHOLD = 0.2;

#more then 3 FDs/HR
$FD_LEAK_RATE_THRESHOLD = 3;

#more then 3 TRDs/HR
$THREAD_LEAK_RATE_THRESHOLD = 3;

#If cpu usage more than 3% as spin cpu
$SPIN_CPU_THRESHOLD = 3;

#TRUE, save the position of $mynode_proc_mon.log, then proc_analyse get data from this location
$isSavePosition = TRUE;

#Hash for recode evcition event
our %TIME2EVENT;

# OS depedentant variables
our ($INST_LOC, $ORA_TAB, $INIT_OHASD) ;
our ($ACFSUTL, $PSP, $PS, $DF, $CAT, $CUT, $AWK, $SED, $GREP, $EGREP, $ECHO, $LS, $HEAD, $TAIL, $ID, $SU, $TAR, $RMF, $GZIP, $MV, $SSH) ;
our ($LSOF, $FUSER, $MAIL ) ;
our ($ORAINST, $ORATAB, $OCR_LOC, $OCR_LOC_DIR, $LASTGASP_DIR, $OPROCD_DIR, $SCLS_SCR_DIR, $ASMLIB_DIR, $VAR_TMP_DIR, $TMP_DIR) ;

#Priority $CSS_RT is for ocssd.bin/cssdagent.bin/cssdmonitor;$CRF_RT is for osysmon.bin/ologger.bin;$NONE_ROOT_RT is for vktm/lms
our ( $CSS_RT, $CRF_RT, $NONE_ROOT_RT );

if ( $PLATFORM eq "linux" ) {
  $INST_LOC   = catfile( rootdir, "etc", "oraInst.loc" );
  $ORA_TAB    = catfile( rootdir, "etc", "oratab" );
  $INIT_OHASD = catfile( rootdir, "etc", "init.d", "init.ohasd" );
  $ACFSUTIL = "/sbin/acfsutil ";
  $PSP          = "/bin/ps -p ";
  $PS           = "/bin/ps ";
  $DF           = "/bin/df -k ";
  $CAT          = "/bin/cat";
  $CUT          = "/usr/bin/cut";
  $AWK="/bin/awk";
  $SED="/bin/sed";
  $GREP="/bin/grep";
  $EGREP="/bin/egrep";
  $ECHO="/bin/echo";
  $LS           = "/bin/ls ";
  $HEAD = "/usr/bin/head" ;
  $TAIL="/usr/bin/tail";
  $ID           = "/usr/bin/id ";
  $SU           = "/bin/su ";
  $LSOF         = "/usr/sbin/lsof ";
  $FUSER        = "/sbin/fuser ";
  $TAR          = "/bin/tar ";
  $RMF          = "/bin/rm -f ";
  $GZIP         = "/bin/gzip ";
  $MV           = "/bin/mv ";
  $MAIL         = "/bin/mailx ";
  $SSH          ="/usr/bin/ssh";
  $CSS_RT       = -100;
  $CRF_RT       = -100;
  $NONE_ROOT_RT = -2;
  $TMP_DIR = "/tmp" ;
  $VAR_TMP_DIR = "/var/tmp" ;
  $ORAINST = "/etc/oraInst.loc";
  $ORATAB = "/etc/oratab" ;
  $OCR_LOC = "/etc/oracle/ocr.loc" ;
  $OCR_LOC_DIR = "/etc/oracle" ;
  $LASTGASP_DIR = "/etc/oracle/lastgasp";
  $OPROCD_DIR = "/etc/oracle/oprocd";
  $SCLS_SCR_DIR = "/etc/oracle/scls_scr";
  $ASMLIB_DIR = "/opt/oracle/extapi" ;
} elsif ( $PLATFORM eq "aix" ) {
  $INST_LOC   = catfile( rootdir, "etc", "oraInst.loc" );
  $ORA_TAB    = catfile( rootdir, "etc", "oratab" );
  $INIT_OHASD = catfile( rootdir, "etc", "init.ohasd" );
  $ACFSUTIL = "" ;    # Do not support ACFS on AIX
  $PSP   = "/bin/ps -p ";
  $PS    = "/bin/ps ";
  $DF    = "/bin/df -k";
  $CAT   = "/bin/cat";
  $CUT   = "/bin/cut";
  $AWK="/bin/awk";
  $SED="/bin/sed";
  $GREP="/bin/grep";
  $EGREP="/bin/egrep";
  $ECHO="/bin/echo";
  $LS    = "/bin/ls ";
  $HEAD = "/usr/bin/head" ;
  $TAIL="/usr/bin/tail";
  $ID    = "/bin/id ";
  $SU    = "/usr/bin/su ";
  $LSOF  = "/usr/sbin/lsof ";    # Do not have default LSOF on AIX
  $FUSER = "/usr/sbin/fuser ";
  $TAR   = "/bin/tar ";
  $RMF   = "/bin/rm -f ";
  $GZIP  = "/bin/gzip ";
  $MV    = "/bin/mv ";
  $MAIL  = "/bin/mailx ";
  $SSH = "/usr/bin/ssh";
  $CSS_RT       = 0;
  $CRF_RT       = 0;
  $NONE_ROOT_RT = 39;
  $TMP_DIR = "/tmp" ;
  $VAR_TMP_DIR = "/var/tmp" ;
  $ORAINST = "/etc/oraInst.loc";
  $ORATAB = "/etc/oratab" ;
  $OCR_LOC = "/etc/oracle/ocr.loc";
  $OCR_LOC_DIR = "/etc/oracle";
  $LASTGASP_DIR = "/etc/oracle/lastgasp";
  $OPROCD_DIR = "/etc/oracle/oprocd";
  $SCLS_SCR_DIR = "/etc/oracle/scls_scr";
  $ASMLIB_DIR = "/opt/oracle/extapi" ;
} elsif ( $PLATFORM eq "solaris" ) {
  $INST_LOC = catfile( rootdir, "var", "opt", "oracle", "oraInst.loc" );
  $ORA_TAB  = catfile( rootdir, "var", "opt", "oracle", "oratab" );
  $INIT_OHASD = catfile( rootdir, "etc", "init.d", "init.ohasd" );
  $ACFSUTIL = "/sbin/acfsutil ";
  $PSP = "/bin/ps -p ";
  $PS = "/bin/ps ";
  $DF  = "/bin/df -k ";
  if ( -e "/usr/xpg4/bin/cat" ) {
    $CAT="/usr/xpg4/bin/cat";
  } else {
    $CAT="/usr/bin/cat";
  }
  if ( -e "/usr/xpg4/bin/cut" ) {
    $CUT="/usr/xpg4/bin/cut";
  } else {
    $CUT="/usr/bin/cut";
  }
  if ( -e "/usr/xpg4/bin/awk" ) {
    $AWK="/usr/xpg4/bin/awk";
  } else {
    $AWK="/usr/bin/awk";
  }
  if ( -e "/usr/xpg4/bin/sed" ) {
    $SED="/usr/xpg4/bin/sed";
  } else {
    $SED="/usr/bin/sed";
  }
  if ( -e "/usr/xpg4/bin/grep" ) {
    $GREP="/usr/xpg4/bin/grep ";
  } else {
    $GREP="/usr/bin/grep";
  }
  if ( -e "/usr/xpg4/bin/egrep" ) {
    $EGREP="/usr/xpg4/bin/egrep";
  } else {
    $EGREP="/usr/bin/egrep";
  }
  $ECHO="/usr/bin/echo";
  $LS  = "/bin/ls ";
  if ( -e "/usr/xpg4/bin/head" ) {
    $HEAD="/usr/xpg4/bin/head";
  } else {
    $HEAD="/usr/bin/head";
  }
  if ( -e "/usr/xpg4/bin/tail" ) {
    $TAIL="/usr/xpg4/bin/tail";
  } else {
    $TAIL="/usr/bin/tail";
  }
  $ID  = "/bin/id ";
  $SU  = "/bin/su ";
  $SSH = "/usr/bin/ssh";
  $PRSTAT = "/usr/bin/prstat";
  if ( -f "/usr/local/bin/lsof" ) {
    $LSOF = "/usr/local/bin/lsof ";   # Default lsof location on our SunOS nodes
  }
  else {
    $LSOF = "/sur/sbin/lsof ";
  }
  $FUSER        = "/usr/sbin/fuser ";
  $TAR          = "/usr/local/bin/tar ";
  $RMF          = "/bin/rm -f ";
  $GZIP         = "/usr/local/bin/gzip ";
  $MV           = "/usr/local/bin/mv ";
  $MAIL         = "/bin/mailx ";
  $CSS_RT       = 100;
  my @ret = exec_OS_cmd ("/bin/uname -r");
  chomp @ret;
  if ( $ret[0] eq "5.11" ){
    $CRF_RT       = 100;
  } else {
    $CRF_RT       = 159;
  }

  $NONE_ROOT_RT = 101;
  $TMP_DIR = "/tmp" ;
  $VAR_TMP_DIR = "/var/tmp" ;
  $ORAINST = "/var/opt/oracle/oraInst.loc";
  $ORATAB = "/var/opt/oracle/oratab" ;
  $OCR_LOC = "/var/opt/oracle/ocr.loc";
  $OCR_LOC_DIR = "/var/opt/oracle";
  $LASTGASP_DIR = "/var/opt/oracle/lastgasp";
  $OPROCD_DIR = "/var/opt/oracle/oprocd";
  $SCLS_SCR_DIR = "/var/opt/oracle/scls_scr";
  $ASMLIB_DIR = "/opt/oracle/extapi" ;
} elsif ( $PLATFORM eq "hpux" ) {
  $INST_LOC   = catfile( rootdir, "var",  "opt", "oracle", "oraInst.loc" );
  $ORA_TAB    = catfile( rootdir, "etc",  "oratab" );
  $INIT_OHASD = catfile( rootdir, "sbin", "init.d", "init.ohasd" );
  $ACFSUTIL = "/sbin/acfsutil " ;    # Do not support ACFS on HPI
  $PSP   = "/usr/bin/ps -p ";
  $PS    = "/usr/bin/ps ";
  $DF    = "/usr/bin/bdf ";
  $CAT   = "/usr/bin/cat";
  $CUT   = "/usr/bin/cut";
  $AWK="/usr/bin/awk";
  $SED="/usr/bin/sed";
  $GREP="/usr/bin/grep";
  $EGREP="/usr/bin/egrep";
  $ECHO="/usr/bin/echo";
  $LS    = "/usr/bin/ls ";
  $HEAD = "/bin/head" ;
  $TAIL="/bin/tail";
  $ID    = "/usr/bin/id ";
  $SU    = "/usr/bin/su ";
  $LSOF  = "/usr/sbin/lsof ";          # Need to install
  $FUSER = "/usr/sbin/fuser ";
  $TAR   = "/usr/local/bin/tar ";
  $RMF   = "/usr/bin/rm -f ";
  $GZIP  = "/usr/contrib/bin/gzip ";
  $MV    = "/usr/bin/mv ";
  $MAIL  = "usr/bin/mailx ";
  $TMP_DIR = "/tmp" ;
  $VAR_TMP_DIR = "/var/tmp" ;
  $ORAINST = "/var/opt/oracle/oraInst.loc" ;
  $ORATAB = "/etc/oratab" ;
  $OCR_LOC = "/var/opt/oracle/ocr.loc";
  $OCR_LOC_DIR = "/var/opt/oracle";
  $LASTGASP_DIR = "/var/opt/oracle/lastgasp";
  $OPROCD_DIR = "/var/opt/oracle/oprocd";
  $SCLS_SCR_DIR = "/var/opt/oracle/scls_scr";
  $ASMLIB_DIR = "/opt/oracle/extapi" ;
} else {

  # Should not enter here
  Logger("Unknow OS type: $PLATFORM!\n");
  exit 1;
}


&Get_RAC_Environment ;




our $CRSCTL = catfile( "$CRS_HOME", "bin", "crsctl" );
our $SRVCTL = catfile( "$CRS_HOME", "bin", "srvctl" );
our $OLSNODES = catfile( "$CRS_HOME", "bin", "olsnodes" );
our $OCLUMON = catfile( "$CRS_HOME", "bin", "oclumon" );




# Subroutines
# Clusterware Information Query Related
our ($ORA_INVENTORY, $CRS_HOME, $CRS_BASE, $CRS_OWNER, $CRS_GROUP, $CLUSTER_NAME, $ORA_DBA_GROUP, $ORA_ASM_GROUP) ;
sub Get_RAC_Environment {
  if ( -f "$ORAINST" && -f "$ORATAB" ) {
    chomp($ORA_INVENTORY = `$CAT $ORAINST | $GREP "inventory_loc=" | $CUT -d "=" -f2`) ;
    chomp($CRS_GROUP = `$CAT $ORAINST | $GREP "inst_group=" | $CUT -d "=" -f2`) ;

    if ( defined $ORA_INVENTORY ) {
      my $inventory_xml = "$ORA_INVENTORY/ContentsXML/inventory.xml" ;
      if ( -f "$inventory_xml" ) {
        chomp(my $tmp = `$GREP 'CRS="true"' $inventory_xml | wc -l`) ;
        if ( $tmp >= 1 ) {
          chomp($CRS_HOME=`$CAT $inventory_xml | $GREP 'CRS="true"' | $TAIL -1 | $CUT -d '"' -f4`) ;
        } else {
          chomp($CRS_HOME=`$CAT $inventory_xml | $GREP 'IDX="1"' | $GREP 'NAME="OraGI' | $CUT -d '"' -f4`) ;
        }

        if ( -f "$CRS_HOME/crs/install/crsconfig_params" ) {
          chomp($CLUSTER_NAME = `$CAT $CRS_HOME/crs/install/crsconfig_params | $GREP "^CLUSTER_NAME=" | $CUT -d '=' -f2`) ;
          chomp($ORA_DBA_GROUP = `$CAT $CRS_HOME/crs/install/crsconfig_params | $GREP "^ORA_DBA_GROUP=" | $CUT -d '=' -f2`) ;
          ($ORA_DBA_GROUP eq "") && ($ORA_DBA_GROUP = $CRS_GROUP) ;
          chomp($ORA_ASM_GROUP = `$CAT $CRS_HOME/crs/install/crsconfig_params | $GREP "^ORA_ASM_GROUP=" | $CUT -d '=' -f2`) ;
          ($ORA_ASM_GROUP eq "") && ($ORA_ASM_GROUP = $CRS_GROUP) ;
        }

        if ( defined $CRS_HOME ) {
          if ( -d "$CRS_HOME" ) {
            $ENV{'ORACLE_BASE'} = "" ; # unset ORACLE_BASE so it won't affect the correct result of orabase
            $ENV{'ORACLE_HOME'} = $CRS_HOME ;
            chomp($CRS_BASE = `$CRS_HOME/bin/orabase 2>/dev/null`) ;
            $CRS_BASE eq "" && chomp($CRS_BASE = `[ -f "$CRS_HOME/crs/install/crsconfig_params" ] && $CAT $CRS_HOME/crs/install/crsconfig_params | $GREP "ORACLE_BASE=" | $CUT -d "=" -f2`) ;

            chomp($CRS_OWNER = `[ -f "$CRS_HOME/crs/install/crsconfig_params" ] && $CAT $CRS_HOME/crs/install/crsconfig_params | $GREP "ORACLE_OWNER=" | $CUT -d "=" -f2`) ;;
          } else {
            die("Can not find CRS_HOME dir \"$CRS_HOME\" on current node, please check it manually !\n");
          }
        } else {
          die("Can not get CRS_HOME from $inventory_xml, please check the inventory file manually !\n");
        }

      } else {
        die("Can not find file $inventory_xml under $ORA_INVENTORY/ContentsXML, please check it manually !\n");
      }      
     
    } else {
      die("Broken oraInst.loc file: the contents of the file $ORAINST is broken, please check it manually !\n");
    }
    
  } else {
    die("Can not find CRS Inventory File $ORAINST on your system, please make sure you have already installed CRS correctly !\n");
  }
}





# Activeversion or release version?
sub get_cluster_version {
  my @activeversion  = exec_OS_cmd("$CRSCTL query crs activeversion");
  my @releaseversion = exec_OS_cmd("$CRSCTL query crs releaseversion");
}

# Check Stack status
# Input: None
# Output: TRUE when stack online
#         FALSE when stack offline
sub is_stack_online {
  my @result = exec_OS_cmd("$CRSCTL check crs");
  foreach my $tmp (@result) {
    if ( $tmp =~ m/CRS-4000|CRS-4639/ ) {
      return FALSE;
    }
    else {
      next;
    }
  }

  return TRUE;
}




# Get resource attribute
# Parameter1: resource name
# Parameter2: resource attribute1
# Return: resource attribute value if successful
#         else return NONE
#
#Rajeev

sub get_attribute_value_from_env {
  my $res_attr = $_[0] ;
  my $ret ;

  if ( $res_attr eq "CHECK_DIRS" )
  {
    #Rajeev Kumar
    $ret = shift|| $ENV{CHECK_DIRS};
    return $ret ;
  }
  if ( $res_attr eq "CHECK_NODES" )
  {
    $ret = shift|| $ENV{CHECK_NODES};
    return $ret ;
  }

  return ;
}



sub get_attribute_value_of_resource {
  my $res_name = $_[0] ;
  my $res_attr = $_[1] ;
  my $ret ;

  my @result = exec_OS_cmd("$CRSCTL stat res $res_name -p") ;
  foreach my $tmp (@result) {
    if ( $tmp =~ m/$res_attr/ ) {
      chomp $tmp ;
      $ret = ( split( /=/, $tmp ) )[-1] ;
      chomp $ret ;
      return $ret ;
    }
  }
  return ;
}





# Get ASM SID
# Input: None
# Output: Local ASM SID
sub get_asm_sid {
  my $asm_sid =
    get_attribute_value_of_resource( "ora.asm",
    "GEN_USR_ORA_INST_NAME\\\@SERVERNAME\\\($HOST\\\)" );
  return $asm_sid;
}

our $ASM_SID = get_asm_sid();
if ($debug) {
  Logger("ASM SID: $ASM_SID\n");
}

# Get Local DB SID
# Input: DB Name
# Output: Local DB SID
sub get_db_sid {
  my $dbname = shift;
  my $db_sid =
    get_attribute_value_of_resource( "ora\.${dbname}\.db",
    "GEN_USR_ORA_INST_NAME\\\@SERVERNAME\\\($HOST\\\)" );
}
if ($debug) {
  $tmp = get_db_sid("waxu");
  print "DB SID: $tmp\n";
}

# ASM Operation Related
sub set_sqlplus_env {
  my $sid  = shift;
  my $home = shift;

  $ENV{'ORACLE_HOME'} = $home;
  $ENV{'ORACLE_SID'}  = $sid;
  $SQLPLUS = catfile( rootdir, "$home", "bin", "sqlplus" );
}

# Get HASH of DB Name and its HOME
sub get_db_list {
  my ( $tmp, %dblist );
  open( FH, "<$ORA_TAB" ) or die "Fail to open $ORA_TAB file for $!";
  while ( $tmp = <FH> ) {
    chomp $tmp;
    if ( $tmp =~ m/^[\#|\+]/ ) {
      next;
    }
    elsif ( $tmp =~ m/^\s+$/ ) {
      next;
    }
    elsif ( $tmp =~ m/^$/ ) {
      next;
    }
    else {
      my $dbname = ( split( ':', $tmp ) )[0];
      $dblist{$dbname} = ( split( ':', $tmp ) )[1];
    }
  }

  close FH;

  return %dblist;
}
if ($debug) {
  my %dblist = get_db_list();
  print "DB names: ",    join( ' ', keys(%dblist) ) . "\n";
  print "Their Homes: ", join( ' ', values(%dblist) ) . "\n";
}

sub get_rac_home {
  my $dbname = shift;
  my $tmp;
  open( FH, "<$ORA_TAB" ) or die "Fail to open $ORA_TAB file for $!";
  while ( $tmp = <FH> ) {
    chomp $tmp;
    if ( $tmp =~ m/^[\#|\+]/ ) {
      next;
    }

    if ( $tmp =~ m/$dbname/ ) {
      $tmp = ( split( ':', $tmp ) )[1];
      last;
    }
  }

  close FH;

  return $tmp;
}
if ($debug) {
  my $tmp = get_rac_home("waxu");
  print "RAC HOME for waxu: $tmp\n";
}

our $SQLPLUS;
our $ORACLE_HOME;

# $sid is the +ASM or DB NAME
# Here we assume same user for CRS/RAC
# Or else we may need check every user
sub run_local_sql {
  my $query = shift;
  my $role  = shift;
  my $sid   = shift;    # For DB, it is DB NAME
  my $ret   = shift;

  # If ASM, use CRS_HOME, or else use RAC_HOME
  # For multiple RAC_HOMEs, needs more code here
  if ( $sid =~ m/\+ASM/ ) {
    set_sqlplus_env( $ASM_SID, $CRS_HOME );
  }
  else {
    $ORACLE_HOME = get_rac_home("$sid");

    # Get RAC SID from DB NAME
    $sid = get_db_sid("$sid");
    set_sqlplus_env( $sid, $ORACLE_HOME );
  }

  my $sysstr       = "\/ as $role";
  my $query_header = "set linesize 9000\nset pagesize 9999\n";
  $query_header .= "set newpage none\nset feedback off\nset verify off\n";
  $query_header .= "set echo off\nset heading off\n";

  my $tmpsqlfile = catfile( rootdir, "tmp", "run_sql.sql$$" );
  unlink $tmpsqlfile;
  open( SQL, ">$tmpsqlfile" ) or die "Can not crate tmp file $tmpsqlfile, $!";
  print SQL $query_header;

  if ( substr( $query, -1 ) eq ";" ) {
    print SQL "$query\n";
  }
  else {
    print SQL "$query;\n";
  }

  print SQL "quit;\n";
  close SQL;

  my $user = get_current_user();
  my @out;

  # Assume same user used for CRS/RAC, and no other non-root users
  if ( $user eq "root" ) {
    @out =
      exec_OS_cmd("$SU $CRS_OWNER -c '$SQLPLUS -s \"$sysstr\" \@$tmpsqlfile'");
  }
  else {
    @out = exec_OS_cmd("$SQLPLUS -s \"$sysstr\" \@$tmpsqlfile");
  }

  unlink $tmpsqlfile;

  if ( defined( $out[0] ) ) {
    my $tmp = join( ' ', @out );
    chomp $tmp;
    if ( $tmp =~ m/(ERROR)|(ORA-)|(unkown command beginning)/ ) {
      Logger("Fail to run SQL statement \"$query\": @out\n");
      return;
    }
  }

  @{$ret} = @out;

  return 0;
}
if ($debug) {
  my @sql_ret;
  my $ret =
    run_local_sql( "select value from v\$parameter where name = 'spfile'",
    "sysasm", $ASM_SID, \@sql_ret );

  if ( defined($ret) ) {
    print "ASM Spfile: ", join( '', @sql_ret );
  }
  else {
    print "Error happens to get ASM Spfile\n";
  }

  @sql_net = "";

  $ret = run_local_sql( "select value from v\$parameter where name = 'spfile'",
    "sysdba", "orcldb", \@sql_ret );

  if ( defined($ret) ) {
    print "DB Spfile: ", join( '', @sql_ret );
  }
  else {
    print "Error happens to get the DB Spfile\n";
  }
}

sub get_current_user {
  my @tmp      = exec_OS_cmd("$ID");
  my $cur_user = shift @tmp;
  $cur_user = ( split( / /, $cur_user ) )[0];
  $cur_user =~ /=\d+\W(\S+)\W/;
  $cur_user = $1;
  return $cur_user;
}
if ($debug) {
  my $cur_user = get_current_user();
  print "Current User: $cur_user\n";
}

#
# Get local ASM instance log destination
# Input: None
# Output: %asm_dest
#    audit_file_dest
#    background_dump_dest
#    core_dump_dest
#    user_dump_dest
sub get_ASM_log_dest {
  my ( @out, $ret, %asm_log );
  my $sql = "select value from v\$parameter where name = 'audit_file_dest';
select value from v\$parameter where name = 'background_dump_dest';
select value from v\$parameter where name = 'core_dump_dest';
select value from v\$parameter where name = 'user_dump_dest';";
  $ret = run_local_sql( "$sql", "sysasm", $ASM_SID, \@out );
  if ( defined($ret) ) {
    chomp @out;
    $asm_log{'audit_file'}      = shift @out;
    $asm_log{'background_dump'} = shift @out;
    $asm_log{'core_dump'}       = shift @out;
    $asm_log{'user_dump'}       = shift @out;

    # Get Incident, Sweep and alert directory
    my $log_loc = $asm_log{'user_dump'};
    my @log_loc = split( '/', $log_loc );
    pop @log_loc;
    $log_loc = join( '/', @log_loc );

    $asm_log{'alert_log'} = catfile( $log_loc, "alert" );
    $asm_log{'incident'}  = catfile( $log_loc, "incident" );
    $asm_log{'sweep'}     = catfile( $log_loc, "sweep" );
  }
  else {
    return;
  }

  return \%asm_log;
}
if ($debug) {
  my $tmp = get_ASM_log_dest();
  if ( defined $tmp ) {
    print "ASM Audit: $tmp->{'audit_file'}\n";
    print "ASM Background: $tmp->{'background_dump'}\n";
    print "ASM CoreDump: $tmp->{'core_dump'}\n";
    print "ASM UserDump: $tmp->{'user_dump'}\n";
    print "ASM Alert: $tmp->{'alert_log'}\n";
    print "ASM Incident: $tmp->{'incident'}\n";
    print "ASM Sweep: $tmp->{'sweep'}\n";
  }
}

# Input: DBName to vaoid multiple DB instance
# Output: %db_dest
#    audit_file_dest
#    background_dump_dest
#    core_dump_dest
#    user_dump_dest
sub get_DB_log_dest {
  my ( $dbname, @out, %db_log, $ret );
  $dbname = $_[0];
  my $sql = "select value from v\$parameter where name = 'audit_file_dest';
select value from v\$parameter where name = 'background_dump_dest';
select value from v\$parameter where name = 'core_dump_dest';
select value from v\$parameter where name = 'user_dump_dest';";
  $ret = run_local_sql( "$sql", "sysdba", $dbname, \@out );
  if ( defined($ret) ) {
    chomp @out;
    $db_log{'audit_file'}      = shift @out;
    $db_log{'background_dump'} = shift @out;
    $db_log{'core_dump'}       = shift @out;
    $db_log{'user_dump'}       = shift @out;

    # Get Incident, Sweep and alert directory
    my $log_loc = $db_log{'user_dump'};
    my @log_loc = split( '/', $log_loc );
    pop @log_loc;
    $log_loc = join( '/', @log_loc );

    $db_log{'alert_log'} = catfile( $log_loc, "alert" );
    $db_log{'incident'}  = catfile( $log_loc, "incident" );
    $db_log{'sweep'}     = catfile( $log_loc, "sweep" );
  }
  else {
    return;
  }

  return \%db_log;
}
if ($debug) {
  my $tmp = get_DB_log_dest("orcldb");
  if ( defined $tmp ) {
    print "DB Audit: $tmp->{'audit_file'}\n";
    print "DB Background: $tmp->{'background_dump'}\n";
    print "DB CoreDump: $tmp->{'core_dump'}\n";
    print "DB UserDump: $tmp->{'user_dump'}\n";
    print "DB Alert: $tmp->{'alert_log'}\n";
    print "DB Incident: $tmp->{'incident'}\n";
    print "DB Sweep: $tmp->{'sweep'}\n";
  }
}

# Get Diskgroup Usable Free Size in MB
# Input: DG Name
# Output: Size in MB or Null
sub get_dg_free_size {
  my ( $dgname, $ret, @out, $dgsize );
  $dgname = shift;
  $dgname = uc $dgname;
  my $sql =
    "select USABLE_FILE_MB from v\$asm_diskgroup where name = \'$dgname\'";
  $ret = run_local_sql( "$sql", "sysasm", $ASM_SID, \@out );
  if ( defined $ret ) {
    $dgsize = shift @out;
    chomp $dgsize;
    return $dgsize;
  }
  return;
}
if ($debug) {
  my $tmp = get_dg_free_size("datadg");
  if ( defined $tmp ) {
    print "DG +DATADG Usage Free Size: $tmp MB\n";
  }
}

# ACFS Operation Related

# Check if the file or directory is on ACFS
# TRUE: yes
# FALSE: no
sub is_on_acfs {
  my $dir = shift;

  # If the file or directory does not exist, return FALSE
  unless ( -e $dir ) {
    return FALSE;
  }

  # Right now, ACFS does not support tag on Solaris, AIX and HPI
  # Linux Support Only with 11202
  if ( $PLATFORM ne "linux" ) {
    return FALSE;
  }

  my @out = exec_OS_cmd("$ACFSUTIL info file $dir");

  my $tmp = join( ' ', @out );
  if ( $tmp =~ m/(not an ACFS file system)/i ) {
    return FALSE;
  }
  elsif ( $tmp =~ m/(CLSU-)|(ACFS-)/ ) {    # With error happens
    return FALSE;
  }

  return TRUE;
}
if ($debug) {
  my $tmp = is_on_acfs("/TB/base/acfs_home");
  print "/TB/base/acfs_home is ",
    ( $tmp == TRUE ) ? "on ACFS\n" : "not on ACFS\n";
}

# Input: Diretory or file
# Output: TRUE - If its ASM DG with ADVM 11.2.0.2 or later
#       : FALSE
sub is_tagable {
  my $file = shift;

  my $DGNAME = "DATAXWARREN";    # how to get ASM DG from file location
  $DGNAME = uc $DGNAME;

  my @sql_ret;
  my $sql =
"select a.value from v\$asm_attribute a, v\$asm_diskgroup b where a.name = 'compatible.advm' and b.name=\'$DGNAME\' and a.GROUP_NUMBER = b.GROUP_NUMBER";

  #alter diskgroup DATAXWARREN set attribute 'compatible.advm' = '11.2.0.2';
  my $version = run_local_sql( "$sql", "sysasm", $ASM_SID, \@sql_ret );
  if ( defined $version && @sql_ret ) {
    $version = shift @sql_ret;
    chomp $version;
  }
  else {
    return FALSE;
  }
  if ( defined $version && $version =~ m/11\.2\.0\.2/ ) {
    return TRUE;
  }
  return FALSE;
}

sub get_volume_size {
  return 0;
}

# Operating System Related

# Input: OS command
# Output: @output
sub exec_OS_cmd {
  my $cmd = $_[0];
  my @return;
  open( CMDEXE, "$cmd 2>&1 |" ) or die "Can't open \"$cmd\" for $!";
  @return = <CMDEXE>;
  close(CMDEXE);
  return @return;
}

# Input: No
# Output: Linux/AIX/SunOS/HP-UX
sub get_OS_type {
  my @uname = exec_OS_cmd("/bin/uname");
  my $uname = shift @uname;
  chomp $uname;
  return $uname;
}

# Input: OS_Name, Directory
# Output: ($percentage $free $total)
sub get_partition_size {
  my $OS  = $_[0];
  my $Dir = $_[1];
  unless ( -d $Dir ) {
    Logger("Directory $Dir does not exist!\n");
    return;
  }

  my @out = exec_OS_cmd("$DF $Dir");

  #Example:
  #Filesystem           1K-blocks      Used Available Use% Mounted on
  #/dev/sda1            275227004  36977844 224042884  15% /

  shift @out;    # Remove the first line

  # In some case, it may have long directory which the output will be like:
  #Filesystem           1K-blocks      Used Available Use% Mounted on
  #/dev/asm/dgrachome-203
  #                    10485760   4666272   5819488  45% /TB/base/acfs_home

  # Also, on AIX, the column is a little bit different which has 7 columns
  #Filesystem    1024-blocks      Free %Used    Iused %Iused Mounted on
  #/dev/eelv        62914560  41201088   35%    20692     1% /ee

  my $size = join( ' ', @out );    # We may make the output in the same line
  chomp $size;
  if ( $PLATFORM eq "aix" ) {
    $out = join( ' ', ( split /\s+/, $size )[ 3, 2 ] );    # 15% Free_space
  }
  else {
    $out = join( ' ', ( split /\s+/, $size )[ 4, 3 ] );    # 15% Free_space
  }
  return $out;
}


if ($debug) {
  my $tmp = get_partition_size( "Linux", "/tmp" );
  print "Size: \"/tmp\" $tmp\n";
}

# Process List
sub get_process_priority {
  my $pname = shift;
  my @out   = exec_OS_cmd("$PS");
  return 0;
}






#
sub check_user
{
  my ($user) = @_ ;
  "$ME" eq "$user" or die "ERROR: Please run this tool as <$user> user !\n" ;
}




#
sub unique
{
  my @non_unique_array = @{$_[0]};
  my %seen;
  my @uniq = grep { ! $seen{$_}++ } @non_unique_array;
  return \@uniq ;
}



# set A or B
sub SetUnion
{
  my @a = @{unique($_[0])} ;
  my @b = @{unique($_[1])} ;
   
  my %union;
  my %intersect;
 
  foreach my $e (@a, @b) {  
    $union{$e}++ && $intersect{$e}++ ;  
  }  
  my @union = keys %union ;  
  my @intersect = keys %intersect ;
  my @diff = grep { $union{$_}==1; } @a ;
  my @xor  = grep { $union{$_}==1; } @union;
  return \@union ;
}



# set A and B
sub SetIntersect
{
  my @a = @{unique($_[0])} ;
  my @b = @{unique($_[1])} ;
   
  my %union ;
  my %intersect ;
 
  foreach my $e (@a, @b) {  
    $union{$e}++ && $intersect{$e}++ ;  
  }  
  my @union = keys %union ;  
  my @intersect = keys %intersect ;
  my @diff = grep { $union{$_}==1; } @a ;
  my @xor  = grep { $union{$_}==1; } @union;
  return \@intersect ;
}



# set A - B
sub SetDiff
{
  my @a = @{unique($_[0])} ;
  my @b = @{unique($_[1])} ;
   
  my %union ;
  my %intersect ;
 
  foreach my $e (@a, @b) {  
    $union{$e}++ && $intersect{$e}++ ;  
  }  
  my @union = keys %union ;  
  my @intersect = keys %intersect ;
  my @diff = grep { $union{$_}==1; } @a ;
  my @xor  = grep { $union{$_}==1; } @union;
  return \@diff ;
}



# set A xor B
sub SetXor
{
  my @a = @{unique($_[0])} ;
  my @b = @{unique($_[1])} ;
   
  my %union ;
  my %intersect ;
 
  foreach my $e (@a, @b) {  
    $union{$e}++ && $intersect{$e}++ ;  
  }  
  my @union = keys %union ;  
  my @intersect = keys %intersect ;
  my @diff = grep { $union{$_} == 1; } @a ;
  my @xor  = grep { $union{$_} == 1; } @union;
  return \@xor ; 
}




#==============================================================================
# NAME:
#   get_current_time - Get the current time, with format "yyyy-mm-dd hh24:mm:ss"
#
# PARAMETERS:
#   None
#
# RETURNS:
#   $timenow - Current time in "yyyy-mm-dd hh24:mm:ss: format
#==============================================================================
sub get_current_time
{
  my ($sec, $min, $hr, $day, $mon, $yr) = localtime(time);
  my $timenow;
  ++$mon; #month begins at '0' ...

  if (length ($mon) == 1) { $mon = '0' . $mon; }
  if (length ($day) == 1) { $day = '0' . $day; }
  if (length ($hr)  == 1) { $hr  = '0' . $hr;  }
  if (length ($min) == 1) { $min = '0' . $min; }
  if (length ($sec) == 1) { $sec = '0' . $sec; }

  $yr += 1900 ;

  $timenow = "$yr-$mon-$day $hr:$min:$sec" ;

  return $timenow ;
}



# Warp print with timestamp
sub Logger {
  my $out_dir = get_output_dir();
  my $logdir = File::Spec->catdir($out_dir, "logs") ;

  (mkdir("$logdir",0777) or die("ERROR: unable to create $logdir in $out_dir\n")) unless ( -d $logdir ) ;
  my $output_log = File::Spec->catfile($logdir, "$RESOURCE_NAME.log") ;

  open(FH, ">>$output_log") or die("ERROR: cannot open file $output_log for writing due to $OS_ERROR !\n") ;

  my $time = get_current_time() ;
  print FH "[$time] @_" ;
  close FH ;
}



# match only core files for find command, from diag collect script
sub coreonly {
  my ( $dev, $ino, $mode, $nlink, $uid, $gid );
  -f $_
    && /^core.*\z/s
    && ( ( $dev, $ino, $mode, $nlink, $uid, $gid ) = lstat($_) )
    && push @corelist, $File::Find::name;
}




sub coreanalyze {

  # map a core-file directory pattern to the daemon binary name
  my %core_dir_map = (
    'crsd',                            'crsd',
    'evmd',                            'evmd',
    'cssd',                            'ocssd',
    'ctssd',                           'octssd',
    'diskmon',                         'diskmon',
    'gipcd',                           'gipcd',
    'gnsd',                            'gnsd',
    'gpnpd',                           'gpnpd',
    'mdnsd',                           'mdnsd',
    'ohasd',                           'ohasd',
    'agent/ohasd/oraagent_*',          'oraagent',
    'agent/ohasd/orarootagent_*',      'orarootagent',
    'agent/ohasd/oracssdagent_root',   'cssdagent',
    'agent/ohasd/oracssdmonitor_root', 'cssdmonitor',
    'agent/crsd/oraagent_*',           'oraagent',
    'agent/crsd/orarootagent_*',       'orarootagent',
    'crflogd',                         'ologgerd',
    'crfmond',                         'osysmond',
  );

  # find each corefile, try to determine which binary it's from
  our @corelist;
  our $coreexists = FALSE;

  my $currtime     = get_current_time();
  my $COREDATA_TAR = "coreData_" . "$HOST" . '_' . $currtime . '.' . "tar";
  my $CF           = "-cf";
  my $RF           = "-rf";
  my @outfiles     = ();
  my ( $outfile, $DBX, $DEBUGGER, $DEBUGCMD );

  File::Find::find( { wanted => \&coreonly }, "${CRS_HOME}/log/${HOST}" );

  foreach my $corefile (@corelist) {
    $coreexists = TRUE;
    my $execname = "";
    foreach my $coredir ( sort keys(%core_dir_map) ) {

      # check if core file name matches coredir pattern
      if ( $corefile =~ /$coredir/ ) {
        $execname = catfile( "$CRS_HOME", "bin/", "$core_dir_map{$coredir}" );
        if ( -e "$execname" . ".bin" ) {
          $execname = "$execname" . ".bin";
        }

        # calculate output filename for debugger command
        my ( $ignvolume, $igndir, $corebase ) =
          File::Spec->splitpath($corefile);
        $outfile = $corebase . "." . $core_dir_map{$coredir} . "." . "txt";
      }
    }

    if ( $execname eq "" ) {
      Logger("unknown binary for corefile $corefile\n");
    }
    else {
      my $info_cmd = "gdb_info_cmd";

      # select a Sun dbx to use
      if ( $PLATFORM eq "solaris" ) {

        # use Sun Studio 12 if available, otherwise 11, or earlier
        if ( -e "/opt/SunProd/studio12/SUNWspro/bin/dbx" ) {
          $DBX = "/opt/SunProd/studio12/SUNWspro/bin/dbx";
        }
        elsif ( -e "/opt/SunProd/studio11/SUNWspro/bin/dbx" ) {
          $DBX = "/opt/SunProd/studio11/SUNWspro/bin/dbx";
        }
        else {

          # Following changes are done for bug 7494746.
          my $OS_VERSION = `/bin/uname -r`;
          my $OS_MINOR_RELEASE_VERSION = substr $OS_VERSION, 2;
          chop($OS_MINOR_RELEASE_VERSION);
          $DBX =
            "/opt/SunProd/SUNWspro" . ($OS_MINOR_RELEASE_VERSION) . "/bin/dbx";
        }
      }

      if ( -e "/usr/bin/gdb" ) {

        # Get the backtrace of all threads
        open OUTFILE, ">> $info_cmd";
        print OUTFILE "set pagination off\n";
        print OUTFILE "where\n";
        print OUTFILE "display\n";
        print OUTFILE "thread apply all bt\n";
        print OUTFILE "quit\n";

        $DEBUGGER = "/usr/bin/gdb";
        $DEBUGCMD =
"${DEBUGGER} --nx --batch --comm=${info_cmd} --e=${execname} --core=${corefile} > ${outfile}";
      }
      elsif ( ( -e "/opt/SUNWspro/bin/dbx" ) || ( -e "$DBX" ) ) {
        open OUTFILE, ">> $info_cmd";
        print OUTFILE "where\n";
        print OUTFILE "thread -info\n";
        print OUTFILE "threads\n";
        print OUTFILE "dump\n";
        print OUTFILE "quit\n";

        if ( -e "/opt/SUNWspro/bin/dbx" ) {
          $DEBUGGER = "/opt/SUNWspro/bin/dbx";
        }
        else {
          $DEBUGGER = "$DBX";
        }

        $DEBUGCMD =
"${DEBUGGER} -c \"source ${info_cmd}\" ${execname} ${corefile} > ${outfile}";
      }
      elsif ( -e "/bin/dbx" ) {
        open OUTFILE, ">> $info_cmd";
        print OUTFILE "where\n";
        print OUTFILE "enable all\n";
        print OUTFILE "corefile\n";
        print OUTFILE "thread info -\n";
        print OUTFILE "dump\n";
        print OUTFILE "list\n";
        print OUTFILE "quit\n";

        $DEBUGGER = "/bin/dbx";
        $DEBUGCMD =
"${DEBUGGER} -c ${info_cmd} ${execname} ${corefile} > ${outfile} 2>&1";
      }
      else {
        Logger("Debugger could not be located on this system\n");
        return;
      }

      exec_OS_cmd("${DEBUGCMD}");
      unlink $info_cmd;

      # save on list of core output text files
      push @outfiles, $outfile;
    }

    # May need delete core file here
    Logger("Core File \"$corefile\" will be deleted to save space\n");
    unlink $corefile;
  }

  if ($coreexists) {
    exec_OS_cmd(
      "${TAR} ${CF} ${COREDATA_TAR} @outfiles; ${GZIP} ${COREDATA_TAR}");
    exec_OS_cmd("$MV ${COREDATA_TAR}.gz $CRS_HOME/log/");
    unlink @outfiles;
    Logger(
      "Core Analyze Tarball \"${COREDATA_TAR}.gz\" at \"$CRS_HOME/log\"\n");
    return TRUE;
  }
  else {

    #print "No corefiles found \n";
    return FALSE;
  }
}
if ($debug) {
  coreanalyze();
}

# Mail sent to Sysadm to give warnnings
sub send_mail {
  my $email_id = shift;
  my $subject  = shift;
  my $file     = shift;
  my $time     = get_current_time();
  unless ( -f $file ) {
    Logger("Email sent fails since no $file found!\n");
    return FALSE;
  }
  else {
    exec_OS_cmd("$MAIL -s \"$time $subject\" < $file $email_id");
  }

  return;
}

#  Function: open_files
#  Description: Set True if the file is in use
#  Input: dir_path
#
sub open_files {

  my $dir = shift;

  # Need to be direcotry since "lsof +D" is used here
  unless ( -d $dir ) { return; }

  # If lsof is installed
  if ( -f $LSOF ) {
    my @file_list = exec_OS_cmd("$LSOF +D $dir");

    #  shift @file_list;

    foreach my $file (@file_list) {
      chomp $file;
      if ( $file =~ m/WARNING:/ ) {
        next;
      }
      if ( $file =~ m/^COMMAND\s+PID/ ) {
        next;
      }

      my @tmp = split /\s+/, $file;

      # Skip directory
      if ( -d $file ) {
        return;
      }

      # Skip Non log/trace file
      if ( $file !~ m/$LOGSUFFIX/ ) {
        return;
      }

      $OPENFILES{ $tmp[8] } = TRUE;
    }
  }
}

#  Function: is_opened
#  Description: Verify whether the file is opened
#  Input: file
#  Return: FALSE - close
#          TRUE - open
sub is_opened {
  my $file = shift;

  unless ( -f $file ) { return FALSE; }

  # In case no lsof is installed on the node, use fuser instead
  # It may affect performance
  unless ( -f $LSOF ) {
    my @tmp = exec_OS_cmd("$FUSER $file");
    if ( scalar(@tmp) < 1 ) {
      return FALSE;
    }
    else {
      chomp @tmp;
      my $tmp = join( '', @tmp );
      if ( $tmp =~ m/$file:\s+\d+/ ) {
        return TRUE;
      }
      else {
        return FALSE;
      }
    }
  }

  if ( defined( $OPENFILES{$file} ) ) {
    return TRUE;
  }
  else {
    return FALSE;
  }
}

#  Function: get_age_acfs
#  Description: Get the file age in ACFS, if the file is open the age is 0.
#  Input: dir_path, current_time
#  Return: file_age
#
sub get_age_acfs {
  my $file = shift;
  unless ( -e $file ) { return FALSE; }

  my $t_time   = time;
  my @fileinfo = exec_OS_cmd("$ACFSUTIL info file $file");
  if ( join( '', @fileinfo ) =~ m/ACFS-/ ) {
    return FALSE;    # File does not exsit or fail to get TAG info
  }
  chomp @fileinfo;

  $fileinfo[10] =~ s/access time: \s+/$`/;
  my $atime = str2time( $fileinfo[10] );
  $fileinfo[11] =~ s/modify time: \s+/$`/;
  my $mtime = str2time( $fileinfo[11] );
  $fileinfo[12] =~ s/change time: \s+/$`/;
  my $ctime = str2time( $fileinfo[12] );
  my $age   = $t_time - $atime;
  $age = $t_time - $mtime if ( $t_time - $mtime < $age );
  $age = $t_time - $ctime if ( $t_time - $ctime < $age );
  return $age;
}

# Set the array whose file has been taaged
sub get_tag_files {
  my $dir = shift;
  my @tmp = get_delfile_acfs($dir);
  foreach my $tmp (@tmp) {
    $TAGFILES{$tmp} = TRUE;
  }
}

# Check if the file is tagged or not
sub is_taged {
  my $file = shift;
  unless ( -f $file ) { return FALSE; }
  if ( defined( $TAGFILES{$file} ) ) {
    return TRUE;
  }
  else {
    return FALSE;
  }
}

#  Function: get_delfile_acfs
#  Description: get deleted files in ACFS
#  Input: dir_path, tag_name
#  Return: FAILED - if (the dir_path is not a dir) or (dir_path is rootdir)
#          SUCCESS - succeed
sub get_delfile_acfs {
  my $dir = shift;
  unless ( -e $dir ) { return; }
  my @tmp = exec_OS_cmd("$ACFSUTIL tag info -r $dir -t $TAGNAME");
  return @tmp;
}

# Set global varaiables and start set tag
sub wrap_set_tag_acfs {
  my $dir = shift;
  my $age = $AGE;

  %OPENFILES = ();
  %TAGFILEs  = ();

  if ($FORCE_DELETION_ACFS) {
    $AGE       = 0;    # Force delete files
    %OPENFILES = ();
    %TAGFILES  = ();
  }
  else {
    open_files($dir);
    get_tag_files($dir);
  }

  $TAG_SUPPORT = FALSE;
  set_tag_acfs($dir);

  $AGE = $age;
}

#  Function: set_tag_acfs
#  Description: Set tag for the old files as the filter in ACFS
#  Input: dir_path, age, suffix, tag_name
#  Return: FAILED - if (the dir_path is not a dir) or (dir_path is rootdir)
#          SUCCESS - succeed
sub set_tag_acfs {

  my $dir = shift;

  Logger("Check Tag with Directory: $dir\n");
  opendir( DIR, $dir );

  my @files = readdir(DIR);
  closedir(DIR);

  shift @files;
  shift @files;

  foreach my $file (@files) {
    if ( $file =~ m/^\.\S*/ ) { next; }    # Excluding hidden files
    $file = catfile( $dir, $file );
    if ( -d $file ) {
      set_tag_acfs($file);
    }
    else {
      if ( $file =~ m/$LOGSUFFIX/ ) {
        my $age   = get_age_acfs($file);
        my $open  = is_opened($file);
        my $taged = is_taged($file);

        #print "$age for $file\n";
        if ( $age > $AGE && !$open ) {
          if ($taged) {
            if ($FORCE_DELETION_ACFS) {
              unlink $file;
            }
            else {
              next;
            }
          }
          Logger("Set Tag for file: $file\n");
          if ($TAG_SUPPORT) {
            if ($FORCE_DELETION_ACFS) {
              Logger("Force option is set. Remove $file\n");
              unlink $file;    # Remove file directly if FORCE set
            }
            else {
              exec_OS_cmd("$ACFSUTIL tag set $TAGNAME $file");
            }
          }
          if ( exec_OS_cmd("$ACFSUTIL tag set $TAGNAME $file") =~ m/ACFS-/ ) {
            return;            # Do not support Tag
          }
          else {
            $TAG_SUPPORT = TRUE;
          }
        }
        elsif ( $age < $AGE || $open ) {
          unless ($taged) { next; }

          #print "Unset Tag for file: $file\n";
          if ($FORCE_DELETION_ACFS) {
            unlink $file;  # Remove the file if it is tagged before if FORCE set
          }
          else {
            exec_OS_cmd("$ACFSUTIL tag unset $TAGNAME $file");
          }
        }
      }
    }
  }
}

sub get_policy_setting {

  # Get the Policy Setting from Resrouce Profile
  $EMAIL_ADDRESS = get_attribute_value_of_resource( "$RESOURCE_NAME", "EMAIL" );
  if ($debug) {
    print "Email Address: $EMAIL_ADDRESS\n";
  }

  $PERCENT_OS = get_attribute_value_of_resource( "$RESOURCE_NAME", "OS_SYS_PERCENT" );
  if ($debug) {
    print "SYS Percent: $PERCENT_OS\n";
  }

  $SPACE_OS = get_attribute_value_of_resource( "$RESOURCE_NAME", "OS_SYS_SPACE" );
  $SPACE_OS = $SPACE_OS * 1024;    # M to kilo
  if ($debug) {
    print "SYS Space: $SPACE_OS\n";
  }

  $FORCE_PERCENT_OS = get_attribute_value_of_resource( "$RESOURCE_NAME", "OS_PERCENT_FORCE" );
  if ($debug) {
    print "SYS Percent Force: $FORCE_PERCENT_OS\n";
  }

  $PERCENT_ACFS = get_attribute_value_of_resource( "$RESOURCE_NAME", "ACFS_SYS_PERCENT" );
  if ($debug) {
    print "ACFS Percent: $PERCENT_ACFS\n";
  }

  $SPACE_ACFS = get_attribute_value_of_resource( "$RESOURCE_NAME", "ACFS_SYS_SPACE" );
  $SPACE_ACFS = $SPACE_ACFS * 1024;    # M to kilo
  if ($debug) {
    print "ACFS Space: $SPACE_ACFS\n";
  }

  $FORCE_PERCENT_ACFS = get_attribute_value_of_resource( "$RESOURCE_NAME", "ACFS_PERCENT_FORCE" );
  if ($debug) {
    print "ACFS Percent FORCE: $FORCE_PERCENT_ACFS\n";
  }

  $AGE = get_attribute_value_of_resource( "$RESOURCE_NAME", "FILE_AGE" );
  $AGE = $AGE * 60;    # Mintues to seconds
  if ($debug) {
    print "Age: $AGE\n";
  }

  $SIZE = get_attribute_value_of_resource( "$RESOURCE_NAME", "FILE_SIZE" );
  $SIZE = $SIZE * 1024;    # K to Byte
  if ($debug) {
    print "Size: $SIZE\n";
  }

  $CHECK_INTERVAL = get_attribute_value_of_resource( "$RESOURCE_NAME", "CHECK_INTERVAL" );
  if ($debug) {
    print "Check interval: $CHECK_INTERVAL\n";
  }

  my $check_interval = get_attribute_value_of_resource( "$RESOURCE_NAME", "CHECK_INTERVAL" );
  if ( $check_interval != $CHECK_INTERVAL * 60 ) {

    # Monitor interval has been updated, need update check_interval also
    $check_interval = $CHECK_INTERVAL * 60;
    my @tmp =
      exec_OS_cmd(
      "$CRSCTL modify res $RESOURCE_NAME -attr \"CHECK_INTERVAL=$check_interval\"");
  }
}

# Create PID file with its PID number
# Modified this function for pid of background $SCRIPT_RESMONITOR
sub set_pid_record {
  my $pwd   = getcwd();
  my $out_dir = get_output_dir();  #Rajeev
  my $pname = $0;
  $pname = ( split( '/', $pname ) )[-1];
  Logger("Add PID $$\n");
  $PIDFILE = catfile( $out_dir, "pids", ${pname} );
  $PIDFILE = $PIDFILE . ".pid";

  if ( defined( $_[0] ) && ( $_[0] eq "start" ) && -f $PIDFILE ) {
    unlink $PIDFILE;
  }

  if ( -f $PIDFILE ) {
    open( FH, "<$PIDFILE" ) or die "Fail to open PID file for $pname, $!";
    my @tmp = <FH>;
    chomp @tmp;
    close FH;
    while ( scalar(@tmp) > 0 ) {
      sleep 1;
      open( FH, "<$PIDFILE" ) or die "Fail to open PID file for $pname, $!";
      @tmp = <FH>;
      close FH;
      chomp @tmp;
      foreach my $pid (@tmp) {
        unless ( kill 0, $pid ) {    # Check if the pid is alive or not
          remove_pid_record($pid);
          next;
        }

        # If PID is alive, check process name
        my @ps = exec_OS_cmd("$PSP $pid");
        shift @ps;                   # Discard the first line
        $line = shift @ps;
        if ( $line =~ m/$pname/ ) {    # Process is still running
          next;
        }
        else {                         # PID should be reused by another process
          remove_pid_record($pid);
        }
      }
    }
  }

  open( FH, ">>$PIDFILE" ) or die "Fail to creat PID file for $pname, $!";
  print FH "$$\n";
  close FH;

  if ( -f "${PIDFILE}.bak" ) { unlink "${PIDFILE}.bak"; }
}
if ($debug) {
  set_pid_record();
  remove_pid_record();
}

# Return the PID file
sub get_pid_numbers {
  my $pwd   = getcwd();
  my $out_dir = get_output_dir(); #Rajeev
  my $pname = $0;
  my @pids;

  $pname = ( split( '/', $pname ) )[-1];
  $PIDFILE = catfile( $out_dir, "pids", ${pname} );
  $PIDFILE = $PIDFILE . ".pid";
  if ( -f $PIDFILE ) {
    open( FH, "<$PIDFILE" ) or die "Fail to open PID file $PIDFILE, $!";
    @pids = <FH>;
    close FH;
  }
  return @pids if (@pids);
  return;
}

# Remove the PID file
sub remove_pid_record {
  my ( $pidfile, $pid );
  if ( defined $_[0] ) {
    $pid = shift;
  }
  else {
    $pid = $$;
  }

  chomp $pid;

  if ( defined $PIDFILE ) {
    $pidfile = $PIDFILE;
  }
  else {
    my $pwd   = getcwd();
    my $out_dir = get_output_dir();  #Rajeev

    my $pname = $0;
    $pname = ( split( '/', $pname ) )[-1];
    $pidfile = catfile( $out_dir, "pids", ${pname} );
    $pidfile = $pidfile . ".pid";
  }

  my $pidbak = "${pidfile}.bak";

  if ( -f $pidfile && -f $pidbak ) { sleep 5; remove_pid_record(); }

  if ( -f $pidfile ) {
    open( FH1, "$pidfile" ) or die "Fail to open PID file $pidfile, $!";
    open( FH2, ">$pidbak" ) or die "Fail to open PID file $pidbak, $!";
    while (<FH1>) {
      if ( $_ =~ m/$pid/ ) {
        next;
      }
      else {
        print FH2 $_;
      }
    }
    close FH1;
    close FH2;
    unlink $pidfile;
    rename $pidbak, $pidfile;
  }
  Logger("Successful remove $pid\n");
}



#function killall_pids
#kill all pids that in pid files under $CRS_HOME/install/utl/pids directory
sub killall_pids {
  my $piddir = catfile( get_output_dir(), "pids" );
  if ( -d $piddir ) {
    my @pidfiles = glob("$piddir/*.pid");
    foreach my $pf (@pidfiles) {
      chomp $pf;
      unless ( -f $pf ) { next; }

      open( FH, "<$pf" ) or next;
      my @pids = <FH>;
      close FH;

      foreach my $pid (@pids) {
        chomp $pid;
        kill 9, $pid;
      }
      if ( -f $pf ) { unlink $pf; }
    }
  }
  else {
    die "killall_pids() can't find pids directory $piddir\n";
  }
}

#  Function: filter
#  Description: create the find filter in normal FS
#  Input: file_name, suffix
#
sub filter {

  # We may need to ignore files/directories starting with '.'
  if ( -f && m/$LOGSUFFIX/ ) {
    my $file = $File::Find::name;

    # Force deletion if FORCE bit set
    if ($FORCE_DELETION_OS) {
      Logger("$file will be deleted to save space!\n");
      unlink $file;
      return;
    }

    my (
      $dev,  $ino,  $mode,  $nlink, $uid, $gid,
      $rdev, $size, $atime, $mtime, $ctime
      )
      = lstat $file;

    #print "$file: atime: $atime mtime: $mtime ctme: $ctime \n";
    my $cur_time = time;
    my $age      = $cur_time - $atime;
    $age = $cur_time - $mtime if ( $cur_time - $mtime < $age );

    # Comment this line to avoid the file/directory with sticky bit set
    #$age = $cur_time - $ctime if ($cur_time - $ctime < $age);
    # Warren Debug
    #print "age:$age AGE: $AGE $file\n";
    if ( $age > $AGE && !is_opened($file) ) {
      Logger("$file will be deleted to save space!\n");
      unlink $file;

      #push (@del_file, $file);
    }
  }
}

# Do the file clean action
# Input: File directory, age
sub do_file_deletion {

  # Get Directory
  my $del_dir = shift;

  # This should not happen
  if ( $del_dir eq rootdir() ) {
    die "Root Partition \"$del_dir\" can not be deleted!\n";
  }

  unless ( -d $del_dir ) {
    Logger("$del_dir is not directlry\n");
    return 1;
  }

  # Empty arry
  @del_file = ();

  # Clear the %OPENFILES
  %OPENFILES = ();

  if ( is_on_acfs($del_dir) ) {

    #find (\&filter, $del_dir);
    @del_file = get_delfile_acfs($del_dir);
  }
  else {

    # Find the file and delete it directly
    find( \&filter, $del_dir );
  }

  # Delete these files in @del_file;
  foreach my $file (@del_file) {
    chomp $file;
    Logger("Log File \"$file\" will be deleted to save space\n");
    unlink $file;
  }
}

# Start to scan the log direcotry and set tag if needs
sub start_set_tag {

  # Check The Disk Usage for RAC_HOME/ASM Log Directories
  my %dblist = get_db_list();

  my @log_dir_list;
  my @dbs = keys %dblist;
  my $log_dest;

  # Push DB log destinations
  foreach my $db (@dbs) {
    $log_dest = get_DB_log_dest($db);
    push @log_dir_list, values %{$log_dest};
  }

  # Push ASM Log destination
  $log_dest = get_ASM_log_dest();
  push @log_dir_list, values %{$log_dest};

  # Check if on ACFS
  # Check each log partition
  my %record;    # To avoid duplicated dirs
  foreach $log_dest (@log_dir_list) {
    unless ( -d $log_dest ) { next; }

    if ( $record{$log_dest} ) {
      next;      # Already checked
    }
    else {
      $record{$log_dest} = TRUE;
    }

    if ( is_on_acfs($log_dest) ) {
      wrap_set_tag_acfs($log_dest);
    }
  }
}

# Check the space and delete the fils
our @del_file;

sub check_space {

  # Get parameters from resource profile
  get_policy_setting();

  # Check The Disk Usage for RAC_HOME/ASM Log Directories
  my %dblist = get_db_list();

  my @log_dir_list;
  my @dbs = keys %dblist;
  my $log_dest;

  # Push DB log destinations
  foreach my $db (@dbs) {
    $log_dest = get_DB_log_dest($db);
    push @log_dir_list, values %{$log_dest};
  }

  # Push ASM Log destination
  $log_dest = get_ASM_log_dest();
  push @log_dir_list, values %{$log_dest};

  unlink $EMAIL_TXT;
  $EMAIL_FLAG = FALSE;

  open( FH, ">$EMAIL_TXT" ) or die "Fail to create $EMAIL_TXT for $!";
  print FH "Hi SysAdmin,\n\n";
  print FH
"  This Email is generated by system of node $HOST to remind you that the free space of some partitions on the node $HOST is not enough!\n\n";
  print FH "*" x 80 . "\n";

  # Check each log partition
  my @log_backup;
  my %record;    # To avoid duplicated dirs
  foreach $log_dest (@log_dir_list) {
    unless ( -d $log_dest ) { next; }

    if ( $record{$log_dest} ) {
      next;      # Already checked
    }
    else {
      $record{$log_dest} = TRUE;
      push @log_backup, $log_dest;
    }

    if ($debug) {
      print "Log Destination: $log_dest\n";
    }

    my $space = get_partition_size( $PLATFORM, $log_dest );
    unless ( defined $space ) { next; }

    my $percent = ( split( ' ', $space ) )[0];
    $percent =~ s/\%//;
    $percent = 100 - $percent;
    $space   = ( split( ' ', $space ) )[1];

    if ( is_on_acfs($log_dest) ) {
      $FORCE_DELETION_ACFS = FALSE;
      if ( $space < $SPACE_ACFS || $percent < $PERCENT_ACFS ) {
        $EMAIL_FLAG = TRUE;
        print FH
          "\nFree Space for \"$log_dest\" does not meet the requirement!\n";
        print FH "Log files will be deleted to save Space.\n";
        if ( $percent < $FORCE_PERCENT_ACFS ) { $FORCE_DELETION_ACFS = TRUE; }
        do_file_deletion($log_dest);
      }
    }
    else {    # Not on ACFS
      $FORCE_DELETION_OS = FALSE;
      if ( $space < $SPACE_OS || $percent < $PERCENT_OS ) {
        $EMAIL_FLAG = TRUE;
        print FH
          "\nFree Space for \"$log_dest\" does not meet the requirement!\n";
        print FH "Log files will be deleted to save Space.\n";
        if ( $percent < $FORCE_PERCENT_OS ) { $FORCE_DELETION_OS = TRUE; }
        do_file_deletion($log_dest);
      }
      else {

      }
    }

    # Debug Warren
    if ( is_on_acfs($log_dest) ) {
      wrap_set_tag_acfs($log_dest);
    }
  }

  # Check Disk Usage for CRS_HOME log directory
  # Core File Scan first
  my $free = get_partition_size( $PLATFORM, "$CRS_HOME/log" );
  unless ( defined $free ) { return; }

  # May have problem if for shared CRS HOME
  push @log_backup, "$CRS_HOME/log";

  my @out = split( ' ', $free );
  if ($debug) {
    print "\"$CRS_HOME has free size: $out[1]\n";
  }

  my $percent = $out[0];
  chomp $percent;
  $percent =~ s/\%//;
  $percent = 100 - $percent;

  if ( $out[1] < $SPACE_OS || $percent < $PERCENT_OS ) {
    coreanalyze();
  }

  # CRS Log Clean
  $free = get_partition_size( $PLATFORM, "$CRS_HOME/log" );
  unless ( defined $free ) { return; }

  @out = split( ' ', $free );
  $percent = $out[0];
  chomp $percent;
  $percent =~ s/\%//;
  $percent = 100 - $percent;

  if ( $out[1] < $SPACE_OS || $percent < $PERCENT_OS ) {
    $FORCE_DELETION_OS = FALSE;
    $EMAIL_FLAG        = TRUE;
    print FH "Space for \"$log_dest\" does not meet the requirement\n";
    print FH "Log files will be deleted to save Space\n\n";
    if ( $percent < $FORCE_PERCENT_OS ) { $FORCE_DELETION_OS = TRUE; }
    do_file_deletion("$CRS_HOME/log");
  }

  # Check Space again and report the Email Alert
  foreach my $log (@log_backup) {
    $free = get_partition_size( $PLATFORM, $log );
    unless ( defined $free ) { next; }
    @out = split( ' ', $free );
    $percent = $out[0];
    chomp $percent;
    $percent =~ s/\%//;
    $percent = 100 - $percent;

    if ( is_on_acfs($log) ) {
      if ( $out[1] < $SPACE_ACFS || $percent < $PERCENT_ACFS ) {
        print FH
          "** Space for \"$log\" is still not enough after deletion **\n";
      }
    }
    else {
      if ( $out[1] < $SPACE_OS || $percent < $PERCENT_OS ) {
        print FH
          "** Space for \"$log\" is still not enough after deletion **\n";
      }
    }
  }

  print FH "*" x 80 . "\n";
  print FH "Please check the space on node $HOST!\n";
  close FH;

  # Report Email if set
  if ( $EMAIL_FLAG && defined($EMAIL_ADDRESS) ) {
    send_mail($EMAIL_ADDRESS, "*** Please Check Free Space on Node $HOST ***", $EMAIL_TXT);
  }

  $EMAIL_FLAG = FALSE;
  unlink $EMAIL_TXT;
}

sub dietrap_mon {

  # Remove the this PID from the PIDFILE
  #print "Enter SIGNAL Catch Handler\n";
  remove_pid_record();

  die @_;
}

# Time string conversion from HTTP:Date.pm
sub str2time {
  my $str = shift;
  return undef unless defined $str;

  # fast exit for strictly conforming string
  if ( $str =~
/^[SMTWF][a-z][a-z], (\d\d) ([JFMAJSOND][a-z][a-z]) (\d\d\d\d) (\d\d):(\d\d):(\d\d) GMT$/
    )
  {
    return eval {
      my $t = Time::Local::timegm( $6, $5, $4, $1, $MoY{$2} - 1, $3 );
      $t < 0 ? undef: $t;
    };
  }

  my @d = parse_date($str);
  return undef unless @d;
  $d[1]--;    # month

  my $tz = pop(@d);
  unless ( defined $tz ) {
    unless ( defined( $tz = shift ) ) {
      return eval {
        my $frac = $d[-1];
        $frac -= ( $d[-1] = int($frac) );
        my $t = Time::Local::timelocal( reverse @d ) + $frac;
        $t < 0 ? undef: $t;
      };
    }
  }

  my $offset = 0;
  if ( $GMT_ZONE{ uc $tz } ) {

    # offset already zero
  }
  elsif ( $tz =~ /^([-+])?(\d\d?):?(\d\d)?$/ ) {
    $offset = 3600 * $2;
    $offset += 60 * $3 if $3;
    $offset *= -1 if $1 && $1 eq '-';
  }
  else {
    eval { require Time::Zone } || return undef;
    $offset = Time::Zone::tz_offset($tz);
    return undef unless defined $offset;
  }

  return eval {
    my $frac = $d[-1];
    $frac -= ( $d[-1] = int($frac) );
    my $t = Time::Local::timegm( reverse @d ) + $frac;
    $t < 0 ? undef: $t - $offset;
  };
}

sub parse_date ($) {
  local ($_) = shift;
  return unless defined;

  # More lax parsing below
  s/^\s+//;                                            # kill leading space
  s/^(?:Sun|Mon|Tue|Wed|Thu|Fri|Sat)[a-z]*,?\s*//i;    # Useless weekday

  my ( $day, $mon, $yr, $hr, $min, $sec, $tz, $ampm );

  # Then we are able to check for most of the formats with this regexp
  (
    ( $day, $mon, $yr, $hr, $min, $sec, $tz ) = /^
         (\d\d?)               # day
            (?:\s+|[-\/])
         (\w+)                 # month
            (?:\s+|[-\/])
         (\d+)                 # year
         (?:
               (?:\s+|:)       # separator before clock
            (\d\d?):(\d\d)     # hour:min
            (?::(\d\d))?       # optional seconds
         )?                    # optional clock
            \s*
         ([-+]?\d{2,4}|(?![APap][Mm]\b)[A-Za-z]+)? # timezone
            \s*
         (?:\(\w+\))?          # ASCII representation of timezone in parens.
            \s*$
        /x
    )

    ||

    # Try the ctime and asctime format
    (
    ( $mon, $day, $hr, $min, $sec, $tz, $yr ) = /^
         (\w{1,3})             # month
            \s+
         (\d\d?)               # day
            \s+
         (\d\d?):(\d\d)        # hour:min
         (?::(\d\d))?          # optional seconds
            \s+
         (?:([A-Za-z]+)\s+)?   # optional timezone
         (\d+)                 # year
            \s*$               # allow trailing whitespace
        /x
    )

    ||

    # Then the Unix 'ls -l' date format
    (
    ( $mon, $day, $yr, $hr, $min, $sec ) = /^
         (\w{3})               # month
            \s+
         (\d\d?)               # day
            \s+
         (?:
            (\d\d\d\d) |       # year
            (\d{1,2}):(\d{2})  # hour:min
            (?::(\d\d))?       # optional seconds
         )
         \s*$
       /x
    )

    ||

    # ISO 8601 format '1996-02-29 12:00:00 -0100' and variants
    (
    ( $yr, $mon, $day, $hr, $min, $sec, $tz ) = /^
          (\d{4})              # year
             [-\/]?
          (\d\d?)              # numerical month
             [-\/]?
          (\d\d?)              # day
         (?:
               (?:\s+|[-:Tt])  # separator before clock
            (\d\d?):?(\d\d)    # hour:min
            (?::?(\d\d(?:\.\d*)?))?  # optional seconds (and fractional)
         )?                    # optional clock
            \s*
         ([-+]?\d\d?:?(:?\d\d)?
          |Z|z)?               # timezone  (Z is "zero meridian", i.e. GMT)
            \s*$
        /x
    )

    ||

    return;    # unrecognized format

  # Translate month name to number
       $mon = $MoY{$mon}
    || $MoY{"\u\L$mon"}
    || ( $mon =~ /^\d\d?$/ && $mon >= 1 && $mon <= 12 && int($mon) )
    || return;

  # If the year is missing, we assume first date before the current,
  # because of the formats we support such dates are mostly present
  # on "ls -l" listings.
  unless ( defined $yr ) {
    my $cur_mon;
    ( $cur_mon, $yr ) = (localtime)[ 4, 5 ];
    $yr += 1900;
    $cur_mon++;
    $yr-- if $mon > $cur_mon;
  }
  elsif ( length($yr) < 3 ) {

    # Find "obvious" year
    my $cur_yr = (localtime)[5] + 1900;
    my $m      = $cur_yr % 100;
    my $tmp    = $yr;
    $yr += $cur_yr - $m;
    $m -= $tmp;
    $yr += ( $m > 0 ) ? 100 : -100
      if abs($m) > 50;
  }

  # Make sure clock elements are defined
  $hr  = 0 unless defined($hr);
  $min = 0 unless defined($min);
  $sec = 0 unless defined($sec);

  # Compensate for AM/PM
  if ($ampm) {
    $ampm = uc $ampm;
    $hr = 0 if $hr == 12 && $ampm eq 'AM';
    $hr += 12 if $ampm eq 'PM' && $hr != 12;
  }

  return ( $yr, $mon, $day, $hr, $min, $sec, $tz )
    if wantarray;

  if ( defined $tz ) {
    $tz = "Z" if $tz =~ /^(GMT|UTC?|[-+]?0+)$/;
  }
  else {
    $tz = "";
  }
  return sprintf( "%04d-%02d-%02d %02d:%02d:%02d%s",
    $yr, $mon, $day, $hr, $min, $sec, $tz );
}

#function:proc_snapshot
#Get clusterware process metrics including "cpuusage,privmem,shm,fd,threads,priority" from all nodes
#input: $RESMON_PROC_LST, output of $OCLUMON
#return: $ret, 0.success 1. failed
sub proc_snapshot {
  my ( $myproc, $mypid, $mycpu, $myprivmem, $myshm, $myfd, $mythreads,
    $mypriority );


  #save metrics value of clusterware process in this array
  my @my_records;

  my $timestamp;
  foreach my $mynode (@NODE_LST)
  {    #this loop for all nodes to get processes metrics valuses
    my $cmd = "$OCLUMON dumpnodeview -n $mynode -last \"00:20:00\"  -v";

    while (TRUE)
    { #sometime can't get dumpview in last 20 mins, so this loop to make sure can get dump date once at last

      my $flag = FALSE;
      open( DUMPVIEW, "$cmd 2>&1 |" ) or die "Can't open \"$cmd\" for $!";
      my $i = 1;
      while (<DUMPVIEW>) {   #search timestamp and processes in $RESMON_PROC_LST
        if ( $_ =~
#/Node: $mynode Clock: \'(\d\d)-(\d\d)-(\d\d) (\d\d).(\d\d).(\d\d)\' .*/
#/Node: $mynode Clock: \'(\d\d)-(\d\d)-(\d\d) (\d\d).(\d\d).(\d\d).*\' .*/
/Node: $mynode Clock: \'(\d\d)-(\d\d)-(\d\d) (\d\d).(\d\d).(\d\d)\ .+' .*/ ||
$_ =~
/Node: $mynode Clock: \'(\d\d)-(\d\d)-(\d\d) (\d\d).(\d\d).(\d\d)\' .*/
          )
        {
          if ($flag)
          { #only get once data very $CHECK_INTERVAL, so exit when hit the 2nd timestamp
             #Getting metrics data for all process is done, then wirte @records to log file
            write_records( $mynode, @myrecords );
            Logger(
"proc_snapshot() complete snap processes metrics from node $mynode.\n"
            );

            #undef @myrecords;
            last;
          }
          else {
            $flag = TRUE;

            #record header in record log.
            $myrecords[0] = "TIME|PROC|PID|CPU|VSZ|PRIVMEM|SHM|FD|THREADS|PRIORITY";
          }
          unless (defined $CRS_VER){
          	my @tmp=exec_OS_cmd ("$CRSCTL query crs activeversion");
          	if ($tmp[0] =~/.*\s\[(\d+).(\d+).(\d+).(\d+).(\d+)\]$/){
          		$CRS_VER=$1 . $2 . $3 . $4 . $5;
          	}
          }
          if ( $CRS_VER > $VERSION_12_1){
          	$timestamp = "20" . $1 . $2 . $3 . "_" . $4 . $5 . $6;
          	next;
          }else{
          	$timestamp = "20" . $3 . $1 . $2 . "_" . $4 . $5 . $6;
          	next;
          }
        }
        elsif ( $_ =~
/^name: '(.*)' pid: (\d*) \#procfdlimit: .* cpuusage: (\d*\.?\d?).*privmem: (\d*) shm: (\d*) \#fd: (\d*) \#threads: (\d*) priority: ([-]?\d*)[ ]?/
          )
        {
          (
            $myproc, $mypid, $mycpu, $myprivmem, $myshm, $myfd, $mythreads,
            $mypriority
            )
            = ( $1, $2, $3, $4, $5, $6, $7, $8 );

#          if ( $RESMON_PROC_LST =~ /$myproc/i ){
#            $myrecords[$i]="$timestamp|$myproc|$mypid|$mycpu|$myprivmem|$myshm|$myfd|$mythreads|$mypriority";
#            $i++;
#          }else{
#            #ignore other processes which not in $RESMON_PROC_LST
#            next;
#          }
          chomp $myproc;
          $myproc =~ s/\..*$/.bin/;
          foreach my $tmpproc ( split( ' ', $RESMON_PROC_LST ) ) {
            chomp $tmpproc;
            if ( $myproc =~ /$tmpproc/i ) {
          #get virtual memory from 'ps -p $mypid -o vsz'
          $myvsz=`$SU $CRS_OWNER -c \"$SSH $mynode $PSP $mypid -o vsz | tail -1\"`;

          chomp $myvsz;
#         if process $mypid is not exist, then ignore it.
          if ( $myvsz=~ /VSZ/i ){
            last;
          }

          #if $myproc in $RESMON_PROC_LST, then save it in array $myrecords;else
              $myrecords[$i] =
"$timestamp|$myproc|$mypid|$mycpu|$myvsz|$myprivmem|$myshm|$myfd|$mythreads|$mypriority";
              $i++;
              last;
            }
          }
        }
        else {

   #ignore other recoreds that is not prcesses metrics data, maybe IO records...
          next;
        }
      }
      close DUMPVIEW;
      if ( scalar @myrecords <= 1 ) {  #can't get any records, continue the loop
        next;
      }
      else {                           #have got recoreds, stop the loop
        undef @myrecords;
        last;
      }
    }
  }
  Logger("proc_snapshot() complete snap processes metrics from all nodes.\n");
  return 0;
}

#function proc_analyse()
#check resource leak for all pid in $mynode_proc_mon.log for all nodes
#input: $1, ALL, check all records, LAST, check last $RESMON_COUNT records.
#output: $mynode_proc_anlys.log
#return $ret 0, sucess; 1, failed

sub proc_analyse {

  if ( scalar @_ != 1 ) {
    die "proc_analyse() need a parameter ALL or LAST\n";
  }
  my $param1 = shift @_;
  if ( uc $param1 ne "LAST" && uc $param1 ne "ALL" ) {
    die
"proc_analyse() need a parameter error $param1, it should be ALL or LAST\n";
  }
  my $pwd = getcwd();
  my $out_dir = get_output_dir();  #Rajeev
  my $logfile;
  my $i = 0;
  my @arr_records;
  my @tmp;

  #all records is value, pid and name is key
  my %pid2arr;

  #my %pid2shortarr;
  #spin cpu processes is value, pid and name is key
  my %pid2spinCPU;

#processes in RESMON_RT_LST and not working in RT value is value, pid and name is key
  my %pid2notRT;
  
  # this hash will save Non-RT threads whose name definfed in RESMON_RT_LST, this requirement due to bug#13935219 
  my %tpid2notRT;
  
  # add this hash value for performance issue. 
  my %RTProc2pid;

  #process name is value, pid is key
  my %pid2restart;

  #pid and name is key, leak records is value
  my %pid2memLeak;
  my %pid2fdLeak;
  my %pid2thdLeak;

  #pid and name is key, leak rack is value
  my %pid2memFlag;
  my %pid2fdFlag;
  my %pid2thdFlag;

#in order to avoid the the same pid been reused by new process,
# in the most of hash tables key value will be constructed proc name + pid as $pkey.
  my $pkey;

  #pid and name is key, rate is value
  my %pid2memRate;
  my %pid2fdRate;
  my %pid2thdRate;

  foreach my $mynode (@NODE_LST) {
    $logfile = $mynode . "_proc_mon.log";
    $logfile = catfile( $out_dir, "logs", $logfile );
    unless ( -e $logfile ) {
      warn("proc_analyse() can't find $logfile to analyse!");
      next;
    }
    open SNAPSHOT, "<$logfile" or die "Fail to open the $logfile for $!\n";

    if ( $param1 eq "LAST" ) {
      seek( SNAPSHOT, $NODE2LINE{$mynode}, 0 );
    }
    elsif ( $param1 eq "ALL" ) {

      #do nothing
    }
    else {
      die("proc_analyse() One enum parameter should be ALL or LAST!\n");
    }

    #init @arr_records
    while (<SNAPSHOT>) {
      if ( $_ =~ /^TIME/i ) {    #ignore the record header
        next;
      }
      else {
        @tmp = split( /\|/, $_ );
        chomp @tmp;

#format for array tmp should be "TIME|PROC|PID|CPU|VSZ|PRIVMEM|SHM|FD|THREADS|PRIORITY", so $tmp[2] is PID

        #if cpu usage >3%, script save this record as cpu spin happened.
        if ( $tmp[3] =~ '/S' && $tmp[3] > $SPIN_CPU_THRESHOLD ) {
          $pkey = $tmp[1] . "|" . $tmp[2];
          unless ( exists $pid2spinCPU{$pkey} ) {

            #push @{$pid2spinCPU{$pkey}},[@tmp];
            #format "TIME|PROC|PID|CPU"
            push @{ $pid2spinCPU{$pkey} },
              [ ( $tmp[0], $tmp[1], $tmp[2], $tmp[3] ) ];
          }
        }

#if process in RESMON_RT_LST are not working in RT module, will save the pid and it's record in %pid2notRT
        my @proc_rt = split( /\|/, $RESMON_RT_LST );

        foreach my $tmpproc (@proc_rt) {
          chomp $tmpproc;
          if ( $tmp[1] =~ /$tmpproc/i ) {
            if ( "ologgerd osysmond.bin" =~ /$tmp[1]/i ) {
              if ( $tmp[9] != $CRF_RT && $tmp[9] != $CSS_RT) {
                $pkey = $tmp[1] . "|" . $tmp[2];
                unless ( exists $pid2notRT{$pkey} ) {

                  #push @{$pid2notRT{$pkey}},[@tmp];
                  #format "TIME|PROC|PID|PRIORITY"
                  push @{ $pid2notRT{$pkey} },
                    [ ( $tmp[0], $tmp[1], $tmp[2], $tmp[9] ) ];
                }
              }else{
              	$RTProc2pid{$tmp[1]}=$tmp[2];
#              	@arr_records=`$SU $CRS_OWNER -c \"$SSH $mynode $PS -Leo pid,tid,class,rtprio | grep $tmp[2]\"`;
#              	foreach my $line (@arr_records){
#              		@attr_lst = split (' ', $line);
#              		$tmp_pri = $attr_lst[3];
#              		if ( $attr_lst[2] ne "RR" || $attr_lst[3] != $tmp_pri){
#              			$pkey = $tmp[1] . "|" . $attr_lst[1];
#              			unless ( exists $tpid2notRT{$pkey} ){
#              				$my_time = get_current_time();
#              				push @{ $tpid2notRT{$pkey}},
#              				  [ ( $my_time, $tmp[1], $attr_lst[0], $attr_lst[1], $attr_lst[2], $attr_lst[3] ) ];
#              			}
#              		}
#              	}
              }
            }
            elsif ( "ocssd.bin cssdmonitor cssdagent" =~ /$tmp[1]/i ) {
              if ( $tmp[9] != $CSS_RT ) {
                $pkey = $tmp[1] . "|" . $tmp[2];
                unless ( exists $pid2notRT{$pkey} ) {
                  push @{ $pid2notRT{$pkey} },
                    [ ( $tmp[0], $tmp[1], $tmp[2], $tmp[9] ) ];
                }
              }else{
              	$RTProc2pid{$tmp[1]}=$tmp[2];
#              	@arr_records=`$SU $CRS_OWNER -c \"$SSH $mynode $PS -Leo pid,tid,class,rtprio | grep $tmp[2]\"`;
#              	foreach my $line (@arr_records){
#              		@attr_lst = split (' ', $line);
#              		$tmp_pri = $attr_lst[3];
#              		if ( $attr_lst[2] ne "RR" || $attr_lst[3] != $tmp_pri){
#              			$pkey = $tmp[1] . "|" . $attr_lst[1];
#              			unless ( exists $tpid2notRT{$pkey} ){
#              				$my_time = get_current_time();
#              				push @{ $tpid2notRT{$pkey}},
#              				[($my_time,$tmp[1], $attr_lst[0], $attr_lst[1], $attr_lst[2], $attr_lst[3])];
#              			}
#              		}
#              	}              
              }
            }
            elsif ( $tmp[1] =~ /vktm|lms/i ) {
              if ( $tmp[9] != $NONE_ROOT_RT ) {
                $pkey = $tmp[1] . "|" . $tmp[2];
                unless ( exists $pid2notRT{$pkey} ) {
                  push @{ $pid2notRT{$pkey} },
                    [ ( $tmp[0], $tmp[1], $tmp[2], $tmp[9] ) ];
                }
              }else{
              	$RTProc2pid{$tmp[1]}=$tmp[2];
#              	@arr_records=`$SU $CRS_OWNER -c \"$SSH $mynode $PS -Leo pid,tid,class,rtprio | grep $tmp[2]\"`;
#              	foreach my $line (@arr_records){
#              		@attr_lst = split (' ', $line);
#              		$tmp_pri = $attr_lst[3];
#              		if ( $attr_lst[2] ne "RR" || $attr_lst[3] != $tmp_pri){
#              			$pkey = $tmp[1] . "|" . $attr_lst[1];
#              			unless ( exists $tpid2notRT{$pkey} ){
#              				$my_time = get_current_time();
#              				push @{ $tpid2notRT{$pkey}},
#              				[($my_time,$tmp[1], $attr_lst[0], $attr_lst[1], $attr_lst[2], $attr_lst[3])];
#              			}
#              		}
#              	}              	
              }
            }
            else {
              die
"proc_analyse() this process $tmp[1] is not in the $RESMON_RT_LST, script shouldn't come here, exit!\n";
            }
          }
        }

        #if one process which have mutiple pids as it has restarted
        $pkey = $tmp[1] . "|" . $tmp[2];
        unless ( exists $pid2restart{$pkey} ) {

          #format "TIME|PROC|PID"
          push @{ $pid2restart{$pkey} }, [ ( $tmp[0], $tmp[1], $tmp[2] ) ];
        }

        #put the proc name and pid as key and row as value of each record from
        #$mynode_proc_mon.log into the hash table %pid2arr
        push @{ $pid2arr{$pkey} }, [@tmp];
      }
    }
    close SNAPSHOT;

    #find resource leak
    my ( $increment, $rate, @attr_lst, $tmp_pri, $my_time );
    foreach my $mykey ( keys %pid2arr ) {
      if ( $#{ $pid2arr{$mykey} } < 2 ) {

        #ignore the records which only have less than 3
        next;
      }

      #found memory leak
      #format for array is "TIME|PROC|PID|CPU|VSZ|PRIVMEM|SHM|FD|THREADS|PRIORITY"
      #print "Big value $pid2arr{$mykey}[-1][4], small value $pid2arr{$mykey}[0][4]\n";
      if ( $pid2arr{$mykey}[-1][4] =~/\D/ || $pid2arr{$mykey}[0][4] =~/\D/){
        next; 
      }
      $increment = sprintf(
        "%.2f",
#        (
#          $pid2arr{$mykey}[-1][4] + $pid2arr{$mykey}[-1][5] -
#            $pid2arr{$mykey}[0][4] - $pid2arr{$mykey}[0][5]
#          ) / 1024
        (
          $pid2arr{$mykey}[-1][4] - $pid2arr{$mykey}[0][4]
          ) / 1024
      );
      $rate = minus_time( $pid2arr{$mykey}[-1][0], $pid2arr{$mykey}[0][0] );
      if ( $rate > 0 ){
        $rate = sprintf( "%.2f", $increment / $rate );
      }

      #set step length
      my ( $i, $stepLength ) = ( 0, 1 );
      if ( $param1 eq "ALL" ) {
      	#modified from if ( $#{ $pid2arr{$mykey} } < ( $RESMON_COUNT - 1 ) ) { to if ( $#{ $pid2arr{$mykey} } <= ( $RESMON_COUNT - 1 ) ) {
      	#since forget to 4 recorde for every pid.
        if ( $#{ $pid2arr{$mykey} } <= ( $RESMON_COUNT - 1 ) ) {
          $stepLength = 1;
        }
        else {
          $stepLength = sprintf( "%d", $#{ $pid2arr{$mykey} } / $RESMON_COUNT );
        }
      }
      else {
        $stepLength = 1;
      }
      if ( $rate >= $MEMORY_LEAK_RATE_THRESHOLD ) {
        $pid2memRate{$mykey} = $rate;
        for (
          $i = 0 ;
          $i + $stepLength <= $#{ $pid2arr{$mykey} } ;
          $i = $i + $stepLength
          )
        {

#get $RESMON_COUNT records from all
#new format in short array "TIME|PROC|PID|VSZ|PRIVMEM|SHM", this array should have $RESMON_COUNT records
          push @{ $pid2memLeak{$mykey} },
            [
            (
              $pid2arr{$mykey}[$i][0], $pid2arr{$mykey}[$i][1],
              $pid2arr{$mykey}[$i][2], $pid2arr{$mykey}[$i][4],
              $pid2arr{$mykey}[$i][5], $pid2arr{$mykey}[$i][6]
            )
            ];

#format for array tmp should be "TIME|PROC|PID|CPU|VSZ|PRIVMEM|SHM|FD|THREADS|PRIORITY"
          if ( $pid2arr{$mykey}[ $i + $stepLength ][4]  >
            $pid2arr{$mykey}[$i][4] )
          {
            push @{ $pid2memFlag{$mykey} }, '+';
          }
          elsif ( $pid2arr{$mykey}[ $i + $stepLength ][4] <
             $pid2arr{$mykey}[$i][4] )
          {
            push @{ $pid2memFlag{$mykey} }, '-';
          }
          else {
            push @{ $pid2memFlag{$mykey} }, '=';
          }
        }

        #add the last line data
        push @{ $pid2memLeak{$mykey} },
          [
          (
            $pid2arr{$mykey}[$i][0], $pid2arr{$mykey}[$i][1],
            $pid2arr{$mykey}[$i][2], $pid2arr{$mykey}[$i][4],
            $pid2arr{$mykey}[$i][5], $pid2arr{$mykey}[$i][6]
          )
          ];

      }

      #found file handle leak
      #format for array is "TIME|PROC|PID|CPU|VSZ|PRIVMEM|SHM|FD|THREADS|PRIORITY"
      $increment =
        sprintf( "%d", $pid2arr{$mykey}[-1][7] - $pid2arr{$mykey}[0][7] );
        $rate = minus_time( $pid2arr{$mykey}[-1][0], $pid2arr{$mykey}[0][0] );
        if ( $rate > 0){
          $rate = sprintf( "%d", $increment / $rate );
        }
      #$rate = sprintf( "%.2f", $increment / $pid2arr{$mykey}[0][7] );
      if ( $rate >= $FD_LEAK_RATE_THRESHOLD ) {
        $pid2fdRate{$mykey} = $rate;
        for (
          $i = 0 ;
          $i + $stepLength <= $#{ $pid2arr{$mykey} } ;
          $i = $i + $stepLength
          )
        {

#get $RESMON_COUNT records from all
#new format in short array "TIME|PROC|PID|FD", this array should have $RESMON_COUNT records
          push @{ $pid2fdLeak{$mykey} },
            [
            (
              $pid2arr{$mykey}[$i][0], $pid2arr{$mykey}[$i][1],
              $pid2arr{$mykey}[$i][2], $pid2arr{$mykey}[$i][7]
            )
            ];

#format for array tmp should be "TIME|PROC|PID|VSZ|CPU|PRIVMEM|SHM|FD|THREADS|PRIORITY"
          if (
            $pid2arr{$mykey}[ $i + $stepLength ][7] > $pid2arr{$mykey}[$i][7] )
          {
            push @{ $pid2fdFlag{$mykey} }, '+';
          }
          elsif (
            $pid2arr{$mykey}[ $i + $stepLength ][7] < $pid2arr{$mykey}[$i][7] )
          {
            push @{ $pid2fdFlag{$mykey} }, '-';
          }
          else {
            push @{ $pid2fdFlag{$mykey} }, '=';
          }
        }
        push @{ $pid2fdLeak{$mykey} },
          [
          (
            $pid2arr{$mykey}[$i][0], $pid2arr{$mykey}[$i][1],
            $pid2arr{$mykey}[$i][2], $pid2arr{$mykey}[$i][7]
          )
          ];

      }

      #found thread leak
      #format for array is "TIME|PROC|PID|CPU|VSZ|PRIVMEM|SHM|FD|THREADS|PRIORITY"
      $increment =
        sprintf( "%d", $pid2arr{$mykey}[-1][8] - $pid2arr{$mykey}[0][8] );
      #$rate = sprintf( "%.2f", $increment / $pid2arr{$mykey}[0][8] );
      $rate = minus_time( $pid2arr{$mykey}[-1][0], $pid2arr{$mykey}[0][0] );
      if ( $rate > 0 ){
        $rate = sprintf( "%d", $increment / $rate );
      }
      if ( $rate >= $THREAD_LEAK_RATE_THRESHOLD ) {

        $pid2thdRate{$mykey} = $rate;
        for (
          $i = 0 ;
          $i + $stepLength <= $#{ $pid2arr{$mykey} } ;
          $i = $i + $stepLength
          )
        {

#get $RESMON_COUNT records from all
#new format in short array "TIME|PROC|PID|THD", this array should have $RESMON_COUNT records
          push @{ $pid2thdLeak{$mykey} },
            [
            (
              $pid2arr{$mykey}[$i][0], $pid2arr{$mykey}[$i][1],
              $pid2arr{$mykey}[$i][2], $pid2arr{$mykey}[$i][8]
            )
            ];

#format for array tmp should be "TIME|PROC|PID|CPU|VSZ|PRIVMEM|SHM|FD|THREADS|PRIORITY"
          if (
            $pid2arr{$mykey}[ $i + $stepLength ][8] > $pid2arr{$mykey}[$i][8] )
          {
            push @{ $pid2thdFlag{$mykey} }, '+';
          }
          elsif (
            $pid2arr{$mykey}[ $i + $stepLength ][8] < $pid2arr{$mykey}[$i][8] )
          {
            push @{ $pid2thdFlag{$mykey} }, '-';
          }
          else {
            push @{ $pid2thdFlag{$mykey} }, '=';
          }
        }
        push @{ $pid2thdLeak{$mykey} },
          [
          (
            $pid2arr{$mykey}[$i][0], $pid2arr{$mykey}[$i][1],
            $pid2arr{$mykey}[$i][2], $pid2arr{$mykey}[$i][8]
          )
          ];
      }
    }
		foreach my $mykey ( keys %RTProc2pid ) {
		  if ($PLATFORM eq "linux") {
    	    @arr_records=`$SU $CRS_OWNER -c \"$SSH $mynode $PS -Leo pid,tid,class,rtprio | grep $RTProc2pid{$mykey}\"`;
          } elsif ($PLATFORM eq "solaris") {
            @arr_records=`$SU $CRS_OWNER -c \"$SSH $mynode $PRSTAT -Lcp $RTProc2pid{$mykey} 1 1| grep $RTProc2pid{$mykey} | awk '{print\\\$1,\\\$NF,\\\$6,\\\$7}'\"`;
          } else {
            warn "code for check threads priority have not be ported to this platform!";
          }
    	  foreach my $line (@arr_records){
    		@attr_lst = split (' ', $line);
    		$tmp_pri = $attr_lst[3];
    		if ( $PLATFORM eq "linux" && $attr_lst[2] ne "RR"|| $PLATFORM eq "solaris" && $attr_lst[2] < 100){
    			$pkey = $mykey . "|" . $attr_lst[1];
    			unless ( exists $tpid2notRT{$pkey} ){
    				$my_time = get_current_time();
    				push @{ $tpid2notRT{$pkey}},
    				[($my_time,$mykey, $attr_lst[0], $attr_lst[1], $attr_lst[2], $attr_lst[3])];
    			}
    		}
    	}
		}
    #write analysis report if found resource leak or process restart
    if ( %pid2spinCPU
      || %pid2notRT
      || %pid2memLeak
      || %pid2fdLeak
      || %pid2thdLeak
      || %tpid2notRT )
    {
      my $rptname = $mynode . "_proc_anlys.log";
      $rptname = catfile( get_output_dir(), "logs", $rptname );
      open ANALYSISREPORT, ">>", $rptname
        or die "Fail to open the $rptname for $!\n";
      my $cur = get_current_time();
      print ANALYSISREPORT "\n****Analysis Report*****$cur*****\n";
      my ( $mem1, $mem2, $duration, $inc, $line, $fdcnt, $thdcnt );
      if (%pid2memLeak) {
        print ANALYSISREPORT "\n***Memory Leak***\n";
        foreach my $mykey ( keys %pid2memLeak ) {
          print ANALYSISREPORT "\nProcess Name|PID: $mykey\n";
          print ANALYSISREPORT "Memory Leak Rate: $pid2memRate{$mykey} MB/HR\n";
          $mem1 = sprintf( "%d",
            $pid2memLeak{$mykey}[0][3] );
          $mem2 = sprintf( "%d",
            $pid2memLeak{$mykey}[-1][3] );
          $inc = sprintf( "%d", ( $mem2 - $mem1 ) / 1024 );
          print ANALYSISREPORT "Memory Increment (VSZ): $inc MB\n";
          $duration = minus_time( $pid2memLeak{$mykey}[-1][0],
            $pid2memLeak{$mykey}[0][0] );
          print ANALYSISREPORT "Duration: $duration Hours\n";
          $line = join( " ", @{ $pid2memFlag{$mykey} } );
          print ANALYSISREPORT "Memory Track:$line\n";
          print ANALYSISREPORT "Details:\n";
          print ANALYSISREPORT "TIME|PROC|PID|VSZ|PRIVMEM|SHM\n";

          for ( my $i = 0 ; $i <= $#{ $pid2memLeak{$mykey} } ; $i++ ) {
            $line = join( "|", @{ $pid2memLeak{$mykey}[$i] } );
            print ANALYSISREPORT "$line\n";
          }
        }
      }

      #found FD leak
      if (%pid2fdLeak) {
        print ANALYSISREPORT "\n***File Handle Leak***\n";
        foreach my $mykey ( keys %pid2fdLeak ) {
          print ANALYSISREPORT "\nProcess Name|PID: $mykey\n";
          print ANALYSISREPORT "FD Leak Rate: $pid2fdRate{$mykey} FDs/HR\n";
          $fdcnt = sprintf( "%d",
            $pid2fdLeak{$mykey}[-1][3] - $pid2fdLeak{$mykey}[0][3] );
          print ANALYSISREPORT "FD Increment: $fdcnt\n";
          $duration =
            minus_time( $pid2fdLeak{$mykey}[-1][0], $pid2fdLeak{$mykey}[0][0] );
          print ANALYSISREPORT "Duration: $duration Hours\n";
          $line = join( " ", @{ $pid2fdFlag{$mykey} } );
          print ANALYSISREPORT "FD Track:$line\n";
          print ANALYSISREPORT "Details:\n";
          print ANALYSISREPORT "TIME|PROC|PID|FD\n";

          for ( my $i = 0 ; $i <= $#{ $pid2fdLeak{$mykey} } ; $i++ ) {
            $line = join( "|", @{ $pid2fdLeak{$mykey}[$i] } );
            print ANALYSISREPORT "$line\n";
          }
        }
      }

      #found thread leak
      if (%pid2thdLeak) {
        print ANALYSISREPORT "\n***Thread Leak***\n";
        foreach my $mykey ( keys %pid2thdLeak ) {
          print ANALYSISREPORT "\nProcess Name|PID: $mykey\n";
          print ANALYSISREPORT "Thd Leak Rate: $pid2thdRate{$mykey} TRDs/HR\n";
          $fdcnt = sprintf( "%d",
            $pid2thdLeak{$mykey}[-1][3] - $pid2thdLeak{$mykey}[0][3] );
          print ANALYSISREPORT "FD Increment: $fdcnt\n";
          $duration = minus_time( $pid2thdLeak{$mykey}[-1][0],
            $pid2thdLeak{$mykey}[0][0] );
          print ANALYSISREPORT "Duration: $duration Hours\n";
          $line = join( " ", @{ $pid2thdFlag{$mykey} } );
          print ANALYSISREPORT "FD Track:$line\n";
          print ANALYSISREPORT "Details:\n";
          print ANALYSISREPORT "TIME|PROC|PID|THREADS\n";

          for ( my $i = 0 ; $i <= $#{ $pid2thdLeak{$mykey} } ; $i++ ) {
            $line = join( "|", @{ $pid2thdLeak{$mykey}[$i] } );
            print ANALYSISREPORT "$line\n";
          }
        }
      }
      if (%pid2spinCPU) {
        print ANALYSISREPORT "\n***Spin CPU***\n";
        foreach my $mykey ( keys %pid2spinCPU ) {
          print ANALYSISREPORT "\nProcess Name|PID: $mykey\n";
          print ANALYSISREPORT "Details:\n";

          #format "TIME|PROC|PID|CPU"
          print ANALYSISREPORT "TIME|PROC|PID|CPU\n";
          for ( my $i = 0 ; $i <= $#{ $pid2spinCPU{$mykey} } ; $i++ ) {
            $line = join( "|", @{ $pid2spinCPU{$mykey}[$i] } );
            print ANALYSISREPORT "$line\n";
          }
        }
      }

      if (%pid2notRT) {
        print ANALYSISREPORT "\n***Processes Not In RT***\n";
        foreach my $mykey ( keys %pid2notRT ) {
          print ANALYSISREPORT "\nProcess Name|PID: $mykey\n";
          print ANALYSISREPORT "Details:\n";

          #format "TIME|PROC|PID|PRIORITY"
          print ANALYSISREPORT "TIME|PROC|PID|PRIORITY\n";
          for ( my $i = 0 ; $i <= $#{ $pid2notRT{$mykey} } ; $i++ ) {
            $line = join( "|", @{ $pid2notRT{$mykey}[$i] } );
            print ANALYSISREPORT "$line\n";
          }
        }
      }
      
      if (%tpid2notRT){
        print ANALYSISREPORT "\n***Threads Not In RT***\n";
        my $cur_pname;
        my $pre_pname="NULL";
        foreach my $mykey ( sort {$a cmp $b} ( keys %tpid2notRT ) ) {
        	$cur_pname = (split ('\|', $mykey))[0];
        	if ( $pre_pname ne $cur_pname ){
	          print ANALYSISREPORT "\nProcess Name: $cur_pname\n";
	          print ANALYSISREPORT "Details:\n";
	          #format "TIME|PROC|PID|TID|CLASS|RTPRIO"
	          print ANALYSISREPORT "TIME|PROC|PID|TID|CLASS|RTPRIO\n";
          }


          for ( my $i = 0 ; $i <= $#{ $tpid2notRT{$mykey} } ; $i++ ) {
            $line = join( "|", @{ $tpid2notRT{$mykey}[$i] } );
            print ANALYSISREPORT "$line\n";
          }
          $pre_pname = $cur_pname;
        }      	
      }
      
      if (%pid2restart) {
        my @pname = keys %pid2restart;
        my @arr_panme;
        my %pname2pids;
        my $isRestared = FALSE;
        my $pk;
        foreach $line (@pname) {
          @arr_panme = split( /\|/, $line );
          push @{ $pname2pids{ $arr_panme[0] } }, $arr_panme[1];
          if ( $#{ $pname2pids{ $arr_panme[0] } } >= 1 ) {
            $isRestared = TRUE;
          }
        }
        if ($isRestared) {
          print ANALYSISREPORT "\n***Processes With Multiple Pids***\n";
          my $multi_flag;
          foreach my $mykey ( keys %pname2pids ) {

            if ( $mykey =~ /ons|agent|tnslsnr/){
              $multi_flag = TRUE;
            }else{
              $multi_flag = FALSE;
            }
            if ( $#{ $pname2pids{$mykey} } >= 1 ) {
              if ($multi_flag == TRUE && $#{ $pname2pids{$mykey} } ==1 ){
                next;
              }elsif( lc $mykey eq "oracle" && $#{ $pname2pids{$mykey} } >= 1){
              	next;
              }
              print ANALYSISREPORT "\nProcess Name: $mykey\n";
              print ANALYSISREPORT "Details:\n";
              print ANALYSISREPORT "TIME|PROC|PID\n";
              foreach my $mypid ( @{ $pname2pids{$mykey} } ) {
                $pk = "$mykey" . "|" . "$mypid";

                #format "TIME|PROC|PID"
                for ( my $i = 0 ; $i <= $#{ $pid2restart{$pk} } ; $i++ ) {
                  $line = join( "|", @{ $pid2restart{$pk}[$i] } );
                  print ANALYSISREPORT "$line\n";
                }
              }
            }
          }
        }
      }

      $cur = get_current_time();
      print ANALYSISREPORT "\n****Done*****$cur*****\n";
      close ANALYSISREPORT;
      Logger("proc_analyse() write report for node $mynode successfully!\n");

      #clear memory
      undef %pid2arr;
      undef %pid2spinCPU;
      undef %pid2notRT;
      undef %pid2restart;
      undef %pid2memLeak;
      undef %pid2fdLeak;
      undef %pid2thdLeak;
      undef %pid2memFlag;
      undef %pid2fdFlag;
      undef %pid2thdFlag;
      undef %pid2memRate;
      undef %pid2fdRate;
      undef %pid2thdRate;
      undef %tpid2notRT;
    }

  }
  Logger("proc_analyse() analyse resource leak for all nodes successfully!\n");
  return 0;
}

#function write_records()
#input: $mynodes, @records
#Global: $isSavePosition, %NODE2LINE
#output: $ret, 0 success, 1 failed
sub write_records {
  my $mynode = shift @_;
  unless ( defined $mynode ) {
    Logger("write_report() can't get node name!\n");
    return 1;
  }
  my @records = @_;
  unless (@records) {
    Logger("write_report() can't get records!\n");
    return 1;
  }
  my $pwd     = getcwd();
  my $out_dir = get_output_dir();  #Rajeev

  my $logfile = $mynode . "_proc_mon.log";
  $logfile = catfile( $out_dir, "logs", $logfile );
  open SNAPSHOT, ">>", "$logfile" or die "Fail to open the $logfile for $!\n";
  if ($isSavePosition) {#save the positon in $mynode_proc_mon.log for new $RESMON_COUNT;
    $NODE2LINE{$mynode} = tell(SNAPSHOT);
  }
  foreach my $line (@records) {
    print SNAPSHOT "$line\n";
  }
  close SNAPSHOT;
  Logger("write_report() write records for node $mynode successfully!\n");
  return 0;
}

#function: minus_time()
#input: $endtime, $starttime format like 20101230_050035
#return: $hours, OK, if undef, failed
sub minus_time() {
  my $hours;
  if ( scalar @_ != 2 ) {
    Logger("minus_time() can't get start and end time!\n");
    return 1;
  }
  my $endtime   = shift @_;
  my $starttime = shift @_;
  if ( $starttime =~ /(\d\d\d\d)(\d\d)(\d\d)_(\d\d)(\d\d)(\d\d)/ ) {
    $starttime = timelocal( "$6", "$5", "$4", "$3", $2 - 1, "$1" );
  }
  else {
    Logger("minus_time() wrong start time format: $starttime\n");
    return undef;
  }

  if ( $endtime =~ /(\d\d\d\d)(\d\d)(\d\d)_(\d\d)(\d\d)(\d\d)/ ) {
    $endtime = timelocal( "$6", "$5", "$4", "$3", $2 - 1, "$1" );
  }
  else {
    Logger("minus_time() wrong end time format: $endtime\n");
    return undef;
  }
  $hours = sprintf( "%.4f", ( $endtime - $starttime ) / 3600 );
  return $hours;
}

#Function: proc_monitor_handler
#Call proc_snapshot() to record metrics in every $RESMON_INTERVAL,
#then call proc_analyse() to analyse resource leak in every $RESMON_COUNT
#Input:None
#Output: None
sub proc_monitor_handler {
  my $param1 = shift @_;
  if ( uc $param1 ne "ALL" && uc $param1 ne "LAST" ) {
    die("proc_monitor_handler() parameter error, it should be ALL or LAST.\n");
  }
  unless ( defined $RESMON_PROC_LST ) {

    #get RESMON_PROC_LST processes list
    $RESMON_PROC_LST = get_attribute_value_of_resource( $RESOURCE_NAME, "RESMON_PROC_LST" );
    chomp $RESMON_PROC_LST;
    my @tmp = split( ' ', $RESMON_PROC_LST );
    if ( scalar @tmp == 0 ) {
      Logger(
        "proc_monitor_handler() failed to get resource key of RESMON_PROC_LST!"
      );
      return 1;
    }
  }

  unless ( defined $RESMON_RT_LST ) {

    #get RESMON_PROC_LST processes list
    $RESMON_RT_LST = get_attribute_value_of_resource( $RESOURCE_NAME, "RESMON_RT_LST" );
    chomp $RESMON_PROC_LST;
    my @tmp = split( ' ', $RESMON_RT_LST );
    if ( scalar @tmp == 0 ) {
      Logger(
        "proc_monitor_handler() failed to get resource key of RESMON_RT_LST!\n"
      );
      return 1;
    }
  }

  #get RESMON_INTERVAL
  unless ( defined $RESMON_INTERVAL ) {
    $RESMON_INTERVAL = get_attribute_value_of_resource( $RESOURCE_NAME, "RESMON_INTERVAL" );
    chomp $RESMON_INTERVAL;
    unless ( defined $RESMON_INTERVAL ) {
      Logger("proc_monitor_handler() can't get parameter RESMON_INTERVAL!\n");
      return 1;
    }
  }

  #get RESMON_COUNT
  unless ( defined $RESMON_COUNT ) {
    $RESMON_COUNT = get_attribute_value_of_resource( $RESOURCE_NAME, "RESMON_COUNT" );
    chomp $RESMON_COUNT;
    unless ( defined $RESMON_COUNT ) {
      Logger("proc_monitor_handler() can't get parameter RESMON_COUNT!\n");
      return 1;
    }
  }

  #get node list in IPD/OS
  unless (defined $CRS_VER){
  	my @tmp=exec_OS_cmd ("$CRSCTL query crs activeversion");
  	if ($tmp[0] =~/.*\s\[(\d+).(\d+).(\d+).(\d+).(\d+)\]$/){
  		$CRS_VER=$1 . $2 . $3 . $4 . $5;
  	}
  }
  if ($CRS_VER > $VERSION_12_1){
  	@NODE_LST = exec_OS_cmd "$OLSNODES -a | grep -i hub | awk '{print\$1}'";
  	chomp @NODE_LST;
  }else{
	  unless ( defined $NODE_LST[0] ) {
	    #@NODE_LST = exec_OS_cmd "$OCLUMON showobjects";
            @NODE_LST = exec_OS_cmd "$OLSNODES -s\|grep Active\|awk \'\{print\$1\}\'";
	    chomp @NODE_LST;
	    #@NODE_LST = grep ( !/Following|^ *$/, @NODE_LST );
	  }  	
  }
  
  if ( scalar @NODE_LST == 0 ) {
	  Logger("proc_monitor_handler() can't get node list from 'oclumon showobjects'!\n");
	  return 1;
  }

  my $isAnalyse = 0;
  my $ret;
  if ( uc $param1 eq "LAST" ) {
    while (TRUE) {
      unless ( check_chm_master() eq $HOST) {
        Logger(
          "proc_monitor_handler() this is not CHM master node, so do nothing!\n"
        );
        sleep $RESMON_INTERVAL;
        next;
      }
      if ( $isAnalyse == 0 ) {
        $isSavePosition = TRUE;
      }
      else {
        $isSavePosition = FALSE;
      }
      $ret = proc_snapshot();
      if ( $ret == 1 ) {
        Logger("proc_monitor_handler() proc_snapshot failed!\n");
        return 1;
      }
      else {
        $isAnalyse++;
        Logger("proc_monitor_handler() call proc_snapshot successfully!\n");
      }
      if ( $isAnalyse == $RESMON_COUNT ) {
        $ret = proc_analyse "LAST";
        if ( $ret == 1 ) {
          Logger("proc_monitor_handler() proc_analyse failed!\n");
          return 1;
        }
        else {
          $isAnalyse = 0;
          Logger("proc_monitor_handler() call proc_analyse successfully!\n");
        }
      }
      sleep $RESMON_INTERVAL;
    }
  }
  else {
    $ret = proc_analyse "ALL";
    if ( $ret == 1 ) {
      Logger("proc_monitor_handler() proc_analyse failed!\n");
      return 1;
    }
    else {
      Logger("proc_monitor_handler() call proc_analyse successfully!\n");
    }
  }
}

#function check_chm_master()
#this function check local node is master or not
#input:none
#return: $master node, .
sub check_chm_master() {
  my @ret = exec_OS_cmd "$OCLUMON manage -get master";
  my $master;
  @ret = grep ( /^Master/, @ret );
  if ( defined $ret[0] ) {
    if ( $ret[0] =~ /Master = (.*)/ ) {
      $master = $1;
    }
    else {
      die "check_chm_master() can't get master node is empty!\n";
    }
  }
  else {
    die "check_chm_master() failed to get master node\n@ret";
  }
  return $master;
}

#Function: node_monitor_handler()
#Call eviction_handler() to record node evciton event in every $NODEMON_INTERVAL
#Input:ALL|LAST
#Output: None
sub node_monitor_handler {
  my $param1 = shift @_;
  if ( uc $param1 ne "ALL" && uc $param1 ne "LAST" ) {
    die("node_monitor_handler() parameter error, it should be ALL or LAST.\n");
  }

  #get NODEMON_INTERVAL
  unless ( defined $NODEMON_INTERVAL ) {
    $NODEMON_INTERVAL = get_attribute_value_of_resource( $RESOURCE_NAME, "NODEMON_INTERVAL" );
    chomp $NODEMON_INTERVAL;
    unless ( defined $NODEMON_INTERVAL ) {
      Logger("node_monitor_handler() can't get parameter NODEMON_INTERVAL!\n");
      return 1;
    }
  }

  #get NODEMON_TIMESTEP
  unless ( defined $NODEMON_TIMESTEP ) {
    $NODEMON_TIMESTEP = get_attribute_value_of_resource( $RESOURCE_NAME, "NODEMON_TIMESTEP" );
    chomp $NODEMON_TIMESTEP;
    unless ( defined $NODEMON_TIMESTEP ) {
      Logger("node_monitor_handler() can't get parameter $NODEMON_TIMESTEP!\n");
      return 1;
    }
  }

  my $ret;
  if ( uc $param1 eq "LAST" ) {
    while (TRUE) {
      unless ( check_chm_master() eq $HOST ) {
        Logger(
          "node_monitor_handler() this is not CHM master node, so do nothing!\n"
        );
        sleep $NODEMON_INTERVAL;
        next;
      }

      $ret = eviction_handler("LAST","NODE_EVICTION");
      sleep $NODEMON_INTERVAL;
    }
  }
  else {
    $ret = eviction_handler("ALL","NODE_EVICTION");
    if ( $ret == TRUE ) {
      Logger("node_monitor_handler() eviction_handler \"ALL\" successfully!\n");
      return TRUE;
    }
    else {
      Logger("node_monitor_handler() call eviction_handler \"ALL\" failed!\n");
      return FALSE;
    }
  }
}
#Function: inst_monitor_handler()
#Call eviction_handler() to record node evciton event in every $NODEMON_INTERVAL
#Input:ALL|LAST
#Output: None
sub inst_monitor_handler {
  my $param1 = shift @_;
  my $ret;
  if ( uc $param1 ne "ALL" && uc $param1 ne "LAST" ) {
    die("inst_monitor_handler() parameter error, it should be ALL or LAST.\n");
  }

  #get INSTMON_INTERVAL
  unless ( defined $INSTMON_INTERVAL ) {
    $INSTMON_INTERVAL = get_attribute_value_of_resource( $RESOURCE_NAME, "INSTMON_INTERVAL" );
    chomp $INSTMON_INTERVAL;
    unless ( defined $INSTMON_INTERVAL ) {
      Logger("inst_monitor_handler() can't get parameter INSTMON_INTERVAL!\n");
      return 1;
    }
  }

  #get INSTMON_TIMESTEP
  unless ( defined $INSTMON_TIMESTEP ) {
    $INSTMON_TIMESTEP = get_attribute_value_of_resource( $RESOURCE_NAME, "INSTMON_TIMESTEP" );
    chomp $INSTMON_INTERVAL;
    unless ( defined $INSTMON_TIMESTEP ) {
      Logger("inst_monitor_handler() can't get parameter INSTMON_TIMESTEP!\n");
      return 1;
    }
  }
  #init hash %INSTANCE2NODE
  my $db_tmp;
  unless ( %INSTANCE2NODE){
    $ret=init_instance2node(\%INSTANCE2NODE);
    unless ( defined $ret){
      Logger("inst_monitor_handler() failed to call init_instance2node!\n");
    }
  }
  if ( uc $param1 eq "LAST" ) {
    while (TRUE) {
      unless ( isCheckInstEvict(\@DB4DUMP) ) {
        Logger(
          "inst_monitor_handler() there is no instance needs to check, so quit!\n"
        );
        sleep $INSTMON_INTERVAL;
        next;
      }else{
        $db_tmp = join (' ', @DB4DUMP);
        #Logger("inst_monitor_handler following database $db_tmp need to be checked on this node. \n");
      }

      $ret = eviction_handler("LAST","INST_EVICTION");
      sleep $INSTMON_INTERVAL;
    }
  }
  else {
    $ret = eviction_handler("ALL","INST_EVICTION");
    if ( $ret == TRUE ) {
      Logger("INST_monitor_handler() eviction_handler \"ALL\" successfully!\n");
      return TRUE;
    }else {
      Logger("INST_monitor_handler() call eviction_handler \"ALL\" failed!\n");
      return FALSE;
    }
  }
}




#Function: eviction_handler()
#Deal with node and instance eviction. Call read_evict_log to initialize %time2node,
#call event_detect to detect eviction and initialize %tmp_time2node, call dump_node_view
#to dump performance data for eviction event, at last call write_evict_log to write eviction and dump information
#
#Input:ALL|LAST, NODE_EVICTION|INST_EVICTION
#return: True or failed
sub eviction_handler {
  my $param1 = shift @_;
  my $param2 = shift @_;
  my (%old_timename2info, %new_timename2info);
  my (@old_dump, @new_dumnp,$hash_ref);
  my ($ret,$path,$inst,$file);
  if ( uc $param1 ne "ALL" && uc $param1 ne "LAST" ||  uc $param2 ne "NODE_EVICTION" && uc $param2 ne "INST_EVICTION") {
    die("node_monitor_handler() parameter error, parameter should be ALL|LAST and NODE_EVICTION|INST_EVICTION.\n");
  }
  #Get all evicted event
  if ( uc $param1 eq "ALL" && uc $param2 eq "INST_EVICTION"){
   @DB4DUMP = exec_OS_cmd ("$SRVCTL config");
   chomp @DB4DUMP;
   unless ( %DB2ALERTLOG ){
     foreach my $db (@DB4DUMP){
       $hash_ref = get_DB_log_dest($db);
       $path = $hash_ref->{'background_dump'};
       $inst = (split ('\/',$path))[-2];
       $file = "alert" . "_" . $inst . ".log";
       $path = catfile ($path, $file);
       $DB2ALERTLOG{$db}=$path;
     }
   }
  }
  event_detect($param2, \%new_timename2info);
  #Get the evicted event that has been done
  read_evict_log($param2, \%old_timename2info);
  if(%new_timename2info){
    if(uc $param1 eq "LAST") {
      @old_dump=keys %old_timename2info;
      foreach (@old_dump){
        if (exists $new_timename2info{$_}){
          delete $new_timename2info{$_};
        }
      }
    }
    if( %new_timename2info ){
      $ret=write_evict_log($param2, \%new_timename2info);
      if ($ret){
        Logger("Found $param2 event and wrote log successfully!\n");
      }else{
        Logger("Found $param2 event, but failed to write log!\n");
        return FALSE;
      }
    }

  }
  return TRUE;
}


#Function: event_detect()
#To detect node eviction on CHM master node from cluster alert log, if find it return dump hash list
#Global: @DB4DUMP,%DB2ALERTLOG, $ALERTLINE
#Input: NODE_EVICTION|INST_EVICTION, %new_timename2info
#Output:%new_timename@info if detect eviction or return undefine
sub event_detect(){
  if (scalar(@_) != 2){
    die("event_detect parameter error, need 3 parameters!\n");
  }
  my $param1=shift @_;
  #get reference of %new_timename2info
  my $hash_ref=shift @_;
  my @log_path;
  my @log_content;
  if ($param1 eq "NODE_EVICTION"){
    $log_path[0]=catfile( $CRS_HOME,"log",$HOST,"alert" . $HOST . ".log");
  }else{
    foreach my $db (@DB4DUMP){
      push (@log_path, $DB2ALERTLOG{$db});
    }
  }
  foreach my $tmp_log (@log_path){
    open(ALERTFILE,$tmp_log) or die ("can't find alert file $_!\nError:$!");
    @log_content=<ALERTFILE>;
    my ($dump_flag, $habit_90_flag, $evict_flag,$ipc_flag) = (FALSE,FALSE,FALSE,FALSE);
    my ($active_nodes_start, $active_nodes_end, $node_evicted, $time_evicted);
    my ($time_reconfig, $time_90, $evict_node, @tmp_arr,$tmp_key, $node_stat, $inst_stat);
    my ($db_unique_name, $active_inst_start, $active_inst_end, $inst_evicted, $time_near, $time_ipc);
    my $myinst;

    for (my $i=0;$i<=$#log_content;$i++){
      if ($param1 eq "NODE_EVICTION"){
        if ($log_content[$i] =~ /.*CSSD Reconfiguration complete. Active nodes are (.*) \./){
          if ($habit_90_flag){
            $time_reconfig = $log_content[$i-1];
            $active_nodes_end = $1;
            chomp $active_nodes_end;
            $dump_flag = TRUE;
          }else{
            $active_nodes_start=$1;
            chomp $active_nodes_start;
          }
        }elsif ($log_content[$i] =~/.*node (.*) \(\d*\) missing for 90%.*/ ){
          $habit_90_flag=TRUE;
          $time_90=$log_content[$i-1];
          $evict_node=$1;
        }elsif($log_content[$i] =~ /.*being evicted.*/){
          $time_evicted = $log_content[$i-1];
          $evict_flag=TRUE;
        }
        #if find evicted event
        if ($dump_flag){
          @tmp_arr=split (' ',(split('\.',$time_reconfig))[0]);
          $tmp_key=$tmp_arr[0] . "_" . $tmp_arr[1] . "|" . $evict_node;
          chomp $tmp_key;
          chomp $time_90;
          if ($evict_flag){
            chomp $time_evicted;
            $node_stat="NODE EVICTED";
            @tmp_arr=(
            $tmp_key . "|" . $node_stat,
            "Active CSSD nodes:" . $active_nodes_start, $time_90 . "|90% of timeout interval",
            $time_evicted . "|" . $evict_node . " is being evicted in cluster",
            "Active CSSD nodes:" . $active_nodes_end
            );
          }else{
            $node_stat="CSS EVICTED";
            @tmp_arr=(
            $tmp_key . "|" . $node_stat,
            "Active CSSD nodes:" . $active_nodes_start,
            $time_90 . "|90% of timeout interval",
            "Active CSSD nodes:" . $active_nodes_end
            );
          }
          #set value for %new_timenode2info
          $hash_ref->{$tmp_key}=[@tmp_arr];
          #clean flag value
          $active_nodes_start = $active_nodes_end;
          $dump_flag = FALSE;
          $habit_90_flag = FALSE;
          $evict_flag = FALSE;
        }
      }else{# find IPC timeout in RDBMS alert log;
        if ($log_content[$i] =~ /^[A-Z]{1}[a-z]{2} [A-Z]{1}[a-z]{2} \d{2} \d{2}:\d{2}:\d{2} \d{4}/){
          $time_near=$log_content[$i];
        #}elsif ($log_content[$i] =~ /.*db_unique_name.*= \"(.*)\"/){
        #  $db_unique_name=$1;
        }elsif($log_content[$i] =~ /(.*)\(myinst: (\d+)\)/){
          if ($ipc_flag){
            $active_inst_end = $1;
            chomp $active_inst_end;
          }else{
            $active_inst_start = $1;
            chomp $active_inst_start;
          }
          $myinst=$2;
        }elsif ($log_content[$i] =~ /^IPC Send timeout detected/){#remote instance IPC timeout
          $time_ipc = fmt_rdbms_time($time_near);
          $ipc_flag = TRUE;
        }elsif ($log_content[$i] =~ /Evicting instance (\d+) from cluster/){
          $inst_evicted = $1;
        }elsif ($log_content[$i] =~ /^Reconfiguration complete/){
          $time_reconfig = fmt_rdbms_time($time_near);
          if ($ipc_flag){
            $dump_flag = TRUE;
          }
        }elsif ($log_content[$i] =~ /Instance terminated by USER/){#local instance IPC timeout
          if ( $ipc_flag ){
            $dump_flag = TRUE;
            $time_reconfig= fmt_rdbms_time($time_near);
            $active_inst_end = $active_inst_start;
            $active_inst_end =~ s/$myinst//g;
            $inst_evicted = $myinst;
            @tmp_arr = split (' ', $active_inst_end);
            $active_inst_end = join (' ', @tmp_arr);
          }
        }
        if ($dump_flag){
          @tmp_arr = keys %INSTANCE2NODE;
          $db_unique_name = (split ('\/', $tmp_log))[-4];
          @tmp_arr = grep (/^$db_unique_name.*$inst_evicted$/, @tmp_arr);
          unless (defined $tmp_arr[0]){
            Logger("event_detect() failed to get instance name, quit!\n");
            return undef;
          }
          $tmp_key = $time_reconfig . "|" . $tmp_arr[0];
          $evict_node = (split('\|', $INSTANCE2NODE{$tmp_arr[0]}))[0];
          chomp $tmp_key;
          $node_stat = $time_reconfig . "|" . $tmp_arr[0] . "|IPC TIMEOUT";

          @tmp_arr = (
            $node_stat,
            "Active instances:" . $active_inst_start,
            $time_ipc . "|" . "IPC Send timeout detected on node " . $evict_node,
            "Active instances:" . $active_inst_end
          );
          #set value for %new_timenode2info
          $hash_ref->{$tmp_key} = [@tmp_arr];
          #clean flag for next dump
          $dump_flag = FALSE;
          $active_inst_start = $active_inst_end;
          $ipc_flag = FALSE;

        }
      }
    }
  }
}
#Function: dump_node_view()
#run 'oclumon dumpnodeview -node1 -s <timestamp> -e <timestamp> -v' to dump performance data.
#Input:$start_time,$end_time,$dump_name
#Return: Expired, Success, Failed
sub dump_node_view{
  if (scalar @_ !=3 ){
    die ("dump_node_view parameter error, need 3 parameters!\n");
  }
  my $start_time = shift @_;
  my $end_time = shift @_;
  my $dump_name = shift @_;
  my $log_file;
  my $node = (split ('_', $dump_name))[0];
  my @ret;
#  $log_file = getcwd();
  $log_file = get_output_dir();  #Rajeev

  $log_file = catfile ($log_file, "logs", $dump_name . "_" . $end_time . ".dmp");
  $start_time = join(' ',split('_',$start_time));
  $end_time = join (' ',split('_',$end_time));
  @ret = exec_OS_cmd ("$OCLUMON dumpnodeview -n $node -s \"$start_time\" -e \"$end_time\" -v>$log_file");
  if($? == 0){
    @ret = stat ($log_file);
    if ( $ret[7] == 0){
      return "Expired";
    }else{
      return "Success";
    }
  }else{
    Logger("dump_node_view failed to run oclumon to dump performance data!\nError:@ret");
    return "Failed";
  }


}


#function write_evict_log()
#According to %time_node2dump_ret, write dump log.
#input: NODE_EVICTION|INST_EVICTION, %new_timenode2info
#return:TRUE or failed
sub write_evict_log{
  my $param1 = shift @_;
  my $hash_ref = shift @_;
  my $logfile;
  my @tmp_arr;
  my $time_before;
  my $time_dump;
  my $cur_time;
  my ($start_time, $ret);
  my ($dump_name,$inst_name);
  unless ( defined $param1 || defined $hash_ref){
    die ("write_evict_log parameter error, need to two parameter!\n");
  }
  $logfile = getcwd();
  $log_file = get_output_dir();  #Rajeev
  if ( uc $param1 eq "NODE_EVICTION"){
    $logfile = catfile ($logfile, "logs","cssd_eviction.log");
    $time_before = $NODEMON_TIMESTEP;
  }elsif ( uc $param1 eq "INST_EVICTION"){
    $logfile = catfile ($logfile, "logs","instance_eviction.log");
    $time_before = $INSTMON_TIMESTEP;
  }else{
    die ("write_evict_log parameter should be NODE_EVICTION|INST_EVICTION, current value is $param1\n");
  }
  open EVICTLOG, ">>", "$logfile" or die "Fail to open the $logfile for $!\n";
  foreach my $key (sort {$a cmp $b} (keys %{$hash_ref})){
    $cur_time = get_current_time();
    print EVICTLOG $cur_time . "\n";
    print EVICTLOG "--------------------------------->\n";
    chomp @{$hash_ref->{$key}};
    foreach my $line (@{$hash_ref->{$key}}){
      print EVICTLOG "$line\n";
    }
    ($time_dump,$dump_name) = split ('\|',$key);
    $start_time = calc_starttime($time_dump, $time_before);
    unless (defined $start_time){
      Logger("write_evict_log call calc_starttime failed, quit!\n");
      return FALSE;
    }else{
      if ($param1 eq "INST_EVICTION"){
        $inst_name = $dump_name;
        $dump_name = (split ('\|',$INSTANCE2NODE{$inst_name}))[0];
        $dump_name = $dump_name . "_" . $inst_name;
      } else{
        $dump_name = $dump_name . "_" . "cssd";
      }
      $ret = dump_node_view($start_time, $time_dump, $dump_name);
      print EVICTLOG "oclumon dump performance data " . $dump_name . "_" . $time_dump . ".dmp" . "|" . $ret . "\n";
    }

    print EVICTLOG "<---------------------------------\n\n";
  }
  close EVICTLOG;
  undef %{$hash_ref};
  return TRUE;
}
#function read_evict_log()
#According evict log to initialize hash %time2node
#input:  NODE_EVICTION|INST_EVICTION,\%old_timenode2info
#output: \%old_timename2info or return undef if not have any line in evict log.
sub read_evict_log{
  if (scalar @_ != 2){
    die("read_evict_log parameter error, need 2 parameters,quit!\n");
  }
  my $param1 = shift @_;
  my $hash_ref = shift @_;
  #my $log_path = getcwd();
  my $log_path = get_output_dir(); #Rajeev
  my @log_content;
  if ( $param1 eq "NODE_EVICTION"){
    $log_path = catfile ($log_path, "logs", "cssd_eviction.log");
  }else{
    $log_path = catfile ($log_path, "logs", "instance_eviction.log");
  }
  if ( -e $log_path){
    open EVICTLOG, "<", "$log_path";
    @log_content = <EVICTLOG>;
    close EVICTLOG;
    my ($time,$node);
    for (my $i=0;$i<=$#log_content;$i++){
      if ($log_content[$i] =~/\-*\>/){
        $time = (split('\|',$log_content[$i+1]))[0];
        $node = (split('\|',$log_content[$i+1]))[1];
        $time = $time . "|" . $node;
        $hash_ref->{$time} = "Dumped";
      }
    }
  }else{
    undef %{$hash_ref};
  }
}

#function calc_starttime()
#According evict log to initialize hash %time2node
#input: $endtime, $timestep
#output:$starttime, return undefine if fail
sub calc_starttime{
  my $endtime= shift @_;
  my $time_before = shift @_;
  my @tmp_time;
  my ($time, $starttime);
  unless (defined $endtime || defined $time_before){
    die ("calc_starttime parameter error, need parameter \$endtime and \$time_before!\n");
  }
  chomp $endtime;
  if ( $endtime =~ /([\d]{4})-([\d]{2})-([\d]{2})_([\d]{2}):([\d]{2}):([\d]{2})/){
    @tmp_time=($6,$5,$4,$3,$2-1,$1);
    $time = timelocal ( @tmp_time );
    $time = $time - $time_before;
    @tmp_time = localtime ($time);
    $tmp_time[4] = $tmp_time[4] + 1;
    $tmp_time[5] = $tmp_time[5] + 1900;
    for (my $i=0; $i<$#tmp_time; $i++){
      if ($tmp_time[$i] < 10){
        $tmp_time[$i] = "0" . $tmp_time[$i];
      }
    }
    $starttime = $tmp_time[5] . "-" . $tmp_time[4] . "-" . $tmp_time[3] . "_" .
                  $tmp_time[2] . ":" . $tmp_time[1] . ":" . $tmp_time[0];
  }else{
    return undef;
  }
  return $starttime;
}


#function fmt_rdbms_time()
#Format timestamp in RDBMS alert log
#Input:$str like Thu Feb 09 13:00:34 2012
#output:$ret like 2012-02-09_13:00:34, or return undef if failed
sub fmt_rdbms_time(){
  my $str=shift @_;
  my @tmp_arr;
  my %month2num=(
                   'Jan' => '01',
                   'Feb' => '02',
                   'Mar' => '03',
                   'Apr' => '04',
                   'May' => '05',
                   'Jun' => '06',
                   'Jul' => '07',
                   'Aug' => '08',
                   'Sep' => '09',
                   'Oct' => '10',
                   'Nov' => '11',
                   'Dec' => '12'
                  );
  if (defined $str){
    chomp $str;
    @tmp_arr = split(' ', $str);
    unless ( exists $month2num{$tmp_arr[1]}){
      return undef;
    }
    $ret = $tmp_arr[4] . "-" . $month2num{$tmp_arr[1]} . "-" . $tmp_arr[2] . "_" . $tmp_arr[3];
  }else{
    return undef;
  }
  return $ret;
}
#function init_instance2node()
#Initialize hash var %instance2node
#Input: \%instance2node
#output: TRUE, or undef if failed
sub init_instance2node{
  my $hash_ref = shift @_;
  my (@tmp_arr, @db_lst);
  my ($stat,$node,$inst);
  @db_lst=exec_OS_cmd("$SRVCTL config");
  chomp @db_lst;
  foreach (@db_lst){
    @tmp_arr=exec_OS_cmd("$SRVCTL status db -d $_");
    chomp @tmp_arr;
    foreach my $line (@tmp_arr){
      if ($line =~ /Instance (.*) is (.*) on node (.*)/ ){
        $stat = $2;
        chomp $stat;
        $inst = $1;
        $node = $3;
        chomp $inst;
        chomp $node;
        if ($stat =~ "not.*"){
          $stat= "offline";
        }else{
          $stat = "online";
        }
        $hash_ref->{$inst} = $node . "|" . $stat;
      }else{
        Logger("init_instance2node failed to get instance and node name.\nError:@tmp_arr\n");
        return undef;
      }
    }
  }
  return TRUE;
}

#function isCheckInstEvict()
#If all rdbms instaces are offline on this node, will return FALSE
#If any rdbms instance is online and this node is CHM master node or
#online instance number is the first then return TRUE
#Input: \@DB4DUMP
#Return: TRUE, yes need to check, False, no need.
sub isCheckInstEvict{
  if(scalar @_ !=1 ){
    die ("isCheckInstEvict parameter error, need 1 parameter!\n");
  }
  my $db_arr_ref = shift @_;
  #get all instances status
  my @db_lst= exec_OS_cmd ("$SRVCTL config db");
  chomp @db_lst;
  my (@inst_lst, @arr_tmp);
  my ($inst,$stat,$node, $tmp, @arr_tmp2);
  #build dbname|instname|online/offline|node list @inst_lst for all database.
  foreach my $db (@db_lst){
    @arr_tmp= exec_OS_cmd("$SRVCTL status db -d $db");
    foreach my $line (@arr_tmp){
      if ($line =~ /Instance (.*) is (.*) on node (.*)/){
        $inst = $1;
        $stat = $2;
        $node = $3;
        if ($stat =~ /not .*/){
          $stat = "offline";
        }else{
          $stat = "online";
        }
        $tmp = $db . "|" . $inst . "|" . $stat . "|" . $node;
        push @inst_lst, $tmp;
      }
    }
  }
  undef @db_lst;
  my $master = check_chm_master;
  my $dbname;
  #if loal host is CHM master, then get online database name.
  if ( uc $master eq uc $HOST){
    @arr_tmp = grep (/$master/, @inst_lst);
    @arr_tmp = grep (/online/, @arr_tmp);
    #build online db list on CHM master node.
    foreach (@arr_tmp){
      $dbname = (split('\|', $_))[0];
      push @db_lst, $dbname;
    }
  }else{
    @arr_tmp = grep (/$master/, @inst_lst);
    @arr_tmp = grep (/offline/, @arr_tmp);
    #build offline db list on non-CHM-master node.
    foreach (@arr_tmp){
      $dbname = (split('\|', $_))[0];
      push @arr_tmp2, $dbname;
    }

    #build online db list on non-CHM-master node from offline db list on CHM master node.
    foreach my $db (@arr_tmp2){
      @arr_tmp = grep (/$db/, @inst_lst);
      @arr_tmp = grep (/online/, @arr_tmp);
      if ( defined $arr_tmp[0] ){
        #get the 1st node from $db online nodes, usually it shoud be samll number node.
        $dbname = (split('\|', $arr_tmp[0]))[0];
        $node = (split('\|', $arr_tmp[0]))[-1];
        if (uc $node eq uc $HOST){
          push @db_lst, $dbname;
        }
      }
    }
  }

  #if found some db will be detected for IPC timeout.
  undef @{$db_arr_ref};
  my ($hash_ref, $path, $file);
  foreach my $db (@db_lst){
    unless (exists $DB2ALERTLOG{$db}){
      $hash_ref = get_DB_log_dest($db);
      $path = $hash_ref->{'background_dump'};
      $inst = (split ('\/',$path))[-2];
      $file = "alert" . "_" . $inst . ".log";
      $path = catfile ($path, $file);
      $DB2ALERTLOG{$db} = $path;
    }

    push @{$db_arr_ref}, $db;
  }

  if (@{$db_arr_ref}) {
    return TRUE ;
  } else {
    return FALSE ;
  }
}






sub read_file {
  my ($filename) = @_ ;

  open my $in, '<:encoding(UTF-8)', $filename or die "Could not open '$filename' for reading $!" ;
  local $/ = undef ;
  my $all = <$in> ;
  close $in ;

  return $all ;
}

sub write_file {
  my ($filename, $content) = @_ ;

  open my $out, '>:encoding(UTF-8)', $filename or die "Could not open '$filename' for writing $!" ;
  print $out $content ;
  close $out ;

  return ;
}

sub append_file {
  my ($filename, $content) = @_ ;

  open my $out, '>>:encoding(UTF-8)', $filename or die "Could not open '$filename' for appending $!" ;
  print $out $content ;
  close $out ;

  return ;
}



1;
__END__
