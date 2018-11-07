#! /bin/sh
#
# This script is called before package software is installed
#

echo  "********************preinst*******************"
echo "arguments $*"
echo  "**********************************************"

# Check if Dashboard is running
if [ -d /tmp/skb-dashboard ]; then
    if [ "`ls /tmp/skb-dashboard | wc -l`" != "0" ]; then
        echo "==> SKB Dashboard processes are running, stop prior to package upgrade"
        echo "==> alternatively: remove /tmp/skb-dashboard"
        exit 1
    fi
fi

mkdir -p /usr/local/share/man/man1/

if ! getent group "skbuser" >/dev/null 2>&1
then
    echo "creating group skbuser . . ."
    groupadd skbuser
fi

if ! getent passwd "skbuser" >/dev/null 2>&1
then
    echo "creating user skbuser . . ."
    useradd -g skbuser skbuser
    usermod -a -G skbuser skbuser
fi

# Create the skbuser home directory
mkdir -p /home/skbuser
chown -R skbuser:skbuser /home/skbuser
