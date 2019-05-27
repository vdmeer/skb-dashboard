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
## acronyms-adoc - converts ADOC to targets, e.g. HTML and PDF
##
## @author     Sven van der Meer <vdmeer.sven@mykolab.com>
## @version    v0.0.0
##


##
## DO NOT CHANGE CODE BELOW, unless you know what you are doing
##

## put bugs into errors, safer
set -o errexit -o pipefail -o noclobber -o nounset

## we want files recursivey
shopt -s globstar

## null directories should not cause error
shopt -s nullglob


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
TARGETS=
BUILD_LOCAL=false
ALL=false
CLI_SET=false



##
## set CLI options and parse CLI
##
CLI_OPTIONS=hAH
CLI_LONG_OPTIONS=help
CLI_LONG_OPTIONS+=,all,html

! PARSED=$(getopt --options "$CLI_OPTIONS" --longoptions "$CLI_LONG_OPTIONS" --name acronyms-adoc -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    ConsoleError "  ->" "acronyms-adoc: unknown CLI options"
    exit 51
fi
eval set -- "$PARSED"

PRINT_PADDING=25
while true; do
    case "$1" in
        -h | --help)
            CACHED_HELP=$(TaskGetCachedHelp "acronyms-adoc")
            if [[ -z ${CACHED_HELP:-} ]]; then
                printf "\n   options\n"
                BuildTaskHelpLine h help        "<none>"    "print help screen and exit"            $PRINT_PADDING
                printf "\n   targets\n"
                BuildTaskHelpLine A     all         "<none>"    "generate all targets"              $PRINT_PADDING
                BuildTaskHelpLine H     html        "<none>"    "generate HTML"                     $PRINT_PADDING
            else
                cat $CACHED_HELP
            fi
            exit 0
            ;;

        -A | --all)
            ALL=true
            CLI_SET=true
            shift
            ;;
        -H | --html)
            TARGETS=$TARGETS" html"
            CLI_SET=true
            shift
            ;;

        --)
            shift
            break
            ;;
        *)
            ConsoleFatal "  ->" "acronyms-adoc: internal error (task): CLI parsing bug"
            exit 52
    esac
done



############################################################################################
## test requirements and CLI
############################################################################################
if [[ $ALL == true ]]; then
    TARGETS="html"
fi
if [[ $CLI_SET == false ]]; then
    TARGETS="html"
fi



############################################################################################
##
## ready to go
##
############################################################################################
ConsoleInfo "  -->" "acradoc: starting task"

ACRONYMS_ADOC=${CONFIG_MAP["TARGET"]}/acronyms
OUTPUT_DIR=${CONFIG_MAP["TARGET"]}/acronyms-docs
if [[ ! -d $ACRONYMS_ADOC ]]; then
    ConsoleError "  ->" "acradoc: no ADOC source found in target '$ACRONYMS_ADOC', build first"
    exit 61
fi

ConsoleDebug "remove and re-create output directory: $OUTPUT_DIR"
if [[ -d $OUTPUT_DIR ]]; then
    rm -fr $OUTPUT_DIR
fi
mkdir -p $OUTPUT_DIR

ADOC_ACRONYM="-a acronyms-adoc=$ACRONYMS_ADOC"
ADOC_OUTPUT_DIR="--destination-dir $OUTPUT_DIR"

for FILE in ${CONFIG_MAP["ACRONYM_DOCS"]}/**/*.adoc; do
    for TARGET in $TARGETS; do
        OUTPUT_FILE="$OUTPUT_DIR${FILE#${CONFIG_MAP["ACRONYM_DOCS"]}}"
        OUTPUT_FILE=${OUTPUT_FILE%.*}
        MKDIR_DIR=${OUTPUT_FILE%/*}

        ConsoleDebug "building file $FILE for target $TARGET"
        case $TARGET in
            html)
                ConsoleDebug "    outfile: ${OUTPUT_FILE}.html"
                mkdir -p $MKDIR_DIR
                asciidoctor $FILE --out-file ${OUTPUT_FILE}.html $ADOC_ACRONYM -a toc=left
                :
                ;;
            *)
                ConsoleError "  ->" "acradoc: unknown target $TARGET"
                ;;
        esac
    done
done


ConsoleInfo "  -->" "acradoc: done"
exit $TASK_ERRORS
