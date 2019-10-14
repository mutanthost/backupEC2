
#=============================================================================#
#                                                                             #
#            This script is used to reset the permissions/ownerships          #
#             of all files under CRS_HOME to the original settings            #
#              as well as some auxiliary files of RAC Installation            #
#                                                                             #
#                       Right now, for Linux/SunOS/AIX/HP                     #
#                                                                             #
#                     Author: jinrong zhang		                      #
#                     Version: v1.1                                           #
#=============================================================================#


#----------------------------- Change Logs -------------------------------
#
# --v1.0--:
#  12/20/2013 - Creation on Linux
#
# 
#-------------------------------- End ------------------------------------

################ Documentation ################
# The SYNOPSIS section is printed out as usage when incorrect parameters are passed
=head1 NAME

  reset_crshome.pl - reset the permissions/ownerships of all files under CRS_HOME to the original settings

=head1 SYNOPSIS

  reset_crshome.pl { -generate <baseline_file> | -compare <baseline_file> }
                   [-verbose]
                   [-version]
                   [-help]


  Options:
    -generate <baseline_file>        Generate a permission/ownership baseline file from a remote node
                                     which should have correct permission/ownership settings
    -compare <baseline_file>         Compare and reset permission/ownership of local CRS_HOME 
                                     based on a pre-Saved baseline file
    -[verbose]                       Print detailed execution info of this script
    -[version]                       Print current version of this script
    -[help|h|?]                      Print this help


=head1 DESCRIPTION

  This script is used to reset the permissions/ownerships of all files under CRS_HOME to the original settings.

=cut
################ End Documentation ################



use strict;
use warnings;
use Data::Dumper;
use English;
use Cwd 'abs_path';
use File::Basename;
use File::Spec;
use File::Spec::Functions qw(catdir rel2abs catfile);
use List::Util qw(max);
use IO::Handle qw(autoflush);
use Pod::Usage;
use POSIX qw/strftime/;
use POSIX ":sys_wait_h";
use Getopt::Long;
use Term::ANSIColor qw(:constants);
use Time::Local;
use Sys::Hostname;

$ENV{'LC_ALL'}='en_US.UTF-8' ;  # set English locale forcely


$| = 1 ; # flush perl's print buffer, equivalent to $OUTPUT_AUTOFLUSH = 1 ;




(getpwuid($<))[0] eq "root" or MsgPrint("E", "To ensure all proper directories/files can be accessed, please run this tool as root !\n") ;



our $VERSION = "1.1" ;



# Hostname info
our $HOSTNAME = hostname ;
# If IP address, do not strip.
$HOSTNAME !~ /(\d{1,3}\.){3}\d{1,3}/ && $HOSTNAME =~ s/^([^.]+)\..*/$1/ ; # strip domain name off hostname
our $hostname = lc($HOSTNAME) ;




# Platform info
our $PLATFORM = $^O ;



