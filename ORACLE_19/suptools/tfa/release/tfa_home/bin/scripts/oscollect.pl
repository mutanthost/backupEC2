# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/oscollect.pl /main/16 2018/05/28 15:06:27 bburton Exp $
#
# oscollect.pl
# 
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      oscollect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    04/26/18 - Adding sudo to ib commands
#    recornej    04/20/18 - Adding sudo when running as non root.
#    bburton     05/08/17 - evt logs on windows not collecting events
#    bburton     04/25/17 - Fix issue with sort options
#    bburton     04/07/17 - Add Top Memory processes
#    bburton     11/20/16 - more file checks
#    llakkana    10/26/16 - Add OS collections needed for analyzing issues like
#                           startup etc
#    manuegar    07/08/16 - Bug 23741237 - TFA: REMOTE NODE DIAGCOLLECTION
#                           FAILING WITH IO EXCEPTION.
#    llakkana    07/04/16 - 23737587 - pckginfo issue
#    arupadhy    06/27/16 - Added code to use win_user_groups.txt for obtaining
#                           windows user group details when queried through
#                           java process
#    bburton     06/20/16 - Add AIX Commands.
#    arupadhy    06/13/16 - Added support for windows os files collection
#    bburton     05/09/16 - OS Data Collections
#    bburton     05/09/16 - Creation
# 
#
use strict;
use English;
use File::Basename;
use File::Spec::Functions;
use File::Copy;
use Time::Local;
use Term::ANSIColor;
use Cwd;
use POSIX;

use Getopt::Long qw(:config no_auto_abbrev);

BEGIN {
  # Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME).'/..';
  push @INC, dirname($PROGRAM_NAME).'/../common';
  push @INC, dirname($PROGRAM_NAME).'/../modules';
  push @INC, dirname($PROGRAM_NAME).'/../common/exceptions';
}

use tfactlglobal;
use tfactlshare;
use tfactlwin;
use collection;
use cmdlocation;

# Set up local variables
my $PLATFORM = $^O;
my $hostname;
my $tfahome;
my $command;
my $crsbindir;

# Parse command line args
GetOptions('hostname=s'    => \$hostname);

if(@ARGV) {
   print "\nInvalid Options specified: @ARGV\n";
   exit(1);
}

# setup Variables for Commands..

my $IPCS; my $DMESG; my $MOUNT; my $SWAPON; my $RAW; my $SAR; my $SERVICE; my $SYSTEMCTL; my $SYSCTL;
my $CHKCONFIG; my $GETENFORCE; my $SESTATUS; my $PSTREE; my $UPTIME; my $IP; my $PRTCONF; my $PSRINFO; 
my $NUMACTL;  my $LSMOD; my $RPM; my $SWAP; my $ERRPT; my $PKGINFO; my $PROJECTS; my $SYSDEF; my $SHOWMOUNT;
my $EXPORTFS; my $LSATTR; my $SCHEDO; my $VMO; my $LSLPP; my $INSTFIX; my $PSTAT; my $LSDEV; my $VGDISPLAY; my $LVDISPLAY; 
my $KCTUNE; my $SWAPINFO; my $MPSCHED; my $IOSCAN; my $SWLIST; my $SORT; my $HEAD;
my $FREE; my $LSPS; my $SVMON; my $SWAP; my $SWAPINFO; my $TOP;
my $NET; my $IPCONFIG; my $NETSH; my $WMIC; my $TASKLIST; my $SC; my $SYSTEMINFO; my $DISKPART; my $WEVTUTIL; my $VER;
my $SUDO ="";
my $outfile;
my $tmpfile;

