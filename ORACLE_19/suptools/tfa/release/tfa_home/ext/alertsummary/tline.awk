# 
# tline.awk - Summarise alert.log timeline
#
# This awk script will extract out the important events out from an alert 
# log and present the timelime and relevant tracefiles. This should make it 
# easier to see the key actions leading up to a problem.
#
# Usage:
#
#  [n]awk -f tline.awk alert.log > out.file
#
# Note: This has only been tested using "nawk" and *might* give different
#       behaviour using "awk" or "gawk".
#
# Configuration:
# 
#  The script's default processing can be amended by changing the following
#  fields in the BEGIN section.
#
#  DFMT  - Date format for output. 
#          If set to 1 (default) then the day of the week is not output.
#          (This doesn't apply to 12.2 as the day of the week isn't available).
#  OS    - OS used to generate the alert log.
#          Some platforms generate different alert-log output. Values are :
#	   "unix" 	- Default
#	   "os/390"	
#  IGN   - This is a string that contains the error codes to explicitly ignore,
#          seperated by spaces. Eg, to avoid Ora-60 and Ora-1551 set the
#          string to "60 1551". Note that Ora-7445 and Ora-600's CANNOT be
#          ignored. [Default is empty string].
#  NOIGN - This is similar to "IGN" except that these errors are NOT ignored.
#  FATAL - Just output fatal errors only. These are Ora-600, Ora-700
#          and Ora-7445s
#  OPI   - Report on opidrv()/opiodr() errors. [Default is ON]
#
# Improvements:
# 
#
# To Do:
# 1. Need to handle cases where we have an null character ('\0') in the
#    middle of a file. This can sometimes be seen in Ora-07445 errors and
#    tline.awk will stop processing the remainder of the lines in the alert
#    log.
#
# V1.0.0 Aug 2003 kquinn........Created.
# V1.0.1 Mar 2004 kquinn........Strip carriage returns
# V1.0.2 Jul 2004 kquinn........Handle null Ora-600 args (all "[]"), extend
#                               error message width, added FATAL and corrected
#                               typo in "is_date".   
# V1.0.3 Oct 2004 kquinn........Added NOIGN
# V1.0.4 Mar 2005 kquinn........Also track "waited too long for rowcache.."
# V1.0.5 Apr 2006 kquinn........Summarise Ora-600/7445's seen
# V1.0.6 Dec 2006 kquinn........Handle non-English languages
# V1.0.7 Feb 2007 kquinn........Handle file names under Windows and 11g
#                               incidents
# V1.0.8 Sep 2007 kquinn........Added "to do" section
# V1.0.9 Dec 2007 kquinn........Handle ":" in the Ora-600 string
# V1.1.0 Apr 2008 kquinn........Use different gsub format for "/" target
# V1.1.1 Sep 2008 kquinn........Support mixed case Ora-600 text
# V1.1.2 Oct 2008 kquinn........Record 11g soft assert messages
# V1.1.3 Nov 2008 kquinn........Ensure summary is printed if any error is seen
# V1.1.4 Feb 2009 kquinn........Print out source file name
# V1.1.5 Aug 2009 kquinn........Handle "Global Enqueue Services Deadlock"
# V1.1.6 Oct 2009 kquinn........Handle French Ora-600/Ora-7445 text
# V1.1.7 Oct 2009 kquinn........Handle "ORA-00600: internal error" on its own
# V1.1.8 Oct 2009 kquinn........Corrected the stripping of incident= problem
#                               seen on some platforms
# V1.1.9 Nov 2009 kquinn........Record System State dumps
# V1.2.0 Jan 2010 kquinn........getfile, intfile added
# V1.2.1 Feb 2010 kquinn........Optionally report on opidrv errors
# V1.2.2 Sep 2012 kquinn........Record PMON failure to acquire latch and trace
#                               ORA-445 (background failed to start)
# V1.2.3 Oct 2012 kquinn........Add 4020 to NOIGN
# V1.2.4 Jul 2013 kquinn........Add 32701 to NOIGN + record DIA messages
# V1.2.5 Sep 2013 kquinn........Record opiodr errors too 
# V1.2.6 Oct 2013 kquinn........Warn about truncated output if the file has a
#                               binary zero (NUL) present.
# V1.2.7 Feb 2014 kquinn........Clarify binry zero message.
# V1.2.8 Feb 2015 kquinn........Warn when "oracle" binary mismatch is seen
# V1.2.9 May 2016 kquinn........Handle 12.2 timestamps and use "\r" for CRs.
#
# This version is tline129.awk
# Bugs fixed in this version are 23272615,23209922,24458371
# Need to take care of these bugs if it is upgraded to later versions

