# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/runaddm.pl /main/10 2018/05/28 15:06:28 bburton Exp $
#
# runaddm.pl
# 
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      runaddm.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    03/07/18 - Fix getcwd in AIX.
#    bburton     11/01/17 - increase timeout for commands
#    recornej    07/25/17 - Fixed snapshot out of range
#    manuegar    05/26/17 - manuegar_srdcwin11.
#    bburton     05/25/17 - Do not chown on windows
#    bburton     05/11/17 - remove unneeded checks
#    manuegar    05/09/17 - manuegar_srdcwin06.
#    manuegar    04/21/17 - manuegar_srdcwin_shared.
#    bburton     03/07/17 - fix double semi colon
#    bburton     12/16/16 - remove /tmp
#    bburton     10/21/16 - addm only has text format
#    bburton     09/22/16 - Creation
#    bburton     09/22/16 - Script to run an addm report for a specific period
# 
#####################################################################
#

use warnings;
use strict;
use English;
use Cwd;
use File::Copy;
use File::Path;
use File::Find;
use File::Basename;
use File::Spec::Functions;
use Getopt::Long;

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME).'/..';
  push @INC, dirname($PROGRAM_NAME).'/../common';
  push @INC, dirname($PROGRAM_NAME).'/../modules';
  push @INC, dirname($PROGRAM_NAME).'/../common/exceptions';
}

use tfactlglobal;
use tfactlshare;

if ( $^O eq "MSWin32" )
{
  eval q{use base 'Win32'; 1} or die $@; 
}

my $stmt;
my $ofile;
my $ohome;
my $sid;
my $user;
my $from;
my $good;
my $bad;
my $to;
my $hostname;
my $newfilename;
my $cwd = $IS_AIX ? $ENV{'PWD'} : getcwd();

GetOptions ('ohome=s' => \$ohome,
            'osid=s' => \$sid,
            'ouser=s' => \$user,
            'from=s' => \$from,
            'to=s' => \$to,
            'hostname=s' => \$hostname,
             );


open (LOG2, '>', $hostname . "_addmcollect.log");
open (*STDERR, '>', $hostname . "_addmcollect.err");
open (*STDOUT, '>', $hostname . "_addmcollect.out");
print LOG2 localtime(time) . ": Running addm collection scripts for TFA \n";
print LOG2 "ORACLE_HOME: $ohome\n";
print LOG2 "ORACLE_SID: $sid\n";
print LOG2 "user: $user\n";
print LOG2 "from: $from\n";
print LOG2 "to: $to\n";

my $addmdir = "addmdir$$";
my $sqlfile = catfile($addmdir,"getsnaps$$.sql");
my $addminfofile = catfile($addmdir,"addminfo$$.out");
my $addmrunfile = catfile($addmdir,"addmrunfile$$.sql");
my $userid;
if ( ! $IS_WINDOWS ) { 
  $userid = getpwnam($user);
} else {
  $userid = getlogin();
}

# Set for MTS connection to Database
$ENV{ORA_SERVER_THREAD_ENABLED}="FALSE";

print LOG2 "sqlfile: $sqlfile \n";
print LOG2 "addminfofile: $addminfofile \n";
print LOG2 "addmrunfile: $addmrunfile \n";
if ( -d $addmdir ) {
print LOG2 "Unable to create user specific ADDM outout dir\n";
exit 0;
}
mkdir $addmdir , 0700;
chown $userid, 0 , $addmdir if not $IS_WINDOWS;

print LOG2 localtime(time) . ": Generating sql file to gets snapshots  \n";
writeADDMsqlfile($from,$to);
print LOG2 localtime(time) . ": Done generating sql file to gets snapshots  \n";

print LOG2 localtime(time) . ": Running sql file to get snapshot IDs  \n";
runsqlFile ($ohome,$sid,$user,$sqlfile);
print LOG2 localtime(time) . ": Done Running sql file to get snapshot IDs from $from to $to \n";

runADDMReports();

unlink($sqlfile);
unlink($addminfofile);
unlink($addmrunfile);
rmdir($addmdir);

close(LOG2);
close(*STDERR);
close(*STDOUT);

sub writeADDMsqlfile {
   open (OF, ">", "$sqlfile") or
           die("\nFailed to open sqlfile for writing get snap query \n");
   print OF "set heading off\n";
   print OF "set echo off\n";
   print OF "set feedback off\n";
   print OF "set pagesize 0\n";
   print OF "spool $addminfofile\n";
   print OF "select snap_id, dbid, instance_number from ( ";
   print OF "select a.snap_id,a.dbid,a.instance_number, a.end_interval_time\n";
   print OF "from dba_hist_snapshot a,v\$instance b\n";
   print OF "where ((a.begin_interval_time < to_date('" . $from . "','YYYY-MM-DD HH24:MI:SS')\n";
   print OF "and a.end_interval_time > to_date('" . $from . "','YYYY-MM-DD HH24:MI:SS'))\n";
   print OF "or (a.begin_interval_time < to_date('" . $to . "','YYYY-MM-DD HH24:MI:SS')\n";
   print OF "and a.end_interval_time > to_date('" . $to . "','YYYY-MM-DD HH24:MI:SS'))\n";
   print OF "or (a.begin_interval_time > to_date('" . $from . "','YYYY-MM-DD HH24:MI:SS')\n";
   print OF "and a.end_interval_time < to_date('" . $to . "','YYYY-MM-DD HH24:MI:SS')))\n";
   print OF "and a.instance_number=b.instance_number\n";
   print OF "order by 3,1 ASC";
   print OF " ) where end_interval_time <= to_date('". $to . "','YYYY-MM-DD HH24:MI:SS');\n";
   print OF "spool off\n";
   print OF "exit\n";
   close(OF);
}
sub runsqlFile {
   my($ohome,$sid,$user,$sqlfile) = @_;
   my $command;

   my $sqlplus = catfile($ohome,"bin","sqlplus");
   $ENV{ORACLE_HOME}=$ohome;
   $ENV{ORACLE_SID}=$sid;
   $command = tfactlshare_checksu($user,"echo exit | $sqlplus -s / as sysdba \@$sqlfile");
   print LOG2 "Running Command : $command with ORACLE_HOME: $ENV{ORACLE_HOME} ORACLE_SID: $ENV{ORACLE_SID}\n";
   runtimedcommand($command,600);
}

