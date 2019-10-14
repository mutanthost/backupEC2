#!/bin/bash

# checkvg.sh
#
# Copyright (c) 2013, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      checkvg.sh
#
#    NOTES

#--------------------------------------------------------------------------------
# PROCEDURE    : get_ext_label
# INPUT        :
# DESCRIPTION  : get label command for the filesystem we need (e2label/e4label)
#------------------------------------------------------------------------------
get_ext_label()
{
   v_logger_msg="Entering ${FUNCNAME}"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   local bin_path=""

   # Bug 28666702 - ol7: verify basic logical volume(lvm) fails on dbsys
   if [ "$(os_at_runtime)" == 'ol7' ]; then
     bin_path=/usr/sbin
   else
     bin_path=/sbin
   fi

   local ext_label=$bin_path/e4label
   [ -x $ext_label ] || ext_label=$bin_path/e2label
   echo "$ext_label"

   v_logger_msg="Leaving ${FUNCNAME}"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
}

#--------------------------------------------------------------------------------
# PROCEDURE    : getFsLabels
# INPUT        :
# DESCRIPTION  : Get fs labels
#------------------------------------------------------------------------------
getFsLabels()
{
   v_logger_msg="Entering ${FUNCNAME}"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   local v_ext_label=$(get_ext_label)
   local v_dev_lst=""
   local v_tmp_dev=""
   local v_tmp_srch=""
   local -i v_el6uek=`uname -a 2>/dev/null | grep el6uek | wc -l`

   # Bug 28666702 - ol7: verify basic logical volume(lvm) fails on dbsys
   if [ ${v_el6uek} -eq 1 ] || [ "$(os_at_runtime)" == 'ol7' ]; then
      v_tmp_srch="LV Path"
   else
      v_tmp_srch="LV Name"
   fi

   for v_tmp_dev in `${v_lvm} lvdisplay --ignorelockingfailure | grep "${v_tmp_srch}" | awk ' { print \$3 } '`
   do
      v_dev_lst="${v_dev_lst} ${v_tmp_dev}"
      imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "v_tmp_dev: ${v_tmp_dev}"
   done
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "v_dev_lst: ${v_dev_lst}"

   local v_sd_cmd="ls -1 /dev/sd?[1-9]"
   local v_dsk
   local v_label

   for v_dsk in ${v_dev_lst} `${v_sd_cmd}`
   do
      v_label=$(${v_ext_label} ${v_dsk} 2>/dev/null)
      if ! [ -z "${v_label}" ]
      then
         v_logger_msg="${v_dsk} has label ${v_label}"
         imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
         echo "${v_label}"
      fi
   done

   v_logger_msg="Leaving ${FUNCNAME}"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
}

#--------------------------------------------------------------------------------
# PROCEDURE    : CheckReclaim
# INPUT        : 
# DESCRIPTION  : Check for possible diskreclaims not done at deployment. 
#                for < 121210, there should not be a dualboot (Solaris + Linux) 
#                "reclaimdisk.sh -isreclaimed -check" returns a 2 if the system is dual  boot 
#
#                for >= 121210, there should not be an OVM + Linux install 
#                "reclaimdisk.sh -isreclaimed -check" returns a 1 in case of both Linux  and DOM0 system partitions exist 
#              
#                See 20519395 
#------------------------------------------------------------------------------
CheckReclaim()
{
   v_logger_msg="Entering ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   local v_current_image_id_maj=0
   local v_reclaim_disk="/opt/oracle.SupportTools/reclaimdisks.sh -isreclaimed -check"
   local -i v_reclaim_ret=0

   v_current_image_id_maj=`/usr/local/bin/imageinfo -ver 2>/dev/null | cut -d \. -f1-5 |  sed -e "s/\.//g"`
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "v_current_image_id_maj: ${v_current_image_id_maj}"
   imageLogger_logMsg $lvmchecker "$imageLogger_LOG_CMDOUT" "${v_reclaim_disk}"

   if [ ${v_current_image_id_maj} -gt 0  ]
   then
      ${v_reclaim_disk} >/dev/null 2>&1
      v_reclaim_ret=$?
      if [  ${v_current_image_id_maj} -gt 121111  ]
      then
         if [ ${v_reclaim_ret} -eq 1 ]
         then
            v_e_message="Both Linux and DOM0 system partitions exist, which is not expected"
            v_checks_failed="CheckReclaim"
            PrintErrorReturn noexit
         else
            v_logger_msg="PASS: No reclaimdisk issues found"
            PrintMsg nolog info "${v_logger_msg}"
         fi
      else
         if [ ${v_reclaim_ret} -eq 2 ]
         then
            v_e_message="Both Linux and Solaris system partitions exist, the system is dual boot which is not expected"
            v_checks_failed="CheckReclaim"
            PrintErrorReturn noexit
         else
            v_logger_msg="PASS: No reclaimdisk issues found"
            PrintMsg nolog info "${v_logger_msg}"
         fi
      fi
   fi

   v_logger_msg="Leaving ${FUNCNAME}"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
}

