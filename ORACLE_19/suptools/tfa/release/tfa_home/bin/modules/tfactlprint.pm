# 
# $Header: tfa/src/v2/tfa_home/bin/modules/tfactlprint.pm /main/44 2018/08/09 22:22:30 recornej Exp $
#
# tfactlprint.pm
# 
# Copyright (c) 2014, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlprint.pm 
#
#    DESCRIPTION
#      Prints requested details
#
#    NOTES
#    
#
#    MODIFIED   (MM/DD/YY)
#    recornej    07/25/18 - Fix exit codes
#    manuegar    07/13/18 - manuegar_multibug_01.
#    cnagur      05/10/18 - Notification using smtp.properties
#    bburton     03/19/18 - Bug 27665984 - remove use of POSIX::tmpnam
#    cnagur      04/07/17 - Removed Error Message 103 - Bug 24971982
#    llakkana    11/15/16 - Print IP numbers
#    cnagur      09/27/16 - Added tfactlprint_configuredComputeNodes
#    llakkana    05/30/16 - ADE Non-Daemon changes
#    manuegar    05/23/16 - Bug 23274045 - WS2012_122_TFA: NO WARNING FOR
#                           INCORRECT PARAMETERS ON TFACTL PROMPT
#    amchaura    04/06/16 - replace checkTFAMain with isTFARunning to check for
#                           TFA process
#    manuegar    03/25/16 - Dynamic help.
#    manuegar    03/02/16 - Bug 21886221 - [12201-LIN64-TFA]OUTPUT OF PRINT
#                           DIRECTORIES IS NOT FRIENDLY.
#    llakkana    12/29/15 - Fix 21885445
#    amchaura    12/14/15 - 22315724 CONFIGURABLE MINIMUM SECURITY LEVEL FOR
#                           TFA
#    manuegar    12/01/15 - Allow TFA IPS pack manipulation for non root users.
#    manuegar    11/29/15 - Bug 22283193 - LNX64-12.2-TFA-IPS: ALLOW TFA IPS
#                           PACKAGE MANIPULATION FEATURE.
#    bibsahoo    11/12/15 - FIX BUG 22172377 - [12201-LIN64-TFA]STATUS AND
#                           SINCE OPTION CAN'T WORK WITH PRINT ACTIONS CMD
#    amchaura    10/13/15 - Fix Bug 20608487 - DIAG : TFA : ER : TFACTL PRINT
#                           DIRECTORIES BASED ON COMPONENTS
#    amchaura    10/07/15 - Fix unknown options for print actions and print
#                           components
#    amchaura    09/23/15 - Fix BUG 21885341 - [12201-LIN64-TFA]PRINT CONFIG
#                           SHOULD CHECK INVALID OPTION
#    cnagur      09/10/15 - Fix for Bug 21816873
#    amchaura    09/02/15 - BUG 21172410 - TFACTL PRINT ACTIONS NEEDS OPTION
#                           FOR LISTING COLLECTIONS -SINCE
#    bibsahoo    08/25/15 - Adding Global Error Code 103
#    cnagur      07/17/15 - XbranchMerge cnagur_tfa_bug_21312262_txn from
#                           st_tfa_12.1.0.2.4psu
#    manuegar    05/05/15 - Bug 19544786 - LNX64-12.2-TFA-SCS:NO PRECHECK WITH
#                           INVALID OPTION FOR PRINT DIRECTORIES.
#    manuegar    05/04/15 - Add a filter to "print components" option.
#    manuegar    03/13/15 - Support additional tags for components.xml
#    cnagur      03/10/15 - Fix for Bug 18814422
#    llakkana    02/18/15 - Add support to print specific config value
#    bburton     02/06/15 - Bug 20445475 adding dotted line to table before
#                           rows added raising ever after fix to asciitable
#                           code
#    bburton     01/14/15 - Bug 20351923 - Do not do addRowLine (---) before a
#                           row exists.
#    cnagur      06/24/15 - Fix for Bug 21312262
#    cnagur      12/17/14 - Added upgradestatus
#    cnagur      12/04/14 - Fix for Bug 20050980
#    amchaura    12/02/14 - Fix BUG 18814417 - LNX64-12.1-TFA-SCS:NEED WARNING
#                           MESSAGE WHEN PRINT REMOTE DOWN TFA DIRECTORIES
#    amchaura    10/01/14 - set print config default clusterwide
#    amchaura    08/27/14 - Cleaned print actions
#    amchaura    08/26/14 - ER: 19504818 XML DRIVEN MAPPINGS AND COMPONENTS
#    manuegar    07/22/14 - Relocate tfactl_lib
#    manuegar    07/03/14 - Creation
#
############################ Functions List #################################
#
# printActions
# printDirectories
# printRunMode
# printOngoingCollections
# printTFALog
# printInventory
# printInventoryRunStatus
# printAdrIncidents
# printStartups
# printShutdowns
# printParameters
# printErrors
# printCollections
# printProblemSets
# printEvents
#
#############################################################################

