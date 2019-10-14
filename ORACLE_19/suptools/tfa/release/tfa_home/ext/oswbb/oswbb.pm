# 
# $Header: tfa/src/v2/ext/osw/oswbb.pm /main/18 2018/08/09 22:22:30 recornej Exp $
#
# osw.pm
# 
# Copyright (c) 2014, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      osw.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    07/19/18 - Fix exitcode
#    migmoren    10/13/17 - Bug 26126811 - TFA TOOLSTATUS OUTPUT DISPLAYS
#                           INCORRECT STATUS MESSAGE FOR OSW
#    llakkana    08/22/17 - Displlay proper message for oswbb when osw is not
#                           started by TFA
#    gadiga      06/07/17 - display output dir
#    bburton     06/07/17 - Error on AIX .. The java class is not found:
#                           OSWGraph.OSWGraph when full path to jar file is not
#                           provided.
#    gadiga      06/05/17 - read version from xml
#    llakkana    02/17/17 - Don't stop oswatcher if not started by TFA
#    manuegar    11/02/16 - Bug 24948477 - WS2012_122_TFA: HELP INFORMATION FOR
#                           'TFACTL RUN GREP' INCORRECT.
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    gadiga      10/20/15 - XbranchMerge gadiga_osw_fixes_12126 from
#                           st_tfa_12.1.2.6
#    gadiga      04/15/15 - fix solaris ps issue
#    gadiga      10/20/15 - fix permission issues
#    gadiga      03/24/15 - fix 20666289. dont show help from remote node
#    gadiga      03/03/15 - change version
#    gadiga      01/13/15 - no osw autostart in exadata
#    gadiga      12/12/14 - dont autostart osw if exawatcher is running
#    gadiga      11/03/14 - Creation
# 
package oswbb;
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
use Math::BigInt;
use tfactlglobal;
use tfactlshare;

use List::Util qw[min max];
use POSIX qw(:termios_h);

use File::Basename;
use File::Spec::Functions;
use File::Path;
use Time::Local;

my %months = ( "Jan" => 0, "Feb" => 1, "Mar" => 2, "Apr" => 3, "May" => 4, "Jun" => 5,
            "Jul" => 6, "Aug" => 7, "Sep" => 8, "Oct" => 9, "Nov" => 10, "Dec" => 11);
my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

my $tool = "oswbb";
my $toolversion = "";
my $tfa_base = tfactlshare_get_repository_location($tfa_home);
my $tool_dir = catfile($tfa_base, "suptools", "$hostname", $tool);
my $tool_base = catfile($tfa_base, "suptools", "$hostname", $tool, $current_user);
my $osw_prop = catfile($tool_base, ".osw.prop");

sub deploy 
{
  my $tfa_home = shift;
  print "OSWatcher is already deployed at $tfa_home/ext/oswbb\n";
  return 1;
}

sub autostart 
{
  my $tfa_home = shift;
  if ( is_exaw_running() || is_exadata() )
  { # Dont autostart osw if exawatcher is running
    return 0;
  }
  if ( tfactlshare_tool_status($tfa_home, "oswbb") eq "notrunning" )
  {
    my @users = get_oracle_users($tfa_home);
    if ( $users[0] )
    {
      $ENV{OSW_RUNUSER} = $users[0];
      start($tfa_home);
    }
  }
}

sub is_running
{
  if ( is_osw_running() )
  {
    return 1;
  }
  my $runuser = get_osw_runuser();
  if ( -f "$tool_dir/$runuser/oswbb.stopped" )
  {
    return 3;
  }
  return 0;
}

sub runstatus
{
  my $tfa_home = shift;
  my $runuser = get_osw_runuser();
  if ( -f "$tool_dir/$runuser/oswbb.stopped" )
  {
    return 2;
  }

  if ( is_osw_running() )
  {
    return 1;
  }
  return 0;
}

sub get_osw_prop
{
  my @dirs = `ls -tr $tool_dir/*/.osw.prop 2>/dev/null|tail -1`;
  chomp(@dirs);
  if ( -f $dirs[0] )
  {
    return $dirs[0];
  }
   else
  {
    if ( $ENV{OSW_RUNUSER} )
    {
      $osw_prop = catfile($tool_dir, $ENV{OSW_RUNUSER}, ".osw.prop");
    }
     else
    {
      $osw_prop = catfile($tool_base, ".osw.prop");
    }
  }
}

