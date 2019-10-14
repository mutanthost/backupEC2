#!../perl/bin/perl
# 
# $Header: assistants/bin/emdwgrd.pl /main/3 2017/08/24 06:36:05 nagarheg Exp $
#
# emdwgrd.pl
# 
# Copyright (c) 2007, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      emdwgrd.pl
#
#    DESCRIPTION
#     Script that saves and restores dbControl information if the database was 
#     downgraded.  Run this script prior to upgrade to save DB Control 
#     information.  After downgrading the database run this script again to 
#     restore the DB Control information.
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    nagarheg    08/24/17 - Fix for the bug 26303572
#    snimmaku    07/21/15 - Fixing bug 19326439: Honoring ORACLE_HOSTNAME env
#                           variable if set in env.
#    idai        08/29/11 - fix bug 12917191-provide dbname when generating cmd
#                           to start/stop db control on windows for 11.2
#    idai        07/14/10 - fix bug 9902401 - 11.2 em downgrade
#    idai        09/08/08 - fix the message
#    idai        07/25/08 - fix bug 7278304: provide dbname when connecting to
#                           db
#    idai        06/02/08 - fix bug 7131048: remove 10g home version check
#    sadattaw    12/10/07 - forward merging fixes for NT
#    sadattaw    06/25/07 - if env variable not defined, find out which remote
#                           copy is configured
#    sadattaw    06/07/07 - fixing issue in restoreJobs, job is being created
#                           as SYS instead of sysman
#    sadattaw    05/25/07 - adding RAC specific changes
#    rpattabh    05/11/07 - restore: fix dbms_jobs and error case
#    rpattabh    04/25/07 - check invalid objects in sysman schema
#    rpattabh    04/20/07 - script to downgrade EM DB Control
#    rpattabh    10/22/04 - Creation
#

use strict;

use DBI qw(:sql_types);
use POSIX;

use Cwd;		# For GetCwd()
use Getopt::Long;	# For GetOptions
use FileHandle;
use IPC::Open2;
use File::Basename;	# for fileparse
use File::Glob qw(:globally :nocase);
use File::Spec::Functions;         # for catfile
## use Sys::Hostname;
use Net::Domain qw (hostname hostfqdn hostdomain);
use vars qw($OS $NT $S $TEMP $CP $MV $PS $DF $Registry);

use File::Temp qw/ tempfile tempdir /;

my $now = "";
my $oh = "";
my $sid = "";
my $path = "";
my $backuppath = "";
my $logpath = "";
my $sysPass = "";
my $sysmanPass = "";
my $save = "";
my $restore = "";
my $tempTablespace = "";
my $dbcloc = "";
my $SQLLOGF = "";
my $tab			= "  ";
my $EMDPDIR = "EM_DBCTL_DOWNGRADE_DUMPDIR";
my $backupdir = "";
my $EMCTL_STOP_LOG = "";
my $EMCTL_STOP_CMD = "";
my $EMCTL_START_LOG = "";
my $EMCTL_START_CMD = "";
my $EXE="";
my $sysmandir="";
my $nlsLang="American_America.WE8ISO8859P1";
my $copyLog="";
my $slash="/";
my $savestr="";

my $dbname="";
my $serviceAlias="";
my $isCluster="";
my $isOHShared="";
my @nodelist=();
my @sidlist=();
my @ohlist=();
my $RCP = "";
my $REMSH = "";
my $host = "";
my $domain = "";
my $is10g = 0;
my $is112 = 0;
my $isAdm = 0;
my $dbh;

my $DEFAULT_CLASSPATH = $ENV{DEFAULT_CLASSPATH};
my $JAVA_HOME = $ENV{JAVA_HOME};
my $slash= "/";
my $cpSep= ":";


# auto flush stdout
$| = 1;

# get the list of options as a hashed array
my $syntax = "

SYNTAX: emdwgrd {-save|-restore} -path <save_path> -sid <SID> -tempTablespace <name> -cluster
This script saves/restores the Enterprise Manager Database Control information. 
The save/restore featre is meant to be used as a workaround to allow 
downgrades for Enterprise Manager Database Control.  It is required that 
prior to upgrading database and EM, this script is run to save the EM DB Control
information.  Later if the database is to be downgraded, follow
the Upgrade guide documentation to downgrade the database and also run emca to 
restore EM information in the src Oracle Home.  Then run this script with the 
-restore option to restore the rest of the EM DB Control information into the 
source Oracle Home.
-cluster indicates the db is RAC db

ASSUMPTIONS:
    - This script will STOP DB CONTROL
    - This script will CREATE A DIRECTORY for use by datapump export
    - This script will EXPORT SYSMAN schema.
    - It will make a COPY of ORACLE_HOME/sysman and ORACLE_HOME/HOST_SID dirs,
    - During restore it will DROP AND RECREATE SYSMAN schema
    - It will import SYSMAN schema
    - It will restore the files under ORACLE_HOME/sysman and 
      ORACLE_HOME/HOST_SID dirs,

Arguments & Environment:

-save
     This option saves EM DB Control information.  It is to be used prior
     to upgrading the database.

-restore
     This option restores EM DB Control information.  It is to be used in the
     event the database has to be downgraded for any reason.  It is assumed
     that the user first follows the downgrade procedure documented in the 
     Oracle Server Upgrade guide.  After performing the downgrade procedure
     the database catalog would be downgraded and the database will be running
     from the source (10.1 or 10.2) Oracle Home. Also emca restore db would have
     been run to restore EM to the source home.  This script is then run with 
     with the -restore flag to restore the sysman schema and also the DB Control
     configuration files.

ORACLE_HOME 
     This env variable should be set to point to the Oracle home from
     where the database is to be upgraded. This is the source ORACLE_HOME. 
     The path or library paths need to be set appropriately to point to this
     home.  Prior to upgrade first install the 11g Home and run this script 
     to save EM DB Control information.

-sid 
     This is the ORACLE_SID that is being upgraded. 
     
-serviceAlias 
     Alias defined in tnsnames.ora that is used to connect to database.
     Required if sid is different from alias.

-path 
     This is a directory location where EM information is to be saved. 
     Please ensure this directory exists and is empty.

-tempTablespace
     This is the temp tablespace name to use for sysman user.
";


# --------- OS platform-specific (BEGIN) -----------------------------------
#
# NOTE:  The isWinOS call is used later to handle special cases for windows.

sub initGlobals
{
    	my $remcp = "/usr/bin/scp";
    	my $rem_sh = "/usr/bin/ssh";

#	my $remcp = "";
#	if ($ENV{'EM_REMCP'}) {
#    	    $remcp = $ENV{'EM_REMCP'};
#  	}
#        else {
#print "ENV var EM_REMCP not defined, assuming scp is configured. \n";
#    	    $remcp = "/usr/bin/scp";
#  	}

	#### GLOBAL Platform-specific flags for all EM OSs ####
	if($^O =~ /solaris/i){
		$OS = "SOL2";
		$NT = 0;
		$S = '/';
		$TEMP = "/tmp";
		$CP = "/bin/cp -R";
		$MV = "/bin/mv";
		$PS = "/bin/ps";
		$DF = "/bin/df -k";
		$RCP = $remcp." -rp";
		$REMSH = $rem_sh;
	}
	elsif($^O =~ /MSWin32/i){
		$OS = "NT";
		$NT = 1;
		eval 'use Win32::TieRegistry';
		$S = '\\';
		if(exists($ENV{TMP})){
			$TEMP = $ENV{TMP};
		}
		elsif(exists($ENV{TEMP})){
			$TEMP = $ENV{TEMP};
		}
		else{
			$TEMP = $ENV{SYSTEMDRIVE} . "\\temp"; # Bug# 5642432
		}
		## The %SystemDrive% variable seems to come back in TEMP;
		##  substitute in the value
		$TEMP =~ s/%SystemDrive%/$ENV{SYSTEMDRIVE}/i;
		$CP = "xcopy /EIY";
#		$MV = "move";
		$MV = "rename";
		$PS = "ps";
		$EXE=".exe";
		$RCP = $remcp." /EIY";
	}
	elsif($^O =~ /aix/i){
		$NT = 0;
		$S = '/';
		$TEMP = "/tmp";
		$CP = "/bin/cp -R";
		$MV = "/bin/mv";
		$PS = "/bin/ps";
		$DF = "/bin/df -Pk";
		$RCP = $remcp." -rp";
		$REMSH = $rem_sh;
	}
	elsif($^O =~ /linux/i){
		$OS = "LINUX";
		$NT = 0;
		$S = '/';
		$TEMP = "/tmp";
		$CP = "/bin/cp -R";
		$MV = "/bin/mv";
		$PS = "/bin/ps";
		$DF = "/bin/df -k";
		$RCP = $remcp." -rp";
		$REMSH = $rem_sh;
	}
	elsif($^O =~ /hpux/i){
		$NT = 0;
		$S = '/';
		$TEMP = "/tmp";
		$CP = "/bin/cp -R";
		$MV = "/bin/mv";
		$PS = "/bin/ps";
		$DF = "/usr/bin/df -Pk";
		$RCP = $remcp." -rp";
		$REMSH = $rem_sh;
	}
	## Operating system unknown (probably Unix)
	else{
		$OS = "";
		$NT = 0;
		$S = '/';
		$TEMP = "/tmp";
		$CP = "/bin/cp -R";
		$MV = "/bin/mv";
		$PS = "/bin/ps";
		$DF = "/bin/df -k";
		$RCP = $remcp." -rp";
		$REMSH = $rem_sh;
	}
}

sub isWinOS
{
	my $isWin = 0;
	if($^O =~ /MSWin/i)
	{
		$isWin = 1;
	}
	return $isWin;
}

