# 
# $Header: tfa/src/v2/tfa_home/bin/uninstall.pl /main/17 2018/05/28 15:06:28 bburton Exp $
#
# uninstall.pl
# 
# Copyright (c) 2015, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      uninstall.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bibsahoo    04/27/18 - FIX BUG 27845377
#    bburton     08/25/17 - bug26696360 - windows hyphen in hostname
#    bibsahoo    06/15/17 - FIX BUG 26279506
#    bibsahoo    09/28/16 - GI HOME INCONSISTENCY AND TFA INSTALLATION ORDER IN
#                           NODES OF A CLUSTER AND ROBOCOPY HANGING DURING
#                           UNINSTALLING TFA WIN
#    bibsahoo    06/17/16 - Windows Typical Install
#    arupadhy    03/21/16 - Windows uninstall fix
#    arupadhy    01/22/16 - refactored windows process management functions
#    arupadhy    01/04/16 - Uninstall issue fix for certain type of windows
#                           machines which take specific format for new
#                           minimized command propmt start
#    arupadhy    11/02/15 - Fix for proper removal of files from Oracle Base
#                           directory during uninstall
#    arupadhy    10/23/15 - fix for proper removal of all files in tfa_home
#    bibsahoo    10/22/15 - BUG 21804887 - TFA DIR FROM GI HOME IS NOT GETTING
#                           REMOVED AFTER UN-INSTALLING TFA
#    arupadhy    10/07/15 - added force removal of tfaservice.exe if not
#                           properly handled by the sc command
#    arupadhy    09/21/15 - initial commit to windows perl uninstaller,
#                           converted from uninstall.sh ( Linux uninstaller)
#    arupadhy    09/21/15 - Creation
# 

use strict;
use English;
use File::Spec::Functions;
use Getopt::Long qw(GetOptions);
use File::Basename qw( dirname );
use Sys::Hostname;
use File::Path;
use Win32;
use Net::Ping;
use POSIX qw(strftime);

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME);
  push @INC, dirname($PROGRAM_NAME).'/common';
}

use tfactlwin;

my $UNAME=$^O;
my $PLATFORM=$UNAME;

### Configure Values ####
my $crsServiceName = "";
my $scriptDebug = 0;
my $TMPLOC="C:\\TMP";#TODO temporary location for windows
if(!-d $TMPLOC){
	mkpath([catdir($TMPLOC)]);
}
### Configure Values ####

#### Utility Functions #####
sub getPerl{
  my $tfa_home = shift;
  my $PERL = "perl";
  if(-f catfile($tfa_home,"tfa_setup.txt")){
  $PERL=getValueOfKeyFromFile(catfile($tfa_home,"tfa_setup.txt"),"PERL=");
  }
  return $PERL;
}

# It extracts value for a key in a given file (equivalent to grep + sed in linux)
# Parameter : $fileName - file path, $key - key whose value is to be extracted
# Return : Value for the key
sub getValueOfKeyFromFile{
  my $fileName=shift;
  my $key=shift;
  my $input_fh;
  open( $input_fh, "<", $fileName ) || die "Can't open $fileName: $!";
  my $line="";
  while (<$input_fh>) {
     if (/$key/) {
      chomp;
      $line=$_;
     }
  }
  close $input_fh;
  $line =~ s/$key//;
  return $line;
}

sub getTFAHome{
	my $BASE_KEY="HKEY_LOCAL_MACHINE\\SOFTWARE\\Oracle";
	my $ELEMENT="TFA_HOME";
	my $tfa_home;

	my $result = `reg query $BASE_KEY /s /e /f $ELEMENT | findstr $ELEMENT`;
	if (index($result, $ELEMENT) != -1) {
	    $result=trim($result);
	    my @array = split ' ', $result;
	    $tfa_home = $array[2];
	}
	return $tfa_home;
}

sub getParentDirectory{
  my @dirs   = File::Spec->splitdir($_[0]);       # parse directories
  pop @dirs;                                      # remove top dir
  my $newdir = File::Spec->catdir(@dirs);         # create new path
  return $newdir;
}

# It extracts value for a key in a given file (equivalent to grep + sed in linux)
# Parameter : $fileName - file path, $key - key whose value is to be extracted
# Return : Value for the key
sub getValueFromFile{
	if($scriptDebug){print __LINE__."\n";}
	my $fileName=shift;
	my $key=shift;
	my $input_fh;

	open( $input_fh, "<", $fileName ) || die "Can't open $fileName: $!";
	my $line="";
	while (<$input_fh>) {
	   if (/$key/) {
			chomp;
			$line=$_;
	   }
	}
	close $input_fh;
	$line =~ s/$key//;
	return $line;
}

