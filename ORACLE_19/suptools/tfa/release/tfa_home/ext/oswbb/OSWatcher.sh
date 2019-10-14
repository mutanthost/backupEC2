#!/bin/sh
######################################################################
# Copyright (c)  2013 by Oracle Corporation
# OSWatcher.sh
# This is the main oswbb program. This program is started by running
# startOSWbb.sh
######################################################################
# Modifications Section:
######################################################################
##     Date        File            Changes
######################################################################
##  04/18/2005                      Baseline version 1.2.1
##
##  05/19/2005     OSWatcher.sh     Add -x option to iostat on linux
##  V1.3.1                          Add code to write pwd to /tmp/osw.hb
##                                  for rac_ddt to find osw archive
##                                  files
##
##  V1.3.2         OSWatcher.sh     Remove -f flag from $TOP for HP Conf
##                                  section. Append -f flag to $TOP when
##                                  running the HP top cmd
##
##  09/29/2006     OSWatcher.sh     Added $PLATFORM key and OSW version
##  V2.0.0                          info to header of all files. This
##                                  will enable parsing by PTA and
##                                  OSWg
##
##  10/03/2006     OSWg.jar         Fixed format problem for device names
##  V2.0.1                          greater than 30 characters
##
##  10/06/2006     OSWg.jar         Fixed linux flag to detect linux
##  V2.0.2                          archive files. Fixed bug  with
##                                  empty lists causing exceptions
##                                  when graphing data on platforms
##                                  other than solaris
##  07/24/2007     OSWatcher.sh     Added enhancements requested by
##  V2.1.0                          linux bde. These include using a
##                                  environment variable to control the
##                                  amount of ps data, changes to top
##                                  and iostat commands, change format
##                                  of filenames to yy.mm.dd, add
##                                  optional flag to compress files.
##                                  Added -D flag for aix iostat
##  07/24/2007     oswlnxtop.sh     Created new file for linux top
##  V2.1.0                          collection.
##  07/24/2007     oswlnxio.sh      Created new file for linux iostat
##  V2.1.0                          collection.
##  07/24/2007     startOSW.sh      Added optional 3rd parameter to
##  V2.1.0                          compress files
##  11/26/2007     oswlnxtop.sh     Fixed bug with awk script. Bug caused
##  V2.1.1                          no output on some linux platforms
##  12/16/2008     OSWg.jar         Fixed problem reading aix
##  V2.1.2                          iostat files
##  06/16/2009     OSWg.jar         Release 3.0 for EXADATA
##  V3.0.0
##  02/11/11       OSWg.jar         Bug Fix for linux iostat spanning
##  V3.0.1                          multiple lines
##  05/04/11                        Fixed directory permission on
##  V3.0.2                          install of osw.tar
##  02/01/12       OSWatcher.sh     Release 4.0 for OSWbb
##  V4.0.0
##  03/01/12       OSWbba.jar       Bug fix for throughput
##  V4.0.1                          analysis
##  03/06/12       OSWbba.jar       Bug fix for timestamp
##  V4.0.2
##  06/18/12       OSWatcher.sh     Release 5.0 for oswbb
##  V5.0.0
##  06/18/12       OSWatcher.sh     Release 5.1 for oswbb
##  V5.1.0                          added nfs collection
##                                  for linux
##  V5.1.1         OSWbba.jar       Ignore compressed files
##  08/22/12                        when analyzing
##  V5.2.0         OSWatcher.sh     Multiple bug fix release
##  11/7/12                         fix vmstat inserting corrupt data
##                 oswbba.jar       fix linux memory status = unknown
##  01/8/12        OSWatcher.sh     Release 6.0 for oswbb
##  V6.0
##  02/20/12       OSWatcher.sh     fix for blank lines in extras.txt 
##  V6.0.1                          causing errors
##  10/17/13       OSWatcher.sh     Release 7.0 for oswbb
##  V7.0   
##  01/08/14       OSWatcher.sh     Release 7.1 for oswbb
##  V7.1   
##  04/29/14       OSWatcher.sh     Release 7.2 for oswbb
##  V7.2.0   
##  05/28/14       OSWatcher.sh     fix bug in ifconfig directory name
##  V7.3.0   
##  09/05/14       OSWatcher.sh     fix bug with oswifconfig directory
##  V7.3.1         OSWatcherFM.sh   not purging 
##  09/05/14       OSWatcherFM.sh   fix bug with oswnfs directory which
##  V7.3.1                          was accidentally introduced in last 
##                                  release
##  09/17/14       OSWatcher.sh     fix bug for oswnfs directory
##  V7.3.2              
##  02/27/17       OSWatcher.sh     fix bug in AIX top collection.
##  V7.3.3                          all add support for all
##                                  internation date support
##  04/21/17       OSwatcher.sh
##  V8.0.0         OSWatcherFM.sh   Release 8.0.0
##  05/16/17       OSwatcher.sh     fix bug with auto traceroute
##  V8.0.1                          config for RAC
######################################################################

snapshotInterval=$1
archiveInterval=$2
zipfiles=0
status=0
vmstatus=0
mpstatus=0
iostatus=0
nfs_collect=0
ifconfig_collect=0
ifconfigstatus=0
nfsstatus=0
psstatus=0
psmemstatus=0
netstatus=0
topstatus=0
rdsstatus=0
ibstatus=0
ZERO=0
PS_MULTIPLIER_COUNTER=0
PRSTAT_FOUND=0
ioheader=1
zip=$3
lasthour="0"
ARCHIVE_FOUND=0
lineCounter1=1
lineCounter2=1
diff=1
PLATFORM=`/bin/uname`
hostn=`hostname`
version="v8.0.1"
qMax=0
CYAN="\033[1;36;40m"
NORM="\033[0m"
loopback='127.0.0.1'

######################################################################
# CPU COUNT
# The CPU core count (core_count) is used by oswbba analyzer to look  
# for cpu issues. The CPU core count is determined by running OS 
# specific commands in the (Discovery of CPU COUNT section). The 
# virtual CPU count or thread count (vcp_count) is also determined by 
# running OS specific commands. In the case these commands fail 
# because of system privs, the core_count and vcp_count can be 
# manually set below by changing these values to the number of cpu
# cores and threads.
######################################################################

core_count=0
vcpu_count=0


######################################################################
# oswbba time stamp format
# This parameter allows oswbba to analyze files using a standardized
# time stamp format. Setting oswgCompliance=1 sets the time stamp to a
# standard ENGLISH time format. if you do not want oswbba to analyze
# your files or you want to use your own time stamp format you can
# overide and set this value to 0
######################################################################

oswgCompliance=1

