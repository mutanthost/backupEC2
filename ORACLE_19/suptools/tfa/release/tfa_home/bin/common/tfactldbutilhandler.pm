# 
# $Header: tfa/src/v2/tfa_home/bin/common/tfactldbutilhandler.pm /main/7 2018/08/20 12:45:48 manuegar Exp $
#
# tfactldbutilhandler.pm
# 
# Copyright (c) 2017, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactldbutilhandler.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    manuegar    08/10/18 - manuegar_dbutils17.
#    recornej    08/06/18 - Change SUCCESS and FAILED values.
#    manuegar    08/05/18 - XbranchMerge manuegar_dbutils16 from main
#    manuegar    07/20/18 - manuegar_dbutils16.
#    manuegar    06/11/18 - manuegar_dbutils13_handlers.
#    manuegar    05/30/18 - manuegar_shared_dbutils12.
#    bburton     05/21/18 - Do not call hostname -d
#    manuegar    05/18/18 - manuegar_shared_dbutils10.
#    manuegar    04/17/18 - Bug 27873519 - LNX-191-TFA: JAVA EXPCETION IN
#                           TFADBUTLTHREAD.
#    manuegar    04/10/18 - manuegar_shared_dbutils06.
#    manuegar    04/03/18 - manuegar_shared_dbutils05.
#    recornej    03/12/18 - Change date/time format.
#    recornej    03/01/18 - Adding SOLARIS support to the handlers
#    recornej    02/13/18 - Completing serverhandler
#    manuegar    12/13/17 - Creation
# 

package tfactldbutilhandler;

our @exp_vars;
our $CFG; 

BEGIN {
use Exporter ();
our($VERSION, @ISA, @EXPORT, @EXPORT_OK);
  $VERSION = 1.00; 
  @ISA = qw(Exporter);

  my @exp_const = qw(TRUE FALSE ERROR FAILED SUCCESS CONNFAIL DBG_HOST DBG_VERB DBG_WHAT DBG_NOTE);

  our @exp_vars = qw($DEBUG $PORT $SUPPORTMODE $SR $TFA_HOME $NODE_NAMES $CRS_HOME $tputcols);

  my @exp_func = qw(tfactldbutilhandler_crsreshandler
                    tfactldbutilhandler_mgmtdbinstancehandler
                    tfactldbutilhandler_dbinstancehandler
                    tfactldbutilhandler_asminstancehandler
                    tfactldbutilhandler_asmdiskgrouphandler
                    tfactldbutilhandler_asmdiskhandler
                    tfactldbutilhandler_serverhandler
                    tfactldbutilhandler_memoryhandler
                    tfactldbutilhandler_diskhandler
                    tfactldbutilhandler_cpuhandler
                    tfactldbutilhandler_networkhandler
                    tfactldbutilhandler_ospackageshandler
                    tfactldbutilhandler_osparameterhandler
                  );

  @EXPORT  = qw($CFG);
  push @EXPORT, @exp_const, @exp_func, @exp_vars;

}

use strict;
use English;
use IPC::Open2;
use File::Copy;
use File::Path;
use File::Find;
use File::Basename;
use File::Basename  qw( dirname );
use File::Spec::Functions;
use Cwd 'abs_path';
use Getopt::Long;
use Sys::Hostname;
use POSIX;
use POSIX qw(:termios_h);
use Carp;
use Config;
use Data::Dumper;
use Socket;
use Term::ANSIColor;
use B;
use Net::Ping;

BEGIN {
  push @INC, dirname($PROGRAM_NAME).'/..';
  push @INC, dirname($PROGRAM_NAME).'/../common/exceptions';
}

use Text::ASCIITable;
use Text::Wrap;
use Time::Local;
use Date::Manip qw(ParseDate UnixDate);
#use Time::HiRes qw(time);
use constant ERROR                     => "-1";
use constant FAILED                    =>  1;
use constant SUCCESS                   =>  0;
use constant TRUE                      =>  "1";
use constant FALSE                     =>  "0";
use constant CONNFAIL                  =>  "99";
use constant DBG_NOTE => "1";              # Notes to the user
use constant DBG_WHAT => "2";              # Explain what you do
use constant DBG_VERB => "4";              # Be verbose
use constant DBG_HOST => "8";              # print command executed on local host

use tfactlexceptions;
use tfactlglobal;
use tfactlshare;
use tfactlparser;
use cmdlocation;
use osutils;
use dbutil;
use tfactlwin;

