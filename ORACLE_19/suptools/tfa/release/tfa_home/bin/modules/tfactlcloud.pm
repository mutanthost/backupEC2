# 
# $Header: tfa/src/v2/tfa_home/bin/modules/tfactlcloud.pm /main/3 2018/08/09 22:22:31 recornej Exp $
#
# tfactlcloud.pm
# 
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlcloud.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      Module to handle all the cloud related requests and calls.
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    08/06/18 - Change SUCCESS and FAILED values.
#    manuegar    07/13/18 - manuegar_multibug_01.
#    llakkana    05/18/18 - Module to handle cloud related requests/calls
#    llakkana    05/18/18 - Creation
# 

package tfactlcloud;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(tfactlcloud_init);

use strict;
use English;
use File::Basename;
use File::Spec::Functions;
use Getopt::Long;
use Data::Dumper;
use POSIX;
use POSIX qw(:termios_h);

use constant ERROR    => "-1";
use constant FAILED   =>  1;
use constant SUCCESS  =>  0;
use constant TRUE     =>  "1";
use constant FALSE    =>  "0";
use constant CONNFAIL =>  "99";
use constant DBG_NOTE => "1";  #Notes to the user
use constant DBG_WHAT => "2";  #Explain what you do
use constant DBG_VERB => "4";  #Be verbose
use constant DBG_HOST => "8";  #Print command executed on local host

use tfactlglobal;
use tfactlshare;
use dateutils;
use tfactlparser;
use cmdlocation;

#################### tfactlcloud Global Constants ####################
my (%tfactlcloud_cmds) = (exacd      => {},
                         );

#################### tfactlcloud Global Variables ####################

my $arg_sep = "_TFAARGSEP_";
my $CLOUDCHECK_EXACD;
my $CLOUDCHECK_LOCAL = 0;

sub is_tfactl
{
  return 1;
}