######################################################################
# ifconfig -a collection
# This parameter enables ifconfig -a data collection using
# ifconfig -a. Default is 1 for collect. Set this parameter to 0
# to disable this collection
######################################################################

ifconfig_collect=1

######################################################################
# Iostat nfs collection
# This parameter creates additional iostat data collection using
# iostat -nk for linux only. Default is 0 for not collect. Set this
# parameter to 1 to enable this collection
######################################################################

nfs_collect=0


######################################################################
# Loading input variables
######################################################################
test $1
if [ $? = 1 ]; then
    echo
    echo "Info...You did not enter a value for snapshotInterval."
    echo "Info...Using default value = 30"
    snapshotInterval=30
fi
test $2
if [ $? = 1 ]; then
    echo "Info...You did not enter a value for archiveInterval."
    echo "Info...Using default value = 48"
    archiveInterval=48
fi

test $3
if [ $? != 1 ]; then
  if [ `echo $3 |grep "NONE"` ]; then
    zipfiles=0
  else
    echo "Info...Zip option IS specified. "
    echo "Info...OSW will use "$zip" to compress files."
    zipfiles=1
  fi
fi

test $4
if [ $? != 1 ]; then
  if [ ! -d $4 ]; then
    echo "The archive directory you specified for parameter 4 in startOSWbb.sh:"$4" does not exist. Please create this directory and rerun ./startOSWbb.sh"
    exit
  else
   ARCHIVE_FOUND=1
   OSWBB_ARCHIVE_DEST=$4
  fi
fi

######################################################################
# Now check to see if snapshotInterval and archiveInterval are valid
######################################################################

test $snapshotInterval
if [ $snapshotInterval -lt 1 ]; then
    echo "Warning...Invalid value for snapshotInterval. Overriding with default value = 30"
    snapshotInterval=30
fi
test $archiveInterval
if [ $archiveInterval -lt 1 ]; then
    echo "Warning...Invalid value for archiveInterval . Overriding with default value = 48"
    archiveInterval=48
fi

######################################################################
# Now check to see if unix environment variable
# OSW_PS_SAMPLE_MULTIPLIER has been set
######################################################################

tst=`env | grep OSW_PS_SAMPLE_MULTIPLIER | wc -c`
if [ $tst = $ZERO ];
then
  PS_MULTIPLIER=0 
else
  PS_MULTIPLIER=$OSW_PS_SAMPLE_MULTIPLIER
fi

######################################################################
# Now check to see if unix environment variable
# OSWBB_ARCHIVE_DEST has been set. If not, then set default value
# to be archive subdirectory under oswbb.
######################################################################

if [ $ARCHIVE_FOUND = $ZERO ];
then
fdir=`env | grep OSWBB_ARCHIVE_DEST | wc -c`
if [ $fdir = $ZERO ];
then
  OSWBB_ARCHIVE_DEST=`pwd`/archive
else
if [ ! -d $OSWBB_ARCHIVE_DEST ]; then
  echo "The archive directory you specified in OSWBB_ARCHIVE_DEST does not exist"
  echo "Please create this directory and rerun ./startOSWbb.sh"
  exit
fi
fi
echo "Setting the archive log directory to"$OSWBB_ARCHIVE_DEST
fi
######################################################################
# Add check for EXADATA Node. OSW must be run as root user else
# nodify and do not collect additional EXADATA stats and exit
######################################################################

grep node:STORAGE /opt/oracle.cellos/image.id > /dev/null 2>&1

if [ $? = 0 ]; then
  echo "EXADATA found on your system."
  XFOUND=1
else
  XFOUND=0
fi

if [ $XFOUND = 1 ]; then

  AWK=/usr/bin/awk
  RUID=`/usr/bin/id|$AWK -F\( '{print $2}'|$AWK -F\) '{print $1}'`
  if [ ${RUID} != "root" ];then

    echo "You must be logged in as root to run OSWatcher for EXADATA."
    echo "No EXADATA stats will be collected."
    echo "Log in as root and restart OSWatcher."
    exit

  fi

fi

######################################################################
# Add check for any additional collections as specified in the file
# extras.txt. Load these values into an array for processing during
# snapshot interval. Create subdirectories if they do not already exist
######################################################################

if [ -f extras.txt ]; then
q=1
exec 9<&0 < extras.txt
while read myline
do

  xshell=`echo $myline | awk '{print $1}'`
  xcmd=`echo $myline | awk '{print $2}'`
  xdir=`echo $myline | awk '{print $3}'`
  xparm1=`echo $myline | awk '{print $4}'`
  xparm2=`echo $myline | awk '{print $5}'`
  xparm3=`echo $myline | awk '{print $6}'`
  xparm4=`echo $myline | awk '{print $7}'`
  xparm5=`echo $myline | awk '{print $8}'`

  if [ -n "$xshell" ]; then

    if [ $xshell != "#" ]; then
      eval array$q=$q
      eval xshell$q=$xshell
      eval xcmd$q=$xcmd
      eval xdir$q=$xdir
     
#     Create log subdirectories if they don't exist. 

      if [ ! -d $OSWBB_ARCHIVE_DEST/$xdir ]; then
        mkdir -p $OSWBB_ARCHIVE_DEST/$xdir    
      fi
      
      eval xparm1$q=$xparm1
      eval xparm2$q=$xparm2
      eval xparm3$q=$xparm3
      eval xparm4$q=$xparm4
      eval xparm5$q=$xparm5
             
      qMax=$q
      q=`expr $q + 1`
    fi

  fi

done 
exec 0<&9 9<&- 

fi

######################################################################
# Create log subdirectories if they don't exist. Also create oswbba
# subdirectories if they don't exist.
######################################################################

path=`pwd`

if [ $path = "/" ]; then
  echo "You can not run oswbb from the root directory"
  exit
else
  rm -rf tmp
fi

if [ ! -d $OSWBB_ARCHIVE_DEST ]; then
        mkdir $OSWBB_ARCHIVE_DEST
fi
if [ ! -d $OSWBB_ARCHIVE_DEST/oswps ]; then
        mkdir -p $OSWBB_ARCHIVE_DEST/oswps
fi
if [ ! -d $OSWBB_ARCHIVE_DEST/oswtop ]; then
        mkdir -p $OSWBB_ARCHIVE_DEST/oswtop
fi
if [ ! -d $OSWBB_ARCHIVE_DEST/oswnetstat ]; then
        mkdir -p $OSWBB_ARCHIVE_DEST/oswnetstat
fi
if [ ! -d $OSWBB_ARCHIVE_DEST/oswiostat ]; then
        mkdir -p $OSWBB_ARCHIVE_DEST/oswiostat
