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
## yaml2src - converts a single YAML file to ADOC, BiBTeX, and Biblatex sources
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
library_url = ''            ## URL for auto-generated library links (yaml, adoc, bib, biblatex)
build_local = False         ## do not generate local links to library
library_home = ''           ## library home directory, with PDFs and other artifacts

target_adoc = False         ## target ADOC
target_bibtex = False       ## target BiBTeX
target_biblatex = False     ## target Biblatex



##
## DO NOT CHANGE CODE BELOW, unless you know what you are doing
##



##
## function: print help, for empty or wrong command line
##
def help():
    print("")
    print("yaml2src - converts a single YAML file to ADOC, BiBTeX, and Biblatex sources\n")
    print("       Usage:  ws-console [options]\n")
    print("       Options")
    print("          [-A | --all]                     - activate all targets")
    print("          [-a | --adoc]                    - target ADOC: create ADOC file")
    print("          [-b | --bibtex]                  - target BiBTeX: create BIB file")
    print("          [-h | --help]                    - this help screen")
    print("          [-l | --local]                   - generate local links, requires lib-home set")
    print("          [-L | --lib-home] <dir>          - home directory of library with artifacts, e.g. PDF files")
    print("          [-o | --output-directory] <dir>  - output directory, default is same as YAML source")
    print("          [-T | --task-level] <level>      - task log level: error, warn, warn-strict, info, debug, trace")
    print("          [-u | --library-url] <URL>       - URL with path prefix for auto-generated links (e.g. yaml, adoc)")
    print("          [-x | --biblatex]                - target BibLatex: create BIB file for Biblatex")
    print("          [-y | --yaml-directory] <dir>    - YAML directory")
    print("\n")



##
## function: parse command line
##
def cli(argv):
    global output_dir
    global yaml_dir
    global library_url
    global task_level
    global build_local
    global library_home

    global target_adoc
    global target_bibtex
    global target_biblatex


    try:
        opts, args = getopt.getopt(argv,"AabhlL:o:T:u:xy:",["all","adoc","bibtex","local","lib-home=","output-directory=","yaml-directory=","help","biblatex","task-level=","library-url="])
    except getopt.GetoptError:
        help()
        sys.exit(70)
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            help()
            sys.exit(0)
        elif opt in ("-T", "--task-level"):
            task_level = arg
        elif opt in ("-o", "--output-directory"):
            output_dir = arg
        elif opt in ("-y", "--yaml-directory"):
            yaml_dir = arg
        elif opt in ("-A", "--all"):
            target_adoc = True
            target_bibtex = True
            target_biblatex = True
        elif opt in ("-a", "--adoc"):
            target_adoc = True
        elif opt in ("-b", "--bibtex"):
            target_bibtex = True
        elif opt in ("-x", "--biblatex"):
            target_biblatex = True
        elif opt in ("-u", "--library-url"):
            library_url = arg
        elif opt in ("-l", "--local"):
            build_local = True
        elif opt in ("-L", "--lib-home"):
            library_home = arg



##
## function: process links
##
def process_links(entries, key, file_no_ext):
    ## process links
    adoc_links = ''
    link_count = 0
    if 'urls' in entries:
        adoc_links += "* Links:"
        link_count = len(entries['urls'])
        for index, url in enumerate(entries['urls']):
            tag = url.strip()
            link = entries['urls'][url].strip()
            if index > 0:
                adoc_links += ",\n      "
            else:
                adoc_links += "\n      "
            adoc_links += "link:" + link + "[" + tag + "]"
        adoc_links += "\n"

    ## process links: SKB links, if URL is set
    if library_url != '':
        if link_count > 0:
            adoc_links += "    ┃ "
        else:
            adoc_links += "* Links:\n      "
        adoc_links += "skb:\n"
        adoc_links +=        "        " + library_url +"/" + os.path.dirname(key) +"/" + os.path.basename(file_no_ext) +".yaml[yaml src]"
