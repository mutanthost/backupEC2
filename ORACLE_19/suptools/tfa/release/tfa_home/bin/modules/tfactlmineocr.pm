#
# $Header: tfa/src/v2/tfa_home/bin/modules/tfactlmineocr.pm /main/5 2017/07/07 20:16:15 bburton Exp $
#
# mineocr.pm
#
# Copyright (c) 2016, 2017, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      mineocr.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    bibsahoo    06/28/17 - FIX BUG 26363301
#    bibsahoo    03/10/17 - DBGlevel Support For Windows
#    llakkana    05/12/16 - Fix for solaris platform
#    bibsahoo    02/17/16 - Creation
#
package tfactlmineocr;

use strict;
use warnings;
use Exporter;
use File::Spec;
use POSIX;
use File::Basename;
use Data::Dumper;
use English;
use POSIX;
use File::Spec::Functions;

use vars qw(@ISA @EXPORT);

BEGIN {
    @ISA	= qw(Exporter);
    @EXPORT 	= qw(get_platform get_orainv get_oratab get_olrloc c_check_SuperUser getGridHome c_trim c_printOut readCfgFile getNodeList
		getClusterName srvctl run_as_user c_system_cmd_capture_noprint getOraInvLoc getGridOwner getCrsdResources getCrsdResourcesCfg
		discover_crs_db_asm_and_write_kvout);

}

our $CRS_HOME;
our $pdebug = 0;

sub get_platform {
    my $platform = "$^O";
    chomp($platform);

    return $platform;
}

sub get_orainv {
    my ($orainv) 	= '/etc/oraInst.loc';
    if (exists $ENV{'RAT_INV_LOC'} && defined $ENV{'RAT_INV_LOC'}) {
        $orainv = $ENV{'RAT_INV_LOC'};
	return $orainv;
    }
    my ($platform)	= get_platform();
    if ( $platform eq "solaris" || $platform eq "SunOS" || $platform eq "HP-UX" ) { 
      $orainv = '/var/opt/oracle/oraInst.loc'; 
    }

    return $orainv;
}

sub get_oratab {
    my ($oratab) 	= '/etc/oratab';
    if (exists $ENV{'RAT_ORATAB_LOC'} && defined $ENV{'RAT_ORATAB_LOC'}) {
        $oratab = $ENV{'RAT_ORATAB_LOC'};
	return $oratab;
    }
    my ($platform) 	= get_platform();
    if ( $platform eq "solaris" || $platform eq "SunOS" ) {
      $oratab = '/var/opt/oracle/oratab'; 
    }

    return $oratab;
}

sub get_olrloc {
    my ($olrloc) 	= '/etc/oracle/olr.loc';
    if (exists $ENV{'RAT_OLR_LOC'} && defined $ENV{'RAT_OLR_LOC'}) {
        $olrloc = $ENV{'RAT_OLR_LOC'};
	return $olrloc;
    }
    my ($platform) 	= get_platform();
    if ( $platform eq "solaris" || $platform eq "SunOS" ) { 
      $olrloc = '/var/opt/oracle/olr.loc'; 
    }

    return $olrloc;
}

sub c_check_SuperUser {
    my $superUser = "root";
    my $usrname   = getpwuid($<);
    if ( $usrname ne $superUser ) {
        return "";
    }
    return $superUser;
}

sub getGridHome {
    if ($ENV{CRS_HOME}) { return $ENV{CRS_HOME}; }
    if (defined $CRS_HOME) {  return $CRS_HOME; }

    my $olrloc	= get_olrloc();
    
    if ( -f "$olrloc" ) {
        my %olr = readCfgFile($olrloc);
        my $ch  = $olr{crs_home};

        if ( -e $ch ) {
            return $ch;           
        } else {   
            exit 0;
        } 
    } else {
        exit 0;
    }     
}

sub c_trim {
    my $str = $_;
    $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    return $str;
}

sub c_printOut {
    foreach my $line (@_) {
        $line = c_trim($line);
    }
}

