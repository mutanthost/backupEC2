# 
# $Header: tfa/src/v2/tfa_home/bin/modules/tfactlips.pm /main/15 2018/07/17 09:48:56 manuegar Exp $
#
# tfactlips.pm
# 
# Copyright (c) 2014, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlips.pm 
#
#    DESCRIPTION
#      TFA/IPS integration
#
#    NOTES
#     
#
#    MODIFIED   (MM/DD/YY)
#    manuegar    07/13/18 - manuegar_multibug_01.
#    bburton     03/19/18 - Bug 27665984 - remove use of POSIX::tmpnam
#    manuegar    09/23/16 - Support ips add adrbase <adrbasepath>.
#    manuegar    09/19/16 - Bug 24593717 - LNX64-12.2-TFA: IPS UNPACK PACKAGE
#                           GOT DIFFERENT RESULT WITH ADRCI IPS UNPACK.
#    manuegar    06/21/16 - Bug 23623096 - WS2012_122_TFA: NO USAGE DESCRIPTION
#                           FOR 'TFACTL IPS' .
#    manuegar    12/07/15 - Bug 21552624 - LNX64-12.2-TFA-IPS:NEW IPS COMMANDS
#                           IN TFACTL DID NOT WORK.
#    manuegar    12/07/15 - Bug 21648528 - LNX64-12.2-TFA-IPS:IPS PACK DID NOT
#                           WORK.
#    manuegar    11/30/15 - Bug 22283921 - TFA : TFA DIAGCOLLECT NOT WORKING
#                           FOR AN INCIDENT WHEN THERE ARE > 50 INC.
#    manuegar    08/06/15 - Bug 21552238 - LNX64-12.2-TFA-IPS:IPS ADD INCIDENT
#                           DID NOT WORK.
#    manuegar    07/03/15 - Bug 21221209 - LNX64-12.2-TFA:IPS SHOW
#                           CONFIGURATION DID NOT WORK AS EXPECTED.
#    manuegar    12/12/14 - Ips collection logic
#    manuegar    12/04/14 - 20176397, Support new commands for TFA-IPS integration
#    manuegar    11/21/14 - Bug 19909906, help messages for tfactl ips -h.
#    manuegar    11/13/14 - Implement <action> <toolname> <flags> for support
#                           tools.
#    manuegar    08/11/14 - Creation
#
############################ Functions List #################################
#
#
#############################################################################

package tfactlips;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(tfactlips_init
                 );

use strict;
use IPC::Open2;
use File::Copy;
use File::Path;
use File::Find;
use File::Basename;
use File::Basename  qw( dirname );
use File::Spec::Functions;
use Getopt::Long;
use Sys::Hostname;
use POSIX;

use tfactlglobal;
use tfactlshare;

#################### tfactlips Global Constants ####################

my (%tfactlips_cmds) = (ips      => {},
                        IPS      => {},
                         );
