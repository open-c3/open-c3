#!/bin/bash
set -e

cd /data/open-c3/Connector/bl/jumpserver
bash build.sh

chmod +x ./c3mc-bl-jumpserver
mkdir -p /data/open-c3/Connector/pp/bl/jumpserver
mv c3mc-bl-jumpserver /data/open-c3/Connector/pp/bl/jumpserver
