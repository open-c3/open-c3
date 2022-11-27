#!/bin/bash

mkdir -p /data/open-c3-data/glusterfs/maintain
cd /data/open-c3-data/glusterfs/maintain || exit

rsync -av data/logs/ /data/open-c3-data/logs/
