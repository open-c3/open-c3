#!/bin/bash
set -e
cd  /data/open-c3-frontend
git pull
npm run build
cd /data/open-c3/Installer/C3/pkg
./build-module.sh open-c3-frontend v2
docker push openc3/pkg-open-c3-frontend:v2
