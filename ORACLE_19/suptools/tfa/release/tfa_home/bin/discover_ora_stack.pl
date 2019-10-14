# 
# $Header: tfa/src/v2/tfa_home/bin/discover_ora_stack.pl /main/20 2018/07/12 10:06:25 recornej Exp $
#
# discover_ora_stack.pl
# 
# Copyright (c) 2014, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      discover_ora_stack.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    06/29/18 - Search for OMS instance
#    manuegar    08/28/17 - manuegar_pmap_disc.
#    manuegar    08/14/17 - Bug 26619915 - LNX64-12.2-TFA:ORATOP DOES NOT WORK
#                           WHEN DB UNIQUE NAME DIFFERS FROM DBNAME.
#    recornej    08/10/17 - Grouping db params to dbparams directory
#    manuegar    05/08/17 - XbranchMerge manuegar_srdcwin02_122 from
#                           st_tfa_12.2.1.1.01
#    manuegar    05/03/17 - manuegar_srdcwin02.
#    manuegar    04/28/17 - manuegar_srdcwin01.
#    manuegar    03/24/17 - emsrdc01
#    bibsahoo    03/10/17 - FIX BUG 25602989 - WS2012_122_TFA: TFACTL
#                           REDISCOVER IN WINDOWS SHOWS SHELL ERRORS
#    manuegar    01/24/17 - EM SRDC.
#    cnagur      12/14/16 - Fix for Bug 25168249
#    cnagur      11/24/15 - Fix for Bug 22244887
#    gadiga      11/04/15 - limit fork count
#    bburton     09/23/15 - remove email address
#    gadiga      06/24/15 - only one instance
#    manuegar    06/12/15 - TFA/Ips collection Logic 2.
#    gadiga      06/09/15 - XbranchMerge gadiga_tfa_in_dbaas_12124 from
#                           st_tfa_12.1.2.4
#    gadiga      04/20/15 - fix 20910717, space in ps
#    gadiga      05/12/15 - change a+x to 755
#    gadiga      02/23/15 - discovery for commands
#    gadiga      01/16/15 - full system discovery
#    gadiga      12/17/14 - discover oracle stack and trace dirs
#    gadiga      11/18/14 - perl version of discovery code
#    gadiga      11/18/14 - Creation
# 

#use strict;
use English;
use File::Basename;
use File::Spec::Functions;
use File::Copy;
use Time::Local;
use Term::ANSIColor;
use Cwd;
use POSIX;
use Sys::Hostname;

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME);
  push @INC, dirname($PROGRAM_NAME).'/common';
  push @INC, dirname($PROGRAM_NAME).'/modules';
  push @INC, dirname($PROGRAM_NAME).'/common/exceptions';
}

use Getopt::Long qw(:config no_auto_abbrev);
use tfactlglobal;
use tfactlshare;
use dbutil;
use tfactlwin;

use Fcntl qw/ :flock /;

if ( ! $ARGV[0] )
{
  print "Usage : $0 -tfahome <tfa_home> [-mode <lite|full>] [-silent]\n";
  exit;
}

our $debug = 0;
my $TFAHOME;
my $OUT;
my $FROM;
my $SILENT = "0";
my $MODE = "full";
my $verbose;
my $localhost = tolower_host();

GetOptions ("tfahome=s" => \$TFAHOME,
                    "mode=s"   => \$MODE,
                    "out=s"   => \$OUT,
                    "from=s"   => \$FROM,
                    "silent"   => \$SILENT,
                    "verbose"  => \$verbose);  # flag\

if ( ! -d $TFAHOME )
{
  print "Error: $TFAHOME does not exists.\n";
  exit;
}

chdir("$TFAHOME/internal");

my $lckfile = ".discovery.pid";
if ( -r "$lckfile")
{
  print "Error: .discovery.pid already locked.\n";
  exit;
}

open(WF1, ">$lckfile");
print WF1 "$$";
close(WF1);

# Read previous discovery results to avoid running commands again.
$OUT = "$$.ora_stack_status.out" if ( ! $OUT );
open(WF, ">>$OUT");

my $PLATFORM = "";

my %g = ();
# $g{SYSTEM} =  GI|RESTART|SI|..

$g{"IS_THIS_ADE"} = 0;
if ( $ENV{"ADE_VIEW_ROOT"} )
{
  $g{"IS_THIS_ADE"} = 1;
}