our ($AWK, $SED, $GREP, $EGREP, $ECHO, $ID, $WHOAMI, $EXPECT, $CAT, $CUT, $CP, $CHMOD, $CHOWN, $DATE, $DF, $STAT, $LS, $HEAD, $TAIL, $WC, $PSEF, $PSELF, $SSH, $SCP, $SORT, $RSH, $RCP, $RM, $SU, $SUDO, $DIFF, $UNZIP, $IFCONFIG, $TMP_DIR, $VAR_TMP_DIR) ;
our ($ORAINST, $ORATAB, $OCR_LOC, $OCR_LOC_DIR, $LASTGASP_DIR, $OPROCD_DIR, $SCLS_SCR_DIR, $ASMLIB_DIR) ;
#===================================================
# Unix Porting code here
#===================================================
if ( $PLATFORM eq "linux" ) {
  $AWK="/bin/awk";
  $SED="/bin/sed";
  $GREP="/bin/grep";
  $EGREP="/bin/egrep";
  $ECHO="/bin/echo";
  $ID="/usr/bin/id";
  $WHOAMI="/usr/bin/whoami";
  $EXPECT= "/usr/bin/expect";
  $CAT="/bin/cat";
  $CUT="/usr/bin/cut";
  $CP = "bin/cp";
  $CHMOD = "/bin/chmod";
  $CHOWN = "/bin/chown";
  $DATE="/bin/date";
  $DF = "/usr/bin/df";
  $STAT = "/usr/bin/stat";
  $LS = "/bin/ls" ;
  $HEAD = "/usr/bin/head" ;
  $TAIL="/usr/bin/tail";
  $WC="/usr/bin/wc" ;
  $PSEF = "/bin/ps -ef" ;
  $PSELF = "/bin/ps -elf";
  $SSH = "/usr/bin/ssh";
  $SCP = "/usr/bin/scp";
  $SORT = "/bin/sort";
  $RSH = "/usr/bin/rsh";
  $RCP = "/usr/bin/rcp";
  $RM = "/bin/rm";
  $SU = "/bin/su";
  $SUDO = "/utilities/sudo/sudo";
  $DIFF = "/usr/bin/diff";
  $UNZIP = "/usr/bin/unzip";
  $IFCONFIG = "/sbin/ifconfig";
  $TMP_DIR = "/tmp" ;
  $VAR_TMP_DIR = "/var/tmp" ;
  $ORAINST = "/etc/oraInst.loc";
  $ORATAB = "/etc/oratab" ;
  $OCR_LOC = "/etc/oracle/ocr.loc";
  $OCR_LOC_DIR = "/etc/oracle";
  $LASTGASP_DIR = "/etc/oracle/lastgasp";
  $OPROCD_DIR = "/etc/oracle/oprocd";
  $SCLS_SCR_DIR = "/etc/oracle/scls_scr";
  $ASMLIB_DIR = "/opt/oracle/extapi" ;
} elsif ( $PLATFORM eq "aix" ) {
  $AWK="/bin/awk";
  $SED="/bin/sed";
  $GREP="/bin/grep";
  $EGREP="/bin/egrep";
  $ECHO="/bin/echo";
  $ID="/bin/id";
  $WHOAMI="/bin/whoami";
  $EXPECT= "/usr/bin/expect";
  $CAT="/bin/cat";
  $CUT="/bin/cut";
  $CP = "bin/cp";
  $CHMOD = "/bin/chmod";
  $CHOWN = "/bin/chown";
  $DATE = "/bin/date";
  $DF = "/usr/bin/df";
  $STAT = "/usr/bin/stat";
  $LS = "/usr/bin/ls" ;
  $HEAD = "/usr/bin/head" ;
  $TAIL="/usr/bin/tail";
  $WC="/usr/bin/wc" ;
  $PSEF = "/bin/ps -ef" ;
  $PSELF = "/bin/ps -elf";
  $SSH = "/bin/ssh";
  $SCP = "/bin/scp";
  $SORT = "/bin/sort";
  $RSH = "/bin/rsh";
  $RCP = "/bin/rcp";
  $RM = "/bin/rm";
  $SU = "/bin/su";
  $SUDO = "/utilities/sudo/sudo";
  $DIFF = "/bin/diff";
  $UNZIP = "/bin/unzip";
  $TMP_DIR = "/tmp" ;
  $VAR_TMP_DIR = "/var/tmp" ;
  $ORAINST = "/etc/oraInst.loc";
  $ORATAB = "/etc/oratab" ;
  $OCR_LOC = "/etc/oracle/ocr.loc";
  $OCR_LOC_DIR = "/etc/oracle";
  $LASTGASP_DIR = "/etc/oracle/lastgasp";
  $OPROCD_DIR = "/etc/oracle/oprocd";
  $SCLS_SCR_DIR = "/etc/oracle/scls_scr";
  $ASMLIB_DIR = "/opt/oracle/extapi" ;
} elsif ( $PLATFORM eq "solaris" ) {
  if ( -e "/usr/xpg4/bin/awk" ) {
    $AWK="/usr/xpg4/bin/awk";
  } else {
    $AWK="/usr/bin/awk";
  }
  if ( -e "/usr/xpg4/bin/sed" ) {
    $SED="/usr/xpg4/bin/sed";
  } else {
    $SED="/usr/bin/sed";
  }
  if ( -e "/usr/xpg4/bin/grep" ) {
    $GREP="/usr/xpg4/bin/grep ";
  } else {
    $GREP="/usr/bin/grep";
  }
  if ( -e "/usr/xpg4/bin/egrep" ) {
    $EGREP="/usr/xpg4/bin/egrep";
  } else {
    $EGREP="/usr/bin/egrep";
  }
  if ( -e "/usr/xpg4/bin/cat" ) {
    $CAT="/usr/xpg4/bin/cat";
  } else {
    $CAT="/usr/bin/cat";
  }
  if ( -e "/usr/xpg4/bin/cut" ) {
    $CUT="/usr/xpg4/bin/cut";
  } else {
    $CUT="/usr/bin/cut";
  }
  if ( -e "/usr/xpg4/bin/du" ) {
    $DF="/usr/xpg4/bin/df";
  } else {
    $DF="/usr/bin/df";
  }
  if ( -e "/usr/xpg4/bin/head" ) {
    $HEAD="/usr/xpg4/bin/head";
  } else {
    $HEAD="/usr/bin/head";
  }
  if ( -e "/usr/xpg4/bin/tail" ) {
    $TAIL="/usr/xpg4/bin/tail";
  } else {
    $TAIL="/usr/bin/tail";
  }
  $WC="/usr/bin/wc" ;
  $LS = "/usr/bin/ls" ;
  $CP = "/usr/bin/cp";
  $CHMOD = "/bin/chmod";
  $CHOWN = "/bin/chown";
  $DATE="/usr/bin/date";
  $ECHO="/usr/bin/echo";
  $ID="/usr/bin/id";
  $WHOAMI="/usr/ucb/whoami";
  $EXPECT= "/usr/local/bin/expect";
  $PSEF = "/usr/bin/ps -ef" ;
  $PSELF = "/usr/bin/ps -cafe";
  $STAT = "/usr/bin/stat";
  $SSH = "/usr/bin/ssh";
  $SCP = "/usr/bin/scp";
  $SORT = "/usr/bin/sort";
  $RSH = "/usr/bin/rsh";
  $RCP = "/usr/bin/rcp";
  $RM = "/usr/bin/rm";
  $SU = "/usr/bin/su";
  $SUDO = "/utilities/sudo/sudo";
  $DIFF = "/usr/bin/diff";
  $UNZIP = "/usr/bin/unzip";
  $TMP_DIR = "/tmp" ;
  $VAR_TMP_DIR = "/var/tmp" ;
  $ORAINST = "/var/opt/oracle/oraInst.loc";
  $ORATAB = "/var/opt/oracle/oratab" ;
  $OCR_LOC = "/var/opt/oracle/ocr.loc";
  $OCR_LOC_DIR = "/var/opt/oracle";
  $LASTGASP_DIR = "/var/opt/oracle/lastgasp";
  $OPROCD_DIR = "/var/opt/oracle/oprocd";
  $SCLS_SCR_DIR = "/var/opt/oracle/scls_scr";
  $ASMLIB_DIR = "/opt/oracle/extapi" ;
} elsif ( $PLATFORM eq "hpux" ) {
  $AWK="/usr/bin/awk";
  $SED="/usr/bin/sed";
  $GREP="/usr/bin/grep";
  $EGREP="/usr/bin/egrep";
  $ECHO="/usr/bin/echo";
  $ID="/usr/bin/id";
  $WHOAMI="/usr/bin/whoami";
  $EXPECT= "/usr/local/bin/expect";
  $CAT="/usr/bin/cat";
  $CUT="/usr/bin/cut";
  $CP = "/usr/bin/cp";
  $CHMOD = "/bin/chmod";
  $CHOWN = "/bin/chown";
  $DATE="/bin/date";
  $DF = "/usr/bin/df";
  $STAT = "/usr/bin/stat";
  $LS = "/bin/ls" ;
  $HEAD = "/bin/head" ;
  $TAIL="/bin/tail";
  $WC="/bin/wc";
  $PSEF = "/usr/bin/ps -ef" ;
  $PSELF = "/usr/bin/ps -elf";
  $SSH = "/usr/bin/ssh";
  $SCP = "/usr/bin/scp";
  $SORT = "/usr/bin/sort";
  $RSH = "/usr/bin/remsh";
  $RCP = "/usr/bin/rcp";
  $RM = "/usr/bin/rm";
  $SU = "/usr/bin/su";
  $SUDO = "/utilities/sudo/sudo";
  $DIFF = "/usr/bin/diff";
  $UNZIP = "/usr/bin/unzip";
  $TMP_DIR = "/tmp" ;
  $VAR_TMP_DIR = "/var/tmp" ;
  $ORAINST = "/var/opt/oracle/oraInst.loc" ;
  $ORATAB = "/etc/oratab" ;
  $OCR_LOC = "/var/opt/oracle/ocr.loc";
  $OCR_LOC_DIR = "/var/opt/oracle";
  $LASTGASP_DIR = "/var/opt/oracle/lastgasp";
  $OPROCD_DIR = "/var/opt/oracle/oprocd";
  $SCLS_SCR_DIR = "/var/opt/oracle/scls_scr";
  $ASMLIB_DIR = "/opt/oracle/extapi" ;
} else {
  die "Error: Unknown Operating System: <$PLATFORM>\n" ;
}



