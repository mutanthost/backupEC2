#!/bin/bash
#
# $Header: tfa/src/orachk/src/checkDiskScheduler.sh /main/3 2017/11/02 20:04:21 rojuyal Exp $
#
# checkDiskScheduler.sh
#
# Copyright (c) 2015, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      checkDiskScheduler.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    shdharma	 08/28/17 - modular, various types of device resolution, run as root
#    cgirdhar    02/10/15 - Checking ASM disks I/O scheduler setting
#    cgirdhar    02/10/15 - Creation
#

# NOTES:
#
#device types:
# nvme:   /dev/nvme*
# scsi:   /dev/sd*
# xen virtual block device:    /dev/xvd*
#
# managed layers:
# dm-mp:  /dev/mapper/* (names could be actual devices (RHEL5) or further symlinks to /dev/dm-* (OL6/OL7))
# asmlib: /dev/oracleasm/disks/*
# afd:    /dev/oracleafd/disks/*
#
# possible mappings to resolve...
#
# a. scsi
# b. nvme
# c. xvd
#
# d. dm-mp -> scsi
# e. dm-mp -> nvme
#  
#
# f. asmlib -> scsi
# g. asmlib -> nvme
# h. asmlib -> xvd
# i. asmlib -> dm-mp -> scsi
# j. asmlib -> dm-mp -> nvme

# k. afd -> scsi
# l. afd -> nvme
# m. afd -> xvd
# 
# n. afd -> dm-mp -> scsi
# o. afd -> dm-mp -> nvme
#
# Determine if afd or asmlib and/or dm-mp are in use. Then derive the eventual device
#

# FUNCTIONS

function check_os {
 # this script is meant to run on Linux

 if [ ! `uname -s` = "Linux" ] ; then
  echo "Operating system isn't Linux. Exiting."
  exit 1
 fi
}

function get_os_user {
 v_os_user=$(/usr/bin/whoami)
}

function locate_lsmod {

if [ -e /usr/sbin/lsmod ] && [ -x /usr/sbin/lsmod ] ; then
   v_lsmod=/usr/sbin/lsmod
 elif [ -e /sbin/lsmod ] && [ -x /sbin/lsmod ] ; then
   v_lsmod=/sbin/lsmod
 else
   echo "unable to locate lsmod. Exiting"
   exit 1
 fi

}

function locate_dmsetup {
 
 if [ -e /usr/sbin/dmsetup ] && [ -x /usr/sbin/dmsetup ] ; then
   v_dmsetup=/usr/sbin/dmsetup
 elif [ -e /sbin/dmsetup ] && [ -x /sbin/dmsetup ] ; then
   v_dmsetup=/sbin/dmsetup
 else
   echo "unable to locate dmsetup. Exiting"
   exit 1
 fi

}

function get_dm_mp_data {

 locate_lsmod
 locate_dmsetup

 # check for dm-multipath module
 v_dm_mp_stat=$($v_lsmod | grep -i multipath | wc -l)

 if [ ${v_dm_mp_stat} -gt 0 ] ; then
   # multipath has been loaded

   # now check for multipath devices
   v_dmsetup_stat=$($v_dmsetup status --target multipath | awk -F: '{print $1}' | wc -l)

   if [ ${v_dm_mp_stat} -gt 0 ] ; then

     # get the device list
     v_dmmp_devlist=$($v_dmsetup status --target multipath | awk -F: '{print "/dev/mapper/"$1}')

     if [[ ! -z $v_dmmp_devlist ]] ; then 
       # set the flag
       v_dm_mp=true
     else
       v_dm_mp=false
     fi
   else
     v_dm_mp=false
   fi
 else
  v_dm_mp=false
 fi

}

function get_asmlib_data {

 if [ -e /usr/sbin/oracleasm ] ; then
  
   v_chk_asmlib=$(/usr/sbin/oracleasm status | grep -i yes | wc -l)

   # asmlib loaded and /dev/oracleasm is mounted
   if [ $v_chk_asmlib -ge 2 ] ; then

     # check for any ASM Lib devices
     v_asmlib_dev=$(/usr/sbin/oracleasm listdisks)

     v_asmlib_dev_cnt=$(echo $v_asmlib_dev | wc -l)

     if [ ${v_asmlib_dev_cnt} -gt 0 ] ; then
        v_asmlib_devlist=$(/usr/sbin/oracleasm querydisk -p ${v_asmlib_dev} | grep -i label | awk -F: '{print $1}' | sort)
        v_asmlib_dev=true
     else
        v_asmlib_dev=false
     fi

   else
     v_asmlib_dev=false
   fi

 else
    v_asmlib_dev=false
 fi

}

