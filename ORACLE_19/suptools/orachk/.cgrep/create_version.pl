
# Copyright (c) 2002, 2018, Oracle and/or its affiliates. All rights reserved.
# Name create_version.pl - generates version matrix.
#Caution This script is provided for educational purposes only and not supported by Oracle Support Services. It has been tested internally, however, and works as documented. We do not guarantee that it will work for you, so be sure to test it in your environment before relying on it.Proofread this script before using it! Due to the differences in the way text editors, e-mail packages and operating systems handle text formatting (spaces, tabs and carriage returns), this script may not be in an executable state when you first receive it. Check over the script to ensure that errors of this type are corrected.

##############################################################################
# Authors        : Rohit Juyal
# Creation Date  :
# Purpose        : Script for generating version matrix
#
##############################################################################

use strict;
use File::Basename;
use File::Spec;
use Data::Dumper;

my $dir      = $ARGV[0];
my $inputdir = $ARGV[1];
my $envfile  = $ARGV[2];
my $is_avm_machine  = $ARGV[3];
my ($PDEBUG) = $ENV{RAT_PDEBUG}||0;

my $PASS_MESSAGE = 'Version within recommended range.';
my $PASS_COLOR   = '#006600';
my $EXC_MESSAGE  = 'Exception: Version is different from peers.';
my $EXC_COLOR    = '#C70303';
my $ALIGN        = 'CENTER';
my $NULL_VER_MSG = 'Bundle patch version not available through opatch';
my $BASE_MSG	 = 'No patch set update applied';
my $COLSPAN      = 1;
my $APPEND_MSG   = '';

open( EFILE, ">", File::Spec->catfile("$dir", 'versions.html') );
close(EFILE);

#--------------------------CHECKS------------------------------
my $v_file    = glob(File::Spec->catfile("$inputdir", "versions.dat"));
my $delimiter = ';';
my $h_checks;

open( CHKINP, '<', $v_file );
while ( my $line = <CHKINP> ) {
    #Skip headers and blank lines
    next if ( $line =~ m/Generated on/ ); 
    next if ( $line =~ m/TARGET;CHECKID;CHECK;THRESHOLD;RULE EVALUATION;DEP FEATURE;RECOMMENDED VERSION;MESSAGE/ ); 
    next if ( $line =~ m/^\s*$/ ); 

    my ( $idtype, $id, $check, $threshold, $rule_eva, $dep_feature, $rec_version, $msg ) = split( $delimiter, $line );
    next if ($id !~ /RA/ && $is_avm_machine == 1);
    next if ($id =~ /RA/ && $is_avm_machine == 0);

    ( $h_checks->{$id}->{'TARGET'}          = lc($idtype) ) =~ s/^\s*|\s*$//g;
    ( $h_checks->{$id}->{'CHECK'}           = $check ) =~ s/^\s*|\s*$//g;
    ( $h_checks->{$id}->{'THRESHOLD'}       = $threshold ) =~ s/^\s*|\s*$//g;
    ( $h_checks->{$id}->{'RULE_EVALUATION'} = $rule_eva ) =~ s/^\s*|\s*$//g;
    ( $h_checks->{$id}->{'DEP_FEATURE'}     = $dep_feature ) =~ s/^\s*|\s*$//g;
    ( $h_checks->{$id}->{'REC_VERSION'}     = $rec_version ) =~ s/^\s*|\s*$//g;
    ( $h_checks->{$id}->{'MSG'}             = $msg ) =~ s/^\s*|\s*$//g;
}
close(CHKINP);
exit if ( !$v_file );

#---------------------------FUNCTIONS-------------------------
sub compare_versions {
    my $v1 = shift;
    my $v2 = shift;
	
    if ( "$v1" eq "N/A" ) {	
	$v1 = 0;
    }
    else {
	$v1 =~ s/\.(\d{1}$)/\.0$1/g;
	$v1 =~ s/\.|-//g;
    }
	
    if ( "$v2" eq "N/A" ) {	
	$v2 = 0;
    }
    else {
	$v2 =~ s/\.(\d{1}$)/\.0$1/g;
	$v2 =~ s/\.|-//g;
    }
	
    if ( $v1 >= $v2 ) {
	return 1;
    }
    else {
	return 0;
    }
}


sub create_expression {
    my $id      = shift;
    my $version = shift;

    $version = 0 if ( "$version" eq 'N/A' );
    $version =~ s/<br>$BASE_MSG<\/br>//g;
    

    my @check     = split( ',', $h_checks->{$id}->{'CHECK'} );
    my @threshold = split( ',', $h_checks->{$id}->{'THRESHOLD'} );
    my $exp;
    for ( my $i = 0 ; $i < scalar(@check) ; $i++ ) {
        $threshold[$i] =~ s/\.(\d{1}$)/\.0$1/g;
        $exp .= 'FV ' . $check[$i] . ' ' . $threshold[$i] . ' && ';
    }
    $exp =~ s/&& $//g;
    $version =~ s/\.(\d{1}$)/\.0$1/g;
    $exp =~ s/FV/$version/g;
    $exp =~ s/\.|-//g;

    return $exp;
}

#--------------------------------------------------------------

my ( $DB_HASH, $SS_HASH, $IBS_HASH );
my (@v_patterns);
my ( $VERSION,  @IDS );
my ( $color,    $msg );
my ( $start_tr, $end_tr );
my ($rowspan);
my ( $WBFC, $SFL, $SS_FOUND ) = ( 0, 0, 0 );

#---------------
my @dbfiles;
my @f_patterns = ('o_exadata_versions_');
my $SAPEXA_VER = 0;
my ( $CLUSTER, $EXADATA, $RDBMS ) = ( 0, 0, 0 );
foreach (@f_patterns) {
    push( @dbfiles, glob(File::Spec->catfile("$dir", "$_*.out")) );
    push( @dbfiles, glob(File::Spec->catfile("$dir", "outfiles/$_*.out")) );
}
@dbfiles = grep( !/report/, @dbfiles );
@v_patterns =
  ( 'Exadata Server software version', 'Clusterware home', 'RDBMS home' );
