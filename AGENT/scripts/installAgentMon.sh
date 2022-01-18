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

/opt/mydan/perl/bin/cpan install AnyEvent::HTTP

wget $OPEN_C3_ADDR/api/scripts/agent.mon.tar.gz -O $MYDanPATH/dan/agent.mon.tar.gz

tar -zxvf agent.mon.tar.gz

cp /opt/mydan/dan/agent.mon/exec.config/mydan.node_exporter.65110 /opt/mydan/dan/bootstrap/exec/
chmod +x /opt/mydan/dan/bootstrap/exec/mydan.node_exporter.65110

killall mydan.node_exporter.65110
