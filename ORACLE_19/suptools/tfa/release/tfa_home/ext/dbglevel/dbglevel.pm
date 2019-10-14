# 
# $Header: tfa/src/v2/ext/dbglevel/dbglevel.pm /main/32 2018/07/20 04:07:08 recornej Exp $
#
# dbglevel.pm
#
# Copyright (c) 2015, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      dbglevel.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    06/19/18 - Remove unneeded code.
#    manuegar    07/11/18 - manuegar_multibug_01.
#    bibsahoo    05/03/18 - FIX BUG 27864732
#    bibsahoo    07/21/17 - FIX BUG 25922581
#    bibsahoo    07/04/17 - FIX BUG 26352393
#    bibsahoo    11/02/16 - FIX BUG 25025907 - LNX64-12.2-TFA:DBGLEVEL SET
#                           TRACE LEVEL FOR ASM_DG_FAILURE FAILED
#    manuegar    11/02/16 - Bug 24948477 - WS2012_122_TFA: HELP INFORMATION FOR
#                           'TFACTL RUN GREP' INCORRECT.
#    bibsahoo    07/25/16 - FIX BUG 24343838
#    bibsahoo    07/12/16 - DBGlevel Support For Windows
#    bibsahoo    06/22/16 - FIX BUG 23624766 and Support of DBGLevel to run in
#                           typical install with GI installed
#    bibsahoo    06/08/16 - DBGLEVEL ADD CONDITIONAL STATEMENTS
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    bburton     05/09/16 - do not load crs resources until run
#    bibsahoo    04/21/16 - FIX BUG 21792941 - NEED RESTRUCTURE PROFILE
#                           COMMANDS TO ALLOW OTHER THAN CRSCTL COMMANDS
#    bibsahoo    03/15/16 - Adding Error statements for missing components
#    bibsahoo    03/14/16 - FIX BUG 21608350 - TFA DBGLEVEL PROFILES NEED TO BE
#                           ABLE TO WORK OUT RESOURCE DEPENDENCIES
#    bibsahoo    02/24/16 - FIX BUG 21660355 - NEED SOME FILES CREATED FOR
#                           DBGLEVEL TRACING
#    bibsahoo    12/06/15 - FIX BUG 22301591 - TIMEOUTS MISSING FROM DBGLEVEL
#                           PROFILES
#    bibsahoo    11/29/15 - FIX BUG 21608252 - NEED ABILITY TO LIMIT DBGLEVEL
#                           SETTINGS TO A DURATION OF TIME
#    manuegar    09/24/15 - Bug 21832933 - LNX64-12.2-TFA-DBGLEVEL:DID NOT
#                           GENERATE PROFILE FILE AFTER CREATE PROFILE.
#    manuegar    07/07/15 - Bug 21386623 - LNX64-12.2-TFA:DBGLEVEL COMMANDS
#                           AREN'T RECOGNIZED AFTER -LSMODULES WAS EXECUTED.
#    manuegar    04/13/15 - Bug 20803141 - LNX64-12.2-TFA:TWO UNSET IN DBGLEVEL
#                           HELP MSG.
#    gadiga      03/24/15 - fix 20666289. dont show help from remote node
#    manuegar    03/18/15 - Return meaningful msgs when CRS stack is down.
#    manuegar    03/17/15 - Use default value if unset value is not set.
#    manuegar    03/05/15 - 20651676 LNX64-12.2-TFA: PROFILE NAME DID NOT
#                           SUPPORT WITH "_
#    manuegar    02/27/15 - Remove debugging info.
#    manuegar    02/10/15 - 20509555 LNX64-12.2-TFA:DBGLEVEL COMMANDS PRINT
#                           LOTS OF "COMMAND NOT FOUND
#    manuegar    01/09/15 - Creation
#
package dbglevel;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(deploy
                 autostart
                 start
                 stop
                 restart
                 status
                 run
                 runstatus
                 is_running
                 help
                );

use strict;
use English;
#use warnings;

use Math::BigInt;

use List::Util qw[min max];
use POSIX qw(:termios_h);
use POSIX;
use File::Basename;
use File::Spec::Functions;
use File::Path;
#use File::Spec;
use Getopt::Long;
use Exporter;

use Data::Dumper;
use Getopt::Long;

use tfactlglobal;
use tfactlshare;
use tfactlmineocr;

#use constant TRUE                      =>  "1";
#use constant FALSE                     =>  "0";
my $tool = "dbglevel";
my $tfa_base = tfactlshare_get_repository_location($tfa_home);
my $oracle_base = get_oracle_base($tfa_home);
my $tool_dir = catfile($tfa_base, "suptools", "$hostname", $tool);
my $tool_base = catfile($tfa_base, "suptools", "$hostname", $tool, $current_user);

my %res;

my @retArr;
#my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");
#if ( dbglevel_validate_gi($tfa_home,$install_type,1) eq "GI" ) {
#  (%res) = getCrsdResourcesCfg();
#}

sub deploy
{
  my $tfa_home = shift;

  return 0;
}

sub is_running
{
  return 2;
}

sub runstatus
{
  return 3;
}

sub autostart
{
  return 0;
}

sub start
{
  print "Nothing to do !\n";
  return 1;
}

sub stop
{
  print "Nothing to do !\n";
  return 1;
}

sub restart
{
  print "Nothing to do !\n";
  return 1;
}

sub status
{
  print "Dbglevel does not run in daemon mode\n";
  return 1;
}

sub run
{
no strict 'vars';
  my $tfa_home = shift;
  my @args = @_;
  my $db = "";
  my $easycs = "";
  my $tfa_profile_xml;
  my %changes = ();
  my $profilename;
  my $profiledesc;
  my $pset;
  my @aset;
  my $punset;
  my @aunset;
  my $pincunset;
  my @aincunset;
  my $punsetflag = FALSE;
  my $pcreate;
  my @acreate;
  my $pdrop;
  my @adrop;
  my $pmodify;
  my @amodify;
  my $pview;
  my @aview;
  my $pls;
  my @als;
  my $plsmodules;
  my @alsmodules;
  my $plscomponents;
  my @alscomponents;
  my $plsres;
  my @alsres;
  my $pcreatessd;
  my @acreatessd;
  my $pactive;
  my @aactive;
  my $pgetstate;
  my @agetstate;
  my $pgetmod;
  my @agetmod;
  my $pgetmodval;
  my $pgetres;
  my $pinctrace;
  my @ainctrace;
  my $ptraceflag = FALSE;
  my @adesc;
  my $pdesc;
  my @adescribe;
  my $pdescribe;
  my @atimeout;
  my $ptimeout;
  my $profiletimeout;
  my $help;
  my $unknownopt;
  my $crsdaemon="";
  my $pcommandsfound = 0;
  my @anobroadcast;
  my $pnobroadcast;
  my %avresources;
  my @adependency;
  my $dependency = "start";
  my @adependency_type;
  my $dependency_type = "hard";
  my $retval = 0;

  my %options = ( "set"          => \@aset,
                  "unset"        => \@aunset,
                  "create"       => \@acreate,
                  "drop"         => \@adrop,
                  "modify"       => \@amodify,
                  "h"            => \$help,
                  "desc"         => \@adesc,
                  "describe"     => \@adescribe,
                  "timeout"  => \@atimeout,
                  "view"         => \@aview,
                  "lsprofiles"   => \@als,
                  "lsmodules"    => \@alsmodules,
                  "lsres"        => \@alsres,
                  "lscomponents" => \@alscomponents,
                  "debugstate"   => \@acreatessd,
                  "active"       => \@aactive,
                  "getstate"     => \@agetstate,
                  "module"       => \@agetmod,
                  "nobroadcast"    => \@anobroadcast,
                  "resources"    => \$pgetres,
                  "dependency"   => \@adependency,
                  "dependency_type"    => \@adependency_type,
                  "includetrace" => \@ainctrace,
                  "includeunset" => \@aincunset,
                  "help"         => \$help );
  my @arrayoptions = ( "set=s{1}",
                       "unset:s",
                       "create=s{1}",
                       "drop=s{1}",
                       "modify=s{1}",
                       "desc=s",
                       "describe=s",
                       "timeout=s",
                       "view=s{1}",
                       "lsprofiles",
                       "lsmodules",
                       "lsres",
                       "nobroadcast",
                       "lscomponents:s",
                       "debugstate",
                       "active:s",
                       "getstate",
                       "module:s",
                       "resources",
                       "dependency=s",
                       "dependency_type=s",
                       "includetrace",
                       "includeunset",
                       "h",
                       "help" );

  if ( $current_user ne "root" ) {
    print "\nAccess Denied: Only TFA Admin can run this command\n\n";
    return 1;
  }

  GetOptions(\%options, @arrayoptions )
  or $unknownopt = 1;

  if ( $help || $unknownopt ) {
    help();
    return 1 if ( $unknownopt );
    return 0;
  }

  tfactlshare_trace(5, "tfactl (PID = $$) dbglevel run " .
                    "Running dbglevel", 'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) dbglevel run " .
                    "Args received @args", 'y', 'y');

  # Process options
  if ( @aset && $#aset == 0 ) {
    $pset = $aset[0];
  } elsif ( @aset )  {
    help();
    return 1;
  }

  if ( $pset ) {
    $profilename = $pset;
    $pcommandsfound++;
  }

  if ( @aunset && $#aunset == 0 ) {
    $punset = $aunset[0];
  } elsif ( @aunset )  {
    help();
    return 1;
  }

  if ( defined $punset ) {
    if ( length $punset ) {
      $profilename = $punset;
      $pcommandsfound++;
    } else {
      help();
      return 1;
    }
  }

  if ( @aincunset && $#aincunset == 0 ) {
    $pincunset = $aincunset[0];
  } elsif ( @aincunset )  {
    help();
    return 1;
  }

  if ( $pincunset ) {
    $punsetflag = TRUE;
  }

  if ( @agetstate && $#agetstate == 0 ) {
    $pgetstate = $agetstate[0];
  } elsif ( @agetstate )  {
    help();
    return 1;
  }

  if ( @agetmod && $#agetmod == 0 ) {
    $pgetmod = $agetmod[0];
  } elsif ( @agetmod )  {
    help();
    return 1;
  }

  if ( $pgetstate ) {
    $profilename = "";
    $pgetmodval = "";
    $pcommandsfound++;
    if ( defined $pgetmod && length $pgetmod ) {
      $pgetmodval = $pgetmod;
    }
  }

  if ( ( defined $pgetmod && not $pgetstate ) ||
       ( $pgetres && not $pgetstate ) ) {
    help();
    return 1;
  }

  if ( @acreate && $#acreate == 0 ) {
    $pcreate = $acreate[0];
  } elsif ( @acreate )  {
    help();
    return 1;
  }

  if ( $pcreate ) {
    $profilename = $pcreate;
    $pcommandsfound++;
  }

  if ( @acreatessd && $#acreatessd == 0 ) {
    $pcreatessd = $acreatessd[0];
  } elsif ( @acreatessd )  {
    help();
    return 1;
  }

  if ( $pcreatessd && not $pcreate ) {
    help();
    return 1;
  }

  if ( @adesc && $#adesc == 0 && $#acreate == 0 ) {
    $pdesc = $adesc[0];
  } elsif ( @adesc )  {
    help();
    return 1;
  }

  if ( $pdesc ) {
    $profiledesc = $pdesc;
  }

  if ( @atimeout && $#atimeout == 0 ) {
    $ptimeout = $atimeout[0];
  } elsif ( @atimeout )  {
    help();
    return 1;
  }

  if ( $ptimeout ) {
    $profiletimeout = $ptimeout;
  } else {
    $profiletimeout = -1;
  }

  if ( @adescribe && $#adescribe == 0 ) {
    $pdescribe = $adescribe[0];
  } elsif ( @adescribe )  {
    help();
    return 1;
  }

  if ( $pdescribe ) {
    $profilename = $pdescribe;
    $pcommandsfound++;
  }

  if ( @amodify && $#amodify == 0 ) {
    $pmodify = $amodify[0];
  } elsif ( @amodify )  {
    help();
    return 1;
  }

  if ( $pmodify ) {
    $profilename = $pmodify;
    $pcommandsfound++;
  }

  if ( @ainctrace && $#ainctrace == 0 ) {
    $pinctrace = $ainctrace[0];
  } elsif ( @ainctrace )  {
    help();
    return 1;
  }

  if ( $pinctrace  && not ( $pcreate || $pmodify ) ) {
    help();
    return 1;
  }

  if ( $punsetflag && not ( $pcreate || $pmodify ) ) {
    help();
    return 1;
  }

  if ( @adrop && $#adrop == 0 ) {
    $pdrop = $adrop[0];
  } elsif ( @adrop )  {
    help();
    return 1;
  }

  if ( $pdrop ) {
    $profilename = $pdrop;
    $pcommandsfound++;
  }

  if ( @aview && $#aview == 0 ) {
    $pview = $aview[0];
  } elsif ( @aview )  {
    help();
    return 1;
  }

  if ( $pview ) {
    $profilename = $pview;
    $pcommandsfound++;
  }

  if ( @aactive && $#aactive == 0 ) {
    $pactive = $aactive[0];
  } elsif ( @aactive )  {
    help();
    return 1;
  }

  if ( defined $pactive ) {
    $pcommandsfound++;
    if ( length $pactive ) {
      $profilename = $pactive;
    } else {
      $profilename = "";
    }
  }

  if ( @als && $#als == 0 ) {
    $pls = $als[0];
  } elsif ( @als )  {
    help();
    return 1;
  }

  if ( $pls ) {
    $profilename = "";
    $pcommandsfound++;
  }

  if ( @alsmodules && $#alsmodules == 0 ) {
    $plsmodules = $alsmodules[0];
  } elsif ( @alsmodules )  {
    help();
    return 1;
  }

  if ( $plsmodules ) {
    $profilename = "";
    $pcommandsfound++;
  }

  if ( @alsres && $#alsres == 0 ) {
    $plsres = 1;
    $profilename = "";
    $pcommandsfound++;
  } elsif ( @alsres )  {
    help();
    return 1;
  }

  if ( @anobroadcast && $#anobroadcast == 0 ) {
    $pnobroadcast = 1;
  } elsif ( @anobroadcast )  {
    help();
    return 1;
  }

  if ( @adependency && $#adependency == 0 ) {
    my @dep = split /,/,$adependency[0];
    foreach my $x (@dep) {
      if ( lc($x) ne "start" && lc($x) ne "stop" && lc($x) ne "all" ) {
        help();
        return 1;
      }
    }
    $dependency = $adependency[0];
  } elsif ( @adependency )  {
    help();
    return 1;
  }

  if ( @adependency_type && $#adependency_type == 0 ) {
    my @types = split /,/,$adependency_type[0];
    foreach my $x (@types) {
      if ( lc($x) ne "hard" && lc($x) ne "weak" && lc($x) ne "dispersion" && lc($x) ne "pullup" && lc($x) ne "all" ) {
        help();
        return 1;
      }
    }
    $dependency_type = $adependency_type[0];
  } elsif ( @adependency_type )  {
    help();
    return 1;
  }

  if ( @alscomponents && $#alscomponents == 0 ) {
    $plscomponents = $alscomponents[0];
  } elsif ( @alscomponents )  {
    help();
    return 1;
  }

  if ( defined $plscomponents ) {
    $profilename = "";
    $pcommandsfound++;
    if ( length $plscomponents ) {
      $crsdaemon = $plscomponents;
    }
  }

  tfactlshare_trace(5, "tfactl (PID = $$) dbglevel run " .
                     "Total commands found $pcommandsfound", 'y', 'y');
  if ( @ARGV || $#args == -1 || $pcommandsfound > 1 ) {
    help();
    return 1;
  }

  if ( $profilename =~ /([a-zA-Z0-9\_\-]+)\.xml/ ) {
    $profilename = $1;
  } elsif ( $profilename =~ /([a-zA-Z0-9\_\-]+)/ ) {
    $profilename = $1;
  }

  # Init tfa_ext_xml file
  my $profilesdir = catfile($tfa_home, "ext", "dbglevel","profiles");
  if ( not -d $profilesdir ) {
    eval { tfactlshare_mkpath("$profilesdir", "1740");
         };
    if ($@)
    {
      print STDERR "Can not create path $profilesdir.\n";
      tfactlshare_trace(3, "tfactl (PID = $$) tfactlshare_init_trace " .
                        "Can not create path $profilesdir.",'y', 'n');
      return 1;
    }
  }
  $tfa_profile_xml = catfile("$profilesdir", $profilename.".xml");

  if ( $pset ) {
    $retval = dbglevel_process_set("set",$tfa_home,$tfa_profile_xml,$profilename,$profiletimeout,$pnobroadcast,$dependency,$dependency_type);
    tfactlshare_trace(5, "tfactl (PID = $$) dbglevel run " .
                     "Set selected", 'y', 'y');
  } elsif ( $punset ) {
    $retval = dbglevel_process_set("unset",$tfa_home,$tfa_profile_xml,$profilename,-1,$pnobroadcast,$dependency,$dependency_type);
    tfactlshare_trace(5, "tfactl (PID = $$) dbglevel run " .
                     "Unset selected", 'y', 'y');
  } elsif ( $pview ) {
    $retval = dbglevel_process_set("view",$tfa_home,$tfa_profile_xml,$profilename,-1,$pnobroadcast,$dependency,$dependency_type);
    tfactlshare_trace(5, "tfactl (PID = $$) dbglevel run " .
                     "View selected", 'y', 'y');
  } elsif ( $pcreatessd ) {
    $retval = dbglevel_process_ssdump($tfa_home,$tfa_profile_xml,$profilename,$profiledesc);
    tfactlshare_trace(5, "tfactl (PID = $$) dbglevel run " .
                      "System State Dump selected", 'y', 'y');
  } elsif ( $pgetstate ) {
    $retval = dbglevel_process_ssview($tfa_home,$pgetmodval);
    tfactlshare_trace(5, "tfactl (PID = $$) dbglevel run " .
                      "View System State selected", 'y', 'y');
  } elsif ( $pcreate ) {
    $ptraceflag = TRUE if $pinctrace;
    $retval = dbglevel_process_create_handle("create",$tfa_home,$tfa_profile_xml,$profilename,$profiledesc,$ptraceflag,
                            $punsetflag,$profiletimeout);
    tfactlshare_trace(5, "tfactl (PID = $$) dbglevel run " .
                      "Create selected", 'y', 'y');
  } elsif ( $pdrop ) {
    $retval = dbglevel_process_drop($tfa_home,$tfa_profile_xml,$profilename);
    tfactlshare_trace(5, "tfactl (PID = $$) dbglevel run " .
                      "Drop selected", 'y', 'y');
  } elsif ( $pmodify ) {
    $ptraceflag = TRUE if $pinctrace;
    $retval = dbglevel_process_create_handle("modify",$tfa_home,$tfa_profile_xml,$profilename,$ptraceflag,
                            $punsetflag,$profiletimeout);
    tfactlshare_trace(5, "tfactl (PID = $$) dbglevel run " .
                      "Modify selected", 'y', 'y');
  } elsif ( $pdescribe ) {
    $ptraceflag = TRUE if $pinctrace;
    $retval = dbglevel_get_description($tfa_profile_xml,$profilename);
    tfactlshare_trace(5, "tfactl (PID = $$) dbglevel run " .
                      "Describe selected", 'y', 'y');
  } elsif ( $pls ) {
    $retval = dbglevel_process_ls($tfa_home);
    tfactlshare_trace(5, "tfactl (PID = $$) dbglevel run " .
                      "lsprofiles selected", 'y', 'y');
  } elsif ( $plsmodules ) {
    $retval = dbglevel_process_lsmodules($tfa_home);
    tfactlshare_trace(5, "tfactl (PID = $$) dbglevel run " .
                      "lsmodules selected", 'y', 'y');
  } elsif ( defined $plscomponents ) {
    $retval = dbglevel_process_lscomponents($tfa_home,$crsdaemon);
    tfactlshare_trace(5, "tfactl (PID = $$) dbglevel run " .
                      "lscomponents selected", 'y', 'y');
  } elsif ( defined $pactive ) {
    $retval = dbglevel_process_active($tfa_home,$tfa_profile_xml,$profilename);
    tfactlshare_trace(5, "tfactl (PID = $$) dbglevel run " .
                      "active selected", 'y', 'y');
  } elsif ( $plsres ) {
    $retval = dbglevel_process_lsres($tfa_home);
    tfactlshare_trace(5, "tfactl (PID = $$) dbglevel run " .
                      "lsres selected", 'y', 'y');
  }

  return $retval;
}

