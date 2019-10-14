#! /usr/bin/perl
# 
# $Header: tfa/src/v2/tfa_home/bin/restServices.pl /st_tfa_19/4 2019/03/02 06:01:51 cnagur Exp $
#
# restServices.pl
# 
# Copyright (c) 2018, 2019, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      restServices.pl - This Script Manages TFA REST options
#
#    DESCRIPTION
#      This Script manages all TFA REST options like start, stop, uninstall etc.
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    cnagur      02/28/19 - Update jackson-annotations-2.9.8.jar
#    cnagur      12/04/18 - XbranchMerge
#                           cnagur_tfa_jackson_core-2.9.6_annotations-2.9.5_txn
#                           from main
#    cnagur      09/18/18 - XbranchMerge cnagur_tfa_rest_loop_last_txn from
#    cnagur      01/11/19 - Update jackson-databind-2.9.8.jar
#    cnagur      11/30/18 - Update jackson Jars
#    bburton     09/13/18 - 28605375 - Fix Permissions issues
#    cnagur      09/04/18 - Fix for Bug 28315266
#    cnagur      08/24/18 - Fix for Bug 28493056
#    cnagur      07/13/18 - Support upgrade option
#    cnagur      07/11/18 - Fix for Bugs 28305945,28171873
#    cnagur      06/13/18 - Updated default Debug Level
#    cnagur      06/04/18 - Bug Fixes - 28101678,28101813,28103243,28102641
#    cnagur      03/20/18 - Creation
# 
###################################################################

use English;
use File::Basename;
use File::Spec::Functions;
use File::Copy;
use Cwd 'abs_path';
use POSIX;
use File::Find;
use POSIX qw(strftime);
use File::Path;
use Net::Domain qw(hostdomain);

BEGIN {
	# Add the directory of this file to the search path
	push @INC, dirname($PROGRAM_NAME);
	push @INC, dirname($PROGRAM_NAME).'/common';
	push @INC, dirname($PROGRAM_NAME).'/modules';
	push @INC, dirname($PROGRAM_NAME).'/common/exceptions';
	$ENV{LC_ALL} = C;
}

use strict;
use Getopt::Long qw(:config no_auto_abbrev);
use tfactlglobal;
use tfactlshare;

# Local variables
my $hostname = tolower_host();
my $tfa_home;
my $tfa_base;
my $perl;
my $crs_home;
my $oracle_base;
my $rest_prop;

my $start;
my $status;
my $stop;
my $upgrade;
my $uninstall;

my $java_home;
my $java;
my $jar;

my $ords_base;
my $ords_dir;
my $ords_port;
my $ords_user;
my $ords_war;
my $ords_prop;
my $ords_config;
my $ords_log;
my $ords_auth = 0;

my $build_version = 0;
my $build_id = 0;

my $context = "tfactl";
my $tool = "tfactl";

my $help = 0;
my $debug = 0;
my $debug_level;

# Basic Checks
if ( ! -r catfile($INITDIR, "init.tfa" ) ) {
	error("TFA is not Installed on this machine. Exiting now\n");
	exit 1;
}

if ( "$current_user" ne "root" ) {
	error("User $current_user does not have permissions to run this script.\n");
	exit 1;
}

# Parse Arguments
GetOptions('tfa_home=s'=> \$tfa_home,
		   'dir=s'     => \$ords_base,
		   'port=s'    => \$ords_port,
		   'user=s'    => \$ords_user,
		   'tool=s'    => \$tool,
		   'start'     => \$start,
		   'status'    => \$status,
		   'stop'      => \$stop,
		   'upgrade'   => \$upgrade,
		   'uninstall' => \$uninstall,
		   'debug'     => \$debug,
		   'level=s'   => \$debug_level,
		   'h'         => \$help,
		   'help'      => \$help
) or $help = 1;