# Perl trim function to remove whitespace from the start and end of the string
sub trim
{
  my $string = shift ;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string ;
}

# Left trim function to remove leading whitespace
sub ltrim
{
    my $string = shift ;
    $string =~ s/^\s+//;
    return $string ;
}

# Right trim function to remove trailing whitespace
sub rtrim
{
    my $string = shift ;
    $string =~ s/\s+$//;
    return $string ;
}

sub now
{
  print BOLD, BLUE, "Local Time Now :\t", RESET ;
  print strftime("%Y-%m-%d %H:%M:%S\n", localtime(time)), "\n" ;
}




sub Usage
{
  pod2usage(1) ;
}



my ($attr_fout, $attr_fin, $verbose, $help, $debug) ;
sub ParseArgs
{
  Getopt::Long::Configure("auto_version") ;
  my $return = GetOptions( "generate|g=s"  =>   \$attr_fout,
                           "compare|c=s"   =>   \$attr_fin,
                           "verbose"       =>   \$verbose,
                           "help|h|?"      =>   \$help,
                           "debug|d"       =>   \$debug,
                          ) ;

  if ( $return ne 1 || defined $help ) {
    Usage() ;
    exit 0 ;
  }

  if ( (defined $attr_fout && defined $attr_fin)  ||
       (!defined $attr_fout && !defined $attr_fin)  ) {
    print BOLD, RED, "ERROR: ", RESET ;
    print "Please specify exactly one of following mandatory options: { -generate | -compare }\n\n" ;
    Usage() ;
    exit -1 ;
  }

  if ( defined $attr_fout && $attr_fout eq "" ) {
    print "ERROR: <baseline_file> specified after option [-genereate] can't be empty !\n\n" ;
    Usage() ;
    exit -1 ;
  }

  if ( defined $attr_fin && $attr_fin eq "" ) {
    print "ERROR: <baseline_file> specified after option [-compare] can't be empty !\n\n" ;
    Usage() ;
    exit -1 ;
  }
}






