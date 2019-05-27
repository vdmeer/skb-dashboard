#!/usr/bin/env python3

#-------------------------------------------------------------------------------
# ============LICENSE_START=======================================================
#  Copyright (C) 2018 Sven van der Meer. All rights reserved.
# ================================================================================
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# 
# SPDX-License-Identifier: Apache-2.0
# ============LICENSE_END=========================================================
#-------------------------------------------------------------------------------

##
## acronyms - finds SKB acronyms in YAML files
##
## @author     Sven van der Meer <vdmeer.sven@mykolab.com>
## @version    v0.0.0
##


##
## Includes, all we need
##
import yaml             ## parsing YAML files
import os               ## operating system, e.g. file handling
from os import walk     ## for walking directories
import functools        ## some tools for functions
import sys, getopt      ## system for exit, getopt for CLI parsing
import glob             ## gobal globbing to get YAML files recursively
import pathlib          ## mkdirs in Python
import datetime         ## to get date/time for ADOC files



##
## Global variables
##
task_level = "warn"         ## warning level
yaml_dir = ''               ## YAML directory
duplicates = False          ## search and print duplicates
search_short = ''           ## search string for SHORT form
search_long = ''            ## search string for LONG form
search_dnu = ''             ## search string for description, notes, and urls

acronyms = {}               ## dictionary of acronyms
acr_idx  = {}               ## index for acronyms, key is short and value is list of names


##
## DO NOT CHANGE CODE BELOW, unless you know what you are doing
##



##
## function: print help, for empty or wrong command line
##
def help():
    print("")
    print("acronyms - finds SKB acronyms in YAML files\n")
    print("       Usage: acronyms [options]\n")
    print("       Options")
    print("          [-d | --duplicates]              - print duplicates (short form)")
    print("          [-h | --help]                    - this help screen")
    print("          [-l | --long] <string>           - search <string> in long form")
    print("          [-n | --notes] <string>          - search <string> in descriptions, notes, and URLs")
    print("          [-T | --task-level] <level>      - task log level: error, warn, warn-strict, info, debug, trace")
    print("          [-s | --short] <string>          - search <string> in short form")
    print("          [-y | --yaml-directory] <dir>    - YAML top directory")
    print("\n")



##
## function: parse command line
##
def cli(argv):
    global output_file
    global yaml_dir
    global task_level
    global duplicates

    global search_short
    global search_long
    global search_dnu

    global latex_aux


    try:
        opts, args = getopt.getopt(argv,"dhl:n:s:T:y:",["yaml-directory=","duplicates","notes=","short=","long=","help","task-level="])
    except getopt.GetoptError:
        help()
        sys.exit(70)
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            help()
            sys.exit(0)
        elif opt in ("-T", "--task-level"):
            task_level = arg
        elif opt in ("-s", "--short"):
            search_short = arg
        elif opt in ("-l", "--long"):
            search_long = arg
        elif opt in ("-n", "--notes"):
            search_dnu = arg
        elif opt in ("-y", "--yaml-directory"):
            yaml_dir = arg
        elif opt in ("-d", "--duplicates"):
            duplicates = True



##
## function: sort acronyms by value of short entry
##
def index_acronyms(dict, idx):
    for key in dict:
        short_lc = dict[key]['short'].lower()
        if short_lc in idx:
            idx[short_lc].append(key)
        else:
            list = [ key ]
            idx[short_lc] = list



##
## function: find and print duplicates (short form)
##
def find_duplicates(dict, idx):
    print("\n    > searching for duplicates\n")
    for key_sorted in sorted(idx.keys()):
        if len(idx[key_sorted]) > 1:
            for entry in idx[key_sorted]:
                print("      %s - %s\n        -> %s" % (dict[entry]['short'], dict[entry]['long'], entry))
            print("\n")



##
## function: find short form of acronyms
##
def find_short(dict, idx, name):
    print("\n    > searching for short %s\n" % name)
    name_lc = name.lower()

    for key_sorted in sorted(idx.keys()):
        for entry in idx[key_sorted]:
            if dict[entry]['short'].lower().find(name_lc) != -1:
                print("      %s - %s\n        -> %s" % (dict[entry]['short'], dict[entry]['long'], entry))



##
## function: find pattern in 'long'
##
def find_long(dict, idx, pattern):
    print("\n    > searching for long %s\n" % pattern)
    pattern_lc = pattern.lower()

    for key_sorted in sorted(idx.keys()):
        for entry in idx[key_sorted]:
            for long_idx in dict[entry]['long']:
                if dict[entry]['long'][long_idx].lower().find(pattern_lc) != -1:
                    print("      %s - %s\n        -> %s" % (dict[entry]['short'], dict[entry]['long'], entry))



