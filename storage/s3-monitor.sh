#!/bin/bash
#set -x
#set encoding=utf-8

#定义的是云存储文件的内容
readonly VALUE="success"

#定义的是命令执行的超时时间
readonly TIMESEC="3"
readonly URL="http://monitor.s3-internal.cn-east-2.jdcloud-oss.com/s3-monitor.txt"
#将输出结果默认赋值
result="-1"
s3_monitor_status="-1"

#检查输出文件的目录，文件和权限
function check_prometheus
{
    mkdir -p  /var/lib/node_exporter/textfile
    cd /var/lib/node_exporter/textfile && touch s3_monitor.prom && chmod 755 s3_monitor.prom
}

#通过云存储的接口获取指定文件的内容并和预先定义的内容进行比对
function check_result
{
    result=$( timeout $TIMESEC curl -s $URL)

    if [ "$result" == "$VALUE" ];then
        cd /var/lib/node_exporter/textfile && echo "s3_monitor_status 0" > s3_monitor.prom
    else
        cd /var/lib/node_exporter/textfile && echo "s3_monitor_status 1" > s3_monitor.prom
    fi
}

function main
{
    check_prometheus
    check_result
}

main
