# $Header: tfa/src/orachk_py/scripts/combine_collections.pl /main/2 2017/08/11 17:38:17 rojuyal Exp $
#
# combine_collections.pl
# 
# Copyright (c) 2015, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      combine_collections.pl - combine different products versions checks
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    rojuyal     07/30/15 - Creation

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use File::Copy;
use File::Spec;

my ($OFFLINE);
my ($INPUTDIR);
my ($what_os);
my ($offline_envfile);
my ($reffil);
my ($is_windows);
my ($grp_str);
my ($GREP);
my ($SCRIPTPATH);
my ($RTEMPDIR);
my ($EXCLUDE_PID_FIL);
my ($versions);
my (@mb_db_versions);
my ($PDEBUG)			= $ENV{RAT_PDEBUG}||0;
my ($perl_exe)			= $ENV{'RAT_PERLEXE'} || 'perl';

sub usage {
  print "Usage: $0 -o offline -p what_od -e offline_enfile -r collections.dat -i inputdir -w if_windows -a grep -g grp_str -t tmpdir -v versions -k excludefile -s scriptpath [-j perltouse]\n";
  exit;
}

if ( @ARGV == 0 ) { usage(); }

GetOptions(
  "o=n" => \$OFFLINE,
  "p=s" => \$what_os,
  "e=s" => \$offline_envfile,
  "r=s" => \$reffil,
  "i=s" => \$INPUTDIR,
  "w=n" => \$is_windows,
  "a=s" => \$GREP,
  "g=s" => \$grp_str,
  "t=s" => \$RTEMPDIR,
  "v=s" => \$versions,
  "k=s" => \$EXCLUDE_PID_FIL,
  "s=s" => \$SCRIPTPATH,
  "j:s" => \$perl_exe
) or usage();

if (defined $PDEBUG && $PDEBUG == 1) {
    print "Logging is ON\n";
    print "Dump Data: $0\n";
    print "===============================\n";
}	

if ($OFFLINE == 0) {
  #`touch "$EXCLUDE_PID_FIL"` if (! -e "$EXCLUDE_PID_FIL");
  if (! -e "$EXCLUDE_PID_FIL") { open(EFIL,'>',"$EXCLUDE_PID_FIL"); close(EFIL); }
  
  open(EPFIL,'>>', "$EXCLUDE_PID_FIL") || die $!;
  print EPFIL "$$\n";
  close(EPFIL);
}

my ($ORIG_REFFIL)	= File::Spec->catfile("$SCRIPTPATH", "collections.dat");

my ( $winpath_orig);
my ( $winpath_ip);
my ( $winpath_ip_val);
my ( $winpath_val);
my ( $nfname);
my ( $winpath_orig_val);

sub get_winpath {
  my ( $fname) = shift;
  if ( $is_windows == 0 ) {
    return;
  } else {
    $winpath_orig	= '$'."$fname"."_winpath_orig";
    $winpath_ip 	= '$'." $fname";
    $winpath_ip_val = eval $winpath_ip;
    $winpath_orig 	= $winpath_ip_val;
    $winpath_val 	= `cygpath -w  $winpath_ip; `;
    $nfname 		= '$'." $fname";
    $nfname 		= $winpath_val;
  }
}

sub restore_winpath {
  my ( $fname) = shift;
  if (  $is_windows == 0 ) {
    return;
  }
  else {
    $winpath_orig 		= '$'." $fname"."_winpath_orig";
    $winpath_ip 		= '$'." $fname";
    $winpath_orig_val 		= eval  $winpath_orig;
    $nfname 			= $winpath_orig_val;
  }
}

sub print_status_bar {
  printf ". ";
}

