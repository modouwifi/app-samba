 #!/bin/sh
echo "---> passwd" >>/var/run/smb.log
CURDIR=$(cd $(dirname $0) && pwd)
PIDFILE_SET="$CURDIR/../custom_set.pid"
input-text "password"  "输入密码" "/var/run/samba.tmp" 1 22
passwd=`cat /var/run/samba.tmp 2>/dev/null`
$CURDIR/../sbin/smb-tp.sh 'set' '2' $passwd
if [ -f $PIDFILE_SET ]; then
    pid=`cat $PIDFILE_SET 2>/dev/null`;
    kill -SIGUSR1 $pid >/dev/null 2>&1;
fi
