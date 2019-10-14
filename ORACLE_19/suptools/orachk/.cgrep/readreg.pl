# 
# $Header: tfa/src/orachk/src/readreg.pl /main/5 2018/11/12 02:51:18 rojuyal Exp $
#
# readreg.pl
# 
# Copyright (c) 2014, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      readreg.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    gadiga      06/22/14 - read windows registry
#    gadiga      06/22/14 - Creation
# 

use File::Spec::Functions;

my $outdir = ".";
if ( $ARGV[0] && -d "$ARGV[0]" )
{
  $outdir = $ARGV[0];
}

open(F1, ">$outdir/registry.out");
open(F2, ">$outdir/windiscover.out");
open(F3, ">$outdir/win_oratab.out");

sub read_key
{
  my $key = shift;
  $key =~ s/\s+$//;
  #print "reg query \"$key\"\n";
  @out = `reg query "$key"`;
  chomp(@out);
  return @out;
}

sub get_dname
{
  my $h = shift;
  $h =~ s/\\/\//g;
  $h =~ s/^\s+//;
  $h =~ s/\s+$//;

  return $h;
}

# Main starts
# system command hangs on windows....
# system("sc query > $outdir/win_services.out");
my $SC_OUTPUT = `sc query`;
open(SCFIL, '>', catfile($outdir, "win_services.out"));
print SCFIL $SC_OUTPUT;
close(SCFIL);

my @out = read_key ("HKEY_LOCAL_MACHINE\\SOFTWARE\\Oracle");
my $line = "";
my $KEY_CRS = $ENV{RAT_KEY_CRS};
my $KEY_DB = $ENV{RAT_KEY_DB};

foreach $line(@out)
{
  print F1 "$line\n";
  if ( $line =~ /^\s+inst_loc\s+\w+\s+(.*)/ )
  { # Inventory location
    my $h = get_dname($1);
    print F2 "INV_LOC=$h\n";
  }

  #$line =~ s/\\/\\\\/g;
  if ( $line =~ /\\KEY_/ )
  { # Found a home
    $typ = "U";
    if ( $line =~ /KEY_ORAGI/i || $line =~ /KEY_ORACRS/i || (defined $KEY_CRS && $line =~ /$KEY_CRS/i))
    { #GI/CRS Home
      $typ = "G";
    }
     elsif ( $line =~ /KEY_ORADB/i || $line =~ /KEY_OH/i || (defined $KEY_DB && $line =~ /$KEY_DB/i))
    {# Database home
      $typ = "R";
    }

    #print "Reading $line - $typ\n";
    @out1 = read_key($line);
    foreach my $line1 (@out1)
    {
      if ( $line1 =~ /^\s+ORACLE_HOME\s+\w+\s+(.*)/ )
      {
        my $h = get_dname($1);
        if ( $typ eq "R" )
        {
          my $sqlplus = catfile($h, "bin", "sqlplus");
          my $v = "";
	  my @v = `$sqlplus -v`;
          chomp(@v);
	  foreach my $lv (@v )
	  {
	    if ( $lv =~ /Release/ )
            {
	      $v = $lv;
              $v =~ s/.*Release\s+//;
              $v =~ s/\s+.*//;
	    }
	  }
          my $s = "";
          my $sid = "";
	  my $dirname = catfile($h, "database");
	  my @files = ();
          if ( -d $dirname )
          {
	    opendir my($dh), $dirname or print "Couldn't open dir '$dirname': $!";
	    @files = readdir $dh;
	    closedir $dh;
          }
          chomp(@files);
          foreach my $file (@files)
          {
            if ( $file =~ /spfile(.*)\.ora/i || $file =~ /init(.*)\.ora/i )
            {
              $s = $1;
              if ( $s )
              {
                $sid = $s if ( ! $sid);
                print F3 "$s|$h|N\n";
              }
            }
          }
          print F2 "ORACLE_HOME=$h|$sid|$v\n";
        }
         elsif ( $typ eq "G" )
        {
          print F2 "CRS_INSTALLED=1\n";
          print F2 "CRS_HOME=$h\n";
        }
      }
      print F1 "$line1\n";
    }
  }
}

close(F1);
close(F2);
close(F3);

