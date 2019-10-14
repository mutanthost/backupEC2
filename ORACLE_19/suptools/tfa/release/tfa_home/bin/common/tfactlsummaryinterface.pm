#
# $Header: tfa/src/v2/tfa_home/bin/common/tfactlsummaryinterface.pm /main/5 2018/05/28 15:06:27 bburton Exp $
#
# tfactlsummaryinterface.pm
#
# Copyright (c) 2017, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlsummaryinterface.pm - Interface between summary tool and tfa 
#
#    DESCRIPTION
#      Common modules used in summary.pm and tfactlshare.pm
#      It acts a interface between tool and tfa 
#      Provide command line interface to summary tool
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    manuegar    11/02/17 - manuegar_summary_basrep2.
#    manuegar    10/25/17 - manuegar_summary_basrep.
#    cpujar      05/19/17 - XbranchMerge cpujar_bug-26090405 from
#                           st_tfa_12.2.1.1.01
#    cpujar      05/17/17 - Summary bug 26090405
#    cpujar      03/05/17 - Code cleanup, ci navigation Bug25971734
#    bburton     04/25/17 - Removed unneeded XML Parser
#    bibsahoo    04/13/17 - Update Windows changes
#    cpujar      04/03/17 - Creation
#
package tfactlsummaryinterface;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(component_shell
  summaryinterface_execute_profile_normal
  summaryinterface_process_collection
  summaryinterface_consolidated_collection_reports
);
use strict;
use Math::BigInt;
use File::Spec::Functions;
use File::Path;
use Getopt::Long qw(GetOptions);
use Data::Dumper;
use tfactlglobal;
use tfactlshare;
use tfactlstore;
use tfactladmin;
use tfactlsumreport;
use tfactlsumcollection;

# -----------------------
sub summary_shell_help
{
  print "\n";
  print "  Following commands are supported in Summary Command-Line Interface\n";
  print "    l|list         => List Supported Components|Nodes|Databases|Tables\n";
  print "    number|select  => Select Component|Node|Database Listed in 'list'\n";
  print "    b|back         => UnSelect Component|Node|Database\n";
  ### print "    number|show    => Show Summary Table for listed(list) table name\n";
  print "    c|clear        => Clear Console\n";
  print "    q|quit         => Quit Summary Command-Line Interface\n";
  print "    ~              => Summary Command-Line Interface Home\n";
  print "    h|help         => Help\n";
  print "\n";
}