our (%tfactlips_commands) = (
    #                                         complete  more    command
    ips => [
             # ips -help
             [ 'ips',        '-h',            MARKED,   UNMARKED, 'ips -help' ],
             [ 'ips',        '-help',         MARKED,   UNMARKED, 'ips -help' ],
             # ips pack
             [ 'ips',        'pack',          MARKED, MARKED,     'ips pack' ],
             [ 'pack',       'incident',      UNMARKED, MARKED,   'none' ],
             [ 'pack',       'problem',       UNMARKED, MARKED,   'none' ],
             [ 'pack',       'problemkey',    UNMARKED, MARKED,   'none' ],
             [ 'pack',       'seconds',       UNMARKED, MARKED,   'none' ],
             [ 'pack',       'time',          UNMARKED, MARKED,   'none' ],
             [ 'pack',       'correlate',     UNMARKED, MARKED,   'none' ],
             [ 'pack',       'integration',   UNMARKED, MARKED,   'none' ],
             [ 'pack',       'manifest',      UNMARKED, MARKED,   'none' ],
             [ 'pack',       'keyfile',       UNMARKED, MARKED,   'none' ],
             [ 'pack',       'in',            UNMARKED, MARKED,   'none' ],

             [ 'incident',   'first',         UNMARKED, MARKED,   'none' ],
             [ 'problem',    'first',         UNMARKED, MARKED,   'none' ],
             [ 'first',      '<integer>',     MARKED,   MARKED,   'incident first <integer>' ],
             [ '<integer>',  'correlate',     UNMARKED, MARKED,   'none' ],
             [ '<integer>',  'integration',   UNMARKED, MARKED,   'none' ],
             [ '<integer>',  'manifest',      UNMARKED, MARKED,   'none' ],
             [ '<integer>',  'keyfile',       UNMARKED, MARKED,   'none' ],

             [ 'incident',   '<integer>',     MARKED,   MARKED,   "incident <integer>" ],
             [ 'problem',    '<integer>',     MARKED,   MARKED,   "problem <integer>" ],
             [ 'problemkey', '<problem_key>', MARKED,   MARKED,   "problemkey '<problem_key>'" ],
             [ 'seconds',    '<integer>',     MARKED,   MARKED,   "seconds <integer>" ],
             [ 'time',       '<start_time>',  UNMARKED, MARKED,   "none" ],
             [ '<start_time>','to',           UNMARKED, MARKED,   "none" ],
             [ 'to',         '<end_time>',    MARKED,   MARKED,   "time '<start_time>' to '<end_time>'"],

             [ '<end_time>', 'correlate',     UNMARKED, MARKED,   'none' ],
             [ '<end_time>', 'integration',   UNMARKED, MARKED,   'none' ],
             [ '<end_time>', 'manifest',      UNMARKED, MARKED,   'none' ],
             [ '<end_time>', 'keyfile',       UNMARKED, MARKED,   'none' ],
             [ '<integer>',  'correlate',     UNMARKED, MARKED,   'none' ],
             [ '<integer>',  'integration',   UNMARKED, MARKED,   'none' ],
             [ '<integer>',  'manifest',      UNMARKED, MARKED,   'none' ],
             [ '<integer>',  'keyfile',       UNMARKED, MARKED,   'none' ],
             [ '<problem_key>','correlate',   UNMARKED, MARKED,   'none' ],
             [ '<problem_key>','integration', UNMARKED, MARKED,   'none' ],
             [ '<problem_key>','manifest',    UNMARKED, MARKED,   'none' ],
             [ '<problem_key>','keyfile',     UNMARKED, MARKED,   'none' ],

             [ '<end_time>', 'in',            UNMARKED, MARKED,   'none' ],
             [ '<integer>',  'in',            UNMARKED, MARKED,   'none' ],
             [ '<problem_key>','in',          UNMARKED, MARKED,   'none' ],

             [ 'correlate',  'basic',         MARKED,   MARKED, 'correlate basic' ],
             [ 'basic',      'integration',   UNMARKED, MARKED,   'none' ],
             [ 'basic',      'manifest',      UNMARKED, MARKED,   'none' ],
             [ 'basic',      'keyfile',       UNMARKED, MARKED,   'none' ],
             [ 'correlate',  'typical',       MARKED,   MARKED, 'correlate typical' ],
             [ 'typical',    'integration',   UNMARKED, MARKED,   'none' ],
             [ 'typical',    'manifest',      UNMARKED, MARKED,   'none' ],
             [ 'typical',    'keyfile',       UNMARKED, MARKED,   'none' ],
             [ 'correlate',  'all',           MARKED,   MARKED, 'correlate all' ],
             [ 'all',        'integration',   UNMARKED, MARKED,   'none' ],
             [ 'all',        'manifest',      UNMARKED, MARKED,   'none' ],
             [ 'all',        'keyfile',       UNMARKED, MARKED,   'none' ],

             [ 'integration','tfa',           MARKED,   MARKED, 'integration tfa' ],
             [ 'tfa',        'manifest',      UNMARKED, MARKED, 'none' ],
             [ 'tfa',        'keyfile',       UNMARKED, MARKED, 'none' ],
             [ 'keyfile',    '<filename>',    MARKED,   MARKED, 'keyfile <filename>' ],
             [ 'manifest',   '<filename>',    MARKED,   MARKED,   'manifest <filename>' ],
             [ '<filename>', 'keyfile',       UNMARKED, MARKED,   'none' ],
             [ 'keyfile',    '<newfilename>', MARKED,   MARKED, 'keyfile <newfilename>' ],

             [ '<pack>',     'in',            UNMARKED, MARKED,   'none' ],
             [ '<filename>', 'in',            UNMARKED, MARKED,   'none' ],
             [ '<newfilename>','in',          UNMARKED, MARKED,   'none' ],
             [ 'basic',      'in',            UNMARKED, MARKED,   'none' ],
             [ 'typical',    'in',            UNMARKED, MARKED,   'none' ],
             [ 'all',        'in',            UNMARKED, MARKED,   'none' ],
             [ 'in',         '<path>',        MARKED,   UNMARKED, 'in <path>' ],

             # ips create package
             [ 'ips',        'create',        UNMARKED, MARKED,   'none' ],
             [ 'create',     'package',       MARKED,   MARKED,   'ips create package' ],
             [ 'package',    'correlate',     UNMARKED, MARKED,   'none' ],
             [ 'package',    'integration',   UNMARKED, MARKED,   'none' ],
             [ 'package',    'manifest',      UNMARKED, MARKED,   'none' ],
             [ 'package',    'keyfile',       UNMARKED, MARKED,   'none' ],

             [ 'package',    'incident',      UNMARKED, MARKED,   'none' ],
             [ 'package',    'problem',       UNMARKED, MARKED,   'none' ],
             [ 'package',    'problemkey',    UNMARKED, MARKED,   'none' ],
             [ 'package',    'seconds',       UNMARKED, MARKED,   'none' ],
             [ 'package',    'time',          UNMARKED, MARKED,   'none' ],

             [ 'incident',   'first',         UNMARKED, MARKED,   'none' ],
             [ 'problem',    'first',         UNMARKED, MARKED,   'none' ],
             [ 'first',      '<integer>',     MARKED,   MARKED,   'incident first <integer>' ],
             [ '<integer>',  'correlate',     UNMARKED, MARKED,   'none' ],
             [ '<integer>',  'integration',   UNMARKED, MARKED,   'none' ],
             [ '<integer>',  'manifest',      UNMARKED, MARKED,   'none' ],
             [ '<integer>',  'keyfile',       UNMARKED, MARKED,   'none' ],

             [ 'incident',   '<integer>',     MARKED,   MARKED,   "incident <integer>" ],
             [ 'problem',    '<integer>',     MARKED,   MARKED,   "problem <integer>" ],
             [ 'problemkey', '<problem_key>', MARKED,   MARKED,   "problemkey '<problem_key>'" ],
             [ 'seconds',    '<integer>',     MARKED,   MARKED,   "seconds <integer>" ],
             [ 'time',       '<start_time>',  UNMARKED, MARKED,   "none" ],
             [ '<start_time>','to',           UNMARKED, MARKED,   "none" ],
             [ 'to',         '<end_time>',    MARKED,   MARKED,   "time '<start_time>' to '<end_time>'"],
             [ '<end_time>', 'correlate',     UNMARKED, MARKED,   'none' ],
             [ '<end_time>', 'integration',   UNMARKED, MARKED,   'none' ],
             [ '<end_time>', 'manifest',      UNMARKED, MARKED,   'none' ],
             [ '<end_time>', 'keyfile',       UNMARKED, MARKED,   'none' ],
             [ '<integer>',  'correlate',     UNMARKED, MARKED,   'none' ],
             [ '<integer>',  'integration',   UNMARKED, MARKED,   'none' ],
             [ '<integer>',  'manifest',      UNMARKED, MARKED,   'none' ],
             [ '<integer>',  'keyfile',       UNMARKED, MARKED,   'none' ],
             [ '<problem_key>','correlate',   UNMARKED, MARKED,   'none' ],
             [ '<problem_key>','integration', UNMARKED, MARKED,   'none' ],
             [ '<problem_key>','manifest',    UNMARKED, MARKED,   'none' ],
             [ '<problem_key>','keyfile',     UNMARKED, MARKED,   'none' ],

             [ 'correlate',  'basic',         MARKED,   MARKED, 'correlate basic' ],
             [ 'basic',      'integration',   UNMARKED, MARKED,   'none' ],
             [ 'basic',      'manifest',      UNMARKED, MARKED,   'none' ],
             [ 'basic',      'keyfile',       UNMARKED, MARKED,   'none' ],
             [ 'correlate',  'typical',       MARKED,   MARKED, 'correlate typical' ],
             [ 'typical',    'integration',   UNMARKED, MARKED,   'none' ],
             [ 'typical',    'manifest',      UNMARKED, MARKED,   'none' ],
             [ 'typical',    'keyfile',       UNMARKED, MARKED,   'none' ],
             [ 'correlate',  'all',           MARKED,   MARKED, 'correlate all' ],
             [ 'all',        'integration',   UNMARKED, MARKED,   'none' ],
             [ 'all',        'manifest',      UNMARKED, MARKED,   'none' ],
             [ 'all',        'keyfile',       UNMARKED, MARKED,   'none' ],

             [ 'integration','tfa',           MARKED,   MARKED, 'integration tfa' ],
             [ 'tfa',        'manifest',      UNMARKED, MARKED, 'none' ],
             [ 'tfa',        'keyfile',       UNMARKED, MARKED, 'none' ],
             [ 'keyfile',    '<filename>',    MARKED,   UNMARKED, 'keyfile <filename>' ],
             [ 'manifest',   '<filename>',    MARKED,   MARKED,   'manifest <filename>' ],
             [ '<filename>', 'keyfile',       UNMARKED, MARKED,   'none' ],
             [ 'keyfile',    '<newfilename>', MARKED,   UNMARKED, 'keyfile <newfilename>' ],

             # ips finalize
             [ 'ips',        'finalize',      UNMARKED, MARKED,   'none' ],
             [ 'finalize',   'package',       UNMARKED, MARKED,   'none' ],
             [ 'package',    '<integer>',     MARKED,   MARKED, 'ips finalize package <integer>' ], 
             [ '<integer>',  'manifest',      UNMARKED, MARKED, 'none' ],
             [ 'manifest',   '<filename>',    MARKED,   UNMARKED, 'manifest <filename>' ],

             # ips generate package
             [ 'ips',        'generate',      UNMARKED, MARKED,   'none' ],
             [ 'generate',   'package',       UNMARKED, MARKED,   'none' ],
             [ 'package',    '<integer>',     MARKED,   MARKED,   'ips generate package <integer>' ],
             [ '<integer>',  'in',            UNMARKED, MARKED,   'none' ],
             [ 'in',         '<path>',        MARKED,   MARKED,   'in <path>' ],
             [ '<path>',     'complete',      MARKED,   UNMARKED, 'complete' ],
             [ '<path>',     'incremental',   MARKED,   UNMARKED, 'incremental' ],
             [ '<integer>',  'complete',      MARKED,   UNMARKED, 'complete' ],
             [ '<integer>',  'incremental',   MARKED,   UNMARKED, 'incremental' ], 

             # ips unpack file / integration tfa
             # ips unpack package
             [ 'ips',        'unpack',        UNMARKED, MARKED,   'none' ],
             [ 'unpack',     'integration',   UNMARKED, MARKED,   'none' ],
             [ 'integration','tfa',           UNMARKED, MARKED,   'none' ],
             [ 'tfa',        'base',          UNMARKED, MARKED,   'none' ],
             [ 'base',       '<path>',        MARKED,   UNMARKED, 'ips unpack integration tfa base <path>' ],
             [ 'unpack',     'file',          UNMARKED, MARKED,   'none' ],
             [ 'file',       '<filename>',    MARKED,   MARKED,   'ips unpack file <filename>' ],
             [ '<filename>', 'into',          UNMARKED, MARKED,   'none' ],
             #[ 'into',       '<path>',        MARKED,   UNMARKED, 'into <path>' ],
             [ 'unpack',     'package',       UNMARKED, MARKED,   'none' ],
             [ 'package',    '<packname>',    MARKED,   MARKED,   'ips unpack package <packname>' ],
             [ '<packname>', 'into',          UNMARKED, MARKED,   'none' ],
             [ 'into',       '<path>',        MARKED,   UNMARKED, 'into <path>' ],
             [ 'package',    '<integer>',     MARKED,   MARKED,   'ips unpack package <integer>' ],
             [ '<integer>',  'into',          UNMARKED, MARKED,   'none' ],
             [ 'into',       '<path>',        MARKED,   UNMARKED, 'into <path>' ],

             [ 'ips',        'add',           UNMARKED, MARKED,   'none' ],
             # ips add adrbase
             [ 'add',        'adrbase',       UNMARKED, MARKED,   'none' ],
             [ 'adrbase',    '<path>',        MARKED,   UNMARKED, 'ips add adrbase <path>' ],

             # ips add new incidents
             [ 'add',        'new',           UNMARKED, MARKED,   'none' ],
             [ 'new',        'incidents',     UNMARKED, MARKED,   'none' ],
             [ 'incidents',  'package',       UNMARKED, MARKED,   'none' ],
             [ 'package',    '<integer>',     MARKED,   UNMARKED, 'ips add new incidents package <integer>' ],

             # ips add file
             [ 'add',        'file',          UNMARKED, MARKED,   'none' ],
             [ 'file',       '<filename>',    UNMARKED, MARKED,   'none' ],
             [ '<filename>', 'package',       UNMARKED, MARKED,   'none' ],
             [ 'package',    '<integer>',     MARKED,   UNMARKED, 'ips add file <filename> package <integer>' ],

             # ips add
             [ 'add',        'incident',      UNMARKED, MARKED,   'none' ],
             [ 'add',        'problem',       UNMARKED, MARKED,   'none' ],
             [ 'add',        'problemkey',    UNMARKED, MARKED,   'none' ],
             [ 'add',        'seconds',       UNMARKED, MARKED,   'none' ],
             [ 'add',        'time',          UNMARKED, MARKED,   'none' ],

             [ 'incident',   '<integer>',     MARKED,   MARKED,   "ips add incident <integer>" ],
             [ 'incident',   'last',          UNMARKED, MARKED,   'none' ],
             [ 'last',       '<integer>',     MARKED,   MARKED,   "ips add incident last <integer>" ],
             [ 'problem',    '<integer>',     MARKED,   MARKED,   "ips add problem <integer>" ],
             [ 'problemkey', '<problem_key>', MARKED,   MARKED,   "ips add problemkey '<problem_key>'" ],
             [ 'seconds',    '<integer>',     MARKED,   MARKED,   "ips add seconds <integer>" ],
             [ 'time',       '<start_time>',  UNMARKED, MARKED,   "none" ],
             [ '<start_time>','to',           UNMARKED, MARKED,   "none" ],
             [ 'to',         '<end_time>',    MARKED,   MARKED,   "ips add time '<start_time>' to '<end_time>'"],
             [ '<end_time>', 'package',       UNMARKED, MARKED,   'none' ],
             [ '<integer>',  'package',       UNMARKED, MARKED,   'none' ],
             [ '<problem_key>','package',     UNMARKED, MARKED,   'none' ],
             [ 'package',    '<integer>',     MARKED,   UNMARKED, 'package <integer>' ],

             [ 'ips',        'remove',        UNMARKED, MARKED,   'none' ],
             # ips remove file
             [ 'remove',     'file',          UNMARKED, MARKED,   'none' ],
             [ 'file',       '<filename>',    UNMARKED, MARKED,   'none' ],
             [ '<filename>', 'package',       UNMARKED, MARKED,   'none' ],
             [ 'package',    '<integer>',     MARKED,   UNMARKED, 'ips remove file <filename> package <integer>' ],

             # ips remove
             [ 'remove',     'incident',      UNMARKED, MARKED,   'none' ],
             [ 'remove',     'problem',       UNMARKED, MARKED,   'none' ],
             [ 'remove',     'problemkey',    UNMARKED, MARKED,   'none' ],

             [ 'incident',   '<integer>',     MARKED,   MARKED,   "ips remove incident <integer>" ],
             [ 'problem',    '<integer>',     MARKED,   MARKED,   "ips remove problem <integer>" ],
             [ 'problemkey', '<problem_key>', MARKED,   MARKED,   "ips remove problemkey '<problem_key>'" ],
             [ '<integer>',  'package',       UNMARKED, MARKED,   'none' ],
             [ '<problem_key>','package',     UNMARKED, MARKED,   'none' ],
             [ 'package',    '<integer>',     MARKED,   UNMARKED, 'package <integer>' ],

             [ 'ips',        'copy',          UNMARKED, MARKED,   'none' ],
             # ips copy in file
             [ 'copy',       'in',            UNMARKED, MARKED,   'none' ],
             [ 'in',         'file',          UNMARKED, MARKED,   'none' ],
             [ 'file',       '<filename>',    MARKED,   MARKED,   'ips copy in file <filename>' ],
             [ '<filename>', 'to',            UNMARKED, MARKED,   'none' ],
             [ 'to',         '<newfilename>', MARKED,   MARKED,   'to <newfilename>' ],
             [ '<newfilename>','overwrite',   MARKED,   MARKED,   'overwrite' ],
             [ '<filename>', 'overwrite',     MARKED,   MARKED,   'overwrite' ],
             [ '<filename>', 'package',       UNMARKED, MARKED,   'none' ], 
             [ '<newfilename>','package',      UNMARKED, MARKED,   'none' ],
             [ 'overwrite',  'package',       UNMARKED, MARKED,   'none' ],
             [ 'package',    '<integer>',     MARKED,   MARKED,   'package <integer>' ],
             [ '<integer>',  'incident',      UNMARKED, MARKED,   'none' ],
             [ 'incident',   '<integer>',     MARKED,   UNMARKED, 'incident <integer>' ],

             # ips copy out file
             [ 'copy',       'out',           UNMARKED, MARKED,   'none' ],
             [ 'out',        'file',          UNMARKED, MARKED,   'none' ],
             [ 'file',       '<filename>',    UNMARKED, MARKED,   'none' ],
             [ '<filename>', 'to',            UNMARKED, MARKED,   'none' ],
             [ 'to',         '<newfilename>', MARKED,   MARKED,   'ips copy out file <filename> to <newfilename>' ],
             [ '<newfilename>','overwrite',   MARKED,   UNMARKED, 'overwrite' ],

             # ips delete package
             [ 'ips',        'delete',        UNMARKED, MARKED,   'none' ],
             [ 'delete',     'package',       UNMARKED, MARKED,   'none' ],
             [ 'package',    '<integer>',     MARKED,   UNMARKED, 'ips delete package <integer>' ],

             [ 'ips',        'get',           UNMARKED, MARKED,   'none' ],
             # ips get manifest 
             [ 'get',        'manifest',      UNMARKED, MARKED,   'none' ],
             [ 'manifest',   'from',          UNMARKED, MARKED,   'none' ],
             [ 'from',       'file',          UNMARKED, MARKED,   'none' ],
             [ 'file',       '<filename>',    MARKED,   UNMARKED, 'ips get manifest from file <filename>' ],

             # ips get metadata 
             [ 'get',        'metadata',      UNMARKED, MARKED,   'none' ],
             [ 'metadata',   'from',          UNMARKED, MARKED,   'none' ],
             [ 'from',       'file',          UNMARKED, MARKED,   'none' ],
             [ 'file',       '<filename>',    MARKED,   UNMARKED, 'ips get metadata from file <filename>' ],
             [ 'from',       'adr',           MARKED,   UNMARKED, 'ips get metadata from adr' ],

             # ips use remote keys file
             # IPS USE REMOTE KEYS FILE <file_spec> PACKAGE <package_id>
             [ 'ips',        'use',           UNMARKED, MARKED,   'none' ],
             [ 'use',        'remote',        UNMARKED, MARKED,   'none' ],
             [ 'remote',     'keys',          UNMARKED, MARKED,   'none' ],
             [ 'keys',       'file',          UNMARKED, MARKED,   'none' ],
             [ 'file',       '<filename>',    UNMARKED, MARKED,   'none' ],
             [ '<filename>', 'package',       UNMARKED, MARKED,   'none' ],
             [ 'package',    '<integer>',     MARKED,   UNMARKED, 'ips use remote keys file <filename> package <integer>' ],

             # ips set base, homepath
             [ 'ips',        'set',           UNMARKED, MARKED,   'none' ],
             [ 'set',        'base',          UNMARKED, MARKED,   'none' ],
             [ 'base',       '<path>',        MARKED,   UNMARKED, 'set base <path>'],
             [ 'set',        'homepath',      UNMARKED, MARKED,   'none'],
             [ 'homepath',   '<path>',        MARKED,   UNMARKED, 'set homepath <path>' ],

             [ 'ips',        'show',          UNMARKED, MARKED,   'none' ],
             # ips show files
             [ 'show',       'files',         UNMARKED, MARKED,   'none' ],
             [ 'files',      'package',       UNMARKED, MARKED,   'none' ],
             [ 'package',    '<integer>',     MARKED,   UNMARKED, 'ips show files package <integer>' ],

             # ips show incidents
             [ 'show',       'incidents',     MARKED,   MARKED,   'ips show incidents' ],
             [ 'incidents',  '-all',          MARKED,   UNMARKED, '-all' ],
             [ 'incidents',  'package',       UNMARKED, MARKED,   'none' ],
             [ 'package',    '<integer>',     MARKED,   UNMARKED, 'package <integer>' ],

             # ips show problems
             [ 'show',       'problems',      MARKED,   UNMARKED, 'ips show problems' ],

             # ips show base, homes, homepath, configuration
             [ 'show',        'base',         MARKED,   UNMARKED, 'ips show base' ],
             [ 'show',        'homes',        MARKED,   UNMARKED, 'ips show homes' ],
             [ 'show',        'homepath',     MARKED,   UNMARKED, 'ips show homepath'],
             [ 'show',        'configuration', MARKED,  UNMARKED, 'ips show configuration'],

             # ips show package
             [ 'show',        'package',      MARKED,   MARKED,   'ips show package' ],
             [ 'package',     '<integer>',    MARKED,   MARKED,   '<integer>' ],
             [ '<integer>',   'basic',        MARKED,   UNMARKED, 'basic' ],
             [ '<integer>',   'brief',        MARKED,   UNMARKED, 'brief' ],
             [ '<integer>',   'detail',       MARKED,   UNMARKED, 'detail' ],

           ]
                               );

