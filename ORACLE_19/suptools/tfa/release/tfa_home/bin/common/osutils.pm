# 
# $Header: tfa/src/v2/tfa_home/bin/common/osutils.pm /main/26 2018/05/28 15:06:27 bburton Exp $
#
# osutils.pm
# 
# Copyright (c) 2015, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      osutils.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     10/18/17 - Add function to grep for a string in a file
#    llakkana    09/18/17 - Add df & zip functions
#    recornej    09/14/17 - Fix osutils_runtimedcommand crashes when there is
#                           no $LOG
#    manuegar    04/06/17 - manuegar_windows_srdc01.
#    bburton     03/13/17 - add checksu and runtimedcommand
#    gadiga      08/26/16 - fix 24528012
#    gadiga      08/23/16 - cred management
#    bburton     08/02/16 - Handle IOS
#    arupadhy    08/01/16 - Added subroutines to count files in a directory and
#                           create file list from a directory
#    gadiga      06/01/16 - add get offset function
#    arupadhy    05/27/16 - getting exact bytes through du for linux
#    bibsahoo    05/23/16 - FIX BUG 21887154 - [12201-LIN64-TFA]ACCESS ADD
#                           SHOULD CHECK USER/GRP EXISTENCE ON REMOTE NODE
#    llakkana    05/04/16 - Remove GetOptionsFromArray as it is not supported
#                           by older versions like 5.8.8
#    manuegar    04/12/16 - Bug 23088441 - TFA: INCIDENT DIAG COLLECTION
#                           'TFAIPS*.LOG' NOT FOUND ERROR.
#    manuegar    03/22/16 - Added osutils_getFileSize
#    sgoggi      03/14/16 - only create topic.txt as root
#    arupadhy    01/17/16 - fix in osutils_chmod to add the initial digit 1 or
#                           0 indicating directory or non directory by
#                           identifying the path type in routine itslef rather
#                           then from the place of function call.created
#                           function to obtain user domain in case of windows
#                           users
#    cnagur      11/16/15 - Added osutils_getFileOwner
#    gadiga      11/09/15 - ade env variables
#    arupadhy    10/23/15 - added routines for windows crs service check and
#                           oracle home path for windows
#    arupadhy    10/07/15 - added certain global variables for osutils.pm,
#                           added functions for removing files/directories,
#                           copy files/directories, getting oracle running
#                           instance list required for instance monitoring for
#                           windows and linux, and modified changepermission
#                           function
#    llakkana    10/05/15 - Creation
# 
############################ Functions List#################################
# osutils_du
# osutils_chmod
#
############################################################################

package osutils;

BEGIN {
use Exporter();
our (@ISA, @EXPORT);
@ISA = qw(Exporter);
my @exp_func = qw(osutils_du osutils_check_available_space osutils_chmod osutils_export2wrapfile 
                  osutils_getRecursiveFolderContents osutils_rm osutils_cp 
                  osutils_getOracleInstanceList osutils_check_os_type osutils_get_oracle_home_path 
                  osutils_query_registry osutils_isCRSRunning osutils_getFileOwner osutils_getFileSize 
                  osutils_getuserdomain osutils_get_offset_in_file_for_time
                  osutils_get_list_of_available_users osutils_get_list_of_available_win_groups
                  osutils_count_files_in_directory osutils_create_file_list_from_directory 
		  osutils_runtimedcommand osutils_get_uncompressed_size osutils_df osutils_grep_file);
push @EXPORT,@exp_func;
}

use strict;
use File::Path;
use File::Find;
use File::Spec::Functions;
use Getopt::Long;
Getopt::Long::Configure("prefix_pattern=(-|--)");
use File::Basename;
use Sys::Hostname;
use Cwd 'abs_path';

###### Global Variables########
my $MV;
my $CP;
my $OSNAME;
my $IS_WINDOWS=0;
if ( $^O eq "MSWin32" )
{
  $IS_WINDOWS = 1;
  $MV = "move";
  $OSNAME = $^O;
}else{
  $MV = "mv";
  $CP = "cp";
  $OSNAME = `uname`;
}
###### Global Variables########

if ($IS_WINDOWS)
{
  eval q{use Win32::Service qw(StartService StopService GetStatus GetServices); 1} or die $@;
}

