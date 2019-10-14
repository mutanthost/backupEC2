#!/bin/sh
#
# $Header: tfa/src/orachk_py/web/setup_ords.sh /main/4 2018/10/25 04:33:15 apriyada Exp $
#
# setup_ords.sh
#
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      setup_ords.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    apriyada    02/13/18 - Creation
#

ORDSUSR="$3"
restart="$5"
JAVA_HOME="$4"
ORDS_PATH="$1"
SCRIPT_DIR="$2"
usrname="$6"
port="$7"
homedir="$8"
plugin_root="$9"
configdir="${10}"
oraclehome="${11}"
servlet_jarpath="$SCRIPT_DIR/web/"
ordswarpath="$SCRIPT_DIR/web/"
cdir=`pwd`;
swusr="su -s /bin/sh"
nhup=`which nohup`

if [ $restart = "0" ]; then
    if [ $homedir = "NULL" ]; then 
        `useradd -s /sbin/nologin $ORDSUSR` 
    else
        `useradd -s /sbin/nologin -b $homedir $ORDSUSR`  
    fi

    if [ -f $ordswarpath/ords.war ] ; then
        cp $ordswarpath/ords.war $ORDS_PATH 
    else 
        cp $oraclehome/ords/ords.war $ORDS_PATH 
    fi
fi 

cd $ORDS_PATH
cp $ordswarpath/orachk.jar .

$swusr $ORDSUSR -c "mkdir $ORDS_PATH/lib"
chown $ORDSUSR ords.war
chown $ORDSUSR orachk.jar
chown -R $ORDSUSR lib
$swusr $ORDSUSR -c "echo $JAVA_HOME > $ORDS_PATH/lib/jhome.dat;mkdir $ORDS_PATH/log >/dev/null 2>&1 ;touch $ORDS_PATH/log/ords_setup.log"

$swusr $ORDSUSR -c "$JAVA_HOME/bin/java -jar ords.war plugin orachk.jar"
if [ $restart = "0" ]; then
    $swusr $ORDSUSR -c "$JAVA_HOME/bin/java -jar ords.war configdir $ORDS_PATH "
else
    if [ $configdir != "NULL" ]; then 
        $swusr $ORDSUSR -c "$JAVA_HOME/bin/java -jar ords.war configdir $configdir "
    fi 
fi
$swusr $ORDSUSR -c "$JAVA_HOME/bin/java -jar ords.war user $usrname \"ORAchk Admin\" "

hostn=`uname -n`
hostf=`hostname -f`

if [ $restart = "0" ]; then
    $swusr $ORDSUSR -c "mkdir -p $ORDS_PATH/ords/standalone"

    $swusr $ORDSUSR -c "touch $ORDS_PATH/ords/standalone/standalone.properties"
    $swusr $ORDSUSR -c "echo jetty.secure.port=$port > $ORDS_PATH/ords/standalone/standalone.properties;echo ssl.cert= >> $ORDS_PATH/ords/standalone/standalone.properties;echo ssl.cert.key= >> $ORDS_PATH/ords/standalone/standalone.properties;echo ssl.host=$hostn >> $ORDS_PATH/ords/standalone/standalone.properties;echo standalone.context.path=/ords >> $ORDS_PATH/ords/standalone/standalone.properties;echo standalone.doc.root=$ORDS_PATH/ords/standalone/doc_root >> $ORDS_PATH/ords/standalone/standalone.properties;echo standalone.scheme.do.not.prompt=true >> $ORDS_PATH/ords/standalone/standalone.properties;echo standalone.static.context.path=/i >> $ORDS_PATH/ords/standalone/standalone.properties;echo standalone.static.path=/tmp >> $ORDS_PATH/ords/standalone/standalone.properties;echo standalone.static.do.not.prompt=true >> $ORDS_PATH/ords/standalone/standalone.properties"
    $swusr $ORDSUSR -c "$JAVA_HOME/bin/java -jar ords.war  standalone &"

else
    if [ $configdir = "NULL" ]; then
        portv=`grep "jetty.secure.port=" $ORDS_PATH/ords/standalone/standalone.properties|sed "s/jetty.secure.port=//"`
    else
        portv=`grep "jetty.secure.port=" $configdir/ords/standalone/standalone.properties|sed "s/jetty.secure.port=//"`
    fi
    $nhup $swusr $ORDSUSR -c "$JAVA_HOME/bin/java -jar ords.war  standalone &"
    $swusr $ORDSUSR -c "echo \"Oracle Rest Data Service (ORDS) URL: https://$hostf:$portv/ords/$plugin_root\" > $ORDS_PATH/log/ords_setup.log"

fi

#$swusr $ORDSUSR -c "$JAVA_HOME/bin/java -jar ords.war  standalone &"



