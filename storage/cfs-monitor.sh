#!/bin/bash
#set -x
#set encoding=utf-8

#定义的是基准文件的内容，内容本身是什么并无所谓，需要关注的是写入内容的长度，体积，是否有特殊字符串，换行等等
readonly MD5="e37115d4da0e187130ab645dee4f14ed"

#定义的是命令执行的超时时间
readonly TIMESECsmall="3"
readonly TIMESEClarge="20"

#文件名的随机后缀变量
KEY=$((RANDOM))

#定义的是功能监控的写入目录
readonly MONITOR_PATH="/cfs-monitor/monitor"

#将输出结果默认赋值
result="-1"
cfs_monitor_status="-1"
cfs_monitor_time="-1"

#检查输出文件的目录，文件和权限
function check_prometheus
{
    mkdir -p $MONITOR_PATH
    mkdir -p  /var/lib/node_exporter/textfile
    cd /var/lib/node_exporter/textfile && touch cfs_monitor.prom && chmod 755 cfs_monitor.prom
}

#通过云硬盘写入文件后读取检查云硬盘的可用性
function check_result
{
    cd $MONITOR_PATH && timeout $TIMESECsmall echo $MD5 > cfs_monitor."$KEY"

    result=$( timeout $TIMESECsmall cat $MONITOR_PATH/cfs_monitor."$KEY")

    cd $MONITOR_PATH && timeout $TIMESECsmall /usr/bin/rm -f cfs_monitor."$KEY"

    if [ "$result" == "$MD5" ];then
        cd /var/lib/node_exporter/textfile && echo "cfs_monitor_status 0" > cfs_monitor.prom
    else
        cd /var/lib/node_exporter/textfile && echo "cfs_monitor_status 1" > cfs_monitor.prom
    fi
}

#通过云硬盘写入1000MB文件来测试性能
function check_performance
{
    Begin_time=$(date +%s)
    cd $MONITOR_PATH && timeout $TIMESEClarge dd if=/dev/zero of=./cfs_monitor.performance."$KEY" bs=1MB count=1000 2>/dev/null
    End_time=$(date +%s)
    time_result=$((End_time - Begin_time))

    if [ "$(md5sum cfs_monitor.performance."$KEY"|grep -c $MD5)" -eq 1 ];then
        cd /var/lib/node_exporter/textfile && echo "cfs_monitor_time $time_result" >> cfs_monitor.prom
    else
        cd /var/lib/node_exporter/textfile && echo "cfs_monitor_time -1" >> cfs_monitor.prom
    fi
    cd $MONITOR_PATH && rm -f cfs_monitor.performance."$KEY"
}

function main
{
    check_prometheus
    check_result
    check_performance
}

main
