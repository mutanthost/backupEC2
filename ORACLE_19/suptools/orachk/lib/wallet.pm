#!/usr/local/bin/perl
# $Header: tfa/src/orachk_py/lib/wallet.pm /main/3 2017/09/13 22:55:20 rojuyal Exp $
#
# wallet.pm
# 
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      wallet.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    rkchaura    09/27/16 - oracle wallet to store secret information
#    rkchaura    09/27/16 - Creation
# 
 
#####################   Wallet API  #######################

use Cwd; 
use Exporter;
use File::Spec;
@ISA = qw(Exporter);
@EXPORT=qw(removeWallet(@ARGV));
@EXPORT=qw(addEntryInWallet(@ARGV));
@EXPORT=qw(createWallet(@ARGV));
@EXPORT=qw(checkWallet(@ARGV));
@EXPORT=qw(removeEntryFromWallet(@ARGV));
@EXPORT=qw(modifyEntryInWallet(@ARGV));
@EXPORT=qw(getSecretFromWallet(@ARGV));
@EXPORT=qw(listEntriesInWallet(@ARGV));

sub addEntryInWallet 
{
  my $PYTHON = $ENV{'RAT_PYTHON'} || 'python';
  my $TOOLPATH = $ENV{'RAT_TOOLPATH'} || getcwd();
  my $WALLET_LOC = shift|| $ENV{WALLET_LOC};
  my $KEY = shift|| $ENV{WALLET_KEY};
  my $VALUE = shift|| $ENV{WALLET_VALUE};
  my $MKSTORE_PATH = File::Spec->catfile("$TOOLPATH", "lib", "mkstore.py");
  if (! -e $MKSTORE_PATH)
  {
    $MKSTORE_PATH = File::Spec->catfile("$TOOLPATH", "lib", "mkstore.pyc");
  }
  my $WALLET_CMD = "$PYTHON $MKSTORE_PATH -wrl $WALLET_LOC -createEntry $KEY '$VALUE' -nologo";
  open( ENTRY, "| $WALLET_CMD" );
  close ( ENTRY );
  exit 0;
}


sub removeEntryFromWallet 
{
  my $PYTHON = $ENV{'RAT_PYTHON'} || 'python';
  my $WALLET_LOC = shift|| $ENV{WALLET_LOC};
  my $KEY = shift|| $ENV{WALLET_KEY};
  my $TOOLPATH = $ENV{'RAT_TOOLPATH'} || getcwd();
  my $MKSTORE_PATH = File::Spec->catfile("$TOOLPATH", "lib", "mkstore.py");
  if (! -e $MKSTORE_PATH)
  {
    $MKSTORE_PATH = File::Spec->catfile("$TOOLPATH", "lib", "mkstore.pyc");
  }
  my $WALLET_CMD = "$PYTHON $MKSTORE_PATH -wrl $WALLET_LOC -deleteEntry $KEY";
  open( REMOVE, "| $WALLET_CMD" );
  close ( REMOVE );
  exit 0;
}


sub modifyEntryInWallet 
{
  my $PYTHON = $ENV{'RAT_PYTHON'} || 'python';
  my $WALLET_LOC = shift|| $ENV{WALLET_LOC};
  my $KEY = shift|| $ENV{WALLET_KEY};
  my $TOOLPATH = $ENV{'RAT_TOOLPATH'} || getcwd();
  my $VALUE = shift|| $ENV{WALLET_VALUE};
  my $MKSTORE_PATH = File::Spec->catfile("$TOOLPATH", "lib", "mkstore.py");
  if (! -e $MKSTORE_PATH)
  {
    $MKSTORE_PATH = File::Spec->catfile("$TOOLPATH", "lib", "mkstore.pyc");
  }
  my $WALLET_CMD = "$PYTHON $MKSTORE_PATH -wrl $WALLET_LOC -modifyEntry $KEY '$VALUE' -nologo";

  open( MODIFY, "| $WALLET_CMD" );
  close ( MODIFY );
  my $STATUS = $?;
  print "RETURN:$STATUS";
  exit 0;
}

sub listEntriesInWallet 
{
  my $PYTHON = $ENV{'RAT_PYTHON'} || 'python';
  my $TOOLPATH = $ENV{'RAT_TOOLPATH'} || getcwd();
  my $WALLET_LOC = shift|| $ENV{WALLET_LOC};
  my $MKSTORE_PATH = File::Spec->catfile("$TOOLPATH", "lib", "mkstore.py");
  if (! -e $MKSTORE_PATH)
  {
    $MKSTORE_PATH = File::Spec->catfile("$TOOLPATH", "lib", "mkstore.pyc");
  }
  my $WALLET_CMD = "$PYTHON $MKSTORE_PATH -wrl $WALLET_LOC -list -nologo";

  open( LIST, "| $WALLET_CMD" );
  close ( LIST );
  exit 0;
}

sub getSecretFromWallet 
{
  my $PYTHON = $ENV{'RAT_PYTHON'} || 'python';
  my $WALLET_LOC = shift|| $ENV{WALLET_LOC};
  my $KEY = shift|| $ENV{WALLET_KEY};
  my $TOOLPATH = $ENV{'RAT_TOOLPATH'} || getcwd();

  my $MKSTORE_PATH = File::Spec->catfile("$TOOLPATH", "lib", "mkstore.py");
  if (! -e $MKSTORE_PATH)
  {
    $MKSTORE_PATH = File::Spec->catfile("$TOOLPATH", "lib", "mkstore.pyc");
  }
  my $WALLET_CMD = "$PYTHON $MKSTORE_PATH -wrl $WALLET_LOC -viewEntry $KEY -nologo";

  open( SECRET, "| $WALLET_CMD" );
  close ( SECRET );
  exit 0;
}
1;
                
