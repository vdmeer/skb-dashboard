#! /bin/sh
#
# This script is called after package software is removed
#

echo  "********************postrm*******************"
echo "arguments $*"
echo  "*********************************************"

# Check for debian upgrade case which calls postrm, in which we do nothing
if [ "$1" = "upgrade" ]; then
    exit 0
fi

# Check if a soft link for Dashboard exists, if so remove it
echo " ==> removing symlinks"
if [ -L "/usr/local/bin/skb-dashboard" ]; then
    rm /usr/local/bin/skb-dashboard
fi
if [ -L "/usr/local/share/man/man1/skb-dashboard.1" ]; then
    rm /usr/local/share/man/man1/skb-dashboard.1
fi

echo " ==> removing /opt/skb-dashboard"
rm -fr /opt/skb/dashboard

echo " ==> removing /var/cache/skb-dashboard"
rm -fr /var/cache/skb-dashboard