if($IS_WINDOWS){
  $NET = cmdlocation_get("net.exe");
  $IPCONFIG = cmdlocation_get("ipconfig.exe");
  $NETSH = cmdlocation_get("netsh.exe");
  $WMIC = cmdlocation_get("wmic.exe");
  $TASKLIST = cmdlocation_get("tasklist.exe");
  $SC = cmdlocation_get("sc.exe");
  $SYSTEMINFO = cmdlocation_get("systeminfo.exe");
  $DISKPART = cmdlocation_get("diskpart.exe");
  $WEVTUTIL = cmdlocation_get("wevtutil.exe");
  $VER = cmdlocation_get("ver.exe");
}else{
  $IPCS = cmdlocation_get("ipcs");
  $DMESG = cmdlocation_get("dmesg");
  $MOUNT = cmdlocation_get("mount");
  $SWAPON = cmdlocation_get("swapon");
  $RAW = cmdlocation_get("raw");
  $SAR = cmdlocation_get("sar");
  $SERVICE = cmdlocation_get("service");
  $SYSTEMCTL = cmdlocation_get("systemctl");
  $SYSCTL = cmdlocation_get("sysctl");
  $CHKCONFIG = cmdlocation_get("chkconfig");
  $GETENFORCE = cmdlocation_get("getenforce");
  $SESTATUS = cmdlocation_get("sestatus");
  $PSTREE = cmdlocation_get("pstree");
  $UPTIME = cmdlocation_get("uptime");
  $IP = cmdlocation_get("ip");
  $PRTCONF = cmdlocation_get("prtconf");
  $PSRINFO = cmdlocation_get("psrinfo");
  $NUMACTL = cmdlocation_get("numactl");
  $LSMOD = cmdlocation_get("lsmod");
  $RPM = cmdlocation_get("rpm");
  $SWAP = cmdlocation_get("swap");
  $ERRPT = cmdlocation_get("errpt");
  $PKGINFO = cmdlocation_get("pkginfo");
  $PROJECTS = cmdlocation_get("projects");
  $SYSDEF = cmdlocation_get("sysdef");
  $SHOWMOUNT = cmdlocation_get("showmount");
  $EXPORTFS = cmdlocation_get("exportfs");
  $LSATTR = cmdlocation_get("lsattr");
  $SCHEDO = cmdlocation_get("schedo");
  $VMO = cmdlocation_get("vmo");
  $LSLPP = cmdlocation_get("lslpp");
  $INSTFIX = cmdlocation_get("instfix");
  $PSTAT = cmdlocation_get("pstat");
  $LSDEV = cmdlocation_get("lsdev");
  $VGDISPLAY = cmdlocation_get("vgdisplay");
  $LVDISPLAY = cmdlocation_get("lvdisplay");
  $KCTUNE = cmdlocation_get("kctune");
  $SWAPINFO = cmdlocation_get("swapinfo");
  $MPSCHED = cmdlocation_get("mpsched");
  $IOSCAN = cmdlocation_get("ioscan");
  $SWLIST = cmdlocation_get("swlist");
  $SORT = cmdlocation_get("sort");
  $HEAD = cmdlocation_get("head");
  $FREE = cmdlocation_get("free");
  $TOP  = cmdlocation_get("top");
  $SVMON = cmdlocation_get("svmon");
  $LSPS = cmdlocation_get("lsps");
  $SWAP = cmdlocation_get("swap");
  $SWAPINFO = cmdlocation_get("swapinfo");
  $SUDO = cmdlocation_get("sudo") if ( $current_user ne "root");
  $SUDO .= " -n" if ( $SUDO ne "" );
}

