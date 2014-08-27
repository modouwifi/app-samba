#!/bin/sh
CURDIR=$(cd $(dirname $0) && pwd)
PIDFILE_SET="$CURDIR/../custom_set.pid"
PIDFILE="$CURDIR/../custom.pid"
NEXTCONF="$CURDIR/../conf/next.conf"

smb_config()
{
    rm $NEXTCONF 1>/dev/null 2>&1
    $CURDIR/../sbin/smb-tp.sh config
    $CURDIR/../sbin/smb-tp.sh flush
    if [ -f $PIDFILE ]; then
        pid=`cat $PIDFILE 2>/dev/null`;
        kill -SIGUSR1 $pid >/dev/null 2>&1;
    fi
    custom $CURDIR/../conf/samba-custom-set.conf&
    echo $! > $PIDFILE_SET
}

smb_flush()
{
    $CURDIR/../sbin/smb-tp.sh flush
    if [ -f $PIDFILE ]; then
        pid=`cat $PIDFILE 2>/dev/null`;
        kill -SIGUSR1 $pid >/dev/null 2>&1;
    fi
}

smb_next()
{
    $CURDIR/../sbin/smb-tp.sh config
    nextcountfile=`cat $NEXTCONF`;
    if [ "${nextcountfile}" == "0" ]; then
        $CURDIR/../sbin/smb-tp.sh flush
        if [ -f $PIDFILE ]; then
            pid=`cat $PIDFILE 2>/dev/null`;
            kill -SIGUSR1 $pid >/dev/null 2>&1;
        fi
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
}

smb_openmd()
{
    $CURDIR/../sbin/smb-tp.sh 'set' '1' 'matrix'
    if [ -f $PIDFILE_SET ]; then
        pid=`cat $PIDFILE_SET 2>/dev/null`;
        kill -SIGUSR1 $pid >/dev/null 2>&1;
    fi
}

smb_passwd()
{
    input-text "password"  "输入密码" "/var/run/samba.tmp" 1 22
    passwd=`cat /var/run/samba.tmp 2>/dev/null`
    $CURDIR/../sbin/smb-tp.sh 'set' '2' $passwd
    if [ -f $PIDFILE_SET ]; then
        pid=`cat $PIDFILE_SET 2>/dev/null`;
        kill -SIGUSR1 $pid >/dev/null 2>&1;
    fi
}

smb_tp_start()
{
    $CURDIR/../sbin/smb-tp.sh flush
    custom $CURDIR/../conf/samba-custom.conf 1>/dev/null 2>&1 &
    echo $! > $PIDFILE
}

smb_server_start()
{
    $CURDIR/../init start
    $CURDIR/../sbin/smb-tp.sh flush
    if [ -f $PIDFILE ]; then
        pid=`cat $PIDFILE 2>/dev/null`;
        kill -SIGUSR1 $pid >/dev/null 2>&1;
    fi
}

smb_server_stop()
{
    $CURDIR/../init stop
    $CURDIR/../sbin/smb-tp.sh flush
    if [ -f $PIDFILE ]; then
        pid=`cat $PIDFILE 2>/dev/null`;
        kill -SIGUSR1 $pid >/dev/null 2>&1;
    fi
}


# main
case "$1" in
    "flush")
        smb_flush;
        exit 0;
        ;;
    "config")
        smb_config;
        exit 0;
        ;;
    "next")
        smb_next;
        exit 0;
        ;;
    "openmd")
        smb_openmd;
        exit 0;
        ;;
    "passwd")
        smb_passwd;
        exit 0;
        ;;
    "tpstart")
        smb_tp_start;
        exit 0;
        ;;
    "serverstart")
        smb_server_start;
        exit 0;
        ;;
    "serverstop")
        smb_server_stop;
        exit 0;
        ;;
    *)
        echo "nothing"
        exit 0;
        ;;
esac
