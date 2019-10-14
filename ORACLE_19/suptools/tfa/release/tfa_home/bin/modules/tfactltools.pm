# 
# $Header: tfa/src/v2/tfa_home/bin/modules/tfactltools.pm /main/6 2018/08/09 22:22:30 recornej Exp $
#
# tfactltools.pm
# 
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactltools.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    08/06/18 - Change SUCCESS and FAILED values.
#    recornej    07/19/18 - Fix exit codes.
#    manuegar    07/13/18 - manuegar_multibug_01.
#    bibsahoo    07/10/18 - FIX BUG 28318884
#    bibsahoo    06/22/18 - FIX BUG 28226244
#    bibsahoo    06/14/18 - FIX BUG 28131000
#    bibsahoo    05/31/18 - Removing events and search from tfa external tools
#                           and fix bug 27908189
#    bibsahoo    05/29/18 - Creation
# 

package tfactltools;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(tfactltools_init
                 );

use strict;
use English;
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
use tfactlparser;
use dateutils;

my $UNAME=$^O;
my $PLATFORM=$UNAME;
#print "$PLATFORM\n";
my $IS_WIN = 0;
if ($PLATFORM eq "MSWin32") {
  $IS_WIN = 1;
}

#################### tfactltools Global Constants ####################

my (%tfactltools_cmds) = (events      => {},
                           search     => {},
                           changes    => {},
                         );


#################### tfactltools Global Variables ####################

sub is_tfactl
{
  return 1;
}


########
# NAME
#   tfactltools_init
#
# DESCRIPTION
#   This function initializes the tfactltools module.  For now it 
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
  push (@tfactlglobal_command_callbacks, \&tfactltools_process_cmd);
  push (@tfactlglobal_help_callbacks, \&tfactltools_process_help);
  push (@tfactlglobal_command_list_callbacks, \&tfactltools_get_tfactl_cmds);
  push (@tfactlglobal_is_command_callbacks, \&tfactltools_is_cmd);
  push (@tfactlglobal_is_wildcard_callbacks, \&tfactltools_is_wildcard_cmd);
  push (@tfactlglobal_syntax_error_callbacks, \&tfactltools_syntax_error);
  push (@tfactlglobal_no_instance_callbacks, \&tfactltools_is_no_instance_cmd);
  %tfactlglobal_cmds = (%tfactlglobal_cmds, %tfactltools_cmds);

  #Perform TFACTL consistency check if enabled
  if($tfactlglobal_hash{'consistchk'} eq 'y')
  {
     if(!tfactlshare_check_option_consistency(%tfactltools_cmds))
     {   
       exit 1;
     }
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactltools init", 'y', 'n');
}

########
# NAME
#   tfactltools_get_tfactl_cmds
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
sub tfactltools_get_tfactl_cmds 
{
  return tfactlshare_filter_invisible_cmds(%tfactltools_cmds);
}

########
# NAME
#   tfactltools_process_help
#
# DESCRIPTION
#   This function is the help function for the tfactltools module.
#
# PARAMETERS
#   command     (IN) - display the help message for this command.
#
# RETURNS
#   1 if command found; 0 otherwise.
########
sub tfactltools_process_help 
{
  my ($command) = shift;       # User-specified argument; show help on $cmd. #

    my ($desc);                                # Command description for $cmd. #
    my ($succ) = 0;                         # 1 if command found, 0 otherwise. #

    if (tfactltools_is_cmd ($command)) 
    {                              # User specified a command name to look up. #
      $desc = tfactlshare_get_help_desc($command);
      tfactlshare_print "$desc\n";
      $succ = 1;
    }

  return $succ;
}

########
# NAME
#   tfactltools_is_cmd
#
# DESCRIPTION
#   This routine checks if a user-entered command is one of the known
#   TFACTL internal commands that belong to the tfactlaccess module.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is one of the known commands, false otherwise.
########
sub tfactltools_is_cmd 
{
  my ($arg) = shift;

  return defined ($tfactltools_cmds {$arg});

}

########
# NAME
#   tfactltools_is_wildcard_cmd
#
# DESCRIPTION
#   This routine determines if an tfactltools command allows the use 
#   of wild cards.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is a command that can take wildcards as part of its argument, 
#   false otherwise.
########
sub tfactltools_is_wildcard_cmd 
{
  my ($arg) = shift;

  return defined ($tfactltools_cmds{ $arg }) &&
    (tfactlshare_get_cmd_wildcard($arg) eq "True" ) ;
}


