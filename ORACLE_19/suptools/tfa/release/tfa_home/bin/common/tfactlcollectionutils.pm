#
# $Header: tfa/src/v2/tfa_home/bin/common/tfactlcollectionutils.pm /main/20 2018/05/28 15:06:27 bburton Exp $
#
# tfactlcollectionutils.pm
#
# Copyright (c) 2017, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlcollectionutils.pm - Summary Utility Methods
#
#    DESCRIPTION
#      This module includes utility methods used in summary collection
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    04/23/18 - Bug 27366222 - TFACTL SUMMARY HANGS IN EXADATA
#    migmoren    04/19/18 - Bug 26984470 - SOLSP-18.1-TFA:TFACTL SUMMARY EXIT
#                           WHEN COLLECTING OS DETAILS
#    migmoren    03/16/18 - Bug 27680284 - AIX-181-TFA:"TFACTL RUN SUMMARY"
#                           EXIT ABRUPTLY DURING "COLLECTING DATABASE
#    recornej    01/26/18 - Check if ASM instance is actually running
#    cnagur      10/31/17 - Fix for Bug 27003629
#    bibsahoo    10/09/17 - FIX BUG 26860487
#    cnagur      10/31/17 - Fix for Bug 27003629
#    bibsahoo    10/04/17 - FIX BUG 26841285
#    bibsahoo    09/26/17 - FIX BUG 26845295
#    bibsahoo    09/07/17 - FIX BUG 26517814
#    bibsahoo    07/19/17 - FIX BUG 26329776
#    bibsahoo    07/10/17 - FIX BUG 26414175
#    bibsahoo    05/30/17 - tfa_windows_fix
#    bibsahoo    05/24/17 - FIX BUG 26127514
#    cpujar      05/23/17 - XbranchMerge cpujar_bug-26117592 from
#                           st_tfa_12.2.1.1.01
#    cpujar      05/22/17 - Summary bug 26117592 
#    bibsahoo    05/19/17 - FIX BUG 26107085
#    cpujar      05/17/17 - Summary bug 26090405
#    cpujar      05/19/17 - XbranchMerge cpujar_bug-26090405 from
#                           st_tfa_12.2.1.1.01
#    bburton     05/08/17 - do not try to run sql when correct env is not set
#    cpujar      05/03/17 - Handle Database Not running cases
#    bibsahoo    04/25/17 - FIX BUG 25950217 - TFACTL SUMMARY FAILING WITH
#                           UNEXPECTED ERRORS
#    cpujar      04/13/17 - Updated summary modules
#    bibsahoo    04/13/17 - Creation
#
#!/usr/bin/perl
package tfactlcollectionutils;
use strict;

#use warnings;
use English;
use File::Basename;
use File::Spec::Functions;
use File::Copy;
use File::Find;
use Time::Local;
use Term::ANSIColor;
use Cwd;
use POSIX;
use Sys::Hostname;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin);
use Cwd qw(realpath abs_path);
use lib realpath("$Bin");
use File::Path qw(mkpath rmtree);
use tfactlglobal;
use tfactlshare;
use tfactlstore;
use tfactlwin;
use dbutil;
use cmdlocation;
use osutils;


BEGIN
{
  use Exporter();
  our ( @ISA, @EXPORT );
  @ISA = qw(Exporter);
  my @exp_func = qw(collectionutil_get_system_date
    collectionutil_get_crs_home
    collectionutil_get_crs_version
    collectionutil_check_crs_state
    collectionutil_get_crs_server_status
    collectionutil_check_crs_integrity
    collectionutil_get_crs_resource_details
    collectionutil_get_crs_user
    collectionutil_get_asm_home
    collectionutil_get_asm_instance
    collectionutil_get_asm_version
    collectionutil_get_asm_status
    collectionutil_get_asm_instance_files
    collectionutil_get_asmdiskgroup_view
    collectionutil_get_asmdiskvolumes_view
    collectionutil_check_asm_hanganalyze
    collectionutil_get_asm_diag_trace_folder
    collectionutil_is_DB_installed
    collectionutil_getRunningDBsDetails
    collectionutil_get_db_diag_trace_folder
    collectionutil_get_db_banner
    collectionutil_get_db_nls_character_set
    collectionutil_get_db_sga
    collectionutil_get_db_instances
    collectionutil_get_db_parameter_instances
    collectionutil_get_db_active_instances
    collectionutil_get_db_instance_details
    collectionutil_get_db_account_status
    collectionutil_get_db_components_version
    collectionutil_get_db_datafiles_details
    collectionutil_get_db_tablespaces
    collectionutil_get_db_invalid_objects
    collectionutil_get_db_groups_status
    collectionutil_get_db_files
    collectionutil_check_db_hanganalyze
    collectionutil_check_system_events
    collectionutil_process_db_stats
    collectionutil_process_sql_stat
    collectionutil_process_sql_monitor
    collectionutil_get_serverpool_details
    collectionutil_get_db_stats
    collectionutil_get_rman_stats
    collectionutil_get_pdbs_stats
    collectionutil_get_os_details
    collectionutil_get_oracle_release
    collectionutil_get_redhat_release
    collectionutil_get_cpu_details
    collectionutil_get_sleeping_tasks
    collectionutil_get_top
    collectionutil_get_fdisk_details
    collectionutil_get_listener_details
    collectionutil_check_service_registered
    collectionutil_check_tns_status
    collectionutil_get_interface_details
    collectionutil_get_cluvfy_details
    collectionutil_get_ocrcheck_details
    collectionutil_opatch_details
    collectionutil_opatch_product_details
    collectionutil_get_events
    collectionutil_SortByDirectory
    collectionutil_SortByExtension
    collectionutil_SortByComponent
    collectionutil_getExtension
    collectionutil_parseXMLCollection
    collectionutil_getCollectionName
    collectionutil_getTFAVersion
    collectionutil_getTFABuildID
    collectionutil_getComponentsCollected
    collectionutil_getCollDuration
    collectionutil_getZipSize
    collectionutil_getDiagnosticsDuration
    collectionutil_is_acfs_configured
    collectionutil_get_acfs_info
    collectionutil_get_acfs_volume_info
    collectionutil_get_asm_acfs_volume_sql
    collectionutil_get_acfs_filesystem_sql
    collectionutil_get_asm_volume_sql
    collectionutil_get_asm_volume_stat_sql
    collectionutil_get_tfa_status
    collectionutil_get_tfa_directories
    collectionutil_get_tfa_repository
    collectionutil_get_tfa_config
    collectionutil_get_hardware_model_exadata
    collectionutil_get_cell_names
    collectionutil_get_cell_status
    collectionutil_get_cell_lun_status
    collectionutil_get_cell_grid_disk_status
    collectionutil_get_iostat_details
    collectionutil_get_infiband_switches
    collectionutil_get_ibsw_linker
    collectionutil_get_ibsw_env_test
    collectionutil_get_ibsw_priority_master
    configure_ssh
    getCommandLocation
    generateKeys
    configureSSH
    get_usern
  );
  push @EXPORT, @exp_func;
}
my $tfa_home = catdir( dirname($PROGRAM_NAME), ".." );
my $WIN_TRANSFER_DIR = catfile( "C:", "transfer" );
my $PLATFORM         = $^O;
my $IS_WIN           = 0;
if ( $PLATFORM eq "MSWin32" )
{
  $IS_WIN = 1;
}
my $SEP = "_|SEP|_";
##=============== CRS FUNCTIONS =====================================================
sub collectionutil_get_crs_home
{
  my $crs_home = "";
  open( RF, catfile( $tfa_home, "tfa_setup.txt" ) ) || die "Cant open " . catfile( $tfa_home, "tfa_setup.txt" ) . "\n";
  while (<RF>)
  {
    chomp;
    if (/^CRS_HOME=(.*)/)
    {
      $crs_home = $1;
      last;
    }
  }
  close(RF);
  tfactlstore_summary_log( "CRS HOME: $crs_home", "collectionutil_get_crs_home" );
  return $crs_home;
}

sub getCRSResourceNames
{
  my $RAT_CRS_HOME = collectionutil_get_crs_home();
  my $resourceList = "";
  my $loc;
  tfactlstore_summary_log( "crs status resource", "collectionutils_getCRSResourceNames" );
  if ($RAT_CRS_HOME)
  {
    if ($IS_WIN)
    {
      $loc = catfile( $RAT_CRS_HOME, "bin", "crsctl.exe" );
    } else
    {
      $loc = catfile( $RAT_CRS_HOME, "bin", "crsctl" );
    }
     
    my $text = `$loc status resource`;
    foreach my $line ( split /\n/, $text )
    {
      if ( $line =~ /^NAME=(.*)/ )
      {
        $resourceList = $resourceList . $1 . " ";
      }
    }
  }
  return $resourceList;
}

sub collectionutil_get_crs_resource_details
{
  my $resourceList = shift;
  if ( !$resourceList )
  {
    $resourceList = getCRSResourceNames();
  }
  my $RAT_CRS_HOME = collectionutil_get_crs_home();
  my %resourcesDetails;
  my $cmd;
  my $loc;
  my $text;
  my $retText;
  if ($RAT_CRS_HOME)
  {

    foreach my $resource ( split /\s/, $resourceList )
    {
      if ($IS_WIN)
      {
        $loc = catfile( $RAT_CRS_HOME, "bin", "crsctl.exe" );
      } else
      {
        $loc = catfile( $RAT_CRS_HOME, "bin", "crsctl" );
      }
      $cmd = "$loc status resource $resource -f";

      tfactlstore_summary_log( "command - $cmd", "collectionutil_get_crs_resource_details" );
      $text = `$cmd`;

      #print "details: $text\n";
      $retText = "";
      foreach my $line ( split /\n/, $text )
      {
        if ( $line =~ /^(TYPE|STATE|TARGET|LOGGING_LEVEL|NLS_LANG|START_DEPENDENCIES|STOP_DEPENDENCIES|VERSION|SCAN_NAME|START_TIMEOUT|STOP_TIMEOUT|USR_ORA_VIP|DESCRIPTION)=/)
        {
          $retText = $retText . $line . "\n";
        }
      }
      if ( !$resourcesDetails{$resource} )
      {
        $resourcesDetails{$resource} = $retText;
      }
    }
  }
  return %resourcesDetails;
}

sub collectionutil_check_crs_state
{
  my $printFlag = shift;
  my $loc;
  my $RAT_CRS_HOME = collectionutil_get_crs_home();
  if ($RAT_CRS_HOME)
  {
    if ($IS_WIN)
    {
      $loc = catfile( $RAT_CRS_HOME, "bin", "crsctl.exe" );
    } else
    {
      $loc = catfile( $RAT_CRS_HOME, "bin", "crsctl" );
    }

    tfactlstore_summary_log( "command - $loc check crs", "collectionutil_check_crs_state" );
    my $text = `$loc check crs`;
    if ($printFlag)
    {
      my $retStr = "";
      if ( $text =~ /Oracle High Availability Services/ && $text =~ /online/ )
      {
        $retStr = $retStr . "Oracle High Availability Services:Online\n";
      } else
      {
        $retStr = $retStr . "Oracle High Availability Services:Offline\n";
      }
      if ( $text =~ /Cluster Ready Services/ && $text =~ /online/ )
      {
        $retStr = $retStr . "Cluster Ready Services:Online\n";
      } else
      {
        $retStr = $retStr . "Cluster Ready Services:Offline\n";
      }
      if ( $text =~ /Cluster Synchronization Services/ && $text =~ /online/ )
      {
        $retStr = $retStr . "Cluster Synchronization Services:Online\n";
      } else
      {
        $retStr = $retStr . "Cluster Synchronization Services:Offline\n";
      }
      if ( $text =~ /Event Manager/ && $text =~ /online/ )
      {
        $retStr = $retStr . "Event Manager:Online\n";
      } else
      {
        $retStr = $retStr . "Event Manager:Offline\n";
      }
      return $retStr;
    }
    my @arrtemp = split /\n/, $text;
    my $count = 0;
    foreach my $x (@arrtemp)
    {
      if ( $x =~ /online/ )
      {
        $count++;
      } elsif ( $x =~ /failure/ || $x =~ /Cannot/ )
      {
        return 0;
      }
    }
    if ( $count >= 4 )
    {
      return 1;
    }
  } else
  {
    return 0;
  }
}

sub collectionutil_get_crs_server_status
{
  my $RAT_CRS_HOME = collectionutil_get_crs_home();
  my $host         = tolower_host();
  my %server_stat;
  my $loc;
  if ($RAT_CRS_HOME)
  {
    if ($IS_WIN)
    {
      $loc = catfile( $RAT_CRS_HOME, "bin", "crsctl.exe" );
    } else
    {
      $loc = catfile( $RAT_CRS_HOME, "bin", "crsctl" );
    }

    tfactlstore_summary_log( "command - $loc status server $host", "collectionutil_get_crs_server_status" );
    my $str = `$loc status server $host`;
    foreach my $line ( split /\n\n/, $str )
    {
      if ( $line =~ /NAME=(.*)\nSTATE=(.*)/ )
      {
        $server_stat{$1} = $2;
      }
    }
  }
  return %server_stat;
}

sub get_crs_version_number
{
  my $crshome = collectionutil_get_crs_home();
  if ( $crshome =~ /12\.1/ )
  {
    return 121;
  } elsif ( $crshome =~ /12\.2/ )
  {
    return 122;
  } elsif ( $crshome =~ /11\.2/ )
  {
    return 112;
  }
}

sub collectionutil_get_crs_version
{
  my $host    = tolower_host();
  my $pattern = $host . "%" . "CRS_ACTIVE_VERSION";
  open( RF, catfile( $tfa_home, "tfa_setup.txt" ) ) || die "Cant open " . catfile( $tfa_home, "tfa_setup.txt" ) . "\n";
  my $crs_version;
  while (<RF>)
  {
    chomp;
    if (/^$pattern=(.*)/)
    {
      $crs_version = $1;
      last;
    }
  }
  close(RF);
  return $crs_version;
}

sub collectionutil_check_crs_integrity
{
  my %crs_integrity;
  my $MASTER_NODE = tolower_host();
  my $OH          = collectionutil_get_crs_home();
  my $crsow;
  my $gpnp_integrity;
  my $asm_integrity;
  my $crs_integrity;
  my $clu_integrity;

  if ($IS_WIN)
  {
    # TODO: Write windows specfic code
  } else
  {
    tfactlstore_summary_log( "command - $OH/bin/cluvfy", "collectionutil_check_crs_integrity" );
    $crsow = `ps -ef|grep asm_pmon| grep -v grep |awk {'print \$1'}`;
    chomp($crsow);
    my $cmd = "su $crsow -c \"$OH/bin/cluvfy comp gpnp -n $MASTER_NODE\"";
    $gpnp_integrity = `$cmd`;
    $asm_integrity  = ` su $crsow -c "$OH/bin/cluvfy comp asm -n $MASTER_NODE" `;
    $crs_integrity  = ` su $crsow -c "$OH/bin/cluvfy comp crs -n $MASTER_NODE" `;
    $clu_integrity  = `  su $crsow -c "$OH/bin/cluvfy comp clu -n $MASTER_NODE" `;
  }
  if ( is_key_present( $gpnp_integrity, "Verification of GPNP integrity was successful." ) == 1 )
  {
    $crs_integrity{"gpnp"} = "PASS";
  } else
  {
    $crs_integrity{"gpnp"} = "FAIL";
  }
  if ( is_key_present( $asm_integrity, "Verification of ASM Integrity was successful." ) == 1 )
  {
    $crs_integrity{"asm"} = "PASS";
  } else
  {
    $crs_integrity{"asm"} = "FAIL";
  }
  if ( is_key_present( $crs_integrity, "Verification of CRS integrity was successful." ) == 1 )
  {
    $crs_integrity{"crs"} = "PASS";
  } else
  {
    $crs_integrity{"crs"} = "FAIL";
  }
  if ( is_key_present( $clu_integrity, "Verification of cluster integrity was successful." ) == 1 )
  {
    $crs_integrity{"cluster"} = "PASS";
  } else
  {
    $crs_integrity{"clusterd"} = "FAIL";
  }
  return %crs_integrity;
}

sub collectionutil_get_crs_user
{
  my $ora_inst_loc;
  my $crs_home = collectionutil_get_crs_home();
  my $crs_user = "";
  if ($IS_WIN)
  {
  } else
  {
    $ora_inst_loc = catfile( $crs_home, "oraInst.loc" );
    my $cmd = "ls -l $ora_inst_loc | awk {'print \$3'}";

    tfactlstore_summary_log( "command - $cmd", "collectionutil_get_crs_user" );
    $crs_user = `$cmd`;
  }
  $crs_user =~ s/^\n{1,}|\n{1,}$//g;
  return $crs_user;
}
##=============== CRS FUNCTIONS =====================================================

##=============== ASM FUNCTIONS =====================================================
sub collectionutil_get_asm_home
{
  my $crs_version = get_crs_version_number();
  my $asm_home;

  ## FIND ASM HOME LOCATION FROM TFA_SETUP.TXT
  open( RF, catfile( $tfa_home, "tfa_setup.txt" ) )
    || die "Cant open " . catfile( $tfa_home, "tfa_setup.txt" ) . "\n";
  while (<RF>)
  {
    chomp;
    if (/^ASM_HOME=(.*)/)
    {
      $asm_home = $1;
      last;
    }
  }
  close(RF);  

  ## IF ASM HOME IS NULL IN TFA_SETUP, ASSIGN ASM HOME AS CRS HOME
  my $crs_home = collectionutil_get_crs_home();
  if (!$asm_home && $crs_home && -d $crs_home) {
    $asm_home = $crs_home;
  }

  tfactlstore_summary_log( "ASM HOME: $asm_home", "collectionutil_get_asm_home" );
  return $asm_home;
}

sub collectionutil_get_asm_instance
{
  my $host = tolower_host();
  my $asm_instance;
  my $pattern_found_flag = 0;
  open( RF, catfile( $tfa_home, "tfa_setup.txt" ) ) || die "Cant open " . catfile( $tfa_home, "tfa_setup.txt" ) . "\n";
  my $pattern = $host . "%ASM_INSTANCE";
  while (<RF>)
  {
    chomp;
    if (/^$pattern=(.*)/)
    {
      $asm_instance       = $1;
      $pattern_found_flag = 1;
      last;
    }
  }
  close(RF);
  if ( $pattern_found_flag == 1 )
  {

    my $running;
    if ( ! $IS_WIN) {
      $running = `$PS -fea | $GREP pmon_$asm_instance | $GREP -v grep`;
      chomp($running);
    } else {
      $running = (dbutil_iswindbrunning($asm_instance))[1];
    }
    if ( $running ) {
      return $asm_instance;
    } else {
      return "";
    }
  } else
  {
    my $crs_state = collectionutil_check_crs_state();
    my $cmd;
    if ( $crs_state == 1 )
    {
      my $crs_home = collectionutil_get_crs_home();
      if ($IS_WIN)
      {
        $cmd = catfile( $crs_home, "bin", "crsctl.exe" ) . " stat res ora.asm -f";
      } else
      {
        $cmd = catfile( $crs_home, "bin", "crsctl" ) . " stat res ora.asm -f";
      }
    }
    tfactlstore_summary_log( "command - $cmd", "collectionutil_get_asm_instance" );
    my $asm_resource_status = `$cmd`;
    foreach my $line ( split /\n/, $asm_resource_status )
    {
      if ( $line =~ /^GEN_USR_ORA_INST_NAME/ && $line =~ /$host/ )
      {
        my @tmp = split /=/, $line;
        my $running;
        if ( ! $IS_WIN ) {
          $running = `$PS -fea | $GREP pmon_$tmp[1] | $GREP -v grep`;
          chomp($running);
        } else {
          $running = (dbutil_iswindbrunning($tmp[1]))[1];
        }
       if ( $running ) {
          return $tmp[1];
        } else {
          return "";
        }
      }
    }
  }
}

sub collectionutil_get_asm_version
{
  my $host               = tolower_host();
  my $asm_instance       = collectionutil_get_asm_instance();
  my $pattern            = $host . "%" . $asm_instance . "%VERSION";
  my $pattern_found_flag = 0;
  open( RF, catfile( $tfa_home, "tfa_setup.txt" ) ) || die "Cant open " . catfile( $tfa_home, "tfa_setup.txt" ) . "\n";
  my $asm_version;
  while (<RF>)
  {
    chomp;
    if (/^$pattern=(.*)/)
    {
      $asm_version        = $1;
      $pattern_found_flag = 1;
      last;
    }
  }
  close(RF);
  if ( $pattern_found_flag == 1 )
  {
    return $asm_version;
  } else
  {
    my $crs_state = collectionutil_check_crs_state();
    my $cmd;
    if ( $crs_state == 1 )
    {
      my $crs_home = collectionutil_get_crs_home();
      if ($IS_WIN)
      {
        $cmd = catfile( $crs_home, "bin", "crsctl.exe" ) . " stat res ora.asm -f";
      } else
      {
        $cmd = catfile( $crs_home, "bin", "crsctl" ) . " stat res ora.asm -f";
      }
    }
    tfactlstore_summary_log( "command - $cmd", "collectionutil_get_asm_version" );
    my $asm_resource_status = `$cmd`;
    foreach my $line ( split /\n/, $asm_resource_status )
    {
      if ( $line =~ /^VERSION=(.*)/ )
      {
        return $1;
      }
    }
  }
}

sub collectionutil_get_asm_status
{
  my $host               = tolower_host();
  my $pattern            = $host . "%ASM_STATUS";
  my $pattern_found_flag = 0;
  open( RF, catfile( $tfa_home, "tfa_setup.txt" ) ) || die "Cant open " . catfile( $tfa_home, "tfa_setup.txt" ) . "\n";
  my $asm_status;
  while (<RF>)
  {
    chomp;
    if (/^$pattern=(.*)/)
    {
      $asm_status         = $1;
      $pattern_found_flag = 1;
      last;
    }
  }
  close(RF);
  if ( $pattern_found_flag == 1 )
  {
    if ($asm_status)
    {
      return $asm_status;
    } else
    {
      return 0;
    }
  } else
  {
    my $crs_state = collectionutil_check_crs_state();
    my $cmd;
    if ( $crs_state == 1 )
    {
      my $crs_home = collectionutil_get_crs_home();
      if ($IS_WIN)
      {
        $cmd = catfile( $crs_home, "bin", "crsctl.exe" ) . " stat res ora.asm -f";
      } else
      {
        $cmd = catfile( $crs_home, "bin", "crsctl" ) . " stat res ora.asm -f";
      }
    
      tfactlstore_summary_log( "command - $cmd", "collectionutil_get_asm_status" );

      my $asm_resource_status = `$cmd`;
      foreach my $line ( split /\n/, $asm_resource_status )
      {
        if ( $line =~ /^STATE=(.*)/ )
        {
          if ( $1 =~ /ONLINE/ )
          {
            return 1;
          } else
          {
            return 0;
          }
        }
      }
    } else {
      return 0;
    }
  }
}

sub collectionutil_get_asm_instance_files
{
  my $asm_home = collectionutil_get_asm_home();
  my $asm_sid  = collectionutil_get_asm_instance();
  my $asm_instance_files = "";
  if ( -d $asm_home && length $asm_sid ) {
    $asm_instance_files = run_a_sql(
    $asm_home,
    $asm_sid,
"set feedback  off heading off lines 120\nselect group_number||':'||file_number||':'||compound_index||':'||incarnation||':'||block_size||':'||bytes||':'||type||':'||striped||':'||creation_date||':'||modification_date from v\$asm_file where TYPE != 'ARCHIVELOG';\nquit\n","sysasm"
  );
  }
  return $asm_instance_files;
}

sub collectionutil_get_asmdiskgroup_view
{
  my $asm_home = collectionutil_get_asm_home();
  my $asm_sid  = collectionutil_get_asm_instance();
  my $asm_asmdiskgroup_view = "";
  if ( -d $asm_home && length $asm_sid ) {
    $asm_asmdiskgroup_view = run_a_sql(
    $asm_home,
    $asm_sid,
"set feedback  off heading off lines 120\nselect group_number||':'||name||':'||allocation_unit_size||':'||state||':'||type||':'||total_mb||':'||usable_file_mb from v\$asm_diskgroup;\nquit\n","sysasm"
  );
  }
  return $asm_asmdiskgroup_view;
}

sub collectionutil_get_asmdiskvolumes_view
{
  my $asm_home = collectionutil_get_asm_home();
  my $asm_sid  = collectionutil_get_asm_instance();
  my $asm_asmdiskvolumes_view = "";
  if ( -d $asm_home && length $asm_sid ) {
    $asm_asmdiskvolumes_view = run_a_sql(
    $asm_home,
    $asm_sid,
"set feedback  off heading off lines 120\nselect name||':'||path||':'||header_status||':'||total_mb||':'||free_mb||':'||bytes_read||':'||bytes_written from v\$asm_disk;\nquit\n","sysasm"
  );
  }
  return $asm_asmdiskvolumes_view;
}

