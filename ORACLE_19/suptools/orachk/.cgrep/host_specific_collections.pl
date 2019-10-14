# $Header: tfa/src/orachk_py/scripts/host_specific_collections.pl /main/5 2018/04/24 23:45:26 rojuyal Exp $
#
# host_specific_collections.pl
# 
# Copyright (c) 2015, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      host_specific_collections.pl - filter out checks not matching system components
#
#    DESCRIPTION
#      filter out checks not matching system components
#
#    NOTES
#      filter out checks not matching system components 
#
#    MODIFIED   (MM/DD/YY)
#    rojuyal     07/07/15 - Creation
# 

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use File::Copy;
use File::Spec;

my ($INPUTDIR);
my ($is_windows);
my ($RTEMPDIR);
my ($EXCLUDE_PID_FIL);
my ($HOST);
my ($SYS_COMPONENTS);
my ($LOCALNODE);
my ($RAT_RUNMODE_INTERNAL);
my ($MIXED_VERSIONS);
my (@profileids2run);
my (%PROFILE_HASH);
my ($OFFLINE);
my ($LOGFIL);
my (%CMHASH);
my (%SELECTED_ROWS,@SELECTED_ROWS);
my ($mixed_hardware,$mixed_hardware_v2,$mixed_hardware_x2_2,$mixed_hardware_x3_2,$mixed_hardware_x4_2,$mixed_hardware_x5_2,$mixed_hardware_x6_2, $mixed_hardware_x7_2);
my (%MODULE_HASH,@MATCHED_CHECKS);
my ($fmw_run_comps,$fmw_comps_running);
my ($SCRIPTPATH);
my (%RMV);
my ($CELLIP);
my ($EXCLUDEFIL);
my ($TMP_EXCLUDEFIL);
my ($is_efile_writable) = 1;
my ($upgrade_mode)		= 0;

my ($inprofiles_id,$exprofiles_id);
my ($run_profile)		= 0;
my ($ex_profile)		= 0;
my ($RANDOM_ID_PRESENT)		= 0;
my ($is_fmw_machine)		= 0;
my ($PDEBUG)                    = $ENV{RAT_PDEBUG}||0;
my ($perl_exe)			= $ENV{'RAT_PERLEXE'} || 'perl';

sub usage {
  print "Usage: $0 -i INPUTDIR -w is_windows -t RTEMPDIR -k watchdog.pid -h HOST -c host components -r profileids2run -l localnode -m mode -v storage_versions -o OFFLINE  -a is_fmw_machine -e fmw_run_comps -g fmw_comps_running -s SCRIPTPATH -b cellip -x excludefil -x exclude_profile -d tmp_excludefile -u upgrade_mode [-j perltouse]\n";
  exit;
}

if ( @ARGV == 0 ) { usage(); }

GetOptions(
  "i=s" => \$INPUTDIR,
  "w=n" => \$is_windows,
  "t=s" => \$RTEMPDIR,
  "k=s" => \$EXCLUDE_PID_FIL,
  "h=s" => \$HOST,
  "c=s" => \$SYS_COMPONENTS,
  "r=s" => \$inprofiles_id,
  "l=s" => \$LOCALNODE,
  "m=s" => \$RAT_RUNMODE_INTERNAL,
  "v=s" => \$MIXED_VERSIONS,
  "o=n" => \$OFFLINE,
  "f=s" => \$LOGFIL,
  "a=s" => \$is_fmw_machine,
  "e=s" => \$fmw_run_comps,
  "g=s" => \$fmw_comps_running,
  "s=s" => \$SCRIPTPATH,
  "b=s" => \$CELLIP,
  "x=s" => \$EXCLUDEFIL,
  "z=s" => \$ex_profile,
  "d=s" => \$TMP_EXCLUDEFIL,
  "u=n" => \$upgrade_mode,
  "j:s" => \$perl_exe
) or usage();

if ($OFFLINE == 0) {
  #`touch "$EXCLUDE_PID_FIL"` if (! -e "$EXCLUDE_PID_FIL");
  if (! -e "$EXCLUDE_PID_FIL") { open(EFIL,'>',"$EXCLUDE_PID_FIL"); close(EFIL); }
  
  open(EPFIL,'>>', "$EXCLUDE_PID_FIL") || die $!;
  print EPFIL "$$\n";
  close(EPFIL);
}

