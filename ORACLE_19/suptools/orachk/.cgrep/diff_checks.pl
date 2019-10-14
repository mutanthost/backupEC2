# 
# $Header: tfa/src/orachk/src/diff_checks.pl /main/17 2018/04/24 23:45:27 rojuyal Exp $
#
# diff_collections.pl
# 
# Copyright (c) 2013, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      diff_collections.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    apriyada    09/27/15 - Remove class
#    rkchaura    09/02/15 - added class attribute in html report
#    apriyada    08/31/15 - Fix diff parsing
#    rkchaura    08/15/15 - changes to html report to easily iterate over the
#                           checks
#    rkchaura    07/31/15 - updated to create diff report with absolute path
#    apriyada    02/22/15 - Change report to new format
#    apriyada    08/12/14 - Diff collection enhancement
#    gadiga      02/04/13 - diff two exachk reports
#    gadiga      02/04/13 - Creation
# 
# Author: Andrego Halim
# Purpose: This script compares the result of two exachk run to analyze the changes between them
# use strict;
# use warnings;

use Data::Dumper;
my $version="1.0";

# Initializing variables to be used

# $ref and $new are the arguments supplied by the user
my $diffcoll = $ARGV[0];
my $path = $ARGV[1];
my $ref = $ARGV[2];
my $new = $ARGV[3];
#my $machinetype = $ARGV[2];
my $output_file = $ARGV[4];
my $ignore_profile_cmp = $ARGV[5] || 0;

my $machinetype = "";

my $same_cluster = 1;
my $append_html = "";

# $refhtml and $newhtml are formed from the user-supplied arguments(if they aren't in html format yet)
my ($refhtml, $newhtml);

###### Sanity checking on the parameters given into the perl script ######
if ( ! $ref || ! $new )
{
  print "Usage : diffc.pl <exachk_output_folder_1> <exachk_output_folder_2>\n";
  exit;
}

if ( $ref =~ /\.html/ )
{
    $refhtml = "$ref";
}
else
{
    if(-e "$ref/outfiles/check_env.out")
    {
      $MASTERFIL1="$ref/outfiles/check_env.out";
    }
    else
    {
      $MASTERFIL1="$ref/outfiles/raccheck_env.out";
    }

    if ( `grep -iwc "IT_IS_RAC = 1" $MASTERFIL1` > 0 )
    {
            $diffcoll=1;
    }
    else
    {
            $diffcoll=-1;
    }
  $baseref = `basename $ref`;chomp($baseref);
  $refhtml = "$ref/$baseref.html";
}

if ( $new =~ /\.html/ )
{
  $newhtml = "$new";
}
else
{
  $basenew = `basename $new`;chomp($basenew);
  $newhtml = "$new/$basenew.html";
}

if ( `grep -iwc "Oracle RAC Assessment Report" $newhtml` > 0 && `grep -iwc "Oracle RAC Assessment Report" $refhtml` > 0 )
{
        $isitrac=1;
}
else
{
        $isitrac=0;
}

if ( ! -r $refhtml || ! -r $newhtml )
{
  print "Can't read files. Please check $refhtml & $newhtml exist and are readable\n";
  exit;
}

my ($refhtml_color, $newhtml_color);
my ($ref_basename, $new_basename);
if ( $refhtml =~ /([^\/]+)\.html/ ) {
  #$refhtml_color = "<span style=\"color:green\">$1</span>";
  $refhtml_color = "$1";
  $ref_basename = $1;
}
if ( $newhtml =~ /([^\/]+)\.html/ ) {
  $newhtml_color = "$1";
  $new_basename = $1;
}
my @d = split(/_/, $ref_basename);
my @dn= split(/_/, $new_basename);
my $program_name = $d[0];
my $program_name_initcap = ucfirst($program_name);

if ( ! $output_file )
{
  $output_file = "$path/${program_name}_$d[-2]$d[-1]_$dn[-2]$dn[-1]_diff.html";
}
else
 {
 $firstchar = substr($output_file, 0,1);
# if relative path is given then following code updates the value of output_file otherwise keeps the output_file as it is
	if ($firstchar ne '/')
	{
	  $output_file = "$path/$output_file";
	}	
 }

###### End of sanity checking ######

# Declare %dh to be a hash table containing data from the first html
my %dh = ();

# list of check_id of all known checks
my %checkid_list = ();

# Summary table details

my %summary = ();

#### Process the first html file that will be compared to and extract the data from it into a hash table %dh
open(RF, $refhtml);
while(<RF>)
{
  my $temp_key;
  chomp;
  $line = $_;

  # Check if the line has info about the details of the pass/error message and its location. If it does, then parse the info
  if ( $line =~  /deletebutton.*deleteRow.*summary/)
  {
    %dh=parse_line("1",%dh);
  }
  # Check if the line has info about the name of the check
  #if ( $line =~ /^<a href="#([\w\d]+)_summary.*/ )
  #{
  #  $temp_key = $1;
  #  chomp;
  #  $line = <RF>;
  #  if ($line =~ /^<h3>(.*)<\/h3>/)
  #  {
  #    $checkid_list{$temp_key}->{NAME}=$1;
  #  }
  #}

  if ( $line =~ /^<a name="([\w\d]+)_details"><\/a>/ )
  {
    $temp_key = $1;
    chomp;
    $line = <RF>;
    if ($line =~ /^<h3 align="center" style="background:#F2F5F7">(.*)<\/h3>/)
    {
      $checkid_list{$temp_key}->{NAME}=$1;
    }
    elsif ($line =~ /^<h3 style="background:#F2F5F7">(.*)<\/h3>/)
    {
        $checkid_list{$temp_key}->{NAME}=$1;
    }
    else
    {
	$line = <RF>;
	if ($line =~ /^<h3>(.*)<\/h3>/)
	{
		$checkid_list{$temp_key}->{NAME}=$1;
	}
    }
  }
   elsif ( ! $machinetype && $line =~ /<title>Oracle (.*) Report<\/title>/ )
  {
    my $words = $1;
    $words =~ s/Upgrade Readiness//;
    $words =~ s/Assessment//;
    $machinetype = $words;
    $machinetype .= " Rack" if ( $machinetype =~ /Exalogic/ );

  }
   elsif ( ! $summary{"OLD-CDATE"} && $line =~ /Collection Date<\/td><td>(.*)<\/td>/ )
  {
    #$summary{"OLD-CDATE"} = $1;
    my $val = $1;
    if ( $val =~ m/\d+\-[a-zA-Z]+\-\d+ \d+:\d+:\d+$/) {
      $summary{"OLD-CDATE"} = $val;
    }
  }
   elsif ( ! $summary{"OLD-VERSION"} && $line =~ /k Version<\/td><td>(.*)<\/td>/ )
  {
    $summary{"OLD-VERSION"} = $1;
    $version1 = $1;
    @v = split(/_/,$version1);
    $version1 = $v[0];
    $version1 =~ s/\(.*\)//;$version1 =~ s/\.//g;
    if ( not ( $version1 =~ m/^12/ ) )
    {
      $version1 = "$version1"."000";
    }
  }
   elsif ( ! $summary{"OLD-CLUSTER"} && $line =~ /Cluster Name<\/td><td>([^<]+)</ )
  {
    $summary{"OLD-CLUSTER"} = lc($1);
  }
   elsif ( ! $summary{"OLD-SHS"} && $line =~ /(System Health Score is [0-9]* out of [0-9]*)/ )
  {
    $summary{"OLD-SHS"} = lc($1);
  }
   elsif ( ! $summary{"OLD-USER"} && $line =~ /Executed by<\/td><td>([^<]+)</ )
  {
    $summary{"OLD-USER"} = lc($1);
  }
   elsif ( ! $summary{"OLD-PROFILE"} && $line =~ /Selected Profiles<\/td><td>([^<]+)</ )
  {
    $summary{"OLD-PROFILE"} = lc($1);
  }
   elsif ( ! $summary{"OLD-EXPROFILE"} && $line =~ /Excluded Profiles<\/td><td>([^<]+)</ )
  {
    $summary{"OLD-EXPROFILE"} = lc($1);
  }
}
close(RF);

