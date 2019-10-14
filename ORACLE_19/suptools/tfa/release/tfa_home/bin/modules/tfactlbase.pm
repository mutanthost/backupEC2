# 
# $Header: tfa/src/v2/tfa_home/bin/modules/tfactlbase.pm /main/4 2018/07/17 09:48:56 manuegar Exp $
#
# tfactlbase.pm
# 
# Copyright (c) 2014, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlbase.pm - Base Module
#
#    DESCRIPTION
#      TFACTL - Trace File Analyzer Control Utility      
#
#    NOTES
#      usage: tfactl [-v {errors|warnings|normal|info|debug|none}] [command] 
#
#    MODIFIED   (MM/DD/YY)
#    manuegar    07/13/18 - manuegar_multibug_01.
#    manuegar    11/05/14 - Implement <action> <toolname> <flags> for support
#                           tools.
#    manuegar    07/22/14 - Relocate tfactl_lib
#    manuegar    06/30/14 - Creation
#
############################ Functions List #################################
#
# Top Level Command Processing Routines
#   tfactlbase_init
#   tfactlbase_process_cmd
#   tfactlbase_process_help

# Internal Command Processing Routines
#
# Parameter Parsing Routines
#   tfactlbase_is_cmd
#   tfactlbase_is_wildcard_cmd
#   tfactlbase_is_no_instance_cmd
#   tfactlbase_parse_int_cmd_line
#
# Error Routines
#   tfactlbase_syntax_error
#
# Initialization Routines
#   tfactlbase_init_global
#
# Help Routines
#   tfactlbase_get_tfactl_cmds
#
#############################################################################

package tfactlbase;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(tfactlbase_init
                 tfactlbase_process_cmd
                 tfactlbase_process_help
                 tfactlbase_is_cmd
                 tfactlbase_parse_int_cmd_line
                 tfactlbase_init_global
                 tfactlbase_syntax_error
                 tfactlbase_get_tfactl_cmds
                );

use strict;
use Math::BigInt;
use tfactlglobal;
use tfactlshare;

use List::Util qw[min max];
use POSIX qw(:termios_h);

############################ Global Constants ###############################
#
# The following list is used primarily for is_cmd.  All other data from XML.
#
my  (%tfactlbase_cmds) = (help    => {},
                          add     => {},
                          modify  => {},
                          remove  => {},
                          );

my ($TFACTLBASE_SPACE) = ' ';           # Constant string for a space.      #
my ($TFACTLBASE_SIXMONTH) = 183;        # Number of days in six months.     #
my ($TFACTLBASE_DATELEN) = 15;          # Length of the date string.        #
my ($TFACTLBASE_MAXPASSWD) = 256;       # Max length of user passwd input   #

# for remote connection
our ($rusr, $rpswd, $rident, $rhost, $rsid, $rport);

sub is_tfactl
{
  return 1;
}


################# Top Level Command Processing Routines ######################
########
# NAME
#   tfactlbase_init
#
# DESCRIPTION
#   This function initializes the tfactlbase module.  For now it simply 
#   registers its callbacks with the tfactlglobal module.
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
  push (@tfactlglobal_command_callbacks, \&tfactlbase_process_cmd);
  push (@tfactlglobal_help_callbacks, \&tfactlbase_process_help);
  push (@tfactlglobal_command_list_callbacks, \&tfactlbase_get_tfactl_cmds);
  push (@tfactlglobal_is_command_callbacks, \&tfactlbase_is_cmd);
  push (@tfactlglobal_is_wildcard_callbacks, \&tfactlbase_is_wildcard_cmd);
  push (@tfactlglobal_syntax_error_callbacks, \&tfactlbase_syntax_error);
  push (@tfactlglobal_no_instance_callbacks, \&tfactlbase_is_no_instance_cmd);
  %tfactlglobal_cmds = (%tfactlglobal_cmds, %tfactlbase_cmds);

  #Perform TFACTL consistency check if enabled
  if($tfactlglobal_hash{'consistchk'} eq 'y')
  {
     if(!tfactlshare_check_option_consistency(%tfactlbase_cmds))
     {
       exit 1;
     }   
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlbase init", 'y', 'n');

}