sub is_osw_running 
{
  my $by = shift;
  my $retval = 0;
  my $oswstatus = `ps -ef | grep OSWatcher  | grep -v grep > /dev/null; echo \$?`;
  chomp($oswstatus);
  if ( $oswstatus == 0 )
  {
    $retval = 1;
  }
  if ( $retval == 1 ) {
    #osw heart beat file always will be under /tmp if osw is running
    #And it contains osw pwd path
    my $osw_hb_file = "/tmp/osw.hb";
    if ( -f $osw_hb_file && -r $osw_hb_file ) {
      $retval = 0;
      open(RF,"$osw_hb_file");
      my $line;
      while(<RF>) {
        $line = $_;
        chomp($line);
        if ( $line =~ /$tool_dir/ ) {
          $retval = 1;
          last;
        }
        else {
          $retval = 0;
        }
      }
      close(RF);
    }
  }
  return $retval;
}

sub is_exadata
{
  if ( -r "/etc/oracle/cell/network-config/cellip.ora" )
  {
    return 1;
  }
  return 0;
}

sub is_exaw_running
{
  my $oswstatus = `ps -ef | grep ExaWatcher  | grep -v grep > /dev/null; echo \$?`;
  chomp($oswstatus);
  if ( $oswstatus == 0 )
  {
    return 1;
  }
  return 0;
}

sub write_to_tmp
{
  my $msg = shift;
  chomp($msg);
  system("echo '$msg' >> /tmp/$$.tfa.log");
}

sub start 
{
  my $tfa_home = shift;
  my $interval = shift;
  my $hours = shift;
  my $zip = shift;
  my $osw_install = "$tfa_home/ext/oswbb";
  my $runuser = $current_user;

  if ( $ENV{OSW_RUNUSER} )
  {
    $runuser = $ENV{OSW_RUNUSER};
  }

  #write_to_tmp("runuser = $runuser\n");
  if ( is_osw_running() )
  {
    print "OSWatcher is already running\n";
    return 1;
  }
   else
  {
    my $adir = catfile($tool_base, "archive");

    if ( $current_user eq "root" )
    {
      $osw_prop = get_osw_prop();
    }

    if ( -f $osw_prop )
    {
      open(ORF, $osw_prop);
      while(<ORF>)
      {
        if ( ! $interval && /interval=(\d+)/ )
        {
          $interval = $1;
        }
         elsif ( ! $hours && /hours=(\d+)/ )
        {
          $hours = $1;
        }
         elsif ( ! $zip && /zip=(.*)/ )
        {
          $zip = $1;
        }
         elsif ( /runuser=(.*)/ )
        {
          $runuser = $1;
        }
      }
      close(ORF);
    }
    #write_to_tmp("2. runuser = $runuser\n");

    $runuser = $current_user if ( $current_user ne "root" );
    #write_to_tmp("3. runuser = $runuser\n");

    if ( $runuser ne "root" )
    {
      $tool_base = catfile($tfa_base, "suptools", "$hostname", $tool, $runuser);
      #write_to_tmp("3. setup dir = $tool_base\n");
      $osw_install = "$tool_base/oswbb";
      $adir = catfile($tool_base, "archive");
    }
    setup_osw_for_user($runuser);
    tfactlshare_enable_tool($tfa_home, "oswbb", $runuser);

    # Defaults
    $interval = 30 if ( ! $interval );
    $hours = 48 if ( ! $hours );
    $zip = "NONE" if ( ! $zip );

    print "Starting OSWatcher\n";
    mkdir $adir if ( ! -d $adir );
    my $log = "$tool_base/run_".time().".log";
    #write_to_tmp("log dir = $log\n");
    if ( $current_user eq "root" and $runuser ne $current_user )
    {
      system("touch $log; chown $runuser $log");
      #write_to_tmp("start as $runuser \n");
      system("cd $osw_install;su $runuser -c './startOSWbb.sh $interval $hours $zip $adir' > $log 2>&1");
    }
     else
    {
      #write_to_tmp("start as me \n");
      system("cd $osw_install;./startOSWbb.sh $interval $hours $zip $adir > $log 2>&1");
    }
    if ( ! is_osw_running() )
    {
      print "ERROR: Failed to start OSWatcher. Please review $log for details\n\n";
    }
     else
    {
      open(OWF, ">$osw_prop");
      print OWF "interval=$interval\n";
      print OWF "hours=$hours\n";
      print OWF "zip=$zip\n";
      print OWF "runuser=$runuser\n";
      close(OWF);
      system("chmod 744 $osw_prop 2>/dev/null");
      if ( $current_user eq "root" )
      {
        system("chown $runuser $osw_prop 2>/dev/null");
      }
    }
  }
  return 0;
}

