#
# $Header: tfa/src/v2/tfa_home/bin/common/tfactlsumreport.pm /main/3 2018/05/28 15:06:27 bburton Exp $
#
# tfactlsumreport.pm
#
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlsumreport.pm - Summary Report Preparation Module 
#
#    DESCRIPTION
#      Common module to prepare
#      1. Intermediate and consolodated reports
#      2. Prepare console(.txt), html and json reports. 
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    manuegar    11/02/17 - manuegar_summary_basrep2.
#    manuegar    10/25/17 - manuegar_summary_basrep.
#    cpujar      05/19/17 - XbranchMerge cpujar_bug-26090405 from
#                           st_tfa_12.2.1.1.01
#    bibsahoo    04/13/17 - Update changes
#    cpujar      12/29/16 - Creation
#
package tfactlsumreport;

BEGIN
{
  use Exporter();
  our ( @ISA, @EXPORT );
  @ISA = qw(Exporter);
  my @exp_func = qw(sumreport_create_console_report
    sumreport_create_json_report
    sumreport_create_html_report
    sumreport_create_console_report_consolidated
    sumreport_create_json_report_consolidated
    sumreport_create_html_report_consolidated
    sumreport_display_summary_report
    sumreport_create_console_report_consolidated_forall_nodes
    sumreport_create_json_report_consolidated_forall_nodes
    sumreport_create_html_report_consolidated_forall_nodes
    sumreport_display_summary_report_consolidated_forall_nodes
  );
  push @EXPORT, @exp_func;
}
use Text::ASCIITable;
use tfactlglobal;
use tfactlstore;
use tfactlshare;
use File::Spec::Functions;
use Data::Dumper;

# ------------------------------
my $CONSOLEREPORT;
my $JSONREPORT;
my $HASHREPORT;
my $HTMLREPORT;
my $JSONREPORT_CONSOLIDATE;
my $HASHREPORT_CONSOLIDATE;
my $CONSOLEREPORT_CONSOLIDATE;
my $HTMLREPORT_CONSOLIDATE;

sub sumreport_create_console_report
{
  my $component       = shift;
  my $repository_loc  = shift;
  my $summary_arr_ref = shift;
  my $node_name       = shift;
  my $data            = shift;
  # @summary_arr = command array for the given $component
  my @summary_arr     = @{$summary_arr_ref};

  return if ( $#summary_arr == -1 );
  my $component_console_ouput = catfile( $repository_loc, "report", $component, "${component}.txt" );
  my $component_hashstore_input;

  # tfasimplerep
  if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} ) {
    print "component               $component\n";
    print "repository_loc          $repository_loc\n";
    print "summary_arr array       @summary_arr\n";
    print "node_name               $node_name\n";
    print "data                    $data\n";
    print "component_console_ouput $component_console_ouput\n";
  } # end if tfasimplerep

  open( REPORT, ">$component_console_ouput" );

  foreach my $summary_option ( @{$summary_arr_ref} )
  {
    # tfasimplerep
    # exadata_cell_details/exadata_infiband_switches_details don't work, disable
    next if ( $summary_option =~ /exadata_cell_details/ || 
              $summary_option =~ /exadata_infiband_switches_details/ );
    print "calling ... tfactlstore_write_perl_data_json_to_asci_table ( , head, $data, $summary_option) \n" if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactlshare_summary"} );

    if ( defined $node_name and $node_name ne $hostname )
    {
      # tfasimplerep , generate ascii_table
      my $table = tfactlstore_write_perl_data_json_to_asci_table( "", "head", $data, $summary_option );
      $table = $table->draw(
                             [ ' ', ' ', ' ', ' ' ],
                             [ ' ', ' ', ' ' ],
                             [ '+', '+', '-', '+' ],
                             [ ' ', ' ', ' ' ],
                             [ '+', '+', '-', '+' ],
                             [ ' ', ' ', ' ', ' ' ]
      );
      print $table. "\n";
    } else
    {
      my $table;
      if ( defined $data )
      {
        $table = tfactlstore_write_perl_data_json_to_asci_table( "", "head", $data, $summary_option );
      } else
      {
        $component_hashstore_input = catfile( $repository_loc, "hashdata", $component, "${summary_option}.hash" );
        if ( -e $component_hashstore_input )
        {
          print REPORT "\n" . uc($summary_option) . ":\n" if ( $component eq 'overview' );
          my $hashref = tfactlstore_retrieve_json_to_hash($component_hashstore_input);
          $table = tfactlstore_write_perl_data_json_to_asci_table( "", "head", $hashref->{'DETAILS'}, $summary_option );
        }
      }
      $table = $table->draw(
                             [ ' ', ' ', ' ', ' ' ],
                             [ ' ', ' ', ' ' ],
                             [ '+', '+', '-', '+' ],
                             [ ' ', ' ', ' ' ],
                             [ '+', '+', '-', '+' ],
                             [ ' ', ' ', ' ', ' ' ]
      );
      print REPORT $table if ( !defined $node_name );
      print $table, "\n" if ( defined $node_name );
    }
  }
  close(REPORT);
}

