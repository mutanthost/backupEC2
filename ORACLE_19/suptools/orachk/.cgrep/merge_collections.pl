#
# $Header: tfa/src/orachk_py/scripts/merge_collections.pl /main/6 2018/11/01 22:56:00 apriyada Exp $
#
# merge_collections.pl
#
# Copyright (c) 2013, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      merge_collections.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      RETURN STATUS	DESCRIPTION
#   	1		Syntax Error
#    	4		Some of the Candidate Collections are faulty
#	5		Candidate Collections are not from same cluster
#
#
#    MODIFIED   (MM/DD/YY)
#    gowsrini   01/09/18 - XbranchMerge gowsrini_bugfixedtxn from st_tfa_18.1
#    rojuyal    04/16/14 - BUG-18530680
#    rojuyal    10/24/13 - Script to merge collections
#

use warnings;
use strict;
use Getopt::Long;
use File::Basename;
use File::Copy;
use File::Path;
use POSIX qw(strftime);
use Data::Dumper;
use FindBin qw($Bin);
use Cwd 'realpath';
use lib realpath("$Bin");
use Recursive;
use IO::Uncompress::Unzip qw($UnzipError);
use File::Spec::Functions qw(splitpath);
use IO::File;
use File::Spec;
use Config;
my ($OSNAME)                	= $Config{'osname'};
my ($is_windows)				= 0;
$is_windows = 1 if ( $OSNAME =~ m/MSWin/ );

$File::Copy::Recursive::CPRFComp = 1;

#Section:VARIABLES--------
my $RAW_COLLECTIONS;
my $LOCALHOST;
my $PROG_NAME;
my $BASEDIR;
my $SKIP_CRS_VAL = 0;
my @COLLECTIONS;
my %FAULTY_COLLECTIONS;
my @NEW_COLLECTIONS;
my ($FAILCOUNT, $WARNCOUNT, $INFOCOUNT, $TOTALCOUNT) = (0, 0, 0, 0);
my @HOSTS;
my %HASH_CN;
my %HASH_CN2;
my %CLUSTER_CHK;
my %REMOVE_HASH;
my (%PROFILE, %PROFILE_NAME);
my ($STR_PROFILE, $STR_PROFILE_NAME);
my ($READ_PROF, $READ_GRP);
my %PROF;
my %RO; 
my %MBTMP;
my ($PDEBUG)                    = $ENV{RAT_PDEBUG}||0;
my ($PYDIR)                 	= $ENV{RAT_PYDIRNAME} || 'Python37';

#Section:FUNCTIONS--------
sub usage {
    print 
	"Usage: $0
	    -f MERGEFILES
	    -n LOCALNODE
	    -p PROGRAM NAME
	    -d WORKING DIRECTORY
	    -o SKIP CRS VAL(1/0)
	    \n\n";
    exit(1);
}

sub unzip {
    my ($zipfile, $dest) = @_;

    die 'Need a zipfile argument' unless defined $zipfile;
    $dest = "." unless defined $dest;
	my ($presentdir) = $ENV{RAT_SCRIPTPATH};
    my ($python_exe) = $ENV{RAT_PYTHONEXE} || File::Spec->catfile( $presentdir, 'build', $PYDIR, 'bin', 'python' );
    if ( $is_windows == 1 ) {
    	$python_exe = $ENV{RAT_PYTHONEXE} || File::Spec->catfile( $presentdir, 'build', $PYDIR, 'python.exe' );
    }
    	
	my ($constants) = File::Spec->catfile($presentdir,"lib","constant.py");
        if (-e $constants) {
            ;
        } else {
            $constants = File::Spec->catfile($presentdir,"lib","constant.pyc");
        }
	$ENV{'PYTHONPATH'} = $presentdir;
	my $status1 = `$python_exe -m lib.constant 'Constants:extract' '$zipfile,$dest'`;
	$ENV{'PYTHONPATH'} = '';
    return;
    
    my $u = IO::Uncompress::Unzip->new($zipfile) or die "Cannot open $zipfile: $UnzipError";

    my $status;
    for ($status = 1; $status > 0; $status = $u->nextStream()) {
        my $header = $u->getHeaderInfo();
        my (undef, $path, $name) = splitpath($header->{Name});
        my $destdir = File::Spec->catfile("$dest","$path");
        unless (-d $destdir) { mkpath($destdir) or die "Couldn't mkdir $destdir: $!"; }

        if ($name =~ m/^$/) {
            last if $status < 0;
            next;
        }

        my $destfile = File::Spec->catfile("$dest","$path","$name");
        my $buff;
        my $fh = IO::File->new($destfile, "w") or die "Couldn't write to $destfile: $!";
        while (($status = $u->read($buff)) > 0) { $fh->write($buff); }
        $fh->close();
        my $stored_time = $header->{'Time'};
        utime ($stored_time, $stored_time, $destfile) or die "Couldn't touch $destfile: $!";
    }
    die "Error processing $zipfile: $!\n" if $status < 0 ;
    return;
}

