# 
# $Header: tfa/src/v2/ext/managelogs/managelogs.pm /st_tfa_19/1 2018/09/24 23:05:04 bibsahoo Exp $
#
# managelogs.pm
# 
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      managelogs.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bibsahoo    09/19/18 - XbranchMerge bibsahoo_bug-28274887 from main
#    bibsahoo    09/17/18 - FIX BUG 28274887
#    recornej    07/19/18 - Fix exit codes.
#    manuegar    11/02/16 - Bug 24948477 - WS2012_122_TFA: HELP INFORMATION FOR
#                           'TFACTL RUN GREP' INCORRECT.
#    bibsahoo    10/14/16 - Removing variable CURRENT_USER
#    arupadhy    07/08/16 - Setting ADR BASE incase if environment variable not
#                           set.
#    arupadhy    06/24/16 - Made managelogs compatible with Windows
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    arupadhy    05/05/16 - Creation from script provided by Ruggero (rcitton)
# 
package managelogs;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(deploy
                 autostart
                 start
                 stop
                 restart
                 status
                 run
                 runstatus
                 is_running
                 help
                );

use strict;
use Math::BigInt;
use tfactlglobal;
use tfactlshare;
use osutils;

use List::Util qw[min max];
use POSIX qw(:termios_h);
use POSIX qw(strftime);

use File::Basename;
use File::Spec::Functions;
use File::Path;
use Term::ANSIColor;
use File::Find;
use Getopt::Long;
use Sys::Hostname;
use Text::ASCIITable;

my $tool = "managelogs";
my $tfa_base = tfactlshare_get_repository_location($tfa_home);
my $tool_dir = catfile($tfa_base, "suptools", "$hostname", $tool);
my $tool_base = catfile($tfa_base, "suptools", "$hostname", $tool, $current_user);

my @data_types = ("ALERT","INCIDENT","TRACE","CDUMP","HM","UTSCDMP","LOG");
my @dir_to_clean = ("alert","incident","trace","cdump","hm","utscdmp","log");
my @df_headers;

# ----------------------------------------------------------------------
# Variables
# ----------------------------------------------------------------------
my $crshome;
my $IS_DRY_RUN = 0;
my $SAVE_USAGE = 0;
my $usage_snapshot_dir;
my @aopath;

# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------
my $tracefile;
my $mgmt_db_diag_path;
my $rdbms_path_pattern;
my %message_type_colors = ('INFO' => 'bold blue', 'WARNING' => 'bold yellow', 'ERROR' => 'bold red', 'MESSAGE' => 'bold magenta');
my $def_purge_age = 30; # 30 days
my $def_show_variation = 7; # 7 days


sub deploy 
{
  my $tfa_home = shift;
  return 0;
}

sub autostart
{
  return 0;
}

sub is_running 
{
  return 1;
}

sub runstatus 
{
  return 3;
}

sub start 
{
  print "Nothing to do !\n";
  return 0;
}

sub stop 
{
  print "Nothing to do !\n";
  return 0;
}

sub restart 
{
  print "Nothing to do !\n";
  return 0;
}

sub status
{
  print "managelogs does not run in daemon mode\n";
  return 0;
}

