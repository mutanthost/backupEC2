#
# $Header: tfa/src/v2/ext/summary/summary.pm /main/17 2018/08/09 22:22:30 recornej Exp $
#
# summary.pm
#
# Copyright (c) 2015, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      summary.pm - Oracle Trace File Analyzer Summary Tool
#
#    DESCRIPTION
#      This is used in collection Cluster Status Summary
#        Component Specific Summary collection :
#            - Collecting CRS details .
#            - Collecting ASM details .
#            - Collecting ACFS details .
#            - Collecting DATABASE details .
#            - Collecting EXADATA details .
#            - Collecting PATCH details .
#            - Collecting LISTENER details .
#            - Collecting OS details .
#            - Collecting NETWORK details .
#            - Collecting TFA details .
#            - Collecting SUMMARY details .
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    07/30/18 - Fix help exit codes
#    recornej    02/07/18 - Bug 27015350 - WS2012_18.1_TFA: NO HELP INFO FOR
#                           TFACTL SUMMARY ON PROMPT
#    manuegar    10/25/17 - manuegar_summary_basrep.
#    bibsahoo    10/05/17 - FIX BUG 26885708
#    bburton     08/17/17 - bug 26227144 summary -h running scripts
#    bibsahoo    08/31/17 - FIX BUG 26414175
#    bibsahoo    05/24/17 - FIX BUG 26127514
#    cpujar      05/19/17 - XbranchMerge cpujar_bug-26090405 from
#                           st_tfa_12.2.1.1.01
#    cpujar      05/17/17 - Summary bug 26090405 
#    cpujar      05/03/17 - XbranchMerge cpujar_bug-25971734 from main
#    cpujar      03/05/17 - Remove unused code
#    cpujar      13/04/17 - Summary Restructure
#    bibsahoo    13/04/17 - Summary Restructure
#    manuegar    11/02/16 - Bug 24948477 - WS2012_122_TFA: HELP INFORMATION FOR
#                           'TFACTL RUN GREP' INCORRECT.
#    arupadhy    07/07/16 - Help fix
#    arupadhy    06/24/16 - Making windows compatible
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    gadiga      03/24/15 - fix 20666289. dont show help from remote node
#    gadiga      02/23/15 - update help text
#    gadiga      01/28/15 - system summary
#    gadiga      01/28/15 - Creation
#
package summary;
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
use File::Copy;
use File::Spec::Functions;
use File::Path qw(mkpath rmtree);
use Getopt::Long qw(GetOptions);

# use XML::Parser;
use Data::Dumper;
use tfactlglobal;
use tfactlshare;
use tfactlstore;
use tfactladmin;
use tfactlsumreport;
use tfactlsumcollection;
use tfactlsummaryinterface;

# -----------------------
my $tool      = "summary";
my $tfa_base  = tfactlshare_get_repository_location($tfa_home);
my $tool_dir  = catfile( $tfa_base, "suptools", "$hostname", $tool );
my $tool_base = catfile( $tfa_base, "suptools", "$hostname", $tool, $current_user );
my $STDERR_ORG;

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

sub cleanup
{
  my $driverhost         = shift;
  my $time               = shift;
  my $repository_loc     = shift;
  my $summary_log_handle = shift;

  my $temp_profile = catfile( $tool_dir, "summaryfile-${time}_profile.xml" );
  unlink($temp_profile) if ( -e $temp_profile );
  close($summary_log_handle);

  # restore STDERR
  open (STDERR, '>&', $STDERR_ORG);
}

  # ##############################################################################
  # \%retitem            ==>
  #   $retitems{$component_name}{$command_name}{$attribute_name} = $attribute_value;
  # summary_profile.xml ==>
  #   <component name="crs">
  #      <command name="crs_status_summary" clusterwide="yes" html="yes" json="yes" console="yes" sequence="1"> </command>
  # $retitems{}          ==>
  #   $retitems{"crs"}{"crs_status_summary"}{"clusterwide"} = "yes";
  #   $retitems{"crs"}{"crs_status_summary"}{"html"}        = "yes";
  #   ...
  #   $retitems{"crs"}{"crs_status_summary"}{"level"}       = "1";   ==> Control shell mode interaction
  # ##############################################################################
