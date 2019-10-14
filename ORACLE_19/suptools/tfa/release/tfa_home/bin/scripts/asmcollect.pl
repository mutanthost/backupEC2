# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/asmcollect.pl /main/1 2018/05/28 15:06:27 bburton Exp $
#
# asmcollect.pl
# 
# Copyright (c) 2017, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      asmcollect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    04/20/18 - Adding sudo to commands that need to run as root
#                           and user is not root.
#    recornej    04/05/18 - Fix Bug 27812531 - TFA IS RUNNING NUMEROUS ASMCMD
#                           LSOF AND LSOD COMMANDS
#    bburton     03/05/18 - XbranchMerge bburton_tfa_122131_fixes_txn from
#                           st_tfa_12.2.1.3.1
#    bburton     12/12/17 - asmcmd should run as grid user
#    recornej    10/26/17 - Removing ORACLE_HOME related code
#    recornej    10/24/17 - Fix script when not running from srdc.
#    recornej    10/16/17 - Change name of the log file
#    recornej    10/04/17 - Script to gather ASM Configuration data.
#    recornej    10/04/17 - Creation
#
#####################################
#
use strict;
use English;
use File::Basename;
use File::Spec::Functions;
use File::Copy;
use Time::Local;
use Term::ANSIColor;
use Cwd;
use POSIX;
use constant TRUE                      =>  "1";
use constant FALSE                     =>  "0";

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME).'/..';
  push @INC, dirname($PROGRAM_NAME).'/../common';
  push @INC, dirname($PROGRAM_NAME).'/../modules';
  push @INC, dirname($PROGRAM_NAME).'/../common/exceptions';
}

use osutils;
use dbutil;
use cmdlocation;
use tfactlglobal;

my $hostname;
my $crsowner;
my $crshome;
my $db = "+ASM";
my $tfa_home;
my $PLATFORM = $^O;
my $IS_WINDOWS;
if ( $PLATFORM eq "MSWin32" ) {
   $IS_WINDOWS = 1;
}
my $SU = cmdlocation_get("su");
my $SUDO;
$SUDO = cmdlocation_get("sudo") if ( $current_user ne "root");
$SUDO .= " -n" if ( $SUDO ne "");
use Getopt::Long qw(:config no_auto_abbrev);

GetOptions ( 'crshome=s'=>\$crshome,
             'hostname=s'=>\$hostname,
             'tfahome=s' =>\$tfa_home
           );

 
#Open a log file for this collection script to write to
open( LOG2, '>' ,$hostname ."_asm_collection.log");
open(*STDERR, '>', $hostname . "_asm_collection.err");
open(*STDOUT, '>', $hostname . "_asm_collection.out");

if ( @ARGV ) {
  print LOG2 "Invalid Options specified: @ARGV\n";
  print LOG2 "Exiting ...\n";
  exit(1);
}
#check parameters;
if ( ! $hostname ) {
   print LOG2 localtime(time) . ": Hostname Not Specified Exiting\n";
   exit(1);
}
if ( ! $crshome ){
  print LOG2 localtime(time) . ": CRS_HOME Not Specified Exiting\n";
  exit (1);
} elsif ( ! -d $crshome ) {
  print LOG2 localtime(time) . ": CRS_HOME does not exists\n";
  exit (1);
}

my $filename = catfile($crshome,"bin","oracle");
my $ownerid;
if (! $IS_WINDOWS ) {
  #Get crsowner
  $ownerid = (stat $filename)[4];
  $crsowner = (getpwuid $ownerid)[0];
}


my $retval = dbutil_setOraEnv($tfa_home,"$db",\*LOG2,TRUE);

if ( $retval ne 0 ){
  print LOG2 localtime(time) ." ASM database was not found or is not running locally exiting...\n";
  exit(1);
}

