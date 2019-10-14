#
# $Header: tfa/src/v2/tfa_home/bin/discoverOraStack.pl /st_tfa_19/1 2018/11/22 01:20:28 bibsahoo Exp $
#
# discoverOraStack.pl
#
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      discoverOraStack.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bibsahoo    11/02/18 - XbranchMerge bibsahoo_bug-28756550 from main
#    bibsahoo    10/09/18 - FIX BUG 28756550
#    bibsahoo    08/28/18 - FIX BUG 28561200
#    bburton     07/10/18 - use odacli or dbcli to get node list when GI not
#                           available
#    bibsahoo    06/27/18 - Discover PDBs: Bug 28255236
#    recornej    05/09/18 - Remove redirect when retrieving shell
#    migmoren    04/04/18 - Bug 27657245 SOL18.1 - TYPE: COMMANDS.SQL: NOT
#                           FOUND ERROR DURING TFA INSTALLATION
#    bibsahoo    03/08/18 - discovery of running dbs on si windows
#    recornej    03/02/18 - Remove extra "
#    recornej    03/05/18 - Fix AIX skipping db_home
#    recornej    01/17/18 - XbranchMerge recornej_aix18_1bug from st_tfa_18.1
#    bburton     02/26/18 - XbranchMerge bburton_new_27446097_txn from
#                           st_tfa_12.2.1.3.1
#    bburton     01/05/18 - fix issue adding /install when no ORACLE_HOME is
#                           set
#    bburton     01/28/18 - fix hang due to permissions on commnds.sql -
#                           27446097
#    recornej    12/05/17 - Adding -L to sqlplus connections to prevent hangs
#    recornej    12/05/17 - Removing export error when running in csh.
#    bburton     11/02/17 - Fix Non Bash Issues
#    bburton     11/01/17 - Fix Discovery for Non root
#    recornej    12/15/17 - Fix pmap in AIX
#    cnagur      10/31/17 - Fix for Bug 27003629
#    bburton     09/19/17 - Fix issues with running as Oracle/GI user
#    manuegar    09/19/17 - manuegar_ips_diff.
#    bburton     08/28/17 - bug26696360 - windows hyphen in hostname
#    manuegar    08/22/17 - pmap discovery.
#    bburton     07/25/17 - Add DBUA Specific directory
#    bibsahoo    06/28/17 - FIX BUG 26363301
#    bburton     06/20/17 - oc4j no longer used in 12.2 but check for older
#                           versions
#    bibsahoo    06/20/17 - FIX BUG 26310237
#    bburton     06/14/17 - do not print ENV issues in ADE
#    llakkana    05/23/17 - Fix issues found in 12.2.1.1.0 testing
#    bibsahoo    05/16/17 - FIX BUG 26084594
#    bburton     05/10/17 - check for transferdie before removal on Win
#    manuegar    05/10/17 - manuegar_srdcwin07.
#    manuegar    05/08/17 - XbranchMerge manuegar_srdcwin02_122 from
#                           st_tfa_12.2.1.1.01
#    bburton     05/08/17 - Invalid ohome
#    manuegar    05/03/17 - manuegar_srdcwin02.
#    bburton     05/03/17 - do not cd to /home/bburton when /home/bburton is
#                           not escaped
#    bburton     05/01/17 - Fix issue sin ADE env breaking sregress
#    manuegar    04/27/17 - manuegar_srdcwin01.
#    bburton     04/07/17 - HOME/inventory added
#    manuegar    01/24/17 - EM SRDC.
#    bibsahoo    11/08/16 - DISCOVERY SHELL ERROR
#    bibsahoo    10/14/16 - tfa windows bugs
#    bibsahoo    09/23/16 - DISCOVERY CRSHOME INCONSISTENCY AFTER GI UPGRADE
#    bibsahoo    08/25/16 - WINDOWS TYPICAL INSTALL BUGS
#    bibsahoo    08/02/16 - DISCOVERY USER ISSUE
#    bburton     08/02/16 - Discover ASMIO (IOS)
#    sgoggi      07/29/16 - XbranchMerge sgoggi_tfa_fixes from main
#    bibsahoo    07/18/16 - FIX Bug 23473630 - LNX64-12.2-TFA:NON ROOT WAS
#                           UNABLE TO RUN TFACTL AFTER RESTART ORACLE INSTALLED
#    bibsahoo    07/12/16 - DISCOVERY RESTRUCTURE
#    bibsahoo    06/17/16 - Windows Typical Install
#    bibsahoo    05/31/16 - TFA ADE/SI FIX
#    arupadhy    05/16/16 - Added windows specific changes
#    bibsahoo    05/13/16 - REMOVE SWITCH CASE DISCOVERY
#    bburton     05/03/16 - remove bad read of oraInst.loc
#    bibsahoo    02/17/16 - Creation

use strict;
#use warnings;
use English;
use File::Basename;
use File::Spec::Functions;
use File::Path qw(mkpath rmtree);
use File::Copy;
use File::Find;
use Time::Local;
use Term::ANSIColor;
use Cwd;
use POSIX;
use Sys::Hostname;

use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin);
use Cwd qw(realpath abs_path);
use lib realpath("$Bin");

my $UNAME=$^O;
my $PLATFORM=$UNAME;
#print "$PLATFORM\n";
my $IS_WIN = 0;
if ($PLATFORM eq "MSWin32") {
  $IS_WIN = 1;
}

my $debug = 0;
my $perl;
my $debugFlag = 0;
my $debugFileName;
my %base_for_homes;

sub usage {
    print "Usage: $0 -d debug(0|1) -h help\n";
    exit;
}

GetOptions(
  "d=n" => \$debug,
  "perl=s" => \$perl,
  "h"   => \&usage
) or usage();

if ( $debug == 1  or $ENV{TFA_DEBUG} ) {
  $debugFlag = 1;
  $debug = 1;
}

## PATH WITH SPACES IN BETWEEN AND " AT THE START AND END FAIL THE "if (-f $path)" CHECK
if ($perl =~ /\s{1,}/ && $perl =~ /"/) {
  $perl =~ s/"//g;
}

my @cmd_win_data;

my $program_name = basename $0;
$program_name =~ s/[\.\/]//g;

my $CHECKHOME = getcwd;
my $SCRIPTPATH = dirname(abs_path($0));
my $LOGDIR = catfile($SCRIPTPATH,"..","tmp");
my $SCRIPTFIL = catfile($SCRIPTPATH,$program_name);
my $FDS = strftime "%Y%m%d_%H%M%S", localtime;
chomp($FDS);
my $INPUTDIR = catfile($LOGDIR,".input_".$FDS);
my $SQLFIL = catfile($INPUTDIR, "d_check.sql");
my $UPLOADFIL_VAR = $program_name;
my $UPLOADFIL = catfile($LOGDIR, $UPLOADFIL_VAR."_".$FDS);
my $OUTPUTDIR_VAR = $program_name;
my $OUTPUTDIR = catfile($LOGDIR, $OUTPUTDIR_VAR."_".$FDS);
my $SPOOLFIL = catfile($OUTPUTDIR,"d_check.out");
my $OSOUTFIL = catfile($OUTPUTDIR, "o_check");
my $UPDATEFIL = catfile($OUTPUTDIR, "db_update_".$FDS.".sql");
my $SQLLOGFIL = catfile($OUTPUTDIR, "sql.log");
my $LOGFIL = catfile($OUTPUTDIR, $program_name.".log");
my $SKIPFIL = catfile($OUTPUTDIR, $program_name."_skipped_checks.log");
my $ERRFIL = catfile($OUTPUTDIR, $program_name."_error.log");
my $HOSTLIST = catfile($OUTPUTDIR, "o_host_list.out");
my $MASTERFIL = catfile($OUTPUTDIR, "raccheck_env.out");
my $ORCLENVFIL = catfile($INPUTDIR, "set_orcl_env.sh");
my $SREPFIL = catfile($OUTPUTDIR, $program_name."_summary.rep");
my $WRNDBPWD = 0;
my $EXESQL = catfile($INPUTDIR, "exec_raccheck_sqls.sh");
my $WIN_TRANSFER_DIR = catfile("C:", "transfer");
my $TFA_HOME = catfile($SCRIPTPATH,"..");

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME);
  push @INC, dirname($PROGRAM_NAME).'/common';
  push @INC, dirname($PROGRAM_NAME).'/common/exceptions';
  push @INC, dirname($PROGRAM_NAME).'/modules';
}

use tfactlshare;
use tfactlmineocr;
use osutils;

if ( $debugFlag == 1 ) {
  $debugFileName = catfile($OUTPUTDIR, "run.out");
  print "$debugFileName\n";
}

#print $WIN_TRANSFER_DIR;
mkpath($LOGDIR);
mkpath($INPUTDIR);
mkpath($OUTPUTDIR);
if ($IS_WIN) {
  mkpath($WIN_TRANSFER_DIR);
}

my $rat_local_install = $ENV{RAT_LOCALONLY};
#print "Local Install: $rat_local_install\n\n";
my $is_this_ade = 0;
my $env_val = $ENV{ADE_VIEW_ROOT};
if ( length("$env_val") != 0 ) {
  $is_this_ade = 1;
}

my $sqlFile;
if ($IS_WIN) {
    $sqlFile = catfile($WIN_TRANSFER_DIR, "oratfa_commands.sql");
} else {
    $sqlFile = catfile($TFA_HOME, "oratfa_commands.sql");
}

# ade settings
my $IS_WINDOWS = 0;
$IS_WINDOWS = 1 if $^O eq "MSWin32";

my $IS_ADE_HOST = FALSE;
my $chkadecmd;
if ( $IS_WINDOWS ) {
  $chkadecmd = `set`;
}
else {
  $chkadecmd = `env`;
}
if ( $chkadecmd ) {
  my @vars = split(/\n/,$chkadecmd);
  @vars    = grep{/ADE_/} @vars;
  if ( @vars ) {
    $IS_ADE_HOST = TRUE;
  }
}

my @MASTERFIL_ARRAY;
open(my $hlist, '>>', $HOSTLIST) or die "Could not open file '$HOSTLIST' $!";

print "\nStarting Discovery...\n\n";

my @tmp;
my @tmp1;
my @tmp2;
my @file_arr;
my $HOSTNAME = tolower_host();
my $ORACLE_BASE;

#FINDING CRSHOME
my $RAT_CRS_HOME = get_crs_home();
chomp($RAT_CRS_HOME);
#print "\nCRS_HOME: $RAT_CRS_HOME\n\n";

my $is_crs_up = check_crs_state();
#print "CRS UP: $is_crs_up\n";

my $cloc;
my @mfile_arr;
my $cluster_name;
if (length($RAT_CRS_HOME) != 0) {
  if ($is_crs_up == 1) {
    if ($IS_WIN) {
      $cloc = catfile($RAT_CRS_HOME,"BIN","cemutlo.exe");
    } else {
      $cloc = catfile($RAT_CRS_HOME,"bin","cemutlo");
    }

    $cluster_name=`$cloc -n`;
  } else {
    $cloc = catfile($RAT_CRS_HOME,"crs","install","crsconfig_params");

    @tmp = readFileToArray("$cloc");
    foreach my $x (@tmp) {
      if ($x =~ /^CLUSTER_NAME=/) {
        @tmp1 = split /=/, $x;
        $cluster_name = $tmp1[-1];
        #print "CLUSTER_NAME : $cluster_name from file\n";
      }
    }
  }
  chomp($cluster_name);
  push @MASTERFIL_ARRAY, "CLUSTER_NAME=$cluster_name";
}

# IF CRS is up then we can use it to gather information and determine the node list.
# mineocr generates an OLSNODES= line that sync will use,
# If we are on a dcs system with no GI installed we need to call in to odacli or dbcli to get the nodes.

my $odacli = catfile("","opt","oracle","dcs","bin","odacli");
my $dbcli = catfile("","opt","oracle","dcs","bin","odacli");
my $listnodescmd;

if (length($RAT_CRS_HOME) != 0 && $is_crs_up == 1) {
  my $result_code = discover_crs_db_asm_and_write_kvout($MASTERFIL,$RAT_CRS_HOME, $debugFileName);
  my @mfile_array = readFileToArray($MASTERFIL);
  foreach my $line (@mfile_array) {
    chomp($line);
    push @MASTERFIL_ARRAY, $line;
  }
} elsif ( -f $odacli ) {
    print "Using $odacli to determine node list\n";
    $listnodescmd = "$odacli list-nodes -j"
} elsif ( -f $dbcli ) {
    print "Using $odacli to determine node list\n";
    $listnodescmd = "$dbcli list-nodes -j"
}

if ( length($listnodescmd) ) { # run the command and get the node list
    my $jsonout = `$listnodescmd`;
    my @odanodes;
    foreach my $line (split /\n/ ,$jsonout) {
      if (  $line =~ /nodeName\"\s\:\s\"(.*)\"/ ) {
      print "line : $line\n" if ( $debug );
      print "node : $1\n" if ( $debug );
      push @odanodes, $1;
      }
    }
    push @MASTERFIL_ARRAY, "ODANODES=@odanodes"
}

#Adding Hostnames to the file $HOSTLIST
my $nodeList = "";
if (length($RAT_CRS_HOME) != 0) {
  #Adding Hostnames to the file $HOSTLIST
  print "\nGetting list of nodes in cluster . . . . .\n\n";
  print "List of nodes in cluster:\n";
  if ($is_crs_up == 1) {
    if ($IS_WIN) {
            $cloc = catfile($RAT_CRS_HOME,"BIN","olsnodes.exe");
    } else {
            $cloc = catfile($RAT_CRS_HOME,"bin","olsnodes");
    }

    $nodeList = `$cloc`;
  } else {
    $cloc = catfile($RAT_CRS_HOME,"crs","install","crsconfig_params");

    @tmp = readFileToArray("$cloc");
    foreach my $x (@tmp) {
      if ($x =~ /^NODE_NAME_LIST=/) {
        @tmp1 = split /=/, $x;
        chomp($tmp1[-1]);
        if ($tmp1[-1]) {
          $nodeList = $tmp1[-1];
        }
        #print "NODELIST : $nodeList from file\n"
      }
    }
  } 
} else {
  print "\nNo Grid Infrastructure Discovered on this system . . . . .\n\n";
  $rat_local_install = 1;
}

if (length($nodeList) == 0) {
  $nodeList = $HOSTNAME;
} else {
  my @nodeArr;
  if ($nodeList =~ /\,/) {
    @nodeArr = split /\,/, $nodeList;
  }  else {
    @nodeArr = split /\n/, $nodeList;
  }

  my @finalNodeArr = ();
  push @finalNodeArr, $HOSTNAME;

  foreach my $node (@nodeArr) {
    if ($node !~ /$HOSTNAME/) {
      push @finalNodeArr, $node;
    }
  }

  $nodeList = join "\,", @finalNodeArr;
}

