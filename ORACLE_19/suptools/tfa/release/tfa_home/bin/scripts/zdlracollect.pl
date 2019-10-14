# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/zdlracollect.pl /main/6 2017/03/01 08:11:28 bburton Exp $
#
# zdlracollect.pl
# 
# Copyright (c) 2014, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      zdlracollect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     12/16/16 - remove /tmp
#    manuegar    09/03/16 - Support the -extractto switch in the TFA installer.
#    bburton     06/01/16 - Fix for MTS
#    bburton     02/23/16 - ER 22294764 changes
#    bburton     07/23/15 - handle tightening of temp dir permissions
#    bburton     09/25/14 - New script to collect zdlra data
#    bburton     09/25/14 - Creation
# 
#####################################################################
#

BEGIN {
  # Add the directory of this file to the search path
  push @INC, "/opt/oracle.RecoveryAppliance/lib";
  $ENV{PATH} = "/usr/local/bin:".$ENV{PATH};
}

use warnings;
use strict;
use File::Copy;
use File::Path;
use File::Find;
use File::Basename;
use File::Spec::Functions;
use Getopt::Long;
use RA::DB::Oracle qw/GetEnv Connect Disconnect/;

if ( $^O eq "MSWin32" )
{
  eval q{use base 'Win32'; 1} or die $@;
}


my $stmt;
my $ofile;
my $hostname;
my $to;
my $from;
my $newfilename;
my $ora_env = GetEnv( TYPE => 'LOCAL');

GetOptions (
            'from=s' => \$from,
            'to=s' => \$to,
            'hostname=s' => \$hostname
             );

open (LOG2, '>', $hostname . "_zdlracollect.log");
open (*STDERR, '>', $hostname . "_zdlracollect.err");
open (*STDOUT, '>', $hostname . "_zdlracollect.out");
print LOG2 localtime(time) . ": Running zdlra collection scripts for TFA \n";
print LOG2 "hostname: $hostname\n";
print LOG2 "from: $from\n";
print LOG2 "to: $to\n";
print LOG2 "ORACLE_HOME: $ora_env->{ORACLE_HOME}\n";
print LOG2 "ORACLE_SID: $ora_env->{ORACLE_SID}\n";

my $tempdir = "tfazdlradir$$";
my $sqlfile = catfile($tempdir,"getincident$$.sql");
my $sqlfile2 = catfile($tempdir,"get_us_queuerectasks$$.sql");
my $sqlfile3 = catfile($tempdir,"get_queuetapejobs$$.sql");
my $sqlfile4 = catfile($tempdir,"get_config$$.sql");
my $sqlfile5 = catfile($tempdir,"get_emcommand$$.sql");
my $infofile = catfile($tempdir,"zdlra_incidents$$.out");
my $infofile2 = catfile($tempdir,"zdlra_queuerectasks$$.out");
my $infofile3 = catfile($tempdir,"zdlra_queuetapejobs$$.out");
my $infofile4 = catfile($tempdir,"zdlra_config_table$$.out");
my $infofile5 = catfile($tempdir,"zdlra_emcommand$$.out");
my $obtool = catfile("","usr","bin","obtool");
my $user = "raext";
my $userid = getpwnam($user);
my $command;

# Set for MTS connection to Database
$ENV{ORA_SERVER_THREAD_ENABLED}="FALSE";

if ( -d $tempdir ) {
   print LOG2 localtime(time) . ":Unable to create user specific ZDLRA output directory\n";
   exit 0;
}
mkdir $tempdir, 0700;
chown $userid, 0, $tempdir;   

