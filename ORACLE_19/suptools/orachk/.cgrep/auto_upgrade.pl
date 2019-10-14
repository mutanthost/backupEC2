#!/usr/local/bin/perl
# 
# $Header: tfa/src/orachk/src/auto_upgrade.pl /main/24 2018/11/29 09:23:47 apriyada Exp $
#
# auto_upgrade.pl
# 
# Copyright (c) 2014, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      auto_upgrade.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    testtesttest
#    apriyada    09/12/14 - Print Version
#    apriyada    05/07/14 - Auto upgrade orachk
#    apriyada    05/07/14 - Creation
#

use warnings;
#use Switch;

$presentpath = `dirname $0`;chomp($presentpath);

my ($program_version) = $ARGV[0];
my ($program_name) = $ARGV[1];
my ($mypref) = $ARGV[2];
my($ORACHK_LOC) = $ARGV[3];
my($workdir) = $ARGV[4];
my($selectedpath) = $ARGV[5];

my($ZIP) = `which unzip`;
$zipstat = `echo $?`;
chomp($ZIP);
#$usrname = `id|gawk 'BEGIN { FS = "(" };{print $2}'|gawk 'BEGIN { FS = ")" };{print $1}'`;chomp($usrname);

if($zipstat == 1)
{
	$platform = `/bin/uname`;

	if($platform eq "Linux" || $platform eq "HP-UX" || $platform eq "AIX")
	{
		$ORATAB="/etc/oratab";
	}
	elsif($platform eq "SunOS")
	{
		$ORATAB="/var/opt/oracle/oratab";
	}
	else
	{
		print "\nERROR: Unknown Operating System\n";
	}
	if ( -e "$ORATAB" )
 	{
        	foreach $var (`grep ":/" $ORATAB |grep -v "+"|grep -v "^#"|cut -d: -f2`)
		{
			if(-e "$var/bin/unzip")
			{
				$ZIP="$var/bin/unzip";
				$zipstat = 0;
			}
		}

	}

}

my ($pdir) = `pwd`;
$pdir =~ s/\s//g;

sub show_version 
{
  $collfile = $_[0];
  if ( -e "$workdir/cgrep" ) {
    $dataFilesDateval=`$workdir/cgrep FILE_DATE $collfile`;
  } else {
    $dataFilesDateval=`/bin/grep FILE_DATE $collfile`;
  }
  @tmpvals = split(/ /,$dataFilesDateval);
  $dataFilesDate = $tmpvals[2];
  if(defined $dataFilesDate && $dataFilesDate ne '')
  {
     $dataFIleMonth=`echo $dataFilesDate|cut -d- -f2|tr "[a-z]" "[A-Z]"`;
     $dataFIleMonth =~ s/\s//g;

	  if($dataFIleMonth eq "JAN")
	  {
	       	$dataFIleMonthNo = "01";
	  }
	  elsif($dataFIleMonth eq "FEB")
	  {
        	$dataFIleMonthNo = "02";
	  }
	  elsif($dataFIleMonth eq "MAR")
	  {
	        $dataFIleMonthNo = "03";
	  }
	  elsif($dataFIleMonth eq "APR")
	  {
	        $dataFIleMonthNo = "04";
	  }
	  elsif($dataFIleMonth eq "MAY")
	  {
	        $dataFIleMonthNo = "05";
	  }
	  elsif($dataFIleMonth eq "JUN")
	  {
        	$dataFIleMonthNo = "06";
	  }
	  elsif($dataFIleMonth eq "JUL")
	  {
        	$dataFIleMonthNo = "07";
	  }
	  elsif($dataFIleMonth eq "AUG")
	  {
        	$dataFIleMonthNo = "08";
	  }
	  elsif($dataFIleMonth eq "SEP")
	  {
        	$dataFIleMonthNo = "09";
	  }
	  elsif($dataFIleMonth eq "OCT")
	  {
        	$dataFIleMonthNo = "10";
	  }
	  elsif($dataFIleMonth eq "NOV")
	  {
        	$dataFIleMonthNo = "11";
	  }
	  else
	  {
        	$dataFIleMonthNo = "12";
	  }

  }

  if(defined $dataFilesDate && $dataFilesDate ne '')
  {
    $dataFIleDay=`echo $dataFilesDate|cut -d- -f1|tr "[a-z]" "[A-Z]"`;
    $dataFIleYear=`echo $dataFilesDate|cut -d- -f3|tr "[a-z]" "[A-Z]"`;  
    $dataFIleYear =~ s/\s//g;
    $dateval = "$dataFIleYear$dataFIleMonthNo$dataFIleDay";
  }
  return $dateval; 
}


