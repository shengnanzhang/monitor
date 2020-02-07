#!/bin/bash
#set -x
#set encoding=utf-8

#使用说明：
#默认情况下，仅需要修改SERVER、PORT、PASSWORD的值，即可执行脚本进行对mysql服务的可用性监控

readonly SERVER="mysql-cn-east-2-01a7e0233e934844.rds.jdcloud.com"
readonly PASSWORD="Chaos_monitor1"
readonly USER="Chaos_monitor1"
readonly DATABASE="monitor"

#定义的是监控key的失效时间
readonly TTL="60"

readonly COMMAND="mysql"

#定义的是命令执行的超时时间
readonly TIMESEC="3"

#将输出结果默认赋值
result="-1"
mysql_monitor_status="-1"

#判断是否安装了mysql-cli工具，如果没有安装则先安装完毕
#安装mysql-cli工具，需要先安装epel源才可以
function check_tools
{
    if [ ! -f /usr/bin/mysql-cli ];then
        nohup yum install -y epel-release >/dev/null 2>&1
        nohup yum install -y mysql >/dev/null 2>&1
    fi
}

function check_prometheus
{
    mkdir -p  /var/lib/node_exporter/textfile 
    cd /var/lib/node_exporter/textfile && touch mysql_monitor.prom && chmod 755 mysql_monitor.prom
}

# 增加timeout命令，限制执行时间，避免超时卡死
# 不关注命令执行的返回值，没有任何意义，需要通过获取key:value来判断才更合理
function monitor_action
{
    timeout $TIMESEC $COMMAND -h $SERVER -u $USER -p$PASSWORD -D$DATABASE -e "insert into test (id) values (7); "
    result=$(timeout $TIMESEC $COMMAND -h $SERVER -u $USER -p$PASSWORD -D$DATABASE -e "select count(*) from test where id = 1;")
    timeout $TIMESEC $COMMAND -h $SERVER -u $USER -p$PASSWORD -D$DATABASE -e "delete from test where id=7;"
}





function check_result
{
    if [ $result!=0 ]; then
        cd /var/lib/node_exporter/textfile && echo "mysql_monitor_status 0" > mysql_monitor.prom
    else
        cd /var/lib/node_exporter/textfile && echo "mysql_monitor_status 1" > mysql_monitor.prom
    fi
}

function main
{  
    check_tools
    check_prometheus
    monitor_action
    check_result
}

main