# Declare %new_dh to be hash table containing new checks within second html that didn't exist in first html
my %new_dh = ();

### Process the second html file that will be compared to and compare it to the data from the first html as it progresses
open(RF, $newhtml);
while(<RF>)
{
  chomp;
  $line = $_;
  if ( $line =~ /deletebutton.*deleteRow.*summary/) 
  {
    %new_dh=parse_line("2",%new_dh);
  }
  # Check if the line has info about the name of the check
  #if ( $line =~ /^<a href="#([\w\d]+)_summary.*/ )
  #{
  #  $temp_key = $1;
  #  chomp;
  #  $line = <RF>;
  #  if ($line =~ /^<h3>(.*)<\/h3>/)
  #  {
  #    $checkid_list{$temp_key}->{NAME}=$1;
  #  }
  #}
 
  if ( $line =~ /^<a name="([\w\d]+)_details"><\/a>/ )
  {
    $temp_key = $1;
    chomp;
    $line = <RF>;
    if ($line =~ /^<h3 align="center" style="background:#F2F5F7">(.*)<\/h3>/)
    {
      $checkid_list{$temp_key}->{NAME}=$1;
    }
    elsif ($line =~ /^<h3 style="background:#F2F5F7">(.*)<\/h3>/)
    {
	$checkid_list{$temp_key}->{NAME}=$1;
    }
    else
    {
        $line = <RF>;
        if ($line =~ /^<h3>(.*)<\/h3>/)
        {
                $checkid_list{$temp_key}->{NAME}=$1;
        }
    }
  }
   elsif ( ! $summary{"NEW-CDATE"} && $line =~ /Collection Date<\/td><td>(.*)<\/td>/ )
  {
    #$summary{"NEW-CDATE"} = $1;
    my $val = $1;
    if ( $val =~ m/\d+\-[a-zA-Z]+\-\d+ \d+:\d+:\d+$/) {
      $summary{"NEW-CDATE"} = $val;
    }
  }
   elsif ( ! $summary{"NEW-VERSION"} && $line =~ /k Version<\/td><td>(.*)<\/td>/ )
  {
    $summary{"NEW-VERSION"} = $1;
    $version2 = $1;
    @v = split(/_/,$version2);
    $version2 = $v[0];
    $version2 =~ s/\(.*\)//; $version2 =~ s/\.//g;
    if ( not ( $version2 =~ m/^12/ ) )
    {
      $version2 = "$version2"."000";
    }
  }
   elsif ( ! $summary{"NEW-CLUSTER"} && $line =~ /Cluster Name<\/td><td>([^<]+)</ )
  {
    $summary{"NEW-CLUSTER"} = lc($1);
    $summary{"NEW-CLUSTER"} =~ s/^ *//g;
    $summary{"NEW-CLUSTER"} =~ s/ *$//g;
    $summary{"OLD-CLUSTER"} =~ s/^ *//g;
    $summary{"OLD-CLUSTER"} =~ s/ *$//g;
    if ( $summary{"NEW-CLUSTER"} ne $summary{"OLD-CLUSTER"} )
    {
      $same_cluster = 0;
    }
  }
   elsif ( ! $summary{"NEW-SHS"} && $line =~ /(System Health Score is [0-9]* out of [0-9]*)/ )
  {
    $summary{"NEW-SHS"} = lc($1);
  }
   elsif ( ! $summary{"NEW-USER"} && $line =~ /Executed by<\/td><td>([^<]+)</ )
  {
    $summary{"NEW-USER"} = lc($1);
  }
   elsif ( ! $summary{"NEW-PROFILE"} && $line =~ /Selected Profiles<\/td><td>([^<]+)</ )
  {
    $summary{"NEW-PROFILE"} = lc($1);
  }
   elsif ( ! $summary{"NEW-EXPROFILE"} && $line =~ /Excluded Profiles<\/td><td>([^<]+)</ )
  {
    $summary{"NEW-EXPROFILE"} = lc($1);
  }
}
close(RF);

if ($same_cluster == 0 && $ignore_profile_cmp == 0) {
  print 'cluster';
  exit 2;
}

# Validationn
if ($ignore_profile_cmp == 0)  {
  if ((defined $summary{"OLD-PROFILE"} && ! defined $summary{"NEW-PROFILE"}) || (! defined $summary{"OLD-PROFILE"} && defined $summary{"NEW-PROFILE"})) {
    print 'profile';
    exit 2;   
  } elsif ((defined $summary{"OLD-EXPROFILE"} && ! defined $summary{"NEW-EXPROFILE"}) || (! defined $summary{"OLD-EXPROFILE"} && defined $summary{"NEW-EXPROFILE"})) {
    print 'profile';
    exit 2;	 
  } 
  if (defined defined $summary{"OLD-PROFILE"} && defined $summary{"NEW-PROFILE"}) {
    my (%old_profiles) = map{$_ => 1}split(',',$summary{"OLD-PROFILE"});
    my (%new_profiles) = map{$_ => 1}split(',',$summary{"NEW-PROFILE"});
    for(keys %old_profiles) { if (!exists($new_profiles{$_})) { print 'profile'; exit 2; }}
  }
  if (defined defined $summary{"OLD-EXPROFILE"} && defined $summary{"NEW-EXPROFILE"}) {
    my (%old_exprofiles) = map{$_ => 1}split(',',$summary{"OLD-EXPROFILE"});
    my (%new_exprofiles) = map{$_ => 1}split(',',$summary{"NEW-EXPROFILE"});
    for(keys %old_exprofiles) { if (!exists($new_exprofiles{$_})) { print 'profile'; exit 2; }}
  }
}

