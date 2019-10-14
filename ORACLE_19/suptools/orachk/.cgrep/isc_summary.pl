# Copyright (c) 2002, 2017, Oracle and/or its affiliates. All rights reserved.
# Name create_version.pl - generates version matrix.
#Caution This script is provided for educational purposes only and not supported by Oracle Support Services. It has been tested internally, however, and works as documented. We do not guarantee that it will work for you, so be sure to test it in your environment before relying on it.Proofread this script before using it! Due to the differences in the way text editors, e-mail packages and operating systems handle text formatting (spaces, tabs and carriage returns), this script may not be in an executable state when you first receive it. Check over the script to ensure that errors of this type are corrected.

###################################################################################
# Authors        : Rohit Juyal
# Creation Date  : 11 Dec 2014
# Purpose        : Script for generating Infrastructure Software and Configuration Summary
#
###################################################################################

use strict;
use File::Basename;
use Data::Dumper;
use Getopt::Long;
use File::Spec;

my ($COLLECTIONDIR)		= "";
my ($COMPUTE_NODES_FIL) 	= "";
my ($STORAGE_SERVERS_FIL)	= "";
my ($IBSWITCHES_FIL)		= "";
my ($COMPARE_ATTR)		= 1;
my ($SYSTEM_TYPE)		= "";
my ($PDEBUG)                    = $ENV{RAT_PDEBUG}||0;

my ($SHOW_HELP)                 = 0;
my ($SEARCH_PATTERN)		= 1;
my ($ALIGN1)			= "CENTER";
my ($ALIGN2)			= "LEFT";
my ($ALIGN3)			= "CENTER";
my ($ALIGN4)			= "LEFT";
my ($ALIGN)			= "";
my ($ISCS_HTML)			= "";
my ($LIMIT)			= 2;

my ($ISC_CONFIG_COMPUTE_FIL)		= "o_isc_config_compute";
my ($ISC_CONFIG_COMPUTE_ASM_FIL)	= "a_isc_config_compute";
my ($ISC_CONFIG_COMPUTE_DB_FIL)		= "d_isc_config_compute";
my ($ISC_CONFIG_COMPUTE_SQL_FIL)	= "c_isc_config_compute";
my ($ISC_CONFIG_CELL_FIL)		= "c_cbc_isc_config_cell";
my ($ISC_CONFIG_IB_FIL)			= "s_isc_config_ib";

sub usage {
    print
	"Usage: $0 
	   -o COLLECTIONDIR 
	   -n HOST FILE
	   -c CELL FILE
	   -s SWITCH FILE 
	   -m COMPARE_ATTR
	   -t SYSTEM_TYPE
	   -h HELP
	\n";
    exit;
}

if ( @ARGV == 0 ) {
    usage();
}

GetOptions(
    	"o=s" => \$COLLECTIONDIR,
	"n=s" => \$COMPUTE_NODES_FIL,
    	"c=s" => \$STORAGE_SERVERS_FIL,
	"s=s" => \$IBSWITCHES_FIL,
	"m=n" => \$COMPARE_ATTR,
	"t=s" => \$SYSTEM_TYPE,
	"h"   => \$SHOW_HELP,
) or usage();

if ( $SHOW_HELP == 1 ) { usage(); exit; }

my (%SYS_TYPE);
foreach my $type(split /,/, $SYSTEM_TYPE) {
  my ($sys_type, $is_sys_type) = split(/:/, $type);
  $sys_type =~ s/\s*//g;
  $is_sys_type =~ s/\s*//g;
  $SYS_TYPE{$sys_type} = $is_sys_type;
}

my (%COMPUTE_ATTR, %COMPUTE_ATTR_FIL_MAP);

