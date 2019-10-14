# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/tfadiagnostics.pl /main/32 2018/08/15 16:55:52 bburton Exp $
#
# tfadiagnostics.pl
# 
# Copyright (c) 2014, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfadiagnostics.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    cnagur      03/13/18 - CPU Usage by all TFA Threads
#    cnagur      05/26/17 - Use zip from CRS_HOME if not found
#    cnagur      04/05/17 - Collect umask details - Bug 25834138 
#    cnagur      12/29/16 - JStack on SunOS - Bug 25304237
#    cnagur      12/02/16 - Fix for Bug 25187624
#    cnagur      07/27/16 - Fix for Bug 24353086
#    cnagur      07/08/16 - Changes to collect olsnodes
#    cnagur      06/10/16 - Fix for Bug 22856578
#    cnagur      05/27/16 - XbranchMerge cnagur_tfa_121260_cell_issues_txn from
#                           st_tfa_12.1.2.6
#    arupadhy    05/17/16 - repository creation for windows and linux
#    arupadhy    04/27/16 - Placed strict import below begin block as it
#                           considers C as bareword
#    cnagur      04/25/16 - Fix for Bug 23119471
#    cnagur      04/15/16 - Fix for Bug 21977668
#    cnagur      04/14/16 - Removed getCommandLocation
#    cnagur      03/02/16 - Fix for Bug 22864375
#    amchaura    02/25/16 - Upgrade BDB version to 6.4.25
#    cnagur      12/28/15 - Fix for Bug 22472749
#    arupadhy    11/02/15 - Changes related to support on windows
#    cnagur      10/29/15 - Fix for Bug 21127068 and 22084086
#    cnagur      10/08/15 - List files opened by TFA - Bug 21966353
#    cnagur      09/14/15 - Fix for Bug 21789336
#    cnagur      08/20/15 - Fix for Bug 21625074
#    cnagur      08/17/15 - Fix for Bug 20380506
#    cnagur      07/10/15 - Fix for Bug 21418316
#    cnagur      03/12/15 - Cloud Support
#    cnagur      12/05/14 - Collect BDB Stats - Bug 20159409
#    cnagur      11/18/14 - Creation
#
##################################################################

use English;
use File::Basename;
use File::Spec::Functions;
use File::Copy;
use Cwd;
use POSIX;
use File::Find;
use POSIX qw(strftime);
use File::Path;

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME);
  push @INC, dirname($PROGRAM_NAME).'/..';
  push @INC, dirname($PROGRAM_NAME).'/../common';
  push @INC, dirname($PROGRAM_NAME).'/../modules';
  push @INC, dirname($PROGRAM_NAME).'/../common/exceptions';
  $ENV{LC_ALL} = C;
}

use strict;
use Getopt::Long qw(:config no_auto_abbrev);
use tfactlglobal;
use tfactlshare;
use osutils;

# Local variables
my $hostname = tolower_host();
my $tfahome = "";
my $crshome = "";
my $javahome = "";
my $basedir = "";
my $tfabase = "";
my $repository = "";
my $oraclebase = "";
my $logdir = "";
my $invdir = "";
my $bdbdir = "";
my $tfa_setup = "";
my $tfa_config = "";
my $installtype = "TYPICAL";
my $nodetype = "TYPICAL";
my $nozip = 0;
my $help = 0;
my $tag = "";
my $notag = 0;
my $collection = "";
my $homedir = getHomeDirectory();
my $PERL;

GetOptions('crshome=s'    => \$crshome,
           'tfahome=s'    => \$tfahome,
           'javahome=s'    => \$javahome,
           'repository=s' => \$repository,
           'tag=s'        => \$tag,
           'nozip'        => \$nozip,
           'notag'        => \$notag,
           'help'         => \$help);

if ( $help ) {
	print "\n  Usage : tfadiagnostics.pl [-tag <tagname>] [-nozip]\n\n";	
	exit 0;
}

if (($repository ne "")  && !(-d $repository)) {
	mkpath($repository);
}

if ( ! $tfahome ) {
	if ( $0 =~ /^\// ) { # It's the full path
    		$basedir = dirname ($0);
  	}
	$basedir = dirname ($0);

	if ($basedir =~ /^\./) {
		my $p = getcwd();
		$basedir =~ s/\./$p/;
	}
	if ($basedir =~ /(\\|\/)bin(\\|\/)scripts/) {
		$basedir =~ s/(\\|\/)bin(\\|\/)scripts//;
	}
	$tfahome = $basedir;
}

if ( $tfahome =~ /(.*)(\\|\/)$hostname(\\|\/)tfa_home$/ ) {
	$tfabase = $1;
}

