#!/bin/sh
#
# $Header: tfa/src/v2/ext/dbcheck/dbcheck.sh /main/2 2018/08/15 16:55:51 bburton Exp $
#
# dbcheck.sh
#
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      dbcheck.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    05/22/18 - Updating dbcheck
#    gadiga      06/07/16 - summary
#    gadiga      06/07/16 - Creation
#
#  rordona - 10/04/2015 modified to work on larger clusters, e.g. 16-node cluster, (stbh)
#  rordona - 09/12/2015 modified for RDS and DB improvements
#  rordona - 09/01/2015 enhanced db time, avg. active session, db latency, db alerts, message alerts
#  pqiao   - 01/06/2015 for mcollect/patching check
#  rordona - 06/18/2014 created
#  
#  Simple health check script for CRS, ASM, DB
#

#CRS_HOME=`ps -eaf|grep ocssd.bin|grep -v grep|awk '{print $NF}'|sed -e "s/\/bin\/ocssd\.bin//g"`
OUTDIR=$1;
CRS_HOME=`ps -eafw|grep asm_pmon|grep -v grep |awk '{print $2}'|xargs pwdx|awk '{print $NF}' | xargs dirname`
ORACLE_BASE=`cat $CRS_HOME/inventory/ContentsXML/oraclehomeproperties.xml|grep "ORACLE_BASE"|grep VAL|awk -F"\"" '{print $(NF-1)}'`
OH_HOME=/u01/app/oracle/product/11.2.0.4/dbhome_1
CELLIPCONF=/etc/oracle/cell/network-config/cellinit.ora
DB_CHECK_CONFIG=0
DB_INFO=$OUTDIR/_db_info.txt
DB_INFO_COUNT=0
DB_STATS=$OUTDIR/_db_stats.txt
DB_TRACE=$OUTDIR/_db_trc.txt
ASM_INFO=$OUTDIR/_asm_info.txt
ASM_TRACE=$OUTDIR/_asm_trc.txt
CRS_TRACE=$OUTDIR/_crs_trc.txt
CELL_TRACE=$OUTDIR/_cell_trc.txt
OS_TRACE=$OUTDIR/_os_trc.txt
IBSW_OS_TRACE=$OUTDIR/_ibsw_os_trc.txt
IBSW_OPENSM=$OUTDIR/_ibsw_opensm_log.txt
IB_DATE=""
NORM="\033[0m"
GREEN="\033[1;32;40m"
ORANGE="\033[33;40m"
RED="\033[1;31;40m"
BLUE="\033[1;34;40m"

RED=red
GREEN=green
ORANGE=orange
BLUE=blue

HOSTNAME=`hostname -s`

GRID_VER="11g"
#### 11g
LOG_HOME="$CRS_HOME/log/$HOSTNAME"
IBQUERYERRORS="/usr/sbin/ibqueryerrors.pl"
#### 12g validate
[ -d "$ORACLE_BASE/diag/crs/$HOSTNAME" ] && LOG_HOME="$ORACLE_BASE/diag//crs/$HOSTNAME"
[ -d "$ORACLE_BASE/diag/crs/$HOSTNAME" ] && GRID_VER="12c"
[ "$GRID_VER" = "12c" ] && IBQUERYERRORS="/usr/sbin/ibqueryerrors"
IBSWITCH=`ibswitches 2>/dev/null|awk '{print $10}'|xargs echo | sed -re "s/ [ ]*/ /g" -e "s/ /,/g"`
CELL_LIST=`cat /etc/oracle/cell/network-config/cellip.ora 2>/dev/null|cut -d"=" -f2| sed -e "s/\"//g"|cut -d";" -f1`

asm_params=$OUTDIR/.ASM_params
db_params=$OUTDIR/.DB_params
db_list=$OUTDIR/.db_list
health_file=$OUTDIR/.health_check

typeset int TASK=2800
typeset int LOADAVG=20
typeset int FREEWAP=20
typeset int FREEMEM=20
typeset int SUMMARY=0
typeset int ISSAAS=0

pass="ok"
warning="warning"
fail="fail"

# SKIPLIST
SKIPLIST=""
SKIP_NODE=0
SKIP_OS=0
SKIP_RDS=0
SKIP_CELL=0
SKIP_IBSW=0
SKIP_CRS=0
SKIP_ASM=0
SKIP_DB=0
SKIP_TNS=0
# CHECKLIST
CHECKLIST=""
CHECKONLY=0
CHECK_NODE=0
CHECK_OS=0
CHECK_RDS=0
CHECK_CELL=0
CHECK_IBSW=0
CHECK_CRS=0
CHECK_ASM=0
CHECK_DB=0
CHECK_TNS=0

PLATFORM=`uname -p`
MASTER_NODE=`hostname`
CORE=$core
WALLCLOCK=$(( CORE * 3600 ))

do_sys_info() {

local core=`cat /proc/cpuinfo|grep "^processor"|wc -l`
local coremodel=`cat /proc/cpuinfo | grep "^model name"|sort|uniq`
local pmem=`dmidecode -t memory | egrep "Device|Size:" |grep Size|egrep -v "Install"| awk '$3 ~ /GB/ { c += $2 * 1024 } $3 ~ /MB/ {c += $2} END { print c}'`
local hwgen=`dmidecode -s system-product-name | sed -e 's/^.*X/X/' -e 's/SERVER//' -e 's/[[:space:]]*//g'`
CORE=$core
WALLCLOCK=$(( CORE * 3600 ))


case $hwgen in
              X4170 | X4275 ) ExaGen="V2" ;;
          X4170M2 | X4270M2 ) ExaGen="X2-2" ;;
                      X4800 ) ExaGen="X2-8" ;;
          X4170M3 | X4270M3 ) ExaGen="X3-2" ;;
                    X4800M2 ) ExaGen="X3-8" ;;
               X4-2 | X4-2L ) ExaGen="X4-2" ;;
                       X4-8 ) ExaGen="X4-8" ;;
               X5-2 | X5-2L ) ExaGen="X5-2" ;;
                          * ) ExaGen="$Model" ;;
esac
echo ""
echo "Hostname: `hostname`"
echo "HW Gen: $ExaGen   (Core: $core, CPU capacity/hr: $WALLCLOCK ) (Phys Mem: $pmem MB)"
echo "           CPU: $coremodel"
echo ""
echo "PLATFORM: $PLATFORM"
echo ""
#echo "-------------------------------------- DMI/SMB ---------------------------------------"
#dmidecode -t 1 | egrep "Manufacturer|Product Name|Serial Number"

#echo "-------------------------------------- IPMI/ILOM -------------------------------------"
#ipmitool -V 2>/dev/null
#ipmitool sunoem cli "show /SP system_description system_identifier" 2>/dev/null|  \
#  egrep "system_description|system_identifier"|grep -v show|sed -e "s/^[ ]*//g"

echo "-------------------------------------- OS --------------------------------------------"
uname -sr
head -1 /etc/*release

#echo "-------------------------------------- ImageHistory ----------------------------------"
#imagehistory 2>/dev/null
#echo ""
#echo "-------------------------------------- Model and BondType ----------------------------------"

# Get hardware model: X2-2 or X2-8
PRODUCT_NAME=`/usr/sbin/dmidecode | grep "Product Name" | head -1 | awk -F":" '{print $2}' | sed -e 's/^ //g'`
if [ `echo $PRODUCT_NAME | grep -c X4800` = 1  -o `echo $PRODUCT_NAME | grep -c X[45]-8` = 1 ]
then
        MODEL=X8
                if [ `echo $PRODUCT_NAME | grep -c X[45]-8` = 1 ]
                then
                        BONDTYPE='AA'
                else
                        BONDTYPE='AB'
                fi
elif [ `echo $PRODUCT_NAME | grep -c X4170` = 1 -o `echo $PRODUCT_NAME | grep -c X[45]-2` = 1 ]
then
        MODEL=X2
                if [ `echo $PRODUCT_NAME | grep -c X[45]-2` = 1 ]
                then
                        BONDTYPE='AA'
                else
                        BONDTYPE='AB'
                fi
fi


#echo "BondType [ AA = Active-Active, AB = Active-Backup ]: $BONDTYPE "
MODEL=X2
echo ""

}

check_ssh() {

 local host="$1"
 ssh -o FallBackToRsh=no  -o PasswordAuthentication=no  -o StrictHostKeyChecking=yes  -o NumberOfPasswordPrompts=0  -o ConnectTimeout=2 "$1" test -d /root 2>/dev/null

}

check_equivalence() {

 local fl="$1"
 for h in `cat $fl`; do
    check_ssh "$h"
    res=$?
    if [ $res -eq 0 ]; then
      msg "Node" "$h is reachable by SSH ... " $pass
    elif [ $res -eq 1 ]; then
      msg "Node" "$h is not reachable by SSH however, unable to run a test (e.g. test -d /root ) ... " $fail
    else
      msg "Node" "$h is not reachable by SSH ... " $fail
    fi
 done

}

check_ibsw_equivalence() {

    check_ssh "$1"
    res=$?
    if [ $res -eq 0 ]; then
      echo "Node" "$h is reachable by SSH ... " $pass
      return 0
    elif [ $res -eq 1 ]; then
      echo "Node" "$h is not reachable by SSH however, unable to run a test (e.g. test -d /root ) ... " $fail
      return -1
    else
      echo "Node" "$h is not reachable by SSH ... " $fail
      return -1
    fi

}


check_os_load() {

  echo ""
  echo "Listing OS load ..."
  echo ""


  local toprc=$OUTDIR/.toprc
  touch $toprc

  [ ! -f "$toprc" ] && echo "Not able to create TOPRC script ..." && return 1

  cat $0 | awk '/^<--- BEGIN TOPRC -->/,/^<--- END TOPRC -->/ { print $0 }' |egrep -v "<--- BEGIN TOPRC -->|<--- END TOPRC -->" > $toprc
  chmod 755 $toprc

  echo "$h:"
  echo ""
  export HOME=$OUTDIR; /usr/bin/top -n 1 -b | head -5 
  echo ""

}

check_os_wchan() {

  echo ""
  echo "Listing WCHAN ..."
  echo ""
  echo "$h:"
  echo ""
  ps -eo user,wchan:80|sort|uniq -c|sort -k1,1 -rn|head -10
  echo ""

}

get_nodes() {

 local IBLIST=""

  localnode=`hostname |cut -d. -f1`

 echo -n "Node: Checking /root/dbs_group ..."

 if [ ! -f "/root/dbs_group" ]; then
   echo "does not exist ... warning"
   echo "Node: Creating /root/dbs_group using olsnodes ..."
   $CRS_HOME/bin/olsnodes -n | awk '{print $1}' |grep $localnode > /root/dbs_group
 else
  echo ""
 fi

 echo -n "Node: Checking /root/cell_group ..."
 if [ ! -f "/root/cell_group" ]; then
  echo "does not exist ... warning"
  echo "Creating /root/cell_group using cellip.ora ..."
  echo "$CELL_LIST" > /root/cell_group
 else
  cg=`wc -l /root/cell_group| awk '{print $1}'`
  ci=`echo "$CELL_LIST" | wc -l`
  echo "Cell Count: $cg vs $ci"
  [ $cg -ne $ci ] && echo "$CELL_LIST" > /root/cell_group 
 fi

 echo "Checking DB node root user equivalence ..."
 check_equivalence "/root/dbs_group"

 echo "Checking Cell node root user equivalence ..."
 check_equivalence "/root/cell_group"

 echo "Checking IB Switch root user equivalence ..."
 for h in `echo $IBSWITCH|sed -e "s/,/ /g"`; do
   check_ibsw_equivalence "$h"
   [ $? -eq 0 ] && IBLIST="$IBLIST,$h"
 done

 IBSWITCH=`echo "$IBLIST" | sed -e "s/^,//g"` 

}

generate_db_list() {
# ps -eaf|grep ora_pmon| grep -v ASM|awk '{print $NF }'|cut -d"_" -f3|grep -v grep > ${db_list}

#ps -eaf|grep ora_pmon| grep -v ASM | grep -v grep | egrep -vi 'ovm|ods' | awk '{print $2,$8}' | while read p pn;do echo -n $pn":" | cut -d"_" -f3 | tr -d '\n'; ls -ld /proc/$p/cwd | awk '{print $NF}' | xargs dirname; done | grep 11.2.0.4 > ${db_list}

ps -eaf|grep ora_pmon| grep -v ASM | grep -v grep | egrep -vi 'ovm|ods' | awk '{print $2,$8}' | while read p pn;do echo -n $pn":" | cut -d"_" -f3 | tr -d '\n'; ls -ld /proc/$p/cwd | awk '{print $NF}' | xargs dirname; done > ${db_list}
}

msg() {
   m1="$1"
   m2="$2"
   m3="$3"
  if [ "$m3" = $pass ] ; then color2show=$GREEN; fi
  if [ "$m3" = $fail ] ; then color2show=$RED; fi
  if [ "$m3" = $warning ] ; then color2show=$ORANGE; fi

  if [  $SUMMARY -eq 1 ]; then
    if [ -n "$m3" -a "$m3" != "$pass" ]; then
       #printf "%s: %-75s <span style='color:$color2show'>%s</span>\n" "$m1" "$m2" "$m3"
       printf "%s: %-75s %s\n" "$m1" "$m2" "$m3"
    fi
  else
       #printf "%s: %-75s <span style='color:$color2show'>%s</span>\n" "$m1" "$m2" "$m3"
       printf "%s: %-75s %s\n" "$m1" "$m2" "$m3"
  fi

}

check_asm_pmon() {

  pmon=`ps -eaf|grep pmon|grep ASM|awk '{print $NF }'|cut -d"_" -f3`

 if [ -n "$pmon" ]; then
    msg "ASM" "$pmon instance up and running" $pass
    ASM_PMON=$pmon
 else
    msg "ASM" "$pmon instance is not running!" $fail
    return 1
 fi

}

env_asm() {
export ORACLE_HOME=$CRS_HOME
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export PATH=/usr//bin:/bin:/usr/bin:$ORACLE_HOME/bin
export ORACLE_SID=${ASM_PMON}
}

env_db() {
export ORACLE_HOME=$OH_HOME
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export PATH=/usr//bin:/bin:/usr/bin:$ORACLE_HOME/bin
export ORACLE_SID=dbm1
}


sql_multi() {

 sid="$1"
 dbh="$2"
 query="$3"


 sql="$dbh/bin/sqlplus"
[ ! -f "$sql" ] && msg "ASM" "$dbh/bin/sqlplus does not exist ..." $fail
ow=`ls -l $sql 2>/dev/null|awk '{print $3}'`
 res=$(su $ow -c "
export ORACLE_HOME=$ORACLE_HOME
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export PATH=${ORACLE_HOME}
export ORACLE_SID=${sid}
$sql  -s /nolog  <<eof!
connect / as sysdba
set head off feed off echo off scan off
set trimspool on trimout on lines 1000 pages 10000
/
exit
eof!
"
)
 echo "$res"  | xargs echo
}




sql_params() {
 typ="$1"
 sid="$2"
 dbh="$3"
 sql="$dbh/bin/sqlplus"
[ ! -f "$sql" ] && msg $typ "$dbh/bin/sqlplus does not exist ..." $fail && exit 2
ow=`ls -l $sql 2>/dev/null|awk '{print $3}'`
su $ow -c "
export ORACLE_HOME=${dbh}
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export PATH=${ORACLE_HOME}
export ORACLE_SID=${sid}
$sql -s /nolog<<eof! > $OUTDIR/${sid}_params
connect / as sysdba
set head off feed off echo off scan off
set trimspool on trimout on lines 1000 pages 10000
select substr(a.ksppinm,1,40) || '@' ||  substr( c.ksppstvl,1,130)
    from x\\\$ksppi a, x\\\$ksppcv b, x\\\$ksppsv c
  where a.indx = b.indx and a.indx = c.indx order by 1;
exit
eof!
"

}


sql() {

 sid="$1"
 dbh="$2"
 query="$3"


 sql="$dbh/bin/sqlplus"
[ ! -f "$sql" ] && msg "ASM" "$dbh/bin/sqlplus does not exist ..." $fail

ow=`ls -l $sql 2>/dev/null|awk '{print $3}'`
 res=$(su  $ow -c "
export ORACLE_HOME=${dbh}
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export PATH=${ORACLE_HOME}
export ORACLE_SID=${sid}
$sql  -s /nolog  <<eof!
connect / as sysdba
set head off feed off echo off scan off
set trimspool on trimout on lines 1000 pages 10000
$query
/
exit
eof!
"
)

 echo "$res"  | xargs echo
}

sql_list()  {
 local sid="$1"
 local dbh="$2"
 local query="$3"

 sql="$dbh/bin/sqlplus"

  [ ! -f "$sql" ] && msg "ASM" "$dbh/bin/sqlplus does not exist ..." $fail
 ow=`ls -l $sql |awk '{print $3}'`

su  $ow -c "
export ORACLE_HOME=$dbh
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export PATH=\$ORACLE_HOME
export ORACLE_SID=$sid
$sql  -s /nolog  <<eof!
  connect / as sysdba
  set head off feed off echo off scan off verify off
  set trimspool on trimout on lines 1000 pages 10000
  $query
  exit
eof!
" | egrep -v "Connected" | sed -e "s/\t/ /g" -e "s/ [ ]*/ /g" | while read line; do
   err=`echo "$line" | egrep -co "ORA-|ERROR at line"`
   [ -n "$line" -a $err -gt 0 ] && echo "" && return 1
   [ -n "$line" -a $err -eq 0 ] && echo "" && echo "$line" 
 done

 return 0

}

check_asm_diskgroup() {

 echo ""
 echo "Checking ASM diskgroup ..."
 echo ""

 local sql_stat="$OUTDIR/_sql_asm_dg.txt"

 ps -eaf|grep asm_pmon | grep -v grep | while read line; do

   SID=`echo "$line" | awk -F"_" '{print $NF}'`
   #export ORACLE_HOME=`echo "$line" | awk '{print $2}'| xargs pwdx | sed -e "s/\/dbs$//g"|cut -d":" -f2|sed -e "s/ //g"`
   export ORACLE_HOME=`echo "$line" | awk '{print $2}'| xargs pwdx | awk '{print $NF}' | xargs dirname`
  

   export LD_LIBRARY_PATH=$ORACLE_HOME/lib
   export PATH=$ORACLE_HOME/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
   export ORACLE_SID=$SID

    local query=`cat $0| awk '/^<--- BEGIN ASM DISKGROUP -->/,/^<--- END ASM DISKGROUP -->/ { print $0 }'| egrep -v "<--- BEGIN ASM DISKGROUP -->|<--- END ASM DISKGROUP -->" `

   sql_list  "$SID" "$ORACLE_HOME" "$query"
   [ $? -ne 0 ] && msg "ASM" "Error detected ..." $fail && return

done > $sql_stat

 echo "" | awk ' { printf "%2s  %14s  %4s  %10s  %10s  %8s  %8s  %20s  %15s  %15s  %15s  %-30s\n", 
       "G#", "NAME", "SECS", "BLKS", "AUS", "STATE", "TYPE", "% FREE/TOTAL(GB)", "RQ_M_FREE_MB", "USABLE_FILE_MB", "OFFLINE_DISKS" , "STATUS" }' 


cat "$sql_stat" | awk  '
  {
      asmgrp[$1]=$1
      asmname[$1]=$2
      asmsecs[$1]=$3
      asmblks[$1] += $4
      asmaus[$1] += $5
      asmstate[$1] = $6
      asmtype[$1] = $7
      asmfree[$1] = $8" "$9
      asmrqfree[$1] += $10
      asmusable[$1] += $11
      asmoffline[$1] += $12
  }
  END {
     for (i in asmgrp) {
        warn="ok"
        if (asmoffline[i] > 0 ) warn="warning (offline disks)"
        if (asmusable[i] < 5000 ) warn="fail (low space)"
        if (length(i) > 0) printf "%2s  %14s  %4d  %10d  %10d  %8s  %8s  %-20s  %15d  %15d  %15d  %-30s\n", 
          i, asmname[i], asmsecs[i],asmblks[i], asmaus[i], asmstate[i], asmtype[i], asmfree[i], asmrqfree[i], asmusable[i], asmoffline[i], warn

    }
  }
   '

}

check_asm_hanganalyze() {

   query="
    oradebug setmypid
    oradebug dump hanganalyze 2
    oradebug tracefile_name
     "
  echo ""
  echo "Checking ASM hangs ..."
  echo ""

  ### Check ASM instance
   sid=${ASM_PMON}

   res=$(  sql "$sid" "$CRS_HOME" "$query" )

   tfile=`echo $res|tail -1 | awk '{print $5}'`

  [ ! -f "$tfile" ] && msg "ASM" "Check $tfile ... no file " $fail && return
  msg "ASM" "Checking Hanganalyze $tfile ... " ""

   typeset int nochain=`cat $tfile | awk '/HANG ANALYSIS:/,/END OF HANG ANALYSIS/ { print $0} '|grep -c "no chains found"`
   typeset int withchain=`cat $tfile | awk '/HANG ANALYSIS:/,/END OF HANG ANALYSIS/ { print $0} '|grep  "Chain" | grep "Signature"|grep -v "Hash"`
   typeset int blocked=`cat $tfile | awk '/HANG ANALYSIS:/,/END OF HANG ANALYSIS/ { print $0} '|grep -c "is blocked by"`
   waiting=`cat $tfile | awk '/HANG ANALYSIS:/,/END OF HANG ANALYSIS/ { print $0} '|grep "waiting for"| \
             sed -e "s/(which is waiting for|is waiting for)//" -e "s/with wait info://"|sort|uniq -c`

  if [ $nochain -gt 0 ]
  then
	msg "ASM" "Check Hang Chains ... no chains " $pass
  else
	msg "ASM" "Check Hang Chains ... no chains " $fail
  fi
  
  if [ $blocked -eq 0 ]
  then
	msg "ASM" "Check Blocked Sessions ... nothing blocked " $pass
  else
	msg "ASM" "Check Blocked Sessions ... nothing blocked " $fail
  fi
	
  [ $blocked -gt 0 ] && msg "ASM" "Check Blocked Sessions ... [ $blocked found ] " $warning

  msg "ASM" "List chains ..." ""
  if [ -z "$withchain" ]
  then
	msg "ASM" "   no chains to list" $pass
  else
	msg "ASM" "   no chains to list" $fail
  fi
  
  [ -n "$withchain" ] && echo "$withchain" |
  while read line
  do
  msg "ASM" "$line" $warning
  done
   
  msg "ASM" "List waits ..." ""
  if [ -z "$waiting" ]
  then
	msg "ASM" "   no waits to list" $pass
  else
	msg "ASM" "   no waits to list" $fail
  fi
  
  [ -n "$waiting" ] && echo "$waiting" |
  while read line
  do
   typeset int cnt=`echo "$line" | awk '{print $1}'`
   event=`echo "$line" | awk '{print $2" "$3" "$4" "$5" "$6" "$6" "$7" "$8}'`
  [ $cnt -gt 0 ] && msg "ASM" "$event [ Count: $cnt ]" $warning
  done

  echo ""
   
}

sql_asm_check() {

  ### Check ASM instance
   sid=${ASM_PMON}

  awk '/^<-- ASM begin -->/,/^<-- ASM end -->/ { print $0}' $0 | egrep -v "^(#|<--)"|
  while read prop
  do
    if [ -n "$prop" ]; then
      typeset int isInt=0
      msg=`echo $prop| awk -F":" '{ print $1 }'`
      val=`echo $prop| awk -F":" '{ print $2 }'`
      query=`echo $prop| awk -F":" '{ print $3 }'`
      oper="=";

     if [ -n "${val}" -a -n "${query}" ]; then

         if [ "$query" = "=" -o "$query" = ">=" -o "$query" = "<=" -o "$query" = ">" -o "$query" = "<" ]; then
             oper=$query
             query=`echo $prop| awk -F":" '{ print $4 }'`
         fi


          res=$(  sql "$sid" "$CRS_HOME" "$query" )
         [[ $val =~ ^-?[0-9]+$ ]] && isInt=1
         if [ -n "$res"  ]; then
           if [ $isInt -eq 1 ]; then
             if [ "$oper" = ">="  -a $res -ge $val ]; then
                msg "ASM" "[$sid] $msg [$res]" $pass
             elif [ "$oper" = "<="  -a $res -le $val ]; then
                msg "ASM" "[$sid] $msg [$res]" $pass
             elif [ "$oper" = ">"  -a $res -gt $val ]; then
                msg "ASM" "[$sid] $msg [$res]" $pass
             elif [ "$oper" = "<"  -a $res -lt $val ]; then
                msg "ASM" "[$sid] $msg [$res]" $pass
             elif [ "$oper" = "="  -a $res -eq $val ]; then
                msg "ASM" "[$sid] $msg [$res]" $pass
             else
                msg "ASM" "[$sid] $msg [$res $oper (expected) $val ]" $fail
             fi
           else
               res=`echo "$res" | tr "a-z" "A-Z"`
               val=`echo "$val" | tr "a-z" "A-Z"`
               if  [  "$res" = "$val" ]; then
                 msg "ASM" "[$sid] $msg [$res]" $pass
               fi
           fi
         else
           [ -z "$res" ] && res="empty"
            msg "ASM" "[$sid] $msg [$res <> (expected) $val]" $fail
         fi
     fi

    fi
 done

  ### Check ASM parameters
 
  asm_params=$OUTDIR/${ASM_PMON}_params
  if [ ! -f "${asm_params}" ]; then
      msg "ASM" "${asm_params} does not exist" $fail
  fi

  query="select version from v\\\$instance"
  ASMVERSION=$(sql "$sid" "$CRS_HOME" "$query" )

        if [[ "$ASMVERSION" =~ "11.2.0.3" ]]
        then
                VER=11203
                VERSION=11.2.0.3
        elif [[ "$ASMVERSION" =~ "11.2.0.4" ]]
        then
                VER=11204
                VERSION=11.2.0.4
        else
                echo "Unsupported version: $ASMVERSION"
                exit 1
        fi

        DIAGNOSTIC_DEST="/u02/app/oracle/admin/${VERSION}"
        AUDIT_FILE_DEST="/u02/app/oracle/admin/${VERSION}/asm/audit"

    for prop in `awk '/^<-- ASM params begin -->/,/^<-- ASM params end -->/ { print $0}' $0 | egrep -v "^(#|<--)" | sed -e "s#DIAGNOSTIC_DEST#$DIAGNOSTIC_DEST#" -e "s#AUDIT_FILE_DEST#$AUDIT_FILE_DEST#" | egrep "ALL$|$VER$|$MODEL$"`
        do
                typeset int isInt=0
        if [ -n "$prop" ]; then
                msg=`echo $prop| awk -F"--" '{ print $1 }'`
                val=`echo $prop| awk -F"--" '{ print $2 }' | tr "a-z" "A-Z" | tr "~" " "`
                oper=`echo $prop| awk -F"--" '{ print $3 }'`
                query=`echo $prop| awk -F"--" '{ print $4 }'`
                val1=''
                res=''
                line=''
         if [ -n "$val" -a -n "$query" ]; then
                                 
                                 if [ "$query" = "cluster_interconnects" ]; then
                                                line=`grep -w "^$query"  ${asm_params}`
                                                res=`echo $line|awk -F"@"  '{print $2}'| tr "a-z" "A-Z"`
                                           
                                                if [ "$res" = "$IBGROUPA" ]
                                                then
                                                        msg "ASM" "[$sid] $msg $query [$res]" $pass
                                                else
                                                        msg "ASM" "[$sid] $msg $query [Bound to IB IPs: $res]" $fail
                                                fi
                                else
                               
                                                 if [ "$query" = "N/A" ]; then
                                                        val1="$query"
                                                        query=`echo $prop| awk -F"--" '{ print $5 }'`
                                                 fi
                                                 
                                                 line=`grep -w "$query"  ${asm_params}`
                                                 res=`echo $line|awk -F"@"  '{print $2}'| tr "a-z" "A-Z" `
                                                 [[ $val =~ ^-?[0-9]+$ ]] && isInt=1
                                                   
                                                 if [ -n "$res"  ]; then
                                                   if [ $isInt -eq 1 ]; then
                                                         if [ "$oper" = ">="  -a $res -ge $val ]; then
                                                                msg "ASM" "[$sid] $msg $query [$res]" $pass
                                                         elif [ "$oper" = "<="  -a $res -le $val ]; then
                                                                msg "ASM" "[$sid] $msg $query [$res]" $pass
                                                         elif [ "$oper" = ">"  -a $res -gt $val ]; then
                                                                msg "ASM" "[$sid] $msg $query [$res]" $pass
                                                         elif [ "$oper" = "<"  -a $res -lt $val ]; then
                                                                msg "ASM" "[$sid] $msg $query [$res]" $pass
                                                         elif [ "$oper" = "="  -a $res -eq $val ]; then
                                                                msg "ASM" "[$sid] $msg $query [$res]" $pass
                                                         else
                                                                msg "ASM" "[$sid] $msg $query $res $oper (expected) $val" $fail
                                                         fi
                                                   else
                                                         if [ "$val1" = "N/A" ]; then
                                                                msg "ASM" "[$sid] $msg $query $res <> (expected) $val" $fail
                                                         elif [ "$res" = "$val" ]; then
                                                                msg "ASM" "[$sid] $msg $query [$res]" $pass ]
                                                         else
                                                                msg "ASM" "[$sid] $msg $query $res <> (expected) $val" $fail
                                                         fi
                                                   fi
                                                 else
                                                        [ -z "$res" ] && res="N/A"
                                                        if [ "$res" = "N/A" -a "$val1" = "N/A" ]; then
                                                                msg "ASM" "[$sid] $msg $query [not set]" $pass
                                                        else
                                                                msg "ASM" "[$sid] $msg $query $res <> (expected) $val" $fail
                                                        fi
                                                 fi
                 fi
         fi
        fi
        done
 
 
  awk '/^<-- ASM params begin -->/,/^<-- ASM params end -->/ { print $0}' $0 | egrep -v "^(#|<--)"|
  while read prop
  do

   if [ -n "$prop" ]; then
      msg=`echo $prop| awk -F":" '{ print $1 }'`
      val=`echo $prop| awk -F":" '{ print $2 }' | tr "a-z" "A-Z"`
      query=`echo $prop| awk -F":" '{ print $3 }'`
      val1=''
      res=''
      line=''
     if [ -n "$val" -a -n "$query" ]; then
         if [ "$query" = "N/A" ]; then
             val1="$query"
             query=`echo $prop| awk -F":" '{ print $4 }'`
         fi
         line=`grep -w "$query"  ${asm_params}`
         res=`echo $line|awk -F"~"  '{print $2}'| tr "a-z" "A-Z"`
         if [ "$res" = "$val" ]; then
           msg "ASM" "[$sid] $msg $query [$res]" $pass
         elif [ "$val1" = "N/A" ]; then
           [ -z "$res" ] && res="N/A"
           [ "$res" = "N/A" -a "$val1" = "N/A" ] && msg "ASM" "[$sid] $msg $query [not set]" $pass
           [ "$res" = "N/A" -a "$val1" = "" ] && msg "ASM" "[$sid] $msg $query [$res <> $val]" $fail
         else
           msg "ASM" "[$sid] $msg $query [$res <> (expected) $val]" $fail
         fi
     fi
    fi

  done

}


