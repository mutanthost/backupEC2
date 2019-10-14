# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/crscollect.pl /main/21 2018/08/15 16:55:52 bburton Exp $
#
# crscollect.pl
# 
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      crscollect.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    llakkana    08/06/18 - XbranchMerge llakkana_bug-28227918 from main
#    llakkana    08/02/18 - collect ps grep of init.ohasd
#    recornej    04/26/18 - Adding sudo cmds.
#    llakkana    02/26/18 - Collect ora agent processes details
#    bburton     10/05/17 - Do not call ocrcheck unless we can be sure CRSD is
#                           down on all nodes bug 26627298
#    bburton     07/17/17 - Do not run ocrcheck when stack is up
#    bburton     07/12/17 - bug 26431907
#    bburton     05/08/17 - Windows opatch trying to get inventory of tfa_home
#                           dir
#    cnagur      04/18/17 - Fix for Bug 25817520
#    bburton     02/10/17 - fix checksu issues - bug 25521625
#    llakkana    11/10/16 - Add crs collections from ER - 23338859
#    manuegar    09/03/16 - Support the -extractto switch in the TFA installer.
#    bburton     08/04/16 - Collect Cluster Type info
#    bibsahoo    08/01/16 - FIX BUG 24285186
#    manuegar    06/24/16 - Bug 23517627 - SOLSP64-12.2-CRS:MANY OPATCH
#                           COREDUMP FILES GENERATED.
#    arupadhy    06/13/16 - Added support for windows crs files collection
#    bburton     02/18/16 - Move the crs collection out of collectfiles.pl
#    bburton     02/18/16 - Creation
# 
###################################################################
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

BEGIN {
  #Add the directory of this file to the search path
  push @INC, dirname($PROGRAM_NAME).'/..';
  push @INC, dirname($PROGRAM_NAME).'/../common';
  push @INC, dirname($PROGRAM_NAME).'/../modules';
  push @INC, dirname($PROGRAM_NAME).'/../common/exceptions';
}

use collection;
use tfactlshare;
use cmdlocation;

if ( $^O eq "MSWin32" )
{
  eval q{use base 'Win32'; 1} or die $@;
}
use Getopt::Long qw(:config no_auto_abbrev);


# Set up local variables
my $hostname;
my $crshome;
my $tfahome;
my $command;
my $from;
my $to;
my $repository=getcwd();

my $IS_WINDOWS;
my $IS_SOLARIS;

if ( $^O eq "MSWin32" ) {
  $IS_WINDOWS = 1;
}
if ( $^O eq "solaris" ) {
  $IS_SOLARIS = 1; 
}

my $current_user = tfactlshare_getUserName();
my $SUDO = "";
$SUDO = cmdlocation_get("sudo") if ( $current_user ne "root" );
$SUDO .=" -n" if ( $SUDO ne "" );

# Parse command line args

GetOptions('crshome=s'    => \$crshome,
           'from=s' => \$from,
           'to=s' => \$to,
           'hostname=s'    => \$hostname);

if(@ARGV) {
   print "\nInvalid Options specified: @ARGV\n";
   exit(1);
}

my $scan_name;
my $output_file;

#Open a log file for this collection script to write to
open (*STDOUT, '>', $hostname . "_crs_collection.log");
open (*STDERR, '>', $hostname . "_crs_collection.err");
print localtime(time) . ": Running CRS collection scripts for TFA \n";
print "hostname: $hostname\n";
print "crshome: $crshome\n";
print "from: $from\n";
print "to: $to\n";