sub run
{
  my $tfa_home = shift;  
  my @args = @_;
  @ARGV=@args;

  #######################################################################################
  ### Commandline argument variables
  #######################################################################################
  my $purge;
  my $age;
  my $gi;
  my $database;
  my $show;
  my $dryrun;
  my $saveusage;
  my $help;

  #######################################################################################
  ### Internal variables
  #######################################################################################
  my $base_commands = 0; # Count of total base commands
  my $current_base_command;
  my $time;
  my $unknownopt;

  #Parse flags

      my %options =  ( "purge" => \$purge,
                       "since" => \$age,
                       "older" => \$age,
                       "gi" => \$gi,
                       "database" => \$database,
                       "show" => \$show,
                       "dryrun" => \$dryrun,
                       "saveusage" => \$saveusage,
                       "h" => \$help,
                       "help" => \$help );

  my @arrayoptions = ( "purge",
                       "since=s",
                       "older=s",
                       "gi",
                       "database:s",
                       "show=s",
                       "dryrun",
                       "saveusage",
                       "h",
                       "help"
                        );

  GetOptions(\%options, @arrayoptions ) or $unknownopt = 1;

  if ( $help || $unknownopt ){ 
    help();
    return 1 if ( $unknownopt );
    return 0;
  }

  tfactlshare_trace(5, "tfactl (PID = $$) managelogs run " .
                    "Running dbglevel", 'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) managelogs run " .
                    "Args received @args", 'y', 'y');

  #######################################################################################
  ### Overridden variables
  #######################################################################################
  if($IS_WINDOWS){
    @df_headers = qw(Caption FileSystem FreeSpace Size SystemName VolumeName);
    $mgmt_db_diag_path = "diag\\\\rdbms\\\\_mgmtdb";
    $rdbms_path_pattern = "diag\\\\rdbms";
  }else{
    @df_headers = qw(name size used free capacity mount);
    $mgmt_db_diag_path = "diag/rdbms/_mgmtdb";
    $rdbms_path_pattern = "diag/rdbms";
  }
  
  if(-e $ENV{"HOME"}){
  	# Changing the directory as adrci if in a particular diagnostic directoy gives home path
  	# only specific to that directory.
  	chdir($ENV{"HOME"}); 
  }
  $crshome = get_crs_home($tfa_home);
  $IS_DRY_RUN = $dryrun;
  $SAVE_USAGE = $saveusage;
  $tracefile = catfile($tool_base,"purgelogs.trc");
  if( ! -f $tracefile ){
    `$TOUCH $tracefile`;
  }
  chmod(0644,$tracefile);
  $usage_snapshot_dir = catdir($tool_dir,"usage_snapshot");
  if( ! -d $usage_snapshot_dir){
  	mkdir($usage_snapshot_dir);
  	chmod(0755,$usage_snapshot_dir);
  }

  #######################################################################################
  ### Argument validation
  #######################################################################################
  
  if($purge){
    trace("OTHER", "ARG [purge : $purge]");
    $base_commands++;
    $current_base_command = "PURGE";
  }

  if(defined($show)  && ($show ne '')){
    trace("OTHER", "ARG [show : $show]");
    if( !( ($show eq "usage") || ($show eq "variation") ) ){
      trace("ERROR", "Show switch takes values usage or variation.");
      help();
      return 1;
    }
    $base_commands++;
    $current_base_command = "SHOW";
  }

  if ($age) {
    trace("OTHER", "ARG [older : $age]");
    my $is_valid = tfactlmanagelogs_validate_since_switch($age);
    if(!$is_valid){ help(); return 1; }
  }

  if ($dryrun) {
    trace("OTHER", "ARG [dryrun : $dryrun]");
  }

  # checking validity of database flag
  if($database){
    trace("OTHER", "ARG [database : $database]");
    # my $is_valid = tfactlmanagelogs_validate_db_list($database);
    # if(!$is_valid){ help(); return 1; }
  }

  if($database){
    trace("OTHER", "ARG [saveusage : $saveusage]");
  }
 
  # checking incompatible argument combination
  if((defined($dryrun)) && ($current_base_command ne "PURGE")){
    trace("ERROR", "Improper combination of switches.\n-dryrun is used along with -purge.");
    help();
    return 1;
  }

  if((defined($age)) && ($show eq "usage")){
    trace("ERROR", "Improper combination of switches.\n-older is used along with -show usage.");
    help();
    return 1;
  }

  if (defined($saveusage) && (lc($current_user) ne "root")) {
  	trace("ERROR", "Only root user is allowed to save usage information.");
    help();
    return 1;
  }

  if( ((defined($saveusage)) && ($current_base_command ne "SHOW")) || ( (defined($saveusage)) && ($show ne "usage"))){
  	trace("ERROR", "Improper combination of switches.\n-saveusage should be used alongwith -show usage.");
    help();
    return 1;
  }

  # Adding trace

  tfactlshare_trace(5, "tfactl (PID = $$) managelogs run " .
                     "Total commands found $base_commands", 'y', 'y');
  if ( @ARGV || $#args == -1 || $base_commands > 1 || $base_commands==0 ) {
    trace("ERROR", "Improper arguments provided for manage logs.");
    help();
    return 1;
  }


  #######################################################################################
  ### Function handling
  #######################################################################################
  my $age_minutes;

  if($purge){

    if(!defined($age)){
    	if($IS_DRY_RUN){
    		trace("INFO", "Estimating files older than $def_purge_age days\n");
    	}else{
    		trace("INFO", "Purging files older than $def_purge_age days\n");
    	}
	    $age_minutes = $def_purge_age*24*60;
    }else{
      # Calculate age
      $age_minutes = $age;
      $age_minutes =~ s/d$//;
      $age_minutes = int($age_minutes);

      if($age =~ /^(\d+)h{1}$/){
      	if($IS_DRY_RUN){
      		trace("INFO", "Estimating files older than $age_minutes hours\n");
    		}else{
    			trace("INFO", "Purging files older than $age_minutes hours\n");
    		}
        $age_minutes = $age_minutes * 60;
      }elsif($age =~ /^(\d+)d{1}$/){
      	if($IS_DRY_RUN){
      		trace("INFO", "Estimating files older than $age_minutes days\n");
    		}else{
    			trace("INFO", "Purging files older than $age_minutes days\n");
    		}
        $age_minutes = $age_minutes * 24 * 60;
      }else{
      	if($IS_DRY_RUN){
      		trace("INFO", "Estimating files older than $age_minutes minutes\n");
    		}else{
    			trace("INFO", "Purging files older than $age_minutes minutes\n");
    		}
      }
    }

    trace("INFO", "Space is calculated in bytes [without round off]\n");
    if((defined($gi) && defined($database)) || ((!defined($gi)) && (!defined($database)))){
      trace("OTHER", "[ Option : Purge All ]");
      cleanGI($age_minutes);
      cleanOH($age_minutes,$database);
    }elsif(defined($gi)){
      trace("OTHER", "[ Option : Purge GI ]");
      cleanGI($age_minutes);
    }elsif(defined($database)){
      trace("OTHER", "[ Option : Purge Database ]");
      cleanOH($age_minutes,$database);
    }

  }elsif($show){


  	if( $show eq "usage" ){
      	trace("OTHER", "[ Option : usage ]");

      	if((defined($gi) && defined($database)) || ((!defined($gi)) && (!defined($database)))){
	      trace("OTHER", "[ Option : Show All ]");
	      showGIusage();
	      showOHusage($database);
	    }elsif(defined($gi)){
	      trace("OTHER", "[ Option : Show GI ]");
	      showGIusage();
	    }elsif(defined($database)){
	      trace("OTHER", "[ Option : Show Database ]");
	      showOHusage($database);
	    }
      
    }elsif( $show eq "variation" ){
      trace("OTHER", "[ Option : variation ]");

		if(!defined($age)){
			trace("ERROR","Please enter -older value in hours and days for usage variation calculation\n");
			help();
			return 1;
		}else{
			# Calculate age
			$age_minutes = $age;
			$age_minutes =~ s/d$//;
			$age_minutes = int($age_minutes);

			if($age =~ /^(\d+)h{1}$/){
				trace("INFO", "Checking space variation for $age_minutes hours\n");
				$age_minutes = $age_minutes * 60;
			}elsif($age =~ /^(\d+)d{1}$/){
				trace("INFO", "Checking space variation for $age_minutes days\n");
				$age_minutes = $age_minutes * 24 * 60;
			}else{
				trace("ERROR","Please enter age in hours and days for usage calculation\n");
				help();
				return 1;
			}

      trace("INFO", "Space is calculated in bytes [without round off]\n");
			if((defined($gi) && defined($database)) || ((!defined($gi)) && (!defined($database)))){
		      trace("OTHER", "[ Option : Show variation All ]");
		      showGIvariation($age_minutes);
		      showOHvariation($age_minutes,$database);
	    }elsif(defined($gi)){
	      trace("OTHER", "[ Option : Show variation GI ]");
	      showGIvariation($age_minutes);
	    }elsif(defined($database)){
	      trace("OTHER", "[ Option : Show variation Database ]");
	      showOHvariation($age_minutes,$database);
	    }

		}

    }



  }


  return 0;
}

sub help
{
  my $cmd;
  if ( $0 =~ /(.*)\.pl/ ) {
    $cmd = $1;
  }
  print "Usage : $cmd [run] managelogs [ -purge [[-older <n><m|h|d>] | [-gi] | [-database <all|d1,d2..>] | [-dryrun] ]] [ -show [usage|variation] [ [-older <n><d>] | [-gi] | [-database <all|d1,d2..>] ] ] [-node <all|local|node1,node2..>]\n\n";
  print "Options: \n";
  print "-purge           Purge logs\n";
  print "   -older        Timeperiod for log purge\n";
  print "   -gi           Purge Grid Infrastructure logs(all ADR homes under GIBASE/diag and crsdata(cvu dirs))\n";
  print "   -database     Purge Database logs (Default all else provide list)\n";
  print "   -dryrun       Estimate logs which will be cleared by purge command\n";
  print "-show            Print usage/variation details\n";
  print "   -older    	  Timeperiod for change in log volume\n";
  print "   -gi           Space utilization under GIBASE\n";
  print "   -database     Space utilization for Database logs (Default all else provide list)\n";
  print "\n";
  print "\n";
  print " -older <n><m|h|d>  Files from past 'n' [d]ays or 'n' [h]ours or 'n' [m]inutes \n";
  print "\n";
  print "\n";

  print "e.g:\n";
  print "   $cmd managelogs -purge -older 30d -dryrun \n";
  print "   $cmd managelogs -purge -older 30d \n";
  print "   $cmd managelogs -show usage \n\n"; 
  print "   $cmd run managelogs -purge -older 30d -dryrun \n";
  print "   $cmd run managelogs -purge -older 30d \n";
  print "   $cmd run managelogs -show usage \n\n";

  return 0;
}