sql_db_check() {

   sid="$1"
   dbh="$2"
   
  ### Check /etc/oratab
  if [ `grep -i $sid /etc/oratab | grep -v '^#' | wc -l` -eq 0 ]
  then
        msg "DB" "[$sid] no entry in /etc/oratab" $fail
  else
    if [ `grep -i $sid /etc/oratab | grep -v '^#' | grep -c "$dbh"` -gt 0 ]
        then
                msg "DB" "[$sid] check /etc/oratab: `grep -i $sid /etc/oratab | grep -v '^#' | sort -u | awk -F'#' '{print $1}' | tr -d '[ \t]*'`" $pass
        else
                msg "DB" "[$sid] check /etc/oratab: `grep -i $sid /etc/oratab | grep -v '^#' | sort -u | awk -F'#' '{print $1}' | tr -d '[ \t]*'`" $fail
        fi
  fi
 
  # Check srvctl config
  query="select value from v\\\$parameter where name='db_unique_name'"
  query2="select version from v\\\$instance"
  query3="select replace(version||comments,'.','') from dba_registry_history where action_time = (select max(action_time) from dba_registry_history where version = '11.2.0.4' and comments like 'BP%') "
  dbnm=$(sql "$sid" "$dbh" "$query" )
  insver=$(sql "$sid" "$dbh" "$query2" )
  dbbp=$(sql "$sid" "$dbh" "$query3" )
 
  dbver=`cat $OUTDIR/dbconfig_all_$$ 2>/dev/null | grep -iw $dbnm | cut -f3`
   
  if [ "X$dbver" != "X" ]
  then
    [ $dbver = '11.2.0.4.0' ] && srvhome='/u01/app/oracle/product/11.2.0.4/dbhome_1'
    [ $dbver = '11.2.0.3.0' ] && srvhome='/u01/app/oracle/product/11.2.0.3/dbhome_1'
    homeinocr=`$CRS_HOME/bin/srvctl config db -d $dbnm | grep 'Oracle home:' | awk '{print $NF}'`
        if [ "$homeinocr" = "$dbh" ]
        then
                msg "DB" "[$sid] check srvctl dbhome config == <expected> $dbh" $pass
        else
                msg "DB" "[$sid] check srvctl dbhome config <> <expected> $dbh" $fail
        fi
       
        if [[ ${insver} = ${dbver} ]]
        then
                msg "DB" "[$sid] check srvctl db version config == <expected> $insver" $pass
        else
                msg "DB" "[$sid] check srvctl db version config <> <expected> $insver" $fail
        fi
  fi
   
  ### Check if it resides in hugepage
   if [ `/usr/bin/pmap -x $(ps -ef| grep _pmon | grep ${sid} | awk '{print $2}') | grep -c shmid` -gt 0 ]
   then
       msg "DB" "[$sid] SGA is not in hugepage" $fail
   else
       msg "DB" "[$sid] SGA is in hugepage" $pass  
   fi
   
  ### Check Status of DB instances
   rundb=`ps -eaf|grep ora_pmon_${sid}|grep -v grep`

  if [ -n "$rundb" ]; then
      query="select open_mode from v\\\$database"
      res=$(  sql "$sid" "$dbh" "$query" )

     msg "DB" "[$sid] pmon process exists" $pass

     if [ `echo "$res" | grep -c "database not mounted"` -eq 1 ]; then
        msg "DB" "[$sid] database is in nomount mode" $warning
        return
     elif [ `echo "$res" | grep -c "MOUNTED"` -eq 1 ]; then
        msg "DB" "[$sid] database is in mount mode" $warning
     elif [ `echo "$res" | grep -c "READ WRITE"` -eq 1 ]; then
        msg "DB" "[$sid] database is in open mode" $pass
     fi
  else
     msg "DB" "[$sid] pmon process not running" $warning
     return
  fi

  ### Check DB instance
   typeset int isInt=0

  awk '/^<-- DB begin -->/,/^<-- DB end -->/ { print $0}' $0 | egrep -v "^(#|<--)"|
  while read prop
  do
    if [ -n "$prop" ]; then
      typeset int isInt=0
      msg=`echo $prop| awk -F":" '{ print $1 }'`
      val=`echo $prop| awk -F":" '{ print $2 }'`
      query=`echo $prop| awk -F":" '{ print $3 }'`
      oper="=";

     if [ -n "$val" -a -n "$query" ]; then

         if [ "$query" = "=" -o "$query" = ">=" -o "$query" = "<=" -o "$query" = ">" -o "$query" = "<" ]; then
             oper=$query
             query=`echo $prop| awk -F":" '{ print $4 }'`
         fi


          res=$(  sql "$sid" "$dbh" "$query" )
         [[ $val =~ ^-?[0-9]+$ ]] && isInt=1
         if [ -n "$res" -a -n "$val" ]; then
           if [ $isInt -eq 1 ]; then
             if [ "$oper" = ">="  -a $res -ge $val ]; then
                msg "DB" "[$sid] $msg [$res]" $pass
             elif [ "$oper" = "<="  -a $res -le $val ]; then
                msg "DB" "[$sid] $msg [$res]" $pass
             elif [ "$oper" = ">"  -a $res -gt $val ]; then
                msg "DB" "[$sid] $msg [$res]" $pass
             elif [ "$oper" = "<"  -a $res -lt $val ]; then
                msg "DB" "[$sid] $msg [$res]" $pass
             elif [ "$oper" = "="  -a $res -eq $val ]; then
                msg "DB" "[$sid] $msg [$res]" $pass
             else
                msg "DB" "[$sid] $msg [$res $oper (expected) $val ]" $fail
             fi
           else
             res=`echo "$res" | tr "a-z" "A-Z"`
             val=`echo "$val" | tr "a-z" "A-Z"`
             if [  "$res" = "$val" ]; then
               msg "DB" "[$sid] $msg [$res]" $pass
             fi
           fi
         else
           [ -z "$res" ] && res="empty"
            msg "DB" "[$sid] $msg [$res <> (expected) $val]" $fail
         fi
     fi
    fi
 done

  ### Check DB parameters
  dbtype=""
  db_params=$OUTDIR/${sid}_params
  if [ ! -f "${db_params}" ]; then
      msg "DB" "${db_params} does not exist" $fail
  fi

        if [[ "$dbnm" =~ f$ ]]
        then
                dbtype="FUSION"
        elif [[ "$dbnm" =~ i$ ]]
        then
                dbtype="IDSTORE"
        elif [[ "$dbnm" =~ p$ ]]
        then
                dbtype="PSTORE"
        else
                dbtype="OTHERS"
        fi
               
        if [[ "$insver" =~ "11.2.0.3" ]]
        then
                VER=11203
                VERSION=11.2.0.3
        elif [[ "$insver" =~ "11.2.0.4" ]]
        then
                VER=11204
                VERSION=11.2.0.4
        else
                echo "Unsupported version: $insver"
                return 1
        fi
               
        DIAGNOSTIC_DEST="/u02/app/oracle/admin/$VERSION"
        AUDIT_FILE_DEST="/u02/app/oracle/admin/$VERSION/rdbms/$dbnm/audit"
        UTL_FILE_DIR="/u02/app/oracle/admin/$VERSION/rdbms/$dbnm/utl_file"
       
        for prop in `awk '/^<-- DB params begin -->/,/^<-- DB params end -->/ { print $0}' $0 | egrep -v "^(#|<--)" | sed -e "s#DIAGNOSTIC_DEST#$DIAGNOSTIC_DEST#" -e "s#AUDIT_FILE_DEST#$AUDIT_FILE_DEST#" -e "s#UTL_FILE_DIR#$UTL_FILE_DIR#" | egrep "ALL$|$VER$|$dbbp$|$dbtype$|$MODEL$"`
        do
                typeset int isInt=0
        if [ -n "$prop" ]; then
                msg=`echo $prop| awk -F"--" '{ print $1 }'`
                val=`echo $prop| awk -F"--" '{ print $2 }' | tr "a-z" "A-Z" | tr "~" " "`
                oper=`echo $prop| awk -F"--" '{ print $3 }'`
                query=`echo $prop| awk -F"--" '{ print $4 }'`
                val1=''
                res=''
                line=''
            if [ -n "$val" -a -n "$query" ]; then
                                 
                                if [ "$query" = "cluster_interconnects" ]; then
                                                line=`grep -w "^$query"  ${db_params}`
                                                res=`echo $line|awk -F"@"  '{print $2}'| tr "a-z" "A-Z"`

                                        if [ "$MODEL" = "X8" ]
                                        then                                          
                                                if [ "$res" = "$IBGROUP1" ]
                                                then
                                                   let "ibgrp1cnt+=1"
                                                                                                                msg "DB" "[$sid] $msg $query [Bound to: $res]" $fail
                                                elif [ "$res" = "$IBGROUP2" ]
                                                then
                                                   let "ibgrp2cnt+=1"
                                                                                                                msg "DB" "[$sid] $msg $query [Bound to: $res]" $fail
                                                elif [ "$res" = "$IBGROUP3" ]
                                                then
                                                   let "ibgrp3cnt+=1"
                                                   msg "DB" "[$sid] $msg $query [Bound to: $res]" $fail
                                                elif [ "$res" = "$IBGROUP4" ]
                                                then
                                                   let "ibgrp4cnt+=1"
                                                                                                        msg "DB" "[$sid] $msg $query [Bound to: $res]" $fail
                                                else
                                                   if [ "$res" = "$IBGROUPA" ]
                                                   then
                                                                                                                let "ibgrpacnt+=1"
                                                                                                                msg "DB" "[$sid] $msg $query [$res]" $pass
                                                                                                        else
                                                        let "ibgrpocnt+=1"
                                                   msg "DB" "[$sid] $msg $query [Bound to: $res]" $fail
                                                   fi

                                                fi
                                        elif [ "$MODEL" = "X2" ]
                                        then
                                                if [ "$res" = "$IBGROUPA" ]
                                                then
                                                        msg "DB" "[$sid] $msg $query [$res]" $pass
                                                else
                                                        msg "DB" "[$sid] $msg $query [Bound to IB IPs: $res]" $fail
                                                fi
                                        fi
                                else
                                                 if [ "$query" = "N/A" ]; then
                                                        val1="$query"
                                                        query=`echo $prop| awk -F"--" '{ print $5 }'`
                                                 fi
                                                 
                                                 line=`grep -w "$query"  ${db_params}`
                                                 res=`echo $line|awk -F"@"  '{print $2}'| tr "a-z" "A-Z" `
                                                 [[ $val =~ ^-?[0-9]+$ ]] && isInt=1
                                                   
                                                 if [ -n "$res"  ]; then
                                                   if [ $isInt -eq 1 ]; then
                                                         if [ "$oper" = ">="  -a $res -ge $val ]; then
                                                                msg "DB" "[$sid] $msg $query [$res]" $pass
                                                         elif [ "$oper" = "<="  -a $res -le $val ]; then
                                                                msg "DB" "[$sid] $msg $query [$res]" $pass
                                                         elif [ "$oper" = ">"  -a $res -gt $val ]; then
                                                                msg "DB" "[$sid] $msg $query [$res]" $pass
                                                         elif [ "$oper" = "<"  -a $res -lt $val ]; then
                                                                msg "DB" "[$sid] $msg $query [$res]" $pass
                                                         elif [ "$oper" = "="  -a $res -eq $val ]; then
                                                                msg "DB" "[$sid] $msg $query [$res]" $pass
                                                         else
                                                                msg "DB" "[$sid] $msg $query $res $oper (expected) $val" $fail
                                                         fi
                                                   else
                                                         if [ "$val1" = "N/A" ]; then
                                                                msg "DB" "[$sid] $msg $query $res <> (expected) $val" $fail
                                                         elif [ "$res" = "$val" ]; then
                                                                msg "DB" "[$sid] $msg $query [$res]" $pass ]
                                                         else
                                                                msg "DB" "[$sid] $msg $query $res <> (expected) $val" $fail
                                                         fi
                                                   fi
                                                 else
                                                        [ -z "$res" ] && res="N/A"
                                                        if [ "$res" = "N/A" -a "$val1" = "N/A" ]; then
                                                                msg "DB" "[$sid] $msg $query [not set]" $pass
                                                        else
                                                                msg "DB" "[$sid] $msg $query $res <> (expected) $val" $fail
                                                        fi
                                                 fi
                                fi
            fi
        fi
        done

  ### Check Multi columns

#  dbversion=`echo $insver| sed -e 's/\.//g'`
  awk '/^<-- DB Multi begin -->/,/^<-- DB Multi end -->/ { print $0}' $0 | egrep -v "^(#|<--)"|
  while read prop
  do
    if [ -n "$prop" ]; then
      typeset int isInt=0
      msg=`echo $prop| awk -F":" '{ print $1 }'`
      val=`echo $prop| awk -F":" '{ print $2 }'`
      oper=`echo $prop| awk -F":" '{ print $3 }'`
      query=`echo $prop| awk -F":" '{ print $4 }'`

          if [ "$val" = "curver" ]; then
                val=$(  sql "$sid" "$dbh" "select replace(version,'.','') from v\\\$instance" )
          fi
         
      if [ -n "$val" -a -n "$query" ]; then

          res=$(  sql "$sid" "$dbh" "$query" )
         [[ $val =~ ^-?[0-9]+$ ]] && isInt=1

         [ -n "$res" ] && echo "$res" |
         sed -e "s/###/\n/g" |
         while read line
         do
           res_n=`echo "$line"| awk -F"~" '{print $1}'`
           typeset int res_v=`echo "$line"| awk -F"~" '{print $2}'`
          if [ $isInt -eq 1 -a -n "${res_v}" ]; then
             if [ "$oper" = ">="  -a $res_v -ge $val ]; then
                msg "DB" "[$sid] $msg $res_n [$res_v]" $pass
             elif [ "$oper" = "<="  -a $res_v -le $val ]; then
                msg "DB" "[$sid] $msg $res_n [$res_v]" $pass
             elif [ "$oper" = ">"  -a $res_v -gt $val ]; then
                msg "DB" "[$sid] $msg $res_n [$res_v]" $pass
             elif [ "$oper" = "<"  -a $res_v -lt $val ]; then
                msg "DB" "[$sid] $msg $res_n [$res_v]" $pass
             elif [ "$oper" = "=="  -a $res_v -eq $val ]; then
                msg "DB" "[$sid] $msg $res_n [$res_v]" $pass
             else
                msg "DB" "[$sid] $msg [$res_n $oper (expected) $val ]" $fail
             fi
          fi
         done
      fi
    fi
  done


}

check_crs_status() {
  ha="Oracle High Availability Services"
  crs="Cluster Ready Services"
  css="Cluster Synchronization Services"
  evm="Event Manager"
  content=''

   [ ! -f "$ORACLE_HOME/bin/crsctl" ] && msg "CRS" "$ORACLE_HOME/bin/crsctl does not exist ..." $fail; 

   content=`$ORACLE_HOME/bin/crsctl check crs`

    if [ "`echo $content|grep -c \"$ha is online\"`" -eq 1 ]; then
       msg "CRS" "Check $ha" $pass
    else
       msg "CRS" "Check $ha" $fail
    fi
    if [ "`echo $content|grep -c \"$crs is online\"`" -eq 1 ]; then
       msg "CRS" "Check $crs" $pass
    else
       msg "CRS" "Check $crs" $fail
    fi
    if [ "`echo $content|grep -c \"$css is online\"`" -eq 1 ]; then
       msg "CRS" "Check $css" $pass
    else
       msg "CRS" "Check $css" $fail
    fi
    if [ "`echo $content|grep -c \"$evm is online\"`" -eq 1 ]; then
       msg "CRS" "Check $evm" $pass
    else
       msg "CRS" "Check $evm" $fail
    fi

    #check crs integrity

     gpnp_integrity=` su $crsow -c "$ORACLE_HOME/bin/cluvfy comp gpnp -n $MASTER_NODE" `
     asm_integrity=` su $crsow -c "$ORACLE_HOME/bin/cluvfy comp asm -n $MASTER_NODE" `
     crs_integrity=` su $crsow -c "$ORACLE_HOME/bin/cluvfy comp crs -n $MASTER_NODE" `
     clu_integrity=`  su $crsow -c "$ORACLE_HOME/bin/cluvfy comp clu -n $MASTER_NODE" `

      msg_="Verification of GPNP integrity (cluvfy comp gpnp -n <nodelist>)"
     if [ `echo "$gpnp_integrity" | grep -ic "PASSED"` -ge 1 ]; then
         msg "CRS" "${msg_}" $pass
     else
         msg "CRS" "${msg_}" $fail
     fi
      msg_="Verification of ASM integrity (cluvfy comp asm -n <nodelist>)"
     if [ `echo "$asm_integrity" | grep -ic "PASSED"` -ge 1 ]; then
         msg "CRS" "${msg_}" $pass
     else
         msg "CRS" "${msg_}" $fail
     fi
      msg_="Verification of CRS integrity (cluvfy comp crs  -n <nodelist>)"
     if [ `echo "$crs_integrity" | grep -ic "PASSED"` -ge 1 ]; then
         msg "CRS" "${msg_}" $pass
     else
         msg "CRS" "${msg_}" $fail
     fi
      msg_="Verification of cluster integrity (cluvfy comp clu -n <nodelist>)"
     if [ `echo "$clu_integrity" | grep -ic "PASSED"` -ge 1 ]; then
         msg "CRS" "${msg_}" $pass
     else
         msg "CRS" "${msg_}" $fail
     fi

    #check CRS resorce
    crs_stat=`$ORACLE_HOME/bin/crsctl stat res | grep scan_listener|wc -l`
    [ $crs_stat -gt 0 ] && msg "CRS" "Able to list CRS resources (crsctl stat res) ...." $pass
    [ $crs_stat -le 0 ] && msg "CRS" "Not Able to list CRS resources (crsctl stat res) ...." $fail

}

check_crs_chmrep_status() {

  chm="CHM Rep Size"
  stdvalue=`awk '/^<-- CRS CHM Repository begin -->/,/^<-- CRS CHM Repository end -->/ { print $0}' $0 | egrep -v "^(#|<--)"| awk -F ":" '{print $NF}'`
  content=''

   [ ! -f "$ORACLE_HOME/bin/oclumon" ] && msg "CRS" "$ORACLE_HOME/bin/oclumon does not exist ..." $fail && exit 2

   content=`$ORACLE_HOME/bin/oclumon manage -get repsize | grep 'CHM Repository Size' | awk '{print $NF}'`

    if [ "$content" -eq $stdvalue ]; then
       msg "CRS" "Check CHM Rep Size ($stdvalue sec) " $pass
    else
       msg "CRS" "Check CHM Rep Size (expected:$stdvalue sec/current:$content sec) " $fail
    fi

}

check_os_filesystem() {

  local ffull="$OUTDIR/_ffull.txt"
  rm -rf $ffull
  df -kP | sed -e "s/: / /g" |  egrep -v ":|Capacity" | while read line; do

    ND=`echo "$line" | awk '{print $1}'`
    FS=`echo "$line" | awk '{print $NF}'`
    SZ=`echo "$line" | awk '{print $(NF-1)}' | sed -e "s/%//g"`

    [ -n "$SZ" -a $SZ -ge 95 ] && msg "OS" "$ND Checking filesystem $FS : $SZ% used" $fail
    [ -n "$SZ" -a $SZ -lt 95 ] && msg "OS" "$ND Checking filesystem $FS : $SZ% used" $pass

  if [  -n "$SZ" -a $SZ -ge 100 ]; then
    echo ""
    echo "*******"
    echo " Please solve the filesystem before proceeding more checks ..."
    echo "*******"
    echo ""
    touch $ffull
  fi

  done

  #[ -f "$ffull" ] && rm -rf $ffull && exit 2

}

check_os_threshold() {
  OS=$(awk '/^<-- OS begin -->/,/^<-- OS end -->/ { print $0}' $0 | egrep -v "^(#|<--)")
 for h in `echo $OS`
 do
   [ `echo "$h"| grep -c "^LOADAVG"` -eq 1 ] && LOADAVG=`echo $h|cut -d":" -f2`
   [ `echo "$h"| grep -c "^FREESWAP"` -eq 1 ] && FREESWAP=`echo $h|cut -d":" -f2`
   [ `echo "$h"| grep -c "^FREEMEM"` -eq 1 ] && FREEMEM=`echo $h|cut -d":" -f2`
   [ `echo "$h"| grep -c "^TASK"` -eq 1 ] && TASK=`echo $h|cut -d":" -f2`
 done
}


check_sparc_os_status() {

   typeset int min1='';
   typeset int min5='';
   typeset int min15='';
   typeset int tasks='';
   typeset int tmem='';
   typeset int freem='';
   typeset int tswap='';
   typeset int frees='';

   top -b -c 0 > $OUTDIR/top.txt
   while read TOP
   do
    [ -z "$min1" ] &&  min1=`echo $TOP|grep "load avg"|awk '{print $6}'|sed -e "s/,//g"`
    [ -z "$min5" ] &&  min5=`echo $TOP|grep "load avg"|awk '{print $7}'|sed -e "s/,//g"`
    [ -z "$min15" ] &&   min15=`echo $TOP|grep "load avg"|awk '{print $8}'|sed -e "s/;//g"`
   [ -z "$tasks" ] &&   tasks=`echo $TOP|grep "processes:"|awk '{print $1}'`
    [ -z "$tmem" ] &&   tmem=`echo $TOP|grep "^Memory:"|awk '{print $2}'|sed -e "s/G//g"`
    [ -z "$freem" ] &&   freem=`echo $TOP|grep "^Memory:"|awk '{print $5}'|sed -e "s/G//g"`
    [ -z "$tswap" ] &&   tswap=`echo $TOP|grep "^Memory:"|awk '{print $8}'|sed -e "s/G//g"`
   [ -z "$frees" ] && frees=`echo $TOP|grep "^Memory:"|awk '{print $11}'|sed -e "s/G//g"`
   done  < $OUTDIR/top.txt

  load=${min5/.*}


   if [ $load -lt $LOADAVG ]; then
      msg "OS" "Load is at $min5" $pass
    else
      msg "OS" "Load is a bit high at $min5" $warning
    fi

    if [ $tasks -lt $TASK ]; then
      msg "OS" "Task count is at $tasks" $pass
    else
      msg "OS" "Task count is a bit high at $tasks" $warning
   fi

 # check swap
  swap=`echo "$tswap $frees"| awk '{print $2/$1*100}'`
 swap=${swap/.*}

    if [ $tasks -gt $FREEWAP ]; then
      msg "OS" "Free Swap is at $swap %" $pass
    else
      msg "OS" "Free Swap is a bit high at $swap %"  $warning
    fi

 # check memory
  free=`echo "$tmem $freem"| awk '{print $2/$1*100}'`
 free=${free/.*}

    if [ $free -gt $FREEMEM ]; then
      msg "OS" "Free Memory is at $free %" $pass
    else
      msg "OS" "Free Memory is a bit low at $free %" $warning
    fi


}