#==== du equivalent function  ====#
sub osutils_du 
{
  my $dir = shift;
  my $retval = shift;
  if ( ! -d $dir ) {
    print "ERROR: $dir is not a directory \n";
  }
  else {
    my $size = 0;
    if (osutils_trim($OSNAME) eq "Linux") {
      my @array = `du -s -B1 $dir | grep '$dir\$'`;
      foreach (@array){
          chomp;
          my ($out_size, $out_dir) = split;
          $size = osutils_trim($out_size);
      }
    }else{
      find( sub { -f and ( $size += -s _ ) }, $dir );
    }
    if($retval){
      return $size;
    }else{
      print "$size\n";
    }
  }
}

#==== Get total size of mount point ====#
sub osutils_df
{
  my $dir = shift;
  my $return = shift;
  my $total = osutils_check_available_space($dir,1,"total");
  print "$total\n";
}

#==== df equivalent function  ====#
sub osutils_check_available_space 
{
  my $dir = shift;
  my $retval = shift;
  my $type = shift;

  if ( ! -d $dir ) {
    print "ERROR: $dir is not a directory \n";
  }
  else {
    my $space_available = 0;
    my $space_used = 0;
    my $cmd;
    if($IS_WINDOWS){
      my $absolute_dir_path = abs_path($dir);
      my $drive = substr($absolute_dir_path, 0, index($absolute_dir_path, ':'));
      $cmd = "wmic /node:\"%COMPUTERNAME%\" LogicalDisk Where DriveType=\"3\" Get DeviceID,FreeSpace|find /I \"$drive:\"";
      my $result = `$cmd`;
      $result =~ s/\D//g;
      $space_available = int(int($result)/(1024)); # Will give space in KB
    }else{
      $cmd = "df -Pk $dir";
      my @output = split(/\n/, `$cmd`);
      my $numlines = scalar(@output)."\n";

      if ($numlines == 3) {
        my $avail = $output[2];
        $avail =~ s/\s+/ /g; # replace multiple white spaces with single white space
        $avail =~ s/^\s+//; # remove space at the beginning
        my @result = split(/\s/, $avail);
        $space_available = $result[2];
	$space_used = $result[1];
      }elsif($numlines == 2) {
        my $avail = $output[1];
        $avail =~ s/\s+/ /g; # replace multiple white spaces with single white space
        $avail =~ s/^\s+//; # remove space at the beginning
        my @result = split(/\s/, $avail);
        $space_available = $result[3];
	$space_used = $result[2];
      }else{
        print "ERROR: Unable to check available space for $dir \n";
      }
    }

    if ($type eq "total") {
      $space_available = $space_available + $space_used;
    }

    if($retval){
      return $space_available;
    }else{
      print "$space_available\n";
    }
  }
}

# Changes File Permission
sub osutils_chmod 
{
  my $args =shift;

  my $seperator="~~";
  my $pair_seperator="=";
  my @pairValues;

  my $perm;
  my $path;
  my $flag_r;
  my $pattern;

  my @fileList;

  #Parse flags
  my @argList = split(/$seperator/, $args);
  foreach my $arg (@argList){
    if(index($arg, "-perm") != -1){
      @pairValues = split(/$pair_seperator/, $arg);
      $perm = osutils_trim($pairValues[1]);
    }elsif(index($arg, "-path") != -1){
      @pairValues = split(/$pair_seperator/, $arg);
      $path = osutils_trim($pairValues[1]);
    }elsif(index($arg, "-pattern") != -1){
      @pairValues = split(/$pair_seperator/, $arg);
      $pattern = osutils_trim($pairValues[1]);
    }elsif(index($arg, "-r") != -1){
      $flag_r = "1";
    }
  }

  # print "\n perm : $perm\n";
  # print "\n path : $path\n";
  # print "\n pattern : $pattern\n";
  # print "\n flag_r : $flag_r\n";

  if ( ! -e $path ) {
    print "ERROR: $path does not exists \n";
  }
  else {
    if(defined $perm && $perm ne ''){
      if((-d $path)){
        if($flag_r){
          @fileList = osutils_getRecursiveFolderContents(catdir($path));
          push @fileList,$path;
        }elsif(defined($pattern) && ($pattern ne '')){
          @fileList = osutils_getRecursiveFolderContents(catdir($path));
          @fileList = grep{/$pattern/} @fileList;
        }else{
          chmod(oct($perm),$path);
          return;
        }
        foreach my $location (@fileList){
          chmod(oct($perm),$location);
        }
      }else{
        chmod(oct($perm),$path);
      }
    }else{
      print "ERROR: '$perm' is an improper permission \n";
    }
  }
}