if ($SYS_TYPE{'is_exalytics_machine'} == 1) {
  (%COMPUTE_ATTR) = (
  	"Exalytics Image Version"		=> "$COMPARE_ATTR",
  	"Operating System Release"		=> "$COMPARE_ATTR",
  	"Operating System Kernel Version"	=> "$COMPARE_ATTR",
  	"Infiniband Firmware Version"		=> "$COMPARE_ATTR",
  	"ILOM Version"				=> "$COMPARE_ATTR",
  	"OVM Version"				=> "$COMPARE_ATTR",
  	"OVM Details"				=> "$COMPARE_ATTR",
  	"JAVA Version"				=> "$COMPARE_ATTR",
  	"OBIEE Version"				=> "$COMPARE_ATTR",
  	"OBIEE Patches Installed"		=> "$COMPARE_ATTR",
  	"TimesTen Version"			=> "$COMPARE_ATTR",
  	);
  
  (%COMPUTE_ATTR_FIL_MAP) = (
  	"Exalytics Image Version"		=> "$ISC_CONFIG_COMPUTE_FIL",
  	"Operating System Release"		=> "$ISC_CONFIG_COMPUTE_FIL",
  	"Operating System Kernel Version"	=> "$ISC_CONFIG_COMPUTE_FIL",
  	"Infiniband Firmware Version"		=> "$ISC_CONFIG_COMPUTE_FIL",
  	"ILOM Version"				=> "$ISC_CONFIG_COMPUTE_FIL",
  	"OVM Version"				=> "$ISC_CONFIG_COMPUTE_FIL",
  	"OVM Details"				=> "$ISC_CONFIG_COMPUTE_FIL",
  	"JAVA Version"				=> "$ISC_CONFIG_COMPUTE_FIL",
  	"OBIEE Version"				=> "$ISC_CONFIG_COMPUTE_FIL",
  	"OBIEE Patches Installed"		=> "$ISC_CONFIG_COMPUTE_FIL",
  	"TimesTen Version"			=> "$ISC_CONFIG_COMPUTE_FIL",
	);
} else {
  (%COMPUTE_ATTR) = (
  	"Exadata Image Version"			=> "$COMPARE_ATTR",
  	"Operating System"			=> "$COMPARE_ATTR",
  	"Operating System Version"		=> "$COMPARE_ATTR",
  	"Package Customizations"		=> "$COMPARE_ATTR",
  	"Hardware Model"			=> "$COMPARE_ATTR",
  	"Disk Configuration"			=> "$COMPARE_ATTR",
  	"Logical Volume Configuration"		=> "$COMPARE_ATTR",
  	"Network Interface Configuration"	=> "$COMPARE_ATTR",
  	"Memory Size"				=> "$COMPARE_ATTR",
  	"CPUs Enabled"				=> "$COMPARE_ATTR",
  	"Custom RPMS"				=> "$COMPARE_ATTR",
  	"ASM Disk Group Configuration"		=> "$COMPARE_ATTR",
  	);
  
  (%COMPUTE_ATTR_FIL_MAP) = (
  	"Exadata Image Version"			=> "$ISC_CONFIG_COMPUTE_FIL",
  	"Operating System"			=> "$ISC_CONFIG_COMPUTE_FIL",
  	"Operating System Version"		=> "$ISC_CONFIG_COMPUTE_FIL",
  	"Package Customizations"		=> "$ISC_CONFIG_COMPUTE_FIL",
  	"Hardware Model"			=> "$ISC_CONFIG_COMPUTE_FIL",
  	"Disk Configuration"			=> "$ISC_CONFIG_COMPUTE_FIL",
  	"Logical Volume Configuration"          => "$ISC_CONFIG_COMPUTE_FIL",
  	"Network Interface Configuration"	=> "$ISC_CONFIG_COMPUTE_FIL",
  	"Memory Size"				=> "$ISC_CONFIG_COMPUTE_FIL",
  	"CPUs Enabled"				=> "$ISC_CONFIG_COMPUTE_FIL",
  	"Custom RPMS"				=> "$ISC_CONFIG_COMPUTE_FIL",
  	"ASM Disk Group Configuration"		=> "$ISC_CONFIG_COMPUTE_ASM_FIL",
  	);
}

my (%STORAGE_ATTR) = (
	"makeModel"		=> "$COMPARE_ATTR",
	"releaseVersion"	=> "$COMPARE_ATTR",
	"releaseTrackingBug"	=> "$COMPARE_ATTR",
	"cellVersion"		=> "$COMPARE_ATTR",
	"flashCacheMode"	=> "$COMPARE_ATTR",
	"flashCacheCompress"	=> "$COMPARE_ATTR",
	"hardDiskScrubInterval"	=> "$COMPARE_ATTR",
	"bbuLearnSchedule"	=> "$COMPARE_ATTR",
	"eighthRack"		=> "$COMPARE_ATTR",
	"Flashlog size"		=> "$COMPARE_ATTR",
	"Flashcache size"	=> "$COMPARE_ATTR",
	"IORM plan active"	=> "$COMPARE_ATTR",
	"Physical disk size"	=> "$COMPARE_ATTR",
	);

