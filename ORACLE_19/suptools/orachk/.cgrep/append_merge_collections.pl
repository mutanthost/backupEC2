# 
# $Header: tfa/src/orachk_py/scripts/append_merge_collections.pl /main/3 2018/10/18 23:48:27 rojuyal Exp $
#
# append_merge_collections.pl
# 
# Copyright (c) 2015, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      append_merge_collections.pl - Rapid collection creation for multiple DB versions
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    rojuyal     06/10/15 - Creation
# 
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
my ($reffil_old);
my ($is_windows);
my ($old_grp_str);
my ($grp_str);
my ($GREP);
my ($SCRIPTPATH);
my ($cindex_collect);
my ($cindex_root);
my ($osCheckIndexNo);
my ($RTEMPDIR);
my ($EXCLUDE_PID_FIL);
my ($versions);
my (@mb_db_versions);
my (%CHECK_PARAMS);
my (%VERSION_F);
my (%MAIN_HASH);
my (%INSERT);
my (@INSERT);
my ($TEMPDIR);
my ($PDEBUG)			= $ENV{RAT_PDEBUG}||0;
my ($perl_exe)			= $ENV{'RAT_PERLEXE'} || 'perl';

my ($cur_check_index)           = 1;

sub usage {
  print "Usage: $0 -o offline_mode -p what_od -e offline_envfile -d collections dir -i inputdir -w if_windows -a grep -g old_grp_str -c cur_check_index -t tmpdir -v versions -k exclude_pidfile [-j perltouse]\n";
  exit;
}

if ( @ARGV == 0 ) { usage(); }

GetOptions(
  "o=n" => \$OFFLINE,
  "p=s" => \$what_os,
  "e=s" => \$offline_envfile,
  "d=s" => \$reffil_old,
  "i=s" => \$INPUTDIR,
  "w=n" => \$is_windows,
  "a=s" => \$GREP,
  "g=s" => \$old_grp_str,
  "c=n" => \$cur_check_index,
  "t=s" => \$RTEMPDIR,
  "v=s" => \$versions,
  "k=s" => \$EXCLUDE_PID_FIL,
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

  if (defined $PDEBUG && $PDEBUG == 1) { print Dumper(\@mb_db_versions); }

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
    get_winpath('reffil_old');

	if (! defined $ENV{'RAT_CACHE_RUN'}) {
	    open(RVDAT,'>',File::Spec->catfile("$INPUTDIR", "collections_$mb_db_version.dat")) || die $!;
	    print RVDAT `$GREP $grp_str $reffil_old`;
	    close(RVDAT);
	}

    open(RVDAT,'<',File::Spec->catfile("$INPUTDIR", "collections_$mb_db_version.dat")) || die $!;    
    my (@IVERSION) 	= <RVDAT>; 
    map {chomp;$_ =~ s/$grp_str\-//g} @IVERSION;
    close(RVDAT);

    $VERSION_F{$mb_db_version} = \@IVERSION;
  }
  if (defined $PDEBUG && $PDEBUG == 1) { print Dumper(\%VERSION_F); }
}

