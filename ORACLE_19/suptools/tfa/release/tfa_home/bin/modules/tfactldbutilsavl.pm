# 
# $Header: tfa/src/v2/tfa_home/bin/modules/tfactldbutilsavl.pm /main/6 2018/08/09 22:22:30 recornej Exp $
#
# tfactldbutilsavl.pm
# 
# Copyright (c) 2017, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactldbutilsavl.pm 
#
#    DESCRIPTION
#      TFA DB Utilities - Availability module
#
#    NOTES
#     
#
#    MODIFIED   (MM/DD/YY)
#    recornej    08/06/18 - Change SUCCESS and FAILED values.
#    manuegar    07/13/18 - manuegar_multibug_01.
#    manuegar    07/05/18 - manuegar_dbutils14.
#    manuegar    06/20/18 - manuegar_dbutils13_handlers.
#    manuegar    05/30/18 - manuegar_shared_dbutils12.
#    manuegar    05/24/18 - manuegar_shared_dbutils11.
#    bburton     05/21/18 - Do not run for AIX, HP-UX and Windows for now
#    recornej    03/13/18 - Adding availability enable|disable
#    manuegar    03/12/18 - manuegar_shared_dbutils04.
#    recornej    02/28/18 - Fix sequence reference in arrays.
#    manuegar    02/07/18 - manuegar_shared_dbutils01.
#    manuegar    02/01/18 - manuegar_shared_dbutils01.
#    manuegar    12/05/17 - Creation
#
############################ Functions List #################################
#
# 
#############################################################################

