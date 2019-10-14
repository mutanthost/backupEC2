# 
# $Header: oracler/migration/oreuser/exp/ore_dsiexport.pl /st_oracler_1.5.1.0.1/1 2017/06/20 18:00:39 qinwan Exp $
#
# ore_dsiexport.pl
# 
# Copyright (c) 2014, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      ore_dsiexport.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    qinwan      06/19/17 - remove shebang line
#    gayyappa    07/18/14 - porting to windows
#    gayyappa    01/21/14 - Creation
#

use strict;
use warnings;
use File::Copy;
use Cwd qw();

use oracle::oremigcommon  qw( sanityChecks checkcmd checkcmdAndDie);

my $MIGUSER='system';
my $MIGPWD='';
my $ORAHOME='';
my $MIGSRCDIR='';
my $MIGDIR='';
my $TARFILE='';
my $MIGSRC_CONNECTSTR='';
my $SQLPLUS='';
my $SQLPLUS_CONSTR='';
my $SCHEMA='';

sub checkArgs
{
  my $argc= $#ARGV ;     
  if ( $argc != 3 )
  {
   # print "argc is $argc+1";
    print "Usage is perl ore_dsiexport.pl <connect-identifier> <migration-dir> <zipfile> <schema-name>\n";
    print "Please specify source db connect identifier \n";
    print "and the name of the directory where data files should be copied\n";
    print "Also specify the name of the output  zip file \n";
    die();
  }

  $SQLPLUS_CONSTR=$ARGV[0];
  $MIGDIR=$ARGV[1];
  $TARFILE=$ARGV[2];
  $SCHEMA=$ARGV[3];
  $MIGSRC_CONNECTSTR=$SQLPLUS_CONSTR;
}

#all global varibale should be validated before calling this function
sub migrateProc
{

  my ($sqlplus, $rqsysexp, $filename, $output);
  my ($step1_setup, $step1_storedproc, $step1_log);
  my ($step4_err, $step2_log);
  my ($step5_clean, $step5_log);
  my ($found, $tmpfile);
  my $fsuff;

  $fsuff = &oracle::oremigcommon::getScriptSuffix();
  $step1_setup= File::Spec->catfile("$MIGSRCDIR",'setup.sql');
  $step1_storedproc= File::Spec->catfile("$MIGSRCDIR",'storedproc.sql');
  $step1_log= File::Spec->catfile("$MIGDIR",'tmpstep1.log');
  #setup stored procedures . generates exp_dsi_user.sh and imp_dsi_user.sh
  print("****Step1 Setup before export ******\n");
  $sqlplus = "$SQLPLUS \@$step1_setup $MIGUSER $MIGPWD $MIGSRC_CONNECTSTR $MIGDIR $SCHEMA $step1_storedproc > $step1_log";
  print("$sqlplus \n");
  &oracle::oremigcommon::checkcmdAndDie( $sqlplus, "Step1 failed : $! \n Please check tmpstep1.log");
  
  #Step 2 export datastore objects for specified schema
  print ("******Step2 export schema with data store ****\n");
  $filename=File::Spec->catfile($MIGDIR,"exp_dsi_user.sh");
  $step2_log=File::Spec->catfile($MIGDIR,"exp_dsi_user.log");
  if( ! -e $filename)
  {
        die("$filename not found. Check log file for errors\n");
  }
  if ( !( ($^O eq 'MSWin32') || ($^O eq 'dos')) )
  {
    &oracle::oremigcommon::checkcmdAndDie( "chmod +x $filename", "Failed chmod");
    $rqsysexp="cp $MIGDIR/*.par .";
  }
  else
  {
    my $cwd = Cwd::getcwd;
    $step4_err= File::Spec->catfile($MIGDIR, "exp_dsi_user.sh");
    $filename=&oracle::oremigcommon::convertShToBat($step4_err); 
    $rqsysexp="xcopy \"$MIGDIR\\*.par\" $cwd\\ ";
  }

 
  &oracle::oremigcommon::checkcmdAndDie($rqsysexp, "Step3 failed ");
  $filename=File::Spec->catfile($MIGDIR,"exp_dsi_user.$fsuff");
  $rqsysexp=" $filename $MIGUSER $MIGPWD $MIGSRC_CONNECTSTR 2> $step2_log";
  &oracle::oremigcommon::checkcmdAndDie($rqsysexp, "Step3 failed ");

  #check for errors
  $step4_err = File::Spec->catfile($MIGDIR, '*.log');
  ($found)=&oracle::oremigcommon::findoraerr($step4_err);
  if( $found > 0 )
  {
     print "Check log files for errors. $TARFILE has not been created \n";
     die($found);
  }


  #cleanup
  print("****Step3 cleanup ****\n");
  $step5_clean= File::Spec->catfile($MIGSRCDIR,'cleanup.sql');
  $step5_log= File::Spec->catfile($MIGDIR,'tmpcleanup.log');
  $sqlplus = "$SQLPLUS \@$step5_clean > $step5_log";
  oracle::oremigcommon::checkcmd($sqlplus, "Cleanup failed");
  print( "Export complete \n");

  print( "dump files are in $MIGDIR\n");
  if ( ($^O eq 'MSWin32') || ($^O eq 'dos'))
  {
    exit;
  }

  print( "*****Step4 creating zip file $TARFILE ***\n");
  system("cat $MIGDIR/genfileList.txt $MIGSRCDIR/tarfilelist.txt > $MIGDIR/files.list");
#  $rqsysexp = "tar -cvf  $TARFILE -C $MIGDIR --files-from files.list";
  $rqsysexp = "cd $MIGDIR; cat $MIGDIR/files.list | zip  $TARFILE -@";
  oracle::oremigcommon::checkcmd($rqsysexp, "Creating zip failed");
  print("Created $TARFILE. Use this for file importing ORE data from $SCHEMA into target db\n");

}


&checkArgs(@ARGV);
($SQLPLUS, $MIGPWD, $ORAHOME, $MIGSRCDIR)=&oracle::oremigcommon::sanityChecks($MIGUSER, $SQLPLUS_CONSTR, $MIGDIR);
$MIGSRCDIR=File::Spec->catfile($MIGSRCDIR, 'oreuser');
$MIGSRCDIR=File::Spec->catfile($MIGSRCDIR, 'exp');
&migrateProc(); 