print LOG2 localtime(time) . ": Running ASM Configuration script for TFA\n";
print LOG2 localtime(time) . ": crshome  => $crshome\n";
print LOG2 localtime(time) . ": crsowner => $crsowner\n";
print LOG2 localtime(time) . ": ORACLE_HOME =>  ".$ENV{"ORACLE_HOME"}."\n";
print LOG2 localtime(time) . ": ORACLE_SID =>   ".$ENV{"ORACLE_SID"}."\n";

my $ASMCMD = catfile("$crshome","bin","asmcmd");
$ASMCMD .=".bat" if ( $IS_WINDOWS );
open( FH, '>', $hostname."_asm_collection.out");
print LOG2 localtime(time). ": Executing asm collect commands\n";

if ( $PLATFORM eq "linux" ) {
  collect_asm_l();
} elsif ( $PLATFORM eq "solaris" ) {
  collect_asm_s();
} elsif ( $PLATFORM eq "aix" ) {
  collect_asm_a();
} elsif ( $PLATFORM eq "hpux" ) {
  collect_asm_h();
} elsif ( $PLATFORM eq "MSWin32") {
  collect_asm_w();
}

#Generic commands for all platforms. 
my @gencommandarray;
print FH "\n***********************************************************************\n";
print FH "ASMCMD commands to gather complemetary metadata information:\n";
print FH "***********************************************************************\n";
push(@gencommandarray, "$ASMCMD --nocp -p ls -ls~~$ASMCMD --nocp -p ls -ls~~$crsowner");
push(@gencommandarray, "$ASMCMD --nocp -p lsattr~~$ASMCMD --nocp -p lsattr~~$crsowner");
push(@gencommandarray, "$ASMCMD --nocp -p lsdg~~$ASMCMD --nocp -p lsdg~~$crsowner");
push(@gencommandarray, "$ASMCMD --nocp -p lsdsk~~$ASMCMD --nocp -p lsdsk~~$crsowner");
push(@gencommandarray, "$ASMCMD --nocp -p lsof~~$ASMCMD --nocp -p lsof~~$crsowner");
push(@gencommandarray, "$ASMCMD --nocp -p lsod~~$ASMCMD --nocp -p lsod~~$crsowner");
push(@gencommandarray, "$ASMCMD --nocp -p iostat~~$ASMCMD --nocp -p iostat~~$crsowner");
push(@gencommandarray, "$ASMCMD --nocp -p dsget~~$ASMCMD --nocp -p dsget~~$crsowner");
push(@gencommandarray, "$ASMCMD --nocp -p lsop~~$ASMCMD --nocp -p lsop~~$crsowner");
push(@gencommandarray, "$ASMCMD --nocp -p spget~~$ASMCMD --nocp -p spget~~$crsowner");
push(@gencommandarray, "$ASMCMD --nocp -p lstmpl~~$ASMCMD --nocp -p lstmpl~~$crsowner");
push(@gencommandarray, "$ASMCMD --nocp -p lsusr~~$ASMCMD --nocp -p lsusr~~$crsowner");
push(@gencommandarray, "$ASMCMD --nocp -p lsgrp~~$ASMCMD --nocp -p lsgrp~~$crsowner");
push(@gencommandarray, "$ASMCMD --nocp -p lspwusr~~$ASMCMD --nocp -p lspwusr~~$crsowner");
push(@gencommandarray, "$ASMCMD --nocp -p volinfo --all~~$ASMCMD --nocp -p volinfo --all~~$crsowner");
runcommandarray(\@gencommandarray);
print LOG2 localtime(time). ": Finished executing asm collect commands\n";
close(FH);

#Close files
close(LOG2);
close(*STDERR);
close(*STDOUT);


