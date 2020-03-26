#!/bin/bash
#set -x
#set encoding=utf-8
#脚本说明：
# 未实现的功能1：没有统计DNS请求的耗时，当前超时时间统一设置，无法识别是不可用导致的脚本异常，还是超时导致的异常
# 未实现的功能2：没有进行加强版功能监控，就是取值为10.0.0.x，x取值为[0-59],时间的分钟数取值，这样就可以知道整体的延时情况
# 未实现的功能3：需要将所有的zone进行监控，而非随机取一个进行监控，因此需要了解公司整体zone的分布情况，分别是由那些集群来管理的
# 未实现的功能4：如果可能，可以使用dig www.baidu.com +short @dns-master来直接检查master上ip生效的情况，避免延时生效导致大规模故障的发生
# 未实现的功能5：为了便于定位异常发生在哪个阶段，最好是对DNS分发的整个过程的各个环节都进行dig，这样就比较容易找出是哪个环节的问题

#域名的选择要求：尽量不要使用线上的域名进行监控，而应该使用线上同一个zone的，自己申请的域名，避免线上域名IP变换后，导致的不必要的报警
readonly DOMAIN="monitor.site7x24.net.cn"
readonly IP="1.1.1.1"

#定义的是命令执行的超时时间
readonly TIMESEC="3"

readonly COMMAND="dig"

HOSTVALUE="1.1.1."$(date +%M)

#将输出结果默认赋值
result="-1"
dns_monitor_status="-1"

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
function monitor_action
{   
    proc="/root/src/monitor/dns/dns-monitor"
    
    ll -h &  chmod u+x ${proc} && ${proc} $HOSTVALUE
    result=$(timeout $TIMESEC $COMMAND $DOMAIN +short|sort)
}

#对获取的value和预先定义好的value进行对比，判断结果是否正常
function check_result
{
    if [ "$result" == "$IP" ]; then
        cd /var/lib/node_exporter/textfile && echo "dns_monitor_status{result=\"$result\"} 0" >  dns_monitor.prom
    else
        cd /var/lib/node_exporter/textfile && echo "dns_monitor_status{result=\"$result\"} 1" >  dns_monitor.prom
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