fi
if [ ! -d $OSWBB_ARCHIVE_DEST/oswnfs ]; then
  if [ $nfs_collect = 1 ]; then
     case $PLATFORM in
     Linux)
        mkdir -p $OSWBB_ARCHIVE_DEST/oswnfs
  ;;
  esac
  fi
fi
if [ ! -d $OSWBB_ARCHIVE_DEST/oswvmstat ]; then
        mkdir -p $OSWBB_ARCHIVE_DEST/oswvmstat
fi
if [ ! -d $OSWBB_ARCHIVE_DEST/oswmpstat ]; then
        mkdir -p $OSWBB_ARCHIVE_DEST/oswmpstat
fi
if [ ! -d $OSWBB_ARCHIVE_DEST/oswprvtnet ]; then
        mkdir -p $OSWBB_ARCHIVE_DEST/oswprvtnet
fi
if [ ! -d $OSWBB_ARCHIVE_DEST/oswifconfig ]; then
        mkdir -p $OSWBB_ARCHIVE_DEST/oswifconfig
fi
if [ ! -d locks ]; then
        mkdir locks
fi
if [ ! -d tmp ]; then
        mkdir tmp
fi


######################################################################
# Create additional EXADATA subdirectories if they don't exist
######################################################################
if [ $XFOUND = 1 ]; then

  if [ ! -d $OSWBB_ARCHIVE_DEST/osw_ib_diagnostics ]; then
        mkdir -p $OSWBB_ARCHIVE_DEST/osw_ib_diagnostics
  fi

  if [ ! -d $OSWBB_ARCHIVE_DEST/osw_rds_diagnostics ]; then
        mkdir -p $OSWBB_ARCHIVE_DEST/osw_rds_diagnostics
  fi

fi

######################################################################
# Create additional linux subdirectories if they don't exist
######################################################################
case $PLATFORM in
  Linux)
    mkdir -p $OSWBB_ARCHIVE_DEST/oswmeminfo
    mkdir -p $OSWBB_ARCHIVE_DEST/oswslabinfo
  ;;
esac

######################################################################
# Remove lock.file if it exists
######################################################################
if [ -f locks/vmlock.file ]; then
  rm locks/vmlock.file
fi
if [ -f locks/mplock.file ]; then
  rm locks/mplock.file
fi
if [ -f locks/pslock.file ]; then
  rm locks/pslock.file
fi
if [ -f locks/toplock.file ]; then
  rm locks/toplock.file
fi
if [ -f locks/iolock.file ]; then
  rm locks/iolock.file
fi
if [ -f locks/nfslock.file ]; then
  rm locks/nfslock.file
fi
if [ -f locks/ifconfiglock.file ]; then
  rm locks/ifconfiglock.file
fi
if [ -f locks/netlock.file ]; then
  rm locks/netlock.file
fi
if [ -f locks/rdslock.file ]; then
  rm locks/rdslock.file
fi
if [ -f locks/iblock.file ]; then
  rm locks/iblock.file
fi
if [ -f tmp/xtop.tmp ]; then
  rm tmp/xtop.tmp
fi
if [ -f tmp/vtop.tmp ]; then
  rm tmp/vtop.tmp
fi
if [ -f locks/lock.file ]; then
  rm locks/lock.file
fi

######################################################################
# CONFIGURATION  Determine Host Platform
#
# Starting in release 4.0, TOP parameters are now configured in the file
# xtop.sh. This was changed because 2 snapshots of top are required
# because the first sample is since system startup and is now
# discarded with only the second sample being being saved in the
# oswtop directory. The previous top commands still exist in this
# section and are used only for the discovery of top on your system.
# Starting in release 7.0, the ps parameters are configured in file
# psmemsub.sh.
######################################################################
case $PLATFORM in
  Linux)
    IOSTAT='iostat -xk 1 3'
    NFSSTAT='iostat -nk 1 3'
    VMSTAT='vmstat 1 3'
    TOP='eval top -b -n 1 | head -50'
    PSELF='ps -elf'
    MPSTAT='mpstat -P ALL 1 2'
    MEMINFO='cat /proc/meminfo'
    SLABINFO='cat /proc/slabinfo'
    IFCONFIG='ifconfig -a'
    TRACERT="traceroute $loopback"
    ;;
  HP-UX|HI-UX)
    IOSTAT='iostat 1 3'
    VMSTAT='vmstat 1 3'
    TOP='top -d 1'
    PSELF='ps -elf'
    MPSTAT='sar -A -S 1 2'
    IFCONFIG='netstat'
    TRACERT="traceroute $loopback"
    ;;
  SunOS)
    IOSTAT='iostat -xn 1 3'
    VMSTAT='vmstat 1 3 '
    TOP='top -d2 -s1'
    PRSTAT='prstat 1 2'
    PSELF='ps -elf'
    MPSTAT='mpstat 1 2'
    IFCONFIG='ifconfig -a' 
    TRACERT="traceroute $loopback"
    ;;
  AIX)
    IOSTAT='iostat -D 1 3'
    VMSTAT='vmstat  -I 1 3'
    TOP='top -d 1'
    PSELF='ps -elf'
    MPSTAT='mpstat 1 2'
    IFCONFIG='ifconfig -a'  
    TRACERT="traceroute $loopback"
    ;;
  OSF1)
    IOSTAT='iostat 1 3'
    VMSTAT='vmstat 1 3'
    TOP='top -d1'
    PSELF='ps -elf'
    PSMEM='ps -elf'
    MPSTAT='sar -S'
    IFCONFIG='ifconfig -a'    
    ;;
esac

######################################################################
# Test for discovery of os utilities. Notify if not found.
######################################################################
echo ""
echo "Testing for discovery of OS Utilities..."

$VMSTAT > /dev/null 2>&1
if [ $? = 0 ]; then
  echo "VMSTAT found on your system."
  VMFOUND=1
else
  echo "Warning... VMSTAT not found on your system. No VMSTAT data will be collected."
  VMFOUND=0
fi
VMFOUND=1
$IOSTAT > /dev/null 2>&1
if [ $? = 0 ]; then
  echo "IOSTAT found on your system."
  IOFOUND=1

  case $PLATFORM in
   HP-UX|HI-UX)
     iostat 1 1 > tmp/ioh.tmp
     lineCounter1=`cat tmp/ioh.tmp | wc -l | awk '{$1=$1;print}'`
     iostat 1 2 > tmp/ioh.tmp
     lineCounter2=`cat tmp/ioh.tmp | wc -l | awk '{$1=$1;print}'`
     diff=`expr $lineCounter2 - $lineCounter1`
     ioheader=`expr $lineCounter1 - $diff`
     head -$ioheader tmp/ioh.tmp > iostat.header
  ;;
  *)
   x=0
  ;;
  esac

