# 
# $Header: tfa/src/v2/tfa_home/bin/modules/tfactlexttools.pm /main/10 2018/07/17 09:48:56 manuegar Exp $
#
# tfactlexttools.pm
# 
# Copyright (c) 2014, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlexttools.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     03/19/18 - Bug 27665984 - remove use of POSIX::tmpnam
#    manuegar    10/09/17 - Bug 26891075 - ERROR: CAN NOT RUN 'FINDSTR' AS USER
#                           DIRECTORIES ARE NOT YET SETUP.
#    manuegar    11/01/16 - Bug 24948477 - WS2012_122_TFA: HELP INFORMATION FOR
#                           'TFACTL RUN GREP' INCORRECT.
#    arupadhy    07/07/16 - Added alias support for supporttools framework
#    manuegar    04/26/16 - Dynamic help.
#    manuegar    12/03/14 - 20140069 - Pass all parameters to support tools
#    manuegar    11/05/14 - Implement <action> <toolname> <flags> for support
#                           tools.
#    manuegar    10/03/14 - Creation
#
############################ Functions List #################################
#
# tfactlexttools_read_ext_xml
# tfactlexttools_diff_ext_xml
# tfactlexttools_deploy_ext_all
# tfactlexttools_deploy_ext
#
#############################################################################

package tfactlexttools;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(tfactlexttools_init
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

use tfactlglobal;
use tfactlshare;

#################### tfactlexttools Global Constants ####################

my (%tfactlexttools_cmds) = (deployext      => {},
                         );
=pod
# Init tfa_ext_xml file
$tfactlglobal_tfa_ext_xml = catfile($tfa_home, "ext", "tfaext.xml");
%tfactlglobal_exttools =
               tfactlexttools_read_ext_xml($tfactlglobal_tfa_ext_xml);
=cut

 # Simulate windows
 # $IS_WINDOWS = 1;

 foreach my $tool (keys %tfactlglobal_exttools)
 {
    # Push tool as a command name
    # $tfactlexttools_cmds{$tool} = {};

    # Push aliases as command name for windows platforms
    if ( $tfactlglobal_exttools{$tool}->{ALIASES} && $IS_WINDOWS ) {
      my @aliases = split(/-/,$tfactlglobal_exttools{$tool}->{ALIASES});
      foreach my $alias (@aliases){
        # Push tool as a command name
        my $toolalias = trim($alias);
        $tfactlexttools_cmds{$toolalias} = {};
        # Make the aliases commands available to "tfactl run <alias_tool>"
        $tfactlglobal_exttools{$toolalias}->{BASENAME} = $tfactlglobal_exttools{$tool}->{BASENAME};       # tool base name
        $tfactlglobal_exttools{$toolalias}->{VERSION} = $tfactlglobal_exttools{$tool}->{VERSION};         # tool version
        $tfactlglobal_exttools{$toolalias}->{ID} = $tfactlglobal_exttools{$tool}->{ID};                   # tool buildid
        $tfactlglobal_exttools{$toolalias}->{UPDATE} = 1;                                                 # update
        $tfactlglobal_exttools{$toolalias}->{CLUSTERWIDE} = $tfactlglobal_exttools{$tool}->{CLUSTERWIDE}; # clusterwide
        $tfactlglobal_exttools{$toolalias}->{AUTOSTART} = $tfactlglobal_exttools{$tool}->{AUTOSTART};     # autostart
        $tfactlglobal_exttools{$toolalias}->{NEEDINVENTORY} = $tfactlglobal_exttools{$tool}->{NEEDINVENTORY}; # tool need inventory
        $tfactlglobal_exttools{$toolalias}->{ALIASES} = $tfactlglobal_exttools{$tool}->{ALIASES};         # tool aliases
        $tfactlglobal_exttools{$toolalias}->{PLATFORMS} = $tfactlglobal_exttools{$tool}->{PLATFORMS};     # tool platforms
        $tfactlglobal_exttools{$toolalias}->{TOOLTYPE} = $tfactlglobal_exttools{$tool}->{TOOLTYPE};       # tool Type
        # Disable the non aliased commands on windows
        delete $tfactlglobal_exttools{$tool};
      }
    } else {
      # Push tool as a command name
      $tfactlexttools_cmds{$tool} = {};
    }
 }

return 1;

#################### tfactlexttools Global Variables ####################

sub is_tfactl
{
  return 1;
}


########
# NAME
#   tfactlexttools_init
#
# DESCRIPTION
#   This function initializes the tfactlexttools module.  For now it 
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
  push (@tfactlglobal_command_callbacks, \&tfactlexttools_process_cmd);
  push (@tfactlglobal_help_callbacks, \&tfactlexttools_process_help);
  push (@tfactlglobal_command_list_callbacks, \&tfactlexttools_get_tfactl_cmds);
  push (@tfactlglobal_is_command_callbacks, \&tfactlexttools_is_cmd);
  push (@tfactlglobal_is_wildcard_callbacks, \&tfactlexttools_is_wildcard_cmd);
  push (@tfactlglobal_syntax_error_callbacks, \&tfactlexttools_syntax_error);
  push (@tfactlglobal_no_instance_callbacks, \&tfactlexttools_is_no_instance_cmd);
  %tfactlglobal_cmds = (%tfactlglobal_cmds, %tfactlexttools_cmds);

  #Perform TFACTL consistency check if enabled
  if($tfactlglobal_hash{'consistchk'} eq 'y')
  {
     if(!tfactlshare_check_option_consistency(%tfactlexttools_cmds))
     {   
       exit 1;
     }
  }

  tfactlshare_trace(3, "tfactl (PID = $$) tfactlexttools init", 'y', 'n');

}

