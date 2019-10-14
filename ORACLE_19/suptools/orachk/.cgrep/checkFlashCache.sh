#!/bin/bash

#################################################################
#                                                               #
#  Purpose: Check the flashcache size in effect for a cell      #
#           against the expected flash cache size for the cell  #
#                                                               #
#################################################################

## Variable declarations

CellcliOutput=$(cellcli -e "list cell detail;list flashlog detail;list celldisk detail;list flashcache detail")      
NumHardDisks=$(echo "$CellcliOutput"|grep -w HardDisk|wc -l)      
NumFlashDisks=$(echo "$CellcliOutput"|grep -w FlashDisk|wc -l)      
IsFlashCacheCompressionEnabled=$(echo "$CellcliOutput"|grep flashCacheCompress|grep -wc TRUE)      
IsFlashLogEnabled=$(echo "$CellcliOutput"|grep -c FLASHLOG)      
ActualFlashCacheSize=$(echo "$CellcliOutput"|grep -w effectiveCacheSize|awk '{print $2}')      
AllFlash=$(echo "$CellcliOutput"|grep -w makeModel|egrep  -ic 'ALLFLASH|EXTREME_FLASH') 
      
CellHardware=$(/usr/sbin/exadata.img.hw --get model)
if [[ -z ${CellHardware} ]]
then
  CellHardware=$(/usr/sbin/dmidecode --string system-product-name)
fi
CellHardwareX3=$(echo $CellHardware|grep -wci "SUN FIRE X4[1-2]70 M3")       
CellHardwareX4=$(echo $CellHardware|grep -ci "SUN SERVER X4-2")
CellHardwareX5=$(echo $CellHardware|grep -ci "ORACLE SERVER X5-2")       
CellHardwareX6=$(echo $CellHardware|grep -ci "ORACLE SERVER X6-2")       
CellHardwareX7=$(echo $CellHardware|grep -ci "ORACLE SERVER X7-2")       

ZDRLADiskFound=$(cellcli -e list griddisk|grep -q "CATALOG_CD_" && echo "1" || echo "0")

if [ $CellHardwareX7 -eq "1" ] && [ $NumFlashDisks -eq "2" ] && [ $ZDRLADiskFound -eq "1" ]
then
  isZDLRA=1
else
  isZDLRA=0
fi

if [ -z $ActualFlashCacheSize ]
then
  export ActualFlashCacheSize=0
fi

## Function Definitions

usage()
{
  echo "Usage: checkflashcache.sh [-o check|report] [-h]";
}

