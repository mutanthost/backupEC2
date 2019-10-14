# 
# $Header: tfa/src/v2/tfa_home/bin/common/tfactlparser.pm /main/4 2018/08/09 22:22:31 recornej Exp $
#
# tfactlparser.pm
# 
# Copyright (c) 2017, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlparser.pm - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    recornej    08/06/18 - Change SUCCESS and FAILED values.
#    recornej    08/03/18 - Add map parameter to tfactlparser_getJSONValues.
#    manuegar    06/15/18 - manuegar_dbutils13_handlers.
#    recornej    03/14/18 - Adding tfactlparser_parse_dduresources.
#    recornej    02/09/18 - Add support to JSON strings to
#                           tfactlparser_decodeJSON
#    manuegar    02/01/18 - manuegar_shared_dbutils01.
#    manuegar    01/08/18 - manuegar_shared_dbutils01.
#    recornej    12/15/17 - Adding query json keys functions
#    recornej    12/06/17 - Adding JSON Parser
#    manuegar    12/01/17 - Creation
# 
package tfactlparser;
#require Exporter;

our @exp_vars;
our $CFG; 

BEGIN {
use Exporter ();
our($VERSION, @ISA, @EXPORT, @EXPORT_OK);
  $VERSION = 1.00; 
  @ISA = qw(Exporter);

  my @exp_const = qw(TRUE FALSE ERROR FAILED SUCCESS CONNFAIL DBG_HOST DBG_VERB DBG_WHAT DBG_NOTE);

  our @exp_vars = qw( );

  my @exp_func = qw( tfactlparser_parse_dbutilcmds tfactlparser_parse_dbutilschedule tfactlparser_encodeJSON
                     tfactlparser_decodeJSON tfactlparser_getJSONValues tfactlparser_getJSONValuesAtIndex
                     tfactlparser_crsctl  tfactlparser_parse_dbutilresources
                  );

  @EXPORT  = qw($CFG);
  push @EXPORT, @exp_const, @exp_func, @exp_vars;

}

use strict;
use English;
use IPC::Open2;
use File::Copy;
use File::Path;
use File::Find;
use File::Basename;
use File::Basename  qw( dirname );
use File::Spec::Functions;
use Cwd 'abs_path';
use Getopt::Long;
use Sys::Hostname;
use POSIX;
use POSIX qw(:termios_h);
use Carp;
use Config;
use Data::Dumper;
use Socket;
use Term::ANSIColor;
use B;
use Storable;


BEGIN {
  push @INC, dirname($PROGRAM_NAME).'/..';
  push @INC, dirname($PROGRAM_NAME).'/../common/exceptions';
}

use constant ERROR                     => "-1";
use constant FAILED                    =>  1;
use constant SUCCESS                   =>  0;
use constant TRUE                      =>  "1";
use constant FALSE                     =>  "0";
use constant CONNFAIL                  =>  "99";
use constant DBG_NOTE => "1";              # Notes to the user
use constant DBG_WHAT => "2";              # Explain what you do
use constant DBG_VERB => "4";              # Be verbose
use constant DBG_HOST => "8";              # print command executed on local host

use tfactlexceptions;
use tfactlglobal;
use tfactlshare;

my $lexem;
my $token;
my $line_num;
my @paths;

# #############
# Main routines
# =============
# tfactlparser_parse_dbutilcmds - This routine parses DbaUtils metadata
# tfactlparser_parse_dbutilschedule  - This routine parses tfactldbutlschedule.xml
# tfactlparser_encodeJSON       - This routine generates the JSON file corresponding to the in-memory hash.
# tfactlparser_decodeJSON       - This routine retrieves a hash reference
#                                 with the contents of a JSON file.
# tfactlparser_JSONObject       - This routine checks the syntax of a JSONObject and returns a hash reference
#                                 with  the JSONObject.
# tfactlparser_JSONArray        - This routine checks the syntax of a JSONArray
#                                 and returns an array reference.
# tfactlparser_JSONValue        - This routine checks the syntax of a JSONValue
#                                 and returns a value.
# tfactlparser_getJSONValues       - This routine returns the values found for a certain key in the json.
# tfactlparser_getJSONValueAtIndex - This routine returns the value or values for a given key at the specified indexes.
#
# #############