########
# NAME
#   tfactlexttools_process_cmd
#
# DESCRIPTION
#   This routine calls the appropriate routine to process the command 
#   specified by $tfactlglobal_hash{'cmd'}.
#
# PARAMETERS
#   dbh       (IN) - initialized database handle, must be non-null.
#
# RETURNS
#   1 if command is found in the tfactlexttools module; 0 if not.
#
# NOTES
#   Only tfactl_shell() calls this routine.
########
sub tfactlexttools_process_cmd 
{
  my ($retval) = 0;
  my ($succ)   = 0;

  # Get current command from global value, which is set by 
  # tfactlexttools_parse_tfactl_args()and by tfactl_shell().
  my ($cmd) = $tfactlglobal_hash{'cmd'};

  # Declare and initialize hash of function pointers, each designating a 
  # routine that processes an tfactlexttools command.
  my (%cmdhash) = ( deployext       => \&tfactlexttools_process_command,
                  );

 foreach my $tool (keys %tfactlglobal_exttools)
 {
   # Push tool as a command name
   $cmdhash{$tool} = \&tfactlexttools_process_command;

   if ( $tfactlglobal_exttools{$tool}->{ALIASES} ) {
    my @aliases = split(/-/,$tfactlglobal_exttools{$tool}->{ALIASES});
    foreach my $alias (@aliases){
      # Push tool as a command name
      $cmdhash{trim($alias)} = \&tfactlexttools_process_command;
    }
   }

 }

  if (defined ( $cmdhash{ $cmd } ))
  {    # If user specifies a known command, then call routine to process it. #
    $retval = $cmdhash{ $cmd }->();
    $succ = 1;
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlexttools tfactlexttools_process_cmd", 'y', 'n');

  return ($succ, $retval);
}

########
# NAME
#   tfactlexttools_process_command
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
#   Only tfactlexttools_process_cmd() calls this function.
########
sub tfactlexttools_process_command
{
  my $retval = 0;

  tfactlshare_trace(3, "tfactl (PID = $$) tfactlexttools_process_command", 'y', 'n');
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlexttools_process_command " .
                    "srcmod: $tfactlglobal_hash{'srcmod'}", 'y', 'y');
  if ( $tfactlglobal_hash{'srcmod'} eq "tfactl" ) {
    unshift @tfactlglobal_argv, $tfactlglobal_argv[0];
    $tfactlglobal_argv[1] = "run"; # Default is run
  }

  # Read the commands
  @ARGV = @tfactlglobal_argv;
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlexttools_process_command " .
                    "ARGV  @ARGV", 'y', 'y');
  my $command1 = shift(@ARGV);
  my $command2 = shift(@ARGV);
  my $switch_val = tfactlexttools_get_base_tool($command1);

  if ( $tfactlglobal_hash{'srcmod'} eq "tfactladmin" ) {
    $tfactlglobal_hash{'srcmod'} = "tfactl";
  } else {
    $tfactlglobal_hash{'localcmd'} = "false";
    $tfactlglobal_hash{'srcmod'} = "tfactl";
  }

