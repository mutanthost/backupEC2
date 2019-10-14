# 
# $Header: tfa/src/v2/tfa_home/bin/installTFA.pl /st_tfa_19/1 2019/03/04 23:32:58 bibsahoo Exp $
#
# installTFA.pl
# 
# Copyright (c) 2015, 2019, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      installTFA.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bibsahoo    03/01/19 - XbranchMerge bibsahoo_bug-28804492 from main
#    bibsahoo    12/06/18 - FIX BUG 28804492
#    bibsahoo    11/02/17 - TFA 122130 WIN PATCH FIX
#    bibsahoo    09/22/17 - FIX BUG 26568567
#    bibsahoo    09/14/17 - FIX BUG 26793178
#    bibsahoo    07/26/17 - FIX BUG 26536025
#    bibsahoo    07/17/17 - WINDOWS 12.2.1.2.0 FIX
#    bibsahoo    06/09/17 - TFA PATCHING ON WINDOWS
#    bibsahoo    05/30/17 - tfa_windows_fix
#    bburton     05/26/17 - Receiver not valid on windows
#    bburton     05/10/17 - TFAHOME always has to have lower case hostname
#    bibsahoo    10/05/16 - FIX BUG BUG 24412770 - WS2012_122_TFA: WRONG HELP
#                           INFORMATION FOR TFA_SETUP.BAT
#    cpujar      09/20/16 - Bug 22004118 - TFA INSTALL SHOULD CHK JAVA HOME 
#                           IN SAME PATH ON ALL NODES
#    bibsahoo    09/06/16 - WINDOWS TYPICAL INSTALL BUGS
#    bibsahoo    06/02/16 - Windows Typical Install
#    arupadhy    03/08/16 - POSIX fix and TFA standalone hardstop for corner
#                           case test
#    arupadhy    02/22/16 - Fixed conditions
#    arupadhy    01/28/16 - removed defer discovery flag for grid install
#    arupadhy    01/22/16 - refactored windows process management functions
#    arupadhy    01/10/16 - Added registry key AUTO_START for enable/disable,
#                           and auto reboot support for TFAService.exe if it
#                           stops by any reason.
#    arupadhy    12/07/15 - Patching specific code and cleanup
#    arupadhy    11/26/15 - Set relative position of installtfa.pl as compared
#                           to the base directory where tfa_home is placed
#    arupadhy    09/21/15 - commented code for zip extraction as now it would
#                           not be a part of installation.
#    arupadhy    09/10/15 - added robocopy routines in place of xcopy
#    arupadhy    09/01/15 - installTFALite equivalent for windows, required for
#                           installation, patching etc on the basis of flags
#                           and other variables
#    arupadhy    09/01/15 - initial commit to windows perl installer, converted
#                           from installtfalite (Linux installer)
#    arupadhy    09/01/15 - Creation
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
use English;
use File::Spec::Functions;
use File::Find qw(finddepth);
use File::Path;
use Cwd            qw( abs_path getcwd );
use File::Basename qw( dirname basename );
use File::Copy;
use Getopt::Long;
Getopt::Long::Configure("prefix_pattern=(-|--)");
use Sys::Hostname;
use Win32;
#use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use POSIX qw(strftime);
use Time::Piece;

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME);
  push @INC, dirname($PROGRAM_NAME).'/common';
}

my $UNAME=$^O;
my $PLATFORM=$UNAME;
my $PERL;

use tfactlwin;

### Configure Values ####
#my $windowsZipLocation = catfile(dirname(abs_path($0)),"TFALiteWin.zip");
my $TMPLOC="C:\\TMP";#Temporary location for windows
if(!-d $TMPLOC){
	mkpath([catdir($TMPLOC)]);
}
$ENV{'TMPLOC'}=$TMPLOC;

my $IS_WINDOWS=0;
if ( $^O eq "MSWin32" )
{
  $IS_WINDOWS = 1;
}
### Configure Values ####

#### Utility Functions #####

# Modifies Permission of a File
# Parameters : $modifiedPermission for eg. a+x -> 0111, $filename - path to the file
# No return value, file permissions are modified
sub chmodModifyPerm{
	my $modifiedPermission = shift;
	my $filename = shift;
	
	my $mode = (stat($filename))[2];
	$mode = $mode &07777;
	my $new_mode = $mode | $modifiedPermission;
	chmod ($new_mode, $filename);
}

# Recursively Modifies permissions to all files.
# Parameters : \@files - file path array
# No return value, file permissions are modified
sub chmodModifyPermRecursive{
	my ($modifiedPermission, $files) = @_;
	my $path;
	for my $path(@$files){
		chmodModifyPerm($modifiedPermission,$path);
	}
}

# Returns array of all file and folder names in a given directory (including nested directories)
# Parameter : $dir Directory path
# Returns : @files - array of all file and folder names in a given directory
sub getRecursiveFolderContents{
	my $dir = shift;
	my @files;
	finddepth(sub {
	  return if($_ eq '.' || $_ eq '..');
	  push @files, $File::Find::name;
	}, $dir);
	return @files;
}

# It extracts value for a key in a given file (equivalent to grep + sed in linux)
# Parameter : $fileName - file path, $key - key whose value is to be extracted
# Return : Value for the key
sub getValueFromFile{
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
		
	$line =~ s/$key//;
	return $line;
}

# Loads file content into variable and returns it in string variable.
# Should be used to read very small files like (.pidfile etc.)
# Parameters : $file - file path
# return : $string - content of the file in a string variable
sub getFileContent{
	my $file = shift;

	my $string;
	{
	    local $/;
	    open my $fh, '<', $file or die "can't open $file: $!";
	    $string = <$fh>;
	}

	return $string;
}