if ($nodeList =~ /\,/) {
  foreach my $x (split /\,/, $nodeList) {
    print "$x\n";
    print $hlist "$x\n";
  }
} else {
  foreach my $x (split /\n/, $nodeList) {
    print "$x\n";
    print $hlist "$x\n";
  }
}

my $nodes;

if ($rat_local_install ==  0) {
  $nodes = join("\,",(split /\n/, $nodeList));
  push @MASTERFIL_ARRAY, "NODE_NAMES=$nodes";
  #print "\nNODE_NAMES=$nodes\n";
} else {
  print $hlist "$HOSTNAME\n";
  push @MASTERFIL_ARRAY, "NODE_NAMES=$HOSTNAME";
}
close $hlist;

my $usern;
if ($PLATFORM eq "linux") {
  $usern = `whoami`;
}
elsif ($IS_WIN) {
  $usern = `echo %USERNAME%`;
}
elsif ($PLATFORM eq "solaris") {
  $usern = `id|awk '{print $1}'|cut -d'(' -f2|cut -d')' -f1`;
}
elsif ($PLATFORM eq "hpux") {
  $usern = `whoami`;
}
elsif ($PLATFORM eq "aix") {
  $usern = `whoami`;
}
else {
  print "ERROR: Unknown Operating System\n";
}

chomp($usern);
my $HOME = $ENV{HOME};

my @hlist_arr = readFileToArray($HOSTLIST);
my $PING;
my $localnode = $HOSTNAME;
my $exitcode;
my $ssh_setup_status;
my $rsh_setup_status;
my $SSHELL;
my $SCOPY;
my $AutoLoginCheck;
my $tmpSshConf;
my $temp_hlist;
my @hnameArr;
my $SILENT = 0;
my $res_ping;
my $sshcmd;

# Variables for SSH
my $SSH = getCommandLocation("ssh");
$SSH = "$SSH -q";
my $SCP = getCommandLocation("scp");
my $SSH_KEYGEN = getCommandLocation("ssh-keygen");
my $SSH_COPY_ID = getCommandLocation("ssh-copy-id");
my $SSH_ENCR = "rsa";
my $SSH_USER = $usern;
my $SSH_BITS = "1024";
my $SSH_ID = "id_rsa";
my $SSH_GEN_KEYS = 0;
my $SSH_COUNT = 0;
my $SSH_GEN_KEYS;
my $CAT = getCommandLocation("cat");
my $SED = getCommandLocation("sed");

if ($IS_WIN) {
  if ($rat_local_install == 0) {
    print "\n\nChecking ssh user equivalency settings on all nodes in cluster\n";
    foreach my $hname (@hlist_arr) {
      chomp($hname);
      if ($hname ne $localnode) {
        $ssh_setup_status = check_ssh_equivalence($hname);
        #print "$hname SSH STATUS: $ssh_setup_status\n";

        if ($ssh_setup_status == 0) {
          print "\nNode $hname is configured for ssh user equivalency for $usern user\n";
        } else {
          print "\nNode $hname is not configured for ssh user equivalency and  the script uses ssh to install TFA on remote nodes.\n\nWithout this facility the script cannot install TFA on the remote nodes. \n";
          if ( length("$SILENT") != 0 && $SILENT == 1 ) { 
            #Remove host
            @tmp = readFileToArray($HOSTLIST);
            $temp_hlist = catfile($INPUTDIR,"o_host_list.out");
            open(my $temp_hlist_ptr, '>>', $temp_hlist) or die "Could not open file '$temp_hlist' $!";
            foreach my $x (@tmp) {
              chomp($x);
              if ($x ne $hname) {
                print $temp_hlist_ptr "$x\n";
              }
            }
            copy($temp_hlist, $HOSTLIST) or die "Copy failed: $temp_hlist to $HOSTLIST $!";
            unlink($temp_hlist);
          } else {
            print "\nDo you want to configure SSH for user $usern on $hname [y/n] ";
            #$AutoLoginCheck = "y";
            $AutoLoginCheck = <STDIN>;
            chomp($AutoLoginCheck);
            #print "$AutoLoginCheck";
            my $pwd;

              if ($AutoLoginCheck =~ /^[Y|YES]$/i) {
                #print "Inhere1\n";
                print "Enter Password for $usern\@$hname: ";
                $pwd = <STDIN>;
                $sshcmd = "NET USE \\\\$hname\\IPC\$ /u:$usern $pwd";
                print `$sshcmd`;
                #$sshcmd = "NET USE \\\\$DstHost\\IPC\$ /D";
                #print `$sshcmd`;
              }
              elsif ($AutoLoginCheck =~ /^[N|NO]$/i) {
                #print "Inhere2\n";
                print "\nWe can configure ssh only for this run and reverse the changes back. do you want to continue?[y/n] ";
                #$tmpSshConf = "y";
                $tmpSshConf = <STDIN>;
                chomp($tmpSshConf);

                if ($tmpSshConf =~ /^[Y|YES]$/i) { 
                  #print "Inhere3\n";
                  print "Enter Password for $usern\@$hname: ";
                  $pwd = <STDIN>;
                  $sshcmd = "NET USE \\\\$hname\\IPC\$ /u:$usern $pwd";
                  print `$sshcmd`;
                  my $temp_ssh_setup_status = check_ssh_equivalence($hname);
                  if ($temp_ssh_setup_status == 0) {
                    push @hnameArr, $hname;
                  }
                }
                elsif ($tmpSshConf =~ /^[N|NO]$/i) { 
                  #print "Inhere4\n";
                  if ( $hname eq $localnode ) {
                    print "\nWithout ssh user equivalency program is executed only on localnode $localnode\n";
                    $temp_hlist = catfile($INPUTDIR,"o_host_list.out");
                    open(my $temp_hlist_ptr, '>>', $temp_hlist) or die "Could not open file '$temp_hlist' $!";
                    print $temp_hlist_ptr "$localnode\n";
                    copy($temp_hlist, $HOSTLIST) or die "Copy failed: $temp_hlist to $HOSTLIST $!";
                    unlink($temp_hlist);
                  } else {
                      print "\nWithout ssh user eqivalency, program is not executed on $hname\n";
                      @tmp = readFileToArray($HOSTLIST);
                      $temp_hlist = catfile($INPUTDIR,"o_host_list.out");
                      open(my $temp_hlist_ptr, '>>', $temp_hlist) or die "Could not open file '$temp_hlist' $!";
                      foreach my $x (@tmp) {
                        chomp($x);
                        if ($x ne $hname) {
                          print $temp_hlist_ptr "$x\n";
                        }
                      }
                      copy($temp_hlist, $HOSTLIST) or die "Copy failed: $temp_hlist to $HOSTLIST $!";
                      unlink($temp_hlist);
                  }
                }
                else {
                  print "Enter Password for $usern\@$hname: ";
                  $pwd = <STDIN>;
                  $sshcmd = "NET USE \\\\$hname\\IPC\$ /u:$usern $pwd";
                  print `$sshcmd`;
                  push @hnameArr, $hname;
                }
              }
              else {
                #print "Inhere5\n";
                print "Enter Password for $usern\@$hname: ";
                $pwd = <STDIN>;
                $sshcmd = "NET USE \\\\$hname\\IPC\$ /u:$usern $pwd";
                print `$sshcmd`;
                if ( $? != 0 ) {
                  @tmp = readFileToArray($HOSTLIST);
                  $temp_hlist = catfile($INPUTDIR,"o_host_list.out");
                  open(my $temp_hlist_ptr, '>>', $temp_hlist) or die "Could not open file '$temp_hlist' $!";
                  foreach my $x (@tmp) {
                    chomp($x);
                    if ($x ne $hname) {
                      print $temp_hlist_ptr "$x\n";
                    }
                  }
                  copy($temp_hlist, $HOSTLIST) or die "Copy failed: $temp_hlist to $HOSTLIST $!";
                  unlink($temp_hlist);
                }
              }
            
          }
        }
      }
    }
  }
} else {
  if ($rat_local_install == 0) {
    print "\n\nChecking ssh user equivalency settings on all nodes in cluster\n";

    foreach my $hname (@hlist_arr) {
      chomp($hname);
      if ($PLATFORM eq "linux") {
        $PING = "/bin/ping";
      } else {
        $PING = "/usr/sbin/ping";
      }

      if ($hname ne $localnode) {
        if ( $PLATFORM eq "solaris" ) {
            $res_ping = `$PING -s $hname 5 5`;
        } elsif ( $PLATFORM eq "hpux" ) {
          $res_ping = `$PING $hname -n 5 -m 5`;
        } else {
            $res_ping = `$PING -c 1 -w 5 $hname`;
        }
        #print "\n$res_ping\n";
        $exitcode = `echo $?`;
        #print "EXITCODE: $exitcode\n";

        if ( $exitcode == 0 && $hname ne $localnode ) {
              `$SSH -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -l $usern $hname ls 2>/dev/null 1>/dev/null`;
              $ssh_setup_status = $?;
            if ( $ssh_setup_status != 0 ) {
                `rsh -l $usern $hname ls 2>/dev/null 1>/dev/null`;
                  $rsh_setup_status = $?; 
                  if ( $rsh_setup_status == 0 ) {
                    $SSHELL = "rsh";
                    $SCOPY = "rcp";
                  }
              }
              #print "SSH STAT: $ssh_setup_status; RSH STAT: $rsh_setup_status\n";

              if ( $ssh_setup_status == 0 || $hname eq $localnode || $rsh_setup_status == 0 ) {
                  print "\nNode $hname is configured for ssh user equivalency for $usern user\n";
                } else {
                    print "\nNode $hname is not configured for ssh user equivalency and  the script uses ssh to install TFA on remote nodes.\n\nWithout this facility the script cannot install TFA on the remote nodes. \n";
                    if ( length("$SILENT") != 0 && $SILENT == 1 ) {
                      #Remove host
                      @tmp = readFileToArray($HOSTLIST);
                      $temp_hlist = catfile($INPUTDIR,"o_host_list.out");
                      open(my $temp_hlist_ptr, '>>', $temp_hlist) or die "Could not open file '$temp_hlist' $!";
                      foreach my $x (@tmp) {
                        chomp($x);
                        if ($x ne $hname) {
                          print $temp_hlist_ptr "$x\n";
                        }
                      }
                      copy($temp_hlist, $HOSTLIST) or die "Copy failed: $temp_hlist to $HOSTLIST $!";
                      unlink($temp_hlist);
                    } else {
                      print "\nDo you want to configure SSH for user $usern on $hname [y/n] ";
                      #$AutoLoginCheck = "y";
                      $AutoLoginCheck = <STDIN>;
                      chomp($AutoLoginCheck);
                      #print "$AutoLoginCheck";
                        if ($AutoLoginCheck =~ /^[Y|YES]$/i) {
                          #print "Inhere1\n";
                          configureSSH($hname);
                          if ( $? != 0 ) {
                                  @tmp = readFileToArray($HOSTLIST);
                            $temp_hlist = catfile($INPUTDIR,"o_host_list.out");
                            open(my $temp_hlist_ptr, '>>', $temp_hlist) or die "Could not open file '$temp_hlist' $!";
                            foreach my $x (@tmp) {
                              chomp($x);
                              if ($x ne $hname) {
                                print $temp_hlist_ptr "$x\n";
                              }
                            }
                            copy($temp_hlist, $HOSTLIST) or die "Copy failed: $temp_hlist to $HOSTLIST $!";
                            unlink($temp_hlist);
                                }
                        }
                        elsif ($AutoLoginCheck =~ /^[N|NO]$/i) {
                          #print "Inhere2\n";
                            print "\nWe can configure ssh only for this run and reverse the changes back. do you want to continue?[y/n] ";
                              #$tmpSshConf = "y";
                              $tmpSshConf = <STDIN>;
                              chomp($tmpSshConf);
                              
                                if ($tmpSshConf =~ /^[Y|YES]$/i) { 
                                  #print "Inhere3\n";
                                    configureSSH($hname); 
                                      if ( $? != 0 ) {
                                      @tmp = readFileToArray($HOSTLIST);
                                $temp_hlist = catfile($INPUTDIR,"o_host_list.out");
                                open(my $temp_hlist_ptr, '>>', $temp_hlist) or die "Could not open file '$temp_hlist' $!";
                                foreach my $x (@tmp) {
                                  chomp($x);
                                  if ($x ne $hname) {
                                    print $temp_hlist_ptr "$x\n";
                                  }
                                }
                                copy($temp_hlist, $HOSTLIST) or die "Copy failed: $temp_hlist to $HOSTLIST $!";
                                unlink($temp_hlist);
                                    } else {
                                          push @hnameArr, $hname;
                                      }
                                }
                                elsif ($tmpSshConf =~ /^[N|NO]$/i) { 
                                  #print "Inhere4\n";
                                    if ( $hname eq $localnode ) {
                                          print "\nWithout ssh user equivalency program is executed only on localnode $localnode\n";
                                        `echo $localnode >$HOSTLIST`;
                                      } else {
                                          print "\nWithout ssh user eqivalency, program is not executed on $hname\n";
                                          @tmp = readFileToArray($HOSTLIST);
                                $temp_hlist = catfile($INPUTDIR,"o_host_list.out");
                                open(my $temp_hlist_ptr, '>>', $temp_hlist) or die "Could not open file '$temp_hlist' $!";
                                foreach my $x (@tmp) {
                                  chomp($x);
                                  if ($x ne $hname) {
                                    print $temp_hlist_ptr "$x\n";
                                  }
                                }
                                copy($temp_hlist, $HOSTLIST) or die "Copy failed: $temp_hlist to $HOSTLIST $!";
                                unlink($temp_hlist);
                                       }
                                  }
                                else {
                                      configureSSH($hname); 
                                      push @hnameArr, $hname;
                                  }
                              
                          }
                          else {
                            #print "Inhere5\n";
                                configureSSH($hname); 
                                  if ( $? != 0 ) {
                                  @tmp = readFileToArray($HOSTLIST);
                            $temp_hlist = catfile($INPUTDIR,"o_host_list.out");
                            open(my $temp_hlist_ptr, '>>', $temp_hlist) or die "Could not open file '$temp_hlist' $!";
                            foreach my $x (@tmp) {
                              chomp($x);
                              if ($x ne $hname) {
                                print $temp_hlist_ptr "$x\n";
                              }
                            }
                            copy($temp_hlist, $HOSTLIST) or die "Copy failed: $temp_hlist to $HOSTLIST $!";
                            unlink($temp_hlist);
                                   }
                          }
                      
                    }
                }     
        } elsif ($hname ne $localnode) {
          @tmp = readFileToArray($HOSTLIST);
                $temp_hlist = catfile($INPUTDIR,"o_host_list.out");
                open(my $temp_hlist_ptr, '>>', $temp_hlist) or die "Could not open file '$temp_hlist' $!";
                foreach my $x (@tmp) {
                  chomp($x);
                  if ($x ne $hname) {
                    print $temp_hlist_ptr "$x\n";
                  }
                }
                copy($temp_hlist, $HOSTLIST) or die "Copy failed: $temp_hlist to $HOSTLIST $!";
                unlink($temp_hlist);
        }
      }
    }
  }
  #ssh setup ends  here and not to change 

  if ($#hnameArr != -1) {
    open(my $remssh_nodes, '>>', "tfa_ssh_nodes") or die "Could not open file tfa_ssh_nodes $!";
    foreach my $x (@hnameArr) {
      print $remssh_nodes "$x\n";
    }
  }
}