sub sumreport_create_json_report
{
  my $component       = shift;
  my $repository_loc  = shift;
  my $summary_arr_ref = shift;
  my @summary_arr     = @{$summary_arr_ref};
  return if ( $#summary_arr == -1 );
  my @component_report;
  my $component_hashstore_input;
  my $hashref;
  my $component_json_ouput = catfile( $repository_loc, "report",   $component, "$component.json" );
  my $component_hash_ouput = catfile( $repository_loc, "hashdata", $component, "$component.hash" );

  foreach my $summary_option ( @{$summary_arr_ref} )
  {
    $component_hashstore_input = catfile( $repository_loc, "hashdata", $component, "$summary_option.hash" );
    $hashref = tfactlstore_retrieve_json_to_hash($component_hashstore_input);
    push( @component_report, $hashref );
  }
  my %component_report;
  $component_report{'COMPONENT'} = $component;
  $component_report{'DETAILS'}   = \@component_report;
  tfactlstore_store_hash_into_json( \%component_report, $component_json_ouput, $component_hash_ouput, "report" );
}

sub sumreport_create_html_report
{
  my $component       = shift;
  my $repository_loc  = shift;
  my $summary_arr_ref = shift;
  my $host            = shift;
  my $table_start_div;
  my $table_end_div;
  my $command_name;
  my $display_type;

  if ( defined $host )
  {
    my @command_array;
    foreach my $comp_details ( @{ $SUMMARY_REMOTE_DATA_REF->{$host}->{"DETAILS"} } )
    {
      if ( $comp_details->{"COMPONENT"} eq "$component" )
      {
        foreach my $command_table ( @{ $comp_details->{"DETAILS"} } )
        {
          my $summary_option = $command_table->{"COMMAND"};
          push( @command_array, $summary_option );
        }
      }
    }
    $summary_arr_ref = \@command_array;
    my @REPORT;
    my $tabs = prepare_html_component_command_header_tabs( $component, $host, $summary_arr_ref );
    push( @REPORT, "$comp_division_start_for_host  $tabs\n" );
    foreach my $summary_option ( @{$summary_arr_ref} )
    {
      $display_type = "inline-block";
      $command_name = join ' ', map ucfirst lc, split /[_]/, $summary_option;
      $table_start_div =
"<p style=\"postion: float;\"> <div id=\"${component}_${component}_${host}_${summary_option}\" style=\"display:${display_type}; \" align=\"left\"> <br> <h3><u> $command_name </u> </h3>";
      ( $status, $dep_hash_ref ) = get_dependent_remote_data( $host, $component, $summary_option );
      next if ( $status eq "false" );
      my $table =
        tfactlstore_write_perl_data_json_to_html_table( "", "head", $dep_hash_ref->{'DETAILS'}, $summary_option );
      $table         = $table . "</table>";
      $table_end_div = "<br> <br> </div> </p> ";
      push( @REPORT, "$table_start_div $table $table_end_div" );
    }
    push( @REPORT, "$comp_division_end_for_host\n" );
    return \@REPORT;
  }
  if ( $component eq "overview" )
  {
    my $component_html_ouput = catfile( $repository_loc, "report", $component, "${component}.html" );
    my $component_hashstore_input;
    open( REPORT, ">$component_html_ouput" );
    my $overview = "<div id='overview' style='display:block;'> \n";
    my $summary_overview =
"<div id='summary_overview' style='display:block'> \n  <h3 style='text-align:center'> <u> OVERVIEW</u> </h3> <br> <hr> <br>\n ";
    $summary_overview = $summary_overview . "<table class='labeltable' cellspacing='30px'> \n <tr> \n ";
    $component_hashstore_input = catfile( $repository_loc, "hashdata", $component, "summary_overview.hash" );
    my $hashref = tfactlstore_retrieve_json_to_hash($component_hashstore_input);
    my $count   = 0;
    my $all_component_overiew;

    foreach my $data ( @{ $hashref->{'DETAILS'} } )
    {
      my $component_name = lc( $data->{'COMPONENT'} );
      my $color          = "background-color:LightGreen;";
      $color = "background-color:tomato;" if ( $data->{'STATUS'} ne 'OK' );
      $color = "background-color:white;"  if ( $data->{'STATUS'} eq 'OFFLINE' );
      $summary_overview = $summary_overview
        . "<th style=\"$color\"> <a href=\"#\" onclick=\"showoverview('summary_overview',\'${component_name}_summary\');\">";
      $summary_overview = $summary_overview . uc($component_name) . "</a> </th>\n";
      $count++;
      $summary_overview = $summary_overview . "</tr>\n<tr>" if ( ( $count % 5 ) == 0 );
      my $component_overview = " <div id=\'${component_name}_summary\' style='display:none'>\n";
      $component_overview =
        $component_overview . "<h4 style='text-align:left'> <u> " . uc($component_name) . " OVERVIEW</u> </h4>\n";
      $component_overview = $component_overview . "<table class='labeltab'> <tr>";
      my %hash;
      my $sequence;

      foreach my $command ( keys %{ $SUMMARY_PROFILE_HASHREF->{"${component_name}overview"} } )
      {
        $sequence = $SUMMARY_PROFILE_HASHREF->{"${component_name}overview"}->{$command}->{'sequence'};
        $sequence =~ s/display_sequence=//;
        $hash{$command} = $sequence;
      }
      my @command_list = sort { $hash{$a} <=> $hash{$b} } keys %hash;
      my $all_comment_overview;
      my $display = "block";
      my $bgcolor = "white";
      foreach my $command (@command_list)
      {
        my $str = "@command_list";
        $str =~ s/ $command//g;
        $str =~ s/$command //g;
        $str =~ s/\s+/\',\'/g;
        $command_count++;
        $component_overview = $component_overview
          . "<th id=\"${component_name}_tabcolor\" style=\"background-color:$bgcolor;\" onclick=\"tabcolorChange(this,\'${component_name}_tabcolor\','lightgrey','white');\" > <a href=\"#\" onclick=\"showsuboverview(\'${component_name}_summary\',\'$command\',\'$str\');\"> $command </a> </th>\n";
        my $command_hashstore_input =
          catfile( $repository_loc, "hashdata", "${component_name}overview", "${command}.hash" );
        my $hashref = tfactlstore_retrieve_json_to_hash($command_hashstore_input);
        my $table = tfactlstore_write_perl_data_json_to_html_table( "", "head", $hashref->{'DETAILS'}, $command );
        $table = $table . "</table>";
        $table =~ s/width:100%;//;
        my $command_overview = "<div id=\"$command\" style=\'display:$display;\'> <br> <br> <br> $table </div> ";
        $all_comment_overview = $all_comment_overview . $command_overview;
        $display              = "none";
        $bgcolor              = "lightgrey";
      }
      $component_overview = $component_overview . "</tr> </table>\n";
      $component_overview = $component_overview
        . "<table align='right'> <tr> <td> <b> <a href=\"#\" onclick=\"showoverview(\'${component_name}_summary\','summary_overview');\">Back To Overview</a> </b> </td> </tr> </table> <br> <hr> <br>\n";
      $component_overview    = $component_overview . $all_comment_overview . "</div>\n";
      $all_component_overiew = $all_component_overiew . $component_overview;
    }
    $summary_overview = $summary_overview . "</tr>  </table> \n</div> \n";
    $overview         = $overview . " $summary_overview \n $all_component_overiew </div> \n";
    print REPORT "$overview\n";
    close(REPORT);
  } else
  {
    my $component_html_ouput = catfile( $repository_loc, "report", $component, "${component}.html" );
    my $component_hashstore_input;
    open( REPORT, ">$component_html_ouput" );
    my $tabs = prepare_html_component_command_header_tabs( $component, $hostname, $summary_arr_ref );
    print REPORT "$comp_division_start_for_host  $tabs\n";
    foreach my $summary_option ( @{$summary_arr_ref} )
    {
      if ( $component eq "overview" and $summary_option eq @{$summary_arr_ref}[0] )
      {
        $display_type = "inline-block";
      } else
      {
        $display_type = "inline-block";
      }
      $command_name = join ' ', map ucfirst lc, split /[_]/, $summary_option;
      $table_start_div =
"<p style=\"postion: float;\"> <div id=\"${component}_${component}_${hostname}_${summary_option}\" style=\"display:${display_type}; \" align=\"left\"> <br> <h3><u> $command_name </u> </h3>";
      $component_hashstore_input = catfile( $repository_loc, "hashdata", $component, "$summary_option.hash" );
      my $hashref = tfactlstore_retrieve_json_to_hash($component_hashstore_input);
      my $table = tfactlstore_write_perl_data_json_to_html_table( "", "head", $hashref->{'DETAILS'}, $summary_option );
      $table         = $table . "</table>";
      $table_end_div = "<br> <br> </div> </p> ";
      print REPORT "$table_start_div $table $table_end_div";
    }
    print REPORT "$comp_division_end_for_host\n";
    close(REPORT);
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
          $data   = $command_table;
        }
      }
    }
  }
  return ( $status, $data );
}

