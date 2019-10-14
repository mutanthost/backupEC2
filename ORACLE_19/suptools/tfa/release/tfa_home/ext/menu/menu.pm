# 
# $Header: tfa/src/v2/ext/menu/menu.pm /main/9 2018/08/08 23:01:02 recornej Exp $
#
# menu.pm
# 
# Copyright (c) 2016, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      menu.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    08/04/18 - Fix bug 28446141.
#    recornej    07/16/18 - Remove format adjustment as is not needed.
#    recornej    05/23/17 - XbranchMerge recornej_bug_26046762 from
#                           st_tfa_12.2.1.1.01
#    recornej    05/11/17 - Bug 26046762 - TFA MENU OPTIONS NO WORKING ON
#                           TFACTL SHELL
#    recornej    05/09/17 - Utilities menu in Windows is showing the wrong Menu
#    recornej    04/25/17 - Bug 25954627 - TFA MENU DOES NOT WORK PROPERLY FOR
#                           SOME COMMANDS
#    recornej    02/16/17 - New menu update
#    bibsahoo    06/06/16 - Change Function name tfactlshare_get_tfa_base
#    gadiga      05/17/16 - remove debug
#    bburton     02/05/16 - Menu driver
#    bburton     02/05/16 - Creation
# 
####
#
package menu;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(deploy
                 autostart
                 start
                 stop
                 restart
                 status
                 run
                 runstatus
                 is_running
                 help
                 ext_menu_read_xml
                 ext_menu_print_menu
                );

use strict;
#use warnings;
#use diagnostics;
use Math::BigInt;
use tfactlglobal;
use tfactlshare;

use List::Util qw[min max];
use POSIX qw(:termios_h);

use File::Basename;
use File::Spec::Functions;
use File::Path;
use Getopt::Long;

#use constant TRUE                      =>  "1";
#use constant FALSE                     =>  "0";
#$EXADATA ="1";
#$IS_WINDOWS = "1";

our @menuoptions;
our @promptdata;
my $tool = "menu";
my $debug = "0";
my $tfa_base = ".";
$|=1;
#my $tfa_base = tfactlshare_get_repository_location($tfa_home);
my $tool_dir = catfile($tfa_base, "suptools", "$hostname", $tool);
my $tool_base = catfile($tfa_base, "suptools", "$hostname", $tool, $current_user);

sub deploy
{
  my $tfa_home = shift;

  return 0;
}

sub is_running
{
  return 2;
}

sub runstatus
{
  return 3;
}

sub autostart
{
  return 0;
}

sub start
{
  print "Nothing to do !\n";
  return 1;
}

sub stop
{
  print "Nothing to do !\n";
  return 1;
}

sub restart
{
  print "Nothing to do !\n";
  return 1;
}

sub status
{
  print "Menu does not run in daemon mode\n";
  return 1;
}

sub run
{
no strict 'vars';

my $tfa_home = shift;
my @args = @_;
my $db = "";
my $easycs = "";
my $startmenu = "mainmenu";
my %options = ( "startmenu"    => \$startmenu,
                "h"            => \$help,
                "help"         => \$help );
#my %supported_Platforms = ( "1" => "Unix",
#                            "2" => "Unix/Windows",
              #                         );

my @arrayoptions = ( "startmenu=s",
                     "h",
                     "help" );

GetOptions(\%options, @arrayoptions )
or $unknownopt = 1;

if ( $help || $unknownopt )
{
    help();
    return 1;
}

tfactlshare_trace(5, "tfactl (PID = $$) menu run " .
                    "Running menu", 'y', 'y');
tfactlshare_trace(5, "tfactl (PID = $$) menu run " .
                    "Args received @args", 'y', 'y');
ext_menu_print_menu($tfa_home);
}

