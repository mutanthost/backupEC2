# 
# $Header: tfa/src/orachk/src/raw_data_browser.pl /main/3 2017/08/11 17:38:19 rojuyal Exp $
#
# raw_data_browser.pl
# 
# Copyright (c) 2013, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      raw_data_browser.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    llakkana    02/19/13 - Script to create raw data browser report
#    llakkana    02/19/13 - Creation
# 

use warnings;
use strict;
use Getopt::Long;
use File::Find;

my $debug = 0;
my @temp;
my $colName;
my $attr1;
my $attr2;
my $attr3;
my $attr4;
my $attr5;
my $line;
my $fh;
my %files;
my @hosts;
my @switches;
my @cells;
my %dbs;
my %asmi;
my $key;
my $key1;
my $ele;
my %seInd;
my $sei_count = -1; #start end index counter
my $id_attr;
my @divs;
my $html;
my %os_param = ('sysctl' => 1,'aix_no'=>1,'etc_system'=>1,'kctune'=>1,'etc_project'=>1);
#Show os patches and packages under os params
#    Linux:       Packages:- package_rpm
#    AIx:-        Packages:- package_lslpp
#	          patches:- patches_instfix
#    Solaris:-    packages:- package_pkginfo
#		  patches:- showrev
#    HP-UX        patches:- show_patches
my %os_package = ('package_rpm'=>1,'package_lslpp'=>1,'package_pkginfo'=>1);
my %os_patch   = ('patches_instfix'=>1,'showrev'=>1,'show_patches'=>1);
my %newHash;
my $flFile;
my $opFile;
my %db_homes;
my %db_type;
my %show;
my $dbs_heads;
my $switch_heads;
my $cell_heads;
my $osp_heads;
############### End of Declaration of Global Variables #################

if ( @ARGV == 0 ) {
  print "Usage: Please give output directory or zip as input\n";
  exit;
}


