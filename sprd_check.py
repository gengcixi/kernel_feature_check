#!/usr/bin/env python3
# coding=utf-8

import sys
import json
import gzip
import os
import getopt

fail_count=0

def print_pass(str):
    print("\033[1;33mCHECK PASS:\033[0m %s" %str)

def print_fail(str):
    print("\033[1;31mCHECK FAIL:\033[0m %s" %str)

def interate_list(list):
    for element in list:
        print("\t"+element)

def check_enabled_config(list_config):
    global fail_count
    test_flag=False
    for config in list_config:
        e_config=(config+"=").encode()
        with gzip.open("/proc/config.gz",'r') as fd:
            for line in fd.readlines():
                if e_config in line:
                    test_flag=True
                    break
                else:
                    test_flag=False
            if test_flag == True:
                print_pass(config + "is enabled")
            else:
                fail_count+=1
                print_fail(config + "is not enabled")

def check_disabled_config(list_config):
    global fail_count
    test_flag=False
    for config in list_config:
        d_config=(config+"=").encode()
        with gzip.open("/proc/config.gz",'r') as fd:
            for line in fd.readlines():
                if d_config in line:
                    test_flag=True
                    break
                else:
                    test_flag=False
            if test_flag == True:
                fail_count+=1
                print_fail(config + "is enabled")
            else:
                print_pass(config + "is not enabled")

def check_properties(file,properties):
    global fail_count
    findflag=False
    for prop in properties:
        with open(file,'r') as fd:
            for line in fd.readlines():
                if prop in line:
                    findflag=True
                    break
                else:
                    findflag=False
            if findflag == True:
                print_pass(file + " have properites of " + prop)
                print("\t"+line)
            else:
                print_fail(file + " no properites of " + prop)
                fail_count+=1

def check_string(file,string):
    global fail_count
    findflag=0
    with open(file,'r') as fd:
        for line in fd.readlines():
            for str in string:
                if str in line:
                    findflag+=1
                    break
        if findflag > 0:
            print_pass(file + " configureation is contain  " + str)
            print("\t"+line)
        else:
            fail_count+=1
            print_fail(file + " configureation is none of follow:")
            print(string)


def check_value(file,value):
    global fail_count
    with open(file,'r') as fd:
        fd_value=fd.read().strip("\n")
        if str(value) == str(fd_value):
            print_pass(file + " value set is " + value)
        else:
            fail_count+=1
            print_fail(file + " value set is not " + value)

def check_interval(file,interval):
    global fail_count
    with open(file,'r') as fd:
        fd_value=int(fd.read())
        if fd_value >= int(min(interval)) and fd_value <= int(max(interval)):
            print_pass(file + " value " + str(fd_value) + " is between:")
            print("\t",end="")
            print(interval)
        else:
            fail_count+=1
            print_fail(file + " value " + str(fd_value) + " is out of range:")
            print("\t",end="")
            print(interval)

def get_each_attri(attri):
    global fail_count
    if 'file' in attri.keys():
        file_nm=attri.get('file')
        if os.path.exists(file_nm):
            print_pass( "exist "+ file_nm)
            if 'properties' in attri.keys():
                list_properties=attri.get('properties')
                check_properties(file_nm,list_properties)

            if 'string' in attri.keys():
                list_string=attri.get('string')
                check_string(file_nm,list_string)

            if 'value' in attri.keys():
                value=attri.get('value')
                check_value(file_nm,value)

            if 'interval' in attri.keys():
                list_interval=attri.get('interval')
                check_interval(file_nm,list_interval)
        else:
            fail_count+=1
            print_fail( " not exist "+ file_nm)




def main(argv=None):
    global fail_count
    fl_file=sys.argv[1]
    with open(fl_file,'r')as load_f:
        d_fl = json.loads(load_f.read())
        feature_nm=d_fl.get('feature_name')

        list_enabled_cfg=d_fl.get('enabled_config')
        list_disabled_cfg=d_fl.get('disabled_config')

        if os.path.exists("/proc/config.gz"):
            check_enabled_config(list_enabled_cfg)
            check_disabled_config(list_disabled_cfg)

        ld_attri=d_fl.get('attribute')
        for d_attri in ld_attri:
            get_each_attri(d_attri)
    return fail_count

if __name__ == "__main__":
    sys.exit(main())
