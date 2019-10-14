#!/usr/local/bin/perl
# 
# $Header: tfa/src/v2/tfa_home/resources/scripts/omsdiag_nodump.pl /main/1 2018/08/15 16:55:52 bburton Exp $
#
# omsdiag_nodump.pl
# 
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      omsdiag_nodump.pl
#
#    DESCRIPTION
#      Extracted from Doc ID 2379199.1
#
#    NOTES
#      Being called by emomshungcpu SRDC collection
#
#    MODIFIED   (MM/DD/YY)
#    xiaodowu    07/13/18 - Being called by emomshungcpu SRDC collection
#    xiaodowu    07/13/18 - Creation
# 
#

my($uptime);
my($cputime);
my($cmd);
my(%time);
my(%timediff);
my($maxlwp) = 5;
my($pid) = $ARGV[0];
my($interval) = $ARGV[1];
my($jhome) = $JAVA_HOME;
my($threshold) = 25;

if ($#ARGV != 1) {
    print "usage: omsdiag pid interval\n";
    print "example: omsdiag 1234 10\n";
    exit;
}

open(PS_PIPE, "/bin/ps --no-header -o etime,bsdtime,cmd -p " . $pid . " |");
   while (<PS_PIPE>) {
      chomp;
      @psField = split(' ');
      $uptime = shift @psField;
      $cputime = shift @psField;
      $jhome = @psField[0];
      $jhome =~ s/java(?!.*java)//;
      $cmd = join(" ", @psField);
   }
close(PS_PIPE);
printf "Processing pid=%s\n", $pid;
printf "Cmdline=%s\n", $cmd;
printf "Up time=%s, CPU time=%s\n", $uptime, $cputime;

open(PS_PIPE,"/bin/ps -L -o lwp,bsdtime -p " . $pid . " |");  
   $i=0;  
   while (<PS_PIPE>) {  
      chomp;
      @psField = split(' ');
      $lwpid = $psField[0];
      ($min,$sec) = split(/:/,$psField[1]);  
      $time{$lwpid} = $min * 60 + $sec;  
      #printf "LWP=%u, TIME=%u\n", $lwpid, $time{$lwpid};
      $i++;  
   }  
close(PS_PIPE);  

sleep($interval);

open(PS_PIPE,"/bin/ps -L -o lwp,bsdtime -p " . $pid . " |");  
   $i=0;  
   while (<PS_PIPE>) {  
      chomp;  
      @psField = split(' ');  
      $lwpid = $psField[0];  
      ($min,$sec) = split(/:/,$psField[1]);  
      $timediff{$lwpid} = ($min * 60 + $sec) - $time{$lwpid};  
      $i++;  
   }  
close(PS_PIPE);  

$i = 0;
printf "\nTop %u threads consuming most CPU time since process start\n", $maxlwp;
foreach $lwpid (sort {$time{$b} <=> $time{$a}} keys %time){
    if ($lwpid != "0" && $time{$lwpid} != "0" && $i < $maxlwp) {
        printf "LWP=%u decimal, %x hex, TOTAL TIME=%u seconds\n", $lwpid, $lwpid, $time{$lwpid};
        $i++
    }
}

$i = 0;
printf "\nTop %u threads consuming most CPU time in the last %u seconds\n", $maxlwp, $interval;
foreach $lwpid (sort {$timediff{$b} <=> $timediff{$a}} keys %timediff){
    if ($lwpid != "0" && $timediff{$lwpid} != "0" && $i < $maxlwp) {
        printf "LWP=%u decimal, %x hex, TIME=%u seconds\n", $lwpid, $lwpid, $timediff{$lwpid};
        $i++
    }
}

my($cmdline) = $jhome . "jstack" . " -l " . $pid;
open(JS_PIPE, $cmdline . " |");  
@threaddump=<JS_PIPE>;

printf " ====== Complete Thread Dump ====== \n";
printf "@threaddump \n";

