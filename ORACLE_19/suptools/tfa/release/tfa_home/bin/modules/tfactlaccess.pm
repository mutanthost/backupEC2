# 
# $Header: tfa/src/v2/tfa_home/bin/modules/tfactlaccess.pm /main/29 2018/08/09 22:22:30 recornej Exp $
#
# tfactlaccess.pm
# 
# Copyright (c) 2014, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlaccess.pm 
#
#    DESCRIPTION
#      Add or Remove or List TFA Users 
#
#    NOTES
#     
#
#    MODIFIED   (MM/DD/YY)
#    recornej    07/30/18 - Fix exitcodes
#    manuegar    07/13/18 - manuegar_multibug_01.
#    recornej    05/16/18 - Do not add user if user does not have access to
#                           java
#    migmoren    04/16/18 - Bug 27605951 - VARIOUS TYPOS IN TFACTL MESSAGING
#    bburton     03/19/18 - Bug 27665984 - remove use of POSIX::tmpnam
#    manuegar    10/13/17 - Bug 26953418 - SOLSP64-181-TFA: OPTION
#                           "REMOVEACCESS/ADDACCESS" ARE NOT LISTED IN COMMAND
#                           HELP.
#    cnagur      04/07/17 - Removed Error Message 103 - Bug 24971982
#    cnagur      02/14/17 - Non Root Daemon Changes
#    bibsahoo    05/23/16 - FIX BUG 21887154 - [12201-LIN64-TFA]ACCESS ADD
#                           SHOULD CHECK USER/GRP EXISTENCE ON REMOTE NODE
#    manuegar    04/19/16 - Dynamic help.
#    manuegar    04/11/16 - Setup user directories for support tools.
#    cnagur      04/07/16 - Fix for Bug 23052798
#    manuegar    03/31/16 - Performance improvement for tfactl.
#    arupadhy    01/17/16 - windows user validation
#    bibsahoo    12/21/15 - FIX BUG 22064785 - LNX64-12.2-TFA:ACCESS LSUSERS
#                           PRINT INCORRECT STATUS OF REMOTE NODES
#    bburton     09/11/15 - XbranchMerge bburton_bug-21517347 from
#                           st_tfa_12.1.2.5
#    bibsahoo    08/23/15 - Adding Error Statements when certificates are not
#                           generated
#    gadiga      08/04/15 - setup suptools directory for user
#    manuegar    05/12/15 - Bug 18220041 - LNX64-12.1-TFA:ADD OPTION TO SHOW
#                           STATUS OF ALL NODES WITH TFACTL ACCESS LSUSER.
#    manuegar    04/23/15 - Setup IPS directories for non root users.
#    manuegar    04/17/15 - Bug 18658721 - LNX64-12.1-TFA-SCS:NEED DISALLOW ADD
#                           ROOT AS NON-ROOT ACCESS USER.
#    bburton     01/14/15 - Bug 20351923 - Do not do addRowLine (---) before a
#                           row exists.
#    manuegar    12/18/14 - LNX64-12.2-TFA-SCS:ACCESS DISABLE DID NOT GIVE
#                           EXPECTED RESPONSE TO "-H
#    cnagur      09/15/14 - Added access update - Bug 19607799
#    manuegar    07/21/14 - Relocate tfactl_lib
#    manuegar    07/04/14 - Creation
#
############################ Functions List #################################
#
# listTFAUsers
# addTFAUser
# addTFAGroup
# removeTFAUser
# blockTFAUser
# blockTFAGroup
# unblockTFAUser
# unblockTFAGroup
# removeTFAUserFromGroup
# removeAllUsers
# resetTFAUsers
# getUserID
# getGroupID 
#
#############################################################################

