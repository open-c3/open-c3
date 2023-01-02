#!/bin/bash
set -e

mkdir -p /data/open-c3-data/jumpserver-data

cd /opt
wget https://github.com/jumpserver/installer/releases/download/v2.28.6/jumpserver-installer-v2.28.6.tar.gz
tar -xf jumpserver-installer-v2.28.6.tar.gz
cd jumpserver-installer-v2.28.6

sed -Ei "s|192.168.250.0/24|172.26.0.0/16|g" config-example.txt
sed -Ei "s|/data/jumpserver|/data/open-c3-data/jumpserver-data|g" config-example.txt
sed -i "/^  read_from_input confirm/d" scripts/1_config_jumpserver.sh
sed -Ei "s|  net:|  JobNet:|g" compose/docker-compose-network.yml
sed -Ei "s|  net:|  JobNet:|g" compose/docker-compose-network_ipv6.yml
sed -i 's/- net/- JobNet/g' compose/*
sed -Ei "s|service=jms_${service}|service=${service}|g" jmsctl.sh
sed -Ei "s|COMPOSE_PROJECT_NAME=jms|COMPOSE_PROJECT_NAME=c3|g" scripts/const.sh
sed -Ei "s|container_name: jms_|container_name: openc3-jms-|g" compose/*
sed -Ei "s|jms_core|openc3-jms-core|g" scripts/utils.sh
sed -Ei "s|jms_mysql|openc3-jms-mysql|g" scripts/utils.sh

echo "        - gateway: 172.26.0.1" >> compose/docker-compose-network.yml

yum install -y iptables
/opt/jumpserver-installer-v2.28.6/jmsctl.sh install