if ( -e "java_install.out" ) {
  @tmp = readFileToArray("java_install.out");
  foreach my $x (@tmp) {
    chomp($x);
    push @MASTERFIL_ARRAY, "$x";
  }
}

my @hlist_arr = readFileToArray($HOSTLIST);
foreach my $host (@hlist_arr) {
  if ( -d "/opt/oracle.SupportTools/onecommand" ) {
      push @MASTERFIL_ARRAY, "$host.OS.user_dump_dest=/opt/oracle.oswatcher/osw/archive";
      push @MASTERFIL_ARRAY, "$host.OS.user_dump_dest=/opt/oracle.SupportTools/onecommand/tmp";
  }

  if ( -d "/opt/oracle.ExaWatcher/archive" ) {
      push @MASTERFIL_ARRAY, "$host.OS.user_dump_dest=/opt/oracle.ExaWatcher/archive";
  }
}

my $invntr_CH;
my $invntr_location;
my $RAT_INV_LOC;
my $SILENT = 1;

my $crs_counter = 0;
my @crs_installed;
my $localhost = $HOSTNAME;

is_crs_installed();

my $v_oratab;
my @rdbms_installed;
my $local_invntr_OH;
my $oratab_OH;
my $RAT_ORACLE_HOME;
my $what_db;

if ($is_crs_up == 0) {
  #check if any db is present and discover the related DB directories
  is_rdbms_installed();
}

my $offline_counter = 0;
my $CRS_ACTIVE_VERSION;

@tmp = grepPatternFromArray(\@MASTERFIL_ARRAY, "CRS_ACTIVE_VERSION");
@tmp = cut_df_from_array(\@tmp, "=", 2);
$CRS_ACTIVE_VERSION = $tmp[0];

my ($crs121,$crs122,$crs112) = (0,0,0);
if ($CRS_ACTIVE_VERSION =~ m/12\.1/) {
  $crs121 = 1;
} elsif ($CRS_ACTIVE_VERSION =~ m/12\.2/) {
    $crs122 = 1;
} elsif ($CRS_ACTIVE_VERSION =~ m/11\.2/) {
    $crs112 = 1;
}

my %asm_installed;
my %stack_asm_up;
my %stack_asm_sid;
my %stack_asm_home;
my %stack_asm_version;
@tmp = @MASTERFIL_ARRAY;

foreach my $node (readFileToArray($HOSTLIST)) {
  chomp($node);
  @tmp1 = grepPatternFromArray(\@tmp, "$node.ASM_INSTALLED");
  @tmp1 = cut_df_from_array(\@tmp1, "=", 2);
  $asm_installed{$node} = trimString("$tmp1[0]");
  chomp($asm_installed{$node});
  @tmp1 = grepPatternFromArray(\@tmp, "$node.ASM_STATUS");
  @tmp1 = cut_df_from_array(\@tmp1, "=", 2);
  $stack_asm_up{$node} = trimString("$tmp1[0]");
  chomp($stack_asm_up{$node});
  @tmp1 = grepPatternFromArray(\@tmp, "$node.ASM_INSTANCE");
  @tmp1 = cut_df_from_array(\@tmp1, "=", 2);
  $stack_asm_sid{$node} = trimString("$tmp1[0]");
  chomp($stack_asm_sid{$node});
  @tmp1 = grepPatternFromArray(\@tmp, "$node.$stack_asm_sid{$node}.VERSION");
  @tmp1 = cut_df_from_array(\@tmp1, "=", 2);
  $stack_asm_version{$node} = trimString("$tmp1[0]");
  chomp($stack_asm_version{$node});
  @tmp1 = grepPatternFromArray(\@tmp, "ASM_HOME");
  @tmp1 = cut_df_from_array(\@tmp1, "=", 2);
  $stack_asm_home{$node} = trimString("$tmp1[0]");
  chomp($stack_asm_home{$node});
}

#foreach my $node (keys %stack_asm_up) {
# print "$stack_asm_up{$node} : $stack_asm_sid{$node} : $stack_asm_version{$node} : $stack_asm_home{$node} ";
#}

write_asm_version_master();

my @installed_DBs;
my @running_DBs;
my %running_DB_config;

if ($is_crs_up == 1 ) {
  my @sfile_arr = @MASTERFIL_ARRAY;
  @sfile_arr = grepPatternFromArray(\@sfile_arr, "ISDBRUNNING");
  
  my $db_instance_name;
  my $db_home;
  my $db_user;
  my $dbname;
  my $count = 1;
  print "Searching for running databases...\n";
  foreach my $line (@sfile_arr) {
    if ($line =~ /(.*)\.ISDBRUNNING=1/) {
      $dbname = $1;
      push @running_DBs, $dbname;
      print "$count\. $dbname\n";
      $count = $count + 1;

      foreach my $x (@MASTERFIL_ARRAY) {
        if ($x =~ /$HOSTNAME\.$dbname\.INSTANCE_NAME=(.*)/) {
          $db_instance_name = $1;
        } elsif ($x =~ /DB_NAME=$dbname/) {
          $db_home = (split /\|/, $x)[-1];
        } elsif (length($db_home) != 0 && $x =~ /\QRDBMS_ORACLE_HOME=$db_home/) {
          $db_user = (split /\|/, $x)[-2];
        }
      }

      $running_DB_config{$dbname} = $db_instance_name . "|" . $db_home . "|" . $db_user if ( $db_instance_name ne "" );
      #print "$dbname ==> " . $running_DB_config{$dbname} . "\n";
    }
  }
  print "\n\nSearching out ORACLE_HOME for selected databases...\n\n";
} else {  #FOR SINGLE INSTANCE
  if ($IS_WIN) {
    print "Searching for running databases...\n";      
    my $count = 1;
    my $command = "sc query | findstr OracleService | findstr SERVICE_NAME";
    my $output = `$command`;

    my @db_services = ();
    foreach my $line (split /\n/, $output) {
      my $svc_name = (split /: /, $line)[1];
      push @db_services, $svc_name;
    }

    #printArr(\@db_services);

    my $cmd;
    my $output;
    # -------------------------------
    foreach my $svc_name (@db_services) {
      chomp($svc_name);
      my $db_sid = $svc_name;
      $db_sid =~ s/OracleService//g;
      #print "DB SID: $db_sid\n";      
      print "$count\. $db_sid\n";

      $cmd = "sc qc $svc_name | findstr BINARY_PATH_NAME";
      $output = `$cmd`;

      my $dboh = (split /\s{1,}:\s{1,}/, $output)[1];
      $dboh = (split /\s{1,}/, $dboh)[0];
      $dboh =~ s/bin\\ORACLE.EXE//g;
      #print "DBHome: $dboh\n";
      $ENV{ORACLE_HOME} = $dboh;

      if (testSQLWin($db_sid, $dboh, $db_sid) == 1) {
        $running_DB_config{$db_sid . ":" . $db_sid} = $db_sid . "|" . $dboh . "|";    #since in SI, dbname is same as the instance name
      }
      $count = $count + 1; 
    } # end foreach @db_services
    # -------------------------------
    print "\n\nSearching out ORACLE_HOME for selected databases...\n\n";
  } else {
    print "Searching for running databases...\n";
    my $cmd = "ps -ef |grep ora_pmon|grep -v grep";
    print "CMD: $cmd\n" if ( $debug );
    my $sids = `$cmd`;
    my $db_sid;
    my $db_home;
    my $db_user;
    my $db_name;
    my $pid;
    my $count = 1;

    my @tmp;
    my $outcmd;

    foreach my $line (split /\n/, $sids) {
      if ( $line =~ /.*ora_pmon_(.*)/ ) {
        $db_sid = $1;
      }
      $db_name = $db_sid;   #since in SI, dbname is same as the instance name
      print "$count\. $db_name\n";
      if ( $line =~ /\w+\s+([0-9]+)\s+.*/ ) {
        $pid = $1;
      }

      if ( not $is_this_ade ) {
        if ($PLATFORM eq "aix" ) {
         $cmd = "procmap $pid | grep lib | grep -v usr | awk '{print \$NF}'";
        } else { 
          $cmd = "pmap -help"; 
          $outcmd = `$cmd 2>&1`;
          if ( $outcmd =~ /\-\-show\-path/ ) {
            $cmd = "pmap -p $pid | grep oracle | grep -v grep | awk '{print \$NF}'";
          } else {
            $cmd = "pmap $pid | grep oracle | grep -v grep | awk '{print \$NF}'";
          } 
        }
      } else {
         $cmd = "ps -ef |grep '$db_sid/oracle/bin/ocssd'| grep -v grep | awk '{print \$NF}'";
      }

      # pmap may not shwo the info required so check if id has the value ..
      print "CMD: $cmd\n" if ( $debug );
      $db_home = `$cmd`;
      @tmp = split /\n/, $db_home;
      $db_home = $tmp[0];
      if ( $db_home =~ /bin\/oracle/ ) {
         print "pmap found the oracle executable path \n" if ( $debug );
      } elsif ( $PLATFORM eq "aix"  && $db_home =~ /lib\/lib.*\.so/ ) {
         print "procmap found the oracle executable path \n" if ( $debug );
      } else {
         print "pmap did not find the oracle executable path \n" if ( $debug );
         if ($PLATFORM eq "linux" and length($pid)) {
            $cmd = "/usr/bin/readlink /proc/$pid/exe";
            $db_home = `$cmd`;
            if ( $db_home =~ /bin\/oracle/ ) {
               print "readlink found the oracle executable path \n" if ( $debug );
            } else {
               print "readlink did not find the oracle executable path \n" if ( $debug );
               print "Skipping sid $db_sid as unable to find ORCLE_HOME \n" if ( $debug );
               next;
            }
         } else {
            print "Skipping sid $db_sid as unable to find ORCLE_HOME \n" if ( $debug );
            next;
         }
      }
      $db_home =~ s/\/bin\/oracle//g;
      $db_home =~ s/\/bin\/ocssd//g;
      $db_home =~ s/\/lib\/.*//g;
      print "DBHOME found $db_home \n" if ( $debug );
      chomp($db_home);

      if ( $line =~ /(\w+)\s+[0-9]+\s+.*/ ) {
        $db_user = $1;
      }
      if ($is_this_ade) {
         $db_home = catdir("","ade","$db_user" ."_" . $db_name,"oracle");
      }
      print "DETAILS: $db_name $db_sid $db_home $db_user $pid\n" if ( $debug );
      $running_DB_config{$db_name} = $db_sid . "|" . $db_home . "|" . $db_user;
      print "Added Running DBConf:" . $running_DB_config{$db_name} . ".\n" if ( $debug );
      $count = $count + 1;
    }
    print "\n\nSearching out ORACLE_HOME for selected databases...\n\n";
  }
}

foreach my $db (keys %running_DB_config) {
  my $sid = (split /\|/, $running_DB_config{$db})[0];
  my $home = (split /\|/, $running_DB_config{$db})[1];
  my $user = (split /\|/, $running_DB_config{$db})[2];
  my $pdb_list = getPDBs($db, $sid, $home, $user);

  if ($pdb_list ne "") {
    my $pdbline = $db . ".PDBS=" . $pdb_list . "\n";
    push @MASTERFIL_ARRAY, "$pdbline";
  }
}

mb_rdbms_stack_status();

my $tfile = catfile($OUTPUTDIR, "$$.tfadirs.txt");
my $sfile = $MASTERFIL;
my $obase_dirs = "";
my @sfile_arr = @MASTERFIL_ARRAY;
@sfile_arr = grepPatternFromArray(\@sfile_arr, "RDBMS_ORACLE_HOME");
@sfile_arr = cut_df_from_array(\@sfile_arr, "=", 2);
foreach my $temp (@sfile_arr) {
  $temp =~ s/^\s+//g;
  $temp =~ s/\s+$//g;
}
@sfile_arr = cut_df_from_array(\@sfile_arr, '\|', 1);

my $loc;
my $obase_dir = "";
my $obase_dirs = "";
my $OH_dbOwner;
my $command;
foreach my $dir (@sfile_arr) {
  if ( not exists $base_for_homes{$dir} ) {
    if ( -d $dir ) {
      $ENV{"ORACLE_HOME"} = $dir;
      $ENV{"LD_LIBRARY_PATH"} = catfile($ENV{"ORACLE_HOME"}, "lib");
  
      if ($IS_WIN) {
        $loc = catfile($ENV{"ORACLE_HOME"}, "BIN", "oracle.exe");
        @tmp = `dir /Q $loc`;
        $OH_dbOwner = $tmp[5];
        $OH_dbOwner =~ s/\s+/ /g;
        @tmp = split / /, $OH_dbOwner;
        $OH_dbOwner = $tmp[4];
        @tmp = split /\\/, $OH_dbOwner;
        $OH_dbOwner = $tmp[-1];
  
        #system("runas /savecred /user:$OH_dbOwner cmd.exe");     #DOUBT need to be logged in as OH DB OWNER
        $loc = catfile($ENV{ORACLE_HOME},"BIN","orabase.exe");
        if ( -e $loc ) {
          $obase_dir = `$loc`;
        }
        #print $obase_dirs;
      } else {
        $loc = catfile($ENV{"ORACLE_HOME"}, "bin", "oracle");
        $OH_dbOwner = `ls -l $loc`;
        @tmp = split " ", $OH_dbOwner;
        $OH_dbOwner = $tmp[2];
  
        $loc = catfile($ENV{"ORACLE_HOME"}, "bin", "orabase");
        if ( -e $loc ) {
          $command = tfactlshare_checksu($OH_dbOwner ,"$loc");
          print "ORABASE Command: $command\n" if ( $debug );
          $obase_dir = `$command`;
          print "OBASEDIR : $obase_dir\n" if ( $debug );
        }
      }
      chomp($obase_dir);
      if ( length("$obase_dir") && $obase_dirs !~ /\Q$obase_dir/ ) {
         $obase_dirs = $obase_dirs." ".$obase_dir;
      }
    }
  }
}
foreach my $ohdir ( keys %base_for_homes ) {
  $obase_dir = $base_for_homes{$ohdir};
  chomp($obase_dir);
  if ( length("$obase_dir") && $obase_dirs !~ /\Q$obase_dir/ ) {
     $obase_dirs = $obase_dirs." ".$obase_dir;
  }
} 

$obase_dirs =~ s/^\s+//g;
$obase_dirs =~ s/\s+$//g;
my $ORACLE_BASE = $obase_dirs;
my $SSH_STATUS;