# I - INFO: for normal information, always print to STDOUT
# E - ERROR: for error messages, always print to STDOUT, also the program will exit from this error
# W - WARNING: for warning messages, always print to STDOUT
# S - SUCCESS: for success messages, always print to STDOUT
# D - Debug: for debug only, print to STDOUT only when $debug flag is set
# V - Verbose: for verbose information, print to STDOUT only when $verbose or $debug flag is set
# Note: all kinds of output will also be copied to the log file
sub MsgPrint
{
  my ($type, $msg, $linenum) = @_;
  $linenum = "" unless defined $linenum ;

  if ( $type =~ /I/ ) {
    print BOLD, BLUE, "INFO: ", RESET ;
  } elsif ( $type =~ /E/ ) {
    print BOLD, RED, "ERROR: ", RESET ;
  } elsif ( $type =~ /W/ ) {
    print BOLD, MAGENTA, "WARNING: ", RESET ;
  } elsif ( $type =~ /S/ ) {
    print BOLD, GREEN, "SUCCESS: ", RESET ;
  } elsif ( $type =~ /V/ ) {
    print BOLD, BLUE, "INFO: ", RESET if (defined $verbose || defined $debug) ;
  } elsif ( $type =~ /D/ ) {
    print BOLD, YELLOW, sprintf("+[Debug][%8d]: \n", $linenum), RESET if (defined $debug) ;
  } else {
    #print FH "" ;
  }

  print "$msg" if ( defined $debug || (defined $verbose && $type =~ /V/) || ($type !~ /D|V/) ) ;

  DieTrap("Exiting...\n") if ($type =~ /E/) ;
}



# All die will come to here, so we can safely remove the lockfile in this routine
sub DieTrap
{
  my ($msg) = @_ ;
  die("$msg") ;
}







