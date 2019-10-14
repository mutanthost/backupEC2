# 
# $Header: tfa/src/v2/tfa_home/bin/common/tfactlwin.pm /main/14 2018/05/28 15:06:27 bburton Exp $
#
# tfactlwin.pm
# 
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlwin.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bibsahoo    01/30/18 - FIX BUG 26985928
#    bburton     08/28/17 - bug26696360 - windows hyphen in hostname
#    bibsahoo    03/16/17 - TFA_WIN_NONDAEMON_SUPPORT
#    cpujar      09/20/16 - bug 22004118 - TFA INSTALL SHOULD CHK JAVA HOME 
#                           IN SAME PATH ON ALL NODES
#    bibsahoo    09/02/16 - TFAC TYPICAL WINDOWS COMMENTS
#    arupadhy    06/13/16 - Added support for getting username from PID,Service
#                           and Service Identifier
#    bibsahoo    06/02/16 - Windows Typical Install
#    arupadhy    05/24/16 - To make sure initstop from TFAService do not
#                           override AUTO_RUN if the key is chaged before
#                           Service stop. Avoids race condition.
#    arupadhy    03/30/16 - initstop called directly from TFAService, when
#                           service is stopped through service controller
#    arupadhy    02/05/16 - added tfactlwin_get_tfa_main_pid routine
#    arupadhy    01/22/16 - Added module to manage functions related to windows
#                           processes
#    arupadhy    01/20/16 - Creation
# 

package tfactlwin;

BEGIN {
use Exporter();
our (@ISA, @EXPORT);
@ISA = qw(Exporter);
my @exp_func = qw(tfactlwin_stop_pid tfactlwin_trim tfactlwin_kill_tfa_main 
	tfactlwin_kill_tfa_service tfactlwin_enableTFA  tfactlwin_disableTFA  
	tfactlwin_start_tfa  tfactlwin_stop_tfa tfactlwin_shutdown_tfa 
	tfactlwin_check_service  tfactlwin_query_registry tfactlwin_check_os_type 
	tfactlwin_isTFAServiceIsConfigured tfactlwin_isTFAServiceRunning 
	tfactlwin_configureTFAService  tfactlwin_get_tfa_main_pid 
	tfactlwin_deConfigureTFAService  tfactlwin_removeTFAService 
        tfactlwin_get_pid_from_service  tfactlwin_get_username_from_pid 
        tfactlwin_get_username_from_service_identifier tfactlwin_ssh
        tfactlwin_ssh_without_cred tfactlwin_check_ssh_equivalence tfactlwin_remote_win_copy
        tfactlwin_remote_win_copy_without_cred tfactlwin_robocopy tfactlwin_readFileToArray 
        tfactlwin_configure_tfa tfactlwin_check_tfa_main_pid_running tfactlwin_query_OracleTFAService_status);
push @EXPORT,@exp_func;
}

use strict;
use File::Path;
use File::Find;
use File::Spec::Functions;
use File::Basename;

###### Global Variables########
my $IS_WINDOWS=0;
if ( $^O eq "MSWin32" )
{
  $IS_WINDOWS = 1;
  eval q{use Win32::Service qw(StartService StopService GetStatus GetServices); 1} or die $@;
}

my $oracleTFAServiceName = "OracleTFAService";
###### Global Variables########


###### Utility Functions ########
sub tfactlwin_stop_pid{
  my $pid = shift;
  if ($^O eq 'MSWin32') # Windows
  {
    system("taskkill /F /T /PID $pid >nul 2>&1");
  }
  else # Unix
  {
    kill 9, $pid || warn "could not kill process $pid: $!";
  }
}

################################################################################
# Function: Remove leading and trailing blanks.
#
# Arg     : string
#
# Return  : trimmed string
################################################################################
sub tfactlwin_trim{
   my $str = $_;
   $str = shift;
   $str =~ s/^\s+//;
   $str =~ s/\s+$//;
   return $str ;
}
###### Utility Functions ########