########
### NAME
###   tfactlparser_parse_dbutilschedule
###
### DESCRIPTION
###   This routine parses tfactldbutlschedule.xml
###
### PARAMETERS
###
### RETURNS
###
### NOTES
###
##########
sub tfactlparser_parse_dbutilschedule {
  my $schedulefile = shift;
  my @schedtagsarray;
  my $attrname;
  my $name;
  my $value;

  tfactlshare_trace(5, "tfactl (PID = $$) tfactlparser_parse_dbutilschedule " .
                    "Scheduler file $schedulefile", 'y', 'y');
  ### print "schedulefile $schedulefile\n";
  if ( -e "$schedulefile" )
  {
    # Parse xml file
    @schedtagsarray = tfactlshare_populate_tagsarray($schedulefile);

    # ==============================================================
    # Parse scheduler file, NOTE 0,0 is very important in order to get the
    # Attributes at root element
    # ==============================================================
    my @schedules = tfactlshare_get_element(\@schedtagsarray, 0,0);
    foreach my $child (@schedules)
    {
      # Get the tag
      $name  = @$child[ELEMNAME];
      $value = @$child[ELEMVAL];
      ### print "\nName $name\n";
      ### print "\nValue $value\n";

      # Get schedules children
      my @schedulesList = tfactlshare_get_element( \@schedtagsarray,
                            @$child[ELEMLEVEL]+1 , @$child[ELEMNDX] );

      foreach my $schedule (@schedulesList)
      {
        $name = @$schedule[ELEMNAME];
        $value = @$schedule[ELEMVAL];
        ### print "\nName1 $name\n";
        ### print "\nValue1 $value\n";

        if ( $name eq "schedule" ) {
          my %retattribs = ();
          %retattribs = tfactlshare_get_hash_attributes(@$schedule[ELEMATTRNAME] , @$schedule[ELEMATTRVAL]);
          my $categoryid = $retattribs{"categoryid"};
          my $commandid  = $retattribs{"commandid"};
          my $frequency  = $retattribs{"frequency"};
          my $frequnits  = $retattribs{"frequnits"};
          push @tfactlglobal_tfa_dbutlschedarr, [ $categoryid, $commandid, $frequency, $frequnits];
          ### print "tfactlparser_parse_dbutilschedule categoryid $categoryid, commandid $commandid, frequency $frequency, frequnits $frequnits\n";
        } # end if $name eq "schedule"
      } # end foreach @schedulesList
    } # end foreach @schedules)

  } # end if -e "$schedulefile"

} # end sub tfactlparser_parse_dbutilschedule


########
### NAME
###   tfactlparser_parse_dbutilcmds
###
### DESCRIPTION
###   This routine parses dba utils metadata
###
### PARAMETERS
###
### RETURNS
###
### NOTES
###
##########
sub tfactlparser_parse_dbutilcmds {
  my $metadatafile = shift;
  my @cmdtagsarray;
  my $attrname;
  my $name;
  my $value;

  tfactlshare_trace(5, "tfactl (PID = $$) tfactlparser_parse_dbutilcmds " .
                    "Metadata file $metadatafile", 'y', 'y');
  ### print "metadatafile $metadatafile\n";
  if ( -e "$metadatafile" )
  {
    # Parse xml file
    @cmdtagsarray = tfactlshare_populate_tagsarray($metadatafile);

    # ==============================================================
    # Parse metadata file, NOTE 0,0 is very important in order to get the
    # Attributes at root element
    # ==============================================================
    my @commands = tfactlshare_get_element(\@cmdtagsarray, 0,0);

    foreach my $child (@commands)
    {
      # Get the tag
      $name  = @$child[ELEMNAME];
      $value = @$child[ELEMVAL]; 
      ### print "\nName $name\n";
      ### print "\nValue $value\n";

      # Get commands children
      my @commandsList = tfactlshare_get_element( \@cmdtagsarray,
                            @$child[ELEMLEVEL]+1 , @$child[ELEMNDX] );

      # begin 2 --------------------------------
      foreach my $commandchild (@commandsList)
      {
        $name  = @$commandchild[ELEMNAME];
        $value = @$commandchild[ELEMVAL];
        ### print "\nName1 $name\n";
        ### print "\nValue1 $value\n";

        if ( $name eq "command" ) {
          my @piecesarray = ();
          my %retattribs = (); 
          %retattribs = tfactlshare_get_hash_attributes(@$commandchild[ELEMATTRNAME] , @$commandchild[ELEMATTRVAL]);

          my $cmdcategoryid = $retattribs{"categoryid"};
          my $cmdcommandid  = $retattribs{"commandid"};

          # Get cmdpieces
          my @cmdpiecesList = tfactlshare_get_element( \@cmdtagsarray,
                            @$commandchild[ELEMLEVEL]+1 , @$commandchild[ELEMNDX] );
          # begin 3 --------------------------------
          foreach my $cmdpiecechild (@cmdpiecesList)
          {   
            $name  = @$cmdpiecechild[ELEMNAME];
            $value = @$cmdpiecechild[ELEMVAL];

            if ( $name eq "cmdpiece" ) {
               my %retattribs = ();
               %retattribs = tfactlshare_get_hash_attributes(@$cmdpiecechild[ELEMATTRNAME] , @$cmdpiecechild[ELEMATTRVAL]);

               my $categoryid = $cmdcategoryid;
               my $parentcmd  = $retattribs{"parentcmd"};
               my $commandid  = $retattribs{"commandid"};
               my $keyname    = $retattribs{"keyname"};
               my $content    = $retattribs{"content"};
               my $handler    = $retattribs{"handler"};

               push @piecesarray, [ $categoryid, $parentcmd, $commandid, $keyname, $content, $handler ];
            } # end if $name eq "cmdpiece"
          } # end foreach @cmdpiecesList
          # end   3 --------------------------------

          # Populate commands global hash
          $tfactlglobal_tfa_dbutlcommands{$cmdcategoryid ."|".$cmdcommandid} = \@piecesarray;


        } # end if $name eq "commands"
      } # end foreach @commandsList
      # end   2 --------------------------------

    } # end foreach @commands)

  } # end if -e "$metadatafile"

  #tfactlparser_genJSON();

} # end sub tfactlparser_parse_dbutilcmds

