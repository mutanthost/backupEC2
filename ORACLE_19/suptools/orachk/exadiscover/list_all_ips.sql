SELECT * FROM (
SELECT '     ' as col1,
  MAX(DECODE ( NAMEIDX , 1, NAME )) IP1,
  MAX(DECODE ( NAMEIDX , 2, NAME )) IP2,
  MAX(DECODE ( NAMEIDX , 3, NAME )) ip3,
  MAX(DECODE ( NAMEIDX , 4, NAME )) IP4,
  MAX(DECODE ( NAMEIDX , 5, NAME )) IP5,
  MAX(DECODE ( NAMEIDX , 6, NAME )) IP6,
  MAX(DECODE ( NAMEIDX , 7, NAME )) IP7,
  MAX(DECODE ( NAMEIDX , 8, NAME )) IP8,
  'Hostname' as hostname
FROM
   (   SELECT 1 as id, NAME, IP, SUBNETMASK, ROWNUM AS NAMEIDX FROM
          (SELECT B.USEFRINAM as name, A.IPADDRESS as ip, a.SUBNETMASK as subnetmask
          FROM VMB_NETWORK A, VMB_MANAGED_RESOURC B 
          WHERE 
            A.ID=B.ID AND
            (upper(B.USEFRINAM) in ('EOIB-EXTERNAL-MGMT', 'IPOIB-VIRT-ADMIN', 'IPOIB-VSERVER-SHARED-STORAGE', 'IPOIB-ADMIN', 'IPOIB-STORAGE', 'IPOIB-OVM-MGMT', 'IPOIB-DEFAULT') OR UPPER(B.USEFRINAM) LIKE '%ETH-ADMIN%')
            ORDER BY  TO_NUMBER (REGEXP_SUBSTR (A.IPADDRESS, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (A.IPADDRESS, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (A.IPADDRESS, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (A.IPADDRESS, '[0-9]+', 1, 4))	ASC)
    )
GROUP BY ID 
) 
UNION
SELECT
  CASE
    WHEN ROWNUM<10 THEN 'ec_0'||ROWNUM
    ELSE 'ec_'||TO_CHAR(ROWNUM)
  END as col1,
  ip1,ip2,ip3,ip4,ip5,ip6,ip7,ip8, b.hostname
FROM (
SELECT
  LISTAGG(DECODE(NAMEIDX, 1, IP),',') within group (order by ip) IP1, 
  LISTAGG(DECODE(NAMEIDX, 2, IP),',') within group (order by ip) IP2,
  LISTAGG(DECODE(NAMEIDX, 3, IP),',') within group (order by ip) IP3,
  LISTAGG(DECODE(NAMEIDX, 4, IP),',') within group (order by ip) IP4,
  LISTAGG(DECODE(NAMEIDX, 5, IP),',') within group (order by ip) IP5,
  LISTAGG(DECODE(NAMEIDX, 6, IP),',') WITHIN GROUP (ORDER BY IP) IP6,
  LISTAGG(DECODE(NAMEIDX, 7, IP),',') within group (order by ip) IP7,
  LISTAGG(DECODE(NAMEIDX, 8, IP),',') within group (order by ip) IP8,
  id
FROM
  (SELECT ips.ID, ips.IP, network_name.name, network_name.nameidx FROM
        (SELECT c.id, A.IPADDRESS AS IP FROM EMOC.VDO_INTERFACE_INFO A, VMB_OPERATIN_SYSTEM_INTERINFOS B,  VMB_INSTANCE C
			WHERE a.id=b.INTERINFOS_ID and b.id=c.id and c.CANONICAL LIKE 'com.sun.hss.domain:name=NORM-%-EC,type=OperatingSystem' and a.ipaddress is not null 
			order by ipmpgrp) IPS,
        (
        SELECT NAME, IP, SUBNETMASK, ROWNUM AS NAMEIDX FROM
          (SELECT B.USEFRINAM as name, A.IPADDRESS as ip, a.SUBNETMASK as subnetmask
          FROM VMB_NETWORK A, VMB_MANAGED_RESOURC B 
          WHERE 
            A.ID=B.ID AND
            (upper(B.USEFRINAM) in ('EOIB-EXTERNAL-MGMT', 'IPOIB-VIRT-ADMIN', 'IPOIB-VSERVER-SHARED-STORAGE', 'IPOIB-ADMIN', 'IPOIB-STORAGE', 'IPOIB-OVM-MGMT', 'IPOIB-DEFAULT') OR UPPER(B.USEFRINAM) LIKE '%ETH-ADMIN%')
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
  ORDER BY 	TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 4))	ASC,
			TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 4))	ASC
  ) a, VMB_OPERATIN_SYSTEM b
  where a.id=b.id
UNION
SELECT
  CASE
    WHEN ROWNUM<10 THEN 'pc_0'||ROWNUM
    ELSE 'pc_'||TO_CHAR(ROWNUM)
  END as col1,
  ip1,ip2,ip3,ip4,ip5,ip6,ip7,ip8, b.hostname as hostname
FROM (
SELECT
  LISTAGG(DECODE(NAMEIDX, 1, IP),',') within group (order by ip) IP1, 
  LISTAGG(DECODE(NAMEIDX, 2, IP),',') within group (order by ip) IP2,
  LISTAGG(DECODE(NAMEIDX, 3, IP),',') within group (order by ip) IP3,
  LISTAGG(DECODE(NAMEIDX, 4, IP),',') within group (order by ip) IP4,
  LISTAGG(DECODE(NAMEIDX, 5, IP),',') within group (order by ip) IP5,
  LISTAGG(DECODE(NAMEIDX, 6, IP),',') WITHIN GROUP (ORDER BY IP) IP6,
  LISTAGG(DECODE(NAMEIDX, 7, IP),',') within group (order by ip) IP7,
  LISTAGG(DECODE(NAMEIDX, 8, IP),',') within group (order by ip) IP8,
  id
FROM
  (SELECT ips.ID, ips.IP, network_name.name, network_name.nameidx FROM
        (SELECT C.ID, A.IPADDRESS AS IP FROM EMOC.VDO_INTERFACE_INFO A, VMB_OPERATIN_SYSTEM_INTERINFOS B,  VMB_INSTANCE C
			WHERE A.ID=B.INTERINFOS_ID AND B.ID=C.ID AND C.CANONICAL LIKE 'com.sun.hss.domain:name=NORM-%-PC,type=OperatingSystem' AND A.IPADDRESS IS NOT NULL 
			order by ipmpgrp) IPS,
        (
        SELECT NAME, IP, SUBNETMASK, ROWNUM AS NAMEIDX FROM
          (SELECT B.USEFRINAM as name, A.IPADDRESS as ip, a.SUBNETMASK as subnetmask
          FROM VMB_NETWORK A, VMB_MANAGED_RESOURC B 
          WHERE 
            A.ID=B.ID AND
            (upper(B.USEFRINAM) in ('EOIB-EXTERNAL-MGMT', 'IPOIB-VIRT-ADMIN', 'IPOIB-VSERVER-SHARED-STORAGE', 'IPOIB-ADMIN', 'IPOIB-STORAGE', 'IPOIB-OVM-MGMT', 'IPOIB-DEFAULT') OR UPPER(B.USEFRINAM) LIKE '%ETH-ADMIN%')
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
  ORDER BY 	TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 4))	ASC,
			TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 4))	ASC
  ) a, VMB_OPERATIN_SYSTEM b
  where a.id=b.id
UNION
SELECT
  CASE
    WHEN ROWNUM<10 THEN 'c_nodes_0'||ROWNUM
    ELSE 'c_nodes_'||TO_CHAR(ROWNUM)
  END as col1,
  ip1,ip2,ip3,ip4,ip5,ip6,ip7,ip8, b.v as hostname
FROM (
SELECT
  LISTAGG(DECODE(NAMEIDX, 1, IP),',') within group (order by ip) IP1, 
  LISTAGG(DECODE(NAMEIDX, 2, IP),',') within group (order by ip) IP2,
  LISTAGG(DECODE(NAMEIDX, 3, IP),',') within group (order by ip) IP3,
  LISTAGG(DECODE(NAMEIDX, 4, IP),',') within group (order by ip) IP4,
  LISTAGG(DECODE(NAMEIDX, 5, IP),',') within group (order by ip) IP5,
  LISTAGG(DECODE(NAMEIDX, 6, IP),',') WITHIN GROUP (ORDER BY IP) IP6,
  LISTAGG(DECODE(NAMEIDX, 7, IP),',') within group (order by ip) IP7,
  LISTAGG(DECODE(NAMEIDX, 8, IP),',') within group (order by ip) IP8,
  id
FROM
  (SELECT ips.ID, ips.IP, network_name.name, network_name.nameidx FROM
        (SELECT c.ID as id, A.IPADDRESS as ip FROM VDO_ETHER_PORT_INFO A, VMB_SERVER_ETHPORINF B, VMB_SERVER C
        	WHERE A.IPADDRESS IS NOT NULL AND A.ID = B.ETHPORINF_ID AND B.ID = C.ID AND upper(C.MODEL) LIKE '%VIRTUAL%MACHINE%'
        	ORDER BY A.IPADDRESS, C.ID) IPS,
        (
        SELECT NAME, IP, SUBNETMASK, ROWNUM AS NAMEIDX FROM
          (SELECT B.USEFRINAM as name, A.IPADDRESS as ip, a.SUBNETMASK as subnetmask
          FROM VMB_NETWORK A, VMB_MANAGED_RESOURC B 
          WHERE 
            A.ID=B.ID AND
            (upper(B.USEFRINAM) in ('EOIB-EXTERNAL-MGMT', 'IPOIB-VIRT-ADMIN', 'IPOIB-VSERVER-SHARED-STORAGE', 'IPOIB-ADMIN', 'IPOIB-STORAGE', 'IPOIB-OVM-MGMT', 'IPOIB-DEFAULT') OR UPPER(B.USEFRINAM) LIKE '%ETH-ADMIN%')
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
  ORDER BY 	TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 4))	ASC,
			TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 4))	ASC
  ) a,
  VMB_RESOURCE_RESANNMAP b
  where
    a.id=B.id and B.K='AltHostname'  