# component_shell is invoked from tfactlshare
sub component_shell
{
  my $tfa_home                = shift;
  my $TIME                    = shift;
  my $report_type             = shift;
  my $display_table           = shift;
  my $hashref                 = shift;
  my $myshell                 = shift;
  my $components_ref          = shift;
  my $complete_overview       = shift;
  my $component_name_selected = shift;
  my %components;
  my @comp_order = (); # tfasimplerep
  my @nodelist   = @{$SUMMARY_NODE_LIST_REF};
  my %nodes;
  my $prefixcomp   = "";
  my $compname = "";
   my $cmdnodename = "";
  my %hash = %$hashref;

  # Add available nodes to the options
  for (@nodelist) {
     $nodes{"$_"} = TRUE;
  }

  if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} ) {
    print "entering sub component_shell ...\n";
    print "--------------------------------\n";
    print "tfa_home $tfa_home\n";
    print "TIME $TIME\n";
    print "report_type $report_type\n";
    print "display_table $display_table\n";
    print "hashref $hashref\n";
    print "myshell $myshell\n";
    print "components_ref $components_ref\n";
    print "complete_overview $complete_overview\n";
    print "component_name_selected $component_name_selected\n";
    print "--------------------------------\n";
  } # end if tracing

  # tfasimplerep
  foreach my $comp (@{$SUMMARY_COMPONENT_ORDER_REF}) {
    # comment next line if level="1" needs to be included
    # in order to show "cluster_status_summary" again

    ### next if ($comp eq "overview");

    if ($comp eq "overview") { # Include cluster_status_summary
      push @comp_order, $comp;
    } else {
      push @comp_order, $comp."overview"; # =====> INCLUDE clusterwide SUMMARIES
    }
  } # end foreach
  if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} ) {
    print "[component_shell] comp_order @comp_order\n";
    print "                  component_name_selected $component_name_selected \n";
  }

  if ( defined $component_name_selected )
  {
    # --------------------- tfasimplerep ---------------------------
    my $count = 1;
    $compname= "";
    $cmdnodename = "";

    # ----------------------------------
    # Determine $cmdnodename & $compname
    #
    # based on $component_name_selected
    # e.g. For $component_name_selected = exadata_busm01client01
    #          ^^^^^^        ^^^^^^^^
    #        $compname       $cmdnodename
    # ----------------------------------

    # Check if node/component exist
    if ( $component_name_selected =~ /(.*?)\_(.*)/ && exists $nodes{$2} && exists $hash{$1} ) {
        $compname = $1;
        $cmdnodename = $2;
    } else {
      $compname = $component_name_selected;
    }

    # Tracing
    print "cmdnodename $cmdnodename, compname $compname \n" if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} );

    # --------------------------------------
    # Prepare keys for given component "$compname"
    # based on $hash{$compname}
    # Valid for Overview subcomponents &
    # <component>_nodewise subcomponents
    # Including only console="yes" reports
    #
    # tfasimplerep
    #
    # e.g. For tfactl_summary_exadataoverview> ,
    # [component_shell] key exadata_clusterwide_status
    # [component_shell] key exadata_clusterwide_summary
    # --------------------------------------
    foreach my $key (keys %{$hash{$compname}} ) {
         my $consoleenabled = $hash{$compname}{$key}{"console"};
         # exadata_cell_details/exadata_infiband_switches_details don't work, disable
         next if ($key =~ /exadata_cell_details/ ||
                  $key =~ /exadata_infiband_switches_details/ );
         print "[component_shell] key $key\n" if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} );
        if ( $key =~ /clusterwide_status/ || (length $cmdnodename) ) {
          print "console report = $consoleenabled\n" if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} );
          if ( lc($consoleenabled) eq "yes" ) { # Include only consoleenables reports console="yes"
            $components{$count++} = $key;
            if ( (not length $prefixcomp) && $key =~ /(.*?)_.*/ ) {
              $prefixcomp = $1;
            }
          } # end if lc($consoleenabled) eq "yes"
        } # end if $key =~ /clusterwide_status/ || (length $cmdnodename
    }

    # ---------------------------------------------------
    # Generate all available reports
    # called recursively by previous level
    # for <component>_<node1>
    #           ...
    #     <component>_<nodeN>
    #
    # includes console="yes" & clusterwide="yes" reports
    # e.g. ,
    #   2 => network_busm01client01
    #   3 => network_busm01client02
    #
    # tfasimplerep
    # ---------------------------------------------------
    if ( length $cmdnodename ) {
      # tracing
      if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} ) {
        print "----------------------------------------------------------------------\n";
        print "sub component_shell() generate all reports available for $compname ...\n";
        print "compname $compname\n";
        print "cmdnodename $cmdnodename\n";
        print "----------------------------------------------------------------------\n";
      }

      for ( my $cnt=1; $cnt < $count; ++$cnt ) {
         my $compreport = $components{$cnt}; 
         my $clusterwide    = $hash{$compname}{$compreport}{"clusterwide"};
         print "report $compreport, clusterwide = $clusterwide\n" if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} );
         next if $clusterwide eq "no"; # only include clusterwide enabled reports
         print "\n\n     =====> $compreport\n";

         # -------------------------------
         # call all the available reports for the node
         # tfasimplerep
         #
         #   1 => <component>_clusterwide_status
         #   2 => <component>_<node1>
         #   ...
         #   N => <componetn>_<nodeN>
         # -------------------------------------------
         my $node_name = $hostname;
         my $repository_base_nodewise = catfile( $SUMMARY_REPOSITORY, $node_name );
         my $status;
         my $data;

         if ( $node_name ne $cmdnodename ) {
           ( $status, $data ) = get_dependent_remote_data( $cmdnodename, $compname, $compreport );
         } else {
           my $get_dependent_data_loc =
             catfile( $repository_base_nodewise, "data", $compname, "$compreport.json" );
           $status = "false" if ( !-e $get_dependent_data_loc );
         } # end if $node_name ne $cmdnodename

         # Report Not enabled for Clusterwide collection
         if ( $status eq "false" ) { print "Report Not enabled for Clusterwide collection\n"; next; }

         sumreport_create_console_report( $compname, $repository_base_nodewise, ["$compreport"], $cmdnodename, $data->{'DETAILS'} );

      }
      return "list"; # ret list after display all available reports
    } else {
      # -------------------------------
      # call the <component>_clusterwide_status 
      # when entering the second level menu
      #
      # tfasimplerep
      #
      # -------------------------------------------
      my $node_name = $hostname;
      my $repository_base_nodewise = catfile( $SUMMARY_REPOSITORY, $node_name );
      my $component = "";
      my $compreport = "";
      my %rev_components = reverse %components;
      if ( $compname =~ /(.*)overview/ ) {
        $component = $1;
      }
      $compreport = $component . "_clusterwide_status" if exists $rev_components{$component . "_clusterwide_status"};

      # tracing
      if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} ) {
        print "----------------------------------------------------------------------\n";
        print "sub component_shell() generate $compname clusterwide_status reports...\n";
        print "node_name                 $node_name\n";
        print "repository_base_nodewise $repository_base_nodewise\n";
        print "compname                 $compname\n";
        print "component                $component\n";
        print "compreport               $compreport\n";
        print "Generating auto report ... $compreport \n";
        print "----------------------------------------------------------------------\n";
      }

      # Generate <component>_clusterwide_status report
      sumreport_create_console_report( $compname, $repository_base_nodewise, ["$compreport"], $node_name );

    }  # end if length $cmdnodename

    # ---------------------------------
    # Add option to print all options
    # tfasimplerep alloptions
    # ---------------------------------
    # Uncomment next three lines to enable "print all options"
    ### if ( length $cmdnodename ) {
    ###  $components{$count++} = "Print all options";
    ### }


    # Add available nodes to the options
    # only for second level
    #
    # e.g. ,
    #   1 => exadata_clusterwide_status
    #        ^^^^^^^
    #        $prefixcomp
    #   2 => exadata_busm01client01
    #   3 => exadata_busm01client02
    # ----------------------------------
    if (not length $cmdnodename) {
      for (@nodelist) {
         $components{ $count++ } = "$prefixcomp" . "_" . "$_";
      }
    }
    
    # --------------------------------------------------------------
    # Uncomment next two lines for full version
    ### $components{"1"} = "${component_name_selected}overview";
    ### $components{"2"} = "nodewise";
  } else
  {
    my $count = 1;
    # Uncomment next line for full version
    ### foreach my $key ( grep { exists $components_ref->{$_} } @{$SUMMARY_COMPONENT_ORDER_REF} )
    foreach my $key ( @comp_order )
    {
      # Uncomment next line for full
      ### $components{ $count++ } = "$key" if ( $components_ref->{$key} == 1 );
      $components{ $count++ } = "$key"; # tfasimplerep
    }
  }
  my %rev_components = reverse %components;
  my $input_command  = "list";
  print "$myshell>list\n";
  while (1)
  {
    # tracing
    if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} ) {
      print "entering loop  ======================> \n";
      print "input_command $input_command \n";
    }

    my $select_component = "yes";
    if ( $input_command =~ m/^select\s+/ )
    {
      $input_command =~ s/select\s+//g;
    }
    if ( $input_command eq 'list' or $input_command eq 'l' )
    {
      print "\n  Status Type: Select Status Type - select [status_type_number|status_type_name]\n"
        if ( defined $component_name_selected );
      print "\n  Components : Select Component - select [component_number|component_name]\n"
        if ( !defined $component_name_selected );
      foreach my $key ( sort { $a <=> $b } keys %components )
      {
        # ---------------------------------------------
        # tfasimplerep
        # Add an underscore into overview command names
        # <n> => <component>_overview
        # ---------------------------------------------
        my $entry = $components{$key};
        if ( $entry =~ /(.+)overview/ ) {
          $entry = $1 . "_overview";
        }
        print "\t$key => $entry\n";
      }
      print "\n";
    } elsif (     ( $select_component eq "yes" )
              and ( exists $components{$input_command} or exists $rev_components{$input_command} ) )
    {
      my $component_name = "$components{$input_command}" if ( exists $components{$input_command} );
      $component_name = $input_command if ( !defined $component_name );

      # ====================================================
      # create tfaclt summary simple report (tfasimplerep)
      # ====================================================

      my $node_name = $hostname;
      my $repository_base_nodewise = catfile( $SUMMARY_REPOSITORY, $node_name );

      # -------------------------------------------------
      # Determine $cmdnodename & $component_name_selected
      # -------------------------------------------------

      if ( not length $cmdnodename ) {
        #if ( $myshell =~ /tfactl_.*?_(.*)/ ) {
        #  $cmdnodename = $1 if exists $nodes{$1};
        #}
        if ( $component_name_selected =~ /(.*?)\_(.*)/ && exists $nodes{$2} ) {
          $component_name_selected = $1;
          $cmdnodename = $2;
        }
      } else {
        if ( $component_name_selected =~ /(.*?)\_(.*)/ && exists $nodes{$2} ) {
          $component_name_selected = $1;
          $cmdnodename = $2;
        }
      }  # end if not length $cmdnodename

      # Tracing section
      if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} ) { 
        print "sub component_shell()\n";
        print "---------------------\n";
        print "about to call sumreport_create_console_report() ...\n";
        print "component_name           $component_name\n";
        print "component_name_selected  $component_name_selected\n";
        print "command_name             $component_name\n";
        print "repository_base_nodewise $repository_base_nodewise\n";
        print "node_name                $node_name\n";
        print "cmdnodename              $cmdnodename\n";
        print "sub component_shell()\n";
        print "---------------------\n";
      } # end if tracing

      # <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
      if ( $component_name =~ /clusterwide_status/ ) { # clusterwide_status reports
        # -------------------------------
        # call clusterwide_status reports
        # tfasimplerep clusterwide_status reports
        #
        # e.g.,
        #    1 => crs_clusterwide_status
        #    ...
        #    1 => asm_clusterwide_status
        #    ...
        #    1 => acfs_clusterwide_status
        #
        # Section for processing,
        #   1 => crsoverview
        #   2 => asmoverview
        #   ...
        #   11 => summaryoverview
        # -------------------------------
        sumreport_create_console_report( $component_name_selected, $repository_base_nodewise, ["$component_name"], $node_name );
        $input_command = "list";
        next;
      } elsif ( length $cmdnodename ) {
        # -------------------------------
        # call all the available reports for the node
        # tfasimplerep
        #
        #   1 => <component>_clusterwide_status
        #   2 => <component>_<node1>
        #   ...
        #   N => <componetn>_<nodeN>
        # -------------------------------------------
        my $status;
        my $data;

        if ( $node_name ne $cmdnodename ) {
          ( $status, $data ) = get_dependent_remote_data( $cmdnodename, $component_name_selected, $component_name );
        } else {
          my $get_dependent_data_loc =
            catfile( $repository_base_nodewise, "data", $component_name_selected, "$component_name.json" );
          $status = "false" if ( !-e $get_dependent_data_loc );
        } # end if $node_name ne $cmdnodename

        if ( $status eq "false" ) { print "Command Not enabled for Clusterwide collection\n"; return "q"; }

        sumreport_create_console_report( $component_name_selected, $repository_base_nodewise, ["$component_name"], $cmdnodename, $data->{'DETAILS'} );
      } # end if $component_name =~ /clusterwide_status/
      # >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

      my $newshell = "${myshell}_$component_name";

      # Determine $cmdnodename from $component_name
      my $cmdnodename = "";
      if ( $component_name =~ /$prefixcomp\_(.*)/ ) {
        $cmdnodename = $1;
      }

      # ----------------------------------------------
      # Call shells
      # show additional levels component_shell()
      # ----------------------------------------------
      if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} ) {
        print "sub component_shell(), call shells -> show additional levels ...\n";
        print "----------------------------------------------------------------\n";
        print "component_name  $component_name\n";
        print "cmdnodename     $cmdnodename \n";
        print "----------------------------------------------------------------\n";
      } # end if tracing

      if ( $component_name =~ /$prefixcomp/ && exists $nodes{$cmdnodename} ) {
        # tfasimplerep
        $newshell = "tfactl_summary_" . $component_name;

        # tracing
        if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} ) { 
          print "newshell $newshell \n";
          print "component_shell(): about to call component_shell recursively, component_name $component_name \n";
        } # end if tracing

        $input_command = &component_shell( $tfa_home,      $TIME,              $report_type,
                                           $display_table, $hashref,           $newshell,
                                           \%components,   $complete_overview, $component_name );

        print "input_command ret ($input_command) after calling component_shell()\n" if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} );
        next if $input_command eq "list"; # tfasimplerep show command listing again ...
        return "q" if not length $input_command;

      } elsif ( $component_name eq "overview" )
      {
        # -------------------------------
        # tfasimplerep overview
        # Show "Overview" menu
        # processed by command_shell()
        # -------------------------------
 
        $input_command = &command_shell(
                                         $tfa_home,       $TIME,              $report_type,    $display_table,
                                         $components_ref, $hashref,           $component_name, $hostname,
                                         $newshell,       $complete_overview, ''
        );
        if ( $input_command eq 'back' or $input_command eq 'b' or $input_command eq '~' ) { $input_command = "list"; next; }
        else                                                     { return "q"; }
      } elsif ( !defined $component_name_selected )
      {
        # tfasimplerep
        print "component_shell(): about to call component_shell recursively, component_name $component_name \n" if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} );
        $input_command = &component_shell(
                                           $tfa_home,      $TIME,              $report_type,
                                           $display_table, $hashref,           $newshell,
                                           \%components,   $complete_overview, $component_name
        );
        if ( $input_command eq 'back' or $input_command eq 'b' or $input_command eq '~' ) { $input_command = "list"; next; }
        else                                                     { return "q"; }
      } elsif ( $component_name eq "nodewise" )
      {
        $input_command = &node_shell(
                                      $tfa_home,                $TIME,           $report_type,
                                      $display_table,           $components_ref, $hashref,
                                      $component_name_selected, $newshell,       $complete_overview
        );
        if ( $input_command eq '~') { return "~"; }
        elsif ( $input_command eq 'back' or $input_command eq 'b' ) { $input_command = "list"; next; }
        else                                                     { return "q"; }
      } elsif ( $component_name =~ "overview" )
      {
        $input_command = &command_shell(
                                         $tfa_home,       $TIME,              $report_type,    $display_table,
                                         $components_ref, $hashref,           $component_name, $hostname,
                                         $newshell,       $complete_overview, ''
        );
        if ( $input_command eq '~') { return "~"; }
        elsif ( $input_command eq 'back' or $input_command eq 'b') { $input_command = "list"; next; }
        else                                                     { return "q"; }
      }
    } elsif ( $input_command =~ m/^(h|help)$/ )
    {
      summary_shell_help();
    } elsif ( defined $component_name_selected and $input_command =~ m/^(b|back)$/ )
    {
      return 'b';
    } elsif ( defined $component_name_selected and $input_command =~ m/^(~)$/ )
    {
      return '~';
    } elsif ( $input_command =~ m/^(b|back)$/ )
    {
      print "  [ERROR] Nothing is Selected to Unselect\n\n";
    } elsif ( $input_command =~ m/^(~)$/ )
    {
      print "  [MESSAGE] At Summary Command-Line Interface Home\n\n";
    } elsif ( $input_command =~ m/^(q|quit)$/ )
    {
      return "q";
    } elsif ( $input_command =~ m/^show\s+/ )
    {
      print "  [ERROR] Please Select Component to show Summary Tables\n\n";
    } elsif ( $input_command eq '' )
    {
    } elsif ( $input_command eq 'clear' or $input_command eq 'c' )
    {
      system("clear");
    } else
    {
      print "  [ERROR] Command \'$input_command\' not found\n";
    }
    print "$myshell>";
    $input_command = <STDIN>;
    chomp($input_command);
    $input_command =~ s/^\s+|\s+$//g;
  } continue
  {
    last unless ( $input_command !~ m/^(q|quit)$/ );
  }
}

