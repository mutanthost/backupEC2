# 
# $Header: tfa/src/v2/ext/dbcsmon/dbcsmon.pm /main/1 2017/05/14 22:10:45 gadiga Exp $
#
# dbcsmon.pm
# 
# Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      dbcsmon.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    gadiga      04/18/17 - DBCS monitor and collector
#    gadiga      04/18/17 - Creation
# 
package dbcsmon;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(deploy
                 autostart
                 start
                 stop
                 restart
                 status
                 runstatus
                 run
                 is_running
                 help
                );

use strict;
use tfactlglobal;
use tfactlshare;

use POSIX qw(:termios_h);

use File::Basename;
use File::Spec::Functions;
use File::Path;
use File::Copy;
use Time::Local;

my $tool = "dbcsmon";
my $tool_name = "dbcsmonitor";
my $mon_script_name = "dbcsmonitor.pl";

my $tfa_base = tfactlshare_get_repository_location($tfa_home);
my $tool_dir = catfile($tfa_base, "suptools", "$hostname", $tool);
# tool_base is directory where run user can write files.
my $tool_base = catfile($tfa_base, "suptools", "$hostname", $tool, $current_user);
my $log = "$tool_base/$tool.alert.log";
my $dbcsmonscript = "/var/opt/oracle/misc/dbcsmonitor.pl";
my $dbcscollectscript = "/var/opt/oracle/misc/dbcscollect.pl";

# deploy function wil be called as part of TFA Install setup.
# Implement any setup/config steps here.
#
sub deploy 
{
  my $tfa_home = shift;
  return 0;
}

# autostart function is called during TFA startup. Mostly we just need to call start function here.
# This function is mainly useful to start the tool only if its enabled. 
# start function will enable and start the tool, whereas autostart only starts if its enabled.
sub autostart 
{
  my $tfa_home = shift;
  return if ( ! is_dbcs_machine() );
  if ( tfactlshare_tool_status($tfa_home, "dbcsmon") eq "notrunning" )
  {
    start($tfa_home);
  }
}

# is_running : return 1 if tool is running.
sub is_running
{
  my $dstatus = `ps -ef | grep $mon_script_name  | grep -v grep > /dev/null; echo \$?`;
  chomp($dstatus);
  if ( $dstatus == 0 )
  {
    return 1;
  }
  return 0;
}

# runstatus : return the run status.. running, notrunning or stopped
#
sub runstatus
{
  my $tfa_home = shift;
  return 10 if ( ! is_dbcs_machine() );
  my $user = get_run_user();

  if ( -f "$tool_base/$tool.stopped" )
  {
    return 2; # stopped
  }

  if ( is_running() )
  {
    return 1; # running
  }
  return 0; # notrunning
}


# Start the monitor script.
sub start 
{
  my $tfa_home = shift;

  if ( $current_user ne "root" )
  {
    print "Error: Only root user can start DBCS Monitor.\n";
    return 2;
  }

  if ( ! is_dbcs_machine() )
  {
    print "Error: This command works only in DBCS host.\n";
    return 2;
  }
  if ( is_running() )
  {
    print "$tool is already running\n";
    return 1;
  }
   else
  {
    my $user = get_run_user();
    tfactlshare_enable_tool($tfa_home, "$tool", $user);
    my $command = "$dbcsmonscript $tfa_home $tool_dir $tool_base &";
    if ( $user ne "root" )
    {
      $command = tfactlshare_checksu($user,"$command");
    }
    tfactlshare_trace(4, "tfactl (PID = $$) $tool_name start: Starting $command", 'y', 'y');
    system($command . "> $log 2>&1");

    if ( is_running() )
    {
      tfactlshare_trace(4, "tfactl (PID = $$) $tool_name start: success", 'y', 'y');
    }
     else
    {
      tfactlshare_trace(1, "tfactl (PID = $$) $tool_name start: failed. Check $log for details.", 'y', 'y');
    }
 }
  return 0;
}