#Main Script--------------
if ( @ARGV == 0 ) {
    usage();
}

GetOptions(
    "f=s" => \$RAW_COLLECTIONS ,
    "n=s" => \$LOCALHOST ,
    "p=s" => \$PROG_NAME ,
    "d=s" => \$BASEDIR ,
    "o=n" => \$SKIP_CRS_VAL ,
) or usage();

if (defined $PDEBUG && $PDEBUG == 1) {
    print "Logging is ON\n";
    print "Dump Data: $0\n";
    print "===============================\n";
}	

$BASEDIR = $BASEDIR."/";
$BASEDIR =~ s/\.cgrep//g;

my ($TARGET) = File::Spec->catfile("$BASEDIR", ".MERGED_COLLECTIONS");
#system("rm -rf $TARGET"); 
rmtree($TARGET);
mkdir($TARGET);

@COLLECTIONS = split( ',', $RAW_COLLECTIONS );
if (defined $PDEBUG && $PDEBUG == 1) { print Dumper(\@COLLECTIONS); }
my $NO_OF_COLL = @COLLECTIONS;
my $COLLECTION_CNT = 0;
my $FULLTEXT_CNT = 0;

for my $inputdir (@COLLECTIONS) {
    $COLLECTION_CNT++;
    my $node_exist = 0;
    my $abs_path;
    if ( -d $inputdir ) {
        $abs_path = $inputdir;
    }
    elsif ( -f $inputdir && $inputdir =~ m/\.zip$/ ) {
        $abs_path = $inputdir;
    }
    else {
        $abs_path = $BASEDIR . $inputdir;
        if ( !-d $abs_path ) {
	    $FAULTY_COLLECTIONS{$inputdir} = 1;
	    next;
        }
    }

    if ( $abs_path =~ m/\.zip$/ ) {
        #system("unzip -o $abs_path -d $BASEDIR 1>/dev/null");
		unzip($abs_path,$BASEDIR);
        $abs_path =~ s/\.zip//g;
    }

    $abs_path=basename($abs_path);
    $abs_path=$BASEDIR.$abs_path;
    push( @NEW_COLLECTIONS, $abs_path );

    my ($cellfile) = File::Spec->catfile("$abs_path", "outfiles", "cell_ib_count.out");
    if ( -e $cellfile ) {
        open my $CFILE, '<', $cellfile ;
        while (<$CFILE>) {
          my $count = 0;
          if ($_ =~ m/(\d+)/) {
            $count = $1;
          }

          if ($_ =~ m/FAIL/) {
            $FAILCOUNT = $FAILCOUNT + $count;
          } elsif ($_ =~ m/WARN/) {
            $WARNCOUNT = $WARNCOUNT + $count;
          } elsif ($_ =~ m/INFO/) {
            $INFOCOUNT = $INFOCOUNT + $count;
          } elsif ($_ =~ m/TOTAL/) {     
            $TOTALCOUNT = $TOTALCOUNT + $count;
          }
        }
        close $CFILE;
    }

    my ($mb_tmp_file) = File::Spec->catfile("$abs_path", "outfiles", "mb_db_tmp.out");
    if ( -e $mb_tmp_file ) {
        open my $MBTMPFIL, '<', $mb_tmp_file; 
        while (<$MBTMPFIL>) {
            my $tdblist = $_;
            chomp($tdblist);
            $MBTMP{$tdblist} = 1;
        }
        close $MBTMPFIL;
    }
 
    my ($hfile)	= File::Spec->catfile("$abs_path", "outfiles", "o_host_list.out");
    if ( -e $hfile ) {
        open my $HFIL, '<', $hfile; 
        my %lhost;
        while (<$HFIL>) {
            my $thost = $_;
            chomp($thost);
            $lhost{$thost} = 1;
        }
        close $HFIL;

        my %hparams = map { $_ => 1 } @HOSTS;
        for ( keys %lhost ) {
            if ( exists( $hparams{$_} ) ) {
                $node_exist = 1;
            }
            else {
                push( @HOSTS, $_ );
            }
        }
    }

    my ($chkfile) = File::Spec->catfile("$abs_path", "outfiles", "check_env.out");
    open my $CHKFILE, '<', $chkfile;
    my $FULLTEXT = 0;
    my @text;
    my $node;
    while (<$CHKFILE>) {
        if ( $_ =~ m/CHECKED_NODE/ ) {
            my $mod_text = $_;
            $mod_text =~ s/=\s(.*$)/= $LOCALHOST/g;
            if ( exists $HASH_CN{$mod_text} ) {
                $HASH_CN{$mod_text} = $HASH_CN{$mod_text} . ":" . $1;
            }
            else {
                $HASH_CN{$mod_text} = $1;
            }
        }
        if ( $_ =~ m/^LOCALNODE/ ) {
            $node = $_;
            $node =~ s/^LOCALNODE = //g;
            chomp($node);
            if ( "$LOCALHOST" eq "$node" ) {
                $FULLTEXT = 1;
		$FULLTEXT_CNT++;
            }
        }
 
        if($_ =~ m/ROOT_OPTION/) {
		$RO{$_}=1;
	}
	else {
        	push( @text, $_ );
	}
    }
    close $CHKFILE;

    if ( $NO_OF_COLL == $COLLECTION_CNT && $FULLTEXT_CNT == 0 ) { $FULLTEXT = 1; }

    foreach( keys %HASH_CN ) {
	$HASH_CN2{$_} = $HASH_CN{$_};
    }

    if ( $node_exist == 1 ) {
	undef %HASH_CN;	
        my @ntext = ();
        foreach my $nline (@text) {
            my $match = 0;
            open my $CHKFILE, '<', File::Spec->catfile("$BASEDIR", ".MERGED_COLLECTIONS", "check_env.out.merge");
            my ( $nkey, $nvalue ) = split( '=', $nline );
            if ( $nkey =~ m/CLUSTER_NAME/ ) {
                $CLUSTER_CHK{$nline} = 1;
            }
            if ( $nkey =~ m/PROFILE_NAMES/ ) {
                $READ_PROF = $nline;
            }
            if ( $nkey =~ m/grp_str/ ) {
                $READ_GRP = $nline;
            }
            while ( my $chkline = <$CHKFILE> ) {
                if ( $chkline eq $nline ) {
                    $match = 1;
                    last;
                }
                else {
                    my ( $chkkey, $chkvalue ) = split( '=', $chkline );
                    if ( "$nkey" eq "$chkkey" ) {
                        if ( "$chkvalue" gt "$nvalue" ) {
                            if ( "$nkey" eq 'PROFILES ' ) {
                                $REMOVE_HASH{$chkline} = 1;
                                $REMOVE_HASH{$nline} = 1;
                                $PROFILE{$nvalue}      = 1;
                                $PROFILE{$chkvalue}    = 1;
                                $match                 = 1;
                            }
                            elsif ( "$nkey" eq 'PROFILE_NAMES ' ) {
                                $REMOVE_HASH{$chkline}   = 1;
                                $REMOVE_HASH{$nline} = 1;
                                $PROFILE_NAME{$nvalue}   = 1;
                                $PROFILE_NAME{$chkvalue} = 1;
                                $match                   = 1;
                            }
                            else {
                                $match = 1;
                                last;
                            }
                        }
                        else {
                            if ( "$nkey" eq 'PROFILES ' ) {
                                $PROFILE{$nvalue}      = 1;
                                $REMOVE_HASH{$nline} = 1;
                                $PROFILE{$chkvalue}    = 1;
                            }
                            elsif ( "$nkey" eq 'PROFILE_NAMES ' ) {
                                $PROFILE_NAME{$nvalue}   = 1;
                                $REMOVE_HASH{$nline} = 1;
                                $PROFILE_NAME{$chkvalue} = 1;
                            }
			    if("$nkey" ne 'RDBMS_ORACLE_HOME ' ) {
                            	$REMOVE_HASH{$chkline} = 1;
                            	$match = 1;
			    }
                        }
                    }
		    else {
			if ($chkline =~ m/ROOT_OPTION/) {
				$RO{$chkline}=1;
				$match=1;
				last;
			}
			$match = 0;
		    }
                }
            }

            if ( $match == 0 ) {
                chomp($nline);
                push( @ntext, $nline );
            }
            close($CHKFILE);
        }

        open my $CHKFILE, '>>', File::Spec->catfile("$BASEDIR", ".MERGED_COLLECTIONS", "check_env.out.merge");
        foreach (@ntext) {
            next if ( $_ =~ m/CHECKED_NODE = / );
            print $CHKFILE $_ . "\n";
        }
        close($CHKFILE);
    }
    else {
        open my $CHKFILE, '>>', File::Spec->catfile("$BASEDIR", ".MERGED_COLLECTIONS", "check_env.out.merge");
        if ( $FULLTEXT == 1 ) {
            foreach (@text) {
                if ( $_ !~ m/CHECKED_NODE = / ) {
                    if ( $_ =~ m/CLUSTER_NAME = / ) {
                        $CLUSTER_CHK{$_} = 1;
                    }
                    if ( $_ =~ m/PROFILE_NAMES = / ) {
                        $READ_PROF = $_;
                    }
                    if ( $_ =~ m/grp_str = / ) {
                        $READ_GRP = $_;
                    }
                    print $CHKFILE $_;
                }
            }
        }
        else {
            foreach (@text) {
                if ( $_ =~ m/$node/ ) {
                    if (   $_ !~ m/CHECKED_NODE = /
                        && $_ !~ m/grp_str = /
                        && $_ !~ m/^LOCALNODE = /
                        && $_ !~ m/^ROOT_OPTION = /
                        && $_ !~ m/$node\.\+ASM(\d)+\.VERSION/ )
                    {
                        if ( $_ =~ m/CLUSTER_NAME = / ) {
                            $CLUSTER_CHK{$_} = 1;
                        }
                        print $CHKFILE $_;
                    }
                }
                elsif ($_ =~ m/DB_NAME = /) {
                    my ($pattern) = $_; chomp($pattern);
                    #my ($t_db_cnt) = `grep -ic "$pattern" $BASEDIR'.MERGED_COLLECTIONS/check_env.out.merge'`;
		    my ($t_db_cnt) = 0;
		    open(BMCFIL,'<',File::Spec->catfile("$BASEDIR", ".MERGED_COLLECTIONS", "check_env.out.merge"));
		    while(<BMCFIL>){
		      chomp($_);
		      if($_ =~ m/$pattern/i) { $t_db_cnt++; last; }
		    }
		    close(BMCFIL);

                    if ($t_db_cnt == 0 ) {
                        print $CHKFILE $_;
                    }
                }elsif ($_ =~ m/COMPONENTS =/) {
                    print $CHKFILE $_;
                }

		if ( $_ =~ m/CLUSTER_NAME = / ) {
		    $CLUSTER_CHK{$_} = 1;
		}
            }
        }
        close $CHKFILE;
    }
    $PROF{$READ_PROF} = $READ_GRP if(defined $READ_PROF);
}