my (%STORAGE_ATTR_FIL_MAP) = (
	"makeModel"		=> "$ISC_CONFIG_CELL_FIL",
	"releaseVersion"	=> "$ISC_CONFIG_CELL_FIL",
	"releaseTrackingBug"	=> "$ISC_CONFIG_CELL_FIL",
	"cellVersion"		=> "$ISC_CONFIG_CELL_FIL",
	"flashCacheMode"	=> "$ISC_CONFIG_CELL_FIL",
	"flashCacheCompress"	=> "$ISC_CONFIG_CELL_FIL",
	"hardDiskScrubInterval"	=> "$ISC_CONFIG_CELL_FIL",
	"bbuLearnSchedule"	=> "$ISC_CONFIG_CELL_FIL",
	"eighthRack"		=> "$ISC_CONFIG_CELL_FIL",
	"Flashlog size"		=> "$ISC_CONFIG_CELL_FIL",
	"Flashcache size"	=> "$ISC_CONFIG_CELL_FIL",
	"IORM plan active"	=> "$ISC_CONFIG_CELL_FIL",
	"Physical disk size"	=> "$ISC_CONFIG_CELL_FIL",
	);

my (%IBSWITCH_ATTR) = (
	"Firmware version"	=> "$COMPARE_ATTR",
	);

my (%IBSWITCH_ATTR_FIL_MAP) = (
	"Firmware version"	=> "$ISC_CONFIG_IB_FIL",
	);