if ( $help ) {
	print "\n   TFA REST Services";
	print "\n";
	print "\n   Usage :";
	print "\n";
	print "\n      tfactl rest [-status|-stop|-upgrade|-uninstall|-start [-dir <directory>] [-port <port>] [-user <user>]] [-debug [-level <debug_level 1-6>]]";
	print "\n\n";
	print "        -status    : Prints current status of TFA REST Services\n";
	print "        -start     : Starts TFA REST Services\n";
	print "        -stop      : Stops TFA REST Services\n";
	print "        -upgrade   : Upgrade TFA REST Services to latest\n";
	print "        -uninstall : Removes TFA REST Configuration and Services\n\n";
	print "        -dir       : Location to configure TFA REST Services (Default Oracle Base)\n";
	print "        -port      : Port to run TFA REST Services (Default 9090)\n";
	print "        -user      : User for running TFA REST Services or ORDS (Default Grid Owner)\n";
	#print "        -tool      : Tool Name after Context (Default tfactl)\n\n";
	print "        -debug     : Debug Script\n";
	print "        -level     : Debug Level 1-6 (Default 4 with option -debug)\n";
	print "                     [FATAL - 1, ERROR - 2, WARNING - 3, INFO - 4, DEBUG - 5, TRACE - 6]\n";
	print "\n\n";
	exit 0;
}

if ( $ENV{"TFA_DEBUG"} gt 0 ) {
	$debug = 1;
	$debug_level = $ENV{"TFA_DEBUG"};
}

if ( $debug ) {
	if ( ! defined($debug_level) ) {
		$debug_level = 4;
	} elsif ( $debug_level < 3 || $debug_level > 6 ) {
		my $invalid_level = $debug_level;
		$debug_level = 4;
		warning("Invalid Debug Level $invalid_level. Resetting it to default debug level(4).");
	}
}

if ( $debug_level < 3 ) {
	$debug_level = 3;
}

info("Script Debug : $debug");
info("Debug Level : $debug_level");

if ( ! $tfa_home ) {
	if ( -d "$ENV{TFA_HOME}" ) {  
		$tfa_home = $ENV{TFA_HOME};
	} else {
		my $exepath = abs_path($0);
		chomp($exepath);

		if ( $exepath eq "" && $ENV{HOME} ) {
			#abs_path will be null when cwd is not accessible
			chdir $ENV{HOME};
			$exepath = abs_path($0);

			if ( $exepath eq "" ) {
				$exepath = $0;
			}
		}

		my $basedir = dirname ($exepath);

		if ( $basedir =~ /\/bin/ ) {
			$basedir =~ s/\/bin//;
		}
		$tfa_home = $basedir;
	}
}
info("TFA_HOME : $tfa_home");

if ( $tfa_home =~ /(.*)(\\|\/)$hostname(\\|\/)tfa_home$/ ) {
	$tfa_base = $1;
} else {
	$tfa_base = $tfa_home;
	$tfa_base =~ s/\/tfa_home//;
}
info("TFA_BASE : $tfa_base");

# TFA JLib
my $tfa_jlib = catdir($tfa_home, "jlib");
debug("JLIB Directory : $tfa_jlib");

$crs_home = get_crs_home($tfa_home);
debug("CRS_HOME : $crs_home");

$oracle_base = get_oracle_base($tfa_home);
debug("ORACLE_BASE : $oracle_base");

$rest_prop = catfile($tfa_home, "internal", "rest.properties");
debug("REST Property File : $rest_prop");

debug("-status : $status, -start : $start, -stop : $stop, -upgrade : $upgrade, -uninstall : $uninstall");

# Check Arguments
my $count = $status + $start + $stop + $upgrade + $uninstall;
debug("Count : $count");

if ( $count > 1 ) {
	error("Invalid Parameters. Please use only one option in -status or -start or -stop or -upgrade or -uninstall");
	exit -1;
}

# Set Status if no parameters
if ( $count == 0 ) {
	$status = 1;
}

debug("-status : $status, -start : $start, -stop : $stop, -upgrade : $upgrade, -uninstall : $uninstall");

# Check Arguments for -start
debug("-dir : $ords_base, -port : $ords_port, -user : $ords_user");

if ( $ords_base || $ords_port || $ords_user ) {
	if ( ! $start ) {
		error("Invalid Parameters. Options -dir or -port or -user must be used only with -start");
		exit -1;
	} else {
		# Warn if TFA REST is already configured
		if ( -f "$rest_prop" ) {
			warning("Ignoring options -dir or -port or -user as TFA REST Services is already configured");
		}
	}
}

