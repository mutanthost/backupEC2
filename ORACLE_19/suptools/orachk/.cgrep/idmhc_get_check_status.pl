# 
# $Header: tfa/src/orachk/src/idmhc_get_check_status.pl /main/3 2017/08/11 17:38:18 rojuyal Exp $
#
# idmhc_get_check_status.pl
# 
# Copyright (c) 2015, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      idmhc_get_check_status.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    gadiga      04/12/15 - parser output and return status
#    gadiga      04/12/15 - Creation
# 

use strict;
use warnings;
use Data::Dumper;

my $checkid	= $ARGV[0];
my $xmlout 	= $ARGV[1];
my ($PDEBUG)    = $ENV{RAT_PDEBUG}||0;

if ( ! $checkid || ! $xmlout || ! -r $xmlout )
{
  print "Usage: $0 <checkid> <xml output file>\n";
  exit;
}

my $readcheck = 0;
my $checkstatus = -1; # 0 pass, 1 failed
open(RF, "$xmlout");
while(<RF>)
{
  chomp;
  if ( /\<id\>$checkid\<\/id\>/ )
  {
    $readcheck = 1;
  }
   elsif ( $readcheck == 1 && /\<status\>(\w+)\<\/status\>/ )
  {
    my $status = $1;
     if ( $status eq "Success" )
     {
       $checkstatus = 0;
     }
      else
     {
       $checkstatus = 1;
     }
  }
   elsif ( $readcheck == 1 && /\<message \/\>/ )
  {
    print "No output\n";
    last;
  }
   elsif ( $readcheck == 1 && /\<message\>(.*)/ )
  {
    my $line = $1;
    if ( $line =~ /^(.*)\<\/message\>.*/ )
    {
      my $msg = "$1";
      print "\n$msg\n";
      last;
    }
     else
    {
      print "\n$line\n";
    }
    $readcheck = 2;
  }
   elsif ( $readcheck == 2 && /(.*)\<\/message\>/ )
  {
    print "$1\n";
    last;
  }
   elsif ( $readcheck == 2 )
  {
    print "$_\n";
  }
}
close(RF);
exit $checkstatus;
