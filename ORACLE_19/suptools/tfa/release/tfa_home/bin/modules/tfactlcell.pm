# 
# $Header: tfa/src/v2/tfa_home/bin/modules/tfactlcell.pm /main/10 2018/08/09 22:22:30 recornej Exp $
#
# tfactlcell.pm
# 
# Copyright (c) 2014, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlcell.pm 
#
#    DESCRIPTION
#      Print or Modify various Storage Cell features
#
#    NOTES
#     
#
#    MODIFIED   (MM/DD/YY)
#    recornej    08/06/18 - Change SUCCESS and FAILED values.
#    manuegar    07/13/18 - manuegar_multibug_01.
#    bburton     03/19/18 - Bug 27665984 - remove use of POSIX::tmpnam
#    cnagur      05/27/16 - XbranchMerge cnagur_tfa_121260_cell_issues_txn from
#                           st_tfa_12.1.2.6
#    manuegar    04/26/16 - Dynamic help.
#    cnagur      03/16/16 - Fix for Bug 22917519
#    bburton     01/14/15 - Bug 20351923 - Do not do addRowLine (---) before a
#                           row exists.
#    manuegar    07/22/14 - Relocate tfactl_lib
#    manuegar    07/04/14 - Creation
#
############################ Functions List #################################
#
# printCellConfiguration
# configureCellsByUser
# printCells
# removeCellConfiguration
# addWalletPasswordByUser
# removeWalletPasswordByUser
# 
#############################################################################

