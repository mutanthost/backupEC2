# 
# $Header: tfa/src/v2/tfa_home/bin/tfasetup.pl /main/15 2018/05/28 15:06:28 bburton Exp $
#
# tfasetup.pl
# 
# Copyright (c) 2012, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfasetup.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     11/08/17 - Allow for responsefile
#    bburton     05/08/17 - do not use parent.pm
#    manuegar    08/25/16 - Support the -extractto switch in the TFA installer.
#    bibsahoo    04/19/16 - TFA DISCOVERY TO PERL
#    bburton     01/26/16 - add more install logging
#    gadiga      04/10/15 - windows
#    gadiga      04/09/15 - windows
#    manuegar    07/22/14 - Relocate tfactl_lib
#    llakkana    01/21/14 - Receiver changes
#    cnagur      01/02/14 - Updated help message - bug 18013907
#    gadiga      11/24/13 - dbhome install
#    bburton     06/07/13 - Allow for local only flag
#    bburton     06/06/13 - allow defer of discovery
#    bburton     05/23/13 - accept -crshome flag for GI install
#    bburton     01/15/13 - add debuging using ENV VAR TFA_DEBUG
#    bburton     07/30/12 - Creation
# 
###################################################################
#
# TFA is delivered in a tarball that has to be extracted into the tfa_home.
# This Script runs in that tfa_home and discovers for or asks for information
# that TFA needs to run..
# It will also optionally copy tfa to other nodes in a cluster and do initial 
# setup there.
# 
#   Step 1) Discover the nodes - uses raccheck code that also sets up ssh if 
#           required.  This discovers a lot of information but intially all we 
#           need are the nodename and to know ssh is setup OK..
#   Step 2) Determine the TFA Home and output trace directory..
#   ????  Where should the default TFA_HOME i under oracle_base if there ?..
#   ????  Should we have a tfa_home for each user ..
#         probably seeing as we will have permissions issues otherwise.
#         would mean a tfamain per user and a requirement to deal with that 
#         when it comes to zipping files etc .. This would require quite a
#         bit more work .. Other option is that tfauser must have read access
#         to files they want to use.
#   Step 3) Copy the software to all the nodes.
#   Step 4) Add the CRS resource - assuming CRS is up and configured
#           if not configured or it is down we will write the command to a file
#           for later execution as required.
#   Step 5) Start the resource on all nodes.
#   Step 6) Check the resource on all nodes.
#   Step 7) Add all the hosts to TFA 
#   Step 8) Discover all the required directories and add those to TFA.
#   Step 9) Run a first off inventory for all directories.
###################################################################
#
#
# The SYNOPSIS section is printed out as usage when incorrect parameters
# are passed

=head1 NAME

  tfasetup.pl - Setup TFA on all nodes of the cluster

=head1 SYNOPSIS

  tfasetup.pl [-help]

     This is an internal script. Please do not call it manually.
     This may affect current TFA configuration.

=head1 DESCRIPTION
  
  Description Coming

=cut

use strict;
use English;
use File::Basename;
use File::Spec::Functions;
#use IO::Socket;
use Cwd;
use FindBin qw($RealBin);

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME);
  push @INC, dirname($PROGRAM_NAME).'/common';
  push @INC, dirname($PROGRAM_NAME).'/modules';
  push @INC, dirname($PROGRAM_NAME).'/common/exceptions';
}

use Getopt::Long; # qw(:config no_auto_abbrev);
use Pod::Usage;
use tfactlglobal;
use tfactlshare;
#use tfactl_lib;

if ( $OSNAME eq "MSWin32" )
{
  eval q{use base 'Win32'; 1} or die $@;
}

# Global variables

our $DEPLOY;
our $REMOTEHOST;
#our $DEBUG;
our $SILENT;
our $NORUNAUTO;
our $RUNDISC;
our $DEFERDISC;
our $CONFDISC;
our $TFAHOME;
our $CRSHOME;
our $ORAHOME;
our $ORABASE;
our $LOCALONLY;
our $RECEIVER;
our $DISCOVERYFILE;
our $HELP = 0;
our $EXTRACTTO;
our $RESPFILE;

$SIG{'INT'} = 'INT_handler';

sub INT_handler {
    print "TFA Setup interrupted\n";
    exit 1;
}

# Parse command line args
# If an incorrect option is specified, the perl POD at the beginning
# of the file is parsed into a man page
# the return code to give when the incorrect parameters are passed
my $usage_rc = 1;
# have to check for no args first..
#pod2usage(-msg => "Must Supply at least 1 Argument",
#          -exitval => $usage_rc) if (@ARGV == 0);

GetOptions('verbose'       => \$DEBUG,
           'rundiscovery'         => \$RUNDISC,
           'confirmdiscovery'         => \$CONFDISC,
           'noclustersetup'         => \$NORUNAUTO,
           'deploy'       => \$DEPLOY,
           'silent'       => \$SILENT,
           'local'       => \$LOCALONLY,
           'extractto'   => \$EXTRACTTO,
           'remotehost=s'       => \$REMOTEHOST,
           'crshome=s'       => \$CRSHOME,
           'ohome=s'       => \$ORAHOME,
           'obase=s'       => \$ORABASE,
           'deferdiscovery'       => \$DEFERDISC,
           'tfabase=s'       => \$TFAHOME,
           'discoveryfile=s'       => \$DISCOVERYFILE,           
	   'receiver'  => \$RECEIVER,
	   'logfile=s'  => \$INSTLOGFILE,
	   'respfile=s'  => \$RESPFILE,
           'help'          => \$HELP) or pod2usage($usage_rc);

pod2usage(-msg => "Invalid extra options passed: @ARGV",
          -exitval => $usage_rc) if (@ARGV);

#
# MAIN SCRIPT BODY
#
if ( $ENV{'TFA_DEBUG'} )
{
  $DEBUG = $ENV{'TFA_DEBUG'};
}
 else
{
  $DEBUG = 1;
}

$TFAHOME = $RealBin;
$TFAHOME =~ s/\/tfa_home\/bin//;
# run the required subroutine dependent on the parameters provided.
if    ($HELP)   { pod2usage(0); }
elsif ($RUNDISC) { runRacCheckDiscovery($TFAHOME) }
elsif ($CONFDISC) { confirmDiscovery() }
elsif ($EXTRACTTO) { runExtracttoSetup($TFAHOME) }
elsif (!$NORUNAUTO) { runAutoSetup($TFAHOME, $SILENT, $CRSHOME, $DEFERDISC, $LOCALONLY, $ORAHOME, $ORABASE, $RECEIVER, $DISCOVERYFILE, $RESPFILE)}
elsif ($DEPLOY) { deployTFA($TFAHOME,$REMOTEHOST) }
0;