########
# NAME
#  collect_asm_l
#
# DESCRIPTION
#  collect asm configuration info in Linux
#
# PARAMETERS
#  None
# RETURNS
#  None
#############
#
sub collect_asm_l
{
  my @commandarray;
  print FH "\n***********************************************************************\n";
  print FH "Additional OS information related to STORAGE: \n";
  print FH "***********************************************************************\n";
  push(@commandarray, "$UNAME -a~~$UNAME -a");
  push(@commandarray, "$CAT /etc/*release~~$CAT /etc/*release");
  push(@commandarray, "$LS -l $crshome/bin/oracle~~$LS -l $crshome/bin/oracle");
  push(@commandarray, "$ID $crsowner~~$ID $crsowner");
  push(@commandarray, "$DF -ha~~$DF -ha");
  push(@commandarray, "$PS -ef | $GREP pmon | $GREP -v grep~~$PS -ef | $GREP pmon | $GREP -v grep");
  push(@commandarray, "$CAT /proc/filesystems~~$CAT /proc/filesystems");
  push(@commandarray, "$CAT /proc/partitions~~$CAT /proc/partitions");
  push(@commandarray, "$MULTIPATH -ll~~$MULTIPATH -ll");
  push(@commandarray, "$DF -m~~$DF -m");
  push(@commandarray, "$LS -l $crshome/bin/oradism~~$LS -l $crshome/bin/oradism");
  push(@commandarray, "$MOUNT -l~~$MOUNT -l");
  runcommandarray(\@commandarray);
  @commandarray = ();

  print FH "\n***********************************************************************\n";
  print FH "ASMLIB API:\n";
  print FH "***********************************************************************\n";
  push(@commandarray, "$RPM -qa | $GREP oracleasm~~$RPM -qa | $GREP oracleasm");
  push(@commandarray, "$LSMOD | $GREP -i asm~~$LSMOD | $GREP -i asm");
  push(@commandarray, "/sbin/modinfo oracleasm~~/sbin/modinfo oracleasm");
  push(@commandarray, "$SUDO $CAT /etc/sysconfig/oracleasm~~$SUDO $CAT /etc/sysconfig/oracleasm");
  push(@commandarray, "$SUDO $LS -l /etc/sysconfig/oracleasm*~~$SUDO $LS -l /etc/sysconfig/oracleasm*");
  runcommandarray(\@commandarray);
  @commandarray = ();

  print FH "\n***********************************************************************\n";
  print FH "ASMLIB DISCOVERY PATH:\n";
  print FH "***********************************************************************\n";
  push(@commandarray, "/etc/init.d/oracleasm status~~/etc/init.d/oracleasm status");
  push(@commandarray, "/usr/sbin/oracleasm-discover~~/usr/sbin/oracleasm-discover");
  push(@commandarray, "/usr/sbin/oracleasm-discover \'ORCL:*\'~~/usr/sbin/oracleasm-discover \'ORCL:*\'");
  push(@commandarray, "/usr/sbin/oracleasm-discover \'/dev/oracleasm/disks/*\'~~/usr/sbin/oracleasm-discover \'/dev/oracleasm/disks/*\'");
  push(@commandarray, "$SUDO $LS -l /usr/sbin/oracleasm-discover~~$SUDO $LS -l /usr/sbin/oracleasm-discover");
  runcommandarray(\@commandarray);
  @commandarray = ();


  print FH "***********************************************************************\n";
  print FH "ASMLIB DEVICE ACCESS:\n";
  print FH "***********************************************************************\n";
  push(@commandarray, "/etc/init.d/oracleasm scandisks~~/etc/init.d/oracleasm scandisks");
  push(@commandarray, "/etc/init.d/oracleasm listdisks~~/etc/init.d/oracleasm listdisks");
  push(@commandarray, "$SUDO $LS -l /dev/oracleasm/disks~~$SUDO $LS -l /dev/oracleasm/disks");
  push(@commandarray, "/sbin/blkid~~/sbin/blkid");
  runcommandarray(\@commandarray);
  @commandarray = ();

  print FH "***********************************************************************\n";
  print FH "MULTIPATH DEVICE ACCESS:\n";
  print FH "***********************************************************************\n";
  push(@commandarray, "$SUDO $LS -l /dev/mpath/*~~$SUDO $LS -l /dev/mpath/*");
  push(@commandarray, "$LS -l /dev/mapper/*~~$LS -l /dev/mapper/*");
  push(@commandarray, "$LS -l /dev/dm-*~~$LS -l /dev/dm-*");
  push(@commandarray, "$SUDO $LS -l /dev/emcpower*~~$SUDO $LS -l /dev/emcpower*");
  runcommandarray(\@commandarray);
}

