#!/bin/bash
#
# $Header: tfa/src/orachk/src/checkLocalDisks.sh /main/8 2017/10/23 07:40:16 cgirdhar Exp $
#
# checkLocalDisks.sh
#
# Copyright (c) 2015, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      checkLocalDisks.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    cgirdhar    08/30/16 - Fixing 22700412 24533293 24533222 24533088 bugs
#    gadiga      12/03/15 - opc support
#    cgirdhar    05/14/15 - Script to check local physcial disks, virtual disks
#                           on all version of Exadata and all types of hardware
#    cgirdhar    05/14/15 - Creation
#


###########################################################################
#                                                     		          #
#  Purpose: Check the Database Server Physical Drive Configuration        #
#           Check the Database Server Virtual Drive Configuration         #
#           Check the Database Server Disk Controller configuration       #
#                                                               	  #
###########################################################################

## Variable declarations
is_opc=0
megaclicmd=/opt/MegaRAID/MegaCli/MegaCli64
nolog_flag="-NoLog"
if [[ -r "$TMPDIR/raccheck_env.out" && `grep -c "IS_OPC = 1" $TMPDIR/raccheck_env.out` -gt 0 ]] ; then
  is_opc=1
  if [ -x /opt/MegaRAID/storcli/storcli64  ] ; then
    megaclicmd=/opt/MegaRAID/storcli/storcli64
  fi
fi
 
## Variable declarations
 

## 2 Socket Systems

NodeHardwareX2_2=0
NodeHardwareX3_2=0
NodeHardwareX4_2=0
NodeHardwareX5_2=0
NodeHardwareX6_2=0
NodeHardwareX7_2=0
NodeHardwareT7_2=0

## 8 Socket Systems

NodeHardwareX2_8=0
NodeHardwareX3_8=0
NodeHardwareX4_8=0
NodeHardwareX5_8=0

Platform=$(uname -p)

if [ $Platform == "sparc64" ]
then
  NodeHardware=$(/usr/sbin/exadata.img.hw --get model)
  ImageVersion=$(imageinfo -ver|awk '{print substr($0,1,10)}'|tr -d ".")
  
  ## 2 Socket Systems
  
  NodeHardwareT7_2=$(echo $NodeHardware|grep -wci "SPARC T7-2")
else
  if [ $is_opc -eq 0 ] ; then
    NodeHardware=$(/usr/sbin/exadata.img.hw --get model)
    ImageVersion=$(imageinfo -ver|awk '{print substr($0,1,10)}'|tr -d ".")
  else
    ImageVersion=112320
    NodeHardware=$(dmidecode|grep "Product Name"|egrep -iw 'SUN FIRE|SUN SERVER|ORACLE SERVER')
  fi
 
 ## 2 Socket Systems
 
 NodeHardwareX2_2=$(echo $NodeHardware|grep -wci "SUN FIRE X4[1-2]70 M2")
 NodeHardwareX3_2=$(echo $NodeHardware|grep -wci "SUN FIRE X4[1-2]70 M3")
 NodeHardwareX4_2=$(echo $NodeHardware|grep -ci "SUN SERVER X4-2")
 NodeHardwareX5_2=$(echo $NodeHardware|grep -ci "ORACLE SERVER X5-2")
 NodeHardwareX6_2=$(echo $NodeHardware|grep -ci "ORACLE SERVER X6-2")
 NodeHardwareX7_2=$(echo $NodeHardware|grep -ci "ORACLE SERVER X7-2")
 
 ## 8 Socket Systems
 
 NodeHardwareX2_8=$(echo $NodeHardware|grep -wci "SUN FIRE X4800 M2")
 NodeHardwareX3_8=$(echo $NodeHardware|grep -wci "SUN FIRE X4800")
 NodeHardwareX4_8=$(echo $NodeHardware|grep -ci "SUN SERVER X4-8")
 NodeHardwareX5_8=$(echo $NodeHardware|grep -ci "ORACLE SERVER X5-8")
fi

## Check to see is Disk Expansion Kit is in place

if [ $NodeHardwareX5_2 -eq 1 ] || [ $NodeHardwareX6_2 -eq 1 ] || [ $NodeHardwareX7_2 -eq 1 ]
then
  pDisks=$($megaclicmd -PDGetNum -a0 $nolog_flag):$?
  Numpdisks=$(echo $pDisks|awk -F":" '{print $NF}')
  [ $Numpdisks -eq 8 ] && DiskExpansionKit=1 || DiskExpansionKit=0
