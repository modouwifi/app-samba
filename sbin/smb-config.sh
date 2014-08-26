#!/bin/sh
echo "---> config" >>/var/run/smb.log
CURDIR=$(cd $(dirname $0) && pwd)
PIDFILE_SET="$CURDIR/../custom_set.pid"
PIDFILE="$CURDIR/../custom.pid"
NEXTCONF="$CURDIR/../conf/next.conf"
rm $NEXTCONF 1>/dev/null 2>&1
$CURDIR/../sbin/smb-tp.sh config
$CURDIR/../sbin/smb-tp.sh flush
if [ -f $PIDFILE ]; then
    pid=`cat $PIDFILE 2>/dev/null`;
    kill -SIGUSR1 $pid >/dev/null 2>&1;
fi
custom $CURDIR/../conf/samba-custom-set.conf&
echo $! > $PIDFILE_SET