sub populate_cmd {
  open(REFIL,'<',File::Spec->catfile("$INPUTDIR", "collections.dat")) || die $!;
  my $CHECK_ID;
  while(my $line = <REFIL>) {
    chomp($line);

    if ($line =~ m/^_.*-CHECK_ID/) {
      my ($iCHECK_ID)		= (split " ",$line)[2];
      $MAIN_HASH{$iCHECK_ID} 	= $line;
    }
    if ($line =~ m/-OS_COLLECT_COUNT/) {
      $MAIN_HASH{'OS_COLLECT_COUNT'}		= $line;
    }
    if ($line =~ m/-_REQUIRES_ROOT_COUNT/) {
      $MAIN_HASH{'REQUIRES_ROOT_COUNT'}		= $line;
    }
    if ($line =~ m/^_.*-TYPE/) {
      $CHECK_ID                 		= (split "-",$line)[0];
      $CHECK_ID                 		=~ s/_//g;
      $CHECK_PARAMS{$CHECK_ID}{'TYPE'}		= (split " ",$line)[1];
    }
    if ($line =~ m/^_.*-PARAM_PATH/) {
      $CHECK_PARAMS{$CHECK_ID}{'PARAM_PATH'}	= (split " ",$line)[1];
    }
    if ($line =~ m/^_.*-NEEDS_RUNNING/) {
      $CHECK_PARAMS{$CHECK_ID}{'NEEDS_RUNNING'}	= (split " ",$line)[1];
    }
    if ($line =~ m/^_.*-HOME_PATH/) {
      $CHECK_PARAMS{$CHECK_ID}{'HOME_PATH'}	= (split " ",$line)[1];
    }
    if ($line =~ m/^_.*-SOURCE_FILE/) {
      $CHECK_PARAMS{$CHECK_ID}{'SOURCE_FILE'}	= (split " ",$line)[1];
    }
  }
  close(REFIL);
}

sub insert_version_checks {
  return if (!keys %INSERT);

  my ($mb_db_version)	= shift;

  my (@INSERT_CLONE)	= @INSERT;
  my ($LAST_IDX)	= $#INSERT;
  for (my $i=0; $i <= $#INSERT_CLONE ; $i++) {  

    my ($iCHECKID)	= $INSERT_CLONE[$i];
    my ($iROW)		= $INSERT{$mb_db_version}{$iCHECKID};
    my ($cindex)	= $iROW;
    $cindex     	=~ s/\..*//;
    $cindex		=~ s/_//g;
   
    my ($LEVEL)		= (split "-",$iROW)[2]; 
    $LEVEL		=~ s/LEVEL//g;
    $LEVEL		=~ s/ //g;
 
    if (exists $INSERT{$mb_db_version}{$iCHECKID} && $INSERT{$mb_db_version}{$iCHECKID} =~ m/no-release/i && $INSERT{$mb_db_version}{$iCHECKID} !~ m/\s$mb_db_version/i) {
      $INSERT{$mb_db_version}{$iCHECKID} = $INSERT{$mb_db_version}{$iCHECKID} . " " . $mb_db_version;
    } else { 
      my (%parent_row_ids);
      my ($pseudo_row_id);
      for (my $i=$LEVEL; $i>1; $i-- ) {
        if(!defined $pseudo_row_id) {
          $pseudo_row_id	= $iROW;
        }
        $pseudo_row_id 				=~ s/([0-9]\.)/--$i == 0 ? "0\.":$1/ge;
        $parent_row_ids{$pseudo_row_id}		= 1;
      }
      $parent_row_ids{$iROW}			= 1;

      $cur_check_index++; 
      my (@index_match)				= grep { $_ =~ /^_$cindex\./ } @{$VERSION_F{$mb_db_version}};
      foreach(@index_match) {
        my ($index_checkid)			= (split " ",$_)[2];

        my ($insert_index)			= $_;

	my ($irowid)                            = (split 'LEVEL',$insert_index)[0];
	my (@chk_presence)                      = grep { $_ =~ /$irowid/ } keys %parent_row_ids;

        if(exists $parent_row_ids{$insert_index} || @chk_presence > 0) { 
          $insert_index				=~ s/^_$cindex\./_$cur_check_index\./; 	
          $insert_index				= $insert_index . " " . $mb_db_version;
        } else {
          $insert_index				=~ s/^_$cindex\./_$cur_check_index\./; 	
          $insert_index           		= $insert_index . " " . 'no-release';
        }
        $INSERT{$mb_db_version}{$index_checkid}	= $insert_index;
      }
    }
  }
  my ($grp_str)                 = $what_os.'_'.$mb_db_version.'-';
  if ($OFFLINE eq 1) {
    my ($what_os_offline)       = (split '_', $old_grp_str)[0];
    $grp_str                    = $what_os_offline.'_'.$mb_db_version.'-';
  }
  foreach my $insert_row(keys %{$INSERT{$mb_db_version}}) {
    my ($iROW)                  = $INSERT{$mb_db_version}{$insert_row};
    $iROW                       =~ s/$grp_str//g;
    if(exists $MAIN_HASH{$insert_row}) {
      $MAIN_HASH{$insert_row.'.'.$mb_db_version}= $iROW;
    } else {
      $MAIN_HASH{$insert_row}     		= $iROW;
    }
  }
  undef(@INSERT) 
}

