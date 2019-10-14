# 
# $Header: tfa/src/orachk/src/discoverdbasm.pl /main/3 2017/08/11 17:38:18 rojuyal Exp $
#
# discoverdbasm.pl
# 
# Copyright (c) 2015, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      discoverdbasm.pl - Discover DB and ASM related information
#
#    DESCRIPTION
#      Discover DB and ASM related information
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    rojuyal     11/19/15 - Creation
# 
#===============================================================================

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use English;
use POSIX;
use File::Spec::Functions;
use FindBin qw($Bin);
use Cwd 'realpath';
use lib realpath("$Bin");
use mineocr;

my ($CRS_HOME);
my ($DUMP_FIL);
my ($OFFLINE)	= 0;
my ($EXCLUDE_PID_FIL);
my ($orainv,$oratab,$olrloc);
my ($result_code) = 0;
my ($debug) = 0;

sub usage {
    print "Usage: $0 -c CRSHOME -f FILE -o OFFLINE -e exclude_pid_file -d debug(0|1) -h help\n";
    exit;
}

sub print_status_bar {
    printf ". "; 
}

GetOptions(
  "c=s" => \$CRS_HOME,
  "f=s" => \$DUMP_FIL,
  "o=n" => \$OFFLINE,
  "e=s" => \$EXCLUDE_PID_FIL,
  "d=n" => \$debug,
  "h"   => \&usage
) or usage();

if ($OFFLINE == 0 && defined $EXCLUDE_PID_FIL) {
  open(EPFIL,'>>', "$EXCLUDE_PID_FIL") || die $!;
  print EPFIL "$$\n";
  close(EPFIL);
}

$result_code = discover_crs_db_asm_and_write_kvout($DUMP_FIL,$CRS_HOME,$debug);

if ($result_code == 2) {
    print "Please specify CRS_HOME\n";
    usage();
}
exit($result_code);