my $perlsrc;
if ( $perl ) {
   $perlsrc = $perl;
} elsif ( -f catfile($RAT_CRS_HOME, "perl", "bin", "perl.exe") ) {
   $perlsrc = catfile($RAT_CRS_HOME, "perl", "bin", "perl.exe")
} elsif ( -f $ENV{"PERL"} && $IS_WIN ) {
   $perlsrc = $ENV{"PERL"};
}

my $text = "";
my $line2w;
my $inst_name;
my $db_name;
my @trc_cpy;
my $count = 0;
my $writeFlag = 0;
my @write_arr;
my @trace_dirs;
my $cmd;
my $remoteDir;
my $remotetFile;
my $remotetFile_op;
my $remotetempDir;
foreach my $dir (split / /, $obase_dirs) {
  $count = 0;
  if ( -e $dir ) {
    $dir = catdir($dir,"diag");
    @trace_dirs = findFilesWithPatternInArray($dir, "trace\$");
    printArr(\@trace_dirs) if ( $debug );
  }

  foreach my $trc (@trace_dirs) {
    chomp($trc);
    my $comp = "";

    if ( $trc =~ /diag\/asm\/+asm/ ) { $comp = "ASM"; }
    elsif ( $trc =~ /diag\/rdbms/ ) { $comp = "RDBMS"; }
    elsif ( $trc =~ /diag\/apx/ ) { $comp = "ASMPROXY"; }
    elsif ( $trc =~ /diag\/ios/ ) { $comp = "ASMIO"; }
    elsif ( $trc =~ /diag\/clients/ ) { $comp = "DBCLIENT"; }
    elsif ( $trc =~ /diag\/asmtool/ ) { $comp = "ASMTOOL"; }
    elsif ( $trc =~ /diag\/asm\/user/ ) { $comp = "ASMCLIENT"; }
    elsif ( $trc =~ /listener/ ) { $comp = "TNS"; }

    @trc_cpy = split "/",$trc;
    $inst_name = $trc_cpy[-2];
    $db_name = $trc_cpy[-3];
    if ( length("$comp") != 0 ) {
      $count++;
      if ( $comp eq "ASM" ) {
          $line2w = "$localhost.$comp|$inst_name.background_dump_dest=$trc";
      } elsif ( $comp eq "TNS" ) {
          $line2w = "$localhost.$comp|TNS.background_dump_dest=$trc";
      } elsif ( $comp eq "RDBMS" ) {
          $line2w = "$localhost.$comp|$db_name|$inst_name.background_dump_dest=$trc";
      } elsif ( $comp eq "ASMPROXY" ) {
          $line2w = "$localhost.$comp|$db_name|$inst_name.background_dump_dest=$trc";
      } elsif ( $comp eq "ASMIO" ) {
          $line2w = "$localhost.$comp|$db_name|$inst_name.background_dump_dest=$trc";
      } elsif ( $comp eq "DBCLIENT" ) {
          $line2w = "$localhost.$comp|$db_name|$db_name.background_dump_dest=$trc";
      } elsif ( $comp eq "ASMCLIENT" ) {
          $line2w = "$localhost.$comp|$db_name|$db_name.background_dump_dest=$trc";
      } elsif ( $comp eq "ASMTOOL" ) {
          $line2w = "$localhost.$comp|$db_name|$db_name.background_dump_dest=$trc";
      }

      push @write_arr, $line2w;
    }
    print "$count : $line2w : $trc : $comp\n" if ( $debug );
  }
}

printArr(\@write_arr) if ( $debug ) ;
@write_arr = array_uniq_elem(@write_arr);
$count = 0;
@mfile_arr = @MASTERFIL_ARRAY;
foreach my $line (@write_arr) {
  $writeFlag = 0;
  foreach my $x (@mfile_arr) {
    if ($x eq $line) { $writeFlag = 1; }
  }

  if ( $writeFlag == 0 ) {
    $count++;
      push @MASTERFIL_ARRAY, "$line";
    }
}

# Core Dump Files
my $cdump_dirs = $obase_dirs;
my $cdump_crs_base;
my $cdump_crs_home;
my $cdump_crs_config;
@mfile_arr = @MASTERFIL_ARRAY;
@mfile_arr = grepPatternFromArray(\@mfile_arr, "ORACLE_BASE=");
if ( $#mfile_arr != -1 ) {
  @tmp = split /=/, $mfile_arr[0];
  $cdump_crs_base = $tmp[1];
  $cdump_crs_base =~ s/^\s+//g;
  $cdump_crs_base =~ s/\s+$//g;
  chomp($cdump_crs_base);
}

if ( ! -d "$cdump_crs_base" ) {
  @mfile_arr = @MASTERFIL_ARRAY;
  @mfile_arr = grepPatternFromArray(\@mfile_arr, "CRS_HOME=");

  if ( $#mfile_arr != -1 ) {
    @tmp = split /=/, $mfile_arr[0];
    $cdump_crs_home = $tmp[1];
    $cdump_crs_home =~ s/^\s+//g;
    $cdump_crs_home =~ s/\s+$//g;
    chomp($cdump_crs_home);
  }

  if ( -d "$cdump_crs_home" ) {
    $cdump_crs_config = $cdump_crs_home."/crs/install/crsconfig_params";
    if ( -e "$cdump_crs_config" ) {
      @file_arr = readFileToArray($cdump_crs_config);
      @file_arr = grepPatternFromArray(\@file_arr, "ORACLE_BASE=");
      if ( $#file_arr != -1 ) {
        @tmp = split /=/, $file_arr[0];
        $cdump_crs_base = $tmp[1];
        $cdump_crs_base =~ s/^\s+//g;
        $cdump_crs_base =~ s/\s+$//g;
        chomp($cdump_crs_base);
      }
      if ( -d "$cdump_crs_base" ) {
        $cdump_dirs = $cdump_dirs." ".$cdump_crs_base;
      }
    }
  }
} else {
  $cdump_dirs = $cdump_dirs." ".$cdump_crs_base;
}

$cdump_dirs =~ s/^\s+//g;
$cdump_dirs =~ s/\s+$//g;
undef @write_arr;
$count = 0;
my @cdumpdirs;
foreach my $dir (split / /, $cdump_dirs) {
  $count = 0;
  if ( -e $dir ) {
    $dir = catdir($dir,"diag");
    @cdumpdirs = findFilesWithPatternInArray($dir, "cdump\$");
    print "cdump dirs :\n" if ( $debug );
    printArr(\@cdumpdirs) if ( $debug );
  }

    #print "$host\n";
  foreach my $trc (@cdumpdirs) {
    chomp($trc);
    my $comp = "";

    if ( $trc =~ /diag\/asm\/\+asm/ ) { $comp = "ASM"; }
    elsif ( $trc =~ /diag\/rdbms/ ) { $comp = "RDBMS"; }
    elsif ( $trc =~ /diag\/crs/ ) { $comp="CRS"; }
    elsif ( $trc =~ /diag\/apx/ ) { $comp = "ASMPROXY"; }
    elsif ( $trc =~ /diag\/ios/ ) { $comp = "ASMIO"; }
    elsif ( $trc =~ /diag\/clients/ ) { $comp = "DBCLIENT"; }
    elsif ( $trc =~ /diag\/asmtool/ ) { $comp = "ASMTOOL"; }
    elsif ( $trc =~ /diag\/asm\/user/ ) { $comp = "ASMCLIENT"; }
    elsif ( $trc =~ /listener/ ) { $comp = "TNS"; }

    @trc_cpy = split "/",$trc;
    $inst_name = $trc_cpy[-2];
    $db_name = $trc_cpy[-3];
    if ( length("$comp") != 0 ) {
      $count++;
      if ( $comp eq "ASM" ) {
          $line2w = "$localhost.$comp|$inst_name.background_dump_dest=$trc";
      } elsif ( $comp eq "TNS" ) {
          $line2w = "$localhost.$comp|TNS.background_dump_dest=$trc";
      } elsif ( $comp eq "CRS" ) {
    $line2w = "$localhost.$comp.background_dump_dest=$trc";
      } elsif ( $comp eq "RDBMS" ) {
          $line2w = "$localhost.$comp|$db_name|$inst_name.background_dump_dest=$trc";
      } elsif ( $comp eq "ASMPROXY" ) {
          $line2w = "$localhost.$comp|$db_name|$inst_name.background_dump_dest=$trc";
      } elsif ( $comp eq "ASMIO" ) {
          $line2w = "$localhost.$comp|$db_name|$inst_name.background_dump_dest=$trc";
      } elsif ( $comp eq "DBCLIENT" ) {
          $line2w = "$localhost.$comp|$db_name|$db_name.background_dump_dest=$trc";
      } elsif ( $comp eq "ASMCLIENT" ) {
          $line2w = "$localhost.$comp|$db_name|$db_name.background_dump_dest=$trc";
      } elsif ( $comp eq "ASMTOOL" ) {
          $line2w = "$localhost.$comp|$db_name|$db_name.background_dump_dest=$trc";
      }

      push @write_arr, $line2w;
    }
    #print "$count : $line2w : $trc : $comp\n";
  }
}

#printArr(\@write_arr);
@write_arr = array_uniq_elem(@write_arr);
$count = 0;
@mfile_arr = @MASTERFIL_ARRAY;
foreach my $line (@write_arr) {
  $writeFlag = 0;
  foreach my $x (@mfile_arr) {
    if ($x eq $line) { $writeFlag = 1; }
  }

  if ( $writeFlag == 0 ) {
    $count++;
      push @MASTERFIL_ARRAY, "$line";
    }
}

# RDBMS install logs 
my @collectionArray; 
my @obase_dirs_arr = split / /, $ORACLE_BASE; 
if ( length("$ORACLE_BASE") != 0 && $#obase_dirs_arr == 0 ) { 
    push @collectionArray, "CFGTOOLS=$ORACLE_BASE/cfgtoollogs"; 
} 
foreach my $dboh (@sfile_arr) { 
    chomp($dboh); 
    print "Adding Install Logs for DBHOME: $dboh \n" if ( $debug ); 
    if (length $dboh ) { 
      push @collectionArray, "CFGTOOLS=$dboh/cfgtoollogs"; 
      push @collectionArray, "INSTALL=$dboh/install"; 
    } 
} 

my $CRS_HOME = $RAT_CRS_HOME;
my $CRS_BASE;
my $found_crs_adr = 0;
my $found_crs_acfs = 0;

if ( length("$CRS_HOME") != 0 ) {
    $ENV{"ORACLE_HOME"} = $CRS_HOME;
    $ENV{"LD_LIBRARY_PATH"} = catfile($ENV{"ORACLE_HOME"}, "lib");
    my $cmd;
    if ($IS_WIN) {
      $cmd = catfile($CRS_HOME, "bin", "orabase.exe");
    }else{
      $cmd = catfile($CRS_HOME, "bin", "orabase");
    }
    
    $CRS_BASE = `$cmd`;
    chomp($CRS_BASE);
    #print "crs base = $CRS_BASE\n";
    if ( -d "$CRS_BASE" ) {
      $loc = catdir($CRS_BASE,"diag","crs",$localhost,"crs","trace");
      if ( -d $loc ) {
          $found_crs_adr = 1;
      }

      $loc = catdir($CRS_BASE,"crsdata",$localhost,"acfs");
      if ( -d $loc ) {
          $found_crs_acfs = 1;
      }
    }
}

print "\nGetting Oracle Inventory...\n";
my $ORACLE_INVENTORY;
my $RAT_INV_LOC;
if ( length("$RAT_INV_LOC") != 0 ) {
    $ORACLE_INVENTORY = $RAT_INV_LOC;
} else {
  if ( $IS_WIN ) {
    $ORACLE_INVENTORY = tfactlwin_query_registry("inst_loc");
    #$ORACLE_INVENTORY =~ s// /g;
    @tmp = split /\s{2,}/, $ORACLE_INVENTORY;
    $ORACLE_INVENTORY = $tmp[-1];
  } elsif ( -e "/etc/oraInst.loc" ) {
    @tmp = readFileToArray("/etc/oraInst.loc");
    @tmp = removePatternFromArray(\@tmp, "^#");
    @tmp = grepPatternFromArray(\@tmp, "inventory_loc");
    @tmp = cut_df_from_array(\@tmp, "=", 2);
    $ORACLE_INVENTORY = $tmp[0];
    chomp($ORACLE_INVENTORY);
  } elsif ( -e "/var/opt/oracle/oraInst.loc" ) {
    @tmp = readFileToArray("/var/opt/oracle/oraInst.loc");
    @tmp = removePatternFromArray(\@tmp, "^#");
    @tmp = grepPatternFromArray(\@tmp, "inventory_loc");
    @tmp = cut_df_from_array(\@tmp, "=", 2);
    $ORACLE_INVENTORY = $tmp[0];
    chomp($ORACLE_INVENTORY);
    }
}
chomp($ORACLE_INVENTORY);
print "\nORACLE INVENTORY: $ORACLE_INVENTORY\n\n";

if ( length("$CRS_HOME") != 0 ) {
  push @collectionArray, "CFGTOOLS=".catdir($CRS_BASE,"cfgtoollogs");
  push @collectionArray, "INSTALL=".catdir($CRS_HOME,"install");
  push @collectionArray, "CFGTOOLS=".catdir($CRS_HOME,"cfgtoollogs");
  push @collectionArray, "ASM=".catdir($CRS_HOME,"rdbms","log");
  push @collectionArray, "DBWLM=".catdir($CRS_HOME,"oc4j","j2ee","home","log") if -d catdir($CRS_HOME,"oc4j","j2ee","home","log");
  push @collectionArray, "CRS=".catdir($CRS_HOME,"crf","db",$localhost);
}

if ( length("$ORACLE_INVENTORY") != 0 ) {
    push @collectionArray, "INSTALL=".catdir($ORACLE_INVENTORY,"ContentsXML");
    push @collectionArray, "INSTALL=".catdir($ORACLE_INVENTORY,"logs");
}

if ( length("$CRS_HOME") != 0 ) {
  push @collectionArray, "CRS=".catdir($CRS_HOME,"cv","log");
  push @collectionArray, "CRS=".catdir($CRS_HOME,"opmn","logs");
  push @collectionArray, "CRS=".catdir($CRS_HOME,"OPatch","crs","log");
  push @collectionArray, "CRS=".catdir($CRS_HOME,"evm","log");
  push @collectionArray, "CRS=".catdir($CRS_HOME,"evm","admin","logger");
  push @collectionArray, "CRS=".catdir($CRS_HOME,"evm","admin","log");
  push @collectionArray, "CRS=".catdir($CRS_HOME,"racg","log");
  push @collectionArray, "CRS=".catdir($CRS_HOME,"scheduler","log");
  push @collectionArray, "CRS=".catdir($CRS_HOME,"srvm","log");
  push @collectionArray, "CRS=".catdir($CRS_HOME,"crs","log");
  push @collectionArray, "CRS=".catdir($CRS_HOME,"network","log");
  push @collectionArray, "CRS=".catdir($CRS_HOME,"css","log");
  push @collectionArray, "CRS=".catdir($CRS_HOME,"ccr","hosts","<host>","log");
  push @collectionArray, "INSTALL=".catdir($CRS_HOME,"inventory","ContentsXML");
}