our (%tfactlips_help_commands) = (
    #                                         complete  more    command
    ips => [ [ 'ips',        '<none>',        MARKED,   UNMARKED, 'ipshlp' ],
             [ 'ips',        'add',           MARKED,   MARKED,   'ipsadd' ],
             [ 'add',        'adrbase',       MARKED,   UNMARKED, 'ipsaddadrbase' ],
             [ 'add',        'file',          MARKED,   UNMARKED, 'ipsaddfile' ],
             [ 'add',        'new',           UNMARKED, MARKED,   'none' ],
             [ 'new',        'incidents',     MARKED,   UNMARKED, 'ipsaddnewinc' ],
             [ 'ips',        'check',         UNMARKED, MARKED,   'none' ],
             [ 'check',      'remote',        UNMARKED, MARKED,   'none' ],
             [ 'remote',     'keys',          MARKED,   UNMARKED, 'ipschkremkey' ],
             [ 'ips',        'copy',          UNMARKED, MARKED,   'none' ],
             [ 'copy',       'in',            UNMARKED, MARKED,   'none' ],
             [ 'in',         'file',          MARKED,   UNMARKED, 'ipscpyinfil' ],
             [ 'ips',        'copy',          UNMARKED, MARKED,   'none' ],
             [ 'copy',       'out',           UNMARKED, MARKED,   'none' ],
             [ 'out',        'file',          MARKED,   UNMARKED, 'ipscpyoutfil' ],
             [ 'ips',        'create',        UNMARKED, MARKED,   'none' ],
             [ 'create',     'package',       MARKED,   UNMARKED, 'ipscrtpck' ],
             [ 'ips',        'delete',        UNMARKED, MARKED,   'none' ],
             [ 'delete',     'package',       MARKED,   UNMARKED, 'ipsdelpck' ],
             [ 'ips',        'finalize',      UNMARKED, MARKED,   'none' ],
             [ 'finalize',   'package',       MARKED,   UNMARKED, 'ipsfinpck' ],
             [ 'ips',        'generate',      UNMARKED, MARKED,   'none' ],
             [ 'generate',   'package',       MARKED,   UNMARKED, 'ipsgenpck' ],
             [ 'ips',        'get',           UNMARKED, MARKED,   'none' ],
             [ 'get',        'manifest',      MARKED,   UNMARKED, 'ipsgetmft' ],
             [ 'ips',        'get',           UNMARKED, MARKED,   'none' ],
             [ 'get',        'metadata',      MARKED,   UNMARKED, 'ipsgetmtd' ],
             [ 'ips',        'get',           UNMARKED, MARKED,   'none' ],
             [ 'get',        'remote',        UNMARKED, MARKED,   'none' ],
             [ 'remote',     'keys',          MARKED,   UNMARKED, 'ipsgetremkey' ],
             [ 'ips',        'pack',          MARKED,   UNMARKED, 'ipspck' ],
             [ 'ips',        'remove',        MARKED,   MARKED,   'ipsrem' ],
             [ 'remove',     'file',          MARKED,   UNMARKED, 'ipsremfil' ],
             [ 'ips',        'set',           UNMARKED, MARKED,   'none' ],
             [ 'set',        'configuration', MARKED,   UNMARKED, 'ipssetcnf' ],
             [ 'ips',        'show',          UNMARKED, MARKED,   'none' ],
             [ 'show',       'configuration', MARKED,   UNMARKED, 'ipsshwcnf' ],
             [ 'ips',        'show',          UNMARKED, MARKED,   'none' ],
             [ 'show',       'files',         MARKED,   UNMARKED, 'ipsshwfil' ],
             [ 'ips',        'show',          UNMARKED, MARKED,   'none' ],
             [ 'show',       'incidents',     MARKED,   UNMARKED, 'ipsshwinc' ],
             [ 'ips',        'show',          UNMARKED, MARKED,   'none' ],
             [ 'show',       'problems',     MARKED,   UNMARKED, 'ipsshwprob' ],
             [ 'ips',        'show',          UNMARKED, MARKED,   'none' ],
             [ 'show',       'package',       MARKED,   UNMARKED, 'ipsshwpkg' ],
             [ 'ips',        'unpack',        UNMARKED, MARKED,   'none' ],
             [ 'unpack',     'file',          MARKED,   UNMARKED, 'ipsunpfil' ],
             [ 'ips',        'unpack',        UNMARKED, MARKED,   'none' ],
             [ 'unpack',     'package',       MARKED,   UNMARKED, 'ipsunppkg' ],
             [ 'ips',        'unpack',        UNMARKED, MARKED,   'none' ],
             [ 'unpack',     'integration',   UNMARKED, MARKED,   'none' ],
             [ 'integration','tfa',           MARKED,   UNMARKED, 'ipsunpinttfa' ],
             [ 'ips',        'use',           UNMARKED, MARKED,   'none' ],
             [ 'use',        'remote',        UNMARKED, MARKED,   'none' ],
             [ 'remote',     'keys',          MARKED,   UNMARKED, 'ipsuseremkey' ],

           ]
                               );