populate_versions;

print_status_bar;
populate_cmd;

foreach my $mb_db_version(@mb_db_versions) {
  my ($k) = 0;
  foreach my $row(@{$VERSION_F{$mb_db_version}})
  {
    my ($ROW)		= $row;
    my ($MERGE_CHECK)	= 0;
    my ($CHECK_ID)	= (split " ",$ROW)[2];

    next if(!defined $CHECK_ID);
 
    my ($PARAM_PATH)	= $CHECK_PARAMS{$CHECK_ID}{'PARAM_PATH'};
    my ($NEEDS_RUNNING)	= $CHECK_PARAMS{$CHECK_ID}{'NEEDS_RUNNING'};
    my ($HOME_PATH)	= $CHECK_PARAMS{$CHECK_ID}{'HOME_PATH'};
    my ($TYPE)		= $CHECK_PARAMS{$CHECK_ID}{'TYPE'};
    my ($SOURCE_FILE)	= $CHECK_PARAMS{$CHECK_ID}{'SOURCE_FILE'};
	
    if ((defined $PARAM_PATH && $PARAM_PATH =~ /^RDBMS/) || (defined $NEEDS_RUNNING && $NEEDS_RUNNING =~ m/^RDBMS/) || (defined $HOME_PATH && $HOME_PATH =~ m/^RDBMS/) || (defined $TYPE && $TYPE =~ m/^SQL/)) {
      $MERGE_CHECK      = 1;
    }
    if ((defined $PARAM_PATH && $PARAM_PATH =~ /^ASM/) || (defined $NEEDS_RUNNING && $NEEDS_RUNNING =~ m/^ASM/) || (defined $HOME_PATH && $HOME_PATH =~ /^ASM/) || (defined $SOURCE_FILE && $SOURCE_FILE =~ /^v_parameter_asm/)) {
      $MERGE_CHECK      = 0;
    }

    next if($MERGE_CHECK == 0);

    if(exists $MAIN_HASH{$CHECK_ID}) {
      $MAIN_HASH{$CHECK_ID} 			= $MAIN_HASH{$CHECK_ID} . " " . $mb_db_version;
    } else {
      if(exists $MAIN_HASH{$CHECK_ID.'.'.$mb_db_version}) {
	$MAIN_HASH{$CHECK_ID.'.'.$mb_db_version}= $MAIN_HASH{$CHECK_ID.'.'.$mb_db_version} . " " . $mb_db_version;
      } else {
        $INSERT{$mb_db_version}{$CHECK_ID}	= $ROW;	
        $INSERT[$k]				= $CHECK_ID;
        $k++;
      }
    }
  }

  if (defined $PDEBUG && $PDEBUG == 1) {
    print Dumper(\%INSERT);
    print Dumper(\@INSERT);
  }
  insert_version_checks("$mb_db_version");
}

my (%cARR);
for(keys %MAIN_HASH) {
  if ($_ =~ /\w+\.\w+/) {
    my ($imCHECKID)     = $_;
    $imCHECKID           =~ s/(\w+)\.(\w+)/$1/g;
    $cARR{$imCHECKID}   = 1;
  }
}
if (defined $PDEBUG && $PDEBUG == 1) { print Dumper(\%cARR); }