#--------------------------------------------------------------------------------
# PROCEDURE    : CheckLabels
# INPUT        : label name (DBSYS / DBORA)
# DESCRIPTION  : Check we have exactly one lvm with $1 as label
#------------------------------------------------------------------------------
CheckLabels()
{
   v_logger_msg="Entering CheckLabels"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   local -i v_tmp_cnt=0

   if [ "${v_lvm_install}" == "yes" ]
   then
      if [ "${v_server_brand}" == "DOM0" ]
      then
         local v_match_label=DBSYSOVS
      else
         local v_match_label=DBSYS
      fi

      v_tmp_cnt=`getFsLabels 2>/dev/null | grep ${v_match_label}$ | wc -l`
      if [ $v_tmp_cnt -ne 1 ]
      then
         # If not just 1 label then we have a problem
         if [ $v_tmp_cnt -eq 0 ]
         then
            v_checks_failed="CheckLabels"
            v_e_message="This is system no filesystem labels of ${v_match_label} wich is not expected."
            PrintErrorReturn noexit
         fi

         if [ $v_tmp_cnt -gt 1 ]
         then
            # If > 1 same labels then we have a problem
            v_checks_failed="CheckLabels"
            v_e_message="This is system has one or more similar filesystem labels (${v_match_label}). Only one is expected."
            PrintErrorReturn noexit
         fi
      else
         # 20719770 
         v_tmp_cnt=`grep -a -s -v ^# /etc/fstab | head -1 | grep -a -s "LABEL=${v_match_label}" | wc -l`
         if [ $v_tmp_cnt -ne 1 ]
         then
            # If ne 1 we don't have LABEL=DBSYS or LABEL=DBSYSOVS in the first line of /etc/fstab
            v_checks_failed="CheckLabels"
            v_e_message="First line of /etc/fstab does not display LABEL=${v_match_label}"
            PrintErrorReturn noexit
         else
            v_logger_msg="PASS: No filesystem label issues for ${v_match_label}"
            PrintMsg nolog info "${v_logger_msg}"
         fi
      fi
   else
      v_checks_failed="CheckIsLvmSys"
      v_e_message="This check does not apply because this system is not configured with Logical Volumes (LV)"
      PrintErrorReturn exit
   fi

   v_logger_msg="Leaving CheckLabels"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
}

#--------------------------------------------------------------------------------
# PROCEDURE    : PrintMsg
# INPUT        : $1: log the message (log/nolog)
#              : $2: state (error/info/warning)
#              : $3: message (string)
# DESCRIPTION  : Print output in a similar formatted way. Needs further output formatting
#------------------------------------------------------------------------------
PrintMsg()
{
   local v_log="${1}"
   local v_state="${2}"
   local v_mesg="${3}"

   case "${v_state}" in
         error)
                echo "  (*) - ERROR: "${v_mesg}""
                if [ "${v_log}" == "log" ]
                then
                   imageLogger_logMsg $lvmchecker $imageLogger_LOG_ERROR "${v_logger_msg}"
                fi
                ;;
         info)
                echo "  (*) "${v_mesg}""
                if [ "${v_log}" == "log" ]
                then
                   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
                fi
                ;;
         warning)
                echo "  (*) - WARNING: "${v_mesg}""
                if [ "${v_log}" == "log" ]
                then
                   imageLogger_logMsg $lvmchecker $imageLogger_LOG_WARNING "${v_logger_msg}"
                fi
                ;;
         esac
}

#--------------------------------------------------------------------------------
# PROCEDURE    : usage
# INPUT        :
# DESCRIPTION  : Print the options/flags the user can use with an example. eeds further finishing
#------------------------------------------------------------------------------
usage()
{
   echo
   PrintMsg log info  "Use this script as follows: ./${v_myname} checkall|vgfree|lvmactive|lvmsize|lvmmin|vgexa|islvm|lvmmax|checklabels|checkreclaim"
   echo
}

#--------------------------------------------------------------------------------
# PROCEDURE    : InitLog
# INPUT        :
# DESCRIPTION  :
#------------------------------------------------------------------------------
InitLog()
{
   v_logger_msg="Entering ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   v_logger_msg="zzz"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   v_logger_msg="#################################################################################"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   v_logger_msg="# ${v_myname} script rel. : ${v_myname_version} started at ${v_timestamp} (runid :${v_runid})"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   v_logger_msg="# arguments given         : ${v_arguments}"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   v_logger_msg="#################################################################################"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   v_logger_msg="Leaving ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
}

#--------------------------------------------------------------------------------
# PROCEDURE    : ExecAllChecks
# INPUT        :
# DESCRIPTION  : Execute all checks described in 19068757 
#------------------------------------------------------------------------------
ExecAllChecks()
{
   v_logger_msg="Entering ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   CheckIsLvmSys
   CheckVGExa
   CheckMinLvm
   CheckMaxLvm
   CheckLvmSize
   CheckLvmActive
   CheckFreeSpaceVG
   CheckLabels
   CheckReclaim

   v_logger_msg="Leaving ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
}

