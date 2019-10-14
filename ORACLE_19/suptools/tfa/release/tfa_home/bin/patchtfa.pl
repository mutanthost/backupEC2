# 
# $Header: tfa/src/v2/tfa_home/bin/patchtfa.pl /st_tfa_19/1 2019/03/02 06:01:52 cnagur Exp $
#
# patchtfa.pl
# 
# Copyright (c) 2015, 2019, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      patchtfa.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bibsahoo    01/31/19 - commons-io upgrade to version 2.6
#    recornej    08/09/18 - Add dbversions.json to the patching.
#    recornej    10/27/17 - Remove extra )
#    bburton     10/26/17 - Fix patching oraclepki
#    bburton     10/25/17 - fix )) and oraclepki jars
#    bburton     09/28/17 - set a variable to ensure tfactl commands do not
#                           state age limit whilst patching
#    bburton     08/28/17 - bug26696360 - windows hyphen in hostname
#    bibsahoo    07/26/17 - FIX BUG 26536025
#    bibsahoo    07/17/17 - FIX BUG 26474638
#    bibsahoo    06/08/17 - TFA PATCHING ON WINDOWS
#    bibsahoo    05/18/17 - FIX BUG 26093490
#    bburton     05/08/17 - ReadKey Not required
#    cnagur      04/19/17 - Remove tfar.jar - Bug 25915789
#    amchaura    02/25/16 - Upgrade BDB version to 6.4.25
#    arupadhy    01/22/16 - refactored windows process management functions
#    cnagur      01/14/16 - Changes for Java 8
#    arupadhy    01/10/16 - Added registry key AUTO_START for enable/disable,
#                           and auto reboot support for TFAService.exe if it
#                           stops by any reason.
#    arupadhy    11/26/15 - Creation
# 
use strict;
use English;
use File::Spec::Functions;
use File::Find qw(finddepth);
use File::Path;
use Cwd            qw( abs_path cwd );
use File::Basename qw( dirname basename );
use File::Copy;
use Getopt::Long qw(GetOptions);
use Sys::Hostname;
use Win32;
use POSIX qw(strftime);

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME);
  push @INC, dirname($PROGRAM_NAME).'/common';
}

use tfactlwin;

#set variable to suppress age warning on patching

$ENV{'TFA_SUPPRESS_AGE_WARN'}="TRUE";

my $UNAME=$^O;
my $PLATFORM=$UNAME;
my $PERL;
my $RM;
my $MV;
my $TOUCH;
my $CP;

my $LOGFILE;

my $TMPLOC="C:\\TMP";
if(!-d $TMPLOC){
	mkpath([catdir($TMPLOC)]);
}

my $RUSER = getActualUserName();

my $IS_WINDOWS=0;
if ( $^O eq "MSWin32" ){
	$IS_WINDOWS = 1;
	$RM = "del";
	$MV = "move";
	$TOUCH = "type NUL >";
}else{
	chomp( $RM  = qx(which rm));
	chomp( $MV  = qx(which mv));
	chomp( $TOUCH = qx(which touch));
	chomp( $CP  = qx(which cp));
}

my $ECHO = "echo";

#if ($IS_WINDOWS)
#{
#  eval q{use Term::ReadKey; 1} or die $@;
#}

my %rmsshlist;

### Configure Values ####
my $oracleTFAServiceName = "OracleTFAService";
my $SSH_USER = "root";
my $TFA_INSTALLER = $ENV{'TFA_INSTALLER'};
### Configure Values ####

#### Utility Functions #####

sub sleepdots{
	my $sleeptime=shift;
	my $count=0;

	while($count < $sleeptime){
		print ".";
		sleep 1;
		$count=$count + 1;
	}
	print "\n";
}

# Queries the registry for the path of TFA Home available due to existing installation
# Returns : TFA Home path 
sub getTFAHomeFromPreviousConfig {
	my $TFA_HOME="";
	my $result = tfactlwin_query_registry("tfa_home");
  	my @lines = split(/\n/,$result);
  	foreach my $line (@lines){
		my @tokens = split(/\s+/,$line);
		my $tokenArrLength = scalar @tokens;
		if($tokenArrLength>=4){
			$TFA_HOME=trim($tokens[3]);
		}
	}
	return $TFA_HOME;
}

# Prvoides the value of a particular parameter in config file
# Parameter - $configfile - path to config file, $parameter - key
# Return - value for required config key
sub getConfigValue {

	my $configfile = shift;
	my $parameter = shift;
	my $value;
	my $line;

	open ( CONFIG, "<$configfile" );

	while ( <CONFIG> ) {
		$line = $_;

		if ( $line =~ /^$parameter=(.*)/ ) {
			$value = $1;
			last;
		}
	}

	close ( CONFIG );

	return $value;
}

# Cleans all files in a folder
sub cleanDir {
	my $dir = shift;
	
	if (! -d $dir) {
		mkpath($dir);
	} else {
		rmtree($dir);
		mkpath($dir);
	}
	
	return;
}

# Provides the path to parent directory
# Parameters: current directory
# Returns : path to parent directory
sub getParentDirectory{
  my @dirs   = File::Spec->splitdir($_[0]);       # parse directories
  pop @dirs;                                      # remove top dir
  my $newdir = File::Spec->catdir(@dirs);         # create new path
  return $newdir;
}