find({ wanted => \&process, follow => 1 }, ${ARGV[0]});
sub process {
 @temp = split('/',$File::Find::fullname);
 $files{$temp[$#temp]} = $File::Find::fullname; 
}

#Output html file
@temp = split('/',$ARGV[0]);
$opFile = $temp[$#temp];
$opFile =~ s/([^_]*)_(.*)/$1_browse_$2.html/;
$opFile = $ARGV[0]."/$opFile";

if ( exists $files{'o_host_list.out'} ) {
 @hosts = parseLineFiles($files{'o_host_list.out'},"HOST");
 @hosts = sort @hosts;
}
if ( exists $files{'o_ibswitches.out'} ) {
 @switches =  parseLineFiles($files{'o_ibswitches.out'},"SWITCH");
 @switches = sort @switches;
}
if ( exists $files{'cells.out'} ) {
 @cells =  parseLineFiles($files{'cells.out'},"CELL");
 @cells = sort @cells;
}

#Get visibility of data
getVisibility();

#parse env file and get DB's and it's instances,ASM instances
parseEnvFile();

open(WF,">$opFile") || die "Can't Open file $opFile\n";

#Write Head section
$html = <<HTML;
<!DOCTYPE html>
<html>
  <head>
    <style>
      .button {
	 height:25px;
	 width:140px;
	 border:0px;
	 margin:5px 1px;
         font-weight:bold;
         cursor:pointer;
         background-color: whitesmoke; 
         color:black;
	}	
      #TID { color:black; position: fixed;right: 19.5%; }
      .h2c {
	 margin:2px 10px;
 	 font-size:1.3em;
      }
      .h2c1 {
         margin:2px;
         font-size:1.3em;
      }
      html,body {
        font-family: Lucida Grande,Lucida Sans,Arial,sans-serif;
        font-size: 14px;
	padding:0px;
	padding-top:2px;
	margin:0;
	height:99.5%;
      }
      #wrapper { position:relative; height:100%;}
      h1 {color:black;}
      h2 {color:black; background:white}
      h3 {color:black; background:white}
      a {color: #000000;} 
      li a {
        color: black;
     }
    </style>
    <script> 
     var report_format = "new";
     
function processForm()
{
    
    if (report_format == "old")
    {
        report_format = "new";
        var i;
	var tid = document.querySelectorAll(".button");	
	for (i = 0; i < tid.length; i++) 
        {
                tid[i].style.backgroundColor = "whitesmoke";
        }
	var tid = document.querySelectorAll("#TID");
	for (i = 0; i < tid.length; i++) 
        {
                tid[i].style.color = "black";
        }
        var bo = document.querySelectorAll(".button");
        for (i = 0; i < bo.length; i++) 
        {
                bo[i].style.color = "black";
        }
        var hc1 = document.querySelectorAll("h1");
        for (i = 0; i < hc1.length; i++) 
        {
                hc1[i].style.color = "black";
        }
        var hc2 = document.querySelectorAll("h2");
        for (i = 0; i < hc2.length; i++) 
        {
                hc2[i].style.color = "black";
        }
        var hc3 = document.querySelectorAll("h3");
        for (i = 0; i < hc3.length; i++) 
        {
                hc3[i].style.color = "black";
        }
	var hc3 = document.querySelectorAll("hr");
        for (i = 0; i < hc3.length; i++) 
        {
                hc3[i].style.backgroundColor = "#F2F5F7";
        }

	document.getElementById("TABS").style.background = "#F2F5F7";
	document.getElementById('results').innerHTML ="Switch to old format";
   }
   else
   {
        report_format = "old";
        var i;
	var tid = document.querySelectorAll("#TID");
        for (i = 0; i < tid.length; i++) 
        {
                tid[i].style.color = "#1C94C4";
        }
        var bo = document.querySelectorAll(".button");
        for (i = 0; i < bo.length; i++) 
        {
                bo[i].style.color = "#1C94C4";
        }
        var hc1 = document.querySelectorAll("h1");
        for (i = 0; i < hc1.length; i++) 
        {
                hc1[i].style.color = "blue";
        }
        var hc2 = document.querySelectorAll("h2");
        for (i = 0; i < hc2.length; i++) 
        {
                hc2[i].style.color = "blue";
        }
        var hc3 = document.querySelectorAll("h3");
        for (i = 0; i < hc3.length; i++) 
        {
                hc3[i].style.color = "blue";
        }
	var hc3 = document.querySelectorAll("hr");
        for (i = 0; i < hc3.length; i++) 
        {
                hc3[i].style.backgroundColor = "#AED0EA";
        }

	document.getElementById("TABS").style.background = "#AED0EA";
	document.getElementById('results').innerHTML ="Switch to new format";
    }
}
     function hideShow(inId,bEle) {
HTML
print WF $html;

$html = "";
$html  = ",'ASM'" if $show{'ASM'};
$html .= ",'DATABASE'" if $show{'DATABASE'};
$html .= ",'DB_SER'" if $show{'DB_SER'};
$html .= ",'SWITCH'" if $show{'SWITCH'};
$html .= ",'CELL'" if $show{'CELL'};
$html =~ s/^.//; #remove first char(,)
$html = "var divs = new Array($html);";
print WF $html;
$html = <<HTML;
    if (report_format == "old"){
      for ( var i = 0;i < divs.length;i++ ) {
        if ( inId == divs[i] ) {
          document.getElementById(divs[i]+'_B').style.background = "#D7EBF9";
          document.getElementById(divs[i]).style.display = "inline";
          document.getElementById(divs[i]+'_BODY').style.display = "inline";
        }
        else {
          document.getElementById(divs[i]+'_B').style.background = "whitesmoke";
          document.getElementById(divs[i]).style.display = "none";
          document.getElementById(divs[i]+'_BODY').style.display = "none";
        }
      }
   }
   else{
        for ( var i = 0;i < divs.length;i++ ) {
        if ( inId == divs[i] ) {
          document.getElementById(divs[i]).style.display = "inline";
          document.getElementById(divs[i]+'_BODY').style.display = "inline";
        }
        else {
          document.getElementById(divs[i]).style.display = "none";
          document.getElementById(divs[i]+'_BODY').style.display = "none";
        }
      }
  }

     }
    </script>
  </head>
HTML
print WF $html;

if ( $show{'ASM'} ) {
   $html = "<body style=\"background:#dddddd;\" onload=\"hideShow('ASM');\"> ";
}
elsif ( $show{'DATABASE'} ) {
   $html = "<body style=\"background:#dddddd;\" onload=\"hideShow('DATABASE');\"> ";
}
elsif ( $show{'DB_SER'} ) {
   $html = "<body style=\"background:#dddddd;\" onload=\"hideShow('DB_SER');\"> ";
}
elsif ( $show{'CELL'} ) {
   $html = "<body style=\"background:#dddddd;\" onload=\"hideShow('CELL);\"> ";
}
elsif ( $show{'SWITCH'} ) {
   $html = "<body style=\"background:#dddddd;\" onload=\"hideShow('SWITCH');\"> ";
}
else {
  $html = "<body style=\"background:#dddddd;\"> ";
}
$html .= "<div id=\"wrapper\"> ";
$html .= "<div style=\"width:65%;height:100%;background:white;margin:0 auto;\"> ";

print WF $html;

writeTabsSec();

#Head Section
print WF "<div id=\"HEAD\" style=\"height:30%;overflow-x:hidden;overflow-y:scroll;\">";
writeASMSec() if ($show{'ASM'});
writeDBSec() if ($show{'DATABASE'});
writeDBSerSec() if ($show{'DB_SER'});
writeCellSec() if ($show{'CELL'});
writeSwitchSec() if ($show{'SWITCH'});
print WF "</div>"; 

#Body sec
print WF "<hr style=\"height:4px;border:0px;background-color:#F2F5F7;\">";
print WF "<div id=\"BODY\" style=\"height:63%;overflow-x:scroll;overflow-y:scroll;\">";
print WF "<span id=\"Top\">&nbsp;</span>";
print WF "<a id=\"TID\" href=\"#Top\"> <b>Top</b> </a>";
for my $i ( 0 .. $#divs ) {
 $id_attr = "START".$i;
 print  WF "<div id=\"$seInd{$id_attr}\">" if exists $seInd{$id_attr};
 print WF "<div id=\"$divs[$i]\" style=\"margin:10px;\">";
 printHeader($divs[$i]);
 writeDivs($divs[$i]);
 print WF "</div>";
 $id_attr = "END".$i;
 print WF "</div>" if exists $seInd{$id_attr};
}
print WF "</div>";
print WF "</div>"; #End of wrapper
print WF "</body><br><a href=\"#\" onclick=\"javascript:processForm();\"><div id=\"results\">Switch to old format</div></a></html>";

#End of Main

###############################################################################
sub getVisibility {
 $show{'ASM'}  = 0; 
 $show{'DATABASE'} = 0;
 $show{'DB_SER'} = 0;
 $show{'SWITCH'} = 0;
 $show{'CELL'} = 0;
 $show{'ASM_PATCH'} = 0;
 $show{'CRS_PATCH'} = 0;
 $show{'RDBMS_PATCH'} = 0; 
 $show{'OS_PARAMS'} = 0;

 foreach $key ( grep { /a_v_parameter_.*\.out/ } keys %files ) {
  $show{'ASM'} = 1;
  last;
 }
 foreach $key ( grep { /d_v_parameter_.*\.out/ } keys %files ) {
  $show{'DATABASE'} = 1;
  last;
 }
 $show{'DB_SER'} = 1 if exists $files{'o_host_list.out'} && $#hosts >= 0;
 $show{'SWITCH'} = 1 if exists $files{'o_ibswitches.out'} && $#switches >= 0;
 $show{'CELL'} = 1 if exists $files{'cells.out'} && $#cells >= 0;
 foreach $key ( grep { /o_asm_inventory.*\.out/ } keys %files ) {
  $show{'ASM_PATCH'} = 1;
  last;
 }
 foreach $key ( grep { /o_crs_inventory.*\.out/ } keys %files ) {
  $show{'CRS_PATCH'} = 1;
  last;
 }
 foreach $key ( grep { /o_rdbms_inventory.*\.out/ } keys %files ) {
  $show{'RDBMS_PATCH'} = 1;
  last;
 }
 foreach $key ( keys %os_param ) {
   foreach $key1 ( grep { /^o_$key\_.*\.out/ } keys %files ) {
     $show{'OS_PARAMS'} = 1;
   }
 }
 if ( $show{'OS_PARAMS'} != 1 ) {
  foreach $key ( keys %os_package ) {
   foreach $key1 ( grep { /^o_$key\_.*\.out/ } keys %files ) {
     $show{'OS_PARAMS'} = 1;
   }
  }
 }
 if ( $show{'OS_PARAMS'} != 1 ) {
  foreach $key ( keys %os_patch ) {
   foreach $key1 ( grep { /^o_$key\_.*\.out/ } keys %files ) {
     $show{'OS_PARAMS'} = 1;
   }
  }
 }
}
###############################################################################
sub writeTabsSec {
$html = <<HTML;
   <div id="TABS" style="width:100%;height:35px;background:#26aec2; background:#F2F5F7;">
HTML
$html .= "<button type=\"button\" class=\"button\" id=\"ASM_B\" ".
 "onclick=\"javascript:hideShow('ASM');\">ASM</button> " if ($show{'ASM'});

$html .= "<button type=\"button\" class=\"button\" id=\"DATABASE_B\" ".
 "onclick=\"javascript:hideShow('DATABASE');\">Database</button>" if($show{'DATABASE'});

$html .= " <button type=\"button\" class=\"button\" id=\"DB_SER_B\" ".
         " onclick=\"javascript:hideShow('DB_SER');\"> ".
         " Database Server</button> " if( $show{'DB_SER'} );

$html .= " <button type=\"button\" class=\"button\" id=\"CELL_B\" ".
         " onclick=\"javascript:hideShow('CELL');\"> ".
         " Storage Server</button> " if( $show{'CELL'} );

$html .= " <button type=\"button\" class=\"button\" id=\"SWITCH_B\" ".
         " onclick=\"javascript:hideShow('SWITCH');\"> ".
         " Infiniband Switch</button> " if( $show{'SWITCH'} );

$html .= " </div> ";
print WF $html;
}

###############################################################################
sub writeASMSec {
 $id_attr = "ASM";
 $html = "<div id=\"$id_attr\">";
 $html .= "<h2 class=\"h2c\">ASM Details</h2>";
 $html .= "<ul>";
 foreach $key ( sort { $a cmp $b } keys %asmi ) {
  $html .= "<li class=\"ulc\">$key</li>";
  #$html .= "<li><a href=\"#$key\"> $key </a></li>";
  push @divs,"$key:ASM_PARAMS";
  $html .= "<ul><li><a href =\"#$key:ASM_PARAMS\"> Init Parameters </a></li></ul>";
 }
 $html .= "</ul></div>\n";
 print WF $html;
 #Get start and end indexes of divs array
 update_se_index($id_attr);
}

###############################################################################
sub writeDBSec {
 $id_attr = "DATABASE";
 $html = "<div id=\"$id_attr\">";
 $html .= "<h2 class=\"h2c\">Database Details</h2>";
 $html .= "<ul>";
 foreach $key ( sort { $a cmp $b } keys %dbs ) {
  next if exists $db_type{$key} and $db_type{$key} eq "PDB";
  $html .= "<li class=\"ulc\">$key</li>";
  $html .= "<ul>";
  $html .= "<li><a href =\"#$key:DB_UPARAMS\"> Underscore params </a></li>";
  push @divs,"$key:DB_UPARAMS";
  foreach $ele ( @{$dbs{$key}} ) {
   $html .= "<li>$ele</li>";
   $html .= "<ul><li><a href =\"#$key:$ele:DB_PARAMS\"> v_parameters </a></li></ul>";
   push @divs,"$key:$ele:DB_PARAMS";
  }
  $html .= "</ul>";
 }
 $html .= "</ul></div>\n";
 print WF $html;
 update_se_index($id_attr);
}

###############################################################################
sub writeDBSerSec {
 $id_attr = "DB_SER";
 $html = "<div id=\"$id_attr\">";
 $html .= "<h2 class=\"h2c\">Database Server Details</h2>";
 $html .= "<ul>";
 foreach $key ( @hosts ) {
  $html .= "<li> $key </li>";
  $html .= "<ul>";
  $html .= "<li>Installed DB Patches</li>" if (  $show{'ASM_PATCH'} || $show{'CRS_PATCH'} || $show{'RDBMS_PATCH'} );
  $html .= "<ul>";
  if ( $show{'ASM_PATCH'} ) {
    $html .= "<li><a href=\"#$key:DB_PATCH:ASM\">Installed ASM Patches</a></li>";
    push @divs,"$key:DB_PATCH:ASM";
  }
  if ( $show{'CRS_PATCH'} ) {
    $html .= "<li><a href=\"#$key:DB_PATCH:CRS\">Installed CRS Patches</a></li>";
    push @divs,"$key:DB_PATCH:CRS";
  }
  if ( $show{'RDBMS_PATCH'} ) {
   $html .= "<li>Installed RDBMS Patches</li>";
   $html .= "<ul>";
   foreach $ele ( grep{ /o_rdbms_inventory_(.*)_$key\.out/ } keys %files ) { 
    if ( $ele =~ /o_rdbms_inventory_(.*)_$key\.out/ ) {
     $attr2 = $1; #home without /
     foreach $key1 ( keys %db_homes ) {
      $attr1 = $key1;
      $attr1 =~ s/\///g;
      if ( $attr1 eq $attr2 ) {
       $html .= "<li><a href=\"#$key:DB_PATCH:RDBMS:$key1\">$key1</a></li>";
       push @divs,"$key:DB_PATCH:RDBMS:$key1";
      }
     }
    }
   }
   $html .= "</ul>";
  }
  $html .= "</ul>";
  if ( $show{'OS_PARAMS'} ) {
   $html .= "<li><a href=\"#$key:OS_PARAMS\"> OS Parameters </a> ".
            "<div id=\"$key:OS_PARAMS:HEADS\"></div>". 
            "</li>";
   push @divs,"$key:OS_PARAMS";
  }
  $html .= "<li><a href=\"#$key:DB_SER_DATA\">Database Server Additional Data</a>".
	   "<div id=\"$key:DB_SER_DATA:HEADS\"></div>".
           "</li>";
  push @divs,"$key:DB_SER_DATA";
  $html .= "</ul>";
 }
 $html .= "</ul></div>\n";
 print WF $html;
 update_se_index($id_attr);
}

###############################################################################
sub writeSwitchSec {
 $id_attr = "SWITCH";
 $html = "<div id=\"$id_attr\">";
 $html .= "<h2 class=\"h2c\">Infiniband Switch Details</h2>";
 $html .= "<ul>";
 foreach $key ( @switches ) {
  my @tkey=split('\.',$key);
  $html .= "<li>$tkey[0]</li>";
  #$html .= "<li>$key</li>";
  ##$html .= "<li><a href=\"#$key\"> $key </a></li>";
  $html .= "<ul>";
  ##$html .= "<li><a href =\"#$key:SWITCH_PARAMS\"> Parameters </a></li>";
  ##push @divs,"$key:SWITCH_PARAMS";
  #$html .= "<li><a href =\"#$key:SWITCH_DATA\">Switches Additional Data</a>".
  #	   "<div id=\"$key:SWITCH_DATA:HEADS\"></div>".
  #	   "</li>";
  #push @divs,"$key:SWITCH_DATA";
  #$html .= "</ul>";
  $html .= "<li><a href =\"#$tkey[0]:SWITCH_DATA\">Switches Additional Data</a>".
           "<div id=\"$tkey[0]:SWITCH_DATA:HEADS\"></div>".
           "</li>";
  push @divs,"$tkey[0]:SWITCH_DATA";
  $html .= "</ul>";
 }
 $html .= "</ul></div>\n";
 print WF $html;
 update_se_index($id_attr);
}

###############################################################################
sub writeCellSec {
 $id_attr = "CELL";
 $html = "<div id=\"$id_attr\">";
 $html .= "<h2 class=\"h2c\">Storage Server Details</h2>";
 $html .= "<ul>";
 foreach $key ( @cells ) {
  $html .= "<li>$key</li>";
  #$html .= "<li><a href=\"#$key\"> $key </a></li>";
  $html .= "<ul><li><a href =\"#$key:CELL_DATA\">Storage Server Data </a>".
	   "<div id=\"$key:CELL_DATA:HEADS\"></div>".
	   "</li></ul>";
  push @divs,"$key:CELL_DATA";
 }
 $html .= "</ul></div>\n";
 print WF $html;
 update_se_index($id_attr);
}

###############################################################################
sub printHeader {
 my $divId = $_[0];
 my $rVal;
 if ( $divId =~ /(.*):ASM_PARAMS/ ) {
  $rVal = "$1 ASM Instance Init Parameters";
 }
 elsif ( $divId =~ /(.*):(.*):DB_PARAMS/ ) {
  $rVal = "$2($1) DB Instance Init Parameters";
 }
 elsif ( $divId =~ /(.*):DB_UPARAMS/ ) {
  $rVal = "$1 DB Underscore Parameters";
 }
 elsif ( $divId =~ /(.*):DB_PATCH:(.*):(.*)/ ) {
  $rVal = "$2 Inventory from $1 ($3)";
 }
 elsif ( $divId =~ /(.*):DB_PATCH:(.*)/ ) {
  $rVal = "$2 Inventory from $1";
 }
 elsif ( $divId =~ /(.*):OS_PARAMS/ ) {
  $rVal = "OS Parameters from $1";
 } 
 elsif ( $divId =~ /(.*):DB_SER_DATA/ ) {
  $rVal = "Data Collected from Host $1";
 }
 elsif ( $divId =~ /(.*):SWITCH_PARAMS/ ) {
  $rVal = "Switch Parameters from $1";
 }
 elsif ( $divId =~ /(.*):SWITCH_DATA/ ) {
  $rVal = "Data Collected from Switch $1";
 }
 elsif ( $divId =~ /(.*):CELL_DATA/ ) {
  $rVal = "Data Collected from Cell $1";
 }
 else {
  $rVal = $divId;
 }
 print WF "<h2 class=\"h2c1\">$rVal</h2><br>"; 
}
###############################################################################
sub update_se_index {
my $divId = $_[0];
my $temp;
if ( $sei_count < $#divs ) {
 $temp = $sei_count+1;
 $seInd{"START".$temp} = $divId."_BODY";
 $seInd{"END".$#divs} = "END";
 $sei_count = $#divs;
}
}
###############################################################################
sub writeDivs {
 my $divId = $_[0];
 my @temp;
 my $line;
 my $flag;
 my $flag1;
 my $text;
 if ( $divId =~ /(.*):ASM_PARAMS/ ) {
  $attr1 = $1;
  $attr1 =~ s/\+/\\\+/g;
  #print all ASM instance specific params from a_v_parameter_asm.out
  return if not exists $files{"a_v_parameter_asm.out"};
  open($fh,"$files{'a_v_parameter_asm.out'}");
  while(<$fh>) {
   chomp;
   $line = $_;
   if ( $line =~ /$attr1\.(.*)/ ) {
     print WF "$1<br>";
   } 
  }
  close($fh);
 }
 elsif ( $divId =~ /(.*):DB_UPARAMS/ ) {
  $attr1 = $1;
  #There is a case where d_v_parameter file not there for stand by database
  return if not exists $files{"d_v_parameter_u_$attr1\.out"};
  open($fh,"$files{\"d_v_parameter_u_$attr1\.out\"}");
  while(<$fh>) {
   chomp;
   $line = $_;
   $text .= "$line<br>";
  }
  print WF $text;
  close($fh);
 }
 elsif ( $divId =~ /(.*):(.*):DB_PARAMS/ ) {
  $text = "";
  $attr1 = $1;
  $attr2 = $2;
  #There is a case where d_v_parameter file not there for stand by database
  return if not exists $files{"d_v_parameter_$attr1\.out"};
  open($fh,"$files{\"d_v_parameter_$attr1\.out\"}");
  while(<$fh>) {
   chomp;
   $line = $_;
   if ( $line =~ /$attr2\.(.*)/ ) {
    $text .= "$1<br>";
   }
  }
  print WF $text;
  close($fh);
 }
 elsif ( $divId =~ /(.*):DB_PATCH:(.*)/ ) {
  $attr1 = $1;
  $attr2 = $2;
  $attr3 = "";
  if ( index($attr2,':') > 0 ) { #Home path included
   @temp = split(':',$attr2);
   $attr2 = $temp[0];
   $attr3 = $temp[1]; #home path
   $attr3 =~ s/\///g;
  }
  $attr2 = lc $attr2;
  $attr4 = "o_$attr2"."_inventory_$attr1\.out" if $attr3 eq "";
  $attr4 = "o_$attr2"."_inventory_$attr3"."_$attr1\.out" if $attr3 ne "";
  $text = "";  
  if ( exists $files{$attr4} ) {
   open($fh,"$files{$attr4}");
   while(<$fh>) {
     $line = $_;
     #display xml files as is
     $line =~ s/</&lt;/g;
     $line =~ s/>/&gt;/g;
     $text .= "$line<br>"; 
   }
   print WF "$text"; 
   close($fh);
  } #Endo of if
 }
 elsif ( $divId =~ /(.*):OS_PARAMS/ ) {
  $osp_heads = "";
  $attr1 = $1;
  foreach $key ( keys %os_param ) {
   $text = "";
   $attr3 = "o_$key"."_$attr1\_report.out";
   if ( exists $files{$attr3} ) {
    open($fh,"$files{$attr3}");
    #$text = "<b>$key Values</b><br>";
    ($attr5 = $key) =~ s/ /_/g;
    $attr5 =~ s/'//g;
    $text .= "<a id=\"$attr1:OS_PARAMS:$attr5\"></a><h3>$key Values</h3>";
    $osp_heads .= "<li><a href=\"#$attr1:OS_PARAMS:$attr5\">$key Values</a></li>";
    while(<$fh>) {
     $line = $_;
     $text .= "$line<br>";
    }
    print WF "$text";
    close($fh);
   } #Endo of if
  } #end of for
  #OS patches and packages show here
  foreach $key ( keys %os_package ) {
   $text = "";
   $attr3 = "o_$key"."_$attr1\_report.out";
   if ( exists $files{$attr3} ) {
    open($fh,"$files{$attr3}");
    #$text = "<b>$key Values</b><br>";
    ($attr5 = $key) =~ s/ /_/g;
    $attr5 =~ s/'//g;
    $text .= "<a id=\"$attr1:OS_PARAMS:$attr5\"></a><h3>Packages - $key</h3>";
    $osp_heads .= "<li><a href=\"#$attr1:OS_PARAMS:$attr5\">Packages - $key</a></li>";
    while(<$fh>) {
     $line = $_;
     $text .= "$line<br>";
    }
    print WF "$text";
    close($fh);
   } #Endo of if
  } #end of for
  foreach $key ( keys %os_patch ) {
   $text = "";
   $attr3 = "o_$key"."_$attr1\_report.out";
   if ( exists $files{$attr3} ) {
    open($fh,"$files{$attr3}");
    #$text = "<b>$key Values</b><br>";
    ($attr5 = $key) =~ s/ /_/g;
    $attr5 =~ s/'//g;
    $text .= "<a id=\"$attr1:OS_PARAMS:$attr5\"></a><h3>Patches - $key</h3>";
    $osp_heads .= "<li><a href=\"#$attr1:OS_PARAMS:$attr5\">Patches - $key</a></li>";
    while(<$fh>) {
     $line = $_;
     $text .= "$line<br>";
    }
    print WF "$text";
    close($fh);
   } #Endo of if
  } #end of for
  #Write heads
  if ( $osp_heads ne "" ) {
      $osp_heads = "<ul>$osp_heads</ul>";
      $osp_heads =~ s/'//g;
      print WF "<script>document.getElementById('$attr1:OS_PARAMS:HEADS').innerHTML = '$osp_heads';</script>";
   }
 }
 elsif ( $divId =~ /(.*):DB_SER_DATA/ ){
   $dbs_heads = "";
   $attr1 = $1;   
   $attr3 = uc $attr1;
   $attr2 = "^o_(.*)_$attr1\_report\.out";
   foreach $key ( grep { /^o_(.*)_report_$attr1\.out/ || /$attr2/ }
                  keys %files ) { #greps report and non report files
    #Don't go through patches report files .. like o_crs_patches_hpi-24_report.out
    next if ( $key =~ /o_.*_patches_(.*)$attr1\_report\.out/);
    #Also don't go through os patches and packages files here..do it under os params
    $flag = 0;
    %newHash = (%os_param,%os_package,%os_patch);
    foreach $key1 ( keys %newHash ) {
      if ( $key =~ /o_$key1\_$attr1\_report\.out/ ) {
	$flag = 1;
	last;
      }
    }
    next if $flag == 1;
    $flag = 0;
    open ( $fh,"$files{$key}") || next;    
    $text = "";
    while (<$fh>) {
      chomp;
      $line = $_;
      $line =~ s///g;
      $line =~ s/^\s+//;    #Remove Leading spaces
      $line =~ s/\s+$//;    #Remove Trailing spaces
      next if $line eq "";
      if ( $line =~ /TO REVIEW COLLECTED DATA FROM\s+$attr3\s+FOR\s+(.*)/ ) {
        #print header for report files 
        $line = ucfirst lc $1;
        #$text = "<b>$line</b><br>";
 	($attr5 = $line) =~ s/ /_/g;
 	$attr5 =~ s/'//g;
        $text = "<a id=\"$attr1:DB_SER_DATA:$attr5\"></a><h3>$line</h3>";
  	$dbs_heads .= "<li><a href=\"#$attr1:DB_SER_DATA:$attr5\">$line</a></li>";
        $flag = 1;
      }
      else {
        #If header is not detected ( like TO REVIEW .. etc, print filename as header )
        if ( $flag == 0 ) {
 	  $key1 = $1 if $key =~ /^o_(.*)_report_$attr1\.out/ || $key =~ /^o_(.*)_$attr1\_report\.out/ ;
          #$text = "<b>$key1</b><br>";
	  ($attr5 = $key1 ) =~ s/ /_/g;
 	  $attr5 =~ s/'//g;
 	  $text ="<a id=\"$attr1:DB_SER_DATA:$attr5\"></a><h3>$key1</h3>";
  	  $dbs_heads .= "<li><a href=\"#$attr1:DB_SER_DATA:$attr5\">$key1</a></li>";
          $flag = 1;
        }
        $text .= "$line<br>";
      }
    }
    print WF "$text<br>" if $text ne "";
    close($fh);
   } #End of for   
   #Write heads
   if ( $dbs_heads ne "" ) {
      $dbs_heads = "<ul>$dbs_heads</ul>";
      $dbs_heads =~ s/'//g;
      print WF "<script>document.getElementById('$attr1:DB_SER_DATA:HEADS').innerHTML = '$dbs_heads';</script>";
   }
 }
 elsif ( $divId =~ /(.*):SWITCH_DATA/ ){
   #Get first part of switch
   @temp = split('\.',$1);
   $attr1 = $temp[0];   
   $attr3 = uc $attr1;
   $switch_heads = "";
   foreach $key ( grep { /^s_(.*)_$attr1(.*)\.out/ } keys %files ) { #greps report and non report files
    $attr2 = "";
    #Some files may not have report files..show them also
    if ( $key =~ /(.*)\.out/ && $key !~ /(.*)_report\.out/ ) {
      next if exists $files{"$1\_report.out"}; #$1 sets for =~ but not for !~	
    }
    open ( $fh,"$files{$key}") || next;
    $attr2 = $1 if $key =~ /^s_(.*)_$attr1\.out/;
    $text = "";
    while (<$fh>) {
      chomp;
      $line = $_;
      $line =~ s/^M//g;
      $line =~ s/^\s+//;    #Remove Leading spaces
      $line =~ s/\s+$//;    #Remove Trailing spaces
      next if $line eq "";
      if ( $line =~ /TO REVIEW COLLECTED DATA FROM\s+$attr3\s+FOR\s+(.*)/ ) {
        #print header for report files 
        $line = ucfirst lc $1;
        #$text = "<b>$line</b><br>";
        ($attr5 = $line) =~ s/ /_/g;
 	$attr5 =~ s/'//g;
        #$text = "<h3>$line</h3>";
        $text = "<a id=\"$attr1:SWITCH_DATA:$attr5\"></a><h3>$line</h3>";
        $switch_heads .= "<li><a href=\"#$attr1:SWITCH_DATA:$attr5\">$line</a></li>";
      }
      else {
        if ( $attr2 ne "" ) {
          #print header for non report files
          #$text = "<b>$attr2 parameter values</b><br>";
          ($attr5 = $attr2 ) =~ s/ /_/g;
 	  $attr5 =~ s/'//g;
          #$text = "<h3>$attr2 parameter values</h3>";
          $text ="<a id=\"$attr1:SWITCH_DATA:$attr5\"></a><h3>$attr2 parameter values</h3>";
          $switch_heads .= "<li><a href=\"#$attr1:SWITCH_DATA:$attr5\">$attr2 parameter values</a></li>";
          $attr2 = "";
        }
        $text .= "$line<br>";
      }
    }
    print WF "$text<br>" if $text ne "";
    close($fh);
   } #End of for
   #Write heads
   if ( $switch_heads ne "" ) {
      $switch_heads = "<ul>$switch_heads</ul>";
      $switch_heads =~ s/'//g;
      print WF "<script>document.getElementById('$attr1:SWITCH_DATA:HEADS').innerHTML = '$switch_heads';</script>";
   }
 }
 #elsif ( $divId =~ /(.*):CELL_DATA/ ){
 #  $attr1 = $1;
 #  $attr3 = uc $attr1;
 #  $cell_heads = "";
 #  foreach $key ( grep { /^c_(.*)_report.out/ && !/^c_c[bw]c_(.*)_report.out/ }  
 #                 keys %files ) {
 #   open ( $fh,"$files{$key}") || next; 
 #   $attr2 = $1 if $key =~ /^c_(.*)_report.out/;
 #   #print WF "<h3>$attr2</h3>";
 #   $flag1 = 0;
 #   $flag = 0;
 #   $text = "";
 #   while (<$fh>) {
 #     chomp; 
 #     $line = $_; 
 #     $line =~ s///g;
 #     $line =~ s/^\s+//;    #Remove Leading spaces
 #     $line =~ s/\s+$//;    #Remove Trailing spaces
 #     next if $line eq "";      
 #     last if $line =~ /TO REVIEW COLLECTED DATA FROM/ && $flag == 1;
 #     next if ( $line !~  /$attr3/ && $flag == 0);
 #     $flag = 1;
 #     if ( $line =~ /TO REVIEW COLLECTED DATA FROM\s+$attr3\s+FOR\s+(.*)/ ) {
 #       $line = ucfirst lc $1;
 #       #$text = "<b>$line</b><br>";
 #       #$text = "<h3>$line</h3>";
 #       ($attr5 = $line) =~ s/ /_/g;
 #       $attr5 =~ s/'//g;
 #       $text = "<a id=\"$attr1:CELL_DATA:$attr5\"></a><h3>$line</h3>";
 #       $dbs_heads .= "<li><a href=\"#$attr1:CELL_DATA:$attr5\">$line</a></li>";
 #     }   
 #     else {
 #       $text .= "$line<br>";
 #     }
 #   }
 #   print WF "$text<br>" if $text ne "";
 #   close($fh);
 #  } #End of for
 #  #Write heads
 #  if ( $cell_heads ne "" ) {
 #     $cell_heads = "<ul>$cell_heads</ul>";
 #     $cell_heads =~ s/'//g;
 #     print WF "<script>document.getElementById('$attr1:CELL_DATA:HEADS').innerHTML = '$cell_heads';</script>";
 #  }
 #} 
 elsif ( $divId =~ /(.*):CELL_DATA/ ){
   $cell_heads = "";
   $attr1 = $1;
   $attr3 = uc $attr1;
   foreach $key ( grep { /^c_(.*)_report.out/ && !/^c_c[bw]c_(.*)_report.out/ } keys %files ) {
    open ( $fh,"$files{$key}") || next;
    $attr2 = $1 if $key =~ /^c_(.*)_report.out/;
    $flag = 0;
    $text = "";
    while (<$fh>) {
      chomp;
      $line = $_;
      $line =~ s/^M//g;
      $line =~ s/^\s+//;    #Remove Leading spaces
      $line =~ s/\s+$//;    #Remove Trailing spaces
      next if $line eq "";
      last if $line =~ /TO REVIEW COLLECTED DATA FROM/ && $flag == 1;
      next if ( $line !~  /$attr3/ && $flag == 0);
      if ( $line =~ /TO REVIEW COLLECTED DATA FROM\s+$attr3\s+FOR\s+(.*)/ ) {
        $line = ucfirst lc $1;
        ($attr5 = $line) =~ s/ /_/g;
        $attr5 =~ s/'//g;
        $text = "<a id=\"$attr1:CELL_DATA:$attr5\"></a><h3>$line</h3>";
        $cell_heads .= "<li><a href=\"#$attr1:CELL_DATA:$attr5\">$line</a></li>";
	$flag = 1;
      }
      else {
        if ( $flag == 0 ) {
          $key1 = $1 if $key =~ /^c_(.*)_report.out/ && $key !~ /^c_c[bw]c_(.*)_report.out/ ;
          ($attr5 = $key1 ) =~ s/ /_/g;
          $attr5 =~ s/'//g;
          $text ="<a id=\"$attr1:CELL_DATA:$attr5\"></a><h3>$key1</h3>";
          $cell_heads .= "<li><a href=\"#$attr1:CELL_DATA:$attr5\">$key1</a></li>";
          $flag = 1;
        }
	$text .= "$line<br>";
      }
    }
    print WF "$text<br>" if $text ne "";
    close($fh);
   } #End of for
   #Write heads
   if ( $cell_heads ne "" ) {
      $cell_heads = "<ul>$cell_heads</ul>";
      $cell_heads =~ s/'//g;
      print WF "<script>document.getElementById('$attr1:CELL_DATA:HEADS').innerHTML = '$cell_heads';</script>";
   }
 }
}
###############################################################################
sub parseEnvFile {
 my $line;
 open($fh,"$files{'check_env.out'}") || return;
 while(<$fh>) {
  chomp;
  $line = $_;
  $line =~ s///g;
  if ( $line =~ /.*\.ASM_INSTANCE\s+=\s+(.*)/ ) { 
    $asmi{$1} = 1 if $1 ne "";
  }
  elsif ($line =~ /^DB_NAME\s+=\s+([^\|]+)\|([^\|]+)\|(.*)/ ) {
    @{$dbs{$1}} = ();
    $db_homes{$3} = 1 if $3 ne "";
  }
 }
 close($fh);

 open($fh,"$files{'check_env.out'}");
 while(<$fh>) {
  chomp;
  $line = $_;
  $line =~ s/^M//g;
  if ( $line =~ /.*\.INSTANCE_NAME\s+=\s+.*/ ) {
    foreach my $key (keys %dbs ) {
      if ( $line =~ /.*\.$key\.INSTANCE_NAME\s+=\s+(.*)/ ) {
        push @{$dbs{$key}},$1 if $1 ne "";
      }
    }
  }
  elsif ( $line =~ /(.*)\.DATABASE_TYPE\s+=\s+(.*)/ ) { 
    #for 12c type can be CDB  or PDB
    $db_type{$1} = $2 if $1 ne "" && $2 ne "";
  }  
 }
 close($fh);
}
###############################################################################
sub parseLineFiles {
 my $file = $_[0];
 my $attr1 = $_[1];
 my @temp;
 my @temp1;
 my $line;
 open($fh,"$file") || return;
 while(<$fh>) {
  chomp();
  $line = $_;
  $line =~ s///g;
  $line =~ s/\s//g;
  if ( $attr1 eq "CELL" && index($line,"=") > 0 ) {
   @temp1 = split("=",$line);
   if ( $temp1[1] ne "" ) {
    push @temp,$temp1[1] if $temp1[1] !~ /spassword:/;
   }
   elsif ( $temp1[0] ne "" ) {
    push @temp,$temp1[0];
   }
  }
  else {
    push @temp,$line if $line ne "";
  }
 }
 close($fh);
 return @temp;
}
###############################################################################
sub debug_fun {
 return if $debug == 0; 
 my $str = $_[0];
 print "$str\n";
}

 


