#!/bin/bash
#
# $Header: tfa/src/v2/tfa_home/bin/scripts/get_acfs_info.sh /main/1 2018/05/28 15:06:27 bburton Exp $
#
# get_acfs_info.sh
#
# Copyright (c) 2017, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      get_acfs_info.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#    Purpose: To obtain a detailed view of Oracle ACFS.
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bburton     11/01/17 - Gets acfs info - Only to run on Linux Systems
#    bburton     11/01/17 - Creation
#

#
# Function ora_acfs_validate
#
ora_acfs_validate () 
{

# check for acfsutil location

if [ -x /sbin/acfsutil ] ; then
 v_util_path=/sbin
elif [ -x /usr/sbin/acfsutil ] ; then
 v_util_path=/usr/sbin
else
 echo "Unable to locate acfsutil. Exiting."
 exit 1
fi

# Check for acfs version > 12.1

v_acfsutil_ver=`$v_util_path/acfsutil version | awk -F: '{print $2}' | sed 's/ //g' | awk -F. '{print $1$2}'`

if [ $v_acfsutil_ver -ge 121 ] ; then
 echo "acfsutil version requirements met."
else
 echo "acfsutil version needs to be >= 12.1.0.x. Exiting."
 exit 1
fi

# Check the acfs driver state
#
v_gi_instid=`cat /etc/oratab | grep -i +asm | awk -F: '{print $1}'`
ORACLE_SID=`echo $v_gi_instid`

v_gi_home=`cat /etc/oratab | grep -i +asm | awk -F: '{print $2}'`

v_ds_i=`$v_gi_home/bin/acfsdriverstate -orahome $v_gi_home installed | sed 's/ //g' | awk -F: '{print tolower($2)}'`
v_ds_l=`$v_gi_home/bin/acfsdriverstate -orahome $v_gi_home loaded | sed 's/ //g' | awk -F: '{print tolower($2)}'`
v_ds_s=`$v_gi_home/bin/acfsdriverstate -orahome $v_gi_home supported | sed 's/ //g' | awk -F: '{print tolower($2)}'`
#
if [ $v_ds_i == 'true' ] && [ $v_ds_l == 'true' ] && [ $v_ds_s = 'supported' ] ; then
 echo "acfsdriverstate conditions met."
else
 echo "acfsdriverstate conditions not met. Please review..."
 echo
 echo "acfsdriverstate: installed? : $v_ds_i"
 echo "acfsdriverstate: loaded? : $v_ds_l"
 echo "acfsdriverstate: Supported? : $v_ds_s"
 echo
 echo "Exiting."
 exit 1
fi

# Check for ADVM volumes. If none, no point in looking for ACFS file systems...

v_advm_vols=`$v_gi_home/bin/srvctl config volume | grep -i PRCA-1051 | wc -l`

if [ $v_advm_vols -eq 1 ] ; then
 echo "No Volumes found. Exiting..."
 exit 1
fi
}

#
# Function ora_acfs_get_report
#