print LOG2 localtime(time) . ": Writing sql file $sqlfile to execute  \n";
writesqlfile();
print LOG2 localtime(time) . ": Completed Writing $sqlfile to execute  \n";
print LOG2 localtime(time) . ": Writing sql file $sqlfile2 to execute  \n";
writesqlfile2();
print LOG2 localtime(time) . ": Completed Writing $sqlfile2 to execute  \n";
print LOG2 localtime(time) . ": Writing sql file $sqlfile3 to execute  \n";
writesqlfile3();
print LOG2 localtime(time) . ": Completed Writing $sqlfile3 to execute  \n";
print LOG2 localtime(time) . ": Writing sql file $sqlfile4 to execute  \n";
writesqlfile4();
print LOG2 localtime(time) . ": Completed Writing $sqlfile4 to execute  \n";
print LOG2 localtime(time) . ": Writing sql file $sqlfile5 to execute  \n";
writesqlfile5();
print LOG2 localtime(time) . ": Completed Writing $sqlfile5 to execute  \n";
print LOG2 localtime(time) . ": Running SQL File $sqlfile\n";
runsqlFile ($ora_env->{ORACLE_HOME},$ora_env->{ORACLE_SID},$sqlfile);
print LOG2 localtime(time) . ": Completed Running SQL File $sqlfile\n";
#unlink($sqlfile);
if ( -e $infofile ) {
   if ( -l $infofile ) {
      print LOG2 localtime(time) . ": Not Moving $infofile as it was replaced by a symbolic Link\n";
      unlink($infofile);
   } else {
      print LOG2 localtime(time) . ": Moving $infofile to $hostname" . "_zdlra_incidents.out \n";
      move($infofile,$hostname . "_zdlra_incidents.out");
   }
}
print LOG2 localtime(time) . ": Running SQL File $sqlfile2\n";
runsqlFile ($ora_env->{ORACLE_HOME},$ora_env->{ORACLE_SID},$sqlfile2);
print LOG2 localtime(time) . ": Completed Running SQL File $sqlfile2\n";
unlink($sqlfile2);
if ( -e $infofile2 ) {
   if ( -l $infofile2 ) {
      print LOG2 localtime(time) . ": Not Moving $infofile2 as it was replaced by a symbolic Link\n";
      unlink($infofile2);
   } else {
      print LOG2 localtime(time) . ": Moving $infofile2 to $hostname" . "_zdlra_incidents.out \n";
      move($infofile2,$hostname . "_zdlra_replication_jobs.out");
   }
}
print LOG2 localtime(time) . ": Running SQL File $sqlfile3\n";
runsqlFile ($ora_env->{ORACLE_HOME},$ora_env->{ORACLE_SID},$sqlfile3);
print LOG2 localtime(time) . ": Completed Running SQL File $sqlfile3\n";
unlink($sqlfile3);
if ( -e $infofile3 ) {
   if ( -l $infofile3 ) {
      print LOG2 localtime(time) . ": Not Moving $infofile3 as it was replaced by a symbolic Link\n";
      unlink($infofile3);
   } else {
      print LOG2 localtime(time) . ": Moving $infofile3 to $hostname" . "_zdlra_incidents.out \n";
      move($infofile3,$hostname . "_zdlra_tape_queue.out");
   }
}
print LOG2 localtime(time) . ": Running SQL File $sqlfile4\n";
runsqlFile ($ora_env->{ORACLE_HOME},$ora_env->{ORACLE_SID},$sqlfile4);
print LOG2 localtime(time) . ": Completed Running SQL File $sqlfile4\n";
unlink($sqlfile4);
if ( -e $infofile4 ) {
   if ( -l $infofile4 ) {
      print LOG2 localtime(time) . ": Not Moving $infofile4 as it was replaced by a symbolic Link\n";
      unlink($infofile4);
   } else {
      print LOG2 localtime(time) . ": Moving $infofile4 to $hostname" . "_zdlra_incidents.out \n";
      move($infofile4,$hostname . "_zdlra_config_table.out");
   }
}
print LOG2 localtime(time) . ": Running SQL File $sqlfile5\n";
runsqlFile ($ora_env->{ORACLE_HOME},$ora_env->{ORACLE_SID},$sqlfile5);
print LOG2 localtime(time) . ": Completed Running SQL File $sqlfile5\n";
unlink($sqlfile5);
if ( -e $infofile5 ) {
   if ( -l $infofile5 ) {
      print LOG2 localtime(time) . ": Not Moving $infofile5 as it was replaced by a symbolic Link\n";
      unlink($infofile5);
   } else {
      print LOG2 localtime(time) . ": Moving $infofile5 to $hostname" . "_zdlra_incidents.out \n";
      move($infofile5,$hostname . "_zdlra_emcommands.out");
   }
}
rmdir($tempdir);