my ($CHTML,%CATTR_HTML,%CVALUE,%NC_CVALUE,$CFIL);
my ($gic, $NO_COMPUTE_ROWS) = (0,0);
while(my ($CATTR, $CCOMPARABLE) = each(%COMPUTE_ATTR)) {
	undef %CVALUE;
	undef %NC_CVALUE;
	my ($o_tcVALUE);
	if ( -e $COMPUTE_NODES_FIL ) {
		open(HOSTFIL,"<",$COMPUTE_NODES_FIL) || die $!;
		my ($LOCALATTR)	= 0;
		while(my $node = <HOSTFIL>) {
			my ($BLOCK2,$BLOCK3,$BLOCK4) = (0,0,0);
			chomp($node);
			my (@CFILES);
	 		push( @CFILES, glob(File::Spec->catfile("$COLLECTIONDIR", "*$COMPUTE_ATTR_FIL_MAP{$CATTR}*")) ) if (defined $COMPUTE_ATTR_FIL_MAP{$CATTR} && $COMPUTE_ATTR_FIL_MAP{$CATTR} ne "");

			foreach my $cfile(@CFILES) {
				my $tcVALUE;

				if ($cfile =~ m/$ISC_CONFIG_COMPUTE_ASM_FIL/) {
					$LOCALATTR=1;
				} else {
					if ($cfile !~ m/_${node}\.out/) { next; }
					if ($cfile =~ m/_report/) { next; }
				}

			  	open(CFIL,"<",$cfile) || die $!;
			  	while(my $cline = <CFIL>) {
			  		chomp($cline);
			  		if ($SEARCH_PATTERN == 1) {
			  			if ( $cline =~ m/$CATTR START/i ) {
			  	      			while( my $icline = <CFIL> ) {
			  	      				if ($icline =~ m/$CATTR FINISH/i) { $BLOCK4=1; last; } 
								chomp($icline);
			  					$tcVALUE .= $icline."<br>";	
			  	      			}
			  			}
			  		} else {
				  	      	$tcVALUE .= $cline."<br>";		  	
			  		}
					if ( $BLOCK4 == 1 ) { $BLOCK3=1; last; }
			  	}
			  	close(CFIL);

				$o_tcVALUE = $tcVALUE;

				if ( $BLOCK3 == 1 ) { $BLOCK2=1; last; }
			}
	
			if ( exists $CVALUE{$o_tcVALUE} && $CCOMPARABLE == 1 ) {
				$CVALUE{$o_tcVALUE} = $CVALUE{$o_tcVALUE} . ',' . $node;
			} else {
				if ( $CCOMPARABLE == 0 ) {
					$NC_CVALUE{$o_tcVALUE .":=>". $node} = $node;
				} else {
					$CVALUE{$o_tcVALUE} = $node;
				}
			}

			if ( $LOCALATTR == 1 ) { last; }
		}
		close(HOSTFIL);
		
		if ($CCOMPARABLE == 0 ) { %CVALUE = %NC_CVALUE; }
		my ($NO_CATTR_ROWS) = scalar(keys %CVALUE);

		if ( $NO_CATTR_ROWS == 1 ) {
			my ($e_KEY);
			while(my ($t_KEY, $t_VAL) = each(%CVALUE)) { $e_KEY = $t_KEY; }
			if (!defined "$e_KEY" || "$e_KEY" eq "" || "$e_KEY" eq "<br>") { next; }
		}

		$NO_CATTR_ROWS = 1 if (!defined $NO_CATTR_ROWS || $NO_CATTR_ROWS == 0);

		my ($ic) = 0;
				
		while(my($KEY, $VAL) = each(%CVALUE)) {
			$VAL =~ s/,,/,/g;
			$VAL =~ s/^,//g;
			$VAL =~ s/,$//g;
		
			if ($CCOMPARABLE == 0 ) {
			  	$KEY =~ s/:=>.*//g;	
			} else {
				$CVALUE{$KEY} = $VAL;		
			}

			my ($unique_compute) = 0;
			$unique_compute = () = $VAL =~ /,/g;

			if ( $ic == 0 ) {
				if ($unique_compute >= $LIMIT) {
					my $random = int( rand(1000) );
					my $tcROW;
					my ($VAL1,$VAL2);

					my (@VAL) = split(',',$VAL); 
					$VAL1 = join( ',', splice( @VAL, 0, $LIMIT ) );
					$VAL2 = join( ',', @VAL);

					$tcROW = qq|	
						<td align="$ALIGN3" scope="row">
						<a href="javascript:ShowHideRegion('$random')">| .$VAL1. qq|</a>
						<div id=$random style="DISPLAY: none">|
						. $VAL2 
						. qq|<a href="javascript:ShowHideRegion('$random');"> ..Hide</a>
						</div>
						</td>
						<td align="$ALIGN4" scope="row"><pre>$KEY</pre></td>
					|;
					$CATTR_HTML{$CATTR} = $tcROW;
				} else {
					$CATTR_HTML{$CATTR} = qq{<td align="$ALIGN3" scope="row">$VAL</td><td align="$ALIGN4" scope="row"><pre>$KEY</pre></td>};
				}
			} else {
				if ($unique_compute >= $LIMIT) {
					my $random = int( rand(1000) );
					my $tcROW;
					my ($VAL1,$VAL2);

					my (@VAL) = split(',',$VAL); 
					$VAL1 = join( ',', splice( @VAL, 0, $LIMIT ) );
					$VAL2 = join( ',', @VAL);

					$tcROW = qq|	
						<tr align="$ALIGN">
						<td align="$ALIGN3" scope="row">
						<a href="javascript:ShowHideRegion('$random')">| .$VAL1. qq|</a>
						<div id=$random style="DISPLAY: none">|
						. $VAL2 
						. qq|<a href="javascript:ShowHideRegion('$random');"> ..Hide</a>
						</div>
						</td>
						<td align="$ALIGN4" scope="row"><pre>$KEY</pre></td>
					|;
					$CATTR_HTML{$CATTR} = $CATTR_HTML{$CATTR} . $tcROW;
				} else {
					$CATTR_HTML{$CATTR} = $CATTR_HTML{$CATTR} . qq{<tr align="$ALIGN"><td align="$ALIGN3" scope="row">$VAL</td><td align="$ALIGN4" scope="row"><pre>$KEY</pre></td>};
				}
			}
			$ic = $ic + 1;
		}

		if ( $gic == 0 ) {
   			$CATTR_HTML{$CATTR} = qq{<td align="$ALIGN2" rowspan=$NO_CATTR_ROWS scope="row">&nbsp;&nbsp;$CATTR</td>} . $CATTR_HTML{$CATTR};
			if ($SYS_TYPE{'is_exalytics_machine'} == 1) {
				$CHTML = qq{<td align="$ALIGN1" rowspan=NO_COMPUTE_ROWS scope="row">Exalytics Compute Node</td>} . $CATTR_HTML{$CATTR};
			} else {
				$CHTML = qq{<td align="$ALIGN1" rowspan=NO_COMPUTE_ROWS scope="row">Exadata Database Server</td>} . $CATTR_HTML{$CATTR};
			}
		} else {
   			$CATTR_HTML{$CATTR} = qq{<tr align="$ALIGN2"><td rowspan=$NO_CATTR_ROWS>&nbsp;&nbsp;$CATTR</td>} . $CATTR_HTML{$CATTR} . qq{</tr>};
			$CHTML = $CHTML . $CATTR_HTML{$CATTR};
		}

		$gic = $gic + 1;
		
		$NO_COMPUTE_ROWS = $NO_COMPUTE_ROWS + $NO_CATTR_ROWS;	
	}
}
$CHTML =~ s/NO_COMPUTE_ROWS/$NO_COMPUTE_ROWS/g;


