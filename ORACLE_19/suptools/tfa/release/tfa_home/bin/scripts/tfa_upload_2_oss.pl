#!/usr/bin/perl
# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/tfa_upload_2_oss.pl /main/3 2018/08/06 11:58:34 llakkana Exp $
#
# tfa_upload_2_oss.pl
# 
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfa_upload_2_oss.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    llakkana    07/10/18 - Fix an issue with reading oss config variables
#    gadiga      06/25/18 - upload collections to object store
#    gadiga      06/25/18 - Creation
# 
use warnings;
use strict;
use English;
use Cwd;
use File::Copy;
use File::Path;
use File::Find;
use File::Basename;
use File::Spec::Functions;
use Getopt::Long;
BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME).'/..';
  push @INC, dirname($PROGRAM_NAME).'/../common';
  push @INC, dirname($PROGRAM_NAME).'/../modules';
  push @INC, dirname($PROGRAM_NAME).'/../common/exceptions';
  }

use tfactlglobal;
use tfactlshare;

my $collection = $ARGV[0];
my $metafile = $ARGV[1];
if ( ! $collection )
{
  print "Usage: $0 <collection>\n";
  exit 1;
}

my $curl = "/usr/bin/curl";

if ( ! -f "$curl" )
{
  $curl = "/bin/curl";
}

my $tfa_home = dirname(dirname(dirname($PROGRAM_NAME)));
my $tvar;
my ($ourl, $ouser, $opass, $oproxy);
open(CF, "$tfa_home/internal/config.properties");
while(<CF>)
{
  chomp;
  if ( /oss\.url=(.*)/ )
  {
    $tvar = $1;
    if ($tvar ne "null") {
      $ourl = tfactlshare_tag2spl($tvar);
    }
  }
  if ( /oss\.user=(.*)/ )
  { 
    $tvar = $1;
    if ($tvar ne "null") {
      $ouser = tfactlshare_tag2spl($tvar);
    }
  }
  if ( /oss\.password=(.*)/ )
  { 
    $tvar = $1;
    if ($tvar ne "null") {
      $opass = tfactlshare_tag2spl($tvar);
    }
  }
  if ( /oss\.proxy=(.*)/ )
  {
    $tvar = $1;
    if ($tvar ne "null") {
      $oproxy = tfactlshare_tag2spl($tvar);
    }
  }
}
close(CF);

if ($oproxy && $oproxy ne "null")
{
  $ENV{"http_proxy"} = $oproxy;
  $ENV{"https_proxy"} = $oproxy;
}

if ( -f $metafile )
{
  open(MF, $metafile);
  my @data = <MF>;
  chomp(@data);
  if ( $data[0] )
  {
    $opass = tfactlshare_tag2spl($data[0]);
  }
}

if ( !$ourl || !$ouser || !$opass )
{
  print "ERROR: OSS is not configured.";
  exit 1;
}

my $fromhost = `hostname`;
chomp($fromhost);
my $trfile = $collection;
$trfile =~ s/.*tfa\/repository\///;

my @out = `$curl -u '$ouser:$opass' -v -X PUT -T $collection -i "$ourl/tfa/$fromhost/$trfile" 2>&1`;

foreach my $line (@out)
{
  tfactlshare_trace(3, $line,'y', 'n');
}