package tfactlprint;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(tfactlprint_init
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

#################### tfactlprint Global Constants ####################

my $PRINTCOMPUTENODES = 0;
my $printsmtp = 0;
my (%tfactlprint_cmds) = (print      => {},
                         );


#################### tfactlprint Global Variables ####################

sub is_tfactl
{
  return 1;
}


########
# NAME
#   tfactlprint_init
#
# DESCRIPTION
#   This function initializes the tfactlprint module.  For now it 
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
  push (@tfactlglobal_command_callbacks, \&tfactlprint_process_cmd);
  push (@tfactlglobal_help_callbacks, \&tfactlprint_process_help);
  push (@tfactlglobal_command_list_callbacks, \&tfactlprint_get_tfactl_cmds);
  push (@tfactlglobal_is_command_callbacks, \&tfactlprint_is_cmd);
  push (@tfactlglobal_is_wildcard_callbacks, \&tfactlprint_is_wildcard_cmd);
  push (@tfactlglobal_syntax_error_callbacks, \&tfactlprint_syntax_error);
  push (@tfactlglobal_no_instance_callbacks, \&tfactlprint_is_no_instance_cmd);
  %tfactlglobal_cmds = (%tfactlglobal_cmds, %tfactlprint_cmds);

  #Perform TFACTL consistency check if enabled
  if($tfactlglobal_hash{'consistchk'} eq 'y')
  {
     if(!tfactlshare_check_option_consistency(%tfactlprint_cmds))
     {   
       exit 1;
     }
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlprint init", 'y', 'n');

}

########
# NAME
#   tfactlprint_process_cmd
#
# DESCRIPTION
#   This routine calls the appropriate routine to process the command 
#   specified by $tfactlglobal_hash{'cmd'}.
#
# PARAMETERS
#   dbh       (IN) - initialized database handle, must be non-null.
#
# RETURNS
#   1 if command is found in the tfactlprint module; 0 if not.
#
# NOTES
#   Only tfactl_shell() calls this routine.
########
sub tfactlprint_process_cmd 
{
  my ($retval) = 0;
  my ($succ)   = 0;

  # Get current command from global value, which is set by 
  # tfactlprint_parse_tfactl_args()and by tfactl_shell().
  my ($cmd) = $tfactlglobal_hash{'cmd'};

  # Declare and initialize hash of function pointers, each designating a 
  # routine that processes an tfactlprint command.
  my (%cmdhash) = ( print       => \&tfactlprint_process_print,
                  );

  if (defined ( $cmdhash{ $cmd } ))
  {    # If user specifies a known command, then call routine to process it. #
    $retval = $cmdhash{ $cmd }->();
    $succ = 1;
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlprint tfactlprint_process_cmd", 'y', 'n');

  return ($succ, $retval);
}

sub tfactlprint_helpargs {
   my $addargs = shift;
   my $help;
   my $unknownopt;

   GetOptions ("h"            => \$help,
               "help"         => \$help) or $unknownopt = 1;

   my $argsleft = scalar(@ARGV);
   if ( $help || $unknownopt || $argsleft ) {
     print "\nInvalid extra options passed : @ARGV\n\n" if $argsleft;
     print_help ("print",$addargs);
     return FALSE;
   }
 
   return TRUE;
}

########
# NAME
#   tfactlprint_process_print
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
#   Only tfactlprint_process_cmd() calls this function.
########
sub tfactlprint_process_print
{
  my $retval = 0;

  tfactlshare_trace(3, "tfactl (PID = $$) tfactlprint tfactlprint_process_print", 'y', 'n');
  # Read the commands
  @ARGV = @tfactlglobal_argv;
  my $command1 = shift(@ARGV);
  my $command2 = shift(@ARGV);
  my $switch_val = $command1;
  my $help;
  my $unknownopt;

  processprint:
  if ($switch_val eq "print" ) 
        {
          print_help ("print", "") if ( ! $command2 ); 
          if (defined $command2 && ($command2 eq "-h" || $command2 eq "-help")) {
                print_help("print");
          }
          $switch_val = $command2 ;
          {
            if ($switch_val eq "directories") {
                #removexmy $help;
                my $node;
                #removexmy $unknownopt;
		my $component;
                my $policy;
                my $permission;
		GetOptions ("h"            => \$help,
                            "help"         => \$help,
                            "node=s"       => \$node, 
			    "comp=s"       => \$component,
                            "policy=s"     => \$policy,
                            "permission=s" => \$permission )
                or $unknownopt = 1;
		if ( $help || $unknownopt )
                {
                  print_help("print","directories");
                  last processprint;
                }
                if ( defined $node && length $node ) {
                  $node_list = $node;
                } else {
                  $node_list = "";
                }
		if ( defined $component && length $component ) {
		  $comp = $component;
		} else {
		  $comp = "";
		}
                if ( defined $policy && length $policy ) {
                  if ( lc($policy) eq "exclusions" || lc($policy) eq "noexclusions" ) {
                    $printdir_policy = $policy;
                  } else {
                    print "-policy must be either exclusion or noexclusion.\n";
                    print_help("print","directories");
                    last processprint; 
                  }
                } else {
                  $printdir_policy = "";
                }
                if ( defined $permission && length $permission ) {
                  if ( lc($permission) eq "public" || lc($permission) eq "private" ) {
                    $printdir_permission = $permission;
                  } else {
                    print "-permission must be either public or private.\n";
                    print_help("print","directories");
                    last processprint;
                  }
                } else {
                  $printdir_permission = "";
                }
                if ( tfactlshare_isnodelist_duplicated($node_list) ) {
                  print "No node can be used more than once, please correct the node list and retry.\n";
                  print_help("print","directories");
                  last processprint;
                }
                $PRINTDIRS = 1; 
            }
	    elsif ($switch_val eq "ipaddress") {
	      $PRINTIPADDRESS = 1;
	      last processprint if not tfactlprint_helpargs("ipaddress");
	    }
            elsif ($switch_val eq "runmode" ) { 
		$PRINTRUNMODE = 1;
                last processprint if not tfactlprint_helpargs("runmode");
	    }
            elsif ($switch_val eq "repository" ) { 
		$PRINTREPO = 1;
                last processprint if not tfactlprint_helpargs("repository");
	    }
            elsif ($switch_val eq "hosts" ) { 
		$PRINTHOSTS = 1;
                last processprint if not tfactlprint_helpargs("hosts");
	    }
            elsif ($switch_val eq "configuredcomputenodes" ) { 
		$PRINTCOMPUTENODES = 1;
	    }
	    elsif ($switch_val eq "protocols" ) {
		$PRINTPROTOCOLS = 1;
                last processprint if not tfactlprint_helpargs("protocols");
	    }
            elsif ($switch_val eq "receivers" ) { 
		$PRINTRECEIVERS = 1;
                last processprint if not tfactlprint_helpargs("receivers");
	    }
            elsif ($switch_val eq "collectors" ) { 
                $PRINTCOLLECTORS = 1;
                last processprint if not tfactlprint_helpargs("collectors"); 
            }
            elsif ($switch_val eq "robjects" ) { 
                $PRINTROBJECTS = 1;
                last processprint if not tfactlprint_helpargs("robjects");
            }
            elsif ($switch_val eq "dom0IP" ) { $PRINTIP =1 }
            elsif ($switch_val eq "cookie" ) { $PRINTCOOKIE = 1 }
            elsif ($switch_val eq "tfahome" ) { $PRINTTFAHOME = 1 }
            elsif ($switch_val eq "walletpassword" ) { $PRINTWALLETPASSWORD = 1 }
            elsif ($switch_val eq "cells" ) { $PRINTCELLS = 1 }
            elsif ($switch_val eq "onlinecells" ) { printOnlineCells($tfa_home); 
                                                    $PRINTONLINECELLS=0; }
            elsif ($switch_val eq "buildversion" ) { $PRINTBUILDVERSION = 1 }
            elsif ($switch_val eq "ongoingcoll" ) { $PRINTONGOINGCOLL = 1 }
            elsif ($switch_val eq "status" ) {
		$CHECKSTATUS = 1;
                last processprint if not tfactlprint_helpargs("status");
	    }
            elsif ($switch_val eq "actions" ) {
		my $help;
                my $pstatus;
                my $unknownopt;
		my $psince;
		my @args = @ARGV;
		GetOptions ("h" => \$help,
                            "help" => \$help,
                            "status:s" => \$pstatus,
			    "since:s" => \$psince )
                or $unknownopt = 1;
		if ( $help || $unknownopt ) {
		  print_help("print","actions");
		  last processprint;
                }
                $PRINTACTIONS = 1;

		if ($pstatus) {
		      $action_status =  $pstatus;
		      if (defined $action_status) {
			      $action_status = trim(uc($action_status));
			      my $status;
			      foreach $status (split(/\,/, $action_status)) {
				  if (!($status eq "REQUESTED" || $status eq "RUNNING" ||
				  $status eq "FAILED" || $status eq "COMPLETE")) {
				    print "Invalid action status: $status. Action status can be COMPLETE/RUNNING/FAILED/REQUESTED\n";
				    print_help("print","actions");
				    last processprint;
				  }
			      }
		      }
		}

		if ($psince) {
		      $action_time = $psince;
		      if (defined $action_time) {
			      $action_time = trim($action_time);
			      if (!($action_time =~ /^(\d+)[d|D]$/ || $action_time =~ /^(\d+?)[h|H]$/)) {
				      print "The time entered is invalid: $action_time\n";
				      print "Some examples of valid time entries for -since flag : 2h, 10d\n";
				      print_help("print","actions");
				      last processprint;
			      }

			      if ( $action_time =~ /^(\d+)[d|D]$/ ) {
				      $action_time =~ s/D$/d/;
				      my $time = $action_time;
				      $time =~ s/d$//;

				      if ( $time > 30 ) {
					      print "Number of days should be less than 30\n";
					      print_help("print","actions");
					      last processprint;
				      }
			      }

			      if ( $action_time =~ /^(\d+)[h|H]$/ ) {
				      $action_time =~ s/H$/h/;
				      my $time = $action_time;
				      $time =~ s/h$//;

				      if ( $time > 720 ) {
					      print "Number of hours should be less than 720\n";
					      print_help("print","actions");
					      last processprint;
				      }
			      }
		      }
		}

		my $argsString = join(' ',@args);
		if ( $argsString =~ /-since/ && !$psince ) {
			print "\nWarning: Action time can't be NULL\n";
		}
		if ( $argsString =~ /-status/ && !$pstatus ) {
			print "\nWarning: Action status can't be NULL\n";
		}
            }
            elsif ($switch_val eq "log" ) { $PRINTTFALOG = 1 }
            elsif ($switch_val eq "inventory" ) {
                my $command3 = @ARGV[0];
                if (defined $command3 && ($command3 eq "-h" || $command3 eq "-help")) {
                  print "Usage: $tfacmd print inventory [ -node <all | local | n1,n2,..> ]\n";
		  last processprint;
                }
                $PRINTINVENTORY = 1;
                $node_list = "";
                for (my $c=0; $c<scalar(@ARGV); $c++) {
                  my $arg = @ARGV[$c];
                  $arg = trim($arg);
                  if ($arg eq "-node") {
                        $node_list =  @ARGV[$c+1];
                        if (defined $node_list) {
                          $node_list = trim($node_list);
                        } else {
			  print "\nPlease specify node list\n\n";
			  print "Usage: $tfacmd print inventory [ -node <all | local | n1,n2,..> ]\n";
		  	  last processprint;
			}
                  }
                }
                @ARGV=[];
                shift(@ARGV);
                if ( tfactlshare_isnodelist_duplicated($node_list) ) {
                  print "No node can be used more than once, please correct the node list and retry.\n";
                  print "Usage: $tfacmd print inventory [ -node <all | local | n1,n2,..> ]\n";
                  last processprint;
                }
                }
            elsif ($switch_val eq "invrunstat" ) { $PRINTINVRUNSTAT = 1 }
            elsif ($switch_val eq "adrincidents" ) { $PRINTADRINCIDENTS = 1 }
            elsif ($switch_val eq "cellinvrunstat" ) { $PRINTCELLINVRUNSTAT = 1 }
            elsif ($switch_val eq "celldiagstat" ) { $PRINTCELLDIAGSTAT = 1 }
            elsif ($switch_val eq "startups" ) { $PRINTSTARTUPS = 1 }
            elsif ($switch_val eq "shutdowns" ) { $PRINTSHUTDOWNS = 1 }
            elsif ($switch_val eq "parameters" ) { $PRINTPARAMETERS = 1 }
            elsif ($switch_val eq "errors" ) { $PRINTERRORS = 1 }
            elsif ($switch_val eq "collections" ) {
                $PRINTCOLLECTIONS = 1;
                my $command3 = shift(@ARGV);
                my $command4 = shift(@ARGV);

                if ( $command3 eq "-status" && $command4 eq "running" ) {
                        $PRINTCOLLECTIONS = 0;
                        $PRINTONGOINGCOLL = 1;
                }
		if ( $command3 eq "-since" && defined $command4 ) {
			$coll_time = $command4;
			$coll_time = trim($coll_time);
                          if (!($coll_time =~ /^(\d+)d{1}$/ || $coll_time =~ /^(\d+?)h{1}$/)) {
                                print "The time entered is invalid: $coll_time\n";
                                print "Some examples of valid time entries for -since flag : 2h, 10d\n";
                                print "Usage: $tfacmd print collections [ -since <n><h|d> ]\n"  ;
                                last processprint;
                          }
		}
                @ARGV=[];
                shift(@ARGV);
            }
            elsif ($switch_val eq "version" ) { $CHECKVERSION = 1 }
            elsif ($switch_val eq "smtp" ) { $printsmtp = 1 }
            elsif ($switch_val eq "upgradestatus" ) {
		$UPGRADEVERSION = shift(@ARGV);
		$UPGRADESTATUS = 1;
	    }
            elsif ($switch_val eq "clustereviction" ) { $PRINTCMD = "printclustereviction" }
            elsif ($switch_val eq "clusterreconfig" ) { $PRINTCMD = "printclusterreconfig" }
            elsif ($switch_val eq "genericevent" ) { $PRINTCMD = "printgenericevent" }
            elsif ($switch_val eq "config" ) {
                $PRINTCONFIG = 1;
                $node_list = "all";
                my $params = "all";
                my $help;
                my $node;
                my $name;
                my $unknownopt;
                GetOptions ("h" => \$help,
                            "help" => \$help,
                            "node=s" => \$node,
                            "name=s" => \$name )
                or $unknownopt = 1;
		my $argsleft = scalar(@ARGV);
                if ( $help || $unknownopt || $argsleft )
                {
		  print "Invalid option $ARGV[0]\n" if $argsleft > 0;
                  print_help("print","config");
                  #removexprint "Usage: $tfacmd print config [ -node <all | local | n1,n2,..>  -name <param>]\n";
                  last processprint;
                }
                if ( defined $node && length $node ) {
                  $node_list = tfactlshare_trim_nodelist($node);
                }
                if ( defined $name && length $name ) {
                  $params = $name;
                }
		$metadata = "node=".$node_list."~name=".$params;
                @ARGV=[];
                shift(@ARGV);
                if ( tfactlshare_isnodelist_duplicated($node_list) ) {
                  print "No node can be used more than once, please correct the node list and retry.\n";
                  print "Usage: $tfacmd print config [ -node <all | local | n1,n2,..> ] [ -name <param> ] \n";
                  last processprint;
                }

            }
            elsif ($switch_val eq "internalconfig" ) {
              $PRINTINTERNALCONFIG = 1;
            }
            elsif ($switch_val eq "suspendedips" ) {
              $PRINTSUSPENDEDIPS = 1;
              last processprint if not tfactlprint_helpargs("suspendedips");
            }
            elsif ($switch_val eq "components" ) {
              if ( @ARGV ) {
                for my $ndx ( 0 .. $#ARGV ) {
		   my $opt = $ARGV[$ndx];
		   if ($opt eq "-h" || $opt eq "-help") {
                        print_help("print","components");
			return;
		   }
                   if ( not exists $tfactlglobal_xmlcompshash{lc($opt)} ) {
                     print "$opt is not a valid component.\n";
                     print_help("print","components");
                     undef %tfactlglobal_usersxmlcompshash;
                     return;
                   }
                   $tfactlglobal_usersxmlcompshash{lc($ARGV[$ndx])} = TRUE;
                } # end for $#ARGV
              } # end if @ARGV
              $PRINTCOMPONENTS = 1;
            }
            elsif ($switch_val eq "problems" ) { $PRINTPROBLEMSETS = 1 }
            elsif ($switch_val eq "events" ) {
                $PRINTEVENTS = 1 ;

                for (my $c=0; $c<scalar(@ARGV); $c++) {
                  my $arg = @ARGV[$c];
                  $arg = trim($arg);
                  if ($arg eq "-since") {
                        $event_time = @ARGV[$c+1];
                        if (defined $event_time) {
                          $event_time = trim($event_time);
                          if (!($event_time =~ /^(\d+)d{1}$/ || $event_time =~ /^(\d+?)h{1}$/)) {
                                print "The time entered is invalid: $event_time\n";
                                print "Some examples of valid time entries for -since flag : 2h, 10d\n";
                                print "Usage: $tfacmd print events [ -since <n><h|d> ]\n"  ;
                                last processprint;
                          }
                        }
                  }
                }
                @ARGV=[];
                shift(@ARGV);
            }
            else { print_help ("print", "Invalid argument $command2") if defined($command2) && ($command2 ne "-h") && ($command2 ne "-help"); }
          }
        }

  # Dispatch the command
  tfactlshare_pre_dispatch();
  $retval = tfactlprint_dispatch();

  return $retval;
}

########
# NAME
#   tfactlprint_action_help
#
# DESCRIPTION
#   Prints the help message for tfactlprint action
#
# PARAMETERS
#
# RETURNS
#
########
sub tfactlprint_action_help
{
  my $tfacmd = shift;

  print "Usage: $tfacmd print actions [ -status <status> ] [ -since <n><h|d> ]\n";
  print "  Print TFA Actions.\n\n";
  print "Options:\n";
  print " -status <status>    Action status can be one or more of\n";
  print "                     COMPLETE,RUNNING,FAILED,REQUESTED\n";
  print "                     Specify comma separated list of statuses\n";
  print " -since <n><h|d>     Actions from past 'n' [d]ays or 'n' [h]our\n";

  return;
}

########
# NAME
#   tfactlprint_dispatch
#
# DESCRIPTION
#   Dispatch de command.
#
# PARAMETERS
#
# RETURNS
#
########
sub tfactlprint_dispatch
{
 my $retval = 0;

 if ($CHECKSTATUS) { $retval = checkTFAStatus($tfa_home); $CHECKSTATUS=0; }
 elsif ($CHECKVERSION) { $retval = checkVersion($tfa_home); $CHECKVERSION=0; }
 elsif ($UPGRADESTATUS) { $retval = tfactlshare_checkUpgradeStatus($tfa_home, $UPGRADEVERSION); $UPGRADESTATUS = 0; undef($UPGRADEVERSION);}
 elsif ($PRINTACTIONS) { $retval = printActions($tfa_home, $action_status, $action_time); $PRINTACTIONS=0; undef($action_status); undef($action_time); }
 elsif ($PRINTCOOKIE) { $retval = printCookie($tfa_home); $PRINTCOOKIE=0; }
 elsif ($PRINTTFAHOME) { $retval = printTfaHome($tfa_home); $PRINTTFAHOME=0; }
 elsif ($PRINTWALLETPASSWORD) { $retval = printWalletPassword($tfa_home); $PRINTWALLETPASSWORD=0; }
 elsif ($PRINTCELLS) { $retval = printCells($tfa_home); $PRINTCELLS=0; }
 elsif ($PRINTONLINECELLS) { $retval = printOnlineCells($tfa_home); $PRINTONLINECELLS=0; }
 elsif ($PRINTBUILDVERSION) { $retval = printBuildVersion($tfa_home); $PRINTBUILDVERSION=0; } 
 elsif ($PRINTONGOINGCOLL) { $retval = printOngoingCollections($tfa_home); $PRINTONGOINGCOLL=0; }
 elsif ($PRINTTFALOG) { $retval = printTFALog($tfa_home); $PRINTTFALOG=0; }
 elsif ($PRINTDIRS) { $retval = printDirectories($tfa_home, $node_list, $comp, $printdir_policy, $printdir_permission); 
                      $PRINTDIRS=0; $comp=""; $printdir_policy=""; $printdir_permission=""; }
 elsif ($PRINTHOSTS) { $retval = printHosts($tfa_home); $PRINTHOSTS=0; }
 elsif ($PRINTCOMPUTENODES) { $retval = tfactlprint_configuredComputeNodes($tfa_home); $PRINTCOMPUTENODES=0; }
 elsif ($printsmtp) { $retval = tfactlshare_printSmtpProperties($tfa_home); $printsmtp=0; } 
 elsif ($PRINTPROTOCOLS) { $retval = tfactlprint_protocols($tfa_home); $PRINTPROTOCOLS=0; } 
 elsif ($PRINTRECEIVERS) { $retval = printReceivers($tfa_home); $PRINTRECEIVERS = 0; }
 elsif ($PRINTCOLLECTORS) { $retval = printCollectors($tfa_home); $PRINTCOLLECTORS= 0; }
 elsif ($PRINTROBJECTS) { $retval = tfactlshare_printRObjects($tfa_home); $PRINTROBJECTS= 0; }
 elsif ($PRINTIP) { $retval = printDom0IP($tfa_home); $PRINTIP=0; }
 elsif ($PRINTSTARTUPS) { $retval = printStartups($tfa_home); $PRINTSTARTUPS=0; }
 elsif ($PRINTADRINCIDENTS)  { $retval = printAdrIncidents($tfa_home); $PRINTADRINCIDENTS=0; }
 elsif ($PRINTCMD) { $retval = printCmd($tfa_home,"$PRINTCMD"); }
 elsif ($PRINTSHUTDOWNS) { $retval = printShutdowns($tfa_home); $PRINTSHUTDOWNS=0; }
 elsif ($PRINTPARAMETERS) { $retval = printParameters($tfa_home); $PRINTPARAMETERS=0; }
 elsif ($PRINTERRORS) { $retval = printErrors($tfa_home); $PRINTERRORS=0; }
 elsif ($PRINTCOLLECTIONS) { $retval = printCollections($tfa_home, $coll_time); $PRINTCOLLECTIONS=0; undef $coll_time; }
 elsif ($PRINTPROBLEMSETS) { $retval = printProblemSets($tfa_home); $PRINTPROBLEMSETS=0; }
 elsif ($PRINTREPO) { $retval = printRepository($tfa_home); $PRINTREPO=0; }
 elsif ($PRINTIPADDRESS) { $retval = tfactlprint_ipaddress($tfa_home); $PRINTIPADDRESS =0;  }
 elsif ($PRINTRUNMODE) { $retval = printRunMode($tfa_home); $PRINTRUNMODE =0;  }
 elsif ($PRINTCONFIG) { $retval = printConfig($tfa_home, $metadata); $PRINTCONFIG=0; }
 elsif ($PRINTCOMPONENTS) { $retval = tfactlprint_components($tfa_home); $PRINTCOMPONENTS=0; }
 elsif ($PRINTSUSPENDEDIPS) { $retval = tfactlprint_suspended_ips($tfa_home); $PRINTSUSPENDEDIPS=0; }
 elsif ($PRINTINTERNALCONFIG) { $retval = printInternalConfig($tfa_home); $PRINTINTERNALCONFIG=0; }
 elsif ($PRINTEVENTS) { $retval = printEvents($tfa_home, $event_time); $PRINTEVENTS=0; }
 elsif ($PRINTINVENTORY) { $retval = printInventory($tfa_home, $node_list); $PRINTINVENTORY=0; }
 elsif ($PRINTINVRUNSTAT) { $retval = printInventoryRunStatus($tfa_home); $PRINTINVRUNSTAT=0; }
 elsif ($PRINTCELLINVRUNSTAT) { $retval = printCellInventoryRunStatus($tfa_home); $PRINTCELLINVRUNSTAT=0; }
 elsif ($PRINTCELLDIAGSTAT) { $retval = printCellDiagCollectRunStatus($tfa_home); $PRINTCELLDIAGSTAT=0; }

 return $retval;
}


########
# NAME
#   tfactlprint_process_help
#
# DESCRIPTION
#   This function is the help function for the tfactlprint module.
#
# PARAMETERS
#   command     (IN) - display the help message for this command.
#
# RETURNS
#   1 if command found; 0 otherwise.
########
sub tfactlprint_process_help 
{
  my ($command) = shift;       # User-specified argument; show help on $cmd. #

  my ($desc);                                # Command description for $cmd. #
  my ($succ) = 0;                         # 1 if command found, 0 otherwise. #

  if (tfactlprint_is_cmd ($command)) 
  {                              # User specified a command name to look up. #
    $desc = tfactlshare_get_help_desc($command);
    tfactlshare_print "$desc\n";
    $succ = 1;
  }

  return $succ;
}

########
# NAME
#   tfactlprint_is_cmd
#
# DESCRIPTION
#   This routine checks if a user-entered command is one of the known
#   TFACTL internal commands that belong to the tfactlprint module.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is one of the known commands, false otherwise.
########
sub tfactlprint_is_cmd 
{
  my ($arg) = shift;

  return defined ($tfactlprint_cmds {$arg});

}

########
# NAME
#   tfactlprint_is_wildcard_cmd
#
# DESCRIPTION
#   This routine determines if an tfactlprint command allows the use 
#   of wild cards.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is a command that can take wildcards as part of its argument, 
#   false otherwise.
########
sub tfactlprint_is_wildcard_cmd 
{
  my ($arg) = shift;

  return defined ($tfactlprint_cmds{ $arg }) &&
    (tfactlshare_get_cmd_wildcard($arg) eq "True" ) ;
}

########
# NAME
#   tfactlprint_is_no_instance_cmd
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
#   The tfactlprint module currently supports no command that can run 
#   without an TFAMain instance.
########
sub tfactlprint_is_no_instance_cmd 
{
  my ($arg) = shift;

  return !defined ($tfactlprint_cmds{ $arg }) ||
    (tfactlshare_get_cmd_noinst($arg) ne "True" ) ;
}

########
# NAME
#   tfactlprint_syntax_error
#
# DESCRIPTION
#   This function prints the correct syntax for a command to STDERR, used 
#   when there is a syntax error.  This function is responsible for 
#   only tfactlprint commands.
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
sub tfactlprint_syntax_error 
{
  my ($cmd) = shift;
  my ($cmd_syntax);                               # Correct syntax for $cmd. #
  my ($succ) = 0;


  #display syntax only for commands in this module.
  if (tfactlprint_is_cmd($cmd))
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
#   tfactlprint_get_tfactl_cmds
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
sub tfactlprint_get_tfactl_cmds 
{
  return tfactlshare_filter_invisible_cmds(%tfactlprint_cmds);
}

#======================= printActions ===========================#
sub printActions
{
  my $tfa_home = shift;
  my $action_status = shift;
  my $action_time = shift;
  dbg(DBG_VERB, "In printActions\n");
  my $localhost = tolower_host();
  if (isTFARunning($tfa_home) == FAILED) {
        return FAILED;
  }
  
  dbg(DBG_VERB, "Running printActions through Java CLI\n");
  my $message ="$localhost:printactions:$action_status:$action_time";
  #if ($action_status eq "") {
  #  $message ="$localhost:printactions";
  #}
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "$command\n");
  my $line;
  my $trigger="";


  #my @nodelist = split("\,",$NODE_NAMES);
  #my %TABLES;
  #foreach (@nodelist) {
  #     my $tb = Text::ASCIITable->new();
  #     $tb->setCols("TIME", "ACTIO4yyN", "STATUS", "COMMENTS");
  #     $tb->setColWidth("COMMENTS", $tputcols-60);
  #     $tb->setOptions({"outputWidth" => $tputcols, "headingText" => $_});
  #     $TABLES{$_} = $tb;
  #}

  my $table = Text::ASCIITable->new();
  $table->setCols("HOST", "START TIME", "END TIME", "ACTION", "STATUS", "COMMENTS");
  $table->setColWidth("COMMENTS", $tputcols-60);
  $table->setColWidth("ACTION", 15);
  #$table->setOptions({"outputWidth" => $tputcols, "headingText" => $_});
  $table->setOptions({"outputWidth" => $tputcols});
  my $tableRowAdded = "FALSE";
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
    if ( $line eq "DONE") {
        #my $key_entry;
        #my $value;
        #while (($key_entry, $value) = each(%TABLES)) {
        #       print $TABLES{$key_entry}."\n";
        #}
        print "$table\n";
        dbg(DBG_WHAT,"#### All Stored Actions Printed ####\n");
        return SUCCESS;
    }
    else {
      if ($line =~ /Connection refused/) {
        #my ($msg, $hostname) = split(/!/, $line);
        #delete $TABLES{$hostname};
      }
      else {
        my ($rname,$rhost,$rclient,$rtime,$etime,$rstatus,$rargs) = split(/!/, $line);
        #$table = $TABLES{$rhost};
        $Text::Wrap::columns = $tputcols-60;
        if ($rargs) {
          if ($rname eq "Collect traces" || $rname eq "Collect traces & zip") {
          $rname = "Collect traces & zip";
            $table->addRow($rhost, $rtime,$etime,$rname,$rstatus, "Collection details:");
            $tableRowAdded = "TRUE";
            my @comments = split (/-/, $rargs);
            for (my $i=0; $i<scalar(@comments); $i++) {
              if ($comments[$i] =~ /^z /) {
                my @res = split(/\s/, $comments[$i]);
                if ($res[1] =~ /\.zip/) {
                  $table->addRow("","","","","",wrap("","","Zip file: $res[1]"));
                  $tableRowAdded = "TRUE";
                }
                else {
                  $table->addRow("","","","","",wrap("","","Zip file: $res[1].zip"));
                  $tableRowAdded = "TRUE";
                }
              }
            elsif ($comments[$i] =~ /^tag /) {
                #my @res = split(/\s/, $comments[$i]);
                #$table->addRow("","","","",wrap("","","Tag: $res[1]"));
              my @arr = split (/ -/, $rargs);
                for (my $j=0; $j<scalar(@arr); $j++) {
                  if ($arr[$j] =~ /^tag /) {
                    my $tagforzip = $arr[$j];
                    $tagforzip =~ s/tag //;
                    $table->addRow("","","","","",wrap("","","Tag: $tagforzip"));
                    $tableRowAdded = "TRUE";
                  }
                }
              }
            } # end of for loop
          }
          elsif ($rname =~ /Change repository size/) {
          my @arglist = split(/\s/, $rargs);
          $table->addRow($rhost,$rtime,$etime,$rname,$rstatus,wrap("","","New size: @arglist[1] MB"));
            $tableRowAdded = "TRUE";
            if (scalar(@arglist) > 2) {
            $table->addRow("","","","",wrap("","","Old size: @arglist[2] MB"));
            $tableRowAdded = "TRUE";
            }
          }
        elsif ($rname =~ /Change repository path/) {
            my @arglist = split(/\s/, $rargs);
            $table->addRow($rhost,$rtime,$etime,$rname,$rstatus,wrap("","","New path: @arglist[0]"));
            $tableRowAdded = "TRUE";
          if (scalar(@arglist) > 3) {
            $table->addRow("","","","",wrap("","","Old path: @arglist[3]"));
            $tableRowAdded = "TRUE";
            }
        }
          else {
            $table->addRow($rhost,$rtime,$etime,$rname,$rstatus,wrap("","",$rargs));
            $tableRowAdded = "TRUE";
          }
        }
        else {
        if ($rname =~ /Run Real Time scan/) {
        }
        else  {
            $table->addRow($rhost,$rtime,$etime,$rname,$rstatus, "");
            $tableRowAdded = "TRUE";
        }
        }
        if ($tableRowAdded eq "TRUE") {
            $table->addRowLine();
        }
        #write;
      }
    }
  }
  dbg(DBG_NOTE,"Could not print stored actions\n");
  return FAILED;

}

#
#==== printDirectories  ====#
#
sub printDirectories
{
my $tfa_home   = shift;
my $node_list  = shift;
my $comp       = shift;
my $policy     = shift;
my $permission = shift;
dbg(DBG_VERB, "In printDirectories\n");
my $localhost=tolower_host();
if (isTFARunning($tfa_home) == FAILED) {
        exit 0;
}
my @nodelist;
my @comps;
my $nodename;
my $compname;
if(defined $node_list){
  if($node_list eq "local" || $node_list eq ""){
    @nodelist[0]=$localhost;
  }
  elsif($node_list eq "all"){
    @nodelist = getListOfAllNodes( $tfa_home );
  }
  else{
    # checking validity of nodes
    $node_list =~ tr/A-Z/a-z/;
    @nodelist = split(/\,/,$node_list);
    foreach $nodename (@nodelist) {
       if (isNodePartOfCluster($tfa_home, $nodename)) {
       }
       else {
         print "Node $nodename is not part of TFA cluster\n";
         exit 0;
       }
    }
   }
}

if ( defined $comp ) {
   # checking validity of components
   @comps = split(/\,/,$comp);
   foreach $compname (@comps) {
      if ( not exists $tfactlglobal_xmlcompshash{lc($compname)} ) {
         print "$compname is not a valid component.\n";
         undef %tfactlglobal_usersxmlcompshash;
         exit 0;
      }
   }
}
dbg(DBG_VERB, "Running printDirectories through Java CLI\n");
my $message ="$localhost:printdirectories:$comp:$policy:$permission:$node_list";
my $command = buildCLIJava($tfa_home,$message);
dbg(DBG_VERB, "$command\n");
my $line;


#my @nodelist = split("\,",$NODE_NAMES);
#my @nodelist = getListOfAllNodes( $tfa_home );

my %TABLES;
my $nodeName;
my @DIRS;
foreach (@nodelist) {
        $nodeName = $_;
        #print "$nodeName\n";
        #@DIRS = getTFADirectories($tfa_home, $nodeName);
        #print "@DIRS\n";
        my $tb = Text::ASCIITable->new();
        $tb->setCols("Trace Directory", "Component", "Permission", "Added By");
        $tb->setColWidth("Trace Directory", $tputcols-45);
        $tb->setOptions({"outputWidth" => $tputcols, "headingText" => $nodeName});
        $TABLES{$nodeName} = $tb;
}

$Text::Wrap::columns = $tputcols-45;

my $table;
my $offlinemode = 0;
my $paramfile = tfactlshare_getSetupFilePath($tfa_home);
if ( isOfflineMode($paramfile) ){
  $offlinemode = 1;
}
my @cli_output = tfactlshare_runClient($command);
foreach $line ( @cli_output )
{
if ( $line eq "DONE") {
       if($offlinemode == 1){
        }
        else{
       printReDiscoveryStats($tfa_home);
        my $key_entry;
        my $value;
        while (($key_entry, $value) = each(%TABLES)) {
                print $TABLES{$key_entry}."\n";
        }
	}
        dbg(DBG_WHAT,"#### All Stored Scan Directories Printed ####\n");
        return SUCCESS;
}
else {
  if ($line =~ /Connection refused/) {
    my ($msg, $hostname) = split(/!/, $line);
    delete $TABLES{$hostname};
    print "Failed to establish connection to remote host $hostname\n";
  }
  else {
    if ( $offlinemode == 1 ) {
                print "$line\n";
        }
        else{
    my ($dirpath, $hostname, $component, $permission, $owner, $collectionpolicy, $collectall) = split(/!/, $line);
    $table = $TABLES{$hostname};
    if (defined($table)) {
        $table->addRow(wrap("","",$dirpath),$component, $permission, $owner);
      #$table->addRow("Resource : $component" );
      if ($collectionpolicy eq "exclusions") {
        $table->addRow("Collection policy : Exclusions");
      }
      elsif ($collectionpolicy eq "noexclusions") {
        $table->addRow("Collection policy : No Exclusions");
      }
      elsif ($collectionpolicy eq "collectall") {
        $table->addRow("Collection policy : Collect All");
      }
      #$table->addRow("Collect All : $collectall");
      #$table->addRow("Permission: $permission","","");
      #$table->addRow("Added by: $owner","","");
      $table->addRowLine();
    }
   }
  }
}
}

dbg(DBG_NOTE,"Could not print stored directories\n");
return FAILED;

}

#
#======================= printRunMode ===========================#
#
sub printRunMode
{
  my $tfa_home = shift;
  my $mode;
  dbg(DBG_VERB, "In printRunMode\n");
  my $localhost=tolower_host();
  #Check whether TFA Main is running or not
  if (isTFARunning($tfa_home) == FAILED) {
        exit 0;
  }
  $mode = getTFARunMode($tfa_home);
  if ( $mode ) {
    print "TFA Run Mode: $mode\n";
  }
  else {
   print "TFA Run Mode: COLLECTOR\n";
  }
}

############### Print Ongoing Collections ############
sub printOngoingCollections
{
        my $tfa_home = shift;
        my $localhost=tolower_host();
        my $status;
        my $line;
      
        my $table = Text::ASCIITable->new();
        $table->setCols("HOST", "STATUS", "TAG", "ZIP");
        $table->setColWidth("TAG", $tputcols-60);
        $table->setColWidth("ZIP", $tputcols-60);
        $table->setOptions({"outputWidth" => $tputcols, "headingText" => "TFA Collections"});

        my @collections = getOngoingCollections( $tfa_home );
        $status = shift @collections;

        if ( $status == -1 ) {
                print "Unable to determine the running collections. Please try again later.\n";
                return SUCCESS;
        }

        if ( $status == 0 ) { 
                foreach $line ( @collections )
                {
                        if ( $line =~ /!/ ) {
                                my @list = split( /!/, $line );
                                $table->addRow( $list[1], $list[2], $list[3], $list[4]);
                        }
                }
                print "$table\n";

        } else {
                print "Currently there are NO COLLECTIONS running on $localhost\n";
        }

        return SUCCESS;
}

sub printTFALog
{
  my $tfa_home = shift;
  my $localhost = tolower_host();
  my $message = "$localhost:printlog";
  my $command = buildCLIJava($tfa_home, $message);
  my $line;
  my $t = localtime();
  print "$t\n";
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {

    if ($line eq "DONE") {
        dbg(DBG_WHAT, "Successfully printed log");
        return SUCCESS;
    }
    elsif ($line =~ /Node:/) {
        print "\n$line\n\n";
    }
    elsif ($line =~ /Connection refused/) {
    }
    else {
        print " $line\n";
    }
  }
  dbg(DBG_WHAT, "Failed to print log");
  return FAILED;
}

#======================= printInventory ===========================#
#
sub printInventory
{
  #my ($tfa_home, $sr) = @_;
  #if ($sr) {dbg(DBG_VERB, "In printInventory for sr : $sr\n");}
  #else {dbg(DBG_VERB,  "In printInventory for All Files\n");}
  my $tfa_home = shift;
  my $node_list = shift;
  my $localhost=tolower_host();
  my @nodelist;
  my $nodename;
  if(defined $node_list){
    if($node_list eq "local" || $node_list eq ""){
      @nodelist[0]=$localhost;
    }
    elsif($node_list eq "all"){
      @nodelist = getListOfAllNodes( $tfa_home );
      my $EXADATA = isExadataConfigured( $tfa_home );
      if ( $EXADATA == 1 ) { 
        my @CELLS = getOnlineCells( $tfa_home );
        @nodelist = (@nodelist, @CELLS );
      }     
    }
    else{ 
      # checking validity of nodes
      $node_list =~ tr/A-Z/a-z/;
      @nodelist = split(/\,/,$node_list);
      foreach $nodename (@nodelist) {
        if (isNodePartOfCluster($tfa_home, $nodename)) {
        }
        else {
         print "Node $nodename is not part of TFA cluster\n";
         exit 0;
        }
      }
    }
  }
  dbg(DBG_VERB, "Running printInventory through Java CLI\n");
  my $message ="$localhost:printinventory:$node_list";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "$command\n");


  #my @nodelist = split("\,",$NODE_NAMES);
  #my @nodelist = getListOfAllNodes( $tfa_home );

  my %TABLES;
  my $nodeName;
  my @DIRS;
  foreach (@nodelist) {
        $nodeName = $_;
        my $tb = Text::ASCIITable->new();
        $tb->setCols("FILE NAME", "LAST MODIFIED", "FIRST TIME", "LAST TIME");
        $tb->setColWidth("FILE NAME", $tputcols-60);
        $tb->alignCol("FILE NAME", "left");
        $tb->setOptions({"outputWidth" => $tputcols, "headingText" => $nodeName});
        $TABLES{$nodeName} = $tb;
  }

  $Text::Wrap::columns = $tputcols-45;

  my $table;

  my ($line, $fname, $lastmodified, $ftype, $firstts, $lastts, $fsize, $hostname);
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
  if ( $line eq "DONE") {
        my $key_entry;
        my $value;

        while (($key_entry, $value) = each(%TABLES)) {
                print $TABLES{$key_entry}."\n";
        }
        #print $tb;
        dbg(DBG_WHAT,"#### Stored TFA files Printed ####\n");
        return SUCCESS;
  }
  else {
        if ($line =~ /Connection refused/) {
                ($fname, $lastmodified, $ftype, $firstts, $lastts, $fsize, $hostname) = split(/!/, $line);
                delete $TABLES{$hostname};
        } else {
                ($fname, $lastmodified, $ftype, $firstts, $lastts, $fsize, $hostname) = split(/!/, $line);
                $table = $TABLES{$hostname};

                if (defined($table)) {
                        $table->addRow(wrap("","",$fname), $lastmodified, $firstts, $lastts);
                        $table->addRow("Size : $fsize kb");
                        if ($ftype eq "null") {
                                $ftype = "Not defined";
                        }
                        $table->addRow("Type : $ftype");
                        $table->addRowLine();
                }
        }
    }
  }
  dbg(DBG_WHAT,"Could not print stored TFA files\n");
  return FAILED;

}

