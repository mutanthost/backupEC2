#!/usr/bin/python
"""
    
 Copyright (c) 2013, 2016, Oracle and/or its affiliates. All rights reserved.

    NAME
      rack_comparison.py

    DESCRIPTION
      Compare two different Exalogic rack and see if both are coming from the same release.
      This is done by comparing software versions of each components, hardware, configurations, and patches.
    AUTHOR
      Andrego Halim

    MODIFIED   (MM/DD/YY)
    mengwliu    09/09/16 - Bug fix for OPCM
    mengwliu    06/13/16 - Bug fix for OPCM
    mengwliu    05/23/16 - Bug fix for EMOC stack
    anhalim     06/27/13 - Creation

"""

#### LIBRARY IMPORTS ####
import sys
import os
import zipfile
import subprocess
import glob
import shutil
import filecmp
import fileinput
import difflib
import re
import cStringIO
from time import strftime,localtime

#### VARIABLES ####
rack_1_name=""
rack_2_name=""
rack_1_fullpath=""
rack_2_fullpath=""
rack_1_shortpath=""
rack_2_shortpath=""
rack_1_outputdir=""
rack_2_outputdir=""
identical_count=0
total_count=0
rack_1_name=""
rack_2_name=""
check_list={} # A map to list all checks that are seen from both racks, and maps to the node names for each check
rack_1_node_id_map={}
rack_2_node_id_map={}
node_with_issues={}
temp_identical_path=os.getcwd()+"/identical.tmp"
temp_different_path=os.getcwd()+"/different.tmp"
traverse_status=0

#### FUNCTIONS ####

# Returns the different variations of input as needed
def get_variation(rack_input):
  if rack_input.endswith(".zip"):
    rack_shortpath=rack_input[:-4]
  elif rack_input.endswith("/"):
    rack_shortpath=rack_input[:-1]
  else:
    rack_shortpath=rack_input
  rack_fullpath=os.getcwd()+ "/" + rack_shortpath
  rack_inputdir=rack_fullpath+"/outfiles/"
  rack_outputdir=rack_fullpath+"/outfiles/rack_compare/"
  rack_name=rack_input.split('_')[1]

  # Check if this report is from a consolidated stack
  conf=rack_fullpath+"/exachk_exalogic.conf"
  if os.path.isfile(conf):
    if subprocess.Popen(["cat "+ conf + " | grep -c ovmm_ip_01"], shell=True,stdout=subprocess.PIPE).communicate()[0].rstrip() > 1:
      is_consolidated=True
    else:
      is_consolidated=False
  else:
    is_consolidated=False
  return rack_shortpath, rack_fullpath, rack_inputdir, rack_outputdir, rack_name, is_consolidated

# If the user gives zip file as an input for the rack info, unzip them as necessary
# Returns the name of the zip file
def unzip_rack_info(rack_input):
  rack_fullpath=os.getcwd() + "/" + rack_input
  rack_shortpath=rack_input
  try:
    if zipfile.is_zipfile(rack_fullpath):
      subprocess.call(['unzip', '-qo', rack_fullpath])
      rack_fullpath=rack_fullpath[:-4]
      rack_shortpath=rack_input[:-4]
  except IOError:
      pass
  if not rack_fullpath.endswith("/"):
    rack_fullpath = rack_fullpath + "/"
  if rack_shortpath.endswith("/"):
    rack_shortpath = rack_shortpath[:-1]
  return rack_shortpath,rack_fullpath

# Creates /rack_compare dir in /outfiles dir of a rack's output folder
def create_output_dir(rack_fullpath):
  rack_OutputDir=rack_fullpath+"outfiles/rack_compare/"
  if not os.path.exists(rack_OutputDir):
    os.makedirs(rack_OutputDir)
  else: 
    fileList = os.listdir(rack_OutputDir)
    for fileName in fileList:
      os.remove(rack_OutputDir+"/"+fileName)
  return rack_OutputDir