sub node_shell
{
  my $tfa_home          = shift;
  my $TIME              = shift;
  my $report_type       = shift;
  my $display_table     = shift;
  my $components_ref    = shift;
  my $hashref           = shift;
  my $component_name    = shift;
  my $myshell           = shift;
  my $complete_overview = shift;
  my %nodes_list;
  my @nodelist;

  if ( $component_name eq "overview" )
  {
    @nodelist = ("$hostname");
  } else
  {
    @nodelist = @{$SUMMARY_NODE_LIST_REF};
  }
  my $count = 1;
  for (@nodelist)
  {
    $nodes_list{ $count++ } = "$_";
  }
  my %rev_nodes_list = reverse %nodes_list;
  my $input_command  = "list";
  print "$myshell>list\n";
  while (1)
  {
    my $select_node = "yes";
    if ( $input_command =~ m/^select\s+/ )
    {
      $input_command =~ s/select\s+//g;
    }
    if ( $input_command eq 'list' or $input_command eq 'l' )
    {
      print "\n  Nodes : Select Node - select [node_number|node_name]\n";
      foreach my $key ( sort { $a <=> $b } keys %nodes_list )
      {
        print "\t$key => $nodes_list{$key}\n";
      }
      print "\n";
    } elsif (     ( $select_node eq "yes" )
              and ( exists $nodes_list{$input_command} or exists $rev_nodes_list{$input_command} ) )
    {
      my $node_name = "$nodes_list{$input_command}" if ( exists $nodes_list{$input_command} );
      $node_name = $input_command if ( !defined $node_name );
      my $newshell = "${myshell}_$node_name";
      if ( $component_name eq "database" )
      {
        $input_command = &dbname_shell(
                                        $tfa_home,       $TIME,    $report_type,    $display_table,
                                        $components_ref, $hashref, $component_name, $node_name,
                                        $newshell,       $complete_overview
        );
      } else
      {
        $input_command = &command_shell(
                                         $tfa_home,       $TIME,              $report_type,    $display_table,
                                         $components_ref, $hashref,           $component_name, $node_name,
                                         $newshell,       $complete_overview, ''
        );
      }
      if ( $input_command eq '~') { return "~"; }
      elsif ( $input_command eq 'back' or $input_command eq 'b' ) { $input_command = "list"; next; }
      else                                                     { return "q"; }
    } elsif ( $input_command =~ m/^(h|help)$/ )
    {
      summary_shell_help();
    } elsif ( $input_command =~ m/^(b|back)$/ )
    {
      return 'back';
    } elsif ( $input_command =~ m/^(~)$/ )
    {
      return '~';
    } elsif ( $input_command =~ m/^(q|quit)$/ )
    {
      return 'q';
    } elsif ( $input_command =~ m/^show\s+/ )
    {
      print "  [ERROR] Please Select Node to show Summary Tables\n\n";
    } elsif ( $input_command eq '' )
    {
    } elsif ( $input_command eq 'clear' or $input_command eq 'c' )
    {
      system("clear");
    } else
    {
      print "  [ERROR] Command \'$input_command\' not found\n";
    }
    if ( $input_command ne 'q' )
    {
      print "$myshell>";
      $input_command = <STDIN>;
      chomp($input_command);
      $input_command =~ s/^\s+|\s+$//g;
    }
  } continue
  {
    last unless ( $input_command !~ m/^(q|quit)$/ );
  }
}