#printArr(\@collectionArray);
#print "found_crs_adr = $found_crs_adr\nfound_crs_acfs = $found_crs_acfs\n";
my @tfile_arr;
my $temp_file;
my $temp_file_op;
my $remotetempFile;
my $remotetempFile_op;
my $dirc;
my $dir;
my @disc_dirs;
@hlist_arr = readFileToArray($HOSTLIST);

if ( $found_crs_adr == 1 ) {
  push @MASTERFIL_ARRAY, "$localhost.CRS.user_dump_dest=".catdir($CRS_BASE,"diag","crs",$localhost,"crs","trace");
  push @MASTERFIL_ARRAY, "$localhost.CRS.user_dump_dest=".catdir($CRS_BASE,"crsdata",$localhost,"output");
  push @MASTERFIL_ARRAY, "$localhost.CRS.user_dump_dest=".catdir($CRS_BASE,"crsdata",$localhost,"cvu");
  push @MASTERFIL_ARRAY, "$localhost.CRS.user_dump_dest=".catdir($CRS_BASE,"crsdata",$localhost,"evm");
  push @MASTERFIL_ARRAY, "$localhost.CRS.user_dump_dest=".catdir($CRS_BASE,"crsdata",$localhost,"crsconfig");
  push @MASTERFIL_ARRAY, "$localhost.ASM.user_dump_dest=".catdir($CRS_BASE,"crsdata",$localhost,"afd");
  push @MASTERFIL_ARRAY, "$localhost.CRS.user_dump_dest=".catdir($CRS_BASE,"crsdata",$localhost,"chad");
  push @MASTERFIL_ARRAY, "$localhost.CRS.user_dump_dest=".catdir($CRS_BASE,"crsdata",$localhost,"core");
  push @MASTERFIL_ARRAY, "$localhost.CRS.user_dump_dest=".catdir($CRS_BASE,"crsdata",$localhost,"crsdiag");
  push @MASTERFIL_ARRAY, "$localhost.CRS.user_dump_dest=".catdir($CRS_BASE,"crsdata",$localhost,"trace");
}

if ( $found_crs_acfs == 1 ) {
  push @MASTERFIL_ARRAY, "$localhost.ACFS.user_dump_dest=".catdir($CRS_BASE,"crsdata",$localhost,"acfs");
}

foreach my $dirl (@collectionArray) {
  @tmp = split /=/, $dirl;
  $dirc = $tmp[0];
  chomp($dirc);
  $dir = $tmp[1];
  $dir =~ s/<host>/$localhost/g;
  chomp($dir);
  if ( -d "$dir" ) {
    push @MASTERFIL_ARRAY, "$localhost.$dirc.user_dump_dest=$dir";
  }
}

#unlink($tfile);
my $oswdir_w = "";
my $oswpid;
my $oswdir;
my $oswdir_w;
my $temp_file = catfile($OUTPUTDIR, "$$.temp.txt");
if ($IS_WIN) {

} else {
  `ps -ef | grep 'OSW[A-Za-z]*\.sh' > $tfile`;
  `ps -ef | grep 'OSW[A-Za-z]*\.sh'`;
  @tfile_arr = readFileToArray($tfile);
  #printArr(\@tfile_arr);
        #print "\n";
  if ($#tfile_arr != -1) {
    my $i = 0;
    foreach my $x (@tfile_arr) {
      $x =~ s/^\s+//;
        $x =~ s/\s+$//;
      @tmp = split / +/, $x;
      @tmp1[$i] = $tmp[1]."|".$tmp[-1];
      $i++;
    }

    foreach my $oswl (@tmp1) {
      chomp($oswl);
      @tmp = split /\|/,$oswl;
      $oswpid = $tmp[0];
      $oswdir = $tmp[1];
      if ( -d "$oswdir" && -d "$oswdir/oswtop" ) {
        $oswdir_w = $oswdir;
      } else {
        my $fd = catfile("", "proc", $oswpid, "fd");
	if ( -r "$fd" ) {
          `ls -l /proc/$oswpid/fd > $temp_file`;
          #`cat $temp_file`;
          #print "CHECK : $oswl\n";
          @tmp = readFileToArray($temp_file);
          foreach my $x (@tmp) {
            if ( $x =~ /OSW[A-Za-z\.]*/ ) {
              @tmp2 = split / +/, $x;
              $tmp2[-1] =~ s/OSW[A-Za-z\.]*/archive/g;
              $oswdir = $tmp2[-1];
            }
          }
          if ( -d "$oswdir" && -d "$oswdir/oswtop" ) {
            $oswdir_w = $oswdir;
          }
        }
      }
    }
  }
}

if ( length("$oswdir_w") != 0 ) {
  chomp($oswdir_w);
  push @MASTERFIL_ARRAY, "$localhost.OS.user_dump_dest=$oswdir_w";
#} else {
#   print "Could not discover OSWatcher directory.\n";
}

if (-d "/radump" ) {      #checks whether we are on ZDLRA   WINDOWS ADDRESS OF /radump unknown
  if ( -d "/dbfs_obdbfs/OSB/tmp" ) {
       push @MASTERFIL_ARRAY, "$localhost.ZDLRA.user_dump_dest=/dbfs_obdbfs/OSB/tmp";
  }
  if ( -d "/dbfs_obdbfs/OSB/backup/admin/log" ) {
       push @MASTERFIL_ARRAY, "$localhost.ZDLRA.user_dump_dest=/dbfs_obdbfs/OSB/backup/admin/log";
  }
  if ( -d "/usr/tmp" ) {
       push @MASTERFIL_ARRAY, "$localhost.ZDLRA.user_dump_dest=/usr/tmp";
  }
  if ( -d "/radump" ) {
       push @MASTERFIL_ARRAY, "$localhost.ZDLRA.user_dump_dest=/radump";
  }
}

my $ASMIO_DIR;
my $ASMPROXY_DIR;
my @diagDirs;
if ( -d $CRS_BASE ) {
  $ASMIO_DIR = catfile($CRS_BASE,"diag", "ios", "+ios"); 
  chomp($ASMIO_DIR);
  print "ASMIO_DIR : $ASMIO_DIR\n" if ( $debug );
  if ( -d $ASMIO_DIR ) {
    push @MASTERFIL_ARRAY, "$localhost.ASMIO.user_dump_dest=$ASMIO_DIR";
    print "Added ASMIO_DIR : $ASMIO_DIR to MASTERFIL_ARRAY\n" if ( $debug );
  }

  $ASMPROXY_DIR = catfile($CRS_BASE,"diag", "apx", "+apx");  
  chomp($ASMPROXY_DIR);
  print "ASMPROXY_DIR : $ASMPROXY_DIR\n" if ( $debug );
  if ( -d $ASMPROXY_DIR ) {
    push @MASTERFIL_ARRAY, "$localhost.ASMPROXY.user_dump_dest=$ASMPROXY_DIR";
    print "Added ASMPROXY_DIR : $ASMPROXY_DIR to MASTERFIL_ARRAY\n" if ( $debug );
  }
}

my $SRCHOME_VAL = $ENV{"SRCHOME"};   
my $T_WORK_VAL = $ENV{"T_WORK"};
my $ORACLE_SID;
if ( length("$SRCHOME_VAL") != 0 ) {
  chomp($SRCHOME_VAL);
  push @MASTERFIL_ARRAY, "localnode%RDBMS.$ORACLE_SID.$ORACLE_SID%DIAGDEST=$SRCHOME_VAL/log/diag";
  push @MASTERFIL_ARRAY, "localnode%RDBMS.$ORACLE_SID.$ORACLE_SID%DIAGDEST=$SRCHOME_VAL/work";

  if ( length("$T_WORK_VAL") != 0 ) {
    my $pattern = catfile($T_WORK_VAL, "*.ora");
    my @files = glob("$pattern");

    foreach my $x (@files) {
    	#print "$x\n";

    	if (-e $x) {
    	  @tmp = readFileToArray("$x");
    	  @tmp1 = grepPatternFromArray(\@tmp, "adr_base=");
    	  @tmp1 = find_and_replace_from_array(\@tmp, ".*adr_base=[[:space:]]*", "");
    	  foreach my $d (@tmp1) {
          chomp($d);
  	      push @MASTERFIL_ARRAY, "localnode%RDBMS.$ORACLE_SID.$ORACLE_SID%DIAGDEST=$d";
  	      push @MASTERFIL_ARRAY, "localnode%ADRBASE=$d";
    	  }

    	  @tmp1 = grepPatternFromArray(\@tmp, "diagnostic_dest");
    	  @tmp1 = find_and_replace_from_array(\@tmp, ".*diagnostic_dest[[:space:]]*=[[:space:]]*", "");
    	  foreach my $d (@tmp1) {
          chomp($d);
  	      push @MASTERFIL_ARRAY, "localnode%RDBMS.$ORACLE_SID.$ORACLE_SID%DIAGDEST=$d";
  	      push @MASTERFIL_ARRAY, "localnode%ADRBASE=$d";
    	  }
    	}
    }
  }
}

## GETTING AN ARRAY OF UNIQUE DISCOVERED DIRECTORIES.
@MASTERFIL_ARRAY = array_uniq_elem(@MASTERFIL_ARRAY);

open(my $mf, '>', $MASTERFIL) or die "Could not open file '$MASTERFIL' $!";
#printArr(\@MASTERFIL_ARRAY);
#write from array to file
foreach my $line (@MASTERFIL_ARRAY) {
  chomp($line);
  print $mf "$line\n";
}
close $mf;
print "\nDiscovery Complete...\n\n";

unlink $sqlFile if (-e $sqlFile);

if ($IS_WIN) {
  print "Cleaning Temporary Folders . . .\n";
  rmtree($WIN_TRANSFER_DIR) if -d $WIN_TRANSFER_DIR;
}
my $finalOutput = catfile($CHECKHOME, "ora_stack_status.out");
my $finalRunOutput = catfile($CHECKHOME, "run.out");

copy($MASTERFIL, $finalOutput) or die "Copy failed: $!";
if ( $debugFlag == 1 && -e $debugFileName ) {
  copy($debugFileName, $finalRunOutput) or die "Copy failed: $!";
}

my $perl = "perl";      

if ( $IS_WIN ) {
  my @defperl = split /\n/, `where perl 2>&1`;
  if ( length $perlsrc && -f $perlsrc ) {
    $perl = $perlsrc;
  } elsif ( @defperl ) {
    $perl = tfactlshare_getLatestPerl(@defperl);
    $perl = "perl" if not length $perl;
  } # end if length $perlsrc && -f $perlsrc
} else {
  if ( $is_this_ade && -f catfile("$ENV{ORACLE_HOME}","perl","bin","perl") ) {
    $perl = catfile($ENV{ORACLE_HOME},"perl","bin","perl");
  } elsif ( -f catfile("", "usr", "bin", "perl") ) {
    $perl = catfile("", "usr", "bin", "perl");
  }
} # end if $IS_WIN

$perl = abs_path($perl);
if ($perl =~ /\s{1,}/) {
  $perl = "\"" . $perl . "\"";
}
my $discover_ora_stack = catfile($TFA_HOME,"bin","discover_ora_stack.pl");
system("$perl $discover_ora_stack -tfahome $TFA_HOME -mode full -silent -out $finalOutput");

rmtree($INPUTDIR) if -d $INPUTDIR;
rmtree($OUTPUTDIR) if -d $OUTPUTDIR;

