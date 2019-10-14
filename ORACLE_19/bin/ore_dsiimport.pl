# 
# $Header: oracler/migration/oreuser/imp/ore_dsiimport.pl /st_oracler_1.5.1.0.1/1 2017/06/20 18:00:39 qinwan Exp $
#
# ore_dsiimport.pl
# 
# Copyright (c) 2014, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      ore_dsiimport.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    qinwan      06/19/17 - remove shebang line
#    gayyappa    07/18/14 - port to windows
#    gayyappa    01/21/14 - Creation
#
use strict;
use warnings;
use File::Copy;
use oracle::oremigcommon  qw( sanityChecks checkcmd checkcmdAndDie);

my $MIGUSER='system';
my $MIGPWD='';
my $ORAHOME='';
my $MIGSRCDIR='';
my $MIGDIR='';
my $MIGSRC_CONNECTSTR='';
my $SQLPLUS='';
my $SQLPLUS_CONSTR='';

sub checkArgs
{
  my $argc= $#ARGV ;     #$argc = @ARGV  will also assign length
  if ( $argc != 1 )
  {
   # print "argc is $argc+1";
    print "Usage is perl ore_dsiimport.pl <connect-identifier> <migration-dir`-name> \n";
    print( "Expect to find <migration-dir-name> directory with files required for import \n");
    die();
  }

  $SQLPLUS_CONSTR=$ARGV[0];
  $MIGDIR=$ARGV[1];
  $MIGSRC_CONNECTSTR=$SQLPLUS_CONSTR;
}

sub importProc
{
  my ($sqlplus, $rqsysexp, $filename, $output);
  my $resp='';
  my $invalid = 1;
  my $exemode = '755';
  my ($tmpexit_in, $tmpexit_log);
  my ($step2_log, $step2_imp, $step2_impbat);
  my ($step3_log, $step3_imp);
  my ($step4_srcsql, $step4_destsql);
  my $fsuff = &oracle::oremigcommon::getScriptSuffix();
  $tmpexit_in=File::Spec->catfile($MIGDIR,'tmpsetup.sql');
  $tmpexit_log=File::Spec->catfile($MIGDIR,'tmpstep1.log');
  open FILE , ">", $tmpexit_in or die $!;
  printf FILE "create directory RQMIG_TEST_DIR as '%s' ;\n", $MIGDIR ;
  print FILE "exit;";
  close FILE;

  $sqlplus = "$SQLPLUS \@$tmpexit_in > $tmpexit_log";

  &oracle::oremigcommon::checkcmdAndDie( $sqlplus, "Step1 failed : check tmpstep1.log");

#step2 : copy of data store inventory from individual schema
  print "****Step2 import of schema with datastoreinventory ****\n";
  $step2_imp = File::Spec->catfile($MIGDIR, "imp_dsi_user.$fsuff");
  $step2_log = File::Spec->catfile($MIGDIR, 'imp_dsi_user.log');
  if ( !( ($^O eq 'MSWin32') || ($^O eq 'dos')) )
  {
    $rqsysexp = "chmod +x $MIGDIR/imp_dsi_user.$fsuff";
    oracle::oremigcommon::checkcmd($rqsysexp, "Step2 failed");
  }
 else
  {
    $step2_impbat = File::Spec->catfile($MIGDIR, 'imp_dsi_user.sh');
    $step2_imp= oracle::oremigcommon::convertShToBat($step2_impbat);
  }
  $rqsysexp = "$step2_imp $MIGUSER $MIGPWD $MIGSRC_CONNECTSTR 2> $step2_log";
  oracle::oremigcommon::checkcmd($rqsysexp, "Step2 failed. check imp_dsi_user.log");

  print "*******Step3 staging datastore metadata *****\n";
  $step3_imp = File::Spec->catfile($MIGSRCDIR, 'dstorestg.sql');
  $step3_log = File::Spec->catfile($MIGDIR, 'dstorestg.log');
  $sqlplus = "$SQLPLUS \@$step3_imp > $step3_log";
  &oracle::oremigcommon::checkcmdAndDie( $sqlplus, "Step3 failed : check dstorestg.log");

  $step4_srcsql= File::Spec->catfile($MIGSRCDIR, 'rqdatastoremig.sql');
  $step4_destsql= File::Spec->catfile($MIGDIR, 'rqdatastoremig.sql');
  copy($step4_srcsql, $step4_destsql);
  $step4_srcsql= File::Spec->catfile($MIGSRCDIR, 'cleanup.sql');
  $step4_destsql= File::Spec->catfile($MIGDIR, 'cleanup.sql');
  copy($step4_srcsql, $step4_destsql);

  print "**********************************************************************************\n";
  print "*****************************IMPORTANT **************************\n";
  print "Check dstorestg.log for errors. Then run the fllowing scripts to complete the import ***\n";
  print "****** Run as sysdba : 1. rqdatastoremig.sql <rquser> ***************\n";
  print "*** To cleanup all the temporary objects created for the migration ***\n";
  print "****** Run as sysdba : 2. cleanup.sql ***********************\n";
  print "*******************************************************\n";
}

&checkArgs(@ARGV);
($SQLPLUS, $MIGPWD, $ORAHOME, $MIGSRCDIR)=&oracle::oremigcommon::sanityChecks($MIGUSER, $SQLPLUS_CONSTR, $MIGDIR);
$MIGSRCDIR=File::Spec->catfile($MIGSRCDIR, 'oreuser');
$MIGSRCDIR=File::Spec->catfile($MIGSRCDIR, 'imp');
&importProc();
                 
