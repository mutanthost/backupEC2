#!/bin/sh
#
# $Header: install/utl/scripts/db/rootPreRequired.sh /main/2 2017/09/19 12:30:11 rfgonzal Exp $
#
# rootPreRequired.sh
#
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    DESCRIPTION
#      This script checks if rootPre.sh execution is required.
#
#    MODIFIED   (MM/DD/YY)
#    rfgonzal    09/13/17 - Bug 26788168 - rootpre.sh is not required for DB in
#                           Solaris
#    davjimen    02/18/16 - Creation
#
UNAME=/bin/uname
PLATFORM="`${UNAME}`";
ROOTPRE_REQUIRED="false";
TYPE="${1}";

# The rootpre.sh is only required in AIX and SunOS platforms
if [ "${PLATFORM}" = "AIX" ] || [ "${PLATFORM}" = "SunOS" ]; then
  ROOTPRE_REQUIRED="true";  
  # bug 26788168 - rootpre.sh is not required for DB in Solaris
  if [ "${TYPE}" = "Database" ] && [ "${PLATFORM}" = "SunOS" ]; then
    ROOTPRE_REQUIRED="false";
  fi
  if [ "${ROOTPRE_REQUIRED}" = "true" ]; then
    # For SunOS, the architecture should be amd64 and Sun Cluster should be running
    if [ "${PLATFORM}" = "SunOS" ]; then
      ISA_INFO="";
      if [ -f '/usr/bin/isainfo' ]; then
        ISA_INFO="`/usr/bin/isainfo -k`";
      fi
      UCMMD_OUT="`/bin/ps -e -u 0 | grep 'ucm[m]d'`";
      if [ "${ISA_INFO}" != "amd64" ] || [ ! -n "${UCMMD_OUT}" ]; then
        ROOTPRE_REQUIRED="false";
      fi 
    fi
  fi

  # Check if oracle.install.skipRootPre=true was passed
  if [ "${ROOTPRE_REQUIRED}" = "true" ]; then
    for ARG in "$@"; do
      CONTAINS_SKIP_ROOTPRE="`/bin/echo ${ARG} | grep 'oracle.install.skipRootPre='`";
      if [ -n "${CONTAINS_SKIP_ROOTPRE}" ]; then
        VAL="`/bin/echo ${ARG} | cut -d '=' -f 2`";
        if [ "${VAL}" = "true" ] || [ "${VAL}" = "TRUE" ] || [ "${VAL}" = "True" ]; then
          ROOTPRE_REQUIRED="false";
        fi
        break;
      fi
    done
  fi

  # Check if SKIP_ROOTPRE is defined
  if [ "${ROOTPRE_REQUIRED}" = "true" ] && [ -n "${SKIP_ROOTPRE}" ]; then
    if [ "${SKIP_ROOTPRE}" = "true" ] || [ "${SKIP_ROOTPRE}" = "TRUE" ] || [ "${SKIP_ROOTPRE}" = "True" ]; then
      ROOTPRE_REQUIRED="false";
    fi
  fi
fi

/bin/echo "${ROOTPRE_REQUIRED}";
