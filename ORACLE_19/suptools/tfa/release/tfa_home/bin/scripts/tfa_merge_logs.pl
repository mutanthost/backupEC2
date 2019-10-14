# 
# $Header: tfa/src/v2/tfa_home/bin/scripts/tfa_merge_logs.pl /main/4 2017/08/11 05:02:21 llakkana Exp $
#
# tfa_merge_logs.pl
# 
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfa_merge_logs.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     12/16/16 - remove references to tmp
#    gadiga      01/18/16 - merge logs
#    gadiga      01/18/16 - Creation
# 

%all_ts = ();

my $fh;

if ( -z $ARGV[0] )
{
  print "Atleast one file is expected as i/p.\n";
  exit;
}
 else
{
    print "";
}

%log_types = ();
$from = "";
$to = "";
my $has_dc = 0;
$osmsgfile = 0;
@osmsgfiles = ();
$day_s = "ddd ";
$old_t = "";
$site = 0;

$vpat = "";

$date_now = `date '+\%Y\%m\%d\%H\%M\%S'`;
chomp($date_now);
$date_now .= "000000";

$i = 0;

$dump_ftype = 0;
$flist = "";
$hash = "";
$write_offset = 0;

$write_matched = 0;

$ptype = "normal";

@s = grep(/-site/,@ARGV);
if ( $s[0] eq "-site" )
{
 $site = 1;
}
$parse = 0;

%toffset = ();

$has_mls = 0;
$has_mrs = 0;
$printlno = 0;
my $tfa_base = "";

foreach $afile (@ARGV)
{
  $i++;
  if ( $afile eq "-from" )
  {
    $from = $ARGV[$i];
    #shift(@ARGV);
    if ( $ARGV[$i+1] =~ /\d+:\d+/ )
    {
      $from .= "$ARGV[$i] $ARGV[$i+1]";
      shift(@ARGV);
    }
    shift(@ARGV);
  }
  elsif ( $afile eq "-tfabase" )
  {
    $tfa_base = $ARGV[$i];
    shift(@ARGV);
    system("mkdir -p $tfa_base/tfaweb/ >/dev/null 2>&1") if ( ! -d "$tfa_base/tfaweb/" );
  }
  elsif ( $afile eq "-flist" )
  {
    $flist = $ARGV[$i];
    shift(@ARGV);
  }
  elsif ( $afile eq "-hash" )
  {
    $hash = $ARGV[$i];
    shift(@ARGV);
  }
  elsif ( $afile eq "-vpat" )
  {
     $vpat = $ARGV[$i];
     shift(@ARGV);
  } 
  elsif ( $afile eq "-readn" )
  {
    $write_offset = 1;
  }
  elsif ( $afile eq "-parse" )
  {
    $parse = 1;
  }
  elsif ( $afile eq "-dump" )
  {
    $dump_ftype = 1;
  }
  elsif ( $afile eq "-f" )
  {
    #shift(@ARGV);
    print "";
  }
  elsif ( $afile eq "-site" )
  {
    $day_s = "";
    $site = 1;
  }
  elsif ( $afile eq "-wmatched" )
  {
    $write_matched = 1;
  }
  elsif ( $afile eq "-printlno" )
  {
    $printlno = 1;
  }
  elsif ( $afile eq "-worker" )
  {
    $day_s = "";
    $ptype = "worker";
    $from = "99999999999999";
  }
  elsif ( $afile eq "-master" )
  {
    $day_s = "";
    $ptype = "master";
  }
   elsif ( $afile eq "-to" )
  {
    $to = $ARGV[$i];
    shift(@ARGV);
  }
   elsif ( $afile =~ /^\d+$/ )
  {
    $ignored = 1;
  }
   elsif ( $afile =~ /(.*)\#([\-\d]+:\d+:\d+)$/ )
  {
    $afile = $1;
    $oset = $2;
    push_file (); 
    $toffset{$afile} = $oset;
  }
   elsif ( -r "$afile" )
  {
    push_file ();
    if ( $ARGV[$i] =~ /[\-\d]+:\d+:\d+$/ )
    {
      $toffset{$afile} = $ARGV[$i];
      shift(@ARGV);
    }
  }
   else
  {
    print  "Could not read file $afile.. Skipping\n";
    next;
  }
}

read_flist() if ( $flist );

if ( $dump_ftype == 1 )
{
  $first_file = 1;
  foreach $afile (@afiles)
  {
    $log_type = $log_types{$afile};
    save_ftype ();
  }
  $dbh->commit;
  exit;
}

#comment
$saved_from = $from;

if ( $site == 1 && $from && $from =~ /(\d\d)\/(\d\d)\/(\d\d\d\d) (\d\d):(\d\d)$/ )
{ # from site it will be like mm/dd/yyyy hh24:mi
  $from = "$3$1$2$4$5"."00";
}
elsif ( $site == 1 && $from && $from =~ /(\d\d)\/(\d\d)\/(\d\d\d\d) (\d\d):(\d\d):(\d\d)/ )
{
  $from = "$3$1$2$4$5$6";
}
elsif ( $site == 1 && $from && $from =~ /(\d\d\d\d)-(\d\d)-(\d+) (\d\d):(\d\d):(\d\d)/ )
{
  $from = "$1$2$3$4$5$6";
}
elsif ( $site == 1 && $from && $from =~ /(\d\d)-(\w+)-(\d+) (\d\d):(\d\d):(\d\d)/ )
{
  $mn = get_mon_number($2);
  $from = "$3$mn$1$4$5$6";
}
elsif ( $site == 1 && $from && $from =~ /(\w+) (\d+) (\d+):(\d+):(\d+) (\d+)/ )
{
  $mn = get_mon_number($1);
  $from = "$6$mn$2$3$4$5";
}

#kumar 20130531: why we are adding 000000 ? .. seems to be a problem in case fof jump time
$from4jt = $from;
$from = $from . "000000" if ( $from );
$to = $to . "000000" if ( $to );

#print "$from to $to\n";
if ( $write_offset == 1 )
{
  # Write offset and exit
  $ofile = "$tfa_base/tfaweb/merged_".$hash.".log";
  getoffset ();
  exit;
}

#Get file details
%file_info = ();
if ( $site != 1 ) {
 %file_info = scan_file4details(@afiles);
 find_similar_files();
}
#print_file_info();

if ( $osmsgfile == 1 )
{
  open_all_files();
  $ignore_msg = 1;
  read_next_ts();
  $ignore_msg = 0;
  if ( $yr )
  {
    foreach $afile (@osmsgfiles)
    {
      $osmsg_year{$afile} = $yr;
      #print "Year for message file $afile is $yr\n";
    }
  }
  close_all_files();
}

if ( $outf)
{
  open($fh, ">$outf") || die "Can'topen $outf for writing\n";
  select $fh;
}
process_alerts();
close($fh) if ( $outf );

write_oldt_to_file(1) if ( $hash );

system("touch $tfa_base/tfaweb/merged_".$hash.".completed") if ( $hash );

#--main ends
##############################################################################
sub check_crs 
{
  $file_name = shift;
  $counter = 0;
  return 1 if ( $file_name =~ /\.trc/ );
  open (RF,"$file_name");
  while (<RF>) {
    $counter++;
    if ( /^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)\./ ) {
      return 1;
    }
     elsif ( /^zzz.*\w\w\w (\w\w\w) (\d\d) (\d\d):(\d\d):(\d\d) \w+ (\d\d\d\d)/ )
    {
      return 1;
    }
    return 0 if ( $counter == 100 );
  }
  close(RF);
  return 0;
}
##############################################################################
sub find_similar_files 
{
  foreach my $key ( sort { $a eq $b } keys %file_info ) {
    @{$file_info{$key}->{DFILE}} = ();
    foreach my $key1 ( sort { $a eq $b } keys %file_info ) {
     next if $key eq $key1;
     if ( $file_info{$key}->{HNAME}  eq $file_info{$key1}->{HNAME}  &&
          $file_info{$key}->{DBNAME} eq $file_info{$key1}->{DBNAME} &&
          $file_info{$key}->{SID}    eq $file_info{$key1}->{SID}    && 
          $file_info{$key}->{ATYPE}  eq $file_info{$key1}->{ATYPE}  ) {
        push(@{$file_info{$key}->{DFILE}}, $key1);         
     }
    }
  }
}

