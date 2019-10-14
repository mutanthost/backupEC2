#!/bin/bash
#
# $Header: tfa/src/orachk/src/checkHiddenParams.sh /main/7 2017/08/30 08:25:03 rojuyal Exp $
#
# checkHiddenParams.sh
#
# Copyright (c) 2015, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      checkHiddenParams.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    cgirdhar    12/01/16 - Adding support for checking hidden parameters on
#                           12.2
#    cgirdhar    07/01/15 - Script to check hidden parameter usage for RDBMS
#                           and ASM on Exadata
#    cgirdhar    07/01/15 - Creation
#


########################################################################################
#										       #
#  Purpose: Check database underscore parameters are set as per the recommendations    #
#  Usage: CheckHiddenParamsRdbms.sh [-o check|report] [-h]				       #
#										       #
########################################################################################


## Variable Declarations

CheckStatus=0
ReportMessage=""
ArrayName=""
ExpectedValue=""
AWK=$(command -v gawk 2>/dev/null)
if [ ! -f "$AWK" ];then  AWK=awk;fi

## Function Definitions

usage()
{
  echo "Usage: checkHiddenParamsRdbms.sh [-t asm|rdbms -o check|report] [-h]";
}

getParmValue() 
{
  ExpectedValue=""
  ParmFound=0
  ArrayName=$1
  ParmName=$2
  if [ -z $ParmName ]
  then
    return
  fi
  NumElements=$(eval echo \${#$ArrayName[@]})
  for ((index=0; index < $NumElements; index++));
  do 
    if [[ $(expr $index % 2) -eq 0 ]]
    then
      if [ "$(eval echo \${$ArrayName[$index]})" = "$ParmName" ];
      then
        ExpectedValue="$(eval echo \${$ArrayName[$(expr $index + 1)]})"
        echo $ExpectedValue
        ParmFound=1
      fi
    fi
  done

  if [ $ParmFound -eq 0 ] && [ "$ParmName" != "_enable_NUMA_support" ]
  then
    echo "ParameterNotExpected"
  fi
}

check_main_rdbms()
{

  ## Populate Arrays with allowed underscore parameters along with their values
  
  ## Array for Versions 11.2.0.3.11+
  
  ArrayAbove1120311[0]="_smm_auto_max_io_size"
  ArrayAbove1120311[1]="1024"
  ArrayAbove1120311[2]="_backup_disk_bufcnt"
  ArrayAbove1120311[3]="64"
  ArrayAbove1120311[4]="_backup_disk_bufsz"
  ArrayAbove1120311[5]="1048576"
  ArrayAbove1120311[6]="_backup_file_bufcnt"
  ArrayAbove1120311[7]="64"
  ArrayAbove1120311[8]="_backup_file_bufsz"
  ArrayAbove1120311[9]="1048576"
#  ArrayAbove1120311[10]="_enable_NUMA_support"
#  ArrayAbove1120311[11]="FALSE"
  
  ## Array for Versions below 11.2.0.3 BP11 and above 11.2.0.1.0
  
  Arraybelow1120311[0]="_file_size_increase_increment"
  Arraybelow1120311[1]="2143289344"
  Arraybelow1120311[2]="_smm_auto_max_io_size"
  Arraybelow1120311[3]="1024"
  Arraybelow1120311[4]="_backup_disk_bufcnt"
  Arraybelow1120311[5]="64"
  Arraybelow1120311[6]="_backup_disk_bufsz"
  Arraybelow1120311[7]="1048576"
  Arraybelow1120311[8]="_backup_file_bufcnt"
  Arraybelow1120311[9]="64"
  Arraybelow1120311[10]="_backup_file_bufsz"
  Arraybelow1120311[11]="1048576"
#  Arraybelow1120311[12]="_enable_NUMA_support"
#  Arraybelow1120311[13]="FALSE"
  
  ## Array for Versions below 11.2.0.1.0
  
  Arraybelow112[0]="_backup_disk_bufcnt"
  Arraybelow112[1]="64"
  Arraybelow112[2]="_backup_disk_bufsz"
  Arraybelow112[3]="1048576"
  Arraybelow112[4]="_backup_file_bufcnt"
  Arraybelow112[5]="64"
  Arraybelow112[6]="_backup_file_bufsz"
  Arraybelow112[7]="1048576"
  Arraybelow112[8]="_file_size_increase_increment"
  Arraybelow112[9]="2143289344"
#  Arraybelow112[10]="_enable_NUMA_support"
#  Arraybelow112[11]="FALSE"

  ## Array for Versions above 12.1.0.1.0 and below 12.2.0.1.0
  
  ArrayAbove121010[0]="_parallel_adaptive_max_users"
  ArrayAbove121010[1]="2"

  ## Array for Versions 12.2.0.1.0+
  
  ArrayAbove122010[0]="_backup_disk_bufcnt"
  ArrayAbove122010[1]="64"
  ArrayAbove122010[2]="_backup_disk_bufsz"
  ArrayAbove122010[3]="1048576"
  ArrayAbove122010[4]="_backup_file_bufcnt"
  ArrayAbove122010[5]="64"
  ArrayAbove122010[6]="_backup_file_bufsz"
  ArrayAbove122010[7]="1048576"
  ArrayAbove122010[8]="_assm_segment_repair_bg"
  ArrayAbove122010[9]="FALSE"
  ArrayAbove122010[10]="_parallel_adaptive_max_users"
  ArrayAbove122010[11]="2"

  DatabaseRelease=$($ORACLE_HOME/OPatch/opatch lsinventory|grep "Oracle Database"|$AWK '{print $4}')
  PatchLevel=$($ORACLE_HOME/OPatch/opatch lspatches|grep -w "DATABASE BUNDLE PATCH"|$AWK -F ":" '{print substr($2,2,10)}'|tr -d ".")
  
  #DatabaseRelease=12.1.0.2.0
  #PatchLevel=121027
  
  if [ -z $PatchLevel ]
  then
    PatchLevel=$(echo $DatabaseRelease|tr -d ".")
  fi
  
  if [ ${#PatchLevel} -eq 6 ]
  then
    PatchLevel=$(echo $PatchLevel|$AWK '{print substr($0,1,5)"0"substr($0,6,1)}')
  fi

sqlCmd_rdbms=$($ORACLE_HOME/bin/sqlplus -s "/ as sysdba"<<EOF1
set pages
set head off
set recsep off
set feedback off
select name,value from v\$parameter where substr(name,1,1)='_' order by name;
EOF1
)

idx_rdbms=0

while read line_rdbms
do
HiddenParmValueList[$idx_rdbms]=$line_rdbms
idx_rdbms=$(expr $idx_rdbms + 1)
done << EOF
$(echo "$sqlCmd_rdbms")
EOF

#  readarray -t HiddenParmValueList <<< "$(sqlplus -s "/ as sysdba" <<EOF
#  set pages
#  set head off
#  set recsep off
#  set feedback off
#  select name,value from v\$parameter where substr(name,1,1)='_' order by name;
#EOF
#  )"
  
  ## Check For Version which is 11.2 but below 11.2.0.3 BP11
  
  if [ $PatchLevel -le 1120311 ] && [ $PatchLevel -ge 1120100 ]
  then
    ArrayToPrint=Arraybelow1120311
    for ((idx=0; idx < ${#HiddenParmValueList[@]}; idx+=2));
    do
      ParmName=${HiddenParmValueList[$idx]}
      ParmValue=${HiddenParmValueList[$(expr $idx + 1)]}
      if [[ $(expr $idx % 2) -eq 0 ]]
      then
        ExpectedParmValue=$(getParmValue $ArrayToPrint $ParmName)
#        if [ "$ExpectedParmValue" = "ParameterNotExpected" ] || [[ ("$ExpectedParmValue" != "$ParmValue") && ("$ParmName" != "_enable_NUMA_support") ]]
#        then
#          CheckStatus=1
#          ReportMessage="$ParmName is Not Expected or has an incorrect Value"\n"$ReportMessage"
#        fi
         if [ "$ExpectedParmValue" = "ParameterNotExpected" ]
         then
           CheckStatus=1
	   ReportMessage="$ParmName is Not Expected to be set at all\n$ReportMessage"
         elif [[ ("$ExpectedParmValue" != "$ParmValue") && ("$ParmName" != "_enable_NUMA_support") ]]
         then
            ReportMessage="$ParmName has an incorrect Value of $ParmValue\n$ReportMessage"
         fi
      fi
    done
  fi
  
  ## Check For Version which is below 11.2
  
  if [ $PatchLevel -lt 1120100 ]
  then
    ArrayToPrint=Arraybelow112
    for ((idx=0; idx < ${#HiddenParmValueList[@]}; idx+=2));
    do
      ParmName=${HiddenParmValueList[$idx]}
      ParmValue=${HiddenParmValueList[$(expr $idx + 1)]}
      if [[ $(expr $idx % 2) -eq 0 ]]
      then
        ExpectedParmValue=$(getParmValue $ArrayToPrint $ParmName)
#        if [ "$ExpectedParmValue" = "ParameterNotExpected" ] || [[ ("$ExpectedParmValue" != "$ParmValue") && ("$ParmName" != "_enable_NUMA_support") ]]
#        then
#          CheckStatus=1
#          ReportMessage="$ParmName is Not Expected or has an incorrect Value"\n"$ReportMessage"
#        fi
         if [ "$ExpectedParmValue" = "ParameterNotExpected" ]
         then
           CheckStatus=1
           ReportMessage="$ParmName is Not Expected to be set at all\n$ReportMessage"
         elif [[ ("$ExpectedParmValue" != "$ParmValue") && ("$ParmName" != "_enable_NUMA_support") ]]
         then
            ReportMessage="$ParmName has an incorrect Value of $ParmValue\n$ReportMessage"
         fi
      fi
    done
  fi
  
  ## Check For Version which is above 11.2.0.3 BP11
  
  if [ $PatchLevel -gt 1120311 ] && [ $PatchLevel -lt 1210100 ]
  then
    ArrayToPrint=ArrayAbove1120311
    for ((idx=0; idx < ${#HiddenParmValueList[@]}; idx+=2));
    do
      ParmName=${HiddenParmValueList[$idx]}
      ParmValue=${HiddenParmValueList[$(expr $idx + 1)]}
      if [[ $(expr $idx % 2) -eq 0 ]]
      then
        ExpectedParmValue=$(getParmValue $ArrayToPrint $ParmName)
#        if [ "$ExpectedParmValue" = "ParameterNotExpected" ] || [[ ("$ExpectedParmValue" != "$ParmValue") && ("$ParmName" != "_enable_NUMA_support") ]]
#        then
#          CheckStatus=1
#          ReportMessage="$ParmName is Not Expected or has an incorrect Value\n$ReportMessage"
#        fi
         if [ "$ExpectedParmValue" = "ParameterNotExpected" ]
         then
           CheckStatus=1
           ReportMessage="$ParmName is Not Expected to be set at all\n$ReportMessage"
         elif [[ ("$ExpectedParmValue" != "$ParmValue") && ("$ParmName" != "_enable_NUMA_support") ]]
         then
            ReportMessage="$ParmName has an incorrect Value of $ParmValue\n$ReportMessage"
         fi
      fi
    done
  fi

  if [ $PatchLevel -ge 1210100 ] && [ $PatchLevel -lt 1220100 ]
  then
    ArrayToPrint=ArrayAbove121010
    for ((idx=0; idx < ${#HiddenParmValueList[@]}; idx+=2));
    do
      ParmName=${HiddenParmValueList[$idx]}
      ParmValue=${HiddenParmValueList[$(expr $idx + 1)]}
      if [[ $(expr $idx % 2) -eq 0 ]]
      then
        ExpectedParmValue=$(getParmValue $ArrayToPrint $ParmName)
#        if [ "$ExpectedParmValue" = "ParameterNotExpected" ] || [[ ("$ExpectedParmValue" != "$ParmValue") && ("$ParmName" != "_enable_NUMA_support") ]]
#        then
#          CheckStatus=1
#          ReportMessage="$ParmName is Not Expected or has an incorrect Value\n$ReportMessage"
#        fi
         if [ "$ExpectedParmValue" = "ParameterNotExpected" ]
         then
           CheckStatus=1
           ReportMessage="$ParmName is Not Expected to be set at all\n$ReportMessage"
         elif [[ ("$ExpectedParmValue" != "$ParmValue") && ("$ParmName" != "_enable_NUMA_support") ]]
         then
            ReportMessage="$ParmName has an incorrect Value of $ParmValue\n$ReportMessage"
         fi
      fi
    done
  fi

  if [ $PatchLevel -ge 1220100 ]
  then
    ArrayToPrint=ArrayAbove122010
    for ((idx=0; idx < ${#HiddenParmValueList[@]}; idx+=2));
    do
      ParmName=${HiddenParmValueList[$idx]}
      ParmValue=${HiddenParmValueList[$(expr $idx + 1)]}
      if [[ $(expr $idx % 2) -eq 0 ]]
      then
        ExpectedParmValue=$(getParmValue $ArrayToPrint $ParmName)
#        if [ "$ExpectedParmValue" = "ParameterNotExpected" ] || [[ ("$ExpectedParmValue" != "$ParmValue") && ("$ParmName" != "_enable_NUMA_support") ]]
#        then
#          CheckStatus=1
#          ReportMessage="$ParmName is Not Expected or has an incorrect Value\n$ReportMessage"
#        fi
         if [ "$ExpectedParmValue" = "ParameterNotExpected" ]
         then
           CheckStatus=1
           ReportMessage="$ParmName is Not Expected to be set at all\n$ReportMessage"
         elif [[ ("$ExpectedParmValue" != "$ParmValue") && ("$ParmName" != "_enable_NUMA_support") ]]
         then
            ReportMessage="$ParmName has an incorrect Value of $ParmValue\n$ReportMessage"
         fi
      fi
    done
  fi
}
  
check_main_asm()
{

  ## Populate Array with allowed underscore parameter(s) along with their values

  ## Array for Version 12.1.0.1

  Array12101[0]="_asm_resyncckpt"
  Array12101[1]="0"

  GIRelease=$($ORACLE_HOME/OPatch/opatch lsinventory|grep "Oracle Grid Infrastructure"|$AWK '{print $5}')

sqlCmd_asm=$($ORACLE_HOME/bin/sqlplus -s "/ as sysdba"<<EOF1
set pages
set head off
set recsep off
set feedback off
select name,value from v\$parameter where substr(name,1,1)='_' order by name;
EOF1
)

idx_asm=0

while read line_asm
do
HiddenParmValueList[$idx_asm]=$line_asm
idx_asm=$(expr $idx_asm + 1)
done << EOF
$(echo "$sqlCmd_asm")
EOF

#  readarray -t HiddenParmValueList <<< "$(sqlplus -s "/ as sysasm" <<EOF
#  set pages
#  set head off
#  set recsep off
#  set feedback off
#  select name,value from v\$parameter where substr(name,1,1)='_' order by name;
#EOF
#  )"
  
  ## Check For Version 12.1.0.1
  
  if [ $GIRelease == "12.1.0.1.0" ]
  then
    ArrayToPrint=Array12101
    for ((idx=0; idx < ${#HiddenParmValueList[@]}; idx+=2));
    do
      ParmName=${HiddenParmValueList[$idx]}
      ParmValue=${HiddenParmValueList[$(expr $idx + 1)]}
      if [[ $(expr $idx % 2) -eq 0 ]]
      then
        ExpectedParmValue=$(getParmValue $ArrayToPrint $ParmName)
#        if [ "$ExpectedParmValue" = "ParameterNotExpected" ] || [ "$ExpectedParmValue" != "$ParmValue" ]
#        then
#          CheckStatus=1
#          ReportMessage="$ParmName is Not Expected or has an incorrect Value\n$ReportMessage"
#        fi
         if [ "$ExpectedParmValue" = "ParameterNotExpected" ]
         then
           CheckStatus=1
           ReportMessage="$ParmName is Not Expected to be set at all\n$ReportMessage"
         elif [ "$ExpectedParmValue" != "$ParmValue" ]
         then
            ReportMessage="$ParmName has an incorrect Value of $ParmValue\n$ReportMessage"
         fi
      fi
    done
  else
    if [ ${#HiddenParmValueList[@]} -gt 1 ]
    then
      CheckStatus=1
    fi
  fi
}

print_result_rdbms()
{
 echo $CheckStatus;
}

print_result_asm()
{
 echo $CheckStatus;
}

print_report_rdbms()
{
  if [[ ! -z $ReportMessage ]]
  then
    echo -e "\nThe Following Underscore Parameters are incorrectly set"
    echo -e "--------------------------------------------------------\n"
    echo -e "$ReportMessage"
  else
    echo -e "The set underscore parameters meet expectations\n"
  fi
  echo -e "For this version of the database, the allowed underscore parameters along with their recommended values are :\n"
  ReportVar=$(eval echo \${$ArrayToPrint[@]})
  ReportToPrint=$(echo $ReportVar|sed 's/'" "_'/\n'_'/g')
  echo -e "$ReportToPrint"
}

print_report_asm()
{
  if [ $GIRelease == "12.1.0.1.0" ]
  then
    if [[ ! -z $ReportMessage ]]
    then
      echo -e "\nThe Following Underscore Parameters are incorrectly set"
      echo -e "--------------------------------------------------------\n"
      echo -e "$ReportMessage"
    else
      echo -e "The set underscore parameters meet expectations\n"
    fi
     echo -e "For this version of ASM, the allowed underscore parameters along with their recommended values are :\n"
     ReportVar=$(eval echo \${$ArrayToPrint[@]})
     ReportToPrint=$(echo $ReportVar|sed 's/'" "_'/\n'_'/g')
     echo -e "$ReportToPrint"
  else
    echo -e "For this version of ASM, no underscore parameters should be set"
    if [ ${#HiddenParmValueList[@]} -gt 1 ]
    then
      echo -e "However, the following underscore parameters are set which should be unset"
      ReportVar=${HiddenParmValueList[@]}
      ReportToPrint=$(echo $ReportVar|sed 's/'" "_'/\n'_'/g')
      echo -e "$ReportToPrint"
    else
      echo -e "Test Passed. No ASM underscore parmaters are set"
    fi
  fi
}

NumArgs=$#

if [ $NumArgs -lt 1 ]
then
  echo "Invalid or missing command line arguments..."
  usage;
  exit 1
fi

while getopts "t:o:h" opt;
do
  case "${opt}" in
    h) usage;
       exit 0
       ;;
    t)
       InstType=${OPTARG};
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

if [ -z $InstType ] || [ -z $swch ]
then
   echo "Invalid or missing command line arguments..."
   usage;
   exit 1
fi

if [ -z $ORACLE_SID ] || [ -z ORACLE_HOME ]
then
  echo "Either ORACLE_HOME or ORACLE_SID is not set"
  exit 1
fi

if [ $InstType == "asm" ]
then
  if [ $swch == "check" ]
  then
    check_main_asm;
    print_result_asm;
  elif [ $swch == "report" ]
  then
    check_main_asm;
    print_report_asm;
  else
    echo "Invalid or missing command line arguments..."
    usage;
    exit 1
  fi
elif [ $InstType == "rdbms" ]
then
  if [ $swch == "check" ]
  then
    check_main_rdbms;
    print_result_rdbms;
  elif [ $swch == "report" ]
  then
    check_main_rdbms;
    print_report_rdbms;
  else
    echo "Invalid or missing command line arguments..."
    usage;
    exit 1
  fi
else
  echo "Invalid or missing command line arguments..."
  usage;
  exit 1

fi
