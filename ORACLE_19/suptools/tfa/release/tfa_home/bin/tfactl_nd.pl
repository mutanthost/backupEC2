#!/usr/local/bin/perl
# 
# $Header: tfa/src/v2/tfa_home/bin/tfactl_nd.pl /main/1 2017/06/08 02:24:03 bibsahoo Exp $
#
# tfactl_nd.pl
# 
# Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactl_nd.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bibsahoo    04/06/17 - Creation
# 

use strict;
#use warnings;
use English;
use File::Basename;
use File::Spec::Functions;
use File::Path qw(mkpath rmtree);
use File::Copy;
use File::Find;
use Time::Local;
use Cwd;
use POSIX;
use Sys::Hostname;
use Data::Dumper;

use Getopt::Long;
use FindBin qw($Bin);
use Cwd qw(realpath abs_path);
use lib realpath("$Bin");

my $PLATFORM=$^O;
if ($PLATFORM ne "MSWin32") {
  print "ERROR: Unknown Operating System";
  exit -1;
}

eval q{use base 'Win32'; 1} or die $@;

my $tfa_home = get_tfa_home_daemon_mode();    ## TFA HOME location for daemon TFA in case TFA is already installed and running
my $TFA_HOME;                                 ## TFA HOME location for non-daemon TFA
my $USER = getUserName();
my $EUSER = getEscapedUserName($USER);
my $HOMEDIR = getHomeDirectory();
my $RUNFROMUSERHOME = 0;
my $RUNFROMTFAHOME = 0;
my $PERL = $ENV{perl};
my $TFA_SETUP;

my $queryTFAService = `sc query OracleTFAService`;
if ($queryTFAService && $queryTFAService =~ /STATE\s{1,}:\s{1,}4\s{1,}RUNNING/) {
  ## TFA SERVICE IS RUNNING
  checkTFAInHomeDir();
} else {
  if (-d catfile($HOMEDIR, ".tfa")) {
    $TFA_SETUP = catfile($HOMEDIR, ".tfa", "tfa_setup.txt");

    if (-e $TFA_SETUP) {
      my @tfasetup_contents = readFileToArray($TFA_SETUP);
      @tfasetup_contents = grepPatternFromArray(\@tfasetup_contents, "TFA_HOME=");
      @tfasetup_contents = cut_df_from_array(\@tfasetup_contents, "=", 2);

      $TFA_HOME = $tfasetup_contents[0];
      chomp($TFA_HOME);

      if (-d $TFA_HOME) {
        $RUNFROMUSERHOME = 1;

        @tfasetup_contents = grepPatternFromArray(\@tfasetup_contents, "PERL=");
        @tfasetup_contents = cut_df_from_array(\@tfasetup_contents, "=", 2);
        $PERL = $tfasetup_contents[0];
      }
    }
  }
}

my $cmd;
my $args = join " ", @ARGV;
if ($RUNFROMTFAHOME == 1) {
  $cmd = "$PERL " . catfile($tfa_home, "bin", "tfactl.pl") . " $args";
} elsif ($RUNFROMUSERHOME == 1) {
  $cmd = "$PERL " . catfile($TFA_HOME, "bin", "tfactl.pl") . " $args";
} else {
  my $currentDirectory = getcwd;
  my $commandPath = dirname(abs_path($0));

  if ($currentDirectory && -e catfile($currentDirectory, "tfactl.pl")) {
    $cmd = "$PERL " . catfile($currentDirectory, "tfactl.pl") . " $args";
  } elsif ($commandPath && -e catfile($commandPath, "tfactl.pl")) {
    $cmd = "$PERL " . catfile($commandPath, "tfactl.pl") . " $args";
  }
}
#print "COMMAND: $cmd\n";

## EXECUTE SCRIPT
system("cmd /c $cmd");

sub getHomeDirectory {
  my $noupdate = shift;
  my $homedir = $ENV{ORA_TFA_USER_HOME};

  if (!$homedir || ($homedir && !-d $homedir)) {
    my $username = getUserName();
    $homedir = catfile("C:", $username);
  }

  return tfactlwin_trim($homedir);
}

sub getUserName {
  my $user;
  if(Win32::IsAdminUser()){
    $user = "root";
  }else{
    $user = getlogin;
    my $domainName = `echo %userdomain%`;
    $domainName = tfactlwin_trim($domainName);
    if($domainName ne ""){
      $user = $domainName."\\".$user;
    }
  }

  #print "USER: $user\n";
  return $user;
} 

sub getEscapedUserName {
  my $user = shift;
  $user =~ s/\\/__/g;
  #print "ESCAPED USER: $user\n";
  return $user;
} 

sub get_tfa_home_daemon_mode {
  my $tfa_home = tfactlwin_query_registry("TFA_HOME");
  $tfa_home = (split /\s{1,}/, $tfa_home)[-1];
  return $tfa_home;
}