########
### NAME
###   ext_menu_print_menu
###
### DESCRIPTION
###   This function reads the profile
###
### PARAMETERS
###   $tfa_home        (IN) - TFA Home
###
### RETURNS
###   %tools
###
##########
sub ext_menu_print_menu
{
   my $tfa_home = shift;
   my $tfa_menu_xml = catfile($tfa_home,"ext","menu","tfa_menu.xml");
   my $choice = "M";
   my $selected_menu = "main";
   my $selectnumber = "0";
   my @menu_history;
   my %menuitems;
   my @options;
   my @prompts;
   my $arrsize;
   my $bme_options="\n\n    (B)ack   (M)ain   (H)elp   E(x)it\n\n";
   my $header_line= "Trace File Analyzer Collector Menu System\n";
   my $header_uline= "=========================================\n\n";
   my $choice_line="    Please enter your selection : ";
   my $tfabin = catfile($tfa_home,"bin");
   push (@menu_history, $selected_menu);
   while ( $choice !~ /[Xx]/ ) {
       ext_menu_cls();
       if ( $choice =~ /[Mm]/) {
          $selected_menu = "main";
          undef @menu_history;
          push (@menu_history, $selected_menu);
       } elsif ( $choice =~ /[Bb]/ && scalar(@menu_history) gt "1")  {
          pop(@menu_history); 
          $arrsize = @menu_history;
          $selected_menu = $menu_history[$arrsize-1]; 
       }
       print "menu history size : " . scalar(@menu_history) . "\n" if $debug;
       print "choice $choice\n" if $debug;
       print "selected $selected_menu\n" if $debug;
       print "@menu_history\n" if $debug;
       
       my (%menuitems) = ext_menu_read_xml($selected_menu, $tfa_home, $tfa_menu_xml);

       print_stuff() if $debug;

       #Printing the actual Menu here.
       print $header_line;
       print $header_uline;

       my $formatted_text = $menuitems{'text'};
       my $formatted_help = $menuitems{'help'};
       $formatted_text =~ s/LFEED/\n/g;
       $formatted_text =~ s/SBRK/(/g;
       $formatted_text =~ s/EBRK/)/g;
       $formatted_help =~ s/LFEED/\n/g;
       $formatted_help =~ s/SBRK/(/g;
       $formatted_help =~ s/EBRK/)/g;
   
       print "$menuitems{'title'}\n\n";
       if ( $choice =~ /[Hh]/) {
           print "$formatted_help";
       } else {
           print "$formatted_text";
       }  
       print $bme_options;
       print $choice_line;
       $choice = <STDIN>;
       $choice =~ s/\r\n//g;
       chomp($choice);

   $selectnumber="0";
   # Work out what to do ..
   if ( $choice =~ /[0-9]/ ) # made a new menu or action choice
   {
      #parse the options and work out what to do ..
       foreach my $row (0..@menuoptions-1)
       {  
           #foreach my $column (0..@{$menuoptions[$row]}-1)
           #{
                #option number is always at column 0
                if ( $choice eq $menuoptions[$row][0] ) {
                   print "chose : $menuoptions[$row][0]\n" if $debug;
                   $selectnumber = $choice;
                   if ( "menu" eq $menuoptions[$row][1] ) {
                      my $prev_menu = $selected_menu;
                      $selected_menu = $menuoptions[$row][2];
                      
                      #Check for Menu Availability
                      my $isAvailable = ext_menu_checkMenuAvailability(\$selected_menu,$menuoptions[$row][3]);
                      if($isAvailable ne "1"){
                        $selected_menu = $prev_menu;
                        pop(@menu_history);
                      }
                      
                      #Check for user access 
                      my $grant_access = ext_menu_checkUserAccess($menuoptions[$row][4],"Menu");
                      if($grant_access ne "1"){
                        $selected_menu = $prev_menu;
                        pop(@menu_history);
                      } 
                      push (@menu_history, $selected_menu);
                   } else { # Must be an action
                     
                     #Check for commands not allowed in Windows
                     if($IS_WINDOWS && $menuoptions[$row][3] ne "Unix/Windows" && $menuoptions[$row][3] ne "Windows"){
                       print "\nCommand not supported by this platform\n";
                       ext_menu_pause();
                      }
                      #Check for user access
                      my $grant_access = ext_menu_checkUserAccess($menuoptions[$row][4],"Command");
                      if($grant_access ne "1"){
                        last;
                      }

                      print "Will run $menuoptions[$row][2]\n" if $debug;
                      #Do we have any params to get.
                      if ( $menuoptions[$row][2] =~ /(%[0-9a-z]+)/ || $menuoptions[$row][2] =~ /^tfactl\s/ ) {
                         print "before replace $menuoptions[$row][2]\n" if $debug;
                         my $checkInput = "1";
                         my $prvDate = "";
                         # We have a variable to fill..
                         foreach my $row2 (0..@promptdata-1)
                         { 
                            print "$promptdata[$row2][0] \n " if $debug;
                            print "$promptdata[$row2][1] \n " if $debug;
                            print "$promptdata[$row2][2] \n " if $debug;
                            if ( $choice eq $promptdata[$row2][0] ) {
                               my $prompt = format_prompt($promptdata[$row2][2]);
                               print "$prompt: ";
                               my $input = <STDIN>;
                               $input =~ s/\r\n//g;
                               chomp($input);
                               if($promptdata[$row2][1] eq "sincetime"){
                                 if($input eq ""){
                                   $input="12h";
                                 } elsif($input !~ /[1-9][0-9]*(d|h)/){
                                    print "\n\tThe input you provide is incorrect.\n\tYou should enter e.g 20d 20h and must be grater than 0\n";
                                    $checkInput ="0";
                                    ext_menu_pause();
                                    last;
                                  }
                                  
                               }elsif($promptdata[$row2][1] eq "local"){
                                 if($input ne ""){
                                   $input=lc($input);
                                   if($input !~ /(y|n)/g){
                                     print"\n Not a valid input \n";
                                     $checkInput="0";
                                     ext_menu_pause();
                                     last;
                                   } elsif($input eq "y"){
                                     $input = "-local";
                                   } else{
                                     $input="";
                                   }
                                 }
                               }elsif($promptdata[$row2][1] eq "number" || $promptdata[$row2][1] eq "sizevalue"){
                                 if($input !~ m/[1-9][0-9]*/){
                                   print "\n\t The input must be a number\n";
                                   $checkInput ="0";
                                   ext_menu_pause();
                                   last;
                                 }
                               }elsif($promptdata[$row2][1] eq "older"){
                                  if($input !~ m/[1-9][0-9]*(h|d)/){
                                    print"\n\tInput must be n<h|d>\n";
                                    $checkInput ="0";
                                    ext_menu_pause();
                                    last;
                                  }
                               }elsif($promptdata[$row2][1] eq "all"){
                                  if($input =~ m/[yY]/g){
                                     $input =~ s/[yY]/all/;
                                  }elsif($input =~ m/[nN]/g){

                                     $input =~ s/[nN]//;
                                  }else{
                                    print "Not a valid input\n";
                                    $checkInput="0";
                                    ext_menu_pause();
                                    last;
                                  }
                               }elsif($promptdata[$row2][1] eq "exact"){
                                 if($input=~ m/[yY]/g){
                                    $input=~ s/[yY]/-exact/;
                                 } elsif($input =~ m/[nN]/g) {
                                    $input =~ s/[nN]//;
                                 } else{
                                   print "Not a valid input, you must enter [y|Y|N|n]\n";
                                   $checkInput ="0";
                                   ext_menu_pause();
                                   last;
                                 }
                               } elsif ($promptdata[$row2][1] eq "sincehours"){
                                   if($input !~ /[1-9][0-9]*/){
                                      print "Input must be a number of hours";
                                      $checkInput = "0";
                                      ext_menu_pause();
                                      last;
                                   }else{
                                       $input = $input . "h";
                                   }
                               }elsif($promptdata[$row2][1] eq "value"){
                                    $input = lc($input);
                                    if( $input ne "on"  && $input ne "off"){
                                       print "Incorrect, input must be <on|off>\n";
                                       $checkInput="0";
                                       ext_menu_pause();
                                       last;
                                    }
                               } elsif($promptdata[$row2][1] eq "level"){
                                 if($input !~ m/^(collect|scan|inventory|other):(1|2|3|4)$/gi){
                                   print "\nNot a valid input, you must enter <COLLECT|SCAN|INVENTORY|OTHER>:<1|2|3|4>\n";
                                   $checkInput="0";
                                   ext_menu_pause();
                                   last;
                                 } else{
                                   $input = uc($input);
                                 }
                               } elsif( $promptdata[$row2][1] eq "fortime" || 
                                       $promptdata[$row2][1] eq "fromtime" || 
                                       $promptdata[$row2][1] eq "totime" ){
                                  my $test = $input;
                                  my $isValid = getValidDateFromString($test,"time");
                                  if($isValid  eq "invalid"){
                                    print "\nThe date entered is either invalid or is not in the correct format: $test\n";
                                    $checkInput = "0";
                                    ext_menu_pause();
                                    last;
                                  }
                                  if($promptdata[$row2][1] eq "fromtime"){
                                      $prvDate = $test;
                                  }elsif($promptdata[$row2][1] eq "totime"){
                                      my $cmpdate = tfactlshare_cmp_timestamps($prvDate,$test);
                                      if($cmpdate != 0 && $cmpdate != 2){
                                        print "Time range entered is invalid.\n Start time should be before the end time.";
                                        $checkInput = "0";
                                        ext_menu_pause();
                                        last;
                                      }#end if $cmpdate
                                  }#end if totime
                                 
                               }#end if fortime,fromtime,totime
                               if ($promptdata[$row2][1] eq "fortime" 
                                 || $promptdata[$row2][1] eq "totime"
                                 || $promptdata[$row2][1] eq "fromtime"){

                                $menuoptions[$row][2] =~ s/%$promptdata[$row2][1]/\"$input\"/;

                              }elsif($promptdata[$row2][1] eq "database"){
                                if($input ne ""){
                                  $menuoptions[$row][2] =~ s/%$promptdata[$row2][1]/\"$input\"/;
                                }else{
                                  $menuoptions[$row][2] =~ s/%$promptdata[$row2][1]/$input/;
                                }
                              }else{
                                $menuoptions[$row][2] =~ s/%$promptdata[$row2][1]/$input/;
                              }
                              print "Will run " . $tfabin. "/" . "$menuoptions[$row][2]\n" if $debug;
                            }#end if choice
                         }#end foreach promptdata
                         print $menuoptions[$row][2] if $debug;
                         if ( $menuoptions[$row][2] =~ /^tfactl\s/ && $checkInput eq "1") {
                           print "\nRunning $tfabin" . "/" . "$menuoptions[$row][2]\n";
                           system($tfabin. "/" . $menuoptions[$row][2]);
                           print "\nFinished Running $tfabin" . "/" . "$menuoptions[$row][2]\n";
                           print "\nEnter to Continue :";
                           my $enter = <STDIN>;
                         }                     
                       }elsif($menuoptions[$row][2] eq "showports"){
                         #Show ports
                         my $tfa_ports    = catfile($tfa_home,"internal","port.txt");
                         print "\n+------------Ports -----------+\n";
                         if ( -f $tfa_ports){
                           system("$CAT", "$tfa_ports");
                         }else{
                           my $tfa_ports = catfile($tfa_home,"internal","usableports.txt");
                           system("$CAT", "$tfa_ports");
                         }
                         ext_menu_pause();
                       }
                     }
                }
           #}
       }
       if ( $selectnumber eq "0" ) {
          print "Not a valid selection\n"; 
          ext_menu_pause();
       }
     }
   } # end while choice is not E[xX]it 
  ext_menu_cls();
} # end sub ext_menu_print_menu