my ($SHTML,%SATTR_HTML,%SVALUE,%NC_SVALUE,$SFIL);
my ($gis,$NO_CELL_ROWS) = (0,0);
while(my ($SATTR, $SCOMPARABLE) = each(%STORAGE_ATTR)) {
	undef %SVALUE;
	undef %NC_SVALUE;
	my ($o_tsVALUE);
	if ( -e $STORAGE_SERVERS_FIL ) {
		open(CELLFIL,"<",$STORAGE_SERVERS_FIL) || die $!;
		while(my $cell = <CELLFIL>) {
			my ($BLOCK2,$BLOCK3,$BLOCK4) = (0,0,0);
			chomp($cell);
			$cell =~ s/ =.*$//g;
			
			my (@SFILES);
			push( @SFILES, glob(File::Spec->catfile("$COLLECTIONDIR", ".CELLDIR", ".*", "*$STORAGE_ATTR_FIL_MAP{$SATTR}*")) ) if (defined $STORAGE_ATTR_FIL_MAP{$SATTR} && $STORAGE_ATTR_FIL_MAP{$SATTR} ne "");

			foreach my $sfile(@SFILES) {
				my $tsVALUE;
				if ($sfile !~ m/_${cell}\.out/) { next; }

			  	open(SFIL,"<",$sfile) || die $!;
			  	while(my $sline = <SFIL>) {
			  		chomp($sline);
			  		if ($SEARCH_PATTERN == 1) {
			  			if ( $sline =~ m/$SATTR START/i ) {
			  	      			while( my $isline = <SFIL> ) {
			  	      				if ($isline =~ m/$SATTR FINISH/i) { $BLOCK4=1; last; } 
								chomp($isline);
			  					$tsVALUE .= $isline."<br>";	
			  	      			}
			  			}
			  		} else {
				  	      	$tsVALUE .= $sline."<br>";		  	
			  		}
					if ( $BLOCK4 == 1 ) { $BLOCK3=1; last; }
			  	}
			  	close(SFIL);

				$o_tsVALUE = $tsVALUE;

				if ( $BLOCK3 == 1 ) { $BLOCK2=1; last; }
			}

			if ( exists $SVALUE{$o_tsVALUE} && $SCOMPARABLE == 1 ) {
				$SVALUE{$o_tsVALUE} = $SVALUE{$o_tsVALUE} . ',' . $cell;
			} else {
                                if ( $SCOMPARABLE == 0 ) {
                                        $NC_SVALUE{$o_tsVALUE .":=>". $cell} = $cell;
                                } else {
                                        $SVALUE{$o_tsVALUE} = $cell;
                                }
			}
		}
		close(CELLFIL);
		
		if ($SCOMPARABLE == 0 ) { %SVALUE = %NC_SVALUE; }

		my ($NO_SATTR_ROWS) = scalar(keys %SVALUE);

		if ( $NO_SATTR_ROWS == 1 ) {
			my ($e_KEY);
			while(my ($t_KEY, $t_VAL) = each(%SVALUE)) { $e_KEY = $t_KEY; }
			if (!defined "$e_KEY" || "$e_KEY" eq "" || "$e_KEY" eq "<br>") { next; }
		}

		$NO_SATTR_ROWS = 1 if (!defined $NO_SATTR_ROWS || $NO_SATTR_ROWS == 0);

		my ($is) = 0;
		while(my($KEY, $VAL) = each(%SVALUE)) {
			$VAL =~ s/,,/,/g;
			$VAL =~ s/^,//g;
			$VAL =~ s/,$//g;

                        if ($SCOMPARABLE == 0 ) {
                                $KEY =~ s/:=>.*//g;
                        } else {
                                $SVALUE{$KEY} = $VAL;
                        }
		
			my ($unique_cell) = 0;
			$unique_cell = () = $VAL =~ /,/g;

			if ( $is == 0 ) {
				if ($unique_cell >= $LIMIT) {
					my $random = int( rand(1000) );
					my $tsROW;
					my ($VAL1,$VAL2);

					my (@VAL) = split(',',$VAL); 
					$VAL1 = join( ',', splice( @VAL, 0, $LIMIT ) );
					$VAL2 = join( ',', @VAL);

					$tsROW = qq|	
						<td align="$ALIGN3" scope="row">
						<a href="javascript:ShowHideRegion('$random')">| .$VAL1. qq|</a>
						<div id=$random style="DISPLAY: none">|
						. $VAL2 
						. qq|<a href="javascript:ShowHideRegion('$random');"> ..Hide</a>
						</div>
						</td>
						<td align="$ALIGN4" scope="row"><pre>$KEY</pre></td>
					|;
					$SATTR_HTML{$SATTR} = $tsROW;
				} else {
					$SATTR_HTML{$SATTR} = qq{<td align="$ALIGN3" scope="row">$VAL</td><td align="$ALIGN4" scope="row"><pre>$KEY</pre></td>};
				}
			} else {
				if ($unique_cell >= $LIMIT) {
					my $random = int( rand(1000) );
					my $tsROW;
					my ($VAL1,$VAL2);

					my (@VAL) = split(',',$VAL); 
					$VAL1 = join( ',', splice( @VAL, 0, $LIMIT ) );
					$VAL2 = join( ',', @VAL);

					$tsROW = qq|	
						<tr align="$ALIGN">
						<td align="$ALIGN3" scope="row">
						<a href="javascript:ShowHideRegion('$random')">| .$VAL1. qq|</a>
						<div id=$random style="DISPLAY: none">|
						. $VAL2 
						. qq|<a href="javascript:ShowHideRegion('$random');"> ..Hide</a>
						</div>
						</td>
						<td align="$ALIGN4" scope="row"><pre>$KEY</pre></td>
					|;
					$SATTR_HTML{$SATTR} = $SATTR_HTML{$SATTR} . $tsROW;
				} else {
					$SATTR_HTML{$SATTR} = $SATTR_HTML{$SATTR} . qq{<tr align="$ALIGN"><td align="$ALIGN3" scope="row">$VAL</td><td align="$ALIGN4" scope="row"><pre>$KEY</pre></td>};
				}
			}
			$is = $is + 1;
		}

		if ( $gis == 0 ) {
   			$SATTR_HTML{$SATTR} = qq{<td align="$ALIGN2" rowspan=$NO_SATTR_ROWS scope="row">&nbsp;&nbsp;$SATTR</td>} . $SATTR_HTML{$SATTR};
			$SHTML = qq{<td align="$ALIGN1" rowspan=NO_CELL_ROWS scope="row">Exadata Storage Server</td>} . $SATTR_HTML{$SATTR};
		} else {
   			$SATTR_HTML{$SATTR} = qq{<tr align="$ALIGN2"><td rowspan=$NO_SATTR_ROWS>&nbsp;&nbsp;$SATTR</td>} . $SATTR_HTML{$SATTR} . qq{</tr>};
			$SHTML = $SHTML . $SATTR_HTML{$SATTR};
		}

		$gis = $gis + 1;
		
		$NO_CELL_ROWS = $NO_CELL_ROWS + $NO_SATTR_ROWS;	
	}
}
$SHTML =~ s/NO_CELL_ROWS/$NO_CELL_ROWS/g;