else
  DiskExpansionKit=0
fi

## Check Hardware Type

if [ $NodeHardwareX2_2 -eq 0 ] && [ $NodeHardwareX3_2 -eq 0 ] && [ $NodeHardwareX4_2 -eq 0 ] && [ $NodeHardwareX5_2 -eq 0 ] && [ $NodeHardwareX6_2 -eq 0 ] && [ $NodeHardwareX7_2 -eq 0 ] && [ $NodeHardwareX2_8 -eq 0 ] && [ $NodeHardwareX3_8 -eq 0 ] && [ $NodeHardwareX4_8 -eq 0 ] && [ $NodeHardwareX5_8 -eq 0 ] && [ $NodeHardwareT7_2 -eq 0 ]
then
  NodeHardwareX2_Other=1
else
  NodeHardwareX2_Other=0
fi

## Values Found

PhyDriveConfigOutput=$($megaclicmd PDList -aALL $nolog_flag| grep "Firmware state")
VirtDriveConfigOutput=$($megaclicmd CfgDsply -aALL $nolog_flag| egrep "Target|Drives|Optimal")
DiskControllerConfigOutput=$($megaclicmd AdpAllInfo -aALL $nolog_flag| grep "Device Present" -A 8)

if [ $ImageVersion -lt 112320 ] && [ $NodeHardwareX2_2 -eq 1 -o $NodeHardwareX2_8 -eq 1 ]
then
  NumPhyDrivesFound=$(echo "$PhyDriveConfigOutput"|wc -l)
  NumPhyDrivesHotSpareFound=$(echo "$PhyDriveConfigOutput"|grep "Hotspare, Spun down"|wc -l)
  NotOnlinePhyDrives=$(echo "$PhyDriveConfigOutput"|grep -v "Online, Spun Up"|grep -v "Hotspare, Spun down"|wc -l)
  if [ $NotOnlinePhyDrives -eq 0 ]
  then
    if [ $NumPhyDrivesHotSpareFound -eq 1 ]
    then
      StatePhyDrivesFound="One Hotspare Spun down, Remaining Physical Drives are Online, Spun Up"
    else
      StatePhyDrivesFound="Not All Expected Physical Drives are Online, Spun Up"
    fi
  else
    StatePhyDrivesFound="Not All Expected Physical Drives are Online, Spun Up"
  fi
else
  NumPhyDrivesFound=$(echo "$PhyDriveConfigOutput"|wc -l)
  NotOnlinePhyDrives=$(echo "$PhyDriveConfigOutput"|grep -v "Online, Spun Up"|wc -l)
  if [ $NotOnlinePhyDrives -eq 0 ]
  then
    StatePhyDrivesFound="All Physical Drives are Online, Spun Up"
  else
    StatePhyDrivesFound="Not All Physical Drives are Online, Spun Up"
  fi
fi

NumVirtDrivesFound=$(echo "$VirtDriveConfigOutput"|grep "Virtual Drive:"|wc -l)
StateVirtDrivesFound=$(echo "$VirtDriveConfigOutput"|grep State|awk -F":" '{print $2}'|sed 's/ //g')
PhyToVirtDrivesFound=$(echo "$VirtDriveConfigOutput"|grep "Number Of Drives"|awk -F":" '{print $2}'|sed 's/ //g')

CntrVirtDrivesFound=$(echo "$DiskControllerConfigOutput"|grep "Virtual Drives"|awk -F":" '{print $2}'|sed 's/ //g')
CntrDegradedFound=$(echo "$DiskControllerConfigOutput"|grep "Degraded"|awk -F":" '{print $2}'|sed 's/ //g')
CntrOfflineFound=$(echo "$DiskControllerConfigOutput"|grep "Offline"|awk -F":" '{print $2}'|sed 's/ //g')
CntrPhyevicesFound=$(echo "$DiskControllerConfigOutput"|grep "Physical Devices"|awk -F":" '{print $2}'|sed 's/ //g')
CntrDisksFound=$(echo "$DiskControllerConfigOutput"|grep "Disks"|egrep -v 'Critical|Failed'|awk -F":" '{print $2}'|sed 's/ //g')
CntrCriticalDisksFound=$(echo "$DiskControllerConfigOutput"|grep "Critical Disks"|awk -F":" '{print $2}'|sed 's/ //g')
CntrFailedDisksFound=$(echo "$DiskControllerConfigOutput"|grep "Failed Disks"|awk -F":" '{print $2}'|sed 's/ //g')