sub help
{
  my $cmd;
  if ( $0 =~ /(.*)\.pl/ ) {
    $cmd = $1;
  }
  print "Usage : $cmd [run] dbglevel [ {-set|-unset} <profile_name> -dependency [<dep1>,<dep2>,...|all] -dependency_type [<type1>,<type2>,<type3>,...|all] | {-view|-drop} <profile_name> | -lsprofiles | -lsmodules | -lscomponents [module_name] | -lsres | -create <profile_name> [ -desc <description> | [-includeunset] [-includetrace] | -debugstate | -timeout <time> ] | -modify <profile_name> [-includeunset] [-includetrace] | -getstate [ -module <module_name> ] | -active [profile_name] | -describe [profile_name] ] ]\n\n";
  print "Options: \n";
  print "profile_name   : Profile name\n";
  print "active         : Show active profiles\n";
  print "set            : Set the trace/log levels for the given profile\n";
  print "unset          : Unset the trace/log levels for the given profile\n";
  print "view           : View the log/trace entries for the given profile\n";;
  print "create         : Creates a new profile\n";
  print "drop           : Drops the given profile\n";
  print "modify         : Modifies the given profile\n";
  print "describe       : Describes the given profile\n";
  print "lsprofiles     : List all the available profiles\n";
  print "lsmodules      : List all the discovered CRS modules\n";
  print "lscomponents   : List all the components associated with the CRS module\n";
  print "lsres          : List all the discovered CRS resources\n";
  print "getstate       : View the current log/trace levels for the CRS components/resources\n";
  print "module         : CRS module\n";
  print "dependency     : Dependencies to be considered (start or stop dependencies or both)\n";
  print "dependency_type: Type of dependencies to be considered\n";
  print "timeout        : Sets a default timeout for the profile\n";
  print "debugstate     : Generate a System State Dump for all the\n";
  print "                 available levels\n";
  print "includeunset   : Add/Modify an unset value for the CRS components/resources\n";
  print "includetrace   : Add/Modify a trace value for the CRS components\n\n";
  print "Warning, the profiles should only be set at the direction of Oracle Support.\n";
  return 0;

}

########
# NAME
#   dbglevel_validate_gi
#
# DESCRIPTION
#   This function validates
#   the install_type to make sure that
#   we are running a GI installation.
#
# PARAMETERS
#   $tfa_home        (IN) - TFA Home
#
# RETURNS
#
########
sub dbglevel_validate_gi {
  my $tfa_home        = shift;
  my $install_type    = shift;
  my $silent          = shift;
  my $crs_home = get_crs_home($tfa_home);

  if ( $install_type eq "GI" || length("$crs_home") != 0 ) {
    $ENV{'GI_HOME'}     = $crs_home."/";
    $ENV{'ORACLE_HOME'} = $crs_home."/";
    if ($IS_WINDOWS) {
      $ENV{'PATH'} = catfile($ENV{GI_HOME}, "bin") . $PSEP . catfile($ENV{ORACLE_HOME}, "bin");
    } else {
      $ENV{'PATH'} = catfile($ENV{GI_HOME}, "bin") . $PSEP . catfile($ENV{ORACLE_HOME}, "bin") . $PSEP . $ENV{PATH} . $PSEP . catfile("", "bin") . $PSEP . catfile("", "usr", "bin");
    }

    # Check if HA Services are available
    my $line;
    my $commandline = catfile($ENV{ORACLE_HOME}, "bin", $crsctl) . " check crs";
    my $stackdown = FALSE;
    foreach $line (split /\n/, `$commandline`) {
      if ( $line =~ /CRS\-4639/ ) {  # Check HA stack
        $stackdown = TRUE;
      }
    } # end foreach $commandline
    if ( $stackdown ) {
      if ($silent == 0) {
        print "Could not contact Oracle High Availability Services.\n";
        print "Please start HA Services and try again.\n";
        return 1;
      }
      return "STACKDOWN";
    } else {
      return "GI";
    }
  } else {
    if ($silent == 0) {
      print "GI installation not detected, execution disabled.\n";
    }
    return "NOTGI";
  }

}

########
# NAME
#   dbglevel_process_ssview
#
# DESCRIPTION
#   This function queries
#   the current levels for all
#   modules and resources
#
# PARAMETERS
#   $tfa_home        (IN) - TFA Home
#   $crsdaemon       (IN) - CRS module
#
# RETURNS
#
########
sub dbglevel_process_ssview {

  my $tfa_home        = shift;
  my $crsdaemon       = shift;
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");
  my $crs_home;
  my (%usermodules) = ();
  my (@modulesarray) = ();
  my (%crsdaemons) = ();
  my @crsmodules;
  my $formattedstring = "";
  my $itemscounter = 0;
  my $currlogvalue;
  my $currtracevalue;
  my $modkey;

  return 1 if dbglevel_validate_gi($tfa_home,$install_type) ne "GI";

  %crsdaemons = dbglevel_load_crs_modules($tfa_home);

  tfactlshare_trace(5, "tfactl (PID = $$) dbglevel_load_crs_components " .
                    "CRS_HOME  $crs_home", 'y', 'y');

  my $line;
  my $commandline;

  if ( defined $crsdaemon && length $crsdaemon ) {
    # validate if $crsdaemon is valid
    if ( not exists $crsdaemons{$crsdaemon} ) {
      print "$crsdaemon is not a valid module !\n";
      return;
    }
    @crsmodules = dbglevel_load_crs_components($crsdaemon);
    print "\nCurrent system levels for module $crsdaemon (log level, trace level),\n";
    $itemscounter = 0;
    for my $ndx (0 .. $#crsmodules) {
       # Get current values for log and trace
      $currlogvalue  = dbglevel_get_current_levels( "log",
                       $crsdaemon, $crsmodules[$ndx] );
      $currtracevalue = dbglevel_get_current_levels( "trace",
                       $crsdaemon, $crsmodules[$ndx] );
      # Format
      $formattedstring .= sprintf("%-18s ","$itemscounter) $crsmodules[$ndx] ($currlogvalue,$currtracevalue)");
      if ( ++$itemscounter % 4 == 0 || $ndx == $#crsmodules ) {
        print "$formattedstring\n";
        $formattedstring = "";
      } # end if formattedstring
    } # end for
  } else {
    foreach my $daemonkey (keys %crsdaemons) {
      @crsmodules = dbglevel_load_crs_components($daemonkey);
      print "\nCurrent system levels for module $daemonkey (log level, trace level),\n";
      $itemscounter = 0;
      for my $ndx (0 .. $#crsmodules) {
        # Get current values for log and trace
        $currlogvalue  = dbglevel_get_current_levels( "log",
                         $daemonkey, $crsmodules[$ndx] );
        $currtracevalue = dbglevel_get_current_levels( "trace",
                         $daemonkey, $crsmodules[$ndx] );

        # Prepare hash entries
        $modkey = $daemonkey.".".$crsmodules[$ndx];
        $usermodules{$modkey} = [ $currlogvalue, $currlogvalue,
                                  $currtracevalue, $currtracevalue ];
        # Format
        $formattedstring .= sprintf("%-18s ","$itemscounter) $crsmodules[$ndx] ($currlogvalue,$currtracevalue)");
        if ( ++$itemscounter % 4 == 0 || $ndx == $#crsmodules ) {
          print "$formattedstring\n";
          $formattedstring = "";
        } # end if formattedstring
      } # end for
    } # end foreach %crsdaemons
  } # end if display all daemons

  # Load available resources if any
  $formattedstring = "";
  $itemscounter = 0;
  my @resources;
  my $resourcedone = FALSE;
# my (%userresources) = ();

  @resources = dbglevel_load_resources($tfa_home);

  print "\nCurrent system levels for resources (log level),\n";

  $itemscounter = 0;
  for my $modndx ( 0..$#resources ) {
       $currlogvalue  = dbglevel_get_current_levels( "resource",
                        $resources[$modndx], $resources[$modndx]  );
       $modkey = "RESOURCE." . $resources[$modndx] ;
       $usermodules{$modkey} = [ $currlogvalue, $currlogvalue, 0, 0 ];

       $formattedstring .= sprintf("%-40s ","$modndx) $resources[$modndx] " .
                           "( $currlogvalue )");
       if ( ++$itemscounter % 2 == 0 || $modndx == $#resources ) {
         print "$formattedstring\n";
         $formattedstring = "";
       }
  } # end for @resources

  return;
}

########
# NAME
#   dbglevel_process_ssdump
#
# DESCRIPTION
#   This function generates a SSD
#   of all the current levels
#
# PARAMETERS
#   $tfa_home        (IN) - TFA Home
#   $tfa_profile_xml (IN) - xml profile
#   $profilename     (IN) - profile name
#
# RETURNS
#
########
sub dbglevel_process_ssdump {
  my $tfa_home        = shift;
  my $tfa_profile_xml = shift;
  my $profilename     = shift;
  my $profiledesc     = shift;
  my $crsdaemon = "";
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");
  my $crs_home;
  my (%usermodules) = ();
  my (@modulesarray) = ();
  my (%crsdaemons) = ();
  my @crsmodules;
  my $formattedstring = "";
  my $itemscounter = 0;
  my $currlogvalue;
  my $currtracevalue;
  my $count;
  my $modkey;

  return 1 if dbglevel_validate_gi($tfa_home,$install_type) ne "GI";

  %crsdaemons = dbglevel_load_crs_modules($tfa_home);

  tfactlshare_trace(5, "tfactl (PID = $$) dbglevel_load_crs_components " .
                    "CRS_HOME  $crs_home", 'y', 'y');

  if ( -e "$tfa_profile_xml" ) {
    my $selectionval;
    print "Profile $profilename  already exists in directory $tfa_home/ext/dbglevel/profiles.\n";
    $selectionval = tfactlshare_get_choice_yn("y","n",
            "Do you want to replace this profile [y,n, default n]?", "n" );
    if ( uc($selectionval) eq "N" ) {
        return;
    }
  } # end if -e $tfa_profile_xml

  my $line;
  my $commandline;

  if ( defined $crsdaemon && length($crsdaemon) > 0 ) {
    # validate if $crsdaemon is valid
    if ( not exists $crsdaemons{$crsdaemon} ) {
      print "$crsdaemon is not a valid module !\n";
      return;
    }
    @crsmodules = dbglevel_load_crs_components($crsdaemon);
    print "\nProcessing components for module $crsdaemon,\n";
    $itemscounter = 0;
    for my $ndx (0 .. $#crsmodules) {
      $formattedstring .= sprintf("%-15s ","$itemscounter) $crsmodules[$ndx]");
      if ( ++$itemscounter % 4 == 0 || $ndx == $#crsmodules ) {
        print "$formattedstring\n";
        $formattedstring = "";
      } # end if formattedstring
    } # end for
  } else {
    foreach my $daemonkey (keys %crsdaemons) {
      @crsmodules = dbglevel_load_crs_components($daemonkey);
      print "\nProcessing components for module $daemonkey,\n";
      $itemscounter = 0;
      for my $ndx (0 .. $#crsmodules) {
        # Get current values for log and trace
        $currlogvalue  = dbglevel_get_current_levels( "log",
                         $daemonkey, $crsmodules[$ndx] );
        $currtracevalue = dbglevel_get_current_levels( "trace",
                         $daemonkey, $crsmodules[$ndx] );

        # Prepare hash entries
        $modkey = $daemonkey.".".$crsmodules[$ndx];
        $usermodules{$modkey} = [ $currlogvalue, $currlogvalue,
                                  $currtracevalue, $currtracevalue ];
        # Format
        $formattedstring .= sprintf("%-18s ","$itemscounter) $crsmodules[$ndx] ($currlogvalue,$currtracevalue)");
        if ( ++$itemscounter % 4 == 0 || $ndx == $#crsmodules ) {
          print "$formattedstring\n";
          $formattedstring = "";
        } # end if formattedstring
      } # end for
    } # end foreach %crsdaemons
  } # end if display all daemons

  # Load available resources if any
  $formattedstring = "";
  $itemscounter = 0;
  my @resources;
  my $resourcedone = FALSE;
# my (%userresources) = ();

  @resources = dbglevel_load_resources($tfa_home);

  print "\nProcessing resources,\n";

  $itemscounter = 0;
  for my $modndx ( 0..$#resources ) {
       $currlogvalue  = dbglevel_get_current_levels( "resource",
                        $resources[$modndx], $resources[$modndx]  );
       $modkey = "RESOURCE." . $resources[$modndx] ;
       $usermodules{$modkey} = [ $currlogvalue, $currlogvalue, 0, 0 ];

       $formattedstring .= sprintf("%-40s ","$modndx) $resources[$modndx] " .
                           "( $currlogvalue )");
       if ( ++$itemscounter % 2 == 0 || $modndx == $#resources ) {
         print "$formattedstring\n";
         $formattedstring = "";
       }
  } # end for @resources


  # Generate profile
  dbglevel_generate_profile(\%usermodules,$tfa_home,$tfa_profile_xml,
                           $profilename,"debugstate",$profiledesc);

  $count = keys %usermodules;
  if ( $count ) {
    print "\nDebugstate $profilename was successfully created !\n";
  } else {
    print "\nDebugstate $profilename was not created !\n";
  }

  return;
}

########
# NAME
#   dbglevel_process_lscomponents
#
# DESCRIPTION
#   This function displays the modules
#   associated with the CRS module
#
# PARAMETERS
#   $crsdaemon - crs module (optional)
#
# RETURNS
#
########
sub dbglevel_process_lscomponents {
  my $tfa_home  = shift;
  my $crsdaemon = shift;
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");
  my $crs_home;
  my (@modulesarray) = ();
  my (%crsdaemons) = ();
  my @crsmodules;
  my $formattedstring = "";
  my $itemscounter = 0;

  return 1 if dbglevel_validate_gi($tfa_home,$install_type) ne "GI";

  %crsdaemons = dbglevel_load_crs_modules($tfa_home);

  tfactlshare_trace(5, "tfactl (PID = $$) dbglevel_load_crs_components " .
                    "CRS_HOME  $crs_home", 'y', 'y');
  my $line;
  my $commandline;

  if ( defined $crsdaemon && length($crsdaemon) > 0 ) {
    # validate if $crsdaemon is valid
    if ( not exists $crsdaemons{$crsdaemon} ) {
      print "$crsdaemon is not a valid module !\n";
      return 1;
    }
    @crsmodules = dbglevel_load_crs_components($crsdaemon);
    print "\nAvailable components for module $crsdaemon,\n";
    $itemscounter = 0;
    for my $ndx (0 .. $#crsmodules) {
      $formattedstring .= sprintf("%-15s ","$itemscounter) $crsmodules[$ndx]");
      if ( ++$itemscounter % 4 == 0 || $ndx == $#crsmodules ) {
        print "$formattedstring\n";
        $formattedstring = "";
      } # end if formattedstring
    } # end for
  } else {
    foreach my $daemonkey (keys %crsdaemons) {
      @crsmodules = dbglevel_load_crs_components($daemonkey);
      print "\nAvailable components for module $daemonkey,\n";
      $itemscounter = 0;
      for my $ndx (0 .. $#crsmodules) {
        $formattedstring .= sprintf("%-15s ","$itemscounter) $crsmodules[$ndx]");
        if ( ++$itemscounter % 4 == 0 || $ndx == $#crsmodules ) {
          print "$formattedstring\n";
          $formattedstring = "";
        } # end if formattedstring
      } # end for
    } # end foreach %crsdaemons
  } # end if display all daemons

  return;
}