########
# NAME
#   tfactlcloud_init
#
# DESCRIPTION
#   This function initializes the tfactlcloud module.  For now it 
#   simply registers its callbacks with the tfactlglobal module.
#
# PARAMETERS
#   None
#
# RETURNS
#   Null
#
# NOTES
#   Only tfactl_main() calls this routine.
########
sub init
{
  #All of the arrays defined in the tfactlglobal module must be 
  #initialized here.  Otherwise, an internal error will result.
  push (@tfactlglobal_command_callbacks, \&tfactlcloud_process_cmd);
  push (@tfactlglobal_help_callbacks, \&tfactlcloud_process_help);
  push (@tfactlglobal_command_list_callbacks, \&tfactlcloud_get_tfactl_cmds);
  push (@tfactlglobal_is_command_callbacks, \&tfactlcloud_is_cmd);
  push (@tfactlglobal_is_wildcard_callbacks, \&tfactlcloud_is_wildcard_cmd);
  push (@tfactlglobal_syntax_error_callbacks, \&tfactlcloud_syntax_error);
  push (@tfactlglobal_no_instance_callbacks, \&tfactlcloud_is_no_instance_cmd);
  %tfactlglobal_cmds = (%tfactlglobal_cmds, %tfactlcloud_cmds);

  #Perform TFACTL consistency check if enabled
  if($tfactlglobal_hash{'consistchk'} eq 'y')
  {
     if(!tfactlshare_check_option_consistency(%tfactlcloud_cmds))
     {   
       exit 1;
     }
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlcloud init", 'y', 'n');

}

########
# NAME
#   tfactlcloud_process_cmd
#
# DESCRIPTION
#   This routine calls the appropriate routine to process the command 
#   specified by $tfactlglobal_hash{'cmd'}.
#
# PARAMETERS
#
# RETURNS
#   1 if command is found in the tfactlcloud module; 0 if not.
#
# NOTES
#   Only tfactl_shell() calls this routine.
########
sub tfactlcloud_process_cmd 
{
  my ($retval) = 0;
  my ($succ)   = 0;
  my $cmd = $tfactlglobal_hash{'cmd'};

  # Declare and initialize hash of function pointers, each designating a 
  # routine that processes an tfactlcloud command.
  my %cmdhash = ( cloudcheck => \&tfactlcloud_process_cloudcheck,
                  );
  if (defined ($cmdhash{$cmd})) {
    # If user specifies a known command, then call routine to process it
    $retval = $cmdhash{ $cmd }->();
    $succ = 1;
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlcloud tfactlcloud_process_cmd", 'y', 'n');
  return ($succ, $retval);
}

########
# NAME
#   tfactlcloud_process_cloudchk
#
# DESCRIPTION
#   This function ...
#
# PARAMETERS
#
# RETURNS
#   Null.
#
# NOTES
#   Only tfactlcloud_process_cmd() calls this function.
########
sub tfactlcloud_process_cloudcheck
{
  my $retval = 0;

  tfactlshare_trace(3, "tfactl (PID = $$) tfactlcloud tfactlcloud_process_cloudcheck", 'y', 'n');
  #Read the commands
  @ARGV = @tfactlglobal_argv;
  my $command1 = shift(@ARGV);
  my $switch_val = $command1;

  if ($switch_val eq "cloudcheck") {
    my $help;
    my $unknownopt;

    my %options =  ( 
      "exacd" => \$CLOUDCHECK_EXACD,
      "local" => \$CLOUDCHECK_LOCAL,
      "h"   => \$help,
      "help" => \$help);
  
    my @arrayoptions = (
      "exacd=s",
      "local",
      "h",
      "help"); 

    GetOptions(\%options, @arrayoptions) or $unknownopt = 1;

    if ($help || $unknownopt) {
      print_help("cloudcheck");
      return 1;
    }
    if (-f $CLOUDCHECK_EXACD) {
      #exacd argument is json file 
      $retval = tfactlcloud_processExacd(); 
    }
    else {
      print_help("cloudcheck");
      return 1;
    }
  } 
  return $retval;
}

########
# NAME
#   tfactlcloud_process_help
#
# DESCRIPTION
#   This function is the help function for the tfactlcloud module.
#
# PARAMETERS
#   command     (IN) - display the help message for this command.
#
# RETURNS
#   1 if command found; 0 otherwise.
########
sub tfactlcloud_process_help 
{
  my ($command) = shift;# User-specified argument; show help on $cmd. #
  my ($desc);           # Command description for $cmd. #
  my ($succ) = 0;       # 1 if command found, 0 otherwise. #
  if (tfactlcloud_is_cmd ($command)) {
    # User specified a command name to look up.
    $desc = tfactlshare_get_help_desc($command);
    tfactlshare_print "$desc\n";
    $succ = 1;
  }
  return $succ;
}

########
# NAME
#   tfactlcloud_is_cmd
#
# DESCRIPTION
#   This routine checks if a user-entered command is one of the known
#   TFACTL internal commands that belong to the tfactlcloud module.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is one of the known commands, false otherwise.
########
sub tfactlcloud_is_cmd 
{
  my ($arg) = shift;
  return defined ($tfactlcloud_cmds {$arg});
}

########
# NAME
#   tfactlcloud_is_wildcard_cmd
#
# DESCRIPTION
#   This routine determines if an tfactlcloud command allows the use 
#   of wild cards.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is a command that can take wildcards as part of its argument, 
#   false otherwise.
########
sub tfactlcloud_is_wildcard_cmd 
{
  my ($arg) = shift;
  return defined ($tfactlcloud_cmds{ $arg }) &&
    (tfactlshare_get_cmd_wildcard($arg) eq "True") ;
}

########
# NAME
#   tfactlcloud_is_no_instance_cmd
#
# DESCRIPTION
#   This routine determines if a command can run without an TFAMain instance.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is a command that can run without an TFAMain instance 
#   or does not exist, false otherwise.
#
# NOTES
#   The tfactlcloud module currently supports no command that can run 
#   without an TFAMain instance.
########
sub tfactlcloud_is_no_instance_cmd 
{
  my ($arg) = shift;
  return !defined ($tfactlcloud_cmds{ $arg }) ||
    (tfactlshare_get_cmd_noinst($arg) ne "True" ) ;
}

########
# NAME
#   tfactlcloud_syntax_error
#
# DESCRIPTION
#   This function prints the correct syntax for a command to STDERR, used 
#   when there is a syntax error.  This function is responsible for 
#   only tfactlcloud commands.
#
# PARAMETERS
#   cmd   (IN) - user-entered command name string.
#
# RETURNS
#   1 if the command belongs to this module; 0 if command not found.
#
# NOTES
#   These errors are user-errors and not internal errors.  They are of type
#   record, not signal.  
# 
#   N.B. Functions in this module can call this function directly, without
#   calling the tfactlshare::tfactlshare_syntax_error equivalent.  The
#   latter is used only by the tfactl module.
########
sub tfactlcloud_syntax_error 
{
  my ($cmd) = shift;
  my ($cmd_syntax);    # Correct syntax for $cmd. #
  my ($succ) = 0;
  #display syntax only for commands in this module.
  if (tfactlcloud_is_cmd($cmd)) {
    tfactlshare_get_help_syntax($cmd);
    $succ = 1;
    if ($tfactlglobal_hash{'mode'} eq 'n') {
      $tfactlglobal_hash{'e'} = -1;
    }
  }
  return $succ;
}

########
# NAME
#   tfactlcloud_get_tfactl_cmds
#
# DESCRIPTION
#   This routine constructs a string that contains a list of the names of all 
#   TFACTL internal commands and returns this string.
#
# PARAMETERS
#   None.
#
# RETURNS
#   A string contain a list of the names of all TFACTL internal commands.
#
# NOTES
#   Used by the help command and by the error command when the user enters
#   an invalid internal command.
#
#   IMPORTANT: the commands names must be preceded by eight (8) spaces of
#              indention!  This formatting is mandatory.
########
sub tfactlcloud_get_tfactl_cmds 
{
  return tfactlshare_filter_invisible_cmds(%tfactlcloud_cmds);
}

########
# NAME
#   tfactlcloud_processExacd
#
# DESCRIPTION
#   This routine constructs and returns a json string of all the
#   collections hapened after start_time
#
# PARAMETERS
#   tfa_home - TFA_HOME
#   start_time - Get all the collections happened from this time
#
# RETURNS
#   A JSON string with attributes as events and tfaml link etc
#
# NOTES
#   Used by the help command and by the error command when the user enters
#   an invalid internal command.
#
#   IMPORTANT: the commands names must be preceded by eight (8) spaces of
#              indention!  This formatting is mandatory.
########

sub tfactlcloud_processExacd {
  my $localhost = tolower_host();
  my $tracebasepath;
  my $json_text;
  my $json_hash_ref;
  my $start_time;
  my $actionmessage;
  my $args;
  my $command;
  my $line;
  my $status = 0;
  my $debugFlag = 0;
  my $json_output = "";
  my $tfaweb_url = "";
  my $config_file;
  my $hostname;
  my $event_name;
  my $timestamp;
  my $instance;
  my $database;
  my $message;
  my $source_file;

  $json_text = `$CAT $CLOUDCHECK_EXACD`;
  chomp($json_text);
  $json_hash_ref = tfactlparser_decodeJSON($json_text); 
  #print Dumper($json_hash_ref);
  $start_time = $json_hash_ref->{start_time};
  #Get tfaml_url from config file
  $config_file = catfile($tfa_home, "internal", "config.properties");
  $tfaweb_url = tfactlshare_getConfigValue($config_file,"tfaweb.url");
  $actionmessage = "$localhost:printcollections:$arg_sep"."start_time=$start_time";
  $command = buildCLIJava($tfa_home,$actionmessage);
  #print "command=$command\n";
  my @cli_output = tfactlshare_runClient($command);
  my $first_collection = 1;
  foreach $line (@cli_output) {
    #print "line=$line\n";
    if ($line eq "NO COLLECTIONS TO PRINT") {
      dbg(DBG_WHAT,"No diagnostic collections to print in TFA\n");
      $json_output = "{\"status\" : \"NO_EVENTS\"}";
      $status = 1;
    }
    elsif ($line eq "DONE" || $line eq "SUCCESS") {
      dbg(DBG_WHAT, "#### All Stored Collections Printed #### \n");
      $status = 1;
      last; 
    }
    else {
      my ($collid, $collType, $requestUser, $nodelist, $masternode, $start, $end, $tag, $zip, $comps, $zipSize, $time, $events) = split(/!/, $line);
      $status = 1;
      if ($json_output eq "") {
	$json_output = "{\"status\": \"events_found\",\"collections\": [";
      }
      $hostname = substr($collid,14);
      #Creating one record for each collection as events is not null in cloud env
      if ($first_collection) {
	$json_output .= "{";
	$first_collection = 0;
      }
      else {
	$json_output .= ",{";
      }
      $json_output .= "\"analysis\": \"$tfaweb_url?goto=details&p_collection=$collid\",".
                      "\"hostname\": \"$hostname\",".
		      "\"events\": [";
      #Get all other details from index
      my $col_txt_file = catfile($tag,"$zip.txt");
      #TODO: Handle colusterwide collection events      
      open(RF,"$col_txt_file") || next;
      my $first_event = 1;
      while(<RF>) {
        if (/Event: (.*)/) {
	  $event_name = $1;
	}
	elsif (/Event time: (.*)/) {
	  $timestamp = $1;
	  $timestamp = dateutils_format_date($timestamp,"YYYY-MM-DDTHH:MM:SS.SSSZ");
	}
	elsif (/File containing event: .*\/([^\/]+$)/) {
	  $source_file = $1;
	  if ($source_file =~ /alert_(.*).log/) {
	    $instance = $1;
	    $database = substr($instance,0,length($instance)-1);
	  }
	  else {
	    $instance = "";
	    $database = "";
	  }
	}
	elsif (/String containing event: (.*)/) {
	  $message = $1;
   	  if ($first_event) {
	    $json_output .= "{";
	    $first_event = 0;
	  }
	  else {
	    $json_output .= ",{";
	  }
          $json_output .= "\"database\": \"$database\",".
	    "\"instance\": \"$instance\",".
            "\"timestamp\": \"$timestamp\",".
	    "\"error\": \"$event_name\",".
	    "\"messagetype\": \"ERROR\",".
	    "\"message\": \"$message\"}";
	}
      }	
      close(RF);
      $json_output .= "]}";
    }
  }
  if ($status == 1) {
    $json_output .= "]}" if $json_output !~ /no_events/;
    print "$json_output\n";
  } 
  else {
    print "Failed. Please try later\n";
  }
  return 0;
}

1;