deployext:
  if ( $switch_val eq "deployext" )
  {
    if ( @ARGV && (lc($ARGV[0]) eq "-h" || lc($ARGV[0]) eq "-help") ) {
       print_help("deployext");
       last deployext;
    }

    $DEPLOYEXT = 1;
  } elsif ( exists $tfactlglobal_exttools{$switch_val}  )
  {
    if ( $command2 eq "-h" || $command2 eq "-help" ) { 
       print_help("runtool");
       last deployext;
    }

    $RUNTOOL = 1;
    $RUNTOOLCMD = $switch_val;      # e.g. orachk
    $RUNTOOLCMDMODE = $command2;    # e.g. start
  }

  # Dispatch the command
  tfactlshare_pre_dispatch();
  $retval = tfactlexttools_dispatch();

  return $retval;
}

########
# NAME
#   tfactlaccess_dispatch
#
# DESCRIPTION
#   Dispatch de command.
#
# PARAMETERS
#
# RETURNS
#
########
sub tfactlexttools_dispatch
{
 my $retval = 0;
 if ( $DEPLOYEXT ) { $retval = tfactlexttools_deploy_ext_all(); 
                     # Execute clusterwide
                     if ( $tfactlglobal_hash{'localcmd'}  eq "false" ) {
                       $retval = tfactlshare_execute_clusterwide("local deployext", "" );
                     } # end if execute clusterwide
                     $DEPLOYEXT = 0; }
 elsif ( $RUNTOOL ) { $retval = tfactlshare_manage_ext($RUNTOOLCMDMODE, $RUNTOOLCMD, 
                      $tfa_home, @ARGV);
                      $RUNTOOL = 0; undef $RUNTOOLCMD; undef $RUNTOOLCMDMODE; }
 # Back to default
 $tfactlglobal_hash{'localcmd'} = "false";

 return $retval;
}


########
# NAME
#   tfactlexttools_process_help
#
# DESCRIPTION
#   This function is the help function for the tfactlexttools module.
#
# PARAMETERS
#   command     (IN) - display the help message for this command.
#
# RETURNS
#   1 if command found; 0 otherwise.
########
sub tfactlexttools_process_help 
{
  my ($command) = shift;       # User-specified argument; show help on $cmd. #

  my ($desc);                                # Command description for $cmd. #
  my ($succ) = 0;                         # 1 if command found, 0 otherwise. #

  if (tfactlexttools_is_cmd ($command)) 
  {                              # User specified a command name to look up. #
    $desc = tfactlshare_get_help_desc($command);
    tfactlshare_print "$desc\n";
    $succ = 1;
  }

  return $succ;
}

########
# NAME
#   tfactlexttools_is_cmd
#
# DESCRIPTION
#   This routine checks if a user-entered command is one of the known
#   TFACTL internal commands that belong to the tfactlexttools module.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is one of the known commands, false otherwise.
########
sub tfactlexttools_is_cmd 
{
  my ($arg) = shift;

  return defined ($tfactlexttools_cmds {$arg});

}

########
# NAME
#   tfactlexttools_is_wildcard_cmd
#
# DESCRIPTION
#   This routine determines if an tfactlexttools command allows the use 
#   of wild cards.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is a command that can take wildcards as part of its argument, 
#   false otherwise.
########
sub tfactlexttools_is_wildcard_cmd 
{
  my ($arg) = shift;

  return defined ($tfactlexttools_cmds{ $arg }) &&
    (tfactlshare_get_cmd_wildcard($arg) eq "True" ) ;
}

