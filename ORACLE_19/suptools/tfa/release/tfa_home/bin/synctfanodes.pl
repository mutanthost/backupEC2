#!/usr/local/bin/perl
# 
# $Header: tfa/src/v2/tfa_home/bin/synctfanodes.pl /main/7 2018/05/28 15:06:28 bburton Exp $
#
# synctfanodes.pl
# 
# Copyright (c) 2017, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      synctfanodes.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bibsahoo    04/27/18 - FIX BUG 27845377
#    bibsahoo    11/02/17 - TFA 122130 WIN FIX
#    bibsahoo    11/02/17 - FIX BUG 27047999
#    bburton     08/25/17 - bug26696360 - windows hyphen in hostname
#    bibsahoo    07/26/17 - FIX BUG 26536025
#    bibsahoo    07/12/17 - FIX BUG 26413598
#    bibsahoo    05/02/17 - Creation
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
use Term::ANSIColor;
use Cwd;
use POSIX;
use Sys::Hostname;

use Getopt::Long;
use FindBin qw($Bin);
use Cwd qw(realpath abs_path);
use lib realpath("$Bin");

my $IS_WINDOWS = 0;
if ( $^O eq "MSWin32" ) {
	$IS_WINDOWS = 1;
}

if ($IS_WINDOWS)
{
  eval q{use base 'Win32'; 1} or die $@;
}

my $TEMP_TRANSFER_DIR;
if ($IS_WINDOWS) {
	$TEMP_TRANSFER_DIR = catfile("C:", "sync_transfer");
  	mkpath($TEMP_TRANSFER_DIR);
} else {
	$TEMP_TRANSFER_DIR = catfile("", "tmp", "sync_transfer");
}

my $SSH_USER = "root";
my $SCRIPT = "synctfanodes.pl";

my $username = getUserName();
my $USER = getEscapedUserName($username);

if ($USER ne $SSH_USER) {
	print "User $USER does not have permissions to run this script.";
	exit 1;
}

my $TFA_HOME;
my $TFA_BASE;
my $TFA_SETUP;
my $TFACTL;
my $PERL;
my $CRSHOME;
my $HOSTNAME;
my $TFA_JHOME;
my $REGENERATE;
my $HELP;

GetOptions(
	'regenerate' => \$REGENERATE,
	'tfa_home=s' => \$TFA_HOME,
	'help' => \$HELP,
	'h' => \$HELP
	) or $HELP = 1;

if ($HELP) {
	printHelp();
	exit 1;
}

if (!$TFA_HOME) {
	if ($IS_WINDOWS) {
		my $str = win_query_registry("TFA_HOME");
		$str = trimString($str);
		$TFA_HOME = (split /\s{1,}/, $str)[2];
	} else {

	}
}

#print "TFA_HOME: $TFA_HOME\n";

if ($IS_WINDOWS) {
	$TFACTL = catfile($TFA_HOME, "bin", "tfactl.bat");
} else {
	$TFACTL = catfile($TFA_HOME, "bin", "tfactl");
}

$TFA_SETUP = catfile($TFA_HOME, "tfa_setup.txt");
if (-f $TFA_SETUP) {	
      my @file_arr = readFileToArray($TFA_SETUP);
      my @perl_arr = grepPatternFromArray(\@file_arr, "PERL=");
      my @crshome_arr = grepPatternFromArray(\@file_arr, "CRS_HOME=");

      $PERL = (split /=/, $perl_arr[0])[1];
      $CRSHOME = (split /=/, $crshome_arr[0])[1];

      chomp($PERL);
      chomp($CRSHOME);
}

#print "PERL: $PERL\nCRSHOME: $CRSHOME\n";

$HOSTNAME = tolower_host();
#print "HOSTNAME: $HOSTNAME\n";

if ($REGENERATE && $REGENERATE == 1) {
	if ( -f catfile($TFA_HOME, "server.jks") ) {
		unlink(catfile($TFA_HOME, "server.jks"));
	}

	if ( -f catfile($TFA_HOME, "client.jks") ) {
		unlink(catfile($TFA_HOME, "client.jks"));
	}

	if ( -f catfile($TFA_HOME, "internal", "ssl.properties") ) {
		unlink(catfile($TFA_HOME, "internal", "ssl.properties"));
	}
}

