# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/tfa_mq.pl /main/2 2017/08/11 05:02:21 llakkana Exp $
#
# tfa_mq.pl
# 
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfa_mq.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    gadiga      02/08/16 - query metadata for receiver
#    gadiga      02/08/16 - Creation
# 
#####################################################################
#

use warnings;
use strict;
use Cwd;
use File::Copy;
use File::Path;
use File::Find;
use File::Basename;
use File::Spec::Functions;
use Getopt::Long;

my $tfahome;
my $otype;
my $onumber;

my $action = $ARGV[0];
if ( ! $action )
{
  print "Usage : $0 <action> -tfahome <tfahome> -t <error facility> -n <error number>\n";
  exit;
}
shift(@ARGV);

GetOptions (
            'tfahome=s' => \$tfahome,
            't=s' => \$otype,
            'n=s' => \$onumber
             );

if ( $action eq "oerr" )
{
  run_oerr($tfahome, $otype, $onumber);
}


sub run_oerr
{
  my ($tfahome, $otype, $onumber) = @_;
  my $crshome = "";
  if ( $tfahome =~ /(.*)\/tfa\/[^\/]+\/tfa_home/ )
  {
    $crshome = $1;
    $ENV{ORACLE_HOME} = $crshome;
    my @out = `$crshome/bin/oerr $otype $onumber`;
    chomp(@out);
    foreach my $line (@out)
    {
      print "$line\n";
    }
  }
}
