#!/bin/bash

set -e 

if [ "X$OPEN_C3_ADDR" == "X" ]; then
    echo 'OPEN_C3_ADDR nofind'
    exit 1
fi

MYDanPATH=/opt/mydan

if [ ! -d "$MYDanPATH/dan" ]; then
    echo "nofind mydan path: $MYDanPATH/dan"
    exit
fi

cd "$MYDanPATH/dan" || exit 1

/opt/mydan/perl/bin/cpan install AnyEvent::HTTP </dev/null

wget $OPEN_C3_ADDR/api/scripts/agent.mon.tar.gz -O $MYDanPATH/dan/agent.mon.tar.gz

tar -zxvf agent.mon.tar.gz

cp /opt/mydan/dan/agent.mon/exec.config/mydan.node_exporter.65110 /opt/mydan/dan/bootstrap/exec/
chmod +x /opt/mydan/dan/bootstrap/exec/mydan.node_exporter.65110


OS=$(uname)
ARCH=$(uname -m)

if [ ! -x /opt/mydan/dan/agent.mon/data/node_exporter/$OS-$ARCH/node_exporter ]; then
    echo "prometheus node_exporter nofind";
    exit
fi

netstat -nlpt >/dev/null 2>&1

NodeExport=$(netstat -tnlp | grep ":9100\b"|wc -l)
if [ "X$NodeExport" == "X0"  ];then
    cp /opt/mydan/dan/agent.mon/exec.config/prometheus.node_exporter.9100 /opt/mydan/dan/bootstrap/exec/
    chmod +x /opt/mydan/dan/bootstrap/exec/prometheus.node_exporter.9100

#    killall mydan.node_exporter.65110 2>/dev/null
fi

echo "INSTALL OPEN-C3 MONITOR AGENT: SUCCESS!!!"
