# 
# $Header: tfa/src/orachk_py/scripts/load_checks_attributes.pl /main/2 2017/08/11 17:38:17 rojuyal Exp $
#
# load_checks_attributes.pl
# 
# Copyright (c) 2015, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      load_checks_attributes.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    rojuyal     06/25/15 - Creation
# 

use strict;
#use warnings;
use Getopt::Long;
use File::Spec;
use Data::Dumper;

my ($BASH_SCR);
my ($INPUTDIR);
my ($RTEMPDIR);
my ($EXCLUDE_PID_FIL);
my (%RULES_PARAMS);
my ($LAST_CHKID);
my ($CNAME_PRESENT) = 0;
my ($PDEBUG)                    = $ENV{RAT_PDEBUG}||0;

sub usage {
  print "Usage: $0 -b bash_scr -i INPUTDIR -f RTEMPDIR -w exclude_pid_file\n";
  exit;
}

if ( @ARGV == 0 ) { usage(); }

GetOptions(
  "b=s" => \$BASH_SCR,
  "i=s" => \$INPUTDIR,
  "f=s" => \$RTEMPDIR,
  "w=s" => \$EXCLUDE_PID_FIL,
) or usage();

#`touch "$EXCLUDE_PID_FIL"` if (! -e "$EXCLUDE_PID_FIL");
if (! -e "$EXCLUDE_PID_FIL") { open(EFIL,'>',"$EXCLUDE_PID_FIL"); close(EFIL); }

open(EPFIL,'>>', "$EXCLUDE_PID_FIL") || die $!;
print EPFIL "$$\n";
close(EPFIL);

sub print_status_bar {
  printf ". ";
}