sub populate_versions {
  @mb_db_versions       = split(' ' , "$versions");

  foreach my $mb_db_version(@mb_db_versions) {
    if ($OFFLINE == 0) {
      $grp_str=$what_os.'_'.$mb_db_version;
    } else {
      my ($what_os_offline);
      open(EFILE,'<',"$offline_envfile") || die $!;
      while (my $eline = <EFILE>) {
        chomp($eline);
	if ($eline =~ m/grp_str/) {
      	  $what_os_offline = $eline;
	  chomp($what_os_offline);
	  $what_os_offline =~ s/^.*=//g;
	  $what_os_offline =~ s/\s*//g;
	  $what_os_offline = (split '_', $what_os_offline)[0];
       	}
      }
      $grp_str=$what_os_offline.'_'.$mb_db_version;
    }
    $grp_str=$grp_str.'-';
    get_winpath('ORIG_REFFIL');

    open(RVDAT,'>',File::Spec->catfile("$INPUTDIR", "collections_$mb_db_version.dat")) || die $!;
    print RVDAT `$GREP $grp_str $ORIG_REFFIL`;
    close(RVDAT);

    open(RVBDAT,'>',File::Spec->catfile("$INPUTDIR", "collections_$mb_db_version.dat.bak")) || die $!;
    open(RVDAT,'<',File::Spec->catfile("$INPUTDIR", "collections_$mb_db_version.dat")) || die $!;
    while(my $line = <RVDAT>) {
      $line =~ s/$grp_str//g;
      print RVBDAT $line; 
    }
    close(RVDAT);
    close(RVBDAT);
	
    move(File::Spec->catfile("$INPUTDIR", "collections_$mb_db_version.dat.bak"),File::Spec->catfile("$INPUTDIR", "collections_$mb_db_version.dat"));
  }
}