if ( ! $tag && ! $notag ) {
	my $dateNtime = strftime "%Y%m%d_%H%M%S", localtime;
	$tag = "tfadiagnostics_".$dateNtime;
	$tag = trim ($tag);
}

my $tfaosutils = catfile($tfahome, "bin", "tfaosutils.pl");
my $internaldir = catdir( $tfahome, "internal" );
$tfa_setup = catfile ($tfahome, "tfa_setup.txt");
$tfa_config = catfile ($internaldir, "config.properties");

if ( isTFAOnCloud($tfahome) ) {
	if ( -f catfile($homedir, ".tfa", "tfa_setup.txt") ) {
		$tfa_setup = catfile($homedir, ".tfa", "tfa_setup.txt");
		$tfa_config = catfile($homedir, ".tfa", "config.properties");
		$tfabase = getTFABase($tfa_setup);
		$installtype = "CLOUD";
	}
}

open ( SETUP, "$tfa_setup") || print "File tfa_setup.ext $tfa_setup not found...\n";

while (<SETUP>) {
	if ( /^CRS_HOME=(.*)/ ) {
		$crshome = $1;
	}
	if ( /^ORACLE_BASE=(.*)/ ) {
		$oraclebase = $1;
	}
	if ( /^INSTALL_TYPE=(.*)/ ) {
                $installtype = $1;
        }
	if ( /NODE_TYPE=(.*)/ ) {
		$nodetype = $1;
	}
	if ( /^JAVA_HOME=(.*)/ ) {
            $javahome = $1;
    }
    if ( /^PERL=(.*)/ ) {
            $PERL = $1;
    }
}
close (SETUP);

if ( ! -f $PERL) {
	$PERL = catfile("","usr","bin","perl");
}

if ( ! -d "$oraclebase" ) {
	my $crsconfig_params = catfile($crshome, "crs", "install", "crsconfig_params");

	if ( -f "$crsconfig_params" ) {
		open ( PARAM, "$crsconfig_params") || print "File crsconfig_params not found...\n";

		while (<PARAM>) {
			if ( /^ORACLE_BASE=(.*)/ ) {
				$oraclebase = $1;
			}
		}
		close (PARAM);
	}	
}

# Set Repository if not set
if ( $installtype eq "GI" ) {
	$repository = catfile ($oraclebase, "tfa", "repository") if ( ! $repository );
	$invdir = catfile ($oraclebase, "tfa", $hostname, "output", "inventory");
	$bdbdir = catfile ($oraclebase, "tfa", $hostname, "database", "BERKELEY_JE_DB");
	$logdir = catfile ($oraclebase, "tfa", $hostname, "log");
} elsif ( $installtype eq "CLOUD" ) {
	$repository = catfile ($tfabase, "repository") if ( ! $repository );
	$invdir = catfile ($tfabase, "output", "inventory");
	$bdbdir = catfile ($tfabase, "database", "BERKELEY_JE_DB");
	$logdir = catfile ($tfabase, "log");
} else {
	$repository = catfile ($tfabase, "repository") if ( ! $repository );
	$invdir = catfile ($tfahome, "output", "inventory");
	$bdbdir = catfile ($tfahome, "database", "BERKELEY_JE_DB");
	$logdir = catfile ($tfahome, "log");
}

if ( -d "$repository" ) {
	$collection = catfile ($repository, $tag);
} else {
	if ( $IS_WINDOWS ) {
		my $TMP_PATH = "C:\\TMP";
		if ( ! -d $TMP_PATH ) {
			mkpath($TMP_PATH);
		}
		$collection = catfile ($TMP_PATH, $tag);
	} else {
		$collection = catfile ("/tmp", $tag);
	}
}

mkdir ($collection);
chdir ($collection);

open (LOG, '>', $hostname . "_diagnostic.log");
open (*STDERR, '>', $hostname . "_diagnostic.err");

print LOG "DATE : " . localtime(time) . "\n";
print LOG "OS : $osname\n";
print LOG "TFA_BASE : $tfabase\n";
print LOG "TFA_HOME : $tfahome\n";
print LOG "TFA INVENTORY : $invdir\n";
print LOG "BDB DIRECTORY : $bdbdir\n";
print LOG "INSTALL TYPE : $installtype\n";
print LOG "NODE TYPE : $nodetype\n";
print LOG "CRS_HOME : $crshome\n";
print LOG "ORACLE_BASE : $oraclebase\n";
print LOG "JAVA_HOME : $javahome\n";
print LOG "Repository : $repository\n";
print LOG "Tag : $tag\n";
print LOG "Collection : $collection\n";

