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
## library-val - validates library YAML sources
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
output_dir = ''             ## empty output directory, means same as the YAML file
yaml_dir = ''               ## YAML directory
library = {}                ## dictionary of library entries



##
## DO NOT CHANGE CODE BELOW, unless you know what you are doing
##



##
## function: print help, for empty or wrong command line
##
def help():
    print("")
    print("library-val - validates library YAML sources\n")
    print("       Usage: library-val [options]\n")
    print("       Options")
    print("          [-h | --help]                    - this help screen")
    print("          [-y | --yaml-directory] <dir>    - YAML directory")
    print("\n")



##
## function: parse command line
##
def cli(argv):
    global yaml_dir
    global task_level


    try:
        opts, args = getopt.getopt(argv,"hy:",["yaml-directory=","help"])
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
    expected_keys = ( 'title', 'titleaddon', 'type', 'year', 'presenters', 'authors', 'editors', 'chair', 'panelists', 'urls', 'adoc', 'bibtex', 'biblatex')
    errors = ""

    if not 'title' in entries:
        errors += "         --> did not find key 'title'\n"
        found_keys = False
    else:
        if len(entries['title']) == 0:
            errors += "         --> key 'title' empty\n"
            found_keys = False

    if not 'type' in entries:
        errors += "         --> did not find key 'type'\n"
        found_keys = False
    else:
        if len(entries['type']) == 0:
            errors += "         --> key 'type' empty\n"
            found_keys = False

    if not 'year' in entries:
        errors += "         --> did not find key 'year'\n"
        found_keys = False


    ## check presenter(s)
    presenters = []
    if 'presenters' in entries:
        for presenter in entries['presenters']:
            if presenter not in presenters:
                presenters.append(presenter)
            else:
                errors += "         --> presenter '" + presenter + "' used more than once\n"
                found_keys = False

    ## check author(s)
    authors = []
    if 'authors' in entries:
        for author in entries['authors']:
            if author not in authors:
                authors.append(author)
            else:
                errors += "         --> author '" + author + "' used more than once\n"
                found_keys = False

    ## check editor(s)
    editors = []
    if 'editors' in entries:
        for editor in entries['editors']:
            if editor not in editors:
                editors.append(editor)
            else:
                errors += "         --> editor '" + editor + "' used more than once\n"
                found_keys = False

    ## check panelist(s)
    panelists = []
    if 'panelists' in entries:
        for panelist in entries['panelists']:
            if panelist not in panelists:
                panelists.append(panelist)
            else:
                errors += "         --> panelist '" + panelist + "' used more than once\n"
                found_keys = False

    if len(presenters) == 0 and len(authors) == 0 and len(editors) == 0 and len(panelists) == 0:
        if not entries['type'] == 'movie':
            errors += "         --> did not find person, tried: presenters, editors, authors, panelists\n"
            found_keys = False
    if entries['type'] == "tutorial" or entries['type'] == "presentation" or entries['type'] == "lecture-note" or entries['type'] == "keynote" or entries['type'] == "invited-talk":
        if len(presenters) == 0:
            errors += "         --> found tutorial/presentation/ln/keynote/it without presenter(s)\n"
            found_keys = False
    elif entries['type'] == "panel":
        if len(panelists) == 0:
            errors += "         --> found panel without panelist(s)\n"
            found_keys = False
        if not entries['chair']:
            errors += "         --> found panel without chair\n"
            found_keys = False
    else:
        if len(authors) == 0 and len(editors) == 0:
            if not entries['type'] == 'movie':
                errors += "         --> found publication (not panel/tutorial/presentation/ln/keynote/it/movie) without author(s) and editor(s)\n"
                found_keys = False

    print("    > found: presenter <%d>, authors <%d>, editor <%d>" % (len(presenters), len(authors), len(editors)))

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

        if not key in library:
            entries['src-file'] = file
            library[key] = entries
        else:
            print("      -> key %s already in dictionary, defined in %s" % (key, library[key]['src-file']))
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

        print("\n    > processed %d YAML files, found %d references" % (len(files), len(library)))

    else:
        print("error: could not open YAML directory: %s" % yaml_dir)
        sys.exit(71)



##
## Call main
##
if __name__ == "__main__":
    main(sys.argv[1:])
    print("    > done")
