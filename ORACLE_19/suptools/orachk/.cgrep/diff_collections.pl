# 
# $Header: tfa/src/orachk/src/diff_collections.pl /main/11 2017/08/11 17:38:18 rojuyal Exp $
#
# diff_collection.pl
# 
# Copyright (c) 2014, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      diff_collection.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    rkchaura    08/18/15 - Added id attribute in comparison summary table on
#                           html report
#    rkchaura    07/30/15 - diff report with absolute path
#    apriyada    08/04/14 - Diff two collections
#    apriyada    08/04/14 - Creation
#

my $scriptpath = `dirname $0`;
chomp($scriptpath);

my $workdir = $ARGV[0];

my $res1 = $ARGV[1];
my $res2 = $ARGV[2];

$coll1 = `basename $res1`;chomp($coll1);
$coll2 = `basename $res2`;chomp($coll2);

my $outfile = $ARGV[3];

my @getfol1arr = split(/\//, $res1);
my @getfol2arr = split(/\//, $res2);
my $getfol1 = $getfol1arr[-1];
my $getfol2 = $getfol2arr[-1];

my @d = split(/_/, $getfol1);
my @dn= split(/_/, $getfol2);

my $program_name = $d[0];
my $COLLDIFFFIL = "collection_diff_candidate.log";


if(-e "$res1/outfiles/check_env.out")
{
    $envfile1 = "$res1/outfiles/check_env.out";
    $envfile2 = "$res2/outfiles/check_env.out";
}
else
{
    $envfile1 = "$res1/outfiles/raccheck_env.out";
    $envfile2 = "$res2/outfiles/raccheck_env.out";
}

if(-e "$res1/log/$COLLDIFFFIL")
{
	$COLLDIFFFIL = "$res1/log/$COLLDIFFFIL";
}
else
{
	if(-e "$res2/log/$COLLDIFFFIL")
	{
		$COLLDIFFFIL = "$res2/log/$COLLDIFFFIL";
	}
	else
	{
		print "\nCannot diff collections. File collection_diff_candidate.log not found.\n\n";
		exit;
	}
}

my $vergrepstr = `echo $program_name|tr "[a-z]" "[A-Z]"`;
chomp ($vergrepstr);
$vergrepstr = "$vergrepstr"."_VERSION";

my $run1_ver = `grep '$vergrepstr' $envfile1|sed 's/$vergrepstr = //'`;
my $run2_ver = `grep '$vergrepstr' $envfile2|sed 's/$vergrepstr = //'`;


# list of check_id with details that were run in either of the runs
my %checkid_list = ();
my %hostlist = ();


if ( ! $res1 || ! $res2 )
{
  print "Usage : diff_collection.pl <exachk_res1_folder> <exachk_res2_folder>\n";
  exit;
}


if ( ! $outfile )
{
  $outfile = "$workdir/${program_name}_diffcoll.txt";
  $outhtml = "$workdir/${program_name}_$d[-2]$d[-1]_$dn[-2]$dn[-1]_diff.html";
}
else 
{ 
  $firstchar = substr($outfile, 0, 1);
  if($firstchar eq '/')
  {
   $outhtml = "$outfile";
   $outfile = "$outfile"."txt";
  }
  else
  {
   $outhtml = "$workdir/$outfile";
   $outfile = "$workdir/$outfile".".txt";
  }
} 

sub generate_report
{
  $paramiter=0;
  open(WF, ">>$outhtml") || die "Can't open $outhtml\n";

print WF <<EOF
<h2>Collections Comparison Details</h2>
<br>
<button type="button" id="expand">Expand All</button>  <button type="button" id="collapse">Collapse All</button> 
EOF
;

######### Changed section
print WF <<EOF
<a name="changedcol"></a>
<table summary="Differences between Run 1 and Run 2" border=1 id="changedcoltbl">

EOF
;

foreach $hostval (keys %hostlist)
{
$hostvalprinted = 0;
	
	foreach $check_id (keys %checkid_list)
	{
		$paramiter++;
		$checkoutfile = "$workdir/$hostval"."_"."$check_id.out";
		if(-e $checkoutfile )
		{
			if($hostvalprinted == 0)
			{
				$hostvalprinted = 1;
				print WF <<EOF
				<tr></tr><tr></tr><tr><td><b>$hostlist{$hostval}->{TYPE} - $hostval</b></td></tr>
				<tr></tr>
EOF
;
			}
			
			print WF <<EOF
			<tr><td><a href="javascript:toggleVis('paramdetails$paramiter', 'check_name_show');" id="check_name_show">$checkid_list{$check_id}</a></td></tr>
			<tr><td><a href="javascript:toggleVis('paramdetails$paramiter', 'check_name_hide');" style="DISPLAY: none" id="check_name_hide">$checkid_list{$check_id}</a></td></tr>
			<script>
                        document.getElementById("expand").onclick = function() {toggleVis_all('paramdetails', 'expand',$paramiter)};
                        document.getElementById("collapse").onclick = function() {toggleVis_all('paramdetails', 'collapse',$paramiter)};
                        </script>
			<tr></tr><tr><td name='paramdetails$paramiter' style='DISPLAY: none'>
EOF
;
#			@params = `cat $checkoutfile`;
			open(OF, "$checkoutfile") || die "Can't open $checkoutfile\n";
			print WF <<EOF
			<table>
			
EOF
;
		        while(<OF>)
        		{
                		chomp;
				@linev = split(/\|delim\|/,$_);
				print WF <<EOF
				<tr><td>$linev[0]</td><td>$linev[1]</td><td>$linev[2]</td></tr>
EOF
;

	        	}
			print WF <<EOF
                        </table>
                        
EOF
;
		        close(OF);
			`rm -rf $checkoutfile`;	
			
			
		}

	}
}
print WF "</td></tr></table>\n";
print WF "<a class=\"a_bgw\" href=\"#\">Top</a>\n";
print WF "<hr><br/>\n";
print WF "</body><br><a class=\"a_bgw\" href=\"#\" onclick=\"javascript:processForm();\"><divcus id=\"results\">Switch to old format</divcus></a></html>";
close(WF);
 ####################################################################################
  
  print "Summary of Collections diffed\n";
  print "Total   : $total_uniq\n";
  print "Missing : $missing_uniq\n";
  print "New     : $new_uniq\n";
  print "Changed : $changed_uniq\n";
  print "Same    : $same_uniq\n";

  rename $outhtml, "$outhtml.orig";
  open FILE, ">", $outhtml;
  open ORIG, "<",  "$outhtml.orig";
  while (<ORIG>) {
    print FILE <<EOF
	<a name="collection"></a>
      <H2>Collection Comparison summary</H2>
      <table id="summarytbl" border=1 summary="Comparison Summary" role="presentation">
      <tr><td class="td_column">Run 1</td><td>$coll1</td></tr>
      <tr><td class="td_column_second">&nbsp;&nbsp;&nbsp;${program_name} Version</td><td>$run1_ver</td></tr>
      <tr><td class="td_column">Run 2</td><td>$coll2</td></tr>
      <tr><td class="td_column_second">&nbsp;&nbsp;&nbsp;${program_name} Version</td><td>$run2_ver</td></tr>
      <tr id="summary_total_checks"><td class="td_column">Total Collections Diffed</td><td>$total_uniq</td></tr>
      <tr><td class="td_column">Differences between<br/>Run 1 and Run 2</td><td>$changed_uniq</td></tr>
      <tr id="summary_unique_1"><td class="td_column" onmouseout="setVisibility('sub3', 'none')" onmouseover="setVisibility('sub3', 'inline')">Unique findings<br/>in Run 1</td><td>$missing_uniq<div id="sub3" style="position: relative; ">Number of unique collections run only in Run 1 </div></td></tr>
      <tr id="summary_unique_2"><td class="td_column" onmouseout="setVisibility('sub4', 'none')" onmouseover="setVisibility('sub4', 'inline')">Unique findings<br/>in Run 2</td><td>$new_uniq<div id="sub4" style="position: relative; ">Number of unique collections run only in Run 2 </div></td></tr>
      </table>
      <a class=\"a_bgw\" href=\"#\">Top</a>
	<div id="totalcoldiv" class="tips" style="z-index:1000;display:none">Total number of checks reported</div>
	<div id="changedcoldiv" class="tips" style="z-index:1000;display:none">Number of checks changed between Report 1 and Report 2</div>
	<div id="missingcoldiv" class="tips" style="z-index:1000;display:none">Number of checks missing in Report 2 </div>
	<div id="newcoldiv" class="tips" style="z-index:1000;display:none">Number of checks new in Report 2</div>
	<div id="samecoldiv" class="tips" style="z-index:1000;display:none">Number of checks without any change</div>
EOF
    if /<h2>Collections Comparison Details<\/h2>/; print FILE $_;
  }
  close ORIG;
  close FILE;
  unlink "$outhtml.orig";
  print "Collection comparison is complete. The comparison report can be viewed in the same file\n"
}

sub diff_opatch_out
{
	$checkoutfile = "$workdir/$hostval"."_"."$check_id.out";
	if(! -f $checkoutfile )
	{
        	`touch $checkoutfile`;
	}

        my $file1 = $_[0];
        my $file2 = $_[1];
	my $printfname = `basename $file1`;chomp($printfname);
        if ( (-f "$file1") && (! -f $file2))
        {
                $hostlist{$hostval}->{$check_id}="missing";
                `echo "This collection on $hostval is unique to Run 1 " >> $checkoutfile`;
                if ($checkid_list{$check_id}->{MATCH} ne "changed")
                {
                        $checkid_list{$check_id}->{MATCH} = "missing";
                }
                $missing++;
                $total++;
                return;
        }

        if ( (-f "$file2") && (! -f $file1))
        {
                $hostlist{$hostval}->{$check_id}=="new";
                `echo "This collection on $hostval is unique to Run 2 " >> $checkoutfile`;
                if ($checkid_list{$check_id}->{MATCH} ne "changed")
                {
                        $checkid_list{$check_id}->{MATCH} = "new";
                }
                $new++;
                $total++;
                return;
        }

        open(OF, "$file1") || die "Can't open $file1\n";
        $iterator=0;
        while(<OF>)
        {
                $iterator++;
                chomp;
                $line = $_;
                if ( $line =~  /(\d+)[\s]+(\d+)[\s]+(.*)/)
                {
                        $hash1{$iterator}->{BUG} = $1;
			$hash1{$iterator}->{PATCH} = $2;
                }

        }
        close(OF);
        open(OF, "$file2") || die "Can't open $file2\n";
        $headingprinted=0;
        $iterator=0;

	while(<OF>)
        {
                $iterator++;
                chomp;
                $line = $_;
                if ( $line =~  /(\d+)[\s]+(\d+)[\s]+(.*)/)
                {
			$bug = $1; $patch = $2;
                        if ($hash1{$iterator}->{BUG} != $bug || $hash1{$iterator}->{PATCH} != $patch)
                        {
                                $hostlist{$hostval}->{$check_id}="changed";
                                if($headingprinted == 0)
                                {
                                        $headingprinted=1;
					`echo "<b>File - $printfname</b>|delim|.|delim|." >> $checkoutfile`;
                                        `echo "<b>Line</b>|delim|<b>$coll1</b>|delim|<b>$coll2</b>" >> $checkoutfile`;
                                }
                                $run1val="Bug - $hash1{$iterator}->{BUG} / Patch - $hash1{$iterator}->{PATCH}";
                                $run2val="Bug - $bug / Patch - $patch";
                                `echo "$iterator|delim|$run1val|delim|$run2val" >> $checkoutfile`;
                                $inchanged++;
                        }
                }

        }
        if($inchanged == 0)
        {
                $hostlist{$hostval}->{$check_id}="same";
                $same++;
		if ( -z $checkoutfile)
		{
                	`rm -rf $checkoutfile`;
		}
        }
        else
        {
                $changed++;
                $checkid_list{$check_id}->{MATCH} = "changed";
        }
        $total++;
        close(OF);
        $inchanged=0;
}

sub diff_line_comp
{
	$checkoutfile = "$workdir/$hostval"."_"."$check_id.out";
        `touch $checkoutfile`;

        my $file1 = $_[0];
        my $file2 = $_[1];
        if ( (-f "$file1") && (! -f $file2))
        {
                $hostlist{$hostval}->{$check_id}="missing";
                `echo "This collection on $hostval is unique to Run 1 " >> $checkoutfile`;
                if ($checkid_list{$check_id}->{MATCH} ne "changed")
                {
                        $checkid_list{$check_id}->{MATCH} = "missing";
                }
                $missing++;
                $total++;
                return;
        }

        if ( (-f "$file2") && (! -f $file1))
        {
                $hostlist{$hostval}->{$check_id}=="new";
                `echo "This collection on $hostval is unique to Run 2 " >> $checkoutfile`;
                if ($checkid_list{$check_id}->{MATCH} ne "changed")
                {
                        $checkid_list{$check_id}->{MATCH} = "new";
                }
                $new++;
                $total++;
                return;
        }
	my @buffer1;
	my @buffer2;

        open(OF, "$file1") || die "Can't open $file1\n";
	$ival=0;
	while(<OF>)
	{
		chomp;
		$buffer1[$ival] = $_;
		$ival++;
	}
	close(OF);

	$ival=0;
	open(OF, "$file2") || die "Can't open $file2\n";
	while(<OF>)
        {
		chomp;
                $buffer2[$ival] = $_;
		$ival++;
        }
	close(OF);

        $iterator=0;$loopvar=0;
        $headingprinted=0;
        foreach (@buffer1)
        {
		chomp;
                $iterator++;
                $line = $_;
		$line2 = $buffer2[$loopvar];$loopvar++;
                if ( $line =~ /[\s]+[\d]+[\s]+(.*)/)
                {
		   $str1=$1;
		   if ( $line2 =~ /[\s]+[\d]+[\s]+(.*)/)
		   {
			$str2 = $1;
                        if ("$str1" ne "$str2")
                        {
                                $hostlist{$hostval}->{$check_id}="changed";
                                if($headingprinted == 0)
                                {
                                        $headingprinted=1;
                                        `echo "<b>Line</b>|delim|<b>$coll1</b>|delim|<b>$coll2</b>" >> $checkoutfile`;
                                }
                                $run1val=$str1;
                                $run2val=$str2;
                                `echo "$iterator|delim|$run1val|delim|$run2val" >> $checkoutfile`;
                                $inchanged++;
                        }
		   }
                }

        }

	if($inchanged == 0)
        {
                $hostlist{$hostval}->{$check_id}="same";
                $same++;
                `rm -rf $checkoutfile`;
        }
        else
        {
                $changed++;
                $checkid_list{$check_id}->{MATCH} = "changed";
        }
        $total++;
        close(OF);
        $inchanged=0;	
}

sub diff_package_version
{
	$checkoutfile = "$workdir/$hostval"."_"."$check_id.out";
        `touch $checkoutfile`;

        my $file1 = $_[0];
        my $file2 = $_[1];
	if ( (-f "$file1") && (! -f $file2))
        {
                $hostlist{$hostval}->{$check_id}="missing";
                `echo "This collection on $hostval is unique to Run 1 " >> $checkoutfile`;
		if ($checkid_list{$check_id}->{MATCH} ne "changed")
		{
			$checkid_list{$check_id}->{MATCH} = "missing";
		}
                $missing++;
                $total++;
                return;
        }

        if ( (-f "$file2") && (! -f $file1))
        {
                $hostlist{$hostval}->{$check_id}=="new";
                `echo "This collection on $hostval is unique to Run 2 " >> $checkoutfile`;
		if ($checkid_list{$check_id}->{MATCH} ne "changed")
                {
                        $checkid_list{$check_id}->{MATCH} = "new";
                }
                $new++;
                $total++;
                return;
        }

        open(OF, "$file1") || die "Can't open $file1\n";
	$iterator=0;
        while(<OF>)
        {
		$iterator++;
                chomp;
                $line = $_;
                if ( $line =~  /(.*)\|(.*)/)
                {
                        $hash2{$iterator} = $line;
                }

        }
        close(OF);
	open(OF, "$file2") || die "Can't open $file2\n";
        $headingprinted=0;
	$iterator=0;
	while(<OF>)
        {
		$iterator++;
                chomp;
                $line = $_;
                if ( $line =~  /(.*)\|(.*)/)
                {
                        if ($hash2{$iterator} eq '' || $hash2{$iterator} ne $_)
                        {
                                $hostlist{$hostval}->{$check_id}="changed";
                                if($headingprinted == 0)
                                {
                                        $headingprinted=1;
                                        `echo "<b>Line</b>|delim|<b>$coll1</b>|delim|<b>$coll2</b>" >> $checkoutfile`;
                                }
                                $run1val=$hash2{$iterator};
                                $run2val=$_;
                                #if($run1val == '')
                                #{
                                #       $run1val="null";
                                #}
                                #if($run2val == '')
                                #{
                                #       $run2val="null";
                                #}
                                `echo "$iterator|delim|$run1val|delim|$run2val" >> $checkoutfile`;
                                $inchanged++;
                        }
                }

        }
        if($inchanged == 0)
        {
                $hostlist{$hostval}->{$check_id}="same";
                $same++;
                `rm -rf $checkoutfile`;
        }
        else
        {
                $changed++;
		$checkid_list{$check_id}->{MATCH} = "changed";
        }
        $total++;
        close(OF);
        $inchanged=0;
}

sub diff_name_value
{
	$checkoutfile = "$workdir/$hostval"."_"."$check_id.out";
	`touch $checkoutfile`;

	my $file1 = $_[0];
	my $file2 = $_[1];

	if ( (-f "$file1") && (! -f $file2))
	{
		$hostlist{$hostval}->{$check_id}="missing";
		`echo "This collection on $hostval is unique to Run 1 " >> $checkoutfile`;
		if ($checkid_list{$check_id}->{MATCH} ne "changed")
                {
                        $checkid_list{$check_id}->{MATCH} = "missing";
                }
		$missing++;
		$total++;
		return;
	}

	if ( (-f "$file2") && (! -f $file1))
        {
                $hostlist{$hostval}->{$check_id}=="new";
                `echo "This collection on $hostval is unique to Run 2 " >> $checkoutfile`;
		if ($checkid_list{$check_id}->{MATCH} ne "changed")
                {
                        $checkid_list{$check_id}->{MATCH} = "new";
                }
		$new++;
		$total++;
                return;
        }

	open(OF, "$file1") || die "Can't open $file1\n";
	$loopvar=0;
	while(<OF>)
	{
		chomp;$loopvar++;
		$line = $_;
		if ( $line =~  /(.*)=(.*)/)
		{
			$keyvl = "$1"."$loopvar";
			$hash3{$keyvl} = $2;
		}
	
	}
	close(OF);
	open(OF, "$file2") || die "Can't open $file2\n";
	$headingprinted=0;$loopvar=0;
	while(<OF>)
        {
                chomp;$loopvar++;
                $line = $_;
                if ( $line =~  /(.*)=(.*)/)
                {
			$keyvl = "$1"."$loopvar";
                        if (($hash3{$keyvl} eq '' && $2 ne '') || $hash3{$keyvl} ne $2)
			{
				$hostlist{$hostval}->{$check_id}="changed";
				if($headingprinted == 0)
				{
					$headingprinted=1;
					`echo "<b>Parameter</b>|delim|<b>$coll1</b>|delim|<b>$coll2</b>" >> $checkoutfile`;
				}
				$run1val=$hash3{$keyvl};
				$run2val=$2;
				#if($run1val == '')
				#{
				#	$run1val="null";
				#}
				#if($run2val == '')
				#{
				#	$run2val="null";
				#}
				`echo "$1|delim|$run1val|delim|$run2val" >> $checkoutfile`;
				$inchanged++;
			}
                }
        
        }
	if($inchanged == 0)
	{
		$hostlist{$hostval}->{$check_id}="same";
		$same++;
		`rm -rf $checkoutfile`;
	}
	else
	{
		$changed++;
		$checkid_list{$check_id}->{MATCH} = "changed";
	}
	$total++;
	close(OF);
	$inchanged=0;
}

  open(RF, $COLLDIFFFIL) || die "Can't open $COLLDIFFFIL\n";
  $total = 0;
  $missing = 0;
  $changed = 0;
  $new = 0;
  $same = 0;
  $inchanged = 0;

while(<RF>)
{
	chomp;
	@check_details = split(/\|/,$_);
	$check_id = $check_details[0];
	$check_name = $check_details[1];
	$needs_running = $check_details[2];
	$outname = $check_details[3];
	$action_type = $check_details[4];
        $checkid_list{$check_id} = $check_name;
	if (! $checkid_list{$check_id}->{MATCH})
	{
		$checkid_list{$check_id}->{MATCH} = "same";	
	}
	if($action_type eq "SQL_COLLECT")
	{
		$prefix = "d_$outname"."_";
		if ($needs_running eq "ASM")
		{
			$prefix = "a_$outname";
		}
	}
	else
	{
		$prefix = "o_$outname"."_";

	}

	$pdir = `pwd`;chomp($pdir);
	chdir "$res1/outfiles/" or die "can't chdir to $res1/outfiles: $!";
	if($prefix =~ /_u_/)
	{
		@filelist1 = `find . -name "$prefix*"|grep -v "_report\.out"`;
	}
	else
	{
		@filelist1 = `find . -name "$prefix*"|grep -v "_report\.out"|grep -v "_u_"`;
	}
        chdir "$pdir" or die "can't chdir to $pdir: $!";

        chdir "$res2/outfiles/" or die "can't chdir to $res2/outfiles: $!";
	if($prefix =~ /_u_/)
	{
		@filelist2 = `find . -name "$prefix*"|grep -v "_report\.out"`;
	}
	else
	{
		@filelist2 = `find . -name "$prefix*"|grep -v "_report\.out"|grep -v "_u_"`;
	}
        chdir "$pdir" or die "can't chdir to $pdir: $!";

	my %filelist = ();

	foreach (@filelist1)
        {
		$filelist{$_}=1;
	}

	foreach (@filelist2)
        {
		$filelist{$_}=1;
        }

	foreach $val (keys %filelist) 
	{
		$outputfl = $val;
		chomp($outputfl);

		if ($outputfl ne '')
        	{
			my @fields = split(/_/, $outputfl); 
			$hostval = $fields[-1];
			$hostval = `echo $hostval | sed 's/\.out//'`;chomp($hostval);	
			if($action_type eq "SQL_COLLECT" && $needs_running eq "ASM")
                        {
                                $hostval = "GENERIC";
                        }
			$hostlist{$hostval}->{$check_id}="same";
			if($action_type eq "SQL_COLLECT")
		        {
                		$hostlist{$hostval}->{TYPE} = "Database";
		                if ($needs_running eq "ASM")
                		{
		                        $hostlist{$hostval}->{TYPE} = "ASM";
                		}
		        }
		        else
		        {
                		$hostlist{$hostval}->{TYPE} = "HOST";

		        }


	                if (-e "$res1/outfiles/$outputfl")
        	        {
                	        $getformat = `tail -5 $res1/outfiles/$outputfl|sort|tail -1`;
	                }
        	        else
                	{
	                        if (-e "$res2/outfiles/$outputfl")
        	                {
                	                $getformat = `tail -5 $res2/outfiles/$outputfl|sort|tail -1`;
                        	}
	                }
        	        chomp($getformat);
                	if($getformat =~  /(.*)=(.*)/)
	                {
        	                diff_name_value("$res1/outfiles/$outputfl","$res2/outfiles/$outputfl");
                	}
			elsif($getformat =~  /(.*)\|(.*)/)
			{
				diff_package_version("$res1/outfiles/$outputfl","$res2/outfiles/$outputfl");
			}
			elsif($getformat =~  /[\s]+[\d]+[\s]+(.*)/)
                        {
                                diff_line_comp("$res1/outfiles/$outputfl","$res2/outfiles/$outputfl");
                        }
			elsif($getformat =~ /OPatch succeeded./)
			{
				diff_opatch_out("$res1/outfiles/$outputfl","$res2/outfiles/$outputfl");
			}
	        }	
		$getformat = '';
 	} 
}
$total_uniq = 0;
$same_uniq = 0;
$new_uniq = 0;
$missing_uniq = 0;
$changed_uniq = 0;

foreach $check_id (keys %checkid_list)
{
	$total_uniq++;
	if($checkid_list{$check_id}->{MATCH} eq "same")
	{
		$same_uniq++;
	}
	elsif($checkid_list{$check_id}->{MATCH} eq "new")
	{
		$new_uniq++;
	}
	elsif($checkid_list{$check_id}->{MATCH} eq "missing")
	{
		$missing_uniq++;
	}
	else
	{
		$changed_uniq++;
	}
}

if( $changed != 0 || $missing != 0 || $new != 0)
{
	generate_report();
}
else
{
	print "\nAll collections matched between the runs on all nodes and DBs\n\n";
}

