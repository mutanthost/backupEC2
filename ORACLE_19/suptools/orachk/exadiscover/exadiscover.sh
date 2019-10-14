#!/bin/env bash

#    NAME
#      exadiscover.sh
#
#    Author
#      Zunping Cheng
#    Update 
#      Benyue Liu 8/27/2014
#
#    DESCRIPTION
#      Discovering and versioning within Exalogic racks
#
#    Update
#      Shi-Rong Chang 09/26/2017
#    DESCRIPTION
#      Update this script to remove the 3rd storage head

################### global variable declarations #######################
THIS_FILE=$(readlink -f ${0})
ECU_CONF_DIR[0]="/mnt/ExalogicControl/Configuration/software"
ECU_CONF_DIR[1]="/var/tmp/exalogic/ecu"
ECU_CONF_DIR[2]="/opt/exalogic/ecu/config"
ECU_OPS_PROPERTY_FILE=${ECU_OPS_PROPERTY_FILE:="ops_center.properties"}
WORK_DIR=$(dirname ${THIS_FILE})

LOCAL_TMP_DIR=${LOCAL_TMP_DIR:="/tmp/exatmp"}
SYS_TMP_DIR=${SYS_TMP_DIR:="/tmp/exatmp"}
D_ACTION="ALL"
IPS_WIDTH=190
IPS_COL_WIDTH=18

LOG_LEVEL="DEBUG"
BATCH_MODE="ON"

# rack info
#RACK_NAME="tlv04"
#RACK_TYPE=8
#EXA_VERSION
#VM_DEFAULT_PASSWORD=ovsroot

# assets IPs
#EXA_EC_IP
#EXA_PC_IP
#CNODES_IP[0]=""
#SNODES_IP
#IBSW_IP
#CNODES_ILOM_IP
#SNODES_ILOM_IP
#PDU_IP
#EXA_DB_IP
#EXA_OVMM_IP


# assets versions

# input
IN_FILENAME=""
# default output is screen + /dev/null
O_FILENAME="/dev/null"
O_FILENAME2="/dev/null"
#O_FILENAME="${WORK_DIR}/exadiscover.out"
O_PREFIX="assets_list"
O_SUFFIX="ECU"

################### basic functions #######################
# temp debug output function
f_decho()
{
	echo $* >/dev/null
}

