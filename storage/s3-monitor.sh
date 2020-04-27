#!/bin/bash
#定义的是命令执行的超时时间
readonly TIMESEC="30"
readonly URL="http://chaos-monitor.s3.cn-north-1.jdcloud-oss.com/5g-unlocks-a-world-of-opportunities-cn.pdf"
#将输出结果默认赋值
result="-1"
s3_monitor_status="-1"
MD5="71cfb9febe321ad91f0d58e1c2c50e46  -"

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
    result=$(timeout $TIMESEC curl -s $URL|md5sum)
    local end=$(date +%s%N)
    local cost=$[$end-$start]

    if [ "$result"=="$MD5" ];then
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
