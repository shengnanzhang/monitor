#!/bin/bash
#set -x
#set encoding=utf-8
#source ~/.bash_profile
readonly DOMAIN="monitor.site7x24.net.cn"

#定义的是命令执行的超时时间
readonly TIMESEC="3"

readonly COMMAND="dig"

HOSTVALUE=$(date +%M|sed -r 's/0*([0-9])/\1/')
NS=$1
#将输出结果默认赋值
result="-1"

#判断是否安装了dig工具，如果没有安装则先安装bind-utils包
#判断是否提供了
function check_tools
{
    if [ ! -f /usr/bin/dig ];then
        nohup yum install -y bind-utils >/dev/null 2>&1
    fi
}

#检查输出到prometheus的目录和文件是否存在，以及权限是否正确
function check_prometheus
{
    mkdir -p  /var/lib/node_exporter/textfile
    cd /var/lib/node_exporter/textfile && touch dns_monitor.prom && chmod 755 dns_monitor.prom
}

#对获取的value和预先定义好的value进行对比，判断结果是否正常
function check_result
{
    if [ $# -eq 1 ];then
        NS=$1
    else
        NS="8.8.8.8"
    fi

    result=$(timeout $TIMESEC $COMMAND $DOMAIN @"$NS" +short|head -n 1|cut -d "." -f4)

    if [ "$result" -ge 0 ];then
	if [ "$HOSTVALUE" -ge "$result" ];then
	    cost=$((HOSTVALUE - result))
	else
	    #对于跨周期的情况，实际时间会小于dns的结果，因此需要加一个60的周期进行补偿
	    cost=$((HOSTVALUE + 60 - result))
	fi

	cd /var/lib/node_exporter/textfile && echo -e "dnsplus_monitor_status{target=\"$NS\"} 0\ndnsplus_monitor_cost{target=\"$NS\"} $cost" >  dnsplus_monitor.prom
    else
	cd /var/lib/node_exporter/textfile && echo -e "dnsplus_monitor_status{target=\"$NS\"} -1\ndnsplus_monitor_cost{target=\"$NS\"} -1" >  dnsplus_monitor.prom

    fi
}

function main
{
    check_tools
    check_prometheus
    check_result  "$@"
}

main "$@"
