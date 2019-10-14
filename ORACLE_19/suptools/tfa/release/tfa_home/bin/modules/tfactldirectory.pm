# 
# $Header: tfa/src/v2/tfa_home/bin/modules/tfactldirectory.pm /main/16 2018/07/17 09:48:56 manuegar Exp $
#
# tfactldirectory.pm
# 
# Copyright (c) 2014, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactldirectory.pm 
#
#    DESCRIPTION
#      Directory commands
#
#    NOTES
#
#    MODIFIED   (MM/DD/YY)
#    manuegar    07/13/18 - manuegar_multibug_01.
#    cnagur      04/07/17 - Removed Error Message 103 - Bug 24971982
#    bibsahoo    10/14/16 - Removing variable CURRENT_USER
#    amchaura    05/03/16 - Fix Bug 19191407 - LNX64-12.1-TFA:COULD NOT REMOVE
#                           DEFAULT DIR OF REMOTE NODE
#    manuegar    04/15/16 - Dynamic help.
#    amchaura    04/06/16 - replace checkTFAMain with isTFARunning to check for
#                           TFA process
#    arupadhy    12/08/15 - Conditional execution of exec in begin block for
#                           windows, due to command difference of env - linux
#                           and set - windows
#    bibsahoo    08/25/15 - Adding Global Error Code 103
#    gadiga      03/24/15 - fix return issue
#    manuegar    03/21/15 - Bug 20749932 - SYNTAX ERROR AT .../TFACTLDIRECTORY.PM WHEN EXECUTING TFACTL
#    cnagur      03/10/15 - Fix for Bug 18814422
#    manuegar    07/25/14 - Creation
#
############################ Functions List #################################
#
# removeDirectory
# removeSubDirectories
# changeDirectoryPermission
#
#############################################################################
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

package tfactldirectory;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(tfactldirectory_init
                 );

use strict;
use File::Basename;
use File::Spec::Functions;
use File::Path;
use Getopt::Long; # qw(:config no_auto_abbrev);
Getopt::Long::Configure("prefix_pattern=(-|--)");
use Pod::Usage;

use tfactlglobal;
use tfactlshare;

#################### tfactldirectory Global Constants ####################

my (%tfactldirectory_cmds) = (  change           => {},
                                directory        => {},
                         );


#################### tfactldirectory Global Variables ####################

sub is_tfactl
{
  return 1;
}


########
# NAME
#   tfactldirectory_init
#
# DESCRIPTION
#   This function initializes the tfactldirectory module.  For now it 
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
  push (@tfactlglobal_command_callbacks, \&tfactldirectory_process_cmd);
  push (@tfactlglobal_help_callbacks, \&tfactldirectory_process_help);
  push (@tfactlglobal_command_list_callbacks, \&tfactldirectory_get_tfactl_cmds);
  push (@tfactlglobal_is_command_callbacks, \&tfactldirectory_is_cmd);
  push (@tfactlglobal_is_wildcard_callbacks, \&tfactldirectory_is_wildcard_cmd);
  push (@tfactlglobal_syntax_error_callbacks, \&tfactldirectory_syntax_error);
  push (@tfactlglobal_no_instance_callbacks, \&tfactldirectory_is_no_instance_cmd);
  %tfactlglobal_cmds = (%tfactlglobal_cmds, %tfactldirectory_cmds);

  #Perform TFACTL consistency check if enabled
  if($tfactlglobal_hash{'consistchk'} eq 'y')
  {
     if(!tfactlshare_check_option_consistency(%tfactldirectory_cmds))
     {   
       exit 1;
     }
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactldirectory init", 'y', 'n');

}

