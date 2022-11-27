#!/bin/bash

mkdir -p /data/open-c3-data/glusterfs/maintain
cd /data/open-c3-data/glusterfs/maintain || exit

mkdir -p data/logs
rsync -av /data/open-c3-data/logs/ data/logs/ --exclude CI/build_temp_uuid --exclude CI/git_cache
