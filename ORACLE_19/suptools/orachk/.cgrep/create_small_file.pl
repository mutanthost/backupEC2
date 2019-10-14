# 
# $Header: tfa/src/orachk/src/create_small_file.pl /main/9 2017/08/11 17:38:18 rojuyal Exp $
#
# create_small_file.pl
# 
# Copyright (c) 2015, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      create_small_file.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    rojuyal     08/26/15 - Mofications for IDMHC and IDMHC_COLLECT
#    gadiga      04/12/15 - create xml COLLECTIONS
#    gadiga      04/12/15 - Creation
# 
use strict;
use warnings;
use Data::Dumper;

my ($CHECK_TYPE)	= $ARGV[0] || "";
my ($COLLECTIONS) 	= $ARGV[1];
my ($MANIFEST_XML)	= $ARGV[2] || "FMW_Checks.xml" ;
my ($COMPONENTS)	= $ARGV[3];
my ($FMW_RUN_COMPS)	= $ARGV[4]; 
my ($FMW_COMPS_RUNNING)	= $ARGV[5]; 
my ($EXCLUDEFIL)	= $ARGV[6] || "";
my ($FMW_EXCLUDE_COMPS)	= $ARGV[7]; 
my ($CHECK_TYPE_CNT)	= 0;
my ($PDEBUG)            = $ENV{RAT_PDEBUG}||0;

if ( ! $COLLECTIONS )
{
  print "Usage : $0 <collections.dat>\n";
  exit;
}

if ( ! -r "$COLLECTIONS" )
{
  print "Failed to read $COLLECTIONS\n";
  exit;
}

my (%i_comps);
$i_comps{"ORACHK_ICOMPS"} = 0;

if ( $COMPONENTS )
{
  $i_comps{"ORACHK_ICOMPS"} = 1;
  foreach my $c (split(/:/, $COMPONENTS) )
  {
    $c =~ s/ //g;
    $c = uc($c);
    $i_comps{$c} = 1;
  }
}

my %run_comps;
$run_comps{"ORACHK_ICOMPS"} = 0;
if ( $FMW_RUN_COMPS )
{
  $run_comps{"ORACHK_ICOMPS"} = 1;
  foreach my $c (split(/,/, $FMW_RUN_COMPS) )
  {
    $c =~ s/ //g;
    $c = uc($c);
    $run_comps{$c} = 1;
  }
}

my %ex_comps;
$ex_comps{"ORACHK_ICOMPS"} = 0;
if ( $FMW_EXCLUDE_COMPS )
{
  $ex_comps{"ORACHK_ICOMPS"} = 1;
  foreach my $c (split(/,/, $FMW_EXCLUDE_COMPS) )
  {
    $c =~ s/ //g;
    $c = uc($c);
    $ex_comps{$c} = 1;
  }
}

my %EXCHECKS;
if ( -e $EXCLUDEFIL ) {
  open(EX, "<$EXCLUDEFIL");
  while(my $excheck = <EX>) { 
    chomp($excheck); 
    next if($excheck =~ m/^\s*$/);
    $EXCHECKS{$excheck} = 1; 
  }
  close(EX);
}

my $bw_start_end = "";
my %checks = ();
my $check_id;
my $key;
my $start_reading = 0;
open(RF, "$COLLECTIONS");
while(<RF>)
{
  chomp;
  $start_reading = 1 if ( /COLLECTIONS_START/ );
  next if ( $start_reading == 0 );

  if ( /^_(\w+)-(\w+) (.*)/ ||
       /^_(\w+)-(\w+)/ )
  {
    $checks{$1}->{$2} = $3;
    $check_id = $1;
    $key = $2;
    $bw_start_end = $key if ( $key =~ /_START$/ );
    $bw_start_end = "" if ( $key =~ /_END$/ );
  }
   elsif ( $bw_start_end )
  {
    $checks{$check_id}->{$key} .= "$_\n";
  }
}
close(RF);

my %actual_check_ids = ();
open(RF, "$COLLECTIONS");
while(<RF>)
{
  chomp;
  last if ( /COLLECTIONS_START/ );
  next if ( /^\s*$/ || /-OS_COLLECT_COUNT/ || /-_REQUIRES_ROOT_COUNT/ ); 
  my $check_id = (split " ",$_)[2];  
  $check_id =~ s/\s*//g;
  if (defined $check_id) { $actual_check_ids{$check_id} = 1; }
}
close(RF);

my %FMW_CR;
foreach my $fcr (split(/:/, $FMW_COMPS_RUNNING) )
{
  $fcr =~ s/ //g;
  if ($fcr ne "") {
    $fcr = uc($fcr);
    $FMW_CR{$fcr} = 1;
  }
}

sub compare_needs_running 
{
  my $iNEEDS_RUNNING = shift;

  my %needs_run;
  foreach my $nr (split(/:/, $iNEEDS_RUNNING) )
  {
    $nr =~ s/ //g;
    if ($nr ne "") {
      $nr = uc($nr);
      $needs_run{$nr} = 1;
    }
  }

  for(keys %needs_run) {
    if (exists $FMW_CR{$_}) {
      return 1;
    }
  } 
  return 0;
}

