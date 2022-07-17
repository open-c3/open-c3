#!/bin/bash
set -e

MYDanPATH=/opt/mydan

if [ "X$OPEN_C3_ADDR" == "X" ]; then
    echo 'OPEN_C3_ADDR nofind'
    exit 1
fi

if [ ! -d "$MYDanPATH/dan" ]; then
    echo "nofind mydan path: $MYDanPATH/dan"
    exit
fi

wget $OPEN_C3_ADDR/api/scripts/packageInstall.sh -O $MYDanPATH/packageInstall.sh

AgentVersion=$(cat /opt/mydan/dan/.version)
if [[ $AgentVersion =~ ^[0-9]{14}$ ]];then
    echo version $AgentVersion
else
    echo no find version info from /opt/mydan/dan/.version
    exit 1
fi

OS=$(  uname   )
ARCH=$(uname -m)


cd $MYDanPATH || exit 1

DIST=/data/openc3.agent.$AgentVersion.$OS.$ARCH

tar -zcvf $DIST.tar.gz *
/opt/mydan/dan/tools/xtar --script $MYDanPATH/packageInstall.sh --package $DIST.tar.gz --output $DIST
rm -f $DIST.tar.gz

echo ok
