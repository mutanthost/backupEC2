# 
# $Header: tfa/src/v2/tfa_home/bin/modules/tfactlanalyze.pm /main/20 2018/08/09 22:22:30 recornej Exp $
#
# tfactlanalyze.pm
# 
# Copyright (c) 2014, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlanalyze.pm 
#
#    DESCRIPTION
#      Analyze component
#
#    NOTES
#     
#
#    MODIFIED   (MM/DD/YY)
#    recornej    07/19/18 - Fix exit codes.
#    recornej    07/17/18 - Fix returning code from runOratop
#    manuegar    07/13/18 - manuegar_multibug_01
#    migmoren    04/19/18 - Bug 27802529 - TFAT: ANALYZE -FROM ACCEPTS INVALID
#                           FORMAT DATES
#    manuegar    04/19/18 - Bug 27746546 - TFAT: DIAGCOLLECT COMMAND RETURNS
#                           EXIT CODE 0 EVEN WHEN FAILS.
#    manuegar    04/17/18 - XbranchMerge manuegar_oratopfx from
#                           st_tfa_pt-quarterly.12.2.1.2.0
#    bburton     03/19/18 - Bug 27665984 - remove use of POSIX::tmpnam
#    llakkana    02/13/18 - Use index for analysis
#    manuegar    11/10/17 - manuegar_oratopfx.
#    manuegar    09/11/17 - manuegar_bug-26619915.
#    recornej    08/17/17 - BUG 26542712 - LNX-18.1-TFA: COMMAND "TFACTL
#                           ANALYZE -EXAMPLES" DOESN'T WORK AS EXPECTED
#    bibsahoo    02/21/17 - TFA_WINDOWS_ANALYZE_OPTION
#    manuegar    11/23/16 - Bug 25096292 - LNX64-12.2-TFA: ANALYZE WITH -FROM
#                           ONLY DID NOT GET CORRECT TIME RANGE.
#    manuegar    11/23/16 - Support -last in analyze command.
#    manuegar    06/20/16 - Dynamic help part 4.
#    amchaura    04/06/16 - replace checkTFAMain with isTFARunning to check for
#                           TFA process
#    gadiga      11/19/14 - Fix Bug 19075994
#    manuegar    07/22/14 - Relocate tfactl_lib
#    manuegar    07/04/14 - Creation
#
############################ Functions List #################################
#
# doSearch
#
#############################################################################