#         if 'adoc' in entries:
#             adoc_links += ",\n        " + library_url +"/" + os.path.dirname(key) +"/" + os.path.basename(file_no_ext) +".adoc[adoc]"
        if 'bibtex' in entries:
            adoc_links += ",\n        " + library_url +"/" + os.path.dirname(key) +"/" + os.path.basename(file_no_ext) +".bib[BiBTeX]"
        if 'biblatex' in entries:
            adoc_links += ",\n        " + library_url +"/" + os.path.dirname(key) +"/" + os.path.basename(file_no_ext) +"-biblatex.bib[Biblatex]"
        adoc_links += "\n"
        link_count += 2

    ## process links: local library links
    if build_local == True and library_home != '':
        dir = library_home +"/" + os.path.dirname(key)
        files = glob.glob(dir + '/' + os.path.basename(file_no_ext) + '*.*', recursive=False)
        if len(files) > 0:
            if link_count > 0:
                adoc_links += "    ┃ "
            else:
                adoc_links += "* Links:\n      "
            adoc_links += "local:"
            link_count = len(files)
            for index, file in enumerate(files):
                if index > 0:
                    adoc_links += ",\n        "
                else:
                    adoc_links += "\n        "

                orig_file = os.path.basename(file_no_ext)
                found_file = os.path.splitext(os.path.basename(file))[0]
                extension = os.path.splitext(file)[1].lstrip('.')

                tag = extension.upper()
                if orig_file != found_file:
                    tag += ": " + found_file[len(orig_file)+1:]
                adoc_links += "link:{library-home}/" + file[len(library_home)+1:] + "[" + tag + "]"
            adoc_links += "\n"
    else:
        print("    > local not requested or library home not set, no local links processed")

    return adoc_links