UNION
SELECT
  CASE
    WHEN ROWNUM<10 THEN 'sn_nodes_0'||ROWNUM
    ELSE 'sn_nodes_'||TO_CHAR(ROWNUM)
  END as col1,
  ip1,ip2,ip3,ip4,ip5,ip6,ip7,ip8, b.hostname as hostname
FROM (
SELECT
  LISTAGG(DECODE(NAMEIDX, 1, IP),',') within group (order by ip) IP1, 
  LISTAGG(DECODE(NAMEIDX, 2, IP),',') within group (order by ip) IP2,
  LISTAGG(DECODE(NAMEIDX, 3, IP),',') within group (order by ip) IP3,
  LISTAGG(DECODE(NAMEIDX, 4, IP),',') within group (order by ip) IP4,
  LISTAGG(DECODE(NAMEIDX, 5, IP),',') within group (order by ip) IP5,
  LISTAGG(DECODE(NAMEIDX, 6, IP),',') WITHIN GROUP (ORDER BY IP) IP6,
  LISTAGG(DECODE(NAMEIDX, 7, IP),',') within group (order by ip) IP7,
  LISTAGG(DECODE(NAMEIDX, 8, IP),',') within group (order by ip) IP8,
  id
FROM
  (SELECT ips.ID, ips.IP, network_name.name, network_name.nameidx FROM
        (SELECT distinct C.ID, A.IPADDRESS AS IP, e.opstatus FROM EMOC.VDO_INTERFACE_INFO A, VMB_OPERATIN_SYSTEM_INTERINFOS B,  VMB_INSTANCE C, VDO_COMPONENT_INFO e, vdo_interface_info f
          Where A.Id=B.Interinfos_Id And B.Id=C.Id And Upper(C.Classname) Like '%STORAGE%' And A.Ipaddress Is Not Null And A.Ipaddress <> '0.0.0.0'
          And b.Interinfos_Id=E.Id And E.Id=F.Id and (lower(e.opstatus)='up' or e.opstatus is null)
          order by c.id, a.ipaddress) IPS,
        (
        SELECT NAME, IP, SUBNETMASK, ROWNUM AS NAMEIDX FROM
          (SELECT B.USEFRINAM as name, A.IPADDRESS as ip, a.SUBNETMASK as subnetmask
          FROM VMB_NETWORK A, VMB_MANAGED_RESOURC B 
          WHERE 
            A.ID=B.ID AND
            (upper(B.USEFRINAM) in ('EOIB-EXTERNAL-MGMT', 'IPOIB-VIRT-ADMIN', 'IPOIB-VSERVER-SHARED-STORAGE', 'IPOIB-ADMIN', 'IPOIB-STORAGE', 'IPOIB-OVM-MGMT', 'IPOIB-DEFAULT') OR UPPER(B.USEFRINAM) LIKE '%ETH-ADMIN%')
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
  ORDER BY 	TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 4))	ASC,
			TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 2))	ASC
            ,     	  To_Number (Regexp_Substr (Ip8, '[0-9]+', 1, 3))	Asc
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 4))	ASC
  ) a, VMB_OPERATIN_SYSTEM b
  where a.id=b.id