my ($IHTML,%IATTR_HTML,%IVALUE,%NC_IVALUE,$IFIL);
my ($gii,$NO_IB_ROWS) = (0,0);
while(my ($IATTR, $ICOMPARABLE) = each(%IBSWITCH_ATTR)) {
	undef %IVALUE;
	undef %NC_IVALUE;
	my ($o_tiVALUE);
	if ( -e $IBSWITCHES_FIL ) {
		open(SWITCHFIL,"<",$IBSWITCHES_FIL) || die $!;
		while(my $ibswitch = <SWITCHFIL>) {
			my ($BLOCK2,$BLOCK3,$BLOCK4) = (0,0,0);
			chomp($ibswitch);
			my (@IFILES);

	 		push( @IFILES, glob(File::Spec->catfile("$COLLECTIONDIR","$IBSWITCH_ATTR_FIL_MAP{$IATTR}*")) ) if (defined $IBSWITCH_ATTR_FIL_MAP{$IATTR} && $IBSWITCH_ATTR_FIL_MAP{$IATTR} ne "");

			foreach my $ifile(@IFILES) {
				my $tiVALUE;
				if ($ifile !~ m/_${ibswitch}\.out/i) { next; }

			  	open(IFIL,"<",$ifile) || die $!;
			  	while(my $iline = <IFIL>) {
			  		chomp($iline);
			  		if ($SEARCH_PATTERN == 1) {
			  			if ( $iline =~ m/$IATTR START/i ) {
			  	      			while( my $iiline = <IFIL> ) {
			  	      				if ($iiline =~ m/$IATTR FINISH/i) { $BLOCK4=1; last; } 
								chomp($iiline);
			  					$tiVALUE .= $iiline."<br>";	
			  	      			}
			  			}
			  		} else {
				  	      	$tiVALUE .= $iline."<br>";		  	
			  		}
					if ( $BLOCK4 == 1 ) { $BLOCK3=1; last; }
			  	}
			  	close(IFIL);

				$o_tiVALUE = $tiVALUE;

				if ( $BLOCK3 == 1 ) { $BLOCK2=1; last; }
			}

			if ( exists $IVALUE{$o_tiVALUE} && $ICOMPARABLE == 1 ) {
				$IVALUE{$o_tiVALUE} = $IVALUE{$o_tiVALUE} . ',' . $ibswitch;
			} else {
                                if ( $ICOMPARABLE == 0 ) {
                                        $NC_IVALUE{$o_tiVALUE .":=>". $ibswitch} = $ibswitch;
                                } else {
                                        $IVALUE{$o_tiVALUE} = $ibswitch;
                                }			
			}
		}
		close(SWITCHFIL);
		
		if ($ICOMPARABLE == 0 ) { %IVALUE = %NC_IVALUE; }
		my ($NO_IATTR_ROWS) = scalar(keys %IVALUE);

		if ( $NO_IATTR_ROWS == 1 ) {
			my ($e_KEY);
			while(my ($t_KEY, $t_VAL) = each(%IVALUE)) { $e_KEY = $t_KEY; }
			if (!defined "$e_KEY" || "$e_KEY" eq "" || "$e_KEY" eq "<br>") { next; }
		}

		$NO_IATTR_ROWS = 1 if (!defined $NO_IATTR_ROWS || $NO_IATTR_ROWS == 0);

		my ($ii) = 0;
		while(my($KEY, $VAL) = each(%IVALUE)) {
			$VAL =~ s/,,/,/g;
			$VAL =~ s/^,//g;
			$VAL =~ s/,$//g;

                        if ($ICOMPARABLE == 0 ) {
                                $KEY =~ s/:=>.*//g;
                        } else {
                                $IVALUE{$KEY} = $VAL;
                        }

			my ($unique_ib) = 0;
			$unique_ib = () = $VAL =~ /,/g;

			if ( $ii == 0 ) {
				if ($unique_ib >= $LIMIT) {
					my $random = int( rand(1000) );
					my $tiROW;
					my ($VAL1,$VAL2);

					my (@VAL) = split(',',$VAL); 
					$VAL1 = join( ',', splice( @VAL, 0, $LIMIT ) );
					$VAL2 = join( ',', @VAL);

					$tiROW = qq|	
						<td align="$ALIGN3" scope="row">
						<a href="javascript:ShowHideRegion('$random')">| .$VAL1. qq|</a>
						<div id=$random style="DISPLAY: none">|
						. $VAL2 
						. qq|<a href="javascript:ShowHideRegion('$random');"> ..Hide</a>
						</div>
						</td>
						<td align="$ALIGN4" scope="row"><pre>$KEY</pre></td>
					|;
					$IATTR_HTML{$IATTR} = $tiROW;
				} else {
					$IATTR_HTML{$IATTR} = qq{<td align="$ALIGN3" scope="row">$VAL</td><td align="$ALIGN4" scope="row"><pre>$KEY</pre></td>};
				}
			} else {
				if ($unique_ib >= $LIMIT) {
					my $random = int( rand(1000) );
					my $tiROW;
					my ($VAL1,$VAL2);

					my (@VAL) = split(',',$VAL); 
					$VAL1 = join( ',', splice( @VAL, 0, $LIMIT ) );
					$VAL2 = join( ',', @VAL);

					$tiROW = qq|	
						<tr align="$ALIGN">
						<td align="$ALIGN3" scope="row">
						<a href="javascript:ShowHideRegion('$random')">| .$VAL1. qq|</a>
						<div id=$random style="DISPLAY: none">|
						. $VAL2 
						. qq|<a href="javascript:ShowHideRegion('$random');"> ..Hide</a>
						</div>
						</td>
						<td align="$ALIGN4" scope="row"><pre>$KEY</pre></td>
					|;
					$IATTR_HTML{$IATTR} = $IATTR_HTML{$IATTR} . $tiROW;
				} else {
					$IATTR_HTML{$IATTR} = $IATTR_HTML{$IATTR} . qq{<tr align="$ALIGN"><td align="$ALIGN3" scope="row">$VAL</td><td align="$ALIGN4" scope="row"><pre>$KEY</pre></td>};
				}
			}
			$ii = $ii + 1;
		}

		if ( $gii == 0 ) {
   			$IATTR_HTML{$IATTR} = qq{<td align="$ALIGN2" rowspan=$NO_IATTR_ROWS scope="row">&nbsp;&nbsp;$IATTR</td>} . $IATTR_HTML{$IATTR};
			$IHTML = qq{<td align="$ALIGN1" rowspan=NO_IB_ROWS scope="row">Exadata InfiniBand Switch</td>} . $IATTR_HTML{$IATTR};
		} else {
   			$IATTR_HTML{$IATTR} = qq{<tr align="$ALIGN2"><td rowspan=$NO_IATTR_ROWS>&nbsp;&nbsp;$IATTR</td>} . $IATTR_HTML{$IATTR} . qq{</tr>};
			$IHTML = $IHTML . $IATTR_HTML{$IATTR};
		}

		$gii = $gii + 1;
		
		$NO_IB_ROWS = $NO_IB_ROWS + $NO_IATTR_ROWS;	
	}
}
$IHTML =~ s/NO_IB_ROWS/$NO_IB_ROWS/g;

my $HEADER =
qq|<table id='t_iscs' border=1 summary="Infrastructure Software and Configuration">
		<tr align=$ALIGN1>
			<th scope="col">Component</th>
			<th scope="col">Attribute</th>
			<th scope="col">Host</th>
			<th scope="col">Value</th>
		</tr>|;

my $FOOTER = qq|</table>|;

if ((defined $CHTML && $CHTML ne "") || (defined $SHTML && $SHTML ne "") || (defined $IHTML && $IHTML ne "")) {
	$ISCS_HTML = qq|
			$HEADER
			<tr>
				$CHTML
				$SHTML
				$IHTML
			</tr>
			$FOOTER
		|;
	
	open( ISCSFIL, '>', File::Spec->catfile("$COLLECTIONDIR", "isc_summary.html") );
	print ISCSFIL $ISCS_HTML;
	close(ISCSFIL);
}