{
local *STDOUT;
local *STDERR;

#Open a log file for this collection script to write to
open (STDOUT, '>', $hostname . "_os_collection.log");
open (STDERR, '>', $hostname . "_os_collection.err");
open (REP, '>', $hostname . "_os_report");
print localtime(time) . ": Running OS collection scripts for TFA \n";
print "Hostname: $hostname\n";

# Collect O/S data and general config files..
print REP "\nOperating System and Configuration Report\n";
print REP "=========================================\n\n";

if ( !$IS_WINDOWS ) {
   my $host = `$HOSTNAME`;
   chomp($host);
   my $domain = `$DOMAINNAME`;
   chomp($domain);
   print REP "Hostname :  $host\.$domain\n\n";
   $command = "$UNAME -a";
   print REP "uname -a : ";
   runtimedcommand($command);
   print REP "\n";

   print "\n".localtime(time) . ": Collecting socket directory listing\n";

   my $socketdir = catfile ("/var","tmp",".oracle");
   if ( -d $socketdir ) {
      $command = "ls -al $socketdir > $hostname"."_VARTMPORACLE";
      runtimedcommand($command);
   }

}else{
  my $domain = `echo \%USERDOMAIN\%`;
  chomp($domain);
  print REP "Hostname :  $domain\\$hostname\n\n";
  $command = "$VER";
  print REP "VER : ";
  runtimedcommand($command);
  print REP "\n";
}


# Top 50 memory consumers .
my $outfiletmp = $hostname . "_TOP_50_MEMORY_tmp";
my $outfile = $hostname . "_TOP_50_MEMORY";
my $command;
if ( $PLATFORM eq "linux" ) {
   $command = "$PS aux | $SORT -k6,7 -n -r -o$outfiletmp";
}
elsif ( $PLATFORM eq "solaris" ) {
  $command = "$PS -eo user,pid,ppid,vsz,rss,time,comm | $SORT -k5,6 -n -r -o$outfiletmp";
}
elsif ( $PLATFORM eq "aix" ) {
  $command = "$PS aux | $SORT -k6,7 -n -r -o$outfiletmp";
}
elsif ( $PLATFORM eq "hpux" ) {
  $command = "$PS -elf | $SORT -k10,11 -n -r -o$outfiletmp";
}
elsif ( $PLATFORM eq "MSWin32" ) {
  $command = "";
}
if ( length $command ) {
  runtimedcommand($command);
  $command = "$HEAD -50 $outfiletmp > $outfile";
  runtimedcommand($command);
  unlink($outfiletmp);
}

# End of Getting generic O/S info
# Collect the loc files ..
getlocfiles();


if ( $PLATFORM eq "linux" ) {
 collect_systeminfo_l();
}
elsif ( $PLATFORM eq "solaris" ) {
 collect_systeminfo_s();
}
elsif ( $PLATFORM eq "aix" ) {
 collect_systeminfo_a();
}
elsif ( $PLATFORM eq "hpux" ) {
 collect_systeminfo_h();
}
elsif ( $PLATFORM eq "MSWin32" ) {
 collect_systeminfo_w();
}

if ( not $IS_WINDOWS ) {
  $outfile = "$hostname"."_RUNLEVEL"; 
  collection_run_level("system",$outfile);
  
  my $filter_str = "ohasd\\|tfa\\|crsd\\|cssd\\|evmd";
  $outfile = "$hostname"."_INITTAB";
  collection_cat_file(catfile("","etc","inittab"),$outfile,$filter_str);
  
  $outfile = "$hostname"."_NSSWITCH_CONF";
  collection_copy(catfile("","etc","nsswitch.conf"),$outfile);
  
  $outfile = "$hostname"."_NETSTAT";
  collection_netstat($outfile);
}

#Exadata specific collection
if ( isExadata() ) {
  $tmpfile = catfile("","etc","oracle","cell","network-config","cellinit.ora");
  collectFile($tmpfile,"cellinit.ora"); 
  $tmpfile = catfile("","etc","oracle","cell","network-config","cellip.ora");
  collectFile($tmpfile,"cellip.ora"); 
  $tmpfile = catfile("","etc","oracle","cell","network-config","cellkey.ora");
  collectFile($tmpfile,"cellkey.ora");
  $tmpfile = catfile("","etc","oracle","cell","network-config","cellroute.ora");
  collectFile($tmpfile,"cellroute.ora");
  $tmpfile = catfile("","etc","oracle","cell","network-config","cellaffinity.ora");
  collectFile($tmpfile,"cellaffinity.ora");

  #Get ibswitches info
  $outfile = "$hostname"."_IBFILE";
  collection_ib_cmd("ibstat",$outfile);
  collection_ib_cmd("ibstatus",$outfile);
  collection_ib_cmd("ibnetdiscover",$outfile,$SUDO);
  collection_ib_cmd("ibqueryerrors",$outfile,$SUDO);
  collection_ib_cmd("ibswitches",$outfile,$SUDO);
  collection_ib_cmd("iblinkinfo",$outfile,$SUDO);
  collection_ib_cmd("ibcheckerrors",$outfile);
  collection_ib_cmd("ibcheckstate",$outfile);
  collection_rds_info("-I",$outfile);
}

#files to collect and print to report. 
if(!$IS_WINDOWS){
  my @filesarray;
  push (@filesarray,"/etc/group");
  push (@filesarray,"/etc/resolv.conf");
  push (@filesarray,"/etc/ntp.conf");
  push (@filesarray,"/etc/filesystems");
  getfilesfromarray(\@filesarray);
}

close LOG2;
close STDOUT;
close STDERR;
}

# End of the MAIN Section

sub collectFile
{
  my $file = shift;
  my $sfn = shift;
  my $outfile = "$hostname"."_"."$sfn";
  if ( -f $file && ! -l $file ) {
    collection_copy($file, $outfile);
  }
}

#######################
## Name
##  getfilesfromarray
## DESCRIPTION
##  Loop through an array of file names and if they exist Print to the report.
## PARAMETERS
##  None
## RETURNS
##  None
#######################
sub getfilesfromarray
{
   my $array_ref = shift;
   my $filestring;
   my $openok;
   my @filearray = @{$array_ref};
   print REP "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n";
   foreach $filestring ( @filearray ) {
      if ( -e $filestring && ! -l $filestring && -f $filestring ) {
         print REP "\n#### Contents of $filestring ####\n";
          $openok = open (RF, "$filestring");
          if ($openok) {
            print localtime(time) . ": Opened file $filestring for read\n";
            while(<RF>) {
              chomp();
              print REP "$_\n";
            }
            close(RF);
          }
          else {
            print localtime(time) . ": Failed to open file $filestring for read\n";
          }
      } else {
        print REP "$filestring not present or invalid on this system\n";
      }
      print REP "\n";
      print REP "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n";
   }
}