print LOG "\n\n";

# Env Details
if ( ! $IS_WINDOWS ) {
	runCommand( $ENV, $hostname . "_env_details");
}

# TFA Process Details
print localtime(time) . " : Collecting TFA Process details...\n";
print LOG localtime(time) . " : Collecting TFA Process details...\n";

my $pscommand_tfa;
my $pscommand_java;

if ( $IS_WINDOWS ) {
	$pscommand_tfa = "Wmic process where \"Name like '\%JAVA\%' and commandline like '\%TFAMain\%'\" get caption, name, commandline, ProcessId";
	$pscommand_java = "Wmic process where \"Name like '\%JAVA\%'\" get caption, name, commandline, ProcessId";
	runCommand( $pscommand_tfa, $hostname . "_tfa_process","","unicodeOutput");
	runCommand( $pscommand_java , $hostname . "_tfa_process","","unicodeOutput");
} else {
	$pscommand_tfa = "$PS -ef | grep tfa";
	$pscommand_java = "$PS -ef | grep java";
	runCommand( $pscommand_tfa, $hostname . "_tfa_process");
	runCommand( $pscommand_java , $hostname . "_tfa_process");
}

# TFA File Details
if ( -d "$tfabase" ) {
	my $lscommand;
	if ( $IS_WINDOWS ) {
		$lscommand = "dir $tfabase /S /Q";
	} else {
		$lscommand = "$FIND $tfabase -ls";
	}

	print localtime(time) . " : Collecting Details of TFA Files...\n";
	print LOG localtime(time) . " : Collecting Details of TFA Files...\n";

	runCommand( $lscommand, $hostname . "_tfa_files");

	if ( $installtype eq "GI" ) {
		my $oracle_base_tfa = catdir($oraclebase, "tfa");
		if ( $IS_WINDOWS ) {
			$lscommand = "dir $oracle_base_tfa /S /Q";
		} else {
			$lscommand = "$FIND $oracle_base_tfa -ls";
		}
		runCommand( $lscommand, $hostname . "_tfa_files");
	}

	if ( ! $IS_WINDOWS ) {
		my $inittfa = catfile($INITDIR, "init.tfa");
		$lscommand = "$LS -lHd $INITDIR $inittfa";
		runCommand( $lscommand, $hostname . "_tfa_files");
	}
}

# Collect Port Files
print LOG localtime(time) . " : Collecting TFA Port Files...\n";
if ( -d "$internaldir" ) {
	my $portfiles;
	if ( $IS_WINDOWS ) {
		my $out = `dir $internaldir /S /B | findstr "port"`;
		my @lines = split(/\n/,$out);
		foreach my $line (@lines) {
			$portfiles = "echo ".trim($line);
			runCommand( $portfiles, $hostname . "_port_files");
			$portfiles = "type ".trim($line);
			runCommand( $portfiles, $hostname . "_port_files");
		}
	} else {
		$portfiles = "$FIND $internaldir -name '*port*' -print -exec $CAT {} \\\;";
		runCommand( $portfiles, $hostname . "_port_files");
	}
}

# CRS Stack Status
if ( -d "$crshome" ) {
	my $crsctl;
	if ( $IS_WINDOWS ) {
		$crsctl = catfile($crshome, "bin", "crsctl.exe");
	} else {
		$crsctl = catfile($crshome, "bin", "crsctl");
	}
	if ( -f $crsctl ) {
		print localtime(time) . " : Collecting CRS Status...\n";
		print LOG localtime(time) . " : Collecting CRS Status...\n";
		runCommand($crsctl, $hostname . "_crs_status", "check crs");
		runCommand($crsctl, $hostname . "_crs_status", "check has");
	} else {
		print LOG localtime(time) . " : CRS crsctl [$crsctl] not found...\n";
	}

	my $olsnodes;
	if ( $IS_WINDOWS ) {
		$olsnodes = catfile($crshome, "bin", "olsnodes.exe");
	} else {
		$olsnodes = catfile($crshome, "bin", "olsnodes");
	}

	if ( -f $olsnodes ) {
		print LOG localtime(time) . " : Collecting CRS olsnodes...\n";
		runCommand($olsnodes, $hostname . "_olsnodes");
	} else {
		print LOG localtime(time) . " : CRS olsnodes [$olsnodes] not found...\n";
	}
	
	my $cfgtoolsdir = catdir($crshome, "cfgtoollogs");
	if ( -d "$cfgtoolsdir" ) {
		my $cfgfind;
		if ( $IS_WINDOWS ) {
			$cfgfind = "findstr /S /M /I \" TFA \" ".catfile($cfgtoolsdir)."\\*.*";
		} else {
			$cfgfind = "$FIND $cfgtoolsdir -type f -exec grep -l ' TFA ' {} \\\;";
		}

		print localtime(time) . " : Collecting GI Install Logs...\n";
		print LOG localtime(time) . " : Collecting GI Install Logs...\n";

		my $out = qx($cfgfind);
		my @list = split(/\s/, $out);
		mkdir($hostname."_cfgtoollogs");
		foreach my $file ( @list ) {
			$file = trim($file);
			print LOG localtime(time) . " : CFGTOOLS : $file\n";
			my $cpcmd = "$PERL $tfaosutils cp $file ".catdir(getcwd,$hostname."_cfgtoollogs")." 1";
			qx($cpcmd);
		}
	} else {
		print LOG localtime(time) . " : Directory [$cfgtoolsdir] not found...\n";
	}
} else {
	print LOG localtime(time) . " : CRS_HOME [$crshome] not found...\n";
}