########
# NAME
#   dbglevel_load_crs_components
#
# DESCRIPTION
#   This function loads the crs components
#   for the given module
#
# PARAMETERS
#   $crsdaemon - crs module
#
# RETURNS
#   A hash of available components
#
########
sub dbglevel_load_crs_components {
  my $crsdaemon = shift;
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");
  my $crs_home;
  my (@modulesarray) = ();

  return 1 if dbglevel_validate_gi($tfa_home,$install_type) ne "GI";

  tfactlshare_trace(5, "tfactl (PID = $$) dbglevel_load_crs_components " .
                    "CRS_HOME  $crs_home", 'y', 'y');
  my $line;
  my $commandline = catfile($ENV{ORACLE_HOME}, "bin", $crsctl) . " lsmodules $crsdaemon";
  foreach $line (split /\n/, `$commandline`) {
    if ( $line =~ /.*\:\s+([a-zA-Z]+)\s*/ ) {  # Retrieve the modules
       #print "Module $1 \n";
       push @modulesarray, $1;
    } 
  } # end foreach $commandline

  return @modulesarray;
}

########
# NAME
#   dbglevel_load_crs_modules
#
# DESCRIPTION
#   This function loads the crs modules
#
# PARAMETERS
#
# RETURNS
#   A hash of available daemons
#
########
sub dbglevel_load_crs_modules {
  my $tfa_home = shift;
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");
  my $crs_home;
  my (%daemonshash) = ();

  return 1 if dbglevel_validate_gi($tfa_home,$install_type) ne "GI";

  tfactlshare_trace(5, "tfactl (PID = $$) dbglevel_load_crs_components " .
                    "CRS_HOME  $crs_home", 'y', 'y');

  my $line;
  my $commandline = catfile($ENV{ORACLE_HOME}, "bin", $crsctl) . " lsmodules";
  foreach $line (split /\n/, `$commandline`) {
     if ( $line !~ /(Usage|lsmodules|where)/ ) {
       if ( $line =~ /\s*([a-zA-Z]+)\s+(.*)/ ) {  # Retrieve daemon & description
          $daemonshash{$1} = $2;
       }
     }
  } # end foreach $commandline

  return %daemonshash;
}

#######
# NAME
#   dbglevel_load_resources
#
# DESCRIPTION
#   This function loads the resources
#
# PARAMETERS
#
# RETURNS
#   A hash of available resources
#
########
sub dbglevel_load_resources {
  my $tfa_home = shift;
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");
  my $crs_home;
  my @resources ;

  return 1 if dbglevel_validate_gi($tfa_home,$install_type) ne "GI";

  my $line;
  my $commandline = catfile($ENV{ORACLE_HOME}, "bin", $crsctl) . " status resource";
  foreach $line (split /\n/, `$commandline`) {
    if ( $line =~ /NAME=(.*)/ ) {  # Retrieve the resource
      #print "Resource, $1\n";
      push @resources, $1;
    }
  } # end foreach $commandline

  return @resources;
}

########
# NAME
#   dbglevel_get_current_levels
#
# DESCRIPTION
#   This function gets the current levels
#   for log and trace
#
# PARAMETERS
#   $cmdtype    - resource , module
#   $daemon
#   $module
#
# RETURNS
#   Log and trace levels
#
########
sub dbglevel_get_current_levels {
  my $cmdtype   = shift;
  my $daemon = shift;
  my $module = shift;
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");
  my $crs_home;
  my $loglevel=2;

  return 1 if dbglevel_validate_gi($tfa_home,$install_type) ne "GI";

  my $line;
  my $commandline;

  if ( lc($cmdtype) eq "log" ) {
    $commandline = catfile($ENV{ORACLE_HOME}, "bin", $crsctl) . " get log $daemon $module";
    foreach $line (split /\n/, `$commandline`) {
       if ( $line =~ /.*Level\:\s*([0-9]+)/ ) {  # Retrieve the levels
         $loglevel = $1;
       } elsif ( $line =~ /CRS-4000/ ) {
         $loglevel = -1;
       }
    } # end foreach $commandline
  } elsif ( lc($cmdtype) eq "trace" ) {
    $commandline = catfile($ENV{ORACLE_HOME}, "bin", $crsctl) . " get trace $daemon $module";
    foreach $line (split /\n/, `$commandline`) {
       if ( $line =~ /.*Level\:\s*([0-9]+)/ ) {  # Retrieve the levels
         $loglevel = $1;
       } elsif ( $line =~ /CRS-4000/ || $line =~ /CRS.*Error/ ) {
         $loglevel = -1;
       }
    } # end foreach $commandline
  } elsif ( lc($cmdtype) eq "resource" ) {
    if ($module !~ /\(/ && $module !~ /\)/) {
      $commandline = "\$ORACLE_HOME/bin/crsctl get log res $module";
      foreach $line (split /\n/, `$commandline`) {
         if ( $line =~ /.*Level\:\s*([0-9]+)/ ) {  # Retrieve the levels
           $loglevel = $1;
         } elsif ( $line =~ /CRS-4000/ || $line =~ /CRS.*Error/ ) {
           $loglevel = -1;
         }
      }
    } else {
      $loglevel = -1;
    } 
  }

  return $loglevel;
}

########
# NAME
#   dbglevel_set_level
#
# DESCRIPTION
#   This function sets the log/trace level
#   for the desired daemon/module
#
# PARAMETERS
#   $command - type of command used
#   $logtype - log, trace or resource
#   $daemon  - Name of the Daemon
#   $module  - Name of the Module
#   $level   - Log level to be set
#
# RETURNS
#   Command output
#
########
sub dbglevel_set_level {
  my $command = shift;
  my $logtype = shift;
  my $daemon = shift;
  my $module = shift;
  my $level  = shift;
  my $error  = FALSE;
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");
  my $crs_home;
  my $commandoutput;
  
  #print "CHECK: $command $logtype $daemon $module $level\n";
  
  return 1 if dbglevel_validate_gi($tfa_home,$install_type) ne "GI";

  my $line;
  if ( lc($command) eq "crsctl" ) {
    if ( lc($logtype) eq "log" ) {
      my $commandline = catfile($ENV{ORACLE_HOME}, "bin", $crsctl) . " set log $daemon \"$module:$level\"";
      foreach $line (split /\n/, `$commandline 2>&1`) {
        if ( $line =~ /Set.*Module.*/ ) {  # Retrieve the output
          $commandoutput = $line;
        } elsif ( $line =~ /CRS-4000/ || $line =~ /CRS.*Error/ ) {
          $commandoutput = "CRS-4000: Command Set failed, or completed with errors.";
          $error = TRUE;
        } elsif ( $line =~ /invalid component key name used/ ) {
          $commandoutput = "Warning: $daemon module: Invalid component $module";
          $error = TRUE;
        }
      } # end foreach $commandline
    } elsif ( lc($logtype) eq "trace" ) {
      my $commandline = catfile($ENV{ORACLE_HOME}, "bin", $crsctl) . " set trace $daemon \"$module:$level\"";
      foreach $line (split /\n/, `$commandline 2>&1`) {
        if ( $line =~ /Set.*Module.*/ ) {  # Retrieve the output
          $commandoutput = $line;
        } elsif ( $line =~ /CRS-4000/ || $line =~ /CRS.*Error/ ) {
          $commandoutput = "CRS-4000: Command Set failed, or completed with errors.";
          $error = TRUE;
        } elsif ( $line =~ /invalid component key name used/ ) {
          $commandoutput = "Warning: $daemon module: Invalid component $module";
          $error = TRUE;
        }
      } # end foreach $commandline
    } elsif ( lc($logtype) eq "resource" ) {
      my $commandline = catfile($ENV{ORACLE_HOME}, "bin", $crsctl) . " set log res \"$module:$level\"";

      my @discResources = dbglevel_load_resources($tfa_home);
      our %avresources = map { $_ => TRUE } @discResources;

      if ( ! exists $avresources{$module} ) {
        $commandoutput = "WARNING: Requested Resource $module is not available";
        print "$commandoutput\n";
        return 1;
      }

      foreach $line (split /\n/, `$commandline 2>&1`) {
        if ( $line =~ /Set.*Resource.*/ ) {  # Retrieve the output
            $commandoutput = $line;
        } elsif ( $line =~ /CRS-4000/ || $line =~ /CRS.*Error/ ) {
          $commandoutput = "CRS-4000: Command Set failed, or completed with errors.";
          $error = TRUE;
        }
      } # end foreach $commandline
    }
  } elsif ( lc($command) eq "oclumon" ) {
    if ( lc($logtype) eq "ologgerd" ) {
      my $commandline = catfile($ENV{ORACLE_HOME}, "bin", $oclumon) . " debug log $logtype \"$module:$level\"";
      foreach $line (split /\n/, `$commandline 2>&1`) {
        if ( $line =~ /CRS-9059/ ) {
          $commandoutput = "CRS-9059- Command Set failed, or completed with errors: Changing log level failed due to connection failure.";
          $error = TRUE;
        } else {
          if ( $line =~ /CRS.*Error/ ) {
            $commandoutput = $line;
            $error = TRUE;
          } else {
            $commandoutput = $line;
          }
        }
      }
    }
  }

  if ( not $error ) {
    return ($commandoutput);
  } else {
    print "$commandoutput\n";
    return 1;
  }
}

########
# NAME
#   dbglevel_process_ls
#
# DESCRIPTION
#   This function lists all the available profiles.
#
# PARAMETERS
#   $tfa_home        (IN) - TFA Home
#
# RETURNS
#
########
sub dbglevel_process_ls {
  my $tfa_home = shift;

  print "Available - profiles:\n\n";
  my $line;
  my $commandline;

  my $profiles_dir = catdir($tfa_home,"ext", "dbglevel", "profiles");

  opendir my $dh, $profiles_dir or print "Could not open '$profiles_dir' for reading: $!\n" and return;
  my @profiles = readdir $dh;

  foreach $line (@profiles) { 
    if ( $line =~ /\.xml/ ) {  # Retrieve profilename
      print catdir($tfa_home, "ext", "dbglevel", "profiles", "$line") . "\n";
    } 
  } # end foreach $commandline
  print "\n";

  return;
}

########
# NAME
#   dbglevel_process_lsmodules
#
# DESCRIPTION
#   This function displays the available CRS modules
#
# PARAMETERS
#
# RETURNS
#
########
sub dbglevel_process_lsmodules {
  my $tfa_home = shift;
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");
  my (%daemonshash) = ();
  my $ndx = 0;
  my $formattedstring = "";

  return  1 if dbglevel_validate_gi($tfa_home,$install_type) ne "GI";

  # Load available daemons
  %daemonshash = dbglevel_load_crs_modules($tfa_home);

  # ------------------------------------------
  # Iterate through the daemons

  print "\nCRS modules discovered,\n\n";
  foreach my $daemonskey ( sort keys %daemonshash ) {
    $formattedstring = sprintf("%-15s %-50s","$ndx) $daemonskey",
                        "$daemonshash{$daemonskey}");
    ++$ndx;
    print "$formattedstring\n";
  } # end foreach %daemonshash

  return;
}

########
# NAME
#   dbglevel_process_lsres
#
# DESCRIPTION
#   This function displays the available resources
#
# PARAMETERS
#
# RETURNS
#
########
sub dbglevel_process_lsres {
  my $tfa_home = shift;
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");
  my $formattedstring = "";
  my $itemscounter = 0;

  return 1 if dbglevel_validate_gi($tfa_home,$install_type) ne "GI";

  # Load available resources
  my @crsresources = dbglevel_load_resources($tfa_home);

  # ------------------------------------------
  # Iterate through the resources

  print "\nCRS resources discovered,\n\n";
  for my $ndx ( 0 .. $#crsresources ) {
    $formattedstring .= sprintf("%-35s ","$ndx) $crsresources[$ndx]");
    if ( ++$itemscounter % 2 == 0 || $ndx == $#crsresources ) {
      print "$formattedstring\n";
      $formattedstring = "";
    }
  } # end for

  return;
}

########
# NAME
#   dbglevel_list_res
#
# DESCRIPTION
#   This function returns a list of the available resources
#
# PARAMETERS
#   $tfa_home     (IN) - TFA Home
#
# RETURNS
#   A list of available resources
#
########
sub dbglevel_list_res {
  my $tfa_home = shift;
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");

  return 1 if dbglevel_validate_gi($tfa_home,$install_type) ne "GI";

  # Load available resources
  my @crsresources = dbglevel_load_resources($tfa_home);
  my $crsres = join(" ", @crsresources);

  return $crsres;
}

# NAME
#   dbglevel_list_similar_resources
#
# DESCRIPTION
#   This function returns a list of the similar resources given a pattern
#
# PARAMETERS
#   $resPattern     (IN) - Pattern of the resource
#   $avblResources  (IN) - List of resources available
#
# RETURNS
#   A list of similar resources available
#
########
sub dbglevel_list_similar_resources {
  my $resPattern = shift;
  my $avblResources = shift;
  my $matchedRes;

  my @array = split / /, $avblResources;

  $resPattern =~ s/^\s+//;
  $resPattern =~ s/\s+$//;  
  $resPattern =~ s/\(/\\\(/g;
  $resPattern =~ s/\)/\\\)/g;
  #print "Pattern: $resPattern\n";

  foreach my $str (@array) {
    if ( $str eq $resPattern ) {
      return 1;
    } elsif ( $str =~ $resPattern ) {
      if ( !$matchedRes ){
        $matchedRes = $str;
      } else {
        $matchedRes = $matchedRes . ' ' . $str;
      }
    }
  }

  return $matchedRes;
}

# NAME
#   dbglevel_process_match
#
# DESCRIPTION
#   This function returns a list of the similar resources given a pattern
#
# PARAMETERS
#   $tfa_home     (IN) - TFA Home
#   $resPattern     (IN) - Pattern of the resource
#   $resource       (IN) - Name of the resource
#
# RETURNS
#   A list of similar resources available
#
########
sub dbglevel_process_match {
  my $tfa_home = shift;
  my $resPattern = shift;
  my $resource = shift;
  my $avblResources = dbglevel_list_res($tfa_home);

  #print "PATTERN: $resPattern\nAVAILABLE: $avblResources\n";
  my $matchedRes = dbglevel_list_similar_resources($resPattern, $avblResources);
  if ( $matchedRes == 1 ){
      print "Resource $resource matched successfully...\n";
      return 1;
  } else {
      my @amatchedres = split(' ', $matchedRes);
      if ( $#amatchedres >= 0 ) {
        print "Resource $resource did not match...\nSimilar Resources available:\n";
        foreach my $str (@amatchedres) {
          print " $str\n";
        }
      } elsif ( $#amatchedres == -1 ) {
        print "No such resource $resource available...\n";
        return 1;
      }
  }

  return 0;
}

########
# NAME
#   dbglevel_get_description
#
# DESCRIPTION
#   This function returns the description of the given profile.
#
# PARAMETERS
#   $tfa_profile_xml (IN) - xml profile
#   $profilename     (IN) - name of the dbglvel profile
#
# RETURNS
#
########
sub dbglevel_get_description {
  my $tfa_profile_xml = shift;
  my $profilename = shift;
  my $profiledesc;

  if ( -e "$tfa_profile_xml" ) {
    $profiledesc = dbglevel_get_attribute($tfa_profile_xml,"description");
    print "PROFILE: $profilename\nDESCRIPTION: $profiledesc\n";
  } else {
    print "Profile $profilename doesn't exist...\n";
    return 1;
  }

  return;
}

########
# NAME
#   dbglevel_get_attribute
#
# DESCRIPTION
#   This function returns the given attribute.
#
# PARAMETERS
#   $tfa_profile_xml (IN) - xml profile
#   $reqattr         (IN) - required attribute (name/type)
#
# RETURNS
#   the attribute queried
########

sub dbglevel_get_attribute {
  my $tfa_profile_xml = shift;
  my $reqattr = shift;
  my $attrname;
  my $attrvalue;

  # Parse xml file
  my @profiletagsarray = tfactlshare_populate_tagsarray($tfa_profile_xml);

  # Parse profile
  my @profileList = tfactlshare_get_element(\@profiletagsarray, 0,0);

  foreach my $child (@profileList)
  {
      # Get the profile
    my $name = @$child[ELEMNAME];
    # Get attributes
    ($attrname , $attrvalue) = tfactlshare_get_attribute( @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL], lc($reqattr) );
  } # end foreach

  return $attrvalue;
}