package tfactldbutilsavl;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(tfactldbutilsavl_init
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

#################### tfactldbutilsavl Global Constants ####################

my (%tfactldbutilsavl_cmds) = (availability           => {},
                               ddusamplenow           => {},
                               ddugenjson             => {},
                              );


#################### tfactldbutilsavl Global Variables ####################

sub is_tfactl
{
  return 1;
}


########
# NAME
#   tfactldbutilsavl_init
#
# DESCRIPTION
#   This function initializes the tfactldbutilsavl module.  For now it 
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
  push (@tfactlglobal_command_callbacks, \&tfactldbutilsavl_process_cmd);
  push (@tfactlglobal_help_callbacks, \&tfactldbutilsavl_process_help);
  push (@tfactlglobal_command_list_callbacks, \&tfactldbutilsavl_get_tfactl_cmds);
  push (@tfactlglobal_is_command_callbacks, \&tfactldbutilsavl_is_cmd);
  push (@tfactlglobal_is_wildcard_callbacks, \&tfactldbutilsavl_is_wildcard_cmd);
  push (@tfactlglobal_syntax_error_callbacks, \&tfactldbutilsavl_syntax_error);
  push (@tfactlglobal_no_instance_callbacks, \&tfactldbutilsavl_is_no_instance_cmd);
  %tfactlglobal_cmds = (%tfactlglobal_cmds, %tfactldbutilsavl_cmds);

  #Perform TFACTL consistency check if enabled
  if($tfactlglobal_hash{'consistchk'} eq 'y')
  {
     if(!tfactlshare_check_option_consistency(%tfactldbutilsavl_cmds))
     {   
       exit 1;
     }
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactldbutilsavl init", 'y', 'n');

}

########
# NAME
#   tfactldbutilsavl_process_cmd
#
# DESCRIPTION
#   This routine calls the appropriate routine to process the command 
#   specified by $tfactlglobal_hash{'cmd'}.
#
# PARAMETERS
#   dbh       (IN) - initialized database handle, must be non-null.
#
# RETURNS
#   1 if command is found in the tfactldbutilsavl module; 0 if not.
#
# NOTES
#   Only tfactl_shell() calls this routine.
########
sub tfactldbutilsavl_process_cmd 
{
  my ($retval) = 0;
  my ($succ)   = 0;

  # Get current command from global value, which is set by 
  # tfactldbutilsavl_parse_tfactl_args()and by tfactl_shell().
  my ($cmd) = $tfactlglobal_hash{'cmd'};

  # Declare and initialize hash of function pointers, each designating a 
  # routine that processes an tfactldbutilsavl command.
  my (%cmdhash) = ( availability           => \&tfactldbutilsavl_process_command,
                    ddusamplenow           => \&tfactldbutilsavl_process_command,
                    ddugenjson             => \&tfactldbutilsavl_process_command,
                  );

  if (defined ( $cmdhash{ $cmd } ))
  {    # If user specifies a known command, then call routine to process it. #
    $retval = $cmdhash{ $cmd }->();
    $succ = 1;
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactldbutilsavl tfactldbutilsavl_process_cmd", 'y', 'n');

  return ($succ, $retval);
}

########
# NAME
#   tfactldbutilsavl_process_command
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
#   Only tfactldbutilsavl_process_cmd() calls this function.
########
sub tfactldbutilsavl_process_command
{
  my $retval = 0;

  tfactlshare_trace(3, "tfactl (PID = $$) tfactldbutilsavl tfactldbutilsavl_process_command", 'y', 'n');
  # Read the commands
  @ARGV = @tfactlglobal_argv;
  my $command1 = shift(@ARGV);
  my $command2 = shift(@ARGV);
  my $command3 = shift(@ARGV);
  my $command4 = shift(@ARGV);
  my $switch_val = $command1;

  if ($switch_val eq "availability" ) {
    $DBUTILSAVLCATID = $command1;
    $DBUTILSAVLCMDID = $command2;
    if ( $DBUTILSAVLCMDID ne "enable" && $DBUTILSAVLCMDID ne "disable" ) {
      $DBUTILSAVLTZONE = $command3; # shift(@ARGV);
    } else {
      push @ARGV, $command3;
    }
    $DBUTILSAVL = TRUE;
    ### print "Running Availability ..., DBUTILSAVLCATID $DBUTILSAVLCATID, DBUTILSAVLCMDID $DBUTILSAVLCMDID \n";
  } elsif ($switch_val eq "ddusamplenow" ) {
    if ( length $command2 && length $command3 && length $command4 ) {
      $DBUTILSAVLSAMPLENOW = TRUE;
      $DBUTILSAVLSAMPLENOWRESTYPE = $command2;
      $DBUTILSAVLSAMPLENOWKEYNAME = $command3;
      $DBUTILSAVLSAMPLENOWKEYVALUE = $command4;
    } else {
      print "Invalid number of arguments for ddusamplenow.\n";
      print "tfactl ddusamplenow <res_type> <keyname> <keyvalue>.\n";
      return 1;
    }
  } elsif ($switch_val eq "ddugenjson" ) {
    $DBUTILSAVLGENJSON = TRUE;
    $DBUTILSAVLGENJSONCAT = $command2;
    $DBUTILSAVLGENJSONCMD = $command3;
    ### print "Running Availability ..., DBUTILSAVLGENJSON $DBUTILSAVLGENJSON, DBUTILSAVLGENJSONCAT $DBUTILSAVLGENJSONCAT, DBUTILSAVLGENJSONCMD $DBUTILSAVLGENJSONCMD\n";
  }

  # Dispatch the command
  tfactlshare_pre_dispatch();
  $retval = tfactldbutilsavl_dispatch();

  return $retval;
}

########
# NAME
#   tfactldbutilsavl_dispatch
#
# DESCRIPTION
#   Dispatch de command.
#
# PARAMETERS
#
# RETURNS
#
########
sub tfactldbutilsavl_dispatch
{
 my $retval = 0;

 if ( $DBUTILSAVL ) {
   if ( $IS_WINDOWS || $IS_AIX || $IS_HPUX ){
        print "Feature not currently available on this platform\n";
	return 1;
   } 
   if ( $DBUTILSAVLCMDID eq "-h" or $DBUTILSAVLCMDID eq "-help" ) {
     print_help("availability");
     return 0;
   } elsif ( $DBUTILSAVLCMDID eq "enable" ||
        $DBUTILSAVLCMDID eq "disable"  ) {
     $retval = tfactldbutilsavl_enable_disable($DBUTILSAVLCMDID);
   
   } else {
     $retval = tfactldbutilsavl_genJSON($DBUTILSAVLCATID, $DBUTILSAVLCMDID);
   }
   $DBUTILSAVL = FALSE; $DBUTILSAVLCATID = ""; $DBUTILSAVLCMDID = "";
 } elsif ( $DBUTILSAVLSAMPLENOW ) {
   $retval = tfactldbutilsavl_sampleNow($DBUTILSAVLSAMPLENOWRESTYPE,$DBUTILSAVLSAMPLENOWKEYNAME, $DBUTILSAVLSAMPLENOWKEYVALUE);
   $DBUTILSAVLSAMPLENOW = FALSE;
   $DBUTILSAVLSAMPLENOWRESTYPE="";
   $DBUTILSAVLSAMPLENOWKEYNAME="";
   $DBUTILSAVLSAMPLENOWKEYVALUE = "";
 } elsif ( $DBUTILSAVLGENJSON ) {
   ### print "DBUTILSAVLGENJSONCAT $DBUTILSAVLGENJSONCAT, DBUTILSAVLGENJSONCMD $DBUTILSAVLGENJSONCMD\n"; 
   $retval = tfactldbutilsavl_genJsonNow($DBUTILSAVLGENJSONCAT,$DBUTILSAVLGENJSONCMD);
   $DBUTILSAVLGENJSON =FALSE;
   $DBUTILSAVLGENJSONCAT = "";
   $DBUTILSAVLGENJSONCMD = "";
 }

 return $retval;
}

########
# NAME
#   tfactldbutilsavl_process_help
#
# DESCRIPTION
#   This function is the help function for the tfactldbutilsavl module.
#
# PARAMETERS
#   command     (IN) - display the help message for this command.
#
# RETURNS
#   1 if command found; 0 otherwise.
########
sub tfactldbutilsavl_process_help 
{
  my ($command) = shift;       # User-specified argument; show help on $cmd. #

  my ($desc);                                # Command description for $cmd. #
  my ($succ) = 0;                         # 1 if command found, 0 otherwise. #

  if (tfactldbutilsavl_is_cmd ($command)) 
  {                              # User specified a command name to look up. #
    $desc = tfactlshare_get_help_desc($command);
    tfactlshare_print "$desc\n";
    $succ = 1;
  }

  return $succ;
}

########
# NAME
#   tfactldbutilsavl_is_cmd
#
# DESCRIPTION
#   This routine checks if a user-entered command is one of the known
#   TFACTL internal commands that belong to the tfactldbutilsavl module.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is one of the known commands, false otherwise.
########
sub tfactldbutilsavl_is_cmd 
{
  my ($arg) = shift;

  return defined ($tfactldbutilsavl_cmds {$arg});

}

########
# NAME
#   tfactldbutilsavl_is_wildcard_cmd
#
# DESCRIPTION
#   This routine determines if an tfactldbutilsavl command allows the use 
#   of wild cards.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is a command that can take wildcards as part of its argument, 
#   false otherwise.
########
sub tfactldbutilsavl_is_wildcard_cmd 
{
  my ($arg) = shift;

  return defined ($tfactldbutilsavl_cmds{ $arg }) &&
    (tfactlshare_get_cmd_wildcard($arg) eq "True" ) ;
}

########
# NAME
#   tfactldbutilsavl_is_no_instance_cmd
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
#   The tfactldbutilsavl module currently supports no command that can run 
#   without an TFAMain instance.
########
sub tfactldbutilsavl_is_no_instance_cmd 
{
  my ($arg) = shift;

  return !defined ($tfactldbutilsavl_cmds{ $arg }) ||
    (tfactlshare_get_cmd_noinst($arg) ne "True" ) ;
}

########
# NAME
#   tfactldbutilsavl_syntax_error
#
# DESCRIPTION
#   This function prints the correct syntax for a command to STDERR, used 
#   when there is a syntax error.  This function is responsible for 
#   only tfactldbutilsavl commands.
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
sub tfactldbutilsavl_syntax_error 
{
  my ($cmd) = shift;
  my ($cmd_syntax);                               # Correct syntax for $cmd. #
  my ($succ) = 0;


  #display syntax only for commands in this module.
  if (tfactldbutilsavl_is_cmd($cmd))
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
#   tfactldbutilsavl_get_tfactl_cmds
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
sub tfactldbutilsavl_get_tfactl_cmds 
{
  return tfactlshare_filter_invisible_cmds(%tfactldbutilsavl_cmds);
}

########
### NAME
###   tfactldbutilsavl_genJsonNow
###
### DESCRIPTION
###   Generate/index JSON records for the given
###   categoryid:commandid combo immediately.
###
### PARAMETERS
###   $categoryid - Category Id
###   $commandid  - Command Id
###
### RETURNS
###
### NOTES
###
##########
sub tfactldbutilsavl_genJsonNow {
  my $categoryid = shift;
  my $commandid  = shift;
  my $localhost = tolower_host();
  my $message = "$localhost:ddugenjsonnow:$categoryid $commandid";
  ### print "message $message\n";
  my $cmd  = buildCLIJava($tfa_home,$message);
  my @output = split(/\n/,`$cmd`);
  print "output array @output\n";
  if ( grep { /SUCCESS/ } @output ) {
    print "genJsonNow() signal completed successfully.\n";
  } elsif ( grep { /CANNOTINTERRUPT/ } @output ) {
    print "genJsonNow() signal failed, cannot interrupt at this time.\n";
    return 1;
  } elsif ( grep { /ALREADYRUNNING/ } @output ) {
    print "genJsonNow() signal failed, execution in progress.\n";
    return 1;
  } else {
    print "genJsonNow() signal failed.\n";
    return 1;
  }

  return 0;
}

########
### NAME
###   tfactldbutilsavl_sampleNow
###
### DESCRIPTION
###   Check DDU unavailable resources now
###
### PARAMETERS
###
### RETURNS
###
### NOTES
###
##########
sub tfactldbutilsavl_sampleNow {
  my $restype = shift;
  my $keyname = shift;
  my $keyvalue = shift;
  my $mode = shift;
  my $localhost = tolower_host();
  my $message = "$localhost:ddusamplenow:$restype $keyname $keyvalue";
  ### print "message $message\n";
  my $cmd  = buildCLIJava($tfa_home,$message);
  my @output = split(/\n/,`$cmd`);
  print "output array @output\n";
  if ( grep { /SUCCESS/ } @output ) {
    print "sampleNow() signal completed successfully.\n";
  } elsif ( grep { /CANNOTINTERRUPT/ } @output ) {
    print "sampleNow() signal failed, cannot interrupt at this time.\n";
    return 1;
  } elsif ( grep { /ALREADYRUNNING/ } @output ) {
    print "sampleNow() signal failed, execution in progress.\n";
    return 1;
  } else {
    print "sampleNow() signal failed.\n";
    return 1;
  }
  return 0;
}

########
### NAME
###   tfactldbutilsavl_genJSON
###
### DESCRIPTION
###   This routine generates the JSON file
###
### PARAMETERS
###   $categoryId - DDU category
###   $commandId  - DDu command
###
### RETURNS
###
### NOTES
###
##########
sub tfactldbutilsavl_genJSON {
  my $incategoryid = shift;
  my $incommandid = shift;
  my %json = ();
  my %seqhash = ();

  my $parent = "";
  my $mainparent = "";
  my @parents;
  my $hashref;
  my $mainhashref;

  my @refsarray;

  my %nestedarrays = ();
  my %nestedobjarr_commandid = ();
  my %nestedobjarr_parentcmd = ();
  my $nestedarrayslevel = 0;
  my @arraycnt = ();

  my $totitems = 0;
  my $ndx = 0;

  my %processedHandlers = ();

  my @piecesarray;
  my $piecesarrayref;
  my $key = $incategoryid ."|" . $incommandid;

  ### print "incategoryid $incategoryid\n";
  ### print "incommandid $incommandid\n";
  if ( not exists $tfactlglobal_tfa_dbutlcommands{$key} ) {
    print "Invalid categoryid/commandid received.\n";
    return 1;
  }
  $piecesarrayref = $tfactlglobal_tfa_dbutlcommands{$key}; 
  @piecesarray = @$piecesarrayref;
  $totitems = $#piecesarray + 1;
  my @arrayKeys= ();
  
  foreach my $refarr (@piecesarray) {
    ++$ndx;
    my @arr = @$refarr;
    my $categoryid = $arr[TFADBUTILS_CATEGORYID];
    my $parentcmd  = $arr[TFADBUTILS_PARENTCMD];
    my $commandid  = $arr[TFADBUTILS_COMMANDID]; 
    my $keyname    = $arr[TFADBUTILS_KEYNAME];
    my $content    = $arr[TFADBUTILS_CONTENT];
    my $handler    = $arr[TFADBUTILS_HANDLER];

    # Dynamic handler
    if (length $handler &&  (not exists $processedHandlers{$handler}) ) {
      my $handlersub = "tfactldbutilhandler_" . $handler;
      ### print "handlersub $handlersub \n";
      my $dynsub;
      my $dynresref;
      eval {
        $dynsub = \&$handlersub;
        $dynresref = $dynsub->();
      };
      if ( not $@ ) {
        $processedHandlers{$handler} =$dynresref ;
      }
    }

    tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                      "---------------------- begin -----------------", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                      "Processing : categoryid: $categoryid, parentcmd: $parentcmd, commandid: $commandid, " .
                      "keynanme: $keyname, content: $content.", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                      "parent: $parent, parents array: @parents", 'y', 'y');

    ### print "Processing : categoryid: $categoryid, parentcmd: $parentcmd, commandid: $commandid, " .
    ###       "keynanme: $keyname, content: $content.\n";
    ### print "parent: $parent, parents array: @parents\n";


    my $continue = TRUE;
    while ( $continue ) {
        if ( (not length $parentcmd) && ( $content eq "object" || $content eq "array" ) ) {
          #   =====================-----------------========= (match 0)

          tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                            "match 0, content = $content", 'y', 'y');
          if ( $content eq "object") {
            my %newhash = ();
            $hashref = \%newhash;
            $mainhashref = $hashref;
            tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                            "hashref $hashref", 'y', 'y');
          } elsif ( $content eq "array" ) {
            ++$nestedarrayslevel;
            my @newarray = ();
            $nestedarrays{$nestedarrayslevel} = \@newarray;
            $mainhashref = \@newarray;
          }
          $parent         = $commandid;
          $mainparent     = $parent;
          $continue       = FALSE;
        } elsif ( $parentcmd eq $parent && $content eq "value" ) {
          #       -------------------------===================== (match 1)

          tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                            "match 1, content = value", 'y', 'y');
          tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                            "hashref $hashref", 'y', 'y');

          ### $$hashref{$keyname} = $keyname . "_value";
          # Dynamic handler 
          if ( exists $processedHandlers{$handler} ) {
            my $rethashref = $processedHandlers{$handler};
            my %retHash = ();
            if ( ref($rethashref) eq "HASH") {
              %retHash = %$rethashref;
            } elsif ( ref($rethashref) eq "ARRAY") {
              #ARRAY and elements of the array are hashes
              my $ref = @{$rethashref}[0];
              %retHash = %{$ref};
            }# TODO: when the handler returns only a value,
             # not sure if this will be needed ....
            if ( exists $retHash{$keyname} ) {
              $$hashref{$keyname} = $retHash{$keyname};
            } else {
              $$hashref{$keyname} = $keyname . "_value";
            }
          } else {
            $$hashref{$keyname} = $keyname . "_value";
          }

          # update sequence
          my $ref = $$hashref{"sequence"};
          my @arr;
          @arr  = @$ref if $ref;
          push @arr, $keyname;
          $$hashref{"sequence"} = [@arr];

          $continue       = FALSE;
          ###foreach my $key ( keys %$hashref ) {
          ###    print "key mahtch 1 = $key\n";
          ###}

        } elsif ( $parentcmd eq $parent && $nestedarrayslevel >= 1 && $content eq "object" ) {
          #     --------------------------==============----===================== (match 2)

          tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                            "match 2, content = object (contentarray)", 'y', 'y');

          push @refsarray, $hashref;
          push @parents, $parent;

          my %newhash = ();
          $hashref = \%newhash;

          tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                            "hashref $hashref", 'y', 'y');

          $nestedobjarr_parentcmd{$nestedarrayslevel} = $parentcmd;
          $nestedobjarr_commandid{$nestedarrayslevel} = $commandid;

          $parent            = $commandid;
          $continue          = FALSE;

        } elsif ( $parentcmd eq $parent && 
                  ($content eq "object" || $content eq "array") ) {
          #       --==================-----==================== (match 3)

          tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                            "match 3, content = $content", 'y', 'y');

          # update sequence
          my $ref = $$hashref{"sequence"};
          my @arr;
          @arr  = @$ref if $ref;
          push @arr, $keyname;
          $$hashref{"sequence"} = [@arr];

          push @refsarray, $hashref;
          push @parents, $parent;

          if ( $content eq "object" ) {
            my %newhash = ();
            $hashref = \%newhash;
          } elsif ( $content eq "array" ) {
            ++$nestedarrayslevel;
            my @newarray = ();
            $nestedarrays{$nestedarrayslevel} = \@newarray;
          }

          tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                            "hashref $hashref", 'y', 'y');

          $parent            = $commandid;
          $continue          = FALSE;

        } elsif ( $parentcmd eq $nestedobjarr_parentcmd{$nestedarrayslevel} && 
                  $commandid eq $nestedobjarr_commandid{$nestedarrayslevel} &&
                  $nestedarrayslevel >= 1 && $content eq "objectclose") {
          #        ======================----=========================== (match 4)
          #        previous object complete, array element

          tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                            "match 4, content = $content", 'y', 'y');

          my $prevparent = $parent;
          my $prevhashref = $hashref;

          # Push object into array
          tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                            "match 4, Pushing object into array (object close), hashref $hashref", 'y', 'y');

          my $arraycntref = $nestedarrays{$nestedarrayslevel};
          push @$arraycntref, $hashref;

          tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                            "match 4, old parent $parent, old hashref $hashref", 'y', 'y');

          $parent = pop @parents;
          $hashref = pop @refsarray;

          tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                            "match 4, final parent $parent:hashref $hashref", 'y', 'y');

          $continue = FALSE;

        } elsif ( $nestedarrayslevel >= 1 && $content eq "arrayclose" ) {
          #      ========================-----========================  (match 5)
          #      previous array complete

          tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                            "match 5, content = $content", 'y', 'y');

          my $prevparent = $parent;
          my $prevhashref = $hashref;

          $parent = pop @parents;
          $hashref = pop @refsarray;

          tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                            "match 5, parent $parent, prevparent $prevparent, hashref $hashref", 'y', 'y');
          
          #Generate Array elements. We need the handler in the arrayclose tag
          #in order to get all the elements of the array.
          #First element of the array at this stage has been  already processed
          ####################################################################
          if ( exists $processedHandlers{$handler} ) {
            my $ref = $processedHandlers{$handler};
            shift(@{$ref});
            my $elem0 = @{$nestedarrays{$nestedarrayslevel}}[0];
            my @seq = @{$$elem0{"sequence"}};
            foreach my $element ( @{$ref}) {
              my @sequence = @seq;
              $$element{"sequence"} = \@sequence;
            }
            push(@{$nestedarrays{$nestedarrayslevel}}, @{$ref});
          }
          ####################################################################

          $$hashref{$prevparent} = $nestedarrays{$nestedarrayslevel};

          # reset
          undef $nestedobjarr_parentcmd{$nestedarrayslevel};
          undef $nestedobjarr_commandid{$nestedarrayslevel};
          --$nestedarrayslevel;

          $continue = FALSE;

        } elsif ( $parentcmd ne $parent ) {
          #       ===================== (match 6)
          #       previous object complete

          my $prevparent = $parent;
          my $prevhashref = $hashref;

          tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                            "match 6 - parentcmd ne parent => old parent $parent, old hashref $hashref", 'y', 'y');

          $parent = pop @parents;
          $hashref = pop @refsarray;

          tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                            "match 6, new parent $parent, hashref $hashref", 'y', 'y');

          $$hashref{$prevparent} = $prevhashref;
          last if ( $ndx >= $totitems );
        }# end if


        tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                          "====> ndx $ndx, totitems $totitems", 'y', 'y');
        tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_genJSON " .
                          "====> parents arr @parents", 'y', 'y');
    } # end if while
  } # end foreach

  my $SINGLE_LINE = FALSE;
  $$hashref{$parent} = $hashref;
  if ( ref($mainhashref) eq "HASH" ){
    $json{$mainparent} = $mainhashref;
    $json{$mainparent}->{"data_type"} = $mainparent;
  } elsif ( ref($mainhashref) eq "ARRAY" ) {
     $SINGLE_LINE = TRUE;
     foreach my $elem ( @{$mainhashref}){
       $$elem{"data_type"} = $mainparent;
     }
     $json{$mainparent} = $mainhashref;
  }

  if ( $tfactlglobal_hash{"debugmask"} & $tfactlglobal_mod_levels{"tfactldbutilsavl"} ) {
    my $ref = $json{$mainparent};
    print Dumper $ref;
  }

  my $jsontime = strftime('%m%d%Y%H%M%S',localtime);
  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  # ddu_base location
  my $ddu_base = catfile($tfa_base,"suptools","ddu");
  my $tfauser = tfactlshare_get_user();
  my $usrddu_base = catfile($ddu_base,"user_$tfauser");
  my $jsonfile = "";

  tfactlshare_check_type_base($tfa_home,"ddu");

  # Create $usrddu_base when running in non daemon mode.
  eval { tfactlshare_mkpath("$usrddu_base", "1741") if ( ! -d "$usrddu_base" );
       };    
  if ($@)
  {
    # print STDERR "Can not create path $usrddu_base \n";
    tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutlsavl " .
                      "Can not create path $usrddu_base, DIAGDIRDDU = FALSE",'y', 'y'); 
    $DIAGDIRDDU = FALSE;
  } else {
    $DIAGDIRDDU = TRUE; 
  }

  if ( not $DIAGDIRDDU ) {
    # unexpected error, TFA DDU repository directory not found
    tfactlshare_signal_exception(210, undef);
  }

  $jsonfile = catfile( $usrddu_base, "$mainparent" . "_" . $jsontime . ".json");
  print "JsonFile to generate $jsonfile\n";

  # Generate JSON file
  tfactlparser_encodeJSON($jsonfile,$json{$mainparent}, TRUE);

  return 0;
  
} # end sub tfactldbutilsavl_genJSON



