# 
# $Header: tfa/src/v2/tfa_home/bin/common/cmdlocation.pm /main/8 2018/07/09 23:34:54 bibsahoo Exp $
#
# cmdlocation.pm
# 
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      cmdlocation.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bibsahoo    07/04/18 - ADDING SHELL COMMAND STAT
#    bburton     04/24/18 - SSH in here is causing SSH env var to be empty for
#                           all commands
#    migmoren    04/19/18 - Add cut,tail,kstat,psrinfo,prtpicl,tr,wc,
#                           uname,ps,sort,uniq,head,df
#    migmoren    04/18/18 - Bug 26984470 - SOLSP-18.1-TFA:TFACTL SUMMARY EXIT
#                           WHEN COLLECTING OS DETAILS
#    recornej    10/17/17 - Adding mount,rpm,id,lsmod,multipath,uname
#    bibsahoo    07/13/17 - FIX BUG 26413598
#    bburton     03/27/17 - Add HEAD
#    llakkana    11/04/16 - Function to get location of command independent of
#                           platform
#    llakkana    11/04/16 - Creation
# 
package cmdlocation;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw( cmdlocation_get
		$AWK
		$BASH	
		$CAT
		$CUT
		$CP
		$DF
		$ECHO
		$GREP
		$HEAD
		$ID
		$IFCONFIG
		$KSTAT
		$LS
		$LSMOD
		$MOUNT
    		$MULTIPATH
		$MV
		$NETSTAT
		$NSLOOKUP
		$PIDOF
		$PING
		$PRTPICL
		$PS
		$PSRINFO
		$PSTACK
		$RDS_INFO
    		$RM
    		$RPM
    		$SED
    		$SH
		$SORT
		$STRACE
		$SU
		$TAIL
		$TR
		$TRUSS
		$UNAME
		$UNIQ
		$UNZIP
		$WC
		$WHO
		$XARGS
		$ZIP
		$STAT
		);

use strict;
use English;
use File::Spec::Functions;

my $IS_WIN = 0;

if ( $^O eq "MSWin32" ) {
  $IS_WIN = 1;
}

our $AWK;
our $BASH;
our $CAT;
our $CUT;
our $CP;
our $DF;
our $ECHO;
our $GREP; 
our $HEAD;
our $ID;
our $IFCONFIG;
our $KSTAT;
our $LS;
our $LSMOD;
our $MOUNT;
our $MULTIPATH;
our $MV;
our $NETSTAT;
our $NSLOOKUP;
our $PIDOF;
our $PING;
our $PRTPICL;
our $PS;
our $PSRINFO;
our $PSTACK;
our $RDS_INFO;
our $SED;
our $SH;
our $SORT;
our $STRACE;
our $SU;
our $TAIL;
our $TR;
our $TRUSS;
our $UNAME;
our $UNIQ;
our $WC;
our $WHO;
our $XARGS;
our $TOUCH;
our $RM;
our $RPM;
our $ADRCI;
our $ORABASE;
our $UNZIP;
our $ZIP;
our $STAT;

if (!$IS_WIN) {
	$AWK = cmdlocation_get("awk");
	$BASH = cmdlocation_get("bash");
	$CAT = cmdlocation_get("cat");
	$CUT = cmdlocation_get("cut");
	$CP = cmdlocation_get("cp");
	$DF = cmdlocation_get("df");
	$ECHO = cmdlocation_get("echo");
	$GREP = cmdlocation_get("grep"); 
	$HEAD = cmdlocation_get("head"); 
	$IFCONFIG = cmdlocation_get("ifconfig");
	$KSTAT = cmdlocation_get("kstat");
	$LS = cmdlocation_get("ls");
	$MV = cmdlocation_get("mv"); 
	$NETSTAT = cmdlocation_get("netstat");
	$NSLOOKUP = cmdlocation_get("nslookup");
	$PIDOF = cmdlocation_get("pidof"); 
	$PING = cmdlocation_get("ping");
	$PRTPICL = cmdlocation_get("prtpicl");
	$PS = cmdlocation_get("ps");
	$PSRINFO = cmdlocation_get("psrinfo");
	$PSTACK = cmdlocation_get("pstack");
	$RDS_INFO = cmdlocation_get("rds-info");
	$SED = cmdlocation_get("sed");
	$SH = cmdlocation_get("sh");
	$SORT = cmdlocation_get("sort");
	$STRACE = cmdlocation_get("strace");
	$SU = cmdlocation_get("su");
	$TAIL = cmdlocation_get("tail");
	$TR = cmdlocation_get("tr");
	$TRUSS = cmdlocation_get("truss");
	$UNAME = cmdlocation_get("uname");
	$UNIQ = cmdlocation_get("uniq");
	$WC = cmdlocation_get("wc");
	$WHO = cmdlocation_get("who");
	$XARGS = cmdlocation_get("xargs");
	$TOUCH = cmdlocation_get("touch");
	$ADRCI = "adrci";
	$ORABASE = "orabase";
	$RM = cmdlocation_get("rm");
  	$ID = cmdlocation_get("id");
  	$RPM= cmdlocation_get("rpm");
  	$MOUNT = cmdlocation_get("mount");
  	$LSMOD = cmdlocation_get("lsmod");
  	$MULTIPATH = cmdlocation_get("multipath");
  	$UNAME = cmdlocation_get("uname");
  	$UNZIP = cmdlocation_get("unzip");
	$ZIP = cmdlocation_get("zip");
	$STAT = cmdlocation_get("stat");
} else {
	$TOUCH   = "type NUL >";
	$MV      = "move";
	$RM      = "del";
	$ADRCI   = "adrci.exe"; 
	$ORABASE = "orabase.exe";
	$CP      = "copy";
	$CAT     = "type";
	$LS      = "dir";
}

####################
# NAME
# 	cmdlocation_get
# DESCRIPTION 	
# 	Subroutine to get the location of command
# PARAMETERS
# 	Name of the command
# RETURNS
# 	Path of the command
####################

sub cmdlocation_get 
{
  my $command = shift;
  my $cmdpath = $command;

  if ( -f catfile("", "bin", $command) ) {
    $cmdpath = catfile("", "bin", $command);
  } 
  elsif ( -f catfile("", "usr", "bin", $command) ) {
    $cmdpath = catfile("", "usr", "bin", $command);
  } 
  elsif ( -f catfile("", "sbin", $command) ) {
    $cmdpath = catfile("", "sbin", $command);
  } 
  elsif ( -f catfile("", "usr", "sbin", $command) ) {
    $cmdpath = catfile("", "usr", "sbin", $command);
  } 
  elsif ( -f catfile("", "usr", "local", "bin", $command) ) {
    $cmdpath = catfile("", "usr", "local", "bin", $command);
  } 
  elsif ( $IS_WIN ) {
    my $output = `where $command 2>&1`;
    chomp $output;
    if ( -f catfile($output) ) {
      $cmdpath = catfile($output);
    }
  }
  return $cmdpath;
}

1;