########
### NAME
###   tfactlparser_parse_dbutilresources
###
### DESCRIPTION
###   This routine parses tfactldbutlresources.xml
###
### PARAMETERS
###   $resourcesfile  - Location of the tfactldbutlresources.xml
### RETURNS
###    $retHash       - hash  with the types and their corresponding attributes. 
### NOTES
###
##########
sub tfactlparser_parse_dbutilresources {
  my $resourcesfile = shift;
  my @restagsarray;
  my $attrname;
  my $name;
  my $value;
  my %retHash;
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlparser_parse_dbutilresources " .
                    "resources file $resourcesfile", 'y', 'y');
  if ( -e "$resourcesfile" ) {
    @restagsarray = tfactlshare_populate_tagsarray($resourcesfile);
    # ==============================================================
    # Parse resources file, NOTE 0,0 is very important in order to get the
    # Attributes at root element
    # ==============================================================
    my @resources = tfactlshare_get_element(\@restagsarray, 0,0);
    foreach my $child ( @resources) {
      my  @resourceList = tfactlshare_get_element( \@restagsarray,
                          @$child[ELEMLEVEL]+1, @$child[ELEMNDX] );
      foreach my $resource ( @resourceList ) {
        my %retattribs = ();
        %retattribs = tfactlshare_get_hash_attributes(@$resource[ELEMATTRNAME], @$resource[ELEMATTRVAL]);
        my $commandid = $retattribs{"commandid"};
        my $categoryid = $retattribs{"categoryid"};
        $retHash{$commandid} = \%retattribs;
      }
    }
  
  }
  return %retHash;
}
########
### NAME
###   tfactlparser_encodeJSON
###
### DESCRIPTION
###   This routine generates the JSON file
###
### PARAMETERS
###    $outfile     - JSON destination file
###    $hshref      - Hash reference pointing to the contents
###    $SINGLE_LINE - flag to make a JSON a single line
###
### RETURNS
###
### NOTES
###
##########
sub tfactlparser_encodeJSON {
   my $outfile = shift;
   my $hshref = shift;
   my $SINGLE_LINE  = shift;
   $Data::Dumper::Pair = " : ";
   $Data::Dumper::Useqq = 1;
   $Data::Dumper::Indent = 1;
   $Data::Dumper::Terse = 1;
   $Data::Dumper::Deepcopy= 1;
   $Data::Dumper::Sortkeys = sub {  
     if ( ${_[0]}->{"sequence"} ) {
       return ${_[0]}->{"sequence"};
     }
     return [sort keys %{$_[0]}];
   };
   my $line;
   if ( $SINGLE_LINE ) { #Single Line JSON
     if ( ref($hshref) eq "ARRAY" ){
       #If first level of the json is an array
       #make a line foreach element of the array
       foreach my $elem ( @{$hshref} ){
         my $tmpline = Dumper $elem;
         $tmpline =~ s/\n//g;
         $line.=$tmpline."\n";
       }  
     } else {
       $line = Dumper $hshref;
       $line =~ s/\n//g;
     }
   
   } else {
     $line = Dumper $hshref;
   }
   $line =~ s/undef/\"\"/g;
   $line =~ s/\'([0-9]+)\'/$1/g; #Dumper changes big numbers as '1010202030103' so
                                 #revert this behavior
   open (JSON,">",$outfile);
   print JSON $line;
   close(JSON);
} # end sub tfactlparser_encodeJSON