#===========osutils_export2wrapfile================#
#We call same fun osutils_export2wrapfile from tfactladmin if root.
#For non root we call it from NonRootMessageHandler.java file.
sub osutils_export2wrapfile
{
  my $ckey = shift;
  my $servers = shift;
  my $requser = shift;

  if ( ! -r $ckey )
  {
    print "ERROR: Can't open $ckey\n";
    return;
  }
 
  my %opts;
  open(RF, $ckey);
  while(<RF>)
  {
    chomp;
    if ( /^(\w+)=(.*)/ )
    {
      $opts{$1} = $2;
    }
  }
  close(RF);
  my $crs_home = $opts{"crshome"};
  my $tfa_home = $opts{"tfahome"};
  my $cname = $opts{"client"};
  my $ropts = $opts{"ropt"};
  my $keyfile = $opts{"keyfile"};
  my @r = split(/\[/, $ropts);

  osutils_write_topic($tfa_home);
  my ($cversion, $cwfile, $cguid);
  $cversion = $r[1];
  my $newf = 1;
if ( $r[2] =~ /export=(.*)/ )
  {
    $cwfile = $1;
    if ( -e $cwfile )
    {
      $newf = 0;
      # Check and make sure $requser can write to this file.
       my $fileowner = getpwuid((stat($cwfile))[4]);
      if ( $fileowner ne $requser )
      {
        print "ERROR: Failed to export to wrap file as file owner $fileowner is not $requser\n";
        return;
      }
    }
  }
  $cguid = $r[3];

  $ENV{ORACLE_HOME} = $crs_home;
  my $ORACLE_HOME = $crs_home;
  $ENV{LD_LIBRARY_PATH} = $ORACLE_HOME."/lib";

  my $outfile = catfile ( $tfa_home, "tfa_setup.txt");
  my $is_ade = 0;
  if ( -r $outfile )
  {
    my $css_cluster = "";
    open(F1, $outfile);
    while(<F1>)
    {
      chomp;
      $is_ade = 1 if ( /NODE_TYPE=ADE/ );
      $css_cluster = $1 if ( /CSS_CLUSTERNAME=(.*)/ );
    }
    close(F1);
    if ( $is_ade == 1 )
    {
      $ENV{CSS_CLUSTERNAME} = $css_cluster;
      $ENV{OCR_DEVELOPER_ENV} = "TRUE";
    }
  }
  
  system("$ORACLE_HOME/jdk/bin/java -cp $tfa_home/jlib/RATFA.jar:$ORACLE_HOME/jlib/clscred.jar:$ORACLE_HOME/jlib/srvm.jar oracle.rat.tfa.uc.TFAManageCredentials -export \"$cwfile\" -client \"$cname\" -guid \"$cguid\" -servers \"$servers\"  -version \"$cversion\" -keyfile \"$keyfile\" 2>&1");

  open(WKF, ">$keyfile.new");
  open(RKF, "$keyfile");
  while(<RKF>)
  {
    print WKF $_ if ( /^detailsof\./ );
  }
  close(RKF);
  close(WKF);
  system("cp -f $keyfile.new $keyfile");
  system("rm -f $keyfile.new");

  if ( $newf == 1 )
  {
    system("chown $requser $cwfile");
  }
  print "Successfully exported TFA credentials for $cname to $cwfile\n";
}

sub osutils_write_topic
{
  my $tfa_home = shift;
  my $loc = catfile($tfa_home, "internal","topic.txt");
  my $localhost=osutils_tolower_host();
  my $hostName = $localhost;
  if ( ! -f $loc )
  {
    open OUT,">$loc" or die $!;
    print OUT $hostName;
    close(OUT);
  }
  return $hostName;
}

sub osutils_tolower_host
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


# Returns array of all file and folder names in a given directory (including nested directories)
# Parameter : $dir Directory path
# Returns : @files - array of all file and folder names in a given directory
sub osutils_getRecursiveFolderContents{
  my $dir = shift;
  my @files;
  finddepth(sub {
    return if($_ eq '.' || $_ eq '..');
    push @files, $File::Find::name;
  }, $dir);
  return @files;
}

# Forcefully removes files
# Parameters : fileName
sub osutils_rm
{
  my $path = shift;
  if ( ! -e $path) {
    print "ERROR: $path does not exists \n";
  }else{
    if(-d $path){
      rmtree($path);
    }else{
      unlink $path;
    }
    if(-e $path){
        print "ERROR: Unable to delete File. File still exists!";
    }else{
        print "SUCCESS: File successfully deleted";
    }
  }
}

sub osutils_cp {
  my $source = shift;
  my $destination = shift;
  my $force = shift;
  my $file;
  my $folderName;
  my $newFile;
  my $forceFlag = "";

  if ( $IS_WINDOWS ){
    if($force eq "1"){
      $forceFlag = "/IS";
    }
    if((-f $source) && (-d $destination)){
      $file = basename($source);
      $source = dirname($source);
      $destination = $destination;
      system("robocopy $source $destination $file /NFL /NDL /NJH /NJS /nc /ns /np $forceFlag");
    }elsif((-d $source) && (-d $destination)){
      $folderName = basename($source);
      $destination = catdir($destination,$folderName);
      system("robocopy $source $destination /MIR /S /E /NFL /NDL /NJH /NJS /nc /ns /np $forceFlag");
    }else{
      $file = basename($source);
      $newFile = basename($destination);
      $source = dirname($source);
      $destination = dirname($destination);
      system("(robocopy $source $destination $file /NFL /NDL /NJH /NJS /nc /ns /np $forceFlag) & ($MV ".catfile($destination,$file)." ".catfile($destination,$newFile).")");
    }
  }else{
    if($force eq "1"){
      $forceFlag = "-f";
    }
    if((-d $source) && (-d $destination)){
      system("$CP -R $forceFlag $source $destination");
    }else{
      system("$CP $forceFlag $source $destination");
    }
  }
  # if (!$?){
  #   print "SUCCESS: Successfully copied $source to $destination";
  # }else{
  #   print "ERROR: Unable to copy $source to $destination";
  # }
}

sub osutils_getOracleInstanceList{
  my $command;
  if ( $IS_WINDOWS ){
    $command = "sc query| findstr Oracle | findstr SERVICE_NAME";
  }else{
    $command = "ps -ef | grep pmon | grep -v grep";
  }
  system($command);
}

sub osutils_check_os_type{
  my $type =`IF EXIST "%PROGRAMFILES(X86)%" (ECHO 64BIT) ELSE (ECHO 32BIT)`;
  return $type;
}

sub osutils_get_oracle_home_path{
  my @ohomes=();
  if($IS_WINDOWS){
    my $result = osutils_query_registry("ORACLE_HOME");
    my @lines = split(/\n/,$result);
    foreach my $line (@lines){
      my @tokens = split(/\s+/,$line);
      my $tokenArrLength = scalar @tokens;
      if($tokenArrLength>=4){
        push @ohomes, osutils_trim($tokens[3]);
      }
    }
  }else{
    my $oratabfile = "";
    if(-f "/etc/oratab"){
      $oratabfile = "/etc/oratab";
    }elsif(-f "/var/opt/oracle/oratab"){
      $oratabfile = "/var/opt/oracle/oratab";
    }
    if(-f $oratabfile){
      @ohomes = `cat $oratabfile  |grep -v ASM | grep -v IOS |grep -v APX |grep -v MGMTDB |grep -v '^#' |grep / |cut -d":" -f2 |sort  -u`;
    }
  }
  return @ohomes;
}

sub osutils_query_registry{
  my $key =shift;
  my $BASE_KEY="HKEY_LOCAL_MACHINE\\SOFTWARE\\Oracle";
  my $result="";

  my $type = osutils_trim(osutils_check_os_type());
  my $REGISTRY_QUERY_TYPE;

  if($type eq "64BIT"){
    $REGISTRY_QUERY_TYPE = "/reg:64";
  }else{
    $REGISTRY_QUERY_TYPE = "/reg:32";
  }

  $result = `reg query $BASE_KEY /s /e /f $key $REGISTRY_QUERY_TYPE | findstr $key`;
  return $result;
}

sub osutils_isCRSRunning{
  my $CRS_HOME = shift;
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

sub check_service {
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
        print "Failed to retieve list of services";
        exit 1;
    };
    %services = reverse %services;

    if (! exists $services{$service}) {
        print "'$service' is not a configured Windows service";
        exit 1;
    }

    if (GetStatus('', $service, \%status)) {
        if ($status{"CurrentState"} eq $status_code{Running} ) {
            print "$service is running";
            return 1;
        }
        elsif ( $status{"CurrentState"} eq $status_code{'Stopped'} ) {
          print "$service is stopped";
            return 0;
        }
    }
    else {
        print "failed to retrieve the status of service '$service'";
        exit 1;
    }
    return;
}

sub osutils_getFileOwner {
	my $file = shift;

	if ( ! -e "$file" ) {
		print "ERROR: File $file not found\n";
	} else {
		my $ownerid = (stat $file)[4];
		my $owner = (getpwuid $ownerid)[0];
		print "$owner\n";
	}
}

sub osutils_getFileSize {
        my $file = shift;
        my $fsize = 0;

        if ( ! -e "$file" ) { 
                $fsize = -1;
        } else {
                $fsize = (stat $file)[7];
        }   
        return $fsize;
}

sub osutils_getuserdomain{
  my $domain = `echo %userdomain%`;
  $domain = osutils_trim($domain);
  print $domain;
}

sub osutils_trim{
   my $str = $_;
   $str = shift;
   $str =~ s/^\s+//;
   $str =~ s/\s+$//;
   return $str ;
}

sub osutils_get_offset_in_file_for_time
{
  my $file = shift;
  my $fts = shift;

  my %mon2num = ( "jan" => "01",
                  "feb" => "02",
                  "mar" => "03",
                  "apr" => "04",
                  "may" => "05",
                  "jun" => "06",
                  "jul" => "07",
                  "aug" => "08",
                  "sep" => "09",
                  "oct" => "10",
                  "nov" => "11",
                  "dec" => "12");

  my $ts = "";
  $fts = $1 if ( $fts =~ /(\d{14}).*/);
  open(RF, $file);
  my $offset = 0;
  my $lno = 0;

  while(<RF>)
  {
    chomp;
    if ( /^(\d+)-(\d+)-(\d+)[T\s](\d+):(\d+):(\d+)/ )
    {
      $ts = "$1$2$3$4$5$6";
      last if ( $ts >= $fts);
    }
     elsif ( /^\w+ (\w+) (\d+) (\d+):(\d+):(\d+) (\d\d\d\d)/ )
    { # Wed May 25 18:17:17 2016
      my $mn = $mon2num{lc($1)};
      $ts = "$6".$mn."$2$3$4$5";
      last if ( $ts >= $fts);
    }
    $offset += 1 + length ;
    $lno++;
  }
  close(RF);
  return "$lno:$offset";

}

########
# NAME
#   osutils_get_list_of_available_users
#
# DESCRIPTION
#   This routine gets list of available users
#
# PARAMETERS
#
# RETURNS
#
########
sub osutils_get_list_of_available_users {
    my $tfa_home = shift;
    my @user_list;
    my @filtered_lines;
    my $available_users;

    if($IS_WINDOWS){
      my @group_list = osutils_get_list_of_available_win_groups($tfa_home);
      foreach my $group (@group_list){
          $available_users = `net localgroup \"$group\"`;
          my @lines = split(/\n/,$available_users);
          my $user_block=0;

          foreach my $line (@lines) {
              if (index($line, "The command completed successfully") != -1) {
                  $user_block=0;
              }
              if($user_block==1){
                  push @user_list, osutils_trim($line);
              }
              if ($user_block==0 && index($line, "---------") != -1) {
                  $user_block=1;
              }
          }
      }

      @user_list = osutils_uniq(@user_list);
    }else{
      
      if( -f catfile("/","etc","passwd")){
        $available_users = `cut -d: -f1 /etc/passwd`;
        my @lines = split(/\n/,$available_users);

        foreach my $line (@lines) {
          push @user_list, osutils_trim($line);
        }
      }

    }

    return @user_list;
}


########
# NAME
#   osutils_get_list_of_available_win_groups
#
# DESCRIPTION
#   This routine gets list of available groups from windows
#
# PARAMETERS
#
# RETURNS
#
########
sub osutils_get_list_of_available_win_groups {
    my $tfa_home = shift;
    my @group_list;
    my @filtered_lines;
    my $available_groups;
    my $win_user_group = catfile($tfa_home,"internal","win_user_groups.txt");
    if (length("$tfa_home") != 0 && -e $win_user_group) {
      open(my $fh, '<', $win_user_group) or die "cannot open file $win_user_group";
      {
          local $/;
          $available_groups = <$fh>;
      }
      #print $available_groups;
      close($fh);
    } else {
      $available_groups = `net localgroup`;
    }
    my $group_block=0;

    my @lines = split(/\n/,$available_groups);
    
    foreach my $line (@lines) {
        if (index($line, "The command completed successfully") != -1) {
            $group_block=0;
        }
        if($group_block==1){
            $line =~ s/\*//;
            push @group_list, osutils_trim($line);
        }
        if ($group_block==0 && index($line, "---------") != -1) {
            $group_block=1;
        }
    }

    return @group_list;
}

sub osutils_uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

sub osutils_count_files_in_directory{
  my $dir = shift;
  my $retval = shift;
  if ( ! -d $dir ) {
    print "ERROR: $dir is not a directory \n";
  }
  else {
    my $counter = 0;
    find( sub { -f && $counter++ }, $dir );
    if($retval){
      return $counter;
    }else{
      print "$counter\n";
    }
  }
}

sub osutils_create_file_list_from_directory{
  my $dir = shift;
  my $min = shift;
  my $filePath = shift;
  if ( ! -d $dir ) {
    print "ERROR: $dir is not a directory \n";
  }
  else {
    my @files = ();
    my $current_time = time();

    find( sub { 
        my $file_created_before_min = ($current_time - (stat($_))[9])/(60);
        if($min eq "0"){
          if( -f $_) { push @files, $File::Find::name;}
        }else{
          if( (-f $_) && $file_created_before_min<=$min) { push @files, $File::Find::name;}
        }}
    , $dir );
    if(scalar(@files)>0){
      open(CF1, ">>$filePath");
      print CF1 join("\n",@files)."\n";
      close(CF1);
    }
  }
}

sub osutils_get_uncompressed_size {
  my $file = shift;
  my $unCompSize = 0;
  my $cmd;
  my $output;
  if (-f $file) {
    $cmd = "unzip -l $file | tail -1";
    $output = `$cmd`;
    chomp($output);
    if ($output =~ /^(\d+)\s+.*/) {
      $unCompSize = $1;
    } 
  }
  return $unCompSize;
}

sub osutils_runtimedcommand  {
my $command = shift;
my $timeout = shift;
my $retoutput = shift;
my $LOG = shift;
my $cmdoutput = "";

if ( !$timeout ) { $timeout = 10 };
  eval {
      local $SIG{ALRM} = sub { die "Timeout\n" };
      alarm $timeout;
      if ( $retoutput ) {
        $cmdoutput = `$command`;
      } else {
       `$command`;
      }
      alarm 0;
  };
  if ($@) {
      print $LOG localtime(time) . ": $command timed out.\n" if $LOG;
      return(99);
  } elsif ($? != 0 && !$retoutput) {
      print $LOG localtime(time) . ": $command failed error $?.\n" if $LOG ;
      return(1);
  } else {
      print $LOG localtime(time) . ": $command success.\n" if $LOG;
      return $cmdoutput if $retoutput;
      return(0);
  }
}

sub osutils_grep_file  {
   my $file = shift;
   my $regex = shift;
   my $retcode = 0;
   open FH,"<", $file;
   if (grep { /$regex/ } <FH>) {
      return 1;
   } else { 
      return 0;
   }
}

1;