########
# NAME
#   dbglevel_process_drop
#
# DESCRIPTION
#   This function drops the given profile.
#
# PARAMETERS
#   $tfa_home        (IN) - TFA Home
#   $tfa_profile_xml (IN) - xml profile
#   $profilename     (IN) - profile name
#
# RETURNS
#
########
sub dbglevel_process_drop {
  my $tfa_home = shift;
  my $tfa_profile_xml = shift;
  my $profilename = shift;
  my $profiletype;

  if ( -e "$tfa_profile_xml" ) {
    my $selection       = "";
    my $selectiondefval = "n";
    while ( not ( uc($selection) eq "Y" || uc($selection) eq "N" ) ) {
       print "\nAre you sure that you want to drop the profile $profilename [y,n, default n]?";
       $selection =<STDIN>;
       chomp($selection);
       if ( length($selection) == 0 ) {
         $selection = $selectiondefval;
       }
    } # end while
    if ( uc($selection) eq "N" ) {
      print "Profile $profilename was not be deleted !\n";
      return;
    } else {
      $profiletype = dbglevel_get_attribute($tfa_profile_xml, "type");

      if ( lc($profiletype) eq "default" ) {
        print "ERROR: Default profile $profilename could not be deleted !\n";
        return 1;
            } else {
        unlink $tfa_profile_xml;
        if ( $! =~ /No such file/ ) {
          print "Profile $profilename could not be deleted !\n";
          return 1;
        } else {
          print "Profile $profilename deleted successfully!\n";
          return 0;
        }
      }
    }
  } else {
   print "Profile $profilename does not exists in directory $tfa_home/ext/dbglevel/profiles.\n";
   return 1;
  } # end if exists $tfa_profile_xml

  return;
}

########
# NAME
#   dbglevel_profile_to_usermodules
#
# DESCRIPTION
#   This function converts the profile read
#   to usermodules format
#
# PARAMETERS
#   $usermodulesref
#   $userresourcesref
#   $userdaemonsref
#   $tfa_home
#   $tfa_profile_xml
#
# RETURNS
#
########
sub dbglevel_profile_to_usermodules {
  my $usermodulesref   = shift;
  my $userresourcesref = shift;
  my $userdaemonsref   = shift;
  my $tfa_home         = shift;
  my $tfa_profile_xml  = shift;
  my $profilename      = shift;

  my $modkey;
  my $ptraceflag = FALSE;
  my $punsetflag = FALSE;

  my %usermodules   = %$usermodulesref;
  my %userresources = %$userresourcesref;
  my %userdaemons   = %$userdaemonsref;

  my %changes;

  %changes = dbglevel_read_profile($tfa_home, $tfa_profile_xml);

      my $arrayref = $changes{$profilename};
      my @tmparray = @$arrayref;
      my $loglevel;
      my $tracelevel;
      my $commandoutput;
      my $pcommand;
      my $pcommandlocation;
      my $pcommandtype;
      my $pdaemon;
      my $pmodule;
      my $psetvalue;
      my $punsetvalue;

      # Read entries for profile
      for my $ndx ( 0 .. $#tmparray ) {
         $pcommand =         $tmparray[$ndx][0];
         $pcommandlocation = $tmparray[$ndx][1];
         $pcommandtype     = $tmparray[$ndx][2];
         $pdaemon          = $tmparray[$ndx][3];
         $pmodule          = $tmparray[$ndx][4];
         $psetvalue        = $tmparray[$ndx][5];
         $punsetvalue      = $tmparray[$ndx][6];

         ###
         ####print "Entries $pcommandtype $pdaemon $pmodule $psetvalue $punsetvalue\n";
         if ( lc($pcommandtype) eq "resource" ) {
           $modkey = "RESOURCE." . $pmodule;
           $userresources{$pmodule} = TRUE;
           $usermodules{$modkey} = [ $psetvalue, $punsetvalue, 0, 0 ];
         } elsif ( lc($pcommandtype) eq "log" ) {
           $modkey = $pdaemon . "." . $pmodule;
           $userdaemons{$pdaemon} = 1;
           if ( exists $usermodules{$modkey} ) {
             # Retrieve previous trace values
             my $ref = $usermodules{$modkey};
             my @array = @$ref; # Log levels
             $usermodules{$modkey} = [ $psetvalue, $punsetvalue, $array[2],
                                $array[3] ];
           } else {
             # No previous value for trace
             $usermodules{$modkey} = [ $psetvalue, $punsetvalue, -1, -1 ];
           }
           # Set punsetflag
           if ( $punsetvalue != -1 ) {
               $punsetflag = TRUE;
             }

         } elsif ( lc($pcommandtype) eq "trace" ) {
           $modkey = $pdaemon . "." . $pmodule;
           $userdaemons{$pdaemon} = 1;
           # Set flags
           if ( $psetvalue != -1 ) {
             $ptraceflag = TRUE;
             if ( $punsetvalue != -1 ) {
               $punsetflag = TRUE;
             }
           }
           if ( exists $usermodules{$modkey} ) {
             # Retrieve previous log values
             my $ref = $usermodules{$modkey};
             my @array = @$ref; # Log levels
             $usermodules{$modkey} = [ $array[0], $array[1],
                                       $psetvalue, $punsetvalue ];
           } else {
             # No previous value for trace
             $usermodules{$modkey} = [ 0, 0, $psetvalue, $punsetvalue ];
           }
         } # end if pcommandtype eq "trace"
      } # end for $#tmparray

  #my $count = keys %usermodules;
  ###
  ###print "Done w/entries $usermodules{'crf.CLSINET'} , count $count\n";
  ###print "ptraceflag $ptraceflag punsetflag $punsetflag \n";
  return (\%usermodules, \%userresources, \%userdaemons, \$ptraceflag,
          \$punsetflag);
}


########
# NAME
#   dbglevel_profile_to_usermodules_noncrs
#
# DESCRIPTION
#   This function converts the profile read
#   to usermodules format
#
# PARAMETERS
#   $usermodulesref - Hash reference to store the information of a profile
#   $tfa_home - TFA home
#   $tfa_profile_xml - Dbglevel xml profile
#   $profilename - Name of the profile
#
# RETURNS
#
########
sub dbglevel_profile_to_usermodules_noncrs {
  my $usermodulesref   = shift;
  my $tfa_home         = shift;
  my $tfa_profile_xml  = shift;
  my $profilename      = shift;

  my $modkey;

  my %usermodules   = %$usermodulesref;

  my %changes;

  %changes = dbglevel_read_profile($tfa_home, $tfa_profile_xml);

      my $arrayref = $changes{$profilename};
      my @tmparray = @$arrayref;
      my $pcommand;
      my $pcommandlocation;
      my $pcommandtype;
      my $pdaemon;
      my $pmodule;
      my $psetvalue;
      my $punsetvalue;

      # Read entries for profile
      for my $ndx ( 0 .. $#tmparray ) {
          $pcommand =         $tmparray[$ndx][0];
          $pcommandlocation = $tmparray[$ndx][1];
          $pcommandtype     = $tmparray[$ndx][2];
          $pdaemon          = $tmparray[$ndx][3];
          $pmodule          = $tmparray[$ndx][4];
          $psetvalue        = $tmparray[$ndx][5];
          $punsetvalue      = $tmparray[$ndx][6];

               ###
          $modkey =  $pdaemon . "|" . $pmodule;
          $usermodules{$modkey} = [ $pcommand, $pcommandlocation, $pcommandtype, $psetvalue, $punsetvalue, -1, -1 ];

      } # end for $#tmparray

  return (\%usermodules);
}

########
# NAME
#   dbglevel_process_create_handle
#
# DESCRIPTION
#   This function handles the creation of crs/non-crs profile
#
# PARAMETERS
#   $optype          (IN) - Operation type: create or modify
#   $tfa_home        (IN) - TFA Home
#   $tfa_profile_xml (IN) - xml profile
#   $profilename     (IN) - profile name
#   $ptraceflag      (IN) - TRUE - Include trace, FALSE - Don't include trace
#   $punsetflag      (IN) - TRUE - unset selected, FALSE - unset not selected
#   $profiletimeout  (IN) - timeout for that profile
#
# RETURNS
#
########
sub dbglevel_process_create_handle {
  my $optype          = shift;
  my $tfa_home        = shift;
  my $tfa_profile_xml = shift;
  my $profilename     = shift;
  my $profiledesc     = shift;
  my $ptraceflag      = shift;
  my $punsetflag      = shift;
  my $profiletimeout  = shift;

  print "\nEnter the type of profile:\n";
  print "Allowed: CRS/OCLUMON\n";

  my $command = <STDIN>;
  chomp($command);
  if ( lc($command) eq "crs" ) {
     dbglevel_process_create($optype,"crsctl",$tfa_home,$tfa_profile_xml,$profilename,$profiledesc,$ptraceflag,
                            $punsetflag,$profiletimeout);
  } else {
    if ( lc($command) ne "oclumon" ) {
      print "$command is not a valid valued.\n";
      print "Allowed values: CRS/OCLUMON.\n";
      return 1;
    }


    if ($ptraceflag) {
      print "\nWARNING: Trace as command-type is not available for $command.\n\n";
    }

    dbglevel_process_create_noncrs($optype,$command,$tfa_home,$tfa_profile_xml,$profilename,$profiledesc,$ptraceflag,
                            $punsetflag,$profiletimeout);
  }
}

########
# NAME
#   dbglevel_process_create_noncrs
#
# DESCRIPTION
#   This function creates a persistent profile
#
# PARAMETERS
#   $optype          (IN) - Operation type: create or modify
#   $is_crs        (IN) - type of profile(CRS/OCLUMON etc)
#   $tfa_home        (IN) - TFA Home
#   $tfa_profile_xml (IN) - xml profile
#   $profilename     (IN) - profile name
#   $profiledesc     (IN) - profile description
#   $ptraceflag      (IN) - TRUE - Include trace, FALSE - Don't include trace
#   $punsetflag      (IN) - TRUE - unset selected, FALSE - unset not selected
#   $profiletimeout  (IN) - timeout for that profile
#
# RETURNS
#
########
sub dbglevel_process_create_noncrs {
  my $optype          = shift;
  my $is_crs          = shift;
  my $tfa_home        = shift;
  my $tfa_profile_xml = shift;
  my $profilename     = shift;
  my $profiledesc     = shift;
  my $ptraceflag      = shift;
  my $punsetflag      = shift;
  my $profiletimeout  = shift;
  my $pmodifyflag     = FALSE;

  my $command;
  my $pcommandlocation;
  my $pcommandtype;
  my $pdaemon;
  my $pmodule;
  my $psetvalue;
  my $punsetvalue;
  my $selectionval;
  my (%changes) = ();
  my (%daemonshash) = ();
  my (@modulesarray) = ();
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");
  my $crs_home;

  my $logsetvalue;
  my $logunsetvalue;

  # Select daemons/modules by user
  my $ndx;
  my @optionsarray;
  my $totndx;
  my $optselected;
  my $daemonselected;
  my $moduleselected;
  my $daemondone = FALSE;
  my $optmaxval;
  my $loglevel;
  my $tracelevel;
  my $logsetvalue;
  my $logunsetvalue;
  my $tracesetvalue;
  my $traceunsetvalue;
  my $currlogvalue;
  my $currtracevalue;
  my $deflogset;
  my $deflogunset;
  my $modkey;

  my (%usermodules) = ();

  tfactlshare_trace(5, "tfactl (PID = $$) dbglevel_process_create_noncrs " .
                    "punsetflag value $punsetflag", 'y', 'y');

  return 1 if dbglevel_validate_gi($tfa_home,$install_type) ne "GI";

  if ( -e "$tfa_profile_xml" ) {
    my $profiletype;

    $profiletype = dbglevel_get_attribute($tfa_profile_xml, "type");

    if ( lc($optype) eq "create" ) {
      print "Profile $profilename  already exists in directory $tfa_home/ext/dbglevel/profiles.\n";
      my $selection       = "";
      my $selectiondefval = "n";
      while ( not ( uc($selection) eq "Y" || uc($selection) eq "N" ) ) {
         print "\nDo you want to replace this profile [y,n, default n]?";
         $selection =<STDIN>;
         chomp($selection);
         if ( length($selection) == 0 ) {
           $selection = $selectiondefval;
         }
      } # end while
      if ( uc($selection) eq "N" ) {
        return;
      }
      elsif ( uc($selection) eq "Y" && lc($profiletype) eq "default" ) {
        print "ERROR: Default profile $profilename can not be overwritten !\n";
        return 1;
      }
    } elsif ( lc($optype) eq "modify" ) { # else $optype = "create"
      ### Modify
      my $usermodulesref;

      if ( lc($profiletype) eq "default" ) {
        print "ERROR: Default profile $profilename can not be modified !\n";
        return 1;
      } else {
        $pmodifyflag = TRUE;

        # profile to usermodules
        $usermodulesref = dbglevel_profile_to_usermodules_noncrs(\%usermodules, $tfa_home, $tfa_profile_xml, $profilename );
        %usermodules    = %$usermodulesref;

        #foreach my $x (keys %usermodules) { print "$x\n"; }
      }
    } # end if $optype = "create"

  } else { # else   exists $tfa_profile_xml
    if ( lc($optype) eq "modify" ) {
      print "Profile $profilename does not exists in directory $tfa_home/ext/dbglevel/profiles.\n";
      return 1;
    }
  } # end if exists $tfa_profile_xml

  # ----------------------------------------
  # Iterate through modules
  my $moduledone =FALSE;

  while ( ! $moduledone ) {
    undef @optionsarray;
    $ndx = 0;

    # Desired module for the given daemon
    my $itemscounter = 0;
    my $formattedstring = "";

    print "\n\nFollowing components added to the profile.\n";
    print "To modify a component select the component.\n\n";

    for my $modndx ( sort keys %usermodules ) {
      my @tmp1 = split /\|/, $modndx;
      my $text = join " => ", @tmp1;
      print "$ndx) $text\n";
      $optionsarray[$ndx++] = $modndx;
    } # end foreach keys %daemonshash

    print "$ndx) Add a Component\n";
    $ndx++;
    print "$ndx) Done \n";
    $totndx = $#optionsarray;
    $optmaxval = $totndx + 2;
    $optselected = -1;

    # Desired module
    $optselected = tfactlshare_get_choice ( 0, $optmaxval,
      "\nPlease select a CRS component for the profile" .
      " [0-$optmaxval, default $optmaxval] ?", $optmaxval );
    if ( $optselected == ($totndx + 2) ) {
      $moduledone = TRUE;
    } elsif ( $optselected == ($totndx + 1) ) {   ##ADD A NEW COMPONENT
      $deflogset     = 2;
      $deflogunset   = -1;

      print "Enter the command to be used:\n";
      $command = <STDIN>;
      chomp($command);
      print "Enter the command location:[GI_HOME]\n";
      $pcommandlocation = <STDIN>;
      chomp($pcommandlocation);
      print "Enter the command type:\n";
      $pcommandtype = <STDIN>;
      chomp($pcommandtype);
      print "Enter the daemon to be used:\n";
      $pdaemon = <STDIN>;
      chomp($pdaemon);
      $pdaemon = uc($pdaemon);
      print "Enter the module to be used:\n";
      $pmodule = <STDIN>;
      chomp($pmodule);
      $pmodule = uc($pmodule);
      print "Enter the set value:\n";
      $psetvalue = <STDIN>;
      chomp($psetvalue);
      print "Enter the unset value:\n";
      $punsetvalue = <STDIN>;
      chomp($punsetvalue);

      $modkey =  $pdaemon . "|" . $pmodule;
      if ($usermodules{$modkey}) {
        print "Component $pmodule already present. Select another component or modify the profile. . .\n";
      } else {
        $usermodules{$modkey} = [ $command, $pcommandlocation, $pcommandtype, $psetvalue, $punsetvalue, -1, -1 ];
      }

    } elsif ($pmodifyflag) {
      $deflogset     = 2;
      $deflogunset   = -1;

      $modkey = $optionsarray[$optselected];
      print "$optionsarray[$optselected] was selected.\n";
      # Unselect previous option
      $selectionval = "";
      if ( exists $usermodules{$modkey} ) {
        $selectionval = tfactlshare_get_choice_yn("y","n",
              "Do you want to unselect this entry [y,n, default n]?", "n" );
        my $ref = $usermodules{$modkey};
        my @array = @$ref;
        $deflogset     = $array[3];
        $deflogunset   = $array[4];
      }

      if ( $selectionval eq "y" ) {
        delete $usermodules{$modkey};
      } else {
        $logsetvalue = tfactlshare_get_choice ( 0, 5,
                "Log set value [current $currlogvalue, 0-5, default $deflogset] ?",
                $deflogset );
        ###
        # Unset emabled ?
        # log
        ###
        if ( $punsetflag ) {
          $logunsetvalue = tfactlshare_get_choice ( 0, 5,
            "Log Unset value [0-5, default $deflogunset] ?",
            $deflogunset );
        } else {
          $logunsetvalue = $deflogunset;
        } # end if, unset enabled ?

        my $ref = $usermodules{$modkey};
        my @comp_details = @$ref;
        $usermodules{$modkey} = [ $comp_details[0], $comp_details[1], $comp_details[2], $logsetvalue, $logunsetvalue, -1,
                -1 ];
      } # end if unselect

      print "-----------------------------------------------------------\n";
      print "Current components selected for profile $profilename:\n";
      foreach my $userkeys ( sort keys %usermodules ) {
        print "$userkeys\n";
        my $ref = $usermodules{$userkeys};
        my @array = @$ref;
        tfactlshare_trace(5, "tfactl (PID = $$) dbglevel_process_create_noncrs " .
            "Log/trace levels  @array", 'y', 'y');
      } # end foreach
      print "-----------------------------------------------------------\n";
      #$pause =<STDIN>;
    }
  } # end while ! $moduledone

  dbglevel_generate_profile_noncrs(\%usermodules,$tfa_home,$tfa_profile_xml,
                            $profilename,"user",$profiledesc,$profiletimeout);

  return;
}