our (%tfactlips_help_messages) = ( 
    ips => [ [ 'ipshlp',    
qq/
  Usage:  IPS [ADD | ADD FILE | ADD NEW INCIDENTS | CHECK REMOTE KEYS | 
               COPY IN FILE | COPY OUT FILE | CREATE PACKAGE | DELETE PACKAGE |
               FINALIZE PACKAGE | GENERATE PACKAGE | GET MANIFEST | GET METADATA |
               GET REMOTE KEYS | PACK | REMOVE | REMOVE FILE | SET CONFIGURATION |
               SHOW CONFIGURATION | SHOW FILES | SHOW INCIDENTS | SHOW PROBLEMS |
               SHOW PACKAGE | UNPACK FILE | UNPACK PACKAGE | USE REMOTE KEYS] [options]

  For detailed help on each topic use:
    help ips <topic>
  
  Available Topics: 
        ADD                Add incidents to an existing package. 
        ADD ADRBASE        Add a custom ADR basepath to the local node.
        ADD FILE           Add a file to an existing package. 
        ADD NEW INCIDENTS  Find new incidents for the problems and
                           add the latest ones to the package.
        CHECK REMOTE KEYS  Create a file with keys matching incidents in
                           specified package.
        COPY IN FILE       Copy an external file into ADR, and associate it
                           with a package and (optionally) an incident.
        COPY OUT FILE      Copy an ADR file to a location outside ADR.
        CREATE PACKAGE     Create a package, and optionally select 
                           contents for the package.
        DELETE PACKAGE     Drops a package and its contents from ADR.
        FINALIZE PACKAGE   Get a package ready for shipping by automatically
                           including correlated contents.
        GENERATE PACKAGE   Create a physical package (zip file) in target
                           directory.
        GET MANIFEST       Extract the manifest from a package file and
                           display it.
        GET METADATA       Extract the metadata XML document from a 
                           package file and display it.
        GET REMOTE KEYS    Create a file with keys matching incidents in
                           specified package.
        PACK               Create a package, and immediately generate 
                           the physical package.
        REMOVE             Remove incidents from an existing package.
        REMOVE FILE        Remove a file from an existing package.
        SET CONFIGURATION  Change the value of an IPS configuration parameter.
        SHOW CONFIGURATION Show the current IPS settings. 
        SHOW FILES         Show files included in the specified package.
        SHOW INCIDENTS     Show incidents included in the specified package.
        SHOW PROBLEMS      Show problems for the current ADR home.
        SHOW PACKAGE       Show details for the specified package.
        UNPACK FILE        Unpackages a physical file into the specified path.
        UNPACK PACKAGE     Unpackages physical files in the current directory
                           into the specified path, if they match the package
                           name.
        USE REMOTE KEYS    Add incidents matching the keys in the specified
                           file to the specified package.
/ ],

             [ 'ipsadd',
qq/
  Usage:  IPS ADD
             [INCIDENT <incid> | PROBLEM <prob_id> | PROBLEMKEY <prob_key> |
              SECONDS <seconds> | TIME <start_time> TO <end_time>]
             PACKAGE <package_id> 

  Purpose: Add incidents to an existing package.

  Arguments:
    <incid>:      ID of incident to add to package contents.
    <prob_id>:    ID of problem to add to package contents.
    <prob_key>:   Problem key to add to package contents.
    <seconds>:    Number of seconds before now for adding package contents .
    <start_time>: Start of time range to look for incidents in.
    <end_time>:   End of time range to look for incidents in.
  Example:
    ips add incident 22 package 12
/ ],

             [ 'ipsaddadrbase',
qq/
  Usage:  IPS ADD ADRBASE <adrpath>

  Purpose: Add a custom ADR basepath in the local node.

  Arguments:
    <adrpath>     :Custom ADR basepath.
  Example:
    ips add adrbase \/u01\/app\/oradb
/ ],

             [ 'ipsaddfile',
qq/
  Usage:  IPS ADD FILE <file_spec> PACKAGE <pkgid>

  Purpose: Add a file to an existing package. The file should be in the same
           ADR_BASE as the package.

  Arguments:
    <file_spec>:  File specified with file and path (full or relative).
    <package_id>: The ID of the package to add file to.

  Example:
    ips add file <ADR_HOME>\/trace\/mydb1_ora_13579.trc package 12
/ ],

             [ 'ipsaddnewinc',
qq/
  Usage:  IPS ADD NEW INCIDENTS PACKAGE <package_id> 

  Purpose: Find new incidents for the problems in the specified package,
           and add the latest ones to the package.

  Arguments:
    <package_id>: The ID of the package to add incidents to.

  Example:
    ips add new incidents package 12
/ ],

             [ 'ipschkremkey',
qq/
  Usage:  IPS GET REMOTE KEYS FILE <file_spec> PACKAGE <package_id> 

  Purpose: Create a file with keys matching incidents in specified package.

  Arguments:
    <file_spec>:  File specified with file name and full path.
    <package_id>: ID of package to get keys for.

  Example:
     ips get remote keys file \/tmp\/key_file.txt package 12
/ ],


             [ 'ipscpyinfil',
qq/
  Usage:  IPS COPY IN FILE <file> [TO <new_name>] [OVERWRITE]
             PACKAGE <pkgid> [INCIDENT <incid>]

  Purpose: Copy an external file into ADR, and associate it with a package
           and (optionally) an incident.

  Arguments:
    <file>:     File specified with file name and full path.
    <new_name>: Use this name for the copy of the file.
    <pkgid>:    ID of package to associate file with.
    <incid>:    ID of incident to associate file with.

  Options:
    OVERWRITE:  If a copy of the file already exists, overwrite it.

  Example:
    ips copy in file \/tmp\/key_file.txt to new_file.txt package 12 incident 62
/ ],


             [ 'ipscpyoutfil',
qq/
  Usage:  IPS COPY OUT FILE <source> TO <target> [OVERWRITE]

  Purpose: Copy an ADR file to a location outside ADR

  Arguments:
    <source>:  ADR file specified with file name and full or relative path.
               This file must be inside ADR.
    <target>:  External file specified with file name and full path.
               This file must be outside ADR.
  Options:
    OVERWRITE:  If a copy of the file already exists, overwrite it.

  Example:
    ips copy out file <ADR_HOME>\/trace\/ora_26201 to \/tmp\/trace_26201.txt
/ ],


             [ 'ipscrtpck',
qq/
  Usage:  IPS CREATE PACKAGE
             [INCIDENT <incid> | PROBLEM <prob_id> | PROBLEMKEY <prob_key> |
              SECONDS <seconds> | TIME <start_time> TO <end_time>]
             [CORRELATE BASIC | TYPICAL | ALL]
             [MANIFEST <file_spec>] [KEYFILE <file_spec>]

  Purpose: Create a package, and optionally select contents for the package.

  Arguments:
    <incid>:      ID of incident to use for selecting package contents.
    <prob_id>:    ID of problem to use for selecting package contents.
    <prob_key>:   Problem key to use for selecting package contents.
    <seconds>:    Number of seconds before now for selecting package contents.
    <start_time>: Start of time range to look for incidents in.
    <end_time>:   End of time range to look for incidents in.

  Options:
    CORRELATE BASIC:   The package will include the incident dumps, and the
                       incident process trace files.
                       Additional incidents can be included automatically,
                       if they share relevant correlation keys.
    CORRELATE TYPICAL: The package will include the incident dumps, and all
                       trace files that were modified in a time window around
                       each incident.
                       Additional incidents can be included automatically,
                       if they share relevant correlation keys, or occurred
                       in a time window around the main incidents.
    CORRELATE ALL:     The package will include the incident dumps, and all
                       trace files that were modified between the first
                       selected incident and the last selected incident.
                       Additional incidents can be included automatically,
                       if they occurred in the same time range.
    MANIFEST file_spec: Generate XML format package manifest file.
    KEYFILE file_spec:  Generate remote key file.

  Notes:
    If no package contents are specified (incident, problem, etc), an empty 
    package will be created. Files and incidents can be added later.
    If no correlation level is specified, the default level is used.
    The default is normally TYPICAL, but it can be changed using the command
    IPS SET CONFIGURATION.

  Example:
    ips create package incident 861;
    ips create package time '2006-12-31 23:59:59.00 -07:00' to
        '2007-01-01 01:01:01.00 -07:00';
/ ],


             [ 'ipsdelpck',
qq/
  Usage:  IPS DELETE PACKAGE <package_id>

  Purpose: Drops a package and its contents from ADR. 

  Arguments:
    <package_id>: ID of package to delete.

  Example:
    ips delete package 12
/ ],


             [ 'ipsfinpck',
qq/
  Usage:  IPS FINALIZE PACKAGE <package_id>

  Purpose: Get a package ready for shipping by automatically including
           correlated contents.

  Arguments:
    <package_id>: ID of package to finalize.

  Example:
    ips finalize package 12
/ ],


             [ 'ipsgenpck',
qq/
  Usage:  IPS GENERATE PACKAGE <package_id> [IN <path>]
             [COMPLETE | INCREMENTAL]

  Purpose: Create a physical package (zip file) in target directory.

  Arguments:
    <package_id>: ID of package to create physical package file for.
    <path>:       Path where the physical package file should be generated.

  Options:
    COMPLETE:    The package will include all package files, even if a
                 previous package sequence has been generated.
                 This is the default.
    INCREMENTAL: The package will only include files that have been added
                 or changed since the last package generation.

  Notes:
    If no target path is specified, the physical package file is generated
    in the current working directory.

  Example:
    ips generate package 12 in \/tmp
/ ],


             [ 'ipsgetmft',
qq/
  Usage:  IPS GET MANIFEST FROM FILE <file>

  Purpose: Extract the manifest from a package file and display it.

  Arguments:
    <file>:  External file specified with file name and full path.

  Example:
    ips get manifest from file \/tmp\/IPSPKG_200704130121_COM_1.zip
/ ],


             [ 'ipsgetmtd',
qq/
  Usage:  IPS GET METADATA [FROM FILE <file> | FROM ADR]

  Purpose: Extract the metadata XML document from a package file and display it.

  Arguments:
    <file>:  External file specified with file name and full path.

  Example:
    ips get metadata from file \/tmp\/IPSPKG_200704130121_COM_1.zip
/ ],

             [ 'ipsgetremkey',
qq/
  Usage:  IPS GET REMOTE KEYS FILE <file_spec> PACKAGE <package_id> 

  Purpose: Create a file with keys matching incidents in specified package.

  Arguments:
    <file_spec>:  File specified with file name and full path.
    <package_id>: ID of package to get keys for.

  Example:
     ips get remote keys file \/tmp\/key_file.txt package 12
/ ],

             [ 'ipspck',
qq/
  Usage:  IPS PACK
             [INCIDENT <incid> | PROBLEM <prob_id> | PROBLEMKEY <prob_key> |
              SECONDS <seconds> | TIME <start_time> TO <end_time>]
             [CORRELATE BASIC | TYPICAL | ALL]
             [MANIFEST <file_spec>] [KEYFILE <file_spec>]
             [IN <path>]

  Purpose: Create a package, and immediately generate the physical package.

  Arguments:
    <incid>:      ID of incident to use for selecting package contents.
    <prob_id>:    ID of problem to use for selecting package contents.
    <prob_key>:   Problem key to use for selecting package contents.
    <seconds>:    Number of seconds before now for selecting package contents.
    <start_time>: Start of time range to look for incidents in.
    <end_time>:   End of time range to look for incidents in.
    <path>:       Path where the physical package file should be generated.

  Options:
    CORRELATE BASIC:   The package will include the incident dumps, and the
                       incident process trace files.
                       Additional incidents can be included automatically,
                       if they share relevant correlation keys.
    CORRELATE TYPICAL: The package will include the incident dumps, and all
                       trace files that were modified in a time window around
                       each incident.
                       Additional incidents can be included automatically,
                       if they share relevant correlation keys, or occurred
                       in a time window around the main incidents.
    CORRELATE ALL:     The package will include the incident dumps, and all
                       trace files that were modified between the first
                       selected incident and the last selected incident.
                       Additional incidents can be included automatically,
                       if they occurred in the same time range.
    MANIFEST file_spec: Generate XML format package manifest file.
    KEYFILE file_spec:  Generate remote key file.

  Notes:
    If no package contents are specified (incident, problem, etc), an empty 
    package will be created. Files and incidents can be added later.
    If no correlation level is specified, the default level is used.
    The default is normally TYPICAL, but it can be changed using the command
    IPS SET CONFIGURATION.

  Example:
    ips pack incident 861;
    ips pack time '2006-12-31 23:59:59.00 -07:00' to
        '2007-01-01 01:01:01.00 -07:00';
/ ],

             [ 'ipsrem',
qq/
  Usage:  IPS REMOVE
             [INCIDENT <incid> | PROBLEM <prob_id> | PROBLEMKEY <prob_key> ]
             PACKAGE <package_id> 

  Purpose: Remove incidents from an existing package. The incidents remain
           associated with the package, but will not be included in the
           physical package file.

  Arguments:
    <incid>:      ID of incident to add to package contents.
    <prob_id>:    ID of problem to add to package contents.
    <prob_key>:   Problem key to add to package contents.
  Example:
     ips remove incident 22 package 12
/ ],

             [ 'ipsremfil',
qq/
  Usage:  IPS REMOVE FILE <file_spec> PACKAGE <pkgid>

  Purpose: Remove a file from an existing package. The file should be in the
           same ADR_BASE as the package. The file remains associated with the
           package, but will not be included in the physical package file.

  Arguments:
    <file_spec>:  File specified with file and path (full or relative).
    <package_id>: The ID of the package to remove file from.

  Example:
     ips remove file <ADR_HOME>\/trace\/mydb1_ora_13579.trc package 12
/ ],

             [ 'ipssetcnf',
qq/
  Usage:  IPS SET CONFIGURATION <parameter_id> <value> 

  Purpose: Change the value of an IPS configuration parameter.

  Arguments:
    <parameter_id>: ID of the parameter to change.
    <value>:        The new value for the parameter.

  Example:
    ips set configuration 6 2
/ ],

             [ 'ipsshwcnf',
qq/
  Usage:  IPS SHOW CONFIGURATION [<parameter_id>]

  Purpose: Show the current IPS settings.

  Arguments:
    <parameter_id>: The ID of the parameter to show information about.

  Example:
     ips show configuration
/ ],

             [ 'ipsshwfil',
qq/
  Usage:  IPS SHOW FILES PACKAGE <package_id>

  Purpose: Show files included in the specified package.

  Arguments:
    <package_id>: The ID of the package to show files for.

  Example:
     ips show files package 12
/ ],

             [ 'ipsshwinc',
qq/
  Usage:  IPS SHOW INCIDENTS PACKAGE <package_id> 

  Purpose: Show incidents included in the specified package.

  Arguments:
    <package_id>: The ID of the package to show incidents for.

  Example:
     ips show incidents package 12
/ ],

             [ 'ipsshwprob',
qq/
  Usage:  IPS SHOW PROBLEMS

  Purpose: Show problems for the current ADR home.

  Arguments:

  Example:
     ips show problems
/ ],

             [ 'ipsshwpkg',
qq/
  Usage:  IPS SHOW PACKAGE <package_id> [BASIC | BRIEF | DETAIL]

  Purpose: Show details for the specified package.

  Arguments:
    <package_id>: The ID of the package to show details for.

  Notes:
    It's possible to specify the level of detail to use with this command.
    BASIC shows a minimal amount of information. It is the default when no
    package ID is specified.
    BRIEF shows a more extensive amount of information. It is the default
    when a package ID is specified.
    DETAIL shows the same information as BRIEF, and additionally some
    package history and information on included incidents and files.
  Example:
     ips show package
     ips show package 12 detail
/ ],

             [ 'ipsunpfil',
qq/
  Usage:  IPS UNPACK FILE <file_spec> [INTO <path>]

  Purpose: Unpackages a physical file into the specified path.
           This automatically creates a valid ADR_HOME structure.
           The path must exist and be writable.

  Arguments:
    <file_spec>:  File specified with file name and full path.
    <path>:       Path where the physical package file should be unpacked.

  Example:
     ips unpack file \/tmp\/IPSPKG_20061026010203_COM_1.zip into \/tmp\/newadr
/ ],

             [ 'ipsunppkg',
qq/
  Usage:  IPS UNPACK PACKAGE <pkg_name> [INTO <path>]

  Purpose: Unpackages physical files in the current directory
           into the specified path, if they match the package name.
           This automatically creates a valid ADR_HOME structure.
           The path must exist and be writable.

  Arguments:
    <pkg_name>:  Package name (used as file name prefix).
    <path>:      Path where the physical package files should be unpacked.

  Example:
     ips unpack package IPSPKG_20061026010203 into \/tmp\/newadr
/ ],

             [ 'ipsunpinttfa',
qq/
  Usage:  IPS UNPACK PACKAGE <pkg_name> [INTO <path>]

  Purpose: Unpackages physical files in the current directory
           into the specified path, if they match the package name.
           This automatically creates a valid ADR_HOME structure.
           The path must exist and be writable.

  Arguments:
    <pkg_name>:  Package name (used as file name prefix).
    <path>:      Path where the physical package files should be unpacked.

  Example:
     ips unpack package IPSPKG_20061026010203 into \/tmp\/newadr
/ ],

             [ 'ipsuseremkey',
qq/
  Usage:  IPS USE REMOTE KEYS FILE <file_spec> PACKAGE <package_id>

  Purpose: Add incidents matching the keys in the specified file
           to the specified package.

  Arguments:
    <file_spec>:  File specified with file name and full path.
    <package_id>: The ID of the package to add incidents to.

  Example:
     ips use remote keys file \/tmp\/key_file.txt package 12
/ ],

           ]
                               );

