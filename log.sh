#!/bin/bash

function log_info ()
{
if [  -d /var/log  ]
then
    mkdir -p /var/log
fi
DATE_N=`date "+%Y-%m-%d %H:%M:%S"`
USER_N=`whoami`
echo "${DATE_N} ${USER_N} execute $0 [INFO] $@"  #执行成功日志打印路径
}

function log_error ()
{
DATE_N=`date "+%Y-%m-%d %H:%M:%S"`
USER_N=`whoami`
echo -e "\033[41;37m ${DATE_N} ${USER_N} execute $0 [ERROR] $@ \033[0m"   #执行失败日志打印路径
}
