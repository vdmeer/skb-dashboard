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
## acronyms-val - validates YAML files of SKB acronyms
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
acronyms = {}               ## dictionary of acronyms



##
## DO NOT CHANGE CODE BELOW, unless you know what you are doing
##



##
## function: print help, for empty or wrong command line
##
def help():
    print("")
    print("acronyms-val - validates YAML files of SKB acronyms\n")
    print("       Usage: acronyms-val [options]\n")
    print("       Options")
    print("          [-h | --help]                    - this help screen")
    print("          [-T | --task-level] <level>      - task log level: error, warn, warn-strict, info, debug, trace")
    print("          [-y | --yaml-directory] <dir>    - top YAML directory")
    print("\n")



##
## function: parse command line
##
def cli(argv):
    global yaml_dir
    global task_level


    try:
        opts, args = getopt.getopt(argv,"hT:y:",["yaml-directory=","help","task-level="])
    except getopt.GetoptError:
        help()
        sys.exit(70)
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            help()
            sys.exit(0)
        elif opt in ("-T", "--task-level"):
            task_level = arg
        elif opt in ("-y", "--yaml-directory"):
            yaml_dir = arg



##
## function: validates a single YAML file
##
def validate_file(file, entries, key):
    ## check for required keys
    found_keys = True
    expected_keys = ( 'short' , 'short-target', 'long', 'long-target', 'description', 'notes', 'urls')
    errors = ""

    if not 'short' in entries:
        errors += "         --> did not find key 'short'\n"
        found_keys = False
    else:
        if len(entries['short']) == 0:
            errors += "         --> key 'short' with no entry\n"
            found_keys = False

    if not 'long' in entries:
        errors += "         --> did not find key 'long'\n"
        found_keys = False
    else:
        if len(entries['long']) == 0:
            errors += "         --> key 'long' with no entry\n"
            found_keys = False

    if 'long-target' in entries and len(entries['long-target']) == 0:
            errors += "         --> key 'long-target' with no entry\n"
            found_keys = False

    if 'description' in entries and len(entries['description']) == 0:
            errors += "         --> key 'description' with no entry\n"
            found_keys = False

    if 'notes' in entries and len(entries['notes']) == 0:
            errors += "         --> key 'notes' with no entry\n"
            found_keys = False

    if 'urls' in entries and len(entries['urls']) == 0:
            errors += "         --> key 'urls' with no entry\n"
            found_keys = False

    if not all(elem in expected_keys for elem in entries):
        errors += "         --> unknown key\n"
        found_keys = False

    file_short = file[len(yaml_dir)+1:]
    dir_short = file_short.rsplit('/', 1)[0]
    key_short = key.rsplit('/', 1)[0]
    if not key_short == dir_short:
        errors += "         --> something wrong in key path (" + key_short + ") and directory (" + dir_short + ")\n"
        found_keys = False

    if found_keys == False:
        print("      -> validation failed")
        print("%s" % errors)
        sys.exit(80)



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

        validate_file(file, entries, key)

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
## function: main function
##
def main(argv):
    cli(argv)

    print("    > YAML directory: %s" % yaml_dir)
    dir_exists = os.path.isdir(yaml_dir)
    if dir_exists == True:
        files = glob.glob(yaml_dir + '/**/*.yaml', recursive=True)
        for file in files:
            print("\n    > processing: .../%s" % file[len(yaml_dir)+1:])
            process_file(file)

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
