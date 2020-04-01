#!/bin/bash
#set -x
#set encoding=utf-8

#域名的选择要求：尽量不要使用线上的域名进行监控，而应该使用线上同一个zone的，自己申请的域名，避免线上域名IP变换后，导致的不必要的报警
readonly Domainlist=(www.baidu.com www.qq.com www.kuaishou.com www.toutiao.com)
#定义的是命令执行的超时时间
readonly TIMESEC="10"

readonly COMMAND="/usr/bin/curl -s -I"

#将输出结果默认赋值
result="0"

#判断是否安装了dig工具，如果没有安装则先安装bind-utils包
#判断是否提供了
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
    number=$(timeout "$TIMESEC" "$COMMAND" "$domain" |grep -c HTTP)
    if [ "$number" -eq 1 ];then
        result=$((result + 1))
    fi
    done

    cd /var/lib/node_exporter/textfile && echo "nat_monitor_status $result" >  nat_monitor.prom
}

function main
{
    check_tools
    check_prometheus
    monitor_action
    check_result
}

main