#######################################################################################
### Validation specific functions
#######################################################################################

########
## NAME
##   tfactlmanagelogs_validate_since_switch
##
## DESCRIPTION
##   This function validates since switch. Allows values of type
##   5m, 2h, 10d etc...
##
## PARAMETERS
##   age - value of since switch passed as an argument
##
## RETURNS
##   1/0. 1 indicating since switch value is valid, 0 if invalid.
#########
sub tfactlmanagelogs_validate_since_switch{
  my $age = shift;
  my $is_valid = 1;

  if (!($age =~ /^(\d+)d{1}$/ || $age =~ /^(\d+)h{1}$/ || $age =~ /^(\d+)m{1}$/ )) {
    trace("ERROR","The time entered is invalid: $age\n");
    print "Some examples of valid time entries for -older flag : 5m, 2h, 10d\n";
    $is_valid = 0;
  }

  return $is_valid;
}

########
## NAME
##   tfactlmanagelogs_validate_db_list
##
## DESCRIPTION
##   This function validates database list
##
## PARAMETERS
##   database - comma seperated database names
##
## RETURNS
##   1/0. 1 indicating since database list is valid, 0 if invalid.
#########
sub tfactlmanagelogs_validate_db_list{
  my $database = shift;
  my $is_valid = 1;

  my @dbs;

  if( !defined($database) || (trim($database) eq "") || $database eq "all"){
  	my $ref = get_db_names();
    @dbs = @{$ref};
    my %db_hash = map { trim($_) => 1 } @dbs;

    foreach my $db (split /\,/ , $database) {
      if($db ne ""){
        if ( ! (exists $db_hash{trim($db)}) ){
          trace("WARNING","Database $db does not exist.\n");
          $is_valid = 0;
        }
      }
    }
  }

  return $is_valid;
}

#######################################################################################
### Purge specific functions
#######################################################################################

# ----------------------------------------------------------------------
# Sub common functions
# ----------------------------------------------------------------------
sub trace
{
  my @msg = @_;
  my ($sec, $min, $hour, $day, $month, $year) = (localtime) [0, 1, 2, 3, 4, 5];
  $month = $month + 1;
  $year  = $year + 1900;
  open (TRCFILE, ">>$tracefile")
    or die "Cant open trace file: '$tracefile'";
  printf TRCFILE  "%04d-%02d-%02d %02d:%02d:%02d: @msg\n", $year, $month, $day, $hour, $min, $sec;
  close (TRCFILE);

  my @msg_types = keys %message_type_colors;
  if(grep { $_ eq $msg[0]} @msg_types){
    printf "%04d-%02d-%02d %02d:%02d:%02d: ", $year, $month, $day, $hour, $min, $sec;
    if($IS_WINDOWS){
      printf "$msg[0] ";
    }else{
      print color $message_type_colors{$msg[0]};
      printf "$msg[0] ";
      print color 'reset';
    }
    printf "$msg[1]\n";
  }
  
}

sub trim_data
{
  my ($data) = @_;
  chomp($data);
  $data =~ s/(\s*)$//;
  $data =~ s/^(\s*)//;
  return $data;
}

sub system_cmd_capture {
  my ($cmd) = @_;
  my @out = `$cmd`;
  trace("OTHER", "---> Command : $cmd");
  trace("OTHER", "---> Output : ".join("", @out));
  my $rc = $? >> 8;
  trace("OTHER", "---> Return Code : $rc");
  return ($rc,@out);
}

sub system_cmd {
  my ($rc, @output) = system_cmd_capture(@_);
  return $rc;
}

sub readfile
{
  my ($in_file, $line, @a);
  $in_file = shift; 
  open(ARRAYFILE, "< $in_file") or die("Cannot open $in_file! \n");
  while ( defined ($line = <ARRAYFILE>)) {
      chomp ($line);
      push @a, $line; 
  };
  close(ARRAYFILE);
  return @a;
}

sub delOlderThen {
  my $folder = $_[0];
  my $days = $_[1];
  
  my @file_list;
  my @find_dirs       = ($folder);
  my $now             = time();
  my $seconds_per_day = 60*60*24;
  my $AGE             = $days*$seconds_per_day;
  find ( sub {
    my $file = $File::Find::name;
    if ( -f $file ) {
      push (@file_list, $file);
    }
  }, @find_dirs);

  for my $file (@file_list) {
    my @stats = stat($file);
    if ($now-$stats[9] > $AGE) {
      unlink $file;
    }
  }
}

# ----------------------------------------------------------------------
# Inventory Sub functions
# ----------------------------------------------------------------------

