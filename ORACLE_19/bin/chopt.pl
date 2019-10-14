# 
# $Header: install/utl/chopt/chopt.pl /main/3 2017/04/19 23:28:17 vansoni Exp $
#
# chopt.pl
# 
# Copyright (c) 2009, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      chopt.pl - change (disable or enable) optional components
#
#    DESCRIPTION
#      this perl script is invoked by chopt (shell script) or chopt.bat, found
#      in ORACLE_HOME/bin.  
#
#      execute ORACLE_HOME/bin/chopt to see usage details
#
#    NOTES
#
#
#    MODIFIED   (MM/DD/YY)
#    vansoni     04/13/17 - Bug 25758159 Fix
#    poosrini    06/12/10 - removing db check and shipping this in server cmp
#    dschrein    03/24/09 - normalize path delimiters
#    dschrein    03/11/09 - prohibit execution unless
#                           oracle_install_db_InstallType is set
#    dschrein    03/10/09 - echo commands being run
#    dschrein    02/24/09 - creation
#

use File::Copy;
use POSIX;
use constant DATETIME => strftime("%Y-%m-%d_%H-%M-%S%p",localtime);

my $ohome = '/u01/app/oracle/product/19.0.0/dbhome_1';

$ohome =~ s,\\,/,g;
my $ini = "$ohome/bin/chopt.ini";

# output of oraBaseHomeUtil executable
my $OraBaseHome=`orabasehome`;
chomp $OraBaseHome;
# if OraBaseHome returns empty value,then set it to oracle_home as default value 
if ( $OraBaseHome eq "" ){
     $OraBaseHome=$ohome;
}
#--------------------------
#install directory where oaa.log is placed
my $logdir="$OraBaseHome/install";
#if logdir does not exist then set it to oracle_home/install location
if ( !-e $logdir ) {
     $logdir="$ohome/install";
}
#---------------------------
my $usage = "\nusage:\n\nchopt <enable|disable> <option>\n\noptions:\n" . &printopts . "\n\n";

my $action = $ARGV[0];
my $option = $ARGV[1];

# check command line validity
if ( @ARGV < 2 || ( $action ne 'disable' && $action ne 'enable' ) ) {
    die $usage;
}
unless ( grep /^$option$/, &getargs() ) {
    die "\nIncorrect option name: $option\n$usage";
}

# valid actions
my @valid_actions = qw ( run movefile );
# acceptable .ini enable/disable command options:
#   run      -- run the string as a system command
#   movefile -- call the move subroutine that does some file existence 
#               checking first

# logfile
# oaa.log is generated under the location created when read only oracle home is enabled
# else it will be under OracleHome/install when read only home is in disabled state.
my $logfile = "$logdir/${action}_${option}_".DATETIME.".log";
open LOGFILE, ">$logfile" or die "couldn't open $logfile:$!\n";
print "\nWriting to $logfile...\n";

# parse .ini file listing the available options and actions
#
open INI, "<$ini" or die "couldn't open $ini:$!\n";
my $in = 0;
my $extname;
my $err = 0;
while ( <INI> ) {
    if ( $in ) { # if we're already in the correct section of the ini file
        if ( /^option=(.*)/ ) { # we're on the line of the product external name
            $extname = $1;
        }
        if ( /^$action=(.*)/ ) {
        # action line:
        #   action=cmd_str1;cmd_str2;...;cmd_strn
        #     where a cmd_str is of the form:
        #     sub:arg_str
        #     e.g.
        #        enable=run:make part_on;run:make part_off (linux)
        #        enable=movefile:orapartop11.dll.dbl orapartop11.dll (NT)
        #
            my $actions_str = $1;
            chomp $actions_str;
            # split action line ("enable=..." or "disable=..." from .ini)
            # into individual command strings
            my @actions = split /;/, $actions_str;
            my $cmd_str;
            # loop through command strings for this action
            foreach $cmd_str ( @actions ) {
                if ( $cmd_str =~ /^(.*?):(.*?)$/ ) {
                    my $sub = $1;
                    my $args = $2;
                    # ensure a valid action/subroutine
                    if ( ! grep /^$sub$/, @valid_actions ) {
                        $err = 1;
                        print "\naction type ('", $sub, "') in .ini must be one of: ", join ' ', @valid_actions, "\n\n";
                        exit 1;
                    }
                    # run subroutine with same name as the action type
                    &$sub ( split /\s/, $args );
                }
                else {
                    die "\naction ('", $cmd_str, "') in .ini must be of the form:\n\taction:args\n";
                }
            }
            # all actions for enabling or disabling option have been processed
            last;
        }
    }
    if ( /^\[$option\]/ ) {
        # indicate that we are in the correct ini section
        $in = 1;
    }
}
close INI;
close LOGFILE;

#
# End main execution
#----------------------

#----------------------
# Begin subroutines
#

#foreach my $error ( @main::errs ) {
#    print $error, "\n";
#}

# one more newline at the end
print "\n";

sub getargs {
# return list of the possible "option" args for $usage
#
    my @a;
    open INI, "<$ini" or die "couldn't open $ini:$!\n";
    while ( <INI> ) {
        if ( /\[(.*?)\]/ ) {
            push @a, $1;
        }
    }
    return @a;
}

sub printopts {
# print out the possible option args and corresponding product names
#
    my %opts;
    open INI, "<$ini" or die "couldn't open $ini:$!\n";
    my $in;
    while ( <INI> ) {
        chomp;
        if ( $in ) {
            if ( /^option=(.*?)$/ ) {
                $opts{$in} = $1;
                $in = '';
                next;
            }
        }
        if ( /\[(.*?)\]/ ) {
            $in = $1;
        }
    }
    close INI;
    my $retval = '';
    my $lastkey;
    my $key;
    my $val;
    foreach $key ( sort keys %opts ) {
        $val = $opts{$key};
        $retval .= sprintf "%20s = %s\n", $key, $val;
        $lastkey = $key;
    }
    $retval .= "\ne.g. chopt enable $lastkey\n";
    return $retval;
}

sub run {
# run the args using backticks
    die "\nsub run called with incorrect number of args.  Expecting at least one, got '", @_, "'\n" unless @_ > 1;

    my $args = join ' ', @_;
    
    # echo and execute the statement and write output to LOGFILE
    print $args, "\n";
    print LOGFILE $args, "\n";
	print LOGFILE `$args`;
}

sub movefile {
# sub movefile ( $source, $destination )
#
    die "\nsub movefile called with incorrect number of args.  Expecting 2, got '", @_, "'\n" unless @_ == 2;
    my $src = shift;
    my $dest = shift;

# if destination is there, print already enabled/disabled
    if ( -e $dest ) {
        my $msg = "\n$dest already exists, Skipping \"move $src $dest\"\n";
        print $msg;
        print LOGFILE $msg;
        return;
    }

# if neither source nor dest exist, the home is in an invalid 
# state w/r/t the option
    if ( ! -e $src && ! -e $dest ) {
        my $msg = "\nNeither $src nor $dest exist.  Therefore, the ORACLE_HOME is in an invalid state with respect to the option '", $option, "'.\n";
        print LOGFILE $msg;
        die $msg;
    }

# now echo the command and try to move the file
	my $cmd = "movefile $src $dest\n";
    print $cmd, "\n";
    print LOGFILE $cmd, "\n";
    unless ( File::Copy::move ( $src, $dest ) ) {
        die "move $src $dest failed: $!" 
    }
    return 1;
}
