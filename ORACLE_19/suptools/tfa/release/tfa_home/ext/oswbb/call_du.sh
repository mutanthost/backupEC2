#!/bin/sh
echo "zzz ***"`date '+%a %b %e %T %Z %Y'` >> $1
du >> $1