sub checkTFAInHomeDir {
  my $user_pub_key_file = catfile($tfa_home, "." . $EUSER, $EUSER . "_mykey.rsa.pub");
  #print "PUBLIC KEY FILE: $user_pub_key_file\nEUSER: $EUSER\n";

  if ($EUSER ne "Administrator" && ! -e $user_pub_key_file) {
    if (-d catfile($HOMEDIR, ".tfa")) {
      $TFA_SETUP = catfile("$HOMEDIR", ".tfa", "tfa_setup.txt");
      #print "TFA_SETUP: $TFA_SETUP\n";

      if (-e $TFA_SETUP) {
        my @tfasetup_contents = readFileToArray($TFA_SETUP);
        @tfasetup_contents = grepPatternFromArray(\@tfasetup_contents, "TFA_HOME=");
        @tfasetup_contents = cut_df_from_array(\@tfasetup_contents, "=", 2);
        
        $TFA_HOME = $tfasetup_contents[0];
        chomp($TFA_HOME);
        #print "TFA_HOME: $TFA_HOME\n";

        if (-d $TFA_HOME) {
          $RUNFROMUSERHOME = 1;
        }
      }
    }
  } else {
    if (-d $tfa_home) {
      $RUNFROMTFAHOME = 1;
      $TFA_SETUP = catfile($tfa_home, "tfa_setup.txt");

      if (-e $TFA_SETUP) {        
        my @tfasetup_contents = readFileToArray($TFA_SETUP);
        @tfasetup_contents = grepPatternFromArray(\@tfasetup_contents, "PERL=");
        @tfasetup_contents = cut_df_from_array(\@tfasetup_contents, "=", 2);

        $PERL = $tfasetup_contents[0];
        chomp($PERL);
      }
    }
  }
}

# Queries the registry for a key under Oracle Parent key to get its corresponding value
# Parameter - $key - registry key
# Return - value for required registry key
sub tfactlwin_query_registry{
  my $key =shift;
  my $unfilterResultFlag = shift;

  my $BASE_KEY="HKEY_LOCAL_MACHINE\\SOFTWARE\\Oracle";
  my $result="";

  my $type = tfactlwin_trim(tfactlwin_check_os_type());
  #print "TYPE: $type\n";
  my $REGISTRY_QUERY_TYPE;

  if ($type eq "64BIT"){
    $REGISTRY_QUERY_TYPE = "/reg:64";
  } else{
    $REGISTRY_QUERY_TYPE = "/reg:32";
  }

  if ($unfilterResultFlag) {
    $result = `reg query $BASE_KEY /s /e /f $key $REGISTRY_QUERY_TYPE`;
  } else {
    $result = `reg query $BASE_KEY /s /e /f $key $REGISTRY_QUERY_TYPE | findstr $key`;
  }
  #print "RES: reg query $BASE_KEY /s /e /f $key $REGISTRY_QUERY_TYPE | findstr $key\n";
  return $result;
}

# Returns the corresponding type of operating system (64BIT/32BIT)
# Return - 32BIT for 32 Bit operating system and 64BIT for 64 BIT operating system
sub tfactlwin_check_os_type{
  my $type =`IF EXIST "%PROGRAMFILES(X86)%" (ECHO 64BIT) ELSE (ECHO 32BIT)`;
  return $type;
}

sub tfactlwin_trim{
   my $str = $_;
   $str = shift;
   $str =~ s/^\s+//;
   $str =~ s/\s+$//;
   return $str ;
}

#Conversion for shell command 'cat <filename>' and returns the contents in an array
sub readFileToArray {
  my $filename = shift;
  my @arr;
  open FILE, "$filename" or die "Could not open $filename!\n";
  while(<FILE>) {
    push @arr, $_;
  }
  close FILE;
  return @arr;
}

#perl conversion of 'grep <pattern>' from array and returns an array
sub grepPatternFromArray {
  my $wordListref = shift;
  my @wordList = @{$wordListref};
  my $pattern = shift;
  chomp($pattern);

  my @retArray;
  my $i;
  foreach $i (@wordList) {
    if ( $i =~ /$pattern/ ){
      push @retArray, $i;
    }
  }
  return @retArray;
}


#perl conversion of awk '{print $n}' from array
sub awk_n_from_array {
  my $arrayRef = shift;
  my @array = @{$arrayRef};
  my $n = shift;
  #$[ = 1;                 # set array base to 1
  #$, = ' ';               # set output field separator
  #$\u = "\n";              # set output record separator

  my $i;
  my @Fld;
  my @retArray;
  foreach $i (@array){
      @Fld = split(' ', $i, -1);
      push @retArray, $Fld[$n-1];
  }
  return @retArray;
}

#perl conversion of 'cut -d<delim> -f<n>'
sub cut_df_from_array {
  my $arrayRef = shift;
  my @array = @{$arrayRef};
  my $delim = shift;
  my $n = shift;

  my $i;
  my @retArray;
  my @tmpArray;
  foreach $i (@array) {
    @tmpArray = split /$delim/,$i;
    push @retArray, $tmpArray[$n-1];
  }
  return @retArray;
}

sub printArr {
  my $arrref = shift;
  my @arr = @{$arrref};
  foreach my $x (@arr) {
    print "$x\n";
  }
}