## Values Expected

if [ $Platform == "sparc64" ]
then
  NumPhyDrivesExpctd_2Socket="6"
  NumPhyDrivesExpctd_8Socket="8"
  NumPhyDrivesExpctd_X4_8="7"
  NumPhyDrivesExpctd_X5_8="8"
  StatePhyDrivesExpctd="All Physical Drives are Online, Spun Up"
  NumVirtDrivesExpctd="1"
  StateVirtDrivesExpctd="Optimal"
  PhyToVirtDrivesExpctd_2Socket="6"
  PhyToVirtDrivesExpctd_8Socket="8"
  PhyToVirtDrivesExpctd_X4_8="7"
  PhyToVirtDrivesExpctd_X5_8="8"
  CntrVirtDrivesExpctd="1"
  CntrDegradedExpctd="0"
  CntrOfflineExpctd="0"
  CntrPhyDevices_2SocketExpctd="7"
  CntrPhyDevices_8SocketExpctd="11"
  CntrPhyDevices_X4_8Expctd="8"
  CntrPhyDevices_X5_8Expctd="9"
  CntrDisks_2SocketExpctd="6"
  CntrDisks_8SocketExpctd="8"
  CntrDisks_X4_8Expctd="7"
  CntrDisks_X5_8Expctd="8"
  CntrCriticalDisksExpctd="0"
  CntrFailedDisksExpctd="0"
elif [ $DiskExpansionKit -eq 1 ]
then
  NumPhyDrivesExpctd_2Socket="8"
  NumPhyDrivesExpctd_8Socket="16"
  NumPhyDrivesExpctd_X4_8="14"
  NumPhyDrivesExpctd_X5_8="16"
  StatePhyDrivesExpctd="All Physical Drives are Online, Spun Up"
  NumVirtDrivesExpctd="1"
  StateVirtDrivesExpctd="Optimal"
  PhyToVirtDrivesExpctd_2Socket="8"
  PhyToVirtDrivesExpctd_8Socket="16"
  PhyToVirtDrivesExpctd_X4_8="14"
  PhyToVirtDrivesExpctd_X5_8="16"
  CntrVirtDrivesExpctd="1"
  CntrDegradedExpctd="0"
  CntrOfflineExpctd="0"
  CntrPhyDevices_2SocketExpctd="9"
  CntrPhyDevices_8SocketExpctd="11"
  CntrPhyDevices_X4_8Expctd="8"
  CntrPhyDevices_X5_8Expctd="9"
  CntrDisks_2SocketExpctd="8"
  CntrDisks_8SocketExpctd="8"
  CntrDisks_X4_8Expctd="7"
  CntrDisks_X5_8Expctd="8"
  CntrCriticalDisksExpctd="0"
  CntrFailedDisksExpctd="0"
else
  if [ $ImageVersion -lt 112320 ] && [ $NodeHardwareX2_2 -eq 1 -o $NodeHardwareX2_8 -eq 1 ]
  then
    NumPhyDrivesExpctd_2Socket="4"
    NumPhyDrivesExpctd_8Socket="8"
    StatePhyDrivesExpctd="One Hotspare Spun down, Remaining Physical Drives are Online, Spun Up"
    NumVirtDrivesExpctd="1"
    StateVirtDrivesExpctd="Optimal"
    PhyToVirtDrivesExpctd_2Socket="3"
    PhyToVirtDrivesExpctd_8Socket="7"
    CntrVirtDrivesExpctd="1"
    CntrDegradedExpctd="0"
    CntrOfflineExpctd="0"
    CntrPhyDevices_2SocketExpctd="5"
    CntrPhyDevices_8SocketExpctd="11"
    CntrDisks_2SocketExpctd="4"
    CntrDisks_8SocketExpctd="8"
    CntrCriticalDisksExpctd="0"
    CntrFailedDisksExpctd="0"
  else
    NumPhyDrivesExpctd_2Socket="4"
    NumPhyDrivesExpctd_8Socket="8"
    NumPhyDrivesExpctd_X4_8="7"
    NumPhyDrivesExpctd_X5_8="8"
    StatePhyDrivesExpctd="All Physical Drives are Online, Spun Up"
    NumVirtDrivesExpctd="1"
    StateVirtDrivesExpctd="Optimal"
    PhyToVirtDrivesExpctd_2Socket="4"
    PhyToVirtDrivesExpctd_8Socket="8"
    PhyToVirtDrivesExpctd_X4_8="7"
    PhyToVirtDrivesExpctd_X5_8="8"
    CntrVirtDrivesExpctd="1"
    CntrDegradedExpctd="0"
    CntrOfflineExpctd="0"
    CntrPhyDevices_2SocketExpctd="5"
    CntrPhyDevices_8SocketExpctd="11"
    CntrPhyDevices_X4_8Expctd="8"
    CntrPhyDevices_X5_8Expctd="9"
    CntrDisks_2SocketExpctd="4"
    CntrDisks_8SocketExpctd="8"
    CntrDisks_X4_8Expctd="7"
    CntrDisks_X5_8Expctd="8"
    CntrCriticalDisksExpctd="0"
    CntrFailedDisksExpctd="0"
  fi
