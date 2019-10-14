# 
# $Header: oracler/migration/imp/ore_destimport.pl /st_oracler_1.5.1.0.1/1 2017/06/20 18:00:39 qinwan Exp $
#
# ore_destimport.pl
# 
# Copyright (c) 2014, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      ore_destimport.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    qinwan      06/19/17 - remove shebang line
#    qinwan      06/26/15 - update refobjID after import
#    gayyappa    07/18/14 - porting for windows
#    gayyappa    01/20/14 - Creation
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
    print "Usage is perl ore_destimport.pl <connect-identifier> <migration-dir`-name> \n";
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
  my $found = 0;
  my ($tmpfile, $convname);
  my ($tmpexit_in, $tmpexit_log);
  my ($step2_rqsys, $step2_log, $step2_imp, $step2_implog, $step2_rqsyslog);
  my ($step3_rqsys, $step3_rqsyslog, $step3_log, $step3_imp);
  my ($step4_log, $step4_imp, $step4_srcsql, $step4_destsql, $step4_logfiles);
  my $fsuff = &oracle::oremigcommon::getScriptSuffix();
  ##generate required .bat files from .sh files
  if ( ($^O eq 'MSWin32') || ($^O eq 'dos'))
  {
    $tmpfile = File::Spec->catfile($MIGSRCDIR, 'rqsys_imp.sh');
    $convname= &oracle::oremigcommon::convertShToBat($tmpfile);
    $tmpfile= File::Spec->catfile($MIGSRCDIR,'rqsystab_imp.sh');
    $convname= &oracle::oremigcommon::convertShToBat($tmpfile);
    $tmpfile= File::Spec->catfile($MIGSRCDIR, 'rqscript_imp.sh');
    $convname= &oracle::oremigcommon::convertShToBat($tmpfile);
    $tmpfile = File::Spec->catfile($MIGDIR, 'imp_ore_user.sh');
    $convname= &oracle::oremigcommon::convertShToBat($tmpfile);
  }

  $tmpexit_in=File::Spec->catfile($MIGDIR,'tmpsetup.sql');
  $tmpexit_log=File::Spec->catfile($MIGDIR,'tmpstep1.log');
  open FILE , ">", $tmpexit_in or die $!;
  printf FILE "create directory RQMIG_TEST_DIR as '%s' ;\n", $MIGDIR ;
  print FILE "exit;";
  close FILE;

  $sqlplus = "$SQLPLUS \@$tmpexit_in > $tmpexit_log";
  &oracle::oremigcommon::checkcmdAndDie( $sqlplus, "Step1 failed : $! \n Please check tmpstep1.log");


# step 2: import rqsys if it does not exists
# otherwise import only rqsys.rq$dataXXX table data only
  print "****Step2 import of rqsys ***\n";
  $step2_rqsys= File::Spec->catfile($MIGSRCDIR,'rqsysquery.sql');
  $step2_log= File::Spec->catfile($MIGDIR,'tmps2rqsysq.log');

  $sqlplus = "$SQLPLUS \@$step2_rqsys > $step2_log";
  &oracle::oremigcommon::checkcmdAndDie( $sqlplus, "Step2 failed : $! \n Please check tmps2rqsysq.log");
  ($found) = oracle::oremigcommon::findoraerr($step2_log);
  if( $found != 0)
  { 
    print "rqsys schema does not exist, creating rqsys from dmp file";
    $step2_imp= File::Spec->catfile($MIGSRCDIR,"rqsys_imp.$fsuff");
    $step2_implog= File::Spec->catfile($MIGDIR,'rqsys_imp.log');
    $rqsysexp = "$step2_imp $MIGUSER $MIGPWD $MIGSRC_CONNECTSTR 2>$step2_implog";
    oracle::oremigcommon::checkcmdAndDie($rqsysexp, "Step2 failed");
  } 
  else
  {
    print "rqsys schmea EXISTS. importing only datastore related data \n";
    print "We will first truncate the data in rq\$datastoreXXX tables from rqsys and then populate from source dump files\n";
    print "****** ALL existing datastores on this database will be removed ********\n\n\n"; 
    while ( $invalid )
    {
      print "Do you wish to continue? Type yes or no\n";
      $resp = <STDIN>;
      chomp $resp;
      if( $resp eq "yes")
      {
        $invalid = 0;
      }
      elsif( $resp eq "no")
      {
        die("Termintaing migration \n");
      }
      else
      {
        print("Please answer yes or no\n");
      }
    }
    $step2_rqsys= File::Spec->catfile($MIGSRCDIR,'rqsystab_prep.sql');
    $step2_rqsyslog= File::Spec->catfile($MIGDIR,'tmps2rqsysprep.log');
    $sqlplus = "$SQLPLUS \@$step2_rqsys > $step2_rqsyslog";
    oracle::oremigcommon::checkcmdAndDie($sqlplus, "Step 2 failed: check tmps2rqsysprep.log");
    $step2_rqsys= File::Spec->catfile($MIGSRCDIR,"rqsystab_imp.$fsuff");
    $step2_rqsyslog= File::Spec->catfile($MIGDIR,'tmps2rqsystab_imp.log');
    $rqsysexp = "$step2_rqsys $MIGUSER $MIGPWD $MIGSRC_CONNECTSTR 2> $step2_rqsyslog";
    oracle::oremigcommon::checkcmdAndDie($rqsysexp, "Step 2 failed: check tmps2rqsystab_imp.log");
    $step2_rqsys= File::Spec->catfile($MIGSRCDIR,'rqsys_sequpdate.sql');
    $step2_rqsyslog= File::Spec->catfile($MIGDIR,'tmps2rqsyssequpd.log');
    $sqlplus = "$SQLPLUS \@$step2_rqsys > $step2_rqsyslog";
    oracle::oremigcommon::checkcmd($sqlplus, "Step 2 failed: check tmps2rqsyssequpd.log");
  }