#======================= printInventoryRunStatus  ==========================#
sub printInventoryRunStatus
{
my $tfa_home = shift;
dbg(DBG_WHAT, "In printInventoryRunStatus\n");
my $localhost=tolower_host();

dbg(DBG_WHAT, "Running printInventoryRunStatus through Java CLI\n");
my $message ="$localhost:printinvrunstat";
my $command = buildCLIJava($tfa_home,$message);
dbg(DBG_VERB, "$command\n");


my $tb = Text::ASCIITable->new();
$tb->setCols("Host Name", "Last Run Started", "Last Run Ended", "Status");
$tb->setOptions({"outputWidth" => $tputcols, "headingText" => "Inventory Run Statistics"});

my $line;
my $flag = 0;
my @cli_output = tfactlshare_runClient($command);
foreach $line ( @cli_output )
{
#print "$line\n";
if ( $line eq "DONE") {
    #dbg(DBG_WHAT,"#### Status Done ####\n");
    #print $tb;
    #return SUCCESS;
    $flag = 1;
}
else {
  my @statistics = split(/!/, $line);
  if ($line =~ /Connection refused/) {
  }
  else {
    $tb->addRow($statistics[0],$statistics[1],$statistics[2],$statistics[3]);
  }
}
}

my $EXADATA = isExadataConfigured( $tfa_home);

if ( $EXADATA == 1 ) {

        use POSIX;

        my $TFA_HOME = $tfa_home;

        my @CELLS = getOnlineCells( $TFA_HOME );
        my $CELL;
        my $STATUS;
        my $START;
        my $END;
        my $FORMAT = "%b %e %H:%M:%S";

        foreach $CELL ( @CELLS ) {
                $STATUS = "COMPLETE";

                $START = getCellInvStartTime( $TFA_HOME, $CELL );
                $END = getCellInvEndTime( $TFA_HOME, $CELL );

                if ( $START >= $END ) {
                        $STATUS = "RUNNING";
                }

                if ( $START != 0 ) {
                        $START = strftime $FORMAT, localtime( $START );
                } else {
                        $START = "-";
                }

                if ( $END != 0 ) {
                        $END = strftime $FORMAT, localtime( $END );
                } else {
                        $END = "-";
                }

                $tb->addRow( $CELL, $START, $END, $STATUS );
        }
}



if ( $flag ) {
        dbg(DBG_WHAT,"#### Status Done ####\n");
        print $tb;
        return SUCCESS;
}

dbg(DBG_WHAT,"Could not print current inventory run status\n");
return FAILED;

}