########
# NAME
#   dbglevel_process_create
#
# DESCRIPTION
#   This function creates a persistent profile
#
# PARAMETERS
#   $optype          (IN) - Operation type
#                         - create or modify
#   $command       (IN) - type of profile(CRS/OCLUMON etc)
#   $tfa_home        (IN) - TFA Home
#   $tfa_profile_xml (IN) - xml profile
#   $profilename     (IN) - profile name
#   $ptraceflag      (IN) - TRUE - Include trace, FALSE - Don't include trace
#   $punsetflag      (IN) - TRUE - unset selected, FALSE - unset not selected
#   $profiletimeout  (IN) - timeout for that profile
#
# RETURNS
#
########
sub dbglevel_process_create {
  my $optype          = shift;
  my $pcommand        = shift;
  my $tfa_home        = shift;
  my $tfa_profile_xml = shift;
  my $profilename     = shift;
  my $profiledesc     = shift;
  my $ptraceflag      = shift;
  my $punsetflag      = shift;
  my $profiletimeout  = shift;
  my $pmodifyflag     = FALSE;

  my $pcommandlocation;
  my $pcommandtype;
  my $pdaemon;
  my $pmodule;
  my $psetvalue;
  my $punsetvalue;
  my (%changes) = ();
  my (%daemonshash) = ();
  my (@modulesarray) = ();
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");
  my $crs_home;
  my @args;
  my $count;
  my $pause;
  my $selectionval;

  # Select daemons/modules by user
  my $ndx;
  my @optionsarray;
  my $totndx;
  my $optselected;
  my $daemonselected;
  my $moduleselected;
  my $daemondone = FALSE;
  my $optmaxval;
  my $loglevel;
  my $tracelevel;
  my $logsetvalue;
  my $logunsetvalue;
  my $tracesetvalue;
  my $traceunsetvalue;
  my $currlogvalue;
  my $currtracevalue;
  my $deflogset;
  my $deflogunset;
  my $deftraceset;
  my $deftraceunset;
  my $modkey;

  my (%userdaemons) = ();
  my (%usermodules) = ();
  my (%userresources) = ();

  tfactlshare_trace(5, "tfactl (PID = $$) dbglevel_process_create " .
                    "ptraceflag value $ptraceflag", 'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) dbglevel_process_create " .
                    "punsetflag value $punsetflag", 'y', 'y');


  return 1 if dbglevel_validate_gi($tfa_home,$install_type) ne "GI";

  if ( -e "$tfa_profile_xml" ) {
    my $profiletype;

    $profiletype = dbglevel_get_attribute($tfa_profile_xml, "type");

    if ( lc($optype) eq "create" ) {
      print "Profile $profilename  already exists in directory $tfa_home/ext/dbglevel/profiles.\n";
      my $selection       = "";
      my $selectiondefval = "n";
      while ( not ( uc($selection) eq "Y" || uc($selection) eq "N" ) ) {
         print "\nDo you want to replace this profile [y,n, default n]?";
         $selection =<STDIN>;
         chomp($selection);
         if ( length($selection) == 0 ) {
           $selection = $selectiondefval;
         }
      } # end while
      if ( uc($selection) eq "N" ) {
        return;
      }
      elsif ( uc($selection) eq "Y" && lc($profiletype) eq "default" ) {
        print "ERROR: Default profile $profilename can not be overwritten !\n";
        return 1;
      }
    } elsif ( lc($optype) eq "modify" ) { # else $optype = "create"
      ### Modify
      my $usermodulesref;
      my $userresourcesref;
      my $userdaemonsref;
      my $ptraceflagref;
      my $punsetflagref;

      if ( lc($profiletype) eq "default" ) {
        print "ERROR: Default profile $profilename can not be modified !\n";
        return 1;
      } else {
        $pmodifyflag = TRUE;

        # profile to usermodules
        ( $usermodulesref, $userresourcesref, $userdaemonsref, $ptraceflagref,
          $punsetflagref ) =
        dbglevel_profile_to_usermodules(\%usermodules, \%userresources, \%userdaemons,
                $tfa_home, $tfa_profile_xml, $profilename );
        %usermodules    = %$usermodulesref;
        %userresources  = %$userresourcesref;
        %userdaemons    = %$userdaemonsref;
        $ptraceflag     = $$ptraceflagref | $ptraceflag;
        $punsetflag     = $$punsetflagref | $punsetflag;

        tfactlshare_trace(5, "tfactl (PID = $$) dbglevel_process_create " .
              "ptraceflag value after to_usermodules $ptraceflag", 'y', 'y');
        tfactlshare_trace(5, "tfactl (PID = $$) dbglevel_process_create " .
              "punsetflag value after to_usermodules $punsetflag", 'y', 'y');
      }
    } # end if $optype = "create"

  } else { # else   exists $tfa_profile_xml
    if ( lc($optype) eq "modify" ) {
      print "Profile $profilename does not exists in directory $tfa_home/ext/dbglevel/profiles.\n";
      return 1;
    }
  } # end if exists $tfa_profile_xml

  # Load available daemons
  %daemonshash = dbglevel_load_crs_modules($tfa_home);

  # ------------------------------------------
  # Iterate through the daemons

  while ( ! $daemondone ) {
  $ndx = 0;
  $totndx = 0;
  undef @optionsarray;

  print "\n\nCRS modules available for selection,\n";
  print "Selected entries are marked with an asterisk (*).\n\n";

  foreach my $daemonskey ( sort keys %daemonshash ) {
    if ( ! exists $userdaemons{$daemonskey} ) {
      print "$ndx) $daemonskey $daemonshash{$daemonskey} \n";
    } else {
      print "$ndx) *$daemonskey $daemonshash{$daemonskey} \n";
    }  # end if exists key in userhash
      $optionsarray[$ndx++] = $daemonskey;
  } # end foreach keys %daemonshash
  print "$ndx) Done \n";
  $totndx = $#optionsarray;
  $optmaxval = $totndx + 1;
  $optselected = -1;

  # Desired daemon
  while ( not ( int($optselected) - $optselected == 0 &&
          $optselected >= 0 && $optselected <= ($totndx+1) ) ) {
     $optselected = 0;

     $optselected = tfactlshare_get_choice ( 0, $optmaxval,
                 "\nPlease select a CRS module for the profile" .
                 " [$optselected-$optmaxval, default $optmaxval] ?", $optmaxval );
  } # end while $optselected
  $daemonselected = $optionsarray[$optselected];

  if ( $optselected == ($totndx + 1) ) {
    $daemondone = TRUE;
    last;
  } else {
    print "$daemonselected module was selected.\n";
    #$pause =<STDIN>;
  }

  # ----------------------------------------
  # Iterate through modules
  my $moduledone =FALSE;
  undef @modulesarray;
  @modulesarray = dbglevel_load_crs_components($daemonselected);

  while ( ! $moduledone ) {
  undef @optionsarray;
  $ndx = 0;

  # Desired module for the given daemon
  my $itemscounter = 0;
  my $formattedstring = "";

  print "\n\n$daemonselected components available for selection,\n";
  print "Selected entries are marked with an asterisk (*).\n\n";

  for my $modndx ( 0..$#modulesarray ) {
    $modkey = $daemonselected.".".$modulesarray[$modndx];
    ###if ( ! exists $usermodules{$modkey} ) {
      if ( exists $usermodules{$modkey} ) {
        $formattedstring .= sprintf("%-15s ","$ndx) *$modulesarray[$modndx]");
      } else {
        $formattedstring .= sprintf("%-15s ","$ndx) $modulesarray[$modndx]");
      }
      #print "$ndx) $modulesarray[$modndx] ";
      if ( ++$itemscounter % 4 == 0 || $modndx == $#modulesarray ) {
        print "$formattedstring\n";
        $formattedstring = "";
      }
      $optionsarray[$ndx++] = $modulesarray[$modndx];
    ###} # end if exists key in userhash
  } # end foreach keys %daemonshash
  print "$ndx) Done \n";
  $totndx = $#optionsarray;
  $optmaxval = $totndx + 1;
  $optselected = -1;

  # Desired module
  $optselected = tfactlshare_get_choice ( 0, $optmaxval,
                 "\nPlease select a CRS component for the profile" .
                 " [0-$optmaxval, default $optmaxval] ?", $optmaxval );
  if ( $optselected == ($totndx + 1) ) {
    $moduledone = TRUE;
  } else {
    $modkey = $daemonselected.".".$optionsarray[$optselected];
    print "$optionsarray[$optselected] was selected.\n";
    # Unselect previous option
    $selectionval = "";
    if ( exists $usermodules{$modkey} ) {
      $selectionval = tfactlshare_get_choice_yn("y","n",
            "Do you want to unselect this entry [y,n, default n]?", "n" );
      my $ref = $usermodules{$modkey};
      my @array = @$ref;
      $deflogset     = $array[0];
      $deflogunset   = $array[1];
      $deftraceset   = $array[2];
      $deftraceunset = $array[3];
    } else {
      $deflogset     = 2;
      $deflogunset   = -1;
      $deftraceset   = -1;
      $deftraceunset = -1;
    }

    if ( $selectionval eq "y" ) {
      delete $usermodules{$modkey};
      # check if userdaemons is still needed
      my $daemonfound = FALSE;
      foreach my $chkkey ( keys %usermodules ) {
        if ( $chkkey =~ /$daemonselected\.(.*)/ ) {
          $daemonfound = TRUE;
        } # end if
      } # end foreach
      if ( not $daemonfound ) {
        delete $userdaemons{$daemonselected};
      } # end if not $daemonfound
    } else {
      # Get current values for log and trace
      $currlogvalue  = dbglevel_get_current_levels( "log",
                       $daemonselected, $optionsarray[$optselected] );
      #  $deflogunset
      if ( $deflogunset == -1 && $punsetflag ) {
        $deflogunset = $currlogvalue;
      }
      ###print "dbg $deflogunset  $punsetflag \n\n";

      $currtracevalue = dbglevel_get_current_levels( "trace",
                        $daemonselected, $optionsarray[$optselected] );
      # $deftraceunset
      if ( $deftraceunset == -1 && $ptraceflag && $punsetflag ) {
        $deftraceunset = $currtracevalue;
      }
      # $deftraceset
      if ( $deftraceset == -1 && $ptraceflag ) {
        $deftraceset = $currtracevalue;
      }

      $logsetvalue = tfactlshare_get_choice ( 0, 5,
                     "Log set value [current $currlogvalue, 0-5, default $deflogset] ?",
                     $deflogset );
      ###
      # Unset emabled ?
      # log
      ###
      if ( $punsetflag ) {
        $logunsetvalue = tfactlshare_get_choice ( 0, 5,
                       "Log Unset value [0-5, default $deflogunset] ?",
                       $deflogunset );
      } else {
        if ( $pmodifyflag ) {
          $logunsetvalue = $deflogunset;
        } else {
          $logunsetvalue = -1;
        } # end if $pmodifyflag
      } # end if, unset enabled ?

      ###
      # Process trace data ?
      ###
      if ( $ptraceflag ) {
        $tracesetvalue = tfactlshare_get_choice ( 0, 5,
                      "Trace set value [current $currtracevalue, 0-5, default $deftraceset] ?",
                       $deftraceset );
        ###
        # Unset emabled ?
        # trace
        ###
        if ( $punsetflag ) {
          $traceunsetvalue = tfactlshare_get_choice ( 0, 5,
                         "Trace Unset value [0-5, default $deftraceunset] ?",
                         $deftraceunset );
        } else {
          if ( $pmodifyflag ) {
            $traceunsetvalue = $deftraceunset;
          } else {
            $traceunsetvalue = -1;
          } # end if $pmodifyflag
        } # end if Unset enabled ?
      } else {
         if ( $pmodifyflag ) {
           $tracesetvalue   = $deftraceset;
           $traceunsetvalue = $deftraceunset;
         } else {
           $tracesetvalue   = -1;
           $traceunsetvalue = -1;
         } # end if $pmodifyflag
      } # end if, trace date
      #$modkey = $daemonselected.".".$optionsarray[$optselected];
      $usermodules{$modkey} = [ $logsetvalue, $logunsetvalue, $tracesetvalue,
                                $traceunsetvalue ];
      ###print "logsetvalue $logsetvalue logunsetvalue $logunsetvalue " .
      ###      "tracesetvalue $tracesetvalue traceunsetvalue $traceunsetvalue\n";
      $userdaemons{$daemonselected} = 1;
    } # end if unselect

    print "-----------------------------------------------------------\n";
    print "Current components selected for module $daemonselected:\n";
    foreach my $userkeys ( sort keys %usermodules ) {
      if ( $userkeys =~ /$daemonselected\.(.*)/ ) {
        print "$1\n";
        my $ref = $usermodules{$userkeys};
        my @array = @$ref;
        tfactlshare_trace(5, "tfactl (PID = $$) dbglevel_process_create " .
                         "Log/trace levels  @array", 'y', 'y');
      }
    } # end foreach
    print "-----------------------------------------------------------\n";
    #$pause =<STDIN>;
  }
  } # end while ! $moduledone
  } # end while ! daemondone

  # -------------------------------------------------
  # Load available resources if any

  my $formattedstring = "";
  my $itemscounter = 0;
  my @resources;
  my $resourcedone = FALSE;
#  my (%userresources) = ();

  @resources = dbglevel_load_resources($tfa_home);

  # If no resources were discovered then
  # populate from profile
  if ( not @resources ) {
    foreach my $userkeys ( sort keys %usermodules ) {
       if ( $userkeys =~ /RESOURCE\.(.*)/ ) {
         push @resources, $1;
        }
     } # end foreach
  } # end if, $#resources == 0

  # ---------  Iterate throuh resources -----------
  while ( not $resourcedone ) {
  $ndx = 0;
  $totndx = 0;
  undef @optionsarray;

  print "\nAvailable resources for selection,\n";
  print "Selected entries are marked with an asterisk (*).\n\n";

  $itemscounter = 0;
  for my $modndx ( 0..$#resources ) {
     ###if ( ! exists $userresources{$resources[$modndx]} ) {
       if ( exists $userresources{$resources[$modndx]} ) {
         $formattedstring .= sprintf("%-35s ","$ndx) *$resources[$modndx]");
       } else {
         $formattedstring .= sprintf("%-35s ","$ndx) $resources[$modndx]");
       }
       if ( ++$itemscounter % 2 == 0 || $modndx == $#resources ) {
         print "$formattedstring\n";
         $formattedstring = "";
       }
       $optionsarray[$ndx++] = $resources[$modndx];
     ###} # end if exists $userresources
  } # end for @resources

  print "$ndx) Done \n";
  $totndx = $#optionsarray;
  $optmaxval = $totndx + 1;
  $optselected = -1;

  # Desired resource
  $optselected = tfactlshare_get_choice ( 0, $optmaxval,
                 "\nPls select a CRS resource the profile" .
                 " [0-$optmaxval, default $optmaxval] ?", $optmaxval );

  if ( $optselected == ($totndx + 1) ) {
    $resourcedone = TRUE;
  } else {
    print "Resource $optionsarray[$optselected] was selected.\n";
    $modkey = "RESOURCE." . $optionsarray[$optselected];

    # Unselect previous option
    $selectionval = "";
    if ( exists $usermodules{$modkey} ) {
      $selectionval = tfactlshare_get_choice_yn("y","n",
            "Do you want to unselect this entry [y,n, default n]?", "n" );
      my $ref = $usermodules{$modkey};
      my @array = @$ref;
      $deflogset     = $array[0];
      $deflogunset   = $array[1];
    } else {
      $deflogset     = 2;
      $deflogunset   = 2;
    }

    if ( $selectionval eq "y" ) {
      delete $usermodules{$modkey};
      delete $userresources{$optionsarray[$optselected]};
    } else {
      # Retrieve current log value for the resource
      $currlogvalue = dbglevel_get_current_levels( "resource",
                      "RESOURCE", $optionsarray[$optselected] );
      if ( $deflogunset == -1 ) {
        $deflogunset = $currlogvalue;
      }

       $logsetvalue = tfactlshare_get_choice ( 0, 5,
                      "Log set value [current $currlogvalue, 0-5, default $deflogset] ?", $deflogset);
       ###
       # Unset enabled ?
       # resource
       ###
       if ( $punsetflag ) {
         $logunsetvalue = tfactlshare_get_choice ( 0, 5,
                        "Log Unset value [0-5, default $deflogunset] ?", $deflogunset);
       } else {
         if ( $pmodifyflag ) {
           $logunsetvalue = $deflogunset;
         } else {
           $logunsetvalue = -1;
         } # end if $pmodifyflag
       }

       # Mark user selection
       $userresources{$optionsarray[$optselected]} = TRUE;
       #$modkey = "RESOURCE." . $optionsarray[$optselected];
       $usermodules{$modkey} = [ $logsetvalue, $logunsetvalue, 0, 0 ];
    } # end if unselect
  } # end if $optselected == ($totndx + 1) -> resource done
  } # end while not $resourcedone
  # --------------- end Iterate through resources --------------------


  $count = keys %userresources;
  if ( $count ) {
  print "-----------------------------------------------------------\n";
  print "Current resources selected for profile $profilename:\n";
  foreach my $userkeys ( sort keys %usermodules ) {
    if ( $userkeys =~ /RESOURCE\.(.*)/ ) {
       print "$1\n";
       my $ref = $usermodules{$userkeys};
       my @array = @$ref;
       tfactlshare_trace(5, "tfactl (PID = $$) dbglevel_process_create " .
                        "Log/trace levels for resource @array", 'y', 'y');
     }
  } # end foreach
  print "-----------------------------------------------------------\n";
  #$pause =<STDIN>;
  } # end if $count

  tfactlshare_trace(5, "tfactl (PID = $$) dbglevel_process_create " .
                    "Resources @optionsarray", 'y', 'y');

  dbglevel_generate_profile(\%usermodules,$tfa_home,$tfa_profile_xml,
                            $profilename,"user",$profiledesc,$profiletimeout);

  if ( lc($optype) eq "modify" ) {
    my $count = keys %usermodules;
    print "\nProfile $profilename was successfully modified.\n" if $count;
  } else {
    $count = keys %usermodules;
    if ( $count ) {
      print "\nProfile $profilename was successfully created.\n";
    } else {
      print "\nProfile $profilename was not created.\n";
    }
  }

  return;
}