print LOG localtime(time) . " : Collecting Root CRS Logs...\n"; 
if ( -d "$oraclebase" ) {
	my $crsdata = catdir($oraclebase, "crsdata", $hostname, "crsconfig");

	if ( -d "$crsdata" ) {
		my $cfgfind;
		if ( $IS_WINDOWS ) {
			$cfgfind = "findstr /S /M /I \" TFA \" ".catfile($crsdata)."\\*.*";
		} else {
			$cfgfind = "$FIND $crsdata -type f -exec grep -l ' TFA ' {} \\\;";
		}

		my $out = qx($cfgfind);
		my @list = split(/\s/, $out);
		mkdir($hostname."_cfgtoollogs") if ( ! -d $hostname."_cfgtoollogs");
		foreach my $file ( @list ) {
			$file = trim($file);
			print LOG localtime(time) . " : CFGTOOLS : $file\n";
			my $cpcmd = "$PERL $tfaosutils cp $file  ".catdir(getcwd,$hostname."_cfgtoollogs")." 1";
			qx($cpcmd);
		}
	} else {
		print LOG localtime(time) . " : Directory [$crsdata] not found...\n";
	}
} else {
	print LOG localtime(time) . " : ORACLE_BASE [$oraclebase] not found...\n";
}

print LOG localtime(time) . " : Collecting TFA Collection Logs\n";
my $reposloc = catfile($tfahome, "internal", ".reposloc.dmp");
my $repo = tfactlshare_cat($reposloc);
$repo = trim($repo);

if ( -d "$repo" ) {
	my $repofind = "$FIND $repo -type f -name '*.log'";
	my $out = qx($repofind);
	my @list = split(/\s/, $out);
	mkdir($hostname."_repo_logs");
	my $receiver = catdir("repository", "receiver");
	foreach my $file ( @list ) {
		$file = trim($file);
		if ( $file !~ /$receiver/ ) {
			print LOG localtime(time) . " : REPO-LOG : $file\n";
			my $cpcmd = "$CP -f $file $hostname" . "_repo_logs/";
			system($cpcmd);
		} else {
			print LOG localtime(time) . " : Skipping REPO-LOG : $file\n";
		}
	}
} else {
	print LOG localtime(time) . " : Repository Directory [$repo] not found...\n";
}

# Collect TFA Install Logs
if ( ! $IS_WINDOWS ) {
	my $tmp_dir = catdir("", "tmp");
	if ( -d "$tmp_dir") {
		mkdir($hostname."_install_logs");
		print localtime(time) . " : Collecting TFA Install Logs...\n";
		copy_files_with_pattern($tmp_dir, "tfa_install_*", catdir(getcwd, $hostname."_install_logs"));
	} else {
		print LOG localtime(time) . " : TMP Directory [$tmp_dir] not found...\n";
	}
}

# Checksum of TFA certificates and ssl.properties
print LOG localtime(time) . " : Collect Checksum of TFA certificates...\n";
my $ckcmd;
if ( $IS_WINDOWS ) {
	my $out = `dir $tfahome /S /B | findstr ".jks"`;
	my @lines = split(/\n/,$out);
	foreach my $file (@lines) {
		$ckcmd = "certUtil -hashfile $file MD5";
		runCommand($ckcmd, $hostname . "_checksum");
	}
	$ckcmd = "certUtil -hashfile ".catfile($internaldir,"ssl.properties")." MD5";
	runCommand($ckcmd, $hostname . "_checksum");
} else {
	$ckcmd = "$CKSUM $tfahome/*.jks";
	runCommand($ckcmd, $hostname . "_checksum");
	$ckcmd = "$CKSUM $internaldir/ssl.properties";
	runCommand($ckcmd, $hostname . "_checksum");
}

