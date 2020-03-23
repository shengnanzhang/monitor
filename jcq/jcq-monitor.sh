#!/bin/bash
set -x
#set encoding=utf-8

#使用说明：
#默认情况下，仅需要修改SERVER、PORT、PASSWORD的值，即可执行脚本进行对es服务的可用性监控


readonly SERVER="http://es-nlb-es-wp54diftud.jvessel-open-sh.jdcloud.com:9200"
readonly USER="Chaos_monitor1"
readonly DATABASE="monitor"
readonly localhost=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`
KEY="shakespeare_"$localhost
EXEC_PATH=$(pwd)
DATA_FILE=$EXEC_PATH/data/shakespeare.json
#curl -XGET $SERVER/_cat

#key的定义要尽量复杂，避免和业务的key冲突了
#定义的是监控key的失效时间
readonly TTL="60"
readonly COMMAND="curl"

#定义的是命令执行的超时时间
readonly TIMESEC="3"

#将输出结果默认赋值
#result="-1"
write_status="-1"
cat_status="-1"
es_status="-1"

#判断是否安装了es-cli工具，如果没有安装则先安装完毕
#安装es-cli工具，需要先安装epel源才可以
function check_tools
{
    if [ ! -f /usr/bin/jq ];then
        nohup yum install -y curl >/dev/null 2>&1
        nohup yum install -y  epel-release 2>&1
        nohup yum install -y jq >/dev/null 2>&1
    fi

    mkdir -p  /var/lib/node_exporter/textfile 
    cd /var/lib/node_exporter/textfile && touch es_monitor.prom && chmod 755 es_monitor.prom
    mkdir $EXEC_PATH/data
    DATA_FILE=$EXEC_PATH/data/shakespeare.json
    head -n 20 $EXEC_PATH/shakespeare.json > $DATA_FILE
    sed -i 's/\"_index\":\"shakespeare\"/\"_index\":\"'"$KEY"'\"/g' $DATA_FILE
}

# 不关注命令执行的返回值，没有任何意义，需要通过获取key:value来判断才更合理
function es_mapping_create
{
    result=$(timeout $TIMESEC $COMMAND -H 'Content-Type: application/json' -XPUT $SERVER/$KEY -d '{ "mappings" : { "_default_" : { "properties" : { "speaker" : {"type": "keyword" }, "play_name" : {"type": "keyword" }, "line_id" : { "type" : "integer" }, "speech_number" : { "type" : "integer" } } } } }' )
    if [ $(echo $result | jq '.acknowledged') == true ];then
        echo true
    else
        echo false
    fi
}

# 往es中添加一个key，并设置key的过期时间较短
# 设置过期时间的目的是，避免服务异常不能写入而无法发现
# 增加timeout命令，限制执行时间，避免超时卡死
# 不关注命令执行的返回值，没有任何意义，需要通过获取key:value来判断才更合理
function es_write
{
    result=$(timeout $TIMESEC $COMMAND -H 'Content-Type: application/x-ndjson' -XPOST $SERVER/$KEY/_bulk?pretty --data-binary @$DATA_FILE)
    if [ $(echo $result|jq '.errors') == true ];then
        echo false
    else
        echo true 
    fi
}

# 从es中读取一个key
# 增加timeout命令，限制执行时间，避免超时卡死
# 取出一个key之后不能直接删除这个key，通过过期时间删除即可，防止del掉这个key的时候，各种异常导致误删除业务上的key
function es_read
{
    result=$(timeout $TIMESEC $COMMAND -XGET "$SERVER/_cat/indices/$KEY?v" |awk -F ' ' '{print $7}'| grep -v docs.count )
    if [ $result -gt 0 ];then
        echo true
    else  
        echo false
    fi 
}

function es_delete
{
    result=$(timeout $TIMESEC $COMMAND -XDELETE "$SERVER/$KEY")
    if [ $(echo $result | jq '.acknowledged') == true ];then
        echo true
    else
        echo false
    fi
}
#对获取的value和预先定义好的value进行对比，判断es是否正常
function check_result
{
    if [ $* == true ]; then
        echo 0
        #cd /var/lib/node_exporter/textfile && echo "es_monitor_status 0" > es_monitor.prom
    else
        echo 1
        #cd /var/lib/node_exporter/textfile && echo "es_monitor_status 1" > es_monitor.prom
    fi
}


function main
{  
    content=""
    check_tools

    metric="es_monitor_create"
    create_result=$(es_mapping_create)
    create_status=$(check_result $create_result)
    content="$content$metric $create_status\n"
     
    metric="es_monitor_write"
    write_result=$(es_write)
    write_status=$(check_result $write_result)
    content="$content$metric $write_status\n"
    sleep 1 
    metric="es_monitor_read"
    read_status=$(es_read)
    read_status=$(check_result $read_status)
    content="$content$metric $read_status\n"

    metric="es_monitor_delete"
    delete_result=$(es_delete)
    delete_status=$(check_result $delete_result)
    content="$content$metric $delete_status\n"
    
    metric="es_monitor_status"
    es_status=$create_status&&$write_status&&$read_status
    content="$content$metric $es_status\n"
    
    cd /var/lib/node_exporter/textfile && echo -e $content > es_monitor.prom
}

main