my $timezone  = "";

if ($IS_WINDOWS)
{
  eval q{use base 'Win32'; 1} or die $@;
}

sub tfactldbutilhandler_timezone {
  my $tz = "";
  if (length $DBUTILSAVLTZONE) {
    $tz  = $DBUTILSAVLTZONE;
    $ENV{"TZ"} = $tz;
    POSIX::tzset();
  } else {
    $tz  = strftime("%Z",localtime);
  }
  return $tz;
} # end sub tfactldbutilhandler_timezone


#
# resType: ora.asm.type,
#
sub tfactldbutilhandler_merge {
  my $atribsarrayref    = shift;
  my $mapatribsarrayref = shift;
  my $resType           = shift;
  my @atribsarray       = @$atribsarrayref;
  my @mapatribsarray    = @$mapatribsarrayref;
  my @hosts             = getListOfAllNodes($tfa_home);
  my $crs_home          = get_crs_home($tfa_home);

  my @retArray;
  my %retHash = ();
  my %hashf   = ();
  my %hashv   = ();

  $retHash{"timestamp"} = get_timestamp();

  foreach my $hostname (@hosts) {
     %hashf = ();
     %hashv = ();
     $retHash{"hostname"} = $hostname;

     %hashf = tfactlparser_crsctl($crs_home,'-f',"(TYPE = $resType) AND (LAST_SERVER = $hostname)");
     %hashv = tfactlparser_crsctl($crs_home,'-v',"(TYPE = $resType) AND (LAST_SERVER = $hostname)");

     # Join %hashf and %hashv, key=ora.asm
     for my $key (keys %hashv) {
        my %hash = ();
        my $reff = $hashf{$key};
        my $refv = $hashv{$key};
        my %joinedHash = ( %$reff, %$refv );
        $hashf{$key} = \%joinedHash;

        # Add result items
        foreach my $ndx (0 .. $#atribsarray) {
          my $item = $atribsarray[$ndx];
          my $mappeditem = $mapatribsarray[$ndx];
          $hash{lc($mappeditem)} = $joinedHash{$item};
        }
        %hash = (%hash,%retHash);
        push @retArray, \%hash;
      }
  } # end foreach @hosts
  return \@retArray;
} # end sub tfactldbutilhandler_merge


sub tfactldbutilhandler_mgmtdbinstancehandler {
  my @atribsarray    = ("DB_UNIQUE_NAME","USR_ORA_DB_NAME","USR_ORA_DOMAIN","GEN_USR_ORA_INST_NAME","CARDINALITY_ID","STATE","TARGET","LAST_SERVER","TARGET_SERVER","RESTART_COUNT","FAILURE_COUNT","INCARNATION","LAST_RESTART","LAST_STATE_CHANGE","STATE_DETAILS","INTERNAL_STATE");
  my @mapatribsarray = ("DB_UNIQUE_NAME","DB_NAME","DB_DOMAIN","ORACLE_SID","CARDINALITY_ID","STATE","TARGET","LAST_SERVER","TARGET_SERVER","RESTART_COUNT","FAILURE_COUNT","INCARNATION","LAST_RESTART","LAST_STATE_CHANGE","STATE_DETAILS","INTERNAL_STATE");

  return tfactldbutilhandler_merge(\@atribsarray,\@mapatribsarray, "ora.mgmtdb.type");
} # end tfactldbutilhandler_mgmtdbinstancehandler


sub tfactldbutilhandler_dbinstancehandler {
  my @atribsarray    = ("DB_UNIQUE_NAME","USR_ORA_DB_NAME","USR_ORA_DOMAIN","GEN_USR_ORA_INST_NAME","CARDINALITY_ID","STATE","TARGET","LAST_SERVER","TARGET_SERVER","RESTART_COUNT","FAILURE_COUNT","INCARNATION","LAST_RESTART","LAST_STATE_CHANGE","STATE_DETAILS","INTERNAL_STATE");
  my @mapatribsarray = ("DB_UNIQUE_NAME","DB_NAME","DB_DOMAIN","ORACLE_SID","CARDINALITY_ID","STATE","TARGET","LAST_SERVER","TARGET_SERVER","RESTART_COUNT","FAILURE_COUNT","INCARNATION","LAST_RESTART","LAST_STATE_CHANGE","STATE_DETAILS","INTERNAL_STATE");

  return tfactldbutilhandler_merge(\@atribsarray,\@mapatribsarray, "ora.database.type");
} # end tfactldbutilhandler_dbinstancehandler


