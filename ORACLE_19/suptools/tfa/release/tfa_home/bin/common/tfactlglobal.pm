# 
# $Header: tfa/src/v2/tfa_home/bin/common/tfactlglobal.pm /st_tfa_19/1 2018/09/20 13:22:40 bburton Exp $
#
# tfactlglobal.pm
# 
# Copyright (c) 2014, 2018, Oracle and/or its affiliates. All rights reserved.
#
#    NAME
#      tfactlglobal - TFA Global Memory Module
#
#    DESCRIPTION
#      TFACTL - Trace File Analyzer Control Utility 
#
#      This module contains the global configuration variables for the
#      modular setup of TFACTL.  Each TFACTL module defines a number of
#      callback functions that are used by the driver module, tfactl.
#      References to these callback functions are stored in the global
#      variables of this module.
#
#    NOTES
#      usage: tfactl [-verbose {errors|warnings|normal|info|debug|none}] [command]
#
#      Whenever a new module of TFACTL commands is added to TFACTL,
#      global arrays in this module needs to be updated with 
#      callback definitions for these functions:
#        1) Entrance function to call all module-specific commands
#             tfactl<module>_process_cmd
#        2) Function to list help messages for module-specific commands
#             tfactl<module>_process_help
#        3) Function to list all available commands for a module
#             tfactl<module>_get_tfactl_cmds
#        4) Function to determine if a given command is one supported
#           by the module
#             tfactl<module>_is_cmd
#        5) Function to determine if a given command supports the use
#           of wildcard characters in its path argument(s).
#             tfactl<module>_is_wildcard_cmd
#        6) Function to display the correct syntax for a command within
#           the module
#             tfactl<module>_syntax_error
#        7) Function to determine if a given command can run without
#           a TFA instance available.
#             tfactl<module>_is_no_instance_cmd
#
#      These arrays should be updated by the means of a module
#      initialization function, which is defined within each module and
#      referenced in the tfactl:tfactl_init_modules array.
#
#      Here is the modular layout of TFACTL:
#
#                                 tfactl
#                                    |
#                                    v
#                                 tfactl.pl
#                                    |
#                                    v
#        ____________________________________________________________
#        |         |            |            |             |        |
#        |         v            v            v             v        v
#        |     tfactlbase   tfactlmod01 tfactl<modN> tfactltemplate*|
#        |         |            |            |             |        |
#        |         |____________|____________|_____________|        |
#        |                                   |                      |
#        |                                   |______________________|
#        |                                   |
#        |                                   v
#        |                              tfactlshare
#        |                                   |
#        v                                   v
#        |___________________________________|
#                                            |
#                                            v
#                                       tfactlglobal
#
#      N.B. tfactltemplate* represents any new module to be added.  Based
#      on this modular model, we have these restrictions:
#        1) tfactlglobal should never use any of the other modules.
#        2) tfactlshare can use only tfactlglobal.
#        3) No module can use tfactl.
#        4) The tfactltempate* modules must not use each other, e.g.
#           tfactlmod01 cannot use tfactlbase.
#
#    MODIFIED   (MM/DD/YY)
#    bburton     09/19/18 - Add updateciphersuite
#    cnagur      08/14/18 - ADW Upload Changes
#    recornej    08/06/18 - Change SUCCESS and FAILED values.
#    manuegar    08/05/18 - XbranchMerge manuegar_dbutils16 from main
#    recornej    08/03/18 - Add tfactlglobal_dbversions hash
#    manuegar    07/31/18 - manuegar_dbutils16.
#    manuegar    07/10/18 - Bug 28250972 - OGG:SHD:TFACTL DIAGCOLLECT FAILS W/
#                           CAN'T CREATE..COMMON/TFACTLSHARE.PM LINE.
#    bburton     07/10/18 - fix build issue
#    manuegar    07/06/18 - manuegar_dbutils14.
#    bburton     07/05/18 - Add supported DB version Array - bug 27889149
#    bibsahoo    07/03/18 - FIX BUG 28095265
#    recornej    06/25/18 - Removing IS_OFFLINEMODE
#    gadiga      06/25/18 - add atp config
#    bburton     06/20/18 - add more valid set commands
#    manuegar    06/20/18 - manuegar_dbutils13_handlers.
#    cnagur      06/13/18 - Export tfactlglobal_getCommandLocation
#    cnagur      06/05/18 - Updated tfactlglobal_getCommandLocation
#    recornej    06/02/18 - Adding IS_OFFLINEMODE
#    manuegar    05/30/18 - manuegar_shared_dbutils12.
#    manuegar    05/18/18 - manuegar_shared_dbutils10.
#    manuegar    05/17/18 - manuegar_adrbasechk.
#    recornej    05/07/18 - Adding max hours and max days global variables.
#    manuegar    04/24/18 - Bug 27669677 - TFAT: INSTALLING TFA -JAVAHOME IS
#                           IGNORED.
#    recornej    04/19/18 - Adding SETUPSUDOCMDS
#    manuegar    04/18/18 - Bug 27879372 - LNX-191-TFA:OFTEN HIT "MASTER
#                           PACKAGE TIMED OUT FOR ADR HOMEPATH" DURING DIAGCOL.
#    manuegar    04/17/18 - XbranchMerge manuegar_oratopfx from
#                           st_tfa_pt-quarterly.12.2.1.2.0
#    recornej    03/14/18 - Adding tfactlglobal_tfa_dbutlresources
#    manuegar    03/13/18 - manuegar_shared_dbutils04.
#    recornej    03/07/18 - Adding ; to pwd to prevent pwd permission denied in
#                           AIX
#    bibsahoo    02/15/18 - Adding hash to map month numbers to month name
#		            removed from here and added to dateutils.pm
#    migmoren    02/13/18 - Adding global variables: IS_AIX, IS_HPUX
#    manuegar    02/01/18 - manuegar_shared_dbutils01.
#    recornej    01/26/18 - Adding $GREP
#    manuegar    01/08/18 - manuegar_shared_dbutils01.
#    recornej    12/15/17 - Adding tfactlglobal_jsonMap
#    recornej    12/06/17 - Adding JSONParser regular expresions.
#    manuegar    12/02/17 - manuegar_shared_dbutils.
#    recornej    11/29/17 - Adding XMLFILTER_REQUIRED
#    recornej    11/27/17 - Adding XMLFILTER_MSG.
#    manuegar    11/17/17 - manuegar_oratopfx.
#    recornej    11/07/17 - Add XMLHEADER regex.
#    cnagur      10/30/17 - Added SSH
#    manuegar    10/25/17 - manuegar_summary_basrep.
#    recornej    10/23/17 - Adding | to attributes xml regex
#    recornej    10/20/17 - Added + for XMLATTRIBUTES pattern matching in xml parser.
#    recornej    10/02/17 - Added ^,$ to xmlattributes to support pattern matching.
#    recornej    10/02/17 - Added @ missing in XMLCONTENT
#    bburton     10/03/17 - Add Age Warning
#    bibsahoo    09/26/17 - FIX BUG 26817718
#    manuegar    09/20/17 - manuegar_ips_diff.
#    manuegar    09/11/17 - manuegar_bug-26619915.
#    bibsahoo    09/06/17 - FIX BUG 26414175
#    manuegar    08/25/17 - manuegar_pmap_disc.
#    manuegar    08/24/17 - Bug 26474385 - SOLSP64-181-TFA: TFACTL DIAGCOLLECT
#                           ALL WILL HUNG.
#    manuegar    08/16/17 - Bug 26638658 - LNX64-12.2-TFA:TFA-00404 XML FILE IS
#                           NOT WELL FORMED WHEN RUNNING -SRDC DBPERF.
#    manuegar    07/28/17 - manuegar-srdc_xmlparser.
#    bburton     07/24/17 - Add globals for xmlfilter depinput and pattern
#    manuegar    07/24/17 - manuegar_srdc_xmlparser.
#    manuegar    07/14/17 - Bug 25913670 - LNX64-12.2-TFA:PLS REMOVE MSG OF
#                           BUNDLED TOOLS FROM HELP.
#    llakkana    07/03/17 - upload to SR support
#    cnagur      06/29/17 - Fix for Bug 26309164
#    manuegar    06/23/17 - Bug 26225219 - LNX64-12.2-TFA: TFACTL DIAGCOLLECT
#                           ALL HUNG MORE THAN ONE HOUR.
#    cnagur      05/24/17 - Fix for Bug 24971982
#    cpujar      05/19/17 - XbranchMerge cpujar_bug-26090405 from
#                           st_tfa_12.2.1.1.01
#    cpujar      05/17/17 - Summary bug 26090405
#    recornej    05/16/17 - Bug 26035086 - TFA NON-DAEMON MODE : TFACTL
#                           DIAGCOLLECT -IPS -INCIDENT HANGS
#    recornej    04/27/17 - Adding IS_ZDLRA global variable
#    bburton     04/07/17 - Add XMLFILTER_VALIDATE
#    recornej    04/05/17 - XML Match pattern constants.
#    manuegar    03/23/17 - emsrdc01
#    bibsahoo    03/22/17 - DBGlevel Support For Windows
#    manuegar    02/23/17 - Bug 25605875 - WS2012_122_TFA: TFACTL IPS
#                           <IPS_COMMAND> RETURNS TFA-00207.
#    cnagur      02/13/17 - Non-Root Daemon Changes
#    manuegar    01/24/17 - EM SRDC.
#    manuegar    01/06/17 - Bug 25208337 - LNX64-12.2-TFA: DID NOT COLLECT IPS
#                           PACKAGE,ORACLE_HOME ENV VARIABLE NOT SET.
#    cpujar      12/13/16 - Added set jvmXmxMB
#    cnagur      11/21/16 - Added Error Message for 208
#    bburton     11/07/16 - Add srdclog
#    cnagur      11/03/16 - Fix for Bug 25039956 and 25039605
#    manuegar    10/27/16 - manuegar_srdc_14.
#    manuegar    10/25/16 - manuegar_extract_tfa_03. Added -setup to support
#                           first time ND configuration.
#    bibsahoo    10/14/16 - tfa windows bugs
#    manuegar    09/28/16 - Bug 24740735 - WS2012_122_TFA: TFACTL DIAGCOLLECT
#                           FAILED WITH OPTION -SILENT.
#    manuegar    09/23/16 - Support ips add adrbase <adrbasepath>.
#    bburton     09/22/16 - changes for odalite
#    manuegar    09/05/16 - Support the -extractto switch in the TFA installer.
#    arupadhy    07/07/16 - Added LS equivalent for windows
#    cnagur      07/07/16 - Removed ADE_ND_RUN
#    manuegar    06/29/16 - Bug 23701024 - LNX64-12.2-TFA: MAY NOT COLLECT LOG
#                           WHEN S/W ONLY GI HOME CO-EXISTS W/ ACTIVE GI.
#    arupadhy    06/24/16 - Added TMP, CAT, support tools list which are
#                           enabled for windows. removed win:ole as it was
#                           interfering with perl child processes created
#                           through fork
#    manuegar    06/13/16 - Dynamic help part 3.
#    manuegar    06/08/16 - Handle no adr basepaths for TFA IPS.
#    cnagur      06/02/16 - Added ISFMW
#    amchaura    05/30/16 - configurable collection wait time for diagcollect
#                           log creation
#    cnagur      05/27/16 - XbranchMerge cnagur_tfa_121260_cell_issues_txn from
#                           st_tfa_12.1.2.6
#    manuegar    05/25/16 - Support silent mode in srdc.
#    amchaura    05/16/16 - Fix Bug 19133987 - LNX64-12.1-TFA-SCS:DID NOT
#                           INCLUDE THE NEW DB LOG LOCATION INTO REDISCOVER DIR
#    cnagur      04/15/16 - Fix for Bug 23112233
#    manuegar    04/14/16 - Bug 23082552 - SOLSP-12.2-TFA:TFACTL DIAGCOLLECT
#                           HIT MANY SHELL-INIT:ERROR RETRIEVING CWD:GETCW.
#    manuegar    03/31/16 - Performance improvement for tfactl.
#    amchaura    03/28/16 - configurable deafult collection time range
#    manuegar    03/25/16 - Dynamic help.
#    manuegar    03/16/16 - Bug 22907263 - LNX64-12.2-TFA-MSG: HIT "ERROR: 13:
#                           PERMISSION DENIEDADDITIONAL INFORMATION: 1".
#    manuegar    03/14/16 - Fix diag directories for non root users.
#    manuegar    03/07/16 - Run TFA Ips collections as ADR homepath owner.
#    manuegar    03/02/16 - Bug 21886221 - [12201-LIN64-TFA]OUTPUT OF PRINT
#                           DIRECTORIES IS NOT FRIENDLY.
#    sgoggi      02/17/16 - Added koption
#    manuegar    02/05/16 - Support ips collections on windows.
#    cnagur      02/02/16 - Added SI_REL_DIR - Bug 22647922
#    manuegar    01/28/16 - Bug 22601081 - LNX64-12.2-TFA:TFA ACCESS ACCOUNTS
#                           ARE NOT BEING CREATED PROPERLY.
#    bburton     01/26/16 - write debug on install to logfile
#    manuegar    01/26/16 - Add hidden diagcollect switch to control all_files
#                           IPS flag.
#    arupadhy    01/22/16 - Added fixtfadiagnostics
#    sgoggi      01/20/16 - support processbug
#    bburton     01/19/16 - Add RACDBCLOUD
#    arupadhy    01/17/16 - support for non root windows user
#    manuegar    01/14/16 - TFA IPS Windows porting.
#    manuegar    12/18/15 - Support ADR paths containing special chars.
#    amchaura    12/14/15 - 22315724 CONFIGURABLE MINIMUM SECURITY LEVEL FOR
#                           TFA
#    manuegar    12/14/15 - Added pool for TFA IPS Parallel Processing.
#    arupadhy    12/07/15 - Setting PROFILING_ON as off for windows for time
#                           being, as it requires shell script conversion
#    manuegar    12/07/15 - Bug 21648528 - LNX64-12.2-TFA-IPS:IPS PACK DID NOT
#                           WORK.
#    amchaura    12/03/15 - Fix Bug 22285015 - TFA : UNABLE TO SET REQUIRED
#                           TRACELEVEL
#    manuegar    11/29/15 - Bug 22283193 - LNX64-12.2-TFA-IPS: ALLOW TFA IPS
#                           PACKAGE MANIPULATION FEATURE.
#    sgoggi      11/23/15 - pluginadd
#    manuegar    10/26/15 - Bug 22077161 - TFA: INCIDENT BASED DIAGCOLLECTION
#                           FROM DEFAULT $ORACLE_HOME/DIAG DIR.
#    amchaura    10/22/15 - Fix Bug 21982899 - LNX64-12.2-TFA:COLLECTION
#                           FAILED, COULD NOT READ DIAGCOLLECT LOG
#    arupadhy    10/16/15 - tput command does not work for windows, setting
#                           default width for windows tables
#    amchaura    10/13/15 - Fix Bug 20608487 - DIAG : TFA : ER : TFACTL PRINT
#                           DIRECTORIES BASED ON COMPONENTS
#    gadiga      10/01/15 - error messages for stopped
#    gadiga      09/24/15 - receiver errors
#    cnagur      09/23/15 - XbranchMerge cnagur_tfa_jcs_support_txn from
#                           st_tfa_12.1.2.5
#    gadiga      09/20/15 - MANAGE_RECEIVER
#    arupadhy    09/11/15 - Added IS_WINDOWS, MKDIR, MV, RM for windows
#    sgoggi      09/07/15 - Bug# 21546218 - LNX64-12.2-TFA:COLLECTOR WAS NOT ABLE TO ADD RECEIVERS
#    amchaura    09/02/15 - BUG 21172410 - TFACTL PRINT ACTIONS NEEDS OPTION
#                           FOR LISTING COLLECTIONS -SINCE
#    manuegar    08/27/15 - Bug 21643708 - LNX64-12.2-TFA-IPS:IPS WAS NOT ABLE
#                           TO SHOW AND COLLECT PKGS IN ANOTHER ADRBASE.
#    bibsahoo    08/23/15 - Adding Global Error Code 103
#    arupadhy    08/20/15 - added code for global variable DEVNULL, TOUCH
#                           condition for windows
#    manuegar    08/06/15 - Bug 21552238 - LNX64-12.2-TFA-IPS:IPS ADD INCIDENT
#                           DID NOT WORK.
#    manuegar    07/21/15 - Bug 21461623 - TRACE AND ALERT FILES FOR TFACTL
#                           HAVE READ WORLD PERMISSION.
#    cnagur      08/26/15 - Support for JCS
#    gadiga      07/21/15 - parseevents
#    manuegar    07/10/15 - Bug 21426172 - TFA: PROBLEM / PROBLEM KEY BASED TFA
#                           DIAGCOLLECT.
#    manuegar    07/03/15 - Bug 21221209 - LNX64-12.2-TFA:IPS SHOW
#                           CONFIGURATION DID NOT WORK AS EXPECTED.
#    manuegar    06/22/15 - Bug 21261716 - TFA: INCIDENT BASED TFA DIAGCOLLECT.
#    manuegar    06/16/15 - Define default IPS collection and support -noips
#                           switch.
#    gadiga      06/09/15 - XbranchMerge gadiga_tfa_in_dbaas_12124 from
#                           st_tfa_12.1.2.4
#    manuegar    05/26/15 - TFA/Ips collection Logic 2.
#    cnagur      05/22/15 - Copy Files using Tags
#    bburton     05/11/15 - Fix bug for upgrading tfa_directories.txt
#    manuegar    05/04/15 - Validate the default attribute for the subcomponent
#                           element.
#    manuegar    05/04/15 - Add a filter to "print components" option.
#    manuegar    04/27/15 - Modular tracing.
#    manuegar    04/15/15 - Bug 20351399 - LNX64-12.2-TFA-FCS:DIAGCOLLECT HELP
#                           MESSAGE NEED DESCRIPTIONS FOR NEW OPTIONS.
#    cnagur      03/30/15 - Fix for Bug 20796717
#    gadiga      03/30/15 - windows
#    manuegar    02/13/15 - Support additional tags for components.xml
#    gadiga      05/04/15 - SR upload
#    manuegar    04/15/15 - Bug 20351399 - LNX64-12.2-TFA-FCS:DIAGCOLLECT HELP
#                           MESSAGE NEED DESCRIPTIONS FOR NEW OPTIONS.
#    gadiga      03/30/15 - windows
#    manuegar    02/13/15 - Support additional tags for components.xml
#    gadiga      01/23/15 - add time
#    amchaura    01/19/15 - 20380630 - TFA SUPPORT FOR EXADATA VM/DOM0
#    cnagur      01/07/15 - Added UPDATEAUTODIAGCOLLECT
#    cnagur      12/17/14 - Added UPGRADESTATUS
#    cnagur      12/16/14 - Added NODE_TYPE
#    gadiga      12/15/14 - add editor to context
#    gadiga      12/12/14 - declare STOPSUPTOOLS
#    manuegar    12/11/14 - Ips collection logic
#    gadiga      12/11/14 - stopsuptools
#    manuegar    12/08/14 - 20176397, Support new commands for TFA-IPS integration
#    cnagur      11/23/14 - Fix for Bug 19985667
#    gadiga      11/21/14 - context
#    manuegar    11/05/14 - Implement <action> <toolname> <flags> for support
#                           tools.
#    manuegar    10/22/14 - Additional functionality for xmlparser.
#    manuegar    10/15/14 - Handle dynamic components.
#    cnagur      10/14/14 - Added FORCE
#    manuegar    10/03/14 - tfa external tools support
#    llakkana    09/25/14 - View files of local/remote node
#    manuegar    09/24/14 - Add support for xml parsing.
#    cnagur      09/15/14 - Added UPDATEACCESS - Bug 19607799
#    amchaura    09/12/14 - Fix 19585579 - HPI_12102_TFA:TFACTL NOT COLLECT CRS
#                           LOGS WHEN RUNNING TFACTL DIAGCOLLECT -ALL
#    cnagur      09/02/14 - Added UPDATEPROPERTIESFILE
#    amchaura    08/27/14 - Fix 18296461 LNX64-12.1-TFA-SCS:NEED A WAY TO INTERRUPT RUNNING DIAGNOSTIC COLLECTIONS
#    cnagur      08/26/14 - Added maxCoreFileSize and maxCoreCollectionSize
#    manuegar    08/12/14 - tfa/ips integration
#    manuegar    07/22/14 - Relocate tfactl_lib
#    manuegar    06/30/14 - Creation
#
#############################################################################