# Get CRS_HOME/ORACLE_HOME from orainst file
our ($ORA_INVENTORY, $CRS_HOME, $CRS_BASE, $CRS_OWNER, $CRS_GROUP, $CLUSTER_NAME, $ORA_DBA_GROUP, $ORA_ASM_GROUP) ;
my $ITEM_WID1 = 39 ;
sub Get_RAC_Environment
{
  if ( -f "$ORAINST" && -f "$ORATAB" ) {
    print "\n\n" ;

    chomp($ORA_INVENTORY = `$CAT $ORAINST | $GREP "inventory_loc=" | $CUT -d "=" -f2`) ;
    chomp($CRS_GROUP = `$CAT $ORAINST | $GREP "inst_group=" | $CUT -d "=" -f2`) ;

    if ( defined $ORA_INVENTORY ) {
      my $inventory_xml = "$ORA_INVENTORY/ContentsXML/inventory.xml" ;
      if ( -f "$inventory_xml" ) {
        chomp(my $tmp = `$GREP 'CRS="true"' $inventory_xml | wc -l`) ;
        if ( $tmp >= 1 ) {
          chomp($CRS_HOME=`$CAT $inventory_xml | $GREP 'CRS="true"' | $TAIL -1 | $CUT -d '"' -f4`) ;
        } else {
          chomp($CRS_HOME=`$CAT $inventory_xml | $GREP 'IDX="1"' | $GREP 'NAME="OraGI' | $CUT -d '"' -f4`) ;
        }

        if ( -f "$CRS_HOME/crs/install/crsconfig_params" ) {
          chomp($CLUSTER_NAME = `$CAT $CRS_HOME/crs/install/crsconfig_params | $GREP "^CLUSTER_NAME=" | $CUT -d '=' -f2`) ;
          chomp($ORA_DBA_GROUP = `$CAT $CRS_HOME/crs/install/crsconfig_params | $GREP "^ORA_DBA_GROUP=" | $CUT -d '=' -f2`) ;
          ($ORA_DBA_GROUP eq "") && ($ORA_DBA_GROUP = $CRS_GROUP) ;
          chomp($ORA_ASM_GROUP = `$CAT $CRS_HOME/crs/install/crsconfig_params | $GREP "^ORA_ASM_GROUP=" | $CUT -d '=' -f2`) ;
          ($ORA_ASM_GROUP eq "") && ($ORA_ASM_GROUP = $CRS_GROUP) ;
        }

        if ( defined $CRS_HOME ) {
          if ( -d "$CRS_HOME" ) {
            print BOLD, BLUE, sprintf("%-${ITEM_WID1}s\t", "CRS_HOME is installed at :"), RESET ;
            print "$CRS_HOME\n" ;
            $ENV{'ORACLE_BASE'} = "" ; # unset ORACLE_BASE so it won't affect the correct result of orabase
            $ENV{'ORACLE_HOME'} = $CRS_HOME ;
            system("$CHMOD 755 $CRS_HOME/bin/orabase") ;
            chomp($CRS_BASE = `$CRS_HOME/bin/orabase 2>/dev/null`) ;
            $CRS_BASE eq "" && chomp($CRS_BASE = `[ -f "$CRS_HOME/crs/install/crsconfig_params" ] && $CAT $CRS_HOME/crs/install/crsconfig_params | $GREP "ORACLE_BASE=" | $CUT -d "=" -f2`) ;
            print BOLD, BLUE, sprintf("%-${ITEM_WID1}s\t", "CRS_BASE is installed at :"), RESET ;
            print "$CRS_BASE\n" ;

            chomp($CRS_OWNER = `[ -f "$CRS_HOME/crs/install/crsconfig_params" ] && $CAT $CRS_HOME/crs/install/crsconfig_params | $GREP "ORACLE_OWNER=" | $CUT -d "=" -f2`) ;
            print BOLD, BLUE, sprintf("%-${ITEM_WID1}s\t", "CRS_OWNER is :"), RESET ;
            print "$CRS_OWNER\n" ;
            print BOLD, BLUE, sprintf("%-${ITEM_WID1}s\t", "CRS_GROUP is :"), RESET ;
            print "$CRS_GROUP\n" ;

            print "\n\n" ;
          } else {
            MsgPrint("E", "Can not find CRS_HOME dir \"$CRS_HOME\" on current node, please check it manually.\n");
          }
        } else {
          MsgPrint("E", "Can not get CRS_HOME from $inventory_xml, please check the inventory file manually.\n");
        }

      } else {
        MsgPrint("E", "Can not find file $inventory_xml under $ORA_INVENTORY/ContentsXML, please check it manually!\n");
      }      
     
    } else {
      MsgPrint("E", "Broken oraInst.loc file: the contents of the file $ORAINST is broken, please check it manually!\n");
    }
    
  } else {
    MsgPrint("E", "Can not find CRS Inventory File $ORAINST on your system, please make sure you have already installed CRS correctly!\n");
  }

}




sub Generate_Permission_Ownership_Baseline
{
  ( @_ != 1 ) && print BOLD, RED, "ERROR: Usage: Generate_Permission_Ownership_Baseline <baseline_file>", RESET && return ;

  my ($baseline_file) = @_ ;

  our $num_saved = 0 ;
  if ( -d $CRS_HOME ) {
    open(my $FH, ">$baseline_file") or die "Open file \"$baseline_file\" failed: $!\n" ;
    parse_dir_recursively("$TMP_DIR/.oracle", $FH) ;
    parse_dir_recursively("$VAR_TMP_DIR/.oracle", $FH) ;
    parse_dir_recursively($ORAINST, $FH) ;
    parse_dir_recursively($ORATAB, $FH) ;
    parse_dir_recursively($OCR_LOC_DIR, $FH) ;
    parse_dir_recursively($ASMLIB_DIR, $FH, "ORA_ASM_GROUP") ; # Rich asked to add : ASMLIB (and some other dynamically loaded libraries) for the Oracle executable default to the following location: /opt/oracle/extapi/[32,64]/{API}/{VENDOR}/{VERSION}/lib<apiname>.<ext>
    parse_dir_recursively($CRS_HOME, $FH) ;
    close $FH ;

    MsgPrint("I", "Total num of files/dirs saved : $num_saved\n") ;
    print "\n\n" ;
  } else {
    MsgPrint("E", "CRS_HOME \"$CRS_HOME\" isn't a valid dir on current node <$HOSTNAME> !\n") ;
  }
}