UNION
SELECT
  CASE
    WHEN ROWNUM<10 THEN 'ovmm_0'||ROWNUM
    ELSE 'ovmm_'||TO_CHAR(ROWNUM)
  END as col1,
  ip1,ip2,ip3,ip4,ip5,ip6,ip7,ip8, '' as hostname
FROM (
SELECT
  LISTAGG(DECODE(NAMEIDX, 1, IP),',') within group (order by ip) IP1, 
  LISTAGG(DECODE(NAMEIDX, 2, IP),',') within group (order by ip) IP2,
  LISTAGG(DECODE(NAMEIDX, 3, IP),',') within group (order by ip) IP3,
  LISTAGG(DECODE(NAMEIDX, 4, IP),',') within group (order by ip) IP4,
  LISTAGG(DECODE(NAMEIDX, 5, IP),',') within group (order by ip) IP5,
  LISTAGG(DECODE(NAMEIDX, 6, IP),',') WITHIN GROUP (ORDER BY IP) IP6,
  LISTAGG(DECODE(NAMEIDX, 7, IP),',') within group (order by ip) IP7,
  LISTAGG(DECODE(NAMEIDX, 8, IP),',') within group (order by ip) IP8
FROM
  (SELECT IPS.ID, IPS.IP, NETWORK_NAME.NAME, NETWORK_NAME.NAMEIDX FROM
        (
        	with NUMS as (select rownum RN from (select 1,2,3 from DUAL group by cube (1, 2, 3, 4)) where rownum <= ovm_ips_num)
			select 1 as id, decode(rn, ovm_ip_cols) as ip from (SELECT ovm_ips_value FROM DUAL) lists, nums
        ) IPS,
        (
        SELECT NAME, IP, SUBNETMASK, ROWNUM AS NAMEIDX FROM
          (SELECT B.USEFRINAM as name, A.IPADDRESS as ip, a.SUBNETMASK as subnetmask
          FROM VMB_NETWORK A, VMB_MANAGED_RESOURC B 
          WHERE 
            A.ID=B.ID AND
            (upper(B.USEFRINAM) in ('EOIB-EXTERNAL-MGMT', 'IPOIB-VIRT-ADMIN', 'IPOIB-VSERVER-SHARED-STORAGE', 'IPOIB-ADMIN', 'IPOIB-STORAGE', 'IPOIB-OVM-MGMT', 'IPOIB-DEFAULT') OR UPPER(B.USEFRINAM) LIKE '%ETH-ADMIN%')
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
  ORDER BY 	TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 4))	ASC,
			TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 4))	ASC)
