#! /bin/sh
#
# This script is called after package software is installed
#

echo  "********************postinst****************"
echo "arguments $*"
echo  "***********************************************"

# Check for debian abort-remove case which calls postinst, in which we do nothing
if [ "$1" = "abort-remove" ]; then
    exit 0
fi

# Ensure everything has the correct permissions
find /opt/skb/dashboard -type d -perm 755
find /opt/skb/dashboard/bin -type f -perm 555
find /opt/skb/dashboard/etc -type f -perm 664
find /opt/skb/dashboard/man -type f -perm 644
find /opt/skb/dashboard/scenarios -type f -perm 644

chown -R skbuser:skbuser /opt/skb/dashboard

mkdir -p /var/cache/skb-dashboard
chown -R skbuser:skbuser /var/cache/skb-dashboard