sub tfactldbutilhandler_asminstancehandler {
  my @atribsarray    = ("GEN_USR_ORA_INST_NAME","CARDINALITY_ID","STATE","TARGET","LAST_SERVER","TARGET_SERVER","RESTART_COUNT","FAILURE_COUNT","INCARNATION","LAST_RESTART","LAST_STATE_CHANGE","STATE_DETAILS","INTERNAL_STATE");
  my @mapatribsarray = ("ORACLE_SID","CARDINALITY_ID","STATE","TARGET","LAST_SERVER","TARGET_SERVER","RESTART_COUNT","FAILURE_COUNT","INCARNATION","LAST_RESTART","LAST_STATE_CHANGE","STATE_DETAILS","INTERNAL_STATE");

  return tfactldbutilhandler_merge(\@atribsarray,\@mapatribsarray, "ora.asm.type");
} # end tfactldbutilhandler_asminstancehandler

sub tfactldbutilhandler_asmdiskhandler {
  my @retArray = ();
  return \@retArray;
}


sub tfactldbutilhandler_asmdiskgrouphandler {
  my @atribsarray    = ("NAME","STATE","TARGET","LAST_SERVER","TARGET_SERVER","RESTART_COUNT","FAILURE_COUNT","INCARNATION","LAST_RESTART","LAST_STATE_CHANGE","STATE_DETAILS","INTERNAL_STATE");
  my @mapatribsarray = ("NAME","STATE","TARGET","LAST_SERVER","TARGET_SERVER","RESTART_COUNT","FAILURE_COUNT","INCARNATION","LAST_RESTART","LAST_STATE_CHANGE","STATE_DETAILS","INTERNAL_STATE");

  return tfactldbutilhandler_merge(\@atribsarray,\@mapatribsarray, "ora.diskgroup.type");
} # end tfactldbutilhandler_asmdiskgrouphandler


sub tfactldbutilhandler_crsreshandler {
  my @retArray;
  my %retHash = ();
  my @cmdsarray = ();
  my @namesarray = ();
  my %hashf = ();
  my %hashv = ();
  my $crs_home = get_crs_home($tfa_home);
  my @atribsarray = ("NAME","TYPE","STATE","TARGET","ACL","INTERNAL_STATE","LAST_RESTART","LAST_STATE_CHANGE");
  my @hosts = getListOfAllNodes($tfa_home);

  $retHash{"timestamp"} = get_timestamp();

  foreach my $hostname (@hosts) {
     %hashf = ();
     %hashv = ();
     $retHash{"hostname"} = $hostname;

     %hashf = tfactlparser_crsctl($crs_home,'-f',"",$hostname);
     %hashv = tfactlparser_crsctl($crs_home,'-v',"",$hostname);

     # Join %hashf and %hashv
     for my $key (keys %hashv) {
        my %hash = ();
        my $reff = $hashf{$key};
        my $refv = $hashv{$key};
        my %joinedHash = ( %$reff, %$refv );
        $hashf{$key} = \%joinedHash;

        # Add result items
        foreach my $item (@atribsarray) {
          $hash{lc($item)} = $joinedHash{$item};
        }
        %hash = (%hash,%retHash);
        push @retArray, \%hash;
      }
  } # end foreach @hosts
  return \@retArray;
} # end sub tfactldbutilhandler_crsreshandler


