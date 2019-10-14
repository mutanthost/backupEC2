#!/usr/bin/perl
# 
# $Header: has/utl/crsdiag.pl.sbs /main/5 2012/08/20 15:29:39 jcreight Exp $
#
# crsdiag.pl
# 
# Copyright (c) 2007, 2012, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      crsdiag.pl - Wrapper over diagcollection.pl for ADR
#
#    DESCRIPTION
#      In the DB home, invokes diagcollection.pl from CRS home
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    jcreight    08/14/12 - Fix bug 14463820 - handle MKS perl
#    jcreight    03/19/10 - Fix bug 9491777: find CRS home in OLR registry key
#    jcreight    12/02/08 - Fix bug 7588168 - OK to not have CRS
#    jcreight    10/16/08 - fix bug 7368124 by looking up CRS home
#    jcreight    05/09/08 - pull into MAIN (11.2) 
#    rajayar     04/24/07 - Fix the ORA_CRS_HOME path
#    ilam        04/11/07 - Fix hard-coded CRS location
#    rajayar     04/05/07 - Creation
# 

print "Production Copyright 2004, 2010, Oracle.  All rights reserved\n";
print "Cluster Ready Services (CRS) diagnostic collection tool wrapper script\n";

#
# Find CRS home
#
$PLATFORM = $^O;
$HPUX = "hpux";
$WIN32 = "MSWin32";
$LINUX = "linux";
$AIX = "aix";
$SOLARIS = "solaris";

if ($PLATFORM eq $WIN32)
{
  require Win32::TieRegistry;
  import Win32::TieRegistry (Delimiter => '/');
}

#### Function for dumping fatal errors on STDOUT
# ARGS : 0
sub errorexit
{
    print "@_\n";
    exit;
}

$HAS_DEVELOPMENT_ENVIRONMENT=$ENV{'HAS_DEVELOPMENT_ENVIRONMENT'};

# in development environment, CRS home is same as ORACLE_HOME
if ($HAS_DEVELOPMENT_ENVIRONMENT eq "")
{
  #Set crshome from olr.loc
  if ($PLATFORM eq $HPUX) {
	$OLRCONFIG="/var/opt/oracle/olr.loc";
  } elsif ($PLATFORM eq $LINUX) {
	$OLRCONFIG="/etc/oracle/olr.loc";
  } elsif ($PLATFORM eq $SOLARIS) {
	$OLRCONFIG="/var/opt/oracle/olr.loc";
  } elsif ($PLATFORM eq $AIX) {
	$OLRCONFIG="/etc/oracle/olr.loc";
  } elsif ($PLATFORM eq $WIN32) {
	my $swkey=$Registry->{"LMachine/Software/Oracle/olr/"};
        $crshome = $swkey->{"/crs_home"};
	if(! $crshome) {
	   errorexit("CRS home not present in the registry");
	}
  } else  {
      errorexit("Error: Unknown Operating System for looking up CRS home");
      exit;
  }
  if ($PLATFORM ne $WIN32) {
      open (OLRCFGFILE, "<$OLRCONFIG") or 
	 errorexit ("CRS not installed, cannot open $OLRCONFIG");
      while (<OLRCFGFILE>) {
	if (/^crs_home=(\S+)/) {
	    $crshome = $1;
	    last;
	}
      }
      close (OLRCFGFILE);
      if (! $crshome) {
	   errorexit("CRS home not present in the $OLRCONFIG file");
      }
  }
}
else  # development environment
{
  $crshome=$ENV{'ORACLE_HOME'};
}

# translate backslash to slash in CRS home path
# which keeps MKS perl happy
grep(s#\\#/#g, $crshome);

#
# Run the CRS home diagcollection script
# Note: The Oracle version of perl always needs -I to find its libraries
# 
system("${crshome}/perl/bin/perl -I${crshome}/perl/lib ${crshome}/bin/diagcollection.pl --collect --crshome ${crshome} @ARGV");

exit;

