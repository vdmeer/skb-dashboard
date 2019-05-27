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
## acronyms-build - builds targets (e.g. ADOC) from acronym YAML sources
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
TARGETS=
ALL=false
DO_CLEAN=false
CLI_SET=false



##
## set CLI options and parse CLI
##
CLI_OPTIONS=Aach
CLI_LONG_OPTIONS=help
CLI_LONG_OPTIONS+=,clean,all,adoc

! PARSED=$(getopt --options "$CLI_OPTIONS" --longoptions "$CLI_LONG_OPTIONS" --name acronyms-build -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    ConsoleError "  ->" "acronyms-build: unknown CLI options"
    exit 51
fi
eval set -- "$PARSED"

PRINT_PADDING=25
while true; do
    case "$1" in
        -h | --help)
            CACHED_HELP=$(TaskGetCachedHelp "acronyms-build")
            if [[ -z ${CACHED_HELP:-} ]]; then
                printf "\n   options\n"
                BuildTaskHelpLine c clean           "<none>"    "cleans build artifacts"            $PRINT_PADDING
                BuildTaskHelpLine h help            "<none>"    "print help screen and exit"        $PRINT_PADDING
                printf "\n   targets\n"
                BuildTaskHelpLine A     all         "<none>"    "generate all targets"              $PRINT_PADDING
                BuildTaskHelpLine a     adoc        "<none>"    "generate ADOC"                     $PRINT_PADDING

                printf "\n   Notes\n"
                printf "Created ADOC files will be written to the target directory\n"
                printf "Entry files for ADOC files will be created in the target directory\n"
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
        -a | --adoc)
            TARGETS=$TARGETS" adoc"
            CLI_SET=true
            shift
            ;;

        -c | --clean)
            DO_CLEAN=true
            shift
            ;;

        --)
            shift
            break
            ;;
        *)
            ConsoleFatal "  ->" "acronyms-build: internal error (task): CLI parsing bug"
            exit 52
    esac
done



############################################################################################
## test requirements and CLI
############################################################################################
if [[ $ALL == true ]]; then
    TARGETS="adoc"
fi
if [[ $CLI_SET == false ]]; then
    TARGETS="adoc"
fi



############################################################################################
##
## ready to go
##
############################################################################################
ConsoleInfo "  -->" "acrbuild: starting task"

OUTPUT_DIRECTORY="${CONFIG_MAP["TARGET"]}/acronyms"

if [[ $DO_CLEAN == true ]]; then
    if [[ -d "$OUTPUT_DIRECTORY" ]]; then
        find $OUTPUT_DIRECTORY -depth -type f -delete
        rmdir `find $OUTPUT_DIRECTORY -type d | sort -nr`
    fi
fi

ACRONYMS_ARGS=" -y ${CONFIG_MAP["ACRONYM_YAML"]}"
ACRONYMS_ARGS+=" --output-directory ${OUTPUT_DIRECTORY}"

for TARGET in $TARGETS; do
    case $TARGET in
        adoc)       ACRONYMS_ARGS+=" --adoc" ;;
    esac
done

${CONFIG_MAP["APP_HOME"]}/bin/python/acronyms-build.py $ACRONYMS_ARGS
__errno=$?
exit $?


ConsoleInfo "  -->" "acrbuild: done"
exit $TASK_ERRORS
