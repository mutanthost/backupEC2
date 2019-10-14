#!/usr/local/bin/perl
#
# $Header: tfa/src/orachk_py/scripts/run_individual_checks.pl /main/5 2018/05/08 06:35:26 juikisho Exp $
#
# run_individual_checks.pl
#
# Copyright (c) 2015, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      run_individual_checks.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    apriyada    07/24/15 - Creation
#

use Data::Dumper;
use POSIX;
use File::Spec;
use File::Basename;
use File::Copy;

my $task       = $ARGV[0];
my $exfil      = $ARGV[1];
my $REFFIL     = $ARGV[2];
my $REFFIL1    = $ARGV[3];
my $check2run  = $ARGV[4];
my $INPUTDIR   = $ARGV[5];
my $OUTPUTDIR  = $ARGV[6];
my $SKIPFIL    = $ARGV[7];
my $components = $ARGV[8];

my $host = $ARGV[9];
chomp($host);
my $EXCLUDELOG = $ARGV[10];
chomp($EXCLUDELOG);
my %parent_ids;
my %selected_ids;
my %suspended_chkids;

open( OF, '>', File::Spec->catfile( $INPUTDIR, "collections1.dat" ) );
open( FF, '>', File::Spec->catfile( $INPUTDIR, "rules1.dat" ) );

if ( $task eq "run" ) {
    print OF "COLLECTIONS_START\n";
    print FF "APPENDIX_START\n";
    print FF "APPENDIX_END\n";
    print FF "RULES_START\n";
    print FF "RULES_END";
}
close(OF);
close(FF);

$check_num = 0;

@checks = split( /,/, $check2run );

$check2run = "";