#--------------------------------------------------------------------------------
# PROCEDURE    : PrintErrorReturn
# INPUT        : $1: exit/noexit 
#                also uses glbal var. v_checks_failed and v_error_cnt
# DESCRIPTION  : return exit code and print out the error itself
#                only for non-lvm systems it should exit 1 immediately
#------------------------------------------------------------------------------
PrintErrorReturn()
{
   v_logger_msg="Entering ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   local v_error=""

   if [ "${v_checks_failed}" != "" ]
   then
      for v_error in "${v_checks_failed}"
      do
         v_logger_msg="Failed on ${v_error}"
         imageLogger_logMsg $lvmchecker $imageLogger_LOG_ERROR "${v_logger_msg}"
         case "${v_error}" in
             CheckIsLvmSys)
                    PrintMsg log error "${v_e_message}"
                    v_logger_msg="Command to validate: awk -F= '/^lvm=/ {print $2}' /opt/oracle.cellos/ORACLE_CELL_OS_IS_SETUP"
                    imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
                     ;;
             CheckVGExa)
                    PrintMsg log error "${v_e_message}"
                    v_logger_msg="Command to validate: ${v_lvdisplay} --ignorelockingfailure --columns --noheadings -o +vg_name,lv_name"
                    imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
                     ;;
             CheckMinLvm)
                    PrintMsg log error "${v_e_message}"
                    v_logger_msg="Command to validate: ${v_lvdisplay} --ignorelockingfailure --columns --noheadings -o lv_name | grep  LVDbSys[1-2] | wc -l"
                    imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
                     ;;
             CheckMaxLvm)
                    PrintMsg log error "${v_e_message}"
                    v_logger_msg="Command to validate: ${v_lvdisplay} --ignorelockingfailure --columns --noheadings -o lv_name | grep  LVDbSys[1-3] | wc -l"
                    imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
                     ;;
             CheckLvmSize)
                    PrintMsg log error "${v_e_message}"
                    v_logger_msg="Command to validate: ${v_lvdisplay} --ignorelockingfailure --columns --noheadings -o +lv_name,lv_size --units g"
                    imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
                     ;;
             CheckFreeSpaceVG)
                    PrintMsg log error "${v_e_message}"
                    v_logger_msg="Command to validate: ${v_vgdisplay}  VGExaDb --ignorelockingfailure --columns --noheadings -o vg_free"
                    imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
                     ;;
             CheckLvmActive)
                    PrintMsg log error "${v_e_message}"
                    v_logger_msg="Command to validate: find active Sys lvm with imageinfo -sys. If active Sys lvm is Sys1, then Sys2 should not be mounted"
                    imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
                     ;;
             CheckLabels)
                    PrintMsg log error "${v_e_message}"
                    v_logger_msg="Command to validate: Use e2label or (e4label for OL6). Filesystems should not have the same label"
                    imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
                     ;;
             CheckReclaim)
                    PrintMsg log error "${v_e_message}"
                    v_logger_msg="Command to validate: Use /opt/oracle.SupportTools/reclaimdisks.sh. System should not be dual boot or have OVM + Linux"
                    imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
                     ;;
         esac
         unset v_e_message
      done

      # only for non-lvm systems it should exit 1 immediately
      # for others we accumulate
      if [ "${1}" == "exit" ]
      then
         exit 1
      else
         v_error_cnt=`expr ${v_error_cnt} + 1 2>/dev/null`
      fi
      imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "v_error_cnt: ${v_error_cnt}"
   fi

   v_logger_msg="Leaving ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
}

#--------------------------------------------------------------------------------
# PROCEDURE    : CheckMaxLvm
# INPUT        :
# DESCRIPTION  : Count the max number of Sys lvms. For all prod systems it should never be 3
#------------------------------------------------------------------------------
CheckMaxLvm()
{
   v_logger_msg="Entering ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   local -i v_tmp_cnt=0

   if [ "${v_lvm_install}" != "yes" ]
   then
      v_checks_failed="CheckIsLvmSys"
      v_e_message="This check does not apply because this system is not configured with Logical Volumes (LV)"
      PrintErrorReturn exit
   fi

   v_tmp_cnt=`${v_lvdisplay} --ignorelockingfailure --columns --noheadings -o lv_name 2>/dev/null | grep " LVDbSys[1-3] "| wc -l`

   if [ ${v_tmp_cnt} -ge 3 ] 
   then
       v_checks_failed="CheckMaxLvm"
       v_e_message="This is system has more than two LVDbSys LV's which is unexpected."
       PrintErrorReturn noexit
   else
      v_logger_msg="PASS: Maximum number of LVDbSys LV's"
      PrintMsg nolog info "${v_logger_msg}"
   fi

   v_logger_msg="Leaving ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
}

#--------------------------------------------------------------------------------
# PROCEDURE    : CheckMinLvm
# INPUT        :
# DESCRIPTION  : Count the min number of Sys lvms. For systems running on Sys2 we expect a Sys1, which makes 2
#------------------------------------------------------------------------------
CheckMinLvm()
{
   v_logger_msg="Entering ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   local v_imageinfo="/usr/local/bin/imageinfo"
   local v_active_image=`${v_imageinfo} --system-partition 2>/dev/null`
   local -i v_tmp_cnt=0

   if [ "${v_lvm_install}" != "yes" ]
   then
      v_checks_failed="CheckIsLvmSys"
      PrintErrorReturn exit
      v_e_message="This check does not apply because this system is not configured with Logical Volumes (LV)"
   fi

   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "v_imageinfo: ${v_imageinfo}"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "v_active_image: ${v_active_image}"

   if [ "${v_server_brand}" == "DOM0" ]
   then
      if [ "${v_active_image}" == "/dev/mapper/VGExaDb-LVDbSys2" ]
      then
         # We expect at least LVDbSys2
         v_tmp_cnt=`${v_lvdisplay} --ignorelockingfailure --columns --noheadings -o lv_name 2>/dev/null | grep " LVDbSys[2-3] "| wc -l`
         if [ ${v_tmp_cnt} -lt 1 ] 
         then
            v_checks_failed="CheckMinLvm"
            v_e_message="This is system does not have the expected minimum number of LVDbSys LV's (1)"
            PrintErrorReturn noexit
         else
            v_logger_msg="PASS: Minimum number of Sys lvms"
            PrintMsg nolog info "${v_logger_msg}"
         fi
      fi

      if [ "${v_active_image}" == "/dev/mapper/VGExaDb-LVDbSys3" ]
      then
         # We expect at least LVDbSys3 and LVDbSys2 to exist
         v_tmp_cnt=`${v_lvdisplay} --ignorelockingfailure --columns --noheadings -o lv_name 2>/dev/null | grep " LVDbSys[2-3] "| wc -l`
         if [ ${v_tmp_cnt} -lt 2 ] 
         then
            v_checks_failed="CheckMinLvm"
            v_e_message="This is system does not have the expected minimum number of LVDbSys LV's (2)"
            PrintErrorReturn noexit
         else
            v_logger_msg="PASS: Minimum number of Sys lvms"
            PrintMsg nolog info "${v_logger_msg}"
         fi
      fi
   else
      if [ "${v_active_image}" == "/dev/mapper/VGExaDb-LVDbSys1" ]
      then
         # We expect at least LVDbSys1
         v_tmp_cnt=`${v_lvdisplay} --ignorelockingfailure --columns --noheadings -o lv_name 2>/dev/null | grep " LVDbSys[1-2] "| wc -l`
         if [ ${v_tmp_cnt} -lt 1 ] 
         then
            v_checks_failed="CheckMinLvm"
            v_e_message="This is system does not have the expected minimum number of LVDbSys LV's (1)"
            PrintErrorReturn noexit
         else
            v_logger_msg="PASS: Minimum number of Sys lvms"
            PrintMsg nolog info "${v_logger_msg}"
         fi
      fi

      if [ "${v_active_image}" == "/dev/mapper/VGExaDb-LVDbSys2" ]
      then
         # We expect at least LVDbSys1 and LVDbSys2 to exist
         v_tmp_cnt=`${v_lvdisplay} --ignorelockingfailure --columns --noheadings -o lv_name 2>/dev/null | grep " LVDbSys[1-2] "| wc -l`
         if [ ${v_tmp_cnt} -lt 2 ] 
         then
            v_checks_failed="CheckMinLvm"
            v_e_message="This is system does not have the expected minimum number of LVDbSys LV's (2)"
            PrintErrorReturn noexit
         else
            v_logger_msg="PASS: Minimum number of LVDbSys LV's"
            PrintMsg nolog info "${v_logger_msg}"
         fi
      fi
   fi

   v_logger_msg="Leaving ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
}

