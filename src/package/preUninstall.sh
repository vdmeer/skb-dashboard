#! /bin/sh
#
# This script is called before package software is removed
#

echo  "**********************prerm********************"
echo "arguments $*"
echo  "***********************************************"

# Check if Dashboard is running
if [ -d /tmp/skb-dashboard ]; then
    if [ "`ls /tmp/skb-dashboard | wc -l`" != "0" ]; then
        echo "==> SKB Dashboard processes are running, stop prior to package upgrade"
        echo "==> alternatively: remove /tmp/skb-dashboard"
        exit 1
    fi
fi