sub get_osw_version_in_ext
{
  my $tfa_home = shift;
  my $tfaextxml = catfile($tfa_home, "ext", "tfaext.xml");
  my $extver = "";

  if (  -r $tfaextxml )
  { 
    open(TEF, $tfaextxml);
    while(<TEF>)
    {
      chomp;
      if ( /tool\s+name=\Woswbb\W\s+.*buildid=\W(\d+)\W/ )
      {
        $extver = $1;
      }
    }
    close(TEF);
  }
  return $extver;
}

sub get_oracle_users
{
  my $tfa_home = shift;
  my $guser = "";
  my $home = get_crs_home($tfa_home);
  if ( $home )
  { # Check for a oracle_home
    my $ofile = catfile($crs_home, "bin", "oracle");
    my $guser = getpwuid((stat($ofile))[4]);
    return ($guser);
  }
   else
  {
    my @users = `ps -ef |grep pmon |grep -v grep |cut -d" " -f1 |sort -u`;
    chomp(@users);
    return @users;
  }
}

sub setup_osw_for_user
{
  my $usern = shift;
  my $tool_base = catfile($tool_dir, $usern);

  my $needs_setup = 1;

  my $tool_v_file = "$tool_base/.tv.dmp";
  
  $toolversion = get_osw_version_in_ext($tfa_home);
  #write_to_tmp("In setup\n");
  if ( -r $tool_v_file )
  { # Setup already for user
    my $ctv = `cat $tool_v_file`;
    chomp($ctv);
    if ( $ctv eq $toolversion )
    { # Same version
      $needs_setup = 0;
    }
  }
  #write_to_tmp("In setup needs_setup = $needs_setup\n");
  $needs_setup = 1 if ( ! -d "$tool_base/oswbb" );
  #write_to_tmp("In setup needs_setup = $needs_setup\n");

  return if ( $needs_setup == 0 );

  if ( ! -d $tool_base )
  {
    #write_to_tmp("create $tool_base\n");
    system("mkdir $tool_base; chmod 740 $tool_base; chown $usern $tool_base");
  }
  #write_to_tmp("setup $tfa_home/ext/oswbb in $tool_base\n");
  if ( $current_user eq "root" )
  {
    #write_to_tmp("setup $tfa_home/ext/oswbb in $tool_base as au $usern\n");
    system("mkdir $tool_base/oswbb.$$");
    system("cp -f -R $tfa_home/ext/oswbb $tool_base/oswbb.$$");
    system("chmod -R 755 $tool_base/oswbb.$$");
    system("su $usern -c 'cp -f -R $tool_base/oswbb.$$/oswbb $tool_base'");
    system("su $usern -c 'mkdir $tool_base/archive'");
    system("rm -rf $tool_base/oswbb.$$");
  }
   else
  {
    #write_to_tmp("setup $tfa_home/ext/oswbb in $tool_base as me\n");
    system("cp -f -R $tfa_home/ext/oswbb $tool_base");
    system("mkdir $tool_base/archive");
  }
  add_new_directory ($tfa_home, "$tool_base/archive", "OS");
  system("echo $toolversion > $tool_v_file");
  if ( $current_user eq "root" )
  {
    system("chown $usern  $tool_v_file");
  }
}

sub stop 
{
  my $tfa_home = shift;
  my $osw_install = "$tfa_home/ext/oswbb";
  if ( is_osw_running() )
  {
    my $runuser = get_osw_runuser();
    if ( $runuser ne "root" )
    {
      $tool_base = catfile($tfa_base, "suptools", "$hostname", $tool, $runuser);
      $osw_install = "$tool_base/oswbb";
    }

    if ( $current_user ne "root" && $current_user ne $runuser )
    {
      print "Error: OSWatcher can not be stopped by $current_user\n";
      return 1;
    }

    my $log = catfile($tool_base, "run_stop_".time().".log");
    if ( $runuser eq $current_user )
    {
      system("cd $osw_install;./stopOSWbb.sh >$log 2>&1");
    }
    if ( $current_user eq "root" && $runuser ne "root" )
    {
      system("cd $osw_install;su $runuser -c ./stopOSWbb.sh >$log 2>&1");
    }
    if ( ! is_osw_running() )
    {
      print "Stopped OSWatcher\n";
      tfactlshare_disable_tool($tfa_home, "oswbb", $runuser);
    }
     else
    {
      print "ERROR: Failed to stop OSWatcher. Please review $log for details\n\n";
    }
    return 1;
  }
   else
  {
    print "OSWatcher is not running by TFA\n";
  }
  return 0;

}