########
### NAME
###   tfactlparser_decodeJSON
###
### DESCRIPTION
###   This routine retrieves a hash reference 
###   with the contents of a JSON file.
###
### PARAMETERS
###    $file - JSON source file
###    $type - file or string
###
### RETURNS
###   $jsondecoded - hash reference with the contents
###                  of the JSON file or JSON string
### NOTES
###
##########
sub tfactlparser_decodeJSON {
  my $file = shift;
  my $type = shift;
  my $jsondecoded;
  my $json;

  $line_num =1;
  @paths = ();
  %tfactlglobal_jsonMap = ();

  if ( lc($type) eq "file" ) {
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlparser_decodeJSON " .
                    "JSON file $file", 'y', 'y');
    if ( -e "$file" ) {
      open(JSON,"$file" ) or die ("Could not open file $file \n");
      my $var = $/;
      undef $/;
      $json = <JSON>;
      close(JSON);
      $/ = $var;
    } else {
      print "JSON file $file does not exist \n";
      exit 0;
    }
  } else {
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlparser_decodeJSON " .
                    "JSON string $file", 'y', 'y');
    $json = $file;
  } #end if $type

  ( $lexem, $token ) = tfactlparser_JSONTokenizer(\$json);
  if ( $lexem ne "{" && $lexem ne "[" &&  $token ne "value" ) {
    tfactlshare_error_msg(450,undef);
    print "JSON error \'{\',\'[\',\'string\',\'number\',\'true\',\'false\',\'null\' expected found \'$lexem\' at line $line_num\n";
    exit 0;
  }
  if ( $token eq "object" ) {
    $jsondecoded = tfactlparser_JSONObject(\$json);
  } elsif ( $token eq "array" ) {
    $jsondecoded = tfactlparser_JSONArray(\$json);
  } elsif ( $token eq "value" ) {
    if ( $json and $json !~ /$JSONEOF/ ){
      ($lexem , $token ) = tfactlparser_JSONTokenizer(\$json);
      tfactlshare_error_msg(450,undef);
      print "JSON error \'EOF\' expected found \'$lexem\' at line $line_num \n";
      exit 0;
    }
    $jsondecoded = $lexem;
  } 

  if ( $tfactlglobal_hash{"debugmask"} & 
    $tfactlglobal_mod_levels{"tfactlparser"} ) {
    print Dumper($jsondecoded);
  }
  return $jsondecoded;
} # end sub tfactlparser_decodeJSON