# Create exachk_exalogic.conf file to aid data processing
def create_conf_file(rack_input):
  rack_shortpath, rack_fullpath, rack_inputdir, rack_outputdir, rack_name, is_consolidated = get_variation(rack_input)
  conf_fullpath = rack_fullpath+"/exachk_exalogic.conf" 
  if os.path.exists(conf_fullpath):
    return
  conf_file = open(conf_fullpath, 'a')
  try:
    # Writing Compute Node section into the conf file
    count=1
    for line in open(rack_inputdir+"o_host_list.out"):
      if count<10:
        conf_file.write("c_nodes_0"+str(count)+"_hostname="+str(line))
      else:
        conf_file.write("c_nodes_"+str(count)+"_hostname="+str(line))
      count+=1 

    # Writing Switch section into the conf file
    count=1
    for line in open(rack_inputdir+"o_ibswitches.out"):
      conf_file.write("ib_switch_0"+str(count)+"_hostname="+str(line))
      count+=1 

    # Writing Storage Node section into the conf file
    count=1
    for line in open(rack_inputdir+"o_storage.out"):
      conf_file.write("sn_nodes_0"+str(count)+"_hostname="+str(line))
      count+=1 

  finally:
    conf_file.close()

# Get the id of the node
def get_node_id(rack_fullpath, node_name, is_consolidated):
  # Get id of the node from exachk_exalogic.conf
  node_id=subprocess.Popen(["cat " + rack_fullpath+"/exachk_exalogic.conf | grep "+node_name+
                            " | egrep 'c_nodes|db|ovmm|ec|pc_01|pc_02|switch|sn_nodes|sn_ext_nodes|controlvm' " +
                            "| head -n1 | cut -d= -f1 |sed 's/rack_0_//'"],
                           shell=True, stdout=subprocess.PIPE).communicate()[0].rstrip()
  m = re.search("^(.+)_[\w-]+$", node_id)
  try:
    node_id=m.groups()[0]
  except:
    global node_with_issues
    if node_name not in node_with_issues.keys():
      print("Node " + node_name + " is invalid when processing " + rack_fullpath + "/exachk_exalogic.conf")
      node_with_issues[node_name]=True
      global traverse_status
      traverse_status=1
    

  # Detect duplicate IPs from Stack 35
  if is_consolidated and ("ovmm" in node_id or "ec" in node_id):
    node_id="ovmm"
  return node_id


# Traverse each rack_comparison-related check within a rack's /outfiles
def traverse_rack_info_dir(rack_input,rack_node_id_map):
  rack_shortpath, rack_fullpath, rack_inputdir, rack_outputdir, rack_name, is_consolidated = get_variation(rack_input)
  
  for filename in sorted(os.listdir(rack_inputdir)):
    # Traverse data files that uses "rack_compare" keyword
    if ("rack_compare" in filename) and ("report" not in filename) and (os.path.isfile(rack_inputdir+filename)):
      parse=filename.split('__')
      check_name=parse[1]
      check_prefix=parse[0]
      node_name=parse[2][:-4]
      fd = open(rack_inputdir+filename, 'r')

      # Find the actual component referred to by this data file(i.e. cnode1, sn02, db, ovmm, etc)
      node_id=get_node_id(rack_fullpath,node_name, is_consolidated)
      if node_id is not "":
        rack_node_id_map[node_id]=node_name
        outputfile=rack_outputdir+check_name+"__"+node_id
        nodelist_filename=rack_outputdir+check_name+"__"+rack_name+"nodelist"
        file = open(outputfile, 'a')
        nodelist_file = open(nodelist_filename, 'a')
        try:
          file.write(fd.read())
          nodelist_file.write(node_name)
        finally:
          file.close()
          nodelist_file.close()
        if not check_name in check_list:
          check_list[check_name]=set()  
        check_list[check_name].add(node_id)
      fd.close()

    # Special case for zfs data in extracting parameter
    elif "exalogic_zfs_checks.out" in filename:
      check_name="Storage_Firmware_Version"
      parse=filename.split('.')
      node_name=parse[0]
      node_id=get_node_id(rack_fullpath,node_name, is_consolidated)
      rack_node_id_map[node_id]=node_name
      outputfile=rack_outputdir+check_name+"__"+node_id
      file = open(outputfile, 'a')
      try:
        firmware_vers = ""
        for line in open(rack_inputdir+filename):
          if "Current firmware version" not in line:
            continue
          firmware_vers=line.split(' ')[8]+"\n"
          break
        file.write(firmware_vers)
      finally:
        file.close()
      if not check_name in check_list:
        check_list[check_name]=set()  
      check_list[check_name].add(node_id)

