#!/bin/bash
#set -x
#set encoding=utf-8

#使用说明：
#默认情况下，仅需要修改SERVER、PORT、PASSWORD的值，即可执行脚本进行对mysql服务的可用性监控


readonly DOMAIN="mysql-cn-east-2-01a7e0233e934844.rds.jdcloud.com"
#readonly DOMAIN="mysql-cn-east-2-01a7e0233e9348445.rds.jdcloud.com"
readonly TYPE="A"

#key的定义要尽量复杂，避免和业务的key冲突了
#定义的是监控key的失效时间
readonly TTL="60"
readonly COMMAND="dig"

#定义的是命令执行的超时时间
readonly TIMESEC="3"

#将输出结果默认赋值
result="-1"

#判断是否安装了工具，如果没有安装则先安装完毕
function check_tools
{
    if [ ! -f /usr/bin/dig ];then
        nohup yum install -y dig >/dev/null 2>&1
    fi

    mkdir -p  /var/lib/node_exporter/textfile 
    cd /var/lib/node_exporter/textfile && touch dns_monitor.prom && chmod 755 dns_monitor.prom
}

# dig 域名解析
# 增加timeout命令，限制执行时间，避免超时卡死
# 不关注命令执行的返回值，没有任何意义，需要通过获取key:value来判断才更合理
function dig_action
{
    result=$(timeout $TIMESEC $COMMAND $DOMAIN |grep "ANSWER SECTION")
    echo "$?"
}

#对获取的value和预先定义好的value进行对比，判断结果是否正常
function check_result
{
    if [ "$result"!="" ]; then
        echo 0
        #cd /var/lib/node_exporter/textfile && echo "mysql_monitor_status 0" > mysql_monitor.prom
    else
        echo 1
        #cd /var/lib/node_exporter/textfile && echo "mysql_monitor_status 1" > mysql_monitor.prom
    fi
}

function main
{  
    content=""
    check_tools
    metric="dns_monitor_status"
    dig_action
    content="$content$metric $(check_result)\n"
    cd /var/lib/node_exporter/textfile && echo -e $content > dns_monitor.prom
}

main