########
# NAME
#  collect_asm_s
#
# DESCRIPTION
#  collect asm configuration info in Solaris
#
# PARAMETERS
#  None
# RETURNS
#  None
#############
#
sub collect_asm_s
{

  my @commandarray;
  print FH "\n***********************************************************************\n";
  print FH "Additional OS information related to STORAGE: \n";
  print FH "***********************************************************************\n";
  push(@commandarray, "$UNAME -a~~$UNAME -a");
  push(@commandarray, "$CAT /etc/*release~~$CAT /etc/*release");
  push(@commandarray, "$LS -l $crshome/bin/oracle~~$LS -l $crshome/bin/oracle");
  push(@commandarray, "$ID $crsowner~~$ID $crsowner");
  push(@commandarray, "$DF -ha~~$DF -ha");
  push(@commandarray, "$PS -ef | $GREP pmon | $GREP -v grep~~$PS -ef | $GREP pmon | $GREP -v grep");
  push(@commandarray, "$CAT /proc/partitions~~$CAT /proc/partitions");
  push(@commandarray, "$MULTIPATH -ll~~$MULTIPATH -ll");
  push(@commandarray, "$DF -m~~$DF -m");
  push(@commandarray, "$LS -l $crshome/bin/oradism~~$LS -l $crshome/bin/oradism");
  push(@commandarray, "$MOUNT -l~~$MOUNT -l");
  runcommandarray(\@commandarray);
  @commandarray = ();

  print FH "***********************************************************************\n";
  print FH "MULTIPATH DEVICE ACCESS:\n";
  print FH "***********************************************************************\n";
  push(@commandarray, "$SUDO $LS -l /dev/mpath/*~~$SUDO $LS -l /dev/mpath/*");
  push(@commandarray, "$LS -l /dev/mapper/*~~$LS -l /dev/mapper/*");
  push(@commandarray, "$LS -l /dev/dm-*~~$LS -l /dev/dm-*");
  push(@commandarray, "$SUDO $LS -l /dev/emcpower*~~$SUDO $LS -l /dev/emcpower*");
  runcommandarray(\@commandarray);

}
########
# NAME
#  collect_asm_a
#
# DESCRIPTION
#  collect asm configuration info in AIX
#
# PARAMETERS
#  None
# RETURNS
#  None
#############
#
sub collect_asm_a
{

  my @commandarray;
  my $OSLEVEL = cmdlocation_get("oslevel");
  my $PRTCONF = cmdlocation_get("prtconf");

  print FH "\n***********************************************************************\n";
  print FH "Additional OS information related to STORAGE: \n";
  print FH "***********************************************************************\n";
  push(@commandarray, "$OSLEVEL -r~~$OSLEVEL -r");
  push(@commandarray, "$PRTCONF | $GREP -i \'System Model\'~~$PRTCONF | $GREP -i \'System Model\'");
  push(@commandarray, "$LS -l $crshome/bin/oracle~~$LS -l $crshome/bin/oracle");
  push(@commandarray, "$ID $crsowner~~$ID $crsowner");
  push(@commandarray, "$DF -ha~~$DF -ha");
  push(@commandarray, "$PS -ef | $GREP pmon | $GREP -v grep~~$PS -ef | $GREP pmon | $GREP -v grep");
  push(@commandarray, "$CAT /etc/filesystem~~$CAT /etc/filesystem");
  push(@commandarray, "$MULTIPATH -ll~~$MULTIPATH -ll");
  push(@commandarray, "$DF -k~~$DF -m");
  push(@commandarray, "$LS -l $crshome/bin/oradism~~$LS -l $crshome/bin/oradism");
  push(@commandarray, "$MOUNT -l~~$MOUNT -l");
  runcommandarray(\@commandarray);
  @commandarray = ();

  print FH "***********************************************************************\n";
  print FH "MULTIPATH DEVICE ACCESS:\n";
  print FH "***********************************************************************\n";
  push(@commandarray, "$SUDO $LS -l /dev/mpath/*~~$SUDO $LS -l /dev/mpath/*");
  push(@commandarray, "$LS -l /dev/mapper/*~~$LS -l /dev/mapper/*");
  push(@commandarray, "$LS -l /dev/dm-*~~$LS -l /dev/dm-*");
  push(@commandarray, "$SUDO $LS -l /dev/emcpower*~~$SUDO $LS -l /dev/emcpower*");
  runcommandarray(\@commandarray);

  
}

