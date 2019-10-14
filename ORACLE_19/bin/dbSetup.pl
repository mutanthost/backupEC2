#!../perl/bin/perl
# 
# $Header: install/utl/scripts/db/dbSetup.pl /main/4 2017/08/23 15:00:30 poosrini Exp $
#
# dbSetup.pl
# 
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      dbSetup.pl
#
#    DESCRIPTION
#      perl script to launch db setup wizard for configuring Database home image
#
#    MODIFIED   (MM/DD/YY)
#    davjimen    03/24/17 - change log dir prefix
#    davjimen    01/18/17 - remove common code
#    davjimen    09/27/16 - Creation
# 
use strict;
use warnings;
package Database;

use parent qw(CommonSetup);

sub new {
  my ($class) = @_;

  my $self = $class->SUPER::new(
    "TYPE" => "Database",
    "PRODUCT_DESCRIPTION" => "Oracle Database",
    "PRODUCT_JAR_NAME" => "instdb.jar",
    "SETUP_SCRIPTS" => "runInstaller,setup.bat",
    "LOG_DIR_PREFIX" => "InstallActions",
    "MAIN_CLASS" => "oracle.install.ivw.db.driver.DBConfigWizard",
  );
  bless $self, $class;
  return $self;
}

my $db = new Database();

$db->main();