sub runADDMReports {
   my $lastsnapid=0;
   my $firstsnapid=0;
   my $nextsnapid;
   my $dbid;
   my $instid;
   my $countawr=0;
   open (IF, "<", "$addminfofile") or
              die("\nFailed to open addminfo file containign snapshot info\n");
   while (<IF>) {
     #@snaps = split /\s+/;
     chomp();
     s/^\s+//;
     ($nextsnapid,$dbid,$instid) = split /\s+/;
     $countawr++;
     print "lastsnapid:$lastsnapid\n";
     print "nextsnapid:$nextsnapid\n";
     print "dbid:$dbid\n";
     print "instid:$instid\n";
     if ( $lastsnapid == 0 ) { 
        $lastsnapid = $nextsnapid;
        $firstsnapid = $nextsnapid;
     } else {
        print LOG2 localtime(time) . ": Building $addmrunfile for snaps $lastsnapid to $nextsnapid\n";
        my $outfilename = "addm_$sid" ."_inst_$instid" ."_$lastsnapid" . "_$nextsnapid.";
	$outfilename .= "txt";
        my $fulloutfilename = catfile($addmdir,$outfilename);
        open (ADDMRUN,">","$addmrunfile") or 
              die("\nFailed to open addmrunfile file \n");
   
        print ADDMRUN "define dbid=$dbid\n";
        print ADDMRUN "define inst_num=$instid\n";
        print ADDMRUN "define num_days=1\n";
        print ADDMRUN "define begin_snap=$lastsnapid\n";
        print ADDMRUN "define end_snap=$nextsnapid\n";
        print ADDMRUN "define report_name=$fulloutfilename\n";
        print ADDMRUN "@@?/rdbms/admin/addmrpti\n";
        print ADDMRUN "exit\n";
        close(ADDMRUN);
        print LOG2 localtime(time) . ": Running $addmrunfile for snaps $lastsnapid to $nextsnapid\n";
        runsqlFile ($ohome,$sid,$user,$addmrunfile);
        print LOG2 localtime(time) . ": Completed Running $addmrunfile for snaps $lastsnapid to $nextsnapid\n";
        $newfilename = catfile($cwd,$outfilename);
        if ( -e $fulloutfilename ) {
            if ( -l $fulloutfilename ) {
                print LOG2 localtime(time) . ": Not Moving $fulloutfilename as it was replaced by a symbolic Link\n";
                unlink($fulloutfilename);
            } else {
                print LOG2 localtime(time) . ": Moving $fulloutfilename to $newfilename\n";
		move ($fulloutfilename,$newfilename); 
            }
	}
        $lastsnapid = $nextsnapid;
     }
   }
   # if we only got one snapshot then likely we are at 1 hour snapshots and so we only got the last one in which case get the previous one.
   if ( $firstsnapid == $lastsnapid ) {
        $firstsnapid--;
   }

   # Now run a report between the very first and last snaps.
   if ( $firstsnapid ne $lastsnapid || $countawr > 2 ) { # we only got one snap period 
      print LOG2 localtime(time) . ": Building $addmrunfile for snaps $firstsnapid to $nextsnapid\n";
      my $outfilename = "addm_$sid" ."_inst_$instid" ."_$firstsnapid" . "_$nextsnapid.";
      $outfilename .= "txt";
      my $fulloutfilename = catfile($addmdir,$outfilename);
      open (ADDMRUN,">","$addmrunfile") or
         die("\nFailed to open addmrunfile file \n");

      print ADDMRUN "define dbid=$dbid\n";
      print ADDMRUN "define inst_num=$instid\n";
      print ADDMRUN "define num_days=1\n";
      print ADDMRUN "define begin_snap=$firstsnapid\n";
      print ADDMRUN "define end_snap=$nextsnapid\n";
      print ADDMRUN "define report_name=$fulloutfilename\n";
      print ADDMRUN "@@?/rdbms/admin/addmrpti\n";
      print ADDMRUN "exit\n";
      close(ADDMRUN);
      print LOG2 localtime(time) . ": Running $addmrunfile for snaps $firstsnapid to $nextsnapid\n";
      runsqlFile ($ohome,$sid,$user,$addmrunfile);
      print LOG2 localtime(time) . ": Completed Running $addmrunfile for snaps $firstsnapid to $nextsnapid\n";
      $newfilename = catfile($cwd,$outfilename);
      if ( -e $fulloutfilename ) {
          if ( -l $fulloutfilename ) {
              print LOG2 localtime(time) . ": Not Moving $fulloutfilename as it was replaced by a symbolic Link\n";
              unlink($fulloutfilename);
          } else {
              print LOG2 localtime(time) . ": Moving $fulloutfilename to $newfilename\n";
              move ($fulloutfilename,$newfilename);
          }
      }
   }
}

sub runtimedcommand  {
my $command = shift;
my $timeout = shift;
if ( !$timeout ) { $timeout = 10 };
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