sub tfactlwin_kill_tfa_main{
	#Kill the TFAMain process 
	my $PID;

	my @out = `Wmic process where "Name like '\%JAVA\%' and commandline like '\%TFAMain\%'" get caption, name, commandline, ProcessId 2>nul`;
    foreach my $line (@out)
    {   
      if ( $line =~ /tfa.TFAMain.* java\..* (\d+)/i )
      { 
        #print "Stopping TFAMain with pid = $1\n";
		$PID = tfactlwin_trim($1);
		tfactlwin_stop_pid($PID);
      }
    }
}

sub tfactlwin_kill_tfa_service{
	my $PID;
	my @out = `Wmic process where "Name like '\%TFAService.exe\%'" get caption, name, commandline, ProcessId 2>nul`;
	foreach my $line (@out)
	{
		if ( $line =~ /TFAService.exe * * (\d+)/i )
		{
		  #print "Stopping TFAService.exe with pid = $1\n";
		  $PID = tfactlwin_trim($1);
		  tfactlwin_stop_pid($PID);
		}
	}
}

sub tfactlwin_enableTFA {
	`reg add "HKEY_LOCAL_MACHINE\\SoftWare\\Oracle\\KEY_TraceFileAnalyzer" /t REG_SZ /v AUTO_START /d true /f`;
}

sub tfactlwin_disableTFA {
    `reg add "HKEY_LOCAL_MACHINE\\SoftWare\\Oracle\\KEY_TraceFileAnalyzer" /t REG_SZ /v AUTO_START /d false /f`;
}

sub tfactlwin_start_tfa {
	my $tfa_home = shift;

	tfactlwin_stop_tfa();
	
	tfactlwin_kill_tfa_service();

	`reg add "HKEY_LOCAL_MACHINE\\SoftWare\\Oracle\\KEY_TraceFileAnalyzer" /v TFA_HOME /d $tfa_home /f`;
	`reg add "HKEY_LOCAL_MACHINE\\SoftWare\\Oracle\\KEY_TraceFileAnalyzer" /v AUTO_START /d true /f`;
	`reg add "HKEY_LOCAL_MACHINE\\SoftWare\\Oracle\\KEY_TraceFileAnalyzer" /v AUTO_RUN /d true /f`;
	`sc delete OracleTFAService`;
	`sc create OracleTFAService binpath= "$tfa_home\\install\\TFAService.exe" DisplayName= "Oracle Trace File Analyzer" start= auto`;
	`sc failure OracleTFAService reset= 3600 reboot= \"OracleTFAService crashed -- rebooting service\" command= \"".catfile($tfa_home,"install","TFAService.exe")."\" actions= restart/5000/restart/5000/restart/5000`;
	`sc start OracleTFAService`;
}

sub tfactlwin_stop_tfa{
	#Setting AUTO_RUN to false so when we remove the TFAMain service it does not spawn it once again
	`reg add "HKEY_LOCAL_MACHINE\\SoftWare\\Oracle\\KEY_TraceFileAnalyzer" /v AUTO_RUN /d false /f`;
  #Stop the service
  `sc stop OracleTFAService >nul 2>&1`;
  sleep(3);
	tfactlwin_kill_tfa_main();
}

sub tfactlwin_shutdown_tfa{
	`reg add "HKEY_LOCAL_MACHINE\\SoftWare\\Oracle\\KEY_TraceFileAnalyzer" /v AUTO_RUN /d false /f`;
	tfactlwin_kill_tfa_main();

	#Stop the service
	`sc stop OracleTFAService >nul 2>&1`;
  sleep(3);
	tfactlwin_kill_tfa_service();

	`sc delete OracleTFAService`;
}

################ Managing Services ###################

sub tfactlwin_check_service {
    my $service = shift;
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
        print "Failed to retieve list of services\n";
        exit 1;
    };
    %services = reverse %services;

    if (! exists $services{$service}) {
        print "'$service' is not a configured Windows service\n";
        exit 1;
    }

    if (GetStatus('', $service, \%status)) {
        if ($status{"CurrentState"} eq $status_code{'Running'} ) {
            print "$service is running\n";
            return 1;
        }
        elsif ( $status{"CurrentState"} eq $status_code{'Stopped'} ) {
 	       	print "$service is stopped\n";
            return 0;
        }
        elsif ( $status{"CurrentState"} eq $status_code{'StartPending'} ) {
 	       	print "$service is StartPending\n";
            return 1;
        }
    }
    else {
        print "failed to retrieve the status of service '$service'\n";
        exit 1;
    }
    return;
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

