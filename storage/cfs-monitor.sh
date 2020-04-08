#!/bin/bash
#set encoding=utf-8
#代码规范遵循shellcheck.net的要求
#建议：使用一个非线上账号进行相关的功能验证，会更加安全，这样即使有问题，也不会将系统文件给误删除！！！
source ~/.bash_profile
source ./log.sh
#定义的是不同体积的文件，其MD5，作为string写入被测试文件来验证文件内容的正确性
#bs=1MB count=1000 的MD5:  e37115d4da0e187130ab645dee4f14ed
#bs=1MB count=100  的MD5:  0f86d7c5a6180cf9584c1d21144d85b0
#bs=1MB count=10   的MD5:  311175294563b07db7ea80dee2e5b3c6

readonly MD5="0f86d7c5a6180cf9584c1d21144d85b0"
readonly LOGFILE=/var/log/cfs-monitor.log
#定义的是命令执行的超时时间
readonly TIMESECsmall="3"
readonly TIMESEClarge="20"

#文件名的随机后缀变量
readonly KEY=$((RANDOM))
readonly CFS_ADDR="10.0.2.12:/cfs"
#定义的是功能监控的写入目录
readonly MONITOR_PATH="/root/nfs"

#检查输出文件的目录，文件和权限
function check_prometheus
{
    mkdir -p $MONITOR_PATH
    mkdir -p  /var/lib/node_exporter/textfile
    cd /var/lib/node_exporter/textfile && touch cfs_monitor.prom && chmod 755 cfs_monitor.prom
}

function check_cfs
{ 
    if [ ! -f /usr/bin/nfs-utils ];then
        nohup yum install -y nfs-utils >/dev/null 2>&1
    fi
     message=$(df -h|grep $CFS_ADDR)
     if [ -z "$message" ]; then
         mkdir -p /root/nfs
         mount -t nfs -o vers=3 -o noresvport $CFS_ADDR $MONITOR_PATH
     fi
}

#通过云硬盘写入文件后读取检查云硬盘的可用性
function check_result
{
    cd $MONITOR_PATH && timeout $TIMESECsmall echo $MD5 > cfs_monitor."$KEY"

    local result=$( timeout $TIMESECsmall cat $MONITOR_PATH/cfs_monitor."$KEY")

    cd $MONITOR_PATH && timeout $TIMESECsmall /usr/bin/rm -f cfs_monitor."$KEY"

    if [ "$result" == "$MD5" ];then
        cd /var/lib/node_exporter/textfile && echo "cfs_monitor_status 0" > cfs_monitor.prom
    else
        cd /var/lib/node_exporter/textfile && echo "cfs_monitor_status 1" > cfs_monitor.prom
    fi
}

#通过云硬盘写入100MB文件来测试性能，目前测试，通过dd生成固定大小的文件，其md5是相同的，因此在该处只验证了md5，只要md5正确，就输出写入耗时
#写入耗时部分，增加了纳秒统计，否则，无法进行精确比较date +%s%N，如果不需要纳秒级别统计，可以改为date +%s
function check_performance
{
    local Begin_time=$(date +%s%N)
    timeout $TIMESEClarge dd if=/dev/zero of=$MONITOR_PATH/cfs_monitor.performance."$KEY" bs=1MB count=100 2>/dev/null
    local End_time=$(date +%s%N)
    local time_result=$((End_time - Begin_time))
    log_info "cfs_monitor.performance.$KEY write finished!!! Cost is $time_result" >> $LOGFILE 
    if [ "$(ll $MONITOR_PATH/cfs_monitor.performance."$KEY"|awk -F" "  '{print $5}')" -eq 100000000 ];then
        cd /var/lib/node_exporter/textfile && echo -e "cfs_monitor_100mb 0\ncfs_monitor_time_100mb $time_result" >> cfs_monitor.prom
    else
        cd /var/lib/node_exporter/textfile && echo -e "cfs_monitor_100mb -1\ncfs_monitor_time_100mb $time_result" >> cfs_monitor.prom
    fi
    rm -f $MONITOR_PATH/cfs_monitor.performance."$KEY"
}

function main
{
    check_cfs
    check_prometheus
    check_result
    check_performance
}

main