# Set JAVA_HOME, JAVA and JAR
setJAVAVariables();

if ( -f "$rest_prop") {
	readRESTProperties();
} else {
	setORDSDefaultValues();
}

# TFA REST Status
if ( $status ) {
	my $pid = getTFAORDSProcessID();
	debug("ODRS PID : $pid");

	if ( ! $pid ) {
		logg("\nTFA REST Services is not running\n");		
	} else {
		logg("\nTFA REST Services is running [PID : $pid]\n");
	}
	exit 0;
}

# Upgrade TFA REST Services
if ( $upgrade ) {
	upgradeTRS();
	exit 0;
}

# Uninstall ORDS
if ( $uninstall ) {
	uninstallORDS();
	exit 0;
}

# Stop ORDS
if ( $stop ) {
	stopORDS();
	exit 0;
}

# Configure/Start ORDS
if ( $start ) {
	if ( ! -f $rest_prop || ! -d $ords_dir ) {
		configureORDS();
	}
	startORDS();
	printURL();
}

exit 0;

# Subroutines :

sub configureORDS {

	# Check if Standard Input is available
	if ( ! -t STDIN ) {
		error("Standard Input is not available. Exiting now.");
		exit -1;
	}

	logg("\nConfiguring TFA REST Services using ORDS : ");
	logg("\nThis might take couple of minutes. Please be patient.");

	my $public_key = catfile($tfa_home, "." . $ords_user, $ords_user . "_mykey.rsa.pub");
	debug("Public Key : $public_key");

	if ( ! -f "$public_key" ) {
		addORDSUserToTFA();
	}

	# Verify ORDS User
	if ( ! -f "$public_key" ) {
		error("Failed to add ORDS user $ords_user to TFA Access List. Exiting now.");
		exit -1;
	}

	if ( ! -d "$ords_dir" ) {
		createORDSDirectories();
	}

	$ords_war = catfile($ords_dir, "ords.war");
	if ( ! -f "$ords_war" ) {
		getORDSWar();
	}
	debug("ORDS War : $ords_war");

	# Add Dependecy Jars to ORDS
	addDependencyJars();

	# Create ORDS Properties
	$ords_prop = catfile($ords_dir, "standalone", "standalone.properties");
	if ( ! -f $ords_prop ) {
	    updateStandaloneProperties();
	}

	# Add tfaadmin and tfaclient to ORDS
	if ( ! -f catfile($ords_dir, "credentials") ) {
		addORDSUsers();
		$ords_auth = 1;
	}

	# Update the permission of ORDS Directory
	updateORDSPermissions();
	
	# TFA REST Properties
	if ( ! -f "$rest_prop" ) {
    		createRESTProperties();
	}
}

sub updateORDSPermissions {
	qx($CHOWN -R $ords_user $ords_base);
	qx($CHMOD -R 750 $ords_base);
	qx($CHMOD 600 $ords_prop);
	my $ords_cred = catfile($ords_dir, "credentials");
	qx($CHMOD 600 $ords_cred);
}

sub addDependencyJars {
	logg("\nAdding Dependency Jars to ORDS");

	my $jar;
	my @jars = ();

	# Copy Log4J Libraries to ORDS
	$jar = catfile($tfa_jlib, "log4j-api-2.9.1.jar");
	if ( -f $jar ) {
		push(@jars, $jar);
	}

	$jar = catfile($tfa_jlib, "log4j-core-2.9.1.jar");
	if ( -f $jar ) {
		push(@jars, $jar);
	}

	# Copy Jackson Libraries to ORDS
	$jar = catfile($tfa_jlib, "jackson-core-2.9.6.jar");
	if ( -f $jar ) {
		push(@jars, $jar);
	}

	$jar = catfile($tfa_jlib, "jackson-databind-2.9.8.jar");
	if ( -f $jar ) {
		push(@jars, $jar);
	}

	$jar = catfile($tfa_jlib, "jackson-annotations-2.9.8.jar");
	if ( -f $jar ) {
		push(@jars, $jar);
	}

	# Copy TFA Jar to ORDS
	$jar = catfile($tfa_jlib, "tfarest.jar");
	if ( -f $jar ) {
		push(@jars, $jar);
	} else {
		info("TFA REST Jar : $jar");
		fatal("This TFA version doesn't support TFA REST Services. Exiting now.");
		exit -1;
	}
	
	# Add Jars to ORDS War
	my $plugin = "$java -jar $ords_war plugin";
	my $command;
	
	foreach $jar ( @jars ) {
		info("Adding Jar $jar");
		$command = "$plugin $jar >> /dev/null 2>&1";
		trace("Running command $command");
		qx($command);
	}
}