#######################
# Name
#  getlocfiles
# DESCRIPTION
#  get files such as ocr.loc, olr.loc, oratab, oraInst.loc
# PARAMETERS
#  None
# RETURNS
#  None
###########

sub getlocfiles 
{
  print "\n".localtime(time) . ": Collecting oratab, ocr.loc, olr.loc etc \n";
  if ($PLATFORM eq "linux" ) {
     my $filename = catfile("/etc","oratab");
     my $fileout = "$hostname"."_oratab";
     if ( -e $filename && ! -l $filename && -f $filename) {
        copy ($filename,$fileout) ;
     }

     my $filename = catfile("/etc","orainst.loc");
     my $fileout = "$hostname"."_orainstloc";
     if ( -e $filename && ! -l $filename && -f $filename) {
        copy ($filename,$fileout) ;
     }
     
     my $filename = catfile("/etc","oracle","ocr.loc");
     my $fileout = "$hostname"."_ocrloc";
     if ( -e $filename && ! -l $filename && -f $filename) {
        copy ($filename,$fileout) ;
     }

     my $filename = catfile("/etc","oracle","olr.loc");
     my $fileout = "$hostname"."_olrloc";
     if ( -e $filename && ! -l $filename && -f $filename) {
        copy ($filename,$fileout) ;
     }

     my $filename = catfile("/etc","oracle-release");
     my $fileout = "$hostname"."_oracle-release";
     if ( -e $filename && ! -l $filename && -f $filename) {
        copy ($filename,$fileout) ;
     }

     my $filename = catfile("/etc","redhat-release");
     my $fileout = "$hostname"."_redhat-release";
     if ( -e $filename && ! -l $filename && -f $filename) {
        copy ($filename,$fileout) ;
     }
  } else {
     if ( not $IS_WINDOWS ) {
       my $filename = catfile("/var","opt","oracle","oratab");
       my $fileout = "$hostname"."_oratab";
       if ( -e $filename && ! -l $filename && -f $filename) {
          copy ($filename,$fileout) ;
       }
       my $filename = catfile("/var","opt","oracle","orainst.loc");
       my $fileout = "$hostname"."_orainstloc";
       if ( -e $filename && ! -l $filename && -f $filename) {
          copy ($filename,$fileout) ;
       }
       my $filename = catfile("/var","opt","oracle","ocr.loc");
       my $fileout = "$hostname"."_ocrloc";
       if ( -e $filename && ! -l $filename && -f $filename) {
          copy ($filename,$fileout) ;
       }
  
       my $filename = catfile("/var","opt","oracle","olr.loc");
       my $fileout = "$hostname"."_olrloc";
       if ( -e $filename && ! -l $filename && -f $filename) {
          copy ($filename,$fileout) ;
       }
       my $filename = catfile("/var","opt","oracle","olr.loc");
       my $fileout = "$hostname"."_olrloc";
       if ( -e $filename && ! -l $filename && -f $filename) {
          copy ($filename,$fileout) ;
       }
     }
  }
} # End sub getlocfiles

