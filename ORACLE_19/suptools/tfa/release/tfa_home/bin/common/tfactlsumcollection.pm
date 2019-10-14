##
# $Header: tfa/src/v2/tfa_home/bin/common/tfactlsumcollection.pm /main/8 2018/04/20 10:18:29 migmoren Exp $
#
# $Header: tfa/src/v2/tfa_home/bin/common/tfactlsumcollection.pm /main/8 2018/04/20 10:18:29 migmoren Exp $
#
# tfactlsumcollection.pm
#
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlsumcollection.pm - Format Collection in to Tables 
#
#    DESCRIPTION
#      This Modules includes - 
#      1. Converts collection utils data in to table
#      2. Prepare overall status
#      3. Handle component and command dependency 
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    migmoren    04/19/18 - Bug 26984470 - SOLSP-18.1-TFA:TFACTL SUMMARY EXIT
#                           WHEN COLLECTING OS DETAILS
#    bibsahoo    09/26/17 - FIX BUG 26845295
#    bibsahoo    08/31/17 - FIX BUG 26414175
#    bibsahoo    07/19/17 - FIX BUG 26329776
#    bibsahoo    05/24/17 - FIX BUG 26127514
#    cpujar      05/19/17 - XbranchMerge cpujar_bug-26090405 from
#                           st_tfa_12.2.1.1.01
#    cpujar      05/17/17 - Summary bug 26090405
#    cpujar      03/05/17 - Split Database problem summary Bug25971734
#    bibsahoo    04/13/17 - Update Collection methods
#    cpujar      12/29/16 - Creation
#
#!/usr/bin/perl
package tfactlsumcollection;

BEGIN
{
  use Exporter();
  our ( @ISA, @EXPORT );
  @ISA = qw(Exporter);
  my @exp_func = qw(
    sumcollection_cluster_nodes
    sumcollection_summary_overview
    sumcollection_cluster_status_summary
    sumcollection_cluster_status_details
    sumcollection_crs_clusterwide_summary
    sumcollection_crs_clusterwide_status
    sumcollection_crs_status_summary
    sumcollection_crs_resource_status_summary
    sumcollection_crs_resource_category
    sumcollection_crs_resource_statistics
    sumcollection_crs_resource_complete_details
    sumcollection_asm_clusterwide_summary
    sumcollection_asm_clusterwide_status
    sumcollection_asm_status_summary
    sumcollection_asm_diskgroup_details
    sumcollection_asm_volumes
    sumcollection_asm_instancefiles
    sumcollection_asm_hang_analysis
    sumcollection_asm_incidents
    sumcollection_asm_problems
    sumcollection_is_database_installed
    sumcollection_database_clusterwide_summary
    sumcollection_database_clusterwide_status
    sumcollection_database_problems_summary
    sumcollection_database_incidents_summary
    sumcollection_database_hang_analysis_summary
    sumcollection_database_status_summary
    sumcollection_database_configuration_details
    sumcollection_database_instance_details
    sumcollection_database_account_status
    sumcollection_database_components_version
    sumcollection_database_datafiles_details
    sumcollection_database_tablespace_details
    sumcollection_database_files_details
    sumcollection_database_group_details
    sumcollection_database_hanganalyze
    sumcollection_database_system_events
    sumcollection_database_statistics
    sumcollection_database_sql_statistics
    sumcollection_database_sqlmon_statistics
    sumcollection_database_get_running_db_details
    sumcollection_database_get_db_stat_details
    sumcollection_database_serverpool_details
    sumcollection_database_incidents
    sumcollection_database_problems
    sumcollection_database_rman_stats
    sumcollection_database_pdb_stats
    sumcollection_os_clusterwide_summary
    sumcollection_os_clusterwide_status
    sumcollection_os_status_summary
    sumcollection_os_details
    sumcollection_system_configuration
    sumcollection_os_sleeping_tasks
    sumcollection_os_cpu_details
    sumcollection_os_disk_location
    sumcollection_os_disk_details
    sumcollection_listener_clusterwide_summary
    sumcollection_listener_clusterwide_status
    sumcollection_listener_status_summary
    sumcollection_listener_scan_details
    sumcollection_listener_lsnrctl_status
    sumcollection_network_clusterwide_summary
    sumcollection_network_clusterwide_status
    sumcollection_network_status_summary
    sumcollection_network_interface_details
    sumcollection_network_cluvfy_details
    sumcollection_network_ocrcheck_details
    sumcollection_patch_clusterwide_summary
    sumcollection_patch_clusterwide_status
    sumcollection_patch_status_summary
    sumcollection_crs_patch_details
    sumcollection_database_patch_details
    sumcollection_crs_product_details
    sumcollection_database_product_details
    sumcollection_acfs_clusterwide_summary
    sumcollection_acfs_clusterwide_status
    sumcollection_acfs_status_summary
    sumcollection_acfs_filesystem_details
    sumcollection_acfs_volume_details
    sumcollection_acfs_volume_statistics
    sumcollection_tfa_clusterwide_summary
    sumcollection_tfa_clusterwide_status
    sumcollection_tfa_status_summary
    sumcollection_tfa_directories
    sumcollection_tfa_directories_summary
    sumcollection_tfa_repository
    sumcollection_tfa_config
    sumcollection_summary_clusterwide_summary
    sumcollection_summary_clusterwide_status
    sumcollection_summary_profile
    sumcollection_summary_exectime_summary
    sumcollection_summary_exectime_component
    sumcollection_exadata_clusterwide_summary
    sumcollection_exadata_clusterwide_status
    sumcollection_exadata_status_summary
    sumcollection_exadata_system_details
    sumcollection_exadata_cell_details
    sumcollection_exadata_infiband_switches_details
    sumcollection_exadata_io_statistics
    sumcollection_exadata_io_status
  );
  push @EXPORT, @exp_func;
}
use strict;
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
use tfactlcollectionutils;
my $SEP = "_|SEP|_";
my $PLATFORM = $^O;

##############################################
# OVERVIEW
##############################################
sub sumcollection_cluster_nodes
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );

  my @nodelist = @{$SUMMARY_NODE_LIST_REF};
  my @node_summary;
  push( @node_summary, { "TYPE" => "Total Number of Node", "DETAILS" => $#nodelist + 1 } );
  push( @node_summary, { "TYPE" => "Cluster Node List",    "DETAILS" => \@nodelist } );
  tfactlstore_store_hash_into_json( \@node_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_summary_overview
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my @cluster_status_summary;
  my $cluster_status_summary = get_dependent_data( $tfa_home, "overview", "cluster_status_summary", $repository_base );
  foreach my $status ( @{$cluster_status_summary} )
  {
    my $overview_status = $status->{STATUS};
    push( @cluster_status_summary, { 'COMPONENT' => $status->{COMPONENT}, 'STATUS' => $overview_status } );
  }
  tfactlstore_store_hash_into_json( \@cluster_status_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_cluster_status_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my @cluster_status_summary;
  foreach my $component ( grep { ( exists $SUMMARY_COMPONENTS_REF->{$_} ) and ( $SUMMARY_COMPONENTS_REF->{$_} eq "1" ) }
                          @{$SUMMARY_COMPONENT_ORDER_REF} )
  {
    next if ( $component =~ /(overview)/ );

    my $clusterwide_summary =
      @{ get_dependent_data( $tfa_home, "${component}overview", "${component}_clusterwide_summary", $repository_base ) }
      [0];
    my $status  = $clusterwide_summary->{"OVERALL_STATUS"};
    my $details = $clusterwide_summary->{"SUMMARY"};
    push( @cluster_status_summary, { 'COMPONENT' => uc($component), 'STATUS' => $status, 'DETAILS' => $details } );
  }
  tfactlstore_store_hash_into_json( \@cluster_status_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_cluster_status_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my @cluster_status_summary;
  foreach my $component ( grep { ( exists $SUMMARY_COMPONENTS_REF->{$_} ) and ( $SUMMARY_COMPONENTS_REF->{$_} eq "1" ) }
                          @{$SUMMARY_COMPONENT_ORDER_REF} )
  {
    next if ( $component =~ /(overview)/ );

    my $clusterwide_status =
      get_dependent_data( $tfa_home, "${component}overview", "${component}_clusterwide_status", $repository_base );
    push( @cluster_status_summary, { 'COMPONENT' => uc($component), 'DETAILS' => $clusterwide_status } );
  }
  tfactlstore_store_hash_into_json( \@cluster_status_summary, $repository_loc, $hash_repository_loc );
}
##############################################
# CRS STATUS
##############################################
sub sumcollection_crs_clusterwide_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $dep_hash_ref = get_dependent_data( $tfa_home, "crsoverview", "crs_clusterwide_status", $repository_base );
  my @crs_clusterwide_status = @{$dep_hash_ref};
  my @crs_clusterwide_summary;
  my @crs_status;
  my $CRS_STATE           = "ONLINE";
  my $CRS_INTEGRITY_CHECK = "PASS";
  my $CRS_SERVER_STATUS   = "ONLINE";
  my $CRS_RESOURCE_STATUS = "ONLINE";

  foreach my $status (@crs_clusterwide_status)
  {
    $CRS_SERVER_STATUS   = "OFFLINE" if ( $status->{"CRS_SERVER_STATUS"} ne "ONLINE" );
    $CRS_STATE           = "OFFLINE" if ( $status->{"CRS_STATE"} ne "ONLINE" );
    $CRS_INTEGRITY_CHECK = "FAIL"    if ( $status->{"CRS_INTEGRITY_CHECK"} ne "PASS" );
    $CRS_RESOURCE_STATUS = "OFFLINE Resources Found"
      if ( $status->{"CRS_RESOURCE_STATUS"} eq "OFFLINE Resource Found" );
  }
  push( @crs_status, "CRS_SERVER_STATUS   : " . $CRS_SERVER_STATUS );
  push( @crs_status, "CRS_STATE           : " . $CRS_STATE );
  push( @crs_status, "CRS_INTEGRITY_CHECK : " . $CRS_INTEGRITY_CHECK );
  push( @crs_status, "CRS_RESOURCE_STATUS : " . $CRS_RESOURCE_STATUS );
  my $OVERALL_STATUS;
  if ( $CRS_SERVER_STATUS eq "ONLINE" and $CRS_INTEGRITY_CHECK eq "PASS" )
  {
    $OVERALL_STATUS = "OK";
  } else
  {
    $OVERALL_STATUS = "PROBLEM";
  }
  push( @crs_clusterwide_summary, { "OVERALL_STATUS" => $OVERALL_STATUS, "SUMMARY" => \@crs_status } );
  tfactlstore_store_hash_into_json( \@crs_clusterwide_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_crs_clusterwide_status
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );

  my @nodelist = @{$SUMMARY_NODE_LIST_REF};
  my @crs_clusterwide_status;
  foreach my $node (@nodelist)
  {
    my $repository_base_nodewise = catfile( $SUMMARY_REPOSITORY, $node );
    my $dep_hash_ref;
    if ( $node ne $hostname )
    {
      my ( $status, $data ) = get_dependent_remote_data( $node, "crs", "crs_status_summary" );
      $dep_hash_ref = $data;
      next if ( $status eq "false" );
    } else
    {
      $dep_hash_ref = get_dependent_data( $tfa_home, "crs", "crs_status_summary", $repository_base_nodewise );
    }
    my @crs_status_summary = @{$dep_hash_ref};
    my $CRS_VERSION;
    my $CRS_SERVER_STATUS   = "OFFLINE";
    my $CRS_INTEGRITY_CHECK = "PASS";
    my $CRS_RESOURCE_STATUS = "OFFLINE Resource Found";
    my $CRS_STATE           = "OFFLINE";
    foreach my $status (@crs_status_summary)
    {
      $CRS_VERSION       = $status->{STATUS} if ( $status->{STATUS_TYPE} eq "CRS_VERSION" );
      $CRS_SERVER_STATUS = $status->{STATUS} if ( $status->{STATUS_TYPE} eq "CRS_SERVER_STATUS" );
      if ( $status->{STATUS_TYPE} eq "CRS_INTEGRITY_CHECK" )
      {
        my %crs_integrity = %{ $status->{STATUS} };
        foreach my $value ( values %crs_integrity )
        {
          $CRS_INTEGRITY_CHECK = "FAIL" if ( $value ne "PASS" );
        }
      }
      if ( $status->{STATUS_TYPE} eq "CRS RESOURCE STATUS" )
      {
        my %crs_resource = %{ $status->{STATUS} };
        if ( keys %crs_resource == 1 and exists $crs_resource{"ONLINE"} )
        {
          $CRS_RESOURCE_STATUS = "ONLINE";
        } else
        {
          $CRS_RESOURCE_STATUS = "OFFLINE Resource Found";
        }
      }
      if ( $status->{STATUS_TYPE} eq "CRS_STATE" )
      {
        my %crs_state = %{ $status->{STATUS} };
        if ( keys %crs_state == 1 and exists $crs_state{"Online"} )
        {
          $CRS_STATE = "ONLINE";
        } else
        {
          $CRS_STATE = "OFFLINE";
        }
      }
    }
    $CRS_INTEGRITY_CHECK = "FAIL" if ( $CRS_STATE eq "OFFLINE" );
    push(
          @crs_clusterwide_status,
          {
            "HOSTNAME"            => $node,
            "CRS_SERVER_STATUS"   => $CRS_SERVER_STATUS,
            "CRS_INTEGRITY_CHECK" => $CRS_INTEGRITY_CHECK,
            "CRS_RESOURCE_STATUS" => $CRS_RESOURCE_STATUS,
            "CRS_STATE"           => $CRS_STATE
          }
    );
  }
  tfactlstore_store_hash_into_json( \@crs_clusterwide_status, $repository_loc, $hash_repository_loc );
}

sub sumcollection_crs_status_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  return unless sumcollection_crs_check( $repository_loc, $hash_repository_loc );
  my @crs_status_summary;
  my %crs_status_summary;
  push( @crs_status_summary, { 'STATUS_TYPE' => "SYSTEM_DATE", 'STATUS' => collectionutil_get_system_date() } );
  push( @crs_status_summary, { 'STATUS_TYPE' => "CRS_HOME",    'STATUS' => collectionutil_get_crs_home() } );
  push( @crs_status_summary, { 'STATUS_TYPE' => "CRS_VERSION", 'STATUS' => collectionutil_get_crs_version() . " " } );
  my %crs_server_status;
  my %crsServerStat = collectionutil_get_crs_server_status();
  $crs_server_status{'STATUS_TYPE'} = "CRS_SERVER_STATUS";
  $crs_server_status{'STATUS'}      = $crsServerStat{$hostname};
  push( @crs_status_summary, \%crs_server_status );
  my $crsState = collectionutil_check_crs_state(1);
  my %hash;

  foreach my $line ( split /\n/, $crsState )
  {
    if ($line)
    {
      my @tmp = split /:/, $line;
      my @components;
      if ( exists $hash{ $tmp[1] } )
      {
        @components = @{ $hash{ $tmp[1] } };
      }
      push( @components, $tmp[0] );
      $hash{ $tmp[1] } = \@components;
    }
  }
  push( @crs_status_summary, { 'STATUS_TYPE' => "CRS_STATE", 'STATUS' => \%hash } );
  my %crs_integrity = collectionutil_check_crs_integrity();
  push( @crs_status_summary, { 'STATUS_TYPE' => "CRS_INTEGRITY_CHECK", 'STATUS' => \%crs_integrity } );
  my $crs_resource_status_summary =
    get_dependent_data( $tfa_home, "crs", "crs_resource_status_summary", $repository_base );
  my %res_status;
  foreach my $resource ( @{$crs_resource_status_summary} )
  {
    $res_status{ $resource->{STATE} } = $resource->{RESOURCE_LIST} if ( $resource->{STATE} ne "ONLINE" );
  }
  my $size = keys %res_status;
  if ( $size != 0 )
  {
    push( @crs_status_summary, { 'STATUS_TYPE' => "CRS RESOURCE STATUS", 'STATUS' => \%res_status } );
  } else
  {
    $res_status{ONLINE} = "ALL RESOURCE";
    push( @crs_status_summary, { 'STATUS_TYPE' => "CRS RESOURCE STATUS", 'STATUS' => \%res_status } );
  }
  tfactlstore_store_hash_into_json( \@crs_status_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_crs_resource_status_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  return unless sumcollection_crs_check( $repository_loc, $hash_repository_loc );
  my $dep_hash_ref = get_dependent_data( $tfa_home, "crs", "crs_resource_complete_details", $repository_base );
  my @crsResourcesStat = @{$dep_hash_ref};
  my %crs_resource_summary;
  my @crs_resource_summary_list;

  foreach my $resource (@crsResourcesStat)
  {
    my $state = $resource->{"STATE"};
    my @resource_array;
    my $name = $resource->{"RESOURCE_NAME"};
    if ( exists $crs_resource_summary{$state} )
    {
      @resource_array = @{ $crs_resource_summary{$state} };
    }
    push( @resource_array, $name );
    $crs_resource_summary{$state} = \@resource_array;
  }
  foreach my $key ( keys %crs_resource_summary )
  {
    push( @crs_resource_summary_list, { "STATE" => $key, "RESOURCE_LIST" => $crs_resource_summary{$key} } );
  }
  tfactlstore_store_hash_into_json( \@crs_resource_summary_list, $repository_loc, $hash_repository_loc );
}

sub sumcollection_crs_resource_category
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  return unless sumcollection_crs_check( $repository_loc, $hash_repository_loc );
  tfactlstore_summary_log( "Collect CRS Resource Category", "sumcollection_crs_resource_category" );
  my $dep_hash_ref = get_dependent_data( $tfa_home, "crs", "crs_resource_complete_details", $repository_base );
  my @crsResourcesStat = @{$dep_hash_ref};
  my %crs_resource_summary;
  my @crs_resource_summary_list;

  foreach my $resource (@crsResourcesStat)
  {
    my $description = $resource->{"DESCRIPTION"};
    my @resource_array;
    my $name = $resource->{"RESOURCE_NAME"};
    if ( exists $crs_resource_summary{$description} )
    {
      @resource_array = @{ $crs_resource_summary{$description} };
    }
    push( @resource_array, $name );
    $crs_resource_summary{$description} = \@resource_array;
  }
  foreach my $key ( keys %crs_resource_summary )
  {
    my %crs_resource_summary_list;
    $crs_resource_summary_list{"RESOURCE TYPE"} = $key;
    $crs_resource_summary_list{"RESOURCE LIST"} = $crs_resource_summary{$key};
    push( @crs_resource_summary_list, \%crs_resource_summary_list );
  }
  tfactlstore_store_hash_into_json( \@crs_resource_summary_list, $repository_loc, $hash_repository_loc );
}

sub sumcollection_crs_resource_statistics
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  return unless sumcollection_crs_check( $repository_loc, $hash_repository_loc );
  my $dep_hash_ref = get_dependent_data( $tfa_home, "crs", "crs_resource_complete_details", $repository_base );
  my @crsResourcesStat = @{$dep_hash_ref};
  my @crs_resource_statistics;

  foreach my $resource (@crsResourcesStat)
  {
    my %resource_stats;
    foreach my $resname ( keys %{$resource} )
    {
      next if ( $resname !~ /(RESOURCE_NAME|STOP_TIMEOUT|START_TIMEOUT|LOGGING_LEVEL)/ );
      $resource_stats{$resname} = $resource->{$resname};
    }
    push( @crs_resource_statistics, \%resource_stats );
  }
  tfactlstore_store_hash_into_json( \@crs_resource_statistics, $repository_loc, $hash_repository_loc );
}

sub sumcollection_crs_resource_complete_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  return unless sumcollection_crs_check( $repository_loc, $hash_repository_loc );
  my %crsResourcesStat = collectionutil_get_crs_resource_details();
  my @crs_resource_details;

  foreach my $res ( keys %crsResourcesStat )
  {
    my %tmp;
    foreach my $line ( split /\n/, $crsResourcesStat{$res} )
    {
      if ( $line && $line =~ /^(.*)=(.*)/ )
      {
        if ( $1 ne "SCAN_NAME" and $1 ne "USR_ORA_VIP" )
        {
          $tmp{$1} = $2;
        }
      }
    }
    $tmp{'RESOURCE_NAME'} = $res;
    push( @crs_resource_details, \%tmp );
  }
  tfactlstore_store_hash_into_json( \@crs_resource_details, $repository_loc, $hash_repository_loc );
}
##############################################
# ASM STATUS
##############################################
sub sumcollection_asm_clusterwide_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $dep_hash_ref = get_dependent_data( $tfa_home, "asmoverview", "asm_clusterwide_status", $repository_base );
  my @asm_clusterwide_status = @{$dep_hash_ref};
  my @asm_clusterwide_summary;
  my @asm_status;
  my $ASM_DISK_SIZE_STATUS = "OK";
  my $ASM_BLOCK_STATUS     = "PASS";
  my $ASM_CHAIN_STATUS     = "PASS";
  my $ASM_INCIDENTS        = "PASS";
  my $ASM_PROBLEMS         = "PASS";

  foreach my $status (@asm_clusterwide_status)
  {
    $ASM_DISK_SIZE_STATUS = "$status->{ASM_DISK_SIZE_STATUS}" if ( $status->{"ASM_DISK_SIZE_STATUS"} ne "GOOD" );
    $ASM_BLOCK_STATUS     = "$status->{ASM_BLOCK_STATUS}"     if ( $status->{"ASM_BLOCK_STATUS"} ne "PASS" );
    $ASM_CHAIN_STATUS     = "$status->{ASM_CHAIN_STATUS}"     if ( $status->{"ASM_CHAIN_STATUS"} ne "PASS" );
    $ASM_INCIDENTS        = "$status->{ASM_INCIDENTS}"        if ( $status->{"ASM_INCIDENTS"} ne "PASS" );
    $ASM_PROBLEMS         = "$status->{ASM_PROBLEMS}"         if ( $status->{"ASM_PROBLEMS"} ne "PASS" );
  }
  push( @asm_status, "ASM_DISK_SIZE_STATUS : " . $ASM_DISK_SIZE_STATUS );
  push( @asm_status, "ASM_BLOCK_STATUS     : " . $ASM_BLOCK_STATUS );
  push( @asm_status, "ASM_CHAIN_STATUS     : " . $ASM_CHAIN_STATUS );
  push( @asm_status, "ASM_INCIDENTS        : " . $ASM_INCIDENTS );
  push( @asm_status, "ASM_PROBLEMS         : " . $ASM_PROBLEMS );
  my $OVERALL_STATUS;
  if ( $ASM_PROBLEMS eq "OK" and $ASM_INCIDENTS eq "OK" )
  {
    $OVERALL_STATUS = "OK";
  } else
  {
    $OVERALL_STATUS = "PROBLEM";
  }
  push( @asm_clusterwide_summary, { "OVERALL_STATUS" => $OVERALL_STATUS, "SUMMARY" => \@asm_status } );
  tfactlstore_store_hash_into_json( \@asm_clusterwide_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_asm_clusterwide_status
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my @asm_clusterwide_status;
  my @nodelist = @{$SUMMARY_NODE_LIST_REF};
  foreach my $node (@nodelist)
  {
    my $repository_base_nodewise = catfile( $SUMMARY_REPOSITORY, $node );
    my $asm_status_summary;
    if ( $node ne $hostname )
    {
      my ( $status, $data ) = get_dependent_remote_data( $node, "asm", "asm_status_summary" );
      $asm_status_summary = $data;
      next if ( $status eq "false" );
    } else
    {
      $asm_status_summary = get_dependent_data( $tfa_home, "asm", "asm_status_summary", $repository_base_nodewise );
    }
    my $ASM_INSTANCE = "OFFLINE";
    my $ASM_DISK_SIZE_STATUS = "OFFLINE";
    my $ASM_CHAIN_STATUS = "OFFLINE";
    my $ASM_BLOCK_STATUS = "OFFLINE";
    my $ASM_INCIDENTS = "OFFLINE";
    my $ASM_PROBLEMS = "OFFLINE";
    foreach my $status ( @{$asm_status_summary} )
    {
      $ASM_INSTANCE         = $status->{STATUS}   if ( $status->{STATUS_TYPE} eq "ASM_INSTANCE" );
      $ASM_DISK_SIZE_STATUS = "$status->{STATUS}" if ( $status->{STATUS_TYPE} eq "ASM_DISK_SIZE_STATUS" );
      $ASM_CHAIN_STATUS     = $status->{STATUS}   if ( $status->{STATUS_TYPE} eq "ASM_CHAIN_STATUS" );
      $ASM_BLOCK_STATUS     = $status->{STATUS}   if ( $status->{STATUS_TYPE} eq "ASM_BLOCK_STATUS" );
      if ( $status->{STATUS_TYPE} eq "ADR_EVENTS" )
      {
        foreach my $details ( @{ $status->{STATUS} } )
        {
          if ( $details->{INSTANCE_NAME} =~ /ASM/ )
          {
            $ASM_INCIDENTS = $details->{INCIDENT_STATUS};
            $ASM_PROBLEMS  = $details->{PROBLEM_STATUS};
          }
        }
      }
    }
    push(
          @asm_clusterwide_status,
          {
            "HOSTNAME"             => $node,
            "ASM_INSTANCE"         => $ASM_INSTANCE,
            "ASM_DISK_SIZE_STATUS" => $ASM_DISK_SIZE_STATUS,
            "ASM_CHAIN_STATUS"     => $ASM_CHAIN_STATUS,
            "ASM_BLOCK_STATUS"     => $ASM_BLOCK_STATUS,
            "ASM_INCIDENTS"        => $ASM_INCIDENTS,
            "ASM_PROBLEMS"         => $ASM_PROBLEMS
          }
    );
  }
  tfactlstore_store_hash_into_json( \@asm_clusterwide_status, $repository_loc, $hash_repository_loc );
}