check_os_status() {

 # check load

 local ctype="$1"
 local group="$2"

 local host=""
 local load=""
 local typeset int min1=0
 local typeset int min5=0
 local typeset int min15=0
 local typeset int min1=0
 local typeset int task=0
 local typeset int tasks=0


 (cat /proc/loadavg| awk '{print "load: "$0}'; free -m)|  while read line; do

   if [ `echo "$line" | grep -c "load:"` -eq 1 ]; then

    host=`hostname |cut -d. -f1`
    load=`echo "$line" | grep "load:"| awk -F":" '{print $2}' `

     min1=`echo $load|awk '{print $1}'`
     min5=`echo $load|awk '{print $2}'`
     min15=`echo $load|awk '{print $3}'`
     task=`echo $load|awk '{print $4}'`
     tasks=`echo $task|awk -F"/" '{print $2}'`
     load=${min5/.*}

   
    if [ $load -lt $LOADAVG ]; then
      msg "${ctype}" "$host Load is at $min5" $pass
    else
      msg "${ctype}" "$host Load is at $min5" $fail
      #msg "${ctype}" "$host Load is a bit high at $min5" $warning
    fi

    if [ $tasks -lt $TASK ]; then
      msg "${ctype}" "$host Task count is at $tasks" $pass
    else
      msg "${ctype}" "$host Task count is at $tasks" $fail
     # msg "${ctype}" "$host Task count is a bit high at $tasks" $warning
    fi

  elif  [ `echo "$line" | grep -c "Swap:"` -eq 1 ];  then


    # check swap
    swap=`echo "$line"| awk -F":" '{print $2}' | awk '{print $3/$1*100}'`
    swap=${swap/.*}

    if [ $tasks -gt $FREEWAP ]; then
      msg "${ctype}" "$host Free Swap is at $swap %" $pass
    else
      msg "${ctype}" "$host Free Swap is at $swap %"  $fail
      #msg "${ctype}" "$host Free Swap is a bit high at $swap %"  $warning
    fi

  elif  [ `echo "$line" | grep -c "Mem:"` -eq 1 ];  then

    # check memory
    free=`echo "$line"| awk -F":" '{print $2}' | awk '{print $3/$1*100}'`
    free=${free/.*}

    if [ $free -gt $FREEMEM ]; then
      msg "${ctype}" "$host Free Memory is at $free %" $pass
    else
      msg "${ctype}" "$host Free Memory is at $free %" $fail
  #    msg "${ctype}" "$host Free Memory is a bit low at $free %" $warning
    fi
 
  fi

 done | awk '

  BEGIN { pref="" }
 
  /^CELL/ {
           pref="CELL OS: "
          host[$3] = $3
          if ($4 ~ /Load/ ) {  host_load[$3] = $7 ; host_load_status[$3] = $8 };
          if ($4 ~ /Task/ ) {  host_task[$3] = $8 ; host_task_status[$3] = $9 };
          if ($4 ~ /Free/ && $5 ~ /Memory/ ) {  host_mem[$3] = $8 ; host_mem_status[$3] = $10 }; 
          if ($4 ~ /Free/ && $5 ~ /Swap/  ) {  host_swap[$3] = $8 ; host_swap_status[$3] = $10 }; 
          
     }
   /^OS/ {
           pref="OS: "
          host[$2] = $2
          if ($3 ~ /Load/ ) {  host_load[$2] = $6 ; host_load_status[$2] = $7 };
          if ($3 ~ /Task/ ) {  host_task[$2] = $7 ; host_task_status[$2] = $8 };
          if ($3 ~ /Free/ && $4 ~ /Memory/ ) {  host_mem[$2] = $7 ; host_mem_status[$2] = $9 };
          if ($3 ~ /Free/ && $4 ~ /Swap/  ) {  host_swap[$2] = $7 ; host_swap_status[$2] = $9 };
     }
   END {
         printf "%-8s %-15s  %10s%-5s  %10s%-5s  %12s%-5s  %12s%-5s   %5s\n", 
             "", "Host", "Load","", "Task","", "FreeMem", "", "FreeSwap" ,"", "Status"

         ok="ok"

         for (i in host) {
             if ( host_load_status[i]  !~ /ok/ || host_task_status[i]  !~ /ok/ ||  host_mem_status[i] !~ /ok/ || host_swap_status[i] !~ /ok/ ) ok="fail"
             printf "%-8s %-15s  %10.2f%-5s  %10d%-5s  %10d%-5s  %10d%-5s  %5s\n", pref, i, 
                              host_load[i]," ("host_load_status[i]")",
                              host_task[i]," ("host_task_status[i]")",
                              host_mem[i]," % ("host_mem_status[i]")",
                              host_swap[i]," % ("host_swap_status [i]")",
                               ok
         }
  }
  '
  echo ""

}

check_os_setting_sub()
{

local delimbegin=$1
local delimend=$2
local reffile=$3

sed -n "/^$delimbegin/,/^$delimend/"p $0 | egrep -v "^(#|<--)" | while read prop
do
        pname=`echo $prop| awk -F":" '{ print $1 }'`
    stdval=`echo $prop| awk -F":" '{ print $2 }'`
        val=`grep "^$pname" $reffile | awk -F":" '{ print $2 }'`
    res=`grep "^$pname" $reffile`
       
        if [[ "$prop" = "$res" ]]
        then
           msg "OS" "[$pname] equals to $stdval " $pass
        else
           msg "OS" "[$pname] [$val <> (expected) $stdval]" $fail
        fi
done
echo

}

check_os_setting_sub1()
{

local delimbegin=$1
local delimend=$2
local reffile=$3

std=`sed -n "/^$delimbegin/,/^$delimend/"p $0 | egrep -v "^(#|<--)"`

cat $reffile | while read prop
do
        pname=`echo $prop| awk -F":" '{ print $1 }'`
    val=`echo $prop| awk -F":" '{ print $2 }'`
        stdval=`sed -n "/^$delimbegin/,/^$delimend/"p $0 | egrep -v "^(#|<--)" | grep "^$pname" | awk -F":" '{ print $2 }'`
    res=`sed -n "/^$delimbegin/,/^$delimend/"p $0 | egrep -v "^(#|<--)" | grep "^$pname"`
       
        if [[ "$prop" = "$res" ]]
        then
           msg "OS" "[$pname] equals to $stdval " $pass
        else
           msg "OS" "[$pname] [$val <> (expected) $stdval]" $fail
        fi
done
echo

}

check_os_setting() {

# Check kernel parameters
systmp=$OUTDIR/dbcheck_sysctl_ctl_$$.lst
onlinesystmp=$OUTDIR/dbcheck_onlinesysctl_ctl_$$.lst

limitstmp=$OUTDIR/dbcheck_limits_$$.lst

mtutmp=$OUTDIR/dbcheck_mtu_$$.lst
onlinemtutmp=$OUTDIR/dbcheck_onlinemtu_$$.lst

#arpannouncetmp=$OUTDIR/dbcheck_arpannounce_$$.lst
onlinearpannouncetmp=$OUTDIR/dbcheck_onlinearpannounce_$$.lst

memsize=`awk '/MemTotal/ {print $2}' /proc/meminfo`

if [ $memsize -ge 800000000 -a $memsize -lt 1700000000 ]
then
        mark='for 1T'
elif [ $memsize -ge 1700000000 ]
then
        mark='for 2T'
fi

# get current sysctl.ctl
egrep -i '^[  ]*(fs.aio-max-nr|kernel.msgmax|kernel.msgmnb|kernel.msgmni|kernel.sem|kernel.shmall|kernel.shmmax|kernel.shmmni|vm.hugetlb_shm_group|vm.nr_hugepages|vm.min_free_kbytes|kernel.randomize_va_space)[   ]*=[  ]*' /etc/sysctl.conf | sed -e 's/^[   ]*//' -e 's/[   ]*=[  ]*/:/' -e 's/[  ][  ]*/ /g' | awk -F ':' '{print $1}' | while read line; do egrep -i $line /etc/sysctl.conf | grep -v '^#'| sed -e 's/^[  ]*//' -e 's/[   ]*=[  ]*/:/' -e 's/[  ][  ]*/ /g' -e 's/[   ]*$//g' | tail -n 1;done | sort -u > $systmp

#egrep -i '^[ \t]*(fs.aio-max-nr|kernel.msgmax|kernel.msgmnb|kernel.msgmni|kernel.sem|kernel.shmall|kernel.shmmax|kernel.shmmni|vm.hugetlb_shm_group|vm.nr_hugepages|vm.min_free_kbytes|kernel.randomize_va_space)[ \t]*=[ \t]*' /etc/sysctl.conf| sed -e 's/^[ \t]*//' -e 's/[ \t]*=[ \t]*/:/' -e 's/[ \t][ \t]*/ /g' | sort -u > $systmp

# get current online kernel setting
sysctl -a 2>/dev/null | egrep -i '^(fs.aio-max-nr|kernel.msgmax|kernel.msgmnb|kernel.msgmni|kernel.sem|kernel.shmall|kernel.shmmax|kernel.shmmni|vm.hugetlb_shm_group|vm.nr_hugepages|vm.min_free_kbytes|kernel.randomize_va_space) ' | grep -v 'kernel.sem_next_id' | sed -e 's/ = /:/' -e 's/[  ][  ]*/ /g' | sort -u > $onlinesystmp

# get limits.conf setting
cat /etc/security/limits.conf | grep '[   ]*oracle' | sed -e 's/[   ][  ]*soft[   ][  ]*/\_soft\_/' -e 's/[   ][  ]*hard[   ][   ]*/\_hard\_/' -e 's/[  ][  ]*/:/' -e 's/^oracle_//' -e 's/[   ]*$//g' | sort -u > $limitstmp

if [ $ISSAAS -eq 1 ]
then
        # check kernel setting
        echo
        echo "Check Kernel Setting in sysctl.ctl: "
        check_os_setting_sub "<-- SAAS OS kernel setting $mark begin -->" "<-- SAAS OS kernel setting $mark end -->" "$systmp"

        echo
        echo "Check Kernel Setting in effect: "
        check_os_setting_sub "<-- SAAS OS kernel setting $mark begin -->" "<-- SAAS OS kernel setting $mark end -->" "$onlinesystmp"

        # check limits
        echo
        echo "Check Limits Setting in limits.conf: "
        check_os_setting_sub "<-- SAAS OS limits setting $mark begin -->" "<-- SAAS OS limits setting $mark end -->" "$limitstmp"

        # get mtu setting
        grep 'MTU=' /etc/sysconfig/network-scripts/ifcfg-*ib* | cut -c 32- | sed 's/[   ]*//g' | grep -v 2044 | grep -v '#MTU' | sed -e 's/^ifup-ib:.*&&/ifup-ib,/' | sed -e 's/^ifcfg-//' -e 's/:MTU=/:/' | sort -u > $mtutmp

        # get mtu online setting
        for F in `cd /sys/class/net/; ls -d *ib*;`;do echo $F':MTU='`cat /sys/class/net/${F}/mtu`;done|sed -e 's/:MTU=/:/' > $onlinemtutmp
       
        # check MTU
        echo
        echo "Check MTU Setting for IB interface in ifcfg-*ib*: "
        check_os_setting_sub1 "<-- SAAS OS mtu setting begin -->" "<-- SAAS OS mtu setting end -->" "$mtutmp"
        echo
        echo "Check MTU Setting in effect: "
        check_os_setting_sub1 "<-- SAAS OS mtu setting begin -->" "<-- SAAS OS mtu setting end -->" "$onlinemtutmp"
else
        # check kernel setting
        echo
        echo "Check Kernel Setting in sysctl.ctl: "
        check_os_setting_sub "<-- $MODEL OS kernel setting begin -->" "<-- $MODEL OS kernel setting end -->" "$systmp"

        echo
        echo "Check Kernel Setting in effect: "
        check_os_setting_sub "<-- $MODEL OS kernel setting begin -->" "<-- $MODEL OS kernel setting end -->" "$onlinesystmp"

        # check limits
        echo
        echo "Check Limits Setting in limits.conf: "
        check_os_setting_sub "<-- $MODEL OS limits setting begin -->" "<-- $MODEL OS limits setting end -->" "$limitstmp"
fi


#egrep "accept_local|arp_announce|arp_ignore|arp_accept|.rp_filter|locktime|base_reachable_time_ms|delay_first_probe_time" /etc/sysctl.conf | egrep "ib|all|default" | grep -v "^#"| cut -d"=" -f1 | awk '{print $1}' | sed -e 's/  *//g' | sort -u | while read line; do egrep -i $line /etc/sysctl.conf | grep -v '^#' | sed -e 's/^[ \t]*//' -e 's/[ \t]*=[ \t]*/:/' -e 's/[ \t][ \t]*/ /g' -e 's/[ \t]*$//g' | tail -n 1;done | sort -u > $arpannouncetmp

#echo
#echo "Check accept_local|arp_announce|arp_ignore|arp_accept|.rp_filter|locktime|base_reachable_time_ms|delay_first_probe_time: "
#check_os_setting_sub "<-- IBARP_${MODEL}_${BONDTYPE}_begin -->" "<-- IBARP_${MODEL}_${BONDTYPE}_end -->" "$arpannouncetmp"

       
rm -f $systmp
rm -f $onlinesystmp
rm -f $limitstmp
rm -f $mtutmp
rm -f $onlinemtutmp
rm -f $mactmp
#rm -f $arpannouncetmp
rm -f $onlinearpannouncetmp
}

check_service_registered() {
   tns="$1"

  # set asm environment
  env_asm

   res=$(
   su $crsow -c "
   export ORACLE_HOME=$CRS_HOME
   export LD_LIBRARY_PATH=$ORACLE_HOME/lib
   export PATH=/usr//bin:/bin:/usr/bin:$ORACLE_HOME/bin
   $ORACLE_HOME/bin/lsnrctl  service $tns"
  )
   typeset int scnt=`echo "$res" | egrep -ce "Service \"[[:alnum:]\._]*\" has"`
   typeset int cnt=`echo "$res" | egrep -ce "Instance \"[[:alnum:]]*\", status READY"`
   typeset int ucnt=`echo "$res" | egrep -ce "Instance \"[[:alnum:]]*\", status UNKNOWN"`

  if [ $ucnt -ne 0 ]; then
     msg "TNS" "[$tns] Check unknown registration [$ucnt]" $warning
     echo "$res" | egrep -e "Instance \"[[:alnum:]]*\", status UNKNOWN"
  elif [ $scnt -eq 0 ]; then
     msg "TNS" "[$tns] Check services [$scnt]" $warning
  elif [ $scnt -le 7 ]; then
     msg "TNS" "[$tns] Check services count [$scnt]" $pass
     echo "$res" | egrep -e "Service \"[[:alnum:]\._]*\" has"
     #echo "$res" | egrep -e "Instance \"[[:alnum:]]*\", status READY"
  else
     msg "TNS" "[$tns] Check services count [$scnt]" $pass
  fi
 
}

check_tns_status() {
   typeset int stat=0
   typeset int cnt=0
  for h in `crsctl stat res|grep lsnr| cut -d"=" -f2`
  do
     lsnr=`echo "$h" | cut -d"." -f2`
    stat=`$ORACLE_HOME/bin/crsctl stat res $h | grep STATE | grep -c "ONLINE on $MASTER_NODE"`
    if [ $stat -eq 1 ]; then
     msg "TNS" "[$lsnr] Check status" $pass
     
     check_service_registered "$lsnr"

     else
     msg "TNS" "[$lsnr] Check status" $fail
    fi
 #  cnt=$((cnt+1))
 #  [ $cnt -eq 10 ] && break
  done
}


check_cell_status() {

 echo ""
 echo "Checking MS, RS, CELLSRV processes ..."
 echo ""
 /usr/local/bin/dcli -l root -g /root/cell_group "service celld status|grep -c \"running$\"|awk '!/3/ { print \"Not all processes (ms,rs,cellsrv) running ... fail\"} /3/ { print \"All processes (ms,rs,cellsrv) running ... ok\"}'"  | while read line; do
    echo "CELL: $line"
 done
}

check_cell_iostat() {

  echo ""
  echo "Checking Cell IOSTAT ..."
  echo ""

  local cell_iostat=$OUTDIR/_cell_iostat.sh
  touch $cell_iostat

  [ ! -f "$cell_iostat" ] && echo "Not able to create CELL IOSTAT script ..." && return 1

  cat $0 | awk '/^<--- BEGIN CELL IOSTAT -->/,/^<--- END CELL IOSTAT -->/ { print $0 }' |egrep -v "<--- BEGIN CELL IOSTAT -->|<--- END CELL IOSTAT -->" > $cell_iostat
  chmod 755 $cell_iostat

   echo ""| awk '{ printf "%16s  %-5s  %7s  %7s  %10s  %10s  %7s  %7s  %7s  %7s  %5s\n", "IP", "Dev", "r/s", "w/s", "rsec/s", "wsec/s", "AvgRq", "AvgQu", "Await","Svctm","%Util" }'
 
  /usr/local/bin/dcli -l root -g /root/cell_group -x $cell_iostat -d $OUTDIR | \
     awk ' { printf "%16s  %-5s  %7.2f  %7.2f  %10.2f  %10.2f  %7.2f  %7.2f  %7.2f  %7.2f  %5.2f\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11 }'

}

check_cell_metric() {

  echo ""
  echo "Checking Cell Metric ..."
  echo ""

  local cell_io=$OUTDIR/_cell_io.txt
  local cell_lrt=$OUTDIR/_cell_lrt.txt
  local cell_lwt=$OUTDIR/_cell_lwt.txt
  local cell_srt=$OUTDIR/_cell_srt.txt
  local cell_swt=$OUTDIR/_cell_swt.txt
  local cell_lrr=$OUTDIR/_cell_lrr.txt
  local cell_lwr=$OUTDIR/_cell_lwr.txt
  local cell_srr=$OUTDIR/_cell_srr.txt
  local cell_swr=$OUTDIR/_cell_swr.txt
  local cell_usm=$OUTDIR/_cell_usm.txt
  local cell_ulg=$OUTDIR/_cell_ulg.txt
  local cell_metric=$OUTDIR/_cell_metric.sh
  touch $cell_metric

  echo -n "" > $cell_io
  echo -n "" > $cell_lrt
  echo -n "" > $cell_lwt
  echo -n "" > $cell_srt
  echo -n "" > $cell_swt
  echo -n "" > $cell_lrr
  echo -n "" > $cell_lwr
  echo -n "" > $cell_srr
  echo -n "" > $cell_swr
  echo -n "" > $cell_usm
  echo -n "" > $cell_ulg

  [ ! -f "$cell_metric" ] && echo "Not able to create CELL METRIC script ..." && return 1

  local c_epoc=`date +"%s"`
  local o_epoc=$(( c_epoc - 7200 ))  # 2 hours
  local sdate=`date -d @$o_epoc +"%Y-%m-%dT%H:%M:%S%z"`

  cat $0 | awk '/^<--- BEGIN CELL METRIC -->/,/^<--- END CELL METRIC -->/ { print $0 }' |egrep -v "<--- BEGIN CELL METRIC -->|<--- END CELL METRIC -->" > $cell_metric
  chmod 755 $cell_metric

  [ -f "$cell_metric" ] && sed -i "s/<DATE>/$sdate/g" $cell_metric

  /usr/local/bin/dcli -l root -g /root/cell_group -x $cell_metric -d $OUTDIR | awk '{ $1=""; print $0}' > $cell_io

   grep " LRT " $cell_io | sed -e "s/ LRT / /g" > $cell_lrt
   grep " LwT " $cell_io | sed -e "s/ LWT / /g" > $cell_lwt
   grep " SRT " $cell_io | sed -e "s/ SRT / /g" > $cell_srt
   grep " SwT " $cell_io | sed -e "s/ SWT / /g" > $cell_swt
   grep " LRR " $cell_io | sed -e "s/ LRR / /g" > $cell_lrr
   grep " LWR " $cell_io | sed -e "s/ LWR / /g" > $cell_lwr
   grep " SRR " $cell_io | sed -e "s/ SRR / /g" > $cell_srr
   grep " SWR " $cell_io | sed -e "s/ SWR / /g" > $cell_swr
   grep " USM " $cell_io | sed -e "s/ USM / /g" > $cell_usm
   grep " ULG " $cell_io | sed -e "s/ ULG / /g" > $cell_ulg


   graph_errors "$cell_lrt" "CM" "LRT"
   graph_errors "$cell_lwt" "CM" "LWT"
   graph_errors "$cell_srt" "CM" "SRT"
   graph_errors "$cell_swt" "CM" "SWT"
   graph_errors "$cell_lrr" "CM" "LRR"
   graph_errors "$cell_lwr" "CM" "LWR" 
   graph_errors "$cell_srr" "CM" "SRR"
   graph_errors "$cell_swr" "CM" "SWR"
   graph_errors "$cell_usm" "CM" "USM"
   graph_errors "$cell_ulg" "CM" "ULG"

   [ -f "$cell_io" ] && rm -rf "$cell_io"
   [ -f "$cell_lrt" ] && rm -rf "$cell_lrt"
   [ -f "$cell_lwt" ] && rm -rf "$cell_lwt"
   [ -f "$cell_srt" ] && rm -rf "$cell_srt"
   [ -f "$cell_swt" ] && rm -rf "$cell_swt"
   [ -f "$cell_lrr" ] && rm -rf "$cell_lrr"
   [ -f "$cell_lwr" ] && rm -rf "$cell_lwr"
   [ -f "$cell_srr" ] && rm -rf "$cell_srr"
   [ -f "$cell_swr" ] && rm -rf "$cell_swr"
   [ -f "$cell_usm" ] && rm -rf "$cell_usm"
   [ -f "$cell_ulg" ] && rm -rf "$cell_ulg"

}


check_cell_lun_status() {
 echo ""
 echo "Checking Cell Luns ..."
 echo ""
 /usr/local/bin/dcli -l root -g /root/cell_group "cellcli -e  list lun attributes disktype,status|sort|uniq -c"|while read line; do


   [ `echo "$line"|grep -c "FlashDisk"` -eq 1 ] && [ `echo "$line" | egrep -i " 16"|grep -c normal` -eq 1 ] && msg "CELL" "Checking LUNs ... $line" $pass
   [ `echo "$line"|grep -c "FlashDisk"` -eq 1 ] && [ `echo "$line" | egrep -i " 16"|grep -c normal` -ne 1 ] && msg "CELL" "Checking LUNs ... $line" $warning

   [ `echo "$line"|grep -c "HardDisk"` -eq 1 ] && [ `echo "$line" | egrep -i " 12"|grep -c normal` -eq 1 ] && msg "CELL" "Checking LUNs ... $line" $pass
   [ `echo "$line"|grep -c "HardDisk"` -eq 1 ] && [ `echo "$line" | egrep -i " 12"|grep -c normal` -ne 1 ] && msg "CELL"  "Checking LUNs ... $line" $warning


 done
}

check_cell_griddisk_active() {
 echo ""
 echo "Checking Cell Griddisks [ if this hangs, you might be hitting bug 20591915 ] ..."
 echo ""
 /usr/local/bin/dcli -l root -g /root/cell_group "cellcli -e 'list griddisk attributes asmmodestatus,asmdeactivationoutcome,status'|sort|uniq -c" | while read line; do

   [ `echo "$line"|egrep -i " 34| 36"|grep -i "online"|grep -i "yes" | grep -ic "active"` -eq  1 ] && msg "CELL" "Checking GRIDDisk  ... $line" $pass
   [ `echo "$line"|egrep -i " 34| 36"|grep -i "online"|grep -i "yes" | grep -ic "active"` -ne  1 ] && msg "CELL"  "Checking GRIDDisk  ... $line" $warning

 done
}

check_hw_fault() {

 local ctype="$1"
 local group="$2"
 local hw_file_fault="$OUTDIR/_hw_fault.txt"

  return;
 echo ""
 echo "Checking Cell Hardware Issue  ..."
 echo ""

 /usr/local/bin/dcli -l root -g "$group" "ipmitool sunoem cli 'show faulty'" 2>&1 | \
  awk '
   /class/ ||
   /sunw-msg-id/ ||
   /component/ ||
   /timestamp/ ||
   /fru_part_number/ ||
   /fru_serial_number/ ||
   /product_serial_number/ ||
   /chassis_serial_number/  { printf "HW: %20s    %-25.25s  :    %s \n", $1, $4, $NF }
   /busy/ { print "HW: ILOM is busy ..." }
 ' > $hw_file_fault

  for h in `cat "$group"`; do
    if [ `egrep "^$h$" -c "$hw_file_fault"` -gt 0 ]; then
        msg "${ctype}" "HW: ${h} Hardware fault detected ..." $fail
        egrep "^$h$" "$hw_file_fault" | awk '{ print "OS: $0" }'
    else
        msg "${ctype}" "HW: ${h} No hardware fault detected ..." $pass
    fi
  done


  [ -f "$hw_file_fault" ] && rm -rf "$hw_file_fault"

}


check_cell_hw_fault() {

  check_hw_fault "CELL" "/root/cell_group"
  echo ""

} 

check_db_hw_fault() {

  check_hw_fault "OS" "/root/dbs_group"
  echo ""
}