########
# NAME
#   dbglevel_generate_profile_noncrs
#
# DESCRIPTION
#   This function generates the profile
#
# PARAMETERS
#   $hashref         (IN) - Hash
#   $tfa_home        (IN) - TFA Home
#   $tfa_profile_xml (IN) - xml profile
#   $profilename     (IN) - profile name
#   $profiletype     (IN) - default, user, debugstate
#   $profiledesc     (IN) - profile description
#   $profiletimeout  (IN) - profile timeout
#
# RETURNS
#
########
sub dbglevel_generate_profile_noncrs {
  my $hashref         = shift;
  my $tfa_home        = shift;
  my $tfa_profile_xml = shift;
  my $profilename     = shift;
  my $profiletype     = shift;
  my $profiledesc     = shift;
  my $profiletimeout  = shift;
  my %usermodules = %$hashref;

  my $count = 0;

  # Generate profile
  $count = keys %usermodules;

  if ( $count ) {
  open (my $ph, '>', $tfa_profile_xml) or die
       "Could not open $tfa_profile_xml\n";

  print $ph "<profile name=\"" . $profilename . "\" description=\"" . $profiledesc . "\" type=\"" .
            $profiletype . "\" timeout=\"" . $profiletimeout . "\">\n";
  foreach my $userkeys ( sort keys %usermodules ) {
      # Levels
      my $ref = $usermodules{$userkeys};
      my @levels = @$ref;

      my @tmp = split /\|/, $userkeys;
      my $command = $levels[0];
      my $commandlocation = $levels[1];
      my $commandtype = $levels[2];
      my $daemon = $tmp[0];
      my $module = $tmp[1];
      my $setvalue = $levels[3];
      my $unsetvalue = $levels[4];

      # Write log record
      print $ph "<change>\n";
      print $ph "<command>$command</command>\n";
      print $ph "<command_location>$commandlocation</command_location>\n";
      print $ph "<command_type>$commandtype</command_type>\n";
      print $ph "<daemon>$daemon</daemon>\n";
      print $ph "<module>$module</module>\n";
      print $ph "<set>$setvalue</set>\n";
      print $ph "<unset>$unsetvalue</unset>\n";
      print $ph "</change>\n";
  } # end foreach
  print $ph "</profile>\n";
  close $ph;

  } else {
    # Profile is empty
    unlink $tfa_profile_xml;
    if ( $! !~ /No such file/ ) {
      print "No entries in profile $profilename,  deleted successfully!\n";
    }
  } # end if $count

  return;

}

########
# NAME
#   dbglevel_generate_profile
#
# DESCRIPTION
#   This function generates the profile
#
# PARAMETERS
#   $hashref     (IN) - Hash
#   $tfa_home        (IN) - TFA Home
#   $tfa_profile_xml (IN) - xml profile
#   $profilename     (IN) - profile name
#   $profiletype     (IN) - default, user, debugstate
#   $profiledesc     (IN) - profile description
#   $profiletimeout  (IN) - profile timeout
#
# RETURNS
#
########
sub dbglevel_generate_profile {
  my $hashref         = shift;
  my $tfa_home        = shift;
  my $tfa_profile_xml = shift;
  my $profilename     = shift;
  my $profiletype     = shift;
  my $profiledesc     = shift;
  my $profiletimeout  = shift;
  my %usermodules = %$hashref;

  my $count = 0;

  # Generate profile
  $count = keys %usermodules;

  if ( $count ) {
  open (my $ph, '>', $tfa_profile_xml) or die
       "Could not open $tfa_profile_xml\n";
  my $isresource = FALSE;

  print $ph "<profile name=\"" . $profilename . "\" description=\"" . $profiledesc . "\" type=\"" .
            $profiletype . "\" timeout=\"" . $profiletimeout . "\">\n";
  foreach my $userkeys ( sort keys %usermodules ) {
      # Levels
      my $ref = $usermodules{$userkeys};
      my @levels = @$ref;

      # daemon & module
      my $outdaemon;
      my $outmodule;
      if ( $userkeys =~ /RESOURCE\.(.*)/ ) {
        $outmodule = $1;
        $outdaemon = $outmodule;
        $isresource = TRUE;
      } elsif ( $userkeys =~ /(.*)\.(.*)/ ) {
        $outdaemon = $1;
        $outmodule = $2;
        $isresource = FALSE;
      }

      if ( not $isresource ) {
        # Write log record
        print $ph "<change>\n";
        print $ph "<command>crsctl</command>\n";
        print $ph "<command_location>GI_HOME</command_location>\n";
        print $ph "<command_type>log</command_type>\n";
        print $ph "<daemon>$outdaemon</daemon>\n";
        print $ph "<module>$outmodule</module>\n";
        print $ph "<set>$levels[0]</set>\n";
        print $ph "<unset>$levels[1]</unset>\n";
        print $ph "</change>\n";

        # 0 1 , log   set/unset
        # 2 3 , trace set/unset

        if ( $levels[2] != -1 ) {
          # Write trace record
          print $ph "<change>\n";
          print $ph "<command>crsctl</command>\n";
          print $ph "<command_location>GI_HOME</command_location>\n";
          print $ph "<command_type>trace</command_type>\n";
          print $ph "<daemon>$outdaemon</daemon>\n";
          print $ph "<module>$outmodule</module>\n";
          print $ph "<set>$levels[2]</set>\n";
          print $ph "<unset>$levels[3]</unset>\n";
          print $ph "</change>\n";
        } # end if , include trace record ?
      } else {
        print $ph "<change>\n";
        print $ph "<command>crsctl</command>\n";
        print $ph "<command_location>GI_HOME</command_location>\n";
        print $ph "<command_type>resource</command_type>\n";
        print $ph "<daemon>$outdaemon</daemon>\n";
        print $ph "<module>$outmodule</module>\n";
        print $ph "<set>$levels[0]</set>\n";
        print $ph "<unset>$levels[1]</unset>\n";
        print $ph "</change>\n";
      } # end if not $isresource
  } # end foreach
  print $ph "</profile>\n";
  close $ph;

  } else {
    # Profile is empty
    unlink $tfa_profile_xml;
    if ( $! !~ /No such file/ ) {
      print "No entries in profile $profilename,  deleted successfully!\n";
    }
  } # end if $count

  return;

}

########
# NAME
#   dbglevel_process_active
#
# DESCRIPTION
#   This function checks if the
#   given profile is active
#
# PARAMETERS
#   $tfa_home        (IN) - TFA Home
#   $tfa_profile_xml (IN) - xml profile
#   $profilename     (IN) - profile name
#
# RETURNS
#
########
sub dbglevel_process_active {
  my $tfa_home        = shift;
  my $tfa_profile_xml = shift;
  my $profilename     = shift;
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");

  my $localhost = tolower_host();

  my $usermodulesref;
  my $userresourcesref;
  my $userdaemonsref;

  my %usermodules;
  my %userresources;
  my %userdaemons;

  my $currlogvalue;
  my $currtracevalue;

  my $profilematched = FALSE;
  my $profilematchedres = FALSE;
  my @plainprofiles;

  my $count = 0;
  my $ptraceflag = FALSE;
  my $punsetflag = FALSE;

  return  1 if dbglevel_validate_gi($tfa_home,$install_type) ne "GI";

  # Load all available profiles
  # type = plain
  if ( defined $profilename && length($profilename) > 0 ) {
     push @plainprofiles, $profilename;
  } else {
    @plainprofiles = dbglevel_load_profiles($tfa_home);
    tfactlshare_trace(5, "tfactl (PID = $$) " .
                      "dbglevel_process_active " .
                      "Plain profiles @plainprofiles",
                      'y', 'y');
  }


  my $message ="$localhost:activeProfileList:";
  my $command = buildCLIJava($tfa_home,$message);
  my $activeProfileList = "";

  foreach my $line (split /\n/ , `$command`)
  {
    if ($line !~ /DONE/) {
      $activeProfileList = $line;
    }
  }

  #print "\n\nACTIVE PROFILES: *$activeProfileList*\n\n";

  for my $ndx (0 .. $#plainprofiles) {
    $profilename = $plainprofiles[$ndx];
    $tfa_profile_xml = catfile($tfa_home, "ext", "dbglevel","profiles",
          $plainprofiles[$ndx] . ".xml");

    # Validate profile
    if ( not -e "$tfa_profile_xml" ) {
      print "Profile $profilename does not exists in directory $tfa_home/ext/dbglevel/profiles.\n";
      return 1;
    }
    
    if ( $activeProfileList =~ /$profilename/ ) {
      print "Profile $profilename is active at this time !\n";
    } else {
      print "Profile $profilename is not active at this time !\n";
    }
  } # end for @plainprofiles
  
  return;
}

########
# NAME
#   dbglevel_get_profileDetails
#
# DESCRIPTION
#   This function reads the profile
#
# PARAMETERS
#   $tfa_home        (IN) - TFA Home
#   $tfa_profile_xml (IN) - xml profile
#   $profilename     (IN) - profile name
#
# RETURNS
#   an array with all the details of the profile
########
sub dbglevel_get_profileDetails {
  my $tfa_home = shift;
  my $tfa_profile_xml = shift;
  my $profilename = shift;
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");

  my (%changes) = ();

  if ( ! -e "$tfa_profile_xml" ) {
    print "Profile $profilename does not exists in directory $tfa_home/ext/dbglevel/profiles.\n";
    return 1;
  };

  %changes = dbglevel_read_profile($tfa_home, $tfa_profile_xml);

  my $arrayref = $changes{$profilename};
  my @tmparray = @$arrayref;

  return @tmparray;
}

########
# NAME
#   dbglevel_get_maxSetLevel
#
# DESCRIPTION
#   This function finds the max set level of a given module (log/trace/resource) in the given profiles
#
# PARAMETERS
#   $commandtype     (IN) - cammand used: crsctl/oclumon etc
#   $module      (IN) - log/trace/resource
#   $daemon      (IN) - Daemon name
#   $profiles      (IN) - List of active profiles
#   $tfa_home        (IN) - TFA Home
#
# RETURNS
#   maximum set level
########
sub dbglevel_get_maxSetLevel {
  my $commandtype = shift;
  my $module = shift;
  my $daemon = shift;
  my $profiles = shift;
  my $tfa_home = shift;
  my $maxLevel = shift;
  my $i;
  my @profiles_as_array = split( ' ', $profiles );
  my $profilesdir = catfile($tfa_home, "ext", "dbglevel","profiles");
  my $tfa_profile_xml;
  my @tmparray;

  foreach $i ( @profiles_as_array ) {
    $tfa_profile_xml = catfile("$profilesdir", lc($i).".xml");
    #print "Profilename: $i\n";

    @tmparray = dbglevel_get_profileDetails($tfa_home, $tfa_profile_xml, $i);

  # Read entries for profile
    for my $ndx ( 0 .. $#tmparray ) {
      if ( lc($tmparray[$ndx][2]) eq lc($commandtype) && lc($tmparray[$ndx][3]) eq lc($daemon) && lc($tmparray[$ndx][4]) eq lc($module) && $maxLevel < $tmparray[$ndx][5] ) {
        $maxLevel = $tmparray[$ndx][5];
        #print  "Profile: $i; Module: $module; Level: $maxLevel\n";
      }
    }
  }

  return $maxLevel;
}

########
# NAME
#   readFileToArray
#
# DESCRIPTION
#   This function reads a file and returns its contents in an array
#
# PARAMETERS
#   $filename      (IN) - Address of the ini file
#
# RETURNS
#   A array of file contents.
########
#Conversion for shell command 'cat <filename>' and returns the contents in an array
sub readFileToArray {
  my $filename = shift;
  my @arr;
  open FILE, "$filename" or die "Could not open $filename!\n";
  while(<FILE>) {
    push @arr, $_;
  }
  close FILE;
  return @arr;
}

########
# NAME
#   read_ini_to_hash
#
# DESCRIPTION
#   This function reads the ini files and ouputs a hash with all key-value pairs
#
# PARAMETERS
#   $comp_loglevel_hash_ref  (IN) - reference of the hash containing components and loglevels
#   $iniFile                 (IN) - Address of the ini file
#
# RETURNS
#   A hash of all key value pairs.
########
sub read_ini_to_hash {
  my $comp_loglevel_hash_ref = shift;
  my $iniFile                = shift;

  my %comp_loglevel_hash     = %$comp_loglevel_hash_ref;

  my @iniFile_contents = readFileToArray($iniFile);
  my @tmp;
  my @tmp1;

  foreach my $line (@iniFile_contents) {
    chomp($line);
    if ( $line =~ /comploglvl/ ) {
      @tmp = split /=/, $line;
      $tmp[1] =~ s/"//g;
      @tmp1 = split /;/, $tmp[1];

      my @tmp2;
      foreach my $keyValPair (@tmp1) {
        @tmp2 = split /:/, $keyValPair;
        if ($tmp2[1]) {
          $comp_loglevel_hash{$tmp2[0]} = $tmp2[1];
        }
      }

      #foreach my $x (keys %comp_loglevel_hash) { print "$x $comp_loglevel_hash{$x}\n"; }
    }
  }

  return \%comp_loglevel_hash;
}

########
# NAME
#   dbglevel_run_dummy_command
#
# DESCRIPTION
#   This function runs a dummy command if its required to set the log levels
#
# PARAMETERS
#   $crs_home        (IN) - set, unset or view
#   $commmand        (IN) - TFA Home
#
# RETURNS
#
########
sub dbglevel_run_dummy_command {
  my $crs_home = shift;
  my $command = shift;

  my $cmdfile = catfile($crs_home, "bin", $command);
  if ( -e $cmdfile ) {
    print "Running Dummy Command...\n";
    if (lc($command) eq "oclumon") {
      `$cmdfile -h`;
    }
  }
}

########
# NAME
#   getTraceFilesList
#
# DESCRIPTION
#   This function get  the list of .trc file related to a command
#
# PARAMETERS
#   $crshome         (IN) - CRS home
#   $oracle_base     (IN) - Oracle Base
#   $command         (IN) - Command type
#
# RETURNS
#
########
sub getTraceFilesList {
  my $crshome = shift;
  my $oracle_base = shift;
  my $command = shift;

  my $localhost = tolower_host();

  my $loc;
  my $files;
  my $cmd;
  my $line;
  my @tmp;
  if (lc($command) eq "oclumon") {
    $files = $command . "_*.trc";
    $loc = catfile($oracle_base, "diag", "crs", $localhost, "crs", "trace", $files);

    $cmd = "ls -ltra $loc | awk '{print \$9}'";
    #print "CMD: $cmd\n";
    $line = `$cmd 2>&1`;
    #print "FILELIST: $line\n";

    @tmp = split /\n/, $line;
  }
  return @tmp;
}

########
# NAME
#   dbglevel_get_ack_noncrs_cmd
#
# DESCRIPTION
#   This function gets the command for the acknowledgement whether the log level has been set or not
#
# PARAMETERS
#   $cmdtype    - resource , module
#   $daemon
#   $module
#
# RETURNS
#   prints the line with the current log level
#
########
sub dbglevel_get_ack_noncrs_cmd {
  my $tfa_home = shift;
  my $command = shift;
  my $cmdtype = shift;
  my $daemon = shift;
  my $module = shift;
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");
  my $crs_home = get_crs_home($tfa_home);

  return 1 if dbglevel_validate_gi($tfa_home,$install_type) ne "GI";

  my $line;
  my $commandline;
  my $output;

  if ( lc($command) eq "oclumon" ) {
    if ( lc($cmdtype) eq "ologgerd" ) {
      $commandline = "$crs_home/bin/oclumon get log $cmdtype $daemon";
    } elsif ( lc($cmdtype) eq "client" ) {
      $commandline = "$crs_home/bin/oclumon get log client $daemon";
      #print "CMD $commandline\n";
    }
  }
  return $commandline;
}