sub printAdrIncidents
{
  my $tfa_home = shift;
  dbg(DBG_WHAT, "In printAdrIncidents\n");
  my $localhost=tolower_host();
  
  dbg(DBG_WHAT, "Running printAdrIncidents through Java CLI\n");
  my $message ="$localhost:printadrincidents";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_WHAT, "$command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
  print "$line\n";
  if ( $line eq "DONE") {
      dbg(DBG_WHAT,"#### All Stored ADR Incidents Printed ####\n");
      return SUCCESS;
  }
  }
  dbg(DBG_WHAT,"Could not print stored ADR incidents\n");
  return FAILED;
}

#
#======================= printStartups ===========================#
#
sub printStartups
{
  my $tfa_home = shift;
  dbg(DBG_WHAT, "In printStartups\n");
  my $localhost=tolower_host();

  dbg(DBG_WHAT, "Running printStartups through Java CLI\n");
  my $message ="$localhost:printstartups";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_WHAT, "$command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
  print "$line\n";
  if ( $line eq "DONE") {
      dbg(DBG_WHAT,"#### All Stored Startups Printed ####\n");
      return SUCCESS;
  }
  }
  dbg(DBG_WHAT,"Could not print stored startups\n");
  return FAILED;

}

#
#======================= printShutdowns ===========================#
#
sub printShutdowns
{
  my $tfa_home = shift;
  dbg(DBG_WHAT,  "In printShutdowns\n");
  my $localhost=tolower_host();

  dbg(DBG_WHAT, "Running printShutdowns through Java CLI\n");
  my $message ="$localhost:printshutdowns";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_WHAT, "$command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
  print "$line\n";
  if ( $line eq "DONE") {
      dbg(DBG_WHAT,"#### All Stored Shutdowns Printed ####\n");
      return SUCCESS;
  }
  }
  dbg(DBG_WHAT,"Could not print stored shutdowns\n");
  return FAILED;

}