##
## function: process single YAML file
##
def process_file(file):
    file_exists = os.path.isfile(file)
    if file_exists == True:
        stream = open(file,'r')

        data = yaml.load(stream)
        stream.close()
        entries = data[list(data.keys())[0]]    ## dictionary with all entries
        key = list(data.keys())[0]              ## key name of the YAML spec

        ## check for required keys
        found_keys = True
        if not 'title' in entries:
            print("error: did not find key 'title'")
            found_keys = False
        if not 'type' in entries:
            print("error: did not find key 'type'")
            found_keys = False
        if not 'year' in entries:
            print("error: did not find key 'year'")
            found_keys = False
        if found_keys == False:
            sys.exit(80)

        ## determine filename for output
        file_no_ext = os.path.splitext(file)[0]

        ## determine presenter(s)
        presenters = []
        if 'presenters' in entries:
            for presenter in entries['presenters']:
                if presenter not in presenters:
                    presenters.append(presenter)

        ## determine author(s)
        authors = []
        if 'authors' in entries:
            for author in entries['authors']:
                if author not in authors:
                    authors.append(author)

        ## determine editor(s)
        editors = []
        if 'editors' in entries:
            for editor in entries['editors']:
                if editor not in editors:
                    editors.append(editor)

        ## determine panelist(s)
        panelists = []
        if 'panelists' in entries:
            for panelist in entries['panelists']:
                if panelist not in panelists:
                    panelists.append(panelist)

        if len(presenters) == 0 and len(authors) == 0 and len(editors) == 0 and len(panelists) == 0:
            if not entries['type'] == 'movie':
                print("error: did not find person, tried: presenters, editors, authors, panelists")
                sys.exit(80)
        if entries['type'] == "tutorial" or entries['type'] == "presentation" or entries['type'] == "lecture-note" or entries['type'] == "keynote" or entries['type'] == "invited-talk":
            if len(presenters) == 0:
                print("error: found tutorial/presentation/ln/keynote/it without presenter(s)")
                sys.exit(80)
        elif entries['type'] == "panel":
            if len(panelists) == 0:
                print("error: found panel without panelist(s)")
                sys.exit(80)
            if not entries['chair']:
                print("error: found panel without chair")
                sys.exit(80)
        else:
            if len(authors) == 0 and len(editors) == 0:
                if not entries['type'] == 'movie':
                    print("error: found publication (not panel/tutorial/presentation/ln/keynote/it/movie) without author(s) and editor(s)")
                    sys.exit(80)

        print("    > found: presenter <%d>, authors <%d>, editor <%d>" % (len(presenters), len(authors), len(editors)))


        ##
        ## generate lists for presenter, author, editor
        ##
        presenter_list = []
        for presenter in presenters:
            psplit = presenter.split(',')
            presenter_list.append(psplit[1].strip() + " " + psplit[0].strip())
        author_list = []
        for author in authors:
            psplit = author.split(',')
            author_list.append(psplit[1].strip() + " " + psplit[0].strip())
        editor_list = []
        for editor in editors:
            psplit = editor.split(',')
            editor_list.append(psplit[1].strip() + " " + psplit[0].strip())
        panelist_list = []
        for panelist in panelists:
            psplit = panelist.split(',')
            panelist_list.append(psplit[1].strip() + " " + psplit[0].strip())


        ##
        ## prepare ADOC content
        ##
        adoc_content = "//\n"
        adoc_content += "// This file was generated by SKB-Dashboard, task 'lib-yaml2src'\n"
        adoc_content += "// - on " + datetime.datetime.now().strftime("%A %B %e") + " at " + datetime.datetime.now().strftime("%T") + "\n"
        adoc_content += "// - skb-dashboard: https://www.github.com/vdmeer/skb-dashboard\n"
        adoc_content += "//\n\n"

        ##
        ## if this is a tutorial/presentation: add 1 name if 1 presenter, no name else, and add "et al." if more names in presenters or authors
        ## if this is not a tutorial/presentation, then add 1 name (plus "et al." if more names on list)
        ##
        if entries['type'] == 'tutorial' or entries['type'] == "presentation" or entries['type'] == "lecture-note" or entries['type'] == "keynote" or entries['type'] == "invited-talk":
            if len(presenter_list) == 1:
                adoc_content += "*" + presenter_list[0] + "*: "
        elif entries['type'] == "panel":
            psplit = entries['chair'].split(',')
            adoc_content += "*" + psplit[1].strip() + " " + psplit[0].strip() + "* (chair): "
        elif entries['type'] == "movie":
            adoc_content += ''
        else:
            adoc_content += "*"
            if len(editor_list) > 0:
                adoc_content += editor_list[0]
                if len(editor_list) > 1:
                    adoc_content += "* et al.: "
                else:
                    adoc_content += "* (ed): "
            elif len(author_list) > 0:
                adoc_content += author_list[0]
                if len(author_list) > 1:
                    adoc_content += "* et al.: "
                else:
                    adoc_content += "*: "
            else:
                adoc_content += "*: "

        ## add title and titleaddon if available, finish with year
        adoc_content += "_" + entries['title']
        if 'titleaddon' in entries:
            adoc_content += " - " + entries['titleaddon']
        adoc_content += "_, " + str(entries['year']) + "\n\n"

        ## add presenter list, if any
        if len(presenter_list) > 0:
            adoc_content += "* Presenter"
            if len(presenter_list) > 1:
                adoc_content += "s"
            adoc_content += ": " +  ", ".join(presenter_list) + "\n"

        ## add editor list, if any
        if len(editor_list) > 0:
            adoc_content += "* Editor"
            if len(editor_list) > 1:
                adoc_content += "s"
            adoc_content += ": " + ", ".join(editor_list) + "\n"

        ## add author list, if any
        if len(author_list) > 0:
            adoc_content += "* Author"
            if len(author_list) > 1:
                adoc_content += "s"
            adoc_content += ": " + ", ".join(author_list) + "\n"

        ## add panel list, if any
        if len(panelist_list) > 0:
            adoc_content += "* Panelist"
            if len(panelist_list) > 1:
                adoc_content += "s"
            adoc_content += ": " + ", ".join(panelist_list) + "\n"

        ## add the ADOC content from the YAML spec
        if 'adoc' in entries:
            adoc_content += entries['adoc']

        ## process links
        adoc_links = process_links(entries, key, file_no_ext)
        if len(adoc_links) > 0 :
            adoc_content += adoc_links

        ## done w/ADOC, write file
        if target_adoc == True:
            file_adoc = file_no_ext + ".adoc"
            if output_dir != '':
                file_adoc = output_dir + "/" + os.path.dirname(key) +"/" + os.path.basename(file_no_ext) + ".adoc"
                pathlib.Path(output_dir + "/" + os.path.dirname(key)).mkdir(parents=True, exist_ok=True)
            stream_out = open(file_adoc,'w')
            stream_out.write(adoc_content + "\n")
            stream_out.close()
            print("    > wrote file: %s" % file_adoc)

        ## if we have BiBTeX in YAML, write file
        if target_bibtex == True and 'bibtex' in entries:
            file_bibtex = file_no_ext + ".bib"
            if output_dir != '':
                file_bibtex = output_dir + "/" + os.path.dirname(key) +"/" + os.path.basename(file_no_ext) + ".bib"
                pathlib.Path(output_dir + "/" + os.path.dirname(key)).mkdir(parents=True, exist_ok=True)
            stream_out = open(file_bibtex,'w')
            stream_out.write(entries['bibtex'] + "\n")
            stream_out.close()
            print("    > wrote file: %s" % file_bibtex)

        ## if we have Biblatex in YAML, write file
        if target_biblatex == True and 'biblatex' in entries:
            file_biblatex = file_no_ext + "-biblatex.bib"
            if output_dir != '':
                file_biblatex = output_dir + "/" + os.path.dirname(key) +"/" + os.path.basename(file_no_ext) + "-biblatex.bib"
                pathlib.Path(output_dir + "/" + os.path.dirname(key)).mkdir(parents=True, exist_ok=True)
            stream_out = open(file_biblatex,'w')
            stream_out.write(entries['biblatex'] + "\n")
            stream_out.close()
            print("    > wrote file: %s" % file_biblatex)
    else:
        print("error: could not open file: %s" % file)
        sys.exit(72)



