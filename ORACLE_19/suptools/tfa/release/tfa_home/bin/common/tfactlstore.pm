#
# $Header: tfa/src/v2/tfa_home/bin/common/tfactlstore.pm /main/5 2017/10/08 22:29:06 bibsahoo Exp $
#
# tfactlstore.pm
#
# Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlstore.pm - Summary Collection Store Module 
#
#    DESCRIPTION
#      Formats collection data in to tables and store in to repository 
#      Prepare HTML,JSON tables
#      Simulate json report generation from hash using Dumper
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bibsahoo    09/19/17 - FIX BUG 26830648
#    bibsahoo    08/28/17 - FIX BUGS 26543201, 26089884, 26089871
#    cpujar      05/19/17 - XbranchMerge cpujar_bug-26090405 from
#                           st_tfa_12.2.1.1.01
#    cpujar      05/17/17 - Summary bug 26090405
#    cpujar      05/03/17 - XbranchMerge cpujar_bug-25971734 from main
#    cpujar      03/05/17 - Color Table Header Bug25971734 
#    bibsahoo    04/13/17 - Logging Updates
#    cpujar      01/10/17 - Creation
#
package tfactlstore;

BEGIN
{
  use Exporter();
  our ( @ISA, @EXPORT );
  @ISA = qw(Exporter);
  my @exp_func = qw(
    tfactlstore_retrieve_json_to_hash
    tfactlstore_store_hash_into_json
    tfactlstore_write_perl_data_to_html_table
    tfactlstore_write_perl_data_to_asci_table
    tfactlstore_write_perl_data_json_to_asci_table
    tfactlstore_write_perl_data_json_to_html_table
    tfactlstore_summary_log
  );
  push @EXPORT, @exp_func;
}