########
### NAME
###   tfactldbutilsavl_enable
###
### DESCRIPTION
###   This routine enables source_types for 
###   availability scores
###
### PARAMETERS
###   $type
###   $key
###   $value
###   $list
###   $categoryid
###   $commandid
###
### RETURNS
###
### NOTES
###
##########
sub tfactldbutilsavl_enable {
  
  my $type  = shift;
  my $key   = shift;
  my $value = shift;
  my $list  = shift;
  my $categoryid = shift;
  my $commandid = shift;
  my %json = ();
  my $localhost = tolower_host();

  ###################################################
  # Set up ddu base 
  # ################################################
  my $jsontime = strftime('%m%d%Y%H%M%S',localtime);
  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  # ddu_base location
  my $ddu_base = catfile($tfa_base,"suptools","ddu");
  my $tfauser = tfactlshare_get_user();
  my $usrddu_base = catfile($ddu_base,"user_$tfauser");
  my $jsonfile = "";
  
  tfactlshare_check_type_base($tfa_home,"ddu");
  
  # Create $usrddu_base when running in non daemon mode.
  eval { tfactlshare_mkpath("$usrddu_base", "1741") if ( ! -d "$usrddu_base" );
       };    
  if ($@)
  {
     tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutlsavl " .
                      "Can not create path $usrddu_base, DIAGDIRDDU = FALSE",'y', 'y'); 
     $DIAGDIRDDU = FALSE;
  } else {
    $DIAGDIRDDU = TRUE; 
  }
  if ( not $DIAGDIRDDU ) {
    # unexpected error, TFA DDU repository directory not found
    tfactlshare_signal_exception(210, undef);
  }
  #----------------------------------------------------------

  ###########################################################
  #     Enabling a Resource
  ##########################################################
  if ( $list ) {
    my %resources = %{$list};
    my @enabled   = ( keys %resources );
    my @options = ();
    #Get all disabled resources 
    foreach my $resource (@enabled) {
     my  $catid = $resources{$resource}->{"categoryid"};
     my  $cmdid = $resources{$resource}->{"commandid"};
     my $message = "$localhost:ddudisabledlist:$catid $cmdid all";
     ### print "message $message\n";
     my $cmd  = buildCLIJava($tfa_home,$message);
     my @output = split /\n/,`$cmd`;
     if ( grep { /SUCCESS/ } @output ) {
       @output = grep { $_ ne "SUCCESS" } @output;
       foreach my $line ( @output ){
         my ( $catid, $cmdid, $type, $value ) = split ",",$line;
         my @option = [ $catid, $cmdid, $type, $value ];
         push @options, @option;
       }
     } 
   }
   if ( @options ) {
     my %indexes = ();
     my $input;
     my $size = scalar(@options);
     do {
       my $table = Text::ASCIITable->new({"headingText" => 'DISABLED RESOURCES'});
       $table->setCols("OPTION","SELECTED","CATEGORY","TYPE","VALUE");
       $table->setOptions({"outputWidth" => $tputcols });
       my $indx = 1;
       foreach my $op ( @options) {
         my @opt = @{$op};
         my $IS_SELECTED = exists $indexes{$indx} ? "(*)" : "( )";
         my $cat = $opt[0];
         my $cmdid = $opt[1];
         my $type = $opt[2];
         my $value = $opt[3];
         $table->addRow($indx++,$IS_SELECTED,$cmdid,$type,$value);
         #$table->addRowLine();
       }
       print $table;
       print " (*) selected\n ( ) no selected\n";
       print "\nSelect an option [ 1-$size ] | [q|Q] : ";

       $input = <STDIN>;
       chomp($input);
       if ( $input !~ /q/i ) {
         if ( $input > 0 && $input <= $size ) {
           #Update indexes 
           if ( exists $indexes{$input} ){
             delete  $indexes{$input};
           } else {
             $indexes{$input} = 1;
           }
         }
       }
     } while( $input !~ /q/i );
     if ( keys %indexes ) {
       my @jsons = ();
       foreach $key ( keys %indexes) {
         my $row = $options[$key-1];
         my @values = @{$row};
         my %json = ();
         $json{"data_type"} = "server_resource";
         $json{"hostname"} = $localhost;
         $json{"resource_data_type"} = $values[1];
         $json{"keyname"} = $values[2];
         $json{"keyvalue"} = $values[3];
         $json{"status"} = "enabled";
         $json{"sequence"}= ["data_type","hostname","resource_data_type","keyname","keyvalue","status"];
         push @jsons, \%json;
       } 
       print "Options [";
       print join(",",( sort (keys %indexes) ));
       print " ] will be enable \n";
       print "Do you want to proceed ? [Y|N] [Y] :";
       my $opt = <STDIN>;
       chomp($opt);
       $opt||= "y";
       if ( $opt =~ /y/i ) {
        my $json_name = "enable_".$jsontime.".json";
        $jsonfile = catfile($usrddu_base,$json_name);
        print "JsonFile to generate $jsonfile\n";
        
        #Generate JSON file
        tfactlparser_encodeJSON($jsonfile,\@jsons,TRUE);

        #Send this JSON for indexing 
        my $message = "$localhost:dduenable:$json_name";
        my $cmd = buildCLIJava($tfa_home,$message);
        my @output = split(/\n/,`$cmd`);
        if ( ! grep { /SUCCESS/ } @output ) {
          print "Disable operation failure : Indexing Error \n";
          return 1;
        }
      }# end if option Y
     }#end if indexes 
   }#end if options 
    
  } else {
    #Retrieve disabled resources
    my $message = "$localhost:ddudisabledlist:$categoryid $commandid $key";
    my $cmd = buildCLIJava($tfa_home,$message);
    my @output = split /\n/,`$cmd`;
    @output = map { s/.*$key\,//g;$_;} @output;#map values 
    if ( grep { /SUCCESS/ } @output ) {
      if ( grep { $_ eq $value } @output ) {
        #We can enable this value since is already disabled
        $json{"data_type"} = "server_resource";
        $json{"hostname"} = $localhost;
        $json{"resource_data_type"} = $type;
        $json{"keyname"} = $key;
        $json{"keyvalue"} = $value;
        $json{"status"} = "enabled";
        $json{"sequence"} = ["data_type","hostname","resource_data_type","keyname","keyvalue","status"];
        my $json_name = "enable_".$jsontime.".json";
        $jsonfile = catfile($usrddu_base,$json_name);
        print "JsonFile to generate $jsonfile\n";
        # Generate JSON file
        tfactlparser_encodeJSON($jsonfile,\%json,TRUE);
        
        #Send this JSON for enabling
        $message = "$localhost:dduenable:$json_name";
        $cmd = buildCLIJava($tfa_home,$message);
        @output = split /\n/ , `$cmd`;
        if ( ! grep { /SUCCESS/ } @output ) {
          print "Enable operation failure : Unable to enable resource \n";
          return 1;
        }
      } else {
        print "Enable operation failure : Value \"$value\" does not exist.\n";
        return 1;
      }#end if SUCCESS for enabling 
    } else {
      print "JAVA OPERATION FAILED\n";
      return 1;
    } #end if SUCCESS ddudisabledlist 
  }#end if list
  #-----------------------------------------------------------

  return 0;
}

