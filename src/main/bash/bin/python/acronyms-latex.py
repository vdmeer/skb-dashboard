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
## acronyms-latex - processes SKB acronyms to build LaTeX file
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
output_file = ''            ## empty output file, means STDOUT
yaml_dir = ''               ## YAML directory
latex_aux = ''              ## target LaTeX, AUX file for reading used acronyms, all acronyms if not set

acronyms = {}               ## dictionary of acronyms
acr_idx  = {}               ## index for acronyms, key is short and value is list of names
longest_acr = ''            ## longest short form found


##
## DO NOT CHANGE CODE BELOW, unless you know what you are doing
##



##
## function: print help, for empty or wrong command line
##
def help():
    print("")
    print("acronyms-latex - processes SKB acronyms to build LaTeX file\n")
    print("       Usage: acronyms-latex [options]\n")
    print("       Options")
    print("          [-a | --aux] <aux-file>          - LaTeX auxiliary file, if used only used acronyms are printed")
    print("          [-h | --help]                    - this help screen")
    print("          [-o | --output-file] <file>      - output file, default is STDOUT")
    print("          [-T | --task-level] <level>      - task log level: error, warn, warn-strict, info, debug, trace")
    print("          [-y | --yaml-directory] <dir>    - YAML top directory")
    print("\n")



##
## function: parse command line
##
def cli(argv):
    global output_file
    global yaml_dir
    global task_level
    global latex_aux


    try:
        opts, args = getopt.getopt(argv,"a:ho:T:y:",["output-file=","yaml-directory=","help","aux=","task-level="])
    except getopt.GetoptError:
        help()
        sys.exit(70)
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            help()
            sys.exit(0)
        elif opt in ("-T", "--task-level"):
            task_level = arg
        elif opt in ("-o", "--output-file"):
            output_file = arg
        elif opt in ("-y", "--yaml-directory"):
            yaml_dir = arg
        elif opt in ("-a", "--aux"):
            latex_aux = arg



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
## function: get used acronyms from AUX file
##
def get_used(fn, acr_required):
    if fn != '':
        file = open(fn, "r")
        for line in file:
            if line.startswith("\\acronymused"):
                key = line[line.find("{")+1:line.find("}")]
                if not key in acr_required:
                    acr_required.append(key)
        file.close()

        add_file = os.path.dirname(fn) + "/add-acronyms.txt"
        file_exists = os.path.isfile(add_file)
        if file_exists == True:
            file = open(add_file, "r")
            for line in file:
                if line.startswith("\\acronymused"):
                    key = line[line.find("{")+1:line.find("}")]
                    if not key in acr_required:
                        acr_required.append(key)
            file.close()



##
## function: get list of acronyms
##
def get_list(acr_required, dict, idx):
    global longest_acr
    acr_list = ''
    for key_sorted in sorted(idx.keys()):
        for entry in idx[key_sorted]:
            acr_entry = entry.replace("/", ":")
            use_acr = False
            if len(acr_required) > 0:
                if acr_entry in acr_required:
                    use_acr = True
            else:
                use_acr = True

            if use_acr == True:
                acr_short = ''
                if 'short-target' in dict[entry] and 'latex' in dict[entry]['short-target']:
                    acr_short = dict[entry]['short-target']['latex']
                else:
                    acr_short = dict[entry]['short']

                acr_long = ''
                if 'long-target' in dict[entry] and 'latex' in dict[entry]['long-target']:
                    acr_long = dict[entry]['long-target']['latex']
                elif 'en' in dict[entry]['long']:
                    acr_long = dict[entry]['long']['en']
                else:
                    acr_long = dict[entry]['long'][next(iter(dict[entry]['long']))]

                acr_list += "    \\acro{" + acr_entry + "}[" + acr_short + "]{" + acr_long + "}\n"
                if len(longest_acr) < len(acr_short):
                    longest_acr = acr_short

    return acr_list



##
## function: print list of acronyms
##
def print_list(acr_list):
    if output_file == '':
        print("\\begin{acronym}[" + longest_acr + "X]\n")
        print(acr_list)
        print("\\end{acronym}\n")
    else:
        file = open(output_file, "w")
        file.write("\\begin{acronym}[" + longest_acr + "X]\n")
        file.write(acr_list)
        file.write("\\end{acronym}\n")
        file.close()
        print("\n    > wrote %s\n" % output_file)



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
## function: main function
##
def main(argv):
    cli(argv)

#     print("    > YAML directory: %s" % yaml_dir)
    dir_exists = os.path.isdir(yaml_dir)
    if dir_exists == True:
        files = glob.glob(yaml_dir + '/**/*.yaml', recursive=True)
        for file in files:
            process_file(file)

        index_acronyms(acronyms, acr_idx)

        acr_required = []
        get_used(latex_aux, acr_required)
        acr_list = get_list(acr_required, acronyms, acr_idx)
        print_list(acr_list)

#         print("\n    > processed %d YAML files, found %d acronyms" % (len(files), len(acronyms)))

    else:
        print("error: could not open YAML directory: %s" % yaml_dir)
        sys.exit(71)



##
## Call main
##
if __name__ == "__main__":
    main(sys.argv[1:])
#     print("    > done")
