# 
# $Header: tfa/src/orachk_py/lib/cm_lib.pl /main/2 2017/08/11 17:38:18 rojuyal Exp $
#
# cm_lib.pl
# 
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      cm_lib.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    rkchaura    10/24/16 - collection manager upgrade
#    rkchaura    10/24/16 - Creation
# 

use DBI;
use DBD::Oracle;
use DBD::Oracle qw(ORA_RSET);
use Cwd qw();
use File::Spec;
use File::Copy;
use Data::Dumper;

$ENV{PERLBIN} = "";
#$ENV{PERL5LIB} = "/usr/lib64/perl5/";

undef $ENV{NLS_LANG};
undef $ENV{ORA_NLS};
undef $ENV{ORA_NLS32};
undef $ENV{ORA_NLS33};

my $debug = FALSE ;

sub db_disconnect 
{
  $sth->finish if ($sth) ;
  $dbh->disconnect if ( $dbh);
} 

sub dbconnect_orachk
{
  $upload_user = shift|| $ENV{RAT_UPLOAD_USER};
  $upload_password = shift|| $ENV{RAT_UPLOAD_PASSWORD};
  $RAT_UPLOAD_CONNECT_STRING = $ENV{RAT_UPLOAD_CONNECT_STRING};   
  $dbuser = "$upload_user/$upload_password";
  $dbh = DBI->connect('dbi:Oracle:', $dbuser . '@' .$RAT_UPLOAD_CONNECT_STRING, '', {AutoCommit => 0});
  my $sql = 'select * from (select app_version from rca13_release_info order by build_id desc) where rownum<2';
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  while (my @row = $sth->fetchrow_array) {
   our $cm_version = $row[0];
   $cm_version =~ s/[^0-9]*//g;
}
  unless($dbh) {
        warn "Unable to connect to Oracle ($DBI::errstr)\n";
        exit 0;
  }
  db_disconnect; 
  return $cm_version;
}

sub check_cm_version
{
  $required_cm_version_int = $required_cm_version;
  $required_cm_version_int =~ s/[^a-zA-Z0-9]*//g; #To remove . from version to get numeric value
  $cm_version = dbconnect_orachk;
  $cm_version_int = $cm_version;
  $cm_version_int =~ s/[^a-zA-Z0-9]*//g;
  $cm_version_in_cmsql_int = $program_version;
  $cm_version_in_cmsql_int =~ s/[^0-9]*//g;
  #$cm_version_in_cmsql_int=122012; #Dummy value for testing 

  if ($cm_version_int ge $cm_version_in_cmsql_int)
  {
    #No need to upgrade the cm but upload the collections in cm
    return 1;
  }
  else
  {
    my $cm_sql_path = Cwd::cwd();
    if ($cm_version_in_cmsql_int gt $cm_version_int)
    {
      print "\nCurrent version of Oracle Health Checks Collection Manager is $cm_version and $program_name requires version $program_version or higher.New version $program_version is available at $SCRIPTPATH. Do you want to upgrade?[y/n][n]";
      if ($prompt_timeout eq 1)  #Check if -silentforce
      {
        print "\n";
        $user_input = "n";
        print "\n$program_name requires Oracle Health Checks Collection Manager version $program_version for uploading collections.\n";
        return 2;
      }
      if ($daemon_running ne "1")
      {
        #Continue execution
        print "";
      }
      else #Daemon
      {
        if ($daemon_init_mode eq 1 || $daemon_init_mode_sudo eq "1")
        {
          print "";
        }
        else
        {
          return 4;
        }
      }
      my $user_input = <STDIN>; 
      chomp $user_input;
      
      if ($user_input eq "y" || $user_input eq "Y" || $user_input eq "yes" || $user_input eq "Yes")
      {
        #upgrade the cm before uploading collections in the cm
        return 0;
      }
      else
      {
        print "\n$program_name requires Oracle Health Checks Collection Manager version $program_version for uploading collections.\n";
        return 2;
      }
    }
    else
    {
      #No need to upgarde the cm but upload the collections in cm
      return 1;
    }
  }
}

sub get_cm_upgrade_status
{
  $upload_user = shift|| $ENV{RAT_UPLOAD_USER};
  $upload_password = shift|| $ENV{RAT_UPLOAD_PASSWORD};
  $RAT_UPLOAD_CONNECT_STRING = $ENV{RAT_UPLOAD_CONNECT_STRING};
  $dbuser = "$upload_user/$upload_password";
  $dbh = DBI->connect('dbi:Oracle:', $dbuser . '@' .$RAT_UPLOAD_CONNECT_STRING, '', {AutoCommit => 0});
  my $sql = qq(SELECT PREFERENCE_VALUE FROM RCA13_INTRACK_PREFERENCES where PREFERENCE_NAME='CM_UPGRADE_MODE');
  my $sth = $dbh->prepare($sql);
  $sth->execute();
  while (my @row = $sth->fetchrow_array) {
  our $upgraded_mode_status = join(" ",@row);
  }
  unless($dbh) {
        warn "Unable to connect to Oracle ($DBI::errstr)\n";
        exit 0;
  }
  db_disconnect;
  return $upgraded_mode_status;
}

our ($program_name) = $ARGV[0];
our ($program_version) = $ARGV[1];
our ($prompt_timeout) = $ARGV[2];
our ($daemon_running) = $ARGV[3];
our ($daemon_init_mode) = $ARGV[4];
our ($daemon_init_mode_sudo) = $ARGV[5];
our ($cmdline_cm_upgrade) = $ARGV[6];
our ($SCRIPTPATH) = $ARGV[7];
if ($prompt_timeout eq 2)
{
  exit 1;
}
#Define the following variable whenever its needed
print "YES";
our $required_cm_version="12.2.0.1.2";
if ( defined $required_cm_version || $cmdline_cm_upgrade eq "1")
{
  $upgraded_mode_status = get_cm_upgrade_status;
  if ( $upgraded_mode_status eq "Y")
  {
    print "\nCollection Manager is upgrading to newest version. Please allow it to finish and try again.\n";
    exit 3; 
  }
  $return_status = check_cm_version;
  if ($return_status eq 0)  {
    print "\nOracle Health Checks Collection Manager is upgrading. Please wait...\n";
    exit 0;
  }
  elsif ($return_status eq 1)
  {
    exit 1;
  } 
  elsif ($return_status eq 4)
  {
    #exit 4 means daemon client is running and upgraded version of cm is available so send an email and continue executing the program
    exit 4;
  }
  else
  {
    exit 2;
  }
}
else
{
  #Do not need to upgrade the cm because required cm version is not defined
  exit 1;
} 

1;
 