sub print_status_bar {
  printf ". "; 
}

sub populate_ids {
  @profileids2run       = split(' ' , "$inprofiles_id");

  if (defined $inprofiles_id && $inprofiles_id ne "") { 
    foreach my $aprofile (@profileids2run) {
      if ($aprofile =~ m/\bRANDOMID\b/i) { $RANDOM_ID_PRESENT = 1; }
      next if (defined $RANDOM_ID_PRESENT && $RANDOM_ID_PRESENT == 1);
      $run_profile        = 1;
      open(PRF,'<',File::Spec->catfile("$SCRIPTPATH", ".cgrep", "profiles", "$aprofile.prf")) || die $!;
      while(my $pline = <PRF>) {
        chomp($pline);
        next if($pline =~ m/^\s*$/);
        my ($cid) = (split '\|', $pline)[0];
        $PROFILE_HASH{$cid}	= 1;
      }
      close(PRF);
    }
  }

  my (@mixed_versions)	= split(" ", $MIXED_VERSIONS);
  $mixed_hardware	= $mixed_versions[0];
  $mixed_hardware_v2	= $mixed_versions[1];
  $mixed_hardware_x2_2	= $mixed_versions[2];
  $mixed_hardware_x3_2	= $mixed_versions[3];
  $mixed_hardware_x4_2	= $mixed_versions[4];
  $mixed_hardware_x5_2	= $mixed_versions[5];
  $mixed_hardware_x6_2	= $mixed_versions[6];
  $mixed_hardware_x7_2	= $mixed_versions[7];
}

sub backup_files {
  copy(File::Spec->catfile("$INPUTDIR", "collections.dat"),File::Spec->catfile("$INPUTDIR", "collections.dat.beforemodule"));
  copy(File::Spec->catfile("$INPUTDIR", "collections.dat"),File::Spec->catfile("$INPUTDIR", "collections.dat.attributes"));

  my ($collection_attr_fil) = File::Spec->catfile("$INPUTDIR", "collections.dat.attributes");
  `$perl_exe -n -i.bak -e "print if /^COLLECTIONS_START/ .. /^COLLECTIONS _END/" "$collection_attr_fil"`;
}

