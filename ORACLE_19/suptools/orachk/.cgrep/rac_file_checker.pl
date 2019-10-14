# 
# $Header: tfa/src/orachk_py/scripts/rac_file_checker.pl /main/4 2017/09/13 22:55:20 rojuyal Exp $
#
# rac_file_checker.pl
# 
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      rac_file_checker.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    rkchaura    10/24/16 - fileattr check
#    rkchaura    10/24/16 - Creation
 

use strict;
use File::Spec::Functions qw(rel2abs catfile catdir) ;
use File::Basename ;
BEGIN {
  push(@INC, dirname(rel2abs($0))) ;
}
use Config;
use File::Find;
use English;
use Cwd;
use List::Util qw(max);
use POSIX qw(strftime);

use rac_lib;

use constant TRUE  => "1";
use constant FALSE => "0";

use constant SUCCESS => "1";
use constant FAILED  => "0";

my $debug = FALSE ;



#check_user("root") ;



# Script agent should only have one parameter. It might be
# start/check/stop/clean
if ( scalar(@ARGV) < 1 ) {
  # Script should not enter here
  Logger "Action Parameter needs for the script: {start|stop|check|clean}\n";
  exit FAILED;
} elsif ( scalar(@ARGV) > 1 ) {
  # Script also should not enter here
  Logger "Too many parameters for the script: @ARGV\n" ;
  exit FAILED;
}

my $operation = $ARGV[0];

if ( $operation eq "stop" ) {
  $operation = "clean" ;
}


$EMAIL_FLAG = FALSE ;
unlink($EMAIL_TXT) ;


# SIGNAL Handler
$SIG{'__DIE__'} = sub { dietrap_mon(@_); } ;
$SIG{'INT'}     = sub { dietrap_mon(@_); } ;
$SIG{'SEGV'} = sub { dietrap_mon(@_); };





# Create the required PID record files and log file
my $pwd = getcwd();
my $out_dir = get_output_dir();  #Rajeev
my $pidfile = catfile( $out_dir, "pids" ); #Rajeev
unless ( -d $pidfile ) {
  mkdir $pidfile;
  chmod 0755, $pidfile;
}

my $logdir = catfile( $out_dir, "logs" ); #Rajeev
unless ( -d $logdir ) {
  mkdir $logdir;
  chmod 0755, $logdir;
}



# Redirect STDOUT/STDERR to the log file
open OUTFH, ">>", $EMAIL_TXT or die "Fail to open the $EMAIL_TXT due to $OS_ERROR !\n" ;
select OUTFH ;  # sets output to OUTFH
$| = TRUE    ;  # make unbuffered








