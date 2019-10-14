        select
                CASE
                        WHEN ROWNUM<10 THEN 'rack_name_0'||ROWNUM||'='||NAME
                        ELSE 'rack_name_'||TO_CHAR(ROWNUM)||'='||name
                END AS NAME2 FROM
                (select USEFRINAM as name from EMOC.VMB_MANAGED_RESOURC where geartype='Rack' order by id) order by rownum;
        select
                CASE
                        WHEN ROWNUM<10 THEN 'rack_size_0'||ROWNUM||'='||rsize
                        ELSE 'rack_size_'||TO_CHAR(ROWNUM)||'='||rsize
                END AS SIZE2 FROM
        	(select INITCAP(trim(rack_cfg)) as rsize from VDO_RACK_INFO order by id) order by rownum;
        select
                CASE
                        WHEN ROWNUM<10 THEN 'rack_id_0'||ROWNUM||'='||NAME
                        ELSE 'rack_id_'||TO_CHAR(ROWNUM)||'='||name
                END AS NAME2 FROM
                (select USEFRIDES as name from EMOC.VMB_MANAGED_RESOURC where geartype='Rack' order by id) order by rownum;        	
        -- list Proxy Controllers
        select
                CASE
                        WHEN ROWNUM<10 THEN 'pc_ip_0'||ROWNUM||'='||ip
                        ELSE 'pc_ip_'||TO_CHAR(ROWNUM)||'='||ip
                END AS IP2 FROM
                (select IP from (
                  SELECT IPS.ID, IPS.IP, NETWORK_NAME.NAME, NETWORK_NAME.NAMEIDX FROM
                          (SELECT C.ID, A.IPADDRESS AS IP FROM EMOC.VDO_INTERFACE_INFO A, VMB_OPERATIN_SYSTEM_INTERINFOS B,  VMB_INSTANCE C
							WHERE A.ID=B.INTERINFOS_ID AND B.ID=C.ID AND C.CANONICAL LIKE 'com.sun.hss.domain:name=NORM-%-PC,type=OperatingSystem' AND A.IPADDRESS IS NOT NULL 
							order by ipmpgrp) IPS,
                          (
                          SELECT NAME, IP, SUBNETMASK, case when UPPER(name) LIKE '%IPOIB-ADMIN%' then 1 when UPPER(name) LIKE '%ETH-ADMIN%' then 2 end as nameidx  FROM
                            (SELECT B.USEFRINAM as name, A.IPADDRESS as ip, a.SUBNETMASK as subnetmask
                            FROM VMB_NETWORK A, VMB_MANAGED_RESOURC B 
                            WHERE 
                              A.ID=B.ID AND
                              ((UPPER(B.USEFRINAM) LIKE '%IPOIB-ADMIN%' OR UPPER(B.USEFRINAM) LIKE '%ETH-ADMIN%')))
                          ) network_name
                      WHERE
                          BITAND(TO_NUMBER (REGEXP_SUBSTR (IPS.IP, '[0-9]+', 1, 1)), TO_NUMBER (REGEXP_SUBSTR (NETWORK_NAME.SUBNETMASK, '[0-9]+', 1, 1))) = TO_NUMBER (REGEXP_SUBSTR (NETWORK_NAME.IP, '[0-9]+', 1, 1)) AND
                          BITAND(TO_NUMBER (REGEXP_SUBSTR (IPS.IP, '[0-9]+', 1, 2)), TO_NUMBER (REGEXP_SUBSTR (NETWORK_NAME.SUBNETMASK, '[0-9]+', 1, 2))) = TO_NUMBER (REGEXP_SUBSTR (NETWORK_NAME.IP, '[0-9]+', 1, 2)) AND
                          BITAND(TO_NUMBER (REGEXP_SUBSTR (IPS.IP, '[0-9]+', 1, 3)), TO_NUMBER (REGEXP_SUBSTR (NETWORK_NAME.SUBNETMASK, '[0-9]+', 1, 3))) = TO_NUMBER (REGEXP_SUBSTR (NETWORK_NAME.IP, '[0-9]+', 1, 3)) AND
                          BITAND(TO_NUMBER (REGEXP_SUBSTR (IPS.IP, '[0-9]+', 1, 4)), TO_NUMBER (REGEXP_SUBSTR (NETWORK_NAME.SUBNETMASK, '[0-9]+', 1, 4))) = TO_NUMBER (REGEXP_SUBSTR (NETWORK_NAME.IP, '[0-9]+', 1, 4)) 
                      ORDER BY NAMEIDX
                  ) where rownum<3        
                ) order by rownum;
        -- list Compute Nodes
		SELECT
		  case 
		  	when ip1 is null and ROWNUM<10 then 'c_nodes_0'||TO_CHAR(ROWNUM)||'='||ip2
		  	when ip1 is null and ROWNUM>=10 then 'c_nodes_'||TO_CHAR(ROWNUM)||'='||ip2
		  	when ip1 is not null and ROWNUM<10 then 'c_nodes_0'||TO_CHAR(ROWNUM)||'='||ip1
		  	when ip1 is not null and ROWNUM>=10 then 'c_nodes_'||TO_CHAR(ROWNUM)||'='||ip1
		  end as ip
		FROM (
		SELECT
		  LISTAGG(DECODE(NAMEIDX, 1, IP),',') within group (order by ip) IP1, 
		  LISTAGG(DECODE(NAMEIDX, 2, IP),',') within group (order by ip) IP2
		FROM
		  (SELECT ips.ID, ips.IP, network_name.name, network_name.nameidx FROM
		        (SELECT c.ID as id, A.IPADDRESS as ip FROM VDO_ETHER_PORT_INFO A, VMB_SERVER_ETHPORINF B, VMB_SERVER C
        			WHERE A.IPADDRESS IS NOT NULL AND A.ID = B.ETHPORINF_ID AND B.ID = C.ID AND upper(C.MODEL) LIKE '%VIRTUAL%MACHINE%'
        			ORDER BY A.IPADDRESS, C.ID) IPS,
		        (
		        SELECT NAME, IP, SUBNETMASK, case when UPPER(name) LIKE '%IPOIB-ADMIN%' then 1 when UPPER(name) LIKE '%ETH-ADMIN%' then 2 end as nameidx FROM
		          (SELECT B.USEFRINAM as name, A.IPADDRESS as ip, a.SUBNETMASK as subnetmask
		          FROM VMB_NETWORK A, VMB_MANAGED_RESOURC B 
		          WHERE 
		            A.ID=B.ID AND
		            ((UPPER(B.USEFRINAM) LIKE '%IPOIB-ADMIN%' OR UPPER(B.USEFRINAM) LIKE '%ETH-ADMIN%'))
		            ORDER BY  TO_NUMBER (REGEXP_SUBSTR (A.IPADDRESS, '[0-9]+', 1, 1))	ASC
		            ,     	  TO_NUMBER (REGEXP_SUBSTR (A.IPADDRESS, '[0-9]+', 1, 2))	ASC
		            ,     	  TO_NUMBER (REGEXP_SUBSTR (A.IPADDRESS, '[0-9]+', 1, 3))	ASC
		            ,     	  TO_NUMBER (REGEXP_SUBSTR (A.IPADDRESS, '[0-9]+', 1, 4))	ASC)
		        ) network_name
		    WHERE
		        BITAND(TO_NUMBER (REGEXP_SUBSTR (IPS.IP, '[0-9]+', 1, 1)), TO_NUMBER (REGEXP_SUBSTR (NETWORK_NAME.SUBNETMASK, '[0-9]+', 1, 1))) = TO_NUMBER (REGEXP_SUBSTR (NETWORK_NAME.IP, '[0-9]+', 1, 1)) AND
		        BITAND(TO_NUMBER (REGEXP_SUBSTR (IPS.IP, '[0-9]+', 1, 2)), TO_NUMBER (REGEXP_SUBSTR (NETWORK_NAME.SUBNETMASK, '[0-9]+', 1, 2))) = TO_NUMBER (REGEXP_SUBSTR (NETWORK_NAME.IP, '[0-9]+', 1, 2)) AND
		        BITAND(TO_NUMBER (REGEXP_SUBSTR (IPS.IP, '[0-9]+', 1, 3)), TO_NUMBER (REGEXP_SUBSTR (NETWORK_NAME.SUBNETMASK, '[0-9]+', 1, 3))) = TO_NUMBER (REGEXP_SUBSTR (NETWORK_NAME.IP, '[0-9]+', 1, 3)) AND
		        BITAND(TO_NUMBER (REGEXP_SUBSTR (IPS.IP, '[0-9]+', 1, 4)), TO_NUMBER (REGEXP_SUBSTR (NETWORK_NAME.SUBNETMASK, '[0-9]+', 1, 4))) = TO_NUMBER (REGEXP_SUBSTR (NETWORK_NAME.IP, '[0-9]+', 1, 4))  
		  ) 
		  GROUP BY ID
		  ORDER BY 	TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 1))	ASC
		            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 2))	ASC
		            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 3))	ASC
		            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 4))	ASC,
					TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 1))	ASC
		            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 2))	ASC
		            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 3))	ASC
		            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 4))	ASC
		            );
        -- list Storage Nodes
        select
                CASE
                        WHEN ROWNUM<10 THEN 'sn_nodes_0'||ROWNUM||'='||ip
                        ELSE 'sn_nodes_'||TO_CHAR(ROWNUM)||'='||ip
                END AS ip2 FROM        
     		(
          SELECT distinct C.ID, A.IPADDRESS AS IP, e.opstatus FROM EMOC.VDO_INTERFACE_INFO A, VMB_OPERATIN_SYSTEM_INTERINFOS B,  VMB_INSTANCE C, VDO_COMPONENT_INFO e, vdo_interface_info f
          Where A.Id=B.Interinfos_Id And B.Id=C.Id And Upper(C.Classname) Like '%STORAGE%' And A.Ipaddress Is Not Null And A.Ipaddress <> '0.0.0.0'
          And B.Interinfos_Id=E.Id And E.Id=F.Id And (Lower(E.Opstatus)='up')
          order by TO_NUMBER (REGEXP_SUBSTR (IP, '[0-9]+', 1, 1))	ASC
		            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP, '[0-9]+', 1, 2))	ASC
		            ,     	  To_Number (Regexp_Substr (Ip, '[0-9]+', 1, 3))	Asc
		            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP, '[0-9]+', 1, 4))	ASC
        ) order by rownum;
        -- list Infiniband Switches
        select
                CASE
                        WHEN ROWNUM<10 THEN 'ib_switch_0'||ROWNUM||'='||ip
                        ELSE 'ib_switch_'||TO_CHAR(ROWNUM)||'='||ip
                END AS ip2 FROM
                (select trim(mgmtipaddr) as ip from VMB_SWITCH where (model like '%InfiniBand Switch%GW' or model like '%InfiniBand Gateway Switch%') order by mgmtipaddr) order by rownum;
        -- list Spine Infiniband Switches
        select
                CASE
                        WHEN ROWNUM<10 THEN 'ib_switch_spine_0'||ROWNUM||'='||ip
                        ELSE 'ib_switch_spine_'||TO_CHAR(ROWNUM)||'='||ip
                END AS ip2 FROM
        --'%Infiniband Switch%36' is changed to '%InfiniBand Switch%036' to avoid getting the information        
                (select trim(mgmtipaddr) as ip from VMB_SWITCH where model like '%InfiniBand Switch%036' order by mgmtipaddr) order by rownum;
        -- list ILOM of Compute Nodes
        select
                CASE
                        WHEN ROWNUM<10 THEN 'cn_ilom_0'||ROWNUM||'='||ip
                        ELSE 'cn_ilom_'||TO_CHAR(ROWNUM)||'='||ip
                END AS ip2 FROM
		(select trim(ipaddress) as ip from vdo_ether_port_info where description like '%management port%' and id in (
			SELECT ETHPORINF_ID AS ID FROM VMB_SERVER_ETHPORINF WHERE ID IN (
				SELECT ID FROM VMB_SERVER WHERE UPPER(MODEL) LIKE '%SERVER%' )) ORDER BY IPADDRESS) order by rownum;
        -- list ILOM of Storage Nodes
        select
                CASE
                        WHEN ROWNUM<10 THEN 'sn_ilom_0'||ROWNUM||'='||ip
                        ELSE 'sn_ilom_'||TO_CHAR(ROWNUM)||'='||ip
                END AS ip2 FROM        
		(select trim(ipaddress) as ip from vdo_ether_port_info where description like '%sp%' and id in (
			select ethporinf_id as id from vmb_server_ethporinf where id in (
				select id from vmb_server where UPPER(MODEL) LIKE '%STORAGE%' )) order by ipaddress) order by rownum;
        -- list PDUs
        select
                CASE
                        WHEN ROWNUM<10 THEN 'pdu_ip_0'||ROWNUM||'='||ip
                        ELSE 'pdu_ip_'||TO_CHAR(ROWNUM)||'='||ip
                END AS ip2 FROM        
        	(select trim(managemeip) as ip from vmb_pdu order by managemeip) order by rownum;
        -- list OVM Manager
        select
                CASE
                        WHEN ROWNUM<10 THEN 'ovmm_ip_0'||ROWNUM||'='||ip
                        ELSE 'ovmm_ip_'||TO_CHAR(ROWNUM)||'='||ip
                END AS ip2 FROM        
        	(select trim(managaddre) as ip from vmb_ovm_manager order by managaddre) order by rownum;
        -- list Exalogic Control DB
        -- select 'db_ip_01='||trim(utl_inaddr.GET_HOST_ADDRESS(host_name)) as ip2 from v$instance;

