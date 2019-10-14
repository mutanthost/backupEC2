# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/procinfocollect.pl /main/3 2017/08/11 05:02:21 llakkana Exp $
#
# procinfocollect.pl
# 
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      procinfocollect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     06/09/16 - Script to gather process info information - not a
#                           default option.,
#    bburton     06/09/16 - Creation
# 
use English;
use File::Basename;
use File::Spec::Functions;
use File::Copy;
use Time::Local;
use Term::ANSIColor;
use Cwd;
use POSIX;

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME).'/..';
  push @INC, dirname($PROGRAM_NAME).'/../common';
  push @INC, dirname($PROGRAM_NAME).'/../modules';
  push @INC, dirname($PROGRAM_NAME).'/../common/exceptions';
}

use tfactlglobal;
use tfactlshare;
use cmdlocation;


use Getopt::Long qw(:config no_auto_abbrev);


# Set up local variables
my $PLATFORM = $^O;
my $hostname;
my $tfahome;
my $command;
my $UNAME;

# Parse command line args
GetOptions( 'hostname=s'    => \$hostname);

if(@ARGV) {
   print "\nInvalid Options specified: @ARGV\n";
   exit(1);
}

#Open a log file for this collection script to write to
open (LOG2, '>', $hostname . "_procinfo_collection.log");
if (  $PLATFORM eq "linux" ) {
open (*STDERR, '>', $hostname . "_procinfo_collection.err");
open (*STDOUT, '>', $hostname . "_procinfo_report");
print LOG2 localtime(time) . ": Running PROCINFO collection script for TFA \n";
print LOG2 "hostname: $hostname\n";

# Get All the FD's  /proc/[0-9]*/fd
my $procdir = catdir("","proc");
my $command = "$LS $procdir | $GREP '[0-9][0-9]*'| $SORT -n | $XARGS -n1 -i $SH -c \"$ECHO 'pid {}'; $CAT $procdir/{}/stack; $LS -al $procdir/{}/fd; $ECHO\"";

print "\nRunning Command : $command\n\n";
runtimedcommand($command);
print "\n";

} else {
   print LOG2 localtime(time) . ": PROCINFO Collection is only supported on Linux Platform\n";
}
close(LOG2);
close(*STDERR);
close(*STDOUT);

sub runtimedcommand  {
my $command = shift;
my $timeout = shift;
if ( !$timeout ) { $timeout = 10 };
  eval {
      local $SIG{ALRM} = sub { die "Timeout\n" };
      alarm $timeout;
      system($command);
      alarm 0;
  };
  if ($@) {
      print LOG2 localtime(time) . ": $command timed out.\n";
      return(99);
  } elsif ($? != 0) {
      print LOG2 localtime(time) . ": $command failed.\n" ;
      return(1);
  } else {
      print LOG2 localtime(time) . ": $command success.\n" ;
      return(0);
  }
}
