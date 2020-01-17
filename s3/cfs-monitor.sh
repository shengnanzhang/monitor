#!/bin/bash
#set -x
#set encoding=utf-8

#定义的是云硬盘文件的内容
readonly VALUE="success"
KEY=$[$RANDOM]
#定义的是命令执行的超时时间
readonly TIMESEC="3"
readonly PATH1="/cfs-monitor/monitor"
#将输出结果默认赋值
result="-1"
cfs_monitor_status="-1"

#检查输出文件的目录，文件和权限
function check_tools
{
    mkdir -p  /var/lib/node_exporter/textfile
    cd /var/lib/node_exporter/textfile && touch cfs_monitor.prom && chmod 755 cfs_monitor.prom
    mkdir -p $PATH1
}

#通过云硬盘写入文件后读取检查云硬盘的可用性
function check_result
{
    cd $PATH1 && timeout $TIMESEC echo $VALUE > cfs_monitor.$KEY
    result=$( timeout $TIMESEC   cat $PATH1/cfs_monitor.$KEY)
    cd $PATH1 && timeout $TIMESEC rm -f cfs_monitor.$KEY

    cd /var/lib/node_exporter/textfile
    if [ "$result" == "$VALUE" ];then
        echo "cfs_monitor_status 0" > cfs_monitor.prom
    else
        echo "cfs_monitor_status 1" > cfs_monitor.prom
    fi
}

function main
{
    check_tools
    check_result
}

main