########
# NAME
#   tfactldirectory_process_cmd
#
# DESCRIPTION
#   This routine calls the appropriate routine to process the command 
#   specified by $tfactlglobal_hash{'cmd'}.
#
# PARAMETERS
#   dbh       (IN) - initialized database handle, must be non-null.
#
# RETURNS
#   1 if command is found in the tfactldirectory module; 0 if not.
#
# NOTES
#   Only tfactl_shell() calls this routine.
########
sub tfactldirectory_process_cmd 
{
  my ($retval) = 0;
  my ($succ)   = 0;

  # Get current command from global value, which is set by 
  # tfactldirectory_parse_tfactl_args()and by tfactl_shell().
  my ($cmd) = $tfactlglobal_hash{'cmd'};

  # Declare and initialize hash of function pointers, each designating a 
  # routine that processes an tfactldirectory command.
  my (%cmdhash) = ( change            => \&tfactldirectory_process_command,
                    directory         => \&tfactldirectory_process_command, 
                  );

  if (defined ( $cmdhash{ $cmd } ))
  {    # If user specifies a known command, then call routine to process it. #
    $retval = $cmdhash{ $cmd }->();
    $succ = 1;
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactldirectory tfactldirectory_process_cmd", 'y', 'n');

  return ($succ, $retval);
}

########
# NAME
#   tfactldirectory_process_command
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
#   Only tfactldirectory_process_cmd() calls this function.
########
sub tfactldirectory_process_command
{
  my $retval = 0;

  tfactlshare_trace(3, "tfactl (PID = $$) tfactldirectory tfactldirectory_process_command", 'y', 'n');
  @ARGV = @tfactlglobal_argv;
  # Read th commands
  my $command1 = shift(@ARGV);
  my $command2 = shift(@ARGV);
  my $switch_val = $command1;

  if ($switch_val eq "change" )
        {
          if ($command2 eq "directory") {
                my $command3 = shift(@ARGV);
                my $command4 = shift(@ARGV);
                if ($command3 eq "-private" || $command3 eq "-public") {
                  $PERMISSION = $command3;
                  if ($command4) {
                        $CHANGEDIR = $command4;
                  }
                  else {
                        print_help("change","");
			return;
                  }
                }
                else {
                  $CHANGEDIR = $command3;
                  if ($command4) {
                        $PERMISSION = $command4;
                  }
                  else {
                      	print_help("change","");
			return;
                  }
                }
          }
          else {
            print_help("change", ""); 
	    return;
          }
          if (!($PERMISSION eq "-private" || $PERMISSION eq "-public")) {
                print_help("change", "Permission should be either private or public") if defined($command2) && ($command2 ne "-h") && ($command2 ne "-help");
          }
        }
  elsif ($switch_val eq "directory" )
        {
          print_help ("directory", "") if ( ! $command2 );
          if (defined $command2 && ($command2 eq "-h" || $command2 eq "-help")) {
                print_help("directory");
		return;
          }
          $switch_val = $command2; {
            if ($switch_val eq "add")
                {
                  $ADDDIR = shift(@ARGV);
                  if ( ! $ADDDIR ) {
                    #print_help("directory", "Directory name is missing from input");
                    print_help("directory","add");
		    return;
                  }

                  if ( defined($ADDDIR) && ( $ADDDIR eq "-h" || $ADDDIR eq "-help" ) ) {
                    #print_help("directory","");
                    print_help("directory","add");
		    return;
                  }

                  my $command3 = shift(@ARGV);
                  my $command4 = shift(@ARGV);
                  my $command5 = shift(@ARGV);
                  my $command6 = shift(@ARGV);
                  $node_list = "";

                  if ( defined($command3) && ($command3 eq "-h" || $command3 eq "-help" ) ) {
                    #print_help("directory","");
                    print_help("directory","add");
		    return;
                  }
                  if ( defined($command4) && ($command4 eq "-h" || $command4 eq "-help" ) ) {
                    #print_help("directory","");
                    print_help("directory","add");
		    return;
                  }

                  if ( defined($command3) && !($command3 eq "-public" || $command3 eq "-noexclusions" || $command3 eq "-exclusions" || $command3 eq "-collectall" || $command3 eq "-node") ) {
                    #print_help("directory", "Invalid flag: $command3");
                    print_help("directory","add");
		    return;
                  }
                  if ( defined($command3) && $command3 eq "-node") {
                      if( !defined($command4) ) {
                        #print_help("directory", "Please specify node list");
                        print_help("directory","add");
			return;
                      }
                      $node_list = $command4;
                  }
                  if ( defined($command4) && $command4 eq "-node") {
                       if( !defined($command5) ) {
                         #print_help("directory", "Please specify node list");
                         print_help("directory","add");
			 return;
                       }
                      $node_list = $command5;
                  }
                  if ( defined($command5) && $command5 eq "-node") {
                       if(!defined($command6) ) {
                          #print_help("directory", "Please specify node list");
                          print_help("directory","add");
			  return;
                       }
                       $node_list = $command6;
                  }

                  if (defined($command3) && ($command3 eq "-public")) {
                        if ( defined($command4) && !($command4 eq "-noexclusions" || $command4 eq "-exclusions" || $command4 eq "-collectall" || $command4 eq "-node") ) {
                                #print_help("directory", "Invalid flag: $command4");
                                print_help("directory","add");
				return;
                        }
                        $private_directory = 0;
                  }
                  elsif (defined($command4) && ($command4 eq "-public")) {
                        if ( defined($command5) && !($command5 eq "-node") ) {
                                print_help("directory", "Invalid flag: $command5");
				return;
                        }
                        $private_directory = 0;
                  }
                  elsif (defined($command5) && ($command5 eq "-public")) {
                        if ( defined($command6) && !($command6 eq "-noexclusions" || $command6 eq "-exclusions" || $command6 eq "-collectall") ) {
                                #print_help("directory", "Invalid flag: $command6");
                                print_help("directory","add");
				return;
                        }
                        $private_directory = 0;
                  }
                  elsif (defined($command6) && ($command6 eq "-public")) {
                        $private_directory = 0;
                  }

                  if (defined($command3) && ($command3 eq "-collectall")) {
                        $collect_all = 1;
                        if (defined($command4) && ($command4 eq "-exclusions" || $command4 eq "-noexclusions")) {
                            print "Please specify one of these < -exclusions | -noexclusions | -collectall >\n";
                            return;
                        }
                         if ( defined($command4) && !($command4 eq "-public" || $command4 eq "-node") ) {
                                #print_help("directory", "Invalid flag: $command4");
                                print_help("directory","add");
				return;
                        }

                  }
                  elsif (defined($command4) && ($command4 eq "-collectall")) {
                         if ( defined($command5) && !($command5 eq "-node") ) {
                                #print_help("directory", "Invalid flag: $command5");
                                print_help("directory","add");
				return;
                        }
                        $collect_all = 1;
                  }
                  elsif (defined($command5) && ($command5 eq "-collectall")) {
                         if ( defined($command6) && !($command6 eq "-public") ) {
                                #print_help("directory", "Invalid flag: $command4");
                                print_help("directory","add");
				return;
                        }
                        $collect_all = 1;
                  }
                   elsif (defined($command6) && ($command6 eq "-collectall")) {
                        $collect_all = 1;
                  }

                  if (defined($command3) && ($command3 eq "-exclusions" || $command3 eq "-noexclusions")) {
                        $EXCLUSION = $command3;
                        if (defined($command4) && ($command4 eq "-collectall")) {
                            print "Please specify one of these < -exclusions | -noexclusions | -collectall >\n";
                            return;
                        }
                        if ( defined($command4) && !($command4 eq "-public" || $command4 eq "-node") ) {
                                #print_help("directory", "Invalid flag: $command4");
                                print_help("directory","add");
				return;
                        }
                  }
                  elsif (defined($command4) && ($command4 eq "-exclusions" || $command4 eq "-noexclusions")) {
                        $EXCLUSION = $command4;
                         if ( defined($command5) && !($command5 eq "-node") ) {
                                #print_help("directory", "Invalid flag: $command5");
                                print_help("directory","add");
				return;
                        }
                  }
                  elsif (defined($command5) && ($command5 eq "-exclusions" || $command5 eq "-noexclusions")) {
                        $EXCLUSION = $command5;
                         if ( defined($command6) && !($command6 eq "-public") ) {
                                #print_help("directory", "Invalid flag: $command6");
                                print_help("directory","add");
				return;
                        }
                  }
                  elsif (defined($command6) && ($command6 eq "-exclusions" || $command6 eq "-noexclusions")) {
                        $EXCLUSION = $command6;
                  }
                  #print "$private_directory $EXCLUSION\n";
                }
            elsif ($switch_val eq "remove" )
                {
                  $RMDIR = shift(@ARGV);
                  if ( ! $RMDIR ) {
                    # print_help("directory", "Directory name is missing from input");
                    print_help("directory", "remove");
		    return;
                  }
                  if ($RMDIR eq "-h" || $RMDIR eq "-help") {
                        print_help("directory", "remove");
			return;
                  }
                  $node_list = "";
                  for (my $c=0; $c<scalar(@ARGV); $c++) {
                      my $arg = @ARGV[$c];
                      $arg = trim($arg);
                      if ($arg eq "-node") {
                        $node_list =  @ARGV[$c+1];
                        if (defined $node_list) {
                          $node_list = trim($node_list);
                        } else {
                          # print_help("directory", "Node name is missing from input");
			  print_help("directory", "remove");
			  return;
			}
                      }
                   }
                   @ARGV=[];
                   shift(@ARGV);
                }
            elsif ($switch_val eq "modify" )
                {
                  $node_list = "";
                  for (my $c=0; $c<scalar(@ARGV); $c++) {
                      my $arg = @ARGV[$c];
                      $arg = trim($arg);
                      if ($arg eq "-node") {
                        if(scalar(@ARGV)>=($c+1)){
                          $node_list =  @ARGV[$c+1];  
                          if (defined $node_list) {
                            $node_list = trim($node_list);
                          }  
                        }else{
                          print_help("directory", "modify");
                          return;
                        }
                      }
                   }

                  my $command3 = shift(@ARGV);
                  my $command4 = shift(@ARGV);
                  my $command5 = shift(@ARGV);
                  my $command6 = shift(@ARGV);

                  print_help("directory","modify") if ( ! $command3 );

                  if ( defined($command3) && ($command3 eq "-h" || $command3 eq "-help") ) {
                        print_help("directory","modify");
			return;
                  }

                  if ( defined($command4) && ($command4 eq "-h" || $command4 eq "-help") ) {
                        print_help("directory","modify");
			return;
                  }

                  if ( defined($command5) && ($command5 eq "-h" || $command5 eq "-help") ) {
                        print_help("directory","modify");
			return;
                  }

                  print_help("directory","modify") if ( ! $command4 );

                  if ( $command3 eq "-private" || $command3 eq "-public" || $command3 eq "-noexclusions" || $command3 eq "-
exclusions" || $command3 eq "-collectall" || $command3 eq "-node") {
                    print_help("directory", "modify");
		    return;
                  }

                  if ( $command4 eq "-private" || $command4 eq "-public" ) {
                    if (defined($command5) && !($command5 eq "-exclusions" || $command5 eq "-noexclusions" || $command5 eq "-collectall"|| $command5 eq "-node")) {
                        print_help("directory", "modify");
			return;
                    }
                    if (defined($command5) && ($command5 eq "-exclusions" || $command5 eq "-noexclusions")) {
                        $EXCLUSION = $command5;
                    }
                    if (defined($command5) && $command5 eq "-collectall") {
                      if ( defined($command6) && !($command6 eq "-node") ) {
                                #print_help("directory", "Invalid flag: $command5");
                                print_help("directory","modify");
        return;
                        }
                        $collect_all = 1;
                    }
                    $CHANGEDIR = $command3;
                    $PERMISSION = $command4;
                  }
                  elsif ( defined ($command5) && ($command5 eq "-private" || $command5 eq "-public") ) {
                    $CHANGEDIR = $command3;
                    $PERMISSION = $command5;
                  }

                  if ( $command4 eq "-noexclusions" || $command4 eq "-exclusions" ) {
                    if (defined($command5) && !($command5 eq "-private" || $command5 eq "-public"|| $command5 eq "-node")) {
                        print_help("directory", "modify");
			return;
                    }
                    if (defined($command5) && ($command5 eq "-private" || $command5 eq "-public")) {
                        $PERMISSION = $command5;
                    }
                    $CHANGEDIR = $command3;
                    $EXCLUSION = $command4;
                  }
                  elsif ( defined($command5) && ($command5 eq "-noexclusions" || $command5 eq "-exclusions") ) {
                    $CHANGEDIR = $command3;
                    $EXCLUSION = $command5;
                  }

                  if ( $command4 eq "-collectall" ) {
                    if (defined($command5) && !($command5 eq "-private" || $command5 eq "-public" || $command5 eq "-node")) {
                        print_help("directory", "modify");
			return;
                    }
                    if (defined($command5) && ($command5 eq "-private" || $command5 eq "-public"))  {
                        $PERMISSION = $command5;
                    }
                    $CHANGEDIR = $command3;
                    $collect_all = 1;
                  }
                  if (!defined $CHANGEDIR && !defined $PERMISSION && !defined $EXCLUSION && ($collect_all == 0)) {
                    print_help("directory","modify");
		    return;
                  }
                }
                #print_help ("directory", "Invalid argument $command2")
                else { print_help ("directory", "modify") if defined($command2) && ($command2 ne "-h") && ($command2 ne "-help"); }
          }
        }

  # Dispatch the command
  tfactlshare_pre_dispatch();
  $retval = tfactldirectory_dispatch();

  return $retval;
}

########
# NAME
#   tfactldirectory_dispatch
#
# DESCRIPTION
#   Dispatch de command.
#
# PARAMETERS
#
# RETURNS
#
########
sub tfactldirectory_dispatch
{
 my $retval = 0;

 if ($CHANGEDIR && ($PERMISSION || $EXCLUSION || $collect_all)) { 
   $retval = changeDirectoryPermission($tfa_home, $CHANGEDIR, $PERMISSION, $EXCLUSION, $collect_all, $node_list);
   undef($CHANGEDIR); undef($PERMISSION); undef($EXCLUSION); $collect_all = 0;  }
 #elsif ($ADDDIR) { $retval = addDirectory($tfa_home, $ADDDIR, $DBNAME, $INSTANCE_NAME); }
 elsif ($ADDDIR) { $retval = addDirectory($tfa_home, $ADDDIR, $private_directory, $EXCLUSION, 
                                $collect_all, $node_list); undef($ADDDIR); }
 elsif ($RMDIR) { $retval = removeDirectory($tfa_home, $RMDIR, $node_list); undef($RMDIR); }

 return $retval;
}


########
# NAME
#   tfactldirectory_process_help
#
# DESCRIPTION
#   This function is the help function for the tfactldirectory module.
#
# PARAMETERS
#   command     (IN) - display the help message for this command.
#
# RETURNS
#   1 if command found; 0 otherwise.
########
sub tfactldirectory_process_help 
{
  my ($command) = shift;       # User-specified argument; show help on $cmd. #

  my ($desc);                                # Command description for $cmd. #
  my ($succ) = 0;                         # 1 if command found, 0 otherwise. #

  if (tfactldirectory_is_cmd ($command)) 
  {                              # User specified a command name to look up. #
    $desc = tfactlshare_get_help_desc($command);
    tfactlshare_print "$desc\n";
    $succ = 1;
  }

  return $succ;
}

########
# NAME
#   tfactldirectory_is_cmd
#
# DESCRIPTION
#   This routine checks if a user-entered command is one of the known
#   TFACTL internal commands that belong to the tfactldirectory module.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is one of the known commands, false otherwise.
########
sub tfactldirectory_is_cmd 
{
  my ($arg) = shift;

  return defined ($tfactldirectory_cmds {$arg});

}

########
# NAME
#   tfactldirectory_is_wildcard_cmd
#
# DESCRIPTION
#   This routine determines if an tfactldirectory command allows the use 
#   of wild cards.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is a command that can take wildcards as part of its argument, 
#   false otherwise.
########
sub tfactldirectory_is_wildcard_cmd 
{
  my ($arg) = shift;

  return defined ($tfactldirectory_cmds{ $arg }) &&
    (tfactlshare_get_cmd_wildcard($arg) eq "True" ) ;
}

########
# NAME
#   tfactldirectory_is_no_instance_cmd
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
#   The tfactldirectory module currently supports no command that can run 
#   without an TFAMain instance.
########
sub tfactldirectory_is_no_instance_cmd 
{
  my ($arg) = shift;

  return !defined ($tfactldirectory_cmds{ $arg }) ||
    (tfactlshare_get_cmd_noinst($arg) ne "True" ) ;
}

########
# NAME
#   tfactldirectory_syntax_error
#
# DESCRIPTION
#   This function prints the correct syntax for a command to STDERR, used 
#   when there is a syntax error.  This function is responsible for 
#   only tfactldirectory commands.
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
sub tfactldirectory_syntax_error 
{
  my ($cmd) = shift;
  my ($cmd_syntax);                               # Correct syntax for $cmd. #
  my ($succ) = 0;


  #display syntax only for commands in this module.
  if (tfactldirectory_is_cmd($cmd))
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
#   tfactldirectory_get_tfactl_cmds
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
sub tfactldirectory_get_tfactl_cmds 
{
  return tfactlshare_filter_invisible_cmds(%tfactldirectory_cmds);
}

#
#==== removeDirectory  ====#
#
sub removeDirectory
{
  my ($tfa_home, $directory, $nodelist) = @_; 
  if (isTFARunning($tfa_home) == FAILED) {
        exit 0;
  }
  dbg(DBG_WHAT, "In removeDirectory for :: $directory\n");
    if ( -d $directory ) {
      dbg(DBG_VERB, "$directory directory exists.\n");
    }
    elsif ( -e $directory ) {
      print "$directory is a file. Enter a valid directory location.\n";
      return FAILED;
    }
    # checking validity of nodes
    $nodelist =~ tr/A-Z/a-z/;
    my @nodelist = split(/\,/,$nodelist);
    my $nodename;
    foreach $nodename (@nodelist) {
        if (isNodePartOfCluster($tfa_home, $nodename) || (lc($nodelist) eq "all")) {
        }
        else {
             print "Node $nodename is not part of TFA cluster\n";
             exit 0;
        }
    }
    #else {
    #  print "$directory does not exist. Failed to remove directory from TFA.\n";
    #  return FAILED;
    #}
# check if current user is root or owner of the directory. If yes, proceed to remove. Else, don't allow.
my $sudo_user = $ENV{SUDO_USER};
my $sudo_uid = $ENV{SUDO_UID};
my $sudo_gid = $ENV{SUDO_GID};
my $sudo_command = $ENV{SUDO_COMMAND};

if ( $sudo_user && $sudo_command =~ /tfactl/ ) {
        print "Running as sudo user : $sudo_user\n";
        print "Checking if '$sudo_user' is the owner of $directory...\n";

#        my $owner_uid = (stat($directory))[4];
#        my $owner_gid = (stat($directory))[5];
#       if ($sudo_uid == $owner_uid) {
#       }

        my $dirowner = getFileOwner( $directory );

        if ( $dirowner ne $sudo_user ) {
          print "User '$sudo_user' does not have the permission to remove $directory from TFA.\n";
          #print "Only $owner_uid has the permission to remove $directory from TFA.\n";
          print "Failed to remove $directory from TFA\n";
          return FAILED;
        }
} elsif ( $current_user ne "root" ) {

        my $dirowner = getFileOwner( $directory );

        if ( $dirowner ne $current_user ) {
                print "User '$current_user' does not have the permission to remove $directory from TFA.\n";
                print "Failed to remove $directory from TFA\n";
                return FAILED;
        }
}

my $localhost=tolower_host();
my $actionmessage = "$localhost:removedirectory:$directory:$nodelist\n";

dbg(DBG_WHAT, "Running remove Directory through Java CLI\n");
my $command = buildCLIJava($tfa_home,$actionmessage);
dbg(DBG_WHAT, "$command\n");
my $line;
my @cli_output = tfactlshare_runClient($command);
foreach $line ( @cli_output )
{
if ($line =~ /FAILED : Subdirectories found in TFA/) {
   print "Do you wish to continue ? [Y/y/N/n] [Y] ";
   chomp( my $removesubdirs = <STDIN> );
   $removesubdirs ||= 'Y';
   $removesubdirs = get_valid_input ($removesubdirs, "Y|y|N|n", "Y");
   if ($removesubdirs =~ /[Yy]/) {
        removeSubDirectories($tfa_home, $directory,$nodelist);
        #printLocalDirectories($tfa_home);
        return SUCCESS;
   }
   else {
        print "No directories were removed from TFA\n";
        #printLocalDirectories($tfa_home);
   }
}
elsif ($line =~ /FAILED : Directory not found in TFA/) {
  print "Directory not found in TFA: $directory\n";
  print "No directories were removed from TFA\n";
  #printLocalDirectories($tfa_home);
}
elsif ( $line eq "SUCCESS") {
    print "Successfully removed trace directory: $directory\n\n";
    #printLocalDirectories($tfa_home);
    dbg(DBG_WHAT,"#### Removed Directory ####\n");
    return SUCCESS;
}
else {
  print "$line\n";
}
#elsif ( $line =~ /Directory not found in database/ ) {
#    print "Directory not found in TFA: $directory\n";
#    print "Failed to remove trace directory\n\n";
#    printLocalDirectories($tfa_home);
#}
}
dbg(DBG_WHAT,"Could not remove directory\n");
return FAILED;
}

sub removeSubDirectories
{
  my ($tfa_home, $directory, $nodelist) = @_;
  my $localhost = tolower_host();
  my $actionmessage = "$localhost:removesubdirectories:$directory:$nodelist\n";

  dbg(DBG_WHAT, "Removing subdirectories through Java CLI\n");
  my $command = buildCLIJava($tfa_home, $actionmessage);
  dbg(DBG_WHAT, "$command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
    if ($line eq "DONE") {
        dbg(DBG_WHAT, "Successfully removed sub-directories from TFA.\n");
	print "Successfully removed directories from TFA\n";
        return SUCCESS;
    }
    else {
      print "$line\n";
    }
  }
  dbg(DBG_WHAT, "Could not remove subdirectories\n");
  return FAILED;
}

sub changeDirectoryPermission
{
  my ($tfa_home, $directory, $permission, $exclusion, $collect_all, $nodelist) = @_;
  if (isTFARunning($tfa_home) == FAILED) {
        exit 0;
  }
    if ( -d $directory ) {
      dbg(DBG_VERB, "$directory directory exists.\n");
    }
    elsif ( -e $directory ) {
      print "$directory is a file. Enter a valid directory location.\n";
      return FAILED;
    }
    else {
      print "$directory does not exist. Failed to modify directory permission in TFA.\n";
      return FAILED;
    }
  my $sudo_user = $ENV{SUDO_USER};
  my $sudo_uid = $ENV{SUDO_UID};
  my $sudo_gid = $ENV{SUDO_GID};
  my $sudo_command = $ENV{SUDO_COMMAND};

  if ( $sudo_user && $sudo_command =~ /tfactl/ ) {
        print "Running as sudo user : $sudo_user\n";
        print "Checking if '$sudo_user' has permission to modify directory permission of $directory...\n";

#        my $owner_uid = (stat($directory))[4];
#        if ($sudo_uid == $owner_uid) {
#        }
#        else {

        my $dirowner = getFileOwner( $directory );

        if ( $dirowner ne $sudo_user ) {
                print "User '$sudo_user' does not have permission to modify directory permission of $directory.\n";
                return FAILED;
        }
  } elsif ( $current_user ne "root" ) {

        my $dirowner = getFileOwner( $directory );

        if ( $dirowner ne $current_user ) {
                print "User '$current_user' does not have permission to modify directory permission of $directory.\n";
                return FAILED;
        }
  }

  # checking validity of nodes
  $nodelist =~ tr/A-Z/a-z/;
  my @node_list = split(/\,/,$nodelist);
  my $nodename;
  foreach $nodename (@node_list) {
     if (isNodePartOfCluster($tfa_home, $nodename)|| (lc($nodelist) eq "all")) {
     }
     else {
         print "Node $nodename is not part of TFA cluster\n";
         exit 0;
     }
  }

  my $localhost=tolower_host();
  my $actionmessage = "$localhost:modifydirectorypermission:$directory:$permission:$exclusion:$collect_all:$nodelist";
  my $command = buildCLIJava($tfa_home,$actionmessage);
  dbg(DBG_WHAT, "$command\n");
  my $line;
  $permission =~ s/^-//;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
    if ($line eq "DONE") {
        print "Successfully changed permission of $directory to $permission and collection policy to $exclusion\n";
        printLocalDirectories($tfa_home);
        return SUCCESS;
    }
    elsif ($line =~ /SUCCESS. UPDATED PERMISSION/) {
        print "Successfully changed permission of $directory to $permission\n";
        printLocalDirectories($tfa_home);
        return SUCCESS;
    }
    elsif ($line =~ /SUCCESS. UPDATED COLLECTION POLICY/) {
        print "Successfully changed collection policy of $directory to $exclusion\n";
        printLocalDirectories($tfa_home);
        return SUCCESS;
    }
    elsif ($line =~ /FAILED. TRYING TO SET PERMISSION TO SAME VALUE/) {
        print "Permission of $directory in TFA is already $permission\n";
    }
    elsif ($line =~ /FAILED. TRYING TO SET PERMISSION AND COLLECTION POLICY TO SAME VALUES/) {
        print "Trying to set permission and collection policy of $directory to same values\n";
    }
    elsif ($line =~ /FAILED. TRYING TO SET COLLECTION POLICY TO SAME VALUE/) {
        print "Collection policy of $directory in TFA is already $exclusion\n";
    }
    elsif ($line =~ /FAILED. DIRECTORY DOES NOT EXIST IN TFA/) {
        print "$directory does not exist in TFA\n";
    }
    else {
      print "$line\n";
    }
  }
  return FAILED;
}