# Get TFA_BASE
if ($TFA_HOME =~ /$HOSTNAME/i) {
	my $parentDir = dirname($TFA_HOME);
	$TFA_BASE = dirname($parentDir);
} else {
	$TFA_BASE = dirname($TFA_HOME);
}
#print "TFA_BASE: $TFA_BASE\n";

if (! -e catfile($TFA_HOME, "server.jks")) {
	if (!$REGENERATE) {
		print "\nTFA has not yet generated any certificates on this Node.\n";
		print "Do you want to generate new certificates to synchronize across the nodes? [Y|N] [Y]: ";
		my $userinput = <STDIN>;

		if ( $userinput eq "n" || $userinput eq "N" ) {	
			print "Exiting Now...";
			exit 1;
		}
	}

	# Get JAVA HOME
	if ( -d catdir($TFA_HOME, "jre") ) {
		$TFA_JHOME = catdir($TFA_HOME, "jre");
	} elsif (-f $TFA_SETUP) {
		my @file_arr = readFileToArray($TFA_SETUP);
      	my @java_arr = grepPatternFromArray(\@file_arr, "JAVA_HOME=");

      	$TFA_JHOME = (split /=/, $java_arr[0])[1];

      	chomp($TFA_JHOME);

      	if (!$TFA_JHOME && -f catfile($TFA_BASE, $HOSTNAME, "java_install.out")) {
      		my @file_arr = readFileToArray(catfile($TFA_BASE, $HOSTNAME, "java_install.out"));
	      	my @java_arr = grepPatternFromArray(\@file_arr, "JAVA_HOME=");

	      	$TFA_JHOME = (split /=/, $java_arr[0])[1];

	      	chomp($TFA_JHOME);
      	}
	}
	#print "JAVA_HOME: $TFA_JHOME\n";

	my $java_exec;
	if ($IS_WINDOWS) {
		$java_exec = catfile($TFA_JHOME, "bin", "java.exe");
	} else {
		$java_exec = catfile($TFA_JHOME, "bin", "java");
	}
	if ( -x $java_exec ) {
		print "Generating new TFA Certificates...\n";
		my $cmd = $TFACTL . " generatecerts $TFA_HOME $TFA_JHOME 1";
		`$cmd`;

		print "Restarting TFA on $HOSTNAME...\n";
		$cmd = $TFACTL . " shutdown";
		`$cmd`;
		sleep(5);
		$cmd = $TFACTL . " start";
		`$cmd`;
	} else {
		print "Unable to determine JAVA HOME. Exiting Now...\n";
		exit 1;
	}
}

my $COUNT = 1;
my @HOSTLIST = ();

my $cmd = $TFACTL . " print hosts";
my $str = `$cmd`;

foreach my $line (split /\n/, $str) {
	$line =~ s/Host Name\s{1,}:\s{1,}//g;
	chomp($line);
	if ($line !~ /$HOSTNAME/) {
		push @HOSTLIST, $line;
	}
}

print "\nCurrent Node List in TFA : \n";
print "$COUNT. $HOSTNAME\n";

foreach my $host (@HOSTLIST) {
	$COUNT++;
	print "$COUNT. $host\n";
}

my $sync_list = "";
my $ping_list = "";

my @NODELIST;
if ($CRSHOME && -d $CRSHOME) {
	my $cmd;
	if ($IS_WINDOWS) {
		$cmd = catfile($CRSHOME, "BIN", "olsnodes.exe");
	} else {
		$cmd = catfile($CRSHOME, "bin", "olsnodes");
	}

	my $str = `$cmd`;
	if ($? == 0) {
		@NODELIST = split /\n/, $str;
		chomp(@NODELIST);
	}
}