##
## function: process directory to create _entries.adoc
##
def process_directory(directory):
    yaml_files = glob.glob(directory + "/*.yaml")
    if len(yaml_files) > 0:
        adoc_content = "//\n"
        adoc_content += "// This file was generated by SKB-Dashboard, task 'lib-yaml2src'\n"
        adoc_content += "// - on " + datetime.datetime.now().strftime("%A %B %e") + " at " + datetime.datetime.now().strftime("%T") + "\n"
        adoc_content += "// - skb-dashboard: https://www.github.com/vdmeer/skb-dashboard\n"
        adoc_content += "//\n\n"
        adoc_content += '[cols="a", grid=rows, frame=none, %autowidth.stretch]\n'
        adoc_content += "|===\n"
        for file in yaml_files:
            adoc_content += "|include::{library-adoc}/" + os.path.splitext(file)[0][len(yaml_dir)+1:] + ".adoc[]\n"
        adoc_content += "|===\n\n"

        file_entries = directory + "/_entries.adoc"
        if output_dir != '':
            file_entries = output_dir + "/" + directory[len(yaml_dir)+1:] +"/" + "_entries.adoc"
        stream_out = open(file_entries,'w')
        stream_out.write(adoc_content + "\n")
        stream_out.close()
        print("    > wrote %d entries to: %s" % (len(yaml_files), file_entries))



##
## function: main function
##
def main(argv):
    cli(argv)

    if build_local == True and library_home == '':
        print("error: local set but no library directory given")
        sys.exit(71)

    print("    > searching in: %s" % yaml_dir)
    dir_exists = os.path.isdir(yaml_dir)
    if dir_exists == True:
        files = glob.glob(yaml_dir + '/**/*.yaml', recursive=True)
        for file in files:
            print("\n    > processing: .../%s" % file.lstrip(yaml_dir))
            process_file(file)
        print("\n    > processed %d YAML files" % len(files))

        for (root, directories, filenames) in walk(yaml_dir):
            for directory in directories:
                process_directory(os.path.join(root, directory))

    else:
        print("error: could not open YAML directory: %s" % yaml_dir)
        sys.exit(71)



##
## Call main
##
if __name__ == "__main__":
    main(sys.argv[1:])
    print("    > done")