########
### NAME
###   tfactlparser_JSONTokenizer
###
### DESCRIPTION
###   This routine returns the current token in the
###   json string. 
###
### PARAMETERS
###    $json_string - JSON string
###
### RETURNS
###   $lexem  - lexem tokenized 
###   $token  - token 
### NOTES
###
##########
sub tfactlparser_JSONTokenizer {
	my $json_string = shift;
  if ( $$json_string =~ /(($JSONOPENOBJ)|($JSONCLOSEOBJ)|($JSONOPENARR)|($JSONCLOSEARR)|($JSONCOMMA)|($JSONCOLON)|($JSONSTR)|($JSONNUM)|($JSONNULL)|($JSONFALSE)|($JSONTRUE)|($JSONEOF))/){
			#Validate token
			$lexem = $1;
			$token = "";
      #Get current line
      if ( $lexem =~ /([\n\r]+)/ ) {
        $line_num += length($1);
      }
			my $index = index($$json_string,$lexem);
			#If the index of the token matched is not 0 we have a non matching token
			#at the beggining of the string.
			if ( $index != 0 ) {
				$lexem = substr($$json_string,0,$index);
			}
      #If lexem  does not match the valid regex it means
      #we have a char or a sequence of chars that are not valid
      #in the json
			if ( $lexem !~ /(($JSONOPENOBJ)|($JSONCLOSEOBJ)|($JSONOPENARR)|($JSONCLOSEARR)|($JSONCOMMA)|($JSONCOLON)|($JSONSTR)|($JSONNUM)|($JSONNULL)|($JSONFALSE)|($JSONTRUE)|($JSONEOF))/ ){
        tfactlshare_error_msg(450,undef);
				print "JSON error unexpected token $lexem at line $line_num\n";
				exit 0;	
			}
      #Assign a token name to the lexem found.
			if ( $lexem =~ /^$JSONCOLON$/ || $lexem =~ /^$JSONCOMMA$/ ) {
				$token = "sep";
			} elsif ( $lexem =~ /^$JSONOPENOBJ$/ || $lexem =~ /^$JSONCLOSEOBJ$/ ){
				$token = "object";			
			} elsif ( $lexem =~ /^$JSONOPENARR$/ || $lexem =~ /^$JSONCLOSEARR$/ ){
				$token = "array";			
			} elsif ( $lexem =~ /^$JSONSTR$/ ){
				$token = "str";
			} elsif ( $lexem =~ /$JSONEOF/ ){
        $token = "eof";
      } else {
				$token = "value";			
			}
      $$json_string = substr($$json_string,length($lexem));
      $lexem =~ s/^\s+|\s+$//g;
      tfactlshare_trace(5, "tfactl (PID = $$) tfactlparser_JSONTokenizer " .
                    "Lexem => \'$lexem\'  Token =>  \'$token\' Line Number => $line_num", 'y', 'y');	 
	} else {
    tfactlshare_error_msg(450,undef);
    print "JSON error unable to tokenize JSONString $$json_string\n";
    exit 0;
  }
	return $lexem,$token;	
} # end sub tfactlparser_JSONTokenizer

########
### NAME
###   tfactlparser_JSONObject
###
### DESCRIPTION
###   This routine checks the syntax of a JSONObject
###   and returns a hash reference with the JSONObject
###
### PARAMETERS
###    $json - JSON string
###
### RETURNS
###   \%jsonObject   jsonObject hash reference
###
### NOTES
###
##########
sub tfactlparser_JSONObject {
    my $json = shift;
    my %jsonObject;
    my $key;
    my $value;
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlparser_JSONObject ", 'y', 'y');
    do {
      ( $key, $value ) = tfactlparser_JSONPair($json);
      if ( $key ) {
        $jsonObject{$key} = $value;
        ( $lexem, $token ) = tfactlparser_JSONTokenizer($json);
      }
    }while ( $lexem eq "," );
    if ( $lexem ne "}" ){
      tfactlshare_error_msg(450,undef);
      print "JSON error \'}\' was expected found \'$lexem\' at line $line_num\n";
      exit 0;
    }
    return \%jsonObject;
} #end sub tfactlparser_JSONObject

########
### NAME
###   tfactlparser_JSONArray
###
### DESCRIPTION
###   This routine checks the syntax of a JSONArray
###   and returns an array reference
###
### PARAMETERS
###    $json - JSON string
###
### RETURNS
###   \@array - Array reference to the array object   
###
### NOTES
###   
##########
sub tfactlparser_JSONArray {
  my $json = shift; 
  my @array;
  my $value;
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlparser_JSONArray ", 'y', 'y');
  do {
    $value = tfactlparser_JSONValue($json);
    if ( $value ) {
      push @array,$value;
      ($lexem,$token) = tfactlparser_JSONTokenizer($json);
    }
  }while ($lexem eq ",");
  if ( $lexem ne "]" ) {
    tfactlshare_error_msg(450,undef);
    print "JSON error \']\' was expected  found \'$lexem\' at line $line_num\n";
    exit 0;
  }
  return \@array;
} #end sub tfactlparser_JSONArray