# Disk Space
print localtime(time) . " : Collecting Disk Space...\n";
print LOG localtime(time) . " : Collecting Disk Space...\n";

my $dfcmd= "$DF -k";

if ( $IS_WINDOWS ) {
	appendResults("Directory Size : ".catfile($tfahome), getDirectorySize($tfahome), $hostname . "_disk_space");
	appendResults("Directory Size : ".catfile($repository), getDirectorySize($repository), $hostname . "_disk_space");

	my $oracle_base_tfa = catdir($oraclebase, "tfa");
	if ( -d "$oracle_base_tfa" ) {
		appendResults("Directory Size : ".catfile($oracle_base_tfa), getDirectorySize($oracle_base_tfa), $hostname . "_disk_space");
	}
} else {
	runCommand($dfcmd, $hostname . "_disk_space", $tfahome);
	runCommand($dfcmd, $hostname . "_disk_space", $repository);	

	my $oracle_base_tfa = catdir($oraclebase, "tfa");
	if ( -d "$oracle_base_tfa" ) {
		runCommand($dfcmd, $hostname . "_disk_space", $oracle_base_tfa);
	}
}

if ( $installtype eq "CLOUD" ) {
	if ( $IS_WINDOWS ) {
		appendResults("Directory Size : ".catfile($tfabase), getDirectorySize($tfabase) ,$hostname . "_disk_space");
	} else {
		runCommand($dfcmd, $hostname . "_disk_space", $tfabase);
	}
}

# Top Command
print localtime(time) . " : Collecting Top Output...\n";
print LOG localtime(time) . " : Collecting Top Output...\n";

my $topcommand = "$TOP -bn 1 | head -30";

if ($osname eq "SunOS") {
	$topcommand = "$TOP -bn 25";
} elsif ( $osname eq "HP-UX" ) {
	$topcommand = "$TOP -d 1 -n 30";
} elsif ( $IS_WINDOWS ) {
	$topcommand = "tasklist";
}
runCommand($topcommand, $hostname . "_top");

# umask details
if ( ! $IS_WINDOWS ) {
	my $umaskcmd = "umask";
	runCommand($umaskcmd, $hostname . "_umask");
	$umaskcmd = "umask -S";
	runCommand($umaskcmd, $hostname . "_umask");
}

# TFA Status
my $tfactl;
if ( $IS_WINDOWS ) {
	$tfactl = catfile ($tfahome, "bin", "tfactl.bat");
} else {
	$tfactl = catfile ($tfahome, "bin", "tfactl");
}

if ( -f "$tfactl" ) {
	print localtime(time) . " : Collecting TFA Status...\n";
	print LOG localtime(time) . " : Collecting TFA Status...\n";
	runCommand( $tfactl, $hostname . "_tfactl_status", "print status");
} else {
	print LOG localtime(time) . " : TFA tfactl [$tfactl] not found...\n";
}

# Copy TFA BuildID
print LOG localtime(time) . " : Collecting TFA Build ID...\n";
my $build = catfile ($internaldir, ".buildid");
if ( -f "$build" ) {
	copy ($build, $hostname . "_buildid");
} else {
	print LOG localtime(time) . " : TFA Build ID file $build not found...\n";
}

# Copy TFA Build Version
print LOG localtime(time) . " : Collecting TFA Build Version...\n";
$build = catfile ($internaldir, ".buildversion");
if ( -f "$build" ) {
	copy ($build, $hostname . "_buildversion");
} else {
	print LOG localtime(time) . " : TFA Build Version file $build not found...\n";
}

# Copy cellip.txt
print LOG localtime(time) . " : Collecting TFA Exadata Configuration Files...\n";
my $cellip = catfile ($internaldir, "cellips.txt");
if ( -f "$cellip" ) {
	copy ($cellip, $hostname . "_cellips");
} else {
	print LOG localtime(time) . " : File cellips.txt [$cellip] not found...\n";
}

# Copy cellnames.txt
my $cellnames = catfile ($internaldir, "cellnames.txt");
if ( -f "$cellnames" ) {
	copy ($cellnames, $hostname . "_cellnames");
} else {
	print LOG localtime(time) . " : File cellnames.txt [$cellnames] not found...\n";
}

# Copy /etc/oracle/cell/network-config/cellip.ora
my $cellipora = catfile ("", "etc", "oracle", "cell", "network-config", "cellip.ora");
if ( -f "$cellipora" ) {
	copy ($cellipora, $hostname . "_cellip.ora");
} else {
	print LOG localtime(time) . " : File cellip.ora [$cellipora] not found...\n";
}