check_sql_monitor() {
 echo ""
 echo "Checking Top SQL  ( Taken from Real-Time SQL monitor  )..."
 echo ""
 echo "Note: SQL monitor statistics stays for 1 minute only by default. It captures active SQL that runs over 5 seconds or with DOP"
 echo ""
 echo "Note: To get detail of a SQL monitored query, use the following:"
 echo ""
 echo "sqlplus> set lines 180 pages 1000 long 1000000 longchunksize 200"
 echo "sqlplus> select dbms_sqltune.report_sql_monitor( -"
 echo "              sql_id=><sqlid>, -"
 echo "              sql_exec_id=><sql_exec_id>, -"
 echo "              sql_exec_start=> TO_DATE('<date>','dd-mon-yyyy hh24:mi:ss'), -"
 echo "              report_level=>'ALL') -"
 echo "              as report  FROM dual; "
 echo ""

 local sql_stat="$OUTDIR/_sql_monitor.txt"
 local sql_top="$OUTDIR/_sql_mtop.txt"

 cat $DB_STATS | grep "^SQLMON " | sed -e "s/^SQLMON //g" > $sql_stat

 echo ""

 cat "$sql_stat" | awk  '
  {
      sqldb[$3]=$1
      sqlsource[$3]=$2
      sqlid[$3]=$3
      sqlelapse[$3] += $4
      sqlcpu[$3] += $5
      sqlqueue[$3] += $6
      sqlappl[$3] += $7
      sqlconc[$3] += $8
      sqlclust[$3] += $9
      sqluserio[$3] += $10
      sqlphysreadmb[$3] += $11
      sqlphyswritemb[$3] += $12
      sqlgets[$3] += $13
      sqlplsql_exe[$3] += $14
      sqljava_exe[$3] += $15
      sqlfetch[$3] += $16
  }
  END {
     for (i in sqlid) {
        printf "%15s  %10d  %10.1f  %12.1f  %10d  %10.1f  %13.1f  %10.1f  %10d  %11d  %10d  %10d  %10d  %-20s\n",
          i, sqlelapse[i], sqlcpu[i], sqlqueue[i], sqlappl[i], sqlconc[i],sqlclust[i],sqluserio[i],
                  sqlphysreadmb[i], sqlphywritemb[i], sqlgets[i], sqlfetch[i], sqlplsql_exe[i], sqlsource[i]

    }
  }
   ' > $sql_top

 for p in `seq 1 6`; do
    echo ""
    case $p in
    1)  echo "Top SQL by Elapse";;
    2)  echo "Top SQL by CPU";;
    3)  echo "Top SQL by Concurrency";;
    4)  echo "Top SQL by Cluster";;
    5)  echo "Top SQL by UserIO";;
    6)  echo "Top SQL by Gets";;
    esac

    echo ""
    echo "" | awk ' { printf "%15s  %10s  %10s  %12s  %10s  %10s  %13s  %10s  %10s  %11s  %10s  %10s  %10s  %-20s\n",
            "SQLID", "Elapsed(s)",  "CPU(s)", "Queue(s)" ,"Applic(s)", "Concurr(s)", "Cluster(s)", "UserIO(s)",
            "PhysReadMb", "PhysWriteMb", "Gets", "Fetches", "PlsqlExe", "Schema"}'

    case $p in
     1)  cat "$sql_top" | sort -rn -k2,2 ;;
     2)  cat "$sql_top" | sort -rn -k3,3 ;;
     3)  cat "$sql_top" | sort -rn -k6,6 ;;
     4)  cat "$sql_top" | sort -rn -k7,7 ;;
     5)  cat "$sql_top" | sort -rn -k8,8 ;;
     6)  cat "$sql_top" | sort -rn -k11,11 ;;
    esac | head -20

 done

 echo ""
 echo "Checking Top SQL By Elapsed Time Order by DB ( Taken from Real-Time SQL monitor  )..."
 echo ""

    echo ""
    echo "" | awk ' {  printf "%15s  %10s %-15s  %10s %-15s  %10s %-15s   %10s %-15s  %10s %-15s\n",
            "DB", "(sec)", "Top 1", "(sec)", "Top 2", "(sec)", "Top 3" , "(sec)", "Top 4", "(sec)", "Top 5" }'

 cat "$sql_stat" | awk  '
  {
      sqldb[$1]=$1
      if ($4 > sqltop1[$1]) { sqltop1[$1]=$4; sqlid1[$1]=$3; next }
      if ($4 > sqltop2[$1]) { sqltop2[$1]=$4; sqlid2[$1]=$3; next }
      if ($4 > sqltop3[$1]) { sqltop3[$1]=$4; sqlid3[$1]=$3; next }
      if ($4 > sqltop4[$1]) { sqltop4[$1]=$4; sqlid4[$1]=$3; next }
      if ($4 > sqltop5[$1]) { sqltop5[$1]=$4; sqlid5[$1]=$3; next }
  }
  END {
     for (i in sqldb) {
        if (length(i)>0) printf "%15s  %10d %-15s  %10d %-15s  %10d %-15s   %10d %-15s  %10d %-15s\n",
          i, sqltop1[i], sqlid1[i], sqltop2[i], sqlid2[i], sqltop3[i], sqlid3[i], sqltop4[i], sqlid4[i], sqltop5[i], sqlid5[i]

    }
  }
   ' | sort -k2,2 -rn | head -20

 echo ""
 echo "Checking Top SQL By CPU Time Order by DB ( Taken from Real-Time SQL monitor  )..."
 echo ""

    echo ""
    echo "" | awk ' {  printf "%15s  %10s %-15s  %10s %-15s  %10s %-15s   %10s %-15s  %10s %-15s\n",
            "DB", "(sec)", "Top 1", "(sec)", "Top 2", "(sec)", "Top 3" , "(sec)", "Top 4", "(sec)", "Top 5" }'

 cat "$sql_stat" | awk  '
  {
      sqldb[$1]=$1
      if ($5 > sqltop1[$1]) { sqltop1[$1]=$5; sqlid1[$1]=$3; next }
      if ($5 > sqltop2[$1]) { sqltop2[$1]=$5; sqlid2[$1]=$3; next }
      if ($5 > sqltop3[$1]) { sqltop3[$1]=$5; sqlid3[$1]=$3; next }
      if ($5 > sqltop4[$1]) { sqltop4[$1]=$5; sqlid4[$1]=$3; next }
      if ($5 > sqltop5[$1]) { sqltop5[$1]=$5; sqlid5[$1]=$3; next }
  }
  END {
     for (i in sqldb) {
        if (length(i) > 0) printf "%15s  %10d %-15s  %10d %-15s  %10d %-15s   %10d %-15s  %10d %-15s\n",
          i, sqltop1[i], sqlid1[i], sqltop2[i], sqlid2[i], sqltop3[i], sqlid3[i], sqltop4[i], sqlid4[i], sqltop5[i], sqlid5[i]

    }
  }
   ' | sort -k2,2 -rn | head -20

 echo ""
 echo "Checking Top SQL By Gets Order by DB ( Taken from Real-Time SQL monitor  )..."
 echo ""

    echo ""
    echo "" | awk ' {  printf "%15s  %10s %-15s  %10s %-15s  %10s %-15s   %10s %-15s  %10s %-15s\n",
            "DB", "(sec)", "Top 1", "(sec)", "Top 2", "(sec)", "Top 3" , "(sec)", "Top 4", "(sec)", "Top 5" }'

 cat "$sql_stat" | awk  '
  {
      sqldb[$1]=$1
      if ($11 > sqltop1[$1]) { sqltop1[$1]=$11; sqlid1[$1]=$3; next }
      if ($11 > sqltop2[$1]) { sqltop2[$1]=$11; sqlid2[$1]=$3; next }
      if ($11 > sqltop3[$1]) { sqltop3[$1]=$11; sqlid3[$1]=$3; next }
      if ($11 > sqltop4[$1]) { sqltop4[$1]=$11; sqlid4[$1]=$3; next }
      if ($11 > sqltop5[$1]) { sqltop5[$1]=$11; sqlid5[$1]=$3; next }
  }
  END {
     for (i in sqldb) {
       if (length(i) > 0)  printf "%15s  %10d %-15s  %10d %-15s  %10d %-15s   %10d %-15s  %10d %-15s\n",
          i, sqltop1[i], sqlid1[i], sqltop2[i], sqlid2[i], sqltop3[i], sqlid3[i], sqltop4[i], sqlid4[i], sqltop5[i], sqlid5[i]

    }
  }
   ' | sort -k2,2 -rn | head -20



 echo ""
  [ -f "$sql_stat" ] && rm -rf "$sql_stat"
  [ -f "$sql_top" ] && rm -rf "$sql_top"

}

check_sql_stat() {

 echo ""
 echo "Checking Top SQL  (Taken from DBA_HIST_SQLSTAT  )..."
 echo ""

 local sql_stat="$OUTDIR/_sql_stat.txt"
 local sql_top="$OUTDIR/_sql_top.txt"
 
 cat $DB_STATS | grep "^SQLSTAT " | sed -e "s/^SQLSTAT //g" > $sql_stat

 echo ""

 cat "$sql_stat" | awk  '
  {
      sqlschema[$2]=$1
      sqlid[$2]=$2
      sqlexec[$2] += $4
      sqlcpu[$2] += $5
      sqlelapse[$2] += $6
      sqlparse[$2] += $7
      sqlfetches[$2] += $8
      sqlrows[$2] += $9
      sqlphysr[$2] += $10
      sqliops[$2] += $11
      sqlmbbytes[$2] += $12
      sqloffload[$2] += $13
      sqlgets[$2] += $14
  }
  END {
     for (i in sqlid) {
        gets_per_exec = 0
        elapse_per_exec = 0
        cpu_per_exec = 0
        if ( sqlexec[i] > 0 ) {
         gets_per_exec = sqlgets[i]/sqlexec[i]
         elapse_per_exec = sqlelapse[i]/sqlexec[i]
         cpu_per_exec = sqlcpu[i]/sqlexec[i]
        }

        printf "%15s  %10d  %10.1f  %12.1f  %10d  %10.1f  %13.1f  %10.1f  %10d  %10d  %10d  %10d  %10d  %-20s\n",
          i, sqlexec[i], sqlcpu[i], sqlelapse[i], sqlgets[i], gets_per_exec, elapse_per_exec, cpu_per_exec,
                  sqlparse[i], sqlfetches[i], sqlrows[i], sqlphysr[i], sqliops[i], sqlschema[i]

    }
  }
   ' > $sql_top

 for p in `seq 1 6`; do

    echo ""
    case $p in
    1)  echo "Top SQL by Execution";;
    2)  echo "Top SQL by CPU";;
    3)  echo "Top SQL by Elapse";;
    4)  echo "Top SQL by Gets";;
    5)  echo "Top SQL by Gets per Exec";;
    6)  echo "Top SQL by Elapse per Exec";;
    esac

    echo ""
    echo "" | awk ' { printf "%15s  %10s  %10s  %12s  %10s  %10s  %13s  %10s  %10s   %10s  %10s  %10s  %10s  %-20s\n",
            "SQLID",  "Execs","CPU(sec)","Elapsed(sec)" ,"Gets", "Gets/Exec", "Elaps/Exe(s)", "CPU/Exec",
            "Parse","Fetches","Rows", "PhysReads", "IOPS", "SCHEMA"}'

    case $p in
     1)  cat "$sql_top" | sort -rn -k2,2 ;;
     2)  cat "$sql_top" | sort -rn -k3,3 ;;
     3)  cat "$sql_top" | sort -rn -k4,4 ;;
     4)  cat "$sql_top" | sort -rn -k5,5 ;;
     5)  cat "$sql_top" | sort -rn -k6,6 ;;
     6)  cat "$sql_top" | sort -rn -k7,7 ;;
    esac | head -20

 done


 echo ""
  [ -f "$sql_stat" ] && rm -rf "$sql_stat"
  [ -f "$sql_top" ] && rm -rf "$sql_top"

}


check_system_event() {

 echo ""
 echo "Checking Latency (Taken from DBA_HIST_SYSTEM_EVENT) ..."
 echo ""

 local sys_event="$OUTDIR/_sys_event.txt"

 cat $DB_STATS | grep "^SYSEVENT " | sed -e "s/^SYSEVENT //g" > $sys_event

 echo ""

 echo "" | awk ' { printf "%11s  %11s  %11s  %11s  %11s  %14s  %11s  %20s  %-45s\n",
      "Waits", "Timeouts", "Waited(sec)", "AvgWt(ms)", "Waits FG", "Waited FG(sec)", "AvgFGWt(ms)", "Wait Class", "Event" }'


 cat "$sys_event" | awk  -F"~" '
  {
     split($4,a, " ")
     evt_event[$2]=$2
     evt_class[$2]=$3
     evt_waits[$2]=a[1]
     evt_wait_to[$2]=a[2]
     evt_time_waited[$2]=a[3]
     evt_waits_fg[$2]=a[4]
     evt_time_waited_fg[$2]=a[5]
  }
   END {
      for (i in  evt_event) {
       time_waited=evt_time_waited[i]/1000
       time_waited_fg=evt_time_waited_fg[i]/1000
       if (evt_waits[i] > 0 && evt_waits_fg[i] > 0) {
          avgms=evt_time_waited[i]/evt_waits[i]
          avgfgms=evt_time_waited_fg[i]/evt_waits_fg[i]
            printf "%11d  %11d  %11d  %11.1f  %11d  %14d  %11.1f  %20s  %-45s\n",
            evt_waits[i], evt_wait_to[i],time_waited, avgms, evt_waits_fg[i],time_waited_fg, avgfgms, evt_class[i], i
        }
      }
    }
   ' | sort -rn -k1,1 | head -30

  [ -f "$sys_event" ] && rm -rf "$sys_event"

}

check_db_info() {

  echo ""
  echo "Collecting SID information ..."
  echo ""

  local db_info=$OUTDIR/_db_info.sh
  touch $db_info

  [ ! -f "$db_info" ] && echo "Not able to create DB INFO script ..." && return 1

  cat $0 | awk '/^<--- BEGIN DB INFO -->/,/^<--- END DB INFO -->/ { print $0 }' |egrep -v "<--- BEGIN DB INFO -->|<--- END DB INFO -->" | sed "s@\$OUTDIR@${OUTDIR}@g" > $db_info
  chmod 755 $db_info

  $db_info -d $OUTDIR

  DB_INFO_COUNT=`wc -l $DB_INFO | awk '{print $1}' 2>/dev/null`

}

sleep_stats() {

 local batch="$1"
 local slp_cnt=0
 local clean=1
 local locked=""
 processed_db=`ls -1 $OUTDIR/_db_stat_*.lck 2>/dev/null|wc -l`
 locked=`ls -l $OUTDIR/_db_stat_*lck 2>/dev/null|awk '{print $NF}'|awk -F"_" '{print $NF}'|cut -d"." -f1|xargs echo`
 echo ""
 echo "Batch $batch: $locked"
 echo -n "processing "
 while [ $processed_db -gt 0 ]; do
   clean=1
   slp_cnt=$(( slp_cnt + 1 ))
   processed_db=`ls -1 $OUTDIR/_db_stat_*.lck 2>/dev/null|wc -l`
   echo -n "."
   [ $slp_cnt -gt 60 ] && echo -n " spent 1 minute ... exiting ... " && break
   clean=0
   sleep 1
 done
 echo " $slp_cnt sec"
 locked=`ls -l $OUTDIR/_db_stat_*lck 2>/dev/null|awk '{print $NF}'|awk -F"_" '{print $NF}'|cut -d"." -f1|xargs echo`
 [ $clean -eq 1 ] && echo "DBs left locked:  $locked"
 rm -rf $OUTDIR/_db_stat*.lck
}


get_db_stats() {

 local lmt=10
 local batch=`echo "$DB_INFO_COUNT / $lmt" | bc -l | awk '{printf "%d", $0}'`
 local min_approx=`echo "$batch * 10 / 60" | bc -l| awk '{printf "%2.2f", $0}'`
 local max_approx=`echo "$batch * 25 / 60" | bc -l| awk '{printf "%2.2f", $0}'`
 echo ""
 echo "Collecting DB Statistics ( Estimate: $min_approx - $max_approx min ) ..."
 echo ""

 echo -n "" > $DB_STATS

 rm -rf $OUTDIR/_db_stat*.lck

 echo "Processing $DB_INFO_COUNT DBs (In batches of $lmt DB instances, No of Batches : $batch) "

 ### This will handle 15 DB instances at a time (parallel) to make it faster
 local sid_cnt=0
 cat "$DB_INFO" | while read line; do

   sid_cnt=$(( sid_cnt + 1 ))

   SID=`echo "$line" | awk  '{print $1}'`
   export ORACLE_HOME=`echo "$line" | awk  '{print $2}'`

   export LD_LIBRARY_PATH=$ORACLE_HOME/lib
   export PATH=$ORACLE_HOME/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
   export ORACLE_SID=$SID

   local query=`cat $0| awk '/^<--- BEGIN DB STATS -->/,/^<--- END DB STATS -->/ { print $0 }'| egrep -v "<--- BEGIN DB STATS -->|<--- END DB STATS -->"`

   ( 
     touch $OUTDIR/_db_stat_${SID}.lck
     sql_list "$SID" "$ORACLE_HOME" "$query"  | grep -v "APSDBCHECK"  > $OUTDIR/_db_stat_$SID.txt
     rm -rf $OUTDIR/_db_stat_${SID}.lck  2>/dev/null
   ) & 

   [ $? -ne 0 ] && continue

   [ $sid_cnt -gt $lmt ] && sleep_stats  "$batch" && batch=$(( batch -1 ))
   [ $sid_cnt -gt $lmt ] && sid_cnt=0

 done 

 ### Handle DB instances less than $lmt
 [ $sid_cnt -le $lmt ] && sleep_stats "(rest)"

 cat "$DB_INFO" | while read line; do
    SID=`echo "$line" | awk  '{print $1}'`
    cat $OUTDIR/_db_stat_$SID.txt >> $DB_STATS
    rm -rf "$OUTDIR/_db_stat_$SID.txt"
 done

 

echo ""

}

check_db_activity() {

 echo ""
 echo "Checking DB Activity (Taken from ASH in memory )..."
 echo ""

 local top_wait="$OUTDIR/_top_wait.txt"

 echo -n "" > $top_wait

 local found_running_db=`wc -l "$DB_INFO"| cut -d" " -f1`  # ps -eaf|grep ora_pmon|grep -v grep|wc -l`

 echo ""
 echo "Collecting 3hr Active sessions (from in-memory ASH ) "

 
 cat $DB_STATS | grep "^ASH " | grep -v "APSDBCHECK" | sed -e "s/^ASH //g" > $top_wait

 echo ""

 [ $found_running_db -eq 0 ] && echo "No DB instances running on this server `hostname -s` ... exiting " && exit 0

 local waittime=`cat "$top_wait" | grep -v "^$" |  awk '{ cnt+=$(NF-1) } END { print cnt }'`
 local cputime=`cat "$top_wait" |  grep -v "^$" | awk ' { cnt+=$NF } END { print cnt }'`
 local dbtime=$(( waittime + cputime ))
 local aas=`echo "$dbtime" | awk '{printf "%-10.2f", $0/10800}'`    # 3/24 - 3 hours (from querying DB_HIST_nnnnn)
 local cpu_aas=`echo "$cputime" | awk '{printf "%-.2f", $0/10800}'`    # 3/24 - 3 hours (from querying DB_HIST_nnnnn)
 local wait_aas=`echo "$waittime" | awk '{printf "%-.2f", $0/10800}'`    # 3/24 - 3 hours (from querying DB_HIST_nnnnn)
 local nodes=`wc -l /root/dbs_group| awk '{print $1}'`
 local cap=$(( CORE * nodes ))
 local cpu_avail=`echo "" | awk -v c="$cap" -v a="$cpu_aas" '{printf "%.2f", 100*(a/c) }'`    # 3/24 - 3 hours (from querying DB_HIST_nnnnn)
 unset POSIXLY_CORRECT
 
 if [ `echo "$aas <= 0" | bc` -eq 1 ]; then

  echo "Computation for Ave active session results to zero ...."
  return

 fi

 # 3/24 - 3 hours (from querying DB_HIST_nnnnn)
 echo ""
 echo "Average Active Session : $aas   [ DB Time = ${dbtime} sec, CPU Time = ${cputime} sec, Elapse (wall clock) =  10800 sec ]"  
 echo ""
 echo "Note: With $CORE core and $nodes nodes, you have a fix capacity of $cap sec at every moment (1 sec slice) of time."
 echo ""
 echo "Note: With Avg active session on CPU at ${cpu_aas}, that is ${cpu_avail} % avg. core utilization ..."
 echo ""
 echo "Note: Active wait is at ${waittime} sec  (  Average active session in active wait is at ${wait_aas} ) ..."

 echo ""
 echo "Listing DB Activity (Group by Event  - Taken from ASH in memory)"
 echo ""


 echo "" | awk ' { printf "%12s  %11s  %13s  %14s  %20s %-35s\n", "DB Time(sec)", "% DB time", "CPU Time(sec)", "Wait Time(sec)", "Wait Class", "Event" }'

 cat "$top_wait" | grep -v "^$" |   awk -F"~" '
  {
    split($NF,a," ");
    evt_event[$2,$5] = $2
    evt_wait_class[$2,$5] = $5
    evt_timewaited[$2,$5] += a[1]
    evt_waittime[$2,$5] += a[2]
    evt_cputime[$2,$5] += a[3]
    evt_dbtime[$2,$5] += ( a[2] + a[3] )
    cnt+=( a[2] + a[3] )
  }
  END {
    if ( cnt > 0 )
    for (i in evt_event) {
       pctload=100*evt_dbtime[i]/cnt
       if (evt_dbtime[i] > 0)
       printf "%12d  %11.1f  %13.1f  %14.1f  %20s  %-35s\n", evt_dbtime[i], pctload, evt_cputime[i], evt_waittime[i], evt_wait_class[i], evt_event[i] 
    }
  }
   ' | sort -rn -k1,1 


 echo ""
 echo "Listing DB Activity (Group by SQL  - Taken from ASH in memory)"
 echo ""

 echo "" | awk ' { printf "%12s  %11s  %13s  %14s  %20s  %-20s  %-40s\n", "DB Time(sec)", "% DB time",  "CPU Time(sec)", "Wait Time(sec)", "USER", "SQLID", "SQLTEXT" }'

 cat "$top_wait" | grep -v "^$" |  awk -F"~" '
   {
    split($NF,a," ");
    evt_sql_id[$3] = $3
    evt_sql_text[$3] = $4
    evt_sql_user[$3] = $6
    evt_timewaited[$3] += a[1]
    evt_waittime[$3] += a[2]
    evt_cputime[$3] += a[3]
    evt_dbtime[$3] += ( a[2] + a[3] )
    cnt+=( a[2] + a[3] )
  }
  END {
    if ( cnt > 0 )
    for (i in evt_sql_id) {
       pctload=100*evt_dbtime[i]/cnt
       if (evt_dbtime[i] > 0 )
       printf "%12d  %11.1f  %13.1f  %14.1f  %20s  %-20s  %-45.45s\n", evt_dbtime[i], pctload, evt_cputime[i], evt_waittime[i], evt_sql_user[i], evt_sql_id[i], evt_sql_text[i]
    }
  }
   '  | sort -rn -k1,1 | head -20




 echo ""
 echo "Listing DB Activity (Group by DBNAME - Taken from ASH in memory)"
 echo ""

 echo "" | awk ' { printf "%12s  %11s  %13s  %14s  %-35s\n", "DB Time(sec)", "% DB time", "CPU Time(sec)", "Wait Time(sec)",  "DBNAME" }'

 cat "$top_wait" | grep -v "^$" | awk -F"~" '
  {
    split($NF,a," ");
    evt_sid[$1]=$1
    evt_timewaited[$1] += a[1]
    evt_waittime[$1] += a[2]
    evt_cputime[$1] += a[3]
    evt_dbtime[$1] += ( a[2] + a[3] )
    cnt+=( a[2] + a[3] )
  }
  END {
    if ( cnt > 0 )
    for (i in evt_sid) {
       pctload=100*evt_dbtime[i]/cnt
       printf "%12d  %11.1f  %13.1f  %14.1f  %-35s\n",  evt_dbtime[i], pctload, evt_cputime[i], evt_waittime[i],  i 
    }
  }
  ' | sort -rn -k1,1 


  [ -f "${top_wait}" ] && rm -rf "${top_wait}"
  echo ""

}

check_db_hanganalyze() {

 echo ""
 echo "Checking DB Hang Chains ..."
 echo ""

  local db_hang=$OUTDIR/_db_hanganalyze.sh
  touch $db_hang

  [ ! -f "$db_hang" ] && echo "Not able to create DB HANGANALYZE script ..." && return 1

  cat $0 | awk '/^<--- BEGIN HANGANALYZE -->/,/^<--- END HANGANALYZE -->/ { print $0 }' |egrep -v "<--- BEGIN HANGANALYZE -->|<--- END HANGANALYZE -->" | sed "s@\$OUTDIR@${OUTDIR}@g" > $db_hang
  chmod 755 $db_hang

  $db_hang

}

get_ibsw_opensm() {

  local cfile="$OUTDIR/_os_ibswopensm_tmp.txt"

  echo "" > $cfile

  /usr/local/bin/dcli -l root -c "$IBSWITCH" \
     "tail -2000 /var/log/messages|egrep -i \"error |errored |fail |failed |restart |eviction |evicted |warn |critical |fatal |up |down |inactive |disconnect |stalling |stall \"|grep -v \"inactive_\"" | \
     awk '{$1="";  print}' > $IBSW_OPENSM

  cat "$IBSW_OPENSM" | sed -e "s/^[ ]*//g"  -e "s/ [ ]*/ /g" | while read line; do

   tday=`echo "$line" | awk '{print $1" "$2" "$3}'`

   epoc=`date --date "$tday" +"%s"`

   ndate=`date -d @$epoc +"%a %b %d %H:%M %Y" | sed -re "s/[0-9] (20[0-9][0-9])$/0 \1/g"`

   err=`echo $line | cut -d" " -f4-`

   echo "$ndate $err" >> $cfile

  done

  mv "$cfile" "$IBSW_OPENSM"

}


get_ibsw_os_alerts() {

  local cfile="$OUTDIR/_os_ibswtrc_tmp.txt"

  echo "" > $cfile

  /usr/local/bin/dcli -l root -c "$IBSWITCH" \
     "tail -2000 /var/log/messages|egrep -i \"error |errored |fail |failed |restart |eviction |evicted |warn |critical |fatal |up |down |inactive |disconnect |stalling |stall \"|grep -v \"inactive_\"" | \
     awk '{$1="";  print}' > $IBSW_OS_TRACE

  cat "$IBSW_OS_TRACE" | sed -e "s/^[ ]*//g"  -e "s/ [ ]*/ /g" | while read line; do

   tday=`echo "$line" | awk '{print $1" "$2" "$3}'`

   epoc=`date --date "$tday" +"%s"`

   ndate=`date -d @$epoc +"%a %b %d %H:%M %Y" | sed -re "s/[0-9] (20[0-9][0-9])$/0 \1/g"`

   err=`echo $line | cut -d" " -f4-`

   echo "$ndate $err" >> $cfile

  done

  mv "$cfile" "$IBSW_OS_TRACE"

}


get_os_alerts() {

  local cfile="$OUTDIR/_os_trc_tmp.txt"

  echo "" > $cfile

     tail -2000 /var/log/messages|egrep -i "error |errored |fail |failed |restart |eviction |evicted |warn |critical |fatal |up |down |inactive |disconnect |stalling |stall "|grep -v "inactive_" | \
     awk '{$1="";  print}' > $OS_TRACE

     tail -2000 /var/log/messages|egrep -i "error |errored |fail |failed |restart |eviction |evicted |warn |critical |fatal |up |down |inactive |disconnect |stalling |stall "|grep -v "inactive_" | \
     awk '{$1="";  print}' >> $OS_TRACE

  cat "$OS_TRACE" | sed -e "s/^[ ]*//g"  -e "s/ [ ]*/ /g" | while read line; do

   tday=`echo "$line" | awk '{print $1" "$2" "$3}'`

   epoc=`date --date "$tday" +"%s"`

   ndate=`date -d @$epoc +"%a %b %d %H:%M %Y" | sed -re "s/[0-9] (20[0-9][0-9])$/0 \1/g"`

   err=`echo $line | cut -d" " -f4-`

   echo "$ndate $err" >> $cfile

  done

  mv "$cfile" "$OS_TRACE"

}


get_cell_alerts() {

  local cfile="$OUTDIR/_cell_trc_tmp.txt"
 
  echo "" > $cfile

  /usr/local/bin/dcli -l root -g /root/cell_group "cellcli -e list alerthistory" | awk '{$1="";  print}' > $CELL_TRACE

  cat "$CELL_TRACE" | sed -e "s/^[ ]*//g"  -e "s/ [ ]*/ /g" | while read line; do

   tday=`echo $line | cut -d" " -f2|tr "T" " "`

   epoc=`date --date "$tday" +"%s"`

   ndate=`date -d @$epoc +"%a %b %d %H:%M %Y" | sed -re "s/[0-9] (20[0-9][0-9])$/0 \1/g"`

   err=`echo $line | cut -d" " -f4-`

   echo "$ndate $err" >> $cfile

  done
 
   mv "$cfile" "$CELL_TRACE"

}

get_asm_alerts() {

  local asm_alert=$OUTDIR/_asm_alert.sh

  touch $asm_alert

  [ ! -f "$asm_alert" ] && echo "Not able to create ASM ALERT script ..." && return 1

  cat $0 | awk '/^<--- BEGIN ASM ALERT -->/,/^<--- END ASM ALERT -->/ { print $0 }' |egrep -v "<--- BEGIN ASM ALERT -->|<--- END ASM ALERT -->" |  sed "s@\$OUTDIR@${OUTDIR}@g" > $asm_alert
  chmod 755 $asm_alert

  $asm_alert -d $OUTDIR | awk '{$1=""; print}' > $ASM_TRACE

}


get_db_alerts() {

  local db_alert=$OUTDIR/_db_alert.sh

  touch $db_alert

  [ ! -f "$db_alert" ] && echo "Not able to create DB ALERT script ..." && return 1

  cat $0 | awk '/^<--- BEGIN DB ALERT -->/,/^<--- END DB ALERT -->/ { print $0 }' |egrep -v "<--- BEGIN DB ALERT -->|<--- END DB ALERT -->" |  sed "s@\$OUTDIR@${OUTDIR}@g" > $db_alert
  chmod 755 $db_alert

  #/usr/local/bin/dcli -l root -g /root/dbs_group -f $db_alert -d /tmp 
  $db_alert -d $OUTDIR | awk '{$1=""; print}' > $DB_TRACE

}

get_crs_alerts() {

  local crs_alert=$OUTDIR/_crs_alert.sh

  touch $crs_alert

  [ ! -f "$crs_alert" ] && echo "Not able to create CRS ALERT script ..." && return 1

  cat $0 | awk '/^<--- BEGIN CRS ALERT -->/,/^<--- END CRS ALERT -->/ { print $0 }' |egrep -v "<--- BEGIN CRS ALERT -->|<--- END CRS ALERT -->" | sed "s@\$OUTDIR@${OUTDIR}@g" > $crs_alert
  chmod 755 $crs_alert

  $crs_alert -d $OUTDIR | awk '{$1=""; print}' > $CRS_TRACE

}