sub command_shell
{
  my $tfa_home           = shift;
  my $TIME               = shift;
  my $report_type        = shift;
  my $display_table      = shift;
  my $components_ref     = shift;
  my $hashref            = shift;
  my $component_name     = shift;
  my $node_name          = shift;
  my $myshell            = shift;
  my $complete_overview  = shift;
  my $database_home_name = shift;
  my $this_db_name       = shift;
  my %command_list;
  my @commands;
  my %command_order;
  my $command_sequence;

  # tracing
  if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} ) {
    print "--------------------------------\n";
    print "Entering command_shell() sub ...\n";
    print "component_name $component_name\n";
    print "--------------------------------\n";
  }

  if ( $component_name eq 'overview1' )
  {
    $command_sequence = $hashref->{$component_name}->{'cluster_nodes'}->{'sequence'};
    $command_order{$command_sequence} = "cluster_nodes";
    foreach my $command ( keys %{ $hashref->{$component_name} } )
    {
      $command =~ s/_status//g;
      if ( $components_ref->{$command} == 1 )
      {
        $command_sequence = $hashref->{$component_name}->{"${command}_status"}->{'sequence'};
        $command_order{$command_sequence} = "${command}_status";
      }
    }
    if ( $complete_overview eq "yes" )
    {
      $command_sequence = $hashref->{$component_name}->{"cluster_status_summary"}->{'sequence'};
      $command_order{$command_sequence} = "cluster_status_summary";
    }
  } else
  {
    foreach my $command ( keys %{ $hashref->{$component_name} } )
    {
      if ( $hashref->{$component_name}->{$command}->{'console'} eq "yes" )
      {
        if ( $hashref->{$component_name}->{$command}->{'clusterwide'} eq "yes" or $node_name eq $hostname )
        {
          $command_sequence = $hashref->{$component_name}->{$command}->{'sequence'};
          # -------------------------------------------------------
          # tfasimplerep overview (top level option)
          # For overview display only cluster_status_summary option
          # -------------------------------------------------------
          if ( $component_name eq "overview" ) {
            if ( $command =~ /cluster_status_summary/ ) {
              $command_order{$command_sequence} = $command;
            }
          } else {
            $command_order{$command_sequence} = $command;
          }
        }
      }
    }
  }
  my $count = 1;
  foreach my $command ( sort keys %command_order )
  {
    $command_list{ $count++ } = $command_order{$command};
  }
  my %rev_command_list = reverse %command_list;
  my $input_command    = "list";

  # tfasimplerep
  ###print "$myshell>list\n";
  while (1)
  {
    my $show_handle = "yes";
    if ( $input_command =~ m/^show\s+/ )
    {
      $input_command =~ s/^show\s+//g;
    }
    if ( $input_command eq 'list' or $input_command eq 'l' )
    {
      if ( keys %command_list == 0 )
      {
        print "\n  Summary Table Not-Found in Selected Node\n\n";
      } else
      {
        # tfasimplerep cluster_status_summary
        # overview reports, 
        if ( exists $rev_command_list{"cluster_status_summary"} ) {
          my $node_name = $hostname;
          my $repository_base_nodewise = catfile( $SUMMARY_REPOSITORY, $node_name );
          my $component_name = "overview";
          my $command_name = "cluster_status_summary";

          my $status;
          my $data;
          if ( $node_name ne $hostname )
          {
            ( $status, $data ) = get_dependent_remote_data( $node_name, $component_name, $command_name );
          } else
          {
            my $get_dependent_data_loc =
              catfile( $repository_base_nodewise, "data", $component_name, "$command_name.json" );
            $status = "false" if ( !-e $get_dependent_data_loc );
          }
          if ( $status eq "false" ) { print "Command Not enabled for Clusterwide collection\n"; next; }

            sumreport_create_console_report( "overview", $repository_base_nodewise, ["cluster_status_summary"], $node_name, $data->{'DETAILS'} );
        }

        print "\n  Tables : Show Table - show [table_number|table_name]\n\n";
        foreach my $key ( sort { $a <=> $b } keys %command_list )
        {
          print "\t$key => $command_list{$key}\n";
        }
      }
      print "\n";
    } elsif (     ( $show_handle eq "yes" )
              and ( exists $command_list{$input_command} or exists $rev_command_list{$input_command} ) )
    {
      my $command_name = $command_list{$input_command} if ( exists $command_list{$input_command} );
      $command_name = $input_command if ( !defined $command_name );
      if ( $component_name eq "database" )
      {
        my $repository_base_nodewise = catfile( $SUMMARY_REPOSITORY, $node_name );
        my $dep_hash_repository_loc =
          catfile( $repository_base_nodewise, "hashdata", $component_name, "${command_name}.hash" );
        my $dep_hash_ref;
        my $status;
        if ( $node_name ne $hostname )
        {
          ( $status, $dep_hash_ref ) = get_dependent_remote_data( $node_name, $component_name, $command_name );
          if ( $status eq "false" ) { print "Command Not enabled for Clusterwide collection\n"; next; }
        } else
        {
          if ( !-e $dep_hash_repository_loc ) { print "Command Not enabled for Clusterwide collection\n"; next; }
          $dep_hash_ref = tfactlstore_retrieve_json_to_hash($dep_hash_repository_loc);
        }
        my @databasewise_details;
        foreach my $data_home_ref ( @{ $dep_hash_ref->{'DETAILS'} } )
        {
          if ( $data_home_ref->{'ORACLE_HOME_NAME'} eq $database_home_name )
          {
            foreach my $data_hash_ref ( @{ $data_home_ref->{'ORACLE_HOME_DETAILS'} } )
            {
              if ( $data_hash_ref->{'DATABASE_NAME'} eq $this_db_name )
              {
                push(
                      @databasewise_details,
                      {
"DATABASE ORACLE_HOME_NAME - \'$database_home_name\' DATABASE - \'$this_db_name\' DATABASE DETAILS"
                          => $data_hash_ref->{'DATABASE_DETAILS'}
                      }
                );
              }
            }
          }
        }

        # tfasimplerep
        if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} ) {
          print "sub command_shell()\n";
          print "about to call sumreport_create_console_report() ...\n";
          print "component_name           $component_name \n";
          print "command_name             $command_name\n";
          print "repository_base_nodewise $repository_base_nodewise\n";
          print "node_name                $node_name\n";
        }

        sumreport_create_console_report( $component_name, $repository_base_nodewise,
                                         ["${command_name}_${this_db_name}"],
                                         $node_name, \@databasewise_details );
      } else
      {
        my $repository_base_nodewise = catfile( $SUMMARY_REPOSITORY, $node_name );
        my $status;
        my $data;
        if ( $node_name ne $hostname )
        {
          ( $status, $data ) = get_dependent_remote_data( $node_name, $component_name, $command_name );
        } else
        {
          my $get_dependent_data_loc =
            catfile( $repository_base_nodewise, "data", $component_name, "$command_name.json" );
          $status = "false" if ( !-e $get_dependent_data_loc );
        }
        if ( $status eq "false" ) { print "Command Not enabled for Clusterwide collection\n"; next; }

        # ---------------------------------------
        # tfasimplerep
        # Display cluster_status_summary report
        # ---------------------------------------
        if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} ) {
          print "sub command_shell()\n";
          print "about to call sumreport_create_console_report() ...\n";
          print "component_name           $component_name \n";
          print "command_name             $command_name\n";
          print "repository_base_nodewise $repository_base_nodewise\n";
          print "node_name                $node_name\n";
        }

        sumreport_create_console_report( $component_name, $repository_base_nodewise, ["$command_name"], $node_name, $data->{'DETAILS'} );
        # tfasimplerep redisplay "list" after report
        $input_command = "list";
        next;
        undef $data;
        undef $status;
      }
    } elsif ( $input_command =~ m/^(h|help)$/ )
    {
      summary_shell_help();
    } elsif ( $input_command =~ m/^(b|back)$/ )
    {
      return 'back';
    } elsif ( $input_command =~ m/^(~)$/ )
    {
      return '~';
    } elsif ( $input_command =~ m/^(q|quit)$/ )
    {
      return "q";
    } elsif ( $input_command =~ m/^select\s+/ )
    {
      print "  [ERROR] Please show Summary Table : 'show table_number|table_name'\n\n";
    } elsif ( $input_command eq '' )
    {
    } elsif ( $input_command eq 'clear' or $input_command eq 'c' )
    {
      system("clear");
    } else
    {
      print "  [ERROR] Command \'$input_command\' not found\n";
    }
    if ( $input_command ne 'q' )
    {
      print "$myshell>";
      $input_command = <STDIN>;
      chomp($input_command);
      $input_command =~ s/^\s+|\s+$//g;
    }
  } continue
  {
    last unless ( $input_command !~ m/^(q|quit)$/ );
  }
}