function get_oratab_loc {

 if [ -e /etc/oratab ] && [ -r /etc/oratab ] ; then
  v_oratab=/etc/oratab
 elif [ -e /var/opt/oracle/oratab ] && [ -r /var/opt/oracle/oratab ] ; then
  v_oratab=/var/opt/oracle/oratab
 else
  echo "unable to get oratab location. Exiting."
  status=1
  exit 1
 fi
}

function set_asm_home {

 get_oratab_loc

 if [[ -z "${ORACLE_SID}"  && ! -z ${v_oratab} ]] ; then
  export ORACLE_SID=`ps -ef| grep -i asm_pmon | grep -v grep | awk '{print $8}' | awk -F_ '{print $3}'`
  if [ ${ORACLE_HOME}x = x ] ; then
   export ORACLE_HOME=`cat $v_oratab | grep -i +ASM | grep -v ^# | awk -F: '{print $2}' | tr -d ' ' `
  fi
  export PATH=$ORACLE_HOME/bin:$PATH
 elif [ ${ORACLE_SID}x = ${ORACLE_SID}x ] && [ ! -z ${v_oratab}  ] ; then
  export ORACLE_SID=`ps -ef| grep -i asm_pmon | grep -v grep | awk '{print $8}' | awk -F_ '{print $3}'`
  if [ ${ORACLE_HOME}x = x ] ; then
   export ORACLE_HOME=`cat $v_oratab | grep -i +ASM | grep -v ^# | awk -F: '{print $2}' | tr -d ' ' `
  fi
  export PATH=$ORACLE_HOME/bin:$PATH
 else
  echo "unable to set ASM Home. Exiting."
  status=1
  exit 1
 fi
}

function get_afd_data {

 locate_lsmod

 v_afd_loaded=$($v_lsmod | grep -i oracleafd | wc -l)

 if [ ${v_afd_loaded} -gt 0 ] ; then
   # AFD is running

   get_oratab_loc
   set_asm_home

   # to get list of AFD managed devices
   v_afd_devlist=$($ORACLE_HOME/bin/afdtool -getdevlist -nohdr | awk '{print $2}' | tr -d ' ')

   v_afd_dev_cnt=$(echo $v_afd_devlist | wc -l)

   if [ ${v_afd_dev_cnt} -gt 0 ] ; then
     v_afd_dev=true
   else
     v_afd_dev=false
   fi

 else
  v_afd_dev=false
 fi

}

function check_kernel_for_elevator {

 # at kernel level

 if [ -r /boot/config-`uname -am | awk '{print $3}'` ] ; then
  v_def_kern_iosched=$(cat /boot/config-`uname -am | awk '{print $3}'`| grep CONFIG_DEFAULT_IOSCHED | awk -F= '{print $2}' | sed 's/.*\"\([^]]*\)\".*/\1/')

  if [ "${v_def_kern_iosched}" = "deadline" ]
   then
    report_command=$(echo "$report_command\nKernel default IO scheduler is deadline.")
    status=0
  else
    status=1
  fi
 else
  report_command=$(echo "$report_command\nUnable to read kernel config file.")
  status=1
 fi

}

function check_grub_for_elevator {

 # at boot level

 v_os_rel_num=$(cat /etc/redhat-release | awk '{print $7}' | awk -F. '{print $1}')

 if [ $v_os_rel_num -lt 7 ]
   then
     v_grub_file=/boot/grub/grub.conf
 else
     v_grub_file=/boot/grub2/grub.cfg
 fi

 if [ -r $v_grub_file ]
  then
    v_grub_deadline_check=$(cat $v_grub_file | grep -i vmlinuz-`uname -am | awk '{print $3}'` | grep -v vmlinuz-`uname -am | awk '{print $3}'`.debug | grep -i "elevator=deadline" | wc -l)
    if [ $v_grub_deadline_check = 1 ]
     then
       report_command=$(echo "$report_command\nelevator=deadline is found in grub config file.")
       status=0
    else
       report_command=$(echo "$report_command\nelevator=deadline is not found in grub config file.")
       status=1
    fi
 else
   report_command=$(echo "$report_command\nUnable to read grub config file.")
   status=1
 fi

}