if (%FAULTY_COLLECTIONS) {
   my $fault_col="";
   for (keys %FAULTY_COLLECTIONS ) {
	$fault_col=$fault_col.", ".$_;
   } 
   $fault_col=~ s/^, //g;
   print "$fault_col does not exists\n";
   exit(4);
}

if ($SKIP_CRS_VAL == 0) {
    if (%CLUSTER_CHK) {
        my $same_cluster = scalar( keys %CLUSTER_CHK );
        if ( "$same_cluster" ne "1" ) {
            exit(5);
        }
    }
}

my ($mchkfile) 	= File::Spec->catfile("$BASEDIR", ".MERGED_COLLECTIONS", "check_env.out.merge"); 
my ($mhostfile) = File::Spec->catfile("$BASEDIR", ".MERGED_COLLECTIONS", "o_host_list.out.merge");
my ($mcellfile) = File::Spec->catfile("$BASEDIR", ".MERGED_COLLECTIONS", "cell_ib_count.out.merge");
my ($mmbtmpfile)= File::Spec->catfile("$BASEDIR", ".MERGED_COLLECTIONS", "mb_db_tmp.out.merge");

if (%MBTMP) {
    open my $TMP_MBTMPFIL, '>>', $mmbtmpfile;
    for (keys %MBTMP) { 
	print $TMP_MBTMPFIL $_."\n";
    }
    close($TMP_MBTMPFIL);
}

