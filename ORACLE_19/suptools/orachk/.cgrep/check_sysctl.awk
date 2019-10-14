#########################################################################
# Notes:
#
# - The purpose of this script is to check certain kernel parameters in
#   /etc/sysctl.conf that could prevent the server from booting if set
#   incorrectly.
# - This script is only capable of checking the validity of the *syntax*
#   of these parameters, but is not capable of assessing whether the
#   values themselves are correct or optimal.
# - This script does not attempt to check all parameters in sysctl.conf.
#   It only checks parameters which have been observed to cause severe
#   impact on server stability.
#
# Revision history:
#    08-May-2014 - initial version
#    28-May-2014 - vm.nr_hugepages must be < 100% of physical memory
#    24-Jun-2014 - add corrective action guidance
#    30-Nov-2016 - fix handling of recommended OVM settings
# 
#########################################################################

BEGIN {
	BEGIN_ovm()
	BEGIN_memtotal_bytes()

	if( is_domU )
	{
		DOMU_NEED["net.core.rmem_default"]=4194304
		DOMU_NEED["net.core.wmem_default"]=4194304
		DOMU_NEED["net.core.rmem_max"]=4194304
		DOMU_NEED["net.core.wmem_max"]=4194304
	}

	errcnt = 0
}

END {
	if( !errcnt && 0 == length(DOMU_NEED) )
	{
		print "SUCCESS: all sysctl.conf formatting checks succeeded"
		exit errcnt
	}

	print "FAILURE: the following issues were detected in /etc/sysctl.conf:"
	for( keystr in DOMU_HAVE )
	{
		print "\t- " keystr " value " DOMU_HAVE[keystr] " does not match recommended value " DOMU_NEED[keystr]
		delete DOMU_NEED[keystr]
	}
	for( keystr in DOMU_NEED )
	{
		errcnt++
		print "\t- " keystr " value is missing, but should be set to " DOMU_NEED[keystr]
	}
	if( HUGEPAGES_INV )
	{
		print "\t- the vm.nr_hugepages value shown below is not formatted properly:"
		print ""
		print "\t     " HUGEPAGES_INV
		print ""
		print "\t  It should look similar to the following example, with no additional comments"
		print "\t  or other characters:"
		print ""
		print "\t     vm.nr_hugepages = 10000"
		print ""
	}
	else if( HUGEPAGES_VAL )
	{
		print "\t- the vm.nr_hugepages value " HUGEPAGES_VAL " exceeds total physical RAM"
		print "\t  It should be much less than the total size of physical RAM in the server."
		print "\t  For this server, any value of " memtotal_hugepages " or larger would comsume all available"
		print "\t  RAM, and would prevent the server from booting.  Please refer to"
		print "\t  MOS Note 401749.1 for guidance on choosing an appropriate value for this."
	}

	exit errcnt
}

function BEGIN_ovm() {
	UUIDFILE="/sys/hypervisor/uuid"
	if( 0 > getline <UUIDFILE )
	{
		return
	}
	close(UUIDFILE)
	if( $1 == "00000000-0000-0000-0000-000000000000" )
	{
		return
	}
	is_domU=1
	return
}

function BEGIN_memtotal_bytes() {
	if( NR )
	{
		exit -1
	}

	cmd = "grep MemTotal /proc/meminfo"
	if( 1 != cmd | getline )
	{
		close( cmd )
		exit -1
	}
	else if( 3 != NF || $3 != "kB" )
	{
		print "Unexpected /proc/meminfo format"
		exit -1
	}
	close( cmd )
	memtotal_bytes = $2 * 1024

	cmd = "grep Hugepagesize /proc/meminfo"
	if( 1 != cmd | getline )
	{
		hugepage_size = 2048 * 1024
	}
	else if( 3 != NF || $3 != "kB" )
	{
		print "Unexpected /proc/meminfo format"
		exit -1
	}
	else
	{
		hugepage_size = $2 * 1024;
	}
	close( cmd )

	memtotal_hugepages = (memtotal_bytes - (memtotal_bytes % hugepage_size))/ hugepage_size
}

# This function verifies that the specified value consists entirely of
# numeric digits 0-9
function check_decimal_int( v ) {
	if( v !~ /^[[:digit:]]*$/ ) { return 0 }
	return 1;
}

# Check for comments first and skip to the next line if found
/^[[:space:]]*[#;]/ {
	next
}

# Trim leading/trailing whitespace and separate the key and value parts
{
	sub( /[[:space:]]*$/, "" )
	sub( /^[[:space:]]*/, "" )
	if( !length() ) { next }
	keystr = gensub( /^[[:space:]]*([^[:space:]=]*).*/, "\\1", 1 )
	valstr = gensub( /^[^=]*=[[:space:]]*(.*)$/, "\\1", 1 )
}

keystr ~ /^vm\.nr_hugepages$/ {
	if( !check_decimal_int(valstr) )
	{
		errcnt++
		HUGEPAGES_INV = $0
		next
	}

	# Add 0 to valstr to force it to numeric type. Otherwise
	# subsequent comparisons will use string comparisons,
	# which won't yield expected results
	valnum = 0 + valstr
	if( valnum >= memtotal_hugepages )
	{
		errcnt++
		HUGEPAGES_VAL = valnum
		next
	}
}

is_domU && keystr in DOMU_NEED {
	if( valstr != DOMU_NEED[keystr] )
	{
		errcnt++;
		DOMU_HAVE[keystr] = valstr
	}
	else
	{
		delete DOMU_NEED[keystr]
	}
}
