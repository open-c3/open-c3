#!/bin/bash

mkdir -p /data/open-c3-data/glusterfs/maintain
cd /data/open-c3-data/glusterfs/maintain || exit

cp data/current     /data/open-c3/Connector/config.ini/current
cp data/sysctl.conf /data/open-c3-data/
cp data/auth/*      /data/open-c3-data/auth/

mkdir -p /data/open-c3-data/private
rsync -av data/private/ /data/open-c3-data/private/
