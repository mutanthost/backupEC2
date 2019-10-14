# 
# $Header: tfa/src/v2/tfa_home/bin/modules/tfactlcollection.pm /main/8 2018/08/09 22:22:31 recornej Exp $
#
# tfactlcollection.pm
# 
# Copyright (c) 2014, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlcollection.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    08/06/18 - Change SUCCESS and FAILED values.
#    manuegar    07/13/18 - manuegar_multibug_01.
#    bburton     03/19/18 - Bug 27665984 - remove use of POSIX::tmpnam
#    cnagur      04/07/17 - Removed Error Message 103 - Bug 24971982
#    bibsahoo    08/25/15 - Adding Global Error Code 103
#    amchaura    01/20/15 - Fix Bug 20351825 - LNX64-12.2-TFA-FCS:NO PRECHECK
#                           FOR TFACTL COLLECTION INVALID OPTION
#    amchaura    08/27/14 - Fix 18296461 LNX64-12.1-TFA-SCS:NEED A WAY TO INTERRUPT RUNNING DIAGNOSTIC COLLECTIONS
#    amchaura    08/26/14 - Creation
#
########################### Functions List #################################
#
# collectionStop
# 
#############################################################################

package tfactlcollection;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(tfactlcollection_init
                 );

use strict;
use IPC::Open2;
use File::Copy;
use File::Path;
use File::Find;
use File::Basename;
use File::Basename  qw( dirname );
use File::Spec::Functions;
use Getopt::Long;
use Sys::Hostname;
use POSIX;
use POSIX qw(:termios_h);
use Carp;
use Config;
use Data::Dumper;
use Socket;
use Text::ASCIITable;
use Text::Wrap;
use Time::Local;
use constant ERROR                     => "-1";
use constant FAILED                    =>  1;
use constant SUCCESS                   =>  0;
use constant TRUE                      =>  "1";
use constant FALSE                     =>  "0";
use constant CONNFAIL                  =>  "99";
use constant DBG_NOTE => "1";              # Notes to the user
use constant DBG_WHAT => "2";              # Explain what you do
use constant DBG_VERB => "4";              # Be verbose
use constant DBG_HOST => "8";              # print command executed on local host

use tfactlglobal;
use tfactlshare;

################### tfactlcollection Global Constants ####################
my (%tfactlcollection_cmds) = (collection      => {},
                         );


################### tfactlcollection Global Variables ####################
sub is_tfactl
{
  return 1;
}


#######
# NAME
#   tfactlcollection_init
#
# DESCRIPTION
#   This function initializes the tfactlcollection module.  For now it 
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
  # All of the arrays defined in the tfactlglobal module must be 
  # initialized here.  Otherwise, an internal error will result.
  push (@tfactlglobal_command_callbacks, \&tfactlcollection_process_cmd);
  push (@tfactlglobal_help_callbacks, \&tfactlcollection_process_help);
  push (@tfactlglobal_command_list_callbacks, \&tfactlcollection_get_tfactl_cmds);
  push (@tfactlglobal_is_command_callbacks, \&tfactlcollection_is_cmd);
  push (@tfactlglobal_is_wildcard_callbacks, \&tfactlcollection_is_wildcard_cmd);
  push (@tfactlglobal_syntax_error_callbacks, \&tfactlcollection_syntax_error);
  push (@tfactlglobal_no_instance_callbacks, \&tfactlcollection_is_no_instance_cmd);
  %tfactlglobal_cmds = (%tfactlglobal_cmds, %tfactlcollection_cmds);

  #Perform TFACTL consistency check if enabled
  if($tfactlglobal_hash{'consistchk'} eq 'y')
  {
     if(!tfactlshare_check_option_consistency(%tfactlcollection_cmds))
     {
       exit 1;
     }
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlcollection init", 'y', 'n');

}

