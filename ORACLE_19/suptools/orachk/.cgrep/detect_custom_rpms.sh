#!/bin/bash
#
# detect_custom_rpms.sh
#
# Copyright (c) 2014, 2016, Oracle and/or its affiliates. All rights reserved.
#
# NAME
#   detect_custom_rpms.sh
#
# DESCRIPTION
#   Detect package customization on 11.2.3.3.0 or later Linux Exadata
#   database servers.
#
#   Report packages that have been:
#   - upgraded to a different version from what was supplied with Exadata
#   - installed in addition to those supplied with Exadata
#
#   Some additional packages are expected to exist and are not considered
#   as a customization; hence, they are not reported.
#
#   The main driver to know what is "expected" is either the exact rpm or
#   the minimum rpm, their required capabilities and versions, and the 
#   packages that supply those capabilities.
#
# MODIFIED    YY-MM-DD
#   rkunders  15-02-26  Added tzdata to noReportAdditionalRpms.
#                       Due to tzdata is listed in 'minimum' for 121111
#   dutzig    15-02-23  Dropped arch from rpm queries for glibc. 
#                       Not printing additional packages anymore when they are expected
#   dutzig    14-10-14  Due to bash3.2+ change, modify rpmlib check (see bash compat31)
#   dutzig    14-10-14  Add OVS support (sun-vm, sun-ovs) - bug 19815957
#   dutzig    14-03-27  Add missing capability check and debug mode
#   dutzig    14-03-26  Initial version
#
version=1.4

# This code block breaks this script if run standalone on versions < 12.1.2
# This script is only called by dbnodeupdate, which handles this scenario
#
# Source required Exadata environment file
if [ -e /opt/oracle.cellos/exadata.img.env ]; then
  source /opt/oracle.cellos/exadata.img.env
  if [ $? -ne 0 ]; then
    echo "[ERROR] Unable to source required Exadata environment file, exadata.img.env."
    exit 1
  fi
else
  echo "[ERROR] Required Exadata environment file, exadata.img.env, not found."
  exit 1
fi

function debug {
  [[ -z $debugOutfile ]] && return

  # make sure each line starts with DEBUG
  echo "$*" | while read; do
    echo "DEBUG: $(/bin/date +'%F %T %Z') ${FUNCNAME[1]}: $REPLY" >> $debugOutfile
  done
}

verbose=no
usage="\
Usage:
$0 [-v][-d]
where
  -v : verbose mode
  -d : turn on debugging
"

while getopts vd OPTION; do
  case $OPTION in
    v)
        verbose=yes
        ;;
    d)
        debugOutfile=${EXADATA_IMG_TMP}/_exa_debug.out
        echo "Debug mode enabled.  Debug output appended to $debugOutfile"
        echo
        ;;
    :)
        echo "Option $OPTARG needs a value"
        echo "$usage"
        exit 1
        ;;
    \?)
        echo "Invalid option $OPTARG"
        echo "$usage"
        exit 1
        ;;
  esac
done
shift $(($OPTIND-1))

debug '=============================================================================='
debug "Starting $0 version $version - options: verbose=$verbose"

if [[ ! -e /opt/oracle.cellos/ORACLE_CELL_OS_IS_SETUP ]]; then
  echo "This is not an Exadata system.  /opt/oracle.cellos/ORACLE_CELL_OS_IS_SETUP does not exist."
  exit 1
fi

if [[ -e /opt/oracle.cellos/ORACLE_CELL_NODE ]]; then
  echo "Exadata RPM customization check is only applicable to database servers, not Exadata Storage Servers."
  exit 1
fi

shortExaVersion=$(/opt/oracle.cellos/imageinfo -ver|cut -d. -f1-4|tr -d '.')
if [[ $shortExaVersion -lt 11233 ]]; then
  echo "Exadata RPM customization check available only for Exadata 11.2.3.3 and higher."
  exit 1
fi



# temporary files - all are removed before exit
depRpmList=${EXADATA_IMG_TMP}/_exa_deplist_$$.txt
missingDepList=${EXADATA_IMG_TMP}/_exa_depsmissing_$$.txt
installedRpmList=${EXADATA_IMG_TMP}/_exa_rpmsinstalled_$$.txt
packageUpgradeList=${EXADATA_IMG_TMP}/_exa_rpmsupgraded_$$.txt
cacheFile=${EXADATA_IMG_TMP}/_exa_rpmcache_$$.txt

