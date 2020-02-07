#!/bin/bash
#set -x
#set encoding=utf-8

#定义的是云硬盘文件的内容
readonly VALUE="success"

#定义的是命令执行的超时时间
readonly TIMESEC="3"

#将输出结果默认赋值
result="-1"
netdisk_monitor_status="-1"

#检查输出文件的目录，文件和权限
function check_prometheus
{
    mkdir -p  /var/lib/node_exporter/textfile
    cd /var/lib/node_exporter/textfile && touch netdisk_monitor.prom && chmod 755 netdisk_monitor.prom
}

#通过云硬盘写入文件后读取检查云硬盘的可用性
function check_result
{
    cd /tmp && timeout $TIMESEC /usr/bin/rm -f netdisk_monitor
    
    cd /tmp && timeout $TIMESEC echo $VALUE > netdisk_monitor
    
    result=$( timeout $TIMESEC cat /tmp/netdisk_monitor)

    if [ "$result" == "$VALUE" ];then
        cd /var/lib/node_exporter/textfile && echo "netdisk_monitor_status 0" > netdisk_monitor.prom
    else
        cd /var/lib/node_exporter/textfile && echo "netdisk_monitor_status 1" > netdisk_monitor.prom
    fi
}

function main
{
    check_prometheus
    check_result
}

main