package tfactlcell;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(tfactlcell_init
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

#################### tfactlcell Global Constants ####################

my (%tfactlcell_cmds) = (cell           => {},
                         configurecells => {},
                         );


#################### tfactlcell Global Variables ####################

sub is_tfactl
{
  return 1;
}


########
# NAME
#   tfactlcell_init
#
# DESCRIPTION
#   This function initializes the tfactlcell module.  For now it 
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
  push (@tfactlglobal_command_callbacks, \&tfactlcell_process_cmd);
  push (@tfactlglobal_help_callbacks, \&tfactlcell_process_help);
  push (@tfactlglobal_command_list_callbacks, \&tfactlcell_get_tfactl_cmds);
  push (@tfactlglobal_is_command_callbacks, \&tfactlcell_is_cmd);
  push (@tfactlglobal_is_wildcard_callbacks, \&tfactlcell_is_wildcard_cmd);
  push (@tfactlglobal_syntax_error_callbacks, \&tfactlcell_syntax_error);
  push (@tfactlglobal_no_instance_callbacks, \&tfactlcell_is_no_instance_cmd);
  %tfactlglobal_cmds = (%tfactlglobal_cmds, %tfactlcell_cmds);

  #Perform TFACTL consistency check if enabled
  if($tfactlglobal_hash{'consistchk'} eq 'y')
  {
     if(!tfactlshare_check_option_consistency(%tfactlcell_cmds))
     {   
       exit 1;
     }
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlcell init", 'y', 'n');

}

########
# NAME
#   tfactlcell_process_cmd
#
# DESCRIPTION
#   This routine calls the appropriate routine to process the command 
#   specified by $tfactlglobal_hash{'cmd'}.
#
# PARAMETERS
#   dbh       (IN) - initialized database handle, must be non-null.
#
# RETURNS
#   1 if command is found in the tfactlcell module; 0 if not.
#
# NOTES
#   Only tfactl_shell() calls this routine.
########
sub tfactlcell_process_cmd 
{
  my ($retval) = 0;
  my ($succ)   = 0;

  # Get current command from global value, which is set by 
  # tfactlcell_parse_tfactl_args()and by tfactl_shell().
  my ($cmd) = $tfactlglobal_hash{'cmd'};

  # Declare and initialize hash of function pointers, each designating a 
  # routine that processes an tfactlcell command.
  my (%cmdhash) = ( cell           => \&tfactlcell_process_command,
                    configurecells => \&tfactlcell_process_command
                  );

  if (defined ( $cmdhash{ $cmd } ))
  {    # If user specifies a known command, then call routine to process it. #
    $retval = $cmdhash{ $cmd }->();
    $succ = 1;
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlcell tfactlcell_process_cmd", 'y', 'n');

  return ($succ, $retval);
}

########
# NAME
#   tfactlcell_process_command
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
#   Only tfactlcell_process_cmd() calls this function.
########
sub tfactlcell_process_command
{
  my $retval = 0;

  tfactlshare_trace(3, "tfactl (PID = $$) tfactlcell tfactlcell_process_command", 'y', 'n');
  # Read the commands
  @ARGV = @tfactlglobal_argv;
  my $command1 = shift(@ARGV);
  my $command2 = shift(@ARGV);
  my $switch_val = $command1;

  if ($switch_val eq "cell" ) 
        {
          if ( $current_user ne "root" ) {
                  print "\nAccess Denied: Only TFA Admin can run this command\n\n";
                  exit 1;
          }

          print_help("cell", "" ) if ( ! $command2 );

          if (defined $command2 && ($command2 eq "-h" || $command2 eq "-help")) {
                 print_help("cell");
          }

          my $command3 = shift(@ARGV);
     
          $switch_val = $command2 ;
          {
            if ($switch_val eq "status") { 
              if ( defined $command3 && (lc($command3) eq "-h" || lc($command3) eq "-help") ) {
                print_help("cell","status");
                return;
              }
              $PRINTCELLS = 1; } 
            elsif ($switch_val eq "config" ) { 
              if ( defined $command3 && (lc($command3) eq "-h" || lc($command3) eq "-help") ) { 
                print_help("cell","config");
                return;
              } 
              $CELLPRINTCONFIG = 1; } 
            elsif ($switch_val eq "invstat" ) { 
              if ( defined $command3 && (lc($command3) eq "-h" || lc($command3) eq "-help") ) { 
                print_help("cell","invstat");
                return;
              }
              $PRINTCELLINVRUNSTAT = 1; } 
            elsif ($switch_val eq "diagstat" ) { 
              if ( defined $command3 && (lc($command3) eq "-h" || lc($command3) eq "-help") ) { 
                print_help("cell","diagstat");
                return;
              }
              $PRINTCELLDIAGSTAT = 1; } 
            elsif ($switch_val eq "deconfigure" ) { 
              if ( defined $command3 && (lc($command3) eq "-h" || lc($command3) eq "-help") ) { 
                print_help("cell","deconfigure");
                return;
              }
              $CELLDECONFIG = 1; }
            elsif ($switch_val eq "add" )       {
                          print_help("cell", "add" ) if ( ! $command3 );
                          if ( defined $command3 && (lc($command3) eq "-h" || lc($command3) eq "-help") ) {
                            print_help("cell","add");
                            return;
                          }
                          if ( $command3 =~ /^walletpassword$/ ) { $CELLADDWALETPASS = 1; }
                          else { print_help("cell","add"); }
                        }
            elsif ($switch_val eq "remove" ) {
                          print_help("cell", "remove" ) if ( ! $command3 );
                          if ( defined $command3 && (lc($command3) eq "-h" || lc($command3) eq "-help") ) {
                            print_help("cell","remove");
                            return;
                          }
                          if ( $command3 =~ /^walletpassword$/ ) { $CELLREMWALLETPASS = 1; }
                          elsif ( $command3 =~ /^wallet$/ ) { $CELLREMWALLET = 1; }
                          else { print_help("cell","remove"); }
                        }
            elsif ($switch_val eq "configure" ) {

                        print_help("cell","configure") if ( $command3 eq "-h" || $command3 eq "-help" );

                        if ( $command3 && $command3 eq "-c" ) {
                                $ISLOCAL = "-c";
                        }

                        my $command4 = shift(@ARGV);

                        if ( $command4 && $command4 eq "-silent" ) {
                                $SILENT = 1;
                        }

                        $CONFIGURECELLS = 1;
                        }
            elsif ($switch_val eq "print" ) {
                          if ( ! $command3 ) { $PRINTCELLS = 1; }
                          if ( defined $command3 && (lc($command3) eq "-h" || lc($command3) eq "-help") ) {
                            print_help("cell","print");
                            return;
                          }
                          if ( $command3 =~ /^cells$/ ) { $PRINTCELLS = 1; }
                          elsif ( $command3 =~ /^config$/ ) { $CELLPRINTCONFIG = 1; }
                          else { print_help("cell","print"); }
                        }
            else {
                  print_help("cell", "Please Enter Options to tfactl cell" ) if defined($command2) && ($command2 ne "-h") && ($command2 ne "-help");
                 }
          }
        }
  elsif ($switch_val eq "configurecells" )
        {
          $CONFIGURECELLS = 1;
        }

  # Dispatch the command
  tfactlshare_pre_dispatch();
  $retval = tfactlcell_dispatch();

  return $retval;
}

########
# NAME
#   tfactlcell_dispatch
#
# DESCRIPTION
#   Dispatch de command.
#
# PARAMETERS
#
# RETURNS
#
########
sub tfactlcell_dispatch
{
 my $retval = 0;

 if ($PRINTCELLS) { $retval = printCells($tfa_home); $PRINTCELLS=0; }
 elsif ($CELLPRINTCONFIG) { $retval = printCellConfiguration($tfa_home); $CELLPRINTCONFIG=0; }
 elsif ($PRINTCELLINVRUNSTAT) { $retval = printCellInventoryRunStatus($tfa_home); $PRINTCELLINVRUNSTAT=0; }
 elsif ($PRINTCELLDIAGSTAT) { $retval = printCellDiagCollectRunStatus($tfa_home); $PRINTCELLDIAGSTAT=0; }
 elsif ($CELLDECONFIG) { $retval = removeCellConfiguration($tfa_home); $CELLDECONFIG=0; }
 elsif ($CELLADDWALETPASS) { $retval = addWalletPasswordByUser($tfa_home); $CELLADDWALETPASS=0; }
 elsif ($CELLREMWALLETPASS) { $retval = removeWalletPasswordByUser($tfa_home); $CELLREMWALLETPASS=0; }
 elsif ($CELLREMWALLET) { $retval = removeWalletByUser($tfa_home); $CELLREMWALLET=0; }
 elsif ($CONFIGURECELLS) { $retval = configureCellsByUser($tfa_home, $ISLOCAL, $SILENT); $CONFIGURECELLS=0; $ISLOCAL="-l"; $SILENT=0; }

 return $retval;
}

########
# NAME
#   tfactlcell_process_help
#
# DESCRIPTION
#   This function is the help function for the tfactlcell module.
#
# PARAMETERS
#   command     (IN) - display the help message for this command.
#
# RETURNS
#   1 if command found; 0 otherwise.
########
sub tfactlcell_process_help 
{
  my ($command) = shift;       # User-specified argument; show help on $cmd. #

  my ($desc);                                # Command description for $cmd. #
  my ($succ) = 0;                         # 1 if command found, 0 otherwise. #

  if (tfactlcell_is_cmd ($command)) 
  {                              # User specified a command name to look up. #
    $desc = tfactlshare_get_help_desc($command);
    tfactlshare_print "$desc\n";
    $succ = 1;
  }

  return $succ;
}

########
# NAME
#   tfactlcell_is_cmd
#
# DESCRIPTION
#   This routine checks if a user-entered command is one of the known
#   TFACTL internal commands that belong to the tfactlcell module.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is one of the known commands, false otherwise.
########
sub tfactlcell_is_cmd 
{
  my ($arg) = shift;

  return defined ($tfactlcell_cmds {$arg});

}

########
# NAME
#   tfactlcell_is_wildcard_cmd
#
# DESCRIPTION
#   This routine determines if an tfactlcell command allows the use 
#   of wild cards.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is a command that can take wildcards as part of its argument, 
#   false otherwise.
########
sub tfactlcell_is_wildcard_cmd 
{
  my ($arg) = shift;

  return defined ($tfactlcell_cmds{ $arg }) &&
    (tfactlshare_get_cmd_wildcard($arg) eq "True" ) ;
}

########
# NAME
#   tfactlcell_is_no_instance_cmd
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
#   The tfactlcell module currently supports no command that can run 
#   without an TFAMain instance.
########
sub tfactlcell_is_no_instance_cmd 
{
  my ($arg) = shift;

  return !defined ($tfactlcell_cmds{ $arg }) ||
    (tfactlshare_get_cmd_noinst($arg) ne "True" ) ;
}

########
# NAME
#   tfactlcell_syntax_error
#
# DESCRIPTION
#   This function prints the correct syntax for a command to STDERR, used 
#   when there is a syntax error.  This function is responsible for 
#   only tfactlcell commands.
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
sub tfactlcell_syntax_error 
{
  my ($cmd) = shift;
  my ($cmd_syntax);                               # Correct syntax for $cmd. #
  my ($succ) = 0;


  #display syntax only for commands in this module.
  if (tfactlcell_is_cmd($cmd))
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
#   tfactlcell_get_tfactl_cmds
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
sub tfactlcell_get_tfactl_cmds 
{
  return tfactlshare_filter_invisible_cmds(%tfactlcell_cmds);
}

sub printCellConfiguration {

        my $TFA_HOME = shift;

        my $EXADATA = isExadata();;
        my $CONFIGURED = isExadataConfigured( $TFA_HOME );;
        my $WALLET_CREATED = checkWallet( $TFA_HOME );
        my $WALLET_LOCATION = "$TFA_HOME/internal/tfawallet";
        my $WALLET_PASS = "Not Stored";
        my $WALLET_PASS_PRESENT = "NO";
        my $WALLET_DB = getWalletPasswordFromDB( $TFA_HOME );
        $WALLET_DB = trim ( $WALLET_DB );

        if ( $WALLET_DB ne "null" ) {
                $WALLET_PASS = "Stored";
                $WALLET_PASS_PRESENT = "YES";
        }

        my $TABLE = Text::ASCIITable->new();
        $TABLE->setCols("Configuration Parameter", "Value");
        $TABLE->alignCol("Value","left");
        $TABLE->setColWidth("Value", $tputcols-30);
        $TABLE->setOptions({"outputWidth" => $tputcols, "headingText" => "Storage Cell Configuration"});

        if ( $EXADATA == 1 ) {
                $TABLE->addRow("Exadata Support", "YES");
        } else {
                $TABLE->addRow("Exadata Support", "NO");
        }

        if ( $CONFIGURED == 1 ) {
                $TABLE->addRow("Configured Storage Cells", "YES");
        } else {
                $TABLE->addRow("Configured Storage Cells", "NO");
        }

        if ( $WALLET_CREATED == 1 ) {
                $TABLE->addRow("Oracle Wallet Used", "YES");
        } else {
                $TABLE->addRow("Oracle Wallet Used", "NO");
                $WALLET_LOCATION = "-";
        }

        $TABLE->addRow("Oracle Wallet Location", $WALLET_LOCATION );

        $TABLE->addRow("Oracle Wallet Password is with TFA", $WALLET_PASS_PRESENT );

        $TABLE->addRow("Oracle Wallet Password Storage Status", $WALLET_PASS );

        print "\n$TABLE\n";
}

sub configureCellsByUser {

        my $TFA_HOME = shift;
        my $isLocal = shift;
        my $silent = shift;

        if ( ! $isLocal ) {
                $isLocal = "-l";
        }

        if ( ! $silent ) {
                $silent = 0;
        }

        my $EXADATA = isExadata();

        if ( $EXADATA == 0 ) {
                print "\nThis Cluster is not configured with Storage Cells. Please Check Again.\n";
                exit 1;
        }

        my $EXADATA_CONFIGURED = isExadataConfigured( $TFA_HOME );

        if ( $EXADATA_CONFIGURED == 1 ) {
                print "\nTFA is already configured with Storage Cells.\n\n";

                printCells ( $TFA_HOME );

                my $OPTION = "N";

                if ( ! $silent ) {
                        print "Do you want to continue: [Y|y|N|n] [Y]: ";
                        chomp( $OPTION = <STDIN> );
                        $OPTION ||= "Y";
                        $OPTION = get_valid_input ( $OPTION, "Y|y|N|n", "Y");
                }

                if ( $OPTION =~ /[Nn]/ ) {
                        exit 1;
                }

                removeCellConfiguration( $TFA_HOME );
        }

        print "\n";

        configureCells( $TFA_HOME, $silent );

	if ( $isLocal eq "-l" ) {
		return;
	}

        $EXADATA_CONFIGURED = isExadataConfigured( $TFA_HOME );

	# Copy Cell details to other Compute Nodes
        if ( $EXADATA_CONFIGURED == 1 ) {

                my $LOCALHOST = tolower_host();
                my @TFA_HOSTS =  getListOfOtherNodes( $TFA_HOME );
                my $REMOTE_NODE;

                foreach $REMOTE_NODE ( @TFA_HOSTS ) {

			# Copy cell configuration files to all Compute Nodes
			copyTagFile( $TFA_HOME, "cellnames", $REMOTE_NODE );
			copyTagFile( $TFA_HOME, "cellips", $REMOTE_NODE );

                        # Copy TFA Wallet to all Compute Nodes
                        if ( -d "$TFA_HOME/internal/tfawallet" ) {

				# Create TFA Wallet Directory
                                qx( $TFA_HOME/bin/tfactl executecommand $REMOTE_NODE "maketfawallet" );

                                my $walletdir = "$TFA_HOME/internal/tfawallet";
                                opendir( WALLET, $walletdir ) or print "Unable to open $walletdir\n";
                                while (my $file = readdir( WALLET ) ) {
                                        next if ($file =~ m/^\./);
					copyTagFile( $TFA_HOME, "walletfile-$file", $REMOTE_NODE );
                                }
                                closedir( WALLET );
                        }
                }

                my $WALLET = checkWallet( $TFA_HOME );

                if ( $WALLET == 1 ) {
                        print "Synchronizing TFA Wallet with Other Nodes...\n";
                        syncWallet( $TFA_HOME );
                }

                print "\nRunning Inventory in Storage Cells now...\n";
                runInventoryInCells($TFA_HOME);
        }
}

#
#Subroutine to print Exadata Cells using cellnames.txt 
#
sub printCells {

        my $TFA_HOME = shift;
        my $EXADATA = isExadataConfigured( $TFA_HOME );

        if ( $EXADATA == 0 ) {
                print "\nStorage Cells are not configured with TFA. Please Configure it using 'tfactl cell configure'.\n";
                exit 1;
        }

        my $COUNT = 1;
        my $TABLE = Text::ASCIITable->new();
        $TABLE->setCols('','EXADATA CELL','CURRENT STATUS');

	my @CELLS = getOnlineCells();

        foreach ( @CELLS ) {
                my $STATUS = "OFFLINE";
                my $CELL = trim("$_");
                my $PING_STATUS = pingHost( $CELL );

                if ( $PING_STATUS == 0 ) {
                        $STATUS = "ONLINE";
                }

                $TABLE->addRow( $COUNT, $CELL, $STATUS );
                $COUNT += 1;
        }

        print "$TABLE\n";
}

sub removeCellConfiguration {

        my $TFA_HOME =  shift;

        my $EXADATA = isExadata();

        if ( $EXADATA == 0 ) {
                print "\nThis Cluster is not configured with Storage Cells. Please Check Again.\n";
                exit 1;
        }

        my $EXADATA_CONFIGURED = isExadataConfigured( $TFA_HOME );

        if ( $EXADATA_CONFIGURED == 0 ) {
                print "\nTFA is not configured with Storage Cells. Please Check Again.\n";
                return;
        }

        print "\nRemoving Storage Cell Configuration...\n";

        my $WALLET = checkWallet( $TFA_HOME );
        my $WALLETDIR = "$TFA_HOME/internal/tfawallet";
        my $CELLFILE = "$TFA_HOME/internal/cellnames.txt";
        my $CELLIPFILE = "$TFA_HOME/internal/cellips.txt";
        my @CELLS = getOnlineCells( $TFA_HOME );

        #Remove all the storage cell related files on Remote Nodes:
        my $LOCALHOST = tolower_host();
        my @TFA_HOSTS = getListOfOtherNodes( $TFA_HOME );
        my $REMOTE_NODE;
        my $CELL;

        foreach $REMOTE_NODE ( @TFA_HOSTS ) {
                print "\nRemoving Storage Cell Configuration on $REMOTE_NODE...\n";
                if ( $WALLET == 1 ) {
                        qx( $TFA_HOME/bin/tfactl executecommand $REMOTE_NODE "removewallet" );
                }
                qx( $TFA_HOME/bin/tfactl executecommand $REMOTE_NODE "removecellnames" );
                qx( $TFA_HOME/bin/tfactl executecommand $REMOTE_NODE "removecellips" );

                foreach $CELL ( @CELLS ) {
                        qx( $TFA_HOME/bin/tfactl executecommand $REMOTE_NODE "rmcellinv-$CELL" );
                }
        }

        #Remove All the storage cell related files on Local:

        if ( $WALLET == 1 ) {
                rmtree "$WALLETDIR";
        }

        removeWalletPasswordFromDB( $TFA_HOME );

        if ( -f "$CELLFILE" ) {
                unlink( "$CELLFILE" );
                unlink( "$CELLIPFILE" );
        }
        qx( rm -f $TFA_HOME/internal/.*.inv );

        print "\nSuccessfully removed Storage Cell Configuration.\n";
}

sub addWalletPasswordByUser {

        my $TFA_HOME = shift;

        my $WALLET = checkWallet( $TFA_HOME );

        if ( $WALLET != 1 ) {
                print "\nTFA is not configured with Oracle Wallet.\n";
                exit 1;
        }

        my $CUR_PASS;

        $CUR_PASS = promptForPassword( "Oracle Wallet", 0 );

        my $CHECK = checkWalletPassword( $TFA_HOME, $CUR_PASS );

        if ( $CHECK != 0 ) {
                print "\nOracle Wallet Password you Entered is incorrect. Please try again.\n";
                exit 1;
        }

        updateWalletPasswordInDB( $TFA_HOME, $CUR_PASS );

        print "\nOracle Wallet Password is successfully added.\n";
}

sub removeWalletPasswordByUser {

        my $TFA_HOME = shift;

        my $WALLET = checkWallet( $TFA_HOME );

        if ( $WALLET != 1 ) {
                print "\nTFA is not configured with Oracle Wallet.\n";
                exit 1;
        }

        my $WALLET_PASS;
        my $CUR_PASS;

        $CUR_PASS = promptForPassword( "Oracle Wallet", 0 );

        my $CHECK = checkWalletPassword( $TFA_HOME, $CUR_PASS );

        if ( $CHECK != 0 ) {
                print "\nOracle Wallet Password you Entered is incorrect. Please try again.\n";
                exit 1;
        }

        removeWalletPasswordFromDB( $TFA_HOME );

        print "\nOracle Wallet Password is successfully removed.\n";
}

sub removeWalletByUser {

        my $TFA_HOME = shift;

        my $WALLET = checkWallet( $TFA_HOME );

        if ( $WALLET != 1 ) {
                print "\nTFA is not configured with Oracle Wallet.\n";
                exit 1;
        }

        my $CUR_PASS = promptForPassword( "Oracle Wallet", 0 );

        my $CHECK = checkWalletPassword( $TFA_HOME, $CUR_PASS );

        if ( $CHECK != 0 ) {
                print "\nOracle Wallet Password you Entered is incorrect. Please try again.\n";
                exit 1;
        }

        my $STATUS = removeWallet( $TFA_HOME );

        if ( $STATUS == 0 ) {
                print "\nOracle Wallet is successfully removed.\n";
        } else {
                print "\nUnable to remove Oracle Wallet. Please try Again.\n";
        }
}


