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
## Build script for creating PPA Debian file
## - builds PPA distribution
##
## @author     Sven van der Meer <vdmeer.sven@mykolab.com>
##

set -o errexit -o pipefail -o noclobber -o nounset
shopt -s globstar

RELEASE_VERSION="$(cat src/main/bash/etc/version.txt)"
TOOL_VERSION="${RELEASE_VERSION}"
TARBALL="./build/distributions/skb-dashboard-${RELEASE_VERSION}-src.tar.gz"
TARGET=/tmp/skb-dashboard-${RELEASE_VERSION}
SKB_HOME=$PWD


help(){ 
    printf "\nusage: build-ppa [targets]\n"
    printf "\n  targets:"
    printf "\n    all       - build all target in the right order"
    printf "\n    clean     - remove all built artifacts (gradle, maven)"
    printf "\n    dist      - build dashboard artifacts and then distributions (gradle)"
    printf "\n    mkdirs    - create required directories to run the dashboard"
    printf "\n"
    printf "\n Requirements:"
#    printf "\n - gradle          - to build the Java tool and the distributions"
#    printf "\n - JDK8            - to build the tool"
#    printf "\n - Apache Ant      - to set file versions"
#    printf "\n - Apache Maven    - to build the site"
#    printf "\n - asciidoctor     - to build some targets for the manual"
#    printf "\n - asciidoctor-pdf - to build the PDF manual"
#    printf "\n - coderay         - for syntax highlighting in ADOC files"
#    printf "\n Requirements are not tested, build will simply fail"
#    printf "\n\n"
}


if [[ -z "${1:-}" ]]; then
    help
    exit 1
fi


##
## function: clean - cleans all artifacts
##
clean(){ 
    printf "%s\n\n" "clean"

    rm -fr ${TARGET}

    printf "\n\n"
}


##
## function: distro - builds PPA distributions
##
fw_distro(){ 
    printf "%s\n\n" "building dashboard PPA distribution"

    (cd ${TARGET}; bzr dh-make skb-dashboard ${RELEASE_VERSION} ${SKB_HOME}/${TARBALL})

    for file in ${TARGET}/skb-dashboard/debian/*; do
        if [[ -f $file ]]; then
            rm $file
        fi
    done

    (cd ${TARGET}/skb-dashboard/debian; cp ${SKB_HOME}/src/package/debian-ppa/* .)

    for file in ${TARGET}/skb-dashboard/debian/*; do
        if [[ -f $file ]]; then
            chmod 644 $file
        fi
    done
    chmod 755 ${TARGET}/skb-dashboard/debian/rules
    chmod 755 ${TARGET}/skb-dashboard/debian/postinst
    chmod 755 ${TARGET}/skb-dashboard/debian/postrm

    (cd ${TARGET}/skb-dashboard; bzr add debian/source/format debian/*)
    (cd ${TARGET}/skb-dashboard; bzr commit -m "Initial commit of Debian packaging.")
    (cd ${TARGET}/skb-dashboard; bzr builddeb -- -us -uc)
    (cd ${TARGET}/skb-dashboard; bzr builddeb -S)

    printf "\n\n"
}


##
## function: mkdirs - create required directories
##
fw_mkdirs(){ 
    mkdir -p ${TARGET} 2> /dev/null
}


while [[ $# -gt 0 ]]; do
    case "$1" in
        all)
            T_CLEAN=true
            T_MKDIRS=true
            T_DIST=true
            shift
            ;;
        clean)
            T_CLEAN=true
            shift
            ;;
        dist)
            T_DIST=true
            shift
            ;;
        mkdirs)
            T_MKDIRS=true
            shift
            ;;
        -h | --help)
            help
            exit 0
            ;;
        *)
            printf "\nunknown target '$1'\n\n"
            help
            exit 2
            ;;
    esac
done


if [[ ! -f "${TARBALL}" ]]; then
    echo "no tarball found, build distribution first"
    echo " - looking for: ${TARBALL}"
    exit 3
fi


if [[ -z "$(command -v bzr)" ]]; then
    echo "bzr not found, cannot build"
    exit 3
fi


TS=$(date +%s.%N)
TIME_START=$(date +"%T")

if [[ ${T_CLEAN:-} == true ]]; then
    clean
fi

if [[ ${T_MKDIRS:-} == true ]]; then
    fw_mkdirs
fi
if [[ ${T_DIST:-} == true ]]; then
    fw_distro
fi


TE=$(date +%s.%N)

TIME=$(date +"%T")
RUNTIME=$(echo "($TE-$TS)/60" | bc -l)
printf "started:  $TIME_START\n"
printf "finished: $TIME, in $RUNTIME minutes\n\n"