function getfile(line_)
{
 res_ = line_;
 ## printf("getfile-1> '%s'\n", res_);
 gsub("/", " ", res_); gsub(":", " ", res_);

 # Try both methods to strip the Windows delimiter
 # gsub("\\", " ", res_); # for Windows but not supported by gawk

 # See http://people.cs.uu.nl/piet/docs/nawk/nawk_92.html for this form
 gsub(/\\/, " ", res_);
 ## printf("getfile-2> '%s'\n", res_);

 return res_;
}

# Handle internal error lines (Ora-600, Ora-700)
function intline(line_, patt_)
{
 tmp_ = index(line_, "],");
 res_ = substr(line_, 1, tmp_);

 sub(patt_, "[", res_);

 return res_;
}

# is_date: return 1 if a date, else 0
#
function is_date(day_, month_, d_arr, m_arr)
{
 d_arr = "Mon Tue Wed Thu Fri Sat Sun";
 m_arr = "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec";

 if (index(d_arr, day_) && index(m_arr, month_))
   return 1;

 return 0;
}

# is_time: return 1 if a valid time, else 0
#
function is_time(var_, bits_)
{
 if (split(var_, bits_, ":") != 3)
   return 0;

 # crude tests for now
 if (bits_[1] > 23 || bits_[2] < 0) return 0;
 if (bits_[2] > 59 || bits_[2] < 0) return 0;
 if (bits_[3] > 60 || bits_[3] < 0) return 0;

 return 1;
}

# printlog: Log an important event
#
function printlog(str)
{
  if ( length(str) > 32 ) 
    printf("%*s %-32s %s\n", datelen, curdate, substr(str,1,29)"...", curfile);
  else 
    printf("%*s %-32s %s\n", datelen, curdate, substr(str,1,32), curfile);
}

## Start of MAIN processing

BEGIN			{ 
   			  # ----- Configuration Variables -------------------
                          # (See header of this file for full details)
                          # -------------------------------------------------
                          DFMT=1;                  # 1 excludes the day of week 
                          OS="unix";               # OS used (unix or os/390)
			  #OS="os/390";

                          # Option to see FATAL (7445, 600 and 700 only)
                          FATAL=1;

                          # A list of errors that we DO want to report 
                          NOIGN="4030 4031 603 4043 445 4020 32701";

			  # A list of errors we are not interested in
			  # separated by spaces
			  # IGN="60";

                          # Report on opidrv / opiodr errors
                          # (comment out the next line if not needed)
                          OPI=1;

			  # DO NOT CHANGE BELOW THIS LINE
 			  datelen=15;
			  if (!DFMT) datelen += 4;
                    
titlestr="tline.awk Version V1.2.9. Source file=";
sep="------------------------------------------------------------------------";

	   		  cnt = split(IGN, val, " ");
	   		  for (i=1; i<=cnt; i++)
			    ignore[val[i]] = 1;
	   		  cnt = split(NOIGN, val, " ");
	   		  for (i=1; i<=cnt; i++)
			    report[val[i]] = 1;
			}

# It looks like FILENAME isn't populated in the BEGIN section so we need to
# print this out when we start processing lines.
TITLE==0	{ printf("%s%s\n\n", titlestr, FILENAME);
                  TITLE=1; 
                }

# handle carriage returns and null characters
    			{ gsub("\r", ""); }
/\000/			{ nullseen = NR;
                          #gsub(/\000/, "."); 
                        }
			
/^[A-Z][a-z][a-z] /	{ if (is_date($1, $2)) 
             	      	   {
			    if (DFMT)
			      curdate=sprintf("%s %2s %s", $2, $3, $4);
			    else
			      curdate=sprintf("%s %s %2s %s", $1, $2, $3, $4);
			    next;
			   }
        	   	}

# Handle 12.2 dates
/^20[0-9][0-9]-.*T.*+/  { if ($0 ~ "^20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]T")
                          {
                            gsub("-", " ");
			    sub(/\./, " "); sub("T", " ");
			    curdate=sprintf("%s %s %s %s", $3, $2, $1, $4);
			    next;
                          }
			}
                               
/^ *[0-9][0-9]*:/	{ if (OS == "os/390" && is_time($1))
			  {
			   curdate = $1;
		           # On this platform, the second word is the 
			   # sessionid - kinda like a Unix processid
			   curfile = $2;

                           # Remove the first two words for later processing
		           sub("^ *[0-9]*:[0-9]*:[0-9]*\\.[0-9][0-9] *", "");
			   sub("^ *[0-9A-Z]* *", "");
			  }
			}

/^Errors in file /	{ 
                          fname=getfile($0);
                          ##printf("DBG2> '%s'\n", $0);
                          gsub(" .incident.*$", " ", fname);
                          ## printf("DBG3> '%s'\n", $0);
                          nw = split(fname, nw_, " ");
                          curfile=nw_[nw];
                          ## printf("DBG> curfile='%s'\n", curfile);
			}

/^System State dumped /	{
                          fname=getfile($0);
                          nw = split(fname, nw_, " ");
                          curfile=nw_[nw];
                          printlog("SystemState Dumped");
			  next;
			}