##############################################################################
sub print_file_info 
{
  printf "%-35s %-16s %-16s %-16s %-5s %-20s\n", "File", "Host", "DB", "SID", "ALERT", "DFILE";
  print "-"x113 . "\n";
  foreach my $key ( sort { $a cmp $b } keys %file_info ) {
    printf "%-35s %-16s %-16s %-16s %-5s %-20s %-20s\n", $key, $file_info{$key}->{HNAME}, $file_info{$key}->{DBNAME},$file_info{$key}->{SID},$file_info{$key}->{ATYPE}, @{$file_info{$key}->{DFILE}};
  }
  print "-"x113 . "\n";
}

##############################################################################

sub process_alerts
{
  $print_cnt = 0;
  %contents = ();
  %line_wo_ts = (); #line after exctracting timestamp from it;
  %c_lno = ();

  print "Merged files\n----------------------------------------------\n" if ( $site != 1 );
  foreach $afile (@afiles)
  {
    open($afile, "$afile") || die "Can't open $afile\n";
    $contents{$afile}->{PRINTED} = 1; # Printed
    $contents{$afile}->{TSG} = "s"; # Minimum timestamp granularity s/mis/mrs
    $contents{$afile}->{CTS} = ""; # Current time stamp
    $contents{$afile}->{NCTS} = ""; # Timestamp where we stopped reading
    $contents{$afile}->{HASMORE} = 1; # morelines exists
    @{$contents{$afile}->{LINES}} = (); # Lines
    $c_lno{$afile} = 0;
    if ( $afile =~ /\/racassurance\/TFAV2\/prod\/files\/.*\/tfa_home\/files\/(.*)/ ) {
      print "$1\n" if ( $site != 1 );
    }
    else {
      print "$afile\n" if ( $site != 1 );
    }
  }
  print "----------------------------------------------\n\n" if ( $site != 1 );

  $done = 0;
  while($done == 0)
  {
    read_next_ts();
    print_min_ts_contents();
    $print_cnt++;
  }

  close_all_files();
}
##############################################################################
sub open_all_files
{
  foreach $afile (@afiles)
  {
    open($afile, "$afile") || die "Can't open $afile\n";
    $contents{$afile}->{PRINTED} = 1; # Printed
    $contents{$afile}->{CTS} = ""; # Current time stamp
    $contents{$afile}->{NCTS} = ""; # Timestamp where we stopped reading
    $contents{$afile}->{HASMORE} = 1; # morelines exists
    @{$contents{$afile}->{LINES}} = (); # Lines
  }
}
##############################################################################
sub close_all_files
{
  foreach $afile (@afiles)
  {
    close($afile);
  }
}
##############################################################################
sub has_duplicate_content 
{
 my $file1 = $_[0];
 my $file2 = $_[1];
 my $flag = $_[2];
 my $count = -1;
 my $ret_val;
 foreach my $i (@{$file_info{$file1}->{DFILE}}) {
   #Return 0 if file2 is not eq to any of the element of array
   if ( $i eq $file2 ) {
     $file1 = $i;
     last;
   }
   $count++ if $i ne $file2;
 }
 if ( $count == $#{$file_info{$file1}->{DFILE}} ) {
   return 0 if $flag == 0;
   $count = -1;
   #That is file2 is not of type file1. In this case, compare file2 with files of @to_print and of type file2
   foreach my $file (@to_print) {
     $ret_val = has_duplicate_content($file2,$file,0);
     return 1 if $ret_val == 1;
     $count++;
   }
   return 0 if $count == $#to_print; 
 }
 #Here we have to check content of these files line by line for this time stamp
 if ( $#{$contents{$file1}->{LINES}} != $#{$contents{$file2}->{LINES}} ) {
   return 0;
 }
 #Compare line by line
 for (my $i = 0; $i <= $#{$contents{$file1}->{LINES}}; $i++) {
    return 0 if ( ${$contents{$file1}->{LINES}}[$i] ne  ${$contents{$file2}->{LINES}}[$i] );  
 }
 return 1;
}
##############################################################################
# Print the lines from min ts
sub print_min_ts_contents
{
  $min = "";
  $has_dc = 0;
  @to_print = (); # Same TS in multiple files
  $done = 1;
  foreach $afile (@afiles)
  {
    #next if ( $contents{$afile}->{HASMORE} == 0 && $last_l{$afile} eq "" );
    next if ( $contents{$afile}->{HASMORE} == 0 );
    $min = $afile if ( ! $min );
    if ($contents{$afile}->{CTS} < $contents{$min}->{CTS})
    {
      $min = $afile;
      @to_print = ($min); # different min found
    }
     elsif ( $contents{$afile}->{CTS} == $contents{$min}->{CTS} )
    {
      $has_dc = has_duplicate_content($min,$afile,1);
      @to_print = (@to_print, $afile) if $has_dc == 0; # same TS
      if ( $has_dc == 1 ) {
        $contents{$afile}->{PRINTED} = 1;
        @{$contents{$afile}->{LINES}} = (); 
      }
    }

    if ($contents{$afile}->{HASMORE} == 1 )
    {
      $done = 0;
    }
  }

  print_debug("Min ts = $contents{$min}->{CTS} and files are \n");
  print_debug (@to_print);
  print_debug ("\n");

  $in_print_range = 1;
  if ( $from || $to )
  {
    $in_print_range = $after_from = $before_to = 0;
    $after_from = 1 if ( $from && $contents{$min}->{CTS} >= $from ); 
    $before_to = 1 if ( $to && $contents{$min}->{CTS} <= $to ); 
    if ( $from && $to )
    {
      $in_print_range = 1 if ( $after_from == 1 && $before_to == 1 );
    }
     elsif ( $from )
    {
      $in_print_range = 1 if ( $after_from == 1 );
    }
     elsif ( $to )
    {
      $in_print_range = 1 if ( $before_to == 1 );
    }
  }
  $t = format_ts($contents{$min}->{CTS});
  if ( $printlno == 1 )
  {
    print "<time>$day_s$t</time>" if ( $in_print_range == 1 && $t && $old_t ne $t);
  }  
   else
  {
    print "\n$day_s$t\n" if ( $in_print_range == 1 && $t && $old_t ne $t);
  }
  $old_t = $t if ( $t );
  write_oldt_to_file(0) if ( $hash );
  foreach $afile (@to_print)
  {
    if ($log_types{$afile} eq "oswtop-" )
    { # parse the array and print only if necessory
      @{$contents{$afile}->{LINES}} = oswtop("-a","zzz $day_s$t", @{$contents{$afile}->{LINES}} );
    }
    #@d = split(/\//, $afile);
    #If size of the array $contents{$afile}->{LINES} is 0, check for $last_l
    if ( $#{$contents{$afile}->{LINES}} < 0 && $last_l{$afile} ne "" ) {
      push (@{$contents{$afile}->{LINES}},$last_l{$afile});
    }
    foreach $l (@{$contents{$afile}->{LINES}})
    {
      #print "[ $d[$#d] ] : $l" if ( $in_print_range == 1 );
      if ( $site == 1 ) {
        $p_l = $l;
        chomp($p_l);
        #if ( $printlno == 1 )
        #{
        #  if ( $p_l =~ /^(\d+):(.*)$/ )
        #  {
        #    $lno = $2;
        #    $p_l = $2;
        #  }
        #}
        #print " "x10 ."$p_l [ $afile ]\n" if ( $in_print_range == 1 && $p_l );
        if ( $last_pfile ne $afile && $printlno == 0 )
        {
          print "\n";
        }
        $last_pfile = $afile;
         if ( $in_print_range == 1 && $p_l ) {
           if ( $afile =~ /plugin_output\/.*.out/ ) {
	     #Don't print file at the end if it is plugin output
             print "$p_l\n";
	   }
	   else {
             print "$p_l [ $afile ]\n";
	   }  
         }
      }
      else {
        print "[ $afile ] : $l" if ( $in_print_range == 1 );
      }
    }
    $contents{$afile}->{PRINTED} = 1;
    @{$contents{$afile}->{LINES}} = ();
  }
}

