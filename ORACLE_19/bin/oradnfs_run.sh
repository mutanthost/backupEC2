#!/bin/sh
#
# $Header: rdbms/bin/oradnfs_run.sh /main/3 2015/12/05 01:20:35 ntulaban Exp $
#
# oradnfs_run.sh
#
# Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      oradnfs_run.sh -  wrapper script to run oradnfs
#
#    DESCRIPTION
#      wrapper script to run oradnfs 
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    ntulaban    11/01/15 - wrapper script to run oradnfs
#    ntulaban    11/01/15 - Creation
#
#!/bin/sh

OHOME=/u01/app/oracle/product/19.0.0/dbhome_1

ORACLE_HOME=$OHOME
export ORACLE_HOME

if [ ! ${OHOME} ]; then
     echo "****ORACLE_HOME environment variable is not set."
     echo "    ORACLE_HOME should be set to the main"
     echo "    directory that contains Oracle products."
     echo "    Set and export ORACLE_HOME, then re-run."
     exit 1;
fi

PATH=$OHOME/bin:$PATH
export PATH

case ${PATH} in
    "")echo "****PATH environment variable is not set."
        echo "   PATH should be set to ORACLE_HOME/bin"
        echo "   Set and export PATH, then re-run."
        exit 1;;
    *)  ;;
esac

# Set the shared library path for ODM shared libraries
# A few platforms use an environment variable other than LD_LIBRARY_PATH
PLATFORM=`/bin/uname`
case ${PLATFORM} in
HP-UX)
   LD_LIBRARY_PATH=${OHOME}/lib
   export LD_LIBRARY_PATH
   ;;
AIX)
   LIBPATH=${OHOME}/lib:${LIBPATH}
   export LIBPATH
   ;;
Linux)
   LD_LIBRARY_PATH=${OHOME}/lib:${LD_LIBRARY_PATH}
   # Linux ( ppc64 || s390x ) => LD_LIBRARY_PATH lib32
   ARCH=`/bin/uname -m`;
   if [ "${ARCH}" = "ppc64" -o "${ARCH}" = "s390x" ]
   then
     LD_LIBRARY_PATH=${OHOME}/lib32:${LD_LIBRARY_PATH}
   fi
   export LD_LIBRARY_PATH
   ;;
SunOS)
    LD_LIBRARY_PATH_64=${OHOME}/lib:${LD_LIBRARY_PATH_64}
    export LD_LIBRARY_PATH_64
    LD_LIBRARY_PATH=${OHOME}/lib:${LD_LIBRARY_PATH}
    export LD_LIBRARY_PATH
    ;;
OSF1) LD_LIBRARY_PATH=${OHOME}/lib:${LD_LIBRARY_PATH}
      export LD_LIBRARY_PATH
      ;;
Darwin)
      DYLD_LIBRARY_PATH=${OHOME}/lib:${DYLD_LIBRARY_PATH}
      export DYLD_LIBRARY_PATH
      ;;
*)    if [ -d ${OHOME}/lib32 ];
      then
        LD_LIBRARY_PATH=${OHOME}/lib32:${LD_LIBRARY_PATH}
      else
        LD_LIBRARY_PATH=${OHOME}/lib:${LD_LIBRARY_PATH}
      fi
      export LD_LIBRARY_PATH
      ;;
esac

# Turn on monitor mode
set -m

# Run oradnfs with user specified flags
$OHOME/bin/oradnfs "$@"
exit $?