sub sumcollection_asm_status_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  return unless sumcollection_asm_check( $repository_loc, $hash_repository_loc );
  my @asm_status_summary;
  my %asm_status_summary;
  push( @asm_status_summary, { 'STATUS_TYPE' => "SYSTEM_DATE",  'STATUS' => collectionutil_get_system_date() } );
  push( @asm_status_summary, { 'STATUS_TYPE' => "ASM_HOME",     'STATUS' => collectionutil_get_asm_home() } );
  push( @asm_status_summary, { 'STATUS_TYPE' => "ASM_VERSION",  'STATUS' => collectionutil_get_asm_version() } );
  push( @asm_status_summary, { 'STATUS_TYPE' => "ASM_INSTANCE", 'STATUS' => collectionutil_get_asm_instance() } );
  push( @asm_status_summary,
        { 'STATUS_TYPE' => "ASM_DIAGNOSTICS_TRACE_FOLDER", 'STATUS' => collectionutil_get_asm_diag_trace_folder() } );
  my $asm_hang_analysis = get_dependent_data( $tfa_home, "asm", "asm_hang_analysis", $repository_base );
  push( @asm_status_summary, { 'STATUS_TYPE' => "ASM_CHAIN_STATUS", 'STATUS' => $asm_hang_analysis->[0]->{DETAILS} } );
  push( @asm_status_summary, { 'STATUS_TYPE' => "ASM_BLOCK_STATUS", 'STATUS' => $asm_hang_analysis->[1]->{DETAILS} } );
  my $dep_hash_ref = get_dependent_data( $tfa_home, "asm", "asm_diskgroup_details", $repository_base );
  my @asm_diskgroup_details = @{$dep_hash_ref};
  my @disk_summary;
  my $status = "GOOD";

  foreach my $hash_ref (@asm_diskgroup_details)
  {
    my %disk_summary;
    $disk_summary{'name'}            = $hash_ref->{'name'};
    $disk_summary{'disk_size_alert'} = $hash_ref->{'disk_size_alert'};
    $status = "WARNING - Available Size < 20%" if ( $disk_summary{'disk_size_alert'} =~ m/Red/ );
    push( @disk_summary, \%disk_summary );
  }
  $status = "BAD : ASM Disk Not Found" if ( $#asm_diskgroup_details == -1 );
  push( @asm_status_summary, { 'STATUS_TYPE' => "ASM_DISK_SIZE_STATUS",   'STATUS' => $status } );
  push( @asm_status_summary, { 'STATUS_TYPE' => "ASM_DISK_GROUP_SUMMARY", 'STATUS' => \@disk_summary } );
  my %incidents;
  my $crs_incidents = get_dependent_data( $tfa_home, "asm", "asm_incidents", $repository_base );
  foreach my $adr_summary_all ( @{$crs_incidents} )
  {

    foreach my $adr_summary ( @{ $adr_summary_all->{'ADR_EVENTS'} } )
    {
      next if ( $adr_summary->{'STATUS_TYPE'} =~ /(INCIDENTS|ORACLE_HOME|ADR_HOME)/ );
      my ( $instance, $INCIDENTS ) = split( /:/, $adr_summary->{'DETAILS'} );
      next if ( $instance !~ /ASM/ );
      $incidents{$instance} = $INCIDENTS;
    }
  }
  my @adr;
  my $crs_problems = get_dependent_data( $tfa_home, "asm", "asm_problems", $repository_base );
  foreach my $adr_summary_all ( @{$crs_problems} )
  {
    foreach my $adr_summary ( @{ $adr_summary_all->{'ADR_EVENTS'} } )
    {
      next if ( $adr_summary->{'STATUS_TYPE'} =~ /(PROBLEMS|ORACLE_HOME|ADR_HOME)/ );
      my ( $instance, $PROBLEMS ) = split( /:/, $adr_summary->{'DETAILS'} );
      next if ( $instance !~ /ASM/ );
      push(
            @adr,
            {
              'HOSTNAME'        => $hostname,
              'INSTANCE_NAME'   => $instance,
              'PROBLEM_STATUS'  => $PROBLEMS,
              'INCIDENT_STATUS' => $incidents{$instance}
            }
      );
    }
  }
  push( @asm_status_summary, { 'STATUS_TYPE' => "ADR_EVENTS", 'STATUS' => \@adr } );
  tfactlstore_store_hash_into_json( \@asm_status_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_asm_hang_analysis
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  return unless sumcollection_asm_check( $repository_loc, $hash_repository_loc );
  my @asm_hang_analysis;
  my %asm_hanganalyse = %{ collectionutil_check_asm_hanganalyze() };
  tfactlstore_summary_log( "CHECK", "sumcollection_asm_hang_analysis" );

  foreach my $key ( keys %asm_hanganalyse )
  {
    tfactlstore_summary_log( "$key => $asm_hanganalyse{$key}", "sumcollection_asm_status_summary" );
  }
  if ( $asm_hanganalyse{'no_chain'} eq "FAIL" )
  {
    push( @asm_hang_analysis, { "ANALYSIS" => "ASM_CHAIN_STATUS", "DETAILS" => "FAIL" } );
  } else
  {
    push( @asm_hang_analysis, { "ANALYSIS" => "ASM_CHAIN_STATUS", "DETAILS" => "PASS" } );
  }
  if ( $asm_hanganalyse{'blocked'} eq "FAIL" )
  {
    push( @asm_hang_analysis, { "ANALYSIS" => "ASM_BLOCK_STATUS", "DETAILS" => "FAIL" } );
  } else
  {
    push( @asm_hang_analysis, { "ANALYSIS" => "ASM_BLOCK_STATUS", "DETAILS" => "PASS" } );
  }
  if ( $asm_hanganalyse{'no_chain'} eq "FAIL" )
  {
    push( @asm_hang_analysis, { "ANALYSIS" => "ASM_CHAIN_SUMMARY", "DETAILS" => $asm_hanganalyse{"CHAIN_DETAILS"} } );
  }
  if ( $asm_hanganalyse{'blocked'} eq "FAIL" )
  {
    push( @asm_hang_analysis, { "ANALYSIS" => "ASM_BLOCK_SUMMARY", "DETAILS" => $asm_hanganalyse{'waiting'} } );
  }
  push( @asm_hang_analysis,
        { "ANALYSIS" => "TRACE_FILE_LOCATION", "DETAILS" => $asm_hanganalyse{"TRACE_FILE_LOCATION"} } );
  tfactlstore_store_hash_into_json( \@asm_hang_analysis, $repository_loc, $hash_repository_loc );
}

sub sumcollection_asm_diskgroup_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  return unless sumcollection_asm_check( $repository_loc, $hash_repository_loc );
  my @disk_details;
  my $asm_disk_groups = collectionutil_get_asmdiskgroup_view();
  if ( $asm_disk_groups && length($asm_disk_groups) != 0 )
  {
    chomp($asm_disk_groups);
    $asm_disk_groups =~ s/^\n//g;

    my @disks;
    foreach my $x ( split /\n/, $asm_disk_groups )
    {
      my @tmp = split /:/, $x;
      my %hash;
      $hash{"group_number"}         = $tmp[0];
      $hash{"name"}                 = $tmp[1];
      $hash{"allocation_unit_size"} = $tmp[2];
      $hash{"state"}                = $tmp[3];
      $hash{"type"}                 = $tmp[4];
      $hash{"total_mb"}             = $tmp[5];
      $hash{"usable_file_mb"}       = $tmp[6];
      my $usable_file_mb = $tmp[6];
      my $total_mb       = $tmp[5];
      my $percent;
      my $alert = "Red : NULL";

      if ( $total_mb != 0 )
      {
        $percent = floor( ( ( $usable_file_mb * 100 ) / $total_mb ) );
        if ( $percent > 50 )
        {
          $alert = "Green : ${percent}%";
        } elsif ( $percent > 20 && $percent < 50 )
        {
          $alert = "Yellow : ${percent}%";
        } else
        {
          $alert = "Red : ${percent}%";
        }
      }
      $hash{"disk_size_alert"} = $alert;
      push( @disk_details, \%hash );
    }
  }
  tfactlstore_store_hash_into_json( \@disk_details, $repository_loc, $hash_repository_loc );
}

sub sumcollection_asm_volumes
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  return unless sumcollection_asm_check( $repository_loc, $hash_repository_loc );
  my @volume_details;
  my $asm_disk_volumes = collectionutil_get_asmdiskvolumes_view();
  if ( $asm_disk_volumes && length($asm_disk_volumes) != 0 )
  {
    chomp($asm_disk_volumes);
    $asm_disk_volumes =~ s/^\n//g;

    foreach my $x ( split /\n/, $asm_disk_volumes )
    {
      my @tmp = split /:/, $x;
      my %hash;
      #$hash{"name"}          = $tmp[0];
      $hash{"path"}          = $tmp[1];
      $hash{"header_status"} = $tmp[2];
      $hash{"total_mb"}      = $tmp[3];
      $hash{"free_mb"}       = $tmp[4];
      $hash{"bytes_read"}    = $tmp[5];
      $hash{"bytes_written"} = $tmp[6];
      my $usable_file_mb = $tmp[4];
      my $total_mb       = $tmp[3];
      my $percent        = "Red : NULL";
      my $alert;

      if ( $total_mb != 0 )
      {
        $percent = floor( ( ( $usable_file_mb * 100 ) / $total_mb ) );
        if ( $percent > 50 )
        {
          $alert = "Green : ${percent}%";
        } elsif ( $percent > 20 && $percent < 50 )
        {
          $alert = "Yellow : ${percent}%";
        } else
        {
          $alert = "Red : ${percent}%";
        }
      }
      $hash{"% Used"} = $alert;
      push( @volume_details, \%hash );
    }
  }
  tfactlstore_store_hash_into_json( \@volume_details, $repository_loc, $hash_repository_loc );
}

sub sumcollection_asm_instancefiles
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  return unless sumcollection_asm_check( $repository_loc, $hash_repository_loc );
  my @file_type;
  my $asm_instance_files = collectionutil_get_asm_instance_files();
  if ( $asm_instance_files && length($asm_instance_files) != 0 )
  {
    chomp($asm_instance_files);
    $asm_instance_files =~ s/^\n//g;

    foreach my $x ( split /\n/, $asm_instance_files )
    {
      my @tmp = split /:/, $x;
      my %hash;
      $hash{"group_number"}      = $tmp[0];
      $hash{"file_number"}       = $tmp[1];
      $hash{"compound_index"}    = $tmp[2];
      $hash{"incarnation"}       = $tmp[3];
      $hash{"block_size"}        = $tmp[4];
      $hash{"bytes"}             = $tmp[5];
      $hash{"name"}              = $tmp[6];
      $hash{"striped"}           = $tmp[7];
      $hash{"creation_date"}     = $tmp[8];
      $hash{"modification_date"} = $tmp[9];
      next if ( $tmp[6] eq "" );
      push( @file_type, \%hash );
    }
  }
  tfactlstore_store_hash_into_json( \@file_type, $repository_loc, $hash_repository_loc );
}

sub sumcollection_asm_incidents
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  return unless sumcollection_asm_check( $repository_loc, $hash_repository_loc );
  my %asm_events = %{ collectionutil_get_events( "incidents", "CRS" ) };
  my @asm_incidents;
  foreach my $home_details ( keys %asm_events )
  {

    foreach my $home ( keys %{ $asm_events{$home_details} } )
    {
      push( @asm_incidents, { 'ADR_EVENTS' => $asm_events{$home_details}{$home} } );
    }
  }
  tfactlstore_store_hash_into_json( \@asm_incidents, $repository_loc, $hash_repository_loc );
}

sub sumcollection_asm_problems
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  return unless sumcollection_asm_check( $repository_loc, $hash_repository_loc );
  my %asm_events = %{ collectionutil_get_events( "problems", "CRS" ) };
  my @asm_problems;
  foreach my $home_details ( keys %asm_events )
  {

    foreach my $home ( keys %{ $asm_events{$home_details} } )
    {
      push( @asm_problems, { 'ADR_EVENTS' => $asm_events{$home_details}{$home} } );
    }
  }
  tfactlstore_store_hash_into_json( \@asm_problems, $repository_loc, $hash_repository_loc );
}
##############################################
# DATABASE STATUS
##############################################
sub sumcollection_is_database_installed {
  return collectionutil_is_DB_installed($hostname);
}