print_d("Starting execution\n");

  read_oratab();
  read_inventory();

if ( $FROM eq "sc" )
{
  discover_system();
  discover_db();
}

discover_gc();

close(WF);

if ( $FROM eq "sc" )
{
  unlink("ora_stack_status.out") if ( -f "ora_stack_status.out" );
  move($OUT, "ora_stack_status.out");
}
print_d("Finished execution\n");
unlink ($lckfile);
#-- end of main


# Debug print
sub print_d
{
  if ( $debug == 1 )
  {
    print "DEBUG: @_";
  }
}

# Read oratab and udpate variables
sub read_oratab
{
  if ( -e "/etc/oratab" )
  {
    read_oratab_file("/etc/oratab");
  }
  if ( -e "/var/opt/oracle/oratab" )
  {
    read_oratab_file("/var/opt/oracle/oratab");
  }
}

#+ASM1:/u01/app/11.2.0/grid_11204:N              # line added by Agent
# RDB10205:/u01/app/oradb/product/10.2.0/db_10205:N
sub read_oratab_file
{
  my $oratab = shift;

  if ( -r "$oratab" )
  {
    print_d("Reading $oratab\n");
    open(RF, "$oratab");
    while(<RF>)
    {
      chomp;
      if ( /^([\w\d\+]+)\:([^\:]+)\:/ )
      {
        my $db = $1;
        my $home = $2;
        if ( -d "$home" )
        {
          print_d("Found $db - $home in oratab\n");
          $g{"ORATAB"}{$db} = $home;
        }
      }
    }
    close(RF);
  } 
}

# Read inventory file and update variables

sub read_inventory
{
  if ( $IS_WINDOWS ) {
    my $ORACLE_INVENTORY = tfactlwin_query_registry("inst_loc");
    my @tmp = split /\s{2,}/, $ORACLE_INVENTORY;
    $ORACLE_INVENTORY = $tmp[-1];
    chomp($ORACLE_INVENTORY);
    my $inv = catfile($ORACLE_INVENTORY, "ContentsXML", "inventory.xml");
    if ( -r "$inv" ) {
      print "Reading inv $inv\n";
      read_inv_xml($inv);
    } 
  } # end if $IS_WINDOWS

  if ( -r "/etc/oraInst.loc" )
  {
    read_inst_loc("/etc/oraInst.loc");
  }
  if ( -r "/var/opt/oracleInst.loc" )
  {
    read_inst_loc("/var/opt/oracleInst.loc");
  }
}

sub read_inst_loc
{
  my $inst_loc = shift;
  open(RF, $inst_loc);
  while(<RF>)
  {
    chomp;
    if ( /inventory_loc=(.*)/ )
    {
      if ( -d "$1" )
      {
        $g{"ORA_INV_LOC"} = $1;
        my $inv = catfile($1, "ContentsXML", "inventory.xml");
        if ( -r "$inv" )
        {
          print_d("Reading $inv\n");
          read_inv_xml($inv);
        }
      }
    }
  }
  close(RF);
}