# Stop the monitor script.
sub stop 
{
  my $tfa_home = shift;
  
  if ( $current_user ne "root" )
  {
    print "Error: Only root user can start DBCS Monitor.\n";
    return 2;
  }

  my $user = get_run_user();
  # Check if the script is already stopped. If so just disable it.
  if ( ! is_running() )
  {
    tfactlshare_trace(4, "tfactl (PID = $$) $tool_name stop: $tool_name is not running", 'y', 'y');
    tfactlshare_disable_tool($tfa_home, "$tool", $user);
    return 0;
  }

  my $pid = `ps -ef |grep $mon_script_name |grep -v grep |sed 's/^ *//' | awk '{print \$2}'`;
  chomp($pid);

  if ( $pid )
  {
    tfactlshare_trace(4, "tfactl (PID = $$) $tool_name stop: killing $pid", 'y', 'y');
    system("kill -15 $pid");
  }

  if ( ! is_running() )
  {
    tfactlshare_trace(4, "tfactl (PID = $$) $tool_name stop: Stopped $tool_name", 'y', 'y');
    tfactlshare_disable_tool($tfa_home, "$tool", $user);
  }
  else
  {
    tfactlshare_trace(1, "tfactl (PID = $$) $tool_name stop: Failed to stop $tool_name. Please review $log for details", 'y', 'y');
  }
  return 0;
}

# Restart the monitor script.
sub restart 
{
  my $tfa_home = shift;
  stop($tfa_home);
  start($tfa_home);
  return 1;
}

# Print status of monitor script.
sub status
{
  if ( is_running() )
  {
    print "\n$tool_name is running\n\n";
    return;
  }
  print "\n$tool_name is NOT running\n\n";
}

# Specific function to check if its a DBCS setup.
sub is_dbcs_machine ()
{
  return 1 if ( -f "$dbcscollectscript" );
  return 0;
}

sub get_run_user
{
  my $f = shift;
  my $uid = (stat $dbcsmonscript)[4];
  if ( $f )
  {
    $uid = (stat $f)[4];
  }
  my $user = getpwuid($uid);
  chomp($user);
  $tool_base = catfile($tfa_base, "suptools", "$hostname", $tool, $user);
  $log = "$tool_base/$tool.alert.log";
  if ( ! -d $tool_base )
  {
    mkdir $tool_base;
    system("$CHOWN $user $tool_base");
    system("$CHMOD 740 $tool_base");
    tfactlshare_trace(4, "tfactl (PID = $$) $tool_name get_run_user : Setup $tool_base for $user", 'y', 'n');
  }
  return $user;

}

# Run the DBCS Collector.
sub run
{
  my $tfa_home = shift;
  my @flags = @_;
  
  if ( ! $flags[0] || ! -d $flags[0] )
  {
    help();
    return 2;
  }
  if ( ! is_dbcs_machine() )
  {
    print "Error: This command is only supported in DBCS machine.\n";
    return 2;
  }
  my $outdir1 = $flags[0];
  if ( ! -d "$outdir1" )
  {
    print "Error : $outdir1 does not exists\n";
    return 2;
  }
  my $user = get_run_user ($dbcscollectscript);
  my $outdir = "$outdir1/$user";
  mkdir("$outdir");
  system("$CHOWN $user $outdir");
  system("$CHMOD a+x $outdir1");
  system("$CHMOD 740 $outdir");

  my $command = "$dbcscollectscript $tfa_home $tool_dir $tool_base $outdir";
  if ( $user ne "root" )
  {
    $command = tfactlshare_checksu($user,"$command");
  }

  copy("$log", "$outdir");
  tfactlshare_trace(4, "tfactl (PID = $$) $tool_name run : Running $command", 'y', 'n');
  print "dbcsmon.pm: run the tool: $command\n";
  system("$command");
  system("$MV -f $outdir/* $outdir1");
  return 0;
}

# Help function.
sub help
{
  print "\nUsage : tfactl [run] dbcsmon <output directory>\n\n";
  return 0;
 
}