f_global_init()
{
	f_decho "Initializing ... "
	IFS=$'\n'	
	if [ ! -e ${LOCAL_TMP_DIR} ]
	then
		mkdir ${LOCAL_TMP_DIR}
		chmod 777 ${LOCAL_TMP_DIR}
	fi
	if [ ! -e ${SYS_TMP_DIR} ]
	then
		mkdir ${SYS_TMP_DIR}
		chmod 777 ${SYS_TMP_DIR}
	fi
	cp ${WORK_DIR}/*.sql ${SYS_TMP_DIR}/
        chmod 755 ${SYS_TMP_DIR}/*.sql
	LocalTmpDir=$TMPDIR
	unset TMPDIR
}

f_global_clean()
{
	f_decho "final cleaning ... "
	rm -rf ${SYS_TMP_DIR}
	rm -rf ${LOCAL_TMP_DIR}
	export TMPDIR=$LocalTmpDir 
}

f_usage()
{
	echo "usage: $(basename $0) [options]"
	echo ""
	echo "options:"
	echo "  -a		verbose option to output more discovery information (affects non-human output only)"
	#echo "  -c		clean temporary files and output files -- for testing"
	echo "  -s <source>	specify discovery sources, e.g. ALL (default), ECU, EMOC, where <source> is one of:"
	echo "		ALL: ECU & EMOC (this permits comparison and warnings between sources, EMOC is the primary source)"
	echo "		ECU: extract information from ECU configuration files on the master node"
	echo "		EMOC: extract live information from EMOC"
	echo "  -f <format>	specify output format, e.g. human (default), shell"
	echo "  -h		show this help message and exit"
	echo "  -i filename	specify desired input file name and its path (ops_center.properties etc.)"
	echo "  -o <filename>	specify desired output file name and its path"
	echo "  -p <password>	specify general password, currently used for master node only"
	#echo "  -r R_ACTION	specify desired remote control actions -- todo"
	echo "  -v		version and compatibility information"
	echo "  -w <width>	specify table width for human readable output"
	echo ""
	echo "Note: some variables can be pre-defined by export:"
	echo " master node: CNODES_IP_0"
	echo " ECU configuration file name: ECU_OPS_PROPERTY_FILE"
	echo " local temporary folder: LOCAL_TMP_DIR"
	echo " system temporary folder: SYS_TMP_DIR"
	echo " OVMM root password (default: ovsroot): OVMM_ROOT_PASSWORD"
	echo ""
	echo "Some examples:"
	echo " $(basename $0) -s EMOC"
	echo " $(basename $0) -f shell"
	echo " $(basename $0) -f shell -a"
	echo ""
	exit 0
}

f_version()
{
	echo ""
	echo "** Version: 1.5.6"
	echo "** Tested on Exalogic 2.0.1.0.0, 2.0.2.0.0, 2.0.4.0.0, 2.0.6.0.0"
	echo ""
	exit 0
}

f_clean()
{
	rm -rf ${LOCAL_TMP_DIR}
	rm -rf ${WORK_DIR}/*.out
	echo "Temp files are cleaned!"
	exit 0
}

f_parse_input_parameters()
{
	while getopts "ace:f:hi:k:o:p:r:s:vw:z" optname
	do
        	case "$optname" in
        	"a")
				A_FLAG="all"
				;;
			"c")
				f_clean
				;;
			"s")
				D_ACTION=$OPTARG
				;;
			"e")
				EXEC_CMD=$OPTARG
				;;
			"f")
				if [ "$OPTARG" == "shell" ]
				then
					exec 3>&1
					exec 1>/dev/null					
					O_FORMAT=$OPTARG
				fi
				;;
			"h")
				f_usage
				;;
			"i")
				IN_FILENAME=$OPTARG
				;;
			"k")
				KEYWORD=$OPTARG
				;;
			"o")
				O_FILENAME2=$OPTARG
				;;
			"p")
				GENERAL_ROOT_PASSWORD=$OPTARG	
				;;
			"r")
				R_ACTION=$OPTARG
				;;
			"v")
				f_version
				;;
			"w")
				IPS_WIDTH=$OPTARG
				let IPS_COL_WIDTH=(IPS_WIDTH-10)/10
				;;
			"z")
				awk '{print NR "\t" $0}' ${THIS_FILE}|egrep "^[0-9]*	f_.*\(\)|^[0-9]*	###################"
				exit 0
				;;
			*)
				echo "Unknown error while processing options"
				;;
	        esac
	done
	
}

# remote leading and trailing whitespaces of a string
# $1: input string
f_trim() 
{
	local var=$1
	var="${var#"${var%%[![:space:]]*}"}"   # remove leading whitespace characters
	var="${var%"${var##*[![:space:]]}"}"   # remove trailing whitespace characters
	echo -n "$var"
}

# output a number with specified number of digits, e.g. if given number's length is less than given length, add 0s in the head
# $1: input number
# $2: length
f_o_number()
{
	printf "%0*d" $2 $1
}

# standard output function -- write values of internal variables into standard output file
# input of f_output:
# $1: output file name
# $2: heading 
# $3: new write or append a file
# $4: screen output on or off
f_output_ips()
{
	exec 4>&1
	if [ -z $4 ]
	then
		exec 1>/dev/null
	fi
	if [ "$3" == "new" ]
	then
		echo "#################################" | tee $1
	else
		echo "#################################" |tee -a $1
	fi

	if [ -z $2 ]
	then
		echo "#        Default heading" |tee -a $1
		echo "#################################" |tee -a $1
	else
		echo "#           ${2}" |tee -a $1
		echo "#################################" |tee -a $1
	fi

	echo "" |tee -a $1
		
	printf "%s\n" "${RACK_NAME[@]}"|awk '{if(NR<10) prefix_0="0"; else prefix_0=""; print "rack_name_" prefix_0 NR  "=" $0}' |tee -a $1
	printf "%s\n" "${RACK_SIZE[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "rack_size_" prefix_0 $1  "=" $2}' |tee -a $1
	printf "%s\n" "${RACK_ID[@]}"|awk '{if(NR<10) prefix_0="0"; else prefix_0=""; print "rack_id_" prefix_0 NR  "=" $0}' |tee -a $1
	printf "%s\n" "${EXA_EC_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "ec_ip_" prefix_0 $1  "=" $2}' |tee -a $1
	printf "%s\n" "${EXA_PC_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "pc_ip_" prefix_0 $1  "=" $2}' |tee -a $1
	printf "%s\n" "${CNODES_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "c_nodes_" prefix_0 $1  "=" $2}' |tee -a $1
	printf "%s\n" "${SNODES_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "sn_nodes_" prefix_0 $1  "=" $2}' |tee -a $1
	printf "%s\n" "${IBSW_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "ib_switch_" prefix_0 $1  "=" $2}' |tee -a $1
	printf "%s\n" "${IBSW_SPINE_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "ib_switch_spine_" prefix_0 $1  "=" $2}' |tee -a $1
	printf "%s\n" "${CNODES_ILOM_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "cn_ilom_" prefix_0 $1  "=" $2}' |tee -a $1
	printf "%s\n" "${SNODES_ILOM_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "sn_ilom_" prefix_0 $1  "=" $2}' |tee -a $1
	printf "%s\n" "${PDU_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "pdu_ip_" prefix_0 $1  "=" $2}' |tee -a $1
	printf "%s\n" "${EXA_OVMM_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "ovmm_ip_" prefix_0 $1  "=" $2}' |tee -a $1
	if [[ $(cat /usr/lib/init-exalogic-node/.template_version | grep "exalogic_version" | awk -F "=" {'print $2'} | awk -F "." {'print $1$2$3'}| awk '{print substr($0,2,4)}') -gt 204 ]]
	then 
		printf "%s\n" "${EXA_DB_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "db_" prefix_0 $1  "_IPoIB-admin=127.0.0.1"}' |tee -a $1
                printf "%s\n" "${EXA_DB_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "db_ip_" prefix_0 $1  "=127.0.0.1"}' |tee -a $1
	else
		printf "%s\n" "${EXA_DB_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "db_ip_" prefix_0 $1  "=" $2}' |tee -a $1
	fi

	echo "" |tee -a $1
	echo "" |tee -a $1
	echo "" |tee -a $1
	exec 1>&4
}

# output without any head information
f_output_ips2()
{
	if [ "${1}" == "/dev/null" ] || [ -z "${1}" ]
	then
		printf "%s\n" "${RACK_NAME[@]}"|awk '{if(NR<10) prefix_0="0"; else prefix_0=""; print "rack_name_" prefix_0 NR  "=" $0}' >&3
		printf "%s\n" "${RACK_SIZE[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "rack_size_" prefix_0 $1  "=" $2}' >&3
		printf "%s\n" "${RACK_ID[@]}"|awk '{if(NR<10) prefix_0="0"; else prefix_0=""; print "rack_id_" prefix_0 NR  "=" $0}' >&3
		printf "%s\n" "${EXA_EC_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "ec_ip_" prefix_0 $1  "=" $2}' >&3
		printf "%s\n" "${EXA_PC_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "pc_ip_" prefix_0 $1  "=" $2}' >&3
		printf "%s\n" "${CNODES_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "c_nodes_" prefix_0 $1  "=" $2}' >&3
		printf "%s\n" "${SNODES_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "sn_nodes_" prefix_0 $1  "=" $2}' >&3
		printf "%s\n" "${IBSW_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "ib_switch_" prefix_0 $1  "=" $2}' >&3
		printf "%s\n" "${IBSW_SPINE_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "ib_switch_spine_" prefix_0 $1  "=" $2}' >&3
		printf "%s\n" "${CNODES_ILOM_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "cn_ilom_" prefix_0 $1  "=" $2}' >&3
		printf "%s\n" "${SNODES_ILOM_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "sn_ilom_" prefix_0 $1  "=" $2}' >&3
		printf "%s\n" "${PDU_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "pdu_ip_" prefix_0 $1  "=" $2}' >&3
		printf "%s\n" "${EXA_OVMM_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "ovmm_ip_" prefix_0 $1  "=" $2}' >&3
		if [[ $(cat /usr/lib/init-exalogic-node/.template_version | grep "exalogic_version" | awk -F "=" {'print $2'} | awk -F "." {'print $1$2$3'}| awk '{print substr($0,2,4)}') -gt 204 ]]
        	then	
			printf "%s\n" "${EXA_DB_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "db_" prefix_0 $1 "_IPoIB-admin=127.0.0.1"}' >&3
			printf "%s\n" "${EXA_DB_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "db_ip_" prefix_0 $1  "=127.0.0.1"}' >&3
		else 
			printf "%s\n" "${EXA_DB_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "db_ip_" prefix_0 $1  "=" $2}' >&3
fi
	else
		printf "%s\n" "${RACK_NAME[@]}"|awk '{if(NR<10) prefix_0="0"; else prefix_0=""; print "rack_name_" prefix_0 NR  "=" $0}' >${1}
		printf "%s\n" "${RACK_SIZE[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "rack_size_" prefix_0 $1  "=" $2}' >> ${1}
		printf "%s\n" "${RACK_ID[@]}"|awk '{if(NR<10) prefix_0="0"; else prefix_0=""; print "rack_id_" prefix_0 NR  "=" $0}' >${1}
		printf "%s\n" "${EXA_EC_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "ec_ip_" prefix_0 $1  "=" $2}' >> ${1}
		printf "%s\n" "${EXA_PC_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "pc_ip_" prefix_0 $1  "=" $2}' >> ${1}
		printf "%s\n" "${CNODES_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "c_nodes_" prefix_0 $1  "=" $2}' >> ${1}
		printf "%s\n" "${SNODES_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "sn_nodes_" prefix_0 $1  "=" $2}' >> ${1}
		printf "%s\n" "${IBSW_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "ib_switch_" prefix_0 $1  "=" $2}' >> ${1}
		printf "%s\n" "${IBSW_SPINE_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "ib_switch_spine_" prefix_0 $1  "=" $2}' >> ${1}
		printf "%s\n" "${CNODES_ILOM_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "cn_ilom_" prefix_0 $1  "=" $2}' >> ${1}
		printf "%s\n" "${SNODES_ILOM_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "sn_ilom_" prefix_0 $1  "=" $2}' >> ${1}
		printf "%s\n" "${PDU_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "pdu_ip_" prefix_0 $1  "=" $2}' >> ${1}
		printf "%s\n" "${EXA_OVMM_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "ovmm_ip_" prefix_0 $1  "=" $2}' >> ${1}
 		if [[ $(cat /usr/lib/init-exalogic-node/.template_version | grep "exalogic_version" | awk -F "=" {'print $2'} | awk -F "." {'print $1$2$3'}| awk '{print substr($0,2,4)}') -gt 204 ]]
        	then
			printf "%s\n" "${EXA_DB_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "db_" prefix_0 $1 "_IPoIB-admin=127.0.0.1"}' >> ${1}
			printf "%s\n" "${EXA_DB_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "db_ip_" prefix_0 $1  "=127.0.0.1"}' >> ${1}
		else 
			printf "%s\n" "${EXA_DB_IP[@]}"|nl|awk '{if($1<10) prefix_0="0"; else prefix_0=""; print "db_ip_" prefix_0 $1  "=" $2}' >> ${1}
		fi
	fi
}

f_clear_var_ips()
{

	unset 	RACK_NAME
	unset 	RACK_SIZE
	unset	RACK_ID
	unset 	EXA_EC_IP
	unset 	EXA_PC_IP
	unset 	CNODES_IP
	unset 	SNODES_IP
	unset 	IBSW_IP
	unset 	IBSW_SPINE_IP
	unset 	CNODES_ILOM_IP
	unset 	SNODES_ILOM_IP
	unset 	PDU_IP
	unset 	EXA_DB_IP
	unset 	EXA_OVMM_IP
}

# ensure each entry gets only one name/ip, pick the first one if there are multiple ips
f_unique_ips()
{
    vars="RACK_NAME RACK_SIZE RACK_ID EXA_EC_IP EXA_PC_IP CNODES_IP SNODES_IP IBSW_IP \
                    IBSW_SPINE_IP CNODES_ILOM_IP SNODES_ILOM_IP PDU_IP EXA_DB_IP EXA_OVMM_IP"
    for var in $(echo $vars | tr ' ' '\n')
    do
	var_len=$(eval echo "\${#$var[@]}")
        for index in $(seq 0 $(expr $var_len - 1))
        do
            values[$index]=$(eval echo "\${$var[$index]}")
        done
        for ((i=0; i<${#values[@]}; i++))
        do
            if [[ $(echo ${values[$i]} | grep -c ',') > 0 ]]; then
                eval values[$i]=$(echo ${values[$i]} | tr ',' '\n' | uniq | tr '\n' ','|sed 's/,$/\n/')
                f_log "$var has multiple values: $value. Removed duplicates, got: $(eval echo \$$var)." WARN
            fi
        done
        for index in $(seq 0 $(expr $var_len - 1))
        do
            eval $var[$index]=\"${values[$index]}\"
        done
    done
}

# read IPs from standard output file into internal variables
# $1: intput file name
f_input_ips()
{
	f_clear_var_ips
	RACK_NAME=( $(grep "^rack_name_" $1 | cut -d"=" -f2) )
	RACK_SIZE=( $(grep "^rack_size_" $1 | cut -d"=" -f2) )
	RACK_ID=( $(grep "^rack_id_" $1 | cut -d"=" -f2) )
	EXA_EC_IP=( $(grep "^ec_ip_" $1 | cut -d"=" -f2) )
	EXA_PC_IP=( $(grep "^pc_ip_" $1 | cut -d"=" -f2) )
	CNODES_IP=( $(grep "^c_nodes_" $1 | cut -d"=" -f2) )
	SNODES_IP=( $(grep "^sn_nodes_" $1 | cut -d"=" -f2) )
	IBSW_IP=( $(egrep "^ib_switch_[0-9]" $1 | cut -d"=" -f2) )
	IBSW_SPINE_IP=( $(grep "^ib_switch_spine_" $1 | cut -d"=" -f2) )
	CNODES_ILOM_IP=( $(grep "^cn_ilom_" $1 | cut -d"=" -f2) )
	SNODES_ILOM_IP=( $(grep "^sn_ilom_" $1 | cut -d"=" -f2) )
	PDU_IP=( $(grep "^pdu_ip_" $1 | cut -d"=" -f2) )
	EXA_DB_IP=( $(grep "^db_ip_" $1 | cut -d"=" -f2) )
	EXA_OVMM_IP=( $(grep "^ovmm_ip_" $1 | cut -d"=" -f2) )
	f_unique_ips
}


# read IPs from standard output file into internal variables and add in logical verification
# $1: intput file name
f_input_ips2()
{

	f_clear_var_ips
	RACK_NAME=( $(grep "^rack_name_" $1 | cut -d"=" -f2) )
	RACK_SIZE=( $(grep "^rack_size_" $1 | cut -d"=" -f2) )
	RACK_ID=( $(grep "^rack_id_" $1 | cut -d"=" -f2) )
	local tmp_rack_size
	local tmp_total_cnodes=0
	local j=0
	for i in "${RACK_SIZE[@]}"
	do
        	if [ "$i" == "Eighth" ]
	        then
        	        tmp_rack_size[$j]=4
        	elif [ "$i" == "Quarter" ]
	        then
        	        tmp_rack_size[$j]=8
	        elif [ "$i" == "Half" ]
        	then
	                tmp_rack_size[$j]=16
        	elif [ "$i" == "Full" ]
	        then
        	        tmp_rack_size[$j]=30
	        fi
		let tmp_total_cnodes=tmp_total_cnodes+tmp_rack_size[$j]
        	let j+=1
	done

	EXA_EC_IP=( $(grep "^ec_ip_" $1 | cut -d"=" -f2) )
	EXA_PC_IP=( $(grep "^pc_ip_" $1 | cut -d"=" -f2) )
	CNODES_IP=( $(grep "^c_nodes_" $1 | cut -d"=" -f2) )
	SNODES_IP=( $(grep "^sn_nodes_" $1 | cut -d"=" -f2) )
	IBSW_IP=( $(grep "^ib_switch_" $1 | cut -d"=" -f2) )
	IBSW_SPINE_IP=( $(grep "^ib_switch_spine_" $1 | cut -d"=" -f2) )
	CNODES_ILOM_IP=( $(grep "^cn_ilom_" $1 | cut -d"=" -f2) )
	SNODES_ILOM_IP=( $(grep "^sn_ilom_" $1 | cut -d"=" -f2) )
	PDU_IP=( $(grep "^pdu_ip_" $1 | cut -d"=" -f2) )
	EXA_DB_IP=( $(grep "^db_ip_" $1 | cut -d"=" -f2) )
	EXA_OVMM_IP=( $(grep "^ovmm_ip_" $1 | cut -d"=" -f2) )
    f_unique_ips
}


# define log level -- todo
# $1: message
# $2: level
f_log()
{
	local msg=$1
	local log_level=$2
	
	if [ "log_level" == "debug" ]
	then
		echo -e [$(date --utc "+%Y-%m-%d %H:%M:%S")][DEBUG]: ${msg} >&2
		return 0
	fi	
	echo -e [$(date --utc "+%Y-%m-%d %H:%M:%S")][$log_level]: ${msg} >&2
}

# f_remote_run is to run a command on a remote node
# input of f_remote_run:
# $1 -- remote user and host
# $2 -- remote command
# $3 -- remote password
f_remote_run()
{
	/usr/bin/expect <<EOD 2>&1 | sed "s/^/      /"
	spawn ssh ${1} ${2}
	expect {
		"*?assword:*" {
			send "${3}\r"
			exp_continue
		}
		"*]#" {
		}
	}
EOD
}

# f_remote_run2 is to copy scripts to a remote node and run them
# input of f_remote_run2:
# $1 -- remote user and host
# $2 -- remote command
# $3 -- remote password
f_remote_run2()
{
	echo ${2} > ${LOCAL_TMP_DIR}/tmp_cmd.sh
	chmod +x ${LOCAL_TMP_DIR}/tmp_cmd.sh
	f_scp ${LOCAL_TMP_DIR}/tmp_cmd.sh ${1}:/tmp $3  > /dev/null
        /usr/bin/expect <<EOD 2>&1 | sed "s/^/      /"
        spawn ssh ${1} "/tmp/tmp_cmd.sh;rm -rf /tmp/tmp_cmd.sh"
        expect {
                "*?assword:*" {
                        send "${3}\r"
                        exp_continue
                }
                "*]#" {
                }
        }
EOD
}


# input of f_scp:
# $1 -- source
# $2 -- destination
# $3 -- password (optional)
f_scp()
{
        /usr/bin/expect <<EOD 2>&1 | sed "s/^/      /"
        spawn scp -r -q -oStrictHostKeyChecking=no -oCheckHostIP=no ${1} ${2}/
        expect {
                "*?assword:*" {
                        send "${3}\r"
                        exp_continue
                }
                "*]#" {
                }
        }
EOD
}

# temp scp function -- toenhance
f_scp2()
{
	/usr/bin/expect <<EOD 2>&1 | sed "s/^/      /"
	spawn scp -r -q -oStrictHostKeyChecking=no -oCheckHostIP=no root@${1}:${2} ${3}/
	expect {
		"*?assword:*" {
			send "${4}\r"
			exp_continue
		}
		"*]#" {
		}
	}
EOD
}

# for execute sql on control db -- tocomplete
f_ops_sqlplus()
{
	local target_sql=$1
	local SQLPLUS="/opt/sun/xvmoc/bin/ecadm"
	if [ ! -e ${SQLPLUS} ]
	then
		echo "${SQLPLUS} not found! Possible reason: this is not EC1 VM or Ops Center is not installed properly."
		return 1
	fi
	SQLPLUS="${SQLPLUS} sqlplus"
	echo ""
	local sql_output="${SYS_TMP_DIR}/tmp_sql.out"
	O_SUFFIX="EMOC"
	local output_file=${LOCAL_TMP_DIR}/${O_PREFIX}_${RACK_NAME}_${O_SUFFIX}.out

	eval $SQLPLUS >/dev/null 2>&1 <<EOF
	set head off
	set lines 150
	set pages 0
	set feedback off
	set trims on
	spool $sql_output 
	@${target_sql}
	spool off
	exit
EOF
	grep -v SQL $sql_output | grep -v Connected > $output_file
}

################### business logic functions #######################

# run commands on specified remote assets
# $1: keyword for assets
# $2: command
# $3: password
f_run_cmd_on_assets()
{
	local input_file=${O_FILENAME}
	local ip=( $(grep "${1}" ${input_file}|cut -d= -f2) )
	for i in "${ip[@]}"
	do
		f_remote_run2 ${i} "${2}" ${3}
	done
}


f_get_db_ip()
{
	local ec_vm_db_props=/var/opt/sun/xvm/db.properties
	if [ ! -e ${ec_vm_db_props} ]
	then
		echo "${ec_vm_db_props} not found. The current host is probably not an EC vm."
		return 1
	fi
	EXA_DB_IP=$(grep mgmtdb.dburl ${ec_vm_db_props}|cut -d@ -f2|cut -d: -f1)
}

f_get_ovmm_ip()
{
	local SQLPLUS="/opt/sun/xvmoc/bin/ecadm"
	if [ ! -e ${SQLPLUS} ]
	then
		echo "${SQLPLUS} not found! Possible reason: this is not EC1 VM or Ops Center is not installed properly."
		return 1
	fi
	SQLPLUS="${SQLPLUS} sqlplus"
	
	echo ""
	local sql_output="${SYS_TMP_DIR}/tmp_ovmm_ip.out"

	eval $SQLPLUS >/dev/null 2>&1 <<EOF
	set head off
	set lines 150
	set pages 0
	set feedback off
	set trims on
	col ip for a20
	spool $sql_output 
	@${SYS_TMP_DIR}/list_ovmm.sql
	spool off
	exit
EOF
	EXA_OVMM_IP=$(grep -v SQL $sql_output | grep -v Connected)
	if [ ! ${OVMM_ROOT_PASSWORD} ]
	then
		eval EXA_OVMM_IPS=( $(f_remote_run root@${EXA_OVMM_IP} ifconfig ${VM_DEFAULT_PASSWORD} |grep inet | cut -d":" -f2|cut -d" " -f1|grep -v "127.0.0.1") )
	else
		eval EXA_OVMM_IPS=( $(f_remote_run root@${EXA_OVMM_IP} ifconfig ${OVMM_ROOT_PASSWORD} |grep inet | cut -d":" -f2|cut -d" " -f1|grep -v "127.0.0.1") )
	fi
	if [ ! ${EXA_OVMM_IPS} ] && [ "${#EXA_OVMM_IPS[@]}" -eq 0 ]
	then
		EXA_OVMM_IPS[0]=${EXA_OVMM_IP}
	fi
	#printf "czp: %s\n" "${EXA_OVMM_IPS[@]}"
}

f_read_ecu_config()
{
	local cnode_01_ip=$1;
	local output_file=${LOCAL_TMP_DIR}/${O_PREFIX}_${RACK_NAME}_${O_SUFFIX}.out
	
	f_scp2 ${cnode_01_ip} ${ECU_CONF_DIR[0]}/${ECU_OPS_PROPERTY_FILE} ${LOCAL_TMP_DIR} ${GENERAL_ROOT_PASSWORD} >/dev/null 2>&1
	if [ ! -e ${LOCAL_TMP_DIR}/${ECU_OPS_PROPERTY_FILE} ]
	then
	        f_scp2 ${cnode_01_ip} ${ECU_CONF_DIR[1]}/${ECU_OPS_PROPERTY_FILE} ${LOCAL_TMP_DIR} ${GENERAL_ROOT_PASSWORD} >/dev/null 2>&1
	        if [ ! -e ${LOCAL_TMP_DIR}/${ECU_OPS_PROPERTY_FILE} ]
	        then
	                f_scp2 ${cnode_01_ip} ${ECU_CONF_DIR[2]}/${ECU_OPS_PROPERTY_FILE} ${LOCAL_TMP_DIR} ${GENERAL_ROOT_PASSWORD} >/dev/null 2>&1
	                if [ ! -e ${LOCAL_TMP_DIR}/${ECU_OPS_PROPERTY_FILE} ]
	                then
	                        echo "${ECU_OPS_PROPERTY_FILE} not found, please check!"
	                        return 1
	                fi
	        fi
	fi

	RACK_NAME=( $(grep "^ecu_rack_name_" ${LOCAL_TMP_DIR}/${ECU_OPS_PROPERTY_FILE} | cut -d"=" -f2) )
	RACK_SIZE=( $(grep "^ecu_rack_size_" ${LOCAL_TMP_DIR}/${ECU_OPS_PROPERTY_FILE} | cut -d"=" -f2) )
	EXA_EC_IP=( $(grep "^ecu_ec_ip_" ${LOCAL_TMP_DIR}/${ECU_OPS_PROPERTY_FILE} | cut -d"=" -f2) )
	EXA_PC_IP=( $(grep "^ecu_pc_ip_" ${LOCAL_TMP_DIR}/${ECU_OPS_PROPERTY_FILE} | cut -d"=" -f2|sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n) )
	CNODES_IP=( $(grep "^ecu_server_osip_" ${LOCAL_TMP_DIR}/${ECU_OPS_PROPERTY_FILE} | cut -d"=" -f2|sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n) )
	SNODES_IP=( $(grep "^ecu_storage_ip_.*snigb[0-9]" ${LOCAL_TMP_DIR}/${ECU_OPS_PROPERTY_FILE} | cut -d"=" -f2|sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n) )
	IBSW_IP=( $(grep "^ecu_infswitch_ip_" ${LOCAL_TMP_DIR}/${ECU_OPS_PROPERTY_FILE} | cut -d"=" -f2|sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n) )
	local cn_prefix=$(grep "^ecu_server_osip_"  ${LOCAL_TMP_DIR}/${ECU_OPS_PROPERTY_FILE} | cut -d"=" -f1|sed 's/^ecu_server_osip_/^ecu_server_ilomip_/g')
	CNODES_ILOM_IP=( $(grep "$cn_prefix" ${LOCAL_TMP_DIR}/${ECU_OPS_PROPERTY_FILE} | cut -d"=" -f2|sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n) )
	local sn_prefix=$(grep "ecu_storage_rackid_.*igb0" ${LOCAL_TMP_DIR}/${ECU_OPS_PROPERTY_FILE} |cut -d"=" -f1|cut -d"_" -f4|awk -F'igb0' '{print "^ecu_server_ilomip_" $1}')
	sn_prefix=$(echo ${sn_prefix[@]}|tr " " "|")
	SNODES_ILOM_IP=( $(egrep "${sn_prefix}" ${LOCAL_TMP_DIR}/${ECU_OPS_PROPERTY_FILE} | cut -d"=" -f2|sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n) )
	PDU_IP=( $(grep "^ecu_pdu_ip_" ${LOCAL_TMP_DIR}/${ECU_OPS_PROPERTY_FILE} | cut -d"=" -f2|sort -t . -k 1,1n -k 2,2n -k 3,3n -k 4,4n) )
	EXA_DB_IP=( $(grep "^ecu_db_ip_" ${LOCAL_TMP_DIR}/${ECU_OPS_PROPERTY_FILE} | cut -d"=" -f2) )
	EXA_OVMM_IP=( $(grep "^ecu_ovmm_ip_" ${LOCAL_TMP_DIR}/${ECU_OPS_PROPERTY_FILE} | cut -d"=" -f2) )
	f_output_ips ${LOCAL_TMP_DIR}/tmp_mainip_ecu.txt "ECU" new
}

# read ECU configuration (i.e. ops_center.properties) from local directory
# $1: full path of the intput file 
f_read_ecu_config2()
{
	local output_file=${LOCAL_TMP_DIR}/${O_PREFIX}_${RACK_NAME}_${O_SUFFIX}.out
	if [ ! -e ${1} ]
	then
		echo "${1} not found, please check!"
		return 1
	fi
	RACK_NAME=( $(grep "^ecu_rack_name_" $1 | cut -d"=" -f2) )
	RACK_SIZE=( $(grep "^ecu_rack_size_" $1 | cut -d"=" -f2) )
	EXA_EC_IP=( $(grep "^ecu_ec_ip_" $1 | cut -d"=" -f2) )
	EXA_PC_IP=( $(grep "^ecu_pc_ip_" $1 | cut -d"=" -f2) )
	CNODES_IP=( $(grep "^ecu_server_osip_" $1 | cut -d"=" -f2) )
	SNODES_IP=( $(grep "^ecu_storage_ip_.*snigb[0-9]" $1 | cut -d"=" -f2) )
	IBSW_IP=( $(grep "^ecu_infswitch_ip_" $1 | cut -d"=" -f2) )
	local cn_prefix=$(grep "^ecu_server_osip_"  $1 | cut -d"=" -f1|sed 's/^ecu_server_osip_/^ecu_server_ilomip_/g')
	CNODES_ILOM_IP=( $(grep "$cn_prefix" $1 | cut -d"=" -f2) )
	local sn_prefix=$(grep "ecu_storage_rackid_.*igb0" $1 |cut -d"=" -f1|cut -d"_" -f4)
	sn_prefix=${sn_prefix%%igb0}
	SNODES_ILOM_IP=( $(grep "^ecu_server_ilomip_${sn_prefix}" $1 | cut -d"=" -f2) )
	PDU_IP=( $(grep "^ecu_pdu_ip_" $1 | cut -d"=" -f2) )
	EXA_DB_IP=( $(grep "^ecu_db_ip_" $1 | cut -d"=" -f2) )
	EXA_OVMM_IP=( $(grep "^ecu_ovmm_ip_" $1 | cut -d"=" -f2) )
	f_output_ips ${LOCAL_TMP_DIR}/tmp_mainip_ecu.txt "ECU" new
}

f_read_control_db()
{
	local SQLPLUS="/opt/sun/xvmoc/bin/ecadm"
	if [ ! -e ${SQLPLUS} ]
	then
		echo "${SQLPLUS} not found! Possible reason: this is not EC1 VM or Ops Center is not installed properly."
		return 1
	fi
	SQLPLUS="${SQLPLUS} sqlplus"
	echo ""
	local sql_output="${SYS_TMP_DIR}/tmp_sql.out"
	O_SUFFIX="EMOC"
	local output_file=${LOCAL_TMP_DIR}/${O_PREFIX}_${RACK_NAME}_${O_SUFFIX}.out

	eval $SQLPLUS >/dev/null 2>&1  <<EOF
	set head off
	set lines 200
	set pages 0
	set feedback off
	set trims on
	col ip2 for a100
	spool $sql_output 
	@${SYS_TMP_DIR}/list_assets.sql
	spool off
	exit
EOF
        sn_fe_ip=$(grep 'sn_nodes_03' $sql_output | cut -d '=' -f 2)
        sed -i.bak '/sn_nodes_03/d' $sql_output
	grep -v SQL $sql_output | grep -v Connected > ${LOCAL_TMP_DIR}/tmp.out
	f_get_db_ip
	echo "db_ip_01=${EXA_DB_IP}" >> ${LOCAL_TMP_DIR}/tmp.out
	sed -e "3 i\\$(ifconfig bond1 | grep 'inet addr:' | cut -d: -f2 | awk '{ print "ec_ip_01=" $1}')" ${LOCAL_TMP_DIR}/tmp.out >$output_file
	rm -rf ${LOCAL_TMP_DIR}/tmp.out
	f_input_ips $output_file
	f_output_ips ${LOCAL_TMP_DIR}/tmp_mainip_db.txt "EMOC" new
	rm -rf $output_file
}

f_get_master_node_ip()
{
	if [ CNODES_IP_0 ] && [ "$CNODES_IP_0" != "" ]
	then
		CNODES_IP[0]=${CNODES_IP_0}
		return 0
	fi
	local SQLPLUS="/opt/sun/xvmoc/bin/ecadm"
	if [ ! -e ${SQLPLUS} ]
	then
		echo "${SQLPLUS} not found! Possible reason: this is not EC1 VM or Ops Center is not installed properly."
		return 1
	fi
	SQLPLUS="${SQLPLUS} sqlplus"
	
	echo ""
	local sql_output="${SYS_TMP_DIR}/tmp_master_node_ip.out"

	eval $SQLPLUS >/dev/null 2>&1 <<EOF
	set head off
	set lines 150
	set pages 0
	set feedback off
	set trims on
	col ipaddress for a20
	spool $sql_output 
	@${SYS_TMP_DIR}/list_master_node.sql
	#select trim(ipaddress) from (select  ipaddress from VDO_SERV_TAG_INFO where upper(productname) like '%ORACLE VM SERVER%' order by host) where rownum<2;
	spool off
	exit
EOF
	CNODES_IP[0]=$(grep -v SQL $sql_output | grep -v Connected)
}

# check the differece between results of reading from ECU and EMOC 
# $1: output file name
# $2: flag for new file or appending to an old file
f_diff_reading()
{
	local ecu_file=${LOCAL_TMP_DIR}/tmp_mainip_ecu.txt
	local db_file=${LOCAL_TMP_DIR}/tmp_mainip_db.txt
	dos2unix $ecu_file > /dev/null 2>&1
	dos2unix $db_file > /dev/null 2>&1
	
	if [ ! -e "${ecu_file}" ] && [ ! -e ${db_file} ]
	then
		return 0
	fi
	if [ "$2" == "new" ]
	then
		echo "#################################" | tee $1
	else
		echo "#################################" |tee -a $1
	fi

	echo "#      Anomalies Detected" |tee -a $1
	echo "#################################" |tee -a $1

	echo "" |tee -a $1

	
	if [ -e "${ecu_file}" ] && [ -e ${db_file} ]
	then
		awk -F'=' 'NR==FNR&&FNR>4{if($0!="") {a[$1]=$2;b[$2]=$1;}}NR>FNR&&FNR>4{if($0!=""&&a[$1]=="") print "[ECU] " $1 " is missing in EMOC"; if($0!=""&&a[$1]==""&&b[$2]=="") print "[ECU] " $1 "=" $2 " is missing in EMOC"; if($0!=""&&a[$1]!=""&&a[$1]!=$2&&b[$2]=="") print "[ECU] " $1 " has different value \"" $2 "\" with EMOC \"" a[$1] "\""; if($0!=""&&a[$1]!=""&&a[$1]!=$2&&b[$2]!="") print "[ECU] " $1 " has different value \"" $2 "\" with EMOC \"" a[$1] "\", but equal to EMOC " b[$2];}' ${db_file} ${ecu_file} | tee -a $1
		echo "" | tee -a $1
		echo "" | tee -a $1
		awk -F'=' 'NR==FNR&&FNR>4{if($0!="") {a[$1]=$2;b[$2]=$1;}}NR>FNR&&FNR>4{if($0!=""&&a[$1]=="") print "[EMOC] " $1 " is missing in ECU"; if($0!=""&&a[$1]==""&&b[$2]=="") print "[EMOC] " $1 "=" $2 " is missing in ECU"; if($0!=""&&a[$1]!=""&&a[$1]!=$2&&b[$2]=="") print "[EMOC] " $1 " has different value \"" $2 "\" with ECU \"" a[$1] "\""; if($0!=""&&a[$1]!=""&&a[$1]!=$2&&b[$2]!="") print "[EMOC] " $1 " has different value \"" $2 "\" with ECU \"" a[$1] "\", but equal to ECU " b[$2];}' ${ecu_file} ${db_file} | tee -a $1
	fi

	if [ -e ${db_file} ]
	then
		f_input_ips ${db_file}
		
		local tmp_rack_size
		local tmp_total_cnodes=0
		local j=0
		for i in "${RACK_SIZE[@]}"
		do
			if [ "$i" == "Eighth" ]
			then
				tmp_rack_size[$j]=4
			elif [ "$i" == "Quarter" ]
			then
				tmp_rack_size[$j]=8
			elif [ "$i" == "Half" ]
        	then
				tmp_rack_size[$j]=16
	        elif [ "$i" == "Full" ]
			then
				tmp_rack_size[$j]=30
			fi
			let tmp_total_cnodes=tmp_total_cnodes+tmp_rack_size[$j]
			let j+=1
		done
		if [ ${#CNODES_IP[@]} != ${tmp_total_cnodes} ]
		then
			echo "[WARNING][EMOC] the number of compute nodes is supposed to be ${tmp_total_cnodes}, but only ${#CNODES_IP[@]} found in EMOC"  | tee -a $1
		fi
		if [ ${#CNODES_ILOM_IP[@]} != ${tmp_total_cnodes} ]
		then
			echo "[WARNING][EMOC] the number of ILOM of compute nodes is supposed to be ${tmp_total_cnodes}, but only ${#CNODES_ILOM_IP[@]} found in EMOC"  | tee -a $1
		fi
		if [ ${#CNODES_ILOM_IP[@]} != ${#CNODES_IP[@]} ]
		then
			printf "[WARNING][EMOC] the numbers of compute nodes and ILOM of compute nodes don\'t match in EMOC (${#CNODES_IP[@]} vs. ${#CNODES_ILOM_IP[@]}), c_nodes and cn_ilom may not be correlated correctly.\n"  | tee -a $1
		fi
	fi
	

	echo "" | tee -a $1
	echo "" | tee -a $1
	echo "" | tee -a $1
}

# read all ips of the assets and output human readable
f_read_all_ips()
{
	f_get_db_ip
	if [ ${EXA_DB_IP} ]
	then
		eval sed -i.bak 's/192.168.20.10/${EXA_DB_IP}/g' ${SYS_TMP_DIR}/list_all_ips.sql
	fi
	f_get_ovmm_ip
	if [ ${EXA_OVMM_IPS} ]
	then
		local tmp_ovm_ips_num=${#EXA_OVMM_IPS[@]}
		local tmp_ovm_ip_cols=""
		local tmp_ovm_ips_value=""
		local tmp_ip=""
		local tmp_i=1
		for tmp_ip in "${EXA_OVMM_IPS[@]}"
		do
			if [ "${tmp_i}" -lt "${tmp_ovm_ips_num}" ]
			then
				tmp_ovm_ip_cols="${tmp_ovm_ip_cols}${tmp_i}, ip${tmp_i}, "
				tmp_ovm_ips_value="${tmp_ovm_ips_value}'${tmp_ip}' as ip${tmp_i}, "
			else
				tmp_ovm_ip_cols="${tmp_ovm_ip_cols}${tmp_i}, ip${tmp_i}"
				tmp_ovm_ips_value="${tmp_ovm_ips_value}'${tmp_ip}' as ip${tmp_i}"
			fi
			let tmp_i=tmp_i+1
		done
		eval sed -i.bak 's/ovm_ips_num/${tmp_ovm_ips_num}/g' ${SYS_TMP_DIR}/list_all_ips.sql
		eval sed -i.bak 's/ovm_ip_cols/${tmp_ovm_ip_cols}/g' ${SYS_TMP_DIR}/list_all_ips.sql
		eval sed -i.bak 's/ovm_ips_value/${tmp_ovm_ips_value}/g' ${SYS_TMP_DIR}/list_all_ips.sql
	else
		tmp_ovm_ip_cols="1, ip1"
		tmp_ovm_ips_value="'192.168.20.11' as ip1"		
		eval sed -i.bak 's/ovm_ips_num/1/g' ${SYS_TMP_DIR}/list_all_ips.sql
		eval sed -i.bak 's/ovm_ip_cols/${tmp_ovm_ip_cols}/g' ${SYS_TMP_DIR}/list_all_ips.sql
		eval sed -i.bak 's/ovm_ips_value/${tmp_ovm_ips_value}/g' ${SYS_TMP_DIR}/list_all_ips.sql
	fi
	local SQLPLUS="/opt/sun/xvmoc/bin/ecadm"
	if [ ! -e ${SQLPLUS} ]
	then
		echo "${SQLPLUS} not found! Possible reason: this is not EC1 VM or Ops Center is not installed properly."
		return 1
	fi
	SQLPLUS="${SQLPLUS} sqlplus"
	echo ""
	local sql_output="${SYS_TMP_DIR}/tmp_sql_allips.out"

	eval $SQLPLUS >/dev/null 2>&1 <<EOF
	set head off
	set lines $IPS_WIDTH
	set pages 0
	set feedback off
	set trims on
	set term on
	set colsep "|"
	set recsep each
	set recsepchar "-"
	set colsep "|"
	col col1 for a${IPS_COL_WIDTH}
	col IP1 for a${IPS_COL_WIDTH}
	col IP2 for a${IPS_COL_WIDTH}
	col ip3 for a${IPS_COL_WIDTH}
	col IP4 for a${IPS_COL_WIDTH}
	col IP5 for a${IPS_COL_WIDTH}
	col IP6 for a${IPS_COL_WIDTH}
	col IP7 for a${IPS_COL_WIDTH}
	col IP8 for a${IPS_COL_WIDTH}
	col hostname for a${IPS_COL_WIDTH}
	spool $sql_output 
	@${SYS_TMP_DIR}/list_all_ips.sql
	spool off
	exit
EOF
#	if [ -e ${SYS_TMP_DIR}/list_all_ips.sql.bak ]
#	then
#		mv -f ${SYS_TMP_DIR}/list_all_ips.sql.bak ${SYS_TMP_DIR}/list_all_ips.sql
#	fi
        sn_fe=$(grep 'sn_nodes.*,' $sql_output)
        ret=$?
        if [ $ret -eq 0 ]
        then
            del_index=$(nl $sql_output|grep "${sn_fe}"|awk '{print $1}')
            sn_ip1=$(echo "${sn_fe}" | cut -d '|' -f 8 | cut -d ',' -f 1)
            sn_ip2_tmp1=$(echo "${sn_fe}" | cut -d '|' -f 8 | cut -d ',' -f 2)
            sn_ip2_tmp2=$(sed -n "$((${del_index}+1))p" $sql_output | cut -d '|' -f 8 | cut -c -11)
            sn_ip2=${sn_ip2_tmp1}${sn_ip2_tmp2}

            sed -i.bak "$((${del_index}+1))d" $sql_output

            if [ ${sn_ip1} == ${sn_fe_ip} ]
            then
                sn_fe_1=$(echo "${sn_fe}" | cut -d '|' -f 1-7)
                sn_fe_2=$(echo "${sn_fe}" | cut -d '|' -f 9,10)
                sn_fe=${sn_fe_1}"|${sn_ip2}    |"${sn_fe_2}
            else
                sn_fe_1=$(echo "${sn_fe}" | cut -d ',' -f 1)
                sn_fe_2=$(echo "${sn_fe}" | cut -d ',' -f 2 | cut -c 4-)
                sn_fe=${sn_fe_1}"    "${sn_fe_2}
            fi
            sed -i.bak "s/.*sn_nodes.*,.*/${sn_fe}/g" $sql_output
        fi

	echo "#################################"  | tee -a $O_FILENAME
	echo "# Full list of IPs from EMOC"  | tee -a $O_FILENAME
	echo "#################################"  | tee -a $O_FILENAME
	echo "" | tee -a $O_FILENAME
	eval printf '%0.1s' "-"{1..${IPS_WIDTH}}  | tee -a $O_FILENAME
	echo ""  | tee -a $O_FILENAME
	if [ -e ${LOCAL_TMP_DIR}/tmp_mainip_db.txt ]
	then
		local index=$(cat ${LOCAL_TMP_DIR}/tmp_mainip_db.txt |awk '{print NR, $0}' |grep "#           EMOC"|awk '{if($3=="EMOC") print $1}')
		if [ index!=0 ]
		then
			sed -n "$((${index}+5)),$ p" ${LOCAL_TMP_DIR}/tmp_mainip_db.txt|cut -d= -f2|awk '{ if($0!="") print "\\b" $0 "\\b"}' > ${LOCAL_TMP_DIR}/tmp_mainip.txt
			echo "$" >> ${LOCAL_TMP_DIR}/tmp_mainip.txt
			export GREP_COLOR='1;34'
			grep -v SQL $sql_output | egrep --color=always -rf ${LOCAL_TMP_DIR}/tmp_mainip.txt | tee -a $O_FILENAME
			echo "** Blue IPs are recommened as on-rack access points." | tee -a $O_FILENAME
		else
			grep -v SQL $sql_output | tee -a $O_FILENAME
		fi
	else
		grep -v SQL $sql_output | tee -a $O_FILENAME
	fi
	echo "" | tee -a $O_FILENAME
	echo "" | tee -a $O_FILENAME
	echo "" | tee -a $O_FILENAME
}