sub readCfgFile {
    my %cfg;

    open( FH, "<", $_[0] ) or return 0;
    while (<FH>) {
        chomp;
        s/#.*//;
        s/^\s+//;
        s/\s+$//;
        next unless length;
        my ( $var, $value ) = split( /\s*=\s*/, $_, 2 );
        $cfg{$var} = $value;
    }
    close FH;

    return %cfg;
}

sub getNodeList {
    my $ghome = getGridHome();
    my $olsnodes = catfile( $ghome, "bin", "olsnodes" );
    my ( $rc, @output ) = c_system_cmd_capture_noprint($olsnodes);
    return @output;
}

sub getClusterName {
    my $ghome    = getGridHome();
    my $olsnodes = catfile( $ghome, "bin", "olsnodes" );
    my $cmd      = qq($olsnodes -c);
    my ( $rc, @output ) = c_system_cmd_capture_noprint($cmd);
    return $output[0];
}

sub srvctl {
    my $run_as_oracle_owner = $_[0];
    my $srvctl_args         = $_[1];
    my $ORA_CRS_HOME        = getGridHome();
    my $ORACLE_OWNER        = getGridOwner();
    my $srvctlbin           = catfile( $ORA_CRS_HOME, "bin", "srvctl" );
    my $status;

    my $cmd = "${srvctlbin} $srvctl_args";

    if ($run_as_oracle_owner) {
        $status = run_as_user( $ORACLE_OWNER, ${cmd} );
    }
    else {
        $status = system_cmd( ${cmd} );
    }

    if ( ( 0 == $status ) || ( 2 == $status ) ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub run_as_user {
    my $user = $_[0];
    my $cmd;

    if ($user) {
        my $SU = "/bin/su";
        $cmd = "$SU $user -c \"$_[1]\"";
    }
    else {
        $cmd = $_[1];
    }

    return system_cmd($cmd);
}

sub c_system_cmd_capture_noprint {
    my $rc  = 0;
    my $prc = 0;
    my @output;

    my $cmd;
    my $platform = get_platform();
    if ($platform eq "MSWin32") {
        $cmd = "@_";
        my $str = `$cmd`;
        if ( !$str ) { $rc = -1; }
        else {
             @output = split /\n/, $str;
             $prc = $CHILD_ERROR >> 8;
             chomp(@output);
        }
    } else {
        $cmd = "@_ 2>&1 |";
        if ( !open( CMD, "@_ 2>&1 |" ) ) { $rc = -1; }
        else {
             @output = (<CMD>);
             close CMD;
             $prc = $CHILD_ERROR >> 8;
             chomp(@output);
        }
    }

    if ( $prc != 0 ) {
        $rc = $prc;
    }
    elsif ( $rc < 0 || ( $rc = $CHILD_ERROR ) < 0 ) {
        push @output,
            "Failure in execution (rc=$rc, $CHILD_ERROR, $!) for command @_";
    }
    elsif ( $rc & 127 ) {
        my $sig = $rc & 127;
        push @output, "Failure with signal $sig from command: @_";
    }
    elsif ($rc) {
        push @output, "Failure with return code $rc from command @_";
    }

    return ( $rc, @output );
}

sub getOraInvLoc {
    my $orainv = get_orainv();

    return 0 if ( !-e $orainv );
    my ( $key, $val );
    my ( $rc, @output );
    open( FH, "<", $orainv ) or return 0;
    while(my $line = <FH>) {
      chomp($line);
      push(@output,$line);
    }
    close(FH);
    if ($rc) {
        c_printOut(@output);
        return "Can not proceeed further, Fix above error and run again";
    }
    foreach my $line (@output) {
        chomp $line;
        if ( $line =~ /^inventory_loc/ ) {
            ( $key, $val ) = split( '=', $line );
            last;
        }
    }
    return $val;
}

sub getGridOwner {
    my $ghome = getGridHome();
    my $crsconfig = catfile( $ghome, "crs", "install", "crsconfig_params" );

    open( FH, "<", $crsconfig ) or return 0;

    while (<FH>) {
        chomp;
        s/#.*//;
        s/^\s+//;
        s/\s+$//;
        next unless length;
        my ( $var, $value ) = split( /\s*=\s*/, $_, 2 );
        return $value if ( $var eq "ORACLE_OWNER" );
    }

    close FH;
}

sub getCrsdResources {
    my %res;
    my $nval;
    my $inum;
    my $skip;
    my $CRS_HOME = getGridHome();
    my $crsctl;
    my $platform = get_platform();
    if ($platform eq "MSWin32") {
        $crsctl = catfile( $CRS_HOME, 'bin', 'crsctl.exe' );
    } else {
        $crsctl = catfile( $CRS_HOME, 'bin', 'crsctl' );
    }
    my $cmd = qq ($crsctl stat res -v);

    my ( $rc, @output ) = c_system_cmd_capture_noprint($cmd);
    if ($rc) {
        c_printOut(@output);
        exit 0;
    }

    foreach my $line (@output) {
        chomp($line);
        next unless length $line;
        my ( $nam, $val ) = split( "=", $line );
        if ( $nam =~ /^NAME/ ) {
            $nval = $val;
            $inum = 0;
            $skip = 0;
        }
        if ( $nam =~ /^LAST_SERVER/ ) {
            $inum++ if ($skip);
            $skip = 1;
        }
        $res{$nval}{$inum}{$nam} = $val;
    }

    foreach my $rname ( sort keys %res ) {
        foreach my $x ( sort keys %{ $res{$rname} } ) {

        }
    }
    return %res;
}

sub getCrsdResourcesCfg {
    my %res;
    my $nval;
    my $inum;
    my $skip;
    my $CRS_HOME = getGridHome();
    my $crsctl;
    my $platform = get_platform();
    if ($platform eq "MSWin32") {
        $crsctl = catfile( $CRS_HOME, 'bin', 'crsctl.exe' );
    } else {
        $crsctl = catfile( $CRS_HOME, 'bin', 'crsctl' );
    }
    my $cmd = qq ($crsctl stat res -p);

    my ( $rc, @output ) = c_system_cmd_capture_noprint($cmd);
    if ($rc) {
        c_printOut(@output);
        exit 0;
    }

    foreach my $line (@output) {
        chomp($line);
        next unless length $line;
        my ( $nam, $val ) = split( "=", $line );
        if ( $nam =~ /^NAME/ ) {
            $nval = $val;
            $inum = 0;
            $skip = 0;
        }
        if ( $nam =~ /^LAST_SERVER/ ) {
            $inum++ if ($skip);
            $skip = 1;
        }
        $res{$nval}{$inum}{$nam} = $val;
    }

    return %res;
}

sub discover_crs_db_asm_and_write_kvout {
    my ($DUMP_FIL)	= shift;
    ($CRS_HOME)		= shift;
    ($pdebug)		= shift;

    if (!defined $CRS_HOME) {
        $CRS_HOME = getGridHome();
        if (! -e $CRS_HOME) {
	  return 2;
        }
    }

    my ($CRS12)		= 0;
    my (%res_1) 	= getCrsdResources();
    my (%res_2) 	= getCrsdResourcesCfg();
    my (%NODES);

    if ($pdebug) {
      open(my $pdbgptr, '>>', $pdebug) or die "Could not open file '$pdebug' $!";
      print $pdbgptr "Logging is ON\n";
      print $pdbgptr "Discovery Dumping Data:\n";
      print $pdbgptr "===============================\n";
      print $pdbgptr "Dump:[-v] \n";
      print $pdbgptr Dumper(\%res_1);
      print $pdbgptr "Dump:[-p] \n";
      print $pdbgptr Dumper(\%res_2);
      print $pdbgptr "\n\n";
    }

    my (%dbistate,%asmstate,%acfsstate,%instmode);
    my ($CRS_ACTIVE_VERSION) = "";
    if (defined $DUMP_FIL) {
	my (@nodes);
        open(CFIL,'>>',"$DUMP_FIL") || die $!;
        foreach my $okey1(keys %res_1) {
            if ($okey1 =~ m/\.db$/i) {
    	        my ($dbname) = $okey1;
    	        $dbname =~ s/ora\.//g;
    	        $dbname =~ s/\.db//g;

                foreach my $ikey1(keys %{$res_1{$okey1}}) {
    	            my ($inst_mode,$server,%absdbistate);
        	    foreach my $i2key1(keys %{$res_1{$okey1}{$ikey1}}) {
        	        if ($i2key1 =~ m/^STATE$/i) {
       		            $dbistate{$dbname.':'.$res_1{$okey1}{$ikey1}{$i2key1}} = $ikey1;
       		        } elsif ($i2key1 =~ m/^STATE_DETAILS$/i) {
       		            $inst_mode = $res_1{$okey1}{$ikey1}{$i2key1};
       		        } elsif ($i2key1 =~ m/^LAST_SERVER$/i) {
       		            $server = $res_1{$okey1}{$ikey1}{$i2key1};
			    push(@nodes,$server);
       		        } elsif ($i2key1 =~ m/^TARGET$/i) {
			    $absdbistate{$ikey1} = $res_1{$okey1}{$ikey1}{$i2key1};
			}
                    }
		    foreach my $odbikey(keys %dbistate) {
			foreach(keys %absdbistate) {
			    if ($dbistate{$odbikey} eq $_) { $dbistate{$odbikey} = $absdbistate{$_}; }
			}
		    }

    		    $instmode{"$server.$dbname.INSTANCE_MODE"} = $inst_mode;
        	}
    	    } elsif ($okey1 =~ m/\.asm$/i) {
                foreach my $ikey1(keys %{$res_1{$okey1}}) {
            	    foreach my $i2key1(keys %{$res_1{$okey1}{$ikey1}}) {
            		if ($i2key1 =~ m/^STATE$/i) {
       	    	            $asmstate{$res_1{$okey1}{$ikey1}{$i2key1}} = 1;
       	    	        }
                    }
            	}
    	    } elsif ($okey1 =~ m/\.acfs$/i) {
            	foreach my $ikey1(keys %{$res_1{$okey1}}) {
            	    foreach my $i2key1(keys %{$res_1{$okey1}{$ikey1}}) {
            	        if ($i2key1 =~ m/^STATE$/i) {
       	  		    $acfsstate{$res_1{$okey1}{$ikey1}{$i2key1}} = 1;
       	    	        }
                    }
                }
            }
	    foreach(@nodes) { $NODES{$_} = $_; }
        }

	my (%rdbms_oh);
        foreach my $okey2(keys %res_2) {
            if ($okey2 =~ m/\.db$/i) {
    	        my (@nodes);
    	        my (%nimap);
    	        my ($dbname,$dbhome,$dbowner,$VERSION,$dbversion,$dbrole,$dbgn);
    	        $VERSION = "";
    	        $dbversion = "";

                foreach my $ikey2(keys %{$res_2{$okey2}}) {
                    foreach my $i2key2(keys %{$res_2{$okey2}{$ikey2}}) {
    	                if ($i2key2 =~ m/^USR_ORA_DB_NAME$/i) {
       	            	    $dbname 		= $res_2{$okey2}{$ikey2}{$i2key2};
                        #} elsif ($i2key2 =~ m/^GEN_USR_ORA_INST_NAME\@SERVERNAME\((\w*)\)$/i) {
                        } elsif ($i2key2 =~ m/^GEN_USR_ORA_INST_NAME\@SERVERNAME\((.*)\)$/i) {
    	            	    if (exists $res_2{$okey2}{$ikey2}{$i2key2}) {
      	                        $nimap{$1}	= $res_2{$okey2}{$ikey2}{$i2key2};
    	            	    }
    	            	    push(@nodes,$1);
                        } elsif ($i2key2 =~ m/^ORACLE_HOME$/i) {
       	            	    $dbhome 	= $res_2{$okey2}{$ikey2}{$i2key2};
                        } elsif ($i2key2 =~ m/^VERSION$/i) {
       	            	    $VERSION	= $res_2{$okey2}{$ikey2}{$i2key2};
	        	    $dbversion	= $VERSION;
    	                    $dbversion	=~s/\.//g;
                        } elsif ($i2key2 =~ m/^ACL$/i) {
       	           	    $dbowner	= (split ':',$res_2{$okey2}{$ikey2}{$i2key2})[1];
                        } elsif ($i2key2 =~ m/^ROLE$/i) {
       	            	    $dbrole	= $res_2{$okey2}{$ikey2}{$i2key2};
                        } elsif ($i2key2 =~ m/^DB_UNIQUE_NAME$/i) {
    	            	    $dbgn	= $res_2{$okey2}{$ikey2}{$i2key2};
    	        	}
                    }

    	            if (!defined $dbname || $dbname eq "" || "$dbname" ne "$dbgn") { $dbname = $dbgn; }

                    my ($nlist) = join(",",keys %nimap);
		    my ($mstr) = "$dbhome|$dbversion|$dbowner";
		    if (exists $rdbms_oh{$mstr}) {
		        $rdbms_oh{$mstr} = $rdbms_oh{$mstr}.",".$nlist;
		    } else {
		        $rdbms_oh{$mstr} = $nlist;
		    }

    		    my ($db_running) = 0;
		    if (grep {$_ =~ /$dbname:/i && $dbistate{$_} =~ /online/i} keys %dbistate) {
	                print CFIL "DB_NAME=$dbname|$VERSION|$dbhome\n";

    	                print CFIL "$dbname.DATABASE_ROLE=$dbrole\n";
	                print CFIL "$dbname.GLOBAL_NAME=$dbgn\n";
		    } else {
			print CFIL "$dbname.RUNNING=0\n";
			next;
		    }

    	            foreach my $node(keys %NODES) {
			if(!defined $node || $node eq "") { next; }
    	                my ($dbionline) = 0;
    	                foreach (keys %dbistate) {
    	                    if (($_ =~ m/ONLINE/i || $dbistate{$_} =~ m/ONLINE/i) && ($_ =~ m/$node/i && $_ =~ m/$dbname:/i)) { $dbionline = 1;}
			    if ($dbistate{$_} !~ m/OFFLINE/i && $_ =~ m/$node/i && $_ =~ m/$dbname:/i) { $db_running++; }
    	                }

    	                if ($dbionline == 1) {
    	                    print CFIL "$node.$dbname.INSTANCE_NAME=$nimap{$node}\n";
    	                    print CFIL "$node.$dbname.INSTANCE_VERSION=$dbversion\n";
    	                } else {
    	                    print CFIL "$node.$dbname.INSTANCE_NAME=\n";
    	                    print CFIL "$node.$dbname.INSTANCE_VERSION=\n";
    	                }

    	                my ($inst_mode) 	= 0;
    	                my ($lcdbname)	= lc($dbname);
    	                my ($ucdbname)	= uc($dbname);
    	                if (exists $instmode{"$node.$dbname.INSTANCE_MODE"}) { $inst_mode = $instmode{"$node.$dbname.INSTANCE_MODE"};
    	                } elsif (exists $instmode{"$node.$lcdbname.INSTANCE_MODE"}) { $inst_mode = $instmode{"$node.$lcdbname.INSTANCE_MODE"};
    	                } elsif (exists $instmode{"$node.$ucdbname.INSTANCE_MODE"}) { $inst_mode = $instmode{"$node.$ucdbname.INSTANCE_MODE"}; }

    	                if ($inst_mode =~ m/OPEN/i) {
    	                    $inst_mode = 3;
			} elsif ($inst_mode =~ m/^MOUNT/i) {
			    $inst_mode = 2;
    	                } else {
    	                    $inst_mode = 0;
    	                }
    	                print CFIL "$node.$dbname.INSTANCE_MODE=$inst_mode\n";
    	            }
		    if ( $db_running == 0 ) {
			print CFIL "$dbname.ISDBRUNNING=0\n";
		    } else {
			print CFIL "$dbname.ISDBRUNNING=1\n";
		    }
                }
    	    } elsif ($okey2 =~ m/\.asm$/i) {
    	        my (@nodes);
    	        my (%nimap);
    	        my ($VERSION) = "";

                foreach my $ikey2(keys %{$res_2{$okey2}}) {
                    foreach my $i2key2(keys %{$res_2{$okey2}{$ikey2}}) {
                        #if ($i2key2 =~ m/^GEN_USR_ORA_INST_NAME\@SERVERNAME\((\w*)\)$/i) {
                        if ($i2key2 =~ m/^GEN_USR_ORA_INST_NAME\@SERVERNAME\((.*)\)$/i) {
                      	    print CFIL "$1.ASM_INSTALLED=1\n";
                    	    print CFIL "$1.ASM_INSTANCE=$res_2{$okey2}{$ikey2}{$i2key2}\n";
                    	    if (exists $res_2{$okey2}{$ikey2}{$i2key2}) {
                                push(@nodes,$1);
                    	    }
                    	    $nimap{$1} = $res_2{$okey2}{$ikey2}{$i2key2};
                        } elsif ($i2key2 =~ m/^VERSION$/i) {
                    	    $VERSION	= $res_2{$okey2}{$ikey2}{$i2key2};
                	}
                    }

    	    	    foreach my $node(@nodes) {
    	    	        my ($asmonline) = 0;
    	    	        foreach (keys %asmstate) {
    	    	            if ( $_ =~ m/ONLINE/i && $_ =~ m/$node/i ) { $asmonline = 1; }
    	    	        }

    	    	        if ($asmonline == 1) {
    	    	            print CFIL "$node.$nimap{$node}.VERSION=$VERSION\n";
    	    	            print CFIL "$node.ASM_STATUS=1\n";
    	    	        } else {
    	    	            print CFIL "$node.ASM_STATUS=0\n";
    	    	        }

    	    	        my ($acfsonline) = 0;
    	    	        foreach (keys %acfsstate) {
    	    	            if ( $_ =~ m/ONLINE/i && $_ =~ m/$node/i ) { $acfsonline = 1; }
    	    	        }

    	    	        if ($acfsonline == 1) {
    	    	            print CFIL "$node.ACFS_STATUS=1\n";
    	    	        } else {
    	    	            print CFIL "$node.ACFS_STATUS=0\n";
    	    	        }
    	    	    }
                }
    	    } elsif ($okey2 =~ m/^ora.cvu$/i) {
       	        foreach my $ikey2(keys %{$res_2{$okey2}}) {
                    foreach my $i2key2(keys %{$res_2{$okey2}{$ikey2}}) {
            	        if ($i2key2 =~ m/^VERSION$/i) {
       	    	            $CRS_ACTIVE_VERSION	= $res_2{$okey2}{$ikey2}{$i2key2};
    	    	        }
    	    	    }
    	        }
    	    }
        }

        foreach(keys %rdbms_oh) {
	    my %rdbmshosts=map{$_ => 1} split(",",$rdbms_oh{$_});
    	    print CFIL "RDBMS_ORACLE_HOME=$_|".join(",",keys %rdbmshosts)."\n";
	}

        my ($allnodes) = join(" ",keys %NODES);
        $allnodes =~ s/^\s//g;
        $allnodes =~ s/\s$//g;
        print CFIL "OLSNODES=$allnodes\n";

        foreach my $node(keys %NODES) {
            print CFIL "$node.CRS_ACTIVE_VERSION=$CRS_ACTIVE_VERSION\n";
        }

        my ($crs121,$crs122,$crs112) = (0,0,0);
        if ($CRS_ACTIVE_VERSION =~ m/12\.1/) {
        	$crs121 = 1;
        } elsif ($CRS_ACTIVE_VERSION =~ m/12\.2/) {
            $crs122 = 1;
        } elsif ($CRS_ACTIVE_VERSION =~ m/11\.2/) {
            $crs112 = 1;
        }

        if ($crs121 == 0 && $crs122 == 0 && $crs112 == 0 ) { $CRS12 = 1; }

        if (defined $crs112 && $crs112 >= 1) {
            print CFIL "ASM_HOME=\n";
        } else {
            print CFIL "ASM_HOME=$CRS_HOME\n";
            print CFIL "ASM_INVENTORY=$CRS_HOME/inventory/ContentsXML/comps.xml\n";
        }
        print CFIL "CRS_HOME=$CRS_HOME\n";
        print CFIL "CRS_INVENTORY=$CRS_HOME/inventory/ContentsXML/comps.xml\n";
        close(CFIL);
    }
    return $CRS12;
}

1;