#################### tfactlips Global Variables ####################

sub is_tfactl
{
  return 1;
}


########
# NAME
#   tfactlips_init
#
# DESCRIPTION
#   This function initializes the tfactlips module.  For now it 
#   simply registers its callbacks with the tfactlglobal module.
#
# PARAMETERS
#   None
#
# RETURNS
#   Null
#
# NOTES
#   Only tfactl_main() calls this routine.
########
sub init
{
  # All of the arrays defined in the tfactlglobal module must be 
  # initialized here.  Otherwise, an internal error will result.
  push (@tfactlglobal_command_callbacks, \&tfactlips_process_cmd);
  push (@tfactlglobal_help_callbacks, \&tfactlips_process_help);
  push (@tfactlglobal_command_list_callbacks, \&tfactlips_get_tfactl_cmds);
  push (@tfactlglobal_is_command_callbacks, \&tfactlips_is_cmd);
  push (@tfactlglobal_is_wildcard_callbacks, \&tfactlips_is_wildcard_cmd);
  push (@tfactlglobal_syntax_error_callbacks, \&tfactlips_syntax_error);
  push (@tfactlglobal_no_instance_callbacks, \&tfactlips_is_no_instance_cmd);
  %tfactlglobal_cmds = (%tfactlglobal_cmds, %tfactlips_cmds);
  %tfactlglobal_commands = (%tfactlglobal_commands, %tfactlips_commands);
  %tfactlglobal_help_commands = (%tfactlglobal_help_commands, %tfactlips_help_commands);
  %tfactlglobal_help_messages = (%tfactlglobal_help_messages, %tfactlips_help_messages);

  #Perform TFACTL consistency check if enabled
  if($tfactlglobal_hash{'consistchk'} eq 'y')
  {
     if(!tfactlshare_check_option_consistency(%tfactlips_cmds))
     {   
       exit 1;
     }
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlips init", 'y', 'n');

}

########
# NAME
#   tfactlips_process_cmd
#
# DESCRIPTION
#   This routine calls the appropriate routine to process the command 
#   specified by $tfactlglobal_hash{'cmd'}.
#
# PARAMETERS
#   dbh       (IN) - initialized database handle, must be non-null.
#
# RETURNS
#   1 if command is found in the tfactlips module; 0 if not.
#
# NOTES
#   Only tfactl_shell() calls this routine.
########
sub tfactlips_process_cmd 
{
  my ($retval) = 0;
  my ($succ)   = 0;

  # Get current command from global value, which is set by 
  # tfactlips_parse_tfactl_args()and by tfactl_shell().
  my ($cmd) = $tfactlglobal_hash{'cmd'};

  # Declare and initialize hash of function pointers, each designating a 
  # routine that processes an tfactlips command.
  my (%cmdhash) = ( ips       => \&tfactlips_process_command,
                    IPS       => \&tfactlips_process_command,
                  );

  if (defined ( $cmdhash{ lc($cmd) } ))
  {    # If user specifies a known command, then call routine to process it. #
    $retval = $cmdhash{ lc($cmd) }->();
    $succ = 1;
  }
  tfactlshare_trace(3, "tfactl (PID = $$) tfactlips tfactlips_process_cmd", 'y', 'n');

  return ($succ, $retval);
}

########
# NAME
#   tfactlips_process_command
#
# DESCRIPTION
#   This function ...
#
# PARAMETERS
#
# RETURNS
#   Null.
#
# NOTES
#   Only tfactlips_process_cmd() calls this function.
########
sub tfactlips_process_command
{
  my $retval = 0;

  tfactlshare_trace(3, "tfactl (PID = $$) tfactlips tfactlips_process_command", 'y', 'n');
  # Read the commands
  # -h/-help switch included after the ips topic
  if ( lc($tfactlglobal_argv[$#tfactlglobal_argv]) eq "-h" || lc($tfactlglobal_argv[$#tfactlglobal_argv]) eq "-help" ) {
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_process_command " .
                      "processing tfactl ips <topic> -h/-help command.", 'y', 'y');
    pop @tfactlglobal_argv;
    @tfactlglobal_help_argv = @tfactlglobal_argv;
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_process_command " .
                      "tfactlglobal_help_argv @tfactlglobal_help_argv", 'y', 'y');
    tfactlips_process_help("ips");
    return;
  }
  @ARGV = @tfactlglobal_argv;
  my $command1 = shift(@ARGV);
  my $command2 = shift(@ARGV);
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_process_command " .
                    "tfactlglobal_argv @tfactlglobal_argv", 'y', 'y');
  my $switch_val = tfactlshare_parse_command( 'cmd', @tfactlglobal_argv);
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_process_command " .
                    "switch_val $switch_val", 'y', 'y');
  my $commandline;

  $TFAIPS_ADRCICOMMAND = $switch_val;
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_process_command " .
                    "====> tfactlshare_parse_command return $TFAIPS_ADRCICOMMAND", 'y', 'y');  

  if ( $switch_val ne 'none' ) {
    $switch_val =~ s/^\s+//g;
    # Handle special cases
    if ( $switch_val =~ m/^ips show incidents(\s+\-[aA][lL][lL])?$/ ) {
      # ips show incidents
      $switch_val = "show incidents$1";
      $TFAIPS_ADRCICOMMAND = $switch_val;
      $TFAIPS_SHOWINC = 1;
    }
    elsif ( $switch_val =~ m/^ips show problems$/ ) {
      # ips show problems
      $switch_val = "show problems";
      $TFAIPS_ADRCICOMMAND = $switch_val;
      $TFAIPS_SHOWPROB = 1;
    }
    elsif ( $switch_val =~ m/^ips show incidents package \d+$/ ) {
      # ips show incidents
      $TFAIPS_SHOWINC = 1;
      # $TFAIPS_PACKNUMBER
    }
    elsif ( $switch_val =~ m/^ips -help$/ ) {
      $TFAIPS_SHOWHELP = 1;
    }
    elsif ($switch_val =~ m/^ips create package/ ) {
      $TFAIPS_CRTPKG = 1;
      if ( $switch_val =~ m/incident\s+\d+/ ) {
        # create package incident <incid> additional processing 
        # $TFAIPS_NUMBER
      } elsif ( $switch_val =~ m/incident first\s+\d+/ ) {
        # create package incident first <integer> additional processing 
        # $TFAIPS_NUMBER
      } elsif ( $switch_val =~ m/incident last\s+\d+/ ) {
        # create package incident last <integer> additional processing 
        # $TFAIPS_NUMBER
      } elsif ( $switch_val =~ m/problemkey/ ) {
        # create package problemkey <probkey> additional processing 
        # $TFAIPS_PRBKEY
      } elsif ( $switch_val =~ m/time/ ) {
        # create package time <start_time> to <end_time> additional processing 
        # $TFAIPS_STTIME 
        # $TFAIPS_ENDTIME
      }

      # manifest file
      if ( $switch_val =~ m/manifest/ ) {
        # $TFAIPS_FILENAME;
      }
      # keyfile
      if ( $switch_val =~ m/keyfile/ ) {
        # $TFAIPS_NEWFILENAME;
      }

      # Detect correlation level if any
      if ( $switch_val =~ m/correlate\s+(basic|typical|all)/ ) {
        $TFAIPS_CORRLVL = $1;
      }
    }
    elsif ($switch_val =~ m/^ips pack/ ) {
      $TFAIPS_PACK = 1;
      if ( $switch_val =~ m/incident\s+\d+/ ) {
        # ips pack incident <incid> additional processing 
        # $TFAIPS_NUMBER
      } elsif ( $switch_val =~ m/problem/ ) {
        # ips pack problem <integer> additional processing 
        # $TFAIPS_NUMBER
      } elsif ( $switch_val =~ m/problemkey/ ) {
        # ips pack problemkey <probkey> additional processing 
        # $TFAIPS_PRBKEY
      } elsif ( $switch_val =~ m/seconds/ ) {
        # ips pack seconds <integer>  additional processing 
        # $TFAIPS_NUMBER
      } elsif ( $switch_val =~ m/time/ ) {
        # ips pack time <start_time> to <end_time> additional processing 
        # $TFAIPS_STTIME 
        # $TFAIPS_ENDTIME
      }

      # manifest file
      if ( $switch_val =~ m/manifest/ ) {
        # $TFAIPS_FILENAME;
      }
      # keyfile
      if ( $switch_val =~ m/keyfile/ ) {
        # $TFAIPS_NEWFILENAME;
      }

      # Detect correlation level if any
      if ( $switch_val =~ m/correlate\s+(basic|typical|all)/ ) {
        $TFAIPS_CORRLVL = $1; }
      # Retrieve path if available 
      if ( $switch_val =~ m/\s+in\+/ ) {
        #  $TFAIPS_FILEPATH
      } 
    }
    elsif ($switch_val =~ m/^ips finalize package/ ) {
      $TFAIPS_FINPKG = 1;
      if ( $switch_val =~ m/package \s+\d+/ ) {
        # ips finalize package <integer> additional processing 
        # $TFAIPS_PACKNUMBER
      }

      # manifest file
      if ( $switch_val =~ m/manifest/ ) {
        # $TFAIPS_FILENAME;
      }
    }
    elsif ($switch_val =~ m/^ips generate package/ ) {
      $TFAIPS_GENPKG = 1;
      if ( $switch_val =~ m/package \s+\d+/ ) {
        # ips finalize package <integer> additional processing 
        # $TFAIPS_PACKNUMBER
        # $TFAIPS_FILEPATH
      }
    }
    elsif ($switch_val =~ m/^ips unpack file/ ) {
      $TFAIPS_UNPFIL = 1;
      # ips unpack file <filename> into <path> additional processing 
      # $TFAIPS_FILEPATH
      # $TFAIPS_FILENAME
    }
    elsif ($switch_val =~ m/^ips unpack package/ ) {
      $TFAIPS_UNPPKG = 1;
      # ips unpack package <packname> into <path> additional processing 
      # $TFAIPS_PACKNAME
      # $TFAIPS_FILEPATH
    }
    elsif ($switch_val =~ m/^ips unpack integration tfa/ ) {
      $TFAIPS_UNPINTTFA = 1;
      # ips unpack integration tfa base <path> additional processing 
      # $TFAIPS_FILEPATH
    }
    elsif ($switch_val =~ m/^ips use remote keys/ ) {
      $TFAIPS_USEREMKEY = 1;
      # ips use remote keys file <filename> package <integer>
      # $TFAIPS_FILENAME
      # $TFAIPS_PACKNUMBER
    }
    elsif ($switch_val =~ m/^ips add adrbase/ ) {
      $TFAIPS_ADDADRBASE = 1;
      # ips add adrbase <basepath>
      # $TFAIPS_FILEPATH
    }
    elsif ($switch_val =~ m/^ips add new incidents/ ) {
      $TFAIPS_ADDNEWINC = 1;
      if ( $switch_val =~ m/package \s+\d+/ ) {
        # ips add new incidents package <integer> additional processing 
        # $TFAIPS_PACKNUMBER
      }
    }
    elsif ($switch_val =~ m/^ips (add|remove) file/ ) {
      # ips add/remove file <filename> package <integer> additional processing 
      $TFAIPS_ADDREMFIL = 1;
      $TFAIPS_OPERATION = $1;
      # $TFAIPS_FILENAME
      # $TFAIPS_PACKNUMBER
    }
    elsif ($switch_val =~ m/^ips (add|remove)\s+(incident|problem|problemkey|seconds|time)/ ) {
      $TFAIPS_ADDREMOPER = 1;
      $TFAIPS_OPERATION = $1;
      if ( $switch_val =~ m/incident\s+\d+/ ) {
        # ips pack incident <incid> additional processing 
        # $TFAIPS_NUMBER
      } elsif ( $switch_val =~ m/problem/ ) {
        # ips pack problem <integer> additional processing 
        # $TFAIPS_NUMBER
      } elsif ( $switch_val =~ m/problemkey/ ) {
        # ips pack problemkey <probkey> additional processing 
        # $TFAIPS_PRBKEY
      } elsif ( $switch_val =~ m/seconds/ ) {
        # ips pack seconds <integer>  additional processing 
        # $TFAIPS_NUMBER
      } elsif ( $switch_val =~ m/time/ ) {
        # ips pack time <start_time> to <end_time> additional processing 
        # $TFAIPS_STTIME 
        # $TFAIPS_ENDTIME
      }
    }
    elsif ($switch_val =~ m/^ips add incident last/ ) {
        $TFAIPS_ADDINCLAST = 1;
        # ips add incident last <integer> package <integer>
        # $TFAIPS_NUMBER
        # $TFAIPS_PACKNUMBER
    }
    elsif ($switch_val =~ m/^ips copy (in|out) file/ ) {
      $TFAIPS_CPYFIL = 1;
      if ( $switch_val =~ m/overwrite/ ) {
        $TFAIPS_OVERWRITE = "overwrite";
      }
      # ips copy in file <filename> to <newfilename> additional processing 
      $TFAIPS_OPERATION = $1; 
      # $TFAIPS_OVERWRITE
      # $TFAIPS_OPERATION
      # $TFAIPS_FILENAME
      # $TFAIPS_NEWFILENAME
      # $TFAIPS_NUMBER
      # $TFAIPS_PACKNUMBER
    }
    elsif ($switch_val =~ m/^ips delete package/ ) {
      # ips delete package <packnumber> additional processing 
      $TFAIPS_DELPKG = 1;
      # $TFAIPS_PACKNUMBER
    }
    elsif ($switch_val =~ m/^ips get manifest from file/ ) {
      # ips get manifest from file <filename> additional processing
      $TFAIPS_GETMANIFEST = 1;
      # $TFAIPS_FILENAME
    }
    elsif ($switch_val =~ m/^ips get metadata from file/ ) {
      # ips get metadata from file <filename> additional processing
      $TFAIPS_GETMETADATA = 1;
      # $TFAIPS_FILENAME
    }
    elsif ($switch_val =~ m/^ips set base/ ) {
      # ips set base <path> additional processing
      $TFAIPS_SETBASE = 1;
      # $TFAIPS_FILEPATH
    }
    elsif ($switch_val =~ m/^ips set homepath/ ) {
      # ips set homepath <path> additional processing
      $TFAIPS_SETHOMEPATH = 1;
      # $TFAIPS_FILEPATH
    }
    elsif ($switch_val =~ m/^ips show files package/ ) {
      # ips show files package <packnumber> additional processing
      $TFAIPS_SHOWFILES = 1; 
      # $TFAIPS_PACKNUMBER
    }
    elsif ($switch_val =~ m/^ips show (base|homes|homepath)/ ) {
      # ips show (base|homes|homepath) additional processing
      $switch_val = "show $1";
      $TFAIPS_ADRCICOMMAND = $switch_val;
      $TFAIPS_SHOWOPER = 1;
      $TFAIPS_OPERATION = $1;
      # $TFAIPS_PACKNUMBER
    }
    elsif ($switch_val =~ m/^ips show (configuration)/ ) {
      $TFAIPS_ADRCICOMMAND = "ips show $1";
      $TFAIPS_SHOWCONFIG = 1;
    }
    elsif ($switch_val =~ m/^ips show package/ ) {
      # ips show package additional processing
      $TFAIPS_SHOWPKG = 1;
      # $TFAIPS_PACKNUMBER
    }

    tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_process_command " .
                      "====> Number     $TFAIPS_NMBR", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_process_command " .
                      "====> tfaips_number $TFAIPS_NUMBER", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_process_command " .
                      "====> tfaips_packnumber $TFAIPS_PACKNUMBER", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_process_command " .
                      "====> Problemkey $TFAIPS_PRBKEY", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_process_command " .
                      "====> Correlation level $TFAIPS_CORRLVL", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_process_command " .
                      "====> Start time $TFAIPS_STTIME, End time $TFAIPS_ENDTIME", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_process_command " .
                      "====> Filepath   $TFAIPS_FILEPATH", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_process_command " .
                      "====> Filename   $TFAIPS_FILENAME", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_process_command " .
                      "====> NewFilename $TFAIPS_NEWFILENAME", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_process_command " .
                      "====> Operation $TFAIPS_OPERATION", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_process_command " .
                      "====> TFAIPS_ADRCICOMMAND $TFAIPS_ADRCICOMMAND", 'y', 'y');
  } else {
    return;
  }

  # Verify is silent mode is running
  if ( $tfactlglobal_hash{'srcmod'} eq "tfactladmin" ) {
    $tfactlglobal_hash{'srcmod'} = "tfactl";
    $TFAIPS_SILENT = "yes";
  } else {
    $TFAIPS_SILENT = "no";
  }

  # Dispatch the command
  tfactlshare_pre_dispatch();
  $retval = tfactlips_dispatch();

  return $retval;
}