sub collectionutil_check_asm_hanganalyze
{
  tfactlstore_summary_log( "ASM HangAnalyze Started...", "collectionutil_check_asm_hanganalyze" );
  my $asm_home = collectionutil_get_asm_home();
  my $asm_sid  = collectionutil_get_asm_instance();
  my $str = "";
  my %retHash;
  if ( -d $asm_home && length $asm_sid ) {
    $str = run_a_sql(
    $asm_home,
    $asm_sid,
"set feedback  off heading off lines 120\noradebug setmypid\noradebug dump hanganalyze 2\noradebug tracefile_name\nquit\n","sysasm"
  );
  my @tmp = split /\n/, $str;
  my $asm_trace_file = $tmp[2];

  tfactlstore_summary_log( "ASM Trace File: $asm_trace_file", "collectionutil_check_asm_hanganalyze" );
  my @asm_trace_file_contents = readFileToArray($asm_trace_file);
  my @trimmed_contents        = ();
  my $pushFlag                = 0;
  foreach my $line (@asm_trace_file_contents)
  {
    if ( $line =~ /END OF HANG ANALYSIS/ )
    {
      $pushFlag = 0;
    }
    if ( $pushFlag == 1 )
    {
      push @trimmed_contents, $line;
    }
    if ( $line =~ /HANG ANALYSIS:/ )
    {
      $pushFlag = 1;
    }
  }

  my $no_chain          = 0;
  my @chain_description = ();
  my $blocked           = 0;
  my @waiting           = ();
  for ( my $i = 0 ; $i <= $#trimmed_contents ; )
  {
    my $line = $trimmed_contents[$i];
    chomp($line);
    if ( $line =~ /no chains found/ )
    {
      $no_chain = 1;
    }
    if ( $line =~ /is blocked by/ )
    {
      $blocked = 1;
    }
    if ( $line =~ /waiting for/ )
    {
      $line =~ s/(which is waiting for|is waiting for)//g;
      $line =~ s/with wait info://g;
      push @waiting, $line;
      @waiting = array_uniq_elem(@waiting);
    }
    if (    $line =~ /={3,}/
         && $trimmed_contents[ $i + 1 ] =~ /Sessions in an involuntary wait or not in a wait:/ )
    {
      my $j;
      my %tmp;
      for ( $j = $i + 2 ; $j <= $#trimmed_contents ; $j++ )
      {
        if (    $trimmed_contents[$j] =~ /-{3,}/
             && $trimmed_contents[ $j + 1 ] =~ /Chain (.*):/
             && $trimmed_contents[ $j + 2 ] =~ /-{3,}/ )
        {
          my $k   = $j + 3;
          my $str = "";
          while ( $k <= $#trimmed_contents && $trimmed_contents[$k] !~ /-{3,}/ )
          {
            $str .= $trimmed_contents[$k] . "\n";
            $k = $k + 1;
          }
          push @chain_description, $trimmed_contents[ $j + 1 ] . "\n" . $str;
          $j = $k;
        } elsif ( $trimmed_contents[$j] =~ /={3,}/ )
        {
          last;
        }
      }
      $i = $j;
    }
    $i = $i + 1;
  }
  $retHash{'TRACE_FILE_LOCATION'} = $asm_trace_file;
  if ( $no_chain > 0 )
  {
    $retHash{"no_chain"} = "PASS";
  } else
  {
    $retHash{"no_chain"} = "FAIL";
  }
  if ( $blocked == 0 )
  {
    $retHash{"blocked"} = "PASS";
  } else
  {
    $retHash{"blocked"} = "FAIL";
  }
  $retHash{"#CHAINS"} = $#chain_description + 1;
  my @chain_details = ();
  foreach my $chain_desc (@chain_description)
  {
    my %tmp;
    if ( ( split /\n/, $chain_desc )[0] =~ /Chain (.*):/ )
    {
      $tmp{'CHAIN_ID'} = $1;

      #print "CHAIN_ID: $1\n";
    }
    foreach my $line ( split /\n/, $chain_desc )
    {
      if ( $line =~ /process id:\s(.*)/ )
      {
        $tmp{'PID'} = $1;

        #print "PID: $1\n";
      } elsif ( $line =~ /1.\s{1,}event:\s(.*)/ )
      {
        $tmp{'EVENT'} = $1;

        #print "EVENT: $1\n";
      }
    }
    push @chain_details, \%tmp;
  }
  $retHash{'CHAIN_DETAILS'} = \@chain_details;
  $retHash{"waiting"}       = \@waiting;
  tfactlstore_summary_log( "ASM HangAnalyze Completed...\n", "collectionutil_check_asm_hanganalyze" );
  }
  return \%retHash;
}

sub collectionutil_get_asm_diag_trace_folder
{
  my $asm_home              = collectionutil_get_asm_home();
  my $asm_sid               = collectionutil_get_asm_instance();
  my $asm_diag_trace_folder = run_a_sql( $asm_home, $asm_sid,
         "set feedback  off heading off lines 120\nselect value from v\$diag_info where name = 'Diag Trace';\nquit\n","sysasm" );
  chomp($asm_diag_trace_folder);
  $asm_diag_trace_folder =~ s/^\n//g;
  return $asm_diag_trace_folder;
}

sub get_asm_alerts
{
  my $asm_sid  = collectionutil_get_asm_instance();
  my $asm_diag = collectionutil_get_asm_diag_trace_folder();
  chomp($asm_diag);
  $asm_diag =~ s/^\n//g;
  my $retStr     = "";
  my $alert_file = catfile( $asm_diag, "alert_" . $asm_sid . ".log" );
  my $cmd        = "tail -1000 $alert_file";
  tfactlstore_summary_log( "command - $cmd", "collectionutils-get_asm_alerts" );
  my $contents = `$cmd`;    ## TODO: Use java class to tail last 1000 lines of the file

  foreach my $line ( split /\n/, $contents )
  {
    if ( $line =~ /(20[0-9][0-9]$|^ORA-|^TNS-|^Starting ORACLE instance|^Shutting down instance)/ )
    {
      $retStr = $retStr . $line . "\n";
    }
  }
  return $retStr;
}
##=============== ASM FUNCTIONS =====================================================

##=============== DB FUNCTIONS =====================================================
sub collectionutil_is_DB_installed {
  my $HOSTNAME = shift;
  tfactlstore_summary_log( "Checking if any DataBase is present", "collectionutil_is_DB_installed" );
  my $running_dbs = collectionutil_getRunningDBsDetails($HOSTNAME, 0, 1);

  my %hash = %{$running_dbs};
  my @db_details = keys %hash;
  if ($#db_details == -1) {
    tfactlstore_summary_log( "No DataBase Found", "collectionutil_is_DB_installed" );
    return 0;
  } else {  
    tfactlstore_summary_log( "DataBase Installation Found", "collectionutil_is_DB_installed" );
    return 1;
  }
}

sub collectionutil_getRunningDBsDetails
{
  my $HOSTNAME         = shift;
  my $get_ohome_sorted = shift;
  my $check_DB_flag    = shift;

  if ( length($get_ohome_sorted) == 0 || $get_ohome_sorted != 0 ) {
    $get_ohome_sorted = 1;
  }

  my @running_DB_resource;
  my %running_DB_config;
  my $RAT_CRS_HOME = collectionutil_get_crs_home();
  my $is_crs_up    = collectionutil_check_crs_state();
  my @tmp;

  #print "CRS UP: $is_crs_up\n";
  if ( $is_crs_up == 1 )
  {
    my $cmd;
    my $cmd_op;
    my $cmd1;
    my $cmd_op1;
    if ($IS_WIN)
    {
      $cmd = catfile( $RAT_CRS_HOME, "bin", "crsctl.exe" ) . " stat res | findstr ora.*.db";
    } else
    {
      $cmd = catfile( $RAT_CRS_HOME, "bin", "crsctl" ) . " stat res | grep ora.*.db";
    }
    tfactlstore_summary_log( "command - $cmd", "collectionutil_getRunningDBsDetails" );
    $cmd_op = `$cmd`;

    #print "CMD: $cmd\nOUTPUT: $cmd_op\n";
    foreach my $line ( split /\n/, $cmd_op )
    {
      chomp($line);
      if ( $line =~ /NAME=(.*)/ )
      {
        push @running_DB_resource, $1;
      }
    }
    foreach my $dbres (@running_DB_resource)
    {
      if ($IS_WIN)
      {
        $cmd = catfile( $RAT_CRS_HOME, "bin", "crsctl.exe" ) . " stat res $dbres -f";
      } else
      {
        $cmd = catfile( $RAT_CRS_HOME, "bin", "crsctl" ) . " stat res $dbres -f";
      }
      tfactlstore_summary_log( "command - $cmd", "collectionutil_getRunningDBsDetails" );
      my $dbres_config = `$cmd`;
      my $db_instance_name;
      my $db_home;
      my $db_user;
      my $db_name;
      foreach my $line ( split /\n/, $dbres_config )
      {

        if ( $line =~ /^DB_UNIQUE_NAME=(.*)/ )
        {
          $db_name = $1;
        } elsif ( $line =~ /^ORACLE_HOME=(.*)/ )
        {
          $db_home = $1;
        } elsif ( $line =~ /^GEN_USR_ORA_INST_NAME/ && $line =~ /$HOSTNAME/ )
        {
          $db_instance_name = ( split /=/, $line )[1];
        } elsif ( $line =~ /^ACL=/ )
        {
          $db_user = ( split /:/, ( split /,/, ( split /=/, $line )[1] )[0] )[1];
        }
      }
      next if ( $db_home =~ /\%CRS_HOME\%/ );
      $running_DB_config{$db_name} = $db_instance_name . "|" . $db_home . "|" . $db_user if ( $db_instance_name ne "" );
      last if ($check_DB_flag == 1);
    }
  } else
  {    #FOR SINGLE INSTANCE
    if ($IS_WIN)
    {
      my $count            = 1;
      my $ORACLE_INVENTORY = tfactlwin_query_registry("inst_loc");

      #$ORACLE_INVENTORY =~ s// /g;
      @tmp = split /\s{2,}/, $ORACLE_INVENTORY;
      $ORACLE_INVENTORY = $tmp[-1];
      chomp($ORACLE_INVENTORY);

      #print "ORACLE_INVENTORY: $ORACLE_INVENTORY\n";
      my $inventoryFile = catfile( $ORACLE_INVENTORY, "ContentsXML", "inventory.xml" );
      my @tmp = readFileToArray($inventoryFile);
      my @tmp1;
      my $db_home;
      my @dbhome_arr;
      foreach my $line (@tmp)
      {
        chomp($line);
        if ( $line =~ /HOME NAME=/ || $line =~ /HOME IDX=/ )
        {
          @tmp1 = split /\s{1,}/, $line;
          foreach my $x (@tmp1)
          {
            chomp($x);
            if ( $x =~ /LOC=/ )
            {
              $db_home = $x;
            }
          }
          @tmp1 = split /=/, $db_home;
          $db_home = $tmp1[1];
          $db_home =~ s/"//g;
          push @dbhome_arr, $db_home;
        }
      }

      my $cmd;
      my @db_name_arr;
      my @db_sid_arr;
      foreach my $dboh (@dbhome_arr)
      {
        chomp($dboh);
        $ENV{ORACLE_HOME} = $dboh;
        $cmd = catfile( $dboh, "bin", "orabase.exe" );

        #print "CMD: $cmd\n$ENV{ORACLE_HOME}\n";
        my $orabase = `$cmd`;
        chomp($orabase);

        #print "ORABASE : $orabase\n";
        $cmd = "dir " . catfile( $orabase, "diag", "rdbms" ) . "/B";
        my $db_names = `$cmd`;

        #print "DBs:\n$db_names\n";
        @db_name_arr = split /\n/, $db_names;
        foreach my $db (@db_name_arr)
        {
          chomp($db);

          # print "$count\. $db\n";
          $cmd = "dir " . catfile( $orabase, "diag", "rdbms", $db ) . "/B";
          my $db_sids = `$cmd`;
          @tmp1 = split /\n/, $db_sids;
          foreach my $x (@tmp1)
          {
            if ( $x =~ /$db/ )
            {
              chomp($x);
              push @db_sid_arr, $x;
              if ( testSQLWin( $db, $dboh, $x ) == 1 )
              {
                $running_DB_config{ $db . ":" . $x } = $x . "|" . $dboh . "|";
              }
            }
          }
          $count = $count + 1;
        }
      }
    } else
    {
      my $cmd = "ps -ef |grep ora_pmon|grep -v grep";

      #print "CMD: $cmd\n";
      my $sids = `$cmd`;
      my $db_sid;
      my $db_home;
      my $db_user;
      my $db_name;
      my $pid;
      my $count = 1;
      my @tmp;

      foreach my $line ( split /\n/, $sids )
      {
        $cmd = "echo $line | awk '{print \$NF}' | sed 's/ora_pmon_//'";

        #print "CMD: $cmd\n";
        $db_sid = `$cmd`;
        chomp($db_sid);
        $db_name = $db_sid;                            #since in SI, dbname is same as the instance name
                                                       # print "$count\. $db_name\n";
        $cmd     = "echo $line | awk '{print \$2}'";

        #print "CMD: $cmd\n";
        $pid = `$cmd`;
        chomp($pid);
        if ($PLATFORM eq "linux") {
          $cmd = "ls -l /proc/" . $pid . "/exe | grep oracle | awk '{print \$NF}'";

          #print "CMD: $cmd\n";
          $db_home = `$cmd`;
          @tmp     = split /\n/, $db_home;
          $db_home = $tmp[0];
        } elsif ($IS_AIX) {
          $cmd = "procmap $pid | grep lib | grep -v usr | awk '{print \$NF}'";
          $db_home = `$cmd`;
          @tmp     = split /\n/, $db_home;
          $db_home = $tmp[1];
          $db_home =~ s/\/lib\/.*//g; 
        } else {
          $cmd = "pmap $pid | grep oracle | awk '{print \$NF}'";
          $db_home = `$cmd`;
          @tmp     = split /\n/, $db_home;
          $db_home = $tmp[1];
        }

        $db_home =~ s/\/bin\/oracle//g;
        chomp($db_home);
        $cmd     = "echo $line | awk '{print \$1}'";
        $db_user = `$cmd`;
        chomp($db_user);

        # print "DETAILS: $db_name $db_sid $db_home $db_user $pid\n";
        $running_DB_config{$db_name} = $db_sid . "|" . $db_home . "|" . $db_user;
        $count = $count + 1;
      }
    }
  }
  my $running_db_details;
  if ( $get_ohome_sorted == 1 )
  {
    $running_db_details = collectionutil_get_runningDB_home( \%running_DB_config );
  } else {
    $running_db_details = \%running_DB_config;
  }
  return $running_db_details;
}

sub collectionutil_get_runningDB_home
{
  my $running_dbs_ref    = shift;
  my %running_dbs        = %{$running_dbs_ref};
  my $inventory_location = collectionutil_get_inventory_location();
  my $inventory_file     = catfile( $inventory_location, "ContentsXML", "inventory.xml" );
  my %running_db_details;

  if (-e $inventory_file) {
    my @tmp = readFileToArray($inventory_file);
    my %home_name_mapper;
    foreach my $line (@tmp)
    {
      chomp($line);
      if ( $line =~ /HOME NAME=\"(.*)\" LOC=\"(.*)\" TYPE=(.*)/ )
      {
        $home_name_mapper{$2} = $1;
      }
    }
    my @db_home = ();
    my $oracle_home;
    foreach my $db ( keys %running_dbs )
    {
      my @db_details_arr = split /\|/, $running_dbs{$db};
      $oracle_home = $db_details_arr[1];
      if ( $oracle_home =~ /(%|\$)/ )
      {
        my $oracle_home_env = $oracle_home;
        $oracle_home = `echo $oracle_home`;
        chomp($oracle_home);
        $running_dbs{$db} =~ s/$oracle_home_env/$oracle_home/g;
      }
      $running_db_details{ $home_name_mapper{$oracle_home} }{$db} = $running_dbs{$db};

      return \%running_db_details;
    } 
  } else {
      return $running_dbs_ref;
  }
}

sub collectionutil_get_inventory_location
{
  my $ORACLE_INVENTORY;
  if ($IS_WIN)
  {
    $ORACLE_INVENTORY = tfactlwin_query_registry("inst_loc");

    #$ORACLE_INVENTORY =~ s// /g;
    $ORACLE_INVENTORY = ( split /\s{2,}/, $ORACLE_INVENTORY )[-1];
  } elsif ( -e "/etc/oraInst.loc" )
  {
    $ORACLE_INVENTORY = `cat /etc/oraInst.loc|grep -v "^#"|grep inventory_loc|cut -d= -f2`;
  } elsif ( -e "/var/opt/oracle/oraInst.loc" )
  {
    $ORACLE_INVENTORY = `cat /var/opt/oracle/oraInst.loc|grep -v "^#"|grep inventory_loc|cut -d= -f2`;
  }
  chomp($ORACLE_INVENTORY);
  return $ORACLE_INVENTORY;
}

sub collectionutil_get_db_diag_trace_folder
{
  my $running_DB_config    = shift;
  my $db_details           = shift;
  my @db_details_arr       = split /\|/, $db_details;
  my $db_instance          = $db_details_arr[0];
  my $db_home              = $db_details_arr[1];
  my $db_user              = $db_details_arr[2];
  my $db_diag_trace_folder = run_a_sql( $db_home, $db_instance,
         "set feedback  off heading off lines 120\nselect value from v\$diag_info where name = 'Diag Trace';\nquit\n" );
  chomp($db_diag_trace_folder);
  $db_diag_trace_folder =~ s/^\n//g;
  return $db_diag_trace_folder;
}

sub collectionutil_get_db_banner
{
  my $running_DB_config = shift;
  my $db_details        = shift;
  my @db_details_arr    = split /\|/, $db_details;
  my $db_instance       = $db_details_arr[0];
  my $db_home           = $db_details_arr[1];
  my $db_user           = $db_details_arr[2];
  my $db_banner         = run_a_sql( $db_home, $db_instance,
                    "set feedback  off heading off lines 120\nselect BANNER from v\$version order by banner;\nquit\n" );
  return transformToStandardOutput($db_banner);
}

sub collectionutil_get_db_nls_character_set
{
  my $running_DB_config = shift;
  my $db_details        = shift;
  my @db_details_arr    = split /\|/, $db_details;
  my $db_instance       = $db_details_arr[0];
  my $db_home           = $db_details_arr[1];
  my $db_user           = $db_details_arr[2];
  my $db_nls_character_set = run_a_sql(
    $db_home,
    $db_instance,
"set feedback  off heading off lines 120\nselect value from nls_database_parameters where parameter='NLS_CHARACTERSET';\nquit\n"
  );
  return transformToStandardOutput($db_nls_character_set);
}

sub collectionutil_get_db_sga
{
  my $running_DB_config = shift;
  my $db_details        = shift;
  my @db_details_arr    = split /\|/, $db_details;
  my $db_instance       = $db_details_arr[0];
  my $db_home           = $db_details_arr[1];
  my $db_user           = $db_details_arr[2];
  my $sga = run_a_sql( $db_home, $db_instance, "set feedback  off heading off lines 120\nshow sga;\nquit\n" );
  return transformToStandardOutput($sga);
}

sub collectionutil_get_db_instances
{
  my $running_DB_config = shift;
  my $db_details        = shift;
  my @db_details_arr    = split /\|/, $db_details;
  my $db_instance       = $db_details_arr[0];
  my $db_home           = $db_details_arr[1];
  my $db_user           = $db_details_arr[2];
  my $db_instances =
    run_a_sql( $db_home, $db_instance, "set feedback  off heading off lines 120\nshow parameter instances;\nquit\n" );
  return transformToStandardOutput($db_instances);
}

sub collectionutil_get_db_parameter_instances
{
  my $running_DB_config = shift;
  my $db_details        = shift;
  my @db_details_arr    = split /\|/, $db_details;
  my $db_instance       = $db_details_arr[0];
  my $db_home           = $db_details_arr[1];
  my $db_user           = $db_details_arr[2];
  my $parameter_instance =
    run_a_sql( $db_home, $db_instance, "set feedback  off heading off lines 120\nshow parameter instance;\nquit\n" );
  return transformToStandardOutput($parameter_instance);
}

sub collectionutil_get_db_active_instances
{
  my $running_DB_config = shift;
  my $db_details        = shift;
  my @db_details_arr    = split /\|/, $db_details;
  my $db_instance       = $db_details_arr[0];
  my $db_home           = $db_details_arr[1];
  my $db_user           = $db_details_arr[2];
  my $active_instances  = run_a_sql( $db_home, $db_instance,
           "set feedback  off heading off lines 120\nselect INST_NUMBER, INST_NAME from v\$active_instances;\nquit\n" );
  return transformToStandardOutput($active_instances);
}

sub collectionutil_get_db_instance_details
{
  my $running_DB_config = shift;
  my $db_details        = shift;
  my @db_details_arr    = split /\|/, $db_details;
  my $db_instance       = $db_details_arr[0];
  my $db_home           = $db_details_arr[1];
  my $db_user           = $db_details_arr[2];
  my $instance_details = run_a_sql(
    $db_home,
    $db_instance,
"set feedback  off heading off lines 120\ncolumn instance_name format a16;\ncolumn host_name format a64;\ncolumn archiver format a7;\ncolumn status format a12;\nselect instance_name||':'||host_name||':'||archiver||':'||thread#||':'||status  from gv\$instance;\nquit\n"
  );
  return transformToStandardOutput($instance_details);
}

sub collectionutil_get_db_account_status
{
  my $running_DB_config = shift;
  my $db_details        = shift;
  my @db_details_arr    = split /\|/, $db_details;
  my $db_instance       = $db_details_arr[0];
  my $db_home           = $db_details_arr[1];
  my $db_user           = $db_details_arr[2];
  my $account_status = run_a_sql(
    $db_home,
    $db_instance,
"set feedback  off heading off lines 120\ncolumn username format a30;\ncolumn account_status format a30;\nselect username,account_status from dba_users order by username;\nquit\n"
  );
  return transformToStandardOutput($account_status);
}

sub collectionutil_get_db_components_version
{
  my $running_DB_config = shift;
  my $db_details        = shift;
  my @db_details_arr    = split /\|/, $db_details;
  my $db_instance       = $db_details_arr[0];
  my $db_home           = $db_details_arr[1];
  my $db_user           = $db_details_arr[2];
  my $components_version = run_a_sql(
    $db_home,
    $db_instance,
"set feedback  off heading off lines 120\ncolumn comp_name format a40;\ncolumn version format a20;\nselect comp_name,version from dba_registry order by comp_name ASC;\nquit\n"
  );
  return transformToStandardOutput($components_version);
}

sub collectionutil_get_db_datafiles_details
{
  my $running_DB_config = shift;
  my $db_details        = shift;
  my @db_details_arr    = split /\|/, $db_details;
  my $db_instance       = $db_details_arr[0];
  my $db_home           = $db_details_arr[1];
  my $db_user           = $db_details_arr[2];
  my $datafiles         = run_a_sql( $db_home, $db_instance,
       "set feedback  off heading off lines 120\nselect file_name||':'||bytes/1024/1024 from dba_data_files;\nquit\n" );
  return transformToStandardOutput($datafiles);
}

sub collectionutil_get_db_tablespaces
{
  my $running_DB_config = shift;
  my $db_details        = shift;
  my @db_details_arr    = split /\|/, $db_details;
  my $db_instance       = $db_details_arr[0];
  my $db_home           = $db_details_arr[1];
  my $db_user           = $db_details_arr[2];
  my $tablespaces = run_a_sql(
    $db_home,
    $db_instance,
"set feedback  off heading off lines 120\nselect tablespace_name||':'||user_bytes/1024/1024||':'||STATUS||':'||file_name from dba_data_files union select tablespace_name||':'||user_bytes/1024/1024||':'||STATUS||':'||file_name from dba_temp_files;\nquit\n"
  );
  return transformToStandardOutput($tablespaces);
}

sub collectionutil_get_db_invalid_objects
{
  my $running_DB_config = shift;
  my $db_details        = shift;
  my @db_details_arr    = split /\|/, $db_details;
  my $db_instance       = $db_details_arr[0];
  my $db_home           = $db_details_arr[1];
  my $db_user           = $db_details_arr[2];
  my $invalid_objects   = run_a_sql( $db_home, $db_instance,
        "set feedback  off heading off lines 120\nselect count(*) from all_objects where status = 'INVALID';\nquit\n" );
  return transformToStandardOutput($invalid_objects);
}

sub collectionutil_get_db_groups_status
{
  my $running_DB_config = shift;
  my $db_details        = shift;
  my @db_details_arr    = split /\|/, $db_details;
  my $db_instance       = $db_details_arr[0];
  my $db_home           = $db_details_arr[1];
  my $db_user           = $db_details_arr[2];
  my $groups_status = run_a_sql(
    $db_home,
    $db_instance,
"set feedback  off heading off lines 120\nselect group#||':'||type||':'||member||':'||is_recovery_dest_file  from v\$logfile;\nquit\n"
  );
  return transformToStandardOutput($groups_status);
}

sub collectionutil_get_db_files
{
  my $running_DB_config = shift;
  my $db_details        = shift;
  my @db_details_arr    = split /\|/, $db_details;
  my $db_instance       = $db_details_arr[0];
  my $db_home           = $db_details_arr[1];
  my $db_user           = $db_details_arr[2];
  my $db_files = run_a_sql(
    $db_home,
    $db_instance,
"set feedback  off heading off lines 120\ncolumn name format a100;\nselect name from v\$datafile union select name from v\$controlfile union select name from v\$tempfile union select member from v\$logfile;\nquit\n"
  );
  return transformToStandardOutput($db_files);
}

sub collectionutil_check_db_hanganalyze
{
  my $db_name        = shift;
  my $db_details     = shift;
  my $printFlag      = shift;
  my @db_details_arr = split /\|/, $db_details;
  my $db_instance    = $db_details_arr[0];
  my $db_home        = $db_details_arr[1];
  my $db_user        = $db_details_arr[2];
  my %retHash;
  tfactlstore_summary_log( "DB HangAnalyze Started...", "collectionutil_check_db_hanganalyze" );
  my $str = run_a_sql(
    $db_home,
    $db_instance,
"set feedback  off heading off lines 120\nset head off feed off echo off scan off verify off\nset trimspool on trimout on lines 1000 pages 10000\noradebug setmypid\noradebug dump hanganalyze 3\noradebug tracefile_name\nquit\n"
  );
  return \%retHash if($str =~ m/Database is Not Running/);
  my @tmp = split /\n/, $str;
  my $db_trace_file = $tmp[2];
  chomp($db_trace_file);
  return if ( !-e $db_trace_file );

  if ( $printFlag && $printFlag == 1 )
  {
    #	print "DB Trace File: $db_trace_file\n";
  }
  tfactlstore_summary_log( "DB Trace File: $db_trace_file", "collectionutil_check_db_hanganalyze" );
  my @db_trace_file_contents = readFileToArray($db_trace_file);
  my @trimmed_contents       = ();
  my $pushFlag               = 0;
  foreach my $line (@db_trace_file_contents)
  {
    if ( $line =~ /END OF HANG ANALYSIS/ )
    {
      $pushFlag = 0;
    }
    if ( $pushFlag == 1 )
    {
      push @trimmed_contents, $line;
    }
    if ( $line =~ /HANG ANALYSIS:/ )
    {
      $pushFlag = 1;
    }
  }

  my $no_chain   = 0;
  my $chain      = 0;
  my @chain_list = ();
  my $blocked    = 0;
  my $cycle      = 0;
  my @waiting    = ();
  my $first;
  my %proc;
  my $proc_id;
  my $proc_type;
  my $event;

  foreach my $line (@trimmed_contents)
  {    #print "IN LOOP";
    chomp($line);
    if ( $line =~ /no chains found/ )
    {
      $no_chain = 1;
    }
    if ( $line =~ /^Chain [0-9]+ Signature:/ )
    {
      if ( $line =~ /\(cycle\)/ )
      {
        $cycle++;
      }
      push @chain_list, $line;
    }
    if ( $line =~ /Oracle session identified/ )
    {
      $first = 1;
    }
    if ( $line =~ /process id:/ )
    {
      my @tmp = split /\s/, $line;
      $proc_id   = $tmp[3];
      $proc_type = $tmp[-1];
      if ( $proc_type =~ /V1\)$/ )
      {
        $proc_type = $tmp[-2] . " " . $tmp[-1];
      }
      if ( $proc_type !~ /\)$/ )
      {
        $proc_type = "";
      }
    }
    if ( $line =~ /which is waiting for/ )
    {
      $first = 0;
    }
    if ( $line =~ /is waiting for/ )
    {
      my @tmp = split /'\''/, $line;
      $event = "'\''" . $tmp[2] . "'\''";
      $proc{$proc_id} = $proc_type . " " . $event;
      if ( $event =~ /EMON slave idle wait/ )
      {
        $proc{$proc_id} = "(E00nn) " . $event;
      }
      if ( $event =~ /parallel recovery slave next change/ )
      {
        $proc{$proc_id} = "(PRnn) " . $event;
      }
      if ( $chain == "" )
      {
        $chain = $proc{$proc_id};
      } else
      {
        $chain = $proc{$proc_id} . " <= " . $chain;
      }
      push @waiting, $line;
      @waiting = array_uniq_elem(@waiting);
    }
    if ( $line =~ /is blocked by/ )
    {
      $blocked++;
    }
  }
  if ( $no_chain > 0 )
  {
    $retHash{"no_chain"} = "PASS";
  } else
  {
    $retHash{"no_chain"} = "FAIL";
  }
  if ( $cycle == 0 )
  {
    $retHash{"no_cycle"} = "PASS";
  } else
  {
    $retHash{"no_cycle"} = "FAIL";
  }
  if ( $blocked > 0 )
  {
    $retHash{"blocked"} = "FAIL";
  } else
  {
    $retHash{"blocked"} = "PASS";
  }
  $retHash{"chain_list"}          = \@chain_list;
  $retHash{"first"}               = $first;
  $retHash{"proc_id"}             = $proc_id;
  $retHash{"proc_type"}           = $proc_type;
  $retHash{"event"}               = $event;
  $retHash{"proc_hash"}           = \%proc;           # print "HANGANALYZE STOPPED\n";
  $retHash{"block_list"}          = \@waiting;
  $retHash{"TRACE_FILE_LOCATION"} = $db_trace_file;
  tfactlstore_summary_log( "DB HangAnalyze Completed...", "collectionutil_check_db_hanganalyze" );
  return \%retHash;
}

sub collectionutil_get_db_stats
{
  my $running_DB_config = shift;
  my $db_details        = shift;
  my @db_details_arr    = split /\|/, $db_details;
  my $db_instance       = $db_details_arr[0];
  my $db_home           = $db_details_arr[1];
  my $db_user           = $db_details_arr[2];
  my $db_stats = run_a_sql(
    $db_home, $db_instance, "set lines 980 pages 180
set head off feed off scan off echo off verify off
set numformat 99999999999.99
col dbname format a25
col sql_id format a20
col sql_text format a60
col wait_class format a25
col name format a15
col stype format a10
col owner format a10
col object_name format a15

select /* APSDBCHECK */  * from
(
WITH sch_user as
(select user#, name from user\$ ),
     stat_obj as
(select owner, object_name, data_object_id from dba_objects )
select
   'ASH' stype,
   (select  name from v\$database) dbname,
     '~' || nvl(a.event,'.')  event,
     '~' || nvl(a.sql_id,'.') sql_id,
     '~' || nvl(substr( sq.sql_text,1,55),'.')  sql_text,
     '~' || decode(session_state,'ON CPU','CPU + CPU Wait',wait_class)  wait_class,
     '~' || u.name name,
     '~' || o.owner owner,
     '~' || o.object_name || '~' object_name,
     '~' || time_waited time_waited,
      session_state
 from gv\$active_session_history a,
      gv\$sql sq,
      sch_user u,
      stat_obj o
     where a.sample_time > sysdate - 3/24 and
           a.sql_id = sq.sql_id and
           a.inst_id = sq.inst_id  and
           a.user_id = u.user#  and
           a.current_obj# = o.data_object_id (+)
)
pivot
(
     count(session_state)
     for (session_state) in ('WAITING' as WAITING, 'ON CPU' as CPU)
);

set lines 980 pages 180
set head off feed off scan off echo off verify off
set trimspool on trimout on
set numformat 99999999999.99
col name format a25
col source format a25
alter session set nls_date_format='DD-MON-RR/HH24:MI:SS';

SELECT 'SQLMON' stype, (select name from v\$database) name,
     nvl(username,regexp_replace(process_name,'(p|m)[0-9]+','\\1NNN')) source, sql_id,
     round(sum( elapsed_time )/1000000)              as elapse_time,
     round(sum( cpu_time )/1000000,2)                as cpu_time,
     round(sum( queuing_time )/1000000,2)            as queuing_time,
     round(sum( application_wait_time )/1000000,2)   as applic_wait,
     round(sum( concurrency_wait_time )/1000000,2)   as concurrency_wait,
     round(sum( cluster_wait_time )/1000000,2)       as cluster_wait,
     round(sum( user_io_wait_time)/1000000,2)       as user_io_wait,
     round(sum( physical_read_bytes)/(1024*1024 ))  as phys_reads_mb,
     round(sum( physical_write_bytes)/(1024*1024))  as phys_writes_mb,
     sum( buffer_gets)                              as buffer_gets,
     round(sum( plsql_exec_time)/1000000,2)         as plsql_exec,
     round(sum( java_exec_time) /1000000,2)         as java_exec,
     round(sum( fetches),2)         as fetches
     FROM gv\$sql_monitor
     where sql_exec_start > sysdate - 3/24
     group by username, process_name, sql_id having  round(sum(elapsed_time)/1000000) > 0;

set lines 980 pages 180
set head off feed off scan off echo off verify off
set numformat 99999999999.99
col dbname format a25
col sql_id format a20
col sql_text format a60
col wait_class format a25
col name format a15


alter session set nls_date_format='DD-MON-RR/HH24:MI:SS';
select
   'SQLSTAT' stype,
   pschema,
   sql_id,
   start_time,
   sum(execs) execs,
   sum(cpu_time)/1000000 cpu_time,
   sum(elapsed_time)/1000000 elapsed_time,
   sum(parse_calls) parse_calls,
   sum(fetches) fetches,
   sum(rows_processed) rows_processed,
   sum(phys_read_reqs) phys_read_reqs,
   sum(phys_read_reqs + phys_write_reqs) iops,
   sum(phys_read_bytes + phys_write_bytes)/1048576 mbbytes,
   sum(io_offloads) io_offloads,
   sum(buffer_gets) buffer_gets
from
 (
 WITH snap as (
    select a.snap_id, a.instance_number, a.dbid, a.start_time
      from (
             select distinct snap_id, instance_number, dbid, trunc(end_interval_time,'MI')  start_time
             from dba_hist_snapshot
             where
             trunc(begin_interval_time,'HH24') > sysdate - 3/24
             order by snap_id desc
      ) a where
      rownum < 2
      order by a.snap_id
  )
  select s.start_time start_time, a.snap_id, a.dbid, a.sql_id sql_id, a.EXECUTIONS_DELTA execs, a.CPU_TIME_DELTA cpu_time, a.ELAPSED_TIME_DELTA elapsed_time,
         a.PARSE_CALLS_DELTA parse_calls, a.DISK_READS_DELTA disk_reads, a.FETCHES_DELTA fetches, a.IO_OFFLOAD_RETURN_BYTES_DELTA io_offloads,
         a.PHYSICAL_READ_REQUESTS_DELTA phys_read_reqs, a.PHYSICAL_WRITE_REQUESTS_DELTA phys_write_reqs,
         a.PHYSICAL_READ_BYTES_DELTA phys_read_bytes, a.PHYSICAL_WRITE_BYTES_DELTA phys_write_bytes, a.ROWS_PROCESSED_DELTA rows_processed,
         a.BUFFER_GETS_DELTA buffer_gets,
         nvl(a.PARSING_SCHEMA_NAME,'.')  pschema
   from snap s,
        dba_hist_sqlstat a
   where s.snap_id = a.snap_id and
        s.instance_number = a.instance_number and
        s.dbid = a.dbid and
        a.parsing_schema_name is not null
  )
  group by pschema, start_time, sql_id;


set lines 1980 pages 180
set head off feed off scan off echo off verify off
set numformat 99999999999.99
col dbname format a25

alter session set nls_date_format='DD-MON-RR/HH24:MI:SS';
select
   'SYSEVENT' stype,
   /* APSDBCHECK */ (select name from v\$database) name,
   '~' || event_name event_name,
   '~' || wait_class || '~' wait_class,
   total_waits,
   total_timeouts,
   time_waited_ms,
   total_waits_fg,
   time_waited_fg_ms
from
(
select
  event_name, wait_class,
  sum(total_waits) total_waits,
  sum(total_timeouts) total_timeouts,
  sum(time_waited_micro/1000) time_waited_ms,
  sum(total_waits_fg) total_waits_fg,
  sum(time_waited_micro_fg/1000) time_waited_fg_ms
from
 (
    WITH snap as (
     select s.snap_id, s.instance_number, s.dbid, s.start_time
      from (
             select distinct snap_id, instance_number,  dbid, trunc(end_interval_time,'MI')  start_time
             from dba_hist_snapshot
             where
             trunc(begin_interval_time,'HH24') > sysdate - 3/24
             order by snap_id desc
      ) s where rownum < 3 order by s.snap_id
    )
    select a.event_name, a.wait_class, a.total_waits, a.total_timeouts,
          a.time_waited_micro, a.total_waits_fg, a.time_waited_micro_fg,
          s.snap_id, s.dbid, s.start_time
       from snap s,
            dba_hist_system_event a
       where s.snap_id = a.snap_id and
             s.instance_number = a.instance_number and
             s.dbid = a.dbid and
             a.wait_class not in ('Idle') and ( a.total_waits > 0 and a.total_waits_fg > 0 )
  )
  group by event_name, wait_class
);
quit\n"
  );
  return $db_stats;
}

sub collectionutil_check_system_events
{
  my $retStr = shift;

  my @db_stats = split /\n/, $retStr;
  my @sys_events = grepPatternFromArray( \@db_stats, "^SYSEVENT " );
  my @sys_events_arr = ();
  foreach my $line (@sys_events)
  {
    $line =~ s/^SYSEVENT\s{1,}//g;
    my @tmp = ();
    foreach my $x ( split /~/, $line )
    {
      $x =~ s/^\s{1,}//g;
      $x =~ s/\s{1,}$//g;
      push @tmp, $x;
    }
    my @tmp1 = split /\s{1,}/, $tmp[-1];
    $tmp[-1] = $tmp1[0];
    push @tmp,            $tmp1[1];
    push @tmp,            $tmp1[2];
    push @tmp,            $tmp1[3];
    push @tmp,            $tmp1[4];
    push @sys_events_arr, \@tmp;
  }

  return @sys_events_arr;
}

sub collectionutil_process_db_stats
{
  my $retStr = shift;
  my $process_criteria = shift;

  my @db_stats = split /\n/, $retStr;
  my @ash_db_stats = grepPatternFromArray( \@db_stats, "^ASH" );
  @ash_db_stats = removePatternFromArray( \@ash_db_stats, "APSDBCHECK" );
  my $waittime = 0;
  my $cputime  = 0;
  foreach my $line (@ash_db_stats)
  {
    my @tmp = split /\s{2,}/, $line;

    #print "line: $tmp[-2] $tmp[-1]\n";
    $waittime += $tmp[-2];
    $cputime  += $tmp[-1];
  }
  my $dbtime   = $waittime + $cputime;
  my $aas      = $dbtime / 10800;        # 3/24 - 3 hours (from querying DB_HIST_nnnnn)
  my $cpu_aas  = $cputime / 10800;       # 3/24 - 3 hours (from querying DB_HIST_nnnnn)
  my $wait_aas = $waittime / 10800;

  my %db_stats_sqlid_hash;
  foreach my $line (@ash_db_stats)
  {
    $line =~ s/^ASH\s{1,}//g;
    my @tmp = split /~/, $line;
    $tmp[3] =~ s/\s{1,}/ /g;
    $tmp[3] =~ s/"/\\"/g;
    foreach my $x (@tmp)
    {
      $x =~ s/\s{1,}$//g;
      $x =~ s/^\s{1,}//g;
    }
    my $last = $tmp[-1];
    my @tmp1 = split /\s{2,}/, $last;
    $tmp[-1] = $tmp1[0];
    push @tmp, $tmp1[1];
    push @tmp, $tmp1[2];
    $db_stats_sqlid_hash{ $tmp[2] } = \@tmp;
    delete ${ $db_stats_sqlid_hash{ $tmp[2] } }[2];
  }

  my %processed_hash;
  foreach my $key ( keys %db_stats_sqlid_hash )
  {
    if ( $process_criteria eq "event" )
    {
      #print "check: ${$db_stats_sqlid_hash{$key}}[1]\n";
      if ( $processed_hash{ ${ $db_stats_sqlid_hash{$key} }[1] } )
      {
        $processed_hash{ ${ $db_stats_sqlid_hash{$key} }[1] } =
          $processed_hash{ ${ $db_stats_sqlid_hash{$key} }[1] } . ":" . $key;
      } else
      {
        $processed_hash{ ${ $db_stats_sqlid_hash{$key} }[1] } = $key;
      }
    } elsif ( $process_criteria eq "sql" )
    {
      if ( $processed_hash{ ${ $db_stats_sqlid_hash{$key} }[3] } )
      {
        $processed_hash{ ${ $db_stats_sqlid_hash{$key} }[3] } =
          $processed_hash{ ${ $db_stats_sqlid_hash{$key} }[3] } . ":" . $key;
      } else
      {
        $processed_hash{ ${ $db_stats_sqlid_hash{$key} }[3] } = $key;
      }
    } elsif ( $process_criteria eq "dbname" )
    {
      if ( $processed_hash{ ${ $db_stats_sqlid_hash{$key} }[0] } )
      {
        $processed_hash{ ${ $db_stats_sqlid_hash{$key} }[0] } =
          $processed_hash{ ${ $db_stats_sqlid_hash{$key} }[0] } . ":" . $key;
      } else
      {
        $processed_hash{ ${ $db_stats_sqlid_hash{$key} }[0] } = $key;
      }
    }
  }
  my %retHash;
  my $count = 0;
  foreach my $x ( keys %processed_hash )
  {
    #print "$x => $processed_hash{$x}\n";
    my @sqlid_list = split /:/, $processed_hash{$x};
    my $cputime    = 0;
    my $waittime   = 0;
    foreach my $sqlid (@sqlid_list)
    {
      $cputime  += ${ $db_stats_sqlid_hash{$sqlid} }[-1];
      $waittime += ${ $db_stats_sqlid_hash{$sqlid} }[-2];
    }
    my $dbtime = $cputime + $waittime;
    $count += $dbtime;
    my @tmp = ();
    push @tmp, $cputime;
    push @tmp, $waittime;
    push @tmp, $dbtime;
    $retHash{$x} = \@tmp;
  }
  foreach my $x ( keys %retHash )
  {
    my $pctload = ( ${ $retHash{$x} }[2] / $count ) * 100;
    push @{ $retHash{$x} }, $pctload;
  }

  return ( \%db_stats_sqlid_hash, \%processed_hash, \%retHash );
}

sub collectionutil_process_sql_stat
{
  my $retStr = shift;
  my $process_criteria = shift;

  #print "$retStr\n\n";
  my @db_stats = split /\n/, $retStr;
  my @sql_stats = grepPatternFromArray( \@db_stats, "^SQLSTAT " );
  my @sql_stats_arr = ();
  foreach my $line (@sql_stats)
  {
    $line =~ s/^SQLSTAT\s{1,}//g;

    #print "$line\n";
    my @tmp = split /\s{1,}/, $line;
    push @sql_stats_arr, \@tmp;
  }
  my %sql_stats_hash;
  foreach my $x (@sql_stats_arr)
  {
    $sql_stats_hash{ ${$x}[1] } = $x;

    #delete ${$sql_stats_hash{${$x}[1]}}[1];
  }

  my %processed_hash;
  my @retArr;
  if ( $process_criteria eq "exec" )
  {
    foreach my $x ( keys %sql_stats_hash )
    {
      $processed_hash{$x} = ${ $sql_stats_hash{$x} }[3];
    }
    foreach my $x ( sort { $processed_hash{$b} <=> $processed_hash{$a} } ( keys(%processed_hash) ) )
    {
      push @retArr, $x;

      #print "$x : $processed_hash{$x}\n";
    }
  } elsif ( $process_criteria eq "cpu" )
  {
    foreach my $x ( keys %sql_stats_hash )
    {
      $processed_hash{$x} = ${ $sql_stats_hash{$x} }[4];
    }
    foreach my $x ( sort { $processed_hash{$b} <=> $processed_hash{$a} } ( keys(%processed_hash) ) )
    {
      push @retArr, $x;
    }
  } elsif ( $process_criteria eq "elapse" )
  {
    foreach my $x ( keys %sql_stats_hash )
    {
      $processed_hash{$x} = ${ $sql_stats_hash{$x} }[5];
    }
    foreach my $x ( sort { $processed_hash{$b} <=> $processed_hash{$a} } ( keys(%processed_hash) ) )
    {
      push @retArr, $x;
    }
  } elsif ( $process_criteria eq "gets" )
  {
    foreach my $x ( keys %sql_stats_hash )
    {
      $processed_hash{$x} = ${ $sql_stats_hash{$x} }[13];
    }
    foreach my $x ( sort { $processed_hash{$b} <=> $processed_hash{$a} } ( keys(%processed_hash) ) )
    {
      push @retArr, $x;
    }
  } elsif ( $process_criteria eq "gets_exec" )
  {
    foreach my $x ( keys %sql_stats_hash )
    {
      if ( ${ $sql_stats_hash{$x} }[3] != 0 )
      {
        $processed_hash{$x} = ${ $sql_stats_hash{$x} }[13] / ${ $sql_stats_hash{$x} }[3];
      } else
      {
        $processed_hash{$x} = ${ $sql_stats_hash{$x} }[13] / 0.001;
      }
    }
    foreach my $x ( sort { $processed_hash{$b} <=> $processed_hash{$a} } ( keys(%processed_hash) ) )
    {
      push @retArr, $x;
    }
  } elsif ( $process_criteria eq "elapse_exec" )
  {
    foreach my $x ( keys %sql_stats_hash )
    {
      if ( ${ $sql_stats_hash{$x} }[3] != 0 )
      {
        $processed_hash{$x} = ${ $sql_stats_hash{$x} }[5] / ${ $sql_stats_hash{$x} }[3];
      } else
      {
        $processed_hash{$x} = ${ $sql_stats_hash{$x} }[5] / 0.001;
      }
    }
    foreach my $x ( sort { $processed_hash{$b} <=> $processed_hash{$a} } ( keys(%processed_hash) ) )
    {
      push @retArr, $x;
    }
  }
  return ( \%sql_stats_hash, \@retArr );
}

sub collectionutil_process_sql_monitor
{
  my $retStr = shift;
  my $process_criteria = shift;

  my @db_stats = split /\n/, $retStr;
  my @sql_monitor = grepPatternFromArray( \@db_stats, "^SQLMON" );
  my @sql_monitor_arr = ();
  foreach my $line (@sql_monitor)
  {
    $line =~ s/^SQLMON\s{1,}//g;

    #print "$line\n";
    my @tmp = split /\s{1,}/, $line;
    push @sql_monitor_arr, \@tmp;
  }
  my %sql_mon_hash;
  foreach my $x (@sql_monitor_arr)
  {
    $sql_mon_hash{ ${$x}[2] } = $x;

    #delete ${$sql_mon_hash{${$x}[2]}}[2];
  }

  my %processed_hash;
  my @retArr;
  if ( $process_criteria eq "elapse" )
  {
    foreach my $x ( keys %sql_mon_hash )
    {
      $processed_hash{$x} = ${ $sql_mon_hash{$x} }[3];
    }
    foreach my $x ( sort { $processed_hash{$b} <=> $processed_hash{$a} } ( keys(%processed_hash) ) )
    {
      push @retArr, $x;

      #print "$x : $processed_hash{$x}\n";
    }
  } elsif ( $process_criteria eq "cpu" )
  {
    foreach my $x ( keys %sql_mon_hash )
    {
      $processed_hash{$x} = ${ $sql_mon_hash{$x} }[4];
    }
    foreach my $x ( sort { $processed_hash{$b} <=> $processed_hash{$a} } ( keys(%processed_hash) ) )
    {
      push @retArr, $x;
    }
  } elsif ( $process_criteria eq "concurrency" )
  {
    foreach my $x ( keys %sql_mon_hash )
    {
      $processed_hash{$x} = ${ $sql_mon_hash{$x} }[7];
    }
    foreach my $x ( sort { $processed_hash{$b} <=> $processed_hash{$a} } ( keys(%processed_hash) ) )
    {
      push @retArr, $x;
    }
  } elsif ( $process_criteria eq "cluster" )
  {
    foreach my $x ( keys %sql_mon_hash )
    {
      $processed_hash{$x} = ${ $sql_mon_hash{$x} }[8];
    }
    foreach my $x ( sort { $processed_hash{$b} <=> $processed_hash{$a} } ( keys(%processed_hash) ) )
    {
      push @retArr, $x;
    }
  } elsif ( $process_criteria eq "userio" )
  {
    foreach my $x ( keys %sql_mon_hash )
    {
      $processed_hash{$x} = ${ $sql_mon_hash{$x} }[9];
    }
    foreach my $x ( sort { $processed_hash{$b} <=> $processed_hash{$a} } ( keys(%processed_hash) ) )
    {
      push @retArr, $x;
    }
  } elsif ( $process_criteria eq "gets" )
  {
    foreach my $x ( keys %sql_mon_hash )
    {
      $processed_hash{$x} = ${ $sql_mon_hash{$x} }[12];
    }
    foreach my $x ( sort { $processed_hash{$b} <=> $processed_hash{$a} } ( keys(%processed_hash) ) )
    {
      push @retArr, $x;
    }
  }
  return ( \%sql_mon_hash, \@retArr );
}

sub collectionutil_getRunningDB_homes
{
  my $running_dbs_ref = shift;
  my %running_dbs     = %{$running_dbs_ref};
  my @db_home         = ();
  foreach my $db ( keys %running_dbs )
  {
    my @db_details_arr = split /\|/, $running_dbs{$db};
    push @db_home, $db_details_arr[1];
  }

  @db_home = array_uniq_elem(@db_home);
  return \@db_home;
}

sub collectionutil_get_serverpool_details
{
  my $running_dbs_ref = shift;
  my $ref             = collectionutil_getRunningDB_homes($running_dbs_ref);
  my @db_homes        = @{$ref};
  my $cmd;
  my $str;
  my @serverpool_details;
  foreach my $db_home (@db_homes)
  {
    $ENV{ORACLE_HOME} = $db_home;

    # CONFIG SERVERPOOL
    if ($IS_WIN)
    {
      $cmd = catfile( $db_home, "bin", "srvctl.bat" ) . " config serverpool";
    } else
    {
      $cmd = catfile( $db_home, "bin", "srvctl" ) . " config serverpool";
    }
    tfactlstore_summary_log( "command - $cmd", "collectionutil_get_serverpool_details" );
    $str = `$cmd`;
    my @config_serverpool = ();
    my @cmd_op = split /\n/, $str;
    for ( my $i = 0 ; $i <= $#cmd_op ; )
    {
      my %tmp;
      if ( $cmd_op[$i] =~ /Server pool name:\s/ )
      {
        $tmp{'SERVERPOOL_NAME'} = ( split /:\s/, $cmd_op[$i] )[1];
        $tmp{'IMPORTANCE'} = ( split /:\s/, ( split /,\s/, $cmd_op[ $i + 1 ] )[0] )[1];
        $tmp{'MINIMUM'}    = ( split /:\s/, ( split /,\s/, $cmd_op[ $i + 1 ] )[1] )[1];
        $tmp{'MAXIMUM'}    = ( split /:\s/, ( split /,\s/, $cmd_op[ $i + 1 ] )[2] )[1];
        $tmp{'CANDIDATE_SERVER_NAMES'} = ( split /:\s{0,1}/, $cmd_op[ $i + 2 ] )[1];
        $i += 3;
      }
      push @config_serverpool, \%tmp;
    }

    push( @serverpool_details, { 'TYPE' => "CONFIG", 'DETAILS' => \@config_serverpool } );

    # STATUS SERVERPOOL
    if ($IS_WIN)
    {
      $cmd = catfile( $db_home, "bin", "srvctl.bat" ) . " status serverpool";
    } else
    {
      $cmd = catfile( $db_home, "bin", "srvctl" ) . " status serverpool";
    }
    tfactlstore_summary_log( "command - $cmd", "collectionutil_get_serverpool_details" );
    $str = `$cmd`;
    my @status_serverpool = ();
    my @cmd_op = split /\n/, $str;
    for ( my $i = 0 ; $i <= $#cmd_op ; )
    {
      my %tmp;
      if ( $cmd_op[$i] =~ /Server pool name:\s/ )
      {
        $tmp{'SERVERPOOL_NAME'}      = ( split /:\s/,      $cmd_op[$i] )[1];
        $tmp{'ACTIVE_SERVERS_COUNT'} = ( split /:\s{0,1}/, $cmd_op[ $i + 1 ] )[1];
        $i += 2;
      }
      push @status_serverpool, \%tmp;
    }

    push( @serverpool_details, { 'TYPE' => "STATUS", 'DETAILS' => \@status_serverpool } );
  }
  return \@serverpool_details;
}

sub collectionutil_get_rman_stats
{
  my $running_DB_config = shift;
  my $db_details        = shift;
  my @db_details_arr    = split /\|/, $db_details;
  my $db_instance       = $db_details_arr[0];
  my $db_home           = $db_details_arr[1];
  my $db_user           = $db_details_arr[2];
  my @retArr            = ();
  my $sqlFile;

  if ($IS_WIN)
  {
    $sqlFile = catfile( $WIN_TRANSFER_DIR, "commands_$$.sql" );
  } else
  {
    my $dir_tfa_base = tfactlshare_get_repository_location($tfa_home);
    my $dir_base = catfile($dir_tfa_base, "suptools", "$hostname", "summary",$db_user);
    $sqlFile = catfile( $dir_base, "commands_$$.sql" );
  }
  tfactlstore_summary_log( "SQLFILE: $sqlFile", "run_a_sql" );
  open( my $sql_fptr, '>', $sqlFile ) or die "Could not open file '$sqlFile' $!";
  print $sql_fptr "list backup summary;\nquit;\n";
  close $sql_fptr;
  tfactlstore_summary_log( "SQLFILE: $sqlFile", "collectionutil_get_rman_stats" );
  chmod(oct("0755"),$sqlFile);

  my $cmd;

  my $OLD_ORACLE_HOME = $ENV{"ORACLE_HOME"};
  my $OLD_ORACLE_SID  = $ENV{"ORACLE_SID"};
  $ENV{"ORACLE_SID"}      = $db_instance;
  $ENV{"ORACLE_HOME"}     = $db_home;
  $ENV{"LD_LIBRARY_PATH"} = catfile( $ENV{"ORACLE_HOME"}, "lib" );
  my $ORACLE_HOME_cpy = $ENV{"ORACLE_HOME"};
  if ($IS_WIN)
  {
    $cmd = catfile( $ORACLE_HOME_cpy, "BIN", "rman.exe" ) . " target / @ $sqlFile";
  } else
  {
    $cmd = "su $db_user -c \"" . catfile( $ORACLE_HOME_cpy, "bin", "rman" ) . " target / @ $sqlFile\"";
  }
  tfactlstore_summary_log( "CMD: $cmd", "collectionutil_get_rman_stats" );
  my $str = `$cmd`;
  my @str_arr = split /\n/, $str;
  return "Database is Not Running" if($str =~ /connected to target database \(not started\)/);
  for ( my $i = 0 ; $i <= $#str_arr ; )
  {
    my $line = $str_arr[$i];
    if ( $line =~ /specification does not match any backup in the repository/ )
    {
      push @retArr, "Does not match any backup in the repository"; 
      last;
    } elsif ( $line =~ /List of Backups/ )
    {
      my $j;
      for ( $j = $i + 4 ; $j <= $#str_arr ; $j++ )
      {
        next if ( $str_arr[$j] =~ /Recovery Manager complete./ );
        my @tmp = split /\s{1,}/, $str_arr[$j];
        my %tmpHash;
        $tmpHash{'KEY'}         = $tmp[0];
        $tmpHash{'TY'}          = $tmp[1];
        $tmpHash{'LV'}          = $tmp[2];
        $tmpHash{'S'}           = $tmp[3];
        $tmpHash{'DEVICE_TYPE'} = $tmp[4];
        $tmpHash{'COMPLETION'}  = $tmp[5];
        $tmpHash{'#PIECES'}     = $tmp[6];
        $tmpHash{'#COPIES'}     = $tmp[7];
        $tmpHash{'COMPRESSED'}  = $tmp[8];
        $tmpHash{'TAG'}         = $tmp[9];
        push @retArr, \%tmpHash;
      }
      $i = $j;
    } elsif ( $line =~ /Recovery Manager complete./ )
    {
      last;
    } else
    {
      $i = $i + 1;
    }
  }
  $ENV{"ORACLE_HOME"}     = $OLD_ORACLE_HOME;
  $ENV{"ORACLE_SID"}      = $OLD_ORACLE_SID;
  $ENV{"LD_LIBRARY_PATH"} = catfile( $ENV{"ORACLE_HOME"}, "lib" );
  unlink($sqlFile);
  return \@retArr;
}

sub collectionutil_get_pdbs_stats
{
  my $running_DB_config = shift;
  my $db_details        = shift;
  my @db_details_arr    = split /\|/, $db_details;
  my $db_instance       = $db_details_arr[0];
  my $db_home           = $db_details_arr[1];
  my $db_user           = $db_details_arr[2];
  my $is_version_12     = shift;
  my %retHash;

  if ($is_version_12)
  {
    my $str = run_a_sql( $db_home, $db_instance,
              "set feedback  off heading off lines 120\nSELECT NAME||':'||CDB||':'||CON_ID FROM V\$DATABASE;\nquit\n" );
    my $isCDB = ( split /:/, $str )[1];
    if ( $isCDB eq "NO" )
    {
      $retHash{'DB_NAME'} = $running_DB_config;
      $retHash{'IS_CDB'}  = "NO";
    } else
    {
      $retHash{'DB_NAME'} = $running_DB_config;
      $retHash{'IS_CDB'}  = "YES";
      my $pdb_details = run_a_sql(
        $db_home,
        $db_instance,
"set feedback  off heading off lines 120\nselect CON_ID||':'||DBID||':'||NAME||':'||OPEN_MODE||':'||RESTRICTED||':'||OPEN_TIME||':'||CREATE_SCN||':'||TOTAL_SIZE||':'||BLOCK_SIZE||':'||RECOVERY_STATUS from v\$pdbs;\nquit\n"
      );
      my @pdb_details_arr = ();
      foreach my $line ( split /\n/, $pdb_details )
      {
        my @line_arr = split /:/, $line;
        my %tmp;
        $tmp{'CON_ID'}     = $line_arr[0];
        $tmp{'DBID'}       = $line_arr[1];
        $tmp{'NAME'}       = $line_arr[2];
        $tmp{'OPEN_MODE'}  = $line_arr[3];
        $tmp{'RESTRICTED'} = $line_arr[4];
        $tmp{'OPEN_TIME'}  = $line_arr[5];

        #	$tmp{'CREATE_SCN'} = $line_arr[6];
        $tmp{'TOTAL_SIZE'} = $line_arr[7];
        $tmp{'BLOCK_SIZE'} = $line_arr[8];

        #	$tmp{'RECOVERY_STATUS'} = $line_arr[9];
        push @pdb_details_arr, \%tmp;
      }
      $retHash{'PDB_DETAILS'} = \@pdb_details_arr;
    }
  }
  return %retHash;
}
##=============== DB FUNCTIONS =====================================================
##=============== OS FUNCTIONS =====================================================
sub collectionutil_get_os_details
{
  my $OS;
  my $kernel;
  my $kernel_release;
  my %retHash;
  tfactlstore_summary_log( "os commands", "collectionutil_get_os_details" );
  if ($IS_WIN)
  {
    my $txt = `systeminfo | findstr /C:"OS"`;

    #print "OP: $txt\n";
    foreach my $line ( split /\n/, $txt )
    {
      if ( $line =~ /^OS Name:/ )
      {
        $retHash{'OS_NAME'} = ( split /:\s{1,}/, $line )[1];
      } elsif ( $line =~ /^OS Version:/ )
      {
        $retHash{'OS_VERSION'} = ( split /:\s{1,}/, $line )[1];
      } elsif ( $line =~ /^OS Manufacturer:/ )
      {
        $retHash{'OS_MANUFACTURER'} = ( split /:\s{1,}/, $line )[1];
      } elsif ( $line =~ /^OS Configuration:/ )
      {
        $retHash{'OS_CONFIGURATION'} = ( split /:\s{1,}/, $line )[1];
      } elsif ( $line =~ /^OS Build Type:/ )
      {
        $retHash{'OS_BUILD_TYPE'} = ( split /:\s{1,}/, $line )[1];
      } elsif ( $line =~ /^BIOS Version:/ )
      {
        $retHash{'BIOS_VERSION'} = ( split /:\s{1,}/, $line )[1];
      }
    }
  } elsif ($IS_SOLARIS) {
    my $str = `$UNAME -a`;
    my @fields =  split(/\s/,$str);
    
    foreach my $field (@fields) {
      my %hash;
      $hash{"OS"} = $fields[0];
      $hash{"OS_RELEASE_LEVEL"} = $fields[2];
      $hash{"OS_VERSION"} = $fields[3];
      $hash{"MACHINE_HW_NAME"} =$fields[4];
      $hash{"PROCESSOR_TYPE"} =$fields[5];
      $hash{"PLATFORM"} = $fields[6];

      $retHash{$fields[0]} = \%hash;
    }

    return %retHash;

  } elsif ($PLATFORM eq "aix") {
    my $txt = `oslevel -s`; 

    my $aix_version = (split /-/, $txt)[0];
    $aix_version /= 1000;
    my $aix_tech_level = (split /-/, $txt)[1];
    my $aix_service_package = (split /-/, $txt)[2];

    $retHash{'OS'}                  = "AIX " . $aix_version;
    $retHash{'OS_TECHNOLOGY_LEVEL'} = $aix_tech_level;
    $retHash{'SERVICE_PACKAGE'}     = $aix_service_package;
    $txt                            = `uname -M`;
    $retHash{'SYSTEM_MODEL_NAME'}   = $txt;
    $txt                            = `uname -p`;
    $retHash{'PROCESSOR_ARCHITECTURE'} = $txt;
  } else {
    my $txt = `uname -o`;
    $retHash{'OS'}             = $txt;
    $txt                       = `uname -s`;
    $retHash{'KERNEL'}         = $txt;
    $txt                       = `uname -r`;
    $retHash{'KERNEL_RELEASE'} = $txt;
    $txt                       = `uname -v`;
    $retHash{'KERNEL_VERSION'} = $txt;
  }
  return %retHash;
}

sub collectionutil_get_oracle_release
{
  my $file;
  if ($IS_WIN)
  {
  } else
  {
    $file = catfile( "/etc", "oracle-release" );
  }

  if (-e $file) {
    my @oracle_release = readFileToArray($file);
    return $oracle_release[0];
  } else {
    return "-";
  }
}

sub collectionutil_get_redhat_release
{
  my $file;
  if ($IS_WIN)
  {
  } else
  {
    $file = catfile( "/etc", "redhat-release" );
  }

  if (-e $file) {
    my @redhat_release = readFileToArray($file);
    return $redhat_release[0];
  } else {
    return "-";
  }
}

sub collectionutil_get_cpu_details
{
  my $cpu_details_file;
  my @cpu_details_file_arr;
  my $no_of_processors = 0;
  my %retHash;
  if ($IS_WIN)
  {
    my $cmd = "echo %PROCESSOR_ARCHITECTURE%!%PROCESSOR_IDENTIFIER%!%PROCESSOR_LEVEL%!%PROCESSOR_REVISION%";

    tfactlstore_summary_log( "command - $cmd", "collectionutil_get_cpu_details" );
    my $txt = `$cmd`;

    #print "OP: $txt\n";
    $retHash{'Architecture'}       = ( split /!/, $txt )[0];
    $retHash{'Model_name'}         = ( split /!/, $txt )[1];
    $retHash{'Processor_level'}    = ( split /!/, $txt )[2];
    $retHash{'Processor_revision'} = ( split /!/, $txt )[3];
    $cmd                           = "wmic cpu get caption";

    #print "CMD: $cmd\n";
    $txt = `$cmd`;
    my @txt_arr = split /\n/, $txt;
    $retHash{'#Processors'} = $#txt_arr;
  } elsif ($PLATFORM eq "aix") { 
    my $cmd = "lparstat -i";

    tfactlstore_summary_log("Command  - $cmd", "collectionutil_get_cpu_details");
    my $txt = `$cmd`;
    chomp($txt);
    $txt =~ s/^\s{1,}|\s{1,}$//g;

    #print "OP: $txt\n";
    my @txt_arr = split /\n/, $txt;
    my %tmp;
    $tmp{'Partition_Name'} = (split /\s{1,}:\s{1,}/, $txt_arr[1])[1];
    $tmp{'Partition_Number'} = (split /\s{1,}:\s{1,}/, $txt_arr[2])[1];
    $tmp{'Type'} = (split /\s{1,}:\s{1,}/, $txt_arr[3])[1];
    $tmp{'Mode'} = (split /\s{1,}:\s{1,}/, $txt_arr[4])[1];
    $tmp{'Power_Saving_Mode'} = (split /\s{1,}:\s{1,}/, $txt_arr[42])[1];
    $retHash{'SYSTEM DETAILS'} = \%tmp;

    my %tmp;
    $tmp{'Online_Virtual_CPUs'} = (split /\s{1,}:\s{1,}/, $txt_arr[8])[1];
    $tmp{'Max_Virtual_CPUs'} = (split /\s{1,}:\s{1,}/, $txt_arr[9])[1];
    $tmp{'Min_Virtual_CPUs'} = (split /\s{1,}:\s{1,}/, $txt_arr[10])[1];
    
    my $cmd = "lsconf|grep Proces";
    tfactlstore_summary_log("Command  - $cmd", "collectionutil_get_cpu_details");
    my $text = `$cmd`;
    my @text_arr = split /\n/, $text;
    $tmp{'Processor_type'} = (split /:\s{1,}/, $text_arr[0])[1];
    $tmp{'Processor_Implementation_Mode'} = (split /:\s{1,}/, $text_arr[1])[1];
    $tmp{'Processor_Version'} = (split /:\s{1,}/, $text_arr[2])[1];
    $tmp{'#Processors'} = (split /:\s{1,}/, $text_arr[3])[1];
    $tmp{'Clock_Speed'} = (split /:\s{1,}/, $text_arr[4])[1];

    $retHash{'CPU DETAILS'} = \%tmp;

    my %tmp;
    $tmp{'Online_Memory'} = (split /\s{1,}:\s{1,}/, $txt_arr[11])[1];
    $tmp{'Max_Memory'} = (split /\s{1,}:\s{1,}/, $txt_arr[12])[1];
    $tmp{'Min_Memory'} = (split /\s{1,}:\s{1,}/, $txt_arr[13])[1];
    $tmp{'Memory_Mode'} = (split /\s{1,}:\s{1,}/, $txt_arr[27])[1];
    $retHash{'MEMORY DETAILS'} = \%tmp;

  } elsif ($IS_SOLARIS) {

    $retHash{"Model"} = `$KSTAT cpu_info | $GREP brand | $TAIL -1 | $CUT -d " " -f28,29`;
    tfactlstore_summary_log( "Catching CPU info with kstat command", "collectionutil_get_cpu_details" );
    $retHash{"Physical_Processors"} = `$PSRINFO -p`;
    $retHash{"Cores"} = `$PSRINFO | $WC -l | $TR -d " "`;
    $retHash{"Frequency"} = `$PSRINFO -v | $GREP -i "processor operates" | $TAIL -1 | $CUT -d " " -f 8,9 | $TR -d ,`;
    $retHash{"Cache"} = `$PRTPICL -v -c cpu | $GREP l2-cache-size | $TAIL -1 | $CUT -d ":" -f 2 | $CUT -d " " -f 2`;

  } else {
    $cpu_details_file = catfile( "/", "proc", "cpuinfo" );
    tfactlstore_summary_log( "Reading File - $cpu_details_file", "collectionutil_get_cpu_details" );
    @cpu_details_file_arr = readFileToArray($cpu_details_file);
    foreach my $line (@cpu_details_file_arr)
    {
      if ( $line =~ /^processor/ )
      {
        $no_of_processors++;
      } elsif ( $line =~ /^vendor_id/ && !$retHash{"Vendor"} )
      {
        my $str = ( split /:/, $line )[1];
        $retHash{"Vendor"} = trimString($str);
      } elsif ( $line =~ /^model name/ && !$retHash{"Model_name"} )
      {
        my $str = ( split /:/, $line )[1];
        $retHash{"Model_name"} = trimString($str);
      } elsif ( $line =~ /^cache size/ && !$retHash{"Cache"} )
      {
        my $str = ( split /:/, $line )[1];
        $retHash{"Cache"} = trimString($str);
      } elsif ( $line =~ /^cpu MHz/ && !$retHash{"Frequency"} )
      {
        my $str = ( split /:/, $line )[1];
        $retHash{"Frequency"} = trimString($str);
      } elsif ( $line =~ /^cpu cores/ && !$retHash{"Cores"} )
      {
        my $str = ( split /:/, $line )[1];
        $retHash{"Cores"} = trimString($str);
      }
    }
    $retHash{"#Processors"} = $no_of_processors;
  }
  return %retHash;
}

sub collectionutil_get_sleeping_tasks
{
  my @sleeping_tasks = ();
  my $cmd;
  my $text;
  if ($IS_WIN)
  {
  } elsif ($PLATFORM eq "aix") {
    $cmd = "$PS -eo user,wchan:80|$UNIQ -c|$HEAD -10";
    tfactlstore_summary_log( "command - $cmd", "collectionutil_get_sleeping_tasks" );
    $text = `$cmd`;
    my @txt_arr = split /\n/, $text;

    #print "CMD: $cmd\nTXT: $text\n";
    for (my $i = 1; $i <= $#txt_arr; $i++)
    { 
      my $line = $txt_arr[$i];
      my @tmp = ();
      $line = trimString($line);
      foreach my $x ( split /\s{1,}/, $line )
      {
        push @tmp, $x;
      }
      push @sleeping_tasks, \@tmp;
    }
  } else
  {
    $cmd  = "$PS -eo user,wchan|$SORT|$UNIQ -c|$SORT -k1,1 -rn|$HEAD -10";
    tfactlstore_summary_log( "command - $cmd", "collectionutil_get_sleeping_tasks" );
    $text = `$cmd`;

    #print "CMD: $cmd\nTXT: $text\n";
    foreach my $line ( split /\n/, $text )
    {
      my @tmp = ();
      $line = trimString($line);
      foreach my $x ( split /\s{1,}/, $line )
      {
        push @tmp, $x;
      }
      push @sleeping_tasks, \@tmp;
    }
  }
  return @sleeping_tasks;
}

sub collectionutil_get_top
{
  my %retHash;
  my $cmd;
  my $text;
  tfactlstore_summary_log( "command - os commands", "collectionutil_get_top" );
  if ($IS_WIN)
  {
    if ( !-e $WIN_TRANSFER_DIR )
    {
      eval { tfactlshare_mkpath("$WIN_TRANSFER_DIR", "1740") if ( ! -d "$WIN_TRANSFER_DIR" );  };
      if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $WIN_TRANSFER_DIR","collectionutil_get_top",1 ); }
    }
    my $powershell_file = catfile( $WIN_TRANSFER_DIR, "top.ps1" );
    my $POWERSHELL      = `where powershell`;
    my @retArr          = ();
    chomp($POWERSHELL);
    open( my $ps_fptr, '>', $powershell_file ) or die "Could not open file '$powershell_file' $!";
    print $ps_fptr "ps | sort -des cpu | select -f 15 | ft -a;";
    close $ps_fptr;
    my $text = `$POWERSHELL -command $powershell_file %USERNAME%`;

    #print "OP: $text\n";
    my @op_arr = split /\n/, $text;
    for ( my $i = 3 ; $i <= $#op_arr ; $i++ )
    {
      my %tmp;
      my $line = $op_arr[$i];
      $line =~ s/^\s{1,}//g;
      $tmp{'HANDLES'}      = ( split /\s{1,}/, $line )[0];
      $tmp{'NPM(K)'}       = ( split /\s{1,}/, $line )[1];
      $tmp{'PM(K)'}        = ( split /\s{1,}/, $line )[2];
      $tmp{'WS(K)'}        = ( split /\s{1,}/, $line )[3];
      $tmp{'VM(M)'}        = ( split /\s{1,}/, $line )[4];
      $tmp{'CPU(sec)'}     = ( split /\s{1,}/, $line )[5];
      $tmp{'ID'}           = ( split /\s{1,}/, $line )[6];
      $tmp{'PROCESS_NAME'} = ( split /\s{1,}/, $line )[7];
      push @retArr, \%tmp;
    }
    $retHash{'TOP_DETAILS'} = \@retArr;
  } elsif ($PLATFORM eq "aix") {
    ## Getting Memory Usage
    $cmd = "svmon -G | head -2|tail -1| awk {'print \$3'}";
    tfactlstore_summary_log( "command - $cmd", "collectionutil_get_top" );
    $text = `$cmd`;
    my $used_mem = $text / 256;

    $cmd = "lsattr -El sys0 -a realmem | awk {'print \$2'}";
    tfactlstore_summary_log( "command - $cmd", "collectionutil_get_top" );
    $text = `$cmd`;
    my $total_mem = $text / 1000;

    my $free_mem = $total_mem - $used_mem;
    my $percent_used = ($used_mem / $total_mem) * 100;

    my %temp;
    $temp{'USED MEMORY'} = ceil($used_mem) . " MB";
    $temp{'FREE MEMORY'} = ceil($free_mem) . " MB";
    $temp{'TOTAL MEMORY'} = ceil($total_mem) . " MB";
    $temp{'PERCENT USED'} = ceil($percent_used) . " %";

    $retHash{"MEMORY"} = \%temp;

    ## Getting Processor details and usage
    my %tmp;
    $cmd = "lparstat 2 10 | tail -10 | awk 'BEGIN {sum=0;} {sum+=\$4} END{print int(100-sum/10)}'";
    tfactlstore_summary_log( "command - $cmd", "collectionutil_get_top" );
    my $cpu_used = `$cmd`;
    chomp($cpu_used);
    $tmp{"%CPU USED"} = $cpu_used . " %";

    $cmd = "lparstat 2 10 | tail -1";
    tfactlstore_summary_log( "command - $cmd", "collectionutil_get_top" );
    my $text = `$cmd`;
    $text =~ s/^\s{1,}//g;

    $tmp{"%USER"} = (split /\s{1,}/, $text)[0];
    $tmp{"%SYS"} = (split /\s{1,}/, $text)[1];
    $tmp{"%WAIT"} = (split /\s{1,}/, $text)[2];
    $tmp{"%IDLE"} = (split /\s{1,}/, $text)[3];
    $tmp{"PHYSC"} = (split /\s{1,}/, $text)[4];
    $tmp{"%ENTC"} = (split /\s{1,}/, $text)[5];
    $tmp{"LBUSY"} = (split /\s{1,}/, $text)[6];
    $tmp{"APP"} = (split /\s{1,}/, $text)[7];
    $tmp{"VCSW"} = (split /\s{1,}/, $text)[8];
    $tmp{"PHINT"} = (split /\s{1,}/, $text)[9];

    $retHash{"CPU"} = \%tmp;
  } else
  {
    $cmd  = "export HOME=$SUMMARY_REPOSITORY/temp; /usr/bin/top -n 1 -b | head -5";
    $text = `$cmd`;
    $text =~ s/,\s{1,}load average:/,\nload average:/g;
    foreach my $line ( split /\n/, $text )
    {
      if ( $line =~ /load average:/ )
      {
        $line =~ s/load average://g;
        $line = trimString($line);
        my @tmp = ();
        foreach my $x ( split /,\s{1,}/, $line )
        {
          push @tmp, $x;
        }
        $retHash{"Average Load"} = \@tmp;
      } elsif ( $line =~ /Mem\s{1,}:/ )
      {
        $line =~ s/(KiB\s)?Mem\s{1,}://g;
        $line = trimString($line);
        my @tmp = ();
        my $total_mem;
        my $used_mem;
        my $free_mem;
        my $buffer_mem;
        foreach my $x ( split /,\s{1,}/, $line )
        {
          my $pushStr = "";
          if ( $x =~ /total/ )
          {
            $x =~ s/total//g;
            $x = trimString($x);
            $x =~ s/k//g;
            $total_mem = $x;
            $pushStr   = "Total:" . $total_mem . " KB";
          } elsif ( $x =~ /used/ )
          {
            $x =~ s/used//g;
            $x = trimString($x);
            $x =~ s/k//g;
            $used_mem = $x;
            $pushStr  = "Used:" . $used_mem . " KB";
          } elsif ( $x =~ /free/ )
          {
            $x =~ s/free//g;
            $x = trimString($x);
            $x =~ s/k//g;
            $free_mem = $x;
            $pushStr  = "Free:" . $free_mem . " KB";
          } elsif ( $x =~ /buffers/ || $x =~ /buff\/cache/ )
          {
            $x =~ s/(buffers|buff\/cache)//g;
            $x = trimString($x);
            $x =~ s/k//g;
            $buffer_mem = $x;
            $pushStr    = "Buffers:" . $buffer_mem . " KB";
          }
          push @tmp, $pushStr;
        }

        # print "( $used_mem / $total_mem ) * 100\n";
        my $percent_used_mem = "NA";
        $percent_used_mem = ( ( $used_mem * 100 ) / $total_mem ) if ( $total_mem != 0 );
        $percent_used_mem = sprintf "%.2f", $percent_used_mem;
        my $str = "Percent_Used: " . $percent_used_mem . " %";
        push @tmp, $str;
        $retHash{"Memory"} = \@tmp;
      } elsif ( $line =~ /Swap\s*:/ )
      {
        $line =~ s/(KiB\s)?Swap\s*://g;
        $line = trimString($line);
        my @tmp = ();
        my $total_swap;
        my $used_swap;
        my $free_swap;
        my $cached_swap;
        foreach my $x ( split /(,|\.)\s{1,}/, $line )
        {
          my $pushStr = "";
          if ( $x =~ /total/ )
          {
            $x =~ s/total//g;
            $x = trimString($x);
            $x =~ s/k//g;
            $total_swap = $x;
            $pushStr    = "Total:" . $total_swap . " KB";
          } elsif ( $x =~ /used/ )
          {
            $x =~ s/used//g;
            $x = trimString($x);
            $x =~ s/k//g;
            $used_swap = $x;
            $pushStr   = "Used:" . $used_swap . " KB";
          } elsif ( $x =~ /free/ )
          {
            $x =~ s/free//g;
            $x = trimString($x);
            $x =~ s/k//g;
            $free_swap = $x;
            $pushStr   = "Free:" . $free_swap . " KB";
          } elsif ( $x =~ /cached/ || $x =~ /avail Mem/ )
          {
            $x =~ s/(cached|avail Mem)//g;
            $x = trimString($x);
            $x =~ s/k//g;
            $cached_swap = $x;
            $pushStr     = "Cached:" . $cached_swap . " KB";
          }
          push @tmp, $pushStr;
        }
        my $percent_used_swap = "NA";
        $percent_used_swap = ( ( $used_swap * 100 ) / $total_swap ) if ( $total_swap != 0 );
        $percent_used_swap = sprintf "%.2f", $percent_used_swap;

        #                                $percent_used_swap = floor($percent_used_swap);
        my $str = "Percent_Used: " . $percent_used_swap . " %";
        push @tmp, $str;
        $retHash{"Swap"} = \@tmp;
      } elsif ( $line =~ /Cpu\(s\):/ )
      {
        $line =~ s/%?Cpu\(s\)://g;
        $line = trimString($line);
        my @tmp = ();
        foreach my $x ( split /,\s{1,}/, $line )
        {
          $x = trimString($x);
          $x =~ s/\s/%/g;
          push @tmp, $x;
        }
        $retHash{"CPU"} = \@tmp;
      } elsif ( $line =~ /Tasks:/ )
      {
        $line =~ s/Tasks://g;
        $line = trimString($line);
        my @tmp = ();
        my $total_task;
        my $running;
        my $sleeping;
        my $stopped;
        my $zombies;

        foreach my $x ( split /,\s{1,}/, $line )
        {
          my $pushStr = "";
          if ( $x =~ /total/ )
          {
            $x =~ s/total//g;
            $x          = trimString($x);
            $total_task = $x;
            $pushStr    = "Total:" . $total_task;
          } elsif ( $x =~ /running/ )
          {
            $x =~ s/running//g;
            $x       = trimString($x);
            $running = $x;
            $pushStr = "Running:" . $running;
          } elsif ( $x =~ /sleeping/ )
          {
            $x =~ s/sleeping//g;
            $x        = trimString($x);
            $sleeping = $x;
            $pushStr  = "Sleeping:" . $sleeping;
          } elsif ( $x =~ /stopped/ )
          {
            $x =~ s/stopped//g;
            $x       = trimString($x);
            $stopped = $x;
            $pushStr = "Stopped:" . $stopped;
          } elsif ( $x =~ /zombie/ )
          {
            $x =~ s/zombie//g;
            $x       = trimString($x);
            $zombies = $x;
            $pushStr = "Zombies:" . $zombies;
          }
          push @tmp, $pushStr;
        }
        $retHash{"Tasks"} = \@tmp;
      }
    }
  }
  return %retHash;
}

sub collectionutil_get_fdisk_details
{
  my $cmd;
  my $str;
  my %retHash;
  tfactlstore_summary_log( "command - os commands", "collectionutil_get_fdisk_details" );
  if ($IS_WIN)
  {
    if ( !-e $WIN_TRANSFER_DIR )
    {
      eval { tfactlshare_mkpath("$WIN_TRANSFER_DIR", "1740") if ( ! -d "$WIN_TRANSFER_DIR" );  };
      if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $WIN_TRANSFER_DIR","collectionutil_get_fdisk_details",1 ); }
    }
    my $diskpart_file = catfile( $WIN_TRANSFER_DIR, "diskpart" );
    my $DISKPART = `where diskpart`;
    chomp($DISKPART);
    ## LIST DISKS
    open( my $dp_fptr, '>', $diskpart_file ) or die "Could not open file '$diskpart_file' $!";
    print $dp_fptr "list disk";
    close($dp_fptr);
    my $cmd = "$DISKPART /s $diskpart_file";

    #print "CMD: $cmd\n";
    my $text = `$cmd`;

    #print "OP: $text\n";
    my @retArr = ();
    my @op_arr = split /\n/, $text;
    for ( my $i = 8 ; $i <= $#op_arr ; $i++ )
    {
      my %tmp;
      my $line = $op_arr[$i];
      $line =~ s/^\s{1,}//g;
      $tmp{'DISK#'}  = ( split /\s{2,}/, $line )[0];
      $tmp{'STATUS'} = ( split /\s{2,}/, $line )[1];
      $tmp{'SIZE'}   = ( split /\s{2,}/, $line )[2];
      $tmp{'FREE'}   = ( split /\s{2,}/, $line )[3];
      $tmp{'DYN'}    = ( split /\s{2,}/, $line )[4];
      $tmp{'GPT'}    = ( split /\s{2,}/, $line )[5];
      push @retArr, \%tmp;
    }
    $retHash{'DISKS'} = \@retArr;
    ## LIST PARTITIONS
    if ( $retHash{'DISKS'} )
    {
      my @disk_details = @{ $retHash{'DISKS'} };
      my %partitions;
      foreach my $disk (@disk_details)
      {
        my %hash     = %{$disk};
        my $diskname = $hash{'DISK#'};

        #print "DISK: $diskname\n";
        open( my $dp_fptr, '>', $diskpart_file ) or die "Could not open file '$diskpart_file' $!";
        print $dp_fptr "select $diskname\nlist partition";
        close($dp_fptr);
        my $text = `$DISKPART /s $diskpart_file`;

        #print "OP: $text\n";
        my @retArr = ();
        my @op_arr = split /\n/, $text;
        for ( my $i = 10 ; $i <= $#op_arr ; $i++ )
        {
          my %tmp;
          my $line = $op_arr[$i];
          $line =~ s/^\s{1,}//g;
          $tmp{'PARTITION#'} = ( split /\s{2,}/, $line )[0];
          $tmp{'TYPE'}       = ( split /\s{2,}/, $line )[1];
          $tmp{'SIZE'}       = ( split /\s{2,}/, $line )[2];
          $tmp{'OFFSET'}     = ( split /\s{2,}/, $line )[3];
          push @retArr, \%tmp;
        }
        $partitions{$diskname} = \@retArr;
      }
      $retHash{'PARTITIONS'} = \%partitions;
    }
    ## LIST VOLUME
    open( my $dp_fptr, '>', $diskpart_file ) or die "Could not open file '$diskpart_file' $!";
    print $dp_fptr "list volume";
    close($dp_fptr);
    my $text = `$DISKPART /s $diskpart_file`;

    #print "OP: $text\n";
    my @retArr = ();
    my @op_arr = split /\n/, $text;
    for ( my $i = 8 ; $i <= $#op_arr ; $i++ )
    {
      my %tmp;
      my $line = $op_arr[$i];
      $line =~ s/^\s{1,}//g;
      $tmp{'VOLUME#'}    = ( split /\s{2,}/, $line )[0];
      $tmp{'LETTER'}     = ( split /\s{2,}/, $line )[1];
      $tmp{'LABEL'}      = ( split /\s{2,}/, $line )[2];
      $tmp{'FILESYSTEM'} = ( split /\s{2,}/, $line )[3];
      $tmp{'TYPE'}       = ( split /\s{2,}/, $line )[4];
      $tmp{'SIZE'}       = ( split /\s{2,}/, $line )[5];
      $tmp{'STATUS'}     = ( split /\s{2,}/, $line )[6];
      $tmp{'INFO'}       = ( split /\s{2,}/, $line )[7];
      push @retArr, \%tmp;
    }
    $retHash{'VOLUMES'} = \@retArr;
    ## LIST VDISK
    open( my $dp_fptr, '>', $diskpart_file ) or die "Could not open file '$diskpart_file' $!";
    print $dp_fptr "list vdisk";
    close($dp_fptr);
    my $text = `$DISKPART /s $diskpart_file`;

    #print "OP: $text\n";
    if ( $text =~ /There are no virtual disks to show/ )
    {
      $retHash{'VDISKS'} = "NIL";
    } else
    {
      my @retArr = ();
      my @op_arr = split /\n/, $text;
      for ( my $i = 8 ; $i <= $#op_arr ; $i++ )
      {
        my %tmp;
        my $line = $op_arr[$i];
        $line =~ s/^\s{1,}//g;
        $tmp{'VDISK#'}     = ( split /\s{2,}/, $line )[0];    ## TODO: EDIT THE KEYS OF THE HASH
        $tmp{'LETTER'}     = ( split /\s{2,}/, $line )[1];
        $tmp{'LABEL'}      = ( split /\s{2,}/, $line )[2];
        $tmp{'FILESYSTEM'} = ( split /\s{2,}/, $line )[3];
        push @retArr, \%tmp;
      }
      $retHash{'VDISKS'} = \@retArr;
    }
    return %retHash;

  } elsif ($IS_SOLARIS) {
    $cmd = "$DF -lh";
    tfactlstore_summary_log( "command - $cmd", "collectionutil_get_fdisk_details" );
    $str = `$cmd`;
    
    my @lines = split(/\n|\n\s+/,$str);
    shift(@lines); #Get rid of heading..
    
    foreach my $line (@lines) {
      my %hash;
      my @cols = split(/\s+/,$line);
      $hash{"filesystem"} = $cols[0];
      $hash{"size"} = $cols[1];
      $hash{"used"} = $cols[2];
      $hash{"available"} =$cols[3];
      $hash{"used_percent"} =$cols[4];
      $hash{"mountpoint"} = $cols[5];
      
      $retHash{$cols[0]} = \%hash;
    }
    tfactlstore_summary_log( "command execution finished", "collectionutil_get_fdisk_details" );

    return %retHash;

  } elsif ($PLATFORM eq "aix") { 
    $cmd = "lsvg -o|lsvg -il";
    tfactlstore_summary_log( "command - $cmd", "collectionutil_get_fdisk_details" );
    $str = `$cmd`;
    my @strArr = split /\n/, $str;

    my $disknames = `lsvg -o`;
    for (my $i = 0; $i <= $#strArr; $i++) {
      my $line = $strArr[$i];
      my $disk;
      my @disk_details_arr = ();
      if ($line =~ /(.*):/) {
        $disk = $1;
        if ($disknames =~ /$disk/) {
          my $j;
          for ($j = $i + 2; $j <= $#strArr; $j++) {
            if ($strArr[$j] !~ /(.*):/) {
              my @arr =  split /\s{2,}/, $strArr[$j];
              my %tmp;

              $tmp{'LV_NAME'} = $arr[0];
              $tmp{'TYPE'} = $arr[1];
              $tmp{'LPs'} = $arr[2];
              $tmp{'PPs'} = $arr[3];
              $tmp{'PVs'} = $arr[4];
              $tmp{'LV_STATE'} = $arr[5];
              $tmp{'MOUNT_POINT'} = $arr[6];

              push @disk_details_arr, \%tmp;
            } else {
              last;
            }
          }
          $i = $j - 1;
          $retHash{$disk} = \@disk_details_arr;
        }
      }
    }
    tfactlstore_summary_log( "command execution finished", "collectionutil_get_fdisk_details" );
    return %retHash;

  } else {
    $cmd = "fdisk -l";
    $str = `$cmd`;
    my $disk_tables  = "";
    my $disk_details = "";
    my @strArr = split /\n/, $str;
    for ( my $i = 0 ; $i <= $#strArr ; $i++ )
    {
      if ( $strArr[$i] =~ /Device\s{1,}Boot\s{1,}Start\s{1,}End\s{1,}Blocks\s{1,}Id\s{1,}System/ )
      {
        my $j;
        for ( $j = $i + 1 ; $j <= $#strArr ; $j++ )
        {
          if ( ($IS_WIN) || ( $strArr[$j] =~ /^\// ) )
          {
            $disk_tables .= $strArr[$j] . "\n";
          } elsif ( $strArr[$j] =~ /Partition/ )
          {
          } else
          {
            last;
          }
        }
        $i = $j;
      } else
      {
        $disk_details .= $strArr[$i] . "\n";
      }
    }

    #print "===============DISK TABLES=============\n";
    #print "$disk_tables\n";
    #print "===============DISK DETAILS=============\n";
    #print "$disk_details\n";
    my %disk_tables_hash;
    foreach my $dt ( split /\n/, $disk_tables )
    {
      my %tmp;
      my @arr = split /\s{2,}/, $dt;
      if ( $#arr == 5 )
      {
        $tmp{'BOOT'}   = "NO";
        $tmp{'START'}  = $arr[1];
        $tmp{'END'}    = $arr[2];
        $tmp{'BLOCKS'} = $arr[3];
        $tmp{'ID'}     = $arr[4];
        $tmp{'SYSTEM'} = $arr[5];
      } elsif ( $arr[1] eq "*" )
      {
        $tmp{'BOOT'}   = "YES";
        $tmp{'START'}  = $arr[2];
        $tmp{'END'}    = $arr[3];
        $tmp{'BLOCKS'} = $arr[4];
        $tmp{'ID'}     = $arr[5];
        $tmp{'SYSTEM'} = $arr[6];
      }
      $disk_tables_hash{ $arr[0] } = \%tmp;
    }

    #foreach my $key (keys %disk_tables_hash) {
    #	print "DISK: $key :\n";
    #	foreach my $cat (keys %{$disk_tables_hash{$key}}) {
    #		print "$cat => ${$disk_tables_hash{$key}}{$cat}\n";
    #	}
    #	print "\n";
    #}
    my %disk_details_hash;
    foreach my $dd ( split /\n{2,}/, $disk_details )
    {
      my %tmp;
      my $disk_name;
      foreach my $line ( split /\n/, $dd )
      {
        if ( $line =~ /Disk identifier: (.*)/ )
        {
          $tmp{'IDENTIFIER'} = $1;
        } elsif ( $line =~ /Disk (.*): (.*), (.*) bytes/ )
        {
          $disk_name = $1;
          $tmp{'SIZE'} = $2;
        } elsif ( $line =~ /heads,/ && $line =~ /sectors\/track,/ && $line =~ /cylinders/ )
        {
          $tmp{'HEADS'}     = ( split /\s/, ( split /, /, $line )[0] )[0];
          $tmp{'SECTORS'}   = ( split /\s/, ( split /, /, $line )[1] )[0];
          $tmp{'CYLINDERS'} = ( split /\s/, ( split /, /, $line )[2] )[0];
        } elsif ( $line =~ /Units/ )
        {
          $tmp{'UNITS'} = ( split /\s/, ( split /\s=\s/, $line )[2] )[0];

          #	} elsif ($line =~ /Sector size \(logical\/physical\):/) {
          #		$tmp{'LOGI_SECTOR'} = (split /\s/, (split /\s\/\s/, (split /: /, $line)[1])[0])[0];
          #		$tmp{'PHYS_SECTOR'} = (split /\s/, (split /\s\/\s/, (split /: /, $line)[1])[1])[0];
        } elsif ( $line =~ /I\/O size \(minimum\/optimal\):/ )
        {
          $tmp{'MIN_IO'} = ( split /\s/, ( split /\s\/\s/, ( split /: /, $line )[1] )[0] )[0];
          $tmp{'OPT_IO'} = ( split /\s/, ( split /\s\/\s/, ( split /: /, $line )[1] )[1] )[0];
        }
      }
      $disk_details_hash{$disk_name} = \%tmp;
    }

    #foreach my $key (keys %disk_details_hash) {
    #	print "DISK: $key :\n";
    #	foreach my $cat (keys %{$disk_details_hash{$key}}) {
    #		print "$cat => ${$disk_details_hash{$key}}{$cat}\n";
    #	}
    #	print "\n";
    #}
    return ( \%disk_tables_hash, \%disk_details_hash );
  }
  print "here 0\n";
}
##=============== OS FUNCTIONS =====================================================
##=============== LISTENER FUNCTIONS ================================================
sub collectionutil_get_listener_details
{
  my $running_dbs_ref = shift;
  my $is_crs_up       = collectionutil_check_crs_state();
  my @oracle_homes;
  if ( $is_crs_up == 1 )
  {
    # @oracle_homes = ();
    my $crs_home = collectionutil_get_crs_home();
    push @oracle_homes, $crs_home;
  } else
  {
    foreach my $db_home_name ( keys %{$running_dbs_ref} )
    {
      my %running_dbs = %{ $running_dbs_ref->{$db_home_name} };
      my $ref         = collectionutil_getRunningDB_homes( \%running_dbs );
      push( @oracle_homes, @{$ref} );
    }
  }
  my $cmd;
  my $str;
  my @listener_details;
  my $count = 1;
  foreach my $oracle_home (@oracle_homes)
  {
    $ENV{ORACLE_HOME} = $oracle_home;
    if ($IS_WIN)
    {
      $cmd = catfile( $oracle_home, "bin", "LSNRCTL.EXE" ) . " status";
    } else
    {
      $cmd = catfile( $oracle_home, "bin", "lsnrctl" ) . " status";
    }
    $str = `$cmd`;
    my @listener;
    my @service;
    my @instance;
    my $endpoints;
    my @endpoints;
    foreach my $line ( split /\n/, $str )
    {

      if ( $line =~ /^Alias/ )
      {
        push( @listener, { "STATUS_TYPE" => 'ALIAS', "DETAILS" => ( split /\s{2,}/, $line )[1] } );
      } elsif ( $line =~ /^Version/ )
      {
        my $x = ( split /:\s/, ( split /\s{2,}/, $line )[1] )[1];
        if ( $x =~ /Version (.*) - Production/ )
        {
          push( @listener, { "STATUS_TYPE" => 'VERSION', "DETAILS" => $1 . " " } );
        }
      } elsif ( $line =~ /^Start Date/ )
      {
        push( @listener, { "STATUS_TYPE" => 'START_DATE', "DETAILS" => ( split /\s{2,}/, $line )[1] } );
      } elsif ( $line =~ /^Uptime/ )
      {
        push( @listener, { "STATUS_TYPE" => 'UPTIME', "DETAILS" => ( split /\s{2,}/, $line )[1] } );
      } elsif ( $line =~ /^Trace Level/ )
      {
        push( @listener, { "STATUS_TYPE" => 'TRACE_LEVEL', "DETAILS" => ( split /\s{2,}/, $line )[1] } );
      } elsif ( $line =~ /^Security/ )
      {
        push( @listener, { "STATUS_TYPE" => 'SECURITY', "DETAILS" => ( split /\s{2,}/, $line )[1] } );
      } elsif ( $line =~ /^SNMP/ )
      {
        push( @listener, { "STATUS_TYPE" => 'SNMP', "DETAILS" => ( split /\s{2,}/, $line )[1] } );
      } elsif ( $line =~ /^Listener Parameter File/ )
      {
        push( @listener, { "STATUS_TYPE" => 'PARAMETER_FILE', "DETAILS" => ( split /\s{2,}/, $line )[1] } );
      } elsif ( $line =~ /^Listener Log File/ )
      {
        push( @listener, { "STATUS_TYPE" => 'LOGFILE', "DETAILS" => ( split /\s{2,}/, $line )[1] } );
      } elsif (     $endpoints eq "true"
                and $line =~ /\(DESCRIPTION=\(ADDRESS=\(PROTOCOL=(.*)\)\(HOST=(.*)\)\(PORT=(.*)\)\)\)/ )
      {
        $endpoints = "true";
        push( @endpoints, { 'PROTOCOL' => $1, 'HOST' => $2, 'PORT' => $3 } );
      } elsif ( $line =~ /Endpoints Summary/ )
      {
        $endpoints = "true";
      } elsif ( $line =~ /^Service "(.*)" has (.*) instance/ )
      {
        push( @service, { 'SERVICE' => $1, 'INSTANCES' => $2 } );
      } elsif ( $line =~ /\s+Instance "(.*)", status (.*), has (.*) handler/ )
      {
        push( @instance, { 'INSTANCE' => $1, 'STATUS' => $2, 'HANDLER' => $3 } );
      }
    }
    push( @listener,         { "STATUS_TYPE" => 'ENDPOINTS',        "DETAILS"          => \@endpoints } );
    push( @listener,         { "STATUS_TYPE" => 'ORACLE_HOME',      "DETAILS"          => $oracle_home } );
    push( @listener,         { "STATUS_TYPE" => 'SERVICE_DETAILS',  "DETAILS"          => \@service } );
    push( @listener,         { "STATUS_TYPE" => 'INSTANCE_DETAILS', "DETAILS"          => \@instance } );
    push( @listener_details, { 'SL_NO'       => $count++,           "LISTENER_DETAILS" => \@listener } );
  }
  return \@listener_details;
}

sub collectionutil_check_service_registered
{
  my $tns      = shift;
  my $crs_home = collectionutil_get_crs_home();
  my @retArr   = ();
  if ($crs_home)
  {
    $ENV{ORACLE_HOME} = $crs_home;
    $ENV{LD_LIBRARY_PATH} = catdir( $ENV{ORACLE_HOME}, "lib" );
    my $crs_owner;
    my $cmd;
    my $text;
    if ($IS_WIN)
    {
      $cmd = catfile( $crs_home, "BIN", "LSNRCTL.EXE" ) . " service $tns";
    } else
    {
      $crs_owner = `ps -ef|grep asm_pmon| grep -v grep|awk {'print $1'}`;
      $cmd       = catfile( $crs_home, "bin", "lsnrctl" ) . " service $tns";
      $text      = `$cmd`;
    }
    tfactlstore_summary_log( "COMMAND: $cmd", "collectionutil_check_service_registered" );
    $text = `$cmd`;
    my $scnt              = 0;
    my $services          = "";
    my $cnt               = 0;
    my $ready_instances   = "";
    my $ucnt              = 0;
    my $unknown_instances = "";

    foreach my $line ( split /\n/, $text )
    {
      if ( $line =~ /Service [A-Za-z0-9]* has/ )
      {
        $scnt++;
        $services = $services . $line . "\n";
      } elsif ( $line =~ /Instance [A-Za-z0-9]* status READY/ )
      {
        $cnt++;
        $ready_instances = $ready_instances . $line . "\n";
      } elsif ( $line =~ /Instance [A-Za-z0-9]* status UNKNOWN/ )
      {
        $ucnt++;
        $unknown_instances = $unknown_instances . $line . "\n";
      }
    }
    if ( $ucnt != 0 )
    {
      push @retArr, "check_unknown_registration:WARNING";
      push @retArr, "unknown_registration_list:$unknown_instances";
    } elsif ( $scnt == 0 )
    {
      push @retArr, "check_services:WARNING";
    } elsif ( $scnt < 7 )
    {
      push @retArr, "check_services_count:OK";
      push @retArr, "services_list:$services";
    } else
    {
      push @retArr, "check_services_count:OK";
    }
  }
  return @retArr;
}

sub collectionutil_check_tns_status
{
  my $cmd;
  my $host     = tolower_host();
  my $crs_home = collectionutil_get_crs_home();
  if ($IS_WIN)
  {
    $cmd = catfile( $crs_home, "BIN", "crsctl.exe" ) . " stat res";
  } else
  {
    $cmd = catfile( $crs_home, "bin", "crsctl" ) . " stat res";
  }
  my $text = `$cmd`;
  my $listener_resource_name;
  my $listener_name;
  my @listener_details;
  foreach my $line ( split /\n/, $text )
  {
    if ( $line =~ /lsnr/ )
    {
      my %listener;
      $listener_resource_name = ( split /=/,  $line )[1];
      $listener_name          = ( split /\./, $listener_resource_name )[1];

      #print "1. $listener_resource_name\n2. $listener_name\n";
      $listener{'RESOURCE'} = $listener_resource_name;
      if ($IS_WIN)
      {
        $cmd = catfile( $crs_home, "BIN", "crsctl.exe" ) . " stat res " . $listener_resource_name;
      } else
      {
        $cmd = catfile( $crs_home, "bin", "crsctl" ) . " stat res " . $listener_resource_name;
      }
      my $text1 = `$cmd`;
      foreach my $x ( split /\n/, $text1 )
      {
        if ( $x =~ /STATE/ )
        {
          if ( $x =~ /ONLINE on $host/ )
          {
            $listener{'STATUS'} = "OK";
            my @retArr = collectionutil_check_service_registered($listener_name);
            foreach my $x (@retArr)
            {
              $listener{'SERVICE_REGISTRATION'} = $x;
            }
          } else
          {
            $listener{'STATUS'}               = "OK";
            $listener{'SERVICE_REGISTRATION'} = "-";
          }
        }
      }
      $listener{'NAME'} = $listener_name;
      push( @listener_details, \%listener );
    }
  }
  return \@listener_details;
}
##=============== LISTENER FUNCTIONS =====================================================
##=============== NETWORK FUNCTIONS =====================================================
sub collectionutil_get_interface_details
{
  my $crs_home = collectionutil_get_crs_home();
  my $cmd;
  my $str;
  my $oifcfg;
  my %retHash;
  if ($crs_home)
  {
    if ($IS_WIN)
    {
      $oifcfg = catfile( $crs_home, "bin", "oifcfg.exe" );
    } else
    {
      $oifcfg = catfile( $crs_home, "bin", "oifcfg" );
    }
    $cmd = "$oifcfg  getif";
    $str = `$cmd`;

    #$str =~ s/\s+/:/g;
    $retHash{'INTERFACE_DETAILS'} = transformToStandardOutput($str);
    $cmd                          = "$oifcfg  iflist";
    $str                          = `$cmd`;

    #$str =~ s/\s+/:/g;
    $retHash{'INTERFACE_LIST'} = transformToStandardOutput($str);
  }
  return %retHash;
}

sub collectionutil_get_cluvfy_details
{
  my $crs_home = collectionutil_get_crs_home();
  my $host     = tolower_host();
  my $cmd;
  my $str;
  my $cluvfy;
  my %retHash;
  if ($crs_home)
  {
    my $crs_user = collectionutil_get_crs_user();
    if ($IS_WIN)
    {
      $cluvfy = catfile( $crs_home, "BIN", "cluvfy.bat" );
      $cmd = "$cluvfy stage -post crsinst -n $host -verbose";
    } else
    {
      $cluvfy = catfile( $crs_home, "bin", "cluvfy" );
      $cmd = "su $crs_user -c \"$cluvfy stage -post crsinst -n $host -verbose\"";
    }

    # print "CMD: $cmd\n";
    $str = `$cmd`;

    # print "STR: $str\n";
    my $tcp_scan_conn_flag = 0;
    foreach my $line ( split /\n/, $str )
    {
      if ( $line =~ /Result: Node reachability check (.*) from node \"(.*)\"/ )
      {
        my $node = $2;
        my @tmp;
        if ( $retHash{'NODE_REACHABILITY'} )
        {
          @tmp = @{ $retHash{'NODE_REACHABILITY'} };
        } else
        {
          @tmp = ();
        }
        if ( $1 =~ /passed/ )
        {
          push @tmp, "NODE $node : PASS";
        } else
        {
          push @tmp, "NODE $node : FAIL";
        }
        $retHash{'NODE_REACHABILITY'} = \@tmp;
      } elsif ( $line =~ /Check for equivalence of user \"(.*)\" from node \".*\" to node \".*\" (.*)/ )
      {
        my $user = $1;
        my @tmp;
        if ( $retHash{'USER_EQUIVALENCE'} )
        {
          @tmp = @{ $retHash{'USER_EQUIVALENCE'} };
        } else
        {
          @tmp = ();
        }
        if ( $2 =~ /passed/ )
        {
          push @tmp, "USER $user : PASS";
        } else
        {
          push @tmp, "USER $user : FAIL";
        }
        $retHash{'USER_EQUIVALENCE'} = \@tmp;
      } elsif ( $line =~ /Result: User equivalence check (.*) for user \"(.*)\"/ )
      {
        my $user = $2;
        my @tmp;
        if ( $retHash{'USER_EQUIVALENCE'} )
        {
          @tmp = @{ $retHash{'USER_EQUIVALENCE'} };
        } else
        {
          @tmp = ();
        }
        if ( $1 =~ /passed/ )
        {
          push @tmp, "USER $user : PASS";
        } else
        {
          push @tmp, "USER $user : FAIL";
        }
        $retHash{'USER_EQUIVALENCE'} = \@tmp;
      } elsif ( $line =~ /Result: Node connectivity (.*) for interface \"(.*)\"/ )
      {
        my $interface = $2;
        my @tmp;
        if ( $retHash{'NODE_CONNECTIVITY'} )
        {
          @tmp = @{ $retHash{'NODE_CONNECTIVITY'} };
        } else
        {
          @tmp = ();
        }
        if ( $1 =~ /passed/ )
        {
          push @tmp, "INTERFACE $interface : PASS";
        } else
        {
          push @tmp, "INTERFACE $interface : FAIL";
        }
        $retHash{'NODE_CONNECTIVITY'} = \@tmp;
      } elsif ( $line =~ /Result: TCP connectivity check (.*) for subnet \"(.*)\"/ )
      {
        my $subnet = $2;
        my @tmp;
        if ( $retHash{'TCP_CONNECTIVITY'} )
        {
          @tmp = @{ $retHash{'TCP_CONNECTIVITY'} };
        } else
        {
          @tmp = ();
        }
        if ( $1 =~ /passed/ )
        {
          push @tmp, "SUBNET $subnet : PASS";
        } else
        {
          push @tmp, "SUBNET $subnet : FAIL";
        }
        $retHash{'TCP_CONNECTIVITY'} = \@tmp;
      } elsif ( $line =~ /Check of subnet \"(.*)\" for multicast communication with multicast group \"(.*)\" (.*)./ )
      {
        my $subnet = $1;
        my $group  = $2;
        my @tmp;
        if ( $retHash{'MULTICAST_COMMUNICATION'} )
        {
          @tmp = @{ $retHash{'MULTICAST_COMMUNICATION'} };
        } else
        {
          @tmp = ();
        }
        if ( $3 =~ /passed/ )
        {
          push @tmp, "GROUP $group : SUBNET $subnet : PASS";
        } else
        {
          push @tmp, "GROUP $group : SUBNET $subnet : FAIL";
        }
        $retHash{'MULTICAST_COMMUNICATION'} = \@tmp;
      } elsif ( $line =~ /Result: Time zone consistency check (.*)/ )
      {
        if ( $1 =~ /passed/ )
        {
          $retHash{'TIME_ZONE_CONSISTENCY'} = "PASS";
        } else
        {
          $retHash{'TIME_ZONE_CONSISTENCY'} = "FAIL";
        }
      } elsif ( $line =~ /Oracle Cluster Voting Disk configuration check (.*)/ )
      {
        if ( $1 =~ /passed/ )
        {
          $retHash{'CLUSTER_VOTING_DISK_CONFIG'} = "PASS";
        } else
        {
          $retHash{'CLUSTER_VOTING_DISK_CONFIG'} = "FAIL";
        }
      } elsif ( $line =~ /(.*) node application (check|is) (.*)/ )
      {
        my $app = $1;
        my @tmp;
        if ( $retHash{'NODE_APPLICATION_CHECK'} )
        {
          @tmp = @{ $retHash{'NODE_APPLICATION_CHECK'} };
        } else
        {
          @tmp = ();
        }
        if ( $3 =~ /passed/ )
        {
          push @tmp, "$app : PASS";
        } elsif ( $3 =~ /offline/ )
        {
          push @tmp, "$app : FAIL";
        }
        $retHash{'NODE_APPLICATION_CHECK'} = \@tmp;
      } elsif ( $line =~ /^Checking TCP connectivity to SCAN Listeners.../ || $tcp_scan_conn_flag == 1 )
      {
        if ( $line !~ /^TCP connectivity to SCAN Listeners/ )
        {
          $tcp_scan_conn_flag = 1;
          my %tmp;
          my @array = ();
          if ( $line =~ /$host/ )
          {
            $tmp{'LISTENER_NAME'}         = ( split /\s{1,}/, $line )[1];
            $tmp{'SCAN_TCP_CONNECTIVITY'} = ( split /\s{1,}/, $line )[2];
            push @array, \%tmp;
          }
          $retHash{'SCAN_TCP_CONNECTIVITY'} = \@array;
        } elsif ( $line =~ /^TCP connectivity to SCAN Listeners/ )
        {
          $tcp_scan_conn_flag = 0;
        }
      } elsif ( $line =~ /^OLR config file check (.*)/ )
      {
        if ( $1 =~ /successful/ )
        {
          $retHash{'OLR_CONFIG_FILE_CHECK'} = "SUCCESS";
        } else
        {
          $retHash{'OLR_CONFIG_FILE_CHECK'} = "FAIL";
        }
      } elsif ( $line =~ /^OLR file check (.*)/ )
      {
        if ( $1 =~ /successful/ )
        {
          $retHash{'OLR_FILE_ATTRIBUTES_CHECK'} = "SUCCESS";
        } else
        {
          $retHash{'OLR_FILE_ATTRIBUTES_CHECK'} = "FAIL";
        }
      } elsif ( $line =~ /^OLR integrity check (.*)/ )
      {
        if ( $1 =~ /passed/ )
        {
          $retHash{'OLR_INTEGRITY_CHECK'} = "PASS";
        } else
        {
          $retHash{'OLR_INTEGRITY_CHECK'} = "FAIL";
        }
      } elsif ( $line =~ /^Result: CTSS resource check (.*)/ )
      {
        if ( $1 =~ /passed/ )
        {
          $retHash{'CTSS_RESOURCE_CHECK'} = "PASS";
        } else
        {
          $retHash{'CTSS_RESOURCE_CHECK'} = "FAIL";
        }
      } elsif ( $line =~ /^CTSS is in (.*) state./ )
      {
        $retHash{'CTSS_STATE'} = $1;
      } elsif ( $line =~ /^NTP Configuration file check (.*)/ )
      {
        if ( $1 =~ /passed/ )
        {
          $retHash{'NTP_CONFIGURATION_CHECK'} = "PASS";
        } else
        {
          $retHash{'NTP_CONFIGURATION_CHECK'} = "FAIL";
        }
      } elsif ( $line =~ /^Check for NTP daemon or service alive (.*) on (.*) nodes/ )
      {
        if ( $1 =~ /passed/ )
        {
          $retHash{'NTP_DAEMON_SERVICE_ALIVE_CHECK'} = "PASS";
        } else
        {
          $retHash{'NTP_DAEMON_SERVICE_ALIVE_CHECK'} = "FAIL";
        }
      } elsif ( $line =~ /^Check for NTP daemon or service alive (.*) on (.*) nodes/ )
      {
        if ( $1 =~ /passed/ )
        {
          $retHash{'NTP_DAEMON_SERVICE_ALIVE_CHECK'} = "PASS";
        } else
        {
          $retHash{'NTP_DAEMON_SERVICE_ALIVE_CHECK'} = "FAIL";
        }
      } elsif ( $line =~ /^NTP daemon slewing option check (.*) on (.*) nodes/ )
      {
        if ( $1 =~ /passed/ )
        {
          $retHash{'NTP_DAEMON_SLEW_OPTION_CHECK'} = "PASS";
        } else
        {
          $retHash{'NTP_DAEMON_SLEW_OPTION_CHECK'} = "FAIL";
        }
      } elsif ( $line =~ /^Check for VIP Subnet configuration (.*)./ )
      {
        if ( $1 =~ /passed/ )
        {
          $retHash{'VIP_SUBNET_CONFIGURATION'} = "PASS";
        } else
        {
          $retHash{'VIP_SUBNET_CONFIGURATION'} = "FAIL";
        }
      } elsif ( $line =~ /^Check for VIP reachability (.*)./ )
      {
        if ( $1 =~ /passed/ )
        {
          $retHash{'VIP_REACHABILITY'} = "PASS";
        } else
        {
          $retHash{'VIP_REACHABILITY'} = "FAIL";
        }
      }
    }
  }

  #foreach my $x (keys %retHash) {
  #	print "$x => $retHash{$x}\n";
  #}
  return \%retHash;
}

sub collectionutil_get_ocrcheck_details
{
  my $crs_home = collectionutil_get_crs_home();
  my $host     = tolower_host();
  my $cmd;
  my $str;
  my $ocrcheck;
  my %retHash;
  if ($crs_home)
  {

    if ($IS_WIN)
    {
      $ocrcheck = catfile( $crs_home, "bin", "ocrcheck.exe" );
    } else
    {
      $ocrcheck = catfile( $crs_home, "bin", "ocrcheck" );
    }
    $cmd = "$ocrcheck -local";
    $str = `$cmd`;
    foreach my $line ( split /\n/, $str )
    {
      if ( $line =~ /Version/ )
      {
        $retHash{'VERSION'} = ( split /\s{1,}:\s{1,}/, $line )[1];
      } elsif ( $line =~ /Total space \(kbytes\)/ )
      {
        $retHash{'TOTAL_SPACE'} = ( split /\s{1,}:\s{1,}/, $line )[1] . " KB";
      } elsif ( $line =~ /Used space \(kbytes\)/ )
      {
        $retHash{'USED_SPACE'} = ( split /\s{1,}:\s{1,}/, $line )[1] . " KB";
      } elsif ( $line =~ /Available space \(kbytes\)/ )
      {
        $retHash{'AVAILABLE_SPACE'} = ( split /\s{1,}:\s{1,}/, $line )[1] . " KB";
      } elsif ( $line =~ /ID/ )
      {
        $retHash{'ID'} = ( split /\s{1,}:\s{1,}/, $line )[1];
      } elsif ( $line =~ /Device\/File Name/ )
      {
        $retHash{'DEVICE_FILE_NAME'} = ( split /\s{1,}:\s{1,}/, $line )[1];
      } elsif ( $line =~ /Device\/File integrity check (.*)/ )
      {
        if ( $1 =~ /succeeded/ )
        {
          $retHash{'DEVICE_FILE_INTEGRITY_CHECK'} = "SUCCESS";
        } else
        {
          $retHash{'DEVICE_FILE_INTEGRITY_CHECK'} = "FAIL";
        }
      } elsif ( $line =~ /Local registry integrity check (.*)/ )
      {
        if ( $1 =~ /succeeded/ )
        {
          $retHash{'DEVICE_FILE_INTEGRITY_CHECK'} = "SUCCESS";
        } else
        {
          $retHash{'DEVICE_FILE_INTEGRITY_CHECK'} = "FAIL";
        }
      } elsif ( $line =~ /Logical corruption check (.*)/ )
      {
        if ( $1 =~ /succeeded/ )
        {
          $retHash{'LOGICAL_CORRUPTION_CHECK'} = "SUCCESS";
        } else
        {
          $retHash{'LOGICAL_CORRUPTION_CHECK'} = "FAIL";
        }
      }
    }
  }
  return \%retHash;
}
##=============== NETWORK FUNCTIONS =====================================================
##=============== COLLECTION FUNCTIONS =====================================================
sub collectionutil_SortByDirectory
{
  my $arrayRef   = shift;
  my @filesArray = @{$arrayRef};
  my %dirHash;
  my $filename;
  my $dirname;
  foreach my $file (@filesArray)
  {
    #print "FILE: $file\n";
    my @tmp = split /\|/, $file;

    #$name . "|" . $size . "|" . $lastMod . "|" . $type . "|" . $comp
    $filename = basename( $tmp[0] );
    $dirname  = dirname( $tmp[0] );

    #print "DIR: $dirname -> FILE: $filename\n";
    if ( !exists $dirHash{$dirname} )
    {
      my @tmpArr = ();
      push @tmpArr, $filename . "|" . $tmp[1] . "|" . $tmp[2] . "|" . $tmp[3] . "|" . $tmp[4];
      $dirHash{$dirname} = [@tmpArr];

      #print "-> DIR: " . $dirname . " ADDRESS0: " . $dirHash{$dirname} . "\n";
    } else
    {
      #print "* DIR: " . $dirname . " ADDRESS1: " . $dirHash{$dirname} . "\n";
      push @{ $dirHash{$dirname} }, $filename . "|" . $tmp[1] . "|" . $tmp[2] . "|" . $tmp[3] . "|" . $tmp[4];
    }
  }
  return %dirHash;
}

sub collectionutil_SortByExtension
{
  my $arrayRef   = shift;
  my @filesArray = @{$arrayRef};
  my %extHash;
  my $extension;
  foreach my $file (@filesArray)
  {
    #print "FILE: $file\n";
    my @tmp = split /\|/, $file;

    #$name . "|" . $size . "|" . $lastMod . "|" . $type . "|" . $comp
    $extension = $tmp[3];

    #print "EXTENSION: $extension\n";
    if ( !exists $extHash{$extension} )
    {
      my @tmpArr = ();
      push @tmpArr, $file;
      $extHash{$extension} = [@tmpArr];

      #print "-> EXT: " . $extension . " ADDRESS0: " . $extHash{$extension} . "\n";
    } else
    {
      #print "* EXT: " . $extension . " ADDRESS1: " . $extHash{$extension} . "\n";
      push @{ $extHash{$extension} }, $file;
    }
  }
  return %extHash;
}

sub collectionutil_SortByComponent
{
  my $arrayRef   = shift;
  my @filesArray = @{$arrayRef};
  my %compHash;
  my $component;
  foreach my $file (@filesArray)
  {
    #print "FILE: $file\n";
    my @tmp = split /\|/, $file;

    #$name . "|" . $size . "|" . $lastMod . "|" . $type . "|" . $comp
    $component = $tmp[4];

    #print "COMPONENT: $component\n";
    if ( !exists $compHash{$component} )
    {
      my @tmpArr = ();
      push @tmpArr, $file;
      $compHash{$component} = [@tmpArr];

      #print "-> COMP: " . $component . " ADDRESS0: " . $compHash{$extension} . "\n";
    } else
    {
      #print "* COMP: " . $component . " ADDRESS1: " . $compHash{$extension} . "\n";
      push @{ $compHash{$component} }, $file;
    }
  }
  return %compHash;
}

sub collectionutil_getExtension
{
  my $filename = shift;
  if ( $filename =~ /\./ )
  {
    my @tmp = split /\./, $filename;

    #print "FILE: $filename -> EXT: $tmp[-1]\n";
    return $tmp[-1];
  } else
  {
    my $retStr = "null";
    return $retStr;
  }
}

sub collectionutil_parseXMLCollection
{
  my $xmlFile         = shift;
  my @xmlFileCont_arr = readFileToArray($xmlFile);
  my @fileList;
  my $name;
  my $size;
  my $lastMod;
  my $type;
  my $comp;
  my $count = 0;

  foreach my $line (@xmlFileCont_arr)
  {
    if ( $line =~ /<file_name>/ )
    {
      my $tmp = $line;
      $tmp =~ s/<file_name>//g;
      $tmp =~ s/<\/file_name>//g;
      chomp($tmp);
      $name = $tmp;
      $count++;
    }
    if ( $line =~ /<file_type>/ )
    {
      my $tmp = $line;
      $tmp =~ s/<file_type>//g;
      $tmp =~ s/<\/file_type>//g;
      chomp($tmp);
      $type = $tmp;
      $count++;
    }
    if ( $line =~ /<size>/ )
    {
      my $tmp = $line;
      $tmp =~ s/<size>//g;
      $tmp =~ s/<\/size>//g;
      chomp($tmp);
      $size = $tmp;
      $count++;
    }
    if ( $line =~ /<last_modified>/ )
    {
      my $tmp = $line;
      $tmp =~ s/<last_modified>//g;
      $tmp =~ s/<\/last_modified>//g;
      chomp($tmp);
      $lastMod = $tmp;
      $count++;
    }
    if ( $line =~ /<component>/ )
    {
      my $tmp = $line;
      $tmp =~ s/<component>//g;
      $tmp =~ s/<\/component>//g;
      chomp($tmp);
      $comp = $tmp;
      $count++;
    }
    if ( $count == 5 )
    {
      push @fileList, $name . "|" . $size . "B |" . $lastMod . "|" . $type . "|" . $comp;
      $count = 0;
    }
  }
  return @fileList;
}

sub collectionutil_getCollectionName
{
  my $directory   = shift;
  my $hostname    = tolower_host();
  my $filePattern = "diagcollect_[0-9]*_" . $hostname;

  #print "FILE PATTERN: $filePattern\nDIR: $directory\n";
  opendir( DIR, $directory );
  my @files = grep( /^$filePattern/, readdir(DIR) );
  closedir(DIR);
  my $collectionName;
  my @tmp = readFileToArray( catfile( $directory, $files[0] ) );
  foreach my $line (@tmp)
  {

    if ( $line =~ /Collection Name/ )
    {
      my @tmp1 = split /:/, $line;
      $collectionName = $tmp1[-1];
      chomp($collectionName);
      $collectionName =~ s/^ //g;
      $collectionName =~ s/\.zip//g;
    }
  }

  #print "Coll Name: $collectionName\n";
  if ($collectionName)
  {
    return $collectionName;
  } else
  {
    return -1;
  }
}

sub collectionutil_getTFAVersion
{
  my $collectionName = shift;
  my $directory      = shift;
  my $hostname       = tolower_host();
  my $fileName       = $hostname . "." . $collectionName . ".zip.txt";
  my @tmp            = readFileToArray( catfile( $directory, $fileName ) );
  my $tfaVersion;
  foreach my $line (@tmp)
  {

    if ( $line =~ /TFA Version/ )
    {
      my @tmp1 = split /:/, $line;
      $tfaVersion = $tmp1[-1];
      chomp($tfaVersion);
      $tfaVersion =~ s/^ //g;
    }
  }

  #print "TFA Version: $tfaVersion\n";
  if ($tfaVersion)
  {
    return $tfaVersion;
  } else
  {
    return -1;
  }
}

sub collectionutil_getTFABuildID
{
  my $collectionName = shift;
  my $directory      = shift;
  my $hostname       = tolower_host();
  my $fileName       = $hostname . "." . $collectionName . ".zip.txt";
  my @tmp            = readFileToArray( catfile( $directory, $fileName ) );
  my $tfaBuildID;
  foreach my $line (@tmp)
  {

    if ( $line =~ /Build ID/ )
    {
      my @tmp1 = split /:/, $line;
      $tfaBuildID = $tmp1[-1];
      chomp($tfaBuildID);
      $tfaBuildID =~ s/^ //g;
    }
  }

  #print "Build ID: $tfaBuildID\n";
  if ($tfaBuildID)
  {
    return $tfaBuildID;
  } else
  {
    return -1;
  }
}

sub collectionutil_getComponentsCollected
{
  my $collectionName = shift;
  my $directory      = shift;
  my $hostname       = tolower_host();
  my $fileName       = $hostname . "." . $collectionName . ".zip.txt";
  my @tmp            = readFileToArray( catfile( $directory, $fileName ) );
  my $components;
  foreach my $line (@tmp)
  {

    if ( $line =~ /Component\(s\) in zip file/ )
    {
      my @tmp1 = split /:/, $line;
      $components = $tmp1[-1];
      chomp($components);
      $components =~ s/^ //g;
    }
  }

  #print "COMP: $components\n";
  if ($components)
  {
    return $components;
  } else
  {
    return -1;
  }
}

sub collectionutil_getCollDuration
{
  my $directory   = shift;
  my $hostname    = tolower_host();
  my $filePattern = "diagcollect_[0-9]*_" . $hostname;

  #print "FILE PATTERN: $filePattern\nDIR: $directory\n";
  opendir( DIR, $directory );
  my @files = grep( /^$filePattern/, readdir(DIR) );
  closedir(DIR);
  my @tmp = readFileToArray( catfile( $directory, $files[0] ) );
  my $collDur;
  foreach my $line (@tmp)
  {

    if ( $line =~ /Total time taken/ )
    {
      my @tmp1 = split /:/, $line;
      $collDur = $tmp1[-1];
      chomp($collDur);
      $collDur =~ s/^ //g;
    }
  }

  #print "COLL DUR: $collDur\n";
  if ($collDur)
  {
    return $collDur;
  } else
  {
    return -1;
  }
}

sub collectionutil_getZipSize
{
  my $directory   = shift;
  my $hostname    = tolower_host();
  my $filePattern = "diagcollect_[0-9]*_" . $hostname;

  #print "FILE PATTERN: $filePattern\nDIR: $directory\n";
  opendir( DIR, $directory );
  my @files = grep( /^$filePattern/, readdir(DIR) );
  closedir(DIR);
  my @tmp = readFileToArray( catfile( $directory, $files[0] ) );
  my $zipSize;
  foreach my $line (@tmp)
  {

    if ( $line =~ /Zip file size/ )
    {
      my @tmp1 = split /:/, $line;
      $zipSize = $tmp1[-1];
      chomp($zipSize);
      $zipSize =~ s/^ //g;
    }
  }

  #print "Zip Size: $zipSize\n";
  if ($zipSize)
  {
    return $zipSize;
  } else
  {
    return -1;
  }
}

sub collectionutil_getDiagnosticsDuration
{
  my $collectionName = shift;
  my $directory      = shift;
  my $hostname       = tolower_host();
  my $fileName       = $hostname . "." . $collectionName . ".zip.txt";
  my @tmp            = readFileToArray( catfile( $directory, $fileName ) );
  my $startDate;
  my $endDate;
  for ( my $i = 0 ; $i < $#tmp ; $i++ )
  {

    if ( $tmp[$i] =~ /Duration of Diagnostics/ )
    {
      if ( $tmp[ $i + 1 ] =~ /Start date/ )
      {
        $startDate = $tmp[ $i + 1 ];
        chomp($startDate);
        $startDate =~ s/^\s+Start date : //g;
      }
      if ( $tmp[ $i + 2 ] =~ /End date/ )
      {
        $endDate = $tmp[ $i + 2 ];
        chomp($endDate);
        $endDate =~ s/^\s+End date : //g;
      }
      next;
    }
  }

  #print "Diag Dur: $startDate $endDate\n";
  if ( $startDate && $endDate )
  {
    my $retStr = $startDate . "->" . $endDate;
    return $retStr;
  } else
  {
    return -1;
  }
}
##=============== COLLECTION FUNCTIONS =====================================================
##=============== ACFS FUNCTIONS =====================================================
sub collectionutil_is_acfs_configured
{
  my $command;
  my $acfsutil_file;
  if ($IS_WIN)
  {
    my $crs_home = collectionutil_get_crs_home();
    if ($crs_home)
    {
      $acfsutil_file = catfile( $crs_home, "BIN", "acfsutil.exe" );
      $command = $acfsutil_file . " info fs";
    } else
    {
      return 0;
    }
  } else
  {
    $acfsutil_file = catfile( "", "sbin", "acfsutil" );
    $command = $acfsutil_file . " info fs";
  }

  #print "CMD: $command\n";

  if (-e $acfsutil_file) {
    my $str = `$command 2>&1`;
    if ( $str =~ /Failed to communicate with the ACFS driver/ || $str =~ /ACFS-03036/ )
    {
      return 0;
    } else
    {
      return 1;
    }
  } else {
    return 0;
  }
}

sub collectionutil_get_acfs_info
{
  my $command;
  my %acfs_info;
  my $crs_home = collectionutil_get_crs_home();
  if ($IS_WIN)
  {
    if ($crs_home)
    {
      $command = catfile( $crs_home, "BIN", "acfsutil.exe" ) . " info fs";
    } else
    {
      return \%acfs_info;
    }
  } else
  {
    $command = catfile( "", "sbin", "acfsutil" ) . " info fs";
  }

  #print "CMD: $command\n";
  my $str              = `$command 2>&1`;
  my @str_arr          = split /\n/, $str;
  my @primary_vol_info = ();
  my $filesystem_name;
  my %tmp;
  for ( my $i = 0 ; $i <= $#str_arr ; )
  {

    if ( $str_arr[$i] =~ /(\\|\/)/ )
    {
      #print "line: $str_arr[$i]\n";
      if ( $str_arr[$i] =~ /^\s{1,}primary volume:/ )
      {
        my %tmp1;
        $tmp1{'VOLUME_NAME'} = ( split /:\s{1,}/, $str_arr[$i] )[1];
        my $j;
        for ( $j = $i ; $j <= $i + 13 ; $j++ )
        {
          $str_arr[$j] =~ s/^\s{1,}//g;
          my $key   = ( split /:\s{1,}/, $str_arr[$j] )[0];
          my $value = ( split /:\s{1,}/, $str_arr[$j] )[1];
          $tmp1{$key} = $value;
        }
        $i = $j;
        push @primary_vol_info, \%tmp1;
      } else
      {
        $filesystem_name = $str_arr[$i];
        $i               = $i + 1;
      }
    } else
    {
      $str_arr[$i] =~ s/^\s{1,}//g;
      my $key   = ( split /:\s{1,}/, $str_arr[$i] )[0];
      my $value = ( split /:\s{1,}/, $str_arr[$i] )[1];
      $tmp{$key} = $value;
      $i = $i + 1;
    }
  }
  $tmp{'PRIMARY_VOLUME'} = \@primary_vol_info;
  $acfs_info{$filesystem_name} = \%tmp;
  return \%acfs_info;
}

sub collectionutil_get_acfs_volume_info
{
  my $command;
  my @acfs_vol_info = ();
  my $crs_home      = collectionutil_get_crs_home();
  if ($IS_WIN)
  {
    if ($crs_home)
    {
      $command = catfile( $crs_home, "BIN", "advmutil.exe" ) . " volinfo";
    } else
    {
      return \@acfs_vol_info;
    }
  } else
  {
    $command = catfile( "", "sbin", "advmutil" ) . " volinfo";
  }
  print "CMD: $command\n";
  my $str = `$command`;
  my @str_arr = split /\n/, $str;
  my $filesystem_name;
  my %tmp;
  for ( my $i = 0 ; $i <= $#str_arr ; )
  {

    if ( $str_arr[$i] =~ "^Device:" )
    {
      $tmp{'device'} = ( split /:\s{1,}/, $str_arr[$i] )[1];
      my %tmp;
      my $j;
      for ( $j = $i + 1 ; $j <= $i + 9 ; $j++ )
      {
        my $key   = ( split /:\s{1,}/, $str_arr[$j] )[0];
        my $value = ( split /:\s{1,}/, $str_arr[$j] )[1];
        $tmp{$key} = $value;
      }
      push @acfs_vol_info, \%tmp;
      $i = $j;
    } else
    {
      $i = $i + 1;
    }
  }
  return \@acfs_vol_info;
}

sub collectionutil_get_asm_acfs_volume_sql
{
  my $asm_instance = collectionutil_get_asm_instance();
  my $asm_home     = collectionutil_get_asm_home();
  my $asm_user     = collectionutil_get_crs_user();
  my $asm_acfs_volumes = run_a_sql(
    $asm_home,
    $asm_instance,
"set feedback  off heading off lines 120\nselect FS_NAME||'!'||VOL_DEVICE||'!'||VOL_LABEL||'!'||TOTAL_MB||'!'||FREE_MB from V\$ASM_ACFSVOLUMES;\nquit\n",
    "sysasm"
  );
  $asm_acfs_volumes = transformToStandardOutput($asm_acfs_volumes);
  my @retArr = ();
  foreach my $line ( split /\n/, $asm_acfs_volumes )
  {
    my %tmp;
    my @line_arr = split /!/, $line;
    $tmp{'FS_NAME'}    = $line_arr[0];
    $tmp{'VOL_DEVICE'} = $line_arr[1];
    $tmp{'VOL_LABEL'}  = $line_arr[2];
    $tmp{'TOTAL_MB'}   = $line_arr[3];
    $tmp{'FREE_MB'}    = $line_arr[4];
    push @retArr, \%tmp;
  }
  my %retHash;
  $retHash{'ASM_ACFS_VOLUME_DETAILS'} = \@retArr;
  return \%retHash;
}

sub collectionutil_get_acfs_filesystem_sql
{
  my $asm_instance = collectionutil_get_asm_instance();
  my $asm_home     = collectionutil_get_asm_home();
  my $asm_user     = collectionutil_get_crs_user();
  my $acfs_filesystem = run_a_sql(
    $asm_home,
    $asm_instance,
"set feedback  off heading off lines 120\nselect FS_NAME||'!'||AVAILABLE_TIME||'!'||BLOCK_SIZE||'!'||STATE||'!'||CORRUPT||'!'||NUM_VOL||'!'||TOTAL_SIZE||'!'||TOTAL_FREE||'!'||TOTAL_SNAP_SPACE_USAGE from V\$ASM_FILESYSTEM;\nquit\n",
    "sysasm"
  );
  $acfs_filesystem = transformToStandardOutput($acfs_filesystem);
  my $acfs_info = collectionutil_get_acfs_info();
  my @status;
  my @stats;
  my @vertical_display;
  my $count = 0;

  foreach my $line ( split /\n/, $acfs_filesystem )
  {
    my @line_arr = split /!/, $line;
    my %status;
    $status{'FS_NAME'}     = $line_arr[0];
    $status{'MOUNT_TIME'}  = $line_arr[1];
    $status{'STATE'}       = $line_arr[3];
    $status{'CORRUPT'}     = $line_arr[4];
    $status{'REPLICATION'} = $acfs_info->{ $line_arr[0] }->{'replication status'};
    $status{'ENCR'}        = $acfs_info->{ $line_arr[0] }->{'Encryption status'};
    $status{'VERSION'}     = "$acfs_info->{$line_arr[0]}->{'ACFS Version'}";
    push( @status, \%status );
    my %stats;
    $stats{'FS_NAME'}    = $line_arr[0];
    $stats{'NUM_VOL'}    = $line_arr[5] . " ";
    $status{'BLK_SIZE'}  = $line_arr[2];
    $stats{'TOTAL_SIZE'} = $line_arr[6];
    $stats{'TOTAL_FREE'} = floor( $line_arr[7] );
    $stats{'SNAPSHOTS'}  = $line_arr[8];
    my $percent;

    if ( $line_arr[6] != 0 )
    {
      $percent = int( ( ( $line_arr[7] * 100 ) / $line_arr[6] ) );
    }
    $stats{'SIZE_STATUS'} = $percent . "\% Available";
    push( @stats, \%stats );
    $count++;
    push( @vertical_display, { 'STATUS_TYPE' => 'FS_NAME',    'DETAILS' => $line_arr[0] } );
    push( @vertical_display, { 'STATUS_TYPE' => 'MOUNT_TIME', 'DETAILS' => $line_arr[1] } );
    push( @vertical_display, { 'STATUS_TYPE' => 'STATE',      'DETAILS' => $line_arr[3] } );
    push( @vertical_display, { 'STATUS_TYPE' => 'CORRUPT',    'DETAILS' => $line_arr[4] } );
    push( @vertical_display,
          { 'STATUS_TYPE' => 'REPLICATION', 'DETAILS' => $acfs_info->{ $line_arr[0] }->{'replication status'} } );
    push( @vertical_display,
          { 'STATUS_TYPE' => 'ENCRIPTION', 'DETAILS' => $acfs_info->{ $line_arr[0] }->{'Encryption status'} } );
    push( @vertical_display,
          { 'STATUS_TYPE' => 'VERSION', 'DETAILS' => $acfs_info->{ $line_arr[0] }->{'ACFS Version'} } );
    push( @vertical_display, { 'STATUS_TYPE' => 'NUM_VOL',     'DETAILS' => $line_arr[5] . " " } );
    push( @vertical_display, { 'STATUS_TYPE' => 'BLK_SIZE',    'DETAILS' => $line_arr[2] } );
    push( @vertical_display, { 'STATUS_TYPE' => 'TOTAL_SIZE',  'DETAILS' => $line_arr[6] } );
    push( @vertical_display, { 'STATUS_TYPE' => 'TOTAL_FREE',  'DETAILS' => floor( $line_arr[7] ) } );
    push( @vertical_display, { 'STATUS_TYPE' => 'SNAPSHOTS',   'DETAILS' => $line_arr[8] } );
    push( @vertical_display, { 'STATUS_TYPE' => 'SIZE_STATUS', 'DETAILS' => $percent . "\% Available" } );
  }
  my @retArr;
  push( @retArr, { 'STATUS_TYPE' => 'FS_STATUS',    'DETAILS' => \@status } );
  push( @retArr, { 'STATUS_TYPE' => 'FS_STATISTIC', 'DETAILS' => \@stats } );
  if ( $count == 1 )
  {
    return \@vertical_display;
  } else
  {
    return \@retArr;
  }
}

sub collectionutil_get_asm_volume_sql
{
  my $asm_instance = collectionutil_get_asm_instance();
  my $asm_home     = collectionutil_get_asm_home();
  my $asm_user     = collectionutil_get_crs_user();
  my $acfs_volumes = run_a_sql(
    $asm_home,
    $asm_instance,
"set feedback  off heading off lines 120\nselect GROUP_NUMBER||'!'||VOLUME_NAME||'!'||COMPOUND_INDEX||'!'||SIZE_MB||'!'||VOLUME_NUMBER||'!'||REDUNDANCY||'!'||STRIPE_COLUMNS||'!'||STRIPE_WIDTH_K||'!'||STATE||'!'||FILE_NUMBER||'!'||INCARNATION||'!'||DRL_FILE_NUMBER||'!'||RESIZE_UNIT_MB||'!'||USAGE||'!'||VOLUME_DEVICE||'!'||MOUNTPATH from V\$ASM_VOLUME;\nquit\n",
    "sysasm"
  );
  $acfs_volumes = transformToStandardOutput($acfs_volumes);
  my @vol_status;
  my @vol_stats;
  foreach my $line ( split /\n/, $acfs_volumes )
  {
    my %tmp;
    my @line_arr = split /!/, $line;
    my %vol_status;
    $vol_status{'NAME'}        = $line_arr[1];
    $vol_status{'GROUP'}       = $line_arr[4];
    $vol_status{'STATE'}       = $line_arr[8];
    $vol_status{'DEVICE'}      = $line_arr[14];
    $vol_status{'REDUNDANCY'}  = $line_arr[5];
    $vol_status{'INCARNATION'} = $line_arr[10];
    $vol_status{'USAGE'}       = $line_arr[13];
    $vol_status{'SIZE_MB'}     = $line_arr[3];
    $vol_status{'MOUNTPATH'}   = $line_arr[15];
    push( @vol_status, \%vol_status );
    my %vol_stats;
    $vol_stats{'NAME'}            = $line_arr[1];
    $vol_stats{'FILE_NUMBER'}     = $line_arr[9];
    $vol_stats{'STRIPE_COLUMNS'}  = $line_arr[6];
    $vol_stats{'STRIPE_WIDTH_K'}  = $line_arr[7];
    $vol_stats{'DRL_FILE_NUMBER'} = $line_arr[11];
    $vol_stats{'RESIZE_UNIT_MB'}  = $line_arr[12];
    $vol_stats{'COMPOUND_INDEX'}  = $line_arr[2];
    $vol_stats{'GROUP_NUMBER'}    = $line_arr[0];
    push( @vol_stats, \%vol_stats );
  }
  my @io_stats = @{ collectionutil_get_asm_volume_stat_sql() };
  my @retArr;
  push( @retArr, { 'STATUS_TYPE' => 'VOLUME_STATUS', 'DETAILS' => \@vol_status } );
  push( @retArr, { 'STATUS_TYPE' => 'VOLUME_STATS',  'DETAILS' => \@vol_stats } );
  push( @retArr, { 'STATUS_TYPE' => 'IO_STATS',      'DETAILS' => \@io_stats } );
  return \@retArr;
}

sub collectionutil_get_asm_volume_stat_sql
{
  my $asm_instance = collectionutil_get_asm_instance();
  my $asm_home     = collectionutil_get_asm_home();
  my $asm_user     = collectionutil_get_crs_user();
  my $acfs_volumes_stat = run_a_sql(
    $asm_home,
    $asm_instance,
"set feedback  off heading off lines 120\nselect GROUP_NUMBER||'!'||VOLUME_NAME||'!'||COMPOUND_INDEX||'!'||VOLUME_NUMBER||'!'||READS||'!'||WRITES||'!'||READ_ERRS||'!'||WRITE_ERRS||'!'||READ_TIME||'!'||WRITE_TIME||'!'||BYTES_READ||'!'||BYTES_WRITTEN from V\$ASM_VOLUME_STAT;\nquit\n",
    "sysasm"
  );
  $acfs_volumes_stat = transformToStandardOutput($acfs_volumes_stat);
  my @retArr;
  foreach my $line ( split /\n/, $acfs_volumes_stat )
  {
    my %tmp;
    my @line_arr = split /!/, $line;

    #$tmp{'GROUP_NUMBER'} = $line_arr[0];
    $tmp{'VOLUME_NAME'} = $line_arr[1];

    #$tmp{'COMPOUND_INDEX'} = $line_arr[2];
    #$tmp{'VOLUME_NUMBER'} = $line_arr[3];
    $tmp{'READS'}         = $line_arr[4];
    $tmp{'WRITES'}        = $line_arr[5];
    $tmp{'READ_ERRS'}     = $line_arr[6];
    $tmp{'WRITE_ERRS'}    = $line_arr[7];
    $tmp{'READ_TIME'}     = $line_arr[8];
    $tmp{'WRITE_TIME'}    = $line_arr[9];
    $tmp{'BYTES_READ'}    = $line_arr[10];
    $tmp{'BYTES_WRITTEN'} = $line_arr[11];
    push @retArr, \%tmp;
  }
  return \@retArr;
}
##=============== ACFS FUNCTIONS =====================================================
##=============== TFA FUNCTIONS =====================================================
sub collectionutil_get_tfa_status
{
  my $localhost  = tolower_host();
  my $message    = "$localhost:checkTFAStatus";
  my $command    = buildCLIJava( $tfa_home, $message );
  my @retArr     = tfactlshare_runClient($command);
  my @tfa_status = ();
  if ( $retArr[1] eq "Connection refused" )
  {
    my %tmp;
    $tmp{'HOST'}   = $localhost;
    $tmp{'STATUS'} = "NOT RUNNING";
    push @tfa_status, \%tmp;
  }
  foreach my $line (@retArr)
  {
    if ( $line =~ /Check/ )
    {
      my %tmp;
      my ( $output, $hostname, $tfapid, $tfaport, $tfaversion, $tfabuildid, $invrunstatus ) = split( /!/, $line );
      if ( $output eq "CheckOK" )
      {
        $output = "RUNNING";
      }
      if ( $output eq "CheckFAIL" )
      {
        $output = "NOT RUNNING";
      }
      $tmp{'HOST'}                 = $hostname;
      $tmp{'STATUS'}               = $output;
      $tmp{'PID'}                  = $tfapid;
      $tmp{'PORT'}                 = $tfaport;
      $tmp{'VERSION'}              = $tfaversion;
      $tmp{'BUILDID'}              = $tfabuildid;
      $tmp{'INVENTORY_RUN_STATUS'} = $invrunstatus;
      push @tfa_status, \%tmp;
    }
  }
  return \@tfa_status;
}

sub collectionutil_get_tfa_directories
{
  my $localhost       = tolower_host();
  my $message         = "$localhost:printdirectories";
  my $command         = buildCLIJava( $tfa_home, $message );
  my @retArr          = tfactlshare_runClient($command);
  my @tfa_directories = ();
  if ( $retArr[1] eq "Connection refused" )
  {
    push( @tfa_directories, { 'ERROR' => "Connection refused" } );
    return \@tfa_directories;
  }
  if ( grep /TFA is not yet secured to run all commands/, @retArr )
  {
    push( @tfa_directories, { 'ERROR' => "TFA is not yet secured to run all commands" } );
    return \@tfa_directories;
  }
  foreach my $line (@retArr)
  {
    my ( $dirpath, $hostname, $component, $permission, $owner, $collectionpolicy, $collectall ) = split( /!/, $line );
    if ( $line !~ /DONE/ )
    {
      my %tmp;
      $tmp{'HOST'}       = $hostname;
      $tmp{'DIRECTORY'}  = $dirpath;
      $tmp{'COMPONENT'}  = $component;
      $tmp{'PERMISSION'} = $permission;
      $tmp{'OWNER'}      = $owner;
      $tmp{'POLICY'}     = $collectionpolicy;
      $tmp{'COLLECTALL'} = $collectall;
      push @tfa_directories, \%tmp;
    }
  }
  return \@tfa_directories;
}

sub collectionutil_get_tfa_repository
{
  my $localhost      = tolower_host();
  my $message        = "$localhost:printrepository";
  my $command        = buildCLIJava( $tfa_home, $message );
  my @retArr         = tfactlshare_runClient($command);
  my @tfa_repository = ();
  if ( $retArr[1] eq "Connection refused" )
  {
    push( @tfa_repository, { 'ERROR' => "Connection refused" } );
    return \@tfa_repository;
  }
  if ( grep /TFA is not yet secured to run all commands/, @retArr )
  {
    push( @tfa_repository, { 'ERROR' => "TFA is not yet secured to run all commands" } );
    return \@tfa_repository;
  }
  foreach my $line (@retArr)
  {
    my ( $rloc, $rmaxmb, $rcurmb, $rcurb, $status, $rhost ) = split( /!/, $line );
    if ( $line !~ /DONE/ )
    {
      my %tmp;
      my $freespace = 0;
      if ( $rmaxmb >= $rcurmb )
      {
        $freespace = $rmaxmb - $rcurmb;
      }
      $tmp{'HOST'}             = $rhost;
      $tmp{'LOCATION'}         = $rloc;
      $tmp{'MAXIMUM_SIZE(MB)'} = $rmaxmb;
      $tmp{'CURRENT_SIZE(MB)'} = $rcurmb;
      $tmp{'FREE_SPACE'}       = $freespace;
      $tmp{'STATUS'}           = $status;
      push @tfa_repository, \%tmp;
    }
  }
  return \@tfa_repository;
}

sub collectionutil_get_tfa_config
{
  my $localhost  = tolower_host();
  my $message    = "$localhost:printconfig:node=all~name=all";
  my $command    = buildCLIJava( $tfa_home, $message );
  my @retArr     = tfactlshare_runClient($command);
  my @tfa_config = ();
  if ( $retArr[1] eq "Connection refused" )
  {
    push( @tfa_config, { 'ERROR' => "Connection refused" } );
    return \@tfa_config;
  }
  if ( grep /TFA is not yet secured to run all commands/, @retArr )
  {
    push( @tfa_config, { 'ERROR' => "TFA is not yet secured to run all commands" } );
    return \@tfa_config;
  }
  my %configMap = ();
  $configMap{"tfaversion"}                   = "TFA Version";
  $configMap{"javaVersion"}                  = "Java Version";
  $configMap{"firezipsinrt"}                 = "Automatic Diagnostic Collection";
  $configMap{"rtscan"}                       = "Alert Log Scan";
  $configMap{"publicIp"}                     = "Public IP Network";
  $configMap{"diskUsageMon"}                 = "Disk Usage Monitor";
  $configMap{"manageLogsAutoPurge"}          = "Managelogs Auto Purge";
  $configMap{"trimmingon"}                   = "Trimming of files during diagcollection";
  $configMap{"currentsizemegabytes"}         = "Repository current size (MB)";
  $configMap{"maxsizemegabytes"}             = "Repository maximum size (MB)";
  $configMap{"inventorytracelevel"}          = "Inventory Trace level";
  $configMap{"collectiontracelevel"}         = "Collection Trace level";
  $configMap{"scantracelevel"}               = "Scan Trace level";
  $configMap{"othertracelevel"}              = "Other Trace level";
  $configMap{"maxlogSize"}                   = "Max Size of TFA Log (MB)";
  $configMap{"maxlogcount"}                  = "Max Number of TFA Logs";
  $configMap{"maxcorefilesize"}              = "Max Size of Core File (MB)";
  $configMap{"maxcorecollectionsize"}        = "Max Collection Size of Core Files (MB)";
  $configMap{"minSpaceForRTScan"}            = "Minimum Free Space to enable Alert Log Scan (MB)";
  $configMap{"diskUsageMonInterval"}         = "Time interval between consecutive Disk Usage Snapshot(minutes)";
  $configMap{"manageLogsAutoPurgeInterval"}  = "Time interval between consecutive Managelogs Auto Purge(minutes)";
  $configMap{"manageLogsAutoPurgePolicyAge"} = "Logs older than the time period will be auto purged(days[d]|hours[h])";
  $configMap{"autopurge"}                    = "Automatic Purging";
  $configMap{"minfileagetopurge"}            = "Age of Purging Collections (Hours)";

  #$configMap{"language"} = "Language";
  #$configMap{"encoding"} = "Encoding";
  #$configMap{"country"} = "Country";
  #$configMap{"AlertLogLevel"} = "AlertLogLevel";
  #$configMap{"UserLogLevel"} = "UserLogLevel";
  #$configMap{"BaseLogPath"} = "BaseLogPath";
  $configMap{"tfaIpsPoolSize"} = "TFA IPS Pool Size";
  foreach my $line (@retArr)
  {
    my $hostname;
    if ( $line !~ /DONE/ )
    {
      my @tmp;
      foreach my $comp ( split /!/, $line )
      {
        my $key   = ( split /=/, $comp )[0];
        my $value = ( split /=/, $comp )[1];
        if ( $key =~ /host/ )
        {
          $hostname = $value;
        } elsif ( $configMap{$key} )
        {
          push @tmp, { "PARAMETER" => $configMap{$key}, "VALUE" => $value };
        }
      }
      push @tfa_config, { "HOSTNAME" => $hostname, "DETAILS" => \@tmp };
    }
  }
  return \@tfa_config;
}
##=============== TFA FUNCTIONS =====================================================
##=============== EXADATA FUNCTIONS =====================================================
sub collectionutil_get_hardware_model_exadata
{
  my $cmd;
  my $product_name;
  my $model;
  my $bondtype;
  my %retHash;
  if ($IS_WIN)
  {
  } else
  {
    $cmd = "/usr/sbin/dmidecode | grep \"Product Name\" | head -1 | awk -F\":\" '{print \$2}' | sed -e 's/^ //g'";
  }
  $product_name = `$cmd`;
  if ( $product_name =~ /X4800/ || $product_name =~ /X[45]-8/ )
  {
    $model = "X8";
    if ( $product_name =~ /X[45]-8/ )
    {
      $bondtype = "AA";
    } else
    {
      $bondtype = "AB";
    }
  } elsif ( $product_name =~ /X4170/ || $product_name =~ /X[45]-2/ )
  {
    $model = "X2";
    if ( $product_name =~ /X[45]-2/ )
    {
      $bondtype = "AA";
    } else
    {
      $bondtype = "AB";
    }
  }
  $retHash{'PRODUCT_NAME'} = $product_name;
  $retHash{'MODEL'}        = $model;
  $retHash{'BONDTYPE'}     = $bondtype;
  return \%retHash;
}

sub collectionutil_get_cell_names
{
  my $filename;
  my $retStr = "";
  if ($IS_WIN)
  {
  } else
  {
    $filename = catfile( "", "root", "cell_group" );
    if (!-f $filename) {
    	$filename = catfile("","etc","oracle","cell","network-config","cellip.ora");
    }
  }

  if (-f $filename) {
	  my @cell_list = readFileToArray($filename);
	  foreach my $cell (@cell_list)
	  {
	  	$cell =~ s/cell=//g;
	    chomp($cell);
	    $retStr .= $cell . ",";
	  }
	  chop $retStr;
	  tfactlstore_summary_log( "Registered Cells: $retStr", "collectionutil_get_cell_names" );
  } else {
  	tfactlstore_summary_log( "[WARNING]: Cell list not found", "collectionutil_get_cell_names" );
  }
  return $retStr;
}

sub collectionutil_get_cell_status
{
  my $CELL_LIST = shift;
  my $command;
  my %retHash;
  if ($CELL_LIST)
  {
    if ($IS_WIN)
    {
    } else
    {
#		$command = "dcli -l root -g $CELL_LIST \"service celld status |grep -c \\\"running\$\\\"|awk '!/3/ { print \"fail\"} /3/ { print \"ok\"}'\" ";
      $command = "dcli -l root -c $CELL_LIST \"service celld status\"";
    }
    tfactlstore_summary_log( "Command: $command", "collectionutil_get_cell_status" );
    my $str = `$command`;
    foreach my $line ( split /\n/, $str )
    {
      my $cell    = ( split /:\s{1,}/, $line )[0];
      my $service = ( split /:\s{1,}/, $line )[1];
      my $status  = ( split /:\s{1,}/, $line )[2];
      $retHash{$cell}{$service} = $status;
    }
  }

  #   my @cell_status;
  #   foreach my $cell ( keys %retHash ) {
  #     my $status = $retHash{$cell};
  #     $status->{SSH_CELL} = $cell;
  #     push(@cell_status, $status );
  #   }
  #	return \@cell_status;
  return \%retHash;
}

sub collectionutil_get_cell_lun_status
{
  my $CELL_LIST = shift;
  my $command;
  my %retHash;
  if ($CELL_LIST)
  {
    if ($IS_WIN)
    {
    } else
    {
      #			$command = "dcli -l root -g $CELL_LIST \"cellcli -e  list lun attributes disktype,status|sort|uniq -c\"";
      $command = "dcli -l root -c $CELL_LIST \"cellcli -e  list lun attributes disktype,status\" |sort|uniq -c";
    }
    my $str = `$command`;
    foreach my $line ( split /\n/, $str )
    {
      $line =~ s/^\s+//g;
      my ( $cell,     $luns )   = split /: /,     $line;
      my ( $num,      $cell )   = split /\s+/,    $cell;
      my ( $lun_type, $status ) = split /\s{1,}/, $luns;
      $retHash{$cell}{"${lun_type}-${num}"} = $status;
    }
  }

  #my @lun_status;
  #foreach my $cell ( keys %retHash ) {
  #  my $status = $retHash{$cell};
  #  $status->{SSH_CELL} = $cell;
  #  push(@lun_status, $status );
  #}
  #return \@lun_status;
  return \%retHash;
}

sub collectionutil_get_cell_grid_disk_status
{
  my $CELL_LIST = shift;
  my $command;
  my %retHash;
  if ($CELL_LIST)
  {
    if ($IS_WIN)
    {
    } else
    {
#$command = "dcli -l root -g $CELL_LIST \"cellcli -e 'list griddisk attributes asmmodestatus,asmdeactivationoutcome,status'|sort|uniq -c\"";
      $command =
"dcli -l root -c $CELL_LIST \"cellcli -e 'list griddisk attributes asmmodestatus,asmdeactivationoutcome,status'|sort|uniq -c\"";
    }
    my $str = `$command`;
    foreach my $line ( split /\n/, $str )
    {
      $line =~ s/^\s+//g;
      my ( $cell, $diskstatus ) = split /: /, $line;
      my ( $GRIDDISKS, $ASM_NODE_STATUS, $ASM_DEACTIVATION_OUTCOME, $STATUS ) = split /\s+/, $diskstatus;
      $retHash{$cell}{'#GRIDDISKS'}               = $GRIDDISKS;
      $retHash{$cell}{'ASM_NODE_STATUS'}          = $ASM_NODE_STATUS;
      $retHash{$cell}{'ASM_DEACTIVATION_OUTCOME'} = $ASM_DEACTIVATION_OUTCOME;
      $retHash{$cell}{'STATUS'}                   = $STATUS;
    }
  }

  #my @griddisk_status;
  #foreach my $cell ( keys %retHash ) {
  #  my $status = $retHash{$cell};
  #  $status->{SSH_CELL} = $cell;
  #  push(@griddisk_status, $status );
  #}
  #return \@griddisk_status;
  return \%retHash;
}

sub collectionutil_get_iostat_details
{
  my %retHash;
  my @get_iostat_details;
  my $cmd;
  if ($IS_WIN)
  {
  } else
  {
    $cmd = "iostat";
  }

  #print "CMD: $cmd\n";
  my $str = `$cmd`;
  my @str_arr = split /\n/, $str;
  for ( my $i = 0 ; $i <= $#str_arr ; )
  {
    if ( $i == 0 )
    {
      my @system_details = split /\s{2,}/, $str_arr[$i];
      my $cpus = $1 if ( $system_details[2] =~ /\((.*) CPU\)/ );
      push( @get_iostat_details, { "STATUS_TYPE" => "KERNEL_VERSION", "DETAILS" => $system_details[0] } );
      push( @get_iostat_details, { "STATUS_TYPE" => "NUMBER_OF_CPU",  "DETAILS" => $cpus . " " } );
      $i += 1;
    } elsif ( $str_arr[$i] =~ /^avg-cpu:/ )
    {
      $str_arr[ $i + 1 ] =~ s/^\s{1}//g;
      my @avg_cpu = split /\s{1,}/, $str_arr[ $i + 1 ];
      my %tmp;
      $tmp{'%USER'}   = $avg_cpu[0];
      $tmp{'%NICE'}   = $avg_cpu[1];
      $tmp{'%SYSTEM'} = $avg_cpu[2];
      $tmp{'%IOWAIT'} = $avg_cpu[3];
      $tmp{'%STEAL'}  = $avg_cpu[4];
      $tmp{'%IDLE'}   = $avg_cpu[5];

      #	$retHash{'AVERAGE_CPU_USAGE'} = \%tmp;
      push( @get_iostat_details, { "STATUS_TYPE" => "AVERAGE_CPU_USAGE", "DETAILS" => [ \%tmp ] } );
      $i += 1;
    } elsif ( $str_arr[$i] =~ /^Device:/ )
    {
      my $j;
      my @device_iostat_arr = ();
      for ( $j = $i + 1 ; $j <= $#str_arr ; $j++ )
      {
        my %tmp;
        $tmp{'DEVICE'}   = ( split /\s{1,}/, $str_arr[$j] )[0];
        $tmp{'RRQM/S'}   = ( split /\s{1,}/, $str_arr[$j] )[1];
        $tmp{'WRQM/S'}   = ( split /\s{1,}/, $str_arr[$j] )[2];
        $tmp{'R/S'}      = ( split /\s{1,}/, $str_arr[$j] )[3];
        $tmp{'W/S'}      = ( split /\s{1,}/, $str_arr[$j] )[4];
        $tmp{'RSEC/S'}   = ( split /\s{1,}/, $str_arr[$j] )[5];
        $tmp{'WSEC/S'}   = ( split /\s{1,}/, $str_arr[$j] )[6];
        $tmp{'AVGRQ-SZ'} = ( split /\s{1,}/, $str_arr[$j] )[7];
        $tmp{'AVGQU-SZ'} = ( split /\s{1,}/, $str_arr[$j] )[8];
        $tmp{'AWAIT'}    = ( split /\s{1,}/, $str_arr[$j] )[9];
        $tmp{'SVCTM'}    = ( split /\s{1,}/, $str_arr[$j] )[10];
        $tmp{'%UTIL'}    = ( split /\s{1,}/, $str_arr[$j] )[11];
        push @device_iostat_arr, \%tmp;
      }
      push( @get_iostat_details, { "STATUS_TYPE" => "DEVICE_IO_STATS", "DETAILS" => \@device_iostat_arr } );

      #	$retHash{'DEVICE_IO_STATS'} = \@device_iostat_arr;
      $i = $j;
    } else
    {
      $i += 1;
    }
  }
  return \@get_iostat_details;

  # return %retHash;
}

sub collectionutil_get_infiband_switches
{
  my $cmd;
  if ($IS_WIN)
  {
  } else
  {
    $cmd = "ibswitches 2>/dev/null|awk '{print \$10}'";
  }
  my $str = `$cmd`;
  my $retStr = join ",", ( split /\n/, $str );
  tfactlstore_summary_log( "Registered Infiband Switches: $retStr", "collectionutil_get_cell_names" );
  return $retStr;
}

sub collectionutil_get_ibsw_linker
{
  my $IBSWITCH = shift;
  my $cmd;
  if ($IBSWITCH)
  {
    if ($IS_WIN)
    {
    } else
    {
      $cmd = "dcli -l root -c $IBSWITCH \"listlinkup|grep Error\"";
    }
    my $str = `$cmd`;
    if ($str)
    {
      return "FAIL";
    } else
    {
      return "PASS";
    }
  }
}

sub collectionutil_get_ibsw_env_test
{
  my $IBSWITCH = shift;
  my %retHash;
  my $cmd;
  if ($IBSWITCH)
  {
    if ($IS_WIN)
    {
    } else
    {
      $cmd = "dcli -l root -c $IBSWITCH \"env_test|grep -i 'Environment test'|grep -iv 'started'\"";
    }

    #print "CMD: $cmd\n";
    my $str = `$cmd`;
    foreach my $line ( split /\n/, $str )
    {
      my $key   = ( split /:\s{1,}/, $line )[0];
      my $value = ( split /:\s{1,}/, $line )[1];
      if ( $line =~ /PASSED/ )
      {
        $retHash{$key} = "PASS";
      } else
      {
        $retHash{$key} = "FAIL";
      }
    }
  }
  return %retHash;
}

sub collectionutil_get_ibsw_priority_master
{
  my $IBSWITCH = shift;
  my %retHash;
  my $cmd;
  if ($IBSWITCH)
  {
    if ($IS_WIN)
    {
    } else
    {
      $cmd = "dcli -l root -c $IBSWITCH \"getmaster; setsmpriority list\"";
    }

    #print "CMD: $cmd\n";
    my $str = `$cmd`;
    my @str_arr = split /\n/, $str;
    for ( my $i = 0 ; $i <= $#str_arr ; $i++ )
    {
      my $line  = $str_arr[$i];
      my $key   = ( split /:\s{1,}/, $line )[0];
      my $value = ( split /:\s{1,}/, $line )[1];
      my @tmp   = ();
      if ( $retHash{$key} )
      {
        @tmp = @{ $retHash{$key} };
      }
      push @tmp, $value;
      $retHash{$key} = \@tmp;
    }
  }
  my %ibsw_priority;
  foreach my $key ( keys %retHash )
  {
    my %details;
    foreach my $value ( @{ $retHash{$key} } )
    {
      $details{'SM_STATE'}            = $1 if ( $value =~ /, state (.*)/ );
      $details{'SM_PRIORITY'}         = $1 if ( $value =~ /smpriority (.*)/ );
      $details{'CONTROLLED_HANDOVER'} = $1 if ( $value =~ /controlled_handover (.*)/ );
      $details{'M_KEY'}               = $1 if ( $value =~ /M_Key (.*)/ );
      $details{'ROUTING'}             = $1 if ( $value =~ /Routing engine (.*)/ );
    }
    $ibsw_priority{$key} = \%details;
  }
  return \%ibsw_priority;
}
##=============== EXADATA FUNCTIONS =====================================================
##=============== MISCELLANEOUS FUNCTIONS ================================================
sub collectionutil_opatch_details
{
  my $oracle_home = shift;
  my $oracle_user = shift;
  my %retHash;
  my $cmd;
  my $patch_flag = 1;
  if ($IS_WIN)
  {
    $cmd = catfile( $oracle_home, "OPatch", "opatch.bat" ) . " lspatches";
  } else
  {
    $cmd =
        "export ORACLE_HOME=$oracle_home ; su $oracle_user -c \""
      . catfile( $oracle_home, "OPatch", "opatch" )
      . " lspatches\"";
  }
  my $str = `$cmd`;

  # print "CMD: $cmd\nOP: $str\n";
  my @patch_list = ();
  foreach my $line ( split /\n/, $str )
  {
    if ( $line =~ /^There are no Interim patches installed in this Oracle Home/ )
    {
      $patch_flag = 0;
    } elsif ( $line =~ /^OPatch succeeded/ )
    {
    } elsif ( $line =~ /^OPatch could not create.*open history file for writing./ )
    {
      next;
    } elsif ( $line =~ /^\s*$/ )
    {
      next;
    } else
    {
      my %tmp;
      $tmp{"BUG#"}              = ( split /;/, $line )[0];
      $tmp{"PATCH_DESCRIPTION"} = ( split /;/, $line )[1];

      #$tmp{'PATCH_NAME'} = (split /\s:\s/, (split /;/, $line)[1])[0];
      #$tmp{'PATCH_VERSION'} = (split /\s/, (split /\s:\s/, (split /;/, $line)[1])[1])[0];
      push @patch_list, \%tmp;
    }
  }
  if ( $patch_flag == 0 )
  {
    $retHash{'PATCHES'} = "NIL";
  } else
  {
    $retHash{'PATCHES'} = \@patch_list;
  }
  return \%retHash;
}

sub collectionutil_opatch_product_details
{
  my $oracle_home = shift;
  my $oracle_user = shift;
  my $cmd;
  my $patch_flag = 0;
  if ($IS_WIN)
  {
    $cmd = catfile( $oracle_home, "OPatch", "opatch.bat" ) . " lsinventory -details";
  } else
  {
    $cmd =
        "export ORACLE_HOME=$oracle_home ;su $oracle_user -c \""
      . catfile( $oracle_home, "OPatch", "opatch" )
      . " lsinventory -details\"";
  }
  my $str = `$cmd`;
  my @patch_list;
  my $product_count;
  my $count = 1;
  foreach my $line ( split /\n/, $str )
  {
    next if ( $line =~ /^$/ );
    if ( $line =~ /^Installed Products \((.*)\)/ )
    {
      $patch_flag    = 1;
      $product_count = $1;
    } elsif ( $line =~ /^There are $product_count products installed in this Oracle Home./ )
    {
      last;
    } elsif ( $patch_flag == 1 )
    {
      my %tmp;
      $tmp{"SL No"} = $count++;
      my @temp = ( split /\s+/, $line );
      my @product_name = splice @temp, 0, -1;
      chomp(@product_name);
      $tmp{'PRODUCT_NAME'}    = "@product_name";
      $tmp{'PRODUCT_VERSION'} = $temp[-1];
      push @patch_list, \%tmp;
    }
  }
  return \@patch_list;
}

sub collectionutil_get_events
{
  my $event_type      = shift;
  my $component       = shift;
  my $running_dbs_ref = shift;
  my @oracle_homes;
  if ( $component eq "CRS" )
  {
    @oracle_homes = ();
    my $crs_home = collectionutil_get_crs_home();
    push @oracle_homes, $crs_home;
  } elsif ( $component eq "DB" )
  {
    my $ref = collectionutil_getRunningDB_homes($running_dbs_ref);
    @oracle_homes = @{$ref};
  }
  my $cmd;
  my $str;
  my @events_details;
  my $oracle_home_count = 0;
  my %adr_for_oracle_home;
  foreach my $oracle_home (@oracle_homes)
  {
    my %adr_homes;
    $oracle_home_count++;
    $ENV{ORACLE_HOME} = $oracle_home;
    my %category;
    my @category;
    push( @category, { 'EVENT_TYPE' => 'ORACLE_HOME', "DETAILS" => $oracle_home } );
    if ($IS_WIN)
    {
      $cmd = catfile( $oracle_home, "BIN", "orabase.exe" );
    } else
    {
      $cmd = catfile( $oracle_home, "bin", "orabase" );
    }
    my $orabase = `$cmd`;
    chomp($orabase);
    if ( $event_type =~ /incidents/ )
    {
      ## ADRCI SHOW INCIDENTS
      if ($IS_WIN)
      {
        $cmd = catfile( $oracle_home, "BIN", "adrci.exe" ) . " EXEC=\"SET BASE $orabase; SHOW HOMES; SHOW INCIDENT;\"";
      } else
      {
        $cmd = catfile( $oracle_home, "bin", "adrci" ) . " EXEC=\"SET BASE $orabase; SHOW HOMES; SHOW INCIDENT;\"";
      }
      $str = `$cmd`;
      my %tmp;
      my $adr_home;
      my @str_contents = split /\n/, $str;
      my @incidents;
      my $count_homes = 0;
      for ( my $i = 0 ; $i <= $#str_contents ; )
      {

        if ( $str_contents[$i] =~ /^ADR Home =/ )
        {
          my @incidents_in_homes;
          $count_homes++;
          $adr_home = ( split /\s=\s/, $str_contents[$i] )[1];
          $adr_home =~ s/://g;
          push( @incidents_in_homes, { "STATUS_TYPE" => "ORACLE_HOME", "DETAILS" => $oracle_home } );
          push( @incidents_in_homes, { "STATUS_TYPE" => "ADR_HOME",    "DETAILS" => $adr_home } );
          my $adr_home_instance = $adr_home;
          $adr_home_instance =~ /(.*)\W(.*)$/;
          $adr_home_instance = $2;

          if ( $str_contents[ $i + 2 ] =~ /^0 rows fetched/ )
          {
            push( @incidents_in_homes,
                  { "STATUS_TYPE" => "INCIDENT_STATUS_CHECK", "DETAILS" => "$adr_home_instance:PASS" } );
            $i += 3;
          } else
          {
            push( @incidents_in_homes,
                  { "STATUS_TYPE" => "INCIDENT_STATUS_CHECK", "DETAILS" => "$adr_home_instance:FAIL" } );
            my @events = ();
            my $j;
            for ( $j = $i + 4 ; $j <= $#str_contents ; $j++ )
            {
              if ( $str_contents[$j] =~ /^ADR Home =/ || $str_contents[$j] =~ /^\n/ )
              {
                last;
              } else
              {
                my %tmp1;
                my $id = ( split /\s{2,}/, $str_contents[$j] )[0];
                next if ( !defined $id );
                $tmp1{'INCIDENT_ID'} = ( split /\s{2,}/, $str_contents[$j] )[0];
                $tmp1{'PROBLEM_KEY'} = ( split /\s{2,}/, $str_contents[$j] )[1];
                $tmp1{'CREATE_TIME'} = ( split /\s{2,}/, $str_contents[$j] )[2];
                push @events, \%tmp1;
              }
            }
            push( @incidents_in_homes, { "STATUS_TYPE" => "INCIDENTS", "DETAILS" => \@events } );
            $i = $j;
          }
          $adr_homes{$adr_home} = \@incidents_in_homes;
        } else
        {
          $i += 1;
        }
      }
    }
    if ( $event_type =~ /problems/ )
    {
      ## ADRCI SHOW PROBLEMS
      if ($IS_WIN)
      {
        $cmd = catfile( $oracle_home, "BIN", "adrci.exe" ) . " EXEC=\"SET BASE $orabase; SHOW HOMES; SHOW PROBLEMS;\"";
      } else
      {
        $cmd = catfile( $oracle_home, "bin", "adrci" ) . " EXEC=\"SET BASE $orabase; SHOW HOMES; SHOW PROBLEMS;\"";
      }

      #print "CMD: $cmd\n";
      $str = `$cmd`;
      my %tmp;
      my $adr_home;
      my @str_contents = split /\n/, $str;
      my $count_homes = 0;
      my @problems;
      my %problem_homes;

      for ( my $i = 0 ; $i <= $#str_contents ; )
      {
        if ( $str_contents[$i] =~ /^ADR Home =/ )
        {
          my @problems_in_home;
          $count_homes++;
          $adr_home = ( split /\s=\s/, $str_contents[$i] )[1];
          $adr_home =~ s/://g;
          if ( exists $adr_homes{$adr_home} )
          {
            my $details = $adr_homes{$adr_home};
            push( @problems_in_home, @{$details} );
          } else
          {
            push( @problems_in_home, { "STATUS_TYPE" => "ADR_HOME",    "DETAILS" => $adr_home } );
            push( @problems_in_home, { "STATUS_TYPE" => "ORACLE_HOME", "DETAILS" => $oracle_home } );
          }
          my $adr_home_instance = $adr_home;
          $adr_home_instance =~ /(.*)\W(.*)$/;
          $adr_home_instance = $2;
          if ( $str_contents[ $i + 2 ] =~ /^0 rows fetched/ )
          {
            push( @problems_in_home,
                  { "STATUS_TYPE" => "PROBLEM_STATUS_CHECK", "DETAILS" => "$adr_home_instance:PASS" } );
            $i += 3;
          } else
          {
            push( @problems_in_home,
                  { "STATUS_TYPE" => "PROBLEM_STATUS_CHECK", "DETAILS" => "$adr_home_instance:FAIL" } );
            my @events = ();
            my $j;
            for ( $j = $i + 4 ; $j <= $#str_contents ; $j++ )
            {
              if ( $str_contents[$j] =~ /^ADR Home =/ || $str_contents[$j] =~ /^\n/ )
              {
                last;
              } else
              {
                my %tmp1;
                my $id = ( split /\s{2,}/, $str_contents[$j] )[0];
                next if ( !defined $id );
                $tmp1{'PROBLEM_ID'}    = ( split /\s{2,}/, $str_contents[$j] )[0];
                $tmp1{'PROBLEM_KEY'}   = ( split /\s{2,}/, $str_contents[$j] )[1];
                $tmp1{'LAST_INCIDENT'} = ( split /\s{2,}/, $str_contents[$j] )[2];
                $tmp1{'LASTINC_TIME'}  = ( split /\s{2,}/, $str_contents[$j] )[3];
                push @events, \%tmp1;
              }
            }
            push( @problems_in_home, { "STATUS_TYPE" => "PROBLEMS", "DETAILS" => \@events } );
            $i = $j;
          }
          $adr_homes{$adr_home} = \@problems_in_home;
        } else
        {
          $i += 1;
        }
      }
    }

    #        my @adr_details;
    #        my $count=1;
    #        push(@adr_details, { 'EVENTS ' => "ORACLE_HOME : $oracle_home" } );
    #        foreach my $home_details ( keys %adr_homes){
    #          my $details = $adr_homes{$home_details};
    #          push(@adr_details, { 'EVENTS ' => $details } );
    #        }
    #	push(@events_details, { "EVENTS_DETAILS" => \@adr_details} );
    $adr_for_oracle_home{$oracle_home} = \%adr_homes;
  }

  # return \@events_details;
  # return \@events_details;
  return \%adr_for_oracle_home;
}

sub check_rds_port_limit
{
  my $cmd;
  my $text;
  my %retHash;
  if ($IS_WIN)
  {
  } else
  {
    $cmd =
"rds-info 2>&1|egrep -v \"Protocol not available\" | awk '/RDS Sockets:/,/RDS Connections:/ { print $1 }'|sort|uniq -c| awk '$1>20 { print $0}'";
    $text = `$cmd`;
  }
  foreach my $line ( split /\n/, $text )
  {
    $line = trimString($line);
    my @tmp = ();
    my $cnt = ( split /\s{1,}/, $line )[0];
    my $ip  = ( split /\s{1,}/, $line )[1];
    push @tmp, "COUNT:$cnt";
    if ( $cnt >= 65000 )
    {
      push @tmp, "STATUS:FAIL";
    } elsif ( $cnt > 40000 )
    {
      push @tmp, "STATUS:WARNING";
    } elsif ( $cnt < 40000 )
    {
      push @tmp, "STATUS:PASS";
    }
    $retHash{$ip} = \@tmp;
  }
  return %retHash;
}

sub get_filesystem_details
{
  my %retHash;
  my $cmd;
  my $text;
  if ($IS_WIN)
  {
  } else
  {
    $cmd  = "df -kP|sed -e \"s/: / /g\" |  egrep -v \":|Capacity\"";
    $text = `$cmd`;
  }
  foreach my $line ( split /\n/, $text )
  {
    $line = trimString($line);
    my @tmp = split /\s{1,}/, $line;
    $tmp[1] = "Blocks:" . $tmp[1];
    $tmp[2] = "Used:" . $tmp[2];
    $tmp[3] = "Available:" . $tmp[3];
    $tmp[4] = "Capacity:" . $tmp[4];
    $tmp[5] = "Mounted:" . $tmp[5];
    my $capacity = ( split /%/, $tmp[4] )[0];

    if ( $capacity == 100 )
    {
      push @tmp, "STATUS:FAIL";
    } elsif ( $capacity > 80 )
    {
      push @tmp, "STATUS:WARNING";
    } elsif ( $capacity <= 80 )
    {
      push @tmp, "STATUS:OK";
    }
    $retHash{ $tmp[1] } = @tmp[ 1 .. $#tmp ];
  }
  return %retHash;
}

#Conversion for shell command 'cat <filename>' and returns the contents in an array
sub readFileToArray
{
  my $filename = shift;
  my @arr;
  open FILE, "$filename" or die "Could not open $filename!\n";
  while (<FILE>)
  {
    push @arr, $_;
  }
  close FILE;
  return @arr;
}

#perl conversion of 'grep <pattern>' from array and returns an array
sub grepPatternFromArray
{
  my $wordListref = shift;
  my @wordList    = @{$wordListref};
  my $pattern     = shift;
  chomp($pattern);
  my @retArray;
  my $i;
  foreach $i (@wordList)
  {

    if ( $i =~ /$pattern/ )
    {
      push @retArray, $i;
    }
  }
  return @retArray;
}

#perl conversion of 'grep -v <pattern> from array and returns an array
sub removePatternFromArray
{
  my $wordListref = shift;
  my @wordList    = @{$wordListref};
  my $pattern     = shift;
  chomp($pattern);
  my @retArray;
  my $i;
  foreach $i (@wordList)
  {

    if ( $i =~ /$pattern/ )
    {
    } else
    {
      push @retArray, $i;
    }
  }
  return @retArray;
}

sub copyArray
{
  my $arrayRef = shift;
  my @array    = @{$arrayRef};
  my @retArr;
  foreach my $x (@array)
  {
    push @retArr, $x;
  }
  return @retArr;
}

#takes an array with redundant elements and returns an array with unique elements
sub array_uniq_elem
{
  my %seen;
  grep !$seen{$_}++, @_;
}

sub convertToStandardString
{
  my $str = shift;
  $str = lc($str);
  $str =~ s/^\s+//g;
  $str =~ s/\s+$//g;
  $str =~ s/\s/_/g;
  chomp($str);
  return $str;
}

sub tolower_host
{
  my $host = hostname() or return "";

  # If the hostname is an IP address, let hostname remain as IP address
  # Else, strip off domain name in case /bin/hostname returns FQDN
  # hostname
  my $shorthost;
  if ( $host =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ )
  {
    $shorthost = $host;
  } else
  {
    ( $shorthost, ) = split( /\./, $host );
  }

  # convert to lower case
  $shorthost =~ tr/A-Z/a-z/;
  die "Failed to get non-FQDN host name for " if ( $shorthost eq "" );
  return $shorthost;
}

sub printArr
{
  my $arrref = shift;
  my @arr    = @{$arrref};
  foreach my $x (@arr)
  {
    print "$x\n";
  }
}

sub trimString
{
  my $str = shift;
  $str =~ s/^[\n|\s]+//g;
  $str =~ s/[\n|\s]+$//g;
  return $str;
}

sub transformToStandardOutput
{
  my $str    = shift;
  my $retStr = "";
  foreach my $x ( split /\n/, $str )
  {
    $x      = trimString($x);
    $x      = join ":", split /\s{2,}/, $x;
    $retStr = $retStr . $x . "\n";
  }
  chomp($retStr);
  $retStr =~ s/^\n//g;
  return $retStr;
}

sub is_key_present
{
  my $text    = shift;
  my $pattern = shift;
  foreach my $line ( split /\n/, $text )
  {
    if ( $line =~ /$pattern/ )
    {
      return 1;
    }
  }
  return 0;
}

sub collectionutil_get_system_date
{
  my $retStr;
  if ($IS_WIN)
  {
    my $date = `date /t`;
    my $time = `time /t`;
    $date =~ s/\n//g;
    $time =~ s/\n//g;
    $retStr = $date . " " . $time;
  } else
  {
    $retStr = `date`;
    $retStr =~ s/\n//g;
  }
  return $retStr;
}

sub run_a_sql
{
  my $oracle_home = shift;
  my $oracle_sid  = shift;
  my $sql_query   = shift;
  my $runas       = shift;
  tfactlstore_summary_log(
             "Running SQL Statement with ARGS:\nOH: $oracle_home\nSID: $oracle_sid\nRUNAS: $runas\nSQL: $sql_query",
             "run_a_sql" );
  if ( !$runas )
  {
    $runas = "sysdba";
  }
  my $sqlFile;
  my $retStr;
  my $OLD_ORACLE_HOME = $ENV{"ORACLE_HOME"};
  my $OLD_ORACLE_SID  = $ENV{"ORACLE_SID"};
  $ENV{"ORACLE_SID"}      = $oracle_sid;
  $ENV{"ORACLE_HOME"}     = $oracle_home;
  $ENV{"LD_LIBRARY_PATH"} = catfile( $ENV{"ORACLE_HOME"}, "lib" );
  my $ORACLE_HOME_cpy = $ENV{"ORACLE_HOME"};
  my $loc;
  my $OH_dbOwner;
  my $text1;
  my @tmp;

  if ($IS_WIN)
  {
    $loc        = catfile( $ENV{"ORACLE_HOME"}, "BIN", "oracle.exe" );
    @tmp        = `dir /Q $loc`;
    $OH_dbOwner = $tmp[5];
    $OH_dbOwner =~ s/\s+/ /g;
    @tmp        = split / /, $OH_dbOwner;
    $OH_dbOwner = $tmp[4];
    @tmp        = split /\\/, $OH_dbOwner;
    $OH_dbOwner = $tmp[-1];
  } else
  {
    $loc        = catfile( $ENV{"ORACLE_HOME"}, "bin", "oracle" );
    $OH_dbOwner = `ls -l $loc`;
    @tmp        = split " ", $OH_dbOwner;
    $OH_dbOwner = $tmp[2];
  }
  tfactlstore_summary_log( "Oracle Home DB Owner: $OH_dbOwner", "run_a_sql" );

  #print "Oracle Home DB Owner: $OH_dbOwner\n";
  my $str;
  if ($IS_WIN)
  {
    if ( !-e $WIN_TRANSFER_DIR )
    {
      eval { tfactlshare_mkpath("$WIN_TRANSFER_DIR", "1740") if ( ! -d "$WIN_TRANSFER_DIR" );  };
      if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $WIN_TRANSFER_DIR","run_a_sql",1 ); }
    }
    $text1 = `set ORACLE_HOME=$ENV{ORACLE_HOME}`;

    #$text1 = `echo %ORACLE_HOME%`;
    #print "$text1\n";
  }
  if ($IS_WIN)
  {
    $sqlFile = catfile( $WIN_TRANSFER_DIR, "commands_$$.sql" );
  } else
  {
    my $dir_tfa_base = tfactlshare_get_repository_location($tfa_home);
    my $dir_base = catfile($dir_tfa_base, "suptools", "$hostname", "summary",$OH_dbOwner);
    $sqlFile = catfile( $dir_base, "commands_$$.sql" );
  }
  tfactlstore_summary_log( "SQLFILE: $sqlFile", "run_a_sql" );
  open( my $sql_fptr, '>', $sqlFile ) or die "Could not open file '$sqlFile' $!";
  print $sql_fptr $sql_query;
  close $sql_fptr;
  chmod(oct("0755"),$sqlFile);
  if ($IS_WIN)
  {
    $text1 = "$ORACLE_HOME_cpy\\bin\\sqlplus.exe -S -l / as $runas @ $sqlFile";
  } else
  {

    my $command = tfactlshare_checksu($OH_dbOwner ,"env | grep -i '^shell='");
    my $shell = `$command`;
    if ( $shell =~ /\/bin\/t?csh/ ) {
     $text1 = tfactlshare_checksu($OH_dbOwner ,"set ORACLE_HOME=$ORACLE_HOME_cpy; set ORACLE_SID=$oracle_sid;".
                                  "$ORACLE_HOME_cpy/bin/sqlplus -S -l / as $runas @ $sqlFile");

    } else {
      $text1 = tfactlshare_checksu($OH_dbOwner ,"export ORACLE_HOME=$ORACLE_HOME_cpy; export ORACLE_SID=$oracle_sid;".
                                  "$ORACLE_HOME_cpy/bin/sqlplus -S -l / as $runas @ $sqlFile");
    }
  }
  tfactlstore_summary_log( "command - $text1", "run_a_sql" );
  $str = osutils_runtimedcommand($text1,30,TRUE,"");
  
  tfactlstore_summary_log( "command - $text1 - done", "run_a_sql" );
  $ENV{"ORACLE_HOME"}     = $OLD_ORACLE_HOME;
  $ENV{"ORACLE_SID"}      = $OLD_ORACLE_SID;
  $ENV{"LD_LIBRARY_PATH"} = catfile( $ENV{"ORACLE_HOME"}, "lib" );
  $str = "Database is Not Running" if($str =~ m/ORA-01034: ORACLE not available/);
  unlink($sqlFile);
  return $str;
}

sub testSQLWin {
  my $db = shift;
  my $dboh = shift;
  my $sid = shift;
  my $text1;

  $ENV{ORACLE_HOME} = $dboh;
  $ENV{ORACLE_SID} = $sid;
  $ENV{LD_LIBRARY_PATH} = catdir($ENV{ORACLE_HOME}, "lib");
  $ENV{ORA_SERVER_THREAD_ENABLED} = "FALSE";

  if ( !-e $WIN_TRANSFER_DIR )
  {
    eval { tfactlshare_mkpath("$WIN_TRANSFER_DIR", "1740") if ( ! -d "$WIN_TRANSFER_DIR" );  };
    if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $WIN_TRANSFER_DIR","run_a_sql",1 ); }
  }

  my $sqlFile = catfile($WIN_TRANSFER_DIR, "commands_$$.sql");
  my $sqlFile_cpy = $sqlFile;

  open(my $sql_fptr, '>', $sqlFile) or die "Could not open file '$sqlFile' $!";
  print $sql_fptr "set feedback  off heading off lines 120\nselect 'Database Connection Successful' from dual;\nquit;\n";
  $text1 = "$dboh\\bin\\sqlplus.exe -l -S / as sysdba @ $sqlFile";
  #print "CMD: $text1\n";
  $text1 = `$text1`;
  chomp($text1);
  #print "TEXT: $text1";
  close $sql_fptr;
  if (-f $sqlFile) {
    unlink($sqlFile);
  }

  if ($text1 =~ /Database Connection Successful/) {
    return 1;
  } else {
    return 0;
  }
}
##=============== MISCELLANEOUS FUNCTIONS ================================================
##=============== SSH FUNCTIONS ================================================
sub configure_ssh
{
  my $host_list = shift;
  my $SILENT    = shift;
  my @hlist_arr = split /,/, $host_list;
  my @SSH_HOSTS = @hlist_arr;
  my $PING;
  my $localnode = tolower_host();
  my $exitcode;
  my $ssh_setup_status;
  my $rsh_setup_status;
  my $SSHELL;
  my $SCOPY;
  my $AutoLoginCheck;
  my $tmpSshConf;
  my $temp_hlist;
  my @hnameArr;
  my $res_ping;
  my $sshcmd;
  my $usern = get_usern();

  if ( length("$SILENT") != 0 && $SILENT == 0 )
  {
    print "\n\nChecking ssh user equivalency settings on all nodes in cluster\n";
  }
  foreach my $hname (@hlist_arr)
  {
    #print "HOST: $hname\n";
    #chomp($hname);
    if ( $PLATFORM eq "linux" )
    {
      $PING = "/bin/ping";
    } else
    {
      $PING = "/usr/sbin/ping";
    }
    if ( $hname ne $localnode )
    {
      if ( $PLATFORM eq "solaris" )
      {
        $res_ping = `$PING -s $hname 5 5`;
      } elsif ( $PLATFORM eq "hpux" )
      {
        $res_ping = `$PING $hname -n 5 -m 5`;
      } else
      {
        $res_ping = `$PING -c 1 -w 5 $hname`;
      }

      #print "\nRES: $res_ping\n";
      $exitcode = `echo $?`;

      #print "EXITCODE: $exitcode\n";
      if ( $exitcode == 0 )
      {
        my $cmd = "$SSH -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -l $usern $hname ls 2>/dev/null 1>/dev/null";

        #print "SSH_CMD:  $cmd\n";
        `$cmd`;
        $ssh_setup_status = $?;

        #print "SSH STAT: $ssh_setup_status\n";
        if ( $ssh_setup_status == 0 )
        {
          if ( length("$SILENT") != 0 && $SILENT == 0 )
          {
            print "\nNode $hname is configured for ssh user equivalency for $usern user\n";
          }
        } else
        {
          if ( length("$SILENT") != 0 && $SILENT == 0 )
          {
            print
"\nNode $hname is not configured for ssh user equivalency and  the script uses ssh to install TFA on remote nodes.\n\nWithout this facility the script cannot install TFA on the remote nodes. \n";
          }
          if ( length("$SILENT") != 0 && $SILENT == 1 )
          {
            #Remove host
            my @tmp = ();
            foreach my $x (@SSH_HOSTS)
            {
              chomp($x);
              if ( $x ne $hname )
              {
                push @tmp, $x;
              }
            }
            @SSH_HOSTS = @tmp;
          } else
          {
            print "\nDo you want to configure SSH for user $usern on $hname [y/n] ";

            #$AutoLoginCheck = "y";
            $AutoLoginCheck = <STDIN>;
            chomp($AutoLoginCheck);

            #print "$AutoLoginCheck";
            if ( $AutoLoginCheck =~ /^[Y|YES]$/i )
            {
              #print "Inhere1\n";
              configureSSH($hname);
              if ( $? != 0 )
              {
                my @tmp = ();
                foreach my $x (@SSH_HOSTS)
                {
                  chomp($x);
                  if ( $x ne $hname )
                  {
                    push @tmp, $x;
                  }
                }
                @SSH_HOSTS = @tmp;
              }
            } elsif ( $AutoLoginCheck =~ /^[N|NO]$/i )
            {
              #print "Inhere2\n";
              print
                "\nWe can configure ssh only for this run and reverse the changes back. do you want to continue?[y/n] ";

              #$tmpSshConf = "y";
              $tmpSshConf = <STDIN>;
              chomp($tmpSshConf);
              if ( $tmpSshConf =~ /^[Y|YES]$/i )
              {
                #print "Inhere3\n";
                configureSSH($hname);
                if ( $? != 0 )
                {
                  my @tmp = ();
                  foreach my $x (@SSH_HOSTS)
                  {
                    chomp($x);
                    if ( $x ne $hname )
                    {
                      push @tmp, $x;
                    }
                  }
                  @SSH_HOSTS = @tmp;
                } else
                {
                  push @hnameArr, $hname;
                }
              } elsif ( $tmpSshConf =~ /^[N|NO]$/i )
              {
                #print "Inhere4\n";
                if ( $hname eq $localnode )
                {
                  print "\nWithout ssh user equivalency program is executed only on localnode $localnode\n";
                  my @tmp = ();
                  push @tmp, $localnode;
                  @hlist_arr = @tmp;
                } else
                {
                  print "\nWithout ssh user eqivalency, program is not executed on $hname\n";
                  my @tmp = ();
                  foreach my $x (@SSH_HOSTS)
                  {
                    chomp($x);
                    if ( $x ne $hname )
                    {
                      push @tmp, $x;
                    }
                  }
                  @SSH_HOSTS = @tmp;
                }
              } else
              {
                configureSSH($hname);
                push @hnameArr, $hname;
              }
            } else
            {
              #print "Inhere5\n";
              configureSSH($hname);
              if ( $? != 0 )
              {
                my @tmp = ();
                foreach my $x (@SSH_HOSTS)
                {
                  chomp($x);
                  if ( $x ne $hname )
                  {
                    push @tmp, $x;
                  }
                }
                @SSH_HOSTS = @tmp;
              }
            }
          }
        }
      } elsif ( $hname ne $localnode )
      {
        my @tmp = ();
        foreach my $x (@SSH_HOSTS)
        {
          chomp($x);
          if ( $x ne $hname )
          {
            push @tmp, $x;
          }
        }
        @SSH_HOSTS = @tmp;
      }
    }
  }

  #ssh setup ends  here and not to change
  my $retStr = join ",", @SSH_HOSTS;
  return $retStr;
}

sub getCommandLocation
{
  my $COMMAND = shift;
  my $CMDLOC;
  if ( -e "/bin/$COMMAND" )
  {
    $CMDLOC = "/bin/$COMMAND";
  } elsif ( -e "/usr/bin/$COMMAND" )
  {
    $CMDLOC = "/usr/bin/$COMMAND";
  } else
  {
    $CMDLOC = "$COMMAND";
  }
  return $CMDLOC;
}

sub generateKeys
{
  my $HOME       = $ENV{HOME};
  my $SSH_KEYGEN = getCommandLocation("ssh-keygen");
  my $SSH_ENCR   = "rsa";
  my $SSH_BITS   = "1024";
  my $SSH_ID     = "id_rsa";
  my $HOSTNAME   = tolower_host();
  my $SSH_GEN_KEYS;

  # Remove Private Key
  if ( -e "$HOME/.ssh/$SSH_ID" )
  {
    unlink("$HOME/.ssh/$SSH_ID");
  }

  # Remove Public Key
  if ( -e "$HOME/.ssh/$SSH_ID.pub" )
  {
    unlink("$HOME/.ssh/$SSH_ID.pub");
  }
  if ( !-d "$HOME/.ssh" )
  {
    eval { tfactlshare_mkpath("$HOME/.ssh", "1740") if ( ! -d "$HOME/.ssh" );  };
    if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $HOME/.ssh","generateKeys",1 ); }
  }

  # Generate Keys
  print "Generating keys on $HOSTNAME...\n";
  `$SSH_KEYGEN -t $SSH_ENCR -b $SSH_BITS -f $HOME/.ssh/$SSH_ID -N '' > /dev/null`;
  $SSH_GEN_KEYS = 1;
}

# Function to configure SSH setup
sub configureSSH
{
  my $REMOTE_HOST = shift;
  my $SSH_ID      = "id_rsa";
  my $SSH_USER    = "root";
  my $SSH_COPY_ID = getCommandLocation("ssh-copy-id");
  my $CAT         = getCommandLocation("cat");
  my $SSH         = getCommandLocation("ssh");
  my $HOME        = $ENV{HOME};

  # Generate keys only if not present
  if ( !-e "$HOME/.ssh/$SSH_ID" )
  {
    generateKeys();
    print "\n";
  }

  # Copy keys to remote node
  print "Copying keys to $REMOTE_HOST...\n";
  print "\n";
  if ( -e "$SSH_COPY_ID" )
  {
    `$SSH_COPY_ID $SSH_USER\@$REMOTE_HOST > /dev/null`;
  } else
  {
`$CAT $HOME/.ssh/$SSH_ID.pub | $SSH $SSH_USER\@$REMOTE_HOST \"mkdir -p $HOME/.ssh && cat >>  $HOME/.ssh/authorized_keys\"`;
  }
}

sub get_usern
{
  my $usern;
  if ( $PLATFORM eq "linux" )
  {
    $usern = `whoami`;
  } elsif ($IS_WIN)
  {
    $usern = `echo %USERNAME%`;
  } elsif ( $PLATFORM eq "solaris" )
  {
    $usern = `id|awk '{print $1}'|cut -d'(' -f2|cut -d')' -f1`;
  } elsif ( $PLATFORM eq "hpux" )
  {
    $usern = `whoami`;
  } elsif ( $PLATFORM eq "aix" )
  {
    $usern = `whoami`;
  } else
  {
    print "ERROR: Unknown Operating System\n";
  }
  chomp($usern);
  return $usern;
}
##=============== SSH FUNCTIONS ================================================
1;