foreach $checkidval (@checks) {
    if ( $selected_ids{$checkidval} eq "" ) {
        $selected_ids{$checkidval} = 1;

        #$checkline = `grep "LEVEL.*$checkidval"  $REFFIL`;
        $checkline = grepPatternFromFile( $REFFIL, "LEVEL.*$checkidval" );
        if ( $checkline ne "" ) {
            @temparr = split( / /, $checkline );
            $realcheck = $temparr[2];

            #$realcheck = `echo "$checkline"|awk -F" " '{print \$3}'`;
            chomp($realcheck);
            chomp($realcheck);
        }
        if ( $checkline eq "" || $checkidval ne $realcheck ) {
            open( OF, ">>", $SKIPFIL );
            print "Skipping check ($checkidval) on $host as it is invalid\n\n";
            print OF "Skipping check ($checkidval) on $host as it is invalid\n";
            close(OF);
        }
        else {

            #$row_id = `echo "$checkline"|awk -F"." '{print \$1}'`;
            @tmparr = split( /\./, $checkline );
            $row_id = $tmparr[0];
            chomp($row_id);
            chomp($row_id);

        #$checklvl = `echo "$checkline"|awk -F"-" '{print \$2}'|sed s/LEVEL //`;
            if ( $checkline =~ /.*LEVEL (\d+).*/ ) {
                $checklvl = $1;
            }

            #@parents = `grep "^$row_id\\.(.*)-LEVEL" $REFFIL`;
            #@parents = `grep "^$row_id\\." $REFFIL`;
            $parret = grepPatternFromFile( $REFFIL, "^$row_id\\." );
            @parents = split( /\n/, $parret );
            #@parents = grepPatternFromFile( $REFFIL, "^$row_id\." );
            foreach $pcheck (@parents) {
                if ( $pcheck =~ /.*LEVEL (\d+).*/ ) {
                    $compval = $1;
                }
                if ( $checklvl >= $compval ) {
                    @tmparr = split( / /, $pcheck );
                    $checkadd = $tmparr[2];

                    #$checkadd = `echo "$pcheck"|awk '{print \$3}'`;
                    chomp($checkadd);
                    chomp($checkadd);
                    if ( $selected_ids{$checkadd} eq "" ) {

                        #$collfil = `grep "$checkadd-SOURCE_FILE" $REFFIL|awk '{print \$(NF)}'`;
                        $srcfil = grepPatternFromFile( $REFFIL,
                            "$checkadd-SOURCE_FILE" );
                        @collfilarr = split( / /, $srcfil );
                        $collfil = $collfilarr[-1];
                        chomp($collfil);
                        if ( $collfil ne "" ) {
                            $collselect = 0;

                            #@coll_id_list = `grep "OUTPUT_FILE $collfil\$" $REFFIL| awk -F"-" '{print \$1}'|sed s/_//`;
                            $coll_id_list_ret = grepPatternFromFile( $REFFIL,   "OUTPUT_FILE ${collfil}\$" );
                            @coll_id_list = split(/\n/,$coll_id_list_ret );
                            if (scalar(@coll_id_list) == 1){
                                chomp($coll_id_list[0]);
                                @tmparr = split( /-/, $coll_id_list[0] );
                                $coll_id = $tmparr[0];
                                $coll_id =~ s/_//;
                                $check2run = "$check2run,$coll_id";
                            }
                            else{ 
                            foreach $coll_id (@coll_id_list) {
                                @tmparr = split( /-/, $coll_id );
                                $coll_id = $tmparr[0];
                                $coll_id =~ s/_//;
                                if ( $collselect == 0 ) {
                                    chomp($coll_id);
                                    grepPatternFromFilecnt( $REFFIL,
                                        "LEVEL.*$coll_id" );
                                    if ( $grpcnt gt 0 ) {
                                        $comp = grepPatternFromFile( $REFFIL,
                                            "_$coll_id-COMPONENTS" );
                                        @comparr = split( / /, $comp );
                                        $comp = $comparr[1];

                                        #$comp = `grep "_$coll_id-COMPONENTS" $REFFIL|awk -F" " '{print \$2}'`;
                                        chomp($comp);
                                        $comp =~ s/:DBM:/:EXADATA:/g;
                                        @compcheck = split( /:/, $comp );
                                        foreach $compval (@compcheck) {
                                            chomp($compval);
                                            if ( uc($components) =~ /$compval/ ) {
                                                if ( $check2run !~ /$coll_id/ )
                                                {
                                                    $check2run =
                                                      "$check2run,$coll_id";
                                                }
                                                $collselect = 1;
                                                last;
                                            }
                                        }
                                    }
                                }
                            }
                          }
                        }
                    }

                    if ( $parent_ids{$checkidval} ) {
                        if ( $selected_ids{$checkadd} eq "" ) {
                            $parent_ids{$checkidval} =
                              "$parent_ids{$checkidval},$checkadd";
                            $selected_ids{$checkadd} = 1;
                        }
                    }
                    else {
                        if ( $selected_ids{$checkadd} eq "" ) {
                            $parent_ids{$checkidval} = "$checkadd";
                            $selected_ids{$checkadd} = 1;
                        }
                    }
                }
            }
            if ( $task eq "run" ) {
                $collfil =
                  grepPatternFromFile( $REFFIL, "$checkidval-SOURCE_FILE" );
                @collfilarr = split( / /, $collfil );
                $collfil = $collfilarr[-1];

      #$collfil = `grep "$checkidval-SOURCE_FILE" $REFFIL|awk '{print \$(NF)}'`;
                chomp($collfil);
                if ( $collfil ne "" ) {
                    $collselect = 0;

                    #@coll_id_list = `grep "OUTPUT_FILE $collfil\$" $REFFIL| awk -F"-" '{print \$1}'|sed s/_//`;
                    $coll_id_list_ret =   grepPatternFromFile( $REFFIL, "OUTPUT_FILE $collfil\$" );
                    @coll_id_list = split( /\n/,$coll_id_list_ret) ;
                    if (scalar(@coll_id_list) == 1){
                        chomp($coll_id_list[0]);
                        @tmparr = split( /-/, $coll_id_list[0] );
                        $coll_id = $tmparr[0];
                        $coll_id =~ s/_//;
                        $check2run = "$check2run,$coll_id";
                    }
                    else{
                    foreach $coll_id (@coll_id_list) {
                        @coll_idarr = split( /-/, $coll_id );
                        $coll_id = $coll_idarr[0];
                        $coll_id =~ s/_//;
                        if ( $collselect == 0 ) {
                            chomp($coll_id);
                            grepPatternFromFilecnt( $REFFIL,
                                "LEVEL.*$coll_id" );
                            if ( $grpcnt gt 0 ) {
                                $comp = grepPatternFromFile( $REFFIL,
                                    "_$coll_id-COMPONENTS" );
                                @comparr = split( / /, $comp );
                                $comp = $comparr[1];

                                #$comp = `grep "_$coll_id-COMPONENTS" $REFFIL|awk -F" " '{print \$2}'`;
                                chomp($comp);
                                $comp =~ s/:DBM:/:EXADATA:/g;
                                @compcheck = split( /:/, $comp );
                                foreach $compval (@compcheck) {
                                    chomp($compval);
                                    if ( uc($components) =~ /$compval/ ) {
                                        if ( $check2run !~ /$coll_id/ ) {
                                            $check2run = "$check2run,$coll_id";
                                        }
                                        $collselect = 1;
                                        last;
                                    }
                                }
                            }
                        }
                    }
                   }
                    #$check2run = "$check2run,$coll_id";
                }
            }
            $check2run = "$check2run,$checkidval";
        }
    }
}