sub translate
{
  my ($array) = $_[0] ;

  foreach my $item ( @$array ) {
    # make proper replacement for <VAR> here
    $item =~ s/<CLUSTER_NAME>/$CLUSTER_NAME/g ;
    $item =~ s/<HOST>/$HOST/g ;
    $item =~ s/<ID>/$HOST/g ;
    $item =~ s/<HAS_USER>/$CRS_OWNER/g ;
    $item =~ s/<SUPERUSER>/root/g ;
    $item =~ s/<LISTENER_USERNAME>/$CRS_OWNER/g ;
    $item =~ s/<ORACLE_OWNER>/$CRS_OWNER/g ;
    $item =~ s/<ORA_DBA_GROUP>/$ORA_DBA_GROUP/g ;
    $item =~ s/<ORA_ASM_GROUP>/$ORA_ASM_GROUP/g ;
    $item =~ s/<VAR_TMP_DIR>/$VAR_TMP_DIR/g ;
    $item =~ s/<TMP_DIR>/$TMP_DIR/g ;
    $item =~ s/<ORAINST>/$ORAINST/g ;
    $item =~ s/<ORATAB>/$ORATAB/g ;
    $item =~ s/<CRS_BASE>/$CRS_BASE/g ;
    $item =~ s/<CRS_HOME>/$CRS_HOME/g ;
    $item =~ s/<GPNPCONFIGDIR>/$CRS_HOME/g ;
    $item =~ s/<GPNPGCONFIGDIR>/$CRS_HOME/g ;
    $item =~ s/<OCRCONFIGDIR>/$OCR_LOC_DIR/g ;
    $item =~ s/<OPROCDDIR>/$OPROCD_DIR/g ;
    $item =~ s/<OPROCDCHECKDIR>/$OPROCD_DIR\/check/g ;
    $item =~ s/<OPROCDSTOPDIR>/$OPROCD_DIR\/stop/g ;
    $item =~ s/<OPROCDFATALDIR>/$OPROCD_DIR\/fatal/g ;
    $item =~ s/<OLASTGASPDIR>/$LASTGASP_DIR/g ;
    $item =~ s/<SCRBASE>/$SCLS_SCR_DIR/g ;

    if ( $item =~ /<INIT_OHASD>/ ) {
      shift(@$array) ;
      if ( $PLATFORM eq "linux" ) {
        if ( -e "/etc/SuSE-release" ) { # SuSE Linux
          unshift(@$array, "/etc/ohasd") ;
          unshift(@$array, "/etc/rc.d/rc3.d/K15ohasd") ;
          unshift(@$array, "/etc/rc.d/rc3.d/S96ohasd") ;
        } else {
          unshift(@$array, "/etc/init.d/ohasd") ;
          unshift(@$array, "/etc/rc.d/init.d/ohasd") ;
          unshift(@$array, "/etc/rc.d/init.d/init.ohasd") ;
          unshift(@$array, "/etc/rc.d/rc3.d/K09ohasd") ;
          unshift(@$array, "/etc/rc.d/rc3.d/S13ohasd") ;
          unshift(@$array, "/etc/init/oracle-ohasd.conf") ;
          unshift(@$array, "/etc/init/oracle-tfa.conf") ;
        }
      } elsif ( $PLATFORM eq "solaris" ) {
        unshift(@$array, "/etc/init.d/ohasd") ;
        unshift(@$array, "/etc/init.d/init.ohasd") ;
        unshift(@$array, "/etc/rc3.d/S96ohasd") ;
        unshift(@$array, "/etc/rcS.d/K19ohasd") ;
      } elsif ( $PLATFORM eq "aix" ) {
        unshift(@$array, "/etc/ohasd") ;
        unshift(@$array, "/etc/rc.d/rc2.d/K19ohasd") ;
        unshift(@$array, "/etc/rc.d/rc2.d/S96ohasd") ;
      } elsif ( $PLATFORM eq "hpux" ) {
        unshift(@$array, "/sbin/init.d/ohasd") ;
        unshift(@$array, "/sbin/init.d/init.ohasd") ;
        unshift(@$array, "/sbin/rc2.d/K001ohasd") ;
        unshift(@$array, "/sbin/rc3.d/S960ohasd") ;
      }
    }
  }
}

my (@include_dirs, @exclude_dirs) ;

if ( defined $ENV{'CHECK_DIRS'} && $ENV{'CHECK_DIRS'} ne '' ) {
  @include_dirs = split(",", $ENV{'CHECK_DIRS'}) ;
} else {
  my $check_dirs = get_attribute_value_from_env("CHECK_DIRS") ; #Rajeev
  if ( defined $check_dirs && $check_dirs ne '' ) {
    @include_dirs = split(",", $check_dirs) ;
    # save current value of attribute "CHECK_DIRS" back into rac_lib.pm, so that when GI stack is down, we can still use this value
    my $data = read_file(catfile($CWD, "rac_lib.pm")) ;
    $data =~ s/our\s+\$CHECK_DIRS\s*=.*/our \$CHECK_DIRS = "$check_dirs" ;/g ;
    #write_file(catfile($CWD, "rac_lib.pm"), $data) ; 
  } else {
    @include_dirs = split(",", $CHECK_DIRS) ;
  }
}

if ( defined $ENV{'UNCHECK_DIRS'} && $ENV{'UNCHECK_DIRS'} ne '' ) {
  @exclude_dirs = split(",", $ENV{'UNCHECK_DIRS'}) ;
} else {
  my $uncheck_dirs = get_attribute_value_from_env("UNCHECK_DIRS") ;
  if ( defined $uncheck_dirs && $uncheck_dirs ne '' ) {
    @exclude_dirs = split(",", $uncheck_dirs) ;
    # save current value of attribute "UNCHECK_DIRS" back into rac_lib.pm, so that when GI stack is down, we can still use this value
    my $data = read_file(catfile($CWD, "rac_lib.pm")) ;
    $data =~ s/our\s+\$UNCHECK_DIRS\s*=.*/our \$UNCHECK_DIRS = "$uncheck_dirs" ;/g ;
    #write_file(catfile($CWD, "rac_lib.pm"), $data) ;
  } else {
    @exclude_dirs = split(",", $UNCHECK_DIRS) ;
  }
}

translate(\@include_dirs) ;
translate(\@exclude_dirs) ;