########
# NAME
#  collect_asm_h
#
# DESCRIPTION
#  collect asm configuration info in HPUX
#
# PARAMETERS
#  None
# RETURNS
#  None
#############
#
sub collect_asm_h
{
  #TODO Add information for HPUX.
=head
  my @commandarray;
  print FH "\n***********************************************************************\n";
  print FH "Additional OS information related to STORAGE: \n";
  print FH "***********************************************************************\n";
  print FH "\n***********************************************************************\n";
  print FH "ASMLIB API:\n";
  print FH "***********************************************************************\n";
  print FH "\n***********************************************************************\n";
  print FH "ASMLIB DISCOVERY PATH:\n";
  print FH "***********************************************************************\n";
  print FH "***********************************************************************\n";
  print FH "ASMLIB DEVICE ACCESS:\n";
  print FH "***********************************************************************\n";
  print FH "***********************************************************************\n";
  print FH "MULTIPATH DEVICE ACCESS:\n";
  print FH "***********************************************************************\n";
  runcommandarray(\@commandarray);
=cut
}
########
# NAME
#  collect_asm_w
#
# DESCRIPTION
#  collect asm configuration info in Windows
#
# PARAMETERS
#  None
# RETURNS
#  None
#############
#

sub collect_asm_w
{
  #TODO add information for Windows 
=head
  my @commandarray;
  print FH "\n***********************************************************************\n";
  print FH "Additional OS information related to STORAGE: \n";
  print FH "***********************************************************************\n";
  print FH "\n***********************************************************************\n";
  print FH "ASMLIB API:\n";
  print FH "***********************************************************************\n";
  print FH "\n***********************************************************************\n";
  print FH "ASMLIB DISCOVERY PATH:\n";
  print FH "***********************************************************************\n";
  print FH "***********************************************************************\n";
  print FH "ASMLIB DEVICE ACCESS:\n";
  print FH "***********************************************************************\n";
  print FH "***********************************************************************\n";
  print FH "MULTIPATH DEVICE ACCESS:\n";
  print FH "***********************************************************************\n";
  runcommandarray(\@commandarray);
=cut

}

sub runcommandarray{
  my $array_ref = shift;
  my @commandarray = @{$array_ref};
   foreach my $commandstring ( @commandarray ) {
    my ( $command, $desc, $runuser ) = split(/~~/,$commandstring);
    print FH "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n";
    print FH "\t $desc :\n" if( $desc );
    my $commandfile = $command;
    $commandfile =~ s/\s.*//;
    if ( -e $commandfile ) {
       if ( length $runuser ) {
          $command = checksu($runuser,$command);
       } 
       print FH osutils_runtimedcommand($command,20,TRUE,\*LOG2);
    } else {
      print FH "$commandfile not found on this system\n";
    }
    print FH "\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n";
  }
}

sub checksu {
  my $requser    = shift;
  my $cmd        = shift;
  my $IS_WINDOWS = 0;
  my $current_user;
  if ( $^O eq "MSWin32" ) {
    $IS_WINDOWS = 1;
    $current_user = Win32::LoginName();
    if ( Win32::IsAdminUser() ) {
      $current_user = "root";
    }
  } else {
    $current_user = getpwuid($<);
  }

  if ( ($current_user eq "root") && (not $IS_WINDOWS) ) {
    return "$SU $requser -c \"" . $cmd . "\"";
  } else {
    return $cmd;
  }
}

