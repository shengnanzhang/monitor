#!/bin/bash

filename="ns.list"
while read line
do
    echo $line
    sh dns-monitor-v1.sh $line
done < $filename
