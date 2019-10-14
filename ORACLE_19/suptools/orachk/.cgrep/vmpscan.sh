#!/bin/bash
set +x # disable debugging
#
# vmpscan.sh
# 
# Overview
#
# VMPScan is a cluster aware, diagnostic script that will run basic health
# checks and gather detailed, addressable system information from an Oracle VM
# Server, Manager (2.2 to 3.3) or generic Enterprise Linux 4, 5 or 6 system.
# A single archive is created that contains the scan data along with linking
# information that can be merged with other host archives to produce a cluster
# oriented report. Html, text, xml and sqlite3 database reports can be generated
# to support both manual and automated fault analysis. The basic sequence of
# operation is:
#
#  - run vmpscan.sh
#  - copy the cluster's tar.gz archives to a single directory and run merge.sh 
#  - firefox index.htm
#  - < Do review and analysis >
#  - ./clean.sh
#
# When run without options, vmpscan places the report archive in the default
# /tmp/vmpscan directory and will display the path and filename at the end of
# the scan. These archives can then be sent to a remote analyst, transferred to
# a local workstation for review or both.
#
# During the scan, a merge.sh script is also created in the report directory to
# unpack and link the node report archives. Running it will decompress any
# number of archives it finds and generate individual host and merged, cluster
# oriented html and sqlite3 reports. The "Clusterview Portal" index.htm page and
# database can then be reviewed in a web browser or with a sql analysis tool.
#
# The Clusterview page contains links to all the individual node reports that
# were found in the report directory during the merge process. It also contains
# a combined list of key OS parameters for each node that are usually reviewed
# first when checking the health of a Linux system. These key parameters are
# grouped together on the page so value correctness and configuration symmetry
# can be quickly verified across clusters of any size.
#
# When the analysis is completed or paused, clean.sh (generated from merge.sh)
# can be run to delete the expanded directories and recover disk space. To
# resume the analysis, run the merge.sh script again.
#
# VMPScan's fault detection architecture is generalized and can be extended to
# provide coverage for additional test scenarios and products using vmp plugins. 
#
# See the manual page (vmpscan.sh -m) for more information.
#
# Reference Oracle KM Documents:
#
# 1940756.1 - The VMPScan Site Review and Cluster Analysis Tool
# 1933450.1 - VMPStat: Analyze and healthcheck an Oracle VM Server or Manager
# 1910895.1 - VMPMaint: Analyze, Backup and Optionally Reset an Oracle VM Server or Manager
# 1290587.1 - Performing Site Reviews and Cluster Troubleshooting with VMPInfo 
# 1263293.1 - Post-installation checklist for new Oracle VM Servers
# 1288854.1 - Automated Installation of Oracle VM Using DNSMasq and Kickstart
# 806645.1  - Troubleshooting a multi-node OCFS2 installation
# 811457.1  - Troubleshooting a multi-node ASMLib installation
#
# License
#
# Copyright (c) 2010, 2018, Oracle and/or its affiliates. All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, version 2. This
# program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 021110-1307, USA.
#
# The full GPL-2 is provided with vmpscan as the filename LICENSE.
#
# Architect and Author: Tom Lisjac <tom.lisjac>
#
# Many people helped with and encouraged this project. Please run
# vmpscan -m and select Contributors to see a listing.
#
readonly VERSION="1"
readonly REVISION="1b4"
readonly LASTUPDATE="March 2, 2016"
readonly MAINTAINER="Tom Lisjac <tom.lisjac>"

# # # # # # # # # # # #
#
# Global Declarations
#
# # # # # # # # # # # #

# --> Fixed session and filename parameters
readonly SESSTIME="$(date +%F\ %H:%M:%S)"       # ISO8601 compliant timestamp for this session
readonly TMPDT=${SESSTIME/ /-}                  # Build a filename compliant timestamp  
readonly DT=${TMPDT//:/}                        # "Now" timestamp used throughout the script
readonly SHORTHOSTNAME=`hostname|cut -d'.' -f1` # Safe short hostname: workaround for -s bug in Fedora 12
readonly ARCTAG="vmpscan"                       # Script name and tag used in base dir/archive name
readonly SESSIONID="$SHORTHOSTNAME-$DT-$ARCTAG" # Name of the archive and directory... also session ID
readonly DTFN="$SHORTHOSTNAME-$DT.dat"          # Filename for storage filesystem tests
readonly ME=$0                                  # path to the script
readonly OUTFILE=$SESSIONID.tar.gz              # Archive name for log and summary aggregation
readonly SERVICEDUMPFN="/root/$SESSIONID.txt"   # Location for ServiceDump text file

# ---> Script default values: can be overridden from vmpscan.conf (be careful!)

MAXIFS="9"                 # Maximum ifcfg-ethX to display, if found (starting at 0)
DEFAULTFIXITFILE="$ME"     # Path and name for fixit hints: defaults to the script
MAXFIOPSTATUSLEN="30000"   # Maximum length of a fixit hint block
OKCOL="45"                 # Console column for ok, warning and error group stats
ELAPSEDCOL="90"            # Console column for test group elapsed time                   
STRIPCOMMENTS1="egrep -v --regex=#\|^$" # strip comments/blank lines
STRIPCOMMENTS="sed -e 's/;.*//' -e 's/#.*//' -e '/^$/d' -e '/^\t\{1,\}$/d'"
ESCTAGS="sed -e 's/</(/g'|sed -e 's/>/)/g'" # replace < > with ( ) for html and db reports
PRINTALL="cat"             # Command to print everything from a file
CAT=$STRIPCOMMENTS         # Cmd to dump text files... cat or comment stripping egrep
CAT1=$STRIPCOMMENTS1       # Alternate comment stripper... works better on some files
MAXVMS="10"                # Alert if more then this number of VM's is on the OVS 2.2 mgmnt_intf

# --> Values that can be changed from the command line and vmpscan.conf
BASEDIR="/tmp/$ARCTAG" # Default base directory for all writes... override with -b
VMPSNAPDIR=$BASEDIR/vmpsnaps # dir to deposit -a quick healthcheck report 
LOGLEVEL="1"        # Level of detail written to /var/log/messages. 0 disables
LOGGING="2"         # non-zero writes logs to $VMPDIAGS
EXTENDED="v"        # non zero or test argument enables extended diagnostic outputs
NETPROBE="1"        # Enables active network testing
LOGROTATE="0"       # Rotate logs after capturing the archive
PRINTCOMMENTS="0"   # Print or strip comments and blanks lines from config files
NODIALOGS="0"       # Skip the initial dialog for non-root users... useful for batching
SOSREPORT=""        # Generate SOS report... any non-zero length will trigger the report
DELAYINTERVAL="50"  # Optional delay between tests in milliseconds... to reduce host loading

WRITETAGS="0"       # Write tags and tips to $ALLTAGS... used for doc maintenance
QUIET="0"           # Don't print progress notification message to stdout
DEBUGGING="0"       # Dump tags and other info to the console during the scan
DEBUG="0"           # Dumps FS get and HealthCheck debug data to serverdata output
JUSTHC="0"          # Only do healthcheck datapoints
ORACLESCAN="0"      # Look for Oracle product info
APPSCAN="0"         # Include installed apps in report: http, smtp, mysql, postfix
WRITEDB="0"         # Write Berkeley DB to the report archive
STARTDELAY="0"      # Add random delay to scan start for large clusters... max rand value
CMDTIMEOUT="20"     # Default command timeout to generate a warning... changed by -T
EXCLUDES=""         # List of -X commands, groups, sections or scopes to exclude from the scan
STORAGETEST=""      # Do storage test
DTSIZE="16384"      # Size of disk test transfer
DTPATH=""           # Path for disk test
NTSIZE="16384"      # Size of network test transfer
SERVERBASEPORT="5949"   # Port to use for client-server network tests
CLUSTERSYNC="0"     # Prompt operator for start of Storage test... useful for syncing on Clusters
                    # If NODES2TEST != "", forks a server and attempts a dd write to 
NODES2TEST=""       #  the nodes to test: "node1 node2 node3... use with Clustersync
IDTAG=""            # Case number, cluster name or comments for grouping scans
REPORTOPTIONS="HT"  # H=html; T=text; X=xml; D=database
PLUGINPATH=""       # VMPScan plugin path... see the plugin man page for details
KERNELFSDATA="files" # Kernel fs directory paths to save. Also takes "all" and "pids"
COMMAND=""          # Can be set once during cli parsing... defaults to "DoHostScan"

# Override script defaults via the -f <file/fn> command line switch or if
# vmpscan.conf exists in ./vmpfinfo.conf or /etc/vmpscan.conf

if [ -f ./vmpscan.conf ]; then
  source ./vmpscan.conf # Override above defaults if vmpscan.conf found
  CONFMSG="Using ./vmpscan.conf"
elif [ -f /etc/vmpscan.conf ]; then
  source /etc/vmpscan.conf # Override above defaults if vmpscan.conf found
  CONFMSG="Using /etc/vmpscan.conf"
else CONFMSG="Using default script settings"
fi

PATH="${PATH}:/sbin:/bin:/usr/sbin:/usr/bin" # Insure paths to system command paths are present

# --> Global state variables
COLOROFF=""           # Disable onscreen ANSI colors
GLOBALERROR="0"       # Set if there's an internal error... returned to the calling process
GLOBALWARNINGS="0"    # Number of FAE warnings detected
KEYPARM="0"           # Key parameter state variable for building clusterview merge file
HCPARM="0"            # HealthCheck parameter flag
PCKFAILS=""           # Host Precheck failures
OPTIMEOUT=$CMDTIMEOUT # Timeout value for the next command... can be overridden by the FAE
LISTENERPID=""        # PID for network test listener process
SENDERPID=""          # PID for network test sender process
EMITXML="0"           # Command line option to write additional xml formatted result file
EMITDB="0"            # Emit a sqlite3 database of the scan data
EMITTEXT="1"          # Emit the text report
EMITHTML="1"          # Emit the html report and clusterview links
OVSPW=""              # PW for database dump... not saved: implements -j
WRITECONF=""          # non-null writes parameterized vmpscan.conf: implements -w
FILESTOSAVE=""
KVER="`uname -r|cut -d'-' -f1|cut -d'.' -f1,2,3`" # Widely referenced base kernel version
EXTOVM="0"            # run extended Oracle VM tests
EXTGECOS="0"          # get extended GECOS data
EXTSEC="0"            # run extended filesystem/package integrity tests
EXTLSOF="0"           # run lsof
EXTNET="0"            # run extended network tests
EXTLVM="1"            # run LVM scan testops
EXTRAID="0"           # run software raid testops
REPORTFORMAT="" # default css stylesheet for html reports

# Doc file names
MANUALNAME="MANUAL-vmpscan.txt"
READMENAME="README-vmpscan.txt"

# Packaging commands
GETPACKAGELIST="rpm -qa --queryformat \"%{NAME}-%{VERSION}-%{RELEASE}-%{ARCH} \\n\""
VERIFYPACKAGEINTEGRITY="rpm -Vav 2>/dev/null | egrep 'S\.5|missing'"
LISTPUBLICKEYS="rpm -qa gpg-pubkey"
GETUDEVVERSION="`rpm -q udev | cut -d'-' -f2`"

# --> Enumeration types

ROLE=""
# Machine Role types
  OVMSERVER="Oracle_VM_Server"; OVMMANAGER="Oracle_VM_Manager"; GENERIC="Generic_Linux"

HOSTTYPE=""
# --> Host OS types
  readonly BAREMETAL="Baremetal_or_HVM"; XENDOM0="Xen_Dom0"; XENDOMU="Xen_PVDomu"

OVMVERSION="2.2"

FATYPE=""
# --> Fault analysis result types
  readonly ERROR='E'; WARNING='W'; INFO="I"

FACLASS="" # Class of test: /h=Health, /k=Key, /e=Error, /w=Warning. /i=Info, /b=Best Practice

FLAGATTR="" # w=warning e=error i=info

# # # # # # # # # # #
#
# Program code begins
#

# Write the vmpscan.conf file for this session. Any global variables above the
# source <path>/vmpscan.conf above can also be added to this file to change
# global default values.

function WriteConf() { # Command line options used during this scan to vmpscan.conf
  echo "# VMPScan Configuration File - Version $VERSION.$REVISION" 
  if [ -z "$WRITECONF" ]; then echo "# Generated by scan with session ID: $SESSIONID"; fi
  echo "# To run a session with these parameters, place this file in /etc, the same"
  echo "# directory as vmpscan.sh or point to it with the -f command line parameter."
  echo "# See the vmpscan.sh -m man page \"vmpscan_conf\" for more information."
  echo
  echo "# -b <path> Path where the report directory and archive will be written"
  echo "# Default is to create /tmp/vmpscan. Other directories must already exist"
  echo "BASEDIR=\"$BASEDIR\""
  echo
  echo "# -L Script event detail written to /var/log/messages"
  echo "# 0:disable; Default=1:start/stop; 2:scope; 3:section; 4:group; 5:debug"
  echo "LOGLEVEL=\"$LOGLEVEL\""
  echo
  echo "# -l Captured logs: Each level ADDS to the files in the previous one:"
  echo "#  0: no logs; 1:/var/log/messages and dmesg; 2: messages* (default)"
  echo "#  3: /var/log/boot,cron,yum; 4: /var/log/maillog*,httpd,samba, cups"
  echo "#  5: /var/log/se*,audit*; 6:/var/log/*; 7:/etc/*; 8:/var/lib/*"
  echo "LOGGING=\"$LOGGING\""
  echo
  echo "# -x <option set> select extended tests: v|V:LVM; r|R:SW RAID"
  echo "# o|O:OVM; g|G:GECOS data; s|S:OS Security; l|L:lsof; n|N: network."
  echo "# Default=v: do LVM scans. Example: -x VOSN selects extended LVM, OVM,"
  echo "# OS Security and Network tests"
  echo "EXTENDED=\"$EXTENDED\""
  echo
  echo "# -n 1 enables extended network testing: Default=1"
  echo "NETPROBE=\"$NETPROBE\""
  echo
  echo "# -r 1 rotates logs after capturing the archive: Default=0"
  echo "LOGROTATE=\"$LOGROTATE\""
  echo
  echo "# -F 0 strips comments and blanks lines from config files: Default=0"
  echo "PRINTCOMMENTS=\"$PRINTCOMMENTS\""
  echo
  echo "# -o 1 skips the initial dialog for non-root users... useful for batching"
  echo "NODIALOGS=\"$NODIALOGS\""
  echo
  echo "# -g Do SOS report if parameters or a blank is supplied: Default=\"\""
  echo "SOSREPORT=\"$SOSREPORT\""
  echo
  echo "# Optional delay between tests in milliseconds: Default=50"
  echo "DELAYINTERVAL=\"$DELAYINTERVAL\""
  echo
  echo "# -q 0/1:print progress notification message to stdout: Default=1"
  echo "QUIET=\"$QUIET\""
  echo
  echo "# -k 1 does a fast scan of key healthcheck parameters and display to console"
  echo "JUSTHC=\"$JUSTHC\""
  echo
  echo "# -O Enable Oracle Product plugins for the report: Default=0"
  echo "ORACLESCAN=\"$ORACLESCAN\""
  echo
  echo "# -A Enable applications and plugins for the report: Default=0"
  echo "APPSCAN=\"$APPSCAN\""
  echo
  echo "# -W Write Oracle VM binary db... warning: exposes ovs passwords: Default=0"
  echo "WRITEDB=\"$WRITEDB\""
  echo
  echo "# -D <secs> Random startup delay for cluster load balancing: Default=0"
  echo "STARTDELAY=\"$STARTDELAY\""
  echo
  echo "# -T <secs> Change global timeout value for all commands: Default=20"
  echo "CMDTIMEOUT=\"$CMDTIMEOUT\""
  echo
  echo "# -X <list> Exclude specified commands by scope, section, group or test"
  echo "EXCLUDES=\"$EXCLUDES\""
  echo
  echo "# -S Storage block r/w test: \"/path1 /path2...\": Default=\"\""
  echo "# Use with -B to set xfr size. Not supported on EL4"
  echo "STORAGETEST=\"$STORAGETEST\""
  echo
  echo "# -B <size in kb> Storage test block size in kilobytes: Default=16384K"
  echo "DTSIZE=\"$DTSIZE\""
  echo
  echo "# -c Client-server-node block transfer size in Kbytes: Default=16384K"
  echo "NTSIZE=\"$NTSIZE\""
  echo
  echo "# -s <port>  Server port base for network node test"
  echo "# Default: 5949 and 5950. Used with -N"
  echo "SERVERBASEPORT=\"$SERVERBASEPORT\""
  echo
  echo "# -C Prompt to Storage and net node tests... use for syncing on clusters"
  echo "CLUSTERSYNC=\"$CLUSTERSYNC\""
  echo
  echo "# If NODES2TEST != \"\", forks a server and attempts a dd network write to" 
  echo "# the nodes to test: \"node1 node2 node3...\". Not supported on EL4"
  echo "NODES2TEST=\"$NODES2TEST\""
  echo
  echo "# -I ID tag to associate this scan with a cluster or case number" 
  echo "IDTAG=\"$IDTAG\""
  echo
  echo "# -R <list> Report output options: h=html; t=text; x=xml; d=database"
  echo "# Example -R htd would produce an html, text and database report"
  echo "REPORTOPTIONS=\"$REPORTOPTIONS\""
  echo
  echo "# -V vmpscan plugin path - where to find .vmp plugins"
  echo "PLUGINPATH=\"$PLUGINPATH\""
  echo
  echo "# -K kernel data collection paths for /sys and /proc. Add specific paths,"
  echo '# "pids" to snapshot /proc/[0-9]* or "all" for maximum collection from both.'
  echo '# "files" just collects /proc root files. Specifying many paths, all or pids'
  echo "# can be problematic and hang the script on some systems: use with caution"
  echo "KERNELFSDATA=\"$KERNELFSDATA\""
  echo
  echo "# Base command that the script will execute. A \"\" defaults to DoHostScan"
  echo "# Options: DoHostScan TestScriptExecute KeyParameterScan:  see man pages"
  echo "COMMAND=\"$COMMAND\""
} > $VMPCONF

function CheckRestrictedDirectories() { # restrict cli parms that point to inappropriate places
  function CheckDir() {
    local tdir baddirs ckerr="0" inparm="$1" invar="$2"
    function BailOut() {
      echo; echo "---> \"$invar\" path parameter error:\"$inparm\""; echo; echo -e "$1"
      echo; echo "Exiting"; echo; exit 1
    }
    tdir="${inparm%% *}";
    if [ -z "$tdir" ]; then BailOut "Path parameter is empty or invalid... cannot continue"; fi
    if [ "${tdir:0:1}" != "/" ]; then BailOut "Path parameters must be absolute begin with /"; fi
    tdir=${tdir:1}
    if [ -z "$tdir" ]; then BailOut "VMPScan will not write to /"; fi
    tdir=${tdir%%/*}
    if [ -z "$tdir" ]; then BailOut "VMPScan will not write to /"; fi
    baddirs="proc bin sbin usr lib dev boot etc opt selinux sys dlm net opt lost+found" 
    for i in $baddirs; do
      if [ "$tdir" = "$i" ]; then
        BailOut "Sorry, VMPScan will not write to these root directories:\n$baddirs" 
      fi
    done
    if ! [ -d "/$tdir" ]; then BailOut "$tdir does not exist or is not a directory"; fi
    return 0
  }

  for indir in $1; do CheckDir "$indir" "$2"; done
}

# Initialize global paths... allows the BASEDIR to be changed via command line switch

SCSI_IDCMD="" # export from this function that provides udev ver scsi_id switches
function InitGlobalVars() {
  VMPDIAGS=$BASEDIR/$SESSIONID      # Full path to root of all archives
  VMPDATA=$VMPDIAGS/vmpdata         # vmpscan script variables and link info
  VMPVAR=$VMPDATA/var               # location for /var data to be written
  VMPCONF=$VMPDIAGS/vmpscan.conf    # configuration file written here for this session
  
  # --> Output files
  VMPVER="$VMPDATA/vmpver.txt"      # vmpscan version to sync with merge and clean
  TEXTDATA="$VMPDIAGS/vmpscan.txt"  # Full path to the text summary data file
  XMLDATA="$VMPDIAGS/vmpscan.xml"   # Fault analysis data in xml format
  HTMLDATA="$VMPDIAGS/vmpscan.htm"  # Fault analysis data in html format
  DBDATA="$VMPDIAGS/vmpscan.sqlite" # Fault analysis data in sqlite3 format

  SUMDATA="$VMPDATA/sumdata"       # Summary key data
  SUMKEYS="$VMPDATA/sumkeys"       # Summary keys

  ALLDATA="$VMPDATA/alldata"       # All key data for a given scope
  ALLKEYS="$VMPDATA/allkeys"       # All keys for a given scope
  
  ALLTAGS="$BASEDIR/alltags.txt"   # All tags and help info for script doc maintenance

  # Temporary result accumulators
  ERRORTEXT=$VMPDATA/errors.txt          # Text error info
  ERRORHTML=$VMPDATA/errors.htm          # Html error info
  ERRORCLU=$VMPDATA/errorclu.htm         # Html error info: cluster
  WARNINGTEXT=$VMPDATA/warnings.txt      # Text warning info
  WARNINGHTML=$VMPDATA/warnings.htm      # Html warning info
  WARNINGCLU=$VMPDATA/warnclu.htm        # Html warning info: cluster
  SYSHEALTHTEXT=$VMPDATA/syshealth.txt   # Text healthcheck info
  SYSHEALTHHTML=$VMPDATA/syshealth.htm   # Html healthcheck info
  SYSHEALTHCLU=$VMPDATA/syshealthclu.htm # Html healthcheck info: cluster
  SCRIPTLOG=$VMPDATA/scriptlog.txt       # Accumulates any internal script errors
  SECTIONHEADERS=$VMPDATA/sections.htm   # Accumulates the section html links
  MERGESCRIPT=$VMPDATA/merge.sh          # Name and location of merge script
  CLUVIEW=$VMPDATA/cluview.htm           # Table slice for reassembly by merge.sh
  CLUHEAD=$VMPDATA/cluhead.htm           # Cluster nav css and html stuff
  CONOUT=$VMPDATA/conout                 # Console output seen by user

  if [ "$PRINTCOMMENTS" = "0" ]; then CAT=$STRIPCOMMENTS; else CAT=$PRINTALL; fi
  TIMEZONE=`date -R | cut -d' ' -f6`
  # Compensate for changes in the scsi_id command with advancing versions of udev
  if [ "$GETUDEVVERSION" -ge "124" ]; then SCSI_IDCMD="--page=0x83 --whitelist --device=/dev"
  else SCSI_IDCMD="-g -u -s /block"
  fi
}

function DeleteWorkingDirectory() { # verify a vmpscan directory signature before deleting
  if [ -d "$VMPDIAGS" ]; then
    CheckRestrictedDirectories "$VMPDIAGS" "BASEDIR Delete"
    if [ -d "$VMPDIAGS" ] && [ "${VMPDIAGS##*-}" = "vmpscan" ]; then rm -rf $VMPDIAGS # Did $ARCTAG here for safety
    else echo "WARNING: Working directory \"$VMPDIAGS\" cannot be deleted... incorrectly named"
    fi
  fi
}

# # # # # # # # # # # # 
#
# --> Utility Functions
#
# Set console colors and provide for internal error logging

OKCOLOR="\033[0;32m"; WARNCOLOR="\033[0;33m"; ERRORCOLOR="\033[0;31m"; NOTESTS="\033[0;34m"
NORMCOLOR="\033[0;39m"         # Return screen colors to normal non-bold b/w              
CONALERTCOLOR="\033[38;0;214m" # For console alerts during the run
HTMLCON=""  # Output html color attributes rather then ansi (for AnalyzeHost)
AHEXIT="0" # AnalyzeHost exit value set by color flags below
AHWARN="0" # AnalyzeHost warnings generated
AHERRORS="0" # AnalyzeHost errors generated

# for i in `seq 1 255`; do echo $i; echo -e "\033[38;0;${i}mThe quick brown fox\033[39m"; done
#<span class=\"resok\">Result:$CONDXRET</span><br>
#.resok {color:#80FF80;} .resinfo {color:#8080FF;}
#.reserr {color:#FF8080;} .reswarn {color:#FFFF80;}

function color() {
  
  function SetEX() { # Exit non-zero only on errors, not warnings
    case "$1" in "1") AHEXIT="$1"; AHERRORS=$((AHERRORS+1));; "2") AHWARN=$((AHWARN+1));; esac
  }

  if [ -n "$HTMLCON" ]; then # This code specifically for the AnalyzeHost function
    case "$1" in
      norm) echo -n "</span>";;
      none) return 0;;
      red) echo -n "<span class=\"reserr\">"; SetEX "1";;
      yellow) echo -n "<span class=\"reswarn\">"; SetEX "2";;
      green) echo -n "<span class=\"resok\">";;
      white) echo -n "<span class=\"ahsec\">";;
      *) echo -n "<span style=\"color:$1\">";;
    esac
  else
    if [ -n "$COLOROFF" ]; then return 0; fi
    if [ "$2" = "" ]; then ATTR="1"; else ATTR="$2"; fi
    case "$1" in
      green) C="32";; red) C="31"; SetEX "1";; yellow) C="33"; SetEX "2";; blue) C="34";; norm) ATTR="0"; C="39";;
      cyan) C="36";; white) C="37";; purple) C="35";; none) return 0;; *)  C="$1";;
    esac
    echo -en "\e[$ATTR;${C}m"
  fi
}

function colorout() { color $1; echo -ne "$2"; color norm; }
function coloroutnl() { colorout $1 "$2"; if [ -n "$HTMLCON" ]; then echo -n "<br>"; else echo; fi; }

function debugon()  { DEBUG=1; set -x; }
function debugoff() { DEBUG=0; set +x; }
function debug() {
  if [ "$DEBUG" != "0" ]; then echo; echo -e "<$ARCTAG-DEBUG>\n"$*"\n</$ARCTAG-DEBUG>"; fi; 
}

# Syslog, internal error and warning handlers

function logit() { # Write $2 to /var/log/messages if $1 <= LOGLEVEL (-l)
  if [ "$1" -le "$LOGLEVEL" ]; then logger -it "$ARCTAG" "$2"; fi
}

function InternalWarning() { echo -e "Warning: $*";GLOBALWARNINGS=1; } >> $SCRIPTLOG
function InternalError() {
  { echo -e "* $*"; } | tee -a $SCRIPTLOG
  GLOBALERROR=1
}

function FatalError() {
  echo
  echo "* * * *"
  echo "* Sorry, an unrecoverable error has occurred and $ARCTAG cannot continue:"
  echo "*" 
  InternalError "Fatal: $*"
  echo "*" 
  echo "* Please make an archive of $VMPDIAGS" 
  echo "* and sent it to the current maintainer: $MAINTAINER"
  echo "* with the subject line \"vmpscan problem\""
  echo "* * * *"  
  echo
  echo "Information on the the error can be found in:"
  echo "$SCRIPTLOG"; echo 
  exit 1
}

LOGSTOLINK="" # List of logs to stuff into the nav table
function FLink() {
  if [ -z "$LOGSTOLINK" ]; then LOGSTOLINK="$1"; else LOGSTOLINK="$LOGSTOLINK $1"; fi
}

# # # # # # # # # # # # # # # # # #
#
# ---> Hierarchical Tag Management
#
# All tests and fault signatures have a "tag" address that is used to lookup "fixit"
# help information and as a unique id for grepping, html anchors and database keys.
# The format is:
#
# <hostname.scope.section.group.sig>
#
# The scope, section, group fault engine commands are used to set these tags. The sig
# component is a mandatory id parameter for every FAE command where data is acquired.
# The toplevel hostname is written to the output files but is not stored in the
# internal FA data array to allow the lookup code to be host agnostic.

TOPLEVEL="" # tagroot                            Root of tag tree... always the hostname
SCOPE=""    # tagroot.scope                      Major subsystem: os, net, storage...
SECTION=""  # tagroot.scope.section              Subsystem components
GROUP=""    # tagroot.scope.section.group        Group of subsystem tests
SIG=""      # tagroot.scope.section.group.sig    Specific test or fault signature

# Fault Engine accumulator
#
# These are virtual registers that are valid for a single FA operation. They are
# moved to the fault analysis array, element 0 for reuse in chained operations. 

OPTAG=""    # Full path of current test: <toplevel.scope.section.group.sig>
OPDATA=""   # Info returned from FS operation
OPMSG=""    # Human readable description of FS
OPSTATUS=0  # FS operation exit status: 0=pass, non-zero=fail

# Fault Analysis lookup array.
#
# An array of records in bash follows... delightful. Computational operations
# on this kind of array will be slow but speed is not important here.
#
# Element 0 of this array always contains the results of the last FAE operation

INX=0        # Pointer to the current record being referenced
HEAPPTR=0    # Always points to the next element to write

declare -a OPTAGS;  # Path of test: hostname.net.pinggw...
declare -a OPSTATS; # Result of FA op command... xor'ed with desired test result
declare -a OPMSGS;  # Informative message to associate with the test or sig
declare -a OPDATS;  # Data returned from the FA operation

# Element zero contains the register set for the previous operation or chain
OPTAGS[0]="TAG"; OPDATS[0]="DATA"; OPMSGS[0]="MSG"; OPSTATS=[0]="STAT"

# # # # # # # # # # # # # # # # 
#
# --> Fixit lookup procedures
#
# Find the data or help information associated with the tag parameter and file
#
# GetTagData greps for the start <tag> parameter ($1) and its end </tag> in an
# optionally provided file ($2). When and if the tag is found, dd the block to the
# FIXITBLOCK variable for processing by the caller. The default "fixitfile" is the
# script itself where the fixit blocks are stored after the end of the script code.
# This allows the script algorithms and help info to be contained in one file.
#
# The GetTagData routine is generalized to also allow retrieving tag data from
# structured XML data files. These files are generated to provide the node
# linkage data that is used in the creation of the Clusterview portal.
#

FIXITBLOCK=""
# Get a tag block from a specified file: $1: tag  $2: optional filename
function GetTagData() {
  FIXITBLOCK=""; local inx startinx endinx fixittag=$1 fixitfile=${2:-"$DEFAULTFIXITFILE"}
  if ! [ -f $fixitfile ]; then InternalError "fixit file $fixitfile not found"; return 1; fi
  inx=`egrep -bam 2 "<$fixittag>|<\/$fixittag>" $fixitfile`
  if [ "$?" != "0" ]; then return 1; fi
  startinx=`echo $inx | cut -d' ' -f1 | cut -d: -f1`
  endinx=`echo $inx | cut -d' ' -f2 | cut -d: -f1`
  if [ "$startinx" = "$endinx" ]; then return 1; fi # Invalid: tags on same line
  let startinx="$startinx+${#fixittag}+3" # index around the starting tag and \n
  let len="$endinx-$startinx"

  # do a simple sanity check
  if [ "$endinx" -gt "$startinx" ] && [ "$len" -lt "$MAXFIOPSTATUSLEN" ]; then
    if [ -z ${3:-""} ]; then
      FIXITBLOCK=`dd skip=$startinx if=$fixitfile bs=1 count=$len 2> /dev/null`
    else dd skip=$startinx if=$fixitfile bs=1 count=$len 2> /dev/null # echo the data to stdout
    fi
  else
    InternalError "Malformed fixit text block at $fixittag, start: $startinx end: $endinx inx:$inx with length $len" 
  fi
  return 0
}

# Search back in the tree until a tag or the toplevel is found as in:
#  os.mem.perf.memfree.min
#  os.mem.perf.memfree
#  os.mem.perf
#  os.mem
#  os
#
LASTFIXIT=""; LASTTAG=""
function SearchTagData() {
  local searchtag=$1 backlevels=${2:-'0'}
  while ! GetTagData $searchtag $VMPDIAGS/fixit.txt; do
    if [ "$backlevels" = "0" ]; then return 1; fi
    if ! [[ "$searchtag" =~ "\." ]]; then return 1; fi # Toplevel... can't go further
    searchtag=${searchtag%.*} # Look higher in the tree by lobbing off the last tag
    if [ "$searchtag" = "$LASTFIXIT" ]; then FIXITBLOCK="See general $LASTFIXIT message in $LASTTAG"; return 1; fi
    let "--backlevels"
  done
  LASTFIXIT=$searchtag; LASTTAG=$1
  return 0     
}

# Get the $FIXITBLOCK for a given tag ($1) from an optionally specified file ($2)
function GetFixitText() {
  local fixittag=$1 toppara
  SearchTagData $fixittag 4 $2
  if [ -n "$FIXITBLOCK" ]; then
    toppara="${FIXITBLOCK%%$'\n\n'*}" # Get first paragraph
    if [ "${toppara:0:2}" = "R:" ]; then # is it a RESULTMSG
      if [ -z "$RESULTMSG" ]; then RESULTMSG="${toppara#R:}"; fi # Testop result overrides
      toppara="${FIXITBLOCK#*$'\n\n'}" # whack R: paragraph... if it's R: again, no fixit
      if [ "${toppara:0:2}" = "R:" ]; then FIXITBLOCK=""; else FIXITBLOCK="$toppara"; fi
    fi
  fi
}

function EchoTagData() { GetTagData "$1" "$2" "1"; }
function ShowManPage() {
  GetTagData "$2"
  echo -e $3"* * * * * * * * * * *\n* ---> $1\n*\n$FIXITBLOCK" | sed 's|\(<!--#scriptverrev-->\)|'"$VERSION.$REVISION"'|g' | less
}
function WriteBlock() { if GetTagData "$1"; then echo -e "$FIXITBLOCK\n" >> $2; fi; }

# # # # # # # # # # # # # # #
#
# ---> Manual Page Routines
#
#
mtitles=""; mpages=""
function InitManPages() {

  function madd() {
    local ss=""
    if [ -n "$mtitles" ]; then ss=" "; fi
    mtitles="$mtitles$ss$1"; mpages="$mpages$ss$2"
  }

  mtitles=""; mpages=""
  madd "Quick_Start" "readme"; madd "Overview" "overview"; madd "Command_Line_Options" "usage"
  madd "Features" "feature_set" ;madd "Known_Issues" "known_issues"
  madd "Healthcheck" "healthcheck"; madd "Full_Scan" "fullscan"
  madd "Merge_and_Clean" "mergeandclean"
  madd "vmpscan_conf" "vmpscan_conf"; madd "Examples" "examples"
  madd "Reading_VMPScan_Reports" "reports"; madd "Managing_Report_Data" "manage"
  madd "XML_Report_Format" "xml_format"; madd "Database_Report_Format" "db_format";
  madd "Customizing_Appearance" "appearance"; madd "VMPScan_css" "vmpscan_css"
  madd "Fixits" "maint-fixits"; madd "FAE_Architecture" "faearch"; madd "FAE_Instruction_Set" "faerules" 
  madd "Writing_VMPScan_Plugins" "vmpplugins"; madd "Generate_Custom_Version" "custom_version"
  madd "Contributors" "contributors"; madd "Quit"
}

function WriteReadme() {
  > $READMENAME
  WriteBlock man.readme $READMENAME
  sed -i 's|\(<!--#scriptverrev-->\)|'"$VERSION.$REVISION"'|g' $READMENAME
}

function PrintAllManPages() {
  > $MANUALNAME
  InitManPages; local i num ss thistitle
  { echo "* * * * * * * * * * * * *"
    echo "*  VMPScan $VERSION.$REVISION Manual *"
    echo "* * * * * * * * * * * * *"
    echo; echo "---> Table of Contents"; echo; num="0";
    for i in $mtitles; do
      let '++num'; if [ "$num" -lt "10" ]; then ss=" "; else ss=""; fi
      if [ "$i" != "Quit" ]; then echo " $num. $ss$i"; fi
    done; echo
  } >> $MANUALNAME
  echo; num="0";
  for i in $mpages; do
    let '++num'
    thistitle=`echo $mtitles|cut -d' ' -f1`; mtitles=${mtitles#$thistitle }
    echo "  $thistitle"    
  { echo "* * * * * * * * * * * * *"
    echo "*"; echo "*   $num. $thistitle ($i)"; echo "*"
  } >> $MANUALNAME
  WriteBlock man.$i $MANUALNAME
  sed -i 's|\(<!--#scriptverrev-->\)|'"$VERSION.$REVISION"'|g' $MANUALNAME
  done
  echo; echo "All manual pages written to:  $MANUALNAME"
}

function PrintReadme() { # implements -p
  echo; echo "Quick Start Guide written to `pwd`/$READMENAME"; echo
  WriteReadme
  exit 0
}

function PrintAllReleaseDocs() { # implements -P
  echo; echo "VMPScan Manual Pages:"
  PrintAllManPages
  WriteReadme
  echo "Quick Start Guide written to: $READMENAME"
  echo; echo "Done... all documentation has been written to `pwd`"; echo
  exit 0
} 

function ShowManPages() { # implements -m
  InitManPages; local i num
  while true; do
    clear;
    echo;
    echo "VMPScan Manual Pages - Version $VERSION.$REVISION"; echo 
    echo "To write the entire manual to disk ($MANUALNAME), run"
    echo "vmpscan.sh -P. To write the start guide ($READMENAME),"
    echo "run vmpscan.sh -p."
    echo; echo "Please select a manual page... hit \"q\" to exit the page:"; echo
    select mtitle in $mtitles; do
      num="0"
      for i in $mtitles; do
         let '++num'
         if [ "$i" = "$mtitle" ]; then
           if [ "$i" = "Quit" ]; then exit 0; fi
           ShowManPage "$num. $mtitle" "man.`echo $mpages|cut -d' ' -f$num`"
           break
         fi
      done
      break  
    done
  done
}

function WriteVMPScanConf() { # implements -w
  VMPCONF="vmpscan.conf"; COMMAND=""; CheckRestrictedDirectories `pwd` "WriteVMPScanConf"
  WriteConf
  echo; echo "---> $CONFMSG as source for defaults"
  echo "Defaults and command line parameters written to: `pwd`/vmpscan.conf"; echo
  exit 0
}

function WriteSpecFile() { # Write current rpm specfile to current directory: implements -Z
  WriteBlock man.rpmspec $ARCTAG-$VERSION.spec
  sed -i 's|\(<!--#scriptver-->\)|'"$VERSION"'|g' $ARCTAG-$VERSION.spec
  sed -i 's|\(<!--#scriptrev-->\)|'"$REVISION"'|g' $ARCTAG-$VERSION.spec
  sed -i 's|\(<!--#maintainer-->\)|'"$MAINTAINER"'|g' $ARCTAG-$VERSION.spec
  echo; echo "$ARCTAG-$VERSION.spec written to `pwd`"; echo
  exit 0
}

FILESTOSAVE=""
function AddData() { # Add a file or directory to the report archive manifest
  if [ "${1:0:1}" = "/" ]; then FILESTOSAVE="$FILESTOSAVE ${1#/}"
  else FILESTOSAVE="$FILESTOSAVE $1"
  fi
}

# # # # # # # # # # # # # # # # #
#
# ---> VMPScan Integrity checks
#
SCRIPTMD5=""; REFMD5=""
function GetScriptMD5() { # get script md5 up to the <$s.md5>
  local s="script" # mask the literal search tag from egrep
  local len=`egrep -bam 1 "<$s.md5>" $ME|cut -d':' -f1`
  SCRIPTMD5=`dd if=$ME bs=$len count=1 2>/dev/null|md5sum|cut -d' ' -f1`
}

function ShowScriptMD5() { # implements -5
  GetScriptMD5; echo Script: $SCRIPTMD5
}

function CheckScriptMD5() {
  GetTagData "script.md5"; REFMD5="$FIXITBLOCK"; GetScriptMD5;
  if [ -z "$FIXITBLOCK" ]; then echo "* Script md5 signature not found"; return 1; fi
  if [ "$FIXITBLOCK" = "$SCRIPTMD5" ]; then echo "* MD5 ok: $SCRIPTMD5"
  else
    echo; echo "---> MD5 check failed:"
    echo "Expected: $FIXITBLOCK"
    echo "Returned: $SCRIPTMD5"
    echo
    echo "This copy has been damaged or modified... $ARCTAG cannot continue."
    echo
    echo "If you have edited this script on a non-Linux system, please move"
    echo "the original archive to a Linux machine, decompress it and try again."
    echo "If this doesn't fix the problem, please get a new copy."; echo
    echo "Checked modifications can be made to $ARCTAG. See the manual page"
    echo "\"Generate_Custom_Version\" for more information (vmpscan -m)."; echo
    exit 1
  fi
}

PREVOP="section"
function RunExtension() { # Implements vmp plugins: see man pages for more info

  function Runit() {
    if [ -f "$1" ]; then
      if grep -q "function vmpplugin" $1; then echo executing; source "$1"; vmpplugin
      else wrcon "\n$ARCTAG $SCOPE extensions must have a function named vmpext\n"; return 1
      fi
    fi
  }

  if [ "$PREVLINEPOS" != "0" ]; then
    case $1 in
      section)
        Runit "$PLUGINPATH/$SCOPE.$SECTION.$GROUP.vmp"
        Runit "$PLUGINPATH/$SCOPE.$SECTION.vmp"
       ;; 
      group)
        if [ "$PREVOP" != "section" ]; then Runit "$PLUGINPATH/$SCOPE.$SECTION.$GROUP.vmp"; fi;;
    esac 
    PREVOP=$1
  fi
}

CLUSYNC=""
function ClusterSync() { # Prompt operator for certain commands: implements -C
  CLUSYNC=""
  if [ "$CLUSTERSYNC" = "1" ] && [ "$ABORTFA" = "0" ]; then
    FS conmsg "\n$1"
    FS conmsg "Press Enter to continue:"
    read; FS conmsg '\n';
    CLUSYNC="   Clustersync start: $(date +%F-%H%M%S)"
  else
    CLUSYNC="   Clustersync: disabled"
  fi
}

# # # # # # # # # # # # # # #
#
# --> FAULT ANALYSIS ENGINE
#
# function FAE
#
# Execute requests for system data, apply fault signature masks and generate reports.
#
# Called by FS routines below that implement conditional chain logic and severity classes
#
# The FAE function does the following:
#   1. Executes the passed command and collects the exit status and returned data
#   2. Builds a id tag from the passed sig parameter and the current scope, section and group
#   3. Deposits the accumulator in FA array index 0 for subsequent chain processing.
#   4. If a failure occurs, look up the tag and retrieve fixit hint text
#   5. Writes the results in text, html and xml formats. Writes warnings and errors to separate files.
#   6. Xor's the test result with CONDXRET to provide correct logic sense for calling FS routines  
#
# The FAE accumulator registers are:
#
# OPTAG     Full path of current test: <toplevel.scope.section.group.sig>
# OPDATA    Info returned from FAE data acquisition command
# OPMSG     Human readable description of test or fault signature
# OPSTATUS  FA op exit status. Xor'ed with requested FS chain logic to determine pass/fail
#
# A typical FAE command has the following format:
#
#   cmd:  <description>  <the test command>  <test or signature id> [ Fail text ] [ Pass Text ]
#
# Example of cmd operation:
#
#   FS cmd "DM-Multipath installed" "rpm -q --quiet device-mapper-multipath" dm-mpath_installed
#
#   cmdx: same as cmd but does not store returned data... used where exit status is all that's needed
#
# # # # # # # # # #
#
# --> FAE utilities
#

# Command prefixes to set state flags and modify defaults and on a per command basis

function BP() { FACLASS="${FACLASS}/b"; } # flag as a best practices datapoint }

function K() { # Flag this op as a key parameter for clusterview merging
  KEYPARM="1"; FACLASS="${FACLASS}/k"
} 

function HC() { # Flag this test as a healthcheck datapoint
  HCPARM="1"; FACLASS="${FACLASS}/h"
  if [ "$JUSTHC" = "1" ]; then ABORTFA="0"; fi 
}

function KHC() { # Combined Key and HealthCheck datapoint
  KEYPARM="1"; HCPARM="1"; FACLASS="${FACLASS}/h/k"; if [ "$JUSTHC" = "1" ]; then ABORTFA="0"; fi
}

function A() { ABORTFA="0"; } # Always execute... setting up data for the healthcheck scan

function TO() { OPTIMEOUT=$1; } #override default command timeout value for this command

REVERSEDR="0"
function R() { REVERSEDR="1"; } # reverses OPDATA and RESULTMSG in xml and db reports: normalization kluge

# Save current FAE accumulator to the array
function SaveOPData() { # Save the FA engine registers for the current operation or passed parm index
  if [ -n "$1" ]; then INX="$1"; else INX=$HEAPPTR; let "++HEAPPTR"; fi
  OPTAGS[$HEAPPTR]="$OPTAG"; OPSTATS[$HEAPPTR]="$OPSTATUS";
  OPMSGS[$HEAPPTR]="$OPMSG"; OPDATS[$HEAPPTR]="$OPDATA"
  return $INX
}

# Locate an FAE record by tag and return its index in global variable INX
function LookupOPData() {
  arraysize=${#OPTAGS[@]}
  for ((INX=0;INX<arraysize;INX++)); do
    if [ "${OPTAGS[${INX}]}" = "$1" ]; then return 0; fi
  done
  return 1
}

function GetOPINX() { # Global INX if tag is found
  if ! LookupOPData "$1"; then FatalError "recall operation on tag $1 failed"; fi
}      

# Load the FA accumulator from the passed tag
function LoadOPData() {
  if ! LookupOPData $1; then FatalError "Lookup of $1 in FA array failed"
  else
    OPTAG="${OPTAGS[${INX}]}"
    OPMSG="${OPMSGS[${INX}]}"
    OPSTATUS="${OPSTATS[${INX}]}"
    OPDATA="${OPDATS[${INX}]}"
  fi
}

# Internal diagnostic dump of FA array to script error file
function DumpOPData() {
  arraysize=${#OPTAGS[@]}
  for (( INX=0;INX<arraysize;INX++)); do
    echo "INX:$INX"
    echo "OPTAG:${OPTAGS[${INX}]}"
    echo "OPMSG:${OPMSGS[${INX}]}"
    echo "OPSTATUS:${OPSTATS[${INX}]}"
    echo "OPDATA:${OPDATS[${INX}]}"
  done
}

# --> FAE statistic and state variables

GROUPOK="0";       TOTALOK="0"
GROUPERRORS="0";   TOTALERRORS="0"
GROUPWARNINGS="0"; TOTALWARNINGS="0"
TOTALHCFLAGS="0" # number of items flagged during healthcheck ops


# Command chaining state variables

ABORTFA="0"     # Set if an ifz/nzFS chain command fails... terminates subsequent group cmds
ABORTREASON=""  # Explains chain abort
CONDXREQ="0"    # Requested FA exit condition
CONDXRET="0"    # ifzFS/ifnzFS branch logic: xor of CONDXVAL and $PASSED

PASSED="";      # pass or fail at the shell level... xor'd with CONDXRET for FAE result
RESULTMSG=""
PREVLINEPOS="0" # used to properly space progress indicators on the console

# # # # # # # # # # # # # #
#
# ---> Console and file I/O
#
# All FA engine writes to the console and data files are done via these routines
#
function wrcon() { if [ "$QUIET" = "0" ]; then echo -en "$@" 2>&1 | tee -a $CONOUT; fi; }
function wrdata() { echo -en "$@"; } >> $TEXTDATA
function wrdataln() { wrdata "$@\n"; }
function wrnf() { echo -n "$@"; } >> $TEXTDATA
function wrnfln() { echo "$@"; } >> $TEXTDATA
function wrreports() { wrdata "$1"; local s=$TEXTDATA TEXTDATA=$HTMLDATA; wrdata "$1"; TEXTDATA=$s; }
function wrreportsln() { wrdataln "$1"; local s=$TEXTDATA TEXTDATA=$HTMLDATA; wrdataln "$1<br>"; TEXTDATA=$s; }

# Elapsed Time Support
#
NOW="0"
function GetNow() { NOW=$(($(date +%s%N)/1000000)); return $NOW; }

ELTIME="0"; ELTIMESEC="0"
function GetElapsed() {
  local ms; local et=$((($(date +%s%N)/1000000) - $1)) 
  ELTIMESEC=$((et / 1000)); ms=$((et % 1000))
  if [ ${#ms} != "3" ]; then ms="0$ms"; fi; if [ ${#ms} != "3" ]; then ms="0$ms"; fi;
  ELTIME="$ELTIMESEC.$ms"
}

FSIZE="0"
function fsize() { if [ -f "$1" ]; then FSIZE=`ls -lah $1|xargs|cut -d' ' -f5`; else FSIZE=""; fi; }

function CmdSleep() { # delay next test to reduce host loading: implements -i
  local z; if [ "$DELAYINTERVAL" != "0" ]; then let z=$DELAYINTERVAL*1000; usleep $z; fi
}

GROUPSTART="0"; GROUPKEY="0"
function flushgroupmsgs() { # Conclude group processing and write status message
  if [ "$PREVLINEPOS" != "0" ]; then # means we're not at the start
    # the following is a kluge to avoid calling bc or awk for floating point math
    GetElapsed "$GROUPSTART"; GROUPELAPSED=$ELTIME  
    wrdataln "Elapsed time for this group: $GROUPELAPSED seconds"
    local tag=$SCOPE.$SECTION.$GROUP
    echo "<br><span class=\"grpend\">Group: $tag completed in $GROUPELAPSED seconds</span><br><hr>" >> $HTMLDATA
    GROUPSTART=$(($(date +%s%N)/1000000)) # in milliseconds
    local c="" fill="0" e="" w="" ok="" padding="" s="" pfx="" elen="${#GROUPELAPSED}"
    if [ "$GROUPERRORS" != "0" ]; then e="${ERRORCOLOR} e:$GROUPERRORS"; fi
    if [ "$GROUPWARNINGS" != "0" ]; then w="${WARNCOLOR} w:$GROUPWARNINGS"; fi
    if [ "$GROUPOK" != "0" ]; then ok="${OKCOLOR} ok:$GROUPOK"; fi 
    s="$ok$w$e"; if [ -z "$s" ]; then s="$NOTESTS <none>"; fi; s=$s$NORMCOLOR
    if [ "$elen" -gt "5" ]; then pfx=$((OKCOL - elen + 5)); else pfx=$OKCOL; fi
    if [ "$PREVLINEPOS" -lt "$pfx" ]; then
      for (( c=0;c<$(( $pfx - $PREVLINEPOS ));c++)); do padding=$padding'-'; done
      wrcon "$padding ${GROUPELAPSED}s$s\n";
    else wrcon "  ${GROUPELAPSED}s$s\n"
    fi
  fi
  GROUPKEY="0"
  TOTALOK="$((TOTALOK + GROUPOK))" 
  TOTALERRORS="$((TOTALERRORS + GROUPERRORS))"
  TOTALWARNINGS="$((TOTALWARNINGS + GROUPWARNINGS))"
  GROUPOK="0"; GROUPERRORS="0"; GROUPWARNINGS="0"; PREVLINEPOS="0"
}

# # # # # # # # # # # #
#
# ---> FAE entry point
#

function FAE() {  # Acquire testop data, apply optional fault signature masks and report results
  local LINKVAL=""

  function dumpFAE() { # Diagnostic dump of engine state and register values
    wrdataln "DEBUG --->\nFAOP:$FAOP\nOPTAG:$OPTAG\nOPMSG:$OPMSG\nOPSTATUS:$OPSTATUS"
    wrdataln "PASSED:$PASSED\nCONDXREQ:$CONDXREQ\nCONDXRET:$CONDXRET\nRESULTMSG:$RESULTMSG\nABORTFA:$ABORTFA"
    wrdataln "OPDATA:$OPDATA\nABORTREASON:$ABORTREASON"
    wrdataln "OPDATS[INX]:${OPDATS[$INX]}\n"
    wrdataln "OPTAGS0:${OPTAGS[0]}\nOPDATS0:${OPDATS[0]}\nOPMSGS0:${OPMSGS[0]}\nOPSTATS0:${OPSTATS[0]}"
    wrdataln "<---"
  }

  function wr() { # Write results to selected text, html, xml or sqlite3 report files
    local faclass=$FACLASS
 
    function wrhtmldata() { # Formats and writes the html report
      # Report components
      function wrhead() {
        wrdataln "<a name=\"$TOPLEVEL.$OPTAG\"></a>"
        wrdata "<span class=\"sig\">$OPMSG</span>&nbsp;&nbsp;"
      }
      function wrlinks() {
        wrdata "<span class=\"tag1\">"
        wrdata "<a href=\"#top\">$TOPLEVEL</a>.<a href=\"#$TOPLEVEL.$SCOPE\">$SCOPE</a>"
        wrdata ".<a href=\"#$TOPLEVEL.$SCOPE.$SECTION\">$SECTION</a>"
        wrdata ".<a href=\"#$TOPLEVEL.$SCOPE.$SECTION.$GROUP\">$GROUP</a>"     
        wrdata ".<a href=\"#$TOPLEVEL.$OPTAG\">$OPNAME</a></span>&nbsp;&nbsp;&nbsp;|&nbsp;"
        if [ "$KEYPARM" != "0" ]; then
          wrdata "<span class=\"clukey\"><a href=\"../index.htm#$OPTAG\">CluKey</a></span>&nbsp;|&nbsp;"
        fi
        wrdata "&nbsp;&nbsp;Next: <span class=\"tag1\"><a href=\"#top\">Top</a>.<a href=\"#$TOPLEVEL.$SCOPE-end\">S</a>"
        wrdata ".<a href=\"#$TOPLEVEL.$SCOPE.$SECTION-end\">s</a>"
        wrdata ".<a href=\"#$TOPLEVEL.$SCOPE.$SECTION.$GROUP-end\">g</a>.<a href=\"#$TOPLEVEL.$OPTAG-end\">Op</a>"
        wrdataln "</span>"
      }     
      function wrresult() {
        if [ "$CONDXRET" = "0" ]; then
          wrdataln "&nbsp;T:${ELTIME}&nbsp;&nbsp;C:$faclass&nbsp;&nbsp;"
          wrdataln "<span class=\"resok\">Result:$CONDXRET</span><br>"
        else 
          wrdataln "&nbsp;T:${ELTIME}&nbsp;&nbsp;C:$faclass&nbsp;&nbsp;"
          wrdataln "<span class=\"reserr\">Result:$CONDXRET</span>&nbsp; $1<br>"
        fi
        if [ -n "$RESULTMSG" ]; then wrdata "<pre>$RESULTMSG</pre>"; fi
      }
      function wropdata() { wrnfln "<pre>$OPDATA</pre>"; }
      function wrfixit() {
        if [ -n "$FIXITBLOCK" ]; then wrdataln "<div class=\"fixit\">+++> Hint:<br>$FIXITBLOCK</div><br>"; fi      
      }
    
      if [ "$ABORTFA" != "0" ]; then
        wrdataln "<a name=\"$TOPLEVEL.$OPTAG\"></a>" # add link so cluview refs will still work
        wrdata "<span class=\"skip\">"; wrdata "$TOPLEVEL.$OPTAG $ABORTREASON</span><br>" 
      else
        wrhead; wrlinks; wrresult ""; wropdata 
        if [ "$CONDXRET" != "0" ]; then wrfixit; fi
        wrdataln 
      fi
      wrdataln "<a name=\"$TOPLEVEL.$OPTAG-end\"></a>"
      if [ "$KEYPARM" = "1" ] && [ "$ABORTFA" = "0" ]; then
        if [ "$GROUPKEY" = "0" ]; then local lnkdata="\\_$GROUP.$OPNAME"; else lnkdata=".&nbsp;&nbsp;\\_$OPNAME"; fi
        if [ "$CONDXRET" = "0" ]; then       
          echo "<a href=\"#$TOPLEVEL.$OPTAG\">&nbsp;&nbsp;$lnkdata</a><br>" >> $SECTIONHEADERS
        else
          echo "<a href=\"#$TOPLEVEL.$OPTAG\"><span class=\"reserr\">&nbsp;&nbsp;$lnkdata</span></a><br>" >> $SECTIONHEADERS        
        fi
      fi
    }

    function wrdbdata() { # Formats and writes the sqlite3 database report... tries to be fast :)
      local pwclean="" scrub=""
      # Remove user passwords from the agent db dumps
      if [ "$SCOPE.$SECTION" = "virt.ovmserver" ]; then
        pwclean="`echo \"$OPDATA\" | sed 's/https:\/\/oracle:.*\@/https:\/\/\oracle:pw_removed@/g' | \
          sed 's/agt_passwd.*\,/agt_passwd'\'': '\''pw_removed'\''\,/g'`"
        scrub="1" # separate flag... assumes nothing about pwclean
      fi
      # Single quoting used to for the fields below
      # Escape any data that might contain one with two quotes, per sql92
      local tag="$OPTAG" opmsg=${OPMSG//\'/\'\'} opdata resmsg
      local cmd=${PARM3//\'/\'\'}
      local dt
      if [ -z "$LINKVAL" ]; then dt="I"; else dt="$LINKTYPE"; fi;
      if [ "$REVERSEDR" = "0" ]; then  # Normal field ordering
        if [ -z "$scrub" ]; then opdata=${OPDATA//\'/\'\'}; else opdata=${pwclean//\'/\'\'}; fi
        resmsg=`echo -e ${RESULTMSG//\'/\'\'}`
      else
        if [ -z "$scrub" ]; then resmsg=${OPDATA//\'/\'\'}; else resdata=${pwclean//\'/\'\'}; fi
        opdata=`echo -e ${RESULTMSG//\'/\'\'}`
      fi
      if ! sqlite3 $DBDATA "INSERT INTO [$SESSIONID] values('$SHORTHOSTNAME','$DT','$tag','$opmsg','$dt',\
        '$cmd', '$opdata','$resmsg','$ELTIME','$FACLASS','$KEYPARM','$CONDXRET');" 2>&1; then
        InternalWarning "Writedbdata exited with an error on: $OPTAG"
      fi
    } >> $SCRIPTLOG

    function wrxmldata() { # Formats and writes the xml report
      local dt="I"
      function wrhead()   { wrdataln "<TAG>$TOPLEVEL.$OPTAG</TAG>"; }
      function wrmsg()    { wrdataln "<MSG>$OPMSG</MSG>"; }
      function wrtype()   { if [ -n "$LINKVAL" ]; then dt="$LINKTYPE"; fi; wrdataln "<TYPE>$dt</TYPE>"; }
      function wreltime() { wrdataln "<TIME>$ELTIME</TIME>"; }
      function wrclass()  { wrdataln "<CLASS>$FACLASS</CLASS>"; }
      function wrkey()    { wrdataln "<KEY>$KEYPARM</KEY>"; }
      function wrresult() { wrdataln "<RESULT>$CONDXRET</RESULT>"; }
      function wrfoot()   { wrdataln "</$TOPLEVEL.$OPTAG>"; }
    
      wrdataln "<OP>"
      if [ "$ABORTFA" != "0" ]; then
        wrhead; wrmsg; wrtype;
        wrnfln "<OPDATA><![CDATA["$ABORTREASON"]]></OPDATA>";
        wrnfln "<RMSG><![CDATA[`echo -e $RESULTMSG`]]></RMSG>"
        wreltime; wrclass; wrkey; wrdataln "<OPRESULT>2</OPRESULT>"
      else 
        wrhead; wrmsg; wrtype
        if [ "$REVERSEDR" = "0" ]; then # Normal field ordering
          wrnfln "<DATA><![CDATA[$OPDATA]]></DATA>"
          wrnfln "<RMSG><![CDATA[`echo -e $RESULTMSG`]]></RMSG>"
        else # reverse OPDATA and RESULTMSG per R prefix
          wrnfln "<DATA><![CDATA[$RESULTMSG]]></DATA>"
          wrnfln "<RMSG><![CDATA[`echo -e $OPDATA`]]></RMSG>"
        fi
        wreltime; wrclass; wrkey; wrresult
      fi
      wrdataln "</OP>"; wrdataln
    }

    function wrtextdata() { # Format and write the text report
      function wrhead() {
        wrdata "---> $OPMSG  <$TOPLEVEL.$OPTAG>"
        if [ "$KEYPARM" = "1" ]; then wrdata " Key"; fi
        wrdata " t:$ELTIME c:$FACLASS <Result:$CONDXRET>"
      }
      function wropdata() { if [ "$OPDATA" != "" ]; then wrnfln "$OPDATA"; fi; }
      function wrresult() { if [ "$RESULTMSG" != "" ]; then wrdataln "$RESULTMSG"; fi; }
      function wrfixit() {
        if [ -n "$FIXITBLOCK" ]; then wrdataln "+++> Hint: \n$FIXITBLOCK"; wrdataln; fi
      }
    
      if [ -n "$LINKVAL" ]; then return 0; fi # don't write links to the text report
      if [ "$ABORTFA" != "0" ]; then wrhead; wrdataln "$ABORTREASON" 
      else 
        wrhead;
        if [ "$CONDXRET" = "0" ]; then wrdataln ":ok"
        else 
          wrdata ":fail";
          if [ "$FATYPE" != "$INFO" ]; then wrdataln " +++$FATYPE+++"; else wrdataln; fi           
        fi
        wropdata; wrresult; wrdataln
        if [ "$CONDXRET" != "0" ]; then wrfixit; fi 
      fi
    }

# # # # # # #
#
# Routines to generate html fragments for Clusterview linkage
#
  
    function wrrow() { # Write a report table row
      wrdataln "<tr><td><span class=\"cv\">$OPMSG<br><a href=\"$1\">($OPTAG)</a></span></td><td><span class=\"ce\">"      
      if [ -n "$RESULTMSG" ]; then wrdataln "$RESULTMSG</span></td><td>"; else wrdataln "&nbsp;</span></td><td>"; fi
      if [ -n "$FIXITBLOCK" ]; then wrdataln "<div class=\"cr\">$FIXITBLOCK</div>"; else wrdata "&nbsp;"; fi; wrdataln
      wrdataln "</td></tr>"
    }
    
    function wrwarnings() {
      local s=$TEXTDATA
      TEXTDATA=$WARNINGTEXT; wrtextdata
      TEXTDATA=$WARNINGHTML; wrrow "#$TOPLEVEL.$OPTAG"
      TEXTDATA=$WARNINGCLU;  wrrow "$SESSIONID/vmpscan.htm#$TOPLEVEL.$OPTAG"
      TEXTDATA=$s
    }
    
    function wrerrors() {
      local s=$TEXTDATA
      TEXTDATA=$ERRORTEXT; wrtextdata
      TEXTDATA=$ERRORHTML; wrrow "#$TOPLEVEL.$OPTAG"
      TEXTDATA=$ERRORCLU;  wrrow "$SESSIONID/vmpscan.htm#$TOPLEVEL.$OPTAG"
      TEXTDATA=$s
    }

    function wrdb() {
      if ! [ -f "$DBDATA" ]; then
        local DBTABLE="hostname varchar, sessdate varchar, tag varchar, msg varchar, type char, cmd varchar, data text, rmsg text,\
        extime datetime, class varchar, key char, result integer,  primary key(hostname,sessdate,tag)"
        sqlite3 $DBDATA "CREATE TABLE [$SESSIONID] ($DBTABLE);"
      fi
      wrdbdata
    }
    
    function wrxml() {
      local s=$TEXTDATA
      TEXTDATA=$XMLDATA 
      if ! [ -f "$TEXTDATA" ]; then
        wrdataln "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
        wrdataln "<$SESSIONID>"
      fi
      wrxmldata
      TEXTDATA=$s    
    }

    function wrhtml() {
      local s=$TEXTDATA
      TEXTDATA=$HTMLDATA; wrhtmldata; TEXTDATA=$s    
    }

    function wrsumkeys() { # Write summary key data
      if [ "$ABORTFA" != "0" ]; then return 0; fi
      local s=$TEXTDATA
      echo "$OPTAG $CONDXRET $FLAGATTR $ELTIME $faclass" >> $SUMKEYS.$SCOPE
      TEXTDATA=$SUMDATA.$SCOPE; wrdataln "<$OPTAG>"; wrdataln "$RESULTMSG"; wrnfln "$OPDATA"; wrdataln "</$OPTAG>";         
      TEXTDATA=$s
    }

    function wrallkeys() { # Write all report data as keys
      if [ "$ABORTFA" != "0" ]; then return 0; fi
      local s=$TEXTDATA
      echo "$OPTAG $CONDXRET $FLAGATTR $ELTIME $faclass" >> $ALLKEYS.$SCOPE
      TEXTDATA=$ALLDATA.$SCOPE; wrdataln "<$OPTAG>"; wrdataln "$RESULTMSG"; wrnfln "$OPDATA"; wrdataln "</$OPTAG>";
      TEXTDATA=$s
    }

    function wrhc() { # Write healthcheck info
      if [ "$CONDXRET" != "0" ]; then
        local s=$TEXTDATA; let "++TOTALHCFLAGS"; if [ "$JUSTHC" = "1" ]; then echo -n "$TOTALHCFLAGS"; fi
        TEXTDATA=$SYSHEALTHTEXT; wrdataln "$TOTALHCFLAGS: $OPMSG - $OPTAG"
        if [ -n "$RESULTMSG" ]; then wrdataln "$RESULTMSG"; else wrdataln; fi
        TEXTDATA=$SYSHEALTHHTML; wrrow "#$TOPLEVEL.$OPTAG"
        TEXTDATA=$SYSHEALTHCLU;  wrrow "$SESSIONID/vmpscan.htm#$TOPLEVEL.$OPTAG"
        TEXTDATA=$s
      else if [ "$JUSTHC" = "1" ]; then echo -n "+"; fi
      fi
    }

    # wr entry point: main report writer routine
    if [ "$CONDXRET" != "0" ]; then
      logit 4 "End:$OPTAG:Fail:$ELTIME"
      GetFixitText $OPTAG 1 # get fixit block if there's been an error
      if [ "$FATYPE" = "$ERROR" ]; then faclass=`echo $FACLASS | sed -e 's/e/\<span class=\"reserr\">E\<\/span\>/g'`
      elif [ "$FATYPE" = "$WARNING" ]; then faclass=`echo $FACLASS | sed -e 's/w/\<span class=\"reswarn\">W\<\/span\>/g'`
      elif [ "$FATYPE" = "$INFO" ]; then faclass=`echo $FACLASS | sed -e 's/i/\<span class=\"resinfo\">I\<\/span\>/g'`
      fi      
    else logit 4 "End:$OPTAG:Pass:$ELTIME"
    fi    
    if [ "$HCPARM" = "1" ]; then wrhc; fi; if [ "$JUSTHC" = "1" ]; then echo -n "-"; return 0; fi;
    if [ "$KEYPARM" = "1" ]; then wrsumkeys; fi
    if [ "$EMITTEXT" = "1" ]; then wrtextdata; fi
    if [ "$EMITXML" = "1" ]; then wrxml; fi
    if [ "$EMITDB" = "1" ]; then wrdb; fi
    REVERSEDR="0"; # Resets R function for normalizing opdata and resultmsg
    if [ "$EMITHTML" = "1" ]; then
      wrhtml; wrallkeys
      if [ "$FATYPE" = "$WARNING" ] && [ "$CONDXRET" != "0" ]; then wrwarnings; fi
      if [ "$FATYPE" = "$ERROR" ] && [ "$CONDXRET" != "0" ]; then wrerrors; fi
    fi
    KEYPARM=0
  }

  function TestOpTimeout() { # Generate another testop record if the command timed out
    if [ "$ABORTFA" = "0" ] || [ "$JUSTHC" = "1" ]; then 
    if [ "$ELTIMESEC" -gt "$OPTIMEOUT" ]; then
      RESULTMSG="Command Timeout: Operation took $ELTIMESEC seconds with timeout value of $OPTIMEOUT"
      OPNAME="${OPNAME}_timeout"; OPTAG="${OPTAG}_timeout"
      OPMSG="${OPMSG} Timeout"; OPSTATUS="1"; CONDXRET="1"; PASSED="1";
      let "++GROUPWARNINGS"; FATYPE=$WARNING; FACLASS="/w"
      OPDATA=""; KHC; wr
    fi
    fi
  }

  function GetTagInx() {
    if [ "$1" = "" ] || [ "$1" = "0" ]; then INX="0"
    else if ! LookupOPData "$1"; then FatalError "Cannot find tag: $1"; fi
    fi
  }

  function GrepTarget() { # Greps a string in OPSTATUS. Grep options can be included in OPDATA
    chkparms 4; GetTagInx "$1"; # 6th parm is optional index into array... default:0
    OPDATA=`echo ${OPDATS[$INX]} | grep "$OPDATA"`; OPSTATUS=$?
  }

  function CompareNumerics() { # Takes an operand and two limit parameters in min max order
    local opmsg=$1 sig=$2 value=$3
      
    function DoACCLimit() { # Apply an expression test to the current value in the accumulator
      local exp="$1" tag="$2"
      OPMSG="$opmsg $exp"; OPTAG="$SCOPE.$SECTION.$GROUP.${sig}_$tag"
      if (( "$value" "$exp" )); then passfail "0" "" ""; else passfail "1" "" ""; fi
      if [ "$PASSED" = "0" ]; then OPDATA=''
      else OPDATA="$sig.$tag should be $1 and is $value"
      fi
      wr
    }
    
    OPMSG=$1; OPNAME=$sig; OPTAG="$SCOPE.$SECTION.$GROUP.$OPNAME"; OPDATA="$value";
    SetACC; passfail $OPSTATUS "" ""; wr; FATYPE=""
    if [ "$4" != "" ]; then DoACCLimit "$4" "$5"; fi
    if [ "$6" != "" ]; then DoACCLimit "$6" "$7"; fi
  }

# # # # # # # # #
#
# Core Parameter and Result Logic
#
#
  function WriteTag() { # write doc tags for external editing (-z|-Z)
    local pf start end
    if [ "$DEBUGGING" = "1" ]; then echo tag:$OPTAG condx:$CONDXRET; fi
    GetFixitText $OPTAG 1; local pf=$1; local start=""; local end=""
    if [ -n "$FIXITBLOCK" ]; then FIXITBLOCK="\n$FIXITBLOCK"; fi
    if [ -n "$pf" ]; then pf="\nR:$pf"; else pf=$pf; fi
    if [ -n "$FIXITBLOCK" ] || [ -n "$pf" ]; then end="\n"; fi
    if [ -n "$FIXITBLOCK" ] && [ -n "$pf" ]; then pf="$pf\n"; fi
    pf="$pf$FIXITBLOCK$end"
    case "$WRITETAGS" in
      1) echo $OPTAG:$FATYPE;;
      2) echo -e "<$OPTAG>$pf</$OPTAG>";;
    esac
  } >> $ALLTAGS

  function ProcessExcludeList() { # Process hierarchical excludes: implements -X
    local i m
    if [ -n "$EXCLUDES" ]; then
      for i in $EXCLUDES; do
        m=${OPTAG#$i};
        if [ "${#m}" -lt "${#OPTAG}" ]; then ABORTFA="1"; ABORTREASON="- excluded by -X $i"; break; fi
      done
    fi
  }

  # This routine is where testop results and logic sense are computed
  #
  function passfail() { # Set the global CONDXRET flag for test result: xor of PASSED and CONDXREQ
    GetElapsed $TESTOPSTART
    if [ "$WRITETAGS" != "0" ]; then WriteTag "$2"; fi
    if [ "$ABORTFA" = "0" ] || [ "$JUSTHC" = "1" ]; then     
      if [ "$1" = "0" ]; then PASSED="0"; else PASSED="1"; fi
      CONDXRET=$CONDXREQ;
      let "CONDXRET^=PASSED" # xor actual result with requested FS ifz/ifnz logic
      if [ "$DEBUGGING" = "1" ]; then wrcon "Result: $CONDXRET  Elapsed: $ELTIME\n\n"; fi
      if [ "$2" = "1" ]; then return; fi # Test but don't count the result... for get command
      case "$FATYPE" in
        $WARNING) FACLASS="${FACLASS}/w";; $ERROR) FACLASS="${FACLASS}/e";; $INFO) FACLASS="${FACLASS}/i";;
      esac
      if [ "$CONDXRET" = "0" ]; then let "++GROUPOK"; RESULTMSG="$3"
      else
        RESULTMSG="$2"
        case "$FATYPE" in
          $WARNING) let "++GROUPWARNINGS"; FLAGATTR="warn";;
          $ERROR)   let "++GROUPERRORS"; FLAGATTR="error";;
          *) FATYPE=$INFO;;
        esac
      fi
      CmdSleep
    else if [ "$DEBUGGING" = "1" ]; then wrcon "Result: Skipped\n\n"; fi
    fi
  }

  function SetACC() { # Move parameters to FA accumulator (register 0)
    OPTAGS[0]="$OPTAG"; OPDATS[0]="$OPDATA"; OPMSGS[0]="$OPMSG"; OPSTATS[0]="$OPSTATUS"
  }
  
  function SetID() { # Globally set the tag value for this testop
    OPTAG="$SCOPE.$SECTION.$GROUP.$PARM4"; OPNAME=$PARM4
    ProcessExcludeList
    if [ "$ABORTFA" = "0" ]; then logit 4 "Start:$OPTAG"; fi
    if [ "$DEBUGGING" = "1" ]; then
     local xstat=""
     if [ "$ABORTFA" = "0" ]; then xstat="Executed"; else xstat="Skipped"; fi
     echo "-->Optag:$OPTAG  -  Status: $xstat"
     echo -e "1:$FAOP  2:$PARM2  3:$PARM3  4:$PARM4  $PARM5 $PARM6\n"
     echo "1:$FAOP  2:$PARM2  3:$PARM3  4:$PARM4  $PARM5 $PARM6" >> $VMPDIAGS/cmdlist.txt
    fi
  }

  OPID=""
  function GetOpID() { OPID=$((TOTALOK+TOTALWARNINGS+TOTALERRORS)); } # unique number for each testop
 
  function chkparms() { # Verify the correct number of parameters have been passed... squawk if not
    if [ "$NUMPARMS" -lt "$1" ]; then
      FatalError "$1 are required but only $NUMPARMS parameters were provided for the $FAOP command:\n $PARM2 $PARM3 $PARM4 $PARM5 $PARM6"
    fi
  }

  function DoLink() { # Execute a command and create an inline report link to the return data and file size
    local sz=""
    if [ "$ABORTFA" != "0" ]; then OPSTATUS="0"
    else 
      chkparms 4; OPMSG=$PARM2
      OPDATA="`eval "$PARM3" 2>&1`"; OPSTATUS=$?; LINKVAL="$PARM4"
      if [ -f "$VMPDIAGS/$PARM4" ]; then fsize "$VMPDIAGS/$PARM4"; sz=" (size: $FSIZE)"; LINKTYPE="F"
      elif [ -d "$VMPDIAGS/$PARM4" ]; then LINKTYPE="D"
      else LINKTYPE="N"
      fi
      if [ -n "$1" ] && [[ ( -f "$VMPDIAGS/$PARM4" ) || ( -d "$VMPDIAGS/$PARM4" ) ]]; then FLink "$PARM4"; fi
      PARM4="`echo ${PARM4##*/}|tr '.' '_'`_link" # strip path / and conv fn dots to underscores
      SetID; SetACC; passfail "$OPSTATUS" "$PARM5" "$PARM6"
      if [ "$LINKTYPE" != "N" ]; then
        wr; echo "<pre><a href=\"$LINKVAL\">Link to $PARM2 data$sz</a></pre>" >> $HTMLDATA; KHC; TestOpTimeout
      else 
        OPDATA="$PARM2 not found on this system"; wr
      fi
      LINKVAL=""
    fi
  }

  #
  # ---> Main body of FAE
  #
  # The wr call writes the testop data to the report archive. The cmdopen allows the OPDATA
  # to be parsed and reformatted by the caller before being written by a cmdclose call.
  #
  
  FAOP=$1; PARM2=${2:-""}; PARM3=${3:-""}; PARM4=${4:-""}; PARM5=${5:-""}; PARM6=${6:-""}; NUMPARMS=$#

  GetNow; TESTOPSTART=$NOW
  
  case "$FAOP" in
    cmd) # Execute a command and generate inline report data
      chkparms 4; OPMSG=$2; SetID;
        if [ "$ABORTFA" = "0" ]; then OPDATA="`eval "$3" 2>&1`"; OPSTATUS=$?; else OPSTATUS="0"; fi 
        SetACC; passfail "$OPSTATUS" "$PARM5" "$PARM6"; wr; KHC; TestOpTimeout
      ;;
    cmdx) # Execute a command, discard return data, but set OPSTATUS
      chkparms 4; OPMSG=$2; SetID;
      if [ "$ABORTFA" = "0" ]; then OPDATA=`eval $3 >/dev/null 2>&1`; OPSTATUS=$?; else OPSTATUS="0"; fi
      SetACC; passfail "$OPSTATUS" "$PARM5" "$PARM6"; wr; KHC; TestOpTimeout
      ;;
    cmdq) # Execute a command if ABORTFA = 0. Return data but do not generate a report record
      PARM3=$PARM2; GetOpID; PARM4=$OPID; SetID
      if [ "$ABORTFA" = "0" ]; then OPDATA="`eval $PARM2 2>&1`"; OPSTATUS=$?; fi
      ;;
    dolink)  DoLink "";;   # Create an inline link
    dolinks) DoLink "1";;  # Create an inline link and add to hostview nav table
    cmdopen) # Begin a compound test operation
      SAVEOPSTART=$TESTOPSTART
      chkparms 4; OPMSG=$2; SetID;
      if [ "$ABORTFA" = "0" ]; then OPDATA=`eval $3 2>&1`; OPSTATUS=$?; else OPSTATUS="0"; fi 
      ;;
    cmdclose) # End a compound test operation and write the report record
      TESTOPSTART=$SAVEOPSTART;
      if [ "$ABORTFA" = "0" ]; then SetACC; passfail "$OPSTATUS" "$PARM5" "$PARM6"; wr; KHC; TestOpTimeout; fi
      ;;
    cmdsave) # Execute a testop and save the accumulator for later recall 
      chkparms 4; OPMSG=$2; SetID;
      if [ "$ABORTFA" = "0" ]; then OPDATA=`eval $3 2>&1`; OPSTATUS=$?; else OPSTATUS="0"; fi 
      SetACC; passfail "$OPSTATUS" "$PARM5" "$PARM6"; SaveOPData ""; wr; KHC; TestOpTimeout
      ;;
    cmdrecall) # load a previous testop and clock the FAE
      if [ "$ABORTFA" = "0" ]; then LoadOPData $2; SetACC; passfail "$OPSTATUS" "$PARM3" "$PARM4"; fi   
      ;; 
    savetag) if [ "$ABORTFA" = "0" ]; then SaveOPData ""; fi;;

    dogrep) SetID; if [ "$ABORTFA" = "0" ]; then OPMSG=$2; OPDATA="$3"; GrepTarget ${7:-""}; wr; KHC; TestOpTimeout; fi;;

    getsysctl)
      SetID;
      if [ "$ABORTFA" = "0" ]; then 
        local val="`sysctl -n $2 2>&1`"; OPSTATUS=$?
        CompareNumerics $2 "${2//./_}" "$val" "$PARM3" "$PARM4" "$PARM5" "$PARM6"
      fi
      ;;

    meminfo)
      SetID;
      if [ "$ABORTFA" = "0" ]; then 
        local opname=`echo $2  | tr '[A-Z]' '[a-z]'` # Convert the tag to lower case (normalize meminfo)
        local val="`cat /proc/meminfo | grep $2 | xargs | cut -d' ' -f2`"; OPSTATUS=$?
        CompareNumerics "$2" $opname $val "$PARM3" "$PARM4" "$PARM5" "$PARM6"
      fi
      ;;
    comp) if [ "$ABORTFA" = "0" ]; then CompareNumerics "$PARM2" "$PARM3" "$PARM4" "$PARM5" "$PARM6"; fi;;

    link)
      local fsz=""
      if [ "$ABORTFA" = "0" ]; then
        if [ -n "$PARM4" ]; then fsz=" (size: $PARM4)"
        else
          if [ -d "$VMPDIAGS/$3" ]; then fsz=" directory "
          else fsize "$VMPDIAGS/$3"; if [ -n "$FSIZE" ]; then fsz=" (size: $FSIZE)"; fi
          fi
        fi
        echo "<pre><a href=\"$3\">$2$fsz</a></pre>" >> $HTMLDATA
      fi
      ;;
    # Tag hierarchy support
    root) # Set tag root (hostname) for this scan
       if [ -n "$TOPLEVEL" ]; then FatalError "Report root already set: $TOPLEVEL. Cannot be reset to $3"
       else chkparms 3; TOPLEVEL=$3; flushgroupmsgs "" 1
       fi;;
    scope) # Set scope
      flushgroupmsgs "$SCOPE"
      if [ -n "$SCOPE" ]; then logit 1 "End:$SCOPE"; fi; logit 1 "Start:$3"
      if [ "$JUSTHC" = "1" ]; then echo; echo -n "$3: "; fi
      echo "<a name=\"$TOPLEVEL.$SCOPE.$SECTION.$GROUP-end\"></a>" >> $HTMLDATA
      echo "<a name=\"$TOPLEVEL.$SCOPE.$SECTION-end\"></a>" >> $HTMLDATA
      echo "<a name=\"$TOPLEVEL.$SCOPE-end\"></a>" >> $HTMLDATA
      if [ "$SCOPE" = "" ]; then
        echo "<tr VALIGN=TOP><td>" >> $SECTIONHEADERS; else echo "</td><td>" >> $SECTIONHEADERS
      fi
      chkparms 3; SCOPE=$3; SECTION=""; GROUP="" OPTAG="$TOPLEVEL.$SCOPE"; ResetChains;
      echo "<span class=\"tagh\"><a href=\"#$OPTAG\">${OPTAG#*.}</a></span><br>" >> $SECTIONHEADERS
      echo "<a name=\"$OPTAG\"></a><hr><br><div class=\"scope\">Scope: $OPTAG</div><br>" >> $HTMLDATA
      wrcon "\n==> Scope: $2 - <$OPTAG>\n"
      wrdata "\n============> Scope: $2\n"
      ;;
    section) # Set section
      flushgroupmsgs "$SCOPE.$SECTION"; chkparms 3; GROUPSTART=$(($(date +%s%N)/1000000))
      if [ -n "$SECTION" ]; then logit 2 "End:$SCOPE.$SECTION"; fi; logit 2 "Start:$SCOPE.$3"
      echo "<a name=\"$TOPLEVEL.$SCOPE.$SECTION.$GROUP-end\"></a>" >> $HTMLDATA
      echo "<a name=\"$TOPLEVEL.$SCOPE.$SECTION-end\"></a>" >> $HTMLDATA
      SECTION=$3; GROUP="" OPTAG="$TOPLEVEL.$SCOPE.$SECTION"; ResetChains
      echo "<span class=\"tagh\"><a href=\"#$OPTAG\">${OPTAG#*.}</a></span><br>" >> $SECTIONHEADERS
      echo "<a name=\"$OPTAG\"></a><div class=\"sec\">Section: $OPTAG</div>" >> $HTMLDATA
      wrcon  "    * $2 - <$OPTAG>\n"
      wrdata "\n********** Section: $2 <$OPTAG>\n"
      ;;
    group) # Set group
      local showgrp=${4:-""}
      chkparms 3; flushgroupmsgs "$SCOPE.$SECTION.$GROUP"
      if [ -n "$GROUP" ]; then logit 3 "End:$SCOPE.$SECTION.$GROUP"; fi; logit 3 "Start:$SCOPE.$SECTION.$3"
      echo "<a name=\"$TOPLEVEL.$SCOPE.$SECTION.$GROUP-end\"></a>" >> $HTMLDATA
      GROUP=$3 OPTAG="$TOPLEVEL.$SCOPE.$SECTION.$GROUP"; ResetChains
      local constr="        - $2"; PREVLINEPOS=${#constr}     
      if [ -z "$showgrp" ]; then
        echo "<a href=\"#$OPTAG\">&nbsp;&nbsp;\\_$GROUP</a><br>" >> $SECTIONHEADERS
        GROUPKEY="1"
      fi
      if [ "$KEYPARM" = "1" ]; then echo "<a href=\"#$OPTAG\">&nbsp;|-$GROUP</a><br>" >> $SECTIONHEADERS; fi
      echo "<br><a name=\"$OPTAG\"></a><div class=\"grp\">Group: $OPTAG</div><br>" >> $HTMLDATA
      wrcon  "$constr"
      wrdata "\n######## Group: $2\n\n"
      ;;

    starttimer) STARTTIME=`date +'%s'`;;
    elapsed)    ELAPSEDTIME=$((`date +'%s'` - STARTTIME));;

    # Console and output file support... shouldn't be needed very often
    conmsg) echo -ne $PARM2;; # Write message to the console
    conmsgln) echo -e $PARM2;;
    msg) wrreports "$PARM2";; # Write inline message to the report
    msgln) wrreportsln "$PARM2";;
    
    dump) dumpFAE;; # Diagnostic dump of FAE context and related state variables
    * ) FatalError "$ARCTAG: unknown test operation \"$1\""; KEYPARM=0; return 1 ;;
  esac
 KEYPARM="0"; HCPARM="0"; FACLASS=""; FLAGATTR="&nbsp;"; OPTIMEOUT=$CMDTIMEOUT 
 if [ "$JUSTHC" = "1" ]; then ABORTFA="1"; fi
 return $CONDXRET
}

# Implement conditional chaining logic for FS primitives below
function ResetChains() {  if [ "$JUSTHC" = "0" ]; then ABORTFA="0"; fi; ABORTREASON=""; }
function doelse() { let "ABORTFA^=1"; } 
function ChainCheck() {
  if [ "$ABORTFA" = "1" ]; then return; fi  
  if [ "$CONDXRET" = "1" ]; then ABORTFA="1"; ABORTREASON=" ->skipped: ${OPTAG##*.} dependency not met"; fi
}
function CONDX() { if [ "$ABORTFA" = "1" ]; then FATYPE=$INFO; else FATYPE=$2; fi; CONDXREQ=$3; }

# # # # # # # # # # # # # # # #
#
# ---> FAE Interface
#
# Implements conditional logic and provides a severity tag for FA operations.
# Severity level suffixes are error (e), warning (w) and the info default.
#
# Chaining is started by an ifz or ifnz and the command set terminates when there
# is a failed condition in the chain or the command has an else or endif prefix.
#
# # # # # # # # # # # # # # # #
#
# This set does not chain test the FAE exit status, but does provide a severity tag
#
# Look for a zero return as a "pass"

function FS()  { # Informational FS
  if [ -n "$PLUGINPATH" ]; then case $1 in section|group) RunExtension $1; esac; fi
  CONDX "$?" "$INFO" "0"; FAE "$@"
}

function FSw() { CONDX "$?" "$WARNING" "0"; FAE "$@"; } # Warning FS 
function FSe() { CONDX "$?" "$ERROR" "0"; FAE "$@"; }   # Error FS

# Look for a non-zero return as a "pass"
function nzFS()  { CONDX "$?" "$INFO" "1"; FAE "$@"; }    # Informational FS
function nzFSw() { CONDX "$?" "$WARNING" "1"; FAE "$@"; } # Warning FS 
function nzFSe() { CONDX "$?" "$ERROR" "1"; FAE "$@"; }   # Error FS

# Conditionals used to terminate chains when a dependency isn't met

# Look for a zero return to continue the chain... terminate if nz
function ifzFS()  { CONDX "$?" "$INFO" "0"; FAE "$@";    ChainCheck; }
function ifzFSw() { CONDX "$?" "$WARNING" "0"; FAE "$@"; ChainCheck; }
function ifzFSe() { CONDX "$?" "$ERROR" "0"; FAE "$@";   ChainCheck; }

# Look for a non-zero return to continue the chain... terminate if z
function ifnzFS()  { CONDX "$?" "$INFO" "1"; FAE "$@";    ChainCheck; }
function ifnzFSw() { CONDX "$?" "$WARNING" "1"; FAE "$@"; ChainCheck; }
function ifnzFSe() { CONDX "$?" "$ERROR" "1"; FAE "$@";   ChainCheck; }

# If a chain has been terminated, resume it with an else
function elseFS()  { OPSTATUS="$?"; doelse; FATYPE="$INFO"; FAE "$@";}
function elseFSw() { OPSTATUS="$?"; doelse; FATYPE="$WARNING"; FAE "$@";}
function elseFSe() { OPSTATUS="$?"; doelse; FATYPE="$ERROR"; FAE "$@"; }

# Unconditionally end a chain... group, section or scope ops also end chaining
function endifFS()  { ResetChains; }

# End of FAE

# # # # # #
#
# Testop Utilities
#

function GetMachineRole() { # Determine OS type and role... set global vars
 HOSTTYPE=$BAREMETAL; ROLE=""; RETCODE=0;
  if [ -d /proc/xen ]; then
    if grep -q "control_d" /proc/xen/capabilities > /dev/null 2>&1; then HOSTTYPE=$XENDOM0
    else HOSTTYPE=$XENDOMU
    fi
  fi
  if grep "Oracle VM server release 2.2" /etc/ovs-release > /dev/null 2>&1; then 
    OVMSERVER=`cat /etc/ovs-release`; ROLE="$OVMSERVER"; OVMVERSION="2.2"
  elif grep "Oracle VM server release 3." /etc/ovs-release > /dev/null 2>&1; then 
    OVMSERVER=`cat /etc/ovs-release`; ROLE="$OVMSERVER"; OVMVERSION="3.0"
  elif rpm --quiet -q ovs-manager > /dev/null 2>&1; then ROLE="$OVMMANAGER"
  elif [ -f "/u01/app/oracle/ovm-manager-3/.config" ]; then ROLE="$OVMMANAGER"; OVMVERSION="3.0"
  elif [ -f /etc/enterprise-release ]; then GENERIC="`cat /etc/enterprise-release`"; ROLE="$GENERIC" 
  elif [ -f /etc/redhat-release ]; then GENERIC="`cat /etc/redhat-release`"; ROLE="$GENERIC"
  else ROLE="Not_Supported"; return 1 # not a RH, EL or Fedora based distro... maybe someday, but not today 
  fi
}

function ServiceCheck() { # $1=package name  $2=service name  $3: w=warning if disabled, e=error if disabled
  local pkgname="$1" srvname="$2" errflag=${3:-""} faclass=$FACLASS odata # push FACLASS... applies to all ops here
  local failmsg=${4:-"$srvname is not enabled"} passmsg=${5:-"$srvname is enabled"} kp="$KEYPARM"; KEYPARM="0"
  ifzFS cmd "$1 installed" "grep ^$pkgname $VMPDIAGS/misc/pkg-list" ${pkgname}_installed "$pkgname not installed" "$pkgname installed" 
  FACLASS="$faclass"
  FS cmd "chkconfig --list $srvname" "chkconfig --list $srvname" ${srvname}_sysv
  FACLASS="$faclass"
  local opdata="$OPDATA"
  FS$errflag cmd "$srvname service at boot" "echo $OPDATA|grep :on" ${srvname}_enabled "$failmsg" "$passmsg"
  if [ "$kp" != "0" ]; then K; fi
  FS$errflag cmd "service $srvname status" "service $srvname status" ${srvname}_sysv_status
}

# # # # #
#
# Start of Testop procedures
#
# Global functions are generally defined by scope.section

# # # # # # # # #
#
# ---> Scope: OS
#

function MachineTypeAndRole() {
  FS section "Machine role" role
  FS group "Host and Product Info" host
     FS cmdsave "Host Type" "echo \"$HOSTTYPE\"" type
  if [ "$ROLE" != "" ]; then FS cmdsave "Host role" "echo \"$ROLE\"" role
  else 
    FS cmdsave "This system is not supported" "echo \"Not Supported\"" role
    RETCODE=1 # not a supported machine
  fi
  FS group "$ARCTAG" "$ARCTAG"
    local uid=`id -u`
    KHC; FSw cmd "Running as root" "[ "$uid" = "0" ]" rootuser "Running as non-root is ok, but the $ARCTAG report will not include some privileged system information" "Running as root"
    FS cmd "Group ID Tag" "echo \"$IDTAG\"" idtag
    FS cmd "SessionID" "echo $SESSIONID" sessionid
    FS cmd "Session Time" "echo $SESSTIME" sessiontime
    FS cmd "Collector" "echo -e \"$ARCTAG $VERSION.$REVISION $LASTUPDATE\nPath:$ME\n$CONFMSG\"" version
    R; FSw cmd "$ARCTAG integrity check" "[ \"$REFMD5\" = \"$SCRIPTMD5\" ]" integrity "$ARCTAG has been modified or damaged\nREF:$REFMD5 != CAL:$SCRIPTMD5"\
      "$ARCTAG is ok\nREF:$REFMD5 = CAL:$SCRIPTMD5"
    FS cmd "vmpscan.conf for this session" "$CAT $VMPCONF" vmpscan_conf
    R; KHC; FSw cmd "Host Precheck" "[ -z \"$PCKFAILS\" ]" precheck "$PCKFAILS" "All host prechecks passed" 
  FS group "Running User" user
    K; FS cmd "User running scan" "id" id
    FS dolink "printenv" "printenv > $VMPDIAGS/misc/printenv" misc/printenv
    FS dolink "/etc/profile" "cp /etc/profile $VMPDIAGS/etc" etc/profile
    FS dolink "/etc/profile.d" "cp -a /etc/profile.d $VMPDIAGS/etc" etc/profile.d
    FS dolink "/etc/bashrc" "cp /etc/bashrc $VMPDIAGS/etc" etc/bashrc
}

function OSHardware() {
  FS section "Hardware, CPU and PCI information" hw
  FS group "dmidecode" dmidecode
    if [ "$HOSTTYPE" != "$XENDOMU" ] && [ "`id -u`" = "0" ]; then
      FS cmd "dmidecode for bios data" "dmidecode | grep -A 3 -i 'BIOS Information'" bios
      FS cmd "dmidecode for system data" "dmidecode | grep -A 3 -i 'System Information'" sys
      FS dolinks "dmidecode" "dmidecode > $VMPDIAGS/misc/dmidecode 2>&1" misc/dmidecode
    else
      FS cmd "dmidecode" "/bin/false" nodmidata "Cannot acquire dmidecode info due to permissions or host type"
    fi

  FS group "cpu info" cpuinfo
    FS dolinks "/proc/cpuinfo" "cat /proc/cpuinfo > $VMPDIAGS/proc/cpuinfo" proc/cpuinfo
    K; FS cmd "cpu info summary" "cat /proc/cpuinfo | head -n25 | grep 'vendor\|family\|model\|cores\|flags\|stepping'" cpuinfo_summary
    FS link "Link to full cpuinfo" "proc/cpuinfo"
    ht="not supported"
    sockets=`grep physical\ id /proc/cpuinfo |sort|uniq|wc -l`
    siblings=`grep -m 1 siblings /proc/cpuinfo |cut -d':' -f2|xargs`
    if [ -n "$siblings" ]; then
      if [ "$HOSTTYPE" = "$BAREMETAL" ]; then 
        cores=`grep -m 1 cpu\ cores /proc/cpuinfo |cut -d':' -f2|xargs`
        threadspercore=$(($siblings/$cores))
      elif [ "$HOSTTYPE" = "$XENDOM0" ]; then
        cores=`xm info | grep ^nr_cpus | cut -d':' -f2 | xargs`
        threadspercore=`xm info | grep ^threads_per_core | cut -d':' -f2 | xargs`
      elif [ "$HOSTTYPE" = "$XENDOMU" ]; then
        cores=`grep -m 1 cpu\ cores /proc/cpuinfo |cut -d':' -f2|xargs`
        threadspercore=$(($siblings/$cores))
      fi
      if grep flags /proc/cpuinfo | grep -wq ht; then
        if [ $threadspercore -gt 1 ]; then ht=on; else ht=off; fi
      fi
      K; FS cmd "Sockets" "echo $sockets" num_sockets
      K; FS cmd "Cores" "echo $cores" num_cores
    fi
    K; FS cmd "Hyperthreading" "echo $ht" hyperthreading
 
  FS group "lspci data" lspci_info
    FS cmd "lspci" "lspci" lspci 
    FS cmd "lspci -n" "lspci -n" lspci_-n
    FS dolinks "lspci -nvvv" "lspci -nvvv > $VMPDIAGS/misc/lspci_-nvvv" misc/lspci_-nvvv
    FS dolinks "lspci -vvv" "lspci -vvv > $VMPDIAGS/misc/lspci_-vvv" misc/lspci_-vvv
    FS cmd "lspci -tv" "lspci -tv" lspci_-tv
    if which lsusb > /dev/null 2>&1; then
      FS group "usb" usb
        FS cmd "lsusb" "lsusb" lsusb
        FS cmd "lsusb -tv" "lsusb -tv" lsusb_-tv
        FS dolink "lsusb -v" "lsusb -v > $VMPDIAGS/misc/lsusb_-v" misc/lsusb_-v
    fi
  FS group "hal and ipmi" halipmi
      FS dolinks "lshal" "lshal > $VMPDIAGS/misc/lshal" misc/lshal
      if [ -f  /etc/sysconfig/hwconf ]; then
        FS dolinks "/etc/sysconfig/hwconf" "cat /etc/sysconfig/hwconf > $VMPDIAGS/etc/sysconfig/hwconf" etc/sysconfig/hwconf
      fi
      if [ -f "/etc/sysconfig/ipmi" ]; then FS cmd "/etc/sysconfig/ipmi" "$CAT /etc/sysconfig/ipmi" ipmi; fi
    FS dolink "/etc/cups" "cp -a /etc/cups $VMPDIAGS/etc/cups" etc/cups
}

function OSConfiguration() {
  local i
  FS section "OS info" conf
  FS group "Boot" boot
    BP; FS cmd "grub.conf" "$CAT /boot/grub/grub.conf" grub_conf
    FS cmd "/boot/grub/device.map" "cat /boot/grub/device.map" grub_devmap
    FS cmd "/etc/sysconfig/grub" "$CAT /etc/sysconfig/grub" grub
  FS group "Installed Packages" packages
    A; FS dolinks "Installed Packages" "$GETPACKAGELIST | sort -n > $VMPDIAGS/misc/pkg-list" misc/pkg-list
    BP; K; FS cmd "Number of Installed Packages" "wc $VMPDIAGS/misc/pkg-list | xargs | cut -d' ' -f1" pkg_count
    FS link "Click for full package listing" "misc/pkg-list" 
  FS group "OS Version and Vendor" version_vendor
    if [ "$ABORTFA" = "0" ]; then local reldat="`for i in /etc/*-release; do echo $i; cat $i; done`"; fi
    FS cmd "/etc/*-release" "echo \"$reldat\"" release
    FS cmd "lsb_release -a" "lsb_release -a" lsb_release_-a
    FS cmd "*-release packages" "grep -release $VMPDIAGS/misc/pkg-list" release_packages
    FS cmd "/etc/issue" "cat /etc/issue" issue
  FS group "i18n" i18n
    FS cmd "locale" "locale" locale
  FS group  "Configuration" sysid
    BP; K; FS cmd "Hostname" "hostname" 'hostname'
    BP; FS cmd "Short hostname" "hostname|cut -d'.' -f1" hostname_-s
    BP; FS cmd "domainname" "domainname" domainname
    FS cmd "uname -a" "uname -a" uname_-a
    K; FS cmd "uname -r" "uname -r" uname_-r
    A; FS cmd "kernel version base" "echo $KVER" kver_base
    FS cmd "os arch" "uname -i" arch
  FS group "OS Services" sysvinit
    FS cmd "inittab" "$CAT /etc/inittab" inittab
    K; FS cmd "runlevel" "runlevel" runlevel
    BP; K; FS cmd "Active services" "chkconfig --list | grep :on" active
    FS cmdopen "Disabled services" "chkconfig --list | tr '\t' ' ' | grep -v :on | cut -d' ' -f1 | xargs | sort" inactive
      local n=0 w=""
      for i in $OPDATA; do # format the disabled services
        let "++n"; if ! (( $n % 8 )); then w=$w`echo -en "\n$i  "`; else w=`echo -en "$w$i  "`; fi
      done
      OPDATA=$w
    FS cmdclose
    mkdir -p $VMPDIAGS/etc/rc.d
    FS dolink "/etc/rc.d/rc.local" "cp /etc/rc.d/rc.local $VMPDIAGS/etc/rc.d" etc/rc.d/rc.local
    # Capture trees for udev and modprobe.d... linked to portal page in log section
    FS group "/etc files" etc
      FS dolinks "/etc/udev" "cp -a /etc/udev $VMPDIAGS/etc" etc/udev
      FS cmd "/etc/modprobe.conf" "$CAT /etc/modprobe.conf" modprobe_conf
      FS dolinks "/etc/modprobe.d" "cp -a /etc/modprobe.d $VMPDIAGS/etc" etc/modprobe.d
      FS cmd "/etc/sysconfig/i18n" "$CAT /etc/sysconfig/i18n" i18n
      FS cmd "prelink" "$CAT /etc/sysconfig/prelink" prelink
      FS cmd "prelink.conf" "$CAT /etc/prelink.conf" prelink_conf
      if [ "$KVER" = "2.6.32" ]; then
        FS cmd "/etc/sysconfig/rsyslog" "$CAT /etc/sysconfig/rsyslog" syslog
      else
        FS cmd "/etc/sysconfig/syslog" "$CAT /etc/sysconfig/syslog" syslog
      fi
      FS cmd "cat /etc/sysconfig/mkinitrd/*" "$CAT /etc/sysconfig/mkinitrd/*" mkinitrd_all
      FS cmd "/etc/alternatives" "ls -la /etc/alternatives" alternatives
      if [ -f /etc/oratab ]; then FS cmd "/etc/oratab" "$CAT1 /etc/oratab" oratab; fi
      if [ -f "/etc/xinetd.conf" ]; then FS cmd "/etc/xinetd.conf" "$CAT /etc/xinetd.conf" xinetd_conf; fi
      FS dolink "/etc/xinetd.d" "cp -a /etc/xinetd.d $VMPDIAGS/etc/xinetd_d" etc/xinetd_d
      if [ -d /etc/X11 ]; then FS dolink "/etc/X11" "cp -a /etc/X11 $VMPDIAGS/etc" etc/X11; fi
      FS cmd "/etc/wgetrc" "$CAT /etc/wgetrc" wgetrc
      FS cmd "/etc/smartd.conf" "$CAT1 /etc/smartd.conf" smartd_conf
}

function OSPerformance() {

  FS section "OS Performance" perf
  FS group "System Performance" process
    K; FS cmd "vmstat -S M -s" "vmstat -S M -s" vmstat_-SMs
    K; FS cmd "Uptime" "uptime" uptime
    if which mpstat > /dev/null 2>&1; then
      FS cmd "mpstat 1 3" "mpstat 1 3" mpstat
      FS cmd "mpstat -P ALL" "mpstat -P ALL" mpstat_cores
    fi
    if which iostat > /dev/null 2>&1; then
      FS cmd "iostat -tmxn" "iostat -tkx" iostat_-tmx
      FS dolinks "iostat -mt -p ALL" "iostat -kt -p ALL > $VMPDIAGS/misc/iostat-mtp-all" misc/iostat-mtp-all
    fi
    FS cmd "/proc/stat" "cat /proc/stat" proc_stat
    FS cmd "/proc/interrupts" "cat /proc/interrupts" proc_interrupts
    A; FS cmd "ps -elf" "ps -elf|$ESCTAGS" ps_-elf
    local dnum=`echo "$OPDATA" |cut -d' ' -f2|grep -ic D`
    R; KHC; nzFSw cmd "D state processes" "[ \"$dnum\" -gt \"5\" ]" num_dstates "$dnum D state processes were detected. Please check the process tree and I/O load." "No D state processes in current ps tree"
    if [ "$KVER" = "2.6.9" ]; then 
      FS cmd "pstree -anpU" "pstree -anpU" pstree_-anp
    else
      FS cmd "pstree -anp" "pstree -anp" pstree_-anp
    fi
    FS dolinks "ps wchan" "ps -e -o pid,stat,comm,wchan=WIDE-WCHAN-COLUMN > $VMPDIAGS/misc/ps_wchan" misc/ps_wchan
    FS cmd "top -bn1" "top -bn1|$ESCTAGS" top_-bn1
    if which sar > /dev/null 2>&1; then FS dolinks "sar -A" "sar -A > $VMPDIAGS/misc/sardata" misc/sardata; fi
  FS section "OS Time" time
  FS group "system time" wallclock
      BP; K; FS cmd "time date and TZ" "date" timedatetz
      FS cmd "GMT offset" "date +%z" gmt_offset
      BP; FS cmd "hwclock" "hwclock" hwclock
      BP; K; FS cmd "/etc/sysconfig/clock" "$CAT /etc/sysconfig/clock" clock
  FS group "cron" cron
    BP; KHC; FSe cmd "cron active" "service crond status" crond_status\
             "Critical: The crond service is not running... please check."
      FS cmd "/etc/crontab" "$CAT /etc/crontab" crontab
      FSe cmd "crontab permissions are 644" '[ `stat -c '%a' /etc/crontab` = "644" ]' crontab_perms \
        "Crontab permissions are $OPDATA but must be 644 for crond to run the file"
      FS cmdq "cp -a /etc/cron* $VMPDIAGS/etc"
      FS link "Click for /etc/cron.d" "etc/cron.d"
      FS link "Click for /etc/cron.hourly" "etc/cron.hourly"
      FS link "Click for /etc/cron.daily" "etc/cron.daily"
      FS link "Click for /etc/cron.weekly" "etc/cron.weekly"
      FS link "Click for /etc/cron.monthly" "etc/cron.monthly"
      FS cmd "/etc/sysconfig/crond" "$CAT /etc/sysconfig/crond" crond
      FS cmd "crontab -l" "crontab -l" crontab_-l
      FS cmd "/etc/anacrontab" "$CAT /etc/anacrontab" anacrontab
}

function OSKernel() {

  function GetKernelFSData() {
    local i sysskip='/sw_activity\|/eject\|em_message\|/dm_mirror_error\|/dormant\|/carrier\|/new_dev\|/attention'
    sysskip="$sysskip\|/drvctl\|new_id\|bind\|trace\|/re\|uevent\|drivers_probe\|rotate_all\|/scan\|unload_heads"
    sysskip="$sysskip\|/delete\|/rom\|new_array\|/alloc_calls\|/free_calls\|cache_disable\|/clear\|/bl_curve"
    sysskip="$sysskip\|kernel/debug\|mpt_qas\|cluster/ocfs2\|issue_lip\|optrom_ctl"
    local procskip='/proc/[0-9]\|/proc/k.*\|flush\|register\|sysrq-trigger\|acpi/event\|xenbus\|privcmd'
    local pidskip='task\|attr\|mem\|pagemap\|clear_refs'

    function WriteSysData() {
      local label=${1#/}
      FS cmdopen "$1 data" "" ${label//\//_}
        find $1 -type d | xargs -I {} mkdir -p $VMPDIAGS{} 2>&1
        eval "find $1 -type f |egrep -v $sysskip|xargs -I {} cp {} $VMPDIAGS{}" 2>&1
      TO 240; FS cmdclose "" "" "" "" ""
      FS link "Link to /$label" "$label"
    } >> $SCRIPTLOG

    function WriteProcFiles() {
      FS cmdopen "/proc root files" "" proc_files
        mkdir -p $VMPDIAGS/proc
        eval "find /proc -maxdepth 1 -type f 2>/dev/null|egrep -v $procskip| xargs -I {} cp {} $VMPDIAGS{}" 2>&1
      TO 240; FS cmdclose "" "" "" "" ""
      FS link "Link to /proc" "proc"
    } >> $SCRIPTLOG

    function WriteProcData() {
      local label=${1#/}
      FS cmdopen "$1 data" "" ${label//\//_}
        find $1 -type d 2>/dev/null|egrep -v /proc/\[0-9\]| xargs -I {} mkdir -p $VMPDIAGS{} 2>&1
        eval "find $1 -type f 2>/dev/null|egrep -v $procskip| xargs -I {} cp {} $VMPDIAGS{}" 2>&1
      TO 240; FS cmdclose "" "" "" "" ""
      FS link "Link to /$label" "$label"
    } >> $SCRIPTLOG

    function WritePidData() { # rough snapshot of /proc/pid's... cp 2>/dev/null because some disappear while being copied
      FS cmdopen "/proc pid data" "" proc_pids
        find /proc/[0-9]* -type d 2>/dev/null|egrep -v task\|attr\|mem | xargs -I {} mkdir -p $VMPDIAGS{} 2>&1
        find /proc/[0-9]* -type f 2>/dev/null|egrep -v task\|attr\|mem\|pagemap\|clear_refs | xargs -I {} cp {} $VMPDIAGS{} 2>/dev/null
      TO 240; FS cmdclose "" "" "" "" ""
      FS link "Link to /proc" "proc"
    } >> $SCRIPTLOG

    FS group "Kernel FS Data" procsys
    for i in $KERNELFSDATA; do
      if [ "$i" = "files" ]; then WriteProcFiles
      elif [ "$i" = "all" ]; then WriteProcFiles; WriteSysData /sys; WriteProcData /proc; WritePidData
      elif [ "$i" = "pids" ]; then WritePidData
      elif [ "${i:0:4}" = "/sys" ]; then WriteSysData $i
      elif [ "${i:0:5}" = "/proc" ]; then WriteProcData $i
      fi
    done
  }

  FS section "Kernel" kernel
  FS group  "Configuration" conf
    FS dolinks "sysctl -a" "sysctl -a | sort > $VMPDIAGS/misc/sysctl" misc/sysctl
    BP; K; FS cmd "/etc/sysctl.conf" "$CAT /etc/sysctl.conf" etc/sysctl_conf
    FS link "Link to full sysctl -a listing" "misc/sysctl"
    K; FS getsysctl kernel.sysrq
    FS getsysctl kernel.panic
    BP; FS cmd "/etc/security/limits.conf" "$CAT /etc/security/limits.conf" limits_conf
    BP; K; FS cmd "ulimit -a" "ulimit -a" ulimit_-a
  FS group "Performance" perf
    FS cmd "loaded modules" "lsmod|sort" lsmod
    FS cmd "/etc/sysconfig/netconsole" "$CAT /etc/sysconfig/netconsole" netconsole
  if [ "$ABORTFA" = "0" ]; then GetKernelFSData; fi
}
  
function OSMemory() {
  local lowlim="25" mfree="50"
  FS section "Memory" mem
  FS group  "Configuration" conf
    K; FSw getsysctl kernel.shmmax ">= 1000000" min
    K; FSw getsysctl kernel.shmall ">1000000" min
    K; FSw getsysctl kernel.shmmni ">=4096" min
    K; FS  getsysctl kernel.sem
  FS group "Performance" perf
    K; FS cmd "/proc/meminfo" "cat /proc/meminfo" meminfo
    K; FS meminfo "MemTotal"
    if [ "$ROLE" = "$OVMSERVER" ]; then mfree="8"; fi
    KHC; FSw meminfo "MemFree" ">$mfree" min
    if cat /proc/meminfo|grep -q LowFree; then
      if [ "$ROLE" = "$OVMSERVER" ]; then lowlim="8"; fi
      KHC; FSw meminfo "LowFree" ">$lowlim" min
    fi
    FS dolinks "/proc/slabinfo" "cat /proc/slabinfo | tr '[:punct:]' '-' > $VMPDIAGS/proc/slabinfo" proc/slabinfo
    if [ "$KVER" != "2.6.9" ]; then FS dolink "/proc/zoneinfo" "cat /proc/zoneinfo > $VMPDIAGS/proc/zoneinfo" proc/zoneinfo; fi
    FS cmd "ipcs -a" "ipcs -a" ipcs_-a 
  FS group "numa support" numa
    ifzFS cmd "numactl installed" "grep -q numactl $VMPDIAGS/misc/pkg-list" numactl_installed
      if [ "`numactl --show 2>/dev/null | grep '^cpubind\|nodebind\|membind'|xargs|cut -d' ' -f2,4,6`" = "0 0 0" ]; then numastatus="NUMA inactive"; else numastatus="NUMA active"; fi
      K; FS cmd "Numa" "echo $numastatus" numa_active
      FS cmd "numactl status" "numastat" numastat
      FS cmd "numactl -show" "numactl --show" numactl_-show
    endifFS
}

SELENFORCING="0"
function CheckSELinux() {
  FS group "Selinux" selinux
    FS cmd "Selinux policy installed" "grep -q selinux-policy $VMPDIAGS/misc/pkg-list" policy_installed
    if ! [ -f /selinux/enforce ]; then FS cmd "/selinux fs active" "/bin/false" fsactive "/selinux fs is not active"
    else
      FS cmd "/selinux fs active" "/bin/true" fsactive "/selinux fs is not active" "/selinux fs is active"
      SELENFORCING=`cat /selinux/enforce`
      KHC; nzFSw cmd "/selinux/enforce" "[ \"$SELENFORCING\" = \"1\" ]" fsenforce "SELinux is in enforcing mode" "SELinux is not in enforcing mode" 
      if which getenforce > /dev/null 2>&1; then
        K; FS cmd "getenforce" "getenforce" getenforce
        K; nzFSw cmd "SELinux Enforcing" "[ \"$OPDATA\" = \"Enforcing\" ]" enforcing "SELinux is in enforcing mode" 
      fi
      if which sestatus > /dev/null 2>&1; then FS cmd "sestatus" "sestatus" sestatus; fi
      FS cmd "/etc/sestatus.conf" "$CAT /etc/sestatus.conf" sestatus_conf
      FS dolink "/etc/selinux" "cp -a /etc/selinux $VMPDIAGS/etc" etc/selinux
   fi
}

function OSSecurity() {
  FS section "Integrity check" security
  if [ "$EXTSEC" = "1" ]; then  
    FS group "Extended OS security (takes a long time)" filescan
      TO 1200; FS cmd "Installed package integrity" "$VERIFYPACKAGEINTEGRITY" package_integrity
      TO 600; FS cmd "Scan for suid/guid executables" "find / -xdev -type f \( -perm -04000 -o -perm -02000 \)" suidguid
      TO 60;  FS cmd "World writeable directories" "find / -xdev -type d \( -perm -0002 -a ! -perm -1000 \) -print" wwrw_dirs
      TO 600;  FS cmd "No owner files" "find / -xdev \( -nouser -o -nogroup \) -print" noowner_files
  else FS group "Basic OS security" filescan
  fi
    #if [ "$KVER" != "2.6.32" ]; then FSw getsysctl kernel.exec-shield "== 1" ok; fi
    if [ "$KVER" != "2.6.9" ]; then FSw getsysctl kernel.randomize_va_space ">= 1" ok; fi
    FS cmd "umask" "umask" 'umask'
    FSw cmd "umask=0022" "[ $OPDATA = 0022 ]" umask_is_0022
    CheckSELinux
  FS group "Access control" access
    FS cmd "/etc/securetty" "$CAT /etc/securetty" securetty
    FS cmd "/etc/login.defs" "$CAT /etc/login.defs" login_defs
    FS cmd "Active Users:" "w" w
    nzFSw cmdx "Login authentication Failures" "grep 'authentication failure' /var/log/secure" login_failures \
        "Authentication failures found in /var/log/secure" "No authentication failures found"
    FS cmd "/etc/hosts.all" "$CAT /etc/hosts.all" hosts_all
    FS cmd "/etc/hosts.allow" "$CAT /etc/hosts.allow" hosts_allow
    FS cmd "/etc/hosts.deny" "$CAT /etc/hosts.deny" hosts_deny
    FS cmd "/etc/host.conf" "$CAT /etc/host.conf" host_conf

    FS section "Authentication" auth
    FS group "nsswitch and pam settings" conf 1
      FS cmd "/etc/nsswitch.conf" "$CAT /etc/nsswitch.conf" nsswitch_conf
      FS dolinks "/etc/pam.d" "cp -a /etc/pam.d $VMPDIAGS/etc" etc/pam.d
      FS dolink "ls -la /lib/security" "ls -la /lib/security > $VMPDIAGS/misc/lib_security" misc/lib_security
      FS cmd "/etc/pam.d/system-auth" "$CAT /etc/pam.d/system-auth" system-auth
      FS cmd "/etc/pam.d/sshd" "$CAT /etc/pam.d/sshd" sshd
      FS cmd "/etc/sysconfig/saslauthd" "$CAT /etc/sysconfig/saslauthd" saslauthd
      FS cmd "/etc/yp.conf" "$CAT /etc/yp.conf" yp_conf

    FS group "SSH" ssh
      FS cmd "/etc/ssh/ssh_config" "$CAT1 /etc/ssh/ssh_config" ssh_config
      FS cmd "/etc/ssh/sshd_config" "$CAT1 /etc/ssh/sshd_config" sshd_config

    # GECOS & FS group data
    if [ "$EXTGECOS" = "1" ]; then
      FS group "GECOS and FS group data" gecos 1
        FS cmd "getent passwd" "getent passwd" passwd
        FS cmd "getent group" "getent group" group
        FS cmd "/etc/sudoers" "$CAT /etc/sudoers" sudoers
    fi

    FS group "NSCD" nscd 1
      ServiceCheck "ncsd" "nscd"
      FS cmd "/etc/nscd.conf" "$CAT /etc/nscd.conf" conf
    FS group "Samba" samba
      ServiceCheck "samba" "smb"
        FS cmd "smb.conf" "$CAT /etc/samba/smb.conf" conf
        FS cmd "pam_smb.conf" "$CAT /etc/pam_smb.conf" pam_smb_conf
        FS dolink "/etc/samba" "cp -a /etc/samba $VMPDIAGS/etc" etc/samba
        FS dolink "testparm -sv" "testparm -sv > $VMPDIAGS/misc/testparm_-sv" misc/testparm_-sv
      ServiceCheck "samba-winbind" "winbind"
        FS cmd "/etc/security/pam_winbind.conf" "$CAT /etc/security/pam_winbind.conf" pam_winbind_conf
    FS group "NIS" nis 1
      ServiceCheck "ypbind" "ypbind"
    FS group "LDAP" ldap
      FS cmd "ldap.conf" "$CAT /etc/ldap.conf" ldap_conf
      ServiceCheck "openldap" "ldap"  
}

function OSDevel() {
  if [ "$ROLE" = "$OVMSERVER" ]; then return 0; fi
  FS section "OS Development" devel
  FS group "java" java 1
    FS dolink "alternatives --display java" "alternatives --display java > $VMPDIAGS/misc/java_config" misc/java_config
    ifzFS cmd "java packages" "egrep java\|jre\|jdk\|jpackage $VMPDIAGS/misc/pkg-list" pkg-list java_packages
      FS cmd "/etc/java/java.conf" "$CAT /etc/java/java.conf" java_conf
  FS group "gcc" gcc 1
    FS cmd "gcc packages" "grep ^gcc $VMPDIAGS/misc/pkg-list" gcc_packages
    FS cmd "Kernel devel package" "grep kernel-devel $VMPDIAGS/misc/pkg-list" kernel_devel "kernel-devel not found"
  FS group libraries libraries
    FS dolink "ldconfig -XNp" "ldconfig -XNp > $VMPDIAGS/misc/ldconfig_-XNp" misc/ldconfig_-XNp
}

function OSUpdate() {
  FS section "OS Update" update
  FS group "Yum Configuration" yum 1
    FS cmd "/etc/yum.conf" "$CAT /etc/yum.conf" yum_conf
    if [ -d /etc/yum.repos.d ]; then 
      FS cmd "/etc/yum.repos.d/*" "ls -la /etc/yum.repos.d/*" yum_repos_d
      FS dolinks "/etc/yum.repos.d" "cp -a /etc/yum.repos.d $VMPDIAGS/etc" etc/yum.repos.d
    fi
  FS group "Up2date Configuration" up2date 1
    if [ -d /etc/sysconfig/rhn ]; then 
      FS dolinks "/etc/sysconfig/rhn" "cp -a /etc/sysconfig/rhn $VMPDIAGS/etc/sysconfig" etc/sysconfig/rhn
    fi
  FS group "Package Tool Configuration" package_tool 1
    FS cmd "Package Public Keys" "$LISTPUBLICKEYS" package_pubkeys
    FS link "Click for full pkg-list" "misc/pkg-list"    
}

function OSLogs() {
  FS section "OS Logs" logs
  FS group "Log configuration" conf
   if [ -f "/etc/rsyslog.conf" ]; then
     FS cmd "/etc/rsyslog.conf" "$CAT1 /etc/rsyslog.conf" rsyslog_conf
   elif [ -f "/etc/syslog.conf" ]; then
     FS cmd "/etc/syslog.conf" "$CAT1 /etc/syslog.conf" syslog_conf
   fi
   FS cmd "/etc/logrotate.conf" "$CAT1 /etc/logrotate.conf" logrotate_conf
   FS cmd "/etc/sysconfig/syslog" "$CAT1 /etc/sysconfig/syslog" sysconfig_syslog
  FS group "Evaluating system logs" system
   FS cmdx "/var/log/dmesg" "egrep -i error\|warn /var/log/dmesg | wc -l" dmesg \
     "Errors or warnings found in /var/log/dmesg"
   fsize "/var/log/dmesg"
   FS link "Click for /var/log/dmesg" "var/log/dmesg" $FSIZE
   FS dolinks "dmesg-now" "dmesg > $VMPDIAGS/misc/dmesg-now" misc/dmesg-now
   FS dolinks "last | grep reboot" "last | grep reboot > $VMPDIAGS/misc/reboots" misc/reboots
   FS dolinks "grep restart /var/log/messages" "grep restart /var/log/messages > $VMPDIAGS/misc/restarts" misc/restarts
   FS cmd "Recent manual reboots" "last | grep reboot | head -n 20" manual_reboots
   K; FSw cmd "Reboot count (last)" "last | grep -i reboot| wc -l" last_reboots
   FS dolinks "last" "last > $VMPDIAGS/misc/last" misc/last
   K; ifzFSw cmd "root user log rights" "[ "`id -u`" = "0" ]" log_access "Cannot provide system logs without running $ARCTAG as root" "Running as root: all logs accessible"
    K; nzFS cmd "Errors/Warnings in messages" "egrep -ic error\|warn /var/log/messages" warnerrors \
       "Errors or warnings in /var/log/messages"

     fsize /var/log/messages
     FS link "Link to /var/log/messages" "var/log/messages" $FSIZE
     nzFS cmd "Reboots" "egrep -ic restart /var/log/messages" reboots "system restarts"
     nzFS cmd "VMWare log signatures" "egrep -ic vmnet /var/log/messages" vmware_sigs \
      "Found VMWare signatures in /var/log/messages" "No VMWare log signatures found" 
     nzFS cmd "VMWare kmods present" "lsmod|grep 'vmmon\|vmnet'" vmware_kmods "" "No vmware modules found"
}

# # # # # # # # # #
#
# ---> Scope: NET
#

function  NetworkDevices() {
  local duptmp="" dupout="" duperr="" linktmp="" linkout="" linkerr="" i
  FS section "Devices" dev
  FS group "Configuration" conf
    for i in /etc/sysconfig/network-scripts/ifcfg-*[0123456789]; do
      BP; FS cmd "interface config: `basename $i`" "$CAT $i" `basename $i`
    done
    for i in `ifconfig 2>/dev/null | egrep -v '^\ ' | cut -d' ' -f1 | xargs`; do
      BP; FS cmd "ifconfig $i 2>/dev/null " "ifconfig $i" ifconfig_$i
    done
    for i in `seq 0 $MAXIFS`; do
      if ! ifconfig eth$i > /dev/null 2>&1; then break; fi
      A; BP; FS cmd "ethtool eth$i" "ethtool eth$i" "ethtool_eth$i"
      duptmp="`echo \"$OPDATA\"|grep Duplex:| grep -v Full`"             
      if [ "$?" = "0" ]; then duperr="1"; dupout="${dupout}eth${i}:$duptmp\n"; fi      
      linktmp="`echo \"$OPDATA\"|grep detected:| grep -v yes`"             
      if [ "$?" = "0" ]; then linkerr="1"; linkout="${linkout}eth${i}:$linktmp\n"; fi      
      BP; FS cmd "ethtool -i eth$i" "ethtool -i eth$i" "ethtool_-i_eth$i"
      BP; FS cmd "ethtool -g eth$i" "ethtool -g eth$i" "ethtool_-g_eth$i"
      BP; FS cmd "ethtool -k eth$i" "ethtool -k eth$i" "ethtool_-k_eth$i"
      BP; FS cmd "ethtool -S eth$i" "ethtool -S eth$i" "ethtool_-S_eth$i"
    done
    R; KHC; nzFSw cmd "Check link active" "[ -n \"$linkerr\" ]" linkactive  "$linkout" "All interface links active"
    R; KHC; nzFSw cmd "Check full duplex" "[ -n \"$duperr\" ]" fullduplex "$dupout" "All interfaces in full duplex mode"
    if [ -f /etc/ethers ]; then FS cmd "/etc/ethers" "$CAT /etc/ethers" ethers; fi
    ifzFSw cmd "Bridge utils" "grep bridge-utils $VMPDIAGS/misc/pkg-list" bridge_utils_installed
      K; FS cmd "brctl show" "brctl show" brctl_show
}

function  NetworkConfiguration() {

  function CheckNTP() {
  FS group "ntp" ntp  
    KHC; ServiceCheck "ntp" "ntpd" w "The ntpd service is not running" "ntpd is active"
      local ntpsrv=`eval $STRIPCOMMENTS /etc/ntp.conf|grep server|grep -v 127.127.1.0|cut -d' ' -f2`
      BP; K; FS cmd "ntp.conf ntp servers" "echo \"$ntpsrv\"" servers
      local ntpnum="0" ntpgood="0" i
      if [ -n "$ntpsrv" ]; then
        for i in $ntpsrv; do
          BP; KHC; FS cmd "Ping ntp server $i" "ping -c 1 -w 3 $i >/dev/null 2>&1" ping_ntp$ntpnum "Ntp server $i does not ping" "Ntp server $i responds to pings"
          if [ "$OPSTATUS" = "0" ]; then let '++ntpgood'; fi
          let '++ntpnum'
        done
      fi
      R; BP; KHC; FS cmd "ntp server redundancy" "[ \"$ntpgood\" -gt \"2\" ]" ntp_redundancy "Insufficient pingable ntp servers found: $ntpgood" "$ntpgood pingable ntp servers found" 
      KHC; FSw cmd "ntpstat" "ntpstat" ntpstat "The ntp daemon is not synchronized... please check /etc/ntp.conf for reachable servers"
      FS cmd "ntptime" "ntptime" ntptime
      BP; K; FSw cmd "ntp active peers" "ntpq -pn | grep '^\*\|^\+'" active_peers "the ntp service is active but there are no active peers. Check /etc/ntp.conf"
      BP; FS cmd "ntp.conf" "$CAT /etc/ntp.conf" ntp_conf
      FS cmd "/etc/ntp/step-tickers" "$CAT /etc/ntp/step-tickers" step-tickers
      FS cmd "/etc/sysconfig/ntpd" "$CAT /etc/sysconfig/ntpd" ntpd
      K; FSw cmd "ntp drift" "cat /var/lib/ntp/drift" ntpdrift
  }

  FS section "Settings" conf
  FS group "hostname" settings
    K; FS cmd "get hostname" "hostname" hostname_cmd
    KHC; FSe cmd "Verify /etc/hosts localhost" "egrep [[:space:]]localhost$\|[[:space:]]localhost[[:space:]] /etc/hosts | egrep ^127.0.0.1[[:space:]]" hosts_localhost "A 127.0.0.1 localhost localhost.localdomain entry was not found in /etc/hosts... please add one"
    KHC; FSe cmd "Ping localhost" "ping -c 1 -w 3 localhost" ping_localhost "The localhost does not ping... please check /etc/hosts and your network configuration"
    BP; K; FSe cmd "/etc/hosts" "$CAT /etc/hosts" etc_hosts
    HC; FSe cmd "/etc/hosts format" "ping -c 1 $HOSTNAME 2>/dev/null" ping_hostname \
     "Cannot locally ping specified hostname \"$HOSTNAME\""
    HC; nzFSw cmdx "Check for malformed /etc/hosts entry" "echo \"${OPDATA}\" | grep 127.0.0.1" malformed_hosts \
     "This system is using dhcp, is not on the network or the /etc/hosts file has a malformed entry" "Ok"
  FS group "gateway" gateway
    FSe cmd "/etc/sysconfig/network" "$CAT /etc/sysconfig/network" sysconfig_network
    K; FS cmd "route -n" "route -n" route_-n
    A; FS cmdq "route -n|grep ^0.0.0.0|xargs"
    local gwdata="$OPDATA"
    BP; HC; ifzFS cmd "Default gateway route set" "echo $gwdata|cut -d' ' -f1|grep -q 0.0.0.0" defaultrouteset "default route not found... machine will not be able to connect outside of the subnet it's currently on" "Default gateway has been set"
    BP; KHC; FS cmd "Default Gateway" "echo $gwdata|cut -d' ' -f2" default_gw "error finding default gateway... please check the setting in /etc/sysconfig/network"
    GW=$OPDATA
    BP; KHC; FS cmd "Default Gateway Interface" "echo $gwdata| cut -d' ' -f8" default_gwintf "error finding default gateway device... please check overall network settings"
    GWInt=$OPDATA
    if [ "$EXTNET" = "1" ]; then FS cmd "tracepath defaultgw" "tracepath $GW" tracepath_gw; fi

  FS group "dns" dns
    local ns=""
    BP; KHC; FSe cmd "/etc/resolv.conf" "$CAT /etc/resolv.conf" resolv_conf "/etc/resolv.conf not found... no dns is possible on this machine until this file is configured"
    if [ -f /etc/resolv.conf ]; then ns=`eval $STRIPCOMMENTS /etc/resolv.conf| grep nameserver | cut -d' ' -f2`; fi
    local nsnum="0" nsgood="0" i
    for i in $ns; do
      KHC; FS cmd "Ping nameserver $i" "ping -c 1 -w 2 $i" pingns$nsnum "nameserver $i does not ping"
      if [ "$OPSTATUS" = "0" ]; then let '++nsgood'; fi
      let '++nsnum'
    done
    R; KHC; FSw cmd "Nameserver redundancy" "[ \"$nsgood\" -gt \"1\" ]" ns_redundancy "Insufficient pingable nameservers found: $nsgood" "$nsgood pingable nameservers found"
    KHC; FSe cmd "DNS lookup hostname" "host $HOSTNAME 2>/dev/null" hostname_ip "The machine $HOSTNAME does not resolve in dns"
    local dtag="" ip nsnum hname
    if [ "$OPSTATUS" = "0" ]; then # Hostname lookup failed... fallback and use default gateway for lookup tests
      dtag="Hostname"; ip=`echo $OPDATA | cut -d' ' -f4`; nsnum="0"; hname=$HOSTNAME
    else
      ifzFS cmd "Reverse lookup Default GW" "host $GW" lookupgwip
      if [ "$OPSTATUS" = "0" ]; then hname=`echo $OPDATA| cut -d' ' -f5`; hname=${hname%.*}; dtag="Default GW"; ip=$GW; fi
    fi
    if [ -n "$dtag" ]; then
      for i in $ns; do
        BP; KHC; FSw cmd "$dtag fwd lookup on $i" "host -W 2 $hname $i" hostname_fwd_ns$nsnum
        BP; KHC; FSw cmd "$dtag rev lookup on $i" "host -W 2 $ip $i" hostname_rev_ns$nsnum
        let "++nsnum"
      done
    fi
   CheckNTP
}

function NetworkSecurity() {
  FS section "Security" security
  FS group "Firewall Settings" firewall
    ServiceCheck "iptables" "iptables" w    
    BP; FS cmd "iptables -nv --list" "iptables -nv --list" iptables_-nv_--list
    BP; FS cmd "/etc/sysconfig/iptables" "$CAT /etc/sysconfig/iptables" iptables
    FS cmd "/etc/sysconfig/iptables-config" "$CAT /etc/sysconfig/iptables-config" iptables-config
  FS group "Netfilter" netfilter
    local NFPATH=""
    if [ -d /proc/sys/net/netfilter ]; then NFPATH="/proc/sys/net/netfilter/nf_conntrack_"
    elif [ -d /proc/sys/net/ipv4/netfilter ]; then NFPATH="/proc/sys/net/ipv4/netfilter/ip_conntrack_"
    fi
#    if [ "$NFPATH" = "" ]; then FS msg "Netfilter not found on this system"
#    else
#      FS cmd "conntrack in use" "cat ${NFPATH}count" contrack_in_use
#      FS cmd "conntrack max" "cat ${NFPATH}max" contrack_max
#    fi
  FS group "Basic Network Security" kernel
    FSw getsysctl net.ipv4.conf.all.rp_filter "== 1" ok
    FSw getsysctl net.ipv4.conf.all.accept_source_route "== 0" ok
    FSw getsysctl net.ipv4.icmp_echo_ignore_broadcasts "== 1" ok
    FSw getsysctl net.ipv4.conf.all.log_martians "== 1" ok
}

function NetworkPerformance() { # os.net.perf

  function GetInterfaceErrors() {
    local ifout="" iferr="" oldifs=$IFS tmp=`echo "$1" | grep -v 'face\|stat'`
    IFS=$'\n'; tmp=`for i in $tmp; do echo $i|xargs; done`; IFS=$oldifs
    echo "$tmp" | while read iface b b b rxerr rxdrp rxovr b txerr txdrp txovr b; do
      if [ "$rxerr$rxdrp$rxovr$txerr$txdrp$txovr" != "000000" ]; then
        iferr="1"
        ifout=$ifout`echo "iface:$iface  RX-ERR:$rxerr  RX-DRP:$rxdrp  RX-OVR:$rxovr  TX-ERR:$txerr  TX-DRP:$txdrp  TX-OVR:$txovr\n"`
      fi
    done
    R; K; FSw cmd "Interface Errors" "[ -z \"$iferr\" ]" iface_errors "$ifout" "No interface errors present"
  }

  local bonds netclass="/sys/class/net" i j w z bdata
  local bondingparms="active_slave ad_num_ports arp_interval downdelay miimon primary use_carrier \
    ad_actor_key ad_partner_key arp_ip_target fail_over_mac mii_status slaves xmit_hash_policy \
    ad_aggregator ad_partner_mac arp_validate lacp_rate mode updelay"
  FS section "Performance" perf
  FS group "netstat info" netstat
    FS cmd "Listening processes (netstat -tuapleo)" "netstat -tuapleo --numeric-hosts --numeric-ports" netstat_-tuapleo
    A; FS cmd "Interface stats (netstat -ia)" "netstat -ia" netstat_-ia
    GetInterfaceErrors "$OPDATA"
  FS group "Network connectivity info" connectivity
    if [ "$NETPROBE" != "0" ]; then   
      KHC; FSw cmd "ARPing default gateway" "arping -I $GWInt -c 4 $GW" arpinggw "Default gateway $GW is not reachable at layer 2 via $GWInt.\nMay be normal for your network but please check"  
      KHC; FSe cmd "Ping default gateway" "ping -c 2 -w 4 $GW" pinggw "Default gateway $GW doesn't ping.\nMay be normal for your network but please check"
    fi  
    FS cmd "arp -n" "arp -n" arp_-n 
  if [ -f /sys/class/net/bonding_masters ]; then
    FS group "Interface Bonding" bonding
      FS cmd "ifenslave -a" "ifenslave -a" ifenslave_-a
      bonds=`cat $netclass/bonding_masters`
      FS cmd "Bond Masters" "echo $bonds" masters
      for i in $bonds; do 
        bdata=""
        for j in $netclass/$i/bonding/*; do 
          bdata=$bdata"`basename $j`:"; z="`cat $j`" 
          if [ -z "$z" ]; then bdata="$bdata\n"; else bdata="$bdata $z\n"; fi
        done
        w="`echo -e $bdata`"    
        FS cmd "Bond data for $i" "echo \"$w\"" ${i}_data
      done
  fi
}

function NodeTests() {
  local listenerport=$SERVERBASEPORT senderport=$((SERVERBASEPORT + 1))

  function DoNodeTests() {
    local disclaimer="NOTE: Unbuffered, unoptimized functionality tests: Not performance benchmarks\n\n"
    local nodes numnodes nstat inx t gotall acc="" fail sects=$((NTSIZE * 2))
    declare -a nodes=($NODES2TEST); numnodes=${#nodes[@]}
    echo "Ping testing $numnodes nodes: ${nodes[@]}";
    fail="" 
    for ((inx=0;inx<numnodes;inx++)); do
      echo -n "${nodes[$inx]}:"
      acc=$acc"`ping -c 2 -w 4 ${nodes[$inx]}`\n\n"
      if [ "$?" = "0" ]; then echo -n "ok  "; else fail="1"; echo -n "failed  "; fi
    done
    R; FSw cmd "Cluster ping test" "[ -z \"$fail\" ]" clu_ping "$acc" "$acc"
    echo
    echo "Host lookups on $numnodes nodes: ${nodes[@]}"
    acc=""; fail="" 
    for ((inx=0;inx<numnodes;inx++)); do
      echo -n "${nodes[$inx]}:"
      acc=$acc"`host -W 2 ${nodes[$inx]}`\n"
      if [ "$?" = "0" ]; then echo -n "ok  "; else fail="1"; echo -n "failed  "; fi
    done
    R; FSw cmd "Cluster DNS lookup" "[ -z \"$fail\" ]" clu_dns "$acc" "$acc"
    echo
    echo; echo "Waiting 20s for $numnodes $ARCTAG listeners:";
    declare -a nstat; gotall="0"
    for t in `seq 1 20`; do
      for ((inx=0;inx<numnodes;inx++)); do
        if [ -z "${nstat[$inx]}" ]; then
          if nc -zv ${nodes[$inx]} $listenerport >/dev/null 2>&1; then echo -n "${nodes[$inx]}:ok  "; nstat[$inx]="1"; fi
        fi
      done
      if [ "${#nstat[@]}" = "${#nodes[@]}" ]; then gotall="1"; break; else sleep 1; echo -n "."; fi
    done
    echo
    if [ "$gotall" = "1" ]; then echo "$ARCTAG listener is active on all specified nodes"
    else
      echo -n "Timeout on: "  
      for ((inx=0;inx<numnodes;inx++)); do if [ -z "${nstat[$inx]}" ]; then echo -n "${nodes[$inx]}  "; fi; done
      echo 
    fi
    logit 1 "Start:rx/tx:net.peers.node.client"
    echo -n "Sending to: "
    disclaimer="${disclaimer}Transfer size: ${NTSIZE}K $CLUSYNC\n"
    for ((inx=0;inx<numnodes;inx++)); do
      echo -n "${nodes[$inx]}  "
      if [ -z "${nstat[$inx]}" ]; then
        R; K; FSw cmd "Network TX test to $i" "/bin/false" client_$inx "VMPScan listener not active on ${nodes[$inx]}:$listenerport... cannot test"
      else
        dd if=/dev/zero count=$sects 2>$VMPDIAGS/node$inx-$DTFN| nc ${nodes[$inx]} $listenerport
        acc="wr: `cat $VMPDIAGS/node$inx-$DTFN|grep -v records`\n"
        nc ${nodes[$inx]} $senderport | dd of=/dev/null count=$sects 2>$VMPDIAGS/node$inx-$DTFN
        acc=$acc"rd: `cat $VMPDIAGS/node$inx-$DTFN|grep -v records`\n"
        R; K; FS cmd "Network R/W test: ${nodes[$inx]}" "/bin/true" clu_rw_$inx "" "$disclaimer$acc"
        rm -f $VMPDIAGS/node$inx-$DTFN
      fi
    done
   echo
  }

  function StartServerProcess() {
    if ps aux|grep -v grep|grep "nc -vkl $senderport" > /dev/null 2>&1; then
      kill -15 `ps aux|grep -v grep|grep "nc -vkl $senderport"|xargs|cut -d' ' -f2`
    fi
    if ps aux|grep -v grep|grep "nc -vkl $listenerport" > /dev/null 2>&1; then
      kill -15 `ps aux|grep -v grep|grep "nc -vkl $listenerport"|xargs|cut -d' ' -f2`
    fi
    K; nzFSw cmd "Listener port available" "netstat -tnl | grep 0.0.0.0:$listenerport" listenerport_available "Port $listenerport in use\nCannot do server role network test" "Server listener port $listenerport is available"
    echo
    if [ "$OPSTATUS" = "0" ]; then
      echo "Listener port $listenerport is busy... aborting listener startup"
    else
      nc -vkl $listenerport 1>/dev/null 2>$VMPDIAGS/listener.txt &
      LISTENERPID="$!"
      if [ -n "$LISTENERPID" ]; then echo "$ARCTAG listener active on port $listenerport with pid $LISTENERPID"
      else echo "Listening process fork failed"
      fi
    fi
    K; nzFSw cmd "Sender port available" "netstat -tnl | grep 0.0.0.0:$senderport" senderport_available "Port $senderport in use\nCannot do server role network test" "Server sender port $senderport is available"
    if [ "$OPSTATUS" = "0" ]; then
      echo "Sender port $senderport is busy... aborting sender startup"
    else
      cat /dev/zero | nc -vkl $senderport 2>$VMPDIAGS/sender.txt &
      SENDERPID="$!"
      if [ -n "$SENDERPID" ]; then echo "$ARCTAG sender active on port $senderport with pid $SENDERPID"
      else echo "Sending process fork failed"
      fi
    fi
  }

  if [ "$ABORTFA" = "0" ] && [ -n "$NODES2TEST" ]; then
    FS section "Peers" peers
    FS group "Node" node
    set -m # enable job control for the fork... nc won't accept rx data without it
    StartServerProcess
    local clusyncsave="$CLUSTERSYNC"
    CLUSTERSYNC="1" # Force clusync for this test... operator must sequence the nodes manually
    ClusterSync "Network Node Test: Please wait for $ARCTAG to reach this point on all nodes,\nthen press enter to execute the tests sequentially one node at a time.\nDon't do this test on a production system\n"
    DoNodeTests
    ClusterSync "Test complete: Please wait for all other nodes to complete before pressing enter\n"
    CLUSTERSYNC="$clusyncsave"
    if [ -n "$LISTENERPID" ]; then kill -15 $LISTENERPID >/dev/null 2>&1; LISTENERPID=""; fi
    if [ -n "$SENDERPID" ]; then kill -15 $SENDERPID >/dev/null 2>&1; SENDERPID=""; fi
    set +m
    FS cmd "listener connection data" "cat $VMPDIAGS/listener.txt" listener_data
    FS cmd "sender connection data" "cat $VMPDIAGS/sender.txt" sender_data
    rm -f $VMPDIAGS/listener.txt
    rm -f $VMPDIAGS/sender.txt
    DoStartupDelay # if specified, to keep the nodes separated with shared resource requests
  fi
}

# # # # # # # # # # # #
#
# ---> Scope: STORAGE
#

function StorageDevices() {
  local i d
  FS section "Storage Devices" dev
  FS group "System Volumes" vols
    K; FS cmd "fdisk -l" "fdisk -l" fdisk_-l
    K; FS cmd "/proc/partitions" "cat /proc/partitions" proc_partitions
    K; FS cmd "LUNS/Paths" "cat /proc/partitions | grep sd | grep -v [0-9]$| wc -l" lunpath_count
    K; FS cmd "mount" "mount" mount
    K; FS cmd "df -h" "df -h" df_-h
    if [ "$KVER" != "2.6.9" ]; then
      FS cmd "loop devices" "losetup -av" losetup_-av
      FS cmd "next free loop device" "losetup -f" losetup_-f
    fi
  FS group "iscsi initiator" iscsi-initiator
    ServiceCheck "iscsi-initiator-utils" "iscsi" "" "iscsi-initiator-utils not found on this system"
    FS cmd "chkconfig --list iscsid" "chkconfig --list iscsid" iscsid_sysv_status 
    FS cmd "/etc/iscsi/initiatorname.iscsi" "$CAT /etc/iscsi/initiatorname.iscsi" initiatorname
    FS cmd "/etc/iscsi/iscsid.conf" "$CAT /etc/iscsi/iscsid.conf" iscsid_conf
    FS cmd "iscsiadm -m node" "iscsiadm -m node" node_recs
    FS cmd "iscsiadm -m discovery -P 1" "iscsiadm -m discovery -P 1" show_targets
    FS cmd "iscsiadm -m node -o show" "iscsiadm -m node -o show|$ESCTAGS" show_nodes
    FS cmd "iscsiadm -m session -P3" "iscsiadm -m session -P3|$ESCTAGS" show_sessions
    FS cmd "iscsiadm -m session -o show" "iscsiadm -m session -o show|$ESCTAGS" show_stats
  FS group "iscsi target" iscsi-target
    FS cmd "ietd.conf" "$CAT /etc/ietd.conf" ietd_conf
  if [ "$EXTLVM" != "0" ]; then
    FS group "LVM Info" lvm
      ifzFS cmd "pvs" "pvs" pvs "No physical LVM volumes detected on this system" 
        FS cmd "vgs" "vgs" vgs
        FS cmd "lvs" "lvs" lvs;
        FS cmd "/etc/lvm/lvm.conf" "$CAT1 /etc/lvm/lvm.conf" lvm_conf
        FS dolinks "/etc/lvm" "cp -a /etc/lvm $VMPDIAGS/etc" etc/lvm
  fi
  FS section "Devicemapper" devmapper
  FS group "Block Device and Device Mapper" dev
    FS cmd "blkid" "blkid | sort -k3" blkid
    FS cmd "dmsetup ls" "dmsetup ls | sort" dmsetup_ls
    FS cmd "dmsetup status" "dmsetup status" dmsetup_status
    FS cmd "dmsetup table" "dmsetup table" dmsetup_table
    FS dolinks "dmsetup info" "dmsetup info > $VMPDIAGS/misc/dmsetup-info" misc/dmsetup-info
    if [ "$ABORTFA" = "0" ]; then
      d=$(for i in `cat /proc/partitions | awk {'print $4'} |grep sd | grep [a-z]$`; do echo "$i: `scsi_id $SCSI_IDCMD/$i`"; done)
      FS cmd "scsi device info" "echo \"$d\"" scsi_info
    fi
    FS cmd "/etc/scsi_id.config" "$CAT /etc/scsi_id.config" scsi_id_config
  FS group "dm multipath info" dm_mpath
    K; ServiceCheck "device-mapper-multipath" "multipathd" w
    FSw cmd "/etc/multipath.conf" "$CAT /etc/multipath.conf" mpath_conf
    if [ -f /var/lib/multipath/bindings ]; then
      K; FS cmd "/var/lib/multipath/bindings" "$CAT /var/lib/multipath/bindings" bindings
    fi     
    FS dolinks "multipath -v4 -ll" "multipath -v4 -ll > $VMPDIAGS/misc/multipath-v4ll" misc/multipath-v4ll
  if [ "$EXTRAID" != "0" ]; then
    FS group "dm raid" dm_raid
        FS cmd "dmraid -b" "dmraid -b" dmraid_-b;
        FS cmd "dmraid -r" "dmraid -r" dmraid_-r;
        FS cmd "dmraid -rD" "dmraid -rD" dmraid_-rD;
        FS cmd "dmraid -s" "dmraid -s" dmraid_-s;
        FS cmd "dmraid -tay" "dmraid -tay" dmraid_-tay;
        FS cmd "dmraid -V" "dmraid -V" dmraid_-V;
        FS cmd "mdadm -D" "mdadm -D /dev/md*" mdadm_-D
  fi
}

function StorageFilesystems() {
  FS section "Filesystems" fs
  FS group "Configuration" conf
    BP; K; FS cmd "fstab" "cat /etc/fstab" fstab
    FS cmd "/etc/sysconfig/readonly-root" "$CAT /etc/sysconfig/readonly-root" readonly-root
    FS cmd "/etc/filesystems" "$CAT /etc/filesystems" filesystems
  FS group "NFS" nfs
    K; FS cmd "/etc/exports" "cat /etc/exports" exports
    FS cmd "rpcinfo -p" "rpcinfo -p" rpcinfo_-p
    FS cmd "nfsstat" "nfsstat" nfsstat
    if [ "$KVER" != "2.6.9" ]; then
      FS dolinks "sar -n NFS" "sar -n NFS > $VMPDIAGS/misc/sar-nfs" misc/sar-nfs
    fi
    FS cmd "/etc/sysconfig/nfs" "$CAT /etc/sysconfig/nfs" sysconfig_nfs
  if [ "$EXTLSOF" = "1" ]; then 
    FS group "Performance" perf
      local novmp="-p ^$$"
      if [ "$KVER" = "2.6.9" ]; then novmp=""; fi
      FS dolinks "lsof -b -Mnl" "lsof -b -Mnl $novmp 2> $VMPDIAGS/misc/lsof_-b_-Mnl.skipped 1> $VMPDIAGS/misc/lsof_-b_-Mnl" misc/lsof_-b_-Mnl
      fsize "$VMPDIAGS/misc/lsof_-b_-Mnl.skipped"
      FS link "Click for skipped lsof filelist" "misc/lsof_-b_-Mnl.skipped" $FSIZE
  fi
}

function StorageOcfs2() {
  
  function CheckO2Connections() { # Local helper function to parse and test ocfs2 connections
    local O2IP O2PORT O2NODES O2NUM z

    function GetParm() { z="`grep $1 /etc/ocfs2/cluster.conf | cut -d '=' -f2`"; }

    if ! [ -f /etc/ocfs2/cluster.conf ]; then return; fi
    local ip port num count j
    GetParm 'ip_addr'; O2IP=$z; GetParm 'ip_port'; O2PORT=$z;
    GetParm 'node_count'; O2NODES=$z; GetParm 'number'; O2NUM=$z;
    FS group "node connectivity:" node
    logit 1 "Start:o2cb connectivity tests to peer nodes"
    for count in `seq $O2NODES`; do
      FS conmsg "$count"; PREVLINEPOS=$(( $PREVLINEPOS + ${#count}))
      ip=`echo $O2IP | cut -d' ' -f$count`
      port=`echo $O2PORT | cut -d' ' -f$count`
      num=`echo $O2NUM | cut -d' ' -f$count`
      for j in `ifconfig 2>/dev/null | grep addr: | cut -d':' -f2 |cut -d' ' -f1`; do
        if [ "$j" = "$ip" ]; then
          R; K; FS cmd "Node Number $num" "/bin/true" $num "" "Skipping nc test on local machine $ip"
          break
        fi
      done
      if [ "$j" != "$ip" ]; then
        K; FS cmd "Node Number $num" "nc -w 5 -zv $ip $port 2>&1" $num "O2cb node $num connectivity failure"
      fi
    done
    logit 1 "End:o2cb connectivity tests to peer nodes"
  }


  # Begin OCFS2Info... general procedure from my Metalink note 806645.1
  FS section "Oracle Ocfs2" ocfs2
  FS group "O2CB and OCFS2 Service status" service
    ifzFSw cmd "Ocfs2-tools installed" "grep ocfs2-tools $VMPDIAGS/misc/pkg-list" tools_installed \
        "ocfs2-tools is not installed on this system... ocfs2 is not operational"
    if [ "$ABORTFA" != "0" ]; then return 1; fi
      FS cmd "ocfs2 packages" "grep ocfs2 $VMPDIAGS/misc/pkg-list" packages
      FSw cmd "lsmod | grep ocfs" "lsmod | grep ocfs" kmod_ok "the ocfs2 module isn't loaded.\nPlease check your kernel configuration and review KM Document 806645.1 for further troubleshooting steps"
      FS cmd "modinfo ocfs2" "modinfo ocfs2" ocfs2_modinfo
      FS cmd "ocfs2 version" "modinfo ocfs2 | grep ^version:|xargs|cut -d' ' -f2" version
      local basever=`echo $OPDATA | cut -d'.' -f1,2`
      K; FS cmd "chkconfig --list o2cb" "chkconfig --list o2cb" o2cb_sysv
      K; FSw cmd "o2cb service at boot" "echo $OPDATA|grep :on" o2cb_enabled "The o2cb service is not set to start at boot... please run: chkconfig o2cb on to correct this"
      K; FS  cmd "o2cb status" "service o2cb status" o2cb_status
      K; ServiceCheck "ocfs2" "ocfs2" w "The ocfs2 service is not set to start at boot... please run: chkconfig ocfs2 to correct"
  FS group "OCFS2 Configuration" conf
      BP; K; FS cmd "/etc/sysconfig/o2cb" "$CAT /etc/sysconfig/o2cb" o2cb_conf
      BP; K; ifzFSw cmd "ocfs2 cluster.conf" "cat /etc/ocfs2/cluster.conf 2>&1" cluster_conf
        K; FS cmd "cluster.conf md5sum" "md5sum /etc/ocfs2/cluster.conf 2>&1" cluster_conf_md5
        if [ -f /etc/ocfs2/cluster.conf ]; then
          KHC; nzFSe cmd "cluster.conf contains a localhost entry" "grep 127.0.0.1 /etc/ocfs2/cluster.conf" localhostentry "Please verify that the hostname and IP address for this machine are correctly entered in /etc/hosts" "Ok: cluster.conf does not have a localhost entry"
        fi
      endifFS
      FS cmd "ocfs2 mount entries in fstab" "$CAT /etc/fstab | grep ocfs2" ocfs2_fstab
      if [ "$SELENFORCING" = "1" ]; then
        if [ "$basever" = "1.2" ] || [ "$basever" = "1.4" ]; then
          KHC; FSe cmd "Selinux Enabled" "/bin/false" selinux_enabled "selinux is active and not supported by ocfs2 $basever"
        fi
      fi
  FS group "OCFS2 Network" net
      if service iptables status | egrep -iq reset\|drop\|reject; then
        FSw cmd "iptables active: rule for 7777 present" "iptables -n --list | grep 7777 | grep ACCEPT" fwport_open \
          "iptable rules are active, but no rule was found to allow connections on o2cb port 7777"
      fi
      if [ "$NETPROBE" != "0" ] && [ "$ABORTFA" = "0" ]; then CheckO2Connections; fi
      K; FS cmd "ocfs2 connections" "netstat -tapn | grep 7777" connections
  FS group "Block Devices" dev
      FS cmd "ocfs2 blockid list" "blkid | grep ocfs" ocfs2_blkid
      if [ -n "$OPDATA" ] && which debugfs.ocfs2 > /dev/null 2>&1; then
        FS cmd "ocfs2 devices" "echo \"$OPDATA\" |cut -d':' -f1" ocfs2_luns
        # Bash wierdism won't allow the following command to be embedded in an FAE call... doing this instead:
#        if [ -n "$OPDATA" ] && [ "$ABORTFA" = "0" ]; then
#          a="$(for i in $OPDATA; do echo Device:$i; dd if=$i count=256 2>/dev/null | strings | grep -A 2 OCFSV2; \
#            echo stats|debugfs.ocfs2 $i 2>/dev/null| egrep -i label:\|UUID\|Count\|Slots\|State; \
#            echo -n slotmap | debugfs.ocfs2 -n $i 2>/dev/null; let "++nn"; echo End:$i; echo; done)"
#         FS cmd "ocfs2 lun header metadata" "echo \"$a\"" ocfs2_fsmetadata
#        fi
      fi
  FS group "Cluster nodes" cluster
      if [ "$ABORTFA" = "0" ]; then
        if [ "$KVER" = "2.6.18" ]; then confs="/sys/kernel/config"; elif [ "$KVER" = "2.6.9" ]; then confs="/config"; fi
        if [[ -n "$confs" && -d $confs ]]; then
          pushd . > /dev/null 2>&1; cd $confs;
          local d=$(for i in `find . -type f`; do echo -n \"${i#*/}: \"; cat $i; done)
          K; FS cmd "$confs" "echo \"$d\"" configfs 
          popd > /dev/null 2>&1
        fi
      fi
      K; FS cmd "mounted.ocfs2 -d" "mounted.ocfs2 -d" mounted_ocfs2_-d
      K; FS cmd "mounted.ocfs2 -f" "mounted.ocfs2 -f" mounted_ocfs2_-f
  FS group "Log analysis" logs
      FS dolinks "Ocfs2 errors/warnings" "egrep -iv $ARCTAG\|stackglue /var/log/messages|grep -ie 'o2net\|ocfs2\|o2hb\|:dlm' > $VMPDIAGS/misc/ocfs2errwarn 2>&1" misc/ocfs2errwarn
      if [ -s $VMPDIAGS/misc/ocfs2errwarn ]; then
        FS cmdq "wc -l $VMPDIAGS/misc/ocfs2errwarn|cut -d' ' -f1"
        R; K; FSe cmd "ocfs2 log errors/warnings" "[ \"$OPDATA\" -eq \"0\" ]" errwarn_count "$OPDATA" "$OPDATA"
      fi
}

function StorageAsmlib() { # Begin general procedure from KM doc 811457.1
  local a="" b c d i
  FS section "Oracle Asmlib" asmlib
  FS group "Service status" service
      ServiceCheck "oracleasm" "oracleasm" "" "No oracleasm packages found on this system... oracleasm is inoperative"
      FSw cmd "Kernel module present" "grep -q oracleasm-`uname -r` misc/pkg-list" kmod_ok
      FS cmd "chkconfig --list oracleasm" "chkconfig --list oracleasm 2>/dev/null" sysv
        FS cmd "service oracleasm listdisks" "service oracleasm listdisks" list_disks
         if [ "$ABORTFA" = "0" ]; then a=`for i in $OPDATA; do oracleasm querydisk $i; done`; fi
        FS cmd "service oracleasm query all disks" "echo \"$a\"" query_disks
        FS cmd "/dev/oracleasm/disks" "ls -la /dev/oracleasm/disks" dev_oracleasm_disks
        FS cmd "asm blockid list" "blkid | grep oracleasm" oracleasm_blkid
  FS group "Configuration" conf
    ifzFS cmd "ls -l /etc/sysconfig/oracleasm*" "ls -l /etc/sysconfig/oracleasm*" files
      FSw cmd "oracleasm config" "$CAT /etc/sysconfig/oracleasm 2>&1" oracleasm
      FS cmd "oracleasm config md5sum" "md5sum /etc/sysconfig/oracleasm" oracleasm_md5sum
      FS cmd "oracleasm-_dev_oracleasm" "$CAT /etc/sysconfig/oracleasm-_dev_oracleasm 2>&1" oracleasm-_dev_oracleasm
  FS group "Luns and Volumes" dev
   ifzFS cmd "asm labeled luns" "blkid | grep oracleasm" asm_luns
    if [ "$ABORTFA" = "0" ]; then   
      a=`cat /proc/partitions |grep sd|while read a b c d;do echo -n $d$'\t'" scsi_id="; \
      (echo $d|tr -d [:digit:]|xargs -i scsi_id $SCSI_IDCMD/{})done`
    fi
    FS cmd "all lun scsi id mappings" "echo \"$a\"" lun_scsi_ids

    # udevadm --version  use -s if 114 or less... use -u -g if greater 
    if [ "$ABORTFA" = "0" ]; then   
      a=`blkid|grep sd.*oracleasm|while read a b;do echo -n $a$b" scsi_id="; \
      (echo $a|tr -d [:digit:]|tr -d [:]|cut -d"/" -f3|xargs -i scsi_id $SCSI_IDCMD/{})done;`
      FS cmd "asm volume id mappings" "echo \"$a\"" asm_lun_ids
      a=$(service oracleasm querydisk -d `service oracleasm listdisks`)
      FS cmd "Asm volumes with disk id" "echo \"$a\"" vol_listing
    fi
    FS cmd "asm volume headers" "find /dev/oracleasm/disks -type b | xargs -i sh -c \"echo {}; \
     dd if={} count=10 2>/dev/null | strings\"" vol_headers
    FS cmd "oracleasm-discover" "/usr/sbin/oracleasm-discover" oracleasm_discover
}

function StorageTest() {
  local tnum="0"

  function DoStorageTest() {
    local clusync="" res="" errmsg="" okmsg tn bsize bcount wr rd ddif ddof ptt="$1" # path to test
    if [ "$KVER" = "2.6.9" ]; then ddif=""; ddof=""; else ddif="iflag=direct "; ddof="oflag=direct "; fi
    R; FS cmdopen "${DTSIZE}k dd r/w to $ptt" "" ddrw$tnum
    OPSTATUS="0"
    local minsize=$((DTSIZE * 3))
    if ! [ -d "$ptt" ]; then errmsg="$ptt path does not exist"; OPSTATUS="1"
    else
      local dtfree=`df -BK $ptt|egrep [0-9]%|xargs|cut -d'K' -f3|xargs`
      if ! [ -w "$ptt" ]; then errmsg="$ptt is not writeable"; OPSTATUS="1"
      elif [ "$dtfree" -lt "$minsize" ]; then 
        errmsg="${dtfree}k of disk space is available and ${minsize}k is needed on $ptt to do the ddrw test"; OPSTATUS="1"
      else
        tn="1"; FS conmsg "$ptt:"; let '++PREVLINEPOS'
        OPDATA=""
        for bsize in 1024 512 256 128 64 32 16 8 4; do
          logit 2 "Start:wr${bsize}k:storage.tests.fsblock.ddrw$tnum"
          FS conmsg "$tn"; PREVLINEPOS=$(( $PREVLINEPOS + ${#tn})); let "++tn"
          bcount=$((DTSIZE / bsize))
          wr=`dd $ddof if=/dev/zero of=$ptt/$DTFN bs=${bsize}K count=$bcount 2>&1`
          if [ "$?" != "0" ]; then OPSTATUS="1"; errmsg="$wr\ndd write error... aborting"; break; fi
          wr=`echo "$wr"|grep -v record`
          logit 2 "End:wr${bsize}k:storage.tests.fsblock.ddrw$tnum"
          logit 2 "Start:rd${bsize}k:storage.tests.fsblock.ddrw$tnum"
          rd=`dd $ddif if=$ptt/$DTFN of=/dev/null bs=${bsize}K count=$bcount 2>&1`
          if [ "$?" != "0" ]; then OPSTATUS="1"; errmsg="$rd\ndd read error... aborting"; break; fi
          rd=`echo "$rd"|grep -v record`
          rm -f $ptt/$DTFN
          logit 2 "End:rd${bsize}k:storage.tests.fsblock.ddrw$tnum"
          OPDATA=$OPDATA`echo -e "\n$bcount blocks of ${bsize}k\twr: ${wr##*s, }\trd: ${rd##*s, }"`
        done
      fi
    fi
    if [ "$OPSTATUS" = "0" ]; then
      local rinfo=""; if [ "$ABORTFA" = "0" ]; then rinfo="`df -Thi $ptt`"; fi
      okmsg="NOTE: Sequential, unbuffered and unoptimized functionality tests: Not benchmarks.\n\n"
      okmsg="${okmsg}Transfer size:${DTSIZE}k   $CLUSYNC\n$rinfo\n\n"
    fi
    TO 600; K; FSe cmdclose "" "" "" "$errmsg" "$okmsg"
    [ -f $ptt/$DTFN ] && rm -f $ptt/$DTFN # clean up in case something errored out
  }

  if [ -n "$STORAGETEST" ]; then
    FS section "Tests" tests
    FS group "Variable Blocksize RW" fsblock
    if [ "$ABORTFA" = "0" ]; then
      local dtp
      for dtp in $STORAGETEST; do
        logit 1 "Start:Storage test on $dtp"
        ClusterSync "Storage test for: $dtp\nPlease don't do this test on a system in production\n"
        if [ "$CLUSTERSYNC" = "0" ]; then FS conmsgln; fi 
        DoStorageTest "$dtp"
        logit 1 "End:Storage test on $dtp"
        let '++tnum'
      done
    fi
    ClusterSync "Test complete: Please wait for all other nodes to complete before pressing enter\n"
    if [ "$CLUSTERSYNC" != "0" ]; then DoStartupDelay; fi # if specified, to keep the nodes separated with shared resource requests
  fi
}

# # # # # # # # # #
#
# ---> Scope: VIRT
#

function VirtXenInfo() {
  if [ "$HOSTTYPE" = "$XENDOM0" ]; then
    FS section "Xen Dom0 info" dom0
    FS group "xm" xm
      FS cmd "xm dmesg" "xm dmesg" dmesg
      K; FS cmd "xm info" "xm info" info
      K; FS cmd "xentop" "/usr/sbin/xentop -b -i 1" xentop
      K; FS cmd "xm list" "xm list" xm_list
      K; FS cmd "Number of Domains" "echo \"$OPDATA\"|grep -v Name|wc -l" num_domains
      K; nzFSw cmd "High Domain Count" "[ \"$OPDATA\" -gt \"$MAXVMS\" ]" high_domain_count "$OPDATA Active domains (> $MAXVMS warning threshold)" "$OPDATA Active domains (< $MAXVMS warning threshold)"
      FS dolinks "xm list -l" "xm list -l > $VMPDIAGS/misc/xm_list-l" misc/xm_list-l
      FS dolinks "xenstore-ls" "xenstore-ls > $VMPDIAGS/misc/xenstore-ls" misc/xenstore-ls
    FS group "Configuration" conf
      FS cmd "xend-config.sxp" "$CAT /etc/xen/xend-config.sxp" xend-config_sxp
      FS dolinks "/etc/xen" "cp -a /etc/xen $VMPDIAGS/etc" etc/xen
      FS cmd "xendomains" "$CAT /etc/sysconfig/xendomains" xendomains
      if [ "$OVMVERSION" = "2.2" ]; then FS cmd "cat /proc/xen/balloon" "$CAT /proc/xen/balloon" balloon; fi
      FS cmd "dom0 autostarts: ls /etc/xen/auto" "ls /etc/xen/auto" ls_xenauto
    FS group "Service Status" sysvstatus
      ifzFSw cmd  "service xend status" "service xend status" xend "the xend service is not running... hypervisor api is not available"
      ifzFSw cmd  "service xendomains status" "service xendomains status >/dev/null 2>&1" xendomains "xendomains service error"
  elif [ "$HOSTTYPE" = "$XENDOMU" ]; then
    FS section "Xen Domu info" domu
    FS group "conf" conf
      if [ "$OVMVERSION" = "2.2" ]; then FS cmd "cat /proc/xen/balloon" "$CAT /proc/xen/balloon" balloon; fi
      FS cmd "xen sysctl.conf" "grep xen /etc/sysctl.conf" xen_sysctl_conf
      FS cmd "xen sysctl -a" "sysctl -a | grep xen" xen_sysctl_-a
  else FS msgln "No Xen Virtualization support is installed on this system"
  fi   
}

function VirtOracleVMInfo() {
  local CLMEMBERS="" VALIDROOTSR="0"

  function DoRPC() { FS cmd "$1" "${AGD}/utils/do_rpc.py $2" "$3" ${4:-""}; }

  function LocalNodeStatus() {
    FS group "Configuration on this node" conf
      K; FS cmd "xen, ovs and ocfs2 packages" "grep -E \(xen\|ovs\|ocfs\) $VMPDIAGS/misc/pkg-list | sort" pkgs_present
      if [ "$OVMVERSION" = "2.2" ]; then
        K; DoRPC "OVM Version (API call)" "ha_check_oracle_vm_version" ha_check_oracle_vm_version
        K; DoRPC "xen_mem_free" "xen_mem_free" xen_mem_free
      fi
      K; FS cmd "/etc/ovs-release" "cat /etc/ovs-release" ovs_release
      FS cmd "/etc/ovs-config" "$CAT1 /etc/ovs-config" ovs_config
      FS cmd "/etc/ovs-info" "cat /etc/ovs-info" ovs_info
      FS cmd "/etc/ovs-agent/agent.ini" "grep -v ^\; /etc/ovs-agent/agent.ini" agent_ini
      if [ "$OVMVERSION" = "2.2" ]; then
        FS cmd "/etc/ovs-agent/logger_client.ini" "$CAT /etc/ovs-agent/logger_client.ini" logger_client_ini
        FS cmd "/etc/ovs-agent/logger_server.ini" "$CAT /etc/ovs-agent/logger_server.ini" logger_server_ini
      fi
    FS group "Performance" perf
      FS cmd "Number of OVS agent processes" "ps -ef|grep OVS.*Server.py|grep -v grep|wc -l" num_agent_processes
      FS cmd "Agent processes > 10" "[ \"$OPDATA\" -lt \"7\" ]" agent_processes_high "Agent processes greater then 7... please check" "Agent Process number ok"
  }

  function NetworkBPCheck() { # Check for > MAXVMS on the management interface
    source /etc/ovs-config; local brnum="0" msg="" i numvms msg
    A; FS cmdq "brctl show|grep -v '^[[:space:]]'|grep -v bridge|tr '[:blank:]' ':'|cut -d':' -f1"
    local bridges=$OPDATA
    for i in $bridges; do
      A; FS cmd "VMs on bridge $i" "xm list -l|grep -c \"(bridge $i)\"" vms_on_br$brnum $i $i
      numvms="$OPDATA"
      if [ "$i" = "$MGMNT_IF" ]; then msg="VMs on the OVS MANAGEMENT INTERFACE... please check"; else msg="VM's on a single bridge"; fi
      if [ "$numvms" -ge "$MAXVMS" ]; then
        R; KHC; FSw cmd "High VM's on bridge $i" "/bin/false" high_vms_on_br$brnum "$numvms $msg" "$numvms"
      fi
      let '++brnum' 
    done 
  }

  function ClusterFilesystems() {

    function Ocfs2BPCheck {
      local repos rmount rtype rpath="" i j tmp="" rnum="0"
      A; K; FS cmd "Repo Types" "mount | grep /var/ovs/mount | cut -d' ' -f3,5" fs_types
      if [ "$ABORTFA" = "0" ]; then
       repos="$OPDATA"
       echo "$repos" | while read rmount rtype; do
         rpath="$rpath $rmount"
         if [ "$rtype" = "ocfs2" ]; then 
           K; nzFSw cmd "Check nested ocfs2" "find $rmount/running_pool/ -name vm.cfg | xargs grep -i w\!|grep file:" nested_ocfs2_$rnum "Ocfs2 shared disks on top of ocfs2 repositories is not recommended\nPlease verify that these guest volumes are not configured that way:" "Ok: No shared disks found on:\n\n$rmount"
           let '++rnum'
         fi
       done
       > $VMPDIAGS/misc/vm-cfg
       pushd . > /dev/null 2>&1  
       for i in $rpath; do
         echo $i; echo
         if cd $i/running_pool >/dev/null 2>&1; then # only search Oracle VM repos
           for j in `find . -name vm.cfg`; do echo $j; cat $j; echo; done
         fi
       done >> $VMPDIAGS/misc/vm-cfg
       FLink "misc/vm-cfg"
       popd > /dev/null 2>&1

       FS link "Link to vm.cfg files on all repos" "misc/vm-cfg"
       FS link "Link to /var/log/ovs-agent" var/log/ovs-agent
       FS link "Link to /var/log/xen" var/log/xen
     fi
    }
   
    FS group "Cluster filesystem and repo info" repos
      K; FS cmd "repos.py -l" "${AGD}/utils/repos.py -l" repos_-l
      DoRPC "API Root repository" "get_storage_repositories True" get_storage_repositories
      local z=`readlink /OVS`
      KHC; FSe cmd "/OVS symlink target" "mount | grep -q $z > /dev/null 2>&1" ovs_symlink_target "/OVS symlink does not point to a mounted repository: ok if server isn't registered" "/OVS symlink points to a mounted repository" 
      K; FS cmd "/OVS root SR symlink" "ls -lah /OVS" ovs_symlink
      KHC; FSe cmdsave "/OVS symlink verification" "ls -lad /OVS/running_pool" validrootsr \
        "/OVS does not point to a valid OVS root repository: ok if the server isn't registered"\
        "The /OVS symlink points to a valid repository"
      KHC; FSe cmd "Repository mount check" "mount | grep /var/ovs/mount" rootsr_mountpoint "there are no OVS repositories mounted"
      Ocfs2BPCheck
    FS group "Agent status (via API)" agent_api
      K; DoRPC "get_agent_version" "get_agent_version" get_agent_version
      DoRPC "Cluster version check: ha_check_agent_version" "ha_check_agent_version" ha_check_agent_version
      K; FSe cmd "service ovs-agent status" "service ovs-agent status" service ovs-agent status "the ovs-agent service is not active... no communication with pool management is possible"
      K; DoRPC "Node view of the cluster" "ha_get_ocfs2_config" ha_get_ocfs2_config
  }

  function ClusterStatus() {
    local clmembers="" op
    
    function GetMemberData() {
      local node a hostn d starttime
      FS cmdopen "$1" "date" "$1"; OPDATA=""
        for node in $clmembers; do #... the joys of bash string formatting
          GetNow; local starttime=$NOW
          a=`${AGD}/utils/do_rpc.py $1 $node`
          GetElapsed $starttime
          CmdSleep
          hostn=`echo $a | cut -d"'" -f2`  #; hostn=${hostn%%.*}
          d="$hostn (${ELTIME}s): `echo -e "\n$a\n" | cut -d">" -f2 |xargs`";
          OPDATA=$OPDATA`echo -ne "\n$d"`
        done
      FS cmdclose
    }
    
    local apiops="get_srv_agent_status get_xen_caps get_free_memory get_server_xm_info get_host_info get_host_arch"
      apiops=${apiops}" get_hs_perf get_server_config get_server_mode get_server_perf_metrics"
      apiops=${apiops}" get_servers_perf sys_perf_info get_network_config get_network_bridges"
    FS group "Cluster Status" clusterstatus
      ifzFSw cmdrecall "virt.ovmserver.repos.validrootsr"
        K; FS cmd "Cluster Members" "${AGD}/db/db_dump.py /OVS/.ovs-agent/db/srv.db | cut -d'=' -f1 | sort" nodes
        if [ "$ABORTFA" = "0" ]; then
          clmembers=$OPDATA
          for op in $apiops; do
            FS conmsg "-"; let "++PREVLINEPOS"
            GetMemberData $op
          done
        fi
  }

  function APINodeDump() {
    FS group "OVS cluster info (via API)" cluster_info
      K; DoRPC "Server registered" "is_registered" is_registered
      DoRPC "check_cluster_root_sr_new" "check_cluster_root_sr_new" check_cluster_root_sr_new
      DoRPC "cluster_get_info" "cluster_get_info" cluster_get_info
      K; DoRPC "cluster_get_master" "cluster_get_master" cluster_get_master "The master server is not set"
      DoRPC "cluster_get_next_master" "cluster_get_next_master" cluster_get_next_master
      DoRPC "get_master_ip" "get_master_ip" get_master_ip
      DoRPC "get_master_vip" "get_master_vip" get_master_vip
      DoRPC "cluster_check_prerequisite" "cluster_check_prerequisite" cluster_check_prerequisite
      DoRPC "get_agent_conf_mode" "get_agent_conf_mode" get_agent_conf_mode
  }
  
  function APIClusterDump() {
    local node op n
    local apiops="get_free_memory sys_perf_info get_server_xm_info get_host_info get_xen_caps get_host_arch"
      apiops=${apiops}" get_hs_perf get_server_config get_server_mode get_server_perf_metrics"
      apiops=${apiops}" get_servers_perf get_srv_agent_status get_network_config get_network_bridges"
    FS group "Get node and global cluster info" clusternodeinfo
      A; K; FS cmd "Cluster Members" "${AGD}/db/db_dump.py /OVS/.ovs-agent/db/srv.db | cut -d'=' -f1 | sort" nodes
      CLMEMBERS=$OPDATA
    if [ "$EXTOVM" = "1" ]; then 
      n="1"
      for node in $CLMEMBERS; do
        FS conmsg "$n"; PREVLINEPOS=$(( $PREVLINEPOS + ${#n})); let "++n"
        for op in $apiops; do
          FS cmd "${node%%.*}:$op" "${AGD}/utils/do_rpc.py $op $node" ${node%%.*}.$op
        done
      done
    fi
  }

  function NodeConnectivityCheck() {
    if [ "$NETPROBE" = "0" ]; then return 0; fi
    FS group "OVS Connectivity" connectivity
    local n="0"
    for node in $CLMEMBERS; do
      KHC; FSw cmd "Ping ovs node $node" "ping -c 2 -w 4 $node" ovsping_node$n
      let "++n"
    done
    n="0"
    for node in $CLMEMBERS; do
      KHC; FSw cmd "Check agent port for $node" "nc -zv $node 8899" ovsport_node$n
      let "++n"
    done
  }
  
  HOSTPW=""; HOSTPWCK=""; CLUSTERPW=""; CLUSTERPWCK=""; CLUSTERPWDIFFER=""
  function DumpBerkelyDBs() {
    local hn="" pw="" cksum="" bdbs lastck fn i ck oldifs hn

    function ProcessPW() {
      hn=`echo $1|xargs|cut -d' ' -f1`
      pw=`echo ${1#*agt_passwd}|cut -d"'" -f3`
      ck=`echo $pw|sum|cut -d' ' -f1`
    }

    FS group "Snapshot of local OVS data" localdb
      bdbs=`ls /etc/ovs-agent/db/*.db | grep -v dbn` # get rid of dbn backups
      for i in $bdbs; do 
        fn=`basename $i`
        FS cmd "$i" "${AGD}/db/db_dump.py $i" ${fn%%.*}
      done  
    FS group "Snapshot of global OVS root data" rootdb
      bdbs=`ls /OVS/.ovs-agent/db/*.db | grep -v dbn` # get rid of dbn backups
      lastck=""
      for i in $bdbs; do
        fn=`basename $i`
        FS cmd "$i" "${AGD}/db/db_dump.py $i" ${fn%%.*}
        if [ "$i" = "/OVS/.ovs-agent/db/srv.db" ]; then
          oldifs=$IFS; IFS=$'\n'
          for j in $OPDATA; do
            ProcessPW "$j"
            CLUSTERPW="$CLUSTERPW $hn:$pw"; CLUSTERPWCK="${CLUSTERPWCK}$hn:$ck\n";
            if [ -z "$lastck" ]; then lastck=$ck
            elif [ "$lastck" != "$ck" ]; then CLUSTERPWDIFFER="1"
            fi
          done
          IFS=$oldifs        
        fi
      done
  }

  function SaveBerkeleyBinaries() {
    if [ "$WRITEDB" != "0" ]; then
      if [ -d /OVS/.ovs-agent ]; then  
        mkdir -p $VMPDIAGS/misc/agent-rootdb
        cp -a /OVS/.ovs-agent/* $VMPDIAGS/misc/agent-rootdb
        FLink "misc/agent-rootdb"
      fi
      if [ -d /etc/ovs-agent/db ]; then  
        mkdir -p $VMPDIAGS/misc/agent-etcdb
        cp -a /etc/ovs-agent/db/* $VMPDIAGS/misc/agent-etcdb
        FLink "misc/agent-etcdb"
      fi
    fi
  }

  function DumpLog() {
    nzFSe cmd "$1" "grep $2 | cut -d' ' -f4,5,6,7,8,9,10 | sed -e 's/<\|>//g'|sort -u" "$3"
  }
 
  function OVS2LogAnalysis() {
     
    FS section "VM Server Logs" logs; local loc="/var/log/ovs-agent"    
    FS group "ovs_autorun" ovs_autorun
      K; nzFSe cmd "Total ovs_autorun.log errors/warnings" "egrep -ic error\|warn $loc/ovs_autorun.log" errorswarnings
      fsize $loc/ovs_autorun.log
      FS link "Link to ovs_autorun.log" "var/log/ovs-agent/ovs_autorun.log" $FSIZE
    FS group "ovs_operation" ovs_operation
      K; nzFSe cmd "ovs_operation errors/warnings" "egrep -ic error\|warn $loc/ovs_operation.log" errorswarnings
      K; nzFSe cmd "ovs_operation exceptions" "egrep -ic exception $loc/ovs_operation.log" exceptions
      fsize $loc/ovs_operation.log
      FS link "Link to ovs_operation.log" "var/log/ovs-agent/ovs_operation.log" $FSIZE
      fsize $loc/ovs_performance.log
      FS link "Link to ovs_performance.log" "var/log/ovs-agent/ovs_performance.log" $FSIZE
      fsize $loc/ovs_query.log
      FS link "Link to ovs_query.log" "var/log/ovs-agent/ovs_query.log" $FSIZE
      fsize $loc/ovs_upgrade.log
      FS link "Link to ovs_upgrade.log" "var/log/ovs-agent/ovs_upgrade.log" $FSIZE
    FS group "ovs_root" ovs_errwarn
      DumpLog "API Errors" "ERROR $loc/ovs_root.log.nopw" "api_errors"
      fsize $loc/ovs_root.log.nopw; local rootsz=$FSIZE
      FS link "Link to ovs_root.log.nopw" "var/log/ovs-agent/ovs_root.log.nopw" $rootsz
      DumpLog "API Warnings" "WARN $loc/ovs_root.log.nopw" "api_warnings" 
      FS link "Link to ovs_root.log.nopw" "var/log/ovs-agent/ovs_root.log.nopw" $rootsz
      DumpLog "API Exceptions" "-i exception $loc/ovs_root.log.nopw" "api_exceptions"
      FS link "Link to ovs_root.log.nopw" "var/log/ovs-agent/ovs_root.log.nopw" $rootsz
      FS link "Link to vm.cfg files on all repos" "misc/vm-cfg"
      FS link "Link to /var/log/ovs-agent" "var/log/ovs-agent"
      FS link "Link to /var/log/xen" "var/log/xen"
  }
  
  function OVS3LogAnalysis() {    
    FS section "VM Server Logs" logs; local loc="/var/log"     
    FS group "ovs_agent" ovs_agent
      K; nzFSe cmd "ovs-agent errors/warnings" "egrep -ic error\|warn /var/log/ovs-agent.log" errorswarnings
      K; nzFSe cmd "ovs-agent exceptions" "egrep -ic exception /var/log/ovs-agent.log" exceptions
      fsize /var/log/ovs-agent.log
      FS link "Link to ovs-agent.log" "var/log/ovs-agent.log" $FSIZE
    FS group "Operation logs" op_logs
      fsize /var/log/osc.log
      FS link "Link to Storage Connect osc.log" "var/log/ovs_performance.log" $FSIZE
      
      fsize /var/log/ovmwatch.log
      FS link "Link to ovmwatch.log" "var/log/ovmwatch.log" $FSIZE
      
      fsize /var/log/ovm-consoled.log
      FS link "Link to ovm-consoled.log" "var/log/ovs-console.log" $FSIZE

      fsize /var/log/devmon.log
      FS link "Link to devmon.log" "var/log/devmon.log" $FSIZE
  }

  function DumpManager2DB() {
    { GetTagData scripts.mgrdump "" "all"; } > $VMPDIAGS/ovm2exp.sql
    ORACLE_HOME=/usr/lib/oracle/xe/app/oracle/product/10.2.0/server
    PATH=$PATH:$ORACLE_HOME/bin
    ORACLE_SID=XE
    export ORACLE_HOME; export PATH; export ORACLE_SID
    if [ -z "$OVSPW" ]; then # no pw provided with -j, prompt for one 
      echo; echo
      while true; do
        read -sp "Please enter the ovs user password for the database dump:" OVSPW
        if [ -z "$OVSPW" ]; then
          FS cmd "Manager DB Dump" "/bin/false" ovs_dbdump "No password entered: operation aborted"
          return
        fi
        echo quit | sqlplus -S -L ovs/$OVSPW >/dev/null 2>&1
        if [ "$?" = "0" ]; then break
        else echo; echo "Password incorrect... please retry or hit Enter to skip the database dump"
        fi
      done
      echo; PREVLINEPOS=1
    fi
    K; FS cmd "Manager DB Dump" "sqlplus -S -L ovs/$OVSPW @$VMPDIAGS/ovm2exp.sql" ovs_dbdump
    if [ -z "$OVSPW" ]; then echo; fi
  }
  

#$ echo "cat //OvmModel//Repositories/FileServers/FileServer" | xmllint --shell ovmm.xml
#/ > / > tlisjac@tlisjac-linux:~ $ echo "cat //OvmModel//Repo/FileServers/FileServer" | xmllint --shell ovmm.xml>]*.//g'
#/ > / > tlisjac@tlisjac-linux:~ $ echo "cat //OvmModel//Repositories/FileServers/*" | xmllint --shell ovmm.xml
#/ > / > tlisjac@tlisjac-linux:~ $ echo "cat //OvmModel//Repositories/FileServers/*/@*" | xmllint --shell ovmm.xml
#/ > / > tlisjac@tlisjac-linux:~ $ echo "cat //OvmModel//Repositories/*/@*" | xmllint --shell ovmm.xml
#/ >  -------
# ID="0004fb00000300007c4324082e45a1fa"
# -------
# ID="0004fb0000030000020216fd37573ab3"
#/ > tlisjac@tlisjac-linux:~ $ echo "cat //OvmModel//Repositories/*/@*" | xmllint --shell ovmm.xml|xargs
#/ > ------- ID=0004fb00000300007c4324082e45a1fa ------- ID=0004fb0000030000020216fd37573ab3 / >


  function DumpManager3DB() {
    OVMMCONFIG="/u01/app/oracle/ovm-manager-3/.config"
    FS cmd "OVMM config file" "cat $OVMMCONFIG" ovmm_config "The OVMM configuration file is not present. This manager is damaged or inoperative"
    if [ "$OPSTATUS" -ne "0" ]; then return 1; fi
    MAJORVER=`grep BUILDID= $OVMMCONFIG | cut -d'=' -f2|cut -d'.' -f1,2`
  
    FS group "OVMM DB and Configuration data" ovmm_data
      if [ -z "$OVSPW" ]; then echo; read -sp "Please enter the UI \"admin\" password for Oracle VM Manager:" OVSPW; fi
      if [ -z "$OVSPW" ]; then return 1; fi
      mkdir -p $VMPDIAGS/misc/ovmm-data
      rm -f /tmp/ovmm.xml
      if [ "$MAJORVER" = "3.3" ] || [ "$MAJORVER" = "3.4" ]; then exportcmd="modelMgr.exportModelData(\"/tmp/ovmm.xml\")"
      elif [ "$MAJORVER" = "3.2" ]; then exportcmd="taskMgr.dumpModelData(\"/tmp/ovmm.xml\")"
      else FS msgln "DB dump not supported in this version of ovmm"
      fi
      { echo "ovmMgr = OvmClient.getOvmManager()"
        echo "foundry = ovmMgr.getFoundryContext()"
        echo "logMgr = foundry.getLogManager()"
        echo "modelMgr = foundry.getModelManager()"
        echo "taskMgr = foundry.getTaskManager()"
        echo "job = ovmMgr.createJob(\"Dump OVM Model DB\")"
        echo "job.begin()"
        echo "$exportcmd"
        echo "job.commit()"
      } > $VMPDIAGS/dumpdb.ovm
      /u01/app/oracle/ovm-manager-3/ovm_shell/ovm_shell.sh -u admin -p $OVSPW < $VMPDIAGS/dumpdb.ovm >/dev/null 2>&1
      if [ -f /tmp/ovmm.xml ]; then mv /tmp/ovmm.xml $VMPDIAGS/misc/ovmm-data # because ovm_shell wouldn't take a full path
      else FS msgln "DB xml dump failed"
      fi
      rm -f /$VMPDIAGS/dumpdb.ovm
  }
  
  function DumpManager2Data() {
    FS group "Oracle VM Manager Packages" packages
      K; FSe cmd "XE, VM Manager and oc4j versions" "egrep ovs-manager\|oc4j\|oracle-xe-univ $VMPDIAGS/misc/pkg-list" versions "oc4j and vm manager packages not found: vm manager is not installed correctly on this system"
    FS group "XE Database status" xeinstance
      KHC; ServiceCheck "oracle-xe-univ" "oracle-xe" e
      if [ "$ABORTFA" = "0" ]; then DumpManager2DB; fi
      FS cmd "XE processes" "ps aux | grep -i xe_ | egrep -v grep" processes
    FS group "oc4j status" oc4j
      FS cmd "oc4j installed" "grep ^oc4j $VMPDIAGS/misc/pkg-list" installed  
      FS cmd "oc4j status" "service oc4j status" sysv_status
      FS cmd "oc4j processes" "ps aux | grep oc4j | grep -v grep" processes
      FS dolink "/opt/oc4j/j2ee/home/config" "cp -a /opt/oc4j/j2ee/home/config $VMPDIAGS/misc/j2ee-config" misc/j2ee-config
      FS cmd "Manager DB is local" "grep -q @localhost:1521:XE /opt/oc4j/j2ee/home/config/data-sources.xml" vmmgr_islocal "No" "Yes"
    FS section "VM Manager Logs" logs; loc="/var/log/ovm-manager"     
    FS group "DB logs" dblogs
      nzFS cmd "Total db.log errors/warnings" "egrep -ic error\|warn $loc/db.log" errorswarnings
      FS cmd "ORA Errors" "grep ORA- $loc/db.log | sort -u" ora_errors
      FS link "Link to db.log" "var/log/ovm-manager/db.log"
    FS group "oc4j Logs" oc4j
      K; nzFS cmd "Total oc4j.log errors/warnings" "egrep -ic error\|warn $loc/oc4j.log" errorswarnings
      fsize $loc/oc4j.log; oc4jsz=$FSIZE
      FS link "Link to entire oc4j.log" "var/log/ovm-manager/oc4j.log" $oc4jsz
      FS dolinks "oc4j.log grepped errors and warnings" "egrep -vi notification\|^$ $loc/oc4j.log > $VMPDIAGS/misc/oc4jerrwarn" misc/oc4jerrwarn
      K; nzFS cmd "Total oc4j.log exceptions" "egrep -ic exception $loc/oc4j.log" exceptions
      nzFS cmd "oc4j OVM Error count" "grep -c OVM- $loc/oc4j.log" ovm_errors          
      FS link "Link to entire oc4j.log" "var/log/ovm-manager/oc4j.log" $oc4jsz
  }
  
  function DumpServer3Data() {
    LocalNodeStatus
    FS group "local ovs-agent and pool data" ovs-agentdb
      K; FS cmd "cluster_state" "ovs-agent-db dump_db server | grep cluster_state | cut -d\"'\" -f4" cluster_state
      K; FS cmd "clustered" "ovs-agent-db dump_db server | grep clustered | cut -d' ' -f3|cut -d',' -f1" clustered
      K; FS cmd "is_master" "ovs-agent-db dump_db server | grep is_master | cut -d' ' -f3|cut -d',' -f1" is_master
      K; FS cmd "pool_alias" "ovs-agent-db dump_db server | grep pool_alias | cut -d\"'\" -f4" pool_alias
      K; FS cmd "manager_uuid" "ovs-agent-db dump_db server | grep manager_uuid | cut -d\"'\" -f4" manager_uuid
      K; FS cmd "poolfs_uuid" "ovs-agent-db dump_db server |grep poolfs_uuid | cut -d\"'\" -f4" poolfs_uuid 
      K; FS cmd "registered_ip" "ovs-agent-db dump_db server | grep registered_ip | cut -d\"'\" -f4" registered_ip
      K; FS cmd "registered_hostname" "ovs-agent-db dump_db server | grep registered_hostname | cut -d\"'\" -f4" registered_hostname
      K; FS cmd "roles" "ovs-agent-db dump_db server | grep roles | cut -d\"(\" -f2|cut -d')' -f1" roles
      if [ "$MAJORRELEASE" = "3.3" ] || [ "$MAJORRELEASE" = "3.4" ]; then 
        K; FS cmd "manager ip" "ovs-agent-db dump_db server|grep manager_event_url |xargs|cut -d'/' -f3 | cut -d':' -f1" manager_ip
        K; FS cmd "manager port" "ovs-agent-db dump_db server|grep manager_event_url |xargs|cut -d'/' -f3 | cut -d':' -f2" manager_port
      else
        K; FS cmd "manager ip" "ovs-agent-db dump_db server|grep manager_core_api_url |xargs|cut -d'@' -f2|cut -d'/' -f1|cut -d':' -f1" manager_ip
        K; FS cmd "manager port" "ovs-agent-db dump_db server|grep manager_core_api_url |xargs|cut -d'@' -f2|cut -d'/' -f1|cut -d':' -f2" manager_port      
      fi
  }

  function DumpServer2Data() {
    local a=`rpm -ql ovs-agent | egrep utils$`
    AGD=${a%/*}
    LocalNodeStatus
    NetworkBPCheck
    ClusterFilesystems
    ClusterStatus
    APINodeDump
    APIClusterDump
    NodeConnectivityCheck
    DumpBerkelyDBs
    SaveBerkeleyBinaries
    FS group "OVS Agent Password Checks" agent_pw
      FS cmd "Pool ovs password checksums" "echo -e \"$CLUSTERPWCK\"" poolpwck
      KHC; FS cmd "All node ovs passwords match" "[ -n $CLUSTERPWDIFFER ]" poolpwmatch "No" "Yes"
  }

  # Begin VirtXenInfo
  if [ "$ROLE" = "$OVMSERVER" ]; then
   FS section "Collecting Oracle VM Server Information" ovmserver
      if [ "$OVMVERSION" = "3.0" ]; then DumpServer3Data; OVS3LogAnalysis
      elif [ "$OVMVERSION" = "2.2" ]; then DumpServer2Data; OVS2LogAnalysis 
      fi   
  elif [ "$ROLE" = "$OVMMANAGER" ]; then
    FS section "Collecting Oracle VM Manager Information" ovmmanager
      if [ "$OVMVERSION" = "3.0" ]; then
          DumpManager3DB
          FLink "misc/ovmm-data/ovmmdb.xml"
      elif [ "$OVMVERSION" = "2.2" ]; then DumpManager2Data  
      fi
  fi
}

# # # # # # # # #
#
# ---> Scope: APPS
#

function Httpd() {
  local z i
  FS section "httpd" httpd
    FS group "Configuration" conf
      ServiceCheck "httpd" "httpd"
      FS cmd "/etc/sysconfig/httpd" "$CAT /etc/sysconfig/httpd" httpd_sysconfig
      FS cmd "httpd.conf" "$CAT /etc/httpd/conf/httpd.conf|sed -e 's/</\&lt;/g'|sed -e 's/>/\&gt;/g'" httpd_conf
      if [ "$ABORTFA" = "0" ]; then
        for z in /etc/httpd/conf.d/*; do
          i=`basename $z`
          FS cmd "$i" "$CAT /etc/httpd/conf.d/$i|sed -e 's/</\&lt;/g'|sed -e 's/>/\&gt;/g'" "${i%%.*}_conf"
        done 
      fi
    FS group "php" php   
    ifzFS cmd "php installed" "grep ^php- $VMPDIAGS/misc/pkg-list" installed
      FS cmd "php.ini" "grep -vh '^\(;\|$\)' /etc/php.ini" php_ini
}

function MySQL() {
  FS section "mysql" mysql
    FS group "Configuration" conf
    ServiceCheck "mysql" "mysqld"
      FS cmd "my.cnf" "$CAT /etc/my.cnf" my_cnf
}

function SendMailPostfix() {
  FS section "sendmail" sendmail
    FS group "Configuration" conf
    ServiceCheck "sendmail" "sendmail" w
      FS dolink "Sendmail dir" "cp -a /etc/mail $VMPDIAGS/etc" etc/sendmail_dir
      FS cmd "Sendmail config" "$CAT /etc/sysconfig/sendmail" sendmail_conf
    ServiceCheck "postfix" "postfix" w
      FS dolink "Postfix dir" "cp -a /etc/postfix $VMPDIAGS/etc" etc/postfix_dir
      FS link "postconf" "postconf > $VMPDIAGS/misc/postconf" misc/postconf
}

function SNMP() {
  FS section "snmp" snmp
    FS group "Configuration" conf
    ServiceCheck "net-snmp" "snmpd"
      FS cmd "snmp.conf" "$CAT /etc/snmp/snmpd.conf" snmpd_conf
}

# # # # # # # # #
#
# ---> Scope: PROD
#

function OracleRDBMS() {
  FS section "Oracle-RDBMS" Oracle
    FS group "Configuration" conf
    ifzFS cmd "running instances" "ps aux | grep smon | grep -v grep" running_instances
    endifFS
}

# # # # # # # # # # # # # # # # # #
#
# ---> DoHostScan Support Routines
#

function WriteSystemLogs() { # complicated a bit by non-root user case
  local i

  if [ "$LOGGING" -ge "8" ]; then AddData "var/lib/* var/log/* etc/*"
  elif [ "$LOGGING" -ge "7" ]; then AddData "var/log/* etc/*"
  elif [ "$LOGGING" -ge "6" ]; then AddData "var/log/*"
  else
    if [ "$LOGGING" -ge "1" ]; then AddData "var/log/messages var/log/dmesg"; fi
    if [ "$LOGGING" -ge "2" ]; then AddData "var/log/messages*"; fi
    if [ "$LOGGING" -ge "3" ]; then AddData "var/log/boot* var/log/cron* var/log/yum*"; fi
    if [ "$LOGGING" -ge "4" ]; then AddData "var/log/maillog* var/log/httpd var/log/samba var/log/cups"; fi
    if [ "$LOGGING" -ge "5" ]; then AddData "var/log/se* var/log/audit*"; fi
  fi
  FLink "var/log/messages var/log/dmesg"
  if [ "$ROLE" = "$OVMSERVER" ]; then
    if [ "$OVMVERSION" = "2.2" ]; then
     [ -f /var/log/ovs-agent/ovs_root.log.nopw ] && rm -f /var/log/ovs-agent/ovs_root.*.nopw*
      # Scrub ovs-agent pw info from this api call
      for i in `find /var/log/ovs-agent/ovs_root*`; do
        cp $i $i.nopw
        sed -i 's/cluster_precheck:.*$/cluster_precheck: Line deleted by vmpscan to remove passwords/g' $i.nopw
      done
      AddData "var/log/ovs-agent/*.nopw var/log/ovs-agent/ovs_autorun.* var/log/ovs-agent/ovs_operation.*"
      AddData "var/log/ovs-agent/ovs_performance.* var/log/ovs-agent/ovs_query.* var/log/ovs-agent/ovs_remaster.*"
      AddData "var/log/ovs-agent/ovs_upgrade.log"
      AddData "var/log/xen var/log/libvirt"; AddData "var/lib/xen/xend-db"; 
      FLink "var/log/ovs-agent"
    else AddData "var/log/o*"; AddData "var/log/dev*"; AddData "var/log/br*"; AddData "var/log/xen"
    fi
    FLink "var/log/xen"
  elif [ "$ROLE" = "$OVMMANAGER" ]; then
    if [ -d  /var/log/ovm-manager-template ]; then AddData "var/log/ovm-manager-template"; fi
    AddData "var/log/ovm-manager"; FLink "var/log/ovm-manager"
  elif [ "$HOSTTYPE" = "$XENDOM0" ]; then AddData "var/log/xen libvirt"; FLink "var/log/xen"
  fi
  pushd . >/dev/null 2>&1
  {
   cd $VMPDIAGS; chmod -R 755 $VMPDIAGS/proc
   tar --ignore-failed-read -czf $VMPDIAGS/archives/local.tar.gz etc proc 2>&1 | grep -v sock
   rm -rf $VMPDIAGS/etc $VMPDIAGS/proc
   cd / # save relative to root
   tar --ignore-failed-read -czf $VMPDIAGS/archives/var.tar.gz $FILESTOSAVE 2>&1 | grep -v sock
  } >> $SCRIPTLOG
  [ -f /var/log/ovs-agent/ovs_root.log.nopw ] && rm -f /var/log/ovs-agent/ovs_root.*.nopw*
  popd >/dev/null 2>&1
  if [ "$LOGGING" != "0" ] && [ "$LOGROTATE" != "0" ]; then
    log logrotate -f /etc/logrotate.conf;
  fi
}

function WriteReportsAndArchive() {

  function WriteStats() { # Write stats to the console after scan is complete
    local e=$(printf '\033')
    echo | tee -a $CONOUT
    echo -en "FAE ops: $((TOTALOK+TOTALWARNINGS+TOTALERRORS)) ---> " | tee -a $CONOUT
    echo -e "$OKCOLOR$TOTALOK ok  $WARNCOLOR$TOTALWARNINGS warnings  $ERRORCOLOR$TOTALERRORS errors" | tee -a $CONOUT
    echo -en $NORMCOLOR | tee -a $CONOUT
    echo "Elapsed time: $ELAPSEDTIME seconds" | tee -a $CONOUT
    echo
    echo "Archive of all data is here: $BASEDIR/$OUTFILE" | tee -a $CONOUT
    echo | tee -a $CONOUT
    sed -i "s/$e\[[0-9;]*m//g" $CONOUT  # remove ansi escapes from the conout file
  }

  function ScrubOVSPasswords() {

    function ScrubVNCPasswords() {
      sed -i s/vncpasswd=.*\'/vncpasswd=pw_removed\'/g $VMPDIAGS/misc/vm-cfg
      sed -i s/vncpasswd\ =.*\'/vncpasswd\ =\ pw_removed\'/g $VMPDIAGS/misc/vm-cfg
      sed -i s/vncpasswd.*\"/vncpasswd\ =\ pw_removed/g $VMPDIAGS/misc/xenstore-ls
      sed -i s/vncpasswd\ .*\)/vncpasswd=pw_removed\)/g $VMPDIAGS/misc/xm_list-l
    }

    function ScrubAgentPasswords() {
      local i
      #keep to test future vers: pwfiles=`egrep -Rl 'https://oracle:.*\@|agt_passwd' $VMPDIAGS 2>/dev/null`
      for i in $1; do
        sed -i 's/https:\/\/oracle:.*\@/https:\/\/\oracle:pw_removed@/g' $VMPDIAGS/$i
        sed -i 's/agt_passwd.*\,/agt_passwd'\'': '\''pw_removed'\''\,/g' $VMPDIAGS/$i
        echo -n "."
      done
    }

    if [ "$ROLE" = "$OVMSERVER" ] && [ "$OVMVERSION" = "2.2" ]; then # Wipe ovs-agent passwords
      echo -n "Scrubbing user passwords from ovs-agent data... please wait:"
      ScrubVNCPasswords
      ScrubAgentPasswords "vmpscan.txt vmpscan.htm vmpdata/alldata.virt" 
      echo " Done!"
    fi
  }

  function initmerge() { # Script that is pushed to the archive root... used to decompress and link node data
    echo "#!/bin/bash"   # ... also contains clean.sh that is created when merge.sh is run
    echo "# Author: Tom Lisjac - License GPL2"
    echo "  VER=\"$VERSION\""
    echo "  echo VMPScan archive merge utility - Version $VERSION.$REVISION"; echo '  echo'
    echo '  echo "#!/bin/bash" > clean.sh'
    echo "  echo \"# Generated by VMPScan $VERSION.$REVISION - Author: Tom Lisjac - License GPL2\" >> clean.sh"  
    echo "  echo VER=\\\"$VERSION\\\" >> clean.sh"
    echo "  echo echo \"VMPScan clean utility - Version $VERSION.$REVISION\" >> clean.sh"
    GetTagData "scripts.merge" "" "all"
    return 
  } > $MERGESCRIPT


  # Put the pieces together...
  
  local i b pwfiles
  echo "<hr><br>" >> $HTMLDATA
  if [ -f $SYSHEALTHTEXT ]; then cat $SYSHEALTHTEXT >> $TEXTDATA; fi
  if [ -f $ERRORTEXT ]; then cat $ERRORTEXT >> $TEXTDATA; rm -f $ERRORTEXT; fi
  if [ -f $WARNINGTEXT ]; then cat $WARNINGTEXT >> $TEXTDATA; rm -f $WARNINGTEXT; fi
  echo "</table></div>" >> $SYSHEALTHHTML; echo "</table></div>" >> $SYSHEALTHCLU
  if [ -f $SYSHEALTHHTML ]; then cat $SYSHEALTHHTML >> $HTMLDATA; fi
  echo "</table></div>" >> $ERRORHTML; echo "</table></div>" >> $ERRORCLU
  if [ -f $ERRORHTML ]; then cat $ERRORHTML >> $HTMLDATA; fi
  echo "</table></div>" >> $WARNINGHTML; echo "</table></div>" >> $WARNINGCLU
  if [ -f $WARNINGHTML ]; then cat $WARNINGHTML >> $HTMLDATA; fi
  echo "</body></html>" >> $HTMLDATA
  if [ "$EMITXML" = "1" ]; then echo "</$SESSIONID>" >> $XMLDATA; fi

  # TODO: not pretty: refactor the html generation and I/O redirection in next version
  echo "</td><td>" >> $SECTIONHEADERS
  echo "<span class=\"tagh\"><a href=\"WARNING-README.TXT\">WARNING!</a></span><br>" >> $SECTIONHEADERS
  echo "<span class=\"tagh\"><a href=\"proc\">/proc</a></span><br>" >> $SECTIONHEADERS
  echo "<span class=\"tagh\"><a href=\"etc\">/etc</a></span><br>" >> $SECTIONHEADERS
  echo "<span class=\"tagh\"><a href=\"var\">/var</a></span><br>" >> $SECTIONHEADERS
  if [ -d $VMPDIAGS/sys ]; then echo "<span class=\"tagh\"><a href=\"sys\">/sys</a></span><br>" >> $SECTIONHEADERS; fi
  echo "<span class=\"tagh\"><a href=\"misc\">misc</a></span><br>" >> $SECTIONHEADERS
  if [ -f $TEXTDATA ]; then echo "<span class=\"tagh\"><a href=\"vmpscan.txt\">text_report</a></span><br>" >> $SECTIONHEADERS; fi
  if [ -f $XMLDATA ]; then echo "<span class=\"tagh\"><a href=\"vmpscan.xml\">xml_report</a></span><br>" >> $SECTIONHEADERS; fi
  if [ -f $DBDATA ]; then echo "<span class=\"tagh\"><a href=\"vmpscan.sqlite\">db_report</a></span><br>" >> $SECTIONHEADERS; fi
  if [ -n "$SOSREPORT" ]; then echo "<span class=\"tagh\"><a href=\"sos\">sos</a></span><br>" >> $SECTIONHEADERS; fi
  if [ -s $SCRIPTLOG ]; then echo "<span class=\"tagh\"><a href=\"vmpdata/scriptlog.txt\">script_log</a></span><br>" >> $SECTIONHEADERS; fi
  if [ -s $CONOUT ]; then echo "<span class=\"tagh\"><a href=\"vmpdata/conout\">conout</a></span><br>" >> $SECTIONHEADERS; fi
  for i in $LOGSTOLINK; do b=${i##*/}; echo "<a href=\"$i\">$b</a><br>" >> $SECTIONHEADERS; done
  echo "</td><!--#cluster-->" >> $SECTIONHEADERS
  echo "<tr><td><a href=\"#$SHORTHOSTNAME-$DT.syshealth\">Health ($TOTALHCFLAGS)</a></td>" >> $SECTIONHEADERS
  echo "<td><a href=\"#$SHORTHOSTNAME-$DT.errors\">Errors ($TOTALERRORS)</a></td>" >> $SECTIONHEADERS
  echo "<td><a href=\"#$SHORTHOSTNAME-$DT.warnings\">Warnings ($TOTALWARNINGS)</a></td>" >> $SECTIONHEADERS
  echo "VMPARCVER=\"$VERSION\"" > $VMPVER
  echo "REVISION=\"$REVISION\"" >> $VMPVER
  echo "REFMD5=\"$REFMD5\"" >> $VMPVER
  echo "CALMD5=\"$SCRIPTMD5\"" >> $VMPVER
  # Make aux directories and links for bolt-on info
  mkdir -p $VMPDIAGS/rda; echo "<td><a href=\"rda\">rda</a></td>" >> $SECTIONHEADERS
  mkdir -p $VMPDIAGS/notes; echo "<td><a href=\"notes\">notes</a></td>" >> $SECTIONHEADERS
  mkdir -p $VMPDIAGS/osw; echo "<td><a href=\"osw\">osw</a></td></tr>" >> $SECTIONHEADERS
  mkdir -p $VMPDIAGS/prod; echo "<tr><td><a href=\"prod\">product data</a></td>" >> $SECTIONHEADERS
  mkdir -p $VMPDIAGS/sos; echo "<td><a href=\"sos\">sos</a></td>" >> $SECTIONHEADERS
  echo "<td><a href=\"misc\">misc</a></td>" >> $SECTIONHEADERS
  echo "<td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr>" >> $SECTIONHEADERS
  echo "<tr><td><a href=\"$SESSIONID/vmpscan.htm\">$SHORTHOSTNAME-$DT</a></td>" > $CLUVIEW
  echo "<td><a href=\"index.htm#$SHORTHOSTNAME-$DT.syshealth\">Health ($TOTALHCFLAGS)</a></td>" >> $CLUVIEW
  echo "<td><a href=\"index.htm#$SHORTHOSTNAME-$DT.errors\">Errors ($TOTALERRORS)</a></td>" >> $CLUVIEW
  echo "<td><a href=\"index.htm#$SHORTHOSTNAME-$DT.warnings\">Warnings ($TOTALWARNINGS)</a></td></tr>" >> $CLUVIEW
  echo "</table></div><br>" >>$SECTIONHEADERS

{ echo "<div class=\"clu\"><table border=\"1\" cellpadding=\"10\" role=\"presentation\"><caption>Legend for Test Headers</caption>"
  echo "<tr><td>T:</td><td>Elapsed Time for test operation</td></tr>"
  echo "<tr><td>C:</td><td>Class of Test:<br>"
  echo "  /h Healthcheck that indicates problem in a critical subsystem<br>"
  echo "  /k Key Parameter included in ClusterView report<br>" 
  echo "  /e Error - Error condition that must be checked<br>"
  echo "  /w Warning - Flagged condition that may or may not be an error<br>"
  echo "  /i Info - Informational test: failures not critical<br>"
  echo "  /b Best Practice setting that should be reviewed</td></tr>" 
  echo "</table></div><br>"; } >>$SECTIONHEADERS

  cat $HTMLDATA >> $SECTIONHEADERS  # Append the data to the section links
  rm -f $HTMLDATA                   # Whack the old data file
  mv $SECTIONHEADERS $HTMLDATA      # Rename the sectionheaders to the main filename
  ScrubOVSPasswords
  WriteStats
  rm -f $VMPDIAGS/fixit.txt
  WriteBlock script.mergewarning $VMPDATA/mw.in  
  cp $VMPDATA/mw.in $VMPDIAGS/WARNING-README.TXT
  initmerge; chmod 744 $MERGESCRIPT
  cp $MERGESCRIPT $BASEDIR
  cd $BASEDIR
  #--exclude "*-socket"
  tar -czf $OUTFILE merge.sh $SESSIONID 2>&1 | grep -v sock >> $SCRIPTLOG
  DeleteWorkingDirectory
}

function Initialize() { # Setup the DoHostScan function report data structures
  local intromsg="VMPScan System Information Utility: Version ${VERSION}.$REVISION"

  function MakeHeaders() {

    function MakeHeader() {
      hmsg=${1:-""}; wrcr=${2:-""} sp=${3:-""}; endsp=${4:-""}
      if ! [ -f "$TEXTDATA" ]; then
        wrdataln $sp$wrcr
        wrdataln "# # # #$wrcr"
        wrdataln "#$wrcr" 
        wrdataln "# -->$1 for $SHORTHOSTNAME-$DT (UTC$TIMEZONE)$wrcr"
        wrdataln "#$wrcr" 
        wrdataln "# # # #$wrcr"
        wrdataln "$endsp$wrcr"
      fi
      }
      
    function MakeTable() {
      dmsg=${1:-""}
      wrdataln "<div class=clu><table border=\"1\" cellpadding=\"10\" role=\"presentation\">"
      wrdataln "<caption>Links to$dmsg Report Details&nbsp;&nbsp;&nbsp;&nbsp;<a href="#top">Top</a></caption>"
      wrdataln "<tr><th>Test Op</th><th>Error&nbsp;Message</th><th>Recommendations</th></tr>"
    }

    local s=$TEXTDATA
    TEXTDATA=$WARNINGTEXT; MakeHeader " WARNINGS"
    TEXTDATA=$ERRORTEXT; MakeHeader " ERRORS"
    TEXTDATA=$SYSHEALTHHTML
    MakeHeader " Key Subsystem Failures" "<br>" "<hr><a name=\"$SHORTHOSTNAME-$DT.syshealth\"></a><span class=\"syshead\">" "</span>"
    MakeTable 
    TEXTDATA=$SYSHEALTHTEXT; MakeHeader " Key Subsystem Failures"
    TEXTDATA=$SYSHEALTHCLU
    MakeHeader " Key Subsystem Failures" "<br>" "<hr><a name=\"$SHORTHOSTNAME-$DT.syshealth\"></a><span class=\"syshead\">" "</span>"
    MakeTable " $SHORTHOSTNAME"
    TEXTDATA=$WARNINGHTML
    MakeHeader " Warnings" "<br>" "<hr><a name=\"$SHORTHOSTNAME-$DT.warnings\"></a><span class=\"warnhead\">" "</span>"
    MakeTable
    TEXTDATA=$WARNINGCLU
    MakeHeader " Warnings" "<br>" "<hr><a name=\"$SHORTHOSTNAME-$DT.warnings\"></a><span class=\"warnhead\">" "</span>"
    MakeTable " $SHORTHOSTNAME"
    TEXTDATA=$ERRORHTML 
    MakeHeader " Errors" "<br>" "<hr><a name=\"$SHORTHOSTNAME-$DT.errors\"></a><span class=\"errhead\">" "</span>"    
    MakeTable
    TEXTDATA=$ERRORCLU 
    MakeHeader " Errors" "<br>" "<hr><a name=\"$SHORTHOSTNAME-$DT.errors\"></a><span class=\"errhead\">" "</span>"    
    MakeTable " $SHORTHOSTNAME"
    TEXTDATA=$s
  }
  
  function inithtml() {  
    echo "<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">"
    echo "<html><head><title>$2</title><style type=text/css>"
    case "$REPORTFORMAT" in
      "1") EchoTagData "man.orachk_css" "";;
        *) EchoTagData "man.vmpscan_css" "";;
    esac
    echo "</style><link rel=\"stylesheet\" media=\"all\" type=\"text/css\" href=\"vmpscan.css\">"
    echo "<link rel=\"stylesheet\" media=\"all\" type=\"text/css\" href=\"../vmpscan.css\"></head><body>"
    echo -e "<a name=\"top\"></a>$1"
  } >>$SECTIONHEADERS
  
  BUSYSYSTEM=""
  function HostPreCheck() { # Perform a host pre-check... flag any low resources

    function ckfail() {
      echo -e "* ---> ${ERRORCOLOR}Precheck Failed: $1${NORMCOLOR}  Pass Criteria: $2"
      PCKFAILS="${PCKFAILS}Failed: $1 -- Pass Criteria: $2\n"
    }

    local lowres="0"
    echo "* Check available disk space, memory and cpu resources: "
    local rootfree=`df -BM / |egrep [0-9]%|xargs|cut -d'M' -f3`
    local vmpscanfree=`df -BM $BASEDIR|egrep [0-9]%|xargs|cut -d'M' -f3`
    if [ "$rootfree" -gt "100" ]; then echo  "*  / $rootfree MB ok"
    else let '++lowres'; ckfail "Disk space=$rootfree MB" "/ partition space < 100 MB"
    fi
    if [ "$vmpscanfree" -gt "100" ]; then echo "*  $BASEDIR $vmpscanfree MB ok"
    else let '++lowres'; ckfail "Report directory space=$vmpscanfree MB" "$BASEDIR space < 100MB"
    fi
    local freemem=`free -m|grep Mem:|xargs|cut -d' ' -f4`
    if [ "$freemem" -gt "5" ]; then echo "* Free Memory $freemem MB ok"
    else let '++lowres'; ckfail "Free Memory=$freemem MB" "Free memory < 5MB"
    fi
    local idlecpu=`vmstat|grep \[0-9\]|xargs|cut -d' ' -f15`
    if [ "$idlecpu" -gt "20" ]; then echo "* CPU idle is ${idlecpu}%"
    else
     let '++lowres'; BUSYSYSTEM="BUSY SYSTEM: "
     DELAYINTERVAL=$((DELAYINTERVAL + 500)); ckfail "CPU Availability=$idlecpu%" "CPU < 20% available"
    fi
    local iowait=`vmstat|grep \[0-9\]|xargs|cut -d' ' -f16`
    if [ "$iowait" -lt "80" ]; then echo "* IOWait is ${iowait}%"
    else 
      let '++lowres'; BUSYSYSTEM="BUSY SYSTEM: "
      DELAYINTERVAL=$((DELAYINTERVAL + 500)); ckfail "System IOWait=$iowait" "IOWait > 80%"
    fi
    if [ "$lowres" != "0" ] && [ "$NODIALOGS" != "1" ]; then
      echo "*"; echo "* WARNING: there were $lowres low resource flags for this system during the pre-check"
      read -p "* THIS IS JUST A WARNING (use -o to skip this prompt)... continue? Y/N:"
      if [[ $REPLY != "Y" && $REPLY != "y" ]]; then echo "Aborting"; DeleteWorkingDirectory; exit 1; fi
    fi
  }

  function PrecheckComplete() {
    echo "ok"; echo "*"; echo "* VMPScan Resource Pre-check complete"
    echo "* * * * * *"; echo
  }

  function CheckOptions() {

    function SetExtendedOptions() {
      EXTOVM="0"; EXTGECOS="0"; EXTSEC="0"; EXTLSOF="0"; EXTNET="0"
      EXTLVM="0"; EXTRAID="0"
      if [ -z "$EXTENDED" ]; then return 0; fi
      case "$EXTENDED" in # Accept legacy numeric argument
        "0") return 0;; "1") EXTENDED="o";; "2") EXTENDED="og";;
        "3") EXTENDED="ogs";; "4") EXTENDED="ogsln";;
      esac
      local i eo=${EXTENDED// /}
      local len=${#eo}
      if [ "$len" != "0" ]; then let '--len'; fi
      for i in `seq 0 $len`; do
        case ${eo:$i:1} in
          o|O) EXTOVM="1";;
          g|G) EXTGECOS="1";;
          s|S) EXTSEC="1";;
          l|L) EXTLSOF="1";;
          n|N) EXTNET="1";;
          v|V) EXTLVM="1";;
          r|R) EXTRAID="1";;
            *) echo; echo "Unknown extended switch ${eo:$i:1}... exiting"; echo; return 1;;
        esac
      done
      return 0
    }

    function SetReportOptions() {
      local i ro=${REPORTOPTIONS// /}
      local len=${#ro}
      EMITXML="0"; EMITDB="0"; EMITTEXT="0"; EMITHTML="0"
      if [ "$len" != "0" ]; then let '--len'; fi
      for i in `seq 0 $len`; do
        case ${ro:$i:1} in
          h|H) EMITHTML="1";;
          t|T) EMITTEXT="1";;
          x|X) EMITXML="1";;
          d|D) EMITDB="1"
               if ! which sqlite3 > /dev/null 2>&1; then
                 echo; echo "sqlite3 not installed... db report option not available"
                 echo "exiting..."; exit 1
               fi
            ;;
            *) echo; echo "Unknown report switch ${ro:$i:1}... exiting"; echo; return 1;;
        esac
      done
      return 0
    }

    function LimitCheck() {
      if ! ([ "$1" -ge "$2" ] && [ "$1" -le "$3" ]); then
        echo; echo "$4 argument is $1 but must be between $2 and $3... exiting"; echo; exit 1
      fi
    }

    LimitCheck "$LOGLEVEL" "0" "5" "Syslog level (-L)"
    LimitCheck "$LOGGING" "0" "8" "Log level (-l)"
    if ! SetReportOptions; then exit 1; fi
    if ! SetExtendedOptions; then exit 1; fi
    if [ -n "$STORAGETEST" ]; then CheckRestrictedDirectories "$STORAGETEST" "STORAGETEST -S"; fi
    if [ -n "$SOSREPORT" ]; then # skip sos installation check if writing a conf file
      if ! (which sosreport >/dev/null 2>&1 || which sysreport >/dev/null 2>&1); then
        echo; echo "The SOS package is not installed on this system: Cannot run sosreport (-g)."; echo; exit 1
      fi
    fi
    if [ "$KVER" = "2.6.9" ]; then # EL4 has nc and dd limitations
      if [ -n "$NODES2TEST" ]; then echo; echo "Node network test is not supported on EL 4"; echo; exit 1; fi # -N
      if [ -n "$STORAGETEST" ]; then echo; echo "Storage test is not supported on EL 4"; echo; exit 1; fi #-S
    fi
  }

# Initialize main block

  echo "* * * * * *"
  echo "* VMPScan Host Resource Pre-check"; echo "*"
  if [ -n "$CONFMSG" ]; then echo "* $CONFMSG"; fi
  CheckScriptMD5
  echo -n "* Init global variables: "
  InitGlobalVars # Propagates BASEDIR to all vars in case it was modified by a -b parameter
  echo "ok"
  echo -n "* Checking selected options: "; CheckOptions; echo "ok"
  # Verify that any test writes don't use restricted directories
  CheckRestrictedDirectories "$BASEDIR" "BASEDIR Initialization"
  if ! mkdir -p $VMPDIAGS; then # Try to create the archive directory if it doesn't exist
    echo; echo "Error: Cannot create directory: $VMPDIAGS"
    echo "Please check the path and your permissions"; echo; exit 1
  fi
  CheckRestrictedDirectories "$VMPDIAGS" "VMPDIAGS mkdir" # just paranoia
  # Create working directories for script related files
  mkdir $VMPDATA  $VMPDIAGS/proc; mkdir -p $VMPDIAGS/etc/sysconfig
  mkdir -p $VMPDIAGS/var/log $VMPDIAGS/var/lib $VMPDIAGS/misc $VMPDIAGS/archives
  echo -n "* Machine and OS type: "
  if ! GetMachineRole; then echo; echo "This machine type is not supported"; return 1; fi
  echo " $HOSTTYPE:$ROLE"
  if ! HostPreCheck; then exit 1; fi
  echo -n "* Writing help cache: "
  WriteBlock fixit.hints $VMPDIAGS/fixit.txt
  echo -ne "ok\n* Generate Clusterview templates: "
  MakeHeaders
  echo "ok" 
  if [ "$JUSTHC" = "1" ]; then
    PrecheckComplete
    echo "---> $intromsg"
    echo
    echo "Starting $ARCTAG Healthcheck scan of $SHORTHOSTNAME: $ROLE ($HOSTTYPE)"
    if [ "`id -u`" != "0" ]; then local uid="non-"; fi
    echo "${BUSYSYSTEM}Running as ${uid}root with $DELAYINTERVAL ms of delay between tests"
    return 0
  fi
  echo -n "* Initialize Report Templates: "
  local pagetitle
  if [ -n "$IDTAG" ]; then pagetitle="$IDTAG:$SHORTHOSTNAME-$DT"; else pagetitle=$SHORTHOSTNAME-$DT; fi
  inithtml "<span class=\"apphead\">$intromsg</span>\n<br><span class=\"head\">Report for: $SHORTHOSTNAME&nbsp; \
    &nbsp;-&nbsp;Session ID: $SHORTHOSTNAME-$DT&nbsp;&nbsp;(UTC$TIMEZONE)</span><br><br>\n \
    <div id=\"nav1\"><table border=\"1\" cellpadding=\"10\" role=\"presentation\"><caption>All Parameter hostview for $SHORTHOSTNAME</caption>" \
    "$pagetitle"
  s=$SECTIONHEADERS; SECTIONHEADERS=$CLUHEAD
  inithtml "VMPScan Report Portal (Collector: $ARCTAG $VERSION.$REVISION)" "<!--#clutitle-->"
  SECTIONHEADERS=$s
  PrecheckComplete
  echo "---> $intromsg"
  echo
  echo "Starting $ARCTAG scan of $SHORTHOSTNAME: $ROLE ($HOSTTYPE)"
  local uid=""; if [ "`id -u`" != "0" ]; then local uid="non-"; fi
  echo "${BUSYSYSTEM}Running as ${uid}root with $DELAYINTERVAL ms of delay between tests"
  echo "Run vmpscan.sh -m to review built-in documentation and manual pages"
  echo
  echo "Data will be saved in: $VMPDIAGS"
  return 0
}

function Startup() {
  RootSquawk
  if ! Initialize; then exit 1; fi; # The init code takes care of the message
  DoStartupDelay
  WriteConf
  FS starttimer 
  FS root "Machine" $SHORTHOSTNAME
}

function Shutdown() {
  if [ "$JUSTHC" = "0" ]; then GenerateHealthcheckReport; fi
  FS msgln
  FS elapsed
  FS msgln "-------------------------------"
  FS msgln "Scan complete... elapsed time: $ELAPSEDTIME seconds"
  FS msgln "End of host report data"
  if [ "$JUSTHC" = "0" ]; then
    WriteSystemLogs
    WriteReportsAndArchive
  fi
}

function TestScriptExecute() { # implement -t switch
  if [ ! -f "$1" ]; then echo "Script $1 not found... quitting"; exit 1; fi
  grep vmptest $1
  if [ "$?" != "0" ]; then  
    echo "External script $1 must have a main function named vmptest... quitting"; exit 1
  fi
  Startup
  DEFAULTFIXITFILE=$1 # Point to the test script for fixit docs
  source $1      # bring in and execute the script code
  vmptest        # execute the required function for external scripts
  Shutdown
}

function GenerateSOSReport() { # implements -g switch
  # not fun... but done
  local fn
  if [ -n "$SOSREPORT" ]; then
    FS conmsgln; FS conmsgln; FS conmsg "==> Generating SOS report "
    mkdir -p $VMPDIAGS/sos
    logit 1 "Start:SOS Report"
    if [ "$ROLE" = "$OVMSERVER" ]; then
      echo y | sysreport $SOSREPORT | tee -a $VMPDIAGS/sosname
      fn=`cat $VMPDIAGS/sosname|grep "Please send"|cut -d' ' -f3`
    else
    { case $KVER in
        2.6.9) echo -e "y\ny\n" |sosreport $SOSREPORT;;
        2.6.18) echo y | sosreport $SOSREPORT;;
        2.6.32) sosreport --batch $SOSREPORT;;
      esac; } | tee -a $VMPDIAGS/sosname
      fn=`cat $VMPDIAGS/sosname|egrep /tmp/sosreport-.*tar.*|xargs`
    fi
    cat $VMPDIAGS/sosname >> $CONOUT
    if [ -f "$fn" ]; then
       mv $fn $VMPDIAGS/archives
       echo `basename $fn` > $VMPDATA/sosfn.txt
       rm -f $fn $VMPDIAGS/sosname
    fi
    logit 1 "End:SOS Report"
    FS conmsgln; FS conmsg "==> SOS report completed "
  fi
}

function GenerateHealthcheckReport() { # Display key parameter healthcheck summary (-k)
  QUIET="0" # let vmpscan speak if it's been quiet
  wrcon "\n\n"
  wrcon "-------- Critical Subsystem Healthcheck -----------"
  cat $SYSHEALTHTEXT | egrep -v '\#|\#$' | tee -a $CONOUT
  if [ "$TOTALHCFLAGS" != "0" ]; then
    wrcon "\n$TOTALHCFLAGS errors were found. Please run a full $ARCTAG scan to generate a detailed report\n"
    wrcon "that will contain additional information. Run ./$ARCTAG -m for instructions.\n"
  else
    wrcon "No major subsystem errors were found by this scan\n"
    if [ -n "$EXCLUDES" ]; then wrcon "\nThe following tests were excluded with the -X option:\n$EXCLUDES\n"; fi
  fi
  wrcon "\n---------------------------------------------------\n"
}

function DoStartupDelay() { # Random delay startup for reduced cluster loading: implements -D
  if [ "$STARTDELAY" != "0" ]; then
    local tdelay=$(( $RANDOM % $STARTDELAY )); echo -n "start delay: $tdelay seconds:"
    while [ $tdelay -gt "10" ]; do sleep 5; tdelay=$((tdelay - 5)); echo -n "<$tdelay>";  done 
    if [ $tdelay -gt "0" ]; then sleep $tdelay; fi; echo; echo "Done... resuming scan"
  fi 
}

function Usage() { ShowManPage "VMPScan $VERSION Command Line Options" "man.usage" "$1"; } # implements -h
function ShowVersion() { # implements -v
  echo; echo "  VMPScan - Version $VERSION.$REVISION"
  echo "  Architect and Author: Tom Lisjac <tom.lisjac>"
  echo "  Current Maintainer:   $MAINTAINER"
  echo "  Release Date: $LASTUPDATE"
  GetTagData "script.md5"; echo "  Released MD5: $FIXITBLOCK"
  GetScriptMD5; echo "  Returned MD5: $SCRIPTMD5"
  EchoTagData man.version
  exit 0
}

function RootSquawk() { # Warn non-root user some data will be missing: bypass with -o
  clear
  if [[ "`id -u`" != "0" && "$NODIALOGS" = "0" ]]; then
    echo
    echo "---> You are running $ARCTAG as a non-root user:"; echo
    echo -n "   "; id; echo 
    echo "This is ok, but the scan won't be able to collect some information"
    echo "such as /var/log/messages and dmesg. If you want this information to"
    echo "be part of the $ARCTAG archive, please exit, become root and re-start."
    echo
    echo "If you continue as `whoami`, errors will be displayed so you'll know"
    echo "what data needs to be gathered as root. You can skip this message by"
    echo "using the -o options on the $ARCTAG command line."
    echo
    read -p "Please press \"y\" to continue as `whoami` or \"Enter\" to exit and restart as root: " REPLY
    echo
    logit 1 "$CONFMSG and running as non-root"
    if [[ $REPLY != "Y" && $REPLY != "y" ]]; then echo "Quitting... no data acquired"; echo; exit 1; fi
  else logit 1 "$CONFMSG and running as root"
  fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # #
# VMPStat Analysis, Dump and Service Dump routines  #
# # # # # # # # # # # # # # # # # # # # # # # # # # #

# --> VMPStat constants

readonly SUPPORTEDVERS="3.2 3.3 3.4"
readonly SYSCONFIG=etc/sysconfig      # Where to find the network configuration files
readonly OVSAGENT=etc/ovs-agent
readonly OCFS2CONF=etc/ocfs2
readonly ISCSICONF=var/lib
readonly SYSCTL=etc/sysctl.conf
readonly OVMMInfo="/u01/app/oracle/ovm-manager-3/.config" # Location of OVMM info
readonly OVMMSys="/etc/sysconfig/ovmm"                    # Yet another location for OVMM info
readonly OVSInfo="/etc/ovs-info"      # Info about current OVS release
readonly EXTDNSTEST="oracle.com"      # lookup target for external DNS resolution test
readonly KMNOTE="1933450.1"           # Applicable Oracle KM note for this script

# --> Global Variables
PASSWORD=""                # Cache for a password per the -p option                    
OSTYPE=""                  # Linux, Solaris... etc
RELEASEVER=""              # X.X.X
BUILD=""                   # Number of the product build
MAJORRELEASE=""            # X.X
V3ROLE=""                  # Either OVS or OVMM... set by the ThisIs* id functions
ISSUPPORTED=""             # Non-blank if this is a supported system
EXITVAL=128                # Exit value returned... 128 if not explicitly set 

function IsRoot() { [ "`id -u`" = "0" ]; }

function ServiceUp() { if ! service $1 status 2>/dev/null; then return 1; else return 0; fi } 2>&1 >/dev/null
function ServiceDown() { if ! service $1 status 2>/dev/null; then return 0; else return 1; fi } 2>&1 >/dev/null
function ServiceStatus() {
  echo -n "  $1 service is "; if ServiceDown $1; then coloroutnl red "down"; return 1; else coloroutnl green "active"; return 0; fi
}

function PackedServiceStatus() {
  echo -n "  "
  for i in $@; do
    service=`echo $i|cut -d',' -f1`; downcolor=`echo $i|cut -d',' -f2`
    echo -n "$service:"; if ServiceDown $service; then colorout $downcolor "down  "; else colorout green "active  "; fi
  done
  echo
}

function StartServices() {
  for i in $*; do  if ! service $i status 2>&1 >/dev/null; then service $i start; fi; done
}  

function StopServices() {
  for i in $*; do if service $i status 2>&1 >/dev/null; then service $i stop; fi; done
}

function GetPassword() { if [ -z "$PASSWORD" ]; then echo; read -s -p "Manager Password (no echo):" PASSWORD; echo; fi; }


# # # # # # # # # # # # #
# Main program components
#

function VerifyOp() { # Confirm permissions are ok for the operation and host is supported for it 
  if ! IsRoot; then echo "Command $COMMAND must be run as root"; echo; return 1; fi
  if [ -z "$ISSUPPORTED" ]; then
    echo "The operation ($COMMAND) is not supported on this system"; echo
    echo "Supported systems are Oracle VM Manager and Server $SUPPORTEDVERS"; echo
    echo "Please see Oracle KM note $KMNOTE for more information about this script"
    echo; return 1
  fi
  return 0
}

function InitializeVMPStat() { # Identify the host type and set the appropriate variables
  
  function IsThisOVMM() {
    if [ -f $OVMMInfo ]; then
      V3ROLE="OVMM"
      RELEASEVER=`grep BUILDID= $OVMMInfo | cut -d'=' -f2`
      MAJORRELEASE=`grep BUILDID= $OVMMInfo | cut -d'=' -f2|cut -d'.' -f1,2`
      return 0
    fi   
  }

  function IsThisOVS() {
    if [ -f $OVSInfo ]; then
      V3ROLE="OVS"
      RELEASEVER=`cat $OVSInfo | grep -i release: | cut -d' ' -f2`
      BUILDID=`cat $OVSInfo | grep -i build: | cut -d' ' -f2`
      MAJORRELEASE=`echo $RELEASEVER|cut -d'.' -f1,2`
    fi
  }

  # Initialize

  # check for Linux host and see if it's ovs or ovmm
  ISSUPPORTED="" # Assume it's not Linux or a supported OVS or OVMM version
  V3ROLE=""        # Either OVMM or OVS
  OSTYPE=`uname`; 
  if [ "$OSTYPE" = "Linux" ]; then
    IsThisOVS; IsThisOVMM 
    if [ -n $V3ROLE ]; then
      for i in $SUPPORTEDVERS; do
        if [ "$i" = "$MAJORRELEASE" ]; then ISSUPPORTED="yes"; return 0; fi
      done
    fi
  fi
  return 1
}
  
function AnalyzeHost() { # Scan and report host status without making any modification... just informational

  function CheckOS() {
    coloroutnl white "Operating System:"
    echo -n "  Kernel release: "; uname --kernel-release
    rootspace=`df -h / | grep -v Filesystem|xargs|cut -d' ' -f2,3,4`
    bootspace=`df -h /boot | grep -v Filesystem|xargs|cut -d' ' -f2,3,4`
    swapspace=`free -m | grep Swap:|xargs`
    echo "  Filesystem usage: Root /:$rootspace  /boot:$bootspace  $swapspace"
    echo -n "  Memory MB: used=`free -m | grep Mem:| xargs | cut -d' ' -f3` free=`free -m | grep Mem:| xargs | cut -d' ' -f4`    "
    dstates=`ps -elf|cut -d' ' -f2|grep -ic D`
    if [ "$dstates" = "0" ]; then coloroutnl green "D-state processes: $dstates"; else coloroutnl red "D-state processes: $dstates"; fi
    echo -n "  Uptime: "; uptime
  }

  function CheckNTP() {
    coloroutnl white "NTP:"
    if ServiceStatus ntpd; then
      z=`ntpstat`
      if [ "$?" = "0" ]; then z=`echo $z|cut -d' ' -f1,2,3,4,5,6,7,8`; coloroutnl green "  $z"
      else coloroutnl red "  System clock is not NTP synchronized: please check /etc/ntp.conf for correct configuration"
      fi
    fi
  }

  function CheckDNS() {
    coloroutnl white "DNS: (timeout = 1 second)"
    if ! rpm -q --quiet bind-utils; then echo "  DNS verification tools not available on this version"; return 0; fi
    hn=`hostname`
    if [ -z "$hn" ]; then coloroutnl red "  Hostname not set"
    else
      if host -W 1 $hn 2>&1 >/dev/null; then coloroutnl green "  `host -W 1 $hn|head -n1`"
      else coloroutnl red "  hostname: $hn does not resolve from any source"
      fi
    fi
    ns=`cat /etc/resolv.conf|grep ^nameserver|cut -d' ' -f2`
    if [ -z "$ns" ]; then coloroutnl red "  no nameservers found in /etc/resolv.conf"
    else
      echo -n "  Configured DNS servers that ping: "
      for i in $ns; do if ping -c 1 -w 2 $i 2>&1 >/dev/null; then colorout green "$i "; else colorout red "$i "; fi; done; echo
    fi
    echo -n "  External DNS resolution "
    if host -W 1 $EXTDNSTEST 2>&1 >/dev/null; then echo -n "is"; else echo -n "is not"; fi; echo " available" 
  }

  function CheckNetworking() {
  
    function DumpInterfaceData() {
      echo "  Interface status:"
      pushd . 2>&1 >/dev/null
      cd /etc/sysconfig/network-scripts
      for i in ifcfg-*; do
        intf=`echo $i|cut -d'-' -f2`
        unset ipaddr speed duplex
        # ipaddr="`ip addr | grep -A2 $intf:|grep "inet "|xargs|cut -d' ' -f2`" # ip addr lumps the interfaces and bonds :(
        ipaddr=`ifconfig $intf 2>/dev/null|grep "inet "|xargs|cut -d':' -f2|cut -d' ' -f1` # old, but reliable and easy to parse
        if echo $intf|grep -iq eth; then
          speed="`ethtool $intf | grep Speed:|xargs|cut -d' ' -f2`, "
          duplex="`ethtool $intf | grep Duplex:|xargs|cut -d' ' -f2` duplex, "
        fi
        if ip link show $intf| grep -q "state UP"; then link="yes"; else link="no"; fi
        bond=`grep MASTER $i| cut -d'=' -f2`
        echo -n "    $intf: $speed${duplex}Link:"; if [ "$link" = "yes" ]; then colorout green "yes"; else colorout yellow "no"; fi
        unset ONBOOT BOOTPROTO
        source /etc/sysconfig/network-scripts/$i
        if [ -z "$ipaddr" ]; then realip="ip:none"
        else
         if echo "$BOOTPROTO"|grep -qi dhcp; then realip="dhcp-ip=$ipaddr"; else realip="fixed-ip=$ipaddr"; fi
        fi
        echo -n " onboot:$ONBOOT, $realip"
        if [ -z "$bond" ]; then echo
        else
          unset IPADDR BOOTPROTO ONBOOT
          bondip=`ip addr | grep -A2 $bond:|grep "inet "|xargs|cut -d' ' -f2`
          source /etc/sysconfig/network-scripts/ifcfg-$bond
          if [ -z "$bondip" ]; then realip="ip:none"
          else
            if echo "$BOOTPROTO"|grep -qi dhcp; then realip="dhcp-ip=$bondip"; else realip="fixed-ip=$bondip"; fi
          fi
          echo " ($bond:$realip, onboot:$ONBOOT)" 
        fi
      done
      popd 2>&1 >/dev/null
    }
  
    # Begin CheckNetworking
    coloroutnl white "Host Networking:"
    DEFAULTGW=`route -n|grep ^0.0.0.0|xargs|cut -d' ' -f2`
    if [ -z $DEFAULTGW ]; then echo "  No default gateway set"
    elif ping -c 1 -w 2 $DEFAULTGW >/dev/null 2>&1; then coloroutnl green "  Default gateway $DEFAULTGW is pingable"
    else coloroutnl red "  Default gateway $DEFAULTGW does not ping"
    fi
    if iptables -L | egrep -v Chain\|target\|^$ 2>&1 >/dev/null; then coloroutnl yellow "  firewall rules are active"
    else coloroutnl yellow "  No firewall rules are active"
    fi 
    DumpInterfaceData   
  }

  function CheckLocalServicePorts() { # dump nc status of specified port ($1),service type ($2)
    echo -n "  Local ports: "
    for i in $@; do
      portnum=`echo $i|cut -d',' -f1`; portname=`echo $i|cut -d',' -f2`
      echo -n "$portnum ($portname):"; if nc -z 127.0.0.1 $portnum 2>&1 >/dev/null; then colorout green "up  "; else colorout red "down  "; fi
    done
    echo 
  }
  
  function AnalyzeOVS() { # Perform a scan of key OVS and OVMM operational parameters. Flag errors in red or warnings in yellow
  
    function CheckServerEnvironment() {
      coloroutnl white "Xen Environment:"
      if ! `xm info >/dev/null 2>&1`; then coloroutnl red "  Xen environment unreachable for status info... check xend service"
      else
        totmem=`xm info | grep total_memory|xargs`
        freemem=`xm info | grep free_memory|xargs`
        nrcpus=`xm info | grep nr_cpus|xargs`
        freecpus=`xm info | grep free_cpus|xargs`
        cpumhz=`xm info | grep cpu_mhz|xargs`
        numvms=`xm list| grep -v 'Name\|Domain-0'|wc -l`
        echo "  $totmem  $freemem  $nrcpus  $freecpus  $cpumhz  Num VMs : $numvms"
        echo "  `xm info | grep xen_commandline|xargs`"
      fi
      coloroutnl white "OVS and misc services:"
      PackedServiceStatus network,red sshd,red crond,red iptables,yellow ocfs2,red o2cb,red
      PackedServiceStatus ovs-agent,red xend,red xendomains,red ovs-devmon,red
      PackedServiceStatus openvswitch,yellow multipathd,yellow iscsi,yellow iscsid,yellow nfs,yellow
    }
    
    function CheckOVSEnvironment() {
      coloroutnl white "OVS status:"
      clustate=`ovs-agent-db dump_db server | grep cluster_state | cut -d"'" -f4`
      clustered=`ovs-agent-db dump_db server | grep clustered | cut -d' ' -f3|cut -d',' -f1`
      ismaster=`ovs-agent-db dump_db server | grep is_master | cut -d' ' -f3|cut -d',' -f1`
      poolalias=`ovs-agent-db dump_db server | grep pool_alias | cut -d"'" -f4`
      mgruuid=`ovs-agent-db dump_db server | grep manager_uuid | cut -d"'" -f4`
      pooluuid=`ovs-agent-db dump_db server |grep poolfs_uuid | cut -d"'" -f4`
      echo "  is_master:$ismaster   clustered:$clustered   cluster_state:$clustate   pool_alias:$poolalias"
      echo "  Owning Manager UUID:$mgruuid   Pool UUID:$pooluuid"
      registeredip=`ovs-agent-db dump_db server | grep registered_ip | cut -d"'" -f4`
      registeredhostname=`ovs-agent-db dump_db server | grep registered_hostname | cut -d"'" -f4`
      roles=`ovs-agent-db dump_db server | grep roles | cut -d"(" -f2|cut -d')' -f1`
      echo "  registered_hostname:$registeredhostname   registered_ip:$registeredip   roles:$roles"
      if ! [ -f /etc/ovs-agent/db/server ]; then echo "  Server database for ovs-agent does not exist. No data available for analysis"; return 1; fi
      if [ -n "$PASSWORD" ]; then
        if ! ServiceUp ovs-agent; then coloroutnl red "  Cannot check OVS agent password: ovs-agent service is not running"
        else
          { ovsres=`ovs-agent-rpc -s https://oracle:$PASSWORD@127.0.0.1:8899/ echo "'$ARCTAG'"`;} 2>/dev/null
          if [ "$ovsres" = "$ARCTAG" ]; then coloroutnl green "  Provided OVS agent password is correct"
          else coloroutnl red "  Provided OVS agent password does not match"
          fi
        fi
      fi 
      if [ "$MAJORRELEASE" = "3.3" ] || [ ""$MAJORRELEASE" = "3.4"" ]; then 
        MGRIP=`ovs-agent-db dump_db server|grep manager_event_url |xargs|cut -d'/' -f3 | cut -d':' -f1`
        MGRPORT=`ovs-agent-db dump_db server|grep manager_event_url |xargs|cut -d'/' -f3 | cut -d':' -f2`
      else
        MGRIP=`ovs-agent-db dump_db server|grep manager_core_api_url |xargs|cut -d'@' -f2|cut -d'/' -f1|cut -d':' -f1`
        MGRPORT=`ovs-agent-db dump_db server|grep manager_core_api_url |xargs|cut -d'@' -f2|cut -d'/' -f1|cut -d':' -f2`      
      fi
      if [ -z "$MGRIP" ]; then coloroutnl yellow "  No Manager for this node"
      elif nc -z $MGRIP $MGRPORT >/dev/null 2>&1; then coloroutnl green "  Manager at $MGRIP:$MGRPORT is reachable on the network"
      else coloroutnl red "  Manager at $MGRIP:$MGRPORT is not reachable on the network"
      fi
    }

    function CheckClusterConfig() {
      clustered=`ovs-agent-db dump_db server | grep clustered| cut -d' ' -f3|cut -d',' -f1`
      if [ "$clustered" != "True" ]; then echo "This node is not clustered"; return 1; fi
      POOLVIP=`ovs-agent-db dump_db server|grep pool_virtual_ip | cut -d':' -f2 | xargs| cut -d',' -f1`
      if [ -z "$POOLVIP" ]; then coloroutnl red "  No VIP listed in agent database"
      elif nc -z $POOLVIP 8899 >/dev/null 2>&1; then coloroutnl green "  VIP at $POOLVIP:8899 is reachable on the network"
      else coloroutnl red "  VIP at $POOLVIP:8899 is not reachable on the network"
      fi
      poolmnt=`mount | grep /poolfsmnt/ | cut -d' ' -f3`
      if [ -w $poolmnt ]; then coloroutnl green "  Pool filesystem is mounted and writeable" 
      else coloroutnl red "  Pool filesystem is not mounted or writeable"
      fi
    }

    function CheckOVSPeers() {
      local checkedports="7777 8002 8003 8899"
      colorout white "Pool Nodes responding on ports: $checkedports"
      clupeers=`grep ip_address /etc/ocfs2/cluster.conf| cut -d'=' -f2|xargs`
      if [ -z "$clupeers" ]; then coloroutnl yellow "  This node has no registered cluster peers"
      else
        count=0; ocfs2oops=""; netoops=""
        for i in $clupeers; do
          if (($((count%7)) == 0)); then echo; echo -n "  "; fi; count=$((count+1)) # 7 IP's per line
          pmsg=""; peeroops=""
          for p in $checkedports; do
            if ! nc -z -w1 $i $p 2>&1 >/dev/null; then 
              netoops="1"; peeroops="1";
              if [ -z "$pmsg" ]; then pmsg=":$p"; else pmsg="$pmsg,$p"; fi
            fi
          done
          if [ -z "$peeroops" ]; then colorout green "$i  "; else  colorout red "**$i$pmsg  "; fi        
        done
        echo
        if [ -n "$netoops" ]; then coloroutnl red "  Nodes with a \"**\" prefix did not respond on port(s) listed"; fi
      fi
    }
  
    function CheckRepoStorage() {
      coloroutnl white "OVS Repo Storage:"
      clupeers=`grep ip_address /etc/ocfs2/cluster.conf| cut -d'=' -f2|xargs`
      repos=`ovs-agent-db dump_db repository | grep mount_point| cut -d"'" -f4`
      repocount=0; error=""
      for i in $repos; do
        if ! mount|grep -q $i; then coloroutnl red "  Expected repo $i not mounted"; error=1
        elif ! [ -w $i ]; then  coloroutnl red "  Expected repo $i not writeable"; error=1 
        fi
        repocount=$((repocount+1))    
      done
      if [[ "$repocount" = "0" ]] && [[ -n "$clupeers" ]]; then
        coloroutnl red "  Cluster has peer nodes, but no repos are registered on this server"
        return 1
      fi
      if [ -z "$error" ]; then coloroutnl green "  $repocount expected repo(s) mounted and in a writeable state."; fi
      actrepos=`mount| grep /OVS/Repositories|wc -l`
      if [ "$repocount" = "$actrepos" ]; then coloroutnl green "  $actrepos mounted repo(s) matches $repocount registered in ovs-agent"
      else coloroutnl red "  $actrepos mounted repo(s) does not match $repocount expected in ovs-agent"
      fi
    }


    # Begin AnalyzeOVS
    if VerifyOp; then
      CheckOS
      CheckNetworking
      CheckDNS
      CheckNTP
      CheckServerEnvironment
      if [ "$MAJORRELEASE" = "3.3" ] || [ ""$MAJORRELEASE" = "3.4"" ]; then ovscon="9020,console 25,smtp"; else ovscon=""; fi
      CheckLocalServicePorts 22,sshd 111,portmap 8002,migrate 8003,migrate-ssl 
      CheckLocalServicePorts 8899,ovs-agent $ovscon
      if ! [ -f "/$OVSAGENT/db/server" ]; then 
        coloroutnl red "  /$OVSAGENT/db/server not found. System has either been damaged or needs a reboot after a clean operation"
      else
        CheckOVSEnvironment
        CheckClusterConfig
        CheckOVSPeers
        CheckRepoStorage
      fi
    fi
  }
  
  # AnalyzeOVMM
  # This format is available in /u01/app/oracle/ovm-manager-3/.config from 3.0.1 to 3.3.1 
  #   DBTYPE=MySQL DBHOST=localhost SID=ovs LSNR=49500 OVSSCHEMA=ovs APEX=8080 WLSADMIN=weblogic
  #   OVSADMIN=admin COREPORT=54321 UUID=0004fb000001000026778f17a0551bd8 BUILDID=3.3.1.1061

  function AnalyzeOVMM() {
  
    # Begin AnalyzeOVMM 
    CheckOS
    CheckNetworking
    CheckDNS
    CheckNTP
    coloroutnl white "OVMM and misc services:"
    local ovmmdb=""
    source $OVMMInfo
    if [ "$DBHOST" = "localhost" ]; then
      if [ $DBTYPE = "MySQL" ]; then ovmmdb="ovmm_mysql"; else ovmmdb="oracle"; fi
      if [ "$MAJORRELEASE" = "3.3" ] || [ ""$MAJORRELEASE" = "3.4"" ]; then cliport="10000,ovmm-cli"; else cliport=""; fi  
      localports="$LSNR,db-listen $cliport"
    fi
    PackedServiceStatus ovmm,red ovmcli,yellow $ovmmdb,red
    PackedServiceStatus network,red sshd,yellow crond,red iptables,yellow
    CheckLocalServicePorts $COREPORT,core-api 7002,ovmm-ui $localports
    coloroutnl white "OVMM Environment: ($OVMMInfo and $OVMMSys)"
    echo "  Oracle VM Manager $BUILDID"
    echo "  Manager UUID=$UUID"
    echo "  DB Type=$DBTYPE  DB Host=$DBHOST  DB Port=$LSNR"
    source $OVMMSys
    echo "  RUN_OVMM=$RUN_OVMM  USETLS1=$USETLS1  JVM_MAX_PERM=$JVM_MAX_PERM  JVM_MEMORY_MAX=$JVM_MEMORY_MAX"
    echo -n "  WLS Memory: "; /u01/app/oracle/java/bin/jps -lmv | grep weblogic.Server | cut -d' ' -f3,4,5
  }

  # Begin AnalyzeHost
  if [ -z "$ISSUPPORTED" ]; then KeyParameterScan
  else
    if VerifyOp; then
      AHEXIT="0" # Global error flag set by any red flag condition
      coloroutnl white "Host Analysis for $V3ROLE $RELEASEVER $BUILDID on `hostname`"
      case $V3ROLE in
        "OVS")  AnalyzeOVS ;;
        "OVMM") AnalyzeOVMM ;;
      esac
      coloroutnl white "Host Analysis completed. Errors:$AHERRORS  Warnings:$AHWARN were detected."; echo;
      if [ "$COMMAND" = "AnalyzeHost" ]; then echo "For a detailed console dump of host configuration data, run: $ARCTAG -D"; echo; fi
      return "$AHEXIT"
    fi
  fi
}

function DoV3Analyis() {
  if [ -n "$ISSUPPORTED" ]; then
    FS section "System Diagnostics" diags  
      FS group "Healthcheck" healthchk  
        #colortmp=$COLOROFF; COLOROFF="1"
        colortmp=$HTMLCON; HTMLCON="1"
        K; TO 60; FS cmd "VMPStat" "AnalyzeHost" vmpstat
        echo $OPDATA > $VMPDIAGS/misc/vmpstat
        HTMLCON=$colortmp
  fi
}

#The report filename prefix looks like "<short hostname>-<timestamp>-vmpscan-a". The suffix will be ".ok" if no flags were generated or ".fault-<exit code>, #if there's a problem.

function AHSnapshot() {
  if [ -n "$ISSUPPORTED" ]; then
    colortmp=$HTMLCON; HTMLCON=""; ABORTFA="0"; OPSTATUS="0"
    FS cmdq "AnalyzeHost"; GLOBALERROR=$OPSTATUS
    err=`echo "$OPDATA" | tail -n1 | cut -d':' -f2 | cut -d' ' -f1`  # can't pass this data back from the process oriented FAE
    warn=`echo "$OPDATA" | tail -n1 | cut -d':' -f3 | cut -d' ' -f1`
    suffix="E$err-W$warn"
    mkdir -p $VMPSNAPDIR
    echo "$OPDATA" > $VMPSNAPDIR/$SESSIONID-a.$suffix
    HTMLCON=$colortmp
  fi
}

function DumpHostData() { # Dumps a pure text summary of all the key OVS and OVMM 3 operating parameters to the console

  function DumpLinuxConfigData() {
    
    function DumpFile() { for i in $@; do echo "-->$i"; grep -v '^$\|^#' $i; echo; done; }

    # Begin DumpLinuxConfigData
    echo
    DumpFile /etc/oracle-release /etc/system-release /etc/resolv.conf /etc/hosts /etc/ntp.conf /etc/exports
    DumpFile /etc/fstab /etc/inittab /etc/sysctl.conf /etc/yum.conf
    echo "-->/etc/yum.repos.d"; ls -la /etc/yum.repos.d; echo
    if [ "$V3ROLE" = "OVS" ]; then
      DumpFile /etc/ovs-info /etc/ovs-release /etc/ovs-config /etc/ovm-consoled.conf /etc/ovs-agent/agent.ini
      DumpFile /etc/ocfs2/cluster.conf /etc/sysconfig/o2cb
    fi
    echo "-->/etc/ntp.conf"; grep -v '^$\|^#' /etc/ntp.conf; echo  #strip all the comments and blank lines
    DumpFile /etc/sysconfig/network
    DumpFile /etc/sysconfig/iptables 
    echo "-->ip addr"; ip addr; echo
    echo "-->ip route"; ip route; echo
    echo "-->brctl show"; brctl show; echo
    echo "-->Network Interfaces:"; echo
    for i in /etc/sysconfig/network-scripts/ifcfg-*; do echo "$i"; cat $i; echo; done
    echo "-->mount"; mount; echo
    echo "-->df -h"; df -h; echo
    echo "-->blkid"; blkid; echo
    echo "--> multipath -ll"; multipath -ll; echo
  }

  function DumpOVSData() {
    
    function DumpOVSDB() {
      echo;
      echo "# # # # # # # # # # # # # # #"
      echo "# Dump of ovs-agent $1 data"
      echo
      echo "-->/etc/ovs-agent/db/$1"
      if [ -f /etc/ovs-agent/db/$1 ]; then ovs-agent-db dump_db $1 
      else echo "File /etc/ovs-agent/db/$1 not found"; echo
      fi
    }
    
    function DumpXenData() {
      echo; echo "--> Xen Data"; echo
      echo "-->xm info"; xm info; echo
      echo "-->xm list"; xm list; echo
      echo "-->xentop -i1 -b"; xentop -i1 -b; echo
    }

    # Begin DumpOVSData
    echo "Key parameter dump from `hostname` $SESSTIME"; echo
    DumpLinuxConfigData
    DumpXenData
    DumpOVSDB server   
    DumpOVSDB repository
    DumpOVSDB exports
    DumpOVSDB aproc
    echo
  }
  
  function DumpOVMMData() {
    DumpLinuxConfigData
    DumpFile $OVMMInfo
    DumpFile $OVMMSys
  }

  # Begin DumpHostData
    if VerifyOp; then
      case $V3ROLE in
       "OVS")  DumpOVSData ;;
       "OVMM") DumpOVMMData ;;
      esac
    fi
}

function ServiceDump() { # Combines the -Ak and -D into a simultaneous dump to the console and file $SERVICEDUMPFN
  COLOROFF="1"
  { AnalyzeHost; echo; DumpHostData; } | tee -a $SERVICEDUMPFN
  echo
  coloroutnl white "Service Dump completed to file $SERVICEDUMPFN";
  echo
} 



# # # # # # # # # #
#
# ---> DoHostScan
#
# Main Function responsible for complete host scan operation
#

function DoHostScan() {
  Startup  

  FS scope "OS" os
    MachineTypeAndRole # os.role
    OSHardware         # os.hw
    OSConfiguration    # os.conf
    OSPerformance      # os.perf
    OSKernel           # os.kernel
    OSMemory           # os.mem
    OSSecurity         # os.security
    OSDevel            # os.devel
    OSUpdate           # os.update
    OSLogs             # os.logs

  FS scope "Network" net
    NetworkDevices             # net.dev
    NetworkConfiguration       # net.conf
    NetworkPerformance perf    # net.perf
    NetworkSecurity security   # net.security
    NodeTests                  # net.nodes

  FS scope "Storage" storage
    StorageDevices             # storage.dev
    StorageFilesystems         # storage.fs
    StorageOcfs2               # storage.ocfs2
    StorageAsmlib              # storage.asmlib
    StorageTest                # storage.test

if [ "$HOSTTYPE" = "$XENDOM0" ] || [ "$ROLE" = "$OVMSERVER" ] || [ "$ROLE" = "$OVMMANAGER" ] || [ "$V3ROLE" = "OVMM" ]; then
  FS scope "Virtualization" virt
    VirtXenInfo                # virt.dom0
    VirtOracleVMInfo           # virt.ovmserver || ovmmanager
    DoV3Analyis                # virt.diags
fi

  if [ "$APPSCAN" = "1" ]; then
  FS scope "Applications" apps
    Httpd
    MySQL
    SendMailPostfix
    SNMP
  fi

  if [ "$ORACLESCAN" = "1" ]; then
  FS scope "Products" prod
      OracleRDBMS
  fi

  GenerateSOSReport
  Shutdown
}

function KeyParameterScan() { # Scan and console output key subsystem failures: implements -k
  QUIET="1"; NODIALOGS="0"; JUSTHC="1"; ABORTFA=1
  DoHostScan
  GenerateHealthcheckReport
  DeleteWorkingDirectory
  exit $GLOBALERROR # Pass any internal errors to the calling process
}

function ExitHandler() { # handles control-c... attempts to clean up a partial scan
  local ddir=""
  echo; echo "Exit trap... cleaning up"
  for ddir in $STORAGETEST; do
    CheckRestrictedDirectories "$ddir" "STORAGETEST"
    if [ -f $ddir/$DTFN ]; then rm -f $ddir/$DTFN; fi
  done
  if [ -n "$LISTENERPID" ]; then kill -15 $LISTENERPID >/dev/null 2>&1; fi
  if [ -n "$SENDERPID" ]; then kill -15 $SENDERPID >/dev/null 2>&1; fi
  if ps aux|grep -v grep|grep "nc -vkl"; then
    kill -15 `ps aux|grep -v grep|grep "nc -vkl"|xargs|cut -d' ' -f2`
  fi
  DeleteWorkingDirectory
  echo "Done"; echo
  exit 1
}

function SetCommand() {
  local wrpath=${2:-""}
  if [ -z "$COMMAND" ]; then
    if [ -n "$wrpath" ]; then CheckRestrictedDirectories "$wrpath" "SetCommand $1"; fi # write path check
    COMMAND="$1"
  else
    echo; echo "$CONFMSG"
    echo "Only one command can be specified"
    echo "$COMMAND and $1 conflict"
    echo; exit 1
  fi
}

trap "ExitHandler" INT TERM

# Begin main program

# Get command line options
CMDLINE="$@"
STARTINGDIR=`pwd`
InitGlobalVars
InitializeVMPStat

while getopts ":AaB:b:Cc:DdE:eFf:g:hHi:I:j:kK:L:l:mM:N:nOopPqR:rSs:T:t:U:V:vwWX:x:z:Z5" opt; do
  case "$opt" in
    A)  SetCommand AnalyzeHost;; # Analyze and run single page diagnostics
    a)  SetCommand AHSnapshot;; # Write AnalyzeHost snapshot (-A) to $BASEDIR
    B)  DTSIZE="$OPTARG";;     # Data size for Blocksize storage test
    b)  BASEDIR="$OPTARG";;    # Destination for report archive
    C)  CLUSTERSYNC="1";;      # Prompt operator for start of Storage test
    c)  NTSIZE="$OPTARG";;     # Blocksize for network test 
    D)  SetCommand "DumpHostData";; # Dump OVM3 key parameters to the console
    d)  DEBUGGING="1";;        # Turns on detailed console debugging of testops
    E)  STARTDELAY="$OPTARG";; # Add a random startup delay for large clusters
    e)  APPSCAN=1;;            # Get info on installed apps like httpd, mysql...
    F)  PRINTCOMMENTS="1";;    # Enable Full comments listing from files
    f)  if ! [ -f "$OPTARG" ]; then echo; echo "config file not found:$OPTARG"; exit 1
        else source $OPTARG; CONFMSG="Using $OPTARG" # Get script defaults from a file
        fi;;                   
    g)  SOSREPORT="$OPTARG ";; # Get SOS report in addition to scan data
    H)  SetCommand "KeyParameterScan";; # Do healthcheck and dump to the console
    h)  Usage; exit 0;;        # Display help on the console
    I)  IDTAG="$OPTARG";;      # ID to identify the case or grouping for a cluster scan
    i)  DELAYINTERVAL="$OPTARG";; # Delay start of the scan by random(optarg) seconds
    j)  OVSPW="$OPTARG";;         # VM Manager pw for OVS DB dump: pw appears in report
    K)  KERNELFSDATA="$OPTARG";;  # /proc and /sys scan parameters
    k)  COLOROFF="1";;            # Disable onscreen ANSI colors
    L)  LOGLEVEL="$OPTARG";;      # Syslog detail level 0..5
    l)  LOGGING="$OPTARG";;       # Amount of logs to include in the report 0..8
    m)  SetCommand "ShowManPages";; # Show internal manual page menu
    M)  REPORTFORMAT="$OPTARG";;  # Specify report format CSS
    N)  NODES2TEST="$OPTARG";;    # Nodes to perform network test on
    n)  NETPROBE=0;;              # Disable some active network tests
    O)  ORACLESCAN=1;;            # Scan Oracle products, if plugins are available
    o)  NODIALOGS="1";;           # Skip prompts for non-root users and pre-check failures
    p)  SetCommand "PrintReadme" `pwd`;; # Write the README to disk
    P)  SetCommand "PrintAllReleaseDocs" `pwd`;; # Write the entire manual to disk
    q)  QUIET=1;;                 # Supress console output
    R)  REPORTOPTIONS="$OPTARG";; # Report options: T:text, H:html, X:xml, or D:sqlite3 db
    r)  LOGROTATE=1;;             # Rotate logs after scan... restart with clean slate
    s)  SERVERBASEPORT="$OPTARG";; # Base port and port +1 for net test send and listen
    S)  SetCommand "ServiceDump";;   # Combines -Ak and -D for a complete text dump to the console and $SERVICEDUMPFN
    T)  CMDTIMEOUT=$OPTARG;;       # Global timeout for commands before error generated
    t)  SetCommand "TestScriptExecute $OPTARG";; # Run a command line specified FA script
    U)  STORAGETEST="$OPTARG";;    # Paths for performing storage tests
    V)  PLUGINPATH="$OPTARG";;     # Path to find available vmp plugins
    v)  SetCommand "ShowVersion";; # Show version and description
    w)  WRITECONF="1";;            # Use defaults and any cli parms and write vmpscan.conf
    W)  WRITEDB="1";;              # Write Berkeley DB binary to report archive
    X)  EXCLUDES="$OPTARG";;       # Command paths and testops to exclude from the scan
    x)  EXTENDED="$OPTARG";;       # Run selected extended tests as a set via OPTARG
    z)  WRITETAGS="$OPTARGS"; > $ALLTAGS;; # Write tags for script documentation maint
    Z)  SetCommand "WriteSpecFile" `pwd`;; # Write rpm spec file for the script to disk
    5)  SetCommand "ShowScriptMD5";; # Computer script md5
    \?) Usage "Error: $0 $*\n\n"; exit 0;;
    * ) Usage "Error: $0 $*\n\n"; exit 1;;
  esac
done
shift $(($OPTIND - 1))

if [ -n "$WRITECONF" ]; then WriteVMPScanConf; exit 0; fi
if [ -z "$COMMAND" ]; then COMMAND="DoHostScan"; fi # default operation
logit 1 "Start:$COMMAND"
$COMMAND # Run the selected command
logit 1 "End:$COMMAND:Elapsed=$ELAPSEDTIME seconds"
cd $STARTINGDIR  # Restore original working directory
exit $GLOBALERROR # Pass any internal errors to the calling process

# ---> End main program <---
#
# All documentation and supplementary data files are in the tagged sections
# below. It is retrieved by the GetTagData function for insertion into the
# reports, dumped to the console or written to disk. The format is:
#
# <section.tag>
# Fixit text, man pages or script data
# </section.tag>
# 
# Fixit hints section: See the man page on fixits for more information
#
<fixit.hints>
<net.conf.ping_hostname>
Please review the format of /etc/hosts. The assigned hostname for this
system is returning 127.0.0.1. This is ok for dhcp, but not for a static
IP assignment. The entries in /etc/hosts should look like this:

127.0.0.1 localhost.localdomain localhost
10.1.2.3  test1.oracle.com test1
</net.conf.ping_hostname>

<net.conf.settings.malformed_hosts>
Please review the format of /etc/hosts. The assigned hostname for this
system is returning 127.0.0.1. This is ok for dhcp, but not for a static
IP assignment. The entries in /etc/hosts should look like this:

127.0.0.1 localhost.localdomain localhost
10.1.2.3  test1.oracle.com test1
</net.conf.settings.malformed_hosts>

<net.conf.settings.ping_hostname>
Inability to ping the hostname generally means that there is an error in /etc/hosts
where the hostname is out of sync with the specified hostname in /etc/sysconfig/network.
</net.conf.settings.ping_hostname>

<net.perf.connectivity.arpinggw>
No layer 2 network connectivity: Cannot arping default gateway. This is
normal if the default gateway is not on your subnet as with a VPN. If your
gateway should be reachable at layer 2, please check your wiring and
network configuration.
</net.perf.connectivity.arpinggw>

<net.perf.connectivity.pinggw>
No layer 3 network connectivity: Cannot ping default gateway.
Please check your gateway router or firewall configuration.
</net.perf.connectivity.pinggw>

<net.conf.dns>
Please check /etc/resolv.conf and insure that there are two active
DNS servers listed in the following format:

domain yourdomain.com
nameserver 10.0.0.1
nameserver 10.0.1.1
search yourdomain.com

These servers must be reachable on the network and where all hostnames and
IP's should be resolvable with forward and reverse lookups.
</net.conf.dns>
<net.conf.dns.lookupgwip>
Forward and reverse DNS lookups on the machine hostname and default gw ip failed.
DNS is not available or not configured correctly on this machine and no further
DNS tests can be performed. 
</net.conf.dns.lookupgwip>

<net.security.kernel>
The "should be" kernel network security settings in this test group are not
needed in all cases. The warning should be reviewed in the context of the
services being provided and this machine's network environment.
</net.security.kernel>

<net.dev.conf.fullduplex>
If this is an active interface, it is not operating in full duplex mode which
can seriously impact performance. Please check the nic configuration.
</net.dev.conf.fullduplex>

<net.dev.conf.linkactive>
This interface is not detecting a layer 1 network link and is inoperative. If it
is intended to be active, please check its cabling and switch port.
</net.dev.conf.linkactive>

<net.conf.ntp.ntp_redundancy>
Three active ntp servers are recommended to conform with general deployment
best practices. This is especially important on cluster filesystems and VM pools.
One can be used if it is reliable. Even numbers of servers are not recommended.

NTP servers can be configured in /etc/ntp.conf. If the system has never been ntp
synchronized, do the following steps to enable and initialize it:

service ntpd stop
chkconfig ntpd on
ntpdate < IP of one of the active ntp servers >
service ntpd start 
</net.conf.ntp.ntp_redundancy>

<storage.dev.mpath.multipathd_enabled>
If your san has been configured with redundant paths and you want to use
device-mapper-multipath, please enable the service to start at boot with:

chkconfig multipathd on
service multipathd start 
</storage.dev.mpath.multipathd_enabled>

</fixit.hints>

# Man Pages Section

<man.readme>
* * * * * * * * * * * * *
* VMPScan System Information Utility: Version <!--#scriptverrev-->
* Author: Tom Lisjac <tom.lisjac>
* Copyright (c) 2010, 2018, Oracle and/or its affiliates. All rights reserved.
* License: GPL2 - See vmpscan.sh header and LICENSE for more information
*

---> Quick Start: Overview

  VMPScan is a cluster aware, diagnostic script that will run basic health
  checks and gather detailed, addressable system information from an Oracle VM
  Server, Manager or generic Enterprise Linux 4, 5 or 6 system. Html, text, xml
  and sqlite3 database reports can be generated and merged with data from other
  nodes to provide a cluster oriented report.
  
---> Quick Start: Responding to an Information Request

  VMPScan is frequently used for remote support issues. If you are responding
  to a request to run the script and upload the report archive to an analyst,
  here are the 4 steps:

    1. Install VMPScan on all requested nodes:
         # tar -xzf vmpscan-(the version).tar.gz or
         # rpm -ivh vmpscan-(the version).noarch.rpm
    2. Run it on all requested nodes:
         # ./vmpscan.sh  in the directory where the tar.gz was unzipped
         # vmpscan  if the rpm was installed.
       Please include any requested command line parameters or place a provided
       vmpscan.conf in /etc, the directory where VMPScan was installed or use
       the -f /path/filename command line parameter to point to it.
    3. Collect the report archive(s): The full path/filename of the archive
       tar.gz location is shown when the script completes. Default: /tmp/vmpscan
    4. Send the archive(s) to the remote analyst for review. If there are
       multiple nodes, tar or zip all the individual archives into a single
       compressed file with the date as part of the archive filename.

---> Quick Start: Analysis Options

    - Optionally expand and review the report by running merge.sh in the
       directory with all the report archives. When linking is complete, use a
       browser to open index.htm that was created by the merge.sh script.
    - When finished with the review, recover space by running clean.sh which
       will update the archives and delete the expanded directories.
    - VMPScan does not need to be installed on the system doing the analysis but
      the merge process is only supported on Linux systems at this time.

   Please run vmpscan.sh -m for console access to the built-in manual pages or
   -P to write them to disk. Details for most commands can be found in the
   "Examples" section. For a list of all command line options, run: vmpscan -h.


---> More Details:

  1. Installing the Script

   - vmpscan.sh is a self contained script that is written entirely in bash.
     After installing, the file can be moved and run from any other location.

   - If installed from a tar.gz, make sure the script has execute permissions:

     # chmod 755 vmpscan.sh
  
   - The rpm install creates a vmpscan symlink to vmpscan.sh and places both in
     the system path /usr/bin. The remainder or this document will assume the
     rpm is installed and call the vmpscan symlink.
  
   - If vmpscan.sh is moved to another system path, check that it reports the
     same version as the package it was provided with to insure there isn't
     another version in another path:
    
       $ vmpscan -v | grep Version
       VMPScan - Version <!--#scriptverrev-->

  2. Doing a Single Node Scan

   - The script defaults to full scan mode:
  
     # vmpscan

     Command line parameters can be provided. The script also looks for a
     command options file called vmpscan.conf in /etc or the current directory.
     The -f /path/vmpscan.conf allows the file to be explicitly pointed to.
    
   - Add a -i 500ms or greater test spacing delay for load reduction on busy
     systems. This is automatically done if VMPScan detects a busy machine:

     # vmpscan -i 500

   - The script may be run non-root, but will not provide root only info in the
     report. Permissions errors may also be displayed, but these will not affect
     the rest of the scan.

   - Errors and warnings will be flagged to the console in yellow and red during
     the scan. The onscreen healthcheck report will flag any critical subsystem
     failures at the end. A quick healthcheck can be run with the -k option.
    
   - By default, the report archive will be placed in /tmp/vmpscan. VMPScan
     outputs the path and filename when the script completes. The archive
     destination can be changed with the -b <path> command line option.

  3. Doing a Cluster Scan

   - If this is a multi-node cluster, run the script on each node. You can
     redirect the archive output to a directory on shared storage with a -b 
     command so the archives for all nodes will be written to one location:
     
      # mkdir -p /OVS/vmpscan
      # vmpscan -b /OVS/vmpscan

   - Collect the archives from all nodes and put them all in a named and dated
     directory such as:
  
      # mkdir mycluster-2011-03-22
      <copy all node archives to this directory>

   -  If responding to an information request, tar and upload the archive:

      tar -czf mycluster-2011-03-22.tar.gz mycluster-2011-03-22

  4. Merging and Reviewing Report Data
      
   -  To review the cluster data, run the following sequence of commands in the
      directory where all the node archives have been placed. The merge.sh
      script is created by VMPScan during it's scan. If merge.sh is missing,
      untarring one of the report archives will create it:

      # cd < root report directory where all the node archives are located >
      # ./merge.sh

      Adding a -b skips the y/n prompt. All node archives are untarred into
      individual directories and linked into a clusterview html page in the root
      report directory. Open the Clusterview report portal in a browser:

      # firefox index.htm

      Run merge.sh -h for additional options 

  5. Interpreting the Reports

      There will be two navigation tables at the top of the Clusterview portal.
      The first table links to the report details for each individual node.
      The second table contains key parameter links that have been merged so
      each node's value is grouped with the other nodes for side by side
      comparison and cluster symmetry verification.

   -  Each "testop" has a unique "path" or id called a "tag", such as:

     "node12.net.conf.gateway.default_gw"

      The hostname "node12" makes the tag unique in a cluster. The "net" is the
      "scope", "conf" is the "section" and "gateway" is the test "group". Links
      in the reports are presented hierarchically and these components can be
      clicked separately to jump between sections of the report. In the above
      example, default_gw can be right clicked and the full link pasted into an
      email or chat to enhance collaboration.

   -  Supplementary data can be added to the node reports. Pre-defined
      directories are available for OSW, RDA, SOS and other diagnostic tool
      outputs. An SOS report can be automatically captured with the -g switch.

  6. Suspending and Resuming an Analysis

   -  When the analysis phase is completed or paused, the report archives can be
      updated with any data that was added to the node directories and disk space
      from the expanded directories recovered by running the clean.sh command:

      # ./clean.sh
     
      The clusterview and node report archives can be re-generated and the
      analysis resumed at any time by running the merge.sh command again.
      Run clean.sh -h for additional options.  

   -  See the manual pages "VMPScan_Reports" and "Managing_Data" for more
      information on the review and analysis process. The "Examples" manual page
      provides example of most of the available command line options.

  7. Quick System Healthcheck

   -  A Quick Healthcheck Scan can be performed to generate an on-screen report
      that is useful for new installation and basic system verification:

       vmpscan -k

      This mode is fast, but does not generate a report archive. It is normally
      used to insure that basic OS configuration, networking and storage are
      operational and conform to best practices.

  8. Bypassing Command Hangs

   - When the system being scanned is in a corrupted or hung state, some VMPScan
     commands that query storage, network or product functions may also hang.
     These tests can be identified by adding the -d switch to the command line.
     This will list the tag for each test prior to executing it:

     # vmpscan -d

     Commands will execute normally until the one that hangs:

     -->Optag:storage.dev.vols.df_-h  -  Status: Executed
     1:cmd  2:df -h  3:df -h  4:df_-h

     <hung due to stale nfs mount or unavailable san>   

     When the hanging command has been identified, it can be excluded with
     the -X parameter:

     # vmpscan -X "storage.dev.vols.df_-h"

     On the next scan pass, this command will show:

     -->Optag:storage.dev.vols.df_-h  -  Status: Skipped
     1:cmd  2:df -h  3:df -h  4:df_-h

     Other commands may also be affected by the same condition, so this is an
     iterative (and sometimes tedious) process. Entire test groups, sections or
     scopes can be excluded to isolate the problem areas more quickly:

     # vmpscan -X "storage.dev"

     Sometimes data gathering from the Kernel's /proc and /sys filesystems can
     also hang the script. The defaults were chosen for maximum safety, but all
     information gathering from these directories can be disabled with: -K ""
     
</man.readme>
<man.overview>

---> VMPScan Overview

  VMPScan is a cluster aware, diagnostic script that will run basic health
  checks and gather detailed, addressable system information from an Oracle VM
  Server, Manager or generic Enterprise Linux 4, 5 or 6 system. A single archive
  is created that contains the scan data along with linking information that can
  be merged with other host archives to produce a cluster oriented report. Html,
  text, xml and sqlite3 database reports can be optionally generated to support
  both manual and automated fault analysis. The basic sequence of operation is:

   vmpscan.sh < command line options >
   cd /tmp/vmpscan
   ./merge.sh
   firefox index.htm
   < Do review and analysis >
   ./clean.sh

  When run without options, VMPScan places the report archive in the default
  /tmp/vmpscan directory and will display the report archive path and filename
  at the end of the scan. These archives can then be sent to a remote analyst,
  transferred to a local workstation for review or both.

---> Report merging and analysis

  During the scan, a merge.sh script is also created in the report directory to
  unpack and link the node report archives. Running it will decompress any
  number of archives it finds and generate individual host and merged, cluster
  oriented html and sqlite3 reports. The "Clusterview Portal" index.htm page and
  database can then be reviewed in a web browser or with a sql analysis tool.

  The Clusterview page contains links to all the individual node reports that
  were found in the report directory during the merge process. It also contains
  a combined list of key OS parameters for each node that are usually reviewed
  first when checking the health of a Linux system. These key parameters are
  grouped together on the page so value correctness and configuration symmetry
  can be quickly verified across clusters of any size.

---> Cleaning up and recovering disk space

  When the analysis is complete or paused, clean.sh (from merge.sh) can be run
  to update each node's report archives and then delete the expanded directories
  to recover disk space. To resume the analysis, run the merge.sh script again.

---> Extensible architecture

  VMPScan's fault detection architecture is generalized and can be extended to
  provide coverage for additional test scenarios and products using vmp plugins. 
  See the manual page "Writing_VMPScan_Plugins" for more information.

</man.overview>

<man.version>

  VMPScan is a cluster aware, diagnostic script that will run basic health
  checks and gather detailed, addressable system information from an Oracle VM
  Server, Manager or generic Enterprise Linux 4, 5 or 6 system. A single archive
  is created that contains the scan data along with linking information that can
  be merged with other host archives to produce a cluster oriented report. Html,
  text, xml and sqlite3 database reports can be optionally generated to support
  both manual and automated fault analysis. Run vmpscan.sh -m for man pages.

 Copyright (c) 2010, 2018, Oracle and/or its affiliates. All rights reserved.
  License: GPL2
  This is free software; see the source for copying conditions.  There is NO
  warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See vmpscan.sh header and included LICENSE file for more information.

  Please send problem reports, suggestions and patches to the current maintainer
  with the subject line "VMPScan comment"

</man.version>

<man.usage>

  VMPScan is a cluster aware, diagnostic script that will run basic health
  checks and gather detailed, addressable system information from an Oracle VM
  Server, Manager or generic Enterprise Linux 4, 5 or 6 system. A single archive
  is created that contains the scan data along with linking information that can
  be merged with other host archives to produce a cluster oriented report.

  Version <!--#scriptverrev--> usage: vmpscan [OPTION]

  Options:

    -A          Analyze and perform diagnostic test to determine host state
    -B <size>   Set storage block test (-S) transfer size in Kbytes. Default 16384K
    -b <path>   Change absolute destination path for report data archive. Default: /tmp/vmpscan
    -C          Prompt for start of Storage and net node tests... use for syncing on clusters
    -c <size>   Client-server-node block transfer size in Kbytes. Default 16384K
    -D          Dump static system configuration data to the console
    -d          Dump testop debugging info to the console during the scan: Default: disabled
    -E <secs>   Execute delayed startup by random seconds up to <secs>. Default: 0
    -e          Enable app info/plugins for the report: http, smtp, mysql, postfix. Default: no
    -F          Print all comments from configuration files: Default: strip all comments
    -f <file>   Path/file to vmpscan conf. Order: internal, ./vmpscan.conf or /etc/vmpscan.conf
    -g <args>   Generate SOS report if installed. Use "" for required args if none desired
    -H          Do fast scan of key healthcheck parameters and display to console
    -h          Display this help usage message
    -I <tag>    Case number, cluster name or comments for grouping scan reports
    -i <msecs>  Optional delay between tests (in ms) to reduce host loading. Default: 50 ms
    -j <db pw>  Password for VM Manager DB dump: appears in report; Will prompt if not provided
    -K <paths>  Get Kernel data from /sys /proc. Specify paths, proc "pids", "files" or "all"
    -k          Disable onscreen ANSI colors        
    -L <0..5>   Syslog logging level: 0 almost none... 5 verbose. Default: 1
    -l <0..8>   Gather system data and logs. Default: 2 (messages* and dmesg)
    -M <format> Select customized CSS for html report format: 1=hi contrast          
    -m          Display built-in manual pages... detailed instructions for using VMPScan
    -N <nodes>  Client-server-node network test: -N "node1 node2 node3..."; -c sets block size
    -n          Disable some network tests: Default: do all network tests
    -O          Enable Oracle Product plugins for the report. Default: no
    -o          Omit the dialog for non-root users and precheck fails. Default: always prompt
    -p          Write quick start/readme to the current directory as README-vmpscan.txt
    -P          Write all release documentation to the current directory
    -q          Disable console progress notification: Default: verbose
    -R <list>   Set Report option set: -R HTXD; H=html; T=text; X=XML; D=Database; Default: HT
    -r          Rotate system logs after capture. Default: do not rotate
    -S          Service dump of -Ak and -D diagnostic data to the console and a file
    -s <port>   Server port base for network node test. Default: 5949 and 5950. Used with -N
    -T <secs>   Change global command timeout value. Default: 20 seconds
    -t <file>   Test script execution. Script must contain a callable "vmptest" bash function
    -U <list>   Storage block r/w test: -S "/path1 /path2 /path3". Use with -B to set xfr size
    -V <path>   VMPScan plugin path: where to find and pull in .vmp plugin extensions
    -v          Display version and description information
    -X <"tags"> Exclude a particular testop, group, section or scope from the scan
    -x <list>   Extended tests. Default v:lvm; r:raid; o:ovm; g:gecos; s:security; l:lsof; n:net
    -w          Write vmpscan.conf to current directory passing any command line parameters
    -W          Write Berkeley DB to archive. WARNING: Contains ovs-root passwords Default: no
    -z <level>  Script maintenance: 1 writes active tags; 2 all tags to reportdir/alltags.txt
    -Z          Script maintenance: Write RPM spec file + changelog to current directory
    -5          Script maintenance: print md5sum for script body to the console

  Please run vmpscan -m to access the full manual pages for more information.
  Details for most command options can be found in the "Examples" section. 

</man.usage>
<man.mergeandclean>

  Merging node archive data

  As part of the scan process, VMPScan creates a "merge.sh" script in the report's
  root directory. This script is archived with the report data and also left
  uncompressed in the report root. The merge.sh script is used to:

    1. Verify any archives it finds in the directory where it is executed
    2. Expand the report archive
    3. Recurse into the report directories and expand any additional archives it finds 
    4. Creates a Hostview navigation table for each report host
    5. Merges the hostview and key navigation tables into the ClusterView portal page
    6. Merges the individual vmpscan.sqlite node databases into vmpmerge.sqlite
    7. Writes a clean.sh script to the current directory

  The command usage can be displayed with ./merge.sh -h:

    merge.sh [options]

    Expands any VMPScan report archives found in the same directory and merges
    data from the individual nodes into a Clusterview portal. See the VMPScan 
    manual pages (vmpscan.sh -m) for more information about this process. 

    Options:

      -a  Merge all keys... takes a long time but includes every node parameter in the Clusterview
      -b  Skips y/n dialog after archives are listed
      -d  Merge database only: skips html report creation and deletes report directories
      -h  This help display
      -i  Ignore version mismatch errors
      -k  Only merges selected keys that are commonly referenced (default)
      -m <db file list> Merge vmpmerge.sqlite with one or more other vmpscan.sqlite db's
      -p  Do not change permissions of report files and directories to 755
      -s  Skip looking for new archives to expand... regenerate the clusterview
      -t  Table name for merged database... defaults to vmpmerge
      -q  Be quieter... suppresses most of the verbose progress indicators
      -x  Export database as sql dump after the merge... file is index.sql

  If a report archive cluster set is provided without a merge.sh, untarring one
  of the report archives will re-create it. By default, merging also changes the
  permissions of the report files and directories to 755 so they can be read by
  non-root users such as a webserver. If this is not acceptable from a security
  perspective, use the -p option.

  Cleaning up

  The clean.sh script is created by running merge.sh. Its purpose is to remove
  the expanded report directories to recover space. By default, clean.sh saves
  the directories back to their original archive names which will preserve any
  data that was manually added to the report archive. The clean.sh script then
  erases itself leaving only the merge.sh script in the report root directory
  to re-expand the archives when needed.

  The command usage can be displayed with ./clean.sh -h:

  clean.sh [options]

  Cleanup and recover expanded report directory space for idle analysis sessions.
  This process will leave the report archives and merge.sh in place so the session
  can be resumed at a later time by running merge.sh again. See the VMPScan manual
  pages (vmpscan.sh -m) for more information about this process.

  Options:

     -b  Skips y/n dialog after report directories are listed for deletion
     -h  This help display
     -s  Save any changes to the archive before deleting report directory (default)
     -n  Delete report directories... do not check integrity or save changes to the archives
     -d  Clean but do not delete merged vmpmerge.sqlite database
     -q  Be quieter... suppress most normal messages

<man.mergeandclean>
<man.examples>

 - Default full scan mode. Report is saved to /tmp/vmpscan:

    ./vmpscan.sh (or just vmpscan if installed from the rpm)

 - Display the built-in manual page menu:

    ./vmpscan.sh -m

   Write the release documentation to the current directory. This includes:
   MANUAL-vmpscan.txt and README-vmpscan.txt:

    ./vmpscan.sh -P

 - Write a parameterized copy of vmpscan.conf can also be generated that
   reflects any included command line parameters with the -w option:

    ./vmpscan.sh -g "" -b /OVS/vmpscan -T 120 -w
  
   This will generate a complete vmpscan.conf in the current directory with the
   following defaults modified per the command line parameters:

    BASEDIR="/OVS/vmpscan"
    SOSREPORT=" "
    CMDTIMEOUT="120"

 -  Do a quick healthcheck of the key system parameters. Verifies dns, ntp and a
    variety of other essential parameters. Outputs results to the console... no
    report archive is generated:

     ./vmpscan.sh -k

 - Run a VMPScan full scan and place the report archive in a specified directory.
   This is useful for accumulating all the report archives for a cluster in a
   single, shared directory. A full, absolute path is required:

    ./vmpscan.sh -b /OVS/vmpscan

 - On a busy production system, add a 500 millisecond delay between each test to
   reduce host loading. The default time is 50 milliseconds. The default is
   automatically extended by 700 milliseconds if the VMPScan host precheck
   determines that the machine is busy. The following will change the default to
   500 milliseconds between each test:

    ./vmpscan.sh -i 500

 - For additional cluster load balancing where commands are being pushed from cssh
   or ssh keyed scripts, the startup time of VMPScan can be delayed by a random
   window. The following will delay the start of the scan operation within a 300
   second period. This prevents large numbers of VMPScan instances from starting
   simultaneously across large and busy clusters.

    ./vmpscan.sh -D 300

   If a startup delay -D was specified along with the -C clustersync option that
   will halt the script for manually started tests, the startup delay will be
   executed again afterward in an attempt to space the shared resource requests
   between nodes.

 - In some situations, particular tests may cause issues or hangs if the underlying
   infrastructure is having problems. These tests can be excluded at the scope,
   section, group or testop level with the -X option. The following will exclude
   all the tests in the storage.dev.lvm group and the specific testop called numastat:

    ./vmpscan.sh -X "storage.dev.lvm mem.numa.numastat"

 - If VMPScan hangs on a particular test due to a problem on the machine, run the
   script again with a -d switch that will show each test name just before it
   executes. You can use the -X command to exclude this test on the next run.

 - All VMPScan commands are measured in time and have timeout values. The default
   timeout for all commands is 20 seconds and an error will be flagged if this period
   is exceeded. To change the global default value to one minute, use the -T option:

    ./vmpscan.sh -T 60

   Add an sosreport to the VMPScan report archive, if the sos package is installed:

    ./vmpscan.sh -g ""

   Parameters are mandatory, so use the "" to escape the command line if none are
   desired. Parameters can also be provided by adding an SOSREPORT="the options"
   to vmpscan.conf. Parameters are version dependent:

    SOSREPORT="--diagnose --analyze --report --batch --build"

   To enable the sos report in vmpscan.conf with no additional parameters, use a
   blank: SOSREPORT=" "

 - Do a simple storage test on the /OVS and /tmp partitions from all nodes in a cluster:

    ./vmpscan.sh -S "/OVS /tmp" -B 32768 -C

   The -B sets the total transfer size in K and -C will pause and wait for the
   admin to hit enter before starting the test. This allows it to be started
   sequentially or simultaneously on all nodes using cssh or pconsole.

 - Do a simple client/server network performance test on a cluster:

    ./vmpscan.sh -N "server1 server1 server2... "

   The scan will run normally, but pause at the start of the network test after a
   listener process has been created. Let all the nodes reach this point, then
   trigger the transmit (TX) test one node at a time. There is another prompt after
   the TX test completes. Please leave the node at the prompt until all the cluster
   peers have completed their TX tests. At that point all the nodes can be triggered
   to continue the regular scan. The -c and -s switches can be used to change the
   test blocksize and server listening port.

 - VMPScan can write to /var/log/messages in detail levels from 1 to 5. A value of
   0 turns off most logging... 5 provides logging of each test. This is particularly
   useful for storage and network related tests where the start of a VMPScan
   operation may trigger useful diagnostic information from other OS components:

    ./vmpscan.sh -L 5 -S "/OVS" -B 32768

 - VMPScan will prompt when being run as non-root and when any of the host prechecks
   for memory, I/O busy or disk space fail. With caution, these prompts can be
   disabled with the -o switch:

    ./vmpscan.sh -o

 - VMPScan supports modular development of test operations and plugin extensions.
   Use the -t switch to point to a file with the extensions .vmp that contains
   two functions: vmptest and vmpplugin. The vmptest function is a test stub
   that calls vmpplugin. The vmpplugin function is called directly from vmpscan
   when the filename.vmp matches a scope, section or group. Using this mechanism,
   FAE instructions and other bash support code can be executed without having
   to run an entire machine scan:

    ./vmpscan.sh -t storage.vmp

   See the manual page "Writing_VMPScan_Plugins" for more information.

 - There are currently 4 report format options available: html, text, xml and db.
   All or none can be selected as a set with the -R switch and a corresponding
   h, t, x or d parameter. The following would select the html and sqlite3
   database reports while disabling text and xml outputs:

    ./vmpscan.sh -R hd

 - To collect data from the /proc and /sys kernel filesystems, use the -K option
   and specify the paths:

    ./vmpscan.sh -K "/sys/devices /sys/class /proc/net /proc/scsi"

   To capture the /proc/[0-9]* pid snapshot use the "pids" as a -K argument. To
   capture all possible data from both /sys and /proc, use "all". Using the
   argument "files" will capture the root files from /proc.

 - To run extended test options, use the -x "extended command list":

    ./vmpscan.sh -x vsln # runs lvm, os security, lsof and extra network tests

   Possible options are: v:lvm; r:software raid o:ovm; g:gecos; s:os security
   l:lsof; n:network. Like the -R switch, these options are a set and can be
   listed in any case or order. Enclose the arguments in "" if the options are
   separated by blanks. Default is v to run LVM pvs, vgs and lvs commands.

 - For dumping the VM Manager database, the -j <pw> command line option can be
   used to provide the ovs user password. This password will appear in the ps
   dumps in the report. If the password is sensitive, don't use -j and wait for
   the db dump testop to prompt for it during the scan.

</man.examples>

<man.healthcheck>

  The VMPScan quick healthcheck scan will flag critical subsystem errors and
  display them on the console. No report archive is produced. Running this
  check on new nodes is always recommended as a post-installation procedure:

  Starting vmpscan healthcheck scan of node12: Oracle VM server release 2.2.1 (Xen_Dom0)
    Running as root  Errors will be displayed

  os: ---------------------------------------------------+--1-2-+-----+--------------+-       
  +--------------------------------------
  net: -------------3-+-+-+--+--+-+-+-+-4---5-6------
  storage: ----------------------------------+----------------------
  virt: 
  apps: ---------------
  prod: -

  1: Ping ntp server 1 - os.time.ntp.ping_ntp1
      - Ntp server 10.0.0.50 does not ping

  2: ntp server redundancy - os.time.ntp.ntp_redundancy
      - Insufficient pingable ntp servers found: 0

  3: /etc/hosts format - net.conf.settings.ping_hostname
      - Cannot locally ping specified hostname "ws1.private.network"

  4: DNS lookup hostname - net.conf.dns.hostname_ip
      - The machine ws1.private.network does not resolve in dns

  5: ARPing default gateway - net.perf.connectivity.arpinggw
      - Default gateway is not reachable at layer 2. May be ok... please check

  6: Ping default gateway 10.0.0.50 - net.perf.connectivity.pinggw
      - Default gateway doesn't ping

  ---------------------------------------------------

  A "+" indicates a healthcheck test that passed. A number is a failure. Dashes
  represent non-critical tests that were skipped. If there are errors, running a
  full VMPScan is recommended where a detailed report with additional
  recommendations will be available.
</man.healthcheck>

<man.fullscan>

  A full VMPScan is done by default and produces a console progress output,
  onscreen subsystem healthcheck report and a detailed report archive with full
  system details. The following is an example run:

  **************
  VMPScan System Information Utility: March 22, 2011 - Version 2.2

  Starting vmpscan of rmvdc1: Oracle VM server release 2.2.1 (Xen_Dom0)
  Running with 50 ms of delay between tests

  Data will be saved in: /tmp/vmpscan/rmvdc1-2011-03-22-221954-vmpscan

  ==> Scope: OS - <rmvdc1.os>
      * Machine role - <rmvdc1.os.role>
          - Xen and Virtualization Products---- 0.294s ok:4
      * Machine hardware - <rmvdc1.os.hw>
          - Hardware, CPU and PCI information-- 0.582s ok:6
      * OS info - <rmvdc1.os.conf>
          - Boot------------------------------- 0.172s ok:2
          - Configuration---------------------- 0.641s ok:9
          - OS Services------------------------ 0.932s ok:8 w:1 e:1
          <... rest of the scan    >
  **************

  The display shows the hierarchical scopes, sections and groups. After the
  group tag is the amount of group elapsed time tests that completed without
  error (ok:), errors (e:) and warnings (w:) that were detected in tests within
  the group. The end of the scan shows:
          
  ==> Scope: Products - <rmvdc1.prod>
      * Oracle-RDBMS - <rmvdc1.prod.Oracle>
          - Configuration

  -------- Critical Subsystem Healthcheck -----------

  No major subsystem errors were found by this scan

  ---------------------------------------------------

  FAE ops: 302 ---> 296 ok  2 warnings  4 errors
  Elapsed time: 69 seconds

  Archive of all data is here: /tmp/vmpscan/rmvdc1-2011-03-22-221954-vmpscan.tar.gz

  **************

  Any subsystem health checks that were detected are flagged at the end of the
  scan. In this case there were none. FAE ops is the total number of tests that
  were performed along with the errors, warnings and total elapsed time for the
  scan operation. The compressed archive of all the data has been placed in
  /tmp/vmpscan along with a merge.sh script that can be used to expand it and any
  other -vmpscan.tar.gz archives that are present there. The merge.sh script is
  packaged with all VMPScan archives and can be generated by decompressing any
  node archive.

  </man.fullscan>

<man.manage>

---> Merging Single Node Reports

  VMPScan creates a timestamped directory during during it's full scan where it
  places all the information that was obtained from the host system. It also
  creates linkage files that are used to create the clusterview portal page when
  merging with other scanned hosts. After a scan has completed, the /tmp/vmpscan
  directory looks like this:

    sysadmin1@ws2:/tmp/vmpscan $ ls
      merge.sh  node12-2011-03-22-231810-vmpscan.tar.gz

  Running the merge.sh script will decompress the single archive and re-create the
  working directory. It will also create a "portal page" in /tmp/vmpscan/index.htm:

    sysadmin1@ws2:/tmp/vmpscan $ ./merge.sh -b
      VMPScan archive merge utility - March 22, 2011 - Version 2.2

      Found new: node12-2011-03-22-231810-vmpscan.tar.gz

      Ready to process and merge all archives and existing directories

      Note: Clusterview report will contain only KEY node data parameters
      To merge ALL node data, abort and run merge.sh with the -a switch: ./merge.sh -a
      This process can take several minutes per node

      Expanding report archives for node12-2011-03-22-231810-vmpscan: ok
      Creating HostView for: node12-2011-03-22-231810 ok
      Creating Clusterview Portal
      ++Merging net keys.............. ok: 14 keys
      ++Merging os keys...................... ok: 22 keys
      ++Merging storage keys............. ok: 13 keys

      Done: Open index.htm in a browser to view the report

  The -b option runs the script in batch mode skipping the y/n "are you sure"
  dialog. The directory now shows the expanded working directory along with an
  additional clean.sh and the index.htm portal page:

    sysadmin@ws2:/tmp/vmpscan $ ls -1
      clean.sh
      index.htm
      merge.sh
      node12-2011-03-22-231810-vmpscan
      node12-2011-03-22-231810-vmpscan.tar.gz

---> Analysis Phase

  Bringing index.htm up in a browser such as firefox or a text version like elinks
  will show the portal page report. See "VMPScan Reports" on other merge.sh options
  and for more information on reviewing this data from an analyst perspective.
  
  The following is an explanation of the files and directories that are
  contained in the expanded report directory. All of these files and directories
  are linked from the individual hostview reports:

  sysadmin@ws2:/tmp/vmpscan $ cd node12-2011-03-22-231810-vmpscan; ls -1

    archives        - Compressed archives are stored here for etc,var,proc and sos data
    proc            - Contains a subset of the node's /proc root directory (see -K)
    sys             - Contains a subset of the node's /sys root directory (see -K)
    etc             - Contains a subset or the entire /etc/directory (set by log level -l)
    var             - Contains a subset or the entire /var/log,lib (set by log level -l)
    misc            - Directory where large outputs are written and linked from the report
    osw             - Empty directory to deposit related OS Watcher archives
    rda             - Empty directory for RDA data
    sos             - Directory for sosreport data... sos can be run with -g
    notes           - Empty directory to keep notes on this hosts
    vmpdata         - VMPScan directory where key and clusterview linkage data is kept
    vmpscan.conf    - Configuration file that reflects the options used for this scan
    vmpscan.htm     - Hostview report in html format
    vmpscan.txt     - Hostview report in text format
    vmpscan.xml     - Hostview report in html format
    vmpscan.sqlite  - Hostview report in sqlite3 database format

  The empty directories are intended to bring all the data for a given case under
  a single root where it can all be accessed with point and click operations from
  a browser.

---> Cleaning up and Recovering Disk Space

  Once the initial analysis is completed, or further review is on hold, the expanded
  directory can be saved to the existing archive and space recovered using the
  clean.sh script:

    sysadmin@ws2:/tmp/vmpscan $ ./clean.sh -b
      VMPScan clean utility - March 22, 2011 - Version 2.2

      Report archives will be updated from existing directories before deletion

      If no new data was added that should be saved or the directory data has been
      modified or damaged, exit and re-run clean.sh with the -n option: ./clean.sh -n
      The clean operation is also faster when the archives are not rebuilt

      Reports found:
      ./node12-2011-03-22-231810-vmpscan

      Saving: node12-2011-03-22-231810-vmpscan - ok

  The cleanup operation will update the original archives with any data that was
  added to the working directory (such as osw, rda, sr notes, etc) and delete the
  working directory. With large clusters, this can be a significant saving of disk
  space. The /tmp/vmpscan directory looks it did when we started after clean.sh:

    sysadmin@ws2:/tmp/vmpscan $ ls
      merge.sh  node12-2011-03-22-231810-vmpscan.tar.gz

  To resume the analysis, run merge.sh again to re-expand the report directory
  and all the information that was previously in it before clean.sh was run.
  If the working directory data is damaged, you can run clean.sh -n to delete
  the directories without updating the original archive. Then run merge.sh again
  to get a fresh copy.

---> Cluster Operation

  Both merge.sh and clean.sh work the same on a single report archive from one
  host or archives from dozens of cluster nodes. Here is a directory where the
  VMPScan archives from a 5 node Oracle VM cluster have been copied:

    root@ovmclu:/mnt/repo1/vmpscan # ls -1
      blade0-2011-03-22-013906-vmpscan.tar.gz
      blade1-2011-03-22-183907-vmpscan.tar.gz
      blade2-2011-03-22-183918-vmpscan.tar.gz
      blade3-2011-03-22-183918-vmpscan.tar.gz
      blade4-2011-03-22-013914-vmpscan.tar.gz
      merge.sh

  There is a merge.sh script in this directory, but if there wasn't, untarring
  one of the archives will recreate it. Running merge.sh shows all the archives
  being expanded and the key data from each being merged into a unified
  clusterview portal:

**************
  root@ovmclu:/mnt/repo1/vmpscan # ./merge.sh -b
    VMPScan archive merge utility - March 22, 2011 - Version 2.2

    Found new: blade0-2011-03-22-013906-vmpscan.tar.gz
    Found new: blade1-2011-03-22-183907-vmpscan.tar.gz
    Found new: blade2-2011-03-22-183918-vmpscan.tar.gz
    Found new: blade3-2011-03-22-183918-vmpscan.tar.gz
    Found new: blade4-2011-03-22-013914-vmpscan.tar.gz

    Ready to process and merge all archives and existing directories

    Note: Clusterview report will contain only KEY node data parameters

    To merge ALL node data, abort and run merge.sh with the -a switch: ./merge.sh -a
    This process can take several minutes per node

    Expanding report archives for blade0-2011-03-22-013906-vmpscan:..... ok
    Expanding report archives for blade1-2011-03-22-183907-vmpscan:..... ok
    Expanding report archives for blade2-2011-03-22-183918-vmpscan:..... ok
    Expanding report archives for blade3-2011-03-22-183918-vmpscan:..... ok
    Expanding report archives for blade4-2011-03-22-013914-vmpscan:..... ok
    Creating HostView for: blade0-2011-03-22-013906 ok
    Creating HostView for: blade1-2011-03-22-183907 ok
    Creating HostView for: blade2-2011-03-22-183918 ok
    Creating HostView for: blade3-2011-03-22-183918 ok
    Creating HostView for: blade4-2011-03-22-013914 ok
    Creating Clusterview Portal
    ++Merging net keys................................... ok: 55 keys
    ++Merging os keys......................................................... ok: 120 keys
    ++Merging storage keys.............................................. ok: 100 keys
    ++Merging virt keys................................................. ok: 100 keys

    Done: Open index.htm in a browser to view the report
**************

  Note that there are many more "keys" being merged from the combination of the
  5 nodes. Please note that merge.sh merges a defined subset of host parameter keys
  like kernel version, resolv.conf and other system values that are always inspected.
  It is also possible to merge ALL the parameters that were captured by the VMPScan
  scan with merge.sh -a. This can take a long time bug provides a side by side method
  of comparing all values between all nodes.

  To cleanup after a complete or suspended analysis:

  root@ovmclu:/mnt/repo1/vmpscan # ./clean.sh -b
    VMPScan clean utility - March 22, 2011 - Version 2.2

    Report archives will be updated from existing directories before deletion

    If no new data was added that should be saved or the directory data has been
    modified or damaged, exit and re-run clean.sh with the -n option: ./clean.sh -n
    The clean operation is also faster when the archives are not rebuilt

    Reports found:
    ./blade1-2011-03-09-183907-vmpscan
    ./blade3-2011-03-09-183918-vmpscan
    ./blade0-2011-03-10-013906-vmpscan
    ./blade4-2011-03-10-013914-vmpscan
    ./blade2-2011-03-09-183918-vmpscan

    Saving: blade1-2011-03-22-183907-vmpscan - ok
    Saving: blade3-2011-03-22-183918-vmpscan - ok
    Saving: blade0-2011-03-22-013906-vmpscan - ok
    Saving: blade4-2011-03-22-013914-vmpscan - ok
    Saving: blade2-2011-03-22-183918-vmpscan - ok

  To resume the analysis and recreate the cluster and hostviews, run merge.sh again.

  Note: If scans are run on the same machine, archives will accumulate in
  /tmp/vmpscan. These archives will be merged, so if they are stale, please
  delete them before running the scan. Accumulating these archives on the same
  machine can also be an advantage as it takes a detailed snapshot of the
  machine at that point in time that can be compared with future scans using the
  clusterview portal.

Please see the manual section "VMPScan Reports" for additional details.
</man.manage>

<man.reports>

---> Host and Cluster Views

  VMPScan creates 2 views of the host data that it acquires during a scan. The
  first is called a "Hostview" where all the information that was collected from
  a given machine is available as single report. This stand-alone view is similar
  to an RDA or SOS report.

  In addition to the Hostview, VMPScan captures pre-defined "Key Parameters"
  during it's scan and saves them as a separate dataset. Key parameters are system
  values that are always reviewed by system administrators and support analysts
  to determine basic OS health, cluster node symmetry and conformance to best
  practices. Examples are the Linux kernel version, network default gateway along
  with the status of critical services such as ntp, dns and product agent daemons.

  Capturing Key parameters during the scan makes it possible to combine these
  values from multiple nodes and "merge" them into html tables so that each one
  is placed next to the other cluster peer values. Having this grouping on a
  single report page allows cluster node symmetry to be quickly reviewed and
  verified by inspection for these key values. The -x command line option also
  allows these values to be exported as pseudo-xml so they can easily be imported
  into a database for automated, heuristic analysis.

---> Fault Signatures and Active Health Checks

  In addition to presenting static data for review, VMPScan also performs active
  tests as it scans. These tests ("TestOps") are sometimes the result of a basic
  command or can be driven by signature based templates. A simple health check
  is to ping the default gateway and see if the operation returns a zero. A
  signature based test is to ping the machines's hostname and look for 127.0.0.1
  in the output, which would indicate that there is a malformed entry in /etc/hosts.
  VMPScan contains a Fault Analysis Engine (FAE) that supports both test models.

---> TestOp Tag ID's

  Each "TestOp" has a unique "path" and id called a "tag", such as
  "ws2.net.conf.gateway.default_gw". The hostname "ws2" makes the tag unique in a
  cluster. The net is the "scope", conf is the "section"  and "conf" is the test
  "group". Links in the reports are presented hierarchically and these components
  can be clicked on separately to jump between sections of the report. In the
  above example, default_gw can be right clicked and the full link pasted into
  an email or chat to enhance collaboration.

---> TestOp Classes

  Each TestOp is a member of one or more classes that are abbreviated in the report:

    I: General information
    B: Best Practice
    K: Key Value
    H: Health Check
    W: Warning
    E: Critical Error

  In the html report, these values are shown for all TestOps and color
  highlighted when it fails.

---> Site Review Process

  For problem sites where an overall configuration baseline does not exist, run
  VMPScan on all nodes,then merge and review the key parameters for basic
  correctness. Although it can take several minutes to complete, running clean.sh
  followed by merge.sh -a will create a Clusterview of all the nodes and all of
  their report parameters. Any discrepancies will easily be picked up by visual
  inspection.  

</man.reports>

<man.maint-fixits>

  VMPScan "fixits" are text recommendations that are provided when a testop fails
  on a critical subsystem. The "fixit" hint text is stored after the end of the
  vmpscan script code. This enables vmpscan to be provided as a single, self
  standing file that is easily deployed. The hints are located by grepping with
  a -b for the start and end testop tags and then dd'ing the data between the
  tags. A typical "fixit" looks like this:

        <net.perf.connectivity.pinggw>
        No layer 3 network connectivity: Cannot ping default gateway.
        Please check your gateway router or firewall configuration.
        </net.perf.connectivity.pinggw>
        
  The fixit lookup engine can be redirected to other files by providing a second
  parameter filename after the tag that is to be retrieved. Whitespace formatting
  is preserved and ansi color sequences and html can be embedded in the fixit
  text, but since vmpscan outputs both formats, the html file display would be
  ugly, so this is not recommended.

  The global variable MAXFIOPSTATUSLEN defines the maximum length of the block.
  The search can also be redirected to a separate file by changing the
  FIOPSTATUSFILE declaration.
</man.maint-fixits>

<man.faearch>

---> The FAE Architecture

  The Fault Analysis Engine structure consists of the following components:
    1. Initialization - establish if the machine is in one of the supported classes
    2. A generic, signature driven Fault Analysis Engine (FAE)
    3. A test suite of information gathering commands and fault signature masks.
    4. Fixit hint documentation that is retrieved when a fault is detected.
    5. Report generation of text, html, xml and cluster view (cluvu)

---> FAE Test Operations

  Test operations (testops) are written in a simple test language that is
  interpreted by the FAE. The syntax is generally composed of 4 mandatory and
  2 optional fields. These fields are:

    1. Call to the FAE. This can also set the pass/fail logic for the test
    2. FAE operation to be performed
    3. Message for the analyst that will appear in the report test item header
    4. FAE command or fault signature mask to be applied to existing data
    5. Optional failure text to be output to the report upon test failure
    6. Optional success text to be output to the report upon test failure

  The following is a typical FAE operation that scans the root filesystem for
  suid/guid executables:

    FS cmd "Scan for suid/guid progs" "find / -type f \( -perm -04000 -o -perm -02000 \)" suidguid

  FS is the call to the FAE. The "cmd" is the FAE operation to execute the
  command in parameter 3. Parameter 2 is a description of the command for the
  analyst and "suidguid" is the unique test ID. Test ID's are hierarchical to
  provide addressability for each test and it's result. The full tag address
  for the above test is:

    teksim1.os.security.filescan.suidguid

    1. "teksim1" is the hostname and the toplevel of the tag hierarchy
    2. "os" is the scope of the test
        os, net, storage, virt, apps and prod are implemented scopes
    3. "security" is a section that contains groups of related tests in the os scope
    4. "filescan" is a test group
    5. "suidguid" is the individual test or fault signature tag

  See the script code comments for more information on test organization and tag
  addressing.If the suidguid test were to fail (suid/guid executables found),
  the FAE would search for fixit text with the tag os.security.filescan.suidguid.
  Note that the hostname is dropped to keep the search generic. The fixit search
  proceeds up the tree until a match is found using the following algorithm:

    scope.section.group.tag, scope.section.group, scope.section, scope

---> Fault Signatures

  Acquired test data can be stored and recalled for subsequent tests. The data
  from a test is also retained in the FAE registers and can be re-used in
  subsequent tests as in the following example:

    FSe cmd "/etc/hosts format" "ping -c 1 $HOSTNAME 2>/dev/null" ping_hostname \
        "Cannot locally ping specified hostname \"$HOSTNAME\""
      nzFSw cmdx "Malformed /etc/hosts entry" "echo \"$OPDATA\" | grep 127.0.0.1" malformed_hosts \
        "This system is using dhcp, is not on the network or the /etc/hosts file has a malformed entry"

  The first test attempts to ping the locally defined hostname and reports and
  error (FSe) if it fails. The next test reuses the ping data that was left in
  the FAE accumulator ($OPDATA) and applies a fault signature mask of 127.0.0.1
  to this data to see if the problem is a malformed entry in /etc/hosts. While
  three parameters are required for a test or fault signature mask operation,
  optional parameter 4 can be provided as a "failure message" and parameter 5
  will echo a message on success. This can be used in cases where the problem is
  simple and can be described to the analyst without the need for a fixit lookup.
  The script can optionally outputs a sequential report in html, text, xml and
  sqlite3 formats. It also emits html fragments and a sqlite3 database that can
  be combined with other node reports to provide a cluster oriented report.

</man.faearch>

<man.faerules>

---> The FAE: Writing Fault Analysis Rules

  The Fault Analysis Engine (FAE) in vmpscan.sh is similar to a general purpose
  processor in that it has an instruction set, registers, result flags and tag
  addressable, random access storage. FAE test operations are calls from
  application space to the FAE entry points (FS, ifzFS, ifnzFS) that also provide
  a flag for result severity (info: FS, warning: FSw, error: FSe) and set up
  command chaining, if a conditional result is requested. The chaining logic
  "requests" a logical outcome that is xor'ed with the actual command result.
  If the test fails and a conditional was specified, an abort flag is set and
  further FAE operations are aborted until an else, endif, session or scope
  directive is encountered.

  Results from executed commands are available to the application space via the
  FAE Accumulator registers where command results can reviewed, modified and
  addressably saved.

---> The FAE Instruction Set

     The general form of an FAE command is:

       FS FAE_Command   Analyst_Message   System_Command   Tag_ID   Pass_Msg   Fail_Msg

  The first parameter is the call to the FAE entry functions. The second parameter
  is the FAE Operation. The following describe the current instruction set:

  Single instruction FAE operations:

    cmd - run a system command and save the data and exit status returned in the FAE accumulator
    cmdx - get the command exit status, but don't save the returned data... useful for grepping large logs for errors
    cmdq - Run a command but do not generate a testop record: handy because it won't execute in a failed chain
    dolink - run a command and generate a link to the data in the report tree
    dolinks - run a command, generate a link and add the parameter to the main nav menu
    link    - Add an arbitrary link after the inline testop data
    meminfo - get numeric from /proc/meminfo and limit check: FSe meminfo "MemFree" "<25000" ">1250000"
    getsysctl - get a sysctl -n value and limit check
    dogrep - grep for a string in the FAE accumulator or a file
    grepcount - count the occurrences of a string in a file: FS grepcount "Reboots" "-i restart /var/log/messages" reboots

  Multiple instruction FAE operations:

    cmdopen - Initialize the FAE and execute a data gathering command
        <Process/format the captured command data>
    cmdclose - Write the command to the report and leave the results in the FAE accumulator
    cmdsave - Write the FAE accumulator to the OP storage array
    cmdrecall - Recall a stored command by tag, load it into the FAE accumulator and clock the processor

  Tag hierarchy management and pseudo-operations:

    root, scope, section, group - Set tag address for subsequent operations
    starttimer, elapsed - Set a starting timestamp and get elapsed time
    conmsg, conmsgln - Send text to the console with and without newlines
    msg, msgln - Send text to the report with and without newlines
    dump - Dump the contents of the FAE registers and state variables

---> Conditional Chain Example

  The following is an example of a data gathering operation and fault signature
  masking that begin the sequence of testing an ocfs2 node for proper operation:

    FS section "Ocfs2 Cluster and connection info" ocfs2
    FS group "O2CB and OCFS2 Service status" service
    ifzFSw cmd "Ocfs2-tools installed" "rpm -q --quiet ocfs2-tools" installed \
      "OCFS2 is not installed on this system"
      ifzFS cmd "chkconfig --list o2cb" "chkconfig --list o2cb 2>/dev/null" o2cb
      ifzFS dogrep "o2cb service active" "0:off 1:off 2:on 3:on 4:on 5:on 6:off" o2cb_active
        FS cmd "chkconfig --list ocfs2" "chkconfig --list ocfs2 2>/dev/null" ocfs2

  The FS call invokes the FAE via it's program and chaining support interface.
  The "section" op defines the section address of the test as "ocfs2". The
  "group" op sets the test group as "service". The next "ifzFSw" is a conditional
  test that is looking for a zero result for success. If a non-zero is returned
  from the operation "rpm -q --quiet ocfs2-tools", a warning (w) is generated and
  the subsequent test chain is skipped. Any failure of an ifz or ifnz will abort
  the test chain until a new section, group, elseFS or endif op is encountered.
  Use of chaining reduces the amount of bash branching that is needed for the
  common test cases where a component or utility is not installed where
  subsequent tests would be futile.

</man.faerules>

<man.vmpplugins>

---> Writing and Debugging VMPScan Plugins

  VMPScan supports modular development of test operations and plugin extensions.
  This allows new testop and other automation to be added without having to
  modify the main body of the script.

  To make plugins and FAE rules easier to develop, vmpscan provides a quick test
  environment via a "-t file" command line switch. The -t option looks for and
  executes a an "stub" function called vmptest to set up the environment and
  call the plugin code under test. The following is an example of a basic plugin
  template:

---> VMPScan Plugin Template

  function vmpplugin() { # called from vmpscan main scan by filename
     < Your FAE or bash plugin code >
  }

  function vmptest() { # stub for quick testing (-t /path/pluginFN)
    < Your FAE or bash plugin setup code >  
     vmpplugin
  }

  In test mode (-t plugin_filename), vmpscan initializes it's internal structures,
  greps for "vmptest" to make sure it's present, sources the external file and
  calls the vmptest function. This function provides a "stub" that allows the
  plugin code to be correctly positioned in the place in the test hierarchy
  where it will ultimately run and then executes the vmpplugin function that
  contains the FAE and bash instructions under test.

  When the vmpplugin completes, it returns to vmptest which returns control to
  VMPScan. The scan as it normally would by writing the report, creating the
  archives and reporting subsystem faults to the console.

  Developing new tests this way is MUCH faster then running the entire VMPScan
  script to exercise the test code. The following code is an example of an
  external plugin.

---> VMPScan Plugin Example

  This code is in a file called os.security.uaccess.vmp to match the place in
  the scan hierarchy where it is intended to run:

  function vmpplugin() { # called from vmpscan by filename
    FS cmd "Current Users" "who | cut -d' ' -f1 | sort -u" cur_users
    FS cmd "Number of Users" "echo $OPDATA|wc -w" num_users
  }

  function vmptest() { # stub for testing (-t /path/plugin_filename)
    FS scope "os" os
      FS section "User Security" security
        FS group "Access Audit" uaccess
          vmpplugin
  }

  To test this plugin, run: vmpscan.sh -t os.security.uaccess.vmp

  To insert the plugin into the vmpscan, place os.security.uaccess.vmp in
  the directory with vmpscan.sh or point to the directory where it (and other
  plugins) reside with the -V <path> command line option.

  Plugins are sourced into the scan hierarchy by filename. The plugin in the
  above example will execute at the end of the os scope, security section and
  access test group.  This enables the plugins to inherit any data from a just
  completed testop context.The above commands will be visible in the report and
  look exactly like the built-in testops. Testop records in the reports and
  database will have the following tag id addresses:

  <hostname>.os.security.uaccess.cur_users
  <hostname>.os.security.uaccess.num_users

  Plugins can also create new sections and test groups. The following file would
  be named "os.security.vmp" because it creates a new group that is intended to
  be inserted at the end of the os.security scope and section:

  function vmpplugin() { # called from vmpscan by filename
    FS group "User Access Audit" user_access
      FS cmd "Current Users" "who | cut -d' ' -f1 | sort -u" cur_users
      FS cmd "Number of Users" "echo $OPDATA|wc -w" num_users
  }

  function vmptest() { # stub for testing (-t /path/pluginFN)
    FS scope "os" os
      FS section "User Security" security
        vmpplugin
  }

  Same instructions as the first example, but moving the group directive to the
  plugin will add a new group user_access that will be added to the reports and
  show up in the main hostview navigational menu.

</man.vmpplugins>

<man.appearance>

  To customize the colors of VMPScan reports, create a file named "vmpscan.css"
  using the script's default css and modify to your personal tastes. Place this
  file in the base directory with the index.htm and VMPScan report archives.
  These files can also be placed in each report directory. The vmpscan.css file
  will not be deleted and remain in the root directory after a clean.sh operation.

  To cut and paste the default css, select the "VMPScan_css" manual page.

  The best way to see where these tags are applied is to "view source" on the report
  pages and look for the tags in their usage context. 
</man.appearance>

</man.vmpscan_css>
body { color:#E0E0E0; background-color:#191919;font-size:14px;font-family:sans-serif;font-weight:normal;}
table {font-size:14px;}
caption { color: #80C0FF; background-color:#333333; text-align:left; }
pre {color:#FFFFFF; margin-left:25px;}
a:link {color: #E8E880; text-decoration: none; }
a:active {color: #E8E880; text-decoration: none; }
a:visited {color: #E8E880; text-decoration: none; }
a:hover {color: #00E040; text-decoration: none; }
.scope {color:#80FF80;background-color:#282828; padding:4px;font-weight: normal;text-decoration: underline;}
.sec {color:#FF8000;background-color:#282828;padding: 4px;margin-left:5px;text-decoration: underline;}
.grp {color:#E0E080; padding:4px; background-color: #282828;text-decoration: underline;font-weight: normal;margin-left:10px;}
.grpend {color:#C0C0FF; padding:4px; background-color: #282828; margin-left:10px;}
.sig {color:#80C0FF; text-decoration: none; background-color:#333333;padding:4px; margin-left:15px;}
.tag {color:#FFFFE0;} .clukey {color:#FF8080;}
.resok {color:#80FF80;} .resinfo {color:#8080FF;}
.reserr {color:#FF8080;} .reswarn {color:#FFFF80;}
.ahsec {font-weight: 900;color:white;}
.cv {font-family:monospace; color:#FFFFFF; margin-left:5; white-space: pre; }
.ce {font-family:monospace; color:#FFFFFF; margin-left:5; white-space: normal; }
.cr {font-family:monospace; color:#80FF80; margin-left:5; white-space: pre; }
.fixit {color:#80FF80;margin-left:25px; white-space: pre;}
.skip {color:#808080; margin-left:25px;}
.apphead {color:#808080;} .syshead {color:#FF8080;} .warnhead {color:#FFFFA0;} .errhead {color:#FF8080;}
.tag1 a:link {color:#E8E880;}      .tag1 a:active {color:#E8E880;}
.tag1 a:visited {color:#E8E880;}   .tag1 a:hover {color:#00E040;}
.clucap a:link {color:#A0E0FF;}    .clucap a:active {color:#A0E0FF;}
.clucap a:visited {color:#A0E0FF;} .clucap a:hover {color:#E0E0A0;}
.tagh a:link {color:#FFFFFF;}      .tagh a:active {color:#FFFFFF;}
.tagh a:visited {color:#FFFFFF;}   .tagh a:hover {color:#80FF80;}
</man.vmpscan_css>

<man.orachk_css>
body { color:#000000; background-color:#FFFFFF;font-size:14px;font-family:sans-serif;font-weight:normal;}
table {font-size:14px;}
caption { color: #FFFFFF; font-weight: bold; background-color:#000000; text-align:left; }
pre {color:#000000; margin-left:25px;}
a:link {color: #0000FF; text-decoration: none; }
a:active {color: #FF0000; text-decoration: none; }
a:visited {color: #800080; text-decoration: none; }
a:hover {color: #CC2200; text-decoration: none; }
.scope {color:#80FF80;background-color:#282828; padding:4px; font-weight: bold;;text-decoration: underline;}
.sec {color:#FF8000;background-color:#282828;padding: 4px;margin-left:5px; font-weight: bold;text-decoration: underline;}
.grp {color:#E0E080; font-weight: bold; padding:4px; background-color: #282828;text-decoration: underline;margin-left:10px;}
.grpend {color:#C0C0FF; padding:4px; font-weight: bold; background-color: #282828; margin-left:10px;}
.sig {color:#FFFFFF; font-weight: bold; background-color:#000000;padding:4px; margin-left:15px;}
.tag {color:#FFFFE0;} .clukey {color:#FF8080;}
.resok {color:#00CC00;} .resinfo {color:#0000FF;}
.reserr {color:#FF0000;} .reswarn {color:#FFFF00;}
.ahsec {font-weight: 900;color:white;}
.cv {font-family:monospace; color:#000000; margin-left:5; white-space: pre; }
.ce {font-family:monospace; color:#000000; margin-left:5; white-space: normal; }
.cr {font-family:monospace; color:#000000; margin-left:5; white-space: pre; }
.fixit {color:#0000FF;margin-left:25px; white-space: pre;}
.skip {color:#808080; margin-left:25px;}
.apphead {color:#000000;} .syshead {color:#FF0000;} .warnhead {color:#0000FF;} .errhead {color:#FF0000;}
.tag1 a:link {color:#0000FF;}      .tag1 a:active {color:#0000FF;}
.tag1 a:visited {color:#0000FF;}   .tag1 a:hover {color:#CC2200;}
.clucap a:link {color:#A0E0FF;}    .clucap a:active {color:#A0E0FF;}
.clucap a:visited {color:#A0E0FF;} .clucap a:hover {color:#E0E0A0;}
.tagh a:link {color:#000000;}      .tagh a:active {color:#000000;}
.tagh a:visited {color:#000000;}   .tagh a:hover {color:#CC2200;}
</man.orachk_css>

<man.vmpscan_conf>

  Each time vmpscan runs, it writes the startup command line options and
  unmodified defaults to a file in the report root directory called vmpscan.conf.
  If this file is placed in the same directory as vmpscan.sh, /etc or pointed to
  by the -f /path/filename command line switch, the script will import and use
  those parameters for the next scan. This file with script defaults contains:

-----------------

# VMPScan Configuration File - Version 2.2-3
# To run a session with these parameters, place this file in /etc, the same
# directory as vmpscan.sh or point to it with the -f command line parameter.
# See the vmpscan.sh -m man page "vmpscan_conf" for more information.

# -b <path> Path where the report directory and archive will be written
# Default is to create /tmp/vmpscan. Other directories must already exist
BASEDIR="/tmp/vmpscan"

# -L Script event detail written to /var/log/messages
# 0:disable; Default=1:start/stop; 2:scope; 3:section; 4:group; 5:debug
LOGLEVEL="1"

# -l Captured logs: Each level ADDS to the files in the previous one:
#  0: no logs; 1:/var/log/messages and dmesg; 2: messages* (default)
#  3: /var/log/boot,cron,yum; 4: /var/log/maillog*,httpd,samba, cups
#  5: /var/log/se*,audit*; 6:/var/log/*; 7:/etc/*; 8:/var/lib/*
LOGGING="2"

# -x <option set> select extended tests: v|V:LVM; r|R:SW RAID
# o|O:OVM; g|G:GECOS data; s|S:OS Security; l|L:lsof; n|N: network.
# Default=v: do LVM scans. Example: -x VOSN selects extended LVM, OVM,
# OS Security and Network tests
EXTENDED="v"

# -n 1 enables extended network testing: Default=1
NETPROBE="1"

# -r 1 rotates logs after capturing the archive: Default=0
LOGROTATE="0"

# -F 0 strips comments and blanks lines from config files: Default=0
PRINTCOMMENTS="0"

# -o 1 skips the initial dialog for non-root users... useful for batching
NODIALOGS="0"

# -g Do SOS report if parameters or a blank is supplied: Default=""
SOSREPORT=""

# Optional delay between tests in milliseconds: Default=50
DELAYINTERVAL="50"

# -q 0/1:print progress notification message to stdout: Default=1
QUIET="0"

# -k 1 does a fast scan of key healthcheck parameters and display to console
JUSTHC="0"

# -O Enable Oracle Product plugins for the report: Default=0
ORACLESCAN="0"

# -A Enable applications and plugins for the report: Default=0
APPSCAN="0"

# -W Write Oracle VM binary db... warning: exposes ovs passwords: Default=0
WRITEDB="0"

# -D <secs> Random startup delay for cluster load balancing: Default=0
STARTDELAY="0"

# -T <secs> Change global timeout value for all commands: Default=20
CMDTIMEOUT="20"

# -X <list> Exclude specified commands by scope, section, group or test
EXCLUDES=""

# -S Storage block r/w test: "/path1 /path2...": Default=""
# Use with -B to set xfr size. Not supported on EL4
STORAGETEST=""

# -B <size in kb> Storage test block size in kilobytes: Default=16384K
DTSIZE="16384"

# -c Client-server-node block transfer size in Kbytes: Default=16384K
NTSIZE="16384"

# -s <port>  Server port base for network node test
# Default: 5949 and 5950. Used with -N
SERVERBASEPORT="5949"

# -C Prompt to Storage and net node tests... use for syncing on clusters
CLUSTERSYNC="0"

# If NODES2TEST != "", forks a server and attempts a dd network write to
# the nodes to test: "node1 node2 node3...". Not supported on EL4
NODES2TEST=""

# -I ID tag to associate this scan with a cluster or case number
IDTAG=""

# -R <list> Report output options: h=html; t=text; x=xml; d=database
# Example -R htd would produce an html, text and database report
REPORTOPTIONS="HT"

# -V VMPScan plugin path - where to find .vmp plugins
PLUGINPATH=""

# -K kernel data collection paths for /sys and /proc. Add specific paths,
# "pids" to snapshot /proc/[0-9]* or "all" for maximum collection from both.
# "files" just collects /proc root files. Specifying many paths, all or pids
# can be problematic and hang the script on some systems: use with caution
KERNELFSDATA="files"

# Base command that the script will execute. A "" defaults to DoHostScan
# Options: DoHostScan TestScriptExecute KeyParameterScan:  see man pages
COMMAND=""

-----------------

  The vmpscan.conf file can also be modified in order to pre-configure the scan
  execution without having to enter command line parameters. It can also be
  generated to reflect any included command line parameters with the -w option:

    ./vmpscan.sh -g "" -b /OVS/vmpscan -T 120 -w

     ---> Using default script settings as source for defaults
     Defaults and command line parameters written to: /tmp/vmpscan.conf

  This will generate a complete vmpscan.conf in the current directory with the
  following defaults modified per the command line parameters:

   BASEDIR="/OVS/vmpscan"
   SOSREPORT=" "
   CMDTIMEOUT="120"

  Writing vmpscan.conf with the -w and no additional parameters will use the
  internal script defaults unless they are overridden in /etc/vmpscan.conf or
  ./vmpscan.conf. Additional script parameters that can be modified by adding
  them in vmpscan.conf are:

MAXIFS="9"                 # Maximum ifcfg-ethX to display, if found (starting at 0)
DEFAULTFIXITFILE="$ME"     # Path and name for fixit hints: defaults to the script
MAXFIOPSTATUSLEN="30000"   # Maximum length of a fixit hint block
OKCOL="45"                 # Console column for ok, warning and error group stats
ELAPSEDCOL="90"            # Console column for test group elapsed time                   
STRIPCOMMENTS1="egrep -v --regex=#\|^$" # strip comments/blank lines
STRIPCOMMENTS="sed -e 's/;.*//' -e 's/#.*//' -e '/^$/d' -e '/^\t\{1,\}$/d'"
PRINTALL="cat"             # Command to print everything from a file
CAT=$STRIPCOMMENTS         # Cmd to dump text files... cat or comment stripping egrep
CAT1=$STRIPCOMMENTS1       # Alternate comment stripper... works better on some files
MAXVMS="10"     # Alert if more then this number of VM's is on the OVS 2.2 mgmnt_intf

</man.vmpscan_conf>

<man.xml_format>

---> Overview

  In addition to text and html reports, VMPScan also outputs a well formed XML report that
  is intended to be imported into a database or spreadsheet. This adds about 15% to the
  execution time of the script and is not generated by default.

---> Schema

  The XML report contains the following record structure and field values:

  <ws1-2011-03-17-015619-vmpscan>  Session ID begin tag

    <OP> Start of testop record

       Full test path: hostname.scope.section.group.testop
      <TAG>
      ws1.storage.dev.mpath.device-mapper-multipath_installed
      </TAG>

       Brief, human readable test description
      <MSG>device-mapper-multipath installed</MSG>

       Testop type: I=Inline report data; F=Link to File; D=Link to Directory
       Files and directory names and paths are relative to the host report directory
      <TYPE>I</TYPE>

       Literal, unescaped data returned from test operation
      <DATA>
      device-mapper-multipath-0.4.9-5.fc12-i686 
      device-mapper-multipath-libs-0.4.9-5.fc12-i686 
      </DATA>

       Execution time for the testop
      <TIME>0.009</TIME>

       Testop class: (compound field) B=Best Practice; K=Key parm; I=Info; W=Warning E=Error
      <CLASS>/k/i</CLASS>

       0/1  1=Key parameter
      <KEY>0</KEY>

       Testop result: 0=Pass;  1=Fail;  2=Test not executed: dependency not met
      <RESULT>0</RESULT>

       Pass or Fail supplementary result message
      <RMSG>device-mapper-multipath installed</RMSG>

    </OP>  End of testop record

    All the rest of the report's OP records

  </ws1-2011-03-17-015619-vmpscan>  Session id end of data tag

</man.xml_format>

<man.db_format>

---> Overview

  In addition to text, html and xml reports, VMPScan also provides a sqlite3
  database report generation option. Like the html report, host report databases
  also cluster merged and can be queried and used for automated diagnostics and
  recurring fault analysis.The database option adds about 10% to the execution
  time of the script and is off by default. The note filename is vmpscan.sqlite.
  The merged clusterview report is named vmpmerge.sqlite.

---> Schema

  The Database report is identical to the xml format and consists of a single,
  flat and unnormalized sqlite3 table with the following schema:

    Table name is the session id as in: ws1-2011-03-17-015619-vmpscan 

    hostname varchar  Short hostname that appears in the session id
    sessdate varchar  The timestamp that appears in the session id
    tag varchar Full test path: hostname.scope.section.group.testop
    msg text    Brief, human readable test description
    type char   Testop type: I=Inline report data; F=Link to File; D=Link to Directory
                Files and directory names and paths are relative to the host report directory
    cmd varchar Command used to obtain the data... varies with os and specific operation
    data text   Literal, unescaped data returned from test operation
    rmsg text   Pass or Fail supplementary result message
    extime datetime  Execution time for the testop
    class varchar    Testop class: B=Best Practice; K=Key parm; I=Info; W=Warning E=Error
                     This is a compound field with forward slash delimiters, ie: /W/B/H 
    key char         0/1  1=Key parameter
    result integer   Testop result: 0=Pass; 1=Fail; 2=Test not executed: dependency not met
    
    primary key hostname,sessdate,tag

  The compound primary key allows node databases for the same host but different sessions
  to be merged and compared. This is useful tracking changes on the same host across
  scans that are run at different times.

---> Merging session databases

  The merge.sh command will automatically merge node report databases into an
  "vmpmerge.sqlite" in the clusterview root directory. If you are only interested
  in the database and don't need the html clusterview report (that can take some
  time to generate), use the following command to expand the report directories,
  merge the individual node databases into vmpmerge.sqlite and immediately
  recover the expanded directory space:

  ./merge.sh -db

  To merge additional databases with vmpmerge.sqlite (always the root db name),
  run the following:

  ./merge.sh -m <file list of vmpscan 2.2 sqlite databases>

  A sql dump of the merged database can also be generated with:

  ./merge -xm <file list of vmpscan 2.2 sqlite databases>

---> Constructing Queries

  Since the sessionid contains hyphens, referencing a node or merged table in a
  sql query will have to be escaped with enclosing brackets:

  select tag,data from [ws1-2011-03-22-015619-vmpscan] where result='1' and key='1' and class like '%/E%';

</man.db_format>

<man.feature_set>

  * Cluster aware... can merge individual node scans into a unified clusterview
    for rapid review and troubleshooting

  * Runs tests as it scans, clearly flags errors and warnings in the reports
    and provides fix-it recommendations for common problems

  * Provides scan data in 4 report formats: html, text, xml and a sqlite3 database

  * Hierarchal links (blade0.os.perf.process.num_dstates) are provided for all
    tests as db keys and links for cutting and pasting into chats and emails

  * Highlights key subsystem parameters for quickly determining the basic health
    of a given node. HTML reports are error highlighted and heavily linked for
    quick navigation.  An equivalent text report is available for grepping.

  * Provides execution time for each test and timeout flags in the report for
    flagging slow operations

  * Xml and sqlite3 reports allow the scan data to be imported for automated
    analysis and fault detection. Sqlite3 reports from any number of nodes or
    different sessions on the same node can be merged and queried

  * Report archive is small yet contains all requested reports along with system
    logs and clusterview linkage information

  * A merge.sh script is generated automatically by VMPScan and placed in the
    report archive directory. Merge expands any report archives it finds and
    links the key parameter data from each node into a unified cluster view

  * Running merge.sh generates a "clean.sh" script to update the report archives
    for each node and then reclaim disk space by deleting the directories

  * Placeholder directories are provided and linked to the host report for RDA,
    OSW, SR notes, Product and Performance data

  * Delayed cluster start and time delay test padding are command line options
    to reduce load on busy production systems

  * VMPScan will automatically add test padding delay if it detects a busy system

</man.feature_set>

<man.known_issues>

---> VMPScan Version <!--#scriptverrev-->

  - Running sosreport on OL6 fails
    The sosreport package has a problem and will not execute on the initial
    release of OL6. Update to the latest sos version and run again.

  - Including sos reports add a LOT of time to the scans and merges. Nothing
    broken... just a lot of data to compress

  - SOS report generates a large amount of call trace information in the logs.
    This is normal and part of the sosreport process

  - This message will appear in /var/log/messages during the vmpscan ocfs2 peer
    networking check. It is unavoidable and not an error:
      o2net_accept_one:<pid> attempt to connect from node <origin ip:port> but
      it already has an open connection

  - Capturing the ovs-agent global binary (-W) will sometimes produce a corrupted
    archive due to concurrent agent writes to the db files. Can't do anything
    about that other then re-run the scan

  - Some data transports replace hyphens with underscores in vmpscan archive
    filenames. Exact file and directory names are required and the merge.sh
    utility will attempt to rename malformed filenames. If this is not possible
    due to permissions, the merge will continue, but clean.sh will generate a
    duplicate and correctly named archive.

  - The database merge in merge.sh will sometimes fail when hosted on nfs storage
    due to problems with some nfs lock implementations. Move the archives to
    another location to do the operation if you need the merged databases.

  - Symlinks aren't followed in the /sys and /proc directories on OL6

</man.known_issues>

<man.custom_version>

  To generate a custom version of VMPScan, create a working directory named
  vmpscan-2.2, copy vmpscan.sh to it and perform the following steps:

    1. Clear the existing script.md5 at the very end of the vmpscan.sh file
    2. Edit the script and test the modifications as desired
    3. Update the following variables at the top of the script:

        readonly REVISION="3"
        readonly LASTUPDATE="May 15, 2011"
        readonly MAINTAINER="Tom Lisjac <tom.lisjac>"

       Please add your initials or some other identifier to the REVISION to
       distinguish it from mainline releases.

    3. Run: vmpscan.sh -5 and paste the new value into the script.md5 record
    4. Run: vmpscan.sh -Z to generate the rpm spec file. Copy to the build system
    5. Delete the vmpscan spec file from the working directory
    6. Copy the GPL2 LICENSE file that came with VMPScan to the working directory
    7. Run: vmpscan.sh -P to generate the documentation (required for the spec)
    8. Run: vmpscan.sh -w to generate a vmpscan.conf. Note that this data may
       originate from ./vmpscan.conf or /etc/vmpfinfo.conf. Rename or move them
       to generate the file from the script defaults
    9. cd .. and run: tar -czf vmpscan-2.2.tar.gz vmpscan-2.2
   10. Copy the tarball to your build system BuildRoot/SOURCES
   11. Log into your build system and run: rpmbuild -ba vmpscan-2.2.spec
   12. The rpm is in the following location on the build system:
         BuildRoot/RPMS/noarch/vmpscan-2.2-<your revision number>.noarch.rpm
       To package as a tar.gz:
         cp vmpscan-2.2.tar.gz vmpscan-2.2-<your revision number>.tar.gz

  The script will operate without an md5, but it's intended to flag any damage
  or modifications that might affect it's performance and accuracy.

  Rather then building a new package, please consider sending your updates and
  improvements to the current maintainer for incorporation into the next mainline
  release.
    
<man.custom_version>

<man.rpmspec>
Summary: Diagnostic Scan and Cluster Report Generator for Oracle VM and EL4/5/6
Name: vmpscan
Version: <!--#scriptver-->
Release: <!--#scriptrev-->
License: GPL2
Group: System
Vendor: Oracle Corporation
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
Source0: %{name}-%{version}.tar.gz
Packager: <!--#maintainer-->
BuildArch: noarch

%define basedir /usr
%define confdir /etc
%define installdir %{basedir}/bin
%define docdir %{basedir}/share/doc/%{name}-%{version}

Requires: bash >= 3.0, coreutils >= 4.5, grep >= 2.0

%description

VMPScan is a cluster aware, diagnostic script that will run basic health
checks and gather detailed, addressable system information from an Oracle VM
Server, Manager or generic Enterprise Linux 4, 5 or 6 system. A single archive
is created that contains the scan data along with linking information that can
be merged with other host archives to produce a cluster oriented report. Html,
text, xml and sqlite3 database reports can be optionally generated to support
both manual and automated fault analysis. VMPScan's fault detection architecture
is generalized and can be extended with plugins to provide test coverage for
additional products and platforms. 

%prep
%setup
%{__rm} -rf %{buildroot}
%{__mkdir} %{buildroot}
%{__mkdir} -p %{buildroot}%{installdir}
%{__mkdir} -p %{buildroot}%{confdir}
%{__mkdir} -p %{buildroot}%{docdir}

%install
install -p -m755 vmpscan.sh $RPM_BUILD_ROOT%{installdir}
install -p -m644 vmpscan.conf $RPM_BUILD_ROOT%{confdir}
install -p -m644 README-vmpscan.txt $RPM_BUILD_ROOT%{docdir}
install -p -m644 MANUAL-vmpscan.txt $RPM_BUILD_ROOT%{docdir}
install -p -m644 LICENSE $RPM_BUILD_ROOT%{docdir}

%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root)
%{installdir}/*
%{docdir}/*
%{confdir}/*

%pre
if [ "$1" = "1" ]; then
  for i in /etc/*-release; do
    if grep -q "Tikanga" $i; then exit 0; fi
    if grep -q "Oracle VM server release 2.2" $i; then exit 0; fi
    if grep -q "Oracle VM server release 3.0" $i; then exit 0; fi
    if grep -q "Oracle VM server release 3.1" $i; then exit 0; fi
    if grep -q "Oracle VM server release 3.2" $i; then exit 0; fi
    if grep -q "Oracle VM server release 3.3" $i; then exit 0; fi
    if grep -q "Oracle VM server release 3.4" $i; then exit 0; fi
    if grep -q "Nahant" $i; then exit 0; fi
    if grep -q "Carthage" $i; then exit 0; fi
    if grep -q "Santiago" $i; then exit 0; fi
    if grep -q "Fedora" $i; then exit 0; fi
  done
  echo "Sorry, VMPScan is not supported on this OS version"
  exit 1
fi

%post
if [ "$1" = "1" ]; then
  [ -h %{installdir}/vmpscan ] && rm -f %{installdir}/vmpscan
  ln -s %{installdir}/vmpscan.sh %{installdir}/vmpscan
  echo
  echo "VMPScan installation successful"
  echo "Run vmpscan -m or see %{docdir} for instructions"
  echo
fi

%postun
if [ "$1" = "0" ]; then
  [ -h %{installdir}/vmpscan ] && rm -f %{installdir}/vmpscan
  rm -rf %{docdir}
  echo
  echo "VMPScan has been successful removed"
  if [ -d /tmp/vmpscan ]; then
    echo
    echo "The /tmp/vmpscan directory exists and may contain report"
    echo "archives from previous scans that you may wish to remove."
  fi
  echo
fi

%changelog
* Wed March 2 2016 Tom Lisjac <tom.lisjac> 1.1b4
- Moved the nav_end tag to omit the br and hr tags (orachk)
- Added index.htm prefixes to Health, Errors and Warnings (orachk)

* Tues March 1 2016 Tom Lisjac <tom.lisjac> 1.1b3
- Added -a command for cron driven healthcheck reports
- Fixed several 3.4 version detect issued
- Added additional detail to healthcheck ntp output
- Added -M to select alternate CSS for html reports (orachk)
- Added index.htm to html # indexes so table could be broken out (orachk)
- Added <!-- nav_start --> and end tags around cluview nav table (orachk)
- Improved high contrast css for -M1 option (orachk)

* Mon Sept 15 2015 Tom Lisjac <tom.lisjac> 1.0.2
- Added numa and additional server side checks
- Added xml manager dump for 3.2 to 3.3
- Temporarily removed hyperthreading for further refinements

* Mon Jul 20 2015 Tom Lisjac <tom.lisjac> 1.0.1
- Added detection for hyperthreading and additional cpu metrics

* Thu Apr 2 2015 Tom Lisjac <tom.lisjac> 1.0.0
- Vectored the -A command to do -H on generic linux
- Fixed pre-check with quotes around: [ -n "$SOSREPORT" ] 
- Added missing bracket to cascaded virt relops

* Fri Mar 20 2015 Tom Lisjac <tom.lisjac> 0.9.5
- Increased MAXLEN in merge.sh from 25 to 150K (thanks: Mary Mcgrath)
- Added relevant support note references to script header

* Wed Nov 19 2014 Tom Lisjac <tom.lisjac> 0.9.4
- Removed required parameter from getopts for -S and -D
- Added -k for kill ansi colors. Moved quick healthcheck to -H
- Reintroduced -e for APPSCAN
- Updated help and usage to reflect command and option changes

* Sat Nov 1 2014 Tom Lisjac <tom.lisjac> 0.9.0
- Forked vmpinfo 2.2-4 to vmpscan to avoid confusion with vmpinfo3
- Added -A, -D and -S code from vmpscan
- Changed vmpinfo S command to U and D to E for vmpscan compatibility

</man.rpmspec>

<script.mergewarning>
WARNING: This report has not been fully expanded with merge.sh. The clusterview
report and key diagnostic data will not be available until this is completed.

Data for the /proc /var and /etc directories and sos report (if requested) is
compressed in the archives directory. That data is expanded and the clusterview
report generated by running the merge.sh script in the directory where the main
report archive is located.

The merge.sh script is packaged with each vmpscan report archive. If the
merge.sh script is not present, decompressing one of the report archives will 
restore it. Successfully running merge.sh will make this file disappear.
until merge.sh has been run
</script.mergewarning>

<man.contributors>
# Thanks to the following contributors:
#
#   Steve Bartholomew  Verizon
#   Martin Foster      Pacnet
#   Wim Coekaerts      Oracle
#   Michael Chan       Oracle
#   Rich Busenbark     Oracle
#   Ozgur Yuksel       Oracle
#   Vishal Bhatia      Oracle
#
#   And my wife Viki for her constant encouragement and endless patience! :)
</man.contributors>

Wim's script for dumping the 2.2 VM Manager database
<scripts.mgrdump>

set serveroutput on format wrapped 

CREATE OR REPLACE PROCEDURE LIST_SP  AS 

begin
  DBMS_OUTPUT.ENABLE(1000000);
-- top loop is the server pool list
  dbms_output.put_line('Server Pools :');
  dbms_output.put_line('--------------');
  dbms_output.put_line(' ');

  
  FOR r IN (SELECT site_id, site_name,ha_enable,description, virtual_IP 
            FROM ovs_site)
  LOOP -- SP
    dbms_output.put_line('SP : '||r.site_name);       
    dbms_output.put_line('  HA mode     : ' || r.ha_enable); 
    dbms_output.put_line('  Virtual IP  : ' || r.virtual_ip);
    dbms_output.put_line('  Description : ' || r.description);
    -- FOR f IN (select sys_value_name, value, digital from ovs_sys_value)
    -- LOOP -- sysval
    -- dbms_output.put_line('  '||f.sys_value_name ||' : ' || f.value || f.digital);
    -- END LOOP SYSVAL;
    
    dbms_output.put_line(' ');
    dbms_output.put_line('     Servers :');

-- second loop is for the servers in a server pool

    FOR x IN (SELECT server_name,ip,location,status, comments,server_type, cpu_num,
              mem_amount
              FROM ovs_server WHERE site_id = r.site_id)
    LOOP -- SRV
    dbms_output.put_line('         Server : '|| x.server_name);
    dbms_output.put_line('               host/ip        : ' || x.ip);
    dbms_output.put_line('               Memory         : ' || x.mem_amount);
    dbms_output.put_line('               # CPUs         : ' || x.cpu_num);
    dbms_output.put_line('               description    : ' || x.location || ' ' || x.comments);
    dbms_output.put_line('               server roles   : ' || x.server_type);
    dbms_output.put_line('               Status         : ' || x.status);
    END LOOP SRV;
    dbms_output.put_line(' ');
-- third loop is VMs in a server pool

    dbms_output.put_line('     Virtual Machines :');
    FOR y IN (SELECT IMG_ID, IMG_NAME, STATUS, LOCATION, SITE_ID,PARENT_IMG, UUID 
                FROM ovs_vm_img WHERE site_id = r.site_id and parent_img <> 0)
    LOOP -- VMS
    dbms_output.put_line('         Virtual Machine      : '|| y.img_name);
    dbms_output.put_line('               Configuration  :');
    dbms_output.put_line('                  Status      : ' || y.status);
    dbms_output.put_line('                  Description : ' || y.location);
    dbms_output.put_line('                  UUID        : ' || y.uuid);
    
-- subloop in VMs for VM specific data
      
      FOR a IN (SELECT ID, VM_OS, VM_USER, VM_PASSWORD, COMMENTS, VM_MEM, 
                  CPU_NUMBER, VT_TYPE, IMG_ID, HA_ENABLE, BOOT_DEVICE
                  FROM OVS_VM_GEN_INFO WHERE IMG_ID = y.img_id)
      LOOP -- generic info
         dbms_output.put_line('                  VM OS       : ' || a.vm_os);
         dbms_output.put_line('                  Description : ' || a.comments);
         dbms_output.put_line('                  VM Memory   : ' || a.vm_mem);
         dbms_output.put_line('                  VM CPUs     : ' || a.cpu_number);
         dbms_output.put_line('                  HA mode     : ' || a.HA_ENABLE);
         dbms_output.put_line('                  Boot Device : ' || a.boot_device);
      
      END LOOP GENERIC;

 -- DISKS     
      dbms_output.put_line('               Virtual Disks  :');
      FOR z in (SELECT ovs_virtual_disk.vd_name,ovs_vd_img.front, ovs_vd_img.status,
                       ovs_virtual_disk.vd_size
                from ovs_virtual_disk, ovs_vd_img
                where ovs_vd_img.img_id=y.img_id 
                      and ovs_vd_img.vd_id = ovs_virtual_disk.vd_id 
                      order by ovs_vd_img.id)
      LOOP -- disks
      dbms_output.put_line('                  Disk        : ' || z.vd_name);
      dbms_output.put_line('                    Status    : ' || z.status);
      dbms_output.put_line('                    Type      : ' || z.front);
      dbms_output.put_line('                    Size      : ' || z.vd_size);
      END LOOP DISKS;      
      
-- VIFS
      dbms_output.put_line('               Virtual NICs   :');
      FOR z in (SELECT network_name, ip_type, network, dev_name, status
                from ovs_vm_network
                where img_id=y.img_id                   
                      order by network_id)
      LOOP -- nics
      dbms_output.put_line('                  VIF         : ' || z.network_name);
      dbms_output.put_line('                    Status    : ' || z.status);
      dbms_output.put_line('                    Type      : ' || z.ip_type);
      dbms_output.put_line('                    MAC Addr  : ' || z.dev_name);
      dbms_output.put_line('                    Bridge    : ' || z.network);
      END LOOP NICS;      
      
 -- ISOs
      dbms_output.put_line('               Assigned ISO   :');
      FOR q in (SELECT ovs_resource.resource_name, ovs_resource.group_name,
                ovs_resource.resource_file_name, ovs_resource.comments
                from ovs_resource,ovs_cdrom,ovs_cdrom_resource
                where ovs_cdrom.img_id=y.img_id and
                      ovs_cdrom_resource.resource_id = ovs_resource.resource_id
                      and ovs_cdrom_resource.cdrom_id = ovs_cdrom.cdrom_id)
      LOOP -- ISOs
      dbms_output.put_line('                  ISO name    : ' || q.resource_name);
      dbms_output.put_line('                    Group     : ' || q.group_name);
      dbms_output.put_line('                    File name : ' || q.resource_file_name);
      dbms_output.put_line('                    Comment   : ' || q.comments);

      END LOOP ISOs;      
           
    END LOOP VMS;
    dbms_output.put_line(' ');
-- Template loop
    dbms_output.put_line('     Templates :');
    FOR y IN (SELECT IMG_ID, IMG_NAME, STATUS, LOCATION, SITE_ID,PARENT_IMG, UUID 
                FROM ovs_vm_img WHERE site_id = r.site_id and parent_img = 0)
    LOOP -- templates
    dbms_output.put_line('         Template : '|| y.img_name);
    dbms_output.put_line('               Configuration  :');
    dbms_output.put_line('                  Status      : ' || y.status);
    dbms_output.put_line('                  Description : ' || y.location);
    dbms_output.put_line('                  UUID        : ' || y.uuid);
    
    -- subloop in VMs for VM specific data

      
      FOR a IN (SELECT ID, VM_OS, VM_USER, VM_PASSWORD, COMMENTS, VM_MEM, 
                  CPU_NUMBER, VT_TYPE, IMG_ID, HA_ENABLE, BOOT_DEVICE
                  FROM OVS_VM_GEN_INFO WHERE IMG_ID = y.img_id)
      LOOP -- generic info
         dbms_output.new_line;
         dbms_output.put_line('                  VM OS       : ' || a.vm_os);
         dbms_output.put_line('                  Description : ' || a.comments);
         dbms_output.put_line('                  VM Memory   : ' || a.vm_mem);
         dbms_output.put_line('                  VM CPUs     : ' || a.cpu_number);
         dbms_output.put_line('                  HA mode     : ' || a.HA_ENABLE);
         dbms_output.put_line('                  Boot Device : ' || a.boot_device);
      
      END LOOP GENERIC;

-- template Virtual Disks      
      dbms_output.put_line('               Virtual Disks  :');
      FOR z in (SELECT ovs_virtual_disk.vd_name,ovs_vd_img.front, ovs_vd_img.status,
                       ovs_virtual_disk.vd_size
                from ovs_virtual_disk, ovs_vd_img
                where ovs_vd_img.img_id=y.img_id 
                      and ovs_vd_img.vd_id = ovs_virtual_disk.vd_id 
                      order by ovs_vd_img.id)
      LOOP -- disks
      dbms_output.put_line('                  Disk        : ' || z.vd_name);
      dbms_output.put_line('                    Status    : ' || z.status);
      dbms_output.put_line('                    Type      : ' || z.front);
      dbms_output.put_line('                    Size      : ' || z.vd_size);
      END LOOP DISKS;      
      
-- template VIFS

      dbms_output.put_line('               Virtual NICs   :');
      FOR z in (SELECT network_name, ip_type, network, dev_name, status
                from ovs_vm_network
                where img_id=y.img_id                   
                      order by network_id)
      LOOP -- nics
      dbms_output.put_line('                  VIF         : ' || z.network_name);
      dbms_output.put_line('                    Status    : ' || z.status);
      dbms_output.put_line('                    Type      : ' || z.ip_type);
      END LOOP NICS;      
-- ISOs
      dbms_output.put_line('               Assigned ISO   :');
      FOR q in (SELECT ovs_resource.resource_name, ovs_resource.group_name,
                ovs_resource.resource_file_name, ovs_resource.comments
                from ovs_resource,ovs_cdrom,ovs_cdrom_resource
                where ovs_cdrom.img_id=y.img_id and
                      ovs_cdrom_resource.resource_id = ovs_resource.resource_id
                      and ovs_cdrom_resource.cdrom_id = ovs_cdrom.cdrom_id)
      LOOP -- ISOs
      dbms_output.put_line('                  ISO name     : ' || q.resource_name);
      dbms_output.put_line('                   group       : ' || q.group_name);
      dbms_output.put_line('                   File name   : ' || q.resource_file_name);
      dbms_output.put_line('                   Comment     : ' || q.comments);

      END LOOP ISOs;           
      
    END LOOP TEMPLATES;
    
-- Serverpool wide shared disk images
    dbms_output.put_line(' ');
    dbms_output.put_line('     SP shared Disks :');
    FOR c IN (SELECT vd_name, vd_size, status, comments 
                FROM ovs_virtual_disk WHERE site_id = r.site_id 
                and sharable = 'Sharable')
    LOOP -- SHARED
    dbms_output.put_line('         Shared Disk : '|| c.vd_name);
    dbms_output.put_line('               Status         : '|| c.status);
    dbms_output.put_line('               Size           : '|| c.vd_size);
    END LOOP SHARED;
dbms_output.put_line(' ');
-- server pool wide ISO images

    dbms_output.put_line('     SP ISO images :');
    FOR i IN (SELECT resource_name,group_name, resource_file_name, status,
                comments, mounted
                FROM ovs_resource WHERE site_id = r.site_id)           
    LOOP -- SPISOs
    dbms_output.put_line('         ISO Name  : '|| i.resource_name);
    dbms_output.put_line('               Group          : '|| i.group_name);
    dbms_output.put_line('               Filename       : '|| i.resource_file_name);
    dbms_output.put_line('               Description    : '|| i.comments);
    dbms_output.put_line('               Mounted        : '|| i.mounted);
    dbms_output.put_line('               Status         : '|| i.status);
    END LOOP SPISOs;    
    
    
  dbms_output.put_line(' ');
  END LOOP SP;
  
-- dump a list of active tasks

  dbms_output.put_line('Active Tasks : ');
  dbms_output.put_line('--------------');
  
  
  FOR i in (SELECT TASK_ID, STATUS, TABLE_NAME, RES_ID, TASK_UUID FROM OVS_TASK)
  LOOP -- tasks
  dbms_output.put_line('Task ID   : ' || i.TASK_ID);
  dbms_output.put_line('   STATUS : ' || i.STATUS);
  dbms_output.put_line('   Action : ' || i.TABLE_NAME);
  dbms_output.put_line('   Res ID : ' || i.RES_ID);
  dbms_output.put_line('   UUID   : ' || i.task_uuid);
  END LOOP tasks;
END LIST_SP;
/

execute list_sp();

exit
</scripts.mgrdump>

# merge and clean scripts

<scripts.merge>
  MAXLEN="150000"
  v="vmpdata"  # Location of vmpscan private files in each report directory
  batch="0"    # default asks the user if it's ok to proceed... -b turns this off
  ignoreerrors=""
  reportdirs="" # report directories created from expanded archives
  scopes=""; keysfn=""; datafn=""; keys="" # vars for building the clusterview
  numreports="0" # number of host reports
  shopt -s nullglob   # omit the . and .. when globbing
  cluvu="" # html accumulator for cluview nav column
  mergeall="" # only merge key data summary by default... merge all with -a
  skipexpand="0" # Just regenerate the cluvue... don't look for archives to expand
  keepperms=""; oldver=""; skiphtml=""; skipdb=""; tblname="vmpmerge"; quieter=""
  exportdb=""; errors="0"

  function err() { let '++errors'; }

  function VersionCheck() {
    VMPARCVER=""
    [ -f $1/$v/vmpver.txt ] && source $1/$v/vmpver.txt
    if [ -z "$VMPARCVER" ] || [ "$VMPARCVER" != "$VER" ]; then return 1; else return 0; fi
  }
  
  function ValidateReportDirs() {
    reportdirs=""
    local rawdirs=`find . -maxdepth 1 -type d|egrep '[-\_]vmpscan'|grep -v .damaged|cut -d'/' -f2|sort`
    for i in $rawdirs; do
      if VersionCheck $i; then reportdirs="$reportdirs $i";
      else
        oldver="1"; 
        if [ -n "$1" ]; then
          echo "Archive $i is broken or incompatible with version $VER"
          if mv $i $i.damaged; then echo " \_Renamed to $i.damaged and skipping";
          else echo "===> Merge could not rename to $i.damaged"; echo "Please remove or delete manually"
          fi
        fi
      fi
    done
  }
  
  function ExpandArchives() {
    local newarcs="" f="" msg=""
    for i in *[-\_]vmpscan.tar.gz; do # either - or _vmpscan are ok for the archive filename... not for the dir name
      dirname=`tar -tzmf $i 2>err.txt | grep vmpscan.conf | cut -d'/' -f1` # get the real vmpscan dir name
      if [ -s "err.txt" ]; then
        err; echo -n "---> Archive $i is damaged:"; cat err.txt
        if mv $i $i.damaged; then echo "===> Renamed to $i.damaged and skipping"; echo
        else err; echo "===> Merge could not rename to $i.damaged"; echo "     Please remove or delete manually"
        fi
        continue
      elif [ -d "$dirname" ] && [ -f $dirname/$v/vmpscan.htm.gz ]; then # existing dir... don't expand
        echo "Expanded report found: $dirname"
      elif [ "$dirname.tar.gz" != "$i" ]; then # if the file and dirnames don't match, try to rename the file
        if mv $i $dirname.tar.gz; then echo "Renamed $i to $dirname.tar.gz"; newarcs="$newarcs $dirname.tar.gz"
        else # must be permissions... warn the user and continue the merge
          echo
          echo "WARNING: $i does not conform to VMPScan" 
          echo "conventions where the file and directory names must match. The attempt to"
          echo "rename it failed but the merge of this archive can continue. Please rename"
          echo "it to $dirname.tar.gz before running the clean.sh"
          echo "script or a duplicate, correctly named archive will be created"
          echo
          err; newarcs="$newarcs $i" # new, malformed archive: unable to rename... settle for it
        fi
      else echo "New report found: $i"; newarcs="$newarcs $i" # new archive properly named
      fi
      let '++numreports'
    done
    [ -f err.txt ] && rm -f err.txt
    if [ -z "$newarcs" ] && [ -f index.htm ]; then 
      echo; echo "No new compressed vmpscan archives found... nothing to do. If you want to" 
      echo "reset or regenerate the Clusterview, run clean.sh and then merge.sh again."; echo
      exit 1
    fi
    echo; echo "$numreports host reports have been found. Ready to process and merge."; echo
    if [ -z "$quieter" ]; then 
      if [ -z "$mergeall" ]; then
        echo "Note: By default, Clusterview report will contain only KEY node data parameters."
        echo "To merge ALL node data, abort and run merge.sh with the -a switch: ./merge.sh -a"
        echo "This process can take several minutes per node"
        echo 
      else 
        echo "Clusterview report will contain a full merge of ALL node parameter data"
        echo "This process can take several minutes per node. For a quick merge of" 
        echo "just KEY data, abort and run merge.sh with the -k switch: ./merge.sh -k"
        echo 
      fi
    fi  
    if [ "$batch" = "0" ]; then
      read -p "Continue? Y/N:"; if [[ $REPLY != "Y" && $REPLY != "y" ]]; then echo "Aborting"; exit 1; fi
    fi
    for i in $newarcs; do 
      echo -n "Expanding New Report Archive $i:"; newdir=`tar -xvzmf $i | grep vmpscan.conf| cut -d'/' -f1`
      cd $newdir; 
      for j in archives/*.tar.gz; do 
        if tar -xzmf $j; then echo -n "."; else
          echo "-->Archive $j is damaged... continuing merge but skipping this file"
          echo "-->Important data may not be available"; err
        fi
      done
      if [ -f vmpdata/sosfn.txt ]; then
        sosfn=`cat vmpdata/sosfn.txt`
        if [ -f archives/$sosfn ]; then
          local sosft=`file -b archives/$sosfn|cut -d' ' -f1`
          echo; echo -n " \_Expanding $sosft sos report $sosfn:"
          cd sos
          case $sosft in
            bzip2) tar -xjf ../archives/$sosfn;;
             gzip) tar -xzf ../archives/$sosfn;;
               xz) if which xz >/dev/null 2>&1; then tar --use-compress-program xz -xf ../archives/$sosfn
                   else
                     echo; echo "Error: the xz decompressor was not found on this system"
                     false
                   fi;;
          esac
          if [ "$?" != "0" ]; then
            err; echo; echo "-->Error in processing the sos report archive... continuing with merge merge"
          fi
          cd ..
        fi
      fi 
      cd ..; if [ -z "$keepperms" ]; then chmod -R 755 $newdir; fi
      echo " ok"
    done   
    echo
    ValidateReportDirs 1
    if [ -n "$oldver" ]; then
      echo
      echo "WARNING: Some of the report archives are damaged, incomplete or were"
      echo "created with an older version of VMPScan. These archives have all"
      echo "been expanded, but the older reports have not been merged into the"
      echo "Clusterview (index.htm). Please review these node reports manually or"
      echo "request a rescan of these systems with VMPScan $VER."; echo; err
      if [ -z "$ignoreerrors" ]; then read -p "Press Enter to continue or control-c to abort"; return 1; fi
    fi  
    if [ -f "index.htm" ]; then rm -f index.htm; fi
}

  function GeneratePortalHeader() {
    local repdate="$( date +%F\ %H\:%M\:%S)"; local cludir=`pwd`; cludir=${cludir##*/}
    if ! [ -f "index.htm" ]; then 
      cp $i/$v/cluhead.htm index.htm
      cluvutitle="Cluview:$cludir-$repdate"; sed -i 's|\(<!--#clutitle-->\)|'"$cluvutitle"'|g' index.htm
      { echo "<!-- nav_start -->" # for orachk
        echo "<br>$numreports node report generated on: $repdate&nbsp;&nbsp;&nbsp;"
        echo "Report Name:&nbsp;$cludir-$repdate<br>"
      if [ -n "$oldver" ]; then      
        err; echo "Warning: Some of the report directory archives were not compatible with VMPScan $VER<br>"
      fi
      echo "<br><div id=\"nav2\">"   
      echo "<table border=\"1\" cellpadding=\"10\" role=\"presentation\">"
      echo "<caption>HostView (Click hostname for all node parameters)</caption>"; } >> index.htm
    fi
  }

  function GenerateHostviewTable() {
    cluvu="<td><span class=\"tagh\"><a href=\"../index.htm\">CluView</a></span><br>"
    for i in $reportdirs; do
      echo -n "Creating HostView for ${i%-*}:"
      cat "$i/$v/cluview.htm" >> index.htm
      { cat "$i/$v/syshealthclu.htm"; cat "$i/$v/errorclu.htm"; cat "$i/$v/warnclu.htm"; } >> portalend.htm
      let x="${#i}-26"; hn=`expr substr $i 1 $x` # isolate hostname with possible dashes... 26=timestamp len
      cluvu=" $cluvu<a href=\"../$i/vmpscan.htm\">$hn</a><br>"
      if [ -f $i/$v/vmpscan.htm.gz ]; then # merging an existing directory... freshen the vmpscan.htm
        rm -f $i/vmpscan.htm; cp $i/$v/vmpscan.htm.gz $i; gunzip $i/vmpscan.htm
      else # save pristine vmpscan.htm
        gzip -c $i/vmpscan.htm > $i/$v/vmpscan.htm.gz
      fi
      echo " ok" 
    done
    echo "</table></div><br>" >> index.htm
    cluvu="$cluvu</td>"
    echo; echo -n "Updating node report headers:"
    for i in $reportdirs; do
      sed -i 's|\(<!--#cluster-->\)|'"$cluvu"'|g' $i/vmpscan.htm
      echo -n "."
    done
    echo " ok"
  }
  
  function MakeKeyNavTable() {
    local prod=""; > tmpkeys; > allkeys; tmpk=""; scopes=""
    local dblink="&nbsp;&nbsp;&nbsp;&nbsp;<a href=".">Clusterview Root</a>"
    if [ -n "$1" ]; then keysfn="allkeys"; datafn="alldata"; else keysfn="sumkeys"; datafn="sumdata"; fi
    for i in $reportdirs; do
      for j in $i/vmpdata/$keysfn.*; do
        if [[ "${j#*.}" = "apps" || "${j#*.}" = "prod" ]]; then prod=" ${j#*.}" # force apps and prod last
        else scopes="$scopes ${j#*.}"
        fi
        cat $j >> tmpkeys
      done 
    done
    { cat tmpkeys | sort -k1,1; echo; } > sortedkeys; rm -f tmpkeys

    curkey=""; failedkey="0"; oldifs=$IFS; IFS=$'\n'; > allkeys
    while read thisline; do
      dat=`echo $thisline | cut -d' ' -f1,2`; thiskey=${dat%% *}; thisres=${dat#* }
      if [ "$thiskey" != "$curkey" ]; then # new key
        if [ -z "$quieter" ]; then echo -n "."; fi
        if [ -z "$curkey" ]; then curkey=$thiskey
        else echo "$curkey $curres" >> allkeys
        fi
        curkey=$thiskey; curres=$thisres; # curdata="${thisline#* $thisres }"
      fi
      if [ "$thisres" = "1" ]; then curres="1"; fi
    done < sortedkeys
    rm -f sortedkeys; IFS=$oldifs
    scopes=`for i in $scopes; do echo "$i"; done|sort -u`$prod
 
   {
    echo "<div id=\"nav3\"><table border=\"1\" cellpadding=\"10\" role=\"presentation\">"
    if [ -f vmpmerge.sqlite ]; then
      dblink="$dblink&nbsp;&nbsp;&nbsp;&nbsp;<a href="vmpmerge.sqlite">Clusterview Database</a>"
    fi
    echo "<caption>ClusterView (Key Parameters)$dblink</caption><tr>"
    for scope in $scopes; do echo "<th>$scope</th>"; done; echo "</tr><tr>"
   } >> index.htm
    keytags=""
    for scope in $scopes; do
      # echo -n "..<$scope>"
      echo "<td VALIGN=\"top\">" >> index.htm
      while read k r; do      
        if [ "${k%%.*}" = "$scope" ]; then
          if [ "$r" = "0" ]; then 
            echo "<a href=\"index.htm#$k\"><span class=\"tag1\">${k#*.}</span></a><br>" >> index.htm    # added index.htm for orachk formatting
          else  
            echo "<a href=\"index.htm#$k\"><span class=\"reserr\">${k#*.}</span></a><br>" >> index.htm  # added index.htm for orachk formatting
          fi
        fi
      done < allkeys
      echo "</td>" >> index.htm
    done
    echo "</tr></table></div>" >> index.htm
    echo "<!-- nav_end -->" >> index.htm # for orachk
    echo "<br><hr>" >> index.htm
    keys=`cat allkeys|cut -d' ' -f1`; rm -f allkeys
  } 

  function GenerateKeyData() {
    local data=""
    
    function RemoveMergeWarning() { # merge complete... get rid of the warning text
      if [ -f $1/WARNING-README.TXT ]; then
        rm -f $1/WARNING-README.TXT
        sed -i 's/href=\"WARNING-README.TXT\">WARNING!/href=\".\">Root_Dir/g' $1/vmpscan.htm
      fi
    }

    function GetKeyData() { # $1=key $2=keydatafn
      local inx=`egrep -ba "<$1>|<\/$1>" $2`
      if [ "$?" != "0" ]; then echo X; return 1; fi   
      startinx=`echo $inx | cut -d' ' -f1 | cut -d: -f1`
      endinx=`echo $inx | cut -d' ' -f2 | cut -d: -f1`
      let startinx="$startinx+${#k}+3"; let len="$endinx-$startinx"
      if [ "$endinx" -gt "$startinx" ] && [ "$len" -lt "$MAXLEN" ]; then
        data=`dd skip=$startinx if=$2 bs=1 count=$len 2> /dev/null | expand`
        if [ -z "$data" ]; then data="no data"; fi
      else
        data=`echo "Data size exceeds $MAXLEN set in merge.sh\nUse link to view node report"`
      fi             
      return 0
    }
    
    function MakeKeyHeader() {
      echo "<br><a name=\"$1\"></a><div class="clu"><table border=\"1\" cellpadding=\"10\" role=\"presentation\">"
      echo "<caption><span class=\"clucap\"><a href=\"index.htm#$1\">$1</a></span>"  # added index.htm for orachk formatting
      echo "&nbsp;&nbsp;&nbsp;&nbsp;<a href="index.htm#top">Top</a></caption>"       # added index.htm for orachk formatting 
      echo "<tr><th>Node</th><th>Value</th><th>Op</th><th>Class</th><th>Time</th></tr>"
    } >> index.htm

    function MakeKeyRow() {
      let x="${#6}-26"; hn=`expr substr $6 1 $x` # extract hostname from directory
      if [ "${#data}" -gt "100" ] && [ "$numreports" -gt "1" ]; then 
        chksum="<br>Data cksum: `echo $data|sum|cut -d' ' -f1`"; else chksum=""
      fi 
      echo -n "<tr><td><a href=\"$6/vmpscan.htm#$hn.$1\">${6%-*}</a>$chksum</td><td><div class=\"cv\">"
      echo "$data" | egrep -v --regex=^#\|^$
      if [ "$2" = "0" ]; then res="<span class=\"resok\">ok</span>"
      else res="<span class=\"reserr\">fail</span>"
      fi
      echo -n "</div></td><td ALIGN=\"center\">$res</td><td>"; echo -n "$4"; echo "</td><td>$5</td></tr>"
    } >> index.htm
    
    prevscope=""; numkeys="0"; totalkeys="0";
    keycount=`echo $keys|wc -w`
    if [ -n "$mergeall" ]; then allparm="total"; else allparm="key"; fi
    echo; echo "Creating Clusterview Portal for $keycount $allparm node parameters from $numreports host reports"
    echo -n "(This operation is resource intensive and can take a long time)"
    for k in $keys; do
      scope=${k%%.*}
      if [ "$scope" != "$prevscope" ]; then 
        if [ -z "$prevscope" ]; then echo
        elif [ -z "$quieter" ]; then 
          echo; 
          echo "Done: $numkeys $prevscope key tables created - $totalkeys of $keycount complete"; numkeys="0"
        fi
        prevscope=$scope
        if [ -z "$quieter" ]; then echo; echo -n "Merging $allparm $scope parameters:"; fi
      fi
      MakeKeyHeader $k
      for d in $reportdirs; do
        if ! [ -f $d/$v/$keysfn.$scope ]; then echo -n "*" # flag that key was not found for this host
        else
          while read hk hr hf ht hc1 hc2; do
            if [ "$k" = "$hk" ]; then
              GetKeyData $k $d/$v/$datafn.$scope
              MakeKeyRow $hk $hr $hf "$hc1 $hc2" $ht $d  ; if [ -z "$quieter" ]; then echo -n "-"; fi
              break
            fi
          done < $d/$v/$keysfn.$scope
        fi
        RemoveMergeWarning $d
      done # reportdirs
      echo "</table></div>" >> index.htm
      let "++numkeys"; let "++totalkeys"
      if [ -z "$quieter" ]; then echo -n "-$totalkeys-"; fi
    done #keys
    if [ -z "$quieter" ]; then echo "|"; fi
    echo "Clusterview build complete: $totalkeys node parameters merged from $numreports host reports"
    mergesec=$((`date +'%s'` - MERGESTART)); mergemin=$((mergesec / 60)); mergesec=$((mergesec % 60))
    echo; echo "Merge operation completed in $mergemin minutes and $mergesec seconds"
    if [ "$errors" != "0" ]; then echo "---> Errors: $errors... please check console messages"; fi
    echo "Open index.htm in a browser to view the report"; echo
  }

  function MergeCluDB() {
    local roottb="" num="0"
    if ! which sqlite3 > /dev/null 2>&1 ; then echo "sqlite3 not found... skipping db cluster merge"; return 1; fi
    for i in $reportdirs; do
      if [ -s $i/vmpscan.sqlite ]; then
        if [ -z $roottb ]; then echo "Sqlite3 databases found... merging:"; fi
        echo -n "  $i/vmpscan.sqlite database: " 
        sqlite3 $i/vmpscan.sqlite 'pragma integrity_check' >/dev/null 2>&1
        if [ "$?" != "0" ]; then "Error in $i/vmpscan.sqlite... skipping"; err
        else
          if [ -z $roottb ]; then
            cp $i/vmpscan.sqlite vmpmerge.sqlite; roottb=$i
            sqlite3 vmpmerge.sqlite "alter table [$i] rename to $1"
            echo "ok"; let '++num'
          else
            sqlite3 vmpmerge.sqlite "attach '$i/vmpscan.sqlite' as tomerge;
              insert into [$1] select * from tomerge.[$i];
              detach database tomerge;"
            if [ "$?" = "0" ]; then
              echo "ok"; let '++num'
              # change inode to prevent db locks from fcntl(3, F_SETLK) call failures on nfs storage 
              cp vmpmerge.sqlite temp.sqlite; rm vmpmerge.sqlite; mv temp.sqlite vmpmerge.sqlite
            else echo "Error in $i/vmpscan.sqlite... merged db may be corrupt"; err
            fi
          fi
        fi
      fi
    done
    if [ "$num" = "0" ]; then echo "No hostview databases found"
    else echo "Done... $num node databases merged into vmpmerge.sqlite as table: $1"
    fi
    if [ "$num" != "0" ] && [ -n "$exportdb" ]; then
      echo ".dump" | sqlite3 vmpmerge.sqlite > $1.sql
      if [ "$?" = "0" ]; then echo "Merged database dumped to $1.sql"; fi
    fi
    echo
  }

  function MergeDB() {
    local roottn mergetn num="0"
    if ! which sqlite3 > /dev/null 2>&1 ; then echo "sqlite3 not found... exiting"; exit 1; fi
    if ! [ -s vmpmerge.sqlite ]; then echo "Root db vmpmerge.sqlite not found... exiting"; exit 1
    else
      sqlite3 vmpmerge.sqlite 'pragma integrity_check' > /dev/null 2>&1
      if [ "$?" != "0" ]; then "Error in vmpmerge.sqlite root db... exiting"; exit 1
      else
        roottn=`sqlite3 vmpmerge.sqlite .table`
        echo "Root database vmpmerge.sqlite ok: merge table name is $roottn"
        for i in $*; do
          sqlite3 $i 'pragma integrity_check' > /dev/null 2>&1 
          if [ "$?" != "0" ]; then echo "  Error in $i db... skipping"; continue; fi
          mergetn=`sqlite3 $i .table`
          echo -n "  Merging db $i table $mergetn: "
          sqlite3 vmpmerge.sqlite "attach '$i' as tomerge;
            insert into [$roottn] select * from tomerge.[$mergetn];
            detach database tomerge;"
          if [ "$?" = "0" ]; then
            echo "ok"; let '++num'
            # change inode to prevent db locks from fcntl(3, F_SETLK) call failures on nfs storage 
            cp vmpmerge.sqlite temp.sqlite; rm vmpmerge.sqlite; mv temp.sqlite vmpmerge.sqlite
          else echo "Error in $i... merged db may be corrupt"
          fi
        done
        echo "Done... $num databases merged into vmpmerge.sqlite as table: $roottn"
        if [ "$num" != "0" ] && [ -n "$exportdb" ]; then
          echo ".dump" | sqlite3 vmpmerge.sqlite > index.sql
          if [ "$?" = "0" ]; then echo "Merged database dumped to index.sql"; fi
        fi
      fi
    fi
  }

  function WriteCleanScript() { # Emit the clean.sh script
    echo 'function Usage() {'
    echo '  echo; echo clean.sh [options]'
    echo '  echo; echo "Cleanup and recover expanded report directory space for idle analysis sessions."'
    echo '  echo "This process will leave the report archives and merge.sh in place so the session"'
    echo '  echo "can be resumed at a later time by running merge.sh again. See the VMPScan manual"'
    echo '  echo " pages (vmpscan.sh -m) for more information about this process."'
    echo '  echo; echo "Options:"; echo'
    echo '  echo "  -b  Skips y/n dialog after report directories are listed for deletion"'
    echo '  echo "  -h  This help display"'
    echo '  echo "  -s  Save any changes to the archive before deleting report directory (default)"'
    echo '  echo "  -n  Delete report directories... do not check integrity or save changes to the archives"'
    echo '  echo "  -d  Clean but do not delete merged vmpmerge.sqlite database"'
    echo '  echo "  -q  Be quieter... suppress most normal messages"'
    echo '  echo; exit 1'
    echo '}'

    echo 'echo; save="1"; batch="0"; err="0"; savedb=""; quieter=""'
    echo 'while getopts "nshdbq" opt; do' 
    echo '  case "$opt" in h) Usage;; q) quieter="1";; s) save="1";; n) save="";; b) batch="1";; d) savedb="1";; *) Usage;; esac'
    echo 'done'
    echo 'if [ -z "$quieter" ]; then'
    echo '  if [ -z "$save" ]; then'
    echo '    echo "WARNING: No save option selected"'
    echo '    echo "Any data that has been added to the report directories will NOT be saved."'
    echo '    echo'
    echo '    echo "To save added data, abort and run clean.sh with the -s switch: ./clean.sh -s"'
    echo '    echo "This will refresh the archives and then delete the expanded directories"'
    echo '    echo'
    echo '  else' 
    echo '    echo; echo "Report archives will be updated from existing directories before deletion"'
    echo '    echo; echo "If no new data was added that should be saved or the directory data has been"'
    echo '    echo "modified or damaged, exit and re-run clean.sh with the -n option: ./clean.sh -n"'
    echo '    echo "The clean operation is also faster when the archives are not rebuilt"'
    echo '    echo'
    echo '  fi'
    echo 'fi'
    echo 'sessions=`find . -maxdepth 1 -type d|egrep [-\_]vmpscan|grep -v .damaged|cut -d'/' -f2|sort`'
    echo 'if [ -z "$sessions" ]; then echo "No session directories found to clean... exiting"; exit; fi'
    echo 'if [ -z "$quieter" ]; then echo "Reports found:"; echo "$sessions"; fi'
    echo 'if [ "$batch" = "0" ]; then'
    echo '  read -p "Continue? Y/N:";'
    echo '  if [[ $REPLY != "Y" && $REPLY != "y" ]]; then echo "Aborting"; exit 1; fi'
    echo 'fi'
    echo 'for i in $sessions; do'
    echo '  an="${i#*/}"'
    echo '  if ! [ -s $an.tar.gz ]; then'
    echo '    echo "---> Archive $an.tar.gz not found"; echo "===> Recreating from report directory $an"'
    echo '  fi'
    echo '  if [ -z "$save" ] && [ -s $an.tar.gz ]; then rm -rf $an'
    echo '  else'
    echo '    if [ -f $an/vmpdata/vmpscan.htm.gz ]; then'
    echo '      echo -n "Saving: $an"'
    echo '      rm -rf $an/var/* $an/etc/* $an/proc/* $an/sos/*'
    echo '      if [ -s $an.tar.gz ]; then mv $an.tar.gz $an.tar.gz.orig; fi'
    echo '      rm -f $an/vmpscan.htm; mv $an/vmpdata/vmpscan.htm.gz $an; gunzip $an/vmpscan.htm'  
    echo '      cp $an/vmpdata/mw.in $an/WARNING-README.TXT'
    echo '      cp $an/vmpdata/merge.sh ../$an'
    echo '      if tar -czf $an.tar.gz merge.sh $an; then'
    echo '        if [ -s $an.tar.gz.orig ]; then rm -f $an.tar.gz.orig; fi'
    echo '        echo " - ok"'
    echo '        rm -rf $an'
    echo '      else'
    echo '        if [ -s $an.tar.gz.orig ]; then mv $an.tar.gz.orig $an.tar.gz; fi'
    echo '        echo; echo "Archive error $?"'
    echo '        echo "Directories preserved and original archive data in $an.tar.gz"'
    echo '        echo "Continuing to next directory"; continue'
    echo '      fi'
    echo '    else'
    echo '      echo "Error: $an has not been merged: skipping without cleaning"'
    echo '      echo "Use the -n switch to override"'
    echo '      err="1"; continue'
    echo '    fi'
    echo '  fi'
    echo 'done'
    echo 'if [ "$err" = "0" ]; then'
    echo '  rm -f index.htm; rm -f clean.sh; msg="All"'
    echo '  if [ -z $savedb ] && [ -s vmpmerge.sqlite ]; then rm -f vmpmerge.sqlite; fi'
    echo 'else msg="Errors detected: Some"'
    echo 'fi'
    echo 'if [ -n "$quieter" ]; then echo "Cleanup complete"'
    echo 'else'
    echo '  if [ -n "$save" ]; then echo; echo "$msg archives have been update and directories deleted."'
    echo '  else echo; echo "Original archives have been preserved and directories deleted."'
    echo '  fi'
    echo '  echo "Run merge.sh again to regenerate the environment"; echo'
    echo 'fi'
    echo
  } >> clean.sh
  
  function Usage() {
    echo "merge.sh [options]"
    echo
    echo "Expands any VMPScan report archives found in the same directory and merges"
    echo "data from the individual nodes into a Clusterview portal. See the VMPScan" 
    echo "manual pages (vmpscan.sh -m) for more information about this process." 
    echo; echo "Options:"; echo
    echo "  -a  Merge all keys... takes a long time but includes every node parameter in the Clusterview"
    echo "  -b  Skips y/n dialog after archives are listed"
    echo "  -d  Merge database only: skips html report creation and deletes report directories"
    echo "  -h  This help display"
    echo "  -i  Ignore version mismatch errors"
    echo "  -k  Only merges selected keys that are commonly referenced (default)"
    echo "  -m <db file list> Merge vmpmerge.sqlite with one or more other vmpscan.sqlite db's"
    echo "  -p  Do not change permissions of report files and directories to 755"
    echo "  -s  Skip looking for new archives to expand... regenerate the clusterview"
    echo "  -t  Table name for merged database... defaults to vmpmerge"
    echo "  -q  Be quieter... suppresses most of the verbose progress indicators"
    echo "  -x  Export database as sql dump after the merge... file is index.sql"
    echo
    exit 1
  }
  
  while getopts "ahibdnkm:pst:qx" opt; do 
    case "$opt" in
      a) mergeall="1";; b) batch=1;; h) Usage;; i) ignoreerrors="1";;
      k) mergeall="";; s) skipexpand="1";; p) keepperms="1";;
      d) skiphtml="1";; n) skipdb="1";; t) tblname="$OPTARG";;
      q) quieter="1";; x) exportdb="1";;
      m) shift; MergeDB $*; exit 0;;
      *) Usage;;
    esac
  done

  WriteCleanScript
  chmod 744 clean.sh
  if [ "$skipexpand" = "0" ]; then ExpandArchives; fi
  MERGESTART=`date +'%s'` # time the merge
  ValidateReportDirs ""
  if [ -z "$skipdb" ]; then MergeCluDB "$tblname"; fi
  if [ -n "$skiphtml" ]; then quieter="1"; ./clean.sh -dbnq
  else
    GeneratePortalHeader
    GenerateHostviewTable
    echo -n "Building Clusterview Navigation Table:"
    MakeKeyNavTable "$mergeall"
    echo " ok"
    GenerateKeyData  
    cat portalend.htm >> index.htm; rm -f portalend.htm
  fi
  echo
  #End of merge.sh

</scripts.merge>

# script.md5 must be last in the file
<script.md5>

</script.md5>