# Print the header html tags prior to the main content table
def print_header():
  header="""
<html lang="en"><head>
<style type="text/css">
body {font-family: Lucida Grande,Lucida Sans,Arial,sans-serif;
    font-size: 14px;
    background:white;
}
h1 {color:black; text-align: center}
h2 {color:black; background:white; font-family: Arial; font-size: 24px}
h3 {color:black; background:white}
a {color: #000000;}
p {font-family: Lucida Grande,Lucida Sans,Arial,sans-serif;
    font-size: 14px;
}
.a_bgw {
  color: #000000;
  background:white;
}

table {
    color: #000000;
    font-weight: bold;
    border-spacing: 0;
    outline: medium;
    font-family: Lucida Grande,Lucida Sans,Arial,sans-serif;
    font-size: 14px;
    border: 2;
}

th {
 background: #F2F5F7;
    border: 1px solid grey;
    font-size: 14px;
    font-weight: bold;
}

.th .rack_col {
    padding:10px 10px 10px 10px;
    width: 40%;
}

th.param_name {
    width: 10%;
}
th.status {
    width: 5%;
}

td {
 background: #F2F5F7;
    border: 1px solid grey;
    font-weight: normal;
    padding: 5;
}

.status_FAIL
{
    font-weight: bold;
    color: #c70303;
}
.status_PASS
{
    font-weight: bold;
    color: #006600;
}

.td_output {
    color: #000000;
    background: white;
    border: 1px solid grey;
    font-family: Lucida Grande,Lucida Sans,Arial,sans-serif;
    font-size: 14px;
    font-weight: normal;
    padding: 1;
}
.td_column {
 background: #F2F5F7;
    border: 1px solid grey;
    font-size: 14px;
    font-weight: bold;
}

.td_column_second {
 background: #F2F5F7;
    border: 1px solid grey;
    font-size: 11px;
    font-weight: bold;
}

td_report {
 background: #F2F5F7;
    border: 1px solid grey;
    font-weight: normal;
    padding: 5;
}

.td_report2 {
 background: #F2F5F7;
    border: 1px solid grey;
    font-size: 14px;
}

.td_report1 {
 background: #F2F5F7;
    border: 1px solid grey;
    font-size: 14px;
}

.td_title {
 background: #F2F5F7;
    border: 0px solid grey;
    font-weight: normal;
    padding: 5;
}

.h3_class {
    font-family: Lucida Grande,Lucida Sans,Arial,sans-serif;
    font-size: 15px;
    font-weight: bold;
    color: black;
    padding: 15;
}

.button{
    cursor:pointer;
    float:left;
}

.container{
    margin-top: 40px;
    font:12px verdana;
    background:#fefcd9;
    padding:10px 10px 10px 10px;
    border:solid 1px lightgray;
    width: 400px;
}

.container .tl{
    position: relative;
    float: left;
}

.container .tr{
    position: relative;
    float: right;
}

.tr .min-button{
    cursor:pointer;
    float:left;
}

.tr .max-button{
    cursor:pointer;
    float:left;
}

.container .bc{
    position: relative;
    display: inline-block;
    float: right;
}


pre {
 overflow-x: auto; /* Use horizontal scroller if needed; for Firefox 2, not needed in Firefox 3 */
 white-space: pre-wrap; /* css-3 */
 white-space: -moz-pre-wrap !important; /* Mozilla, since 1999 */
 white-space: -pre-wrap; /* Opera 4-6 */
 white-space: -o-pre-wrap; /* Opera 7 */
 word-wrap: break-word; /* Internet Explorer 5.5+ */
}

.shs_bar {
width: 500px ;
height: 20px ;
float: left ;
border: 1px solid #444444;
background-color: white ;
}

.shs_barfill {
height: 20px ;
float: left ;
background-color: #FF9933 ;
width: 94% ;
}

</style>
<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js"></script>
<script type="text/javascript" src="http://code.jquery.com/ui/1.8.18/jquery-ui.min.js"></script>
<script type = "text/javascript">

//<![CDATA[
$(window).load(function(){
  $(".tr").click(function() {
    id=this.getAttribute('id');
    $("#div_"+id).toggle("blind");
    $(".toggle_"+id).toggle();
  });
});//]]>

var report_format = "new";
function processForm()
{
    
    if (report_format == "old")
    {
        report_format = "new";
        var i;
        var bo = document.querySelectorAll("body");
        for (i = 0; i < bo.length; i++) 
        {
                bo[i].style.fontSize = "14px";
        }
        var hc1 = document.querySelectorAll("h1");
        for (i = 0; i < hc1.length; i++) 
        {
                hc1[i].style.color = "black";
        }
        var hc2 = document.querySelectorAll("h2");
        for (i = 0; i < hc2.length; i++) 
        {
                hc2[i].style.color = "black";
        }
        var hc3 = document.querySelectorAll("h3");
        for (i = 0; i < hc3.length; i++) 
        {
                hc3[i].style.color = "black";
        }
        var pf = document.querySelectorAll("p");
        for (i = 0; i < pf.length; i++) 
        {
                pf[i].style.fontSize = "14px";
        }
        var tf = document.querySelectorAll("table");
        for (i = 0; i < tf.length; i++) 
        {
                tf[i].style.fontSize = "14px";
        }
        var th = document.querySelectorAll("th");
        for (i = 0; i < th.length; i++) 
        {
                th[i].style.background = "#F2F5F7";
                th[i].style.border = "1px solid grey";
                th[i].style.fontSize = "14px";
        }
        var td = document.querySelectorAll("td");
        for (i = 0; i < td.length; i++) 
        {
                td[i].style.border = "1px solid grey";
	}
        var tdo = document.querySelectorAll(".td_output");
        for (i = 0; i < tdo.length; i++) 
        {
                tdo[i].style.background = "white";
                tdo[i].style.border = "1px solid grey";
                tdo[i].style.fontSize = "14px";
        }
        var tdc = document.querySelectorAll(".td_column");
        for (i = 0; i < tdc.length; i++) 
        {
                tdc[i].style.background = "#F2F5F7";
                tdc[i].style.border = "1px solid grey";
                tdc[i].style.fontSize = "14px";
        }
	var tdc = document.querySelectorAll(".td_column_second");
        for (i = 0; i < tdc.length; i++) 
        {
                tdc[i].style.background = "#F2F5F7";
                tdc[i].style.border = "1px solid grey";
        }
	var tdc = document.querySelectorAll("td_report");
        for (i = 0; i < tdc.length; i++) 
        {
                tdc[i].style.border = "1px solid grey";
        }
        var tdc = document.querySelectorAll(".td_report2");
        for (i = 0; i < tdc.length; i++) 
        {
                tdc[i].style.background = "#F2F5F7";
                tdc[i].style.border = "1px solid grey";
                tdc[i].style.fontSize = "14px";
        }
        var tdc = document.querySelectorAll(".td_report1");
        for (i = 0; i < tdc.length; i++) 
        {
                tdc[i].style.background = "#F2F5F7";
                tdc[i].style.border = "1px solid grey";
                tdc[i].style.fontSize = "14px";
        }
        var tdc = document.querySelectorAll(".h3_class");
        for (i = 0; i < tdc.length; i++) 
        {
                tdc[i].style.color = "black";
        }
        var tdt = document.querySelectorAll(".td_title");
        for (i = 0; i < tdt.length; i++) 
        {
                tdt[i].style.border = "0px solid grey";
        }
        var shs = document.querySelectorAll(".shs_bar");
        for (i = 0; i < shs.length; i++) 
        {
                shs[i].style.background = "white";
        }
        var ml = document.querySelectorAll(".more_less_style");
        for (i = 0; i < ml.length; i++) 
        {
                ml[i].style.color = "black";
        }
        document.getElementById('results').innerHTML ="Switch to old format";

    }
    else
    {
        report_format = "old";
        var i;
        var bo = document.querySelectorAll("body");
        for (i = 0; i < bo.length; i++) 
        {
                bo[i].style.fontSize = "13px";
        }
        var hc1 = document.querySelectorAll("h1");
        for (i = 0; i < hc1.length; i++) 
        {
                hc1[i].style.color = "blue";
        }
	var hc2 = document.querySelectorAll("h2");
        for (i = 0; i < hc2.length; i++) 
        {
                hc2[i].style.color = "blue";
        }
        var hc3 = document.querySelectorAll("h3");
        for (i = 0; i < hc3.length; i++) 
        {
                hc3[i].style.color = "blue";
        }
        var pf = document.querySelectorAll("p");
        for (i = 0; i < pf.length; i++) 
        {
                pf[i].style.fontSize = "13px";
        }
        var tf = document.querySelectorAll("table");
        for (i = 0; i < tf.length; i++) 
        {
                tf[i].style.fontSize = "12px";
        }
        var th = document.querySelectorAll("th");
        for (i = 0; i < th.length; i++) 
        {
                th[i].style.background = "#D7EBF9";
                th[i].style.border = "1px solid #AED0EA";
                th[i].style.fontSize = "13px";
        }
        var td = document.querySelectorAll("td");
        for (i = 0; i < td.length; i++) 
        {
                td[i].style.border = "1px solid #AED0EA";
        }
        var tdo = document.querySelectorAll(".td_output");
        for (i = 0; i < tdo.length; i++) 
        {
                tdo[i].style.background = "#E0E0E0";
                tdo[i].style.border = "1px solid #AED0EA";
                tdo[i].style.fontSize = "13px";
        }
        var tdc = document.querySelectorAll(".td_column");
        for (i = 0; i < tdc.length; i++) 
        {
                tdc[i].style.background = "#D7EBF9";
                tdc[i].style.border = "1px solid #AED0EA";
                tdc[i].style.fontSize = "13px";
        }
	var tdc = document.querySelectorAll(".td_column_second");
        for (i = 0; i < tdc.length; i++) 
        {
                tdc[i].style.background = "#D7EBF9";
                tdc[i].style.border = "1px solid #AED0EA";
        }
	var tdc = document.querySelectorAll("td_report");
        for (i = 0; i < tdc.length; i++) 
        {
                tdc[i].style.border = "1px solid #AED0EA";
        }
	var tdc = document.querySelectorAll(".td_report2");
        for (i = 0; i < tdc.length; i++) 
        {
                tdc[i].style.background = "#F2EDEF";
                tdc[i].style.border = "1px solid #AED0EA";
		tdc[i].style.fontSize = "13px";
        }
	var tdc = document.querySelectorAll(".td_report1");
        for (i = 0; i < tdc.length; i++) 
        {
                tdc[i].style.background = "#F2F5EE";
                tdc[i].style.border = "1px solid #AED0EA";
		tdc[i].style.fontSize = "13px";
        }
	var tdc = document.querySelectorAll(".h3_class");
        for (i = 0; i < tdc.length; i++) 
        {
                tdc[i].style.color = "blue";
        }
	var tdt = document.querySelectorAll(".td_title");
        for (i = 0; i < tdt.length; i++) 
        {
                tdt[i].style.border = "0px solid #AED0EA";
        }
        var shs = document.querySelectorAll(".shs_bar");
        for (i = 0; i < shs.length; i++) 
        {
                shs[i].style.background = "#656565";
        }
        var ml = document.querySelectorAll(".more_less_style");
        for (i = 0; i < ml.length; i++) 
        {
                ml[i].style.color = "blue";
        }
        document.getElementById('results').innerHTML ="Switch to new format";
    }
}


function hide_help(tipdiv)
{
  document.getElementById(tipdiv).style.display = "none";
}
</script>

<title>Exalogic Rack Comparison Report</title>
</head>

<body>

<center><table summary="Comparison Report" border=0 width=100%><tr><td class="td_title" align="center"><h1>Exalogic Rack Comparison Report<br><br></td></tr></table></center>
<h2>Exalogic Rack Comparison Summary</h2>
<hr><br/>
"""
  return header