sub updateTFARESTJar {
	logg("Upgrading TFA Jars");

	my @jars = ();
	my $jar = catfile($tfa_jlib, "tfarest.jar");
	if ( -f $jar ) {
		push(@jars, $jar);
	} else {
		info("TFA REST Jar : $jar");
		fatal("This TFA version doesn't support TFA REST Services. Exiting now.");
		exit -1;
	}

	$jar = catfile($tfa_jlib, "jackson-core-2.9.6.jar");
	if ( -f "$jar" ) {
		push(@jars, $jar);
	}
	
	$jar = catfile($tfa_jlib, "jackson-databind-2.9.8.jar");
	if ( -f "$jar" ) {
		push(@jars, $jar);
	}

	$jar = catfile($tfa_jlib, "jackson-annotations-2.9.8.jar");
	if ( -f "$jar" ) {
		push(@jars, $jar);
	}

	# Add Jars to ORDS War
	my $plugin = "$java -jar $ords_war plugin";
	my $command;
	
	foreach $jar ( @jars ) {
		info("Adding Jar $jar");
		$command = "$plugin $jar >> /dev/null 2>&1";
		trace("Running command $command");
		qx($command);
	}
}

sub setJAVAVariables {
	# Get JAVA HOME
	$java_home = get_java_home($tfa_home);
	info("JAVA HOME : $java_home");

	if ( ! -d $java_home ) {
		$java_home = get_java_home_defer();
		debug("JAVA HOME DEFER : $java_home");
	}

	$java = catfile($java_home, "bin", "java");
	debug("JAVA : $java");

	# GET JDK JAR
	$jar = catfile($crs_home, "jdk", "bin", "jar");
	debug("JAR : $jar");
}

sub vaidateORDSPort {
	my $port = shift;

	if ( $port !~ /^\d+$/ ) {
		error("Port $port should have only numbers. Exiting now.");
		exit -1;
	}
	
	if ( $ords_port < 0 || $ords_port > 65536 ) {
		error("Invalid port $ords_port. Exiting now.");
		exit -1;
	}

	# Check if port is free or not
}

sub validateORDSUser {
	my $user = shift;

	my $ruid = tfactlglobal_getCommandLocation("id");

	qx($ruid -u $user >> /dev/null 2>&1);

	if ( $? != 0 ) {
		error("User $user not exist on this host. Please verify.");
		exit -1;
	}
}

sub validateORDSBase {
	my $directory = shift;

	if ( ! -d "$directory" ) {
		error("Directory $directory not found. Exiting now");
		exit -1;
	}
}

sub setORDSDefaultValues {
	# TODO : Check port before using it
	if ( ! $ords_port ) {
		$ords_port = "9090";
	} else {
		vaidateORDSPort($ords_port);
	}
	debug("ORDS Port : $ords_port");

	# TODO Confirm default ORDS user
	if ( ! $ords_user ) {
		setORDSUser();
	} else {
		validateORDSUser($ords_user);
	}
	info("ORDS USER : $ords_user");

	# ORDS Directories
	if ( ! $ords_base ) {
		if ( -d catdir($oracle_base, "tfa", $hostname)) {
			$ords_base = catdir($oracle_base, "tfa", $hostname);
		} else {
			$ords_base = $tfa_home;
		}
	} else {
		validateORDSBase($ords_base);
	}
	$ords_base = catdir($ords_base, "rest");
	info("ORDS Base : $ords_base");

	$ords_dir = catdir($ords_base, "ords");
	info("ORDS Directory : $ords_dir");

	$ords_war = catfile($ords_dir, "ords.war");
	info("ORDS WAR : $ords_war");

	$ords_log = catdir($ords_dir, "log");
	info("ORDS Log Directory : $ords_log");
}

