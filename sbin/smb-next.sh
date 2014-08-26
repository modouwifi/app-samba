#!/bin/sh
echo "---> next" >>/var/run/smb.log
CURDIR=$(cd $(dirname $0) && pwd)
PIDFILE_SET="$CURDIR/../custom_set.pid"
PIDFILE="$CURDIR/../custom.pid"
NEXTCONF="$CURDIR/../conf/next.conf"
$CURDIR/../sbin/smb-tp.sh config
nextcountfile=`cat $NEXTCONF`;
if [ "${nextcountfile}" == "0" ]; then
    if [ -f $PIDFILE_SET ]; then
        pid=`cat $PIDFILE_SET 2>/dev/null`;
        kill -9 $pid >/dev/null 2>&1;
    fi
else
    if [ -f $PIDFILE_SET ]; then
        pid=`cat $PIDFILE_SET 2>/dev/null`;
        kill -SIGUSR1 $pid >/dev/null 2>&1;
    fi
fi