########
# NAME
#  collect_systeminfo_l
#
# DESCRIPTION
#  collect data from info files under /proc dir in linux env
#
# PARAMETERS
#  None
# RETURNS
#  None
###########
#
sub collect_systeminfo_l
{
  my $infofile;
  my $dirfile;
  my $date = `date`;
  chomp($date);
  
  # get lsmod output 
  $command = $LSMOD;
  if ( -e $command ) {
    $command = $command . " > $hostname"."_LSMOD";
    runtimedcommand($command);
  }
  
  $command = $RPM;
  if ( -e $command ) {
    $command = $command . " -qa > $hostname"."_RPMQA";
    runtimedcommand($command);
  }
  #   Reading *info* and modules from /proc
  my $outfile = $hostname . "_PROCDIRINFO";
  my $procdir="/proc";
  my $openok =  opendir(my $dir, $procdir);
  if ( -d $procdir ) {
    if ( $openok ) {
      my @files = readdir $dir;
      closedir $dir;

      open(WF, ">$outfile");
      print WF "### Contents of /proc/*info* at $date ###\n";

      foreach $dirfile (@files) {
        if ($dirfile =~ /info/ || $dirfile eq "modules" || $dirfile eq "locks" || $dirfile eq "version" || $dirfile eq "mounts") {
          $infofile = catfile($procdir,$dirfile);
          print localtime(time) . ": Collecting $infofile into $outfile\n";

          print WF "\n####### $infofile ########\n";
          $openok = open (RF, "$infofile");
          if ($openok) {
            print localtime(time) . ": Opened file $infofile for read\n";
            while(<RF>) {
              chomp();
              print WF "$_\n";
            }
            close(RF);
          }
          else {
            print localtime(time) . ": Failed to open file $infofile for read\n";
          }
        }
      }
      close(WF);
    }
    else {
      print localtime(time) . ": Unable to open /proc files\n";
    }
  } #  End  if -d procdir Reading *info* and modules from /proc
   # Print more data to the main report.
   
   my @commandarray;
   my $commandstring;
   push (@commandarray,"$UPTIME~~System Uptime");
   push (@commandarray,"$GETENFORCE~~SELinux Enforced");
   push (@commandarray,"$SESTATUS~~SELinux Status");
   push (@commandarray,"$IFCONFIG -a~~Network Interfaces");
   push (@commandarray,"$IP address~~Interface Addresses");
   push (@commandarray,"$MOUNT~~Mount Information");
   push (@commandarray,"$DF -k~~Filesystem Information");
   push (@commandarray,"$SUDO $RAW -qa~~Raw Device Information");
   push (@commandarray,"$IPCS -m~~Shared Memory Segment Info");
   push (@commandarray,"$IPCS -ml~~Shared Memory Segment Limits");
   push (@commandarray,"$IPCS -s~~Semaphore Info");
   push (@commandarray,"$IPCS -sl~~Semaphore Limits");
   push (@commandarray,"$IPCS -mt~~Shared Memory Segment Info with Time");
   push (@commandarray,"$IPCS -st~~Semaphore Info with Time");
   push (@commandarray,"$NUMACTL --show~~NUMA Policy Settings");
   push (@commandarray,"$NUMACTL --hardware~~NUMA Available Nodes");
   push (@commandarray,"$SWAPON -s~~Swap F/S Information");
   push (@commandarray,"$SAR -v 1 1~~Sar - inode, file and other kernel tables");
   push (@commandarray,"$SERVICE --status-all~~Status of All Services");
   push (@commandarray,"$SYSTEMCTL -a~~SYSTEMD Info");
   push (@commandarray,"$SYSCTL -a~~System and Kernel Settings");
   push (@commandarray,"$CHKCONFIG --list~~System Service information");
   push (@commandarray,"$PSTREE -lp~~Process Tree");
   push (@commandarray,"$SUDO $SHOWMOUNT -e~~NFS Exports");
   push (@commandarray, "$FREE -m~~Free Info");

   runcommandarray(\@commandarray);
   # Other Data 
   
   # dmesg
   $command = "$DMESG > $hostname" . "_dmesg";
   print localtime(time) . ": Gathering DMESG data\n";
   if ( -e $DMESG ) {
      runtimedcommand($command);
   }
}


########
# NAME
#  collect_systeminfo_s
#
# DESCRIPTION
#  collect osinfo in solaris env
#
# PARAMETERS
#  None
# RETURNS
#  None
############

sub collect_systeminfo_s
{
  my $infofile;
  my $command;
  my $date = `date`;
  chomp($date);

  my $outfile = $hostname . "_PROCDIRINFO";

  system("echo \"### System info  at $date ###\" > $outfile");
  system("echo >> $outfile");

  print localtime(time) . ": Collecting prtconf cmd output into $outfile\n";
  system("echo \"####### prtconf output ########\" >> $outfile");
  if ( -e $PRTCONF ) {
    $command = "$PRTCONF >> $outfile 2>&1";
    runtimedcommand($command);
  } else {
    print "$PRTCONF does not exist on this system\n\n";
  }

  print localtime(time) . ": Collecting psrinfo cmd output into $outfile\n";
  system("echo >> $outfile");
  system("echo \"####### psrinfo output ########\" >> $outfile");
  if ( -e $PSRINFO ) {
    $command = "$PSRINFO -v >> $outfile 2>&1";
    runtimedcommand($command);
  } else {
    print "$PSRINFO does not exist on this system\n\n";
  }

  # Print more data to the main report.

  my @commandarray;
  my $commandstring;
  push (@commandarray,"$UPTIME~~System Uptime");
  push (@commandarray,"$IFCONFIG -a~~Network Interfaces");
  push (@commandarray,"$IP address~~Interface Addresses");
  push (@commandarray,"$MOUNT~~Mount Information");
  push (@commandarray,"$DF -k~~Filesystem Information");
  push (@commandarray,"$IPCS -m~~Shared Memory Segment Info");
  push (@commandarray,"$IPCS -s~~Semaphore Info");
  push (@commandarray,"$IPCS -mt~~Shared Memory Segment Info with Time");
  push (@commandarray,"$IPCS -st~~Semaphore Info with Time");
  push (@commandarray,"$SWAP -s~~Swap F/S Information");
  push (@commandarray,"$SWAP -l~~Swap Allocation Information");
  push (@commandarray,"$SAR -v 1 1~~Sar - inode, file and other kernel tables");
  push (@commandarray,"$PSTREE -lp~~Process Tree");
  push (@commandarray,"$SYSDEF~~Solaris System Definition");
  push (@commandarray,"$PROJECTS -l~~Solaris Projects info");
  push (@commandarray,"$EXPORTFS~~NFS Exports");
  push (@commandarray,"$TOP -n 1~~TOP Info");
  push (@commandarray,"$SWAP -s~~SWAP Info");

  runcommandarray(\@commandarray);
  # Other Data

  # dmesg
  my $command = "$DMESG > $hostname" . "_dmesg";
  print localtime(time) . ": Gathering DMESG data\n";
  if ( -e $DMESG ) {
     runtimedcommand($command);
  }

  # pkginfo -x
  my $command = "$PKGINFO -x > $hostname" . "_pkginfo";
  print localtime(time) . ": Gathering Package data\n";
  if ( -e $PKGINFO ) {
     runtimedcommand($command);
  }
}