sub getORDSWar {

	if ( -f catfile($tfa_home, "ext", "orachk", "web", "ords.war") ) {
		$ords_war = catfile($tfa_home, "ext", "orachk", "web", "ords.war");
	} elsif ( -f catfile($crs_home, "ords", "ords.war") ) {
		$ords_war = catfile($crs_home, "ords", "ords.war");
	}

	if ( ! -f "$ords_war" ) {
		my $count = 0;
		{ do {
			print "\nPlease Enter location of ords.war : ";
			my $userinput;
			chomp( $userinput = <STDIN> );
			$userinput = trim($userinput);
			$count++;

			if ( -f "$userinput" ) {
				$ords_war = $userinput;
				last;
			} else {
				if ( $count == 3 ) {
					error("\nMax limit reached. Exiting now.");
					exit -1;
				}
				error("\nInvalid ords.war location $userinput. Please try again.");
			}
		} while ($count < 3); }
	}

	# Copy ords.war to ORDS Directory
	if ( -f "$ords_war" ) {
		trace("Copying $ords_war to $ords_dir");
		copy($ords_war, catfile($ords_dir, "ords.war"));
	}

	$ords_war = catfile($ords_dir, "ords.war");
}

sub createRESTProperties {
	info("Creating TFA REST Properties");
	open (PROP, '>', $rest_prop) or error("Can't create file $rest_prop : $!");
	print PROP "BUILD_VERSION=" . tfactlshare_getTFAVersion($tfa_home) . "\n";
	print PROP "BUILD_ID=" . tfactlshare_getTFABuild($tfa_home) . "\n";
	#print PROP "TOOL=$tool\n";
	print PROP "ORDS_BASE=$ords_base\n";
	print PROP "ORDS_DIR=$ords_dir\n";
	print PROP "ORDS_USER=$ords_user\n";
	print PROP "ORDS_PORT=$ords_port\n";
	print PROP "ORDS_WAR=$ords_war\n";
	print PROP "LOG_DIR=$ords_log\n";

	if ( $ords_auth ) {
		print PROP "ORDS_AUTH=true\n";
	} else {
		print PROP "ORDS_AUTH=false\n";
	}
	close PROP;
}

sub readRESTProperties {
	info("Loading TFA REST Properties");
	open (PROP, '<', $rest_prop) or error("Can't create file $rest_prop : $!");
	
	while (<PROP>) {
		chomp;
		if ( /^BUILD_VERSION=(.*)/ ) {
			$build_version = int($1);
		} elsif ( /^BUILD_ID=(.*)/ ) {
			$build_id = int($1);
		} elsif ( /^ORDS_BASE=(.*)/ ) {
			$ords_base = $1;
		} elsif ( /^ORDS_DIR=(.*)/ ) {
			$ords_dir = $1;
		} elsif ( /^ORDS_USER=(.*)/ ) {
			$ords_user = $1;
		} elsif ( /^ORDS_PORT=(.*)/ ) {
			$ords_port = $1;
		} elsif ( /^ORDS_WAR=(.*)/ ) {
			$ords_war = $1;
		} elsif ( /^LOG_DIR=(.*)/ ) {
			$ords_log = $1;
		} elsif ( /^ORDS_AUTH=(.*)/ ) {
			$ords_auth = 1;
		} elsif ( /^TOOL=(.*)/ ) {
			$tool = $1;
		}
	}
	close(PROP);
}

sub setORDSUser {
	my $oracle_owner = tfactlshare_getConfigValue(catfile($crs_home, "crs", "install", "crsconfig_params"), "ORACLE_OWNER");
	debug("ORACLE OWNER : $oracle_owner");

	if ( $oracle_owner ) {
		$ords_user = $oracle_owner;
	} else {
		$ords_user = "oratfa";
	}
}