########
# NAME
#   tfactlbase_process_cmd
#
# DESCRIPTION
#   This routine calls the appropriate routine to process the command specified
#   by $tfactlglobal_hash{'cmd'}.
#
# PARAMETERS
#   dbh       (IN) - initialized database handle, must be non-null.
#
# RETURNS
#   1 if command is found; 0 if not.
#
# NOTES
#   Only tfactl_shell() calls this routine.
########
sub tfactlbase_process_cmd 
{
  my ($retval) = 0;
  my ($succ)   = 0;
 
  # Get current command from global value, which is set by 
  # tfactlbase_parse_tfactl_args()and by tfactl_shell().
  my($cmd) = $tfactlglobal_hash{'cmd'};

  # Declare and initialize hash of function pointers, each designating a 
  # routine that processes an TFACTL command.  Now that TFACTL is divided
  # into modules, the help command needs to be removed from this list,
  # because it's a global command, not a module specific command.
  # command => \&tfactlbase_process_command
  my (%cmdhash) = (  add       => \&tfactlbase_process_deprecated,
                     remove    => \&tfactlbase_process_deprecated,
                     modify    => \&tfactlbase_process_deprecated, 
                 );

  if (defined ( $cmdhash{ $cmd } ))
  {    # If user specifies a known command, then call routine to process it. #
    $retval = $cmdhash{ $cmd }->();
    $succ = 1;
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlbase tfactlbase_process_cmd", 'y', 'n');

  return ($succ, $retval);
}


########
# NAME
#   tfactlbase_process_help
#
# DESCRIPTION
#   This function is the help function for the tfactlbase module.
#
# PARAMETERS
#   command     (IN) - display the help message for this command.
#
# RETURNS
#   1 if command found; 0 otherwise.
########
sub tfactlbase_process_help 
{
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlbase tfactlbase_process_help", 'y', 'n');
  my ($command) = shift;       # User-specified argument; show help on $cmd. #
  my ($desc);                                # Command description for $cmd. #
  my ($succ) = 0;                         # 1 if command found, 0 otherwise. #

  if (tfactlbase_is_cmd ($command)) 
  {                              # User specified a command name to look up. #
    $desc = tfactlshare_get_help_desc($command);
    tfactlshare_print("$desc\n");
    $succ = 1;
  }

  return $succ;
}


########
# NAME
#   tfactlbase_process_deprecated
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
#   Only tfactlbase_process_cmd() calls this function.
########
sub tfactlbase_process_deprecated
{
  my $retval = 0;

  tfactlshare_trace(3, "tfactl (PID = $$) tfactlbase tfactlbase_process_deprecated", 'y', 'n');
  # Read the commands
  @ARGV = @tfactlglobal_argv;
  my $command1 = shift(@ARGV);
  my $command2 = shift(@ARGV);
  my $switch_val = $command1;

  if ($switch_val eq "add" ) 
        {
           print "This command is deprecated. Please use one of the following commands:\n";
           print "$tfacmd directory add <dir>\n";
           print "$tfacmd host add <host>\n";
           print "$tfacmd receiver add <host>\n";
          #exit 0;
          #print_help ("add", "") if ( ! $command2 );
          #if ( ! $command2 ) {
          #  print "This command is deprecated. Please use one of the following commands:\n";
          #  print "$tfacmd directory add <dir>\n";
          #  print "$tfacmd host add <host>\n";
          #  exit 0;
          #}
          #if (defined $command2 && ($command2 eq "-h" || $command2 eq "-help")) {
                #print_help("add");
          #      print "This command is deprecated. Please use one of the following commands:\n";
          #      print "$tfacmd directory add <dir>\n";
          #      print "$tfacmd host add <host>\n";
          #      exit 0;
          #}
          #$switch_val = $command2;
          #{
          #  if ($switch_val eq "directory")
          #      { $ADDDIR = shift(@ARGV);
          #        if ( ! $ADDDIR ) {
          #          #print_help ("add", "Directory name is missing from input") 
          #          print "This command is deprecated. Please use the following command:\n";
          #          print "$tfacmd directory add <dir>.\n";
          #          exit 0;
          #        }
          #        if ($ADDDIR eq "-h" || $ADDDIR eq "-help") {
          #          print "This command is deprecated. Please use the following command:\n";
          #          print "$tfacmd directory add <dir>.\n";
          #          exit 0;
          #        }
          #        my $command3 = shift(@ARGV);
          #        if ($command3 eq "-h" || $command3 eq "-help") {
          #          print "This command is deprecated. Please use the following command:\n";
          #          print "$tfacmd directory add <dir>.\n";
          #          exit 0;
          #        }
          #        if ($command3 && ($command3 eq "-private")) {
          #              $private_directory = 1;
          #        }
          #      }
          #  elsif ($switch_val eq "host" )
          #      {
          #        $ADDHOST = shift(@ARGV);
          #        if ( ! $ADDHOST ) {
          #              #print_help ("add", "Host name is missing from input") 
          #              print "This command is deprecated. Please use the following command:\n";
          #              print "$tfacmd host add <host>.\n";
          #              exit 0;
          #        }
          #        if ($ADDHOST eq "-h" || $ADDHOST eq "-help") {
          #              print "This command is deprecated. Please use the following command:\n";
          #              print "$tfacmd host add <host>.\n";
          #              exit 0;
          #        }
          #      }
          #  else { print_help ("add", "Invalid argument $command2"); }
          #}
        }
  elsif ($switch_val eq "modify" ) {
           print "This command is deprecated. Please use one of the following commands:\n";
           print "$tfacmd set reposizeMB=<N>\n";
           print "$tfacmd set repositorydir=<dir>\n";
           # exit 0;
           #$MODIFY = 1;
           #if ($command2 =~ /-reposizeMB/) {
           #     $CHANGEREPOSIZE=shift(@ARGV);
           #     my $command3 = shift(@ARGV);
           #     if ($command3 =~ /-repositorydir/) {
           #             $CHANGEREPO=shift(@ARGV);
           #     }
           #}
           #elsif ($command2 =~ /-repositorydir/) {
           #     $CHANGEREPO=shift(@ARGV);
           #     my $command3 = shift(@ARGV);
           #     if ($command3 =~ /-reposizeMB/) {
           #             $CHANGEREPOSIZE=shift(@ARGV);
           #     }
           #}
           #if (defined $CHANGEREPOSIZE) {
           #     if ($CHANGEREPOSIZE =~ /\D[\D]?/) {
           #       print_help("modify","Enter a valid number for repository size");
           #     }
           #}
           #if (! (defined $CHANGEREPO || defined $CHANGEREPOSIZE) ) {
           #     print_help ("modify", "" );
           #}
        }
  elsif ($switch_val eq "remove" )
        {
          print "This command is deprecated. Please use one of the following commands:\n";
          print "$tfacmd directory remove <dir>\n";
          print "$tfacmd host remove <host>\n";
          print "$tfacmd receiver remove <host>\n";
          #exit 0;
          #print_help ("remove", "") if ( ! $command2 );
          #if ( ! $command2 ) {
          #  print "This command is deprecated. Please use $tfacmd directory remove <dir>.\n";
          #  exit 0;
          #}
          #if (defined $command2 && ($command2 eq "-h" || $command2 eq "-help")) {
            #print_help("remove");
          #  print "This command is deprecated. Please use $tfacmd directory remove <dir>.\n";
          #  exit 0;
          #}
          #$switch_val = $command2 ;
          #{
          #  if ($switch_val eq "directory")
          #      { $RMDIR = shift(@ARGV);
          #        if ( ! $RMDIR ) {
          #          print_help ("remove", "Directory name is missing from input") }
          #      }
          #  elsif ($switch_val eq "host" )
          #      { $RMHOST = shift(@ARGV);
          #        if ( ! $RMHOST ) {
          #          print_help ("remove", "Host name is missing from input")
          #        }
          #      }
          #  else  { print_help ("remove", "Invalid argument $command2"); }
          #}
        }

  # Invoke the command
  tfactlshare_pre_dispatch();

  return $retval;
}

########
# NAME
#   tfactlbase_is_remote_syntax
#
# DESCRIPTION
#   To check whether given string is of remote-file syntax
#
# PARAMETERS
#   file (IN) - name of the file
#
# RETURNS
#   1 if remote syntax and 0 if not
#
# NOTES:  Checks with Windows file name syntax also.
###########
sub tfactlbase_is_remote_syntax
{
  my ($file) = shift ;               # file name to check for.
  my ($remote) = 0 ; 

  if ( $^O =~ /win/i )
  {
    #windows OS (both 32 & 64 bit OS).
    # the valid syntax are x:\dir\file & \\server\share\dir\file

    if ((($file !~ /^[a-z]:/i) &&  ($file !~ /^\\\\/)) && ($file =~ m':'))
    {
      # not starting with x: or \\ and found a ':' -> 
      # this is of format usr@server.port.inst:file used for remote syntax
      $remote = 1 ;
    }
  }
  else
  {
    $remote = 1  if ($file =~ m':');
  }
  return $remote ;
}

########
# NAME
#   tfactlbase_is_cmd
#
# DESCRIPTION
#   This routine checks if a user-entered command is one of the known TFACTL
#   internal commands that belong to the base module.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is one of the known commands, false otherwise.
########
sub tfactlbase_is_cmd 
{
  my ($arg) = shift;

  return defined ( $tfactlbase_cmds{ $arg } );
}

########
# NAME
#   tfactlbase_is_wildcard_cmd
#
# DESCRIPTION
#   This routine determines if a command allows the use of wild cards.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is a command that can take wildcards as part of its argument, 
#   false otherwise.
#
# NOTES
#   Currently, only cd, du, find, ls, and rm can take wildcard as part of
#   their arguments.
########
sub tfactlbase_is_wildcard_cmd 
{
  my ($arg) = shift;

  return defined ($tfactlbase_cmds{ $arg }) &&
         (tfactlshare_get_cmd_wildcard($arg) eq "True") ;
}

########
# NAME
#   tfactlbase_is_no_instance_cmd
#
# DESCRIPTION
#   This routine determines if a command can run without an TFA instance.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is a command that can run without an TFA instance 
#   or does not exist, false otherwise.
#
# NOTES
#   The tfactlbase module currently supports only the help as a command
#   that does not require an TFA instance.
########
sub tfactlbase_is_no_instance_cmd 
{
  my ($arg) = shift;

  return !defined ($tfactlbase_cmds{ $arg }) ||
         (tfactlshare_get_cmd_noinst($arg) ne "True" ) ;
}

########
# NAME
#   tfactlbase_parse_int_cmd_line
#
# DESCRIPTION
#   This routine parses a line of command and divides it up into tokens of 
#   arguments, delimited by spaces.
#
# PARAMETERS
#   cmd_line  (IN)   - user-entered line of command, including the command
#                      name and its arguments.
#   argv_ref  (OUT)  - Reference to an array of arguments to return, with the 
#                      command name stored as element zero of the array, and 
#                      its arguments stored as the subsequent elements; much 
#                      like the array 'argv' in C.  Should be passed in as 
#                      an empty array.
#
# RETURNS
#   0 on success, -1 on error.
#
# NOTES
#   Arguments are delimited by whitespace, unless that whitespace is enclosed
#   within single quotes, in which case they are considered as part of one
#   argument.
#
#   Valid states for the state transition:
#     NO QUOTE - parsing a portion of $cmd_line that's *not* in quotes.
#     IN QUOTE - parsing a portion of $cmd_line that's in quotes.
#     SPACES   - same condition for NO QUOTE is true; also true: currently
#                parsing the delimiter $TFACTLBASE_SPACE before tokens, or 
#                arguments.
#
#   State transition diagram:
#
#    Input -> 
#   ----------------------------------------------------
#   |State    | quote    | space    | other    | NULL  |
#   |---------+----------+----------+----------+-------|
#   |NO QUOTE | IN QUOTE | SPACES*  | NO QUOTE | DONE* |
#   |---------+---------------------+----------+-------|
#   |IN QUOTE | NO QUOTE | IN QUOTE | IN QUOTE | ERR   |
#   |---------+----------+----------+----------+-------|
#   |SPACES   | IN QUOTE | SPACES   | NO QUOTE | DONE* |
#   |--------------------------------------------------|
#
#   * In these cases, $token must have one complete argument, so add $token
#     to the output parameter array.
########
sub tfactlbase_parse_int_cmd_line
{
  my ($cmd_line, $argv_ref) = @_;

  my ($char);                                # One character from $cmd_line. #
  my ($state) = 'NO QUOTE';
  my ($token) = '';                           # One argument from $cmd_line. #
  my ($offset);       # Offset to interate through $cmd_line using substr(). #
  my (@eargs);                                   # Array of error arguments. #

  # Iterate through $cmd_line character by character using substr().
  for ($offset = 0; $offset < length($cmd_line); $offset++) 
  {
    $char = substr ($cmd_line, $offset, 1);

    if ($state eq 'NO QUOTE')
    {
      if ($char eq "'")
      {
        $state = 'IN QUOTE';
      }
      elsif ($char eq $TFACTLBASE_SPACE)
      {
        $state = 'SPACES';
        push (@{ $argv_ref }, $token);
        $token = '';
      }
      else
      {                # $char is any non-space, non-single quote character. #
        $token .= $char;
      }
    }
    elsif ($state eq 'IN QUOTE')
    {
      if ($char eq "'")
      {
        $state = 'NO QUOTE';
      }
      else
      {                           # $char is any non-single quote character. #
        $token .= $char;
      }
    }
    elsif ($state eq 'SPACES')
    {
      if ($char eq "'")
      {
        $state = 'IN QUOTE';
      }
      elsif ($char ne $TFACTLBASE_SPACE)
      {                                  # $char is any non-space character. #
        $token .= $char;
        $state = 'NO QUOTE';
      }
      else
      {                                             # $char must be a space. #
        # Multiplie consecutive spaces encountered; do nothing.
      }
    }
    else
    {
      # Should never get here.  Signal internal error.
      @eargs = ("tfactlbase_parse_int_cmd_line_05");
      tfactlshare_signal_exception (8202, \@eargs);
    }
  }

  push (@{ $argv_ref }, $token);

  if ($state eq 'IN QUOTE')
  {             # Error: somebody forgot to close the quote; parsing failed. #
    return -1;
  }

  return 0;
}
##############################################################################





############################# Error Routines #################################
########
# NAME
#   tfactlbase_syntax_error
#
# DESCRIPTION
#   This routine prints the correct syntax for a command to STDERR, used 
#   when there is a syntax error.  If the command with bad syntax is tfactl 
#   itself, then tfactlbase_syntax_error lso calls exit() to quit out.
#
# PARAMETERS
#   cmd   (IN) - user-entered command name string.
#
# RETURNS
#   1 if the command belongs to this module; 0 if command not found.
#
# NOTES
#   These errors are user-errors and not internal errors.  They are of type
#   record, not signal.  Thus, even if exit() is called, the exit value is
#   zero.
########
sub tfactlbase_syntax_error 
{
  my ($cmd) = shift;
  my ($cmd_syntax);                               # Correct syntax for $cmd. #
  my ($cmd_print_name) = '';
  my ($succ) = 0;

  #display syntax only for commands in this module.
  if (tfactlbase_is_cmd($cmd))
  {
    tfactlshare_get_help_syntax($cmd);    # Get syntax for $cmd. #
    $succ = 1;

    if ($tfactlglobal_hash{'mode'} eq 'n')
    {
      $tfactlglobal_hash{'e'} = -1;
    }
  }

  return $succ;
}


########################## Initialization Routines ###########################

########
# NAME
#   tfactlbase_init_global
#
# DESCRIPTION
#   This routine initializes the global variables in the hash 
#   %tfactlglobal_hash.
#
# PARAMETERS
#   dbh   (IN) - initialized database handle, must be non-null.
#
# RETURNS
#   Null.
#
# NOTES
#   
########
sub tfactlbase_init_global 
{
}


############################## Help Routines #################################
########
# NAME
#   tfactlbase_get_tfactl_cmds
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
########
sub tfactlbase_get_tfactl_cmds 
{
  return tfactlshare_filter_invisible_cmds(%tfactlbase_cmds);
}

##############################################################################
1;