sub print_debug
{
#print @_;
  if ( $ENV{DEBUG} && $ENV{DEBUG} == 1)
  {
    print @_;
  }
}

# format yyyymmddhh24miss to readable format
sub format_ts
{
  $it = $_[0];
  if ( $it =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d\d)(\d\d\d)/ ||
       $it =~ /(\d\d\d\d)(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)()()/ )
  {
    $m = get_month($2);
    $ss2 = "";
    if ( $has_mls == 1 )
    {
      $ss2 = ".$7";
    }
    if ( $has_mrs == 1 )
    {
      $ss2 = ".$7$8";
    }
    return "$m $3 $4:$5:$6$ss2 $1";
  }
}

# From all files read till next ts
sub read_next_ts
{

  #$done = 1;
  my $matched_pat = "";

  foreach $afile (@afiles)
  {
#print STDERR "reading $afile\n";
    #Follwong variable  handle the case when last line of file is like..
    #2012-08-01 15:05:43.241: [ OCRDUMP][663850368]Exiting [status=failed]
    $log_type = $log_types{$afile};
    if ($contents{$afile}->{PRINTED} != 0 && $contents{$afile}->{HASMORE} == 1 )
    { # Read only files which are spooled out
      $contents{$afile}->{HASMORE} = 0;
      $contents{$afile}->{CTS} = $contents{$afile}->{NCTS};
      $contents{$afile}->{PRINTED} = 0;
      while(<$afile>)
      {
        $c_lno{$afile}++;
        $c_lno_v = "";
        $c_lno_v = $c_lno{$afile} . ":" if ( $printlno == 1 );

        $last_l{$afile} = "";
        #$done = 0;
        $contents{$afile}->{HASMORE} = 1;
        #$matched_pat = "";
        $line = $_;
        $line =~ s///g;
        #Remove leading spaces ===> Don't do it. Looking for spaces before init params.
        #$line =~ s/^\s+//;  
        next if ( $vpat && $line =~ /$vpat/i );
        if ( $log_type eq "osmsg" && $ignore_msg == 0  &&
                 $line =~ /(\w\w\w)\s+(\d+) (\d\d):(\d\d):(\d\d) (.*)/ )
        { # Every line has timestamp.. no need to read multiple lines
          $mon = get_mon_number($1); 
          $dte = sprintf("%02d",$2);
          $hh24 = $3;
          $mi = $4;
          $ss = $5;
          $miss = "000000";
          $yr = $osmsg_year{$afile};
          $ts = "$yr$mon$dte$hh24$mi$ss$miss";
          $matched_pat = 1 if ( $write_matched == 1 );
          if ( $ts > $date_now )
          {
            $yr--;
            $ts = "$yr$mon$dte$hh24$mi$ss$miss";
          }
          add_offset() if ( defined $toffset{$afile} );
          $contents{$afile}->{NCTS} = $ts;

          @d = split(/\//, $afile);
          #push(@{$contents{$afile}->{LINES}}, "[ $d[$#d] ] : $last_line") if ( defined $last_line );
          push(@{$contents{$afile}->{LINES}}, "$c_lno_v$last_line$matched_pat") if ( defined $last_line );
          $last_line = $line;
          if ( eof($afile) )
          {
            push(@{$contents{$afile}->{LINES}}, "$c_lno_v$last_line$matched_pat") if ( defined $last_line );
          }
          last;
        }
         elsif ( $line =~ /^\[(\d+)-(\w+)-(\d+) (\d\d):(\d\d):(\d\d):\d+\](.*)/ ||
                 $line =~ /^\[\d+ (\d+)-(\w+)-(\d+) (\d\d):(\d\d):(\d\d):\d+\](.*)/ )
        {
          $mon = get_mon_number($2);
          $dte = $1;
          $yr = $3;
          $hh24 = $4;
          $mi = $5;
          $ss = $6;
          $miss = "000000";
          add_offset() if ( defined $toffset{$afile} );
          $ts = "$yr$mon$dte$hh24$mi$ss$miss";
          $matched_pat = 2 if ( $write_matched == 1 );
          $contents{$afile}->{NCTS} = $ts;
          $last_l{$afile} = $line;

          @d = split(/\//, $afile);
          #push(@{$contents{$afile}->{LINES}}, "[ $d[$#d] ] : $last_line") if ( defined $last_line );
          push(@{$contents{$afile}->{LINES}}, "$c_lno_v$last_line$matched_pat") if ( defined $last_line );
          #$last_line = $7;
          $last_line = $line;
          last;
        }
         elsif ( $line =~ /\[(\d+)\/(\d+)\/(\d+) (\d\d):(\d\d):(\d\d)\](.*)/ )
        {
          $mon = $1;
          $dte = $2;
          $yr = $3;
          $hh24 = $4;
          $mi = $5;
          $ss = $6;
          $miss = "000000";
          add_offset() if ( defined $toffset{$afile} );
          $ts = "$yr$mon$dte$hh24$mi$ss$miss";
          $contents{$afile}->{NCTS} = $ts;
          $matched_pat = 3 if ( $write_matched == 1 );

          @d = split(/\//, $afile);
          #push(@{$contents{$afile}->{LINES}}, "[ $d[$#d] ] : $last_line") if ( defined $last_line );
          push(@{$contents{$afile}->{LINES}}, "$c_lno_v$last_line$matched_pat") if ( defined $last_line );
          $last_line = $line;
          last;
        }
         elsif ( $line =~ /^(\d+)-(\w+)-(\d\d) (\d\d):(\d\d) (.*)/ )
        {
          $mon = get_mon_number($2);
          $dte = $1;
          $yr = "20".$3;
          $hh24 = $4;
          $mi = $5;
          $ss = "00";
          $miss = "000000";
          add_offset() if ( defined $toffset{$afile} );
          $ts = "$yr$mon$dte$hh24$mi$ss$miss";
          $contents{$afile}->{NCTS} = $ts;
          $matched_pat = 4 if ( $write_matched == 1 );

          @d = split(/\//, $afile);
          #push(@{$contents{$afile}->{LINES}}, "[ $d[$#d] ] : $last_line") if ( defined $last_line );
          push(@{$contents{$afile}->{LINES}}, "$c_lno_v$last_line$matched_pat") if ( defined $last_line );
          $last_line = $line;
          last;
        }
         elsif ( $line =~ /^(.*)\[ (\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)\.([\d\w\s]+)\] (.*)/ ||                 
                 $line =~ /^(\[[\s\w]+\])(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)\.(\d+) (.*)/ )
        {#[    CSSD]2012-09-22 22:08:02.547  [18] >TRACE:   cl
          $mon = $3;
          $dte = $4;
          $yr = $2;
          $hh24 = $5;
          $mi = $6;
          $ss = $7;
          $miss = $8;
          $matched_pat = 5 if ( $write_matched == 1 );
          $last_line = "$line";
          $miss =~ s/[^\d]//g;
          $contents{$afile}->{TSG} = "mls";
          if ( $miss >= 1000 )
          {
            $contents{$afile}->{TSG} = "mrs";
            $has_mrs = 1;
          }
           else
          {
            $miss = "${miss}000";
            $has_mls = 1;
          }
          add_offset() if ( defined $toffset{$afile} );
          $ts = "$yr$mon$dte$hh24$mi$ss$miss";
          $contents{$afile}->{NCTS} = $ts;

          @d = split(/\//, $afile);
          #push(@{$contents{$afile}->{LINES}}, "[ $d[$#d] ] : $last_line") if ( defined $last_line );
          push(@{$contents{$afile}->{LINES}}, "$c_lno_v$last_line$matched_pat") if ( defined $last_line );
          last;
        }
        elsif ( $line =~ /^([^\s\[]*)\s*\W*(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)[\.\d]*[-+]\d\d:\d\d\W*\s+(.*)/               || $line =~ /^\s*(.*)\s*(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)[\.\d]*[-+]\d\d:\d\d\W*\s+(.*)/) {
          #sundiag output files
	  #Ex:2012-10-03T17:25:51.000+00:00
	  #This part works only if each line of has time stamp
	  add_offset() if ( defined $toffset{$afile} );
          $ts = "$2$3$4$5$6$7";
          $contents{$afile}->{NCTS} = $ts;
          $contents{$afile}->{CTS} = $ts;
	  $first_part = $1;
          $last_part = $8;
          $matched_pat = 6 if ( $write_matched == 1 );
          $last_part =~ s/\s+/ /g; #Replae morethan one space with one space
          $last_line = "$line";
          push(@{$contents{$afile}->{LINES}}, "$c_lno_v$last_line$matched_pat");
          last;  
        }
        elsif (  $line =~ /^(\d\d)\/(\d\d)\/(\d\d\d\d) (\d\d):(\d\d):(\d\d)\s+(.*)/ ||
                 $line =~ /(\d\d)\/(\d\d)\/(\d\d\d\d) \| (\d\d):(\d\d):(\d\d)\s+\|(.*)/ ) {
	  #sundiag output files
    	  #Ex:09/25/2012 01:32:44  (Command Tool)(Debug) /ClearCaseBuild/UNIV_VIVA_Cli/CpMgmt/CmdPro..
          add_offset() if ( defined $toffset{$afile} );
	  $ts = "$3$1$2$4$5$6";
	  $contents{$afile}->{NCTS} = $ts;
          $contents{$afile}->{CTS} = $ts;
	  $last_line = $line; 
          $matched_pat = 7 if ( $write_matched == 1 );
          push(@{$contents{$afile}->{LINES}}, "$c_lno_v$last_line$matched_pat");
	  last;
        } 
	elsif (  $line =~ /^(\d\d)\/(\d\d)\/(\d\d) (\d\d):(\d\d):(\d\d):\s+(.*)/ ) {
          #sundiag output files
          #Ex:09/25/2012 01:32:44  (Command Tool)(Debug) /ClearCaseBuild/UNIV_VIVA_Cli/CpMgmt/CmdPro..
          add_offset() if ( defined $toffset{$afile} );
          $ts = "20"."$3$1$2$4$5$6";
          $matched_pat = 8 if ( $write_matched == 1 );
          $contents{$afile}->{NCTS} = $ts;
          $contents{$afile}->{CTS} = $ts;
          $last_line = $line;
          push(@{$contents{$afile}->{LINES}}, "$c_lno_v$last_line$matched_pat");
          last;
        }
         elsif (  $line =~ /^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)\s+(.*)/ ) {
	  #2012-10-18 20:39:07  WARNING OGG-01834...
          add_offset() if ( defined $toffset{$afile} );
          $ts = "$1$2$3$4$5$6";
          $matched_pat = 9 if ( $write_matched == 1 );
          $contents{$afile}->{NCTS} = $ts;
          $contents{$afile}->{CTS} = $ts;
          $last_line = $line;
          push(@{$contents{$afile}->{LINES}}, "$c_lno_v$last_line$matched_pat");
          last;
        }

        $writeLine = 1;

        if ( $line =~ /^\w\w\w (\w\w\w)\s+(\d+) (\d\d):(\d\d):(\d\d)\s+(\d\d\d\d)/ || 
             $line =~ /^\w\w\w (\w\w\w) (\d\d) (\d\d):(\d\d):(\d\d) \w+ (\d\d\d\d)$/ ||
	     $line =~ /(\w\w\w)\s+(\d+) (\d\d):(\d\d):(\d\d) (\d\d\d\d)/ )
        { # database alert
          $mon = get_mon_number($1);
          $dte = sprintf("%02d",$2);
          $hh24 = $3;
          $mi = $4;
          $ss = $5;
          $yr = $6;
          $miss = "000000";
          add_offset() if ( defined $toffset{$afile} );
          $ts = "$yr$mon$dte$hh24$mi$ss$miss";
          $matched_pat = 10 if ( $write_matched == 1 );
          $contents{$afile}->{NCTS} = $ts;
          $writeLine = 0;
          push(@{$contents{$afile}->{LINES}}, "$c_lno_v$line$matched_pat");
          last;     
        }
        elsif (  $line =~ /^(.*): \w\w\w (\w\w\w)\s+(\d+) (\d\d):(\d\d):(\d\d) (\d\d\d\d)(:.*)/ )
        {
          $mon = get_mon_number($2);
          $dte = sprintf("%02d",$3);
          $hh24 = $4;
          $mi = $5; 
          $ss = $6;
          $yr = $7;
          $rline = "$1$8";
          $miss = "000000";
          add_offset() if ( defined $toffset{$afile} );
          $ts = "$yr$mon$dte$hh24$mi$ss$miss";
          $matched_pat = 11 if ( $write_matched == 1 );
          $contents{$afile}->{NCTS} = $ts;
          #$line = $rline."\n";
          push(@{$contents{$afile}->{LINES}}, "$c_lno_v$pre_line$matched_pat");
          $pre_line = "$c_lno_v$line";
          last;
        }
        elsif (  $line =~ /^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)\.([\d\s]+): (.*)/ ||
                 $line =~ /^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d):() (.*)/ ||
                 $line =~ /^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d),(\d+) (.*)/ )
        { # CRS Alert
          $yr = $1;
          $mon = $2;
          $dte = $3;
          $hh24 = $4;
          $mi = $5;
          $ss = $6;
          $miss = $7;
          $rline = $8;
          $miss =~ s/[^\d]//g;
          $contents{$afile}->{TSG} = "mls";
          if ( $miss >= 1000 )
          {
            $contents{$afile}->{TSG} = "mrs";
            $has_mrs = 1;
          }
           else
          {
            $miss = "${miss}000";
            $has_mls = 1;
          }
          add_offset() if ( defined $toffset{$afile} );
          $matched_pat = 12 if ( $write_matched == 1 );
          $ts = "$yr$mon$dte$hh24$mi$ss$miss";
          $contents{$afile}->{NCTS} = $ts;
          #$line = $rline."\n";
          push(@{$contents{$afile}->{LINES}}, "$pre_line$matched_pat");
          $pre_line = "$c_lno_v$line";
  	  $last_l{$afile} = $line;
          last;
        } 
         elsif (  $line =~ /^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)\.(\d+)(.*)/ ||
                  $line =~ /^\W\W\W\s+(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)\.(\d+)(.*)/ )
        { # CRS Alert
          $yr = $1;
          $mon = $2;
          $dte = $3;
          $hh24 = $4;
          $mi = $5;
          $ss = $6;
          $miss = $7;
          $miss =~ s/[^\d]//g;
          $rline = $8;
          $contents{$afile}->{TSG} = "mls";
          if ( $miss >= 1000 )
          {
            $contents{$afile}->{TSG} = "mrs";
            $has_mrs = 1;
          }
           else
          {
            $miss = "${miss}000";
            $has_mls = 1;
          }
          add_offset() if ( defined $toffset{$afile} );
          $matched_pat = 13 if ( $write_matched == 1 );
          $ts = "$yr$mon$dte$hh24$mi$ss$miss";
          $contents{$afile}->{NCTS} = $ts;
          #if ( ! $line )
          #{
          #  $writeLine = 0;
          #}
          # else
          #{
            push(@{$contents{$afile}->{LINES}}, "$c_lno_v$pre_line$matched_pat");
            $pre_line = "$c_lno_v$line$matched_pat";
          #}
          last;
        }
         elsif (  $line =~ /^zzz.*\w\w\w (\w\w\w) (\d+) (\d+):(\d+):(\d+) \w+ (\d\d\d\d)/ )
        { # oswtop
          $mon = get_mon_number($1);
          $dte = sprintf("%02d",$2);
          $hh24 = $3;
          $mi = $4;
          $ss = $5;
          $yr = $6;
          $miss = "000000";;
          add_offset() if ( defined $toffset{$afile} );
          $ts = "$yr$mon$dte$hh24$mi$ss$miss";
          $matched_pat = 14 if ( $write_matched == 1 );
          $contents{$afile}->{NCTS} = $ts;
	  $writeLine = 0;
          push(@{$contents{$afile}->{LINES}}, "$c_lno_v$line");
          last;
        }
         elsif (  $line =~ /^zzz.*\w\w\w (\d+) (\w+) (\d\d):(\d\d):(\d\d) (\d\d\d\d)/ )
        { # oswtop
          $mon = get_mon_number($2);
          $dte = $1;
          $hh24 = $3;
          $mi = $4;
          $ss = $5;
          $yr = $6;
          $miss = "000000";
          add_offset() if ( defined $toffset{$afile} );
          $ts = "$yr$mon$dte$hh24$mi$ss$miss";
          $matched_pat = 15 if ( $write_matched == 1 );
          $contents{$afile}->{NCTS} = $ts;
          $writeLine = 0;
          push(@{$contents{$afile}->{LINES}}, "$c_lno_v$line");
          last; 
        }
         elsif (  $line =~ /^Node:.*Clock:\s+\'(\d+)-(\d+)-(\d+) (\d+)\.(\d+)\.(\d+)([\s\'])/ )
        { # chmos
          if ( $7 eq " " )
          {
            $yr = 2000 + $1;
            $mon = $2;
            $dte = $3;
          }
          $hh24 = $4;
          $mi = $5;
          $ss = $6;
          $miss = "000000"; 
          add_offset() if ( defined $toffset{$afile} );
          $ts = "$yr$mon$dte$hh24$mi$ss$miss";
          $matched_pat = 22 if ( $write_matched == 1 );
          $contents{$afile}->{NCTS} = $ts;
          $writeLine = 0;
          push(@{$contents{$afile}->{LINES}}, "$c_lno_v$line");
          last;
        }
         elsif (  $line =~ /^(\d\d)-(\w+)-(\d\d\d\d) (\d\d):(\d\d):(\d\d) (.*)/ )
        { # listener log 08-APR-2014 08:01:04 * (CONNECT_DATA=(SERVER=D
          $mon = get_mon_number($2);
          $dte = $1;
          $hh24 = $4;
          $mi = $5;
          $ss = $6;
          $yr = $3;
          $miss = "000000";
          add_offset() if ( defined $toffset{$afile} );
          $ts = "$yr$mon$dte$hh24$mi$ss$miss";
          $matched_pat = 17 if ( $write_matched == 1 );
          $contents{$afile}->{NCTS} = $ts;
          $writeLine = 0;
          push(@{$contents{$afile}->{LINES}}, "$c_lno_v$line");
          last; 
        }
         elsif (  $line =~ /^(\d\d)\/(\d\d)\/(\d\d\d\d) (\d\d):(\d\d):(\d\d)$/ )
        { # 08/30/2012 15:43:01
          $mon = $1;
          $dte = $2;
          $hh24 = $4;
          $mi = $5;
          $ss = $6;
          $yr = $3;
          $miss = "000000";
          add_offset() if ( defined $toffset{$afile} );
          $matched_pat = 16 if ( $write_matched == 1 );
          $ts = "$yr$mon$dte$hh24$mi$ss$miss";
          $contents{$afile}->{NCTS} = $ts;
          $writeLine = 0;
          last;
        }
         elsif ( $pre_line )
        {
          push(@{$contents{$afile}->{LINES}}, "$pre_line$matched_pat");
          $pre_line = "";
        }

        if ( $writeLine == 1 ) {
          push(@{$contents{$afile}->{LINES}}, "$c_lno_v$line$matched_pat");
        }
      } #End of while
    }
     else
    {
      #$done = 0 if ( $contents{$afile}->{PRINTED} == 0 );
      print_debug("$afile not printed\n");
    }
  }#End of for
}

sub get_mon_number
{
  $mon = uc($_[0]);
  return "01" if ( $mon eq "JAN");
  return "02" if ( $mon eq "FEB");
  return "03" if ( $mon eq "MAR");
  return "04" if ( $mon eq "APR");
  return "05" if ( $mon eq "MAY");
  return "06" if ( $mon eq "JUN");
  return "07" if ( $mon eq "JUL");
  return "08" if ( $mon eq "AUG");
  return "09" if ( $mon eq "SEP");
  return "10" if ( $mon eq "OCT");
  return "11" if ( $mon eq "NOV");
  return "12" if ( $mon eq "DEC");
}


sub get_month
{
  $mon = $_[0];
  return "Jan" if ( $mon == 1 );
  return "Feb" if ( $mon == 2 );
  return "Mar" if ( $mon == 3 );
  return "Apr" if ( $mon == 4 );
  return "May" if ( $mon == 5 );
  return "Jun" if ( $mon == 6 );
  return "Jul" if ( $mon == 7 );
  return "Aug" if ( $mon == 8 );
  return "Sep" if ( $mon == 9 );
  return "Oct" if ( $mon == 10 );
  return "Nov" if ( $mon == 11 );
  return "Dec" if ( $mon == 12 );
}

sub parse_path_for_sr
{
  $sr = "";
}

sub push_file
{
    $log_type = "unknown";
    $log_type = "osmsg" if ( $afile =~ /messages/ );
    $log_type = "crsalert" if ( $afile =~ /alert/ );
    $log_type = "dbalert" if ( $afile =~ /alert_/ );
    #$log_type = "oswtop" if ( $afile =~ /_top_[\d\.]+\.dat/ );
    $log_type = "osw$1" if ( $afile =~ /_([a-z]+)_[\d\.]+\.dat/ );
    $log_type = "trc" if ( $afile  =~ /\.trc/ );
    $log_type = "crsalert" if ( $log_type eq "unknown" && check_crs($afile) );
    $log_type = "oracle" if ( $log_type eq "unknown" );

    if ( $log_type eq "unknown" )
    {
      print "Could not determine log type. Skipping file $afile\n";
      next;
    }

      if ( $log_type eq "osmsg" && $afile =~ /messages[\.\w]*-(\d\d\d\d)/ )
      { # Format should be messages...-\d\d\d\d for year
        $osmsg_year{$afile} = $1;
      }
       elsif ( $log_type eq "osmsg" )
      {
        $osmsgfile = 1;
        @osmsgfiles = (@osmsgfiles, $afile);
      }

    $log_types{$afile} = $log_type;
    @afiles = (@afiles, $afile);
}

sub read_flist
{
  open(F1, "$flist");
  while(<F1>)
  {    
    chomp;
    $afile = $_;
    push_file () if ( -r "$afile" );
  }
  close(RF);
}

sub write_oldt_to_file
{
  $end = $_[0];
  system("echo \"<tfa-start-ts-full>$old_t<endof-tfa-start-ts-full>\" > $tfa_base/tfaweb/merged_${hash}.log.sts") if ( ! -f "$tfa_base/tfaweb/merged_${hash}.log.sts" && $old_t );
  if ( $print_cnt%100 == 0 || $end)
  {
    open(WF, ">$tfa_base/tfaweb/merged_${hash}.log.ets");
    print WF "<tfa-end-ts-full>$old_t<endof-tfa-end-ts-full>";
    close(WF);
  }
}

sub getoffset
{
  my $temp_from = $from;
  $from = $from4jt;
  $start_lno = 0;
  while ( ! -e  "$tfa_base/tfaweb/merged_".$hash.".completed" )
  {
    $efile = "$tfa_base/tfaweb/merged_".$hash.".log.ets";
    $etime = `cat $efile | head -1` if ( -r "$efile" );
    chomp($etime);
    if ( $etime =~ /\<tfa-end-ts-full\>(\w+) (\d+) (\d+):(\d+):(\d+) (\d+)<endof-tfa-end-ts-full>/ ||
         $etime =~ /\<tfa-end-ts-full\>(\w+) (\d+) (\d+):(\d+):(\d+)\.\d+ (\d+)<endof-tfa-end-ts-full>/ )
    {
      $mon = get_mon_number($1);
      $dte = $2;
      $hh24 = $3;
      $mi = $4;
      $ss = $5;
      $yr = $6;
      $ts = "$yr$mon$dte$hh24$mi$ss";
      last if ( $ts >= $from );
    }
    sleep(1);
  }

  open(OF, "$ofile");
  $offset = 0;
  while(<OF>)
  {
    $org_line = $_;
    chomp;
    if ( /^(\w+) (\d+) (\d+):(\d+):(\d+) (\d+)$/ ||
         /^(\w+) (\d+) (\d+):(\d+):(\d+)\.\d+ (\d+)$/ ||
         /^<time>(\w+) (\d+) (\d+):(\d+):(\d+) (\d+)</ ||
         /^<time>(\w+) (\d+) (\d+):(\d+):(\d+)\.\d+ (\d+)</
       )
    {
      $mon = get_mon_number($1);
      $dte = $2;
      $hh24 = $3;
      $mi = $4;
      $ss = $5;
      $yr = $6;
      $ts = "$yr$mon$dte$hh24$mi$ss";
      last if ( $ts >= $from );
    }
    $offset += length($org_line);
    $start_lno ++;
  }
  print "$offset,$start_lno\n";
  $from = $temp_from;
}

sub add_offset
{
  @d_t = split(/:/, $toffset{$afile});
  if ( $d_t[0] =~ /\-/ )
  {
    $d_t[1] = 0-$d_t[1];
    $d_t[2] = 0-$d_t[2];
  }
  ($yr, $mon, $dte, $hh24, $mi, $ss) = Add_Delta_YMDHMS($yr, $mon, $dte, 
     $hh24, $mi, $ss, 0, 0, 0, $d_t[0], $d_t[1], $d_t[2]);
  $mon = sprintf("%02d",$mon);
  $dte = sprintf("%02d",$dte);
  $hh24 = sprintf("%02d",$hh24);
  $mi = sprintf("%02d",$mi);
  $ss = sprintf("%02d",$ss);
}

sub oswtop
{
  $option = $_[0];
  shift;
  $print_option = "array";
  if ( $_[0] eq "-p" )
  { # print on screen
    $print_option = "screen";
    shift;
  }
  
  $line_prefix = "";
  $line_prefix = "OSWTOP:" if ( $print_option eq "array" );
  if ( $option eq "-f" )
  {
    $file = $_[0];
  }
   else
  {
    @lines = @_;
  }

  $at = "start";
  $print = "none";
  $summary = "";
  @plines = ();
  if ( $option eq "-f" )
  {
    open(RF, "$file") || die "Cant open $file for reading\n";
    @lines = <RF>;
  }

  foreach $line (@lines)
  {
    #chomp($line);
    #$line = $_;
    if ( $line =~ /^zzz.*(\w\w\w \w\w\w \d\d \d\d:\d\d:\d\d) \w+ (\d\d\d\d)/ ||
         $line =~ /^zzz.*(\w\w\w \w\w\w \d\d \d\d:\d\d:\d\d) (\d\d\d\d)/ )
    {
      @plines = ("OSWTOPSUMMARY:$summary\n", @plines) if ( $at ne "start");
      print_lines() if ($print ne "none");
      $timenow = "$1 $2";
      $print = "none";
      $at = "summary";
      @plines = ();
      $summary = "";
      @plines = ("$timenow") if ( $print_option eq "screen" );
    }
     elsif ( $line =~ /PID/ )
    {
      @plines = (@plines, "$line_prefix$line");
      $at = "detailed";
      $line =~ s/^\s+//;
      @d = split(/\s+/, $line);
      for ( $i = 0; $i <= $#d ; $i++ )
      {
        $cindex = $i if ( $d[$i] =~ /CPU/ ); 
        $mindex = $i if ( $d[$i] =~ /MEM/ ); 
      }
#print "cindex=$cindex, mindex=$mindex\n";
    }
     elsif ( $at eq "summary" )
    { # print if load_av > 10, iowait > 5, idle < 90, free swap is less, free mem is less
      @plines = (@plines, "$line_prefix$line");
      if ( $line =~ /load average: ([\d\.]+), ([\d\.]+), ([\d\.]+)/ ||
           $line =~ /load averages:\s+([\d\.]+),\s+([\d\.]+),\s+([\d\.]+)/ )
      {
        $print = "summary" if ( $1 >= 10 || $2 >= 10 || $3 >= 10);
        $summary .= "LOADAVG=$1, $2, $3/";
      }
       elsif ( $line =~ /([\d\.]+)\% idle/ || $line =~ /([\d\.]+)\%id,/ )
      {
        $print = "summary" if ( $1 < 70 );
        $summary .= "CPUIDLE=$1/"
      }
       elsif ( $line =~ /(\w+):\s+(\d+)\w total,\s+\d+\w used,\s+(\d+)\w free/ )
      {
        $free_pct = $3*100/$2;
        $memtype = uc($1);
        $free_pct =~ s/(.*\.\d\d).*/$1/;
        $print = "summary" if ( $free_pct < 1 );
        $summary .= "FREE$memtype=$free_pct/"
      }
       elsif ( $line =~ /Memory: (\d+)\w phys mem, (\d+)\w free mem, (\d+)\w total swap, (\d+)\w free swap/ )
      {
        $free_pct_mem = $2*100/$1;
        $free_pct_swap = $4*100/$3;
        $free_pct_mem =~ s/(.*\.\d\d).*/$1/;
        $free_pct_swap =~ s/(.*\.\d\d).*/$1/;
        $print = "summary" if ( $free_pct_mem < 1 || $free_pct_swap < 1 );
        $summary .= "FREEMEM=$free_pct_mem/FREESWAP=$free_pct_swap"
      }
    }
     elsif ( $at eq "detailed" )
    { # print if cpu or memory by a process is greater than 10
      $oline = $line;
      $line =~ s/^\s+//;
      $line =~ s/^\s+//;
      @d = split(/\s+/, $line);
      if ( $d[$cindex] > 10 || $d[$mindex] > 10 )
      {
        $print = "detailed";
        @plines = (@plines, "$line_prefix$oline");
      }
    }
  }
  @plines = ("OSWTOPSUMMARY:$summary\n", @plines);
  print_lines() if ($print ne "none"); # Last timestamp
  close(RF) if ( $option eq "-f" );
  return (@plines) if ( $print_option eq "array" && $print ne "none");
}

sub print_lines
{
  return if ( $print_option ne "screen" );
  foreach $pline (@plines)
  {
    print "OSWOUT: $pline\n";
  }
}

sub scan_file4details 
{
 my %file_info = ();
 my @files = @_;
 foreach $file ( @files )  {
  $sid = "";
  $dbname = "";
  $hname = "";
  $myinst = "";
  $atype = "DB";   
  open(RF, "$file") || die "Can't open the file $file";
  while(<RF>) {
    chomp;
    if ( /SID=\W([\+\w]+)\W/ ) {
      $sid = $1;
    }
    elsif ( /cellrssmt with pid \d+/ ) {
      $atype = "CELL";
    }
    elsif ( /CELLSRV cell host name=(\w+)\./ ) {
      $atype = "CELL";
      $hname = "$1";
      last;
    }
    elsif ( /Errors in file .*diag\/rdbms\/([\+\w]+)\/([\+\w]+)\// ||
             /.*diag\/rdbms\/([\+\w]+)\/([\+\w]+)\/trace\/\w+\.\w+/ ||
             /.*diag\/asm\/cell\/([\+\w]+)\/trace\/([\+\w]+)_[\d\_]+\.trc/ ||
             /System State dumped to trace file .*diag\/asm\/([\+\w]+)\/([\+\w]+)\// ) {
      $dbname = $1;
      $sid = $2;
    }
    elsif ( /\/([\w\+]+)_\w+_\d+\.trc/ || /ORACLE Instance ([\w\+]+) - Archival Error/ ) {
      $sid = $1;
    }
    elsif ( /\/admin\/(\w+)\/adump/ ||
                /Current log# \d+.*: \+\w+\/(\w+)\/onlinelog/ || /^\s+db_name\s+=\s+(\w+)/ ) {
      $dbname = $1;
    }
    elsif ( /^ [\d\s]+ \(myinst: (\d+)\)/ ) {
      $myinst = $1;
    }
    elsif ( /^\[\w+\W\d+\W\][\w\d\-\:]+ started on node (.*)\./ ) {
      $atype = "CRS";
      $hname = "$1";
    }
    elsif ( /\/grid\/log\/(.*)\/agent\// || /\/crs\/log\/(.*)\/crsd\// ) {
      $atype = "CRS";
      $hname = "$1";
    }
    elsif ( /^\[\w+\W\d+\W\][\w\d\-\:]+The clock on host (.*) is not synchronous/ ) {
      $atype = "CRS";
      $hname = "$1";
    }
    last if ( $sid && $dbname );
  } #End of while
  close(RF);

  # Get dbname from instance name 
  if ( ! $dbname && $sid && $myinst )
  {
    $dbname = $sid;
    $dbname =~ s/$myinst$//;
  }

  # Get sid from db name 
  $sid = "$dbname$myinst" if ( ! $sid && $myinst && $dbname );
  $atype = "ASM" if ( $sid =~ /\+/ );
  $file_info{$file}->{SID} = $sid;
  $file_info{$file}->{DBNAME} = $dbname;
  $file_info{$file}->{HNAME} = $hname;
  $file_info{$file}->{ATYPE} = $atype;
 } #end of for
 return %file_info;
}

##############################################################################

sub parse_trc_600
{
  $file = $_[0];
  $tapi600_output{CNT} = 0;
  $print_all_keys = 1;
  if ( ! -z "$_[1]" )
  {
    $print_all_keys = 0;
    foreach $tkey (@_)  # STACK, SQL, 
    {
      $tapi600_output{$tkey}->{PRINT} = 1 if ( $tkey ne $file );
      $tapi_600output{$tkey}->{VAL} = "";
    }
  }

  $ora_600 = 0;
  $ora_600_stack = 0;
  $ora_600_sql = 0;
  $tapi_hi = 0;
  $last_saved_time = "";

  open (RFTRC, "$file") || die "Can't open $file for reading\n";
  while(<RFTRC>)
  {
    chomp;
    $tapi_line = $_;
    if ( $tapi_line =~ /^Oracle Database .* Release (\d+\.\d+\.\d+\.\d+\.\d+)/ )
    {
      $tapi600_output{VERSION} = $1;
    }
     elsif ( $tapi_line =~ /Call stack signature: (.*)/ )
    {
      $tapi600_output{SIGNATURE} = $1;
    }
     elsif ( $tapi_line =~ /^Unix process pid: (\d+),/ )
    {
      $tapi600_output{PID} = $1;
    }
     elsif ( $tapi_line =~ /^Instance name:\s+(\w.*)/ )
    {
      $tapi600_output{INSTANCE} = $1;
    }
     elsif ( $tapi_line =~ /^Node name:\s+(\w.*)/ )
    {
      $tapi600_output{HOST} = $1;
    }
     elsif ( $tapi_line =~ /^Machine:\s+(\w.*)/ )
    {
      $tapi600_output{PTYPE} = $1;
    }
     elsif ( $tapi_line =~ /^System name:\s+(\w.*)/ )
    {
      $tapi600_output{PLATFORM} = $1;
    }
     elsif ( $tapi_line =~ /^\*\*\* (\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d\.\d\d\d)/ ||
             $tapi_line =~ /^\*\*\* (\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d\d\d)/ )
    {
      $tapi600_output{STACK}[$tapi_hi]->{TIME} = $1;
      $tapi600_output{STACK}[$tapi_hi]->{TIME} =~ s/T/ /;
      $last_saved_time = $1;
    }

    #print "$ora_600 | $ora_600_stack  $tapi_line\n";
    if ( $ora_600 == 0 && $tapi_line =~ /-- Call Stack Trace/ )
    {
      $ora_600 = 1;
      $oeri = "";
      $tapi600_output{STACK}[$tapi_hi]->{MSG} = "";
    }

    if ( $tapi_line =~ /^(ORA-00600): internal error code, arguments: \[([^\]]+)\]/ ||
         $tapi_line =~ /^(ORA-00603): ORACLE server session terminated by fatal error/ ||
         $tapi_line =~ /^(ORA-07445): [\w\:\s]+\[([^\]]+)\]/)
    {
      $ora_600 = 1;
      $oeri = $1;
      $tapi600_output{STACK}[$tapi_hi]->{MSG} = "$1 $2\n";
      $tapi600_output{STACK}[$tapi_hi]->{MLINE} = "$tapi_line";
    }
     elsif ( $ora_600 == 0 && $tapi_line =~ /^(ORA-\d+):/ )
    {
      $ora_600 = 1;
      $oeri = $1;
      $tapi600_output{STACK}[$tapi_hi]->{MSG} = "$1\n";
      $tapi600_output{STACK}[$tapi_hi]->{MLINE} = "$tapi_line";
    }

     elsif ( $ora_600 == 1 && ( $tapi_line =~ /^([\w\$]+)[\W\d]+\s+call[\?\s]+[\$\w]+/i ||
                                $tapi_line =~ /^([\w\$]+)[\W\d]+\s+ptr_call[\?\s]+[\$\w]+/i )
                           && $tapi_line !~ /^calling/ ) 
    {
      $ora_600_stack = 1;
      $tapi600_output{STACK}[$tapi_hi]->{VAL} .= "<-$1";
      $tapi600_output{STACK}[$tapi_hi]->{TIME} = $last_saved_time if ( ! defined $tapi600_output{STACK}[$tapi_hi]->{TIME} );
    }
     elsif ( $ora_600_sql == 1 && ($tapi_line =~ /^$/ || $tapi_line =~ /Call Stack Trace/ || $tapi_line =~ /sql_text_length=\d+/) )
    {
      $ora_600_sql = 0;
    }
     elsif ( $tapi_line =~ /Current SQL Statement for this session/ ) 
    {
      $ora_600_sql = 1;
      $ora_600_stack = 1;
    }
     elsif ( $ora_600_sql == 1 )
    {
      $tapi600_output{SQL}[$tapi_hi]->{VAL} .= "$tapi_line\n";
    }
     elsif ( $ora_600_stack == 1 && $tapi_line =~ /^[\-]+ \w+/ && $tapi_line !~ /^[\-]+ Call Stack Trace/ )
    {
      $ora_600 = 0;
      $ora_600_stack = 0;
      $tapi600_output{STACK}[$tapi_hi]->{VAL} .= "\n";
      $tapi600_output{CNT}++;
      $tapi_hi++;
    }
  }
  close(RFTRC);
}

sub check_for_repeated_patterns2
{
  $in_rp = 0;
  $tapi_start = $ctime;
  foreach $key (keys %patterns)
  {
    if ( $patterns{$key}->{IS_REPEATING} == 1 &&
         $line =~ /$patterns{$key}->{BEGINPATTERN}/ )
    {
      $in_rp = 1;
      print "$ctime - $line\n";
      $mkey = $key;
      last;
    }
  }

  if ( $in_rp == 1 )
  {
    $rp_cnt = 1;
    @arr = split(/\<ENDLINE\>/, $patterns{$mkey}->{INBETWEEN});
    while(<$ih>)
    {
      chomp;
      $line = $_;
      $rp_cnt++ if ( /$patterns{$mkey}->{BEGINPATTERN}/ );
      $in_rp = 0;
      if ( $line =~ /^(\w+\s+\w+\s+\d+\s+\d+:\d+:\d+\s+\d+)/)
      {
        $ctime = $1;
        $tapi_end = $ctime;
        $print = 0 if ($print != 2 );
        $in_rp = 1;
      }
       else
      {
        print " "x$space . "$_\n" if ( $rp_cnt == 1 );
      }
      foreach $ele (@arr)
      {
        chomp($ele);
        if ( $line =~ /$patterns{$mkey}->{BEGINPATTERN}/ || $line =~ /$ele/ )
        {
          $in_rp = 1;
          last;
        }
      }
      last if ( $in_rp == 0 );
    }
    if ( $rp_cnt > 1)
    {
      print " "x$space . "Above message repeated $rp_cnt times between \n";
      print " "x$space . "$tapi_start & $tapi_end.\n";
    }
    #print "Breaking line : $line $patterns{$mkey}->{INBETWEEN}\n";
  }
}

use File::Find;

sub get_files_in_pwd
{
  @files = ();
  find(\&wanted, '.');
  return (@files);
}

sub wanted {
  -f && -r && !-d && push(@files, $File::Find::name);
}