check_main()
{
if [ $CellHardwareX3 -eq 1 ]       
then       
  if [ $NumHardDisks -eq 6 ] && [ $NumFlashDisks -eq 8 ]       
  then       
    if [ $IsFlashCacheCompressionEnabled -eq 1 ] && [ $IsFlashLogEnabled -eq 1 ]       
    then       
      FlashCacheSizeG=1489.125       
      FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    elif [ $IsFlashCacheCompressionEnabled -eq 1 ] && [ $IsFlashLogEnabled -eq 0 ]       
    then       
      FlashCacheSizeG=1489.625       
      FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    elif [ $IsFlashCacheCompressionEnabled -eq 0 ] && [ $IsFlashLogEnabled -eq 1 ]       
    then       
      FlashCacheSizeG=744.125       
      FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    elif [ $IsFlashCacheCompressionEnabled -eq 0 ] && [ $IsFlashLogEnabled -eq 0 ]       
    then       
      FlashCacheSizeG=744.625       
      FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    fi       
  else       
    if [ $IsFlashCacheCompressionEnabled -eq 1 ] && [ $IsFlashLogEnabled -eq 1 ]       
    then       
      FlashCacheSizeG=2978.75       
      FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    elif [ $IsFlashCacheCompressionEnabled -eq 1 ] && [ $IsFlashLogEnabled -eq 0 ]       
    then       
      FlashCacheSizeG=2979.25       
      FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    elif [ $IsFlashCacheCompressionEnabled -eq 0 ] && [ $IsFlashLogEnabled -eq 1 ]       
    then       
      FlashCacheSizeG=1488.75       
      FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    elif [ $IsFlashCacheCompressionEnabled -eq 0 ] && [ $IsFlashLogEnabled -eq 0 ]       
    then       
      FlashCacheSizeG=1489.25       
      FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    fi       
  fi       
elif [ $CellHardwareX4 -eq 1 ]       
then       
  if [ $NumHardDisks -eq 6 ] && [ $NumFlashDisks -eq 8 ]       
  then       
       
if [ $IsFlashCacheCompressionEnabled -eq 1 ] && [ $IsFlashLogEnabled -eq 1 ]       
    then       
      FlashCacheSizeG=2979.25       
      FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    elif [ $IsFlashCacheCompressionEnabled -eq 1 ] && [ $IsFlashLogEnabled -eq 0 ]       
    then       
      FlashCacheSizeG=2979.75       
      FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    elif [ $IsFlashCacheCompressionEnabled -eq 0 ] && [ $IsFlashLogEnabled -eq 1 ]       
    then       
      FlashCacheSizeG=1489.125       
      FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    elif [ $IsFlashCacheCompressionEnabled -eq 0 ] && [ $IsFlashLogEnabled -eq 0 ]       
    then       
      FlashCacheSizeG=1489.625       
      FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    fi       
  else       
    if [ $IsFlashCacheCompressionEnabled -eq 1 ] && [ $IsFlashLogEnabled -eq 1 ]       
    then       
      FlashCacheSizeG=5959       
      FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    elif [ $IsFlashCacheCompressionEnabled -eq 1 ] && [ $IsFlashLogEnabled -eq 0 ]       
    then       
      FlashCacheSizeG=5959.5       
      FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    elif [ $IsFlashCacheCompressionEnabled -eq 0 ] && [ $IsFlashLogEnabled -eq 1 ]       
    then       
      FlashCacheSizeG=2978.75       
      FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    elif [ $IsFlashCacheCompressionEnabled -eq 0 ] && [ $IsFlashLogEnabled -eq 0 ]       
    then       
      FlashCacheSizeG=2979.25       
      FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    fi       
  fi
elif [ $CellHardwareX5 -eq 1 ]       
then
  if [ $AllFlash -eq 0 ]
  then      
    if [ $NumHardDisks -eq 6 ] && [ $NumFlashDisks -eq 2 ]       
    then       
      if [ $IsFlashLogEnabled -eq 1 ]       
      then       
        FlashCacheSizeT=2.910369873046875
        FlashCacheSizeG=$(echo $FlashCacheSizeT \* 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
      else
        FlashCacheSizeT=2.910858154296875
        FlashCacheSizeG=$(echo $FlashCacheSizeT \* 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
      fi       
    else
      if [ $IsFlashLogEnabled -eq 1 ]       
      then       
        FlashCacheSizeT=5.82122802734375       
        FlashCacheSizeG=$(echo $FlashCacheSizeT \* 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
      else
        FlashCacheSizeT=5.82171630859375       
        FlashCacheSizeG=$(echo $FlashCacheSizeT \* 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
      fi       
    fi
  else
    if [ $NumFlashDisks -eq 4 ]
    then
      FlashCacheSizeG=298.0625
      FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    else
      FlashCacheSizeG=596.125
      FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    fi
  fi                
elif [ $CellHardwareX6 -eq 1 ]       
then
  if [ $AllFlash -eq 0 ]
  then      
    if [ $NumHardDisks -eq 6 ] && [ $NumFlashDisks -eq 2 ]       
    then       
      if [ $IsFlashLogEnabled -eq 1 ]       
      then       
        FlashCacheSizeT=5.821319580078125
        FlashCacheSizeG=$(echo $FlashCacheSizeT \* 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
      else
        FlashCacheSizeT=5.821807861328125
        FlashCacheSizeG=$(echo $FlashCacheSizeT \* 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
      fi       
    else
      if [ $IsFlashLogEnabled -eq 1 ]       
      then       
        FlashCacheSizeT=11.64312744140625
        FlashCacheSizeG=$(echo $FlashCacheSizeT \* 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
      else
        FlashCacheSizeT=11.64361572265625
        FlashCacheSizeG=$(echo $FlashCacheSizeT \* 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
      fi       
    fi
  else
    if [ $NumFlashDisks -eq 4 ]
    then
      FlashCacheSizeT=0.5821533203125
      FlashCacheSizeG=$(echo $FlashCacheSizeT \* 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    else
      FlashCacheSizeT=1.164306640625
      FlashCacheSizeG=$(echo $FlashCacheSizeT \* 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    fi
  fi                
elif [ $CellHardwareX7 -eq 1 ]       
then
  if [ $AllFlash -eq 0 ] && [ $isZDLRA -eq 0 ]
  then      
    if [ $IsFlashLogEnabled -eq 1 ]       
    then       
      FlashCacheSizeT=23.28692626953125
      FlashCacheSizeG=$(echo $FlashCacheSizeT \* 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    else
      FlashCacheSizeT=23.28741455078125
      FlashCacheSizeG=$(echo $FlashCacheSizeT \* 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    fi       
  elif [ $isZDLRA -eq 1 ]
  then      
    if [ $IsFlashLogEnabled -eq 1 ]       
    then       
      FlashCacheSizeT=11.643218994140625
      FlashCacheSizeG=$(echo $FlashCacheSizeT \* 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    else
      FlashCacheSizeT=11.643707275390625
      FlashCacheSizeG=$(echo $FlashCacheSizeT \* 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
    fi       
  else
    FlashCacheSizeT=2.3287353515625
    FlashCacheSizeG=$(echo $FlashCacheSizeT \* 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
  fi
else       
  if [ $IsFlashLogEnabled -eq 1 ]       
  then       
    FlashCacheSizeG=364.75       
    FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
  elif [ $IsFlashLogEnabled -eq 0 ]       
  then       
    FlashCacheSizeG=365.25       
    FlashCacheSizeT=$(echo $FlashCacheSizeG / 1024|bc -l|awk '{ if ($0 ~ /\./){ sub("0*$","",$0);} print}')
  fi       
fi       
FlashCacheSize_in_G=$(echo $FlashCacheSizeG)G
FlashCacheSize_in_T=$(echo $FlashCacheSizeT)T
}

print_result()
{
if [ $ActualFlashCacheSize == $FlashCacheSize_in_G ] || [ $ActualFlashCacheSize == $FlashCacheSize_in_T ]       
then       
  echo 0       
else       
  echo 1       
fi 
}

print_report()
{
  LineNumFC=$(echo "$CellcliOutput"|nl|grep FLASHCACHE|awk '{print $1}')
  TotalLn=$(echo "$CellcliOutput"|grep -v ^$|wc -l|awk '{print $1}')
  LinesToPrint=$(expr $TotalLn - $LineNumFC + 1)
  report_command1=$(echo "$CellcliOutput"|tail -$LinesToPrint)
  report_command2=$(echo -e "\nThe Flashcache size should be :  "$FlashCacheSize_in_G or $FlashCacheSize_in_T)
  report_command3=$(echo -e "\nThe Flashcache size found is :  "$ActualFlashCacheSize)
  echo -e "$report_command1\n$report_command2\n$report_command3"
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