sub restart 
{
  my $tfa_home = shift;
  stop($tfa_home);
  start($tfa_home);
  return 1;
}

sub status
{
  if ( is_osw_running() )
  {
    print "\nOSWatcher is running\n\n";
    return;
  }
  print "\nOSWatcher is NOT running\n\n";
}

sub formatnum
{
  my $n = shift;
  return sprintf "%02d", $n;
}

sub get_osw_runuser
{
  my $runuser;
  my $ps_output;
  # Code Modified to work on Solaris - Modifications by Bryan Vongray - Oracle GCS
  $ps_output = `ps -ef | grep OSWatcher  | grep -v grep | head -1`;
  $ps_output =~ s/^\s+//;
  $runuser = (split / +/, $ps_output)[0];
  #$runuser = `ps -ef | grep OSWatcher  | grep -v grep |cut -d" " -f1 |head -1`;
  chomp($runuser);
  return $runuser if ( $runuser );

  if ( $current_user eq "root" )
  {
    $osw_prop = get_osw_prop();
  }
  if ( -f $osw_prop )
  {
    open(ORF, $osw_prop);
    while(<ORF>)
    {
      if ( /runuser=(.*)/ )
      {
        $runuser = $1;
        return $runuser;
      }
    }
    close(ORF);
  }

}

sub run
{
  my $tfa_home = shift;
  my @flags = @_;
  my $command = "analyze";
  
  if ( $flags[0] eq "-h" || $flags[0] eq "-help" )
  {
    help();
    return 0;
  }

  my $java_home = get_java_home($tfa_home);
  $ENV{JAVA_HOME} = $java_home;
  # Modified by Bryan Vongray to cover cases where OS Java does not meet the java version requirement
  my $cur_path = $ENV{PATH};
  my $java = catfile($java_home, "bin", "java");
  $ENV{PATH} = "$java_home/bin:$cur_path\n";

  my %opts = ();

  my $splice = 0;
  if ( $flags[0] eq "getstat" )
  {
    $command = "getstat";
    $splice = 1;
  }
   elsif ( $flags[0] eq "analyze" )
  {
    $splice = 1;
  }
  if ( $splice == 1 )
  {
    splice @flags, 0, 1;
  }

  if ( $command eq "analyze" )
  {
    my $stime = "";
    if ( $flags[0] =~ /\d+[dhm]/ )
    {
      $stime = $flags[0];
    }
     elsif ( $flags[0] eq "-since" && $flags[1] =~ /\d+[dhm]/ )
    {
      $stime = $flags[1];
    }

    if ( $stime )
    {
      my $secs_since = 0;
      if ( $stime =~ /(\d+)(\w)/ )
      {
        if ( $2 eq "m" )
        { # Mins
          $secs_since = $1 * 60;
        }
         elsif ( $2 eq "h" )
        { # Hours
          $secs_since = $1 * 60 * 60;
        }
         elsif ( $2 eq "d" )
        { # Mins
          $secs_since = $1 * 60 * 60 * 24;
        }
      }
      my $ctime = time();
      my $otime = $ctime - $secs_since;
      my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($ctime);
      $year += 1900;
      my $etime = "$months[$mon] ".formatnum($mday)." ".formatnum($hour).":".formatnum($min).":".formatnum($sec)." $year";
      my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($otime);
      $year += 1900;
      my $btime = "$months[$mon] ".formatnum($mday)." ".formatnum($hour).":".formatnum($min).":".formatnum($sec)." $year";
      my $afile = "$tool_base/analysis_${ctime}_$otime.txt";
      $opts{"afile"} = $afile;
      @flags = ("analyze", "-B", "$btime", "-E", "$etime", "-A", "$afile");
    }
  }

  #print "Running analyze with @flags\n";
  chdir("$tool_base");
  if ( $command eq "analyze" )
  {
    my $runuser = get_osw_runuser();
    if ( ! $runuser )
    {
      print "Error finding run user. OSWatcher is not running from TFA.\n";
      return 1;
    }

    $tool_base = catfile($tfa_base, "suptools", "$hostname", $tool, $runuser);
    my $osw_install = "$tool_base/oswbb";
    chdir($osw_install);
  
    my $adir = catfile($tfa_base, "suptools", "$hostname", $tool, $runuser, "archive");

    if ( ! -d "$adir" )
    {
      print "Error: OSWatcher files not found under $adir for analysis\n";
      if (!is_osw_running()) {
        print "OSWatcher is not started by TFA. To analyze osw files from TFA stop that instance first and then start from TFA\n";   
      }
      return 1;
    }

    setup_osw_for_user($current_user);
    $tool_base = catfile($tfa_base, "suptools", "$hostname", $tool, $current_user);
    my $osw_install = catfile($tool_base,"oswbb");
    my $oswjar = catfile($osw_install,"oswbba.jar");
    chdir($osw_install);

    if ( ! -f "oswbba.jar" )
    {
      print "Error: Could not locate oswbba.jar in $osw_install\n";
      return 1;
    }

    system("$java -Xmx512M -jar $oswjar -i $adir @flags");
    if ( $opts{"afile"} && -f $opts{"afile"} )
    {
      system("more", $opts{"afile"});
      print "\n\nAnalysis results are also saved in ". $opts{"afile"} ." \n\n";
    }
     else
    {
      print "\n\nAnalysis results are saved in ". catfile($tool_base, "oswbb") ." \n\n";
    }
  }
   #elsif ( $command eq "getstat" )
  #{ # getstat <time> -> show the values from give time
    # Find file which has contents for given time
    # Uncompress if required
    # Read contents and display
  #}
  return 0;
}

