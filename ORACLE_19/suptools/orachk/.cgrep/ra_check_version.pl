#!/opt/oracle.RecoveryAppliance/bin/perl -w
# 
# $Header: tfa/src/orachk_py/scripts/ra_check_version.pl /main/1 2018/04/12 09:20:23 cgirdhar Exp $
#
# ra_check_version.pl
# 
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      ra_check_version.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    scorso      04/10/18 - Creation
#    cgirdhar    04/10/18 - Verify ZDLRA version
# 

use strict;
use warnings;

use RA::DB::Oracle qw/GetEnv/;
use RA::Util qw/SysRun $default_base/;
use Getopt::Long qw/GetOptions/;
use Pod::Usage;

$ENV{PATH} = "/usr/bin";
my $env;
my $version_opt;
my $report;
my $help;

GetOptions( "help" => \$help, "v:s" => \$version_opt, "report" => \$report );

if ($help) {
  _help();
}

eval {
  $env = GetEnv( TYPE => 'DB' );
};

if ( $@ ) {
  die "Failed getting environment information. Confirm the ZDLRA is online\n";
}

#Source in our running env:
my $patch_info = do "$env->{ORACLE_HOME}/rdbms/install/zdlra/zdlra-software-id";
$patch_info->{zdlra_label} =~ /ZDLRA_(\S+)_LINUX.X64_(\S+)/;
my $version = $1;
my $main_version = $2;

#First weed out MAIN
if ( $patch_info->{zdlra_label} =~ /MAIN/ ) {
  $version = $main_version;
}
else {
  #Not Main so we need to check for CIs

  if ( $patch_info->{transaction} ) {
  
    #Confirm the CI installed is the CI for the RPM too
    my $rpm_patch_info = do "$default_base/zdlra/install/zdlra/zdlra-software-id";
    die "Failed: Mismatch between installed version and RPM installed\n"
      . "Installed Version: $patch_info->{transaction}\n"
      . "RPM Version: $rpm_patch_info->{transaction}\n"
      unless ( $patch_info->{transaction} eq $rpm_patch_info->{transaction} );
  
    #We have a CI lets get that value.
    my $rpm_info = SysRun(
      CMD => "/bin/rpm",
      ARGS => '-qa ra_automation --queryformat %{VERSION}.%{RELEASE}',
      LOG  => sub { print "$_\n" if ($_); }, #simple logger 
    );
    die "Failed to determine CI information: $rpm_info [$!]\n"
      unless ( ref $rpm_info eq 'ARRAY' );
  
    if ( scalar @{ $rpm_info } == 1 ) {
      #We have a match for an RPM
      # replace , with . to pick up CI/1 off versions
      ( $version = $rpm_info->[0] ) =~ s/[-,]/./g;
    }
    else {
      die "Failed to find exact match for ra_automation rpm. Results: [@{ $rpm_info }]\n";
    }
  }
}


print "Current Version: $version\n" if ( $report );
my $version_dec = single_dec($version);
$version_opt =~ s/.RELEASE$//;
$version_opt =~ s/[-,]/./g;
my $version_opt_dec = single_dec($version_opt);
if ( $version_dec >= $version_opt_dec ) {
   exit 0;
}
else {
  exit 1;
}

sub single_dec {
# Versions end up having lots of '.' in them. When we compare we will keep the first number as a whole number all remainining
# places will go after a single decimal.
# This is a little crude but it allows us to not care about the number of interim patches. We will just create a longer number.

  my $dot_version = shift;

  my @version = split(/\./, $dot_version);
  my $int = shift(@version); 
  my $fract = join('', @version);
  my $return = $int . '.' . $fract;
  return($return);
}

sub _help {
 pod2usage( -verbose => 3, -output => \*STDERR );
 exit;
}

=head1 NAME

ra_check_version.pl

=head1 SYNOPSIS

Check if the version running is newer or older then the version requested.

ra_check_version.pl -v RA_VERSION_TO_CHECK [ -report ];

Exit 0 if the running version is newer then the requested version.
Exit 1 if the running version is older then the requested version.

=head1 ARGUMENTS

=head2 -v

Minimum Version.  Example 12.1.1.1.8

=head2 -report

Print The current version out.

=head2 -help

Print this help message

=head1 COPYRIGHT AND LICENSE

 Copyright (c) 2013, 2018, Oracle and/or its affiliates. All rights reserved.