if (%REMOVE_HASH) {
    if ( -e $mchkfile) {
        my $cur_grp_str = "";
        my $new_grp_str = "";
        open my $TMP_CHKFILE, '>>', File::Spec->catfile("$BASEDIR", ".MERGED_COLLECTIONS", ".check_env.out.merge2");
        open my $CHKFILE, '<', $mchkfile;
        while (<$CHKFILE>) {
            if ( !exists $REMOVE_HASH{$_} ) {
                if ( $_ =~ m/grp_str =/ ) {
                    $cur_grp_str = $_;
                }
                else {
                    print $TMP_CHKFILE $_;
                }
            }
        }
        if (%PROF) {
            for ( keys %PROF ) {
                if ( $_ =~ m/dba/ ) {
                    $new_grp_str = $PROF{$_};
                }
            }
            if ($new_grp_str) {
                print $TMP_CHKFILE $new_grp_str;
            }
            else {
                print $TMP_CHKFILE $cur_grp_str;
            }
        }

        close($CHKFILE);
        close($TMP_CHKFILE);

        unlink($mchkfile); 
        rename(
            File::Spec->catfile("$BASEDIR", ".MERGED_COLLECTIONS", ".check_env.out.merge2"),
            $mchkfile 
        );
    }
}

if (defined $PDEBUG && $PDEBUG == 1) { print Dumper(\%PROFILE); }
if (%PROFILE) {
    for ( keys %PROFILE ) {
        my $temp = $_;
        chomp($temp);
        $temp =~ s/\s//g;
        $STR_PROFILE .= $temp . " ";
    }

    for ( keys %PROFILE_NAME ) {
        my $temp = $_;
        chomp($temp);
        $temp =~ s/\s//g;
        $STR_PROFILE_NAME .= $temp . ',';
    }

    open my $CHKFILE, '>>', $mchkfile;
    chop($STR_PROFILE);
    chop($STR_PROFILE_NAME);
    
    print $CHKFILE "PROFILES = " . $STR_PROFILE . "\n";
    print $CHKFILE "PROFILE_NAMES = " . $STR_PROFILE_NAME . "\n";
    close($CHKFILE);
}