$check2run =~ s/^.//;

@checks = split( /,/, $check2run );

sub append_to_date_file {
    my $checkidval  = $_[0];
    my $check_num   = $_[1];
    my $p_abs_rowid = $_[2];
    $start      = 0;
    $line       = "";
    $checkentry = grepPatternFromFile( $REFFIL, "LEVEL.*$checkidval" );

    #$checkentry = `grep "LEVEL.*$checkidval" $REFFIL`;
    @c_abs_rowidarr = split( /-/, $checkentry );
    $c_abs_rowid = $c_abs_rowidarr[0];
    $c_abs_rowid =~ s/_//g;
    $c_abs_rowid =~ s/\.//g;

#my $c_abs_rowid = `echo "$checkentry"|awk -F- '{print \$1}'|sed 's/_//g'|sed 's/\\.//g'`;

    $checkentry =~ s/_(\d+)\./_$check_num./;
    $checkentry = "${checkentry}COLLECTIONS_START";
    if (   defined $p_abs_rowid
        && defined $c_abs_rowid
        && $c_abs_rowid > $p_abs_rowid )
    {
        $suspended_chkids{$c_abs_rowid} = $checkidval;
        return;
    }

my ($tfile) = File::Spec->catfile($INPUTDIR, 'collections1.dat');
`perl -i.bak -pe "s/COLLECTIONS_START/$checkentry/" $tfile`;

    open( COLFIL, '<', $REFFIL );
    open( OF, '>>', File::Spec->catfile( $INPUTDIR, "collections1.dat" ) );
    while (<COLFIL>) {
        $this_line = $_;
        if ( $start == 1 || $this_line =~ /$checkidval-/ ) {
            print OF "$this_line";
        }
        if ( $this_line =~ /$checkidval-.*_START/ ) {
            $start = 1;
        }
        if ( $this_line =~ /$checkidval-.*_END/ ) {
            $start = 0;
        }
    }    #while
    close(COLFIL);
    close(OF);

    open( RULFIL, '<', $REFFIL1 );
    $appline = "";
    $rulline = "";
    $start   = 0;
    while (<RULFIL>) {
        $this_line = $_;
        if (   $this_line =~ /$checkidval-BEGIN_COMMENTS/
            || $this_line =~ /$checkidval-END_COMMENTS/
            || $this_line =~ /$checkidval-PLA_LINE/
            || $this_line =~ /$checkidval-PLA_FAMILY/
            || $this_line =~ /$checkidval-PLA_AREA/
            || $this_line =~ /$checkidval-LINK/
            || $start == 1 )
        {
            $appline = "$appline\n$this_line";
        }
        if (   $this_line =~ /$checkidval-ALERT_LEVEL/
            || $this_line =~ /$checkidval-PASS_MSG/
            || $this_line =~ /$checkidval-FAIL_MSG/
            || $this_line =~ /$checkidval-CAT/
            || $this_line =~ /$checkidval-SUBCAT/ )
        {
            $rulline = "$rulline\n$this_line";
        }
        if ( $this_line =~ /$checkidval-BEGIN_COMMENTS/ ) {
            $start = 1;
        }
        if ( $this_line =~ /$checkidval-END_COMMENTS/ ) {
            $start = 0;
        }
    }    #while
    close(RULFIL);
    $appline = "$appline\nAPPENDIX_END";
    $rulline = "$rulline\nRULES_END";

    $rulline =~ s/\\/\\\\\\\\/g;
    $rulline =~ s/\$/\\\\\\\$/g;
    $rulline =~ s/\//\\\//g;
    $rulline =~ s/\`/\\\`/g;
    $rulline =~ s/\'/\\\'/g;
    $rulline =~ s/\"/\\\"/g;
    $rulline =~ s/\^/\\\^/g;
    $rulline =~ s/\(/\\\(/g;
    $rulline =~ s/\)/\\\)/g;

    $appline =~ s/\\/\\\\\\\\/g;
    $appline =~ s/\$/\\\\\\\$/g;
    $appline =~ s/\//\\\//g;
    $appline =~ s/\`/\\\`/g;
    $appline =~ s/\'/\\\'/g;
    $appline =~ s/\"/\\\"/g;
    $appline =~ s/\^/\\\^/g;
    $appline =~ s/\(/\\\(/g;
    $appline =~ s/\)/\\\)/g;
    
    my ($trfile) = File::Spec->catfile( $INPUTDIR, 'rules1.dat' );
    `perl -i.bak -pe "s/APPENDIX_END/$appline/" $trfile`;
    `perl -i.bak -pe "s/RULES_END/$rulline/" $trfile`;
}

if ( $task eq "run" ) {
    foreach $checkidind (@checks) {
        $p_abs_rowid = grepPatternFromFile( $REFFIL, "LEVEL.*$checkidind" );
        @p_abs_rowidarr = split( /-/, $p_abs_rowid );
        $p_abs_rowid = $p_abs_rowidarr[0];
        $p_abs_rowid =~ s/_//g;
        $p_abs_rowid =~ s/\.//g;

#my $p_abs_rowid = `grep "LEVEL.*$checkidind" $REFFIL|awk -F- '{print \$1}'|sed 's/_//g'|sed 's/\\.//g'`;
        $check_num++;
        if ( $parent_ids{$checkidind} ) {
            @pchecksval = split( /,/, $parent_ids{$checkidind} );
            foreach $pcheckidval (@pchecksval) {
                chomp($pcheckidval);
                chomp($pcheckidval);
                append_to_date_file( $pcheckidval, $check_num, $p_abs_rowid );
            }
        }
        append_to_date_file( $checkidind, $check_num );
        for ( sort( keys(%suspended_chkids) ) ) {
            append_to_date_file( $suspended_chkids{$_}, $check_num );
        }
        undef %suspended_chkids;
    }
    open( AF, ">>", File::Spec->catfile( $INPUTDIR, "collections1.dat" ) );
    print AF "COLLECTIONS_END";
    close(AF);
    move(File::Spec->catfile( $INPUTDIR, "collections1.dat" ), $REFFIL);
    move(File::Spec->catfile( $INPUTDIR, "rules1.dat" ),       $REFFIL1);
}
else {
    open( AF, ">>", File::Spec->catfile( $OUTPUTDIR, 'cmdexfil.txt' ) );
    open( BF, ">>", $exfil );
    open( CF, ">>", $EXCLUDELOG );

    foreach $checkidind (@checks) {
        # if ( $parent_ids{$checkidind} ) {
        #     @pchecksval = split( /,/, $parent_ids{$checkidind} );
        #     foreach $pcheckidval (@pchecksval) {
        #         chomp($pcheckidval);
        #         chomp($pcheckidval);
        #         print BF "$pcheckidval\n";
        #         print AF "$pcheckidval\n";
        #     }
        # }
        print BF "$checkidind\n";
        print AF "$checkidind\n";

#$check_name=`grep "$checkidind-AUDIT_CHECK_NAME" $REFFIL | sed 's/_$checkidind-AUDIT_CHECK_NAME//'`;
        $check_name =
          grepPatternFromFile( $REFFIL, "$checkidind-AUDIT_CHECK_NAME" );
        $check_name =~ s/_$checkidind-AUDIT_CHECK_NAME//;
        chomp($check_name);
        print CF
"Skipping CHECK ID: $checkidind ($check_name) on $host because its excluded\n";
    }
    close(AF);
    close(BF);
    close(CF);
}

sub grepPatternFromFile {
    my $filename = shift;
    my $pattern  = shift;
    my $retpat = "";
    chomp($pattern);
    chomp($filename);
    open FILE, "$filename" or die "Could not open $filename!\n";
    while (<FILE>) {
    	if (/$pattern/) {
        	$retpat = "$retpat"."$_";
        }
    }
    return $retpat;
}

sub grepPatternFromFilecnt {
    $grpcnt = 0;
    my $filename = shift;
    my $pattern  = shift;
    chomp($pattern);
    chomp($filename);
    open FILE, "$filename" or die "Could not open $filename!\n";
    while (<FILE>) {
    	if (/$pattern/) {
	        $grpcnt++;
	    }
    }
    return $grpcnt;
}