# Copy tfa_directories.txt
print LOG localtime(time) . " : Collecting TFA Directories File...\n";
my $tfa_directories = catfile($tfahome, "tfa_directories.txt");
if ( -f "$tfa_directories" ) {
	copy ($tfa_directories, $hostname . "_tfa_directories");
} else {
	print LOG localtime(time) . " : TFA Directories file $tfa_directories not found...\n";
}

# Copy removed_directories.txt
print LOG localtime(time) . " : Collecting TFA Removed Directories File...\n";
my $removed_directories = catfile($internaldir, "removed_directories.txt");
if ( -f "$removed_directories" ) {
	copy( $removed_directories, $hostname . "_tfa_removed_directories");
} else {
	print LOG localtime(time) . " : TFA Removed Directories file $removed_directories not found...\n";
}

# Copy tfa_setup.txt
copy($tfa_setup, $hostname . "_tfa_setup");

# Copy TFA Config
copy($tfa_config, $hostname . "_config.properties");

# Copy Inventory Related Stuffs
print LOG localtime(time) . " : Collecting TFA Inventory and Mapping Files...\n";
if ( -d "$invdir" ) {
	my $invxml = catfile ($invdir, "inventory.xml");
	if ( -f "$invxml" ) {
		copy ( $invxml, $hostname . "_inventory.xml");
	}

	my $dirwithnomap = catfile ($invdir, "directoriesWithNoMappings.xml");
	if ( -f "$dirwithnomap" ) {
		copy ( $dirwithnomap, $hostname . "_directoriesWithNoMappings.xml");
	}

	my $fileswithnotype = catfile ($invdir, "filesWithNoFileTypes.xml");
	if ( -f "$fileswithnotype" ) {
		copy ( $fileswithnotype, $hostname . "_filesWithNoFileTypes.xml");
	}
} else {
        print LOG localtime(time) . " : TFA Inventory Directory [$invdir] not found...\n";
}

# Get status of ports using netstat
print LOG localtime(time) . " : Collecting netstat details...\n";
my $netstatcmd = "$NETSTAT -an | grep LISTEN | grep 50[01][0-9]";
if ( $osname eq "Linux" ) {
	$netstatcmd = "$NETSTAT -anp | grep LISTEN | grep 50[01][0-9]";
} elsif ( $IS_WINDOWS ) {
	$netstatcmd = "netstat -an | findstr LISTENING | findstr 50[01][0-9]";
}
runCommand($netstatcmd, $hostname . "_tfa_netstat");