foreach (@dbfiles) {
    open( OUTFILE, '<', $_ );

    my $name = $_;
    $name = $2 if ( $name =~ m/^.*_((.*)\.)out$/ );

    while ( my $line = <OUTFILE> ) {
        next if ( chomp($line) =~ m/^\s*$/ );
        $line =~ s|<.+?>||g;
        $line =~ s/^\s*|\s*$//g;

        foreach my $pattern (@v_patterns) {
            $VERSION = 'N/A';
            if ( $line =~ m/\Q$pattern/i ) {
                if ( $pattern eq 'Exadata Server software version' ) {
                    ( $line = <OUTFILE> ) =~ s/^\s*|\s*$//g;
                    $VERSION = $1 if ( $line =~ m/((\d{1,3}(\.|\-))+\d+)/ );
                    ( $VERSION = $1 ) =~ s/\.$//g
                      if ( $VERSION =~ m/((\d{1,3}\.){5})/ );
                    $DB_HASH->{'EXADATA'}->{$name}->{'EVERSION'} = $VERSION;
                    $EXADATA = 1;
                }
                elsif ( $pattern eq 'Clusterware home' ) {
                    my $crhome = $1 if ( $line =~ m/\((.*)\)/ );

		    my ($tmp_version) = 'N/A';
		    my ($PATTERN1) = 'DATABASE';
		    my ($patchfile) = $_;

		    #$tmp_version = `cat "$patchfile"|grep -wi "$PATTERN1"|head -1`;
		    open(PFILE,'<',$patchfile);
		    while(<PFILE>) {
		      chomp($_);
		      if ($_ =~ m/\b$PATTERN1\b/i) { $tmp_version = $_; last; }
		    }
		    close(PFILE);

		    chomp($tmp_version);
		    $tmp_version = $1 if ( defined $tmp_version && $tmp_version =~ m/((\d{1,3}(\.|\-))+\d+)/ );


		    if ( $tmp_version !~ m/^\d+\.\d+\.\d+\.\d+/ ) {
                        open( ENVFILE, '<', $envfile );
                        while ( my $envline = <ENVFILE> ) {
                            if ( $envline =~ m/CRS_ACTIVE_VERSION =/ ) {
                                $tmp_version = $envline;
                                $tmp_version =~
                                  s/.*CRS_ACTIVE_VERSION = //g;
                                $tmp_version =~ s/^\s*|\s*$//g;
                            }
                        }
                        close(ENVFILE);

		        $tmp_version = $tmp_version . "<br>$BASE_MSG</br>";
		    }

		    if ( $tmp_version =~ m/^\d+\.\d+\.\d+\.\d+/ ) {
		        $VERSION = $tmp_version; 
		        chomp($VERSION);
		    }
 
                    $DB_HASH->{'EXADATA'}->{$name}->{'CLUSTER'}->{$crhome} = $VERSION;
                    $CLUSTER = 1;
                }
                elsif ( $pattern eq 'RDBMS home' ) {
		    my ($PRNT_SAPEXA_VER,$CMP_SAPEXA_VER) = ('N/A','N/A');
                    my $rdhome = $1 if ( $line =~ m/\((.*)\)/ );

                    while ( $line = <OUTFILE> ) {
                        if ( $line =~ m/DATABASE PATCH/i || $line =~ m/Database Recommended Patch/i || $line =~ m/DATABASE/i ) {
                            last;
                        }
			elsif ( $line =~ m/SAPEXADBBP/i ) {
			    $SAPEXA_VER=1;
			    if ( $line =~ m/Patch description:  \"SAPEXADBBP ((\d+\.)+\d+) BASED ON EXA BP : ((\d+\.)+\d+)/ ) {
			    	$PRNT_SAPEXA_VER="SAPEXADBBP $1";
			    	$CMP_SAPEXA_VER="$3";	
			    }
			}
                        else {
                            $line = 0;
                        }
                    }

		    if ($SAPEXA_VER == 1) {
			$VERSION = $CMP_SAPEXA_VER;
		    }
		    else {
                    	$VERSION = $1 if ( defined $line && $line =~ m/((\d{1,3}(\.|\-))+\d+)/ );
		    }
	
                    if ( $VERSION eq 'N/A' ) {
                        my ($tmp_version) = 'N/A';
                        open( ENVFILE, '<', $envfile );
                        while ( my $envline = <ENVFILE> ) {
                            if ( $envline =~ m/RDBMS_ORACLE_HOME = $rdhome/ )
                            {
                                $tmp_version = $envline;
                                $tmp_version =~
                                  s/RDBMS_ORACLE_HOME =.*?\|//g;
                                $tmp_version =~ s/\|.*$//g;
                                $tmp_version =~ s/^\s*|\s*$//g;
                                $tmp_version =~ s/(^\d{2})(\d{1})(\d{1})(\d{1})/$1\.$2\.$3\.$4\./g;
                            }
                        }
                        close(ENVFILE);

			$tmp_version = $tmp_version . "<br>$BASE_MSG</br>";

                        $VERSION = $tmp_version;
                    }

		    if  ($SAPEXA_VER == 1) { $DB_HASH->{'EXADATA'}->{$name}->{'RDBMS_PRINT_MAP'}->{$rdhome} = $PRNT_SAPEXA_VER; }

		    $DB_HASH->{'EXADATA'}->{$name}->{'RDBMS'}->{$rdhome} = $VERSION;
                    $RDBMS = 1;
                }
            }
        }
        if ( !defined $DB_HASH->{'EXADATA'}->{$name}->{'EVERSION'} ) {
            $DB_HASH->{'EXADATA'}->{$name}->{'EVERSION'} = 'N/A';
        }
    }
    close(OUTFILE);
}

my %DB_NAMES;
my $trowspan = 0;
my $irowspan = 0;

my ( $db_html, $exadata_html, $grid_html, $rdbms_html );
$db_html =
  qq|<tr align=$ALIGN><td scope="row" rowspan=DBCOUNT>DATABASE SERVER</td>|;