#####################################################################
#
# This function is used to save current ACLs of $path into $hashref
#
# ACL format: Permission Owner Group Path
#
# Usage: get_dir_attr($path, $hashref)
#
#####################################################################
sub get_dir_attr
{
  my $path = $_[0] ;
  my $hash = $_[1] ;

  unless ( -e $path ) {
    Logger("Directory or File \"$path\" does not exist !\n") ;
    return ;
  }


  my ($handle, $fullpath) ; 
  if ( -d $path ) { # if $path is a directory

    if ( opendir($handle, $path) ) {
      while ( my $object = readdir($handle) ) {
        $fullpath = "$path/$object" ;

        my $can_skip = "false" ;
        foreach ( @exclude_dirs ) {
          if ( $fullpath =~ /$_/ ) {
            $can_skip = "true" ;
            last ;
          }
        }
        next if $can_skip eq "true" ;

        if ( $object eq ".." ) { # if this is the parent dir
          next ; # skip the parent dir
        } elsif ( -d $fullpath && $object ne "." ) { # if this is a sub dir, do it recursively
          get_dir_attr($fullpath, $hash) ;
        } else {
          no warnings;
          $fullpath = $path if $object eq "." ;
          $hash->{$fullpath}->{'p'} = sprintf("%04o", ((stat($fullpath))[2]) & 007777) ;
          $hash->{$fullpath}->{'o'} = getpwuid((stat($fullpath))[4]) ;
          $hash->{$fullpath}->{'g'} = getgrgid((stat($fullpath))[5]) ;
        }
      }
      closedir($handle) ;
    }

  } else {
    my $can_skip = "false" ;
    foreach ( @exclude_dirs ) {
      if ( $path =~ /$_/ ) {
        $can_skip = "true" ;
        last ;
      }
    }
    
    unless ( $can_skip eq "true" ) {
      $hash->{$path}->{'p'} = sprintf("%04o", ((stat($path))[2]) & 007777) ;
      $hash->{$path}->{'o'} = getpwuid((stat($path))[4]) ;
      $hash->{$path}->{'g'} = getgrgid((stat($path))[5]) ;
    }
  }

}





#####################################################################
#
# This function is used to parse dirs recursively
#
# Usage: parse_dir_recursively($path, $FH)
#
#####################################################################
sub parse_dir_recursively
{
  my ($path, $FH) = @_ ;

  my ($handle, $fullpath, $perm, $owner, $group, $line) ; 
  if ( -d $path ) { # if $path is a directory

    if ( opendir($handle, $path) ) {
      my @object = readdir($handle) ;
      my $elem ;
      foreach  $elem (@object) {
        if ($elem =~ /\s/) {
           print "\n===============\n",$elem,"\n==============\n";
           next ;
        }
        $fullpath = "$path/$elem" ;

        my $can_skip = "false" ;
        foreach ( @exclude_dirs ) {
          if ( $fullpath =~ /$_/ ) {
            $can_skip = "true" ;
            last ;
          }
        }
        next if $can_skip eq "true" ;

        if ( $elem eq ".." ) { # if this is the parent dir
          next ; # skip the parent dir
        } elsif ( -d $fullpath && $elem ne "." ) { # if this is a sub dir, do it recursively
          parse_dir_recursively($fullpath, $FH) ;
        } else {
          no warnings; #Rajeev added this line to supress warnings
          $fullpath = $path if $elem eq "." ;
          $perm  = sprintf("%04o", ((stat($fullpath))[2]) & 007777) ;
          $owner = getpwuid((stat($fullpath))[4]) ;
          #! defined $owner && $owner = sprintf("%s",(stat($fullpath))[4]) ;
          $group = getgrgid((stat($fullpath))[5]) ;
          #! defined $group && $group = sprintf("%s",(stat($fullpath))[5]) ;
          if ( ! defined $group )
          {
             $group = sprintf("%s",(stat($fullpath))[5]) ;
          }
          $line = "$perm $owner $group $fullpath" ;
          print $FH "$line\n" ;
        }
      }
      closedir($handle) ;
    }

  } else {
    my $can_skip = "false" ;
    foreach ( @exclude_dirs ) {
      if ( $path =~ /$_/ ) {
        $can_skip = "true" ;
        last ;
      }
    }
    
    unless ( $can_skip eq "true" ) {
      $perm  = sprintf("%04o", ((stat($path))[2]) & 007777) ;
      $owner = getpwuid((stat($path))[4]) ;
      $group = getgrgid((stat($path))[5]) ;
      $line = "$perm $owner $group $path" ;
      print $FH "$line\n" ;
    }
  }
}