#
#======================= printParameters ===========================#
#
sub printParameters
{
  my $tfa_home = shift;
  dbg(DBG_WHAT, "In printParameters\n");
  my $localhost=tolower_host();

  dbg(DBG_WHAT, "Running printParameters through Java CLI\n");
  my $message ="$localhost:printparameters";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_WHAT, "$command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
  print "$line\n";
  if ( $line eq "DONE") {
      dbg(DBG_WHAT,"#### All Stored Parameters Printed ####\n");
      return SUCCESS;
  }
  }
  dbg(DBG_WHAT,"Could not print stored parameters\n");
  return FAILED;

}

#
#======================= printErrors ===========================#
#
sub printErrors
{
  my $tfa_home = shift;
  dbg(DBG_WHAT, "In printErrors\n");
  my $localhost=tolower_host();

  dbg(DBG_WHAT, "Running printErrors through Java CLI\n");
  my $message ="$localhost:printerrors";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_WHAT, "$command\n");
  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
  print "$line\n";
  if ( $line eq "DONE") {
      dbg(DBG_WHAT,"#### All Stored Errors Printed ####\n");
      return SUCCESS;
  }
  }
  dbg(DBG_WHAT,"Could not print stored errors\n");
  return FAILED;

}

#
#======================= printCollections ===========================#
#
sub printCollections {
  my ($tfa_home, $coll_time) = @_;
  dbg(DBG_WHAT, "In printCollections \n");
  my $localhost = tolower_host();

  my $message;
  if (defined $coll_time) {
    $message = "$localhost:printcollections:$coll_time";
  }
  else {
    $message = "$localhost:printcollections";
  }
  
  dbg(DBG_WHAT, "Running printCollections through Java CLI \n");
  my $command = buildCLIJava($tfa_home, $message);
  dbg(DBG_WHAT, "$command\n");
  my $table = Text::ASCIITable->new();
  $table->setCols("Collection Id", "Nodelist", "Collection Time", "Collection Details");
  #$table->setColWidth("Collection Details", 40);
  $table->setOptions({"outputWidth" => $tputcols});
  $Text::Wrap::columns = $tputcols-30;

  my $line;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output ) {
    #print "$line\n";
    if ($line eq "NO COLLECTIONS TO PRINT") {
        print "No diagnostic collections to print in TFA\n";
    }
    elsif ($line eq "SUCCESS") {
        dbg(DBG_WHAT, "#### All Stored Collections Printed #### \n");
        print "$table\n";
        return SUCCESS;
    }
    else {
	my ($collid, $collType, $requestUser, $nodelist, $masternode, $start, $end, $tag, $zip, $comps, $zipSize, $time, $events) = split(/!/, $line);
    if (defined($table)) {
        $table->addRow($collid,wrap("","",$nodelist),"Start Time: $start",wrap("","","Tag: $tag"));
	$table->addRow($collType,"Initiating node: $masternode","End Time: $end",wrap("","","Zip: $zip"));
	if (defined($events)) {
		$table->addRow("Events: $events","","", wrap("","","Components: $comps"));
        } else {
		$table->addRow("","","", wrap("","","Components: $comps"));
	}
	$table->addRow("Request User: $requestUser","","", wrap("","","Zip Size: $zipSize"));
	$table->addRow("","","", wrap("","","Time Taken: $time s"));
        $table->addRowLine();
       }
    }
  }
  dbg(DBG_WHAT, "Could not print stored errors \n");
  return FAILED;
}