if ($#NODELIST == -1) {
	my $crs_config_file = catfile($CRSHOME, "crs", "install", "crsconfig_params");
	if (-f $crs_config_file) {
		my $node_list;
		my @tmp = readFileToArray("$crs_config_file");
	    foreach my $x (@tmp) {
	      if ($x =~ /^NODE_NAME_LIST=/) {
	        my @tmp1 = split /=/, $x;
	        chomp($tmp1[-1]);
	        if ($tmp1[-1]) {
	          $node_list = $tmp1[-1];
	        }
	        #print "NODELIST : $nodeList from file\n"
	      }
	    }

	    push @NODELIST, $HOSTNAME;
	    foreach my $node (split /,/, $node_list) {
	    	if ($node !~ /$HOSTNAME/) {
	    		push @NODELIST, $node;
	    	}
	    }
	}
}

if ($#NODELIST > -1) {
	my $COUNT = 1;
	print "\nNode List in Cluster :\n";
	foreach my $node (@NODELIST) {
		print "$COUNT. $node\n";
		$COUNT++;
	}

	# Copy all the nodes to sync list 
	foreach my $node (@NODELIST) {
		if ($node !~ /$HOSTNAME/) {
			$sync_list = $sync_list . "$node\n";
		}
	}

	foreach my $node (@HOSTLIST) {
		if ($node !~ /$HOSTNAME/) {
			if ($sync_list !~ /$node/) {
				$sync_list = $sync_list . "$node\n";
			}
		}
	}
}

if (length($sync_list) > 0) {
	print "\nNode List to sync TFA Certificates : \n";
	print "$sync_list\n";
} else {
	print "\nUnable to determine Node List to be synced. Please update manually.\n";
}

print "\nDo you want to update this node list? [Y|N] [N]: ";
my $userinput = <STDIN>;
chomp($userinput);

if ($userinput eq "y" || $userinput eq "Y") {
	$sync_list = "";

	print "\nPlease Enter all the remote nodes you want to sync...\n";
	print "\nEnter Remote Node List (separated by space) : ";
	my $usernodelist = <STDIN>;
	chomp($usernodelist);

	$usernodelist =~ s/,/\s/g;
	foreach my $node (split /\s/, $usernodelist) {
		if ($node !~ /$HOSTNAME/) {
			$sync_list = $sync_list . "$node\n";
		}
	}

	if (length($sync_list) > 0) {
		print "\nNode List to sync TFA Certificates : \n";
		print "$sync_list\n";
	}
}

if (length($sync_list) == 0) {
	print "\nNode List to sync TFA Certificates is Empty. Exiting Now...\n";
	exit 1;
}

my $SAME = 0 ;
my $COPY_CERT = 0;

# Transferring the generated certificates
if ($IS_WINDOWS) {
	foreach my $node (split /\n/, $sync_list) {
		my $ssh_setup_status = check_ssh_equivalence($node);
		#print "IS SSH SETUP: $ssh_setup_status\n";

		if ($ssh_setup_status != 0) {
			print "Unable to ping Host $node. Please verify.\n";
			next;
		}

		$ping_list = $ping_list . "$node\n";
		print "Syncing TFA Certificates on $node :\n";

		my $remote_tfahome = catfile($TFA_BASE, $node, "tfa_home");
		print "TFA_HOME on $node : $remote_tfahome\n";

		if (-d $remote_tfahome) {
			print "Copying TFA Certificates to $node...\n";
			copy(catfile($TFA_HOME, "server.jks"), catfile($remote_tfahome, "server.jks")) or print "Copy failed: server.jks $!";
			copy(catfile($TFA_HOME, "client.jks"), catfile($remote_tfahome, "client.jks")) or print "Copy failed: client.jks $!";
			copy(catfile($TFA_HOME, "internal", "ssl.properties"), catfile($remote_tfahome, "internal", "ssl.properties")) or print "Copy failed: ssl.properties $!";

			open(my $fptr, '>', catfile($remote_tfahome, "internal", ".initRestartTFA")) or print "Could not create file .initRestartTFA $!";
			close $fptr; 
			$COPY_CERT = 1;
		} elsif ($ssh_setup_status == 0) {
			print "Copying TFA Certificates to $node...\n";
			robocopy(catfile($TFA_HOME, "server.jks"), $TEMP_TRANSFER_DIR);
			robocopy(catfile($TFA_HOME, "client.jks"), $TEMP_TRANSFER_DIR);
			remote_win_copy_without_cred($HOSTNAME, $TEMP_TRANSFER_DIR, $node, $remote_tfahome);
			unlink catfile($TEMP_TRANSFER_DIR, "server.jks");
			unlink catfile($TEMP_TRANSFER_DIR, "client.jks");

			print "Copying SSL Properties to $node...\n";
			robocopy(catfile($TFA_HOME, "internal", "ssl.properties"), $TEMP_TRANSFER_DIR);
			remote_win_copy_without_cred($HOSTNAME, $TEMP_TRANSFER_DIR, $node, catdir($remote_tfahome, "internal"));
			unlink catfile($TEMP_TRANSFER_DIR, "server.jks");	

			print "Shutting down TFA on $node...\n";
			my $remote_cmd = catfile($remote_tfahome, "bin", "tfactl.bat") . " stop";
			my $retVal = win_ssh_without_cred($node, "cmd /c $remote_cmd");
			if ($retVal != 0) {
				print "[ERROR] Unable to stutdown TFA on $node.\n";
			}

			print "Sleeping for 5 seconds...\n";
			sleep(5);

			print "Starting TFA on $node...\n";
			$remote_cmd = catfile($remote_tfahome, "bin", "tfactl.bat") . " start";
			$retVal = win_ssh_without_cred($node, "cmd /c $remote_cmd");
			if ($retVal != 0) {
				print "[ERROR] Unable to start TFA on $node.\n";
			}
		}
	}
} else {

}