sub tfactldbutilhandler_serverhandler {
  my %retHash = ();
  my @cmdsarray = ();
  my @namesarray = ();

  if ( $IS_SOLARIS ){
    push @namesarray, "hostname"; push @cmdsarray, "$HOSTNAME"; #hostname -s AIX
    push @namesarray, "domainname"; push @cmdsarray, "$DOMAINNAME";
    push @namesarray, "osname"; push @cmdsarray, "$UNAME -s";
    push @namesarray, "down"; push @cmdsarray, "last reboot -n 10 | $GREP down";
    push @namesarray, "boot"; push @cmdsarray, "last reboot -n 10 | $GREP \"system boot\"";
    push @namesarray, "osversion"; push @cmdsarray, "$UNAME -r"; 
  } elsif ( $IS_AIX ){
    #TODO
    return \%retHash;
  } elsif ( $IS_HPUX ) {
    #TODO
    return \%retHash;
  } elsif ( $IS_WINDOWS) {
    #TODO
    return \%retHash;
  } else {
    #Linux
    push @namesarray, "hostname"; push @cmdsarray, "$HOSTNAME -s"; #hostname -s AIX
    push @namesarray, "domainname"; push @cmdsarray, "$HOSTNAME -d";
    push @namesarray, "osname"; push @cmdsarray, "$UNAME -o"; 
    push @namesarray, "down"; push @cmdsarray, "last -x shutdown -n 10 | $GREP shutdown";
    push @namesarray, "boot"; push @cmdsarray, "last -x reboot -n 10 | $GREP reboot";
    push @namesarray, "osversion"; push @cmdsarray, "$CAT /etc/*-release | $GREP \"^VERSION=\"";
  }
  
  %retHash = tfactldbutilhandler_execcmds( \@namesarray, \@cmdsarray );
  
  my @downs;
  my @boots;
  if ($IS_SOLARIS) {
    @downs= split(/(?=^reboot)|(?=reboot)/,$retHash{"down"});
    @boots= split(/(?=^reboot)|(?=reboot)/,$retHash{"boot"});
  
  } else {
    @downs= split(/(?=^shutdown)|(?=shutdown)/,$retHash{"down"});
    @boots= split(/(?=^reboot)|(?=reboot)/,$retHash{"boot"});
  }
  $retHash{"down"} = "";
  $retHash{"boot"} = "";
  
  foreach my $down ( @downs) {
    my $time = (split ( /\s+/,$down,5))[4];
    $time =~ s/^\s+|\s+$//g;
    if ( $retHash{"down"} eq "" ){
      $retHash{"down"}.=$time;
    } else { 
      $retHash{"down"} .= "|" . $time;
    }
  }#end foreach

  foreach my $boot ( @boots) {
    my $time = (split ( /\s+/,$boot,5))[4];
    $time =~ s/^\s+|\s+$//g;
    if($retHash{"boot"} eq "") {
      $retHash{"boot"}.=$time 
    } else {
      $retHash{"boot"}.="|".$time;
    }
  }#end foreach

  $retHash{"osversion"} =~ s/VERSION\=|\"|\s+$//g;
  $retHash{"vm"} = $IS_VM ? "true" : "false";
  $retHash{"timestamp"} = get_timestamp();
  $retHash{"timezone"} = $timezone;
  return \%retHash;
} # end sub tfactldbutilhandler_serverhandler

sub tfactldbutilhandler_cpuhandler {
  my %retHash= ();
  my @cmdsarray = ();
  my @namesarray = ();
  my $out;

  push @namesarray, "load_averange"; push @cmdsarray,$UPTIME;
  push @namesarray, "hostname"; push @cmdsarray, $HOSTNAME;

  if ( $IS_SOLARIS ) {
    #Pending cpuhandler info 
    push @namesarray, "count"; push @cmdsarray, "psrinfo | $GREP \"Status.*processor\" | wc -l";
  } elsif ( $IS_AIX ) {
    #TODO
    return \%retHash;
  } elsif ( $IS_HPUX ) {
    #TODO
    return \%retHash;
  } elsif ( $IS_WINDOWS ) {
    #TODO
    return \%retHash;
  } else { 
    #LINUX 
    push @namesarray, "count"; push @cmdsarray, "$LSCPU | $GREP \"^CPU(s)\"";
    $out = `$VMSTAT -w | $GREP -v procs | $GREP -v r`;
  }
  %retHash = tfactldbutilhandler_execcmds( \@namesarray, \@cmdsarray );

   
  my @cols = split(/\s+/,$out);
  $retHash{"pct_user"} = $cols[-5];
  $retHash{"pct_sys"} = $cols[-4];
  $retHash{"pct_idle"} = $cols[-3];
  $retHash{"pct_wio"} = $cols[-2];
  $retHash{"pct_used"} = 100 - $retHash{"pct_idle"}; 
  $retHash{"load_averange"} =~ s/.*\:\s*//g;
  $retHash{"count"} =~ s/.*\:\s*|^\s+|\s+$//g;
  $retHash{"timestamp"} = get_timestamp();
  return \%retHash;
}
sub tfactldbutilhandler_memoryhandler {
  my %retHash = ();
  my @cmdsarray = ();
  my @namesarray = ();

  push @namesarray, "hostname"; push @cmdsarray,$HOSTNAME;
  %retHash = tfactldbutilhandler_execcmds( \@namesarray, \@cmdsarray );

  my $out = `$EGREP 'Mem|Cache|Swap' /proc/meminfo | $GREP -v SwapCached `;
  $out =~ s/MemTotal/total_memory/g;
  $out =~ s/MemFree/free_memory/g;
  $out =~ s/Cached/cache_memory/g;
  $out =~ s/SwapTotal/swap_total/g;
  $out =~ s/SwapFree/swap_free/g;
  %retHash = (%retHash, split( /[\:\n]/ ,$out));
  foreach my $key (keys %retHash) {
    $retHash{$key} =~ s/^\s+//g;
  }
  $retHash{"used_memory"} = ($retHash{"total_memory"} - $retHash{"free_memory"})." kB";
  $retHash{"swap_used"} = ($retHash{"swap_total"} - $retHash{"swap_free"})." kB";
  $retHash{"timestamp"} = get_timestamp();
  return \%retHash;
} # end sub tfactldbutilhandler_memoryhandler

