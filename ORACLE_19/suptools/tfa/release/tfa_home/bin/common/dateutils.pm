# 
# $Header: tfa/src/v2/tfa_home/bin/common/dateutils.pm /main/3 2018/07/19 09:16:01 recornej Exp $
#
# dateutils.pm
# 
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      dateutils.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    07/13/18 - Adding sub to check future and older dates.
#    llakkana    05/22/18 - Add date format function
#    bibsahoo    02/15/18 - Creation
# 

package dateutils;

BEGIN {
  use Exporter();
  our (@ISA, @EXPORT);
  @ISA = qw(Exporter);
  my @exp_var = qw(%dateutils_months_dict %dateutils_rev_months_dict MAX_OLD_DATE);
  push @EXPORT,@exp_var;
  my @exp_func = qw(dateutils_format_logdate dateutils_format_date 
                    dateutils_valid_date_age );
  push @EXPORT,@exp_func;
}

use strict;
our %dateutils_months_dict = ("jan"=>"01", "feb"=>"02", "mar"=>"03", "apr"=>"04", 
                             "may"=>"05", "jun"=>"06", "jul"=>"07", "aug"=>"08", 
                             "sep"=>"09", "oct"=>"10", "nov"=>"11", "dec"=>"12");
our %dateutils_rev_months_dict=("01"=>"Jan", "02"=>"Feb", "03"=>"Mar", "04"=>"Apr", 
                               "05"=>"May", "06"=>"Jun", "07"=>"Jul", "08"=>"Aug", 
                               "09"=>"Sep", "10"=>"Oct", "11"=>"Nov", "12"=>"Dec");
use constant  MAX_OLD_DATE  => 180; #Days
####
# NAME
#   dateutils_format_logdate
#
# DESCRIPTION
#   This fuction takes log date format as output and returns user readable date format
#
# PARAMETERS
#     $timestamp       (IN)  date format used in logs
#	  $format_number   (IN)  format number to print a type of format
# RETURNS
#     $date            (OUT) User readable date format
#
# NOTES 
#   NONE
#####
#TODOD: Change to dateutils_format_date 
sub dateutils_format_logdate
{
  ## YYYYMMDDHHMMSSSSS as input to be converted into a user readable format
  my $timestamp = shift;	
  my $format_number = shift;
  my $date = "";
  my $year = substr $timestamp, 0, 4;
  my $month = substr $timestamp, 4, 2;
  my $day = substr $timestamp, 6, 2;
  my $hour = substr $timestamp, 8, 2;
  my $min = substr $timestamp, 10, 2;
  my $sec = substr $timestamp, 12, 2;
  my $msec = substr $timestamp, 14, 3;

  if ($format_number == 1) {
    # eg. Jan/01/2017 00:00:00.000 
    $date = $dateutils_rev_months_dict{$month} . "/" . $day . "/" . $year . " " . $hour . ":" . $min . ":" . $sec . "." . $msec; 
  } else {
    # eg. 2017/01/01 00:00:00.000 (default format)
    $date = $year . "/" . $month . "/" . $day . " " . $hour . ":" . $min . ":" . $sec . "." . $msec; 
  }
  return $date;
}

sub dateutils_format_date
{
  my $in_date = shift;
  my $out_format = shift;
  my $date = "";
  my ($year,$month,$day);
  my ($hour,$min,$sec);
  my $msec;

  if ($in_date =~ /([0-9]{4})-([0-9]{2})-([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})\.(\d)/) {
    $year = $1; $month = $2; $date = $3;
    $hour = $4; $min = $5; $sec = $6; $msec = $7;
    if ($out_format eq "YYYYMMDDHHMMSSSSS") {
      $date = "$1$2$3$4$5$6$7"."00";
    }
  }
  elsif ($in_date =~ /[A-Za-z]{3} ([A-Za-z]{3}) ([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2}) [A-Za-z]{3} ([0-9]{4})/) {
    #Ex - Tue Jun 12 10:24:13 PDT 2018
    $year = $6; $month = $dateutils_months_dict{lc$1}; $date = $2;
    $hour = $3; $min = $4; $sec = $5;
    if ($out_format eq "YYYY-MM-DDTHH:MM:SS.SSSZ") {
      $date = "$year-$month-$date"."T$hour:$min:$sec.000Z";
    }
  }
  return $date;
}
####
# NAME
#   dateutils_valid_date_age
#
# DESCRIPTION
#   This fuction validates a date for older and future dates. 
#
# PARAMETERS
#     $date        (IN)  date in seconds
#
# RETURNS
#     $valid       (OUT) 0(true) | 1(false/future date) | -1(false/old date)
#
# NOTES 
#   NONE
#####
sub dateutils_valid_date_age 
{
  my $date = shift;
  my $epoc = time();
  my $olddate = $epoc - MAX_OLD_DATE*24*60*60; #Old date limit 
  return 1 if ( $date > $epoc );#Future date 
  return -1 if ( $date < $olddate );#Very old date
  return 0; #OK
}
1;
