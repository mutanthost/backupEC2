#!/bin/bash
#
# $Header: tfa/src/orachk/src/check_dom0_ocfs2.sh /main/2 2017/04/04 11:13:51 cgirdhar Exp $
#
# check_dom0_ocfs2.sh
#
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      check_dom0_ocfs2.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    cgirdhar    10/17/16 - Check the /EXAVMIMAGES ocfs2 filesystem on a dom0
#                           for adequate available space
#    cgirdhar    10/17/16 - Creation
#
## Variable declarations

ThresholdPct=95

## Function Definitions

usage()
{
  echo "Usage: check_dom0_ocfs2.sh [-o check|report] [-h]";
}

check_dom0()
{
  xendStat=$(/sbin/service xend status 2> /dev/null):$?
  isdom0=$(echo $xendStat|awk -F":" '{print $NF}') 
}

check_dom0_ocfs2()
{
  LVDISPLAY=$(which lvdisplay)
  isLVM=$($LVDISPLAY 2>&1|grep -qi EXAVMIMAGES;echo $?)
  if [ $isLVM -eq 1 ]
  then
    ocfs2TotalSize=$(df /EXAVMIMAGES | tail -1 | awk '{print $2}')
    ocfs2AllocSize=$(df /EXAVMIMAGES | tail -1 | awk '{print $3}')
  elif [ $isLVM -eq 0 ]
  then
    ocfs2TotalSize=$(df /EXAVMIMAGES | tail -1 | awk '{print $1}')
    ocfs2AllocSize=$(df /EXAVMIMAGES | tail -1 | awk '{print $2}')
  fi  
  ocfs2ApparentAllocSize=$(du -csS --apparent-size /EXAVMIMAGES | tail -1 | awk '{print $1}')
  ThresholdAllocSize=$( expr $ocfs2TotalSize \* $ThresholdPct / 100 )
 
  if [ $ocfs2AllocSize -gt $ThresholdAllocSize ]
  then
    exit_code=1
    ErrorMsg="/EXAVMIMAGES is more than 95% full. Please free up some space to avoid unpredictable issues with the user domains."
    messageGeneric1='Benefit: To use dom0 disk space efficiently, two space saving techniques are used for disk image files in /EXAVMIMAGES, sparse files and reflinks. Sparse files do not allocate blocks on disk for empty space. OCFS2 reflinks allow disk image copies to share blocks on disk until one of the copies changes, at which time a new block on disk is allocated. The result of these space saving features is the amount of disk space consumed is less than the apparent size of the user domain disk image files reported by the "du -sS --apparent-size <file_name>" command. However, as a user domain is used and files are changed, created, and removed, the disk space consumed from the /EXAVMIMAGES file system will continually grow while the actual space used by disk image files could remain the same. This check warns when the total apparent size of all files in /EXAVMIMAGES exceeds the size of file system.'
    messageGeneric2="Impact: The impact of this check is minimal"
    messageGeneric3="Risk: A failure does not occur when the apparent size exceeds the size of the /EXAVMIMAGES file system. It may be normal in many environments that benefit from sparse files and reflinks heavily. However, over time as changes are made to user domain disks (e.g. by applying Exadata, Grid Infrastructure, or Database patches), allocated space in the /EXAVMIMAGES file system increases. If the allocated space reaches /EXAVMIMAGES file system size in dom0, then an out of space error will occur within the user domain, even though df output within the user domain shows there is available space. This can cause unpredictable behavior, such as an unbootable user domains, or corrupted files that were being changed at the time the out of space error occurred."
    dom0ocfs2SpaceWarn=0
    dom0ocfs2SpaceFail=1
  elif [ $ocfs2ApparentAllocSize -gt $ocfs2TotalSize ]
  then
    exit_code=0
    ALVL=1
    dom0ocfs2SpaceWarn=1
    dom0ocfs2SpaceFail=0
    WarnMsg="Cumulative apparent size of all files under /EXAVMIMGES exceeds the /EXVMIMAGES file system size. This is not a problem at the moment but can potentially lead to problems once /EXAVMIMAGES becomes 100% full. To avoid such issues it is recommended to put a monitoring in place for /EXAVMIMAGES such that the allocated space never exceeds 95% of the file system space."
    AllocSizeMsg="Cumulative apparent size of all files under /EXAVMIMGES :"$ocfs2ApparentAllocSize
    TotSizeMsg="/EXAVMIMGES file system size :"$ocfs2TotalSize
    messageGeneric1='Benefit: To use dom0 disk space efficiently, two space saving techniques are used for disk image files in /EXAVMIMAGES, sparse files and reflinks. Sparse files do not allocate blocks on disk for empty space. OCFS2 reflinks allow disk image copies to share blocks on disk until one of the copies changes, at which time a new block on disk is allocated. The result of these space saving features is the amount of disk space consumed is less than the apparent size of the user domain disk image files reported by the "du -sS --apparent-size <file_name>" command. However, as a user domain is used and files are changed, created, and removed, the disk space consumed from the /EXAVMIMAGES file system will continually grow while the actual space used by disk image files could remain the same. This check warns when the total apparent size of all files in /EXAVMIMAGES exceeds the size of file system.'
    messageGeneric2="Impact: The impact of this check is minimal"
    messageGeneric3="Risk: A failure does not occur when the apparent size exceeds the size of the /EXAVMIMAGES file system. It may be normal in many environments that benefit from sparse files and reflinks heavily. However, over time as changes are made to user domain disks (e.g. by applying Exadata, Grid Infrastructure, or Database patches), allocated space in the /EXAVMIMAGES file system increases. If the allocated space reaches /EXAVMIMAGES file system size in dom0, then an out of space error will occur within the user domain, even though df output within the user domain shows there is available space. This can cause unpredictable behavior, such as an unbootable user domains, or corrupted files that were being changed at the time the out of space error occurred."
  else
    exit_code=0
    dom0ocfs2SpaceWarn=0
    dom0ocfs2SpaceFail=0
    PassMsg="/EXAVMIMAGES space has not been over allocated and the space usage is under the threshold."
  fi
}

check_main()
{
  check_dom0
  if [ $isdom0 -eq 0 ]
  then
    checkNotApplicable=0
    check_dom0_ocfs2
  else
    checkNotApplicable=1
    exit_code=0
  fi
}

print_result()
{
  echo $exit_code
}

print_report()
{
  if [ $checkNotApplicable -eq 1 ]
  then
    echo "This check is not applicable to this environment"
  elif [ $dom0ocfs2SpaceFail -eq 1 ]
  then
    echo $ErrorMsg
#    printf "\n$messageGeneric1\n"
#    printf "\n$messageGeneric2\n"
#    printf "\n$messageGeneric3\n"
  elif [ $dom0ocfs2SpaceWarn -eq 1 ]
  then
    echo $WarnMsg
    printf "\n$AllocSizeMsg\n"
    printf "$TotSizeMsg\n"
#    printf "\n$messageGeneric1\n"
#    printf "\n$messageGeneric2\n"
#    printf "\n$messageGeneric3\n"
  else
    echo $PassMsg
  fi
}

NumArgs=$#

if [ $NumArgs -lt 1 ]
then
  echo "Invalid or missing command line arguments..."
  usage;
  exit 1
fi

while getopts "o:h" opt;
do
  case "${opt}" in
    h) usage;
       exit 0
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
  check_main;
  print_result;
elif [ $swch == "report" ]
then
  check_main;
  print_report;
else
  echo "Invalid or missing command line arguments..."
  usage;
  exit 1
fi