sub prepare_html_component_command_header_tabs
{
  my $component                    = shift;
  my $hostname                     = shift;
  my $divs_for_summary_options_ref = shift;
  @divs_for_summary_options = @{$divs_for_summary_options_ref};
  my $divs_for_summary_options_names = "\'${component}\',\'${component}_${hostname}\'";
  foreach my $name (@divs_for_summary_options)
  {
    $divs_for_summary_options_names =
      $divs_for_summary_options_names . ",\'${component}_${component}_${hostname}_$name\'";
  }
  my $nodeinfo = "<h3> <u> Cluster Node : ${hostname} </u> </h3>";
  $nodeinfo = '' if ( $component eq "overview" );
  my $commands_tabs = "$nodeinfo <br> <table align=\"left\" > <tr> \
       <td id=\"${component}commandtabcolor\" onclick=\"tabcolorChange(this,\'${component}commandtabcolor\','#D3E1ED','white');\" style=\"text-align: center; padding: 5px 5px 5px 5px; background-color: white; border-top-right-radius: 12px; border: 1px solid black;\"> \n\
       <div id=\"${component}_${hostname}_hide\" style=\"display:block;\"> <a href=\"#\" onclick=\"hidetables($divs_for_summary_options_names);\">Hide All Tables</a> </div> \n \
       <div id=\"${component}_${hostname}_show\" style=\"display:none;\"> <a href=\"#\" onclick=\"showtables($divs_for_summary_options_names);\">Show All Tables</a> </div> \n \
       </td> ";
  foreach my $summary_option_tab_name ( @{divs_for_summary_options} )
  {
    $commands_tabs = $commands_tabs
      . "<td id=\"${component}commandtabcolor\" onclick=\"tabcolorChange(this,\'${component}commandtabcolor\','#D3E1ED','white');\" style=\"text-align: center; padding: 5px 5px 5px 5px; background-color: #D3E1ED; border-top-right-radius: 12px; border: 1px solid black;\"> \n\
		       <a href=\"#\" onclick=\"hidetables($divs_for_summary_options_names);showCollectionSubList(\'${component}_${component}_${hostname}_${summary_option_tab_name}\');\">";
    $summary_option_tab_name = join ' ', map ucfirst lc, split /[_]/, $summary_option_tab_name;
    $commands_tabs = $commands_tabs . " ${summary_option_tab_name} </a> </td>\n";
  }
  $commands_tabs = $commands_tabs . "</tr> </table> <div> <br><br> <hr> <hr> </div>";
  return "$commands_tabs";
}