UNION
SELECT
  CASE
    WHEN ROWNUM<10 THEN 'pdu_0'||ROWNUM
    ELSE 'pdu_'||TO_CHAR(ROWNUM)
  END as col1,
  ip1,ip2,ip3,ip4,ip5,ip6,ip7,ip8, '' as hostname
FROM (
SELECT
  LISTAGG(DECODE(NAMEIDX, 1, IP),',') within group (order by ip) IP1, 
  LISTAGG(DECODE(NAMEIDX, 2, IP),',') within group (order by ip) IP2,
  LISTAGG(DECODE(NAMEIDX, 3, IP),',') within group (order by ip) IP3,
  LISTAGG(DECODE(NAMEIDX, 4, IP),',') within group (order by ip) IP4,
  LISTAGG(DECODE(NAMEIDX, 5, IP),',') within group (order by ip) IP5,
  LISTAGG(DECODE(NAMEIDX, 6, IP),',') WITHIN GROUP (ORDER BY IP) IP6,
  LISTAGG(DECODE(NAMEIDX, 7, IP),',') within group (order by ip) IP7,
  LISTAGG(DECODE(NAMEIDX, 8, IP),',') within group (order by ip) IP8
FROM
  (SELECT IPS.ID, IPS.IP, NETWORK_NAME.NAME, NETWORK_NAME.NAMEIDX FROM
        (select id, trim(managemeip) as ip from vmb_pdu order by managemeip) IPS,
        (
        SELECT NAME, IP, SUBNETMASK, ROWNUM AS NAMEIDX FROM
          (SELECT B.USEFRINAM as name, A.IPADDRESS as ip, a.SUBNETMASK as subnetmask
          FROM VMB_NETWORK A, VMB_MANAGED_RESOURC B 
          WHERE 
            A.ID=B.ID AND
            (upper(B.USEFRINAM) in ('EOIB-EXTERNAL-MGMT', 'IPOIB-VIRT-ADMIN', 'IPOIB-VSERVER-SHARED-STORAGE', 'IPOIB-ADMIN', 'IPOIB-STORAGE', 'IPOIB-OVM-MGMT', 'IPOIB-DEFAULT') OR UPPER(B.USEFRINAM) LIKE '%ETH-ADMIN%')
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
  ORDER BY 	TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 4))	ASC,
			TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 4))	ASC)            