else
  echo "Warning... IOSTAT not found on your system. No IOSTAT data will be collected."
  IOFOUND=0
fi

$MPSTAT > /dev/null 2>&1
if [ $? = 0 ]; then
  echo "MPSTAT found on your system."
  MPFOUND=1
else
  echo "Warning... MPSTAT not found on your system. No MPSTAT data will be collected."
  MPFOUND=0
fi

$IFCONFIG > /dev/null 2>&1
if [ $? = 0 ]; then
  echo "IFCONFIG found on your system."
  IFCONFIGFOUND=1
else
  echo "Warning... IFCONFIG not found on your system. No IFCONFIG data will be collected."
  IFCONFIGFOUND=0
fi

netstat > /dev/null 2>&1
if [ $? = 0 ]; then
  echo "NETSTAT found on your system."
  NETFOUND=1
else
  echo "Warning... NETSTAT not found on your system. No NETSTAT data will be collected."
  NETFOUND=0
fi

case $PLATFORM in
  AIX)
    TOPFOUND=1
    ;;
  SunOS)
    $TOP > /dev/null 2>&1
    if [ $? = 0 ]; then
      echo "TOP found on your system."
      TOPFOUND=1
    else
     $PRSTAT > /dev/null 2>&1
     if [ $? = 0 ]; then
      echo "PRSTAT found on your system."
      PRSTAT_FOUND=1
      TOPFOUND=1
      TOP=$PRSTAT
     else
      echo "Warning... TOP/PRSTAT not found on your system. No TOP data will be collected."
      TOPFOUND=0
     fi
    fi
    ;;
  *)
    $TOP > /dev/null 2>&1
    if [ $? = 0 ]; then
      echo "TOP found on your system."
      TOPFOUND=1
    else
     echo "Warning... TOP not found on your system. No TOP data will be collected."
     TOPFOUND=0
    fi
    ;;
esac

case $PLATFORM in
  Linux)
    $MEMINFO > /dev/null 2>&1
    if [ $? = 0 ]; then
      MEMFOUND=1
    else
      echo "Warning... /proc/meminfo not found on your system."
      MEMFOUND=0
    fi
    $SLABINFO > /dev/null 2>&1
    if [ $? = 0 ]; then
      SLABFOUND=1
    else
      echo "Warning... /proc/slabinfo not found on your system."
      SLABFOUND=0
    fi
  ;;
esac

########################################################################
# TRACEROUTE DISCOVERY
# private.net file configuration.
# Configure private.net if it doesn't exist.
# Configure private.net only if CRS is up and running and ssh 
# is working fine on all Nodes.
##########################################################################
 $TRACERT > /dev/null 2>&1
 if [ $? = 0 ]; then
	echo "TRACEROUTE found on your system."
	       if [ ! -x private.net ]
               then		  
			     if [ -x ssh1.net ]; then
                     rm ssh1.net
				 fi
     CHECK_CRS=`ps -ef | grep crsd.bin | grep -v grep |wc -l`
	
		if [ $CHECK_CRS -eq 1 ]
		  then
		    OSWID=`id | awk '{print $1}' | cut -d"=" -f2 | cut -d"(" -f2 |  cut -d")" -f1`
            GRIDID=`ps -ef |grep ocssd.bin | grep -v grep | awk '{print $1}'`
                if [ $OSWID != $GRIDID ]
                 then
                    printf $CYAN"OS User running OSwatcher is not the same as Oracle Clusterware software owner..private.net will not be configured.\n"$NORM
					printf $CYAN"private.net file is required to monitor private Networks in RAC environment.\n"$NORM
                    printf $CYAN"Kindly configure & run OSWatcher as Oracle Clusterware software owner..\n"$NORM
					printf $CYAN"If you want to run OSWatcher as a different OS User than Oracle Clusterware software owner then configure private.net manually as per OSWatcher README.\n"$NORM 
		             TRACERTFOUND=0
				       else
		           	TRACERTFOUND=1
        HOME=`ps -ef |grep crsd.bin | grep -v grep | awk '{print $9}' | head -1`
        GRID_HOME=`echo $HOME | sed 's/\/bin\/crsd.bin//'`
          if [ "$GRID_HOME" = "reboot" ] || [ "GRID_HOME" = "restart" ]
          then
       HOME=`ps -ef |grep crsd.bin | grep -v grep | awk '{print $8}' | head -1`
       GRID_HOME=`echo $HOME | sed 's/\/bin\/crsd.bin//'`
          fi
            for list in `$GRID_HOME/bin/olsnodes`
               do
                 MEMBER=$MEMBER:$list
               done
              COUNT=`echo $MEMBER | tr -dc ":"|wc -c | sed -e 's/^[ \t]*//'`
             printf $CYAN"Number of RAC Nodes: $COUNT\n"$NORM
			 printf "\n"
		    printf $CYAN"The following Nodes are members of RAC Cluster:\n"$NORM
      for name in `$GRID_HOME/bin/olsnodes`
         do
    HOST=`hostname |cut -d"." -f1`
       if [ "$name" = "$HOST" ]
         then
    LOCAL=$name
      else
   REMOTE=$REMOTE:$name
       fi
       done
  NEW_REMOTE=`echo $REMOTE | sed 's/://'`
     if [ "$LOCAL" = "$HOST" ]
      then
       printf $CYAN"Local Node: $LOCAL\n"$NORM
       printf $CYAN"Remote Node(s): $NEW_REMOTE\n"$NORM
	   printf "\n"
       printf $CYAN" CRS is up and running on local Node\n"$NORM
	   printf "\n"
     fi

   for var in `$GRID_HOME/bin/olsnodes`
     do
   MEM=$MEM:$var
     done
    TOTAL=`echo $MEM | tr -dc ":"|wc -c`
    TOTAL=`expr $TOTAL + 1`
  i=2
    while [ $i -le "$TOTAL" ]
    do 
     NODE=`echo $MEM | cut -d":" -f$i`
    echo "/usr/bin/ssh -o FallBackToRsh=no  -o PasswordAuthentication=no  -o StrictHostKeyChecking=yes  -o NumberOfPasswordPrompts=0  $NODE -n /bin/true >/dev/null 2>&1" >> ssh1.net
    echo "if [ \$? != 0 ]; then exit 1; fi" >> ssh1.net
     i=`expr $i + 1`
    done
 chmod +x ssh1.net