########
### NAME
###   tfactlparser_JSONValue
###
### DESCRIPTION
###   This routine checks the syntax of a JSONValue
###   and returns a value
###
### PARAMETERS
###    $json - JSON string
###
### RETURNS
###   $value - value of key   
###
### NOTES
###   $value can be a string or a scalar reference 
###   to a hash or an array depending on the object value.
##########
sub tfactlparser_JSONValue {
  my $json = shift;
  my $value;
  my $prvlexem = $lexem;
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlparser_JSONValue ", 'y', 'y');
  ( $lexem, $token ) = tfactlparser_JSONTokenizer($json);
  if ( $lexem eq "{"){
     $value = tfactlparser_JSONObject($json);
  } elsif ($lexem eq "[" ) {
    $value = tfactlparser_JSONArray($json);
  } elsif ( $token eq "value" ) {
    $value = $lexem;
  } elsif ( $token eq "str" ) {
    $value = $lexem;
    $value =~ s/\"+//g;
  } else {
    #Empty array or empty object
    if ( ($prvlexem eq "[" && $lexem eq "]" ) ||
         ($prvlexem eq "{" && $lexem eq "}" )) {
         $value = "";
    } else {
      tfactlshare_error_msg(450,undef);
      print "JSON error a valid JSONValue was expected  found \'$lexem\' at line $line_num\n";
      exit 0;
    }
  }
  return $value;
} #end sub tfactlparser_JSONValue

########
### NAME
###   tfactlparser_JSONPair
###
### DESCRIPTION
###   This routine checks the syntax of a JSONPair
###   and returns the key,value pair
###
### PARAMETERS
###    $json - JSON string
###
### RETURNS
###   $key   - key of the JSONPair
###   $value - value of the JSONPair  
###
### NOTES
###    
#############
sub tfactlparser_JSONPair {
  my $json = shift;
  my $key;
  my $value;
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlparser_JSONPair ", 'y', 'y');
  ( $lexem, $token ) = tfactlparser_JSONTokenizer($json);
  if ( $token ne "str" && $lexem ne "}") {
    tfactlshare_error_msg(450,undef);
    print "JSON error \'string key\' or \'}\' was expected  at line $line_num\n";
    exit 0;
  } elsif( $lexem ne "}") {
    $key = $lexem;
    $key =~ s/\"+//g;
    push(@paths,$key);
    ($lexem, $token) = tfactlparser_JSONTokenizer($json);
    if ( $lexem ne ":" ){
      tfactlshare_error_msg(450,undef);
      print "JSON error \':\' was expected found $lexem at line $line_num\n";
      exit 0;
    }
    $value = tfactlparser_JSONValue($json);
  }
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlparser_JSONPair ".
                   "     Key => $key | Value => $value" , 'y', 'y');
  #Create path to access the value of the current key 
  ##================================================
  my $path = join("->",@paths);
  pop(@paths);
  if( $tfactlglobal_jsonMap{$key} ){
    my %map = map { $_ => 1 } @{$tfactlglobal_jsonMap{$key}};
    if ( not exists($map{$path}) ) {
      push @{$tfactlglobal_jsonMap{$key}},$path;
    }
  } else {
    $tfactlglobal_jsonMap{$key} = [$path];
  }
  #=================================================
  return ( $key , $value );
} #end sub tfactlparser_JSONPair

########
### NAME
###   tfactlparser_getJSONValues
###
### DESCRIPTION
###   This routine returns the values
###   found for a certain key in the json.
###
### PARAMETERS
###    $key     - key to look for
###    $jsonref - JSON reference,data structure 
###               that holds the JSON in memory
###    $map     - hash reference that contains the 
###               the mapping of the keys in the JSON,
###               this parameter will overwrite the
###               current tfactlglobal_jsonMap and
###               it will restore it at the end.
###
### RETURNS
###   \@values   - array reference with the values found
###               "" if key does not exists
###
### NOTES
###   NONE
###
### USAGE                                      Key    JSON ref
###  my $values = tfactlparser_getJSONValues("disks",$JSON);
###  my $values = tfactlparser_getJSONValues("disks",$JSON, \%map);
#############
sub tfactlparser_getJSONValues {
  my $key = shift;
  my $jsonref = shift;
  my $map = shift; 
  my @values = ();
  my %tmp = ();
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlparser_getJSONValues ".
                   "     Key => $key" , 'y', 'y');
  if ( $map ) {
    if ( ref($map) eq "HASH") {
      %tmp = %tfactlglobal_jsonMap;
      %tfactlglobal_jsonMap = %{$map};
    } else {
      print "Invalid argument passed: map parameter must be a hash\n";
      return "";
    }
  }
  if ( ! $tfactlglobal_jsonMap{$key} ) {
    print "JSONValue not found for key $key \n";
    return "";
  }
  my @keypaths = @{$tfactlglobal_jsonMap{$key}};
  foreach my $path ( @keypaths ) {
    my @steps = split("->",$path);
    tfactlparser_getJSONObject($key,\@steps,$jsonref,\@values); 
  }
  %tfactlglobal_jsonMap = %tmp if ( %tmp );
   return $values[0] if ( scalar(@values) == 1 );
  return \@values;
} #end sub tfactlparser_getJSONValues