graph_errors() {

  local tfile="$1"
  local ttype="$2"
  local ctype="$3"

  epoc=`date +%s`


  local p=$( for h in `seq 1 120`;  do date -d @$epoc +"%a %b %d %H:%M %Y!"; epoc=$(( epoc - 60 )) ; done )

  local rep=`echo $p | sed -re "s/![ ]*/|^/g" | sed  -re "s/\|\^$//g"`


   epoc_tmp=$epoc

   timeline=""
   for h in `seq 1 12`;  do
     ttime=`date -d @$epoc +"%H:%M" | sed -re "s/[0-9]?$/0/g"`
     if [ -n "$ttype" -a "$ttype" = "CM" ]; then
      timeline=`echo "$timeline    $ttime"`;
     else
      timeline=`echo "$timeline  $ttime"`;
     fi
     epoc=$(( epoc - 600 ))
   done

  if [ -n "$ttype" -a "$ttype" = "CM" ]; then
     case "$ctype" in
      LRT) echo "Cell Metric - CD_IO_BY_R_LG_SEC (IO MB/sec) "; echo "" ;;
      LWT) echo "Cell Metric - CD_IO_BY_W_LG_SEC (IO MB/sec) "; echo "" ;;
      SRT) echo "Cell Metric - CD_IO_BY_R_SM_SEC (IO MB/sec) "; echo "" ;;
      SWT) echo "Cell Metric - CD_IO_BY_W_SM_SEC (IO MB/sec) "; echo "" ;;

      LRR) echo "Cell Metric - CD_IO_RQ_R_LG_SEC (IO/sec) "; echo "" ;;
      LWR) echo "Cell Metric - CD_IO_RQ_W_LG_SEC (IO/sec) "; echo "" ;;
      SRR) echo "Cell Metric - CD_IO_RQ_R_SM_SEC (IO/sec) "; echo "" ;;
      SWR) echo "Cell Metric - CD_IO_RQ_W_SM_SEC (IO/sec) "; echo "" ;;

      USM) echo "Cell Metric - DB_IO_UTIL_SM (%) "; echo "" ;;
      ULG) echo "Cell Metric - DB_IO_UTIL_LG (%) "; echo "" ;;
     esac
  fi

   if [ -n "$ttype" -a "$ttype" = "DB" ]; then
      echo "$timeline" | sed "s/^  //g" | awk '{ printf "%s  %-8.8s %-8.8s Log\n", $0, "First", "Last" }'
    else
       echo "$timeline  Log"  | sed "s/^  //g"
   fi

   epoc=$epoc_tmp

   cat $tfile | grep -v "^$" | egrep -v "\*\*\*\*\*" | awk -v tline="$timeline" -v db="$ttype" '
     BEGIN  {
       inst=""
       split(tline,hist, " ")
     }
     {
       cnt=$1; ttime=$5;
       $1=$2=$3=$4=$5=$6="";
     }
     {
       if (db ~ /DB/)  { inst=$7; $7="" }
       gsub(/^[ ]*/,"", $0)
       err_evt[$0]=$0
       err_last[$0]=inst
       if (db ~ /DB/)  { if (length(err_first[$0]) == 0 ) { err_first[$0]=inst } }
       err_cnt[$0,ttime] += cnt
     }
     END {
       found=0
       for (i in err_evt) {
         for (h=1;h<=12;h++) {
            cnt =  err_cnt[i,hist[h]]
            if ( err_cnt[i,hist[h]] == 0 ) cnt = "."; else found += cnt
             if (db ~ /CM/) printf("%7s  ", cnt  ); else printf("%5s  ", cnt)
         }
       if (db ~ /DB/)  { printf("%-8.8s %-8.8s %-80.80s\n", err_first[i], err_last[i], i) } else
                       { printf("%-80.80s\n", i) }
       }
        print ""
        if (db !~ /CM/ ) {
          if (found == 0 ) print "No errors found ... ok"; else print found" errors found ... fail"
        }
     }
   ' | sed -e "s/[ ]*$//g"

   echo ""

}

check_asm_db_alert() {

  local wtype="$1"
  local wtrace=""
  local tfile="$OUTDIR/_ora_trc1.txt"

  local sid=""
  local trclog=""

  echo ""
  echo -n "Checking $wtype Alerts "
 
  local inst_cnt=0

  [ "$wtype" = "DB"  ] && wtrace="$DB_TRACE" && get_db_alerts 
  [ "$wtype" = "ASM" ] && wtrace="$ASM_TRACE" && get_asm_alerts

  echo "(instances: $inst_cnt)"
  echo ""

  epoc=`date +%s`

  local p=$( for h in `seq 1 120`;  do date -d @$epoc +"%a %b %d %H:%M %Y!"; epoc=$(( epoc - 60 )) ; done )

  local rep=`echo $p | sed -re "s/![ ]*/|^/g" | sed  -re "s/\|\^$//g"`


  cat $wtrace |  sed -re "s/:[0-9][0-9] (20[0-9][0-9])$/ \1/g" | \
   awk -v m="$rep" '
    $2 ~ /^[ ]*(Sun|Mon|Tue|Wed|Thu|Fri|Sat)/ && $2" "$3" "$4" "$5" "$6 ~ m  {
        $1=""  
        d=gensub(/([0-9]?) (20[0-9][0-9])$/,"0 \\2", $0 )
        r=0; next
     }
    $2 ~ /^[ ]*(Sun|Mon|Tue|Wed|Thu|Fri|Sat)/ {  r=1 }
    r==0 {
        e=gensub(/^[ ]*/,"", $0 )
        print d" "e
     }
   ' 2>/dev/null|  sort |uniq -c >  $tfile


  graph_errors "$tfile" "DB"

  [ -f "$tfile" ] && rm -rf "$tfile"

}

check_crs_alert() {

  local tfile="$OUTDIR/_crs_trc1.txt"

  local sid=""
  local trclog=""

  echo ""
  echo -n "Checking CRS Alerts "

  local inst_cnt=0

  get_crs_alerts

  echo ""
  
  epoc=`date +%s`


  local p=$( for h in `seq 1 120`;  do date -d @$epoc +"%a %b %d %H:%M %Y!"; epoc=$(( epoc - 60 )) ; done )

  local rep=`echo $p | sed -re "s/![ ]*/|^/g" | sed  -re "s/\|\^$//g"`
  
  if [ "$GRID_VER" = "11g" ]; then

     cat $CRS_TRACE  | \
       awk -v m="$rep" '
       $1 ~  /^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)/ && $1" "$2" "$3" "$4" "$5 ~ m  { print $0 }
       ' | sort | uniq -c > $tfile

   elif [ "$GRID_VER" = "12c" ]; then

      cat $CRS_TRACE |  sed -re "s/:[0-9][0-9] (20[0-9][0-9])$/ \1/g" | \
        awk -v m="$rep" '
        $1 ~ /^[ ]*(Sun|Mon|Tue|Wed|Thu|Fri|Sat)/ && $1" "$2" "$3" "$4" "$5 ~ m  {
           d=gsub(/([0-9]?) (20[0-9][0-9])$/,"0 \\2", $0 );
           r=0; next
         }
        $1 ~ /^[ ]*(Sun|Mon|Tue|Wed|Thu|Fri|Sat)/ {  r=1 }
         r==0 {
           e=gsub(/^[ ]*/,"", $0 );
           print d" "e
         }
       ' |  sort |uniq -c > $tfile

   fi

   graph_errors "$tfile"

   [ -f "$tfile" ] && rm -rf "$tfile"


}


check_cell_alert() {

  local tfile="$OUTDIR/_cell_trc1.txt"

  local sid=""
  local trclog=""

  echo ""
  echo -n "Checking CELL Alerts "

  local inst_cnt=0

  get_cell_alerts

  echo ""

  epoc=`date +%s`


  local p=$( for h in `seq 1 120`;  do date -d @$epoc +"%a %b %d %H:%M %Y!"; epoc=$(( epoc - 60 )) ; done )

  local rep=`echo $p | sed -re "s/![ ]*/|^/g" | sed  -re "s/\|\^$//g"`


  cat $CELL_TRACE  | \
   awk -v m="$rep" '
    $1 ~  /^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)/ && $1" "$2" "$3" "$4" "$5 ~ m  { print $0 } 
   ' | sort | uniq -c > $tfile

   graph_errors "$tfile"

   [ -f "$tfile" ] && rm -rf "$tfile"

}

check_os_alert() {

  local tfile="$OUTDIR/_os_trc1.txt"

  local sid=""
  local trclog=""

  echo ""
  echo -n "Checking DB & Cell OS Alerts "

  local inst_cnt=0

  get_os_alerts

  echo ""

  epoc=`date +%s`


  local p=$( for h in `seq 1 120`;  do date -d @$epoc +"%a %b %d %H:%M %Y!"; epoc=$(( epoc - 60 )) ; done )

  local rep=`echo $p | sed -re "s/![ ]*/|^/g" | sed  -re "s/\|\^$//g"`


  cat $OS_TRACE  | \
   awk -v m="$rep" '
    $1 ~  /^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)/ && $1" "$2" "$3" "$4" "$5 ~ m  { print $0 }
   ' | sort | uniq -c > $tfile

   graph_errors "$tfile"

   [ -f "$tfile" ] && rm -rf "$tfile"

}

check_ibsw_equivalence() {

    check_ssh "$1"
    res=$?
    if [ $res -eq 0 ]; then
      echo "Node" "$h is reachable by SSH ... " $pass
      return 0
    elif [ $res -eq 1 ]; then
      echo "Node" "$h is not reachable by SSH however, unable to run a test (e.g. test -d /root ) ... " $fail
      return -1
    else
      echo "Node" "$h is not reachable by SSH ... " $fail
      return -1
    fi

}

check_ibsw_alert() {

 [ ! -n "$IBSWITCH" ] && echo "Not able to SSH to IB switches due to absence of user equivalence ..." && return 

  local tfile="$OUTDIR/_ibsw_os_trc1.txt"

  local sid=""
  local trclog=""

  echo ""
  echo -n "Checking IBSW OS Alerts "

  local inst_cnt=0

  get_ibsw_os_alerts

  echo ""

  epoc=`date +%s`


  local p=$( for h in `seq 1 120`;  do date -d @$epoc +"%a %b %d %H:%M %Y!"; epoc=$(( epoc - 60 )) ; done )

  local rep=`echo $p | sed -re "s/![ ]*/|^/g" | sed  -re "s/\|\^$//g"`


  cat $IBSW_OS_TRACE  | \
   awk -v m="$rep" '
    $1 ~  /^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)/ && $1" "$2" "$3" "$4" "$5 ~ m  { print $0 }
   ' | sort | uniq -c > $tfile

   graph_errors "$tfile"

   [ -f "$tfile" ] && rm -rf "$tfile"

 
}

check_ibsw_opensm() {

 [ ! -n "$IBSWITCH" ] && echo "Not able to SSH to IB switches due to absence of user equivalence ..." && return 


  local tfile="$OUTDIR/_ibsw_opensm_trc1.txt"

  local sid=""
  local trclog=""

  echo ""
  echo -n "Checking IBSW OpenSM log "

  local inst_cnt=0

  get_ibsw_opensm

  echo ""

  epoc=`date +%s`


  local p=$( for h in `seq 1 120`;  do date -d @$epoc +"%a %b %d %H:%M %Y!"; epoc=$(( epoc - 60 )) ; done )

  local rep=`echo $p | sed -re "s/![ ]*/|^/g" | sed  -re "s/\|\^$//g"`


  cat $IBSW_OPENSM  | \
   awk -v m="$rep" '
    $1 ~  /^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)/ && $1" "$2" "$3" "$4" "$5 ~ m  { print $0 }
   ' | sort | uniq -c > $tfile

   graph_errors "$tfile"

   [ -f "$tfile" ] && rm -rf "$tfile"



}

get_param_interconnect() {

  local sid="$1"
 
  local paramlist=`grep "^cluster_interconnects" $OUTDIR/${sid}_params`
  local val=`echo "$paramlist" |  awk -F"@" '{print $2}'`

  echo "$val"
}


check_db_configuration() {

 local ipclist=""
 local ipclist=`/sbin/ip addr show|grep "inet"|egrep  "^bondib|ib"|grep -v "169.254"|awk '{print $2}'|cut -d"/" -f1`
 local -a ip_carr=()
 local ip_parr=""
 local ipflist="$OUTDIR/_interconnect_list.txt"
 local typeset int acnt=0
 local typeset int icnt=0

 $CRS_HOME/bin/srvctl config db -v > $OUTDIR/dbconfig_all_$$

 rm -rf "${ipflist}"

 ip_carr=($ipclist)

 echo ""
 echo "Checking DB Configurations ..."
 echo ""

 icnt=`grep "wc -l $DB_INFO| cut -d" " -f1`  # ps -eaf|grep ora_pmon | grep -v grep|wc -l`

 cat "$DB_INFO" | while read line; do
 #ps -eaf|grep ora_pmon | grep -v grep | while read line; do

   #SID=`echo "$line" | awk -F"_" '{print $NF}'`
   #export ORACLE_HOME=`echo "$line" | awk '{print $2}'| xargs pwdx | sed -e "s/\/dbs$//g"|cut -d":" -f2|sed -e "s/ //g"`

   SID=`echo "$line" | awk  '{print $1}'`
   export ORACLE_HOME=`echo "$line" | awk  '{print $2}'`

   export LD_LIBRARY_PATH=$ORACLE_HOME/lib
   export PATH=$ORACLE_HOME/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
   export ORACLE_SID=$SID

   sql_params "DB" "$SID" "$ORACLE_HOME"
   echo ""
   sql_db_check "$SID" "$ORACLE_HOME"
   
   ipclist=$(get_param_interconnect "$SID")

   echo "$ipclist" >> $ipflist

   rm -rf $OUTDIR/${SID}_params

done  

   echo
   echo "[DB]: the configuration summary of cluster_interconnects:"
   ip_parr=`cat "${ipflist}"`
   for i in "${ip_carr[@]}"; do
     acnt=`echo "${ip_parr}" | egrep -co "${i}"`
     [ $icnt -eq $acnt ] && msg "DB" "Instances configured with interconnect IP  $i : $acnt" $pass
     [ $icnt -ne $acnt ] && msg "DB" "Instances configured with interconnect IP  $i : $acnt (Expected: $icnt)" $fail
   done
   echo

   [ -f "${ipflist}" ] && rm -rf "$ipflist"

}




check_kfod() {
 local CRS_BIN=`ps -eaf|grep ocssd.bin|grep -v grep|awk '{print $NF}'|sed -e "s/ocssd\.bin//g"`

 echo ""
 echo "Checking KFOD to Cell discovery ..."
 echo ""


 [ -n "$CRS_BIN" -a -d "$CRS_BIN" ] && $CRS_BIN/kfod disks=all|  awk '{print $4}'|grep "o\/"|awk -F"/" '{print $NF}' |awk -F"_" '{ print $1" "$NF}'|sort|uniq -c| awk '{ x[$3]=x[$3]" "$1" "$2 }
     END {
       for (i in x) {
         print i" "x[i]
       }
     }
  '| while read line; do
 
   [ `echo "$line"|egrep -o " 12 DATA| 12 RECO| 12 FRA| 10 DBFS| 12 DBFS"|wc -l` -eq 3 ] && msg "CELL" "Checking KFOD ... $line" $pass
   [ `echo "$line"|egrep -o " 12 DATA| 12 RECO| 12 FRA| 10 DBFS| 12 DBFS"|wc -l` -ne 3 ] && msg "CELL" "Checking KFOD ... $line" $warning

  done

}

check_rds_port_limit() {
   rds=`rds-info 2>&1|egrep -v "Protocol not available" | awk '/RDS Sockets:/,/RDS Connections:/ { print $1 }'|sort|uniq -c| awk '$1>20 { print $0}'`

 echo ""
 echo "Checking RDS port limit ..."
 echo ""

 echo "$rds" | while read line
 do
  typeset int cnt=`echo $line | awk '{ print $1}'`
  ip=`echo $line | awk '{ print $2}'`
 
  # limit is 65536
  [ $cnt -ge 65000 ] && msg "RDS" "Check RDS port limit ($ip)  $cnt ~ close to 65k " $fail
  [ $cnt -gt 40000 ] && msg "RDS" "Check RDS port limit ($ip)  $cnt ~ close to 40k " $warning
  [ $cnt -le 40000 ] && msg "RDS" "Check RDS port limit ($ip)  [ Port count: $cnt ] " $pass
 done

}

check_rds_ping() {

  echo ""
  echo "Checking RDS latency (should be two digit ) ..."
  echo ""

  local rds_ping=$OUTDIR/_rds_ping.sh
  touch $rds_ping

  [ ! -f "$rds_ping" ] && echo "Not able to create RDS PING script ..." && return 1

  cat $0 | awk '/^<--- BEGIN RDS PING -->/,/^<--- END RDS PING -->/ { print $0 }' |egrep -v "<--- BEGIN RDS PING -->|<--- END RDS PING -->" > $rds_ping
  chmod 755 $rds_ping

  $rds_ping

}


check_eth_link() {

 local OK=1
 local ethlinks="$1"
 local ethhost="$2"

 echo "$ethlinks" | while read ethlink; do

 eth_dev=`echo $ethlink | awk '{print $1}'`
 eth_state=`echo $ethlink | awk '{print $2}'`

 [ -n "$eth_state" -a "$eth_state" != "1" ] && OK=0

 [ $OK -eq 1 ] && msg "ETH" "$ethhost $eth_dev carrier=$eth_state" $pass
 [ $OK -eq 0 ] && msg "ETH" "$ethhost $eth_dev carrier=$eth_state" $fail

 done

}

check_eth_dev() {

  local _dev=""
  local eth_dev=$OUTDIR/_eth_dev.sh
  touch $eth_dev


  [ ! -f "$eth_dev" ] && echo "Not able to create ETH DEV script ..." && return 1

  cat $0 | awk '/^<--- BEGIN ETHDEV -->/,/^<--- END ETHDEV -->/ { print $0 }' |egrep -v "<--- BEGIN ETHDEV -->|<--- END ETHDEV -->" > $eth_dev
  chmod 755 $eth_dev

  $eth_dev | awk '
  /IFACE/ {
       printf("%15s  %8s  %8s  %8s  %8s  %8s  %8s  %8s  %8s  %8s  %25s\n",
             "IFACE", "rxerr/s", "txerr/s", "coll/s", "rxdrop/s", "txdrop/s", "txcarr/s", "rxfram/s", "rxfifo/s", "txfifo/s", "code");
  }
  !/IFACE/ {
     N=$13; M=""
     if ( N == 1 || N == 2 ) { M = "ok" }
     if ( N == 3 || N == 4 || N == 5 || N == 6 ) { M = "ignore" }
     if ( N== 7 ||  N == 8 ) {  M = "fail" }
     if ( N== 9 ||  N ==10 || N == 12 ) { M = "ignore(possibly not cabled)" }
     if ( N== 11 ) {  M = "warning(possibly misconfigured)" }

     printf(" %15s  %8.2f  %8.2f  %8.2f  %8.2f  %8.2f  %8.2f  %8.2f  %8.2f  %8.2f  %20s %1s %2d %-10s\n",$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, M);
  }
  '


  #[ -f "$eth_dev" ] && rm -rf $eth_dev

}



check_ib_dev() {

  local _dev=""
  local ib_dev=$OUTDIR/_ib_dev.sh
  touch $ib_dev

  echo ""
  echo "Checking IB link ..."
  echo ""


  [ ! -f "$ib_dev" ] && echo "Not able to create IB DEV script ..." && return 1

  cat $0 | awk '/^<--- BEGIN IBDEV -->/,/^<--- END IBDEV -->/ { print $0 }' |egrep -v "<--- BEGIN IBDEV -->|<--- END IBDEV -->" > $ib_dev
  chmod 755 $ib_dev

  $ib_dev  -d $OUTDIR
  /usr/local/bin/dcli -l root -g /root/cell_group -x $ib_dev  -d $OUTDIR


}


check_arp_addr() {

 local RDS_I="$1"
 local iparps="$2"
 local iphost="$3"
 local macaddr=""
 local ipaddr=""

  echo ""
  echo "Checking RDS HWAddr ..."
  echo ""

  echo "$iparps" | while read iparp; do

  macaddr=`echo "$iparp"| cut -d"/" -f2`
  ipaddr=`echo "$iparp"| cut -d"/" -f1`

   [ `echo $RDS_I | grep -c "$iparp"`  -gt 0 ] && msg "RDS" "MAC registration: $ipaddr $macaddr from $iphost" $pass
   [ `echo $RDS_I | grep -c "$iparp"`  -eq 0 ] && msg "RDS" "MAC registration: $ipaddr $macaddr from $iphost" $fail

 done


}

check_ib_hwaddr() {

  local ib_dev=$OUTDIR/_ib_addr.sh
  touch $ib_dev

  [ ! -f "$ib_dev" ] && echo "Not able to create IB DEV script ..." && return 1

  cat $0 | awk '/^<--- BEGIN HWADDR -->/,/^<--- END HWADDR -->/ { print $0 }' |egrep -v "<--- BEGIN HWADDR -->|<--- END HWADDR -->" |  sed "s@\$OUTDIR@${OUTDIR}@g" > $ib_dev
  chmod 755 $ib_dev

  $ib_dev -d $OUTDIR
  /usr/local/bin/dcli -l root -g /root/cell_group -x $ib_dev  -d $OUTDIR

}

check_rds_addr() {

  local rds_mac="$1"
  rds-info -I | egrep -iv "Remote|Connection" > $rds_mac
  dcli -l root -g /root/cell_group "rds-info -I" | egrep -iv "Remote|Connection" >> $rds_mac

}


check_ib_addr() {

 local ib_addr=$OUTDIR/_ib_addr.txt

 local rds_mac=$OUTDIR/_rds_mac.txt

 # Get all MAC ADDR of all DB and Cell nodes
 check_ib_hwaddr | grep -v "Checking" > $ib_addr

 # Get all rds-info connections
 check_rds_addr $rds_mac


 # Now begin to compare
 echo ""
 echo "Checking IB Connectivity (ARP/MAC) ... "

 echo ""
 echo "" | awk '
   {
     printf("%-20s  %15s  %15s  %3s %3s    %25s  %25s\n", "Hostname", "LocalAddr","RemoteAddr","Tos","SL","LocalDev","RemoteDev" )
   }
 '

 awk '
   BEGIN { fnd=0 }
   FNR==NR {
     if ($0 !~ /Checking/) ib_addr[$2]=$3
     next
   }
   $2 !~ /169.254/ && ib_addr[$2] != $6 {
    
     comment="(local  = "ib_addr[$2]") ... fail"
     printf("%-20s  %15s  %15s  %3s %3s    %25s  %25s %-35s\n", $1, $2, $3, $4, $5, $6, $7, comment )
     fnd+=1
   }
   $3 !~ /169.254/ && ib_addr[$3] != $7 {
     comment="(remote = "ib_addr[$3]") ... fail"
     printf("%-20s  %15s  %15s  %3s %3s    %25s  %25s %-35s\n", $1, $2, $3, $4, $5, $6, $7, comment )
     fnd+=1
   }
   END {
    if (fnd == 0 ) print "RDS: No HW MAC Address mismatch ... ok"
    if (fnd > 0 ) print "RDS: HW MAC address "fnd" mismatch ( Use rds-stress -r <local> -s <remote> -Q <Tos> --reset)  ... fail "
   }

 ' $ib_addr $rds_mac

 [ -f "$ib_addr" ] && rm -rf $ib_addr
 [ -f "$rds_mac" ] && rm -rf $rds_mac

}


check_rds_mac() {

  local _dev=""
  local ib_dev=$OUTDIR/_rds_mac.sh
  touch $ib_dev



  [ ! -f "$ib_dev" ] && echo "Not able to create RDS MAC script ..." && return 1

  cat $0 | awk '/^<--- BEGIN RDS MAC -->/,/^<--- END RDS MAC -->/ { print $0 }' |egrep -v "<--- BEGIN RDS MAC -->|<--- END RDS MAC -->" > $ib_dev
  chmod 755 $ib_dev

  for h in `cat /root/dbs_group`; do
    scp -q $ib_dev $h:$OUTDIR
    iblink=`ssh $h "$ib_dev" 2>&1`
    echo "$iblink"
  #  check_arp_addr "$RDS_I" "$iblink" "$h"
  done

  for h in `echo "$CELL_LIST"`; do
    scp -q $ib_dev $h:$OUTDIR
    iblink=`ssh $h "$ib_dev" 2>&1`
    echo "$iblink"
  #  check_arp_addr "$RDS_I" "$iblink" "$h"
  done

}



check_switch_query_errors() {
 local loc="$1"
 $IBQUERYERRORS -s PortXmitWait,PortRcvData,PortXmitPkts,PortRcvPkts 2>/dev/null | egrep -A32 "^Errors" | grep -A36 "QDR" | awk '
 /^Errors/ { p=$8 }
 /^[ ]*GUID/ { print p" "$0 }
' | grep ALL > $loc

}

check_node_query_errors() {
 local loc="$1"

 $IBQUERYERRORS -rR -s PortXmitWait,PortRcvData,PortXmitPkts,PortRcvPkts 2>/dev/null| egrep -A2 "^Errors" | grep -A2 "HCA" | \
  sed -re "s/(\[  \] ==\(|\( \)$|\[  \] \"|\")/ /g" | \
  awk '
 /^Errors/ { p=$5 }
 /^[ ]*GUID/ { e=$0 }
 /^[ ]*Link info:/  {print  p" "e" [PEER == "$3":"$4":"$(NF-7)":"$(NF-6)":"$(NF-1)":"$NF"]" }

 ' > $loc


}

