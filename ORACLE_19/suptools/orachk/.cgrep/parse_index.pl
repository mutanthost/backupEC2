# 
# $Header: tfa/src/orachk/src/parse_index.pl /main/3 2017/11/14 22:16:52 rojuyal Exp $
#
# parse_index.pl
# 
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      parse_index.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    apriyada    02/26/16 - Parse part of index.htm and add it to main orachk
#                           report
#    apriyada    02/26/16 - Creation
#


use warnings;

$presentpath = `dirname $0`;chomp($presentpath);

my ($indexfil) = $ARGV[0];
my ($mainfil) = $ARGV[1];

`sed -i 's/"vmptoc" style="DISPLAY: none"/"vmptoc"/' $mainfil`;
`sed -i 's/"vmpcheck" style="DISPLAY: none"/"vmpcheck"/' $mainfil`;

open( IF, '<', $indexfil );
open(OF, ">>$mainfil");
my $begin = 0;

while (<IF>) 
{
    $line=$_;
    chomp $line;
	if ($line =~/nav_end/){
            $begin=0;
        }
	if ($begin == 1)
	{
		print OF "$line\n";
	}
	if ($line =~/nav_start/){
            $begin=1;
        }

} 

close(IF);
close(OF);
