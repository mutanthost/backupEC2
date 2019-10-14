#!/bin/sh
#
# $Header: tfa/src/v2/tfa_home/bin/scripts/unzip.sh /main/1 2017/10/08 22:51:00 gadiga Exp $
#
# unzip.sh
#
# Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      unzip.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    gadiga      10/03/17 - unzip collection
#    gadiga      10/03/17 - Creation
#

usage()
{
  echo "$0 [-o|-q|-d <dir>] <zip>"
  exit
}

collection=$1

tfa_home_bin_scripts=`dirname $0`
tfa_home_bin=`dirname $tfa_home_bin_scripts`
tfa_home=`dirname $tfa_home_bin`
tfa_setup=$tfa_home/tfa_setup.txt
crs_home=`grep '^CRS_HOME=' $tfa_setup |cut -d= -f2`

if [ -z "$crs_home" ] ; then
  echo "CRS_HOME is not found";
  exit 1;
fi

$crs_home/jdk/bin/jar xf $collection

