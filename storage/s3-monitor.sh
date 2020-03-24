#!/bin/bash
#set -x
#set encoding=utf-8
source ./log.sh
#定义的是云存储文件的内容
readonly VALUE="success"
readonly LOGFILE="/var/log/s3-monitor.log"
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
    local start=$(date +%s%N)
    result=$( timeout $TIMESEC curl -s $URL)
    local end=$(date +%s%N)
    local cost=$[$end-$start]
   
     #目前原因暂未定位，如果下面打印log的部分，放到上面cost的上面，那么耗时就会增加非常多，和用系统的time命令得到的时间相差较大，但放在下面就没有问题
    log_info $result >> $LOGFILE

    
    if [ "$result" == "$VALUE" ];then
        cd /var/lib/node_exporter/textfile && echo -e "s3_monitor_status 0\ns3_read_cost $cost" > s3_monitor.prom
    else
        cd /var/lib/node_exporter/textfile && echo -e "s3_monitor_status 1\ns3_read_cost $cost" > s3_monitor.prom
    fi
}

function main
{
    check_prometheus
    check_result
}

main