sub summary_parse_summary_profile_xml_file
{
  my $tfa_menu_xml = shift;
  my %retitems     = ();
  my @menutagsarray;
  my @menuentries;
  if ( -e "$tfa_menu_xml" )
  {
    @menutagsarray = tfactlshare_populate_tagsarray($tfa_menu_xml);

    # Get top level tags <menus>
    my @menusList = tfactlshare_get_element( \@menutagsarray, 0, 0 );

    # For each menu .
    foreach my $menus (@menusList)
    {
      my @allmenus = tfactlshare_get_element( \@menutagsarray, @$menus[ELEMLEVEL] + 1, @$menus[ELEMNDX] );

      # For each menus get the menu .
      foreach my $menu (@allmenus)
      {
        my ( $name, $component_name ) = tfactlshare_get_attribute( @$menu[ELEMATTRNAME], @$menu[ELEMATTRVAL], "name" );

        # Now get each of the items
        my @menuItems = tfactlshare_get_element( \@menutagsarray, @$menu[ELEMLEVEL] + 1, @$menu[ELEMNDX] );
        foreach my $menuItems (@menuItems)
        {
          if ( @$menuItems[ELEMNAME] eq "command" )
          {
            # tfasimplerep, added level
            my @attributes = ( "clusterwide", "html", "json", "console", "sequence", "level");
            my ( $name, $command_name ) =
              tfactlshare_get_attribute( @$menuItems[ELEMATTRNAME], @$menuItems[ELEMATTRVAL], "name" );
            foreach my $attribute (@attributes)
            {
              my ( $attribute_name, $attribute_value ) =
                tfactlshare_get_attribute( @$menuItems[ELEMATTRNAME], @$menuItems[ELEMATTRVAL], "$attribute" );
              $retitems{$component_name}{$command_name}{$attribute_name} = $attribute_value;
            }
          }    # end if menu_option
        }    # end for each menuItems
      }    # end for each menu
    }    # end for each MenuList
  } else
  {      # end if xml file exists
    print "File : $tfa_menu_xml  Does not exist\n";
    exit;
  }
  return \%retitems;
}