# Trims whitespaces around a string
# Parameters : $s - string that needs to be trimmed
# return : $s - trimmed string
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

sub get_shared_directory_count{
	my $directory = shift;
	my $SHARED_COUNT=0;
	if(-d $directory){
		opendir(DIR, $directory) or print "Can't open directory $directory: $!\n";
	    while (my $file = readdir(DIR)) {
	    	if($file eq '.' || $file eq '..'){
	    		next;
	    	}
	    	if($file =~ m/.*.shared$/){
	    		$SHARED_COUNT = $SHARED_COUNT +1;
	    	}
	    }
	    closedir(DIR);
	}
	return $SHARED_COUNT;
}
#### Utility Functions #####


my $ME=$ARGV[0];
my $SILENT=0;
my $LOCAL=0;
my $CLUSTERWIDE=1;
my $CRSHOME;
my $HELP;

# Print help function
sub printhelp{

	my $help = <<EOF;
		
	   Usage for $ME
	
	   $ME [-local] [-silent]
	
	        -local            -    Uninstall TFA only on the local node
	        -silent           -    Do not ask any uninstall questions
	
        
           Note: Without parameters, this will uninstall TFA on all configured nodes.
	        		
EOF

	print $help;
}

#
# Parse argument
#
my $tfa_home;my $tfabase;

GetOptions(
	'silent' => \$SILENT,
	'local' => \$LOCAL,
	'tfa_home=s' => \$tfa_home,
	'clusterwide' => \$CLUSTERWIDE,
	'crshome=s' => \$CRSHOME,
	'help' => \$HELP,
	'h' => \$HELP,
	) or printhelp();

if ($SILENT){
	#print "\nSILENT : $SILENT\n";
}
if ($LOCAL){  
	#print "\nLOCAL : $LOCAL\n";
	$CLUSTERWIDE = 0;
}
if ($CLUSTERWIDE){  
	#print "\nCLUSTERWIDE : $CLUSTERWIDE\n";
}
if ($CRSHOME){
	#print "\nCRSHOME : $CRSHOME\n";	
	$LOCAL=1;
	$ENV{"CRSHOME"} = $CRSHOME;
}
if ($HELP){
	#print "\nHELP : $HELP\n";
}

if($HELP){
	if($scriptDebug){print __LINE__."\n";}
	printhelp();
	exit;
}

#print "PRINTING FLAGS....\n";
#print "\nSILENT : $SILENT\n";
#print "\nLOCAL : $LOCAL\n";
#print "\nCLUSTERWIDE : $CLUSTERWIDE\n";
#print "\nCRSHOME : $CRSHOME\n";	
#print "\nHELP : $HELP\n";

if(!tfactlwin_isTFAServiceIsConfigured()){
	print "\nTFA is not Installed on this machine. Exiting now...\n";
	exit;
}

if (!$tfa_home) {
	$tfa_home=getTFAHome();
}
my $PERL=getPerl($tfa_home);
$tfabase=getParentDirectory($tfa_home);
my $CRS_HOME;

#Chech for -crshome, Uninstall only if tfa_home is under CRSHOME.
if(defined($CRSHOME) && ($CRSHOME ne '')){
	if (!(index($CRS_HOME, $tfa_home) != -1)) {
		exit;
	}
}

if(! -r catfile($tfa_home,"bin","tfactl.bat")){
	print "\nUnable not locate TFA binaries. Exiting now.\n";
	exit;
}

if(-f catfile($tfa_home,"tfa_setup.txt")){
	$CRS_HOME=getValueFromFile(catfile($tfa_home,"tfa_setup.txt"),"CRS_HOME=");
	if(defined($CRSHOME) && ($CRSHOME ne '')){
		$PERL=catfile($CRS_HOME,"perl","bin","perl");
	}
}

my $HOSTNAME=hostname;
my $host_count;

my $cmd = catfile($tfa_home,"bin","tfactl.bat")." print hosts";
my $value = qx($cmd);

my @tfahosts = ();
my @lines = split(/\n/,$value);
@lines = grep{/Host Name :/} @lines;
$host_count = scalar @lines;
foreach my $line (@lines) {
  my @tokens = split(/Host Name :/,$line);
  push @tfahosts, trim($tokens[1]);
}