sub addORDSUserToTFA {
	my $ruid = tfactlglobal_getCommandLocation("id");
	debug("Location of ID : $ruid");

	my $command = "$ruid -u $ords_user >> /dev/null 2>&1";
	debug("Check User ID Command : $command");
	qx($command);

	if ( $? != 0 ) {
		logg("\nCreating ORDS user $ords_user");

		my $useradd = tfactlglobal_getCommandLocation("useradd");
		my $nologin = tfactlglobal_getCommandLocation("nologin");
		$command = "$useradd -s $nologin $ords_user 2>&1";
		debug("User Add Command : $command");
		qx($command);

		if ( $? != 0 ) {
			error("\nFailed to create ORDS user $ords_user. Please add user and try again");
			exit 1;
		}
	}

	logg("\nAdding ORDS user $ords_user to TFA Access List");
	qx($tfa_home/bin/tfactl access add -user $ords_user -local);
}

sub updateStandaloneProperties {
	info("Creating ORDS Standalone Properties");    
	open (PROP, '>', $ords_prop) or error("Can't create file $ords_prop : $!");
	print PROP "jetty.secure.port=$ords_port\n";
	print PROP "ssl.cert=\n";
	print PROP "ssl.host=$hostname\n";
	print PROP "standalone.context.path=/ords\n";
	print PROP "standalone.doc.root=$ords_dir/standalone/doc_root\n";
	print PROP "standalone.scheme.do.not.prompt=true\n";
	print PROP "standalone.static.context.path=/i\n";
	print PROP "standalone.static.do.not.prompt=true\n";
	close PROP;    
}

sub startORDS {
	my $pid = getTFAORDSProcessID();
	debug("ORDS PID : $pid");

	if ( ! $pid ) {
		my $log = catfile($ords_log, "ords.start.log_$$");
		trace("ORDS Start Log : $log");

		# Unset Environment Variable DISPLAY
		if ($ENV{'DISPLAY'}) {
			delete $ENV{'DISPLAY'};
		}

		my $su = catfile("", "bin", "su");
		my $command = "$su $ords_user -c \"$java -Dconfig.dir=$ords_base -jar $ords_war standalone >> $log 2>&1 &\"";
		trace("ORDS Start Command : $command");
		logg("\nStarting TFA REST Services");
		qx($command);
		sleep(5);

		$pid = getTFAORDSProcessID();
		if ( $pid ) {
			logg("\nSuccessfully started TFA REST Services [PID : $pid]");
		} else {
			logg("\nFailed to start TFA REST Services");
		}
	} else {
		logg("\nTFA REST Services is already running [PID : $pid]");
	}
}

sub createORDSDirectories {
	mkpath($ords_base);
	mkpath($ords_dir);
	mkpath(catdir($ords_dir, "log"));
	mkpath(catdir($ords_dir, "standalone"));
	mkpath(catdir($ords_dir, "standalone", "doc_root"));
}

sub addORDSUsers {
	my @users = ("tfaadmin", "tfarest");
	my $user;
	my $role;

	logg("\nAdding users to ORDS :");

	foreach $user ( @users ) {
		logg();
		if ($user eq "tfaadmin") {
			$role = "TFA_ADMIN";
		} else {
			$role = "TFA_REST";
		}
		debug("ORDS Access User : $user, Access Role : $role");
		my $status = addUserToORDS($user, $role);

		if ( $status != 0 ) {
			logg("Unable to add $user to ORDS. Please try later");
		}
	}
}

sub addUserToORDS {
	my $user = shift;
	my $role = shift;
	trace("addUserToORDS $user $role");
	my $log = catfile($ords_log, "ords.start.log_$$");
	my $cmd = "$java -Dconfig.dir=$ords_base -jar $ords_war user $user $role 2> $log";
	trace("addUserToORDS Command : $cmd");
	my $status = system($cmd);
	return $status;
}

sub getTFAORDSProcessID {
	my $pscommand = "ps -ef | grep $ords_user | grep \"ords.war standalone\" | grep tfa | grep -v \"grep\" | awk '{ print \$2 }'";
	debug("ORDS Stop Command : $pscommand");
	my $pid = qx($pscommand);
	return trim($pid);
}

sub stopORDS {
	my $pid = getTFAORDSProcessID();
	if ( $pid > 0 ) {
		debug("ORDS PID : $pid");
		logg("\nStopping TFA REST Services [PID : $pid]\n");
		my $command = "kill -9 $pid";
		debug("ORDS Kill Command : $command");
		qx($command);
	} else {
		logg("\nTFA REST Services is not running\n");
	}
}