package tfactlglobal;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(%tfactlglobal_hash
		 tfactlglobal_getCommandLocation
                 %tfactlglobal_mod_levels
                 %tfactlglobal_cmds
                 %tfactlglobal_options
                 %tfactlglobal_deprecated_options
                 %tfactlglobal_error_message
                 %tfactlglobal_commands
                 %tfactlglobal_help_commands
                 %tfactlglobal_help_messages
                 %tfactlglobal_set_commands
                 %tfactlglobal_jsonMap
                 %tfactlglobal_versionsMap 
                 @tfactlglobal_command_callbacks
                 @tfactlglobal_help_callbacks
                 @tfactlglobal_command_list_callbacks
                 @tfactlglobal_is_command_callbacks
                 @tfactlglobal_is_wildcard_callbacks
                 @tfactlglobal_syntax_error_callbacks
                 @tfactlglobal_no_instance_callbacks
                 @tfactlglobal_error_message_callbacks
                 @tfactlglobal_signal_exception_callbacks
                 @tfactlglobal_argv
                 @tfactlglobal_help_argv
                 @tfactlglobal_oracle_homes
                 %tfactlglobal_oracle_homes_adrciversion
                 @tfactlglobal_adr_homes
                 %tfactlglobal_adrbaseselected
                 @xmlcompsarray
                 @validatexmlcompsarray
                 @retcomparray
                 $tfactlglobal_dbversions
                 $TFACTLGLOBAL_WCARD_CHARS
                 $tfactlglobal_trace_path
                 $tfactlglobal_log_path
                 $tfactlglobal_alert_path
                 $tfactlglobal_diag_base
                 $tfactlglobal_components_file
                 $tfactlglobal_tfa_ext_xml
                 %tfactlglobal_tfa_dbutlcommands
                 $tfactlglobal_tfa_dbutlcmds
                 @tfactlglobal_tfa_dbutlschedarr
                 $tfactlglobal_tfa_dbutlsched
                 $tfactlglobal_tfa_dbutlresources
                 %tfactlglobal_exttools
                 %tfactlglobal_exttools_categories
                 %tfactlglobal_xmlcompshash
                 %tfactlglobal_usersxmlcompshash
                 %tfactlglobal_adrbasepaths
                 %tfactlglobal_ctx
                 %tfactlglobal_ctx_commands
                 %tfactlglobal_srdc
                 $tfactlglobal_clsecho
                 $tfactlglobal_product
                 $tfactlglobal_facility
                 $tfactlglobal_maxub4
                 MARKED
                 UNMARKED
                 PREVCMD
                 NXTCMD
                 COMPCMD
                 MORECMD
                 RETCMD
                 HLPCMD
                 HLPMSG
                 XMLARRLEVEL
                 XMLARRTAG
                 XMLARRTAGMODE
                 XMLLINENUM
                 $XMLTAGCLOSE
                 $XMLTAGOPEN
                 $XMLCONTENT
                 $XMLCDATAOPEN
                 $XMLCDATACONTENT
                 $XMLCDATACLOSE
                 $XMLATTRIBUTES
                 $XMLTAGOPENATTRIBUTES
                 $XMLTAGOPENCLOSE
                 $XMLTAGOPENATTRIBUTESCLOSE
                 $XMLCOMMENTOPEN
                 $XMLCOMMENTCLOSE
                 $XMLCOMMENTCONTENT
                 $XMLEMPTYLINE
                 $XMLHEADER
                 $JSONSTR
                 $JSONNUM
                 $JSONOPENOBJ
                 $JSONCLOSEOBJ
                 $JSONOPENARR
                 $JSONCLOSEARR
                 $JSONCOLON
                 $JSONCOMMA
                 $JSONNULL
                 $JSONTRUE
                 $JSONFALSE
                 $JSONEOF
                 ELEMNAME
                 ELEMVAL
                 ELEMVALTYPE
                 ELEMNDX
                 ELEMLEVEL
                 ELEMATTRNAME
                 ELEMATTRVAL
                 COMPNAME
                 COMPVALIDATE
                 COMPALTNAME
                 COMPDESCRIPTION
                 COMPINSTANCEHOME
                 COMPTYPE
                 COMPSUB
                 COMPCONFIG
                 COMPSCRIPTS
                 COMPALSO
                 COMPSCRIPTNAME
                 COMPSCRIPTRUSER
                 COMPSCRIPTINT
                 COMPSCRIPTPARAMS
                 SUBCOMPVALUE
                 SUBCOMPIDX
                 SUBCOMPNAME
                 SUBCOMPREQUIRED
                 SUBCOMPDEFAULT
                 SUBCOMPVALSNODE
                 SUBCOMPVALSCOMP
                 SUBCOMPVALSKVHASH
                 VALIDATECOMP
                 VALIDATESUBCOMPIDX
                 VALIDATESUBCOMPNAME
                 VALIDATESUBCOMPREQUIRED
                 VALIDATESUBCOMPDEFAULT
                 COMPVALIDSUBNAME
                 COMPVALIDSUBVALUE
                 RETCOMPNAME
                 RETCOMPTYPE
                 RETCOMPCONFIG
                 MFILE_NAME
                 MLOCATION
                 MSIZE
                 MINCIDENT_ID
                 MADR_BASE
                 MADR_HOME
                 MPACKAGE_ID
                 TFAUSER_HOST
                 TFAUSER_NAME
                 TFAUSER_TYPE
                 TFAUSER_ALLOWED
                 XMLFILTER_CMDLINE
                 XMLFILTER_DEFAULT
                 XMLFILTER_VALIDFOR
                 XMLFILTER_VALIDATE
                 XMLFILTER_SHOWPROMPT
                 XMLFILTER_SETENV
                 XMLFILTER_PROMPT
                 XMLFILTER_DEPINPUT
                 XMLFILTER_DEPPATTERN
                 XMLFILTER_MSG
                 XMLFILTER_REQUIRED
                 TFADBUTILS_CATEGORYID
                 TFADBUTILS_PARENTCMD
                 TFADBUTILS_COMMANDID
                 TFADBUTILS_KEYNAME
                 TFADBUTILS_CONTENT
                 TFADBUTILS_HANDLER
                 MAX_HOURS
                 MAX_DAYS
                 MAX_DSKUSG_MON_INT
                 MAX_AGE_PURGE
                 RETCOMPVALIDATE
                 $START
                 $STARTFROMINIT
                 $STOPFROMINIT
                 $SHUTDOWN
                 $ENABLE
                 $DISABLE
                 $STOP
                 $CHECK
                 $CHECKSTATUS
                 $CHECKAUTOPATCHING
                 $CHECKKEYSTORES
                 $COMMANDTOEXECUTE
                 $COMMANDTOEXECUTE_PRINT
                 $EXECUTEINHOST_PRINT
                 $PROGRAM_PRINT
                 $TNTPROP
                 $INVFILE
                 $EXECUTEINHOST
                 $SEARCH
                 $SEARCH_PAT
                 $TNT_VERBOSE
                 $TNT_TYPE
                 $TNT_OFILE
                 $TNT_FROM
                 $TNT_TO
                 $TNT_COMP
                 $TNT_TCASE
                 $A_RUN_CMD
                 $A_RUN_FLAGS
                 $CLEAN
                 $RUNINVENTORY
                 $RUNCELLINVENTORY
                 $RUNINVENTORYINCELLS
                 $RUNCELLODSCAN
                 $RUNODSCANINCELLS
                 $cell
                 $cells
                 $onlycell
                 $PRINTACTIONS
                 $PRINTCOOKIE
                 $PRINTTFAHOME
                 $PRINTWALLETPASSWORD
                 $PRINTCELLS
                 $PRINTONLINECELLS
                 $PRINTBUILDVERSION
                 $PRINTONGOINGCOLL
                 $COPYTFACTL
                 $UPDATEAUTODIAGCOLLECT
                 $UPDATECIPHERSUITE
                 $UPDATEPROPERTIESFILE
                 $UPDATEDIRECTORIESFILE
                 $FIXTFACTL
                 $FIXTFADIAGNOSTICS
                 $UPLOAD
                 @UPLOAD_FLAGS
                 $SETUPMOS
                 $FIXINITTFA
                 $SETUPND
                 $SETUPND_JAVAHOME
                 $CREATETFASETUP
                 $UPDATEJDKINTFASETUP
                 $RECREATEFILEENTITIESINBDB
                 $CREATETFADIRECTORIES
                 $PRINTTFALOG
                 $PRINTDIRS
                 $CHANGEREPO
                 $PRINTREPO
                 $PRINTRUNMODE
                 $PRINTIPADDRESS
                 $PRINTCONFIG
                 $PRINTCOMPONENTS
                 $PRINTSUSPENDEDIPS
                 $PRINTINTERNALCONFIG
                 $PRINTEVENTS
                 $RUNTEST
                 $MANAGER
                 $CHANGEREPOSIZE
                 $CHANGEJVMMEMSIZE
                 $CHANGEJVMOTHER
                 $RESTARTTFA
                 $FORCE
                 $MAXLOGSIZE
                 $MAXLOGCOUNT
                 $maxCoreFileSize
                 $maxCoreCollectionSize
                 $PRINTHOSTS
                 $PRINTPROTOCOLS
                 $PRINTRECEIVERS
                 $PRINTCOLLECTORS
                 $PRINTROBJECTS
                 $PRINTIP 
                 $PRINTINVENTORY
                 $PRINTADRINCIDENTS
                 $PRINTSTARTUPS
                 $PRINTCMD
                 $PRINTSHUTDOWNS
                 $PRINTPARAMETERS
                 $PRINTERRORS
                 $PRINTCOLLECTIONS
                 $PRINTPROBLEMSETS
                 $CHECKVERSION
                 $UPGRADESTATUS
                 $UPGRADEVERSION
                 $GENERATECOOKIE
                 $SSLKEY
                 $GENCERTS
                 $SSLRESTART
                 $TEMP_TFAHOME
                 $TFA_JHOME
                 $PRINTINVRUNSTAT
                 $PRINTCELLINVRUNSTAT
                 $PRINTCELLDIAGSTAT
                 $CONFIGURECELLS
                 $CHECKFILETYPEXML
                 $ZIPFILESFORDATE
                 $RUNDIAGCOLLECT
                 $RUNDIAGCOLLECTCELL
                 $RUNDIAGCOLLECTINCELLS
                 $DIAGCOLLECT
                 $STOPCOLLECTION
                 $FILELISTDIRECTORY
                 $FILELISTLASTINV 
                 $STARTDATE
                 $ENDDATE
                 $OUTFILE
                 $RDMODE
                 $RDAUTO
                 $DELETEDB
                 $ADDDIR
                 $CHANGEDIR
                 $PERMISSION
                 $EXCLUSION
                 $ADDHOST
                 $RMHOST
                 $RMRECEIVER
                 $ADDDOM0IP
                 $RESTRICTPROTOCOL
                 $FORCERESTRICT
                 $RMDOM0IP
                 $RMDIR
                 $RUNDISC
                 $RUNREDISC
                 $CLUSTERWIDE
                 $SET_CMD_ARGS
                 $private_directory
                 $collect_all
                 $DSCRIPT_OPTS
                 $DSCRIPT_DEF
                 $DSCRIPT_RUNDEF
                 $DSCRIPT_NOIPS
                 $DSCRIPT_IPS
                 @DSCRIPT_COMP_CMDLINE
                 $COLLECTZIPS
                 $RUNSCAN
                 $DIR
                 $HOST
                 $SINCE
                 $FOR
                 $MODIFY
                 $SET_FLAG
                 $HELP
                 $silent
                 $node_list
                 $comp
                 $printdir_policy
                 $printdir_permission
                 $metadata
                 $action_status
                 $action_time
                 $event_time
                 $coll_time
                 $SENDUNINSTALLUPDATE
                 $STOPSUPTOOLS
                 $PARSEEVENTS
                 $PURGE
                 $purge_time
                 $CHECKFILEACCESS
                 $CHECKFILEACCESSUSINGSU
                 $INPUTFILE
                 $CELLREMWALLETPASS
                 $CELLREMWALLET
                 $CELLADDWALETPASS
                 $CELLPRINTCELLS
                 $CELLPRINTCONFIG
                 $CELLDECONFIG
                 $ISLOCAL
                 $SILENT
                 $SRDCSILENT
                 $NOMONITOR
                 $DEPLOYEXT
                 $RUNTOOL
                 $RUNTOOLCMD
                 $RUNTOOLCMDMODE
                 $UNINSTALL
                 $UNINSTALLARGS
                 $DIAGNOSETFA
                 $SENDMAIL
                 $LISTTFAUSERS
                 $TFAUSER
                 $TFACMT
                 $TFABUGSFTP
                 $TFABUG
                 $TFASR
                 $TFAUPLOAD
                 $SETUPTRACEDIR
                 $ADDDEFAULTUSERS
                 $ADDTFAUSER
                 $ADDTFAGROUP
                 $BLOCKTFAUSER
                 $BLOCKTFAGROUP
                 $UNBLOCKTFAUSER
                 $UNBLOCKTFAGROUP
                 $RESETTFAUSERS
                 $REMOVETFAUSER
                 $REMOVEALLUSERS
                 $RMUSERFROMGP
                 $ADDACCESS
                 $REMOVEACCESS
                 $UPDATEACCESS
                 $ACCESSLOCAL
                 $IS_NON_ROOT_DAEMON
                 $IS_TFA_ADMIN
                 $DAEMON_OWNER
                 $ISCLOUD
                 $ISJCS
                 $ISFMW
                 $SI_REL_DIR
                 $ADRCI
                 $ORABASE
                 $TFAIPS_PARROUT
                 $TFAIPS_NMBR
                 $TFAIPS_NUMBER
                 $TFAIPS_PACKNUMBER
                 $TFAIPS_PACKNAME
                 $TFAIPS_PRBKEY
                 $TFAIPS_STTIME
                 $TFAIPS_ENDTIME 
                 $TFAIPS_TIME
                 $TFAIPS_FILENAME
                 $TFAIPS_NEWFILENAME
                 $TFAIPS_FILEPATH
                 $TFAIPS_OPERATION
                 $TFAIPS_OVERWRITE
                 $TFAIPS_ADRBASE
                 $TFAIPS_ADRHOMEPATH
                 $TFAIPS_ADRHOMEPATH_MULTI
                 $TFAIPS_ADRCIHOMEPATH
                 $TFAIPS_ADRCIORACLEHOME
                 $TFAIPS_TARGETHOMEPATH
                 $TFAIPS_MULTIHOMEPATH 
                 $TFAIPS_LEFTCHK
                 $TFAIPS_OHOMESET
                 $TFAIPS_OHOME
                 $TFAIPS_CORRLVL
                 $TFAIPS_SHOWINC
                 $TFAIPS_SHOWPROB
                 $TFAIPS_SHOWHELP
                 $TFAIPS_CRTPKG
                 $TFAIPS_GENPKG
                 $TFAIPS_PACK
                 $TFAIPS_FINPKG
                 $TFAIPS_UNPFIL
                 $TFAIPS_ADDADRBASE
                 $TFAIPS_ADDINCLAST
                 $TFAIPS_ADDNEWINC
                 $TFAIPS_ADDREMFIL
                 $TFAIPS_ADDREMOPER
                 $TFAIPS_CPYFIL
                 $TFAIPS_DELPKG
                 $TFAIPS_GETMANIFEST
                 $TFAIPS_GETMETADATA
                 $TFAIPS_SETBASE
                 $TFAIPS_SETHOMEPATH
                 $TFAIPS_SHOWFILES
                 $TFAIPS_SHOWOPER
                 $TFAIPS_SHOWCONFIG
                 $TFAIPS_SHOWPKG
                 $TFAIPS_USEREMKEY
                 $TFAIPS_UNPPKG
                 $TFAIPS_UNPINTTFA
                 $TFAIPS_ADRCICOMMAND
                 $TFAIPS_SILENT
                 $TFAIPS_INCIDENTNMBR
                 $TFAIPS_PROBLEMNMBR
                 $TFAIPS_PROBLEMKEY
                 $TFAIPS_COLLECTIONDIR
                 $TFAIPS_COLLECTIONDIR_REL
                 $TFAIPS_COLLECTIONID
                 $TFAIPS_PURGEREMOTE
                 $TFAIPS_PACKTYPE
                 $TFAIPS_UNDO_ADRBASEPATH
                 $TFAIPS_UNDO_ADRHOMEPATH
                 $TFAIPS_ADETIMEOUT
                 $TFAIPS_NONADETIMEOUT
                 $TFAIPS_MAXTRIES
                 $TFAIPS_POOLSIZE
                 $TFAIPS_MINPOOLSIZE
                 $TFAIPS_MAXPOOLSIZE
                 $TFAIPS_KEYSEP
                 $TFAIPS_KEYMATCHER
                 $TFAIPS_KEYMATCHERSEP
                 $TFAIPS_ALLFILES
                 $TFAIPS_ALLFILESTXT
                 $TFAIPS_FILESEP
                 $OSSHELL
                 $CSH
                 $SRDCHLPSTRING
                 $EMAGENTOHOME
                 $EMAGENTIHOME
                 $EMOMSOHOME
                 $EMTARGETDBNAME
                 $EMTARGETASMINSTANCE
                 $EMREPOSITORYDBNAME
                 $EMREPOSITORYREPVFY
                 $EMREPOSITORYOHOME
                 $EMREPOSITORYTNS
                 $EMDBSNMPPWD
                 $EMSYSMANPWD
                 $DBUTILSSUMMARY
                 $DBUTILSSUMMARYNODES
                 $DBUTILSSUMMARYMODE
                 $DBUTILSAVL
                 $DBUTILSAVLCATID
                 $DBUTILSAVLCMDID
                 $DBUTILSAVLTZONE
                 $DBUTILSAVLSAMPLENOW
                 $DBUTILSAVLSAMPLENOWRESTYPE
                 $DBUTILSAVLSAMPLENOWKEYNAME
                 $DBUTILSAVLSAMPLENOWKEYVALUE
                 $DBUTILSAVLGENJSON
                 $DBUTILSAVLGENJSONCAT
                 $DBUTILSAVLGENJSONCMD
                 $ADDCOMPSTRING
                 $ADDCOMPHLPSTRING
                 $ADDCOMPHLPDESC
                 $ADDCOMPSTRING_EXADATA
                 $ADDCOMPHLPSTRING_EXADATA
                 $ADDCOMPHLPDESC_EXADATA
                 $ADDCOMPSTRING_ODA
                 $ADDCOMPHLPSTRING_ODA
                 $ADDCOMPHLPDESC_ODA
                 $ADDCOMPSTRING_RACDBCLOUD
                 $ADDCOMPHLPSTRING_RACDBCLOUD
                 $ADDCOMPHLPDESC_RACDBCLOUD
                 $hostname
                 $current_user
                 $srdc_log_fh
                 $paramfile
                 $tfacmd
                 $tfa_home
                 $crs_home
                 $EXADATA
                 $EXADATA_SETUP
                 $DEBUG
                 $PROFILING_ON
                 $HPROF_ON
                 $PORT
                 $NODE_NAMES
                 $SUPPORTMODE
                 $SR
                 $TFA_HOME
                 $CRS_HOME
                 $IS_ODA
                 $IS_ODALITE
                 $ODALITE_TYPE
                 $IS_RACDBCLOUD
                 $IS_ODADom0
                 $IS_VM
                 $IS_EXADATADom0
                 $IS_WINDOWS
                 $IS_SOLARIS
                 $IS_AIX
                 $IS_HPUX
                 $IS_ADE
                 $IS_ADE_HOST
                 $IS_ZDLRA
                 $INSTLOGFILE
                 $BASEDIR
                 $ORACLE_BASE
                 $DEFERDISC
                 $INSTALL_TYPE
                 $NODE_TYPE
                 $GLB_REMOVE_WALLET
                 $DIAGDIR
                 $DIAG_TIME
                 $DIAGDIRIPS
                 $DIAGDIRDDU
                 $tputcols
                 $DEVNULL
                 $TMP
                 $INITDIR
                 $EXE 
                 $PSEP
                 $FSEP
                 $node 
                 $osname
                 $processor
                 $pingflag
                 $PWD
                 $SSH
                 $RM
                 $MV
                 $MKDIR
                 $CP
                 $SCP
                 $CHMOD
                 $CHGRP
                 $GROUPADD
                 $GROUPDEL
                 $USERMOD
                 $CHOWN
                 $FIND
                 $ZIP
                 $UNZIP
                 $TOUCH
                 $HOSTNAME
                 $DOMAINNAME
                 $UNAME
                 $CAT
                 $TAR
                 $LS
                 $PS
                 $ENV
                 $CKSUM
                 $DF
                 $TOP
                 $NETSTAT
                 $PTREE
                 $PSTREE
                 $IFCONFIG
                 $GREP
                 $DATE
                 $EGREP
                 $UPTIME
                 $VMSTAT
                 $LSCPU
                 $SYSCTL
                 $VIEW_LOG
                 $LOG_TYPE
                 $RACTION
                 $FTYPES
                 $MANAGE_RECEIVER
                 $CACTION
                 $CTYPE
                 $CollectorNode
                 $Cpassword
                 $receiverNode
                 $pluginadd
                 $processbug
                 $Rpassword
                 $roption
                 $koption
                 $FILETOSEND
                 $osutil_sep
                 $PRINT_CERT_WARNING
                 $TFA_AGE_WARNING
                 $crsctl
                 $oclumon
                 $SUMMARY_REPOSITORY
                 $INTERACTIVE_SUMMARY
                 $SUMMARY_REPORTTYPE
                 $SUMMARY_DISPLAY_TABLE
                 $SUMMARY_COMPONENTS_REF
                 $SUMMARY_TIME
                 $SUMMARY_LOG_FH
                 $SUMMARY_COMPONENT_ORDER_REF
                 $SUMMARY_NODE_LIST_REF
                 $SUMMARY_TIME_PROFILE_HREF
                 $SUMMARY_PROFILE_HASHREF
                 $SUMMARY_REMOTE_DATA_REF
                 $SUMMARY_OVERVIEW_TYPE
                 $SUMMARY_LOG_FILE 
                 $IS_DB_INSTALLED
                 $IS_CRS_INSTALLED
                 $SETUPSUDOCMDS
                 $SERIALIZEMETADATA
                 );