# PID and Jstack
print LOG localtime(time) . " : Collecting details of TFA Process...\n";
my $pidfile = catfile ($internaldir, ".pidfile");
my $pscommand;
if ( -f $pidfile ) {
	my $tfapid = tfactlshare_cat($pidfile);
	$tfapid = trim($tfapid);
	copy ($pidfile, $hostname . "_pid");

        if ( $IS_WINDOWS ) {
        	$pscommand = "tasklist | findstr $tfapid";
        } else {
        	$pscommand = "$PS -ef | grep $tfapid";
        }
        runCommand( $pscommand, $hostname . "_tfa_process");

	# TFA Threads
	if ( $IS_WINDOWS ) {
		#In case of windows there is no parent child relation as linux.
		runCommand("tasklist | findstr java | findstr $tfapid", $hostname . "_tfa_threads");
	} elsif ( $osname ne "HP-UX" && $osname ne "AIX" ) {
		runCommand("$PS -AL | grep java | grep $tfapid", $hostname . "_tfa_threads");
	}

	my $thread_cpu = "$PS -p $tfapid -L -o pid,tid,time,pcpu,pmem";

	if ( $osname eq "SunOS" ) {
		$thread_cpu = "$PS -p $tfapid -L -o pid,lwp,time,pcpu,pmem";
	} elsif ( $osname eq "AIX" ) {
		$thread_cpu = "$PS -L $tfapid -o pid,time,pcpu";
	}

	print LOG localtime(time) . " : Collecting details of TFA Threads...\n";

	if ( ! $IS_WINDOWS && $osname ne "HP-UX" ) {
		runCommand("$thread_cpu", $hostname . "_tfa_cpu_usage");
	}

	# Files opened by TFA
	print LOG localtime(time) . " : Collecting List of Open Files...\n";
	if ( $osname eq "Linux" ) {
		my $lsof = catfile("", "usr", "sbin", "lsof");
		if ( -f "$lsof" ) {
			runCommand("$lsof -p $tfapid", $hostname . "_lsof");
		}
	} elsif ( $osname eq "SunOS" ) {
		my $pfiles = catfile("", "usr", "bin", "pfiles");
		if ( -f "$pfiles" ) {
			runCommand("$pfiles $tfapid", $hostname . "_lsof");
		}
	} elsif ( $osname eq "HP-UX" ) {
		my $lsof = catfile("", "usr", "local", "bin", "lsof");
		if ( -f "$lsof" ) {
			runCommand("$lsof -p $tfapid", $hostname . "_lsof");
		}
	} elsif ( $osname eq "AIX" ) {
		my $pfiles = catfile("", "bin", "procfiles");
		if ( -f "$pfiles" ) {
			runCommand("$pfiles -n $tfapid", $hostname . "_lsof");
		}
	}

	# Process Tree
	print LOG localtime(time) . " : Collecting Process Tree Output...\n";
	if ( ! $IS_WINDOWS ) {
		my $treecmd = "$PTREE -a";
		if ( $osname eq "Linux" ) {
			$treecmd = "$PTREE -ap";
		} elsif ( $osname eq "HP-UX" ) {
			$treecmd = "$PTREE -s";
		}
		runCommand("$treecmd $tfapid", $hostname . "_process_tree");

		# Process Status and pmap
		my $pmap = catfile("", "usr", "bin", "pmap");
		if ( -f "$pmap" ) {
			runCommand("$pmap $tfapid", $hostname . "_pmap");
		}

		my $pstatus = catfile("", "proc", $tfapid, "status");
		if ( -f "$pstatus" ) {
			copy($pstatus, $hostname . "_proc_status");
		}
	}

	# Collect JStack details
	print localtime(time) . " : Collecting JStack Output...\n";
	print LOG localtime(time) . " : Collecting JStack Output...\n";

	my $jstack;
	if ( $IS_WINDOWS ) {
		$jstack = catfile ($crshome, "jdk", "bin", "jstack.exe");
	} elsif ( $osname eq "SunOS" ) {
		$jstack = getJavaOnSunOS(catfile($crshome, "jdk"), "jstack");
	} else {
		$jstack = catfile ($crshome, "jdk", "bin", "jstack");
	}

	if ( -f "$jstack" ) {
		runCommand("$jstack $tfapid", $hostname . "_jstack");
		sleep(5);
		my $echocmd;
		if ( $IS_WINDOWS ) {
			$echocmd = "(echo.========================================================== & echo.) >> $hostname\_jstack";
		} else {
			$echocmd = "echo \"==========================================================\n\" >> $hostname\_jstack";
		}
		system($echocmd);
		runCommand("$jstack $tfapid", $hostname . "_jstack");
		sleep(5);
		system($echocmd);
		runCommand("$jstack $tfapid", $hostname . "_jstack");
	} else {
		print LOG localtime(time) . " : Java JStack [$jstack] not found...\n";
	}
} else {
	print LOG localtime(time) . " : TFA PID file [$pidfile] not found...\n";
}

# TFA Logs
if ( -d "$logdir" ) {
	mkdir($hostname."_logs");
	print localtime(time) . " : Collecting TFA Logs...\n";
	print LOG localtime(time) . " : Collecting TFA Logs...\n";
	my $logcommand = "$PERL $tfaosutils cp $logdir ".catdir(getcwd,$hostname."_logs")." 1";
	qx($logcommand);
} else {
	print LOG localtime(time) . " : TFA Log Directory [$logdir] not found...\n";
}

# Patch Log
print LOG localtime(time) . " : Collecting TFA Patch Logs...\n";
my $patchlog = substr($tfahome, 0, (index ($tfahome, "tfa_home") - 1) );
$patchlog = catfile($patchlog, "tfapatch.log");
if ( -f $patchlog ) {
	copy($patchlog, $hostname . "_tfa_patchlog");
}