# Checks if TFA Service is configured or not in windows
# Return - True or false
sub tfactlwin_isTFAServiceIsConfigured{
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
}

#
# Checks whether TFAService is running
#
sub tfactlwin_isTFAServiceRunning{
	if(tfactlwin_check_service($oracleTFAServiceName)){
		return 1;
	}else{
		return 0;
	}
}

# Configures TFA Service in windows registry
# Parameter - $tfa_home - TFA HOME Path
sub tfactlwin_configureTFAService {
	my $tfa_home = shift;
	my $is_enabled = "true";
	`reg add "HKEY_LOCAL_MACHINE\\SoftWare\\Oracle\\KEY_TraceFileAnalyzer" /v TFA_HOME /d $tfa_home /f`;
	`reg add "HKEY_LOCAL_MACHINE\\SoftWare\\Oracle\\KEY_TraceFileAnalyzer" /v AUTO_START /d $is_enabled /f`;
	`reg add "HKEY_LOCAL_MACHINE\\SoftWare\\Oracle\\KEY_TraceFileAnalyzer" /v AUTO_RUN /d $is_enabled /f`;
	`sc create OracleTFAService binpath= "$tfa_home\\install\\TFAService.exe" DisplayName= "Oracle Trace File Analyzer" start= auto`;
	`sc failure OracleTFAService reset= 3600 reboot= \"OracleTFAService crashed -- rebooting service\" command= \"".catfile($tfa_home,"install","TFAService.exe")."\" actions= restart/5000/restart/5000/restart/5000`;
}

# Removes TFA Service configuration from registry
sub tfactlwin_deConfigureTFAService {
	#Remove TFA_HOME keys from registry
	`reg delete "HKEY_LOCAL_MACHINE\\SoftWare\\Oracle\\KEY_TraceFileAnalyzer" /F`;
}

# Stops and Removes TFA Service if present and deconfigures it
# Parameter - $tfa_home - TFA HOME Path
sub tfactlwin_removeTFAService{
	tfactlwin_shutdown_tfa();
	tfactlwin_deConfigureTFAService();
}

########
# NAME
#   tfactlwin_get_tfa_main_pid
#
# DESCRIPTION
#   This function returns TFAMain pid in case of windows
#
# PARAMETERS
#
# RETURNS
#   returns pid of TFAMain as a string
########   
sub tfactlwin_get_tfa_main_pid{
  my $PID;

  my @out = `Wmic process where "Name like '\%JAVA\%' and commandline like '\%TFAMain\%'" get caption, name, commandline, ProcessId 2>nul`;
    foreach my $line (@out)
    {   
      if ( $line =~ /tfa.TFAMain.* java\..* (\d+)/i )
      { 
        #print "Stopping TFAMain with pid = $1\n";
        $PID = tfactlwin_trim($1);
      }
    }
    return $PID;
}

########
# NAME
#   tfactlwin_check_tfa_main_pid_running
#
# DESCRIPTION
#   This function returns 1 if TFAMain process is running in case of windows
#
# PARAMETERS
#   PID   : PID of TFAMain process
#
# RETURNS
########  

sub tfactlwin_check_tfa_main_pid_running {
  my $PID = shift;
  my $check_process_exist = 0;

  my @out = `Wmic process where "ProcessId like $PID" get caption, name, commandline, ProcessId 2>nul`;
    foreach my $line (@out)
    {   
      if ( $line =~ /java.exe/i )
      { 
        $check_process_exist = 1;
      }
    }
    return $check_process_exist;
}

