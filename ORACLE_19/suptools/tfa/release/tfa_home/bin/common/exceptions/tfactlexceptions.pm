# 
# $Header: tfa/src/v2/tfa_home/bin/common/exceptions/tfactlexceptions.pm /main/1 2014/07/17 08:32:54 manuegar Exp $
#
# tfactlexceptions.pm
# 
# Copyright (c) 2014, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlexceptions.pm - Exception Handling Functionality Module
#
#    DESCRIPTION
#      TFACTL - Trace File Analyzer Control Utility 
#
#    NOTES
#      usage: tfactl [-v {errors|warnings|normal|info|debug|none}] [command]
#
#    MODIFIED   (MM/DD/YY)
#    manuegar    06/30/14 - Creation
#
#############################################################################
#
############################ Functions List #################################
#   tfactlexceptions::catch
#   tfactlexceptions::throw
#   tfactlexceptions::getType
#   tfactlexceptions::getErrmsg
#   new
#
#############################################################################

use strict;
package tfactlexceptions;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(tfactlexceptions::throw 
                 tfactlexceptions::catch 
                 tfactlexceptions::getType 
                 tfactlexceptions::getErrmsg 
                 tfactlexceptions::getExceptionstring
                 tfactlexceptions::noexceptions
                 $_EXCEPTION_);

our $_EXCEPTION_;
our $_HASBEENCAUGHT_;
our $_EXCEPTIONSTRING_;
our @_EXCEPTIONLIST_;

my $_NOEXCEPTIONSYET_;
BEGIN
{
   $_HASBEENCAUGHT_   = 1; # There are no uncaught exceptions.
   @_EXCEPTIONLIST_   = ();
   $_NOEXCEPTIONSYET_ = 1; # No exceptions have been thrown yet;
}

########
# NAME
#   tfactlexceptions::catch
#
# DESCRIPTION
#   This routine catches the most recent exception to be raised.
#
# PARAMETERS
#   None.
#
# RETURNS
#   0 - If no exceptions were caught.
#   1 - If an exception was successfully caught.
########
sub tfactlexceptions::catch
{
   return 0 if($_HASBEENCAUGHT_ && $@ eq ""); # If the flag is 1 and $@ is 
                                              # empty, there are no uncaught 
                                              # exception
   my $class = "tfactlexceptions";
   if(!$_HASBEENCAUGHT_) # There is an uncaught exception which was created by
                         # this exception class.
   {
      $_EXCEPTIONSTRING_ = "\nException Caught"; 
      if (defined ($_EXCEPTION_->{_TYPE_}))
      {
         $_EXCEPTIONSTRING_ = $_EXCEPTIONSTRING_ . "\nType :" . 
                                        $_EXCEPTION_->{_TYPE_};
      }
      if (defined($_EXCEPTION_->{_ERRMSG_}))
      {
         $_EXCEPTIONSTRING_ = $_EXCEPTIONSTRING_ . "\nMessage :" . 
                                        $_EXCEPTION_->{_ERRMSG_};
      }
      if (defined($_EXCEPTION_->{_FILE_}))
      {
         $_EXCEPTIONSTRING_ = $_EXCEPTIONSTRING_ . "\nFile :" . 
                                        $_EXCEPTION_->{_FILE_};
      }
      if (defined($_EXCEPTION_->{_LINE_}))
      {
         $_EXCEPTIONSTRING_ = $_EXCEPTIONSTRING_ . "\nLine :" . 
                                        $_EXCEPTION_->{_LINE_} . "\n";
      }
 
      $_HASBEENCAUGHT_ = 1; # Set the flag as 1. No uncaught exceptions.
      $@ = ""; # Clear the exception string. This would have been populated 
               # when the exception (that was just caught) was thrown.
      return 1;
   }
   else  # If control reaches here, the exception was not created by these 
         # set of exception classes. Hence create a corresponding general 
         # exception. It was already thrown and is being caught now.
   {
      my $errmsg = $@;
      $@ =~ s/\n//g;
      $@ =~ m/at (\S*) line (\d*)[\.]*$/;
      $_EXCEPTION_ = new tfactlexceptions("GeneralException", $errmsg, 0, $1, $2);
    
      if (defined($_EXCEPTION_))
      {
        $_EXCEPTIONSTRING_ = "\nUnrecognized exception";
        if (defined ($_EXCEPTION_->{_TYPE_}))
        {    
           $_EXCEPTIONSTRING_ = $_EXCEPTIONSTRING_ . "\nType :" .
                                          $_EXCEPTION_->{_TYPE_};
        } 
        if (defined($_EXCEPTION_->{_ERRMSG_}))  
        {
           $_EXCEPTIONSTRING_ = $_EXCEPTIONSTRING_ . "\nMessage :" . 
                                          $_EXCEPTION_->{_ERRMSG_};
        }
        if (defined($_EXCEPTION_->{_FILE_}))
        {
           $_EXCEPTIONSTRING_ = $_EXCEPTIONSTRING_ . "\nFile :" .
                                          $_EXCEPTION_->{_FILE_};
        }
        if (defined($_EXCEPTION_->{_LINE_}))
        {
           $_EXCEPTIONSTRING_ = $_EXCEPTIONSTRING_ . "\nLine :" . 
                                          $_EXCEPTION_->{_LINE_} . "\n";
        }
     }     
     return 2;
   }
}

