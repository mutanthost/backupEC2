# 
# $Header: tfa/src/v2/ext/cnsmon/cnsmon.pm /main/1 2018/08/30 04:13:08 llakkana Exp $
#
# cnsmon.pm
# 
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      cnsmon.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      cnsmon plugin/tool is owned by CNS team and they wanted to use TFA's 
#      lucene index and notification framwork for monitoring and alerting 
#      pdb,cdb events. This plugin will be run by TFAPluginMonitor periodically,
#      index the changes,events into index. This plugin runs on Master node.
#
#    NOTES
#      It should be run only for cloud. 
#
#    MODIFIED   (MM/DD/YY)
#    llakkana    07/30/18 - CNS monitor pluign to monitor pdb/cdb status etc
#    llakkana    07/30/18 - Creation
#
package cnsmon;
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

my $tool = "cnsmon";
my $tool_name = "cnsmonitor";
my $mon_script_name = "cnsmon.pl";

my $tfa_base = tfactlshare_get_repository_location($tfa_home);
my $tool_dir = catfile($tfa_base, "suptools", "$hostname", $tool);
# tool_base is directory where run user can write files.
my $tool_base = catfile($tfa_base, "suptools", "$hostname", $tool, $current_user);
my $log = "$tool_base/$tool.alert.log";
my $cnsmonscript = "/var/opt/oracle/cns/bin/cnsmon.pl";

# deploy function will be called as part of TFA Install setup.
# Implement any setup/config steps here.
sub deploy 
{
  my $tfa_home = shift;
  return 0;
}

# autostart function is called during TFA startup. 
# Mostly we just need to call start function here.
# This function is mainly useful to start the tool only if its enabled. 
# start function will enable and start the tool, whereas autostart 
# only starts if its enabled.
sub autostart 
{
  my $tfa_home = shift;
  return if ( ! is_cns_supported_env() );
  if ( tfactlshare_tool_status($tfa_home, "cnsmon") eq "notrunning" )
  {
    start($tfa_home);
  }
}

# is_running : return 1 if tool is running.
sub is_running
{
  my $status = `ps -ef | grep $mon_script_name  | grep -v grep > /dev/null; echo \$?`;
  chomp($status);
  if ( $status == 0 )
  {
    return 1;
  }
  return 0;
}

# runstatus : return the run status.. running, notrunning or stopped
sub runstatus
{
  my $tfa_home = shift;
  return 10 if ( ! is_cns_supported_env() );
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
  print "Nothing to do !\n";
  return 0;
}

# Stop the monitor script.
sub stop 
{
  my $tfa_home = shift;
  
  if ( $current_user ne "root" )
  {
    print "Error: Only root user can stop CNS Monitor.\n";
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
sub is_cns_supported_env()
{
  return 1 if (-f "$cnsmonscript");
  return 0;
}

sub get_run_user
{
  my $f = shift;
  my $uid = (stat $cnsmonscript)[4];
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

# Run the CNS
sub run
{
  my $tfa_home = shift;
  my @flags = @_; #Frequency etc
  
  if ( ! is_cns_supported_env() )
  {
    print "Error: Command is not supported for this env\n";
    return 2;
  }
  my $user = get_run_user ($cnsmonscript);

  my $command = "$cnsmonscript $tfa_home @flags";
  if ( $user ne "root" )
  {
    $command = tfactlshare_checksu($user,"$command");
  }

  tfactlshare_trace(4, "tfactl (PID = $$) $tool_name run : Running $command", 'y', 'n');
  print "cnsmon.pm: run the tool: $command\n";
  system("$command");
  return 0;
}

# Help function.
sub help
{
  print "\nUsage : tfactl [run] cnsmon\n\n";
  return 0;
 
}