#--------------------------------------------------------------------------------
# PROCEDURE    : CheckLvmSize
# INPUT        :
# DESCRIPTION  : Check for a minimum size and for both sys lvms to be the same size
#------------------------------------------------------------------------------
CheckLvmSize()
{
   v_logger_msg="Entering ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   local v_dbvg="VGExaDb"
   local v_imageinfo="/usr/local/bin/imageinfo"
   local v_active_lvm_name=`${v_imageinfo} --system-partition 2>/dev/null`
   local -i v_tmp_cnt=0

   if [ "${v_lvm_install}" != "yes" ]
   then
      v_checks_failed="CheckIsLvmSys"
      v_e_message="This check does not apply because this system is not configured with Logical Volumes (LV)"
      PrintErrorReturn exit
   fi

   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "v_imageinfo: ${v_imageinfo}"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "v_active_lvm_name: ${v_active_lvm_name}"

   if [ "${v_server_brand}" == "DOM0" ]
   then
      # If active lvm is 3 then inactive is 2 and vise versa
      # On OVS lvmsys1 should be reclaimed and not exist
      # What remains is lvmsys2 and lvmsys3
      if [ "${v_active_lvm_name}" == "/dev/mapper/${v_dbvg}-LVDbSys3" ]
      then
         v_inactive_lvm_name=/dev/mapper/${v_dbvg}-LVDbSys2
         v_inactive_lvm_block="/dev/${v_dbvg}/LVDbSys2"
         v_active_lvm_block="/dev/${v_dbvg}/LVDbSys3"
         v_inactive_part_no=2
      fi

      # If active lvm is 2 then inactive is 3 and vise versa
      if [ "${v_active_lvm_name}" == "/dev/mapper/${v_dbvg}-LVDbSys2" ]
      then
         v_inactive_lvm_name=/dev/mapper/${v_dbvg}-LVDbSys3
         v_inactive_lvm_block="/dev/${v_dbvg}/LVDbSys3"
         v_active_lvm_block="/dev/${v_dbvg}/LVDbSys2"
         v_inactive_part_no=3
      fi
   else
      # If active lvm is 1 then inactive is 2 and vise versa
      if [ "${v_active_lvm_name}" == "/dev/mapper/${v_dbvg}-LVDbSys1" ]
      then
         v_inactive_lvm_name=/dev/mapper/${v_dbvg}-LVDbSys2
         v_inactive_lvm_block="/dev/${v_dbvg}/LVDbSys2"
         v_active_lvm_block="/dev/${v_dbvg}/LVDbSys1"
         v_inactive_part_no=2
      fi

      # If active lvm is 1 then inactive is 2 and vise versa
      if [ "${v_active_lvm_name}" == "/dev/mapper/${v_dbvg}-LVDbSys2" ]
      then
         v_inactive_lvm_name=/dev/mapper/${v_dbvg}-LVDbSys1
         v_inactive_lvm_block="/dev/${v_dbvg}/LVDbSys1"
         v_active_lvm_block="/dev/${v_dbvg}/LVDbSys2"
         v_inactive_part_no=1
      fi
   fi

   # Check min size of active lvm
   local -i v_ac_lvm_size=`${v_lvdisplay} --ignorelockingfailure --columns --noheadings -o lv_size --units g ${v_active_lvm_name} 2>/dev/null \
                            | awk -F "." ' { print $1 } ' \
                            | sed -e "s/ //g"`
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "v_ac_lvm_size: ${v_ac_lvm_size}"

   if [ ${v_ac_lvm_size} -lt ${v_lvmsys_min_size_gb} ]
   then
      v_e_message="Size of active LV (${v_active_lvm_name}) (${v_ac_lvm_size}GB) smaller than minimum size (${v_lvmsys_min_size_gb}GB)"
      imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_e_message}"
      v_checks_failed="CheckLvmSize"
      PrintErrorReturn noexit
   else
      v_logger_msg="PASS: LVDbSys LV minimum size of ${v_active_lvm_name}"
      PrintMsg nolog info "${v_logger_msg}"
   fi

   if [ -b "${v_inactive_lvm_name}" ] 
   then
       # When exists check size of the inactive device. It should be the same as active
       local -i v_inac_lvm_size=`${v_lvdisplay} --ignorelockingfailure --columns --noheadings -o lv_size --units g ${v_inactive_lvm_name} 2>/dev/null \
                               | awk -F "." ' { print $1 } ' \
                               | sed -e "s/ //g"`

       imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "v_ac_lvm_size: ${v_ac_lvm_size}"
       imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "v_inac_lvm_size: ${v_inac_lvm_size}"

       if [ ${v_inac_lvm_size} -ne ${v_ac_lvm_size} ]
       then
          v_e_message="Inactive LV (${v_inactive_lvm_name}) (${v_inac_lvm_size}GB) not equal to active LV ${v_active_lvm_name} (${v_ac_lvm_size}GB)." 
          imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_e_message}"
          v_checks_failed="CheckLvmSize"
          PrintErrorReturn noexit
       else
          v_logger_msg="PASS: LVDbSys LV size"
          PrintMsg nolog info "${v_logger_msg}"
       fi

       if [ ${v_inac_lvm_size} -lt ${v_lvmsys_min_size_gb} ]
       then
          v_e_message="Size of inactive LV (${v_inactive_lvm_name}) (${v_inac_lvm_size}GB) smaller than minimum size (${v_lvmsys_min_size_gb}GB)"
          imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_e_message}"
          v_checks_failed="CheckLvmSize"
          PrintErrorReturn noexit
       else
          v_logger_msg="PASS: LVDbSys inactive LV minimum size of ${v_inactive_lvm_name}"
          PrintMsg nolog info "${v_logger_msg}"
       fi
   fi

   v_logger_msg="Leaving ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
}