# Perform the data comparison from the two reports
foreach $check (keys %checkid_list)
{ 
  $checkid_list{$check}->{STATUS} = compare($check);
}


dump_html();

#-- end of main

sub sorted_list
{
  my $line = $_[0];
  $line =~ s/, /,/g;
  return join(', ', sort split(/,/, $line));

}

# Auxiliary function called to parse each line within the html report containing a check. The parsed results are stored in $status, $type, $msg, $on, $key
# $status : WARNING, FAIL, INFO, PASS
# $type : OS Check, Switch Check, etc
# $msg : Success Message if it's a PASS, Failure Message otherwise
# $on : The nodes where the check pass/fail
# $key : <$check_id>_<$status> (Status is needed as a key since a check may show up in both PASS and non-PASS if the check doesn't pass in all intended nodes)
sub parse_line()
{
  my $key;
  my $in = 0;
  my ($iter, %hash)=@_;
  if ( $line =~ /this,\W(\w+)_contents\'.*/)
  {
    $key = $1;
  }
  $checkid_list{$key}->{NAME}="";
  $pline = $line;
  $pline =~ s/.*_summary......//;
  $pline =~ s/.*\<b\>//;
  $pline =~ s/\<\/b\>\<\/font\>//;

  if($iter == 1)
  {
	if ($version1 < 121025)
	{
		if ( $pline =~ /(\w+)\<\/td..td\>([\w\s]+)\<\/td..td scope=\"row\"\>(.*)\<\/td..td\>[\<a.*\>]*([^\<]+)[\<\/a\>]*\<\/td..td\>.*\<\/td.\<\/tr/ )
		{
			$in = 1;
		    $status = $1;
		    $type = $2;
		    if ( $status eq "PASS" )
		    {
		      $pass_msg = $3;
		      $pass_on = $4;
		      if ( $pass_on =~ /.*title\=\"(.*)\".*/ )
		      {
        		 $pass_on = $1;
		      }
			$pass_on =~ s/All Infiniband Switches/All InfiniBand Switches/;
		    }
		    else
		    {
		      $error_label = $status;
		      $error_msg = $3;
		      $error_on = $4;
		      if ( $error_on =~ /.*title\=\"(.*)\".*/ )
		      {
        		 $error_on = $1;
		      }
			$error_on =~ s/All Infiniband Switches/All InfiniBand Switches/;
	    	    }
			
		}
		else
		{
			$in = 0;
		}
	}
	else
	{
		if ( $pline =~ /(\w+)\<\/td..td class=\"check-name\"\>([\w\s]+)\<\/td..td class=\"check-message\" scope=\"row\"\>(.*)\<\/td..td class=\"check-status-on\"\>[\<a.*\>]*([^\<]+)[\<\/a\>]*\<\/td..td class=\"check-view-link\"\>.*\<\/td.\<\/tr/ )
                {
                        $in = 1;
		    $status = $1;
                    if ( $status eq "CRITICAL" )
                    {
                         $status = "FAIL"
                    }  
                    $type = $2;
                    if ( $status eq "PASS" )
                    {
                      $pass_msg = $3;
                      $pass_on = $4;
                      if ( $pass_on =~ /.*title\=\"(.*)\".*/ )
                      {
                         $pass_on = $1;
                      }
			$pass_on =~ s/All Infiniband Switches/All InfiniBand Switches/;
                    }
                    else
                    {
                      $error_label = $status;
                      $error_msg = $3;
                      $error_on = $4;
                      if ( $error_on =~ /.*title\=\"(.*)\".*/ )
                      {
                         $error_on = $1;
                      }
			$error_on =~ s/All Infiniband Switches/All InfiniBand Switches/;
                    }
                        
                }
                else
                {
                        $in = 0;
                }
		
	}
  }
  else
  {
	if ($version2 < 121025)
        {
                if ( $pline =~ /(\w+)\<\/td..td\>([\w\s]+)\<\/td..td scope=\"row\"\>(.*)\<\/td..td\>[\<a.*\>]*([^\<]+)[\<\/a\>]*\<\/td..td\>.*\<\/td.\<\/tr/ )
                {
                        $in = 1;
		    $status = $1;
                    $type = $2;
                    if ( $status eq "PASS" )
                    {
                      $pass_msg = $3;
                      $pass_on = $4;
                      if ( $pass_on =~ /.*title\=\"(.*)\".*/ )
                      {
                         $pass_on = $1;
                      }
			$pass_on =~ s/All Infiniband Switches/All InfiniBand Switches/;
                    }
                    else
                    {
                      $error_label = $status;
                      $error_msg = $3;
                      $error_on = $4;
                      if ( $error_on =~ /.*title\=\"(.*)\".*/ )
                      {
                         $error_on = $1;
                      }
			$error_on =~ s/All Infiniband Switches/All InfiniBand Switches/;
                    }
                        
                }
                else
                {
                        $in = 0;
                }
        }
        else
        {
                if ( $pline =~ /(\w+)\<\/td..td class=\"check-name\"\>([\w\s]+)\<\/td..td class=\"check-message\" scope=\"row\"\>(.*)\<\/td..td class=\"check-status-on\"\>[\<a.*\>]*([^\<]+)[\<\/a\>]*\<\/td..td class=\"check-view-link\"\>.*\<\/td.\<\/tr/ )          
                {
                        $in = 1;
		    $status = $1;
                    if ( $status eq "CRITICAL" )
                    {
                         $status = "FAIL"
                    }
                    $type = $2;
                    if ( $status eq "PASS" )
                    {
                      $pass_msg = $3;
                      $pass_on = $4;
                      if ( $pass_on =~ /.*title\=\"(.*)\".*/ )
                      {
                         $pass_on = $1;
                      }
			$pass_on =~ s/All Infiniband Switches/All InfiniBand Switches/;
                    }
                    else
                    {
                      $error_label = $status;
                      $error_msg = $3;
                      $error_on = $4;
                      if ( $error_on =~ /.*title\=\"(.*)\".*/ )
                      {
                         $error_on = $1;
                      }
			$error_on =~ s/All Infiniband Switches/All InfiniBand Switches/;
                    }
      
                }
                else
                {
                        $in = 0;
                }

        }
  }

#  if ( $pline =~ /(\w+)\<\/td..td\>([\w\s]+)\<\/td..td scope=\"row\"\>(.*)\<\/td..td\>[\<a.*\>]*([^\<]+)[\<\/a\>]*\<\/td..td\>.*\<\/td.\<\/tr/ )
#  if ( $pline =~ /(\w+)\<\/td..td class=\"check-name\"\>([\w\s]+)\<\/td..td class=\"check-message\" scope=\"row\"\>(.*)\<\/td..td class=\"check-status-on\"\>[\<a.*\>]*([^\<]+)[\<\/a\>]*\<\/td..td class=\"check-view-link\"\>.*\<\/td.\<\/tr/ )
#
 # if($in == 1)
 # {
 #   $status = $1;
 #   $type = $2;
    
 #   if ( $status eq "PASS" ) 
 #   {
 #     $pass_msg = $3;
 #     $pass_on = $4;
 #     if ( $pass_on =~ /.*title\=\"(.*)\".*/ )
 #     {
 #        $pass_on = $1;
 #     }
 #   }
 #   else 
 #   {
 #     $error_label = $status;
 #     $error_msg = $3;
 #     $error_on = $4;
 #     if ( $error_on =~ /.*title\=\"(.*)\".*/ )
 #     {
 #        $error_on = $1;
 #     }
 #   }
 # }
 
  $hash{$key}->{TYPE} = "$type";
  if ( $status eq "PASS" )
  {
    $hash{$key}->{PASS_MSG} = "$pass_msg";
    $hash{$key}->{PASS_ON} = sorted_list("$pass_on");
    $hash{$key}->{PASS_LINE} = "$line";
  }
  else
  {
    $hash{$key}->{ERROR_LABEL} = "$error_label";
    $hash{$key}->{ERROR_MSG} = "$error_msg";
    $hash{$key}->{ERROR_ON} = sorted_list("$error_on");
    $hash{$key}->{ERROR_LINE} = "$line";
  }
  $pass_msg = "";
  $pass_on = "";
  $error_label = "";
  $error_msg = "";
  $error_on = "";
  
  return %hash;
}

# Auxiliary function called by the parser of the second html report that will perform the comparison
sub compare
{
  my $check_id = shift;
  my $ret;
  # First, verify if the check id exists in the first html report
  if ( exists $dh{$check_id} )
  {
    # Check if the check id also exists in the second html report
    if ( exists $new_dh{$check_id} )
    {
      # If the check exists in both report, check if it pass and/or fail at the same nodes
      if ( ("$dh{$check_id}->{PASS_ON}" eq "$new_dh{$check_id}->{PASS_ON}" ) && ("$dh{$check_id}->{ERROR_ON}" eq "$new_dh{$check_id}->{ERROR_ON}" ) && ("$dh{$check_id}->{ERROR_LABEL}" eq "$new_dh{$check_id}->{ERROR_LABEL}" ) )
      { # Everything is same
        $ret = "same";
      }
       elsif ( $same_cluster == 0 && ("$dh{$check_id}->{ERROR_LABEL}" eq "$new_dh{$check_id}->{ERROR_LABEL}" ) )
      { # If results are from different clusters, ignore the host names
        if ( ( $dh{$check_id}->{PASS_ON} && ! $new_dh{$check_id}->{PASS_ON} ) ||
             ( ! $dh{$check_id}->{PASS_ON} && $new_dh{$check_id}->{PASS_ON} ) ||
             ( $dh{$check_id}->{ERROR_ON} && ! $new_dh{$check_id}->{ERROR_ON} ) ||
             ( ! $dh{$check_id}->{ERROR_ON} && $new_dh{$check_id}->{ERROR_ON} )
           )
        {
          $ret = "diff";
        }
         else
        {
          $ret = "same";
        }
      }
      else
      {
        $ret = "diff";
      }
    }
    else 
    {
      # if the check id doesn't exist in the second html report, tag it as "missing"
      $ret = "missing";
    }
  }
  else
  {
    # If key doesn't exist (meaning that it's a new check showing up in the 2nd html that didn't exist in the 1st html)
    $ret = "new";
  }
}

# Prints the comparison report from the processed data
sub dump_html
{
  $total = scalar(keys(%checkid_list));
  $missing = 0;
  $changed = 0;
  $new = 0;
  $same = 0;
  open(WF, ">$output_file") || die "Can't open $output_file\n";

  # Initialize the header for the comparison html report
  print WF <<EOF
<html lang="en"><head>
<style type="text/css">
body {font-family: Lucida Grande,Lucida Sans,Arial,sans-serif;
    font-size: 14px;
    background:white;
}
h1 {color:black; text-align: center}
h2 {color:black; background:white; font-family: Arial; font-size: 24px}
h3 {color:black; background:white}
a {color: #000000;}
p {font-family: Lucida Grande,Lucida Sans,Arial,sans-serif;
    font-size: 14px;
}
.a_bgw {
  color: #000000;
  background:white;
}

table {
    color: #000000;
    font-weight: bold;
    border-spacing: 0;
    outline: medium none;
    font-family: Lucida Grande,Lucida Sans,Arial,sans-serif;
    font-size: 14px;
}

th {
 background: #F2F5F7;
    border: 1px solid grey;
    font-size: 14px;
    font-weight: bold;
}

th.checktype {
    width: 5%;
}
th.checkname {
    width: 15%;
}
th.status_halved {
    width: 40%;
}
th.status_halved_status{
    width: 5%;
}
td {
 background: #F2F5F7;
    border: 1px solid grey;
    font-weight: normal;
    padding: 5;
}

.status_FAIL
{
    font-weight: bold;
    color: #c70303;
}
.status_WARNING
{
    font-weight: bold;
    color: #b05c1c;
}
.status_INFO
{
    font-weight: bold;
    color: blue;
}
.status_PASS
{
    font-weight: bold;
    color: #006600;
}

.td_output {
    color: #000000;
    background: white;
    border: 1px solid grey;
    font-family: Lucida Grande,Lucida Sans,Arial,sans-serif;
    font-size: 14px;
    font-weight: normal;
    padding: 1;
}

.td_column {
 background: #F2F5F7;
    border: 1px solid grey;
    font-size: 14px;
    font-weight: bold;
}

.td_column_second {
 background: #F2F5F7;
    border: 1px solid grey;
    font-size: 11px;
    font-weight: bold;
}

td_report {
 background: #F2F5F7;
    border: 1px solid #AED0EA;
    font-weight: normal;
    padding: 5;
}

.td_report2 {
 background: #F2F5F7;
    border: 1px solid grey;
    font-size: 13px;
}

.td_report1 {
 background: #F2F5F7;
    border: 1px solid grey;
    font-size: 13px;
}   

.td_title {

 background: #F2F5F7;
    border: 0px solid grey;
    font-weight: normal;
    padding: 5;
}

.h3_class {
    font-family: Lucida Grande,Lucida Sans,Arial,sans-serif;
    font-size: 15px;
    font-weight: bold;
    color: black;
    padding: 15;
}

.tips {
    display: none;
    position: absolute;
    border: 3px solid #AED0EA;;
    padding:5;
    background-color: #D7EBF9;
    width: 200px;
    font-family: Lucida Grande,Lucida Sans,Arial,sans-serif;
    font-size: 13px;
    font-weight: normal;
}

pre {
 overflow-x: auto; /* Use horizontal scroller if needed; for Firefox 2, not needed in Firefox 3 */
 white-space: pre-wrap; /* css-3 */
 white-space: -moz-pre-wrap !important; /* Mozilla, since 1999 */
 white-space: -pre-wrap; /* Opera 4-6 */
 white-space: -o-pre-wrap; /* Opera 7 */
 /* width: 99%; */
 word-wrap: break-word; /* Internet Explorer 5.5+ */
}

.shs_bar {
width: 500px ;
height: 20px ;
float: left ;
border: 1px solid #444444;
background-color: white ;
}

.shs_barfill {
height: 20px ;
float: left ;
background-color: #FF9933 ;
width: 94% ;
}

div {
background-color: #f1f1f1;
width: 500px;
height: 500px ;
color: black;
border: 1px solid #AED0EA;
display: none;
}

divcus {
color: black;
}


</style>

<script type = "text/javascript">

var report_format = "new";
function processForm()
{
    
    if (report_format == "old")
    {
        report_format = "new";
        var i;
        var bo = document.querySelectorAll("body");
        for (i = 0; i < bo.length; i++) 
        {
                bo[i].style.fontSize = "14px";
        }
        var hc1 = document.querySelectorAll("h1");
        for (i = 0; i < hc1.length; i++) 
        {
                hc1[i].style.color = "black";
        }
        var hc2 = document.querySelectorAll("h2");
        for (i = 0; i < hc2.length; i++) 
        {
                hc2[i].style.color = "black";
        }
	var hc3 = document.querySelectorAll("h3");
        for (i = 0; i < hc3.length; i++) 
        {
                hc3[i].style.color = "black";
        }
	var hc3 = document.querySelectorAll("h3_class");
        for (i = 0; i < hc3.length; i++)
        {
                hc3[i].style.color = "black";
        }
        var pf = document.querySelectorAll("p");
        for (i = 0; i < pf.length; i++) 
        {
                pf[i].style.fontSize = "14px";
        }
        var tf = document.querySelectorAll("table");
        for (i = 0; i < tf.length; i++) 
        {
                tf[i].style.fontSize = "14px";
        }
        var th = document.querySelectorAll("th");
        for (i = 0; i < th.length; i++) 
        {
                th[i].style.background = "#F2F5F7";
                th[i].style.border = "1px solid grey";
                th[i].style.fontSize = "14px";
        }
        var td = document.querySelectorAll("td");
	for (i = 0; i < td.length; i++) 
        {
                td[i].style.border = "1px solid grey";
        }
        var tdo = document.querySelectorAll(".td_output");
        for (i = 0; i < tdo.length; i++) 
        {
                tdo[i].style.background = "white";
                tdo[i].style.border = "1px solid grey";
                tdo[i].style.fontSize = "14px";
        }
        var tdc = document.querySelectorAll(".td_column");
        for (i = 0; i < tdc.length; i++) 
        {
                tdc[i].style.background = "#F2F5F7";
                tdc[i].style.border = "1px solid grey";
                tdc[i].style.fontSize = "14px";
        }
	var tdc = document.querySelectorAll(".td_column_second");
        for (i = 0; i < tdc.length; i++)
        {
                tdc[i].style.background = "#F2F5F7";
                tdc[i].style.border = "1px solid grey";
        }
	var tdc = document.querySelectorAll(".td_report1");
        for (i = 0; i < tdc.length; i++)
        {
                tdc[i].style.background = "#F2F5F7";
		tdc[i].style.border = "1px solid grey";
        }
	var tdc = document.querySelectorAll(".td_report2");
        for (i = 0; i < tdc.length; i++)
        {
                tdc[i].style.background = "#F2F5F7";
		tdc[i].style.border = "1px solid grey";
        }
        var tdt = document.querySelectorAll(".td_title");
        for (i = 0; i < tdt.length; i++) 
        {
                tdt[i].style.border = "0px solid grey";
        }
        var shs = document.querySelectorAll(".shs_bar");
        for (i = 0; i < shs.length; i++) 
	{
                shs[i].style.background = "white";
        }
        document.getElementById('results').innerHTML ="Switch to old format";

    }
    else
    {
        report_format = "old";
        var i;
        var bo = document.querySelectorAll("body");
        for (i = 0; i < bo.length; i++) 
        {
                bo[i].style.fontSize = "13px";
        }
        var hc1 = document.querySelectorAll("h1");
        for (i = 0; i < hc1.length; i++) 
        {
                hc1[i].style.color = "blue";
        }
        var hc2 = document.querySelectorAll("h2");
        for (i = 0; i < hc2.length; i++) 
        {
                hc2[i].style.color = "blue";
        }
        var hc3 = document.querySelectorAll("h3");
        for (i = 0; i < hc3.length; i++) 
        {
                hc3[i].style.color = "blue";
        }
	var hc3 = document.querySelectorAll("h3_class");
        for (i = 0; i < hc3.length; i++)
        {
                hc3[i].style.color = "blue";
        }
        var pf = document.querySelectorAll("p");
        for (i = 0; i < pf.length; i++) 
        {
                pf[i].style.fontSize = "13px";
        }
        var tf = document.querySelectorAll("table");
        for (i = 0; i < tf.length; i++) 
        {
                tf[i].style.fontSize = "12px";
        }
        var th = document.querySelectorAll("th");
        for (i = 0; i < th.length; i++) 
        {
                th[i].style.background = "#D7EBF9";
                th[i].style.border = "1px solid #AED0EA";
                th[i].style.fontSize = "13px";
        }
        var td = document.querySelectorAll("td");
        for (i = 0; i < td.length; i++) 
        {
                td[i].style.border = "1px solid #AED0EA";
        }
        var tdo = document.querySelectorAll(".td_output");
        for (i = 0; i < tdo.length; i++) 
        {
                tdo[i].style.background = "#E0E0E0";
                tdo[i].style.border = "1px solid #AED0EA";
                tdo[i].style.fontSize = "13px";
        }
        var tdc = document.querySelectorAll(".td_column");
        for (i = 0; i < tdc.length; i++) 
        {
                tdc[i].style.background = "#D7EBF9";
                tdc[i].style.border = "1px solid #AED0EA";
                tdc[i].style.fontSize = "13px";
        }
	var tdc = document.querySelectorAll(".td_column_second");
        for (i = 0; i < tdc.length; i++)
        {
                tdc[i].style.background = "#D7EBF9";
                tdc[i].style.border = "1px solid #AED0EA";
        }
	var tdc = document.querySelectorAll(".td_report1");
        for (i = 0; i < tdc.length; i++)
        {
                tdc[i].style.background = "#F2F5EE";
		tdc[i].style.border = "1px solid #AED0EA";
        }
        var tdc = document.querySelectorAll(".td_report2");
        for (i = 0; i < tdc.length; i++)
        {
                tdc[i].style.background = "#F2EDEF";
		tdc[i].style.border = "1px solid #AED0EA";
        }
        var tdt = document.querySelectorAll(".td_title");
        for (i = 0; i < tdt.length; i++) 
        {
                tdt[i].style.border = "0px solid #AED0EA";
        }
        var shs = document.querySelectorAll(".shs_bar");
        for (i = 0; i < shs.length; i++) 
        {
                shs[i].style.background = "#656565";
        }
        document.getElementById('results').innerHTML ="Switch to new format";
    }
}

function show_help(tipdiv, e ) 
{
  var x = 0;
  var y = 0;
  if ( document.all ) 
  {
    x = event.clientX;
    y = event.clientY;
  } 
   else 
  {
    x = e.pageX;
    y = e.pageY;
  }

  var element = document.getElementById(tipdiv);
  element.style.display = "block";
  element.style.left = x + 12;
  element.style.top = y + 10;
}

function setVisibility(id, visibility) 
{
	document.getElementById(id).style.display = visibility;
}

var showMode = 'table-cell';
if (document.all) showMode='block';

function toggleVis_all(btn , callid, paramiter)
{
     for(x = 0; x <= paramiter; x++) 
     {	
	var elem = btn+x;
	cells = document.getElementsByName(elem);
	if(callid == 'expand')
	{
        	mode=showMode;
	}
	else
	{
		mode='none';
	}
	for(j = 0; j < cells.length; j++) cells[j].style.display = mode;
    }
}

var showMode = 'table-cell';
if (document.all) showMode='block';
function toggleVis(btn , callid)
{
  cells = document.getElementsByName(btn);
  if(cells[0].style.display == 'none')
  {
        mode=showMode;
  }
  else
  {
        mode='none';
  }

  for(j = 0; j < cells.length; j++) cells[j].style.display = mode;

  if(callid == 'hide_check_link')
  {
        document.getElementById('hide_check_link').style.display='none';
        document.getElementById('show_check_link').style.display="";
  }
  else
  {
        document.getElementById('show_check_link').style.display='none';
        document.getElementById('hide_check_link').style.display="";
  }
  if(callid == 'check_name_hide')
  {
        document.getElementById('check_name_hide').style.display='none';
        document.getElementById('check_name_show').style.display="";
  }
  else
  {
        document.getElementById('check_name_show').style.display='none';
        document.getElementById('check_name_hide').style.display="";
  }
}

function hide_help(tipdiv) 
{
  document.getElementById(tipdiv).style.display = "none";
}
</script>

<title>${program_name_initcap} Baseline Comparison Report</title>
</head><body>

<center><table summary="Comparison Report" border=0 width=100%><tr><td class="td_title" align="center"><h1>${machinetype} Health Check Baseline Comparison Report<br><br></td></tr></table></center>
EOF
;

if (  $diffcoll == 0 )
{
	if($isitrac == 1)
	{
        	print "\n\nCollections were not diffed because only html reports were compared \n\n";
	        print WF <<EOF
        	<b><font color="red">Collections were not diffed because only html reports were compared</b></font>
EOF
;
	}
}

print WF <<EOF
<h2>Table of Contents</h2>
<ul>
  <li><a class="a_bgw" href="#changed">Differences between Report 1 and Report 2</a></li>
  <li><a class="a_bgw" href="#missing">Unique findings in Report 1</a></li>
  <li><a class="a_bgw" href="#new">Unique findings in Report 2</a></li>
  <li><a class="a_bgw" href="#same">Common Findings in Both Reports</a></li>
EOF
;

if (  $diffcoll == 1 )
{
print WF <<EOF
  <li><a class="a_bgw" href="#collection">Health Check Collection Comparison summary</a></li>
EOF
;
}

print WF <<EOF
</ul>
<br>
<a href="javascript:toggleVis('checkid', 'show_check_link');" id="show_check_link">Show Check Ids</a>
<a href="javascript:toggleVis('checkid', 'hide_check_link');" style="DISPLAY: none" id="hide_check_link">Hide Check Ids</a>
<hr><br/>
EOF
;
###################################################################################
  # Create a section for checks changed from the 1st to 2nd html report
  print WF <<EOF
<a name="changed"></a>
<table summary="Differences between Report 1 and Report 2" border=1 id="changedtbl">
  <tr>
    <td colspan="7" align="center" scope="row"><span class="h3_class">Differences between Report 1 ($refhtml_color) and Report 2 ($newhtml_color)</span><br/><br/></td>
  </tr>
  <tr>         
      <th scope="col" class="checkid" rowspan="2" name='checkid' style="DISPLAY: none">Check Id</th>
      <th scope="col" class="checktype" rowspan="2">Type</th>
      <th scope="col" class="checkname" rowspan="2">Check Name</th>
      <th scope="col" class="status_halved" colspan="2">Status On Report 1</th>
      <th scope="col" class="status_halved" colspan="2" border-left-style="solid" border-left-width="20">Status On Report 2</th>
  </tr>
  <tr>
     <th scope="col" class="status_halved_status">Status</th>
     <th scope="col">Status On</th>
     <th scope="col" class="status_halved_status">Status</th>
     <th scope="col">Status On</th>
  </tr>
EOF
;
  foreach $key (keys %checkid_list)
  {
    if ( $checkid_list{$key}->{STATUS} eq "diff" )
    {
      $changed++;
      if ( (! ($dh{$key}->{PASS_ON} ) || (! $dh{$key}->{ERROR_ON} )) && ((!$new_dh{$key}->{PASS_ON}) || (! $new_dh{$key}->{ERROR_ON})))
      {
        $rowspan1 = 1;
      } 
      else 
      {
        $rowspan1 = 2;
      }
      if ( $dh{$key}->{PASS_ON} && $dh{$key}->{ERROR_ON} ) 
      {
        $rowspan2=1;
      }
      else {
        $rowspan2=2;
      }
      if ( $new_dh{$key}->{PASS_ON} && $new_dh{$key}->{ERROR_ON} ) 
      {
        $rowspan3=1;
      }
      else {
        $rowspan3=2;
      }
      if ( ($rowspan2 eq 2) && ($rowspan3 eq 2) ){
        $rowspan2 = 1;
        $rowspan3 = 1;
      }
      print WF "<tr class=\"check-result\" rowspan=$rowspan1>\n";
      print WF "<td class=\"check-id\" rowspan=$rowspan1 name='checkid' style='DISPLAY: none'>$key</td>\n";
      print WF "<td class=\"check-name\" rowspan=$rowspan1>$dh{$key}->{TYPE}</td>\n";
      print WF "<td class=\"check-message\" scope=\"row\" rowspan=$rowspan1>$checkid_list{$key}->{NAME}</td>\n";
      $ret_extra_row1=print_node_status("td_report1", "WF", \%dh, $key, $rowspan2);
      $ret_extra_row2=print_node_status("td_report2", "WF", \%new_dh, $key, $rowspan3);
      if ( $ret_extra_row1 || $ret_extra_row2 ) 
      {
        print WF "<tr>\n$ret_extra_row1\n$ret_extra_row2</tr>\n";
      }
      print WF "</tr>\n";
    }
  }
  print WF "</table>\n";
  print WF "<a class=\"a_bgw\" href=\"#\">Top</a>\n";
  print WF "<hr><br/>\n";

  ###################################################################################
  # Create a section for checks that are missing in the 2nd html report
  print WF <<EOF
<a name="missing"></a>
<table summary="Unique findings in Report 1" border=1 id="missingtbl_1">
  <tr>
    <td colspan="5" align="center" scope="row"><span class="h3_class">Unique findings in Report 1 ($refhtml_color)<br/><br/></span></td>
  </tr>
  <tr>         
      <th scope="col" rowspan="2" name='checkid' style="DISPLAY: none">Check Id</th>
      <th scope="col" rowspan="2">Type</th>
      <th scope="col" rowspan="2">Check Name</th>
      <th scope="col" colspan="2">Status On Report 1</th>
  </tr>
  <tr>
     <th scope="col">Status</th>
     <th scope="col">Status On</th>
  </tr>
EOF
;
  foreach $key (keys %checkid_list)
  {
    $append_html = "";
    if ( $checkid_list{$key}->{STATUS} eq "missing" )
    {
      $missing++;

      if ( $dh{$key}->{PASS_ON} && $dh{$key}->{ERROR_ON} )
      {
        $rowspan1=2;
      }
      else {
        $rowspan1=1;
      }
      print WF "<tr rowspan=$rowspan1 class=\"check-result\">\n";
      print WF "<td rowspan=$rowspan1 class=\"check-id\" name='checkid' style='DISPLAY: none'>$key</td>\n";
      print WF "<td rowspan=$rowspan1 class=\"check-name\">$dh{$key}->{TYPE}</td>\n";
      print WF "<td  rowspan=$rowspan1 class=\"check-message\" scope=\"row\">$checkid_list{$key}->{NAME}</td>\n";
      $ret_extra_row1=print_node_status("td_report", "WF", \%dh, $key);
      print WF "</tr>\n";
  
      #if ( $append_html ) 
      #{
	#print WF $append_html;
      #}
      if ( $ret_extra_row1  )
      {
        print WF "<tr>\n$ret_extra_row1</tr>\n";
      }
    }
  }
  $append_html = "";

  print WF "</table>\n";
  print WF "<a class=\"a_bgw\" href=\"#\">Top</a>\n";
  print WF "<hr><br/>\n";

  ####################################################################################
  # Create a section for checks that are new in the 2nd html report, and doesn't show up in the 1st one
  ####################################################################################
  print WF <<EOF
<a name="new"></a>
<table summary="Unique findings in Report 2" border=1 id="missingtbl_2">
  <tr>
    <td colspan="5" align="center" scope="row"><span class="h3_class">Unique findings in Report 2 ($newhtml_color)<br/><br/></span></td>
  </tr>

  <tr>         
      <th scope="col" rowspan="2" name='checkid' style="DISPLAY: none">Check Id</th>
      <th scope="col" rowspan="2">Type</th>
      <th scope="col" rowspan="2">Check Name</th>
      <th scope="col" colspan="2">Status On Report 2</th>
  </tr>
  <tr>
     <th scope="col">Status</th>
     <th scope="col">Status On</th>
  </tr>
EOF
;
  foreach $key (keys %checkid_list)
  {
    $append_html = "";
    if ( $checkid_list{$key}->{STATUS} eq "new" )
    {
      $new++;
      if ( $new_dh{$key}->{PASS_ON} && $new_dh{$key}->{ERROR_ON} )
      {
        $rowspan1=2;
      }
      else {
        $rowspan1=1;
      }
      print WF "<tr rowspan=$rowspan1 class=\"check-result\">\n";
      print WF "<td rowspan=$rowspan1 class=\"check-id\" name='checkid' style='DISPLAY: none'>$key</td>\n";
      print WF "<td rowspan=$rowspan1 class=\"check-name\">$new_dh{$key}->{TYPE}</td>\n";
      print WF "<td rowspan=$rowspan1 class=\"check-message\" scope=\"row\">$checkid_list{$key}->{NAME}</td>\n";
      $ret_extra_row1=print_node_status("td_report", "WF", \%new_dh, $key);
      print WF "</tr>\n";
	if ( $ret_extra_row1  )
      {
        print WF "<tr>\n$ret_extra_row1</tr>\n";
      }
    }
  }
  $append_html = "";

  print WF "</table>\n";
  print WF "<a class=\"a_bgw\" href=\"#\">Top</a>\n";
  print WF "<hr><br/>\n";

  ####################################################################################
  # Create a section for checks that didn't change between the 1st html report to the 2nd one
  ####################################################################################
  print WF <<EOF
<a name="same"></a>
<table summary="Common Findings in Both Reports" border=1 id="sametbl">
  <tr>
    <td colspan="5" align="center" scope="row"><span class="h3_class">Common Findings in Both Reports<br/><br/></span></td>
  </tr>
  <tr>         
      <th scope="col" rowspan="2" name='checkid' style="DISPLAY: none">Check Id</th>
      <th scope="col" rowspan="2">Type</th>
      <th scope="col" rowspan="2">Check Name</th>
      <th scope="col" colspan="2">Status On Both Report</th>
  </tr>
  <tr>
     <th scope="col">Status</th>
     <th scope="col">Status On</th>
  </tr>
EOF
;
  foreach $key (keys %checkid_list)
  {
    $append_html = "";
    if ( $checkid_list{$key}->{STATUS} eq "same" )
    {
      $same++;
      print WF "<tr class=\"check-result\">\n";
      print WF "<td class=\"check-id\" name='checkid' style='DISPLAY: none'>$key</td>\n";
      print WF "<td class=\"check-name\">$new_dh{$key}->{TYPE}</td>\n";
      print WF "<td class=\"check-message\" scope=\"row\">$checkid_list{$key}->{NAME}</td>\n";
      print_node_status("td_report", "WF", \%new_dh, $key);
      print WF "</tr>\n";
    }
  }
  $append_html = "";

  print WF "</table>\n";
  print WF "<a class=\"a_bgw\" href=\"#\">Top</a>\n";
  if (  $diffcoll == 0 )
  {
  	print WF "</body><br><a class=\"a_bgw\" href=\"#\" onclick=\"javascript:processForm();\"><divcus id=\"results\">Switch to old format</divcus></a></html>";
  }
  close(WF);
  
  # Done processing the comparison report
  ####################################################################################

  # Prepare summary table to be displayed at the top of the html report
  print "Summary \n";
  print "Total   : $total\n";
  print "Missing : $missing\n";
  print "New     : $new\n";
  print "Changed : $changed\n";
  print "Same    : $same\n";
  my $row1 = "";
  my $row2 = "";
  if ( $same_cluster == 0 )
  {
    $row1 = "<tr><td class=\"td_column_second\">&nbsp;&nbsp;&nbsp;Cluster Name</td><td>".$summary{"OLD-CLUSTER"}."</td></tr>";
    $row2 = "<tr><td class=\"td_column_second\">&nbsp;&nbsp;&nbsp;Cluster Name</td><td>".$summary{"NEW-CLUSTER"}."</td></tr>";
  }
  rename $output_file, "$output_file.orig";
  open FILE, ">", $output_file;
  open ORIG, "<",  "$output_file.orig";
  while (<ORIG>) {
    print FILE <<EOF
      <H2>$machinetype Health Check Baseline Comparison summary</H2>
      <table id="summarytbl"  border=1 summary="Comparison Summary" role="presentation">
      <tr><td class="td_column">Report 1</td><td>$refhtml_color</td></tr>$row1
      <tr><td class="td_column_second">&nbsp;&nbsp;&nbsp;Collection Date</td><td>$summary{"OLD-CDATE"}</td></tr>
      <tr><td class="td_column_second">&nbsp;&nbsp;&nbsp;${program_name} Version</td><td>$summary{"OLD-VERSION"}</td></tr>
      <tr><td class="td_column_second">&nbsp;&nbsp;&nbsp;System Health Score</td><td>$summary{"OLD-SHS"}</td></tr>
      <tr><td class="td_column_second">&nbsp;&nbsp;&nbsp;Executed by</td><td>$summary{"OLD-USER"}</td></tr>
      <tr><td class="td_column">Report 2</td><td>$newhtml_color</td></tr>$row2
      <tr><td class="td_column_second">&nbsp;&nbsp;&nbsp;Collection Date</td><td>$summary{"NEW-CDATE"}</td></tr>
      <tr><td class="td_column_second">&nbsp;&nbsp;&nbsp;${program_name} Version</td><td>$summary{"NEW-VERSION"}</td></tr>
      <tr><td class="td_column_second">&nbsp;&nbsp;&nbsp;System Health Score</td><td>$summary{"NEW-SHS"}</td></tr>
      <tr><td class="td_column_second">&nbsp;&nbsp;&nbsp;Executed by</td><td>$summary{"NEW-USER"}</td></tr>
      <tr id="summary_total_checks"><td class="td_column">Total Checks Reported</td><td>$total</td></tr>
      <tr><td class="td_column">Differences between<br/>Report 1 and Report 2</td><td>$changed</td></tr>
      <tr id="summary_unique_1"><td class="td_column">Unique findings<br/>in Report 1</td><td>$missing</td></tr>
      <tr id="summary_unique_2"><td class="td_column">Unique findings<br/>in Report 2</td><td>$new</td></tr>
      <tr id="summary_common"><td class="td_column">Common Findings<br/>in Both Reports</td><td>$same</td></tr>
      </table>

<div id="totaldiv" class="tips" style="z-index:1000;display:none">Total number of checks reported</div>
<div id="changeddiv" class="tips" style="z-index:1000;display:none">Number of checks changed between Report 1 and Report 2</div>
<div id="missingdiv" class="tips" style="z-index:1000;display:none">Number of checks missing in Report 2 </div>
<div id="newdiv" class="tips" style="z-index:1000;display:none">Number of checks new in Report 2</div>
<div id="samediv" class="tips" style="z-index:1000;display:none">Number of checks without any change</div>
EOF
    if /<h2>Table of Contents<\/h2>/; print FILE $_;
  }
  close ORIG;
  close FILE;
  unlink "$output_file.orig";
  #use Cwd qw();
  #my $path = Cwd::cwd();
  #print "File comparison is complete. The comparison report can be viewed in: $path/$output_file\n"
  print "Check comparison is complete. The comparison report can be viewed in: $output_file\n"
}

# This function prepares the detail for a specified check from a specified report
sub print_node_status()
{
  my $tdclass = @_[0];
  my $classval = "check-status-on";
  my $classres = "check-result";
  if ( $tdclass eq "td_report1" )
  {
	$classval = "check-status-on-1";	
	$classres = "check-result-1";
  }
  if ( $tdclass eq "td_report2" )
  {
	$classval = "check-status-on-2";
	$classres = "check-result-2";
  }
  my $out = @_[1];
  my %hash = %{$_[2]};
  my $check_id = $_[3];
  my $return_next_row;
  my $rowspan = $_[4];
  if ( $hash{$check_id}->{PASS_ON} )
  {
    print $out "<td class=\"$classres\" rowspan=$rowspan scope=\"row\">";
    print $out "PASS</td>\n<td class=\"$classval\" rowspan=$rowspan>$hash{$check_id}->{PASS_ON}</td>\n";
    if ( $hash{$check_id}->{ERROR_ON} ) 
    {
      $append_html  = "<tr>\n";
      $append_html .= "<td></td>\n";
      $append_html .= "<td scope=\"row\"></td>\n";
      $append_html .= "<td class=\"$classres\" scope=\"row\">$hash{$check_id}->{ERROR_LABEL}</td>\n";
      $append_html .= "<td class=\"$classval\">$hash{$check_id}->{ERROR_ON}</td></tr>\n";

      $return_next_row="<td class=\"$classres\" scope=\"row\">$hash{$check_id}->{ERROR_LABEL}</td>\n<td class=\"$classval\">$hash{$check_id}->{ERROR_ON}</td>\n";
    }
  }
  else  
  {
    print $out "<td class=\"$classres\" rowspan=$rowspan scope=\"row\">$hash{$check_id}->{ERROR_LABEL}</td>\n<td class=\"$classval\" rowspan=$rowspan>$hash{$check_id}->{ERROR_ON}</td>\n";
  }
  return $return_next_row;
}
