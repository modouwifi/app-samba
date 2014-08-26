#!/bin/sh
echo "---> open" >>/var/run/smb.log
CURDIR=$(cd $(dirname $0) && pwd)
PIDFILE_SET="$CURDIR/../custom_set.pid"
$CURDIR/../sbin/smb-tp.sh 'set' '1' 'matrix'
if [ -f $PIDFILE_SET ]; then
    pid=`cat $PIDFILE_SET 2>/dev/null`;
    kill -SIGUSR1 $pid >/dev/null 2>&1;
fi