# nodes.out has nodes
#
sub run
{
  my $tfa_home  = shift;
  my @temp_args = @_;
  my @args;
  my $TIME = 1;
  my $driverhost;
  while (@temp_args)
  {
    my $top = shift(@temp_args);
    chomp($top);
    if ( $top eq "-time" )
    {
      $TIME = shift(@temp_args);
      next;
    }
    if ( $top eq "-driverhost" )
    {
      $driverhost = shift(@temp_args);
      next;
    }
    push( @args, $top );
  }

  # moved arguments so help did not generate logs and excessive work.
  @ARGV = @args;

  my %components;
  $components{'overview'} = 0;
  $components{'crs'}      = 0;
  $components{'database'} = 0;
  $components{'exadata'}  = 0;
  $components{'asm'}      = 0;
  $components{'listener'} = 0;
  $components{'network'}  = 0;
  $components{'acfs'}     = 0;
  $components{'os'}       = 0;
  $components{'tfa'}      = 0;
  $components{'patch'}    = 0;
  $components{'summary'}  = 0;
  
  my $help = 0;
  GetOptions(
              "overview"     => \$components{'overview'},
              "crs"          => \$components{'crs'},
              "database"     => \$components{'database'},
              "exadata"      => \$components{'exadata'},
              "asm"          => \$components{'asm'},
              "listener"     => \$components{'listener'},
              "network"      => \$components{'network'},
              "acfs"         => \$components{'acfs'},
              "os"           => \$components{'os'},
              "tfa"          => \$components{'tfa'},
              "summary"      => \$components{'summary'},
              "patch"        => \$components{'patch'},
              "json"         => \my $JSON_REPORT,
              "html"         => \my $HTML_REPORT,
              "print"        => \my $PRINT,
              "silent"       => \my $SILENT,
              "consolidated" => \my $CONSOLIDATED,
              "history=s"       => \my $VIEW,
              "help"         => \$help
  ) or ( $help = 1 );
  if ( $help == 1 ) { help(); return 0; }

  my $REPOSITORY = catfile( $tool_base, "$TIME", $hostname );
  $SUMMARY_REPOSITORY      = catfile( $tool_base, "$TIME" );

  my $summary_logfile_dir = catfile( $SUMMARY_REPOSITORY, "log" );
  if (!-e $summary_logfile_dir) {
    eval { tfactlshare_mkpath("$summary_logfile_dir", "1740") if ( ! -d "$summary_logfile_dir" );  };
    if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $summary_logfile_dir", "summary_run", 1 ); }
   
    my $summary_logfile = catfile( $summary_logfile_dir,"summary_command_${TIME}_${hostname}_$$.log" );
    open( $SUMMARY_LOG_FH, '>>', $summary_logfile ) or die "Could not open $summary_logfile!\n";
    $SUMMARY_LOG_FILE = $summary_logfile;
    open ($STDERR_ORG, '>&', STDERR);
    open (STDERR, ">>$summary_logfile") or die "Cannot redirect STDERR to $summary_logfile file"; 
    print "LOGFILE LOCATION : $summary_logfile\n\n";
  }
  
  $CONSOLIDATED = 1 if ( !defined $CONSOLIDATED );
  $components{'overview'} = 1 unless ( grep( /1/, ( values %components ) ) );
  
  if (! defined $VIEW) {
    $IS_DB_INSTALLED = 0 if (!sumcollection_is_database_installed());
    $IS_CRS_INSTALLED = 0 if (!tfactlshare_is_crs_installed($tfa_home));
  }

  if ( $components{'exadata'} == 1 and ( $IS_WINDOWS or !isExadata() ) )
  {
    delete $components{'exadata'};
    print "WARNING: Not an Exadata Machine\n\n";
    unless ( grep( /1/, ( values %components ) ) )
    {
      return 1;
    }
  }

  if ( ($components{'crs'} == 1 || $components{'asm'} == 1) and ( $IS_CRS_INSTALLED == 0 ) )
  {
    delete $components{'crs'} if($components{'crs'} == 1);
    delete $components{'asm'} if($components{'asm'} == 1);
    print "WARNING: Not a GRID INFRASTRUSTURE\n\n";
    unless ( grep( /1/, ( values %components ) ) )
    {
      return 1;
    }
  }

  if ( $components{'database'} == 1 and ( $IS_DB_INSTALLED == 0 ) )
  {
    delete $components{'database'} if($components{'database'} == 1);
    print "WARNING: No DATABASE found\n\n";
    unless ( grep( /1/, ( values %components ) ) )
    {
      return 1;
    }
  }

  if ( $IS_DB_INSTALLED == 0 && $IS_CRS_INSTALLED == 0 ) 
  {
    if($components{'patch'} == 1) {
      print "WARNING: Skipping Patches Collection: No CRS/ASM/DATABASE found\n\n";
      delete $components{'patch'};
    }
    if($components{'listener'} == 1) {
      print "WARNING: Skipping Listener Collection: No CRS/ASM/DATABASE found\n\n";
      delete $components{'listener'};
    }
    if($components{'network'} == 1) {
      print "WARNING: Skipping Network Collection: No CRS/ASM/DATABASE found\n\n";     
      delete $components{'network'};
    }
    
    unless ( grep( /1/, ( values %components ) ) )
    {
      return 1;
    }
  }
  
  my %computed_components;
  $computed_components{'overview'} = 1;
  $computed_components{'crs'}      = 1;
  $computed_components{'database'} = 1;
  $computed_components{'exadata'}  = 1;
  $computed_components{'asm'}      = 1;
  $computed_components{'listener'} = 1;
  $computed_components{'network'}  = 1;
  $computed_components{'acfs'}     = 1;
  $computed_components{'os'}       = 1;
  $computed_components{'tfa'}      = 1;
  $computed_components{'patch'}    = 1;
  $computed_components{'summary'}  = 1;
    
  if ( $IS_WINDOWS or !isExadata() )
  {
    delete $computed_components{'exadata'};
  } 

  if ($IS_CRS_INSTALLED == 0) {
    delete $computed_components{'crs'};
    delete $computed_components{'asm'};
  } 

  if ($IS_DB_INSTALLED == 0) {
    delete $computed_components{'database'};
  } 

  if ($IS_DB_INSTALLED == 0 && $IS_CRS_INSTALLED == 0) {
    delete $computed_components{'listener'};
    delete $computed_components{'network'};
    delete $computed_components{'patch'};
  } 

  my @comp_order = ("overview", "crs",      "asm",     "acfs", "database", "exadata",
                    "patch",    "listener", "network", "os",   "tfa",      "summary");

  my @compute_array = ();
  foreach my $comp (@comp_order) {
    if ($computed_components{$comp} == 1) {
      push @compute_array, $comp;
      #print "$comp\n";
    }
  }

  # ----------------------------------------------------------------
  # tfasimplerep
  # \@SUMMARY_COMPONENT_ORDER_REF : Includes components from summary_profile.xml
  # which have been already computed
  # ----------------------------------------------------------------

  $SUMMARY_COMPONENT_ORDER_REF = \@compute_array;

  my $report_type   = "console";
  my $display_table = "no";
  $report_type = "json"      if ( defined $JSON_REPORT );
  $report_type = "html"      if ( defined $HTML_REPORT );
  $report_type = "json_html" if ( defined $HTML_REPORT and defined $JSON_REPORT );
  if ( !defined $PRINT )
  {
    $display_table = "yes";
  }
  my $profile_name = catfile( $tfa_home, "resources", "summary_profile.xml" );
  return 1 if ( $profile_name eq "2" );
  my $hashdatadir;
  my $datadir;
  my $reportdir;
  my $hashref;
  my $command_array_ref;
  # ##############################################################################
  # tfactl summary simple report (tfasimplerep)
  # %hashref            ==>
  #   $hashref{$component_name}{$command_name}{$attribute_name} = $attribute_value;
  # summary_profile.xml ==>
  #   <component name="crs">
  #      <command name="crs_status_summary" clusterwide="yes" html="yes" json="yes" console="yes" sequence="1"> </command>
  # $hashref{}          ==>
  #   $hashref{"crs"}{"crs_status_summary"}{"clusterwide"} = "yes";
  #   $hashref{"crs"}{"crs_status_summary"}{"html"}        = "yes";
  #   ...
  # ##############################################################################
  $hashref = summary_parse_summary_profile_xml_file($profile_name);
  my $complete_overview;

  if ( $components{'overview'} == 1 )
  {
    $complete_overview = "yes";
    %components = map { $_ => 1 } keys %components;    # if($components{'overview'}==1);
  } else
  {
    $complete_overview = "no";
    $components{'overview'} = 1;
  }

  # Assign Global Variables
  if(defined $VIEW){
    foreach my $component ( keys %components){
      my $component_path = catfile( $tool_base, "$TIME",$hostname,"data",$component );
      $components{$component} = 0 if(!-e $component_path);
    }
  }

  # Assign Global Variables
  $SUMMARY_REPORTTYPE      = $report_type;
  $SUMMARY_DISPLAY_TABLE   = $display_table;
  $SUMMARY_COMPONENTS_REF  = \%components;
  $SUMMARY_TIME            = $TIME;
  $SUMMARY_PROFILE_HASHREF = $hashref;
  $SUMMARY_OVERVIEW_TYPE   = $complete_overview;

  return if(defined $VIEW);

  
  eval { tfactlshare_mkpath("$REPOSITORY", "1740") if ( ! -d "$REPOSITORY" );  };
  if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $REPOSITORY", "summary_run", 1 ); }
  
  print "  Component Specific Summary collection :\n";
  my @comp_order = ();
  foreach my $comp (@{$SUMMARY_COMPONENT_ORDER_REF}) {
    next if ($comp eq "overview");
    push @comp_order, $comp;
  }
  my $local_compoment_order = \@comp_order;

  my $hashdatadirbase;
  my $datadirbase; 
  my $reportdirbase;
  foreach my $component ( grep { exists $components{$_} } @{$local_compoment_order} )
  {
    next if ( $components{$component} != 1 );

    $hashdatadirbase = catfile( "$REPOSITORY", "hashdata");
    $datadirbase     = catfile( "$REPOSITORY", "data");
    $reportdirbase   = catfile( "$REPOSITORY", "report");
    eval { tfactlshare_mkpath("$hashdatadirbase", "1740") if ( ! -d "$hashdatadirbase" );  };
    if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $hashdatadirbase","summary_run",1 ); }
    eval { tfactlshare_mkpath("$datadirbase", "1740") if ( ! -d "$datadirbase" );  };
    if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $datadirbase","summary_run",1 ); }
    eval { tfactlshare_mkpath("$reportdirbase", "1740") if ( ! -d "$reportdirbase" );  };
    if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $reportdirbase","summary_run",1 ); }

    $hashdatadir = catfile( "$REPOSITORY", "hashdata", $component );
    $datadir     = catfile( "$REPOSITORY", "data",     $component );
    $reportdir   = catfile( "$REPOSITORY", "report",   $component );
    
    eval { tfactlshare_mkpath("$hashdatadir", "1740") if ( ! -d "$hashdatadir" );  };
    if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $hashdatadir","summary_run",1 ); }
    eval { tfactlshare_mkpath("$datadir", "1740") if ( ! -d "$datadir" );  };
    if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $datadir","summary_run",1 ); }
    eval { tfactlshare_mkpath("$reportdir", "1740") if ( ! -d "$reportdir" );  };
    if ($@) { tfactlstore_summary_log( "(PID = $$) mkpath Can not create path $reportdir","summary_run",1 ); }

    # ---------------------------------------------------------------------------
    # Collecting component details
    # ---------------------------------------------------------------------------
    print "    - Collecting " . uc($component) . " details ... ";
    my @command_array;

    foreach my $command ( keys %{ $hashref->{$component} } )
    {
      if ( ( $hashref->{$component}->{$command}->{'clusterwide'} eq "yes" ) or ( $hostname eq $driverhost ) )
      {
        push( @command_array, $command );
      }
    }
    # tfasimplerep
    print "[summary,run,Collecting $component details] command_array @command_array.\n" if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} );

    $SUMMARY_TIME_PROFILE_HREF->{'COMPONENT'}->{"$component"}->{'START'} = time;
    my $str = join ',', @command_array;
    tfactlstore_summary_log( "Commands Selected: $str", "Summary" );
    summaryinterface_execute_profile_normal( $tfa_home, \@command_array, $component, $REPOSITORY, $hashref );
    summaryinterface_process_collection( $component, $REPOSITORY, $hashref, $report_type, $driverhost, \@command_array,
                                         $complete_overview );
    $SUMMARY_TIME_PROFILE_HREF->{'COMPONENT'}->{"$component"}->{'END'} = time;
    print "Done.\n";
    # ---------------------------------------------------------------------------
  } # end foreach grep { exists $components{$_} } @{$local_compoment_order}

  # print "\n";
  if ( $hostname ne $driverhost )
  {
    summaryinterface_consolidated_collection_reports( $tfa_home, $TIME, $REPOSITORY, $report_type, \%components ) if ( $hostname ne $driverhost );
    my $source = catfile( $REPOSITORY, "hashdata", "summary_report_${TIME}.hash" );
    my $destination = catfile( $SUMMARY_REPOSITORY, "summaryfile-${hostname}.hash" );
    copy($source,$destination);
    copyTagFile( $tfa_home, "summaryfile-FILE-${hostname}.hash-USER-${current_user}-TIME-${TIME}", $driverhost );
  }

  cleanup( $driverhost, $TIME, $REPOSITORY, $SUMMARY_LOG_FH );
  print "Summary - Done" if ( $hostname ne $driverhost );
  print "\n  Remote Summary Data Collection : In-Progress - Please wait ...\n"
    if ( $hostname eq $driverhost and $#{$SUMMARY_NODE_LIST_REF} > 0 );
  return 0;
}

