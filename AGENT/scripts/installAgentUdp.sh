#!/bin/bash

set -e 

if [ "X$OPEN_C3_ADDR" == "X" ]; then
    echo 'OPEN_C3_ADDR nofind'
    exit 1
fi

MYDanPATH=/data/mydan

if [ ! -d "$MYDanPATH/dan" ]; then
    echo "nofind mydan path: $MYDanPATH/dan"
    exit
fi

cd "$MYDanPATH/dan" || exit 1

/opt/mydan/perl/bin/cpan  install AnyEvent::Handle::UDP

wget $OPEN_C3_ADDR/api/scripts/agent.udp.tar.gz -O $MYDanPATH/dan/agent.udp.tar.gz

tar -zxvf agent.udp.tar.gz

cp /opt/mydan/dan/agent.udp/exec.config/mydan.udpserver.65111 /opt/mydan/dan/bootstrap/exec/
chmod +x /opt/mydan/dan/bootstrap/exec/mydan.udpserver.65111

killall mydan.udpserver.65111
