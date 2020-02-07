#!/bin/bash
#set -x
#set encoding=utf-8

#定义的是基准文件的内容
readonly VALUE="success"

#定义的是命令执行的超时时间
readonly TIMESEC="3"

#文件名的随机后缀变量
KEY=$[$RANDOM]

#定义的是功能监控的写入目录
readonly MONITOR_PATH="/cfs-monitor/monitor"

#将输出结果默认赋值
result="-1"
cfs_monitor_status="-1"

#检查输出文件的目录，文件和权限
function check_prometheus
{
    mkdir -p $MONITOR_PATH
    mkdir -p  /var/lib/node_exporter/textfile
    cd /var/lib/node_exporter/textfile && touch cfs_monitor.prom && chmod 755 cfs_monitor.prom
}

#通过云硬盘写入文件后读取检查云硬盘的可用性
function check_result
{
    cd $MONITOR_PATH && timeout $TIMESEC echo $VALUE > cfs_monitor.$KEY
    result=$( timeout $TIMESEC   cat $MONITOR_PATH/cfs_monitor.$KEY)
    cd $MONITOR_PATH && timeout $TIMESEC rm -f cfs_monitor.$KEY

    
    if [ "$result" == "$VALUE" ];then
        cd /var/lib/node_exporter/textfile && echo "cfs_monitor_status 0" > cfs_monitor.prom
    else
        cd /var/lib/node_exporter/textfile && echo "cfs_monitor_status 1" > cfs_monitor.prom
    fi
}

function main
{
    check_prometheus
    check_result
}

main
