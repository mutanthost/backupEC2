#!/bin/sh
#
# $Header: tfa/src/orachk/src/ofm_client.sh /main/1 2015/08/31 18:43:19 cgirdhar Exp $
#
# ofm_client.sh
#
# Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      ofm_client.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    cgirdhar    08/31/15 - script to login to Oracle Fabric Manager and query
#                           configuration using OFM API
#    cgirdhar    08/31/15 - Creation
#

if [ -z "$RAT_OFM_USER" ]; then
    export RAT_OFM_USER=$USER
fi

executeLogin() {
  response=`_executeCurl "POST" "xms/resource/rest/xmsSession" '{"username":"'$RAT_OFM_USER'","password":"'$RAT_OFM_PASSWORD'"}' --cookie-jar $cookieFile`
  status=`echo "$response" | tr , \\\n | grep '^"status"'`
  
  if [ -z "`echo "$response" | tr , \\\n | grep '^"status":"pass"'`" ]; then 
    >&2 echo "INFO - Password is wrong! Please provide correct password."
    exit 255
  fi
}

_executeCurl() {
  _method=$1; shift
  _uri=$1; shift
  _body=$1; shift

  curl --silent --insecure -H 'Content-Type: application/json;' -X $_method "https://$hostname:8443/$_uri" -d "$_body" $*
  if [ $? != 0 ]; then
    >&2 echo "INFO - Command Failed: $?"
    exit 253
  fi

  checkCurlInstalled=`curl -V`
  curlStatus=`echo "$checkCurlInstalled" | grep 'curl ' | awk '{print $1}'`
  if [ "$curlStatus" != "curl" ]; then
    >&2 echo "INFO - Curl is not installed! Please install it first."
    exit 254
  fi  
}

hostname=$1
method=$2
uri=$3

cookieFile=/tmp/cookie.txt.$$

executeLogin
_executeCurl "GET" "$uri" "" "--cookie $cookieFile" | tr , \\\n