# Return the string representation of a component
def to_string(node_id):
  if "c_nodes" in node_id:
    return "Compute Node " + node_id.split("c_nodes_")[1]
  elif "ec" in node_id:
    return "Enterprise Controller"
  elif "ovmm" in node_id:
    return "Oracle VM Manager"
  elif "db" in node_id:
    return "Oracle Database"
  elif "pc" in node_id:
    return "Proxy Controller " + node_id.split("pc_0")[1]
  elif "ib_switch_spine_0" in node_id:
    return "Infiniband Spine Switch " + node_id.split("ib_switch_spine_0")[1]
  elif "ib_switch_0" in node_id:
    return "Infiniband Switch " + node_id.split("ib_switch_0")[1]
  elif "sn_nodes" in node_id:
    return "Storage Node " + node_id.split("sn_nodes_0")[1]
  elif "sn_ext_nodes" in node_id:
    return "External Storage Node " + node_id.split("sn_ext_nodes_")[1]
  elif "controlvm" in node_id:
    return "Privileged Control VM " + node_id.split("controlvm")[1]
  else:
    return node_id

# Returns content from a file desc to a cell, complete appropriate html tags and maximize/minimize capability
def print_content(fd, div_id):
  ret=""
  for i in range(1,5):
    ret=ret+fd.readline().replace("\n","<br/>\n")
  remaining=fd.read().replace("\n","<br/>\n")
  if remaining != "":
    remaining="""
    <div class="bc" style="display:none;" id="div_""" +div_id  + """">
""" + remaining + """
    </div>
    <div class="tr" id="\
""" + div_id + """\
">
      <span class="button toggle_""" + div_id + "\"" + " style=\"font-weight:bold\"" + ">[+" + str(remaining.count("\n"))+ " more lines" + """]</span>
      <span class="button toggle_""" + div_id + """" style="display: none;font-weight:bold">[-]</span>
    </div>
"""
  ret=ret+"\n"+remaining
  return ret