report_rds_query_error() {

 local squeryf="$1"

 local COUNTERS=`echo SWRE:PortRcvSwitchRelayErrors LNKE:LinkErrorRecoveryCounter SYMB:SymbolErrorCounter \
                VL15:VL15Dropped RCVE:PortRcvErrors PHYE:PortRcvRemotePhysicalErrors XMTD:PortXmitDiscards \
                XMTE:PortXmitConstraintErrors INTE:LocalLinkIntegrityErrors EBUF:ExcessiveBufferOverrunErrors PEER:PEER`

  local EFOUND=0

 echo ""
 printf "%35s  %35s  %35s\n" "PortRcvSwitchRelayErrors (SWRE)" "LinkErrorRecoveryCounter (LNKE)" "SymbolErrorCounter (SYMB)"
 printf "%35s  %35s  %35s\n" "VL15Dropped (VL15)" "PortRcvErrors (RCVE)" "PortRcvRemotePhysicalErrors (PHYE)"
 printf "%35s  %35s  %35s\n" "PortXmitDiscards (XMTD)" "PortXmitConstraintErrors (XMTE)" "LocalLinkIntegrityErrors (INTE)"
 printf "%35s  %35s  %35s\n" "ExcessiveBufferOverrunErrors (EBUF)" "" ""

 echo ""
 echo ""

 printf "%-20s  %-5s  %-5s  %5s  %5s %5s  %5s  %5s  %5s  %5s  %5s  %5s  %5s  %5s %10s\n" \
       "HOST" "LID" "PORT" "SWRE" "LNKE" "SYMB" "VL15" "RCVE" "PHYE" "XMTD" "XMTE" "INTE" "EBUF"  "PEER"

 cat $squeryf | while read line; do

  HOST=`echo "$line"| awk '{print $2}'`
  GUID=`echo "$line"| awk '{print $4}'`
  PORT=`echo "$line"| awk '{print $6}'|sed -e "s/://g"`

  SWRE="."
  LNKE="."
  SYMB="."
  VL15="."
  RCVE="."
  PHYE="."
  XMTD="."
  XMTE="."
  INTE="."
  EBUF="."
  PEER="."
  L_LID=""
  R_LID=""
  L_PORT=""
  R_PORT=""
  R_HOST=""

  EFOUND=1


 for cntr in `echo "$COUNTERS"`; do

 sym=`echo $cntr|cut -d":" -f1`
  h=`echo $cntr|cut -d":" -f2`

  CNT=`echo "$line" |egrep -co "\[$h == [0-9]+\]"`
  CNTR=`echo "$line" |egrep -o "\[$h == [0-9]+\]" | sed -e "s/\]//g" | egrep -o "[0-9]+$"`
  P=`echo "$line" |egrep -o "\[$h == [.0-9:a-zA-Z-]+]" | sed -e "s/\]//g" | egrep -o "[.0-9:a-zA-Z-]+$"`

  [ $CNT -gt 0 -a "$h" = "PortRcvSwitchRelayErrors" ] && SWRE=$CNTR
  [ $CNT -gt 0 -a "$h" = "LinkErrorRecoveryCounter" ] && LNKE=$CNTR
  [ $CNT -gt 0 -a "$h" = "SymbolErrorCounter" ] && SYMB=$CNTR
  [ $CNT -gt 0 -a "$h" = "VL15Dropped" ] && VL15=$CNTR
  [ $CNT -gt 0 -a "$h" = "PortRcvErrors" ] && RCVE=$CNTR
  [ $CNT -gt 0 -a "$h" = "PortRcvRemotePhysicalErrors" ] && PHYE=$CNTR
  [ $CNT -gt 0 -a "$h" = "PortXmitDiscards" ] && XMTD=$CNTR
  [ $CNT -gt 0 -a "$h" = "PortXmitConstraintErrors" ] && XMTE=$CNTR
  [ $CNT -gt 0 -a "$h" = "LocalLinkIntegrityErrors" ] && INTE=$CNTR
  [ $CNT -gt 0 -a "$h" = "ExcessiveBufferOverrunErrors" ] && EBUF=$CNTR
  [ "$h" = "PEER" ] && PEER=$P

 done

  [ -n "$P" -a "$PEER" != "." ] && L_LID=`echo "$PEER" | awk -F":" '{ print $1}'`
  [ -n "$P" -a "$PEER" != "." ] && L_PORT=`echo "$PEER" | awk -F":" '{ print $2}'`
  [ -n "$P" -a "$PEER" != "." ] && R_LID=`echo "$PEER" | awk -F":" '{ print "LID("$3")"}'`
  [ -n "$P" -a "$PEER" != "." ] && R_PORT=`echo "$PEER" | awk -F":" '{ print "PORT("$4")"}'`
  [ -n "$P" -a "$PEER" != "." ] && R_HOST=`echo "$PEER" | awk -F":" '{ print $5}'`
  printf "%-20s  %-5s  %-5s  %5s  %5s %5s  %5s  %5s  %5s  %5s  %5s  %5s  %5s  %5s %10s\n" \
    "$HOST" "$L_LID" "$PORT" "$SWRE" "$LNKE" "$SYMB" "$VL15" "$RCVE" "$PHYE" "$XMTD" "$XME" "$INTE" "$EBUF" "$R_HOST $R_LID $R_PORT"

 done

  [ $EFOUND -eq 0 ] && 
  printf "%-20s  %-5s  %-5s  %5s  %5s %5s  %5s  %5s  %5s  %5s  %5s  %5s  %5s  %5s %10s\n" \
    "NONE" "." "." "." "." "." "." "." "." "." "." "." "." "." $pass && \
   msg "RDS" "No RDS Counter or Errors increases ..." $pass


}

check_clear_counters() {

 echo -n "Clearing Errors ..."
 /usr/sbin/ibclearerrors 2>&1 > /dev/null
 echo "done"
 echo -n "Clearing Counters ..."
 /usr/sbin/ibclearcounters 2>&1 > /dev/null
  echo "done"

}

check_ib_query_initial() {

 check_switch_query_errors "$OUTDIR/_rds_squery_1.log"
 check_node_query_errors "$OUTDIR/_rds_nquery_1.log"

 IB_DATE=`date`

}

check_ib_query_final() {

  local sdate=""
  local squeryf="$OUTDIR/_rds_query_result.log"

  echo ""
  echo "Checking RDS Errors (Sleeping 10 seconds) ..."
  echo ""

  sleep 10

  sdate=`date`
  local s_epoc=`date --date "$IB_DATE" +"%s"`
  local e_epoc=`date --date "$sdate" +"%s"`
  local sdelta=$((  e_epoc - s_epoc   ))
 
 

  echo "Collecting switch errors (final run) ..."
  check_switch_query_errors "$OUTDIR/_rds_squery_2.log"
  echo "Collecting node errors (final run) ..."
  check_node_query_errors "$OUTDIR/_rds_nquery_2.log"

  echo "Duration: $sdelta sec" 


  diff "$OUTDIR/_rds_squery_1.log" "$OUTDIR/_rds_squery_2.log" |grep GUID| cut -d">" -f2 | cut -d"<" -f2| sort -k2,2|uniq -c| awk '$1 == 1 { print $0}' > $squeryf
  diff "$OUTDIR/_rds_nquery_1.log" "$OUTDIR/_rds_nquery_2.log" |grep GUID| cut -d">" -f2 | cut -d"<" -f2| sort -k2,2|uniq -c| awk '$1 == 1 { print $0}' >> $squeryf

  report_rds_query_error "$squeryf"

  check_summary_query_errors

  rm -rf $OUTDIR/_rds_squery* $OUTDIR/_rds_nquery* $OUTDIR/_rds_query*

}



check_summary_query_errors() {
 local loc="$1"

 local OK=1
 $IBQUERYERRORS -rR -s PortXmitWait,PortRcvData,PortXmitPkts,PortRcvPkts | egrep -A1 "^## Summary:" | sed -e "s/##//g" | while read line; do

  [ `echo "$line" | egrep -c "bad nodes found"` -eq 1 -a `echo "$line" | awk '$(NF-3) > 0 { print "NOTGOOD" }'` = "NOTGOOD"  ] && OK=0

  [ $OK -eq 0 ] && msg "RDS" "$line" $warning
  [ $OK -eq 1 ] && msg "RDS" "$line" $pass

 done


}

check_ibsw_linkerr() {

  echo ""
  echo "Checking ListLinkUp Errors  ..."
  echo ""

 [ ! -n "$IBSWITCH" ] && echo "Not able to SSH to IB switches due to absence of user equivalence ..." && return

 /usr/local/bin/dcli -l root -c "$IBSWITCH" "listlinkup|grep Error" | while read line; do
    msg "IBSW" "$line" $fail
 done

}

check_ibsw_env_test() {

  echo ""
  echo "Checking Environment Test  ..."
  echo ""

 [ ! -n "$IBSWITCH" ] && echo "Not able to SSH to IB switches due to absence of user equivalence ..." && return

 /usr/local/bin/dcli -l root -c "$IBSWITCH" "env_test|grep -i 'Environment test'|grep -iv 'started'" | while read line; do
    res=`echo "$line" | grep -ic "passed"`
    [ $res -gt 0 ] && msg "IBSW" "$line" $pass
    [ $res -eq 0 ] && msg "IBSW" "$line  (Run env_test to validate ... ) " $fail
 done


}


check_ibsw_priority_master() {

  echo ""
  echo "Checking SM Priority and SM master  ..."
  echo ""

 [ ! -n "$IBSWITCH" ] && echo "Not able to SSH to IB switches due to absence of user equivalence ..." && return

 /usr/local/bin/dcli -l root -c "$IBSWITCH" "getmaster; setsmpriority list" 

}


do_node_check() {

 
  return;
  echo "-----------------------------------------------"
  echo "Nodes : Start checking ..."
  get_nodes
  echo ""
  echo "Nodes : Done checking ..."

}

do_os_check() {


  echo "-----------------------------------------------"
  echo "OS : Start checking ..."

  # get wchan
  check_os_wchan

  # get threshold
  check_os_threshold

  # get load
  check_os_load


  # check os
  if [ "$PLATFORM" == "sparc" ]; then
   check_sparc_os_status
  else
   check_os_status "OS" "/root/dbs_group"
  fi

  # Checking Ethernet
  echo ""
  echo "Checking Client Ethernet Link ..."
  echo ""
  echo "code: 1 = ok                                 2 = notconfigured,healthy(possibly vip)   3 = ignore                           4 = ignore"
  echo "      5 = ignore                             6 = ignore                                7 = configured/no power/no carrier   8 = not configured/unhealthy"
  echo "      9 = ignore                            10 = ignore                               11 = configured/no power/no carrier   12 = not in use"
  echo ""

  check_eth_dev
  echo ""

  # checking HW failure
  #echo ""
  #echo "Checking HW failures  ..."
  #check_db_hw_fault

  # get filesystem ussage
  echo "Checking Filesystems ..."
  check_os_filesystem

  if [ "$PLATFORM" != "sparc" ]; then
   check_os_setting
  fi

  # Check Alerts
  check_os_alert

  echo "OS : Done checking ..."
  #echo "-----------------------------------------------"


}



do_crs_check() {
  echo "-----------------------------------------------"
  echo "CRS: Start checking ..."

  # set asm environment
  env_asm

  # check status of crs
  check_crs_status

  # check CHM Repository Size
  # check_crs_chmrep_status

  # check alerts
  check_crs_alert
 
  echo "CRS: Done checking ..."
  #echo "-----------------------------------------------"
}

do_asm_check() {
  echo "-----------------------------------------------"
  echo "ASM: Start checking ..."
 
  # check if asm pmon is running
  check_asm_pmon

  # set asm environment
  env_asm

  if [[ $CRS_HOME =~ "11.2.0.3" ]]
  then
    echo "It's 11.2.0.3 version, skip ASM check." && return
  elif [[ $CRS_HOME =~ "11.2.0.4" ]]
  then
    # capture asm parameters
    sql_params  "ASM" "${ASM_PMON}" "${CRS_HOME}"

    sql_asm_check
  fi
  
  rm -rf $OUTDIR/${ASM_PMON}_params

  check_asm_diskgroup
  check_asm_hanganalyze
  check_asm_db_alert "ASM"

  echo "ASM: Done checking ..."
  #echo "-----------------------------------------------"


}


do_db_check() {
  echo "-----------------------------------------------"
  echo "DB: Start checking ..."

  check_db_info
  get_db_stats
  check_db_activity
  check_system_event
  #check_sql_monitor
  #check_sql_stat
  #check_db_hanganalyze
  #check_asm_db_alert "DB"
  [ $DB_CHECK_CONFIG -eq 1 ] && check_db_configuration

  echo "DB: Done checking ..."
  #echo "-----------------------------------------------"
  echo ""

}

do_tns_check() {
  echo "-----------------------------------------------"
  echo "TNS: Start checking ..."

  # set asm environment
  env_asm

  check_tns_status

  echo "TNS: Done checking ..."
  #echo "-----------------------------------------------"
  echo ""


}


do_rds_check() {
  echo "-----------------------------------------------"
  echo "RDS: Start checking ..."

  check_rds_port_limit
  check_rds_ping
  check_ib_dev
  check_ib_addr
  check_ib_query_final

  echo ""
  echo "RDS: Done checking ..."
  #echo "-----------------------------------------------"
  echo ""

}

do_cell_check() {
  echo "-----------------------------------------------"
  echo "CELL: Start checking ..."

  check_os_status "CELL: OS" "/root/cell_group"
  check_cell_status
  check_cell_iostat
  check_cell_metric
  check_cell_hw_fault
  check_cell_alert
  check_kfod
  check_cell_lun_status
  check_cell_griddisk_active

  echo "CELL: Done checking ..."
  #echo "-----------------------------------------------"
  echo ""

}

do_ibsw_check() {
  echo ""
  echo "-----------------------------------------------"
  echo "IBSW: Start checking ..."

  # Check Environment Test
  check_ibsw_env_test

  # Check Alerts
  check_ibsw_alert

  # Check Open SM
  check_ibsw_opensm

  # Check LinkError
  check_ibsw_linkerr

  # Check SM Priority and SM Master
  check_ibsw_priority_master

  echo ""
  echo "IBSW: Done Error checking ..."
  #echo "-----------------------------------------------"
  echo ""

}


usage() {

  echo "Version: 2015/01/19"
  echo "Note: This script needs to be run as root. It will only check state of components in the  node."
  echo "      You have to run the script to other cluster nodes..."
  echo ""
  echo "Usage:  $0 -g <grid_home> -o <db_home> -l <sid_list_file> [-s] [-c]"
  echo ""
  echo "where: -s <-- skip (os,rds,cell,ibsw,asm,db,tns) comma delimited"
  echo "       -c <-- check only the following (os,rds,cell,ibsw,asm,db,tns) comma delimited. This over-rides -s"
  echo "       -f <-- Summary of failures only"
  echo "       -l <-- specify a file including sid list following the format: [sid]"
  echo "       -v <-- validate CLOUD SAAS standard configuration"
  echo "       -d <-- Include DB configuration checks"
  echo ""
  exit
}

while getopts "g:o:l:s:c:fhvd" OPT
 do
   case $OPT in
    d) DB_CHECK_CONFIG=1
      ;;
    g)
      CRS_HOME=$OPTARG
      ;;
    o)
      OH_HOME=$OPTARG
      ;;
    l)
      LIST_FILE=$OPTARG
      ;;
    c)
      CHECKLIST=$OPTARG
      ;;
    s)
      SKIPLIST=$OPTARG
      ;;
    f)
       SUMMARY=1
      ;;
    v)
       ISSAAS=1
      ;;
    h)
      usage
      ;;
    ?)
      usage
      ;;
   esac
 done


#[ ! -d "$CRS_HOME" ] &&  msg "CRS" "$CRS_HOME does not exist" $fail
#[ ! -d "$OH_HOME" ] &&  msg "DB" "$OH_HOME does not exist" $fail

#[  -d "$CRS_HOME" -a ! -f $CRS_HOME/bin/sqlplus ] &&  msg "CRS" "$CRS_HOME/bin/sqlplus does not exist" $fail
#[  -d "$OH_HOME" -a ! -f $OH_HOME/bin/sqlplus ] &&  msg "DB" "$OH_HOME/bin/sqlplus does not exist" $fail

[ -n "$LIST_FILE" -a ! -f "$LIST_FILE" ] && msg "DB" "${LIST_FILE} does not exist ..." $fail

[ -f ${health_file} ] && rm -rf ${health_file}

################## Main #######################################################

BONDTYPE=''
[ "$PLATFORM" == "x86_64" ] && MASTER_NODE=`hostname -s`


CRS_HOME=`ps -ef| grep smon | grep -i asm | grep -v grep | awk '{print $2}' | xargs -i ls -l /proc/{}/cwd | awk '{print $NF}' | tail -n 1 | xargs dirname`


# Filter display option
for h in `echo "$SKIPLIST" | sed -e "s/,/ /g"|tr "a-z" "A-Z"`; do

  case $h in
   NODES)   SKIP_NODE=1 ;; 
   NODE)   SKIP_NODE=1 ;; 
   OS)   SKIP_OS=1 ;; 
   RDS)   SKIP_RDS=1 ;; 
   CELL)   SKIP_CELL=1 ;; 
   IBSW)   SKIP_IBSW=1 ;; 
   CRS)   SKIP_CRS=1 ;; 
   ASM)   SKIP_ASM=1 ;; 
   DB)   SKIP_DB=1 ;; 
   TNS)   SKIP_TNS=1 ;; 
  esac
  
done

# Filter display option
for h in `echo "$CHECKLIST" | sed -e "s/,/ /g"|tr "a-z" "A-Z"`; do

  case $h in
   NODES)   CHECK_NODE=1 ; CHECKONLY=1;;
   NODE)   CHECK_NODE=1 ; CHECKONLY=1;;
   OS)     CHECK_OS=1 ; CHECKONLY=1 ;;
   RDS)    CHECK_RDS=1 ; CHECKONLY=1 ;;
   CELL)   CHECK_CELL=1 ; CHECKONLY=1 ;; 
   IBSW)   CHECK_IBSW=1 ; CHECKONLY=1 ;; 
   CRS)    CHECK_CRS=1 ; CHECKONLY=1 ;;
   ASM)    CHECK_ASM=1 ; CHECKONLY=1 ;;
   DB)     CHECK_DB=1 ; CHECKONLY=1 ;;
   TNS)    CHECK_TNS=1 ; CHECKONLY=1 ;;
  esac

done

if [ $CHECKONLY -eq 1 ]; then
   SKIP_NODE=1; SKIP_OS=1; SKIP_RDS=1; SKIP_CELL=1; SKIP_IBSW=1; SKIP_CRS=1; SKIP_ASM=1; SKIP_DB=1; SKIP_TNS=1
fi

crsow=`ls -l $CRS_HOME/bin/sqlplus 2>/dev/null|awk '{print $3}'`

# Capture ib query errors first
check_ib_query_initial

do_sys_info
[ $SKIP_NODE -eq 0 -o $CHECK_NODE -eq 1 ] && do_node_check
[ $SKIP_OS -eq 0  -o $CHECK_OS -eq 1 ] && do_os_check
[ $SKIP_RDS -eq 0  -o $CHECK_RDS -eq 1 ] && do_rds_check
[ $SKIP_CELL -eq 0  -o $CHECK_CELL -eq 1 ] && do_cell_check
[ $SKIP_IBSW -eq 0  -o $CHECK_IBSW -eq 1 ] && do_ibsw_check
[ $SKIP_CRS -eq 0  -o $CHECK_CRS -eq 1 ] && do_crs_check
[ $SKIP_ASM -eq 0  -o $CHECK_ASM -eq 1 ] && do_asm_check
[ $SKIP_DB -eq 0  -o $CHECK_DB -eq 1 ] && do_db_check
[ $SKIP_TNS -eq 0  -o $CHECK_TNS -eq 1 ] && do_tns_check


exit
################## Modules for DCLI #############################################################
####
#### Following modules/segment of code is used for DCLI to pass to other nodes
####
####
###############################################################################################

<--- BEGIN ETHDEV -->

sarf=`ls -1 /var/log/sa/sa[0-9]* | tail -1`

[ -f "$sarf" ] && xx=`sar -n EDEV -f "$sarf" |egrep  "IFACE|Average"|wc -l`

[ $xx -le 1 ] && sarf=`ls -1 /var/log/sa/sa[0-9]* | tail -2|head -1`

[ -f "$sarf" ] && sar -n EDEV -f $sarf |egrep  "IFACE|Average"  |  awk '
  /IFACE/ {  $1=$2="" }
  !/IFACE/ {  $1="" }
  { print $0 }
' | while read line; do

    h=`echo "$line" | awk '{print "/sys/class/net/"$1 }'`

    IFACE=`echo "$line" | grep -c IFACE`
    NOLINE=0; [ -n "$line" ] && NOLINE=1

    # echo "ray: [$line]"
    sl=""
    [ `echo "$h" | grep -c "bond"` -gt 0 ] &&  sl=`cat $h/bonding/slaves |sed -e "s/ /:/g" 2>/dev/null`

    if [ $IFACE -eq 0 -a $NOLINE -ne 0 ]; then

       c=`cat $h/carrier 2>&1`
       i=`echo "$h" | awk -F"/" '{ print $NF }'`
       s=`cat /etc/sysconfig/network-scripts/ifcfg-$i 2>/dev/null |egrep -c "^[ ]*IPADDR=|^[ ]*MASTER="`
       o=`cat $h/operstate 2>/dev/null`
       a=`echo "$c" | grep -c "Invalid argument"`

       [ -n "$sl" ] && echo  -n "$line ($sl) = "
       [ ! -n "$sl" ] && echo  -n "$line $i = "


    fs="0"
    case $a in
      0)
          if [ "$c" = "1" ]; then
          [ "$o" = "up"   -a $s -gt 0 ] && fs="1"  # interface is configured, healthy
          [ "$o" = "up"   -a $s -eq 0 ] && fs="2"  # interface is not configured, healthy (possibly VIP)
          [ "$o" = "down" -a $s -gt 0 ] && fs="3"  # Not Possible
          [ "$o" = "down" -a $s -eq 0 ] && fs="4"  # Not Possible

          elif [ "$c" = "0" ]; then

          [ "$o" = "up"   -a $s -gt 0 ] && fs="5"  # Not Possible
          [ "$o" = "up"   -a $s -eq 0 ] && fs="6"  # Not Possible
          [ "$o" = "down" -a $s -gt 0 ] && fs="7"  # interface is configured, but no power/carrier
          [ "$o" = "down" -a $s -eq 0 ] && fs="8"  # interface is not configured, unhealthy (could affect VIP)

          fi
           ;;
      1)
          [ "$o" = "up"   -a $s -gt 0 ] && fs="9"  # Not Possible
          [ "$o" = "up"   -a $s -eq 0 ] && fs="10"  # Not Possible
          [ "$o" = "down" -a $s -gt 0 ] && fs="11"  # interface is configured, but no power/carrier
          [ "$o" = "down" -a $s -eq 0 ] && fs="12"  # not in use
          ;;
     esac
     echo "$fs"

    else

     echo "$line"

    fi


 done 

<--- END ETHDEV -->

<--- BEGIN IBDEV -->

check_ib_link() {

 local iblink="$1"
 local OK=1

 P1_state=`echo $iblink | awk '{print $7}'`
 P1_rate=`echo $iblink | awk '{print $8}'`
 P1_link=`echo $iblink | awk '{print $9}'`
 P2_state=`echo $iblink | awk '{print $10}'`
 P2_rate=`echo $iblink | awk '{print $11}'`
 P2_link=`echo $iblink | awk '{print $12}'`

 [ -n "$P1_state" -a "$P1_state" != "ACTIVE" ] && OK=0
 [ -n "$P2_state" -a "$P2_state" != "ACTIVE" ] && OK=0

 [ -n "$P1_rate" -a "$P1_rate" != "40" ] && OK=0
 [ -n "$P2_rate" -a "$P2_rate" != "40" ] && OK=0

 [ -n "$P1_link" -a "$P1_link" != "LinkUp" ] && OK=0
 [ -n "$P2_link" -a "$P2_link" != "LinkUp" ] && OK=0

 [ $OK -eq 1 ] && echo "RDS" "$iblink        ok" 
 [ $OK -eq 0 ] && echo "RDS" "$iblink        fail" 

}


for h in `ls -d1 /sys/class/infiniband/*`; do

DEV=`ls -dl $h`
PCI=`echo "$DEV" | awk -F"/" '{print $(NF-4)}'`
PTH=`echo "$DEV" | awk -F"/" '{print $(NF-3)}'`
#CODE=`echo "$DEV" | awk -F"/" '{print $(NF-2)}'|cut -d":" -f2-3`
CODE=`echo "$DEV" | awk -F"/" '{print $(NF-2)}'`
HCA=`echo "$DEV" | awk -F"/" '{print $NF}'`
MLX=`cat "$h/node_desc" | awk '{print $NF}'`
GUID=`cat "$h/node_guid" | awk '{print $NF}'`

P1_STATE=`cat $h/ports/1/state |awk '{print $2}'`
P1_RATE=`cat $h/ports/1/rate | awk '{print $1}'`
P1_PHYS_STATE=`cat $h/ports/1/phys_state | awk '{print $2}'`

P2_STATE=`cat $h/ports/2/state | awk '{print $2}'`
P2_RATE=`cat $h/ports/2/rate | awk '{print $1}'`
P2_PHYS_STATE=`cat $h/ports/2/phys_state | awk '{print $2}'`

P1_IB=`ls -1d /sys/devices/$PCI/$PTH/$CODE/net/* | head -1`
P2_IB=`ls -1d /sys/devices/$PCI/$PTH/$CODE/net/* | tail -1`

P1_PORT=`echo "$P1_IB" | awk -F"/" '{print $NF}'`
P2_PORT=`echo "$P2_IB" | awk -F"/" '{print $NF}'`

P1_CAR=`cat "$P1_IB/carrier"`
P2_CAR=`cat "$P2_IB/carrier"`

P1_MSTR="."
P2_MSTR="."
P1_ACTIVE="."
P2_ACTIVE="."
[ -d "$P1_IB/master" ] && P1_MSTR=`ls -ld "$P1_IB/master" | awk -F"/" '{print $NF}'`
[ -d "$P2_IB/master" ] && P2_MSTR=`ls -ld "$P2_IB/master" | awk -F"/" '{print $NF}'`

[ -d "$P1_IB/master" ] && P1_ACTIVE=`cat "$P1_IB/master/bonding/active_slave"`
[ -d "$P2_IB/master" ] && P2_ACTIVE=`cat "$P2_IB/master/bonding/active_slave"`


MASTER=""
ACTIVE_SLAVE=""

[ -n "$P1_MSTR" -a "$P1_MSTR" = "$P2_MSTR" ] && MASTER=$P1_MSTR
[ -n "$P1_MSTR" -a "$P1_MSTR" = "$P2_MSTR" ] && ACTIVE_SLAVE=$P1_ACTIVE


check_ib_link "$PCI $PTH $CODE $HCA $MLX $GUID $P1_STATE $P1_RATE $P1_PHYS_STATE $P2_STATE $P2_RATE $P2_PHYS_STATE $P1_PORT $P1_CAR $P2_PORT $P2_CAR $MASTER $ACTIVE_SLAVE"


done

<--- END IBDEV -->

<--- BEGIN RDS PING -->
  DB_LIST=`ip addr show|grep "inet"|egrep  "^bondib|ib"|grep -v "169.254"|awk '{print $2}'|cut -d"/" -f1 | sed -e "s/ //g"`
  CELL_LIST=`cat /etc/oracle/cell/network-config/cellip.ora|cut -d"=" -f2| sed -e "s/\"//g"|cut -d";" -f1`
  RES=""
  OK=1
  LT=""
  UNIT=""

  for dbnode in `echo $DB_LIST`; do

     cnt=0
     for cell in `echo $CELL_LIST`; do

        OK=1
        cnt=$(( cnt + 1 ))
        RES=`numactl --cpubind=0 --membind=0 rds-ping -c 1 -i 5 -I $dbnode $cell 2>&1`

        LT=`echo "$RES" | awk '{ print $(NF-1)}'`
        UNIT=`echo "$RES" | awk '{ print $(NF)}'`

        [ ! -n "$LT" -o ! -n "$UNIT" ] && OK=0
        [  "$UNIT" != "usec" ] && OK=0
        [  "$UNIT" == "usec" -a $LT -gt 500 ] && OK=0

        ### Display just a few rds ping so report won't be too long, however test them all nevertheless
        [ $OK -eq 1 -a $cnt -lt 15 ] && echo "RDS" "Pinging from $dbnode to $cell ... $RES        ok" 
        [ $OK -ne 1 ] && echo "RDS" "Pinging from $dbnode to $cell ... $RES        fail" 

     done

  done

<--- END RDS PING -->

<--- BEGIN HW FAULT -->

echo "Checking HW Fault `hostname` ..."

hw_file="$OUTDIR/_hw_fault.txt"
ipmitool sunoem cli 'show faulty' > $hw_file
cat $hw_file | awk '
   /class/ ||
   /sunw-msg-id/ ||
   /component/ ||
   /timestamp/ ||
   /fru_part_number/ ||
   /fru_serial_number/ ||
   /product_serial_number/ ||
   /chassis_serial_number/  { printf "HW: %-25.25s  :    %s \n", $3, $NF }
'

[ -f "$hw_file" ] && rm -rf $hw_file

<--- END HW FAULT -->


<--- BEGIN RDS MAC -->

echo "Checking RDS MAC `hostname` ..."

rdsi=`rds-info -I|egrep -v "Remote|Connection|^$"`

rds1=`echo "$rdsi" | awk '{print $1"/"$5}'|sort|uniq`
rds2=`echo "$rdsi" | awk '{print $2"/"$6}'|sort|uniq`

rds_mac_fnd=0

for h in `echo "$rds1"`; do

 for i in `echo "$rds2"`; do
    l_ip=`echo "$h" | awk -F"/" '{print $1}'|sed -e "s/[ ]*//g"`
    l_mac=`echo "$h" | awk -F"/" '{print $2}'|sed -e "s/[ ]*//g"`
    r_ip=`echo "$i" | awk -F"/" '{print $1}'|sed -e "s/[ ]*//g"`
    r_mac=`echo "$i" | awk -F"/" '{print $2}'|sed -e "s/[ ]*//g"`

    [ "$l_ip" = "$r_ip" -a "$l_mac" != "$r_mac" ] && \
     echo "$l_ip $l_mac $r_ip $r_mac" |  awk '
     {
       printf("RDS: unmatched MAC:  %20s  %-20s     %20s  %-20s      fail\n", $1, $2, $3, $4 )
      }' && rds_mac_fnd=1
 done