########
# NAME
#   dbglevel_maintain_support_files
#
# DESCRIPTION
#   This function creates/deletes the support files for the profile
#
# PARAMETERS
#   $proctype        (IN) - set, unset or view
#   $tfa_home        (IN) - TFA Home
#   $profilename     (IN) - profile name
#   $tfa_profile_xml (IN) - xml profile
#   $time            (IN) - Time of setting the profile
#
# RETURNS
#
########
sub dbglevel_maintain_support_files {
  my $proctype = shift;
  my $tfa_home = shift;
  my $profilename = shift;
  my $tfa_profile_xml = shift;
  my $time = shift;
  my $commandtype = shift;
  my $FILE;
  my $crs_home = get_crs_home($tfa_home);

  my $pcommand;
  my $pcommandlocation;
  my $pcommandtype;
  my $pdaemon;
  my $pmodule;
  my $psetvalue;
  my $punsetvalue;
  my $localhost = tolower_host();

  my %changes = dbglevel_read_profile($tfa_home, $tfa_profile_xml);

  my $arrayref = $changes{$profilename};
  my @tmparray = @$arrayref;

  my %comp_loglevel_hash;
  my $comp_loglevel_hash_ref;

  if ( lc($proctype) eq "set" ) {
    print "Creating Support Files...\n";
    if ( lc($profilename) eq "crs_gi_startup_stop" ) {
      $FILE = catfile($oracle_base, "crsdata", "$hostname", "crsdiag", "ohasd.ini");
      print "$FILE\n";
      open(my $fptr, '>>', $FILE) or die "Could not open file '$FILE' $!";
      print $fptr "#mesg_logging_level=5\ncomploglvl=\"CRSPE:5;AGFW:5;UiServer:5\"\n";

      $FILE = catfile($oracle_base, "crsdata", "$hostname", "crsdiag", "crsd.ini");
      print "$FILE\n";
      open(my $fptr, '>>', $FILE) or die "Could not open file '$FILE' $!";
      print $fptr "#mesg_logging_level=5\ncomploglvl=\"CRSPE:5;AGFW:5;UiServer:5\"\n";
    } else {
      undef %comp_loglevel_hash;
      undef $comp_loglevel_hash_ref;

      if (lc($commandtype) eq "oclumon") {
        $FILE = catfile($oracle_base, "crsdata", "$hostname", "crsdiag", "oclumon.ini");
        print "$FILE\n";
      }

      if ( -e $FILE ) {
        $comp_loglevel_hash_ref = read_ini_to_hash(\%comp_loglevel_hash,$FILE);
        %comp_loglevel_hash = %$comp_loglevel_hash_ref;
      }

      for my $ndx ( 0 .. $#tmparray ) {
        $pcommand         = $tmparray[$ndx][0];
        $pcommandlocation = $tmparray[$ndx][1];
        $pcommandtype     = $tmparray[$ndx][2];
        $pdaemon          = $tmparray[$ndx][3];
        $pmodule          = $tmparray[$ndx][4];
        $psetvalue        = $tmparray[$ndx][5];
        $punsetvalue      = $tmparray[$ndx][6];

        if ( lc($pcommand) eq "oclumon" && lc($pcommandtype) eq "ini" ) {
          if ( $comp_loglevel_hash{$pmodule} && $comp_loglevel_hash{$pmodule} < $psetvalue ) {
            $comp_loglevel_hash{$pmodule} = $psetvalue;
          } elsif ( ! $comp_loglevel_hash{$pmodule} ) {
            $comp_loglevel_hash{$pmodule} = $psetvalue;
          }
        }
      }

      if (lc($commandtype) eq "oclumon") {
        my $KeyValuePair = "";
        if ( keys %comp_loglevel_hash ) {
          foreach my $comp (keys %comp_loglevel_hash) {
            $KeyValuePair = $KeyValuePair.$comp.":".$comp_loglevel_hash{$comp}.";";
          }
        }
        chop($KeyValuePair);

        if ( length($KeyValuePair) != 0 ) {
          #print "Key Value Pair: $KeyValuePair\n";
          open(my $fptr, '>', $FILE) or die "Could not open file '$FILE' $!";
          print $fptr "#mesg_logging_level=5\ncomploglvl=\"$KeyValuePair\"\n";
        }

        dbglevel_run_dummy_command($crs_home, "oclumon");
        my $ackUser;
        my $cmd;
        my $check_ack_recieved = 1;
        foreach my $key (keys %comp_loglevel_hash) {
          $cmd = dbglevel_get_ack_noncrs_cmd($tfa_home, "oclumon", "client", $key, $key );
          `$cmd &> /tmp/ack.txt`;
          my @ackArr = readFileToArray("/tmp/ack.txt");
          $ackUser = $ackArr[0];
          chomp($ackUser);
          unlink("/tmp/ack.txt");
          if ($ackUser =~ /CRS-9008/ ) {
            $check_ack_recieved = 0;
          } else {
            print "$ackUser\n";
          }
        }

        if ($check_ack_recieved == 0) {
          print "GI Version doesn't support setting through DIF files. Setting the env variable...\n";
          $ENV{"ORA_OSTOOL_LOG_LEVEL"} = 3;
        }
      }
    }
  } elsif ( lc($proctype) eq "unset" ) {
    print "Deleting/Modifying Support Files...\n";
    if ( lc($profilename) eq "crs_gi_startup_stop" ) {
      $FILE = catfile($oracle_base, "crsdata", "$hostname", "crsdiag", "ohasd.ini");
      if ( -e $FILE ) {
        print "$FILE\n";
        unlink $FILE;
      }

      $FILE = catfile($oracle_base, "crsdata", "$hostname", "crsdiag", "crsd.ini");
      if ( -e $FILE ) {
        print "$FILE\n";
        unlink $FILE;
      }
    } else {
      undef %comp_loglevel_hash;
      undef $comp_loglevel_hash_ref;
      my $setvalue;

      if (lc($commandtype) eq "oclumon") {
        $FILE = catfile($oracle_base, "crsdata", "$hostname", "crsdiag", "oclumon.ini");
        print "$FILE\n";
      }

      if ( -e $FILE ) {
        $comp_loglevel_hash_ref = read_ini_to_hash(\%comp_loglevel_hash,$FILE);
        %comp_loglevel_hash = %$comp_loglevel_hash_ref;
      }

      for my $ndx ( 0 .. $#tmparray ) {
        $pcommand         = $tmparray[$ndx][0];
        $pcommandlocation = $tmparray[$ndx][1];
        $pcommandtype     = $tmparray[$ndx][2];
        $pdaemon          = $tmparray[$ndx][3];
        $pmodule          = $tmparray[$ndx][4];
        $psetvalue        = $tmparray[$ndx][5];
        $punsetvalue      = $tmparray[$ndx][6];

        if ( lc($pcommand) eq "oclumon" && lc($pcommandtype) eq "ini" ) {
          my $message = "$localhost:activeProfileList:";
          my $command = buildCLIJava($tfa_home,$message);

          foreach my $line (split /\n/ , `$command`)
          {
            if ($line ne "" && $line ne 'DONE' && $line ne '\n') {
              $setvalue = dbglevel_get_maxSetLevel($pcommandtype, $pmodule, $pdaemon, $line, $tfa_home, $punsetvalue);
            }
          }
          
          $comp_loglevel_hash{$pmodule} = $setvalue;
        }
      }

      if (lc($commandtype) eq "oclumon") {
        my $KeyValuePair = "";
        if ( keys %comp_loglevel_hash ) {
          foreach my $comp (keys %comp_loglevel_hash) {
            $KeyValuePair = $KeyValuePair.$comp.":".$comp_loglevel_hash{$comp}.";";
          }
        }
        chop($KeyValuePair);

        if ( length($KeyValuePair) != 0 ) {
          #print "Key Value Pair: $KeyValuePair\n";
          #print "$FILE\n";
          open(my $fptr, '>', $FILE) or die "Could not open file '$FILE' $!";
          print $fptr "#mesg_logging_level=5\ncomploglvl=\"$KeyValuePair\"\n";
        }

        dbglevel_run_dummy_command($crs_home, "oclumon");
        my $ackUser;
        my $cmd;
        my $check_ack_recieved = 1;
        foreach my $key (keys %comp_loglevel_hash) {
          $cmd = dbglevel_get_ack_noncrs_cmd($tfa_home, "oclumon", "client", $key, $key );
          `$cmd &> /tmp/ack.txt`;
          my @ackArr = readFileToArray("/tmp/ack.txt");
          $ackUser = $ackArr[0];
          chomp($ackUser);
          unlink("/tmp/ack.txt");
          if ($ackUser =~ /CRS-9008/ ) {
            $check_ack_recieved = 0;
          } else {
            print "$ackUser\n";
          }
        }

        if ($check_ack_recieved == 0) {
          print "GI Version doesn't support setting through DIF files. Setting the env variable...\n";
          $ENV{"ORA_OSTOOL_LOG_LEVEL"} = 0;
        }
      }
    }
  }
  return;
}

