#!/bin/bash
set -e

cd /data/open-c3/Installer/C3/pkg/jumpserver || exit

bash -c "cd /data/open-c3/Connector/bl/sync/jumpserver && ./build.sh"

mkdir -p _tempdata/open-c3/Connector/bl/sync/jumpserver
cp /data/open-c3/Connector/bl/sync/jumpserver/jumpserver _tempdata/open-c3/Connector/bl/sync/jumpserver/
chmod +x _tempdata/open-c3/Connector/bl/sync/jumpserver/jumpserver
mv _tempdata tempdata
