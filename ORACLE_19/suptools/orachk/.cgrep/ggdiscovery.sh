 #!/bin/env bash 
 isogghome() 
 { 
 local isgghome; 
 isgghome=$(ls $1"/extract" $1"/replicat"); 
 ogghasmgr=$(ps -ef |grep -v grep|grep -wi mgr | grep -wi PARAMFILE|wc -l ); 

 if [ "$isgghome" != "" ] && [ "$ogghasmgr" -gt 0 ]
 then 
     echo 0; 
 else 
     echo 1; 
 fi 
 }

oggarr() # OGG Array
{
    local str1="{print $""$2}";
    echo $(echo $1 | awk "$str1");
}
 
 findogghome4() 
 { 
 local oggindex=1;
 local oggpid=-1; 
 local oggdirhome=""; 
 local ogghomefound=$RAT_OGG_HOMES; 
 local ogghomelist=""; 
 local oggcount=0; 
 local oggret=""; 
 local oggpos=0; 
 local oggversionline=""; 
 local ggowner=""; 
 local ggversion=""; 
 local ogglist=$(ps -ef |grep -v grep|grep -wi mgr |grep -wi PARAMFILE |awk '{print $2}'); 
 local oggishome; 
 local oggallfound=1; 
 local ogghasmgr; 
 local ogghostname;
 local str1;
 local oggplatform=$(uname);
 #ogglist=$(echo $ogglist); 

 #echo $(echo $ogglist | awk "$str1");
 # if we found mgr running and RAT_OGG_HOMES is not set 
 # attempt to find the home directories 
 while [ "$oggpid" != "" ] && [ "$ogghomefound" = "" ] 
 do 
   oggpos=$oggindex; 

   oggpid=$(oggarr "$ogglist" $oggindex);
   
   if [ "$oggpid" != "" ] 
   then 
       
       if [ "$oggplatform" = "LINUX" ]
       then
         oggdirhome=$(pmap $oggpid | grep -w mgr | grep -ioP "/.*mgr$");
         oggdirhome=$(dirname $(oggarr "$oggdirhome" 1) 2>/dev/null);
       elif [ "$oggplatform" = "AIX" ]
       then
         oggdirhome=$(procmap $oggpid | grep mgr | perl -lne 'print $1 while /(\/.*\/mgr)/gi' | head -n 1);
         oggdirhome=$(dirname $oggdirhome 2> /dev/null);        
       else # Solaris and HP-UX
         oggdirhome=$(pmap $oggpid | grep mgr | perl -lne 'print $1 while /(\/.*\/mgr)/gi' | head -n 1);
         oggdirhome=$(dirname $oggdirhome 2> /dev/null); 
       fi       
   fi 
 
   oggishome=$(isogghome "$oggdirhome" 2> /dev/null);
   if [ "$oggishome" != "0" ] ; then oggdirhome="";  fi;
     
   if [ "$oggdirhome" = "" ] && [ "$oggpid" != "" ] 
       then 
       if [ "$oggplatform" = "LINUX" ]
       then
         oggdirhome=$(pmap $oggpid | grep mgr | grep -ioP "paramfile /.*.prm" | grep -ioP "/.*.prm"); 
         oggdirhome=$(dirname $(dirname $oggdirhome 2> /dev/null) 2> /dev/null); 
       elif [ "$oggplatform" = "AIX" ]
       then
         oggdirhome=$(procmap $oggpid | grep mgr | perl -lne 'print $1 while /(paramfile \/.*[.]prm)/gi' |  perl -lne 'print $1 while /([\/].*[.]prm)/gi');
         oggdirhome=$(dirname $(dirname $oggdirhome 2> /dev/null) 2> /dev/null); 
       else # Solaris and HP-UX
         oggdirhome=$(pmap $oggpid | grep mgr | perl -lne 'print $1 while /(paramfile \/.*[.]prm)/gi' |  perl -lne 'print $1 while /([\/].*[.]prm)/gi');
         oggdirhome=$(dirname $(dirname $oggdirhome 2> /dev/null) 2> /dev/null); 
       fi
       

       oggishome=$(isogghome $oggdirhome 2> /dev/null); 
       if [ "$oggishome" != "0" ] 
       then 
	   oggallfound=0; 
	   oggdirhome=""; 
       fi 
   fi 

   oggishome=$(isogghome "$oggdirhome" 2> /dev/null);
   if [ "$oggishome" != "0" ] ; then oggdirhome="";  fi;
   
   if [ "$oggdirhome" != "" ] && [ "$RAT_OGG_HOMES" = "" ] 
   then 
       RAT_OGG_HOMES="$oggdirhome"; 
   elif [ "$oggdirhome" != "" ] 
   then 
       RAT_OGG_HOMES="$RAT_OGG_HOMES,$oggdirhome"; 
   fi 
   oggdirhome=""; 
   oggindex=$(expr $oggindex + 1); 
 done 
 
 # if we couldnt find home directories but we have mgr(s) running 
 # then prompt for it 
 ogghasmgr=$(ps -ef |grep -v grep|grep -wi mgr | grep -wi PARAMFILE|wc -l ); 
 if [ "$ogghasmgr" -gt 0 ] && [ "$RAT_OGG_HOMES" = "" ] || [ $oggallfound -eq 0 ] 
 then 
     if [ $oggallfound -eq 0 ] 
     then 
	 echo "could not found all OGG homes, found: $RAT_OGG_HOMES"; 
     fi 
     echo "Prompt for OGG_HOME" 
       
 fi 
 
 ogghomelist=$(echo $RAT_OGG_HOMES | tr "," " "); 
# ogghomelist=($ogghomelist); 
 oggdirhome=""; 
 oggindex=1;
 oggcount=$(echo $RAT_OGG_HOMES | tr "," " " | wc -w); 
 
 # with the list of home directories, find version and owner 
 while [ $oggindex -le $oggcount ] 
 do 
   oggdirhome=$(oggarr "$ogghomelist" $oggindex); 
   oggindex=$(expr $oggindex + 1);

   if [ "$oggdirhome" != "" ]
       then
       # Validate Directory 
       oggishome=$(isogghome "$oggdirhome" 2> /dev/null); 
       if [ "$oggishome" != "0" ] ; then echo "$oggdirhome is not a valid path for OGG home"; continue;  fi;
      
       if [ "$oggplatform" = "LINUX" ]
       then
         oggversionline=$(echo " " | $oggdirhome"/ggsci" | tail -n +2); 
         ggversion=$(echo $oggversionline | grep -ioP "version [0-9.]*" | grep -ioP "[0-9][0-9.]*"|tr -d .)
       else
         oggversionline=$(echo " " | $oggdirhome"/ggsci");
         ggversion=$(echo $oggversionline | perl -lne 'print $1 while /(version [0-9.]*)/gi' | perl -lne 'print $1 while /([0-9][0-9.]*)/gi' )
       fi
       ggowner=$(ls -ld $oggdirhome); 
       ggowner=$(oggarr "$ggowner" 3); 
       
       #find hostname 
       ogghostname=$(hostname|cut -d. -f1); 
       #ogghostname=""; 
       #alternative method to get the hostname 
       if [ -z "$ogghostname"  ]; then ogghostname=$(echo "info mgr" | $oggdirhome"/ggsci" | grep -i "ip port"|awk '{print $NF}'|cut -d. -f1); fi 
       echo "RAT_OGG_HOMES="$ogghostname"|"$oggdirhome"|"$ggversion"|"$ggowner; 
     fi 
 done 
 } 

