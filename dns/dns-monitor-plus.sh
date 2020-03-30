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
    #判断输入的参数数量是否为1，如果为1，则将NS设置为$1；如果不为1，直接上默认的8.8.8.8
    if [ $# -eq 1 ];then
        NS=$1
    else
        NS="8.8.8.8"
    fi

    #直接将dig的结果获取的IP的最后一位拿出来
    result=$(timeout $TIMESEC $COMMAND $DOMAIN @"$NS" +short|head -n 1|cut -d "." -f4)

    #如果result有结果且结果是数字的话，则进行下面的处理；避免result没有获取到结果就参与计算，导致误报
    #cost里面均有-1,是因为调度层面会有1分钟左右的延时，dns修改Ip地址的调度延时，以及dns检查Ip地址的调度延时，最坏是2min，通常不超过1min
    if [ "$result" -ge 1 ];then
	if [ "$HOSTVALUE" -ge "$result" ];then
	    cost=$((HOSTVALUE - result - 1))
	else
	    #对于跨周期的情况，实际时间会小于dns的结果，因此需要加一个60的周期进行补偿
	    cost=$((HOSTVALUE + 60 - result -1 ))
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