# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/collection.pl /main/2 2017/08/11 05:02:21 llakkana Exp $
#
# collection.pl
# 
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      collection.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    llakkana    11/15/16 - Creation
# 
BEGIN {
unless ($ENV{BEGIN_BLOCK}) {
  $ENV{POSIXLY_CORRECT} = 1;
  $ENV{BEGIN_BLOCK} = 1;
  if($^O eq "MSWin32"){
    exec 'set',"$^X",$0,@ARGV;
  }else{
    exec 'env',"$^X",$0,@ARGV;
  }
}
 $ENV{LC_ALL} = C;
}

use strict;
use File::Spec::Functions;
use File::Basename;
use Cwd 'abs_path';

our $PROGRAM_NAME;
BEGIN {
 $PROGRAM_NAME = abs_path($0);
 push @INC, catdir(dirname($PROGRAM_NAME),"..",'common');
}

use collection;

my $cmd;

if ( scalar @ARGV <= 0 ) {
   help();
   exit 1;
}

$cmd= $ARGV[0];
shift @ARGV;

$cmd = lc $cmd;

if ( $cmd eq "ipaddress" ) {
  my %ips = collection_ip_address(@ARGV);
  #For now need only priv ip
  if ( exists $ips{PRIVATE_IP} ) {
    print "$ips{PRIVATE_IP}";
  }
}
else {
  help();
}

sub help 
{
  print "Usage: $0 [ ipaddress ] <ARGS>\n";
}

