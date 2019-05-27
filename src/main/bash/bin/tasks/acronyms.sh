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
## acronyms - finds SKB acronyms in YAML files
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
CLI_SET=false
SEARCH_SHORT=
SEARCH_LONG=
SEARCH_NOTES=
DUBPLICATES=false



##
## set CLI options and parse CLI
##
CLI_OPTIONS=dhl:n:s:x
CLI_LONG_OPTIONS=help
CLI_LONG_OPTIONS+=,short:,long:,notes:,duplicates

! PARSED=$(getopt --options "$CLI_OPTIONS" --longoptions "$CLI_LONG_OPTIONS" --name acronyms -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    ConsoleError "  ->" "acronyms: unknown CLI options"
    exit 51
fi
eval set -- "$PARSED"

PRINT_PADDING=25
while true; do
    case "$1" in
        -h | --help)
            CACHED_HELP=$(TaskGetCachedHelp "acronyms")
            if [[ -z ${CACHED_HELP:-} ]]; then
                printf "\n   options\n"
                BuildTaskHelpLine d dubplicates     "<none>"    "find and print duplpicate acronyms (short form)"       $PRINT_PADDING
                BuildTaskHelpLine h help            "<none>"    "print help screen and exit"                            $PRINT_PADDING
                BuildTaskHelpLine l long            "<string>"  "search for string in long form"                        $PRINT_PADDING
                BuildTaskHelpLine n notes           "<string>"  "search for string in description, notes, and URLs"     $PRINT_PADDING
                BuildTaskHelpLine s short           "<name>"    "search for acronym name"                               $PRINT_PADDING
            else
                cat $CACHED_HELP
            fi
            exit 0
            ;;

        -d | --duplicates)
            DUBPLICATES=true
            CLI_SET=true
            shift
            ;;

        -l | --long)
            SEARCH_LONG="$2"
            CLI_SET=true
            shift 2
            ;;

        -n | --notes)
            SEARCH_NOTES="$2"
            CLI_SET=true
            shift 2
            ;;

        -s | --short)
            SEARCH_SHORT="$2"
            CLI_SET=true
            shift 2
            ;;

        --)
            shift
            break
            ;;
        *)
            ConsoleFatal "  ->" "acronyms: internal error (task): CLI parsing bug"
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
ConsoleInfo "  -->" "acr: starting task"


ACRONYMS_ARGS=" -y ${CONFIG_MAP["ACRONYM_YAML"]}"

if [[ $DUBPLICATES == true ]]; then
    ACRONYMS_ARGS+=" --duplicates"
fi

if [[ -n "$SEARCH_LONG" ]]; then
    ACRONYMS_ARGS+=" --long ${SEARCH_LONG}"
fi

if [[ -n "$SEARCH_SHORT" ]]; then
    ACRONYMS_ARGS+=" --short ${SEARCH_SHORT}"
fi

if [[ -n "$SEARCH_NOTES" ]]; then
    ACRONYMS_ARGS+=" --notes ${SEARCH_NOTES}"
fi

${CONFIG_MAP["APP_HOME"]}/bin/python/acronyms.py $ACRONYMS_ARGS
__errno=$?
exit $?


ConsoleInfo "  -->" "acr: done"
exit $TASK_ERRORS