if($host_count == 0){ # TFA is probably not running
	print "\nUnable to determine a host list from TFA. So running local uninstall.\n";
}

# if there is only one node in a cluster, set LOCAL to 1
# If host count is 0, set LOCAL to 1 which will do local uninstall

if(($host_count == 1) || ($host_count == 0)){
	$LOCAL=1;
}

# Prompt user before uninstall if its not a part of clusterwide uninstall
if($LOCAL == 1){
	print "\nTFA will be Uninstalled on Node $HOSTNAME: \n";
}else{
	print "\nTFA will be Uninstalled on: \n";
	foreach my $host (@tfahosts) {
	  print $host."\n";
	}
}

print "";

# This will prompt user when there is only one node and silent is not enabled.
if( $SILENT == 0){
	my $userinput;
	print "\nDo you want to continue with Uninstall? [Y|N] [Y]: ";
	chomp( $userinput = <STDIN> );
	$userinput = trim($userinput);

	if(($userinput eq "n")|| ($userinput eq "N")){
		print "\nExiting from TFA Uninstall now.\n";
		exit 0;
	}
	print "";
}


# if there is only one node in the cluster, set CLUSTERWIDE to 1
if($host_count == 1){
	$CLUSTERWIDE=1;
}

# If this is a local then we do not need to check further
# If it is remote and silent then we need to check ssh is OK
# If it is remote but not silent then we can prompt for passwords if required.
my $exitcode;
my $ssh_setup_status;
my $rsh_setup_status;
my $usern;

if(($LOCAL == 0) && ($SILENT == 1)){
	my $localnode = hostname; #TODO  Need to set the localnode - changed
	foreach my $hname (@tfahosts){
		print "\nChecking for ssh equivalency in $hname\n";
		if($hname ne $localnode){
			#TODO need to change - changed
			my $p = Net::Ping->new();
			if ($p->ping($hname)) {
				$exitcode = 0;
			}else{
				$exitcode = 1;
			}
			#TODO need to change - changed
		}

		if (($exitcode == 0) && ($hname ne $localnode )){
			$ssh_setup_status = tfactlwin_check_ssh_equivalence($hname);

			if ($ssh_setup_status==0){
				print "\n$hname is configured for ssh user equivalency for $usern user\n";
			} else {
				print "\nNode $hname is not configured for ssh user equivalency\n";
				$LOCAL = 1;
			}
		}
	}
}

if($LOCAL == 1){
	if($CLUSTERWIDE == 0){
		print "\nRemoving TFA from $HOSTNAME only\n";
        print "\nPlease remove TFA locally on any other configured nodes\n";
	}else{
		print "\nRemoving TFA from $HOSTNAME...\n";
	}
	print "";
}

#Send uninstall update to other nodes if its local uninstall.
if(($LOCAL == 1) && ($CLUSTERWIDE == 0)){
	print "\nNotifying Other Nodes about TFA Uninstall...\n"; 
	system(catfile($tfa_home,"bin","tfactl.bat")." senduninstallupdate");
    print "\nSleeping for 10 seconds...\n";
    sleep (10);
}

# Stop tools first
print "\nStopping TFA Support Tools...\n"; 
my $cmd = catfile($tfa_home,"bin","tfactl.bat")." stop_suptools > NUL 2>&1"; qx($cmd);
print "";

#Stop tfa in localhost
print "\nStopping TFA in $HOSTNAME...\n";
tfactlwin_shutdown_tfa();

# Stop and delete tfa_home on remote hosts
my $rem_tfa_home;
my $command;