sub prepare_html_component_hosts_list
{
  my $component        = shift;
  my $hostname_arr_ref = shift;
  my $header =
" <br> <hr> <div id=\"${component}_hosts\" style=\"display:block;background-color: lightblue;\" align=\"right\"> \n \
<table width=\"100%\" align=\"right\"> <tr> <td style=\"text-align:right\"> \n \
Select Cluster Node : <select id=\"${component}_hostname\" onchange=\"showDiv(\'$component\',\'${component}_hostname\');\"> \n";
  my $selected;
  foreach my $host ( @{$hostname_arr_ref} )
  {
    if ( $host eq $hostname )
    {
      $selected = "selected";
    } else
    {
      $selected = '';
    }
    $header = $header . "<option value=\"${component}_${host}\" $selected> ${host} </option>\n";
  }
  $header = $header . "</select> \n </td> </tr> </table> <br> <br> <hr> </div> ";
  return $header;
}

sub sumreport_create_console_report_consolidated
{
  my $tfa_home            = shift;
  my $time                = shift;
  my $repository_loc      = shift;
  my $components_hash_ref = shift;
  $CONSOLEREPORT = "summary_report_${time}.txt";
  my $console_report = catfile( $repository_loc, "report", "$CONSOLEREPORT" );
  my $component_console_input;
  open( COMPLETE_REPORT, ">$console_report" );

  foreach my $component ( sort keys %{$components_hash_ref} )
  {
    next if ( $components_hash_ref->{$component} != 1 );
    $component_console_input = catfile( $repository_loc, "report", $component, "${component}.txt" );
    open( CON_REPORT, "<$component_console_input" );
    print COMPLETE_REPORT <CON_REPORT>;
    close(CON_REPORT);
  }
  close(COMPLETE_REPORT);
}

