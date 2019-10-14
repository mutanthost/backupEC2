# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/runawr.pl /main/15 2018/05/28 15:06:28 bburton Exp $
#
# runawr.pl
# 
# Copyright (c) 2014, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      runawr.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    03/07/18 - Fix getcwd in AIX
#    bburton     11/01/17 - increase timeout for commands
#    recornej    07/25/17 - Fixed snapshot out of range.
#    manuegar    05/26/17 - manuegar_srdcwin11.
#    bburton     05/25/17 - Do not chown on windows
#    manuegar    04/21/17 - manuegar_srdcwin_shared.
#    bburton     03/07/17 - fix double semi colon
#    bburton     02/10/17 - fix checksu issues - bug 25521625
#    bburton     12/16/16 - remove /tmp
#    bburton     09/22/16 - changes for srdc dbperf
#    manuegar    09/03/16 - Support the -extractto switch in the TFA installer.
#    bburton     06/01/16 - Fix for MTS
#    bburton     07/15/15 - Need to open permissions for output file whilst
#                           sqlplus writes it
#    bburton     09/25/14 - Script to gather AWR information for TFA
#    bburton     09/25/14 - Creation
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
my $text;
my $html;
my $format="text";
my $hostname;
my $newfilename;
my $cwd = $IS_AIX ? $ENV{'PWD'} : getcwd();
my $goodorbad;

GetOptions ('ohome=s' => \$ohome,
            'osid=s' => \$sid,
            'ouser=s' => \$user,
            'from=s' => \$from,
            'to=s' => \$to,
            'html' => \$html,
            'text' => \$text,
            'hostname=s' => \$hostname,
            'good' => \$good,
            'bad' => \$bad,
             );

if ( $good ) {
   $goodorbad = "good";
   open (LOG2, '>', $hostname . "_goodawrcollect.log");
   print LOG2 "Collection for Good/BaseLine time\n";
} elsif ( $bad ) {
   $goodorbad = "bad";
   open (LOG2, '>', $hostname . "_badawrcollect.log");
   print LOG2 "Collection for Slow Performance time\n" if ( $bad );
} else {
   $goodorbad = "";
   open (LOG2, '>', $hostname . "_awrcollect.log");
   print LOG2 "Collection : Not known if good or bad\n" if ( $bad );
}
open (*STDERR, '>', $hostname . "_awrcollect.err");
open (*STDOUT, '>', $hostname . "_awrcollect.out");
print LOG2 localtime(time) . ": Running awr collection scripts for TFA \n";
print LOG2 "ORACLE_HOME: $ohome\n";
print LOG2 "ORACLE_SID: $sid\n";
print LOG2 "user: $user\n";
print LOG2 "from: $from\n";
print LOG2 "to: $to\n";

my $awrdir = "awrdir$$";
my $sqlfile = catfile($awrdir,"getsnaps$$.sql");
my $awrinfofile = catfile($awrdir,"awrinfo$$.out");
my $awrrunfile = catfile($awrdir,"awrrunfile$$.sql");
my $userid;
if ( ! $IS_WINDOWS ) {
  $userid = getpwnam($user);
} else {
  $userid = getlogin();
}
# Set for MTS connection to Database
$ENV{ORA_SERVER_THREAD_ENABLED}="FALSE";

print LOG2 "sqlfile: $sqlfile \n";
print LOG2 "awrinfofile: $awrinfofile \n";
print LOG2 "awrrunfile: $awrrunfile \n";
$format = "html" if ( $html );
$format = "text" if ( $text );
if ( -d $awrdir ) {
print LOG2 "Unable to create user specific AWR outout dir\n";
exit 0;
}
mkdir $awrdir , 0700;
chown $userid, 0 , $awrdir if not $IS_WINDOWS;

print LOG2 "AWR report format: $format\n";

print LOG2 localtime(time) . ": Generating sql file to gets snapshots  \n";
writeAWRsqlfile($from,$to);
print LOG2 localtime(time) . ": Done generating sql file to gets snapshots  \n";

print LOG2 localtime(time) . ": Running sql file to get snapshot IDs  \n";
runsqlFile ($ohome,$sid,$user,$sqlfile);
print LOG2 localtime(time) . ": Done Running sql file to get snapshot IDs from $from to $to \n";

if ( -z $awrinfofile ) {
  print LOG2 localtime(time) . ": Snapshot file was empty - No snapshots found \n";
} else {
  runAWRReports( $format );
}
unlink($sqlfile);
unlink($awrinfofile);
unlink($awrrunfile);
rmdir($awrdir);

close(LOG2);
close(*STDERR);
close(*STDOUT);