/^PMON started /	{ curfile=""; 
                          printf("%s\n", sep);
                          printlog("Database started"); 
                          next; }

/WAITED TOO LONG FOR A ROW CACHE ENQUEUE LOCK/ { curfile="";
                                                 printlog("Rowcache Wait");
                                                 next;
					       }

/PMON failed to acquire latch,/ { curfile="";
                                  printlog("PMON failed to acquire latch");
                                  next;
                                }

/Binary of new process does not/{ curfile="";
                                  printlog("==[**Binary Mismatch Seen**]==");
				  next;
				}
/Global Enqueue Services Deadlock / { curfile=""; 
				      printlog("GES Deadlock");
				      next;
				    }

/opi[do].. aborting process/ { if (!OPI) next;
			       curfile="";
                               if ($1 ~ "opidrv")
                                 printlog($4 " aborted, err " $(NF));
                               else if ($1 ~ "opiodr")
                                 printlog("aborted " $6 " " $(NF));
			       next;
			     }

# It would be ideal if we could dump the SID/OSPID but we don't have space
# so just record the fact that we attempted to kill -something-.
/^DIA.*terminating/	  { gsub("terminating blocker.*", "killing blocker");
                            printlog($0);
                            next;
                          }

/^DIA.*terminated/	  { gsub("successfully terminated session", "killed");
                            printlog($0);
                            next;
                          }

/^ORA-00600:/		{ 
                          line = intline($0, "ORA-00600:[a-zA-Z ,]*: .");
                          if (line ~ "code d'erreur")
                            gsub(" code d'erreur interne", "", line);
                          ##printf("DBG-600:2> '%s'\n", line);

			  # Seen one case with a single line that reads:
			  # ORA-00600: internal error
                          args = line;
                          if (!args || args ~ "^ORA-00600:")
                           args = "<missing>";
			  printlog("Ora-00600 " args);
                          o600_cnt++;
                          errseen=1;
			  next;
			}

/^ORA-00700:/		{ 
                          args = intline($0, "ORA-00700:[a-zA-Z ,]*: .");
                          # printf("DBG> '%s'\n", args);
                          if (!args)
                           args = "<missing>";
			  printlog("Ora-00700 " args);
                          o700_cnt++;
                          errseen=1;
			  next;
			}

# ORA-07445: exception encountered: core dump [kohatd()+758] [SIGSEGV] 
# ORA-07445: exception trouvée : image mémoire [kkfipbr()+11] [SIGSEGV]
/^ORA-07445:/		{ 
                          if ($0 ~ "exception trouv")
		    	    myfun=substr($7,2, length($7)-2);
                          else { 
                            if ( $6 ~ "]" )
		    	                    myfun=substr($6,2, length($6)-2);
                          else 
                              myfun=substr($6,2, length($6));
                          }
 			  printlog("Ora-07445 " myfun);
                          o7445_cnt++;
                          errseen=1;
			  next;
			}

/^ORA-[0-9][0-9]*:/	{ 
			  sub("^.*ORA-", "");
			  sub(":.*$", "");
			  oerr=$0+0;                          # coerce to number
                          # printf("err=%d ign=%d report=%d\n", 
                          #       oerr, ignore[oerr], report[oerr]);
			  if ((ignore[oerr] || FATAL) &&
                              !report[oerr])
			   {
                            ignore[oerr] = 1;
                            if (!index(runtime_IGN, oerr))
                              runtime_IGN = runtime_IGN " " oerr;
			    errseen = 1;
 			    skipped[oerr] = 1;
			   }
			  else
                            printlog("Ora-" $0);

                          # record that we have seen a non-fatal error
                          nonfatal = 1; 
			  next;
			}

END	{
	 if (errseen)
	  {
           printf("\nSummary: Ora-600=%d, Ora-7445=%d, Ora-700=%d", 
                o600_cnt, o7445_cnt, o700_cnt);
           printf("\n~~~~~~~");

           if (FATAL)
            printf("\nWarning: Only FATAL errors reported");
           if (nonfatal)
	    printf("\nWarning: These errors were seen and NOT reported\n");
	   cnt = split(runtime_IGN, val, " ");
	   for (i=1; i<=cnt; i++)
	    if (skipped[val[i]]) 
             {
              nl_sp = (i%7)?"":"\n";
              
              printf(" Ora-%05d%s", val[i], nl_sp);
             }
           printf("\n");
	  } # end errseen

         if (nullseen)
         {
           printf("\nIMPORTANT:\n~~~~~~~~~\n");
           printf("A NULL (binary zero) was seen in the file near line %d\n",
                   nullseen);
           printf("%s %s\n\n", 
            "If this line isn't the last one in the file then the output",
            "from this script\nmight have been truncated.");
           printf("Under UNIX Use: cat old_alert | tr -d '\\000' > new_alert\n");
         }
	}