sub sumreport_create_json_report_consolidated
{
  my $tfa_home            = shift;
  my $time                = shift;
  my $repository_loc      = shift;
  my $components_hash_ref = shift;
  $JSONREPORT = "summary_report_${time}.json";
  $HASHREPORT = "summary_report_${time}.hash";
  my $json_report = catfile( $repository_loc, "report",   "$JSONREPORT" );
  my $hash_report = catfile( $repository_loc, "hashdata", "$HASHREPORT" );
  my @final_json;

  foreach my $component ( sort keys %{$components_hash_ref} )
  {
    next if ( $components_hash_ref->{$component} != 1 );
    my $component_hashstore_input = catfile( $repository_loc, "hashdata", $component, "${component}.hash" );
    if ( -e $component_hashstore_input )
    {
      my $hashref = tfactlstore_retrieve_json_to_hash("$component_hashstore_input");
      push( @final_json, $hashref );
    }
  }
  my %final_json;
  $final_json{'HOSTNAME'} = $hostname;
  $final_json{'DETAILS'}  = \@final_json;
  tfactlstore_store_hash_into_json( \%final_json, $json_report, $hash_report, "report" );
}

sub sumreport_create_html_report_consolidated
{
  my $tfa_home            = shift;
  my $time                = shift;
  my $repository_loc      = shift;
  my $components_hash_ref = shift;
  $HTMLREPORT = "summary_report_${time}.html";
  my $html_report = catfile( $repository_loc, "report", "$HTMLREPORT" );
  my $component_html_input;
  my @html_component_div;
  my $html_template = catfile( $tfa_home, "resources", "summary_html.tmpl" );
  open( HTML_TEMPLATE, "<$html_template" );
  my @html_template;
  while (<HTML_TEMPLATE>) { push( @html_template, $_ ); }
  close(HTML_TEMPLATE);
  my @hosts = ("$hostname");
  my $div_start;
  my $div_end;
  my $component_host_list;

  foreach my $component ( grep { exists $components_hash_ref->{$_} } @{$SUMMARY_COMPONENT_ORDER_REF} )
  {
    next if ( $components_hash_ref->{$component} != 1 );
    my $comp_division_start_for_host;
    my $comp_division_end_for_host;
    if ( $component ne "overview" )
    {
      $div_start =
          "<div id=\"${component}\" style=\"display:none;\"> \n <h2> <u> "
        . uc( ${component} )
        . " Status Summary</u> </h2> \n ";
      $component_host_list = prepare_html_component_hosts_list( $component, \@hosts );
      $div_end = "</div>";
      $comp_division_start_for_host =
        "<div class=\"$component\" id=\"${component}_${hostname}\" style=\"display:inline-block;\"> \n";
      $comp_division_end_for_host = " </div> <br> <br>";
    }
    $component_html_input = catfile( $repository_loc, "report", $component, "${component}.html" );
    open( HTML_REPORT, "<$component_html_input" );
    @html_component_div = <HTML_REPORT>;
    @html_component_div = (
                            $div_start, $component_host_list, $comp_division_start_for_host, @html_component_div,
                            $comp_division_end_for_host, $div_end
    );
    close(HTML_REPORT);
    open( COMPLETE_REPORT, ">$html_report" );
    foreach my $line (@html_template)
    {

      if ( $line =~ m/##component_left_menu_script##/ and $component ne "overview" )
      {
        $line = "\tdocument.getElementById(\"$component\").style.display=\'none\'\;\n $line";
      } elsif ( $line =~ m/##component_left_menu##/ and $component ne "overview" )
      {
        $line =
"\t<li id=\"overviewtabcolor\" onclick=\"tabcolorChange(this,\'overviewtabcolor\','#0c4266','#1d6290');\" ><a href=\"#\" onclick=\"showCollection(\'$component\');\">"
          . uc($component)
          . "</a></li> <hr>\n $line";
      } elsif ( $line =~ m/##division##/ )
      {
        $line = "@html_component_div \n $line";
      } elsif ( $line =~ m/##reprt_name##/ )
      {
        $line = "$HTMLREPORT";
      }
      print COMPLETE_REPORT $line;
    }
    close(COMPLETE_REPORT);
    undef @html_template;
    open( TEMPLATE, "<$html_report" );
    while (<TEMPLATE>) { push( @html_template, $_ ); }
    close(TEMPLATE);
  }
}

sub sumreport_display_summary_report
{
  my $report_type         = shift;
  my $repository_loc      = shift;
  my $display_table       = shift;
  my $components_hash_ref = shift;
  $display_table = "no" if ( $report_type eq "console" );
  my $report;
  $report = $CONSOLEREPORT if ( $report_type eq "console" );
  $report = $JSONREPORT    if ( $report_type eq "json" );
  $report = $HTMLREPORT    if ( $report_type eq "html" );

  if ( $display_table eq "yes" )
  {
    $report        = $CONSOLEREPORT;
    $display_table = "no";
  }
  $complete_report_location = catfile( $repository_loc, "report", $report );
  my $complete_report_location_relative = catfile( "<repository>", "report", $report );
  if ( $display_table eq "no" )
  {
    open( COMPLETE_REPORT, "<$complete_report_location" );
    print <COMPLETE_REPORT>, "\n";
    close(COMPLETE_REPORT);
  } else
  {
    my $tab = Text::ASCIITable->new();
    $tab->setCols( "Report Type", "Report Location" );
    $tab->setOptions( { "outputWidth" => $tputcols } );
    $tab->addRow( "Repository Location", $repository_loc );
    $tab->addRowLine();
    foreach my $component ( sort keys %{$components_hash_ref} )
    {
      next if ( $components_hash_ref->{$component} != 1 );
      my $reportdetails = uc($component) . " Summary Report";
      my $component_json_html_location = catfile( "<repository>", "report", $component, "${component}.${report_type}" );
      if ( $report_type eq "json" )
      {
        $tab->addRow( $reportdetails, $component_json_html_location );
        $tab->addRowLine();
      }
    }
    $tab->addRow( "Consolidated Report", $complete_report_location_relative );
    print $tab;
  }
}

sub sumreport_create_console_report_consolidated_forall_nodes
{
  my $tfa_home            = shift;
  my $time                = shift;
  my $repository_loc      = shift;
  my $components_hash_ref = shift;
  my $host_ref            = shift;
  $CONSOLEREPORT_CONSOLIDATE = "Consolidated_Summary_Report_${time}.txt";
  my $console_report = catfile( $repository_loc, $hostname, "report", "$CONSOLEREPORT_CONSOLIDATE" );
  open( COMPLETE_REPORT, ">$console_report" );
  my $component_console_input;

  foreach my $host ( sort @{$host_ref} )
  {
    next if ( $host ne $hostname );
    $component_console_input = catfile( $repository_loc, $host, "report", $CONSOLEREPORT );
    if ( -e $component_console_input and ( !-z $component_console_input ) )
    {
      if ( $host ne $hostname )
      {
        print COMPLETE_REPORT "Output From Host : $host\n";
        print COMPLETE_REPORT "--------------------------\n";
      }
      open( CON_REPORT, "<$component_console_input" );
      print COMPLETE_REPORT <CON_REPORT>;
      close(CON_REPORT);
    }
  }
  close(COMPLETE_REPORT);
}

sub sumreport_create_json_report_consolidated_forall_nodes
{
  my $tfa_home            = shift;
  my $time                = shift;
  my $repository_loc      = shift;
  my $components_hash_ref = shift;
  my $host_ref            = shift;
  $JSONREPORT_CONSOLIDATE = "Consolidated_Summary_Report_${time}.json";
  $HASHREPORT_CONSOLIDATE = "Consolidated_Summary_Report_${time}.hash";
  my $json_report = catfile( $repository_loc, $hostname, "report",   $JSONREPORT_CONSOLIDATE );
  my $hash_report = catfile( $repository_loc, $hostname, "hashdata", $HASHREPORT_CONSOLIDATE );

  #  open(COMPLETE_REPORT,">$json_report");
  #  print COMPLETE_REPORT "{\n";
  #  foreach my $host ( sort @{$host_ref} ) {
  #    my $host_hashstore_input = catfile($repository_loc,$host, "report", $JSONREPORT);
  #    if(-e $host_hashstore_input){
  #      open(CON_REPORT,"<$host_hashstore_input");
  #      print COMPLETE_REPORT "\"$host\":";
  #      print COMPLETE_REPORT <CON_REPORT>;
  #      close(CON_REPORT);
  #    }
  #  }
  #  print COMPLETE_REPORT "\}";
  #  close(COMPLETE_REPORT);
  my @final_json;
  foreach my $host ( sort @{$host_ref} )
  {
    my $host_hashstore_input = catfile( $repository_loc, $host, "hashdata", $HASHREPORT );
    if ( -e $host_hashstore_input )
    {
      my $hashref = tfactlstore_retrieve_json_to_hash("$host_hashstore_input");
      push( @final_json, $hashref );
    }
    if ( $host ne $hostname )
    {
      push( @final_json, $SUMMARY_REMOTE_DATA_REF->{$host} );
    }
  }
  my %final_json;
  $final_json{'REPORT'}  = 'TFA SUMMARY';
  $final_json{'DETAILS'} = \@final_json;
  tfactlstore_store_hash_into_json( \%final_json, $json_report, $hash_report, "report" );
}

sub sumreport_create_html_report_consolidated_forall_nodes
{
  my $tfa_home            = shift;
  my $time                = shift;
  my $repository_loc      = shift;
  my $components_hash_ref = shift;
  my $hosts_ref           = shift;
  $HTMLREPORT_CONSOLIDATE = "Consolidated_Summary_Report_${time}.html";
  my $html_report = catfile( $repository_loc, $hostname, "report", "$HTMLREPORT_CONSOLIDATE" );
  my $component_html_input;
  my @html_component_div;
  my $html_template = catfile( $tfa_home, "resources", "summary_html.tmpl" );
  open( HTML_TEMPLATE, "<$html_template" );
  my @html_template;
  while (<HTML_TEMPLATE>) { push( @html_template, $_ ); }
  close(HTML_TEMPLATE);
  my @hosts = @{$hosts_ref};
  my $div_start;
  my $div_end;
  my $component_host_list;

  foreach my $component ( grep { exists $components_hash_ref->{$_} } @{$SUMMARY_COMPONENT_ORDER_REF} )
  {
    next if ( $components_hash_ref->{$component} != 1 );
    my $comp_division_start_for_host;
    my $comp_division_end_for_host;
    if ( $component ne "overview" )
    {
      $div_start =
          "<div id=\"${component}\" style=\"display:none;\"> \n <h2> <u> "
        . uc( ${component} )
        . " Status Summary</u> </h2> \n ";
      $component_host_list        = prepare_html_component_hosts_list( $component, \@hosts );
      $div_end                    = "</div>";
      $comp_division_end_for_host = " <br> <br> </div>";
    }
    foreach $host (@hosts)
    {
      next if ( $component eq "overview" and $host ne $hostname );
      $comp_division_start_for_host =
        "<div class=\"$component\" id=\"${component}_${host}\" style=\"display:##blockupdate##;\"> \n";
      if ( $host eq $hostname )
      {
        $comp_division_start_for_host =~ s/##blockupdate##/inline-block/g;
      } else
      {
        $comp_division_start_for_host =~ s/##blockupdate##/none/g;
      }
      my @html_component_div_perhost;
      if ( $host ne $hostname )
      {
        @html_component_div_perhost = @{ sumreport_create_html_report( $component, $repository_loc, " ", $host ) };
      } else
      {
        $component_html_input = catfile( $repository_loc, $host, "report", $component, "${component}.html" );
        if ( -e $component_html_input )
        {
          open( HTML_REPORT, "<$component_html_input" );
          @html_component_div_perhost = <HTML_REPORT>;
        }
      }
      $comp_division_start_for_host = "" if ( $component eq "overview" );
      @html_component_div = ( @html_component_div, $comp_division_start_for_host, @html_component_div_perhost,
                              $comp_division_end_for_host );
    }
    @html_component_div = ( $div_start, $component_host_list, @html_component_div, $div_end );
    close(HTML_REPORT);
    open( COMPLETE_REPORT, ">$html_report" );
    foreach my $line (@html_template)
    {
      if ( $line =~ m/##component_left_menu_script##/ and $component ne "overview" )
      {
        $line = "\tdocument.getElementById(\"$component\").style.display=\'none\'\;\n $line";
      } elsif ( $line =~ m/##component_left_menu##/ and $component ne "overview" )
      {
        $line =
"\t<li id=\"overviewtabcolor\" onclick=\"tabcolorChange(this,\'overviewtabcolor\','#0c4266','#1d6290');\" ><a href=\"#\" onclick=\"showCollection(\'$component\');\">"
          . uc($component)
          . "</a></li> <hr>\n $line";
      } elsif ( $line =~ m/##division##/ )
      {
        $line = "@html_component_div \n $line";
        undef @html_component_div;
      } elsif ( $line =~ m/##reprt_name##/ )
      {
        $line = "$HTMLREPORT";
      }
      print COMPLETE_REPORT $line;
    }
    close(COMPLETE_REPORT);
    undef @html_template;
    open( TEMPLATE, "<$html_report" );
    while (<TEMPLATE>) { push( @html_template, $_ ); }
    close(TEMPLATE);
  }
}

sub sumreport_display_summary_report_consolidated_forall_nodes
{
  my $report_type         = shift;
  my $repository_loc      = shift;
  my $display_table       = shift;
  my $components_hash_ref = shift;
  my $hosts_ref           = shift;
  $display_table = "no" if ( $report_type eq "console" );
  my $local_report;
  $local_report = $CONSOLEREPORT if ( $report_type eq "console" );
  $local_report = $JSONREPORT    if ( $report_type eq "json" );
  $local_report = $HTMLREPORT    if ( $report_type eq "html" );
  my $report;
  if ( $report_type eq "console" ){
    $report = $CONSOLEREPORT_CONSOLIDATE;
    $report = "Consolidated_Summary_Report_${SUMMARY_TIME}.txt" if($report eq "");
  }
  $report = $JSONREPORT_CONSOLIDATE    if ( $report_type eq "json" );
  $report = $HTMLREPORT_CONSOLIDATE    if ( $report_type eq "html" );

  if ( $display_table eq "yes" )
  {
    $report        = $CONSOLEREPORT_CONSOLIDATE;
    $display_table = "no";
  }
  $complete_report_location = catfile( $repository_loc, $hostname, "report", $report );
  my $complete_report_location_relative = catfile( "<repository>", $hostname, "report", $report );
  if ( $display_table eq "no" )
  {
    open( COMPLETE_REPORT, "<$complete_report_location" );
    print <COMPLETE_REPORT>, "\n";
    close(COMPLETE_REPORT);
  } else
  {
    my $tab = Text::ASCIITable->new();
    $tab->setCols( "Report Host", "Report Location" );
    $tab->setOptions( { "outputWidth" => $tputcols } );
    $tab->addRow( "Repository Location", $repository_loc );
    $tab->addRowLine();
    foreach my $host ( sort @{$hosts_ref} )
    {
      my $reportdetails = $host;
      my $component_json_html_location = catfile( "<repository>", $host, "report", $local_report );
      $tab->addRow( $reportdetails, $component_json_html_location );
      $tab->addRowLine();
    }
    $tab->addRow( "Consolidated Report", $complete_report_location_relative );
    print $tab;
  }
}
1;