# Gather zdlra-sw-id
my $swidfile = catfile($ora_env->{ORACLE_HOME},"rdbms","install","zdlra","zdlra-software-id");
$command = checksu("raext","/bin/cat $swidfile ") . " > $hostname" . "_zdlra_sw_id.log";
runtimedcommand($command);

# Gather ob/xcr dir
$command = "/bin/tar zcvf job_xcrs.tar.gz /usr/etc/ob/xcr/" ;
runtimedcommand($command);
$command = "/bin/ps -efww | /bin/grep ob > $hostname" . "_psefww_grepob";
runtimedcommand($command);

if ( -e $obtool ) {
   print LOG2 localtime(time) . ": Running obtool commands \n";
   #  jobs now 
   $command = $obtool . " lsj > $hostname"."_obtool_lsj_now";
   runtimedcommand($command);
   #  jobs at issue time 
   $command = $obtool . " lsj --to ". formatdate($to) ." --from ". formatdate($from) ." > $hostname"."_obtool_lsj";
   runtimedcommand($command);
   # active jobs
   $command = $obtool . " lsj --log > $hostname"."_obtool_lsj_log";
   runtimedcommand($command);
   # completed jobs
   $command = $obtool . " lsj --log -c --to ". formatdate($to) ." --from ". formatdate($from) ." > $hostname"."_obtool_lsj_log_c";
   runtimedcommand($command);
   $command = $obtool . " lsd -ldg > $hostname"."_obtool_lsd_ldg";
   runtimedcommand($command);
   $command = $obtool . " lspiece -S > $hostname"."_obtool_lspiece_S";
   runtimedcommand($command);
   $command = $obtool . " lsh -l > $hostname"."_obtool_lsh_l";
   runtimedcommand($command);
   $command = $obtool . " lsd -t library -s > $hostname"."_obtool_lsdt_librarys"; 
   runtimedcommand($command);
   open (INF, '<', "$hostname"."_obtool_lsdt_librarys");
   while(<INF>)
   {
        chomp();
        $command = $obtool . " lsvol -L " . $_ . " -l > $_.inv.txt"; 
        #print "$command\n";
        runtimedcommand($command,10);
   }
   close (INF);
   open (INF, '<', "$hostname"."_obtool_lsj_log");
   while(<INF>)
   {
	if ( /^(\S+\d+\.\d+)\s/ )
	{
	   $command = $obtool . " catxcr -l0 " . $1 . " >> $hostname"."_obtool_catxcr";
           #print "$command\n";
           runtimedcommand($command,10);
	}
   }
   close (INF);
   open (INF, '<', "$hostname"."_obtool_lsj_log_c");
   while(<INF>)
   {
	if ( /^(\S+\d+\.\d+)\s/ )
	{
	   $command = $obtool . " catxcr -l0 " . $1 . " >> $hostname"."_obtool_catxcr";
           #print "$command\n";
           runtimedcommand($command,10);
	}
   }
   close (INF);
   print LOG2 localtime(time) . ": Completed Running obtool commands \n";
}

print LOG2 localtime(time) . ": Completed Running zdlracollect.pl for TFA \n";
close(LOG2);
close(*STDERR);
close(*STDOUT);