if ( $RDBMS != 0 ) {
    my %RD_NAMES;
    foreach my $server ( sort { $a cmp $b } keys %{ $DB_HASH->{'EXADATA'} } ) {
        foreach
          my $rdhomes ( keys %{ $DB_HASH->{'EXADATA'}->{$server}->{'RDBMS'} } )
        {
            if (
                !exists $RD_NAMES{
                        $rdhomes . ':'
                      . $DB_HASH->{'EXADATA'}->{$server}->{'RDBMS'}->{$rdhomes}
                }
              )
            {
                $RD_NAMES{ $rdhomes . ':'
                      . $DB_HASH->{'EXADATA'}->{$server}->{'RDBMS'}->{$rdhomes}
                } = $server;
            }
            else {
                $RD_NAMES{ $rdhomes . ':'
                      . $DB_HASH->{'EXADATA'}->{$server}->{'RDBMS'}->{$rdhomes}
                } .= ',' . $server;
            }
        }
    }
    $rdbms_html .= qq|<td scope="row" rowspan=DBHCOUNT>Database Home</td>|;
    ( $start_tr, $end_tr ) = ( '', '</tr>' );
    my $rdrow;

    foreach ( keys %RD_NAMES ) {
        my $random = int( rand(1000) );
        my ( $rdhome, $version ) = split( ':', $_ );
 
        my $print_version = $version;
	if  ($SAPEXA_VER == 1) {		
	    my ($t_KEY) = $_;
    	    my ($t_HOME,$t_VERSION) = split(':',$t_KEY);
	    my (@t_HOSTS) = split(',',$RD_NAMES{$_});
	
	    foreach my $host(@t_HOSTS) {  
	        if ( exists $DB_HASH->{'EXADATA'}->{$host}->{'RDBMS_PRINT_MAP'}->{$t_HOME} && $DB_HASH->{'EXADATA'}->{$host}->{'RDBMS'}->{$t_HOME} eq "$t_VERSION") {
	  	    $print_version = $DB_HASH->{'EXADATA'}->{$host}->{'RDBMS_PRINT_MAP'}->{$t_HOME};
		    last;
	        }
	    }
        }

        $version =~ s/<br>$BASE_MSG<\/br>//g;

        my $FAIL = 0;
        my $dbrow;
        my ( $istart_tr, $iend_tr ) = ( '', '</tr>' );

        #----------------------
        my ( $mstr, $tversion );
        $tversion = $version;
        $tversion =~ s/\.(\d{1}$)/\.0$1/g;
        $tversion =~ s/\.|-//g;

	$APPEND_MSG = '';

	if ( $tversion =~ m/^11202/ ) {
            $mstr = 'dbhome11202';
	}
	elsif ( $tversion =~ m/^11203/ ) {
            $mstr = 'dbhome11203';
	    if ($tversion >= 1120321 && $tversion <= 1120324) {
		$APPEND_MSG="<br><font color=$PASS_COLOR>$PASS_MESSAGE</font></br>";
	    }
	}
        elsif ( $tversion =~ m/^11204/ ) {
            $mstr = 'dbhome11204';
        }
        elsif ( $tversion =~ m/^12101/ ) {
            $mstr = 'dbhome12101';
        }
        elsif ( $tversion =~ m/^12102/ ) {
            $mstr = 'dbhome12102';
        }
        elsif ( $tversion =~ m/^12201/ ) {
            $mstr = 'dbhome12201';
        }
        elsif ( $tversion =~ m/^18/ ) {
            $mstr = 'dbhome18';
        }        
        else {
            $mstr = 'dbhome';
        }
        @IDS = ();
        for ( keys %{$h_checks} ) {
            if ( $h_checks->{$_}->{'TARGET'} eq "$mstr" ) {
                my @threshold = split( ',', $h_checks->{$_}->{'THRESHOLD'} );
                my $insert    = 0;
                my $iversion  = substr( $tversion, 0, 5 );
                if ($iversion =~ m/^18/) {
                	$iversion = substr( $tversion, 0, 2);
                }
                foreach my $threshold (@threshold) {
                    $threshold =~ s/\.(\d{1}$)/\.0$1/g;
                    $threshold =~ s/\.|-//g;
                    if ($iversion =~ m/^18/) {
                    	$threshold =  substr( $threshold, 0, 2 );
                    }
                    if ( $threshold =~ m/$iversion/ ) {
                        $insert = 1;
                        last;
                    }
                }
                if ( $insert == 1 ) {
                    push( @IDS, $_ );
                }
            }
        }

        my ( $max, $tmp ) = ( 'N/A', 0 );
        foreach my $id (@IDS) {
            if ( $tversion !~ m/^11204/ && $tversion !~ m/^12101/ && $tversion !~ m/^12201/) {
                if (   $SFL == 0
                    && $h_checks->{$id}->{'DEP_FEATURE'} eq "SMART FLASH LOG" )
                {
                    if ( $tversion !~ m/^11203/ ) {
                        next;
                    }
                }
                elsif ($SFL == 0
                    && $h_checks->{$id}->{'DEP_FEATURE'} ne "SMART FLASH LOG" )
                {
                    if (   $WBFC == 1
                        && $h_checks->{$id}->{'DEP_FEATURE'} ne "WBFC" )
                    {
                        next;
                    }
                    elsif ($WBFC == 0
                        && $h_checks->{$id}->{'DEP_FEATURE'} eq "WBFC" )
                    {
                        next;
                    }
                }
                elsif ($SFL == 1
                    && $h_checks->{$id}->{'DEP_FEATURE'} ne "SMART FLASH LOG" )
                {
                    if (   $WBFC == 1
                        && $h_checks->{$id}->{'DEP_FEATURE'} ne "WBFC" )
                    {
                        next;
                    }
                    elsif ( $WBFC == 0 ) {
                        if ( $tversion !~ m/^11203/ ) {
                            next;
                        }
                    }
                }
            }
            my $abs = $h_checks->{$id}->{'REC_VERSION'};
            $abs =~ s/\.(\d{1}$)/\.0$1/g;
            $abs =~ s/\.|-//g;
            $tmp =~ s/\.(\d{1}$)/\.0$1/g;
            $tmp =~ s/\.|-//g;
            if ( $tmp < $abs ) {
                $tmp = $h_checks->{$id}->{'REC_VERSION'};
                $max = $h_checks->{$id}->{'REC_VERSION'};
            }
        }

        #----------------------
	$COLSPAN=1;
        foreach my $id (@IDS) {
            $msg = '';
            if ( $tversion !~ m/^11204/ && $tversion !~ m/^12101/ && $tversion !~ m/^12201/ ) {
                if (   $SFL == 0
                    && $h_checks->{$id}->{'DEP_FEATURE'} eq "SMART FLASH LOG" )
                {
                    if ( $tversion !~ m/^11203/ ) {
                        next;
                    }
                }
                elsif ($SFL == 0
                    && $h_checks->{$id}->{'DEP_FEATURE'} ne "SMART FLASH LOG" )
                {
                    if (   $WBFC == 1
                        && $h_checks->{$id}->{'DEP_FEATURE'} ne "WBFC" )
                    {
                        next;
                    }
                    elsif ($WBFC == 0
                        && $h_checks->{$id}->{'DEP_FEATURE'} eq "WBFC" )
                    {
                        next;
                    }
                }
                elsif ($SFL == 1
                    && $h_checks->{$id}->{'DEP_FEATURE'} ne "SMART FLASH LOG" )
                {
                    if (   $WBFC == 1
                        && $h_checks->{$id}->{'DEP_FEATURE'} ne "WBFC" )
                    {
                        next;
                    }
                    elsif ( $WBFC == 0 ) {
                        if ( $tversion !~ m/^11203/ ) {
                            next;
                        }
                    }
                }
            }

            if ( eval &create_expression( $id, $version ) ) {
                $color = $EXC_COLOR;
                $msg   = $h_checks->{$id}->{'MSG'};
		if ( "$version" eq "N/A" ) {
			$msg   = $NULL_VER_MSG;
			$COLSPAN=3;
		}

                $dbrow .= qq|
			$istart_tr
			<td scope="row">$h_checks->{$id}->{'REC_VERSION'}</td>
			<td scope="row"><font color=$color>$msg</font>$APPEND_MSG</td>
			$iend_tr|;
                $FAIL = $FAIL + 1;
            }
            else {
                next;
            }
            $istart_tr = qq|<tr align=$ALIGN>|;
        }
        if ( $FAIL >= 1 ) {
            my @server_count = split( ',', $RD_NAMES{$_} );
            my $limit = 2;
            if ( scalar(@server_count) <= $limit ) {
                $rdrow = qq|
			       $start_tr
			       <td scope="row" rowspan=$FAIL>
			       <div id=$random.$version>$RD_NAMES{$_}:</div>
			       <br>$rdhome
			       </td>|;
		if($COLSPAN == 1) {
			$rdrow .= qq|
			       <td class="DBVERSION:$rdhome" scope="row" rowspan=$FAIL>$print_version</td>
			       $dbrow		
			       $end_tr
			|;
		}
		else {
			$rdrow .= qq|<td scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
		}
            }
            else {
                $rdrow = qq|
			       	$start_tr
				<td scope="row" rowspan=$FAIL>
					<a href="javascript:ShowHideRegion('$random.$version')">| . join( ',', splice( @server_count, 0, $limit ) ) . qq|</a>
					<div id=$random.$version style="DISPLAY: none">|
	 			        . join( ',', @server_count )
			         	. qq|<a href="javascript:ShowHideRegion('$random.$version');"> ..Hide</a>
			       		</div>
				       <br>$rdhome
			       </td>|;
		if($COLSPAN == 1) {
			       $rdrow .= qq|<td class="DBVERSION:$rdhome" scope="row" rowspan=$FAIL>$print_version</td>
			       $dbrow
			       $end_tr
			|;
		}
		else{
			$rdrow .= qq|<td scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
		}
            }
        }
        elsif ( $FAIL == 0 ) {
            if ( "$version" eq "N/A" || "$max" eq "N/A" ) {
                $color = $EXC_COLOR;
                $msg   = $NULL_VER_MSG;
		$COLSPAN = 3;
            }
            else {
                $color = $PASS_COLOR;
                $msg   = $PASS_MESSAGE;
            }

            my @server_count = split( ',', $RD_NAMES{$_} );
            my $limit = 2;
            if ( scalar(@server_count) <= $limit ) {
                $rdrow = qq|
				$start_tr
				<td scope="row">
					<div id=$random.$version>$RD_NAMES{$_}:</div>
					<br>$rdhome
				</td>|;
		if($COLSPAN == 1) {
			$rdrow .= qq|
				<td class="DBVERSION:$rdhome" scope="row">$print_version</td>
				<td scope="row">$max</td>
				<td scope="row"><font color=$color>$msg</font></td>		
				$end_tr
	                       |;
		}
		else {
			$rdrow .= qq|<td scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
		}
            }
            else {
                $rdrow = qq|
				$start_tr
				<td scope="row">
					<a href="javascript:ShowHideRegion('$random.$version')">| . join( ',', splice( @server_count, 0, $limit ) ) . qq|</a>
					<div id=$random.$version style="DISPLAY: none">|
					. join( ',', @server_count )
					. qq|<a href="javascript:ShowHideRegion('$random.$version');"> ..Hide</a>
					</div>
					<br>$rdhome
				</td scope="row">|;
		if($COLSPAN == 1) {
			$rdrow .= qq|
				<td class="DBVERSION:$rdhome" scope="row">$print_version</td>
				<td scope="row">$max</td>
				<td scope="row"><font color=$color>$msg</font></td>		
				$end_tr
		       |;
		}
		else {
			$rdrow .= qq|<td scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
		}
            }
        }
        $rdbms_html .= $rdrow;
        $start_tr = qq|<tr align=$ALIGN>|;
        if ($FAIL) {
            $irowspan = $irowspan + $FAIL;
        }
        else {
            $irowspan = $irowspan + 1;
        }
    }
    $trowspan = $trowspan + $irowspan;
    $rdbms_html =~ s/DBHCOUNT/\Q$irowspan/;
}