########
# NAME
#   dbglevel_process_set
#
# DESCRIPTION
#   This function reads the profile
#
# PARAMETERS
#   $proctype        (IN) - set, unset or view
#   $tfa_home        (IN) - TFA Home
#   $tfa_profile_xml (IN) - xml profile
#   $profilename     (IN) - profile name
#   $profiletimeout  (IN) - Duration upto which the profile remains active
#   $pnobroadcast    (IN) - Flag used when needed to activate a
#         profile on a node without notifying
#         other nodes in a cluster
#   $dependency      (IN) - START/STOP dependencies
#   $dependency_type (IN) - Type of dependencies to be considered
#
# RETURNS
#
########
sub dbglevel_process_set {
  my $proctype     = shift;
  my $tfa_home = shift;
  my $tfa_profile_xml = shift;
  my $profilename = shift;
  my $profiletimeout = shift;
  my $pnobroadcast = shift;
  my $dependency = shift;
  my $dependency_type = shift;
  my $install_type = tfactlshare_get_val4key_in_tfa_setup($tfa_home,"INSTALL_TYPE");
  my $pcommand;
  my $pcommandlocation;
  my $pcommandtype;
  my $pdaemon;
  my $pmodule;
  my $psetvalue;
  my $punsetvalue;
  my $setvalue;
  my $datestring = strftime "%Y-%m-%d %H:%M:%S", localtime;
  my $oclumon_unset = 0;

  my (%changes) = ();

  if ( ! -e "$tfa_profile_xml" ) {
    print "Profile $profilename does not exists in directory $tfa_home/ext/dbglevel/profiles.\n";
    return 1;
  };

  if ( dbglevel_validate_gi($tfa_home,$install_type) eq "STACKDOWN" ) {
    dbglevel_maintain_support_files($proctype, $tfa_home, $profilename, $tfa_profile_xml, $datestring, "");
  } elsif ( dbglevel_validate_gi($tfa_home,$install_type) ne "GI" ) {
    return 1;
  }

  %changes = dbglevel_read_profile($tfa_home, $tfa_profile_xml);

  my $arrayref = $changes{$profilename};
  my @tmparray = @$arrayref;
  my $loglevel;
  my $tracelevel;
  my $commandoutput;
  my $profiletype;

  $profiletype = dbglevel_get_attribute($tfa_profile_xml, "type");

  my $line;
  my $localhost = tolower_host();

  if ( lc($proctype) eq "set" ) {
    my $time;
    my $timeout;

    #print "\nTimeout: $profiletimeout\n";

    if ( $pnobroadcast == 0 && $profiletimeout ne "" ) {
      if ( $profiletimeout eq "-1" ) {
        $profiletimeout = dbglevel_get_attribute($tfa_profile_xml,"timeout");
      }

      if ( $profiletimeout ne "-1" ) {
        my @time_as_array = split( '', $profiletimeout );   #converts 3h-> 10800s (3*3600s), 2m -> 120s (2*60s), 5s -> 5s (5*1s)
        if ( lc($time_as_array[-1]) eq 's' ) {
                $time = join( '', @time_as_array );
                $timeout = $time * 1;
        } elsif ( lc($time_as_array[-1]) eq 'm' ) {
                $time = join( '', @time_as_array );
                $timeout = $time * 60;
        } elsif ( lc($time_as_array[-1]) eq 'h' ) {
                $time = join( '', @time_as_array );
                $timeout = $time * 3600;
        }
      } else {
        $timeout = -1;
      }

      my $message ="$localhost:setprofilelist:$profilename $timeout";
      my $command = buildCLIJava($tfa_home,$message);

      foreach $line (split /\n/ , `$command`)
      {
        #print "$line\n";
        if ( $line eq "SUCCESS") {
          if ( $profiletimeout eq "-1" ) {
              print "\nSetting $profilename for infinite time\n\n";
          } else {
              print "\nSetting $profilename for $profiletimeout\n\n";
          }
        } elsif ( $line =~ /Succesfully added Profile to DB/) {
          print "$line\n\n";
        } elsif ( $line =~ /FAILED/) {
          print "\nFailed setting $profilename for $profiletimeout\n\n";
          return 1;
        } else { # Stop loop
          print "$line\n";
          return;
        }
      }
    }
  } elsif ( $pnobroadcast == 0 && lc($proctype) eq "unset" ) {
    my $message ="$localhost:unsetprofilelist:$profilename";
    my $command = buildCLIJava($tfa_home,$message);

    foreach $line (split /\n/ , `$command`)
    {
      #print "$line\n";
      if ( $line eq "SUCCESS" ) {
        print "\nUnsetting $profilename\n\n";
      } elsif ( $line =~ /Succesfully removed Profile from DB/) {
        print "$line\n\n";
      } elsif ( $line =~ /FAILED/) {
        print "\nFailed unsetting $profilename\n\n";
        return 1;
      } else { # Stop loop
        print "$line\n";
        return;
      }
    }
  }

  my $iniFileCreatedFlag = 0;
  if ( dbglevel_validate_gi($tfa_home,$install_type) eq "GI" ) {
    # Read entries for profile
    for my $ndx ( 0 .. $#tmparray ) {
      $pcommand =         $tmparray[$ndx][0];
      $pcommandlocation = $tmparray[$ndx][1];
      $pcommandtype     = $tmparray[$ndx][2];
      $pdaemon          = $tmparray[$ndx][3];
      $pmodule          = $tmparray[$ndx][4];
      $psetvalue        = $tmparray[$ndx][5];
      $punsetvalue      = $tmparray[$ndx][6];

      #print "CHECK: $pcommand $pcommandlocation $pcommandtype $pdaemon $pmodule $psetvalue $punsetvalue\n";

      if ( lc($proctype) ne "view" ) {
        if ( lc($proctype) eq "set" ) {
          $setvalue = $psetvalue;
        } elsif ( lc($proctype) eq "unset" ) {
          if ( $punsetvalue != -1 ) {
            $setvalue = $punsetvalue;
          } else {
            print "Unset value is not yet defined for $pcommandtype $pdaemon:$pmodule, " .
            "setting to default...\n";
            if ( lc($pcommandtype) eq "log" || lc($pcommandtype) eq "resource" ) {
              $setvalue = 2;
            } elsif ( lc($pcommandtype) eq "trace" ) {
              $setvalue =  0;
            }
          }
        } else {
          $setvalue = $psetvalue;
        }

        tfactlshare_trace(5, "tfactl (PID = $$) dbglevel_process_set " .
                              "Record $proctype $pcommand $pcommandlocation $pcommandtype " .
                              "$pdaemon $pmodule $psetvalue $punsetvalue",
                              'y', 'y');
        if ( lc($pcommand) eq "crsctl" ) {
          if ( lc($pcommandtype) eq "resource" ) {
            if ( $pdaemon =~ /\(/ ) {
            } else {
              $loglevel = dbglevel_get_current_levels("resource",
                      $pdaemon, $pmodule);
            }
          } else {
            $loglevel = dbglevel_get_current_levels("log",$pdaemon, $pmodule);
            $tracelevel = dbglevel_get_current_levels("trace",
                    $pdaemon, $pmodule);
          }
        }

        # Set levels
        if ( lc($pcommand) eq "crsctl" ) {
          if ( lc($pcommandtype) eq "log" ) {
            tfactlshare_trace(5, "tfactl (PID = $$) dbglevel_process_set " .
                  "Before modification, Log level: $loglevel", 'y', 'y');
            if ( lc($proctype) eq "unset" || (lc($proctype) eq "set" && $loglevel < $setvalue) ) {
              if ( lc($proctype) eq "unset" ) {
                my $message ="$localhost:activeProfileList:";
                my $command = buildCLIJava($tfa_home,$message);

                foreach $line (split /\n/ , `$command`)
                {
                  if ($line ne "" && $line ne 'DONE' && $line ne '\n') {
                    $setvalue = dbglevel_get_maxSetLevel($pcommandtype, $pmodule, $pdaemon, $line, $tfa_home, $setvalue);
                  }
                }
              }
              $commandoutput = dbglevel_set_level($pcommand, $pcommandtype, $pdaemon, $pmodule, $setvalue );
              print "dbglevel_set_level $commandoutput \n";
            } else {
              print "Module $pmodule already set by some other profile at level $loglevel....\n";
              return 1;
            }
          } elsif ( lc($pcommandtype) eq "trace" ) {
            tfactlshare_trace(5, "tfactl (PID = $$) dbglevel_process_set " .
                  "Before modification, Trace level: $tracelevel", 'y', 'y');
            if ( lc($proctype) eq "unset" || (lc($proctype) eq "set" && $loglevel < $setvalue) ) {
              if ( lc($proctype) eq "unset" ) {
                my $message ="$localhost:activeProfileList:";
                my $command = buildCLIJava($tfa_home,$message);

		foreach $line (split /\n/ , `$command`)
		{
		  if ($line ne "" && $line ne 'DONE' && $line ne '\n') {
		    $setvalue = dbglevel_get_maxSetLevel($pcommandtype, $pmodule, $pdaemon, $line, $tfa_home, $setvalue);
		  }
		}
	      }
	      $commandoutput = dbglevel_set_level($pcommand, $pcommandtype, $pdaemon, $pmodule, $setvalue );
              print "dbglevel_set_level $commandoutput\n";
	    } else {
	      print "Module $pmodule already set by some other profile at level $loglevel....\n";
              return 1;
	    }
	  }  elsif ( lc($pcommandtype) eq "resource" ) {
            if ( $pmodule =~ /\(/ || $pmodule =~ /\*/) {
              my $module = "^" . $pmodule . "\$";

              # Numeric placeholder for $pmodule -> (n)
              # e.g. ora.scan(n).vip will be transformed to ora.scan[0-9].vip
              # ora.scan[0-9].vip will be processed in dbglevel_process_match()
              if ( $pmodule =~ /\(n\)/ ) {
                      $module =~ s/\(n\)/[0-9]*/g;
              }
              # Alphanumeric placeholder for $pmodule -> (a-zA-Z0-9)
              # e.g. ora.(hostname).vip will be transformed to ora.[a-zA-Z0-9].vip
              # ora.[a-zA-Z0-9].vip will be processed in dbglevel_process_match()
              elsif ( $pmodule =~ /\([a-zA-Z]*\)/ ) {
                      $module =~ s/\([a-zA-z]*\)/[a-zA-Z0-9]*/g;
              }

              #print "MODULE: $module\nPMODULE: $pmodule\n";
              
              my $matchResult = dbglevel_process_match($tfa_home, $module, $pmodule);
              if ( $matchResult == 0 ) {
                print "\nEnter any one of the above similar resource\n";
                $pmodule = <STDIN>;
                $pmodule =~ s/^\s+//;
                $pmodule =~ s/\s+$//;
              } elsif ( $matchResult == -1 ) {
                print "Unable to set $pmodule...\n";
                next;
              }
            }

            tfactlshare_trace(5, "tfactl (PID = $$) dbglevel_process_set " .
                  "Before modification, Log level: $loglevel", 'y', 'y');
            if ( lc($proctype) eq "unset" || (lc($proctype) eq "set" && $loglevel < $setvalue) ) {
              if ( lc($proctype) eq "unset" ) {
                my $message ="$localhost:activeProfileList:";
                my $command = buildCLIJava($tfa_home,$message);

                foreach $line (split /\n/ , `$command`)
                {
                  if ($line ne "" && $line ne 'DONE' && $line ne 'l\n') {
                    $setvalue = dbglevel_get_maxSetLevel($pcommandtype, $pmodule, $pdaemon, $line, $tfa_home, $setvalue);
                  }
                }
              }
              $commandoutput = dbglevel_set_level($pcommand, $pcommandtype, $pdaemon, $pmodule, $setvalue );
              print "dbglevel_set_level $commandoutput\n";
            } else {
              print "Module $pmodule already set by some other profile at a higher level: $loglevel....\n";
              return 1;
            }

            if (lc($proctype) eq "set") {
              dbglevel_process_set_dependent_resources($proctype, $pmodule, $tfa_home, $profilename, $dependency, $dependency_type, 5);
            } elsif (lc($proctype) eq "unset") {
              dbglevel_process_set_dependent_resources($proctype, $pmodule, $tfa_home, $profilename, $dependency, $dependency_type, 1);
            }
          }
        } elsif ( lc($pcommand) eq "oclumon" ) {
          if ( lc($pcommandtype) eq "ologgerd" ) {
            tfactlshare_trace(5, "tfactl (PID = $$) dbglevel_process_set " .
                  "oclumon debug log ologgerd,set $pmodule Log level: $setvalue", 'y', 'y');
            if ( lc($proctype) eq "unset" ) {
              my $message ="$localhost:activeProfileList:";
              my $command = buildCLIJava($tfa_home,$message);

              foreach $line (split /\n/ , `$command`)
              {
                if ($line ne "" && $line ne 'DONE' && $line ne '\n') {
                  $setvalue = dbglevel_get_maxSetLevel($pcommandtype, $pmodule, $pdaemon, $line, $tfa_home,$setvalue);
                }
              }
            }

            #print "$pcommand => $pmodule => $setvalue\n";
            $commandoutput = dbglevel_set_level($pcommand, $pcommandtype, $pdaemon, $pmodule, $setvalue );
            if ( $commandoutput =~ /CRS.*Error/i ) {
              print "$commandoutput\n";
              return 1;
            }
          } elsif ( lc($proctype) eq "set" && lc($pcommandtype) eq "ini" ) {
            if ( $iniFileCreatedFlag == 0 ) {
              dbglevel_maintain_support_files($proctype, $tfa_home, $profilename, $tfa_profile_xml, $datestring, "oclumon");
              $iniFileCreatedFlag = 1;
            }
          } elsif ( lc($proctype) eq "unset" && lc($pcommandtype) eq "ini" ) {
            $oclumon_unset = 1;
          }
        }
      } else { # else ->  view
        my $formattedstring = "";

        if ( $ndx == 0 ) {
          print "PROFILE\t: $profilename\nTYPE\t: $profiletype\n";
          $formattedstring = sprintf("%-10s %-10s %-10s %-20s %-20s %1s %1s",
            "Command", "Cmd. Loc.", "Cmd. Type", "Daemon", "Module",
            "S", "U");
          print "$formattedstring\n";
          $formattedstring = sprintf("%-10s %-10s %-10s %-20s %-20s %1s %1s",
            "-------", "---------", "----------", "----------", "----------",
            "-", "-");
          print "$formattedstring\n";
        }
        $formattedstring = "";
        $formattedstring .= sprintf("%-10s %-10s %-10s %-20s %-20s %1s %1s",
          $pcommand, $pcommandlocation, $pcommandtype, $pdaemon,
          $pmodule, $psetvalue, $punsetvalue);
        print "$formattedstring\n";
        $formattedstring = "";
      } # end if not view
    } # end for @profilerecords
  }

  if ( dbglevel_validate_gi($tfa_home,$install_type) eq "GI" && lc($proctype) eq "unset" ) {
    if ($oclumon_unset == 0) {
      dbglevel_maintain_support_files($proctype, $tfa_home, $profilename, $tfa_profile_xml, $datestring, "");
    } else {
      dbglevel_maintain_support_files($proctype, $tfa_home, $profilename, $tfa_profile_xml, $datestring, "oclumon");
    }
  }

  return;
}

########
# NAME
#   dbglevel_process_set_dependent_resources
#
# DESCRIPTION
#   This function sets/unsets the dependent resources given a resource.
#
# PARAMETERS
#   $proctype        (IN) - set, unset or view
#   $module          (IN) - Name of the resource
#   $tfa_home        (IN) - TFA Home
#   $profilename     (IN) - profile name
#   $dependency      (IN) - Option for START/STOP dependency
#   $dependency_type (IN) - Type of dependency to be considered
#   $setval      (IN) - Log level to be set
#
# RETURNS
#
########
sub dbglevel_process_set_dependent_resources {
  my $proctype = shift;
  my $pmodule = shift;
  my $tfa_home = shift;
  my $profilename = shift;
  my $dependency = shift;
  my $dependency_type = shift;
  my $setval = shift;

  my $commandoutput;
  my @tmp = split /,/,$dependency;
  my @adepn;
  foreach my $x (@tmp) {
    if (lc($x) eq "start") {
      push @adepn, "START_DEPENDENCIES";
    } elsif (lc($x) eq "stop") {
      push @adepn, "STOP_DEPENDENCIES";
    } elsif (lc($x) eq "all") {
      push @adepn, "START_DEPENDENCIES";
      push @adepn, "STOP_DEPENDENCIES";
    }
  }
  #printArr(\@adepn);

  @tmp = split /,/,$dependency_type;
  my @adepntp;
  foreach my $x (@tmp) {
    if (lc($x) eq "all") {
      push @adepntp, "hard";
      push @adepntp, "weak";
      push @adepntp, "pullup";
      push @adepntp, "dispersion";
    } else {
      push @adepntp, lc($x);
    }
  }
  #printArr(\@adepntp);

  undef(@retArr);
  print "\nSearching Dependent Resources for $pmodule . . .\n\n";
  dbglevel_search_dependent_resources($pmodule,\@adepn,\@adepntp);
  if ($#retArr == -1) {
    print "\n$pmodule has no dependent resources. . .\n";
  } else {
    print "\nSetting the following Dependent Resources:\n";
    printArr(\@retArr);
    print "\n";

    foreach my $res (@retArr) {
      $commandoutput = dbglevel_set_level("crsctl", "resource", $res, $res, $setval );
      print "$commandoutput\n";
    }
    undef(@retArr);
  }
  return;
}

########
# NAME
#   dbglevel_load_profiles
#
# DESCRIPTION
#   This function loads the available profile
#
# PARAMETERS
#   $tfa_home        (IN) - TFA Home
#
# RETURNS
#
########
sub dbglevel_load_profiles {
  my $tfa_home = shift;
  my $tfa_profile;
  my @profiletagsarray;
  my $attrname;
  my $profilename;
  my $profiletype;
  my $line;
  my $commandline;
  my @profiles;
  my @retprofiles;

  # Load potential profiles  
  my $profiles_dir = catdir($tfa_home,"ext", "dbglevel", "profiles");

  opendir my $dh, $profiles_dir or print  "Could not open '$profiles_dir' for reading: $!\n" and return @retprofiles;
  my @dir_contents = readdir $dh;

  foreach $line (@dir_contents) { 
    if ( $line =~ /(.*)\.xml/ ) {  # Retrieve profilename
      push @profiles, $1;
      tfactlshare_trace(5, "tfactl (PID = $$) " .
                       "dbglevel_load_profiles " .
                       "Profilename $1", 'y', 'y');
    } 
  } # end foreach $commandline
  
  for my $ndx ( 0 .. $#profiles ) {
    $tfa_profile = "$tfa_home/ext/dbglevel/profiles/" . $profiles[$ndx] . ".xml";

    tfactlshare_trace(5, "tfactl (PID = $$) " .
                     "dbglevel_load_profiles " .
                     "tfa_profile $tfa_profile", 'y', 'y');

    if ( -e "$tfa_profile" )
    {
      $profiletype = dbglevel_get_attribute($tfa_profile, "type");
    } # end if -e "$tfa_profile"

    tfactlshare_trace(5, "tfactl (PID = $$) " .
                     "dbglevel_load_profiles " .
                     "Profile = $profiles[$ndx] , type =  $profiletype", 'y', 'y');

    if ( lc($profiletype) eq "default" || lc($profiletype) eq "user" ) {
      push @retprofiles, $profiles[$ndx];
    }

  } # end for

  return @retprofiles;
}

########
# NAME
#   dbglevel_read_profile
#
# DESCRIPTION
#   This function reads the profile
#
# PARAMETERS
#   $tfa_home        (IN) - TFA Home
#   $tfa_profile     (IN) - profile
#
# RETURNS
#   %tools
#
########
sub dbglevel_read_profile
{
  my $tfa_home = shift;
  my $tfa_profile = shift;
  my %changes = ();
  my @profiletagsarray;
  my @profileentries;
  my $attrname;
  my $profilename;
  my $profiletype;
  my $pcommand;
  my $pcommandlocation;
  my $pcommandtype;
  my $pdaemon;
  my $pmodule;
  my $psetvalue;
  my $punsetvalue;
  my $name;
  my $value;

  tfactlshare_trace(5, "tfactl (PID = $$) " .
                    "dbglevel_read_profile " .
                    "Profile $tfa_profile tfa_home $tfa_home",
                    'y', 'y');

  if ( -e "$tfa_profile" )
  {
    # Parse xml file
    @profiletagsarray = tfactlshare_populate_tagsarray($tfa_profile);

    # Parse profile
    my @profileList = tfactlshare_get_element(\@profiletagsarray, 0,0);

    foreach my $child (@profileList)
    {
      # Get the profile
      my $name = @$child[ELEMNAME];
      # Get attributes
      ($attrname , $profilename) = tfactlshare_get_attribute(
                   @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL],
                   "name" );
      ($attrname , $profiletype) = tfactlshare_get_attribute(
                   @$child[ELEMATTRNAME] , @$child[ELEMATTRVAL],
                   "type" );

      # Get the change
      my @changesList = tfactlshare_get_element( \@profiletagsarray,
                        @$child[ELEMLEVEL]+1 , @$child[ELEMNDX] );

      foreach my $change (@changesList)
      {
        $name = @$change[ELEMNAME];
        $value = @$change[ELEMVAL];

        # Get the change details
        my @changedetList = tfactlshare_get_element( \@profiletagsarray,
                            @$change[ELEMLEVEL]+1 , @$change[ELEMNDX] );

        undef $pcommand;
        undef $pcommandlocation;
        undef $pcommandtype;
        undef $pdaemon;
        undef $pmodule;
        undef $psetvalue;
        undef $punsetvalue;

        foreach my $changedet (@changedetList)
        {
          $name = @$changedet[ELEMNAME];
          $value = @$changedet[ELEMVAL];

          # ------------------------------------------------------
          if ( lc($name) eq "command" ) {                # command
            $pcommand = $value;
          # ------------------------------------------------------
          } elsif ( lc($name) eq "command_location" ) {  # command_location
            $pcommandlocation = $value;
          # ------------------------------------------------------
          } elsif ( lc($name) eq "command_type" ) {      # command_type
            $pcommandtype = $value;
          # ------------------------------------------------------
          } elsif ( lc($name) eq "daemon" ) {            # daemon
            $pdaemon = $value;
          # ------------------------------------------------------
          } elsif ( lc($name) eq "module" ) {            # module
            $pmodule = $value;
          # ------------------------------------------------------
          } elsif ( lc($name) eq "set" ) {               # set
            $psetvalue = $value;
          # ------------------------------------------------------
          } elsif ( lc($name) eq "unset" ) {             # unset
            $punsetvalue = $value;
          # ------------------------------------------------------
          }

          if ( defined $pcommand     && defined $pcommandlocation &&
               defined $pcommandtype && defined $pdaemon &&
               defined $pmodule      && defined $psetvalue &&
               defined $punsetvalue ) {

            push @profileentries, [ $pcommand, $pcommandlocation, $pcommandtype,
                                    $pdaemon,  $pmodule,          $psetvalue,
                                    $punsetvalue  ];

            tfactlshare_trace(5, "tfactl (PID = $$) " .
                              "dbglevel_read_profile " .
                              "ProfileName $profilename $pcommand $pcommandlocation " .
                              "$pcommandtype $pdaemon $pmodule $psetvalue " .
                              "$punsetvalue", 'y', 'y');

            undef $pcommand;
            undef $pcommandlocation;
            undef $pcommandtype;
            undef $pdaemon;
            undef $pmodule;
            undef $psetvalue;
            undef $punsetvalue;
          } # end if check complete entry

          } # end foreach @changedetList
        } # end foreach @changeList
    } # end foreach @profileList

    $changes{$profilename} =  [ @profileentries ] ;

  } else {
    print "Profile doesn't exists ...\n";
    return 1;
  } # end if exists $tfa_profile

  #$changes{$profilename} =  [ @profileentries ] ;

  return %changes;
}

sub dbglevel_search_dependent_resources {
    my $resource =  shift;
    my $dep_arrayRef = shift;
    my @dep_array = @{$dep_arrayRef};
    my $dep_type_arrayRef = shift;
    my @dep_type_array = @{$dep_type_arrayRef};

    my $dep;
    my @dep_res;
    my @recArr;
    my @tmp;
    my @tmp1;
    my $dep_type_hash;

    if ( keys(%res) == 0 ) {
        %res = getCrsdResourcesCfg();
    }

    #print "**************\n";
    #printArr(\@retArr);
    #print "**************\n";
    #print "\nRESOURCE: $resource\n";

    if ($res{$resource}) {
      foreach my $x (keys %{$res{$resource}}) {
          foreach my $y (keys %{$res{$resource}{$x}}) {
        foreach my $dp ( @dep_array ) {
            if ( $y =~ /$dp$/ ) {
              $dep = $res{$resource}{$x}{$y};
              #print "$dep\n";

              @dep_res = split /\) /, $dep;
              foreach my $z (@dep_res) {
                $z =~ s/\)//g;
                @tmp = split /\(/,$z;
                $dep_type_hash = $tmp[0];
                @tmp = split /,\s*/,$tmp[1];
                #print "$z\n";

                foreach my $v (@tmp) {
                  @tmp1 = split /:/, $v;
                  foreach my $dp_tp (@dep_type_array) {
                    #print "type: $dp_tp -> $dep_type_hash\n";
                    if ($dep_type_hash eq $dp_tp) {
                      push @retArr, $tmp1[-1];
                      push @recArr, $tmp1[-1];
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    @retArr = array_uniq_elem(@retArr);
    @recArr = array_uniq_elem(@recArr);

    #print "\n";
    while( $#recArr != -1 ) {
      dbglevel_search_dependent_resources(pop(@recArr),\@dep_array,\@dep_type_array);
    }
}

#takes an array with redundant elements and returns an array with unique elements
sub array_uniq_elem {
    my %seen;
    grep !$seen{$_}++, @_;
}

sub printArr {
  my $arrref = shift;
  my @arr = @{$arrref};
  foreach my $x (@arr) {
    print "$x\n";
  }
}

sub trimString{
   my $str = $_;
   $str = shift;
   $str =~ s/^\s+//;
   $str =~ s/\s+$//;
   return $str ;
}

1;