def prepare_rack_columns(fd,rack_node_id_map,node_id,rack_shortpath,checkname,rack_check_filename):
  ret="<td>"
  if node_id in rack_node_id_map:
    ret=ret+rack_node_id_map[node_id]
  else:
    ret=ret+"Component "+node_id+" was not found"
  ret=ret+"</td>\n"
  rack_check_div_id=rack_shortpath.replace('.', '_') + "_" + node_id + "_" + checkname
  ret=ret+"<td>\n"
  if os.path.exists(rack_check_filename):
    ret=ret+print_content(open(rack_check_filename), rack_check_div_id)
  else:
    ret=ret+"Details for " + node_id + " was not found"
  ret=ret+"</td>\n"
  return ret

# Generate an html report for the rack comparison summary
def generate_report():
  # Reference to variables containing details for each rack
  global rack_1_name, rack_2_name
  global rack_1_fullpath, rack_2_fullpath
  global rack_1_outputdir, rack_2_outputdir
  global rack_1_shortpath, rack_2_shortpath
  global rack_1_node_id_map, rack_2_node_id_map
 
  html_report_path=os.getcwd()+"/rack_comparison_"+strftime("%y%m%d_%H%M%S", localtime())+".html"

  # Initiate a html report
  fd = open(html_report_path,'a')
  try:
    # Print the pre-formatted basic html tags to the output file before processing the main content
    fd.write(print_header())

    # Print the header row of the main table which will contain the details on each parameters
    fd.write("""
<table class="main">
<tr border=5px>
  <th class="param_name" rowspan=2>Parameter Name</th>
  <th class="param_name" rowspan=2>Component Type</th>
  <th class="rack_col" colspan=2>Rack """ + rack_1_shortpath + """</th>
  <th class="rack_col" colspan=2>Rack """ + rack_2_shortpath + """</th>
  <th class="diff_col" rowspan=2>Difference</th>
  <th class="status" rowspan=2>Status</th>
</tr>
<tr border=5px> 
  <th width: 7%;>Node Name</th>
  <th width: 20%;>Details</th>
  <th width: 7%>Node Name</th>
  <th width:20%>Details</th>
</tr> 
""")
    
    global temp_identical_path
    iden_fd = open(temp_identical_path,'a+')

    global temp_different_path
    diff_fd = open(temp_different_path,'a+')

    # Loop through each check as gathered in the check_list set
    for checkname in sorted(check_list.keys()):
      rowspan=str(len(check_list[checkname]))
      count=0
      global total_count,identical_count
      total_count+=1
      identical_bool="true"
      buffer=""
      # Loop through data from each node regarding 'checkname' variable
      for node_id in sorted(check_list[checkname]):
        buffer=buffer+"<tr border=5px>\n"
        checkname_string=checkname.replace('_',' ')
        if count==0:
          # Prepare the cell containing the name of the parameter to be checked
          buffer=buffer+"<td rowspan="+rowspan+">"+checkname_string+"</td>\n"
        #print checkname
        #print sorted(check_list[checkname])
        buffer=buffer+"<td>"+to_string(node_id)+"</td>"
        
        rack_1_check_filename=rack_1_outputdir+checkname+"__"+node_id
        rack_2_check_filename=rack_2_outputdir+checkname+"__"+node_id

        
        # Prepare the columns containing data for each parameter to be checked, gathered from each rack respectively
        buffer=buffer+prepare_rack_columns(fd,rack_1_node_id_map,node_id,rack_1_shortpath,checkname,rack_1_check_filename)
        buffer=buffer+prepare_rack_columns(fd,rack_2_node_id_map,node_id,rack_2_shortpath,checkname,rack_2_check_filename)

        # Prepare the column containing differences for each parameter between two racks
        buffer=buffer+"<td>"
        if (os.path.exists(rack_1_check_filename) and os.path.exists(rack_2_check_filename)):
          diff_str=subprocess.Popen(["diff", rack_1_check_filename, rack_2_check_filename], stdout=subprocess.PIPE).communicate()[0]
          if not diff_str or diff_str.isspace():
            diff_str="No difference"
          diff_stream=cStringIO.StringIO(diff_str)
          div_id = "diff_" + node_id + "_" + checkname
          buffer=buffer+print_content(diff_stream, div_id)
        else:
          if (not os.path.exists(rack_1_check_filename)):
            buffer=buffer+"Data from Rack 1 is unavailable for this parameter<br/>"
          if (not os.path.exists(rack_2_check_filename)):
            buffer=buffer+"Data from Rack 2 is unavailable for this parameter<br/>"
        buffer=buffer+"</td>"

        # Prepare the column containing the status of each parameter, i.e. whether it's identical on both racks or not
        if ( os.path.exists(rack_1_check_filename) and os.path.exists(rack_2_check_filename) and filecmp.cmp(rack_1_check_filename,rack_2_check_filename)):
          status="<span class=\"status_PASS\">IDENTICAL</span>"
        else:
          status="<span class=\"status_FAIL\">DIFFERENT</span>"
          identical_bool="false"
        buffer=buffer+"<td>"+status+"</td>"
        buffer=buffer+"</tr>"
        count+=1
      if identical_bool is "true":
        identical_count+=1
        iden_fd.write(buffer)
      else:
        diff_fd.write(buffer)
        # Reset the boolean tracker for the next check
        identical_bool="true"

    # After all the rows have been processed, flush data rows to the html report
    # organized by parameters that are different to be shown earlier, and identical latter towards the bottom
    diff_fd.seek(0)
    fd.write(diff_fd.read())
    diff_fd.close()

    iden_fd.seek(0)
    fd.write(iden_fd.read())
    iden_fd.close()
		
    # End of the loop, print the rest of the footer html tags to complete the html report
    fd.write("""
</table>
</body>
<br><a href=\"#\" onclick=\"javascript:processForm();\"><div id=\"results\">Switch to old format</div></a>
</html>
""")
  finally:
    fd.close()

  # Append a summary table at the top of the html report
  insert_summary_table(html_report_path)
  return html_report_path