#---------------
my $dbserver_list;

if ( $CLUSTER != 0 ) {
    $APPEND_MSG='';
    if ( $EXADATA != 0 ) {
        foreach ( sort { $a cmp $b } keys %{ $DB_HASH->{'EXADATA'} } ) {
            $dbserver_list .= ',' . $_;
        }
        $dbserver_list =~ s/^,//g;
        $grid_html .= qq|<tr align=$ALIGN><td scope="row" rowspan=GRIDCOUNT>Grid Infrastructure</td>|;
    }
    else {
        foreach ( sort { $a cmp $b } keys %{ $DB_HASH->{'EXADATA'} } ) {
            $dbserver_list .= ',' . $_;
        }
        $dbserver_list =~ s/^,//g;
        $grid_html .= qq|<td align=$ALIGN scope="row" rowspan=GRIDCOUNT>Grid Infrastructure</td>|;
    }

    my ( $cluster_home, $cluster_version );
    foreach ( sort { $a cmp $b } keys %{ $DB_HASH->{'EXADATA'} } ) {
        while ( my ( $key, $value ) =
            each( %{ $DB_HASH->{'EXADATA'}->{$_}->{'CLUSTER'} } ) )
        {
            $cluster_home    = $key;
            $cluster_version = $value;
            last;
        }
    }

    my ( $mstr, $tversion );

    my $print_cluster_version = $cluster_version;
    $cluster_version =~ s/<br>$BASE_MSG<\/br>//g;
    
    $tversion = $cluster_version;
    $tversion =~ s/\.(\d{1}$)/\.0$1/g;
    $tversion =~ s/\.|-//g;

    if ( $tversion =~ m/^11202/ ) {
        $mstr = 'gihome11202';
    }
    elsif ( $tversion =~ m/^11203/ ) {
        $mstr = 'gihome11203';
	if ($tversion >= 1120321 && $tversion <= 1120324) {
	    $APPEND_MSG="<br><font color=$PASS_COLOR>$PASS_MESSAGE</font></br>";
	}
    }
    elsif ( $tversion =~ m/^11204/ ) {
        $mstr = 'gihome11204';
    }
    elsif ( $tversion =~ m/^12101/ ) {
        $mstr = 'gihome12101';
    }
    elsif ( $tversion =~ m/^12102/ ) {
        $mstr = 'gihome12102';
    }
    elsif ( $tversion =~ m/^12201/ ) {
        $mstr = 'gihome12201';
    }    
    elsif ( $tversion =~ m/^18/ ) {
        $mstr = 'gihome18';
    }
    else {
        $mstr = 'gihome';
    }

    @IDS = ();
    for ( keys %{$h_checks} ) {
        if ( $h_checks->{$_}->{'TARGET'} eq "$mstr" ) {
            my @threshold = split( ',', $h_checks->{$_}->{'THRESHOLD'} );
            my $insert    = 0;
            my $iversion  = substr( $tversion, 0, 5 );
			if ($iversion =~ m/^18/) {
				$iversion = substr( $tversion, 0, 2);
			}
			
            foreach my $threshold (@threshold) {
                $threshold =~ s/\.(\d{1}$)/\.0$1/g;
                $threshold =~ s/\.|-//g;
                if ($iversion =~ m/^18/) {
                	$threshold =  substr( $threshold, 0, 2 );
                }
                if ( $threshold =~ m/$iversion/ ) {
                    $insert = 1;
                    last;
                }
            }
            if ( $insert == 1 ) {
                push( @IDS, $_ );
            }
        }
    }
    my $trow;
    my ( $cmax, $ctmp ) = ( 'N/A', 0 );
    foreach my $id (@IDS) {
        my $abs = $h_checks->{$id}->{'REC_VERSION'};
        $abs =~ s/\.(\d{1}$)/\.0$1/g;
        $abs =~ s/\.|-//g;
        $ctmp =~ s/\.(\d{1}$)/\.0$1/g;
        $ctmp =~ s/\.|-//g;
        if ( $ctmp < $abs ) {
            $ctmp = $h_checks->{$id}->{'REC_VERSION'};
            $cmax = $h_checks->{$id}->{'REC_VERSION'};
        }
    }

    my ( $istart_tr, $iend_tr ) = ( '', '</tr>' );
    my $FAIL = 0;
    my $gridrow;

    $COLSPAN = 1;
    foreach my $id (@IDS) {
        $msg = '';
        if ( $tversion !~ m/^11204/ && $tversion !~ m/^12101/ && $tversion !~ m/^12201/ ) {
            next if ( $WBFC == 0 && $h_checks->{$id}->{'DEP_FEATURE'} eq "WBFC" );
            next if ( $WBFC == 1 && $h_checks->{$id}->{'DEP_FEATURE'} ne "WBFC" );
        }

        if ( eval &create_expression( $id, $cluster_version ) ) {
            $color = $EXC_COLOR;
            $msg   = $h_checks->{$id}->{'MSG'};
            if ( "$cluster_version" eq "N/A" ) {
                $msg     = $NULL_VER_MSG;
                $COLSPAN = 3;
            }

            $trow .= qq|
			$istart_tr
			<td align=$ALIGN scope="row">$h_checks->{$id}->{'REC_VERSION'}</td>
			<td align=$ALIGN scope="row"><font color=$color>$msg</font>$APPEND_MSG</td>
			$iend_tr
			|;
            $FAIL = $FAIL + 1;
        }
        else {
            next;
        }
        $istart_tr = qq|<tr align=$ALIGN>|;
    }
    my ( $start_tr, $end_tr ) = ( '', '</tr>' );
    if ( $FAIL >= 1 ) {
        my @server_count = split( ',', $dbserver_list );
        my $limit = 2;
        if ( scalar(@server_count) <= $limit ) {
            $gridrow = qq|
			$start_tr
				<td align=$ALIGN scope="row" rowspan=$FAIL>
				<div id='GI'>$dbserver_list:</div>
				<br>$cluster_home
	                        </td>|;
            if ( $COLSPAN == 1 ) {
                $gridrow .= qq|<td class="GIVERSION" align=$ALIGN scope="row" rowspan=$FAIL>$print_cluster_version</td> $trow $end_tr |;
            }
            else {
                $gridrow .= qq|<td scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
            }
        }
        else {
            $gridrow = qq|
			$start_tr
			<td align=$ALIGN scope="row" rowspan=$FAIL>
				<a href="javascript:ShowHideRegion('GI');">| . join( ',', splice( @server_count, 0, $limit ) ) . qq|</a>
		                <div id='GI' style="DISPLAY: none">|
        	      		. join( ',', @server_count )
              			. qq|:<a href="javascript:ShowHideRegion('GI');"> ..Hide</a>
	                	</div>
		                <br>$cluster_home
	                </td>|;
            if ( $COLSPAN == 1 ) {
                $gridrow .= qq|<td class="GIVERSION" align=$ALIGN scope="row" rowspan=$FAIL>$print_cluster_version</td> $trow $end_tr |;
            }
            else {
                $gridrow .= qq|<td align=$ALIGN scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
            }
        }
    }
    else {
        if ( "$cmax" eq "N/A" ) {
            $color   = $EXC_COLOR;
            $msg     = $NULL_VER_MSG;
            $COLSPAN = 3;
        }
        else {
            $color = $PASS_COLOR;
            $msg   = $PASS_MESSAGE;
        }

        my @server_count = split( ',', $dbserver_list );
        my $limit = 2;
        if ( scalar(@server_count) <= $limit ) {
            $gridrow = qq|
			$start_tr
			<td align=$ALIGN scope="row">
			<div id='GI'>$dbserver_list:</div>
			<br>$cluster_home
			</td>|;
            if ( $COLSPAN == 1 ) {
                $gridrow .=
                  	qq|<td class="GIVERSION" align=$ALIGN scope="row">$print_cluster_version</td>
			<td align=$ALIGN scope="row">$cmax</td>
			<td align=$ALIGN scope="row"><font color=$color>$msg</td>
			$end_tr
			|;
            }
            else {
                $gridrow .= qq|<td align=$ALIGN scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
            }
        }
        else {
            $gridrow = qq|
			$start_tr
	                        <td align=$ALIGN scope="row">
					<a href="javascript:ShowHideRegion('GI');">| . join( ',', splice( @server_count, 0, $limit ) ) . qq|</a>
					<div id='GI' style="DISPLAY: none">|
				        . join( ',', @server_count )
				        . qq|:<a href="javascript:ShowHideRegion('GI');"> ..Hide</a>
					</div>
					<br>$cluster_home
	                        </td>|;
			if ( $COLSPAN == 1 ) {
	                        $gridrow .= qq|<td class="GIVERSION" align=$ALIGN scope="row">$print_cluster_version</td>
		                        <td align=$ALIGN scope="row">$cmax</td>
		                        <td align=$ALIGN scope="row"><font color=$color>$msg</font></td>
					$end_tr
					|;
			}
			else {
				$gridrow .= qq|<td align=$ALIGN scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
			}
        }
    }
    $grid_html .= $gridrow;
    if ( $FAIL == 0 ) {
        $trowspan = $trowspan + 1;
    }
    else {
        $trowspan = $trowspan + $FAIL;
    }
    
    my ($growspan) = $trowspan - $irowspan;
    $grid_html =~ s/GRIDCOUNT/\Q$growspan/g;
}

