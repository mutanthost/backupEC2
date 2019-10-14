### profile_collections.pl
###
### Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.
###
###    NAME
###      profile_collections.pl - Rapid collections creation for profile runs
###
###    DESCRIPTION
###      <short description of component this file declares/defines>
###
###    NOTES
###      <other useful comments, qualifications, etc.>
###
###    MODIFIED   (MM/DD/YY)
###    rojuyal     06/10/15 - Creation


use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use File::Spec;

my ($bs_reffil);
my ($INPUTDIR);
my ($targetVesionCheckFil);
my ($upgrade_mode);
my ($SCRIPTPATH);
my ($cindex_collect);
my ($cindex_root);
my ($osCheckIndexNo);
my ($RTEMPDIR);
my (@profileids2run);
my (@profileids2exclude);
my ($EXCLUDE_PID_FIL);
my (@CMDATA);
my (%CMHASH,%rCMHASH);
my (%NETIDS);
my (%CHECK_TYPE,%REQUIRES_ROOT);
my ($OFFLINE);
my ($TEMPDIR);
my ($EXCLUDEFIL);
my ($TMP_EXCLUDEFIL);
my ($is_efile_writable) = 1;
my ($PDEBUG)                    = $ENV{RAT_PDEBUG}||0;
my ($perl_exe)			= $ENV{'RAT_PERLEXE'} || 'perl';

my ($cur_check_index) 		= 1;
my ($selected_collect_count) 	= 0;
my ($selected_root_count) 	= 0;
my ($inprofiles_id,$exprofiles_id);
my ($run_profile)		= 0;
my ($exclude_profile)		= 0;

sub usage {
  print "Usage: $0 -b bs_reffil -i INPUTDIR -t targetVesionCheckFil -r inprofiles_id -e exprofiles_id -u upgrade_mode -s SCRIPTPATH -c cindex_collect -a cindex_root -o osCheckIndexNo -f RTEMPDIR -w exclude_pid_file [-j perltouse]\n";
  exit;
}

if ( @ARGV == 0 ) { usage(); }

