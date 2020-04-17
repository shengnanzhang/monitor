#!/bin/bash
set -x
readonly DOMAIN="monitor.site7x24.net.cn"

#定义的是命令执行的超时时间
readonly TIMESEC="3"

readonly COMMAND="dig"

HOSTVALUE=$(date +%M|sed -r 's/0*([0-9])/\1/')

Domainlist=(ns1.jdgslb.com ns2.jdgslb.com ns3.jdgslb.com ns4.jdgslb.com ns5.jdgslb.com ns6.jdgslb.com vip1.jdgslb.com vip2.jdgslb.com freens1.jdgslb.com freens2.jdgslb.com 103.224.222.222 103.224.222.223)

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
    cd /var/lib/node_exporter/textfile && touch dnsplus_monitor.prom && chmod 755 dnsplus_monitor.prom && echo > dnsplus_monitor.prom
}

#对获取的value和预先定义好的value进行对比，判断结果是否正常
function check_result
{
    for NS in ${Domainlist[@]};do
	#直接将dig的结果获取的IP的最后一位拿出来
	result=$(timeout $TIMESEC $COMMAND $DOMAIN @"$NS" +short|head -n 1|cut -d "." -f4)

	#如果result有结果且结果是数字的话，则进行下面的处理；避免result没有获取到结果就参与计算，导致误报
	if [ "$result" -ge 0 ];then
	    if [ "$HOSTVALUE" -ge "$result" ];then
	        cost=$((HOSTVALUE - result ))
	    else
	    #对于跨周期的情况，实际时间会小于dns的结果，因此需要加一个60的周期进行补偿
	        cost=$((HOSTVALUE + 60 - result ))
	    fi

	    cd /var/lib/node_exporter/textfile && echo -e "dnsplus_monitor_status_$NS 0\ndnsplus_monitor_cost_$NS $cost" >>  dnsplus_monitor.prom
	else
	    cd /var/lib/node_exporter/textfile && echo -e "dnsplus_monitor_status_$NS -1\ndnsplus_monitor_cost_$NS  -1" >>  dnsplus_monitor.prom
	fi
    done
}

function main
{
    check_tools
    check_prometheus
    check_result  
}

main 
