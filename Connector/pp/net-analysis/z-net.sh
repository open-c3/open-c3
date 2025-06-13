#!/bin/bash

netstat -antp 2>/dev/null | grep "tcp" | awk '{print $5}' | grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}:[0-9]+'|grep -v "^127.0.0.1:"|grep -v "^0.0.0.0:" |awk -F '.' '{print $1"."$2}'|sort|uniq

if systemctl is-active --quiet docker; then
    docker ps -q|xargs -i{} docker inspect --format '{{.State.Pid}}' {}|grep "^[0-9]*$"|xargs -i{} nsenter --net=/proc/{}/ns/net netstat -antp 2>/dev/null | grep "tcp" | awk '{print $5}' | grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}:[0-9]+' | grep -v "^127.0.0.1:"|grep -v "^0.0.0.0:" |awk -F '.' '{print $1"."$2}'|sort|uniq
fi

if systemctl is-active --quiet containerd && ! systemctl is-active --quiet docker; then
    crictl ps -q|xargs -i{} bash -c "crictl inspect {} |grep pid|sed 's/ //g'|grep '^\"pid\"'|awk -F: '{print \$2}'|sed 's/,//'|grep -v \"^[0-9]$\"|head -n 1"|grep "^[0-9]*$"|xargs -i{} nsenter --net=/proc/{}/ns/net netstat -antp 2>/dev/null | grep "tcp" | awk '{print $5}' | grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}:[0-9]+' | grep -v "^127.0.0.1:"|grep -v "^0.0.0.0:" |awk -F '.' '{print $1"."$2}'|sort|uniq
fi