#                 $DBNAME
#                 $INSTANCE_NAME

use strict;
use File::Spec::Functions;

if ( $^O eq "MSWin32" )
{
  eval q{use base 'Win32'; 1} or die $@;
}
######################### TFACTL Global Constants ############################
our ($TFACTLGLOBAL_WCARD_CHARS) = '[%*]';      # Set of wildcard characters. #
use constant MARKED                    =>  "1";
use constant UNMARKED                  =>  "0"; 
use constant PREVCMD                   => 0;
use constant NXTCMD                    => 1;
use constant COMPCMD                   => 2;
use constant MORECMD                   => 3;
use constant RETCMD                    => 4;
use constant HLPCMD                    => 0;
use constant HLPMSG                    => 1;

use constant XMLARRLEVEL               => 0;
use constant XMLARRTAG                 => 1;
use constant XMLARRTAGMODE             => 2;
use constant XMLLINENUM                => 3;

use constant ELEMNAME                  => 0;
use constant ELEMVAL                   => 1;
use constant ELEMVALTYPE               => 2;
use constant ELEMNDX                   => 3;
use constant ELEMLEVEL                 => 4;
use constant ELEMATTRNAME              => 5;
use constant ELEMATTRVAL               => 6;

use constant COMPNAME                  => 0;
use constant COMPVALIDATE              => 1;
use constant COMPALTNAME               => 2;
use constant COMPDESCRIPTION           => 3;
use constant COMPINSTANCEHOME          => 4;
use constant COMPTYPE                  => 5;
use constant COMPSUB                   => 6;
use constant COMPCONFIG                => 7;
use constant COMPSCRIPTS               => 8;
use constant COMPALSO                  => 9;