# read through a file and modify it to have unique ip instead of duplicate ones
f_unique_file()
{
    local tmp_file=$1
    for num in $(grep -n ',' $tmp_file | cut -d: -f1); do
       local var=$(sed -n ${num}p $tmp_file | awk -F '=' '{ print $ 1}')
       local value=$(sed -n ${num}p $tmp_file | awk -F '=' '{ print $ NF}')
       local new_value=$(echo "$value" | tr ',' '\n' | uniq | tr '\n' ',' | sed 's/,$/\n/')
       if [[ $value != $new_value ]]; then
           f_log "$var has multiple values: $value. Removed duplicates, got: $new_value." WARN
       fi
       eval sed -i.bak 's/$value/$new_value/g' $tmp_file
    done
}

# read all ips of the assets and output machine readable
f_read_all_ips_vars()
{
	f_get_db_ip
	if [ ${EXA_DB_IP} ]
	then
		eval sed -i.bak 's/192.168.20.10/${EXA_DB_IP}/g' ${SYS_TMP_DIR}/list_all_ips_vars.sql
	fi
	f_get_ovmm_ip
	if [ ${EXA_OVMM_IPS} ]
	then
		local tmp_ovm_ips_num=${#EXA_OVMM_IPS[@]}
		local tmp_ovm_ip_cols=""
		local tmp_ovm_ips_value=""
		local tmp_ip=""
		local tmp_i=1
		for tmp_ip in "${EXA_OVMM_IPS[@]}"
		do
			if [ "${tmp_i}" -lt "${tmp_ovm_ips_num}" ]
			then
				tmp_ovm_ip_cols="${tmp_ovm_ip_cols}${tmp_i}, ip${tmp_i}, "
				tmp_ovm_ips_value="${tmp_ovm_ips_value}'${tmp_ip}' as ip${tmp_i}, "
			else
				tmp_ovm_ip_cols="${tmp_ovm_ip_cols}${tmp_i}, ip${tmp_i}"
				tmp_ovm_ips_value="${tmp_ovm_ips_value}'${tmp_ip}' as ip${tmp_i}"
			fi
			let tmp_i=tmp_i+1
		done
		eval sed -i.bak 's/ovm_ips_num/${tmp_ovm_ips_num}/g' ${SYS_TMP_DIR}/list_all_ips_vars.sql
		eval sed -i.bak 's/ovm_ip_cols/${tmp_ovm_ip_cols}/g' ${SYS_TMP_DIR}/list_all_ips_vars.sql
		eval sed -i.bak 's/ovm_ips_value/${tmp_ovm_ips_value}/g' ${SYS_TMP_DIR}/list_all_ips_vars.sql
	else
		tmp_ovm_ip_cols="1, ip1"
		tmp_ovm_ips_value="'192.168.20.11' as ip1"		
		eval sed -i.bak 's/ovm_ips_num/1/g' ${SYS_TMP_DIR}/list_all_ips.sql
		eval sed -i.bak 's/ovm_ip_cols/${tmp_ovm_ip_cols}/g' ${SYS_TMP_DIR}/list_all_ips_vars.sql
		eval sed -i.bak 's/ovm_ips_value/${tmp_ovm_ips_value}/g' ${SYS_TMP_DIR}/list_all_ips_vars.sql
	fi	
	local SQLPLUS="/opt/sun/xvmoc/bin/ecadm"
	if [ ! -e ${SQLPLUS} ]
	then
		echo "${SQLPLUS} not found! Possible reason: this is not EC1 VM or Ops Center is not installed properly."
		return 1
	fi
	SQLPLUS="${SQLPLUS} sqlplus"
	echo ""
	local sql_output="${SYS_TMP_DIR}/tmp_sql_allips.out"

	eval $SQLPLUS >/dev/null 2>&1 <<EOF
	set head off
    set linesize 32000
    set wrap off
	set pages 0
	set feedback off
	set trims on
	set term off
	spool $sql_output 
	@${SYS_TMP_DIR}/list_all_ips_vars.sql
	spool off
	exit
EOF
#	if [ -e ${SYS_TMP_DIR}/list_all_ips_vars.sql.bak ]
#	then
#		mv -f ${SYS_TMP_DIR}/list_all_ips_vars.sql.bak ${SYS_TMP_DIR}/list_all_ips_vars.sql
#	fi
	if [[ -n $(cat $sql_output | grep "IPoIB-admin" | grep "ovmm_" | grep ',') ]]
       	then
        	ip_one=$(cat $sql_output | grep "IPoIB-admin" | grep "ovmm_" | cut -d"=" -f2 | awk -F "," {'print $2'})
               	ip_two=$(cat $sql_output | grep "IPoIB-admin" | grep "ovmm_" | cut -d"=" -f2 | awk -F "," {'print $1'})
		ovmm_header=$(cat $sql_output | grep "IPoIB-admin" | grep "ovmm_" | awk -F "=" {'print $1'})
               	ec_header=$(cat $sql_output | grep "IPoIB-admin" | grep "ec_01" | awk -F "=" {'print $1'})
       		eval sed -i.bak 's/$ovmm_header=$ip_two,$ip_one/$ovmm_header=$ip_one/g' $sql_output
       		eval sed -i.bak 's/$ec_header=$ip_two,$ip_one/$ec_header=$ip_two/g' $sql_output
       	fi
    f_unique_file $sql_output

        sn_fe=$(grep 'sn_nodes.*,' $sql_output)
        ret=$?
        if [ $ret -eq 0 ]
        then
            sn_ip1=$(echo "${sn_fe}" | cut -d '=' -f 2 | cut -d ',' -f 1)
            sn_ip2=$(echo "${sn_fe}" | cut -d '=' -f 2 | cut -d ',' -f 2)
            sn_fe_1=$(echo "${sn_fe}" | cut -d '=' -f 1)

            if [ ${sn_ip1} == ${sn_fe_ip} ]
            then
                sn_fe=${sn_fe_1}"="${sn_ip2}
            else
                sn_fe=${sn_fe_1}"="${sn_ip1}
            fi
            sed -i.bak "s/.*sn_nodes.*,.*/${sn_fe}/g" $sql_output
        fi

	if [ "$O_FILENAME2" == "/dev/null" ] && [ -z "${1}" ]
	then
		grep -v SQL $sql_output >&3
	else
		grep -v SQL $sql_output > ${1}
		cat ${1} > $O_FILENAME2
	fi
}

f_main_program() 
{
	if [ "${O_FORMAT}" == "shell" ] && [ "$A_FLAG" != "all" ]
	then
		D_ACTION="EMOC"
	elif [ "${O_FORMAT}" == "shell" ] && [ "$A_FLAG" == "all" ]
	then
		D_ACTION="IPS"
	fi	
	if [ ${D_ACTION} ]
	then
		f_decho D_ACTION: $D_ACTION
	fi
	if [ "$D_ACTION" == "ECU" ] || [ "$D_ACTION" == "ALL" ]
	then
		if [ IN_FILENAME ] && [ "${IN_FILENAME}" != "" ]
		then
			f_read_ecu_config2 ${IN_FILENAME}
		else
			f_get_master_node_ip
			f_read_ecu_config ${CNODES_IP[0]}
		fi
		f_output_ips ${O_FILENAME} "ECU" new on		
	fi
	if [ "$D_ACTION" == "EMOC" ] || [ "$D_ACTION" == "ALL" ]
	then
		f_read_control_db
		if [ "$D_ACTION" == "EMOC" ]
		then
			local fileflag="new"
		fi
		if [ "${O_FORMAT}" == "shell" ] && [ "$A_FLAG" != "all" ]
		then
			if [ "${O_FILENAME2}" == "/dev/null" ]
			then
				f_output_ips2
			else
				f_output_ips2 "${O_FILENAME2}"
			fi
		else
			f_output_ips  ${O_FILENAME}  "EMOC" $fileflag append on
		fi
	fi
	if [ "$D_ACTION" == "ALL" ] || [ "$D_ACTION" == "EMOC" ]
	then
		f_diff_reading ${O_FILENAME}
	fi
	if [ "$D_ACTION" == "IPS" ] || [ "$D_ACTION" == "ALL" ] || [ "$D_ACTION" == "EMOC" ]
	then
		if [ ! "${O_FORMAT}" ]
		then
			f_read_all_ips
		elif [ "${O_FORMAT}" == "shell" ] && [ "$A_FLAG" == "all" ]
		then
			f_read_control_db
			f_output_ips2 "${LOCAL_TMP_DIR}/tmp_short_list.out"
			f_read_all_ips_vars ${LOCAL_TMP_DIR}/tmp_full_list.out
			cat ${LOCAL_TMP_DIR}/tmp_short_list.out ${LOCAL_TMP_DIR}/tmp_full_list.out > ${LOCAL_TMP_DIR}/tmp_list.out
			if [ "$O_FILENAME2" == "/dev/null" ]
			then
				sort ${LOCAL_TMP_DIR}/tmp_list.out >&3
			else
				sort ${LOCAL_TMP_DIR}/tmp_list.out > $O_FILENAME2
			fi			
		fi	
	fi
	if [ ${R_ACTION} ]
	then
		echo R_ACTION: $R_ACTION
	fi
	if [ "$R_ACTION" == "test" ]
	then
		f_run_cmd_on_assets ${KEYWORD} ${EXEC_CMD} ${GENERAL_ROOT_PASSWORD}
		#f_run_cmd_on_assets c_nodes "ifconfig |grep inet |cut -d: -f2|cut -d\" \" -f1" ${GENERAL_ROOT_PASSWORD}
		#f_run_cmd_on_assets c_nodes_01 ls
	fi
}
################### main program #######################


f_parse_input_parameters $@

f_global_init

f_main_program

f_global_clean