# Copies file/Directory as per robocopy in windows.
# Should be used to read very small files like (.pidfile etc.)
# Parameters : $source - source path, $destination - destination path
sub win_robocopy{
  my $source = shift;
  my $destination = shift;

  my $file;
  my $folderName;
  my $newFile;

  if((-f $source) && (-d $destination)){
	$file = basename($source);
	$source = dirname($source);
	$destination = $destination;
	system("robocopy $source $destination $file /NFL /NDL /NJH /NJS /nc /ns /np");
  }elsif((-d $source) && (-d $destination)){
	$folderName = basename($source);
	$destination = catdir($destination,$folderName);
	system("robocopy $source $destination /MIR /S /E /NFL /NDL /NJH /NJS /nc /ns /np");
  }else{
  	$file = basename($source);
  	$newFile = basename($destination);
	$source = dirname($source);
	$destination = dirname($destination);
	system("robocopy $source $destination $file /NFL /NDL /NJH /NJS /nc /ns /np");
	system("move ".catfile($destination,$file)." ".catfile($destination,$newFile));
  }
}

# Trims whitespaces around a string
# Parameters : $s - string that needs to be trimmed
# return : $s - trimmed string
sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

#
# Checks whether CRS is up and running
#
sub isCRSRunning{
  my $CRS_HOME="";
  my $result = tfactlwin_query_registry("crs_home");
  my @lines = split(/\n/,$result);
  foreach my $line (@lines){
    my @tokens = split(/\s+/,$line);
    my $tokenArrLength = scalar @tokens;
    if($tokenArrLength>=4){
      $CRS_HOME=trim($tokens[3]);
    }
  }

  if($CRS_HOME eq ""){
    print "Clusterware is not configured.\n";
    return 0;
  }

  my $crsctl;
  if($IS_WINDOWS){
    $crsctl = catfile($CRS_HOME,"bin","crsctl.exe");
  }else{
    $crsctl = catfile($CRS_HOME,"bin","crsctl");
  }

  my $upServiceCounter = 0;
  my $output = `$crsctl check crs`;
  my @lines = split(/\n/,$output);
  foreach my $line (@lines) {
    if(index($line,"online")!=-1){
      $upServiceCounter = $upServiceCounter + 1;
    }
  }
  if($upServiceCounter == 4){
    return 1;
  }else{
    return 0;
  }
}