#####################################################################
#
# This function is used to save current ACLs of $path into $save_file
#
# ACL format: Permission Owner Group Path
#
# Usage: save_dir_attr($path, $attr_file)
#
#####################################################################
sub save_dir_attr
{
  my $path      = $_[0] ;
  my $save_file = $_[1] ;

  unless ( -e $path ) {
    Logger("Directory or File \"$path\" does not exist !\n") ;
    return ;
  }
  
  my ($FH) ;
  open ($FH, ">>$save_file") or die "Can not open file \"$save_file\": $!\n" ;
  # $| = TRUE ; # make unbuffered

  parse_dir_recursively($path, $FH) ;

  close $FH ; 
}








#####################################################################
#
# This function is used to read baseline ACLs from $atttr_file into $hashref
#
# ACL format: Permission Owner Group Path
#
# Usage: read_attr_file($attr_file, $hashref)
#
#####################################################################
sub read_attr_file
{
  my $attr_file = $_[0] ;
  my $hashref   = $_[1] ;
  my ($FH, @lines) ;
  open ($FH, "<$attr_file") or die "Get atrribute from file \"$attr_file\" failed: $!\n" ;
  @lines = <$FH> ;
  close $FH ;

  foreach my $line ( @lines ) {
    chomp($line) ;
    if ( $line =~ /^\s*$/ ) { next ; }
    elsif ( $line =~ /^(\S+)\s+(\S+)\s+(\S+)\s+(.+)$/ ) {
      my $perm  = $1 ;
      my $owner = $2 ;
      my $group = $3 ;
      my $filename = $4 ;
      my $can_skip = "false" ;
      foreach ( @exclude_dirs ) {
        if ( $filename =~ /$_/ ) {
          $can_skip = "true" ;
          last ;
        }
      }
      next if $can_skip eq "true" ;
      
      $hashref->{$filename}->{'p'} = $perm  ;
      $hashref->{$filename}->{'o'} = $owner ;
      $hashref->{$filename}->{'g'} = $group ;
    } else {
      print "The attribute file \"$attr_file\" is broken !\n" ;
      exit -1 ;
    }
  }
}









#####################################################################
#
# This function is used to do the actual comparison work
# and output possible inconsistency in a kindly format
#
# Usage: do_comparison($hashref1, $hashref2)
#
#####################################################################
sub do_comparison
{
  my %dir1_attr = %{$_[0]} ;
  my %dir2_attr = %{$_[1]} ;
  

  my @dir1 = keys %dir1_attr ;
  my @dir2 = keys %dir2_attr ;

  
  my %union = () ;
  foreach ( @dir1 ) { ++$union{$_} ;  }
  foreach ( @dir2 ) { ++$union{$_} ;  }
  my @union = keys %union ;
  my @files_in_both      = sort ( grep { 2 == $union{$_} ; } @dir1 ) ;
  my @files_only_in_dir1 = sort ( grep { 1 == $union{$_} ; } @dir1 ) ;
  my @files_only_in_dir2 = sort ( grep { 1 == $union{$_} ; } @dir2 ) ;

    
  my @files_same = () ;
  my @files_diff = () ;
  foreach my $file ( @files_in_both ) {
    my $difference = "" ;
    "$dir1_attr{$file}{'p'}" ne "$dir2_attr{$file}{'p'}" && ( $difference .= "p" ) ;
    "$dir1_attr{$file}{'o'}" ne "$dir2_attr{$file}{'o'}" && ( $difference .= "o" ) ;
    #Following condition added by Rajeev
    if ( defined $difference && defined $dir1_attr{$file}{'g'} && defined $dir2_attr{$file}{'g'} )
    {
      "$dir1_attr{$file}{'g'}" ne "$dir2_attr{$file}{'g'}" && ( $difference .= "g" ) ;
    }
    $difference eq "" ? push(@files_same, $file) : push(@files_diff, [$file, $difference]) ;
  }
  ( @files_diff > 0 ) && ( $EMAIL_FLAG = TRUE ) ;

  
  my ($dir1, $dir2) ;
  $dir1 = "Baseline" ;
  $dir2 = "Current"  ;
  #print "Files/Directories differ before/after :\n\n" ; #Rajeev
  

  my $indent = max(length($dir1), length($dir2)) ;
  foreach my $item ( @files_diff ) {
      my $file       = $item->[0] ;
      my $difference = $item->[1] ;
      print "\"$file\" is different:\n" ;

      printf("%-${indent}s : ", $dir1) ;
      $difference =~ /p/ ? print sprintf("%10s ", $dir1_attr{$file}{'p'}) :
                           printf ("%10s ", $dir1_attr{$file}{'p'}) ;
      
      $difference =~ /o/ ? print sprintf("%10s ", $dir1_attr{$file}{'o'}) :
                           printf ("%10s ", $dir1_attr{$file}{'o'}) ;
        
      $difference =~ /g/ ? print sprintf("%10s ", $dir1_attr{$file}{'g'}) :
                           printf ("%10s ", $dir1_attr{$file}{'g'}) ;

      printf("%-20s\n", $file);
        

      printf("%-${indent}s : ", $dir2) ;
      $difference =~ /p/ ? print sprintf("%10s ", $dir2_attr{$file}{'p'}) : 
                           printf ("%10s ", $dir2_attr{$file}{'p'}) ;
        
      $difference =~ /o/ ? print sprintf("%10s ", $dir2_attr{$file}{'o'}) :
                           printf ("%10s ", $dir2_attr{$file}{'o'}) ;
        
      $difference =~ /g/ ? print sprintf("%10s ", $dir2_attr{$file}{'g'}) :
                           printf ("%10s ", $dir2_attr{$file}{'g'}) ;

      printf("%-20s\n\n", $file) ;
  }
}
