# Return the exachk version of the collection files
def get_exachk_version(rack_fullpath):
  for line in open(rack_fullpath+"outfiles/check_env.out"):
    if "EXACHK_VERSION" not in line:
      continue
    return line.split(" = ")[1]

# Return the date of the collection files
def get_exachk_date(rack_fullpath):
  for line in open(rack_fullpath+"outfiles/check_env.out"):
    if "COLLECTION DATE" not in line:
      continue
    return line.split(" = ")[1]

# Insert summary table, containing the number of parameters which are identical and different respectively
def insert_summary_table(html_report_path):
  for line in fileinput.input(html_report_path, inplace=1):
    print line, # preserve old content
    if "<h2>Exalogic Rack Comparison Summary</h2>" in line:
      print """
<table>
<tr>
<td class="td_column">Report 1</td> 
<td>"""+rack_1_shortpath+"""</td> 
</tr>
<tr>
<td class="td_column" style="padding-left:3em">Collection Date</td> 
<td>"""+get_exachk_date(rack_1_fullpath)+"""</td> 
</tr>
<tr>
<td class="td_column" style="padding-left:3em">Exacheck Version</td> 
<td>"""+get_exachk_version(rack_1_fullpath)+"""</td> 
</tr>
<tr>
<td class="td_column">Report 2</td> 
<td>"""+rack_2_shortpath+"""</td> 
</tr>
<tr>
<td class="td_column" style="padding-left:3em">Collection Date</td> 
<td>"""+get_exachk_date(rack_2_fullpath)+"""</td> 
</tr>
<tr>
<td class="td_column" style="padding-left:3em">Exacheck Version</td> 
<td>"""+get_exachk_version(rack_2_fullpath)+"""</td> 
</tr>
<tr>
<td class="td_column">Total Number of Parameters</td> 
<td>"""+str(total_count)+"""</td> 
</tr>
<tr> 
<td class="td_column">Number of Identical Parameters</td> 
<td>"""+str(identical_count)+"""</td> 
</tr>
<tr> 
<td class="td_column">Number of Non-Identical Parameters</td> 
<td>"""+str(total_count-identical_count)+"""</td> 
</tr>
</table>
"""