use constant COMPSCRIPTNAME            => 0;
use constant COMPSCRIPTRUSER           => 1;
use constant COMPSCRIPTINT             => 2;
use constant COMPSCRIPTPARAMS          => 3;

use constant SUBCOMPVALUE              => 0;
use constant SUBCOMPIDX                => 1;
use constant SUBCOMPNAME               => 2;
use constant SUBCOMPREQUIRED           => 3;
use constant SUBCOMPDEFAULT            => 4;

use constant SUBCOMPVALSNODE          => 0;
use constant SUBCOMPVALSCOMP          => 1;
use constant SUBCOMPVALSKVHASH        => 2;

use constant VALIDATECOMP             => 0;
use constant VALIDATESUBCOMPIDX       => 1;
use constant VALIDATESUBCOMPNAME      => 2;
use constant VALIDATESUBCOMPREQUIRED  => 3;
use constant VALIDATESUBCOMPDEFAULT   => 4;

use constant COMPVALIDSUBNAME         => 0;
use constant COMPVALIDSUBVALUE        => 1;

use constant RETCOMPNAME               => 0;
use constant RETCOMPTYPE               => 1;
use constant RETCOMPCONFIG             => 2;
use constant RETCOMPVALIDATE           => 3;

use constant MFILE_NAME                => 0;
use constant MLOCATION                 => 1;
use constant MSIZE                     => 2;
use constant MFILE_TIME                => 3;
use constant MINCIDENT_ID              => 4;
use constant MADR_BASE                 => 5;
use constant MADR_HOME                 => 6;
use constant MPACKAGE_ID               => 7;

