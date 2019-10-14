# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/runawrcompare.pl /main/8 2018/05/28 15:06:28 bburton Exp $
#
# runawrcompare.pl
# 
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      runawrcompare.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    05/15/18 - Prevent unintitialize value of badnextsnapid.
#    recornej    03/07/18 - Fix getcwd in AIX
#    bburton     11/01/17 - increase timeout for commands
#    recornej    07/25/17 - Fixed snapshot out of range
#    manuegar    05/26/17 - manuegar_srdcwin11.
#    bburton     05/25/17 - Do not chown on windows
#    bburton     05/11/17 - remove unneeded checks
#    manuegar    05/09/17 - manuegar_srdcwin06.
#    manuegar    04/21/17 - manuegar_srdcwin_shared.
#    bburton     12/16/16 - remove /tmp
#    bburton     09/22/16 - Script to call the comparisonreport for 2 AWR
#                           snapshot periods
#    bburton     09/22/16 - Creation
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
my $to;
my $baselinefrom;
my $baselineto;
my $text;
my $html;
my $format="text";
my $hostname;
my $newfilename;
my $cwd = $IS_AIX ? $ENV{'PWD'} : getcwd();

GetOptions ('ohome=s' => \$ohome,
            'osid=s' => \$sid,
            'ouser=s' => \$user,
            'from=s' => \$from,
            'to=s' => \$to,
            'baselinefrom=s' => \$baselinefrom,
            'baselineto=s' => \$baselineto,
            'html' => \$html,
            'text' => \$text,
            'hostname=s' => \$hostname,
             );

open (LOG2, '>', $hostname . "_awrcomparecollect.log");
open (*STDERR, '>', $hostname . "_awrcomparecollect.err");
open (*STDOUT, '>', $hostname . "_awrcomparecollect.out");
print LOG2 localtime(time) . ": Running awr compare collection scripts for TFA \n";
print LOG2 "ORACLE_HOME: $ohome\n";
print LOG2 "ORACLE_SID: $sid\n";
print LOG2 "user: $user\n";
print LOG2 "from: $from\n";
print LOG2 "to: $to\n";
print LOG2 "baselinefrom: $from\n";
print LOG2 "baselineto: $to\n";


my $awrdir = "awrdir$$";
my $sqlfile = catfile($awrdir,"getsnaps$$.sql");
my $awrinfofilebad = catfile($awrdir,"awrinfo$$.out");
my $awrinfofilegood = catfile($awrdir,"awrinfobaseline$$.out"); 
my $awrrunfile = catfile($awrdir,"awrrunfile$$.sql");
my $userid;
if ( ! $IS_WINDOWS ) {
  $userid = getpwnam($user);
} else {
  $userid = getlogin();
}

my $awrinfofile = $awrinfofilebad;

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

print LOG2 "AWR Compare report format: $format\n";

# Getting snaps for first timespan
print LOG2 localtime(time) . ": Generating sql file to gets snapshots for $from to $to  \n";
writeAWRsqlfile($from,$to);
print LOG2 localtime(time) . ": Done generating sql file to gets snapshots  \n";

print LOG2 localtime(time) . ": Running sql file to get snapshot IDs  \n";
runsqlFile ($ohome,$sid,$user,$sqlfile);
print LOG2 localtime(time) . ": Done Running sql file to get snapshot IDs from $from to $to \n";

# Getting snaps for second timespan
$awrinfofile = $awrinfofilegood;
$from = $baselinefrom;
$to = $baselineto;
print LOG2 "awrinfofile: $awrinfofile \n";
print LOG2 localtime(time) . ": Generating sql file to gets snapshots for $baselinefrom to $baselineto  \n";
writeAWRsqlfile($baselinefrom,$baselineto);
print LOG2 localtime(time) . ": Done generating sql file to gets snapshots  \n";

print LOG2 localtime(time) . ": Running sql file to get snapshot IDs  \n";
runsqlFile ($ohome,$sid,$user,$sqlfile);
print LOG2 localtime(time) . ": Done Running sql file to get snapshot IDs from $from to $to \n";


