#!/bin/bash
#set -x
#set encoding=utf-8

#域名的选择要求：找国内的几个大的网站，假设他们不会同时全部故障
readonly Domainlist=(www.baidu.com www.qq.com www.kuaishou.com www.toutiao.com)

#定义的是命令执行的超时时间
readonly TIMESEC="10"

readonly COMMAND="/usr/bin/curl"

#将输出结果默认赋值
result="0"
number="0"

#判断是否安装了curl工具，如果没有安装则先安装curl包
function check_tools
{
    if [ ! -f "$COMMAND" ];then
        nohup yum install -y curl >/dev/null 2>&1
    fi
}

#检查输出到prometheus的目录和文件是否存在，以及权限是否正确
function check_prometheus
{
    mkdir -p  /var/lib/node_exporter/textfile
    cd /var/lib/node_exporter/textfile && touch nat_monitor.prom && chmod 755 nat_monitor.prom
}

#对获取的value和预先定义好的value进行对比，判断结果是否正常
function check_result
{
    for domain in "${Domainlist[@]}";do
    number=$(timeout "$TIMESEC" "$COMMAND" -s -I "$domain" |grep -c HTTP)
    if [ "$number" -ge 1 ];then
        result=$((result + 1))
    fi
    done

    length=${#Domainlist[@]}
    if [ "$length" -ge "$((result / 2))" ];then
        cd /var/lib/node_exporter/textfile && echo "nat_monitor_status 0" >  nat_monitor.prom
    else
        cd /var/lib/node_exporter/textfile && echo "nat_monitor_status 1" >  nat_monitor.prom
    fi
}

function main
{
    check_tools
    check_prometheus
    check_result
}

main