sub placeholder
{
  my ($text, $preferable_group) = @_ ;

  # make proper replacement for %VAR% here
  $text =~ s/$CLUSTER_NAME/%CLUSTER_NAME%/g ;
  $text =~ s/$hostname/%HOST%/g ;
  #$text =~ s/$host/%ID%/g ;

  $text =~ s/$CRS_OWNER/%HAS_USER%/g ;
  $text =~ s/root/%SUPERUSER%/g ;


  # on some env ORA_ASM_GROUP=ORA_DBA_GROUP, while on other env it could be that ORA_ASM_GROUP!=ORA_DBA_GROUP
  # so we must choose here which one is more preferable
  if ( $preferable_group eq "ORA_ASM_GROUP" ) {
    $text =~ s/$ORA_ASM_GROUP/%ORA_ASM_GROUP%/g ;
    $text =~ s/$ORA_DBA_GROUP/%ORA_DBA_GROUP%/g ;
  } else {
    $text =~ s/$ORA_DBA_GROUP/%ORA_DBA_GROUP%/g ;
    $text =~ s/$ORA_ASM_GROUP/%ORA_ASM_GROUP%/g ;
  }


  $text =~ s/Path="$VAR_TMP_DIR/Path="%VAR_TMP_DIR%/g ;
  $text =~ s/Path="$TMP_DIR/Path="%TMP_DIR%/g ;
  $text =~ s/Path="$ORAINST/Path="%ORAINST%/g ;
  $text =~ s/Path="$ORATAB/Path="%ORATAB%/g ;

  #$text =~ s/$CRS_BASE/%ORACLE_BASE%/g ;
  #$text =~ s/$CRS_HOME/%ORACLE_HOME%/g ;
  $text =~ s/$OCR_LOC_DIR/%OCRCONFIGDIR%/g ;
  #$text =~ s/$OPROCD_DIR/%OPROCDDIR%/g ;
  #$text =~ s/$LASTGASP_DIR/%OLASTGASPDIR%/g ;
  #$text =~ s/$SCLS_SCR_DIR/%SCRBASE%/g ;

  return $text ;
}





sub parse_dir_recursively
{
  my ($path, $FH, $preferable_group) = @_ ;
  !defined $preferable_group && ( $preferable_group = "ORA_DBA_GROUP" ) ; # the default more preferable group is set to ORA_DBA_GROUP

  my ($handle, $relativepath, $fullpath, $perm, $owner, $group, $line) ; 

  if ( -d $path ) { # if $path is a directory

    if ( opendir($handle, $path) ) {
      while ( my $object = readdir($handle) ) {
        if ( $object ne ".." ) {
          $fullpath = "$path/$object" ;
          if ( -d $fullpath && $object ne "." ) {
            parse_dir_recursively($fullpath, $FH, $preferable_group) ;
          } else {
            ($relativepath = $fullpath) =~ s/^$CRS_HOME\///g ;
            $perm  = sprintf("%04o", ((stat($fullpath))[2]) & 007777) ;
            $owner = getpwuid((stat($fullpath))[4]) ;
            $group = getgrgid((stat($fullpath))[5]) ;
            $line = "<File Path=\"$relativepath\" Name=\"\" Permissions=\"$perm\" Owner=\"$owner\" Group=\"$group\"/>" ;

            $line = placeholder($line, $preferable_group) ;
            print $FH "$line\n" ;
            our $num_saved = $num_saved + 1 ;
          }
        }
      }
      closedir($handle) ;
    }

  } elsif ( -f $path ) { # if $path is a file

    ($relativepath = $path) =~ s/^$CRS_HOME\///g ;
    $perm  = sprintf("%04o", ((stat($path))[2]) & 007777) ;
    $owner = getpwuid((stat($path))[4]) ;
    $group = getgrgid((stat($path))[5]) ;
    $line = "<File Path=\"$relativepath\" Name=\"\" Permissions=\"$perm\" Owner=\"$owner\" Group=\"$group\"/>" ;
    $line = placeholder($line, $preferable_group) ;
    print $FH "$line\n" ;
    our $num_saved = $num_saved + 1 ;

  } else {
    #
  }
}