#step3 : copy of data store inventory from individual schema
  print "****Step3 import of schema with datastoreinventory ****\n";
  if ( !( ($^O eq 'MSWin32') || ($^O eq 'dos')) )
  {
    $rqsysexp = "chmod +x $MIGDIR/imp_ore_user.sh";
    oracle::oremigcommon::checkcmd($rqsysexp, "Step3 failed");
  } 
  $step3_imp = File::Spec->catfile($MIGDIR, "imp_ore_user.$fsuff");
  $step3_log = File::Spec->catfile($MIGDIR, 'tmps3imp_ore_user.log');
  $rqsysexp = "$step3_imp $MIGUSER $MIGPWD $MIGSRC_CONNECTSTR 2> $step3_log";
  oracle::oremigcommon::checkcmd($rqsysexp, "Step3 failed. check tmps3imp_ore_user.log"); 
  $step3_rqsys= File::Spec->catfile($MIGSRCDIR,'rqsys_refidupdate.sql');
  $step3_rqsyslog= File::Spec->catfile($MIGDIR,'tmps3rqsysrefidupd.log');
  $sqlplus = "$SQLPLUS \@$step3_rqsys > $step3_rqsyslog";
  oracle::oremigcommon::checkcmd($sqlplus, "Step 3 failed: check tmps3rqsysrefidupd.log");

#Step4 : import rqscript data
  print "****Step4 import rqscript *****\n";
  $step4_imp = File::Spec->catfile($MIGSRCDIR, "rqscript_imp.$fsuff");
  $step4_log = File::Spec->catfile($MIGDIR, 'tmps4rqscript_imp.log');
  $rqsysexp = "$step4_imp $MIGUSER $MIGPWD $MIGSRC_CONNECTSTR 2>$step4_log";
  oracle::oremigcommon::checkcmd($rqsysexp, "Step4 failed. check tmps4rqscript_imp.log"); 

  $step4_srcsql= File::Spec->catfile($MIGSRCDIR, 'rqscriptmig.sql');
  $step4_destsql= File::Spec->catfile($MIGDIR, 'rqscriptmig.sql');
  copy($step4_srcsql, $step4_destsql);

#check for errors
  $step4_logfiles=File::Spec->catfile($MIGDIR, '*.log');
  ($found) =oracle::oremigcommon::findoraerr($step4_logfiles);
  if( $found > 0 )
  {
    print "Failure: Please check log files in $MIGDIR for errors \n";
  }
print "*****************************IMPORTANT ******************************\n";
print " Please connect as sysdba and run the script rqscriptmig.sql in $MIGDIR to complete the IMPORT\n";
print "********************************************************************\n";


}

&checkArgs(@ARGV);
($SQLPLUS, $MIGPWD, $ORAHOME, $MIGSRCDIR)=&oracle::oremigcommon::sanityChecks($MIGUSER, $SQLPLUS_CONSTR, $MIGDIR);
$MIGSRCDIR=$MIGSRCDIR."/imp";
&importProc(); 
