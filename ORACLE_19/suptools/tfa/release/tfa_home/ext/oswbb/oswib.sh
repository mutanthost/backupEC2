#!/bin/sh
#
# IB Diagnostics
#
#
echo "zzz ***"`date` >> $1
echo "IB Config on Hosts..." >> $1
echo "ibconfig...." >> $1
ifconfig >> $1
echo "" >> $1
echo "ib-bond..." >> $1
ib-bond --status >> $1
echo "" >> $1
echo "ibstat..." >> $1
ibstat >> $1
echo "" >> $1
echo "ibstatus..." >> $1
ibstatus >> $1
echo "" >> $1
echo "lspci -vv..." >> $1
lspci -vv |grep InfiniBand -A27 >> $1
echo "" >> $1
rm locks/iblock.file