fi

if [ $is_opc -eq 1 ] ; then
  nvme_disks=$(/sbin/lspci -d 144d:a821 2>/dev/null)
  if [[ -x /sbin/lspci && -n "$nvme_disks" ]]
  then
      NumPhyDrivesExpctd_2Socket="4"
      CntrPhyDevices_2SocketExpctd="5"
      CntrDisks_2SocketExpctd="4"
  else
      NumPhyDrivesExpctd_2Socket="8"
      CntrPhyDevices_2SocketExpctd="9"
      CntrDisks_2SocketExpctd="8"
  fi
fi
  
PhyDriveStatus=1
VirtDriveStatus=1
DiskControllerStatus=1

## Function Definitions

usage()
{
  echo "Usage: CheckPhyVirtDrivesController.sh [-c PhyDrive|VirtDrive|DiskController -o check|report] [-h]";
}

CheckPhyDrives()
{
  NumSockets=$1
  if [ "$NumSockets" == "2Socket" ]
  then
    if [ "$NumPhyDrivesFound" == "$NumPhyDrivesExpctd_2Socket" ] && [ "$StatePhyDrivesFound" == "$StatePhyDrivesExpctd" ]
    then
      PhyDriveStatus=0
    fi
  elif [ "$NumSockets" == "8Socket" ]
  then
    if [ "$NumPhyDrivesFound" == "$NumPhyDrivesExpctd_8Socket" ] && [ "$StatePhyDrivesFound" == "$StatePhyDrivesExpctd" ]
    then
      PhyDriveStatus=0
    fi
  elif [ "$NumSockets" == "X4_8" ]
  then
    if [ "$NumPhyDrivesFound" == "$NumPhyDrivesExpctd_X4_8" ] && [ "$StatePhyDrivesFound" == "$StatePhyDrivesExpctd" ]
    then
      PhyDriveStatus=0
    fi
  elif [ "$NumSockets" == "X5_8" ]
  then
    if [ "$NumPhyDrivesFound" == "$NumPhyDrivesExpctd_X5_8" ] && [ "$StatePhyDrivesFound" == "$StatePhyDrivesExpctd" ]
    then
      PhyDriveStatus=0
    fi
  fi 
}

CheckVirtDrives()
{
  NumSockets=$1
  if [ "$NumSockets" == "2Socket" ]
  then
    if [ "$NumVirtDrivesFound" == "$NumVirtDrivesExpctd" ] && [ "$StateVirtDrivesFound" == "$StateVirtDrivesExpctd" ] && [ "$PhyToVirtDrivesFound" == "$PhyToVirtDrivesExpctd_2Socket" ]
    then
      VirtDriveStatus=0
    fi
  elif [ "$NumSockets" == "8Socket" ]
  then
    if [ "$NumVirtDrivesFound" == "$NumVirtDrivesExpctd" ] && [ "$StateVirtDrivesFound"  ==  "$StateVirtDrivesExpctd" ] && [ "$PhyToVirtDrivesFound" == "$PhyToVirtDrivesExpctd_8Socket" ]
    then
      VirtDriveStatus=0
    fi
  elif [ "$NumSockets" == "X4_8" ]
  then
    if [ "$NumVirtDrivesFound" == "$NumVirtDrivesExpctd" ] && [ "$StateVirtDrivesFound" == "$StateVirtDrivesExpctd" ] && [ "$PhyToVirtDrivesFound" == "$PhyToVirtDrivesExpctd_X4_8" ]
    then
      VirtDriveStatus=0
    fi
  elif [ "$NumSockets" == "X5_8" ]
  then
    if [ "$NumVirtDrivesFound" == "$NumVirtDrivesExpctd" ] && [ "$StateVirtDrivesFound" == "$StateVirtDrivesExpctd" ] && [ "$PhyToVirtDrivesFound" == "$PhyToVirtDrivesExpctd_X5_8" ]
    then
      VirtDriveStatus=0
    fi
  fi 
}