#--------------------------------------------------------------------------------
# PROCEDURE    : CheckLvmActive
# INPUT        :
# DESCRIPTION  : Only Sys1 or Sys2 should be mounted
#------------------------------------------------------------------------------
CheckLvmActive()
{
   v_logger_msg="Entering ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   local v_lvm="/sbin/lvm"
   local v_dbvg="VGExaDb"
   local v_imageinfo="/usr/local/bin/imageinfo"
   local v_active_lvm_name=`${v_imageinfo} --system-partition 2>/dev/null`
   local -i v_tmp_cnt=1

   if [ "${v_lvm_install}" != "yes" ]
   then
      v_checks_failed="CheckIsLvmSys"
      v_e_message="This check does not apply because this system is not configured with Logical Volumes (LV)"
      PrintErrorReturn exit
   fi

   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "v_imageinfo: ${v_imageinfo}"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "v_active_lvm_name: ${v_active_lvm_name}"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "v_server_brand: ${v_server_brand}"

   if [ "${v_server_brand}" == "DOM0" ]
   then
      if [ "${v_active_lvm_name}" == "/dev/mapper/VGExaDb-LVDbSys2" ]
      then
         v_inactive_lvm_name=/dev/mapper/VGExaDb-LVDbSys3
         v_tmp_cnt=`/bin/mount -l | grep ${v_inactive_lvm_name} | wc -l`
      fi

      if [ "${v_active_lvm_name}" == "/dev/mapper/VGExaDb-LVDbSys3" ]
      then
         v_inactive_lvm_name=/dev/mapper/VGExaDb-LVDbSys2
         v_tmp_cnt=`/bin/mount -l | grep ${v_inactive_lvm_name} | wc -l`
      fi
   else
      if [ "${v_active_lvm_name}" == "/dev/mapper/VGExaDb-LVDbSys1" ]
      then
         v_inactive_lvm_name=/dev/mapper/VGExaDb-LVDbSys2
         v_tmp_cnt=`/bin/mount -l | grep ${v_inactive_lvm_name} | wc -l`
      fi

      if [ "${v_active_lvm_name}" == "/dev/mapper/VGExaDb-LVDbSys2" ]
      then
         v_inactive_lvm_name=/dev/mapper/VGExaDb-LVDbSys1
         v_tmp_cnt=`/bin/mount -l | grep ${v_inactive_lvm_name} | wc -l`
      fi
   fi

   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "v_tmp_cnt: ${v_tmp_cnt}"

   if [ ${v_tmp_cnt} -eq 0 ]
   then
      v_logger_msg="PASS: Inactive LVDbSys LV's not mounted"
      PrintMsg nolog info "${v_logger_msg}"
   else
      v_checks_failed="CheckLvmActive"
      v_e_message="This is system has inactive LV's (${v_inactive_lvm_name}) mounted which is not expected."
      PrintErrorReturn noexit
   fi
   
   v_logger_msg="Leaving ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
}

#--------------------------------------------------------------------------------
# PROCEDURE    : is_second_arg_equal_or_bigger
# INPUT        :
#              :
# DESCRIPTION  :
#------------------------------------------------------------------------------
is_second_arg_equal_or_bigger ()
{
  # Remove any non digits from the both arguments
  local -i first=`echo $1 | perl -pne 's/\D//g'`
  local -i second=`echo $2 | perl -pne 's/\D//g'`

  [ $second -ge $first ] && return 0
  return 1
}