ora_acfs_get_report ()
{

v_pit=$(date +"%d-%b-%Y %R:%S")
v_acfs_mnts=`$v_util_path/acfsutil info fs -o mountpoints`
v_acfs_mnts_ar=(`echo $v_acfs_mnts`)

echo
echo "======================================================================="
echo "Obtaining Oracle ACFS details as of $v_pit"
echo "======================================================================="
echo
echo "A. Kernel/Driver/Version info:"
echo "------------------------------"
$v_gi_home/bin/acfsdriverstate -orahome $v_gi_home version
echo
$v_util_path/acfsutil version -v
echo
echo
echo "B. Checking for any Corrupt File systems:"
echo "------------------------------------------"
for mp in "${v_acfs_mnts_ar[@]}" ; do
if [ `$v_util_path/acfsutil info fs -o iscorrupt $mp` == 1 ] ; then
 echo
 echo "Note: $mp is found to be corrupt. Please review and address it."
 echo
else
 echo "$mp is fine."
fi
done
echo
echo
echo "C. Registry details:"
echo "---------------------"
echo
echo "1. Registered File system(s):"
$v_util_path/acfsutil registry -r
echo
echo "2. File system(s) with automatic start"
$v_util_path/acfsutil registry -l
echo
echo
echo "D. Log size & levels:"
echo "----------------------"
if [ `whoami` == "root" ] ; then
echo
echo "1. Size:"
$v_util_path/acfsutil log -s
echo
echo "2. Log level for OKS (Oracle Kernel Services):"
$v_util_path/acfsutil log -q -p oks
echo
echo "3. Log Level for OFS:"
$v_util_path/acfsutil log -q -p ofs
echo
echo "4. Log Level for AVD:"
$v_util_path/acfsutil log -q -p avd
echo
else
echo "Note: Root privilege required to obtain this information."
fi
echo
echo
echo "E. Snapshot(s):"
echo "----------------"
echo
echo "Mount point(s), type and snapshot info:"
echo
for mp in "${v_acfs_mnts_ar[@]}" ; do
$v_util_path/acfsutil snap info -t $mp
$v_util_path/acfsutil snap info $mp
echo
echo
done
echo "F. Replication:"
echo "----------------"
v_cnt=1
for mp in "${v_acfs_mnts_ar[@]}" ; do
if [ `$v_util_path/acfsutil info fs -o replication $mp` == 1 ] ; then
echo
echo "$v_cnt. Configuration and background process details for $mp:"
echo
$v_util_path/acfsutil repl info -c -v $mp
echo
$v_util_path/acfsutil repl bg info $mp
echo
else
 echo
 echo "$v_cnt. Replication is not enabled for $mp"
 echo
fi
v_cnt=$((v_cnt+1))
done
echo
echo
echo "G. Security:"
echo "-------------"
v_sec_status=`$v_util_path/acfsutil info fs | grep -i 'Security status' | awk -F: '{print $2}' | sed 's/ //g'`

if [ ${v_sec_status} == 'ENABLED'  ] ; then
 echo "Found ACFS security enabled."

#for mp in "${v_acfs_mnts_ar[@]}" ; do
echo
echo "Please request ACFS security admin to run following type of commands manually:"
echo
echo "List all realms:"
echo "$v_util_path/acfsutil sec info -m $mp -n"
echo "List all rules:"
echo "$v_util_path/acfsutil sec info -m $mp -l"
echo "List all command rules:"
echo "$v_util_path/acfsutil sec info -m $mp -c"
echo "List all rule sets:"
echo "$v_util_path/acfsutil sec info -m $mp -s"
echo
#done
echo "Security admin details:"
echo "$v_util_path/acfsutil sec admin info"
echo
else
echo "Nothing to report."
fi
echo
echo
echo "H. Encryption:"
echo "---------------"
v_cnt=1
for mp in "${v_acfs_mnts_ar[@]}" ; do
echo "$v_cnt. Obtaining encryption information for $mp:"
$v_util_path/acfsutil encr info -m $mp
echo
v_cnt=$((v_cnt+1))
done
echo
echo "I. Audit information:"
echo "---------------------"
echo
$v_util_path/acfsutil audit info
echo
if [ `whoami` == "root" ] ; then
v_cnt=1
for mp in "${v_acfs_mnts_ar[@]}" ; do
echo "$v_cnt. For mount point: $mp:"
$v_util_path/acfsutil audit info -m $mp
echo
v_cnt=$((v_cnt+1))
done
else
 echo "Note: Requires root privilege to obtain this information."
fi
echo
echo
echo "J. Plugin(s):"
echo "--------------"
for mp in "${v_acfs_mnts_ar[@]}" ; do
$v_util_path/acfsutil plugin info $mp
echo
done
echo
echo
echo "K. File Systems, Statistics and Fragmentation details:"
echo "-------------------------------------------------------"
echo
$v_util_path/acfsutil info fs
echo
echo
echo "2. Detailed Statistics:"
echo
$v_util_path/acfsutil info fs -s -d
echo
echo
echo "3. Fragmentation details:"
echo
$v_util_path/acfsutil info fs -f -v
echo
echo
echo "======================================================================="
echo "End of Report."
echo "======================================================================="

}

#
# Main section
#
ora_acfs_validate
ora_acfs_get_report

exit 0