GetOptions(
  "b=s" => \$bs_reffil,
  "i=s" => \$INPUTDIR,
  "t=s" => \$targetVesionCheckFil,
  "r=s" => \$inprofiles_id,
  "e=s" => \$exprofiles_id,
  "u=n" => \$upgrade_mode,
  "s=s" => \$SCRIPTPATH,
  "c=n" => \$cindex_collect,
  "a=n" => \$cindex_root,
  "o=n" => \$osCheckIndexNo,
  "f=s" => \$RTEMPDIR,
  "w=s" => \$EXCLUDE_PID_FIL,
  "m=n" => \$OFFLINE,
  "x=s" => \$EXCLUDEFIL,
  "d=s" => \$TMP_EXCLUDEFIL,
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

if (-e $EXCLUDEFIL && ! -w $EXCLUDEFIL) { $is_efile_writable = 0;}

sub print_status_bar {
  printf ". "; 
}

sub populate_ids {
  @profileids2run 	= split(' ' , "$inprofiles_id");
  @profileids2exclude 	= split(' ' , "$exprofiles_id");

  if (defined $inprofiles_id && $inprofiles_id ne "") {
    $run_profile	= 1;
  } elsif (defined $exprofiles_id && $exprofiles_id ne "") {
    $exclude_profile	= 1;
  }

  if (defined $PDEBUG && $PDEBUG == 1) {
    print Dumper(\@profileids2run);
    print Dumper(\@profileids2exclude);
  }
}

sub populate_cmd {
  open(BSREFIL,'<',$bs_reffil) || die $!;
  my $CHECK_ID;
  while(my $line = <BSREFIL>) {
    chomp($line);
 
    if ($line =~ m/^_.*-TYPE/) { 
      $CHECK_ID 		= (split "-",$line)[0];   
      $CHECK_ID			=~ s/_//g;
      $CHECK_TYPE{$CHECK_ID} 	= (split " ",$line)[1];
    }
    if ($line =~ m/^_.*-REQUIRES_ROOT/) { 
      $REQUIRES_ROOT{$CHECK_ID} = (split " ",$line)[1];
    }
  }
  close(BSREFIL);

  open(CMDAT,'<',File::Spec->catfile("$INPUTDIR", "cm.dat")) || die $!;
  my $cmd_cnt = 0;
  while(my $cmline = <CMDAT>) {
    chomp($cmline);
    my ($CHECK_ID)	= (split " ",$cmline)[2];
   
    $CMHASH{$CHECK_ID} 	= $cmline;
    $CMDATA[$cmd_cnt]	= $CHECK_ID;
    $cmd_cnt++;
  }
  close(CMDAT);
  unlink(File::Spec->catfile("$INPUTDIR", "cm.dat"));

  if (defined $PDEBUG && $PDEBUG == 1) {
    print Dumper(\%CMHASH);
    print Dumper(\@CMDATA);
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
  my (%cpNETIDS) = %NETIDS;
  while(my($checkid,$pv_rowline) = each(%cpNETIDS)) {
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

    if (defined $PDEBUG && $PDEBUG == 1) { print Dumper(\%parent_row_ids); }
    for my $rowid(keys %parent_row_ids) {
      if(!grep { $_ =~ /^_$rowid-/ } values %NETIDS) {
	my (@found_row);
        @found_row = grep { $_ =~ /^_$rowid-/ } values %CMHASH;
 	if (defined $found_row[0] && exists $rCMHASH{$found_row[0]}) { 
	  $NETIDS{$rCMHASH{$found_row[0]}} = $found_row[0]; 
          #uncomment this to exclude checks added to correct indexing
	  if ($is_efile_writable == 1) { add_check_in_exefil($found_row[0]); }
	}
      }
    }
  } 
}

print_status_bar;
populate_ids;

print_status_bar;
`$perl_exe -n -i -e 'print if /^COLLECTIONS_START/ .. /^COLLECTIONS _END/' "$bs_reffil";`;
populate_cmd;

print_status_bar;
if ($run_profile == 1) {
  foreach my $aprofile (@profileids2run) {
    open(PRF,'<',File::Spec->catfile("$SCRIPTPATH", ".cgrep", "profiles", "$aprofile.prf")) || die $!;
    while(my $pline = <PRF>) {
      chomp($pline);
      next if ($pline =~ m/^\s*$/);
      my ($cid) = (split '\|', $pline)[0];
    
      if(exists $CMHASH{$cid}) { 
        $NETIDS{$cid} = $CMHASH{$cid}; 

        my ($LEVEL)	= (split "-",$CMHASH{$cid})[1];
        $LEVEL            =~ s/LEVEL//g;
        $LEVEL            =~ s/ //g;

        my (%parent_row_ids);
        my ($pseudo_row_id);
        for (my $i=$LEVEL; $i>1; $i-- ) {
          if(!defined $pseudo_row_id) {
            $pseudo_row_id	= $CMHASH{$cid};
          }
          $pseudo_row_id          =~ s/([0-9]\.)/--$i == 0 ? "0\.":$1/ge;
          $pseudo_row_id          = (split "-",$pseudo_row_id)[0];
          $pseudo_row_id          =~ s/_//g;
          $parent_row_ids{$pseudo_row_id}         = 1;
        }
  	if (defined $PDEBUG && $PDEBUG == 1) { print Dumper(\%parent_row_ids); }
        for my $rowid(keys %parent_row_ids) {
          my ($pchkid)             = grep { $CMHASH{$_} =~ /^_$rowid-/ } keys %CMHASH;
          if (defined $pchkid) { $NETIDS{$pchkid} = $CMHASH{$pchkid}; }
        }
      }
    }
    close(PRF);
  }
}
elsif ($exclude_profile == 1) {
  %rCMHASH = reverse %CMHASH;
  %NETIDS = %CMHASH;

  if (defined $PDEBUG && $PDEBUG == 1) {
    print Dumper(\%rCMHASH);
    print Dumper(\%NETIDS);
  }

  foreach my $aprofile (@profileids2exclude) {
    open(PRF,'<',File::Spec->catfile("$SCRIPTPATH", ".cgrep", "profiles", "$aprofile.prf")) || die $!;
    while(my $pline = <PRF>) {
      chomp($pline);
      my ($cid) = (split '\|', $pline)[0];
 
      if (exists $NETIDS{$cid}) { delete $NETIDS{$cid}; }
    }
    close(PRF);
  }
  include_parent_checkids();
}
elsif ($upgrade_mode >= 2) {
  open(TVC,'<',"$targetVesionCheckFil") || die $!;
  while(my $tline = <TVC>) {
    chomp($tline);
    my ($cid) = (split '\|', $tline)[0];
    if(exists $CMHASH{$cid}) {
      $NETIDS{$cid} = $CMHASH{$cid};

      my ($LEVEL)	= (split "-",$CMHASH{$cid})[1];
      $LEVEL            =~ s/LEVEL//g;
      $LEVEL            =~ s/ //g;

      my (%parent_row_ids);
      my ($pseudo_row_id);
      for (my $i=$LEVEL; $i>1; $i-- ) {
        if(!defined $pseudo_row_id) {
          $pseudo_row_id	= $CMHASH{$cid};
        }
        $pseudo_row_id          =~ s/([0-9]\.)/--$i == 0 ? "0\.":$1/ge;
        $pseudo_row_id          = (split "-",$pseudo_row_id)[0];
        $pseudo_row_id          =~ s/_//g;
        $parent_row_ids{$pseudo_row_id}         = 1;
      }
      if (defined $PDEBUG && $PDEBUG == 1) { print Dumper(\%parent_row_ids); }
      for my $rowid(keys %parent_row_ids) {
        my ($pchkid)             = grep { $CMHASH{$_} =~ /^_$rowid-/ } keys %CMHASH;
        if (defined $pchkid) { $NETIDS{$pchkid} = $CMHASH{$pchkid}; }
      }
    }
  }
  close(TVC);
}

print_status_bar;
my ($COL_DATA_WRITTEN) = 0;
open(CFIL,'>>',File::Spec->catfile("$INPUTDIR", "collections.dat")) || die $!;
for (my $i=0; $i <= $#CMDATA; $i++) {
  my $CHECK_ID = $CMDATA[$i];
  if (! exists $NETIDS{$CHECK_ID}) { next; }

  my $cindex    = $CMHASH{$CHECK_ID};
  if (defined $PDEBUG && $PDEBUG == 1) { print "CHECKID:$CHECK_ID , cindex:$cindex\n"; }
  $cindex       =~ s/\..*//;
  $cindex       =~ s/_//g;

  my ($j) = 0;
  my (@PICK_CHECKIDS);
  $PICK_CHECKIDS[$j] = $CMDATA[$i];
  $j++;
  for (my $k=$i+1; $k <= $#CMDATA; $k++) {
    if ($CMHASH{$CMDATA[$k]} =~ m/^_$cindex\./) {
      $PICK_CHECKIDS[$j] = $CMDATA[$k];
      $j++;
    } else {
      $i = $k-1;
      last;
    }
  }

  if (defined $PDEBUG && $PDEBUG == 1) { print Dumper(\@PICK_CHECKIDS); }
  for(@PICK_CHECKIDS) {
    my ($data) = $CMHASH{$_};
    $data =~ s/^_$cindex\./_$cur_check_index\./;
    print CFIL $data."\n";
  }

  if ($CHECK_TYPE{$CHECK_ID} eq "OS_COLLECT") { $selected_collect_count++; }
  if ($REQUIRES_ROOT{$CHECK_ID} == 1) { $selected_root_count++; }
  $cur_check_index++;

  my ($n) = $i+1;
  if (defined $CMDATA[$n] && $CHECK_TYPE{$CMDATA[$n]} !~ m/_COLLECT/ && $COL_DATA_WRITTEN == 0) {
    print CFIL "_$cur_check_index.0.0.0.0.0.0.0.0.0-OS_COLLECT_COUNT $selected_collect_count\n"; 
    print CFIL "_$cur_check_index.0.0.0.0.0.0.0.0.0-_REQUIRES_ROOT_COUNT $selected_root_count\n"; 
    $osCheckIndexNo	= $cur_check_index;
    $cindex_collect	= 0;
    $cindex_root	= 0;

    $COL_DATA_WRITTEN	= 1;
  }
}

print_status_bar;
open(BSREFIL,'<',"$bs_reffil") || die $!;
print CFIL $_ while(<BSREFIL>);
close(CFIL);
close(BSREFIL);

unlink("$bs_reffil");
unlink("$targetVesionCheckFil");


if ($OFFLINE == 0) {
  $TEMPDIR=$RTEMPDIR;
} else {
  $TEMPDIR=$INPUTDIR;
}
#`touch "$TEMPDIR/.collections.cfg"` if ( ! -e "$TEMPDIR/.collections.cfg");
if (! -e File::Spec->catfile("$TEMPDIR", ".collections.cfg")) { open(TFIL,'>',File::Spec->catfile("$TEMPDIR", ".collections.cfg")); close(TFIL); }

open('PEFIL','>>',File::Spec->catfile("$TEMPDIR", ".collections.cfg")) || die $!;
print PEFIL "osCheckIndexNo=$osCheckIndexNo\n";
print PEFIL "cur_check_index=$cur_check_index\n";
close(PEFIL);