# use JSON;
use Text::ASCIITable;
use Data::Dumper;
use Storable;
use tfactlglobal;
use File::Spec::Functions;
use File::Basename;
###########
# NAME: tfactlstore_retrieve_json_to_hash
#
# DESCRIPTION
# Retrieve JSNO format input from file to perl hash
#
# Parameters
# -repository_loc json repository location
#
# Return perl hash reference
# #####################
#
sub tfactlstore_retrieve_json_to_hash
{
  my $hash_filename = shift;
  $hashref = retrieve("$hash_filename");
  return $hashref;
}
###########
# NAME: tfactlstore_store_hash_into_json
#
# DESCRIPTION
# Convert perl hash in to JSON format and store in repository
#
# Parameters
# -hashref Hash Reference
# -repository_loc json repository location
#
# #####################
#
sub tfactlstore_store_hash_into_json
{
  my $hashref             = shift;
  my $repository_loc      = shift;
  my $hash_repository_loc = shift;
  my $type                = shift;
  my %store;
  if ( $type ne "report" )
  {
    my $filename = basename( "$repository_loc", ".json" );
    $store{'COMMAND'} = $filename;
    $store{'DETAILS'} = $hashref;
    store \%store, "$hash_repository_loc";
  } else
  {
    store $hashref, "$hash_repository_loc";
  }
  $Data::Dumper::Pair   = " : ";
  $Data::Dumper::Useqq  = 1;
  $Data::Dumper::Indent = 1;
  $Data::Dumper::Terse  = 1;

  #$Data::Dumper::Purity = 1;
  $Data::Dumper::Deepcopy = 1;
  my $line;
  if ( $type ne "report" )
  {
    $line = Dumper \%store;
  } else
  {
    $line = Dumper $hashref;
  }
  $line =~ s/undef/\'\'/g;
  open( JSON, ">$repository_loc" );
  print JSON $line;
  close(JSON);
}
###########
# NAME: tfactlstore_write_perl_data_to_asci_table
#
# DESCRIPTION
# Convert any perl data structure in to ASCII table
#
# Parameters
# -any perl variable Reference
# -table header name
## #####################
#
sub tfactlstore_write_perl_data_to_asci_table
{
  my $argref         = shift;
  my $summary_option = shift;
  my $tab;
  my $type;
  my $arg_type = ref($argref);
  if ( defined $summary_option )
  {
    $summary_option =~ s/_/ /g;
    $summary_option = ucfirst($summary_option);
  }
  if ( $arg_type ne 'HASH' )
  {
    if ( defined $summary_option )
    {
      $tab = Text::ASCIITable->new( { headingText => $summary_option } );
      $tab->setOptions( { hide_HeadRow => 1 } );
    } else
    {
      $tab = Text::ASCIITable->new();
      $tab->setOptions( { hide_HeadLine => 1, hide_HeadRow => 1 } );
    }
    $tab->setCols("First column");
    $tab->setOptions( 'drawRowLine', 1 );
  } else
  {
    if ( defined $summary_option )
    {
      $tab = Text::ASCIITable->new( { headingText => $summary_option } );
      $tab->setOptions( { hide_HeadRow => 1 } );
    } else
    {
      $tab = Text::ASCIITable->new();
      $tab->setOptions( { hide_HeadLine => 1, hide_HeadRow => 1 } );
    }
    $tab->setCols( "First column", "Second column" );
    $tab->setOptions( 'drawRowLine', 1 );
    $tab->setOptions( { "outputWidth" => $tputcols } );
  }
  if ( $arg_type eq 'HASH' )
  {
    while ( my ( $key, $val ) = each %{$argref} )
    {
      $type = ref($val);
      if ( $type eq 'HASH' )
      {
        $val = tfactlstore_write_perl_data_to_asci_table($val);
      } elsif ( $type eq 'ARRAY' )
      {
        $val = tfactlstore_write_perl_data_to_asci_table($val);
      }
      $tab->addRow( $key, $val );
    }
  } elsif ( $arg_type eq 'ARRAY' )
  {
    foreach my $arr_val ( @{$argref} )
    {
      $type = ref($arr_val);
      if ( $type eq 'HASH' )
      {
        $arr_val = tfactlstore_write_perl_data_to_asci_table($arr_val);
      } elsif ( $type eq 'ARRAY' )
      {
        $arr_val = tfactlstore_write_perl_data_to_asci_table($arr_val);
      }
      $tab->addRow($arr_val);
    }
  } else
  {
    $tab->addRow($$argref);
  }
  return $tab;
}
###########
# NAME: tfactlstore_write_perl_data_to_html_table
#
# DESCRIPTION
# Convert any perl data structure in to HTML table
#
# Parameters
# -any perl variable Reference
# -table header name
## #####################
#
sub tfactlstore_write_perl_data_to_html_table
{
  my $argref         = shift;
  my $summary_option = shift;
  my $tab;
  my $type;
  my $arg_type = ref($argref);
  if ( defined $summary_option )
  {
    $summary_option =~ s/_/ /g;
    $summary_option = ucfirst($summary_option);
    $tab            = "\n <br> <table border=\"2\" style=\"table-layout:relative;\" align=\"left\">";
  } else
  {
    $tab = "\n <table border=\"1\" style=\"table-layout:relative; width:100%;\" >";
  }
  if ( $arg_type eq 'HASH' )
  {
    while ( my ( $key, $val ) = each %{$argref} )
    {
      $type = ref($val);
      my $subtab;
      if ( $type eq 'HASH' )
      {
        $subtab = $subtab . tfactlstore_write_perl_data_to_html_table($val);
      } elsif ( $type eq 'ARRAY' )
      {
        $subtab = $subtab . tfactlstore_write_perl_data_to_html_table($val);
      }
      $subtab = $val if ( !defined $subtab );
      $tab = $tab . "<tr> <td> $key </td> <td> $subtab </td> </tr>";
    }
  } elsif ( $arg_type eq 'ARRAY' )
  {
    foreach my $arr_val ( @{$argref} )
    {
      $type = ref($arr_val);
      if ( $type eq 'HASH' )
      {
        $tab = $tab . tfactlstore_write_perl_data_to_html_table($arr_val);
      } elsif ( $type eq 'ARRAY' )
      {
        $tab = $tab . tfactlstore_write_perl_data_to_html_table($arr_val);
      } else
      {
        $tab = $tab . "<tr> <td> $arr_val </td> </tr>";
      }
    }
  } else
  {
    $tab = $tab . "<tr> <td> $$argref </td> </tr>";
  }
  $tab = $tab . "</table>\n";
  return $tab;
}

sub tfactlstore_summary_log
{
  my $message  = shift;
  my $function = shift;
  my $loglevel = shift;
  my $time     = tfactlstore_get_time();
  my $message_type;
  if ( $loglevel == 1 )
  {
    $message_type = "ERROR";
  } elsif ( $loglevel == 2 )
  {
    $message_type = "WARNING";
  } else
  {
    $message_type = "INFO";
  }
  print $SUMMARY_LOG_FH "[$time][$message_type][$function]: $message\n";
}

sub tfactlstore_get_time
{
  my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
  $year += 1900;
  my $month = sprintf( "%02d", $mon + 1 );
  $hour = sprintf( "%02d", $hour );
  $min  = sprintf( "%02d", $min );
  $sec  = sprintf( "%02d", $sec );
  $mday = sprintf( "%02d", $mday );
  return "$year$month$mday$hour$min$sec";
}

