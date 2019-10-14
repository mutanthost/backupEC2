#!/bin/sh
#
# $Header: tfa/src/v2/tfa_home/bin/scripts/tfa_push_to_logstash.sh /main/1 2018/06/27 06:02:22 gadiga Exp $
#
# tfa_push_to_logstash.sh
#
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfa_push_to_logstash.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    gadiga      06/25/18 - push events to logstash
#    gadiga      06/25/18 - Creation
#

PWD=/bin/pwd
MV=/bin/mv
CHMOD=/bin/chmod
GREP=/bin/grep
SED=/bin/sed
AWK=/bin/awk
HOSTNAME=/bin/hostname

cwd=`$PWD`
scr=$0

ifile=$1
$MV $ifile $ifile.$$
ifile=$ifile.$$
tlog=$ifile.$$.log

function wl
{
  return;
  echo $1 >> $tlog
}

tfa_home=`echo $scr |$SED 's/tfa_home.*/tfa_home/'`
if [ ! -x "/usr/bin/nc" ] ; then
  nc=$tfa_home/bin/scripts/nc
  chmod +x $nc
fi

wl "TFA_HOME=$tfa_home" 

l_port=`$GREP logstash.port= $tfa_home/internal/config.properties |$SED  's/logstash.port=//'`
l_host=`$GREP logstash.host= $tfa_home/internal/config.properties |$SED  's/logstash.host=//'`
tfaweb_url_base=`$GREP tfaweb.url= $tfa_home/internal/config.properties |$SED  's/tfaweb.url=//' | $SED  's/\\\\//g' |$SED  's/.COLON./:/g'`

if [ -z "$l_port" ] ; then
  wl "Logstash is not configured";
  exit
fi

file=`$GREP file= $ifile |$SED  's/file=//'`
wl "file=$file"
dbname=`echo $file | $AWK -F"/" '{print $(NF-2)}'`
inst=`echo $file | $AWK -F"/" '{print $(NF-3)}'`
hostname=`$HOSTNAME`
pts=`$GREP time= $ifile |$SED  's/time=//' |$SED  's/ /T/'`
msg=`$GREP String= $ifile |$SED  's/String=//'`
err=
if [ `echo $msg| $GREP -c :` -gt 0 ] ; then
  err=`echo $msg | $SED  's/:.*//'`
fi

typ=`$GREP type= $ifile |$SED  's/type=//'`
if [ -z "$typ" ] ; then typ=ERROR; fi

tfaweb_url="$tfaweb_url_base?host=$hostname&time=$pts";

cmd="{\"@timestamp\" : \"$pts\", \"hostname\" : \"$hostname\", \"database\" : \"$dbname\", \"instance\" : \"$inst\", \"msgtype\" : \"$typ\", \"error\" : \"$err\", \"@message\" : \"$msg\"} | $nc $l_host $l_port"
wl "running $cmd"

echo "{\"@timestamp\" : \"$pts\", \"hostname\" : \"$hostname\", \"database\" : \"$dbname\", \"instance\" : \"$inst\", \"msgtype\" : \"$typ\", \"error\" : \"$err\", \"@message\" : \"$msg\", \"analysis\" : \"$tfaweb_url\" }" | $nc $l_host $l_port