use constant TFAUSER_HOST              => 0;
use constant TFAUSER_NAME              => 1;
use constant TFAUSER_TYPE              => 2;
use constant TFAUSER_ALLOWED           => 3;

use constant XMLFILTER_CMDLINE         => 0;
use constant XMLFILTER_DEFAULT         => 1;
use constant XMLFILTER_VALIDFOR        => 2;
use constant XMLFILTER_SHOWPROMPT      => 3;
use constant XMLFILTER_SETENV          => 4;
use constant XMLFILTER_VALIDATE        => 5;
use constant XMLFILTER_PROMPT          => 6;
use constant XMLFILTER_DEPINPUT        => 7;
use constant XMLFILTER_DEPPATTERN      => 8;
use constant XMLFILTER_MSG             => 9;
use constant XMLFILTER_REQUIRED        =>10;

use constant TFADBUTILS_CATEGORYID     => 0;
use constant TFADBUTILS_PARENTCMD      => 1;
use constant TFADBUTILS_COMMANDID      => 2;
use constant TFADBUTILS_KEYNAME        => 3;
use constant TFADBUTILS_CONTENT        => 4;
use constant TFADBUTILS_HANDLER        => 5;

use constant MAX_HOURS                 => 172; #Hours
use constant MAX_DAYS                  => 3650;#Days
use constant MAX_DSKUSG_MON_INT        => 1440;#Minutes
use constant MAX_AGE_PURGE             => 168; #Hours

# Previously located in tfactl_lib
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

######################### TFACTL Global Variables ################################
our %tfactlglobal_hash = (                                                       #
                          cmd        => '',  # The current internal command      #
                          mode       => 'i', # i=interactive,n=non-interactive   #
                          srcmod     => 'tfactl', # Source module for the call   #
                          localcmd   => 'false',  # Local command                #
                          adecmd     => 'false',  # ade command                  #
                          endn       => '',       # Endianness of the system     #
                          acver      => '12.1.0.2.0', # TFACTL version number    #
                                             # Update acver for every TFACTL     #
                                             # release!!!                        # 
                          tempdir    => '',  # Temp directory (OS specific)      #
                          verbose    => 'errors',  # verbose mode                  #
                          debugmask  => 0x10000, # Debug mask                    #
                          e          => 0,                    # output the error #
                          running    => 0,   # is an infinite command running?   #
                          consistchk => 'n'  # run options consistancy check ?   #
                          ); 

our %tfactlglobal_mod_levels = (
                             tfactlaccess => 0x0000010,
                             tfactladmin  => 0x0000020,
                             tfactlanalyze => 0x0000040,
                             tfactlbase    => 0x0000080,
                             tfactlcell    => 0x0000100,
                             tfactlcollection => 0x0000200,
                             tfactldiagcollect => 0x0000400,
                             tfactldirectory   => 0x0000800,
                             tfactlexttools    => 0x0001000,
                             tfactlips         => 0x0002000,
                             tfactlprint       => 0x0004000,
                             tfactlshare       => 0x0008000,
                             main              => 0x0010000,
                             dbglevel          => 0x0020000,
                             tfactlshare_populate_tagsarray => 0x0040000,
                             tfactlshare_parse_xmlcomp => 0x0080000,
                             tfactlshare_load_xmlcomp  => 0x0100000,
                             tfactlshare_read_ext_xml  => 0x0200000,
                             tfactlshare_get_element   => 0x0400000,
                             buildCLIJava              => 0x0800000,
                             tfactlshare_validate_tagsarray =>  0x1000000,
                             tfactlshare_menu               =>  0x2000000,
                             tfactlshare_non_daemon         =>  0x4000000,
                             tfactlshare_summary            =>  0x8000000,
                             tfactlshare_oratop             => 0x10000000,
                             tfactldbutilsavl               => 0x20000000,
                             tfactlparser                   => 0x40000000,
                             );

our ($tfactlglobal_trace_path);
our ($tfactlglobal_alert_path);
our ($tfactlglobal_log_path);
our ($tfactlglobal_diag_base);
our ($tfactlglobal_components_file) = "../resources/components.xml";
our (%tfactlglobal_exttools) = ();
our (%tfactlglobal_exttools_categories) = ();
our (%tfactlglobal_xmlcompshash) = ();
our (%tfactlglobal_usersxmlcompshash) = ();
our (%tfactlglobal_adrbasepaths) = ();
our ($tfactlglobal_tfa_ext_xml ) = "";
our (%tfactlglobal_tfa_dbutlcommands) = ();
our ($tfactlglobal_tfa_dbutlcmds ) = "";
our (@tfactlglobal_tfa_dbutlschedarr ) = ();
our ($tfactlglobal_tfa_dbutlsched ) = "";
our ($tfactlglobal_tfa_dbutlresources) = "";
our (%tfactlglobal_jsonMap ) = ();
our (%tfactlglobal_versionsMap ) = ();
our ($tfactlglobal_clsecho) = "echo";
$tfactlglobal_clsecho .= ".exe" if($^O =~ /win/i);
our ($tfactlglobal_product) = "RDBMS";
our ($tfactlglobal_facility) = "TFACTL";
our ($tfactlglobal_maxub4) = 4294967295;

our (%tfactlglobal_error_message) = ( 
      1 => 'Failed to start Oracle Trace File Analyzer (TFA) daemon. Please check TFA logs.', 
      2 => 'Oracle Trace File Analyzer (TFA) is not running',
     16 => 'Oracle Trace File Analyzer (TFA) requires GAWK or NAWK. Please install gawk or nawk and try again.',
     17 => 'Unable to create Installation Log File no log file will be written.',
     51 => 'Oracle Trace File Analyzer (TFA) is not running. Please run tfactl using non-root user',
    101 => 'TFA setup is not running as the root user...',
    102 => 'Unable to determine ORACLE_BASE. Exiting Installation now...',
    103 => 'TFA is not yet secured to run all commands',
    104 => 'Cannot establish connection with TFA Server. Please check TFA Certificates',
    200 => 'TFA_HOME is not set correctly.',
    201 => 'Diagnostic directory not found.',
    202 => 'No ORACLE_HOME was found, ADRCI commands are disabled.',
    203 => 'The required ADR relation is missing, ADR may be corrupted.',
    204 => 'File components.xml is missing.',
    205 => 'TFA IPS integation is not supported for pre 12.2.0 versions.',
    206 => 'Diagnostic directory for TFA IPS not found.',
    207 => 'No ADR basepaths were discovered.',
    208 => 'TFA Base Directory not found.',
    209 => 'Timeout while updating file Config.properties. Please run in debug mode.',
    210 => 'Repository directory for TFA DDU not found.',
    301 => 'Invalid character in password.',
    302 => 'Unknown command.', 
    303 => 'Syntax error in IPS command.',
    307 => 'Unclosed single-quote.',
    402 => 'Internal error.',
    403 => 'Assert that first argument is not true',
    404 => 'XML file is not well formed',
    405 => 'Multiple root elements were found.',
    406 => 'Invalid regular expression.',
    450 => 'JSON file is not well formed',
    500 => 'You can not run this command in client cluster',
    501 => 'You can not register receiver in receiver cluster',
    502 => 'Receiver name is missing from input',
    503 => 'Receiver node is missing from input',
    504 => 'Receiver port is missing from input',
    505 => 'Receiver is already added',
    506 => 'You can not do this action from receiver cluster',
    507 => 'User does not have permissions to add receiver. Please run the command as root',
    508 => 'Unable to determine port on which TFA is listening in receiver',
    509 => 'Password macth failed in Receiver',
    510 => 'Unexpected Client Command',
    511 => 'Failed to add Client in Receiver',
    512 => 'Client name is missing from input',
    513 => 'Connection Refused',
    514 => 'Failed to remove client',
    515 => 'Invalid option',
    516 => 'This client is already registered in receiver',
    517 => 'This client does not exist',
    518 => 'Oracle Trace File Analyzer (TFA) is not running (stopped)',
    519 => 'Oracle Trace File Analyzer (TFA) is not installed',
    520 => 'Only Reciever Config Parameters supported with -name flag',
    521 => 'User does not have permission to run TFA',
    522 => 'Successive clients should be added on the receiver node where the first was added'
                                      );
our (%tfactlglobal_commands);
our (%tfactlglobal_help_commands);
our (%tfactlglobal_help_messages);
#Hash with the set available commands
our (%tfactlglobal_set_commands) = (
  "tracelevel"                   => 1,
  "trimsize"                     => 1,
  "collectionPeriod"             => 1,
  "fileCountInventorySwitch"     => 1,
  "inventoryThreadPoolSize"      => 1,
  "collectAllDirsByFile"         => 1,
  "rtscan"                       => 1,
  "diskUsageMon"                 => 1,
  "manageLogsAutoPurge"          => 1,
  "bugsftpurl"                   => 1,
  "odscan"                       => 1,
  "firediagcollect"              => 1,
  "internalSearchString"         => 1,
  "ignoreEventsInADE"            => 1,
  "notificationAddress"          => 1,
  "chanotification"              => 1,
  "chaautocollect"               => 1,
  "firediagcollectOD"            => 1,
  "firediagcollectRT"            => 1,
  "autodiagcollect"              => 1,
  "autopurge"                    => 1,
  "minagetopurge"                => 1,
  "minSpaceForRTScan"            => 1,
  "diskUsageMonInterval"         => 1,
  "manageLogsAutoPurgeInterval"  => 1,
  "manageLogsAutoPurgePolicyAge" => 1,
  "minTimeForAutoDiagCollection" => 1,
  "cookie"                       => 1,
  "trimfiles"                    => 1,
  "walletpassword"               => 1,
  "buildversion"                 => 1,
  "ciphersuite"                  => 1,
  "publicip"                     => 1,
  "debugips"                     => 1,
  "tfaIpsPoolSize"               => 1,
  "tfaDbUtlPurgeAge"             => 1,
  "tfaDbUtlPurgeMode"            => 1,
  "r.repository"                 => 1,
  "r.port"                       => 1,
  "r.send.collections"           => 1,
  "logstash.host"                => 1,
  "logstash.port"                => 1,
  "tfaweb.env"                   => 1,
  "tfaweb.url"                   => 1,
  "oss.type"                     => 1,
  "oss.url"                      => 1,
  "oss.user"                     => 1,
  "oss.password"                 => 1,
  "oss.proxy"                    => 1,
  "wallet.location"              => 1,
  "secureadd"                    => 1,
  "blackout"                     => 1,
  "blackout.timeout"             => 1,
  "redact"                       => 1
);
# The following arrays hold lists of functions.  Each TFACTL module must
# have exactly one function in each of these arrays.