./ssh1.net

  if [ "$?" = 0 ]
  then
    printf $CYAN"ssh test is successful on all RAC Nodes.\n"$NORM
        TRACERTFOUND=1
		LINK=`$GRID_HOME/bin/oifcfg getif | grep cluster | awk '{print $1}'`
         if [ ! -z $LINK ]
	       then
            ./genprvnet.sh
			printf $CYAN"Private.net configured on local node !\n"$NORM
	      else
		 printf $CYAN"Cluster Interconnect not configured in Oracle Cluster Registry(OCR).Private.net will not be configured on local node.\n"$NORM
		 printf $CYAN"Configure private.net manually as per the OSWatcher README.\n"$NORM
		      TRACERTFOUND=0
     fi
  else
        printf $CYAN"ssh is having some issue on Local/Remote Nodes.Private.net file will not be configured on local node.\n"$NORM
       printf $CYAN"Ensure passwordless ssh connectivity works on all RAC Nodes and then restart the OSWatcher.\n"$NORM
	    printf $CYAN"If ssh issue cannot be identified then configure private.net file manually as per the OSWatcher README.\n"$NORM
        TRACERTFOUND=0
     fi
        fi
  else
    v_oratab="/etc/oratab"
 case `/bin/uname` in
    SunOS)
      v_oratab="/var/opt/oracle/oratab"
  esac
GHOME=`cat $v_oratab | grep "^+ASM" | grep -v grep | head -1 | cut -d":" -f2`
$GHOME/bin/crsctl check crs >/dev/null 2>&1
 if [ "$?" = 0 ]
    then
     printf $CYAN" Warning: Oracle Clusterware detection failed on this Node..private.net file will not be configured on local node.\n"$NORM
    printf $CYAN" private.net file is required to monitor private Networks in RAC environment.\n"$NORM
    printf $CYAN"If this Node is a member of multi Node RAC Cluster then start the CRS Stack.Otherwise configure private.net manually as per OSWatcher README.\n"$NORM
	   fi
			TRACERTFOUND=2
		fi
         else
            printf $CYAN"private.net already exists !\n"$NORM
		    TRACERTFOUND=1
       fi	
 else
	  printf $CYAN"Warning... TRACEROUTE not found on your system. No TRACEROUTE data will be collected.\n"$NORM
     	    TRACERTFOUND=0
	  
     fi

######################################################################
# Discovery of CPU COUNT. Notify if not found.
######################################################################

echo ""
if [ $core_count = 0 ]; then

echo "Discovery of CPU CORE COUNT"
echo "CPU CORE COUNT will be used by oswbba to automatically look for cpu problems"
echo ""
case $PLATFORM in
  Linux)
    vcpu_count=`cat /proc/cpuinfo|grep processor|wc -l`
    core_count=`cat /proc/cpuinfo | egrep "core id" | sort | uniq | wc -l`

    ;;
  HP-UX|HI-UX)
    vcpu_count=`/usr/sbin/ioscan -kC processor | grep processor | wc -l`
    core_count=`/usr/sbin/ioscan -kC processor | grep processor | wc -l`
    ;;
  SunOS)
    vcpu_count=`/usr/sbin/psrinfo -v|grep "on-line"|wc -l`
    core_count=`kstat cpu_info | grep core_id | uniq | wc -l`
    ;;
  AIX)
    vcpu_count=`mpstat | grep lcpu | awk '{print $3}'`
    core_count=`/usr/sbin/lsdev -C|grep Process|wc -l`
    ;;
  OSF1)

    ;;
esac


if [ $core_count -gt 0 ]; then
  echo "CPU CORE COUNT =" $core_count
  echo "VCPUS/THREADS =" $vcpu_count
else
  echo " "
  echo "Warning... CPU CORE COUNT not found on your system."
  echo " "
  echo " "
  echo "Defaulting to CPU CORE COUNT = 1"
  echo "To correctly specify CPU CORE COUNT"
  echo "1. Correct the error listed above for your unix platform or"
  echo "2. Manually set core_count on OSWatcher.sh line 16 or"
  echo "3. Do nothing and accept default value = 1"
  core_count=1
fi

else
  echo "Maunal override of CPU CORE COUNT in effect"
  echo "CPU CORE COUNT =" $core_count
fi

echo ""
echo "Discovery completed."
echo ""
sleep 15
echo "Starting OSWatcher "$version " on "`date`
echo "With SnapshotInterval = "$snapshotInterval
echo "With ArchiveInterval = "$archiveInterval
echo ""
echo "OSWatcher - Written by Carl Davis, Center of Expertise,"
echo "Oracle Corporation"
echo "For questions on install/usage please go to MOS (Note:301137.1)"
echo "If you need further assistance or have comments or enhancement"
echo "requests you can email me Carl Davis"
sleep 5
echo ""
echo "Data is stored in directory: "$OSWBB_ARCHIVE_DEST
echo ""
echo "Starting Data Collection..."
echo ""

######################################################################
# Start OSWFM the File Manager Process
######################################################################
./OSWatcherFM.sh $archiveInterval $OSWBB_ARCHIVE_DEST &
######################################################################
# Loop Forever
######################################################################

until test 0 -eq 1
do
echo "oswbb heartbeat:"`date`
pwd > /tmp/osw.hb
echo $OSWBB_ARCHIVE_DEST >> /tmp/osw.hb

######################################################################
# Generate generic log file string depending on what hour of the day
# it is. Have 1 report per hour per operation.
######################################################################
#hour=`date +'%m.%d.%y.%H00.dat'`
hour=`date +'%y.%m.%d.%H00.dat'`

######################################################################
# VMSTAT
######################################################################
if [ $VMFOUND = 1 ]; then
  if [ $hour != $lasthour ]; then
    echo $PLATFORM OSWbb $version $hostn >> $OSWBB_ARCHIVE_DEST/oswvmstat/${hostn}_vmstat_$hour
    echo "SNAP_INTERVAL" $snapshotInterval  >> $OSWBB_ARCHIVE_DEST/oswvmstat/${hostn}_vmstat_$hour
    echo "CPU_CORES" $core_count  >> $OSWBB_ARCHIVE_DEST/oswvmstat/${hostn}_vmstat_$hour
    echo "VCPUS" $vcpu_count  >> $OSWBB_ARCHIVE_DEST/oswvmstat/${hostn}_vmstat_$hour
    echo "OSWBB_ARCHIVE_DEST" $OSWBB_ARCHIVE_DEST  >> $OSWBB_ARCHIVE_DEST/oswvmstat/${hostn}_vmstat_$hour
    if [ $zipfiles = 1 ]; then
      if [ -f  $OSWBB_ARCHIVE_DEST/oswvmstat/${hostn}_vmstat_$lasthour ]; then
       $zip $OSWBB_ARCHIVE_DEST/oswvmstat/${hostn}_vmstat_$lasthour &
       fi
    fi
  fi

  if [ -f locks/vmlock.file ]; then
    vmstatus=1
  else
    touch locks/vmlock.file
    if [ $vmstatus = 1 ]; then
      echo "***Warning. VMSTAT response is spanning snapshot intervals."
      vmstatus=0
    fi
    ./vmsub.sh $OSWBB_ARCHIVE_DEST/oswvmstat/${hostn}_vmstat_$hour "$VMSTAT" $oswgCompliance &

  fi

