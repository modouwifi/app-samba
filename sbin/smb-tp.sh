#!/bin/sh
curdir=$(cd $(dirname $0) && pwd)
MATCHCONF="$curdir/../conf/match.conf"
NEXTCONF="$curdir/../conf/next.conf"
SETCONF="$curdir/../conf/set.conf"
MAINCUSTOMCONF="$curdir/../conf/samba-custom.conf"
MAINCUSTOMCONF_SET="$curdir/../conf/samba-custom-set.conf"
SMBSTATUSFILE="$curdir/../conf/smb.status"
SHELLBUTTON1_CLOSE="$curdir/../init stop"
SHELLBUTTON1_OPEN="$curdir/../init start"
SHELLBUTTON2="$curdir/../sbin/smb-config.sh"
SHELLBUTTON3="$curdir/../sbin/smb-flush.sh"
SHELLBUTTON4="$curdir/../sbin/smb-next.sh"
SHELLBUTTON5="$curdir/../sbin/smb-open.sh"
SHELLBUTTON6="$curdir/../sbin/smb-passwd.sh"
HEAD='"cmd":"'
TAIL='",'
CMDBUTTON1_CLOSE="${HEAD}${SHELLBUTTON1_CLOSE}${TAIL}"
CMDBUTTON1_OPEN="${HEAD}${SHELLBUTTON1_OPEN}${TAIL}"
CMDBUTTON2="${HEAD}${SHELLBUTTON2}${TAIL}"
CMDBUTTON3="${HEAD}${SHELLBUTTON3}${TAIL}"
CMDBUTTON4="${HEAD}${SHELLBUTTON4}${TAIL}"
CMDBUTTON5="${HEAD}${SHELLBUTTON5}${TAIL}"
CMDBUTTON6="${HEAD}${SHELLBUTTON6}${TAIL}"

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

smb_flush_match_config()
{
    tag="_0_null"
    if [ ! -f $MATCHCONF ]; then
        touch $MATCHCONF;
        for nodes in `smb_available_list`
        do
            echo "${nodes}${tag}" >> $MATCHCONF;
        done
    else
        for nodes in `smb_available_list`
        do
            cat $MATCHCONF | grep $nodes 1>/dev/null 2>&1
            if [ "$?" != "0" ]; then
                echo "${nodes}${tag}" >> $MATCHCONF;
            fi
        done
    fi
    return 0;
}

smb_get_type_from_match()
{
    if [ "$#" == "2" ]; then
        return 1;
    fi
    node="$1";
    type=`cat $MATCHCONF | grep "$node" | cut -d '_' -f2`;
    echo $type;
    return 0;
}


smb_set_match()
{
    node="$1";
    type="$2";
    passwd="$3";
    node1=`echo $node | cut -d '/' -f3`
    new=${node1}"_"${type}"_"${passwd}
    old=`cat $MATCHCONF | grep "$node" | cut -d '/' -f3-`
    sed -i "s/$old/$new/" $MATCHCONF
}

smb_get_passwd_from_match()
{
    if [ "$#" == "2" ]; then
        return 1;
    fi
    node="$1";
    passwd=`cat $MATCHCONF | grep "$node" | cut -d '_' -f3-`;
    echo $passwd;
    return 0;
}

smb_gen_content_flush()
{
    contenthead='"content":"'
    contenttail='",'
    contentbody=""
    otherwd=" ..... "
    linetag="\n"
    smb_list_is_available;
    if [ "$?" == "1" ]; then
        contentbody="无可共享设备,请插入U盘或移动硬盘,并点击刷新按钮";
        echo ${contenthead}${contentbody}${contenttail};
        return 0;
    fi
    smb_flush_match_config;
    for nodes in `smb_available_list`
    do
        type=`smb_get_type_from_match $nodes`
        passwd=`smb_get_passwd_from_match $nodes`
        case "$type" in
            "0")
                typewd="未共享的";
                ;;
            "1")
                typewd="开放共享的";
                ;;
            "2")
                typewd="加密共享的";
                ;;
            *)
                typewd="未知的";
                ;;
        esac
        contentbody="${contentbody}${nodes}${otherwd}${typewd}${linetag}";
    done
    echo ${contenthead}${contentbody}${contenttail};
    return 0;
}

smb_gen_content_config()
{
    contenthead='"content":"'
    contenttail='",'
    contentbody=""
    nextcount=1;
    [ ! -f $NEXTCONF ] && touch $NEXTCONF && echo 2 > $NEXTCONF;
    nextcountfile=`cat $NEXTCONF`;
    smb_list_is_available;
    if [ "$?" == "1" ]; then
        contentbody="无可配置项";
        echo ${contenthead}${contentbody}${contenttail};
        return 0;
    fi
    smb_flush_match_config;
    allcount=`smb_available_list | wc -l`
    let allcount+=2
    let tmp=allcount-nextcountfile
    if [ "$tmp" == "0" ]; then
        echo 0 > $NEXTCONF
        return 0
    fi
    for nodes in `smb_available_list`
    do
        let nextcount+=1
        if [ "${nextcountfile}" == "${nextcount}" ]; then
            echo $nodes > $SETCONF
            type=`smb_get_type_from_match $nodes`
            passwd=`smb_get_passwd_from_match $nodes`
            titlewd="正在配置${nodes}\n"
            case "$type" in
                "0")
                    typewd="当前状态为未共享";
                    ;;
                "1")
                    typewd="当前状态为开放共享";
                    ;;
                "2")
                    typewd="当前状态为加密共享";
                    ;;
                *)
                    typewd="当前状态未知";
                    ;;
            esac
            contentbody="${contentbody}${titlewd}${typewd}";
            if [ "${nextcountfile}" == "${allcount}" ]; then
                echo 0 > $NEXTCONF;
            else
                let nextcountfile+=1
                echo $nextcountfile > $NEXTCONF;
            fi
            break;
        fi
    done
    echo ${contenthead}${contentbody}${contenttail};
    return 0;

}

