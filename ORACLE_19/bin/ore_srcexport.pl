# 
# $Header: oracler/migration/exp/ore_srcexport.pl /st_oracler_1.5.1.0.1/1 2017/06/20 18:00:39 qinwan Exp $
#
# ore_srcexport.pl
# 
# Copyright (c) 2014, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      ore_srcexport.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    qinwan      06/19/17 - remove shebang line
#    gayyappa    07/11/14 - port to windows
#    gayyappa    01/17/14 - Creation
# 
#

use strict;
use warnings;
use File::Spec;
use File::Copy;
use oracle::oremigcommon  qw( sanityChecks checkcmd checkcmdAndDie); 

my $MIGUSER='system';
my $MIGPWD='';
my $ORAHOME='';
my $MIGSRCDIR='';
my $MIGDIR='';
my $TARFILE='';
my $MIGSRC_CONNECTSTR='';
my $SQLPLUS='';
my$SQLPLUS_CONSTR='';
  
sub checkArgs
{
  my $argc= $#ARGV ;     #$argc = @ARGV  will also assign length
  if ( $argc != 2 )
  {
   # print "argc is $argc+1";
    print "Usage is perl  ore_srcexport.pl <connect-identifier> <migration-dir> <zipfile>\n";
    print "Please specify source db name \n";
    print "and the name of the directory where data files should be copied\n";
    print "Also specify the name of the output zip file \n";
    die();
  }
  
  $SQLPLUS_CONSTR=$ARGV[0];
  $MIGDIR=$ARGV[1];
  $TARFILE=$ARGV[2];
  $MIGSRC_CONNECTSTR=$SQLPLUS_CONSTR;
#  $MIGSRC_CONNECTSTR =~ s/[=|\.|\)|\(]/PPP$&/g ;
#  $MIGSRC_CONNECTSTR =~ s/[=|\.|\)|\(]/\\$&/g ;
}