sub translate
{
  my ($text) = @_ ;

  # make proper replacement for %VAR% here
  $text =~ s/%CLUSTER_NAME%/$CLUSTER_NAME/g ;
  $text =~ s/%HOST%/$hostname/g ;
  #$text =~ s/%ID%/$host/g ;

  $text =~ s/%HAS_USER%/$CRS_OWNER/g ;
  $text =~ s/%SUPERUSER%/root/g ;
  #$text =~ s/%LISTENER_USERNAME%/$CRS_OWNER/g ;
  #$text =~ s/%ORACLE_OWNER%/$CRS_OWNER/g ;
  $text =~ s/%ORA_DBA_GROUP%/$ORA_DBA_GROUP/g ;
  $text =~ s/%ORA_ASM_GROUP%/$ORA_ASM_GROUP/g ;

  $text =~ s/Path="%VAR_TMP_DIR%/Path="$VAR_TMP_DIR/g ;
  $text =~ s/Path="%TMP_DIR%/Path="$TMP_DIR/g ;
  $text =~ s/Path="%ORAINST%/Path="$ORAINST/g ;
  $text =~ s/Path="%ORATAB%/Path="$ORATAB/g ;

  #$text =~ s/%ORACLE_BASE%/$CRS_BASE/g ;
  #$text =~ s/%ORACLE_HOME%/$CRS_HOME/g ;
  #$text =~ s/%GPNPCONFIGDIR%/$CRS_HOME/g ;
  #$text =~ s/%GPNPGCONFIGDIR%/$CRS_HOME/g ;
  $text =~ s/%OCRCONFIGDIR%/$OCR_LOC_DIR/g ;
  #$text =~ s/%OPROCDDIR%/$OPROCD_DIR/g ;
  #$text =~ s/%OPROCDCHECKDIR%/$OPROCD_DIR\/check/g ;
  #$text =~ s/%OPROCDSTOPDIR%/$OPROCD_DIR\/stop/g ;
  #$text =~ s/%OPROCDFATALDIR%/$OPROCD_DIR\/fatal/g ;
  #$text =~ s/%OLASTGASPDIR%/$LASTGASP_DIR/g ;
  #$text =~ s/%SCRBASE%/$SCLS_SCR_DIR/g ;

  return $text ;
}




sub Reset_Permission_Ownership_Using_Baseline
{
  ( @_ != 1 ) && print BOLD, RED, "ERROR: Usage: Reset_Permission_Ownership_Using_Baseline <baseline_file>", RESET && return ;

  my ($baseline_file) = @_ ;

  if ( -d $CRS_HOME ) {

    if ( -f "$baseline_file" ) {
      open(my $FH, "<$baseline_file") or die "Open file \"$baseline_file\" failed: $!\n" ;

      my $total = 0 ;
      my $succeeded = 0 ;
      my $failed = 0 ;
      my $skipped = 0 ;
      while ( <$FH> ) {

        chomp(my $line = $_) ;

        # make proper replacement for %VAR% here
        $line = translate($line) ;

        my $object ;
        if ( $line =~ /^\s*<File Path="(.*)" Name="(.*)" Permissions="(\d+)" Owner="(.+)" Group="(.+)"\/>$/ ) {

          $object = ( (substr($1,0,1) eq "/" || substr($2,0,1) eq "/") ? catdir($1, $2) : catdir($CRS_HOME, $1, $2) ) ;

          if ( -e "$object" ) {

            system("$CHOWN $4:$5 $object") ;
            my $ret_code1 = $? ;
            $ret_code1 != 0 && MsgPrint("D", "Current line is : $line\nExecuting \"$CHOWN $4:$5 $object\" failed : $!\n", __LINE__) ;

            system("$CHMOD $3 $object") ;
            my $ret_code2 = $? ;
            $ret_code2 != 0 && MsgPrint("D", "Current line is : $line\nExecuting \"$CHMOD $3 $object\" failed : $!\n", __LINE__) ;

            MsgPrint("V", "changed permission/ownership of \"$object\" to $3/$4:$5\n") ;
            ++$total ;
            if ( 0 == $ret_code1 && 0 == $ret_code2 ) {
              ++$succeeded ;
            } else {
              ++$failed ;
            }
          } else {
            ++$skipped ;
            MsgPrint("D", "Skipped line is : $line\n", __LINE__) ;
            MsgPrint("V", "File/Dir \"$object\" doesn't exist\n") ;
          }

        } elsif ( $line =~ /^\s*<File Path="(.*)" Name="(.*)" Permissions="(\d+)"\/>$/ ) {

          $object = ( (substr($1,0,1) eq "/" || substr($2,0,1) eq "/") ? catdir($1, $2) : catdir($CRS_HOME, $1, $2) ) ;

          if ( -e "$object" ) {
            system("$CHMOD $3 $object") ;
            MsgPrint("V", "changed permission of \"$object\" to $3\n") ;
            ++$total ;
            if (0 == $?) {
              ++$succeeded ;
            } else {
              ++$failed ;
              MsgPrint("D", "Current line is : $line\nExecuting \"$CHMOD $3 $object\" failed : $!\n", __LINE__) ;
            }
          } else {
            ++$skipped ;
            MsgPrint("D", "Skipped line is : $line\n", __LINE__) ;
            MsgPrint("V", "File/Dir \"$object\" doesn't exist\n") ;
          }

        } elsif ( $line =~ /^\s*<File Path="(.*)" Name="(.*)" Owner="(.+)" Group="(.+)"\/>$/ ) {

          $object = ( (substr($1,0,1) eq "/" || substr($2,0,1) eq "/") ? catdir($1, $2) : catdir($CRS_HOME, $1, $2) ) ;

          if ( -e "$object" ) {
            system("$CHOWN $3:$4 $object") ;
            MsgPrint("V", "changed ownership of \"$object\" to $3:$4\n") ;
            ++$total ;
            if (0 == $?) {
              ++$succeeded ;
            } else {
              ++$failed ;
              MsgPrint("D", "Current line is : $line\nExecuting \"$CHOWN $3:$4 $object\" failed : $!\n", __LINE__) ;
            }
          } else {
            ++$skipped ;
            MsgPrint("D", "Skipped line is : $line\n", __LINE__) ;
            MsgPrint("V", "File/Dir \"$object\" doesn't exist\n") ;
          }

        } else { # if the $line isn't a well-formatted baseline text 
          #MsgPrint("D", "Skipped line is : $line\n", __LINE__) ;
        }

      }

      close $FH ;


      MsgPrint("I", "Total num of files/dirs changed   : $total\n") ;
      MsgPrint("I", "Total num of files/dirs succeeded : $succeeded\n") ;
      MsgPrint("I", "Total num of files/dirs failed    : $failed\n") ;
      MsgPrint("V", "Total num of files/dirs skipped   : $skipped\n") ;
      print "\n\n" ;

    } else {
      MsgPrint("W", "Software Config Baseline File \"$baseline_file\" doesn't exist on currect node <$HOSTNAME> !\n") ;
    }

  } else {
    MsgPrint("E", "CRS_HOME \"$CRS_HOME\" isn't a valid dir on current node <$HOSTNAME> !\n") ;
  }

}