########
### NAME
###   tfactlparser_getSubArray
###
### DESCRIPTION
###   This routine returns the sub array of the given indexes 
###   from an array
###
### PARAMETERS
###    $index    - list of the indexes to retrive e.g "0,1" , "0,5,10","2"
###    $refarr   - reference to the array that we want to get the subarray from
###
### RETURNS
###   \@array    - reference to the subarray 
###
### NOTES
###    
#############
sub tfactlparser_getSubArray {
  my $index = shift; 
  my $refarr = shift; 
  my @array;
  my @indexes = split(',',$index);
  my %seen;
  grep !$seen{$_}++,@indexes;
  foreach my $idx (@indexes) {
    if ( $idx >= 0 && $idx < scalar(@{$refarr})) {
      push @array, @{$refarr}[$idx];
    }
  }
  return \@array;
}#end sub tfactlparser_getSubArray

########
### NAME
###   tfactlparser_getJSONValuesAtIndex
###
### DESCRIPTION
###   This routine returns the value or values for a given key 
###   at the specified indexes.
###
### PARAMETERS
###    $key      - key to look for
###    $jsonref  - JSON reference,data structure 
###                that holds the JSON in memory
###    $index    - list of the indexes to retrive e.g "0,1" , "0,5,10","2"
###
### RETURNS
###   $values    - reference to the value or values found 
###
### NOTES
###   NONE
###
### USAGE:
###                                                   key    json ref  index|indexes
###   my $values = tfactlparser_getJSONValuesAtIndex("disks", $JSON,    "0,2");
###   my $values = tfactlparser_getJSONValuesAtIndex("network",$JSON,   "1");
#############
sub tfactlparser_getJSONValuesAtIndex {
  my $key = shift;
  my $jsonref = shift;
  my $index = shift;
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlparser_getJSONValuesAtIndex ".
                   "     Key => $key Index => $index" , 'y', 'y');
  my $values = tfactlparser_getJSONValues($key, $jsonref);
  if ( ref($values) eq "ARRAY" && $index ne "" ) {
     $values =  tfactlparser_getSubArray($index,$values);
     return $$values[0] if ( scalar(@{$values}) == 1 );
  }
  return $values;
}#end sub tfactlparser_getJSONValuesAtIndex

########
### NAME
###   tfactlparser_getJSONObject
###
### DESCRIPTION
###   This routine populates the @values array 
###   if the value is a JSONObject 
###
### PARAMETERS
###    $key      - key to look for
###    $stepsref - reference to the array of the steps left
###                until we reach the target key
###    $jsonref  - reference to the data structure that 
###                holds the jsonObject
###    $values   - reference to the array that contains the actual
###                values for the given keys
###
### RETURNS
###   NONE
###
### NOTES
###    
#############
sub tfactlparser_getJSONObject {
  my $key = shift;
  my $stepsref = shift;
  my $jsonref = shift;
  my $values =shift;
  my %json = %{$jsonref};
  my @steps = @{$stepsref};
  my $parent;
  my $value;
  do {
    $parent = shift(@steps);
    $value  = $json{$parent};
    if ( $key ne $parent ){
      tfactlshare_trace(5, "tfactl (PID = $$) tfactlparser_getJSONObject ".
                   "     Parent => $parent | Values => @{$values}" , 'y', 'y');
      if (ref($value) eq "HASH"){
        %json = %{$value};
      } elsif(ref($value) eq "ARRAY" ){
        tfactlparser_getJSONArray($key,\@steps,$value,$values);
      }
    } else {
      tfactlshare_trace(5, "tfactl (PID = $$) tfactlparser_getJSONObject ".
                   "     Parent => $parent | Value => $value" , 'y', 'y');
      if ( $value ){
        push @{$values},$value;
      }
    }
  } while(@steps);
}