fi

######################################################################
# MPSTAT
######################################################################
if [ $MPFOUND = 1 ]; then
  if [ $hour != $lasthour ]; then
    echo $PLATFORM OSWbb $version  >> $OSWBB_ARCHIVE_DEST/oswmpstat/${hostn}_mpstat_$hour
    if [ $zipfiles = 1 ]; then
      if [ -f  $OSWBB_ARCHIVE_DEST/oswmpstat/${hostn}_mpstat_$lasthour ]; then
        $zip $OSWBB_ARCHIVE_DEST/oswmpstat/${hostn}_mpstat_$lasthour &
      fi
    fi
  fi


  if [ -f locks/mplock.file ]; then
    mpstatus=1
  else
    touch locks/mplock.file
    if [ $mpstatus = 1 ]; then
      echo "***Warning. MPSTAT response is spanning snapshot intervals."
      mpstatus=0
    fi
   ./mpsub.sh $OSWBB_ARCHIVE_DEST/oswmpstat/${hostn}_mpstat_$hour "$MPSTAT" $oswgCompliance &

  fi

fi

######################################################################
# NETSTAT
# NETSTAT configured in oswnet.sh file
######################################################################
if [ $NETFOUND = 1 ]; then
  if [ $hour != $lasthour ]; then
    echo $PLATFORM OSWbb $version >> $OSWBB_ARCHIVE_DEST/oswnetstat/${hostn}_netstat_$hour
    if [ $zipfiles = 1 ]; then
      if [ -f  $OSWBB_ARCHIVE_DEST/oswnetstat/${hostn}_netstat_$lasthour ]; then
        $zip $OSWBB_ARCHIVE_DEST/oswnetstat/${hostn}_netstat_$lasthour &
      fi
    fi
  fi


  if [ -f locks/netlock.file ]; then
    netstatus=1
  else
    touch locks/netlock.file
    if [ $netstatus = 1 ]; then
      echo "***Warning. NETSTAT response is spanning snapshot intervals."
      netstatus=0
    fi
    ./oswnet.sh $OSWBB_ARCHIVE_DEST/oswnetstat/${hostn}_netstat_$hour $oswgCompliance &

  fi

fi

######################################################################
# IOSTAT
######################################################################
if [ $IOFOUND = 1 ]; then
  if [ $hour != $lasthour ]; then
    echo $PLATFORM OSWbb $version  >> $OSWBB_ARCHIVE_DEST/oswiostat/${hostn}_iostat_$hour
    case $PLATFORM in
        HP-UX|HI-UX)
          echo "################################################################################" >> $OSWBB_ARCHIVE_DEST/oswiostat/${hostn}_iostat_$hour
          echo "" >> $OSWBB_ARCHIVE_DEST/oswiostat/${hostn}_iostat_$hour
          echo "Note: Additional i/o data is collected by sar and has been placed in the" >> $OSWBB_ARCHIVE_DEST/oswiostat/${hostn}_iostat_$hour
          echo "oswmpstat directory. Please review this additional data." >> $OSWBB_ARCHIVE_DEST/oswiostat/${hostn}_iostat_$hour
          echo "" >> $OSWBB_ARCHIVE_DEST/oswiostat/${hostn}_iostat_$hour
          echo "################################################################################" >> $OSWBB_ARCHIVE_DEST/oswiostat/${hostn}_iostat_$hour
        ;;
        *)
         x=0
        ;;
    esac
    if [ $zipfiles = 1 ]; then
      if [ -f  $OSWBB_ARCHIVE_DEST/oswiostat/${hostn}_iostat_$lasthour ]; then
        $zip $OSWBB_ARCHIVE_DEST/oswiostat/${hostn}_iostat_$lasthour &
      fi
    fi

  fi


  if [ -f locks/iolock.file ]; then
    iostatus=1
  else
    touch locks/iolock.file
    if [ $iostatus = 1 ]; then
      echo "***Warning. IOSTAT response is spanning snapshot intervals."
      iostatus=0
    fi

    ./iosub.sh $OSWBB_ARCHIVE_DEST/oswiostat/${hostn}_iostat_$hour "$IOSTAT" $oswgCompliance &

  fi

fi

######################################################################
# LINUX NFS IOSTAT
######################################################################
if [ $nfs_collect = 1 ]; then

  if [ $hour != $lasthour ]; then
    echo $PLATFORM OSWbb $version  >> $OSWBB_ARCHIVE_DEST/oswnfs/${hostn}_nfs_$hour

    if [ $zipfiles = 1 ]; then
      if [ -f  $OSWBB_ARCHIVE_DEST/oswnfs/${hostn}_nfs_$lasthour ]; then
        $zip $OSWBB_ARCHIVE_DEST/oswnfs/${hostn}_nfs_$lasthour &
      fi
    fi

  fi


  if [ -f locks/nfslock.file ]; then
    nfsstatus=1
  else
    touch locks/nfslock.file
    if [ $nfsstatus = 1 ]; then
      echo "***Warning. IOSTAT NFS response is spanning snapshot intervals."
      nfsstatus=0
    fi

    ./nfssub.sh $OSWBB_ARCHIVE_DEST/oswnfs/${hostn}_nfs_$hour "$NFSSTAT" $oswgCompliance &

  fi
fi

######################################################################
# IFCONFIG
######################################################################
if [ $IFCONFIGFOUND = 1 ]; then

if [ $ifconfig_collect = 1 ]; then

  if [ $hour != $lasthour ]; then
    echo $PLATFORM OSWbb $version  >> $OSWBB_ARCHIVE_DEST/oswifconfig/${hostn}_ifconfig_$hour

    if [ $zipfiles = 1 ]; then
      if [ -f  $OSWBB_ARCHIVE_DEST/oswifconfig/${hostn}_ifconfig_$lasthour ]; then
        $zip $OSWBB_ARCHIVE_DEST/oswifconfig/${hostn}_ifconfig_$lasthour &
      fi
    fi

  fi


  if [ -f locks/ifconfiglock.file ]; then
    ifconfigstatus=1
  else
    touch locks/ifconfiglock.file
    if [ $ifconfigstatus = 1 ]; then
      echo "***Warning. IFCONFIG response is spanning snapshot intervals."
      ifconfigstatus=0
    fi

    ./ifconfigsub.sh $OSWBB_ARCHIVE_DEST/oswifconfig/${hostn}_ifconfig_$hour "$IFCONFIG" $oswgCompliance &

  fi