####### MAIN PROGRAM #######
# Validate input

# Check if the user gives correct number of arguments
if len(sys.argv) != 3 :
  print "Usage  : ", sys.argv[0], " <rack_1> <rack_2>"
  print "<rack_1> and <rack_2> correspond to each rack's exachk zip or folder respectively\n"
  print "Example: ", sys.argv[0], " exachk_ec1-vm_123456_123456 exachk_ec1-vm_654321_654321"
  print "         ", sys.argv[0], " exachk_ec1-vm_123456_123456.zip exachk_ec1-vm_654321_654321.zip"
  sys.exit()

rack_1_input=sys.argv[1]
rack_2_input=sys.argv[2]

# Check if the given racks' zip or folder exist
if ( not os.path.exists(rack_1_input) or not os.path.exists(rack_2_input) ):
  if not os.path.exists(rack_1_input) : 
    print rack_1_input, "doesn't exist"
  if not os.path.exists(rack_2_input) : 
    print rack_2_input, "doesn't exist"
  sys.exit()

print("The process may take 10-20 seconds. Please wait a moment...\n")
# Parse the rack name
rack_1_name=rack_1_input.split('_')[1]
rack_2_name=rack_2_input.split('_')[1]

# Unzip the folders if it hasn't already
rack_1_shortpath, rack_1_fullpath=unzip_rack_info(rack_1_input)
rack_2_shortpath, rack_2_fullpath=unzip_rack_info(rack_2_input)
rack_1_inputdir=rack_1_fullpath+"outfiles/"
rack_2_inputdir=rack_2_fullpath+"outfiles/"

