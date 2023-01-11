#!/bin/bash
set -ex

cd /data/open-c3/Installer/C3/pkg/trouble-ticketing || exit

bash -c "cd /data/open-c3/Connector/tt/trouble-ticketing && ./build.sh"

mkdir -p _tempdata/open-c3/Connector/pkg
cp /data/open-c3/Connector/tt/trouble-ticketing/trouble-ticketing _tempdata/open-c3/Connector/pkg/
mv _tempdata tempdata
