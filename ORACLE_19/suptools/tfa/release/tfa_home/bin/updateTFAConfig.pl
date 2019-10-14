#!/usr/local/bin/perl
# 
# $Header: tfa/src/v2/tfa_home/bin/updateTFAConfig.pl /main/1 2018/05/18 03:54:15 bibsahoo Exp $
#
# updateTFAConfig.pl
# 
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      updateTFAConfig.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bibsahoo    04/27/18 - FIX BUG 27845377
#    bibsahoo    04/26/18 - Creation
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
use File::Copy;
use Cwd 'abs_path';

#variables
my $cmd;

if ( scalar @ARGV <= 0 ) {
   help();
   exit 1;
}

$cmd= $ARGV[0];
shift @ARGV;

if ( $cmd eq "updateConfig" ) { 
  my $tfa_config_file = $ARGV[0];
  my $config = $ARGV[1];
  my $value = $ARGV[2];
  my $tfahome = $ARGV[3];

  my $error_message = "";
  my $status = -1;

  my $config_found = 0;
  my $backup_file = $tfa_config_file . "\.old";
  my $tmp_tfa_config_file = $tfa_config_file . "\.tmp";
  unlink($backup_file) if (-f $backup_file);
  copy($tfa_config_file, $backup_file) or $error_message = "FAILED: Copy failed: $!";
  #unlink($tfa_config_file);
  my $tmp_value = $value;
  $tmp_value =~ s/\\/\\\\/g;
  my $str = $config . "=" . $tmp_value;

  open(RF, "$tfa_config_file" ) or $error_message = "FAILED: Unable to open file $tfa_config_file...\n";
  open(my $fptr, '>>', $tmp_tfa_config_file ) or $error_message = "FAILED: Unable to open file $tmp_tfa_config_file...\n";
  while( <RF> ) {
	chomp;
	if ( /^$config=(.*)/ ) {
	  print $fptr "$str\n";
	  $config_found = 1;
	} else {
	  print $fptr "$_\n";
	}
  }
  close(RF);

  if ($fptr && $error_message eq "") {
	if ( $config_found == 0 ) {	
	  print $fptr "$str\n";
	  $status = 0;
	} else {
	  $status = 1;
    }
  }
  close($fptr);

  copy($tmp_tfa_config_file, $tfa_config_file) or $error_message = "FAILED: Copy failed: $!";
  unlink($tmp_tfa_config_file);

  if ($status == -1 || $error_message ne "") {
  	print $error_message;
  } else {
  	print $status;
  }
} else { 
  help();
}

#=======updateTFAConfig help fun=============#
sub help 
{
  print "Usage: $0 [ updateConfig ] <ConfigKey> <ConfigValue> <tfaHome> \n";
}