##
## function: find pattern in 'description' and 'notes' and 'urls'
##
def find_dnu(dict, idx, pattern):
    print("\n    > searching for pattern %s\n" % pattern)
    pattern_lc = pattern.lower()

    for key_sorted in sorted(idx.keys()):
        for entry in idx[key_sorted]:
            if 'description' in dict[entry]:
                for key in dict[entry]['description']:
                    if dict[entry]['description'][key].lower().find(pattern_lc) != -1:
                        print("      %s - %s\n        -> %s" % (dict[entry]['short'], dict[entry]['long'], entry))
            if 'notes' in dict[entry]:
                for key in dict[entry]['notes']:
                    if dict[entry]['notes'][key].lower().find(pattern_lc) != -1:
                        print("      %s - %s\n        -> %s" % (dict[entry]['short'], dict[entry]['long'], entry))
            if 'urls' in dict[entry]:
                for key in dict[entry]['urls']:
                    if dict[entry]['urls'][key].lower().find(pattern_lc) != -1:
                        print("      %s - %s\n        -> %s" % (dict[entry]['short'], dict[entry]['long'], entry))



##
## function: process a single YAML file
##
def process_file(file):
    file_exists = os.path.isfile(file)
    if file_exists == True:
        stream = open(file,'r')

        data = yaml.load(stream)
        stream.close()
        entries = data[list(data.keys())[0]]    ## dictionary with all entries
        key = list(data.keys())[0]              ## key name of the YAML spec

        if not key in acronyms:
            entries['src-file'] = file
            acronyms[key] = entries
        else:
            print("      -> key %s already in dictionary, defined in %s" % (key, acronyms[key]['src-file']))
            sys.exit(80)

    else:
        print("error: could not open file: %s" % file)
        sys.exit(72)



##
## function: process directory
##
def process_directory(directory):
    yaml_files = glob.glob(directory + "/*.yaml")
    if len(yaml_files) > 0:
#         adoc_content = "//\n"
#         adoc_content += "// This file was generated by SKB-Dashboard, task 'lib-yaml2src'\n"
#         adoc_content += "// - on " + datetime.datetime.now().strftime("%A %B %e") + " at " + datetime.datetime.now().strftime("%T") + "\n"
#         adoc_content += "// - skb-dashboard: https://www.github.com/vdmeer/skb-dashboard\n"
#         adoc_content += "//\n\n"
#         adoc_content += '[cols="a", grid=rows, frame=none, %autowidth.stretch]\n'
#         adoc_content += "|===\n"
#         for file in yaml_files:
#             adoc_content += "|include::{library-adoc}/" + os.path.splitext(file)[0][len(yaml_dir)+1:] + ".adoc[]\n"
#         adoc_content += "|===\n\n"
# 
#         file_entries = directory + "/_entries.adoc"
#         if output_dir != '':
#             file_entries = output_dir + "/" + directory[len(yaml_dir)+1:] +"/" + "_entries.adoc"
#         stream_out = open(file_entries,'w')
#         stream_out.write(adoc_content + "\n")
#         stream_out.close()
        print("    > %5d -- %s" % (len(yaml_files), directory[len(yaml_dir)+1:]))



##
## function: main function
##
def main(argv):
    cli(argv)

    print("    > YAML directory: %s" % yaml_dir)
    dir_exists = os.path.isdir(yaml_dir)
    if dir_exists == True:
        files = glob.glob(yaml_dir + '/**/*.yaml', recursive=True)
        for file in files:
            process_file(file)

        index_acronyms(acronyms, acr_idx)

        if duplicates == True:
            find_duplicates(acronyms, acr_idx)
        if search_short != '':
            find_short(acronyms, acr_idx, search_short)
        if search_long != '':
            find_long(acronyms, acr_idx, search_long)
        if search_dnu != '':
            find_dnu(acronyms, acr_idx, search_dnu)

#         for (root, directories, filenames) in walk(yaml_dir):
#             for directory in directories:
#                 process_directory(os.path.join(root, directory))

        print("\n    > processed %d YAML files, found %d acronyms" % (len(files), len(acronyms)))

    else:
        print("error: could not open YAML directory: %s" % yaml_dir)
        sys.exit(71)



##
## Call main
##
if __name__ == "__main__":
    main(sys.argv[1:])
    print("    > done")
