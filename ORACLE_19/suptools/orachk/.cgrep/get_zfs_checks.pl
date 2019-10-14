# 
# $Header: tfa/src/orachk/src/get_zfs_checks.pl /main/4 2017/08/11 17:38:18 rojuyal Exp $
#
# get_zfs_checks.pl
# 
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      get_zfs_checks.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    gadiga      05/03/16 - support exlude checks
#    mengwliu    04/28/16 - Add an argument to support NEEDS_RUNNING =
#                           EXTERNAL_ZFS
#    gadiga      04/08/16 - Read zfs checks from small file
#    gadiga      04/08/16 - Creation
# 
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;

my ($COLLECTIONS) 	= $ARGV[0];
my ($COMPONENTS)	= $ARGV[1];
my ($CHECK_TYPE_CNT)	= 0;
my ($PDEBUG)            = $ENV{RAT_PDEBUG}||0;
my ($NEEDS_RUNNING);
my ($EXFIL);
GetOptions ("needs_running=s" => \$NEEDS_RUNNING,
            "excludefile=s", \$EXFIL);

if ( ! $COLLECTIONS )
{
  print "Usage : $0 <collections.dat> -needs_running <ZFS/EXTERNAL_ZFS> -excludefile <exclude file>\n";
  exit;
}

if ( ! -r "$COLLECTIONS" )
{
  print "Error: Failed to read $COLLECTIONS\n";
  exit;
}

if ( ! $NEEDS_RUNNING || ! ($NEEDS_RUNNING eq "ZFS" || $NEEDS_RUNNING eq "EXTERNAL_ZFS") )
{
  print "Error: Invalid value for -needs_running\n";
  exit;
}

my $bw_start_end = "";
my %checks = ();
my $check_id;
my $key;
my $start_reading = 0;
my $cnt = 0;
my $zfscheck = "";
my %excl = ();

read_excl_file();

open(RF, "$COLLECTIONS");
while(<RF>)
{
  chomp;
  $start_reading = 1 if ( /COLLECTIONS_START/ );

  if ( $start_reading == 0 )
  {
     #_4.0.0.0.0.0.0.0.0.0-LEVEL 1-CHECK_ID BC7D40E36C995EF4E0431EC0E50A4E5D
    if ( /^_[\d\.]+-LEVEL\s+\d+-CHECK_ID (\w+)/ )
    {
      $checks{$1} = 1;
    }
  }
   else
  {
    if ( /^_(\w+)-(\w+) (.*)/ ||
         /^_(\w+)-(\w+)/ )
    {
      $check_id = $1;
      $key = $2;
      $bw_start_end = $key if ( $key =~ /_START$/ );
      $bw_start_end = "" if ( $key =~ /_END$/ );
      if ( exists $checks{$check_id} && /NEEDS_RUNNING $NEEDS_RUNNING/ && ! exists $excl{$check_id} )
      {
        $cnt ++;
        #print "$cnt. $check_id - $bw_start_end : $zfscheck\n";
        print "$zfscheck\n";
      }
    }
     elsif ( $bw_start_end && exists $checks{$check_id} && $bw_start_end eq "OS_COMMAND_START" )
    {
      $zfscheck = $_;
    }
  }
}
close(RF);

sub read_excl_file
{
  open(RF, $EXFIL);
  while(<RF>)
  {
    chomp;
    s/\s//g;
    $excl{$_} = 1;
  }
  close(RF);
}