sub upgradeTRS() {
	debug("TFA REST Properties : $rest_prop");
	if ( ! -f $rest_prop ) {
		logg("\nTFA is not configured with REST Services");
		exit -1;
	}

	my $tfa_version = int(tfactlshare_getTFAVersion($tfa_home));
	my $tfa_id = int(tfactlshare_getTFABuild($tfa_home));

	logg("\nCurrent Build Version : $build_version and Build ID : $build_id");
	logg("Installed TFA Version : $tfa_version and Build ID : $tfa_id");

	my $status = 0;

	if ( $tfa_version >= $build_version ) {
		if ( $tfa_version == $build_version ) {
			if ( $tfa_id > $build_id ) {
				$status = 1;
			}
		} else {
			$status = 1;
		}
	}

	# No upgrade
	if ( $status == 0 ) {
		logg("\nAlready running latest version. No need to upgrade TFA REST Services.");
		exit 0;
	}

	# Upgrade TFA REST Services
	if ( $status == 1 ) {
		logg("\nUpgrading TFA REST Services to TFA installed version $tfa_version");

		# Stop Services if running
		my $pid = getTFAORDSProcessID();
		if ( $pid > 0 ) {
			stopORDS();
		}

		# Update TFA Jars
		updateTFARESTJar();

		# Start Services
		startORDS();

		$pid = getTFAORDSProcessID();
		if ( $pid > 0 ) {
			createRESTProperties();
			printURL();
		} else {
			logg("\nFailed to upgrade TFA REST Services\n");
		}
	}
}

sub uninstallORDS {
	debug("TFA REST Properties : $rest_prop");
	if ( ! -f $rest_prop ) {
		logg("TFA is not configured with REST Services");
		exit -1;
	}
	logg("\nUninstalling TFA REST Services on $hostname");

	# Stop ORDS Services
	info("Stopping TFA REST Services");
	stopORDS();

	# Remove TFA REST Properties
	info("Removing TFA REST Properties [$rest_prop]");
	unlink($rest_prop);

	# Remove ORDS Base
	debug("ORDS Base Directory : $ords_base");
	info("Removing ORDS Base [$ords_base]");
	rmtree($ords_base);

	logg("Successfully uninstalled TFA REST Services\n");
}

sub getDomainName() {
	my $domain = hostdomain();
	debug("Domain Name : $domain");
	if ( $domain =~ /\.$/ ) {
		$domain =~ s/\.$//;
	}
	debug("Domain Name after removing . : $domain");
	return $domain;
}

sub printURL {
	my $domain = getDomainName();
	debug("Domain : $domain");
	my $url = "https://" . $hostname . "." . $domain . ":" . $ords_port . "/ords/" . $context . "/print/status";
	debug("URL: $url");
	print "\nURL : $url\n\n";
	#print "\nNOTE : The Standalone Oracle Rest Data Services (ORDS) setup feature utilizes file based user";
	#print "\n       authentication and is provided solely for use in test and development environments.\n\n";
}

sub fatal {
	my $text = shift;
	logg($text, 1);
}

sub error {
	my $text = shift;
	logg($text, 2);
}

sub warning {
	my $text = shift;
	logg($text, 3);
}

sub info {
	my $text = shift;
	logg($text, 4);
}

sub debug {
	my $text = shift;
	if ( $debug ) {
		logg($text, 5);
	}
}

sub trace {
	my $text = shift;
	if ( $debug ) {
		logg($text, 6);
	}
}

sub logg {
	my $text = shift;
	my $level = shift;

	$level = 0 if ( ! $level );

	return if ($level gt $debug_level);

	if ( $level == 1 )    { print localtime(time) . " [FATAL] : $text\n"; }
	elsif ( $level == 2 ) { print localtime(time) . " [ERROR] : $text\n"; }
	elsif ( $level == 3 ) { print localtime(time) . " [ WARN] : $text\n"; }
	elsif ( $level == 4 ) { print localtime(time) . " [ INFO] : $text\n"; }
	elsif ( $level == 5 ) { print localtime(time) . " [DEBUG] : $text\n"; }
	elsif ( $level == 6 ) { print localtime(time) . " [TRACE] : $text\n"; }
	else  { print "$text\n"; }
}