runAWRDiffReports( $format );

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
   print OF "select a.snap_id,a.dbid,a.instance_number,a.end_interval_time\n";
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

sub runAWRDiffReports {
   my $format = shift;
   my $badlastsnapid=0;
   my $goodlastsnapid=0;
   my $badfirstsnapid=0;
   my $goodfirstsnapid=0;
   my $badnextsnapid;
   my $goodnextsnapid;
   my $dbid;
   my $instid;
   my $filesnapid;
   my @badsnaps;
   my @goodsnaps;
   my $countawr=0;
   open (IF, "<", "$awrinfofilebad") or
              die("\nFailed to open awrinfo file containig bad performance snapshot info\n");
   while (<IF>) {
     chomp();
     s/^\s+//;
     ($filesnapid,$dbid,$instid) = split /\s+/;
     print "filesnapid:$filesnapid\n";
     print "dbid:$dbid\n";
     print "instid:$instid\n";
     push (@badsnaps, $filesnapid);
   }
   close (IF);
   open (IF, "<", "$awrinfofilegood") or
              die("\nFailed to open awrinfo file containing good performance snapshot info\n");
   while (<IF>) {
     chomp();
     s/^\s+//;
     ($filesnapid,$dbid,$instid) = split /\s+/;
     print "filesnapid:$filesnapid\n";
     print "dbid:$dbid\n";
     print "instid:$instid\n";
     push (@goodsnaps, $filesnapid);
   }
   close (IF);
   if ( scalar(@goodsnaps) < 1 || scalar(@badsnaps) < 1 ) {
     print LOG2 localtime(time) . ": Zero Snapshots to compare - need 2 for each period. \n";
     return 0;
   }
   if ( scalar(@goodsnaps) == 1 ) {
     print LOG2 localtime(time) . ": Only one Good Snapshots to compare - need 2 for each period will use previous. \n";
     push (@goodsnaps, $goodsnaps[0]--);
   }
   if ( scalar(@badsnaps) == 1 ) {
     print LOG2 localtime(time) . ": Only one Bad Snapshots to compare - need 2 for each period will use previous. \n";
     push (@badsnaps, $badsnaps[0]--);
   }
   if ( scalar(@goodsnaps) != scalar(@badsnaps) ) {
     print LOG2 localtime(time) . ": Unable to Compare all AWR due to mismatch in number of snapshots\n";
     print LOG2 localtime(time) . ": Running compare against first and last ID for each period only\n";
     $badlastsnapid = shift(@badsnaps); # first snapid to use
     $badfirstsnapid = $badlastsnapid; 
     $badnextsnapid = pop(@badsnaps);   # last snapid to use
     $goodlastsnapid = shift(@goodsnaps);
     $goodfirstsnapid = $goodlastsnapid; 
     $goodnextsnapid = pop(@goodsnaps);
   } else {
     foreach my $snap (@badsnaps) {
       $badnextsnapid = $snap; 
       $goodnextsnapid = shift(@goodsnaps); 
       $countawr++;
       print "countawr:$countawr\n";
       print "badfirstsnapid:$badlastsnapid\n";
       print "goodfirstsnapid:$goodlastsnapid\n";
       print "badlastsnapid:$badlastsnapid\n";
       print "badnextsnapid:$badnextsnapid\n";
       print "goodlastsnapid:$goodlastsnapid\n";
       print "goodnextsnapid:$goodnextsnapid\n";
       print "dbid:$dbid\n";
       print "instid:$instid\n";
       if ( $badlastsnapid == 0 ) { 
          $badlastsnapid = $badnextsnapid;
          $goodlastsnapid = $goodnextsnapid;
          $badfirstsnapid = $badnextsnapid;
          $goodfirstsnapid = $goodnextsnapid;
       } else {
          print LOG2 localtime(time) . ": Building Compare $awrrunfile for bad snaps $badlastsnapid to $badnextsnapid\n";
          print LOG2 localtime(time) . ": Good snaps $goodlastsnapid to $goodnextsnapid\n";
          my $outfilename = "compareawr_$sid" ."_inst_$instid" ."_$badlastsnapid" . "_$badnextsnapid"."_with_$goodlastsnapid" . "_$goodnextsnapid.";
          if ( $format eq "html" ) {
  	   $outfilename .= "html";
          } else {
  	   $outfilename .= "txt";
   	  }
          my $fulloutfilename = catfile($awrdir,$outfilename);
          open (AWRRUN,">","$awrrunfile") or 
              die("\nFailed to open awrrunfile file \n");
   
          print AWRRUN "define dbid=$dbid\n";
          print AWRRUN "define dbid2=$dbid\n";
          print AWRRUN "define inst_num=$instid\n";
          print AWRRUN "define inst_num2=$instid\n";
          print AWRRUN "define num_days=1\n";
          print AWRRUN "define num_days2=1\n";
          print AWRRUN "define begin_snap=$badlastsnapid\n";
          print AWRRUN "define end_snap=$badnextsnapid\n";
          print AWRRUN "define begin_snap2=$goodlastsnapid\n";
          print AWRRUN "define end_snap2=$goodnextsnapid\n";
          print AWRRUN "define report_type=$format\n";
          print AWRRUN "define report_name=$fulloutfilename\n";
          print AWRRUN "@@?/rdbms/admin/awrddrpi\n";
          print AWRRUN "exit\n";
          close(AWRRUN);
          print LOG2 localtime(time) . ": Running Compare $awrrunfile for snaps $badlastsnapid to $badnextsnapid with $goodlastsnapid to $goodnextsnapid\n";
          runsqlFile ($ohome,$sid,$user,$awrrunfile);
          print LOG2 localtime(time) . ": Completed Running Compare $awrrunfile for snaps $badlastsnapid to $badnextsnapid with $goodlastsnapid to $goodnextsnapid\n";
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
          $badlastsnapid = $badnextsnapid;
          $goodlastsnapid = $goodnextsnapid;
       } # End Else snapid==0
     }
   }
   # Now run a report between the very first and last snaps or the only 2
   if ( $badfirstsnapid ne $badlastsnapid && $countawr > 2) { # we only got one snap period or 2 
      print LOG2 localtime(time) . ": Building Compare $awrrunfile for bad snaps $badfirstsnapid to $badnextsnapid\n";
      print LOG2 localtime(time) . ": Good snaps $goodfirstsnapid to $goodnextsnapid\n";
      my $outfilename = "compareawr_$sid" ."_inst_$instid" ."_$badfirstsnapid" . "_$badnextsnapid"."_with_$goodfirstsnapid" . "_$goodnextsnapid.";
      if ( $format eq "html" ) {
         $outfilename .= "html";
      } else {
         $outfilename .= "txt";
      }
      my $fulloutfilename = catfile($awrdir,$outfilename);
      open (AWRRUN,">","$awrrunfile") or
         die("\nFailed to open awrrunfile file \n");

      print AWRRUN "define dbid=$dbid\n";
      print AWRRUN "define dbid2=$dbid\n";
      print AWRRUN "define inst_num=$instid\n";
      print AWRRUN "define inst_num2=$instid\n";
      print AWRRUN "define num_days=1\n";
      print AWRRUN "define num_days2=1\n";
      print AWRRUN "define begin_snap=$badfirstsnapid\n";
      print AWRRUN "define end_snap=$badnextsnapid\n";
      print AWRRUN "define begin_snap2=$goodfirstsnapid\n";
      print AWRRUN "define end_snap2=$goodnextsnapid\n";
      print AWRRUN "define report_type=$format\n";
      print AWRRUN "define report_name=$fulloutfilename\n";
      print AWRRUN "@@?/rdbms/admin/awrddrpi\n";
      print AWRRUN "exit\n";
      close(AWRRUN);
      print LOG2 localtime(time) . ": Running Compare $awrrunfile for snaps $badfirstsnapid to $badnextsnapid with $goodfirstsnapid to $goodnextsnapid\n";
      runsqlFile ($ohome,$sid,$user,$awrrunfile);
      print LOG2 localtime(time) . ": Completed Running Compare $awrrunfile for snaps $badfirstsnapid to $badnextsnapid with $goodfirstsnapid to $goodnextsnapid\n";
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
   } # End now run a report for the first and last 
} # end sub

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