package tfactlanalyze;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(tfactlanalyze_init
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
use POSIX qw(strftime);

use tfactlglobal;
use tfactlshare;

#################### tfactlanalyze Global Constants ####################

my (%tfactlanalyze_cmds) = (analyze      => {},
    );


#################### tfactlanalyze Global Variables ####################
our $ANALYZE_LEGACY = 0;

sub is_tfactl
{
  return 1;
}


########
# NAME
#   tfactlanalyze_init
#
# DESCRIPTION
#   This function initializes the tfactlanalyze module.  For now it 
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
  push (@tfactlglobal_command_callbacks, \&tfactlanalyze_process_cmd);
  push (@tfactlglobal_help_callbacks, \&tfactlanalyze_process_help);
  push (@tfactlglobal_command_list_callbacks, \&tfactlanalyze_get_tfactl_cmds);
  push (@tfactlglobal_is_command_callbacks, \&tfactlanalyze_is_cmd);
  push (@tfactlglobal_is_wildcard_callbacks, \&tfactlanalyze_is_wildcard_cmd);
  push (@tfactlglobal_syntax_error_callbacks, \&tfactlanalyze_syntax_error);
  push (@tfactlglobal_no_instance_callbacks, \&tfactlanalyze_is_no_instance_cmd);
  %tfactlglobal_cmds = (%tfactlglobal_cmds, %tfactlanalyze_cmds);

#Perform TFACTL consistency check if enabled
  if($tfactlglobal_hash{'consistchk'} eq 'y')
  {
    if(!tfactlshare_check_option_consistency(%tfactlanalyze_cmds))
    {   
      exit 1;
    }
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlanalyze init", 'y', 'n');

}

########
# NAME
#   tfactlanalyze_process_cmd
#
# DESCRIPTION
#   This routine calls the appropriate routine to process the command 
#   specified by $tfactlglobal_hash{'cmd'}.
#
# PARAMETERS
#   dbh       (IN) - initialized database handle, must be non-null.
#
# RETURNS
#   1 if command is found in the tfactlanalyze module; 0 if not.
#
# NOTES
#   Only tfactl_shell() calls this routine.
########
sub tfactlanalyze_process_cmd 
{
  my ($retval) = 0;
  my ($succ)   = 0;

  # Get current command from global value, which is set by 
  # tfactlanalyze_parse_tfactl_args()and by tfactl_shell().
  my ($cmd) = $tfactlglobal_hash{'cmd'};

  # Declare and initialize hash of function pointers, each designating a 
  # routine that processes an tfactlanalyze command.
  my (%cmdhash) = ( analyze       => \&tfactlanalyze_process_command,
      );

  if (defined ( $cmdhash{ $cmd } ))
  {    # If user specifies a known command, then call routine to process it. #
    $retval = $cmdhash{ $cmd }->();
    $succ = 1;
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlanalyze tfactlanalyze_process_cmd", 'y', 'n');

  return ($succ, $retval);
}

########
# NAME
#   tfactlanalyze_process_command
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
#   Only tfactlanalyze_process_cmd() calls this function.
########
sub tfactlanalyze_process_command
{
  my $retval = 0;

  tfactlshare_trace(3, "tfactl (PID = $$) tfactlanalyze tfactlanalyze_process_command", 'y', 'n');
  # Read the commands
  @ARGV = @tfactlglobal_argv;
  my $command1 = shift(@ARGV);
  my $command2 = shift(@ARGV);
  my $switch_val = $command1;
  $TNT_TCASE = FALSE;


  if ($switch_val eq "analyze" )
  {
    if ( $command2 eq "-h" || $command2 eq "-help" ) {
      print_help("analyze");
      return 0;
    }

    $SEARCH = 1;
    $COMMANDTOEXECUTE = "analyze";

    my $invalid_flags = "";
    if ( $command2 eq "-examples" )
    {
      if ( $ARGV[0] eq "-h" || $ARGV[0] eq "" || $ARGV[0] eq "-help") {
        print_help("analyze","examples");
        return 0;
      }
    } 
    if ( $command2 eq "-search" ) 
    {
      $SEARCH_PAT = $ARGV[0];
      shift(@ARGV);
    } elsif ( $command2 eq "-verbose" )
    {
      $TNT_VERBOSE = 1; 
    } elsif ( $command2 eq "-type" )
    {
      $TNT_TYPE = $ARGV[0];
      shift(@ARGV);
    } elsif ( $command2 eq "-database" )
    {
      $TNT_TYPE = $ARGV[0];
      shift(@ARGV);
    } elsif ( $command2 eq "-from" )
    {
      $TNT_FROM = $ARGV[0];
      shift(@ARGV);
    } elsif ( $command2 eq "-for" )
    {
      $TNT_FROM = $ARGV[0];
      shift(@ARGV);
    } elsif ( $command2 eq "-to" )
    {
      $TNT_TO = $ARGV[0];
      shift(@ARGV);
    } elsif ( $command2 eq "-comp" )
    {
      $TNT_COMP = $ARGV[0];
      shift(@ARGV);
    } elsif ( $command2 eq "-tcase" )
    {       
      $TNT_TCASE = TRUE if $ARGV[0] == 1;
      shift(@ARGV);
    } elsif ( $command2 eq "-since" || $command2 eq "-last" )
    {
      $SINCE = $ARGV[0];
      shift(@ARGV);
    } elsif ( $command2 eq "-o" )
    {
      $TNT_OFILE = $ARGV[0];
      shift(@ARGV);
    } elsif ( $command2 eq "-node" )
    {
      $node_list = $ARGV[0];
      shift(@ARGV);
    }
    elsif ($command2 eq "-legacy") {
      $ANALYZE_LEGACY = 1;      
    }
    else
    {
      $invalid_flags .= $command2 if lc($command2) ne "-examples";
    }
    for (my $c=0; $c<scalar(@ARGV); $c++) {
      my $arg = @ARGV[$c];
      $arg = trim($arg);
      if ( $arg eq "-search" )
      {
        $SEARCH_PAT = $ARGV[$c+1];
        $c++;
      } elsif ( $arg eq "-verbose" )
      {
        $TNT_VERBOSE = 1;
      } elsif ( $arg eq "-type" )
      {
        $TNT_TYPE = $ARGV[$c+1];
        $c++;
      } elsif ( $arg eq "-database" )
      {
        $TNT_TYPE = $ARGV[$c+1];
        $c++;
      } elsif ( $arg eq "-from" )
      {
        $TNT_FROM = $ARGV[$c+1];
        $c++;
      } elsif ( $arg eq "-for" )
      {
        $TNT_FROM = $ARGV[$c+1];
        $c++;
      } elsif ( $arg eq "-to" )
      {
        $TNT_TO = $ARGV[$c+1];
        $c++;
      } elsif ( $arg eq "-since" || $arg eq "-last" )
      {
        $SINCE = $ARGV[$c+1];
        $c++;
      } elsif ( $arg eq "-comp" )
      {
        $TNT_COMP = $ARGV[$c+1];
        $c++;
      } elsif ( $arg eq "-tcase" )
      {       
        $TNT_TCASE = TRUE if $ARGV[$c+1] == 1;
        $c++;
      } elsif ( $arg eq "-o" )
      {
        $TNT_OFILE = $ARGV[$c+1];
        $c++;
      } elsif ( $arg eq "-node" )
      {
        $node_list = $ARGV[$c+1];
        $c++;
      } 
      elsif ($arg eq "-legacy") {
        $ANALYZE_LEGACY = 1;
      }
      else
      {
        $invalid_flags .= " $arg";
      }

    }

          if ( $invalid_flags && $TNT_COMP ne "oratop" )
          {
            print "\n ERROR: Invalid arguments : $invalid_flags\n\n";
            print_help("analyze","");
            exit 1;
          }
          $SINCE = "1h" if ( ! $SINCE );
          $TNT_COMP = "all" if ( ! $TNT_COMP );
          $TNT_VERBOSE++ if ( $SEARCH_PAT );
          $TNT_FROM = getValidDateFromString ($TNT_FROM) if ($TNT_FROM);
          if ( $TNT_FROM eq "invalid" )
          {
            print "\n ERROR: Invalid value for -from. Supported format MMM/DD/YYYY HH24:MI:SS\n\n";
            exit 1;
          } else {
            # replace the date format returned from getValidDate to expected format 
            $TNT_FROM =~ s/([a-zA-Z]{3})\/(\d{2})\/(.*)/$2\/$1\/$3/g;
          }
          $TNT_TO = getValidDateFromString ($TNT_TO) if($TNT_TO);
          if ( $TNT_TO eq "invalid" )
          {
              print "\n ERROR: Invalid value for -to. Supported format MMM/DD/YYYY HH24:MI:SS\n\n";
              exit 1;
          } elsif ( $TNT_FROM && (not length $TNT_TO) ) {
            # switch -from was provided and -to was not provided
            $TNT_TO = strftime "%d/%b/%Y %H:%M:%S", localtime();
          } elsif ( $TNT_TO && (not length $TNT_FROM) ) {
            print "\n ERROR: start time is missing from input. Please enter a start time using -from flag.\n\n";
            exit 1;
          } else {
            # replace the date format returned from getValidDate to expected format
            $TNT_TO =~ s/([a-zA-Z]{3})\/(\d{2})\/(.*)/$2\/$1\/$3/g;
          }

    if ( $TNT_TYPE )
    { # Should be error/warning/generic
      if ( ! ( lc($TNT_TYPE) eq "error" ||
            lc($TNT_TYPE) eq "warning" ||
            lc($TNT_TYPE) eq "generic" ) )
      {
        if ( $TNT_COMP ne "oratop" )
        {
          print "\nERROR : Invalid value for type. Supported values are error|warning|generic\n\n";
          return 1;
        }
      }
    }
    if ( $TNT_COMP )
    {
      my %comps = ("db" => 1,"asm" => 1,"crs" => 1, "acfs" => 1, "oratop" => 1,
          "os" => 1,"osw" => 1,"oswslabinfo" => 1,"all" => 1);
      if ( ! exists $comps{lc($TNT_COMP)} )
      {
        print "\nERROR: Invalid value for component. Supported values are db|asm|crs|acfs|os|osw|oswslabinfo|all\n\n";
        return 1;
      }
    }
    if ( $SINCE )
    {#Value can be n, nh or nd
      if ( ! ( $SINCE =~ /^\d+$/ || $SINCE =~ /^\d+h$/ || $SINCE =~ /^\d+d$/ ) )
      {
        print "\nERROR: Invalid value for -last. Supported values are n<h|d>\n\n";
        return 1;
      }
    }
    if ( $TNT_COMP eq "oratop" )
    {
      $SINCE = $invalid_flags;
    }

    @ARGV = ();
  }

  # Dispatch the command
  tfactlshare_pre_dispatch();
  $retval = tfactlanalyze_dispatch();
  
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
sub tfactlanalyze_dispatch
{
  my $retval = 0;

  if ($COMMANDTOEXECUTE && $SEARCH) { $retval = doSearch($tfa_home, $SEARCH_PAT, $SINCE, $TNT_COMP, $TNT_TYPE, $TNT_FROM, $TNT_TO, $TNT_VERBOSE, $TNT_OFILE, $node_list); undef($COMMANDTOEXECUTE); undef($SEARCH); undef($SEARCH_PAT); undef($SINCE); undef($TNT_COMP); undef($TNT_TYPE); undef($TNT_FROM); undef($TNT_TO); undef($TNT_VERBOSE); undef($TNT_OFILE); undef($node_list); }

  return $retval;
}


########
# NAME
#   tfactlanalyze_process_help
#
# DESCRIPTION
#   This function is the help function for the tfactlanalyze module.
#
# PARAMETERS
#   command     (IN) - display the help message for this command.
#
# RETURNS
#   1 if command found; 0 otherwise.
########
sub tfactlanalyze_process_help 
{
  my ($command) = shift;       # User-specified argument; show help on $cmd. #

    my ($desc);                                # Command description for $cmd. #
    my ($succ) = 0;                         # 1 if command found, 0 otherwise. #

    if (tfactlanalyze_is_cmd ($command)) 
    {                              # User specified a command name to look up. #
      $desc = tfactlshare_get_help_desc($command);
      tfactlshare_print "$desc\n";
      $succ = 1;
    }

  return $succ;
}

########
# NAME
#   tfactlanalyze_is_cmd
#
# DESCRIPTION
#   This routine checks if a user-entered command is one of the known
#   TFACTL internal commands that belong to the tfactlanalyze module.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is one of the known commands, false otherwise.
########
sub tfactlanalyze_is_cmd 
{
  my ($arg) = shift;

  return defined ($tfactlanalyze_cmds {$arg});

}

########
# NAME
#   tfactlanalyze_is_wildcard_cmd
#
# DESCRIPTION
#   This routine determines if an tfactlanalyze command allows the use 
#   of wild cards.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is a command that can take wildcards as part of its argument, 
#   false otherwise.
########
sub tfactlanalyze_is_wildcard_cmd 
{
  my ($arg) = shift;

  return defined ($tfactlanalyze_cmds{ $arg }) &&
    (tfactlshare_get_cmd_wildcard($arg) eq "True" ) ;
}

########
# NAME
#   tfactlanalyze_is_no_instance_cmd
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
#   The tfactlanalyze module currently supports no command that can run 
#   without an TFAMain instance.
########
sub tfactlanalyze_is_no_instance_cmd 
{
  my ($arg) = shift;

  return !defined ($tfactlanalyze_cmds{ $arg }) ||
    (tfactlshare_get_cmd_noinst($arg) ne "True" ) ;
}

########
# NAME
#   tfactlanalyze_syntax_error
#
# DESCRIPTION
#   This function prints the correct syntax for a command to STDERR, used 
#   when there is a syntax error.  This function is responsible for 
#   only tfactlanalyze commands.
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
sub tfactlanalyze_syntax_error 
{
  my ($cmd) = shift;
  my ($cmd_syntax);                               # Correct syntax for $cmd. #
    my ($succ) = 0;


#display syntax only for commands in this module.
  if (tfactlanalyze_is_cmd($cmd))
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
#   tfactlanalyze_get_tfactl_cmds
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
sub tfactlanalyze_get_tfactl_cmds 
{
  return tfactlshare_filter_invisible_cmds(%tfactlanalyze_cmds);
}

sub doSearch 
{
  my ($tfa_home, $searchpat, $since, $component, $tnt_type, $tnt_from, $tnt_to, $tnt_v, $tnt_ofile,$node_list) = @_;
  my $show_info = $tnt_v;
  if ( $tnt_v == 2 )
  { # Search with verbose
    $show_info = 1;
    $tnt_v = 1;
  } elsif ( $searchpat )
  {
    $show_info = 0;
  }

  if (isTFARunning($tfa_home) == FAILED) {
    return 1;
  }

  if ( $component eq "oratop" )
  {
    my $retval = runOraTop($tfa_home, $tnt_type, $since, $tnt_ofile, $TNT_TCASE);
    return $retval;
  }

  my $localhost=tolower_host();
  my @nodelist = split(/\,/,$node_list);
  $node_list = "";

  foreach my $nodename (@nodelist)
  {
    $nodename =~ tr/A-Z/a-z/;
    next if ($nodename eq "all");
    $nodename = $localhost if ( $nodename eq "local");

    if (isNodePartOfCluster($tfa_home, $nodename)) {
    }
    else {
      print "Node $nodename is not part of TFA cluster\n";
      return 1;
    }
    $node_list .= "$nodename,"
  }
  $node_list =~ s/,$//;

  if ( $tnt_ofile )
  { # Create report file
    if ( -f "$tnt_ofile" )
    {
      print "WARNING: File $tnt_ofile already exists. Overwriting..\n";
    }
    open(WF, ">$tnt_ofile") || die "ERROR: Can't create $tnt_ofile for writing\n";
    print "INFO: Started command execution. Output will be saved to $tnt_ofile\n";
  }

  my $localhost=tolower_host();
  my $tntbin = catfile($tfa_home, "ext", "tnt", "bin", "tnt");
  my $tntcmd = $tntbin;
  my $targs = "-e ";
  $targs .= "-p \"$searchpat\"" if ( $searchpat );
  $targs .= " $since";  
  my $actionmessage;
  #Till new analyze get some shape execute new analyze under legacy
  if (!$ANALYZE_LEGACY) {
    $actionmessage = "$localhost:searchusingtnt:$searchpat~$since~$component~$tnt_type~$tnt_from~$tnt_to~$tnt_v~$node_list";
  }
  else {
    #For now directly call instead of connecting to TFA daemon
    my $outdir = tfactlshare_get_tfa_output_loc($tfa_home);
    my $indexLocation = catdir($outdir,"index");
    my $jsonString = "\"{\\\"data_type\\\":\\\"event\\\"";    
    $jsonString .= "}\"";
    chomp($jsonString);
    $actionmessage = "RUN_ANALYZE -indexloc $indexLocation -tfahome $tfa_home -json $jsonString";
  }  
  my $command = buildCLIJava($tfa_home,$actionmessage);
  my $line;
  my $printl = 1;
  my $hostn = "";
  my %phosts = ();
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
    if ($line eq "DONE") {
      close(WF) if ( $tnt_ofile );
      return 0;
    }
    #print "Received : $line\n";
    if ( $line =~ /Match count: (\d+)/ )
    {
      #print "Search results from host : $hostn. Found $1 matches.\n\n";
      $printl = 1;
    }
    elsif ( $line =~ /unique error count:\s+\d+/ )
    {
      #print "Message summary from host : $hostn.\n\n";
      $printl = 1;
    }
    elsif ( $line =~ /^tnt \(\$Revision:/ ||
        $line =~ /toaster - log file analyzer/ ||
        $line =~ /^INFO: Check documentation for more help./ )
    {
      $printl = 0;
    }
    elsif ( $line =~ /INFO: analyzing file:/ ||
        $line =~ /INFO: analyzing .* in dir:/
        )
    {
      $printl = 0 if ( $show_info == 0 );
    }
    elsif ( $line =~ /^INFO: analyzing host: (.*)$/ )
    {
      $hostn = $1;
      $printl = 0 if ( defined $phosts{$hostn} && $show_info == 0);
      $phosts{$hostn} = 1;
    }
    if (  $printl == 1 )
    {
      my $line_to_print = "";
      if ( $line =~ /^(\[Source: .*Line: \d+\]) ([^-]+) - \w+ - (.*)/ ||
          $line =~ /^(\[Source: .*Line: \d+\]) ([\d\s\:\.\-]+) - \w+ - (.*)/ )
      {
        $line_to_print = "\n$1\n$2\n$3\n";
      }
      else
      {
        $line_to_print = "$line\n";
      }
      if ( $tnt_ofile )
      {
        print WF "$line_to_print";
      }
      else
      {
        print "$line_to_print";
      }
    }
    $printl = 1;
  }
  close(WF) if ( $tnt_ofile );
  return 1;
}

1;