sub dbname_shell
{
  my $tfa_home           = shift;
  my $TIME               = shift;
  my $report_type        = shift;
  my $display_table      = shift;
  my $components_ref     = shift;
  my $hashref            = shift;
  my $component_name     = shift;
  my $node_name          = shift;
  my $myshell            = shift;
  my $complete_overview  = shift;
  my $database_home_name = shift;
  my $command_name       = "database_get_running_db_details";
  my $dep_hash_ref;
  my $status;

  if ( $node_name ne $hostname )
  {
    ( $status, $dep_hash_ref ) = get_dependent_remote_data( $node_name, $component_name, $command_name );
  } else
  {
    my $repository_base_nodewise = catfile( $SUMMARY_REPOSITORY, $node_name );
    my $dep_hash_repository_loc =
      catfile( $repository_base_nodewise, "hashdata", $component_name, "${command_name}.hash" );
    $dep_hash_ref = tfactlstore_retrieve_json_to_hash($dep_hash_repository_loc);
  }
  my @databasewise_details;
  my @db_list;
  if ( defined $database_home_name )
  {
    @db_list = ( keys %{ $dep_hash_ref->{'DETAILS'}->{$database_home_name} } );
  } else
  {
    @db_list = ( keys %{ $dep_hash_ref->{'DETAILS'} } );
  }
  my %db_name_list;
  my $count = 1;
  for (@db_list)
  {
    $db_name_list{ $count++ } = "$_";
  }
  my %rev_db_name_list = reverse %db_name_list;
  my $input_command    = "list";
  print "$myshell>list\n";
  while (1)
  {
    my $select_db = "yes";
    if ( $input_command =~ m/^select\s+/ )
    {
      $input_command =~ s/select\s+//g;
    }
    if ( $input_command eq 'list' or $input_command eq 'l' )
    {
      if ( keys %db_name_list == 0 )
      {
        print "\n  Database Not Running in Selected Node\n\n";
      } else
      {
        print "\n  Database : Please Select with Respective Number\n";
        foreach my $key ( sort { $a <=> $b } keys %db_name_list )
        {
          if ( defined $database_home_name )
          {
            print "\t$key => $db_name_list{$key}\n";
          } else
          {
            my $oracle_home_name = $db_name_list{$key};
            my $db               = ( keys %{ $dep_hash_ref->{'DETAILS'}->{$oracle_home_name} } )[0];
            my $oh_path          = ( split( /\|/, $dep_hash_ref->{'DETAILS'}->{$oracle_home_name}->{$db} ) )[1];
            print "\t$key => $oracle_home_name [ $oh_path ]\n";
          }
        }
        print "\n";
      }
    } elsif (     ( $select_db eq "yes" )
              and ( exists $db_name_list{$input_command} or exists $rev_db_name_list{$input_command} ) )
    {
      my $this_db_name = "$db_name_list{$input_command}" if ( exists $db_name_list{$input_command} );
      $this_db_name = $input_command if ( !defined $this_db_name );
      my $newshell = "${myshell}_$this_db_name";
      if ( defined $database_home_name )
      {
        $input_command = &command_shell(
                                         $tfa_home,          $TIME,               $report_type,
                                         $display_table,     $components_ref,     $hashref,
                                         $component_name,    $node_name,          $newshell,
                                         $complete_overview, $database_home_name, $this_db_name
        );
      } else
      {
        $input_command = &dbname_shell(
                                        $tfa_home,       $TIME,              $report_type,    $display_table,
                                        $components_ref, $hashref,           $component_name, $node_name,
                                        $newshell,       $complete_overview, $this_db_name
        );
      }
      if ( $input_command eq '~') { return "~"; }
      elsif ( $input_command eq 'back' or $input_command eq 'b' ) { $input_command = "list"; next; }
      else                                                     { return "q"; }
    } elsif ( $input_command =~ m/^(h|help)$/ )
    {
      summary_shell_help();
    } elsif ( $input_command =~ m/^(b|back)$/ )
    {
      return 'back';
    } elsif ( $input_command =~ m/^(~)$/ )
    {
      return '~';
    } elsif ( $input_command =~ m/^(q|quit)$/ )
    {
      return "q";
    } elsif ( $input_command =~ m/^show\s+/ )
    {
      print "  [ERROR] Please Select Database to show Summary Tables\n\n";
    } elsif ( $input_command eq '' )
    {
    } elsif ( $input_command eq 'clear' or $input_command eq 'c' )
    {
      system("clear");
    } else
    {
      print "  [ERROR] Command \'$input_command\' not found\n";
    }
    if ( $input_command ne 'q' )
    {
      print "$myshell>";
      $input_command = <STDIN>;
      chomp($input_command);
      $input_command =~ s/^\s+|\s+$//g;
    }
  } continue
  {
    last unless ( $input_command !~ m/^(q|quit)$/ );
  }
}