if($LOCAL == 0){
	foreach my $host (@tfahosts){
		if ($host ne $HOSTNAME) {			
			$rem_tfa_home = $tfa_home;
			$rem_tfa_home =~ s/$HOSTNAME/$host/g;

			print "\nStopping TFA in $host and removing $rem_tfa_home...\n";

			my $remote_cmd_uninstall_logdir = catdir("C:", "tfactl_remote_cmd_dir");
			my $create_remote_dir_cmd = "cmd /c mkdir $remote_cmd_uninstall_logdir";  # Create Remote Temp dir
		    my $create_remote_dir_command = "WMIC /node:\"$host\" PROCESS call create \"$create_remote_dir_cmd\"";     
		    `$create_remote_dir_command`;

			my $remote_cmd_uninstall_logfile = catdir($remote_cmd_uninstall_logdir, "uninstall.log");
			$command = catfile($rem_tfa_home,"bin","tfactl.bat")." uninstall > $remote_cmd_uninstall_logfile 2>&1";
			tfactlwin_ssh_without_cred($host,"cmd /c $command");

			my $count = 0;
			while(1) {
				tfactlwin_remote_win_copy_without_cred($host,$remote_cmd_uninstall_logdir,$HOSTNAME,catdir($tfa_home, "tmp"));

				if (-e catfile($tfa_home, "tmp", "uninstall.log")) {
					my $cmd = "type " . catfile($tfa_home, "tmp", "uninstall.log");
					my $file_contents = `$cmd`;
					my $rem_tfa_base = dirname($rem_tfa_home);
					if ($file_contents =~ /\QRemoving $rem_tfa_base on $host/) {
						print "\n$file_contents\n";
						last;
					}
				} 

				if ($count > 120) {
					print "\nFailed to uninstall TFA on node $host\n";
					last;
				}

				sleep(5);
				$count += 5;
			} 

			$command = "rmdir $remote_cmd_uninstall_logdir /S /Q 2>nul";
			tfactlwin_ssh_without_cred($host,"cmd /c $command");

			if (-e catdir($tfa_home, "tmp", "uninstall.log")) {
				unlink(catdir($tfa_home, "tmp", "uninstall.log"));
			}

			print "\n";
		}
	}
}

# Delete TFA files in local
print "\nDeleting TFA support files on $HOSTNAME:\n";

#Added below to remove BDB and logs if its a GI Install
my $GI_CRS_HOME;
my $GI_ORACLE_BASE;
my $BDB_DIR;
my $LOG_DIR;
my $OUT_DIR;
my $SHARED_FILE;
my $SHARED_COUNT;
my $NEWOWNER;

if(-f catfile($tfa_home,"tfa_setup.txt")){
	$GI_CRS_HOME = getValueFromFile(catfile($tfa_home,"tfa_setup.txt"),"CRS_HOME=");
	$GI_ORACLE_BASE = getValueFromFile(catfile($tfa_home,"tfa_setup.txt"),"ORACLE_BASE=");

	if((defined($GI_CRS_HOME) && ($GI_CRS_HOME ne '')) && (defined($GI_CRS_HOME) && ($GI_CRS_HOME ne ''))){
		if (index($tfa_home, $GI_CRS_HOME) != -1) {
			$BDB_DIR=catdir($GI_ORACLE_BASE,"tfa",$HOSTNAME,"database");
            $LOG_DIR=catdir($GI_ORACLE_BASE,"tfa",$HOSTNAME,"log");
			$OUT_DIR=catdir($GI_ORACLE_BASE,"tfa",$HOSTNAME,"output");

			if(-d $BDB_DIR){
				print "\nRemoving $BDB_DIR...\n";
				rmtree $BDB_DIR;
			}

			if(-d $LOG_DIR){
				print "\nRemoving $LOG_DIR...\n";
				rmtree $LOG_DIR;
			}

			if(-d $OUT_DIR){
				print "\nRemoving $OUT_DIR...\n";
				rmtree $OUT_DIR;
			}

			if(-d catdir($GI_ORACLE_BASE,"tfa",$HOSTNAME)){
				print "\nRemoving ".catdir($GI_ORACLE_BASE,"tfa",$HOSTNAME)."...\n";
				rmtree catdir($GI_ORACLE_BASE,"tfa",$HOSTNAME);
			}
			
			#Added below to remove .<node>.shared under <ORACLE_BASE>/tfa
			$SHARED_FILE=catfile($GI_ORACLE_BASE,"tfa",".$HOSTNAME.shared");

			if(-f $SHARED_FILE){
				unlink $SHARED_FILE;
			}

			$SHARED_COUNT=get_shared_directory_count(catdir($GI_ORACLE_BASE,"tfa"));

			if($SHARED_COUNT == 0){
				if(-d catdir($GI_ORACLE_BASE,"tfa")){
					print "\nRemoving ".catdir($GI_ORACLE_BASE,"tfa")."...\n";
					rmtree catdir($GI_ORACLE_BASE,"tfa");
				}
			}
			
			if(-d catdir($GI_ORACLE_BASE,"tfa")){
				#TODO need to change
				#$NEWOWNER = `$LS -ld $GI_ORACLE_BASE/. | $AWK '{print $3":"$4}'`;
				#TODO need to change

				if(defined($NEWOWNER) && ($NEWOWNER ne '')){
					print "\nChanging ownership of ".catdir($GI_ORACLE_BASE,"tfa")." to $NEWOWNER.\n";
					#TODO need to change
					#$CHOWN -R $NEWOWNER $GI_ORACLE_BASE/tfa;
					#TODO need to change
				}else{
					# print "\nUnable to change ownership of ".catdir($GI_ORACLE_BASE,"tfa");
				}
			}
		}
	}
}