#
# NOTE:  The isWinOS call is used later to handle special cases for windows.
#

# --------- OS platform-specific (END) -----------------------------------

sub printLog
{
    my $line = @_[0];
	print ("$line");
	print (SQLLOG "$line");
}

sub printLogDie
{
    my $line = @_[0];
	print ("$line\n");
	print (SQLLOG "$line\n");
	exit 1;
}

sub createDPDir
{
	$now = localtime time;

	printLog ("$now - Creating directory");
	executeDDL("drop directory $EMDPDIR", 1);

	# connect to db and create a directory for expdp dumpfile
	my $count = runQuery("select count(directory_name) from dba_directories where directory_name = '$EMDPDIR'");

	# create DPDIR if it does not exist
	if ( $count == 0 ) {
		executeDDL("create directory $EMDPDIR as '$backuppath'");
	}
	else {
		printLog (" ... failed\nError: Failed creating directory $EMDPDIR as path: $backuppath\n");
		exit;
	}

	printLog (" ... created\n");

	$count = runQuery("select count(directory_name) from dba_directories where directory_name = '$EMDPDIR'");

	$now = localtime time;

	# if dpdir isnt there exit
	if ( $count <= 0 ) {
		printLog ("Error: Failed creating directory $EMDPDIR as path: $backuppath\n");
		exit;
	}
}