sub tfactldbutilhandler_diskhandler {
  my @retArray;
  my %retHash = ();
  my @cmdsarray = ();
  my @namesarray = ();

  push @namesarray, "hostname"; push @cmdsarray,$HOSTNAME;
  %retHash = tfactldbutilhandler_execcmds( \@namesarray, \@cmdsarray );
  $retHash{"timestamp"} = get_timestamp();

  my $out;
  if ( $IS_SOLARIS ){
    $out = `$DF -h`;
  } elsif ( $IS_AIX ) {
    $out = `$DF -Pg`;
  } else {
    $out = `$DF -PH`;
  }
  my @lines = split(/\n|\n\s+/,$out);
  shift(@lines); #Get rid of heading.. 
  foreach my $line (@lines) {
    my %hash;
    my @cols = split(/\s+/,$line);
    $hash{"filesystem"} = $cols[0];
    $hash{"size"} = $cols[1];
    $hash{"used"} = $cols[2];
    $hash{"available"} =$cols[3];
    $hash{"used_percent"} =$cols[4];
    $hash{"mountpoint"} = $cols[5];
    %hash = (%hash,%retHash);
    push(@retArray,\%hash);
  }
  return \@retArray;
} # end sub tfactldbutilhandler_diskhandler

sub tfactldbutilhandler_networkhandler {
  my %retHash= ();
  my @cmdsarray = ();
  my @namesarray = ();
  my @retArray;
  
  
  push @namesarray, "hostname"; push @cmdsarray, $HOSTNAME;
  %retHash = tfactldbutilhandler_execcmds( \@namesarray, \@cmdsarray );
  $retHash{"timestamp"} = get_timestamp();

  my $net = `$IFCONFIG -a`;
  my @networks = split (/\n\n+/,$net);
  foreach my $network ( @networks ) {
    my %hash = ();
    my @lines =  split ( /\n/,$network);
    @lines = grep { $_ !~ /^\s*RX|^\s*TX|^\s*collisions|^\s*inet6/ } @lines;
    foreach my $line ( @lines ) {
      if ( $line =~ /^\s+/ ) {
        $line =~ s/^\s+|\s+$//g;
        if ( $line =~ /^inet addr\:(.*?)\s+.*$/) {
          #inet addr:192.168.1.194 Bcast:192.168.1.225 .....
          $hash{"ip_address"} =$1;
        } elsif ( $line =~ /^(.*?)\s+MTU\:(.*?)\s+.*$/ ){
          #UP LOOPBACK RUNNING MULTICAST MTU:1500 Metric:1
          $hash{"state"} = $1;
          $hash{"mtu"} = $2;
        } elsif ( $line =~ /^inet\s+(.*?)\s+.*$/ ) {
          #inet 169.254.143.200 netmask 255.0.0.0
          $hash{"ip_address"} =$1;
        } elsif ( $line =~ /^ether\s+(.*?)\s+.*$/ ) {
          #ether 00:16:3e:32:d6:be txqueuelen 1000 (Ethernet)
          $hash{"mac_address"} = $1;
        }
      
      } else { 
        #Line with the interface 
        $line =~ s/\s+$//g;
        if ( $line =~ /^(.*)\:\s+flags\=\d+\<(.*)\>\s*mtu\s+(.*)\s*$/ ) {
          # eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST> mtu 1500
          $hash{"interface"} = $1;
          $hash{"state"} =$2;
          $hash{"mtu"} = $3;
        } elsif ( $line =~ /^(.*?)\s+Link.*HWaddr\s+(.*)\s*$/ ) {
          # eth0 Link encap:Ethernet HWaddr 00:21:F6:02:7C:C2
          $hash{"interface"} = $1;
          $hash{"mac_address"} = $2;
        } elsif ( $line =~ /^(.*?)\s+Link.*$/){
          # lo Link encap:Local Loopback
          $hash{"interface"} = $1;
        }#If there is another case add it here
      
      } #end if $line 
    
    }#end foreach $line 
    if ( $hash{"interface"} =~ /\:/ ) {
      next; # Don't add virtual interfaces
      $hash{"virtual_interface"} = "true";
    } else {
      $hash{"virtual_interface"} = "false";
    }
    #ping ip to see if its alive 
    my $p = Net::Ping->new();
    $hash{"alive"} = "false";
    $hash{"alive"} = "true" if ( $p->ping($hash{"ip_address"}));

    %hash = ( %hash, %retHash);
    push (@retArray,\%hash);
  }#end foreach $network 

  return \@retArray;
}

