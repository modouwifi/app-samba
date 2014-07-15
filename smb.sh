#!/bin/sh 

# Throw Away a Brick in Order to Get a Gem, by roubo.
curdir=$(cd $(dirname $0) && pwd)
smbconf_def="$curdir/conf/smb.def"
smbconf="$curdir/conf/smb.conf"
smbpasswdfile="$curdir/conf/smbpasswd"

smb_try_user()
{
     # whether it is a system user
     sys_here=`cat /etc/passwd | grep "$1:" | wc -l`;
     if [ "0" == "$here" ]; then
         return 1; 
     fi
     
     # whether it is a samba user
     smb_here=`cat "$smbpasswdfile" | grep "$1:" | wc -l`;
     if [ "1" == "$smb_here" ]; then
         return 0; 
     fi
     return 2; 
}

smb_add_user()
{
    if [ "$#" != "2" ]; then
        echo " Usage: smb_add_user <user_name> <user_passwd> "
        return 1; 
    fi
    
    if [ ! -f "/lib/libbigballofmud.so.0" ]; then
        ln -s $curdir/lib/libbigballofmud.so /lib/libbigballofmud.so.0
    fi
    # Just in case
    smb_try_user $1;
    if [ "1" == "$?" ]; then
        echo "there is not the user in system";
        return 1;
    fi
    $curdir/bin/smbpasswd -c $smbconf_def $1 $2;
    if [ "1" == "$?" ]; then
        echo "add samba user $1 error";
        return 1;
    fi
    return 0;
}

smb_add_dir_help()
{
    echo " Help may be needed for function: smb_add_dir();"
    echo " Usage: smb_add_dir <share_name> <dir_name with path>  <allow_user> <user_passwd if need>"
    echo " Example1: smb_add_dir data /media/sda1 matrix "
    echo " Example2: smb_add_dir share /media/sda1 guest "
}

smb_add_dir()
{
    if [ ! -d "$2" ]; then
        smb_add_dir_help; 
        return 1;
    fi    
    smb_try_user $3;
    if [ "1" == "$?" ]; then
        echo "there is not the user $3 in system";
        return 1;
    elif [ "2" == "$?" ]; then
        smb_add_user $3 $4;
        if [ "1" == "$?" ]; then
            return 1;
        fi 
        echo "Add the user success"
    else
        # maybe need to change the passwd
        smb_add_user $3 $4;
        if [ "1" == "$?" ]; then
            return 1;
        fi 
        echo "Check the user success"
    fi
    if [ ! -f "$smbconf" ]; then
        cp "$smbconf_def" "$smbconf";
    fi
    if [ "guest" == "$3" ]; then 
        echo "
        ["$1"]
        comment = "$1 for $3" 
        path = "$2"
        browseable = yes
        writable = yes
        create mask = 0664
        directory mask = 0775
        public = yes 
        " >> $smbconf
    else
        echo "
        ["$1"]
        comment = "$1 for $3" 
        path = "$2"
        browseable = yes
        writable = yes
        create mask = 0664
        directory mask = 0775
        valid users = "$3"
        " >> $smbconf
    fi   
    return 0; 
}

smb_stop()
{
    killall smbd >/dev/null 2>&1;
    killall nmbd >/dev/null 2>&1;
    return 0;
}

smb_start()
{
    if [ ! -f "$smbconf" ]; then
        cp "$smbconf_def" "$smbconf";
    fi
    if [ ! -f "/lib/libbigballofmud.so.0" ]; then
        ln -s $curdir/lib/libbigballofmud.so /lib/libbigballofmud.so.0
    fi
    smb_stop;
    $curdir/bin/nmbd -D -s $smbconf;
    if [ "0" != "$?" ]; then
        smb_stop;
        return 1;
    fi
    $curdir/bin/smbd -D -s $smbconf;
    if [ "0" != "$?" ]; then
        smb_stop;
        return 1;
    fi
    return 0;
}

smb_restart()
{
    smb_stop;
    smb_start;
    if [ "0" != "$?" ]; then
        smb_stop;
        return 1;
    fi
    return 0;
}

smb_list_is_available()
{
    list=`mount | grep "/media/" | cut -d " " -f3`; 
    if [ "$list" == "" ]; then
        return 1;
    fi
    return 0;
}

smb_available_list()
{
    mount | grep "/media/" | cut -d " " -f3; 
    return 0;
}


smb_one_key_share()
{
    if [ "$1" != "" ]; then
        if [ "$1" == "public" -o "$1" == "private" ]; then
            as="$1";
        else
            as="private";
        fi
    else
        as="private";
    fi
    smb_list_is_available;
    if [ "1" == "$?" ]; then
        echo "Nothing to share with samba";
        return 1;
    fi
    # need to remove the old conf
    rm $smbconf >/dev/nul 2>&1;
    for share_path in `smb_available_list`
    do
        type=`mount | grep $share_path | cut -d " " -f5`;
        dev_num=`echo $share_path | cut -d "/" -f3`;
        if [ "$type" == "ntfs" ]; then
            umount $share_path;
            $curdir/bin/ntfs-3g /dev/$dev_num $share_path;
            if [ "1" == "$?" ]; then
                return 1;
            fi
        fi
        if [ "$as" == "public" ]; then
            smb_add_dir "share_${dev_num}" "$share_path" "guest";
            if [ "1" == "$?" ]; then
                return 1;
            fi
        else 
            password=`/bin/nvram_get 2860 Password`;
            smb_add_dir "data_${dev_num}" "$share_path" "matrix" "$password";
            if [ "1" == "$?" ]; then
                return 1;
            fi
        fi
    done
    smb_restart;
    return 0;
}

# Main
case $1 in
        "stop")
            smb_stop;
            if [ "0" != "$?" ]; then
                exit 1;
            fi 
            exit 0;
            ;;
        "start")
            smb_start;
            if [ "0" != "$?" ]; then
                exit 1;
            fi 
            exit 0;
            ;;
        "restart")
            smb_restart;
            if [ "0" != "$?" ]; then
                exit 1;
            fi 
            exit 0;
            ;;
        "smb_list_is_available")
            smb_list_is_available;
            if [ "0" != "$?" ]; then
                exit 1;
            fi 
            exit 0;
            ;;
        "smb_one_key_share_public")
            smb_one_key_share "public";
            if [ "0" != "$?" ]; then
                exit 1;
            fi 
            exit 0;
            ;;
        "smb_one_key_share_private")
            smb_one_key_share "private";
            if [ "0" != "$?" ]; then
                exit 1;
            fi 
            exit 0;
            ;;
         *)
            exit 1;
esac