########
# NAME
#   tfactlaccess_dispatch
#
# DESCRIPTION
#   Dispatch de command.
#
# PARAMETERS
#
# RETURNS
#
########
sub tfactlips_dispatch
{
  my $retval = 0;

  if ( $TFAIPS_SHOWINC ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); $TFAIPS_ADRCICOMMAND = "";
                           $TFAIPS_PACKNUMBER = 0; $TFAIPS_SHOWINC = 0; }
  elsif ( $TFAIPS_SHOWPROB ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); $TFAIPS_ADRCICOMMAND = "";
                           $TFAIPS_PACKNUMBER = 0; $TFAIPS_SHOWPROB = 0; }
  elsif ( $TFAIPS_SHOWHELP ) { $tfactlglobal_help_argv[0] = "ips"; tfactlips_process_help("ips"); 
                               $TFAIPS_SHOWHELP = 0; }
  elsif ( $TFAIPS_CRTPKG ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); $TFAIPS_ADRCICOMMAND = "";
                             $TFAIPS_NUMBER = 0; $TFAIPS_PRBKEY = ""; $TFAIPS_STTIME = "";
                             $TFAIPS_ENDTIME = ""; $TFAIPS_CORRLVL = ""; $TFAIPS_CRTPKG = 0;
                             $TFAIPS_FILENAME = ""; $TFAIPS_NEWFILENAME = ""; }
  elsif ( $TFAIPS_PACK ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); $TFAIPS_ADRCICOMMAND = "";
                             $TFAIPS_NUMBER = 0; $TFAIPS_PRBKEY = ""; $TFAIPS_STTIME = "";
                             $TFAIPS_ENDTIME = ""; $TFAIPS_CORRLVL = ""; $TFAIPS_FILEPATH = ""; 
                             $TFAIPS_PACK = 0; $TFAIPS_FILENAME = ""; $TFAIPS_NEWFILENAME = ""; }
  elsif ( $TFAIPS_FINPKG ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); 
                             $TFAIPS_ADRCICOMMAND = ""; $TFAIPS_PACKNUMBER = 0; 
                             $TFAIPS_FILENAME = "";     $TFAIPS_FINPKG = 0; }
  elsif ( $TFAIPS_GENPKG ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); $TFAIPS_ADRCICOMMAND = "";
                             $TFAIPS_PACKNUMBER = 0; $TFAIPS_FILEPATH = ""; $TFAIPS_GENPKG = 0; }
  elsif ( $TFAIPS_UNPFIL ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); 
                             $TFAIPS_ADRCICOMMAND = ""; $TFAIPS_FILEPATH = ""; 
                             $TFAIPS_FILENAME = "";     $TFAIPS_UNPFIL = 0; }
  elsif ( $TFAIPS_UNPPKG ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT);
                             $TFAIPS_ADRCICOMMAND = ""; $TFAIPS_FILEPATH = "";
                             $TFAIPS_PACKNAME = "";    $TFAIPS_UNPPKG = 0; }
  elsif ( $TFAIPS_UNPINTTFA ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); 
                                $TFAIPS_ADRCICOMMAND = ""; $TFAIPS_FILEPATH = ""; 
                                $TFAIPS_UNPINTTFA = 0; }
  elsif ( $TFAIPS_USEREMKEY ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT);
                             $TFAIPS_ADRCICOMMAND = ""; $TFAIPS_FILENAME = "";
                             $TFAIPS_PACKNUMBER = 0;    $TFAIPS_USEREMKEY = 0; }
  elsif ( $TFAIPS_ADDADRBASE ) { $retval = tfactlips_add_adrbase($TFAIPS_FILEPATH);
                                 $TFAIPS_ADDADRBASE = 0; $TFAIPS_FILEPATH = ""; }
  elsif ( $TFAIPS_ADDNEWINC ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); $TFAIPS_ADRCICOMMAND = "";
                                $TFAIPS_PACKNUMBER = 0; $TFAIPS_ADDNEWINC = 0; }
  elsif ( $TFAIPS_ADDREMFIL ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); $TFAIPS_ADRCICOMMAND = "";
                                $TFAIPS_OPERATION = ""; $TFAIPS_FILENAME = ""; $TFAIPS_PACKNUMBER = 0; 
                                $TFAIPS_ADDREMFIL = 0; }
  elsif ( $TFAIPS_ADDREMOPER ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); $TFAIPS_ADRCICOMMAND = "";
                                 $TFAIPS_OPERATION = ""; $TFAIPS_NUMBER = 0; $TFAIPS_PRBKEY = "";
                                 $TFAIPS_STTIME = ""; $TFAIPS_ENDTIME = ""; $TFAIPS_ADDREMOPER = 0; }
  elsif ( $TFAIPS_CPYFIL ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); $TFAIPS_ADRCICOMMAND = "";
                             $TFAIPS_OVERWRITE = ""; $TFAIPS_OPERATION = ""; $TFAIPS_FILENAME = "";
                             $TFAIPS_NEWFILENAME = ""; $TFAIPS_NUMBER = 0; $TFAIPS_PACKNUMBER = 0; 
                             $TFAIPS_CPYFIL = 0; }
  elsif ( $TFAIPS_ADDINCLAST ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); 
                                 $TFAIPS_ADRCICOMMAND = ""; $TFAIPS_NUMBER = 0; $TFAIPS_PACKNUMBER = 0; 
                                 $TFAIPS_ADDINCLAST = 0; }
  elsif ( $TFAIPS_DELPKG ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); $TFAIPS_ADRCICOMMAND = "";
                             $TFAIPS_PACKNUMBER = 0; $TFAIPS_DELPKG = 0; }
  elsif ( $TFAIPS_GETMANIFEST ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); 
                                  $TFAIPS_ADRCICOMMAND = ""; $TFAIPS_FILENAME = ""; 
                                  $TFAIPS_GETMANIFEST = 0; }
  elsif ( $TFAIPS_GETMETADATA ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); 
                                  $TFAIPS_ADRCICOMMAND = ""; $TFAIPS_FILENAME = ""; 
                                  $TFAIPS_GETMETADATA = 0; }
  elsif ( $TFAIPS_SETBASE ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); $TFAIPS_ADRCICOMMAND = "";
                              $TFAIPS_FILEPATH = ""; $TFAIPS_SETBASE = 0; }
  elsif ( $TFAIPS_SETHOMEPATH  ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); 
                                   $TFAIPS_ADRCICOMMAND = ""; $TFAIPS_FILEPATH = ""; 
                                   $TFAIPS_SETHOMEPATH = 0; }
  elsif ( $TFAIPS_SHOWFILES  ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); $TFAIPS_ADRCICOMMAND = "";
                                 $TFAIPS_PACKNUMBER = 0; $TFAIPS_SHOWFILES = 0; }
  elsif ( $TFAIPS_SHOWOPER  ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); $TFAIPS_ADRCICOMMAND = "";
                                $TFAIPS_OPERATION = ""; $TFAIPS_PACKNUMBER = 0; $TFAIPS_SHOWOPER = 0; }
  elsif ( $TFAIPS_SHOWCONFIG  ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); $TFAIPS_ADRCICOMMAND = "";
                                $TFAIPS_PACKNUMBER = 0; $TFAIPS_SHOWCONFIG = 0; }
  elsif ( $TFAIPS_SHOWPKG ) { $retval = tfactlshare_call_adrci($TFAIPS_ADRCICOMMAND,$TFAIPS_SILENT); $TFAIPS_ADRCICOMMAND = "";
                              $TFAIPS_PACKNUMBER = 0; $TFAIPS_SHOWPKG = 0; }
 $TFAIPS_SILENT = "no";

 return $retval;
}


