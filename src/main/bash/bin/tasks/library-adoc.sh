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
## library-adoc - converts ADOC to targets, e.g. HTML and PDF
##
## @author     Sven van der Meer <vdmeer.sven@mykolab.com>
## @version    v0.0.0
##


##
## DO NOT CHANGE CODE BELOW, unless you know what you are doing
##

## put bugs into errors, safer
set -o errexit -o pipefail -o noclobber -o nounset


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
CLI_OPTIONS=hlAHP
CLI_LONG_OPTIONS=help,local
CLI_LONG_OPTIONS+=,all,html,pdf

! PARSED=$(getopt --options "$CLI_OPTIONS" --longoptions "$CLI_LONG_OPTIONS" --name library-adoc -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    ConsoleError "  ->" "library-adoc: unknown CLI options"
    exit 51
fi
eval set -- "$PARSED"

PRINT_PADDING=25
while true; do
    case "$1" in
        -h | --help)
            CACHED_HELP=$(TaskGetCachedHelp "library-adoc")
            if [[ -z ${CACHED_HELP:-} ]]; then
                printf "\n   options\n"
                BuildTaskHelpLine h help        "<none>"    "print help screen and exit"            $PRINT_PADDING
                BuildTaskHelpLine l local       "<none>"    "build from local target"               $PRINT_PADDING
                printf "\n   targets\n"
                BuildTaskHelpLine A     all         "<none>"    "generate all targets"              $PRINT_PADDING
                BuildTaskHelpLine H     html        "<none>"    "generate HTML"                     $PRINT_PADDING
                BuildTaskHelpLine P     pdf         "<none>"    "generate PDF"                      $PRINT_PADDING
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
        -H | --html)
            TARGETS=$TARGETS" html"
            CLI_SET=true
            shift
            ;;
        -P | --pdf)
            TARGETS=$TARGETS" pdf"
            CLI_SET=true
            shift
            ;;

        --)
            shift
            break
            ;;
        *)
            ConsoleFatal "  ->" "library-adoc: internal error (task): CLI parsing bug"
            exit 52
    esac
done



############################################################################################
## test requirements and CLI
############################################################################################
if [[ $ALL == true ]]; then
    TARGETS="html pdf"
fi
if [[ $CLI_SET == false ]]; then
    TARGETS="html"
fi



############################################################################################
##
## ready to go
##
############################################################################################
ConsoleInfo "  -->" "libadoc: starting task"

LIBRARY_ADOC=${CONFIG_MAP["TARGET"]}/library
OUTPUT_DIR=${CONFIG_MAP["TARGET"]}/library-docs
ADOC_LIBRARY_HOME=
if [[ $BUILD_LOCAL == true ]]; then
    if [[ -z ${CONFIG_MAP["LIBRARY_HOME"]:-} ]]; then
        ConsoleError "  ->" "libadoc: build local without library home set, please set 'LIBRARY_HOME'"
        exit 61
    fi
    LIBRARY_ADOC=${CONFIG_MAP["TARGET"]}/library-local
    OUTPUT_DIR=${CONFIG_MAP["TARGET"]}/library-local-docs
    ADOC_LIBRARY_HOME="-a library-home=$(PathToSystemPath ${CONFIG_MAP["LIBRARY_HOME"]})"
fi
if [[ ! -d $LIBRARY_ADOC ]]; then
    ConsoleError "  ->" "libadoc: no ADOC source found in target '$LIBRARY_ADOC', build first"
    exit 61
fi

ConsoleDebug "remove and re-create output directory: $OUTPUT_DIR"
if [[ -d $OUTPUT_DIR ]]; then
    rm -fr $OUTPUT_DIR
fi
mkdir -p $OUTPUT_DIR

ADOC_LIBRARY="-a library-adoc=$LIBRARY_ADOC"
ADOC_LIBRARY_DOCS="-a library-docs=${CONFIG_MAP["LIBRARY_DOCS"]}"
ADOC_OUTPUT_DIR="--destination-dir $OUTPUT_DIR"

SKB_BUILD_DAY=$(date +"%d")
SKB_BUILD_MONTH=$(date +"%b")
SKB_BUILD_MONTH_LC=${SKB_BUILD_MONTH,,}
SKB_BUILD_YEAR=$(date +"%Y")
SKB_BUILD_DATE=$(date -I)
ADOC_SKB_ATTRIBUTES="-a skb-build-day=$SKB_BUILD_DAY -a skb-build-month=$SKB_BUILD_MONTH -a skb-build-month-lc=$SKB_BUILD_MONTH_LC -a skb-build-year=$SKB_BUILD_YEAR -a skb-build-date=$SKB_BUILD_DATE"

for FILE in ${CONFIG_MAP["LIBRARY_DOCS"]}/*.adoc; do
    for TARGET in $TARGETS; do
        ConsoleDebug "building file $FILE for target $TARGET"
        case $TARGET in
            html)
                asciidoctor $FILE $ADOC_OUTPUT_DIR $ADOC_LIBRARY $ADOC_LIBRARY_DOCS $ADOC_LIBRARY_HOME $ADOC_SKB_ATTRIBUTES -a toc=left
                ;;
            pdf)
                asciidoctor-pdf $FILE $ADOC_OUTPUT_DIR $ADOC_LIBRARY $ADOC_LIBRARY_DOCS $ADOC_LIBRARY_HOME $ADOC_SKB_ATTRIBUTES -a toc=left
                ;;
            *)
                ConsoleError "  ->" "libadoc: unknown target $TARGET"
                ;;
        esac
    done
done


ConsoleInfo "  -->" "libadoc: done"
exit $TASK_ERRORS