if ( $operation eq "start" ) {

  Logger "Start to monitor critical file attributes ...\n";

  close OUTFH ;
  exit 0 ;

} elsif ( $operation eq "stop" ) {

  close OUTFH ;
  exit 0 ;

} elsif ( $operation eq "check" ) {

  Logger "Checking critical file attributes ...\n" ;
  set_pid_record() ;

  #my @snapshots = glob("$out_dir/Snapshot*.txt") ; #Rajeev
  my @snapshots = glob(catfile( $out_dir, "Snapshot*.txt" )) ; #Gowtham
  my $snap_file = catfile( $out_dir, "Snapshot_" ); #Gowtham
  if ( 0 == scalar @snapshots ) { # if there's no any snapshot right now, then generate a new one
    my $attr_fout = $snap_file . strftime("%Y-%m-%d_%H-%M-%S",localtime) . ".txt" ;  #Rajeev
    map { save_dir_attr($_, $attr_fout) ; } @include_dirs ;
    Logger "Attribute file \"$attr_fout\" saved successfully !\n" ;
  } else {
    @snapshots = sort { ((stat($a))[9]) <=> ((stat($b))[9]) } @snapshots ;
    my (%dir1_attr, %dir2_attr) ;
    print "\n" ;
   # print "[" . get_current_time . "][Baseline: $snapshots[-1]]\n" ; #Rajeev
   # print "---\n" ; #Rajeev
    read_attr_file($snapshots[-1], \%dir1_attr) ;
    map { get_dir_attr($_, \%dir2_attr) ; } @include_dirs ;
    do_comparison(\%dir1_attr, \%dir2_attr) ;

    append_file($ALERT_LOG, read_file($EMAIL_TXT)) ;
    if ( $EMAIL_FLAG ) { # Report Email if set
      $EMAIL_ADDRESS = get_attribute_value_from_env("EMAIL") ; #Rajeev
      defined $EMAIL_ADDRESS && $EMAIL_ADDRESS ne "" && send_mail($EMAIL_ADDRESS, "*** Please Check Possible Wrong File/Directory attriubtes on Node $HOST ***", $EMAIL_TXT) ;
    }
  }


  remove_pid_record() ;
  close OUTFH ;

  select STDOUT ; # resets output to STDOUT
  $| = TRUE ;     # make unbuffered
  print read_file($EMAIL_TXT) ;
  exit 0 ;

} elsif ( $operation eq "clean" ) {

  # Kill the processes and quit
  my @pids = get_pid_numbers() ;
  foreach my $pid (@pids) {
    chomp $pid;
    # Check if it is valid checker process
    my @ps = exec_OS_cmd("$PSP $pid");
    shift @ps;
    if (@ps) {
      my $line = shift @ps;
      chomp $line;
      my @arr= split(" ",$line);
      $line=$arr[-1];
      if ( $PROGRAM_NAME =~ m/$line/ ) {
        kill 9, $pid;
      }
    }
  }
  if ( defined $PIDFILE && -f $PIDFILE ) { unlink $PIDFILE ; }
  close OUTFH ;
  exit 0 ;

} else {

  # Script should not enter here
  Logger "Some Error happens since script should not be here !\n" ;
  close OUTFH ;
  exit 1 ;

}






1;
__END__
