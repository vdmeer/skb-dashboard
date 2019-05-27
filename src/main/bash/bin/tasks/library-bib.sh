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
## library-bib - processes SKB library to build BIB file
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


## we want extended pattern matching
shopt -s extglob


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
CLI_SET=false
DO_BIB=false




##
## set CLI options and parse CLI
##
CLI_OPTIONS=bh
CLI_LONG_OPTIONS=bib,help

! PARSED=$(getopt --options "$CLI_OPTIONS" --longoptions "$CLI_LONG_OPTIONS" --name library-bib -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    ConsoleError "  ->" "library-bib: unknown CLI options"
    exit 51
fi
eval set -- "$PARSED"

PRINT_PADDING=25
while true; do
    case "$1" in
        -h | --help)
            CACHED_HELP=$(TaskGetCachedHelp "library-bib")
            if [[ -z ${CACHED_HELP:-} ]]; then
                printf "\n   options\n"
                BuildTaskHelpLine b bib  "<none>" "use BiBTeX references instead of Biblatex"   $PRINT_PADDING
                BuildTaskHelpLine h help "<none>" "print help screen and exit"                  $PRINT_PADDING
            else
                cat $CACHED_HELP
            fi
            exit 0
            ;;

        -b | --bib)
            DO_BIB=true
            CLI_SET=true
            shift
            ;;

        --)
            shift
            break
            ;;
        *)
            ConsoleFatal "  ->" "library-bib: internal error (task): CLI parsing bug"
            exit 52
    esac
done



############################################################################################
## test requirements and CLI
############################################################################################



############################################################################################
##
## ready to go
##
############################################################################################
ConsoleInfo "  -->" "libbib: starting task"

if [[ -n "${CONFIG_MAP["LATEX_AUX"]:-}" ]]; then
    if [[ ! -r "${CONFIG_MAP["LATEX_AUX"]:-}" ]]; then
        ConsoleError "  ->" "libbib: could not read LATEX_AUX '${CONFIG_MAP["LATEX_AUX"]:-}'"
        ConsoleInfo "  -->" "libbib: done"
        exit 61
    fi
fi

if [[ -n "${CONFIG_MAP["LIBRARY_BIB_FILE"]:-}" ]]; then
    if [[ ! -w "${CONFIG_MAP["LIBRARY_BIB_FILE"]:-}" ]]; then
        ConsoleError "  ->" "libbib: could not write LIBRARY_BIB_FILE '${CONFIG_MAP["LIBRARY_BIB_FILE"]:-}'"
        ConsoleInfo "  -->" "libbib: done"
        exit 60
    fi
fi

FILE_EXT="-biblatex.bib"
if [[ $DO_BIB == true ]]; then
    FILE_EXT=".bib"
fi

AUX=$(cat ${CONFIG_MAP["LATEX_AUX"]:-})
REFERENCES=
for LINE in $AUX; do
    case $LINE in
        *"abx@aux@cite"*)
            LINE=${LINE#*\{}
            LINE=${LINE%\}*}
            REFERENCES=(${REFERENCES[@]:-} $LINE)
            ;;
        *)
            ;;
    esac
done

FILE_SET=
for i in ${!REFERENCES[@]}; do
    ID=${REFERENCES[$i]}
    FILE="${ID#cite:}"
    FILE="${CONFIG_MAP["LIBRARY_YAML"]}/${FILE//+([:])/\/}${FILE_EXT}"
    if [[ -r "${FILE}" ]]; then
        FILE_SET=(${FILE_SET[@]:-} $FILE)
    fi
#     printf "%s -- %s\n" "$ID" "$FILE"
done

if [[ "${#FILE_SET[@]}" > 0 ]]; then
    rm "${CONFIG_MAP["LIBRARY_BIB_FILE"]}"
    echo > "${CONFIG_MAP["LIBRARY_BIB_FILE"]}"
    for i in ${!FILE_SET[@]}; do
        FILE="${FILE_SET[$i]}"
        cat "$FILE" >> "${CONFIG_MAP["LIBRARY_BIB_FILE"]}"
    done
    ConsoleInfo "  -->" "libbib: references - ${#FILE_SET[@]} --> ${CONFIG_MAP["LIBRARY_BIB_FILE"]}"


    REFERENCES_CR=
    while read LINE; do
        case $LINE in
            *"crossref"*)
                LINE=${LINE#*crossref*\{}
                LINE=${LINE%\}*}
                REFERENCES_CR=(${REFERENCES_CR[@]:-} $LINE)
                ;;
            *)
                ;;
        esac
    done < "${CONFIG_MAP["LIBRARY_BIB_FILE"]}"
    FILE_SET_CR=
    for i in ${!REFERENCES_CR[@]}; do
        ID=${REFERENCES_CR[$i]}
        FILE="${ID#cite:}"
        FILE="${CONFIG_MAP["LIBRARY_YAML"]}/${FILE//+([:])/\/}${FILE_EXT}"
        if [[ -r "${FILE}" ]]; then
            FILE_SET_CR=(${FILE_SET_CR[@]:-} $FILE)
        fi
    done
    if [[ -n "${FILE_SET_CR:-}" && "${#FILE_SET_CR[@]}" > 0 ]]; then
        for i in ${!FILE_SET_CR[@]}; do
            FILE="${FILE_SET_CR[$i]}"
            cat "$FILE" >> "${CONFIG_MAP["LIBRARY_BIB_FILE"]}"
        done
        ConsoleInfo "  -->" "libbib: crossrefs  - ${#FILE_SET_CR[@]} --> ${CONFIG_MAP["LIBRARY_BIB_FILE"]}"
    fi
fi


ConsoleInfo "  -->" "libbib: done"
exit $TASK_ERRORS