########
# NAME
#  collect_systeminfo_a
#
# DESCRIPTION
#  collect meminfo, cpuinfo in AIX env
#
# PARAMETERS
#  None
# RETURNS
#  None
#############
#

sub collect_systeminfo_a
{
  my $outfile = $hostname . "_PROCDIRINFO";
  my $infofile;
  my $command;
  my $date = `date`;
  chomp($date);
  
  #collect errpt on AIX systems
  if ( -e $ERRPT ) {
    $command = $ERRPT . " -a > $hostname" . "_ERRPT";
    runtimedcommand("$command");
  }

  system("echo \"### System info  at $date ###\" > $outfile");
  system("echo >> $outfile");

  print localtime(time) . ": Collecting prtconf cmd output into $outfile\n";
  system("echo \"####### prtconf output ########\" >> $outfile");
  if ( -e $PRTCONF ) {
    $command = "$PRTCONF >> $outfile 2>&1";
    runtimedcommand($command);
  } else {
    print "$PRTCONF does not exist on this system\n\n";
  }

  print localtime(time) . ": Collecting psrinfo cmd output into $outfile\n";
  system("echo >> $outfile");
  system("echo \"####### psrinfo output ########\" >> $outfile");
  if ( -e $PSRINFO ) {
    $command = "$PSRINFO -v >> $outfile 2>&1";
    runtimedcommand($command);
  } else {
    print "$PSRINFO does not exist on this system\n\n";
  }

  my @commandarray;
  my $commandstring;
  push (@commandarray,"$UPTIME~~System Uptime");
  push (@commandarray,"$IFCONFIG -a~~Network Interfaces");
  push (@commandarray,"$MOUNT~~Mount Information");
  push (@commandarray,"$DF -k~~Filesystem Information");
  push (@commandarray,"$IPCS -m~~Shared Memory Segment Info");
  push (@commandarray,"$IPCS -s~~Semaphore Info");
  push (@commandarray,"$SWAP -s~~Swap F/S Information");
  push (@commandarray,"$SWAP -l~~Swap Allocation Information");
  push (@commandarray,"$SAR -v 1 1~~Sar - inode, file and other kernel tables");
  push (@commandarray,"$PSTAT -S~~CPU Information");
  push (@commandarray,"$LSATTR -E -O -l sys0 -a realmem~~Memory Information");
  push (@commandarray,"$LSATTR -El sys0~~System and Kernel Settings");
  push (@commandarray,"$LSATTR -E -l sys0 -a maxpout~~Disk I/O pacing maxpout");
  push (@commandarray,"$LSATTR -E -l sys0 -a minpout~~Disk I/O pacing minpout");
  push (@commandarray,"$SCHEDO -a~~Processor Scheduling tunables");
  push (@commandarray,"$VMO -a~~Virtual Memory Manager tunables");
  push (@commandarray,"$SVMON -G~~SVMON Info");
  push (@commandarray,"$LSPS -a~~LSPS Info");
  # Have to do some processing of devices here to get ones we may need info on.
  foreach my $deviceline (`$LSDEV`) {
     chomp($deviceline);
     my $device = (split(' ', $deviceline))[0];
     if ( $device =~ /fscsi/ ) {    
        push (@commandarray,"$LSATTR -El $device~~Error Recovery Policy Settings for $device");
     }
  }

  runcommandarray(\@commandarray);
  
  # Very large output we push to a file.
  # instfix -ia
  my $command = "$INSTFIX -ia > $hostname" . "_ospatches";
  print localtime(time) . ": Gathering Patch data\n";
  if ( -e $INSTFIX ) {
    runtimedcommand($command);
  }
  # lslpp -h
  my $command = "$LSLPP -h > $hostname" . "_ospackages";
  print localtime(time) . ": Gathering OS Package data\n";
  if ( -e $LSLPP ) {
    runtimedcommand($command);
  }
  # devices
  my $command = "$LSDEV > $hostname" . "_devices";
  print localtime(time) . ": Gathering System Devices\n";
  if ( -e $LSDEV ) {
    runtimedcommand($command);
  }

}

