# 
# $Header: tfa/src/v2/tfa_home/bin/common/collection.pm /main/6 2018/05/28 15:06:27 bburton Exp $
#
# collection.pm
# 
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      collection.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    04/26/18 - Adding sudo to ib commands.
#    cnagur      11/21/16 - Remove quotes from CRS_NODEVIPS
#    llakkana    11/30/16 - XbranchMerge bburton_fix_nslookup from
#                           st_tfa_12.1.2.8
#    bburton     11/20/16 - validation
#    bburton     11/18/16 - Need to handle CRS being down
#    llakkana    10/26/16 - Creation
# 
package collection;

BEGIN {
use Exporter();
our (@ISA, @EXPORT);
@ISA = qw(Exporter);
my @exp_func = qw(collection_run_level collection_cat_file collection_netstat
		  collection_copy collection_ps_grep collection_ls collection_nslookup
		  collection_scan collection_gpnptool collection_mtu collection_ip_address
		  collection_vips collection_ping collection_rds_info collection_ib_cmd
		  collection_nodes_list
		 );
push @EXPORT,@exp_func;
}

use strict;
use English;
use File::Spec::Functions;
use File::Copy;
use Time::Local;
use POSIX;
use cmdlocation;

my $command;

###########Typical OS functions############
sub collection_run_level
{
  my $service = shift; #run level of system/service
  my $outfile = shift;
  if ( $service eq "system" ) {
    $command = "$WHO -r";
  }
  else {
    #TODO
    $command = "$WHO -r";
  }
  runtimedcommand($command,$outfile,"Output of $command");
}


sub collection_cat_file
{
  my $file = shift;
  my $outfile = shift;
  my $filter_str = shift;
  if ( ! -e $file || -l $file || ! -f $file) {
    print "File $file does not exists or is invalid to cat";
    return;
  }
  $command = "$CAT $file | $GREP \"$filter_str\"";
  runtimedcommand($command,$outfile,"Output of $command");
}

sub collection_copy
{
  my $file = shift;
  my $outfile = shift;
  if ( ! -e $file || -l $file || ! -f $file ) {
    print "File $file does not exists or is invalid";
    return;
  }
  copy($file,$outfile);
}

sub collection_netstat
{
  my $outfile = shift;
  $command = "$NETSTAT -in";
  runtimedcommand($command,$outfile,"Output of $command");
}

sub collection_ps_grep
{
  my $grep_for = shift;
  my $outfile = shift;
  my $flags;
  $flags = "-ef";
  #TODO - Have flags based on platform
  $command = "$PS $flags | $GREP -v grep | $GREP \"$grep_for\"";
  runtimedcommand($command,$outfile,"Output of $command");
}

sub collection_ls
{
  my $file = shift;
  my $outfile = shift;
  if ( ! -e $file ) {
    print "File $file does not exists";
    return;
  }
  $command = "$LS -ltr $file";
  runtimedcommand($command,$outfile,"Output of $command");
}

#######Network related functions######
sub collection_nslookup
{
  my $arg = shift;
  my $outfile = shift;  
  if ( invalid_chars($arg)) {
     print "Invalid Characters in Hostname for nslookup";
     return;
  }
  $command = "$NSLOOKUP $arg";
  runtimedcommand($command,$outfile,"Output of $command");
}

sub collection_scan
{
  my $crshome = shift;
  my $outfile = shift;
  $command = catfile("$crshome","bin","srvctl config scan");
  runtimedcommand($command,$outfile,"Output of $command");
}

sub collection_gpnptool
{
  my $crshome = shift;
  my $arg = shift;  
  my $outfile = shift;
  my $tmp_file = $outfile."_tmp";
  $command = catfile("$crshome","bin","gpnptool $arg");
  runtimedcommand($command,$outfile,"Output of $command");
  #Security - Remove <ds:Signature ...> ...</ds:Signature>
  if ( -f $outfile ) {
    open(RF,"$outfile");
    open(WF,">$tmp_file");
    while(<RF>) {
      if (/(.*)<ds:Signature\s+.*<\/ds:Signature>(.*)/) {
	print WF $1.$2;
      }
      else {
        print WF;
      }
    } 
    close(RF);
    close(WF);
    copy($tmp_file,$outfile);
    unlink $tmp_file;
    
  }
}