sub writeAWRsqlfile {
   open (OF, ">", "$sqlfile") or
           die("\nFailed to open sqlfile for writing get snap query \n");
   print OF "set heading off\n";
   print OF "set echo off\n";
   print OF "set feedback off\n";
   print OF "set pagesize 0\n";
   print OF "spool $awrinfofile\n";
   print OF "select snap_id, dbid, instance_number from ( ";
   print OF "select a.snap_id ,a.dbid ,a.instance_number,a.end_interval_time\n";
   print OF "from dba_hist_snapshot a,v\$instance b\n";
   print OF "where ((a.begin_interval_time < to_date('" . $from . "','YYYY-MM-DD HH24:MI:SS')\n";
   print OF "and a.end_interval_time > to_date('" . $from . "','YYYY-MM-DD HH24:MI:SS'))\n";
   print OF "or (a.begin_interval_time < to_date('" . $to . "','YYYY-MM-DD HH24:MI:SS')\n";
   print OF "and a.end_interval_time > to_date('" . $to . "','YYYY-MM-DD HH24:MI:SS'))\n";
   print OF "or (a.begin_interval_time > to_date('" . $from . "','YYYY-MM-DD HH24:MI:SS')\n";
   print OF "and a.end_interval_time < to_date('" . $to . "','YYYY-MM-DD HH24:MI:SS')))\n";
   print OF "and a.instance_number=b.instance_number\n";
   print OF "order by 3,1 ASC\n";
   print OF ") where end_interval_time <= to_date('". $to . "','YYYY-MM-DD HH24:MI:SS');\n";
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

sub runAWRReports {
   my $format = shift;
   my $lastsnapid=0;
   my $firstsnapid=0;
   my $nextsnapid = 0;
   my $dbid = "";
   my $instid = "";
   my $countawr=0;
      
   open (IF, "<", "$awrinfofile") or
              die("\nFailed to open awrinfo file containign snapshot info\n");
   while (<IF>) {
     $countawr++;
     #@snaps = split /\s+/;
     chomp();
     s/^\s+//;
     ($nextsnapid,$dbid,$instid) = split /\s+/;
     print "countawr:$countawr\n";
     print "firstsnapid:$lastsnapid\n";
     print "lastsnapid:$lastsnapid\n";
     print "nextsnapid:$nextsnapid\n";
     print "dbid:$dbid\n";
     print "instid:$instid\n";
     if ( $lastsnapid == 0 ) { 
        $lastsnapid = $nextsnapid;
        $firstsnapid = $nextsnapid;
     } else {
        print LOG2 localtime(time) . ": Building $awrrunfile for snaps $lastsnapid to $nextsnapid\n";
        my $outfilename = "$goodorbad" . "awr_$sid" ."_inst_$instid" ."_$lastsnapid" . "_$nextsnapid.";
        if ( $format eq "html" ) {
	   $outfilename .= "html";
        } else {
	   $outfilename .= "txt";
	}
        my $fulloutfilename = catfile($awrdir,$outfilename);
        open (AWRRUN,">","$awrrunfile") or 
              die("\nFailed to open awrrunfile file \n");
   
        print AWRRUN "define dbid=$dbid\n";
        print AWRRUN "define inst_num=$instid\n";
        print AWRRUN "define num_days=1\n";
        print AWRRUN "define begin_snap=$lastsnapid\n";
        print AWRRUN "define end_snap=$nextsnapid\n";
        print AWRRUN "define report_type=$format\n";
        print AWRRUN "define report_name=$fulloutfilename\n";
        print AWRRUN "@@?/rdbms/admin/awrrpti\n";
        print AWRRUN "exit\n";
        close(AWRRUN);
        print LOG2 localtime(time) . ": Running $awrrunfile for snaps $lastsnapid to $nextsnapid\n";
        runsqlFile ($ohome,$sid,$user,$awrrunfile);
        print LOG2 localtime(time) . ": Completed Running $awrrunfile for snaps $lastsnapid to $nextsnapid\n";
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
   if ( $firstsnapid ne $lastsnapid || $countawr > 2 ) {
      print LOG2 localtime(time) . ": Building $awrrunfile for total period snaps $firstsnapid to $nextsnapid\n";
      my $outfilename = $goodorbad . "awr_$sid" ."_inst_$instid" ."_$firstsnapid" . "_$nextsnapid.";
      if ( $format eq "html" ) {
         $outfilename .= "html";
      } else {
         $outfilename .= "txt";
      }
      my $fulloutfilename = catfile($awrdir,$outfilename);
      open (AWRRUN,">","$awrrunfile") or
         die("\nFailed to open awrrunfile file \n");

      print AWRRUN "define dbid=$dbid\n";
      print AWRRUN "define inst_num=$instid\n";
      print AWRRUN "define num_days=1\n";
      print AWRRUN "define begin_snap=$firstsnapid\n";
      print AWRRUN "define end_snap=$nextsnapid\n";
      print AWRRUN "define report_type=$format\n";
      print AWRRUN "define report_name=$fulloutfilename\n";
      print AWRRUN "@@?/rdbms/admin/awrrpti\n";
      print AWRRUN "exit\n";
      close(AWRRUN);
      print LOG2 localtime(time) . ": Running $awrrunfile for snaps $firstsnapid to $nextsnapid\n";
      runsqlFile ($ohome,$sid,$user,$awrrunfile);
      print LOG2 localtime(time) . ": Completed Running $awrrunfile for snaps $firstsnapid to $nextsnapid\n";
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