#--------------------------------------------------------------------------------
# PROCEDURE    : CheckFreeSpaceVG
# INPUT        :
# DESCRIPTION  : Check is there is enough free space if the vg (Sys1+Sys2+snapshot)
#------------------------------------------------------------------------------
CheckFreeSpaceVG()
{
   v_logger_msg="Entering ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   local v_dbvg="VGExaDb"
   local v_imageinfo="/usr/local/bin/imageinfo"
   local v_active_lvm_name=`${v_imageinfo} --system-partition 2>/dev/null`

   if [ "${v_lvm_install}" != "yes" ]
   then
      v_checks_failed="CheckIsLvmSys"
      v_e_message="This check does not apply because this system is not configured with Logical Volumes (LV)"
      PrintErrorReturn exit
   fi

   # 25660458 - only test for free space when LVDoNotRemoveOrUse does not exist
   if ! [ -b /dev/VGExaDb/LVDoNotRemoveOrUse ]
   then
      # Check free space in the Volume group
      vg_free_size_gb=`${v_vgdisplay} --ignorelockingfailure --columns --noheadings -o vg_free --units g ${v_dbvg} 2>/dev/null`
      if [ -z "$vg_free_size_gb" ]
      then
         v_logger_msg="Unable to get total amount of free space in Volume group ${v_dbvg}"
         imageLogger_logMsg $lvmchecker $imageLogger_LOG_ERROR "${v_logger_msg}"
      fi
      vg_free_size_gb=`echo $vg_free_size_gb`
      imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "vg_free_size_gb: ${vg_free_size_gb}"
   
      vg_free_size_sc=`${v_vgdisplay} --ignorelockingfailure --columns --noheadings -o vg_free --units s ${v_dbvg} 2>/dev/null`
      if [ -z "$vg_free_size_sc" ]
      then
         v_logger_msg="Unable to get total amount of free space in Volume group ${v_dbvg}"
         imageLogger_logMsg $lvmchecker $imageLogger_LOG_ERROR "${v_logger_msg}"
      fi
      vg_free_size_sc=`echo $vg_free_size_sc`
      imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "vg_free_size_sc: ${vg_free_size_sc}"
    
      v_logger_msg="Total amount of free space: $vg_free_size_gb ($vg_free_size_sc)"
      imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
   
      # Get size of root LVM partition
      root_size_gb=`${v_lvdisplay} --ignorelockingfailure --columns --noheadings -o lv_size --units g ${v_active_lvm_name} 2>/dev/null`
      if [ -z "$root_size_gb" ]
      then
         v_logger_msg="Unable to get size of the root partition ${v_active_lvm_name}"
         imageLogger_logMsg $lvmchecker $imageLogger_LOG_ERROR "${v_logger_msg}"
      fi
      root_size_gb=`echo $root_size_gb`
      imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "root_size_gb: ${root_size_gb}"
   
      root_size_sc=`${v_lvdisplay} --ignorelockingfailure --columns --noheadings -o lv_size --units s ${v_active_lvm_name} 2>/dev/null`
      if [ -z "$root_size_sc" ]
      then
         v_logger_msg="Unable to get size of the root partition ${v_active_lvm_name}"
         imageLogger_logMsg $lvmchecker $imageLogger_LOG_ERROR "${v_logger_msg}"
      fi
      root_size_sc=`echo $root_size_sc`
      imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "root_size_sc: ${root_size_sc}"
   
      # For system that have only LVDbSys1 or LVDbsys2 free space has to be equal or bigger than one root partition
      # this to make sure LVDbSys1 and LVDbSys2 both exist
      # plus the space for the snapshot which is 1GB (+10M) (calculation is in sector size where 1 sector=512 bytes)
      # lvm lvcreate -L 1G -s -n $LV_ROOT_SNAP $g_lv_root
   
      # LVM layout for OVS systems differs from regular
      if [ "${v_server_brand}" == "DOM0" ]
      then
         local -i v_lvm_cnt=`${v_lvdisplay} --ignorelockingfailure --columns --noheadings 2>/dev/null | grep -a -s  LVDbSys[2-3] | wc -l`
      else
         local -i v_lvm_cnt=`${v_lvdisplay} --ignorelockingfailure --columns --noheadings 2>/dev/null | grep -a -s  LVDbSys[1-2] | wc -l`
      fi
   
      if [ ${v_lvm_cnt} -lt 2 ]
      then
         # We assume LVDbSys2 (or 3) is not created yet
         # So we require the space of LVDbSys1 (or 2) + (1GB+10M)
         # Add 2117632 sectors (1GB+10M) to the found root_size_sc
   
         # Remove the "S" and add the number
         root_size_sc=`echo $root_size_sc 2>/dev/null | sed 's/[^0-9]*//g'`
         root_size_sc="`expr ${root_size_sc} + 2117632 2>/dev/null`S"
         v_logger_msg="Adding 2117632 (1GB + 10M) sectors to root_size_sc. New value for root_size_sc: ${root_size_sc}"
         imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
   
         # If the free space in the VG is larger than the root size than we are good
         is_second_arg_equal_or_bigger $root_size_sc $vg_free_size_sc
         if [ $? -ne 0 ]
         then
            v_checks_failed="CheckFreeSpaceVG"
            PrintErrorReturn noexit
            v_e_message="Total amount of free space in the volume group is less than ${root_size_gb}GB + 1GB. Unable to make a backup"
         else
            v_logger_msg="PASS: Enough free space found for snapshot"
            PrintMsg nolog info "${v_logger_msg}"
         fi
      else
         # We assume active syslvm and inactive syslvm exist and require only enough space for the 1GB snapshot
         # Remove the "S" from vg_free_size_sc
         vg_free_size_sc=`echo ${vg_free_size_sc} | sed 's/[^0-9]*//g'`
         if [ ${vg_free_size_sc} -lt 2117632 ]
         then
            v_checks_failed="CheckFreeSpaceVG"
            v_e_message="Total amount of free space in VG (${v_dbvg}) is less than 1GB. Unable to make a snapshot"
            PrintErrorReturn noexit
         else
               v_logger_msg="PASS: Enough free space found for snapshot"
               PrintMsg nolog info "${v_logger_msg}"
         fi
      fi
   else
      v_logger_msg="PASS: Enough free space found for snapshot"
      PrintMsg nolog info "${v_logger_msg}"
   fi

   v_logger_msg="Leaving ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
}