sub write_asm_version_master {
  print "In write_asm_version_master\n" if ( $debug );
  my @tmpArr;
  my $sqlplus_src;
  my $loc;
  my $OH_dbOwner;
  my $text1;
  my $ORACLE_HOME_cpy;
  
  if ($stack_asm_up{$localnode} == 1) {
    my $OLD_ORACLE_HOME = $ENV{"ORACLE_HOME"};
        my $OLD_ORACLE_SID = $ENV{"ORACLE_SID"};

        if ( length("$crs112") != 0 && $crs112 >= 1 ) {
          $ENV{"ORACLE_SID"} = $stack_asm_sid{$localnode};
          $ENV{"ORACLE_HOME"} = $RAT_CRS_HOME;
        } else {
          $ENV{"ORACLE_HOME"} = $stack_asm_home{$localnode};
          $ENV{"ORACLE_SID"} = $stack_asm_sid{$localnode};
        }
        if ( -d $ENV{"ORACLE_HOME"} ) {
          if ($IS_WIN) {
            $loc = catfile($ENV{"ORACLE_HOME"}, "BIN", "oracle.exe");
            @tmp = `dir /Q $loc`;
            $OH_dbOwner = $tmp[5];
            $OH_dbOwner =~ s/\s+/ /g;
            @tmp = split / /, $OH_dbOwner;
            $OH_dbOwner = $tmp[4];
            @tmp = split /\\/, $OH_dbOwner;
            $OH_dbOwner = $tmp[-1];
            #print "Oracle Home DB Owner: $OH_dbOwner\n";
          } else {
            $loc = catfile($ENV{"ORACLE_HOME"}, "bin", "oracle");
            $OH_dbOwner = `ls -l $loc`;
            @tmp = split " ", $OH_dbOwner;
            $OH_dbOwner = $tmp[2];
          }
        }

        my $host = $HOSTNAME;
        my $sqlplusexe; 
        if ($host =~ /\./) {
          #print "CHECK1\n";
        if ( -d $ENV{"ORACLE_HOME"}) {
           $ENV{"LD_LIBRARY_PATH"} = catfile($ENV{"ORACLE_HOME"},"lib");
           $ORACLE_HOME_cpy = $ENV{"ORACLE_HOME"};
           if ($IS_WIN) {
               $sqlplusexe = catfile($ORACLE_HOME_cpy,"bin","sqlplus.exe");
           } else {
               $sqlplusexe = catfile($ORACLE_HOME_cpy,"bin","sqlplus");
           }
           open(my $sql_fptr, '>', $sqlFile) or die "Could not open file '$sqlFile' $!";
           chown(0644,$sqlFile);
           print $sql_fptr "set feedback  off heading off lines 120\nselect substr(HOST_NAME,1,instr(HOST_NAME,'.',1)-1)||'.'||INSTANCE_NAME||'.VERSION='||VERSION from gv\$instance;\nquit\n";
           $text1 = tfactlshare_checksu($OH_dbOwner, "$sqlplusexe -S -L '/ as sysasm' @ $sqlFile", 1);
           print "CMD: $text1\n" if ( $debug );
           $text1 = osutils_runtimedcommand($text1,10,TRUE);
           print "OP: $text1\n" if ( $debug );
           chomp($text1);
           @tmpArr = split /\n/, $text1;
           foreach my $x (@tmpArr) {
             if ($x =~ "$localnode") {
               push @MASTERFIL_ARRAY, "$x";
             }
           }
           close $sql_fptr;
           open(my $sql_fptr, '>', $sqlFile) or die "Could not open file '$sqlFile' $!";
           chown(0644,$sqlFile);
           print $sql_fptr "set feedback  off heading off lines 120\nselect  substr(a.HOST_NAME,1,instr(a.HOST_NAME,'.',1)-1)||'.ASM|'|| a.INSTANCE_NAME||'.'|| b.name ||'='||b.value from gv\$instance a, gv\$parameter b where  a.inst_id = b.inst_id and lower(b.name) in ('diagnostic_dest', 'user_dump_dest', 'background_dump_dest');\nquit\n";
           $text1 = tfactlshare_checksu($OH_dbOwner, "$sqlplusexe -S -L '/ as sysasm' @ $sqlFile", 1);
           print "CMD: $text1\n" if ( $debug );
           $text1 = osutils_runtimedcommand($text1,10,TRUE);
           print "OP: $text1\n" if ( $debug );
           chomp($text1);
           @tmpArr = split /\n/, $text1;
           foreach my $x (@tmpArr) {
             if ($x =~ "$localnode") {
               push @MASTERFIL_ARRAY, "$x";
             }
           }
           close $sql_fptr;
        }
    } else {
      print "CHECK2\n$usern\n" if ( $debug );
        if ( -d $ENV{"ORACLE_HOME"}) {
           $ENV{"LD_LIBRARY_PATH"} = catfile($ENV{"ORACLE_HOME"},"lib");
           $ORACLE_HOME_cpy = $ENV{"ORACLE_HOME"};
  
           if ($IS_WIN) {
               $sqlplusexe = catfile($ORACLE_HOME_cpy,"bin","sqlplus.exe");
           } else {
               $sqlplusexe = catfile($ORACLE_HOME_cpy,"bin","sqlplus");
           }
           #print "ORACLE_HOME:$ENV{ORACLE_HOME}";
           open(my $sql_fptr, '>', $sqlFile) or die "Could not open file '$sqlFile' $!";
           chown(0644,$sqlFile);
           print $sql_fptr "set feedback  off heading off lines 120\nselect HOST_NAME||'.'||INSTANCE_NAME||'.VERSION='||VERSION from gv\$instance;\nquit\n";
           print "CMD: $text1\n" if ( $debug );
           $text1 = osutils_runtimedcommand($text1,10,TRUE);
           print "OP: $text1\n" if ( $debug );
           chomp($text1);
           @tmpArr = split /\n/, $text1;
           foreach my $x (@tmpArr) {
             if ($x =~ "$localnode") {
               push @MASTERFIL_ARRAY, "$x";
             }
           }
           close $sql_fptr;
           open(my $sql_fptr, '>', $sqlFile) or die "Could not open file '$sqlFile' $!";
           chown(0644,$sqlFile);
           print $sql_fptr "set feedback  off heading off lines 120\nselect a.HOST_NAME||'.ASM|'|| a.INSTANCE_NAME||'.'|| b.name ||'='||b.value from gv\$instance a, gv\$parameter b where  a.inst_id = b.inst_id and lower(b.name) in ('diagnostic_dest', 'user_dump_dest', 'background_dump_dest');\nquit\n";
           $text1 = tfactlshare_checksu($OH_dbOwner, "$sqlplusexe -S -L '/ as sysasm' @ $sqlFile", 1);
           print "CMD: $text1\n" if ( $debug );
           print "OP: $text1\n" if ( $debug );
           $text1 = osutils_runtimedcommand($text1,10,TRUE);
           chomp($text1);
           @tmpArr = split /\n/, $text1;
           foreach my $x (@tmpArr) {
             if ($x =~ "$localnode") {
               push @MASTERFIL_ARRAY, "$x";
             }
           }
           close $sql_fptr;
          }
        }
        $ENV{"ORACLE_HOME"} = $OLD_ORACLE_HOME;
        $ENV{"ORACLE_SID"} = $OLD_ORACLE_SID;
        $ENV{"LD_LIBRARY_PATH"} = catfile($ENV{"ORACLE_HOME"},"lib");
  }
  print "Out of write_asm_version_master\n" if ( $debug );
}

sub mb_rdbms_stack_status {
  print "In mb_rdbms_stack_status\n" if ( $debug );
  my @tmpArr;
  my $sqlplus_src;
  my $loc;
  my $OH_dbOwner;
  my $text1;
  my $ORACLE_HOME_cpy;
  my $dbconfig;
  my @tmp;
  my $db_home;
  my $db_sid;
  my $db_user;

  my $OLD_ORACLE_HOME = $ENV{"ORACLE_HOME"};
  my $OLD_ORACLE_SID = $ENV{"ORACLE_SID"};
  my $OLD_LD_LIBRARY_PATH = $ENV{"LD_LIBRARY_PATH"};
  my $orabaseexe = catfile($ENV{"ORACLE_HOME"},"bin","orabase");
  my $orabasedir;
  my $tracedir;
  my $orabasecmd;

  print "OLD HOME : $OLD_ORACLE_HOME SID : $OLD_ORACLE_SID LD_LIB : $OLD_LD_LIBRARY_PATH\n" if ( $debug ) ;

  foreach my $db (keys %running_DB_config) {
    $dbconfig = $running_DB_config{$db};
    @tmp = split /\|/, $dbconfig;
    $db_home = $tmp[1];
    $db_sid = $tmp[0];
    $db_user = $tmp[2];
    $ENV{"ORACLE_HOME"} = $db_home;
    $ENV{"ORACLE_SID"} = $db_sid;

    @tmp = split /:/, $db;
    $db = $tmp[0];
    
    print "DBCONFIG: $db_home $db_sid $db_user\n" if ( $debug );

    # Before accessing the database see if it's using default diagdest.
    
    if ( not exists $base_for_homes{$db_home} ) {
      if ($IS_WIN) { 
        $orabaseexe = catfile($db_home,"BIN","orabase.exe");
      } else {
        $orabaseexe = catfile($db_home,"bin","orabase");
      }
      if ( $is_this_ade ) {
        print "ADE - Connecting to DB for diagnostic dest\n" if ( $debug);
      } else {
        $orabasecmd = tfactlshare_checksu($db_user,$orabaseexe);
        print "Command to get orabase is : $orabasecmd\n" if ( $debug ) ;
        $orabasedir = osutils_runtimedcommand($orabasecmd,10,TRUE);
        chomp($orabasedir);
        print "$orabasedir is orabase for $db_home\n" if ( $debug ) ;
      }
      $base_for_homes{$db_home} = $orabasedir;
    }

    # Does this database have a trace directory in that base dir and have they been updated recently.
    my $defaulttrace = 0;
    $tracedir = catdir($base_for_homes{$db_home},"diag","rdbms",$db,$db_sid,"trace");
    if ( -d $tracedir ) {
      print "$tracedir exists for $db SID $db_sid\n" if ( $debug ) ;
      if ( $IS_WIN ) {
        print "$tracedir exists for $db SID $db_sid on Windows\n" if ( $debug ) ;
        $defaulttrace = 1;
      } else {
        my $filename = `ls -1tr $tracedir | tail -1`;
        chomp ($filename);
        $filename = catfile ($tracedir, $filename);
        my @status = (stat ($filename));
        # If stat fail, an empty list is returned 
        if ( @status ) {
          my $mtime = $status[9];
          my $ctime = time();
          my $time = ( $ctime - $mtime );
          if ( $time <= 1800 ) {
            $defaulttrace = 1;
          }
          print "\n\n $defaulttrace files found updated in last 30 mins in $tracedir\n\n" if ( $debug );
        } else {
          print "\n\n The $filename file could not be found or was unable to stat'ed it \n\n" if ( $debug );
        }
      }
    }

    if ( $defaulttrace ) {
      print "$tracedir exists and has been written in the last 30 minutes for $db SID $db_sid\n" if ( $debug ) ;
      my $line = $HOSTNAME . ".RDBMS|" . $db . "|$db_sid" . ".diagnostic_dest=" . $base_for_homes{$db_home};
      print "line to add to MASTERFIL : $line\n" if ( $debug ) ;
      push @MASTERFIL_ARRAY, "$line";
    } else {
      print "$tracedir does not exist for $db SID $db_sid\n" if ( $debug ) ;
      if ( -d $ENV{"ORACLE_HOME"} ) {
        if ($IS_WIN) {
          $loc = catfile($ENV{"ORACLE_HOME"}, "BIN", "oracle.exe");
          @tmp = `dir /Q $loc`;
          $OH_dbOwner = $tmp[5];
          $OH_dbOwner =~ s/\s+/ /g;
          @tmp = split / /, $OH_dbOwner;
          $OH_dbOwner = $tmp[4];
          @tmp = split /\\/, $OH_dbOwner;
          $OH_dbOwner = $tmp[-1];
          #print "Oracle Home DB Owner: $OH_dbOwner\n";
        } else {
          $loc = catfile($ENV{"ORACLE_HOME"}, "bin", "oracle");
          $OH_dbOwner = `ls -l $loc`;
          @tmp = split " ", $OH_dbOwner;
          $OH_dbOwner = $tmp[2];
        }
        my $sqlplusexe;
        $ENV{"LD_LIBRARY_PATH"} = catfile($ENV{"ORACLE_HOME"},"lib") . ":" . $ENV{"LD_LIBRARY_PATH"};
        print "Changed LD_LIB :" . $ENV{"LD_LIBRARY_PATH"} . "\n" if ( $debug );
        $ORACLE_HOME_cpy = $ENV{"ORACLE_HOME"};
        if ($IS_WIN) {
            $sqlplusexe = catfile($ORACLE_HOME_cpy,"bin","sqlplus.exe");
        } else {
            $sqlplusexe = catfile($ORACLE_HOME_cpy,"bin","sqlplus");
        }
        open(my $sql_fptr, '>', $sqlFile) or die "Could not open file '$sqlFile' $!";
        chown(0644,$sqlFile);
        print $sql_fptr "set feedback  off heading off lines 120\nselect substr(a.HOST_NAME,1,decode(instr(a.HOST_NAME,'.',1)-1, -1, length(a.HOST_NAME), instr(a.HOST_NAME,'.',1)-1))||'.RDBMS|$db|'|| a.INSTANCE_NAME||'.'|| b.name ||'='||b.value
                  from gv\$instance a,  gv\$parameter b
                  where  a.inst_id = b.inst_id and lower(b.name) in
                  ('diagnostic_dest', 'user_dump_dest', 'background_dump_dest');\nquit;\n";
        $text1 = tfactlshare_checksu($OH_dbOwner, "$sqlplusexe -S -L '/ as sysdba' @ $sqlFile", 1);
        print "CMD: $text1\n" if ( $debug );
        $text1 = osutils_runtimedcommand($text1,10,TRUE);
        print "OP: $text1\n" if ( $debug );
        close $sql_fptr;
        chomp($text1);
        print "OUTPUT:\n$text1\n" if ( $debug );
        @tmpArr = split /\n/, $text1;
        foreach my $x (@tmpArr) {
          if (lc($x) =~ "$localnode") {
            print "Adding $x to MASTERFIL_ARRAY \n" if ( $debug );
            push @MASTERFIL_ARRAY, "$x";
          }
        }
      }
    }
  }
  $ENV{"ORACLE_HOME"} = $OLD_ORACLE_HOME;
  $ENV{"ORACLE_SID"} = $OLD_ORACLE_SID;
  $ENV{"LD_LIBRARY_PATH"} = $OLD_LD_LIBRARY_PATH;
  
  print "Out mb_rdbms_stack_status\n" if ( $debug ) ;;
}

sub print_note {
  my $id = shift;
  my $note = shift;
  my $msg;
  
  if ( not $is_this_ade) {
    if ( $id eq "INVENTORY_NOTFOUND" ) {
      $msg = <<TEXT;
Discovery could not find inventory location on $localnode from environment.
Please set RAT_INV_LOC to your global inventory home in current shell and run discovery.
Eg: export RAT_INV_LOC=/u01/app/oraInventory\n
TEXT
    }
    elsif ( $id eq "INVENTORY_INVALID" ) {
      $msg = <<TEXT;
Inventory location $note found by discovery script is not valid.
Please set RAT_INV_LOC to your global inventory home in current shell and run discovery.
Eg: export RAT_INV_LOC=/u01/app/oraInventory\n
TEXT
    }
    elsif ( $id eq "INVENTORY_PROMPT" ) {
      $msg = "Discovery could not find the inventory location on $localnode from environment. Does $localnode have Oracle software installed [y/n][n]?";
    }
    else {
      $msg = $note."\n";
    }
    print "$msg";
  }
}

sub search_invntr_platform {
  #print "In search_invntr_platform\n";
  my $ask_inv_loc;
  my $inv_ptr_exist;
  my $ORACLE_INVENTORY = "";  
  my $ora_inst_loc = "";

  my $invntr = $localnode;
  #print "$invntr : $localnode : $PLATFORM\n";
  if($IS_WIN) {
    $ORACLE_INVENTORY = tfactlwin_query_registry("inst_loc");
    @tmp = split /\s{2,}/, $ORACLE_INVENTORY;
    $ORACLE_INVENTORY = $tmp[-1];
  }
  else {
    if ($PLATFORM eq "linux" || $PLATFORM eq "aix" ) {
      $ora_inst_loc = catfile("","etc","oraInst.loc");
    }
    elsif ($PLATFORM eq "solaris" || $PLATFORM eq "hpux" ) { 
      $ora_inst_loc = catfile("","var","opt","oracle","oraInst.loc");
    }
    else {
      print "ERROR: Unknown Operating System\n";
      $invntr_location = 0;
      return;
    }
  }

  if ( -e $ora_inst_loc ) {
    @tmp1 = readFileToArray($ora_inst_loc);
    @tmp1 = removePatternFromArray(\@tmp1, "^#");
    @tmp1 = grepPatternFromArray(\@tmp1, "inventory_loc");
    @tmp1 = cut_df_from_array(\@tmp1, "=", 2);
    $ORACLE_INVENTORY = $tmp1[0];
  }
  chomp($ORACLE_INVENTORY);

  if ( length("$ORACLE_INVENTORY") != 0 && -d "$ORACLE_INVENTORY" && length("$RAT_INV_LOC") == 0 ) {
      $invntr_location = $ORACLE_INVENTORY;
  }
  elsif ( length("$ORACLE_INVENTORY") == 0 && length("$RAT_INV_LOC") == 0 )  {      
    $invntr_location = "";
    print_note("INVENTORY_NOTFOUND");
  }
  elsif ( length("$ORACLE_INVENTORY") != 0 && ! -d "$ORACLE_INVENTORY" && length("$RAT_INV_LOC") == 0 ) { 
    $invntr_location = "";
    print_note("INVENTORY_INVALID",$ORACLE_INVENTORY);
  }
  elsif ( length("$ORACLE_INVENTORY") == 0 && length("$RAT_INV_LOC") == 0 && $SILENT == 0 ) {
    #We never come here
    $invntr_location = "";
    print_note("INVENTORY_PROMPT");
    $ask_inv_loc = <STDIN>;
    if ($ask_inv_loc =~ /^[Y|YES]$/i) {
      print_note("INVENTORY_NOTFOUND");
      exit 1;
    }
    elsif ($ask_inv_loc =~ /^[N|NO]$/i) {
    }
    else {
    }
  } 
  else {
    $invntr_location = $RAT_INV_LOC;
  }
}