UNION
SELECT
  CASE
    WHEN ROWNUM<10 THEN 'sn_ilom_0'||ROWNUM
    ELSE 'sn_ilom_'||TO_CHAR(ROWNUM)
  END as col1,
  ip1,ip2,ip3,ip4,ip5,ip6,ip7,ip8, b.name as hostname
FROM (
SELECT
  LISTAGG(DECODE(NAMEIDX, 1, IP),',') within group (order by ip) IP1, 
  LISTAGG(DECODE(NAMEIDX, 2, IP),',') within group (order by ip) IP2,
  LISTAGG(DECODE(NAMEIDX, 3, IP),',') within group (order by ip) IP3,
  LISTAGG(DECODE(NAMEIDX, 4, IP),',') within group (order by ip) IP4,
  LISTAGG(DECODE(NAMEIDX, 5, IP),',') within group (order by ip) IP5,
  LISTAGG(DECODE(NAMEIDX, 6, IP),',') WITHIN GROUP (ORDER BY IP) IP6,
  LISTAGG(DECODE(NAMEIDX, 7, IP),',') within group (order by ip) IP7,
  LISTAGG(DECODE(NAMEIDX, 8, IP),',') within group (order by ip) IP8,
  id
FROM
  (SELECT IPS.ID, IPS.IP, NETWORK_NAME.NAME, NETWORK_NAME.NAMEIDX FROM
        (select c.id, trim(ipaddress) as ip from vdo_ether_port_info a, vmb_server_ethporinf b, vmb_server c
          where a.DESCRIPTION like '%sp%' and a.id=B.ETHPORINF_ID and B.id=C.id and UPPER(C.model) like '%STORAGE%' 
          order by a.ipaddress) IPS,
        (
        SELECT NAME, IP, SUBNETMASK, ROWNUM AS NAMEIDX FROM
          (SELECT B.USEFRINAM as name, A.IPADDRESS as ip, a.SUBNETMASK as subnetmask
          FROM VMB_NETWORK A, VMB_MANAGED_RESOURC B 
          WHERE 
            A.ID=B.ID AND
            (upper(B.USEFRINAM) in ('EOIB-EXTERNAL-MGMT', 'IPOIB-VIRT-ADMIN', 'IPOIB-VSERVER-SHARED-STORAGE', 'IPOIB-ADMIN', 'IPOIB-STORAGE', 'IPOIB-OVM-MGMT', 'IPOIB-DEFAULT') OR UPPER(B.USEFRINAM) LIKE '%ETH-ADMIN%')
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
  ORDER BY 	TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 4))	ASC,
			TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 4))	ASC
  ) a, VDO_COMPONENT_INFO B, VMB_SERVER_SEPRINSE C
  where a.id=c.id and b.id=c.SEPRINSE_ID