package tfactlaccess;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(tfactlaccess_init
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
use osutils;

#################### tfactlaccess Global Constants ####################

my (%tfactlaccess_cmds) = (access      => {},
                         );


#################### tfactlaccess Global Variables ####################

sub is_tfactl
{
  return 1;
}


########
# NAME
#   tfactlaccess_init
#
# DESCRIPTION
#   This function initializes the tfactlaccess module.  For now it 
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
  push (@tfactlglobal_command_callbacks, \&tfactlaccess_process_cmd);
  push (@tfactlglobal_help_callbacks, \&tfactlaccess_process_help);
  push (@tfactlglobal_command_list_callbacks, \&tfactlaccess_get_tfactl_cmds);
  push (@tfactlglobal_is_command_callbacks, \&tfactlaccess_is_cmd);
  push (@tfactlglobal_is_wildcard_callbacks, \&tfactlaccess_is_wildcard_cmd);
  push (@tfactlglobal_syntax_error_callbacks, \&tfactlaccess_syntax_error);
  push (@tfactlglobal_no_instance_callbacks, \&tfactlaccess_is_no_instance_cmd);
  %tfactlglobal_cmds = (%tfactlglobal_cmds, %tfactlaccess_cmds);

  #Perform TFACTL consistency check if enabled
  if($tfactlglobal_hash{'consistchk'} eq 'y')
  {
     if(!tfactlshare_check_option_consistency(%tfactlaccess_cmds))
     {   
       exit 1;
     }
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlaccess init", 'y', 'n');

}

########
# NAME
#   tfactlaccess_process_cmd
#
# DESCRIPTION
#   This routine calls the appropriate routine to process the command 
#   specified by $tfactlglobal_hash{'cmd'}.
#
# PARAMETERS
#   dbh       (IN) - initialized database handle, must be non-null.
#
# RETURNS
#   1 if command is found in the tfactlaccess module; 0 if not.
#
# NOTES
#   Only tfactl_shell() calls this routine.
########
sub tfactlaccess_process_cmd 
{
  my ($retval) = 0;
  my ($succ)   = 0;

  # Get current command from global value, which is set by 
  # tfactlaccess_parse_tfactl_args()and by tfactl_shell().
  my ($cmd) = $tfactlglobal_hash{'cmd'};

  # Declare and initialize hash of function pointers, each designating a 
  # routine that processes an tfactlaccess command.
  my (%cmdhash) = ( access       => \&tfactlaccess_process_access,
                  );

  if (defined ( $cmdhash{ $cmd } ))
  {    # If user specifies a known command, then call routine to process it. #
    $retval = $cmdhash{ $cmd }->();
    $succ = 1;
  }

  tfactlshare_trace(3, "tfactl (PID = $$) tfactlaccess tfactlaccess_process_cmd", 'y', 'n');
  return ($succ, $retval);
}

########
# NAME
#   tfactlaccess_process_access
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
#   Only tfactlaccess_process_cmd() calls this function.
########
sub tfactlaccess_process_access
{
 my $retval = 0;

 tfactlshare_trace(3, "tfactl (PID = $$) tfactlaccess tfactlaccess_process_access", 'y', 'n');

  # Read the commands
  @ARGV = @tfactlglobal_argv;
  my $command1 = shift(@ARGV);
  my $command2 = shift(@ARGV);
  my $switch_val = $command1;

  if ($switch_val eq "access" ) 
        {    
                my $accesshelp = 0;
                my $invalidaccesscmd = FALSE;

		if ( $current_user ne "root" ) {
                        print "\nAccess Denied: Only TFA Admin can run this command\n\n";
                        exit 1;
                }

                if ( ! $command2 ) {
                  print_help("access");
                  $accesshelp = 1;
                }
           
                if (defined $command2 && ($command2 eq "-h" || $command2 eq "-help")) {
                        print_help("access");
                        return 0;
                }

                $switch_val =  $command2; {
                        if ($switch_val eq "lsusers") { 
                          my $command3 = shift(@ARGV);
                          if ( $command3 eq "-h" || $command3 eq "-help" ) {
                            print_help("access","lsusers");
                            tfactlaccess_clean_env();
                            return 0;
                          }
                          $LISTTFAUSERS = 1; 

                          # Check local or clusterwide
                          my $islocal = $command3;

                          if ( $islocal eq "-local" ) {
                            $ACCESSLOCAL = "-l";
                          }

                          if ( $islocal && $islocal ne "-local" ) {
                            #print_help("access", "Invalid flag $islocal passed\n");
                            print_help("access", "lsusers");
                            tfactlaccess_clean_env();
                            return 1;
                          }

                        } 
                        elsif ($switch_val eq "update" ) {  
                                $UPDATEACCESS = 1; 

                                # Check local or clusterwide
                                my $islocal = shift(@ARGV);

                                if ( $islocal eq "-local" ) {
                                        $ACCESSLOCAL = "-l";
                                }

                                if ( $islocal && $islocal ne "-local" ) {
                                        print_help("access", "Invalid flag $islocal passed\n");
                                        tfactlaccess_clean_env();
                                        return 1;
                                }
                        }
                        elsif ($switch_val eq "enable" ) {
                                my $command3 = shift(@ARGV);

                                if ( $command3 eq "-h" || $command3 eq "-help" ) {
                                  print_help("access","enable");
                                  tfactlaccess_clean_env();
                                  return 0;
                                }

                                $ADDACCESS = 1;

                                # Check local or clusterwide
                                my $islocal = $command3;

                                if ( $islocal eq "-local" ) {
                                        $ACCESSLOCAL = "-l";
                                }

                                if ( $islocal && $islocal ne "-local" ) {
                                        #print_help("access", "Invalid flag $islocal passed\n");
                                        print_help("access","enable");
                                        tfactlaccess_clean_env();
                                        return 1;
                                }
                        }
                        elsif ($switch_val eq "disable" ) {
                                my $command3 = shift(@ARGV);

                                if ( $command3 eq "-h" || $command3 eq "-help" ) {
                                  print_help("access","disable");
                                  tfactlaccess_clean_env();
                                  return 0;
                                }

                                $REMOVEACCESS = 1;

                                # Check local or clusterwide
                                my $islocal = $command3;

                                if ( $islocal eq "-local" ) {
                                        $ACCESSLOCAL = "-l";
                                }

                                if ( $islocal && $islocal ne "-local" ) {
                                        #print_help("access", "Invalid flag $islocal passed\n");
                                        print_help("access", "disable");
                                        tfactlaccess_clean_env();
                                        return 1;
                                }
                        }

                        elsif ($switch_val eq "adddefaultusers" ) {
                                $ADDDEFAULTUSERS = 1;

                                # Check local or clusterwide
                                my $islocal = shift(@ARGV);

                                if ( $islocal eq "-local" ) {
                                        $ACCESSLOCAL = "-l";
                                }

                                if ( $islocal && $islocal ne "-local" ) {
                                        print_help("access", "Invalid flag $islocal passed\n");
                                        tfactlaccess_clean_env();
                                        return 1;
                                }
                        }

                        elsif ($switch_val eq "setupdir" ) {
                                my $command3 = shift(@ARGV);
                                
                                if ( ! $command3 || $command3 eq "-h" ||
                                     $command3 eq "-help" ) {
                                  print_help("access");
                                  tfactlaccess_clean_env();
                                  return 1 if ( ! $command3 );
                                  return 0;
                                }
                                
                                if ( $command3 eq "-user" ) {
                                        my $command4 = shift(@ARGV);
                                        if ( ! $command4 ) {
                                          print_help("access", "Please provide the user name to create directory");
                                          return 1;
                                        }
                                        if ( $command4 eq "-h" || $command4 eq "-help" ) {
                                          print_help("access");
                                          tfactlaccess_clean_env();
                                          return 0;
                                        }
                                        $ADDTFAUSER = 2;
                                        $TFAUSER = $command4;
                                }
                                else {
                                        print_help("access");
                                        tfactlaccess_clean_env();
                                        return FAILED;
                                }
                        }
                        elsif ($switch_val eq "setuptracedir" ) {
                                my $command3 = shift(@ARGV);
     
                                if ( ! $command3 || $command3 eq "-h" ||
                                     $command3 eq "-help" ) {
                                  print_help("access");
                                  tfactlaccess_clean_env();
                                  return 1 if ( ! $command3 );
                                  return 0;
                                }    
     
                                if ( $command3 eq "-user" ) {
                                        my $command4 = shift(@ARGV);
                                        if ( ! $command4 ) {
                                          print_help("access", "Please provide the user name to setup trace directory");
                                        }
                                        if ( $command4 eq "-h" || $command4 eq "-help" ) {
                                          print_help("access");
                                          tfactlaccess_clean_env();
                                          return 0;
                                        }    
                                        $SETUPTRACEDIR = 1; 
                                        $TFAUSER = $command4;
                                }    
                                else {
                                        print_help("access");
                                        tfactlaccess_clean_env();
                                        return 1;
                                }    
                        }
                        elsif ($switch_val eq "add" ) {
                                my $command3 = shift(@ARGV);

                                if ( ! $command3 || $command3 eq "-h" || 
                                     $command3 eq "-help" ) {
                                  print_help("access","add");
                                  tfactlaccess_clean_env();
                                  return 1 if ( ! $command3 );
                                  return 0;
                                }

                                if ( $command3 eq "-user" ) {
                                        my $command4 = shift(@ARGV);
                                        #print_help("access", "Please provide the user name to be added") 
                                        if ( ! $command4 ) {
                                          print_help("access","add");
                                          return 1;
                                        }
                                        if ( $command4 eq "-h" || $command4 eq "-help" ) {
                                          print_help("access","add");
                                          tfactlaccess_clean_env();
                                          return 0;
                                        }
                                        $ADDTFAUSER = 1;
                                        $TFAUSER = $command4;
                                }
                                #elsif ( $command3 eq "-group" ) {
                                #        my $command4 = shift(@ARGV);
                                #        print_help("access", "Please provide the group name to be added") if ( ! $command4 );
                                #        print_help("access") if ( $command4 eq "-h" || $command4 eq "-help" );
                                #        $ADDTFAGROUP =  1;
                                #        $TFAUSER = $command4;
                                #}
                                else {
                                        print_help("access","add");
                                        tfactlaccess_clean_env();
                                        return 1;
                                }

                                # Check local or clusterwide
                                my $islocal = shift(@ARGV);

                                if ( $islocal eq "-local" ) {
                                        $ACCESSLOCAL = "-l";
                                }

                                if ( $islocal && $islocal ne "-local" ) {
                                        #print_help("access", "Invalid flag $islocal passed\n");
                                        print_help("access", "add");
                                        tfactlaccess_clean_env();
                                        return 1;
                                }
                        }
                        elsif ($switch_val eq "reset" ) {
                                my $command3 = shift(@ARGV);

                                if ( $command3 eq "-h" || $command3 eq "-help" ) {
                                  print_help("access","reset");
                                  tfactlaccess_clean_env();
                                  return 0;
                                 }

                                $RESETTFAUSERS = 1;

                                # Check local or clusterwide
                                my $islocal = $command3;

                                if ( $islocal eq "-local" ) {
                                        $ACCESSLOCAL = "-l";
                                }

                                if ( $islocal && $islocal ne "-local" ) {
                                        #print_help("access", "Invalid flag $islocal passed\n");
                                        print_help("access", "reset");
                                        tfactlaccess_clean_env();
                                        return 1;
                                }
                        }

                        elsif ($switch_val eq "allow" ) {
                                my $command3 = shift(@ARGV);

                                if ( ! $command3 || $command3 eq "-h" ||
                                     $command3 eq "-help" ) {
                                  print_help("access");
                                  tfactlaccess_clean_env();
                                  return 1 if ( ! $command3 );
                                  return 0;
                                }

                                #if ( $command3 eq "-user" || $command3 eq "-group" ) {
                                if ( $command3 eq "-user" ) {
                                        my $command4 = shift(@ARGV);
                                        if ( ! $command4 ) {
                                          print_help("access", "Please provide the TFA User to be allowed");
                                          return 1;
                                        }
                                        if ( $command4 eq "-h" || $command4 eq "-help" ) {
                                          print_help("access");
                                          tfactlaccess_clean_env();
                                          return 0;
                                        }
                                        $ADDTFAUSER = 1;
                                        $TFAUSER = $command4;
                                }
                                else {
                                        print_help("access");
                                        tfactlaccess_clean_env();
                                        return 1;
                                }

                                # Check local or clusterwide
                                my $islocal = shift(@ARGV);

                                if ( $islocal eq "-local" ) {
                                        $ACCESSLOCAL = "-l";
                                }

                                if ( $islocal && $islocal ne "-local" ) {
                                        print_help("access", "Invalid flag $islocal passed\n");
                                        tfactlaccess_clean_env();
                                        return 1;
                                }
                        }

                        elsif ($switch_val eq "unblock" ) {
                                my $command3 = shift(@ARGV);

                                if ( ! $command3 || $command3 eq "-h" || 
                                     $command3 eq "-help" ) {
                                  print_help("access","unblock");
                                  tfactlaccess_clean_env();
                                  return 1 if ( !$command3 );
                                  return 0;
                                 }

                                if ( $command3 eq "-user" ) {
                                        my $command4 = shift(@ARGV);
                                        #print_help("access", "Please provide user name to be unblocked") if ( ! $command4 );
                                        if ( ! $command4 ){
                                          print_help("access", "unblock");
                                          return 1;
                                        }
                                        if ( $command4 eq "-h" || $command4 eq "-help" ) {
                                          print_help("access","unblock");
                                          tfactlaccess_clean_env();
                                          return 0;
                                        }
                                        $UNBLOCKTFAUSER = 1;
                                        $TFAUSER = $command4;
                                }
                                #elsif ( $command3 eq "-group" ) {
                                #        my $command4 = shift(@ARGV);
                                #        print_help("access", "Please provide group name to be unblocked") if ( ! $command4 );
                                #        print_help("access") if ( $command4 eq "-h" || $command4 eq "-help" );
                                #        $UNBLOCKTFAGROUP = 1;
                                #        $TFAUSER = $command4;
                                #}
                                else {
                                        print_help("access","unblock");
                                        tfactlaccess_clean_env();
                                        return 1;
                                }

                                # Check local or clusterwide
                                my $islocal = shift(@ARGV);

                                if ( $islocal eq "-local" ) {
                                        $ACCESSLOCAL = "-l";
                                }

                                if ( $islocal && $islocal ne "-local" ) {
                                        #print_help("access", "Invalid flag $islocal passed\n");
                                        print_help("access", "unblock");
                                        tfactlaccess_clean_env();
                                        return 1;
                                }
                        }

                        elsif ($switch_val eq "block" ) {
                                my $command3 = shift(@ARGV);

                                if ( ! $command3 || $command3 eq "-h" || 
                                     $command3 eq "-help" ) {
                                  print_help("access","block");
                                  tfactlaccess_clean_env();
                                  return 1 if ( !$command3 );
                                  return 0;
                                }

                                if ( $command3 eq "-user" ) {
                                        my $command4 = shift(@ARGV);
                                        #print_help("access", "Please provide user name to be blocked") if ( ! $command4 );
                                        if ( ! $command4 ) {
                                          print_help("access", "block");
                                            return 1;
                                        }
                                        if ( $command4 eq "-h" || $command4 eq "-help" ) {
                                          print_help("access","block");
                                          tfactlaccess_clean_env();
                                          return 0;
                                        }
                                        $BLOCKTFAUSER = 1;
                                        $TFAUSER = $command4;
                                }
                                #elsif ( $command3 eq "-group" ) {
                                #        my $command4 = shift(@ARGV);
                                #        print_help("access", "Please provide group name to be blocked") if ( ! $command4 );
                                #        print_help("access") if ( $command4 eq "-h" || $command4 eq "-help" );
                                #        $BLOCKTFAGROUP = 1;
                                #        $TFAUSER = $command4;
                                #}
                                else {
                                        print_help("access","block");
                                        tfactlaccess_clean_env();
                                        return 1;
                                }

                                # Check local or clusterwide
                                my $islocal = shift(@ARGV);

                                if ( $islocal eq "-local" ) {
                                        $ACCESSLOCAL = "-l";
                                }

                                if ( $islocal && $islocal ne "-local" ) {
                                        #print_help("access", "Invalid flag $islocal passed\n");
                                        print_help("access", "block");
                                        tfactlaccess_clean_env();
                                        return 1;
                                }
                        }

                        elsif ($switch_val eq "remove" ) {
                                my $command3 = shift(@ARGV);

                                if ( ! $command3 || $command3 eq "-h" || 
                                     $command3 eq "-help" ) {
                                  print_help("access","remove");
                                  tfactlaccess_clean_env();
                                  return 1 if ( ! $command3 );
                                  return 0;
                                }

                                #if ( $command3 eq "-user" || $command3 eq "-group") {
                                if ( $command3 eq "-user" ) {
                                        my $command4 = shift(@ARGV);
                                        #rint_help("access","Please provide the TFA User to be removed") if ( ! $command4 );
                                        if ( ! $command4 ) {
                                          print_help("access","remove");
                                          return 1;
                                        }
                                        if ( $command4 eq "-h" || $command4 eq "-help" ) {
                                          print_help("access","remove");
                                          tfactlaccess_clean_env();
                                          return 0;
                                        }
                                        $REMOVETFAUSER = 1;
                                        $TFAUSER = $command4;
                                }
                                elsif ( $command3 eq "-all" ) {
                                        $REMOVEALLUSERS = 1;
                                }
                                #elsif ( $command3 eq "-userfromgroup" ) {
                                #        my $command4 = shift(@ARGV);
                                #        print_help("access","Please provide the TFA User to be removed") if ( ! $command4 );
                                #        print_help("access") if ( $command4 eq "-h" || $command4 eq "-help" );
                                #        $RMUSERFROMGP = 1;
                                #        $TFAUSER = $command4;
                                #}
                                else {
                                        print_help("access","remove");
                                        tfactlaccess_clean_env();
                                        return 1;
                                }

                                # Check local or clusterwide
                                my $islocal = shift(@ARGV);

                                if ( $islocal eq "-local" ) {
                                        $ACCESSLOCAL = "-l";
                                }

                                if ( $islocal && $islocal ne "-local" ) {
                                        #print_help("access", "Invalid flag $islocal passed\n");
                                        print_help("access","remove");
                                        tfactlaccess_clean_env();
                                        return 1;
                                }
                        }
                        elsif ($switch_val eq "removeall" ) {
                                my $command3 = shift(@ARGV);

                                if ( $command3 eq "-h" || $command3 eq "-help" ) {
                                  print_help("access","removeall");
                                  tfactlaccess_clean_env();
                                  return 0;
                                 }

                                $REMOVEALLUSERS = 1;

                                # Check local or clusterwide
                                my $islocal = $command3;

                                if ( $islocal eq "-local" ) {
                                        $ACCESSLOCAL = "-l";
                                }

                                if ( $islocal && $islocal ne "-local" ) {
                                        #print_help("access", "Invalid flag $islocal passed\n");
                                        print_help("access", "removeall");
                                        tfactlaccess_clean_env();
                                        return 1;
                                }
                        }
                        else { 
                               if ( defined($command2) && !$accesshelp  ) {
                                 print_help("access");
                                 tfactlaccess_clean_env();
                                 return 1;
                               }
                             }
                }
                # validate access command
                if ( @ARGV || $invalidaccesscmd ) {
                  print_help("access");
                  tfactlaccess_clean_env();
                  return 1;
                }
        }

  # Dispatch the command
  tfactlshare_pre_dispatch();
  $retval = tfactlaccess_dispatch();

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
sub tfactlaccess_dispatch
{
  my $retval = SUCCESS;

  if ($LISTTFAUSERS) { $retval = listTFAUsers($tfa_home,$ACCESSLOCAL); $LISTTFAUSERS=0;
      $ACCESSLOCAL="-c"; }
  elsif ($ADDACCESS) { $retval = addNonRootAccess($tfa_home, $ACCESSLOCAL); $ADDACCESS=0; }
  elsif ($UPDATEACCESS) { $retval = updateNonRootAccess($tfa_home, $ACCESSLOCAL); $UPDATEACCESS=0; }
  elsif ($REMOVEACCESS) { $retval = removeNonRootAccess($tfa_home, $ACCESSLOCAL); $REMOVEACCESS=0; }
  elsif ($ADDDEFAULTUSERS) { $retval = addDefaultAccessList($tfa_home, $ACCESSLOCAL); $ADDDEFAULTUSERS=0; }
  elsif ($ADDTFAUSER == 1 ) { $retval = addTFAUser($tfa_home, $TFAUSER, $ACCESSLOCAL); $ADDTFAUSER=0; }
  elsif ($ADDTFAUSER == 2 ) { $retval = tfactlshare_setup_alltool_dir_for_user ($tfa_home, $TFAUSER); $ADDTFAUSER=0; }
  elsif ($SETUPTRACEDIR) { $retval = tfactlshare_check_trace($tfa_home,$TFAUSER); 
                           $retval = tfactlshare_setup_alltool_dir_for_user ($tfa_home, $TFAUSER); 
                           $SETUPTRACEDIR=0; undef $TFAUSER; }
#  elsif ($ADDTFAGROUP) { $retval = addTFAGroup($tfa_home, $TFAUSER, $ACCESSLOCAL); $ADDTFAGROUP=0; }
  elsif ($BLOCKTFAUSER) { $retval = blockTFAUser($tfa_home, $TFAUSER, $ACCESSLOCAL); $BLOCKTFAUSER=0; }
#  elsif ($BLOCKTFAGROUP) { $retval = blockTFAGroup($tfa_home, $TFAUSER, $ACCESSLOCAL); $BLOCKTFAGROUP=0; }
  elsif ($UNBLOCKTFAUSER) { $retval = unblockTFAUser($tfa_home, $TFAUSER, $ACCESSLOCAL); $UNBLOCKTFAUSER=0; }
#  elsif ($UNBLOCKTFAGROUP) { $retval = unblockTFAGroup($tfa_home, $TFAUSER, $ACCESSLOCAL); $UNBLOCKTFAGROUP=0; }
  elsif ($RESETTFAUSERS) { $retval = resetTFAUsers($tfa_home, $ACCESSLOCAL); $RESETTFAUSERS=0; }
  elsif ($REMOVETFAUSER) { $retval = removeTFAUser($tfa_home, $TFAUSER, $ACCESSLOCAL); $REMOVETFAUSER=0; }
  elsif ($REMOVEALLUSERS) { $retval = removeAllUsers($tfa_home, $ACCESSLOCAL); $REMOVEALLUSERS=0; }
#  elsif ($RMUSERFROMGP) { $retval = removeTFAUserFromGroup($tfa_home, $TFAUSER, $ACCESSLOCAL); $RMUSERFROMGP=0; }
  
 return $retval;
}

########
# NAME
#   tfactlaccess_process_help
#
# DESCRIPTION
#   This function is the help function for the tfactlaccess module.
#
# PARAMETERS
#   command     (IN) - display the help message for this command.
#
# RETURNS
#   1 if command found; 0 otherwise.
########
sub tfactlaccess_process_help 
{
  my ($command) = shift;       # User-specified argument; show help on $cmd. #

  my ($desc);                                # Command description for $cmd. #
  my ($succ) = 0;                         # 1 if command found, 0 otherwise. #

  if (tfactlaccess_is_cmd ($command)) 
  {                              # User specified a command name to look up. #
    $desc = tfactlshare_get_help_desc($command);
    tfactlshare_print "$desc\n";
    $succ = 1;
  }

  return $succ;
}

########
# NAME
#   tfactlaccess_is_cmd
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
sub tfactlaccess_is_cmd 
{
  my ($arg) = shift;

  return defined ($tfactlaccess_cmds {$arg});

}

########
# NAME
#   tfactlaccess_is_wildcard_cmd
#
# DESCRIPTION
#   This routine determines if an tfactlaccess command allows the use 
#   of wild cards.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is a command that can take wildcards as part of its argument, 
#   false otherwise.
########
sub tfactlaccess_is_wildcard_cmd 
{
  my ($arg) = shift;

  return defined ($tfactlaccess_cmds{ $arg }) &&
    (tfactlshare_get_cmd_wildcard($arg) eq "True" ) ;
}

########
# NAME
#   tfactlaccess_is_no_instance_cmd
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
#   The tfactlaccess module currently supports no command that can run 
#   without an TFAMain instance.
########
sub tfactlaccess_is_no_instance_cmd 
{
  my ($arg) = shift;

  return !defined ($tfactlaccess_cmds{ $arg }) ||
    (tfactlshare_get_cmd_noinst($arg) ne "True" ) ;
}

########
# NAME
#   tfactlaccess_syntax_error
#
# DESCRIPTION
#   This function prints the correct syntax for a command to STDERR, used 
#   when there is a syntax error.  This function is responsible for 
#   only tfactlaccess commands.
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
sub tfactlaccess_syntax_error 
{
  my ($cmd) = shift;
  my ($cmd_syntax);                               # Correct syntax for $cmd. #
  my ($succ) = 0;


  #display syntax only for commands in this module.
  if (tfactlaccess_is_cmd($cmd))
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
#   tfactlaccess_get_tfactl_cmds
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
sub tfactlaccess_get_tfactl_cmds 
{
  return tfactlshare_filter_invisible_cmds(%tfactlaccess_cmds);
}

sub listTFAUsers {
        #print "Executing listTFAUsers \n";
        my $tfa_home = shift;
        my $islocal  = shift;
        my $localhost = tolower_host();
        my $actionmessage;
        my $command;
        my $line;

        my @list;
        my $status = 0;

        my $accessstatus = checkNonRootAccess( $tfa_home );

        if ( $accessstatus == 0 ) {
                print "\nTFA for all Non-Root Users is currently disabled. Please enable it using \'tfactl access enable\'.\n\n";
        }

	my $remotehost;
	my $counter = 0;
	my $index = 0;
	my @hostlist;

	$remotehost = $localhost;

	if ( $islocal eq "-l" ) {
		push(@hostlist, $localhost);
	} else {
		@hostlist = getListOfAllNodes( $tfa_home );
	}

	my $table = Text::ASCIITable->new();
	$table->setCols("User Name", "User Type", "Status");
	$table->setOptions({"outputWidth" => $tputcols, "headingText" => "TFA Users in $remotehost"});
	# removed $localhost
	$actionmessage = "$localhost:listtfausers:$islocal\n";
	$command = buildCLIJava($tfa_home,$actionmessage);
	my @cli_output = tfactlshare_runClient($command);
	foreach $line ( @cli_output ) {
		if ( $line =~ /!/ ) {
			@list = split( /!/, $line );
			while ( $counter <= $#hostlist && $list[0] ne $remotehost ) {
				if ( $status == 1 ) {
					print "$table\n";
                                        $counter++;
				} else {
					print "\nNo Users in TFA Access Manager list in $remotehost.\n\n";
                                        $counter++;
				}

				if ($remotehost eq $localhost && @hostlist[$index] ne $localhost) {
					$remotehost = @hostlist[$index];
					$index++;
				} elsif (@hostlist[$index] eq $localhost) {
					$remotehost = @hostlist[$index+1];
					$index = $index + 2;
				} else {
					$remotehost = @hostlist[$index];
					$index++;
				}
				$status = 0;

				$table = Text::ASCIITable->new();
				$table->setCols("User Name", "User Type", "Status");
				$table->setOptions({"outputWidth" => $tputcols, "headingText" => "TFA Users in $remotehost"});
			}

			my $userStatus = "Blocked";

			if ( $accessstatus == 0 ) {
				$userStatus = "Disabled";
			} elsif ( $list[3] eq "true" ) {
				$userStatus = "Allowed";
			}
			if ( $list[2] =~/USER/ ) {
			  $status = 1;
			  $table->addRow( $list[1], $list[2], $userStatus);
			}
		}
	} # end foreach $line

	if ( $status == 1 ) {
		print "$table\n";
		$counter++;
	} else {
		print "\nNo Users in TFA Access Manager list in $remotehost.\n\n";
		$counter++;
	}

	if ( $counter <= $#hostlist ) {
		while ( $counter <= $#hostlist ) {
			print "\nNo Users in TFA Access Manager list in @hostlist[$index].\n\n";
			$index++;
			$counter++;
		}
	}
  return SUCCESS;
}

sub addTFAUser {

        my $tfa_home = shift;
        my $tfauser = shift;
        my $isLocal = shift;
        my $localhost = tolower_host();
        my $tracebasepath;

        $tfauser = tfactlaccess_sanitize_nonroot_username($tfauser);

        my $valid_nonroot_user = tfactlaccess_validate_nonroot_user($tfauser,$localhost,"added");
        if(!$valid_nonroot_user){
          return FAILED;
        }

        if ( ! $IS_WINDOWS ) {
          #Validate Java access for tfauser
          ##================================
          my $java_home = tfactlshare_getConfigValue(catfile($tfa_home,"tfa_setup.txt"),"JAVA_HOME");
          $java_home = catfile("$java_home","bin","java");
          my $cmd = tfactlshare_checksu($tfauser,"$java_home ");
          my $shell = `env | grep -i '^shell='`;
          if ( $shell =~ /\/bin\/t?csh/ ) {
            $cmd .= " >& /dev/stdout";
          } else {
            $cmd .= " 2>&1";
          }
          my $access = `$cmd`;
          if ( $access =~ /Permission Denied/i ) {
            print "\nUnable to add user \'$tfauser\'. User does not have access to JAVA_HOME\n";
            return FAILED;
          }
          #================================
        }
        my $actionmessage;
        my $command;
        my $line;
        my $status = 0;

        $actionmessage = "$localhost:addtfauser:$isLocal:$tfauser:USER:true\n";
        $command = buildCLIJava($tfa_home,$actionmessage);
        my @cli_output = tfactlshare_runClient($command);
        foreach $line ( @cli_output ) {
                if ( $line eq "ADDED" ) {
                        $status = 1;
                }
        }

        if ( $status == 1 ) {
                print "\nSuccessfully added \'$tfauser\' to TFA Access list.\n\n";
                # Init the tfauser diag directory if not yet initialized
                tfactlshare_check_trace($tfa_home,$tfauser);
                listTFAUsers( $tfa_home, $isLocal );
                return SUCCESS;
        } else {
                print "\nUnable to add user \'$tfauser\'. Please try later\n";
                return FAILED;
        }
}

=head
sub addTFAGroup {

        my $tfa_home = shift;
        my $tfagroup = shift;
        my $isLocal = shift;
        my $localhost = tolower_host();

        if ( getGroupID($tfagroup) == -1 ) {
                print "Group '$tfagroup' does not exist on $localhost.\n";
                print "Only Valid groups may be added to TFA.\n";
                return;
        }

        my $actionmessage;
        my $command;
        my $line;
        my $status = 0;

        $actionmessage = "$localhost:addtfauser:$isLocal:$tfagroup:GROUP:true\n";
        $command = buildCLIJava($tfa_home,$actionmessage);

        foreach $line (split /\n/ , `$command`) {
                if ( $line eq "ADDED" ) {
                        $status = 1;
                }
        }

        if ( $status == 1 ) {
                print "\nSuccessfully added \'$tfagroup\' to TFA Access list.\n\n";
                listTFAUsers( $tfa_home, $isLocal );
        } else {
                print "\nUnable to add group \'$tfagroup\'. Please try later\n";
        }
}
=cut

sub removeTFAUser {

        my $tfa_home = shift;
        my $tfauser = shift;
        my $isLocal = shift;
        my $localhost = tolower_host();
        my $actionmessage;
        my $command;
        my $line;
        my $status = 0;

        $tfauser = tfactlaccess_sanitize_nonroot_username($tfauser);

        my $valid_nonroot_user = tfactlaccess_validate_nonroot_user($tfauser,$localhost,"removed");
        if(!$valid_nonroot_user){
          return FAILED;
        }

        $actionmessage = "$localhost:removetfauser:$isLocal:$tfauser\n";
        $command = buildCLIJava($tfa_home,$actionmessage);

        foreach $line (split /\n/ , `$command`) {
                if ( $line eq "REMOVED" ) {
                        $status = 1;
                }
        }

        if ( $status == 1 ) {
                print "\nSuccessfully removed \'$tfauser\' from TFA Access list.\n\n";
                listTFAUsers( $tfa_home, $isLocal );
                return SUCCESS;
        } else {
                print "\nUnable to remove user \'$tfauser\'. Please try later\n";
                return FAILED;
        }
}

sub blockTFAUser {
        my $tfa_home = shift;
        my $tfauser = shift;
        my $isLocal = shift;
        my $localhost = tolower_host();

        $tfauser = tfactlaccess_sanitize_nonroot_username($tfauser);

        my $valid_nonroot_user = tfactlaccess_validate_nonroot_user($tfauser,$localhost,"blocked");
        if(!$valid_nonroot_user){
          return FAILED;
        }

        my $actionmessage;
        my $command;
        my $line;
        my $status = 0;

        $actionmessage = "$localhost:blocktfauser:$isLocal:$tfauser\n";
        $command = buildCLIJava($tfa_home,$actionmessage);

        foreach $line (split /\n/ , `$command`) {
                if ( $line eq "BLOCKED" ) {
                        $status = 1;
                }
        }

        if ( $status == 1 ) {
                print "\nSuccessfully blocked \'$tfauser\' from TFA Access list.\n\n";
                listTFAUsers( $tfa_home, $isLocal );
                return SUCCESS;
        } else {
                print "\nUnable to block user \'$tfauser\'. Please try later\n\n";
                return FAILED;
        }
}
=head
sub blockTFAGroup {
        my $tfa_home = shift;
        my $tfauser = shift;
        my $isLocal = shift;
        my $localhost = tolower_host();

        if ( getGroupID($tfauser) == -1 ) {
                print "Group '$tfauser' does not exist on $localhost.\n";
                print "Only Valid groups may be blocked in TFA.\n";
                return;
        }

        my $actionmessage;
        my $command;
        my $line;
        my $status = 0;

        $actionmessage = "$localhost:blocktfauser:$isLocal:$tfauser\n";
        $command = buildCLIJava($tfa_home,$actionmessage);

        foreach $line (split /\n/ , `$command`) {
                if ( $line eq "BLOCKED" ) {
                        $status = 1;
                }
        }

        if ( $status == 1 ) {
                print "\nSuccessfully blocked \'$tfauser\' from TFA Access list.\n\n";
                listTFAUsers( $tfa_home, $isLocal );
        } else {
                print "\nUnable to block group \'$tfauser\'. Please try later\n\n";
        }
}
=cut

sub unblockTFAUser {
        my $tfa_home = shift;
        my $tfauser = shift;
        my $isLocal = shift;
        my $localhost = tolower_host();

        $tfauser = tfactlaccess_sanitize_nonroot_username($tfauser);

        my $valid_nonroot_user = tfactlaccess_validate_nonroot_user($tfauser,$localhost,"unblocked");
        if(!$valid_nonroot_user){
          return FAILED;
        }

        my $actionmessage;
        my $command;
        my $line;
        my $status = 0;

        $actionmessage = "$localhost:unblocktfauser:$isLocal:$tfauser\n";
        $command = buildCLIJava($tfa_home,$actionmessage);
	my @cli_output = tfactlshare_runClient($command);
        foreach $line ( @cli_output ) {
                if ( $line eq "UNBLOCKED" ) {
                        $status = 1;
                }
        }

        if ( $status == 1 ) {
                print "\nSuccessfully unblocked \'$tfauser\' in TFA Access list.\n\n";
                listTFAUsers( $tfa_home, $isLocal );
                return SUCCESS;
        } else {
                print "\nUnable to unblock \'$tfauser\'. Please try later\n\n";
                return FAILED;
        }
}
=head
sub unblockTFAGroup {
        my $tfa_home = shift;
        my $tfauser = shift;
        my $isLocal = shift;
        my $localhost = tolower_host();

        if ( getGroupID($tfauser) == -1 ) {
                print "Group '$tfauser' does not exist on $localhost.\n";
                print "Only Valid groups may be unblocked in TFA.\n";
                return;
        }

        my $actionmessage;
        my $command;
        my $line;
        my $status = 0;

        $actionmessage = "$localhost:unblocktfauser:$isLocal:$tfauser\n";
        $command = buildCLIJava($tfa_home,$actionmessage);

        foreach $line (split /\n/ , `$command`) {
                if ( $line eq "UNBLOCKED" ) {
                        $status = 1;
                }
        }

        if ( $status == 1 ) {
                print "\nSuccessfully unblocked \'$tfauser\' in TFA Access list.\n\n";
                listTFAUsers( $tfa_home, $isLocal );
        } else {
                print "\nUnable to unblock \'$tfauser\'. Please try later\n\n";
        }
}

sub removeTFAUserFromGroup {
        my $tfa_home = shift;
        my $tfauser = shift;
        my $isLocal = shift;
        my $localhost = tolower_host();
        my $tfauserid = getUserID($tfauser);

        if ( $tfauserid == -1 ) {
                print "User '$tfauser' does not exist on $localhost.\n";
                print "Only Valid users may be removed from a TFA group.\n";
                return;
        } elsif ( $tfauserid == 0 ) {
                print "User '$tfauser' is the super user on $localhost.\n";
                print "Only valid non-root users may be removed from a TFA group.\n";
                return;
        }

        my $actionmessage;
        my $command;
        my $line;
        my $status = 0;

        $actionmessage = "$localhost:addtfauser:$isLocal:$tfauser:USER:false\n";
        $command = buildCLIJava($tfa_home,$actionmessage);
	my @cli_output = tfactlshare_runClient($command);
        foreach $line ( @cli_output ) {
                if ( $line eq "ADDED" ) {
                        $status = 1;
                }
        }

        if ( $status == 1 ) {
                print "\nSuccessfully blocked \'$tfauser\' from TFA Access list.\n\n";
                listTFAUsers( $tfa_home, $isLocal );
        } else {
                print "\nUnable to block user \'$tfauser\'. Please try later\n";
        }
}
=cut

sub removeAllUsers {

        my $tfa_home = shift;
        my $isLocal = shift;
        my $localhost = tolower_host();
        my $actionmessage;
        my $command;
        my $line;
        my $status = 0;

        $actionmessage = "$localhost:removeallusers:$isLocal\n";
        $command = buildCLIJava($tfa_home,$actionmessage);

        foreach $line (split /\n/ , `$command`) {
                if ( $line eq "REMOVED" ) {
                        $status = 1;
                }
        }

        if ( $status == 1 ) {
                print "\nSuccessfully removed all users and groups from TFA Access list.\n\n";
                return SUCCESS;
        } else {
                print "\nUnable to remove all users and groups. Please try later\n";
                return FAILED;
        }
}

sub resetTFAUsers {

        my $tfa_home = shift;
        my $isLocal = shift;
        my $localhost = tolower_host();
        my $actionmessage;
        my $command;
        my $line;
        my $status = 0;

        $actionmessage = "$localhost:resettfausers:$isLocal\n";
        $command = buildCLIJava($tfa_home,$actionmessage);

        foreach $line (split /\n/ , `$command`) {
                if ( $line eq "RESET" ) {
                        $status = 1;
                }
        }

        if ( $status == 1 ) {
                print "\nSuccessfully restored to default TFA Access list.\n\n";
                return SUCCESS;
        } else {
                print "\nUnable to restore to default TFA Access list. Please try later\n";
                return FAILED;
        }
}

sub getUserID {
        my $user = shift;
        my $id = (getpwnam($user))[2];

        if ( defined $id && $id == 0 ) {
                $id = 0; 
        } elsif ( ! $id ) {
                $id = -1;
        }
        return $id;
}

sub getGroupID {
        my $group = shift;
        my $id = (getgrnam($group))[2];

        if ( ! $id ) {
                $id = -1; 
        }
        return $id;
}

########
# NAME
#   tfactlaccess_clean_env
#
# DESCRIPTION
#   This routine resets tfactlaccess environment
#
# PARAMETERS
#
# RETURNS
#
########
sub tfactlaccess_clean_env 
{
  $LISTTFAUSERS=0;
  $ADDACCESS=0;
  $UPDATEACCESS=0;
  $REMOVEACCESS=0;
  $ADDDEFAULTUSERS=0;
  $ADDTFAUSER=0;
  $ADDTFAGROUP=0;
  $BLOCKTFAUSER=0;
  $BLOCKTFAGROUP=0;
  $UNBLOCKTFAUSER=0;
  $UNBLOCKTFAGROUP=0;
  $RESETTFAUSERS=0;
  $REMOVETFAUSER=0;
  $REMOVEALLUSERS=0;
  $RMUSERFROMGP=0;

  return;
}

########
# NAME
#   tfactlaccess_is_valid_windows_user
#
# DESCRIPTION
#   This routine checks if a given user is valid windows user or not
#
# PARAMETERS
#   $user - User Name
# RETURNS
#   0 for invalid user and 1 for a valid user
########
sub tfactlaccess_is_valid_windows_user{
  my $user = shift;
  my $is_valid = 0;
  my @user_list = osutils_get_list_of_available_users();
  foreach my $existing_user (@user_list) {
    if($existing_user eq $user){
      $is_valid = 1;
      last;
    }
  }
  return $is_valid;
}

########
# NAME
#   tfactlaccess_validate_nonroot_user
#
# DESCRIPTION
#   This routine checks if a given user is valid non root user or not
#
# PARAMETERS
#   $user - User Name
#   $localhost - Localhost
#   $message - activity performed
# RETURNS
#   0 for invalid user and 1 for a valid nonroot user
########
sub tfactlaccess_validate_nonroot_user{
  my $tfauser = shift;
  my $localhost = shift;
  my $message = shift;

  if($IS_WINDOWS){
    if(!tfactlaccess_is_valid_windows_user($tfauser)){
      print "User '$tfauser' does not exist on $localhost.\n";
      print "Only Valid users may be $message to TFA.\n";
      return 0;
    }
  }else{
    my $tfauserid = getUserID($tfauser);
    if ( $tfauserid == -1 ) {
      print "User '$tfauser' does not exist on $localhost.\n";
      print "Only Valid users may be $message to TFA.\n";
      return 0;
    } elsif ( $tfauserid == 0 ) {
      print "User '$tfauser' is the super user on $localhost.\n";
      print "Only valid non-root users may be $message to TFA.\n";
      return 0;
    }
  }

  return 1;
}

########
# NAME
#   tfactlaccess_sanitize_nonroot_username
#
# DESCRIPTION
#   This routine checks if a user with same name existis without considering 
#   upper, lower or mixed case. Moreover returns same user which exists in system list.
#
# PARAMETERS
#   $user - User Name
# RETURNS
#   $user - Equivalent system User Name
########
sub tfactlaccess_sanitize_nonroot_username{
  my $tfauser = shift;
  my $matches = 0;
  my $matched_user;

  my @user_list = osutils_get_list_of_available_users();
  foreach my $existing_user (@user_list) {
    if($existing_user eq $tfauser){
      # Exact match
      return $existing_user;
    }
    if(lc($existing_user) eq lc($tfauser)){
      # Case insensitive match
      $matches = $matches + 1;
      $matched_user = $existing_user;
    }
  }

  if($matches==1){
    return $matched_user;
  }elsif($matches>1){
    print "\nThere are multiple users that match with '$tfauser' with different case.\n";
  }

  return $tfauser;
}
