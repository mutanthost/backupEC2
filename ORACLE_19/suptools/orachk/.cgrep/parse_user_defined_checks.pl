# 
# $Header: tfa/src/orachk/src/parse_user_defined_checks.pl /main/7 2017/08/11 17:38:18 rojuyal Exp $
#
# parse_user_defined_checks.pl
# 
# Copyright (c) 2015, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      parse_user_defined_checks.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    apriyada    07/16/15 - Filter CDATA
#    apriyada    05/20/15 - Parse user defined checks
#    apriyada    05/20/15 - Creation
#

my $grp_str = $ARGV[0];    
my $REFFIL = $ARGV[1];
my $REFFIL1 = $ARGV[2];
my $UDC = $ARGV[3];
my $sys_component =  $ARGV[4];

my $user_def_chk  = $ARGV[5];
my $wrkdir = $ARGV[6];

my @oracle_version;

my $uname = `uname`;chomp($uname);

#`cat $user_def_chk | perl -e '\$/ = ""; \$_ = <>; s/<\!--.*?-->//gs; print;' > $wrkdir/udc_no_comments.xml`;

open( IF, '<', $user_def_chk );
open(OF, ">$wrkdir/udc_no_comments.xml");
$cmtbegin=0;
while (<IF>) {
    $line=$_;
    chomp $line;
    $line =~ s/<!--.*?-->//g;
    $StartTag='<!--';
    $EndTag='-->';
        if ($line =~/<!--/){
            $cmtbegin=1;
        }
	if ($line =~/-->/){
            $cmtbegin=0;
        }
           
        if($cmtbegin == 0){
           print OF "$line\n";            
        }
  
}
close(OF);
close(IF);


$user_def_chk = "$wrkdir/udc_no_comments.xml";

open( IF, '<', $user_def_chk );
open(OF, ">$wrkdir/udc_no_cdata.xml");
$cdata=0;
while (<IF>) {
    $line=$_;
    chomp $line;
        if ($line =~/<!\[CDATA\[/){
            $line =~ s/<!\[CDATA\[//g;
            $cdata=1;
        }
        if ($line =~/\]\]>/ && $cdata == 1 ){
	    $line =~ s/\]\]>//g;
            $cdata=0;
        }

        print OF "$line\n";
  
}
close(OF);
close(IF);

`mv $wrkdir/udc_no_cdata.xml $wrkdir/udc_no_comments.xml`;

sub set_check_valid
{
	$platform_valid = 1;

	open( COLFIL, '<', $REFFIL );

	while ( <COLFIL> )
	{
		$last_line = $this_line;
		$this_line = $_;
		if ($this_line =~ /COLLECTIONS_START/)
		{
			@num = split(/\./,$last_line);
			$cons_str = `echo "$num[0]"|sed 's/_//'`;
			$check_num = `perl -e 'print "$cons_str" + 1;'`;
			$cons_str = "_$check_num.0.0.0.0.0.0.0.0.0-LEVEL 1-CHECK_ID $check_id\nCOLLECTIONS_START";
			last;
		}
	}#while
	close(COLFIL);
	`perl -i -pe 's/COLLECTIONS_START/$cons_str/' $REFFIL`;

}

open( CHKINP, '<', $user_def_chk );

