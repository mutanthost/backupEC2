# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/runash.pl /main/9 2018/05/28 15:06:28 bburton Exp $
#
# runash.pl
# 
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      runash.pl - <one-line expansion of the name>
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
#    recornej    07/11/17 - Fix Can't return outside a subroutine error
#    manuegar    05/26/17 - manuegar_srdcwin11.
#    bburton     05/25/17 - Not needed for 12.2 as AWR has ASH
#    manuegar    05/09/17 - manuegar_srdcwin06.
#    manuegar    04/21/17 - manuegar_srdcwin_shared.
#    bburton     12/16/16 - remove /tmp
#    bburton     09/22/16 - changes for srdc dbperf
#    manuegar    09/03/16 - Support the -extractto switch in the TFA installer.
#    bburton     06/01/16 - Fix for MTS
#    bburton     01/25/16 - Run an ash report for a given database
#    bburton     01/25/16 - Creation
# 

use warnings;
use strict;
use English;
use Cwd;
use Time::Local;
use File::Copy;
use File::Path;
use File::Find;
use File::Basename;
use File::Spec::Functions;
use Getopt::Long;
use POSIX;


BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME).'/..';
  push @INC, dirname($PROGRAM_NAME).'/../common';
  push @INC, dirname($PROGRAM_NAME).'/../modules';
  push @INC, dirname($PROGRAM_NAME).'/../common/exceptions';
  }

  use tfactlglobal;
  use tfactlshare;


my $ohome;
my $sid;
my $user;
my $text;
my $html;
my $format="text";
my $target_sessionid;
my $target_sql_id;
my $target_wait_class;
my $target_service_hash;
my $target_module_name;
my $target_action_name;
my $target_client_id;
my $target_plsql_entry;
my $begin_time;
my $end_time;
my $duration = "";
my $hostname;
my $newfilename;
my $cwd = $IS_AIX ? $ENV{'PWD'} : getcwd();
my $good;
my $bad;
my $goodorbad;

my $username = tfactlshare::tfactlshare_getUserName();

GetOptions ('ohome=s' => \$ohome,
            'osid=s' => \$sid,
            'ouser=s' => \$user,
            'from=s' => \$begin_time,
            'to=s' => \$end_time,
            'duration=s' => \$duration,
            'html' => \$html,
            'text' => \$text,
            'hostname=s' => \$hostname,
            'good' => \$good,
            'bad' => \$bad,
             );

exit(98) if $ENV{"TFA_ORACLE_VERSION"} =~ /^12.2/;
if ( !$user ) { $user = $username } 
open (LOG2, '>', $hostname . "_ashcollect.log");
open (*STDERR, '>', $hostname . "_ashcollect.err");
open (*STDOUT, '>', $hostname . "_ashcollect.out");
print LOG2 localtime(time) . ": Running ash collection scripts for TFA \n";
print LOG2 "ORACLE_HOME: $ohome\n";
print LOG2 "ORACLE_SID: $sid\n";
print LOG2 "user: $user\n";
if ( $good ) {
   print LOG2 "Collection for Good/BaseLine time\n";
   $goodorbad = "good";
} elsif ( $bad ) {
   print LOG2 "Collection for Slow Performance time\n" if ( $bad );
   $goodorbad = "bad";
} else {
   print LOG2 "Collection : Not known if good or bad\n" if ( $bad );
   $goodorbad = "";
}


# Work out star/end/duration

if ( $begin_time =~ /(\d+)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)/ )
{
    my $t1 = timelocal($6, $5, $4, $3, $2-1, $1);
    $begin_time = strftime '%m/%d/%y %H:%M:%S', localtime $t1;
    if ( $end_time =~ /(\d+)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)/ )
    {
        my $t2 = timelocal($6, $5, $4, $3, $2-1, $1);
        $duration = int(( $t2 - $t1 ) / 60 );
    } 
} else {
    $begin_time = "-240";
    $duration = "240"
}

print LOG2 "from: $begin_time\n";
print LOG2 "duration: $duration\n";

my $ashdir = "ashdir$$";
my $ashrunfile = catfile($ashdir,"ashrunfile$$.sql");
my $userid;
if ( ! $IS_WINDOWS ) { 
  $userid = getpwnam($user);
} else {
  $userid = getlogin();
}

