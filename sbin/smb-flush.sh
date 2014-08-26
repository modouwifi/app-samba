#!/bin/sh
echo "---> flush">>/var/run/smb.log
CURDIR=$(cd $(dirname $0) && pwd)
PIDFILE="$CURDIR/../custom.pid"
CONFIDR="$CURDIR/../conf"
$CURDIR/../sbin/smb-tp.sh flush
if [ -f $PIDFILE ]; then
    pid=`cat $PIDFILE 2>/dev/null`;
    kill -SIGUSR1 $pid >/dev/null 2>&1;
fi