if (!$crshome) {
    print localtime(time) . ": CRS Home Not Specified : Not running CRS or CHMOS Commands\n";
} else {
my $crsbindir = catfile ($crshome,"bin");

$command = catfile ($crsbindir,"crsctl");
runtimedcommand("$command check crs > $hostname"."_CHECKCRS");
runtimedcommand("$command query crs activeversion > $hostname"."_ACTIVEVERSION");
# Check the CRS ACTIVE VERSION.
# If there is no CRS ACTIVE VERSION then do not run all the CRS file gets 
my $activeversion="0";
open (AV,$hostname . "_ACTIVEVERSION") or $activeversion = "0";
while (<AV>) {
   if (/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/) {
       $activeversion = $&;
       print localtime(time) . ": CRS ACTIVE VERSION is $activeversion\n";
   }
}
close(AV);

# Check is CRS is up ..

my @lines = split /\n/ , tfactlshare_cat($hostname."_CHECKCRS");
my $crs_running = grep { $_ =~ /CRS-4537/ } @lines;
chomp($crs_running);

if ( $crs_running ) {
  print localtime(time) . ": CRS was available when running this script\n";
} else {
  print localtime(time) . ": CRS was not available when running this script\n";
}

# Collect GPNP profile
my $gpnp_profile = catfile($crshome,"gpnp",$hostname,"profiles","peer","profile.xml");
if(-f $gpnp_profile){
  print localtime(time) . ": Copying GPNP profile\n";
  copy($gpnp_profile,"$hostname"."_gpnp_peer_profile.xml");
}

if ( $activeversion > 0 ) { # Only run these commands if active version was found.

   my $ocrdumpfile = "$hostname"."_OCRDUMP";
   if ( -e $ocrdumpfile ) { unlink($ocrdumpfile) }  
   my $olrdumpfile = "$hostname"."_OLRDUMP";
   if ( -e $olrdumpfile ) { unlink($olrdumpfile) }  

   runtimedcommand("$command get css diagwait > $hostname"."_GETCSS");
   runtimedcommand("$command get css disktimeout >> $hostname"."_GETCSS");
   runtimedcommand("$command get css misscount >> $hostname"."_GETCSS");
   runtimedcommand("$command get css reboottime >> $hostname"."_GETCSS");
   runtimedcommand("$command get css priority >> $hostname"."_GETCSS");

   runtimedcommand("$command query css votedisk > $hostname"."_QUERYVOTE");
   runtimedcommand("$command query crs softwareversion > $hostname"."_SOFTWAREVERSION");

   $command = catfile ($crsbindir,"ocrconfig");
   runtimedcommand("$command -showbackup > $hostname"."_OCRBACKUP");

   ## commenting for now as we should not run ocrcheck when the stack is up on any node,,,
   #if ( $crs_running ) {
   #  print localtime(time) . ": Not running ocrcheck as CRS Stack is running\n";
   #} else {
   #  $command = catfile ($crsbindir,"ocrcheck");
   #  runtimedcommand("$command > $hostname"."_OCRCHECK",60);
   #}

   $command = catfile ($crsbindir,"olsnodes -n -i");
   runtimedcommand("$command > $hostname"."_OLSNODES",60);

   $command = catfile ($crsbindir,"olsnodes -l -p");
   runtimedcommand("$command >> $hostname"."_OLSNODES",60);

   $command = catfile ($crsbindir,"oifcfg getif");
   runtimedcommand("$command > $hostname"."_OIFCFG",60);

   $command = catfile ($crsbindir,"crsctl config crs"); 
   runtimedcommand("$SUDO $command > $hostname"."_crsctl_config_crs");  

   $output_file = "$hostname"."_PS";
   collection_ps_grep("d\\.bin",$output_file);
   collection_ps_grep("agent",$output_file);
   collection_ps_grep("init.ohasd",$output_file);

   $output_file = "$hostname"."_LS";
   collection_ls(catfile("","etc","oracle","scls_scr","$hostname","root"),$output_file);
   collection_ls(catfile("$crshome","cdata"),$output_file);
   collection_ls(catfile("$crshome","bin"),"$output_file"); 
   collection_ls(catfile("$crshome","crs","init"),"$output_file"); 

   collectFile(catfile("","etc","oracle","scls_scr","$hostname","root","ohasdrun"),"ohasdrun");
   collectFile(catfile("$crshome","crs","init","$hostname.pid"),"PIDS");

   $output_file = "$hostname"."_GPNPTOOL";
   collection_gpnptool($crshome,"get",$output_file);

   my $pattern="^10|^11.1";  # for version 10.1/10.2/11.1

   if ( $activeversion =~ /$pattern/ ) {
      print "\n".localtime(time) . ": Running Commands for 10g and 11gR1 installations\n";
      $command = catfile ($crsbindir,"crs_stat");
      runtimedcommand("$command > $hostname"."_CRSSTAT");
      $command = catfile ($crsbindir,"ocrdump");
      runtimedcommand("$command $hostname"."_OCRDUMP");
   } else {  # for commands OK on 11.2 and 12 
      print "\n".localtime(time) . ": Running Commands for 11gR2 and above installations\n";
      $command = catfile ($crsbindir,"crsctl");
      $command = $command . " stat res";
      runtimedcommand("$command -t > $hostname"."_STATRESCRS");
      runtimedcommand("$command -t -init > $hostname"."_STATRESOHAS");
      runtimedcommand("$command -f > $hostname"."_STATRESCRSFULL");
      runtimedcommand("$command -f -init > $hostname"."_STATRESFULLOHAS");
      runtimedcommand("$command -dependency > $hostname"."_STATRESDEPENDENCY");
      
      $command = catfile ($crsbindir,"crsctl");
      runtimedcommand("$SUDO $command query css ipmiconfig > $hostname"."_IPMI");
      runtimedcommand("$command query css ipmidevice >> $hostname"."_IPMI");
      runtimedcommand("$command query dns -servers > $hostname"."_DNSSERVERS");

      $command = catfile ($crsbindir,"srvctl");
      runtimedcommand("$command config nodeapps > $hostname"."_NODEAPPS");
      runtimedcommand("$command config asm > $hostname"."_CONFIGASM");
      runtimedcommand("$command config scan > $hostname"."_CONFIGSCAN");
      runtimedcommand("$command config scan_listener >> $hostname"."_CONFIGSCAN");
      runtimedcommand("$command status scan_listener >> $hostname"."_CONFIGSCAN");
      runtimedcommand("$command config gns -a  > $hostname"."_CONFIGGNS");

      $command = catfile ($crsbindir,"ocrdump");
      runtimedcommand("$command $hostname"."_OCRDUMP");
      runtimedcommand("$command -local $hostname"."_OLRDUMP");
   
      $command = catfile ("/sbin","acfsutil");
      if ( -e $command ) {
         runtimedcommand("$command registry > $hostname"."_ACFSREGISTRY");
         runtimedcommand("$command info fs > $hostname"."_ACFSINFOFS");
         runtimedcommand("$SUDO $command log"); 
         $command = "mv oks.log $hostname"."_ACFSUTILLOG";
         system("$command");
      } 
      
      #Get scan name
      $scan_name;
      open(RF,$hostname."_CONFIGSCAN") ||  print "Can't open file $hostname"."_CONFIGSCAN";
      while(<RF>) {
        chomp;
	if ( /SCAN name:\s([^,]+),/i ) {
	  $scan_name = $1;
	  last;
	}
      }
      close(RF);
   } 

   my $pattern="^12";  # for version 12 only

   if ( $activeversion =~ /$pattern/ ) {
      print "\n".localtime(time) . ": Running Commands for 12cR1 and above installations\n";
      $command = catfile ($crsbindir,"crsctl");
      runtimedcommand("$command get cluster mode config > $hostname"."_CLUSTERCONFIG");
      runtimedcommand("$command get cluster mode status >> $hostname"."_CLUSTERCONFIG");
      runtimedcommand("$command get node role config -all >> $hostname"."_CLUSTERCONFIG");
      runtimedcommand("$command get node role status -all >> $hostname"."_CLUSTERCONFIG");
      runtimedcommand("$command get cluster hubsize >> $hostname"."_CLUSTERCONFIG");
      runtimedcommand("$command get css leafmisscount >> $hostname"."_CLUSTERCONFIG");
      runtimedcommand("$SUDO $command get css ipmiaddr >> $hostname"."_CLUSTERCONFIG");
      runtimedcommand("$command query crs releasepatch >> $hostname"."_CLUSTERCONFIG");
      runtimedcommand("$command query crs softwarepatch >> $hostname"."_CLUSTERCONFIG");
      runtimedcommand("$command query socket udp >> $hostname"."_CLUSTERCONFIG");
   }

   $pattern="^12\.2"; # for 12.2 and above
   if ( $activeversion =~ /$pattern/ ) {
      print "\n".localtime(time) . ": Running Commands for 12cR2 and above installations\n";
      $command = catfile ($crsbindir,"crsctl");
      if ($to) {
         runtimedcommand("$command query calog -aftertime \"$from\" -beforetime \"$to\" > $hostname"."_CALOG");
      }
      else {
         runtimedcommand("$command query calog -aftertime \"$from\" > $hostname"."_CALOG");
      }
      runtimedcommand("$command get cluster type >> $hostname"."_CLUSTERCONFIG");
      runtimedcommand("$command get cluster extended >> $hostname"."_CLUSTERCONFIG");
      runtimedcommand("$command get cluster class >> $hostname"."_CLUSTERCONFIG");
      runtimedcommand("$command get cluster name >> $hostname"."_CLUSTERCONFIG");
      
   }
} 
else { # End of only run commands whe we have an active version.
   print localtime(time) . ": No CRS Active Version Found\n";
}
# End of collecting CRS related data .

#Collect Network related data
print "\n".localtime(time) . ": Started collecting Network related Data \n";
$output_file = "$hostname"."_NSLOOKUP";
collection_nslookup("$hostname",$output_file);
if ( $scan_name ) {
  collection_nslookup($scan_name,$output_file);
}
my %vips = collection_vips($crshome);
foreach my $vip ( keys %vips) {
  #key is vip name and values is vip ddress
  collection_nslookup($vip,$output_file);
}

my $mtu = collection_mtu();
my %ips = collection_ip_address($crshome);
my @nodes = collection_nodes_list($crshome);
$output_file = "$hostname"."_PING_INFO";
if ( exists $ips{PUBLIC_IP} && $ips{PUBLIC_IP} ne "" ) {
  foreach my $node (@nodes) {
    collection_ping("-s $mtu -c 2 -I $ips{PUBLIC_IP} $node",$output_file);
  } 
}
if ( exists $ips{PRIVATE_IP} && $ips{PRIVATE_IP} ne "" ) {
  collection_nslookup($ips{PRIVATE_IP});
  $command = catfile($crshome,"bin","tfactl print ipaddress");
  my $pips = `$command`;
  foreach my $pip (split /\n/,$pips) {    
    collection_ping("-s $mtu -c 2 -I $ips{PRIVATE_IP} $pip",$output_file);
  }
}
foreach my $vip ( keys %vips) {
  collection_ping("-c 2 $vips{$vip}",$output_file);
}


print localtime(time) . ": Completed collecting Network related Data \n";


# Collect CRS opatch lsinventory data. 

$command = catfile ($crshome,"OPatch","opatch");

if ( -e $command ) {
  if($IS_WINDOWS){
    $command = "$command lsinventory -detail -retry 0 -oh $crshome > $hostname"."_OPATCH_CRS 2>&1";
  }else{
    my $uid = (stat $command)[4];
    my $user = getpwuid($uid);
    chomp($user);
    $command = tfactlshare_checksu($user,"$command lsinventory -detail -retry 0 -oh $crshome") . " > $hostname"."_OPATCH_CRS 2>&1";
  }
  chmod(0711,$repository);
  runtimedcommand("$command > $hostname"."_OPATCH_CRS 2>&1",30);
  chmod(0700,$repository);
}

# Collect Windows Specific collection

if($IS_WINDOWS){
  # TODO check with Bill if is_crs_up needs to be checked 
  $command = catfile($crshome,"bin","orahomeuserctl.exe");
  if(-f $command){
    $command = "$command list > $hostname"."_GRIDUSERINFO 2>&1";
    runtimedcommand($command,30);
  }

  $command = catfile($crshome,"bin","asmtool.exe");
  if(-f $command){
    $command = "$command -list > $hostname"."_GRIDSTAMPDISKS 2>&1";
    runtimedcommand($command,30);

    $command = catfile($crshome,"bin","asmtool.exe");
    my @output = `$command -list 2>&1`;    
    chomp @output;

    @output = grep { /ORCL/ } @output;

    foreach my $line (@output)
    {
        my @list = split(/\s/, $line);
        $command = catfile($crshome, "bin", "kfed.exe");
        $command = "$command read \\\\.\\$list[0] > $hostname"."_$list[0] 2>&1";
        runtimedcommand($command,30);
    }
  }
  
}

} # End of only run if crshome is set.

print localtime(time) . ": Completed collecting CRS Specific Data \n";
     
close(LOG2);


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

sub collectFile 
{
  my $file = shift;
  my $sfn = shift;
  my $outfile = "$hostname"."_"."$sfn";
  if ( -f $file ) {
    collection_cat_file($file, $outfile);
  }
}