########
# NAME
#   tfactltools_syntax_error
#
# DESCRIPTION
#   This function prints the correct syntax for a command to STDERR, used 
#   when there is a syntax error.  This function is responsible for 
#   only tfactltools commands.
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
sub tfactltools_syntax_error 
{
  my ($cmd) = shift;
  my ($cmd_syntax);                               # Correct syntax for $cmd. #
    my ($succ) = 0;


#display syntax only for commands in this module.
  if (tfactltools_is_cmd($cmd))
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
#   tfactltools_is_no_instance_cmd
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
sub tfactltools_is_no_instance_cmd 
{
  my ($arg) = shift;

  return !defined ($tfactltools_cmds{ $arg }) ||
    (tfactlshare_get_cmd_noinst($arg) ne "True" ) ;
}

########
# NAME
#   tfactltools_process_cmd
#
# DESCRIPTION
#   This routine calls the appropriate routine to process the command 
#   specified by $tfactlglobal_hash{'cmd'}.
#
# PARAMETERS
#   dbh       (IN) - initialized database handle, must be non-null.
#
# RETURNS
#   1 if command is found in the tfactltools module; 0 if not.
#
# NOTES
#   Only tfactl_shell() calls this routine.
########
sub tfactltools_process_cmd 
{
  my ($retval) = 0;
  my ($succ)   = 0;

  # Get current command from global value, which is set by 
  # tfactltools_parse_tfactl_args()and by tfactl_shell().
  my ($cmd) = $tfactlglobal_hash{'cmd'};

  # Declare and initialize hash of function pointers, each designating a 
  # routine that processes an tfactltools command.
  my (%cmdhash) = ( events       => \&tfactltools_process_events,
                    search      => \&tfactltools_process_events,
                    changes     => \&tfactltools_process_events,
                  );

  if (defined ( $cmdhash{ $cmd } ))
  {    # If user specifies a known command, then call routine to process it. #
    $retval = $cmdhash{ $cmd }->();
    $succ = 1;
  }

  tfactlshare_trace(3, "tfactl (PID = $$) tfactltools tfactltools_process_cmd", 'y', 'n');
  return ($succ, $retval);
}

########
# NAME
#   tfactltools_process_events
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
#   Only tfactltools_process_cmd() calls this function.
########
sub tfactltools_process_events
{
  my $retval = 0;
  my $localhost = tolower_host();  
  my $arg_sep = "_TFAARGSEP_";
    
  tfactlshare_trace(3, "tfactl (PID = $$) tfactltools tfactltools_process_events", 'y', 'n');

  # Read the commands
  @ARGV = @tfactlglobal_argv;
  my $command1 = shift(@ARGV);
  my $switch_val = $command1;

  #print "stat : $tfa_home -> @ARGV -> $localhost\n";

  if ($switch_val eq "events" ) 
  {    
    my $search;
    my $source;
    my $database;
    my $instance;
    my $component;
    my $startDate;
    my $endDate;
    my $forDate;
    my $last;
    my $help;
    my $debug;
    my $json = 0;
    my $node;
    my $fields;
    my $unknownopt;
    
    #Save global context, in case -for | -from -to are provided on the shell use those values.
    #Otherwise use global context variables.
    my $gblbackup_time = $tfactlglobal_ctx{"time"};
    my $gblbackup_stime = $tfactlglobal_ctx{"start-time"};
    my $gblbackup_etime = $tfactlglobal_ctx{"end-time"};
    my $gblbackup_db = $tfactlglobal_ctx{"db"};
    my $gblbackup_inst = $tfactlglobal_ctx{"inst"};

    my $argvStr = join " ", @ARGV;

    my %options =  ( 
                  "search" => \$search,
                  "source" => \$source,
                  "database" => \$database,
                  "instance" => \$instance,
                  "component" => \$component,
                  "from" => \$startDate,
                  "to" => \$endDate,
                  "for" => \$forDate,
                  "last" => \$last,
                  "json" => \$json,
                  "fields" => \$fields,
                  "node" => \$node,
                  "h"   => \$help,
                  "help" => \$help );

    my @arrayoptions = ( 
                      "search=s",
                      "source=s",
                      "database=s",
                      "instance=s",
                      "component=s",
                      "from=s",
                      "to=s",
                      "for=s",
                      "last=s",
                      "fields=s",
                      "json",
                      "node=s",
                      "h",
                      "help" );

    GetOptions(\%options, @arrayoptions ) or $unknownopt = 1;
    if ($argvStr ne "" && $argvStr !~ /-/) {
      $unknownopt = 1;
    }

    if ( $help || $unknownopt ) { 
      print_help("events");
      return 1 if ( $unknownopt );
      return 0;
    }

    if ($ENV{TFA_DEBUG} == 1) {
      $debug = 1;
    }

    my %cmd_hash;
    if ($search) {$cmd_hash{"content"} = $search;}
    if ($source) {$cmd_hash{"source"} = $source;}
    if ($component) {$cmd_hash{"component"} = $component;}

    if ($database) {
      $cmd_hash{"database"} = $database;
    } elsif ($tfactlglobal_ctx{"db"}) {
      $cmd_hash{"database"} = $tfactlglobal_ctx{"db"};
    }

    if ($instance) {
      $cmd_hash{"instance"} = $instance;
    } elsif ($tfactlglobal_ctx{"inst"}) {
      $cmd_hash{"instance"} = $tfactlglobal_ctx{"inst"};
    }
  
    my @args = @_;
    my $time;

    undef $tfactlglobal_ctx{"time"};
    undef $tfactlglobal_ctx{"start-time"};
    undef $tfactlglobal_ctx{"end-time"};
    if ($startDate) {
      $endDate = strftime("%Y-%m-%d %H:%M:%S",localtime(time)) if (!$endDate);
      $startDate =~ s/.SPACE./ /g;
      $endDate =~ s/.SPACE./ /g;
      my $valids = isValidDate($startDate);
      my $valide = isValidDate($endDate);
      if($valids != 0 && $valide != 0){      
        $tfactlglobal_ctx{"start-time"} = $startDate;
        $tfactlglobal_ctx{"end-time"} = $endDate;
      }
    } elsif ($forDate) {
      $forDate =~ s/.SPACE./\s/g;
      my $valid = isValidDate($forDate);
      if($valid != 0){
        $tfactlglobal_ctx{"time"} = $forDate;
      }
    } elsif ($last) {
      $last =~ s/\.SPACE\./ /g;
      if( $last =~ /([0-9]+)([hH]|[dD])/ ) {
        $time = $1;
        $time *= 60 if ( $2 =~ /[hH]/ );
        $time *= 60 * 24 if ( $2 =~ /[dD]/ );
      } else {
        help();
        return;
      }
    } else {
      tfactltools_restoreCtx($gblbackup_time,$gblbackup_stime,$gblbackup_etime);
    }

    my ($start, $end) = tfactltools_get_range($time);
    $cmd_hash{"from"} = $start;
    $cmd_hash{"to"} = $end;

    #print Dumper(\%cmd_hash);

    my $dateParsedFlag = 0;

    ## Build jsonString out of cmd_hash
    my $jsonString = "\"{\\\"data_type\\\":\\\"event\\\",";
    foreach my $key (keys %cmd_hash) {
      if ($key eq "from" || $key eq "to") {
        if ($dateParsedFlag == 0) {
          $jsonString .= "\\\"from\\\":\\\"" . $cmd_hash{from} . "\\\",\\\"to\\\":\\\"" . $cmd_hash{to} . "\\\",";
          $dateParsedFlag = 1;
        }
      } elsif ($key eq "database") {  
        $jsonString .= "\\\"component\\\":\\\"RDBMS\\\",\\\"database\\\":\\\"" . $cmd_hash{database} . "\\\",";
      } else {
        $jsonString .= "\\\"" . $key . "\\\":\\\"" . $cmd_hash{$key} . "\\\",";
      }
    }
    chop($jsonString);
    $jsonString .= "}\"";

    my $debugFlag;
    if ($debug) {
      $debugFlag = "-debug";
    } 

    my $nodeFlag;
    if ($node eq "local") {
      $nodeFlag = "-local";
    } elsif ($node eq "all") {
      $nodeFlag = "-all";
    } else {
      $nodeFlag = $node;
    }

    my $fieldsFlag = "";
    if ($json == 1 && length($fields) > 0) {
      $fieldsFlag = $fieldsFlag . $arg_sep . "-fields" . $arg_sep . $fields;
    } elsif ($json == 0 && length($fields) > 0) {
      print "ERROR: FLag -fields can be combined only with flag -json.\n";
      return;
    }

    my $message ="$localhost:indexSearch:$nodeFlag".$arg_sep."$debugFlag".$arg_sep."-json".$arg_sep."$jsonString".$fieldsFlag;
    my $command = buildCLIJava($tfa_home,$message);
    #print "CMD: $command\n";
    my @cli_output = tfactlshare_runClient($command);
    my $line;
    my $output = "";
    foreach $line (@cli_output) {
      if ($line !~ /DONE/) {
        $output .= $line . "\n";
      }
    }
    
    my $jsonString = $output;
    my $hits = 0;
    if ($debug) {
      #This debug is to get extra info from daemon
      foreach my $line (split /\n/, $output) {
        if ($hits > 0) {
          $jsonString .= $line;
        } else {
          print "$line\n\n";
        }
        if ($line =~ /^Total Hits/) {
          $hits = (split /\s::\s/, $line)[1];
          chomp($hits);
        }
      }
    } 

    my $host;
    my $jsonStr;
    my $consolidated_json = "[ ";
    foreach my $str (split /\n{1,}/, $jsonString) {
      if ($str =~ /^(.*)_TFAOPSEP_(.*)$/) {
        $host = $1;
        $jsonString = $2;
        #print "HOST: $host\n";
        $jsonString =~ s/^.(.*).$/$1/;   
        $consolidated_json .= "{\"hostname\":\"" . $host . "\"".
                              "," . $jsonString . "},";
      }
    }
    chop $consolidated_json;
    $consolidated_json .= "]";
    
    if ($json == 1) {
      print "$consolidated_json\n";
    } else {
      #print "JSON:\n*$consolidated_json*\n";
      if (!$consolidated_json) {
        #TODO - We should simply say No Events found .. 
        #I tihnk we r printing to avaoid diff ?  

        print "\n\nOutput from host : " . $localhost . "\n";
        print "------------------------------\n";

        print "\nEvent Summary:\n";
        print "INFO    :0\nERROR   :0\nWARNING :0\n"; 

        print "\nEvent Timeline:\n";
        print "No Events Found\n";
      } else {
        my $hashref = tfactlparser_decodeJSON($consolidated_json);
        #print Dumper($hashref);
        tfactltools_print_hash($hashref);
      }
    }
    tfactltools_restoreCtx($gblbackup_time,$gblbackup_stime,$gblbackup_etime);
    return $retval;
  } 
  elsif ($switch_val eq "search")
  {    
    my $help;
    my $debug;
    my $showdatatypes;
    my $fields;
    my $showfields;
    my $last;
    my $json = "";
    my $unknownopt;
    my $local = 0;

    my $gblbackup_time = $tfactlglobal_ctx{"time"};
    my $gblbackup_stime = $tfactlglobal_ctx{"start-time"};
    my $gblbackup_etime = $tfactlglobal_ctx{"end-time"};

    my $argvStr = join " ", @ARGV;

    my %options =  ( 
                    "json" => \$json,
                    "showdatatypes" => \$showdatatypes,
                    "fields" => \$fields,
                    "showfields" => \$showfields,
                    "last" => \$last,
                    "local" => \$local,
                    "h"   => \$help,
                    "help" => \$help );

    my @arrayoptions = (
                        "json=s",
                        "showdatatypes",
                        "fields=s",
                        "showfields=s",
                        "last=s",
                        "local",
                        "h",
                        "help" );
    
    GetOptions(\%options, @arrayoptions ) or $unknownopt = 1;
    if ($argvStr !~ /-/) {
      $unknownopt = 1;
    }

    if ( $help || $unknownopt ){
      print_help("search"); 
      return 1 if ( $unknownopt );
      return 0;
    }

    if ($ENV{TFA_DEBUG} == 1) {
      $debug = 1;
    }
    
    my $debugFlag;
    if ($debug) {
      $debugFlag = "-debug";
    } 

    my $fieldsFlag = "";
    if (length($fields) > 0) {
      $fieldsFlag = $fieldsFlag . $arg_sep . "-fields" . $arg_sep . $fields;
    } 

    my $localFlag;
    if ($local) {
      $localFlag = "-local";
    }

    my $time;
    undef $tfactlglobal_ctx{"time"};
    undef $tfactlglobal_ctx{"start-time"};
    undef $tfactlglobal_ctx{"end-time"};
    if ($last) {
      $last =~ s/\.SPACE\./ /g;
      if( $last =~ /([0-9]+)([mM]|[hH]|[dD])/ ) {
        $time = $1;
        $time *= 60 if ( $2 =~ /[hH]/ );
        $time *= 60 * 24 if ( $2 =~ /[dD]/ );
      } else {
        help();
        return;
      }
    } else {
      tfactltools_restoreCtx($gblbackup_time,$gblbackup_stime,$gblbackup_etime);
    }

    my ($start, $end) = tfactltools_get_range($time);

    my $message = "";
    if ($json) {
      $json =~ s/.SPACE./ /g;
      if ($json =~ /\"from\"/ && $json !~ /\"to\"/) {
        my $endTime = time;
        my $end = strftime("%m/%d/%Y %H:%M:%S",localtime($endTime));
        $json =~ s/\"from\"/\"to\":\"$end\",\"from\"/g;
      } elsif ($last && !($json =~ /\"from\"/ && $json =~ /\"to\"/)) {
        $json =~ s/}/,\"from\":\"$start\", \"to\":\"$end\"}/g;
      }
      $message = "$localhost:indexSearch:$localFlag".$arg_sep."$debugFlag".$arg_sep."-json".$arg_sep.tfactltools_convertToCompatibleJSONString($json).$fieldsFlag;
    } else {
      if ($showdatatypes) {
        $message = "$localhost:indexMetadata:showdatatypes";
      } elsif ($showfields) {
        my $jsonString = "\"{\\\"data_type\\\":\\\"".$showfields."\\\"}\"";
        $message = "$localhost:indexMetadata:showfields".$arg_sep.$jsonString;
      }
    }
    my $command = buildCLIJava($tfa_home,$message);
    #print "CMD: $command\n";
    
    my $output = "";
    foreach my $line (split /\n/ , `$command`)
    {
      if ($line !~ /DONE/) {
        $output .= $line . "\n";
      }
    }
    
    if ($showdatatypes || $showfields) {
      print "\n$output\n";
      return 2;
    } else {
      my $jsonString = $output;
      my $hits = 0;

      my $host;
      my $json;
      my $consolidated_json = "[ ";
      foreach my $str (split /\n{1,}/, $jsonString) {
        if ($str =~ /^(.*)_TFAOPSEP_(.*)$/) {
          $host = $1;
          $json = $2;
          #print "HOST: $host\n";
          $json =~ s/^.(.*).$/$1/;   
          $consolidated_json .= "{\"hostname\":\"" . $host . "\"".
                                "," . $json . "},";
        }
      }
      chop $consolidated_json;
      $consolidated_json .= "]";
      
      print "$consolidated_json\n";
      return 0;
    } 
  } 
  elsif ($switch_val eq "changes")
  {
    my %cmd_hash;

    my $help;
    my $debug;
    my $startDate;
    my $endDate;
    my $forDate;
    my $last;
    my $unknownopt;
    my $local = 0;

    my $argvStr = join " ", @ARGV;

    #Save global context, in case -for | -from -to are provided on the shell use those values.
    #Otherwise use global context variables.
    my $gblbackup_time = $tfactlglobal_ctx{"time"};
    my $gblbackup_stime = $tfactlglobal_ctx{"start-time"};
    my $gblbackup_etime = $tfactlglobal_ctx{"end-time"};
    my $gblbackup_db = $tfactlglobal_ctx{"db"};
    my $gblbackup_inst = $tfactlglobal_ctx{"inst"};

    my %options =  ( 
                    "from" => \$startDate,
                    "to" => \$endDate,
                    "for" => \$forDate,
                    "last" => \$last,
                    "local" => \$local,
                    "h"   => \$help,
                    "help" => \$help );

    my @arrayoptions = (
                        "from=s",
                        "to=s",
                        "for=s",
                        "last=s",
                        "local",
                        "h",
                        "help" );
    
    GetOptions(\%options, @arrayoptions ) or $unknownopt = 1;
    if ($argvStr ne "" && $argvStr !~ /-/) {
      $unknownopt = 1;
    }

    if ( $help || $unknownopt ){ 
      print_help("changes"); 
      return 1 if ( $unknownopt );
      return 0;
    }

    my $debugFlag;
    my $debug = 0;
    if ($ENV{TFA_DEBUG} == 1) {
      $debugFlag = "-debug";
      $debug = 1;
    }

    if ($tfactlglobal_ctx{"db"}) {
      $cmd_hash{"database"} = $tfactlglobal_ctx{"db"};
    }

    if ($tfactlglobal_ctx{"inst"}) {
      $cmd_hash{"instance"} = $tfactlglobal_ctx{"inst"};
    }
    
    my $time;
    undef $tfactlglobal_ctx{"time"};
    undef $tfactlglobal_ctx{"start-time"};
    undef $tfactlglobal_ctx{"end-time"};
    if ($startDate) {
      $endDate = strftime("%Y-%m-%d %H:%M:%S",localtime(time)) if (!$endDate);
      $startDate =~ s/.SPACE./ /g;
      $endDate =~ s/.SPACE./ /g;
      my $valids = isValidDate($startDate);
      my $valide = isValidDate($endDate);
      if($valids != 0 && $valide != 0){      
        $tfactlglobal_ctx{"start-time"} = $startDate;
        $tfactlglobal_ctx{"end-time"} = $endDate;
      }
    } elsif ($forDate) {
      $forDate =~ s/.SPACE./\s/g;
      my $valid = isValidDate($forDate);
      if($valid != 0){
        $tfactlglobal_ctx{"time"} = $forDate;
      }
    } elsif ($last) {
      $last =~ s/\.SPACE\./ /g;
      if( $last =~ /([0-9]+)([hH]|[dD])/ ) {
        $time = $1;
        $time *= 60 if ( $2 =~ /[hH]/ );
        $time *= 60 * 24 if ( $2 =~ /[dD]/ );
      } else {
        help();
        return;
      }
    } else {
      tfactltools_restoreCtx($gblbackup_time,$gblbackup_stime,$gblbackup_etime);
    }

    my ($start, $end) = tfactltools_get_range($time);
    $cmd_hash{"from"} = $start;
    $cmd_hash{"to"} = $end;

    #print Dumper(\%cmd_hash);

    my @datatypeList = ();
    if ($IS_WIN == 1) {
      @datatypeList = ("db_param", "server_ospackages");
    } else {
      @datatypeList = ("db_param", "server_osparameter", "server_ospackages");
    }

    ## Build jsonString out of cmd_hash
    my %changes_hash;
    my $jsonOPString = "";
    my $consolidated_json;
    foreach my $datatype (@datatypeList) {
      my $dateParsedFlag = 0;
      my $jsonString = "\"{\\\"data_type\\\":\\\"".$datatype."\\\",";
      foreach my $key (keys %cmd_hash) {
        if ($key eq "from" || $key eq "to") {
          if ($dateParsedFlag == 0) {
            $jsonString .= "\\\"from\\\":\\\"" . $cmd_hash{from} . "\\\",\\\"to\\\":\\\"" . $cmd_hash{to} . "\\\",";
            $dateParsedFlag = 1;
          }
        } else {
          $jsonString .= "\\\"" . $key . "\\\":\\\"" . $cmd_hash{$key} . "\\\",";
        }
      }
      chop($jsonString);
      $jsonString .= "}\"";

      my $outputdir = tfactlshare_get_tfa_output_loc($tfa_home);
      my $arg_sep = "_TFAARGSEP_";
      my $message ="$localhost:indexSearch:$debugFlag".$arg_sep."-json".$arg_sep."$jsonString";
      my $command = buildCLIJava($tfa_home,$message);
      #print "CMD: $command\n";
      my $output = "";
      foreach my $line (split /\n/ , `$command`)
      {
        if ($line !~ /DONE/) {
          $output .= $line . "\n";
        }
      }
      #print "OP:\n$output\n";

      $jsonOPString = "";
      my $hits = 0;
      if ($debug) {
        foreach my $line (split /\n/, $output) {
          if ($hits > 0) {
            $jsonOPString .= $line;
          } else {
            print "$line\n\n";
          }

          if ($line =~ /^Total Hits/) {
            $hits = (split /\s::\s/, $line)[1];
            chomp($hits);
          }
        }
      } else {
        $jsonOPString = $output;
      }

      my $host;
      my $jsonStr;
      $consolidated_json = "[ ";
      foreach my $str (split /\n{1,}/, $jsonOPString) {
        if ($str =~ /^(.*)_TFAOPSEP_(.*)$/) {
          $host = $1;
          $jsonStr = $2;
          #print "HOST: $host\n";
          $jsonStr =~ s/^.(.*).$/$1/;   
          $consolidated_json .= "{\"hostname\":\"" . $host . "\"".
                                "," . $jsonStr . "},";
        }
      }
      chop $consolidated_json;
      $consolidated_json .= "]";

      my $hashref = tfactlparser_decodeJSON($consolidated_json);
      foreach my $element (@{$hashref}) {
        my $hostname = $element->{hostname};
        my %tmphash = ("Result" => $element->{Result});
        $changes_hash{$hostname}->{$datatype} = \%tmphash; 
      }
      
    }

    #print "JSON:\n*$consolidated_json*\n";
    if (!$debug) {
      if (!$consolidated_json) {
        print "No Changes Found\n";
      } else {
        #print Dumper($hashref);
        tfactltools_print_changes_hash(\%changes_hash);
      }
    }
        
    return 0;
  }
}

####
# NAME
#   tfactltools_print_changes_hash
#
# DESCRIPTION
#   This fuction prints the changes hash
#
# PARAMETERS
#     $hashref       (IN)  Hash reference to the output hash
# RETURNS
#     NULL
#
# NOTES 
#   NONE
#####
sub tfactltools_print_changes_hash
{
  my $hashref = shift;
  my $retStr = "";

  my @print_arr = ();
  foreach my $hostname (keys %{$hashref}) {
    print "\n\nOutput from host : " . $hostname . "\n";
    print "------------------------------\n";

    foreach my $datatype (keys %{$hashref->{$hostname}}) {
      my @events_arr = @{$hashref->{$hostname}->{$datatype}->{Result}};
      foreach my $element (@events_arr) {
        my $component_info;
        if ($element->{database} && $element->{database} ne "NULL") {
          $component_info = "db." . $element->{database} . "." . $element->{instance};
        } elsif ($element->{instance} =~ /ASM/) {
          $component_info = "asm." . $element->{instance};
        } else {
          $component_info = "crs";
        }  

        if ($datatype =~ /db_param/) {
          if ($element->{previous_value} && $element->{previous_value} ne "null" ) {
            push @print_arr, $element->{timestamp} . "<opstr>[" . dateutils_format_logdate($element->{timestamp},1) . "]: [" . $component_info . "]: Parameter: " . $element->{name} . ": Value: " . $element->{previous_value} . " => " . $element->{value};
          }
        } elsif ($datatype =~ /server_osparameter/) {
          if ($element->{previous_value} && $element->{previous_value} ne "null" ) {
            push @print_arr, $element->{timestamp} . "<opstr>[" . dateutils_format_logdate($element->{timestamp},1) . "]: Parameter: " . $element->{name} . ": Value: " . $element->{previous_value} . " => " . $element->{value};
          }      
        } elsif ($datatype =~ /server_ospackages/) {
          push @print_arr, $element->{timestamp} . "<opstr>[" . dateutils_format_logdate($element->{timestamp},1) . "]: Package: " . $element->{package};
        }
      } 
    }

    my @sorted_print_arr = sort @print_arr;

    if ($#sorted_print_arr > -1) {
      foreach my $elem (@sorted_print_arr) {
        my $opstr = (split /<opstr>/, $elem)[1];
        print "$opstr\n";
      }
      print "\n";
    } else {
        print "No Changes Found\n";    
    }
  }
}

####
# NAME
#   tfactltools_print_hash
#
# DESCRIPTION
#   This fuction prints the event hash
#
# PARAMETERS
#     $hashref       (IN)  Hash reference to the output hash
# RETURNS
#     NULL
#
# NOTES 
#   NONE
#####
sub tfactltools_print_hash
{
  my $hashref = shift;
  my $retStr = "";

  foreach my $element (@{$hashref}) {
    my $hostname = $element->{hostname};
    my @events_arr = @{$element->{Result}};
    my @print_arr = ();
    my $error_event_count = 0;
    my $warning_event_count = 0;
    my $info_event_count = 0;
    foreach my $element (@events_arr) {
      my $component_info;
      if ($element->{component} eq "RDBMS") {
        $component_info = "db." . $element->{database} . "." . $element->{instance};
      } elsif ($element->{component} eq "ASM") {
        $component_info = "asm." . $element->{instance};
      } elsif ($element->{component} eq "ASMPROXY") {
        $component_info = "apx." . $element->{instance};
      } elsif ($element->{component} eq "ASMIO") {
        $component_info = "ios." . $element->{instance};
      } elsif ($element->{component} eq "CRS") {
        $component_info = "crs";
      }  

      my $event_alert_level = $element->{alertlevel};
      if ($event_alert_level == 1) {$error_event_count++;}
      elsif ($event_alert_level == 2) {$warning_event_count++;}
      elsif ($event_alert_level == 3) {$info_event_count++;}

      push @print_arr, $element->{timestamp} . "<opstr>[" . dateutils_format_logdate($element->{timestamp},1) . "]: [" . $component_info . "]: " . $element->{content};
    }
    my @sorted_print_arr = sort @print_arr;

    print "\n\nOutput from host : " . $hostname . "\n";
    print "------------------------------\n";

    print "\nEvent Summary:\n";
    print "INFO    :$info_event_count\nERROR   :$error_event_count\nWARNING :$warning_event_count\n"; 

    print "\nEvent Timeline:\n";
    if ($#sorted_print_arr > -1) {
      foreach my $elem (@sorted_print_arr) {
        my $opstr = (split /<opstr>/, $elem)[1];
        print "$opstr\n";
      }
      print "\n";
    } else {
        print "No Events Found\n";    
    }   
  }                                  
}

####
# NAME
#   tfactltools_restoreCtx
#
# DESCRIPTION
#   This fuction restore the  global context => tfactlglobal_ctx hash
#
# PARAMETERS
#     $time       (IN)  Saved global context variable $time
#     $start-time (IN)  Saved global context variable $start-time
#     $end-time   (IN)  Saved global context variable $end-time
# RETURNS
#     NULL
#
# NOTES 
#   NONE
#####
sub tfactltools_restoreCtx
{
  my $time = shift;
  my $stime =shift;
  my $etime =shift;
  if($time eq ""){
    undef $tfactlglobal_ctx{"time"};
  } else {
    $tfactlglobal_ctx{"time"} = $time;
  }
  if($stime eq ""){
    undef $tfactlglobal_ctx{"start-time"};
  } else {
    $tfactlglobal_ctx{"start-time"} = $stime;
  }
  if($etime eq ""){
    undef $tfactlglobal_ctx{"end-time"};
  } else {
    $tfactlglobal_ctx{"end-time"} = $etime;
  }
}

sub tfactltools_get_range
{
  my $start = "";
  my $end;
  my $time = shift;

  #print "status: " . $tfactlglobal_ctx{"time"} . " -> " .  $tfactlglobal_ctx{"start-time"} . " -> " .  $tfactlglobal_ctx{"end-time"} . "\n";

  if ( ! $tfactlglobal_ctx{"time"} && ! $tfactlglobal_ctx{"start-time"} &&
       !  $tfactlglobal_ctx{"end-time"} )
  {
    # default last 24 hours
    my $endTime = time;
    $end = strftime("%m/%d/%Y %H:%M:%S",localtime($endTime));
    $time = 24*60 if ( ! $time );
    my $startTime = $endTime - $time*60; 
    $start = strftime("%m/%d/%Y %H:%M:%S",localtime($startTime));  
  }
   elsif ( $tfactlglobal_ctx{"start-time"} )
  { 
    $end = getValidDateFromString($tfactlglobal_ctx{"end-time"}, "eventdate");
    $start = getValidDateFromString($tfactlglobal_ctx{"start-time"}, "eventdate");
  }
   elsif ( $tfactlglobal_ctx{"time"} )
  {
    #Show events for a particular date
    #Note that if time is provided it would show just events for that particular date-time.
    #If no time is provided it would show events for that whole day.  
    my $for = getValidDateFromString($tfactlglobal_ctx{"time"},"startDate");
    $start  = getValidDateFromString($for,"eventdate");
    $for = getValidDateFromString($tfactlglobal_ctx{"time"},"endDate");
    $end = getValidDateFromString($for,"eventdate");
    # my $for = getValidDateFromString($tfactlglobal_ctx{"-for"}, "time");
    #$start = $for - 4*60*60;
    #$end = $for + 4*60*60;
  }

  return ($start, $end);
}

sub tfactltools_convertToCompatibleJSONString {
  my $json_string = shift;
  $json_string =~ s/\"/\\\"/g;
  $json_string = "\"" . $json_string . "\"";
  return $json_string;
}