sub tfactlstore_write_perl_data_json_to_html_table
{
  my $tab            = shift;
  my $head           = shift;
  my $argref         = shift;
  my $summary_option = shift;
  my $key_order_ref  = shift;
  my @key_order = @{$key_order_ref};
  my $type;
  my $arg_type = ref($argref);
  if ( defined $summary_option )
  {
    $summary_option =~ s/_/ /g;
    $summary_option = ucfirst($summary_option);
  }
  if ( $arg_type eq 'HASH' )
  {
    if ( $head eq "head" )
    {
      my @keys = keys %{$argref};
      @key_order = @keys;
      $head = "data";
      $tab  = "\n <br> <table border=\"2\" style=\"table-layout:relative;\" align=\"left\">";
      my $size = $#keys + 1;
      $tab = $tab . "<tr><th colspan=\"$size\"> $summary_option </th></tr>\n";
      $tab = $tab . "<tr>";
      foreach my $key (@keys) { $tab = $tab . "<th> $key </th>"; }
      $tab = $tab . "</tr>\n";
    }
    my @values = values %{$argref};
    my @table_values;
    foreach my $key (@key_order)
    {
      my $val = ${$argref}{$key};
      $type = ref($val);
      if ( $type eq 'HASH' )
      {
        $val = tfactlstore_write_perl_data_json_to_html_table( $tab, "head", $val );
        $val = $val . "</table>";
      } elsif ( $type eq 'ARRAY' )
      {
        $val = tfactlstore_write_perl_data_json_to_html_table( $tab, "head", $val );
        $val = $val . "</table>";
      }
      push( @table_values, $val );
    }
    $tab = $tab . "<tr>";
    foreach my $key (@table_values) { $tab = $tab . "<td> $key </td>"; }
    $tab = $tab . "</tr>";
  } elsif ( $arg_type eq 'ARRAY' )
  {
    my $count = 1;
    my @table_values;
    my $normal_table;
    foreach my $arr_val ( @{$argref} )
    {
      $type = ref($arr_val);
      if ( $type eq 'HASH' )
      {
        if ( $count == 1 )
        {
          my @keys = keys %{$arr_val};
          @key_order = @keys;
          $head = "data";
          $tab  = "\n <table border=\"1\" style=\"table-layout:relative; width:100%;\" >";
         # $tab  = $tab . "<tr>";
          $tab  = $tab . "<tr style=\"background-color:lightblue;\">";
          foreach my $key (@keys) { $tab = $tab . "<th> $key </th>"; }
          $tab = $tab . "</tr>\n";
        }
        $tab = tfactlstore_write_perl_data_json_to_html_table( $tab, $head, $arr_val, "", \@key_order );
      } elsif ( $type eq 'ARRAY' )
      {
        $tab = tfactlstore_write_perl_data_json_to_html_table( $tab, $head, $arr_val );
      } else
      {
        push( @table_values, $arr_val );
      }
      $count++;
    }
    if ( $#table_values != -1 )
    {
      $tab = "\n <table border=\"1\" style=\"table-layout:relative; width:100%;\" >";
      foreach my $key (@table_values) { $tab = $tab . "<tr><td> $key </td></tr>"; }
    }
  }
  return $tab;
}

sub tfactlstore_write_perl_data_json_to_asci_table
{
  my $tab            = shift;
  my $head           = shift;
  my $argref         = shift;
  my $summary_option = shift;
  my $key_order_ref  = shift;
  my @key_order = @{$key_order_ref};
  my $type;
  my $arg_type = ref($argref);
  if ( defined $summary_option )
  {
    $summary_option =~ s/_/ /g;
    $summary_option = ucfirst($summary_option);
  }
  if ( $arg_type eq 'HASH' )
  {
    if ( $head eq "head" )
    {
      $tab = Text::ASCIITable->new( { headingText => $summary_option } );
      my @keys = keys %{$argref};
      @key_order = @keys;
      $tab->setCols(@keys);
      $head = "data";
    }
    my @values = values %{$argref};
    my @table_values;
    foreach my $key (@key_order)
    {
      my $val = ${$argref}{$key};
      $type = ref($val);
      if ( $type eq 'HASH' )
      {
        $val = tfactlstore_write_perl_data_json_to_asci_table( $tab, "head", $val );

        #$tab->setOptions('drawRowLine',1);
      } elsif ( $type eq 'ARRAY' )
      {
        $val = tfactlstore_write_perl_data_json_to_asci_table( $tab, "head", $val );
      }
      push( @table_values, $val );
    }
    $tab->addRow(@table_values);
  } elsif ( $arg_type eq 'ARRAY' )
  {
    my $count = 1;
    my @table_values;
    my $normal_table;
    foreach my $arr_val ( @{$argref} )
    {
      $type = ref($arr_val);
      if ( $type eq 'HASH' )
      {
        if ( $count == 1 )
        {
          $tab = Text::ASCIITable->new();
          my @keys = keys %{$arr_val};
          @key_order = @keys;
          $tab->setCols(@keys);
          $head = "data";
        }
        $arr_val = tfactlstore_write_perl_data_json_to_asci_table( $tab, $head, $arr_val, "", \@key_order );

        #$tab->setOptions('drawRowLine',1);
      } elsif ( $type eq 'ARRAY' )
      {
        $arr_val = tfactlstore_write_perl_data_json_to_asci_table( $tab, $head, $arr_val );
      } else
      {
        push( @table_values, $arr_val );
      }
      $count++;
    }
    if ( $#table_values != -1 )
    {
      $tab = Text::ASCIITable->new();
      $tab->setOptions( { hide_HeadLine => 1, hide_HeadRow => 1 } );
      $tab->setCols("Table");
      foreach my $key (@table_values)
      {
        $tab->addRow($key);
      }
    }
  }
  return $tab;
}
1;