rm -f $depRpmList $installedRpmList $packageUpgradeList $cacheFile $missingDepList
[[ ! -f $cacheFile ]] && touch $cacheFile

# this list of RPMs may be installed - if so, do not report
noReportAdditionalRpms=(\
  exadata-sun-computenode-exact
  exadata-sun-computenode-minimum 
  exadata-hp-computenode-exact
  exadata-hp-computenode-minimum 
  exadata-sun-ovs-computenode-exact
  exadata-sun-ovs-computenode-minimum 
  exadata-sun-vm-computenode-exact
  exadata-sun-vm-computenode-minimum 
  uln-internal-setup
  cvuqdisk
  gpg-pubkey 
  up2date
  wget
  yum-downloadonly
  tzdata
)

# this list of RPMs may be installed - if so, report but mark as acceptable
markedAdditionalRpms=(\
)

# special consideration for DBLRA
dbmXmlFile=/opt/oracle.SupportTools/onecommand/databasemachine.xml
if [[ -e $dbmXmlFile ]]; then
  if grep -asq '<BACKUP_APPLIANCE>true</BACKUP_APPLIANCE>' $dbmXmlFile; then
    debug "This is DBLRA"
    noReportAdditionalRpms+=(QConvergeConsoleCLI)
  fi
fi

grepNoReport=$( IFS=$'|'; echo "${noReportAdditionalRpms[*]}" )
grepMarked=$( IFS=$'|'; echo "${markedAdditionalRpms[*]}" )

computeNodePackage=UNKNOWN
computeNodeRpm=''
packageUpgradeListCount=UNKNOWN
customRpmListCount=UNKNOWN

# Detect the computenode rpm installed
for hw in sun sun-ovs sun-vm hp; do
  for pkg in exact minimum; do
    if rpm=$(rpm -q exadata-$hw-computenode-$pkg); then
      computeNodePackage=$pkg
      computeNodeRpm=exadata-$hw-computenode-$pkg
      break 2
    fi
  done
done
debug "computenode package in effect = $computeNodePackage $computeNodeRpm"

if [[ $computeNodePackage == exact ]]; then
  computeNodePackageState=locked
elif [[ $computeNodePackage == minimum ]]; then
  computeNodePackageState=unlocked
fi

