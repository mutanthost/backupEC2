#!/bin/sh
#
# $Header: install/utl/scripts/db/commonSetup.sh /main/2 2017/07/07 13:19:22 davjimen Exp $
#
# commonSetup.sh
#
# Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      commonSetup.sh - Common Setup shell script.
#
#    DESCRIPTION
#      Contains the common shell script code for Install launch command construction.
#
#    MODIFIED   (MM/DD/YY)
#    davjimen    07/07/17 - only make the xpdyinfo check for interactive
#    davjimen    01/23/17 - Creation
#

# Binaries
UNAME="/bin/uname";
WHOAMI="/usr/bin/whoami";
XDPYINFO="/usr/bin/xdpyinfo";

# Parse arguments to identify common flags.
silent="false";
help="false";
for arg in $*
do
    if [ "$arg" = "-silent" ]; then
       silent="true";
    else
      if [ "$arg" = "-h" -o "$arg" = "-help" ]; then
         help="true";
      fi
    fi
    if [ $silent = "true" -a $help = "true" ]; then
       break;
    fi  
done

# bug 26405571 - only check xdpyinfo for interactive and non-help
if [ "$silent" = "false" -a "$help" = "false" ]; then
  # Check if xdpyinfo is available for non-silent and non-help cases.
  if [ ! -f $XDPYINFO ]; then
      case `$UNAME` in
          AIX)
              XDPYINFO="/usr/bin/X11/xdpyinfo";
          ;;
          HP-UX)
              XDPYINFO="/usr/contrib/bin/X11/xdpyinfo";
          ;;
          Linux)
              XDPYINFO="/usr/X11R6/bin/xdpyinfo";
          ;;
          SunOS)
              XDPYINFO="/usr/openwin/bin/xdpyinfo";
          ;;
      esac
      if [ ! -f $XDPYINFO ]; then
          XDPYINFO="/usr/lpp/tcpip/X11R6/Xamples/clients/xdpyinfo";
          if [ ! -f $XDPYINFO ]; then
              XDPYINFO="xdpyinfo";
          fi
      fi
  fi
  ${XDPYINFO} > /dev/null 2>&1;
  if [ $? -ne 0 ]; then
      echo "ERROR: Unable to verify the graphical display setup. This application requires X display. Make sure that xdpyinfo exist under PATH variable.";
  fi
fi

# Check that the CommonSetup.pm module is available.
CSPL_FILE="${ORACLE_HOME}/bin/CommonSetup.pm";
if [ ! -f "${CSPL_FILE}" ]; then
  echo "ERROR: The Oracle home software is not complete. Ensure the complete software is available at location (${ORACLE_HOME}).";
  exit 1;
fi

# Get the current user name.
USRNAME="";
if [ -f ${WHOAMI} ]; then
  USRNAME="`${WHOAMI}`";
fi

# Check if the current user has perl execution permissions.
PERL_FILE="${ORACLE_HOME}/perl/bin/perl";
PERL_LIB_DIR="${ORACLE_HOME}/perl/lib";
EXEC_PERM="true";
if [ ! -x "${PERL_FILE}" ]; then
  EXEC_PERM="false";
else
  FIND="/bin/find";
  if [ ! -f "${FIND}" ]; then
    FIND="/usr/bin/find";
  fi
  if [ -f "${FIND}" ]; then
    if [ -n "`${FIND} ${PERL_LIB_DIR} ! -executable 2> /dev/null`" ]; then
      EXEC_PERM="false";
    fi
  fi
fi
if [ "${EXEC_PERM}" = "false" ]; then
  if [ "${USRNAME}" = "" ]; then
    echo "ERROR: Unable to continue with the setup. Ensure the current user has execution permission over software home (${ORACLE_HOME}).";
  else
    echo "ERROR: Unable to continue with the setup. Ensure user (${USRNAME}) has execution permission over software home (${ORACLE_HOME}).";
  fi
  exit 1;
fi
