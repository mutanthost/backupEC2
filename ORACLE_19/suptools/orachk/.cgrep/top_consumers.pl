# 
# $Header: tfa/src/orachk_py/scripts/top_consumers.pl /main/7 2018/05/21 00:11:45 apriyada Exp $
#
# top_consumers.pl
# 
# Copyright (c) 2017, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      top_consumers.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    gowsrini    02/13/17 - Creation
# 

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;

my ($CHKFILE);
my ($CHECKS);
my ($THTML)= "topconsumers.html";
my ($TLIMIT)= 10;
my ($UNIT)= "ms";
my ($PROGRAM_NAME);

sub usage {
  print "Usage: $0 -f CHECK TIMINGS FILE -t NUMBER(Top n Checks) -r TIMING HTML -p PROGRAM_NAME \n";
  exit;
}

if ( @ARGV == 0 ) {
  usage();
}

Getopt::Long::GetOptions( "f=s" => \$CHKFILE, "t=i" => \$TLIMIT, "r=s" => \$THTML, "p=s" => \$PROGRAM_NAME  ) or usage();
sub process_line {
  my ($line) = shift;
  my ($process) = 1;    

  $process = 0 if ( $line =~ m/^\s*#/ );
  $process = 0 if ( $line =~ m/^\s*$/ );

  return $process;
}

sub get_checkid {
  my ($line) = shift;
  $line =~ s/^\[CHECK://g;
  $line =~ s/\].*$//g;
  $line =~ s/\s*//g;
  return $line;
}
sub get_time {
  my ($line) = shift;
  $line =~ s/^.*Time: //g;
  return $line;
}

sub get_host {
  my ($line) = shift;
  $line =~ s/^.*\[HOST://g;
  $line =~ s/\].*$//g;
  $line =~ s/\s*//g;
  return $line;
}

sub get_type {
  my ($line) = shift;
  $line =~ s/^.*\[TYPE://g;
  $line =~ s/\].*$//g;
  $line =~ s/\s*//g;
  return $line;
}

sub get_tag1 {
  my ($line) = shift;

  return "" if ( $line !~ m/TAG1/ );

  $line =~ s/^.*\[TAG1://g;
  $line =~ s/\].*$//g;
  $line =~ s/\s*//g;
  return $line;
}

sub get_tag2 {
  my ($line) = shift;

  return "" if ( $line !~ m/TAG2/ );

  $line =~ s/^.*\[TAG2://g;
  $line =~ s/\].*$//g;
  $line =~ s/\s*//g;
  return $line;
}

sub get_tag3 {
  my ($line) = shift;

  return "" if ( $line !~ m/TAG3/ );

  $line =~ s/^.*\[TAG3://g;
  $line =~ s/\].*$//g;
  $line =~ s/\s*//g;
  return $line;
}

sub get_cn {
  my ($line) = shift;
  $line =~ s/^.*\[COLLECTION_NAME://g;
  $line =~ s/\].*$//g;
  $line =~ s/^\s*//g;
  $line =~ s/\s*$//g;
  return $line;
}

sub get_chkname {
  my ($line) = shift;
  $line =~ s/^.*\[AUDIT_CHECK_NAME://g;
  $line =~ s/\].*$//g;
  $line =~ s/^\s*//g;
  $line =~ s/\s*$//g;
  return $line;
}

sub timings {
  my $CHECKID      = shift; 
  my $HOST         = shift;
  my $TYPE         = shift;
  my $END_TIME     = shift;
  my $START_TIME   = shift;
  my $SECTION      = shift;
  my $COL_NAME     = shift || "";
  my $CHK_NAME     = shift || "";
  my $TAG1         = shift || "";
  my $TAG2         = shift || "";
  my $TAG3         = shift || 0;
  my $DIFF = $END_TIME - $START_TIME;

  $CHECKS->{"$CHECKID:$HOST:$TYPE:$START_TIME:$END_TIME:$COL_NAME:$CHK_NAME:$TAG1:$TAG2:$TAG3"} = $DIFF;
}

sub convert_format {
  my ($duration);
  if ( $UNIT eq 'ms' ) {
    my ($Milliseconds) = shift;

    my ($Hours)   = ($Milliseconds/(1000*60*60))%24;
    my ($Minutes) = ($Milliseconds/(1000*60))%60;
    my ($Seconds) = ($Milliseconds/1000)%60;

    $duration = $Hours . " hrs, " . $Minutes . " mins" . " and " . $Seconds . " secs";
    if ( $Hours == 0 ) {
      $duration =~ s/^.*hrs, //g;
    }
    if ( $Minutes == 0 && $Hours == 0 ) {
      $duration =~ s/^.*mins and //g;
    }
    if ( $Seconds == 0 && $Minutes == 0 && $Hours == 0 ) {
      $duration =~ s/^.*secs //g;
      $duration = $Milliseconds . " ms";
    }
  }
  elsif ( $UNIT eq 'secs' ) {
    my ($Seconds) = shift;

    my ($Hours)   = ($Seconds/(60*60))%24;
    my ($Minutes) = ($Seconds/60)%60;
    $Seconds      = $Seconds%60;

    $duration = $Hours . " hrs, " . $Minutes . " mins" . " and " . $Seconds . " secs";
    if ( $Hours == 0 ) {
      $duration =~ s/^.*hrs, //g;
    }
    if ( $Minutes == 0 && $Hours == 0 ) {
      $duration =~ s/^.*mins and //g;
    }
  }
  return $duration;
}

sub print_info {
  my ($count) = 0;
  my $pg  = uc substr($PROGRAM_NAME, 0, 3);
  $pg = $pg."chk";
  open ( my $TCF, ">" , $THTML ) || die $!;
  print $TCF "<div id=\"tcbody\"><a href=\"\#\" class=\"a_bgw\">Top</a>\n";
  print $TCF "<a name=\"top_consumers\"></a>\n";
  print $TCF "<h2>Top 10 Time Consuming Checks</h2>\n";
  print $TCF "<p><b>NOTE:</b> This information is primarily used for helping Oracle optimize the run time of $pg.<br></br>These timings are not necessarily indicative of any problem and may vary widely from one system to another.</p>\n";
  print $TCF "<table summary=\"Top Time Consuming Checks\">\n";
  print $TCF "<tr>\n";
  print $TCF "<th style=\"DISPLAY: none;\" name=\"checkid\" scope=\"col\">Check Id</th>\n";
  print $TCF "<th scope=\"col\">Name</th>\n";
  print $TCF "<th scope=\"col\">Type</th>\n";
  print $TCF "<th scope=\"col\">Target</th>\n";
  print $TCF "<th scope=\"col\">Execution Duration</th>\n";
  print $TCF "</tr>\n";

  foreach my $data (sort { $CHECKS->{$b} <=> $CHECKS->{$a} } keys %$CHECKS) {
  if ( $TLIMIT <= $count ) { last; }
      
  my (@data) = split(':',$data);
  my ($checkid)    = $data[0];

  my ($name)       = $data[5];
  if (!defined $data[5] || $data[5] =~ m/^\s*$/ ) { $name = $data[6]; }
  
  my ($target)     = $data[1];
  if (defined $data[7] && $data[7] !~ m/^\s*$/ ) { $target .= ':'.$data[7]; }
  if (defined $data[8] && $data[8] !~ m/^\s*$/ ) { $target .= ':'.$data[8]; }

  my ($duration)  = convert_format($CHECKS->{$data});

  print $TCF "<tr>\n";

  my ($type)      = $data[2];
  if (( $type =~ m/SQL_COLLECT/ || $type =~ m/OS_COLLECT/ ) || (defined $data[9] && $data[9] =~ m/[0-9]/ && $data[9] == 0 )) {
    print $TCF "<td align=\"center\" class=\"check-id\" style=\"DISPLAY: none;\" name=\"checkid\" scope=\"row\">$checkid</td>\n";
    print $TCF "<td scope=\"row\">$name</td>\n";
  }
  else {
    print $TCF "<td align=\"center\" class=\"check-id\" style=\"DISPLAY: none;\" name=\"checkid\" scope=\"row\">$checkid</td>\n";
    print $TCF "<td scope=\"row\"><a class=\"a_bgw\" href=\"\#".$checkid."_summary\">$name</a></td>\n";
  }

  if ( $type =~ m/SQL_COLLECT/ ) {
	print $TCF "<td scope=\"row\" align=\"center\"> SQL Collection </td>\n";
  }
  elsif ( $type =~ m/OS_COLLECT/ ) {
    print $TCF "<td scope=\"row\" align=\"center\"> OS Collection </td>\n";
  }
  else {
    print $TCF "<td scope=\"row\" align=\"center\"> $type Check </td>\n";

  }
  print $TCF "<td scope=\"row\" align=\"center\"> $target </td>\n";
  print $TCF "<td scope=\"row\" align=\"center\">".$duration."</td>\n";
  print $TCF "</tr>\n";

  $count++;
  }

  print $TCF "</table></div>";
}

my ($EPOCH_TIME) = '`date +%s%3N`';
if ( $EPOCH_TIME =~ m/%3N$/ || $EPOCH_TIME !~ m/^[0-9]*$/) { $UNIT = "secs"; }

if (-e $CHKFILE) {
  open( my $CTIME, "<", $CHKFILE ) || die $!;
  while ( my $line = <$CTIME> ) {
    if ( process_line($line) == 0 ) { next; } else { chomp($line); }      
    if ( $line =~ m/Check Start Time/ ) {
      my $CHECKID  = get_checkid($line);
      next if ( $CHECKID eq "" );
      
      my $TIME_st  = get_time($line);
      my $HOST     = get_host($line);
      my $TYPE     = get_type($line);
      my $COL_NAME   = get_cn($line);
      my $CHK_NAME   = get_chkname($line);
	  
	  while ( my $line = <$CTIME> ) {
        if ( process_line($line) == 0 ) { next; } else { chomp($line); }  
        if ( $line =~ m/Execution Start Time:/i && $line =~ m/$CHECKID/ && $line =~ m/$HOST/i ) {
          my $TIME_est     = get_time($line);
          my $TAG1         = get_tag1($line);
          my $TAG2         = get_tag2($line);
          my $TAG3         = get_tag3($line);
  
          while ( my $line = <$CTIME> ) {
            if ( process_line($line) == 0 ) { next; } else { chomp($line); }
  
            if ( $line =~ m/Check:get_log_result.*Start Time/i && $line =~ m/$CHECKID/ && $line =~ m/$HOST/i ) {
                my $TIME_gst    = get_time($line);
  
                while ( my $line = <$CTIME> ) {
                if ( process_line($line) == 0 ) { next; } else { chomp($line); }
  
                if ( $line =~ m/Check:log_pass.*Start Time/ && $line =~ m/$CHECKID/ && $line =~ m/$HOST/i ) {
                  my $TIME_lpst = get_time($line);
  
                  while ( my $line = <$CTIME> ) {
                    if ( process_line($line) == 0 ) { next; } else { chomp($line); }
  
                    if ( $line =~ m/Check:log_pass.*End Time/ && $line =~ m/$CHECKID/ && $line =~ m/$HOST/i ) {
                      my $TIME_lpet = get_time($line);
                      last;
                    }
                  }
                }
                if ( $line =~ m/Check:log_fail.*Start Time/ && $line =~ m/$CHECKID/ && $line =~ m/$HOST/i ) {
                  my $TIME_lfst = get_time($line);
  
                  while ( my $line = <$CTIME> ) {
                    if ( process_line($line) == 0 ) { next; } else { chomp($line); }
  
                    if ( $line =~ m/Check:fail.*End Time/ && $line =~ m/$CHECKID/ && $line =~ m/$HOST/i ) {
                      my $TIME_lfet = get_time($line);
					  last;
                    }
                  }
                }
                if ( $line =~ m/Check:get_log_result.*End Time/i && $line =~ m/$CHECKID/ && $line =~ m/$HOST/i ) {
                  my $TIME_get = get_time($line);
                  last;
                }
              }
            }
            if ( $line =~ m/Execution End Time:/i && $line =~ m/$CHECKID/ && $line =~ m/$HOST/i ) {
              my $TIME_eet = get_time($line);
              timings($CHECKID, $HOST, $TYPE, $TIME_eet, $TIME_est, 'execution', "$COL_NAME", "$CHK_NAME", "$TAG1", "$TAG2", "$TAG3");
  
              last;
            }
		   }
        }
        elsif ( $line =~ m/Check:get_log_result.*Start Time/i && $line =~ m/$CHECKID/ && $line =~ m/$HOST/i ) {
          my $TIME_gst     = get_time($line);
          my $TAG1         = get_tag1($line);
          my $TAG2         = get_tag2($line);
          my $TAG3         = get_tag3($line);
  
          while ( my $line = <$CTIME> ) {         
            if ( process_line($line) == 0 ) { next; } else { chomp($line); }      
  
            if ( $line =~ m/Execution Start Time:/i && $line =~ m/$CHECKID/ && $line =~ m/$HOST/i ) {
                my $TIME_est = get_time($line);
  
                while ( my $line = <$CTIME> ) {
                if ( process_line($line) == 0 ) { next; } else { chomp($line); }  
  
                if ( $line =~ m/Check:log_pass.*Start Time/ && $line =~ m/$CHECKID/ && $line =~ m/$HOST/i ) {
                    my $TIME_lpst = get_time($line);
  
                    while ( my $line = <$CTIME> ) {
                    if ( process_line($line) == 0 ) { next; } else { chomp($line); }      
  
                    if ( $line =~ m/Check:log_pass.*End Time/ && $line =~ m/$CHECKID/ && $line =~ m/$HOST/i ) {
                      my $TIME_lpet = get_time($line);
                      last;
                      }     
                    }
				}
				if ( $line =~ m/Check:log_fail.*Start Time/ && $line =~ m/$CHECKID/ && $line =~ m/$HOST/i ) {
                  my $TIME_lfst = get_time($line);
  
                  while ( my $line = <$CTIME> ) {
                    if ( process_line($line) == 0 ) { next; } else { chomp($line); }      
  
                    if ( $line =~ m/Check:fail.*End Time/ && $line =~ m/$CHECKID/ && $line =~ m/$HOST/i ) {
                      my $TIME_lfet = get_time($line);
                      last;
                    }       
                  }
                }
                if ( $line =~ m/Execution End Time:/i && $line =~ m/$CHECKID/ && $line =~ m/$HOST/i ) {
                  my $TIME_eet = get_time($line);
            
                  timings($CHECKID, $HOST, $TYPE, $TIME_eet, $TIME_est, 'execution', "$COL_NAME", "$CHK_NAME", "$TAG1", "$TAG2", "$TAG3");
                  last;
                }  
              }
            }
            if ( $line =~ m/Check:get_log_result.*End Time/i && $line =~ m/$CHECKID/ && $line =~ m/$HOST/i ) {
              my $TIME_get = get_time($line);
              last;
            }
          }
        }
  
        if ( $line =~ m/Check End Time/ && $line =~ m/$CHECKID/ && $line =~ m/$TYPE/ ) {
          my $TIME_et = get_time($line);
          last;
        }   
      }
    }
  }
  close($CTIME);
  print_info ();
}