########
# NAME
#  collect_systeminfo_h
#
# DESCRIPTION
#  collect meminfo, cpuinfo etc in HP/UX env
#
# PARAMETERS
#  None
# RETURNS
#  None
##############
 
sub collect_systeminfo_h
{
  my $outfile = $hostname . "_PROCDIRINFO";
  my $infofile;
  my $command;
  my $date = `date`;
  chomp($date);

  my @commandarray;
  my $commandstring;
  push (@commandarray,"$UPTIME~~System Uptime");
  push (@commandarray,"$MOUNT~~Mount Information");
  push (@commandarray,"$DF -k~~Filesystem Information");
  push (@commandarray,"$IPCS -m~~Shared Memory Segment Info");
  push (@commandarray,"$IPCS -s~~Semaphore Info");
  push (@commandarray,"$SWAPINFO -tm~~Swap F/S Information");
  push (@commandarray,"$SAR -w 2 2~~Sar - Swap Info");
  push (@commandarray,"$SAR -v 1 1~~Sar - inode, file and other kernel tables");
  push (@commandarray,"$MPSCHED -s~~System Processor Configuration");
  push (@commandarray,"$IOSCAN -fnkC processor~~CPU Information");
  push (@commandarray,"$KCTUNE~~System Kernel settings");
  push (@commandarray,"$SYSDEF~~System Kernel settings");
  push (@commandarray,"$VGDISPLAY -v~~Logical Volumes Groups");
  push (@commandarray,"$TOP -n 1~~TOP Info");
  push (@commandarray,"$SWAPINFO -a~~SWAPINFO");

  # Have to do some processing of Volume Groups here to get ones we may need info on.
  if ( -e $VGDISPLAY ) { 
     foreach my $deviceline (`$VGDISPLAY -v`) {
        chomp($deviceline);
        if ( $deviceline =~ /LV\sName/ ) {    
           $deviceline =~ s/.*LV\sName\s+//;
           push (@commandarray,"$LVDISPLAY $deviceline~~Logical Volume info for $deviceline");
        }
     }
  }

  runcommandarray(\@commandarray);
  
  # Very large output we push to a file.
  # show_patches  or swlist
  print localtime(time) . ": Gathering Patch data\n";
  my $SHOW_PATCHES = catfile("","usr","contrib","bin","show_patches");
  if ( -e $SHOW_PATCHES ) {
     my $command = "$SHOW_PATCHES > $hostname" . "_ospatches";
     runtimedcommand($command);
  } else {
     if ( -e $SWLIST ) {
        my $command = "$SWLIST -lproduct PH\* > $hostname" . "_ospatches";
        runtimedcommand($command);
     }
  }
 
  # OS packages
  my $command = "$SWLIST -lbundle > $hostname" . "_ospackages";
  print localtime(time) . ": Gathering OS Package data\n";
  if ( -e $SWLIST ) {
    runtimedcommand($command);
  }
}

