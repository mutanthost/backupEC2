# 
# $Header: tfa/src/v2/tfa_home/bin/tfadiagnosticsDriver.pl /main/7 2017/08/11 05:02:21 llakkana Exp $
#
# tfadiagnosticsDriver.pl
# 
# Copyright (c) 2015, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfadiagnosticsDriver.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     05/08/17 - ReadKey Not required
#    arupadhy    06/21/16 - Updated help and added validation for unsupported
#                           extra arguments
#    bibsahoo    06/17/16 - Windows Typical Install
#    arupadhy    05/17/16 - exit after wrong option, double checking path
#                           creation if the repository directory provided does
#                           not exist, change for tag based zip collection
#    arupadhy    01/22/16 - Added tfadiagnostics.bat to make sure that PERLLIB
#                           conflicts does not hamper the diagnosetfa processes
#    arupadhy    10/30/15 - Creation
# 

use strict;
use English;
use File::Spec::Functions;
use File::Find;
use File::Path;
use Cwd            qw( abs_path cwd getcwd);
use File::Basename qw( dirname basename );
use File::Copy;
use Getopt::Long qw(GetOptions);
use Sys::Hostname;
use Win32;	#Move to eval when this file will be used for Win/Linux both
use Win32::Service qw(StartService StopService GetStatus GetServices);
use POSIX qw(strftime);

my $UNAME=$^O;
my $PLATFORM=$UNAME;
my $PERL;

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME);
  push @INC, dirname($PROGRAM_NAME).'/common';
}

use tfactlwin;

### Configure Values ####
my $oracleTFAServiceName = "OracleTFAService";
my $crsServiceName = "";
my $scriptDebug = 0;
my $IS_WINDOWS=0;
my $MV;
my $CP;
my $RM;
my $repository;
if ( $^O eq "MSWin32" )
{
  $IS_WINDOWS = 1;
  $MV = "move";
  $repository="C:\\TMP";
  if(! -d $repository){
  	mkpath($repository);
  }
  $RM = "del";
}else{
  $MV = "mv";
  $CP = "cp";
  chomp( $RM  = qx(which rm));
  $repository="/tmp";
}

#if ($IS_WINDOWS)
#{
#  eval q{use Term::ReadKey; 1} or die $@;
#}

### Configure Values ####

### Utility Functions ###
sub isTFAServiceIsConfigured{
	if($scriptDebug){print __LINE__."\n";}
	my $service = $oracleTFAServiceName;
    my %status_code = (
	    Stopped       => 1,
	    StartPending  => 2,
	    StopPending   => 3,
	    Running       => 4,
	    ResumePending => 5,
	    PausePending  => 6,
	    Paused        => 7
	);
    my (%status, %services);

    GetServices('', \%services) or do {
        print "Failed to retieve list of services";
        exit 1;
    };
    %services = reverse %services;

    if (! exists $services{$service}) {
        #print "\n'$service' is not a configured Windows service\n";
        return 0;
    }else{
    	#print "\n'$service' is a configured Windows service\n";
    	return 1;
    }
#    my $qxCommand = system('reg query "HKEY_LOCAL_MACHINE\\SoftWare\\Oracle\\KEY_TraceFileAnalyzer" /v TFA_HOME');
#	if($qxCommand){
#		return 1; #Registry Key Exists
#	}else{
#		return 0; #Registry Key does not Exists
#	}
}

sub runUsingExpect{
	#TODO implement when linux will also use this file for diagnostics.
}

sub trim{
	my $str = $_;
	$str = shift;
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;
	return $str ;
}

sub getActualUserName {
	my $username;
	if ( $IS_WINDOWS ){
		$username = getlogin;
	}else{
		$username = (getpwuid($<))[0];
	}
	return $username;
}

sub get_tfa_home_from_registry{
	my $tfa_home;
	if($IS_WINDOWS){
		my $result = osutils_query_registry("TFA_HOME");
		my @tokens = split(/\s+/,$result);
		my $tokenArrLength = scalar @tokens;
		if($tokenArrLength>=4){
			$tfa_home = trim($tokens[3]);
		}
	}else{
		if(defined($tfa_home) && ($tfa_home ne '')){
			#TODO need to set $ID and $AWK and $GREP
			# $tfa_home = `$GREP '^export TFA_HOME=' $ID/init.tfa | $AWK -F"=" '{print $2}'`;
		}
	}
	return $tfa_home;
}

sub osutils_check_os_type{
  my $type =`IF EXIST "%PROGRAMFILES(X86)%" (ECHO 64BIT) ELSE (ECHO 32BIT)`;
  return $type;
}