sub Reset_Auxiliary_Files
{

}




sub Delete_TMP_Files
{
  MsgPrint("I", "Removing temporary socket files under $VAR_TMP_DIR/.oracle/ && $OCR_LOC_DIR/maps/\n") ;
  system("$RM -rf $TMP_DIR/.oracle/*") ;
  system("$RM -rf $VAR_TMP_DIR/.oracle/*") ;
  system("$RM -rf $OCR_LOC_DIR/maps/*") ;
  print "\n\n" ;
}







MAIN: {

  &ParseArgs ;

  &Get_RAC_Environment ;

  if ( defined $attr_fout ) {

    &Generate_Permission_Ownership_Baseline($attr_fout) ;

  } else {

    if ( -d $CRS_HOME ) {
      MsgPrint("I", "Resetting Permissions & Ownerships of current CRS_HOME to 755/$CRS_OWNER:$CRS_GROUP recursively in a batch first\n") ;
      system("$CHOWN -R $CRS_OWNER:$CRS_GROUP $CRS_HOME") ;
      system("$CHMOD -R 755 $CRS_HOME") ;
      print "\n\n" ;

      chomp(my $css_status = `$CRS_HOME/bin/crsctl check css 2>/dev/null`) ;
      if ( $css_status =~ /CRS-4529/ ) {
        MsgPrint("E", "Cluster Synchronization Services is still online, please stop it manually by \"crsctl stop crs -f\" first !\n") ;
      }

      &Delete_TMP_Files ;

      if ( defined $attr_fin ) {
        MsgPrint("I", "Resetting Permissions & Ownerships of current CRS_HOME using pre-Saved Baseline file \"$attr_fin\"\n") ;
        &Reset_Permission_Ownership_Using_Baseline($attr_fin) ;
        system("$CHOWN $CRS_OWNER:$CRS_GROUP $ORATAB") ; # handle possible <racusr> owned oratab file because <racusr1> in the baseline file could be <racusr2> in another env
      }

      # don't use $CRS_HOME/cv/cvdata/ora_software_cfg.xml here since its contents are not very correct, e.g.:
      #      <File Path="bin/" Name="setasmgidwrap" Permissions="0755"/>
      #      <File Path="bin/" Name="setasmgidwrap" Permissions="0750"/>
      #my $ora_software_cfg_file = "$CRS_HOME/cv/cvdata/ora_software_cfg.xml" ;
      #MsgPrint("I", "Resetting Permissions & Ownerships of current CRS_HOME using RAC CVU Baseline file \"$ora_software_cfg_file\"\n") ;
      #&Reset_Permission_Ownership_Using_Baseline("$ora_software_cfg_file") ;

      &Reset_Auxiliary_Files ;
    }

  }

}



1;
__END__