if($mypref eq "-check")
{
	$ORACHK_LOC =~ s/RAT_UPGRADE_LOC=//g;
	my ($pdir) = `pwd`;
	$pdir =~ s/\s//g;
#	$cur_ver = `bash $pdir/$program_name -v`;
#	$cur_ver =~ s/\s//g;
        $cur_ver_no = show_version("$presentpath/../.cgrep/collections.dat");
#	my($cur_ver_no) = (split /_/, $cur_ver)[-1];

	my($selectedpath)=".";

	my (@loc)= split(/,/,$ORACHK_LOC);
	foreach $locval (@loc)
	{
		chomp($locval);

		if (-f "$locval/$program_name.zip")
		{
			chdir "$locval/";
			if ( -e "$locval/extract_files/collections.dat" )
			{
				$loccoltimestamp = `ls -l $locval/extract_files/collections.dat`;
				if($zipstat == 0)
				{
                        		$coltimestamp = `$ZIP -l $locval/$program_name.zip |grep collections.dat`;
				}
				else
				{
					$selectedpath = "-1";
					last;
				}		
                                if ($loccoltimestamp ne ""){
					@tmp = split(/ /,$loccoltimestamp);$sizelocal = $tmp[4];
				}
				if ($coltimestamp ne ""){
					@tmp1 = split(/ /,$coltimestamp); $sizezip = $tmp1[1];
				}

#				if($sizelocal ne "$usrname" && $sizezip ne "$usrname")
                                if($sizelocal =~ /^\d+$/ && $sizezip =~ /^\d+$/)
				{
					if($sizelocal != $sizezip)
					{
						chdir "extract_files";
						`$ZIP -o "../$program_name.zip" 2> /dev/null`;
					}
				}
			}
			unless(-e "$locval/extract_files/collections.dat")
			{
				`rm -rf extract_files`;
				 `mkdir -p extract_files 2>/dev/null`;
				if(-d "$locval/extract_files")
				{
				 chdir "extract_files";
				  if($zipstat == 0)
                                  {
					`$ZIP -o "../$program_name.zip" 2>/dev/null`;
				  }
  				  else
				  {
				  	$selectedpath = "-1";
				  	last;
				  }
				}
			}
		}

        	if ( -e "$locval/extract_files/collections.dat" )
	       	{
                	#$ver_at_loc=`bash $locval/$program_name -v`;
			#$ver_at_loc =~ s/\s//g;
	                #$veratloc_no=(split /_/, $ver_at_loc)[-1];
			$veratloc_no=show_version("$locval/extract_files/.cgrep/collections.dat");
		  if(defined $veratloc_no && $veratloc_no ne '' && defined $cur_ver_no && $cur_ver_no ne '')
		  {
                	if ( $veratloc_no > $cur_ver_no )
        	        {
				`touch $workdir/versionfil.dat`;
				#`echo "$program_name  version: ${program_version}_$veratloc_no"|tr "[a-z]" "[A-Z]" > $workdir/versionfil.dat`;
				`echo "$program_name  version: \$(grep 'program_version=' $locval/extract_files/$program_name|head -1|cut -d= -f2|sed 's/"//g'|sed 's/ //g')_$veratloc_no"|tr "[a-z]" "[A-Z]" > $workdir/versionfil.dat`;
	                        $selectedpath="$locval/extract_files";
                        	$cur_ver_no=$veratloc_no;
                	}  
		  }    
        	}          
	}

	chdir "$pdir/"; 

	if($selectedpath eq ".")
	{
		$ret_val="0";
	} 
	else
	{
		$ret_val="$selectedpath";
	}
	foreach $locval (@loc)
        {
       	        chomp($locval);
		if($selectedpath ne "$locval/extract_files")
		{
	               	`rm -rf $locval/extract_files`;
		}
       	}
	print $ret_val;
}
else
{
	$srcdir="$0";
	$srcdir =~ s/.cgrep\/auto_upgrade.pl//g;
	$ORACHK_LOC =~ s/RAT_UPGRADE_LOC=//g;
	@pathval = split(/,/,$selectedpath);
	my ($timestamp) = `date '+%m%d%y_%H%M%S'`;
	my (@backup_files) = ($program_name, 'CollectionManager_App.sql', $program_name.'.py', $program_name.'.pyc', $program_name.'.bat', 'Apex5_CollectionManager_App.sql', 'user_defined_checks.xsd', 'sample_user_defined_checks.xml', 'exadiscover', 'build', 'bash','templates', '.cgrep', 'rules.dat', 'collections.dat', 'lib','web' );
	`mkdir $srcdir/back_up_${program_name}_$timestamp`;
	foreach $val (@backup_files)
	{
        	`cp -R -f $srcdir/$val $srcdir/back_up_${program_name}_$timestamp 2>/dev/null`;
	        `cp -R -f $pathval[0]/$val $srcdir 2>/dev/null`;
	}
	`rm -rf $workdir/cgrep`;
	$upgraded_ver = `bash $srcdir/$program_name -v`;
	$upgraded_ver =~ s/\s//g;$upgraded_ver =~ s/RACCHECKVERSION://g;
	print "\n\n$program_name has been upgraded to $upgraded_ver\n\n";

	my (@loc)= split(/,/,$ORACHK_LOC);
        foreach $locval (@loc)
        {
                chomp($locval);
		`rm -rf $locval/extract_files`;
		
	}

}
