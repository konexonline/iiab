#!/usr/bin/python3
# Creates json files for presets

import os, sys, syslog
from datetime import date
import pwd, grp
import shutil
import argparse
import sqlite3
import iiab.iiab_lib as iiab
import iiab.adm_lib as adm
import requests
import json

all_menu_defs = adm.get_all_menu_defs()

def main():
    parser = argparse.ArgumentParser(description="Get size for item.")
    parser.add_argument("name", help="Name item.")

    # menu_dir
    args =  parser.parse_args()

    name = args.name

    content= get_item_size(name)

    #print('size: ',iiab.human_readable(content["size"]))
    print(f'content ', content)

    sys.exit()

def get_zims_size_from_header(url):
    #url = 'https://download.kiwix.org/zim/other/mdwiki_en_all_2023-03.zim'
    response = requests.head(url, allow_redirects=True)
    size = 0
    if (response.status_code == 200):
        size = int(response.headers.get('Content-Length', 0))
    return size

def get_zims_size_from_file(name):
    data_output = {}
    data_output['download_url']= ''
    data_output['size'] = 0

    with open('/etc/iiab/kiwix_catalog.json') as json_file:
        data = json.load(json_file)['zims']
        result = { data[element]['perma_ref']: data[element]  for element in  list(data.keys())}
        if result.get(name) is not None:
            data_output['download_url']= result[name]['download_url']
            data_output['size']= (int(result[name].get('size',0)) * 1024) + 1023
    return data_output

def get_zims_size(name):
    data = get_zims_size_from_file(name)
    #if data['size'] <= 1023:
    #    data['size'] = get_zims_size_from_header(data['download_url'])
    return data

def get_oer2go_size_from_file(name):
    data_output = {}
    data_output['download_url']= ''
    data_output['size'] = 0

    with open('/etc/iiab/oer2go_catalog.json') as json_file:
        data = json.load(json_file)['modules']
        if data.get(name) is not None:
            data_output['download_url']= data[name]['rsync_url']
            data_output['size']= (int(data[name].get('ksize',0)) * 1024) + 1023
    return data_output

def get_map_size_from_file(name):
    data_output = {}
    data_output['download_url']= ''
    data_output['size'] = 0

    with open('/etc/iiab/map-catalog.json') as json_file:
        data = json.load(json_file)['base']
        result = { data[element]['perma_ref']: data[element]  for element in  list(data.keys())}
        if result.get(name) is not None:
            data_output['download_url']= result[name]['archive_url']
            data_output['size']= (int(result[name].get('size',0))) + 1023
    return data_output


def get_item_size(name_input):
	return [get_size(element) for element in [name_input]]

def get_items_size(name_input):	
	return [get_size(element) for element in name_input]

def element_unknown(name):
	return {"size":0}

def build_otput(name, type_element, function):
    data = function(name)
    if data['size']== 0:
    	print(name, "element",type_element,"not found")

    return {
        "name": name
        ,"type": type_element
        ,"size": data['size']
    }

def get_size(name_input):
    if name_input in all_menu_defs:
        info = all_menu_defs[name_input]
        intended_use = info["intended_use"]

        if intended_use == "html":
            name_element = info["moddir"]
            return build_otput(name_element, "module", get_oer2go_size_from_file)

        elif intended_use == "zim":
            name_element = info["zim_name"]
            return build_otput(name_element, "zim", get_zims_size)
       
        elif intended_use == "webroot":
            name_element = info["name"]
            return build_otput(name_element, "map", get_map_size_from_file)
                    
    return build_otput(name_input, "unknown", element_unknown)

# Now start the application
if __name__ == "__main__":
    main()

