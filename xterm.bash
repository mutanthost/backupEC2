#!/usr/bin/env bash
DATE=$(date +"%Y-%m-%d-%H:%M")
export DATE
/opt/X11/bin/xterm -fg GREEN -bg BLACK -lf $PWD/logs/$DATE-xterm.log -e $PWD/advanced.bash &