# These functions process TFACTL commands within their respective modules.
our (@tfactlglobal_command_callbacks);

# These functions process the help command within their respective modules.
our (@tfactlglobal_help_callbacks);

# These functions list available TFACTL commands supported by their
# respective modules.
our (@tfactlglobal_command_list_callbacks);

# These functions determine if a command is supported by their respective
# modules.
our (@tfactlglobal_is_command_callbacks);

# These functions determine if a command supports wildcards.
our(@tfactlglobal_is_wildcard_callbacks);

# These functions display the correct syntax of an TFACTL command supported
# by their respective modules.
our (@tfactlglobal_syntax_error_callbacks);

# These functions determine if a command can run even without a TFA 
# instance.
our (@tfactlglobal_no_instance_callbacks);

our (%tfactlglobal_cmds);

# Global Hash table to store all options for consistency check
our (%tfactlglobal_options);

# Copy of @ARGV array
our (@tfactlglobal_argv);
# Copy of help @ARGV array
our (@tfactlglobal_help_argv);

# ORACLE_HOMEs available
our (@tfactlglobal_oracle_homes);
our (%tfactlglobal_oracle_homes_adrciversion);
# ADR HOMEs available
our (@tfactlglobal_adr_homes);
# ADR BASE paths available
our (%tfactlglobal_adrbaseselected);

# XML support arrays
our @xmlcompsarray;
our @validatexmlcompsarray;
our @retcomparray;

# Oracle Versions
our $tfactlglobal_dbversions;

#XML match patterns
our $XMLTAGCLOSE = '\s*\<\s*\/\s*([\w-_]+)\s*\>\s*';
our $XMLTAGOPEN  = '\s*\<\s*([\w-_]+)\s*\>\s*';
our $XMLCONTENT  = '[a-zA-Z0-9\s\.\-\_\+\/\\\!\@\^\%\,\?\|\*\&\;\:\,\'\`\"\>\[\]\{\}\(\)\=\#\$]';
our $XMLCDATAOPEN = '\<\!\[CDATA\[';
our $XMLCDATACONTENT ='[\w\W]*';
our $XMLCDATACLOSE = '\]\]\>';
our $XMLATTRIBUTES = '(?:^|\s+)(\S+)\s*=\s*("[^"]*"|\S*)';
our $XMLTAGOPENATTRIBUTES = '\s*\<\s*([\w-_]+)\s*([\w-_\'\"\s\=\.\^\$\+\|\\\%\*\#\[\]\(\)\/\&\;\?\:,]+)\s*\>\s*';
our $XMLTAGOPENCLOSE =  '\s*\<\s*([\w-_]+)\s*\/\s*\>\s*';
our $XMLTAGOPENATTRIBUTESCLOSE = '\s*\<\s*([\w-_]+)\s*([\w-_\'\"\s\=\.\^\$\+\|\\\%\*\#\[\]\/\&\;\?\:,]+)\s*\/\s*\>\s*';
our $XMLCOMMENTOPEN = '\s*(\<\!\-\-)([a-zA-Z0-9\s\.\-\_\/\\\%\|\*\$\:\(\)\{\}\[\]]*)';
our $XMLCOMMENTCLOSE = '([a-zA-Z0-9\s\.\-\_\/\\\%\|\*\$\:\(\)\{\}\[\]]*)(\-\-\>)\s*';
our $XMLHEADER ='\<\?xml\s+((\S+)\s*=\s*("[^"]*"|\S*)\s*)+\?\>\s*';
our $XMLEMPTYLINE = '\s*';
our $XMLCOMMENTCONTENT = '.*';

#JSONParser match patterns
our $JSONSTR      = '\s*\"[ -~]+?\"(?<!\\\")';
our $JSONNUM      = '\s*[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?';
our $JSONOPENOBJ  = '\s*\{';
our $JSONCLOSEOBJ = '\s*\}';
our $JSONOPENARR  = '\s*\[';
our $JSONCLOSEARR = '\s*\]';
our $JSONCOLON	  = '\s*\:';
our $JSONCOMMA	  = '\s*\,';
our $JSONNULL	    = '\s*null';
our $JSONTRUE	    = '\s*true';
our $JSONFALSE	  = '\s*false';
our $JSONEOF      = '^\s*$';

# Global Context 
our (%tfactlglobal_ctx);
our %tfactlglobal_ctx_commands = ( "db" => 1,
                        "database" => "db",
                        "host" => 1,
                        "node" => "host",
                        "inst" => 1,
                        "instance" => "inst",
                        "time" => 1,
                        "ed" => 1,
                        "editor" => "ed"
                      );

# SRDC
our (%tfactlglobal_srdc);

# List of deprecated options 
# Pls update this table with all options that are deprecated
# in the next release so that WARNING can be shown when used
# Delete the entries from the table in the succesive release
# after the deprecation.
# #########################################################
# Format
# ( COMMAND1 => { Option1 => [ GetoptSyntax , NewOption ]
#                 Option2 => [ GetoptSyntax , NewOption ]
#   COMMAND2 => { Option 1 .......
#  
#  if NewOption is NULL then, option no more supported
#
#  Algo for handling deprecated options
#--------------------------------------
#  1. push the current options in @string for GetOptions
#  2. push deprecated options if any 
#  3. process args using GetOptions
#  4. if any depr options were used, set the value of the 
#     corresponding options
#  5. print WARNING for each depcr option used.
#
# Please see init() for each perl module and tfactlshare_handle_deprecation 
###########################################################
our (%tfactlglobal_deprecated_options) = ( 
                                         );

# These functions display error messages for module-specific TFACTL commands.
# TFACTL Error Message Numbers:
#   1000-1099 - General TFACTL errors.
#     1000    - message for error 1000.
#     1001    - message for error 1001.
#
# Functions for recording errors; does not terminate TFACTL session.
our (@tfactlglobal_error_message_callbacks);
# Functions for signaling errors; terminates TFACTL session.
our (@tfactlglobal_signal_exception_callbacks);

#our $DEBUG;
our $START = 0;
our $STARTFROMINIT = 0;
our $STOPFROMINIT = 0;
our $SHUTDOWN = 0; 
our $ENABLE = 0; 
our $DISABLE = 0; 
our $STOP = 0; 
our $CHECK = 0; 
our $CHECKSTATUS = 0; 
our $CHECKAUTOPATCHING = 0; 
our $CHECKKEYSTORES = 0; 
our $COMMANDTOEXECUTE;
our $COMMANDTOEXECUTE_PRINT;
our $EXECUTEINHOST_PRINT;
our $PROGRAM_PRINT;
our $TNTPROP;
our $INVFILE;
our $EXECUTEINHOST;
our $SEARCH;
our $SEARCH_PAT;
our $TNT_VERBOSE = 0; 
our $TNT_TYPE;
our $TNT_OFILE;
our $TNT_FROM;
our $TNT_TO;
our $TNT_COMP;
our $TNT_TCASE;
our $A_RUN_CMD;
our $A_RUN_FLAGS;
our $CLEAN = 0;
our $RUNINVENTORY;
our $RUNCELLINVENTORY;
our $RUNINVENTORYINCELLS;
our $RUNCELLODSCAN;
our $RUNODSCANINCELLS;
our $cell;
our $cells;
our $onlycell;
our $PRINTACTIONS = 0;
our $PRINTCOOKIE = 0;
our $PRINTTFAHOME = 0;
our $PRINTWALLETPASSWORD = 0;
our $PRINTCELLS = 0;
our $PRINTONLINECELLS = 0;
our $PRINTBUILDVERSION = 0;
our $PRINTONGOINGCOLL = 0;
our $COPYTFACTL = 0; 
our $UPDATEAUTODIAGCOLLECT = 0;
our $UPDATECIPHERSUITE = 0;
our $UPDATEPROPERTIESFILE = 0;
our $UPDATEDIRECTORIESFILE = 0;
our $FIXTFACTL;
our $FIXTFADIAGNOSTICS;
our $UPLOAD;
our @UPLOAD_FLAGS;
our $SETUPMOS;
our $FIXINITTFA;
our $SETUPND = 0; # manuegar_extract_tfa_03
our $SETUPND_JAVAHOME = "";
our $CREATETFASETUP;
our $UPDATEJDKINTFASETUP;
our $RECREATEFILEENTITIESINBDB;
our $CREATETFADIRECTORIES;
our $PRINTTFALOG = 0;
our $PRINTDIRS = 0;
our $CHANGEREPO;
our $PRINTREPO;
our $PRINTRUNMODE;
our $PRINTCONFIG;
our $PRINTIPADDRESS;
our $PRINTCOMPONENTS;
our $PRINTSUSPENDEDIPS;
our $PRINTINTERNALCONFIG;
our $PRINTEVENTS;
our $RUNTEST;
our $MANAGER = 0;
our $CHANGEREPOSIZE;
our $CHANGEJVMMEMSIZE;
our $CHANGEJVMOTHER;
our $RESTARTTFA;
our $FORCE;
our $MAXLOGSIZE;
our $MAXLOGCOUNT;
our $maxCoreFileSize;
our $maxCoreCollectionSize;
our $PRINTHOSTS = 0;
our $PRINTPROTOCOLS = 0;
our $PRINTRECEIVERS = 0;
our $PRINTCOLLECTORS= 0;
our $PRINTROBJECTS= 0;
our $PRINTIP = 0; 
our $PRINTINVENTORY;
our $PRINTADRINCIDENTS;
our $PRINTSTARTUPS;
our $PRINTCMD;
our $PRINTSHUTDOWNS;
our $PRINTPARAMETERS;
our $PRINTERRORS;
our $PRINTCOLLECTIONS;
our $PRINTPROBLEMSETS;
our $CHECKVERSION;
our $UPGRADESTATUS = 0;
our $UPGRADEVERSION;
our $GENERATECOOKIE;
our $GENCERTS;
our $SSLRESTART;
our $SSLKEY = 0;
our $TEMP_TFAHOME;
our $TFA_JHOME;
our $PRINTINVRUNSTAT = 0;
our $PRINTCELLINVRUNSTAT = 0;
our $PRINTCELLDIAGSTAT = 0;
our $CONFIGURECELLS = 0;
our $CHECKFILETYPEXML = 0;
our $ZIPFILESFORDATE = 0;
our $RUNDIAGCOLLECT = 0;
our $RUNDIAGCOLLECTCELL = 0;
our $RUNDIAGCOLLECTINCELLS;
our $DIAGCOLLECT = 0;
our $STOPCOLLECTION;
our $FILELISTDIRECTORY;
our $FILELISTLASTINV;
our $STARTDATE;
our $ENDDATE;
our $OUTFILE;
our $RDMODE;
our $RDAUTO;
our $DELETEDB;
our $ADDDIR;
our $CHANGEDIR;
our $PERMISSION;
our $EXCLUSION;
our $ADDHOST;
our $RMHOST;
our $RMRECEIVER;
our $ADDDOM0IP;
our $RESTRICTPROTOCOL;
our $FORCERESTRICT = 0;
our $RMDOM0IP;
our $RMDIR;
our $RUNDISC;
our $RUNREDISC;
our $CLUSTERWIDE = 0;
our $SET_CMD_ARGS = "";
our $private_directory = 1;
our $collect_all = 0;
our $DSCRIPT_OPTS;
our $DSCRIPT_RUNDEF= FALSE;
our $DSCRIPT_DEF   = FALSE;
our $DSCRIPT_NOIPS = FALSE;
our $DSCRIPT_IPS   = FALSE;
our @DSCRIPT_COMP_CMDLINE = ();
our $COLLECTZIPS;
our $RUNSCAN;
our $DIR;
our $HOST;
#our $DBNAME;
#our $INSTANCE_NAME;
our $SINCE;
our $FOR;
our $MODIFY;
our $SET_FLAG;
our $HELP = 0;
our $silent = 0;
our $node_list;
our $comp;
our $printdir_policy;
our $printdir_permission;
our $metadata;
our $action_status;
our $action_time;
our $event_time;
our $coll_time;
our $SENDUNINSTALLUPDATE = 0;
our $STOPSUPTOOLS = 0;
our $PARSEEVENTS = 0;
our $PURGE = 0;
our $purge_time;
our $DIAG_TIME = 12;
our $SETUPSUDOCMDS = 0;
our $SERIALIZEMETADATA = FALSE;
our $CHECKFILEACCESS = 0;
our $CHECKFILEACCESSUSINGSU = 0;
our $INPUTFILE;

