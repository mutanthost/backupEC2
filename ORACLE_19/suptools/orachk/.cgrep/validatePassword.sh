#!/bin/bash
#
# $Header: tfa/src/orachk/src/validatePassword.sh /main/3 2017/12/12 23:17:55 rojuyal Exp $
#
# validatePassword.sh
#
# Copyright (c) 2015, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      validatePassword.sh - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    cgirdhar    12/06/17 - Remove hardcode default password
#    cgirdhar    08/13/15 - Validate default OS passwords
#    cgirdhar    08/13/15 - Creation
#

if [ -z "$RAT_SSHELL" ]; then
  SSHELL="/usr/bin/ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=quiet -o PreferredAuthentications=password -o PubkeyAuthentication=no -q"
else
  SSHELL=$RAT_SSHELL   
fi

if [ -z "$RAT_EXPECT" ]; then
  EXPECT=/usr/bin/expect
else
  EXPECT=$RAT_EXPECT
fi

bash_scr="/bin/env bash"
if [[ ! -f "/bin/bash" || ! -f "/bin/env" ]] ; then
  bash_scr=$(which bash)
fi
defaultpassword1="wel"
defaultpassword2="come1"
defaultpassword="${defaultpassword1}${defaultpassword2}"

fixRootPassword ()
{
  inputPassword=$1
  fixedRootPassword=$(echo "$inputPassword" | sed  -e 's/\\/\\\\/g' -e 's/\[/\\[/g' -e 's/"/\\"/g')

  hasDollar=$(echo "$fixedRootPassword"|grep -c "$");
  if [[ -n "$hasDollar" && $hasDollar -ge "1" ]]; then 
    fixedRootPassword=$(echo "$fixedRootPassword"|sed 's/\$/\\$/g');
  fi
}

checkDBPassword ()
{
  userToCheck=$1
  ipasswordToCheck=$2
  nodeNameToCheck=$3
	
  if [ -z "$nodeNameToCheck" ]; then nodeNameToCheck=`hostname | tr "[A-Z]" "[a-z]" |cut -d. -f1|tr -d '\r'`; fi;
  if [ -z "$ipasswordToCheck" ]; then ipasswordToCheck="${defaultpassword}"; fi;
  if [ -z "$userToCheck" ]; then userToCheck="sys"; fi;

  passwordCheckSum=0

  nodeNameToCheck=`echo "$nodeNameToCheck" | tr "[A-Z]" "[a-z]" |cut -d. -f1|tr -d '\r'`;

  for passwordToCheck in `echo "$ipasswordToCheck"|tr ',' '\n'` 
  do
    localnode=`hostname | tr "[A-Z]" "[a-z]" |cut -d. -f1|tr -d '\r'`
    if [[ $nodeNameToCheck = $localnode ]]; then
      is_password_correct=$(echo "select name from v\$database;"|$ORACLE_HOME/bin/sqlplus -s ${userToCheck}/${passwordToCheck} as sysdba|grep -v ^$)
    else
      is_password_correct=$($SSHELL $nodeNameToCheck $bash_scr <<EOF
      export ORACLE_HOME=$ORACLE_HOME
      export ORACLE_SID=$ORACLE_SID; \
      echo "select name from v\\\$database;"|$ORACLE_HOME/bin/sqlplus -s ${userToCheck}/${passwordToCheck} as sysdba|grep -v ^$ 
EOF
)
    fi
    if [[ -z "$is_password_correct" ]] || [[ `echo "$is_password_correct"|grep -ic "ORA-01017"` -ge 1 ]]
    then
      passwordCheckSum=1
    else
      passwordCheckSum=0
      break;
    fi
  done

  if [[ $passwordCheckSum -eq "0" ]]; then 
    echo "0"
  else
    echo "1"
  fi 
}
checkILOMPassword ()
{
  userToCheck=$1
  ipasswordToCheck=$2
  nodeNameToCheck=$3

  if [ -z "$nodeNameToCheck" ]; then nodeNameToCheck=`hostname | tr "[A-Z]" "[a-z]" |cut -d. -f1|tr -d '\r'`; fi;
  if [ -z "$ipasswordToCheck" ]; then ipasswordToCheck="${defaultpassword}"; fi;
  if [ -z "$userToCheck" ]; then userToCheck="root"; fi;
  if [ -z "$RAT_IPMITOOL" ]; then
  IPMITOOL=/usr/bin/ipmitool
  else
  IPMITOOL=$RAT_IPMITOOL
  fi

  passwordCheckSum=0

  nodeNameToCheck=`echo "$nodeNameToCheck" | tr "[A-Z]" "[a-z]" |tr -d '\r'`;

  for passwordToCheck in `echo "$ipasswordToCheck"|tr ',' '\n'`
  do
    is_password_correct=$($IPMITOOL -I lanplus -H $nodeNameToCheck -U $userToCheck -P $passwordToCheck bmc info  > /dev/null 2>&1;echo $?)
    if [[ -z "$is_password_correct" ]] || [[ $is_password_correct -ge 1 ]]
    then
      passwordCheckSum=1
    else
      passwordCheckSum=0
      break;
    fi
  done

  if [[ $passwordCheckSum -eq "0" ]]; then
    echo "0"
  else
    echo "1"
  fi

}