done
   
[ $rds_mac_fnd -eq 0 ] && echo "RDS: No unmatched MAC Address  ... ok"

<--- END RDS MAC -->


<--- BEGIN HWADDR -->
check_hw_addr() {

for h in `ls -1 /sys/class/net/bondib*/address /sys/class/net/ib*/address 2>/dev/null`; do

IBINTRF=`echo "$h"| awk -F"/" '{print $(NF-1)}'`
HWADDR=`cat $h | awk -F":" '
     {
        gsub("^[0]*","",$17)
        gsub("^[0]*","",$19)
        print $5$6"::"$14":"$15$16":"$17$18":"$19$20
     }
     '`

 MACADDR=`ip addr show $IBINTRF|grep link|grep -v inet6| awk '{print $2}'| awk -F":" '
       {
          gsub("^[0]*","",$17)
          gsub("^[0]*","",$19)
          print $5$6"::"$14":"$15$16":"$17$18":"$19$20
      }'`

 IPADDR=`ip addr show $IBINTRF| grep inet|egrep " $IBINTRF$|$IBINTRF:[0-9]$" | awk '{print $2}'|cut -d"/" -f1`

  [ "$MACADDR" = "$HWADDR" ] && echo "Checking ${IBINTRF} [ ${HWADDR} ] [ ${MACADDR} ]... ok"
 for h in `echo "$IPADDR"`; do
   echo "$h $MACADDR $HWADDR"
 done

done

}

check_hw_addr
<--- END HWADDR -->/

<--- BEGIN CRS ALERT -->

log_write() {

   local nepoc="$1"
   local log="$2"
   
   fdate=`ls -ltr $log | awk '{print $6" "$7" "$8}'`

   fepoc=`date --date "$fdate" +"%s"`

   epoc_8hr=$(( nepoc - 28800 ))

   if [ $(( nepoc - 28800 )) -le $fepoc ]; then

     LTYPE=`echo "$log" | awk -F"/" '{print $(NF-1)}'| tr "a-z" "A-Z"`

     LTYPE=`echo "$log" | awk -F"/" '{print $(NF-2)}' | tr "a-z" "A-Z" | awk -v p="$LTYPE" '$0 ~ /OHASD|CRSD/ { p=$0"_"p } {print p}'`

     tail -1000 $log | awk '
      $1 ~ /^[ ]*20[0-9][0-9]-[0-9][0-9]-/ { d=$0 }
      $1 !~ /^[ ]*20[0-9][0-9]-[0-9][0-9]-/ { print d" "$0  }
     ' | egrep -i "started |startup|stop|stopped shut|shutdown|fail |failed | error |warning|critical|down| timed out | timed-out |fatal| miss |disconnect|evicted|eviction|evict|kill| unable | fault | abort | aborted " | \
              egrep -v "^client|evmd|Invalid argument|error \[29\] msg \[gipcretConnectionRefused\]" | \
     while read line; do

        fdate=`echo "$line" | awk -F" " '{print $1" "$2}'|sed -e "s/:$//g"`
        err=`echo "$line" | cut -d" " -f3-`

        fepoc=`date --date "$fdate" +"%s"`

        ndate=`date -d @$fepoc +"%a %b %d %H:%M %Y" | sed -re "s/[0-9] (20[0-9][0-9])$/0 \1/g"`

        echo "$ndate $LTYPE $err" | sed -re "s/ (\[(crsd|cssd|mdnsd|gpnpd|ohasd|ctssd|ctssd))\([0-9]+\)/\1/g"

     done 
   fi

}

MASTER_NODE=`hostname -s`
CRS_HOME=`ps -eaf|grep ocssd.bin|grep -v grep|awk '{print $NF}'|sed -e "s/\/bin\/ocssd\.bin//g"`

[ ! -n "$CRS_HOME" ] && exit

ORACLE_BASE=`cat $CRS_HOME/inventory/ContentsXML/oraclehomeproperties.xml|grep "ORACLE_BASE"|grep VAL|awk -F"\"" '{print $(NF-1)}'`

GRID_VER="11g"
#### 11g
LOG_HOME="$CRS_HOME/log/$MASTER_NODE"

#### 12g validate
[ -d "$ORACLE_BASE/diag/crs/$MASTER_NODE" ] && LOG_HOME="$ORACLE_BASE/diag//crs/$MASTER_NODE"
[ -d "$ORACLE_BASE/diag/crs/$MASTER_NODE" ] && GRID_VER="12c" #Lets assume 12c is 12 and higher versions

nepoc=`date +"%s"`

 if [ "$GRID_VER" = "11g" ]; then

  for log in `ls -1 $LOG_HOME/alert*log $LOG_HOME/agent/{ohasd,crsd}/*/*log  $LOG_HOME/{diskmon,cssd,crsd,evmd,ohasd,gipcd,gpnpd}/*log 2>/dev/null`; do

     log_write $nepoc "$log"

  done

 elif [ "$GRID_VER" = "12c" ]; then

  for log in `ls -1 $LOG_HOME/crs/trace/{crsd,diskmon,evmd,evmlogger,gipcd,gpnpd,mdnsd,ocssd,octssd,ohasd,ologgerd,osysmond}.trc  2>/dev/null`; do

    log_write $nepoc "$log"

  done
 

 fi

<--- END CRS ALERT -->

<--- BEGIN ASM ALERT -->
  asm_info="$OUTDIR/_asm_info.txt"

  [ ! -f "$asm_info" ] && exit

  for h in  `cat "$asm_info" | awk '{print $1":"$3}'`; do

     ll=`echo "$h" | cut -d":" -f2`
     dbm=`echo "$h" | cut -d":" -f1`

     trclog=`ls -1 $ll/alert*log 2>/dev/null`

     [ -n "$trclog" ] && ( tail -1000 "$trclog" 2>/dev/null) | egrep -h "^20[0-9][0-9]-| 20[0-9][0-9]$|^ORA-|^TNS-|^Starting ORACLE instance|^Shutting down instance" | \
       grep -iv "^version" | sed -re "s/^(.?)/$dbm \1/g" 

   done
<--- END ASM ALERT -->


<--- BEGIN DB ALERT -->
  db_info="$OUTDIR/_db_info.txt"

  [ ! -f "$db_info" ] && exit

  for h in  `cat "$db_info" | awk '{print $1":"$3}'`; do

     ll=`echo "$h" | cut -d":" -f2`
     dbm=`echo "$h" | cut -d":" -f1`

     trclog=`ls -1 $ll/alert*log 2>/dev/null`

     [ -n "$trclog" ] && ( tail -1000 "$trclog"  2>/dev/null) | egrep -h "^20[0-9][0-9]-| 20[0-9][0-9]$|^ORA-|^TNS-|^Starting ORACLE instance|^Shutting down instance" | \
       grep -iv "^version" | sed -re "s/^(.?)/$dbm \1/g"

   done
<--- END DB ALERT -->

<--- BEGIN DB INFO -->

sql() {

 sid="$1"
 dbh="$2"
 query="$3"


 sql="$dbh/bin/sqlplus"
[ ! -f "$sql" ] && msg "ASM" "$dbh/bin/sqlplus does not exist ..." $fail

ow=`ls -l $sql 2>/dev/null|awk '{print $3}'`
 res=$(su  $ow -c "
export ORACLE_HOME=${dbh}
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export PATH=${ORACLE_HOME}
export ORACLE_SID=${sid}
$sql  -s /nolog  <<eof!
connect / as sysdba
set head off feed off echo off scan off
set trimspool on trimout on lines 1000 pages 10000
$query
/
exit
eof!
"
)

 echo "$res"  | xargs echo
}

check_asm_info() {


  local asm_info="$OUTDIR/_asm_info.txt"
  local dbhome=""
  local sid=""

  touch $asm_info
  ps -eaf|grep asm_pmon | grep -v grep | while read line; do

   sid=`echo "$line" | awk -F"_" '{print $NF}'`
   #dbhome=`echo "$line" | awk '{print $2}'| xargs pwdx | sed -e "s/\/dbs$//g"|cut -d":" -f2|sed -e "s/ //g"`
   dbhome=`echo "$line" | awk '{print $2}'| xargs pwdx | awk '{print $NF}' | xargs dirname`

   sql "$sid" "$dbhome" "select  a.instance_name ,'$dbhome',  b.value from (select  instance_name from v\\\$instance) a, (select value from v\\\$diag_info where name = 'Diag Trace') b" >> $asm_info

  done
  rm -rf $asm_info
}


check_db_info() {


  local db_info="$OUTDIR/_db_info.txt"
  local dbhome=""
  local sid=""


  touch $db_info
  ps -eaf|grep ora_pmon | grep -v grep | while read line; do

   sid=`echo "$line" | awk -F"_" '{print $NF}'`
   #dbhome=`echo "$line" | awk '{print $2}'| xargs pwdx | sed -e "s/\/dbs$//g"|cut -d":" -f2|sed -e "s/ //g"`
   dbhome=`echo "$line" | awk '{print $2}'| xargs pwdx | awk '{print $NF}' | xargs dirname`

   sql "$sid" "$dbhome" "select  a.instance_name ,'$dbhome',  b.value from (select  instance_name from v\\\$instance) a, (select value from v\\\$diag_info where name = 'Diag Trace') b" >> $db_info

  done
  rm -rf $db_info
}

check_asm_info
check_db_info
<--- END DB INFO -->

<--- BEGIN CELL IOSTAT -->
 # echo ""| awk '{ printf "%-8s  %7s  %7s  %7s  %5s\n", "Dev", "AvgQu", "Await","Svctm","%Util" }'
 iostat -x 3 2|awk '
     /^sd|^md/ {
                   rps[$1]=$4
                   wps[$1]=$5
                   rbps[$1]=$6
                   wbps[$1]=$7
                   avgrq[$1]=$8
                   avgqu[$1]=$9
                   await[$1]=$10
                   svctm[$1]=$11
                    util[$1]=$12
               }
     END {
         found=0
         for (i in avgqu) {
            rs=rps[i]
            ws=wps[i]
            rbs=rbps[i]
            wbs=wbps[i]
            rq=avgrq[i]
            qu=avgqu[i]
            aw=await[i]
            sv=svctm[i]
            ut=util[i]
            if (qu > 20 || aw > 20 || sv > 20 || ut > 70 ) {
                     printf "%s %f %f %f %f %f %f %f %f %f\n", i,rs,ws,rbs,wbs,rq,qu,aw,sv,ut
                     found=1
            }
         }
     #    if (found ==0 ) print "No disks with IO Queue above 10, or Latency (Wait/Service) above 5ms, or %Util above 50"
     }
   '
<--- END CELL IOSTAT -->

<--- BEGIN CELL METRIC -->
 host=`hostname -s`
 cellcli -e "list metrichistory \
     DB_IO_UTIL_SM,DB_IO_UTIL_LG, \
     CD_IO_BY_R_LG_SEC,CD_IO_BY_W_LG_SEC,CD_IO_BY_R_SM_SEC,CD_IO_BY_W_SM_SEC, \
     CD_IO_RQ_R_LG_SEC,CD_IO_RQ_R_SM_SEC,CD_IO_RQ_W_LG_SEC,CD_IO_RQ_W_SM_SEC \
     where collectionTime > '<DATE>'" | awk -v h="$host" '
                                { t=gensub(/T([0-9]+:[0-9])[0-9]:[0-9]+/," \\10:00","g", $5);  time[t]=t }
    /CD_IO_BY_R_LG_SEC/ && $3>0 { l_r_t[t] +=$3; lrt[t]++ }
    /CD_IO_BY_W_LG_SEC/ && $3>0 { l_w_t[t] +=$3; lwt[t]++ }
    /CD_IO_BY_R_SM_SEC/ && $3>0 { s_r_t[t] +=$3; srt[t]++ }
    /CD_IO_BY_W_SM_SEC/ && $3>0 { s_w_t[t] +=$3; swt[t]++ }

    /CD_IO_RQ_R_LG_SEC/ && $3>0 { l_r_r[t] +=$3; lrr[t]++ }
    /CD_IO_RQ_W_LG_SEC/ && $3>0 { l_w_r[t] +=$3; lwr[t]++ }
    /CD_IO_RQ_R_SM_SEC/ && $3>0 { s_r_r[t] +=$3; srr[t]++ }
    /CD_IO_RQ_W_SM_SEC/ && $3>0 { s_w_r[t] +=$3; swr[t]++ }

    /DB_IO_UTIL_SM/ { db_sm[$2]=$2; util_sm[$2,t] +=$4; usm[$2,t]++ }
    /DB_IO_UTIL_LG/ { db_lg[$2]=$2; util_lg[$2,t] +=$4; ulg[$2,t]++ }

     END {
      for (t in time) {
          if (length(l_r_t[t]) > 0) printf "LRT %s %s  %10.2f\n",h,   t, l_r_t[t] / lrt[t]
          if (length(l_w_t[t]) > 0) printf "LWT %s %s  %10.2f\n",h,   t, l_w_t[t] / lwt[t]
          if (length(s_r_t[t]) > 0) printf "SRT %s %s  %10.2f\n",h,   t, s_r_t[t] / srt[t]
          if (length(s_w_t[t]) > 0) printf "SWT %s %s  %10.2f\n",h,   t, s_w_t[t] / swt[t]

          if (length(l_r_r[t]) > 0) printf "LRR %s %s  %10.2f\n",h,   t, l_r_r[t] / lrr[t]
          if (length(l_w_r[t]) > 0) printf "LWR %s %s  %10.2f\n",h,   t, l_w_r[t] / lwr[t]
          if (length(s_r_r[t]) > 0) printf "SRR %s %s  %10.2f\n",h,   t, s_r_r[t] / srr[t]
          if (length(s_w_r[t]) > 0) printf "SWR %s %s  %10.2f\n",h,   t, s_w_r[t] / swr[t]
        for (d in db_sm) {
          if (length(util_sm[d,t]) > 0) printf "USM %s %s  %10.2f\n",  d, t, util_sm[d,t] / usm[d,t]
         }
        for (d in db_lg) {
          if (length(util_lg[d,t]) > 0) printf "ULG %s %s  %10.2f\n",  d, t, util_lg[d,t] / ulg[d,t]
         }
      }
     }

  ' | while read line; do
     dtime=`echo "$line" | awk '{ print $3" "$4}'`
     sdate=`date --date "$dtime" +"%a %b %d %H:%M %Y"`
     echo "$line" |  awk -v d="$sdate" '{ printf("%10.2f %s %s %s\n", $NF,d, $1, $2) } '
  done

<--- END CELL METRIC -->

<--- BEGIN HANGANALYZE -->

sql_hanganalyze() {

 local sid="$1"
 local dbh="$2"

 sql="$dbh/bin/sqlplus"

  [ ! -f "$sql" ] && msg "ASM" "$dbh/bin/sqlplus does not exist ..." $fail
ow=`ls -l $sql 2>/dev/null|awk '{print $3}'`
 res=$(su  $ow -c "
export ORACLE_HOME=$dbh
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export PATH=\$ORACLE_HOME
export ORACLE_SID=$sid
$sql  -s /nolog  <<eof!
  connect / as sysdba

  set head off feed off echo off scan off verify off
  set trimspool on trimout on lines 1000 pages 10000
  oradebug setmypid
  -- oradebug -g all hanganalyze 3
  oradebug dump hanganalyze 3
  oradebug tracefile_name
  exit
eof!
"
)
  echo "$res" | while read line; do
    [ -n "$line" ] &&  echo $SID $line | grep -v "Statement processed."
    #[ -n "$line" ] && grep  "Hang Analysis in" | awk -v SID="$SID" '{print SID" "$NF}'
  done

}


check_db_chains() {
  local line="$1"
  local sid=`echo $line|awk '{print $1}'`
  local htrace=`echo $line|awk '{print $2}'`

   cat "$htrace" | awk '/^HANG ANALYSIS:/,/^END OF HANG ANALYSIS/ { print $0}' | \
   egrep -i "Oracle session identified|is waiting for|is blocked by|Chain|time in wait|process id" | awk '

    BEGIN {  chn=0; }

    /^Chain [0-9]+:/ { chain=""; blocks=0; cycle=0 }

    /^Chain [0-9]+ Signature:/ { if ($0 ~ /\(cycle\)/) cycle++ }
    /^Chain [0-9]+ Signature:/ { chains[++chn]=chain" (blocked="blocks",cycle="cycle")"; chain=""  }

    /Oracle session identified/ { proc_id=""; proc_type="";  event="" ; first = 1  }

    /process id:/ { gsub(",","",$3); proc_id=$3
                    proc_type=$NF
                    if ( proc_type ~ /V1\)$/)  proc_type=$(NF-1)" "$NF
                    if ( proc_type !~ /)$/)  proc_type=""
                   #  proc_type="["proc_id"]"proc_type
                   }

    /which is waiting for/ {
                               first = 0
                           }

    /is waiting for/  {  split($0, a, "'\''");
                         event="'\''"a[2]"'\''"
                         proc[proc_id] = proc_type" "event
                         if (event ~ /EMON slave idle wait/) proc[proc_id] = "(E00nn) "event
                         if (event ~ /parallel recovery slave next change/) proc[proc_id] = "(PRnn) "event
                         if ( chain == "" ) chain = proc[proc_id]; else chain = proc[proc_id]" <= "chain


                      }

    /and is blocked by/ {  blocks++ }

    END {

       if (chn == 0) print "No chains ..."; else
        for (i=1; i<=chn; i++) {
         # print "chain "i" "chains[i]
          print "Chains: "chains[i]
        }

    }

 ' | sort|uniq -c | \
    egrep -iv "EMON slave idle wait|Streams AQ: waiting for messages in the queue" |  \
    while read line; do

      echo "$sid $line"
  done
}


check_db_hanganalyze() {

 local db_info="$OUTDIR/_db_info.txt"
 echo ""
 echo "Checking DB Hang Chains ..."
 echo ""

 cat "$db_info"  | while read line; do

   #SID=`echo "$line" | awk -F"_" '{print $NF}'`
   #export ORACLE_HOME=`echo "$line" | awk '{print $2}'| xargs pwdx | sed -e "s/\/dbs$//g"|cut -d":" -f2|sed -e "s/ //g"`

   SID=`echo "$line" | awk  '{print $1}'`
   export ORACLE_HOME=`echo "$line" | awk  '{print $2}'`

   export LD_LIBRARY_PATH=$ORACLE_HOME/lib
   export PATH=$ORACLE_HOME/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
   export ORACLE_SID=$SID

   sql_hanganalyze "$SID" "$ORACLE_HOME"

done | while read line; do

  check_db_chains "$line"

 done

}

check_db_hanganalyze
<--- END HANGANALYZE -->

<--- BEGIN DB STATS -->


set lines 980 pages 180
set head off feed off scan off echo off verify off
set numformat 99999999999.99
col dbname format a25
col sql_id format a20
col sql_text format a60
col wait_class format a25
col name format a15
col stype format a10
col owner format a10
col object_name format a15