sub is_crs_installed {
  #print "In is_src_installed\n";
  search_invntr_platform();
  my @tmp;
  my @invntr_CH_arr;
  my $invntr_CH2;
  my $invntr_CH3;
  my $local_invntr_CH;
  my $remote_crs_home_status;
  my $remote_crsd_file_status;
  my $inventory_file;

  my $crs_install = $localnode;
  undef $invntr_CH;
  if ( length("$invntr_location") != 0 ) {
    $inventory_file = catfile("$invntr_location","ContentsXML","inventory.xml"); 
    @invntr_CH_arr = readFileToArray($inventory_file);
    @invntr_CH_arr = grepPatternFromArray(\@invntr_CH_arr, "CRS=\"true\"");
    @invntr_CH_arr = removePatternFromArray(\@invntr_CH_arr, "REMOVED=\"T\"");
    @invntr_CH_arr = awk_n_from_array(\@invntr_CH_arr, 3);
    @invntr_CH_arr = cut_df_from_array(\@invntr_CH_arr,"=",2);
    @invntr_CH_arr = find_and_replace_from_array(\@invntr_CH_arr,"\"","");
    $local_invntr_CH = $invntr_CH_arr[0];
    $invntr_CH = $local_invntr_CH;
    chomp($invntr_CH);
    if ( -e "$invntr_CH" && $#invntr_CH_arr > 1 && length("$RAT_CRS_HOME") == 0 ) {
      print "Discovery found more than one CRS_HOME in inventory.\n\nPlease verify inventory file $inventory_file\n";
      exit 1;
    }

    
    if ( $#invntr_CH_arr == -1 ) {
      #When no crs home found in aboe try
      @tmp = readFileToArray($inventory_file);
      @tmp = removePatternFromArray(\@tmp, "REMOVED=\"T\"");
      @tmp = awk_n_from_array(\@tmp, 3);
      @tmp = cut_df_from_array(\@tmp,"=",2);
      @tmp = find_and_replace_from_array(\@tmp,"\"","");
      foreach $invntr_CH3 (@tmp) {
        chomp($invntr_CH3);
        my @tmp1 = running_processes_to_array();
        #print @tmp1;
        $invntr_CH3 =~ s/\\/\\\\/g;
        @tmp1 = grepPatternFromArray(\@tmp1, $invntr_CH3);
        if ($IS_WIN) {
          @tmp1 = grepPatternFromArray(\@tmp1, "crsd.exe");
        } elsif ($PLATFORM eq "linux") {
          @tmp1 = grepPatternFromArray(\@tmp1, "crsd.bin");
        }
        @tmp1 = removePatternFromArray(\@tmp1, "grep");
        if ( $#tmp1 > 0 ) {
           $invntr_CH = $invntr_CH3;
        }
      }
    }
  }

  #my $crsSoftwareOwner;
  if ( -d $invntr_CH || length("$RAT_CRS_HOME") != 0 ) {
    if ($IS_WIN) {
      $loc = catfile($invntr_CH, "BIN", "crsd.exe");
    } else {
      $loc = "$invntr_CH/bin/crsd";
    }

    if ( -f "$loc" || length("$RAT_CRS_HOME") != 0 ) {
      $crs_installed[$crs_counter]=1;
      push @MASTERFIL_ARRAY, "$crs_install.CRS_INSTALLED=$crs_installed[$crs_counter]";
      my $crs_found = 0;
      for( my $x = 0; $x <= $#MASTERFIL_ARRAY; $x = $x +1) {
        if ($MASTERFIL_ARRAY[$x] =~ /CRS_HOME=/) {
          $crs_found = 1;
          my @crsVal = split /=/, $MASTERFIL_ARRAY[$x];
          if (length($crsVal[1]) == 0) {
            if ( length("$RAT_CRS_HOME") != 0 ) {
              $MASTERFIL_ARRAY[$x] = "CRS_HOME=$RAT_CRS_HOME";
            } else {
              $MASTERFIL_ARRAY[$x] = "CRS_HOME=$invntr_CH";
            }
          }
        }
      }
        
      if ( length("$RAT_CRS_HOME") != 0 ) {
        print "\nCRS_HOME=$RAT_CRS_HOME\n\n";
        if ($crs_found == 0) {
          push @MASTERFIL_ARRAY, "CRS_HOME=$RAT_CRS_HOME";
        }
        #$crsSoftwareOwner = `ls -l $RAT_CRS_HOME/bin/ocssd 2>/dev/null|awk '{print $3}'`;
      } else {
        print "\nCRS_HOME=$invntr_CH\n\n";
        if ($crs_found == 0) {
          push @MASTERFIL_ARRAY, "CRS_HOME=$invntr_CH";
        }
        #$crsSoftwareOwner = `ls -l $RAT_CRS_HOME/bin/ocssd 2>/dev/null|awk '{print $3}'`;  #for windows dr doesnot gi
      }
    } else {
      $crs_installed[$crs_counter] = 0;
      push @MASTERFIL_ARRAY, "$crs_install.CRS_INSTALLED=$crs_installed[$crs_counter]";
    }
  } else {
      $crs_installed[$crs_counter]=0;
      push @MASTERFIL_ARRAY, "$crs_install.CRS_INSTALLED=$crs_installed[$crs_counter]";
  }

  $crs_counter = 0;
}

#this function is to check that RDBMS is installed or not on all nodes in cluster
sub is_rdbms_installed
{
  #print "In is_rdbms_installed\n";
  my $rdbms_counter = 0;
  #unset $invntr_OH;
  my @tmp;
  my @tmp1;
  my $counter;
  my @oracle_home_owner;
  my $loc;
  
  if ( length("$invntr_location") != 0 ) {
    my $file = catfile($invntr_location, "ContentsXML", "inventory.xml");
    @tmp = readFileToArray($file);
    @tmp = grepPatternFromArray(\@tmp, "LOC");
    @tmp = removePatternFromArray(\@tmp, "CRS=\"true\"");
    @tmp = removePatternFromArray(\@tmp, "ASM");
    @tmp = removePatternFromArray(\@tmp, "agent");
    @tmp = removePatternFromArray(\@tmp, "REMOVED=\"T\"");
    @tmp = awk_n_from_array(\@tmp, 3);
    @tmp = cut_df_from_array(\@tmp, "=", 2);
    @tmp = find_and_replace_from_array(\@tmp, "\"", "");

    #printArr(\@tmp);
    $counter = 0;
    foreach my $invntr_OH (@tmp) {
      chomp($invntr_OH);
      if ( -d $invntr_OH || length("$RAT_ORACLE_HOME") != 0 ) {
        my $ora_file;
        if ($IS_WIN) {
          $ora_file = catfile($invntr_OH, "bin", "oracle.exe");
        } else {
          $ora_file = catfile($invntr_OH, "bin", "oracle");
        }

        if ( -f $ora_file || length("$RAT_ORACLE_HOME") != 0 ) {
          $rdbms_installed[$rdbms_counter] = 1;
          $ENV{ORACLE_HOME} = $invntr_OH;
          get_sqlplus_version();
          if ($IS_WIN) {
            #Extracting Oracle Home 
            my $key_home = tfactlwin_query_registry("ORACLE_HOME", 1);
            my $key_user = tfactlwin_query_registry("ORACLE_SVCUSER", 1);

            chomp($key_home);
            chomp($key_user);

            my @key_home_arr = split /\n\n/, $key_home;
            my @key_user_arr = split /\n\n/, $key_user;

            my %registry_entries;
            foreach my $x (@key_home_arr) {
              $x =~ s/\n//g;
              if ($x !~ /End of search/) {
                @tmp1 = split /\s{2,}/, $x;
                foreach my $y (@tmp1) {
                  chomp($y);
                  tfactlwin_trim($y);
                }
                $registry_entries{$tmp1[0]} = $tmp1[-1];
              }
            }

            foreach my $x (@key_user_arr) {
              $x =~ s/\n//g;
              if ($x !~ /End of search/) {
                @tmp1 = split /\s{2,}/, $x;
                foreach my $y (@tmp1) {
                  chomp($y);
                  tfactlwin_trim($y);
                }
                $registry_entries{$tmp1[0]} = $registry_entries{$tmp1[0]} . "|" . $tmp1[-1];
              }
            }

            foreach my $x (keys %registry_entries) {
              #print "$x : $registry_entries{$x}\n";
              @tmp1 = split /\|/, $registry_entries{$x};
              if ($invntr_OH eq $tmp1[0]) {
                $oracle_home_owner[$counter] = $tmp1[1];
              }
            }
          } else {
            if ( $PLATFORM eq "linux" ) {
              $loc = catfile($ENV{ORACLE_HOME}, "bin", "oracle");
              $oracle_home_owner[$counter] = `stat -L -c "%U" $loc`;
              chomp($oracle_home_owner[$counter]);
            } else {
              $loc = catfile($ENV{ORACLE_HOME}, "bin", "oracle");
              $oracle_home_owner[$counter] = `ls -l $loc|awk '{print \$3}'`;
              chomp($oracle_home_owner[$counter]);
            }
          }
          push @MASTERFIL_ARRAY, "RDBMS_ORACLE_HOME=$invntr_OH|$what_db|$oracle_home_owner[$counter]|";
        } else {
          $rdbms_installed[$rdbms_counter] = 0;
        }
      } else {
        $rdbms_installed[$rdbms_counter] = 0;  
      }
      $counter = $counter + 1;
    }
    if ( length("$rdbms_installed[$rdbms_counter]") != 0 && $rdbms_installed[$rdbms_counter] == 1 ) {
      push @MASTERFIL_ARRAY, "$localhost.RDBMS_INSTALLED=1";
    } else {
      push @MASTERFIL_ARRAY, "$localhost.RDBMS_INSTALLED=0";
    }
  } else {
    $rdbms_installed[$rdbms_counter] = 0;
    push @MASTERFIL_ARRAY, "$localhost.RDBMS_INSTALLED=0";
  } 
}

sub get_sqlplus_version
{
  #print "In get_sqlplus_version\n";
  my $oracle_home = $ENV{ORACLE_HOME};
  $ENV{LD_LIBRARY_PATH} = catdir($oracle_home, "lib");
  my $OH_dbOwner;
  my $loc;
  my @tmp;

  if ( -d $ENV{"ORACLE_HOME"} ) {
    if ($IS_WIN) {
      $loc = catfile($ENV{"ORACLE_HOME"}, "BIN", "oracle.exe");
      @tmp = `dir /Q $loc`;
      $OH_dbOwner = $tmp[5];
      $OH_dbOwner =~ s/\s+/ /g;
      @tmp = split / /, $OH_dbOwner;
      $OH_dbOwner = $tmp[4];
      @tmp = split /\\/, $OH_dbOwner;
      $OH_dbOwner = $tmp[-1];

      #`set ORACLE_HOME=$oracle_home`;
      $loc = catfile($oracle_home, "bin", "sqlplus.exe");
      if (-e $loc) {
        $what_db = `$loc -v`;
        @tmp = split / /, $what_db;
        $what_db = $tmp[2];
        $what_db =~ s/\.//g;
        chomp($what_db);
        print "\n\n***$what_db***\n\n" if ( $debug );
      }
    } else {
      $loc = catfile($ENV{"ORACLE_HOME"}, "bin", "oracle");
      $OH_dbOwner = `ls -l $loc`;
      @tmp = split " ", $OH_dbOwner;
      $OH_dbOwner = $tmp[2];
      print "OH OWNER: $OH_dbOwner\n" if ( $debug );
      my $current_user = getpwuid($<);
      if ( $current_user eq "root" ) {
         my $shell = `su - $OH_dbOwner -c "env|grep -i '^shell='"`;
         if ( $shell =~ /\/bin\/t?csh/ ) {
           $what_db = `su $OH_dbOwner -c \"set ORACLE_HOME=$oracle_home;$oracle_home/bin/sqlplus -v\"|awk '{print \$3}'|sed 's/\\.//g'|sed '/^\$/d'`;
         } else {
           $what_db = `su $OH_dbOwner -c \"ORACLE_HOME=$oracle_home;export ORACLE_HOME;$oracle_home/bin/sqlplus -v\"|awk '{print \$3}'|sed 's/\\.//g'|sed '/^\$/d'`;
         }
      } else {
         my $shell = `env|grep -i '^shell='`;
         if ( $shell =~ /\/bin\/t?csh/ ) {
           $what_db = `set ORACLE_HOME=$oracle_home;$oracle_home/bin/sqlplus -v | awk '{print \$3}'|sed 's/\\.//g'|sed '/^\$/d'`;
         } else {
           $what_db = `ORACLE_HOME=$oracle_home;export ORACLE_HOME;$oracle_home/bin/sqlplus -v |awk '{print \$3}'|sed 's/\\.//g'|sed '/^\$/d'`;
         }
      }
      print "command for version: $what_db\n" if ( $debug );
      $what_db = `$what_db`;
      chomp($what_db);
      print "Version: $what_db\n" if ( $debug );
    }
  }
}

sub check_crs_state {
  my $loc;
  if ($IS_WIN) {
    $loc = catfile($RAT_CRS_HOME, "bin", "crsctl.exe");
  } else {
    $loc = catfile($RAT_CRS_HOME, "bin", "crsctl");
  }

  return 0 if ! -f $loc;
  my $text = `$loc check crs`;
  my @arrtemp = split /\n/,$text;
  my $count = 0;
  foreach my $x (@arrtemp) {
    if ($x =~ /online/) {
      $count++;
    } elsif ($x =~ /failure/ || $x =~ /Cannot/) {
      return 0;
    }
  }

  if ($count >= 4) {
    return 1;
  } else {
    return 0;
  }
}

sub get_crs_home {
  my $CHOME = "";
  my $OLR_LOC = "";

  if ($IS_WIN) {
    my $BASE_KEY="HKEY_LOCAL_MACHINE\\SOFTWARE\\Oracle";

    my $type = tfactlwin_trim(tfactlwin_check_os_type());
    #print "TYPE: $type\n";
    my $REGISTRY_QUERY_TYPE;

    if ($type eq "64BIT"){
      $REGISTRY_QUERY_TYPE = "/reg:64";
    } else{
      $REGISTRY_QUERY_TYPE = "/reg:32";
    }

    $CHOME = `reg query $BASE_KEY\\olr /s /e /f crs_home $REGISTRY_QUERY_TYPE | findstr crs_home 2>nul`;
    my @tmp = split /\s{2,}/, $CHOME;
    $CHOME = $tmp[-1];
    chomp($CHOME);
  } else {
    if ( -e "/etc/oracle/olr.loc" ) {
      $OLR_LOC = "/etc/oracle/olr.loc";
    } elsif ( -e "/var/opt/oracle/olr.loc" ) {
      $OLR_LOC = "/var/opt/oracle/olr.loc";
    }
    if ( length("$OLR_LOC") != 0 ) {
      my @tmp = readFileToArray("$OLR_LOC");
      foreach my $x (@tmp) {
        if ($x =~ /crs_home=/) {
          my @tmp1 = split /=/,$x;
          $CHOME = $tmp1[1];
        }
      }
    }
  }
  return $CHOME;
}

