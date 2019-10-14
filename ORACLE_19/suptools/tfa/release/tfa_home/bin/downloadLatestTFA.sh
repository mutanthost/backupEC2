#!/bin/sh
#
# $Header: tfa/src/v2/tfa_home/bin/downloadLatestTFA.sh /main/1 2016/08/04 23:00:30 llakkana Exp $
#
# downloadLatestTFA.sh
#
# Copyright (c) 2016, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      downloadLatestTFA.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    llakkana    07/21/16 - Script to download latest TFA Version from Oracle
#                           ARU
#    llakkana    07/21/16 - Creation
#

################ Functions ###############
check_CURL ()
{
  is_curl_available=1
  if [[ -z $RAT_CURL_CMD ]]; then
    CURL_CMD=$(which curl 2>/dev/null)
    if [[ -z "$CURL_CMD" || `echo $?` -ne 0 || `echo "$CURL_CMD" | grep -ic "no curl"` -gt "0" ]]; then
      unset CURL_CMD
      is_curl_available=0
    fi
  else
    CURL_CMD=$RAT_CURL_CMD
  fi
}

check_WGET ()
{
  is_wget_available=1
  if [[ -z $RAT_WGET_CMD ]]; then
    WGET_CMD=$(which wget 2>/dev/null)
    if [[ -z "$WGET_CMD" || `echo $?` -ne 0 || `echo "$WGET_CMD" | grep -ic "no wget"` -gt "0" ]]; then
      unset WGET_CMD
      is_wget_available=0
    fi
  else
    WGET_CMD=$RAT_WGET_CMD
  fi
}

process_prompt ()
{
  prompt_code=$1
  var_name=$2
  var_value=$3
  if [[ $prompt_timeout -eq 1 ]]; then
    if [[ $prompt_code -ne 0 ]]; then
      eval "$var_name=\"$var_value\""
    fi
  fi
}

#Format: download_using_CURL host_url username password cookies_file logfile downloaded_zipname(absolute)
download_using_CURL ()
{
  $CURL_CMD --user $2:$3 --cookie-jar $4 --location-trusted "$1" -o $6 --verbose 2>>$5
  if [[ `grep -ic 'HTTP/1.1 401 Unauthorized' $LOGFIL` -gt 0 ]]; then
    curl_return_code=0
  elif [[ `grep -ic 'SSL certificate problem' $LOGFIL` -gt 0 ]]; then
    curl_return_code=2
  else
    curl_return_code=1
  fi
}

#Format: download_using_WGET host_url username password cookies_file sso_auth_file logfile downloaded_zipname(absolute)
download_using_WGET ()
{
  SSO_RESPONSE=`$WGET_CMD --user-agent="Mozilla/5.0" https://$8/Orion/Services/download 2>&1|grep Location`
  # Extract request parameters for SSO
  if [[ `echo "$SSO_RESPONSE"|grep -ic "Location"` -gt "0" ]]; then
    SSO_TOKEN=`echo "$SSO_RESPONSE"| cut -d '=' -f 2|cut -d ' ' -f 1`
    SSO_SERVER=`echo "$SSO_RESPONSE"| cut -d ' ' -f 2|cut -d 'p' -f 1,2`
    SSO_AUTH_URL=sso/auth
    AUTH_DATA="ssousername=$2&password=$3&site2pstoretoken=${SSO_TOKEN}"

    # The following command to authenticate uses HTTPS. This will work only if the wget in the environment
    # where this script will be executed was compiled with OpenSSL. Remove the --secure-protocol option
    # if wget was not compiled with OpenSSL
    # Depending on the preference, the other options are --secure-protocol= auto|SSLv2|SSLv3|TLSv1

    # Contact updates site so that we can get SSO Params for logging in
    $WGET_CMD --user-agent="Mozilla/5.0" --secure-protocol=auto --post-data $AUTH_DATA --save-cookies=$4 --keep-session-cookies ${SSO_SERVER}${SSO_AUTH_URL} -O $5 >> $6 2>&1

    if [[ -e $4 ]]; then
      if [[ `grep -ic "$8" "$4"` -gt 0 ]]; then
        echo ""
        $WGET_CMD --user-agent="Mozilla/5.0" --load-cookies=$4 --save-cookies=$4 --keep-session-cookies "$1" -O $7 >>$6 2>&1
        wget_return_code=1
      else
        wget_return_code=0
      fi
    else
      wget_return_code=2
    fi
  else
    wget_return_code=2
    $WGET_CMD --user-agent="Mozilla/5.0" https://$8/Orion/Services/download 2>>$6
  fi
}