sub populate_cmd {
  open(REFIL, '<' , File::Spec->catfile("$INPUTDIR", "collections.dat")) || die $!;
  my ($CHECK_ID);
  my ($ROWIDS_line) 	= 1;
  my ($i)		= 0;
  while(my $line = <REFIL>) {
    next if ( $line =~ m/^\s*#/ || $line =~ m/^\s*$/ );
    my ($rawline) = $line;
    chomp($line);

    $ROWIDS_line = 0 if($line =~ m/COLLECTIONS_START/);

    if ($ROWIDS_line == 1) {
      my ($ROWID) 		= (split "-", $line)[0];
      $ROWID			=~ s/_//g;

      if ($line =~ m/CHECK_ID/) {
        my ($iCHECK_ID)		= (split "CHECK_ID" , $line)[1];
        $iCHECK_ID		= (split " ", $iCHECK_ID)[0];
        $RMV{$iCHECK_ID}		= (split "$iCHECK_ID", $line)[1] || "";
        $RMV{$iCHECK_ID}		=~ s/^\s*//g;
        $RMV{$iCHECK_ID}		=~ s/\s*$//g;
 
        $SELECTED_ROWS{$line}	= $iCHECK_ID; 
      } else {
        $SELECTED_ROWS{$line}	= 1; 
      }

      $SELECTED_ROWS[$i]	= $line;
      $i++;
  
      next;
    }

    if ($line =~ m/^_.*_COMMAND_START/) {
      $CHECK_ID	= (split "-",$line)[0];
      $CHECK_ID =~ s/_//g;
    }
    elsif ($line =~ m/^_.*OS_COMMAND /) {
      $CHECK_ID	= (split "-",$line)[0];
      $CHECK_ID =~ s/_//g;
    }
    elsif ($line =~ m/^_.*-TYPE/) {
      $line	= (split " ",$line)[1];
      $CMHASH{$CHECK_ID}{'TYPE'}		= $line;
    }
    elsif ($line =~ m/^_.*-NEEDS_RUNNING/) {
      $line	= (split " ",$line)[1];
      $CMHASH{$CHECK_ID}{'NEEDS_RUNNING'}	= $line;
    }
    elsif ($line =~ m/^_.*-COMPONENTS/) { 
      $line	= (split " ",$line)[1];
      $CMHASH{$CHECK_ID}{'COMPONENTS'}		= $line;
    }
    elsif ($line =~ m/^_.*-REQUIRES_ROOT/) {
      $line	= (split " ",$line)[1];
      $CMHASH{$CHECK_ID}{'REQUIRES_ROOT'}	= $line;
    }
  }
}

sub add_check_in_exefil {
  my ($pv_foundrow) = shift;

  my ($pv_CHECKID)		= (split "CHECK_ID", $pv_foundrow)[1];
  $pv_CHECKID			= (split " ",$pv_CHECKID)[0];
  $pv_CHECKID			=~ s/\s*//g;

  if (defined $pv_CHECKID) {
    open(EFIL,'>>',"$EXCLUDEFIL") || die $!;
    print EFIL "$pv_CHECKID\n";
    close(EFIL);

    open(EFIL,'>>',"$TMP_EXCLUDEFIL") || die $!;
    print EFIL "$pv_CHECKID\n";
    close(EFIL);
  }
}

sub include_parent_checkids {
  my ($pv_rowline)	= shift;
  my ($pv_CHECK_ID)	= shift;
  my ($pv_mcnt)		= shift;

  my ($LEVEL)		= (split "-",$pv_rowline)[1];
  $LEVEL            	=~ s/LEVEL//g;
  $LEVEL            	=~ s/ //g;

  my (%parent_row_ids);
  my ($pseudo_row_id);
  my ($pv_cindex);

  $pseudo_row_id = $pv_rowline;
  $pv_cindex = (split "-",$pv_rowline)[0];
  $pv_cindex =~ s/_//g; 

  my (@chk_digits) = split(/\./,$pv_cindex);

  for (my $i=1; $i<$LEVEL; $i++) {
    my ($pre_append,$pos_append)= ("","");
    for(my $l=0; $l<$i; $l++) { $pre_append .= "$chk_digits[$l]."; }
    for(my $k=$i; $k<9; $k++) { $pos_append .= ".0"; }
    for (my $j=0; $j<=$chk_digits[$i]-1; $j++) { $parent_row_ids{$pre_append.$j.$pos_append} = 1; }
  }

  for my $rowid(sort keys %parent_row_ids) {
    if(!grep { $_ =~ /^_$rowid-/ } @MATCHED_CHECKS) {
	my (@found_row);
	@found_row = grep { $_ =~ /^_$rowid-/ } @SELECTED_ROWS;
	if (defined $found_row[0]) {
	  $MATCHED_CHECKS[$pv_mcnt++]  = $found_row[0];
	  $MODULE_HASH{$found_row[0]}     = 1;
	  #uncomment this to exclude checks added to correct indexing
	  if ($is_efile_writable == 1) { add_check_in_exefil($found_row[0]); }
	}
    }
  }
  return $pv_mcnt;
}

sub matched_components_checks {
  my ($current_cindex)	= 1;
  my ($os_collect_row,$requires_root_row);
  my ($SKIP_THIS_CHECK) = 0;

  my ($mcnt) = 0;
  foreach my $rowline(@SELECTED_ROWS) {
    $SKIP_THIS_CHECK = 0;

    my $LWRITE = 0;
    if ($rowline =~ m/-OS_COLLECT_COUNT/) {
      $os_collect_row		= $rowline;
      $MATCHED_CHECKS[$mcnt++]	= $rowline;
      $MODULE_HASH{$rowline}	= 1;
      next; 
    }
    if ($rowline =~ m/-_REQUIRES_ROOT_COUNT/) {
      $requires_root_row	= $rowline;
      $MATCHED_CHECKS[$mcnt++]	= $rowline;
      $MODULE_HASH{$rowline}	= 1;
      next;
    }

    my ($CHECK_ID)		= (split "CHECK_ID", $rowline)[1];
    $CHECK_ID			= (split " ",$CHECK_ID)[0];
    $CHECK_ID			=~ s/\s*//g;
    my ($OLD_COMPONENTS)	= $SYS_COMPONENTS;

    my ($NEEDS_RUNNING)		= $CMHASH{$CHECK_ID}{'NEEDS_RUNNING'} || "";

    if ($RAT_RUNMODE_INTERNAL eq "slave" && defined $NEEDS_RUNNING && $NEEDS_RUNNING eq "STORAGE_CELL") { next; }
    if ($RAT_RUNMODE_INTERNAL eq "slave" && defined $NEEDS_RUNNING && $NEEDS_RUNNING eq "SWITCH") { next; } 

    if (defined $mixed_hardware && $mixed_hardware ne "" && $mixed_hardware >= 1 && $CMHASH{$CHECK_ID}{'TYPE'} eq "OS_OUT_CHECK" && defined $NEEDS_RUNNING && $NEEDS_RUNNING eq "STORAGE_CELL" && "$HOST" eq "$LOCALNODE" && $RAT_RUNMODE_INTERNAL eq "master") {
      if (defined $mixed_hardware_v2 && $mixed_hardware_v2 ne "" && $mixed_hardware_v2 >= 1 && $CMHASH{$CHECK_ID}{'COMPONENTS'} =~ m/\bDBM\b/i && $CMHASH{$CHECK_ID}{'COMPONENTS'} !~ m/\bEXADATA\b/i) {
	$OLD_COMPONENTS .= ":EXADATA";
      }
      if (defined $mixed_hardware_x2_2 && $mixed_hardware_x2_2 ne "" && $mixed_hardware_x2_2 >= 1 && $CMHASH{$CHECK_ID}{'COMPONENTS'} =~ m/\bX2-2\b/i && $SYS_COMPONENTS !~ m/\bX2-2\b/i) {
	$OLD_COMPONENTS .= ":X2-2";
      }
      if (defined $mixed_hardware_x3_2 && $mixed_hardware_x3_2 ne "" && $mixed_hardware_x3_2 >= 1 && $CMHASH{$CHECK_ID}{'COMPONENTS'} =~ m/\bX3-2\b/i && $SYS_COMPONENTS !~ m/\bX3-2\b/i) { 
	$OLD_COMPONENTS .= ":X3-2";
      } 
      if (defined $mixed_hardware_x4_2 && $mixed_hardware_x4_2 ne "" && $mixed_hardware_x4_2 >= 1 && $CMHASH{$CHECK_ID}{'COMPONENTS'} =~ m/\bX4-2\b/i && $SYS_COMPONENTS !~ m/\bX4-2\b/i) { 
	$OLD_COMPONENTS .= ":X4-2";
      }
      if (defined $mixed_hardware_x5_2 && $mixed_hardware_x5_2 ne "" && $mixed_hardware_x5_2 >= 1 && $CMHASH{$CHECK_ID}{'COMPONENTS'} =~ m/\bX5-2\b/i && $SYS_COMPONENTS !~ m/\bX5-2\b/i) { 
	$OLD_COMPONENTS .= ":X5-2";
      }
      if (defined $mixed_hardware_x6_2 && $mixed_hardware_x6_2 ne "" && $mixed_hardware_x6_2 >= 1 && $CMHASH{$CHECK_ID}{'COMPONENTS'} =~ m/\bX6-2\b/i && $SYS_COMPONENTS !~ m/\bX6-2\b/i) { 
	$OLD_COMPONENTS .= ":X6-2";
      }
      if (defined $mixed_hardware_x7_2 && $mixed_hardware_x7_2 ne "" && $mixed_hardware_x7_2 >= 1 && $CMHASH{$CHECK_ID}{'COMPONENTS'} =~ m/\bX7-2\b/i && $SYS_COMPONENTS !~ m/\bX7-2\b/i) { 
	$OLD_COMPONENTS .= ":X7-2";
      }
    }  
    elsif (defined $mixed_hardware && $mixed_hardware ne "" && $mixed_hardware >= 1 && defined $NEEDS_RUNNING && $NEEDS_RUNNING eq "STORAGE_CELL" && "$HOST" eq "$LOCALNODE" && $RAT_RUNMODE_INTERNAL eq "master" && defined $mixed_hardware_v2 && $mixed_hardware_v2 ne "" && $mixed_hardware_v2 >= 1 && $CMHASH{$CHECK_ID}{'COMPONENTS'} =~ m/\bDBM\b/i && $CMHASH{$CHECK_ID}{'COMPONENTS'} !~ m/\bEXADATA\b/i) {
      $OLD_COMPONENTS .= ":EXADATA";
    }

    if ($OLD_COMPONENTS =~ m/\bEXADATA\b/i && $CMHASH{$CHECK_ID}{'COMPONENTS'} =~ m/\bDBM\b/) {
      my ($HOLD_CHECK_COMPONENTS)	= $CMHASH{$CHECK_ID}{'COMPONENTS'};
      $HOLD_CHECK_COMPONENTS		=~ s/:/ /g;
      $HOLD_CHECK_COMPONENTS		=~ s/DBM/EXADATA/g;
      $HOLD_CHECK_COMPONENTS		=~ s/ /:/g;
      $CMHASH{$CHECK_ID}{'COMPONENTS'}	= $HOLD_CHECK_COMPONENTS;
    }
    
    if(!defined $CMHASH{$CHECK_ID}{'COMPONENTS'} or $CMHASH{$CHECK_ID}{'COMPONENTS'} eq "") {
      next;
      print LOGFIL "Skipping check (id $CHECK_ID) because it is not applicable for this system(Host Components:$SYS_COMPONENTS Check Components:$CMHASH{$CHECK_ID}{'COMPONENTS'})\n";
    } 

    my (@CHECK_COMPONENTS)		= split(":", $CMHASH{$CHECK_ID}{'COMPONENTS'});
    my (%CHECK_COMPONENTS)		= map{ $_ => 1 } @CHECK_COMPONENTS;
    
    my (@SYS_COMPONENTS)		= split(":", $OLD_COMPONENTS);
    my ($COMP_MATCH) = 0;
    foreach(@SYS_COMPONENTS) {
      if (defined $CHECK_COMPONENTS{$_} || defined $CHECK_COMPONENTS{uc($_)}) { 
	$COMP_MATCH = 1;
        last;
      }
    }
    if ($COMP_MATCH == 0) { 
      $SKIP_THIS_CHECK = 1; 
    } else {
      $SKIP_THIS_CHECK = 0;
    }

    if (defined $is_fmw_machine && $is_fmw_machine ne "" && $is_fmw_machine == 1) {
      $LWRITE = 1;
      if (! defined $NEEDS_RUNNING) { $NEEDS_RUNNING=""; }

      if ( $NEEDS_RUNNING ne "RDBMS" ) {
        print LOGFIL "Checking CHECK ID $CHECK_ID because NEEDS_RUNNING=$NEEDS_RUNNING and Selected Components=$fmw_run_comps\n";

        if (defined $fmw_run_comps && $fmw_run_comps ne "" && $fmw_run_comps !~ m/\b$NEEDS_RUNNING\b/i) {
          $LWRITE = 1;
          print LOGFIL "Skipping CHECK ID $CHECK_ID because NEEDS_RUNNING=$NEEDS_RUNNING and Selected Components=$fmw_run_comps\n";
          $SKIP_THIS_CHECK=1;
        }

        if (defined $NEEDS_RUNNING && $NEEDS_RUNNING ne "" && $NEEDS_RUNNING ne "UNSPECIFIED" && $fmw_comps_running !~ m/\b$NEEDS_RUNNING\b/i) {
          $LWRITE = 1;
          print LOGFIL "Skipping CHECK ID $CHECK_ID because NEEDS_RUNNING=$NEEDS_RUNNING and Selected Components=$fmw_run_comps and running components in $HOST = $fmw_comps_running\n";
          $SKIP_THIS_CHECK=1;
        }
      }
    }

    if($run_profile eq "1") {
      my ($in_profile)	= 0;
      
      if($RANDOM_ID_PRESENT == 1) {
	$in_profile = 1;
      } else { 
	if(defined $PROFILE_HASH{$CHECK_ID}) { $in_profile = 1; } 
      }
      if($in_profile == 0) {
	$SKIP_THIS_CHECK=1;
        $LWRITE = 1;
        print LOGFIL "Skipping check (id $CHECK_ID) because its not in profile\n";
      }
    } 

    if(defined $RMV{$CHECK_ID} && $RMV{$CHECK_ID} eq "no-release") { $SKIP_THIS_CHECK = 1; }

    if ($SKIP_THIS_CHECK == 0) { 
      $mcnt = include_parent_checkids("$rowline","$CHECK_ID",$mcnt);
      $MATCHED_CHECKS[$mcnt++]	= $rowline;
      $MODULE_HASH{$rowline}	= $CHECK_ID; 
    } else {
      if($LWRITE == 0) {
        print LOGFIL "Skipping check (id $CHECK_ID) because it is not applicable for this system(Host Components:$SYS_COMPONENTS Check Components:$CMHASH{$CHECK_ID}{'COMPONENTS'})\n";
      } 
    }
  }
}

sub print_filtered_collections {
  my $OS_COLLECT_COUNT    = 0;
  my $REQUIRES_ROOT_COUNT = 0;
  foreach(@MATCHED_CHECKS) {
    if(defined $CMHASH{$MODULE_HASH{$_}}{'TYPE'} && $CMHASH{$MODULE_HASH{$_}}{'TYPE'} ne "" && $CMHASH{$MODULE_HASH{$_}}{'TYPE'} eq "OS_COLLECT") { $OS_COLLECT_COUNT++; };
    if(defined $CMHASH{$MODULE_HASH{$_}}{'REQUIRES_ROOT'} && $CMHASH{$MODULE_HASH{$_}}{'REQUIRES_ROOT'} ne "" && $CMHASH{$MODULE_HASH{$_}}{'REQUIRES_ROOT'} == 1) { $REQUIRES_ROOT_COUNT++; };
  }

  open(REFIL,'>',File::Spec->catfile("$INPUTDIR", "collections.dat")) || die $!;
  my ($cur_check_index) = 1;
  for (my $i=0; $i <= $#MATCHED_CHECKS ; $i++) {  
    my ($cindex)        = $MATCHED_CHECKS[$i];
    $cindex             =~ s/\..*//;
    $cindex             =~ s/_//g;

    my ($nROW)		= $MATCHED_CHECKS[$i];
    $nROW 		=~ s/^_$cindex\./_$cur_check_index\./;
    if ($nROW =~ m/OS_COLLECT_COUNT/) {
      $nROW		=~ s/(_.*-OS_COLLECT_COUNT).*$/$1 $OS_COLLECT_COUNT/g; 
    }
    if ($nROW =~ m/REQUIRES_ROOT_COUNT/) {
      $nROW		=~ s/(_.*-REQUIRES_ROOT_COUNT).*$/$1 $REQUIRES_ROOT_COUNT/g; 
    }
    print REFIL "$nROW\n";

    my $j=$i+1;
    if($run_profile eq "1" || $ex_profile eq "1" || $upgrade_mode >= 2) {
      if (defined $MATCHED_CHECKS[$j] && $MATCHED_CHECKS[$j] ne "") {
        my ($ncindex)       = $MATCHED_CHECKS[$j];
        $ncindex            =~ s/\..*//;
        $ncindex            =~ s/_//g;
        if("$cindex" ne "$ncindex") { $cur_check_index++; }
      }
    } else {
      if (defined $MATCHED_CHECKS[$j] && $MATCHED_CHECKS[$j] ne "" && $MATCHED_CHECKS[$j] !~ m/OS_COLLECT_COUNT|REQUIRES_ROOT_COUNT/) {
        my ($ncindex)       = $MATCHED_CHECKS[$j];
        $ncindex            =~ s/\..*//;
        $ncindex            =~ s/_//g;
        if("$cindex" ne "$ncindex") { $cur_check_index++; }
      }
    }
  }  

  open(CDAT,'<',File::Spec->catfile("$INPUTDIR", "collections.dat.attributes")) || die $!;
  while(<CDAT>) {
    print REFIL $_;
  }
  close(CDAT);
  close(REFIL);

  unlink(File::Spec->catfile("$INPUTDIR", "collections.dat.attributes")); 
}

open(LOGFIL,'>>',$LOGFIL) || die $!;

if (-e $EXCLUDEFIL) {
  if (! -w $EXCLUDEFIL) { 
    $is_efile_writable = 0;
    print LOGFIL "$EXCLUDEFIL exist but not writable";
  }
}

print_status_bar;
populate_ids;

print_status_bar;
backup_files

print_status_bar;
populate_cmd;

print_status_bar;
matched_components_checks;

print_status_bar;
print_filtered_collections;
print "\n";

close(LOGFIL);
