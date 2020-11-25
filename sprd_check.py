#!/usr/bin/env python3
# coding=utf-8

import sys
import json
import csv
import io
import os


def interate_list(list):
    for element in list:
        print(element)
def check_file(file):
    print(file)

def check_properties(properties):
        print(properties)

def check_string(string):
        print(string)

def check_value(value):
        print(value)

def check_interval(interval):
        print(interval)

def get_each_attri(attri):
    if 'file' in attri.keys():
        file_nm=attri.get('file')
        check_file(file_nm)

    if 'properties' in attri.keys():
        properties=attri.get('properties')
        check_properties(properties)

    if 'string' in attri.keys():
        string=attri.get('string')
        check_string(string)

    if 'value' in attri.keys():
        value=attri.get('value')
        check_value(value)

    if 'interval' in attri.keys():
        interval=attri.get('interval')
        check_interval(interval)

fl_file=sys.argv[1]
with open(fl_file,'r')as load_f:
    d_fl = json.loads(load_f.read())
    feature_nm=d_fl.get('feature_name')
    enabled_cfg=d_fl.get('enabled_config')
    disabled_cfg=d_fl.get('disabled_config')
    ld_attri=d_fl.get('attribute')
    interate_list(enabled_cfg)
    for d_attri in ld_attri:
        get_each_attri(d_attri)
