#
# $Header: tfa/src/orachk/src/show_file_in_html.pl /main/5 2018/04/10 21:21:35 apriyada Exp $
#
# show_fil_in_html.pl
#
# Copyright (c) 2013, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      show_fil_in_html.pl	- Append small html files into main html report.
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    rojuyal     04/04/14 	- Creation

use strict;
use warnings;
use Data::Dumper;

use Getopt::Long;

my ($SOURCEFILE);
my ($SFH_RCNT);
my ($SFH_HOSTS);
my ($WH_HOSTS);
my ($CID_HTML_REPFILE);
my ($SFH_ID);
my ($SFH_SUFFIX);
my ($G_OUT_LINES) = 20;
my ($WOH_LINE_CNT);
my ($PDEBUG)              = $ENV{RAT_PDEBUG} || 0;
my ($IS_FIXUP_RUN)        = 0;
my ($COM_TYPE_VALIDATION) = 0;

sub usage {
    print
"Usage: $0 -f SOURCEFILE -o CID_HTML_REPFILE -c SFH_CNT -i SFH_ID -x SFH_SUFFIX -h SFH_HOSTS -w WH_HOSTS -l G_OUT_LINES -n WOH_LINE_CNT -r IS_FIXUP_RUN -t COM_TYPE_VALIDATION\n";
    exit;
}

GetOptions(
    "f=s" => \$SOURCEFILE,
    "o=s" => \$CID_HTML_REPFILE,
    "c=n" => \$SFH_RCNT,
    "i=s" => \$SFH_ID,
    "x=s" => \$SFH_SUFFIX,
    "h=s" => \$SFH_HOSTS,
    "w=s" => \$WH_HOSTS,
    "l=n" => \$G_OUT_LINES,
    "n=n" => \$WOH_LINE_CNT,
    "r=n" => \$IS_FIXUP_RUN,
    "t=n" => \$COM_TYPE_VALIDATION,
) or usage();

my ($SFH_DINDEX)       = 0;
my ($SFH_INDEX)        = 0;
my ($SFH_SHOW_LINE)    = 1;
my ($SFH_DISPLAY_MORE) = 0;
my ($REVIEW_CNT)       = 0;
my (%TRACK_ENTRY)      = ();

if ( $SFH_SHOW_LINE == 1 ) {

    #check is for cell or ibswitch
    if ( $COM_TYPE_VALIDATION == 1 ) {
        open( my $FH, "<", "$SOURCEFILE" ) or die "Cannot open $SOURCEFILE: $!";
        while ( my $sfh_line = <$FH> ) {
            if ( $sfh_line =~ m/TO REVIEW COLLECTED DATA/i ) {
                if ( defined $TRACK_ENTRY{$sfh_line} ) {
                    $TRACK_ENTRY{$sfh_line} = $TRACK_ENTRY{$sfh_line} + 1;
                }
                else {
                    $TRACK_ENTRY{$sfh_line} = 1;
                }
            }
        }
        close($FH);
    }
}

open( my $FH, "<", "$SOURCEFILE" ) or die "Cannot open $SOURCEFILE: $!";
open( my $CHR, ">>", "$CID_HTML_REPFILE" )
  or die "Cannot open $CID_HTML_REPFILE: $!";
while ( my $sfh_line = <$FH> ) {
    my ($sfh_lined) = $sfh_line;
    $sfh_lined =~ s/TO REVIEW COLLECTED //;
    $sfh_lined =~ s/>/\&gt;/g;
    $sfh_lined =~ s/</\&lt;/g;

    my ($SFH_MNAME);
    my ($INST_NAME);

    if ( $SFH_RCNT > 1 && $sfh_line =~ m/TO REVIEW COLLECTED DATA/i ) {
        if ( $sfh_line =~ m/ DATABASE -/i or $sfh_line =~ m/ ORACLE_HOME -/i ) {
            $SFH_MNAME = ( split ' ', $sfh_line )[7];
        }
        else {
            $SFH_MNAME = ( split ' ', $sfh_line )[5];
        }

        if ( $SFH_HOSTS =~ m/$SFH_MNAME/i ) {
            $SFH_SHOW_LINE = 1;
        }
        else {
            $SFH_SHOW_LINE = 0;
        }

        if (   $sfh_line =~ m/ DATABASE_HOME -/i
            or $sfh_line =~ m/DATABASE_HOME - TIMESTEN/i )
        {
            $SFH_MNAME = ( split ' ', $sfh_line )[7];
            if ( $sfh_line =~ m/BI_INSTANCE -/i ) {
                if ( $WH_HOSTS =~ m/$SFH_MNAME:/i ) {
                    $INST_NAME = ( split ' ', $sfh_line )[10];
                    if ( $WH_HOSTS =~ m/$INST_NAME/i ) {
                        $SFH_SHOW_LINE = 1;
                    }
                    else {
                        $SFH_SHOW_LINE = 0;
                    }
                }
                else {
                    $SFH_SHOW_LINE = 0;
                }
            }
            else {
                if ( $WH_HOSTS =~ m/$SFH_MNAME$/i ) {
                    $SFH_SHOW_LINE = 1;
                }
                else {
                    $SFH_SHOW_LINE = 0;
                }
            }
        }
    }

    if ( $SFH_SHOW_LINE == 1 ) {
        if (%TRACK_ENTRY) {
        	# check 0th entry for old data
            if ( defined $TRACK_ENTRY{$sfh_line}
                and $TRACK_ENTRY{$sfh_line} > 1 )
            {
                $TRACK_ENTRY{$sfh_line} = $TRACK_ENTRY{$sfh_line} - 1;
                $SFH_SHOW_LINE = 0;
            }
        }
    }

    if ( $IS_FIXUP_RUN == 1  and !%TRACK_ENTRY) {
        if ( $SFH_SHOW_LINE == 1 ) {
            $REVIEW_CNT = $REVIEW_CNT + 1;

            # include '2' for old result in html
            if ( $REVIEW_CNT < 4 ) {
                $SFH_SHOW_LINE = 0;
            }
        }
    }

    if ( $SFH_SHOW_LINE == 1 ) {
        if ( $SFH_DINDEX == $G_OUT_LINES ) {
            print $CHR "<div id=$SFH_ID"
              . '_more_text'
              . $SFH_SUFFIX
              . ' style="DISPLAY: none">' . "\n";

            $SFH_DISPLAY_MORE = 1;
        }
        print $CHR $sfh_lined ;

        $SFH_DINDEX++;
    }
    $SFH_INDEX++;

    if (   $SFH_INDEX >= $WOH_LINE_CNT
        && $SFH_DINDEX > $G_OUT_LINES
        && $SFH_DISPLAY_MORE == 1 )
    {
        print $CHR qq{</div><a id="$SFH_ID}
          . qq{_more_text$SFH_SUFFIX}
          . qq{_mh" class=more_less_style onclick="javascript:ShowHide('}
          . qq{$SFH_ID}
          . qq{_more_text$SFH_SUFFIX')" href="javascript:;">Click for more data</a>\n};
    }

}
close($CHR);
close($FH);