help ()
{
  echo "Usage: `basename ${0}` [-username <username> | -password <passwordd> | 
				-outputdir <outputdir>]"
  echo "	username  - User name to access ARU. If not provided will prompt for it"
  echo "	password  - Password to access ARU. If not provided will prompt for it"
  echo "	outputdir - Dir path to whcih installer will be downloaded."
  echo "		    If not provided, defalut dir is /tmp/tfa_date"
  echo ""  
}

download_from_ARU ()
{
  LANG=C
  export LANG
  DOWNLOAD_STATUS=1
  is_windows=0
  #Validation1: URL host reachable or not
  URL_HOST="updates.oracle.com"
  platform=`uname -s`
  if [ $is_windows -eq "1" ]; then
    PING=$(which ping| tr -d '\r')
    if [[ -z $PING ]]; then PING="/bin/ping"; fi
  else
    if [ $platform = "Linux" ]
    then
      PING="/bin/ping"
      PING_W_FLAG="-w 5"
    else
      PING="/usr/sbin/ping"
    fi
  fi
  if [ $platform = "SunOS" ]; then
    $PING -s $URL_HOST 5 5 >/dev/null 2>&1
  elif [ $platform = "HP-UX" ]; then
    $PING $URL_HOST -n 5 -m 5 >/dev/null 2>&1
  elif  [ $is_windows -eq "1" ]; then
    $PING -n 5 $URL_HOST >/dev/null 2>&1
  else
    $PING -c 1 $PING_W_FLAG $URL_HOST >/dev/null 2>&1
  fi
  if [ $? -ne "0" ]; then
    echo -e "${URL_HOST} is not reachable. Please establish connectivity to ${URL_HOST} and try again."
    echo ""
    DOWNLOAD_STATUS=0
    return;
  fi
  
  #Validation2: curl/wget utility is available or not
  check_CURL    
  check_WGET
  if [[ -n $is_curl_available && $is_curl_available -eq "0" &&-n $is_wget_available && $is_wget_available -eq "0" ]]; then
    echo "This feature requires curl/wget command. If curl/wget is installed, please set PATH and try again, else please install curl/wget and try again.";
    echo ""
    DOWNLOAD_STATUS=0
    return;
  fi

  if [[ -z "$RAT_DOWNLOAD_BUGNO" ]]; then
    RAT_DOWNLOAD_BUGNO="21757377" #"19847683"
  fi

  DOWNLOAD_LINK="https://$URL_HOST/Orion/Services/search?bug=$RAT_DOWNLOAD_BUGNO"
  READ="read"

  #If credentials not provided, prompt for them
  if [[ `echo "$ARGS"|grep -ic "\-username"` -eq 0 ]]; then
    echo ""
    exec 3<&2; exec 2<&0
    $READ -p "Enter your my oracle support username:- " SSO_USERNAME
    read_code=`echo $?`;
    exec 2<&3
    process_prompt "$read_code" "SSO_USERNAME" ""
  fi
  if [[ `echo "$ARGS"|grep -ic "\-password"` -eq 0 ]]; then
    echo ""
    tty -s && stty -echo
    $READ -p "Enter your my oracle support password:- " SSO_PASSWORD
    read_code=`echo $?`;
    tty -s && stty echo
    process_prompt "$read_code" "SSO_PASSWORD" ""
    echo ""
  fi
  SSO_USERNAME=$(echo "$SSO_USERNAME"|sed 's/ //g')
  SSO_PASSWORD=$(echo "$SSO_PASSWORD"|sed 's/ //g')

  if [[ -z $OUTPUTDIR ]];then
    OUTPUTDIR=/tmp/tfa_`date +%y.%m.%d-%H.%M.%S`
  fi
  if [[ ! -d $OUTPUTDIR ]];then
    mkdir -p $OUTPUTDIR >/dev/null 2>&1;
  fi
  LOGFIL=$OUTPUTDIR/tfa_download_`date +%y.%m.%d-%H.%M.%S`.log
  RTEMPDIR=/tmp/.tfa
  COOKIE_FILE=$RTEMPDIR/$$.cookies
  SSOFIL=$RTEMPDIR/sso.out
  DOWNLOADED_ZIP=$OUTPUTDIR/tfa.zip
  DOWNLOADED_XML=$OUTPUTDIR/download.xml

  if [[ -n $CURL_CMD && $is_curl_available -eq "1" ]]; then
    download_using_CURL "$DOWNLOAD_LINK" "$SSO_USERNAME" "$SSO_PASSWORD" "$COOKIE_FILE" "$LOGFIL" "$DOWNLOADED_XML"
  fi
  if [[ -n $curl_return_code && $curl_return_code -eq "2" ]]; then
    if [[ -n $WGET_CMD && -n $is_wget_available && $is_wget_available -eq "1" ]]; then
      download_using_WGET "$DOWNLOAD_LINK" "$SSO_USERNAME" "$SSO_PASSWORD" "$COOKIE_FILE" "$SSOFIL" "$LOGFIL" "$DOWNLOADED_XML" "$URL_HOST"
    fi
  fi

  if [[ -f "$DOWNLOADED_XML" ]]; then
    DOWNLOAD_URL=`grep -w download_url $DOWNLOADED_XML|sed 's/.*https/https/'|sed 's/\.zip\]\].*/\.zip/'|sed 's/"><!\[CDATA\[//'`;
    zipname=`echo $DOWNLOAD_URL|sed 's/.*=//'`
    DOWNLOADED_ZIP=$OUTPUTDIR/$zipname
  fi

  echo "Started downloading...."
  if [[ -n $CURL_CMD && $is_curl_available -eq "1" ]]; then
    download_using_CURL "$DOWNLOAD_URL" "$SSO_USERNAME" "$SSO_PASSWORD" "$COOKIE_FILE" "$LOGFIL" "$DOWNLOADED_ZIP"
  fi
  if [[ -n $curl_return_code && $curl_return_code -eq "2" ]]; then
    if [[ -n $WGET_CMD && -n $is_wget_available && $is_wget_available -eq "1" ]]; then
      download_using_WGET "$DOWNLOAD_URL" "$SSO_USERNAME" "$SSO_PASSWORD" "$COOKIE_FILE" "$SSOFIL" "$LOGFIL" "$DOWNLOADED_ZIP" "$URL_HOST"
    fi
  fi
 
  #Display/return messages....
  if [[ -n $curl_return_code && $curl_return_code -eq "1" ]] || [[ -n $wget_return_code && $wget_return_code -eq "1" ]]; then  
    DOWNLOAD_STATUS=1    
    echo ""
    echo "$DOWNLOADED_ZIP successfully downloaded to $OUTPUTDIR"
    echo ""
  elif [[ -n $curl_return_code && $curl_return_code -eq "0" ]] || [[ -n $wget_return_code && $wget_return_code -eq "0" ]]; then 
    DOWNLOAD_STATUS=0
    rm -f $DOWNLOADED_ZIP >/dev/null 2>&1
    echo ""
    echo "Incorrect username or password.Please try again."
    echo ""
    echo "Incorrect username or password." >>$LOGFIL
  elif [[ -n $curl_return_code && $curl_return_code -eq "2" ]] && [[ -n $wget_return_code && $wget_return_code -eq "2" ]]; then
    DOWNLOAD_STATUS=0
    rm -f $DOWNLOADED_ZIP >/dev/null 2>&1
    echo ""
    echo "curl: SSL certificate problem and wget: Unexpected problem. Please review $LOGFIL for more detail"    
    echo ""
  elif [[ -n $curl_return_code && $curl_return_code -eq "2" ]]; then
    DOWNLOAD_STATUS=0
    rm -f $DOWNLOADED_ZIP >/dev/null 2>&1
    echo ""
    echo "curl: SSL certificate problem. Please review $LOGFIL for more detail"
    echo ""
  elif [[ -n $wget_return_code && $wget_return_code -eq "2" ]]; then
    DOWNLOAD_STATUS=0
    rm -f $DOWNLOADED_ZIP >/dev/null 2>&1
    echo ""
    echo "wget: Unexpected problem. Please review $LOGFIL for more detail"
    echo ""
  fi

  #Cleanup
  rm -f $COOKIE_FILE >/dev/null 2>&1
  rm -f $SSOFIL >/dev/null 2>&1
  return
}

##############Main#############
ARGS=$*
while [[ $# > 0 ]]; do
  ins_args="$1"
  case $ins_args in
    -username)
      SSO_USERNAME="$2"
      shift
    ;;
    -password)
      SSO_PASSWORD="$2"
      shift
    ;;
    -outputdir)
      OUTPUTDIR="$2"
      shift
    ;;
    -h|-help|*)
      help
      exit 0 
    ;;
  esac
  shift
done
download_from_ARU