# BDB Stats
if ( -d "$bdbdir" ) {
	print localtime(time) . " : Collecting TFA BDB Stats...\n";
	print LOG localtime(time) . " : Collecting TFA BDB Stats...\n";

	mkdir($hostname."_database");
	copy_files_with_pattern($bdbdir,"je.stat.*",catdir(getcwd,$hostname."_database"));
	copy_files_with_pattern($bdbdir,"je.info.*",catdir(getcwd,$hostname."_database"));
	copy_files_with_pattern($bdbdir,"je.config.*",catdir(getcwd,$hostname."_database"));

	# Collect BDB Stats
	my $java = catfile ( $javahome, "bin", "java" );
	my $bdbjar = catfile ( $tfahome, "jlib", "je-6.4.25.jar" );

	if ( ! -f "$java" ) {
		$java = catfile ( $crshome, "jdk", "jre", "bin", "java" ) if ( -d "$javahome" );
	}

	if ( -f "$java" && -f "$bdbjar" ) {
		my $javacmd = "$java -jar $bdbjar";

		my $dbspace = "$javacmd DbSpace -h $bdbdir -l -p";
		runCommand($dbspace, $hostname . "_database_dbspace");
	
		my $dbdump = "$javacmd DbDump -h $bdbdir -l -p";
		runCommand($dbdump, $hostname . "_database_dbdump");

		my $dbverify = "$javacmd DbVerify -h $bdbdir -l -p";
		runCommand($dbverify, $hostname . "_database_dbverify");
	} else {
		print LOG localtime(time) . " : Java [$java] or BDB Jar [$bdbjar] not found...\n";
	}
} else {
	print LOG localtime(time) . " : TFA BDB Directory [$bdbdir] not found...\n";
}

# Zip all Files
if ( ! $nozip ) {
	my $zip = "$ZIP";
	my $zipcommand;
	print localtime(time) . " : Zipping Collections...\n";
	print LOG localtime(time) . " : Zipping Collections...\n";

	if ( ! -f "$ZIP" ) {
		if ( -f catfile($crshome, "bin", "zip") ) {
			$zip = catfile($crshome, "bin", "zip");
		}
	}
	
	# Close Diagnostic Log 
	close (LOG);

	if ( $IS_WINDOWS ) {
		$zipcommand = "zip -rqm $hostname.zip *.* ";
	} else {
		$zipcommand = "$zip -rm $hostname.zip * > /dev/null";
	}

	system($zipcommand);

} else {
	print LOG localtime(time) . " : NOZIP : $nozip";
	print LOG localtime(time) . " : Not Zipping Collections due to nozip flag\n";

	# Close Diagnostic Log 
	close (LOG);
}

my @fileList = osutils_getRecursiveFolderContents(catdir($collection));
chmod 0700, @fileList;

sub runCommand {
	my $script = shift;
	my $outfile = shift;
	my $parameters = shift;
	my $unicodeOutput = shift;

	my $cmd = "$script";

	if ( $parameters ) {
		$cmd = "$script " . "$parameters";
	}

	my $dateNtime = strftime "%a %b %d %H:%M:%S %Z %Y", localtime;
	my $echocmd;
	my $echocmd1;

	if ( $IS_WINDOWS ) {
		$echocmd = "(echo Date : $dateNtime & echo.Command : \'$cmd\' & echo. & echo.Output : & echo.) >> $outfile";
		$echocmd1 = "(echo. & echo.) >> $outfile";
	} else {
		$echocmd = "echo \"Date : $dateNtime\nCommand : \'$cmd\' \n\nOutput : \n\" >> $outfile";
		$echocmd1 = "echo \"\n\" >> $outfile";
	}

	my $command;
	if ( $IS_WINDOWS && (defined($unicodeOutput) && ($unicodeOutput ne ''))) {
		$command = "$cmd | more >> $outfile 2>&1";
	} else {
		$command = "$cmd >> $outfile 2>&1";
	}
	
	system($echocmd);
	system($command);
	system($echocmd1);
}

sub appendResults {
	my $command = shift;
	my $output = shift;
	my $outfile = shift;

	my $dateNtime = strftime "%a %b %d %H:%M:%S %Z %Y", localtime;
	my $echocmd;
	my $echocmd1;

	if ( $IS_WINDOWS ) {
		$echocmd = "(echo Date : $dateNtime & echo.Command : \'$command\' & echo. & echo.Output : & echo.) >> $outfile";
		$echocmd1 = "(echo. & echo.) >> $outfile";
	} else {
		$echocmd = "echo \"Date : $dateNtime\nCommand : \'$command\' \n\nOutput : \n\" >> $outfile";
		$echocmd1 = "echo \"\n\" >> $outfile";
	}
	my $command = "echo $output >> $outfile 2>&1";
	system($echocmd);
	system($command);
	system($echocmd1);
}

sub getDirectorySize{
	my $dir = shift;
	my $size;
	$size = 0; find( sub { -f and ( $size += -s _ ) }, $dir );
	return $size;
}

sub copy_files_with_pattern{
	my $source =shift;
	my $pattern =shift;
	my $destination =shift;

	my $cmd;
	if ( $IS_WINDOWS ) {
		$cmd = "robocopy $source $pattern $destination  /NFL /NDL /NJH /NJS /nc /ns /np";
	} else {
		$cmd = "$CP -rf $source/$pattern $destination/ > /dev/null 2>&1";
	}
	system($cmd);
}