# Create an output directory "rack_compare" for rack comparison purpose
rack_1_outputdir=create_output_dir(rack_1_fullpath)
rack_2_outputdir=create_output_dir(rack_2_fullpath)

# Create a mock "exachk_exalogic.conf" if it's not there already
conf_1_filename=create_conf_file(rack_1_input)
conf_2_filename=create_conf_file(rack_2_input)

# Traverse through each files in the input directory for each rack
traverse_rack_info_dir(rack_1_input,rack_1_node_id_map)
traverse_rack_info_dir(rack_2_input,rack_2_node_id_map)

# Check if the traversal results in missing/misconfigured info
if traverse_status is 1 :
  print
  print """Please resolve the above issue by editing corresponding exachk_exalogic.conf file above with the correct hostnames and re-run the comparison script.")
Possible reason:
- There may be more than one node mapped to the same hostname
- Hostname is not mapped to any node

Format: <node_type>_<index_of_the_node>_hostname=<storage_node_hostname_goes_here>
List of node types:
- Compute Node : c_nodes
- Infiniband Switch : ib_switch
- Storage Node : sn_nodes
- Enterprise Controller : ec
- Database : db
- Proxy Controller : pc
- Oracle VM Manager : ovmm
Example:
sn_nodes_01_hostname=el01sn01
"""
  sys.exit()

# Traverse through each check and generate report
html_report_path=generate_report()

# Clean up files or folders that were created in the process
if conf_1_filename is not None:
  pass
  #os.remove(conf_1_filename) 
if conf_2_filename is not None:
  pass
  #os.remove(conf_2_filename) 
shutil.rmtree(rack_1_outputdir)
shutil.rmtree(rack_2_outputdir)
os.remove(temp_identical_path)
os.remove(temp_different_path)


print "Rack comparison is complete. The comparison report can be viewed in: "+html_report_path