#######
# NAME
#   tfactlcollection_process_cmd
#
# DESCRIPTION
#   This routine calls the appropriate routine to process the command 
#   specified by $tfactlglobal_hash{'cmd'}.
#
# PARAMETERS
#   dbh       (IN) - initialized database handle, must be non-null.
#
# RETURNS
#   1 if command is found in the tfactlcollection module; 0 if not.
#
# NOTES
#   Only tfactl_shell() calls this routine.
########
sub tfactlcollection_process_cmd 
{
  my ($retval) = 0;
  my ($succ)   = 0;

  # Get current command from global value, which is set by 
  # tfactlcollection_parse_tfactl_args()and by tfactl_shell().
  my ($cmd) = $tfactlglobal_hash{'cmd'};

  # Declare and initialize hash of function pointers, each designating a 
  #   # routine that processes an tfactlcollection command.
  my (%cmdhash) = ( collection       => \&tfactlcollection_process_command,
                  );

  if (defined ( $cmdhash{ $cmd } ))
  {    # If user specifies a known command, then call routine to process it. #
    $retval = $cmdhash{ $cmd }->();
    $succ = 1;
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlcollection tfactlcollection_process_cmd", 'y', 'n');

  return ($succ, $retval);
}

#######
# NAME
#   tfactlcollection_process_command
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
#   Only tfactlcollection_process_cmd() calls this function.
########
sub tfactlcollection_process_command
{
  my $retval = 0;

  tfactlshare_trace(3, "tfactl (PID = $$) tfactlcollection tfactlcollection_process_command", 'y', 'n');
  # Read the commands
   @ARGV = @tfactlglobal_argv;
  my $command1 = shift(@ARGV);
  my $command2 = shift(@ARGV);
  my $command3 = shift(@ARGV);
  my $switch_val = $command1;

  if ($switch_val eq "collection" ) {
	if ( ! $command2 ) {
	   print_help ("collection", ""); 
	   return;
	}
        if (defined $command2 && ($command2 eq "-h" || $command2 eq "-help")) {
           print_help("collection", "");
           return;
        }
        $switch_val = $command2 ;
        if ($switch_val eq "stop" ) {
           if (defined $command3 && ($command3 eq "-h" || $command3 eq "-help")) {
              print_help("collection", "");
              return;
           }
           $STOPCOLLECTION = $command3;
        } 
	else { print_help("collection", ""); return; }      
   }
  # Dispatch the command
  tfactlshare_pre_dispatch();
  $retval = tfactlcollection_dispatch();

  return $retval;
}
#######
# NAME
#   tfactlcollection_dispatch
#
# DESCRIPTION
#   Dispatch de command.
#
# PARAMETERS
#
# RETURNS
#
########
sub tfactlcollection_dispatch
{
 my $retval = 0;

 if ($STOPCOLLECTION) { $retval = collectionStop($tfa_home, $STOPCOLLECTION); undef($STOPCOLLECTION); }

 return $retval;
}

#######
# NAME
#   tfactlcollection_process_help
#
# DESCRIPTION
#   This function is the help function for the tfactlcollection module.
#
# PARAMETERS
#   command     (IN) - display the help message for this command.
#
# RETURNS
#   1 if command found; 0 otherwise.
########
sub tfactlcollection_process_help 
{
  my ($command) = shift;       # User-specified argument; show help on $cmd. #

  my ($desc);                                # Command description for $cmd. #
  my ($succ) = 0;                         # 1 if command found, 0 otherwise. #

  if (tfactlcollection_is_cmd ($command))
  {                              # User specified a command name to look up. #
    $desc = tfactlshare_get_help_desc($command);
    tfactlshare_print "$desc\n";
    $succ = 1;
  }

  return $succ;
}
#######
# NAME
#   tfactlcollection_is_cmd
#
# DESCRIPTION
#   This routine checks if a user-entered command is one of the known
#   TFACTL internal commands that belong to the tfactlcollection module.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is one of the known commands, false otherwise.
########
sub tfactlcollection_is_cmd 
{
  my ($arg) = shift;

  return defined ($tfactlcollection_cmds {$arg});

}
#######
# NAME
#   tfactlcollection_is_wildcard_cmd
#
# DESCRIPTION
#   This routine determines if an tfactlcollection command allows the use 
#   of wild cards.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is a command that can take wildcards as part of its argument, 
#   false otherwise.
########
sub tfactlcollection_is_wildcard_cmd 
{
  my ($arg) = shift;

  return defined ($tfactlcollection_cmds{ $arg }) &&
    (tfactlshare_get_cmd_wildcard($arg) eq "True" ) ;
}

#######
# NAME
#   tfactlcollection_is_no_instance_cmd
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
#   The tfactlcollection module currently supports no command that can run 
#   without an TFAMain instance.
########
sub tfactlcollection_is_no_instance_cmd 
{
  my ($arg) = shift;

  return !defined ($tfactlcollection_cmds{ $arg }) ||
    (tfactlshare_get_cmd_noinst($arg) ne "True" ) ;
}

#######
# NAME
#   tfactlcollection_syntax_error
#
# DESCRIPTION
#   This function prints the correct syntax for a command to STDERR, used 
#   when there is a syntax error.  This function is responsible for 
#   only tfactlcollection commands.
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
#######
sub tfactlcollection_syntax_error 
{
  my ($cmd) = shift;
  my ($cmd_syntax);                               # Correct syntax for $cmd. #
  my ($succ) = 0;


  #display syntax only for commands in this module.
  if (tfactlcollection_is_cmd($cmd))
  {
    tfactlshare_get_help_syntax($cmd);
    $succ = 1;

    if ($tfactlglobal_hash{'mode'} eq 'n')
    {
      $tfactlglobal_hash{'e'} = -1;
    }
  }

  return $succ;
}

#######
# NAME
#   tfactlcollection_get_tfactl_cmds
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
sub tfactlcollection_get_tfactl_cmds 
{
  return tfactlshare_filter_invisible_cmds(%tfactlcollection_cmds);
}

#====================== collectionStop = ===========================#
sub collectionStop
{
  my $tfa_home = shift;
  my $collectionid = shift;
  my $localhost=tolower_host();
  my $message = "$localhost:stopcollection:$collectionid";
  my $command = buildCLIJava($tfa_home,$message);
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
    if ($line eq "SUCCESS") {
        print "Collection $collectionid stopped Successfully\n";
        return SUCCESS;
    }
    elsif ($line eq "FAILED") {
      print "Stop Collection failed.\n";
    }
    else {
      print "$line\n";
    }
  }
  return FAILED;
}