sub populate_small_collection {
  my ($mcollection_fil)		= File::Spec->catfile("$INPUTDIR", "collections_main.dat");

  copy(File::Spec->catfile("$INPUTDIR", "collections.dat"),File::Spec->catfile("$INPUTDIR", "collections_main.dat")); 
  `$perl_exe -n -i -e 'print if /^_1.0.0.0.0.0.0.0.0.0-/ .. /^COLLECTIONS_START/' "$mcollection_fil";`;

  open(RVDAT,'<',File::Spec->catfile("$INPUTDIR", "collections_main.dat")) || die $!;
  my (@IVERSION)      = <RVDAT>;
  map {chomp;$_ !~ s/^COLLECTIONS_START//g} @IVERSION;
  close(RVDAT);
}

sub combine_product_version {
  my ($OS_COLLECT_CNT)		= 0;
  my ($REQUIRES_ROOT_CNT)	= 0;
  my ($cur_check_index)		= 0;
  my (@MAIN_DATA_COLLECT);
  my (@MAIN_DATA_NONCOLLECT);
  my ($mcollection_col_fil) 	= File::Spec->catfile("$INPUTDIR", "collections_main.dat.collect");

  copy(File::Spec->catfile("$INPUTDIR", "collections_main.dat"),File::Spec->catfile("$INPUTDIR", "collections_main.dat.collect"));
  `$perl_exe -n -i -e 'if(/^_1.0.0.0.0.0.0.0.0.0-LEVEL/ .. /OS_COLLECT_COUNT/) {print unless /OS_COLLECT_COUNT/}' "$mcollection_col_fil";`;

  open(DAT,'<',File::Spec->catfile("$INPUTDIR", "collections_main.dat")) || die $!;
  while(my $line = <DAT>) {
    chomp($line);
    if($line =~ m/OS_COLLECT_COUNT/) {
      $line =~ s/.*OS_COLLECT_COUNT //g; 
      $line =~ s/ //g;
      $OS_COLLECT_CNT=$line;
    } elsif($line =~ m/REQUIRES_ROOT_COUNT/) {
      $line =~ s/.*REQUIRES_ROOT_COUNT //g; 
      $line =~ s/\s*//g;
      $REQUIRES_ROOT_CNT=$line;
      last;
    } 
  }
  close(DAT);

  my ($mcollection_ncol_fil) 	= File::Spec->catfile("$INPUTDIR", "collections_main.dat.noncollect");
  copy(File::Spec->catfile("$INPUTDIR", "collections_main.dat"),File::Spec->catfile("$INPUTDIR", "collections_main.dat.noncollect"));
  `$perl_exe -n -i -e 'if(/REQUIRES_ROOT_COUNT/ .. /^COLLECTIONS_START/) {print unless /REQUIRES_ROOT_COUNT/ || /COLLECTIONS_START/}' "$mcollection_ncol_fil";`;

  open(DAT,'<',File::Spec->catfile("$INPUTDIR", "collections_main.dat.collect")) || die $!;
  @MAIN_DATA_COLLECT = <DAT>;
  close(DAT);

  open(DAT,'<',File::Spec->catfile("$INPUTDIR", "collections_main.dat.noncollect")) || die $!;
  @MAIN_DATA_NONCOLLECT = <DAT>;
  close(DAT);

  foreach my $mb_db_version(@mb_db_versions) {
    my ($mcollection_vcol_fil) 	= File::Spec->catfile("$INPUTDIR", "collections_$mb_db_version.dat.collect");
    copy(File::Spec->catfile("$INPUTDIR", "collections_$mb_db_version.dat"),File::Spec->catfile("$INPUTDIR/collections_$mb_db_version.dat.collect")); 
    `$perl_exe -n -i -e 'if(/^_1.0.0.0.0.0.0.0.0.0-LEVEL/ .. /OS_COLLECT_COUNT/) {print unless /OS_COLLECT_COUNT/}' "$mcollection_vcol_fil";`;

    my ($t_OS_COLLECT_CNT,$t_REQUIRES_ROOT_CNT) = (0,0);
    open(DAT,'<',File::Spec->catfile("$INPUTDIR", "collections_$mb_db_version.dat")) || die $!;
    while(my $line = <DAT>) {
      chomp($line);
      if($line =~ m/OS_COLLECT_COUNT/) {
        $line =~ s/.*OS_COLLECT_COUNT //g; 
        $line =~ s/\s*//g;
        $t_OS_COLLECT_CNT=$line;
      } elsif($line =~ m/REQUIRES_ROOT_COUNT/) {
        $line =~ s/.*REQUIRES_ROOT_COUNT //g; 
        $line =~ s/\s*//g;
        $t_REQUIRES_ROOT_CNT=$line;
        last;
      } 
    }
    close(DAT);
    $OS_COLLECT_CNT=$OS_COLLECT_CNT+$t_OS_COLLECT_CNT;
    $REQUIRES_ROOT_CNT=$REQUIRES_ROOT_CNT+$t_REQUIRES_ROOT_CNT;

    my ($mcollection_vncol_fil) 	= File::Spec->catfile("$INPUTDIR", "collections_$mb_db_version.dat.noncollect");
    copy(File::Spec->catfile("$INPUTDIR", "collections_$mb_db_version.dat"),File::Spec->catfile("$INPUTDIR", "collections_$mb_db_version.dat.noncollect")); 
    `$perl_exe -n -i -e 'if(/REQUIRES_ROOT_COUNT/ .. /^\$/) {print unless /REQUIRES_ROOT_COUNT/ || /^\$/}' "$mcollection_vncol_fil";`;

    open(DAT,'<',File::Spec->catfile("$INPUTDIR", "collections_$mb_db_version.dat.collect")) || die $!;
    my (@t_MAIN_DATA_COLLECT) = <DAT>;
    close(DAT);

    open(DAT,'<',File::Spec->catfile("$INPUTDIR", "collections_$mb_db_version.dat.noncollect")) || die $!;
    my (@t_MAIN_DATA_NONCOLLECT) = <DAT>;
    close(DAT);

    my (@t_clone_MAIN_DATA_NONCOLLECT) = @t_MAIN_DATA_NONCOLLECT;
    foreach my $lnc_checkid(@t_clone_MAIN_DATA_NONCOLLECT) {
      my ($nc_checkid)	= (split 'CHECK_ID ',$lnc_checkid)[1];
      $nc_checkid	=~ s/\s*//g;
      if (grep {$_ =~ m/CHECK_ID $nc_checkid/} @MAIN_DATA_NONCOLLECT) {
        @t_MAIN_DATA_NONCOLLECT = grep { "$_" ne "$lnc_checkid"} @t_MAIN_DATA_NONCOLLECT;
      } 
    }

    push(@MAIN_DATA_COLLECT,@t_MAIN_DATA_COLLECT);
    push(@MAIN_DATA_NONCOLLECT,@t_MAIN_DATA_NONCOLLECT);
  }

  open(C2DAT,'>>',File::Spec->catfile("$INPUTDIR", "collections.2.dat")) || die $!;

  my ($previous_cindex)	= 'NULL';
  my ($last_collect_row)= 'ROW';
  for my $ROW(@MAIN_DATA_COLLECT) {
    my ($cindex)	= $ROW;
    $cindex     	=~ s/\..*//;
    $cindex		=~ s/_//g;
    $cindex		=~ s/\n//g;

    if("$previous_cindex" ne "$cindex") {
      $cur_check_index++;
    }
    $ROW		=~ s/^_$cindex\./_$cur_check_index\./; 	
    $previous_cindex    = $cindex;

    print C2DAT $ROW;
    $last_collect_row	= $ROW;
  }

  $last_collect_row	= (split '-',$last_collect_row)[0];
  $last_collect_row	=~ s/\n//g;

  print C2DAT "$last_collect_row-OS_COLLECT_COUNT $OS_COLLECT_CNT\n";
  print C2DAT "$last_collect_row-_REQUIRES_ROOT_COUNT $REQUIRES_ROOT_CNT\n";

  $previous_cindex	= 'NULL';  
  for my $ROW(@MAIN_DATA_NONCOLLECT) {
    my ($cindex)	= $ROW;
    $cindex     	=~ s/\..*//;
    $cindex		=~ s/_//g;
    $cindex		=~ s/\n//g;

    if("$previous_cindex" ne "$cindex") {
      $cur_check_index++;
    }
    
    $ROW		=~ s/^_$cindex\./_$cur_check_index\./; 	
    $previous_cindex	= $cindex;

    print C2DAT $ROW;
  }

  my ($mcollection_fil)		= File::Spec->catfile("$INPUTDIR", "collections.dat");
  `$perl_exe -n -i -e 'print if /^COLLECTIONS_START/ .. /^COLLECTIONS _END/' "$mcollection_fil";`;
  open(CDAT,'<',File::Spec->catfile("$INPUTDIR", "collections.dat")) || die $!;
  while(<CDAT>) {
    print C2DAT $_;
  }
  close(CDAT);
  close(C2DAT);

  move(File::Spec->catfile("$INPUTDIR", "collections.2.dat"), File::Spec->catfile("$INPUTDIR", "collections.dat"));
} 

sub housekeeping {
  unlink(File::Spec->catfile("$INPUTDIR", "collections_main.dat"));
  unlink(File::Spec->catfile("$INPUTDIR", "collections_main.dat.collect"));
  unlink(File::Spec->catfile("$INPUTDIR", "collections_main.dat.noncollect"));
  foreach my $mb_db_version(@mb_db_versions) {
    unlink(File::Spec->catfile("$INPUTDIR", "collections_$mb_db_version.dat"));
    unlink(File::Spec->catfile("$INPUTDIR", "collections_$mb_db_version.dat.collect"));
    unlink(File::Spec->catfile("$INPUTDIR", "collections_$mb_db_version.dat.noncollect")); 
  }
}

print_status_bar;
populate_versions;

print_status_bar;
populate_small_collection;

print_status_bar;
combine_product_version;

print_status_bar;
housekeeping;