sub sumcollection_database_clusterwide_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $dep_hash_ref =
    get_dependent_data( $tfa_home, "databaseoverview", "database_clusterwide_status", $repository_base );
  my @database_clusterwide_status;
  my $OVERALL_STATUS;

  foreach my $home_name ( @{$dep_hash_ref} )
  {
    my @db_details;
    foreach my $db_name ( @{ $home_name->{'ORACLE_HOME_DETAILS'} } )
    {
      my $INCIDENTS = "PASS";
      my $PROBLEMS  = "PASS";
      my $DB_CHAINS = "PASS";
      my $DB_BLOCKS = "PASS";
      my $STATUS    = "OK";
      foreach my $details ( @{ $db_name->{'DATABASE_DETAILS'} } )
      {
        $INCIDENTS = "PROBLEM" if ( $details->{'INCIDENTS'} ne "PASS" );
        $PROBLEMS  = "PROBLEM" if ( $details->{'PROBLEMS'} ne "PASS" );
        $DB_CHAINS = "PROBLEM" if ( $details->{'DB_CHAINS'} ne "PASS" );
        $DB_BLOCKS = "PROBLEM" if ( $details->{'DB_BLOCKS'} ne "PASS" );
        if ( $INCIDENTS eq "PROBLEM" or $PROBLEMS eq "PROBLEM" or $DB_CHAINS eq "PROBLEM" or $DB_BLOCKS eq "PROBLEM" )
        {
          $STATUS         = "PROBLEM";
          $OVERALL_STATUS = "PROBLEM";
        }
      }
      push(
            @db_details,
            {
              "DATABASE_NAME" => $db_name->{'DATABASE_NAME'},
              "INCIDENTS"     => $INCIDENTS,
              "PROBLEMS"      => $PROBLEMS,
              "DB_CHAINS"     => $DB_CHAINS,
              "DB_BLOCKS"     => $DB_BLOCKS,
              "STATUS"        => $STATUS
            }
      );
    }
    push( @database_clusterwide_status,
          { "ORACLE_HOME_NAME" => $home_name->{'ORACLE_HOME_NAME'}, "ORACLE_HOME_DETAILS" => \@db_details } );
  }
  my @database_clusterwide_summary;
  push( @database_clusterwide_summary,
        { "OVERALL_STATUS" => $OVERALL_STATUS, "SUMMARY" => \@database_clusterwide_status } );
  tfactlstore_store_hash_into_json( \@database_clusterwide_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_problem_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $dep_hash_ref =
    get_dependent_data( $tfa_home, "databaseoverview", "database_clusterwide_status", $repository_base );
  my @database_problem_summary;
  my @database_clusterwide_status;
  my $OVERALL_STATUS;
  my @oh_inc_details;
  my @oh_pro_details;
  my @oh_chain_details;
  my @oh_block_details;

  foreach my $home_name ( @{$dep_hash_ref} )
  {
    my @db_inc_details;
    my @db_pro_details;
    my @db_chain_details;
    my @db_block_details;
    foreach my $db_name ( @{ $home_name->{'ORACLE_HOME_DETAILS'} } )
    {
      my @inc_instance_list;
      my @pro_instance_list;
      my @chain_instance_list;
      my @block_instance_list;
      foreach my $details ( @{ $db_name->{'DATABASE_DETAILS'} } )
      {
        if ( $details->{'INCIDENTS'} ne "PASS" )
        {
          push( @inc_instance_list, "$details->{'HOSTNAME'}:$details->{'INSTANCE_NAME'}" );
        }
        if ( $details->{'PROBLEMS'} ne "PASS" )
        {
          push( @pro_instance_list, "$details->{'HOSTNAME'}:$details->{'INSTANCE_NAME'}" );
        }
        if ( $details->{'DB_CHAINS'} ne "PASS" )
        {
          push( @chain_instance_list, "$details->{'HOSTNAME'}:$details->{'INSTANCE_NAME'}" );
        }
        if ( $details->{'DB_BLOCKS'} ne "PASS" )
        {
          push( @block_instance_list, "$details->{'HOSTNAME'}:$details->{'INSTANCE_NAME'}" );
        }
      }
      if ( $#inc_instance_list != -1 )
      {
        push( @db_inc_details,
              { "DATABASE_NAME" => $db_name->{'DATABASE_NAME'}, "INSTANCE_DETAILS" => "@inc_instance_list" } )
          if ( $#inc_instance_list != -1 );
      }
      if ( $#pro_instance_list != -1 )
      {
        push( @db_pro_details,
              { "DATABASE_NAME" => $db_name->{'DATABASE_NAME'}, "INSTANCE_DETAILS" => "@pro_instance_list" } )
          if ( $#pro_instance_list != -1 );
      }
      if ( $#chain_instance_list != -1 )
      {
        push( @db_chain_details,
              { "DATABASE_NAME" => $db_name->{'DATABASE_NAME'}, "INSTANCE_DETAILS" => "@chain_instance_list" } )
          if ( $#chain_instance_list != -1 );
      }
      if ( $#block_instance_list != -1 )
      {
        push( @db_block_details,
              { "DATABASE_NAME" => $db_name->{'DATABASE_NAME'}, "INSTANCE_DETAILS" => "@block_instance_list" } )
          if ( $#block_instance_list != -1 );
      }
    }
    push( @oh_inc_details, { "OH_NAME" => $home_name->{ORACLE_HOME_NAME}, "OH_DETAILS" => \@db_inc_details } )
      if ( $#db_inc_details != -1 );
    push( @oh_pro_details, { "OH_NAME" => $home_name->{ORACLE_HOME_NAME}, "OH_DETAILS" => \@db_pro_details } )
      if ( $#db_pro_details != -1 );
    push( @oh_chain_details, { "OH_NAME" => $home_name->{ORACLE_HOME_NAME}, "OH_DETAILS" => \@db_chain_details } )
      if ( $#db_chain_details != -1 );
    push( @oh_block_details, { "OH_NAME" => $home_name->{ORACLE_HOME_NAME}, "OH_DETAILS" => \@db_block_details } )
      if ( $#db_block_details != -1 );
  }
  push( @database_problem_summary, { "PROBLEM_TYPE" => "INCIDENTS", "DETAILS" => \@oh_inc_details } )
    if ( $#oh_inc_details != -1 );
  push( @database_problem_summary, { "PROBLEM_TYPE" => "PROBLEMS", "DETAILS" => \@oh_pro_details } )
    if ( $#oh_pro_details != -1 );
  push( @database_problem_summary, { "PROBLEM_TYPE" => "DB_CHAINS", "DETAILS" => \@oh_chain_details } )
    if ( $#oh_chain_details != -1 );
  push( @database_problem_summary, { "PROBLEM_TYPE" => "DB_BLOCKS", "DETAILS" => \@oh_block_details } )
    if ( $#oh_block_details != -1 );
  tfactlstore_store_hash_into_json( \@database_problem_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_problems_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $dep_hash_ref = get_dependent_data( $tfa_home, "databaseoverview", "database_clusterwide_status", $repository_base );
  my @database_problem_summary;
  my @database_clusterwide_status;
  my @oh_pro_details;

  foreach my $home_name ( @{$dep_hash_ref} )
  {
    my @db_pro_details;
    foreach my $db_name ( @{ $home_name->{'ORACLE_HOME_DETAILS'} } )
    {
      my @pro_instance_list;
      foreach my $details ( @{ $db_name->{'DATABASE_DETAILS'} } )
      {
        if ( $details->{'PROBLEMS'} ne "PASS" )
        {
          push( @pro_instance_list, "$details->{'HOSTNAME'}:$details->{'INSTANCE_NAME'}" );
        }
      }
      if ( $#pro_instance_list != -1 )
      {
        push( @db_pro_details, { "DATABASE_NAME" => $db_name->{'DATABASE_NAME'}, "INSTANCE_DETAILS" => "@pro_instance_list" } ) if ( $#pro_instance_list != -1 );
      }
    }
    if ( $#db_pro_details != -1 ){
      push( @oh_pro_details, { "OH_NAME" => $home_name->{ORACLE_HOME_NAME}, "OH_DETAILS" => \@db_pro_details } );
    } else {
      push( @oh_pro_details, { "OH_NAME" => $home_name->{ORACLE_HOME_NAME}, "OH_DETAILS" => "Problems Not Found" } );
    }
  }
  push( @database_problem_summary, { "PROBLEM_TYPE" => "PROBLEMS", "DETAILS" => \@oh_pro_details } ) if ( $#oh_pro_details != -1 );
  tfactlstore_store_hash_into_json( \@database_problem_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_incidents_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $dep_hash_ref =
    get_dependent_data( $tfa_home, "databaseoverview", "database_clusterwide_status", $repository_base );
  my @database_problem_summary;
  my @database_clusterwide_status;
  my @oh_inc_details;

  foreach my $home_name ( @{$dep_hash_ref} )
  {
    my @db_inc_details;
    foreach my $db_name ( @{ $home_name->{'ORACLE_HOME_DETAILS'} } )
    {
      my @inc_instance_list;
      foreach my $details ( @{ $db_name->{'DATABASE_DETAILS'} } )
      {
        if ( $details->{'INCIDENTS'} ne "PASS" )
        {
          push( @inc_instance_list, "$details->{'HOSTNAME'}:$details->{'INSTANCE_NAME'}" );
        }
      }
      if ( $#inc_instance_list != -1 )
      {
        push( @db_inc_details,
              { "DATABASE_NAME" => $db_name->{'DATABASE_NAME'}, "INSTANCE_DETAILS" => "@inc_instance_list" } )
          if ( $#inc_instance_list != -1 );
      }
    }
    if ( $#db_inc_details != -1 ){
      push( @oh_inc_details, { "OH_NAME" => $home_name->{ORACLE_HOME_NAME}, "OH_DETAILS" => \@db_inc_details } );
    } else {
      push( @oh_inc_details, { "OH_NAME" => $home_name->{ORACLE_HOME_NAME}, "OH_DETAILS" => "Incidents Not Found" } );
    }
  }
  push( @database_problem_summary, { "PROBLEM_TYPE" => "INCIDENTS", "DETAILS" => \@oh_inc_details } )
    if ( $#oh_inc_details != -1 );
  tfactlstore_store_hash_into_json( \@database_problem_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_hang_analysis_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $dep_hash_ref =
    get_dependent_data( $tfa_home, "databaseoverview", "database_clusterwide_status", $repository_base );
  my @database_problem_summary;
  my @database_clusterwide_status;
  my @oh_chain_details;
  my @oh_block_details;

  foreach my $home_name ( @{$dep_hash_ref} )
  {
    my @db_chain_details;
    my @db_block_details;
    foreach my $db_name ( @{ $home_name->{'ORACLE_HOME_DETAILS'} } )
    {
      my @chain_instance_list;
      my @block_instance_list;
      foreach my $details ( @{ $db_name->{'DATABASE_DETAILS'} } )
      {
        if ( $details->{'DB_CHAINS'} ne "PASS" )
        {
          push( @chain_instance_list, "$details->{'HOSTNAME'}:$details->{'INSTANCE_NAME'}" );
        }
        if ( $details->{'DB_BLOCKS'} ne "PASS" )
        {
          push( @block_instance_list, "$details->{'HOSTNAME'}:$details->{'INSTANCE_NAME'}" );
        }
      }
      if ( $#chain_instance_list != -1 )
      {
        push( @db_chain_details,
              { "DATABASE_NAME" => $db_name->{'DATABASE_NAME'}, "INSTANCE_DETAILS" => "@chain_instance_list" } )
          if ( $#chain_instance_list != -1 );
      }
      if ( $#block_instance_list != -1 )
      {
        push( @db_block_details,
              { "DATABASE_NAME" => $db_name->{'DATABASE_NAME'}, "INSTANCE_DETAILS" => "@block_instance_list" } )
          if ( $#block_instance_list != -1 );
      }
    }
    push( @oh_chain_details, { "OH_NAME" => $home_name->{ORACLE_HOME_NAME}, "OH_DETAILS" => \@db_chain_details } )
      if ( $#db_chain_details != -1 );
    push( @oh_block_details, { "OH_NAME" => $home_name->{ORACLE_HOME_NAME}, "OH_DETAILS" => \@db_block_details } )
      if ( $#db_block_details != -1 );
  }
  if ( $#oh_chain_details != -1 ){
    push( @database_problem_summary, { "PROBLEM_TYPE" => "DB_CHAINS", "DETAILS" => \@oh_chain_details } );
  } else {
    push( @database_problem_summary, { "PROBLEM_TYPE" => "DB_CHAINS", "DETAILS" => "Chains Not Found" } );
  }

  if ( $#oh_block_details != -1 ){
    push( @database_problem_summary, { "PROBLEM_TYPE" => "DB_BLOCKS", "DETAILS" => \@oh_block_details } );
  } else {
    push( @database_problem_summary, { "PROBLEM_TYPE" => "DB_BLOCKS", "DETAILS" => "Blocks Not Found" } );
  }

  tfactlstore_store_hash_into_json( \@database_problem_summary, $repository_loc, $hash_repository_loc );
}


sub sumcollection_database_clusterwide_status
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my @nodelist = @{$SUMMARY_NODE_LIST_REF};
  my @database_clusterwide_status;
  my %clusterwide_details;

  foreach my $node (@nodelist)
  {
    my $repository_base_nodewise = catfile( $SUMMARY_REPOSITORY, $node );
    my $dep_hash_ref;
    if ( $node ne $hostname )
    {
      my ( $status, $data ) = get_dependent_remote_data( $node, "database", "database_status_summary" );
      $dep_hash_ref = $data;
      next if ( $status eq "false" );
    } else
    {
      $dep_hash_ref = get_dependent_data( $tfa_home, "database", "database_status_summary", $repository_base_nodewise );
    }
    foreach my $home_name ( @{$dep_hash_ref} )
    {
      my @db_details;
      foreach my $db_name ( @{ $home_name->{'ORACLE_HOME_DETAILS'} } )
      {
        my %instance_details;
        foreach my $details ( @{ $db_name->{'DATABASE_DETAILS'} } )
        {
          $instance_details{INSTANCE_NAME} = $details->{'DETAILS'} if ( $details->{'STATUS_TYPE'} =~ /INSTANCE_NAME/ );
          $instance_details{STATUS}        = $details->{'DETAILS'} if ( $details->{'STATUS_TYPE'} eq "STATUS" );
          $instance_details{INCIDENTS} = $details->{'DETAILS'} if ( $details->{'STATUS_TYPE'} =~ /INCIDENT_STATUS/ );
          $instance_details{PROBLEMS}  = $details->{'DETAILS'} if ( $details->{'STATUS_TYPE'} =~ /PROBLEMS_STATUS/ );
          $instance_details{DB_CHAINS} = $details->{'DETAILS'} if ( $details->{'STATUS_TYPE'} =~ /DB_CHAINS_STATUS/ );
          $instance_details{DB_BLOCKS} = $details->{'DETAILS'} if ( $details->{'STATUS_TYPE'} =~ /DB_BLOCKS_STATUS/ );
          $instance_details{HOSTNAME}  = $node;
        }
        my @cluster_data;
        if ( exists $clusterwide_details{ $home_name->{'ORACLE_HOME_NAME'} }{ $db_name->{'DATABASE_NAME'} } )
        {
          @cluster_data = @{ $clusterwide_details{ $home_name->{'ORACLE_HOME_NAME'} }{ $db_name->{'DATABASE_NAME'} } };
        }
        push( @cluster_data, \%instance_details );
        $clusterwide_details{ $home_name->{'ORACLE_HOME_NAME'} }{ $db_name->{'DATABASE_NAME'} } = \@cluster_data;
      }
    }
  }
  foreach my $home_name ( keys %clusterwide_details )
  {
    my @db_details;
    foreach my $db_name ( keys %{ $clusterwide_details{$home_name} } )
    {
      push( @db_details,
            { "DATABASE_NAME" => $db_name, 'DATABASE_DETAILS' => $clusterwide_details{$home_name}{$db_name} } );
    }
    push( @database_clusterwide_status, { "ORACLE_HOME_NAME" => $home_name, "ORACLE_HOME_DETAILS" => \@db_details } );
  }
  tfactlstore_store_hash_into_json( \@database_clusterwide_status, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_status_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my @database_status_summary;
  my $database_configuration_details =
    get_dependent_data( $tfa_home, "database", "database_configuration_details", $repository_base );
  my $database_instance_details =
    get_dependent_data( $tfa_home, "database", "database_instance_details", $repository_base );
  my $database_incidents   = get_dependent_data( $tfa_home, "database", "database_incidents",   $repository_base );
  my $database_problems    = get_dependent_data( $tfa_home, "database", "database_problems",    $repository_base );
  my $database_hanganalyze = get_dependent_data( $tfa_home, "database", "database_hanganalyze", $repository_base );
  my %config;

  foreach my $home_name ( @{$database_configuration_details} )
  {
    foreach my $db_name ( @{ $home_name->{'ORACLE_HOME_DETAILS'} } )
    {
      my @db_details = ();
      foreach my $details ( @{ $db_name->{'DATABASE_DETAILS'} } )
      {
        next if ( $details->{'STATUS_TYPE'} =~ /BANNER/ );
        push( @db_details, $details );
      }
      $config{ $home_name->{'ORACLE_HOME_NAME'} }{ $db_name->{'DATABASE_NAME'} } = \@db_details;
    }
  }
  my %instance;
  foreach my $home_name ( @{$database_instance_details} )
  {
    foreach my $db_name ( @{ $home_name->{'ORACLE_HOME_DETAILS'} } )
    {
      my @db_details = ();
      foreach my $details ( @{ $db_name->{'DATABASE_DETAILS'} } )
      {
        if ( $details->{'STATUS_TYPE'} =~ /STATUS/ )
        {
          foreach my $status_details ( @{ $details->{'DETAILS'} } )
          {
            if ( $status_details->{INSTANCE_NAME} eq "Not Running" or $config{ $home_name->{'ORACLE_HOME_NAME'} }{ $db_name->{'DATABASE_NAME'} }->[1]->{DETAILS} eq
                 $status_details->{INSTANCE_NAME} )
            {
              push( @db_details, { 'STATUS_TYPE' => "THREAD_NO", 'DETAILS' => $status_details->{THREAD_NO} } );
              push( @db_details, { 'STATUS_TYPE' => "STATUS",    'DETAILS' => $status_details->{STATUS} } );
              push( @db_details, { 'STATUS_TYPE' => "ARCHIVER",  'DETAILS' => $status_details->{ARCHIVER} } );
            }
          }
        }
      }
      $instance{ $home_name->{'ORACLE_HOME_NAME'} }{ $db_name->{'DATABASE_NAME'} } = \@db_details;
    }
  }
  my $INSTANCE_NAME;
  my %incidents;
  foreach my $home_name ( @{$database_incidents} )
  {
    foreach my $db_name ( @{ $home_name->{'ORACLE_HOME_DETAILS'} } )
    {
      my @db_details = ();
      foreach my $details ( @{ $db_name->{'DATABASE_DETAILS'} } )
      {
        foreach my $adr_summary ( @{ $details->{'ADR_DETAILS'} } )
        {
          next if ( $adr_summary->{'STATUS_TYPE'} =~ /(INCIDENTS|ORACLE_HOME|ADR_HOME)/ );
          my ( $instance, $INCIDENTS ) = split( /:/, $adr_summary->{'DETAILS'} );
          if ( $config{ $home_name->{'ORACLE_HOME_NAME'} }{ $db_name->{'DATABASE_NAME'} }->[1]->{DETAILS} eq $instance )
          {
            push( @db_details, { 'STATUS_TYPE' => "INCIDENT_STATUS", 'DETAILS' => $INCIDENTS } );
          }
        }
      }
      $incidents{ $home_name->{'ORACLE_HOME_NAME'} }{ $db_name->{'DATABASE_NAME'} } = \@db_details;
    }
  }
  my %problems;
  foreach my $home_name ( @{$database_problems} )
  {
    foreach my $db_name ( @{ $home_name->{'ORACLE_HOME_DETAILS'} } )
    {
      my @db_details = ();
      foreach my $details ( @{ $db_name->{'DATABASE_DETAILS'} } )
      {
        foreach my $adr_summary ( @{ $details->{'ADR_DETAILS'} } )
        {
          next if ( $adr_summary->{'STATUS_TYPE'} =~ /(PROBLEMS|ORACLE_HOME|ADR_HOME)/ );
          my ( $instance, $PROBLEMS ) = split( /:/, $adr_summary->{'DETAILS'} );
          if ( $config{ $home_name->{'ORACLE_HOME_NAME'} }{ $db_name->{'DATABASE_NAME'} }->[1]->{DETAILS} eq $instance )
          {
            push( @db_details, { 'STATUS_TYPE' => "PROBLEMS_STATUS", 'DETAILS' => $PROBLEMS } );
          }
        }
      }
      $problems{ $home_name->{'ORACLE_HOME_NAME'} }{ $db_name->{'DATABASE_NAME'} } = \@db_details;
    }
  }
  my %hangs;
  foreach my $home_name ( @{$database_hanganalyze} )
  {
    foreach my $db_name ( @{ $home_name->{'ORACLE_HOME_DETAILS'} } )
    {
      my @db_details = ();
      foreach my $details ( @{ $db_name->{'DATABASE_DETAILS'} } )
      {
        push( @db_details, { 'STATUS_TYPE' => "DB_CHAINS_STATUS", 'DETAILS' => $details->{'DETAILS'} } )
          if ( $details->{'ANALYSIS'} eq "DB_CHAIN_STATUS" );
        push( @db_details, { 'STATUS_TYPE' => "DB_BLOCKS_STATUS", 'DETAILS' => $details->{'DETAILS'} } )
          if ( $details->{'ANALYSIS'} eq "DB_BLOCK_STATUS" );
      }
      $hangs{ $home_name->{'ORACLE_HOME_NAME'} }{ $db_name->{'DATABASE_NAME'} } = \@db_details;
    }
  }
  foreach my $home_name ( sort keys %config )
  {
    my @oh_details = ();
    foreach my $db_name ( sort keys %{ $config{$home_name} } )
    {
      my @db_details = ();
      foreach my $details ( @{ $config{$home_name}{$db_name} } )
      {
        push( @db_details, $details );
      }
      foreach my $details ( @{ $instance{$home_name}{$db_name} } )
      {
        push( @db_details, $details );
      }
      foreach my $details ( @{ $incidents{$home_name}{$db_name} } )
      {
        push( @db_details, $details );
      }
      foreach my $details ( @{ $problems{$home_name}{$db_name} } )
      {
        push( @db_details, $details );
      }
      foreach my $details ( @{ $hangs{$home_name}{$db_name} } )
      {
        push( @db_details, $details );
      }
      push( @oh_details, { 'DATABASE_NAME' => $db_name, 'DATABASE_DETAILS' => \@db_details } );
    }
    push( @database_status_summary, { 'ORACLE_HOME_NAME' => $home_name, 'ORACLE_HOME_DETAILS' => \@oh_details } );
  }
  tfactlstore_store_hash_into_json( \@database_status_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_configuration_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %running_dbs_homes =
    %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
  my @db_config_details_final = ();
  foreach my $db_home_name ( keys %running_dbs_homes )
  {
    my %running_dbs = %{ $running_dbs_homes{$db_home_name} };
    my @db_config_details;
    my $SYSTEM_DATE = collectionutil_get_system_date();

    foreach my $db ( keys %running_dbs )
    {
      my @db_details;
      my @db_details_arr = split /\|/, $running_dbs{$db};
      push( @db_details, { 'STATUS_TYPE' => "SYSTEM_DATE",   'DETAILS' => $SYSTEM_DATE } );
      push( @db_details, { 'STATUS_TYPE' => "INSTANCE_NAME", 'DETAILS' => $db_details_arr[0] } );
      push( @db_details, { 'STATUS_TYPE' => "DB_HOME",       'DETAILS' => $db_details_arr[1] } );
      push( @db_details, { 'STATUS_TYPE' => "DB_USER",       'DETAILS' => $db_details_arr[2] } );
      push(
            @db_details,
            {
              'STATUS_TYPE' => "DB_DIAG_DEST",
              'DETAILS'     => collectionutil_get_db_diag_trace_folder( $db, $running_dbs{$db} )
            }
      );
      push(
            @db_details,
            {
              'STATUS_TYPE' => "NLS_CHARACTER_SET",
              'DETAILS'     => collectionutil_get_db_nls_character_set( $db, $running_dbs{$db} )
            }
      );
      my $invalid_objects = collectionutil_get_db_invalid_objects( $db, $running_dbs{$db} );
      push( @db_details, { 'STATUS_TYPE' => "INVALID_OBJECTS", 'DETAILS' => $invalid_objects . " " } );
      my $banner = collectionutil_get_db_banner( $db, $running_dbs{$db} );
      tfactlstore_summary_log( "BANNER:\n$banner", "sumcollection_database_status_summary" );
      my @banner_arr = ();

      foreach my $line ( split /\n/, $banner )
      {
        $line = trimString($line);
        push @banner_arr, $line;
      }
      push( @db_details,        { 'STATUS_TYPE'   => "BANNER", 'DETAILS'          => \@banner_arr } );
      push( @db_config_details, { 'DATABASE_NAME' => $db,      'DATABASE_DETAILS' => \@db_details } );
    }
    push( @db_config_details_final,
          { 'ORACLE_HOME_NAME' => $db_home_name, 'ORACLE_HOME_DETAILS' => \@db_config_details } );
  }
  tfactlstore_store_hash_into_json( \@db_config_details_final, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_instance_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %running_dbs_homes =
    %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
  my @running_db_instance_details_final = ();
  foreach my $db_home_name ( keys %running_dbs_homes )
  {
    my @running_db_instance_details = ();
    my %running_dbs                 = %{ $running_dbs_homes{$db_home_name} };
    foreach my $db ( keys %running_dbs )
    {
      my %tmp;
      my @instance_details;
      my $sga = collectionutil_get_db_sga( $db, $running_dbs{$db} );
      my @sga_array = ();
      foreach my $line ( split /\n/, $sga )
      {
        $line = trimString($line);
        my @tmp1 = split /:/, $line;
        my %sga_hash;
        if($tmp1[0] =~ m/Database is Not Running/){
          $sga_hash{'AREAS'} = "Not Running";
          $sga_hash{'SIZE'}  = "Not Running";
        } else {
          $sga_hash{'AREAS'} = $tmp1[0];
          $sga_hash{'SIZE'}  = $tmp1[1];
        }
        push @sga_array, \%sga_hash;
      }
      push( @instance_details, { 'STATUS_TYPE' => "SGA_SUMMARY", 'DETAILS' => \@sga_array } );

      my $parameter_instance = collectionutil_get_db_parameter_instances( $db, $running_dbs{$db} );
      my @parameter_instance_array = ();
      foreach my $line ( split /\n/, $parameter_instance )
      {
        $line = trimString($line);
        my @tmp1 = split /:/, $line;
        my %parameter_instance_hash;
        if($tmp1[0] =~ m/Database is Not Running/){
          $parameter_instance_hash{'INSTANCE_NAME'} = "Not Running";
          $parameter_instance_hash{'TYPE'}          = "Not Running";
          $parameter_instance_hash{'VALUE'}         = "Not Running";
        } else {
          $parameter_instance_hash{'INSTANCE_NAME'} = $tmp1[0];
          $parameter_instance_hash{'TYPE'}          = $tmp1[1];
          $parameter_instance_hash{'VALUE'}         = $tmp1[2];
        }
        push @parameter_instance_array, \%parameter_instance_hash;
      }

      push( @instance_details, { 'STATUS_TYPE' => "PARAMETERS", 'DETAILS' => \@parameter_instance_array } );

      my $instance_details = collectionutil_get_db_instance_details( $db, $running_dbs{$db} );
      my @instance_details_array = ();
      foreach my $line ( split /\n/, $instance_details )
      {
        $line = trimString($line);
        my @tmp1 = split /:/, $line;
        my %instance_details_hash;
        if($tmp1[0] =~ m/Database is Not Running/){
          $instance_details_hash{'INSTANCE_NAME'} = "Not Running";
          $instance_details_hash{'HOSTNAME'}      = "Not Running";
          $instance_details_hash{'ARCHIVER'}      = "Not Running";
          $instance_details_hash{'THREAD_NO'}     = "Not Running";
          $instance_details_hash{'STATUS'}        = "CLOSED";
        } else {
          $instance_details_hash{'INSTANCE_NAME'} = $tmp1[0];
          $instance_details_hash{'HOSTNAME'}      = $tmp1[1];
          $instance_details_hash{'ARCHIVER'}      = $tmp1[2];
          $instance_details_hash{'THREAD_NO'}     = $tmp1[3] . " ";
          $instance_details_hash{'STATUS'}        = $tmp1[4];
        }
        push @instance_details_array, \%instance_details_hash;
      }

      push( @instance_details, { 'STATUS_TYPE' => "STATUS", 'DETAILS' => \@instance_details_array } );
      my %db_details;

      push( @running_db_instance_details, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => \@instance_details } );

    }
    push( @running_db_instance_details_final,
          { 'ORACLE_HOME_NAME' => $db_home_name, 'ORACLE_HOME_DETAILS' => \@running_db_instance_details } );
  }

  tfactlstore_store_hash_into_json( \@running_db_instance_details_final, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_account_status
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %running_dbs_homes =
    %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
  my @running_db_account_details_final = ();
  foreach my $db_home_name ( keys %running_dbs_homes )
  {
    my %running_dbs                = %{ $running_dbs_homes{$db_home_name} };
    my @running_db_account_details = ();
    foreach my $db ( keys %running_dbs )
    {
      my $account_status = collectionutil_get_db_account_status( $db, $running_dbs{$db} );
      my @account_status_array = ();
      foreach my $line ( split /\n/, $account_status )
      {
        next if ( $line =~ /^\s*$/ );
        $line = trimString($line);
        my @tmp1 = split /:/, $line;
        my %account_status_hash;
        $account_status_hash{'USERNAME'} = $tmp1[0];
        $account_status_hash{'STATUS'}   = $tmp1[1];
        push @account_status_array, \%account_status_hash;
      }
      push( @running_db_account_details, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => \@account_status_array } );
    }
    push( @running_db_account_details_final,
          { 'ORACLE_HOME_NAME' => $db_home_name, 'ORACLE_HOME_DETAILS' => \@running_db_account_details } );
  }
  tfactlstore_store_hash_into_json( \@running_db_account_details_final, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_components_version
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %running_dbs_homes =
    %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
  my @running_db_components_final = ();
  foreach my $db_home_name ( keys %running_dbs_homes )
  {
    my %running_dbs           = %{ $running_dbs_homes{$db_home_name} };
    my @running_db_components = ();
    foreach my $db ( keys %running_dbs )
    {
      my $components = collectionutil_get_db_components_version( $db, $running_dbs{$db} );
      my @components_array = ();
      foreach my $line ( split /\n/, $components )
      {
        next if ( $line =~ /^\s*$/ );
        $line = trimString($line);
        my @tmp1 = split /:/, $line;
        my %components_hash;
        $components_hash{'NAME'}    = $tmp1[0];
        $components_hash{'VERSION'} = $tmp1[1];
        push @components_array, \%components_hash;
      }
      push( @running_db_components, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => \@components_array } );
    }
    push( @running_db_components_final,
          { 'ORACLE_HOME_NAME' => $db_home_name, 'ORACLE_HOME_DETAILS' => \@running_db_components } );
  }
  tfactlstore_store_hash_into_json( \@running_db_components_final, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_datafiles_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %running_dbs =
    %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
  my @running_db_datafiles = ();
  foreach my $db ( keys %running_dbs )
  {
    my %tmp;
    my $datafiles = collectionutil_get_db_datafiles_details( $db, $running_dbs{$db} );
    my @datafiles_array = ();
    foreach my $line ( split /\n/, $datafiles )
    {
      $line = trimString($line);
      my @tmp1 = split /:/, $line;
      my %datafiles_hash;
      $datafiles_hash{'FILENAME'} = $tmp1[0];
      $datafiles_hash{'SIZE'}     = $tmp1[1];
      push @datafiles_array, \%datafiles_hash;
    }
    my %db_details;

    $db_details{'DATABASE_NAME'} = $db;
    $db_details{'DETAILS'}       = \@datafiles_array;
    push @running_db_datafiles, \%db_details;
  }
  tfactlstore_store_hash_into_json( \@running_db_datafiles, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_tablespace_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %running_dbs_homes =
    %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
  my @running_db_tablespace_final = ();
  foreach my $db_home_name ( keys %running_dbs_homes )
  {
    my %running_dbs           = %{ $running_dbs_homes{$db_home_name} };
    my @running_db_tablespace = ();
    foreach my $db ( keys %running_dbs )
    {
      my $tablespace = collectionutil_get_db_tablespaces( $db, $running_dbs{$db} );
      tfactlstore_summary_log( "TABLESPACE:\n$tablespace", "sumcollection_database_tablespace_details" );
      my @tablespace_array = ();
      foreach my $line ( split /\n/, $tablespace )
      {
        $line = trimString($line);
        my @tmp1 = split /:/, $line;
        my %tablespace_hash;
        $tablespace_hash{'TABLESPACE_NAME'} = $tmp1[0];
        $tablespace_hash{'SIZE(MB)'}        = $tmp1[1];
        $tablespace_hash{'STATUS'}          = $tmp1[2];
        $tablespace_hash{'FILENAME'}        = $tmp1[3];
        push @tablespace_array, \%tablespace_hash;
      }
      push( @running_db_tablespace, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => \@tablespace_array } );
    }
    push( @running_db_tablespace_final,
          { 'ORACLE_HOME_NAME' => $db_home_name, 'ORACLE_HOME_DETAILS' => \@running_db_tablespace } );
  }
  tfactlstore_store_hash_into_json( \@running_db_tablespace_final, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_files_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %running_dbs =
    %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
  my @running_db_files = ();
  foreach my $db ( keys %running_dbs )
  {
    my %tmp;
    my $db_files = collectionutil_get_db_files( $db, $running_dbs{$db} );
    tfactlstore_summary_log( "DB FILES:\n$db_files", "sumcollection_database_files_details" );
    my @db_files_array = ();
    foreach my $line ( split /\n/, $db_files )
    {
      $line = trimString($line);
      my @tmp1 = split /:/, $line;
      my %db_files_hash;
      $db_files_hash{'NAME'} = $tmp1[0];
      push @db_files_array, \%db_files_hash;
    }
    my %db_details;
    $db_details{'DATABASE_NAME'} = $db;
    $db_details{'DETAILS'}       = \@db_files_array;
    push @running_db_files, \%db_details;
  }
  tfactlstore_store_hash_into_json( \@running_db_files, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_group_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %running_dbs_homes =
    %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
  my @running_db_groups_final = ();
  foreach my $db_home_name ( keys %running_dbs_homes )
  {
    my %running_dbs       = %{ $running_dbs_homes{$db_home_name} };
    my @running_db_groups = ();
    foreach my $db ( keys %running_dbs )
    {
      my $db_groups = collectionutil_get_db_groups_status( $db, $running_dbs{$db} );
      tfactlstore_summary_log( "DB GROUPS:\n$db_groups", "sumcollection_database_group_details" );
      my @db_groups_array = ();
      foreach my $line ( split /\n/, $db_groups )
      {
        $line = trimString($line);
        my @tmp1 = split /:/, $line;
        my %db_groups_hash;
        $db_groups_hash{'GROUP_NO'}                     = $tmp1[0];
        $db_groups_hash{'TYPE'}                         = $tmp1[1];
        $db_groups_hash{'MEMBER'}                       = $tmp1[2];
        $db_groups_hash{'IS_RECOVERY_DESTINATION_FILE'} = $tmp1[3];
        push @db_groups_array, \%db_groups_hash;
      }
      push( @running_db_groups, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => \@db_groups_array } );
    }
    push( @running_db_groups_final,
          { 'ORACLE_HOME_NAME' => $db_home_name, 'ORACLE_HOME_DETAILS' => \@running_db_groups } );
  }
  tfactlstore_store_hash_into_json( \@running_db_groups_final, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_hanganalyze
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %running_dbs_homes =
    %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
  my @running_db_hanganalyze_final = ();
  foreach my $db_home_name ( keys %running_dbs_homes )
  {
    my %running_dbs            = %{ $running_dbs_homes{$db_home_name} };
    my @running_db_hanganalyze = ();
    foreach my $db ( keys %running_dbs )
    {
      my %db_hanganalyze = %{collectionutil_check_db_hanganalyze( $db, $running_dbs{$db} )};
      my @db_hanganalyse_details;
      if(keys %db_hanganalyze == 0){
        push( @db_hanganalyse_details, { "ANALYSIS" => "DB_CHAIN_STATUS", "DETAILS" => "FAIL" } );
        push( @db_hanganalyse_details, { "ANALYSIS" => "DB_BLOCK_STATUS", "DETAILS" => "FAIL" } );
      } else {
        if ( $db_hanganalyze{'no_chain'} eq "FAIL" )
        {
          push( @db_hanganalyse_details, { "ANALYSIS" => "DB_CHAIN_STATUS", "DETAILS" => "FAIL" } );
        } else
        {
          push( @db_hanganalyse_details, { "ANALYSIS" => "DB_CHAIN_STATUS", "DETAILS" => "PASS" } );
        }
        if ( $db_hanganalyze{'blocked'} eq "FAIL" )
        {
          push( @db_hanganalyse_details, { "ANALYSIS" => "DB_BLOCK_STATUS", "DETAILS" => "FAIL" } );
        } else
        {
          push( @db_hanganalyse_details, { "ANALYSIS" => "DB_BLOCK_STATUS", "DETAILS" => "PASS" } );
        }
        if ( $db_hanganalyze{'no_chain'} eq "FAIL" )
        {
          push( @db_hanganalyse_details,
                { "ANALYSIS" => "DB_CHAIN_SUMMARY", "DETAILS" => $db_hanganalyze{"chain_list"} } );
        }
        if ( $db_hanganalyze{'blocked'} eq "FAIL" )
        {
          push( @db_hanganalyse_details,
                { "ANALYSIS" => "DB_CHAIN_SUMMARY", "DETAILS" => $db_hanganalyze{"block_list"} } );
        }
        if ( exists $db_hanganalyze{"TRACE_FILE_LOCATION"} )
        {
          push( @db_hanganalyse_details,
                { "ANALYSIS" => "TRACE_FILE_LOCATION", "DETAILS" => $db_hanganalyze{"TRACE_FILE_LOCATION"} } );
        }
      }
      push( @running_db_hanganalyze, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => \@db_hanganalyse_details } );
    }
    push( @running_db_hanganalyze_final,
          { 'ORACLE_HOME_NAME' => $db_home_name, 'ORACLE_HOME_DETAILS' => \@running_db_hanganalyze } );
  }
  tfactlstore_store_hash_into_json( \@running_db_hanganalyze_final, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_system_events
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %running_dbs_homes =
    %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
  my @running_db_events_final = ();
  foreach my $db_home_name ( keys %running_dbs_homes )
  {
    my %running_dbs       = %{ $running_dbs_homes{$db_home_name} };
    my %statstr = %{ get_dependent_data( $tfa_home, "database", "database_get_db_stat_details", $repository_base ) };
    %statstr = %{ $statstr{$db_home_name} };
    
    my @running_db_events = ();
    foreach my $db ( keys %running_dbs )
    {
      my @db_events_arr = collectionutil_check_system_events( ${ $statstr{$db} } );
      my @tmpArr = ();
      foreach my $x (@db_events_arr)
      {
        my @arr = @{$x};
        my %tmpHash;
        $tmpHash{'EVENT'}       = $arr[1];
        $tmpHash{'CLASS'}       = $arr[2];
        $tmpHash{'WAITS'}       = $arr[3];
        $tmpHash{'WAIT_TO'}     = $arr[4];
        $tmpHash{'TIME_WAITED'} = $arr[5];
        $tmpHash{'WAITS_FG'}    = $arr[6];
        $tmpHash{'WAITED_FG'}   = $arr[7];
        push @tmpArr, \%tmpHash;
      }
      if($#tmpArr == -1){
        push( @running_db_events, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => "System Events Not Found" } );
      } else {
        push( @running_db_events, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => \@tmpArr } );
      }
    }
    push( @running_db_events_final,
          { 'ORACLE_HOME_NAME' => $db_home_name, 'ORACLE_HOME_DETAILS' => \@running_db_events } );
  }
  tfactlstore_store_hash_into_json( \@running_db_events_final, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_statistics
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %running_dbs_homes =
    %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
  my @running_db_stats_final = ();
  foreach my $db_home_name ( keys %running_dbs_homes )
  {
    my %running_dbs = %{ $running_dbs_homes{$db_home_name} };
    my %statstr = %{ get_dependent_data( $tfa_home, "database", "database_get_db_stat_details", $repository_base ) };
    %statstr = %{ $statstr{$db_home_name} };
    my @running_db_stats = ();
    foreach my $db ( keys %running_dbs )
    {
      my @process_criteria = ( "dbname", "event", "sql" );
      my @statistics;
      foreach my $criteria (@process_criteria)
      {
        my ( $ref1, $ref2, $ref3 ) = collectionutil_process_db_stats( ${ $statstr{$db} }, $criteria );
        my %db_stats_sqlid_hash      = %{$ref1};
        my %processed_hash           = %{$ref2};
        my %retHash                  = %{$ref3};
        my $keys_db_stats_sqlid_hash = keys %db_stats_sqlid_hash;
        my $keys_retHash             = keys %retHash;
        my $keys_processed_hash      = keys %processed_hash;
        my @criteria_db_stats_arr    = ();

        if ($keys_db_stats_sqlid_hash)
        {
          foreach my $element ( keys %retHash )
          {
            my @arr = @{ $retHash{$element} };
            my %hash;
            if ( $criteria eq 'sql' )
            {
              my $event_name = $element;
              $event_name =~ s/\s+.*//g;
              $hash{'EVENT_NAME'} = $event_name;
            } else
            {
              $hash{'EVENT_NAME'} = $element;
            }
            $hash{'CPU_TIME'}  = $arr[0];
            $hash{'WAIT_TIME'} = $arr[1];
            $hash{'DB_TIME'}   = $arr[2];
            $hash{'PCTLOAD'}   = $arr[3];
            if ( $criteria eq "event" )
            {
              my $sqlid_list = $processed_hash{$element};
              my $wait_class = ${ $db_stats_sqlid_hash{ ( split /:/, $processed_hash{$element} )[0] } }[4];
              $hash{'WAIT_CLASS'} = $wait_class;
            } elsif ( $criteria eq "sql" )
            {
              my $sqlid_list = $processed_hash{$element};
              my $sqlid      = ( split /:/, $processed_hash{$element} )[0];
              my $user       = ${ $db_stats_sqlid_hash{ ( split /:/, $processed_hash{$element} )[0] } }[4];
              $hash{'USER'}  = $user;
              $hash{'SQLID'} = $sqlid;
            }
            push @criteria_db_stats_arr, \%hash;
          }
        }
        if($#criteria_db_stats_arr == -1){
          push( @statistics, { 'STAT_TYPE' => $criteria, 'STATISTICS' => "Database Statistics Data Not Found" } );
        } else {
          push( @statistics, { 'STAT_TYPE' => $criteria, 'STATISTICS' => \@criteria_db_stats_arr } );
        }
      }
      push( @running_db_stats, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => \@statistics } );
    }
    push( @running_db_stats_final,
          { 'ORACLE_HOME_NAME' => $db_home_name, 'ORACLE_HOME_DETAILS' => \@running_db_stats } );
  }

  tfactlstore_store_hash_into_json( \@running_db_stats_final, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_sql_statistics
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %running_dbs_homes =
    %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
  my @running_db_stats_final = ();
  foreach my $db_home_name ( keys %running_dbs_homes )
  {
    my %running_dbs = %{ $running_dbs_homes{$db_home_name} };
    my %statstr = %{ get_dependent_data( $tfa_home, "database", "database_get_db_stat_details", $repository_base ) };
    %statstr = %{ $statstr{$db_home_name} };
    my @running_db_stats = ();
    foreach my $db ( keys %running_dbs )
    {
      my @statistics;
      my $criteria = "exec";
      my ( $ref1, $ref2 ) = collectionutil_process_sql_stat( ${ $statstr{$db} }, $criteria );
      my %sql_stats_hash        = %{$ref1};
      my @retArr                = @{$ref2};
      my $keys_sql_stats_hash   = keys %sql_stats_hash;
      my @criteria_db_stats_arr = ();
      if ($keys_sql_stats_hash)
      {

        foreach my $sqlid (@retArr)
        {
          my @arr = @{ $sql_stats_hash{$sqlid} };
          my %hash;
          $hash{'SCHEMA'}      = $arr[0];
          $hash{'SQLID'}       = $arr[1];
          $hash{'TIME'}        = $arr[2];
          $hash{'EXEC_TIME'}   = $arr[3];
          $hash{'CPU_TIME'}    = $arr[4];
          $hash{'ELAPSE_TIME'} = $arr[5];
          $hash{'PARSE_TIME'}  = $arr[6];
          $hash{'FETCHES'}     = $arr[7];
          $hash{'ROWS'}        = $arr[8];

          #  $hash{'READS'} = $arr[9];
          #  $hash{'IOPS'} = $arr[10];
          $hash{'MB_BYTES'} = $arr[11];

          #  $hash{'OFFLOAD'} = $arr[12];
          $hash{'GETS'} = $arr[13];
          push @criteria_db_stats_arr, \%hash;
        }
      }
      if($#criteria_db_stats_arr == -1){
        push( @running_db_stats, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => "SQL Statistics Not Found" } );
      } else {
        push( @running_db_stats, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => \@criteria_db_stats_arr } );
      }
    }
    push( @running_db_stats_final,
          { 'ORACLE_HOME_NAME' => $db_home_name, 'ORACLE_HOME_DETAILS' => \@running_db_stats } );
  }

  tfactlstore_store_hash_into_json( \@running_db_stats_final, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_sqlmon_statistics
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %running_dbs_homes =
    %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
  my @running_db_stats_final = ();
  foreach my $db_home_name ( keys %running_dbs_homes )
  {
    my %running_dbs = %{ $running_dbs_homes{$db_home_name} };
    my %statstr = %{ get_dependent_data( $tfa_home, "database", "database_get_db_stat_details", $repository_base ) };
    %statstr = %{ $statstr{$db_home_name} };
    my @running_db_stats = ();
    foreach my $db ( keys %running_dbs )
    {
      my $criteria = "cpu";
      my ( $ref1, $ref2 ) = collectionutil_process_sql_monitor( ${ $statstr{$db} }, $criteria );
      my %sql_mon_hash          = %{$ref1};
      my @retArr                = @{$ref2};
      my $keys_sql_mon_hash     = keys %sql_mon_hash;
      my @criteria_db_stats_arr = ();
      if ($keys_sql_mon_hash)
      {

        foreach my $sqlid (@retArr)
        {
          my @arr = @{ $sql_mon_hash{$sqlid} };
          my %hash;

          #  $hash{'DB_NAME'} = $arr[0];
          $hash{'SQL_SOURCE'}   = $arr[1];
          $hash{'SQLID'}        = $arr[2];
          $hash{'ELAPSED_TIME'} = $arr[3];
          $hash{'CPU_TIME'}     = $arr[4];
          $hash{'QUEUE_TIME'}   = $arr[5];

          #  $hash{'APPLICATION'} = $arr[6];
          #  $hash{'CONCURRENCY'} = $arr[7];
          $hash{'CLUSTER'} = $arr[8];

          #  $hash{'USER_IO'} = $arr[9];
          $hash{'READS'}       = $arr[10];
          $hash{'WRITES'}      = $arr[11];
          $hash{'GETS'}        = $arr[12];
          $hash{'PLSQL_EXECS'} = $arr[13];
          $hash{'JAVA_EXECS'}  = $arr[14];
          $hash{'FETCHES'}     = $arr[15];
          push @criteria_db_stats_arr, \%hash;
        }
      }

      if($#criteria_db_stats_arr != -1){
        push( @running_db_stats, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => \@criteria_db_stats_arr } );
      } else {
        push( @running_db_stats, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => "SQLMON Data Not Found"} );
      }
       
    }
    push( @running_db_stats_final,
          { 'ORACLE_HOME_NAME' => $db_home_name, 'ORACLE_HOME_DETAILS' => \@running_db_stats } );
  }

  tfactlstore_store_hash_into_json( \@running_db_stats_final, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_get_running_db_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $running_dbs = collectionutil_getRunningDBsDetails($hostname);
  tfactlstore_store_hash_into_json( $running_dbs, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_get_db_stat_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %running_dbs_homes =
    %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
  my %db_stat_details_final;
  foreach my $db_home_name ( keys %running_dbs_homes )
  {
    my %running_dbs = %{ $running_dbs_homes{$db_home_name} };
    my %db_stat_details;
    foreach my $db ( keys %running_dbs )
    {
      my $retStr = collectionutil_get_db_stats( $db, $running_dbs{$db} );
      $db_stat_details{$db} = \$retStr;
    }
    $db_stat_details_final{$db_home_name} = \%db_stat_details;
  }
  tfactlstore_store_hash_into_json( \%db_stat_details_final, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_serverpool_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %running_dbs_homes =
    %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
  my @serverpool_details_final = ();
  foreach my $db_home_name ( keys %running_dbs_homes )
  {
    my %running_dbs = %{ $running_dbs_homes{$db_home_name} };
    my @serverpool_details = ();
    foreach my $db ( keys %running_dbs )
    {
      my $serverpool_details_ref = collectionutil_get_serverpool_details( \%running_dbs );
      push( @serverpool_details, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => $serverpool_details_ref } );
    }
    push( @serverpool_details_final,
          { 'ORACLE_HOME_NAME' => $db_home_name, 'ORACLE_HOME_DETAILS' => \@serverpool_details } );
  }
  tfactlstore_store_hash_into_json( \@serverpool_details_final, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_incidents
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %running_dbs_homes =
    %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
  my @running_db_events_final;
  foreach my $db_home_name ( keys %running_dbs_homes )
  {
    my %running_dbs = %{ $running_dbs_homes{$db_home_name} };
    my $db_events = collectionutil_get_events( "incidents", "DB", \%running_dbs );
    my @running_db_events;
    foreach my $db ( keys %running_dbs )
    {
      my @events_arr;
      foreach my $home ( keys %{$db_events} )
      {
        foreach my $adr_home ( keys %{ $db_events->{$home} } )
        {
          if ( $adr_home =~ /\W$db\W/ )
          {
            push( @events_arr, { 'ADR_DETAILS' => $db_events->{$home}->{$adr_home} } );
          }
        }
      }
      push( @running_db_events, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => \@events_arr } );
    }
    push( @running_db_events_final,
          { 'ORACLE_HOME_NAME' => $db_home_name, 'ORACLE_HOME_DETAILS' => \@running_db_events } );
  }
  tfactlstore_store_hash_into_json( \@running_db_events_final, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_problems
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %running_dbs_homes =
    %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
  my @running_db_events_final;
  foreach my $db_home_name ( keys %running_dbs_homes )
  {
    my %running_dbs = %{ $running_dbs_homes{$db_home_name} };
    my $db_events = collectionutil_get_events( "problems", "DB", \%running_dbs );
    my @running_db_events;
    foreach my $db ( keys %running_dbs )
    {
      my @events_arr;
      foreach my $home ( keys %{$db_events} )
      {
        foreach my $adr_home ( keys %{ $db_events->{$home} } )
        {
          if ( $adr_home =~ /\W$db\W/ )
          {
            push( @events_arr, { 'ADR_DETAILS' => $db_events->{$home}->{$adr_home} } );
          }
        }
      }
      push( @running_db_events, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => \@events_arr } );
    }
    push( @running_db_events_final,
          { 'ORACLE_HOME_NAME' => $db_home_name, 'ORACLE_HOME_DETAILS' => \@running_db_events } );
  }
  tfactlstore_store_hash_into_json( \@running_db_events_final, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_rman_stats
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %running_dbs_homes =
    %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
  my @running_db_rman_stats_final = ();
  foreach my $db_home_name ( keys %running_dbs_homes )
  {
    my %running_dbs = %{ $running_dbs_homes{$db_home_name} };
    my @running_db_rman_stats = ();
    foreach my $db ( keys %running_dbs )
    {
      my $db_rman_stats = collectionutil_get_rman_stats( $db, $running_dbs{$db} );
      push( @running_db_rman_stats, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => $db_rman_stats } );
    }
    push( @running_db_rman_stats_final,
          { 'ORACLE_HOME_NAME' => $db_home_name, 'ORACLE_HOME_DETAILS' => \@running_db_rman_stats } );
  }
  tfactlstore_store_hash_into_json( \@running_db_rman_stats_final, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_pdb_stats
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %running_dbs_homes =
    %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
  my @running_db_pdb_stats_final = ();
  foreach my $db_home_name ( keys %running_dbs_homes )
  {
    my %running_dbs = %{ $running_dbs_homes{$db_home_name} };
    my @running_db_pdb_stats = ();
    foreach my $db ( keys %running_dbs )
    {
      my $banner = collectionutil_get_db_banner( $db, $running_dbs{$db} );
      my %retHash;
      if ( $banner =~ /Oracle Database (.*) .*Release/ )
      {
        my $version = $1;
        $version =~ s/\D//;
        if($version >= 12) 
        {
          %retHash = collectionutil_get_pdbs_stats( $db, $running_dbs{$db}, 1 );
        }
        if(keys %retHash != 0){ 
          push( @running_db_pdb_stats, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => \%retHash } );
        } else {
          push( @running_db_pdb_stats, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => "Not A Container Database" } );
        }
      } else {
        push( @running_db_pdb_stats, { 'DATABASE_NAME' => $db, 'DATABASE_DETAILS' => "Database is Not Running" } );
      }
    }
    push( @running_db_pdb_stats_final,
          { 'ORACLE_HOME_NAME' => $db_home_name, 'ORACLE_HOME_DETAILS' => \@running_db_pdb_stats } );
  }
  tfactlstore_store_hash_into_json( \@running_db_pdb_stats_final, $repository_loc, $hash_repository_loc );
}
##############################################
# OS STATUS
##############################################
sub sumcollection_os_clusterwide_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $dep_hash_ref = get_dependent_data( $tfa_home, "osoverview", "os_clusterwide_status", $repository_base );
  my @os_clusterwide_status = @{$dep_hash_ref};
  my @os_clusterwide_summary;
  my @os_status;
  my $MEM_USAGE_STATUS = "OK";

  foreach my $status (@os_clusterwide_status)
  {
    my $MEM_USED = $status->{"MEM_USED"};
    $MEM_USED =~ s/\s*%//g;
    $MEM_USAGE_STATUS = "WARNING" if ( $MEM_USED > 95 );
  }
  push( @os_status, "MEM_USAGE_STATUS : " . $MEM_USAGE_STATUS );
  my $OVERALL_STATUS;
  if ( $MEM_USAGE_STATUS eq "OK" )
  {
    $OVERALL_STATUS = "OK";
  } else
  {
    $OVERALL_STATUS = "WARNING";
  }
  push( @os_clusterwide_summary, { "OVERALL_STATUS" => $OVERALL_STATUS, "SUMMARY" => \@os_status } );
  tfactlstore_store_hash_into_json( \@os_clusterwide_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_os_clusterwide_status
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my @nodelist = @{$SUMMARY_NODE_LIST_REF};
  my @os_clusterwide_status;
  foreach my $node (@nodelist)
  {
    my $repository_base_nodewise = catfile( $SUMMARY_REPOSITORY, $node );
    my $os_status_summary;
    if ( $node ne $hostname )
    {
      my ( $status, $data ) = get_dependent_remote_data( $node, "os", "os_status_summary" );
      $os_status_summary = $data;
      next if ( $status eq "false" );
    } else
    {
      $os_status_summary = get_dependent_data( $tfa_home, "os", "os_status_summary", $repository_base_nodewise );
    }

    my $os_and_system  = $os_status_summary->[0]->{DETAILS};

    if ($PLATFORM eq 'aix') {
      my $os_top_details = $os_status_summary->[1]->{DETAILS};
      push(
            @os_clusterwide_status,
            {
              "HOSTNAME"      => $node,
              "#PROCESSORS"   => $os_top_details->{'#PROCESSORS'},
              "CPU_USED"      => $os_top_details->{'%CPU USED'},
              "MEM_USED"      => $os_top_details->{'%MEMORY USED'}
            }
      );
    } else {
      my $os_top_details = $os_status_summary->[2]->{DETAILS};
      push(
            @os_clusterwide_status,
            {
              "HOSTNAME"    => $node,
              "#CORES"      => $os_and_system->{"#CORES"},
              "#PROCESSORS" => $os_and_system->{"#PROCESSORS"},
              "IDLE_TIME"   => $os_top_details->{IDLE_TIME},
              "SWAP_USED"   => $os_top_details->{SWAP_USED},
              "LOAD"        => $os_top_details->{LOAD},
              "TASKS"       => $os_top_details->{TASKS},
              "MEM_USED"    => $os_top_details->{MEM_USED}
            }
      );
    }
  }
  tfactlstore_store_hash_into_json( \@os_clusterwide_status, $repository_loc, $hash_repository_loc );
}

sub sumcollection_os_status_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my @os_status_summary;
  if ($IS_WINDOWS)
  {
    my $dep_hash_ref = get_dependent_data( $tfa_home, "os", "os_details", $repository_base );
    my %os_and_system;
    $os_and_system{BIOS_VERSION} = $dep_hash_ref->[1]->{DETAILS}->{BIOS_VERSION};
    $os_and_system{OS_VERSION}   = $dep_hash_ref->[1]->{DETAILS}->{OS_VERSION};
    $dep_hash_ref = get_dependent_data( $tfa_home, "os", "system_configuration", $repository_base );
    $os_and_system{PROCESSOR} = $dep_hash_ref->{Model_name};
    $os_and_system{'#PROCESSORS'} = $dep_hash_ref->{'#Processors'};
    push( @os_status_summary, { "STATUS TYPE" => "OS and SYSTEM", "DETAILS" => \%os_and_system } );
    my @os_top_3_processes = ();
    $dep_hash_ref = get_dependent_data( $tfa_home, "os", "os_cpu_details", $repository_base );
    my %os_top_details = %{$dep_hash_ref};
    my @arr            = @{ $os_top_details{TOP_DETAILS} };

    for ( my $i = 0 ; $i < 3 ; $i++ )
    {
      push @os_top_3_processes, $arr[$i];
    }
    push( @os_status_summary, { "STATUS TYPE" => "TOP 3 PROCESSES", "DETAILS" => \@os_top_3_processes } );
  } elsif ($PLATFORM eq "aix") { 
    ## OS DETAILS
    my $dep_hash_ref = get_dependent_data( $tfa_home, "os", "os_details", $repository_base );
    my %os_and_system;
    my %cpu_details;
    $os_and_system{OS} = $dep_hash_ref->[1]->{DETAILS}->{OS};
    $os_and_system{Service_Package} = $dep_hash_ref->[1]->{DETAILS}->{SERVICE_PACKAGE};
    $cpu_details{Architecture} = $dep_hash_ref->[1]->{DETAILS}->{PROCESSOR_ARCHITECTURE};
    $dep_hash_ref = get_dependent_data( $tfa_home, "os", "system_configuration", $repository_base );
    $os_and_system{Partition_Name} = $dep_hash_ref->[1]->{'DETAILS'}->{Partition_Name};
    $os_and_system{Partition_Number} = $dep_hash_ref->[1]->{'DETAILS'}->{Partition_Number};
    $os_and_system{Memory}  = $dep_hash_ref->[3]->{'DETAILS'}->{Online_Memory};

    push( @os_status_summary, { "STATUS TYPE" => "OS and SYSTEM", "DETAILS" => \%os_and_system } );

    ## CPU/MEMORY DETAILS
    $dep_hash_ref = get_dependent_data( $tfa_home, "os", "system_configuration", $repository_base );
    $cpu_details{'PROCESSOR TYPE'} = $dep_hash_ref->[2]->{'DETAILS'}->{Processor_type};
    $cpu_details{'#PROCESSORS'} = $dep_hash_ref->[2]->{'DETAILS'}->{'#Processors'};
    $cpu_details{'CLOCK SPEED'} = $dep_hash_ref->[2]->{'DETAILS'}->{Clock_Speed};

    $dep_hash_ref = get_dependent_data( $tfa_home, "os", "os_cpu_details", $repository_base );
    $cpu_details{'TOTAL MEMORY'} = $dep_hash_ref->[0]->{'DETAILS'}->{'TOTAL MEMORY'};
    $cpu_details{'%MEMORY USED'} = $dep_hash_ref->[0]->{'DETAILS'}->{'PERCENT USED'};
    $cpu_details{'%CPU USED'} = $dep_hash_ref->[1]->{'DETAILS'}->{'%CPU USED'};

    push( @os_status_summary, { "STATUS TYPE" => "CPU AND MEMORY DETAILS", "DETAILS" => \%cpu_details } );
  } else {
    my $dep_hash_ref = get_dependent_data( $tfa_home, "os", "os_details", $repository_base );
    my %os_and_system;
    $os_and_system{KERNEL_RELEASE} = $dep_hash_ref->[1]->{DETAILS}->{KERNEL_RELEASE};
    $dep_hash_ref = get_dependent_data( $tfa_home, "os", "system_configuration", $repository_base );
    $os_and_system{"#CORES"} = $dep_hash_ref->{Cores};
    $os_and_system{CACHE} = $dep_hash_ref->{Cache};
    $os_and_system{"#PROCESSORS"}  = $dep_hash_ref->{"#Processors"};
    push( @os_status_summary, { "STATUS TYPE" => "OS and SYSTEM", "DETAILS" => \%os_and_system } );
    $dep_hash_ref = get_dependent_data( $tfa_home, "os", "os_sleeping_tasks", $repository_base );
    my @os_sleeping_tasks = @{$dep_hash_ref}[ 0 .. 4 ];
    push( @os_status_summary, { "STATUS TYPE" => "SLEEPING TASK", "DETAILS" => \@os_sleeping_tasks } );
    my @os_top_details;
    my %os_top_details;
    $dep_hash_ref = get_dependent_data( $tfa_home, "os", "os_cpu_details", $repository_base );
    my @os_top_details = @{$dep_hash_ref};

    foreach my $header (@os_top_details)
    {
      if ( $header->{TYPE} eq "TASKS" )
      {
        $os_top_details{TASKS} = "$header->{DETAILS}->{Total}";
      }
      if ( $header->{TYPE} eq "AVERAGE_LOAD" )
      {
        $os_top_details{LOAD} = "$header->{DETAILS}->{LAST_15_MINUTE}";
      }
      if ( $header->{TYPE} eq "MEMORY" )
      {
        $os_top_details{MEM_USED} = "$header->{DETAILS}->{Percent_Used}";
      }
      if ( $header->{TYPE} eq "SWAP" )
      {
        $os_top_details{SWAP_USED} = "$header->{DETAILS}->{Percent_Used}";
      }
      if ( $header->{TYPE} eq "CPU" )
      {
        $os_top_details{IDLE_TIME} = "$header->{DETAILS}->[3]->{'VALUE'}";
      }
    }
    push( @os_status_summary, { "STATUS TYPE" => "CPU DETAILS", "DETAILS" => \%os_top_details } );
  }
  tfactlstore_store_hash_into_json( \@os_status_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_os_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my @os_basic_info;
  my %retHash = collectionutil_get_os_details();
  push( @os_basic_info, { "TYPE" => "HOSTNAME", "DETAILS" => $hostname } );
  push( @os_basic_info, { "TYPE" => "OS",       "DETAILS" => \%retHash } );

  if ( $PLATFORM eq "linux" )
  {
    push( @os_basic_info, { "TYPE" => "ORACLE_RELEASE", "DETAILS" => collectionutil_get_oracle_release() } );
    push( @os_basic_info, { "TYPE" => "REDHAT_RELEASE", "DETAILS" => collectionutil_get_redhat_release() } );
  }
  tfactlstore_store_hash_into_json( \@os_basic_info, $repository_loc, $hash_repository_loc );
}

sub sumcollection_system_configuration
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my %os_system_info = collectionutil_get_cpu_details();
 
  if ($PLATFORM eq "aix") {
    my @os_sys_info;
    push( @os_sys_info, { "TYPE" => "HOSTNAME", "DETAILS" => $hostname } );
    push( @os_sys_info, { "TYPE" => "SYSTEM DETAILS", "DETAILS" => $os_system_info{'SYSTEM DETAILS'} } );
    push( @os_sys_info, { "TYPE" => "CPU DETAILS", "DETAILS" => $os_system_info{'CPU DETAILS'} } );
    push( @os_sys_info, { "TYPE" => "MEMORY DETAILS", "DETAILS" => $os_system_info{'MEMORY DETAILS'} } );

    tfactlstore_store_hash_into_json( \@os_sys_info, $repository_loc, $hash_repository_loc );
  } else {
    $os_system_info{'Hostname'} = $hostname;
    tfactlstore_store_hash_into_json( \%os_system_info, $repository_loc, $hash_repository_loc );
  }
}

sub sumcollection_os_sleeping_tasks
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $hostname          = tolower_host();
  my @os_sleeping_tasks = ();
  my @retArr            = collectionutil_get_sleeping_tasks();
  if ($#retArr)
  {

    foreach my $x (@retArr)
    {
      my %tmp;
      $tmp{'PID'}  = ${$x}[0];
      $tmp{'USER'} = ${$x}[1];
      $tmp{'TASK'} = ${$x}[2];
      push @os_sleeping_tasks, \%tmp;
    }
  }
  tfactlstore_store_hash_into_json( \@os_sleeping_tasks, $repository_loc, $hash_repository_loc );
}

sub sumcollection_os_cpu_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $hostname = tolower_host();
  my %os_top_details;
  my %retHash = collectionutil_get_top();

  if ($IS_WINDOWS)
  {
    tfactlstore_store_hash_into_json( \%retHash, $repository_loc, $hash_repository_loc );
  } elsif ($PLATFORM eq "aix") {
    my @os_top_details;
    push( @os_top_details, { "TYPE" => "MEMORY DETAILS", "DETAILS" => $retHash{'MEMORY'} } );
    push( @os_top_details, { "TYPE" => "CPU DETAILS", "DETAILS" => $retHash{'CPU'} } );

    tfactlstore_store_hash_into_json( \@os_top_details, $repository_loc, $hash_repository_loc );
  } else
  {
    my @os_top_details;
    foreach my $key ( keys %retHash )
    {
      if ( $key eq "Average Load" )
      {
        my %tmp;
        $tmp{'LAST_1_MINUTE'}  = ${ $retHash{$key} }[0];
        $tmp{'LAST_5_MINUTE'}  = ${ $retHash{$key} }[1];
        $tmp{'LAST_15_MINUTE'} = ${ $retHash{$key} }[2];

        push( @os_top_details, { "TYPE" => 'AVERAGE_LOAD', "DETAILS" => \%tmp } );
      } elsif ( $key eq "CPU" )
      {
        my @cpu;
        push( @cpu, { 'TYPE' => 'USER_CPU_TIME',      'VALUE' => ( split /%/, ${ $retHash{$key} }[0] )[0] } );
        push( @cpu, { 'TYPE' => 'SYSTEM_CPU_TIME',    'VALUE' => ( split /%/, ${ $retHash{$key} }[1] )[0] } );
        push( @cpu, { 'TYPE' => 'USER_NICE_CPU_TIME', 'VALUE' => ( split /%/, ${ $retHash{$key} }[2] )[0] } );
        push( @cpu, { 'TYPE' => 'IDLE_CPU_TIME',      'VALUE' => ( split /%/, ${ $retHash{$key} }[3] )[0] } );
        push( @cpu, { 'TYPE' => 'IO_WAIT_CPU_TIME',   'VALUE' => ( split /%/, ${ $retHash{$key} }[4] )[0] } );
        push( @cpu, { 'TYPE' => 'HARDWARE_IRQ',       'VALUE' => ( split /%/, ${ $retHash{$key} }[5] )[0] } );
        push( @cpu, { 'TYPE' => 'SOFTWARE_IRQ',       'VALUE' => ( split /%/, ${ $retHash{$key} }[6] )[0] } );
        push( @cpu, { 'TYPE' => 'STEAL_TIME',         'VALUE' => ( split /%/, ${ $retHash{$key} }[7] )[0] } );
        my %tmp;
        $tmp{'USER_CPU_TIME'}      = ( split /%/, ${ $retHash{$key} }[0] )[0];
        $tmp{'SYSTEM_CPU_TIME'}    = ( split /%/, ${ $retHash{$key} }[1] )[0];
        $tmp{'USER_NICE_CPU_TIME'} = ( split /%/, ${ $retHash{$key} }[2] )[0];
        $tmp{'IDLE_CPU_TIME'}      = ( split /%/, ${ $retHash{$key} }[3] )[0];
        $tmp{'IO_WAIT_CPU_TIME'}   = ( split /%/, ${ $retHash{$key} }[4] )[0];
        $tmp{'HARDWARE_IRQ'}       = ( split /%/, ${ $retHash{$key} }[5] )[0];
        $tmp{'SOFTWARE_IRQ'}       = ( split /%/, ${ $retHash{$key} }[6] )[0];
        $tmp{'STEAL_TIME'}         = ( split /%/, ${ $retHash{$key} }[7] )[0];
        push( @os_top_details, { "TYPE" => 'CPU', "DETAILS" => \@cpu } );
      } else
      {
        my %tmp;
        foreach my $x ( @{ $retHash{$key} } )
        {
          my $key   = ( split /:/, $x )[0];
          my $value = ( split /:/, $x )[1];
          $tmp{$key} = $value;
        }

        push( @os_top_details, { "TYPE" => uc($key), "DETAILS" => \%tmp } );
      }
    }
    tfactlstore_store_hash_into_json( \@os_top_details, $repository_loc, $hash_repository_loc );
  }
}

sub sumcollection_os_disk_location
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  tfactlstore_summary_log( "command execution started", "sumcollection_os_disk_location" );
  if ($IS_WINDOWS)
  {
    my %disk = collectionutil_get_fdisk_details();
    tfactlstore_store_hash_into_json( $disk{'DISKS'}, $repository_loc, $hash_repository_loc );
  }
  elsif ($IS_SOLARIS || $IS_AIX) 
  {
    my %retHash;
    $retHash{'SUPPORT'} = "NOT SUPPORTED";
    tfactlstore_store_hash_into_json( \%retHash, $repository_loc, $hash_repository_loc );
  } else
  {
    my ( $ref1, $ref2 ) = collectionutil_get_fdisk_details();
    my @disk_location;
    foreach my $key ( sort keys %{$ref1} )
    {
      my $value_ref = $ref1->{$key};
      $value_ref->{'PATH'} = $key;
      push( @disk_location, $value_ref );
    }
    tfactlstore_store_hash_into_json( \@disk_location, $repository_loc, $hash_repository_loc );
  }
  tfactlstore_summary_log( "command execution finished", "sumcollection_os_disk_location" );
}

sub sumcollection_os_disk_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  if ($IS_WINDOWS)
  {
    my %disk = collectionutil_get_fdisk_details();
    my %tmp;
    $tmp{'PARTITIONS'} = $disk{'PARTITIONS'};
    $tmp{'VOLUMES'}    = $disk{'VOLUMES'};
    $tmp{'VDISKS'}     = $disk{'VDISKS'};
    tfactlstore_store_hash_into_json( \%tmp, $repository_loc, $hash_repository_loc );
  } elsif ($IS_SOLARIS)
  {
    my %disk = collectionutil_get_fdisk_details();
    my @arr = ();
    foreach my $key (keys %disk) {
      my %tmp;
      $tmp{'FILESYSTEM'} = $key;
      $tmp{'DETAILS'} = $disk{$key};
      push @arr, \%tmp;
    }
    
    tfactlstore_store_hash_into_json( \@arr, $repository_loc, $hash_repository_loc );

  } elsif ($PLATFORM eq "aix") 
  {
    my %disk = collectionutil_get_fdisk_details();
    my @arr = ();
    foreach my $key (keys %disk) {
      my %tmp;
      $tmp{'DISK_NAME'} = $key;
      $tmp{'DETAILS'} = $disk{$key};
      push @arr, \%tmp;
    }
    tfactlstore_store_hash_into_json( \@arr, $repository_loc, $hash_repository_loc );
  } else
  {
    my ( $ref1, $ref2 ) = collectionutil_get_fdisk_details();
    my @disk_details;
    foreach my $key ( sort keys %{$ref2} )
    {
      my $value_ref = $ref2->{$key};
      $value_ref->{'PATH'} = $key;
      push( @disk_details, $value_ref );
    }
    tfactlstore_store_hash_into_json( \@disk_details, $repository_loc, $hash_repository_loc );
  }
}
##############################################
# LISTENER STATUS
##############################################
sub sumcollection_listener_clusterwide_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $dep_hash_ref =
    get_dependent_data( $tfa_home, "listeneroverview", "listener_clusterwide_status", $repository_base );
  my @listener_clusterwide_status = @{$dep_hash_ref};
  my @listener_clusterwide_summary;
  my @listener_status;
  my $LISTNER_STATUS = "OK";

  foreach my $status (@listener_clusterwide_status)
  {
    $LISTNER_STATUS = "PROBLEM" if ( $#{ $status->{LISTENER_DETAILS} } == -1 );
  }
  push( @listener_status, "LISTNER_STATUS   : " . $LISTNER_STATUS );
  my $OVERALL_STATUS;
  if ( $LISTNER_STATUS eq "OK" )
  {
    $OVERALL_STATUS = "OK";
  } else
  {
    $OVERALL_STATUS = "PROBLEM";
  }
  push( @listener_clusterwide_summary, { "OVERALL_STATUS" => $OVERALL_STATUS, "SUMMARY" => \@listener_status } );
  tfactlstore_store_hash_into_json( \@listener_clusterwide_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_listener_clusterwide_status
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my @listener_clusterwide_status;
  my @nodelist = @{$SUMMARY_NODE_LIST_REF};
  foreach my $node (@nodelist)
  {
    my $repository_base_nodewise = catfile( $SUMMARY_REPOSITORY, $node );
    my $listener_status_summary;
    if ( $node ne $hostname )
    {
      my ( $status, $data ) = get_dependent_remote_data( $node, "listener", "listener_status_summary" );
      $listener_status_summary = $data;
      next if ( $status eq "false" );
    } else
    {
      $listener_status_summary =
        get_dependent_data( $tfa_home, "listener", "listener_status_summary", $repository_base_nodewise );
    }
    my @listner_details;
    foreach my $status ( @{$listener_status_summary} )
    {
      my $ALIAS;
      my $ORACLE_HOME;
      my $UPTIME;
      my $PORT;
      foreach my $listner ( @{ $status->{LISTENER_DETAILS} } )
      {
        $ALIAS       = $listner->{DETAILS}              if ( $listner->{STATUS_TYPE} eq "ALIAS" );
        $ORACLE_HOME = $listner->{DETAILS}              if ( $listner->{STATUS_TYPE} eq "ORACLE_HOME" );
        $UPTIME      = $listner->{DETAILS}              if ( $listner->{STATUS_TYPE} eq "UPTIME" );
        $PORT        = $listner->{DETAILS}->[0]->{PORT} if ( $listner->{STATUS_TYPE} eq "ENDPOINTS" );
      }
      push(
            @listner_details,
            {
              "SL_NO"       => $status->{SL_NO},
              "ALIAS"       => $ALIAS,
              "ORACLE_HOME" => $ORACLE_HOME,
              "UPTIME"      => $UPTIME,
              "PORT"        => $PORT
            }
      );
    }
    push( @listener_clusterwide_status, { "HOSTNAME" => $node, "LISTENER_DETAILS" => \@listner_details } );
  }
  tfactlstore_store_hash_into_json( \@listener_clusterwide_status, $repository_loc, $hash_repository_loc );
}

sub sumcollection_listener_status_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $is_crs_up = collectionutil_check_crs_state();
  my $listener_scan_details = get_dependent_data( $tfa_home, "listener", "listener_scan_details", $repository_base )
    if ( $is_crs_up == 1 );
  my $listener_lsnrctl_status =
    get_dependent_data( $tfa_home, "listener", "listener_lsnrctl_status", $repository_base );
  my @listener_status_summary;
  my $count = 1;

  foreach my $status ( @{$listener_lsnrctl_status} )
  {
    my @status;
    my $scan;
    foreach my $detailed_status ( @{ $status->{LISTENER_DETAILS} } )
    {
      next if ( $detailed_status->{'STATUS_TYPE'} =~ /(PARAMETER_FILE|LOGFILE|START_DATE|SERVICE_DETAILS)/ );
      push( @status, $detailed_status );
      if ( $scan ne "done" and $is_crs_up == 1 )
      {
        my @scan_status;
        foreach my $status ( @{$listener_scan_details} )
        {
          push( @scan_status, { 'NAME' => $status->{'NAME'}, 'STATUS' => $status->{'STATUS'} } );
        }
        push( @status, { 'STATUS_TYPE' => 'SCAN_STATUS', 'DETAILS' => \@scan_status } );
        $scan = "done";
      }
    }
    push( @listener_status_summary, { 'SL_NO' => $count++, "LISTENER_DETAILS" => \@status } );
  }
  tfactlstore_store_hash_into_json( \@listener_status_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_listener_scan_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );

  if ($IS_CRS_INSTALLED == 0) {
    my @listener_scan = ();
    push( @listener_scan,
            { "STATUS" => "NO CRS INSTALLATION FOUND" } );
    tfactlstore_store_hash_into_json( \@listener_scan, $repository_loc, $hash_repository_loc );
  } else {
    my $is_crs_up = collectionutil_check_crs_state();
    if ( $is_crs_up != 1 ) {
      my @listener_scan = ();
      push( @listener_scan, { "STATUS" => "CRS NOT RUNNING" } );
      tfactlstore_store_hash_into_json( \@listener_scan, $repository_loc, $hash_repository_loc );
    } else {
      my $status;
      $status = collectionutil_check_tns_status();
      tfactlstore_store_hash_into_json( $status, $repository_loc, $hash_repository_loc );
    }
  }
}

sub sumcollection_listener_lsnrctl_status
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );

  my @listener_status = ();
  if ($IS_DB_INSTALLED == 0) {
    push( @listener_status,
            { "STATUS" => "NO DB INSTALLATION FOUND" } );
  } else {
    my %running_dbs =
      %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
    @listener_status = @{ collectionutil_get_listener_details( \%running_dbs ) };
  }
  tfactlstore_store_hash_into_json( \@listener_status, $repository_loc, $hash_repository_loc );
}
##############################################
# NETWORK STATUS
##############################################
sub sumcollection_network_clusterwide_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $dep_hash_ref = get_dependent_data( $tfa_home, "networkoverview", "network_clusterwide_status", $repository_base );
  my @network_clusterwide_status = @{$dep_hash_ref};
  my @network_clusterwide_summary;
  my @network_status;
  my $CLUSTER_NETWORK_STATUS = "OK";

  foreach my $status (@network_clusterwide_status)
  {
    if ( $status->{"STATUS_TYPE"} eq "CLUSTER_NETWORK_STATUS" )
    {
      push( @network_status, "CLUSTER_NETWORK_STATUS : " . $status->{"CLUSTER_NETWORK_STATUS"} );
    } else
    {
      $CLUSTER_NETWORK_STATUS = "PROBLEM";
      push( @network_status, "$status->{STATUS_TYPE} : " . "FAIL" );
    }
  }
  my $OVERALL_STATUS;
  if ( $CLUSTER_NETWORK_STATUS eq "OK" )
  {
    $OVERALL_STATUS = "OK";
  } else
  {
    $OVERALL_STATUS = "PROBLEM";
  }
  push( @network_clusterwide_summary, { "OVERALL_STATUS" => $OVERALL_STATUS, "SUMMARY" => \@network_status } );
  tfactlstore_store_hash_into_json( \@network_clusterwide_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_network_clusterwide_status
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my @network_clusterwide_status;
  my $network_status_summary = get_dependent_data( $tfa_home, "network", "network_status_summary", $repository_base );
  my $network_status = "GOOD";

  foreach my $status_details ( @{$network_status_summary} )
  {
    my $details = $status_details->{DETAILS};
    my $status  = $status_details->{STATUS_TYPE};
    if ( ref($details) eq 'ARRAY' )
    {
      if ( grep /FAIL/, @{$details} )
      {
        push( @network_clusterwide_status, { "STATUS_TYPE" => $status, "DETAILS" => $details } )
          if ( grep /FAIL/, @{$details} );
      }
    } else
    {
      if ( grep /FAIL/, $details )
      {
        push( @network_clusterwide_status, { "STATUS_TYPE" => $status, "DETAILS" => $details } )
          if ( grep /FAIL/, $details );
      }
    }
  }
  if ( $#network_clusterwide_status == -1 )
  {
    push( @network_clusterwide_status, { "STATUS_TYPE" => "CLUSTER_NETWORK_STATUS", "DETAILS" => $network_status } );
  }
  tfactlstore_store_hash_into_json( \@network_clusterwide_status, $repository_loc, $hash_repository_loc );
}

sub sumcollection_network_status_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my @network_status_summary;
  my $network_cluvfy_details = get_dependent_data( $tfa_home, "network", "network_cluvfy_details", $repository_base );
  foreach my $cluvfy_details ( @{$network_cluvfy_details} )
  {
    next if ( $cluvfy_details->{STATUS_TYPE} eq "SCAN_TCP_CONNECTIVITY" );
    push( @network_status_summary,
          { "STATUS_TYPE" => $cluvfy_details->{STATUS_TYPE}, "DETAILS" => $cluvfy_details->{DETAILS} } );
  }
  tfactlstore_store_hash_into_json( \@network_status_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_network_interface_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $hostname = tolower_host();
  my @network_basic_info;
  my %retHash = collectionutil_get_interface_details();

  if ( keys %retHash )
  {
    my @array = ();
    foreach my $x ( split /\n/, $retHash{'INTERFACE_DETAILS'} )
    {
      my %tmp;
      $tmp{'INTERFACE_NAME'} = ( split /:/, $x )[0];
      $tmp{'IP'}             = ( split /:/, $x )[1];
      $tmp{'INTERFACE_TYPE'} = ( split /:/, $x )[2];
      $tmp{'DESCRIPTION'}    = ( split /:/, $x )[3];
      push @array, \%tmp;
    }
    push( @network_basic_info, { "TYPE" => "CLUSTER_INTERFACE", "DETAILS" => \@array } );
    my @array1 = ();
    foreach my $x ( split /\n/, $retHash{'INTERFACE_LIST'} )
    {
      my %tmp1;
      $tmp1{'INTERFACE_NAME'} = ( split /:/, $x )[0];
      $tmp1{'IP'}             = ( split /:/, $x )[1];
      push @array1, \%tmp1;
    }
    push( @network_basic_info, { "TYPE" => "INTERFACE_LIST", "DETAILS" => \@array1 } );
  }
  tfactlstore_store_hash_into_json( \@network_basic_info, $repository_loc, $hash_repository_loc );
}

sub sumcollection_network_cluvfy_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $hostname = tolower_host();
  my @network_cluvfy_details;
  my $cluvfy = collectionutil_get_cluvfy_details();

  foreach my $key ( sort keys %{$cluvfy} )
  {
    push( @network_cluvfy_details, { "STATUS_TYPE" => $key, "DETAILS" => $cluvfy->{$key} } );
  }
  tfactlstore_store_hash_into_json( \@network_cluvfy_details, $repository_loc, $hash_repository_loc );
}

sub sumcollection_network_ocrcheck_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $hostname = tolower_host();
  my @network_ocrcheck_details;
  my $ocrcheck = collectionutil_get_ocrcheck_details();
  my %olr_details;

  foreach my $key ( sort keys %{$ocrcheck} )
  {
    if ( $key !~ m/^(DEVICE_FILE_NAME|DEVICE_FILE_INTEGRITY_CHECK|LOGICAL_CORRUPTION_CHECK)$/ )
    {
      $olr_details{$key} = $ocrcheck->{$key};
      next;
    }
    push( @network_ocrcheck_details, { "STATUS_TYPE" => $key, "DETAILS" => $ocrcheck->{$key} } );
  }
  push( @network_ocrcheck_details, { "STATUS_TYPE" => "OLR_DETAILS", "DETAILS" => \%olr_details } );
  tfactlstore_store_hash_into_json( \@network_ocrcheck_details, $repository_loc, $hash_repository_loc );
}
##############################################
# ACFS STATUS
##############################################
sub sumcollection_acfs_clusterwide_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $dep_hash_ref = get_dependent_data( $tfa_home, "acfsoverview", "acfs_clusterwide_status", $repository_base );
  my @acfs_clusterwide_status = @{$dep_hash_ref};
  my @acfs_clusterwide_summary;
  my @acfs_status;
  my $ACFS_STATUS = "ONLINE";
  my $SIZE_STATUS = "OK";

  foreach my $status (@acfs_clusterwide_status)
  {
    $ACFS_STATUS = "OFFLINE" if ( $status->{'STATE'} ne "AVAILABLE" );
    my $SIZE        = $status->{"SIZE_STATUS"};
    my $ACTUAL_SIZE = $status->{"SIZE_STATUS"};
    $SIZE =~ s/% Available//g;
    $SIZE_STATUS = "WARNING : $ACTUAL_SIZE" if ( $SIZE < 20 );
  }
  push( @acfs_status, "ACFS_STATUS : " . $ACFS_STATUS );
  push( @acfs_status, "SIZE_STATUS : " . $SIZE_STATUS ) if ( $ACFS_STATUS eq "ONLINE" );
  my $OVERALL_STATUS;
  if ( $ACFS_STATUS eq "ONLINE" )
  {
    $OVERALL_STATUS = "OK";
  } else
  {
    $OVERALL_STATUS = "OFFLINE";
  }
  push( @acfs_clusterwide_summary, { "OVERALL_STATUS" => $OVERALL_STATUS, "SUMMARY" => \@acfs_status } );
  tfactlstore_store_hash_into_json( \@acfs_clusterwide_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_acfs_clusterwide_status
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my @nodelist = @{$SUMMARY_NODE_LIST_REF};
  my @acfs_clusterwide_status;
  foreach my $node (@nodelist)
  {
    my $repository_base_nodewise = catfile( $SUMMARY_REPOSITORY, $node );
    my $acfs_status_summary;
    if ( $node ne $hostname )
    {
      my ( $status, $data ) = get_dependent_remote_data( $node, "acfs", "acfs_status_summary" );
      $acfs_status_summary = $data;
      next if ( $status eq "false" );
    } else
    {
      $acfs_status_summary = get_dependent_data( $tfa_home, "acfs", "acfs_status_summary", $repository_base_nodewise );
    }
    my %acfs_status;
    my @list = ( "TOTAL_SIZE", "SIZE_STATUS", "HOSTNAME", "STATE", "NUM_VOL", "FS_NAME", "VERSION" );
    foreach my $name (@list)
    {
      $acfs_status{$name} = "";
    }
    foreach my $status ( @{$acfs_status_summary} )
    {
      next if ( $status->{STATUS_TYPE} =~ /(MOUNT_TIME|CORRUPT|ENCRIPTION|REPLICATION|SNAPSHOTS|BLK_SIZE|TOTAL_FREE)/ );
      $acfs_status{ $status->{STATUS_TYPE} } = $status->{DETAILS};
    }
    $acfs_status{HOSTNAME} = $node;
    push( @acfs_clusterwide_status, \%acfs_status );
  }
  tfactlstore_store_hash_into_json( \@acfs_clusterwide_status, $repository_loc, $hash_repository_loc );
}

sub sumcollection_acfs_status_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  return unless sumcollection_acfs_check( $repository_loc, $hash_repository_loc );
  my $acfs_status_summary = get_dependent_data( $tfa_home, "acfs", "acfs_filesystem_details", $repository_base );
  tfactlstore_store_hash_into_json( $acfs_status_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_acfs_filesystem_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  return unless sumcollection_acfs_check( $repository_loc, $hash_repository_loc );
  my @acfs_filesystem_details;
  if ( collectionutil_is_acfs_configured() )
  {
    @acfs_filesystem_details = @{ collectionutil_get_acfs_filesystem_sql() };
  }
  tfactlstore_store_hash_into_json( \@acfs_filesystem_details, $repository_loc, $hash_repository_loc );
}

sub sumcollection_acfs_volume_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  return unless sumcollection_acfs_check( $repository_loc, $hash_repository_loc );
  my $acfs_volume_details;
  if ( collectionutil_is_acfs_configured() )
  {
    $acfs_volume_details = collectionutil_get_asm_volume_sql();
    $acfs_volume_details = $acfs_volume_details->[0]->{DETAILS};
  }
  tfactlstore_store_hash_into_json( $acfs_volume_details, $repository_loc, $hash_repository_loc );
}

sub sumcollection_acfs_volume_statistics
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  return unless sumcollection_acfs_check( $repository_loc, $hash_repository_loc );
  my @acfs_volume_statistics;
  if ( collectionutil_is_acfs_configured() )
  {
    my $acfs_volume_details = collectionutil_get_asm_volume_sql();
    push( @acfs_volume_statistics, $acfs_volume_details->[1] );
    push( @acfs_volume_statistics, $acfs_volume_details->[2] );
  }
  tfactlstore_store_hash_into_json( \@acfs_volume_statistics, $repository_loc, $hash_repository_loc );
}
##############################################
# TFA STATUS
##############################################
sub sumcollection_tfa_clusterwide_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $dep_hash_ref = get_dependent_data( $tfa_home, "tfaoverview", "tfa_clusterwide_status", $repository_base );
  my @tfa_clusterwide_status = @{$dep_hash_ref};
  my @tfa_clusterwide_summary;
  my @tfa_status;
  my $TFA_STATUS = "RUNNING";

  foreach my $status (@tfa_clusterwide_status)
  {
    my $TFA_STATUS = "NOT RUNNING" if ( $status->{"STATUS"} ne "RUNNING" );
  }
  push( @tfa_status, "TFA_STATUS : " . $TFA_STATUS );
  my $OVERALL_STATUS;
  if ( $TFA_STATUS eq "RUNNING" )
  {
    $OVERALL_STATUS = "OK";
  } else
  {
    $OVERALL_STATUS = "OFFLINE";
  }
  push( @tfa_clusterwide_summary, { "OVERALL_STATUS" => $OVERALL_STATUS, "SUMMARY" => \@tfa_status } );
  tfactlstore_store_hash_into_json( \@tfa_clusterwide_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_tfa_clusterwide_status
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $tfa_status_summary = get_dependent_data( $tfa_home, "tfa", "tfa_status_summary", $repository_base );
  tfactlstore_store_hash_into_json( $tfa_status_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_tfa_status_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $tfa_basic_info = collectionutil_get_tfa_status();
  tfactlstore_store_hash_into_json( $tfa_basic_info, $repository_loc, $hash_repository_loc );
}

sub sumcollection_tfa_directories
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $tfa_directories = collectionutil_get_tfa_directories();
  tfactlstore_store_hash_into_json( $tfa_directories, $repository_loc, $hash_repository_loc );
}

sub sumcollection_tfa_directories_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my @tfa_dir_summary = ();
  my $tfa_directories = get_dependent_data( $tfa_home, "tfa", "tfa_directories", $repository_base );
  if ( !exists $tfa_directories->[0]->{ERROR} )
  {

    foreach my $dirhash ( @{$tfa_directories} )
    {
      push( @tfa_dir_summary, { 'COMPONENT' => "$dirhash->{'COMPONENT'}", 'DIRECTORY' => "$dirhash->{'DIRECTORY'}" } );
    }
    $tfa_directories = \@tfa_dir_summary;
  }
  tfactlstore_store_hash_into_json( $tfa_directories, $repository_loc, $hash_repository_loc );
}

sub sumcollection_tfa_repository
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $tfa_repository = collectionutil_get_tfa_repository();
  tfactlstore_store_hash_into_json( $tfa_repository, $repository_loc, $hash_repository_loc );
}

sub sumcollection_tfa_config
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $tfa_config = collectionutil_get_tfa_config();
  tfactlstore_store_hash_into_json( $tfa_config, $repository_loc, $hash_repository_loc );
}
##############################################
## PATCH Status Summary
##############################################
sub sumcollection_patch_clusterwide_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $dep_hash_ref = get_dependent_data( $tfa_home, "patchoverview", "patch_clusterwide_status", $repository_base );
  my @patch_clusterwide_status = @{$dep_hash_ref};
  my @patch_clusterwide_summary;
  my @patch_status;
  my $CRS_PATCH_CONSISTENCY_ACROSS_NODES      = "OK";
  my $DATABASE_PATCH_CONSISTENCY_ACROSS_NODES = "OK";

  foreach my $status (@patch_clusterwide_status)
  {
    $CRS_PATCH_CONSISTENCY_ACROSS_NODES = "PROBLEM"
      if ( $status->{"COMPONENT"} eq "CRS" and 
        ( ($status->{"PATCH_CONSISTENCY_ACROSS_NODES"} && $status->{"PATCH_CONSISTENCY_ACROSS_NODES"} ne "PASSED") || 
          ($status->{"PATCH_STATUS"} && $status->{"PATCH_STATUS"} ne "PASSED") ) );

    $DATABASE_PATCH_CONSISTENCY_ACROSS_NODES = "PROBLEM"
      if ( $status->{"COMPONENT"} eq "DATABASE" and 
        ( ($status->{"PATCH_CONSISTENCY_ACROSS_NODES"} && $status->{"PATCH_CONSISTENCY_ACROSS_NODES"} ne "PASSED") || 
          ($status->{"PATCH_STATUS"} && $status->{"PATCH_STATUS"} ne "PASSED") ) );
  }
  push( @patch_status, "CRS_PATCH_CONSISTENCY_ACROSS_NODES      : " . $CRS_PATCH_CONSISTENCY_ACROSS_NODES );
  push( @patch_status, "DATABASE_PATCH_CONSISTENCY_ACROSS_NODES : " . $DATABASE_PATCH_CONSISTENCY_ACROSS_NODES );
  my $OVERALL_STATUS;
  if ( $DATABASE_PATCH_CONSISTENCY_ACROSS_NODES eq "OK" and $CRS_PATCH_CONSISTENCY_ACROSS_NODES eq "OK" )
  {
    $OVERALL_STATUS = "OK";
  } else
  {
    $OVERALL_STATUS = "PROBLEM";
  }
  push( @patch_clusterwide_summary, { "OVERALL_STATUS" => $OVERALL_STATUS, "SUMMARY" => \@patch_status } );
  tfactlstore_store_hash_into_json( \@patch_clusterwide_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_patch_clusterwide_status
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $patch_clusterwide_status_details =
    get_dependent_data( $tfa_home, "patchoverview", "patch_clusterwide_status_details", $repository_base );
  my @patch_clusterwide_status;
  foreach my $patch_details ( @{$patch_clusterwide_status_details} )
  {

    if ( $patch_details->{COMPONENT} eq "CRS" )
    {
      if (ref($patch_details->{PATCH_STATUS}) eq "ARRAY") {
        push(
              @patch_clusterwide_status,
              {
                "COMPONENT"                      => $patch_details->{COMPONENT},
                "HOME_NAME"                      => "N/A",
                "COMMON_PATCH_COUNT"             => $patch_details->{PATCH_STATUS}->[0]->{DETAILS},
                "PATCH_CONSISTENCY_ACROSS_NODES" => $patch_details->{PATCH_STATUS}->[1]->{DETAILS},
                "COMMON_PATCH_LIST_ACROSS_NODES" => $patch_details->{PATCH_STATUS}->[2]->{DETAILS}
              }
        );
      } else {
        push(
              @patch_clusterwide_status,
              {
                "COMPONENT"                      => $patch_details->{COMPONENT},
                "PATCH_STATUS"                   => $patch_details->{PATCH_STATUS}
              }
        );
      }
    } else
    {
      if (ref($patch_details->{PATCH_STATUS}) eq "ARRAY") {
        foreach my $db_patch_details ( @{ $patch_details->{PATCH_STATUS} } )
        {
          push(
                @patch_clusterwide_status,
                {
                  "COMPONENT"                      => $patch_details->{COMPONENT},
                  "HOME_NAME"                      => $db_patch_details->{OH_NAME},
                  "COMMON_PATCH_COUNT"             => $db_patch_details->{PATCH_DETAILS}->[0]->{DETAILS},
                  "PATCH_CONSISTENCY_ACROSS_NODES" => $db_patch_details->{PATCH_DETAILS}->[1]->{DETAILS},
                  "COMMON_PATCH_LIST_ACROSS_NODES" => $db_patch_details->{PATCH_DETAILS}->[2]->{DETAILS}
                }
          );
        } 
      } else {
         push(
              @patch_clusterwide_status,
              {
                "COMPONENT"                        => $patch_details->{COMPONENT},
                "PATCH_STATUS"                     => $patch_details->{PATCH_STATUS}
              }
        );
      }
    }
  }
  tfactlstore_store_hash_into_json( \@patch_clusterwide_status, $repository_loc, $hash_repository_loc );
}

sub sumcollection_patch_clusterwide_status_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );

  my @nodelist = @{$SUMMARY_NODE_LIST_REF};
  my %crs_patch_list;
  my %db_patch_list;
  foreach my $node (@nodelist)
  {
    my $repository_base_nodewise = catfile( $SUMMARY_REPOSITORY, $node );
    my $dep_hash_ref;
    if ( $node ne $hostname )
    {
      my ( $status, $data ) = get_dependent_remote_data( $node, "patch", "patch_status_summary" );
      $dep_hash_ref = $data;
      next if ( $status eq "false" );
    } else
    {
      $dep_hash_ref = get_dependent_data( $tfa_home, "patch", "patch_status_summary", $repository_base_nodewise );
    }

    my @crs_patch_list;
    if (ref($dep_hash_ref->[0]->{'PATCH_DETAILS'}->[3]->{'DETAILS'}) eq "ARRAY") {
      foreach my $arr_val ( @{ $dep_hash_ref->[0]->{'PATCH_DETAILS'}->[3]->{'DETAILS'} } )
      {
        push( @crs_patch_list, ( split( / /, $arr_val ) ) );
      }
      $crs_patch_list{$node} = \@crs_patch_list;
    } else {
      $crs_patch_list{$node} = $dep_hash_ref->[0]->{'PATCH_DETAILS'}->[3]->{'DETAILS'};
    }

    my @db_patch_list;
    my %homes;
    if (ref($dep_hash_ref->[1]->{'PATCH_DETAILS'}) eq "ARRAY") {
      foreach my $home_name ( @{ $dep_hash_ref->[1]->{'PATCH_DETAILS'} } )
      {
        foreach my $arr_val ( @{ $home_name->{'PATCH_DETAILS'}->[3]->{'DETAILS'} } )
        {
          push( @db_patch_list, ( split( / /, $arr_val ) ) );
        }
        $homes{ $home_name->{'OH_NAME'} } = \@db_patch_list;
      }
      $db_patch_list{$node} = \%homes;
    } else {
      $db_patch_list{$node} = $dep_hash_ref->[1]->{'PATCH_DETAILS'};
    }
  }
  my @final_patch_clusterwide_status;
  my @COMPONENTS = ( "CRS", "DATABASE" );
  my @component  = ( "crs", "database" );
  foreach my $COMPONENT (@COMPONENTS)
  {
    if ( $COMPONENT eq "CRS" )
    {
      my @union;
      my @intersection;
      my @difference;
      my %count = ();
      my @complete_array;
      foreach my $node (@nodelist)
      {
        push( @complete_array, @{ $crs_patch_list{$node} } )
          if ( $COMPONENT eq "CRS" and exists $crs_patch_list{$node} );
      }
      foreach my $element (@complete_array) { $count{$element}++ }
      foreach my $element ( keys %count )
      {
        push @union, $element;
        push @{ $count{$element} > $#nodelist ? \@intersection : \@difference }, $element;
      }
      my @patch_clusterwide_status;
      my $COMMON_PATCH_COUNT = 0;
      my @COMMON_PATCH_LIST;
      if ( $#intersection != -1 )
      {
        $COMMON_PATCH_COUNT = $#intersection + 1;
        @COMMON_PATCH_LIST  = @{ format_list_array( \@intersection ) };
      }
      push( @patch_clusterwide_status, { "STATUS" => "COMMON_PATCH_COUNT", "DETAILS" => $COMMON_PATCH_COUNT } );
      my $PATCH_CONSISTENCY_ACROSS_NODES = "PASSED";
      $PATCH_CONSISTENCY_ACROSS_NODES = "FAILED" if ( $#difference != -1 );
      push( @patch_clusterwide_status,
            { "STATUS" => "PATCH_CONSISTENCY_ACROSS_NODES", "DETAILS" => $PATCH_CONSISTENCY_ACROSS_NODES } );
      push( @patch_clusterwide_status,
            { "STATUS" => "COMMON_PATCH_LIST_ACROSS_NODES", "DETAILS" => \@COMMON_PATCH_LIST } );
      if ( $#difference != -1 )
      {
        my @INCONSISTENT_PATCH_LIST = @{ format_list_array( \@difference ) };
        push( @patch_clusterwide_status,
              { "STATUS" => "INCONSISTENT_PATCH_LIST", "DETAILS" => \@INCONSISTENT_PATCH_LIST } );
      }
      push( @final_patch_clusterwide_status,
            { "COMPONENT" => "$COMPONENT", "PATCH_STATUS" => \@patch_clusterwide_status } );
      tfactlstore_store_hash_into_json( \@final_patch_clusterwide_status, $repository_loc, $hash_repository_loc );
    } elsif ( $COMPONENT eq "DATABASE" )
    {
      my @home_patch_status;
      if (ref($db_patch_list{$hostname}) eq "HASH") {
        foreach my $homename ( keys %{ $db_patch_list{$hostname} } )
        {
          my @complete_array;
          foreach my $node (@nodelist)
          {
            push( @complete_array, @{ $db_patch_list{$node}->{$homename} } );
          }
          my @union;
          my @intersection;
          my @difference;
          my %count = ();
          foreach my $element (@complete_array) { $count{$element}++ }
          foreach my $element ( keys %count )
          {
            push @union, $element;
            push @{ $count{$element} > $#nodelist ? \@intersection : \@difference }, $element;
          }
          my @patch_clusterwide_status;
          my $COMMON_PATCH_COUNT = 0;
          my @COMMON_PATCH_LIST;
          if ( $#intersection != -1 )
          {
            $COMMON_PATCH_COUNT = $#intersection + 1;
            @COMMON_PATCH_LIST  = @{ format_list_array( \@intersection ) };
          }
          push( @patch_clusterwide_status, { "STATUS" => "COMMON_PATCH_COUNT", "DETAILS" => $COMMON_PATCH_COUNT } );
          my $PATCH_CONSISTENCY_ACROSS_NODES = "PASSED";
          $PATCH_CONSISTENCY_ACROSS_NODES = "FAILED" if ( $#difference != -1 );
          push( @patch_clusterwide_status,
                { "STATUS" => "PATCH_CONSISTENCY_ACROSS_NODES", "DETAILS" => $PATCH_CONSISTENCY_ACROSS_NODES } );
          push( @patch_clusterwide_status,
                { "STATUS" => "COMMON_PATCH_LIST_ACROSS_NODES", "DETAILS" => \@COMMON_PATCH_LIST } );
          if ( $#difference != -1 )
          {
            my @INCONSISTENT_PATCH_LIST = @{ format_list_array( \@difference ) };
            push( @patch_clusterwide_status,
                  { "STATUS" => "INCONSISTENT_PATCH_LIST", "DETAILS" => \@INCONSISTENT_PATCH_LIST } );
          }

          push( @home_patch_status, { 'OH_NAME' => "$homename", "PATCH_DETAILS" => \@patch_clusterwide_status } );
        }
        push( @final_patch_clusterwide_status, { "COMPONENT" => "$COMPONENT", "PATCH_STATUS" => \@home_patch_status } );
      } else {
        push( @final_patch_clusterwide_status, { "COMPONENT" => "$COMPONENT", "PATCH_STATUS" => $db_patch_list{$hostname} } );
      }
      tfactlstore_store_hash_into_json( \@final_patch_clusterwide_status, $repository_loc, $hash_repository_loc );
    }
  }
}

sub sumcollection_patch_status_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my @patch_status_summary;
  my @COMPONENTS = ( "CRS", "DATABASE" );
  my @component  = ( "crs", "database" );

  foreach my $COMPONENT (@COMPONENTS)
  {
    my $comp = lc($COMPONENT);
    if ( $COMPONENT eq 'DATABASE' )
    {
      if ($IS_DB_INSTALLED == 0) {
        push( @patch_status_summary, { "COMPONENT" => "${COMPONENT}", "PATCH_DETAILS" => "NO DB INSTALLATION FOUND" } );
      } else {
        my $db_patch_details = get_dependent_data( $tfa_home, "patch", "${comp}_patch_details", $repository_base );
        my @patch_array_final;
        foreach my $db_home_name ( @{$db_patch_details} )
        {
          my $patch_details = $db_home_name->{'PATCH_DETAILS'};
          my @patch;
          if ( $patch_details->[2]->{DETAILS} ne "NIL" )
          {
            foreach my $patch ( @{ $patch_details->[2]->{DETAILS} } )
            {
              push( @patch, $patch->{'BUG#'} );
            }
          } else
          {
            push @patch, "NIL";
          }
          my $patch_count = $#patch;
          my @patch_list  = @{ format_list_array( \@patch ) };
          my @patch_array;
          push( @patch_array,
                { "STATUS" => "$patch_details->[0]->{STATUS_TYPE}", "DETAILS" => $patch_details->[0]->{DETAILS} } );
          push( @patch_array,
                { "STATUS" => "$patch_details->[1]->{STATUS_TYPE}", "DETAILS" => $patch_details->[1]->{DETAILS} } );
          push( @patch_array,       { "STATUS"  => "${COMPONENT}_PATCH_COUNT", "DETAILS"       => $patch_count . " " } );
          push( @patch_array,       { "STATUS"  => "PATCH_LIST",               "DETAILS"       => \@patch_list } );
          push( @patch_array_final, { 'OH_NAME' => $db_home_name->{'OH_NAME'}, 'PATCH_DETAILS' => \@patch_array } );
        }
        push( @patch_status_summary, { "COMPONENT" => "${COMPONENT}", "PATCH_DETAILS" => \@patch_array_final } );
      }
    } else
    {
      if ($IS_CRS_INSTALLED == 0) {
        push( @patch_status_summary, { "COMPONENT" => "${COMPONENT}", "PATCH_DETAILS" => "NO CRS INSTALLATION FOUND" } );
      } else {
        my $patch_details = get_dependent_data( $tfa_home, "patch", "${comp}_patch_details", $repository_base );
        my @patch;
        if ( $patch_details->[2]->{DETAILS} ne "NIL" )
        {
          foreach my $patch ( @{ $patch_details->[2]->{DETAILS} } )
          {
            push( @patch, $patch->{'BUG#'} );
          }
        } else
        {
          push @patch, "NIL";
        }
        my $patch_count = $#patch;
        my @patch_list  = @{ format_list_array( \@patch ) };
        my @patch_array;
        push( @patch_array,
              { "STATUS" => "$patch_details->[0]->{STATUS_TYPE}", "DETAILS" => $patch_details->[0]->{DETAILS} } );
        push( @patch_array,
              { "STATUS" => "$patch_details->[1]->{STATUS_TYPE}", "DETAILS" => $patch_details->[1]->{DETAILS} } );
        push( @patch_array, { "STATUS" => "${COMPONENT}_PATCH_COUNT", "DETAILS" => $patch_count . " " } );
        push( @patch_array, { "STATUS" => "PATCH_LIST", "DETAILS" => \@patch_list } );
        push( @patch_status_summary, { "COMPONENT" => "${COMPONENT}", "PATCH_DETAILS" => \@patch_array } );
      }
    }
  }
  tfactlstore_store_hash_into_json( \@patch_status_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_crs_patch_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my @crs_patch_details;

  if ($IS_CRS_INSTALLED == 0) {
    push( @crs_patch_details,
            { "STATUS" => "NO CRS INSTALLATION FOUND" } );
  } else {
    my $crs_home          = collectionutil_get_crs_home();
    my $crs_user          = collectionutil_get_crs_user();
    my $crs_patch_details = collectionutil_opatch_details( $crs_home, $crs_user );
    push( @crs_patch_details, { "STATUS_TYPE" => 'CRS_HOME',  'DETAILS' => $crs_home } );
    push( @crs_patch_details, { "STATUS_TYPE" => 'CRS_USER',  'DETAILS' => $crs_user } );
    push( @crs_patch_details, { "STATUS_TYPE" => 'CRS_PATCH', 'DETAILS' => $crs_patch_details->{PATCHES} } );
  }
  tfactlstore_store_hash_into_json( \@crs_patch_details, $repository_loc, $hash_repository_loc );
}

sub sumcollection_database_patch_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );

  my @database_patch_details_final = ();

  if ($IS_DB_INSTALLED == 0) {
    push( @database_patch_details_final,
            { "STATUS" => "NO DB INSTALLATION FOUND" } );
  } else {
    my %running_dbs_homes = %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
    foreach my $db_home_name ( keys %running_dbs_homes )
    {
      my %running_dbs = %{ $running_dbs_homes{$db_home_name} };
      my @database_patch_details;
      foreach my $db ( keys %running_dbs )
      {
        my @db_details_arr   = split /\|/, $running_dbs{$db};
        my $db_home          = $db_details_arr[1];
        my $db_user          = $db_details_arr[2];
        my $db_patch_details = collectionutil_opatch_details( $db_home, $db_user );
        push( @database_patch_details, { "STATUS_TYPE" => 'DATABASE_HOME',  'DETAILS' => $db_home } );
        push( @database_patch_details, { "STATUS_TYPE" => 'DATABASE_USER',  'DETAILS' => $db_user } );
        push( @database_patch_details, { "STATUS_TYPE" => 'DATABASE_PATCH', 'DETAILS' => $db_patch_details->{PATCHES} } );
        last;
      }
      push( @database_patch_details_final,
            { "OH_NAME" => "$db_home_name", 'PATCH_DETAILS' => \@database_patch_details } );
    }
  }
  tfactlstore_store_hash_into_json( \@database_patch_details_final, $repository_loc, $hash_repository_loc );
}

sub sumcollection_crs_product_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );

  if ($IS_CRS_INSTALLED == 0) {
    my @crs_product_details = ();
    push( @crs_product_details,
            { "STATUS" => "NO CRS INSTALLATION FOUND" } );
    tfactlstore_store_hash_into_json( \@crs_product_details, $repository_loc, $hash_repository_loc );
  } else {
    my $crs_home          = collectionutil_get_crs_home();
    my $crs_user          = collectionutil_get_crs_user();
    my $crs_patch_details = collectionutil_opatch_product_details( $crs_home, $crs_user );
    tfactlstore_store_hash_into_json( $crs_patch_details, $repository_loc, $hash_repository_loc );
  }
}

sub sumcollection_database_product_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );

  my @database_product_details_final = ();

  if ($IS_DB_INSTALLED == 0) {
    push( @database_product_details_final,
            { "STATUS" => "NO DB INSTALLATION FOUND" } );
  } else {
    my %running_dbs_homes =
      %{ get_dependent_data( $tfa_home, "database", "database_get_running_db_details", $repository_base ) };
    foreach my $db_home_name ( keys %running_dbs_homes )
    {
      my %running_dbs = %{ $running_dbs_homes{$db_home_name} };

      my $db_patch_details;
      foreach my $db ( keys %running_dbs )
      {
        my @db_details_arr = split /\|/, $running_dbs{$db};
        my $db_home        = $db_details_arr[1];
        my $db_user        = $db_details_arr[2];
        $db_patch_details = collectionutil_opatch_product_details( $db_home, $db_user );
        last;
      }
      push( @database_product_details_final, { "OH_NAME" => "$db_home_name", 'PATCH_DETAILS' => $db_patch_details } );
    }
  }

  tfactlstore_store_hash_into_json( \@database_product_details_final, $repository_loc, $hash_repository_loc );
}
##############################################
## Dependency Check tools
##############################################
sub sumcollection_dependency_check
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  my $dependent_command   = shift;
  if ( $dependent_command ne "" )
  {
    my $command_method;
    my $method_ref;
    $command_method = "sumcollection_$dependent_command";
    $method_ref     = \&{$command_method};
    $method_ref->( $tfa_home, $repository_base, $repository_loc, $hash_repository_loc );
  }
}

sub get_dependent_remote_data
{
  my $host      = shift;
  my $component = shift;
  my $command   = shift;
  my $status    = "false";
  my $data;
  foreach my $comp_details ( @{ $SUMMARY_REMOTE_DATA_REF->{$host}->{"DETAILS"} } )
  {
    if ( $comp_details->{"COMPONENT"} eq "$component" )
    {
      foreach my $command_table ( @{ $comp_details->{"DETAILS"} } )
      {
        if ( $command_table->{"COMMAND"} eq "$command" )
        {
          $status = "true";
          $data   = $command_table->{"DETAILS"};
        }
      }
    }
  }
  return ( $status, $data );
}

sub get_dependent_data
{
  my $tfa_home                = shift;
  my $component               = shift;
  my $dependent_command       = shift;
  my $repository_base         = shift;
  my $dep_repository_loc      = catfile( $repository_base, "data", $component, "${dependent_command}.json" );
  my $dep_hash_repository_loc = catfile( $repository_base, "hashdata", $component, "${dependent_command}.hash" );
  if ( !-e $dep_repository_loc )
  {
    my $dep_repository_dir      = catfile( $repository_base, "data",     $component );
    my $dep_hash_repository_dir = catfile( $repository_base, "hashdata", $component );
    eval { tfactlshare_mkpath("$dep_repository_dir", "1740") if ( ! -d "$dep_repository_dir" );  };
    if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $dep_repository_dir","get_dependent_data",1 ); }
    eval { tfactlshare_mkpath("$dep_hash_repository_dir", "1740") if ( ! -d "$dep_hash_repository_dir" );  };
    if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $dep_hash_repository_dir","get_dependent_data",1 ); }
  }
  sumcollection_dependency_check( $tfa_home, $repository_base, $dep_repository_loc, $dep_hash_repository_loc,
                                  $dependent_command );
  my $dep_hashref = tfactlstore_retrieve_json_to_hash($dep_hash_repository_loc);
  return $dep_hashref->{'DETAILS'};
}

sub sumcollection_crs_check
{
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  my $is_crs_up           = collectionutil_check_crs_state();
  if ( $is_crs_up == 1 )
  {
    return 1;
  } else
  {
    my @crs_status;
    push( @crs_status, { "CRS_STATUS" => "OFFLINE" } );
    tfactlstore_store_hash_into_json( \@crs_status, $repository_loc, $hash_repository_loc );
    return 0;
  }
}

sub sumcollection_asm_check
{
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  my $is_asm_up           = collectionutil_get_asm_status();
  if ( $is_asm_up == 1 )
  {
    return 1;
  } else
  {
    my @asm_status;
    push( @asm_status, { "ASM_STATUS" => "OFFLINE" } );
    tfactlstore_store_hash_into_json( \@asm_status, $repository_loc, $hash_repository_loc );
    return 0;
  }
}

sub sumcollection_acfs_check
{
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  my $is_acfs_configured  = collectionutil_is_acfs_configured();
  if ( $is_acfs_configured == 1 )
  {
    return 1;
  } else
  {
    my @acfs_status;
    push( @acfs_status, { "STATUS_TYPE" => "STATE", "DETAILS" => "NOT CONFIGURED" } );
    tfactlstore_store_hash_into_json( \@acfs_status, $repository_loc, $hash_repository_loc );
    return 0;
  }
}
##############################################
## Summary Functions
##############################################
sub sumcollection_summary_clusterwide_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $dep_hash_ref = get_dependent_data( $tfa_home, "summary", "summary_exectime_summary", $repository_base );
  my @summary_clusterwide_status = @{$dep_hash_ref};
  my @summary_clusterwide_summary;
  my @summary_status;
  my $SUMMARY_EXECUTION_TIME;

  foreach my $status (@summary_clusterwide_status)
  {
    $SUMMARY_EXECUTION_TIME = $status->{"DETAILS"} if ( $status->{"STATUS_TYPE"} eq "SUMMARY_EXECUTION_TIME" );
  }
  push( @summary_status, "SUMMARY_EXECUTION_TIME : " . $SUMMARY_EXECUTION_TIME );
  my $OVERALL_STATUS;
  if ( defined $SUMMARY_EXECUTION_TIME )
  {
    $OVERALL_STATUS = "OK";
  } else
  {
    $OVERALL_STATUS = "PROBLEM";
  }
  push( @summary_clusterwide_summary, { "OVERALL_STATUS" => $OVERALL_STATUS, "SUMMARY" => \@summary_status } );
  tfactlstore_store_hash_into_json( \@summary_clusterwide_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_summary_clusterwide_status
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  my $profile_hash_ref    = shift;
  return if ( -e $repository_loc );
  my @summary_exectime_clusterwide;
  my @nodelist = @{$SUMMARY_NODE_LIST_REF};

  foreach my $node (@nodelist)
  {
    my $repository_base_nodewise = catfile( $SUMMARY_REPOSITORY, $node );
    my $dep_hash_ref;
    if ( $node ne $hostname )
    {
      my ( $status, $data ) = get_dependent_remote_data( $node, "summary", "summary_exectime_component" );
      $dep_hash_ref = $data;
      next if ( $status eq "false" );
    } else
    {
      $dep_hash_ref =
        get_dependent_data( $tfa_home, "summary", "summary_exectime_component", $repository_base_nodewise );
    }
    my %hash;
    $hash{'hostname'} = $node;
    foreach my $element (@$dep_hash_ref)
    {
      $hash{ $element->{'COMPONENT'} } = $element->{'EXEC_TIME'};
    }
    push( @summary_exectime_clusterwide, \%hash );
  }
  tfactlstore_store_hash_into_json( \@summary_exectime_clusterwide, $repository_loc, $hash_repository_loc );
}

sub sumcollection_summary_profile
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  my $profile_hash_ref    = shift;
  return if ( -e $repository_loc );
  my @summary_profile;
  foreach my $component ( grep { exists $profile_hash_ref->{$_} } @{$SUMMARY_COMPONENT_ORDER_REF} )
  {
    next if ( !exists $profile_hash_ref->{$component} );
    my $value = $profile_hash_ref->{$component};
    my %hash_for_sort;
    my @profile;
    foreach my $val ( sort keys %{$value} )
    {
      my %profile_hash;
      $profile_hash{'ALL_COMMANDS'} = $val;
      my $val_ref = $profile_hash_ref->{$component}->{$val};
      my $sequence;
      foreach my $status ( sort keys %{$val_ref} )
      {
        $profile_hash{ uc($status) } = $profile_hash_ref->{$component}->{$val}->{$status};
        $sequence = $profile_hash_ref->{$component}->{$val}->{$status} if ( $status eq 'sequence' );
      }
      $hash_for_sort{$sequence} = \%profile_hash;
    }
    foreach my $seq ( sort { $a <=> $b } keys %hash_for_sort )
    {
      push( @profile, $hash_for_sort{$seq} );
    }
    push( @summary_profile, { 'COMPONENT' => $component, 'DETAILS' => \@profile } );
  }
  tfactlstore_store_hash_into_json( \@summary_profile, $repository_loc, $hash_repository_loc );
}

sub sumcollection_summary_exectime_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  my $profile_hash_ref    = shift;
  return if ( -e $repository_loc );
  my @summary_exectime_summary;

  $SUMMARY_TIME_PROFILE_HREF->{'TOOL'}->{'SUMMARY'}->{'END'} = time;
  my $starttime     = $SUMMARY_TIME_PROFILE_HREF->{'TOOL'}->{'SUMMARY'}->{'START'};
  my $endtime       = $SUMMARY_TIME_PROFILE_HREF->{'TOOL'}->{'SUMMARY'}->{'END'};
  my $diffinseconds = $endtime - $starttime;
  my $hours         = int( $diffinseconds / 3600 );
  my $leftover      = $diffinseconds % 3600;
  my $minz          = int( $leftover / 60 );
  my $secz          = int( $leftover % 60 );
  my $exec_time     = "${hours}H:${minz}M:${secz}S";
  push( @summary_exectime_summary, { 'STATUS_TYPE' => 'SUMMARY_EXECUTION_TIME', 'DETAILS' => $exec_time } );

  tfactlstore_store_hash_into_json( \@summary_exectime_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_summary_exectime_component
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  my $profile_hash_ref    = shift;
  return if ( -e $repository_loc );
  my @summary_exectime_component;
  foreach my $component ( keys %{ $SUMMARY_TIME_PROFILE_HREF->{'COMPONENT'} } )
  {
    next if ( $component =~ /\w+overview/ );
    my $starttime = $SUMMARY_TIME_PROFILE_HREF->{'COMPONENT'}->{$component}->{'START'};
    $SUMMARY_TIME_PROFILE_HREF->{'COMPONENT'}->{$component}->{'END'} = time if ( $component eq "summary" );
    my $endtime       = $SUMMARY_TIME_PROFILE_HREF->{'COMPONENT'}->{$component}->{'END'};
    my $diffinseconds = $endtime - $starttime;
    my $hours         = int( $diffinseconds / 3600 );
    my $leftover      = $diffinseconds % 3600;
    my $minz          = int( $leftover / 60 );
    my $secz          = int( $leftover % 60 );
    my $exec_time     = "${hours}H:${minz}M:${secz}S";
    push( @summary_exectime_component, { 'COMPONENT' => $component, 'EXEC_TIME' => $exec_time } );
  }
  tfactlstore_store_hash_into_json( \@summary_exectime_component, $repository_loc, $hash_repository_loc );
}
##############################################
## Exadata Functions
##############################################
sub sumcollection_exadata_clusterwide_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my $dep_hash_ref = get_dependent_data( $tfa_home, "exadataoverview", "exadata_clusterwide_status", $repository_base );
  my @exadata_clusterwide_status = @{$dep_hash_ref};
  my @exadata_clusterwide_summary;
  my @exadata_status;
  my $ENV_TEST          = "PASS";
  my $LINKUP            = "PASS";
  my $ENV_TEST          = "PASS";
  my $LINKUP            = "PASS";
  my $SWITCH_SSH_STATUS = 'CONFIGURED';
  my $CELL_SSH_STATUS   = 'CONFIGURED';
  my $LUN_STATUS        = 'NORMAL';
  my $RS_STATUS         = 'RUNNING';
  my $CELLSRV_STATUS    = 'RUNNING';
  my $MS_STATUS         = 'RUNNING';

  foreach my $status (@exadata_clusterwide_status)
  {
    $ENV_TEST          = "FAIL"           if ( $status->{"ENV_TEST"} ne "PASS" );
    $LINKUP            = "FAIL"           if ( $status->{"LINKUP"} ne "PASS" );
    $SWITCH_SSH_STATUS = "NOT CONFIGURED" if ( $status->{"SWITCH_SSH"} ne "CONFIGURED" );
    $CELL_SSH_STATUS   = "NOT CONFIGURED" if ( $status->{"CELL_SSH"} ne "CONFIGURED" );
    $LUN_STATUS        = "FAIL"           if ( $status->{"LUN_STATUS"} ne "NORMAL" );
    $RS_STATUS         = "NOT RUNNING"    if ( $status->{"RS_STATUS"} ne "RUNNING" );
    $CELLSRV_STATUS    = "NOT RUNNING"    if ( $status->{"CELLSRV"} ne "RUNNING" );
    $MS_STATUS         = "NOT RUNNING"    if ( $status->{"MS_STATUS"} ne "RUNNING" );
  }
  push( @exadata_status, "SWITCH_SSH_STATUS : " . $SWITCH_SSH_STATUS );
  push( @exadata_status, "CELL_SSH_STATUS   : " . $CELL_SSH_STATUS );
  if ( $SWITCH_SSH_STATUS eq "CONFIGURED" )
  {
    push( @exadata_status, "ENVIRONMENT_TEST  : " . $ENV_TEST );
    push( @exadata_status, "LINKUP            : " . $LINKUP );
  }
  if ( $CELL_SSH_STATUS eq "CONFIGURED" )
  {
    push( @exadata_status, "LUN_STATUS        : " . $LUN_STATUS );
    push( @exadata_status, "RS_STATUS         : " . $RS_STATUS );
    push( @exadata_status, "CELLSRV_STATUS    : " . $CELLSRV_STATUS );
    push( @exadata_status, "MS_STATUS         : " . $MS_STATUS );
  }
  my $OVERALL_STATUS;
  if (     $ENV_TEST eq "PASS"
       and $LINKUP eq "PASS"
       and $SWITCH_SSH_STATUS eq 'CONFIGURED'
       and $CELL_SSH_STATUS eq 'CONFIGURED'
       and $LUN_STATUS eq 'NORMAL'
       and $RS_STATUS eq 'RUNNING'
       and $CELLSRV_STATUS eq 'RUNNING'
       and $MS_STATUS eq 'MS_STATUS' )
  {
    $OVERALL_STATUS = "OK";
  } else
  {
    $OVERALL_STATUS = "PROBLEM";
  }
  push( @exadata_clusterwide_summary, { "OVERALL_STATUS" => $OVERALL_STATUS, "SUMMARY" => \@exadata_status } );
  tfactlstore_store_hash_into_json( \@exadata_clusterwide_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_exadata_clusterwide_status
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my @nodelist = @{$SUMMARY_NODE_LIST_REF};
  my @exadata_clusterwide_status;
  foreach my $node (@nodelist)
  {
    my $repository_base_nodewise = catfile( $SUMMARY_REPOSITORY, $node );
    my $dep_hash_ref;
    if ( $node ne $hostname )
    {
      my ( $status, $data ) = get_dependent_remote_data( $node, "exadata", "exadata_status_summary" );
      $dep_hash_ref = $data;
      next if ( $status eq "false" );
    } else
    {
      $dep_hash_ref = get_dependent_data( $tfa_home, "exadata", "exadata_status_summary", $repository_base_nodewise );
    }
    my @exadata_status_summary = @{$dep_hash_ref};
    my $PRODUCT_NAME;
    my $MODEL;
    my $NUMBER_OF_CPU;
    my $ENV_TEST          = "PASS";
    my $LINKUP            = "PASS";
    my $SWITCH_SSH_STATUS = 'CONFIGURED';
    my $CELL_SSH_STATUS   = 'CONFIGURED';
    my $LUN_STATUS        = 'NORMAL';
    my $RS_STATUS         = 'RUNNING';
    my $CELLSRV_STATUS    = 'RUNNING';
    my $MS_STATUS         = 'RUNNING';
    my $ASM_STATUS        = 'ONLINE';

    foreach my $status (@exadata_status_summary)
    {
      $PRODUCT_NAME      = $status->{DETAILS} if ( $status->{STATUS_TYPE} eq "PRODUCT_NAME" );
      $MODEL             = $status->{DETAILS} if ( $status->{STATUS_TYPE} eq "MODEL" );
      $NUMBER_OF_CPU     = $status->{DETAILS} if ( $status->{STATUS_TYPE} eq "NUMBER_OF_CPU" );
      $SWITCH_SSH_STATUS = $status->{DETAILS} if ( $status->{STATUS_TYPE} eq "SWITCH_SSH_STATUS" );
      $CELL_SSH_STATUS   = $status->{DETAILS} if ( $status->{STATUS_TYPE} eq "CELL_SSH_STATUS" );
      $ENV_TEST          = $status->{DETAILS} if ( $status->{STATUS_TYPE} eq "ENV_TEST" );
      $LINKUP            = $status->{DETAILS} if ( $status->{STATUS_TYPE} eq "LINKUP" );
      $LUN_STATUS        = $status->{DETAILS} if ( $status->{STATUS_TYPE} eq "LUN_STATUS" );
      $RS_STATUS         = $status->{DETAILS} if ( $status->{STATUS_TYPE} eq "RS_STATUS" );
      $CELLSRV_STATUS    = $status->{DETAILS} if ( $status->{STATUS_TYPE} eq "CELLSRV_STATUS" );
      $MS_STATUS         = $status->{DETAILS} if ( $status->{STATUS_TYPE} eq "MS_STATUS" );
      $ASM_STATUS        = $status->{DETAILS} if ( $status->{STATUS_TYPE} eq "ASM_STATUS" );
    }
    my %status;
    $status{"HOSTNAME"} = $node;
    $PRODUCT_NAME =~ s/\s*$//g;
    $status{"PRODUCT_NAME"} = $PRODUCT_NAME;
    $status{"SWITCH_SSH"}   = $SWITCH_SSH_STATUS;
    if ( $SWITCH_SSH_STATUS eq 'CONFIGURED' )
    {
      $status{"ENV_TEST"} = $ENV_TEST;
      $status{"LINKUP"}   = $LINKUP;
    }
    $status{"CELL_SSH"} = $CELL_SSH_STATUS;
    if ( $CELL_SSH_STATUS eq 'CONFIGURED' )
    {
      $status{"LUN_STATUS"} = $LUN_STATUS;
      $status{"RS_STATUS"}  = $RS_STATUS;
      $status{"CELLSRV"}    = $CELLSRV_STATUS;
      $status{"MS_STATUS"}  = $MS_STATUS;
      $status{"ASM"}        = $ASM_STATUS;
    }
    push( @exadata_clusterwide_status, \%status );
  }
  tfactlstore_store_hash_into_json( \@exadata_clusterwide_status, $repository_loc, $hash_repository_loc );
}

sub sumcollection_exadata_status_summary
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  return if ( -e $repository_loc );
  my @exadata_status_summary;
  my $exadata_system_details = get_dependent_data( $tfa_home, "exadata", "exadata_system_details", $repository_base );
  foreach my $status ( @{$exadata_system_details} )
  {
    push( @exadata_status_summary, { "STATUS_TYPE" => 'PRODUCT_NAME', "DETAILS" => $status->{'DETAILS'} } )
      if ( $status->{'STATUS_TYPE'} eq "PRODUCT_NAME" );
    push( @exadata_status_summary, { "STATUS_TYPE" => 'MODEL', "DETAILS" => $status->{'DETAILS'} } )
      if ( $status->{'STATUS_TYPE'} eq "MODEL" );
    push( @exadata_status_summary, { "STATUS_TYPE" => 'BONDTYPE', "DETAILS" => $status->{'DETAILS'} } )
      if ( $status->{'STATUS_TYPE'} eq "BONDTYPE" );
    push( @exadata_status_summary, { "STATUS_TYPE" => 'NUMBER_OF_CPU', "DETAILS" => $status->{'DETAILS'} } )
      if ( $status->{'STATUS_TYPE'} eq "NUMBER_OF_CPU" );
  }
  my $exadata_infiband_switches_details =
    get_dependent_data( $tfa_home, "exadata", "exadata_infiband_switches_details", $repository_base );
  my $LINKUP            = "PASS";
  my $SWITCH_SSH_STATUS = 'CONFIGURED';
  my $ENV_TEST          = "PASS";
  my $SWITCHS;
  foreach my $status ( @{$exadata_infiband_switches_details} )
  {
    $SWITCH_SSH_STATUS = 'NOT CONFIGURED' if ( $status->{'SSH'} ne 'ENABLED' );
    $ENV_TEST          = "FAIL"           if ( $status->{'ENV_TEST'} ne "PASS" );
    $LINKUP            = "FAIL"           if ( $status->{'LINKUP'} ne "PASS" );
    if ( !defined $SWITCHS )
    {
      $SWITCHS = "$status->{'SWITCH'}";
    } else
    {
      $SWITCHS = "$SWITCHS,$status->{'SWITCH'}";
    }
  }
  push( @exadata_status_summary, { "STATUS_TYPE" => 'SWITCHS',           "DETAILS" => $SWITCHS } );
  push( @exadata_status_summary, { "STATUS_TYPE" => 'SWITCH_SSH_STATUS', "DETAILS" => $SWITCH_SSH_STATUS } );
  if ( $SWITCH_SSH_STATUS eq 'CONFIGURED' )
  {
    push( @exadata_status_summary, { "STATUS_TYPE" => 'ENV_TEST', "DETAILS" => $ENV_TEST } );
    push( @exadata_status_summary, { "STATUS_TYPE" => 'LINKUP',   "DETAILS" => $LINKUP } );
  }
  my $exadata_cell_details = get_dependent_data( $tfa_home, "exadata", "exadata_cell_details", $repository_base );
  my $CELL_SSH_STATUS = 'CONFIGURED';
  my $CELLS;
  my $lun_status    = 'NORMAL';
  my $rsStatus      = 'RUNNING';
  my $cellsrvStatus = 'RUNNING';
  my $msStatus      = 'RUNNING';
  my $ASM_STATUS    = 'ONLINE';

  foreach my $status ( @{$exadata_cell_details} )
  {
    $CELL_SSH_STATUS = 'NOT CONFIGURED' if ( $status->{'SSH'} ne 'ENABLED' );
    $lun_status      = 'FAIL'           if ( $status->{'FlashDisk-16'} ne 'normal' );
    $rsStatus        = 'NOT RUNNING'    if ( $status->{'rsStatus'} ne 'running' );
    $cellsrvStatus   = 'NOT RUNNING'    if ( $status->{'cellsrvStatus'} ne 'running' );
    $msStatus        = 'NOT RUNNING'    if ( $status->{'msStatus'} ne 'running' );
    $ASM_STATUS      = 'OFFLINE'        if ( $status->{'ASM_STATUS'} ne 'ONLINE' );
    if ( !defined $CELLS )
    {
      $CELLS = "$status->{'CELL'}";
    } else
    {
      $CELLS = "$CELLS,$status->{'CELL'}";
    }
  }
  push( @exadata_status_summary, { "STATUS_TYPE" => 'CELLS',           "DETAILS" => $CELLS } );
  push( @exadata_status_summary, { "STATUS_TYPE" => 'CELL_SSH_STATUS', "DETAILS" => $CELL_SSH_STATUS } );
  if ( $CELL_SSH_STATUS eq 'CONFIGURED' )
  {
    push( @exadata_status_summary, { "STATUS_TYPE" => 'LUN_STATUS',     "DETAILS" => $lun_status } );
    push( @exadata_status_summary, { "STATUS_TYPE" => 'RS_STATUS',      "DETAILS" => $rsStatus } );
    push( @exadata_status_summary, { "STATUS_TYPE" => 'CELLSRV_STATUS', "DETAILS" => $cellsrvStatus } );
    push( @exadata_status_summary, { "STATUS_TYPE" => 'MS_STATUS',      "DETAILS" => $msStatus } );
    push( @exadata_status_summary, { "STATUS_TYPE" => 'ASM_STATUS',     "DETAILS" => $ASM_STATUS } );
  }
  tfactlstore_store_hash_into_json( \@exadata_status_summary, $repository_loc, $hash_repository_loc );
}

sub sumcollection_exadata_system_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  my $profile_hash_ref    = shift;
  return if ( -e $repository_loc );
  my $hardware_details = collectionutil_get_hardware_model_exadata();
  my $exadata_io_status = get_dependent_data( $tfa_home, "exadata", "exadata_io_status", $repository_base );
  my @exadata_system_details;
  push( @exadata_system_details,
        { 'STATUS_TYPE' => 'PRODUCT_NAME', 'DETAILS' => $hardware_details->{'PRODUCT_NAME'} } );
  push( @exadata_system_details, { 'STATUS_TYPE' => 'MODEL',    'DETAILS' => $hardware_details->{'MODEL'} } );
  push( @exadata_system_details, { 'STATUS_TYPE' => 'BONDTYPE', 'DETAILS' => $hardware_details->{'BONDTYPE'} } );

  foreach my $status ( @{$exadata_io_status} )
  {
    push( @exadata_system_details, { "STATUS_TYPE" => 'KERNEL_VERSION', "DETAILS" => $status->{'DETAILS'} } )
      if ( $status->{'STATUS_TYPE'} eq "KERNEL_VERSION" );
    push( @exadata_system_details, { "STATUS_TYPE" => 'NUMBER_OF_CPU', "DETAILS" => $status->{'DETAILS'} } )
      if ( $status->{'STATUS_TYPE'} eq "NUMBER_OF_CPU" );
    push( @exadata_system_details, { "STATUS_TYPE" => 'AVERAGE_CPU_USAGE', "DETAILS" => $status->{'DETAILS'} } )
      if ( $status->{'STATUS_TYPE'} eq "AVERAGE_CPU_USAGE" );
  }
  tfactlstore_store_hash_into_json( \@exadata_system_details, $repository_loc, $hash_repository_loc );
}

sub change_ip_to_hostname {
  my $ip_address = shift;
  my $command;
  my $hostname = "";

  if (length($ip_address) != 0) {
    if ($ip_address =~ /\,/) {   ## list of ip addresses
      foreach my $ip (split /\,/, $ip_address) {
        $command = "$SSH root@" . $ip . " hostname";
        tfactlstore_summary_log( "COMMAND: $command", "change_ip_to_hostname" );
        my $host = `$command`;
        $host = (split /\./, $host)[0];

        $hostname .= $host . ",";
      }
      chop $hostname;
    } else {
      $command = "$SSH root@" . $ip_address . " hostname";
      tfactlstore_summary_log( "COMMAND: $command", "change_ip_to_hostname" );
      $hostname = `$command`;
    }
  }
  tfactlstore_summary_log( "IP: $ip_address", "change_ip_to_hostname" );
  tfactlstore_summary_log( "HOST: $hostname", "change_ip_to_hostname" );

  return $hostname;
}

sub sumcollection_exadata_cell_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  my $profile_hash_ref    = shift;
  return if ( -e $repository_loc );
  my @cell_details;
  my $cells            = collectionutil_get_cell_names();
  my $ssh_cells        = configure_ssh( $cells, 1 );
  $ssh_cells           = change_ip_to_hostname($ssh_cells);
  my $cell_status      = collectionutil_get_cell_status($ssh_cells);
  my $lun_status       = collectionutil_get_cell_lun_status($ssh_cells);
  my $grid_disk_status = collectionutil_get_cell_grid_disk_status($ssh_cells);

  foreach my $cell ( split( /,/, $ssh_cells ) )
  {
    my %cell_data;
    $cell_data{'CELL'} = $cell;
    if ( $ssh_cells =~ /$cell/ )
    {
      $cell_data{'SSH'} = "ENABLED";
    } else
    {
      $cell_data{'SSH'} = "DISABLED";
    }
    $cell_data{'rsStatus'}      = $cell_status->{$cell}->{rsStatus};
    $cell_data{'cellsrvStatus'} = $cell_status->{$cell}->{cellsrvStatus};
    $cell_data{'msStatus'}      = $cell_status->{$cell}->{msStatus};
    $cell_data{'msStatus'}      = $cell_status->{$cell}->{msStatus};
    $cell_data{'FlashDisk-16'}  = $lun_status->{$cell}->{'FlashDisk-16'};
    $cell_data{'HardDisk-12'}   = $lun_status->{$cell}->{'HardDisk-12'};
    $cell_data{'#GRIDDISKS'}    = $grid_disk_status->{$cell}->{'#GRIDDISKS'};
    $cell_data{'ASM_STATUS'}    = $grid_disk_status->{$cell}->{'ASM_NODE_STATUS'};
    $cell_data{'STATUS'}        = $grid_disk_status->{$cell}->{'STATUS'};
    push( @cell_details, \%cell_data );
  }
  tfactlstore_store_hash_into_json( \@cell_details, $repository_loc, $hash_repository_loc );
}

sub sumcollection_exadata_infiband_switches_details
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  my $profile_hash_ref    = shift;
  return if ( -e $repository_loc );
  my @switch_details;
  my $switches      = collectionutil_get_infiband_switches();
  my $ssh_switches  = configure_ssh( $switches, 1 );
  $ssh_switches     = change_ip_to_hostname($ssh_switches);
  my $linkup_status = collectionutil_get_ibsw_linker($ssh_switches);
  my %env_test      = collectionutil_get_ibsw_env_test($ssh_switches);
  my $ibsw_priority = collectionutil_get_ibsw_priority_master($ssh_switches);

  foreach my $switch ( split( /,/, $ssh_switches ) )
  {
    my %switch_data;
    $switch_data{'SWITCH'} = $switch;
    if ( $ssh_switches =~ /$switch/ )
    {
      $switch_data{'SSH'} = "ENABLED";
    } else
    {
      $switch_data{'SSH'} = "DISABLED";
    }
    $switch_data{'LINKUP'}              = $linkup_status;
    $switch_data{'ENV_TEST'}            = $env_test{$switch};
    $switch_data{'SM_STATE'}            = $ibsw_priority->{$switch}->{'SM_STATE'};
    $switch_data{'SM_PRIORITY'}         = $ibsw_priority->{$switch}->{'SM_PRIORITY'};
    $switch_data{'CONTROLLED_HANDOVER'} = $ibsw_priority->{$switch}->{'CONTROLLED_HANDOVER'};
    $switch_data{'M_KEY'}               = $ibsw_priority->{$switch}->{'M_KEY'};
    $switch_data{'ROUTING'}             = $ibsw_priority->{$switch}->{'ROUTING'};
    push( @switch_details, \%switch_data );
  }
  tfactlstore_store_hash_into_json( \@switch_details, $repository_loc, $hash_repository_loc );
}

sub sumcollection_exadata_io_statistics
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  my $profile_hash_ref    = shift;
  return if ( -e $repository_loc );
  my $exadata_io_status = get_dependent_data( $tfa_home, "exadata", "exadata_io_status", $repository_base );
  my $exadata_io_statistics;

  foreach my $status ( @{$exadata_io_status} )
  {
    $exadata_io_statistics = $status->{'DETAILS'} if ( $status->{'STATUS_TYPE'} eq "DEVICE_IO_STATS" );
  }
  tfactlstore_store_hash_into_json( $exadata_io_statistics, $repository_loc, $hash_repository_loc );
}

sub sumcollection_exadata_io_status
{
  my $tfa_home            = shift;
  my $repository_base     = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  my $profile_hash_ref    = shift;
  return if ( -e $repository_loc );
  my $io_status = collectionutil_get_iostat_details();
  tfactlstore_store_hash_into_json( $io_status, $repository_loc, $hash_repository_loc );
}
##############################################
## Miscellaneous Functions
##############################################
sub trimString
{
  my $str = shift;
  $str =~ s/^[\n|\s]+//g;
  $str =~ s/[\n|\s]+$//g;
  return $str;
}

sub format_list_array
{
  my $input_array_ref = shift;
  my @output_array;
  my $n = 5;
  my $i = 0;
  my $line;
  foreach my $item ( @{$input_array_ref} )
  {
    $line = $line . $item . " ";
    $i++;
    if ( $i % $n == 0 )
    {
      push( @output_array, $line );
      undef $line;
    }
  }
  push( @output_array, $line ) if ( $i % $n != 0 );
  return \@output_array;
}
1;
