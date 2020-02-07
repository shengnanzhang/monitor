#!/bin/bash
#set -x
#set encoding=utf-8

#脚本说明：
# 未实现的功能1：没有统计DNS请求的耗时
# 未实现的功能2：没有进行加强版功能监控，就是取值为10.0.0.x，x取值为[0-59],从而便于识别延时和故障定位

#使用说明：

#域名的选择要求：尽量不要使用线上的域名进行监控，而应该使用线上同一个zone的，自己申请的域名，避免线上域名IP变换后，导致的不必要的报警
#需要注意的是：同一个zone是需要了解细节的，可能不同的二级域名归属于不同的dns-server维护，需要了解这个细节，最好是知道每个master是谁
readonly DOMAIN="mysql-cn-east-2-01a7e0233e934844.rds.jdcloud.com"
readonly COMMAND="dig"
readonly IP="10.0.128.4"

#说明：上面使用的是最简单的固定的IP地址进行可用性监控，因此在缓存作用干扰的情况下，其实无法很好的判断集群是否正常，为此，可以使用加强版的功能监控，
#  具体来说：每分钟修改dns的解析结果，10.0.0.x，x的取值是当前的分钟数，取值范围可以是0-59，这样对于下游来讲，就可以知道延时多久，和哪个环节延时较大

#定义的是命令执行的超时时间
readonly TIMESEC="3"

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

# dig 域名解析
# 增加timeout命令，限制执行时间，避免超时卡死
# 增加+short是为了让返回值仅仅返回IP地址，增加sort是为了让IP排序后进行检查，目前暂未考虑多个IP地址的问题
# 如对可能，可以使用dig www.baidu.com +short @dns-master来直接检查master上ip生效的情况，避免延时生效导致大规模故障的发生
# 更进一步的，为了便于定位异常发生在哪个阶段，最好是对DNS分发的整个过程的各个环节都进行dig，这样就比较容易找出是哪个环节的问题
function monitor_action
{
    result=$(timeout $TIMESEC $COMMAND $DOMAIN +short|sort)
}

#对获取的value和预先定义好的value进行对比，判断结果是否正常
function check_result
{
    if [ "$result" == "$IP" ]; then
        cd /var/lib/node_exporter/textfile && echo "dns_monitor_status 0" >  dns_monitor.prom
    else
        cd /var/lib/node_exporter/textfile && echo "dns_monitor_status 1" >  dns_monitor.prom
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