CheckDiskController()
{
  NumSockets=$1
  if [ "$NumSockets" == "2Socket" ]
  then
    if [ "$CntrVirtDrivesFound" == "$CntrVirtDrivesExpctd" ] && [ "$CntrDegradedFound" == "$CntrDegradedExpctd" ] && [ "$CntrOfflineFound" == "$CntrOfflineExpctd" ] && [ "$CntrPhyevicesFound" == "$CntrPhyDevices_2SocketExpctd" ] && [ "$CntrDisksFound" == "$CntrDisks_2SocketExpctd" ] && [ "$CntrCriticalDisksFound" == "$CntrCriticalDisksExpctd" ] && [ "$CntrFailedDisksFound" == "$CntrFailedDisksExpctd" ]
    then
      DiskControllerStatus=0
    fi
  elif [ "$NumSockets" == "8Socket" ]
  then
    if [ "$CntrVirtDrivesFound" == "$CntrVirtDrivesExpctd" ] && [ "$CntrDegradedFound"  == "$CntrDegradedExpctd" ] && [ "$CntrOfflineFound" == "$CntrOfflineExpctd" ] && [ "$CntrPhyevicesFound" == "$CntrPhyDevices_8SocketExpctd" ] && [ "$CntrDisksFound" == "$CntrDisks_8SocketExpctd" ] && [ "$CntrCriticalDisksFound" == "$CntrCriticalDisksExpctd" ] && [ "$CntrFailedDisksFound" == "$CntrFailedDisksExpctd" ]
    then
      DiskControllerStatus=0
    fi
  elif [ "$NumSockets" == "X4_8" ]
  then
    if [ "$CntrVirtDrivesFound" == "$CntrVirtDrivesExpctd" ] && [ "$CntrDegradedFound" == "$CntrDegradedExpctd" ] && [ "$CntrOfflineFound" == "$CntrOfflineExpctd" ] && [ "$CntrPhyevicesFound" == "$CntrPhyDevices_X4_8Expctd" ] && [ "$CntrDisksFound" == "$CntrDisks_X4_8Expctd" ] && [ "$CntrCriticalDisksFound" == "$CntrCriticalDisksExpctd" ] && [ "$CntrFailedDisksFound" == "$CntrFailedDisksExpctd" ]
    then
      DiskControllerStatus=0
    fi
  elif [ "$NumSockets" == "X5_8" ]
  then
    if [ "$CntrVirtDrivesFound" == "$CntrVirtDrivesExpctd" ] && [ "$CntrDegradedFound" == "$CntrDegradedExpctd" ] && [ "$CntrOfflineFound" == "$CntrOfflineExpctd" ] && [ "$CntrPhyevicesFound" == "$CntrPhyDevices_X5_8Expctd" ] && [ "$CntrDisksFound" == "$CntrDisks_X5_8Expctd" ] && [ "$CntrCriticalDisksFound" == "$CntrCriticalDisksExpctd" ] && [ "$CntrFailedDisksFound" == "$CntrFailedDisksExpctd" ]
    then
      DiskControllerStatus=0
    fi
  fi 
}

check_main()
{
ChkToPerform=$1
case "${ChkToPerform}" in
    PhyDrive)
       FuncToCall=CheckPhyDrives;
       ;;
    VirtDrive)
       FuncToCall=CheckVirtDrives;
       ;;
    DiskController)
       FuncToCall=CheckDiskController;
       ;;
    *) echo "Invalid or missing command line arguments..."
       usage;
       exit 1
       ;;
   esac