########
### NAME
###   tfactldbutilsavl_disable
###
### DESCRIPTION
###   This routine disables source_types for 
###   availability scores
###
### PARAMETERS
###   $type  
###   $key
###   $value
###   $list
###   $for
###   $units
###   $categoryid
###   $commandid
###
### RETURNS
###
### NOTES
###
##########
sub tfactldbutilsavl_disable {

  my $type  = shift;
  my $key   = shift;
  my $value = shift;
  my $list  = shift;
  my $for   = shift;
  my $units = shift;
  my $categoryid = shift;
  my $commandid = shift;
  my %json = ();
  my $localhost = tolower_host();

  ###################################################
  # Set up ddu base 
  # ################################################
  my $jsontime = strftime('%m%d%Y%H%M%S',localtime);
  my $tfa_base = tfactlshare_get_repository_location($tfa_home);
  # ddu_base location
  my $ddu_base = catfile($tfa_base,"suptools","ddu");
  my $tfauser = tfactlshare_get_user();
  my $usrddu_base = catfile($ddu_base,"user_$tfauser");
  my $jsonfile = "";
  
  tfactlshare_check_type_base($tfa_home,"ddu");
  
  # Create $usrddu_base when running in non daemon mode.
  eval { tfactlshare_mkpath("$usrddu_base", "1741") if ( ! -d "$usrddu_base" );
       };    
  if ($@)
  {
    # print STDERR "Can not create path $usrddu_base \n";
     tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutlsavl " .
                      "Can not create path $usrddu_base, DIAGDIRDDU = FALSE",'y', 'y'); 
     $DIAGDIRDDU = FALSE;
  } else {
    $DIAGDIRDDU = TRUE; 
  }
  if ( not $DIAGDIRDDU ) {
    # unexpected error, TFA DDU repository directory not found
    tfactlshare_signal_exception(210, undef);
  }
  ###########################################################

  $for = $for ? $for : 7; #Default 7 days if $for is not provided 
  $units = $units ? $units : "d";
  my $now = time;
  my $expires;

  #####Convert expiration date ############
  if ($units eq "h" ) {
    $expires = $now + ( $for *3600); 
  } elsif ($units eq "m") {
    $expires = $now + ( $for * 60);
  } elsif ($units eq "d") {
    $expires = $now + ( $for*86400);
  } 
  $expires = strftime('%Y%m%d%H%M%s',localtime($expires));
  $expires = substr($expires,0,17);
  $expires += 0; 
  ###########################################
  # Disabling resource 
  ##########################################
  if ( $list ) {
    my %resources = %{$list};
    my @enabled   = ( keys %resources );
    my @options = ();
    #Get all enabled resources 
    foreach my $resource (@enabled) {
     my  $catid = $resources{$resource}->{"categoryid"};
     my  $cmdid = $resources{$resource}->{"commandid"};
     my $message = "$localhost:ddureslist:$catid $cmdid all";
     ### print "message $message\n";
     my $cmd  = buildCLIJava($tfa_home,$message);
     my @output = split /\n/,`$cmd`;
     if ( grep { /SUCCESS/ } @output ) {
       @output = grep { $_ ne "SUCCESS" } @output;
       foreach my $line ( @output ){
         my ( $catid, $cmdid, $type, $value ) = split ",",$line;
         my @option = [ $catid, $cmdid, $type, $value ];
         push @options, @option;
         ### print "retrieved options $catid, $cmdid, $type, $value  \n";
       }
     } else {
       #Unable to retrieve list 
     }
   }
   if ( @options ) {
     my %indexes = ();
     my $input;
     my $size = scalar(@options);
     do {
       my $table = Text::ASCIITable->new({"headingText" => 'ENABLED RESOURCES'});
       $table->setCols("OPTION","SELECTED","CATEGORY","TYPE","VALUE");
       $table->setOptions({"outputWidth" => $tputcols });
       my $indx = 1;
       foreach my $op ( @options) {
         my @opt = @{$op};
         my $IS_SELECTED = exists $indexes{$indx} ? "(*)" : "( )";
         my $cat = $opt[0];
         my $cmdid = $opt[1];
         my $type = $opt[2];
         my $value = $opt[3];
         $table->addRow($indx++,$IS_SELECTED,$cmdid,$type,$value);
         #$table->addRowLine();
       }
       print $table;
       print " (*) selected\n ( ) no selected\n";
       print "\nSelect an option [ 1-$size ] | [q|Q] : ";

       $input = <STDIN>;
       chomp($input);
       if ( $input !~ /q/i ) {
         if ( $input > 0 && $input <= $size ) {
           #Update indexes 
           if ( exists $indexes{$input} ){
             delete  $indexes{$input};
           } else {
             $indexes{$input} = 1;
           }
         }
       }
     } while( $input !~ /q/i );
     if ( keys %indexes ) {
       my @jsons = ();
       foreach $key ( keys %indexes) {
         my $row = $options[$key-1];
         my @values = @{$row};
         my %json = ();
         $json{"data_type"} = "server_resource";
         $json{"hostname"} = $localhost;
         $json{"resource_data_type"} = $values[1];
         $json{"keyname"} = $values[2];
         $json{"keyvalue"} = $values[3];
         $json{"for"} = $expires;
         $json{"status"} = "disabled";
         $json{"sequence"}= ["data_type","hostname","resource_data_type","keyname","keyvalue","for","status"];
         push @jsons, \%json;
       } 
       print "Options [";
       print join(",",(sort (keys %indexes) ));
       print " ] will be disable \n";
       print "Do you want to proceed ? [Y|N] [Y] :";
       my $opt = <STDIN>;
       chomp($opt);
       $opt||= "y";
       if ( $opt =~ /y/i ) {
        my $json_name = "disable_".$jsontime.".json";
        $jsonfile = catfile($usrddu_base,$json_name);
        print "JsonFile to generate $jsonfile\n";
        
        #Generate JSON file
        tfactlparser_encodeJSON($jsonfile,\@jsons,TRUE);

        #Send this JSON for indexing 
        my $message = "$localhost:ddudisable:$json_name";
        my $cmd = buildCLIJava($tfa_home,$message);
        my @output = split(/\n/,`$cmd`);
        if ( ! grep { /SUCCESS/ } @output ) {
          print "Disable operation failure : Indexing Error \n";
          return 1;
        }
      }# end if option Y
     }#end if indexes 
   }#end if options 
 } else {
    #Retrieve resources available for disabling
    my $message = "$localhost:ddureslist:$categoryid $commandid $key";
    my $cmd = buildCLIJava($tfa_home,$message);
    my @output = split /\n/, `$cmd`;
    @output = map { s/.*$key\,//g;$_;} @output;
    if ( grep { /SUCCESS/ } @output ) {
      if ( grep { $_ eq $value  } @output ) {
        #We can disable this value
        $json{"data_type"} = "server_resource";
        $json{"hostname"} = $localhost;
        $json{"resource_data_type"} = $type;
        $json{"keyname"} = $key;
        $json{"keyvalue"} = $value;
        $json{"for"} = $expires;
        $json{"status"} = "disabled";
        $json{"sequence"}= ["data_type","hostname","resource_data_type","keyname","keyvalue","for","status"];
        my $json_name = "disable_".$jsontime.".json";
        $jsonfile = catfile( $usrddu_base, $json_name);
        print "JsonFile to generate $jsonfile\n";
        
        # Generate JSON file
        tfactlparser_encodeJSON($jsonfile,\%json, TRUE);
        
        #Send this JSON for indexing 
        $message = "$localhost:ddudisable:$json_name";
        $cmd = buildCLIJava($tfa_home,$message);
        @output = split /\n/,`$cmd`;
        if ( ! grep { /SUCCESS/ } @output ){
          print "Disable operation failure : Indexing Error\n";
          return 1;
        }
      } else {
        print "Disable operation failure : Value \"$value\" does not exist.\n";
        exit(1);
      }
    } else { 
      print "JAVA OPERATION FAILED \n";
      exit(1);
    }
  } #end if list disable 
  return 0;
}