sub read_inv_xml
{
  my $invxml = shift;
  my $home = "";
  open(RF, "$invxml" );
  while(<RF>)
  {
    chomp;
    if ( /\<HOME NAME=\"([^\"]+)\" LOC=\"([^\"]+)\"/ )
    {
      $home = $2;
      my $hname = $1;
      my $dirowner;
      if ( -d "$home" )
      {
        $g{"ORAINV"}{$home}->{"NAME"} = $hname;
        $g{"ORAINV"}{$home}->{"TYPE"} = "U";
        $dirowner = getFileOwner($home) if -d $home;
        $g{"ORAINV"}{$home}->{"OUSER"} = $dirowner;
        print_d("Found in inventory $home\n");
        if ( /CRS=\"true\"/ )
        {
          $g{"ORAINV"}{$home}->{"TYPE"} = "GI";
        }
        if ( /REMOVED=\"T\"/ )
        {
          $g{"ORAINV"}{$home}->{"REMOVED"} = "T";
        }
      }
    }
  } # end while
  close(RF);
}

#
sub discover_system
{
  my @crsprocs = `ps -ef |grep d.bin|grep -v grep|sed 's/^ *//'`;
  chomp(@crsprocs);
  my @bgprocs = `ps -ef |grep ora_pmon_ |grep -v grep|sed 's/^ *//'`;
  chomp(@bgprocs);

  #TODO .. handle ADE, what if crs is down.. read inventroy
  # Also check crs_stat for CRSUP
  if (my ($matched) = grep /\/crsd.bin/, @crsprocs) 
  { # GI
    $g{"SYSTEM"} = "GI";
    print_d("System is GI\n");
    add_key_val($localhost, "SYSTEM", "TYPE", "GI");
    if ( $matched =~ /^(\w+) .* (\/.*)\/bin\/crsd.bin/ )
    {
      $g{"CRSHOME"} = $2;
      my ($matched) = grep /\/ocssd.bin/, @crsprocs;
      if ( $matched =~ /^(\w+) .* (\/.*)\/bin\/ocssd.bin/ )
      {
        $g{"CRSUSER"} = $1;
      }
      $g{"CRSUP"} = 1;
      print_d("Found CRS_HOME $g{CRSHOME} - $g{CRSUSER}\n");
      add_key_val($localhost, "SYSTEM", "CRSHOME", "$g{CRSHOME}");
      add_key_val($localhost, "SYSTEM", "CRSUSER", "$g{CRSUSER}");
      add_key_val($localhost, "SYSTEM", "CRSUP", "1");
    }
  }
   elsif ( my ($matched) = grep /\/ohasd.bin/, @crsprocs) 
  { # SIHA
    $g{"SYSTEM"} = "SIHA";
    if ( $matched =~ /^(\w+).* (\/.*)\/bin\/ohasd.bin/ )
    {
      $g{"CRSUSER"} = $1;
      $g{"CRSHOME"} = $2;
      $g{"CRSUP"} = 1;
      print_d("Found CRS_HOME $1 - $2\n");
    }
  }
   elsif ( $#bgprocs >= 0 )
  { # Single Instance
    $g{"SYSTEM"} = "SI";
    add_key_val($localhost, "SYSTEM", "TYPE", "SI");
    print_d("Found SI @bgprocs\n");
  }

  foreach my $line (@bgprocs)
  {
    if ( $line =~ / ora_pmon_(\w+)/ )
    {
      push(@{$g{"PMONS"}}, $1);
    }
  }
}

# Discover all databases from CRS/ps -ef etc
sub discover_db
{
  my @dbs = ();
  if ( $g{"SYSTEM"} eq "GI" )
  { # Run srvctl config database as grid user and get list
    my $srvctl = catfile($g{"CRSHOME"}, "bin", "srvctl");
    if ( $current_user eq "root" )
    {
      @dbs = `su $g{"CRSUSER"} -c "$srvctl config database"`;
    }
     else
    {
      @dbs = `$srvctl config database`;
    }
    chomp(@dbs);
    if ( @dbs )
    {
      push(@{$g{"DBS"}}, @dbs);
    }
  }
   elsif ( @{$g{"PMONS"}} )
  {
    push(@{$g{"DBS"}}, @{$g{"PMONS"}});
  }
  if ( @{$g{DBS}} )
  {
    print_d("Found dbs @{$g{DBS}}\n");
    get_db_details();
  }
}

# Sub get_db_details
# Get ORACLE_HOME, ORACLE_SID, trace directory locations, ORACLE_BASE
sub get_db_details
{
  my $LIMIT = no_of_child_proc();
  $LIMIT = 1 if ( ! $LIMIT || $LIMIT < 1 );
  $LIMIT = 10 if ( $LIMIT > 10 );

  my $CHILDREN = 0;
  my $dbname = "";

  print_d("Process Limit = $LIMIT\n");
  foreach $dbname (@{$g{DBS}})
  {
    if ( $CHILDREN == $LIMIT ) {
        print_d("Limit Reached.. waiting for one of child to finish..\n");
        my $PID = wait();
        $CHILDREN--;
    }

    $CHILDREN++;
    print_d("Starting process $CHILDREN for $dbname\n");
    my $pid;
    next if $pid = fork;
    die "fork failed: $!" unless defined $pid;

    print_d("Checking $dbname status\n");
    $ENV{ORACLE_HOME} = "";
    $ENV{ORACLE_SID} = "";
    $ENV{TFA_ORACLE_USER} = "";
    $ENV{TFA_ORACLE_VERSION} = "";
    $ENV{TFA_RUNNING_LOCAL} = "";
    dbutil_setOraEnv($TFAHOME, $dbname);
    print_d("ORACLE_HOME=$ENV{ORACLE_HOME}\n");
    print_d("ORACLE_SID=$ENV{ORACLE_SID}\n");
    print_d("TFA_ORACLE_USER=$ENV{TFA_ORACLE_USER}\n");
    print_d("TFA_ORACLE_VERSION=$ENV{TFA_ORACLE_VERSION}\n");
    print_d("TFA_RUNNING_LOCAL=$ENV{TFA_RUNNING_LOCAL}\n");
    add_key_val($localhost, $dbname, "ORACLE_HOME", $ENV{ORACLE_HOME});
    add_key_val($localhost, $dbname, "ORACLE_SID", $ENV{ORACLE_SID});
    add_key_val($localhost, $dbname, "ORACLE_USER", $ENV{TFA_ORACLE_USER});
    add_key_val($localhost, $dbname, "ORACLE_VERSION", $ENV{TFA_ORACLE_VERSION});
    add_key_val($localhost, $dbname, "RUNNING_LOCAL", $ENV{TFA_RUNNING_LOCAL});
    if ( $ENV{ORACLE_HOME} )
    {
      my $ohome = $ENV{ORACLE_HOME};
      $g{$dbname}->{HOME} = $ohome;
      $g{$dbname}->{SID} = $ENV{ORACLE_SID};
      $g{$dbname}->{USER} = $ENV{TFA_ORACLE_USER};
      $g{$dbname}->{VERSION} = $ENV{TFA_ORACLE_VERSION};
      $g{$dbname}->{TFA_RUNNING_LOCAL} = $ENV{TFA_RUNNING_LOCAL};
      if ( $ENV{TFA_RUNNING_LOCAL} == 1 )
      {
        my @out = run_a_sql("sql", "select 1 from dual;");
        print_d(@out);
        $g{$dbname}->{SYSDBA} = 1;
        if ( grep /ORA-01013/, @out )
        {
          $g{$dbname}->{SYSDBA} = 0;
        }
         else
        {
          get_db_diag_dest($dbname);
          get_db_params($dbname);
        }
      }
    }
    exit;
  }
  1 while (wait() != -1);
}

# Query diag dest
sub get_db_diag_dest
{
  my $dbname = shift;
  my $tmpsql = "/tmp/$$.tfa.sql";
  open(SWF, ">$tmpsql");
  print SWF "set feedback  off heading off lines 1200\n";
  print SWF "select substr(a.HOST_NAME,1,decode(instr(a.HOST_NAME,'.',1)-1, -1, length(a.HOST_NAME), instr(a.HOST_NAME,'.',1)-1))||'.RDBMS|$dbname|'|| a.INSTANCE_NAME||'.'|| b.name ||'='||b.value ".
                      "from     gv\$instance a,  gv\$parameter b ".
                      "where  a.inst_id = b.inst_id and lower(b.name) in  ".
                       "('diagnostic_dest', 'user_dump_dest', 'background_dump_dest');";
  my @out = run_a_sql("file", "$tmpsql");
  print_d(@out);
  foreach my $line (@out)
  {
    write_master($line);
  }
  #system("rm -f $tmpsql");
}

sub get_db_params
{
  my $dbname = shift;
  my $tmpsql = "/tmp/$$.tfa.sql";
  $dbname = uc($dbname);
  open(SWF, ">$tmpsql");
  print SWF "set feedback  off heading off lines 1200\n";
  print SWF "select i.host_name ||'.$dbname.'||i.instance_name||'.'||p.name || ' = ' || value ".
                     "from gv\$parameter p,gv\$instance i ".
                     "where p.inst_id = i.inst_id order by p.name,i.instance_name;";
  my @out = run_a_sql("file", "$tmpsql");
  my $file = catfile("dbparams","$dbname.param");
  write_to_file($file, @out);
  system("rm -f $tmpsql");
}

sub write_to_file
{
  my $f = shift;
  open(W1F, ">$f.out");
  foreach my $line (@_)
  {
    print W1F "$line\n";
  }
  close(W1F);
}

# Run a sql
sub run_a_sql
{
  my $iptype = shift;
  my $sql = shift;

  my $ORACLE_HOME = $ENV{ORACLE_HOME};
  my $ORACLE_SID = $ENV{ORACLE_SID};
  my $OH_dbOwner = $ENV{TFA_ORACLE_USER};

  my $runsqlsh="/tmp/runsql.$$.sh";
  open (SF, ">$runsqlsh");
  print SF "#!/bin/sh\n";
  print SF "ORACLE_SID=$ORACLE_SID; export ORACLE_SID\n";
  print SF "ORACLE_HOME=$ORACLE_HOME; export ORACLE_HOME\n";
  print SF "LD_LIBRARY_PATH=$ORACLE_HOME/lib; export LD_LIBRARY_PATH\n";
  if ( $iptype eq "file" )
  {
    print SF "cat $sql | $ORACLE_HOME/bin/sqlplus -s / as sysdba";
  }
   else
  {
    print SF "echo '$sql' | $ORACLE_HOME/bin/sqlplus -s / as sysdba";
  }
  close(SF);
  system("chmod 755 $runsqlsh");
  my @out;
  if ( $current_user eq "root" )
  {
    print_d("Running $runsqlsh as $OH_dbOwner\n");
    @out = `su $OH_dbOwner -c "$runsqlsh" 2>&1`;
  }
   else
  {
    print_d("Running $runsqlsh\n");
    @out = `$runsqlsh 2>&1`;
  }
  system("rm -f $runsqlsh");
  chomp(@out);
  return @out;
}

# Add to master file
sub add_key_val
{
  my $host = shift;
  my $comp = shift;
  my $key = shift;
  my $val = shift;
  write_master("$host.$comp.$key=$val");
}

sub write_master
{
  my $line = shift;
  flock WF, LOCK_EX  or die  "$0 [$$]: flock: $!";
  print WF "$line\n";
  flock WF, LOCK_UN  or die  "$0 [$$]: flock: $!";
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

# You can find the OMS and Management Agent entries in the /etc/oragchomelist file for all UNIX platforms except HPUNIX, HPia64, and Solaris Sparc.
# On HPUNIX, HPia64, Solaris Sparc platforms, the entries are present in /var/opt/oracle/oragchomelist.
sub discover_gc
{
  my $gcfile = "";
  $gcfile = "/etc/oragchomelist" if ( -r "/etc/oragchomelist" );
  $gcfile = "/var/opt/oracle/oragchomelist" if ( -r "/var/opt/oracle/oragchomelist" );
  my $tfaemdirs = catfile($TFAHOME,"resources","tfa_emdirectories.txt");
  if ( ! -f $tfaemdirs ) {
    my $hndlr;
    open $hndlr,'>',$tfaemdirs and close $hndlr or die "Failed to create $tfaemdirs.\n";
  }

  my $oms_home;
  my $oms_base;
  my $mwdir;
  my $emagent_1;
  my $emagent_2;
  my $emcomp  = "";
  my $emhtype = "";
  my $emadd;
  my $ohome   = "";
  my $hname   = "";
  my $ouser   = "";
  my @res ;
  my %home_processed;

  foreach my $key ( keys %{$g{"ORAINV"}} ) {
     $ohome = $key;
     $hname = $g{"ORAINV"}{$key}->{"NAME"};
     $ouser = $g{"ORAINV"}{$key}->{"OUSER"};
     $emadd = FALSE;

     if ( $hname =~ /oms/ ) {
       $emcomp   = "OMS";
       $emhtype  = "ORACLE_HOME"; 
       $emadd    = TRUE;
     } # end if oms

     if ( $hname =~ /agent/ ) {
       $emcomp   = "EMAGENT";
       $emhtype  = "ORACLE_HOME";
       $emadd    = TRUE;
     } # end if agent

     if ( $emadd ) {
       $lohome = $ohome;
       $lohome =~ s/\\/\\\\/g;  
       $lohome =~ s/\./\\\./g;
       $lohome =~ s/\:/\\\:/g; 
       @res = tfactlshare_look4regex($tfaemdirs,"($localhost\%$emcomp\%$emhtype=$lohome)");
       if ( not @res ) {
         open(EMF, ">>$tfaemdirs");
         flock EMF, LOCK_EX  or die  " [$$]: flock: $!";
         if ( $emcomp eq "EMAGENT" ) {
           if ( $IS_WINDOWS ) {
             $gcfile = catfile($ohome,"install","oragchomelist");
           } # end if $IS_WINDOWS
           my $insthomefound = FALSE;
           print EMF "$localhost\%$emcomp\%$emhtype=$ohome\n";
           if ( -r $gcfile ) {
             @res = tfactlshare_look4regex($gcfile,"$lohome:(.*)");
             if ( length $res[0] ) {
               $emhtype="INSTANCE_HOME";
               $ohome  =$res[0];
               print EMF "$localhost\%$emcomp\%$emhtype=$ohome\n";
               $insthomefound = TRUE;
             } # end if length $res[0]
           } # end if -r $gcfile
           # Locate INSTANCE_HOME for given ORACLE_HOME
           # ------------------------------------------
           if ( not $insthomefound ) {
             my $emctl = catfile($ohome,"bin","emctl");
             my @outcmd = `su $ouser $emctl getemhome 2>&1`;
             foreach my $line (@outcmd) {
                if ( $line =~ /EMHOME=(.*)/ ) {
                  $emhtype="INSTANCE_HOME";
                  $ohome  = $1;
                  print EMF "$localhost\%$emcomp\%$emhtype=$ohome\n";
                  print "INSTANCE_HOME added \n";
                }
             }
           } # end if not $insthomefound
         } elsif ( $emcomp eq "OMS" ) {
           my $omsinst_home;
           my $em_nodemgr_home;
           my $adm_server_name;
           my $em_domain_home;
           my $omsname;
           $home_processed{$ohome} = 1;
           print EMF "$localhost\%$emcomp\%$emhtype=$ohome\n";
           add_key_val($localhost, "OMS", "ORACLE_HOME", "$ohome");
           add_key_val($localhost, "EMAGENT", "user_dump_dest", "$ohome/sysman/prov/agentpush");
           add_key_val($localhost, "OMS", "user_dump_dest", "$ohome/cfgtoollogs");
           add_key_val($localhost, "OMS", "user_dump_dest", "$ohome/sysman/log/schemamanager");
           add_key_val($localhost, "OMS", "user_dump_dest", "$ohome/.gcinstall_temp");

           #Get INSTANCE_HOME of the OMS 
           my $file = catfile($ohome,"sysman","config","emInstanceMapping.properties");
           if ( -e $file and -r $file ) {
             my @res =  tfactlshare_look4regex($file,".*=(.*/emgc.properties)");
             if ( @res ) {
               $omsinst_home    = (tfactlshare_look4regex($res[0],"EM_INSTANCE_HOME="))[0];
               $em_nodemgr_home = (tfactlshare_look4regex($res[0],"EM_NODEMGR_HOME="))[0];
               $adm_server_name = (tfactlshare_look4regex($res[0],"ADMIN_SERVER_NAME="))[0];
               $em_domain_home  = (tfactlshare_look4regex($res[0],"EM_DOMAIN_HOME="))[0];
               $omsname         = (tfactlshare_look4regex($res[0],"OMSNAME="))[0];

             }
             if ($omsinst_home) {
               print EMF"$localhost\%$emcomp\%INSTANCE_HOME\%=$omsinst_home";
               add_key_val($localhost, "OCM", "user_dump_dest", "$omsinst_home/sysman/log");
             }
             if ( $em_nodemgr_home ){
               add_key_val($localhost, "EMWLS", "user_dump_dest", "$em_nodemgr_home");
             }
             if ( $em_domain_home ) {
               add_key_val($localhost, "EMWLS", "user_dump_dest", "$em_domain_home/servers/$admin_server_name/logs") if ( $admin_server_name );
               add_key_val($localhost, "EMWLS", "user_dump_dest", "$em_domain_home/servers/$omsname/logs") if ( $omsname );
             }
                         
           }
         } else {
           print EMF "$localhost\%$emcomp\%$emhtype=$ohome\n";
         } # end if $emcomp eq "EMAGENT"
         flock EMF, LOCK_UN  or die  " [$$]: flock: $!";
         close(EMF);
       }
     } # end if $emadd

  } # end foreach keys %{$g{"ORAINV"}}


  if ( -r $gcfile )
  {
    open(RF, $gcfile);
    while(<RF>)
    {
      chomp;
      my $line = $_;
      if ( $line =~ /^(.*)\/([^\/]+)\/oms/ )
      {
        $oms_home = $line;
        $oms_base = $1;
        $mwdir = $2;
      }
       elsif ( $line =~ /(.*)\/emcc.*/ )
      {
        $oms_home = $line;
      }
       elsif ( $line =~ /(.*)\:(\/.*)\/agent_inst/ )
      {
        $emagent_1 = $1;
        $emagent_2 = $2;
      }
    }
    close(RF);
    #check if oms home was already proccessed 
    #so that we dont duplicate entries.....
    next if ( exists $home_processed{$oms_home} );
    if ( $oms_home )
    {
      add_key_val($localhost, "OMS", "ORACLE_HOME", "$oms_home");
    }
    if ( $oms_base )
    {
      add_key_val($localhost, "EMAGENT", "user_dump_dest", "$oms_home/sysman/prov/agentpush");
      add_key_val($localhost, "OCM", "user_dump_dest", "$oms_base/gc_inst/em/ccr/hosts");
      add_key_val($localhost, "OCM", "user_dump_dest", "$oms_home/ccr/hosts");
      add_key_val($localhost, "OMS", "user_dump_dest", "$oms_home/cfgtoollogs");
      add_key_val($localhost, "OMS", "user_dump_dest", "$oms_home/sysman/log/schemamanager");
      add_key_val($localhost, "OMS", "user_dump_dest", "$oms_base/$mwdir/.gcinstall_temp");
      add_key_val($localhost, "OCM", "user_dump_dest", "$oms_base/gc_inst/em/EMGC_OMS1/sysman/log");
      add_key_val($localhost, "EMWLS", "user_dump_dest", "$oms_base/gc_inst/user_projects/domains/GCDomain/servers/EMGC_ADMINSERVER/logs");
      add_key_val($localhost, "EMWLS", "user_dump_dest", "$oms_base/gc_inst/user_projects/domains/GCDomain/servers/EMGC_OMS1/logs");
      add_key_val($localhost, "EMWLS", "user_dump_dest", "$oms_base/gc_inst/NodeManager/emnodemanager");
    }
    if ( $emagent_1 )
    {
      add_key_val($localhost, "EMAGENT", "ORACLE_HOME", "$emagent_1");
    }
    if ( $emagent_2 )
    {
      add_key_val($localhost, "EMAGENT", "INSTANCE_HOME", "$emagent_2/agent_inst");
      add_key_val($localhost, "EMAGENT", "user_dump_dest", "$emagent_2/agent_inst/sysman/log");
      add_key_val($localhost, "EMAGENT", "user_dump_dest", "$emagent_2/sbin/cfgtoollogs");
      add_key_val($localhost, "EMAGENT", "user_dump_dest", "$emagent_1/cfgtoollogs");
      add_key_val($localhost, "EMPLUGINS", "user_dump_dest", "$emagent_2/agent_inst/install/logs");
    }
  } # end if

  my $mode = (stat($tfaemdirs))[2];
  $mode = sprintf("%04o",$mode & 07777);
  if ( $mode ne "0644" ) {
    chmod(oct("0644"),$tfaemdirs);
  }
}

sub no_of_cpus {
    my ($PROCESSORS)   = 2;
    if ( lc($OSNAME) eq 'linux' ) {
        $PROCESSORS =
          `cat /proc/cpuinfo 2>/dev/null|grep -w 'processor'|wc -l|sed 's/ //g'`;
    }
    elsif ( lc($OSNAME) eq 'solaris' ) {
        $PROCESSORS =
          `psrinfo -v 2>/dev/null|grep 'Status of processor'|wc -l|sed 's/ //g'`;
        if ( $PROCESSORS == 0 ) {
            $PROCESSORS = `/usr/bin/kstat -m cpu_info 2>/dev/null |egrep 'chip_id'|uniq|wc -l|sed 's/ //g'`;
        }
    }
    elsif ( lc($OSNAME) eq 'aix' ) {
        $PROCESSORS = `lsdev -Cc processor 2>/dev/null|wc -l|sed 's/ //g'`;
    }
    elsif ( lc($OSNAME) eq 'hp-ux' ) {
        $PROCESSORS =
          `cat /var/adm/syslog/syslog.log 2>/dev/null|grep 'processor'|wc -l|sed 's/ //g'`;
    }

    if ( $PROCESSORS !~ m/^\d+$/ ) { $PROCESSORS = 2; }

    return $PROCESSORS;
}

sub no_of_child_proc {
    my ($PROCESSORS)   = 2;
    my ($DEF_CHLD_CNT) = 1;

    $PROCESSORS=no_of_cpus();

    $DEF_CHLD_CNT = ceil( 25 / 100 * $PROCESSORS );

    return $DEF_CHLD_CNT;
}

