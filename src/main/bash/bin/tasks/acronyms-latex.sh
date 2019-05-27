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
## acronyms-latex - processes SKB acronyms to build LaTeX file
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




##
## set CLI options and parse CLI
##
CLI_OPTIONS=h
CLI_LONG_OPTIONS=help

! PARSED=$(getopt --options "$CLI_OPTIONS" --longoptions "$CLI_LONG_OPTIONS" --name acronyms-latex -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    ConsoleError "  ->" "acronyms-latex: unknown CLI options"
    exit 51
fi
eval set -- "$PARSED"

PRINT_PADDING=25
while true; do
    case "$1" in
        -h | --help)
            CACHED_HELP=$(TaskGetCachedHelp "acronyms-latex")
            if [[ -z ${CACHED_HELP:-} ]]; then
                printf "\n   options\n"
                BuildTaskHelpLine h help "<none>" "print help screen and exit" $PRINT_PADDING
            else
                cat $CACHED_HELP
            fi
            exit 0
            ;;

        --)
            shift
            break
            ;;
        *)
            ConsoleFatal "  ->" "acronyms-latex: internal error (task): CLI parsing bug"
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
ConsoleInfo "  -->" "acrltx: starting task"


ACRONYMS_ARGS=" -y ${CONFIG_MAP["ACRONYM_YAML"]}"

if [[ -n "${CONFIG_MAP["LATEX_AUX"]:-}" ]]; then
    if [[ ! -r "${CONFIG_MAP["LATEX_AUX"]:-}" ]]; then
        ConsoleError "  ->" "acrltx: could not read LATEX_AUX '${CONFIG_MAP["LATEX_AUX"]:-}'"
        ConsoleInfo "  -->" "acrltx: done"
        exit 61
    else
        ACRONYMS_ARGS+=" --aux ${CONFIG_MAP["LATEX_AUX"]:-}"
    fi
fi

if [[ -n "${CONFIG_MAP["ACRONYM_LATEX_FILE"]:-}" ]]; then
    if [[ ! -w "${CONFIG_MAP["ACRONYM_LATEX_FILE"]:-}" ]]; then
        ConsoleError "  ->" "acrltx: could not write ACRONYM_LATEX_FILE '${CONFIG_MAP["ACRONYM_LATEX_FILE"]:-}'"
        ConsoleInfo "  -->" "acrltx: done"
        exit 60
    else
        ACRONYMS_ARGS+=" --output-file ${CONFIG_MAP["ACRONYM_LATEX_FILE"]:-}"
    fi
fi

${CONFIG_MAP["APP_HOME"]}/bin/python/acronyms-latex.py $ACRONYMS_ARGS
__errno=$?
exit $?


ConsoleInfo "  -->" "acrltx: done"
exit $TASK_ERRORS


# #!/usr/bin/env bash
# 
# AUX=`cat lcn-acronyms.aux`
# ACRONYMS=
# for LINE in $AUX; do
#     case $LINE in
#         *acronymused*)
#             LINE=${LINE#*\{}
#             LINE=${LINE%\}*}
#             ACRONYMS=(${ACRONYMS[@]:-} $LINE)
#             ;;
#         *)
#             ;;
#     esac
# done
# ACRONYMS=($(printf '%s\n' "${ACRONYMS[@]:-}" | sort -u))
# 
# TMP_FILE=$(mktemp "${TMPDIR:-/tmp/}$(basename $0)-$(date +"%H-%M-%S")-XXX")
# for i in ${!ACRONYMS[@]}; do
#     ID=${ACRONYMS[$i]}
#     #printf "%s\n" "$ID"
#     echo $ID >> $TMP_FILE
# done
# 
# cat $TMP_FILE
# rm $TMP_FILE