# 
# $Header: tfa/src/orachk_py/scripts/rac_main.pl /main/5 2017/09/13 22:55:19 rojuyal Exp $
#
# rac_main.pl
# 
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      rac_main.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    rkchaura    10/24/16 - fileattr check
#    rkchaura    10/24/16 - Creation
 

use strict ;
use File::Spec::Functions qw(rel2abs catfile catdir) ;
use File::Basename ;
BEGIN {
  push(@INC, dirname(rel2abs($0))) ;
}
use Config ;
use File::Find ;
use English ;
use Cwd ;
use List::Util qw(max) ;
use POSIX qw(strftime) ;
use Data::Dumper; #Added by Rajeev to support debug in perl

use rac_lib ;

use constant TRUE  => "1" ;
use constant FALSE => "0" ;

use constant SUCCESS => "1" ;
use constant FAILED  => "0" ;

my $debug = FALSE ;



#check_user("root") ;
my ($PDEBUG)    = $ENV{RAT_PDEBUG}||0; #Rajeev

my ($perl_exe) = $ENV{RAT_PERL_EXE}||"perl"; #Gowtham
# Script agent should only have one parameter. It might be
# start/check/stop/clean
if ( scalar(@ARGV) < 1 ) {
  # Script should not enter here
  Logger("Action Parameter needs for the script: {start|stop|check|clean|delete}\n") ;
  exit FAILED ;
} elsif ( scalar(@ARGV) > 1 ) {
  # Script also should not enter here
  Logger("Too many parameters for the script: @ARGV\n") ;
  exit FAILED ;
}

my $operation = $ARGV[0] ;

$EMAIL_FLAG = FALSE ;

# Create the required PID record files and log file
my $out_dir = get_output_dir(); #Rajeev
my ($toolpath)    = $ENV{RAT_TOOLPATH} || getcwd(); #Gowtham added to handle cases while running from orabase
my $file_checker_script = catfile($toolpath, $FILE_CHECKER_SCRIPT) ;
my $pidfile = catfile( $out_dir, "pids" ) ; #Rajeev
unless ( -d $pidfile ) {
  mkdir $pidfile ;
  chmod 0755, $pidfile ;
}

my $check_nodes = get_attribute_value_from_env("CHECK_NODES") ; #Rajeev


if ( $operation eq "start" ) { # agent start operation

  unless ( -e $RESOURCE_RUNNING_FLAG ) {
    Logger("Starting the resource ...\n") ;
  } else {
    Logger("Resource is already running !\n") ;
    exit TRUE ;
  }

  # Create Flag file
  open( FH, ">$RESOURCE_RUNNING_FLAG" ) or die "Can not create $RESOURCE_RUNNING_FLAG for $!" ;
  print FH "Resource Started\n" ;
  print FH "Do not delete this file manually !\n" ;
  close FH ;

  # Call scrip to do start action
  system("$perl_exe $file_checker_script start 2>&1 &") ;

  # Do One Time Sanity Checks Here
  exit FALSE ;

} elsif ( $operation eq "stop" ) { # agent stop operation
  Logger "Stopping the resource ...\n" ;

  # Delete the RESOURCE_RUNNING_FLAG to avoid further actions
  if ( -e $RESOURCE_RUNNING_FLAG ) {
    unlink $RESOURCE_RUNNING_FLAG ;
  }

  # Call script to do start action
  system("$perl_exe $file_checker_script stop 2>&1 &") ;
  killall_pids ;

  exit FALSE ;

} elsif ( $operation eq "check" ) { # agent check operation
  if ( -e $RESOURCE_RUNNING_FLAG ) {
    system("$perl_exe $file_checker_script check 2>&1 &") ;
    Logger("Checking the resource ...\n") ;
    exit FALSE ;
  } else {
    Logger "Please start the resource first !\n" ;
    exit TRUE ;
  }

  exit FALSE ;

} elsif ( $operation eq "clean" || $operation eq "delete" ) { # agent clean/delete operation
  Logger "Cleaning the resource ...\n" ;

  unlink $RESOURCE_RUNNING_FLAG if ( -e $RESOURCE_RUNNING_FLAG ) ;

  # Kill the processes and quit
  system("$perl_exe $file_checker_script clean 2>&1 &") ;

  killall_pids ;

  exit FALSE ;

} else {

  # Script should not enter here
  Logger "Some Error happens since script should not be here !\n" ;
  exit TRUE ;

}





1;
__END__