#---------------
if ( $EXADATA != 0 ) {
	$COLSPAN = 3;
    @IDS = ();
    for ( keys %{$h_checks} ) {
	if ( $h_checks->{$_}->{'TARGET'} =~ m/exadatadatabase/ ) {
            push( @IDS, $_ );
        }
    }
    foreach ( sort { $a cmp $b } keys %{ $DB_HASH->{'EXADATA'} } ) {
        $dbserver_list .= ',' . $_;
        if ( !exists $DB_NAMES{ $DB_HASH->{'EXADATA'}->{$_}->{'EVERSION'} } ) {
            $DB_NAMES{ $DB_HASH->{'EXADATA'}->{$_}->{'EVERSION'} } = $_;
        }
        else {
            $DB_NAMES{ $DB_HASH->{'EXADATA'}->{$_}->{'EVERSION'} } .= ',' . $_;
        }
    }
    $dbserver_list =~ s/^,//g;
    $rowspan = scalar( keys %DB_NAMES );
    if (! defined $rdbms_html && ! defined $grid_html) {
    	$exadata_html =
      	qq|<td scope="row" rowspan=$rowspan>Exadata</td>|;
    } else {
    	$exadata_html =
      	qq|<tr align=$ALIGN><td scope="row" rowspan=$rowspan>Exadata</td>|;
    }
    ( $start_tr, $end_tr ) = ( '', '</tr>' );
    my ($G_REC_VERSION) = '';
    foreach my $unique_version ( keys %DB_NAMES ) {
        my ($tunique_version) = $unique_version;
        $tunique_version =~ s/\.//g;
	my ($unique_version_withoutdot) = $tunique_version;
        $tunique_version = substr($tunique_version, 0, 3);	    
        my (@tIDS);
	foreach my $id (@IDS) {
	    if ( $unique_version_withoutdot >= 122120 && $h_checks->{$id}->{'TARGET'} =~ m/^ExadataDatabase18100$/i) {
		$G_REC_VERSION = $h_checks->{$id}->{'REC_VERSION'};
	    } elsif ( $unique_version_withoutdot < 121230 && {$id}->{'TARGET'} =~ m/^ExadataDatabase$/i) {
		$G_REC_VERSION = $h_checks->{$id}->{'REC_VERSION'};
	    } elsif ($h_checks->{$id}->{'TARGET'} =~ m/$tunique_version/) {
		$G_REC_VERSION = $h_checks->{$id}->{'REC_VERSION'};
	    } else {
		next;
	    }
		$COLSPAN = 1;								
	    if ( eval &create_expression( $id, $unique_version ) ) {
	    	push(@tIDS , $id);    
	    }
	}
	if (!@tIDS) {
            $color 	= $PASS_COLOR;
            $msg   	= qq|<font color=$color>$PASS_MESSAGE</font>|;
            my $ltd	= qq|<td scope="row">$msg</td>|;
            my $REC_VERSION = '12.1.2.3.6';
	    if ($G_REC_VERSION != '') { $REC_VERSION = $G_REC_VERSION; }

            my @server_count = split( ',', $DB_NAMES{$unique_version} );
            my $limit = 2;
            if ( scalar(@server_count) <= $limit ) {
                $exadata_html .= qq|
				$start_tr
				<td scope="row">
				<div id=$unique_version>$DB_NAMES{$unique_version}</div>
				</td>|;
                if ( $COLSPAN == 1 ) {
                    $exadata_html .= qq|<td scope="row">$unique_version</td>
		    		<td scope="row">$REC_VERSION</td>
		    		$ltd
		    		$end_tr
		    		|;
                }
                else {
                    $exadata_html .= qq|<td scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
                }
            }
            else {
                $exadata_html .= qq|
				$start_tr
				<td scope="row">
					<a href="javascript:ShowHideRegion('$unique_version');">| . join( ',', splice( @server_count, 0, $limit ) ) . qq|</a>
					<div id=$unique_version style="DISPLAY: none">|
					. join( ',', @server_count )
					. qq|<a href="javascript:ShowHideRegion('$unique_version');"> ..Hide</a>
					</div>
				</td>|;
                if ( $COLSPAN == 1 ) {
                    $exadata_html .= qq|
		    		<td scope="row">$unique_version</td>
		    		<td scope="row">$REC_VERSION</td>
		    		$ltd
		    		$end_tr|;
                }
                else {
                    $exadata_html .= qq|<td scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
                }
            }
            $start_tr = qq|<tr align=$ALIGN>|;
	    next;
	}

        foreach my $id (@tIDS) {
            my ($ltd);

            $COLSPAN = 1;
            if ( eval &create_expression( $id, $unique_version ) ) {
                $color = $EXC_COLOR;
                $msg   = $h_checks->{$id}->{'MSG'};
                if ( "$unique_version" eq "N/A" ) {
                    $msg     = $NULL_VER_MSG;
                    $COLSPAN = 3;
                }

                $msg .= qq|<br>| . $EXC_MESSAGE if ( $rowspan > 1 );
                $ltd = qq|<td scope="row"><font color=$color>$msg</font></td>|;
            }
            else {
                $color = $PASS_COLOR;
                $msg   = qq|<font color=$color>$PASS_MESSAGE</font>|;
                if ( $rowspan > 1 ) {
                    $color = $EXC_COLOR;
                    $msg   .= qq|<br>| . qq|<font color=$color>$EXC_MESSAGE</font>|;
                }
                $ltd = qq|<td scope="row">$msg</td>|;
            }

            my @server_count = split( ',', $DB_NAMES{$unique_version} );
            my $limit = 2;
            if ( scalar(@server_count) <= $limit ) {
                $exadata_html .= qq|
				$start_tr
				<td scope="row">
				<div id=$unique_version>$DB_NAMES{$unique_version}</div>
				</td>|;
                if ( $COLSPAN == 1 ) {
                    $exadata_html .= qq|<td scope="row">$unique_version</td>
		    		<td scope="row">$h_checks->{$id}->{'REC_VERSION'}</td>
		    		$ltd
		    		$end_tr
		    		|;
                }
                else {
                    $exadata_html .= qq|<td scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
                }
            }
            else {
                $exadata_html .= qq|
				$start_tr
				<td scope="row">
					<a href="javascript:ShowHideRegion('$unique_version');">| . join( ',', splice( @server_count, 0, $limit ) ) . qq|</a>
					<div id=$unique_version style="DISPLAY: none">|
					. join( ',', @server_count )
					. qq|<a href="javascript:ShowHideRegion('$unique_version');"> ..Hide</a>
					</div>
				</td>|;
                if ( $COLSPAN == 1 ) {
                    $exadata_html .= qq|
		    		<td scope="row">$unique_version</td>
		    		<td scope="row">$h_checks->{$id}->{'REC_VERSION'}</td>
		    		$ltd
		    		$end_tr|;
                }
                else {
                    $exadata_html .= qq|<td scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
                }
            }
            $start_tr = qq|<tr align=$ALIGN>|;
        }
    }
    if (! defined $rdbms_html && ! defined $grid_html) {
	$exadata_html .= qq||;
    } else {
        $exadata_html .= qq|</tr>|;
    }
    $trowspan = $trowspan + $rowspan;
}