#--------------------------------------------------------------------------------
# PROCEDURE    : CheckVGExa
# INPUT        :
# DESCRIPTION  : For domU and normal hw: LVDbSys1 and LVDbSys2 should always reside in VGExa (CheckVGExa)
#              : For dom0              : LVDbSys2 and LVDbSys3 should always reside in VGExa (CheckVGExa)
#------------------------------------------------------------------------------
CheckVGExa()
{
   v_logger_msg="Entering ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   local v_lvm_name=""
   local -i v_tmp_cnt=0
   local -i c=0

   if [ "${v_lvm_install}" != "yes" ]
   then
      v_checks_failed="CheckIsLvmSys"
      v_e_message="This check does not apply because this system is not configured with Logical Volumes (LV)"
      PrintErrorReturn exit
   fi

   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "v_syslvms: ${v_syslvms}"

   for v_lvm_name in `${v_lvdisplay} --ignorelockingfailure --columns --noheadings -o lv_name 2>/dev/null | grep " ${v_syslvms} " | sed -e "s/ //g"`
   do
      imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "checking lvm: ${v_lvm_name}"
      v_tmp_cnt=`${v_lvdisplay} --ignorelockingfailure --columns --noheadings -o vg_name /dev/VGExaDb/${v_lvm_name} 2>/dev/null | wc -l`
      if [ ${v_tmp_cnt} -eq 0 ]
      then
         imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "issue with lvm: ${v_lvm_name}"
         c=`expr ${c} + 1`
      else
         imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "lvm: ${v_lvm_name} ok"
      fi

      if [ ${c} -gt 0 ]
      then
         v_checks_failed="CheckVGExa"
         PrintErrorReturn noexit
         v_e_message="This is system does not have the expected Volume Group (VG) VGExaDb."
      else
         v_logger_msg="PASS:  ${v_lvm_name} should reside in Volume Group (VG) VGExaDb."
         PrintMsg nolog info "${v_logger_msg}"
      fi
   done

   v_logger_msg="Leaving ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
}

#--------------------------------------------------------------------------------
# PROCEDURE    : CheckIsLvmSys
# INPUT        :
# DESCRIPTION  : Check is the system is lvm enabled
#------------------------------------------------------------------------------
CheckIsLvmSys()
{
   v_logger_msg="Entering ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   if [ "${v_lvm_install}" != "yes" ]
   then
      v_checks_failed="CheckIsLvmSys"
      v_e_message="This is system does not have lvm configured. System with lvm enabled have rollback options and are recommended."
      PrintErrorReturn exit
   else
      v_logger_msg="PASS: This is an LV (Logical Volume) enabled system "
      PrintMsg nolog info "${v_logger_msg}"
   fi

   v_logger_msg="Leaving ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
}

#--------------------------------------------------------------------------------
# PROCEDURE    : DetermineModel
# INPUT        :
# DESCRIPTION  : 
#------------------------------------------------------------------------------
DetermineModel()
{
   v_logger_msg="Entering ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"

   # Model will either be HP or Sun. For Sun we can have Sun and SUN
   # serverModel=`/usr/sbin/dmidecode -s system-product-name 2>/dev/null | sed '/^#/d;s/ *$//'`
   if [ -f /usr/sbin/exadata.img.hw ]
   then
     serverModel=$(/usr/sbin/exadata.img.hw --get model 2>/dev/null | sed '/^#/d;s/ *$//')
   else 
     serverModel=$(/usr/sbin/dmidecode -s system-product-name 2>/dev/null | sed '/^#/d;s/ *$//')
   fi
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "serverModel: ${serverModel}"

   v_lvm_install=`awk -F= '/^lvm=/ {print $2}' /opt/oracle.cellos/ORACLE_CELL_OS_IS_SETUP 2>/dev/null`
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "v_lvm_install: ${v_lvm_install}"

   # For domU
   local v_tmp_cnt=`echo ${serverModel} | grep domU | wc -l`
   if [ ${v_tmp_cnt} -eq 1 ]
   then
      # VM Image
      v_server_brand=DOMU
      v_lvmsys_min_size_gb=12
      v_syslvms="LVDbSys[1-2]"
   elif [ -f /etc/ovs-release ]
   then
      # For Dom0
      v_server_brand=DOM0
      v_syslvms="LVDbSys[2-3]"
      v_lvmsys_min_size_gb=30
   else
      # For baremetal
      v_server_brand=SUN
      v_syslvms="LVDbSys[1-2]"
      v_lvmsys_min_size_gb=30
   fi

   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "v_server_brand: ${v_server_brand}"
   imageLogger_logMsg $lvmchecker "$imageLogger_LOG_CMDOUT" "${v_vgdisplay}"
   imageLogger_logMsg $lvmchecker "$imageLogger_LOG_CMDOUT" "${v_lvdisplay}"
   imageLogger_logMsg $lvmchecker "$imageLogger_LOG_CMDOUT" "/bin/mount -l"

   v_logger_msg="Leaving ${FUNCNAME} $1 $2 $3"
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "${v_logger_msg}"
}

#--------------------------------------------------------------------------------
# PROCEDURE    : CheckandPrepUtils
# INPUT        :
# DESCRIPTION  : This script requires imageLogger and imageLogger requires exadata.img.env
#                Older images may not have these libraries
#                For this reason these files need to be packaged with checkvg.sh
#                If files can be found locally, we use these, if not we copy them over
#------------------------------------------------------------------------------
CheckandPrepUtils()
{
   for v_file in exadata.img.env imageLogger
   do
      if ! [ -e /opt/oracle.cellos/${v_file} ]
      then
         cp -af ${v_pwd}/${v_file} /opt/oracle.cellos/ 2>/dev/null
         if [ $? -ne 0 ]
         then
            echo "[ERROR] Unable to find required Exadata environment file, /opt/oracle.cellos/${v_file}."
            exit 1
         fi
      fi
   done
}