if [[ -n $computeNodeRpm ]]; then

  # Process list of dependent capabilities from computenode rpm
  # This loop will create two files:
  #  $packageUpgradeList - RPMs that provide a required capability, but at 
  #                        different version than computenode package specifies
  #  $depRpmList         - RPMs that provide required capability at the
  #                        version specified in computenode package
  while read depCur equality requiredDepVersion; do

    debug "> working on capability $depCur version $requiredDepVersion"
    
    # skip rpmlib(*) capabilities - those capabilities satisfied implicitly by rpm
    skipRpmlib='^rpmlib\('
    if [[ $depCur =~ $skipRpmlib ]]; then
      debug "> skip rpmlib capabilities"
      continue
    fi

    foundDepRpm=yes
    foundRequiredDepVersion=no

    while read; do
          
      # no package provides this capability - this is incorrect configuration
      if [[ "$REPLY" =~ "no package provides" ]]; then
        debug ">> no package provides this capability - package configuration is unexpected"
        foundDepRpm=no
        echo "$depCur $equality $requiredDepVersion" >> $missingDepList
        break
      fi

      set -- $REPLY
      providesDepName=$1 providesDepPackage=$2
      
      debug ">> capability $providesDepName provided by package $providesDepPackage"
      
      # For each package that provides the dep, match against the capability version
      #   to know which is actually satisfying the dependency.
      # Note the following about packages and what capabilities they provide
      # - a single package may provide multiple versions of the same capability (e.g. cpp)
      # - multiple packages may provide different versions of the same capability (e.g. krb5-libs i386/x86_64)
      #
      # Maintain a cache since some packages (e.g. kernel-uek) take a lot of CPU
      #   when executing --provides.

      # Find installed dep version in cache
      installedDepVersionList=$(grep "^$providesDepPackage $depCur" $cacheFile | cut -d ' ' -f3)

      # If provideslist not in cache, then populate cache
      if [[ ! -n $installedDepVersionList ]]; then
        rpm -q --queryformat '[%{=name}-%{version}-%{release} %{providename} %{provideversion}\n]' "$providesDepPackage" | sort -u >> $cacheFile
        installedDepVersionList=$(grep "^$providesDepPackage $depCur" $cacheFile | cut -d ' ' -f3)
        debug ">> obtained installed version of $depCur from rpm command, saved output in cache $cacheFile"
      else
        debug ">> obtained installed version of $depCur from cache $cacheFile"
      fi
      debug "$installedDepVersionList"

      for installedDepVersion in $installedDepVersionList; do

        # The current package satisfies the dependency
        if [[ $requiredDepVersion == $installedDepVersion ]]; then
          debug ">> version $installedDepVersion satisfies capability requirement"
          foundRequiredDepVersion=yes
          # This gets redirected to depRpmList in the close of the while loop
          echo "$providesDepPackage"
          break
        fi

      done

    done < <(rpm -q --whatprovides --queryformat="%{name} %{name}-%{version}-%{release}\n" "$depCur" | sort -u)

    # Reached last of packages that provide this capability
    # If no packages provide required version, then there has been an upgrade
    if [[ $foundDepRpm == yes && $foundRequiredDepVersion == no ]]; then
      debug ">> no package provides required capability version - add to packageUpgradeList $packageUpgradeList"
      echo "$providesDepPackage" >> $packageUpgradeList
    fi

    
  done < <(rpm -q --requires $(rpm -q $computeNodeRpm) | grep '=') | grep -aiv 'no package provides' | sort -u > $depRpmList
 
  # Get list of currently installed rpms
  debug "get list of currently installed RPMs $installedRpmList"
  rpm -qa --queryformat="%{name}-%{version}-%{release}\n" | sort -u > $installedRpmList

  # Detect additional rpms installed in addition to Exadata dependencies
  # Do not report rpms in the accepted list defined above
  customRpmList=$(
    for p in $(diff $depRpmList $installedRpmList | grep '^>' | grep -Ev $grepNoReport | awk '{print $NF}'); do
      if [[ -e $packageUpgradeList ]] && grep -asq $p $packageUpgradeList; then continue; else echo $p; fi
    done
  )
  customRpmListCount=0
  if [[ ! -z $customRpmList ]]; then
    customRpmListCount=$(echo "$customRpmList" | wc -l)
  fi

  if [[ ! -e $packageUpgradeList ]]; then
    packageUpgradeListCount=0
  else
    sort -u $packageUpgradeList > $packageUpgradeList_$$
    mv $packageUpgradeList_$$ $packageUpgradeList
    packageUpgradeListCount=$(wc -l $packageUpgradeList | cut -d' ' -f1)
  fi
  if [[ ! -e $missingDepList ]]; then
    missingDepListCount=0
  else
    sort -u $missingDepList > $missingDepList_$$
    mv $missingDepList_$$ $missingDepList
    missingDepListCount=$(wc -l $missingDepList | cut -d' ' -f1)
  fi
fi
  
echo "Exadata computenode package   : $computeNodePackage ($computeNodePackageState)"
echo "Missing capabilities          : $missingDepListCount $([[ $missingDepListCount > 0 ]] && echo -n '(action required)')"
echo "Exadata packages upgraded     : $packageUpgradeListCount"
echo "Additional packages installed : $customRpmListCount"

if [[ $verbose == yes ]]; then
  if [[ -e $missingDepList ]]; then
    echo
    echo "Exadata capabilities missing (capabilities required but not supplied by any package)"
    echo "  NOTE: Unexpected configuration - Contact Oracle Support"
    echo "===================================================================================="
    cat $missingDepList | sort
  fi
  if [[ -e $packageUpgradeList ]]; then
    echo
    echo "Exadata packages upgraded"
    echo "========================="
    cat $packageUpgradeList | sort
  fi
  if [[ ! -z $customRpmList ]]; then
    echo
    echo "Additional packages installed (* - expected)"
    echo "============================================"
    for p in $customRpmList; do
      if [[ -z "$grepMarked" ]]; then
        echo "$p"
      else
        echo "$p" | grep -asqEv "$grepMarked" && echo "$p" || echo "* $p"
      fi
    done
  fi
fi

rm -f $depRpmList $installedRpmList $packageUpgradeList $cacheFile $missingDepList
exit 0