if (! defined $rdbms_html && ! defined $grid_html && ! defined $exadata_html) { $db_html = ""; }

$db_html .= $rdbms_html . $grid_html . $exadata_html;
$db_html =~ s/DBCOUNT/\Q$trowspan/;
$db_html = '' if ( !@dbfiles );

#---------------
my @ssfiles;
@f_patterns = ( 'c_cbc_exadata_versions_', 'c_cbc_CellFlashCacheMode_', 'c_cbc_smart_flashlog_');
foreach (@f_patterns) {
    push( @ssfiles, glob(File::Spec->catfile("$dir", "$_*.out")) );
    push( @ssfiles, glob(File::Spec->catfile("$dir", "outfiles", "$_*.out")) );
    push( @ssfiles, glob(File::Spec->catfile("$dir", ".CELLDIR", "$_*.out")) );
}
@ssfiles = grep( !/report/, @ssfiles );
@v_patterns = ('Exadata Server software version');
my ( $SFL_FOUND, $WBFC_FOUND ) = ( 0, 0 );
foreach (@ssfiles) {
    open( OUTFILE, '<', $_ );

    my $name = $_;
    $name = basename($name);
    $name =~ s/\.out$//g;
    $name =~ s/^c_cbc_//g;
 
    my @ss_ipadr = split('_', $name);
    if ( $#ss_ipadr > 3 ) {
	$name = (split('_', $name))[-4] . '.' . (split('_', $name))[-3] . '.' . (split('_', $name))[-2] . '.' . (split('_', $name))[-1];
    } else {
	$name = (split('_', $name))[-1];
    }
    
    my ($cellfile) = File::Spec->catfile("$dir", ".CELLDIR", "cells.out");
    open (CELLFIL , $cellfile);
    while (<CELLFIL>) {
        if ( $_ =~ m/$name/ ) {
          $name = $_;
	  chomp($name);
          $name = ( split '=' , $name ) [1];
          $name =~ s/ //g;
        }
    }
    close(CELLFIL);

    my $value;
    if ( $_ =~ m/c_cbc_smart_flashlog_/ ) {
        $SFL_FOUND = 1;
        ( $value = <OUTFILE> ) =~ s/^\s*|\s*$//g;
        $SS_HASH->{'EXADATA'}->{$name}->{'SMART FLASH LOG'} = $value;
    }
    elsif ( $_ =~ m/c_cbc_CellFlashCacheMode_/ ) {
        $WBFC_FOUND = 1;
        ( $value = <OUTFILE> ) =~ s/^\s*|\s*$//g;
        $SS_HASH->{'EXADATA'}->{$name}->{'WBFC'} = $value;
    }

    while ( my $line = <OUTFILE> ) {
        next if ( chomp($line) =~ m/^\s*$/ );
        $line =~ s|<.+?>||g;
        $line =~ s/^\s*|\s*$//g;

        foreach my $pattern (@v_patterns) {
            $VERSION  = 'N/A';
            $SS_FOUND = 1;
            if ( $line =~ m/\Q$pattern/i ) {
                ( $line = <OUTFILE> ) =~ s/^\s*|\s*$//g;
                $VERSION = $1 if ( $line =~ m/((\d{1,3}(\.|\-))+\d+)/ );
                ( $VERSION = $1 ) =~ s/\.$//g
                  if ( $VERSION =~ m/((\d{1,3}\.){5})/ );
                $SS_HASH->{'EXADATA'}->{$name}->{'EVERSION'} = $VERSION;
            }
        }
    }
    close(OUTFILE);
}
if ( $SFL_FOUND == 0 ) {
    foreach ( keys %{ $SS_HASH->{'EXADATA'} } ) {
        $SS_HASH->{'EXADATA'}->{$_}->{'SMART FLASH LOG'} = 0;
    }
}
if ( $WBFC_FOUND == 0 ) {
    foreach ( keys %{ $SS_HASH->{'EXADATA'} } ) {
        $SS_HASH->{'EXADATA'}->{$_}->{'WBFC'} = 0;
    }
}

