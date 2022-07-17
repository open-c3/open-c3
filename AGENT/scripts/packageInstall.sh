#!/bin/bash
set -e

MYDanPATH=/opt/mydan

if [ -d "$MYDanPATH" ]; then
    echo "$MYDanPATH already exists, exit"
    exit
fi

INFO=$(    echo $0|sed  's/.*openc3.agent.//'|sed 's/.run.*//')

version=$( echo $INFO|awk -F. '{print $1}')
FOS=$(     echo $INFO|awk -F. '{print $2}')
FARCH=$(   echo $INFO|awk -F. '{print $3}')

LOS=$(  uname   )  
LARCH=$(uname -m)

checktool() {
    if ! type $1 >/dev/null 2>&1; then
        echo "Need tool: $1"
        exit 1;
    fi
}

checktool tar
checktool head

if [[ "X$FOS" == "X$LOS" ]] && [[ "X$FARCH" == "X$LARCH" ]] ;then
    echo OS: $FOS ARCH: $FARCH 
else
    echo "nomatch FOS: $FOS FARCH: $FARCH <=> LOS: $LOS LARCH: $LARCH"
    echo "ERROR"
    exit 1
fi

if [ -f $MYDanPATH/perl/.lock ]; then
    echo "The perl is locked"
    exit 1;
fi

clean_exit () {
    echo  "ERROR"
    exit $1
}

rm    -rf /data/mydan /opt/mydan
mkdir -p  /data/mydan

tar -zxvf $TMP -C /data/mydan || clean_exit 1

ln -fs /data/mydan /opt/mydan


netstat -nlpt >/dev/null 2>&1

NodeExport=$(netstat -tnlp | grep ":9100\b"|wc -l)
if [ "X$NodeExport" == "X0"  ];then
    cp /opt/mydan/dan/agent.mon/exec.config/prometheus.node_exporter.9100 /opt/mydan/dan/bootstrap/exec/
    chmod +x /opt/mydan/dan/bootstrap/exec/prometheus.node_exporter.9100

else
    if [ -f /opt/mydan/dan/bootstrap/exec/prometheus.node_exporter.9100 ]; then
        rm /opt/mydan/dan/bootstrap/exec/prometheus.node_exporter.9100
    fi
fi

/opt/mydan/dan/bootstrap/bin/bootstrap --install
/opt/mydan/dan/bootstrap/bin/bootstrap --start

echo "INSTALL OPEN-C3 AGENT: SUCCESS!!!"