sub help
{
  my $cmd;
  $cmd = $1 if ( $0 =~ /(.*)\.pl/ );
  print "---------------------------------------------------------------------------------
Usage : TFACTL [run] summary -help
---------------------------------------------------------------------------------
Command : $cmd [run] summary [OPTIONS]
Following Options are supported:
        [no_components] : [Default] Complete Summary Collection    
        -overview       : [Optional/Default] Complete Summary Collection - Overview
        -crs            : [Optional/Default] CRS Status Summary
        -asm            : [Optional/Default] ASM Status Summary
        -acfs           : [Optional/Default] ACFS Status Summary
        -database       : [Optional/Default] DATABASE Status Summary
        -exadata        : [Optional/Default] EXADATA Status Summary 
                          Not enabled/ignored in Windows and Non-Exadata machine
        -patch          : [Optional/Default] Patch Details
        -listener       : [Optional/Default] LISTENER Status Summary
        -network        : [Optional/Default] NETWORK Status Summary
        -os             : [Optional/Default] OS Status Summary
        -tfa            : [Optional/Default] TFA Status Summary
        -summary        : [Optional/Default] Summary Tool Metadata 

        -json           : [Optional] - Prepare json report
        -html           : [Optional] - Prepare html report 
        -print          : [Optional] - Display [html or json] Report at Console
        -silent         : [Optional] - Interactive console by defauly
        -history <num>  : [Optional] - View Previous <numberof> Summary Collection History in Interpreter 
        -node <node(s)> : [Optional] - local or Comma Separated Node Name(s)
        -help           : Usage/Help.
---------------------------------------------------------------------------------\n";
  return 1;
}
1;