sub summaryinterface_execute_profile_normal
{
  my $tfa_home          = shift;
  my $command_array_ref = shift;
  my $component         = shift;
  my $repository_loc    = shift;
  my $profile_hashref   = shift;
  my $command_method;
  my $repository;
  my $hash_repository;
  my $method_ref;
  my $repository_base;

  foreach my $command ( @{$command_array_ref} )
  {
    tfactlstore_summary_log( "Command executed: $component:$command", "summaryinterface_execute_profile_normal" );
    $repository_base = $repository_loc;
    $repository      = catfile( $repository_loc, "data", $component, "$command.json" );
    $hash_repository = catfile( $repository_loc, "hashdata", $component, "$command.hash" );
    $command_method  = "sumcollection_$command";

    # tfasimplerep

    print "calling sumcollection_$command() \n" if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} );
    $method_ref      = \&{$command_method};
    $method_ref->( $tfa_home, $repository_base, $repository, $hash_repository, $profile_hashref );
  }
}

sub summaryinterface_process_collection
{
  my $component         = shift;
  my $repository_loc    = shift;
  my $hashref           = shift;
  my $report_type       = shift;
  my $driverhost        = shift;
  my $command_array_ref = shift;
  my $complete_overview = shift;
  my %console_hash;
  my %html_hash;
  my %json_hash;
  my $sequence;

  foreach my $command ( keys %{ $hashref->{$component} } )
  {
    if ( ( $hashref->{$component}->{$command}->{'clusterwide'} eq "yes" ) or ( $hostname eq $driverhost ) )
    {
      if ( $hashref->{$component}->{$command}->{'json'} eq "yes" )
      {
        $sequence = $hashref->{$component}->{$command}->{'sequence'};
        $sequence =~ s/display_sequence=//;
        $json_hash{$command} = $sequence;
      }
      if ( $hashref->{$component}->{$command}->{'html'} eq "yes" )
      {
        $sequence = $hashref->{$component}->{$command}->{'sequence'};
        $sequence =~ s/display_sequence=//;
        $html_hash{$command} = $sequence;
      }
    }
  }
  my @console_command_array;
  my @json_command_array;
  my @html_command_array;
  if ( $component eq "overview" )
  {
    if ( $complete_overview eq "yes" )
    {
      @console_command_array = ("summary_overview");
    } else
    {
      @console_command_array = ("cluster_status_summary");
    }
    @json_command_array = ("cluster_status_summary");
    @html_command_array = ("cluster_status_summary");
  } else
  {
    @json_command_array = sort { $json_hash{$a} <=> $json_hash{$b} } keys %json_hash;
    @html_command_array = sort { $html_hash{$a} <=> $html_hash{$b} } keys %html_hash;
  }
  sumreport_create_console_report( $component, $repository_loc, \@console_command_array );
  sumreport_create_json_report( $component, $repository_loc, \@json_command_array )
    if ( $SUMMARY_REPORTTYPE =~ /json/ );
  sumreport_create_html_report( $component, $repository_loc, \@html_command_array )
    if ( $SUMMARY_REPORTTYPE =~ /html/ );
}