########
# NAME
#   tfactlwin_get_pid_from_service
#
# DESCRIPTION
#   This function returns pid for a provided service identifier like OracleASMService etc..
#
# PARAMETERS
#   Service Identifier
# RETURNS
#   returns pid of service identifier as a string
########   
sub tfactlwin_get_pid_from_service{
  my $serviceIdentifier = shift;
  my $result = `wmic service get caption, name, processid, startname | findstr $serviceIdentifier`;
  my @lines = split(/\n/,$result);
  my $pid = "";
  foreach my $line (@lines){
    if(tfactlwin_trim($line) ne ""){
      my @tokens = split(/\s{2,}/,$line);
      my $tokenArrLength = scalar @tokens;
      if($tokenArrLength>=2){
        $pid=tfactlwin_trim($tokens[2]);
      }
    }
  }
  return tfactlwin_trim($pid);
}

########
# NAME
#   tfactlwin_get_username_from_pid
#
# DESCRIPTION
#   This function returns username for a pid.
#
# PARAMETERS
#   PID of a process
# RETURNS
#   returns username of the account running the process
########   
sub tfactlwin_get_username_from_pid{
  my $pid = shift;
  my $result = `tasklist /v | findstr \"$pid \"`;
  my @lines = split(/\n/,$result);
  my $username = "";
  foreach my $line (@lines){
    if(tfactlwin_trim($line) ne ""){
      my @tokens = split(/\s{2,}/,$line);
      my $tokenArrLength = scalar @tokens;
      if($tokenArrLength>=4){
        $username=tfactlwin_trim($tokens[4]);
      }
    }
  }
  return tfactlwin_trim($username); 
}

########
# NAME
#   tfactlwin_get_username_from_service_identifier
#
# DESCRIPTION
#   This function returns username for a Service Identifier.
#
# PARAMETERS
#   Service Identifier
# RETURNS
#   returns username of the account running the process corresponding 
#   to a particular Service Identifier
########   
sub tfactlwin_get_username_from_service_identifier{
  my $serviceIdentifier = shift;
  my $pid = tfactlwin_get_pid_from_service($serviceIdentifier);
  my $username = "";
  if($pid ne ""){
    $username = tfactlwin_get_username_from_pid($pid);
  }
  return $username;
}