########
### NAME
###   tfactldbutilsavl_enable_disable
###
### DESCRIPTION
###   This routine check the syntax for enabling/disabling
###   a resource for availability score
###
### PARAMETERS
###   $cmd  - DDu command
###
### RETURNS
###
### NOTES
###
##########
sub tfactldbutilsavl_enable_disable {
  my $cmd = shift;
  my $type;
  my $key;
  my $value;
  my $list;
  my $for;
  my $units;
  my $commandid;
  my $categoryid;
  my $help;
  my %valid_types =  tfactlparser_parse_dbutilresources($tfactlglobal_tfa_dbutlresources);
  my $unknownopt = 0;
  tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_enable_disable " .
                            "CMD : $cmd ARGS : @ARGV", 'y', 'y');
  #Pending add rules for -for option 
  ############### PARSE CMDLINE PARAMETERS############
  #GetOptions setup 
  my @options = ( 'type=s', 'key=s','value=s','list!','for=s','help!','h!');
  my %opts = (
     'type'   => \$type,
     'key'    => \$key,
     'value'  => \$value,
     'list'   => \$list,
     'for'    => \$for,
     'help'   => \$help,
     'h'      => \$help
  );
  GetOptions ( \%opts , @options ) or $unknownopt = 1;
  if ( $unknownopt ) {
    print_help("availability");
    return 1;
  }
  if ( $help ) {
    print_help("availability",$cmd);
    return 0;
  }
  if ( @ARGV ) {
    print "Invalid Arguments passed : @ARGV \n";
    return 1;
  } elsif ( $list and ( $type or $key or $value ) ) {
    print_help ("availability" ,$cmd);
    return 1;
  } elsif (($type && (!$key || !$value)) ||
           ($key && (!$type || !$value)) ||
           ($value && (!$type || !$key))) {
    print_help("availability",$cmd); 
    return 1;
  } elsif ( $cmd eq "enable" && $for ) {
    print_help("availability",$cmd);
    return 1;
  }  elsif ( $cmd eq "disable" && $for ) {
      if ( $for =~ /^([0-9]+)(d|D|h|H|m|M)$/ ){
           $for = $1;
           $units = $2;
           $units = lc($units);
      } else { 
        print "Invalid value in -for option \n";
        return 1;
      }
  }
  if ( $list ) {
    $list = \%valid_types;
  } else {
    if (! exists $valid_types{$type}) {
      print_help("availability",$cmd);
      exit(2);
    } else { 
      #We have a valid type  retrieve commandid and categoryid;
      $commandid  = $valid_types{$type}->{"commandid"};
      $categoryid = $valid_types{$type}->{"categoryid"};
      if ( $valid_types{$type}->{"keyname"} ne $key  ) {
        print "Key \"$key\" is not a valid key for this type \n";
        print_help("availability",$cmd);
        return 1;
      }
      tfactlshare_trace(5, "tfactl (PID = $$) tfactldbutilsavl_enable_disable " .
                         "valid_type : $type  categoryid : $categoryid commandid : $commandid", 'y', 'y');
    }
  }
  if ( $cmd eq "disable" ) {
    tfactldbutilsavl_disable($type,$key,$value,$list,$for,$units,$categoryid,$commandid);
  } else {
    tfactldbutilsavl_enable($type,$key,$value,$list,$categoryid,$commandid);
  } 

  return 0;

}
