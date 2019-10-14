#!/bin/sh
echo "zzz ***"`date '+%a %b %e %T %Z %Y'` >> $1
uptime >> $1