#ssh equivalents in perl for windows
sub tfactlwin_ssh{
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

sub tfactlwin_ssh_without_cred{
  my $host = shift;
  my $remoteCommand = shift;
  my $localhost = shift;
  my $output_type = shift;

  my $output;
  my @command_output;
  my $returnValue = "1"; # 0 means proper execution else improper execution
  my $cmd;
  my $ignore_output;

  if($output_type eq 'OUTPUT_REDIRECT'){
    my $tmploc_tfa = $ENV{'TMPLOC'};
    my $remote_cmd_temp_dir = catfile($tmploc_tfa, 'tfactl_remote_cmd_dir');
    my $remote_cmd_temp_log = catfile($remote_cmd_temp_dir, "tfactl_remote_command.log");
    my $remote_cmd_temp_log_local = catfile($tmploc_tfa,"tfactl_remote_command.log");

    my $create_remote_dir_cmd = "cmd /c mkdir $remote_cmd_temp_dir"; # Create Remote Temp dir
    my $create_remote_dir_command = "WMIC /node:\"$host\" PROCESS call create \"$create_remote_dir_cmd\"";     
    `$create_remote_dir_command`;

    my $remote_command = "$remoteCommand > $remote_cmd_temp_log 2>&1";
    $cmd = "WMIC /node:\"$host\" PROCESS call create \"$remote_command\"";
    $output = `$cmd`;
     
    tfactlwin_remote_win_copy_without_cred($host,$remote_cmd_temp_dir,$localhost,$tmploc_tfa);
    
    my $remove_remote_dir_cmd = "cmd /c rmdir /S /Q $remote_cmd_temp_dir"; # Remove Remote Temp dir
    my $remove_remote_dir_command = "WMIC /node:\"$host\" PROCESS call create \"$remove_remote_dir_cmd\"";     
    `$remove_remote_dir_command`;

    @command_output = tfactlwin_readFileToArray($remote_cmd_temp_log_local);

    my $remove_remote_temp_log_local_cmd = "cmd /c del /F /Q $remote_cmd_temp_log_local";
    my $remove_remote_temp_log_local_command = "WMIC /node:\"$localhost\" PROCESS call create \"$remove_remote_temp_log_local_cmd\"" if(-f $remote_cmd_temp_log_local);
    `$remove_remote_temp_log_local_command`;
  } else {
    $cmd = "WMIC /node:\"$host\" PROCESS call create \"$remoteCommand\"";
    $output = `$cmd`;
    # print "SSH CMD: $cmd\n";
  }
  my @lines = split(/\n/,$output);
  foreach my $line (@lines) {
    if (index($line, "ReturnValue") != -1) {
      $returnValue = $line;
      $returnValue =~ s/\D//g;
    }
  }
  return $returnValue if($output_type ne 'OUTPUT_REDIRECT');
  return \@command_output,$returnValue if($output_type eq 'OUTPUT_REDIRECT');
}

#check if ssh eqivalence is present b/w the nodes of a cluster
sub tfactlwin_check_ssh_equivalence{
  my $REMOTE_HOST = shift;
  my $SSH_STATUS="1";

  if($IS_WINDOWS) {
    my $returnValue = tfactlwin_ssh_without_cred($REMOTE_HOST,"cmd /c dir");
    if("$returnValue" eq "0"){
      $SSH_STATUS = "0";
    }
  }else{
    # $SSH -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -l $SSH_USER $REMOTE_HOST ls > /dev/null 2>&1
    # SSH_STATUS=$?
  }
  return $SSH_STATUS;
}


#copy files between the nodes
sub tfactlwin_remote_win_copy{
  # Authentication
  my $IPCUser = shift;
  #for IPC$ share
  my $IPCPwd  = shift;
  # Source Host Name
  my $SrcHost = shift;
  # Source Directory Path
  my $SrcDir  = shift;
  # Destination Host Name
  my $DstHost = shift;
  # Destination Directory Path
  my $DstDir  = shift;
  # Parameters (robocopy keys)
  # my $Params = "/XD * /Z /MIR";
  my $Params = "/S /E /NFL /NDL /NJH /NJS ";

  my @SrcDirPath = split(/:/,$SrcDir);
  my $derivedSrcDir = substr($SrcDir,0,1)."\$".$SrcDirPath[1];

  my @DstDirPath = split(/:/,$DstDir);
  my $derivedDesDir = substr($DstDir,0,1)."\$".$DstDirPath[1];

  my $cmd;
  $cmd = "NET USE \\\\$DstHost\\IPC\$ /u:$IPCUser $IPCPwd";
  print `$cmd`;
  $cmd = "robocopy.exe \\\\$SrcHost\\$derivedSrcDir\\ *.* \\\\$DstHost\\$derivedDesDir\\ $Params ";
  # /NFL /NDL /NJH /NJS /nc /ns /np
  print `$cmd`;
  $cmd = "NET USE \\\\$DstHost\\IPC\$ /D";
  print `$cmd`;
}

sub tfactlwin_remote_win_copy_without_cred{
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

# Copies file/Directory as per robocopy in windows.
# Should be used to read very small files like (.pidfile etc.)
# Parameters : $source - source path, $destination - destination path
sub tfactlwin_robocopy{
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

#Conversion for shell command 'cat <filename>' and returns the contents in an array
sub tfactlwin_readFileToArray {
  my $filename = shift;
  my @arr;
  open FILE, "$filename" or die "Could not open $filename!\n";
  while(<FILE>) {
    push @arr, $_;
  }
  close FILE;
  return @arr;
}


sub tfactlwin_configure_tfa {
  my $op = shift;
  my $tfa_home = shift;

  if ( lc($op) eq "start" ) {
    tfactlwin_start_tfa($tfa_home);
  } elsif ( lc($op) eq "stop" ) {
    tfactlwin_stop_tfa($tfa_home);
  } elsif ( lc($op) eq "shutdown" ) {
    tfactlwin_shutdown_tfa($tfa_home);
  }
}

sub tfactlwin_query_OracleTFAService_status {
  my $queryTFAService = `sc query OracleTFAService`;
  if ($queryTFAService && $queryTFAService =~ /STATE\s{1,}:\s{1,}4\s{1,}RUNNING/) {
    return 1;
  } else {
    return 0;
  }
}

################ Managing Services ###################