while ( my $line = <CHKINP> ) 
{
	chomp;
	$line =~ s/^\s*(.*?)\s*$/$1/;
	$line =~ s/<!--.*?-->//g;
	$line =~ s/\\/\\\\\\\\/g;
	$line =~ s/\$/\\\\\\\$/g;

	if ( $line =~ /CHECK AUDIT_CHECK_NAME/ )
	{
		$platform_valid = 0;
		$on_hold = 0;
		$param_path = "";
		$ora_home_type = "";
		$db_role = "";
		$db_type = "";
		$db_mode = "";
		$comp_dep = "";
		$comp = "";
		$os_cmd_rep = 0;
		$os_cmd_start = 0;
		$sql_cmd_rep = 0;
		$sql_cmd_start = 0;		
		$check_id= `cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 32 | head -n 1`;chomp($check_id);
		if($uname eq "SunOS")
		{
			$check_id= `cat /dev/urandom | tr -dc '[:digit:]' | fold -w 32 | head -n 1`;chomp($check_id);
		}
		`echo "$check_id|" >> $UDC`;
		$check_name = `echo "$line" |sed 's/<CHECK AUDIT_CHECK_NAME=//'|sed 's/"//'|sed 's/>//'`;
	}

	if ( $line =~ /DISABLED/ )
        {
                $on_hold = `echo "$line" | sed 's/<\\/DISABLED>//'|sed 's/<DISABLED>//'|sed 's/ //'`;
                $on_hold =~ s/^\s*(.*?)\s*$/$1/;
        }

	if ( $on_hold == 0 && $line =~ /ORACLE_VERSION/ )
        {
		$ora_ver = `echo "$line" | sed 's/<\\/ORACLE_VERSION>//'|sed 's/<ORACLE_VERSION>//'|sed 's/ //'`;
		$ora_ver =~ s/^\s*(.*?)\s*$/$1/;
		@oracle_version = split(/:/,$ora_ver);
        }

	if ( $on_hold == 0 && $line =~ /<PLATFORMS>/ && $line =~ /<\/PLATFORMS>/ )
        {
                $pttyp = `echo "$line" | sed 's/<\\/PLATFORMS>//'|sed 's/<PLATFORMS>//'|sed 's/ //'`;
                $pttyp =~ s/^\s*(.*?)\s*$/$1/;
		if($pttyp eq "")
		{
			$pttyp="*";
		}

                if ($pttyp =~ /\*/ && $ora_ver =~ /\*/)
                {
                        set_check_valid;
                }
                else
                {
                        if ($pttyp =~ /\*/)
                        {
                                foreach $o (@oracle_version)
                                {
                                        if ($grp_str =~ /$o/)
                                        {
                                                set_check_valid;
                                                last;
                                        }
                                }
                        }
                }

        }

	if ( $on_hold == 0 && $line =~ /PLATFORM TYPE/ )
        {
		$pttyp = `echo "$line" |sed 's/.*<PLATFORM TYPE=//'|sed 's/"//'|sed 's/>//'|sed 's/ //'`;
		$pttyp =~ s/^\s*(.*?)\s*$/$1/;
		if ($pttyp =~ /\*/ && $ora_ver =~ /\*/)
		{
			set_check_valid;
		}
		else
		{
			if ($pttyp =~ /\*/)
			{
				foreach $o (@oracle_version)
				{
					if ($grp_str =~ /$o/)
					{
						set_check_valid;
						last;
					}	
				}
			}
		}

        }

	if ( $on_hold == 0 && $line =~ /FLAVOR/ && $pttyp !~ /\*/ )
        {
		$fl = `echo "$line" | sed 's/<\\/FLAVOR>//'|sed 's/<FLAVOR>//'|sed 's/\s+//'`;
		$fl =~ s/^\s*(.*?)\s*$/$1/;
                @flavor = split(/:/,$fl);
		if ($ora_ver =~ /\*/)
		{
			if($fl =~ /\*/)
			{
				if ($grp_str =~ /$pttyp/)
				{
					set_check_valid;
				}
			}
			else
			{
				foreach $f (@flavor)
                                {
                                        $flavor1="$f";
                                        $cmpstr = $pttyp."$flavor1";
                                        if ($grp_str =~ /$cmpstr/)
                                        {
                                                set_check_valid;
                                        }#compare str matches

                                }#foreach
			}
		}
		else
		{
			foreach $o (@oracle_version) 
			{
				$crs_ver = "$o";
				if($fl =~ /\*/)
				{
					if ($grp_str =~ /$pttyp/ && $grp_str =~ /$o/)
					{
						set_check_valid;
					}
				}
				else
				{
					foreach $f (@flavor)
					{
						$flavor1="$f";
						$cmpstr = $pttyp."$flavor1"."_"."$crs_ver";
						if ("$cmpstr-" eq "$grp_str")
						{
							set_check_valid;
						}#compare str matches
					
					}#foreach 
				}
			}#foreach
		}
        }#flavor

	if ( $platform_valid == 1 && $os_cmd_start == 1 && $line !~ /<\/OS_COMMAND>/)
        {
		$line =~ s/^\s*(.*?)\s*$/$1/;
		$line =~ s/&amp;/&/g;
		$line =~ s/&gt;/>/g;
		$line =~ s/&lt;/</g;
                $os_cmd = $os_cmd."\n$line";
        }
	if ( $platform_valid == 1 && $line =~ /<OS_COMMAND>/ )
        {
		$os_cmd_start = 1;
		$os_cmd="";
		$sql_cmd="null";
	}
	if ( $platform_valid == 1 && $line =~ /<\/OS_COMMAND>/ )
        {
                $os_cmd_start = 0;
		
        }
	if ($platform_valid == 1 &&  $os_cmd_rep == 1 && $line !~ /<\/OS_COMMAND_REPORT>/)
        {
		$line =~ s/^\s*(.*?)\s*$/$1/;
		$line =~ s/&amp;/&/g;
                $line =~ s/&gt;/>/g;
                $line =~ s/&lt;/</g;
                $cmd_rep_os = $cmd_rep_os."\n$line";
        }
	if ( $platform_valid == 1 && $line =~ /<OS_COMMAND_REPORT>/ )
        {
                $os_cmd_rep = 1;
		$cmd_rep_os = "";
		$cmd_rep_sql = "null";
        }
        if ( $platform_valid == 1 && $line =~ /<\/OS_COMMAND_REPORT>/ )
        {
                $os_cmd_rep = 0;

        }
	if ( $platform_valid == 1 && $sql_cmd_start == 1 && $line !~ /<\/SQL_COMMAND>/)
        {
		$line =~ s/^\s*(.*?)\s*$/$1/;
		$line =~ s/&amp;/&/g;
                $line =~ s/&gt;/>/g;
                $line =~ s/&lt;/</g;
                $sql_cmd = $sql_cmd."\n$line";
        }
	if ( $platform_valid == 1 && $line =~ /<SQL_COMMAND>/ )
        {
                $sql_cmd_start = 1;
                $sql_cmd="";
		$os_cmd="null";
        }
        if ( $platform_valid == 1 && $line =~ /<\/SQL_COMMAND>/ )
        {
                $sql_cmd_start = 0;
                
        }
	if ( $platform_valid == 1 && $sql_cmd_rep == 1 && $line !~ /<\/SQL_COMMAND_REPORT>/)
        {
		$line =~ s/^\s*(.*?)\s*$/$1/;
		$line =~ s/&amp;/&/g;
                $line =~ s/&gt;/>/g;
                $line =~ s/&lt;/</g;
                $cmd_rep_sql = $cmd_rep_sql."\n$line";
        }
        if ( $platform_valid == 1 && $line =~ /<SQL_COMMAND_REPORT>/ )
        {
                $sql_cmd_rep = 1;
                $cmd_rep_sql = "";
		$cmd_rep_os = "null";
        }
        if ( $platform_valid == 1 && $line =~ /<\/SQL_COMMAND_REPORT>/ )
        {
                $sql_cmd_rep = 0;

        }

	if ( $line =~ /ORACLE_HOME_TYPE/ )
        {
                $ora_home_type = `echo "$line" | sed 's/<\\/ORACLE_HOME_TYPE>//'|sed 's/<ORACLE_HOME_TYPE>//'|sed 's/\s+//'`;

        }	
	if ( $line =~ /PARAM_PATH/ )
        {
                $param_path = `echo "$line" | sed 's/<\\/PARAM_PATH>//'|sed 's/<PARAM_PATH>//'|sed 's/\s+//'`;

        }
	if ( $line =~ /COMPONENT_DEPENDENCY/ )
        {
                $comp_dep = `echo "$line" | sed 's/<\\/COMPONENT_DEPENDENCY>//'|sed 's/<COMPONENT_DEPENDENCY>//'|sed 's/\s+//'`;

        }
	if ( $line =~ /EXECUTE_ONCE/ )
        {
                $exec_once = `echo "$line" | sed 's/<\\/EXECUTE_ONCE>//'|sed 's/<EXECUTE_ONCE>//'|sed 's/\s+//'`;

	}
	if ( $line =~ /CANDIDATE_SYSTEMS/ )
        {
                $comp = `echo "$line" | sed 's/<\\/CANDIDATE_SYSTEMS>//'|sed 's/<CANDIDATE_SYSTEMS>//'|sed 's/\s+//'`;
		chomp($comp);

        }
        if ( $line =~ /DATABASE_ROLE/ )
        {
                $db_role = `echo "$line" | sed 's/<\\/DATABASE_ROLE>//'|sed 's/<DATABASE_ROLE>//'|sed 's/\s+//'`;

        }
        if ( $line =~ /DATABASE_TYPE/ )
        {
                $db_type = `echo "$line" | sed 's/<\\/DATABASE_TYPE>//'|sed 's/<DATABASE_TYPE>//'|sed 's/\s+//'`;

        }
	if ( $line =~ /DATABASE_MODE/ )
        {
                $db_mode = `echo "$line" | sed 's/<\\/DATABASE_MODE>//'|sed 's/<DATABASE_MODE>//'|sed 's/\s+//'`;

        }
	if ( $line =~ /OPERATOR/ )
        {
                $oper = `echo "$line" | sed 's/<\\/OPERATOR>//'|sed 's/<OPERATOR>//'|sed 's/\s+//'`;

        }
	if ( $line =~ /COMPARE_VALUE/ )
        {
                $comp_val = `echo "$line" | sed 's/<\\/COMPARE_VALUE>//'|sed 's/<COMPARE_VALUE>//'|sed 's/\s+//'`;

        }
	if ( $line =~ /ALERT_LEVEL/ )
        {
                $alvl = `echo "$line" | sed 's/<\\/ALERT_LEVEL>//'|sed 's/<ALERT_LEVEL>//'|sed 's/\s+//'`;
		$alvl =~ s/^\s*(.*?)\s*$/$1/;

        }
	if ( $line =~ /PASS_MSG/ )
        {
		$pass_msg =~ s/\"/\\\"/g;
                $pass_msg = `echo "$line" | sed "s/<\\/PASS_MSG>//"|sed "s/<PASS_MSG>//"|sed "s/\s+//"`;
		$pass_msg =~ s/^\s*(.*?)\s*$/$1/;

        }
	if ( $line =~ /FAIL_MSG/ )
        {
		$fail_msg =~ s/\"/\\\"/g;
                $fail_msg = `echo "$line" | sed "s/<\\/FAIL_MSG>//"|sed "s/<FAIL_MSG>//"|sed "s/\s+//"`;
		$fail_msg =~ s/^\s*(.*?)\s*$/$1/;

        }
#	if ( $platform_valid == 1 && $cmt == 1 && $line !~ /<\/BENEFIT_IMPACT>/ && $line !~ /<RISK>/ && $line !~ /<\/RISK>/ && $line !~ /<ACTION_REPAIR>/ && $line !~ /<\/ACTION_REPAIR>/)
#        {
#		$line =~ s/^\s*(.*?)\s*$/$1/;
 #               $cmt_txt = $cmt_txt."\n$line";
  #      }
#	if ( $platform_valid == 1 && $line =~ /<BENEFIT_IMPACT>/ )
#        {
#                $cmt = 1;
#                $cmt_txt = "";
#        }
#        if ( $platform_valid == 1 && $line =~ /<\/ACTION_REPAIR>/ )
#        {
#                $cmt = 0;
#       }

	if ( $platform_valid == 1 && $cmt1 == 1 && $line !~ /<\/BENEFIT_IMPACT>/)
	{
		$line =~ s/^\s*(.*?)\s*$/$1/;
		 $bi = $bi."\n$line";
	}
	if ( $platform_valid == 1 && $line =~ /<BENEFIT_IMPACT>/ )
        {
                $cmt1 = 1;
                $bi = "";
		$cmt_txt = "";
        }
	if ( $platform_valid == 1 && $line =~ /<\/BENEFIT_IMPACT>/ )
        {
                $cmt1 = 0;
	}

        if ( $platform_valid == 1 && $cmt2 == 1 && $line !~ /<\/RISK>/)
        {
                $line =~ s/^\s*(.*?)\s*$/$1/;
                 $risk = $risk."\n$line";
        }
        if ( $platform_valid == 1 && $line =~ /<RISK>/ )
        {
                $cmt2 = 1;
                $risk = "";
        }
        if ( $platform_valid == 1 && $line =~ /<\/RISK>/ )
        {
                $cmt2 = 0;
        }
	if ( $platform_valid == 1 && $cmt3 == 1 && $line !~ /<\/ACTION_REPAIR>/)
        {
                $line =~ s/^\s*(.*?)\s*$/$1/;
                 $ar = $ar."\n$line";
        }
        if ( $platform_valid == 1 && $line =~ /<ACTION_REPAIR>/ )
        {
                $cmt3 = 1;
                $ar = "";
        }
        if ( $platform_valid == 1 && $line =~ /<\/ACTION_REPAIR>/ )
        {
                $cmt3 = 0;
		if($ar eq "" || $risk eq "")
		{
			$cmt_txt = "$bi\n$risk\n$ar\n";
		}
		else
		{
			$bi = "Benefit / Impact:"."\n$bi";
			$risk = "\nRisk:"."\n$risk";
			$ar = "\nAction / Repair:"."\n$ar";
			$cmt_txt = "$bi\n$risk\n$ar\n";
		}
        }

	if ( $platform_valid == 1 && $link == 1 && $line !~ /<\/LINKS>/ && $line ne "")
        {
		$line = `echo "$line" | sed 's/<\\/LINK>//'|sed 's/<LINK>//'|sed 's/\s+//'`;
		$line =~ s/^\s*(.*?)\s*$/$1/;
                $link_txt = $link_txt."\n_$check_id-LINK$lnk_cnt $line";
		$lnk_cnt = `perl -e 'print "$lnk_cnt" + 1;'`;
        }
        if ( $platform_valid == 1 && $line =~ /<LINKS>/ )
        {
                $link = 1;
		$lnk_cnt=1;
                $link_txt = "";
        }
        if ( $platform_valid == 1 && $line =~ /<\/LINKS>/ )
        {
		#$link_txt = `echo "$link_txt" | sed 's#/#\/#'`;
                $link = 0;

        }
	if ( $line =~ /\/CHECK/ )
        {
		$check_in_collection = "";
		if ($comp eq "" || $comp eq "*")
		{
			$comp = "$sys_component";
		}
		if ($os_cmd eq "null")
		{
			$check_in_collection = $check_in_collection."_$check_id-SQL_COMMAND_START\n";
			$check_in_collection = $check_in_collection."$sql_cmd\n";
			$check_in_collection = $check_in_collection."_$check_id-SQL_COMMAND_END\n";
			$check_in_collection = $check_in_collection."_$check_id-SQL_COMMAND_REPORT_START\n";
                        $check_in_collection = $check_in_collection."$cmd_rep_sql\n";
                        $check_in_collection = $check_in_collection."_$check_id-SQL_COMMAND_REPORT_END\n";
			$check_in_collection = $check_in_collection."_$check_id-TYPE SQL\n";
		}
		else
		{
			$check_in_collection = $check_in_collection."_$check_id-OS_COMMAND_START\n";
			$check_in_collection = $check_in_collection."$os_cmd\n";
			$check_in_collection = $check_in_collection."_$check_id-OS_COMMAND_END\n";
			$check_in_collection = $check_in_collection."_$check_id-OS_COMMAND_REPORT_START\n";
                        $check_in_collection = $check_in_collection."$cmd_rep_os\n";
                        $check_in_collection = $check_in_collection."_$check_id-OS_COMMAND_REPORT_END\n";
			$check_in_collection = $check_in_collection."_$check_id-TYPE OS\n";
		}
		if ($param_path ne "")
		{
			$check_in_collection = $check_in_collection."_$check_id-PARAM_PATH $param_path\n";
		}
		if($ora_home_type ne "")
		{
			$check_in_collection = $check_in_collection."_$check_id-HOME_PATH $ora_home_type\n";
		}

		$check_in_collection = $check_in_collection."_$check_id-NEEDS_RUNNING $comp_dep\n";
		$check_in_collection = $check_in_collection."_$check_id-EXECUTE_ONCE $exec_once\n";
		$check_in_collection = $check_in_collection."_$check_id-AUDIT_CHECK_NAME $check_name\n";
		$check_in_collection = $check_in_collection."_$check_id-REQUIRES_ROOT 0\n";
		$check_in_collection = $check_in_collection."_$check_id-COMPONENTS $comp\n";	
		if($db_role ne "")
		{
			$check_in_collection = $check_in_collection."_$check_id-DATABASE_ROLE $db_role\n";
		}
		if($db_type ne "")
		{
			$check_in_collection = $check_in_collection."_$check_id-DATABASE_TYPE $db_type\n";
		}
		if( $db_mode ne "")
		{
			$check_in_collection = $check_in_collection."_$check_id-DATABASE_MODE $db_mode\n";
		}
		$check_in_collection = $check_in_collection."_$check_id-OPERATOR $oper\n";
		$check_in_collection = $check_in_collection."_$check_id-COMPARE_VALUE $comp_val\nCOLLECTIONS_END";

		if ($platform_valid == 1)
		{
			#$check_in_collection =~ s/\$/\\\\\\\$/g;
			$check_in_collection =~ s/\//\\\//g;	
			$check_in_collection =~ s/\`/\\\`/g;
                        $check_in_collection =~ s/\"/\\\"/g;
                        $check_in_collection =~ s/\^/\\\^/g;
                        $check_in_collection =~ s/\(/\\\(/g;
                        $check_in_collection =~ s/\)/\\\)/g;
			`perl -i -pe "s/COLLECTIONS_END/$check_in_collection/" $REFFIL`;
		}

		$check_in_rules = "";	
		$check_in_rules = $check_in_rules."_$check_id-ALERT_LEVEL $alvl\n";
		$check_in_rules = $check_in_rules."_$check_id-PASS_MSG $pass_msg\n";
		$check_in_rules = $check_in_rules."_$check_id-FAIL_MSG $fail_msg\nRULES_END";

		if ($platform_valid == 1)
		{
			#$check_in_rules =~ s/\$/\\\\\\\$/g;
			$check_in_rules =~ s/\//\\\//g;
			$check_in_rules =~ s/\`/\\\`/g;
                        #$check_in_rules =~ s/\"/\\\"/g;
                        $check_in_rules =~ s/\^/\\\^/g;
                        $check_in_rules =~ s/\(/\\\(/g;
                        $check_in_rules =~ s/\)/\\\)/g;
			`perl -i -pe "s/RULES_END/$check_in_rules/" $REFFIL1`;
		}

		$check_in_rules = "";
		$check_in_rules = $check_in_rules."_$check_id-BEGIN_COMMENTS\n";
		$check_in_rules = $check_in_rules."$cmt_txt\n";
		$check_in_rules = $check_in_rules."_$check_id-END_COMMENTS\n";
		$check_in_rules = $check_in_rules."_$check_id-PLA_LINE user_defined_checks\n";
		$check_in_rules = $check_in_rules."$link_txt\nAPPENDIX_END";
		
		if ($platform_valid == 1)
		{
			#$check_in_rules =~ s/\$/\\\\\\\$/g;
			$check_in_rules =~ s/\//\\\//g;
			$check_in_rules =~ s/\`/\\\`/g;
		        $check_in_rules =~ s/\!/\\\!/g;
		        $check_in_rules =~ s/\^/\\\^/g;
		        $check_in_rules =~ s/\(/\\\(/g;
		        $check_in_rules =~ s/\)/\\\)/g;
			$check_in_rules =~ s/\"/\\\"/g;
			`perl -i -pe "s!APPENDIX_END!$check_in_rules!" $REFFIL1`;
		}
        }

}

close(CHKINP);