if [ $NodeHardwareX2_2 -eq 1 ] || [ $NodeHardwareX3_2 -eq 1 ] || [ $NodeHardwareX4_2 -eq 1 ] || [ $NodeHardwareX5_2 -eq 1 ] || [ $NodeHardwareX6_2 -eq 1 ] || [ $NodeHardwareX7_2 -eq 1 ] || [ $NodeHardwareT7_2 -eq 1 ] || [ $NodeHardwareX2_Other -eq 1 ]
then       
  $FuncToCall 2Socket;
elif [ $NodeHardwareX2_8 -eq 1 ] || [ $NodeHardwareX3_8 -eq 1 ]
then
  $FuncToCall 8Socket;
elif [ $NodeHardwareX4_8 -eq 1 ]
then
  $FuncToCall X4_8;
elif [ $NodeHardwareX5_8 -eq 1 ]
then
  $FuncToCall X5_8;
fi
}

print_result()
{
ResultToCheck=$1
case "${ResultToCheck}" in
    PhyDrive)
       Status=$PhyDriveStatus;
       ;;
    VirtDrive)
       Status=$VirtDriveStatus;
       ;;
    DiskController)
       Status=$DiskControllerStatus;
       ;;
    *) echo "Invalid or missing command line arguments..."
       usage;
       exit 1
       ;;
  esac
if [ $Status -eq 0 ]
then       
  echo 0       
else       
  echo 1       
fi 
}