if ( $CHECK_TYPE eq 'IDMHC_CHECK' || $CHECK_TYPE eq 'IDMHC_COLLECT') {
  open(WF, ">$MANIFEST_XML");
  print WF "<?xml version=\"1.0\"?>\n";
  print WF "<plugins report.name=\"IDM System Health Check Summary\">\n";
  print WF "\n";
  
  my %pluginids = ();
  
  foreach my $key ( keys %checks )
  {
    my $FMW_COMPS_MATCH = 0;
    if ( $checks{$key}->{TYPE} =~ /\b$CHECK_TYPE\b/ )
    {
      my ($excheckid) = 0;
      
      #my $pid 		= $checks{$key}->{AUDIT_CHECK_NAME};
      my $needs_running	= $checks{$key}->{NEEDS_RUNNING};

      $needs_running =~ s/\s*//g;
      if ($needs_running eq "" || $needs_running eq 'UNSPECIFIED') {
        $FMW_COMPS_MATCH=1
      } else {
        $FMW_COMPS_MATCH=compare_needs_running($needs_running);
      }
  
      $checks{$key}->{$CHECK_TYPE.'_COMMAND_START'} =~ s/\n\s*$//mgx;
      $checks{$key}->{$CHECK_TYPE.'_COMMAND_START'} =~ s/\r//g;
      $checks{$key}->{AUDIT_CHECK_NAME} =~ s/\r//g;

      my $pid = $checks{$key}->{$CHECK_TYPE.'_COMMAND_START'};
      $pid =~ s/\w*.(\w*)$//g;
      $pid = $1;
  
      if ( ! exists $pluginids{$pid} && ( $run_comps{"ORACHK_ICOMPS"} == 0 || exists $run_comps{"$needs_running"} ) && (! exists $EXCHECKS{$key} && ! exists $EXCHECKS{$checks{$key}->{AUDIT_CHECK_NAME}} ) && ($FMW_COMPS_MATCH == 1) && ($ex_comps{"ORACHK_ICOMPS"} == 0 || ! exists $ex_comps{"$needs_running"}))
      {
        my @comps = split(/:/, $checks{$key}->{COMPONENTS});
        my $MMATCH = 0;
        foreach my $comp (@comps) {
	  if ($i_comps{"ORACHK_ICOMPS"} == 0 || exists $i_comps{$comp}) {
	    $MMATCH = 1;
  	    last;        
          } 
	}
	
        if ($MMATCH == 1 && exists $actual_check_ids{$key}) {
          $CHECK_TYPE_CNT++;
 	  $pluginids{$pid} = 1;	
	  #print WF "<plugin id=\"$checks{$key}->{AUDIT_CHECK_NAME}\"\n";
	  print WF "<plugin id=\"$pid\"\n";
	  print WF "        description=\"$checks{$key}->{AUDIT_CHECK_NAME}\"\n";
	  print WF "        invoke=\"\"\n";
	  print WF "        plugin.class=\"$checks{$key}->{$CHECK_TYPE.'_COMMAND_START'}\"\n";
	  print WF "        class.path=\"\"/>\n";
	}
      }
    }
  }
  print WF "</plugins>\n";
  close(WF);

  if ( $CHECK_TYPE_CNT == 0 ) {
    unlink("$MANIFEST_XML");
  }
} else {
  my %files = ();
  
  open(WF, ">FMW_Checks.xml");
  print WF "<?xml version=\"1.0\"?>\n";
  print WF "<plugins report.name=\"IDM System Health Check Summary\">\n";
  print WF "\n";
  
  my %pluginids = ();
  
  foreach my $key ( keys %checks )
  {
    my $FMW_COMPS_MATCH = 0;
    if ( $checks{$key}->{OS_COMMAND_START} =~ /\<plugin id=\"(\w+)\"/ )
    {
      my $pid = $1;
      $checks{$key}->{OS_COMMAND_START} =~ s/\r//g;
  
      my $needs_running = $checks{$key}->{NEEDS_RUNNING};

      $needs_running =~ s/\s*//g;
      if ($needs_running eq "" || $needs_running eq 'UNSPECIFIED') {
        $FMW_COMPS_MATCH=1
      } else {
        $FMW_COMPS_MATCH=compare_needs_running($needs_running);
      }
  
      if ( ! exists $pluginids{$pid} && ( $run_comps{"ORACHK_ICOMPS"} == 0 || exists $run_comps{"$needs_running"} ) && ($FMW_COMPS_MATCH == 1) && ($ex_comps{"ORACHK_ICOMPS"} == 0 || ! exists $ex_comps{"$needs_running"}) )
      {
        $pluginids{$pid} = 1;
        my @comps = split(/:/, $checks{$key}->{COMPONENTS});
        my $write_this_check = 0;
        foreach my $comp (@comps)
        {
          if ( $i_comps{"ORACHK_ICOMPS"} == 0 || exists $i_comps{$comp} )
          {
            if ( ! exists $files{$comp} && exists $actual_check_ids{$key})
            {
              $CHECK_TYPE_CNT++;
              $files{$comp}->{NAME} = "${comp}_checks.xml";
              open($comp, ">", $files{$comp}->{NAME}) || die "Can't open $files{$comp}->{NAME} for writing\n";
              print $comp "<?xml version=\"1.0\"?>\n";
              print $comp "<plugins report.name=\"IDM System Health Check Summary\">\n";
              print $comp "\n";
            }
            $write_this_check = 1;
            print "\n$key - $checks{$key}->{AUDIT_CHECK_NAME}\n";
            print $comp "$checks{$key}->{OS_COMMAND_START}\n";
          }
        }
        print "$write_this_check - $checks{$key}->{AUDIT_CHECK_NAME}\n";
        print WF "$checks{$key}->{OS_COMMAND_START}\n" if ( $write_this_check == 1 );
      }
    }
  }
  
  foreach my $comp (keys %files)
  {
    print $comp "</plugins>\n";
    close($comp);
  }
  print WF "</plugins>\n";
  close(WF);

  if ( $CHECK_TYPE_CNT == 0 ) {
    unlink("$MANIFEST_XML");
  }
}