sub tfactldbutilhandler_ospackageshandler {
  my %retHash= ();
  my @retArray = ();
  my @namesarray = ();
  my @cmdsarray = ();

  push @namesarray, "hostname"; push @cmdsarray, $HOSTNAME;
  %retHash = tfactldbutilhandler_execcmds( \@namesarray, \@cmdsarray );
  
  my @packages = `rpm -qa -last`;
  chomp(@packages);
  foreach my $package ( @packages ) {
    my %hash = ();
    my ( $name, $installtime ) = split (/\s+/,$package,2);
    $hash{"timestamp"} = get_timestamp($installtime);
    $hash{"package"} = $name;
    %hash = (%hash, %retHash);
    push(@retArray, \%hash);
  }
  return \@retArray;
}# end sub tfactldbutilhandler_ospackageshandler

sub tfactldbutilhandler_osparameterhandler {
  my %retHash= ();
  my %excludeHash = ();
  my @retArray = ();
  my @namesarray = ();
  my @cmdsarray = ();

  $excludeHash{"kernel.core_pattern"} = TRUE;

  push @namesarray, "hostname"; push @cmdsarray, $HOSTNAME;
  %retHash = tfactldbutilhandler_execcmds( \@namesarray, \@cmdsarray );
  $retHash{"timestamp"} = get_timestamp();

  my @parameters;
  #Add platform specific command 
  @parameters = `$SYSCTL -a 2>&1`;
  chomp(@parameters);
  @parameters = grep { $_ !~ /error:|sysctl:/ } @parameters;
  foreach my $param ( @parameters) {
    my %hash = ();
    my ($name,$value) =  split( /\=/ ,$param);
    $name =~ s/^\s+|\s+$//g;
    next if ( (grep /$name/, keys %excludeHash) && length $name ); 
    $hash{"name"} = $name;
    $value = "EMPTYVAL" if trim($value) eq '';
    $hash{"value"} = $value;
    %hash = (%hash, %retHash);
    push(@retArray, \%hash);
  }
  return \@retArray;
}# end sub tfactldbutilhandler_osparameterhandler


sub tfactldbutilhandler_execcmds {
  my $names_ref  = shift;
  my $cmds_ref   = shift;
  my @namesarray = @$names_ref;
  my @cmdsarray  = @$cmds_ref;
  my %retHash    = ();

  for ( my $ndx = 0; $ndx <= $#namesarray; $ndx++ ) {
     my $name = $namesarray[$ndx];
     my $cmd  = $cmdsarray[$ndx];
     my $output = `$cmd`;
     ### print "name $name, cmd $cmd, output $output \n";
     $output =~ s/\n//g;
     $retHash{$name} = $output;
  }

  return %retHash;
} # end sub tfactldbutilhandler_execcmds

sub get_timestamp {
  my $str = shift;
  my $t;
  my $timestamp;

  $timezone = tfactldbutilhandler_timezone();

  if ($str ) {
    $t = tfactlshare_get_date($str);
    $timestamp = getValidDateFromString($t,"time");
    $timestamp = strftime('%Y%m%d%H%M%s',localtime($timestamp));
  } else {
    $timestamp = strftime('%Y%m%d%H%M%s',localtime());
  }
  $timestamp = substr($timestamp,0,17); #17 digits precision
  $timestamp += 0; #Force timestamp to be a number;
  return $timestamp;
}

1;