#Maximum transmission unit
sub collection_mtu
{
  my $mtu = 576;  
  my $line;
  $command = $IFCONFIG;
  foreach $line (split /\n/ , `$command`) {
    if ( $line =~ /.*\sMTU:(\d+).*/ ) {
      $mtu = $1;
      last;
    }
  }
  return $mtu;
}

sub collection_ip_address
{
  my $crshome = shift;
  my %ips = ();
  my $public_if;
  my $priv_if;
  my $interface;
  my $if_type; 

  #Get public/private interface names
  $command = catfile("$crshome","bin","oifcfg getif");
  foreach my $line (split /\n/,`$command`) {
    chomp($line);
    if ( $line =~ /PRIF-/) { # crs was not up use crsconfig_params {
       my $cfgparams = catfile("$crshome","crs","install","crsconfig_params");
       #print "Using $cfgparams to get Interface Information due to CRS down\n";
       open (IF,"$cfgparams");
       while (<IF>)
       {
          if ($_ =~ s/NETWORKS=//)
          {
             foreach my $ifaceline (split (/,/, $_))
             {
                if ( $ifaceline =~ /\"(.*)\"\/.*\:(.*)/ ) {
                   $interface = $1;
                   $if_type = $2;
                   #print "interface $interface type $if_type \n";
                }
             }
          }
       }
       close(IF);
       last; 
    } else {
       #output look like eth0  10.214.104.0  global  public
       if ( $line =~ /([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+([^\s]+)/ ) {
         $interface = $1;
         $if_type = $4;
       }
    }
  }
  $public_if = $interface if ( $if_type =~ /public/ && !invalid_chars($interface) );
  $priv_if = $interface if ( $if_type =~ /cluster_interconnect/ && !invalid_chars($interface) );
  #Get public/private Ip's
  if ($public_if) {
    $command="$IFCONFIG $public_if";
    foreach my $line ( split /\n/,`$command` ) {
      if ( $line =~ /inet addr:(\d+\.\d+.\d+.\d+)/ || $line =~ /inet\s*(\d+\.\d+.\d+.\d+)/ ) {
        $ips{PUBLIC_IP} = $1;
      }
    }
  }
  if ($priv_if) {
    $command="$IFCONFIG $priv_if";
    foreach my $line ( split /\n/,`$command` ) {
      if ( $line =~ /inet addr:(\d+\.\d+.\d+.\d+)/ || $line =~ /inet\s*(\d+\.\d+.\d+.\d+)/ ) {
        $ips{PRIVATE_IP} = $1;
      }
    }
  }
  return %ips;
}

sub collection_vips
{
  my $crshome = shift;
  my %vips = ();
  my $vip_name = "";
  $command = catfile("$crshome","bin","srvctl config nodeapps");
  #Note that observed 2 kinds of output for this command
  foreach my $row (split /\n/,`$command`) {
    if ( $row =~ /PRCR-/ || $row =~ /CRS-/ ) { # srvctl failed read crsconfig_params
       my $cfgparams = catfile("$crshome","crs","install","crsconfig_params");
       #print "Using $cfgparams to get VIP Information due to CRS down\n";
       open (IF,"$cfgparams");
       while (<IF>) {
          if ($_ =~ s/CRS_NODEVIPS=//) {
             $_ =~ s/[\"\']//g;
             foreach my $vipline (split (/,/, $_)) {
                if ( $vipline =~ /(.*?)\/.*/ ) {
                   if ( !invalid_chars($vipline) && length($1) ) {
                      $vip_name = $1;
                      my $com = "$NSLOOKUP $1";
                      #print "Running : $com\n";
                      my $next = 0;
		      foreach my $nsrow (split /\n/,`$com`) {
                         if ($nsrow =~ /Name/) {
                            $next = 1;
                         }
                         if ($nsrow =~ /Address/ && $next == 1)  {
                             $nsrow =~ s/.*\://;
                             chomp($nsrow);
                             #print "VIP $vip_name ADDR $nsrow \n";
                             $vips{$vip_name} = $nsrow;
                             $next = 0;
                         }
                      }
                   }
                }
             }
          }
       }
       close(IF);
       last;
    } else {
       if ( $row =~ /VIP Name:\s*([^\s]+)/ ) {
         $vip_name = $1;
       }
       elsif ( $row =~ /VIP IPv\d+ Address:\s*([^\s]+)/ ) {
         $vips{$vip_name} = $1 if $vip_name ne "";
       }
    }
  }
  if ( !keys(%vips) ) {
    foreach my $row (split /\n/,`$command`) {
    #key is vip name and vlaue is vip address
    if ( $row =~ /VIP exists:\s+\/([^\/]+)\/([^\/]+)\/.*/ ) {
        $vips{$1}=$2;
      }
    }
  } 
  return %vips;
}

sub collection_ping
{
  my $args = shift;
  my $outfile = shift;
  $command = "$PING $args";
  runtimedcommand($command,$outfile,"Output of $command");
}

sub collection_rds_info
{
  my $args = shift;
  my $outfile = shift;
  $command = "$RDS_INFO $args";
  runtimedcommand($command,$outfile,"Output of $command");
}

sub collection_nodes_list
{
  my $crshome = shift;
  my $output;
  my @nodes;
  $command = catfile("$crshome","bin","olsnodes");
  $output = `$command`;
  if ( $output !~ /PRCO-/ ) {
    foreach my $node (split /\n/,$output) {
      chomp($node);
      push @nodes,$node;
    }
  }
  else {
    #When crs is down
    $command = catfile("$crshome","bin","tfactl print hosts");
    foreach my $node (split /\n/,`$command`) {
      if ( $node =~ /Host Name : (.*)/ ) {
        push @nodes,$1;
      }
    }
  } 
  return @nodes;
}

#Engineered systems related functions
sub isExadata
{
  my $CELLIPFILE = catfile("","etc","oracle","cell","network-config","cellip.ora");
  my $FLAG = 0;
  if ( -f "$CELLIPFILE" ) {
    $FLAG = 1;
  }
  return $FLAG;
}

sub collection_ib_cmd
{
  my $cmd = shift;
  my $outfile = shift;
  my $sudo = shift;
  $command = cmdlocation_get($cmd);
  $command = $sudo ." ".$command if ( $sudo );
  runtimedcommand($command,$outfile,"Output of $command");
}


#######################
#NAME
#    runtimedcommand
#DESCRIPTION
#    Run a command and have a timeout
#PARAMETERS
#	command,output file etc
#RETURNS
#	None
#######################
sub runtimedcommand  
{
  my $command = shift;
  my $outfile = shift;
  my $header = shift;
  my $timeout = shift;
  my $cmdout;

  if ( !$timeout ) {
    $timeout = 10;
  }
  open(WF,">>$outfile");
  print WF "#HEADER:$header\n";
  eval {
    local $SIG{ALRM} = sub { die "Timeout\n" };
    alarm $timeout;
    $cmdout = `$command`;
    print WF "$cmdout\n";
    alarm 0;
  };
  close(WF);
  if ($@) {
    print localtime(time) . ": $command timed out.\n";
      return(99);
  } 
  elsif ($? != 0) {
    print localtime(time) . ": $command failed.\n" ;
    return(1);
  } 
  else {
    print localtime(time) . ": $command success.\n" ;
    return(0);
  }
}

###########
# Name: invalid_chars
#
# Descriptions.
# Checks for $;&` in a string that we might want t use to execute an os command
#
# parameters
# instring - String to check
# 
# returns TRUe if any of the chanracters are found
#
sub invalid_chars {

  my $instring = shift ;
  if ( $instring =~ /[\$\;\&\`\(\)]/ ) {
     return 1;
  } else {
     return 0;
  }
}
1;