if(%RO){
    my $lowest_rvalue = ( sort {$a cmp $b} keys %RO )[0];
    open my $CHKFILE, '>>', $mchkfile;
    print $CHKFILE $lowest_rvalue;
    close($CHKFILE);
}

if (defined $PDEBUG && $PDEBUG == 1) { print Dumper(\%HASH_CN); }
open my $CHKFILE, '>>', $mchkfile;
foreach ( keys %HASH_CN ) {
    my $ok     = 0;
    my $DBNAME = $_;
    $DBNAME =~ s/(^.*)\.CHECKED_NODE.*$/$1/g;
    chomp($DBNAME);

    print $CHKFILE $_;
    my (@p_hosts) = split( ':', $HASH_CN{$_} );
    for my $host (@HOSTS) {
        $ok = 0;
        my $ihost = $host;
        chomp($ihost);
        for my $phost (@p_hosts) {
            my $iphost = $phost;
            if ( $ihost eq $iphost ) {
                $ok = 1;
            }
        }
        if ( $ok eq 0 ) {
            print $CHKFILE "$ihost.$DBNAME.INSTANCE_NAME = \n";
            print $CHKFILE "$ihost.$DBNAME.INSTANCE_MODE = 0\n";
            print $CHKFILE "$ihost.$DBNAME.INSTANCE_VERSION = \n";
        }
    }
}
if (defined $PDEBUG && $PDEBUG == 1) { print Dumper(\%HASH_CN2); }
foreach ( keys %HASH_CN2 ) {
    print $CHKFILE $_;
}
close $CHKFILE;

if (defined $PDEBUG && $PDEBUG == 1) { print Dumper(\@HOSTS); }
open my $FILE, '>>', $mhostfile;
foreach (@HOSTS) {
    print $FILE $_."\n";
}
close $FILE;

open my $CFILE, '>>', $mcellfile ;
print $CFILE "FAIL = $FAILCOUNT\n";
print $CFILE "WARN = $WARNCOUNT\n";
print $CFILE "INFO = $INFOCOUNT\n";
print $CFILE "TOTAL = $TOTALCOUNT\n";
close $CFILE;

for my $inputdir (@NEW_COLLECTIONS) {
    my ($tget) = File::Spec->catfile("$BASEDIR", ".MERGED_COLLECTIONS");
    #system("cp -r $inputdir $tget");
    File::Copy::Recursive::dircopy("$inputdir","$tget");
}