########
# NAME
#   tfactlips_process_help
#
# DESCRIPTION
#   This function is the help function for the tfactlips module.
#
# PARAMETERS
#   command     (IN) - display the help message for this command.
#
# RETURNS
#   1 if command found; 0 otherwise.
#
# NOTES
#   process help ips <topic> commands
#           ips <topic> -h/-help commands
#
########
sub tfactlips_process_help 
{
  my ($command) = lc(shift);       # User-specified argument; show help on $cmd. #
  my $switch_val;
  #print "command $command from tfactlips_process_help \n\n";

  my ($desc);                                # Command description for $cmd. #
  my ($succ) = 0;                         # 1 if command found, 0 otherwise. #

  if (tfactlips_is_cmd ($command)) 
  {                              # User specified a command name to look up. #
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_process_help " .
                      "command $command", 'y', 'y');
    tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_process_help " .
                      "tfactlglobal_help_argv @tfactlglobal_help_argv", 'y', 'y');
    $switch_val = tfactlshare_parse_command( 'hlp', @tfactlglobal_help_argv);
    $desc = tfactlshare_get_help_message($command, $switch_val);

    #$desc = tfactlshare_get_help_desc($command);
    #tfactlshare_print "$desc\n";

    # Review command
    # print "switch val ips $switch_val \n";
    $succ = 1;
    print $desc;
  }

  return $succ;
}

