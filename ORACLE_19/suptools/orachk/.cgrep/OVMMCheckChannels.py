#!/usr/bin/python
############################################################################################
#
#  THIS SCRIPT IS PROVIDED ON AN AS IS BASIS, WITHOUT WARRANTY OF ANY KIND,
#  EITHER EXPRESSED OR IMPLIED, INCLUDING, WITHOUT LIMITATION, WARRANTIES THAT
#  THE COVERED SCRIPT IS FREE OF DEFECTS, MERCHANTABLE, FIT FOR A PARTICULAR
#  PURPOSE OR NON-INFRINGING. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE
#  OF THE COVERED SOFTWARE IS WITH YOU. SHOULD ANY COVERED SOFTWARE PROVE
#  DEFECTIVE IN ANY RESPECT, YOU (NOT THE INITIAL DEVELOPER OR ANY OTHER
#  CONTRIBUTOR) ASSUME THE COST OF ANY NECESSARY SERVICING, REPAIR OR CORRECTION.
#  NO USE OF ANY COVERED SOFTWARE IS AUTHORIZED HEREUNDER EXCEPT UNDER THIS
#  DISCLAIMER.
#
#  When distributing this Code, include this HEADER in each file.
#  If applicable, add the following below this this HEADER, with the fields
#  enclosed by brackets "[]" replaced with your own identifying information:
#       Portions Copyright [yyyy] [name of copyright owner]
#
#
#       Copyright 2014 Exalogic A-Team, Oracle and/or its affiliates. All rights reserved.
#
############################################################################################
import os
import sys

# Boiler plate
__author__  = "Eder Zechim (Exalogic A-Team)"
__date__    = "$12-Aug-2014 14:23:15$"

SCRIPT_NAME = 'OVMMCheckChannels.py'
VERSION     = '1.0.0.1                                '
BUILD_DATE  = '12-Aug-2014                            '

wlst_script = r"""
import weblogic.security.internal.SerializedSystemIni
import weblogic.security.internal.encryption.ClearOrEncryptedService
encryptionService = weblogic.security.internal.SerializedSystemIni.getEncryptionService(os.path.abspath('/u01/app/oracle/ovm-manager-3/machine1/base_adf_domain'))
ces = weblogic.security.internal.encryption.ClearOrEncryptedService(encryptionService)

username = ''
password = ''
fd = open('/u01/app/oracle/ovm-manager-3/machine1/base_adf_domain/servers/AdminServer/security/boot.properties', 'r')
for line in fd:
    if line.startswith('username='):
        encryptedUser = line.replace('username=','')
        username = ces.decrypt(encryptedUser)
    if line.startswith('password='):
        encryptedPass = line.replace('password=','')
        password = ces.decrypt(encryptedPass)
fd.close()

if username == '' or password == '':
    print('OUTPUT[ERROR] Unable to collect the username/password for OVMM')
    sys.exit(1)

try:
    connect(username,password,'t3://localhost:7001')
    domainConfig()
    cd('/Servers/AdminServer/NetworkAccessPoints')
    error = False
    channels=cmo.getNetworkAccessPoints()
    if ( len(channels) == 1 ) and ( channels[0].getName() == 'https' ):
        print('OUTPUT[INFO] Found only the default channel (https). Configuration is sane.')
    elif (len(channels) > 1): 
        print('OUTPUT[ERROR] Found the following custom channels: '),
        for c in channels:
            print('\"'+ c.getName() +'\" '),
        print('. Configuration was modified.')
        error = True
    else:
        print('OUTPUT[ERROR] Can\'t find custom channel \"https\". Configuration was modified.')
        error = True
    if error:
        print('OUTPUT[ERROR] OVMM should have only one channel named \"https\"')
except:
    print('OUTPUT[ERROR] Unable to connect to OVMM')
"""
tmp_wlst_script = '/tmp/OVMMCheckChannels.'+ str(os.getpid()) +'.wlst'

def showVersionHistory():
  print('')
  print('##########################################################################################')
  print('## Version    Date         Change')
  print('## =======    ==========   ===============================================================')
  print('##')
  print('## 1.0.0.1    12/08/2014   Peer review 1 with Denny and  testing on http://scae05ec1-vm/')
  print('## 1.0.0.0    12/08/2014   Initial release.')
  print('##')
  print('##########################################################################################')
  print('')
  return

#
# Main 
def main(argv):
    fd = open(tmp_wlst_script, 'w')
    fd.write(wlst_script)
    fd.close()
    for line in os.popen('/u01/app/oracle/Middleware/wlserver_10.3/common/bin/wlst.sh '+ tmp_wlst_script):
        if line.startswith('OUTPUT'):
            print line.replace('OUTPUT',''),
    os.remove(tmp_wlst_script)

# Main function to kick off processing
if __name__ == '__main__':
  main(sys.argv[1:])