if ($COPY_CERT == 1) {
	print "Sleeping for 60 seconds...\n";
	sleep(60);
}

my $cmd = $TFACTL . " print hosts";
my $str = `$cmd`;

# Add Nodes if not already added
my $tfahosts = "";
foreach my $line (split /\n/, $str) {
	$line =~ s/Host Name\s{1,}:\s{1,}//g;
	chomp($line);
	if ($line !~ /$HOSTNAME/) {
		$tfahosts = $tfahosts . "$line\n";
	}
}

foreach my $rhost (split /\n/, $ping_list) {
	if ($tfahosts !~ /$rhost/) {
		print "Trying to add $rhost to TFA...\n";
		my $cmd = $TFACTL . " host add $rhost -silent";
		my $str = `$cmd`;
	}
}

sleep(10);
my $cmd = $TFACTL . " print status";
my $str = `$cmd`;
print "$str\n";

$sync_list = "";
$ping_list = "";

if (-d $TEMP_TRANSFER_DIR) {
	rmtree($TEMP_TRANSFER_DIR);
}

sub robocopy{
  my $source = shift;
  my $destination = shift;

  my $file;
  my $folderName;
  my $newFile;

  if((-f $source) && (-d $destination)){
  $file = basename($source);
  $source = dirname($source);
  $destination = $destination;
  #print "COPY CMD: robocopy $source $destination $file /NFL /NDL /NJH /NJS /nc /ns /np\n";
  system("robocopy $source $destination $file /NFL /NDL /NJH /NJS /nc /ns /np");
  }elsif((-d $source) && (-d $destination)){
  $folderName = basename($source);
  $destination = catdir($destination,$folderName);
  #print "COPY CMD: robocopy $source $destination /MIR /S /E /NFL /NDL /NJH /NJS /nc /ns /np\n";
  system("robocopy $source $destination /MIR /S /E /NFL /NDL /NJH /NJS /nc /ns /np");
  }else{
    $file = basename($source);
    $newFile = basename($destination);
  $source = dirname($source);
  $destination = dirname($destination);
  #print "COPY CMD: robocopy $source $destination $file /NFL /NDL /NJH /NJS /nc /ns /np\n";
  system("robocopy $source $destination $file /NFL /NDL /NJH /NJS /nc /ns /np");
  system("move ".catfile($destination,$file)." ".catfile($destination,$newFile)." > nul");
  }
}