#Storage Cell Variables
our $CELLREMWALLETPASS = 0;
our $CELLREMWALLET = 0;
our $CELLADDWALETPASS = 0;
our $CELLPRINTCELLS = 0;
our $CELLPRINTCONFIG = 0;
our $CELLDECONFIG = 0;
our $ISLOCAL = "-l";
our $SILENT = 0;
our $SRDCSILENT = FALSE;
our $NOMONITOR = FALSE;

our $UNINSTALL = 0;
our $UNINSTALLARGS;

our $DIAGNOSETFA = 0;
our $SENDMAIL = 0;
our $TFAUPLOAD;
our $TFABUG;
our $TFASR;
our $TFACMT;
our $TFABUGSFTP;

# tfa ext tools
our $DEPLOYEXT  = 0;
our $RUNTOOL    = 0;
our $RUNTOOLCMD;
our $RUNTOOLCMDMODE;

# Non-Root Access Variables:
our $LISTTFAUSERS = 0;
our $TFAUSER;
our $SETUPTRACEDIR = 0;
our $ADDDEFAULTUSERS = 0;
our $ADDTFAUSER = 0;
our $ADDTFAGROUP = 0;
our $BLOCKTFAUSER = 0;
our $BLOCKTFAGROUP = 0;
our $UNBLOCKTFAUSER = 0;
our $UNBLOCKTFAGROUP = 0;
our $RESETTFAUSERS = 0;
our $REMOVETFAUSER = 0;
our $REMOVEALLUSERS = 0;
our $RMUSERFROMGP = 0;
our $ADDACCESS = 0;
our $REMOVEACCESS = 0;
our $UPDATEACCESS = 0;
our $ACCESSLOCAL = "-c";

# Cloud
our $ISCLOUD = 0;
our $ISJCS = 0;
our $ISFMW = 0;
our $SI_REL_DIR = catdir("", "suptools","tfa","release","tfa_home");
# TFA/IPS global variables
our $ADRCI   = "";
our $ORABASE = "";
our $TFAIPS_PARROUT = "";
our $TFAIPS_NMBR = 0;
our $TFAIPS_NUMBER = 0;
our $TFAIPS_PACKNUMBER = 0;
our $TFAIPS_PACKNAME = "";
our $TFAIPS_PRBKEY = "";
our $TFAIPS_STTIME = "";
our $TFAIPS_ENDTIME = "";
our $TFAIPS_TIME = "";
our $TFAIPS_FILENAME = "";
our $TFAIPS_NEWFILENAME = "";
our $TFAIPS_FILEPATH = "";
our $TFAIPS_OPERATION = "";
our $TFAIPS_OVERWRITE = "";
our $TFAIPS_LEFTCHK = 0 ;
our $TFAIPS_ADRBASE = "";
our $TFAIPS_ADRHOMEPATH = "";
our $TFAIPS_ADRHOMEPATH_MULTI = "";
our $TFAIPS_ADRCIHOMEPATH = "";
our $TFAIPS_ADRCIORACLEHOME = "";
our $TFAIPS_TARGETHOMEPATH = "";
our $TFAIPS_MULTIHOMEPATH = 0;
our $TFAIPS_OHOMESET = 0;
our $TFAIPS_OHOME = "";
our $TFAIPS_CORRLVL;
our $TFAIPS_SHOWINC = 0;
our $TFAIPS_SHOWPROB = 0;
our $TFAIPS_SHOWHELP = 0;
our $TFAIPS_CRTPKG = 0;
our $TFAIPS_GENPKG = 0;
our $TFAIPS_PACK = 0;
our $TFAIPS_FINPKG = 0;
our $TFAIPS_UNPFIL = 0;
our $TFAIPS_ADDADRBASE = 0;
our $TFAIPS_ADDINCLAST = 0;
our $TFAIPS_ADDNEWINC = 0;
our $TFAIPS_ADDREMFIL = 0;
our $TFAIPS_ADDREMOPER = 0;
our $TFAIPS_CPYFIL = 0;
our $TFAIPS_DELPKG = 0;
our $TFAIPS_GETMANIFEST = 0;
our $TFAIPS_GETMETADATA = 0;
our $TFAIPS_SETBASE = 0;
our $TFAIPS_SETHOMEPATH = 0;
our $TFAIPS_SHOWFILES = 0;
our $TFAIPS_SHOWOPER = 0;
our $TFAIPS_SHOWCONFIG = 0;
our $TFAIPS_SHOWPKG = 0;
our $TFAIPS_USEREMKEY = 0;
our $TFAIPS_UNPPKG = 0;
our $TFAIPS_UNPINTTFA = 0;
our $TFAIPS_ADRCICOMMAND = "";
our $TFAIPS_SILENT ="no";
our $TFAIPS_INCIDENTNMBR = "";
our $TFAIPS_PROBLEMNMBR = "";
our $TFAIPS_PROBLEMKEY = "";
our $TFAIPS_COLLECTIONDIR = "nodirectory";
our $TFAIPS_COLLECTIONDIR_REL = "nodirectory";
our $TFAIPS_COLLECTIONID  = "none";
our $TFAIPS_PURGEREMOTE   = "none";
our $TFAIPS_PACKTYPE      = "timerange";
our $TFAIPS_UNDO_ADRBASEPATH = "";
our $TFAIPS_UNDO_ADRHOMEPATH = "";
our $TFAIPS_ADETIMEOUT    = 1000;
our $TFAIPS_NONADETIMEOUT = 600;
our $TFAIPS_MAXTRIES      = 30;
our $TFAIPS_POOLSIZE      = 5;
our $TFAIPS_MINPOOLSIZE   = 2;
our $TFAIPS_MAXPOOLSIZE   = 20;
our $TFAIPS_KEYSEP        = '==';
our $TFAIPS_KEYMATCHERSEP    = '\=\=';
our $TFAIPS_KEYMATCHER       = '(.*)' . $TFAIPS_KEYMATCHERSEP . '(.*)' . $TFAIPS_KEYMATCHERSEP . '(.*)';
our $TFAIPS_ALLFILES      = FALSE;
our $TFAIPS_ALLFILESTXT   = "";
our $TFAIPS_FILESEP       = catfile("","");

our $OSSHELL = "";
our $CSH     = FALSE;

# srdc help
our $SRDCHLPSTRING            = "";

# EM srdc
our $EMAGENTOHOME = "";
our $EMAGENTIHOME = "";
our $EMOMSOHOME   = "";
our $EMTARGETDBNAME = "";
our $EMTARGETASMINSTANCE = "";
our $EMREPOSITORYDBNAME = "";
our $EMREPOSITORYREPVFY = "";
our $EMREPOSITORYOHOME  = "";
our $EMREPOSITORYTNS = "";
our $EMDBSNMPPWD = "";
our $EMSYSMANPWD = "";

# DB Utilities
our $DBUTILSSUMMARY = FALSE;
our $DBUTILSSUMMARYNODES = "";
our $DBUTILSSUMMARYMODE = "default";
our $DBUTILSAVL = FALSE;
our $DBUTILSAVLCATID = "";
our $DBUTILSAVLCMDID = "";
our $DBUTILSAVLTZONE = "";
our $DBUTILSAVLSAMPLENOW = FALSE;
our $DBUTILSAVLSAMPLENOWRESTYPE = "";
our $DBUTILSAVLSAMPLENOWKEYNAME = "";
our $DBUTILSAVLSAMPLENOWKEYVALUE = "";
our $DBUTILSAVLGENJSON = FALSE;
our $DBUTILSAVLGENJSONCAT = "";
our $DBUTILSAVLGENJSONCMD = "";

# xml dynamic components
our $ADDCOMPSTRING            = "";
our $ADDCOMPHLPSTRING         = "";
our $ADDCOMPHLPDESC           = "";
our $ADDCOMPSTRING_EXADATA    = "";
our $ADDCOMPHLPSTRING_EXADATA = "";
our $ADDCOMPHLPDESC_EXADATA   = "";
our $ADDCOMPSTRING_ODA        = "";
our $ADDCOMPHLPSTRING_ODA     = "";
our $ADDCOMPHLPDESC_ODA       = "";
our $ADDCOMPSTRING_RACDBCLOUD        = "";
our $ADDCOMPHLPSTRING_RACDBCLOUD     = "";
our $ADDCOMPHLPDESC_RACDBCLOUD       = "";

# TFA global environment
our $hostname;
our $paramfile;
our $tfacmd = "";
our $tfa_home;
our $crs_home;
our $EXADATA;
our $EXADATA_SETUP;
#our $DEBUG = DBG_NOTE | DBG_WHAT | DBG_VERB | DBG_HOST;
#our $DEBUG = DBG_NOTE | DBG_WHAT;
our $DEBUG = DBG_NOTE;
our $PROFILING_ON=TRUE;
our $HPROF_ON=FALSE;
our $PORT;
our $NODE_NAMES;
our $SUPPORTMODE;
our $SR;
our $TFA_HOME;
our $CRS_HOME;
our $INSTLOGFILE;

our $IS_ZDLRA =FALSE;
if ( -f catfile("","opt","oracle.RecoveryAppliance")){
  $IS_ZDLRA=TRUE;
}
our $IS_ODA=FALSE;
if ( -f catfile("","opt","oracle","oak","bin","oakd") ) {
  $IS_ODA=TRUE;
}

our $ODALITE_TYPE;
our $IS_ODALITE=FALSE;
if ( -f catfile("","proc","cmdline")) {
   open (F1,catfile("","proc","cmdline"));
   while (<F1>) {
   $IS_ODALITE=TRUE if $_ =~ /X.*_LITE_([LMS]|IAAS)/;
   $ODALITE_TYPE = $1;
   }
}
our $IS_ODABMIAAS=FALSE;
$IS_ODABMIAAS = TRUE if $ODALITE_TYPE eq "IAAS";