########
### NAME
###   tfactlparser_getJSONArray
###
### DESCRIPTION
###   This routine populates the @values array 
###   if the value is an array.
###
### PARAMETERS
###    $key      - key to look for
###    $stepsref - reference to the array of the steps left 
###                until we reach the target key
###    $arrayref - reference to the value array
###    $values   - reference to the array that contains the actual
###                values for the given key
###
### RETURNS
###
###    NONE
###   
### NOTES
###    
#############
sub tfactlparser_getJSONArray {
  my $key =shift;
  my $stepsref = shift;
  my $arrayref = shift;
  my $values = shift;
  my @array = @{$arrayref};
  my @steps = @{$stepsref};
  my $value;
  my $step = shift(@steps);
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlparser_getJSONArray ".
                   "     Step => $step | Values => @{$values}" , 'y', 'y');
  foreach my $elem (@array){
    if (ref($elem) eq "HASH" ) {
      my %hash = %{$elem};
      $value = $hash{$step};
      $value = tfactlparser_getJSONObject($key,\@steps,$value,$values) if( $key ne $step);
      push @{$values},$value if ( $value );
    } else {
      tfactlshare_trace(5, "tfactl (PID = $$) tfactlparser_getJSONArray ".
                   "     Elem $elem Step => $step | Key => $key" , 'y', 'y');
      push @{$values},$elem if($key eq $step && ref($elem) eq "HASH");
    }
  }
}#end sub tfactlparser_getJSONArray

########
### NAME
###   tfactlparser_crsctl
###
### DESCRIPTION
###   This routine returns a hash of hashes  with all the key=value lines 
###   from the crsctl stat res <-f | -v | -p> command with NAME as the main key. 
###
### PARAMETERS
###   $crshome  - CRS HOME 
###   $type     - <-f | -v | -p>
###   $crstype  - CRS type (e.g. ora.asm.type)
###   $host     - hostname
###
### RETURNS
###   $retHash  - A hash with key=value lines of crsctl
###
### NOTES
###   - It only supports crsctl stat res <-f | -v | -p>
###   - In case we have the CRS_HOME globally available this won't be needed
##########
sub tfactlparser_crsctl {
  my $crshome = shift;
  my $type    = shift;
  my $crstype = shift;
  my $host    = shift;
  my $crsctl  = catfile("$crshome","bin","crsctl");
  my $output  = "";
  my @blocks  = ();
  my %retHash = ();
  my $cmd     = "";

  $crsctl .=".exe" if($IS_WINDOWS);

  tfactlshare_trace(5,"tfactl (PID = $$) tfactlparser_crsctl ".
                    "CRSHOME $crshome, TYPE $type, crstype $crstype, host $host", 'y','y');
  if ( $current_user ne "root" ) { #Need to verify if this needs to be run as root
    print "Access Denied. Only TFA Admin can run this command\n";
    exit 1;
  }

  if ( not -e $crsctl ) {
    print "crsctl binary not found on $crsctl.\n";
    exit 1;
  }
  if ( $type !~ /\-[vfp]/ ) {
     print "Type \'$type\' not supported \n";
     exit 1;
  }
  if ( (defined $crstype && length $crstype) ) {
    $crstype = " -w \"$crstype\"";
  } else {
    $crstype = "";
  }
  if ( (defined $host) && length $host ) {
    $host = " -n $host";
  } else {
    $host = "";
  }

  $cmd    = "$crsctl stat res $type$crstype$host";
  tfactlshare_trace(5,"tfactl (PID = $$) tfactlparser_crsctl ".
                    "cmd : $cmd", 'y','y');
  $output = `$cmd`;
  tfactlshare_trace(5,"tfactl (PID = $$) tfactlparser_crsctl ".
                    "output : $output", 'y','y');
  

  @blocks = split(/(?=^NAME\=)|(?=\nNAME\=)/, $output);

  foreach my $block (@blocks) {
    $block =~ s/^\s+|\s+$//g;

    if ( $type eq "-v"  && (not length $host) && (not length $crstype) ) {
      $block =~ s/\n\n+//g;
      my @subBlocks = split ( /(?=LAST_SERVER\=)/,$block);
      my $name_type = shift(@subBlocks);
      my %hash = split(/[\=\n]/,$name_type);
      my @array;
      foreach my $subBlock (@subBlocks) {
        my %hash = map { (split(/\=/,$_,2))[0] => (split(/\=/,$_,2))[1] } (split /\n/, $subBlock);
        push(@array,\%hash);
      }
      $hash{"NODES"} =\@array;
      $retHash{$hash{"NAME"}} = \%hash;
    } else {
      my %hash = map { (split(/\=/,$_,2))[0] => (split(/\=/,$_,2))[1] } (split /\n/, $block);
      $retHash{$hash{"NAME"}} = \%hash;
    }
  }
  return %retHash;
}#end sub tfactlparser_crsctl
1;