sub help
{
  print "\nUsage : $0 [run] oswbb [<OSWatcher Analyzer Options> | -since n[mhd] ]\n\n";
  print "Options: \n\n";
  print "-since n[mhd] Run OSWatcher analyzer for last n [m]inutes or [h]ours or [d]ays.\n\n";
  print "<OSWatcher Analyzer Options>: -P <name> -L <name> -6 -7 -8 -B <time> -E <time> -A \n";
  print <<"EOF";
     -P <profile name>  User specified name of the html profile generated
                        by oswbba. This overrides the oswbba automatic naming
                        convention for html profiles. All profiles
                        whether user specified named or auto generated
                        named will be located in the /profile directory.

     -A <analysis name> Same as option A from the menu. Will generate
                        an analysis report in the /analysis directory or
                        user can also specify the name of the analysis file
                        by specifying full qualified path name of file.
                        The "A" option can not be used together with the
                        "S" option.
     -S <>              Will generate an analysis of a subset of the data
                        in the archive directory. This option must be used
                        together with the -b and -e options below. See the
                        section "Specifying the begin/end time of the analysis"
                        above. The "S" option can not be used together with
                        the "A" option.

     -START <filename>  Used with the analysis option to specify the first
                        file located in the oswvmstat directory to analyze.

     -STOP <filename>   Used with the analysis option to specify the last
                        file located in the oswvmstat directory to analyze.

     -b <begin time>    Used with the -S option to specify the begin time
                        of the analysis period. Example format:
                        -b Jan 09 13:00:00 2013

     -e <end time>      Used with the -S option to specify the end time
                        of the analysis period. Example format:
                        -e Jan 09 13:15:00 2013

     -L <location name> User specified location of an existing directory
                        to place any gif files generated
                        by oswbba. This overrides the oswbba automatic
                        convention for placing all gif files in the
                        /gif directory. This directory must pre-exist!
     -6                 Same as option 6 from the menu. Will generate
                        all cpu gif files.


     -7                 Same as option 7 from the menu. Will generate
                        all memory gif files.

     -8                 Same as option 8 from the menu. Will generate
                        all disk gif files.



     -NO_IOSTAT         Ignores files in the oswiostat directory from
                        analysis

     -NO_TOP            Ignores files in the oswtop directory from
                        analysis

     -NO_NETSTAT        Ignores files in the oswnetstat directory from
                        analysis

     -NO_PS             Ignores files in the oswps directory from
                        analysis

     -MEM_ALL           Analyzes virtual and resident memory allocations
                        for all processes. This is very resource intensive.

     -NO_Linux          Ignores files in the oswmeminfo directory from
                        analysis
EOF
  print "\ne.g:\n";
  print "   $0 oswbb\n";
  print "   $0 oswbb -since 2h\n\n";
  print "   $0 run oswbb\n";
  print "   $0 run oswbb -since 2h\n\n";
  return 0;
 
}