# Set for MTS connection to Database
$ENV{ORA_SERVER_THREAD_ENABLED}="FALSE";

print LOG2 "ashrunfile: $ashrunfile \n";
$format = "html" if ( $html );
$format = "text" if ( $text );
if ( -d $ashdir ) {
print LOG2 "Unable to create user specific ASH outout dir\n";
exit 0;
}
mkdir $ashdir , 0700;
chown $userid, 0 , $ashdir if not $IS_WINDOWS;

print LOG2 "ASH report format: $format\n";

runASHReport( $format );

unlink($ashrunfile);
rmdir($ashdir);

close(LOG2);
close(*STDERR);
close(*STDOUT);

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

sub runASHReport {
   my $format = shift;
     my $outfilename = $goodorbad . "ash_report_sid_$sid";
     my $fulloutfilename = catfile($ashdir,$outfilename . ".lst");
     open (ASHRUN,">","$ashrunfile") or 
           die("\nFailed to open ashrunfile file \n");
     if ( $format eq "html" ) {
           $outfilename .= ".html";
     } else {
	   $outfilename .= ".txt";
     }
    # print "dbid:$dbid\n";
    # print "instid:$instid\n";
     print "report_type:$format\n";
     print "begin_time:$begin_time\n";
     print "duration:$duration\n";
     print "report_name:$fulloutfilename\n";
     print "target_session_id:$target_sessionid\n" if ( $target_sessionid ) ;
     print "target_sql_id:$target_sql_id\n" if ( $target_sql_id ) ;
     print "target_wait_class:$target_wait_class\n" if ( $target_wait_class ) ;
     print "target_service_hash:$target_service_hash\n" if ( $target_service_hash ) ;
     print "target_module_name:$target_module_name\n" if ( $target_module_name ) ;
     print "target_action_name:$target_action_name\n" if ( $target_action_name ) ;
     print "target_client_id:$target_client_id\n" if ( $target_client_id ) ;
     print "target_plsql_entry:$target_plsql_entry\n" if ( $target_plsql_entry ) ;

     print LOG2 localtime(time) . ": Building $ashrunfile for $begin_time for $duration minutes \n";
   
    # print ASHRUN "define dbid=$dbid\n";
    # print ASHRUN "define inst_num=$instid\n";
     print ASHRUN "define report_type=$format\n";
     print ASHRUN "define begin_time=\"$begin_time\"\n";
     print ASHRUN "define duration=$duration\n";
     print ASHRUN "define report_name=$fulloutfilename\n";
     print ASHRUN "define target_session_id=$target_sessionid\n" if ( $target_sessionid ) ;
     print ASHRUN "define target_sql_id=$target_sql_id\n" if ( $target_sql_id ) ;
     print ASHRUN "define target_wait_class=$target_wait_class\n" if ( $target_wait_class ) ;
     print ASHRUN "define target_service_hash=$target_service_hash\n" if ( $target_service_hash ) ;
     print ASHRUN "define target_module_name=$target_module_name\n" if ( $target_module_name ) ;
     print ASHRUN "define target_action_name=$target_action_name\n" if ( $target_action_name ) ;
     print ASHRUN "define target_client_id=$target_client_id\n" if ( $target_client_id ) ;
     print ASHRUN "define target_plsql_entry=$target_plsql_entry\n" if ( $target_plsql_entry ) ;
     print ASHRUN "@@?/rdbms/admin/ashrpt\n";
     print ASHRUN "exit\n";
     close(ASHRUN);
     print LOG2 localtime(time) . ": Running $ashrunfile for $begin_time for $duration minutes \n";
     runsqlFile ($ohome,$sid,$user,$ashrunfile);
     print LOG2 localtime(time) . ": Completed Running $ashrunfile for $begin_time for $duration minutes \n";
     $newfilename = catfile($cwd,$outfilename);
     if ( -e $fulloutfilename ) {
         if ( -l $fulloutfilename ) {
             print LOG2 localtime(time) . ": Not Moving $fulloutfilename as it was replaced by a symbolic Link\n";
             unlink($fulloutfilename);
         } else {
             print LOG2 localtime(time) . ": Moving $fulloutfilename to $newfilename\n";
             move ($fulloutfilename,$newfilename); 
         }
     } else {
         print LOG2 localtime(time) . ": $fulloutfilename did not exist\n";
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
