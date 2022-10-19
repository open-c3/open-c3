#!/bin/bash
set -ex

mkdir -p temp
cd temp

VERSION=v2.0.1
rm -f cloudeye-exporter.*.tar.gz
wget https://github.com/huaweicloud/cloudeye-exporter/releases/download/$VERSION/cloudeye-exporter.$VERSION.tar.gz
tar -zxvf cloudeye-exporter.$VERSION.tar.gz

echo $VERSION > .version