########
# NAME
#   tfactlexttools_is_no_instance_cmd
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
#   The tfactlexttools module currently supports no command that can run 
#   without an TFAMain instance.
########
sub tfactlexttools_is_no_instance_cmd 
{
  my ($arg) = shift;

  return !defined ($tfactlexttools_cmds{ $arg }) ||
    (tfactlshare_get_cmd_noinst($arg) ne "True" ) ;
}

########
# NAME
#   tfactlexttools_syntax_error
#
# DESCRIPTION
#   This function prints the correct syntax for a command to STDERR, used 
#   when there is a syntax error.  This function is responsible for 
#   only tfactlexttools commands.
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
sub tfactlexttools_syntax_error 
{
  my ($cmd) = shift;
  my ($cmd_syntax);                               # Correct syntax for $cmd. #
  my ($succ) = 0;


  #display syntax only for commands in this module.
  if (tfactlexttools_is_cmd($cmd))
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
#   tfactlexttools_get_tfactl_cmds
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
sub tfactlexttools_get_tfactl_cmds 
{
  return tfactlshare_filter_invisible_cmds(%tfactlexttools_cmds);
}

sub tfactlexttools_diff_ext_xml
{
  my ($setup_loc) = shift;
  my ($tfa_home) = shift;
  my ($tfa_ext_xml) = catfile($tfa_home, "ext", "tfaext.xml");
  my ($setup_ext_xml) = catfile($setup_loc, "ext", "tfaext.xml");
  my (%tools, %newtools);
  my ($tools, $newtools);

  # Reading existsing install files if it exists
  %tools = %tfactlglobal_exttools;

  # Reading new install files
  %newtools = tfactlexttools_read_ext_xml ($setup_ext_xml);

  foreach my $tool (keys %newtools)
  {
    if ( exists $tools{$tool} )
    {
      if ( $tools{$tools}->{ID} >= $newtools{$tools}->{ID} )
      { # We already have a greater or same.. so no update required.
        $newtools{$tool}->{UPDATE} = 0;
      }
    }
  }

  # Copy the new tools

  # Deploy new tools
  tfactlexttools_deploy_ext($tfa_home, %newtools);
}

sub tfactlexttools_deploy_ext_all
{
  # Deploy them
  print "About to deploy tfactlexttools_deploy_ext_all \n";
  tfactlexttools_deploy_ext($tfa_home, \%tfactlglobal_exttools);
}

sub tfactlexttools_deploy_ext
{
  my $tfa_home = shift;
  my $toolsref = shift;

  my %tools = %{$toolsref};
  foreach my $tool (keys %tools)
  {
    my $tool_pm = catfile($tfa_home, "ext", $tool, "$tool.pm");
    print "Tool pm => $tool_pm \n";
    if ( $tools{$tool}->{UPDATE} == 1 && -e "$tool_pm" )
    {
      print "Deploying $tool in $tfa_home\n";
      tfactlshare_manage_ext("deploy", $tool, $tfa_home, $tfa_home);
    }
  }
  return;
}

########
# NAME
#   tfactlexttools_get_base_tool
#
# DESCRIPTION
#   This subroutine gets the base toolname for aliases
#
# PARAMETERS
#   cmd_tool - Name of the tool
# RETURNS
#   Returns name of the base tool
# NOTES/USAGE
#
########
sub tfactlexttools_get_base_tool{
  my $cmd_tool = shift;
  my %tools = %tfactlglobal_exttools;
  my $base_tool;
  
  foreach my $tool (keys %tools){
    my $tool_pm = catfile($tfa_home, "ext", $tool, "$tool.pm");
    if ( (-e "$tool_pm") && $tools{$tool}->{ALIASES} ) {
      my @aliases = split(/-/,$tools{$tool}->{ALIASES});
      foreach my $alias (@aliases){
        if(lc(trim($alias)) eq lc(trim($cmd_tool))){
          return $tool;
        }
      }
    }
  }
  
  return $cmd_tool;
}