sub getDBHomeNamefromInventory
{
   my ($db_home) = @_;
   my $dbhomename;
   my $invloc=getCentralInvLocation();
   my @invfile=readfile("$invloc/ContentsXML/inventory.xml");

   my @invline = grep (/LOC=\"$db_home\"/,@invfile);
   if ( defined($invline[0]) ) {
      $dbhomename = $invline[0];
      $dbhomename =~ s/^<.*(HOME NAME=\")(.*)(\".*LOC).*>$/$2/;      
   } 
   return $dbhomename;
}

sub get_db_home
{
  my ($db_name) = @_;
  my $db_home_path = "";

  $db_name = lc($db_name);

  # Check if DB_NAME= entry exists in tfa_setup.txt
  my $tfa_setup = catfile($tfa_home,"tfa_setup.txt");
  open my $fh, '<',  $tfa_setup or die "Could not open $tfa_setup: $!";
  
  my @lines = sort grep /DB_NAME=$db_name/, <$fh>;
  foreach my $line(@lines){
    my @out = split(/\|/, $line);
    $db_home_path = trim(@out[2]);
  }

  close($fh);
  if($db_home_path ne ""){
  	return $db_home_path;
  }

  # Check if crs is up
  my $is_crs_up;

  if($crshome eq ""){
    $is_crs_up = 0;
  }else{
    $is_crs_up = osutils_isCRSRunning($crshome);
  }
  
  if($is_crs_up){
    my $db_resource_name="ora.".$db_name.".db";
    my $crsctl_cmd = catfile($crshome,"bin", "crsctl");
    my $crsctl_get_res_attr = $crsctl_cmd." "."stat resource $db_resource_name -p";
    open (my $RES, "$crsctl_get_res_attr |");
    my $sstring = "ORACLE_HOME=";
    my @db_homes = grep /^$sstring/, <$RES>;
    close $RES;
    if(!(scalar(@db_homes)==0)){
    	my @db_home_string = split("=",$db_homes[0]);
    	$db_home_path = trim($db_home_string[1]);
    	if($db_home_path ne ""){
    		return $db_home_path;
    	}
    }
  }

  # Check all the home paths for diag/rdbms/<dbname> folder existence
  my @dbhome_paths = ();
  open $fh, '<',  $tfa_setup or die "Could not open $tfa_setup: $!";
  
  my @lines = sort grep /RDBMS_ORACLE_HOME=/, <$fh>;
  foreach my $line(@lines){
    my @out_home_line = split(/\|/, $line);
    my @out_home_path = split(/=/, @out_home_line[0]);
    push (@dbhome_paths, trim(@out_home_path[1]));
  }
  close($fh);

  my $orabase_dir;
  foreach my $home (@dbhome_paths){
  	$orabase_dir = get_base_dir($home);
  	if(-d catdir($orabase_dir,"diag","rdbms",$db_name)){
  		return $home;
  	}
  }
  
  # Note : need to handle the case where adr is moved out of orabase

  return $db_home_path;
}

sub get_db_names
{
  my @dbs = ();

  my %db_hash = ();

  # Checking tfa_setup.txt
  my $tfa_setup = catfile($tfa_home,"tfa_setup.txt");
  open my $fh, '<',  $tfa_setup or die "Could not open $tfa_setup: $!";

  my @lines = sort grep /$hostname\%RDBMS\|/, <$fh>;
  foreach my $line(@lines){
    my @out = split(/\|/, $line);
    if( ! (exists($db_hash{lc(@out[1])})) ){
  	  $db_hash{lc(@out[1])}=1;
    }
  }
  close($fh);

  # Add database entries to array if not found in tfa_setup.txt through srvctl command

  my $is_crs_up;

  if($crshome eq ""){
    $is_crs_up = 0;
  }else{
    $is_crs_up = osutils_isCRSRunning($crshome);
  }

  if($is_crs_up){
    my $srvctl_cmd = catfile($crshome,"bin", "srvctl");
    my $srvctl_list_dbs = $srvctl_cmd." "."config database";
    open (my $RES, "$srvctl_list_dbs |");
    my @db_ress = <$RES>;
    close $RES;
    foreach my $resname (@db_ress)
    {
      chomp($resname);
      if( ! (exists($db_hash{lc($resname)})) ){
  	  	$db_hash{lc($resname)}=1;
      }
    }
  }

  @dbs = keys %db_hash;

  return \@dbs;
}

sub getCentralInvLocation
{
  my $orainstloc;
  my (@orainstfile,@tmp,@invline,$inv_loc);
  @orainstfile=readfile($orainstloc);
  @tmp = grep /inventory_loc/, @orainstfile;
  if ( defined($tmp[0]) ) {
      @invline = split /=/, $tmp[0];
      $inv_loc = $invline[1];
      chomp $inv_loc;
  } else {die ("Cannot retrieve inventory location from $orainstloc! \n");} 
  return $inv_loc;
}

# ----------------------------------------------------------------------
# Sub functions
# ----------------------------------------------------------------------
sub checkroot {
  if ( "root" ne tfactlshare_get_user()) {
    print("This should be run as root user. Exiting...\n");
    exit(1);
  }
}

sub setenv {
  my $orahome = $_[0];

  my $ADR_BASE = tfactlshare_get_adrbase($orahome);

  if($ADR_BASE ne "invalid"){
    $ENV{ADR_BASE}=$ADR_BASE;
  }
  $ENV{ORACLE_HOME}=$orahome;
}

sub cleanGI {
  my $AGE = shift;

  my $tot_files_deleted = 0;
  my $tot_space_freed = 0;

  my $files_deleted = 0;
  my $space_freed = 0;

  # Collect filesystem level data
  my ($file_sys_ref_start,$file_sys_ref_end);

  if($crshome ne ""){
    my @home = get_diagnostic_destinations($crshome);
    if (scalar(@home)>0){
    	if(!$IS_DRY_RUN){
    		$file_sys_ref_start = get_df_record_for_directory($crshome);
    		trace("INFO", "Cleaning Grid Infrastructure destinations\n");
    	}

	  	@home = grep { ((index($_, $rdbms_path_pattern) == -1) || /$mgmt_db_diag_path/) } @home;
      
	    while (@home) {
	      my $home_line = trim_data(shift(@home));
	      trace("OTHER", "Cleaning destination : $home_line");  

	      my ($files_to_clean_ref_start,$files_count_start,$space_count_start) = collect_files_to_cleanup($AGE,$home_line,$crshome);

	      if($IS_DRY_RUN){

	      	$tot_files_deleted = $tot_files_deleted + $files_count_start;
	    	  $tot_space_freed = $tot_space_freed + $space_count_start;

	      	trace("INFO", "Estimating purge for diagnostic destination \"$home_line\" for files ~ $files_count_start files deleted , ".space_in_human_readable_units($space_count_start)." freed ]");
	      }else{
			  
			  execute_purge($crshome,$AGE,$home_line);

		      my ($files_to_clean_ref_end,$files_count_end,$space_count_end) = collect_files_to_cleanup($AGE,$home_line,$crshome);
	    	  $files_deleted = $files_count_start-$files_count_end;
	    	  $space_freed = $space_count_start-$space_count_end;

	    	  my @files_to_clean_ref_end_keys = keys %{ $files_to_clean_ref_end };
	    	  my $files_to_clean_ref_end_size = @files_to_clean_ref_end_keys;

	    	  if($files_to_clean_ref_end_size>0){
	    	  	foreach my $key ( keys %{ $files_to_clean_ref_start } )
			    {
				  if(exists($files_to_clean_ref_end->{$key})){
				  	trace("OTHER", "Failed to remove : $key");
				  }else{
				  	trace("OTHER", "Removed : $key");
				  }
			    }
	    	  }else{
	    	  	foreach my $key ( keys %{ $files_to_clean_ref_start } )
			    {
				  trace("OTHER", "Removed : $key");
			    }
	    	  }

	    	  $tot_files_deleted = $tot_files_deleted + $files_deleted;
	    	  $tot_space_freed = $tot_space_freed + $space_freed;

		      trace("INFO", "Purging diagnostic destination \"$home_line\" for files - $files_deleted files deleted , ".space_in_human_readable_units($space_freed)." freed");
	      }

	    }

	    if($IS_DRY_RUN){
	    	trace("MESSAGE", "Estimation for Grid Infrastructure : $crshome [ Files to delete : ~ $tot_files_deleted files | Space to be freed : ~ ".space_in_human_readable_units($tot_space_freed)." ]\n\n");
    	}else{
    		trace("MESSAGE", "Grid Infrastructure : $crshome [ Files deleted : $tot_files_deleted files | Space Freed : ".space_in_human_readable_units($tot_space_freed)." ]\n\n");

    		$file_sys_ref_end = get_df_record_for_directory($crshome);
    		print_file_system_variation($crshome,$file_sys_ref_start,$file_sys_ref_end);
    	}

      $tot_files_deleted = 0;
      $tot_space_freed = 0;

    }

  }else{
    trace("INFO", "Grid installation not present on $hostname. ");
  }

}

sub cleanOH {    
  my $AGE = shift;
  my $database = shift;

  my @dbs;
  my $oraclehome;

  my $tot_files_deleted = 0;
  my $tot_space_freed = 0;

  my $files_deleted = 0;
  my $space_freed = 0;

  # Collect filesystem level data
  my ($file_sys_ref_start,$file_sys_ref_end);

  if( !defined($database) || (trim($database) eq "") || $database eq "all"){
    my $ref = get_db_names();
    @dbs = @{$ref};
  }else{
    @dbs = split(',', $database);
  }

  for my $db_name (@dbs){
    $oraclehome = get_db_home($db_name);
    if($oraclehome eq ""){
      trace("WARNING", "Database : $db_name not found on host : $hostname");
      next;
    }
	$oraclehome = trim_data($oraclehome);

      my @home = get_diagnostic_destinations($oraclehome);
      
      if (scalar(@home)>0){

	  	if(!$IS_DRY_RUN){
	  		trace("INFO", "Cleaning Database Home destinations\n");
	  		$file_sys_ref_start = get_df_record_for_directory($oraclehome);
	  	}

	  	$db_name = lc($db_name);
	  	@home = grep { /$db_name/ } @home;
	  	while (@home) {
	      my $home_line = trim_data(shift(@home));
	      trace("OTHER", "Cleaning destination : $home_line");  

	      my ($files_to_clean_ref_start,$files_count_start,$space_count_start) = collect_files_to_cleanup($AGE,$home_line,$oraclehome);

	      if($IS_DRY_RUN){

	      	$tot_files_deleted = $tot_files_deleted + $files_count_start;
	    	$tot_space_freed = $tot_space_freed + $space_count_start;

	      	trace("INFO", "Estimating purge for diagnostic destination \"$home_line\" for files ~ $files_count_start files deleted , ".space_in_human_readable_units($space_count_start)." freed ]");
	      }else{

			  execute_purge($oraclehome,$AGE,$home_line);
			  
		      my ($files_to_clean_ref_end,$files_count_end,$space_count_end) = collect_files_to_cleanup($AGE,$home_line,$oraclehome);
	    	  $files_deleted = $files_count_start-$files_count_end;
	    	  $space_freed = $space_count_start-$space_count_end;

	    	  my @files_to_clean_ref_end_keys = keys %{ $files_to_clean_ref_end };
	    	  my $files_to_clean_ref_end_size = @files_to_clean_ref_end_keys;

	    	  if($files_to_clean_ref_end_size>0){
	    	  	foreach my $key ( keys %{ $files_to_clean_ref_start } )
			    {
				  if(exists($files_to_clean_ref_end->{$key})){
				  	trace("OTHER", "Failed to remove : $key");
				  }else{
				  	trace("OTHER", "Removed : $key");
				  }
			    }
	    	  }else{
	    	  	foreach my $key ( keys %{ $files_to_clean_ref_start } )
			    {
				  trace("OTHER", "Removed : $key");
			    }
	    	  }

	    	  $tot_files_deleted = $tot_files_deleted + $files_deleted;
	    	  $tot_space_freed = $tot_space_freed + $space_freed;

		      trace("INFO", "Purging diagnostic destination \"$home_line\" for files - $files_deleted files deleted , ".space_in_human_readable_units($space_freed)." freed");
	      }
	    }

	    if($IS_DRY_RUN){
	    	trace("MESSAGE", "Estimation for Database Home : $oraclehome [ Files to delete : ~ $tot_files_deleted files | Space to be freed : ~ ".space_in_human_readable_units($tot_space_freed)." ]\n\n");
    	}else{
    		trace("MESSAGE", "Database Home : $oraclehome [ Files deleted : $tot_files_deleted files | Space Freed : ".space_in_human_readable_units($tot_space_freed)." ]\n\n");
    		
    		$file_sys_ref_end = get_df_record_for_directory($oraclehome);
			  print_file_system_variation($oraclehome,$file_sys_ref_start,$file_sys_ref_end);
    	}

      $tot_files_deleted = 0;
      $tot_space_freed = 0;

	  }
  }

}

sub cleanTFA {
  my $days = $_[0];
  trace("INFO", "Purging TFA archives older then $days days");  
  $days =  $days . "d";

  # TODO - Always check for CRSHOME

  my ($rc,@home) = system_cmd_capture("$crshome/bin/tfactl purge -older $days");
  trace("WARNING", "Not able to cleanup TFA repository")  if ($rc);
}

sub cleanOSW {
  my $days = $_[0];  
  trace("INFO", "Purging OSW archives older then $days days");  
  my $oswArchive = "/opt/oracle/oak/oswbb/archive";
  if (! -d $oswArchive) {
    trace("WARNING", "Path $oswArchive does not exist, OSW archive cleanup skipped...");
  }
  else {
    delOlderThen($oswArchive,$days);
  }
}

sub cleanOAKLogs {
  my $days = $_[0];  
  trace("INFO", "Purging OAK logs older then $days days");    
  my $oakLogs = "/opt/oracle/oak/log";  
  if (! -d $oakLogs) {
    trace("WARNING", "Path $oakLogs does not exist, OAK logs cleanup skipped...");
  }
  else {
    delOlderThen($oakLogs,$days);  
  }
}

sub showGIusage{
  if($crshome ne ""){
    my @home = get_diagnostic_destinations($crshome);
    
    if (scalar(@home)>0){

    	my $ADR_BASE = tfactlshare_get_adrbase($crshome);
    	my $total_size = 0;
    	my $current_dir;
		  my $current_dir_size = 0;

    	if($ADR_BASE ne "invalid"){
    		my $table;
    		my $outfile;
    		
			if($SAVE_USAGE){
				my $outfile = catfile ( $usage_snapshot_dir, "gi_usage_".strftime("%d_%b_%y_%H_%M_%S_%Z", localtime()).".txt");
				open (OUT, '>', $outfile) or die "Can't open file $outfile: $!\n";
			}else{
				$table = Text::ASCIITable->new();
				$table->setCols('Location','Size');
				$table->setOptions({"outputWidth" => $tputcols, "headingText" => "Grid Infrastructure Usage"});
			}
      
			@home = grep { ((index($_, $rdbms_path_pattern) == -1) || /$mgmt_db_diag_path/) } @home;
		    while (@home) {
		      my $diagnostic_dest = trim_data(shift(@home));
			  
				for my $dir (@dir_to_clean){
					$current_dir = catdir($ADR_BASE,$diagnostic_dest,$dir);
					if(-d $current_dir){
						$current_dir_size = osutils_du($current_dir,1);
						if($SAVE_USAGE){ 
							print OUT "$current_dir,$current_dir_size\n";
						}else{
							$table->addRow("$current_dir",space_in_human_readable_units($current_dir_size));
					    	$total_size = $total_size + int($current_dir_size);
						}
					}
				}

		    }

		    if($SAVE_USAGE){
		    	close(OUT);
	    	}else{
	    		if($total_size>0){
			    	$table->addRowLine();
			    	$table->addRow('Total',space_in_human_readable_units($total_size));
			    }
	  			print "\n$table";
	    	}

    	}
    }

  }else{
    trace("INFO", "Grid installation not present on $hostname. ");
  }
}

sub showOHusage{
  my $database = shift;

  my @dbs;
  my $oraclehome;

  my $total_size;
  my $current_dir;
  my $current_dir_size;

  if( !defined($database) || (trim($database) eq "") || $database eq "all"){
    my $ref = get_db_names();
    @dbs = @{$ref};
  }else{
    @dbs = split(',', $database);
  }

  my $table;
  my $outfile;

  if($SAVE_USAGE){
  	$outfile = catfile ( $usage_snapshot_dir, "oh_usage_".strftime("%d_%b_%y_%H_%M_%S_%Z", localtime()).".txt");
  	open (OUT, '>', $outfile) or die "Can't open file $outfile: $!\n";
  }else{
	$table = Text::ASCIITable->new();
	$table->setCols('Location','Size');
	$table->setOptions({"outputWidth" => $tputcols, "headingText" => "Database Homes Usage"});
  }

  for my $db_name (@dbs){
    $oraclehome = get_db_home($db_name);
    if($oraclehome eq ""){
      trace("WARNING", "Database : $db_name not found on host : $hostname");
      next;
    }
    $oraclehome = trim_data($oraclehome);
      my @home = get_diagnostic_destinations($oraclehome);
      
      if (scalar(@home)>0){
	  	
	  	my $ADR_BASE = tfactlshare_get_adrbase($oraclehome);

    	if($ADR_BASE ne "invalid"){
			
			$db_name = lc($db_name);
	  		@home = grep { /$db_name/ } @home;
		    while (@home) {
		      my $diagnostic_dest = trim_data(shift(@home));
			  
				for my $dir (@dir_to_clean){
					$current_dir = catdir($ADR_BASE,$diagnostic_dest,$dir);
					if(-d $current_dir){
						$current_dir_size = osutils_du($current_dir,1);
						if($SAVE_USAGE){
							print OUT "$current_dir,$current_dir_size\n";
						}else{
							$table->addRow("$current_dir",space_in_human_readable_units($current_dir_size));
					    	$total_size = $total_size + int($current_dir_size);
						}
					}
				}

		    }

    	}
	  }

  }

  if($SAVE_USAGE){
  	close(OUT);
  }else{
    if($total_size>0){
      $table->addRowLine();
      $table->addRow('Total',space_in_human_readable_units($total_size));
    }
    print "\n$table";
  }

}


sub showGIvariation{
	my $age = shift;

	# my %start_usage = ();
	my %end_usage = ();

	if($crshome ne ""){
	    my @home = get_diagnostic_destinations($crshome);
	    
	    if (scalar(@home)>0){

	    	my $ADR_BASE = tfactlshare_get_adrbase($crshome);
	    	my $current_dir;
			my $current_dir_size = 0;

	    	if($ADR_BASE ne "invalid"){
	    		@home = grep { ((index($_, $rdbms_path_pattern) == -1) || /$mgmt_db_diag_path/) } @home;
			    while (@home) {
			      my $diagnostic_dest = trim_data(shift(@home));
				  
					for my $dir (@dir_to_clean){
						$current_dir = catdir($ADR_BASE,$diagnostic_dest,$dir);
						if(-d $current_dir){
							$current_dir_size = osutils_du($current_dir,1);
							$end_usage{$current_dir}=$current_dir_size;
						}
					}

			    }

	    	}

	    	my ($start_usage_ref,$usage_file) = get_usage_file($age,"GI","older");
        if( -f $usage_file ){
          my $current_time = time();
          my $filemodtime = (stat($usage_file))[9];
          my $snapshot_age = difference( $current_time - $filemodtime );
          my $usage_file_date =  POSIX::strftime( 
               "%d-%b-%Y %H:%M:%S %Z", 
               localtime( 
                   ( stat $usage_file )[9]
                   )
               );
          trace("INFO", "Snapshot considered for size comparision was created at $usage_file_date [$snapshot_age].");
        }
	    	
	    	print_usage_variation($start_usage_ref,\%end_usage,"Grid Infrastructure Variation");
	    }
  }else{
    	trace("INFO", "Grid installation not present on $hostname. ");
  }
}

sub showOHvariation{
  my $age = shift;
  my $database = shift;

  # my %start_usage = ();
  my %end_usage = ();

  my @dbs;
  my $oraclehome;

  if( !defined($database) || (trim($database) eq "") || $database eq "all"){
    my $ref = get_db_names();
    @dbs = @{$ref};
  }else{
    @dbs = split(',', $database);
  }

  for my $db_name (@dbs){
    $oraclehome = get_db_home($db_name);
    if($oraclehome eq ""){
      trace("WARNING", "Database : $db_name not found on host : $hostname");
      next;
    }
    $oraclehome = trim_data($oraclehome);
      my @home = get_diagnostic_destinations($oraclehome);
      
      if (scalar(@home)>0){
	  	
  	  	my $ADR_BASE = tfactlshare_get_adrbase($oraclehome);
      	my $total_size;
      	my $current_dir;
  		  my $current_dir_size;

      	if($ADR_BASE ne "invalid"){
      		$db_name = lc($db_name);
  	  		@home = grep { /$db_name/ } @home;
  		    while (@home) {
  		      my $diagnostic_dest = trim_data(shift(@home));
  			  
  				for my $dir (@dir_to_clean){
  					$current_dir = catdir($ADR_BASE,$diagnostic_dest,$dir);
  					if(-d $current_dir){
  						$current_dir_size = osutils_du($current_dir,1);
  						$end_usage{$current_dir}=$current_dir_size;
  					}
  				}

  		    }
      	}

  	  }

  }

  my ($start_usage_ref,$usage_file) = get_usage_file($age,"OH","older");
  if( -f $usage_file ){
    my $current_time = time();
    my $filemodtime = (stat($usage_file))[9];
    my $snapshot_age = difference( $current_time - $filemodtime );
    my $usage_file_date =  POSIX::strftime( 
         "%d-%b-%Y %H:%M:%S %Z", 
         localtime( 
             ( stat $usage_file )[9]
             )
         );
    trace("INFO", "Snapshot considered for size comparision was created at $usage_file_date [$snapshot_age].");
  }
    	
  print_usage_variation($start_usage_ref,\%end_usage,"Database Homes Variation");
}


sub get_usage_file{
	my $age = shift;
	my $type = shift;
	my $limit = shift;

	my $usage_file;
	my $usage_file_age_in_minutes;
	my %usage_hash = ();
	my $file_name_pattern = "";

	if($type eq "GI"){
		$file_name_pattern = "gi_usage_";
	}else{
		$file_name_pattern = "oh_usage_";
	}

	if(-d $usage_snapshot_dir){
		# Add files satisfying the age condition to the files_to_clean hash
		my @find_dirs = ($usage_snapshot_dir);
		my @files;
		find ( sub {
	      my $file = $File::Find::name;
	      if ( -f $file ) {
	      	my($filename, $dirs, $suffix) = fileparse($file);
	      	if (index($filename, $file_name_pattern) != -1) {
			    push (@files, $file);
			} 
	      }
	    }, @find_dirs);

		my $current_age;
		my $current_age_in_minutes;
    my $filemodtime;
    my $file_age_in_minutes;
    my %file_age_hash = ();
    my $current_time = time();

    foreach my $current_file (@files) {
      if(-f $current_file){
          $filemodtime = (stat($current_file))[9];
          $current_age_in_minutes = ($current_time - $filemodtime)/(60);
          $file_age_hash{$current_file}=$current_age_in_minutes;
      }
    }

    # Sorted decending by value
    my @file_age_sorted = sort { $file_age_hash{$b} <=> $file_age_hash{$a} } keys %file_age_hash;

		foreach my $current_file (@file_age_sorted) {
		  	if($limit eq "younger"){
		  		# Find file which is younger than the age provided but older than everyone else
		  		if(!(defined($usage_file))){
				  	$usage_file = $current_file;
				  	$usage_file_age_in_minutes = $file_age_hash{$current_file};
		  		}else{
		  			if(($file_age_hash{$current_file}<=$age) && ($file_age_hash{$current_file}>$usage_file_age_in_minutes)){
				  		$usage_file = $current_file;
				  		$usage_file_age_in_minutes = $file_age_hash{$current_file};
				  	}
		  		}

	  		}else{
	  			# Find file which is older than the age provided but younger than everyone else
	  			if(!(defined($usage_file))){
				  	$usage_file = $current_file;
				  	$usage_file_age_in_minutes = $file_age_hash{$current_file};
		  		}else{
		  			if(($file_age_hash{$current_file}>=$age) && ($file_age_hash{$current_file}<$usage_file_age_in_minutes)){
				  		$usage_file = $current_file;
				  		$usage_file_age_in_minutes = $file_age_hash{$current_file};
				  	}
		  		}
	  		}
		}

		if(defined($usage_file) && (-f $usage_file)){
			# Read the file and fill the hash
			open my $fh, '<', $usage_file or die "Unable to open file:$!\n";
			%usage_hash = map { split /,/; } <$fh>;
			close $fh;
		}

	}

	return (\%usage_hash,$usage_file);
}

sub print_usage_variation{
	my $start_usage_ref = shift;
	my $end_usage_ref = shift;
	my $table_header = shift;

	my $dir;
	my $old_value;
	my $new_value;

	my $table = Text::ASCIITable->new();
	$table->setCols('Directory','Old Size','New Size');
	$table->setOptions({"outputWidth" => $tputcols, "headingText" => "$table_header"});

	foreach my $key ( keys %{ $end_usage_ref } )
	{
		$dir = $key;
		if(exists($start_usage_ref->{$key})){
			$old_value = space_in_human_readable_units(${$start_usage_ref}{$key});
			$new_value = space_in_human_readable_units(${$end_usage_ref}{$key});
		}else{
			$old_value = "-";
			$new_value = space_in_human_readable_units(${$end_usage_ref}{$key});
		}
		$table->addRow("$dir","$old_value","$new_value");
		$table->addRowLine();
	}

	foreach my $key ( keys %{ $start_usage_ref } ){
		if(!(exists($end_usage_ref->{$key}))){
			$dir = $key;
			$old_value = space_in_human_readable_units(${$start_usage_ref}{$key});
			$new_value = "-";
			$table->addRow("$dir","$old_value","$new_value");
			$table->addRowLine();
		}
	}

	print "\n$table";
}

sub collect_files_to_cleanup{
	my $AGE = shift;
	my $diagnostic_dest = shift;
	my $oraclehome = shift;

	my %files_to_clean = ();
	my $ADR_BASE;
	my $files_count = 0;
	my $space_count = 0;

	my $current_file_size;

	$ADR_BASE = tfactlshare_get_adrbase($oraclehome);
	if($ADR_BASE ne "invalid"){
		for my $clean_dir (@dir_to_clean){
			my $current_dir = catdir($ADR_BASE,$diagnostic_dest,$clean_dir);
			if(-d $current_dir){
				# Add files satisfying the age condition to the files_to_clean hash
				my @find_dirs = ($current_dir);
				my @files;
				find ( sub {
			      my $file = $File::Find::name;
			      if ( -f $file ) {
			        push (@files, $file);
			      }
			    }, @find_dirs);

        my $current_time = time();
        my $filemodtime;
        my $file_age_in_minutes;

				foreach my $current_file (@files) {
					if(-f $current_file){
              $filemodtime = (stat($current_file))[9];
              $file_age_in_minutes = ($current_time - $filemodtime)/(60);
					  	if($file_age_in_minutes>$AGE){
                $current_file_size = (stat $current_file)[7];
					  		$files_to_clean{$current_file} = $current_file_size;
					  		$files_count = $files_count + 1;
					  		$space_count = $space_count + $current_file_size;
					  	}
					}
				}

			}
		}
	}

	return (\%files_to_clean,$files_count,$space_count);
}


sub space_in_human_readable_units{
	my $size = shift;

	if ($size > 1099511627776)  #   TB: 1024 GB
	{
	    return sprintf("%.2f TB", $size / 1099511627776);
	}
	elsif ($size > 1073741824)  #   GB: 1024 MB
	{
	    return sprintf("%.2f GB", $size / 1073741824);
	}
	elsif ($size > 1048576)     #   MB: 1024 KB
	{
	    return sprintf("%.2f MB", $size / 1048576);
	}
	elsif ($size > 1024)        #   KB: 1024 B
	{
	    return sprintf("%.2f KB", $size / 1024);
	}
	else                        #   bytes
	{
	    return "$size byte" . ($size == 1 ? "" : "s");
	}
}

sub get_diagnostic_destinations{
	my $home = shift;
	my $rc;
	my @home = ();

	setenv($home);
    my $cmd;
    if($IS_WINDOWS){
      $cmd = catfile($home,"bin","adrci.exe")." exec=\"show homes\" |findstr /v :";
    }else{
      $cmd = catfile($home,"bin","adrci")." exec='show homes' |grep -v :";
    }
    my $ouser = tfactlshare_get_dir_file_owner(catfile($home,"bin","adrci"));
    if (lc($current_user) eq "root") {
      if($IS_WINDOWS){
        ($rc,@home) = system_cmd_capture("$cmd");
      }else{
        ($rc,@home) = system_cmd_capture("su $ouser -c \"$cmd\"");
      }
    	if ($rc){
	    	trace("WARNING", "Not able to get the ADR homes for $home");
	    }
  	}elsif(lc($current_user) eq lc("$ouser")){
  		($rc,@home) = system_cmd_capture("$cmd");
      	if ($rc){
  	    	trace("WARNING", "Not able to get the ADR homes for $home");
  	    }
  	}else{
  		trace("OTHER", "User \'$current_user\' does not have access to \'$home\'.");
  	}

    return @home;
}

sub execute_purge{
	my $home = shift;
	my $AGE = shift;
	my $diagnostic_dest = shift;
	my $rc;

	setenv($home);
  my $cmd;
  if($IS_WINDOWS){
    $diagnostic_dest =~ s{\\}{\\\\}g;
    $cmd = catfile($home,"bin","adrci.exe")." exec=\"set homepath $diagnostic_dest;purge -age $AGE\"";  
  }else{
    $cmd = catfile($home,"bin","adrci")." exec=\'set homepath $diagnostic_dest;purge -age $AGE\'";  
  }
	
	my $ouser = tfactlshare_get_dir_file_owner(catfile($home,"bin","adrci"));
	if (lc($current_user) eq "root") {
      if($IS_WINDOWS){
        $rc = system_cmd("$cmd");
      }else{
        $rc = system_cmd("su $ouser -c \"$cmd\"");
      }
    	if ($rc){
			trace("WARNING", "Unable to purge");
		}else{
			trace("OTHER", "Purged");
		}
	}elsif(lc($current_user) eq lc("$ouser")){
		$rc = system_cmd("$cmd");
    	if ($rc){
			trace("WARNING", "Unable to purge");
		}else{
			trace("OTHER", "Purged");
		}
	}else{
		trace("OTHER", "User \'$current_user\' does not have access to \'$home\'.");
	}

	# This block can be used when we want low level bifurcation on the type of log files we want to remove.
	# for my $type (@data_types){
	# 	$rc = system_cmd("$homesetenv;$crshome/bin/adrci exec=\"set homepath $diagnostic_dest;purge -age $AGE -type $type\"");
	# 	if ($rc){
	# 		trace("WARNING", "Not able to purge $type");
	# 	}else{
	# 		trace("OTHER", "Purged $type");
	# 	}
	# }

}

sub get_df_record_for_directory{
	my $dir = shift;
	my @df = ();
  if($IS_WINDOWS){
    my $marker = substr $dir, 0, index($dir, ":");
    $marker = $marker.":";
    @df = `wmic logicaldisk get Caption, FileSystem , FreeSpace, Size, SystemName, VolumeName | findstr $marker`;
  }else{
    @df = `df -k $dir`;
    shift @df;  # get rid of the header
  }

	my %devices;
	for my $line (@df) {
	    @devices{@df_headers} = split /\s+/, $line;
	}

	return \%devices;
}

sub print_file_system_variation{
	my $base_path = shift;
	my $file_sys_ref_start = shift;
	my $file_sys_ref_end = shift;

	my $table = Text::ASCIITable->new();
  if($IS_WINDOWS){
    $table->setCols('State','Caption', 'FileSystem' , 'FreeSpace', 'Size', 'SystemName', 'VolumeName');
    $table->setOptions({"outputWidth" => $tputcols, "headingText" => "File System Variation : $base_path"});
    # Old State
    $table->addRow("Before","${$file_sys_ref_start}{Caption}","${$file_sys_ref_start}{FileSystem}","${$file_sys_ref_start}{FreeSpace}","${$file_sys_ref_start}{Size}","${$file_sys_ref_start}{SystemName}","${$file_sys_ref_start}{VolumeName}");
    # Old State
    $table->addRow("After","${$file_sys_ref_end}{Caption}","${$file_sys_ref_end}{FileSystem}","${$file_sys_ref_end}{FreeSpace}","${$file_sys_ref_end}{Size}","${$file_sys_ref_end}{SystemName}","${$file_sys_ref_end}{VolumeName}");
  }else{
    $table->setCols('State', 'Name' , 'Size', 'Used', 'Free' ,'Capacity' ,'Mount');
    $table->setOptions({"outputWidth" => $tputcols, "headingText" => "File System Variation : $base_path"});
    # Old State
    $table->addRow("Before","${$file_sys_ref_start}{name}","${$file_sys_ref_start}{size}","${$file_sys_ref_start}{used}","${$file_sys_ref_start}{free}","${$file_sys_ref_start}{capacity}","${$file_sys_ref_start}{mount}");
    # Old State
    $table->addRow("After","${$file_sys_ref_end}{name}","${$file_sys_ref_end}{size}","${$file_sys_ref_end}{used}","${$file_sys_ref_end}{free}","${$file_sys_ref_end}{capacity}","${$file_sys_ref_end}{mount}");    
  }
	
	print "\n$table\n";
}

sub truncate_float{
  my $value = shift;
  my $places = shift;
  my $factor = 10**$places;
  return int($value * $factor) / $factor;
}

sub difference
{
    my( $seconds ) =  (@_ );

    if ( $seconds < 60 )
    {
        # less than a minute
        return( "Just now" );
    }
    if ( $seconds <= ( 60 * 60 ) )
    {
        # less than an hour
        return( int($seconds/ 60 ) . " minutes ago" );
    }
    if ( $seconds <= ( 60 * 60 * 24 ) )
    {
        # less than a day
        return( int( $seconds/(60 * 60) ) . " hours ago" );
    }
    if ( $seconds <= ( 60 * 60 * 24 * 7 ) )
    {
        # less than a week
        return( int( $seconds/(60*60*24)) . " days ago" );
    }

    # fall-back weeks ago
    return( int( $seconds/(60*60*24*7)) . " weeks ago" );

}

# sub checkExtra {
#   my $days; 
#   my $char; 
#   my @elements = split(",",$extra);
#   while (@elements) {
#     my $entry = trim_data(shift(@elements));
#     my @longpath = split(":",$entry);
#     if (!defined $longpath[0] or $longpath[0] eq "") {
#       trace("ERROR", "Empty path provided, exiting... ");
#       exit(1);
#     }
#     if (! -d $longpath[0]) {
#       trace("ERROR", "Path $longpath[0] does not exist, exiting... ");
#       exit(1);
#     }
#     if ( !defined($longpath[1]) ){ 
#       $longpath[1] = $def_ext; 
#     }
#     elsif (!($longpath[1] =~ /^[1-9][0-9]*$/)) {
#       trace("ERROR", "Days=$longpath[1] in extra option not valid, exiting... "); 
#       exit(1);
#     }
#     push @aopath, [$longpath[0],$longpath[1]];
#   }
# }

# sub cleanExtra {
#   for my $i (0..$#aopath) {     
#     trace("INFO", "Purging files older then $aopath[$i][1] days on user specified folder '$aopath[$i][0]'");
# 	return (\%files_to_clean,$files_count,$space_count);
# }
#     delOlderThen($aopath[$i][0],$aopath[$i][1]); 
#   }
# }