fi
fi

######################################################################
# TOP
######################################################################
if [ $TOPFOUND = 1 ]; then

  if [ $hour != $lasthour ]; then
    echo $PLATFORM  OSWbb $version >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour
    case $PLATFORM in
        AIX)
           echo "################################################################################" >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour
           echo "" >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour
           echo "Note: When reviewing LPAR process cpu usage, look at the C column." >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour 
           echo "This column indicates how many ticks of CPU the command has used recently." >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour
           echo "" >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour
           echo "It is specifically defined as:" >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour
           echo "C: CPU utilization of process or thread, incremented each time the system clock " >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour
           echo "ticks and the process or thread is found to be running. The value is decayed " >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour
           echo "by the scheduler by dividing it by 2 once per second. For the sched_other " >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour
           echo "policy, CPU utilization is used in determining process scheduling priority." >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour 
           echo "Large values indicate a CPU intensive process and result in lower process " >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour
           echo "priority, whereas small values indicate an I/O intensive process and result" >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour
           echo "in a more favorable priority." >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour
           echo "" >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour
           echo "AIX uses this value along with the process base priority and nice value to " >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour
           echo "compute new effective thread/process priorities. The OSW data is sorted on" >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour
           echo "this column in reverse numberical order. This gives you the top N CPU users" >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour
           echo "in the last 2-3 seconds:" >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour
 
           echo "" >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour
           echo "################################################################################" >> $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour
        ;;
        *)
         x=0
        ;;
    esac    
    
    if [ $zipfiles = 1 ]; then
      if [ -f  $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$lasthour ]; then
        $zip $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$lasthour &
      fi
    fi
  fi

  if [ -f locks/toplock.file ]; then
    topstatus=1
  else
    touch locks/toplock.file
    if [ $topstatus = 1 ]; then
      echo "***Warning. TOP response is spanning snapshot intervals."
      topstatus=0
    fi
    case $PLATFORM in
      AIX)
        ./topaix.sh $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour $oswgCompliance
      ;;
      Linux)
      ./xtop.sh $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour $oswgCompliance &
      ;;
      HP-UX|HI-UX)
        x=0
      ;;
      *)
        ./xtop.sh $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour $oswgCompliance $PRSTAT_FOUND &
    ;;
    esac
  fi

# no file check for HP. Move code outside test above

  case $PLATFORM in
      HP-UX|HI-UX)
    ./xtop.sh $OSWBB_ARCHIVE_DEST/oswtop/${hostn}_top_$hour $oswgCompliance &
    ;;
      *)
        x=0
    ;;
  esac

fi

######################################################################
# PS -ELF
######################################################################
  if [ $hour != $lasthour ]; then
    echo $PLATFORM  OSWbb $version >> $OSWBB_ARCHIVE_DEST/oswps/${hostn}_ps_$hour
    if [ $zipfiles = 1 ]; then
      if [ -f  $OSWBB_ARCHIVE_DEST/oswps/${hostn}_ps_$lasthour ]; then
        $zip $OSWBB_ARCHIVE_DEST/oswps/${hostn}_ps_$lasthour &
      fi
    fi
  fi

  if [ -f locks/pslock.file ]; then
    psstatus=1
  else
    touch locks/pslock.file
    if [ $psstatus = 1 ]; then
      echo "***Warning. PS response is spanning snapshot intervals."
      psstatus=0
    fi

    if [ $PS_MULTIPLIER -gt $ZERO ]; then

      if [ $PS_MULTIPLIER_COUNTER -eq $ZERO ]; then
          ./psmemsub.sh $OSWBB_ARCHIVE_DEST/oswps/${hostn}_ps_$hour "$PSELF" $oswgCompliance &
      else
        rm locks/pslock.file
      fi
      PS_MULTIPLIER_COUNTER=`expr $PS_MULTIPLIER_COUNTER + 1`
      if [ $PS_MULTIPLIER_COUNTER -eq  $PS_MULTIPLIER ]; then
           PS_MULTIPLIER_COUNTER=0
      fi
    else
      ./psmemsub.sh $OSWBB_ARCHIVE_DEST/oswps/${hostn}_ps_$hour "$PSELF" $oswgCompliance &
    fi

  fi
  
######################################################################
# Additional Linux Only Collection
######################################################################
case $PLATFORM in
  Linux)
  if [ $MEMFOUND = 1 ]; then
    ./oswsub.sh $OSWBB_ARCHIVE_DEST/oswmeminfo/${hostn}_meminfo_$hour "$MEMINFO" $oswgCompliance &
  fi
  if [ $SLABFOUND = 1 ]; then
    ./oswsub.sh $OSWBB_ARCHIVE_DEST/oswslabinfo/${hostn}_slabinfo_$hour "$SLABINFO" $oswgCompliance &
  fi

  if [ $hour != $lasthour ]; then
    if [ $zipfiles = 1 ]; then
      if [ -f $OSWBB_ARCHIVE_DEST/oswmeminfo/${hostn}_meminfo_$lasthour  ]; then
        $zip $OSWBB_ARCHIVE_DEST/oswmeminfo/${hostn}_meminfo_$lasthour &
      fi
      if [ -f $OSWBB_ARCHIVE_DEST/oswslabinfo/${hostn}_slabinfo_$lasthour  ]; then
        $zip $OSWBB_ARCHIVE_DEST/oswslabinfo/${hostn}_slabinfo_$lasthour &
      fi
    fi
  fi
  ;;
esac