sub formatdate {
  my $time = shift;
  if ( $time =~ /(\d+)-(\d+)-(\d+) (\d+:\d+:\d+)/ )
  {
    return "$1/$2/$3.$4";
  }
   else
  {
    print LOG2 localtime(time) . "Error: Date format unexpected : $time\n";
    return;
  }
}
sub writesqlfile {
   open (OF, ">", "$sqlfile") or
           die("\nFailed to open sqlfile for writing get snap query \n");
   print OF "set echo off\n";
   print OF "set feedback off\n";
   print OF "set termout off\n";
   print OF "set pagesize 9999\n";
   print OF "spool $infofile\n";
   print OF "select *\n";
   print OF "from rasys.ra_incident_log \n";
   print OF "where severity in ('ERROR','INTERNAL')";
   print OF "order by last_seen,error_code ASC;\n";
   print OF "spool off\n";
   close(OF);
}
# Sql to show the number of queued replication tasks for each database. 
sub writesqlfile2{
   open (OF, ">", "$sqlfile2") or
           die("\nFailed to open sqlfile for writing queued rep tasks \n");
   print OF "set serveroutput on tab off pages 1000 lines 32767 trimspool on lines 222\n";
   print OF "spool $infofile2\n";
   print OF "select db_unique_name, count(*)\n";
   print OF "from rasys.ra_sbt_task \n";
   print OF "where lib_name in ( select distinct (sbt_library_name) "; 
   print OF "from ra_replication_server )\n";
   print OF "and replication='YES'\n";
   print OF "and state='EXECUTABLE'\n";
   print OF "group by DB_UNIQUE_NAME;\n";
   print OF "spool off\n";
   close(OF);
}
# Sql to show number of queued Copy-to-Tape tasks for each database
sub writesqlfile3{
   open (OF, ">", "$sqlfile3") or
           die("\nFailed to open sqlfile for writing copy to tape tasks \n");
   print OF "set serveroutput on tab off pages 1000 lines 32767 trimspool on lines 222\n";
   print OF "spool $infofile3\n";
   print OF "select db_unique_name, count(*)\n";
   print OF "from rasys.ra_sbt_task \n";
   print OF "where replication='YES'\n";
   print OF "and state='EXECUTABLE'\n";
   print OF "group by DB_UNIQUE_NAME;\n";
   print OF "spool off\n";
   close(OF);
}
# Sql to show configuration table
sub writesqlfile4{
   open (OF, ">", "$sqlfile4") or
           die("\nFailed to open sqlfile for writing config data \n");
   print OF "set pages 1000 lines 1000 trimspool on tab off\n";
   print OF "spool $infofile4\n";
   print OF "select name,value\n";
   print OF "from rasys.config \n";
   print OF "order by name;\n";
   print OF "spool off\n";
   close(OF);
}
#Sql to get EM command History
sub writesqlfile5{
   open (OF, ">", "$sqlfile5") or
           die("\nFailed to open sqlfile for writing EM command history \n");
   print OF "set pages 1000 lines 1000 trimspool on tab off\n";
   print OF "spool $infofile5\n";
   print OF "select command_issued,execute_time,results\n";
   print OF "from rasys.ra_api_history \n";
   print OF "where execute_time > to_date('" . $from . "','YYYY-MM-DD HH24:MI:SS')\n";
   print OF "and execute_time < to_date('" . $to . "','YYYY-MM-DD HH24:MI:SS')\n";
   print OF "spool off\n";
   close(OF);
}

sub runsqlFile {
   my($ohome,$sid,$sqlfile) = @_;
   my $command;

   my $sqlplus = catfile($ohome,"bin","sqlplus");
   $ENV{ORACLE_HOME}=$ohome;
   $ENV{ORACLE_SID}=$sid;
   #print "su: $ouser: $sqlplus -s / < $sqlfile \n";
   $command = checksu("raext","$sqlplus -s /  < $sqlfile");
   runtimedcommand($command);
}

sub runtimedcommand  {
my $command = shift;
my $timeout = shift;
my $ktree_level = 0;

if ( !$timeout ) { $timeout = 10 };
print LOG2 localtime(time) . ": Running " . $command . " as a timed command for $timeout seconds.\n";
eval {
    local $SIG{ALRM} = sub { die "Timeout\n" };
    alarm $timeout;
    `$command`;
    alarm 0;
};
if ($@) {
    print LOG2 localtime(time) . ": $command timed out.\n";
    return(99);
} else {
    print LOG2 localtime(time) . ": $command successful.\n" ;
    return(0);
}
}

sub checksu {
  my $requser    = shift;
  my $cmd        = shift;
  my $IS_WINDOWS = 0;
  my $current_user;

  if ( $^O eq "MSWin32" ) { 
    $IS_WINDOWS = 1;
    $current_user = Win32::LoginName();
    if ( Win32::IsAdminUser() ) { 
      $current_user = "root";
    }   
  } else {
    $current_user = getpwuid($<);
  }

  if ( ($current_user eq "root") && (not $IS_WINDOWS) ) { 
    return "SU $requser -c '" . $cmd . "'";
  } else {
    return $cmd; 
  }
}