sub printProblemSets {
  my $tfa_home = shift;
  dbg(DBG_WHAT, "In printProblemSets \n");
  my $localhost = tolower_host();

  dbg(DBG_WHAT, "Running printProblemSets through Java CLI \n");
  my $message = "$localhost:printproblemsets";
  my $command = buildCLIJava($tfa_home, $message);
  dbg(DBG_WHAT, "$command\n");
  my $line;
  my $choice;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output ) {
    if ($line eq "DONE") {
        dbg(DBG_WHAT, "#### All Stored ProblemSets Printed #### \n");
        $choice = <STDIN>;
        chomp($choice);
        print "Option chosen: $choice\n";
        runTasks($tfa_home, $choice);
        return SUCCESS;
    }
    elsif ($line =~ /INVALID INPUT/) {
        print "Invalid option chosen $choice\n";
    }
    elsif ($line eq "FAILED") {
        return FAILED;
    }
    else {
        print "$line\n";
    }
  }
  dbg(DBG_WHAT, "Could not print stored problemsets \n");
  return FAILED;
}

sub printEvents
{
  my ($tfa_home, $event_time) = @_; 
  my $localhost = tolower_host();
  my $message;
  if (defined $event_time) {
    $message = "$localhost:printevents:$event_time";
  }
  else {
    $message = "$localhost:printevents:";
  }
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "$command\n");
  my $line;
  my $tb = Text::ASCIITable->new();
  $tb->setCols("Event Id", "Node", "Event Type", "Event Time", "Event Information");
  $tb->setColWidth("Event Type", 15);
  $tb->setOptions({"outputWidth" => $tputcols});
  $Text::Wrap::columns = $tputcols-60;
  my $summary;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
    if ( $line eq "DONE") {
      dbg(DBG_WHAT,"#### All Lines Printed ####\n");
      if (! (defined $event_time) ) {
        print "\nDisplaying list of events since the previous day\n\n";
      }     
      print $tb;
      print "\nSummary of events:\n";
      print $summary;
      return SUCCESS;
    } elsif ( $line =~ /found in database/) {
      $summary .= "$line\n";
    } else {
      my @eventinfo = split(/!/, $line);
      $tb->addRow(wrap("","",$eventinfo[0]), $eventinfo[1], $eventinfo[2], $eventinfo[3],  wrap("","","File Name : $eventinfo[4]"));
      if (defined $eventinfo[5]) {
        if ($eventinfo[2] eq "Generic") {
          $tb->addRow("","","",wrap("","","\nEvent Line : \n$eventinfo[5]"));
        }
        elsif ($eventinfo[2] eq "Instance Shutdown") {
          $tb->addRow("","","",wrap("","","\nProcess Type : \n$eventinfo[5]"));
        }
        elsif ($eventinfo[2] eq "Cluster Eviction") {
          $tb->addRow("","","",wrap("","","\nNode Name : \n$eventinfo[5]"));
        }
        elsif ($eventinfo[2] eq "Cluster Reconfiguration") {
          $tb->addRow("","","",wrap("","","\nNumber of Nodes : $eventinfo[5]"));
        }
        elsif ($eventinfo[2] eq "Database General Error") {
          $tb->addRow("","","",wrap("","","\nError Code : \n$eventinfo[5]"));
        }
      }
      $tb->addRowLine();
    }
  }
  return FAILED;
}