########
# NAME
#   new
#
# DESCRIPTION
#   This routine creates an exception of type tfactlexceptions
#
# PARAMETERS
#   ($class) - This is passed implicitely when this function is called.
#   $type    - The type of the exception, usually a String like
#              "XML Exception"
#   $errmsg  - The error message associated with this exception
#   $package - The package where this exception was raised.
#   $file    - The file in which this exception was raised.
#   $lineno  - The line number in the file where the exception occured.
#
# RETURNS
#   A new instance of this exception class
#
########
sub new
{
   my $class = shift;
 
   my $self = {_TYPE_ => shift,
               _ERRMSG_ => shift,
               _PACKAGE_ => shift,
               _FILE_ => shift,
               _LINE_ => shift
              };
   bless $self, $class;
   $_EXCEPTION_       = $self;
   $_HASBEENCAUGHT_   = 0;
   $_NOEXCEPTIONSYET_ = 0;
   return $self;
}

########
# NAME
#   tfactlexceptions::throw
#
# DESCRIPTION
#   This routine throws an exception of type tfactlexceptions
#
# PARAMETERS
#   None.
#
# RETURNS
#   The last staement of this function is die, which raises the exception. 
########
sub tfactlexceptions::throw
{
   my $class = shift;
   my ($package, $filename, $line) = caller;

   my $newException = new tfactlexceptions($class, "General Exception", 
                                           $package, $filename, $line);
   push (@_EXCEPTIONLIST_, $newException);
   die "General Exception raised.";
}

########
# NAME
#   tfactlexceptions::getType
#
# DESCRIPTION
#   This accessor routine returns the type of the most recent exception
#
# PARAMETERS
#   None.
#
# RETURNS
#   The type of the last exception to be raised
########
sub tfactlexceptions::getType
{
   return $_EXCEPTION_->{_TYPE_};
}

########
# NAME
#   tfactlexceptions::geyErrmsg
#
# DESCRIPTION
#   This accessor routine returns the error messsage of the most recent
#   exception.
#
# PARAMETERS
#   None.
#
# RETURNS
#   The error messsage associated with the last exception to be raised
########
sub tfactlexceptions::getErrmsg
{
   return $_EXCEPTION_->{_ERRMSG_};
}

########
# NAME
#   tfactlexceptions::noexceptions
#
# DESCRIPTION
#   This routine can be sued to check whether there is any exceptions pending
#
# PARAMETERS
#   None.
#
# RETURNS
#   1 - If there are no exceptions to be caught.
#   0 - if there is an exception to be caught
########
sub tfactlexceptions::noexceptions
{
   return 1 if($_NOEXCEPTIONSYET_ || $_HASBEENCAUGHT_);
   return 0;
}

sub tfactlexceptions::getExceptionstring
{
  return $_EXCEPTIONSTRING_
}
1;