for(keys %cARR) {
  my ($mCHECKID)        = $_;

  my ($imVERSIONS)      = $MAIN_HASH{$_};
  $imVERSIONS           =~ s/.*$mCHECKID//g;
  $imVERSIONS           =~ s/^\s*//g;
  $imVERSIONS           =~ s/\s*$//g;

  my ($i)               = 0;
  my (@verSTR)          = ();
  foreach my $mb_db_version(@mb_db_versions) {
    for(@verSTR) {
      $imVERSIONS       =~ s/$_//g;
    }
    $imVERSIONS         =~ s/^\s*//g;
    $imVERSIONS         =~ s/\s*$//g;

    next if(!defined $MAIN_HASH{$mCHECKID.'.'.$mb_db_version});
    my ($mod_str)       = $MAIN_HASH{$mCHECKID.'.'.$mb_db_version};

    $mod_str            =~ s/no-release//g;
    $mod_str            =~ s/^\s*//g;
    $mod_str            =~ s/\s*$//g;
    $mod_str            = $mod_str." ".$imVERSIONS;

    $MAIN_HASH{$mCHECKID.'.'.$mb_db_version}    = $mod_str;

    push(@verSTR,$mb_db_version);
  }
}

if (defined $PDEBUG && $PDEBUG == 1) { print Dumper(\%MAIN_HASH); }

my (%pMAIN_HASH);
my (%OS_COLLECT,%REQUIRES_ROOT);
for(keys %MAIN_HASH) {
  my ($mROW)    = $MAIN_HASH{$_};
  my ($ROWID)   = $mROW;
  $ROWID        = (split "-", $ROWID)[0];
  $ROWID        =~ s/([0-9]+)/sprintf("%04d",$1)/ge;
  if ($MAIN_HASH{$_} =~ m/OS_COLLECT/) {
    $OS_COLLECT{$ROWID}         = $MAIN_HASH{$_};
    next;
  }elsif ($MAIN_HASH{$_} =~ m/REQUIRES_ROOT/) {
    $REQUIRES_ROOT{$ROWID}      = $MAIN_HASH{$_};
    next;
  }
  $pMAIN_HASH{$ROWID}   = $mROW;
}

my ($col_file) = File::Spec->catfile("$INPUTDIR", "collections.dat");
`$perl_exe -n -i -e 'print if /^COLLECTIONS_START/ .. /^COLLECTIONS _END/' "$col_file";`;

open(CDAT,'>',File::Spec->catfile("$INPUTDIR", "collections.2.dat")) || die $!;
foreach(sort keys %pMAIN_HASH) {
  print CDAT $pMAIN_HASH{$_}."\n";
  if(exists $OS_COLLECT{$_}) {
    print CDAT $OS_COLLECT{$_}."\n";
    print CDAT $REQUIRES_ROOT{$_}."\n";
  }
}
close(CDAT);

open(CDAT,'<',File::Spec->catfile("$INPUTDIR", "collections.dat")) || die $!;
open(C2DAT,'>>',File::Spec->catfile("$INPUTDIR", "collections.2.dat")) || die $!;
while(<CDAT>) {
  print C2DAT $_;
}
close(CDAT);
close(C2DAT);

move(File::Spec->catfile("$INPUTDIR", "collections.2.dat"),File::Spec->catfile("$INPUTDIR", "collections.dat"));

if ($OFFLINE == 0) {
  $TEMPDIR=$RTEMPDIR;
} else {
  $TEMPDIR=$INPUTDIR;
}

#`touch "$TEMPDIR/.collections.cfg"` if ( ! -e "$TEMPDIR/.collections.cfg");
if (! -e File::Spec->catfile("$TEMPDIR", ".collections.cfg")) { open(TFIL,'>',File::Spec->catfile("$TEMPDIR", ".collections.cfg")); close(TFIL); }

open('PEFIL','>>',File::Spec->catfile("$TEMPDIR", ".collections.cfg")) || die \$!;
print PEFIL "cur_check_index=$cur_check_index\n";
close(PEFIL);