sub validate
{
	$now = localtime time;

	$slash="/";
	if ( isWinOS ) {
		$slash="\\";
	}
	umask(0027);

	$cpSep=":";
	if ( isWinOS ) {
		$cpSep=";";
	}

	my %opt_hash=();
	my $error = GetOptions( \%opt_hash, "save", "restore", "path=s", "tempTablespace=s", "cluster", "shared", "sid=s", "dbunqname=s", "serviceAlias=s");
	if ( $error == 0 || $opt_hash{help}) {
		printLog "$syntax";
		exit;
	}

	if ( isWinOS() ) {
		$backupdir = ".orig";
	}
	else {
		my $sec;
		my $min;
		my $hour;
		my $mday;
		my $mon;
		my $year;
		my $wday;
		my $yday;
		my $isdst;
		($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		$mon=$mon+1;
		$year=$year+1900;
		$backupdir = "_orig_" . ${mon} . "_" . $mday . "_" . $year . "_" . $hour . "_" . $min . "_" . $sec;
	}

	# options
	$save=$opt_hash{"save"};
	$restore=$opt_hash{"restore"};
	$oh=$ENV{"ORACLE_HOME"};
	$sid=$opt_hash{"sid"};

        $serviceAlias=$opt_hash{"serviceAlias"};
        #look for hidden parameter dbunqname 
        if ( $serviceAlias eq '' ) {
           $serviceAlias=$opt_hash{"dbunqname"};
        }
        # Default to SID if none of the above passed
        if ( $serviceAlias eq '' ) {
           $serviceAlias=$sid;
        }

	$path = $opt_hash{"path"};
	$tempTablespace = $opt_hash{"tempTablespace"};
        my $oracleHostName = $ENV{'ORACLE_HOSTNAME'};
        # Check ORACLE_HOSTNAME env variable and use it if it is set.
        if ( $oracleHostName ne '' ) {
            $host = $oracleHostName;
        }
        # Otherwise use OS host name
        else {
            $host = hostname;
        } 
	$domain = hostdomain;

	$isCluster=$opt_hash{"cluster"};
#	$isOHShared=$opt_hash{"shared"};

	# read sys password
#	printLog ("Enter sys password for database $sid?\n");
#system("stty -echo");

#	$sysPass = readline( *STDIN );
#system("stty echo");

$sysPass = promptUserPasswd("Enter sys password for database $sid?\n");
#print "sys passwd : $sysPass \n";

	$sysPass =~ s/^\s+//;
	$sysPass =~ s/\s+$//;
	if ( $sysPass =~ /^$/ ) {
		printLog ("Error: sys password cannot be null\n");
		exit;
	}
        

	if ( isWinOS() ) {
                # flip slashes
                $oh =~ s|\/|\\|g;
                $ENV{"ORACLE_HOME"} = "$oh";
                $path =~ s|\/|\\|g;
                $backuppath =~ s|\/|\\|g;
                $logpath =~ s|\/|\\|g;
                $nlsLang="American_America.WE8MSWIN1252";
        }

	$ENV{"ORACLE_SID"} = "$sid";
        $ENV{"NLS_LANG"} = "$nlsLang";

	if ( ! $oh ||  ! $sid || ! $path || 
		( $restore && ! $tempTablespace ) || 
		( ! $restore && ! $save ) ) {
		printLog ("Error:  Please ensure following argument restrictions are satisfied:\n -> ORACLE_HOME must point to source database home\n -> -sid, -path are required.\n -> Either -save or -restore must be specified.\n -> If restoring -tempTablespace is required.\n -> If sid is different from service alias defined in tnsnames.ora then -serviceAlias is required.\n");
		exit;
	}


        # Get DB_UNIQUE_NAME for all cases as it's used by state dir for EM as well
	my $tblnm = 'v$parameter';
	$dbname = runQuery("select value from $tblnm where name='db_unique_name'");
	printLog( "Database Unique Name : $dbname \n");

	$ENV{"ORACLE_UNQNAME"} = "$dbname";

	if ($save) {
		$savestr="save";
	}
	else {
		$savestr="restore";
	}

	# verify path
	if ( ! -e "$path" || ! -w "$path" ) {
		printLog ("Error: Path does not exist or is not writable.\n");
		exit;
	}

	my @pathfiles = <${path}${slash}*>;
	my $numpaths = @pathfiles;

	$backuppath = $path . $slash . "backup";
	$logpath = $path . $slash . "logs";
	if ( $save && $numpaths > 0 ) {
		printLog ("Error:  $path must be an empty directory.\n");
		exit;
	}

	if ($save) {
		mkdir($backuppath) or die "Error: failed creating $backuppath";
		mkdir($logpath) or die "Error: failed creating $logpath";
	}
	else {
		if ( ! -e $backuppath || !-e $logpath || ! -r $backuppath || ! -w $logpath ) {
		printLog ("Error: $backuppath or $logpath does not exist or is not writable.\n");
			exit;
		}
	}

	# create a sql log file
	$SQLLOGF = "$logpath" . $slash . "sql" . $savestr . ".log";
	open(SQLLOG, ">$SQLLOGF");

	my $sqlplus="$oh" . $slash . "bin" . $slash . "sqlplus" . "${EXE}";
	if ( ! -e "$sqlplus" || ! -x "$sqlplus" ) {
		printLog ("Error:  Invalid Oracle Home, sqlplus was not found\n");
		exit;
	}

	# check db version
	printLog ("$now - Validating DB Connection to $sid");
	my $version = runQuery("select max(version) from dba_registry where comp_id = 'CATALOG'");
	$is10g = 0;
        $is112 = 0;
        if ( $version =~ /11.2/ ) {
          $is112 = 1;
          #print "is112: $is112\n";
        } 
	elsif ( $version =~ /10.1/ ) {
		$is10g = 1;
	}
	elsif ( $version =~ /10.2/ ) { 
		$is10g = 2;
	}
	elsif ( $version =~ /11.1/ ) { 
		$is10g = 2;
	}
	else {
		$is10g = 0;
	}
  

	#if ( $is10g == 0 ) {
	#	printLog (" ... failed\n");
	#	printLog ("Error:  Invalid Database Version $version.  DB Control downgrade procedure only applicable to 10g R1 and 10g R2.\n");
	#	exit;
	#}

	printLog (" ... pass\n");


	if ($isCluster == 1)
	{
	    my $res = '';
	    $res = get_dbinfo($dbname, \@nodelist, \@sidlist, \@ohlist);
	    if (! defined $res)
	    {
		printLogDie("get_dbinfo returned null, possible errs found \n");
	    }
      #printLog("get_dbinfo dbname: $dbname\n");
      #printLog("get_dbinfo nodelist: @nodelist\n");
      #printLog("get_dbinfo sidlist: @sidlist\n");
      #printLog("get_dbinfo ohlist: @ohlist\n");

#TODO need to verify EM DBControl files are present on all nodes before copying from all nodes
	}

	if ($restore) {
		# read sys password
#		printLog ("Enter sysman password for database $sid?\n");
#system("stty -echo");
#		$sysmanPass = readline( *STDIN );
#system("stty echo");

$sysmanPass = promptUserPasswd("Enter sysman password for database $sid?\n");
#print "sysman passwd : $sysmanPass \n";

		$sysmanPass =~ s/^\s+//;
		$sysmanPass =~ s/\s+$//;
		if ($sysmanPass =~ /^$/) {
			printLog ("Error: sysman password cannot be null\n");
			exit;
		}
	}

	if ($save || $isCluster != 1)
	{
	    printLog ("$now - Verify EM DB Control files");
	    # verify EM DBControl files are present
            my @dbcdirs = ();
            if ($is112 == 1) {
              @dbcdirs = <${oh}${slash}${host}*${dbname}>;
            }
            else {
              @dbcdirs = <${oh}${slash}${host}*${sid}>;
            }
	    foreach my $dbcdir (@dbcdirs) {

		    if ( -e "$dbcdir" . $slash . "sysman" . $slash . "config" . $slash . "emd.properties" ) {
			    $dbcloc=$dbcdir;
			    last;
		    }
	    }

	    if ( ! -e "$dbcloc" . $slash . "sysman" . $slash . "config" . $slash . "emd.properties" ) {
		    printLog (" ... cannot find emd.properties ... failed\n");
		    printLog ("Error:  DB Control location not found.\n");
		    exit;
	    }
	    printLog (" ... pass\n");
	} 

	$copyLog="$logpath" . $slash . "copy" . $savestr . ".log";
	$sysmandir = "$oh" . $slash . "sysman";
	if ( isWinOS() ) {
		# flip slashes
		$dbcloc =~ s|\/|\\|g;
	}

	print (SQLLOG "\nfound $dbcloc\n");
	$EMCTL_STOP_LOG = "$logpath" . $slash . "emctl_stop" . $savestr . ".log";
	$EMCTL_STOP_CMD = "$oh" . $slash . "bin" . $slash . "emctl stop dbconsole 2>&1";
	$EMCTL_START_LOG = "$logpath" . $slash . "emctl_start" . $savestr . ".log";
	$EMCTL_START_CMD = "$oh" . $slash . "bin" . $slash . "emctl start dbconsole 2>&1";

	if ( isWinOS() ) {
		$EMCTL_STOP_CMD = "net stop OracleDBConsole" . "$sid 2>&1";
		$EMCTL_START_CMD = "net start OracleDBConsole" . "$sid 2>&1";
	}


	# check tablespace
	if ($restore) {
		printLog ("$now - Validating $tempTablespace tablespace in $sid");
		my $count = runQuery("select count(*) from dba_tablespaces where tablespace_name = upper('$tempTablespace') and contents = 'TEMPORARY'");
		if ( $count != 1 ) {
			printLog (" ... failed\n");
			printLog ("Error:  Temporary tablespace $tempTablespace does not exist.\n");
			exit;
		}
		printLog (" ... pass\n");
	}

	# At this point all validations is done an we know we can connect to the db.
}

sub stopDBCntrl
{
	$now = localtime time;

	printLog ("$now - Stopping DB Control");

	# shutdown db control
	open(EMCTLLOG, ">$EMCTL_STOP_LOG");
	open(EMCTLSTOP, "$EMCTL_STOP_CMD |") or printLogDie "Error: Cannot run $EMCTL_STOP_CMD \n";
	
	my $stopped=0;
	my $failed=0;
	while (<EMCTLSTOP>) {

		my $line="$_";
		if ( $line =~ /stopped/ ) {
			$stopped=1;
			print (SQLLOG "\nstopped present\n");
		}
		if ( $line =~ /Stopped/ ) {
			$stopped=1;
			print (SQLLOG "\nStopped present\n");
		}
		if ( isWinOS() ) {
			if ( $line =~ /not started/ ) {
				$stopped=1;
				print (SQLLOG "\nnot started present\n");
			}
			if ( $line =~ /stopped successfully/ ) {
				$stopped=1;
				print (SQLLOG "\nstopped successfully present\n");
			}
			if ( $line =~ /System error/ ) {
				$failed=1;
				print (SQLLOG "\nSystem error present\n");
			}
		}
		else {
			if ( $line =~ /emctl.pid does not exist/ ) {
				$stopped=1;
				print (SQLLOG "\nemctl.pid present\n");
			}
		}
		if ( $line =~ /failed/ ) {
			$failed=1;
			print (SQLLOG "\nfailed present\n");
		}
		print (EMCTLLOG "$_\n");
	}

	close(EMCTLSTOP);
	close(EMCTLLOG);

	$now = localtime time;
	if ( $failed || ! $stopped ) {
		printLog (" ... failed\n");
		printLog ("Error: Could not stop DB Control, see log file $EMCTL_STOP_LOG.\n");
		exit;
	}

	printLog (" ... stopped\n");
}
	
sub stopDBCntrlOnCluster
{
	$now = localtime time;

	printLog ("$now - Stopping DB Control on all Nodes \n");

my $nodename;
my $i=0;
my $nodelist_str = "";
my $isLastNode = 0;
my $remCmdFile = "$TEMP"."/racdwgrd_dbctl.sh";
foreach $nodename (@nodelist) {
my $nodeoh = $ohlist[$i];
my $nodesid = $sidlist[$i];

if ($i != 0)
{
    $nodelist_str = $nodelist_str.", ";
}
$nodelist_str = "$nodelist_str" ."$nodename";

##  print "Executing stop dbcontrol on node $nodename , nodesid $nodesid , nodeoh $nodeoh \n";
$i++;

if ($i == scalar(@nodelist))
{
   $isLastNode = 1;
}
$remCmdFile = create_startstop_dbctlfile($nodename, $nodesid, $nodeoh, "stop", $isLastNode);
}

printLog( "Please Execute '$remCmdFile' on $nodelist_str. \nPress yes to continue when the operations are successful. \n");
	# read sys password
	printLog ("Continue (yes/no) ?\n");
	my $cnt = readline( *STDIN );
	$cnt =~ s/^\s+//;
	$cnt =~ s/\s+$//;
	while (!( lc($cnt) eq "y" || lc($cnt) eq "yes" || lc($cnt) eq "n" || lc($cnt) eq "no")) {
		printLog ("Please execute command file on all nodes and press y / yes to continue ( or n / no to quit ).\n");
		printLog ("Continue (yes/no) ?\n");
	 	$cnt = readline( *STDIN );
		$cnt =~ s/^\s+//;
		$cnt =~ s/\s+$//;
	}
	if ( lc($cnt) eq "n" || lc($cnt) eq "no") {
    exit;
  }

#TODO need to collect status from all nodes to report a combined status

	# shutdown db control
#	open(EMCTLLOG, ">$EMCTL_STOP_LOG");
#	open(EMCTLSTOP, "$EMCTL_STOP_CMD |") or printLogDie "Error: Cannot run $EMCTL_STOP_CMD \n";
#	
#	my $stopped=0;
#	my $failed=0;
#	while (<EMCTLSTOP>) {
#
#		my $line="$_";
#		if ( $line =~ /stopped/ ) {
#			$stopped=1;
#			print (SQLLOG "\nstopped present\n");
#		}
#		if ( $line =~ /Stopped/ ) {
#			$stopped=1;
#			print (SQLLOG "\nStopped present\n");
#		}
#		if ( isWinOS() ) {
#			if ( $line =~ /not started/ ) {
#				$stopped=1;
#				print (SQLLOG "\nnot started present\n");
#			}
#			if ( $line =~ /stopped successfully/ ) {
#				$stopped=1;
#				print (SQLLOG "\nstopped successfully present\n");
#			}
#			if ( $line =~ /System error/ ) {
#				$failed=1;
#				print (SQLLOG "\nSystem error present\n");
#			}
#		}
#		else {
#			if ( $line =~ /emctl.pid does not exist/ ) {
#				$stopped=1;
#				print (SQLLOG "\nemctl.pid present\n");
#			}
#		}
#		if ( $line =~ /failed/ ) {
#			$failed=1;
#			print (SQLLOG "\nfailed present\n");
#		}
#		print (EMCTLLOG "$_\n");
#	}
#
#	close(EMCTLSTOP);
#	close(EMCTLLOG);

#	$now = localtime time;
#	if ( $failed || ! $stopped ) {
#		printLog (" ... failed\n");
#		printLog ("Error: Could not stop DB Control, see log file $EMCTL_STOP_LOG.\n");
#		exit;
#	}

	printLog (" ... stopped\n");
}
	
sub startDBCntrl
{
	$now = localtime time;

	printLog ("$now - Starting DB Control");

	# shutdown db control
	open(EMCTLLOG, ">$EMCTL_START_LOG");
	open(EMCTLSTART, "$EMCTL_START_CMD |") or printLogDie "Error: Cannot run $EMCTL_START_CMD \n";

	my $started=0;
	my $failed=0;
	while (<EMCTLSTART>) {
		my $line="$_";
		if ( isWinOS ) {
			if ( $line =~ /started successfully/ ) {
				$started=1;
				print (SQLLOG "\nstarted successfully present\n");
			}
		}
		else {
			if ( $line =~ /started./ ) {
				$started=1;
				print (SQLLOG "\nstarted successfully present\n");
			}
		}
		if ( $line =~ /failed/ ) {
			$failed=1;
			print (SQLLOG "\nfailed present\n");
		}
		print (EMCTLLOG "$_\n");
	}

	close(EMCTLSTART);
	close(EMCTLLOG);

	$now = localtime time;
	if ( $failed || ! $started ) {
		printLog (" ... failed\n");
		printLog ("Error: Could not start DB Control, see log file $EMCTL_START_LOG.\n");
		exit;
	}

	printLog (" ... started\n");
}
	
sub startDBCntrlOnCluster
{
	$now = localtime time;

	printLog ("$now - Starting DB Control On All nodes \n");

	my $nodename;
	my $nodelist_str = "";
	my $i=0;
   	my $isLastNode = 0;
	my $remCmdFile = "$TEMP"."/racdwgrd_dbctl.sh";
	foreach $nodename (@nodelist) {
	   my $nodeoh = $ohlist[$i];
	   my $nodesid = $sidlist[$i];
	   if ($i != 0)
	   {
    	       $nodelist_str = $nodelist_str.", ";
	   }
	   $nodelist_str = "$nodelist_str" ."$nodename";

##  print "Executing start dbcontrol on node $nodename , nodesid $nodesid , nodeoh $nodeoh \n";
	   $i++;

	   if ($i == scalar(@nodelist))
	   {
   	      $isLastNode = 1;
	   }

	   $remCmdFile = create_startstop_dbctlfile($nodename, $nodesid, $nodeoh, "start", $isLastNode);
       }

printLog( "Please Execute '$remCmdFile' on $nodelist_str. \nPress yes to continue when the operations are successful. \n");
        printLog ("Continue (yes/y) ?\n");
        my $cnt = readline( *STDIN );
        $cnt =~ s/^\s+//;
        $cnt =~ s/\s+$//;
        while (!( lc($cnt) eq "y" || lc($cnt) eq "yes") ){
                printLog ("Please execute command file on all nodes and press y / yes to continue.\n");
                printLog ("Continue (yes/y) ?\n");
                $cnt = readline( *STDIN );
        	$cnt =~ s/^\s+//;
	        $cnt =~ s/\s+$//;
        }

#TODO need to collect status from all nodes to report a combined status

	# startup db control
#	open(EMCTLLOG, ">$EMCTL_START_LOG");
#	open(EMCTLSTART, "$EMCTL_START_CMD |") or printLogDie "Error: Cannot run $EMCTL_START_CMD \n";

#	my $started=0;
#	my $failed=0;
#	while (<EMCTLSTART>) {
#		my $line="$_";
#		if ( isWinOS ) {
#			if ( $line =~ /started successfully/ ) {
#				$started=1;
#				print (SQLLOG "\nstarted successfully present\n");
#			}
#		}
#		else {
#			if ( $line =~ /started./ ) {
#				$started=1;
#				print (SQLLOG "\nstarted successfully present\n");
#			}
#		}
#		if ( $line =~ /failed/ ) {
#			$failed=1;
#			print (SQLLOG "\nfailed present\n");
#		}
#		print (EMCTLLOG "$_\n");
#	}
#	close(EMCTLSTART);
#	close(EMCTLLOG);

#	$now = localtime time;
#	if ( $failed || ! $started ) {
#		printLog (" ... failed\n");
#		printLog ("Error: Could not start DB Control, see log file $EMCTL_START_LOG.\n");
#		exit;
#	}

	printLog (" ... started\n");
}
	
sub saveDBControlInfo 
{
	$now = localtime time;

	printLog ("$now - Saving DB Control files \n");

	# copy db control directories to $backuppath
	if ($isCluster != 1)
	{
	    copyFile($dbcloc, $backuppath) or printLogDie " ... failed\nError: Failed copying DB Control dir $dbcloc to $backuppath\n";
	    copyFile("$sysmandir", $backuppath) or printLogDie " ... failed\nError: Failed copying DB Control dir $sysmandir to $backuppath\n";
	}
	else
	{
	    my $nodename;
	    my $i=0;
	    foreach $nodename (@nodelist) {
	       	printLog( "Executing save directories from node $nodename\n");
	       	my $nodeoh = $ohlist[$i];
	       	my $nodesid = $sidlist[$i];
#print "nodesid $nodesid , nodeoh $nodeoh , dbname $dbname\n";
	       	$i++;

	       	my $dbcdir = '';
	       	my $hostsiddir = '';
                if ( $is112 == 1 ) {
                         $hostsiddir = "$nodename" . "_" . "$dbname";
                         #print "hostsiddir 1 $hostsiddir\n"
                } 
		elsif ( $is10g == 1 ) {
	       	   $hostsiddir = "$nodename" . ".$domain" . "_" . "$nodesid";
                  #print "hostsiddir 2 $hostsiddir\n"
		}
		else {
	       	   $hostsiddir = "$nodename" . "_" . "$nodesid";
                  #print "hostsiddir 3 $hostsiddir\n"
		}
	       	$dbcdir = "$nodeoh" . "$slash" . "$hostsiddir";
                #print "dbcdir $dbcdir\n";

	       	my $bkuppath = "$backuppath" . "$slash" . "$nodename";
 #print " dbcdir $dbcdir , bkuppath $bkuppath \n";

		if (! -e $bkuppath)
        	{
# print "make directory for host $nodename in backup path \n";
	           my $mkhostdir = "mkdir ". "$bkuppath";
           	   if (system($mkhostdir) != 0)
             	   { printLogDie "failed to make directory for host $nodename\n"; }
        	}

#TODO verify EM DBControl files are present   this needs to be done on remote nodes ?

	my $bkup_siddir = $bkuppath;
	if (isWinOS() && ($isOHShared != 1)) {
	   $bkup_siddir = $bkuppath . "$slash". $hostsiddir;
	}
	my $bkup_sysman = $bkuppath;
	if (isWinOS() && ($isOHShared != 1)) {
	   $bkup_sysman = $bkuppath . "$slash". "sysman";
	}

	# copy db control directories to $backuppath
	if ($isOHShared)
	{
#print "save -- shared  src $dbcdir, dest $bkup_siddir \n";
        	copyFile( $dbcdir, $bkup_siddir) or printLogDie(" ... failed\nError: Failed copying DB Control dir $dbcdir to $bkup_siddir for node $nodename\n");

#print "save -- shared  src $sysmandir, dest $bkup_sysman \n";
        	copyFile("$sysmandir", $bkup_sysman) or printLogDie(" ... failed\nError: Failed copying DB Control dir $sysmandir to $bkup_sysman for node $nodename\n");
	}
	else
	{
#print "save -- non shared  nodename $nodename , src $dbcdir, dest $bkup_siddir \n";
        	rcopyFileFrom($nodename, $dbcdir, $bkup_siddir) or printLogDie(" ... failed\nError: Failed copying DB Control dir $dbcdir to $bkup_siddir for node $nodename\n");

#print "save -- non shared  nodename $nodename , src $sysmandir, dest $bkup_sysman \n";
        	rcopyFileFrom($nodename, "$sysmandir", $bkup_sysman) or printLogDie(" ... failed\nError: Failed copying DB Control dir $sysmandir to $bkup_sysman for node $nodename\n");
	}

	    }
        }

	printLog (" ... saved\n");

	recompileObjects();

	printLog ("$now - Exporting sysman schema for $sid");

	# create and expdp dumpfile for sysman schema
	my $expcmd="$oh" . $slash . "bin" . $slash . "expdp SCHEMAS=SYSMAN DIRECTORY=$EMDPDIR DUMPFILE=export.dmp LOGFILE=export.log 2>&1";

	my $explog="$logpath" . $slash . "export_dmp.log";
	my $explog2="$backuppath" . $slash . "export.log";

	my $pid = open2(*Reader, *Writer, "$expcmd" );
	Writer->autoflush(); # default here, actually
	print Writer "sys/${sysPass} as sysdba\n";
	Writer->autoflush(); # default here, actually

	print (SQLLOG "$expcmd\n");

	my $exppass=0;

	open (FILE, ">$explog");
	while (my $line = <Reader>) {

		# trim space on both ends
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;

		if ($line =~ /successfully completed/) {
			$exppass=1;
		}
	}
	close(FILE);

	$now = localtime time;
	if ($exppass != 1) {
		printLog (" ... failed\n");
		printLogDie "Error: export of sysman schema failed see log $explog2\n";
	}

	printLog (" ... exported\n");

	printLog "$now - DB Control was saved successfully.\n";
}

sub createSysmanUser
{
	# THIS SYSMAN CREATE definition needs to be kept in sync with EMCP.
	executeDDL("CREATE USER SYSMAN PROFILE DEFAULT IDENTIFIED BY $sysmanPass DEFAULT TABLESPACE SYSAUX TEMPORARY TABLESPACE $tempTablespace QUOTA UNLIMITED ON SYSAUX ACCOUNT UNLOCK");
	executeDDL("GRANT ALTER USER TO SYSMAN");
	executeDDL("GRANT CREATE ANY TABLE TO SYSMAN");
	executeDDL("GRANT CREATE USER TO SYSMAN");
	executeDDL("GRANT DROP USER TO SYSMAN");
	executeDDL("GRANT SELECT ANY DICTIONARY TO SYSMAN");
	executeDDL("GRANT UNLIMITED TABLESPACE TO SYSMAN");
	executeDDL("GRANT EXECUTE ON SYS.DBMS_AQ TO SYSMAN");
	executeDDL("GRANT EXECUTE ON SYS.DBMS_AQ_BQVIEW TO SYSMAN");
	executeDDL("GRANT EXECUTE ON SYS.DBMS_CRYPTO TO SYSMAN");
	executeDDL("GRANT EXECUTE ON SYS.DBMS_JOB TO SYSMAN");
	executeDDL("GRANT EXECUTE ON SYS.DBMS_LOB TO SYSMAN WITH GRANT OPTION");
	executeDDL("GRANT EXECUTE ON SYS.DBMS_LOCK TO SYSMAN");
	executeDDL("GRANT EXECUTE ON SYS.DBMS_REDEFINITION TO SYSMAN");
	executeDDL("GRANT EXECUTE ON SYS.DBMS_REGISTRY TO SYSMAN");
	executeDDL("GRANT SELECT ON SYS.USER_TAB_COLUMNS TO SYSMAN");
	executeDDL("GRANT DBA TO SYSMAN");
	executeDDL("GRANT MGMT_USER TO SYSMAN WITH ADMIN OPTION");
}

sub createMgmtUser
{
    # THIS MGMT_USER ROLE create definition needs to be kept in sync with SYSMAN
  executeDDL("CREATE ROLE MGMT_USER");
  executeDDL("GRANT CREATE SESSION TO MGMT_USER");
  executeDDL("GRANT CREATE TRIGGER TO MGMT_USER");
  executeDDL("CREATE USER MGMT_VIEW IDENTIFIED BY $sysmanPass DEFAULT TABLESPACE SYSAUX TEMPORARY TABLESPACE $tempTablespace");
}

sub recompileObjects {
	$now = localtime time;
	printLog ("$now - Recompiling invalid objects");

	executeScript("@?" . $slash . "rdbms" . $slash . "admin" . $slash . "utlrp.sql");

	# drop the sysman user and recreate.
	my $count = runQuery("select count(object_name) from dba_objects where owner = 'SYSMAN' and status <> 'VALID'");
	if ( "$count" > 0 ) {
		printLog (" ... failed\n");
		printLog ("Error: $count objects remain invalid after running utlrp.");
		exit;
	}
	printLog (" ... recompiled\n");
}

sub restoreJobs {
	$now = localtime time;
	printLog ("$now - restoring dbms_jobs");

	# DB Control sets up one dbms_job that is not restored on an import.
	executeDDL("BEGIN emd_maintenance.submit_em_dbms_jobs; END;", 0, "sysman", $sysmanPass);

	# drop the sysman user and recreate.
	my $count = runQuery("select count(what) from dba_jobs where what like 'EMD_MAINTENANCE.EXECUTE_EM_DBMS_JOB_PROCS%'");
	if ( "$count" <= 0 ) {
		printLog (" ... failed\n");
		printLog ("Error: Could not restore EMD_MAINTENANCE.EXECUTE_EM_DBMS_JOB_PROCS please execute emd_maintenance.submit_em_dbms_jobs as sysman user.");
		exit;
	}
	printLog (" ... restored\n");
}

sub restoreRegistry {
	$now = localtime time;
	printLog ("$now - restoring dbms_registry");

	# DB Control sets up one dbms_job that is not restored on an import.
	executeDDL("DECLARE
  l_comp_short_name VARCHAR2(256);
  l_comp_name VARCHAR2(256);
BEGIN
  EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA=SYSMAN';

  -- Mark the dbms_registry for EM component as upgrading.
  l_comp_short_name := 'EM';
  l_comp_name       := 'Oracle Enterprise Manager';
  EXECUTE IMMEDIATE 'BEGIN dbms_registry.loading(:1, :2); END;' 
        USING l_comp_short_name, l_comp_name;

  -- Mark the dbms_registry for EM component as loaded
  l_comp_name := 'EM';
  EXECUTE IMMEDIATE 'BEGIN dbms_registry.loaded(:1); dbms_registry.valid(:2); END;' 
        USING l_comp_name, l_comp_name;
  -- Reset the session back to SYS
  EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA=SYS';
END;", 0, "sys", $sysPass);

	# Check if registry information got populated
	my $count = runQuery("select count(*) from dba_registry where comp_name = 'Oracle Enterprise Manager'");
	if ( "$count" != 1 ) {
		printLog (" ... failed\n");
		printLog ("Error: Could not restore DBA_REGISTRY please manually restore registry information using dbms_registry package prior to upgrading EM.");
		exit;
	}
	printLog (" ... restored\n");
}

sub restoreDBControlInfo 
{
	$now = localtime time;
	printLog ("$now - dropping sysman schema");

	# drop the sysman user and recreate.
	my $count = runQuery("select count(username) from dba_users where username = 'SYSMAN'");
	if ( "$count" > 0 ) {
		executeDDL("drop user sysman cascade");
	}

	$count = runQuery("select count(username) from dba_users where username = 'SYSMAN'");
	if ( "$count" != 0 ) {
		printLog (" ... failed\n");
		printLog ("Error: Could not drop sysman user see ${SQLLOGF}");
		exit;
	}
	printLog (" ... dropped\n");

	printLog ("$now - Recreating sysman user");

	# recreate sysman user
	createSysmanUser();

	$count = runQuery("select count(username) from dba_users where username = 'SYSMAN'");
	if ( "$count" != 1 ) {
		printLog (" ... failed\n");
		printLog ("Error: Could not recreate sysman user see ${SQLLOGF}");
		exit;
	}
	printLog (" ... recreated\n");

  printLog ("$now - Recreating mgmt user role");
  # recreate mgmt_user role and their priviliges
  createMgmtUser();
  $count = runQuery("select count(username) from dba_users where username = 'MGMT_VIEW'");
  if ( "$count" != 1 ) {
    printLog (" ... failed\n");
    printLog ("Error: Could not recreate mgmt_view user see ${SQLLOGF}");
    exit;
  }
  $count = runQuery("select count(role) from dba_roles where role = 'MGMT_USER'");
  if ( "$count" != 1 ) {
    printLog (" ... failed\n");
    printLog ("Error: Could not recreate mgmt_user role  see ${SQLLOGF}");
    exit;
  }
  printLog (" ... recreated\n");

	printLog ("$now - Restoring DB Control files \n");

	# move db control directories out of the way
	my $rendir = $dbcloc;
	if ( isWinOS ) {
		$rendir = "host_$sid";
	}

#TODO need to rename files on remote nodes

	if ($isCluster == 1)
	{
	# restore db control directories from $backuppath

	 my $nodename;
        my $i=0;
        foreach $nodename (@nodelist) {
             printLog( "Executing Restore directories to node $nodename\n");
	     my $nodeoh = $ohlist[$i];
	     my $nodesid = $sidlist[$i];
             $i++;

	     my $bkuppath = "$backuppath" . "$slash" . "$nodename";
# print "nodesid $nodesid , nodeoh $nodeoh bkuppath $bkuppath \n";

             my $dbcdir = '';
             if ($is112 ==1 ) {
                       $dbcdir = "$nodename"."_"."$dbname";
             }
	     elsif ($is10g == 1) {
                 $dbcdir = "$nodename".".$domain". "_"."$nodesid";
	     }
	     else
	     {
                 $dbcdir = "$nodename"."_"."$nodesid";
	     }

             my $srcdir = $bkuppath."$slash"."$dbcdir";
             if ( -d $srcdir ) {
                my $destdir = "$nodeoh" . "$slash" . "$dbcdir";

print " restore -- src $srcdir, dest $destdir \n";
		if ($isOHShared)
		{
		    if (isWinOS()) {
                       copyFile($srcdir, $nodeoh) or print " ... failed\nError: Failed restoring DB Control dir $srcdir\n";
		    } else {
                    copyFile($srcdir, $destdir) or print " ... failed\nError: Failed restoring DB Control dir $srcdir\n";
		    }
		} else {
                    rcopyFileTo($nodename, $srcdir, $destdir) or print " ... failed\nError: Failed restoring DB Control dir $srcdir\n";
		}
             }

             $dbcdir = "sysman";
             $srcdir= $bkuppath."$slash"."$dbcdir";
             if ( -d $srcdir ) {
                my $destdir = "$nodeoh" . "$slash" . "$dbcdir";

 print " restore -- src $srcdir, dest $destdir \n";
		if ($isOHShared)
                {
		    if (isWinOS()) {
                       copyFile($srcdir, $nodeoh) or print " ... failed\nError: Failed restoring DB Control dir $srcdir\n";
		    } else {
                   copyFile( $srcdir, $destdir) or print " ... failed\nError: Failed restoring DB Control dir $srcdir\n";
		    }
                } else {
                    rcopyFileTo($nodename, $srcdir, $destdir) or print " ... failed\nError: Failed restoring DB Control dir $srcdir\n";
		}
             }
        }

	}
	else
	{
	    renameFile($dbcloc, "$rendir${backupdir}" ) or 
		printLogDie " ... failed\nError: Failed renaming DB Control dir $dbcloc to ${dbcloc}${backupdir}\n";
	    renameFile("$sysmandir", "$sysmandir${backupdir}" ) or 
		printLogDie " ... failed\nError: Failed renaming DB Control dir $sysmandir to $sysmandir${backupdir}\n";


# restore db control directories from $backuppath

	my @dbcdirs = <$backuppath${slash}*>;
        foreach my $dbcdir (@dbcdirs) {

                if ( -d $dbcdir ) {
                        copyFile($dbcdir, $oh) or printLogDie " ... failed\nError: Failed restoring DB Control dir $dbcdir\n";
                }
        }
        }

	printLog (" ... restored\n");

	printLog ("$now - Importing sysman schema");

	# import the expdp dumpfile for sysman schema
	my $impcmd="$oh" . $slash . "bin" . $slash . "impdp SCHEMAS=SYSMAN DIRECTORY=$EMDPDIR DUMPFILE=export.dmp LOGFILE=import.log 2>&1";

	my $implog="$logpath" . $slash . "import_dmp.log";
	my $implog2="$backuppath" . $slash . "import.log";

	my $pid = open2(*Reader, *Writer, "$impcmd" );
	Writer->autoflush(); # default here, actually
	print Writer "sys/${sysPass} as sysdba\n";
	Writer->autoflush(); # default here, actually

	print (SQLLOG "$impcmd\n");

	my $imppass=0;

	open (FILE, ">$implog");
	while (my $line = <Reader>) {

		# trim space on both ends
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;

		if ($line =~ /completed with 1 error/) {
			$imppass=1;
		}
	}
	close(FILE);

	$now = localtime time;
	if ($imppass != 1) {
		printLogDie " ... failed\nError: import of sysman schema failed see log $implog2\n";
	}

	printLog (" ... imported\n");

	recompileObjects();

### may not need this, as import job seems to restore
 	restoreJobs();

    restoreRegistry();

	printLog "$now - DB Control was restored successfully.\n";

}

sub dropDPDir
{
	$now = localtime time;
	executeDDL("drop directory $EMDPDIR", 1);
	printLog "$now - Dump directory was dropped successfully.\n";
}

sub runQuery {

	$now = localtime time;
    
    # 0 - normal, 2 - sysdba, 4 - sysoper
    my $sql = @_[0];
    # my $connectionMode = "ORA_SYSDBA"; # 2 
    my $connectionMode = 2; 
    $dbh = DBI->connect("dbi:Oracle:$serviceAlias", 
			   #'host=' . $host . 
			   #';port=' . $port . 
			   #';sid=' . $SID, 
			   #';service=' . $serviceName,
			   "sys",
			   $sysPass,
			   { ora_session_mode => $connectionMode }
			   );
    printLogDie "$now - Connect failed \n" unless $dbh;
    $dbh->{RowCacheSize} = 100;

    print (SQLLOG "\nSQL> $sql\n");

    my $sth = $dbh->prepare($sql,{ora_check_sql => 0 });
    $sth->execute or printLogDie "\nError: Sql failed: $sql\n";

    my $returned="";
    while (my @row = $sth->fetchrow_array)
    {
		$returned = $row[0];
		print (SQLLOG "RESULT> $row[0]\n");
    }

    $sth->finish;

    $dbh->disconnect or die (filterOraError("disconnect failed", $DBI::err));

    return $returned;
}

sub executeDDL {

	$now = localtime time;
    
    # 0 - normal, 2 - sysdba, 4 - sysoper
    my $sql = @_[0];
    my $ignoreError = @_[1];
    my $user = @_[2];
    my $pass = @_[3];

	if ( $ignoreError == 1 )
	{
		$ignoreError = 0;
	}

	if (!$user) {
		$user="sys";
	}

	if (!$pass) {
		$pass=$sysPass;
	}

    # my $connectionMode = "ORA_SYSDBA"; # 2 
    my $connectionMode = 0;
    if (($user eq "sys") || ($user eq "SYS")) {
        $connectionMode = 2;
    }

    if (($user eq "sys") || ($user eq "SYS")) {
#        print (" CONNECT AS $user ,   $ignoreError \n");
         $dbh = DBI->connect("dbi:Oracle:$serviceAlias", 
                           #'host=' . $host .
                           #';port=' . $port .
                           #';sid=' . $SID,
                           #';service=' . $serviceName,
                           $user,
                           $pass,
                           { ora_session_mode => $connectionMode,
                             PrintError => $ignoreError }
                           );
    }
    else {
#	 print (" CONNECT AS $user ,   $ignoreError \n");

        $dbh = DBI->connect("dbi:Oracle:$serviceAlias", 
			   #'host=' . $host . 
			   #';port=' . $port . 
			   #';sid=' . $SID, 
			   #';service=' . $serviceName,
			   $user,
			   $pass,
			   { PrintError => $ignoreError }
			   );
    }

    printLogDie "$now - Connect failed \n" unless $dbh;

    print (SQLLOG "\nSQL> $sql\n");

    my $sth = $dbh->prepare($sql,{ora_check_sql => 0 });
    $sth->execute or "$ignoreError" == 0 or printLogDie "\nError: Sql failed: $sql\n";

    $dbh->disconnect or die (filterOraError("disconnect failed", $DBI::err));
    return 1;
}

sub executeScript {

	$now = localtime time;

    my $script = @_[0];

    my $pid = open2(*Reader, *Writer, "$oh" . $slash . "bin" . $slash . "sqlplus -S /nolog 2>&1" );
    Writer->autoflush(); # default here, actually
    print Writer "set head off echo off trims on feedback off\n";
    print Writer "connect sys/${sysPass} as sysdba\n";
    print Writer "${script};\n";
    print Writer "exit;\n";
    Writer->autoflush(); # default here, actually

    print (SQLLOG "\nSQL> ${script}\n");
    my $count=0;
	my $line="";

    while ($line = <Reader>)
    {
		#print $line;
		# trim space on both ends
		$line =~ s/^\s+//;
		$line =~ s/\s+$//;

		print (SQLLOG "$line\n");

		if ($line =~ /ORA-[0-9]+/) {
			$count = $count + 1;
			# last;
		}
		elsif ($line =~ /Error/) {
			$count = $count + 1;
			# last;
		}
		#last;
    }
    close(FILE);

    if ($count != 1) {
		print (SQLLOG "Number of issues found = $count\n");
		return 0;
    }

    return 1;
}

# Copy a file from source to destination location
# copyFile(sourceFile, destFile)
sub copyFile
{
	my ($sourceFile, $destFile) = @_;

	if ( isWinOS() ) {
		# get the dest dir
		my $destDir=basename($sourceFile);
		$destFile = "$destFile" . ${slash} . "$destDir";
	}

	print (SQLLOG "\n$CP $sourceFile $destFile 2>&1 >> $copyLog\n");
	return system ("$CP $sourceFile $destFile 2>&1 >> $copyLog") == 0;
}

# renameFile(sourceFile, destFile)
sub renameFile
{
	my ($sourceFile, $destFile) = @_;

print "in renameFile : $MV $sourceFile $destFile \n";

	print (SQLLOG "\n$MV $sourceFile $destFile 2>&1 >> $copyLog\n");
	my $ret = rename($sourceFile, $destFile);
	if ( isWinOS() ) {
		# on windows rename file can fail if file is in use
		# in this case ignore this error and move on as we overwrite the
		# files when copying 
		return 1;
	}
	return $ret;
}

#remote Copy a file from source on another host to destination location on current host
# rcopyFileFrom(nodename, sourceFile, destFile)
sub rcopyFileTo
{
        my ($node, $sourceFile, $destFile, $inputopt) = @_;

        if ( isWinOS() ) {
                # get the dest dir
           $destFile = "\\\\" . "$node" . "\\" ."$destFile"; 
	# replace : with $
	   $destFile =~  s/:/\$/g;

  # print "rcopyfileTo: node $node, src $sourceFile, dest $destFile \n";

	# if we are copying a single file and it doesnot exist at dest location
	# xcopy will wait for user input, we can use copy instead 
	if (defined $inputopt && ($inputopt eq "F")){
           print (SQLLOG "\nCOPY $sourceFile $destFile 2>&1 >> $copyLog\n");
           return system ("COPY $sourceFile $destFile 2>&1 >> $copyLog") == 0;
	} else {
           print (SQLLOG "\n$RCP $sourceFile $destFile 2>&1 >> $copyLog\n");
           return system ("$RCP $sourceFile $destFile 2>&1 >> $copyLog") == 0;
        }

	}
	else {

           $destFile = "$node" . ":" . "$destFile" ;

  # print "rcopyfileTo: node $node, src $sourceFile, dest $destFile \n";

        print (SQLLOG "\n$RCP $sourceFile $destFile 2>&1 >> $copyLog\n");
        return system ("$RCP $sourceFile $destFile 2>&1 >> $copyLog") == 0;
	}
}
#remote Copy a file from source on another host to destination location on current host # rcopyFileFrom(nodename, sourceFile, destFile)
sub rcopyFileFrom
{
        my ($node, $sourceFile, $destFile, $inputopt) = @_;

        if ( isWinOS() ) {
                # get the dest dir
#                my $destDir=basename($sourceFile);
#                $destFile = "$destFile" . ${slash} . "$destDir";
           $sourceFile = "\\\\". "$node" . "\\" . "$sourceFile" ;
	   $sourceFile =~  s/:/\$/g;

#  print "rcopyfileFrom: node $node, src $sourceFile, dest $destFile \n";

	# if we are copying a single file and it doesnot exist at dest location
	# xcopy will wait for user input, we can use copy instead 
	if (defined $inputopt && ($inputopt eq "F")){
           print (SQLLOG "\nCOPY $sourceFile $destFile 2>&1 >> $copyLog\n");
           return system ("COPY $sourceFile $destFile 2>&1 >> $copyLog") == 0;
	} else {
           print (SQLLOG "\n$RCP $sourceFile $destFile 2>&1 >> $copyLog\n");
           return system ("$RCP $sourceFile $destFile 2>&1 >> $copyLog") == 0;
	}

        }
        else {

        $sourceFile = "$node" . ":" . "$sourceFile" ;

#  print "rcopyfileFrom: node $node, src $sourceFile, dest $destFile \n";

        print (SQLLOG "\n$RCP $sourceFile $destFile 2>&1 >> $copyLog\n");
        return system ("$RCP $sourceFile $destFile 2>&1 >> $copyLog") == 0;
        }
}

# Usage: get_dbinfo($dbname)
# Calls: srvctl config
sub get_dbinfo
{
     my ($dbName, $nlist, $slist, $hlist) = @_;

     my $cmd = '';
     my $result = '';
     
     if ($is112 == 1) {
        $cmd = "$ENV{ORACLE_HOME}/bin/srvctl config database -d " . $dbName . " -S 1";
     } else {
        $cmd = "$ENV{ORACLE_HOME}/bin/srvctl config database -d ".$dbName ;
     }

     #print "Srvctl command: $cmd\n";
     #EMD_PERL_DEBUG( "get_dbinfo : srvctl command $cmd  \n");
     
     my @lines = ();
     chomp ($result = `$cmd`);
     if ($? != 0) {
          printLog( "Failed to run the srvctl command in get_dbinfo $? \n");
          #EMD_PERL_DEBUG( "get_dbinfo : failed to run srvctl command status $?  \n");
          return undef;
     }
   my $err= has_errcode($result);
     if ($err != 0)
     {
        #EMD_PERL_DEBUG( "get_dbinfo : error codes found in the srvctl result : $result \n");
        return undef;
     }

#     print "in get_dbinfo, result : $result.\n ------- \n";
     @lines = split("\n", $result);

     my $line = '';
     my $lineno = 0;
     #printLog("is112: $is112\n");
     
     my $home = '';
     if ($is112 == 1) {
       foreach $line (@lines)
       {
          #printLog("line: $line\n");
          
          my @tokens = split("} ",$line);
          
          my $token = '';
          foreach $token (@tokens) {
          
            #printLog("token: $token\n");
            my @attrs = split("={",$token);
            #printLog("attrs $attrs[0] $attrs[1]\n");
            
            if ($attrs[0] eq "db_type") {
            
              if ($attrs[1] eq "ADMIN_MANAGED") {
                $isAdm = 1;
              }
              #printLog("isAdm $isAdm\n");
              
            } elsif ($attrs[0] eq "enabled_nodes") {
            
              my @nodels = split("}",$attrs[1]);
              my @nodes = split(",",$nodels[0]);
              foreach my $node (@nodes) {
                #printLog("node $node\n");
                 push (@{$nlist}, $node);
                 push (@{$hlist}, $home); 
              }
              
            } elsif ($attrs[0] eq "oh") {
            
              $home = $attrs[1];
              #printLog("home $home\n");
              
            }
                      
          }
                    
          
       }#foreach line
        if ($isAdm == 0) {
     
                my $cmd_crshome = $ENV{ORACLE_HOME} . $slash . "srvm" . $slash . "admin" . $slash . "getcrshome" ;
                
                #printLog("crshome command: $cmd_crshome\n");
  
                my $result_crshome = '';        
                chomp ($result_crshome = `$cmd_crshome`);
                
                my $cmd_nls = $result_crshome . $slash . "bin" . $slash . "olsnodes";
                
                #printLog("node ls cammamd: $cmd_nls\n");
                
                my $result_nls = '';
                chomp ($result_nls = `$cmd_nls`);
                
                my @lines_nls = split("\n", $result_nls);
                
                my $node = '';
                                
               foreach $node (@lines_nls)
               {
                  #printLog("node $node\n");
                  push (@{$nlist}, $node);                  
                  push (@{$hlist}, $home); 
               }
        }#if isAdmin
     }#if 112
     else {
       foreach $line (@lines)
       {
                 
          my @tokens = split(" ",$line);
          push (@{$nlist}, $tokens[0]);
          push (@{$slist}, $tokens[1]);
          push (@{$hlist}, $tokens[2]);
       }
     }
     

     return $result;
}

# Purpose: find following error codes in input string:
#          "PRKP"
#          "PRKH"
#          "PRKO"
#          "CRS"
#          "ORA"
sub has_errcode
{
    my $in_str = $_[0];

#    print "error code detector: $in_str\n";

    if ($in_str =~ /PRKP-/ || $in_str =~ /PRKH-/ || $in_str =~ /PRKO-/ || $in_str =~ /CRS-/ || $in_str =~ /ORA-/ || $in_str =~ /SEVERE-/) {
        return(-1);  # error mesg
    }
    else {
        return(0);
    }

}

sub create_startstop_dbctlfile
{
    my ($nodename, $nodesid, $nodeoh, $verb, $isLastNode) = @_;

## print "$nodename, $nodesid, $nodeoh, $verb, $isLastNode\n";

    my $cmd = '';
    my $result = '';

    my $local_oh=$ENV{"ORACLE_HOME"};

    if ( isWinOS() ) {
       $cmd = "net ". "$verb " . "OracleDBConsole";
    }
    else {
       $cmd = "$nodeoh"."/bin/emctl ". "$verb " . "dbconsole";
    }

    # create a file for each node which contains commands to execute on all that node
    my $shr_file = "";
    if (isWinOS()) {
	$shr_file = "$nodename". "_" . "racdwgrd_dbctl.bat";
    }
    else {
	$shr_file = "$nodename". "_" . "racdwgrd_dbctl.sh";
    }

    $shr_file = catfile($local_oh, $shr_file);
#  print "cmd : $cmd , file $shr_file \n ";

#    sysopen( H_SHRFILE, ">$shr_file", 0755);
    sysopen( H_SHRFILE, "$shr_file", O_CREAT|O_RDWR|O_TRUNC, 0755);

    if ( isWinOS ) {
	if ($is112 == 0) {
     		$cmd = $cmd . $nodesid;
	}
	else {
     		$cmd = $cmd . $dbname;
	}
     print H_SHRFILE
	"$cmd \n";
    }
    else {
     print H_SHRFILE
        "#!/bin/sh \n";

  # dynmically set environment variables
  my $envvar = "ORACLE_HOME";
  printf H_SHRFILE "export $envvar=$nodeoh \n";
  if ($is112 == 0) {
    $envvar = "ORACLE_SID";
    printf H_SHRFILE "export $envvar=$nodesid \n";
  }
  else {
    $envvar = "ORACLE_UNQNAME";
    printf H_SHRFILE "export $envvar=$dbname \n";
  }

  my $emctlname = catfile($nodeoh, "bin", "emctl");
  print H_SHRFILE
        "$emctlname $verb dbconsole\n";
  }

#if we are stopping dbcontrol during restore step, rename the host_sid and sysman directories with .orig extension on the remote nodes
  if ($restore && ($verb eq "stop"))
  {
    my $dbcdir = '';
    my $hostsiddir = '';
    if ( $is112 == 1 ) {
       $hostsiddir = "$nodename" . "_" . "$dbname";
       $dbcdir = "$nodeoh" . "$slash" . "$hostsiddir";
    }
    elsif ( $is10g == 1 ) {
       $hostsiddir = "$nodename" . ".$domain" . "_" . "$nodesid";
       $dbcdir = "$nodeoh" . "$slash" . "$hostsiddir";
    }
    else {
       $hostsiddir = "$nodename" . "_" . "$nodesid";
       $dbcdir = "$nodeoh" . "$slash" . "$hostsiddir" ;
    }

    my $rendir = "";
    if (isWinOS()) {
       $rendir = "$hostsiddir" . "$backupdir";
    }
    else {
       $rendir = "$dbcdir" . "$backupdir";
    }

    print H_SHRFILE
        "\n echo \"Renaming host_sid and sysman directories with .orig ext. Restore will overwrite them.\" \n";
    print H_SHRFILE
        "$MV $dbcdir $rendir\n";

    my $sman = "sysman";
    if (isWinOS()) {
       $rendir = "$sman" . "$backupdir";
    }
    else {
       $rendir = "$sysmandir" . "$backupdir";
    }

    if ($isOHShared)
    {
	if ($isLastNode)
	{
        $dbcdir = "$sysmandir";
#        $rendir = "$sysmandir" . "$backupdir";
        print H_SHRFILE
           "$MV $dbcdir $rendir\n";
	}
    }
    else
    {
        $dbcdir = "$sysmandir";
#        $rendir = "$sysmandir" . "$backupdir";
        print H_SHRFILE
           "$MV $dbcdir $rendir\n";
    }
  }

  close(H_SHRFILE);

## put the file in the tmp dir of remote node
##  my $remote_file = catfile($nodeoh, "racdwgrd_dbctl.sh");

  my $remote_file = "";
  if (isWinOS()){
     $remote_file = catfile($TEMP, "racdwgrd_dbctl.bat");
  } else {
     $remote_file = catfile($TEMP, "racdwgrd_dbctl.sh");
  }

  rcopyFileTo($nodename, $shr_file, $remote_file, "F") or printLogDie(" ... failed\nError: Failed remote copying of DB Control command file $shr_file to $remote_file for node $nodename\n");

  # doesnot seem to be configured  my $remsh = "/usr/bin/rsh -n";
# do not execute, ask user to execute on all nodes to take care of all platforms
#  my $remsh = "/usr/bin/ssh";
#  my $perlexe = "/usr/bin/perl ";
#  print "Executing emctl on node $nodename\n";
#  my @program = ($remsh, $nodename, $perlexe, $remote_file, " >> /tmp/tstrcmd.out");
#  print "pgm @program \n \n";
#  system(@program);
#print "pgm executed \n -------------- \n";

   return $remote_file;
}

sub setRemoteCopyOption
{
	my ( $ssh_cmd, $rsh_cmd )    = ( "/usr/bin/ssh", "/usr/bin/rsh" );
# first check if the environment variable is set
	my $remcp = "";
	if ($ENV{'EM_REMCP'}) {
    	    $RCP = $ENV{'EM_REMCP'};
	    if ( $RCP !~ /-rp/ ) {
                $RCP = $RCP . " -rp";
            }
	    if ( $RCP =~ /rcp/ ) {
                $REMSH = $rsh_cmd;
            }
	    $REMSH = $ssh_cmd;
  	}
        else {
	  if ( isWinOS() ) {
	    $RCP = "xcopy /EIY";
  	  } 
 	  else {
print "ENV var EM_REMCP not defined, check if rcp or scp is configured. \n";

	    my ( $scp_cmd, $rcp_cmd )    = ( "/usr/bin/scp -rp", "/usr/bin/rcp -rp" );

        my $dirPath = $TEMP;
	my $suffix   = ".tmp";
        my $template = "checkSharedOHXXXX";

        my ( $fh, $tmpfile ) = tempfile( $template, DIR => $dirPath, SUFFIX => $suffix, UNLINK => 1 );
        close $fh;

	
	my $foundRemoteCopy = 0;
	if ( -e $rsh_cmd ) {
	   $RCP = $rcp_cmd;
	   $REMSH = $rsh_cmd;
	   
           my $ res = testRemoteCopy($tmpfile);
	   if ($res != 1){
  print " ... failed\nError: Failed remote copy using rcp, rsh not configured.\n";
	   }
	   else
	   {
		$foundRemoteCopy = 1;
	   }
	}

	if ( -e $rsh_cmd  && $foundRemoteCopy == 0) {
	   $RCP = $scp_cmd;
	   $REMSH = $ssh_cmd;
	   
           testRemoteCopy($tmpfile) == 1 or print " ... failed\nError: Failed remote copy using scp, ssh not configured.\n";
	}
	}
  	}

print "RCP = $RCP, REMSH = $REMSH \n";

$isOHShared = checkIfOHShared($oh, \@nodelist);

print "shared = $isOHShared \n";

}

sub testRemoteCopy
{

   my ($tmpfile) = @_;

#print " in testRemoteCopy, tmp file $tmpfile, rcp $RCP \n";

   my $nodename;
   my $i = 0;
   my $copySuccessful = 1;
   foreach $nodename (@nodelist) {

	my $nodeoh = $ohlist[$i];
	my $nodesid = $sidlist[$i];
#print "node $nodename , nodesid $nodesid , nodeoh $nodeoh \n";

#print " rcopy to $nodename, src $tmpfile, dest $tmpfile \n";

        rcopyFileTo($nodename, $tmpfile, $tmpfile) or $copySuccessful = 0;

	if ( $copySuccessful == 0)
	{
	     print " ... failed\nError: Failed restoring DB Control dir $tmpfile\n";
	     last;
	}
	    $i++;
	}
    return $copySuccessful;
}


sub checkIfOHShared {
        my $shared = 0;
        my ( $ohPath, $hostList ) = @_;

#print "in isOHShared $ohPath \n";

        my @hosts = @{$hostList};
        return $shared if @hosts <= 0;

#print " in isOHShared nodelist @hosts \n";

        # return if OH or hostlist is invalid 
        return $shared
          if ( ( !defined($ohPath) || $ohPath eq "" )
                || ( !defined($hostList) || $hostList eq "" ) );

        # return if path not directory
        return $shared if !( -d $ohPath && -w $ohPath );

	my $dirPath = $ohPath;
        my $suffix   = ".tmp";
        my $template = "checkSharedOHXXXX";

        my ( $fh, $tmpfile ) = tempfile( $template, DIR => $dirPath, SUFFIX => $suffix, UNLINK => 1 );
        close $fh;

#print " tmp file $tmpfile\n";

        my $count = 0;
	$shared = 1;
        foreach my $host (@hosts) {
#  print( "check file on host $host :  \n" );
                my ( $status, $errCode ) = checkFileOnHost( $host, $tmpfile );
#  print( "check file on host $host, status = $status  errCode=$errCode \n " );

                #if error occured check for next host
                if ($errCode != 0) {
                    $shared = 0;
		    last;
		}
	
		$count++;
		$shared &= $status;
#  print " shared $shared \n";

        }
#  print " shared $shared count $count \n";
    return $shared;
}

sub isWinOS
{
        my $isWin = 0;
        if($^O =~ /MSWin/i)
        {
                $isWin = 1;
        }
        return $isWin;
}

sub executeCommand {
        my ( $cmd, $input )  = @_;
        my ( $err, $output ) = ( "", "" );

        if ( open2( *README, *WRITEME, $cmd ) ) {
                print WRITEME $input if defined $input;
                $output = <README>;
                if ( !close(README) ) {
                        if ( $output ne "" ) {
                                $err    = "\"${cmd}\" returned: \"" . $output . "\"";
                                $output = "";
                        }
                        else {
                                $err = "bad \"$cmd\": $! $?";
                        }
                }
                close(WRITEME);
        }
        else {
                # open error
                $err = "cannot execute \"$cmd\": $!";
        }
        return ( $err, $output );
}

sub checkFileOnHost {

     my ($node, $filenm) = @_;

     my $exists = 0;
     my $remFile = '';
     if (isWinOS()){
	# get remote file name
           $remFile = "\\\\" . "$node" . "\\" ."$filenm";
# replace : with $
           $remFile =~  s/:/\$/g;
	if ( -e $remFile) {
	   $exists = 1;
	}
     }
     else
     {
	my ( $visible, $notvisible ) = ( "filevisible",  "notfilevisible" );
        my ( $err,     $output )     = ( "","" );
        my ( $ssh_cmd, $rsh_cmd )    = ( "/usr/bin/ssh", "/usr/bin/rsh" );
        my $commArg = " $node -n /bin/sh  -c \'\" if [ -f $filenm ] ; then echo $visible; else echo $notvisible;  fi \"\' ";

        my $retVal = undef;
        my $cmd;

        if ( -e $rsh_cmd ) {
                # assume success op
                $retVal =1 ;
                $cmd = "$rsh_cmd ";
                $cmd .= $commArg;
                ( $err, $output ) = executeCommand($cmd);
                $retVal = -1   if $err ne "" or ( $output ne "" && !( $output =~ /\s*($visible|$notvisible)\s*/ ) );
                print( " retVal = $retVal  output = $output err=$err \n" );
        }

        if ( (!defined($retVal) || $retVal == -1) && -e $ssh_cmd ) {
                # assume success op
                $retVal =1 ;
                $cmd = "$ssh_cmd -o FallBackToRsh=no -o PasswordAuthentication=no -o NumberOfPasswordPrompts=0  -o StrictHostKeyChecking=yes ";
                $cmd .= $commArg;
                ( $err, $output ) = executeCommand($cmd);
                $retVal = -1 if $err ne "" or ( $output ne "" && !( $output =~ /\s*($visible|$notvisible)\s*/ ) );
                print( " retVal = $retVal  output = $output err=$err \n" );
        }
	# trim space on both ends
        $output =~ s/^\s+//;
        $output =~ s/\s+$//;

        my ( $fexist, $errOcc ) = ( 0, 0 );

        #if retVal still -1 means error occured during command execution .
        if ( $retVal == -1 || !defined($retVal)) {
                $fexist = 0;
                $errOcc = 1;
        }
        elsif ( $output =~ /^$visible$/ ) {
                $fexist = 1;
        }
        elsif ( $output =~ /^$notvisible$/ ) {
                $fexist = 0;
        }
        print ( "checkFileOnHost: fexist = $fexist  errOcc = $errOcc  " );

        return ( $fexist, $errOcc );

     }
}




sub getDBConsoleClassPath
{
#Downgrade is only supported for DBControl currently
  my $consoleMode = "DBCONSOLE";

  my $emLibDir  = "$oh".$slash."sysman".$slash."jlib";
  my $emJarFile = "emCORE.jar";
  my $emagJarFile = "emagentSDK.jar";

  # adding oracle_home/jlib/ojpse.jar from DB11 bug 5491469
  # keeping oracle_home/encryption/jlib/ojpse.jar for backward compatibility


  my $consoleClassPath = "$DEFAULT_CLASSPATH".
                 "$cpSep$oh".$slash."jdbc".$slash."lib".$slash."classes12.jar".
                 "$cpSep$oh".$slash."jlib".$slash."uix2.jar".
                 "$cpSep$oh".$slash."jlib".$slash."share.jar".
                 "$cpSep$oh".$slash."jlib".$slash."ojmisc.jar".
                 "$cpSep$oh".$slash."lib".$slash."xmlparserv2.jar".
                 "$cpSep$emLibDir".$slash."log4j-core.jar".
                 "$cpSep$emLibDir".$slash."ojpse_2_1_5.jar".
                 "$cpSep$emLibDir".$slash."$emJarFile".
                 "$cpSep$emLibDir".$slash."$emagJarFile";

  return $consoleClassPath;
}

######################################################################
# WINReadPasswd()
# prompt: The message to be displayed before the password is read
# return: user input
# Comment: Do not call this routine directly, instead call promptUserPasswd().
# This routine is only for Windows systems only.
######################################################################
sub WINReadPasswd
{
  my ($prompt) = @_;
  my $passwd = "";
  my $finalPwd = "";
  my $lineCnt = 0; 

  my $CLASSPATH = getDBConsoleClassPath();
## print "classpath = $CLASSPATH \n ";

  eval
  {
    my $cmd =  "$JAVA_HOME".$slash."bin".$slash."java -classpath $CLASSPATH " .
                 "oracle.sysman.util.winUtil.WinUtil -readPasswd " .
                 "\"$prompt\" -invertFileHandles |";

##     print "cmd = $cmd \n";

    open GETPWD, "$JAVA_HOME".$slash."bin".$slash."java -classpath $CLASSPATH " .
                 "oracle.sysman.util.winUtil.WinUtil -readPasswd " .
                 "\"$prompt\" -invertFileHandles |";
    while(<GETPWD>)
    {
      $passwd .= $_;
      $lineCnt++;
    };
  };
  if($passwd eq "")
  {
    die("Failed executing java!\n");
  }

  unless(($lineCnt == 1) && (($finalPwd) = $passwd =~ m/Password='(.*)'\n$/o))
  {
    die("Failed parsing password returned from Java.\n$passwd\n");
  }
  return($finalPwd);
}

######################################################################
# promptUserPasswd()
# prompt for user/passwd input
# return: user input
# Comment: This is how it should look once we get Win32::Console in the
#          standard perl distribution.
#            my $STDIN = new Win32::Console(STD_INPUT_HANDLE);
#            defined($STDIN) or die "Failed to create Win32::Console object!\n";
#            my $origMode = $STDIN->Mode();
#            $STDIN->Mode(&ENABLE_LINE_INPUT | &ENABLE_PROCESSED_INPUT);
#            $password=<STDIN>;
#            $STDIN->Mode($origMode);
#          ---
#          Alternatively, if we get ReadKey() (also Win32 specific):
#            ReadMode('noecho');
#            $password = ReadLine(0);
#            ReadMode('normal');
######################################################################

sub promptUserPasswd
{
   my ($prompt) = @_;
   my $password;
   if(isWinOS())
   {
     $password = WINReadPasswd($prompt);
   }
   else
   {
     print $prompt;
     system "stty -echo";
     $password=<STDIN>;
     system "stty echo";
     print "\n";
   }
   chomp ($password);
   return $password;
}





# ======================================
# MAIN
# ======================================

# OS Specific inits
initGlobals();

# validate input args
validate();

#set remotecopy to scp or rcp based on which one is configured
setRemoteCopyOption();

# --------------------------------------------
# All Validations Complete
# --------------------------------------------

# create the data pump directory if it is not already there.
createDPDir();

# stop EM DB Control
if ($isCluster == 1) {
   stopDBCntrlOnCluster();
}
else {
   stopDBCntrl();
}

if ( $save )
{
	saveDBControlInfo;
}
elsif ( $restore ) {
	restoreDBControlInfo;
}

# stop EM DB Control
if ($isCluster == 1) {
   startDBCntrlOnCluster();
}
else {
   startDBCntrl();
}

# drop the data pump directory 
dropDPDir();

close (SQLLOG);