UNION
SELECT
  CASE
    WHEN ROWNUM<10 THEN 'cn_ilom_0'||ROWNUM
    ELSE 'cn_ilom_'||TO_CHAR(ROWNUM)
  END as col1,
  ip1,ip2,ip3,ip4,ip5,ip6,ip7,ip8, b.name as hostname
FROM (
SELECT
  LISTAGG(DECODE(NAMEIDX, 1, IP),',') within group (order by ip) IP1, 
  LISTAGG(DECODE(NAMEIDX, 2, IP),',') within group (order by ip) IP2,
  LISTAGG(DECODE(NAMEIDX, 3, IP),',') within group (order by ip) IP3,
  LISTAGG(DECODE(NAMEIDX, 4, IP),',') within group (order by ip) IP4,
  LISTAGG(DECODE(NAMEIDX, 5, IP),',') within group (order by ip) IP5,
  LISTAGG(DECODE(NAMEIDX, 6, IP),',') WITHIN GROUP (ORDER BY IP) IP6,
  LISTAGG(DECODE(NAMEIDX, 7, IP),',') within group (order by ip) IP7,
  LISTAGG(DECODE(NAMEIDX, 8, IP),',') within group (order by ip) IP8,
  id
FROM
  (SELECT IPS.ID, IPS.IP, NETWORK_NAME.NAME, NETWORK_NAME.NAMEIDX FROM
        (select C.id, TRIM(IPADDRESS) as IP from VDO_ETHER_PORT_INFO a, VMB_SERVER_ETHPORINF B, VMB_SERVER C
          where a.DESCRIPTION like '%management port%' and a.id=B.ETHPORINF_ID and B.id=C.id and UPPER(C.model) like '%SERVER%' 
          order by a.ipaddress) IPS,
        (
        SELECT NAME, IP, SUBNETMASK, ROWNUM AS NAMEIDX FROM
          (SELECT B.USEFRINAM as name, A.IPADDRESS as ip, a.SUBNETMASK as subnetmask
          FROM VMB_NETWORK A, VMB_MANAGED_RESOURC B 
          WHERE 
            A.ID=B.ID AND
            (upper(B.USEFRINAM) in ('EOIB-EXTERNAL-MGMT', 'IPOIB-VIRT-ADMIN', 'IPOIB-VSERVER-SHARED-STORAGE', 'IPOIB-ADMIN', 'IPOIB-STORAGE', 'IPOIB-OVM-MGMT', 'IPOIB-DEFAULT') OR UPPER(B.USEFRINAM) LIKE '%ETH-ADMIN%')
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
  ORDER BY 	TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 4))	ASC,
			TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 4))	ASC
  ) a, VDO_COMPONENT_INFO B, VMB_SERVER_SEPRINSE C
  where a.id=c.id and b.id=c.SEPRINSE_ID                   
UNION
SELECT
  CASE
    WHEN ROWNUM<10 THEN 'ib_switch_0'||ROWNUM
    ELSE 'ib_switch_'||TO_CHAR(ROWNUM)
  END as col1,
  ip1,ip2,ip3,ip4,ip5,ip6,ip7,ip8, b.host as hostname
