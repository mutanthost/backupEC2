#!/usr/bin/python
import sys, getopt
import os, stat, time, string
from multiprocessing import Process
import paramiko


class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def generate_ocm_sw_script(envfile):
    outputdir = ""
    excludefil = ""
    inputdir = ""
    scriptfil = ""
    with open(envfile) as f:
        for line in f:
            if "OUTPUTDIR" in line:
                outputdir = line.rstrip().split('=')[1]
            if "EXCLUDEFIL" in line:
                excludefil = line.rstrip().split('=')[1]
            if "INPUTDIR" in line:
                inputdir = line.rstrip().split('=')[1]
            if "OCMSWGENERATEDSCRIPT" in line:
                scriptfil = line.rstrip().split('=')[1]
                if os.path.isfile(scriptfil):
                    os.remove(scriptfil)

    with open(outputdir+"/switchexcl.txt", 'a') as f:
        if os.path.isfile(outputdir+"/cmdexfil.txt"):
            with open(outputdir+"/cmdexfil.txt") as f1:
                for line in f1:
                    f.write(line)
        if os.path.isfile(excludefil):
            with open(excludefil) as f2:
                for line in f2:
                    f.write(line)
    with open(inputdir+"/collections.dat") as f3:
        data = f3.read().splitlines()
        result = [item.rstrip().split('-')[0] for item in data if "NEEDS_RUNNING TOR_SWITCH" in item]
        if os.path.isfile(outputdir+"/switchexcl.txt"):
            with open(outputdir+"/switchexcl.txt") as exf:
                for line in exf:
                    result = [item for item in result if line not in item]
        with open(scriptfil, 'w') as f4:
            f4.write("cli start shell sh\n")
            for check in result:
                start_num = 0
                end_num = 0
                for i, item in enumerate(data):
                    if item.startswith(check+"-OS_COLLECT_COMMAND_START"):
                        start_num = i+1
                    if item.startswith(check+"-OS_COLLECT_COMMAND_END"):
                        end_num = i

                for code in data[start_num:end_num]:
                    f4.write(code + "\n")
            f4.write("exit\nexit\nexit")
            os.chmod(scriptfil, stat.S_IRUSR|stat.S_IWUSR|stat.S_IXUSR|stat.S_IRGRP|stat.S_IROTH)


def run_script(credential, hostname, port, scriptfil, outfile):
    client = paramiko.SSHClient()
    client.load_system_host_keys()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(hostname, port=port, username=credential[hostname]['username'], password=credential[hostname]['password'])

    with open(scriptfil, 'r') as f2:
        cmd = f2.read()
        chan = client.invoke_shell()
        stdin = chan.makefile('wb')
        stdout = chan.makefile('rb')
        stdin.write(cmd)
        buff = stdout.read()
        with open(outfile, "a") as f:
            f.write(filter(lambda x: x in string.printable, buff))
    client.close()


def execute_ocm_sw_script(envfile):
    switches = ""
    outputdir = ""
    offline = 0
    logfil = ""
    ocm_sw_timeout = 100
    scriptfil = ""
    opc_credfile = ""

    with open(envfile) as f:
        for line in f:
            if "RAT_TORSWITCHES" in line:
                switches = line.rstrip().split('=')[1].split(' ')
            if "OUTPUTDIR" in line:
                outputdir = line.rstrip().split('=')[1]
            if "OFFLINE" in line:
                offline = line.rstrip().split('=')[1]
            if "LOGFIL" in line:
                logfil = line.rstrip().split('=')[1]
                if os.path.isfile(logfil):
                    os.remove(logfil)
            if "zfs_aksh_timeout" in line:
                temp = line.rstrip().split('=')[1]
                if temp:
                    ocm_sw_timeout = temp
            if "OCMSWGENERATEDSCRIPT" in line:
                scriptfil = line.rstrip().split('=')[1]
            if "opc_credfile" in line:
                opc_credfile = line.rstrip().split('=')[1]

        if offline != "0":
            return
        with open(opc_credfile) as f2:
            credential = {}
            for line in f2:
                hostname = line.rstrip().split('|')[0]
                credential[hostname] = {}
                credential[hostname]['username'] = line.rstrip().split('|')[1]
                credential[hostname]['password'] = line.rstrip().split('|')[2]

        processes = []
        pids = []
        for switch in switches:
            output = "\n" + bcolors.OKGREEN + \
                    "Starting to run root privileged commands in background on OCM TOR Switch " + \
                    switch + bcolors.ENDC + "\n"
            print output
            with open(logfil, 'a') as f1:
                f1.write(output)
            outfile = outputdir + "/" + switch + ".ocm_switch_checks.out"
            if os.path.isfile(outfile):
                os.remove(outfile)
            port = 22
            p = Process(target=run_script, args=(credential, switch, port, scriptfil, outfile,))
            p.start()
            # p.join()
            processes.append(p)
            pids.append(p.pid)
        print ""
        count = time.time()
        while time.time() - count <= ocm_sw_timeout:
            if not [p for p in processes if p.is_alive()]:
                break
            else:
                sys.stdout.write(". ")
                sys.stdout.flush()
                time.sleep(1)
        else:
            for p in processes:
                p.terminate()
        sys.stdout.write("\n")
        sys.stdout.flush()


def main(argv):
    envfile = ""
    try:
        opts, args = getopt.getopt(argv, "hf:ge", ["envfile="])
    except getopt.GetoptError:
        print 'ocm_switch.py -f <environment file>' \
                '-g (generate script)' \
                '-e (execute script)'
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print 'ocm_switch.py -f <environment file>' \
                    '-g (generate script)' \
                    '-e (execute script)'
            sys.exit()
        elif opt in ("-f", "--envfile"):
            envfile = arg
        elif opt == "-g":
            generate_ocm_sw_script(envfile)
        elif opt == "-e":
            execute_ocm_sw_script(envfile)


if __name__ == "__main__":
    main(sys.argv[1:])


