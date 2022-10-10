#!/bin/bash
domain=$1
name=$2

if [ "X$domain" == "X" ];then
    echo \$0 example.domain
    exit 1
fi

if [ "X$name" == "X" ];then
    name=default
fi

function push {
    request_address='http://127.0.0.1:65110/v1/push'
    ts=`date +%s`
    endpoint=`hostname`
    declare -i step='60'
    tags="name=$name,domain=$domain";
    metric="vm_dns_check";
    counterType='GAUGE'
    curl --connect-timeout 3 -m 3 -X POST -d "[{\"metric\": \"$metric\", \"endpoint\": \"$endpoint\", \"timestamp\": $ts,\"step\": $step,\"value\": $value,\"counterType\": \"$counterType\",\"tags\": \"$tags\"}]" $request_address
}

domainv=`dig $domain +short |egrep ^'[1-9]' -c`
value=${domainv:-0}
echo value:$value

push
echo