sub osutils_query_registry{
  my $key =shift;
  my $BASE_KEY="HKEY_LOCAL_MACHINE\\SOFTWARE\\Oracle";
  my $result="";

  my $type = trim(osutils_check_os_type());
  my $REGISTRY_QUERY_TYPE;

  if($type eq "64BIT"){
    $REGISTRY_QUERY_TYPE = "/reg:64";
  }else{
    $REGISTRY_QUERY_TYPE = "/reg:32";
  }

  $result = `reg query $BASE_KEY /s /e /f $key $REGISTRY_QUERY_TYPE | findstr $key`;
  return $result;
}

# It extracts value for a key in a given file (equivalent to grep + sed in linux)
# Parameter : $fileName - file path, $key - key whose value is to be extracted
# Return : Value for the key
sub tfactldiagnostics_getValueOfKeyFromFile{
  my $fileName=shift;
  my $key=shift;

  open( my $input_fh, "<", $fileName ) || die "Can't open $fileName: $!";
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

sub getParentDirectory{
	my @dirs   = File::Spec->splitdir($_[0]);       
	pop @dirs;                                      
	my $newdir = File::Spec->catdir(@dirs);         
	return $newdir;
}

sub write_to_file{
	my $filename = shift;
	my $content = shift;
	my $type = shift;
	my $fh;
	if($type ne "A"){
		open($fh, '>', $filename) or die "Could not open file '$filename' $!";
	}else{
		open($fh, '>>', $filename) or die "Could not open file '$filename' $!";
	}
	print $fh $content;
	close $fh;
}

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

sub print_file_with_line_no{
	my $file_name = shift;
	open my $info, $file_name or die "Could not open $file_name: $!";
	my $lineCounter = 0;
	while( my $line = <$info>)  {   
		$lineCounter = $lineCounter +1;
	    print $lineCounter ." ". $line;
	}
	close $info;
}

sub tfactldiagnostics_readMode{
  my $mode =shift;
  if($IS_WINDOWS){
    if($mode){
      ReadMode(0);
    }else{
      ReadMode('noecho');
    }
  }else{
    if($mode){
      system('stty', 'echo');
    }else{
      system('stty', '-echo');
    }
  }
}

sub get_password_from_user{
	my $SAME = shift;
	my $REMOTE_HOST = shift;
	my $PASS;
	if($SAME != 1){
		print "";
		print "Please Enter the password for $REMOTE_HOST : \n";
		tfactldiagnostics_readMode(0);
		$PASS = <STDIN>;
		chomp $PASS;
		tfactldiagnostics_readMode(1);
		print "";

		if($SAME != 2){
			my $option;
			print "";
			print "Is password same for all the nodes? [Y|N] [Y]: \n";
			chomp( $option = <STDIN> );
			$option ||= "n";
			$option = get_valid_input ($option, "y|Y|n|N", "Y");

			if ( $option =~ /[Yy]/ ) {
				$SAME=1;
			}else{
				$SAME=2;
			}
		}
	}
	return $SAME;
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
### Utility Functions ###

if(!isTFAServiceIsConfigured()){
	print "TFA is not Installed on this machine. Exiting now...\n";
	exit;
}

my $RUSER = getActualUserName();

if(! Win32::IsAdminUser()){
	print "User '$RUSER' does not have permissions to run this script.\n";
	exit 1;
}

my $dateNtime = strftime "%Y%m%d_%H%M%S", localtime;
my $tag="tfadiagnostics_$dateNtime";

#
# Parse argument
#

my $tfa_home; my $tag; my $local;
my $help;

my $CRS_HOME; my $tfa_base; my $NODELIST; my $EXPECT;

GetOptions(
	'-tfa_home=s' => \$tfa_home,
	'-repo=s' => \$repository,
	'-tag=s' => \$tag,
	'-local' => \$local,
	'-help' => \$help,
	'-h' => \$help
	) or printhelp(1);

# if ($tfa_home){
# 	print "tfa_home : $tfa_home\n";
# }

# if ($repository){
# 	print "repository : $repository\n";
# }

# if ($tag){
# 	print "tag : $tag\n";
# }

# if ($local){
# 	print "local : $local\n";
# }

my $argsleft = scalar(@ARGV);
if ($help || $argsleft){
	print "Invalid option $ARGV[0]\n" if $argsleft > 0;
	printhelp();
	exit;
}

# print help function
sub printhelp{
	my $exit = shift;
	my $tfactl = catfile($tfa_home,"bin","tfactl");
	my $help = <<EOF;

   Usage : $tfactl diagnosetfa [-repo <repository>] [-tag <tag_name>] [-local]

        repository        Repository directory for TFA Diagnostic Collections
        tag_name          The files will be collected into tag_name directory
        local             Run TFA Diagnostics only on local node


EOF
	print $help;

	if(defined($exit) && ($exit == 1)){
		exit;
	}
}

print "\n";

if(-d catdir($repository,$tag)){
	print "Directory [".catdir($repository,$tag)."] already exists. Using new tag for collecting diagnostics...\n";
	print "\n";
	my $dateNtime = strftime "%Y%m%d_%H%M%S", localtime;
	$tag="tfadiagnostics_$dateNtime";
}

if(!(defined($tfa_home) && ($tfa_home ne ''))){
	$tfa_home = get_tfa_home_from_registry();
}

if(-f catfile($tfa_home,"tfa_setup.txt")){
	$CRS_HOME = tfactldiagnostics_getValueOfKeyFromFile(catfile($tfa_home,"tfa_setup.txt"),"CRS_HOME=");
	$PERL=tfactldiagnostics_getValueOfKeyFromFile(catfile($tfa_home,"tfa_setup.txt"),"PERL=");
}

my $HOSTNAME=hostname;

$tfa_base=getParentDirectory($tfa_home);

# Check if TFA HOME contains HOSTNAME
if(!(index($tfa_home, $HOSTNAME) == -1)){
	$tfa_base=getParentDirectory($tfa_base);
}

eval {mkpath(catdir($repository,$tag))} or die "Can't create repo directory: $@\n";

my $node_list="tfa_node_list";

if(-s $node_list){
	unlink $node_list;
}

# Node List
if(defined($local) && ($local ne '')){
	write_to_file($node_list,"$HOSTNAME","W");
}else{
	my @tfahosts = getListOfAllNodes($tfa_home);
	my %uniqueHostMap = map { $_ => 1 } @tfahosts;

	if(-s catfile($CRS_HOME,"crs","install","crsconfig_params")){
		my $list_of_nodes = tfactldiagnostics_getValueOfKeyFromFile(catfile($CRS_HOME,"crs","install","crsconfig_params"),"NODELIST=");
		my @NODELIST = split(/,/,$list_of_nodes);

		foreach my $host (@NODELIST) {
		  my $host = trim($host);
		  if($host ne ''){
		  	$uniqueHostMap{$host} = 1;
		  }
		}

		my @uniqueHostList = keys %uniqueHostMap;
		my $fileContent="";
		foreach my $unqHost (@uniqueHostList){
			$fileContent = $fileContent . "$unqHost". "\n";
		}
		write_to_file($node_list,$fileContent,"W");
	}
}

if(-s $node_list){
	print "Node List to collect TFA Diagnostics : \n";
	print_file_with_line_no($node_list);
	print "\n";
}else{
	print "Unable to determine Node List. Please update manually.\n";
	print "\n";
}


if(!(defined($local) && ($local ne ''))){
	my $option;
	print "Do you want to update this node list? [Y|N|y|n]: ";
    chomp( $option = <STDIN> );
	$option ||= "n";
	$option = get_valid_input ($option, "y|Y|n|N", "Y");

	if ( $option =~ /[Yy]/ ) {
		if(-f $node_list){
			unlink $node_list;
		}

		print "Please Enter all the nodes you want to collect diagnostics...\n";
		print "\n";

		print "Enter Node List (seperated by space) : \n";
		my $usernodelist = <STDIN>;
		chomp $usernodelist;
		print "\n";

		my @NODELIST = split(/ /,$usernodelist);
		my $fileContent="";
		foreach my $host (@NODELIST) {
		  my $host = trim($host);
		  if($host ne ''){
		  	$fileContent = $fileContent . "$host". "\n";
		  }
		}

		write_to_file($node_list,$fileContent,"W");

		if(-s $node_list){
			print "Node List to collect TFA Diagnostics : \n";
			print_file_with_line_no($node_list);
			print "\n";
		}
	}
}

if(! -s $node_list){
	print "Node List to collect TFA Diagnostics is Empty.\n";
	print "\n";
	write_to_file($node_list,"$HOSTNAME","W");
}

my $SAME=0;
my $RUNONLOCAL=0;
my $SSH_STATUS="1";
my $PASS;

open my $info, $node_list or die "Could not open $node_list: $!";
while( my $REMOTE_HOST = <$info>)  {   
    $REMOTE_HOST = trim($REMOTE_HOST);
    if($REMOTE_HOST eq $HOSTNAME){
    	$RUNONLOCAL=1;
		next;
    }

    print "Running TFA Diagnostics on $REMOTE_HOST...\n";	
    $SSH_STATUS = tfactlwin_check_ssh_equivalence($REMOTE_HOST);

	my $TFA_HOME=$tfa_home;

	if($IS_WINDOWS){
		if(!(index($tfa_home, "\\tfa\\$HOSTNAME\\tfa_home") == -1)){
			$TFA_HOME = catdir($tfa_base,$REMOTE_HOST,"tfa_home");
		}
	}else{
		if(!(index($tfa_home, "/tfa/$HOSTNAME/tfa_home") == -1)){
			$TFA_HOME = catdir($tfa_base,$REMOTE_HOST,"tfa_home");
		}
	}
	
	print "\n";
	print "TFA_HOME on $REMOTE_HOST : $TFA_HOME\n";

	my $command= catfile($TFA_HOME,"bin","tfadiagnostics.bat")." -tfahome $TFA_HOME -repository $repository -tag $tag";

	if($IS_WINDOWS){
		my $returnValue = "1";
		if("$SSH_STATUS" eq "0"){
			$returnValue = tfactlwin_ssh_without_cred($REMOTE_HOST,"cmd /c $command");
		}else{
			$SAME = get_password_from_user($SAME,$REMOTE_HOST);
			$returnValue = tfactlwin_ssh($REMOTE_HOST,$RUSER,$PASS,"cmd /c $command");
		}
		if($returnValue eq "0"){
			print "Remote SSH executed successfully.\n";
		}else{
			print "Remote SSH execution failed.\n";
		}
	}else{
		if(("$SSH_STATUS" eq "0") || (!(-f $EXPECT))){
			#$SSH $SSH_USER@$REMOTE_HOST "$command > /dev/null" &
		}else{
			$SAME = get_password_from_user($SAME,$REMOTE_HOST);
			# COMMAND="$SSH $SSH_USER@$REMOTE_HOST $command > /dev/null &";
			# runUsingExpect();
		}
	}
	print "\n";
}
close $info;

if($RUNONLOCAL == 1){
	print "Running TFA Diagnostics on $HOSTNAME...\n";
	print "\n";
	my $cmd = "$PERL ".catfile($tfa_home,"bin","scripts","tfadiagnostics.pl")." -tfahome $tfa_home -repository $repository -tag $tag";
	print `$cmd`;
	print "\n";
	print "Sleeping for 10 Seconds...\n";
	sleep(10);
}else{
	print "Waiting for Remote Nodes to complete TFA diagnostics...\n";
	sleep(30);
}
print "\n";

my $retry_list="tfa_retry_list";

if(-f $retry_list){
	unlink $retry_list;
}

# Try to get zips from remote nodes
for (my $COUNT=0; $COUNT <= 2; $COUNT++) {
	# Sleep for another 10 sec if Retry List is not empty
	if(-s $retry_list){
		print "Waiting for Remote Nodes to complete TFA diagnostics...\n";
		sleep(10);
		print "\n";
		my $cmd;
		if($IS_WINDOWS){
			$cmd = "type $retry_list > $node_list";
		}else{
			$cmd = "cat $retry_list > $node_list";
		}
		system($cmd);
		unlink $retry_list;
	}

	open my $info, $node_list or die "Could not open $node_list: $!";
	while( my $REMOTE_HOST = <$info>)  {   
	    $REMOTE_HOST = trim($REMOTE_HOST);
	    if($REMOTE_HOST eq $HOSTNAME){
			next;
	    }

	    print "Copying TFA Diagnostics from $REMOTE_HOST...\n";
	    $SSH_STATUS = tfactlwin_check_ssh_equivalence($REMOTE_HOST);

		if($IS_WINDOWS){
			my $source=catdir($repository,$tag);
			my $destination=catdir($repository,$tag);
			if("$SSH_STATUS" eq "0"){
				tfactlwin_remote_win_copy_without_cred($REMOTE_HOST,$source,$HOSTNAME,$destination);

				if(-f catfile($repository,$tag,$REMOTE_HOST.".zip")){
					my $cmd = "RD /S /Q ".catdir($repository,$tag)." >nul 2>nul";
					my $returnValue = tfactlwin_ssh_without_cred($REMOTE_HOST,"cmd /c $cmd");
					# if($returnValue eq "0"){
					# 	print "Remote SSH executed successfully.\n";
					# }else{
					# 	print "Remote SSH execution failed.\n";
					# }
				}else{
					if($COUNT != 2){
						my $root = catdir($repository,$tag);
						opendir my $dh, $root or die "$0: opendir: $!";
						my @dirs = grep {-d "$root/$_" && ! /^\.{1,2}$/} readdir($dh);
						my @dirs = grep{/^$REMOTE_HOST/} @dirs;
						foreach my $dir (@dirs){
							my $cmd = "RD /S /Q ".catdir($repository,$tag)." >nul 2>nul";
							my $returnValue = tfactlwin_ssh_without_cred($REMOTE_HOST,"cmd /c $cmd");
							# if($returnValue eq "0"){
							# 	print "Remote SSH executed successfully.\n";
							# }else{
							# 	print "Remote SSH execution failed.\n";
							# }
						}
					}
					write_to_file($retry_list,"$REMOTE_HOST\n","A");
				}
			}else{
				tfactlwin_remote_win_copy($RUSER,$PASS,$REMOTE_HOST,$source,$HOSTNAME,$destination);

				if(-f catfile($repository,$tag,$REMOTE_HOST.".zip")){
					my $cmd = "RD /S /Q ".catdir($repository,$tag)." >nul 2>nul";
					$SAME = get_password_from_user($SAME,$REMOTE_HOST);
					my $returnValue = tfactlwin_ssh($REMOTE_HOST,$RUSER,$PASS,"cmd /c $cmd");
					# if($returnValue eq "0"){
					# 	print "Remote SSH executed successfully.\n";
					# }else{
					# 	print "Remote SSH execution failed.\n";
					# }
				}else{
					if($COUNT != 2){
						my $root = catdir($repository,$tag);
						opendir my $dh, $root or die "$0: opendir: $!";
						my @dirs = grep {-d "$root/$_" && ! /^\.{1,2}$/} readdir($dh);
						my @dirs = grep{/^$REMOTE_HOST/} @dirs;
						$SAME = get_password_from_user($SAME,$REMOTE_HOST);
						foreach my $dir (@dirs){
							my $cmd = "RD /S /Q ".catdir($repository,$tag)." >nul 2>nul";
							my $returnValue = tfactlwin_ssh($REMOTE_HOST,$RUSER,$PASS,"cmd /c $cmd");
							# if($returnValue eq "0"){
							# 	print "Remote SSH executed successfully.\n";
							# }else{
							# 	print "Remote SSH execution failed.\n";
							# }
						}
					}
					write_to_file($retry_list,"$REMOTE_HOST\n","A");
				}
			}
		}else{
			my $source="$repository/$tag/*.*";
			my $destination="$repository/$tag/";
			if(("$SSH_STATUS" eq "0") || (!(-f $EXPECT))){
				# $SCP $SSH_USER@$REMOTE_HOST:$source $destination > /dev/null;
				if(-f catfile($repository,$tag,$REMOTE_HOST.".zip")){
					# $SSH $SSH_USER@$REMOTE_HOST "rm -rf $repository/$tag" > /dev/null &
				}else{
					if($COUNT != 2){
						# rm -f $repository/$tag/$REMOTE_HOST*;
					}
					write_to_file($retry_list,"$REMOTE_HOST\n","A");
				}
			}else{
				$SAME = get_password_from_user($SAME,$REMOTE_HOST);
				# $COMMAND="$SCP $SSH_USER@$REMOTE_HOST:$source $destination";
				runUsingExpect();

				if(-f catfile($repository,$tag,$REMOTE_HOST.".zip")){
					# $COMMAND="$SSH $SSH_USER@$REMOTE_HOST \"rm -rf $repository/$tag\" > /dev/null &";
					runUsingExpect();
				}else{
					if($COUNT != 2){
						# rm -f $repository/$tag/$REMOTE_HOST*;
					}
					write_to_file($retry_list,"$REMOTE_HOST\n","A");
				}
			}
		}
		print "\n";
	}
	close $info;

	# Break if retry list is empty
	if(! -s $retry_list){
		last;
	}
}

# Change permissions of all the zips to 700
if(-d catdir($repository,$tag)){
	my @fileList = getRecursiveFolderContents(catdir($repository,$tag));
	chmod 0700, @fileList;

	print "TFA Diagnostics are being collected to ".catdir($repository,$tag)." :\n";
	my $dirLoc = catfile($repository,$tag);
	if($IS_WINDOWS){
	  my $cwd = getcwd();
	  chdir($dirLoc);
      my $cmd = "dir /s /b *.zip";
      print `$cmd`;
      chdir($cwd);
    }else{
      print `find $dirLoc -type f -name "*.zip"`;
    }
    print "\n";
}else{
	print "Unable to collect TFA Diagnostics. Please try later...\n";
}

# Remove temp files
if(-f $node_list){
	unlink $node_list;
}

if(-f $retry_list){
	unlink $retry_list;
}

print "";