########
# NAME
#   tfactlprint_components
#
# DESCRIPTION
#   This routine prints XML components
#
# PARAMETERS
#
# RETURNS
#
########
sub tfactlprint_components {
  my $tfa_home = shift;
  my $table = Text::ASCIITable->new();
  my $printAll = not @ARGV;

  $table->setCols("Field","Value");
  $table->setOptions({"outputWidth" => $tputcols, "headingText" => "XML Components" });

  for my $ndx ( 0 .. $#xmlcompsarray ) {
    my $compname = $xmlcompsarray[$ndx][COMPNAME];
    my $compvalidate = $xmlcompsarray[$ndx][COMPVALIDATE];
    my $compaltname = $xmlcompsarray[$ndx][COMPALTNAME];
    my $compdescription = $xmlcompsarray[$ndx][COMPDESCRIPTION];
    my $compinstancehome = $xmlcompsarray[$ndx][COMPINSTANCEHOME];
    my $comptyperef = $xmlcompsarray[$ndx][COMPTYPE];
    my $comptype = "@$comptyperef";
    my $compconfig = $xmlcompsarray[$ndx][COMPCONFIG];
    # Get subcomponents
    my $compsubcomps = "";
    my $subxmlcompsarrayref = $xmlcompsarray[$ndx][COMPSUB];
    my @subcompsderef = @$subxmlcompsarrayref;

    if ( exists $tfactlglobal_usersxmlcompshash{lc($compname)} || $printAll ) {
    for my $idx ( 0 .. $#subcompsderef ) {
       my $subcompref = $subcompsderef[$idx];
       my @subcomps = @$subcompref;
       $compsubcomps .= "name:" . $subcomps[SUBCOMPNAME] . " " . 
                        "required:" . $subcomps[SUBCOMPREQUIRED] . " " .
                        "default:" . $subcomps[SUBCOMPDEFAULT] . "\n";
    } # end for $#subcompsderef

    # Get also-collects
    my $compalsocollects = "";
    my $alsocollectarrayref = $xmlcompsarray[$ndx][COMPALSO];
    my @alsocollectderef = @$alsocollectarrayref;
    for my $idx ( 0..$#alsocollectderef ) {
      $compalsocollects .= $alsocollectderef[$idx] . "\n";
    }

    $table->alignCol("Value","left");
    $table->addRow("Name",$compname) if defined $compname && length $compname;
    $table->addRow("Description",$compdescription) if defined $compdescription &&
          length $compdescription;
    $table->addRow("Instance Home",$compinstancehome) if defined $compinstancehome &&
          length $compinstancehome;
    $table->addRow("Alt. Name",$compaltname) if defined $compaltname && length $compaltname;
    $table->addRow("Comp. Types",$comptype) if defined $comptype && length $comptype;
    $table->addRow("Configuration",$compconfig) if defined $compconfig &&
          length $compconfig;
    $table->addRow("Subcomponents",$compsubcomps) if defined $compsubcomps &&
          length $compsubcomps;
    $table->addRow("Also collect",$compalsocollects) if defined $compalsocollects &&
          length $compalsocollects;
    $table->addRowLine();
    } # end if tfactlglobal_usersxmlcompshash{lc($compname)}
  } # end for $#xmlcompsarray

  print $table;
  return;
}