# Checks whether directory is empty or not
# Parameters: path to directory
# Returns : 1 if directory is empty
sub is_folder_empty {
    my $dirname = shift;
    opendir(my $dh, $dirname) or die "Not a directory";
    return scalar(grep { $_ ne "." && $_ ne ".." } readdir($dh)) == 0;
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

# Provides the path to parent directory
# Parameters: current directory
# Returns : path to parent directory
sub getParentDirectory{
  my @dirs   = File::Spec->splitdir($_[0]);       # parse directories
  pop @dirs;                                      # remove top dir
  my $newdir = File::Spec->catdir(@dirs);         # create new path
  return $newdir;
}

#provides path to the logfile while installing TFA
sub startlog {
	my $DATEFORFILE = strftime "%Y_%m_%d-%H_%M_%S", localtime;
	chomp($DATEFORFILE);

	my $retStr = catfile("C:", "tfa_install_" . $$ . "_" . $DATEFORFILE . ".log");
	print "TFA Installation Log will be written to File : $retStr\n";
	return $retStr;
}

#### Utility Functions #####

#Check if platform other than windows
if(!$IS_WINDOWS){
	#TODO Need to get a new TFA Number for error.
	print "TFA-00000: Oracle Trace File Analyzer (TFA) installer is not compatible with this platform.";
	exit 1;
}

my $SCRIPT=$0;
my $SILENT;
my $CRSHOME;
my $CRSHOMEFLAG;
my $ORAHOME;
my $ORABASE;
my $ORAHOMEFLAG;
my $DEFERDISCOVERY;
my $LOCALONLY;
my $MODE;
my $BUILDID;

my $TFA_INSTALLED="0";

$BUILDID=

# Extract Current TFA Build Version and Date
my $BUILD_DATE=substr($BUILDID, -14);
my $BUILD_VERSION=substr($BUILDID, 0, -14);

# We might need original Build Date later
my $ORG_BUILD_DATE="$BUILD_DATE";

# Remove Seconds from Build Date
$BUILD_DATE=substr($BUILD_DATE, 0, 12);

# print help function
sub printhelp{
	my $exit_after_print = shift;

 my $help = <<EOF;

   Usage for $SCRIPT

   $SCRIPT [-local][-deferdiscovery][-tfabase <install dir>][-javahome <path to JRE>][-silent][-receiver]

        -local            -    Only install on the local node
        -deferdiscovery   -    Discover Oracle trace directories after installation completes
        -tfabase          -    Install into the directory supplied 
        -javahome         -    Use this directory for the JRE
        -silent           -    Do not ask any install questions
        -receiver         -    TFA runs in receiver mode.  Otherwise run in full mode
        -debug            -    Print debug tracing and do not remove TFA_HOME on install failure
        -perl 			  -    Use given perl binary for execution of perl programs


   Note: Without parameters TFA will take you through an interview process for installation
         /tfa will be appended to -tfabase if it is not already there. 


EOF
	print $help;

	if(defined($exit_after_print) && ($exit_after_print ne '')){
		exit $exit_after_print;
	}
}

# Extract ext jar
sub install_ext {
	my $tfa_home = shift;

	if ($CRSHOME ne ""){
		
		if (! -d catdir($tfa_home,"ext")){
			
			chmodModifyPerm(0111,catdir($tfa_home,"ext"));
			chmodModifyPerm(0111,catdir($tfa_home,"ext","oratop"));
			my @fileList = getRecursiveFolderContents(catdir($tfa_home,"ext","oratop"));
			chmodModifyPermRecursive(0111,\@fileList);
		}
		return;
	}

	if(! -d catdir($tfa_home)){
		
		my $c_loc = dirname(abs_path($0));
		my $java_home_loc = getValueFromFile(catfile($tfa_home,"tfa_setup.txt"),"JAVA_HOME=");
		#TODO Need to verify in environment
#		my $jar_exe = catfile($java_home_loc,"bin","jar");
#		if(! -e $jar_exe){
#			print "ORATOP-WARNING: Could not find java exe program\n";
#			return;
#		}
#		my @args = ($jar_exe, "xf",catfile($tfa_home,"jlib","RATFA.jar"),catfile($tfa_home,"jlib","ext.jar"));
#		system(@args);
#		move("ext.jar", catfile($tfa_home,"ext","ext.jar"));
#		if( -e $java_home_loc){
#			if( -e catfile($tfa_home,"ext","ext.jar")){
#				print "";
#				print "Installing oratop extension..";
#				print "";
#
#				#Windows specific ORA Top command (Currently Linux Commented)
#				#$RM -f oratop/oratop.RDBMS_12.1_LINUX.X64 oratop/oratop.RDBMS_12.1_LINUX.X32 oratop/oratop.RDBMS_11.2_LINUX.X64 oratop/oratop.RDBMS_11.2_LINUX.X32 oratop/oratop.pm
#            	#$jar_exe xf ext.jar oratop/oratop.RDBMS_12.1_LINUX.X64 oratop/oratop.RDBMS_12.1_LINUX.X32 oratop/oratop.RDBMS_11.2_LINUX.X64 oratop/oratop.RDBMS_11.2_LINUX.X32 oratop/oratop.pm
#           	#Windows specific ORA Top command (Currently Linux Commented)
#
#            	unlink "ext.jar";
#            	chmodModifyPerm(0111,catdir($tfa_home,"ext"));
#				chmodModifyPerm(0111,catdir($tfa_home,"ext","oratop"));
#				my @fileList = getRecursiveFolderContents(catdir($tfa_home,"ext","oratop"));
#				chmodModifyPermRecursive(0111,\@fileList);
#			}else{
#
#			}
#		}else{
#			print "ORATOP-WARNING: Unable to find JAVA_HOME";
#		}
		#TODO Need to verify in environment
	}else{
		
		#print "\nORATOP-WARNING: Unable to find tfa_home.\n";
	}
}

# Function to Start TFA
sub start_tfa {
	my $tfa_home = shift;
	
	# Start TFA if its not running
	my $STARTTFA=1;

	if(-f catfile($tfa_home,"internal",".pidfile")){
		my $TFAPID=trim(getFileContent(catfile($tfa_home,"internal",".pidfile")));
		if($TFAPID eq ""){
			my @out = `Wmic process where "Name like '\%JAVA\%' and commandline like '\%TFAMain\%'" get caption, name, commandline, ProcessId`;
			foreach my $line (@out)
			{   
			  if ( $line =~ /tfa.TFAMain.* java\..* (\d+)/i )
			  { 
				$TFAPID = $1;
			  }
			}
			if($TFAPID eq ""){
				$STARTTFA=0;
			}
		}
	}

	if($STARTTFA == 1){
		tfactlwin_start_tfa($tfa_home);
		print "\n";
	}
}

#
# Parse argument
#

my $TFABASE; my $TFA_JAVA; my $JAVA_HOME; my $RECEIVER;
my $PATCH; my $INSTDEBUG; my $HELP; my $TFA_DEBUG; my $PERLHOME;

my $REL_DIR;

GetOptions(
	'silent' => \$SILENT,
	'tfabase=s' => \$TFABASE,
	'crshome=s' => \$CRSHOME,
	'ohome=s' => \$ORAHOME,
	'javahome=s' => \$JAVA_HOME,
	'receiver' => \$RECEIVER,
	'deferdiscovery' => \$DEFERDISCOVERY,
	'local' => \$LOCALONLY,
	'patch' => \$PATCH,
	'debug' => \$INSTDEBUG,
	'help' => \$HELP,
	'h' => \$HELP,
	'perlhome=s' => \$PERLHOME,
	'perl=s' => \$PERL
	) or printhelp(1);

if ($SILENT){
	$SILENT = "-silent";
}
if ($TFABASE){
	print "TFABASE : $TFABASE\n";
	$ENV{"TFABASE"} = $TFABASE;
}
if ($CRSHOME){
	print "CRSHOME : $CRSHOME\n";	
	$ENV{"CRSHOME"} = $CRSHOME;
}
if ($ORAHOME){
	print "ORAHOME : $ORAHOME\n";
	$ENV{"ORAHOME"} = $ORAHOME; 
	$ORAHOMEFLAG = "-ohome";
}
if ($JAVA_HOME){
   print "JAVA_HOME : $JAVA_HOME\n";	
   $ENV{"JAVA_HOME"} = $JAVA_HOME; 
   $TFA_JAVA = $JAVA_HOME;	
}
if ($RECEIVER){
	print "RECEIVER : $RECEIVER\n";
	$MODE=$RECEIVER;
}
if ($DEFERDISCOVERY){
	print "DEFERDISCOVERY : $DEFERDISCOVERY\n";
}
if ($LOCALONLY){  
	print "LOCALONLY : $LOCALONLY\n";
}
if ($PATCH){
	print "PATCH : $PATCH\n";
}
if ($INSTDEBUG){  
	print "INSTDEBUG : $INSTDEBUG\n";
	$TFA_DEBUG =7;
	$ENV{"TFA_DEBUG"} = $TFA_DEBUG;
}
if ($HELP){
	print "HELP : $HELP\n";
}
if ($PERLHOME){
	print "PERLHOME : $PERLHOME\n";
	$ENV{"PERLHOME"} = $PERLHOME;
}
if ($PERL){
	print "PERL : $PERL\n";
	if ( $PERL =~ /\s/ ) {
		$PERL="\"".$PERL."\"";
	}
	$ENV{"PERL"} = $PERL;
}

if($HELP){
	printhelp(0);
}

if(defined($TFABASE) && ($TFABASE ne '') && (! -d $TFABASE)){
	print "TFA-00004: Provided TFA Base Directory $TFABASE does not exist";
	exit 1;
}

if(defined($CRSHOME) && ($CRSHOME ne '') && (! -d $CRSHOME)){
	print "TFA-00005: Provided CRS_HOME directory $CRSHOME does not exist";
	exit 1;
}

if(defined($ORAHOMEFLAG) && ($ORAHOMEFLAG ne '') && ((!defined($ORAHOME) || $ORAHOME eq ''))){
	my $find;
	if(!$IS_WINDOWS){
		$find = "crs/install";
	}else{
		$find = "crs\\install";
	}
	$ORAHOME=substr($SCRIPT,0,index($SCRIPT, $find));
}

if(defined($ORAHOMEFLAG) && ($ORAHOMEFLAG ne '') && (! -d $ORAHOME)){
	print "TFA-00006: Provided ORACLE_HOME directory $ORAHOME does not exist";
	exit 1;
}

if(defined($ORAHOME) && ($ORAHOME ne '') && (-f catfile($ORAHOME,"bin","orabase"))){
	`set ORACLE_HOME=$ORAHOME`;
	$ORABASE=catfile($ORAHOME,"bin","orabase");
}

if(defined($ORAHOMEFLAG) && ($ORAHOMEFLAG ne '') && (! -d $ORABASE)){
	print "TFA-00007: ORACLE_BASE directory '$ORABASE' does not exist";
	exit 1;
}

if(defined($TFA_JAVA) && ($TFA_JAVA ne '') && (! -x catfile($TFA_JAVA,"bin","java.exe"))){
	print "TFA-00008: JAVAHOME supplied does not have ".catfile($TFA_JAVA,"bin","java.exe")." executable";
	exit 1;
}

#TODO - No need to convert as of now
#if [ -n "$TFA_JAVA" ] && [ ! -x "$TFA_JAVA/bin/keytool" ]; then
#  out=$(perl -e "use Cwd 'abs_path'; print abs_path(\"$TFA_JAVA/bin/java\");")
#  out=$(echo $out |sed -n '1s/bin\/java$//p')
#  if [ ! -x "$out/bin/keytool" ]; then
#    $ECHO "TFA-00008: JAVAHOME supplied does not have $out/bin/keytool executable"
#    exit 1
#  fi
#  TFA_JAVA=$out
#  JAVA_HOME=$out
#  export JAVA_HOME
#fi

if(	(defined($CRSHOME) && ($CRSHOME ne '')) || (defined($ORAHOME) && ($ORAHOME ne '')) ){
	if( (defined($TFABASE) && ($TFABASE ne '')) || (defined($TFA_JAVA) && ($TFA_JAVA ne '')) || 
		(defined($DEFERDISCOVERY) && ($DEFERDISCOVERY ne '')) || (defined($LOCALONLY) && ($LOCALONLY ne '')) 
		){
		print "TFA-00009: Invalid Parameters. Do not use any other parameters with -crshome or -ohome\n";
		printhelp(1);
	}
}
 
if ($CRSHOME && -d catdir($CRSHOME, "jdk", "jre")) {
	$TFA_JAVA = catdir($CRSHOME, "jdk", "jre");	
	$ENV{"JAVA_HOME"} = $TFA_JAVA;	
}

if ($ORAHOME && -d catdir($ORAHOME, "jdk", "jre")) {
	$TFA_JAVA = catdir($ORAHOME, "jdk", "jre");
	$ENV{"JAVA_HOME"} = $TFA_JAVA;	
}

if(defined($CRSHOME) && ($CRSHOME ne '') && !(defined($SILENT) && ($SILENT ne ''))){ # -crshome is always a silent install
	$SILENT="-silent";
}

if(defined($CRSHOME) && ($CRSHOME ne '') && !(defined($LOCALONLY) && ($LOCALONLY ne ''))){ # -crshome is always a local install
	$LOCALONLY="-local";
}

if(defined($ORAHOME) && ($ORAHOME ne '')){
	$SILENT="-silent";
  	$LOCALONLY="-local";
}

if (defined($LOCALONLY) && ($LOCALONLY != 0)){
  	$LOCALONLY="-local";
}

if (defined($DEFERDISCOVERY) && ($DEFERDISCOVERY != 0)){
  	$DEFERDISCOVERY="-deferdiscovery";
}

if(defined($CRSHOME) && ($CRSHOME ne '')){
	$CRSHOME =catdir($CRSHOME);
	if(! -f catfile($CRSHOME,"crs","install","crsconfig_params")){
		print "TFA-00010: Provided CRS_HOME directory $CRSHOME is not valid. Please verify once again.\n";
		exit 1;
	}

	$REL_DIR=catdir($CRSHOME,"suptools","tfa","release");
}

if(defined($ORAHOME) && ($ORAHOME ne '')){
	$ORAHOME =catdir($ORAHOME);
	$REL_DIR=catdir($ORAHOME,"suptools","tfa","release");
}

my $HOSTNAME=hostname;
$HOSTNAME=lc($HOSTNAME);

print "\n";
if(defined($MODE) && ($MODE ne '') && $RECEIVER){
	print "Starting TFA installation in receiver mode\n";
}else{
	print "Starting TFA installation\n";
}
print "\n";

# Firstly check if we are root .. If not then stop here.
if(! Win32::IsAdminUser()){
	print "TFA-00011: Oracle Trace File Analyzer (TFA) must be run as as a Windows Admin user";
	exit 1;
}

#Not required for Windows hence commenting
# Check if bash exists
#BASH_EXIST=`which bash >/dev/null 2>&1; $ECHO $?`
#if [ $BASH_EXIST -ne 0 ]
#then
#   $ECHO "TFA-00012: Oracle Trace File Analyzer (TFA) requires BASH shell. Please install bash and try again."
#   exit 1
#fi


# If we are patching then we do not to do a number of the following checks.
# If tfa is already installed just patch
$TFA_INSTALLED="0";
my $INSTALLED_BUILD="0";
my $INSTALLED_BLDDT="0";
my $INSTALLED_BLDVR="0";

# Below varables are used to remove Old TFA after Install.
my $OLD_TFA_HOME;
my $REMOVE_OLD_TFA=0;

my $tfa_home;
my $PATCH_STATUS;
my $TFAMAIN_STATUS;
my $BASEDIR;
my $EXIT_STATUS;
my $tfa_base;
my $CRS_HOME;
my $ORACLE_BASE;

if(tfactlwin_isTFAServiceIsConfigured()){
	$tfa_home=getTFAHomeFromPreviousConfig();

	if($tfa_home eq ""){
		print "\n Could not locate TFA HOME.\n";
		exit;
	}

	$BASEDIR=getParentDirectory(catdir($tfa_home));
	
	if(-r catfile($tfa_home,"bin","tfactl.bat")){
		$TFA_INSTALLED=1;

		print "TFA Build Version: $BUILD_VERSION Build Date: $BUILD_DATE\n";

		if(-f catfile($tfa_home,"internal",".buildid")){
			$INSTALLED_BUILD= trim(getFileContent(catfile($tfa_home,"internal",".buildid")));

			# Extract Current TFA Build Version and Date
			$INSTALLED_BLDDT=substr($INSTALLED_BUILD, -14);
			$INSTALLED_BLDVR=substr($INSTALLED_BUILD, 0, -14);

			# Get Build Version from .buildversion
			my $buildVersionFile = catfile($tfa_home,"internal",".buildversion");
			if( -f $buildVersionFile ){
				$INSTALLED_BLDVR=trim(getFileContent($buildVersionFile));
			}

			# If Installed version is null then set it to 0
			if(!(defined($INSTALLED_BLDVR) && ($INSTALLED_BLDVR ne ''))){
				$INSTALLED_BLDVR=0;
			}

			# Remove Seconds from Build Date
			$INSTALLED_BLDDT=substr($INSTALLED_BLDDT, 0, 12);

			print "Installed Build Version: $INSTALLED_BLDVR Build Date: $INSTALLED_BLDDT\n";
			print "\n";
		}

		# Check and see its a new TFA_HOME for GI Install
		if(defined($CRSHOME) && ($CRSHOME ne '') && (index($tfa_home, $CRSHOME) == -1)){
			#Shutdown TFA if it is running
			if(tfactlwin_isTFAServiceRunning()){
				print "Shutting Down TFA for Patching...\n";
        my $qxCommand = catfile($tfa_home,"bin","tfactl")." -initstop";
        system($qxCommand);
				print "\n";
			}

			# Remove init.tfa
			if(tfactlwin_isTFAServiceIsConfigured()){
				tfactlwin_removeTFAService();
			}

			print "Installing TFA new version at ".catdir($CRSHOME,"tfa",$HOSTNAME,"tfa_home")."...\n";
			print "\n";

			#Do a Fresh Install
			$TFA_INSTALLED=0;

			# Check Build Version
		}elsif($BUILD_VERSION >= $INSTALLED_BLDVR){
			if(defined($CRSHOME) && ($CRSHOME ne '')){
				# Check Build Date
				if(Time::Piece->strptime($BUILD_DATE, "%Y%m%d%H%M") >= Time::Piece->strptime($INSTALLED_BLDDT, "%Y%m%d%H%M")){
					# TFA will get upgraded if Build Date is greater than installed Build Date
					if(Time::Piece->strptime($BUILD_DATE, "%Y%m%d%H%M") == Time::Piece->strptime($INSTALLED_BLDDT, "%Y%m%d%H%M")){
						#Just Start TFA if its not running and Exit
						print "TFA is already running latest version. No need to patch.\n";
						print "\n";

						# Start TFA if its not running
						start_tfa($tfa_home);

						exit 0;
					}
				}else{
					#Just Start TFA if its not running and Exit
					print "TFA is already running latest version. No need to patch.\n";
					print "\n";

					# Start TFA if its not running
					start_tfa($tfa_home);

					exit 0;
				}
			}elsif (Time::Piece->strptime($BUILD_DATE, "%Y%m%d%H%M") <= Time::Piece->strptime($INSTALLED_BLDDT, "%Y%m%d%H%M")){
				# END OF BUILD_DATE - CRSHOME
				# Check for NON-GI Install
				# TFA will get upgraded if Build Date is greater than installed Build Date
				print "TFA is already running latest version. No need to patch.\n";
				print "\n";
				exit 0;
			}
		}else{
			#END of CRSHOME	
			print "TFA is already running latest version. No need to patch.\n";
			print "\n";

			# Start TFA if its not running
			if(defined($CRSHOME) && ($CRSHOME ne '')){
				start_tfa($tfa_home);
			}
			exit 0;
		}# END of CHECK BUILD_VERSION
	}else{
		#No TFA Binaries. Remove init.tfa and do fresh install.
		print "Not able to find TFA binaries.\n";
		tfactlwin_removeTFAService();
	}
}

if("$TFA_INSTALLED" eq "1"){
	my $TFA_INSTALLER = abs_path($SCRIPT);
	$ENV{"TFA_INSTALLER"} = $TFA_INSTALLER;
}

#TODO Need to verify this, if required
# archive required for patching and not patching
#my $ARCHIVE=`$AWK '/^__ARCHIVE_BELOW__/ {print NR + 1; exit 0; }' $0`

#Only do the basedir and crs_up checks if we are doing a new install.
if($TFA_INSTALLED == "0"){
	# And more over don't do them if we are passed the -crshome as CRS is unlikely to be up and we know where the BASE is .
	if(defined($CRSHOME) && ($CRSHOME ne '')){ # CRSHOME was supplied 
		$BASEDIR=catdir($CRSHOME,"tfa");
		$CRSHOMEFLAG="-crshome $CRSHOME";
        if ( ! -d $BASEDIR ){
        	mkpath([catfile($BASEDIR)]);
        }
	}elsif(defined($ORAHOME) && ($ORAHOME ne '')){
    	$BASEDIR=catdir($ORABASE,"tfa");
    	$CRSHOMEFLAG="-ohome $ORAHOME -obase $ORABASE";
    	if(! -d $BASEDIR){
    		mkpath([catfile($BASEDIR)]);
    	}
    }else{
    	# Check if CRS is up
    	my $crs_up;
    	if(isCRSRunning()){
    		$crs_up=1;
    	}else{
    		$crs_up=0;
    		if(defined($SILENT) && ($SILENT ne '')){
    			print "TFA-00013: CRS must be running for Silent Mode install. Exiting Installation";
    			exit 1;
    		}
    	}
  		
  		if(defined($TFABASE) && ($TFABASE ne '')){ # We supplied the install dir
  			$BASEDIR=$TFABASE;
  		}else{
  			$BASEDIR=getcwd();
  			print "Enter a location for installing TFA (/tfa will be appended if not supplied) [$BASEDIR]: ";
  			$BASEDIR = <STDIN>;
  			chomp($BASEDIR);
  		}

		# Check if default BASEDIR ends with /tfa. If not add /tfa to BASEDIR.
		if ( ($BASEDIR !~ /\\tfa$/) && ($BASEDIR !~ /\/tfa$/) ) {
			$BASEDIR = catdir($BASEDIR,"tfa");
		}

		# Create BASEDIR if it does not exist
		if(! -d $BASEDIR){
			mkpath([catfile($BASEDIR)]);
		}
	}
}

#Load content of zip in ZFILE 
#copy($windowsZipLocation,catfile($BASEDIR,"tfa_install.$$.zip")) or die "Copy failed: $!";

#TODO make sure the files are getting created at right locations as we are not able to change the directory as in shell file.
my $currentDirectory = $BASEDIR;

my $ZFILE=catfile($BASEDIR,"tfa_install.$$.zip");
my $LOGFILE;

if($TFA_INSTALLED == "1"){
	print "TFA is already installed. Patching $tfa_home...\n";

	$PATCH_STATUS="1";
  	$TFAMAIN_STATUS="0";

	my $patchLog = catfile($BASEDIR,"tfapatch.log");
	print "LOGFILE: $patchLog\n";

  	if(defined($CRSHOME) && ($CRSHOME ne '')){
  		#If the ZIP FILE Size > 0 use that else use release DIR.
  		if(-s $ZFILE){
  			if(! -e catdir($TMPLOC)){
  				mkpath([catdir($TMPLOC)]);
  			}
			#extractZip($ZFILE,$BASEDIR);
			win_robocopy(catdir(dirname(abs_path($0)),"tfa_home"),catdir($TMPLOC));
			my $qxCommand = "$PERL ".catfile($REL_DIR,"tfa_home","bin","patchtfa.pl")." -local -silent -cwd $TMPLOC -log $patchLog"; 
  			$EXIT_STATUS = system($qxCommand);
  		}elsif( -d catdir($REL_DIR)){
  			my $qxCommand = "$PERL ".catfile($REL_DIR,"tfa_home","bin","patchtfa.pl")." -local -silent -cwd $REL_DIR -log $patchLog"; 
  			$EXIT_STATUS = system($qxCommand);
  		}else{
  			print "TFA-00014: Invalid TFA Installer. Please Contact Oracle Support for Help.";
			unlink $ZFILE;
			exit 1;
  		}
	}else{
		if ($IS_WINDOWS && not length $SILENT){ # We are on windows so this is installtfa.pl in the newly unzipped tfa_home/bin
        	    	if(! -e catdir($TMPLOC)){
                		mkpath([catdir($TMPLOC)]);
	        	}
	            	my $installbase = catdir(dirname(abs_path($0)));
	            	$installbase =~ s/\\tfa_home\\bin//;
	            	print "Using $installbase for the extracted tfa_home base directory\n";
	            	win_robocopy(catdir(($installbase),"tfa_home"),catdir($TMPLOC));
            	    	print "Copied $installbase\tfa_home to $TMPLOC\n";
            	    	my $qxCommand = "$PERL ".catfile($installbase,"tfa_home","bin","patchtfa.pl")." $LOCALONLY $SILENT -cwd $TMPLOC -log $patchLog";
		        print "executing: $qxCommand\n";
            	    	$EXIT_STATUS = system($qxCommand);
  		}else{
  			print "Unable to patch TFA...\n";
			print "\n";
			print "TFA-00014: Invalid TFA Installer. Please Contact Oracle Support for Help.\n";
			unlink $ZFILE;
			exit 1;
  		}
	}

	if(-f catfile($TMPLOC,".tfa.patch")){
		$PATCH_STATUS=trim(getFileContent(catfile($TMPLOC,".tfa.patch")));
		unlink catfile($TMPLOC,".tfa.patch");
	}

	# If its patched properly then generate cookie and copy buildid
	if($PATCH_STATUS eq "0"){
		install_ext($tfa_home);
		# We no longer support file for cookie.
		# Remove it if its already present.
		if (-r catfile($tfa_home,"internal",".tfacookie")){
			unlink catfile($tfa_home,"internal",".tfacookie");
		}

		# Check status of TFAMain
		my $qxCommand = catfile($tfa_home,"bin","tfactl")." -check > NUL";
		$TFAMAIN_STATUS = system($qxCommand);
		if ($TFAMAIN_STATUS == 1) {
			#$ECHO "Setting TFA cookie clusterwide"
			my $qxCommand = catfile($tfa_home,"bin","tfactl")." generatecookie";
			$EXIT_STATUS = system($qxCommand);

			$qxCommand = "echo $ORG_BUILD_DATE > ".catfile($tfa_home,"internal",".buildid");
			$EXIT_STATUS = system($qxCommand);

			$qxCommand = "echo $BUILD_VERSION > ".catfile($tfa_home,"internal",".buildversion");
			$EXIT_STATUS = system($qxCommand);

			#Start inventory after patch
			$qxCommand = catfile($tfa_home,"bin","tfactl")." run inventory";
			$EXIT_STATUS = system($qxCommand);
		}
	}

	# Print Upgrade Status
	if(!(defined($PATCH) && ($PATCH ne ''))){
		my $qxCommand = catfile($tfa_home,"bin","tfactl")." print upgradestatus $BUILD_VERSION";
		$EXIT_STATUS = system($qxCommand);
	}
	
	# rmtree $TMPLOC;
	unlink $ZFILE;
	unlink catfile($BASEDIR,"tfa_home","tfahome_full.tar");

	if($TFAMAIN_STATUS == 1){
		exit 0;
	}else{
		exit 1;
	}
}else{
	if((defined($CRSHOME) && ($CRSHOME ne '')) || (defined($ORAHOME) && ($ORAHOME ne ''))){
		$tfa_base=catdir($BASEDIR,$HOSTNAME);
		$tfa_home=catdir($tfa_base,"tfa_home");
		#Add TFA HOME to environment
		$ENV{TFA_HOME} = $tfa_home;

		if ( ! -d catdir($BASEDIR,"bin")){
			mkpath([catdir($BASEDIR,"bin")]);
			chmodModifyPerm(0111,catdir($BASEDIR,"bin"));
		}

		if(! -d catdir($tfa_base)){
			mkpath([catdir($tfa_base)]);
			chmodModifyPerm(0111,catdir($tfa_base));	
		}

		#If the ZIP FILE Size > 0 use that else use release DIR.
		#TODO currently not considering to get zip from any other location. Need to be changed in future.
		if (-s "$ZFILE"){
			#extractZip($ZFILE,$BASEDIR);
			my $DIR_LOC_TFA = getParentDirectory(getParentDirectory(dirname(abs_path($0))));
			win_robocopy(catdir($DIR_LOC_TFA,"tfa_home"),catdir($tfa_base));
		}elsif(-d catdir($REL_DIR,"tfa_home")){
			win_robocopy(catdir($REL_DIR,"tfa_home"),catdir($tfa_base));
		}else{
			print "TFA-00014: Invalid TFA Installer. Please Contact Oracle Support for Help.";
			unlink $ZFILE;
			exit 1;
		}

		$LOGFILE = startlog();
	 	my $qxCommand = "$PERL ".catfile($tfa_home,"bin","tfasetup.pl")." $SILENT -logfile $LOGFILE $CRSHOMEFLAG $DEFERDISCOVERY $LOCALONLY"; #TODO Review this line
	 	$EXIT_STATUS = system($qxCommand);
	}else{
		# This is an ODA/Windows so we never provide CRSHOME
		$tfa_base = catdir($BASEDIR,$HOSTNAME);
		$tfa_home=catdir($tfa_base,"tfa_home");
		#extractZip($ZFILE,$tfa_base);
		if(! -d $tfa_base){
			mkpath([catfile($tfa_base)]);
		}
		my $cmd1;
		if ( ! -d catdir($BASEDIR,"bin")){
			mkpath([catdir($BASEDIR,"bin")]);
			chmodModifyPerm(0111,catdir($BASEDIR,"bin"));
		}

		my $DIR_LOC_TFA = getParentDirectory(getParentDirectory(dirname(abs_path($0))));
		win_robocopy(catdir($DIR_LOC_TFA,"tfa_home"),catdir($tfa_base));
		$cmd1 = installtfa_get_cp_cmd(catfile($tfa_home,"bin","tfactl.bat"),catdir($BASEDIR,"bin"));
		#print "CMD: $cmd1\n";
		`$cmd1`;
		$LOGFILE = startlog();
		my $qxCommand = "$PERL ".catfile($tfa_home,"bin","tfasetup.pl")." $SILENT $MODE -logfile $LOGFILE $DEFERDISCOVERY $LOCALONLY";
	 	$EXIT_STATUS = system($qxCommand);
	 	
	}
}

my $TEMP_LOG_DIR = catdir($TMPLOC,"tfa",strftime('%Y%m%d_%H%M%S',localtime));

#$EXIT_STATUS should have value 0 for successful completion of above program execution
if ($EXIT_STATUS == 0){
	install_ext($tfa_home);

	print "\n";
	print "TFA is successfully installed...\n";
	print "\n";
	
	my $qxCommand = catfile($tfa_home,"bin","tfactl")." -help";
	system($qxCommand);

	#Remove Old TFA Home if present
	if($REMOVE_OLD_TFA == 1){
		if(-d catdir($OLD_TFA_HOME)){
			print "Removing Old TFA $OLD_TFA_HOME...\n";
			rmtree $OLD_TFA_HOME;
		}
	}
}else{
	
	print "Removing TFA Setup files...\n";
	exit;
	#Move the TFA logs to /tmp

	my $LOG_DIR=catdir($tfa_home,"log");
	my $BDB_DIR;
	my $OUT_DIR;
	my $SHARED_FILE;
	my $REPO_DIR;

	if(-f catfile($tfa_home,"tfa_setup.txt")){
		$CRS_HOME=getValueFromFile(catfile($tfa_home,"tfa_setup.txt"),"CRS_HOME=");
		$ORACLE_BASE=getValueFromFile(catfile($tfa_home,"tfa_setup.txt"),"ORACLE_BASE=");
		if(defined($CRS_HOME) && ($CRS_HOME ne '')){
			#Check if TFA_HOME is under CRS_HOME [ GI Install ]
			if (index($CRS_HOME, $tfa_home) != -1) {
			    if(defined($ORACLE_BASE) && ($ORACLE_BASE ne '')){
			    	$LOG_DIR=catdir($ORACLE_BASE,"tfa",$HOSTNAME,"log");
					$BDB_DIR=catdir($ORACLE_BASE,"tfa",$HOSTNAME,"database");
					$OUT_DIR=catdir($ORACLE_BASE,"tfa",$HOSTNAME,"output");
					$SHARED_FILE=catfile($ORACLE_BASE,"tfa",".$HOSTNAME.shared");
					$REPO_DIR=catdir($ORACLE_BASE,"tfa","repository");
			    }
			} 
		}
	}
	print "\n";

	my $LOG_COUNT;
	++$LOG_COUNT while glob "$LOG_DIR/*";
	
	my $TEMP_LOG_DIR;

	if( (-d catdir($LOG_DIR)) && (defined($LOG_COUNT) && ($LOG_COUNT ne '')) && ($LOG_COUNT >=1) ){		
		if(! -d $TEMP_LOG_DIR){
			mkpath([catfile($TEMP_LOG_DIR)]);
		}
		print "Copying TFA logs to $TEMP_LOG_DIR\n";
		my $qxCommand = win_robocopy(catdir($LOG_DIR),catdir($TEMP_LOG_DIR));
		system($qxCommand);
		print "\n";
	}else{
		print "No TFA Logs in $LOG_DIR to copy to $TEMP_LOG_DIR.\n";
		print "\n";
	}

	# Shutdown TFA if it is running
	if(tfactlwin_isTFAServiceRunning()){
		print  "Shutting down TFA now...\n";
    print "\n";
    my $qxCommand = catfile($tfa_home,"bin","tfactl")." -initstop";
    system($qxCommand);
		print "\n";
	}

	# Do not remove TFA if we supply the -debug option
	if($INSTDEBUG){
		print "Leaving TFA_HOME in tact due to -debug flag: $tfa_home...\n";
	}else{
		# Remove init.tfa
		if(tfactlwin_isTFAServiceIsConfigured()){
			tfactlwin_removeTFAService();
		}

		# Remove TFA Log Directory
		if(-d catdir($LOG_DIR)){
			print "Removing $LOG_DIR...\n";
			rmtree $LOG_DIR;
		}

		# Remove Shared File 
		if( defined($SHARED_FILE) && ($SHARED_FILE ne '') && (-f catfile($SHARED_FILE)) ){
			print "Removing $SHARED_FILE...\n";
			unlink $SHARED_FILE;
		}

		# Remove BDB in ORACLE_BASE
		if( defined($BDB_DIR) && ($BDB_DIR ne '') && (-d catdir($BDB_DIR)) ){
			print "Removing $BDB_DIR...\n";
			rmtree $BDB_DIR;
		}

		# Remove Output Directory in ORACLE_BASE
		if( defined($OUT_DIR) && ($OUT_DIR ne '') && (-d catdir($OUT_DIR)) ){
			print "Removing $OUT_DIR...";
			rmtree $OUT_DIR;
		}
		
		# Remove <ORACLE_BASE>/tfa/<NODE>
		if(defined($CRS_HOME) && ($CRS_HOME ne '')){
			my $OB_TFA = catdir($ORACLE_BASE,"tfa",$HOSTNAME);
			if(-d catdir($OB_TFA)){
				print "Removing $OB_TFA...\n";
				rmtree $OB_TFA;
			}
		}

		# Remove TFA_HOME
		if(-d catdir($tfa_home)){
			print "Removing TFA_HOME $tfa_home...\n";
	  		rmtree $tfa_home;
		}

		# Remove TFA_BASE/HOSTNAME
		if(-d catdir($BASEDIR,$HOSTNAME)){
			print "Removing ".catdir($BASEDIR,$HOSTNAME)."...\n";
			rmtree catdir($BASEDIR,$HOSTNAME);
		}

		# Remove GIHOME/bin/tfactl
		if(defined($CRS_HOME) && ($CRS_HOME ne '') && (-f catfile($CRS_HOME,"bin","tfactl.bat"))){
			print "Removing ".catfile($CRS_HOME,"bin","tfactl.bat")."...\n";
			unlink catfile($CRS_HOME,"bin","tfactl.bat");
		}
	}
	# Remove repository if its empty.
	if(defined($CRS_HOME) && ($CRS_HOME ne '')){
		if(defined($ORACLE_BASE) && ($ORACLE_BASE ne '')){
			$REPO_DIR=catdir($ORACLE_BASE,"tfa","repository");
		}else{
			if(-f catfile($tfa_base,"ora_stack_status.out")){
				$ORACLE_BASE= getValueFromFile(catfile($tfa_base,"ora_stack_status.out"),"ORACLE_BASE=");
				$REPO_DIR=catdir($ORACLE_BASE,"tfa","repository");
			}
		}
	}else{
		$REPO_DIR=catdir($BASEDIR,"repository");
	}

	if(-d catdir($REPO_DIR)){
		if(is_folder_empty(catdir($REPO_DIR))){
			print "Repository[$REPO_DIR] is not Empty to delete.\n";
		}else{
			print "Removing Repository $REPO_DIR\n";
			rmtree $REPO_DIR;
		}
	}
}

sub installtfa_get_cp_cmd{
  my $source = shift;
  my $destination = shift;

  my $file;
  my $folderName;
  my $newFile;
  my $cmd;

  if ( $IS_WINDOWS ){
    if((-f $source) && (-d $destination)){
      $file = basename($source);
      $source = dirname($source);
      $destination = $destination;
      $cmd = "robocopy $source $destination $file /NFL /NDL /NJH /NJS /nc /ns /np";
    }elsif((-d $source) && (-d $destination)){
      $folderName = basename($source);
      $destination = catdir($destination,$folderName);
      $cmd = "robocopy $source $destination /MIR /S /E /NFL /NDL /NJH /NJS /nc /ns /np";
    }else{
      $file = basename($source);
      $newFile = basename($destination);
      $source = dirname($source);
      $destination = dirname($destination);
      $cmd = "robocopy $source $destination $file /NFL /NDL /NJH /NJS /nc /ns /np; move ".catfile($destination,$file)." ".catfile($destination,$newFile);    
    }
  }else{
    $cmd = "cp $source $destination";
  } 

  return $cmd;
}

unlink $ZFILE;
rmtree catdir($tfa_home,"tfa_install");

print "\n";

my $dir = catdir($tfa_home, "log");
if (-f catfile($tfa_home,"tfa_setup.txt")) {
	my $install_type = getValueFromFile(catfile($tfa_home,"tfa_setup.txt"),"INSTALL_TYPE=");

	if ($install_type eq "GI" || $install_type eq "DB") {
		$dir = catdir($ORACLE_BASE, "tfa", $HOSTNAME, "log");
	}
}

if (! -d $dir) {
	if (! -d $TEMP_LOG_DIR) {
		mkpath($TEMP_LOG_DIR);
	}
	$dir = $TEMP_LOG_DIR;
}

print "\n\nMoving Install log file to " . $dir . "\n\n";
copy($LOGFILE, $dir);
unlink($LOGFILE);

exit $EXIT_STATUS;