FROM (
SELECT
  LISTAGG(DECODE(NAMEIDX, 1, IP),',') within group (order by ip) IP1, 
  LISTAGG(DECODE(NAMEIDX, 2, IP),',') within group (order by ip) IP2,
  LISTAGG(DECODE(NAMEIDX, 3, IP),',') within group (order by ip) IP3,
  LISTAGG(DECODE(NAMEIDX, 4, IP),',') within group (order by ip) IP4,
  LISTAGG(DECODE(NAMEIDX, 5, IP),',') within group (order by ip) IP5,
  LISTAGG(DECODE(NAMEIDX, 6, IP),',') WITHIN GROUP (ORDER BY IP) IP6,
  LISTAGG(DECODE(NAMEIDX, 7, IP),',') within group (order by ip) IP7,
  LISTAGG(DECODE(NAMEIDX, 8, IP),',') within group (order by ip) IP8,
  id
FROM
  (SELECT IPS.ID, IPS.IP, NETWORK_NAME.NAME, NETWORK_NAME.NAMEIDX FROM
        (select id, trim(mgmtipaddr) as ip from VMB_SWITCH where (model like '%InfiniBand Switch%GW' or model like '%InfiniBand Gateway Switch%') order by mgmtipaddr) IPS,
        (
        SELECT NAME, IP, SUBNETMASK, ROWNUM AS NAMEIDX FROM
          (SELECT B.USEFRINAM as name, A.IPADDRESS as ip, a.SUBNETMASK as subnetmask
          FROM VMB_NETWORK A, VMB_MANAGED_RESOURC B 
          WHERE 
            A.ID=B.ID AND
            (upper(B.USEFRINAM) in ('EOIB-EXTERNAL-MGMT', 'IPOIB-VIRT-ADMIN', 'IPOIB-VSERVER-SHARED-STORAGE', 'IPOIB-ADMIN', 'IPOIB-STORAGE', 'IPOIB-OVM-MGMT', 'IPOIB-DEFAULT') OR UPPER(B.USEFRINAM) LIKE '%ETH-ADMIN%')
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
  ORDER BY 	TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 4))	ASC,
			TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 4))	ASC
  ) a, VMB_SERVICE_TAG B
  where a.id=b.id(+)  
UNION
SELECT
  CASE
    WHEN ROWNUM<10 THEN 'db_0'||ROWNUM
    ELSE 'db_'||TO_CHAR(ROWNUM)
  END as col1,
  ip1,ip2,ip3,ip4,ip5,ip6,ip7,ip8, '' as hostname
FROM (
SELECT
  LISTAGG(DECODE(NAMEIDX, 1, IP),',') within group (order by ip) IP1, 
  LISTAGG(DECODE(NAMEIDX, 2, IP),',') within group (order by ip) IP2,
  LISTAGG(DECODE(NAMEIDX, 3, IP),',') within group (order by ip) IP3,
  LISTAGG(DECODE(NAMEIDX, 4, IP),',') within group (order by ip) IP4,
  LISTAGG(DECODE(NAMEIDX, 5, IP),',') within group (order by ip) IP5,
  LISTAGG(DECODE(NAMEIDX, 6, IP),',') WITHIN GROUP (ORDER BY IP) IP6,
  LISTAGG(DECODE(NAMEIDX, 7, IP),',') within group (order by ip) IP7,
  LISTAGG(DECODE(NAMEIDX, 8, IP),',') within group (order by ip) IP8
FROM
  (SELECT IPS.ID, IPS.IP, NETWORK_NAME.NAME, NETWORK_NAME.NAMEIDX FROM
        (select 1 as id, '192.168.20.10' as ip from dual) IPS,
        (
        SELECT NAME, IP, SUBNETMASK, ROWNUM AS NAMEIDX FROM
          (SELECT B.USEFRINAM as name, A.IPADDRESS as ip, a.SUBNETMASK as subnetmask
          FROM VMB_NETWORK A, VMB_MANAGED_RESOURC B 
          WHERE 
            A.ID=B.ID AND
            (upper(B.USEFRINAM) in ('EOIB-EXTERNAL-MGMT', 'IPOIB-VIRT-ADMIN', 'IPOIB-VSERVER-SHARED-STORAGE', 'IPOIB-ADMIN', 'IPOIB-STORAGE', 'IPOIB-OVM-MGMT', 'IPOIB-DEFAULT') OR UPPER(B.USEFRINAM) LIKE '%ETH-ADMIN%')
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
  ORDER BY 	TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP1, '[0-9]+', 1, 4))	ASC,
			TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP2, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP3, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP4, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP5, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP6, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP7, '[0-9]+', 1, 4))	ASC,
            TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 1))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 2))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 3))	ASC
            ,     	  TO_NUMBER (REGEXP_SUBSTR (IP8, '[0-9]+', 1, 4))	ASC)  
ORDER BY 1
;