alter session set nls_date_format='DD-MON-RR/HH24:MI:SS';
select /* APSDBCHECK */  * from
(
WITH sch_user as
(select user#, name from user\$ ),
     stat_obj as
(select owner, object_name, data_object_id from dba_objects )
select
   'ASH' stype,
   (select  name from v\$database) dbname,
     '~' || nvl(a.event,'.')  event,
     '~' || nvl(a.sql_id,'.') sql_id,
     '~' || nvl(substr( sq.sql_text,1,55),'.')  sql_text,
     '~' || decode(session_state,'ON CPU','CPU + CPU Wait',wait_class)  wait_class,
     '~' || u.name name,
     '~' || o.owner owner,
     '~' || o.object_name || '~' object_name,
     '~' || time_waited time_waited,
      session_state
 from gv\$active_session_history a,
      gv\$sql sq,
      sch_user u,
      stat_obj o
     where a.sample_time > sysdate - 3/24 and
           a.sql_id = sq.sql_id and
           a.inst_id = sq.inst_id  and
           a.user_id = u.user#  and
           a.current_obj# = o.data_object_id (+)
)
pivot
(
     count(session_state)
     for (session_state) in ('WAITING' as WAITING, 'ON CPU' as CPU)
);


set lines 980 pages 180
set head off feed off scan off echo off verify off
set trimspool on trimout on
set numformat 99999999999.99
col name format a25
col source format a25
alter session set nls_date_format='DD-MON-RR/HH24:MI:SS';

SELECT 'SQLMON' stype, (select name from v\$database) name,
     nvl(username,regexp_replace(process_name,'(p|m)[0-9]+','\1NNN')) source, sql_id,
     round(sum( elapsed_time )/1000000)              as elapse_time,
     round(sum( cpu_time )/1000000,2)                as cpu_time,
     round(sum( queuing_time )/1000000,2)            as queuing_time,
     round(sum( application_wait_time )/1000000,2)   as applic_wait,
     round(sum( concurrency_wait_time )/1000000,2)   as concurrency_wait,
     round(sum( cluster_wait_time )/1000000,2)       as cluster_wait,
     round(sum( user_io_wait_time)/1000000,2)       as user_io_wait,
     round(sum( physical_read_bytes)/(1024*1024 ))  as phys_reads_mb,
     round(sum( physical_write_bytes)/(1024*1024))  as phys_writes_mb,
     sum( buffer_gets)                              as buffer_gets,
     round(sum( plsql_exec_time)/1000000,2)         as plsql_exec,
     round(sum( java_exec_time) /1000000,2)         as java_exec,
     round(sum( fetches),2)         as fetches
     FROM gv\$sql_monitor
     where sql_exec_start > sysdate - 3/24
     group by username, process_name, sql_id having  round(sum(elapsed_time)/1000000) > 0;

set lines 980 pages 180
set head off feed off scan off echo off verify off
set numformat 99999999999.99
col dbname format a25
col sql_id format a20
col sql_text format a60
col wait_class format a25
col name format a15


alter session set nls_date_format='DD-MON-RR/HH24:MI:SS';
select
   'SQLSTAT' stype,
   pschema,
   sql_id,
   start_time,
   sum(execs) execs,
   sum(cpu_time)/1000000 cpu_time,
   sum(elapsed_time)/1000000 elapsed_time,
   sum(parse_calls) parse_calls,
   sum(fetches) fetches,
   sum(rows_processed) rows_processed,
   sum(phys_read_reqs) phys_read_reqs,
   sum(phys_read_reqs + phys_write_reqs) iops,
   sum(phys_read_bytes + phys_write_bytes)/1048576 mbbytes,
   sum(io_offloads) io_offloads,
   sum(buffer_gets) buffer_gets
from
 (
 WITH snap as (
    select a.snap_id, a.instance_number, a.dbid, a.start_time
      from (
             select distinct snap_id, instance_number, dbid, trunc(end_interval_time,'MI')  start_time
             from dba_hist_snapshot
             where
             trunc(begin_interval_time,'HH24') > sysdate - 3/24
             order by snap_id desc
      ) a where
      rownum < 2
      order by a.snap_id
  )
  select s.start_time start_time, a.snap_id, a.dbid, a.sql_id sql_id, a.EXECUTIONS_DELTA execs, a.CPU_TIME_DELTA cpu_time, a.ELAPSED_TIME_DELTA elapsed_time,
         a.PARSE_CALLS_DELTA parse_calls, a.DISK_READS_DELTA disk_reads, a.FETCHES_DELTA fetches, a.IO_OFFLOAD_RETURN_BYTES_DELTA io_offloads,
         a.PHYSICAL_READ_REQUESTS_DELTA phys_read_reqs, a.PHYSICAL_WRITE_REQUESTS_DELTA phys_write_reqs,
         a.PHYSICAL_READ_BYTES_DELTA phys_read_bytes, a.PHYSICAL_WRITE_BYTES_DELTA phys_write_bytes, a.ROWS_PROCESSED_DELTA rows_processed,
         a.BUFFER_GETS_DELTA buffer_gets,
         nvl(a.PARSING_SCHEMA_NAME,'.')  pschema
   from snap s,
        dba_hist_sqlstat a
   where s.snap_id = a.snap_id and
        s.instance_number = a.instance_number and
        s.dbid = a.dbid and
        a.parsing_schema_name is not null
  )
  group by pschema, start_time, sql_id;


set lines 1980 pages 180
set head off feed off scan off echo off verify off
set numformat 99999999999.99
col dbname format a25

alter session set nls_date_format='DD-MON-RR/HH24:MI:SS';
select
   'SYSEVENT' stype,
   /* APSDBCHECK */ (select name from v\$database) name,
   '~' || event_name event_name,
   '~' || wait_class || '~' wait_class,
   total_waits,
   total_timeouts,
   time_waited_ms,
   total_waits_fg,
   time_waited_fg_ms
from
(
select
  event_name, wait_class,
  sum(total_waits) total_waits,
  sum(total_timeouts) total_timeouts,
  sum(time_waited_micro/1000) time_waited_ms,
  sum(total_waits_fg) total_waits_fg,
  sum(time_waited_micro_fg/1000) time_waited_fg_ms
from
 (
    WITH snap as (
     select s.snap_id, s.instance_number, s.dbid, s.start_time
      from (
             select distinct snap_id, instance_number,  dbid, trunc(end_interval_time,'MI')  start_time
             from dba_hist_snapshot
             where
             trunc(begin_interval_time,'HH24') > sysdate - 3/24
             order by snap_id desc
      ) s where rownum < 3 order by s.snap_id
    )
    select a.event_name, a.wait_class, a.total_waits, a.total_timeouts,
          a.time_waited_micro, a.total_waits_fg, a.time_waited_micro_fg,
          s.snap_id, s.dbid, s.start_time
       from snap s,
            dba_hist_system_event a
       where s.snap_id = a.snap_id and
             s.instance_number = a.instance_number and
             s.dbid = a.dbid and
             a.wait_class not in ('Idle') and ( a.total_waits > 0 and a.total_waits_fg > 0 )
  )
  group by event_name, wait_class
);

<--- END DB STATS -->

<--- BEGIN TOP ACTIVITY -->


set lines 980 pages 180
set head off feed off scan off echo off verify off
set numformat 99999999999.99
col dbname format a25
col sql_id format a20
col sql_text format a60
col wait_class format a25
col name format a15

alter session set nls_date_format='DD-MON-RR/HH24:MI:SS';
select /* APSDBCHECK */ * from
(
WITH sch_user as
(select user#, name from user\$ )
select
   (select  name from v\$database) dbname,
     '~' || nvl(a.event,'.')  event,
     '~' || nvl(a.sql_id,'.') sql_id,
     '~' || nvl(substr( sq.sql_text,1,55),'.')  sql_text,
     '~' || decode(session_state,'ON CPU','CPU + CPU Wait',wait_class)  wait_class,
     '~' ||  u.name || '~' ,
      session_state
 from gv\$active_session_history a,
      gv\$sqlarea sq,
      sch_user u
     where a.sample_time > sysdate - 3/24 and
           a.sql_id = sq.sql_id and
           a.inst_id = sq.inst_id  and
           a.user_id = u.user# and
           sq.sql_text not like '%~%'
)
pivot
(
     count(session_state)
     for (session_state) in ('WAITING' as WAITING, 'ON CPU' as CPU)
);


<--- END TOP ACTIVITY -->


<--- BEGIN SQL MONITOR -->


set lines 980 pages 180
set head off feed off scan off echo off verify off
set trimspool on trimout on
set numformat 99999999999.99
col name format a25
col source format a25
alter session set nls_date_format='DD-MON-RR/HH24:MI:SS';

SELECT (select name from v\$database) name,
     nvl(username,regexp_replace(process_name,'(p|m)[0-9]+','\1NNN')) source, sql_id,
     round(sum( elapsed_time )/1000000)              as elapse_time,
     round(sum( cpu_time )/1000000,2)                as cpu_time,
     round(sum( queuing_time )/1000000,2)            as queuing_time,
     round(sum( application_wait_time )/1000000,2)   as applic_wait,
     round(sum( concurrency_wait_time )/1000000,2)   as concurrency_wait,
     round(sum( cluster_wait_time )/1000000,2)       as cluster_wait,
     round(sum( user_io_wait_time)/1000000,2)       as user_io_wait,
     round(sum( physical_read_bytes)/(1024*1024 ))  as phys_reads_mb,
     round(sum( physical_write_bytes)/(1024*1024))  as phys_writes_mb,
     sum( buffer_gets)                              as buffer_gets,
     round(sum( plsql_exec_time)/1000000,2)         as plsql_exec,
     round(sum( java_exec_time) /1000000,2)         as java_exec
     FROM gv\$sql_monitor
     group by username, process_name, sql_id having  round(sum(elapsed_time)/1000000) > 0;

<--- END SQL MONITOR -->

<--- BEGIN SQL STAT -->

set lines 980 pages 180
set head off feed off scan off echo off verify off
set numformat 99999999999.99
col dbname format a25
col sql_id format a20
col sql_text format a60
col wait_class format a25
col name format a15


alter session set nls_date_format='DD-MON-RR/HH24:MI:SS';
select 
   pschema,
   sql_id,
   start_time,
   sum(execs) execs,
   sum(cpu_time)/1000000 cpu_time,
   sum(elapsed_time)/1000000 elapsed_time,
   sum(parse_calls) parse_calls,
   sum(fetches) fetches,
   sum(rows_processed) rows_processed,
   sum(phys_read_reqs) phys_read_reqs, 
   sum(phys_read_reqs + phys_write_reqs) iops,
   sum(phys_read_bytes + phys_write_bytes)/1048576 mbbytes,
   sum(io_offloads) io_offloads,
   sum(buffer_gets) buffer_gets
from
 ( select  snap_id, dbid, sql_id, EXECUTIONS_DELTA execs, CPU_TIME_DELTA cpu_time, ELAPSED_TIME_DELTA elapsed_time,
         PARSE_CALLS_DELTA parse_calls, DISK_READS_DELTA disk_reads, FETCHES_DELTA fetches, IO_OFFLOAD_RETURN_BYTES_DELTA io_offloads,
         PHYSICAL_READ_REQUESTS_DELTA phys_read_reqs, PHYSICAL_WRITE_REQUESTS_DELTA phys_write_reqs,
         PHYSICAL_READ_BYTES_DELTA phys_read_bytes, PHYSICAL_WRITE_BYTES_DELTA phys_write_bytes, ROWS_PROCESSED_DELTA rows_processed,
         BUFFER_GETS_DELTA buffer_gets,
         nvl(PARSING_SCHEMA_NAME,'.')  pschema
   from dba_hist_sqlstat b where parsing_schema_name is not null ) snt,
 (
      select a.snap_id, a.dbid, a.start_time
      from (
             select distinct snap_id, dbid, trunc(end_interval_time,'MI')  start_time
             from dba_hist_snapshot
             where
             trunc(begin_interval_time,'HH24') > sysdate - 4/24
             order by snap_id desc
      ) a where
      rownum < 2
      order by a.snap_id
  ) sn
  where snt.snap_id = sn.snap_id and
        snt.dbid = sn.dbid 
  group by pschema, start_time, sql_id;


<--- END SQL STAT -->

<--- BEGIN SYSTEM EVENT -->

set lines 980 pages 180
set head off feed off scan off echo off verify off
set numformat 99999999999.99
col dbname format a25

alter session set nls_date_format='DD-MON-RR/HH24:MI:SS';
select /* APSDBCHECK */ (select name from v\$database) name, 
   '~' || event_name ,
   '~' || wait_class || '~',
   total_waits,
   total_timeouts,
   time_waited_ms,
   total_waits_fg,
   time_waited_fg_ms
from
(
select 
  syse.event_name, syse.wait_class,
  sum(syse.total_waits) total_waits,
  sum(syse.total_timeouts) total_timeouts,
  sum(syse.time_waited_micro/1000) time_waited_ms,
  sum(syse.total_waits_fg) total_waits_fg,
  sum(syse.time_waited_micro_fg/1000) time_waited_fg_ms
from
 ( select * from dba_hist_system_event a where wait_class not in ('Idle')
     and ( total_waits > 0 and total_waits_fg > 0 ) ) syse,
 (
      select a.snap_id, a.dbid, a.start_time
      from (
             select distinct snap_id, dbid, trunc(end_interval_time,'MI')  start_time
             from dba_hist_snapshot
             where
             trunc(begin_interval_time,'HH24') > sysdate - 4/24
             order by snap_id desc
      ) a where
      rownum < 3
      order by a.snap_id
  ) sn
  where syse.snap_id = sn.snap_id and
        syse.dbid = sn.dbid 
  group by syse.event_name, syse.wait_class
);
<--- END SYSTEM EVENT -->


<--- BEGIN ASM DISKGROUP -->

set lines 980 pages 180
set head off feed off scan off echo off verify off
col compatibility format a10
col database_compatibility format a10
set lines 1000
col name format a15
col state format a10
col blks format 9999
col secs format 999
col type format a8
col g# format 99
col "% FREE/TOTAL(GB)" format a20


    select group_number g#, name, sector_size secs, block_size blks, ALLOCATION_UNIT_SIZE "AUS",
    STATE, TYPE, ' ' || round(free_mb/total_mb*100)  || ' ' || round(FREE_MB/1024) || '/' || round(TOTAL_MB/1024)
    "% FREE/TOTAL(GB)",
    REQUIRED_MIRROR_FREE_MB RQ_M_FREE_MB, USABLE_FILE_MB, OFFLINE_DISKS
   from v\$asm_diskgroup_stat where total_mb > 0;

<--- END ASM DISKGROUP -->



################## Properties #################################################################
####
#### Format:  <message>:<expected value>:<parameter>
####
####  Note:  parameter can be derived via query or params files
####         if it's from params file, just specify the parameter

####  Note:  if expected value is an integer, you can use operators to compare
####         e.g.  <message>:<expected value>:=:<parameter>    <-- if expected value is equal
####         e.g.  <message>:<expected value>:>=:<parameter>    <-- if expected value is greater than or equal

###############################################################################################################

<-- ASM begin -->
Check status of ASM instance:NORMAL:select active_state from v\\$instance

#check DATA diskgroup
Check state of DATA diskgroup:MOUNTED:select state from v\\$asm_diskgroup where name like '%DATA%'
Check state of RECO diskgroup:MOUNTED:select state from v\\$asm_diskgroup where name like '%RECO%'
#Check state of REDO diskgroup:MOUNTED:select state from v\\$asm_diskgroup where name like '%REDO%'
#Check state of LOB diskgroup:MOUNTED:select state from v\\$asm_diskgroup where name like '%LOB%'
Check state of DBFS_DG diskgroup:MOUNTED:select state from v\\$asm_diskgroup where name='DBFS_DG'

Check offlined disks on DATA diskgroup:0:=:select offline_disks from v\\$asm_diskgroup where name='DATA'
Check offlined disks on RECO diskgroup:0:=:select offline_disks from v\\$asm_diskgroup where name='RECO'
Check offlined disks on DBFS diskgroup:0:=:select offline_disks from v\\$asm_diskgroup where name='DBFS_DG'

Check blocking session count:2:<=:select count(*) cnt from v\\$session where blocking_session is not null
Check global blocking session count:2:<=:select count(*) cnt from gv\\$session where blocking_session is not null

<-- ASM end -->

<-- ASM params begin -->
Check--0--=--memory_target--ALL
Check--0--=--memory_max_target--ALL
Check--256--=--_ksxp_reaping--ALL
Check--140--=--_lm_idle_connection_check_interval--ALL
Check--o/*/*--=--asm_diskstring--ALL
Check--4--=--asm_power_limit--ALL
Check--TRUE--=--cluster_database--ALL
Check--ASM--=--instance_type--ALL
# large pool size is set to a granule by default, that is 16m for 2G SGA
Check--16777216--=--large_pool_size--ALL
Check--EXCLUSIVE--=--remote_login_passwordfile--ALL
Check--419430400--=--pga_aggregate_target--ALL
Check--86400--=--_asm_disk_repair_time--ALL
Check--TRUE--=--_auto_manage_exadata_disks--ALL
Check--FALSE--=--_library_cache_advice--ALL
Check--TRUE--=--_enable_shared_pool_durations--ALL
#Check--TRUE--=--use_large_pages--ALL
Check--10262~trace~name~context~forever,~level~1073741824,~4031~trace~name~systemstate~level~267--=--event--ALL
Check--<IBIPGROUP>--=--cluster_interconnects--ALL
Check--700--=--processes--X2
Check--1500--=--processes--X8
Check--1090519040--=--sga_target--X2
Check--2147483648--=--sga_target--X8
<-- ASM params end -->

<-- CRS CHM Repository begin -->
Check:CHM Repository Size:259200
<-- CRS CHM Repository end -->

<-- DB begin -->
Check status of DB  instance:NORMAL:select active_state from v\\$instance
Check blocking session count:2:<=:select count(*) cnt from v\\$session where blocking_session is not null
Check global blocking session count:2:<=:select count(*) cnt from gv\\$session where blocking_session is not null
#Check bundle patch level:11.2.0.3.BP23:select version||'.'||comments  from registry\\$history where comments='BP23' and rownum < 2
#Check bundle patch level:11.2.0.3.BP22:select version||'.'||comments  from registry\\$history where comments='BP22' and rownum < 2
#Check bundle patch level:11.2.0.4.BP6:select version||'.'||comments  from registry\\$history where comments='BP6' and rownum < 2
#Check bundle patch level:11.2.0.4.BP9:select version||'.'||comments  from registry\\$history where comments='BP9' and rownum < 2
#Check bundle patch level:11.2.0.4.BP15:select version||'.'||comments  from registry\\$history where comments='BP15' and rownum < 2
Check bundle patch level:11.2.0.4.BP16:select version||'.'||comments  from registry\\$history where comments='BP16' and rownum < 2
Check invalid objects:0:=:select count(*) from dba_objects where status='INVALID'
<-- DB end -->

<-- DB Multi begin -->
Check:0:==:select e.name || '~' || count(1) || '###' from v\\\$wait_chains c, v\\\$event_name e where c.wait_event = e.event_id group by e.name
Check:curver:==:select comp_name || '~' || replace(version,'.','') || '###' from dba_registry where comp_name not in ('OWB','Oracle Application Express','Oracle Enterprise Search')
<-- DB Multi end -->

<-- DB params begin -->
Check--0--=--memory_target--ALL
Check--0--=--memory_max_target--ALL
Check--LOCATION=USE_DB_RECOVERY_FILE_DEST--=--log_archive_dest_1--ALL
Check--TRUE--=--_disable_autotune_gtx--ALL
Check--TRUE--=--parallel_force_local--ALL
Check--FALSE--=--_kqr_optimistic_reads--11204
Check--<IBIPGROUP>--=--cluster_interconnects--ALL
Check--140--=--_lm_rcvr_hang_allow_time--ALL
Check--140--=--_kill_diagnostics_timeout--ALL
Check--2143289344--=--_file_size_increase_increment--ALL
Check--0--=--_wcr_control--ALL
Check--8--=--_backup_ksfq_bufcnt_max--ALL
Check--134217728--=--_bct_public_dba_buffer_size--ALL
Check--0--=--_gc_defer_time--ALL
Check--TYPICAL--=--db_block_checksum--ALL
Check--TYPICAL--=--db_lost_write_protect--ALL
Check--SETAll--=--filesystemio_options--ALL
Check--TRUE--=--use_large_pages--ALL
Check--FALSE--=--_b_tree_bitmap_plans--ALL
Check--6708183:ON,~5483301:OFF,~14764840:ON,~17799716:ON,~18115594:ON,~18134680:ON,~19710102:ON,~14545269:OFF--=--_fix_control--11204BP16
Check--6708183:ON,~5483301:OFF,~14764840:ON,~17799716:ON,~18115594:ON,~18134680:ON,~19710102:ON,~14545269:OFF--=--_fix_control--11204BP12
Check--6708183:ON,~5483301:OFF--=--_fix_control--11203
Check--6708183:ON,~5483301:OFF--=--_fix_control--11204BP6
Check--6708183:ON,~5483301:OFF--=--_fix_control--11204BP9
Check--FALSE--=--_optimizer_distinct_agg_transform--ALL
Check--8--=--_ktb_debug_flags--ALL
Check--TRUE--=--_trace_files_public--ALL
Check--TRUE--=--audit_sys_operations--ALL
Check--TRUE--=--log_checkpoints_to_alert--ALL
Check--FALSE--=--db_block_checking--ALL
Check--TRUE--=--disk_asynch_io--ALL
Check--FALSE--=--global_names--ALL
Check--''--=--N/A--os_authent_prefix--ALL
Check--FALSE--=--parallel_adaptive_multi_user--ALL
Check--0--=--parallel_min_servers--ALL
Check--1--=--parallel_threads_per_cpu--ALL
Check--FALSE--=--skip_unusable_indexes--ALL
Check--TRUE--=--sql92_security--ALL
Check--FALSE--=--star_transformation_enabled--ALL
Check--4--=--parallel_max_servers--ALL
Check--100--=--session_max_open_files--ALL
Check--500--=--open_cursors--ALL
Check--500--=--session_cached_cursors--ALL
Check--300--=--fast_start_mttr_target--ALL
Check--10261~trace~name~context~forever,~level~1048576,~10262~trace~name~context~forever,~level~1048576--=--event--ALL
Check--19327352832-->=--sga_target--FUSION
Check--4294967296-->=--sga_target--IDSTORE
Check--4294967296-->=--sga_target--PSTORE
Check--8589934592-->=--pga_aggregate_target--FUSION
Check--2147483648-->=--pga_aggregate_target--IDSTORE
Check--2147483648-->=--pga_aggregate_target--PSTORE
Check--5000-->=--processes--FUSION
Check--2500-->=--processes--IDSTORE
Check--2500-->=--processes--PSTORE
Check--10--=--global_txn_processes--ALL
Check--+DATA--=--db_create_file_dest--ALL
Check--always--=--db_securefile--ALL
Check--2--=--gcs_server_processes--ALL
Check--NATIVE--=--plsql_code_type--ALL
Check--600--=--distributed_lock_timeout--ALL
Check--600--=--_external_scn_logging_threshold_seconds--ALL
Check--TRUE--=--_active_session_legacy_behavior--ALL
Check--FALSE--=--_gc_read_mostly_locking--ALL
Check--FALSE--=--_gc_persistent_read_mostly--ALL
Check--FALSE--=--_diag_proc_enabled--ALL
Check--120--=--_redo_transport_stall_time--ALL
Check--240--=--_redo_transport_stall_time_long--ALL
Check--8--=--db_writer_processes--ALL
Check--7920--=--dml_locks--ALL
Check--10--=--job_queue_processes--ALL
Check--4--=--log_archive_max_processes--ALL
Check--+RECO--=--db_recovery_file_dest--ALL
Check--FALSE--=--_optimizer_ads_use_result_cache--11204
Check--FALSE--=--_enable_NUMA_support--X2
Check--TRUE--=--_enable_NUMA_support--X8
Check--TRUE--=--_client_enable_auto_unregister--11204
Check--NONE--=--audit_trail--ALL
Check--BINARY--=--nls_sort--ALL
# Check--FUSIONAPPS_PLAN--=--resource_manager_plan--ALL
<-- DB params end -->

<-- OS begin -->
TASK:28000
FREESWAP:20
FREEMEM:20
LOADAVG:20
<-- OS end -->

<-- SAAS OS kernel setting for 1T begin -->
fs.aio-max-nr:10485760
kernel.msgmax:8192
kernel.msgmnb:65536
kernel.msgmni:2878
kernel.sem:9000 500000 6010 256
kernel.shmall:1073741824
kernel.shmmax:4398046511104
kernel.shmmni:4096
kernel.randomize_va_space:2
vm.hugetlb_shm_group:1001
vm.min_free_kbytes:4194304
vm.nr_hugepages:275000
<-- SAAS OS kernel setting for 1T end -->

<-- SAAS OS kernel setting for 2T begin -->
fs.aio-max-nr:10485760
kernel.msgmax:8192
kernel.msgmnb:65536
kernel.msgmni:2878
kernel.sem:9000 500000 6010 256
kernel.shmall:1073741824
kernel.shmmax:4398046511104
kernel.shmmni:4096
kernel.randomize_va_space:2
vm.hugetlb_shm_group:1001
vm.min_free_kbytes:4194304
vm.nr_hugepages:500000
<-- SAAS OS kernel setting for 2T end -->

<-- SAAS OS limits setting for 1T begin -->
hard_core:unlimited
hard_memlock:563200000
hard_nofile:131072
hard_nproc:131072
soft_core:unlimited
soft_memlock:563200000
soft_nofile:131072
soft_nproc:131072
<-- SAAS OS limits setting for 1T end -->

<-- SAAS OS limits setting for 2T begin -->
hard_core:unlimited
hard_memlock:1024000000
hard_nofile:131072
hard_nproc:131072
soft_core:unlimited
soft_memlock:1024000000
soft_nofile:131072
soft_nproc:131072
<-- SAAS OS limits setting for 2T end -->

<-- SAAS OS mtu setting begin -->
bondib0:7000
bondib1:7000
bondib2:7000
bondib3:7000
ib0:7000
ib1:7000
ib2:7000
ib3:7000
ib4:7000
ib5:7000
ib6:7000
ib7:7000
<-- SAAS OS mtu setting end -->

<-- X8 OS kernel setting begin -->
fs.aio-max-nr:6291456
kernel.msgmax:8192
kernel.msgmnb:65536
kernel.msgmni:2878
kernel.sem:9000 262144 6010 256
kernel.shmall:1073741824
kernel.shmmax:4398046511104
kernel.shmmni:4096
kernel.randomize_va_space:2
vm.hugetlb_shm_group:1001
vm.min_free_kbytes:524288
vm.nr_hugepages:153600
<-- X8 OS kernel setting end -->

<-- X8 OS limits setting begin -->
hard_core:unlimited
hard_memlock:314572800
hard_nofile:131072
hard_nproc:131072
soft_core:unlimited
soft_memlock:314572800
soft_nofile:131072
soft_nproc:131072
<-- X8 OS limits setting end -->

<-- X2 OS kernel setting begin -->
fs.aio-max-nr:3145728
kernel.msgmax:8192
kernel.msgmnb:65536
kernel.msgmni:2878
kernel.sem:250  32000 100 142
kernel.shmall:1073741824
kernel.shmmax:4398046511104
kernel.shmmni:4096
kernel.randomize_va_space:2
vm.hugetlb_shm_group:1001
vm.min_free_kbytes:524288
vm.nr_hugepages:11264
<-- X2 OS kernel setting end -->

<-- X2 OS limits setting begin -->
hard_core:unlimited
hard_memlock:23068672
hard_nofile:131072
hard_nproc:131072
soft_core:unlimited
soft_memlock:23068672
soft_nofile:131072
soft_nproc:131072
<-- X2 OS limits setting end -->

<-- IB ARP_ANNOUNCE setting begin -->
net.ipv4.conf.ib0.arp_announce:2
net.ipv4.conf.ib1.arp_announce:2
net.ipv4.conf.ib2.arp_announce:2
net.ipv4.conf.ib3.arp_announce:2
net.ipv4.conf.ib4.arp_announce:2
net.ipv4.conf.ib5.arp_announce:2
net.ipv4.conf.ib6.arp_announce:2
net.ipv4.conf.ib7.arp_announce:2
<-- IB ARP_ANNOUNCE setting end -->

<-- IBARP_X8_AA_begin -->
net.ipv4.conf.all.accept_local:1
net.ipv4.conf.all.rp_filter:0
net.ipv4.conf.default.rp_filter:0
net.ipv4.conf.ib0.accept_local:1
net.ipv4.conf.ib0.arp_accept:1
net.ipv4.conf.ib0.arp_announce:2
net.ipv4.conf.ib0.arp_ignore:1
net.ipv4.conf.ib0.rp_filter:0
net.ipv4.conf.ib1.accept_local:1
net.ipv4.conf.ib1.arp_accept:1
net.ipv4.conf.ib1.arp_announce:2
net.ipv4.conf.ib1.arp_ignore:1
net.ipv4.conf.ib1.rp_filter:0
net.ipv4.conf.ib2.accept_local:1
net.ipv4.conf.ib2.arp_accept:1
net.ipv4.conf.ib2.arp_announce:2
net.ipv4.conf.ib2.arp_ignore:1
net.ipv4.conf.ib2.rp_filter:0
net.ipv4.conf.ib3.accept_local:1
net.ipv4.conf.ib3.arp_accept:1
net.ipv4.conf.ib3.arp_announce:2
net.ipv4.conf.ib3.arp_ignore:1
net.ipv4.conf.ib3.rp_filter:0
net.ipv4.conf.ib4.accept_local:1
net.ipv4.conf.ib4.arp_accept:1
net.ipv4.conf.ib4.arp_announce:2
net.ipv4.conf.ib4.arp_ignore:1
net.ipv4.conf.ib4.rp_filter:0
net.ipv4.conf.ib5.accept_local:1
net.ipv4.conf.ib5.arp_accept:1
net.ipv4.conf.ib5.arp_announce:2
net.ipv4.conf.ib5.arp_ignore:1
net.ipv4.conf.ib5.rp_filter:0
net.ipv4.conf.ib6.accept_local:1
net.ipv4.conf.ib6.arp_accept:1
net.ipv4.conf.ib6.arp_announce:2
net.ipv4.conf.ib6.arp_ignore:1
net.ipv4.conf.ib6.rp_filter:0
net.ipv4.conf.ib7.accept_local:1
net.ipv4.conf.ib7.arp_accept:1
net.ipv4.conf.ib7.arp_announce:2
net.ipv4.conf.ib7.arp_ignore:1
net.ipv4.conf.ib7.rp_filter:0
net.ipv4.neigh.ib0.base_reachable_time_ms:10000
net.ipv4.neigh.ib0.delay_first_probe_time:1
net.ipv4.neigh.ib0.locktime:0
net.ipv4.neigh.ib1.base_reachable_time_ms:10000
net.ipv4.neigh.ib1.delay_first_probe_time:1
net.ipv4.neigh.ib1.locktime:0
net.ipv4.neigh.ib2.base_reachable_time_ms:10000
net.ipv4.neigh.ib2.delay_first_probe_time:1
net.ipv4.neigh.ib2.locktime:0
net.ipv4.neigh.ib3.base_reachable_time_ms:10000
net.ipv4.neigh.ib3.delay_first_probe_time:1
net.ipv4.neigh.ib3.locktime:0
net.ipv4.neigh.ib4.base_reachable_time_ms:10000
net.ipv4.neigh.ib4.delay_first_probe_time:1
net.ipv4.neigh.ib4.locktime:0
net.ipv4.neigh.ib5.base_reachable_time_ms:10000
net.ipv4.neigh.ib5.delay_first_probe_time:1
net.ipv4.neigh.ib5.locktime:0
net.ipv4.neigh.ib6.base_reachable_time_ms:10000
net.ipv4.neigh.ib6.delay_first_probe_time:1
net.ipv4.neigh.ib6.locktime:0
net.ipv4.neigh.ib7.base_reachable_time_ms:10000
net.ipv4.neigh.ib7.delay_first_probe_time:1
net.ipv4.neigh.ib7.locktime:0
<-- IBARP_X8_AA_end -->

<-- IBARP_X8_AB_begin -->
net.ipv4.conf.all.accept_local:1
net.ipv4.conf.all.rp_filter:0
net.ipv4.conf.bondib0.arp_accept:1
net.ipv4.conf.bondib0.arp_ignore:1
net.ipv4.conf.bondib0.rp_filter:0
net.ipv4.conf.bondib1.arp_accept:1
net.ipv4.conf.bondib1.arp_ignore:1
net.ipv4.conf.bondib1.rp_filter:0
net.ipv4.conf.bondib2.arp_accept:1
net.ipv4.conf.bondib2.arp_ignore:1
net.ipv4.conf.bondib2.rp_filter:0
net.ipv4.conf.bondib3.arp_accept:1
net.ipv4.conf.bondib3.arp_ignore:1
net.ipv4.conf.bondib3.rp_filter:0
net.ipv4.conf.default.rp_filter:0
net.ipv4.neigh.bondib0.base_reachable_time_ms:10000
net.ipv4.neigh.bondib0.delay_first_probe_time:1
net.ipv4.neigh.bondib0.locktime:0
net.ipv4.neigh.bondib1.base_reachable_time_ms:10000
net.ipv4.neigh.bondib1.delay_first_probe_time:1
net.ipv4.neigh.bondib1.locktime:0
net.ipv4.neigh.bondib2.base_reachable_time_ms:10000
net.ipv4.neigh.bondib2.delay_first_probe_time:1
net.ipv4.neigh.bondib2.locktime:0
net.ipv4.neigh.bondib3.base_reachable_time_ms:10000
net.ipv4.neigh.bondib3.delay_first_probe_time:1
net.ipv4.neigh.bondib3.locktime:0
<-- IBARP_X8_AB_end -->

<-- IBARP_X2_AA_begin -->
net.ipv4.conf.all.accept_local:1
net.ipv4.conf.all.rp_filter:0
net.ipv4.conf.default.rp_filter:0
net.ipv4.conf.ib0.accept_local:1
net.ipv4.conf.ib0.arp_accept:1
net.ipv4.conf.ib0.arp_ignore:1
net.ipv4.conf.ib0.rp_filter:0
net.ipv4.conf.ib1.accept_local:1
net.ipv4.conf.ib1.arp_accept:1
net.ipv4.conf.ib1.arp_ignore:1
net.ipv4.conf.ib1.rp_filter:0
net.ipv4.neigh.ib0.base_reachable_time_ms:10000
net.ipv4.neigh.ib0.delay_first_probe_time:1
net.ipv4.neigh.ib0.locktime:0
net.ipv4.neigh.ib1.base_reachable_time_ms:10000
net.ipv4.neigh.ib1.delay_first_probe_time:1
net.ipv4.neigh.ib1.locktime:0
<-- IBARP_X2_AA_end -->

<-- IBARP_X2_AB_begin -->
net.ipv4.conf.bondib0.arp_accept:1
net.ipv4.conf.bondib0.arp_ignore:1
net.ipv4.conf.default.rp_filter:1
net.ipv4.neigh.bondib0.base_reachable_time_ms:10000
net.ipv4.neigh.bondib0.delay_first_probe_time:1
net.ipv4.neigh.bondib0.locktime:0
<-- IBARP_X2_AB_end -->

<--- BEGIN TOPRC -->
RCfile for "top with windows"           # shameless braggin'
Id:a, Mode_altscr=0, Mode_irixps=1, Delay_time=3.000, Curwin=0
Def     fieldscur=AEHIOQTWKNMbcdfgjplrsuvyzX
        winflags=62905, sortindx=10, maxtasks=0
        summclr=1, msgsclr=1, headclr=3, taskclr=1
Job     fieldscur=ABcefgjlrstuvyzMKNHIWOPQDX
        winflags=62777, sortindx=0, maxtasks=0
        summclr=6, msgsclr=6, headclr=7, taskclr=6
Mem     fieldscur=ANOPQRSTUVbcdefgjlmyzWHIKX
        winflags=62777, sortindx=13, maxtasks=0
        summclr=5, msgsclr=5, headclr=4, taskclr=5
Usr     fieldscur=ABDECGfhijlopqrstuvyzMKNWX
        winflags=62777, sortindx=4, maxtasks=0
        summclr=3, msgsclr=3, headclr=2, taskclr=3
<--- END TOPRC -->

