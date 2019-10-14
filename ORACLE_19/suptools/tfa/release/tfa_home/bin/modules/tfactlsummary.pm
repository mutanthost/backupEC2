# 
# $Header: tfa/src/v2/tfa_home/bin/modules/tfactlsummary.pm /main/6 2018/08/15 16:55:52 bburton Exp $
#
# tfactlsummary.pm
# 
# Copyright (c) 2017, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlsummary.pm 
#
#    DESCRIPTION
#      TFA Summary
#
#    NOTES
#     
#
#    MODIFIED   (MM/DD/YY)
#    recornej    08/06/18 - Change SUCCESS and FAILED values.
#    manuegar    08/05/18 - XbranchMerge manuegar_dbutils16 from main
#    manuegar    07/23/18 - manuegar_dbutils16.
#    manuegar    07/13/18 - manuegar_multibug_01.
#    manuegar    07/03/18 - manuegar_dbutils14.
#    manuegar    03/13/18 - Creation
#
############################ Functions List #################################
#
# 
#############################################################################

package tfactlsummary;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(tfactlsummary_init
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
Getopt::Long::Configure("prefix_pattern=(-|--)");
use Pod::Usage;
use Sys::Hostname;
use POSIX;
use POSIX qw(strftime);
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
use tfactlparser;
use tfactldbutilhandler;

#################### tfactlsummary Global Constants ####################

my (%tfactlsummary_cmds) = (isa           => {},
                              );


#################### tfactlsummary Global Variables ####################

sub is_tfactl
{
  return 1;
}


########
# NAME
#   tfactlsummary_init
#
# DESCRIPTION
#   This function initializes the tfactlsummary module.  For now it 
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
  push (@tfactlglobal_command_callbacks, \&tfactlsummary_process_cmd);
  push (@tfactlglobal_help_callbacks, \&tfactlsummary_process_help);
  push (@tfactlglobal_command_list_callbacks, \&tfactlsummary_get_tfactl_cmds);
  push (@tfactlglobal_is_command_callbacks, \&tfactlsummary_is_cmd);
  push (@tfactlglobal_is_wildcard_callbacks, \&tfactlsummary_is_wildcard_cmd);
  push (@tfactlglobal_syntax_error_callbacks, \&tfactlsummary_syntax_error);
  push (@tfactlglobal_no_instance_callbacks, \&tfactlsummary_is_no_instance_cmd);
  %tfactlglobal_cmds = (%tfactlglobal_cmds, %tfactlsummary_cmds);

  #Perform TFACTL consistency check if enabled
  if($tfactlglobal_hash{'consistchk'} eq 'y')
  {
     if(!tfactlshare_check_option_consistency(%tfactlsummary_cmds))
     {   
       exit 1;
     }
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlsummary init", 'y', 'n');

}

########
# NAME
#   tfactlsummary_process_cmd
#
# DESCRIPTION
#   This routine calls the appropriate routine to process the command 
#   specified by $tfactlglobal_hash{'cmd'}.
#
# PARAMETERS
#   dbh       (IN) - initialized database handle, must be non-null.
#
# RETURNS
#   1 if command is found in the tfactlsummary module; 0 if not.
#
# NOTES
#   Only tfactl_shell() calls this routine.
########
sub tfactlsummary_process_cmd 
{
  my ($retval) = 0;
  my ($succ)   = 0;

  # Get current command from global value, which is set by 
  # tfactlsummary_parse_tfactl_args()and by tfactl_shell().
  my ($cmd) = $tfactlglobal_hash{'cmd'};

  # Declare and initialize hash of function pointers, each designating a 
  # routine that processes an tfactlsummary command.
  my (%cmdhash) = ( isa           => \&tfactlsummary_process_command,
                  );

  if (defined ( $cmdhash{ $cmd } ))
  {    # If user specifies a known command, then call routine to process it. #
    $retval = $cmdhash{ $cmd }->();
    $succ = 1;
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlsummary tfactlsummary_process_cmd", 'y', 'n');

  return ($succ, $retval);
}

########
# NAME
#   tfactlsummary_process_command
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
#   Only tfactlsummary_process_cmd() calls this function.
########
sub tfactlsummary_process_command
{
  my $retval = 0;
  my @diagoptions;
  my %diaghashoptions;
  my $availability;
  my $all;
  my $includescore;
  my $node;
  my $unknownopt;
  my $help;
  my @nodes = ();
  my $scoretxt = "";

  tfactlshare_trace(3, "tfactl (PID = $$) tfactlsummary tfactlsummary_process_command", 'y', 'n');

  @diagoptions = ( 'node=s', 'availability!', 'all!', 'includescore!', 'help|h!' );
  %diaghashoptions = (
        'node'           =>\$node,
        'availability'   =>\$availability,
        'all'            =>\$all,
        'includescore'   =>\$includescore,
        'help'           =>\$help,
        'h'              =>\$help,
      );

  my $warning;
  local $SIG{__WARN__} = sub {$warning = $_[0];};# Supress warnings
  GetOptions( \%diaghashoptions, @diagoptions )
  or $unknownopt = 1;

  if ( $unknownopt )
  {
    print_help("isa");
    exit 1;
  }

  if ( $help ) {
    print_help("isa");
    exit 0;
  }

  if ( $node ) {
    @nodes = tfactlshare_check_node_validity($tfa_home, $node, "isa");
  } else {
    @nodes = tfactlshare_check_node_validity($tfa_home, 'all', "isa");
  }

  if ( $includescore ) {
    $scoretxt = "score";
  }

  if ( $all ) {
    $DBUTILSSUMMARYMODE = "all$scoretxt";
  } else {
    $DBUTILSSUMMARYMODE = "default$scoretxt";
  }

  ### print "nodes @nodes\n";

  # Read the commands
  if ( @ARGV ) {
    print "@ARGV is(are) not valid argument(s).\n";
    print_help("isa");
    exit 1;
  }

  @ARGV = @tfactlglobal_argv;

  my $command1 = shift(@ARGV);
  my $switch_val = $command1;

  if ($switch_val eq "isa" ) {
    $DBUTILSSUMMARY = TRUE;
    $DBUTILSSUMMARYNODES = "@nodes";
    tfactlshare_trace(3, "tfactl (PID = $$) tfactlsummary tfactlsummary_process_command Running Isa ...", 'y', 'n');
    ### print "Running Isa ...\n";
  }

  # Dispatch the command
  tfactlshare_pre_dispatch();
  $retval = tfactlsummary_dispatch();

  return $retval;
}

########
# NAME
#   tfactlsummary_dispatch
#
# DESCRIPTION
#   Dispatch de command.
#
# PARAMETERS
#
# RETURNS
#
########
sub tfactlsummary_dispatch
{
 my $retval = 0;

 if ( $DBUTILSSUMMARY ) { $retval = tfactlsummary_main($DBUTILSSUMMARYMODE, $DBUTILSSUMMARYNODES); 
                      $DBUTILSSUMMARY = FALSE;
                      $DBUTILSSUMMARYNODES = "";
                      $DBUTILSSUMMARYMODE = "default"; }

 return $retval;
}

########
# NAME
#   tfactlsummary_process_help
#
# DESCRIPTION
#   This function is the help function for the tfactlsummary module.
#
# PARAMETERS
#   command     (IN) - display the help message for this command.
#
# RETURNS
#   1 if command found; 0 otherwise.
########
sub tfactlsummary_process_help 
{
  my ($command) = shift;       # User-specified argument; show help on $cmd. #

  my ($desc);                                # Command description for $cmd. #
  my ($succ) = 0;                         # 1 if command found, 0 otherwise. #

  if (tfactlsummary_is_cmd ($command)) 
  {                              # User specified a command name to look up. #
    $desc = tfactlshare_get_help_desc($command);
    tfactlshare_print "$desc\n";
    $succ = 1;
  }

  return $succ;
}

########
# NAME
#   tfactlsummary_is_cmd
#
# DESCRIPTION
#   This routine checks if a user-entered command is one of the known
#   TFACTL internal commands that belong to the tfactlsummary module.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is one of the known commands, false otherwise.
########
sub tfactlsummary_is_cmd 
{
  my ($arg) = shift;

  return defined ($tfactlsummary_cmds {$arg});

}

########
# NAME
#   tfactlsummary_is_wildcard_cmd
#
# DESCRIPTION
#   This routine determines if an tfactlsummary command allows the use 
#   of wild cards.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is a command that can take wildcards as part of its argument, 
#   false otherwise.
########
sub tfactlsummary_is_wildcard_cmd 
{
  my ($arg) = shift;

  return defined ($tfactlsummary_cmds{ $arg }) &&
    (tfactlshare_get_cmd_wildcard($arg) eq "True" ) ;
}

########
# NAME
#   tfactlsummary_is_no_instance_cmd
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
#   The tfactlsummary module currently supports no command that can run 
#   without an TFAMain instance.
########
sub tfactlsummary_is_no_instance_cmd 
{
  my ($arg) = shift;

  return !defined ($tfactlsummary_cmds{ $arg }) ||
    (tfactlshare_get_cmd_noinst($arg) ne "True" ) ;
}

########
# NAME
#   tfactlsummary_syntax_error
#
# DESCRIPTION
#   This function prints the correct syntax for a command to STDERR, used 
#   when there is a syntax error.  This function is responsible for 
#   only tfactlsummary commands.
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
sub tfactlsummary_syntax_error 
{
  my ($cmd) = shift;
  my ($cmd_syntax);                               # Correct syntax for $cmd. #
  my ($succ) = 0;


  #display syntax only for commands in this module.
  if (tfactlsummary_is_cmd($cmd))
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

########
# NAME
#   tfactlsummary_get_tfactl_cmds
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
sub tfactlsummary_get_tfactl_cmds 
{
  return tfactlshare_filter_invisible_cmds(%tfactlsummary_cmds);
}

########
### NAME
###   tfactlsummary_main
###
### DESCRIPTION
###   TFA Summary entry point
###
### PARAMETERS
###
### RETURNS
###
### NOTES
###
##########
sub tfactlsummary_main {
  my $mode  = shift;
  my $nodes = shift;
  my $localhost = tolower_host();
  my $message = "$localhost:ddusummary:$mode $nodes";
  ### print "message $message\n";
  my $cmd  = buildCLIJava($tfa_home,$message);
  my @output = split(/\n/,`$cmd`);
  if ( grep { /SUCCESS/ } @output ) {
    ### print "tfactlsummary_main : TFA Summary entry point is working !\n";
    tfactlshare_trace(3, "tfactl (PID = $$) tfactlsummary tfactlsummary_main TFA Summary entry point is working !", 'y', 'n');
    foreach my $line (@output) {
      print "$line\n" if $line !~ /SUCCESS/;
    }
  } else {
    print "tfactlsummary_main failed.\n";
    exit (1); 
  }

  return 0;
} # end sub tfactlsummary_main