sub remote_win_copy_without_cred{
  my $SrcHost = shift; # Source Host Name
  my $SrcDir  = shift; # Source Directory Path
  my $DstHost = shift; # Destination Host Name
  my $DstDir  = shift; # Destination Directory Path
  my $extra_params = shift; # Extra parmeters if any - Optional
  # Parameters (robocopy keys)
  # my $Params = "/XD * /Z /MIR";
  my $Params = "/S /E /NFL /NDL /NJH /NJS ";

  my @SrcDirPath = split(/:/,$SrcDir);
  my $derivedSrcDir = substr($SrcDir,0,1)."\$".$SrcDirPath[1];

  my @DstDirPath = split(/:/,$DstDir);
  my $derivedDesDir = substr($DstDir,0,1)."\$".$DstDirPath[1];

  my $cmd;
  $cmd = "robocopy.exe \"\\\\$SrcHost\\$derivedSrcDir\" *.* \"\\\\$DstHost\\$derivedDesDir\" $Params $extra_params";
  #print "\n$cmd\n";
  # /NFL /NDL /NJH /NJS /nc /ns /np
  #print "CMD: $cmd\n";
  print `$cmd`;
}

sub win_ssh_without_cred{
  my $host = shift;
  my $remoteCommand = shift;
  my $returnValue = "1"; # 0 means proper execution else improper execution
  my $cmd = "WMIC /node:\"$host\" PROCESS call create \"$remoteCommand\"";
  #print "CMD: $cmd\n";
  my $output = `$cmd`;
  my @lines = split(/\n/,$output);
  foreach my $line (@lines) {
    if (index($line, "ReturnValue") != -1) {
      $returnValue = $line;
      $returnValue =~ s/\D//g;
    }
  }
  return $returnValue;
}

#check if ssh eqivalence is present b/w the nodes of a cluster
sub check_ssh_equivalence{
  my $REMOTE_HOST = shift;
  my $SSH_STATUS="1";

  if($IS_WINDOWS) {
    my $returnValue = win_ssh_without_cred($REMOTE_HOST,"cmd /c dir");
    if("$returnValue" eq "0"){
      $SSH_STATUS = "0";
    }
  }else{
    # $SSH -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -l $SSH_USER $REMOTE_HOST ls > /dev/null 2>&1
    # SSH_STATUS=$?
  }
  return $SSH_STATUS;
}

sub getUserName {
	my $username;
	if ( $IS_WINDOWS ) {
		if(Win32::IsAdminUser()){
	    	$username = "root";
	    } else {
			$username = getlogin;
			my $domainName = `echo %userdomain%`;
			$domainName = trim($domainName);
			if($domainName ne ""){
				$username = $domainName."\\".$username;
			}
	    }
	} else {
		$username = (getpwuid($<))[0];
	}
	return $username;
}

sub getEscapedUserName {
	my $user = shift;

	if (index($user,"\\")!=-1) {
		$user =~ s/\\/__/g;
	}

	return $user;
} 

sub tolower_host
{
    my $host = hostname () or return "";

    # If the hostname is an IP address, let hostname remain as IP address
    # Else, strip off domain name in case /bin/hostname returns FQDN
    # hostname
    my $shorthost;
    if ($host =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
        $shorthost = $host;
    } else {
        ($shorthost,) = split (/\./, $host);
    }

    # convert to lower case
    $shorthost =~ tr/A-Z/a-z/;

    die "Failed to get non-FQDN host name for " if ($shorthost eq "");

    return $shorthost;
}

sub printHelp {
	print "\nUsage: 

	This will generate and copy TFA Certificates to other TFA Nodes
		   
	$SCRIPT [-regenerate] [-help]
		     
	-regenerate 	- Regenerate TFA Certificates\n";	
}


# Queries the registry for a key under Oracle Parent key to get its corresponding value
# Parameter - $key - registry key
# Return - value for required registry key
sub win_query_registry{
  my $key =shift;
  my $unfilterResultFlag = shift;

  my $BASE_KEY="HKEY_LOCAL_MACHINE\\SOFTWARE\\Oracle";
  my $result="";

  my $type = trimString(win_check_os_type());
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
sub win_check_os_type{
  my $type =`IF EXIST "%PROGRAMFILES(X86)%" (ECHO 64BIT) ELSE (ECHO 32BIT)`;
  return $type;
}

sub trimString{
   my $str = $_;
   $str = shift;
   $str =~ s/^\s+//;
   $str =~ s/\s+$//;
   return $str ;
}

## CONVERSION OF BASIC SHELL COMMANDS

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