########
### NAME
###   ext_menu_checkMenuAvailability
###
### DESCRIPTION
###   This function checks if the selected menu
###   is available, selected menu is received as
###   reference to be change  for certains menus
###
### PARAMETERS
###	$selected_menu	  (IN)
### $platform_support (IN)
###
### RETURNS
### 
###  $isAvailable
##########
#
sub ext_menu_checkMenuAvailability{

  my $selected_menuref = shift;
  my $selected_menu= $$selected_menuref;
  my $platform_support = shift;
  my $isAvailable = "1";

  if($selected_menu eq "ODA"){
    if($IS_ODA ne "1" && $IS_ODADom0 ne "1" && $IS_ODALITE ne "1" ){
      print "\n Menu not available!\n Oracle Database Appliance (ODA) needed!\n";
      ext_menu_pause();
      $isAvailable="0";
    }
  }elsif ( $selected_menu eq "exadataDBM" ) {
    if ( $EXADATA ne "1" && $IS_EXADATADom0 ne "1" ) {
      print "\n Menu not available!\n Oracle Exadata DBMachine needed!\n";
      ext_menu_pause();
      $isAvailable="0";
    }
  }elsif( $selected_menu eq "engineered"
    && $EXADATA ne "1"
    && $IS_EXADATADom0 ne "1"
    && $IS_ODA ne "1"
    && $IS_ODADom0 ne "1"
    && $IS_ODALITE ne "1"
    && $IS_ZDLRA ne "1"){
    print"\n Menu not available!\n Engineered system needed!\n";
    ext_menu_pause();
    $isAvailable="0";
  }elsif( $selected_menu eq "utilities" ){
    if($IS_WINDOWS){
      $$selected_menuref.="Win";
    }
  }elsif ( $IS_WINDOWS && $platform_support ne "Unix/Windows" ) {
    print"\n Menu not supported by this platform\n";
    ext_menu_pause();
    $isAvailable="0";
   
  }elsif( $selected_menu eq "ZDLRA"){
    if($IS_ZDLRA ne "1" ){
      print"\n Menu not available!\n Oracle ZDLRA needed!\n";
      ext_menu_pause();
      $isAvailable="0"
    }
  }elsif($selected_menu eq "orachk/exachk"){
    if($EXADATA ne "1" && $IS_EXADATADom0 ne "1" ){
      $$selected_menuref="orachk";
    }
    else{
      $$selected_menuref="exachk";
    }
  }		      
  return $isAvailable;
}
########
### NAME
###   ext_menu_checkUserAccess
###
### DESCRIPTION
###   This function checks if the current user
###   has access to the selected menu or command
###
### PARAMETERS
###	$menu_optionaccess  (IN)
###	$type	      	    (IN)  (menu or command)
###
### RETURNS
### 
###  $grant_access
##########
#
sub ext_menu_checkUserAccess
{
  my $menu_optionaccess =shift;
  my $type =shift;
  my $grant_access ="1";
  if(!$IS_WINDOWS){
    if ( $menu_optionaccess eq "root" && $current_user ne "root" ){
      print "\n Access Denied. Only TFA Admin can use this $type.\n";
      ext_menu_pause();
      $grant_access="0";
    } elsif( $menu_optionaccess eq "non-root" && $current_user eq "root" ){
      print "\n $type must be run as an oracle privileged user - non root\n";
      ext_menu_pause();
      $grant_access="0";
    }
  }

  return $grant_access;
}
########
### NAME
###   ext_menu_cls
###
### DESCRIPTION
###   This function clears the screen
###
### PARAMETERS
###
### RETURNS
###
##########
#
sub ext_menu_cls()
{
   if ( $IS_WINDOWS ) {
      system("cls");
   } else {
      system("clear");
   }

}
########
### NAME
###   ext_menu_pause
###
### DESCRIPTION
###   This function waits for enter to continue
###
### PARAMETERS
###
### RETURNS
###
##########
#
sub ext_menu_pause()
{
    print "\n Press enter to Continue :";
    my $enter =<STDIN>;
}
########
## NAME
##   ext_menu_read_xml
##
## DESCRIPTION
##   This function reads the profile
##
## PARAMETERS
##   $tfa_home        (IN) - TFA Home
##   $tfa_menu        (IN) - menu to get
#
##   $tfa_menu_xml    (IN) - menu xml file
##
## RETURNS
##   %tools
##
#########
sub ext_menu_read_xml
{
  my $tfa_menu = shift;
  my $tfa_home = shift;
  my $tfa_menu_xml = shift;
  my %retitems = ();
  my @menutagsarray;
  my @menuentries;
  my ($promptattr, $promptname, $prompttext);
  my $title;
  my $text;
  my $help;
  my $value;

  tfactlshare_trace(5, "tfactl (PID = $$) " .
                    "ext_menu_read_xml " .
                    "File $tfa_menu_xml tfa_home $tfa_home",
                    'y', 'y');

  if ( -e "$tfa_menu_xml" )
  {
    undef(@menuoptions);
    undef(@promptdata);
    @menutagsarray = tfactlshare_populate_tagsarray($tfa_menu_xml);

    # Get top level tags <menus>
    my @menusList = tfactlshare_get_element(\@menutagsarray, 0,0);

    # For each menu .
    foreach my $menus (@menusList)
    {
       my @allmenus = tfactlshare_get_element(\@menutagsarray,
                           @$menus[ELEMLEVEL]+1, @$menus[ELEMNDX] );

    # For each menus get the menu .
       foreach my $menu (@allmenus)
       {
          my ($name,$value)=tfactlshare_get_attribute(@$menu[ELEMATTRNAME],@$menu[ELEMATTRVAL],"name");
          # Now get each of the items 
          my @menuItems = tfactlshare_get_element(\@menutagsarray,
                        @$menu[ELEMLEVEL]+1, @$menu[ELEMNDX] );

           if ( $value eq $tfa_menu ) {
              my $ndx1 = 0 ;
              my $ndx2 = 0 ;

              foreach my $menuItems ( @menuItems ) {
                 if (@$menuItems[ELEMNAME] eq "menu_option") {
                    #pull the number, type,action,support and access from the menu_option
                    my ($name,$optnum)=tfactlshare_get_attribute(@$menuItems[ELEMATTRNAME],@$menuItems[ELEMATTRVAL],"number");
                    my ($type,$opttype)=tfactlshare_get_attribute(@$menuItems[ELEMATTRNAME],@$menuItems[ELEMATTRVAL],"type");
                    my ($actname,$action)=tfactlshare_get_attribute(@$menuItems[ELEMATTRNAME],@$menuItems[ELEMATTRVAL],"action");
                    my ($supname,$support)=tfactlshare_get_attribute(@$menuItems[ELEMATTRNAME],@$menuItems[ELEMATTRVAL],"support");
		    my ($accname,$access)=tfactlshare_get_attribute(@$menuItems[ELEMATTRNAME],@$menuItems[ELEMATTRVAL],"access");

                    # Get all the prompts for this menu_option ( if any ) 
                    my @prompts = tfactlshare_get_element(\@menutagsarray,
                                @$menuItems[ELEMLEVEL]+1, @$menuItems[ELEMNDX] ); 
                    # add each of the prompts as a row to the promptdata array
                    foreach my $prompts ( @prompts ) {
                        ($promptattr, $promptname) = tfactlshare_get_attribute(@$prompts[ELEMATTRNAME],@$prompts[ELEMATTRVAL],"name");
                        $prompttext = @$prompts[ELEMVAL];
                        push (@{$promptdata[$ndx2]}, $optnum);
                        push (@{$promptdata[$ndx2]}, $promptname);
                        push (@{$promptdata[$ndx2]}, $prompttext);
                        $ndx2 ++;
                    }
                    # add each menu item as a row to the menu options array
                    push (@{$menuoptions[$ndx1]}, $optnum);
                    push (@{$menuoptions[$ndx1]}, $opttype);
                    push (@{$menuoptions[$ndx1]}, $action);
                    push (@{$menuoptions[$ndx1]}, $support);
		    push (@{$menuoptions[$ndx1]}, $access);
                    $ndx1++;
                 } # end if menu_option
              $retitems{@$menuItems[ELEMNAME]} = @$menuItems[ELEMVAL];
              } # end for each menuItems
              last;
           } # end if the right menu
       } # end for each menu
    } # end for each MenuList
  } else { # end if xml file exists
     print "File : $tfa_menu_xml  Does not exist\n";
     exit;
  }
  return %retitems;
}
sub print_stuff()
{
       foreach my $row (0..@menuoptions-1)
       {
           foreach my $column (0..@{$menuoptions[$row]}-1)
           {
                print "Element options [$row][$column] = $menuoptions[$row][$column]\n";
           }
       }

foreach my $row (0..@promptdata-1)
{
  foreach my $column (0..@{$promptdata[$row]}-1)
  {
    print "Element [$row][$column] = $promptdata[$row][$column]\n";
  }
}
}
sub format_prompt()
{
   my $instring = shift;
   print "formatting $instring\n" if ($debug);
   $instring =~ s/SSQB/\[/g; 
   $instring =~ s/ESQB/\]/g; 
   $instring =~ s/PRMT/\=\=\>/g; 
   print "returning $instring\n" if ($debug);
   return $instring;
}

