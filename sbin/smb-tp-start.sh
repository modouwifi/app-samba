#!/bin/sh
echo "---> start" >/var/run/smb.log
CURDIR=$(cd $(dirname $0) && pwd)
PIDFILE="$CURDIR/../custom.pid"
$CURDIR/../sbin/smb-tp.sh flush
custom $CURDIR/../conf/samba-custom.conf 1>/dev/null 2>&1 &
echo $! > $PIDFILE
