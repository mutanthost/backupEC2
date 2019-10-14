#!/bin/sh

declare DISCOVERED_JAVA_HOME

# Getting the java home location form OUD/WLS AdminServer
oudoutput=$(ps -aef | grep org.opends.server.core.DirectoryServer | grep config.ldif)
wlsoutput=$(ps -aef | grep AdminServer)

# Keeping the output in an array
oudarray=($oudoutput)
wlsarray=($wlsoutput)

# First getting the java home from OUD JAVA_HOME if its not availble getting it from AdminServer.
if [  ${#oudarray[@]} != 0 ]
then
        for  value in "${oudarray[@]}"
        do
                if [[ $value  == *"/bin/java" ]]
                then
                        DISCOVERED_JAVA_HOME=$(echo $value | sed 's/.\{8\}$//')
                        break;
                fi
        done
else [  ${#wlsarray[@]} != 0 ]
        for value in "${wlsarray[@]}"
        do
                if [[ $value == *"/bin/java" ]]
                then
                        DISCOVERED_JAVA_HOME=$(echo $value | sed 's/.\{8\}$//')
                        break;
                fi
        done

fi

if [[ ! -z $DISCOVERED_JAVA_HOME ]]
then
        echo "$DISCOVERED_JAVA_HOME"
fi