# Function : migrateProc
#NOTE:  all global varibale should be validated before calling this function
sub migrateProc
{

  my ($sqlplus, $rqsysexp, $filename, $output);
  my ($step1_setup, $step1_storedproc, $step1_log);
  my ($step1_gengrant, $step1_grant);
  my ($step2_rqsys, $step2_log);
  my ($step3_expore, $step3_log, $convname);
  my ($step4_rqscr, $step4_log, $step4_err);
  my ($step5_clean, $step5_log);
  my $found;
  my $fsuff = &oracle::oremigcommon::getScriptSuffix();
  ##generate required .bat files from .sh files
  if ( ($^O eq 'MSWin32') || ($^O eq 'dos'))
  {
    $step3_expore= File::Spec->catfile($MIGSRCDIR, "rqscript_exp.sh");
    $convname= &oracle::oremigcommon::convertShToBat($step3_expore);
    $step3_expore= File::Spec->catfile($MIGSRCDIR, "rqsys_exp.sh");
    $convname= &oracle::oremigcommon::convertShToBat($step3_expore);
  }

  $step1_setup= File::Spec->catfile("$MIGSRCDIR",'setup.sql');
  $step1_storedproc= File::Spec->catfile("$MIGSRCDIR",'storedproc.sql');
  $step1_log= File::Spec->catfile("$MIGDIR",'tmpstep1.log');
  #setup stored procedures . generates exp_ore_user.sh and imp_ore_user.sh
  print("****Step1 Setup before export ******\n");
  $sqlplus = "$SQLPLUS \@$step1_setup $MIGUSER $MIGPWD $MIGSRC_CONNECTSTR $MIGDIR $step1_storedproc > $step1_log";
  &oracle::oremigcommon::checkcmdAndDie( $sqlplus, "Step1 failed : $! \n Please check tmpstep1.log");

  #generate grant_mining.sql
  $step1_gengrant= File::Spec->catfile($MIGSRCDIR,'gen_grant_mining.sql');
  $step1_grant= File::Spec->catfile($MIGDIR,'grant_mining.sql');
  $sqlplus = "$SQLPLUS \@$step1_gengrant > $step1_grant";
  &oracle::oremigcommon::checkcmd( $sqlplus, "Fail :$!\n");

  print("******Step2 export rqsys *****\n");
  $step2_rqsys= File::Spec->catfile($MIGSRCDIR,"rqsys_exp.$fsuff");
  $step2_log= File::Spec->catfile($MIGDIR,'rqsys_exp.log');
  $rqsysexp = "$step2_rqsys $MIGUSER $MIGPWD $MIGSRC_CONNECTSTR 2>$step2_log";
  &oracle::oremigcommon::checkcmdAndDie($rqsysexp, "Step2 failed ");

  print ("******Step 3 export schema with data store ****\n");
  $filename=File::Spec->catfile($MIGDIR,"exp_ore_user.sh");
  if( ! -e $filename)
  { 
        die("$filename not found. Check log file for errors\n");
  }
  if ( ($^O eq 'MSWin32') || ($^O eq 'dos'))
  {  
    $convname= &oracle::oremigcommon::convertShToBat($filename);
  }
  else
  { 
    system("chmod +x $filename");
  }
  $step3_expore= File::Spec->catfile($MIGDIR, "exp_ore_user.$fsuff");
  $step3_log= File::Spec->catfile($MIGDIR,'exp_ore_user.log');
  $rqsysexp=" $step3_expore $MIGUSER $MIGPWD $MIGSRC_CONNECTSTR 2> $step3_log";
  &oracle::oremigcommon::checkcmdAndDie($rqsysexp, "Step3 failed ");

#export tmprqscript
  print("****Step4 export rqscript data ****\n");
  $step4_rqscr= File::Spec->catfile($MIGSRCDIR,"rqscript_exp.$fsuff");
  $step4_log= File::Spec->catfile($MIGDIR,'rqscript_exp.log');
  $rqsysexp = "$step4_rqscr $MIGUSER $MIGPWD $MIGSRC_CONNECTSTR 2>$step4_log";
  &oracle::oremigcommon::checkcmdAndDie($rqsysexp, "Step4 failed ");

#check for errors. note windows specific code here
  $step4_err = File::Spec->catfile($MIGDIR, '*.log');
  ($found)=&oracle::oremigcommon::findoraerr($step4_err);
  if( $found > 0 )
  {
     print "Check log files for errors. $TARFILE has not been created \n";
  }

#cleanup
  print("****Step5 cleanup ****\n");
  $step5_clean= File::Spec->catfile($MIGSRCDIR,'cleanup.sql');
  $step5_log= File::Spec->catfile($MIGDIR,'tmpcleanup.log');
  $sqlplus = "$SQLPLUS \@$step5_clean > $step5_log";
  oracle::oremigcommon::checkcmd($sqlplus, "Cleanup failed");
  print( "Export complete \n");

  print( "dump files are in $MIGDIR\n");
  if ( ($^O eq 'MSWin32') || ($^O eq 'dos'))
  {
    print "Skipping $TARFILE creation. Cannot create $TARFILE on this OS.";
    exit;
  }
 
  print( "*****Step 6 creating zip file $TARFILE ***\n");
  system("cat $MIGDIR/genfileList.txt $MIGSRCDIR/tarfilelist.txt > $MIGDIR/files.list");

#  $rqsysexp = "tar -cvf  $TARFILE -C $MIGDIR --files-from files.list";
  $rqsysexp = "cd $MIGDIR; cat $MIGDIR/files.list | zip  $TARFILE -@";
  oracle::oremigcommon::checkcmd($rqsysexp, "Creating zip file failed");
  print("Created $TARFILE. Use this for file importing ORE data into target db\n");
}



&checkArgs(@ARGV);
($SQLPLUS, $MIGPWD, $ORAHOME, $MIGSRCDIR)=&oracle::oremigcommon::sanityChecks($MIGUSER, $SQLPLUS_CONSTR, $MIGDIR);
$MIGSRCDIR=$MIGSRCDIR."/exp";
&migrateProc();