########
# NAME
#   tfactlips_is_cmd
#
# DESCRIPTION
#   This routine checks if a user-entered command is one of the known
#   TFACTL internal commands that belong to the tfactlips module.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is one of the known commands, false otherwise.
########
sub tfactlips_is_cmd 
{
  my ($arg) = shift;

  return defined ($tfactlips_cmds {$arg});

}

########
# NAME
#   tfactlips_is_wildcard_cmd
#
# DESCRIPTION
#   This routine determines if an tfactlips command allows the use 
#   of wild cards.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is a command that can take wildcards as part of its argument, 
#   false otherwise.
########
sub tfactlips_is_wildcard_cmd 
{
  my ($arg) = shift;

  return defined ($tfactlips_cmds{ $arg }) &&
    (tfactlshare_get_cmd_wildcard($arg) eq "True" ) ;
}

########
# NAME
#   tfactlips_is_no_instance_cmd
#
# DESCRIPTION
#   This routine determines if a command can run without an TFAMain instance.
#
# PARAMETERS
#   arg   (IN) - user-entered command name string.
#
# RETURNS
#   True if $arg is a command that can run without an TFAMain instance 
#   or does not exist, false otherwise.
#
# NOTES
#   The tfactlips module currently supports no command that can run 
#   without an TFAMain instance.
########
sub tfactlips_is_no_instance_cmd 
{
  my ($arg) = shift;

  return !defined ($tfactlips_cmds{ $arg }) ||
    (tfactlshare_get_cmd_noinst($arg) ne "True" ) ;
}

########
# NAME
#   tfactlips_syntax_error
#
# DESCRIPTION
#   This function prints the correct syntax for a command to STDERR, used 
#   when there is a syntax error.  This function is responsible for 
#   only tfactlips commands.
#
# PARAMETERS
#   cmd   (IN) - user-entered command name string.
#
# RETURNS
#   1 if the command belongs to this module; 0 if command not found.
#
# NOTES
#   These errors are user-errors and not internal errors.  They are of type
#   record, not signal.  
# 
#   N.B. Functions in this module can call this function directly, without
#   calling the tfactlshare::tfactlshare_syntax_error equivalent.  The
#   latter is used only by the tfactl module.
########
sub tfactlips_syntax_error 
{
  my ($cmd) = shift;
  my ($cmd_syntax);                               # Correct syntax for $cmd. #
  my ($succ) = 0;


  #display syntax only for commands in this module.
  if (tfactlips_is_cmd($cmd))
  {
    tfactlshare_get_help_syntax($cmd);
    $succ = 1;

    if ($tfactlglobal_hash{'mode'} eq 'n')
    {
      $tfactlglobal_hash{'e'} = -1;
    }
  }

  return $succ;
}

########
# NAME
#   tfactlips_get_tfactl_cmds
#
# DESCRIPTION
#   This routine constructs a string that contains a list of the names of all 
#   TFACTL internal commands and returns this string.
#
# PARAMETERS
#   None.
#
# RETURNS
#   A string contain a list of the names of all TFACTL internal commands.
#
# NOTES
#   Used by the help command and by the error command when the user enters
#   an invalid internal command.
#
#   IMPORTANT: the commands names must be preceded by eight (8) spaces of
#              indention!  This formatting is mandatory.
########
sub tfactlips_get_tfactl_cmds 
{
  return tfactlshare_filter_invisible_cmds(%tfactlips_cmds);
}

#######
# NAME
#   tfactlips_add_adrbase
#
# DESCRIPTION
#   This routine adds a custom ADR basepath to the local node.
#
# PARAMETERS
#   $custompath - ADR basepath
#
# RETURNS
#   None
#
# NOTES
########
sub tfactlips_add_adrbase {
  my $custompath = shift;
  my $tfa_setup = tfactlshare_getSetupFilePath($tfa_home);
  my @hpaths;

  tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_add_adrbase " .
                    "custompath $custompath", 'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_add_adrbase " .
                    "tfasetup   $tfa_setup", 'y', 'y');
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_add_adrbase " .
                    "tfa_home   $tfa_home", 'y', 'y');

  tfactlshare_get_oracle_homes($tfa_home);
  tfactlshare_trace(5, "tfactl (PID = $$) tfactlips tfactlips_add_adrbase " .
                    "Oracle homes @tfactlglobal_oracle_homes", 'y', 'y');

  # Validate that the path exist
  if ( not -d $custompath ) {
    print "Custom path $custompath does not exist.\n";
    print "Please provide a valid path.\n";
    return;
  }

  # Check if any ORACLE_HOME is available
  if ( not @tfactlglobal_oracle_homes ) {
    print "No Oracle Homes were discovered.\n";
    print "Custom path $custompath cannot be validated.\n";
    return;
  }

  # Validate that the path is a valid ADR basepath
  @hpaths = tfactlshare_get_homepaths($tfactlglobal_oracle_homes[0],$custompath);
  if ( not @hpaths ) {
    print "Custom path $custompath cannot be added.\n";
    print "No homepaths available in the specified custom path.\n";
    return;
  }

  # Validate w permission over tfa_setup file
  if ( not -w $tfa_setup ) {
    print "Custom path $custompath cannot be added.\n";
    print "No write permission to the file $tfa_setup.\n";
    return;
  }

  # validate that the custompath entry does not already exists in tfa_setup
  open(FH, '<', $tfa_setup) or die "Could not open file '$tfa_setup' $!";
  while (<FH>) {
    # print $_;
    if ( $_ =~ /localnode\%ADRBASE\=$custompath$/ ) {
      print "Custom path $custompath aready exists in tfa_setup file.\n";
      return;
    }
  }

  # Add entry to tfa_setup
  open(my $fh, '>>', $tfa_setup) or die "Could not open file '$tfa_setup' $!";
  print $fh "localnode%ADRBASE=$custompath\n";
  close $fh;

  print "Custom path $custompath was added successfully to tfa_setup file.\n";

  return;
}