our $IS_RACDBCLOUD=FALSE;
if ( -d catfile("","opt","oracle","opc") ) { $IS_RACDBCLOUD=TRUE; }

our $IS_ODADom0=FALSE;
if ( -d catfile("","opt","oracle","oak","bin") ) {
  my $xenblk = `/sbin/lsmod | grep xen_blkback | awk '{print \$1}'`;
  my $xennet = `/sbin/lsmod | grep xen_netback | awk '{print \$1}'`;
  #print "$xenblk $xennet";
  if ( $xenblk && $xennet ) {
    $IS_ODADom0=TRUE;
  }
} # end if checking ODADom0

our $IS_EXADATADom0=FALSE;
our $DAEMON_OWNER = "";
our $IS_NON_ROOT_DAEMON = 0;
our $IS_TFA_ADMIN = 0;
our $current_user = "";
our $srdc_log_fh;
our $DEVNULL = "";
our $TMP;
our $osname;
our $IS_WINDOWS=0;
our $IS_SOLARIS=0;
our $IS_AIX=0;
our $IS_HPUX=0;
if ( $^O eq "solaris" )
{
  $IS_SOLARIS = 1;
}
if ( $^O eq "aix" )
{
  $IS_AIX = 1;
}
if ( $^O eq "hpux" )
{
  $IS_HPUX = 1;
}
if ( $^O eq "MSWin32" )
{
  if(Win32::IsAdminUser()){
    $current_user = "root";
  }else{
    $current_user = getlogin;
  }
  $IS_WINDOWS = 1;
  $DEVNULL = "nul";
  $osname = $^O;
  $PROFILING_ON=FALSE;
  $TMP = "C:\\TMP";
}
 else
{
  $current_user = getpwuid($<);
  $DEVNULL = "/dev/null";
  $osname = `uname`;
  $TMP = "/tmp";
  $OSSHELL = `env|grep -i '^shell='`;
  if ( $OSSHELL =~ /\/bin\/t?csh/ ) { 
    $CSH = TRUE;
  }
}
chomp ($osname);

# ade settings
our $IS_ADE = FALSE;
our $IS_ADE_HOST = FALSE;
my $chkadecmd;
if ( $IS_WINDOWS ) {
  $chkadecmd = `set`;
}
else {
  $chkadecmd = `env`;
}
if ( $chkadecmd ) {
  my @vars = split(/\n/,$chkadecmd);
  @vars    = grep{/ADE_VIEW_NAME/} @vars;
  if ( @vars ) {
    $IS_ADE = TRUE;
  }
  @vars = split(/\n/,$chkadecmd);
  @vars    = grep{/ADE_/} @vars;
  if ( @vars ) {
    $IS_ADE_HOST = TRUE;
  }
}

if ( $IS_ADE ) {
  $SETUPND = 1;
}

our $BASEDIR = "";
our $ORACLE_BASE;
our $DEFERDISC = 0; 
our $INSTALL_TYPE = "TYPICAL"; # GI/ODA etc
our $NODE_TYPE = "TYPICAL";
our $GLB_REMOVE_WALLET = 0;

our $DIAGDIR = 0;    # Diagnostic directory set
our $DIAGDIRIPS = 0; # Diagnostic directory set for TFA IPS
our $DIAGDIRDDU = 0; # Diagnostic directory set for TFA DDU

our $tputcols = `tput cols 2>&1`;
if ( $IS_WINDOWS || $tputcols =~ /tput:/ ) {
  $tputcols = "80";
}

our $INITDIR="/etc/init.d";
our $EXE = ""; 
our $PSEP = ":";
our $FSEP = "/";
our $node;

our $processor;
our $pingflag;

our $PWD; 
our $SSH="/usr/bin/ssh -x";
our $RM;
our $MV;
our $CP;
our $SCP; 
our $CHMOD;
our $CHGRP;
our $GROUPADD = "groupadd";
our $GROUPDEL = "groupdel";
our $USERMOD  = "usermod";
our $CHOWN;
our $FIND;
our $ZIP;
our $UNZIP;
our $TOUCH;
our $HOSTNAME;
our $DOMAINNAME;
our $TAR; 
our $UNAME; 
our $CAT; 
our $LS;
our $PS;
our $ENV;
our $CKSUM;
our $DF;
our $TOP;
our $NETSTAT;
our $PTREE;
our $PSTREE;
our $IFCONFIG;
our $GREP;
our $DATE;
our $EGREP;
our $UPTIME;
our $VMSTAT;
our $LSCPU;
our $SYSCTL;

our $VIEW_LOG;
our $LOG_TYPE;
our $RACTION;
our $FTYPES;
our $MANAGE_RECEIVER;
our $CACTION;
our $CTYPE;
our $CollectorNode;
our $Cpassword;
our $receiverNode;
our $pluginadd;
our $processbug;
our $Rpassword;
our $roption;
our $koption;
our $crsctl;
our $oclumon;

our $FILETOSEND;
our $MKDIR;

our $SUMMARY_REPOSITORY;
our $INTERACTIVE_SUMMARY;
our $SUMMARY_REPORTTYPE;
our $SUMMARY_DISPLAY_TABLE;
our $SUMMARY_COMPONENTS_REF;
our $SUMMARY_TIME;
our $SUMMARY_LOG_FH;
our $SUMMARY_COMPONENT_ORDER_REF;
our $SUMMARY_NODE_LIST_REF;
our $SUMMARY_TIME_PROFILE_HREF;
our $SUMMARY_PROFILE_HASHREF;
our $SUMMARY_REMOTE_DATA_REF;
our $SUMMARY_OVERVIEW_TYPE;
our $SUMMARY_LOG_FILE;
our $IS_DB_INSTALLED = 1;
our $IS_CRS_INSTALLED = 1;

our $osutil_sep ="~~";
our $PRINT_CERT_WARNING = 1;
our $TFA_AGE_WARNING = 180;

# Set up some command stuff
if (!$IS_WINDOWS)
{
  chomp( $PWD = `pwd;`);
  $ADRCI = "adrci";
  $CAT = tfactlglobal_getCommandLocation("cat");
  $CHGRP = tfactlglobal_getCommandLocation("chgrp");
  $CHMOD = tfactlglobal_getCommandLocation("chmod");
  $CHOWN = tfactlglobal_getCommandLocation("chown");
  $CKSUM = tfactlglobal_getCommandLocation("cksum");
  $CP = tfactlglobal_getCommandLocation("cp");
  $DF = tfactlglobal_getCommandLocation("df");
  $DOMAINNAME = tfactlglobal_getCommandLocation("domainname");
  $ENV = tfactlglobal_getCommandLocation("env");
  $FIND = tfactlglobal_getCommandLocation("find");
  $GROUPADD = tfactlglobal_getCommandLocation("groupadd") if ( $current_user eq "root" );
  $GROUPDEL = tfactlglobal_getCommandLocation("groupdel") if ( $current_user eq "root" );
  $HOSTNAME = tfactlglobal_getCommandLocation("hostname");
  $LS = tfactlglobal_getCommandLocation("ls");
  $MV = tfactlglobal_getCommandLocation("mv");
  $NETSTAT = tfactlglobal_getCommandLocation("netstat");
  $ORABASE = "orabase";
  $PS = tfactlglobal_getCommandLocation("ps");
  $PTREE = tfactlglobal_getCommandLocation("ptree");
  $PSTREE = tfactlglobal_getCommandLocation("pstree");
  $RM = tfactlglobal_getCommandLocation("rm");
  $SCP = tfactlglobal_getCommandLocation("scp");
  $SCP = "$SCP -q";
  $SSH = tfactlglobal_getCommandLocation("ssh");
  $SSH = "$SSH -q";
  $TAR = tfactlglobal_getCommandLocation("tar");
  $TOP = tfactlglobal_getCommandLocation("top");
  $TOUCH = tfactlglobal_getCommandLocation("touch");
  $UNAME = tfactlglobal_getCommandLocation("uname");
  $USERMOD = tfactlglobal_getCommandLocation("usermod") if ( $current_user eq "root" );
  $ZIP = tfactlglobal_getCommandLocation("zip");
  $UNZIP = tfactlglobal_getCommandLocation("unzip");
  $IFCONFIG = tfactlglobal_getCommandLocation("ifconfig");
  $GREP = tfactlglobal_getCommandLocation("grep");
  $DATE = tfactlglobal_getCommandLocation("date");
  $EGREP= tfactlglobal_getCommandLocation("egrep");
  $UPTIME= tfactlglobal_getCommandLocation("uptime");
  $VMSTAT= tfactlglobal_getCommandLocation("vmstat");
  $LSCPU = tfactlglobal_getCommandLocation("lscpu");
  $SYSCTL = tfactlglobal_getCommandLocation("sysctl");
}else{
  $TOUCH   = "type NUL >";
  $MV      = "move";
  $RM      = "del";
  $ADRCI   = "adrci.exe"; 
  $ORABASE = "orabase.exe";
  $CP      = "copy";
  $CAT     = "type";
  $LS      = "dir";
  $IFCONFIG = "ipconfig";
  $GREP    = "findstr";
  $DATE    = "echo \%DATE\% \%TIME\%";
}
$MKDIR = "mkdir";

our $IS_VM = 0;

if ($osname eq "Linux") {
        $pingflag = "-c"; 
        $processor = `uname -p`;
        $PTREE = tfactlglobal_getCommandLocation("pstree");
        chomp ($processor);
        my $out = `$CAT /proc/cpuinfo | $GREP hypervisor`;
        $IS_VM = 1 if ( $out );
}
elsif ($osname eq "SunOS") {
        $pingflag = "-c"; 
        $processor = `uname -p`;
        chomp ($processor);
        $INITDIR="/etc/init.d";
}
elsif ($osname eq "AIX") {
        $pingflag = "-c";
        $INITDIR="/etc";
}
elsif ($osname eq "HP-UX") {
        $pingflag = "-n";
        $processor = `uname -m`;
        chomp ($processor);
        $INITDIR="/sbin/init.d";
}
elsif ($osname eq "MSWin32" ) {
        $pingflag = "-n";
        $processor = "x86_64";
        chomp ($processor);
        $INITDIR="c:\\";
        $EXE = ".exe";
        $PSEP = ";";
        $FSEP = "\\";
}
else {
        print "This Code cannot run on  $osname $processor \n";
        exit 0;
}

$crsctl = "crsctl" . $EXE;
$oclumon = "oclumon" . $EXE;

sub tfactlglobal_getCommandLocation {
  my $command = shift;
  my $cmdpath = $command;

  if ( -f catfile("", "bin", $command) ) {
    $cmdpath = catfile("", "bin", $command);
  } elsif ( -f catfile("", "usr", "bin", $command) ) {
    $cmdpath = catfile("", "usr", "bin", $command);
  } elsif ( -f catfile("", "usr", "local", "bin", $command) ) {
    $cmdpath = catfile("", "usr", "local", "bin", $command);
  } elsif ( -f catfile("", "sbin", $command) ) {
    $cmdpath = catfile("", "sbin", $command);
  } elsif ( -f catfile("", "usr", "sbin", $command) ) {
    $cmdpath = catfile("", "usr", "sbin", $command);
  }
  
  return $cmdpath;
}

return 1;