#--------------------------------------------------------------------------------
# MAIN         : Start of script
# INPUT        :
# DESCRIPTION  : Support only Linux
#------------------------------------------------------------------------------
[[ $(uname) != Linux ]] && {
  PrintMsg nolog info
  PrintMsg nolog info "This script only support on Linux, exiting..."
  PrintMsg nolog info
  exit 1
}

#--------------------------------------------------------------------------------
# ENV SETTINGS :
# INPUT        :
# DESCRIPTION  : Default env settings
#------------------------------------------------------------------------------
LANG="en_US.UTF-8"
LC_ALL=C
export LANG LC_ALL


#--------------------------------------------------------------------------------
# PARAMS       :
# INPUT        :
# DESCRIPTION  : Default param values
#------------------------------------------------------------------------------
v_checks_failed=""
v_action=""
v_myname="checkvg.sh"
v_logfile=checkvg
v_timestamp=`date '+%d%m%y_%H%M%S'`
v_runid=`date '+%d%m%y%H%M%S'`
v_arguments="$@"
v_imagelogger="imageLogger"
v_error_cnt=0
v_myname_version="1.05"
v_pwd="$(dirname $(readlink -f $0))"
v_vgdisplay="/sbin/lvm vgdisplay"
v_lvdisplay="/sbin/lvm lvdisplay"
v_lvm_install=no

# Checks we implement according to 19068757 
#------------------------------------------------------------------------------
# 1.  A system may not be an lvm enabled system - then the check does not apply  (CheckIsLvmSys)
# 1b. LVDbSys1 and LVDbSys2 should always reside in VGExa (CheckVGExa) for domU and regular HW
# 1c. LVDbSys2 and LVDbSys3 should always reside in VGExa (CheckVGExa) for dom0
# 2.  The LVDbSys2 lvm can exist - but does not have to (CheckMinLvm)
# 2a. The LVDbSys3 lvm can exist - but does not have to (CheckMinLvm)
# 3.  If LVDbSys1 lvm is active - LVDbSys2 can exist, then LVDbSys2 and LVDbSys1  should be the same size (CheckLvmSize) 
# 3a  If LVDbSys2 lvm is active - LVDbSys3 can exist, then LVDbSys2 and LVDbSys3  should be the same size (CheckLvmSize) 
# 4.  If LVDbSys2 lvm is active - LVDbSys1 exists - then LVDbSys2 and LVDbSys1  should be the same size (CheckLvmSize)
# 4a. If LVDbSys3 lvm is active - LVDbSys2 exists - then LVDbSys3 and LVDbSys2  should be the same size (CheckLvmSize)
# 5.  LVDbSys2 and LVDbSys1 should not be mounted at the same time  (CheckLvmActive)
# 5a. LVDbSys3 and LVDbSys2 should not be mounted at the same time  (CheckLvmActive)
# 6.  If LVDbSys2 does not exist - then enough free space is required to create  it (with size of LVDbSys1 ) (CheckFreeSpaceVG) 
# 6a. If LVDbSys3 does not exist - then enough free space is required to create  it (with size of LVDbSys1 ) (CheckFreeSpaceVG) 
# 7.  On top of (6) enough free space should exist for the 1GB snapshot  (but take 1GB + 10M to be sure)  (CheckFreeSpaceVG) 
# 8.  Customers may decide to do backups and not use lvms for that (No check)
# 9.  Max No of Sys lvms (CheckMaxLvm)
#------------------------------------------------------------------------------

# Check number of arguments. No argument assumes we want to run allchecks
# This is a quick implementation - should be replaced by getopts later 
if [ $# -lt 1 ]
then
   v_action="checkall"    
else
   v_action="$1"    
fi

# Check and prepare for required utils
CheckandPrepUtils

# Init imageLogger
source /opt/oracle.cellos/${v_imagelogger}
if [ $? -ne 0 ]
then
   echo "[ERROR] Unable to source required Exadata environment file, /opt/oracle.cellos/${v_imagelogger}"
   exit 1
else
   imageLogger_init lvmchecker -name=${v_logfile} -notrace -silent
fi

# Source image_functions
if [ -f /opt/oracle.cellos/image_functions ]; then
  source /opt/oracle.cellos/image_functions
  if [ $? -ne 0 ]
  then
    echo "[ERROR] Unable to source required image_functions file, /opt/oracle.cellos/image_functions'."
    exit 1
  fi
else
  echo "[ERROR] Unable to source required image_functions file, /opt/oracle.cellos/image_functions'."
  exit 1
fi


# Print header
InitLog

# Set some defaults depending on the machine type (normal, domU, dom0)
DetermineModel

# We can do individual checks, but also all (default)
case "${v_action}" in
     islvm)
           CheckIsLvmSys
           ;;
     vgexa)
           CheckVGExa
           ;;
     lvmmin)
           CheckMinLvm
           ;;
     lvmmax)
           CheckMaxLvm
           ;;
     lvmsize)
           CheckLvmSize
           ;;
     lvmactive)
           CheckLvmActive
           ;;
     vgfree)
           CheckFreeSpaceVG
           ;;
 checklabels)
           CheckLabels
           ;;
 checkreclaim)
           CheckReclaim
           ;;
   checkall)
           # exec steps for completion (relink etc)
           ExecAllChecks
           ;;
          *)
           usage
           exit 1
           ;;
esac

# When more errors found than zero return value will be 1
if [ ${v_error_cnt} -gt 0 ]
then
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "exit value: 1"
   exit 1
else
   imageLogger_logMsg $lvmchecker $imageLogger_LOG_INFO "exit value: 0"
   exit 0
fi