sub populate_rules {
  open(RDAT,'<',File::Spec->catfile("$INPUTDIR", "rules.dat")) || die $!;
  my $CHECK_ID;
  while(my $line = <RDAT>) {
    next if ( $line =~ m/^\s*#/ );
    chomp($line);   
    
    if ($line =~ m/^_.*-ALERT_LEVEL/) {
      $CHECK_ID	= (split "-",$line)[0];
      $CHECK_ID =~ s/_//g;

      $line = (split "-ALERT_LEVEL ",$line)[1];  
      $RULES_PARAMS{$CHECK_ID}{'ALERT_LEVEL'}	= "export ALVL=\"$line\"";
    }
    elsif ($line =~ m/^_.*-PASS_MSG/) {
      $line = (split "-PASS_MSG ",$line)[1];  
      $line =~ s/\n\s*$//mgx;
      $line =~ s/"/\\"/g;
      $line =~ s/\$/\\\$/g;
      $line =~ s/`/\\`/g;
      $line =~s/\\\\\"/\\\\\\\"/g;
      $line =~s/\\\\\$/\\\\\\\$/g;

      $RULES_PARAMS{$CHECK_ID}{'PASS_MSG'}	= "export PMSG=\"$line\"";
    }
    elsif ($line =~ m/^_.*-FAIL_MSG/) {
      $line = (split "-FAIL_MSG ",$line)[1];  
      $line =~ s/\n\s*$//mgx;
      $line =~ s/"/\\"/g;
      $line =~ s/\$/\\\$/g;
      $line =~ s/`/\\`/g;
      $line =~s/\\\\\"/\\\\\\\"/g;
      $line =~s/\\\\\$/\\\\\\\$/g;

      $RULES_PARAMS{$CHECK_ID}{'FAIL_MSG'}	= "export FMSG=\"$line\"";
    }
    elsif ($line =~ m/^_.*-CAT/) {
      $line = (split "-CAT ",$line)[1];  
      $RULES_PARAMS{$CHECK_ID}{'CAT'}		= "export CAT=\"$line\"";
    }
    elsif ($line =~ m/^_.*-SUBCAT/) {
      $line = (split "-SUBCAT ",$line)[1];  
      $RULES_PARAMS{$CHECK_ID}{'SUBCAT'}	= "export SUBCAT=\"$line\"";
    }
  }
  close(RDAT);
}

sub unset_checks_attributes {
  open(LCASH,'>', File::Spec->catfile("$RTEMPDIR", "unset_checks_attributes.sh")) || die $!;
  print LCASH "#!$BASH_SCR\n";
  print LCASH "unset COM\n";
  print LCASH "unset TYPE\n";
  print LCASH "unset PARAM_PATH\n";
  print LCASH "unset PARAM\n";
  print LCASH "unset NEEDS_RUNNING\n";
  print LCASH "unset HOME_PATH\n";
  print LCASH "unset SOURCEFIL\n";
  print LCASH "unset ORIG_SOURCEFIL\n";
  print LCASH "unset OUTFILVAL\n";
  print LCASH "unset OUTFILNAM\n";
  print LCASH "unset EXECUTE_ONCE\n";
  print LCASH "unset REQUIRES_ROOT_OS\n";
  print LCASH "unset REQUIREE_ROOT\n";
  print LCASH "unset COLLECTION_NAME\n";
  print LCASH "unset TARGET_VERSION\n";
  print LCASH "unset TARGET_TYPE\n";
  print LCASH "unset SF\n";
  print LCASH "unset COMPONENTS\n";
  print LCASH "unset DATABASE_ROLE\n";
  print LCASH "unset DATABASE_TYPE\n";
  print LCASH "unset DATABASE_MODE\n";
  print LCASH "unset COLLECTION_DIFF_CANDIDATE\n";
  print LCASH "unset LOGIC\n";
  print LCASH "unset AUDIT_CHECK_NAME\n";
  print LCASH "unset IS_BRANCH\n";
  print LCASH "unset COMP\n";
  print LCASH "unset OP\n";
  print LCASH "unset FIELDPOS\n";
  print LCASH "unset ROOT_DEPENDENT\n";
  print LCASH "unset EXADATA_VERSION\n";
  print LCASH "unset ALERT_LEVEL\n";
  print LCASH "unset PASS_MSG\n";
  print LCASH "unset FAIL_MSG\n";
  print LCASH "unset CAT\n";
  print LCASH "unset SUBCAT\n";
  close(LCASH);
}

sub populate_cmd {
  open(REFIL,'<',File::Spec->catfile("$INPUTDIR", "collections.dat")) || die $!;
  my $CHECK_ID;
  while(my $line = <REFIL>) {
    next if ( $line =~ m/^\s*#/ );
    my ($rawline) = $line;
    chomp($line);

    if ($line =~ m/^_.*_COMMAND_START/) {
      if (defined $CHECK_ID) {
	print LCASH "$RULES_PARAMS{$CHECK_ID}{'ALERT_LEVEL'}\n";
	print LCASH "$RULES_PARAMS{$CHECK_ID}{'PASS_MSG'}\n";
	print LCASH "$RULES_PARAMS{$CHECK_ID}{'FAIL_MSG'}\n";
	print LCASH "$RULES_PARAMS{$CHECK_ID}{'CAT'}\n";
	print LCASH "$RULES_PARAMS{$CHECK_ID}{'SUBCAT'}\n";
	if ($CNAME_PRESENT == 0) { print LCASH "export COLLECTION_NAME=\"\"\n"; }
        close(LCASH);
      }

      $CHECK_ID	= (split "-",$line)[0];
      $CHECK_ID =~ s/_//g;
      $LAST_CHKID = $CHECK_ID;
 
      my ($COM);
      while (my $line = <REFIL>) {
	if ( $line =~ m/^_.*_COMMAND_END/ ){
	  last;  
	}
	$COM .= $line;
      }
      chomp($COM);
      $COM =~ s/\n\s*$//mgx;
      $COM =~ s/"/\\"/g;
      $COM =~ s/\$/\\\$/g;
      $COM =~ s/`/\\`/g;
      $COM =~s/\\\\\"/\\\\\\\"/g;
      $COM =~s/\\\\\$/\\\\\\\$/g;

      $CNAME_PRESENT=0;
      open(LCASH,'>', File::Spec->catfile("$INPUTDIR", "${CHECK_ID}_load_checks_attributes.sh")) || die $!;
      print LCASH "#!$BASH_SCR\n";
      print LCASH "export COM=\"$COM\"\n";
    }
    elsif ($line =~ m/^_.*_COMMAND_REPORT_START/) {
      my ($COM_REPORT);
      while (my $line = <REFIL>) {
	if ( $line =~ m/^_.*_COMMAND_REPORT_END/ ){
	  last;  
	}
	$COM_REPORT .= $line;
      }
      chomp($COM_REPORT);
      $COM_REPORT =~ s/\n\s*$//mgx;
      $COM_REPORT =~ s/"/\\"/g;
      $COM_REPORT =~ s/\$/\\\$/g;
      $COM_REPORT =~ s/`/\\`/g;
      $COM_REPORT =~s/\\\\\"/\\\\\\\"/g;
      $COM_REPORT =~s/\\\\\$/\\\\\\\$/g;

      if($COM_REPORT =~ m/\bblank\b/i) { $COM_REPORT=""; }

      print LCASH "export COM_REPORT=\"$COM_REPORT\"\n";
    }
    elsif ($line =~ m/^_.*OS_COMMAND /) {
      if (defined $CHECK_ID) {
	print LCASH "$RULES_PARAMS{$CHECK_ID}{'ALERT_LEVEL'}\n";
	print LCASH "$RULES_PARAMS{$CHECK_ID}{'PASS_MSG'}\n";
	print LCASH "$RULES_PARAMS{$CHECK_ID}{'FAIL_MSG'}\n";
	print LCASH "$RULES_PARAMS{$CHECK_ID}{'CAT'}\n";
	print LCASH "$RULES_PARAMS{$CHECK_ID}{'SUBCAT'}\n";
	if ($CNAME_PRESENT == 0) { print LCASH "export COLLECTION_NAME=\"\"\n"; }
        close(LCASH);
      }
      $CHECK_ID	= (split "-",$line)[0];
      $CHECK_ID =~ s/_//g;
      $LAST_CHKID = $CHECK_ID;
 
      my ($COM);
      $COM = (split "-OS_COMMAND ",$line)[1];   
      $COM =~ s/\n\s*$//mgx;
      $COM =~ s/"/\\"/g;
      $COM =~ s/\$/\\\$/g;
      $COM =~ s/`/\\`/g;
      $COM =~s/\\\\\"/\\\\\\\"/g;
      $COM =~s/\\\\\$/\\\\\\\$/g;

      $CNAME_PRESENT=0;
      open(LCASH,'>', File::Spec->catfile("$INPUTDIR", "${CHECK_ID}_load_checks_attributes.sh")) || die $!;
      print LCASH "#!$BASH_SCR\n";
      print LCASH "export COM=\"$COM\"\n";
    }
    elsif ($line =~ m/^_.*-TYPE/) {
      $line	= (split " ",$line)[1];
      print LCASH "export COMTYPE=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-PARAM_PATH/) {
      $line	= (split " ",$line)[1];
      $line	=~ s/\$/\\\$/g;
      print LCASH "export PARAM_PATH=\"$line\"\n";
      print LCASH "export PARAM=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-NEEDS_RUNNING/) {
      $line	= (split " ",$line)[1];
      print LCASH "export NEEDS_RUNNING=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-HOME_PATH/) {
      $line	= (split " ",$line)[1];
      print LCASH "export HOME_PATH=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-SOURCE_FILE/) {
      $line	= (split " ",$line)[1];
      print LCASH "export SOURCEFIL=\"$line\"\n";
      print LCASH "export ORIG_SOURCEFIL=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-OUTPUT_FILE/) {
      $line	= (split " ",$line)[1];
      print LCASH "export OUTFILVAL=\"$line\"\n";
      print LCASH "export OUTFILNAM=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-EXECUTE_ONCE/) {
      $line	= (split " ",$line)[1];
      print LCASH "export execute_once=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-REQUIRES_ROOT/) {
      $line	= (split " ",$line)[1];
      print LCASH "export REQUIRES_ROOT_OS=\"$line\"\n";
      print LCASH "export REQUIEE_ROOT=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-COLLECTION_NAME/) {
      $line = (split "-COLLECTION_NAME ",$line)[1];
      $line =~ s/"/\\"/g;
      $line =~ s/\$/\\\$/g;
      print LCASH "export COLLECTION_NAME=\"$line\"\n";
      $CNAME_PRESENT=1;
    }
    elsif ($line =~ m/^_.*-TARGET_VERSION/) {
      $line	= (split " ",$line)[1];
      print LCASH "export TARGET_VERSION=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-TARGET_TYPE/) {
      $line	= (split " ",$line)[1];
      print LCASH "export TARGET_TYPE=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-SF/) {
      $line = (split "-SF ",$line)[1];
      print LCASH "export SF=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-COMPONENTS/) {
      $line	= (split " ",$line)[1];
      print LCASH "export check_components=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-DATABASE_ROLE/) {
      $line	= (split " ",$line)[1];
      print LCASH "export check_database_role=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-DATABASE_TYPE/) {
      $line	= (split " ",$line)[1];
      print LCASH "export check_database_type=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-DATABASE_MODE/) {
      $line	= (split " ",$line)[1];
      print LCASH "export check_database_mode=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-COLLECTION_DIFF_CANDIDATE/) {
      $line	= (split " ",$line)[1];
      print LCASH "export COLLECTION_DIFF_CANDIDATE=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-LOGIC/) {
      $line	= (split " ",$line)[1];
      print LCASH "export LOGIC=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-AUDIT_CHECK_NAME/) {
      $line = (split "-AUDIT_CHECK_NAME ",$line)[1];
      $line =~ s/"/\\"/g;
      $line =~ s/\$/\\\$/g;
      print LCASH "export audit_check_name=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-IS_BRANCH/) {
      $line	= (split " ",$line)[1];
      print LCASH "export ISBRANCH=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-COMPARE_VALUE/) {
      $line	= (split " ",$line)[1];
      print LCASH "export COMP=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-OPERATOR/) {
      $line	= (split "-OPERATOR ",$line)[1];
      print LCASH "export OP=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-FIELD_POSITION/) {
      $line	= (split " ",$line)[1];
      print LCASH "export FIELDPOS=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-ROOT_DEPENDENT/) {
      $line	= (split " ",$line)[1];
      print LCASH "export ROOT_DEPENDENT=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-EXADATA_VERSION/) {
      $line	= (split " ",$line)[1];
      print LCASH "export check_exadata_version=\"$line\"\n";
    }
    elsif ($line =~ m/^_.*-PROFILE_ONLY/) {
      $line	= (split " ",$line)[1];
      print LCASH "export PROFILE_ONLY=\"$line\"\n";
    }
  }
  close(REFIL);
}

print_status_bar;

populate_rules;

populate_cmd;

if (defined $LAST_CHKID) {
  open(LCASH,'>>', File::Spec->catfile("$INPUTDIR", "${LAST_CHKID}_load_checks_attributes.sh")) || die $!;
  print LCASH "$RULES_PARAMS{$LAST_CHKID}{'ALERT_LEVEL'}\n";
  print LCASH "$RULES_PARAMS{$LAST_CHKID}{'PASS_MSG'}\n";
  print LCASH "$RULES_PARAMS{$LAST_CHKID}{'FAIL_MSG'}\n";
  print LCASH "$RULES_PARAMS{$LAST_CHKID}{'CAT'}\n";
  print LCASH "$RULES_PARAMS{$LAST_CHKID}{'SUBCAT'}\n";
  if ($CNAME_PRESENT == 0) { print LCASH "export COLLECTION_NAME=\"\"\n"; }
  close(LCASH);
}

print_status_bar;

unset_checks_attributes;