my $local_base_dir;

if(index($tfa_home,"\\tfa\\$HOSTNAME\\tfa_home") != -1){
	$local_base_dir=getParentDirectory($tfabase);
	print "\nRemoving TFAService...\n";
	tfactlwin_removeTFAService();

	# This will remove GIHOME/bin/tfactl
	if(defined($GI_CRS_HOME) && ($GI_CRS_HOME ne '')){
		if(-d catfile($GI_CRS_HOME,"bin","tfactl.bat")){
			print "\nRemoving ".catfile($GI_CRS_HOME,"bin","tfactl.bat")."...\n";
	    	unlink catfile($GI_CRS_HOME,"bin","tfactl.bat");
		}
	}

	if(-d $tfabase){
    	print "\nRemoving ".$tfabase." on $HOSTNAME...\n";
    	my $dateNtime = strftime "%Y%m%d_%H%M%S", localtime;
    	my $EMPTY_FOLDER = catdir($TMPLOC,"empty_$dateNtime");
    	if(!-d $EMPTY_FOLDER){
			mkpath([catdir($EMPTY_FOLDER)]);
		}
		my $cmd = "cmd /c start /min robocopy /MIR $EMPTY_FOLDER ".$tfabase;
		#print "CMD: $cmd\n";
		`$cmd`;
		sleep(5);
		rmtree($tfabase);
		rmtree($EMPTY_FOLDER);
		#exec("cmd /c start RD /S /Q ".$tfabase." >nul 2>nul & RD /S /Q $EMPTY_FOLDER >nul 2>nul & exit \b 0");
    	exit 0;
    }

    if(-d catdir($GI_CRS_HOME,"tfa")){
    	print "\nRemoving ".catdir($GI_CRS_HOME,"tfa")." on $HOSTNAME...\n";
    	my $dateNtime = strftime "%Y%m%d_%H%M%S", localtime;
    	my $EMPTY_FOLDER = catdir($TMPLOC,"empty_$dateNtime");
    	if(!-d $EMPTY_FOLDER){
			mkpath([catdir($EMPTY_FOLDER)]);
		}
		my $directory = catdir($GI_CRS_HOME,"tfa");
		my $cmd = "cmd /c start /min robocopy /MIR $EMPTY_FOLDER ".$directory;		
		#print "CMD: $cmd\n";
		`$cmd`;
		sleep(5);
		rmtree($directory);
		rmtree($EMPTY_FOLDER); 
    	exit 0;
    }
}else{
	if(-d catfile($tfabase,"final_tfa_discovery.out")){
		unlink catfile($tfabase,"final_tfa_discovery.out");
	}
	if(-d catfile($tfabase,"ora_stack_status.out")){
		unlink catfile($tfabase,"ora_stack_status.out");
	}
	if(-d catfile($tfabase,"ora_stack_status_pct.out")){
		unlink catfile($tfabase,"ora_stack_status_pct.out");
	}

    # This will remove GIHOME/bin/tfactl
    if(defined($GI_CRS_HOME) && ($GI_CRS_HOME ne '')){
    	if(-f catfile($GI_CRS_HOME,"bin","tfactl.bat")){
    		print "\nRemoving ".catfile($GI_CRS_HOME,"bin","tfactl.bat")."...\n";
            unlink catfile($GI_CRS_HOME,"bin","tfactl.bat");
    	}
    }
	
	print "\nRemoving TFASerice...\n";
	tfactlwin_removeTFAService();

	if(-d $tfa_home){
    	print "\nRemoving $tfa_home on $HOSTNAME...\n";
    	my $dateNtime = strftime "%Y%m%d_%H%M%S", localtime;
    	my $EMPTY_FOLDER = catdir($TMPLOC,"empty_$dateNtime");
    	if(!-d $EMPTY_FOLDER){
			mkpath([catdir($EMPTY_FOLDER)]);
		}
		my $cmd = "cmd /c start /min robocopy /MIR $EMPTY_FOLDER $tfa_home";	
		#print "CMD: $cmd\n";
		`$cmd`;
		sleep(5);
		rmtree($tfa_home);
		rmtree($EMPTY_FOLDER); 
    	exit 0;
    }
}