smb_gen_maincustomcof_flush()
{
    smbstatus=`cat $SMBSTATUSFILE 2>/dev/null`
    if [ "${smbstatus}" == "1" ]; then
        echo '
        {
            "title" : "魔豆文件共享(已开)",
        ' > $MAINCUSTOMCONF

        content=`smb_gen_content_flush`
        echo $content >> $MAINCUSTOMCONF

        echo '
        "button1" :  {
            "txt" : "关闭服务",
        ' >> $MAINCUSTOMCONF
        echo $CMDBUTTON1_CLOSE >> $MAINCUSTOMCONF
    else
        echo '
        {
            "title" : "魔豆文件共享(已关)",
        ' > $MAINCUSTOMCONF

        content=`smb_gen_content_flush`
        echo $content >> $MAINCUSTOMCONF
        echo '
        "button1" :  {
            "txt" : "开启服务",
        ' >> $MAINCUSTOMCONF
        echo $CMDBUTTON1_OPEN >> $MAINCUSTOMCONF
    fi
    echo '
    "code" : {
          "0" : "Nothing",
          "256" : "Nothing too"
        }
      },

    "button2" :  {
        "txt" : "配置",
    ' >> $MAINCUSTOMCONF
    echo $CMDBUTTON2 >> $MAINCUSTOMCONF

    echo '
        "code" : {
          "0" : "Nothing",
          "256" : "Nothing too"
        }
      },

      "button3" :  {
        "txt" : "刷新",
    ' >> $MAINCUSTOMCONF

    echo $CMDBUTTON3 >> $MAINCUSTOMCONF

    echo '
        "code" : {
          "0" : "Nothing",
          "256" : "Nothing too"
        }
      }
    }
    ' >>$MAINCUSTOMCONF
    return 0;
}

smb_gen_maincustomcof_config()
{
    smbstatus=`cat $SMBSTATUSFILE 2>/dev/null`
    if [ "${smbstatus}" == "1" ]; then
        echo '
        {
            "title" : "魔豆文件共享(已开)",
        ' > $MAINCUSTOMCONF_SET
    else
        echo '
        {
            "title" : "魔豆文件共享(已关)",
        ' > $MAINCUSTOMCONF_SET
    fi

    content=`smb_gen_content_config`
    echo $content >> $MAINCUSTOMCONF_SET

    echo '
    "button1" :  {
        "txt" : "开放共享",
    ' >> $MAINCUSTOMCONF_SET

    echo $CMDBUTTON5 >> $MAINCUSTOMCONF_SET

    echo '
        "code" : {
          "0" : "Nothing",
          "256" : "Nothing too"
        }
      },

      "button2" :  {
        "txt" : "加密分享",
    ' >> $MAINCUSTOMCONF_SET

    echo $CMDBUTTON6 >> $MAINCUSTOMCONF_SET

    echo '
        "code" : {
          "0" : "Nothing",
          "256" : "Nothing too"
        }
      },
      "button3" :  {
        "txt" : "下一项",
    ' >> $MAINCUSTOMCONF_SET

    echo $CMDBUTTON4 >> $MAINCUSTOMCONF_SET

    echo '
        "code" : {
          "0" : "Nothing",
          "256" : "Nothing too"
        }
      }
    }
    ' >>$MAINCUSTOMCONF_SET
    return 0;
}

# main
case "$1" in
    "flush")
        rm $MAINCUSTOMCONF 1>/dev/null 2>&1
        touch $MAINCUSTOMCONF;
        smb_gen_maincustomcof_flush;
        exit 0;
        ;;
    "config")
        rm $MAINCUSTOMCONF_SET 1>/dev/null 2>&1
        touch $MAINCUSTOMCONF_SET;
        smb_gen_maincustomcof_config;
        exit 0;
        ;;
    "set")
        style=$2;
        passwd=$3;
        node=`cat $SETCONF`
        smb_set_match $node $style $passwd
        if [ ! -f $NEXTCONF ]; then
            echo 2 > $NEXTCONF
        fi
        nextcountfile=`cat $NEXTCONF`;
        if [ "${nextcountfile}" == "0" ]; then
            allcount=`smb_available_list | wc -l`
            echo $allcount > $NEXTCONF;
            rm $MAINCUSTOMCONF_SET 1>/dev/null 2>&1
            touch $MAINCUSTOMCONF_SET;
            smb_gen_maincustomcof_config;
            echo 0 > $NEXTCONF;
        else
            let nextcountfile-=1
            echo $nextcountfile > $NEXTCONF;
            rm $MAINCUSTOMCONF_SET 1>/dev/null 2>&1
            touch $MAINCUSTOMCONF_SET;
            smb_gen_maincustomcof_config;
            let nextcountfile+=1
            echo $nextcountfile > $NEXTCONF;
        fi
        exit 0;
        ;;
    *)
        exit 0;
        ;;
esac
