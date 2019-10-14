#!/bin/sh
#
# $Header: opsm/cvutl/cluvfyrac.sh /main/3 2012/09/13 01:16:26 dsaggi Exp $
#
# Copyright (c) 2003, 2012, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      cluvfyrac.sbs 
#
#    DESCRIPTION
#      cluvfyrac.sbs - This is the wrapper script to invoke cluvfy launcher
#                      from CRS_HOME. This file gets copied to OH/bin during
#                      install process and it is named as cluvfy.
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    dsaggi      09/11/12 - Fix 14612018 -- Qualify path for dirname
#    spavan      01/27/10 - set ORACLE_HOME as grid home
#    dsaggi      06/12/09 - Create for 11.2 release
#

ECHO=/bin/echo
DIRNAME=/usr/bin/dirname

cmdpath=`$DIRNAME $0`

#Check whether the command is invoked from a proper Oracle Home
if [ -f  $cmdpath/../srvm/admin/getcrshome ]
then
   #Get CRS home
   CRSHOME=`$cmdpath/../srvm/admin/getcrshome`
   if [ $? -eq 0 ]
   then
      # Run cluvfy from CRS_HOME 
      ORACLE_HOME=$CRSHOME
      export ORACLE_HOME
      exec $CRSHOME/bin/cluvfy "$@" 
      exit $?
   fi
   $ECHO "ERROR: "
   $ECHO "Oracle Grid Infrastructure not configured. "
   $ECHO "You cannot run '$0' without the Oracle Grid Infrastructure."
   $ECHO " "
   exit 1
fi
$ECHO "ERROR: "
$ECHO "Command '$0' is being run from an improper Oracle Home."
$ECHO " "
exit 1