checkOSPassword ()
{
  userToCheck=$1
  ipasswordToCheck=$2
  nodeNameToCheck=$3
	
  if [ -z "$nodeNameToCheck" ]; then nodeNameToCheck=$(hostname); fi;
  if [ -z "$ipasswordToCheck" ]; then ipasswordToCheck="${defaultpassword}"; fi;
  if [ -z "$userToCheck" ]; then userToCheck="root"; fi;

  if [ -n "$4" ]; then targetHostType="$5"; else targetHostType="normal"; fi

  if [[ -n "$4" && "$4" = "ibswitch" ]]; then hostTypeSwitch=1;else hostTypeSwitch=0;fi
  if [[ -n "$4" && "$4" = "normal" ]]; then hostTypeCell=1;else hostTypeCell=0;fi

  if [[ `uname -s` = "Linux" || $hostTypeCell -eq 1 ]] && [ $hostTypeSwitch -eq 0 ];then loginDelayHost=1;else loginDelayHost=0;fi  
 
  if [[ -n "$RAT_PASSWORDCHECK_TIMEOUT" && $RAT_PASSWORDCHECK_TIMEOUT -gt 1 ]] 
  then 
    passwordcheck_timeout=$RAT_PASSWORDCHECK_TIMEOUT
  else 
    passwordcheck_timeout=1
  fi

  CONNECTTIMEOUT=$passwordcheck_timeout
  $EXPECT -f - << IBEOF
            set timeout $CONNECTTIMEOUT
            log_user 0
            if { "$RAT_EXPECT_DEBUG" == "-d" } {
              exp_internal 1
            }
            if { "$targetHostType" == "normal" } {
              spawn -noecho $SSHELL $userToCheck@$nodeNameToCheck "ls >/dev/null 2>&1"
            } else {
              spawn -noecho $SSHELL $userToCheck@$nodeNameToCheck script "ls >/dev/null 2>&1;"
            }
            match_max 100000
            expect {
              -nocase "no)?" {
                  send -- "yes\n"
              }
              -nocase "*?assword:*" {
		 exit 5;
              }
              -nocase "permission denied *" {
                  exit 4;
              }
              -nocase timeout {
                  exit 2;
              }
              -nocase eof {
                  exit 0;
              }
           }
            expect {
              -nocase "*?assword:*" {
           	  exit 5; 
              }
              -nocase "permission denied *" {
                  exit 4;
              }
              -nocase timeout {
                  exit 2;
              }
              -nocase eof {
                  exit 0;
              }
           }
         expect {
                 -nocase default {exit 0}
              }
         exit 0
IBEOF
  tmp_passwordCheckStatus=$(echo $?)
  if [[ $tmp_passwordCheckStatus -eq "2" ]] ; then
    echo 1;
    exit 1;
  fi
  tty -s && stty echo
 
  SSHELL=$(echo "$SSHELL -o PubkeyAuthentication=no")

  passwordCheckSum=0
  for passwordToCheck in `echo "$ipasswordToCheck"|tr ',' '\n'` 
  do
    fixRootPassword "$passwordToCheck"

    $EXPECT -f - << IBEOF
                           set timeout $passwordcheck_timeout
			   set le_passwordToCheck "$fixedRootPassword"
                           log_user 0
                           if { "$RAT_EXPECT_DEBUG" == "-d" } { 
                             exp_internal 1
                           } 
			   if { "$targetHostType" != "zfscell" } {
                             spawn -noecho $SSHELL $userToCheck@$nodeNameToCheck "echo \"LoginSuccessfull\""
			   } else {
                             spawn -noecho $SSHELL $userToCheck@$nodeNameToCheck script "printf(\"LoginSuccessfull\\\\n\");"
			   }
                           match_max 100000
                           expect {
                             -nocase "no)?" {
                                 send -- "yes\n"
                                 }
                             -nocase "*?assword:*" {
				 send -- "\$le_passwordToCheck\n"
                                 }
                             -nocase "permission denied *" {
                                 exit 4;
                                 }
                             LoginSuccessfull { exit 0; }
 			     -nocase timeout {
                                 exit 3
                             }
                             -nocase eof {
                                 exit 0
                                 }
                          }
                           expect {
                             -nocase "*?assword:*" {
				 send -- "\$le_passwordToCheck\n"
                                 }
                             -nocase "permission denied *" {
                                 exit 4;
                                 }
                             LoginSuccessfull { exit 0; }
 			     -nocase timeout {
                                 exit 3
                             }
                             -nocase eof {
                                 exit 0
                                 }
                          }
                        expect {
                                -nocase default {exit 2}
                                LoginSuccessfull
                               }
                         exit 0
IBEOF
    passwordCheckStatus=$(echo $?)
    if [[ $passwordCheckStatus -eq "0" ]] ; then
      passwordCheckSum=0
      break; 
    else
      passwordCheckSum=1
    fi
  done

  if [[ $passwordCheckSum -eq "0" ]]; then 
    echo "0"
  else
    echo "1"
  fi 
}

checkType=$1
if [ -z "$checkType" ]; then checkType="os"; fi;

if [[ `echo "$checkType"|grep -icw "os"` -gt "0" ]]; then 
  checkOSPassword "$2" "$3" "$4" "$5"
elif [[ `echo "$checkType"|grep -icw "ilom"` -gt "0" ]]; then
  checkILOMPassword "$2" "$3" "$4" "$5"
else
  checkDBPassword "$2" "$3" "$4" "$5"
fi
