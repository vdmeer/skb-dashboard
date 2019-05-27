#!/usr/bin/env bash

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
## library-ext - extracts ADOC, BIB and Biblatec from library YAML sources
##
## @author     Sven van der Meer <vdmeer.sven@mykolab.com>
## @version    v0.0.0
##


##
## DO NOT CHANGE CODE BELOW, unless you know what you are doing
##

## put bugs into errors, safer
set -o errexit -o pipefail -o noclobber -o nounset


# ## we want files recursivey
# shopt -s globstar


##
## Test if we are run from parent with configuration
## - load configuration
##
if [[ -z ${FW_HOME:-} || -z ${FW_L1_CONFIG-} ]]; then
    printf " ==> please run from framework or application\n\n"
    exit 50
fi
source $FW_L1_CONFIG
CONFIG_MAP["RUNNING_IN"]="task"


##
## load main functions
## - reset errors and warnings
##
source $FW_HOME/bin/api/_include
ConsoleResetErrors
ConsoleResetWarnings


##
## set local variables
##
BUILD_LOCAL=false
TARGETS=
ALL=false
CLI_SET=false



##
## set CLI options and parse CLI
##
CLI_OPTIONS=Aabhlx
CLI_LONG_OPTIONS=help,local
CLI_LONG_OPTIONS+=,all,adoc,bib,biblatex

! PARSED=$(getopt --options "$CLI_OPTIONS" --longoptions "$CLI_LONG_OPTIONS" --name library-ext -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    ConsoleError "  ->" "library-ext: unknown CLI options"
    exit 51
fi
eval set -- "$PARSED"

PRINT_PADDING=25
while true; do
    case "$1" in
        -h | --help)
            CACHED_HELP=$(TaskGetCachedHelp "library-ext")
            if [[ -z ${CACHED_HELP:-} ]]; then
                printf "\n   options\n"
                BuildTaskHelpLine h help            "<none>"    "print help screen and exit"        $PRINT_PADDING
                BuildTaskHelpLine l local           "<none>"    "build with local links"            $PRINT_PADDING
                printf "\n   targets\n"
                BuildTaskHelpLine A     all         "<none>"    "generate all targets"              $PRINT_PADDING
                BuildTaskHelpLine a     adoc        "<none>"    "generate ADOC"                     $PRINT_PADDING
                BuildTaskHelpLine b     bib         "<none>"    "generate BiBTeX bib files"         $PRINT_PADDING
                BuildTaskHelpLine x     biblatex    "<none>"    "generate Biblatex bib files"       $PRINT_PADDING
                printf "\n   Notes\n"
                printf "Extracted ADOC files will be written to the target directory\n"
                printf "Entry files for ADOC files will be created in the target directory\n"
                printf "Extracted BiBTeX and Biblatex files will be written to the YAML source directory\n"
            else
                cat $CACHED_HELP
            fi
            exit 0
            ;;

        -l | --local)
            BUILD_LOCAL=true
            shift
            ;;

        -A | --all)
            ALL=true
            CLI_SET=true
            shift
            ;;
        -a | --adoc)
            TARGETS=$TARGETS" adoc"
            CLI_SET=true
            shift
            ;;
        -b | --bib)
            TARGETS=$TARGETS" bib"
            CLI_SET=true
            shift
            ;;
        -x | --biblatex)
            TARGETS=$TARGETS" biblatex"
            CLI_SET=true
            shift
            ;;

        --)
            shift
            break
            ;;
        *)
            ConsoleFatal "  ->" "library-ext: internal error (task): CLI parsing bug"
            exit 52
    esac
done



############################################################################################
## test requirements and CLI
############################################################################################
if [[ $ALL == true ]]; then
    TARGETS="adoc bib biblatex"
fi
if [[ $CLI_SET == false ]]; then
    TARGETS="adoc"
fi



############################################################################################
##
## ready to go
##
############################################################################################
ConsoleInfo "  -->" "libext: starting task"


LIB_EXT_ARGS=" -y ${CONFIG_MAP["LIBRARY_YAML"]}"

if [[ $BUILD_LOCAL == true ]]; then
    if [[ -z "${CONFIG_MAP["LIBRARY_HOME"]:-}" ]]; then
        ConsoleError "  ->" "libext: 'LIBRARY_HOME' not set, cannot generate local library links"
        exit 61
    else
        LIB_EXT_ARGS+=" --output-directory ${CONFIG_MAP["TARGET"]}/library-local --local --lib-home ${CONFIG_MAP["LIBRARY_HOME"]}"
    fi
else
    LIB_EXT_ARGS+=" --output-directory ${CONFIG_MAP["TARGET"]}/library"
fi

if [[ ! -z "${CONFIG_MAP["LIBRARY_URL"]:-}" ]]; then
    LIB_EXT_ARGS+=" --library-url ${CONFIG_MAP["LIBRARY_URL"]}"
fi

for TARGET in $TARGETS; do
    case $TARGET in
        adoc)       LIB_EXT_ARGS+=" --adoc" ;;
        bib)        LIB_EXT_ARGS+=" --bibtex" ;;
        biblatex)   LIB_EXT_ARGS+=" --biblatex" ;;
    esac
done


${CONFIG_MAP["APP_HOME"]}/bin/python/library-ext.py $LIB_EXT_ARGS
__errno=$?
exit $?


ConsoleInfo "  -->" "libext: done"
exit $TASK_ERRORS