sub summaryinterface_consolidated_collection_reports
{
  my $tfa_home            = shift;
  my $time                = shift;
  my $repository_loc      = shift;
  my $report_type         = shift;
  my $components_hash_ref = shift;
  sumreport_create_console_report_consolidated( $tfa_home, $time, $repository_loc, $components_hash_ref );
  sumreport_create_json_report_consolidated( $tfa_home, $time, $repository_loc, $components_hash_ref )
    if ( $SUMMARY_REPORTTYPE =~ /json/ );
  sumreport_create_html_report_consolidated( $tfa_home, $time, $repository_loc, $components_hash_ref )
    if ( $SUMMARY_REPORTTYPE =~ /html/ );
}

sub get_dependent_remote_data
{
  my $host      = shift;
  my $component = shift;
  my $command   = shift;
  my $status    = "false";
  my $data ="";
  my $command_table ="";
  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  my $dep_hash_repository_loc = catfile($SUMMARY_REPOSITORY, "summaryfile-${host}.hash");
  my $dep_hashref;
  my $SUMMARY_REMOTE_DATA;
  if(-e $dep_hash_repository_loc and !-z $dep_hash_repository_loc){
    $dep_hashref = tfactlstore_retrieve_json_to_hash($dep_hash_repository_loc);
    $SUMMARY_REMOTE_DATA->{$host} = $dep_hashref;
  }

  foreach my $comp_details ( @{ $SUMMARY_REMOTE_DATA->{$host}->{"DETAILS"} } )
  {
    if ( $comp_details->{"COMPONENT"} eq "$component" )
    {
      foreach my $command_table ( @{ $comp_details->{"DETAILS"} } )
      {
        if ( $command_table->{"COMMAND"} eq "$command" )
        {
          $status = "true";
          my %command_tab = %{$command_table};
          $data = \%command_tab;  
        }
      }
    }
  }
  return ( $status, $data );
}
1;
