# 
# $Header: tfa/src/v2/tfa_home/bin/tfaosutils.pl /main/18 2017/09/27 00:54:31 llakkana Exp $
#
# tfaosutils.pl
# 
# Copyright (c) 2015, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfaosutils.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    llakkana    09/18/17 - Add function to get uncompressed size of file and
#                           df of mnt
#    arupadhy    08/01/16 - Added subroutines to count files in a directory and
#                           create file list from a directory
#    bibsahoo    06/02/16 - Windows Typical Install
#    gadiga      06/01/16 - get offset in file for time
#    bibsahoo    05/23/16 - FIX BUG 21887154 - [12201-LIN64-TFA]ACCESS ADD
#                           SHOULD CHECK USER/GRP EXISTENCE ON REMOTE NODE
#    arupadhy    04/27/16 - Added support for check available space function
#    arupadhy    01/17/16 - support for user domain in case of windows users
#    arupadhy    12/08/15 - Conditional execution of exec in begin block for
#                           windows, due to command difference of env - linux
#                           and set - windows
#    cnagur      11/03/15 - Added getfileowner
#    arupadhy    10/07/15 - added utility for removing files/directories,
#                           copy files/directories, getting oracle running
#                           instance list required for instance monitoring for
#                           windows and linux
#    gadiga      10/01/15 - export to wrap file
#    arupadhy    09/11/15 - added change file permission utility
#    cnagur      03/30/15 - Initialized Dir size to 0
#    bburton     03/24/15 - Perl Script to provide OS utilities to be called
#                           from Java
#    bburton     03/24/15 - Creation
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
 push @INC, catdir(dirname($PROGRAM_NAME),'common');
}

use osutils;
use tfactlwin;

#variables
my $cmd;

if ( scalar @ARGV <= 0 ) {
   help();
   exit 1;
}

$cmd= $ARGV[0];
shift @ARGV;

if ( $cmd eq "chmod" ) { 
  osutils_chmod(@ARGV); 
}
elsif ( $cmd eq "du" ) { 
  osutils_du(@ARGV); 
}  
elsif ( $cmd eq "df" ) { 
  osutils_df(@ARGV); 
}  
elsif ( $cmd eq "export2wrapfile" ) {
  osutils_export2wrapfile(@ARGV);
}
elsif ( $cmd eq "rm" ) {
  osutils_rm(@ARGV);
}
elsif ( $cmd eq "cp" ) {
  osutils_cp(@ARGV);
}
elsif ( $cmd eq "getOracleInstanceList" ) {
  osutils_getOracleInstanceList(@ARGV);
}
elsif ( $cmd eq "getfileowner" ) {
  osutils_getFileOwner(@ARGV);
}
elsif ( $cmd eq "getuserdomain" ) {
  osutils_getuserdomain(@ARGV);
}
elsif ( $cmd eq "check_available_space" ) {
  osutils_check_available_space(@ARGV);
}
elsif ( $cmd eq "listusers" ) {
  my @users = osutils_get_list_of_available_users(@ARGV);
  my $tfalist = join " ", @users;
  print "$tfalist\n";
}
elsif ( $cmd eq "configureTFA" ) {
  tfactlwin_configure_tfa(@ARGV);
}
elsif ( $cmd eq "getfileoffset" ) {
  print osutils_get_offset_in_file_for_time(@ARGV);
}
elsif ( $cmd eq "countFilesInDirectory" ) {
  print osutils_count_files_in_directory(@ARGV);
}
elsif ( $cmd eq "createFileListFromDirectory" ) {
  print osutils_create_file_list_from_directory(@ARGV);
}
elsif ($cmd eq "getUncompressedSize") {
  print osutils_get_uncompressed_size(@ARGV);
}
else {
  help();
}


#=======tfaosutils help fun=============#
sub help 
{
  print "Usage: $0 [ chmod | du | ls | rm | cp | getOracleInstanceList | getuserdomain | check_available_space | getfileoffset | countFilesInDirectory | createFileList] <ARGS>\n";
}