my %SS_NAMES;
my $ss_html;
if ( $SS_FOUND != 0 ) {
	$COLSPAN = 3;
    @IDS = ();
    for ( keys %{$h_checks} ) {
	if ( $h_checks->{$_}->{'TARGET'} =~ m/exadatastorage/ ) {
            push( @IDS, $_ );
        }
    }
    foreach ( sort { $a cmp $b } keys %{ $SS_HASH->{'EXADATA'} } ) {
        $SFL = $SS_HASH->{'EXADATA'}->{$_}->{'SMART FLASH LOG'};
        if ( !exists $SS_NAMES{ ':' . $SS_HASH->{'EXADATA'}->{$_}->{'EVERSION'} } && !  exists $SS_NAMES{ 'WBFC:' . $SS_HASH->{'EXADATA'}->{$_}->{'EVERSION'} } )
        {
            if ( $SS_HASH->{'EXADATA'}->{$_}->{'WBFC'} >= 1 ) {
                $SS_NAMES{ 'WBFC:' . $SS_HASH->{'EXADATA'}->{$_}->{'EVERSION'} } = $_;
            }
            else {
                $SS_NAMES{ ':' . $SS_HASH->{'EXADATA'}->{$_}->{'EVERSION'} } = $_;
            }
        }
        else {
            if ( $SS_HASH->{'EXADATA'}->{$_}->{'WBFC'} >= 1 ) {
                $SS_NAMES{ 'WBFC:' . $SS_HASH->{'EXADATA'}->{$_}->{'EVERSION'} } .= ',' . $_;
            }
            else {
                $SS_NAMES{ ':' . $SS_HASH->{'EXADATA'}->{$_}->{'EVERSION'} } .= ',' . $_;
            }
        }
    }

    $rowspan = scalar( keys %SS_NAMES );
    $ss_html = qq|<tr align=$ALIGN>
	                        <td scope="row" rowspan=$rowspan>STORAGE SERVER</td>
				<td scope="row" rowspan=$rowspan>Exadata</td>
	                |;
    ( $start_tr, $end_tr ) = ( '', '</tr>' );
    my ($G_REC_VERSION) = '';
    foreach my $unique_version ( keys %SS_NAMES ) {
        my ($tunique_version) = $unique_version;
        $tunique_version =~ s/\.//g;
	$tunique_version =~ s/^.*://g;
	my ($unique_version_withoutdot) = $tunique_version;
        $tunique_version = substr($tunique_version, 0, 3);
        my (@tIDS);
        my $version = $unique_version;
        $version =~ s/^.*://g;
        foreach my $id (@IDS) {
	    if ( $unique_version_withoutdot >= 122120 && $h_checks->{$id}->{'TARGET'} =~ m/^ExadataStorage18100$/i) {
		$G_REC_VERSION = $h_checks->{$id}->{'REC_VERSION'};
	    } elsif ( $unique_version_withoutdot < 121230 && {$id}->{'TARGET'} =~ m/^ExadataStorage$/i) {
		$G_REC_VERSION = $h_checks->{$id}->{'REC_VERSION'};
            } elsif ($h_checks->{$id}->{'TARGET'} =~ m/$tunique_version/) {
                $G_REC_VERSION = $h_checks->{$id}->{'REC_VERSION'};
            } else {
                next;
            }
			$COLSPAN = 1;
            if ( eval &create_expression( $id, $version ) ) {
                push(@tIDS , $id);
            }
        }
        if (!@tIDS) {
            $color 	= $PASS_COLOR;
            $msg   	= qq|<font color=$color>$PASS_MESSAGE</font>|;
            my $ltd	= qq|<td scope="row">$msg</td>|;
            my $REC_VERSION = '12.1.2.3.6';
	    if ($G_REC_VERSION != '') { $REC_VERSION = $G_REC_VERSION; }

            my @server_count = split( ',', $SS_NAMES{$unique_version} );
            my $limit = 3;
            if ( scalar(@server_count) <= $limit ) {
                if ( $unique_version =~ m/11\.2\.3\.3\.0/ ) {
                    $ss_html .= qq|
				$start_tr
				<td scope="row">
				<div id=$unique_version>$SS_NAMES{$unique_version}</div>
				</td>|;

                    if ( $COLSPAN == 1 ) {
                        $ss_html .= qq|<td scope="row">$version</td>
				<td scope="row">11.2.3.3.1</td>
				$ltd
				$end_tr
				|;
                    }
                    else {
                        $ss_html .= qq|<td scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
                    }
                }
                else {
                    $ss_html .= qq|
				$start_tr
				<td scope="row">
				<div id=$unique_version>$SS_NAMES{$unique_version}</div>
				</td>|;

                    if ( $COLSPAN == 1 ) {
                        $ss_html .= qq|<td scope="row">$version</td>
				<td scope="row">$REC_VERSION</td>
				$ltd
				$end_tr		
				|;
                    }
                    else {
                        $ss_html .= qq|<td scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
                    }
                }
            }
            else {
                if ( $unique_version =~ m/11\.2\.3\.3\.0/ ) {
                    $ss_html .= qq|
				$start_tr
				<td scope="row">
					<a href="javascript:ShowHideRegion('$unique_version');">| . join( ',', splice( @server_count, 0, $limit ) ) . qq|</a>
					<div id=$unique_version style="DISPLAY: none">|
                      			. join( ',', @server_count )
		                	. qq|<a href="javascript:ShowHideRegion('$unique_version');"> ..Hide</a>
                                	</div>
                	        </td>|;
                    if ( $COLSPAN == 1 ) {
                        $ss_html .= qq|<td scope="row">$version</td>
				<td scope="row">11.2.3.3.1</td>
				$ltd
				$end_tr
				|;
                    }
                    else {
                        $ss_html .= qq|<td scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
                    }
                }
                else {
                    $ss_html .= qq|
				$start_tr
				<td scope="row">
					<a href="javascript:ShowHideRegion('$unique_version');">| . join( ',', splice( @server_count, 0, $limit ) ) . qq|</a>
					<div id=$unique_version style="DISPLAY: none">|
				        . join( ',', @server_count )
				        . qq|<a href="javascript:ShowHideRegion('$unique_version');"> ..Hide</a>
					</div>
				</td>|;
                    if ( $COLSPAN == 1 ) {
                        $ss_html .= qq|<td scope="row">$version</td>
				<td scope="row">$REC_VERSION</td>
				$ltd
				$end_tr		
				|;
                    }
                    else {
                        $ss_html .= qq|<td scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
                    }
                }
            }

            #----
            $start_tr = qq|<tr align=$ALIGN>|;

        }

        foreach my $id (@tIDS) {
            next if ( $h_checks->{$id}->{'DEP_FEATURE'} eq 'WBFC' && $unique_version !~ m/WBFC/i );
            next if ( $h_checks->{$id}->{'DEP_FEATURE'} ne 'WBFC' && $unique_version =~ m/WBFC/i );

            #-----
            if ( $unique_version =~ m/WBFC/i ) {
                $WBFC = 1;
            }
            else {
                $WBFC = 0;
            }
            #-----

            $COLSPAN = 1;
            my $version = $unique_version;
            $version =~ s/^.*://g;
            my ($ltd);
            if ( eval &create_expression( $id, $version ) ) {
                $color = $EXC_COLOR;
                $msg   = $h_checks->{$id}->{'MSG'};

                if ( "$version" eq "N/A" ) {
                    $msg     = $NULL_VER_MSG;
                    $COLSPAN = 3;
                }

                $msg .= qq|<br>| . $EXC_MESSAGE if ( $rowspan > 1 );
                $ltd = qq|<td scope="row"><font color=$color>$msg</font></td>|;
            }
            else {
                $color = $PASS_COLOR;
                $msg   = qq|<font color=$color>$PASS_MESSAGE</font>|;
                if ( $rowspan > 1 ) {
                    $color = $EXC_COLOR;
                    $msg   .= qq|<br>| . qq|<font color=$color>$EXC_MESSAGE</font>|;
                }
                $ltd = qq|<td scope="row">$msg</td>|;
            }

            #----
            my @server_count = split( ',', $SS_NAMES{$unique_version} );
            my $limit = 3;
            if ( scalar(@server_count) <= $limit ) {
                if ( $unique_version =~ m/11\.2\.3\.3\.0/ ) {
                    $ss_html .= qq|
				$start_tr
				<td scope="row">
				<div id=$unique_version>$SS_NAMES{$unique_version}</div>
				</td>|;

                    if ( $COLSPAN == 1 ) {
                        $ss_html .= qq|<td scope="row">$version</td>
				<td scope="row">11.2.3.3.1</td>
				$ltd
				$end_tr
				|;
                    }
                    else {
                        $ss_html .= qq|<td scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
                    }
                }
                else {
                    $ss_html .= qq|
				$start_tr
				<td scope="row">
				<div id=$unique_version>$SS_NAMES{$unique_version}</div>
				</td>|;

                    if ( $COLSPAN == 1 ) {
                        $ss_html .= qq|<td scope="row">$version</td>
				<td scope="row">$h_checks->{$id}->{'REC_VERSION'}</td>
				$ltd
				$end_tr		
				|;
                    }
                    else {
                        $ss_html .= qq|<td scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
                    }
                }
            }
            else {
                if ( $unique_version =~ m/11\.2\.3\.3\.0/ ) {
                    $ss_html .= qq|
				$start_tr
				<td scope="row">
					<a href="javascript:ShowHideRegion('$unique_version');">| . join( ',', splice( @server_count, 0, $limit ) ) . qq|</a>
					<div id=$unique_version style="DISPLAY: none">|
                      			. join( ',', @server_count )
		                	. qq|<a href="javascript:ShowHideRegion('$unique_version');"> ..Hide</a>
                                	</div>
                	        </td>|;
                    if ( $COLSPAN == 1 ) {
                        $ss_html .= qq|<td scope="row">$version</td>
				<td scope="row">11.2.3.3.1</td>
				$ltd
				$end_tr
				|;
                    }
                    else {
                        $ss_html .= qq|<td scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
                    }
                }
                else {
                    $ss_html .= qq|
				$start_tr
				<td scope="row">
					<a href="javascript:ShowHideRegion('$unique_version');">| . join( ',', splice( @server_count, 0, $limit ) ) . qq|</a>
					<div id=$unique_version style="DISPLAY: none">|
				        . join( ',', @server_count )
				        . qq|<a href="javascript:ShowHideRegion('$unique_version');"> ..Hide</a>
					</div>
				</td>|;
                    if ( $COLSPAN == 1 ) {
                        $ss_html .= qq|<td scope="row">$version</td>
				<td scope="row">$h_checks->{$id}->{'REC_VERSION'}</td>
				$ltd
				$end_tr		
				|;
                    }
                    else {
                        $ss_html .= qq|<td scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
                    }
                }
            }

            #----
            $start_tr = qq|<tr align=$ALIGN>|;
        }
    }
    $ss_html = '' if ( !@ssfiles );
}

