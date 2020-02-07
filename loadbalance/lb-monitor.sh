#!/bin/bash
#set -x
#set encoding=utf-8

#定义的检查内容
readonly VALUE="CentOS"
readonly URL="http://114.67.64.243/"

#定义的是命令执行的超时时间
readonly TIMESEC="3"

#将输出结果默认赋值
result="-1"
lb_monitor_status="-1"

#检查输出文件的目录，文件和权限
function check_prometheus
{
    mkdir -p  /var/lib/node_exporter/textfile
    cd /var/lib/node_exporter/textfile && touch lb_monitor.prom && chmod 755 lb_monitor.prom
}

#通过云存储的接口获取指定文件的内容并和预先定义的内容进行比对
function check_result
{
    result=$( timeout $TIMESEC curl -s $URL 2>/dev/null |grep -c  $VALUE)

    if [ "$result" -gt 1 ];then
        cd /var/lib/node_exporter/textfile && echo "lb_monitor_status 0" > lb_monitor.prom
    else
        cd /var/lib/node_exporter/textfile && echo "lb_monitor_status 1" > lb_monitor.prom
    fi
}

function main
{
    check_prometheus
    check_result
}

main