######################################################################
# EXADATA
######################################################################
if [ $XFOUND = 1 ]; then
  if [ $hour != $lasthour ]; then
    echo $PLATFORM OSWbb $version $hostn >> $OSWBB_ARCHIVE_DEST/osw_ib_diagnostics/${hostn}_ib_$hour
    if [ $zipfiles = 1 ]; then
      if [ -f  $OSWBB_ARCHIVE_DEST/osw_ib_diagnostics/${hostn}_ib_$lasthour ]; then
       $zip $OSWBB_ARCHIVE_DEST/osw_ib_diagnostics/${hostn}_ib_$lasthour &
       fi
    fi
  fi

  if [ -f locks/iblock.file ]; then
    ibstatus=1
  else
    touch locks/iblock.file
    if [ $ibstatus = 1 ]; then
      echo "***Warning. IB DIAGNOSTICS response is spanning snapshot intervals."
      ibstatus=0
    fi

     ./oswib.sh $OSWBB_ARCHIVE_DEST/osw_ib_diagnostics/${hostn}_ib_$hour &

  fi



  if [ $hour != $lasthour ]; then
    echo $PLATFORM OSWbb $version $hostn >> $OSWBB_ARCHIVE_DEST/osw_rds_diagnostics/${hostn}_rds_$hour
    if [ $zipfiles = 1 ]; then
      if [ -f  $OSWBB_ARCHIVE_DEST/osw_rds_diagnostics/${hostn}_rds_$lasthour ]; then
       $zip $OSWBB_ARCHIVE_DEST/osw_rds_diagnostics/${hostn}_rds_$lasthour &
       fi
    fi
  fi

  if [ -f locks/rdslock.file ]; then
    rdsstatus=1
  else
    touch locks/rdslock.file
    if [ $rdsstatus = 1 ]; then
      echo "***Warning. VMSTAT response is spanning snapshot intervals."
      rdsstatus=0
    fi

    ./oswrds.sh $OSWBB_ARCHIVE_DEST/osw_rds_diagnostics/${hostn}_rds_$hour &

  fi

fi

######################################################################
# Run traceroute for private networks if file private.net exists
######################################################################
if [ -x private.net ]; then
  if [ -f locks/lock.file ]; then
    status=1
  else
    touch locks/lock.file
    if [ $status = 1 ]; then
      echo "zzz ***Warning. Traceroute response is spanning snapshot intervals." >> $OSWBB_ARCHIVE_DEST/oswprvtnet/${hostn}_prvtnet_$hour &
      status=0
    fi
   ./private.net >> $OSWBB_ARCHIVE_DEST/oswprvtnet/${hostn}_prvtnet_$hour 2>&1 &
  fi
  if [ $hour != $lasthour ]; then
    if [ $zipfiles = 1 ]; then
      if [ -f $OSWBB_ARCHIVE_DEST/oswprvtnet/${hostn}_prvtnet_$lasthour  ]; then
        $zip $OSWBB_ARCHIVE_DEST/oswprvtnet/${hostn}_prvtnet_$lasthour &
      fi
    fi
  fi
fi

##################################################################
# private.net file configuration during OSWatcher heartbeat.
# Configure private.net if it doesn't exist.
# Configure private.net only if CRS is up and running and ssh is 
# working fine on all Nodes.
#################################################################
if [ $TRACERTFOUND = 2 ] && [ ! -x private.net ]
then

	CHECK_CRS=`ps -ef | grep crsd.bin | grep -v grep |wc -l`
	
		if [ $CHECK_CRS = 1 ]
		then
			TRACERTFOUND=1
		fi
fi

if [ $TRACERTFOUND = 1 ] && [ ! -x private.net ] 
  then
         if [ -x ssh2.net ]; then
           rm ssh2.net
         fi
    CHECK_CRS=`ps -ef | grep crsd.bin | grep -v grep |wc -l`
	
  if [ $CHECK_CRS = 1 ]
	  then
	       OSWID=`id | awk '{print $1}' | cut -d"=" -f2 | cut -d"(" -f2 |  cut -d")" -f1`
		    GRIDID=`ps -ef |grep ocssd.bin | grep -v grep | awk '{print $1}'`
                if [ $OSWID != $GRIDID ]
                 then
                    TRACERTFOUND=0
                 else
	      HOME1=`ps -ef |grep crsd.bin | grep -v grep | awk '{print $9}' | head -1`
           GRID_HOME1=`echo $HOME1 | sed 's/\/bin\/crsd.bin//'`
             if [ "$GRID_HOME1" = "reboot" ] || [ "GRID_HOME1" = "restart" ]
                 then
          HOME1=`ps -ef |grep crsd.bin | grep -v grep | awk '{print $8}' | head -1`
         GRID_HOME1=`echo $HOME1 | sed 's/\/bin\/crsd.bin//'`
        fi

     for value in `$GRID_HOME1/bin/olsnodes`
     do
     CANDIDATE=$CANDIDATE:$value
    done
    SUM=`echo $CANDIDATE | tr -dc ":"|wc -c`
    SUM=`expr $SUM + 1`
    i=2
       while [ $i -le "$SUM" ]
          do
           RAC_NODE=`echo $CANDIDATE | cut -d":" -f$i`
          echo "/usr/bin/ssh -o FallBackToRsh=no  -o PasswordAuthentication=no  -o StrictHostKeyChecking=yes  -o NumberOfPasswordPrompts=0  $RAC_NODE -n /bin/true >/dev/null 2>&1" >> ssh2.net
          echo "if [ \$? != 0 ]; then exit 1; fi" >> ssh2.net
         i=`expr $i + 1`
        done
chmod +x ssh2.net

./ssh2.net
  if [ $? = 0 ]
     then  
	 	LINK=`$GRID_HOME1/bin/oifcfg getif | grep cluster | awk '{print $1}'`
            if [ ! -z $LINK ]
	         then
            ./genprvnet.sh
              fi
         else
	       TRACERTFOUND=0
     fi			 
fi	 
        else 
		   TRACERTFOUND=2 
		fi
 
		
 fi



######################################################################
# Run any extra commands in file extras.txt if that file exists
######################################################################
if [ $qMax -gt $ZERO ]; then
a=1

while [ "$a" -le "$qMax" ]
do


  if [ $hour != $lasthour ]; then

    echo $PLATFORM OSWbb $version  >> $OSWBB_ARCHIVE_DEST/`eval echo '$xdir'$a`/${hostn}_`eval echo '$xcmd'$a`_$hour

    if [ $zipfiles = 1 ]; then
      if [ -f  $OSWBB_ARCHIVE_DEST/`eval echo  '$xdir'$a`/${hostn}_`eval echo  '$xcmd'$a`_$lasthour ]; then
        $zip $OSWBB_ARCHIVE_DEST/`eval echo  '$xdir'$a`/${hostn}_`eval echo  '$xcmd'$a`_$lasthour &
      fi
    fi
 fi
   
 ./`eval echo  '$xshell'$a` $OSWBB_ARCHIVE_DEST/`eval echo  '$xdir'$a`/${hostn}_`eval echo  '$xcmd'$a`_$hour &
   
 a=`expr $a + 1`
 
done 

fi

######################################################################
# Sleep for specified interval and repeat
######################################################################

lasthour=$hour
sleep $snapshotInterval
done



