#!/usr/bin/env bash

# menu
echo "=========================================================="
echo "Enter one of the following actions or press CTRL-D to exit."
echo "M - map and create your environment"
echo "F - find database config  file"
echo "S - Show your current database and status"
echo "X - go to advanced menu"
echo "=========================================================="
#Read and validate action value
while read action; 
do
    case $action in
        [Mm])
            # map and create environment
            bash MAPS.bash
            ;;
        [Ff])
            # find database
            bash find.bash
            ;;
        [Ss])
            # show env
            bash startup.bash 
            ;;
        [Xx])
            # advanced
            bash xterm.bash
            ;;
        *)
            #Display error message
            echo "Error: invalid action value"
            ;;
    esac
    
    #Re-display the action menu, after completing the action
    echo ""
    echo "Enter one of the following actions or press CTRL-D to exit."
    echo "M - map and create your environment"
    echo "F - find database config file"
    echo "S - Show your current database and status" 
    echo "X - go to advanced menu"
 done