#---------------
my @ibsfiles;
@f_patterns = ('s_nm2version_');
foreach (@f_patterns) {
    push( @ibsfiles, glob(File::Spec->catfile("$dir", "$_*.out")) );
    push( @ibsfiles, glob(File::Spec->catfile("$dir", "outfiles", "$_*.out")) );
}
@ibsfiles = grep( /report/, @ibsfiles );
@v_patterns = ('infiniband switch firmware version');
foreach (@ibsfiles) {
    open( OUTFILE, '<', $_ );

    my $name = $_;
    $name =~ s/_report//g;
    $name =~ s/^.*version_//g;
    $name =~ s/\.out$//g;
    $name =~ s/_/\./g;
    #$name = $2 if ( $name =~ m/^.*_((.*)\.)out$/ );

    while ( my $line = <OUTFILE> ) {
        next if ( chomp($line) =~ m/^\s*$/ );
        $line =~ s|<.+?>||g;
        $line =~ s/^\s*|\s*$//g;

        foreach my $pattern (@v_patterns) {
            $VERSION = 'N/A';
            if ( $line =~ m/\Q$pattern/i ) {
                for ( my $i = 0 ; $i <= 3 ; $i++ ) {
                    $line = <OUTFILE>;
                }
                $VERSION = $1 if ( $line =~ m/((\d{1,3}(\.|\-))+\d+)/ );
                $IBS_HASH->{'IBSWITCH'}->{$name} = $VERSION;
            }
        }
    }
    close(OUTFILE);
}

my %IBS_NAMES;
my $ibs_html;
@IDS = ();
@IDS = ();
for ( keys %{$h_checks} ) {
    if ( $h_checks->{$_}->{'TARGET'} eq 'ibswitch' ) {
        push( @IDS, $_ );
    }
}
foreach ( sort { $a cmp $b } keys %{ $IBS_HASH->{'IBSWITCH'} } ) {
    if ( !exists $IBS_NAMES{ $IBS_HASH->{'IBSWITCH'}->{$_} } ) {
        $IBS_NAMES{ $IBS_HASH->{'IBSWITCH'}->{$_} } = $_;
    }
    else {
        $IBS_NAMES{ $IBS_HASH->{'IBSWITCH'}->{$_} } .= ',' . $_;
    }
}
$rowspan  = scalar( keys %IBS_NAMES );
$ibs_html = qq|<tr align=$ALIGN>
			<td scope="row" rowspan=$rowspan>IB SWITCH</td>
			<td scope="row" rowspan=$rowspan>Firmware</td>
		|;
( $start_tr, $end_tr ) = ( '', '</tr>' );
foreach my $unique_version ( keys %IBS_NAMES ) {
    foreach my $id (@IDS) {
        my ($ltd);

        $COLSPAN = 1;
        if ( eval &create_expression( $id, $unique_version ) ) {
            $color = $EXC_COLOR;
            $msg   = $h_checks->{$id}->{'MSG'};
            if ( "$unique_version" eq "N/A" ) {
                $msg     = $NULL_VER_MSG;
                $COLSPAN = 3;
            }

            $msg .= qq|<br>| . $EXC_MESSAGE if ( $rowspan > 1 );
            $ltd = qq|<td scope="row"><font color=$color>$msg</font></td>|;
        }
        else {
            $color = $PASS_COLOR;
            $msg   = qq|<font color=$color>$PASS_MESSAGE</font>|;
            if ( $rowspan > 1 ) {
                $color = $EXC_COLOR;
                $msg   .= qq|<br>| . qq|<font color=$color>$EXC_MESSAGE</font>|;
            }
            $ltd = qq|<td scope="row">$msg</td>|;
        }

        #----
        my @server_count = split( ',', $IBS_NAMES{$unique_version} );
        my $limit = 3;
        if ( scalar(@server_count) <= $limit ) {
            $ibs_html .= qq|
				$start_tr
				<td scope="row">
				<div id=$unique_version>$IBS_NAMES{$unique_version}
				</div>
				</td>|;
            if ( $COLSPAN == 1 ) {
                $ibs_html .= qq|<td scope="row">$unique_version</td>
				<td scope="row">$h_checks->{$id}->{'REC_VERSION'}</td>
				$ltd
				$end_tr		
				|;
            }
            else {
                $ibs_html .= qq|<td scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
            }
        }
        else {
            $ibs_html .= qq|
				$start_tr
				<td scope="row">
					<a href="javascript:ShowHideRegion('$unique_version');">| . join( ',', splice( @server_count, 0, $limit ) ) . qq|</a>
					<div id=$unique_version style="DISPLAY: none">|
					. join( ',', @server_count )
					. qq|<a href="javascript:ShowHideRegion('$unique_version');"> ..Hide</a>
					</div>
				</td>|;
            if ( $COLSPAN == 1 ) {
                $ibs_html .= qq|<td scope="row">$unique_version</td>
			<td scope="row">$h_checks->{$id}->{'REC_VERSION'}</td>
			$ltd
			$end_tr		
			|;
            }
            else {
                $ibs_html .= qq|<td scope="row" colspan=$COLSPAN><font color=$color>$NULL_VER_MSG</font></td>$end_tr|;
            }
        }
        $start_tr = qq|<tr align=$ALIGN>|;
    }
}
$ibs_html = '' if ( !@ibsfiles );

#----------------------------------------------------------
my $HEADER =
qq|<table id='t_versions' border=1 width=100% summary="Software Version Matrix">
		<tr align=$ALIGN>
			<th scope="col" colspan=2>Component</th>
			<th scope="col">Host/Location</th>
			<th scope="col">Found version
			<th scope="col">Recommended versions</th>
			<th scope="col">Status</th>
		</tr>|;

my $FOOTER = qq|</table>|;

my $HTML = qq|
		<tr>
		<td colspan=7 scope="row">
		$HEADER
		$db_html
		$ss_html
		$ibs_html
		$FOOTER
		</td>
		</tr>
	|;

#----------------------------------------------------------
open( GENREPORT, '>', $dir . '/versions.html' );
print GENREPORT $HTML if ( @dbfiles || @ssfiles || @ibsfiles );
close(GENREPORT);