########
# NAME
#  collect_systeminfo_w
#
# DESCRIPTION
#  collect meminfo, cpuinfo etc in Windows
#
# PARAMETERS
#  None
# RETURNS
#  None
###############
#
sub collect_systeminfo_w
{
  print localtime(time) . ": Exporting registry keys\n";

  save_registry_keys('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services',"SERVICES_KEYS","Service Keys");
  save_registry_keys('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\SubSystems',"SUBSYSTEMS_KEYS","Subsystem Keys");
  save_registry_keys('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment',"ENVIRONMENT_KEYS","Environment Keys");
  save_registry_keys('HKEY_LOCAL_MACHINE\SOFTWARE\Oracle',"ORACLE_KEYS","Oracle Keys");

  # Print more data to the main report.
   
   my @commandarray;
   my $commandstring;
   push (@commandarray,"$NET statistics Server~~Server Statistics");
   push (@commandarray,"$NET statistics Workstation~~Workstation Statistics");
   push (@commandarray,"$IPCONFIG /ALL~~Network Interfaces");
   push (@commandarray,"$NETSH interface ipv4 show global~~IPV4 Interface Details");
   push (@commandarray,"$NETSH interface ipv6 show global~~IPV6 Interface Details");
   push (@commandarray,"$NETSH interface tcp show global~~TCP Details");
   push (@commandarray,"$NETSH advfirewall show currentprofile~~ADV Firewall Details");
   push (@commandarray,"$NETSH interface ip show config~~Interface IP Config Details");
   push (@commandarray,"$NETSH -c interface dump~~Interface Dump Details");
   push (@commandarray,"$WMIC cpu~~CPU Details");
   push (@commandarray,"$WMIC diskdrive~~Diskdrive Details");
   push (@commandarray,"$WMIC logicaldisk~~Logicaldisk Details");
   push (@commandarray,"$WMIC service get caption, name, processid, startname~~Service Details");
   push (@commandarray,"$WMIC process get caption, name, commandline, ProcessId~~Process Details");
   push (@commandarray,"$TASKLIST /v~~Tasklist Details");
   push (@commandarray,"$SC query~~System Service Information");
   push (@commandarray,"$SYSTEMINFO~~System Information");
   push (@commandarray,"$NET localgroup~~User Details");

   my $tfa_home ="";
   my $result = tfactlwin_query_registry("tfa_home");
    my @lines = split(/\n/,$result);
    foreach my $line (@lines){
    my @tokens = split(/\s+/,$line);
    my $tokenArrLength = scalar @tokens;
    if($tokenArrLength>=4){
      $tfa_home=trim($tokens[3]);
    }
   }

   if(($tfa_home ne "") && (-r catfile($tfa_home,"internal","win_user_groups.txt"))){
     open my $handle, '<', catfile($tfa_home,"internal","win_user_groups.txt");
     chomp(my @output = <$handle>);
     close $handle;

     @output = grep { (/ORA/) } @output;
     push(@output,"Administrators");

     foreach my $group_name (@output){
      $group_name =~ s/^\*//;
      push (@commandarray,"$NET localgroup $group_name~~ $group_name Group Details");
     }
   }

   runcommandarray(\@commandarray);

   my $TMP_PATH = $ENV{TMP};

   if(-d $TMP_PATH){
    my $diskpart_commands = catfile($TMP_PATH,"diskpart.txt");
    system ("echo list disk >> $diskpart_commands");
    system ("echo list volume >> $diskpart_commands");
    $command = "$DISKPART < $diskpart_commands";
    open (my $file, ">", "$hostname"."_DISKPARTINFO") or die "Could not open file: $!";
    my $output = `$command`;
    die "$!" if $?; 
    print $file $output;
    close($file);
    unlink($diskpart_commands);
  }
  $command = "$WEVTUTIL qe System /f:text > $hostname" . "_SystemEventLog";
  runtimedcommand($command);
  $command = "$WEVTUTIL qe Application /f:text > $hostname" . "_ApplicationLog";
  runtimedcommand($command);
  $command = "$WEVTUTIL qe Security /f:text > $hostname" . "_SecurityLog";
  runtimedcommand($command);
}


sub runcommandarray {
   my $array_ref = shift;
   my $commandstring;
   my @commandarray = @{$array_ref};
   print REP "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n";
   foreach $commandstring ( @commandarray ) {
      my ($command,$desc) = split(/~~/,$commandstring);
      print REP "$desc :\n\n ";
      my $commandfile = $command;
      $commandfile =~ s/\s.*//;
      if ( -e $commandfile ) {
        runtimedcommand($command);
      } else {
        print REP "$commandfile not found on this system";
      }
      print REP "\n";
      print REP "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n";
   }
}


sub runtimedcommand  {
my $command = shift;
my $timeout = shift;
my $cmdout;

if ( !$timeout ) { $timeout = 10 };
  eval {
      local $SIG{ALRM} = sub { die "Timeout\n" };
      alarm $timeout;
      $cmdout = `$command`;
      print REP "$cmdout\n";
      alarm 0;
  };
  if ($@) {
      print localtime(time) . ": $command timed out.\n";
      return(99);
  } elsif ($? != 0) {
      print localtime(time) . ": $command failed.\n" ;
      return(1);
  } else {
      print localtime(time) . ": $command success.\n" ;
      return(0);
  }
}

sub save_registry_keys{
  my $base_key = shift;
  my $name = shift;
  my $header = shift;
  system("echo \"### $header ###\" >> "."$hostname"."_$name");
  system("reg export \"$base_key\" "."$hostname"."_$name"." /y >nul 2>&1");
}
