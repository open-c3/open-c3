#!/bin/bash

mkdir -p data/logs
rsync -av /data/open-c3-data/logs/ data/logs/ --exclude CI/build_temp_uuid --exclude CI/git_cache