########
## NAME
##   tfactlprint_components
##
## DESCRIPTION
##   This routine prints XML components
##
## PARAMETERS
##
## RETURNS
##
#########
sub tfactlprint_suspended_ips {
  my $tfa_home = shift;
  my $localhost = tolower_host();
  my $message ="$localhost:getsuspendedips";
  my $command = buildCLIJava($tfa_home,$message);
  my $table = Text::ASCIITable->new();

  $table->setCols("CollectionId","Suspended time");
  $table->setOptions({"outputWidth" => $tputcols, "headingText" => "Suspended TFA IPS collections" });

  my @cli_output = tfactlshare_runClient($command);
  foreach my $line ( @cli_output ) {
     if ( $line =~ /(\S*)(.*)/ ) {
       my $collectionid = $1;
       my $rem = $2;
       $rem =~ s/$collectionid\s//g;
       if ( $rem =~ /([^\/]*)([^-]*)(.*)/ ) {
         my $timestamp = $1;
         my $colldir   = $2;
         my $opts      = $3;
         # print "collid: $collectionid \n";
         # print "1: $1, 2: $2, 3 : $3  \n";
         if ( length $collectionid && length $timestamp ) {
           $table->addRow($collectionid,$timestamp);
           $table->addRowLine();
         }
       }
     }
  } # end foreach

  print $table;  

  return;
}

##################################
### NAME
###   tfactlprint_configuredComputeNodes
###
### DESCRIPTION
###   This routine prints list of Compute Nodes
###
### PARAMETERS 
###
### RETURNS
###
##################################

sub tfactlprint_configuredComputeNodes {
  my $tfa_home = shift;
  dbg(DBG_VERB, "In tfactlprint_configuredComputeNodes\n");
  my @nodes = tfactlshare_getConfiguredComputeNodes($tfa_home);
  my $node;

  foreach $node (@nodes) {
    print "Compute Node : $node\n";
  }
}

########
### NAME
###   tfactlprint_protocols
###
### DESCRIPTION
###   This routine prints list of available and restricted protocols clusterwide
###
### PARAMETERS
###
### RETURNS
###
##########
sub tfactlprint_protocols {
  my $tfa_home = shift;
  dbg(DBG_VERB, "In tfactlprint_protocols\n");
  my $localhost=tolower_host();
  my @nodelist = getListOfAllNodes( $tfa_home );
  if (isTFARunning($tfa_home) == FAILED) {
        exit 0;
  }
  dbg(DBG_VERB, "Running tfactlprint_protocols through Java CLI\n");
  my $message ="$localhost:printprotocols";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "$command\n");
  my $line;
  my %TABLES;
  my $nodeName;
  my @DIRS;
  foreach (@nodelist) {
        $nodeName = $_;
        my $tb = Text::ASCIITable->new();
	$tb->setCols("Protocols");
        $tb->setOptions({"outputWidth" => $tputcols, "headingText" => $nodeName});
        $TABLES{$nodeName} = $tb;
  }
  $Text::Wrap::columns = $tputcols-45;
  my @cli_output = tfactlshare_runClient($command);
  foreach $line ( @cli_output )
  {
     #print "line $line\n";
     if ( $line eq "DONE") {
	my $key_entry;
        my $value;
        while (($key_entry, $value) = each(%TABLES)) {
                print $TABLES{$key_entry}."\n";
        }
        return SUCCESS;
     }
     else {
        if ($line =~ /Connection refused/) {
           my ($msg, $hostname) = split(/!/, $line);
           delete $TABLES{$hostname};
           print "Failed to establish connection to remote host $hostname\n";
        }
        else {
	   my ($msg, $hostname) = split(/!/, $line);
           my $table = $TABLES{$hostname};
           if (defined($table)) {
              $table->addRow($msg);                                                                                                                                              
           }
        }
     }
  }
  return FAILED;
}

########
#### NAME
####   tfactlprint_ipaddress
####
#### DESCRIPTION
####   This routine prints ip addresses of all nodes 
####
#### PARAMETERS
####
#### RETURNS
####
###########
#For now getting only priv IP's
sub tfactlprint_ipaddress
{
  my $tfa_home = shift;
  dbg(DBG_VERB, "In tfactlprint_ipaddress\n");
  my $localhost=tolower_host();
  my @nodelist = getListOfAllNodes($tfa_home);
  if (isTFARunning($tfa_home) == FAILED) {
    exit 0;
  }
  my $message ="$localhost:printipaddress";
  my $command = buildCLIJava($tfa_home,$message);
  dbg(DBG_VERB, "$command\n");
  my @cli_output = tfactlshare_runClient($command);
  foreach my $line ( @cli_output ) {
    dbg(DBG_VERB,"$line\n");
    if ($line eq "DONE") {
      return SUCCESS;
    }
    else {
      print "$line\n";
    }
  }
  return FAILED;
}
