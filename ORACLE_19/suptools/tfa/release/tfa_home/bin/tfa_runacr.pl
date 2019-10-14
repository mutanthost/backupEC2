#!/usr/bin/perl
# 
# $Header: tfa/src/v2/tfa_home/bin/tfa_runacr.pl /main/3 2018/08/08 09:00:28 bburton Exp $
#
# tfa_runacr.pl
# 
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfa_runacr.pl - Wrapper script for calling acr python script acrctl.pyc 
#
#    DESCRIPTION
#      This Wrapper script sets ACR_REPO env variable and compatible python bin
#      This script is called at the end of diag collection on each node
#      It takes collecion file as input, unzips, redacts and zips the file 
#      If output dir is not passed then do inplace redaction	
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     07/17/18 - Bug 28100803 - ODA: SUPPORT ACR (REDACTION) OPTIONS
#    llakkana    05/30/18 - Changes for in place redaction
#    llakkana    05/08/18 - Wrapper script to run ACR(Adaptive classification &
#                           redaction)
#    llakkana    05/08/18 - Creation
# 

use strict;
use Getopt::Long;
use File::Spec::Functions;
use File::Basename;
use File::Path;
use Cwd 'abs_path';
use POSIX;
use POSIX qw(:termios_h strftime);
our $PROGRAM_NAME;

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
 $PROGRAM_NAME = abs_path($0); 
 push @INC, dirname($PROGRAM_NAME).'/common'; 
}

Getopt::Long::Configure("prefix_pattern=(-|--)");
use cmdlocation;

if (scalar @ARGV <= 0) {
   help();
   exit 1;
}

my $tfa_home;
my $input;
my $in_dir;
my $output;
my $out_dir;
my $sanitize;
my $mask;
my $help;
my $redact_dir = "redact_".strftime("%Y%m%d%H%M%S",localtime(time));
my $mode;

# Parse Arguments
GetOptions('tfa_home=s' => \$tfa_home,
            'i=s'       => \$input,
            'o=s'       => \$output,
            'sanitize'    => \$sanitize,
            'mask'      => \$mask,
            'h'         => \$help,
            'help'      => \$help) or $help = 1;

if (!$tfa_home || !$input) {
  $help = 1;
}

if ($help) {
  help();
  exit 0;
}

if ( $sanitize ) {
   $mode = "-m sanitize";
} else {
   $mode = "-m mask";
}

my $acr_home = catdir($tfa_home,"acr_home");
my $acrctl = catfile($acr_home,"acrctl.pyc");
my $acr_repo = catdir($tfa_home,"acr_repo");
my $python = getPythonLoc($tfa_home);

#Setting ACR_REPO env variable is requirement from acr
$ENV{ACR_REPO} = $acr_repo;


if (-d $input) {
  $in_dir = $input;
}
elsif ($input =~ /\.zip$/i) {
  my $zip_path = abs_path($input);
  my $basedir = dirname($zip_path);
  $in_dir = catdir($basedir,$redact_dir);  
  mkdir($in_dir);
  system("$UNZIP -q $input -d $in_dir");
}

if ($output) {
  #acr uses output dir to keep redated files when it is passed 
  #In this case it will not change original files
  $out_dir = $output;
}
else {
  #When output dir is not passed do inplace redaction
  #In this case orginal files will be overwrite by redacted files
  $out_dir = $in_dir; 
}

if (!-d $in_dir || ($output && !-d $out_dir)) {
  print "Input/Output directories should be valid directories\n";
  exit 1;
}

#print "$python $acrctl redact -i $in_dir -o $out_dir $mode\n";
if ($output) {
  system("$python $acrctl redact -i $in_dir -o $out_dir $mode");
}
else {
  #Inplace redaction
  system("$python $acrctl redact -i $in_dir $mode");
}

if ($input =~ /\.zip$/i) { #TFA collection
  unlink $input;
  #print "Running cd $out_dir;zip -qr $input *; cd -\n";
  system("cd $out_dir;$ZIP -qr $input *; cd -");
}
#rm in_dir When input is zip file
rmtree($in_dir) if ($input ne $in_dir); 

##################Function###################
sub getPythonLoc
{
  my $tfa_home = shift;
  my $python_home;
  my $python_zip;   
  my $python;
  my $extract_to;

  #Check for python2.7 in the following order
  #check tfa_home/Python2712
  #check suptools/orachl
  #check default python

  $python_home = catdir($tfa_home,"Python2712");  

  if (!-d $python_home) {
    #Check orachk for python 
    $python_home = catdir($tfa_home,"ext","orachk","build","Python2712");
    if (!-d $python_home) {
      $python_zip = catfile($tfa_home,"ext","orachk","build","Python2712_linux.zip");      	
      $extract_to = catdir($tfa_home,"ext","orachk","build");
      system("$UNZIP -q $python_zip -d  $extract_to");
    }
  }
  
  if (!-d $python_home) {
    #Check default python
  }

  if (-d $python_home) {
    $python = catfile($python_home,"bin","python");
  }

  return $python;
}

sub help 
{
  print "Usage: $0 -tfa_home <TFA_HOME> -i <zip|dir> [-o outdir] \n";
}


