#!/bin/bash
set -x
#set encoding=utf-8

#使用说明：
#默认情况下，仅需要修改SERVER、PORT、PASSWORD的值，即可执行脚本进行对mysql服务的可用性监控
#mysql -h mysql-cn-cast-2-01a7e0233e934844.rds.jdcloud.com -U Chaos_monitor1 -PChaos_monitor1 -D monitor -c "select count(*) from test"
psql -h pg-cast2-10c0167e9bb5449c.rds.jdcloud.com -p5432 -UChaos_monitor1  -dmonitor -f create_table.sql

readonly SERVER="pg-east2-10c0167e9bb5449c.rds.jdcloud.com"
readonly PORT="5432"
readonly PASSWORD="Chaosmonitor1"
readonly USER="Chaos_monitor1"
readonly DATABASE="monitor"
readonly localhost=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`

#key的定义要尽量复杂，避免和业务的key冲突了
#定义的是监控key的失效时间
readonly TTL="60"
readonly COMMAND="psql"

#定义的是命令执行的超时时间
readonly TIMESEC="3"
datetime=$(date "+%Y-%m-%d %H:%M:%S")
echo $datetime
#将输出结果默认赋值
#result="-1"
insert_status="-1"
select_status="-1"
postgreSQL_status="-1"

#判断是否安装了mysql-cli工具，如果没有安装则先安装完毕
#安装mysql-cli工具，需要先安装epel源才可以
function check_tools
{
    if [ ! -f /usr/bin/mysql-cli ];then
        nohup yum install -y epel-release >/dev/null 2>&1
        nohup yum install -y mysql >/dev/null 2>&1
    fi

    mkdir -P  /var/lib/node_exporter/textfile 
    cd /var/lib/node_exporter/textfile && touch postgreSQL_monitor.prom && chmod 755 postgreSQL_monitor.prom
    export PGPASSWORD=$PASSWORD
}

# 往mysql中添加一个key，并设置key的过期时间较短
# 设置过期时间的目的是，避免服务异常不能写入而无法发现
# 增加timeout命令，限制执行时间，避免超时卡死
# 不关注命令执行的返回值，没有任何意义，需要通过获取key:value来判断才更合理
function postgreSQL_insert
{
    
    result=$(timeout $TIMESEC $COMMAND -h $SERVER -p $PORT -U $USER  -d$DATABASE -c "insert into test (host, time) values ('$localhost', '$datetime')")
    echo $?
}

# 从mysql中读取一个key
# 增加timeout命令，限制执行时间，避免超时卡死
# 取出一个key之后不能直接删除这个key，通过过期时间删除即可，防止del掉这个key的时候，各种异常导致误删除业务上的key
function postgreSQL_select
{
    result=$(timeout $TIMESEC $COMMAND -h $SERVER -p $PORT -U $USER  -d$DATABASE -q -c "select time from test where host='$localhost';" |grep "$datetime")
    if [ -z "$result"];then
        echo 1
    else
        echo 0
    fi
}

function postgreSQL_delete
{
    result=$(timeout $TIMESEC $COMMAND -h $SERVER -p $PORT -U $USER  -d$DATABASE -q -c "delete from test where host='$localhost';")
    if [ -z "$result"];then
        echo 1
    else
        echo 0
    fi
}



#对获取的value和预先定义好的value进行对比，判断mysql是否正常
function check_result
{
    if [ -z "$*"]; then
        echo 1
        #cd /var/lib/node_exporter/textfile && echo "postgreSQL_monitor_status 0" > postgreSQL_monitor.prom
    else
        echo 0
        #cd /var/lib/node_exporter/textfile && echo "postgreSQL_monitor_status 1" > postgreSQL_monitor.prom
    fi
}


function main
{  
    content=""
    check_tools
    metric="postgreSQL_monitor_insert"
    local start=$(date +%s%N)
    insert_status=$(postgreSQL_insert)
    local end=$(date +%s%N)
    local cost=$[$end-$start]
    #insert_status=$(check_result)
    content="$content$metric $insert_status\npostgreSQL_insert_cost $cost\n"
    
    metric="postgreSQL_monitor_select"
    local start=$(date +%s%N)
    select_status=$(postgreSQL_select)
    local end=$(date +%s%N)
    local cost=$[$end-$start]
    select_status=$(check_result $select_status)
    content="$content$metric $select_status\npostgreSQL_select_cost $cost\n"
    
    metric="postgreSQL_monitor_status"
    postgreSQL_status=$insert_status&&$select_status
    content="$content$metric $postgreSQL_status\n"
    cd /var/lib/node_exporter/textfile && echo -e $content > postgreSQL_monitor.prom
    
    postgreSQL_delete    
}

main