sub printArrayToFile {
  my $arrref = shift;
  my @arr = @{$arrref};
  my $file = shift;
  open(my $fileptr, '>>', $file) or die "Could not open file '$file' $!";

  foreach my $x (@arr) {
    print $fileptr "$x\n";
  }

  close $fileptr;
}

sub printArr {
  my $arrref = shift;
  my @arr = @{$arrref};
  foreach my $x (@arr) {
    print "$x\n";
  }
}

# Queries the registry for a key under Oracle Parent key to get its corresponding value
# Parameter - $key - registry key
# Return - value for required registry key
sub tfactlwin_query_registry{
  my $key =shift;
  my $unfilterResultFlag = shift;

  my $BASE_KEY="HKEY_LOCAL_MACHINE\\SOFTWARE\\Oracle";
  my $result="";

  my $type = tfactlwin_trim(tfactlwin_check_os_type());
  #print "TYPE: $type\n";
  my $REGISTRY_QUERY_TYPE;

  if ($type eq "64BIT"){
    $REGISTRY_QUERY_TYPE = "/reg:64";
  } else{
    $REGISTRY_QUERY_TYPE = "/reg:32";
  }

  if ($unfilterResultFlag) {
    $result = `reg query $BASE_KEY /s /e /f $key $REGISTRY_QUERY_TYPE`;
  } else {
    $result = `reg query $BASE_KEY /s /e /f $key $REGISTRY_QUERY_TYPE | findstr $key`;
  }
  #print "RES: reg query $BASE_KEY /s /e /f $key $REGISTRY_QUERY_TYPE | findstr $key\n";
  return $result;
}

# Returns the corresponding type of operating system (64BIT/32BIT)
# Return - 32BIT for 32 Bit operating system and 64BIT for 64 BIT operating system
sub tfactlwin_check_os_type{
  my $type =`IF EXIST "%PROGRAMFILES(X86)%" (ECHO 64BIT) ELSE (ECHO 32BIT)`;
  return $type;
}

# Function: Remove leading and trailing blanks.
# Arg     : string
# Return  : trimmed string
sub tfactlwin_trim{
   my $str = $_;
   $str = shift;
   $str =~ s/^\s+//;
   $str =~ s/\s+$//;
   return $str ;
}

#ssh equivalents in perl for windows
sub win_ssh{
  my $host = shift;
  my $user = shift;
  my $pass  = shift;
  my $remoteCommand = shift;
  my $returnValue = "1"; # 0 means proper execution else improper execution
  my $cmd = "WMIC /user:$user /Password:$pass /node:\"$host\" PROCESS call create \"$remoteCommand\"";
  my $output = `$cmd`;
  my @lines = split(/\n/,$output);
  foreach my $line (@lines) {
    if (index($line, "ReturnValue") != -1) {
      $returnValue = $line;
      $returnValue =~ s/\D//g;
    }
  }
  return $returnValue;
}

sub win_ssh_without_cred{
  my $host = shift;
  my $remoteCommand = shift;
  my $returnValue = "1"; # 0 means proper execution else improper execution
  my $cmd = "WMIC /node:\"$host\" PROCESS call create \"$remoteCommand\"";
  #print "CMD: $cmd\n";
  my $output = `$cmd`;
  my @lines = split(/\n/,$output);
  foreach my $line (@lines) {
    if (index($line, "ReturnValue") != -1) {
      $returnValue = $line;
      $returnValue =~ s/\D//g;
    }
  }
  return $returnValue;
}

#check if ssh eqivalence is present b/w the nodes of a cluster
sub check_ssh_equivalence{
  my $REMOTE_HOST = shift;
  my $SSH_STATUS="1";

  if($IS_WIN) {
    my $returnValue = win_ssh_without_cred($REMOTE_HOST,"cmd /c dir");
    if("$returnValue" eq "0"){
      $SSH_STATUS = "0";
    }
  }else{
    # $SSH -o NumberOfPasswordPrompts=0 -o StrictHostKeyChecking=no -l $SSH_USER $REMOTE_HOST ls > /dev/null 2>&1
    # SSH_STATUS=$?
  }
  return $SSH_STATUS;
}

#Function to get the location of commands
sub getCommandLocation {

        my $COMMAND = shift;
        my $CMDLOC;

        if ( -e "/bin/$COMMAND" ) {
            $CMDLOC = "/bin/$COMMAND";
        } elsif ( -e "/usr/bin/$COMMAND" ) {
            $CMDLOC = "/usr/bin/$COMMAND";
        } else {
            $CMDLOC = "$COMMAND";
        }

        return $CMDLOC;
}

sub generateKeys {
  # Remove Private Key
  if ( -e "$HOME/.ssh/$SSH_ID" ) {
    unlink("$HOME/.ssh/$SSH_ID");
  }

  # Remove Public Key
  if ( -e "$HOME/.ssh/$SSH_ID.pub" ) {
    unlink("$HOME/.ssh/$SSH_ID.pub");
  }

  if ( ! -d "$HOME/.ssh" ) {
    mkpath("$HOME/.ssh");
  }

  # Generate Keys
  print "Generating keys on $HOSTNAME...\n";
  `$SSH_KEYGEN -t $SSH_ENCR -b $SSH_BITS -f $HOME/.ssh/$SSH_ID -N '' > /dev/null`;
  $SSH_GEN_KEYS=1;
}

# Function to configure SSH setup
sub configureSSH {
  my $REMOTE_HOST = shift;

  # Generate keys only if not present
  if ( ! -e "$HOME/.ssh/$SSH_ID" ) {
    generateKeys();
    print "\n";
  }

  # Copy keys to remote node
  print "Copying keys to $REMOTE_HOST...\n";
  print "\n";

  if ( -e "$SSH_COPY_ID" ) {
    `$SSH_COPY_ID $SSH_USER\@$REMOTE_HOST > /dev/null`;
  } else {
    `$CAT $HOME/.ssh/$SSH_ID.pub | $SSH $SSH_USER\@$REMOTE_HOST \"mkdir -p $HOME/.ssh && cat >>  $HOME/.ssh/authorized_keys\"`;
  }
}

sub trimString {
  my $str = shift;
  $str =~ s/^\s+//g;
  $str =~ s/\s+$//g;
  return $str;
}

sub findFilesWithPattern {
  my $loc = shift;
  my $pattern = shift;
  find({wanted => sub { print "$File::Find::name\n" if (-d $_ && $_ =~ /$pattern/) }}, "$loc");
}

sub findFilesWithPatternInArray {
  my $loc = shift;
  my $pattern = shift;
  my @retArray;
  if ($IS_WIN) {
    find({wanted => sub { push @retArray, $File::Find::name if (-d $_ && $_ =~ /$pattern/ ) }}, "$loc");
  } else { # UX find is so much more efficient
    @retArray = split /\n/, `find $loc -type d | grep \'$pattern\'`;
  }
  return @retArray;
}

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

#Conversion for shell command 'cat <filename1> > <filename2>'
sub readFileToFile {
  my $file1 = shift;
  my $file2 = shift;
  open (FILE, "$file1") || die "Could not open $file1!\n";
  open OUT, ">", "$file2" or die "Could not open $file2 for writing!\n";
  while(<FILE>) {
    print OUT $_;
  }
  close FILE;
}

#perl conversion of 'ls -l'
sub listContentsOfFolder {
  my $folderLoc = shift;
  my @retArray;
  if ($IS_WIN) {
    @retArray = `dir`;
  } elsif ($PLATFORM == "linux") {
    @retArray = `ls -l`;
  }
  return @retArray;
}

#perl conversion of 'grep <pattern>' and prints the matches
sub grepPatternFromFile {
  my $filename = shift;
  my $pattern = shift;
  chomp($pattern);
    chomp($filename);
  open FILE, "$filename" or die "Could not open $filename!\n";
  while(<FILE>) {
        print $_ if /$pattern/o;
  }
}

#perl conversion of 'grep <pattern>' from array and returns an array
sub grepPatternFromArray {
  my $wordListref = shift;
  my @wordList = @{$wordListref};
  my $pattern = shift;
  chomp($pattern);

  my @retArray;
  my $i;
  foreach $i (@wordList) {
    if ( $i =~ /$pattern/ ){
      push @retArray, $i;
    }
  }
  return @retArray;
}

#perl conversion of 'grep -v <pattern> from array and returns an array
sub removePatternFromArray {
  my $wordListref = shift;
  my @wordList = @{$wordListref};
  my $pattern = shift;
  chomp($pattern);

  my @retArray;
  my $i;
  foreach $i (@wordList) {
    if ( $i =~ /$pattern/ ){
    } else {
      push @retArray, $i;
    }
  }
  return @retArray;
}

#perl conversion of awk '{print $n}' from array
sub awk_n_from_array {
  my $arrayRef = shift;
  my @array = @{$arrayRef};
  my $n = shift;
  #$[ = 1;                 # set array base to 1
  #$, = ' ';               # set output field separator
  #$\u = "\n";              # set output record separator

  my $i;
  my @Fld;
  my @retArray;
  foreach $i (@array){
      @Fld = split(' ', $i, -1);
      push @retArray, $Fld[$n-1];
  }
  return @retArray;
}

#perl conversion of awk '{print $n}' from file
sub awk_n_from_file{
  my $filename = shift;
  my $n = shift;
  my @Fld;
  chomp($filename);
  open FILE, "$filename" or die "Could not open $filename!\n";

  #$[ = 1;                 # set array base to 1
  #$, = ' ';               # set output field separator
  #$\ = "\n";              # set output record separator

  my @retArray;
  while (<FILE>){
    @Fld = split(' ', $_, -1);
    push @retArray, $Fld[$n];
  }
  return @retArray;
}

#perl conversion of 'cut -d<delim> -f<n>'
sub cut_df_from_array {
  my $arrayRef = shift;
  my @array = @{$arrayRef};
  my $delim = shift;
  my $n = shift;

  my $i;
  my @retArray;
  my @tmpArray;
  foreach $i (@array) {
    @tmpArray = split /$delim/,$i;
    push @retArray, $tmpArray[$n-1];
  }
  return @retArray;
}

#perl conversion of 'sed 's/<pattern1>/<pattern2>/'' from array
sub find_and_replace_from_array {
        my $arrayRef = shift;
        my @array = @{$arrayRef};
        my $pattern1 = shift;
        my $pattern2 = shift;

        chomp($pattern1);
        chomp($pattern2);

        my $i;
        my @retArray;
        foreach $i (@array) {
                if ($i =~ /$pattern1/) {
                        $i =~ s/$pattern1/$pattern2/g;
                }
                push @retArray, $i;
        }
        return @retArray;
}

#perl conversion of 'ps -ef' or 'tasklist'
sub running_processes_to_array {
  my @retArray;
  if ($IS_WIN) {
    @retArray = `tasklist`;
    @retArray = @retArray[3 .. $#retArray];
  } elsif ($PLATFORM eq "linux") {
    @retArray = `ps -ef`;
    @retArray = @retArray[2 .. $#retArray];
  }
  return @retArray;
}

#takes an array with redundant elements and returns an array with unique elements
sub array_uniq_elem {
    my %seen;
    grep !$seen{$_}++, @_;
}

sub tolower_host
{
    my $host = hostname () or return "";

    # If the hostname is an IP address, let hostname remain as IP address
    # Else, strip off domain name in case /bin/hostname returns FQDN
    # hostname
    my $shorthost;
    if ($host =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) {
        $shorthost = $host;
    } else {
        ($shorthost,) = split (/\./, $host);
    }

    # convert to lower case
    $shorthost =~ tr/A-Z/a-z/;

    die "Failed to get non-FQDN host name for " if ($shorthost eq "");

    return $shorthost;
}

sub writeToFile{
  my $cfile = shift;
  my $line = shift;
  open(CF1, ">>$cfile");
  print CF1 "$line";
  close(CF1);
}

sub testSQLWin {
  my $db = shift;
  my $dboh = shift;
  my $sid = shift;
  my $text1;

  $ENV{ORACLE_HOME} = $dboh;
  $ENV{ORACLE_SID} = $sid;
  $ENV{LD_LIBRARY_PATH} = catdir($ENV{ORACLE_HOME}, "lib");
  $ENV{ORA_SERVER_THREAD_ENABLED} = "FALSE";

  open(my $sql_fptr, '>', $sqlFile) or die "Could not open file '$sqlFile' $!";
  print $sql_fptr "set feedback  off heading off lines 120\nselect 'Database Connection Successful' from dual;\nquit;\n";
  $text1 = "$dboh\\bin\\sqlplus.exe -l -S / as sysdba @ $sqlFile";
  #print "CMD: $text1\n";
  $text1 = `$text1`;
  chomp($text1);
  #print "TEXT: $text1";
  close $sql_fptr;

  if ($text1 =~ /Database Connection Successful/) {
    return 1;
  } else {
    return 0;
  }
}

sub getPDBs {
  my $db = shift;
  my $sid = shift;
  my $home = shift;
  my $user = shift;
  my $pdb_list = "";
  my $sqlplusexe = "";

  $ENV{ORACLE_HOME} = $home;
  $ENV{ORACLE_SID} = $sid;
  $ENV{LD_LIBRARY_PATH} = catdir($ENV{ORACLE_HOME}, "lib");
  $ENV{ORA_SERVER_THREAD_ENABLED} = "FALSE";

  if ( -d $ENV{"ORACLE_HOME"}) {
     my $ORACLE_HOME_cpy = $ENV{"ORACLE_HOME"};

     if ($IS_WIN) {
         $sqlplusexe = catfile($ORACLE_HOME_cpy,"bin","sqlplus.exe");
     } else {
         $sqlplusexe = catfile($ORACLE_HOME_cpy,"bin","sqlplus");
     }

     open(my $sql_fptr, '>', $sqlFile) or die "Could not open file '$sqlFile' $!";
     chown(0644,$sqlFile);
     print $sql_fptr "set feedback  off heading off lines 120\nselect NAME from v\$pdbs;\nquit\n";
     my $text1 = tfactlshare_checksu($user, "$sqlplusexe -S -L '/ as sysdba' @ $sqlFile", 1);
     print "CMD: $text1\n" if ( $debug );
     $text1 = osutils_runtimedcommand($text1,10,TRUE);
     print "OP: $text1\n" if ( $debug );
     close $sql_fptr;

     chomp($text1);
     $text1 =~ s/^\n|\n$//g;
     if ($text1 !~ /ERROR/) {
       $pdb_list = join ",", (split /\n/, $text1);
     }
   }

   unlink($sqlFile) if (-e $sqlFile);
   return $pdb_list;
}
