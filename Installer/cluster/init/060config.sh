#!/bin/bash

set -e

APIC=$(cat /etc/hosts|grep open-c3.org|wc -l)
if [ $APIC = 0 ]; then
    echo >> /etc/hosts
fi

function updatehosts() {
    API=$1
    C=$(cat /etc/hosts|grep $API|wc -l)
    if [ $C = 0 ]; then
        echo "127.0.0.1 $API" >> /etc/hosts
    fi
}

updatehosts api.connector.open-c3.org
updatehosts api.ci.open-c3.org
updatehosts api.agent.open-c3.org
updatehosts api.job.open-c3.org
updatehosts api.jobx.open-c3.org

setenforce 0

iptables -I INPUT -p tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp --dport 81 -j ACCEPT
iptables -I INPUT -p tcp --dport 88 -j ACCEPT

seq 65135 65235|xargs -i{} iptables -I INPUT -p tcp --dport {} -j ACCEPT