# Provides list of all nodes other than localnode
# Parameters: $tfa_home - path to TFA Home
# Returns : list of nodes
sub getListOfOtherNodes {
	my $TFA_HOME = shift;
	my $LOCALHOST = tolower_host();

	my $tfaexe = catfile($TFA_HOME,"bin","tfactl");
	my @NODES;
	my $NODE;
	my $TFA_HOSTS;

	$TFA_HOSTS = qx($tfaexe print hosts);

	my @lines = split(/\n/,$TFA_HOSTS);
	@lines = grep{/Host Name :/} @lines;

	foreach my $line (@lines) {
	  my @tokens = split(/Host Name :/,$line);
	  my $node = trim($tokens[1]);
	  if($LOCALHOST ne $node){
	  	push @NODES, trim($tokens[1]);
	  }
	}
	return @NODES;
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

# Provides list of all nodes
# Parameters: $tfa_home - path to TFA Home
# Returns : list of nodes
sub getListOfAllNodes {

        my $TFA_HOME = shift;
		my $tfaexe = catfile($TFA_HOME,"bin","tfactl");
		my @NODES;
        my $NODE;
		my $TFA_HOSTS;

        $TFA_HOSTS = qx($tfaexe print hosts);

		my @lines = split(/\n/,$TFA_HOSTS);
		@lines = grep{/Host Name :/} @lines;

		foreach my $line (@lines) {
		  my @tokens = split(/Host Name :/,$line);
		  push @NODES, trim($tokens[1]);
		}

        return @NODES;
}

sub getFileContent{
	my $file = shift;

	my $string;
	{
	    local $/;
	    open my $fh, '<', $file or print "can't open $file: $!";
	    $string = <$fh>;
	}

	return $string;
}

sub get_valid_input
{
  my $ip = shift;
  my $str_to_check = shift;
  my $default_on_empty = shift;
  my $valid_input = 0;
  my @valid_inputs = split(/\|/, $str_to_check);
  my ( $str2 );

  while ( $valid_input == 0 )
  {
    foreach $str2 (@valid_inputs)
    {
      if ( $ip eq $str2 )
      {
        $valid_input = 1;
        return $ip;
      }
    }
    print "Invalid input. Please enter again : $str_to_check [$default_on_empty]\n";
    $ip = <STDIN>;
    chomp($ip);
    $ip = $default_on_empty if ( ! $ip );
  }
}

sub trim{
   my $str = $_;
   $str = shift;
   $str =~ s/^\s+//;
   $str =~ s/\s+$//;
   return $str ;
}

sub shutdown_remoteTFAService{
	my $host = shift;
	my $tfa_home = shift;

	my $command = "sc stop OracleTFAService";
	win_ssh_without_cred($host,"cmd /c $command");

	$command = "wmic Path win32_process Where \\\"CommandLine Like '%TFAService.exe%'\\\" Call Terminate";
	win_ssh_without_cred($host,"cmd /c $command");
	
	#Stop Remote TFA
	$command = catfile($tfa_home,"bin","tfactl")." -initstop";
	win_ssh_without_cred($host,"cmd /c $command");

}

sub win_ssh{
	my $host = shift;
	my $user = shift;
	my $pass  = shift;
	my $remoteCommand = shift;
	my $returnValue = "1"; # 0 means proper execution else improper execution
	my $cmd = "WMIC /user:$user /Password:$pass /node:\"$host\" PROCESS call create \"$remoteCommand\"";
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

sub win_ssh_without_cred{
	my $host = shift;
	my $remoteCommand = shift;
	my $returnValue = "1"; # 0 means proper execution else improper execution
	my $cmd = "WMIC /node:\"$host\" PROCESS call create \"$remoteCommand\"";
	#print "CMD: $cmd\n";
	my $output = `$cmd`;
	#print "OP: $output\n";
	my @lines = split(/\n/,$output);
	foreach my $line (@lines) {
		if (index($line, "ReturnValue") != -1) {
			$returnValue = $line;
			$returnValue =~ s/\D//g;
		}
	}

	return $returnValue;
}

sub copy_files_with_pattern{
	my $source =shift;
	my $pattern =shift;
	my $destination =shift;

	my $cmd;
	if($IS_WINDOWS){
		$cmd = "robocopy $source $pattern $destination  /NFL /NDL /NJH /NJS /nc /ns /np";
	}else{
		$cmd = "$CP -rf $source/$pattern $destination/";
	}
	system($cmd);
}

sub getActualUserName {
	my $username;
	$username = getlogin;
	return $username;
}

sub check_ssh_equivalence_with_cred{
	my $REMOTE_HOST = shift;
	my $PASS = shift;

	my $SSH_STATUS="1";

	if($IS_WINDOWS){
		my $returnValue = win_ssh($REMOTE_HOST,$RUSER,$PASS,"cmd /c dir");
		if("$returnValue" eq "0"){
			$SSH_STATUS = "0";
		}
		# Creating equivalence
		my $cmd;
		$cmd = "NET USE \\\\$REMOTE_HOST\\IPC\$ /u:$RUSER $PASS";
		print `$cmd`;
	}else{
		# $SSH -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -l $SSH_USER $REMOTE_HOST ls > /dev/null 2>&1
		# SSH_STATUS=$?
	}
	return $SSH_STATUS;
}

sub get_password_from_user{
	my $REMOTE_HOST = shift;
	my $PASS;
	my $counter = 0;
	
	print "\n";
	print "Please Enter the password for $REMOTE_HOST : \n";
	tfactldiagnostics_readMode(0);
	$PASS = <STDIN>;
	chomp $PASS;
	tfactldiagnostics_readMode(1);
	my $SSH_STATUS = check_ssh_equivalence_with_cred($REMOTE_HOST,$PASS);
	print "\n";
	while(!($SSH_STATUS eq "0")){
		print "\n";
		print "Password is incorrect ! Please try again.\n";
		print "Please Enter the password for $REMOTE_HOST : \n";
		tfactldiagnostics_readMode(0);
		$PASS = <STDIN>;
		chomp $PASS;
		tfactldiagnostics_readMode(1);
		$SSH_STATUS = check_ssh_equivalence_with_cred($REMOTE_HOST,$PASS);
		$counter = $counter +1;
		if($counter>3){
			last;
		}
	}

	if($counter>3){
		$PASS = "";
	}
	
	return $PASS;
}

sub store_password_non_ssh{
	my $REMOTE_HOST = shift;
	my $PASS = get_password_from_user($REMOTE_HOST);
	if($PASS!=""){
		rmsshlist{$REMOTE_HOST}=$PASS;
	}
}

sub remove_password_non_ssh{
	foreach my $key (keys %rmsshlist) {
	    my $DstHost = $key;
	    my $PASS = $rmsshlist{$key};
	    my $cmd = "NET USE \\\\$DstHost\\IPC\$ /D";
		print `$cmd`;
	}
}

sub find_and_replace{
	my $str = shift;
	my $find = shift;
	my $replace = shift;
	$find = quotemeta $find; # escape regex metachars if present

	$str =~ s/$find/$replace/g;
	return $str;
}

sub chmodAddPerm{
  my $modifiedPermission = shift;
  my $filename = shift;
  
  my $mode = (stat($filename))[2];
  $mode = $mode &07777;
  my $new_mode = $mode | $modifiedPermission;
  chmod ($new_mode, $filename);
}

sub getRecursiveFolderContents{
  my $dir = shift;
  my @files;
  finddepth(sub {
    return if($_ eq '.' || $_ eq '..');
    push @files, $File::Find::name;
  }, $dir);
  return @files;
}

sub printLog {
	my $logStr = shift;
	my $loglevel = shift;

	open(my $fptr, '>>', $LOGFILE) or print "Could not open file $LOGFILE: $!";
	if ($loglevel == 1) {		
		print $fptr "$logStr";
	} elsif ($loglevel == 2) {
		print "$logStr";
	} else {
		print $fptr "$logStr";
		print "$logStr";
	}
	close($fptr);
}

#### Utility Functions #####

my $SCRIPT=$0;

my $tfa_home; my $CRS_HOME; my $PERL; my $tfabase;
my $e_tfabase; my @tfahosts; my $host_count; my $keystoresupdated;
my $ORACLE_BASE; my $curr_work_dir; my $SSH_STATUS;

my $SILENT=0;
my $LOCAL=0;

GetOptions(
	'-silent' => \$SILENT,
	'-local' => \$LOCAL,
	'-cwd=s' => \$curr_work_dir,
	'-log=s' => \$LOGFILE
	);

printLog("\n");

if(!tfactlwin_isTFAServiceIsConfigured()){
	printLog("TFA is not setup\n");

	open(my $fptr, '>', catfile($TMPLOC,".tfa.patch")) or die "Could not open file ".catfile($TMPLOC,".tfa.patch")." $!";
	print $fptr "1";
	close($fptr);

	exit 1;
}

$tfa_home=getTFAHomeFromPreviousConfig();

if(-f catfile($tfa_home,"tfa_setup.txt")){
	$CRS_HOME=getConfigValue(catfile($tfa_home,"tfa_setup.txt"),"CRS_HOME");
	if(-d $CRS_HOME){
		$PERL = getConfigValue(catfile($tfa_home,"tfa_setup.txt"),"PERL");
	}
}

my $HOSTNAME=hostname;

$tfabase=getParentDirectory(catdir($tfa_home));

#Check if TFA HOME contains HOSTNAME
if (index($HOSTNAME, $tfa_home) != -1) {
	$tfabase=getParentDirectory(catdir($tfa_home));
}

$e_tfabase=$curr_work_dir;

# If its a local patch then don't check the status of TFA in other nodes.

if($LOCAL == 0){
	@tfahosts=getListOfOtherNodes($tfa_home);
	my @allhosts = getListOfAllNodes($tfa_home);
	$host_count=scalar @allhosts;

	if($host_count == 0){
		printLog("Unable to determine the status of TFA in other nodes.\n");
		$LOCAL=1;
	}
	
	# If TFA is installed only on one Node then do local patch.
	if($host_count == 1){
		$LOCAL=1;
	}
}

if($LOCAL == 1){
	printLog("TFA will be Patched on Node $HOSTNAME:\n");
}else{
	printLog("TFA will be Patched on: \n");
	printLog("$HOSTNAME\n");
	foreach my $REMOTE_NODE ( @tfahosts ) {
		printLog("$REMOTE_NODE ");
	}
}

printLog("\n");

if($SILENT == 0){
	my $option;
	printLog("\n");
	printLog("Do you want to continue with patching TFA? [Y|N] [Y]: ");
	chomp( $option = <STDIN> );
	$option ||= "Y";
	$option = get_valid_input ($option, "y|Y|n|N", "Y");

	if ( $option =~ /[Nn]/ ) {
		printLog("\n");
        printLog("Exiting from TFA Patching now.\n");

		open(my $fptr, '>', catfile($TMPLOC,".tfa.patch")) or die "Could not open file ".catfile($TMPLOC,".tfa.patch")." $!";
		print $fptr "2";
		close($fptr);

        exit 2;
	}
}

my $INSTALLED_BUILD=0;
my $INSTALLED_BLDDT=0;
my $INSTALLED_BLDVR=0;

my $buildIdFile = catfile($tfa_home,"internal",".buildid");
if(-f $buildIdFile){
	$INSTALLED_BUILD= trim(getFileContent($buildIdFile));

	# Extract Installed Build Version and Date
	my $INSTALLED_BLDDT=substr($INSTALLED_BUILD, -14);
	my $INSTALLED_BLDVR=substr($INSTALLED_BUILD, 0, -14);

	# Get Build Version from .buildversion
	my $buildVersionFile = catfile($tfa_home,"internal",".buildversion");
	if( -f $buildVersionFile ){
		$INSTALLED_BLDVR=trim(getFileContent($buildVersionFile));
	}
	
	# If Installed version is null then set it to 0
	if(defined($INSTALLED_BLDVR) && ($INSTALLED_BLDVR ne '')){
		$INSTALLED_BLDVR=0;
	}
}

my $ssh_list = "";
my $nonssh_list = "";
my $socket_list = "";

if($LOCAL == 0){
	foreach my $host ( @tfahosts ) {
		printLog("\n");
		printLog("Checking for ssh equivalency in $host\n");

		if($host ne "$HOSTNAME"){
			$SSH_STATUS = tfactlwin_check_ssh_equivalence($host);
			printLog("SSH_STATUS : $SSH_STATUS\n",1);
			
			if("$SSH_STATUS" eq "0"){
				printLog("$host is configured for ssh user equivalency for $SSH_USER user\n");
				$ssh_list = $ssh_list . $host . "\n";
			}else{
				printLog("Node $host is not configured for ssh user equivalency\n");
				$nonssh_list = $nonssh_list . $host . "\n";
			}
		}
	}
	printLog("\n");
} #LOCAL IF

# SSH Setup
if(($LOCAL == 0) && ($SILENT == 0) && (length($nonssh_list) != 0) ){
	printLog("SSH is not configured on these nodes : \n");
	printLog("$nonssh_list\n");

	printLog("\n");
	my $option;
	printLog("\n");
	printLog("Do you want to configure SSH on these nodes ? [Y|N] [Y]: ");
	chomp( $option = <STDIN> );
	$option ||= "Y";
	$option = get_valid_input ($option, "y|Y|n|N", "Y");

	if ( $option =~ /[Nn]/ ) {
		my @hosts = ();
		my @lines = split(/\n/,$nonssh_list);
		foreach my $line (@lines) {
			if($line ne ""){
				push @hosts, trim($line);
			}
		}
		foreach my $host ( @hosts ) {
			printLog("\n");
			printLog("Configuring SSH on $host...\n");
			printLog("\n");
			# Get passwords for nodes which do not have ssh equivalency and store them in 
			# an associative array while checking the passwords are actually correct
			store_password_non_ssh($host);
			$ssh_list = $ssh_list . $host . "\n";
		}

		# Remove Non-SSH List
		$nonssh_list = "";
	}else{
		printLog("\n");
		# Use TFA Installer to patch remote nodes
		if(defined($TFA_INSTALLER) && ($TFA_INSTALLER ne '')){
			printLog("Patching remote nodes using TFA Installer $TFA_INSTALLER...\n");
		}else{
			printLog("Patching only on local node...\n");
			$LOCAL=1;
			$nonssh_list = "";
		}
	}
	printLog("\n");
}

# Get the TFA BDB 
my $BDB_DIR=catdir($tfa_home,"database");
my $INSTALL_TYPE="TYPICAL";
my $LOG_DIR;

if(-f catfile($tfa_home,"tfa_setup.txt")){
	$ORACLE_BASE=getConfigValue(catfile($tfa_home,"tfa_setup.txt"),"ORACLE_BASE");
	$INSTALL_TYPE=getConfigValue(catfile($tfa_home,"tfa_setup.txt"),"INSTALL_TYPE");
	
	if(defined($ORACLE_BASE) && ($ORACLE_BASE ne '')){
		if ($INSTALL_TYPE eq "GI") {
			if(defined($ORACLE_BASE) && ($ORACLE_BASE ne '')){
				$BDB_DIR=catdir($ORACLE_BASE,"tfa",$HOSTNAME,"database");
				$LOG_DIR=catdir($ORACLE_BASE,"tfa",$HOSTNAME,"log");
			}
		}
	}
}

my $BDB_HOME;
if(-d $BDB_DIR){
	$BDB_HOME=catdir($BDB_DIR,"BERKELEY_JE_DB");
}

#Get JAVA HOME
my $TFA_JHOME;
if(-d catdir($tfa_home,"jre")){
	$TFA_JHOME = catdir($tfa_home,"jre");
}elsif(-f catfile($tfa_home,"tfa_setup.txt")){
	$TFA_JHOME=getConfigValue(catfile($tfa_home,"tfa_setup.txt"),"JAVA_HOME");

	if(defined($TFA_JHOME) && ($TFA_JHOME ne '')){
		#Get JAVA_HOME from TFA_BASE/java_install.out
		if(-f catfile($tfabase,$HOSTNAME,"java_install.out")){
			$TFA_JHOME=getConfigValue(catfile($tfabase,$HOSTNAME,"java_install.out"),"JAVA_HOME");
		}
	}
}

my $JAVA;
if(-d $TFA_JHOME){
	$JAVA=catdir($TFA_JHOME,"bin","java");
}

my $temp_tfahome;

if(! -f catfile($tfa_home,"server.jks")){
	if($INSTALL_TYPE eq "GI"){
		if($LOCAL == 0){
			$temp_tfahome = catdir($e_tfabase,"tfa_home");
			my $cmd = "$PERL ".catfile($e_tfabase,"tfa_home","bin","tfactl.pl")." generatecerts $temp_tfahome $TFA_JHOME 1";
			qx($cmd);
		}
	}else{
		$temp_tfahome = catdir($e_tfabase,"tfa_home");
		my $cmd = "$PERL ".catfile($e_tfabase,"tfa_home","bin","tfactl.pl")." generatecerts $temp_tfahome $TFA_JHOME 1";
		qx($cmd);
	}
}

# Create zip or tar if not local
my $zipfile;
if($LOCAL == 0){
	if(defined($CRS_HOME) && ($CRS_HOME ne '')){
		my $ZIP = catfile($CRS_HOME,"bin","zip.exe");
		$zipfile= catfile($tfa_home,"internal","tfapatch.zip");
		printLog("Creating ZIP: $zipfile\n");
		my $cmd = "$ZIP -r -q $zipfile ".catdir($e_tfabase,"tfa_home","jlib")." ".catdir($e_tfabase,"tfa_home","bin")." ".catdir($e_tfabase,"tfa_home","resources")." ".catdir($e_tfabase,"tfa_home","ext")." ".catdir($e_tfabase,"tfa_home","install")." ".catfile($e_tfabase,"tfa_home","internal","usableports.txt")." ".catfile($e_tfabase,"tfa_home","internal",".buildid")." ".catfile($e_tfabase,"tfa_home","internal",".buildversion")." ".catfile($e_tfabase,"tfa_home","internal","config.properties")." ".catfile($e_tfabase,"tfa_home","tfa.jks")." ".catfile($e_tfabase,"tfa_home","public.jks")." ".catfile($e_tfabase,"tfa_home","server.jks")." ".catfile($e_tfabase,"tfa_home","client.jks")." ".catfile($e_tfabase,"tfa_home","internal","ssl.properties")." ".catfile($e_tfabase,"tfa_home","internal","rconfig.properties")." ".catfile($e_tfabase,"tfa_home","tfa_directories.txt")." ".catfile($e_tfabase,"tfa_home","internal","timezones_mapping")." ".catfile($e_tfabase,"tfa_home","internal","dbversions.json");
		qx($cmd);
	}else{
		printLog("Unable to locate Zip Utility.\n");
	}
}

# If SSH equivalency present then we use SSH to patch TFA to remote nodes.
my $TFA_HOME; 
my $command; 
my $REMOTE_BDB_HOME; 
my $REM_JHOME;
my $REM_JAVA;
my $REM_JAR_DIR;
my $REM_JLIB_DIR;
my $REM_OB_OUT_DIR;
my $REM_TFA_OUT_DIR;

if(($LOCAL == 0) && (length($ssh_list) != 0)){
	printLog("\n");
	printLog("Using SSH to patch TFA to remote nodes :\n");

	my @hosts = ();
	my @lines = split(/\n/,$ssh_list);
	foreach my $line (@lines) {
		if($line ne ""){
			push @hosts, trim($line);
		}
	}
	foreach my $host ( @hosts ) {
		printLog("\n");
		printLog("Applying Patch on $host:\n");
		printLog("\n");
		
		$TFA_HOME=$tfa_home;

		# if tfa_home in local host contains hostname, then the tfa_home in 
		# remote node will also contain hostname

		if ($tfa_home =~ /$HOSTNAME/) {
			$TFA_HOME =~ s/$HOSTNAME/$host/g;
			printLog("TFA_HOME: $TFA_HOME\n");
		}
		
		# Stop TFA Tools first
		printLog("\nStopping TFA Support Tools...\n");
		$command = catfile($TFA_HOME,"bin","tfactl")." stop_suptools";
		win_ssh_without_cred($host,"cmd /c $command");

		printLog("Shutting down TFA for Patching...\n");
		#shutdown_remoteTFAService($host,$TFA_HOME);
		tfactlwin_ssh_without_cred($host, "cmd /c $PERL ".catfile($TFA_HOME, "bin", "tfaosutils.pl")." configureTFA stop ".$TFA_HOME);
	      	
		printLog("Sleeping for 10 Seconds...\n");
		sleep(10);

		printLog("Copying files from $HOSTNAME to $host...\n");

		#TFA BDB on Remote Node:
		if ($BDB_HOME =~ /$HOSTNAME/) {
			$REMOTE_BDB_HOME = $BDB_HOME;
			$REMOTE_BDB_HOME =~ s/$HOSTNAME/$host/g;
		}

		printLog("BDB_HOME: $BDB_HOME\nREMOTE_BDB_HOME: $REMOTE_BDB_HOME\n",1);

		#TFA JAVA on Remote Node:
		if ($TFA_JHOME =~ /$HOSTNAME/) {
			$REM_JHOME = $TFA_JHOME;
			$REM_JHOME =~ s/$HOSTNAME/$host/g;
			if ($IS_WINDOWS) {
				$REM_JAVA=catfile($REM_JHOME,"bin","java.exe");
			} else {
				$REM_JAVA=catfile($REM_JHOME,"bin","java");
			}
		}
		
		printLog("REM_JAVA: $REM_JAVA\n",1);

		# Changes for Patching 11204 to 12c in Remote Node using SSH
		$REM_JAR_DIR = catdir($TFA_HOME, "jar");
		$REM_JLIB_DIR = catdir($TFA_HOME, "jlib");
		$REM_OB_OUT_DIR = catdir($ORACLE_BASE, "tfa", $host);
		$REM_TFA_OUT_DIR = catdir($TFA_HOME, "output");

		printLog("REM_JAR_DIR: $REM_JAR_DIR\nREM_JLIB_DIR: $REM_JLIB_DIR\nREM_OB_OUT_DIR: $REM_OB_OUT_DIR\nREM_TFA_OUT_DIR: $REM_TFA_OUT_DIR\n",1);

		my $temp_transfer_dir = catdir($e_tfabase,"tfa_home","tmp_transfer");
		if (! -d $temp_transfer_dir) {
			mkpath($temp_transfer_dir);
		}

		cleanDir($temp_transfer_dir);
		tfactlwin_robocopy(catfile($e_tfabase,"tfa_home","jlib","RATFA.jar"),$temp_transfer_dir);
		tfactlwin_robocopy(catfile($e_tfabase,"tfa_home","jlib","oraclepki.jar"),$temp_transfer_dir);
		tfactlwin_robocopy(catfile($e_tfabase,"tfa_home","jlib","ojmisc.jar"),$temp_transfer_dir);
		tfactlwin_robocopy(catfile($e_tfabase,"tfa_home","jlib","ojpse.jar"),$temp_transfer_dir);
		tfactlwin_robocopy(catfile($e_tfabase,"tfa_home","jlib","osdt_cert.jar"),$temp_transfer_dir);
		tfactlwin_robocopy(catfile($e_tfabase,"tfa_home","jlib","osdt_core.jar"),$temp_transfer_dir);
		tfactlwin_robocopy(catfile($e_tfabase,"tfa_home","jlib","owm-3_0.jar"),$temp_transfer_dir);
		tfactlwin_robocopy(catfile($e_tfabase,"tfa_home","jlib","je-*.jar"),$temp_transfer_dir);
		tfactlwin_robocopy(catfile($e_tfabase,"tfa_home","jlib","commons-io-2.6.jar"),$temp_transfer_dir);
		tfactlwin_remote_win_copy_without_cred($HOSTNAME,$temp_transfer_dir,$host,catdir($TFA_HOME,"jlib"));

		cleanDir($temp_transfer_dir);
		tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","bin"),$temp_transfer_dir);
		tfactlwin_remote_win_copy_without_cred($HOSTNAME,$temp_transfer_dir,$host,$TFA_HOME);

		cleanDir($temp_transfer_dir);
		tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","resources"),$temp_transfer_dir);
		tfactlwin_remote_win_copy_without_cred($HOSTNAME,$temp_transfer_dir,$host,$TFA_HOME);

		cleanDir($temp_transfer_dir);
		tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","ext"),$temp_transfer_dir);
		tfactlwin_remote_win_copy_without_cred($HOSTNAME,$temp_transfer_dir,$host,$TFA_HOME);

		cleanDir($temp_transfer_dir);
		tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","install"),$temp_transfer_dir);
		tfactlwin_remote_win_copy_without_cred($HOSTNAME,$temp_transfer_dir,$host,$TFA_HOME);

		cleanDir($temp_transfer_dir);
		tfactlwin_robocopy(catfile($e_tfabase,"tfa_home","internal","usableports.txt"),$temp_transfer_dir);
		tfactlwin_robocopy(catfile($e_tfabase,"tfa_home","internal","config.properties"),catfile($temp_transfer_dir,"config.properties.bkp"));
		tfactlwin_robocopy(catfile($e_tfabase,"tfa_home","internal","timezones_mapping"),catfile($temp_transfer_dir,"timezones_mapping.bkp"));
		tfactlwin_robocopy(catfile($e_tfabase,"tfa_home","internal","dbversions.json"),$temp_transfer_dir);
		tfactlwin_remote_win_copy_without_cred($HOSTNAME,$temp_transfer_dir,$host,catdir($TFA_HOME,"internal"));

		cleanDir($temp_transfer_dir);
		tfactlwin_robocopy(catfile($e_tfabase,"tfa_home","tfa.jks"),$temp_transfer_dir);
		tfactlwin_robocopy(catfile($e_tfabase,"tfa_home","public.jks"),$temp_transfer_dir);
		tfactlwin_remote_win_copy_without_cred($HOSTNAME,$temp_transfer_dir,$host,$TFA_HOME);

		if (! -f catfile($tfa_home, "server.jks")) {
			cleanDir($temp_transfer_dir);
			tfactlwin_robocopy(catfile($e_tfabase,"tfa_home","server.jks"),$temp_transfer_dir);
			tfactlwin_robocopy(catfile($e_tfabase,"tfa_home","client.jks"),$temp_transfer_dir);
			tfactlwin_remote_win_copy_without_cred($HOSTNAME,$temp_transfer_dir,$host,$TFA_HOME);
			cleanDir($temp_transfer_dir);
			tfactlwin_robocopy(catfile($e_tfabase,"tfa_home","internal", "ssl.properties"),$temp_transfer_dir);
			tfactlwin_remote_win_copy_without_cred($HOSTNAME,$temp_transfer_dir,$host,catdir($TFA_HOME,"internal"));
		}

		cleanDir($temp_transfer_dir);
		tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","tfa_directories.txt"),catfile($temp_transfer_dir, "tfa_directories.txt.bkp"));
		tfactlwin_remote_win_copy_without_cred($HOSTNAME,$temp_transfer_dir,$host,$TFA_HOME);

		my $rem_command;

		# BDB Upgrade on remote nodes
		cleanDir($temp_transfer_dir);
		tfactlwin_remote_win_copy_without_cred($host,catfile($TFA_HOME,"jlib"),$HOSTNAME,$temp_transfer_dir);
		if (-e catfile($temp_transfer_dir, "je-4.0.103.jar")) {
			printLog("Current version of Berkeley DB is 4.0.103 in $host\nRunning DbPreUpgrade_4_1 utility\n");
			$rem_command = "$REM_JAVA -jar " . catfile($TFA_HOME,"jlib","je-4.1.27.jar") . " DbPreUpgrade_4_1 -h $REMOTE_BDB_HOME 2>&1";
			win_ssh_without_cred($host,"cmd /c $rem_command");
		} else {
			printLog("Current version of Berkeley DB in $host is 5 or higher, so no DbPreUpgrade required\n");
		}

		printLog("REMOTE PERL: $PERL\n",1);

		$rem_command = "$PERL $TFA_HOME/bin/tfactl.pl updatepropertiesfile 2>&1";
		win_ssh_without_cred($host,"cmd /c $rem_command");

		$rem_command = "$PERL $TFA_HOME/bin/tfactl.pl updatedirectoriesfile 2>&1";
		win_ssh_without_cred($host,"cmd /c $rem_command");

		$rem_command = "$PERL $TFA_HOME/bin/tfactl.pl updateautodiagcollect 2>&1";
		win_ssh_without_cred($host,"cmd /c $rem_command");

		cleanDir($temp_transfer_dir);
                #TODO BS/CN need to verify syncpatch on windows.
		tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","internal",".buildid"),catfile($temp_transfer_dir, ".buildid.bkp"));
		tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","internal",".buildid"),catfile($temp_transfer_dir, ".buildid"));
		tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","internal",".buildversion"),catfile($temp_transfer_dir, ".buildversion.bkp"));
		tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","internal",".buildversion"),catfile($temp_transfer_dir, ".buildversion"));
		tfactlwin_remote_win_copy_without_cred($HOSTNAME,$temp_transfer_dir,$host,catdir($TFA_HOME,"internal"));

		printLog("Running commands to fix init.tfa and tfactl in $host...\n");
		$rem_command = "$PERL $TFA_HOME/bin/tfactl.pl fixInitTfa 2>&1";
		win_ssh_without_cred($host,"cmd /c $rem_command");
		$rem_command = "$PERL $TFA_HOME/bin/tfactl.pl fixTfactl 2>&1";
		win_ssh_without_cred($host,"cmd /c $rem_command");
		$rem_command = "$PERL $TFA_HOME/bin/tfactl.pl copytfactl 2>&1";
		win_ssh_without_cred($host,"cmd /c $rem_command");

		printLog( "Starting TFA in $host...\n");
		#$rem_command = "$TFA_HOME/bin/tfactl -initstart 2>&1";
		#win_ssh_without_cred($host,"cmd /c $rem_command");
		tfactlwin_ssh_without_cred($host, "cmd /c $PERL ".catfile($TFA_HOME, "bin", "tfaosutils.pl")." configureTFA start ".$TFA_HOME);

		printLog("Sleeping for 10 Seconds...\n");
		sleep(10);

		cleanDir($temp_transfer_dir);
		tfactlwin_remote_win_copy_without_cred($host,catfile($TFA_HOME,"jlib"),$HOSTNAME,$temp_transfer_dir);
		if (-e catfile($temp_transfer_dir, "je-4.0.103.jar")) {
			printLog("Removing " . catfile($TFA_HOME,"jlib","je-4.0.103.jar") . "\n");
			$rem_command = "$RM " . catfile($TFA_HOME,"jlib","je-4.0.103.jar");
			win_ssh_without_cred($host,"cmd /c $rem_command");
		} 

		if (-e catfile($temp_transfer_dir, "je-5.0.84.jar")) {
			printLog("Removing " . catfile($TFA_HOME,"jlib","je-5.0.84.jar") . "\n");
			$rem_command = "$RM " . catfile($TFA_HOME,"jlib","je-5.0.84.jar");
			win_ssh_without_cred($host,"cmd /c $rem_command");
		} 

		if (-e catfile($temp_transfer_dir, "commons-io-2.2.jar")) {
			printLog("Removing " . catfile($TFA_HOME,"jlib","commons-io-2.2.jar") . "\n");
			$rem_command = "$RM " . catfile($TFA_HOME,"jlib","commons-io-2.2.jar");
			win_ssh_without_cred($host,"cmd /c $rem_command");
		} 

		if (-e catfile($temp_transfer_dir, "commons-io-2.5.jar")) {
			printLog("Removing " . catfile($TFA_HOME,"jlib","commons-io-2.5.jar") . "\n");
			$rem_command = "$RM " . catfile($TFA_HOME,"jlib","commons-io-2.5.jar");
			win_ssh_without_cred($host,"cmd /c $rem_command");
		} 

		if (-e catfile($temp_transfer_dir, "jre1.6.0_18.jar")) {
			printLog("Removing " . catfile($TFA_HOME,"jlib","jre1.6.0_18.jar") . "\n");
			$rem_command = "$RM " . catfile($TFA_HOME,"jlib","jre1.6.0_18.jar");
			win_ssh_without_cred($host,"cmd /c $rem_command");
		} 

		$rem_command = "$TFA_HOME/bin/tfactl access setuptracedir -user root";
		win_ssh_without_cred($host,"cmd /c $rem_command");

		$rem_command = "$TFA_HOME/bin/tfactl access update -local";
		win_ssh_without_cred($host,"cmd /c $rem_command");

		cleanDir($temp_transfer_dir);			## TODO: Find a better way as transferring whole tfahome for just a file may impact the performance
		tfactlwin_remote_win_copy_without_cred($host,catfile($TFA_HOME),$HOSTNAME,$temp_transfer_dir);
		if (! -f catfile($temp_transfer_dir, ".$host.shared")) {
			$rem_command = catfile($TFA_HOME,"bin","tfactl") . " access enable -local";
			win_ssh_without_cred($host,"cmd /c $rem_command");
			$rem_command = catfile($TFA_HOME,"bin","tfactl") . " access adddefaultusers -local";
			win_ssh_without_cred($host,"cmd /c $rem_command");
			$rem_command = $TOUCH . " " . catfile($TFA_HOME,".$host.shared");
			win_ssh_without_cred($host,"cmd /c $rem_command");
		} 

		if (-d $temp_transfer_dir) {
			rmtree($temp_transfer_dir);
		}

		printLog("Patching on $host complete...\n\n");
	}
}

# Patch Non-SSH remote nodes using TFA Installer
if(($LOCAL == 0) && (length($nonssh_list) != 0)){
	my $dateNtime = strftime "%Y%m%d_%H%M%S", localtime;
	my $REM_TFA_INSTALLER=catdir($TMPLOC,"tfa_setup_$dateNtime");

	my @hosts = ();
	my @lines = split(/\n/,$nonssh_list);
	foreach my $line (@lines) {
		if($line ne ""){
			push @hosts, trim($line);
		}
	}
	foreach my $host ( @hosts ) {
		printLog("\n");
		printLog("Copying TFA Installer to $host...\n");
		tfactlwin_remote_win_copy_without_cred($host,catdir($TFA_INSTALLER),$HOSTNAME,catdir($REM_TFA_INSTALLER));
		printLog("\n");
		printLog("Starting TFA Installer on $host...\n");
		#TODO - check whether the command is appropriate fow windows
		$command = "$REM_TFA_INSTALLER -local -silent -patch; $RM -f $REM_TFA_INSTALLER";
		win_ssh_without_cred($host,"cmd /c $command");
	}
}

printLog("\n");
printLog("Applying Patch on $HOSTNAME:\n");
printLog("\n");

#Shutdown TFA if its running:
if(tfactlwin_isTFAServiceRunning()){
	# Stop tools first
	printLog("Stopping TFA Support Tools...\n"); 
	my $cmd = catfile($tfa_home,"bin","tfactl")." stop_suptools > NUL 2>&1";
    qx($cmd);
	
	printLog("\n");
	printLog("Shutting down TFA for Patching...\n");
	#my $qxCommand = catfile($tfa_home,"bin","tfactl")." -initstop";
	#system($qxCommand);
	tfactlwin_stop_tfa();
	printLog("\n");
	printLog("Sleeping for 10 Seconds...\n");
	sleep(10);
}

my $JAR_DIR=catdir($tfa_home,"jar");

if(-d $JAR_DIR){
	my $JLIB_DIR=catdir($tfa_home,"jlib");
    printLog("Renaming $JAR_DIR to $JLIB_DIR\n");
    system("$MV $JAR_DIR $JLIB_DIR"); #TODO check if force movement is required
Log(    printLog("Adding INSTALL_TYPE = $INSTALL_TYPE to tfa_setup.txt\n"));
    $command = "$ECHO \"INSTALL_TYPE=$INSTALL_TYPE\" >>  ".catfile($tfa_home,"tfa_setup.txt");
    qx($command);

    # Only for GI Install move Output Dir to ORACLE_BASE
    if (index("GI", $INSTALL_TYPE) != -1) {
    	if(defined($ORACLE_BASE) && ($ORACLE_BASE ne '')){
    		my $OB_OUT_DIR=catdir($ORACLE_BASE,"tfa",$HOSTNAME);
            my $TFA_OUT_DIR=catdir($tfa_home,"output");

            printLog("Copying $TFA_OUT_DIR to $OB_OUT_DIR\n");
            tfactlwin_robocopy(catdir($TFA_OUT_DIR),catdir($OB_OUT_DIR));
    	}
    }
    printLog("\n");
}

if(defined($PERL) && ($PERL ne '')){
	if(-f catfile($tfa_home,"tfa_setup.txt")){
		my $configFound = 0;
		my $prop = catfile($tfa_home,"tfa_setup.txt");
		open(FILE, '<', $prop) || print "File not found";
        my @lines = <FILE>;
        close(FILE);

        my @newlines;
        my $statement;
        foreach(@lines) {
                if (/^PERL=/) {
                    $configFound = 1;
                }
                $statement = $_;
                push(@newlines,$statement);
        }
        if(!$configFound){
        	$statement = "PERL=$PERL";
        	push(@newlines,$statement);
        }
        open(FILE, '>', $prop) || print "File not found";
        print FILE @newlines;
        close(FILE);  
	}
}

tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","jlib","RATFA.jar"),catdir($tfa_home,"jlib","RATFA.jar"));
tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","jlib","oraclepki.jar"),catdir($tfa_home,"jlib","oraclepki.jar"));
tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","jlib","ojmisc.jar"),catdir($tfa_home,"jlib","ojmisc.jar"));
tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","jlib","ojpse.jar"),catdir($tfa_home,"jlib","ojpse.jar"));
tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","jlib","osdt_cert.jar"),catdir($tfa_home,"jlib","osdt_cert.jar"));
tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","jlib","osdt_core.jar"),catdir($tfa_home,"jlib","osdt_core.jar"));
tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","jlib","owm-3_0.jar"),catdir($tfa_home,"jlib","owm-3_0.jar"));

if(! -f catfile($tfa_home,"jlib","commons-io-2.6.jar")){
	tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","jlib","commons-io-2.6.jar"),catdir($tfa_home,"jlib","commons-io-2.6.jar"));
}

if(-f catfile($tfa_home,"jlib","commons-io-2.1.jar")){
	unlink catfile($tfa_home,"jlib","commons-io-2.1.jar");
}

if(-f catfile($tfa_home,"jlib","commons-io-2.5.jar")){
	unlink catfile($tfa_home,"jlib","commons-io-2.5.jar");
}

# For bdb upgrade check if current version of BDB is 4.0.103
if(-s catfile($tfa_home,"jlib","je-4.0.103.jar")){
	printLog("The current version of Berkeley DB is 4.0.103\n");
    printLog("Copying je-4.1.27.jar to ".catdir($tfa_home,"jlib")."\n");
    tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","jlib","je-4.1.27.jar"),catdir($tfa_home,"jlib"));
    printLog("Copying je-6.4.25.jar to ".catdir($tfa_home,"jlib")."\n");
    tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","jlib","je-6.4.25.jar"),catdir($tfa_home,"jlib"));
    printLog("Running DbPreUpgrade_4_1 utility\n");
    my $command = "$JAVA -jar ".catfile($tfa_home,"jlib","je-4.1.27.jar")." DbPreUpgrade_4_1 -h $BDB_HOME";
    printLog("Command: $command\n",1);
    my $output=`$command`;
	printLog("Output of upgrade : $output\n",1);
}elsif(-s catfile($tfa_home,"jlib","je-5.0.84.jar")){
    printLog("Copying je-6.4.25.jar to ".catdir($tfa_home,"jlib")."\n");
    tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","jlib","je-6.4.25.jar"),catdir($tfa_home,"jlib")); 
}else{
	printLog("No Berkeley DB upgrade required\n");
}

tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","bin"),catdir($tfa_home));
tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","resources"),catdir($tfa_home));
tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","ext"),catdir($tfa_home));

if(tfactlwin_isTFAServiceRunning()){	## Checking if OraceTFAService is running before transferring TFAService.exe in install folder
	tfactlwin_stop_tfa();
	tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","install"),catdir($tfa_home));
} else {	
	tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","install"),catdir($tfa_home));
}

tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","internal","usableports.txt"),catdir($tfa_home,"internal"));
tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","internal","config.properties"),catdir($TMPLOC,"config.properties.bkp"));
tfactlwin_robocopy(catdir($TMPLOC,"config.properties.bkp"),catdir($tfa_home,"internal"));
tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","internal","timezones_mapping"),catdir($TMPLOC,"timezones_mapping.bkp"));
tfactlwin_robocopy(catdir($TMPLOC,"timezones_mapping.bkp"),catdir($tfa_home,"internal"));
tfactlwin_robocopy(catdir($TMPLOC,"dbversions.json"),catdir($tfa_home,"internal"));
tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","receiver","internal","rconfig.properties"),catdir($TMPLOC,"rconfig.properties.bkp"));
tfactlwin_robocopy(catdir($TMPLOC,"rconfig.properties.bkp"),catdir($tfa_home,"receiver","internal","rconfig.properties.bkp"));
tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","tfa_directories.txt"),catdir($TMPLOC,"tfa_directories.txt.bkp"));
tfactlwin_robocopy(catdir($TMPLOC,"tfa_directories.txt.bkp"),catdir($tfa_home,"tfa_directories.txt.bkp"));

if(! -d catdir($tfa_home,"internal","scripts")){
	mkpath([catdir($tfa_home,"internal","scripts")]);
}
tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","internal",".buildid"),catdir($tfa_home,"internal"));
tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","internal",".buildversion"),catdir($tfa_home,"internal"));

# Copy ceritificates
printLog("\n");
printLog("Copying TFA Certificates...\n");
tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","tfa.jks"),catdir($tfa_home,"tfa.jks"));
tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","public.jks"),catdir($tfa_home,"public.jks"));

if(! -f catfile($tfa_home,"server.jks")){
	tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","server.jks"),catdir($tfa_home,"server.jks"));
	tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","client.jks"),catdir($tfa_home,"client.jks"));
	tfactlwin_robocopy(catdir($e_tfabase,"tfa_home","internal","ssl.properties"),catdir($tfa_home,"internal","ssl.properties"));
}

$command = "$PERL ".catfile($tfa_home,"bin","tfactl.pl")." updateautodiagcollect";qx($command);
$command = "$PERL ".catfile($tfa_home,"bin","tfactl.pl")." updatepropertiesfile";qx($command);
$command = "$PERL ".catfile($tfa_home,"bin","tfactl.pl")." updatedirectoriesfile";qx($command);

printLog("\n");
printLog("Running commands to fix init.tfa and tfactl in localhost\n");
# perl $tfa_home/bin/tfactl.pl fixInitTfa
$command = "$PERL ".catfile($tfa_home,"bin","tfactl.pl")." fixTfactl";qx($command);
$command = "$PERL ".catfile($tfa_home,"bin","tfactl.pl")." copytfactl";qx($command);
$command = "$PERL ".catfile($tfa_home,"bin","tfactl.pl")." fixTfadiagnostics";qx($command);

chmodAddPerm(0111,catdir($tfa_home,"ext"));
chmodAddPerm(0111,catdir($tfa_home,"ext","oratop"));
my @fileList = getRecursiveFolderContents(catdir($tfa_home,"ext","oratop"));
chmod 0111, @fileList;
#TODO changing of TFA Serivce if required.
# cp $tfa_home/install/init.tfa $ID/init.tfa

printLog("\n");
printLog("Starting TFA in $HOSTNAME...\n");
printLog("\n");
tfactlwin_start_tfa($tfa_home);

printLog("Sleeping for 10 Seconds...\n");
sleep(10);

if(-f catfile($tfa_home,"jlib","je-4.0.103.jar")){
	printLog("Removing ".catfile($tfa_home,"jlib","je-4.0.103.jar"));
	$command ="$RM ".catfile($tfa_home,"jlib","je-4.0.103.jar");qx($command);
}
if(-f catfile($tfa_home,"jlib","je-5.0.84.jar")){
        printLog("Removing ".catfile($tfa_home,"jlib","je-5.0.84.jar"));
        $command ="$RM ".catfile($tfa_home,"jlib","je-5.0.84.jar");qx($command);
}

$command = catfile($tfa_home,"bin","tfactl")." access setuptracedir -user root";qx($command);

# Update File Permissions for Non-root Access
$command = catfile($tfa_home,"bin","tfactl")." access update -local";qx($command);

# Changes for Non-root Access
if(! -f catfile($tfa_home,".$HOSTNAME.shared")){
	# Open File Permissions for Non-root Access
	$command = catfile($tfa_home,"bin","tfactl")." access enable -local";qx($command);

    # Add Default users for Non-root Access
    $command = catfile($tfa_home,"bin","tfactl")." access adddefaultusers -local";qx($command);

    $command = "$TOUCH ".catfile($tfa_home,".$HOSTNAME.shared");qx($command);
}
printLog("\n");

remove_password_non_ssh();

open(my $fptr, '>', catfile($TMPLOC,".tfa.patch")) or die "Could not open file ".catfile($TMPLOC,".tfa.patch")." $!";
print $fptr "0";
close($fptr);

exit 0;