print_report()
{
  ReportToPrint=$1
  case "${ReportToPrint}" in
    PhyDrive)
       ReportOutput1=$PhyDriveConfigOutput;
       if [ $NodeHardwareX2_2 -eq 1 ] || [ $NodeHardwareX3_2 -eq 1 ] || [ $NodeHardwareX4_2 -eq 1 ] || [ $NodeHardwareX5_2 -eq 1 ] || [ $NodeHardwareX6_2 -eq 1 ] || [ $NodeHardwareX7_2 -eq 1 ] || [ $NodeHardwareT7_2 -eq 1 ] || [ $NodeHardwareX2_Other -eq 1 ]
       then
         ReportOutput2="The Number of Physical Drives Found is :$NumPhyDrivesFound\nThe State of Physical Drive Found is :$StatePhyDrivesFound"
         ReportOutput3="The Number of Physical Drives Expected is :$NumPhyDrivesExpctd_2Socket\nThe State of Physical Drive Expected is :$StatePhyDrivesExpctd"
       elif [ $NodeHardwareX2_8 -eq 1 ] || [ $NodeHardwareX3_8 -eq 1 ]
       then
         ReportOutput2="The Number of Physical Drives Found is :$NumPhyDrivesFound\nThe State of Physical Drive Found is :$StatePhyDrivesFound"
         ReportOutput3="The Number of Physical Drives Expected is :$NumPhyDrivesExpctd_8Socket\nThe State of Physical Drive Expected is :$StatePhyDrivesExpctd"
       elif [ $NodeHardwareX4_8 -eq 1 ]
       then
         ReportOutput2="The Number of Physical Drives Found is :$NumPhyDrivesFound\nThe State of Physical Drive Found is :$StatePhyDrivesFound"
         ReportOutput3="The Number of Physical Drives Expected is :$NumPhyDrivesExpctd_X4_8\nThe State of Physical Drive Expected is :$StatePhyDrivesExpctd"
       elif [ $NodeHardwareX5_8 -eq 1 ]
       then
         ReportOutput2="The Number of Physical Drives Found is :$NumPhyDrivesFound\nThe State of Physical Drive Found is :$StatePhyDrivesFound"
         ReportOutput3="The Number of Physical Drives Expected is :$NumPhyDrivesExpctd_X5_8\nThe State of Physical Drive Expected is :$StatePhyDrivesExpctd"
       fi
       ;;
    VirtDrive)
       ReportOutput1=$VirtDriveConfigOutput;
       if [ $NodeHardwareX2_2 -eq 1 ] || [ $NodeHardwareX3_2 -eq 1 ] || [ $NodeHardwareX4_2 -eq 1 ] || [ $NodeHardwareX5_2 -eq 1 ] || [ $NodeHardwareX6_2 -eq 1 ] || [ $NodeHardwareX7_2 -eq 1 ] || [ $NodeHardwareT7_2 -eq 1 ] || [ $NodeHardwareX2_Other -eq 1 ]
       then
         ReportOutput2="The Number of Virtual Drives Found is :$NumVirtDrivesFound\nThe State of Virtual Drive Found is :$StateVirtDrivesFound\nThe Number of Physical drives making up the Virtual Drive Found is :$PhyToVirtDrivesFound"
         ReportOutput3="The Number of Virtual Drives Expected is :$NumVirtDrivesExpctd\nThe State of Virtual Drive Expected is :$StateVirtDrivesExpctd\nThe Expected Number of Physical drives making up the Virtual Drive is :$PhyToVirtDrivesExpctd_2Socket"
       elif [ $NodeHardwareX2_8 -eq 1 ] || [ $NodeHardwareX3_8 -eq 1 ]
       then
         ReportOutput2="The Number of Virtual Drives Found is :$NumVirtDrivesFound\nThe State of Virtual Drive Found is :$StateVirtDrivesFound\nThe Number of Physical drives making up the Virtual Drive Found is :$PhyToVirtDrivesFound"
         ReportOutput3="The Number of Virtual Drives Expected is :$NumVirtDrivesExpctd\nThe State of Virtual Drive Expected is :$StateVirtDrivesExpctd\nThe Expected Number of Physical drives making up the Virtual Drive is :$PhyToVirtDrivesExpctd_8Socket"
       elif [ $NodeHardwareX4_8 -eq 1 ]
       then
         ReportOutput2="The Number of Virtual Drives Found is :$NumVirtDrivesFound\nThe State of Virtual Drive Found is :$StateVirtDrivesFound\nThe Number of Physical drives making up the Virtual Drive Found is :$PhyToVirtDrivesFound"
         ReportOutput3="The Number of Virtual Drives Expected is :$NumVirtDrivesExpctd\nThe State of Virtual Drive Expected is :$StateVirtDrivesExpctd\nThe Expected Number of Physical drives making up the Virtual Drive is :$PhyToVirtDrivesExpctd_X4_8"
       elif [ $NodeHardwareX5_8 -eq 1 ]
       then
         ReportOutput2="The Number of Virtual Drives Found is :$NumVirtDrivesFound\nThe State of Virtual Drive Found is :$StateVirtDrivesFound\nThe Number of Physical drives making up the Virtual Drive Found is :$PhyToVirtDrivesFound"
         ReportOutput3="The Number of Virtual Drives Expected is :$NumVirtDrivesExpctd\nThe State of Virtual Drive Expected is :$StateVirtDrivesExpctd\nThe Expected Number of Physical drives making up the Virtual Drive is :$PhyToVirtDrivesExpctd_X5_8"
       fi
       ;;
    DiskController)
       ReportOutput1=$DiskControllerConfigOutput;
       if [ $NodeHardwareX2_2 -eq 1 ] || [ $NodeHardwareX3_2 -eq 1 ] || [ $NodeHardwareX4_2 -eq 1 ] || [ $NodeHardwareX5_2 -eq 1 ] || [ $NodeHardwareX6_2 -eq 1 ] || [ $NodeHardwareX7_2 -eq 1 ] || [ $NodeHardwareT7_2 -eq 1 ] || [ $NodeHardwareX2_Other -eq 1 ]
       then
         ReportOutput2="The Number of Controller Virtual Drives Found is :$CntrVirtDrivesFound\nThe Number of Degraded Devices Found is :$CntrDegradedFound\nThe Number of Offline devices found is :$CntrOfflineFound\nThe Number of Physical Devices Found is :$CntrPhyevicesFound\nThe Number of Disks Found is :$CntrDisksFound\nThe Numebr of Critical Disks Found is :$CntrCriticalDisksFound\nThe Number of Failed Disks Found is :$CntrFailedDisksFound"
         ReportOutput3="The Number of Controller Virtual Drives Expected is :$CntrVirtDrivesExpctd\nThe Number of Degraded Devices Expected is :$CntrDegradedExpctd\nThe Number of Offline devices Expected is :$CntrOfflineExpctd\nThe Number of Physical Devices Expected is :$CntrPhyDevices_2SocketExpctd\nThe Number of Disks Expected is :$CntrDisks_2SocketExpctd\nThe Numebr of Critical Disks Expected is :$CntrCriticalDisksExpctd\nThe Number of Failed Disks Expected is :$CntrFailedDisksExpctd"
       elif [ $NodeHardwareX2_8 -eq 1 ] || [ $NodeHardwareX3_8 -eq 1 ]
       then
         ReportOutput2="The Number of Controller Virtual Drives Found is :$CntrVirtDrivesFound\nThe Number of Degraded Devices Found is :$CntrDegradedFound\nThe Number of Offline devices found is :$CntrOfflineFound\nThe Number of Physical Devices Found is :$CntrPhyevicesFound\nThe Number of Disks Found is :$CntrDisksFound\nThe Numebr of Critical Disks Found is :$CntrCriticalDisksFound\nThe Number of Failed Disks Found is :$CntrFailedDisksFound"
         ReportOutput3="The Number of Controller Virtual Drives Expected is :$CntrVirtDrivesExpctd\nThe Number of Degraded Devices Expected is :$CntrDegradedExpctd\nThe Number of Offline devices Expected is :$CntrOfflineExpctd\nThe Number of Physical Devices Expected is :$CntrPhyDevices_8SocketExpctd\nThe Number of Disks Expected is :$CntrDisks_8SocketExpctd\nThe Numebr of Critical Disks Expected is :$CntrCriticalDisksExpctd\nThe Number of Failed Disks Expected is :$CntrFailedDisksExpctd"
       elif [ $NodeHardwareX4_8 -eq 1 ]
       then
         ReportOutput2="The Number of Controller Virtual Drives Found is :$CntrVirtDrivesFound\nThe Number of Degraded Devices Found is :$CntrDegradedFound\nThe Number of Offline devices found is :$CntrOfflineFound\nThe Number of Physical Devices Found is :$CntrPhyevicesFound\nThe Number of Disks Found is :$CntrDisksFound\nThe Numebr of Critical Disks Found is :$CntrCriticalDisksFound\nThe Number of Failed Disks Found is :$CntrFailedDisksFound"
         ReportOutput3="The Number of Controller Virtual Drives Expected is :$CntrVirtDrivesExpctd\nThe Number of Degraded Devices Expected is :$CntrDegradedExpctd\nThe Number of Offline devices Expected is :$CntrOfflineExpctd\nThe Number of Physical Devices Expected is :$CntrPhyDevices_X4_8Expctd\nThe Number of Disks Expected is :$CntrDisks_X4_8Expctd\nThe Numebr of Critical Disks Expected is :$CntrCriticalDisksExpctd\nThe Number of Failed Disks Expected is :$CntrFailedDisksExpctd"
       elif [ $NodeHardwareX5_8 -eq 1 ]
       then
         ReportOutput2="The Number of Controller Virtual Drives Found is :$CntrVirtDrivesFound\nThe Number of Degraded Devices Found is :$CntrDegradedFound\nThe Number of Offline devices found is :$CntrOfflineFound\nThe Number of Physical Devices Found is :$CntrPhyevicesFound\nThe Number of Disks Found is :$CntrDisksFound\nThe Numebr of Critical Disks Found is :$CntrCriticalDisksFound\nThe Number of Failed Disks Found is :$CntrFailedDisksFound"
         ReportOutput3="The Number of Controller Virtual Drives Expected is :$CntrVirtDrivesExpctd\nThe Number of Degraded Devices Expected is :$CntrDegradedExpctd\nThe Number of Offline devices Expected is :$CntrOfflineExpctd\nThe Number of Physical Devices Expected is :$CntrPhyDevices_X5_8Expctd\nThe Number of Disks Expected is :$CntrDisks_X5_8Expctd\nThe Numebr of Critical Disks Expected is :$CntrCriticalDisksExpctd\nThe Number of Failed Disks Expected is :$CntrFailedDisksExpctd"
       fi
       ;;
    *) echo "Invalid or missing command line arguments..."
       usage;
       exit 1
       ;;
   esac
  echo -e "$ReportOutput1\n\n$ReportOutput2\n\n$ReportOutput3"
}


## Main Body

NumArgs=$#

if [ $NumArgs -lt 1 ]
then
  echo "Invalid or missing command line arguments..."
  usage;
  exit 1
fi

while getopts "c:o:h" opt;
do
  case "${opt}" in
    h) usage;
       exit 0
       ;;
    c)
       chk=${OPTARG};
       ;;
    o)
       swch=${OPTARG};
       ;;
    *) echo "Invalid or missing command line arguments..."
       usage;
       exit 1
       ;;
   esac
done

if [ $swch = "check" ]
then
   check_main $chk
   print_result $chk;
elif [ $swch == "report" ]
then
   check_main $chk
   print_report $chk;
else
  echo "Invalid or missing command line arguments..."
  usage;
  exit 1
fi
