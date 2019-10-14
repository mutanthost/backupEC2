#!/usr/bin/env python

import os
import sys

class ExaDiscover:
    
    def __init__(self, rack_name=None, rack_size=None, exa_ec_ip=None, exa_pc_ip=None, 
                 cnodes_ip=None, snodes_ip=None, ibsw_ip=None, ibsw_spine_ip=None, cnodes_ilom_ip=None, 
                 snodes_ilom_ip=None, pdu_ip=None, exa_ovmm_ip=None, exa_db_ip=None):
        self.__rack_name=rack_name
        self.__rack_size=rack_size
        self.__exa_ec_ip=exa_ec_ip
        self.__exa_pc_ip=exa_pc_ip
        self.__cnodes_ip=cnodes_ip
        self.__snodes_ip=snodes_ip
        self.__ibsw_ip=ibsw_ip
        self.__ibsw_spine_ip=ibsw_spine_ip
        self.__cnodes_ilom_ip=cnodes_ilom_ip
        self.__snodes_ilom_ip=snodes_ilom_ip
        self.__pdu_ip=pdu_ip
        self.__exa_ovmm_ip=exa_ovmm_ip
        self.__exa_db_ip=exa_db_ip

    def get_rack_name(self):
        return self.__rack_name


    def get_rack_size(self):
        return self.__rack_size


    def get_exa_ec_ip(self):
        return self.__exa_ec_ip


    def get_exa_pc_ip(self):
        return self.__exa_pc_ip


    def get_cnodes_ip(self):
        return self.__cnodes_ip


    def get_snodes_ip(self):
        return self.__snodes_ip


    def get_ibsw_ip(self):
        return self.__ibsw_ip


    def get_ibsw_spine_ip(self):
        return self.__ibsw_spine_ip


    def get_cnodes_ilom_ip(self):
        return self.__cnodes_ilom_ip


    def get_snodes_ilom_ip(self):
        return self.__snodes_ilom_ip


    def get_pdu_ip(self):
        return self.__pdu_ip


    def get_exa_ovmm_ip(self):
        return self.__exa_ovmm_ip


    def get_exa_db_ip(self):
        return self.__exa_db_ip


    def set_rack_name(self, value):
        self.__rack_name = value


    def set_rack_size(self, value):
        self.__rack_size = value


    def set_exa_ec_ip(self, value):
        self.__exa_ec_ip = value


    def set_exa_pc_ip(self, value):
        self.__exa_pc_ip = value


    def set_cnodes_ip(self, value):
        self.__cnodes_ip = value


    def set_snodes_ip(self, value):
        self.__snodes_ip = value


    def set_ibsw_ip(self, value):
        self.__ibsw_ip = value


    def set_ibsw_spine_ip(self, value):
        self.__ibsw_spine_ip = value


    def set_cnodes_ilom_ip(self, value):
        self.__cnodes_ilom_ip = value


    def set_snodes_ilom_ip(self, value):
        self.__snodes_ilom_ip = value


    def set_pdu_ip(self, value):
        self.__pdu_ip = value


    def set_exa_ovmm_ip(self, value):
        self.__exa_ovmm_ip = value


    def set_exa_db_ip(self, value):
        self.__exa_db_ip = value


    def del_rack_name(self):
        del self.__rack_name


    def del_rack_size(self):
        del self.__rack_size


    def del_exa_ec_ip(self):
        del self.__exa_ec_ip


    def del_exa_pc_ip(self):
        del self.__exa_pc_ip


    def del_cnodes_ip(self):
        del self.__cnodes_ip


    def del_snodes_ip(self):
        del self.__snodes_ip


    def del_ibsw_ip(self):
        del self.__ibsw_ip


    def del_ibsw_spine_ip(self):
        del self.__ibsw_spine_ip


    def del_cnodes_ilom_ip(self):
        del self.__cnodes_ilom_ip


    def del_snodes_ilom_ip(self):
        del self.__snodes_ilom_ip


    def del_pdu_ip(self):
        del self.__pdu_ip


    def del_exa_ovmm_ip(self):
        del self.__exa_ovmm_ip


    def del_exa_db_ip(self):
        del self.__exa_db_ip

    # if filename is not None, will be an offline mode
    def initShortList(self, filename=None):
        rack_name=[]
        rack_size=[]
        ec_ip=[]
        pc_ip=[]
        c_nodes=[]
        sn_nodes=[]
        ib_switch=[]
        ib_switch_spine=[]
        cn_ilom=[]
        sn_ilom=[]
        pdu_ip=[]
        ovmm_ip=[]
        db_ip=[]        
        
        asset_list=self.getIps(filename)
        for key in sorted(asset_list.keys()):
            if key.startswith('rack_name'):
                rack_name.append(asset_list[key])
            if key.startswith('rack_size'):
                rack_size.append(asset_list[key])
            if key.startswith('ec_ip'):
                ec_ip.append(asset_list[key])
            if key.startswith('pc_ip'):
                pc_ip.append(asset_list[key])
            if key.startswith('c_nodes'):
                c_nodes.append(asset_list[key])
            if key.startswith('sn_nodes'):
                sn_nodes.append(asset_list[key])
            if key.startswith('ib_switch') and key.find('spine')==-1:
                ib_switch.append(asset_list[key])
            if key.startswith('ib_switch_spine'):
                ib_switch_spine.append(asset_list[key])
            if key.startswith('cn_ilom'):
                cn_ilom.append(asset_list[key])
            if key.startswith('sn_ilom'):
                sn_ilom.append(asset_list[key])
            if key.startswith('pdu_ip'):
                pdu_ip.append(asset_list[key])
            if key.startswith('ovmm_ip'):
                ovmm_ip.append(asset_list[key])
            if key.startswith('db_ip'):
                db_ip.append(asset_list[key])
        
        self.set_rack_name(rack_name)
        self.set_rack_size(rack_size)
        self.set_exa_ec_ip(ec_ip)
        self.set_exa_pc_ip(pc_ip)
        self.set_cnodes_ip(c_nodes)
        self.set_snodes_ip(sn_nodes)                
        self.set_ibsw_ip(ib_switch)
        self.set_ibsw_spine_ip(ib_switch_spine)
        self.set_cnodes_ilom_ip(cn_ilom)
        self.set_snodes_ilom_ip(sn_ilom)
        self.set_pdu_ip(pdu_ip)
        self.set_exa_ovmm_ip(ovmm_ip)
        self.set_exa_db_ip(db_ip)
    
    
    def initFullList(self, filename=None):
        rack_name={}
        rack_size={}
        ec_ip={}
        pc_ip={}
        c_nodes={}
        sn_nodes={}
        ib_switch={}
        ib_switch_spine={}
        cn_ilom={}
        sn_ilom={}
        pdu_ip={}
        ovmm_ip={}
        db_ip={}        
        
        asset_list=self.getFullIps(filename)
        for key in sorted(asset_list.keys()):
            if key.startswith('rack_name'):
                rack_name[key]=asset_list[key]
            if key.startswith('rack_size'):
                rack_size[key]=asset_list[key]
            if key.startswith('ec_'):
                ec_ip[key]=asset_list[key]
            if key.startswith('pc_'):
                pc_ip[key]=asset_list[key]
            if key.startswith('c_nodes'):
                c_nodes[key]=asset_list[key]
            if key.startswith('sn_nodes'):
                sn_nodes[key]=asset_list[key]
            if key.startswith('ib_switch') and key.find('spine')==-1:
                ib_switch[key]=asset_list[key]
            if key.startswith('ib_switch_spine'):
                ib_switch_spine[key]=asset_list[key]
            if key.startswith('cn_ilom'):
                cn_ilom[key]=asset_list[key]
            if key.startswith('sn_ilom'):
                sn_ilom[key]=asset_list[key]
            if key.startswith('pdu_'):
                pdu_ip[key]=asset_list[key]
            if key.startswith('ovmm_'):
                ovmm_ip[key]=asset_list[key]
            if key.startswith('db_'):
                db_ip[key]=asset_list[key]
        
        self.set_rack_name(rack_name)
        self.set_rack_size(rack_size)
        self.set_exa_ec_ip(ec_ip)
        self.set_exa_pc_ip(pc_ip)
        self.set_cnodes_ip(c_nodes)
        self.set_snodes_ip(sn_nodes)                
        self.set_ibsw_ip(ib_switch)
        self.set_ibsw_spine_ip(ib_switch_spine)
        self.set_cnodes_ilom_ip(cn_ilom)
        self.set_snodes_ilom_ip(sn_ilom)
        self.set_pdu_ip(pdu_ip)
        self.set_exa_ovmm_ip(ovmm_ip)
        self.set_exa_db_ip(db_ip)        

    def printIps(self):
        print self.get_rack_name()
        print self.get_rack_size()
        print self.get_exa_ec_ip()
        print self.get_exa_pc_ip()
        print self.get_cnodes_ip()
        print self.get_snodes_ip()                
        print self.get_ibsw_ip()
        print self.get_ibsw_spine_ip()
        print self.get_cnodes_ilom_ip()
        print self.get_snodes_ilom_ip()
        print self.get_pdu_ip()
        print self.get_exa_ovmm_ip()
        print self.get_exa_db_ip()        

    # return a dictionary object
    def getIps(self, filename=None):
        results={}
        lines=None
        if filename:
            lines=open(filename)
        else:
            lines=os.popen('/bin/sh exadiscover.sh -f shell')
        for line in lines:
            pair=line.rstrip('\n').split('=')
            results[pair[0]]=pair[1]
        return results
    
    # return a dictionary object
    def getFullIps(self, filename=None):
        results={}
        lines=None
        if filename:
            lines=open(filename)
        else:
            lines=os.popen('/bin/sh exadiscover.sh -f shell -a')
        for line in lines:
            pair=line.rstrip('\n').split('=')
            results[pair[0]]=pair[1]
        return results
    
    # return a string list
    def getHumanReadable(self):
        results=[]
        lines=os.popen('/bin/sh exadiscover.sh')
        for line in lines:
            tmp=line.rstrip('\n')
            results.append(tmp)
        return results

    
    rack_name = property(get_rack_name, set_rack_name, del_rack_name, "rack_name's docstring")
    rack_size = property(get_rack_size, set_rack_size, del_rack_size, "rack_size's docstring")
    exa_ec_ip = property(get_exa_ec_ip, set_exa_ec_ip, del_exa_ec_ip, "exa_ec_ip's docstring")
    exa_pc_ip = property(get_exa_pc_ip, set_exa_pc_ip, del_exa_pc_ip, "exa_pc_ip's docstring")
    cnodes_ip = property(get_cnodes_ip, set_cnodes_ip, del_cnodes_ip, "cnodes_ip's docstring")
    snodes_ip = property(get_snodes_ip, set_snodes_ip, del_snodes_ip, "snodes_ip's docstring")
    ibsw_ip = property(get_ibsw_ip, set_ibsw_ip, del_ibsw_ip, "ibsw_ip's docstring")
    ibsw_spine_ip = property(get_ibsw_spine_ip, set_ibsw_spine_ip, del_ibsw_spine_ip, "ibsw_spine_ip's docstring")
    cnodes_ilom_ip = property(get_cnodes_ilom_ip, set_cnodes_ilom_ip, del_cnodes_ilom_ip, "cnodes_ilom_ip's docstring")
    snodes_ilom_ip = property(get_snodes_ilom_ip, set_snodes_ilom_ip, del_snodes_ilom_ip, "snodes_ilom_ip's docstring")
    pdu_ip = property(get_pdu_ip, set_pdu_ip, del_pdu_ip, "pdu_ip's docstring")
    exa_ovmm_ip = property(get_exa_ovmm_ip, set_exa_ovmm_ip, del_exa_ovmm_ip, "exa_ovmm_ip's docstring")
    exa_db_ip = property(get_exa_db_ip, set_exa_db_ip, del_exa_db_ip, "exa_db_ip's docstring")

def testPyWrapper():
    cmd="/bin/sh exadiscover.sh %s" % (' '.join(sys.argv[1:]))
    os.system(cmd)    

def testShortList():
    rack=ExaDiscover()
    rack.initShortList()
    rack.printIps()

def testFullList():
    rack=ExaDiscover()
    rack.initFullList()
    rack.printIps()    

if __name__ == '__main__':
    testFullList()

