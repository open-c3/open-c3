#!/bin/bash

/opt/mydan/perl/bin/perl -MAnyEvent::HTTP -e 1
checkPerlModule=$?

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


if [ $checkPerlModule -ne 0 ];then

    if [ "X$OPENC3_ZONE" == "XCN" ];then

        if [ -f /root/.cpan/CPAN/MyConfig.pm ] && [ ! -f /root/.cpan/CPAN/MyConfig.pm.c3.bak ] ; then
            cp /root/.cpan/CPAN/MyConfig.pm /root/.cpan/CPAN/MyConfig.pm.c3.bak
        fi

        /opt/mydan/dan/tools/alarm 10 "/opt/mydan/perl/bin/cpan install AnyEvent::HTTP </dev/null" || echo skip www.cpan.org

        sed -i "s/'urllist' => \[q\[http:\/\/www\.cpan\.org\/\]\],/'urllist' => \[q[http:\/\/mirrors.163.com\/cpan\/]\],/" /root/.cpan/CPAN/MyConfig.pm

    else
        if [ -f /root/.cpan/CPAN/MyConfig.pm ] && [ -f /root/.cpan/CPAN/MyConfig.pm.c3.bak ] ; then
            cp /root/.cpan/CPAN/MyConfig.pm.c3.bak /root/.cpan/CPAN/MyConfig.pm
        fi
    fi

    /opt/mydan/perl/bin/cpan install AnyEvent::HTTP </dev/null

fi

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
fi

killall mydan.node_exporter.65110 2>/dev/null

echo "INSTALL OPEN-C3 MONITOR AGENT: SUCCESS!!!"