function resolve_device_list {

 get_dm_mp_data
 get_asmlib_data
 get_afd_data

 # dm-mp & asmlib
 if [ $v_dm_mp = true ] && [ $v_asmlib_dev = true ] && [ $v_afd_dev = false ] ; then
  asm_disks=$(echo $v_asmlib_devlist)
 # only asmlib
 elif [ $v_dm_mp = false ] && [ $v_asmlib_dev = true ] && [ $v_afd_dev = false ] ; then
  asm_disks=$(echo $v_asmlib_devlist)
 # dm-mp & afd
 elif [ $v_dm_mp = true ] && [ $v_asmlib_dev = false ] && [ $v_afd_dev = true ]; then
  asm_disks=$(echo $v_afd_devlist)
 # only afd
 elif [ $v_dm_mp = false ] && [ $v_asmlib_dev = false ] && [ $v_afd_dev = true ]; then
  asm_disks=$(echo $v_afd_devlist)
 # only dm-mp
 elif [ $v_dm_mp = true ] && [ $v_asmlib_dev = false ] && [ $v_afd_dev = false ]; then
  asm_disks=$(echo $v_dmmp_devlist)
 # bare bones
 elif [ $v_dm_mp = false ] && [ $v_asmlib_dev = false ] && [ $v_afd_dev = false ]; then
  set_asm_home
  v_asmcmd_owner=$(ls -l $ORACLE_HOME/bin/asmcmd | awk '{print $3}')
  asm_disks=$(su -l $v_asmcmd_owner -c "export ORACLE_SID=$ORACLE_SID;export ORACLE_HOME=$ORACLE_HOME;$ORACLE_HOME/bin/asmcmd lsdsk --suppressheader")
  if [ ! $? -eq 0 ] ; then
   echo "Problem getting the list of ASM Disks."
   status=1
  fi

 else
 # don't know
  echo "Unable to determine device list. Exiting..."
  exit 1
 fi

}

function check_device_for_scheduler {

 resolve_device_list

 for asm_disk in `echo "$asm_disks"`
 do
  # logic to handle OL7 based SYMLINKs
  if [ -L $asm_disk ]
    then
      v_lfile=$asm_disk
      lfile=$(ls -l "$asm_disk" 2>/dev/null|awk -F'->' '{print $2}' | sed -e 's/^ *//' -e 's/ *$//');
      asm_disk=$(basename "$lfile");
      v_os_dev=/dev/$asm_disk

  # logic to handle block devices
  elif [ -b $asm_disk ]
    then
      v_lfile=$(ls -l "$asm_disk" 2>/dev/null|awk '{print $10}' | sed -e 's/^ *//' -e 's/ *$//');
      v_asm_disk=$(basename "$v_lfile");

      # logic to handle dm-multipath devices
      if [ -L /dev/mapper/$v_asm_disk ]
        then
          lfile=$(ls -l "/dev/mapper/$v_asm_disk" 2>/dev/null|awk -F'->' '{print $2}' |awk -F'/' '{print $2}' | sed -e 's/^ *//' -e 's/ *$//');
          asm_disk=$(basename "$lfile");
          v_os_dev=/dev/$asm_disk
      else
      # logic to handle devices
          lfile=$(ls -l "$asm_disk" 2>/dev/null|awk '{print $10}' | sed -e 's/^ *//' -e 's/ *$//');
          asm_disk=$(basename "$lfile");
          v_os_dev=/dev/$asm_disk
      fi
  else
     report_command=$(echo "$report_command\nDevice type unknown")
    status=1
    break
  fi

   # check for deadline io scheduler
  if [ -e /sys/block/${asm_disk}/queue/scheduler ]
    then
      scheduler_count=$(cat /sys/block/${asm_disk}/queue/scheduler |grep -w "\[deadline\]" | wc -l )
      scheduler_info=$(cat /sys/block/${asm_disk}/queue/scheduler | sed 's/.*\[\([^]]*\)\].*/\1/')
      report_command=$(echo "$report_command\nASM Disk is: ${v_lfile}. Underlying OS Disk ${v_os_dev} is currently set to $scheduler_info")
      status=0
  elif [ -e /sys/block/*/${asm_disk}/../queue/scheduler ]
    then
      scheduler_count=$(cat /sys/block/*/${asm_disk}/../queue/scheduler |grep -w "\[deadline\]" | wc -l )
      scheduler_info=$(cat /sys/block/*/${asm_disk}/../queue/scheduler | sed 's/.*\[\([^]]*\)\].*/\1/')
      report_command=$(echo "$report_command\nASM Disk is ${v_lfile}. Underlying OS Disk ${v_os_dev} is currently set to $scheduler_info")
      status=0
  else
      report_command=$(echo "$report_command\nCould not obtain the IO Scheduler info for this device")
      status=1
      break
  fi

#  if [[ $scheduler_count -lt 1 ]]
#   then
#    status=1
#    break
#  fi
 done

 if [[ $scheduler_count -lt 1 ]] ; then
   status=1
 fi

}


# initialize
status=0

# main section

check_os
get_os_user

if [ ${v_os_user} = "root" ] ; then

 # device level
 check_device_for_scheduler

 # boot level  
 if [ $status = 1 ] ; then
   check_grub_for_elevator
 fi

 # kernel level default value
 if [ $status = 1 ] ; then
  check_kernel_for_elevator
 fi

else
 echo "Please run the script $0 as root. Exiting."
 exit 1
fi

# 
# return the result
#
#report_command="IO Scheduler Report Output"
report_command=$(echo "$report_command\n---------------------------")
echo -e "$report_command"
exit $status

